//! The interpreter: runtime limits, the native bridge the prelude closes
//! over, the event loop and how a script's end is classified.

use std::cell::RefCell;
use std::collections::{BTreeMap, HashMap, HashSet};
use std::rc::Rc;
use std::sync::atomic::{AtomicBool, AtomicU64, AtomicU8, Ordering};
use std::sync::mpsc::{Receiver, RecvTimeoutError};
use std::sync::Arc;
use std::time::{Duration, Instant};

use rquickjs::context::{intrinsic, EvalOptions};
use rquickjs::{qjs, Context, Ctx, Exception, Function, Object, Runtime, Value};
use serde_json::Value as Json;

use crate::alloc::{HeapStats, LimitedAllocator};
use crate::cputime::{process_cpu_ns, thread_cpu_ns};
use crate::io::{write_done, write_frame, Event};
use crate::protocol::{
    self, done_frame, CallResult, ErrorKind, HostFrame, Init, Limits, ScriptError, Stats,
    MAX_FRAME_BYTES, MAX_ITEM_BYTES, MAX_STORE_KEY_BYTES,
};
use crate::site::{Script, SCRIPT_FILE, SCRIPT_HEAD, SCRIPT_TAIL};

/// The embedded prelude.
pub const PRELUDE: &str = include_str!("prelude.js");

/// Engine identifier announced in `ready`.
pub const ENGINE: &str = "quickjs-ng 0.16.2";

/// Heap limit while the prelude runs, before `init` sets the real one.
const PRELUDE_HEAP_BYTES: usize = 64 * 1024 * 1024;

/// Most timers a script may have pending at once.
const MAX_TIMERS: usize = 10_000;

/// Longest timer delay (the usual 32-bit millisecond bound).
const MAX_TIMER_MS: f64 = 2_147_483_647.0;

/// CPU time the runner may spend reading an error after a stop.
const GRACE_NS: u64 = 200_000_000;

/// Jobs run between two looks at the host queue.
const JOB_BATCH: usize = 256;

/// Most `store()` writes and deletes one script may make. Each one is a
/// frame the host has to read and record, so without a count a script could
/// overwrite one key in a loop and emit an unbounded stream of them.
pub const MAX_STORE_OPS: u64 = 2_000;

/// The serialized values one script may write in total, as a multiple of
/// `store_total_bytes`. Overwriting one key keeps the stored total within
/// budget while every write is still a frame the host reads; this bounds
/// the bytes those frames carry.
pub const STORE_WRITE_FACTOR: u64 = 16;

/// Longest `call` name, in UTF-8 bytes: the host's cap
/// (`CodeModeLimits.maxCallNameBytes`). Catalog names are far shorter.
pub const MAX_CALL_NAME_BYTES: usize = 256;

/// The media types `image()` accepts: the host's
/// `CodeModeLimits.imageMediaTypes`, the ones every model provider takes.
pub const IMAGE_MEDIA_TYPES: [&str; 4] = ["image/png", "image/jpeg", "image/gif", "image/webp"];

/// Largest image, decoded: the host's `CodeModeLimits.maxImageBytes`.
pub const MAX_IMAGE_BYTES: usize = 5 * 1024 * 1024;

/// Longest image data, in base64 characters: four characters per three
/// bytes, padding included, the host's `(maxImageBytes + 2) ~/ 3 * 4`.
pub const MAX_IMAGE_BASE64: usize = MAX_IMAGE_BYTES.div_ceil(3) * 4;

/// Strings up to this many UTF-16 units are copied before they are measured
/// in UTF-8 bytes, so a refusal can name the exact size; longer ones over a
/// limit are refused by their length alone, without a copy.
const COPY_TO_MEASURE_UNITS: usize = 64 * 1024;

/// Host functions a `call` frame with `target: "host"` may name.
pub const HOST_CALLS: [&str; 10] = [
    "searchTools",
    "describeTool",
    "describeNamespace",
    "models.embed",
    "models.rank",
    "models.classify",
    "history",
    "outputs",
    "loadOutput",
    "keep",
];

/// Why the interpreter was stopped. First reason wins.
#[repr(u8)]
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Abort {
    None = 0,
    Cpu = 1,
    Cancelled = 2,
    Output = 3,
    Memory = 4,
    Exit = 5,
}

impl Abort {
    fn from_u8(v: u8) -> Abort {
        match v {
            1 => Abort::Cpu,
            2 => Abort::Cancelled,
            3 => Abort::Output,
            4 => Abort::Memory,
            5 => Abort::Exit,
            _ => Abort::None,
        }
    }
}

/// State the interrupt handler reads. Shared with the stdin reader through
/// `cancel`.
pub struct Shared {
    pub cancel: Arc<AtomicBool>,
    abort: AtomicU8,
    /// Thread CPU time (ns) after which the script is stopped; 0 = unarmed.
    cpu_deadline_ns: AtomicU64,
    /// While non-zero, the runner itself is reading an error after a stop:
    /// the interpreter may run until this thread CPU time and nothing else
    /// is checked.
    grace_deadline_ns: AtomicU64,
    pub heap: Arc<HeapStats>,
    /// Process CPU time (ns) after which the watchdog ends the script
    /// itself; 0 = unarmed.
    pub watchdog_deadline_ns: AtomicU64,
    /// Process CPU time (ns) when the script started, for the watchdog's
    /// `stats.cpu_ms`.
    pub exec_process_cpu_ns: AtomicU64,
    /// The script's CPU and heap budgets, for the watchdog's messages.
    pub cpu_budget_ms: AtomicU64,
    pub heap_budget_bytes: AtomicU64,
    /// Why an output limit ended the script, once one did.
    pub output_message: std::sync::Mutex<String>,
    /// Copies of the counters in the interpreter's own state, for the
    /// watchdog's `stats`.
    pub calls: AtomicU64,
    pub output_chars: AtomicU64,
    pub output_items: AtomicU64,
}

impl Shared {
    pub fn new(cancel: Arc<AtomicBool>) -> Arc<Shared> {
        Arc::new(Shared {
            cancel,
            abort: AtomicU8::new(0),
            cpu_deadline_ns: AtomicU64::new(0),
            grace_deadline_ns: AtomicU64::new(0),
            heap: HeapStats::new(PRELUDE_HEAP_BYTES),
            watchdog_deadline_ns: AtomicU64::new(0),
            exec_process_cpu_ns: AtomicU64::new(0),
            cpu_budget_ms: AtomicU64::new(0),
            heap_budget_bytes: AtomicU64::new(0),
            output_message: std::sync::Mutex::new(String::new()),
            calls: AtomicU64::new(0),
            output_chars: AtomicU64::new(0),
            output_items: AtomicU64::new(0),
        })
    }

    pub fn abort(&self) -> Abort {
        Abort::from_u8(self.abort.load(Ordering::SeqCst))
    }

    /// Records `reason` unless another reason was recorded first.
    pub fn set_abort(&self, reason: Abort) {
        let _ = self
            .abort
            .compare_exchange(0, reason as u8, Ordering::SeqCst, Ordering::SeqCst);
    }

    /// How a script that has stopped ended. A limit or a cancel the
    /// interpreter recorded stands: it fired first. A script's own ending
    /// (`exit()`, recorded as `Exit`, or `None` for its promise settling)
    /// stands only if, when the script actually stopped, nothing had fired
    /// that it could not have chosen: a cancel, an exhausted heap or
    /// `cpu_over` (CPU past the budget), checked in the interrupt check's
    /// order. Without this, `exit()` or a throw from inside a long native
    /// call (a typed-array sort's comparator) would turn the CPU overrun or
    /// the cancel that the rest of the call ran into into the script's
    /// milder ending.
    pub fn ending(&self, cpu_over: bool) -> Abort {
        match self.abort() {
            own @ (Abort::None | Abort::Exit) => {
                if self.cancel.load(Ordering::SeqCst) {
                    Abort::Cancelled
                } else if self.heap.exhausted() {
                    Abort::Memory
                } else if cpu_over {
                    Abort::Cpu
                } else {
                    own
                }
            }
            recorded => recorded,
        }
    }

    /// How the watchdog ends a script it stops. It fires only when the
    /// interpreter did not stop on time, after the CPU budget ran out or a
    /// cancel was ignored, so the script's own ending never applies: this is
    /// [`Shared::ending`] with the CPU over budget, and never `Exit` or
    /// `None`.
    pub fn stop_reason(&self) -> Abort {
        self.ending(true)
    }

    /// Whether the calling thread (the interpreter's) has used its CPU
    /// budget.
    pub fn cpu_over_budget(&self) -> bool {
        let deadline = self.cpu_deadline_ns.load(Ordering::Relaxed);
        deadline != 0 && thread_cpu_ns() >= deadline
    }

    /// The interrupt check: true stops the interpreter with an uncatchable
    /// error. Also called between jobs.
    pub fn should_stop(&self) -> bool {
        let grace = self.grace_deadline_ns.load(Ordering::Relaxed);
        if grace != 0 {
            return thread_cpu_ns() >= grace;
        }
        if self.abort() != Abort::None {
            return true;
        }
        if self.cancel.load(Ordering::SeqCst) {
            self.set_abort(Abort::Cancelled);
            return true;
        }
        if self.heap.exhausted() {
            self.set_abort(Abort::Memory);
            return true;
        }
        let deadline = self.cpu_deadline_ns.load(Ordering::Relaxed);
        if deadline != 0 && thread_cpu_ns() >= deadline {
            self.set_abort(Abort::Cpu);
            return true;
        }
        false
    }
}

/// How the script's own promise ended.
enum Settled {
    Value(Option<String>),
    Error(String),
    /// The return value's JSON is longer than one frame can carry; it was
    /// refused by its length, without being copied.
    TooLarge,
}

/// Length of a JavaScript string in UTF-16 code units, read from the string
/// itself without copying it.
fn js_units(ctx: &Ctx<'_>, s: &rquickjs::String<'_>) -> usize {
    let mut n: i64 = 0;
    // SAFETY: the value is a live string of this context; JS_GetLength only
    // reads its length property into n.
    let rc = unsafe { qjs::JS_GetLength(ctx.as_raw().as_ptr(), s.as_value().as_raw(), &mut n) };
    if rc < 0 {
        // Reading a string's length cannot fail; if it ever did, treat the
        // string as too long for any limit.
        let _ = ctx.catch();
        return usize::MAX;
    }
    n.max(0) as usize
}

/// A string's size when it is over a byte limit.
enum Size {
    Exact(usize),
    AtLeast(usize),
}

impl std::fmt::Display for Size {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Size::Exact(n) => write!(f, "{n} bytes"),
            Size::AtLeast(n) => write!(f, "at least {n} bytes"),
        }
    }
}

/// Copies `s` into a Rust string when its UTF-8 form is at most `max_bytes`.
/// A string is never shorter in UTF-8 bytes than in UTF-16 units, so one
/// whose length is over the limit is refused before anything is copied
/// (unless it is short enough that copying it to name its exact size costs
/// nothing). This keeps the runner's own allocations, which the heap limit
/// does not cover, a small multiple of what a frame may hold.
fn bounded(ctx: &Ctx<'_>, s: &rquickjs::String<'_>, max_bytes: usize) -> rquickjs::Result<Result<String, Size>> {
    let units = js_units(ctx, s);
    if units > max_bytes && units > COPY_TO_MEASURE_UNITS {
        return Ok(Err(Size::AtLeast(units)));
    }
    let text = s.to_string()?;
    if text.len() > max_bytes {
        return Ok(Err(Size::Exact(text.len())));
    }
    Ok(Ok(text))
}

/// Length of `s` once escaped as a JSON string, quotes excluded, the way
/// serde_json writes it: two bytes for `"`, `\\` and the five short control
/// escapes, six for every other control character, UTF-8 for the rest.
fn escaped_len(s: &str) -> usize {
    s.bytes()
        .map(|b| match b {
            b'"' | b'\\' | b'\n' | b'\r' | b'\t' | 0x08 | 0x0c => 2,
            0..=0x1f => 6,
            _ => 1,
        })
        .sum()
}

/// Bookkeeping the bridge functions update. Never borrowed across a call
/// into JavaScript.
struct State {
    limits: Option<Limits>,
    next_call_id: u64,
    pending: HashSet<u64>,
    calls: u64,
    store_ops: u64,
    store_written: u64,
    output_chars: u64,
    output_items: u64,
    store_sizes: HashMap<String, u64>,
    store_total: u64,
    timers: BTreeMap<(Instant, u64), ()>,
    timer_deadlines: HashMap<u64, Instant>,
    next_timer_id: u64,
    settled: Option<Settled>,
    exec_start: Option<Instant>,
    cpu_start_ns: u64,
    credit_ms: u64,
    /// The script, from `exec` on.
    script: Option<Script>,
}

impl State {
    fn new() -> State {
        State {
            limits: None,
            next_call_id: 1,
            pending: HashSet::new(),
            calls: 0,
            store_ops: 0,
            store_written: 0,
            output_chars: 0,
            output_items: 0,
            store_sizes: HashMap::new(),
            store_total: 0,
            timers: BTreeMap::new(),
            timer_deadlines: HashMap::new(),
            next_timer_id: 1,
            settled: None,
            exec_start: None,
            cpu_start_ns: 0,
            credit_ms: 0,
            script: None,
        }
    }

    fn limits(&self) -> &Limits {
        self.limits.as_ref().expect("init precedes exec")
    }

    fn cpu_used_ms(&self) -> u64 {
        thread_cpu_ns().saturating_sub(self.cpu_start_ns) / 1_000_000
    }
}

type St = Rc<RefCell<State>>;

/// Creates the runtime with the limited allocator and the interrupt handler.
pub fn new_runtime(shared: &Arc<Shared>) -> Result<(Runtime, Context), String> {
    let rt = Runtime::new_with_alloc(LimitedAllocator::new(shared.heap.clone()))
        .map_err(|e| format!("runtime: {e}"))?;
    let s = shared.clone();
    rt.set_interrupt_handler(Some(Box::new(move || s.should_stop())));
    let ctx = Context::custom::<(
        intrinsic::Date,
        intrinsic::Eval,
        intrinsic::RegExpCompiler,
        intrinsic::RegExp,
        intrinsic::Json,
        intrinsic::Proxy,
        intrinsic::MapSet,
        intrinsic::TypedArrays,
        intrinsic::Promise,
        intrinsic::WeakRef,
    )>(&rt)
    .map_err(|e| format!("context: {e}"))?;
    Ok((rt, ctx))
}

/// Throws an error the script cannot catch. QuickJS skips every `catch`
/// and `finally` for it.
fn uncatchable(ctx: &Ctx<'_>, message: &str) -> rquickjs::Error {
    let err = match Exception::from_message(ctx.clone(), message) {
        Ok(e) => e,
        Err(e) => return e,
    };
    let v: Value = err.into_value();
    // SAFETY: v is a live Error object owned by this context.
    unsafe { qjs::JS_SetUncatchableError(ctx.as_raw().as_ptr(), v.as_raw()) };
    ctx.throw(v)
}

fn stopped(ctx: &Ctx<'_>) -> rquickjs::Error {
    uncatchable(ctx, "script stopped")
}

/// Why `image()` refuses its data.
enum ImageProblem {
    Type(String),
    Range(String),
}

/// The host's image rules after the media type: strict standard base64
/// (the alphabet `A-Z a-z 0-9 + /`, `=` padding to a multiple of four, zero
/// bits after the last byte, as Dart's decoder demands), at most
/// [`MAX_IMAGE_BYTES`] decoded, and the file header of `media_type`.
fn image_problem(media_type: &str, data: &str) -> Option<ImageProblem> {
    let not_base64 = || Some(ImageProblem::Type(
        "image() data must be standard base64: A-Z, a-z, 0-9, + and /, padded with = to a multiple of 4".into()));
    let b = data.as_bytes();
    if !b.len().is_multiple_of(4) {
        return not_base64();
    }
    let pad = b.iter().rev().take(2).take_while(|&&c| c == b'=').count();
    let value = |c: u8| -> Option<u8> {
        match c {
            b'A'..=b'Z' => Some(c - b'A'),
            b'a'..=b'z' => Some(c - b'a' + 26),
            b'0'..=b'9' => Some(c - b'0' + 52),
            b'+' => Some(62),
            b'/' => Some(63),
            _ => None,
        }
    };
    let body = &b[..b.len() - pad];
    if body.iter().any(|&c| value(c).is_none()) {
        return not_base64();
    }
    // The bits after the last whole byte must be zero.
    if let Some(&last) = body.last() {
        let spare = match pad { 1 => 0b11, 2 => 0b1111, _ => 0 };
        if value(last).unwrap_or(0) & spare != 0 {
            return not_base64();
        }
    }
    let decoded = b.len() / 4 * 3 - pad;
    if decoded > MAX_IMAGE_BYTES {
        return Some(ImageProblem::Range(format!(
            "image() data decodes to {decoded} bytes; the limit is {MAX_IMAGE_BYTES}")));
    }
    // Decode the first 12 bytes for the header.
    let mut head = Vec::with_capacity(12);
    for quad in body.chunks(4).take(4) {
        let v: Vec<u32> = quad.iter().map(|&c| u32::from(value(c).unwrap_or(0))).collect();
        let n = v.iter().fold(0u32, |acc, x| (acc << 6) | x) << (6 * (4 - v.len()));
        for i in 0..v.len().saturating_sub(1) {
            head.push((n >> (16 - 8 * i)) as u8);
        }
    }
    let starts = |magic: &[u8], at: usize| head.len() >= at + magic.len() && &head[at..at + magic.len()] == magic;
    let ok = match media_type {
        "image/png" => starts(&[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A], 0),
        "image/jpeg" => starts(&[0xFF, 0xD8, 0xFF], 0),
        "image/gif" => starts(b"GIF87a", 0) || starts(b"GIF89a", 0),
        _ => starts(b"RIFF", 0) && starts(b"WEBP", 8),
    };
    if ok {
        None
    } else {
        Some(ImageProblem::Type(format!(
            "image() data is not {media_type}: it does not start with that format's file header")))
    }
}

/// What kind of JSON value `v` is, for an error message.
fn json_kind(v: &Json) -> &'static str {
    match v {
        Json::Null => "null",
        Json::Bool(_) => "a boolean",
        Json::Number(_) => "a number",
        Json::String(_) => "a string",
        Json::Array(_) => "an array",
        Json::Object(_) => "an object",
    }
}

fn json_or_type_error(ctx: &Ctx<'_>, text: &str, what: &str) -> rquickjs::Result<Json> {
    serde_json::from_str(text)
        .map_err(|e| Exception::throw_type(ctx, &format!("{what} cannot be encoded as JSON: {e}")))
}

/// Compiles the session's script the way `new AsyncFunction(code)` would,
/// but under the file name [`SCRIPT_FILE`], and returns the function (or
/// whatever a script that closes the wrapping early evaluates to, as the
/// constructor would). Called once, by the prelude's `run`.
fn compile_script<'js>(ctx: &Ctx<'js>, code: &str) -> rquickjs::Result<Value<'js>> {
    let mut src = Vec::with_capacity(SCRIPT_HEAD.len() + code.len() + SCRIPT_TAIL.len() + 1);
    src.extend_from_slice(SCRIPT_HEAD.as_bytes());
    src.extend_from_slice(code.as_bytes());
    src.extend_from_slice(SCRIPT_TAIL.as_bytes());
    // JS_Eval reads `len` bytes and needs a NUL after them; a NUL inside the
    // script stays part of it, as it does for the AsyncFunction constructor
    // (rquickjs's eval would refuse it).
    src.push(0);
    // SAFETY: src is NUL-terminated and outlives the call; len excludes the
    // terminator; the file name is a static C string. The returned value is
    // owned by us and handed to rquickjs, which frees it.
    unsafe {
        let v = qjs::JS_Eval(
            ctx.as_raw().as_ptr(),
            src.as_ptr().cast(),
            (src.len() - 1) as _,
            SCRIPT_FILE.as_ptr(),
            qjs::JS_EVAL_TYPE_GLOBAL as i32,
        );
        if qjs::JS_VALUE_GET_NORM_TAG(v) == qjs::JS_TAG_EXCEPTION {
            return Err(rquickjs::Error::Exception);
        }
        Ok(Value::from_raw(ctx.clone(), v))
    }
}

/// Builds the bridge object the prelude closes over.
fn bridge<'js>(ctx: &Ctx<'js>, st: &St, shared: &Arc<Shared>) -> rquickjs::Result<Object<'js>> {
    let b = Object::new(ctx.clone())?;

    let s = st.clone();
    b.set(
        "compile",
        Function::new(ctx.clone(), move |ctx: Ctx<'js>| -> rquickjs::Result<Value<'js>> {
            // The borrow ends before compiling: a script that closes the
            // wrapping early runs code, and calls, while it is evaluated.
            let text = s.borrow().script.as_ref().map(Script::text);
            match text {
                Some(text) => compile_script(&ctx, &text),
                None => Err(Exception::throw_internal(&ctx, "no script to compile")),
            }
        }),
    )?;

    let (s, sh) = (st.clone(), shared.clone());
    b.set(
        "call",
        Function::new(ctx.clone(), move |ctx: Ctx<'js>, target: rquickjs::String<'js>, name: rquickjs::String<'js>, args: rquickjs::String<'js>, line: f64, column: f64| -> rquickjs::Result<f64> {
            if sh.abort() != Abort::None {
                return Err(stopped(&ctx));
            }
            let limits = s.borrow().limits().clone();
            let target = match bounded(&ctx, &target, 8)? {
                Ok(t) => t,
                Err(_) => return Err(Exception::throw_type(&ctx, "invalid call target")),
            };
            let name = match bounded(&ctx, &name, MAX_CALL_NAME_BYTES)? {
                Ok(n) if n.is_empty() => return Err(Exception::throw_type(&ctx, "A call name cannot be empty")),
                Ok(n) => n,
                Err(size) => {
                    return Err(Exception::throw_range(&ctx, &format!(
                        "Call name is {size}; the limit is {MAX_CALL_NAME_BYTES}")))
                }
            };
            if target != "tool" && !(target == "host" && HOST_CALLS.contains(&name.as_str())) {
                return Err(Exception::throw_type(&ctx, "invalid call target"));
            }
            if s.borrow().calls >= limits.max_calls {
                return Err(Exception::throw_range(&ctx, &format!(
                    "This script reached its limit of {} calls", limits.max_calls)));
            }
            let args = match bounded(&ctx, &args, limits.max_call_args_bytes as usize)? {
                Ok(a) => a,
                Err(size) => {
                    return Err(Exception::throw_range(&ctx, &format!(
                        "Call arguments are {size}; the limit is {}", limits.max_call_args_bytes)))
                }
            };
            let args_json = json_or_type_error(&ctx, &args, "Call arguments")?;
            drop(args);
            if !args_json.is_object() {
                return Err(Exception::throw_type(&ctx, &format!(
                    "Call arguments must be a JSON object, not {}", json_kind(&args_json))));
            }
            // The host measures the arguments as Dart re-encodes them, which
            // can be longer than the script's own JSON (see hostjson).
            let host_size = crate::hostjson::dart_len(&args_json);
            if host_size > limits.max_call_args_bytes {
                return Err(Exception::throw_range(&ctx, &format!(
                    "Call arguments are {host_size} bytes as the host measures them; the limit is {}",
                    limits.max_call_args_bytes)));
            }
            let mut st = s.borrow_mut();
            let at = st.script.as_ref().and_then(|script| script.site(line, column));
            let id = st.next_call_id;
            let frame = protocol::call_frame(id, &target, &name, args_json, at);
            if frame.len() > MAX_FRAME_BYTES {
                return Err(Exception::throw_range(&ctx, "Call frame is too large"));
            }
            st.next_call_id += 1;
            st.calls += 1;
            sh.calls.store(st.calls, Ordering::SeqCst);
            st.pending.insert(id);
            drop(st);
            write_frame(&frame);
            Ok(id as f64)
        }),
    )?;

    // Output: every size is checked before the frame is built, and the
    // script's string is not copied at all when its length alone shows it
    // is over a limit. The refusal ends the script (uncatchable).
    let refuse = |sh: &Arc<Shared>, ctx: &Ctx<'js>, msg: String| -> rquickjs::Error {
        *sh.output_message.lock().unwrap_or_else(|e| e.into_inner()) = msg.clone();
        sh.set_abort(Abort::Output);
        uncatchable(ctx, &msg)
    };
    let frame_limit = || format!("One output item exceeds the {MAX_FRAME_BYTES}-byte frame limit");
    // Checks one item's text against the frame and the character budget,
    // first by length, then (copied) by characters and escaped size.
    let admit = move |s: &St, sh: &Arc<Shared>, ctx: &Ctx<'js>, text: &rquickjs::String<'js>, count_bytes: bool| -> rquickjs::Result<(String, u64)> {
        if sh.abort() != Abort::None {
            return Err(stopped(ctx));
        }
        let (max_chars, used_chars, used_items, max_items) = {
            let st = s.borrow();
            let l = st.limits();
            (l.max_output_chars, st.output_chars, st.output_items, l.max_output_items)
        };
        if used_items + 1 > max_items {
            return Err(refuse(sh, ctx, format!("Output exceeded {max_items} items")));
        }
        let units = js_units(ctx, text);
        if units > MAX_ITEM_BYTES {
            return Err(refuse(sh, ctx, frame_limit()));
        }
        // A character is one or two UTF-16 units, so half the length is a
        // floor on the characters this item adds.
        if (units as u64).div_ceil(2) > max_chars.saturating_sub(used_chars) {
            return Err(refuse(sh, ctx, format!("Output exceeded {max_chars} characters")));
        }
        let text = text.to_string()?;
        let chars = if count_bytes { text.len() } else { text.chars().count() } as u64;
        if escaped_len(&text) > MAX_ITEM_BYTES {
            return Err(refuse(sh, ctx, frame_limit()));
        }
        if used_chars + chars > max_chars {
            return Err(refuse(sh, ctx, format!("Output exceeded {max_chars} characters")));
        }
        Ok((text, chars))
    };
    let emit = move |s: &St, sh: &Arc<Shared>, ctx: &Ctx<'js>, chars: u64, frame: String| -> rquickjs::Result<()> {
        if frame.len() > MAX_FRAME_BYTES {
            return Err(refuse(sh, ctx, frame_limit()));
        }
        let mut st = s.borrow_mut();
        st.output_chars += chars;
        st.output_items += 1;
        sh.output_chars.store(st.output_chars, Ordering::SeqCst);
        sh.output_items.store(st.output_items, Ordering::SeqCst);
        drop(st);
        write_frame(&frame);
        Ok(())
    };

    let (s, sh) = (st.clone(), shared.clone());
    b.set(
        "text",
        Function::new(ctx.clone(), move |ctx: Ctx<'js>, text: rquickjs::String<'js>| -> rquickjs::Result<()> {
            let (text, chars) = admit(&s, &sh, &ctx, &text, false)?;
            emit(&s, &sh, &ctx, chars, protocol::text_frame(&text))
        }),
    )?;
    let (s, sh) = (st.clone(), shared.clone());
    b.set(
        "log",
        Function::new(ctx.clone(), move |ctx: Ctx<'js>, level: rquickjs::String<'js>, text: rquickjs::String<'js>| -> rquickjs::Result<()> {
            // The prelude passes one of five fixed level names.
            let level = match bounded(&ctx, &level, 8)? {
                Ok(l) => l,
                Err(_) => return Err(Exception::throw_type(&ctx, "invalid log level")),
            };
            let (text, chars) = admit(&s, &sh, &ctx, &text, false)?;
            emit(&s, &sh, &ctx, chars, protocol::log_frame(&level, &text))
        }),
    )?;
    let (s, sh) = (st.clone(), shared.clone());
    b.set(
        "image",
        Function::new(ctx.clone(), move |ctx: Ctx<'js>, media_type: rquickjs::String<'js>, data: rquickjs::String<'js>| -> rquickjs::Result<()> {
            if sh.abort() != Abort::None {
                return Err(stopped(&ctx));
            }
            // The host's rules (`imageProblem`), checked here so that a
            // script gets a catchable error instead of losing its session.
            let media_type = match bounded(&ctx, &media_type, 16)? {
                Ok(m) if IMAGE_MEDIA_TYPES.contains(&m.as_str()) => m,
                _ => return Err(Exception::throw_type(&ctx,
                    "image() media type must be image/png, image/jpeg, image/gif or image/webp")),
            };
            let units = js_units(&ctx, &data);
            if units > MAX_IMAGE_BASE64 {
                return Err(Exception::throw_range(&ctx, &format!(
                    "image() data is {units} base64 characters; the limit is {MAX_IMAGE_BASE64} ({MAX_IMAGE_BYTES} bytes decoded)")));
            }
            // Checked before the output budget, which ends the script: a
            // malformed image is the script's mistake to catch.
            match image_problem(&media_type, &data.to_string()?) {
                None => {}
                Some(ImageProblem::Type(msg)) => return Err(Exception::throw_type(&ctx, &msg)),
                Some(ImageProblem::Range(msg)) => return Err(Exception::throw_range(&ctx, &msg)),
            }
            let (data, chars) = admit(&s, &sh, &ctx, &data, true)?;
            emit(&s, &sh, &ctx, chars, protocol::image_frame(&media_type, &data))
        }),
    )?;

    let (s, sh) = (st.clone(), shared.clone());
    b.set(
        "store",
        Function::new(ctx.clone(), move |ctx: Ctx<'js>, key: rquickjs::String<'js>, value: Option<rquickjs::String<'js>>| -> rquickjs::Result<()> {
            if sh.abort() != Abort::None {
                return Err(stopped(&ctx));
            }
            let limits = s.borrow().limits().clone();
            if s.borrow().store_ops >= MAX_STORE_OPS {
                return Err(Exception::throw_range(&ctx, &format!(
                    "This script reached its limit of {MAX_STORE_OPS} store operations")));
            }
            let key = match bounded(&ctx, &key, MAX_STORE_KEY_BYTES)? {
                Ok(k) => k,
                Err(size) => {
                    return Err(Exception::throw_range(&ctx, &format!(
                        "Store key is {size}; the limit is {MAX_STORE_KEY_BYTES}")))
                }
            };
            let frame = match &value {
                None => {
                    // A session that may not write (budget 0) may not delete
                    // either: a delete changes stored state just as a write does.
                    if limits.store_total_bytes == 0 {
                        return Err(Exception::throw_range(&ctx,
                            "Stored values cannot change in this session; the limit is 0 bytes"));
                    }
                    let mut st = s.borrow_mut();
                    let old = st.store_sizes.remove(&key).unwrap_or(0);
                    st.store_total -= old;
                    st.store_ops += 1;
                    protocol::store_frame(&key, None)
                }
                Some(json) => {
                    let json = match bounded(&ctx, json, limits.store_value_bytes as usize)? {
                        Ok(j) => j,
                        Err(size) => {
                            return Err(Exception::throw_range(&ctx, &format!(
                                "Stored value is {size}; the limit is {}", limits.store_value_bytes)))
                        }
                    };
                    let parsed = json_or_type_error(&ctx, &json, "Stored value")?;
                    drop(json);
                    // Measured as the host measures it (see hostjson); never
                    // less than the script's own JSON, which `bounded` checked.
                    let size = crate::hostjson::dart_len(&parsed);
                    if size > limits.store_value_bytes {
                        return Err(Exception::throw_range(&ctx, &format!(
                            "Stored value is {size} bytes as the host measures it; the limit is {}", limits.store_value_bytes)));
                    }
                    let written_limit = limits.store_total_bytes.saturating_mul(STORE_WRITE_FACTOR);
                    let written = s.borrow().store_written.saturating_add(size);
                    if written > written_limit {
                        return Err(Exception::throw_range(&ctx, &format!(
                            "Values written by this script would total {written} bytes; the limit is {written_limit} ({STORE_WRITE_FACTOR} times the store budget)")));
                    }
                    let old = s.borrow().store_sizes.get(&key).copied().unwrap_or(0);
                    let total = s.borrow().store_total - old + size;
                    if total > limits.store_total_bytes {
                        return Err(Exception::throw_range(&ctx, &format!(
                            "Stored values would total {total} bytes; the limit is {}", limits.store_total_bytes)));
                    }
                    let mut st = s.borrow_mut();
                    st.store_sizes.insert(key.clone(), size);
                    st.store_total = total;
                    st.store_written = written;
                    st.store_ops += 1;
                    protocol::store_frame(&key, Some(parsed))
                }
            };
            write_frame(&frame);
            Ok(())
        }),
    )?;
    let s = st.clone();
    b.set(
        "limits",
        Function::new(ctx.clone(), move || -> String {
            let st = s.borrow();
            let l = st.limits();
            let elapsed = st.exec_start.map(|t| t.elapsed().as_millis() as u64).unwrap_or(0);
            let mut m = serde_json::Map::new();
            m.insert("wallMsRemaining".into(), (l.wall_ms + st.credit_ms).saturating_sub(elapsed).into());
            m.insert("cpuMsRemaining".into(), l.cpu_ms.saturating_sub(st.cpu_used_ms()).into());
            m.insert("callsRemaining".into(), l.max_calls.saturating_sub(st.calls).into());
            m.insert("returnBudgetChars".into(), l.return_budget_chars.into());
            m.insert("outputItemsRemaining".into(), l.max_output_items.saturating_sub(st.output_items).into());
            Json::Object(m).to_string()
        }),
    )?;

    let sh = shared.clone();
    b.set(
        "exit",
        Function::new(ctx.clone(), move |ctx: Ctx<'js>| -> rquickjs::Result<()> {
            sh.set_abort(Abort::Exit);
            Err(stopped(&ctx))
        }),
    )?;

    let (s, sh) = (st.clone(), shared.clone());
    b.set(
        "setTimer",
        Function::new(ctx.clone(), move |ctx: Ctx<'js>, delay: f64| -> rquickjs::Result<f64> {
            if sh.abort() != Abort::None {
                return Err(stopped(&ctx));
            }
            let mut st = s.borrow_mut();
            if st.timer_deadlines.len() >= MAX_TIMERS {
                return Err(Exception::throw_range(&ctx, &format!("At most {MAX_TIMERS} timers may be pending")));
            }
            let ms = if delay.is_finite() { delay.clamp(0.0, MAX_TIMER_MS) } else { 0.0 };
            let at = Instant::now() + Duration::from_millis(ms as u64);
            let id = st.next_timer_id;
            st.next_timer_id += 1;
            st.timers.insert((at, id), ());
            st.timer_deadlines.insert(id, at);
            Ok(id as f64)
        }),
    )?;
    let s = st.clone();
    b.set(
        "clearTimer",
        Function::new(ctx.clone(), move |id: f64| {
            let mut st = s.borrow_mut();
            let id = id as u64;
            if let Some(at) = st.timer_deadlines.remove(&id) {
                st.timers.remove(&(at, id));
            }
        }),
    )?;

    let s = st.clone();
    b.set(
        "settle",
        Function::new(ctx.clone(), move |ctx: Ctx<'js>, ok: bool, json: Option<rquickjs::String<'js>>| -> rquickjs::Result<()> {
            if s.borrow().settled.is_some() {
                return Ok(());
            }
            let text = match &json {
                None => None,
                Some(j) => Some(bounded(&ctx, j, MAX_ITEM_BYTES)?),
            };
            let settled = match (ok, text) {
                (true, None) => Settled::Value(None),
                (true, Some(Ok(t))) => Settled::Value(Some(t)),
                (true, Some(Err(_))) => Settled::TooLarge,
                (false, Some(Ok(t))) => Settled::Error(t),
                // The prelude caps an error's texts at 64 KiB each, so its
                // description always fits; this only guards that promise.
                (false, _) => Settled::Error(String::new()),
            };
            s.borrow_mut().settled = Some(settled);
            Ok(())
        }),
    )?;
    Ok(b)
}

/// Loads the prelude and returns its hooks.
fn load_prelude<'js>(ctx: &Ctx<'js>, st: &St, shared: &Arc<Shared>) -> Result<Object<'js>, String> {
    let b = bridge(ctx, st, shared).map_err(|e| format!("bridge: {e}"))?;
    let mut opts = EvalOptions::default();
    opts.global = true;
    opts.strict = true;
    opts.filename = Some("prelude.js".into());
    let f: Function = ctx
        .eval_with_options(PRELUDE, opts)
        .map_err(|e| describe_rust_error(ctx, e))?;
    let hooks: Object = f.call((b,)).map_err(|e| describe_rust_error(ctx, e))?;
    Ok(hooks)
}

fn describe_rust_error(ctx: &Ctx<'_>, e: rquickjs::Error) -> String {
    if matches!(e, rquickjs::Error::Exception) {
        let v = ctx.catch();
        if let Some(ex) = v.as_exception() {
            return format!("{}\n{}", ex.message().unwrap_or_default(), ex.stack().unwrap_or_default());
        }
        return format!("{v:?}");
    }
    e.to_string()
}

/// Runs one pending job. `None` when there was none; `Some(Err(v))` when
/// the job threw `v`.
fn run_job<'js>(ctx: &Ctx<'js>) -> Option<Result<(), Value<'js>>> {
    let mut job_ctx = std::ptr::null_mut();
    // SAFETY: the runtime belongs to this context; job_ctx is an out-pointer.
    let rc = unsafe {
        let rt = qjs::JS_GetRuntime(ctx.as_raw().as_ptr());
        qjs::JS_ExecutePendingJob(rt, &mut job_ctx)
    };
    match rc {
        0 => None,
        r if r > 0 => Some(Ok(())),
        _ => Some(Err(ctx.catch())),
    }
}

/// One script execution, from `init` to `done`.
pub struct Session<'js> {
    ctx: Ctx<'js>,
    hooks: Object<'js>,
    st: St,
    shared: Arc<Shared>,
    /// Description of the last exception that stopped the script, used to
    /// locate where an abort happened.
    last_exception: Option<Json>,
    stalled: bool,
    violation: Option<String>,
}

/// What `main` does once a session ends.
pub enum Finish {
    /// `done` was written. Exit 0.
    Done,
    /// The host broke the protocol; `done` with kind `internal` was written.
    /// Exit 1.
    Violation,
}

impl Finish {
    /// Process exit code for this ending.
    pub fn exit_code(&self) -> i32 {
        match self {
            Finish::Done => 0,
            Finish::Violation => 1,
        }
    }
}

impl<'js> Session<'js> {
    pub fn new(ctx: Ctx<'js>, shared: Arc<Shared>) -> Result<Session<'js>, String> {
        let st: St = Rc::new(RefCell::new(State::new()));
        let hooks = load_prelude(&ctx, &st, &shared)?;
        Ok(Session {
            ctx,
            hooks,
            st,
            shared,
            last_exception: None,
            stalled: false,
            violation: None,
        })
    }

    /// Runs the session against host frames from `rx`.
    pub fn run(mut self, rx: &Receiver<Event>) -> Finish {
        // init
        let init = match self.next_frame(rx) {
            Some(HostFrame::Init(init)) => init,
            Some(HostFrame::Cancel) => return self.finish_cancelled_early(),
            Some(_) => return self.violate("expected init"),
            None => return self.violate_pending(),
        };
        if let Err(e) = self.apply_init(init) {
            return self.internal(&e);
        }
        // exec
        let code = match self.next_frame(rx) {
            Some(HostFrame::Exec { code }) => code,
            Some(HostFrame::Cancel) => return self.finish_cancelled_early(),
            Some(_) => return self.violate("expected exec"),
            None => return self.violate_pending(),
        };
        self.start(code);
        self.event_loop(rx);
        self.finish()
    }

    fn next_frame(&mut self, rx: &Receiver<Event>) -> Option<HostFrame> {
        match rx.recv() {
            Ok(Event::Frame(f)) => Some(f),
            Ok(Event::Violation(v)) => {
                self.violation = Some(v);
                None
            }
            Err(_) => None,
        }
    }

    fn apply_init(&mut self, init: Init) -> Result<(), String> {
        let Init {
            limits,
            catalog,
            store,
        } = init;
        self.shared.heap.set_limit(limits.heap_bytes as usize);
        // Runtime methods take the runtime lock, which `Context::with`
        // already holds; set the stack limit through the raw API instead.
        // SAFETY: the runtime is alive for as long as this context.
        unsafe {
            let rt = qjs::JS_GetRuntime(self.ctx.as_raw().as_ptr());
            qjs::JS_SetMaxStackSize(rt, limits.stack_bytes as _);
        }
        let mut catalog_json = Vec::with_capacity(catalog.len());
        for e in &catalog {
            let mut m = serde_json::Map::new();
            m.insert("id".into(), e.id.clone().into());
            m.insert("name".into(), e.name.clone().into());
            m.insert("namespace".into(), e.namespace.clone().into());
            m.insert("description".into(), e.description.clone().into());
            catalog_json.push(Json::Object(m));
        }
        let mut store_obj = serde_json::Map::new();
        {
            let mut st = self.st.borrow_mut();
            for (k, v) in &store {
                let parsed: Json = serde_json::from_str(v).map_err(|e| e.to_string())?;
                // The host counts a stored value as its saved JSON, which is
                // Dart's encoding; measure it the same way.
                let size = crate::hostjson::dart_len(&parsed);
                st.store_sizes.insert(k.clone(), size);
                st.store_total += size;
                store_obj.insert(k.clone(), parsed);
            }
            st.limits = Some(limits);
        }
        let init_fn: Function = self.hooks.get("init").map_err(|e| e.to_string())?;
        let r: rquickjs::Result<()> = init_fn.call((
            Json::Array(catalog_json).to_string(),
            Json::Object(store_obj).to_string(),
        ));
        r.map_err(|e| describe_rust_error(&self.ctx, e))
    }

    fn start(&mut self, code: String) {
        {
            let mut st = self.st.borrow_mut();
            st.exec_start = Some(Instant::now());
            st.cpu_start_ns = thread_cpu_ns();
            let budget_ns = st.limits().cpu_ms.saturating_mul(1_000_000);
            self.shared
                .cpu_deadline_ns
                .store(st.cpu_start_ns.saturating_add(budget_ns).max(1), Ordering::Relaxed);
            let process_start = process_cpu_ns();
            self.shared.cpu_budget_ms.store(st.limits().cpu_ms, Ordering::SeqCst);
            self.shared.heap_budget_bytes.store(st.limits().heap_bytes, Ordering::SeqCst);
            self.shared.exec_process_cpu_ns.store(process_start, Ordering::SeqCst);
            self.shared.watchdog_deadline_ns.store(
                process_start
                    .saturating_add(budget_ns)
                    .saturating_add(crate::watchdog::CPU_GRACE_NS),
                Ordering::SeqCst,
            );
        }
        self.shared.heap.reset_peak();
        self.st.borrow_mut().script = Some(Script::new(code));
        let run: rquickjs::Result<Function> = self.hooks.get("run");
        let r = run.and_then(|f| f.call::<_, ()>(()));
        if let Err(e) = r {
            self.on_exception(e);
        }
    }

    /// Records an exception that escaped into Rust. Aborts carry their own
    /// reason; anything else is the script failing.
    fn on_exception(&mut self, e: rquickjs::Error) {
        let v = if matches!(e, rquickjs::Error::Exception) {
            self.ctx.catch()
        } else {
            self.violation_internal(&e.to_string());
            return;
        };
        self.on_thrown(v);
    }

    fn on_thrown(&mut self, v: Value<'js>) {
        if self.shared.should_stop() {
            // The value is the uncatchable error the runner or QuickJS
            // created; reading it runs no script code, but bound it anyway.
            let grace = thread_cpu_ns().saturating_add(GRACE_NS);
            self.shared.grace_deadline_ns.store(grace, Ordering::Relaxed);
            self.last_exception = self.describe(v);
            self.shared.grace_deadline_ns.store(0, Ordering::Relaxed);
            return;
        }
        let desc = self.describe(v);
        if self.shared.should_stop() {
            return;
        }
        let mut st = self.st.borrow_mut();
        if st.settled.is_none() {
            st.settled = Some(Settled::Error(desc.map(|d| d.to_string()).unwrap_or_default()));
        }
    }

    fn describe(&self, v: Value<'js>) -> Option<Json> {
        let f: Function = self.hooks.get("describe").ok()?;
        let s: String = f.call((v,)).ok()?;
        serde_json::from_str(&s).ok()
    }

    fn violation_internal(&mut self, text: &str) {
        let mut st = self.st.borrow_mut();
        if st.settled.is_none() {
            let mut m = serde_json::Map::new();
            m.insert("name".into(), "InternalError".into());
            m.insert("message".into(), text.into());
            st.settled = Some(Settled::Error(Json::Object(m).to_string()));
        }
    }

    fn done(&self) -> bool {
        self.st.borrow().settled.is_some() || self.shared.should_stop() || self.violation.is_some()
    }

    fn event_loop(&mut self, rx: &Receiver<Event>) {
        loop {
            while let Ok(ev) = rx.try_recv() {
                self.handle(ev);
            }
            if self.done() {
                return;
            }
            let mut ran = 0;
            while ran < JOB_BATCH {
                match run_job(&self.ctx) {
                    None => break,
                    Some(Ok(())) => ran += 1,
                    Some(Err(v)) => {
                        ran += 1;
                        self.on_thrown(v);
                    }
                }
                if self.done() {
                    return;
                }
            }
            if ran > 0 {
                continue;
            }
            if self.fire_due_timers() {
                continue;
            }
            let (idle, next_timer) = {
                let st = self.st.borrow();
                (
                    st.pending.is_empty() && st.timers.is_empty(),
                    st.timers.keys().next().map(|(at, _)| *at),
                )
            };
            if idle {
                self.stalled = true;
                return;
            }
            let ev = match next_timer {
                Some(at) => match rx.recv_timeout(at.saturating_duration_since(Instant::now())) {
                    Ok(ev) => ev,
                    Err(RecvTimeoutError::Timeout) => continue,
                    Err(RecvTimeoutError::Disconnected) => return,
                },
                None => match rx.recv() {
                    Ok(ev) => ev,
                    Err(_) => return,
                },
            };
            self.handle(ev);
            if self.done() {
                return;
            }
        }
    }

    fn fire_due_timers(&mut self) -> bool {
        let now = Instant::now();
        let due: Vec<u64> = {
            let mut st = self.st.borrow_mut();
            let due: Vec<(Instant, u64)> = st
                .timers
                .range(..=(now, u64::MAX))
                .map(|(k, _)| *k)
                .collect();
            for k in &due {
                st.timers.remove(k);
                st.timer_deadlines.remove(&k.1);
            }
            due.into_iter().map(|(_, id)| id).collect()
        };
        if due.is_empty() {
            return false;
        }
        let fire: Function = match self.hooks.get("fireTimer") {
            Ok(f) => f,
            Err(e) => {
                self.violation_internal(&e.to_string());
                return true;
            }
        };
        for id in due {
            if let Err(e) = fire.call::<_, ()>((id as f64,)) {
                self.on_exception(e);
            }
            if self.done() {
                break;
            }
        }
        true
    }

    fn handle(&mut self, ev: Event) {
        match ev {
            Event::Violation(v) => self.violation = Some(v),
            Event::Frame(HostFrame::Cancel) => self.shared.set_abort(Abort::Cancelled),
            Event::Frame(HostFrame::Result(r)) => self.deliver(r),
            Event::Frame(HostFrame::Init(_)) => self.violation = Some("unexpected init".into()),
            Event::Frame(HostFrame::Exec { .. }) => {
                self.violation = Some("only one exec per process".into())
            }
        }
    }

    fn deliver(&mut self, r: CallResult) {
        {
            let mut st = self.st.borrow_mut();
            if !st.pending.remove(&r.id) {
                drop(st);
                self.violation = Some(format!("result for unknown call id {}", r.id));
                return;
            }
            st.credit_ms = st.credit_ms.saturating_add(r.credit_ms);
        }
        let settle: Function = match self.hooks.get("settleCall") {
            Ok(f) => f,
            Err(e) => return self.violation_internal(&e.to_string()),
        };
        let res = match r.outcome {
            Ok(payload) => settle.call::<_, ()>((r.id as f64, true, payload, rquickjs::Undefined)),
            Err((message, Some(status))) => settle.call::<_, ()>((r.id as f64, false, message, status)),
            Err((message, None)) => settle.call::<_, ()>((r.id as f64, false, message, rquickjs::Undefined)),
        };
        if let Err(e) = res {
            self.on_exception(e);
        }
    }

    fn stats(&self) -> Stats {
        let st = self.st.borrow();
        Stats {
            cpu_ms: if st.exec_start.is_some() { st.cpu_used_ms() } else { 0 },
            peak_heap_bytes: self.shared.heap.peak() as u64,
            calls: st.calls,
            output_chars: st.output_chars,
            output_items: st.output_items,
        }
    }

    fn located(&self, kind: ErrorKind, name: &str, message: String) -> ScriptError {
        let (stack, line, column) = match &self.last_exception {
            Some(d) => (
                d["stack"].as_str().unwrap_or("").to_string(),
                d["line"].as_u64(),
                d["column"].as_u64(),
            ),
            None => (String::new(), None, None),
        };
        ScriptError {
            kind,
            name: name.into(),
            message,
            stack,
            line,
            column,
        }
    }

    fn finish(self) -> Finish {
        if let Some(v) = self.violation.clone() {
            return self.violate(&v);
        }
        let stats = self.stats();
        let limits = self.st.borrow().limits().clone();
        let abort = self.shared.ending(self.shared.cpu_over_budget());
        let (value, error) = match abort {
            Abort::Exit => (None, None),
            Abort::Cpu => (None, Some(self.located(
                ErrorKind::CpuExceeded,
                "CpuLimitExceeded",
                format!("The script used more than its {} ms CPU budget", limits.cpu_ms),
            ))),
            Abort::Cancelled => (None, Some(self.located(
                ErrorKind::Cancelled,
                "Cancelled",
                "The script was cancelled".into(),
            ))),
            Abort::Output => {
                let msg = self.shared.output_message.lock().unwrap_or_else(|e| e.into_inner()).clone();
                (None, Some(self.located(ErrorKind::OutputExceeded, "OutputLimitExceeded", msg)))
            }
            Abort::Memory => (None, Some(self.located(
                ErrorKind::MemoryExceeded,
                "MemoryLimitExceeded",
                format!("The script exceeded its heap limit of {} bytes", limits.heap_bytes),
            ))),
            Abort::None => self.settled_outcome(),
        };
        write_done(&done_frame(value, error.as_ref(), stats), Finish::Done.exit_code());
        Finish::Done
    }

    fn settled_outcome(&self) -> (Option<Json>, Option<ScriptError>) {
        let st = self.st.borrow();
        match &st.settled {
            Some(Settled::Value(None)) => (None, None),
            Some(Settled::TooLarge) => (None, Some(ScriptError {
                kind: ErrorKind::OutputExceeded,
                name: "OutputLimitExceeded".into(),
                message: format!("The return value exceeds {MAX_ITEM_BYTES} bytes"),
                stack: String::new(),
                line: None,
                column: None,
            })),
            Some(Settled::Value(Some(json))) => {
                if json.len() > MAX_ITEM_BYTES {
                    return (None, Some(ScriptError {
                        kind: ErrorKind::OutputExceeded,
                        name: "OutputLimitExceeded".into(),
                        message: format!("The return value exceeds {MAX_ITEM_BYTES} bytes"),
                        stack: String::new(),
                        line: None,
                        column: None,
                    }));
                }
                match serde_json::from_str::<Json>(json) {
                    Ok(v) => (Some(v), None),
                    Err(e) => (None, Some(ScriptError {
                        kind: ErrorKind::ScriptError,
                        name: "TypeError".into(),
                        message: format!("The return value cannot be encoded as JSON: {e}"),
                        stack: String::new(),
                        line: None,
                        column: None,
                    })),
                }
            }
            Some(Settled::Error(desc)) => {
                let d: Json = serde_json::from_str(desc).unwrap_or(Json::Null);
                (None, Some(ScriptError {
                    kind: ErrorKind::ScriptError,
                    name: d["name"].as_str().unwrap_or("Error").to_string(),
                    message: d["message"].as_str().unwrap_or("").to_string(),
                    stack: d["stack"].as_str().unwrap_or("").to_string(),
                    line: d["line"].as_u64(),
                    column: d["column"].as_u64(),
                }))
            }
            None if self.stalled => (None, Some(ScriptError {
                kind: ErrorKind::Stalled,
                name: "Stalled".into(),
                message: "The script is waiting on a promise that can never settle: no tool call, timer or job is pending".into(),
                stack: String::new(),
                line: None,
                column: None,
            })),
            None => (None, Some(ScriptError {
                kind: ErrorKind::Internal,
                name: "InternalError".into(),
                message: "The script ended without a result".into(),
                stack: String::new(),
                line: None,
                column: None,
            })),
        }
    }

    fn finish_cancelled_early(self) -> Finish {
        let e = ScriptError {
            kind: ErrorKind::Cancelled,
            name: "Cancelled".into(),
            message: "The script was cancelled before it started".into(),
            stack: String::new(),
            line: None,
            column: None,
        };
        write_done(&done_frame(None, Some(&e), Stats::default()), Finish::Done.exit_code());
        Finish::Done
    }

    fn violate_pending(self) -> Finish {
        let v = self
            .violation
            .clone()
            .unwrap_or_else(|| "stdin closed".into());
        self.violate(&v)
    }

    fn violate(self, text: &str) -> Finish {
        let stats = self.stats();
        let e = ScriptError {
            kind: ErrorKind::Internal,
            name: "ProtocolError".into(),
            message: format!("Host protocol violation: {text}"),
            stack: String::new(),
            line: None,
            column: None,
        };
        write_done(&done_frame(None, Some(&e), stats), Finish::Violation.exit_code());
        Finish::Violation
    }

    fn internal(self, text: &str) -> Finish {
        let e = ScriptError {
            kind: ErrorKind::Internal,
            name: "InternalError".into(),
            message: text.into(),
            stack: String::new(),
            line: None,
            column: None,
        };
        write_done(&done_frame(None, Some(&e), Stats::default()), Finish::Done.exit_code());
        Finish::Done
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn shared() -> Arc<Shared> {
        Shared::new(Arc::new(AtomicBool::new(false)))
    }

    /// The watchdog's reason follows the interrupt check: what was recorded
    /// first, else cancel, then an exhausted heap, then CPU; never the
    /// script's own ending.
    #[test]
    fn stop_reason_follows_the_interrupt_check() {
        let s = shared();
        assert_eq!(s.stop_reason(), Abort::Cpu);
        let mut a = crate::alloc::LimitedAllocator::new(s.heap.clone());
        assert!(rquickjs::allocator::Allocator::alloc(&mut a, 1 << 40).is_null());
        assert_eq!(s.stop_reason(), Abort::Memory);
        s.cancel.store(true, Ordering::SeqCst);
        assert_eq!(s.stop_reason(), Abort::Cancelled);
        s.set_abort(Abort::Output);
        assert_eq!(s.stop_reason(), Abort::Output);

        for (cancel, exhaust, expect) in [
            (false, false, Abort::Cpu),
            (true, false, Abort::Cancelled),
            (false, true, Abort::Memory),
        ] {
            let s = shared();
            s.set_abort(Abort::Exit);
            s.cancel.store(cancel, Ordering::SeqCst);
            if exhaust {
                let mut a = crate::alloc::LimitedAllocator::new(s.heap.clone());
                assert!(rquickjs::allocator::Allocator::alloc(&mut a, 1 << 40).is_null());
            }
            assert_eq!(s.stop_reason(), expect);
        }
    }

    /// The script's own ending (`exit()` or settling) stands only when no
    /// cancel, exhausted heap or CPU overrun came before it actually
    /// stopped; a recorded limit always stands.
    #[test]
    fn a_script_cannot_choose_a_milder_ending() {
        for own in [Abort::None, Abort::Exit] {
            let s = shared();
            if own == Abort::Exit {
                s.set_abort(Abort::Exit);
            }
            assert_eq!(s.ending(false), own);
            assert_eq!(s.ending(true), Abort::Cpu);
            s.cancel.store(true, Ordering::SeqCst);
            assert_eq!(s.ending(false), Abort::Cancelled);
        }
        let s = shared();
        s.set_abort(Abort::Output);
        s.cancel.store(true, Ordering::SeqCst);
        assert_eq!(s.ending(true), Abort::Output);
    }

    #[test]
    fn first_abort_reason_wins() {
        let s = shared();
        assert!(!s.should_stop());
        s.set_abort(Abort::Cpu);
        s.set_abort(Abort::Cancelled);
        assert_eq!(s.abort(), Abort::Cpu);
        assert!(s.should_stop());
    }

    #[test]
    fn cancel_flag_stops_as_cancelled() {
        let s = shared();
        s.cancel.store(true, Ordering::SeqCst);
        assert!(s.should_stop());
        assert_eq!(s.abort(), Abort::Cancelled);
    }

    #[test]
    fn cpu_deadline_stops_as_cpu() {
        let s = shared();
        s.cpu_deadline_ns.store(1, Ordering::Relaxed);
        assert!(s.should_stop());
        assert_eq!(s.abort(), Abort::Cpu);
    }

    #[test]
    fn grace_lets_the_runner_read_an_error() {
        let s = shared();
        s.set_abort(Abort::Output);
        s.grace_deadline_ns
            .store(thread_cpu_ns() + 10_000_000_000, Ordering::Relaxed);
        assert!(!s.should_stop());
        s.grace_deadline_ns.store(0, Ordering::Relaxed);
        assert!(s.should_stop());
    }

    #[test]
    fn prelude_loads_and_keeps_the_bridge_private() {
        let s = shared();
        let (_rt, ctx) = new_runtime(&s).unwrap();
        ctx.with(|ctx| {
            let session = Session::new(ctx.clone(), s.clone()).unwrap();
            let checks: Vec<bool> = ctx
                .eval(
                    r#"[
                    typeof bridge === 'undefined',
                    typeof hooks === 'undefined',
                    typeof tools === 'object',
                    typeof text === 'function',
                    Object.isFrozen(Array.prototype),
                    Object.isFrozen(console),
                    !('prepareStackTrace' in Error),
                    Object.getOwnPropertyDescriptor(globalThis, 'JSON').writable === false,
                    Object.isExtensible(globalThis),
                ]"#,
                )
                .unwrap();
            assert!(checks.iter().all(|c| *c), "{checks:?}");
            let keys: Vec<String> = ctx
                .eval::<Vec<String>, _>("Object.keys(globalThis)")
                .unwrap();
            assert!(keys.is_empty(), "script globals are not enumerable: {keys:?}");
            drop(session);
        });
    }

    #[test]
    fn describe_reads_errors() {
        let s = shared();
        let (_rt, ctx) = new_runtime(&s).unwrap();
        ctx.with(|ctx| {
            let session = Session::new(ctx.clone(), s.clone()).unwrap();
            let err: Value = ctx
                .eval("(() => { try { new (async function () {}).constructor('let a = 1;\\nnull.x')().catch(() => {}); } catch (e) {} return new Error('x') })()")
                .unwrap();
            let d = session.describe(err).unwrap();
            assert_eq!(d["name"], "Error");
            assert_eq!(d["message"], "x");
            drop(session);
        });
    }
}
