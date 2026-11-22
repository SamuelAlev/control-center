//! Wire protocol: newline-delimited JSON on stdio. README.md is the
//! specification; this module parses host frames strictly and builds runner
//! frames with serde_json, so script-controlled text is always escaped.

use serde_json::{Map, Value};

/// Protocol version announced in `ready` and by `--version`. 2: `init.limits`
/// requires `return_budget_chars`, and scripts have `history`, `outputs`,
/// `loadOutput` and `keep`.
pub const PROTOCOL_VERSION: u64 = 2;

/// Largest frame in either direction, newline excluded.
pub const MAX_FRAME_BYTES: usize = 8 * 1024 * 1024;

/// Largest serialized value carried inside one runner frame (a return value,
/// an output item). Leaves room for the frame's own fields.
pub const MAX_ITEM_BYTES: usize = MAX_FRAME_BYTES - 64 * 1024;

/// Largest stack size a host may request; the interpreter thread has 8 MiB.
pub const MAX_STACK_BYTES: u64 = 4 * 1024 * 1024;

/// Smallest heap that still fits the prelude and a trivial script.
pub const MIN_HEAP_BYTES: u64 = 4 * 1024 * 1024;

/// Largest interpreter CPU budget a host may request: the plan's 120 s
/// ceiling, below the kernel backstop.
pub const MAX_CPU_MS: u64 = 120_000;

/// Longest `store()` key, in UTF-8 bytes. The host applies the same rule
/// (`CodeModeStoreRules` in cc_domain) when it persists a write, so a key the
/// runner accepts is never refused later.
pub const MAX_STORE_KEY_BYTES: usize = 512;

/// Limits from `init.limits`. Wall clock is the host's to enforce; the
/// runner only reports what is left of it through `limits()`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Limits {
    pub wall_ms: u64,
    pub cpu_ms: u64,
    pub heap_bytes: u64,
    pub stack_bytes: u64,
    pub max_calls: u64,
    pub max_call_args_bytes: u64,
    pub max_output_chars: u64,
    pub max_output_items: u64,
    pub store_value_bytes: u64,
    pub store_total_bytes: u64,
    /// How many characters of output the script's result keeps whole (the
    /// host's budget, not a runner limit): `limits().returnBudgetChars`.
    pub return_budget_chars: u64,
}

/// One entry of `init.catalog`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct CatalogEntry {
    pub id: String,
    pub name: String,
    pub namespace: String,
    pub description: String,
}

/// Contents of `init`.
#[derive(Clone, Debug)]
pub struct Init {
    pub limits: Limits,
    pub catalog: Vec<CatalogEntry>,
    /// Stored values as JSON text, by key.
    pub store: Vec<(String, String)>,
}

/// A frame from the host.
#[derive(Clone, Debug)]
pub enum HostFrame {
    Init(Init),
    Exec { code: String },
    Result(CallResult),
    Cancel,
}

/// Contents of `result`.
#[derive(Clone, Debug, PartialEq)]
pub struct CallResult {
    pub id: u64,
    /// `Ok(json text)` for `ok: true`; `Err((message, status))` otherwise.
    pub outcome: Result<String, (String, Option<String>)>,
    pub credit_ms: u64,
}

fn obj<'a>(v: &'a Value, what: &str) -> Result<&'a Map<String, Value>, String> {
    v.as_object().ok_or_else(|| format!("{what} must be an object"))
}

fn uint(m: &Map<String, Value>, key: &str, what: &str) -> Result<u64, String> {
    m.get(key)
        .and_then(Value::as_u64)
        .ok_or_else(|| format!("{what}.{key} must be a non-negative integer"))
}

fn string(m: &Map<String, Value>, key: &str, what: &str) -> Result<String, String> {
    m.get(key)
        .and_then(Value::as_str)
        .map(str::to_string)
        .ok_or_else(|| format!("{what}.{key} must be a string"))
}

fn parse_limits(v: &Value) -> Result<Limits, String> {
    let m = obj(v, "init.limits")?;
    let w = "init.limits";
    let limits = Limits {
        wall_ms: uint(m, "wall_ms", w)?,
        cpu_ms: uint(m, "cpu_ms", w)?,
        heap_bytes: uint(m, "heap_bytes", w)?,
        stack_bytes: uint(m, "stack_bytes", w)?,
        max_calls: uint(m, "max_calls", w)?,
        max_call_args_bytes: uint(m, "max_call_args_bytes", w)?,
        max_output_chars: uint(m, "max_output_chars", w)?,
        max_output_items: uint(m, "max_output_items", w)?,
        store_value_bytes: uint(m, "store_value_bytes", w)?,
        store_total_bytes: uint(m, "store_total_bytes", w)?,
        return_budget_chars: uint(m, "return_budget_chars", w)?,
    };
    if limits.cpu_ms == 0 || limits.cpu_ms > MAX_CPU_MS {
        return Err(format!("init.limits.cpu_ms must be 1..={MAX_CPU_MS}"));
    }
    if limits.heap_bytes < MIN_HEAP_BYTES || limits.heap_bytes > lockdown::HEAP_CEILING_BYTES {
        return Err(format!(
            "init.limits.heap_bytes must be {MIN_HEAP_BYTES}..={}",
            lockdown::HEAP_CEILING_BYTES
        ));
    }
    if limits.stack_bytes < 64 * 1024 || limits.stack_bytes > MAX_STACK_BYTES {
        return Err(format!("init.limits.stack_bytes must be 65536..={MAX_STACK_BYTES}"));
    }
    if limits.max_call_args_bytes as usize > MAX_ITEM_BYTES {
        return Err(format!("init.limits.max_call_args_bytes must be at most {MAX_ITEM_BYTES}"));
    }
    if limits.store_value_bytes as usize > MAX_ITEM_BYTES {
        return Err(format!("init.limits.store_value_bytes must be at most {MAX_ITEM_BYTES}"));
    }
    Ok(limits)
}

fn parse_init(m: &Map<String, Value>) -> Result<Init, String> {
    let limits = parse_limits(m.get("limits").ok_or("init.limits is missing")?)?;
    let catalog_v = m
        .get("catalog")
        .and_then(Value::as_array)
        .ok_or("init.catalog must be an array")?;
    let mut catalog = Vec::with_capacity(catalog_v.len());
    for (i, e) in catalog_v.iter().enumerate() {
        let what = format!("init.catalog[{i}]");
        let em = obj(e, &what)?;
        catalog.push(CatalogEntry {
            id: string(em, "id", &what)?,
            name: string(em, "name", &what)?,
            namespace: string(em, "namespace", &what)?,
            description: string(em, "description", &what)?,
        });
    }
    let store_m = obj(m.get("store").ok_or("init.store is missing")?, "init.store")?;
    let store = store_m
        .iter()
        .map(|(k, v)| (k.clone(), v.to_string()))
        .collect();
    Ok(Init {
        limits,
        catalog,
        store,
    })
}

fn parse_result(m: &Map<String, Value>) -> Result<CallResult, String> {
    let id = uint(m, "id", "result")?;
    let ok = m
        .get("ok")
        .and_then(Value::as_bool)
        .ok_or("result.ok must be a boolean")?;
    let payload = m.get("payload").ok_or("result.payload is missing")?;
    let credit_ms = match m.get("credit_ms") {
        None | Some(Value::Null) => 0,
        Some(v) => v.as_u64().ok_or("result.credit_ms must be a non-negative integer")?,
    };
    let outcome = if ok {
        Ok(payload.to_string())
    } else {
        let pm = obj(payload, "result.payload")?;
        let message = string(pm, "message", "result.payload")?;
        let status = match pm.get("status") {
            None | Some(Value::Null) => None,
            Some(Value::String(s)) => Some(s.clone()),
            Some(_) => return Err("result.payload.status must be a string".into()),
        };
        Err((message, status))
    };
    Ok(CallResult {
        id,
        outcome,
        credit_ms,
    })
}

/// Parses one line from the host.
pub fn parse_host_frame(line: &str) -> Result<HostFrame, String> {
    let line = well_formed_escapes(line);
    let v: Value = serde_json::from_str(&line).map_err(|e| format!("frame is not JSON: {e}"))?;
    let m = obj(&v, "frame")?;
    let ty = m
        .get("type")
        .and_then(Value::as_str)
        .ok_or("frame.type must be a string")?;
    match ty {
        "init" => Ok(HostFrame::Init(parse_init(m)?)),
        "exec" => Ok(HostFrame::Exec {
            code: string(m, "code", "exec")?,
        }),
        "result" => Ok(HostFrame::Result(parse_result(m)?)),
        "cancel" => Ok(HostFrame::Cancel),
        other => Err(format!("unknown frame type {other:?}")),
    }
}

fn hex4(b: &[u8]) -> Option<u16> {
    let s = std::str::from_utf8(b.get(..4)?).ok()?;
    u16::from_str_radix(s, 16).ok()
}

/// Replaces `\uXXXX` escapes of unpaired UTF-16 surrogates with `\ufffd`,
/// as `String.prototype.toWellFormed` would. JSON allows such escapes (tool
/// results relayed from other servers can contain them) but they have no
/// UTF-8 form, so the parser would otherwise reject the whole frame.
fn well_formed_escapes(line: &str) -> std::borrow::Cow<'_, str> {
    let b = line.as_bytes();
    if !line.contains("\\u") {
        return std::borrow::Cow::Borrowed(line);
    }
    let mut out: Option<String> = None;
    let mut copied = 0usize;
    let mut i = 0usize;
    while i < b.len() {
        if b[i] != b'\\' {
            i += 1;
            continue;
        }
        if b.get(i + 1) != Some(&b'u') {
            // Any other escape is two bytes; skipping both keeps an escaped
            // backslash from being read as the start of a new escape.
            i += 2;
            continue;
        }
        let Some(unit) = hex4(&b[i + 2..]) else {
            i += 2;
            continue;
        };
        match unit {
            0xD800..=0xDBFF => {
                let pair = b.get(i + 6) == Some(&b'\\')
                    && b.get(i + 7) == Some(&b'u')
                    && matches!(b.get(i + 8..).and_then(hex4), Some(0xDC00..=0xDFFF));
                if pair {
                    i += 12;
                    continue;
                }
            }
            0xDC00..=0xDFFF => {}
            _ => {
                i += 6;
                continue;
            }
        }
        let o = out.get_or_insert_with(|| String::with_capacity(line.len()));
        o.push_str(&line[copied..i]);
        o.push_str("\\ufffd");
        i += 6;
        copied = i;
    }
    match out {
        Some(mut o) => {
            o.push_str(&line[copied..]);
            std::borrow::Cow::Owned(o)
        }
        None => std::borrow::Cow::Borrowed(line),
    }
}

/// `ready`.
pub fn ready_frame(engine: &str, runner: &str, lockdown_json: &str) -> String {
    let lockdown: Value =
        serde_json::from_str(lockdown_json).expect("lockdown report is valid JSON");
    let mut m = Map::new();
    m.insert("type".into(), "ready".into());
    m.insert("protocol".into(), PROTOCOL_VERSION.into());
    m.insert("engine".into(), engine.into());
    m.insert("runner".into(), runner.into());
    m.insert("lockdown".into(), lockdown);
    Value::Object(m).to_string()
}

/// `call`. `args_json` was produced by the prelude's captured
/// `JSON.stringify` and is checked by the caller before it gets here. `at`
/// is the call site, `[line, column]` in the script (see `site`), absent
/// when none was found.
pub fn call_frame(id: u64, target: &str, name: &str, args: Value, at: Option<(u64, u64)>) -> String {
    let mut m = Map::new();
    m.insert("type".into(), "call".into());
    m.insert("id".into(), id.into());
    m.insert("target".into(), target.into());
    m.insert("name".into(), name.into());
    m.insert("args".into(), args);
    if let Some((line, column)) = at {
        m.insert("at".into(), Value::Array(vec![line.into(), column.into()]));
    }
    Value::Object(m).to_string()
}

/// `output` with `kind: "text"`.
pub fn text_frame(text: &str) -> String {
    let mut m = Map::new();
    m.insert("type".into(), "output".into());
    m.insert("kind".into(), "text".into());
    m.insert("text".into(), text.into());
    Value::Object(m).to_string()
}

/// `output` with `kind: "log"`.
pub fn log_frame(level: &str, text: &str) -> String {
    let mut m = Map::new();
    m.insert("type".into(), "output".into());
    m.insert("kind".into(), "log".into());
    m.insert("level".into(), level.into());
    m.insert("text".into(), text.into());
    Value::Object(m).to_string()
}

/// `output` with `kind: "image"`.
pub fn image_frame(media_type: &str, data: &str) -> String {
    let mut image = Map::new();
    image.insert("type".into(), "image".into());
    image.insert("mediaType".into(), media_type.into());
    image.insert("data".into(), data.into());
    let mut m = Map::new();
    m.insert("type".into(), "output".into());
    m.insert("kind".into(), "image".into());
    m.insert("image".into(), Value::Object(image));
    Value::Object(m).to_string()
}

/// `store`. `value` is `None` for a deletion.
pub fn store_frame(key: &str, value: Option<Value>) -> String {
    let mut m = Map::new();
    m.insert("type".into(), "store".into());
    m.insert("key".into(), key.into());
    match value {
        Some(v) => {
            m.insert("value".into(), v);
        }
        None => {
            m.insert("delete".into(), true.into());
        }
    }
    Value::Object(m).to_string()
}

/// How a script ended, as `done.error.kind`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ErrorKind {
    ScriptError,
    CpuExceeded,
    MemoryExceeded,
    OutputExceeded,
    Stalled,
    Cancelled,
    Internal,
}

impl ErrorKind {
    pub fn as_str(self) -> &'static str {
        match self {
            ErrorKind::ScriptError => "script_error",
            ErrorKind::CpuExceeded => "cpu_exceeded",
            ErrorKind::MemoryExceeded => "memory_exceeded",
            ErrorKind::OutputExceeded => "output_exceeded",
            ErrorKind::Stalled => "stalled",
            ErrorKind::Cancelled => "cancelled",
            ErrorKind::Internal => "internal",
        }
    }
}

/// `done.error`.
#[derive(Clone, Debug, PartialEq)]
pub struct ScriptError {
    pub kind: ErrorKind,
    pub name: String,
    pub message: String,
    pub stack: String,
    pub line: Option<u64>,
    pub column: Option<u64>,
}

/// `done.stats`.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct Stats {
    pub cpu_ms: u64,
    pub peak_heap_bytes: u64,
    pub calls: u64,
    pub output_chars: u64,
    pub output_items: u64,
}

fn truncate(s: &str, max: usize) -> &str {
    if s.len() <= max {
        return s;
    }
    let mut end = max;
    while !s.is_char_boundary(end) {
        end -= 1;
    }
    &s[..end]
}

/// `done`. `value` is the return value as JSON text, absent for
/// `undefined`. Error texts are capped at 64 KiB each.
pub fn done_frame(value: Option<Value>, error: Option<&ScriptError>, stats: Stats) -> String {
    const TEXT_CAP: usize = 64 * 1024;
    let mut m = Map::new();
    m.insert("type".into(), "done".into());
    m.insert("ok".into(), error.is_none().into());
    if let Some(v) = value {
        m.insert("value".into(), v);
    }
    if let Some(e) = error {
        let mut em = Map::new();
        em.insert("kind".into(), e.kind.as_str().into());
        em.insert("name".into(), truncate(&e.name, TEXT_CAP).into());
        em.insert("message".into(), truncate(&e.message, TEXT_CAP).into());
        em.insert("stack".into(), truncate(&e.stack, TEXT_CAP).into());
        em.insert("line".into(), e.line.map(Value::from).unwrap_or(Value::Null));
        em.insert("column".into(), e.column.map(Value::from).unwrap_or(Value::Null));
        m.insert("error".into(), Value::Object(em));
    }
    let mut sm = Map::new();
    sm.insert("cpu_ms".into(), stats.cpu_ms.into());
    sm.insert("peak_heap_bytes".into(), stats.peak_heap_bytes.into());
    sm.insert("calls".into(), stats.calls.into());
    sm.insert("output_chars".into(), stats.output_chars.into());
    sm.insert("output_items".into(), stats.output_items.into());
    m.insert("stats".into(), Value::Object(sm));
    Value::Object(m).to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn lone_surrogate_escapes_become_replacement_characters() {
        assert_eq!(well_formed_escapes(r#""a\ud800b""#), r#""a\ufffdb""#);
        assert_eq!(well_formed_escapes(r#""\udc00""#), r#""\ufffd""#);
        assert_eq!(well_formed_escapes(r#""\ud83d\ude00""#), r#""\ud83d\ude00""#);
        assert_eq!(well_formed_escapes(r#""\ud83d\u0041""#), r#""\ufffd\u0041""#);
        assert_eq!(well_formed_escapes(r#""\\ud800""#), r#""\\ud800""#);
        assert_eq!(well_formed_escapes(r#""\\\ud800""#), r#""\\\ufffd""#);
        assert_eq!(well_formed_escapes(r#""\ud800"#), r#""\ufffd"#);
        let v: Value = serde_json::from_str(&well_formed_escapes(r#""x\udbff""#)).unwrap();
        assert_eq!(v, "x\u{fffd}");
    }

    fn limits_json() -> &'static str {
        r#"{"wall_ms":300000,"cpu_ms":30000,"heap_bytes":268435456,"stack_bytes":524288,
            "max_calls":500,"max_call_args_bytes":1048576,"max_output_chars":16777216,
            "max_output_items":100000,"store_value_bytes":262144,"store_total_bytes":1048576,
            "return_budget_chars":30400}"#
    }

    #[test]
    fn parses_init() {
        let line = format!(
            r#"{{"type":"init","limits":{},"catalog":[{{"id":"search","name":"search","namespace":"builtin","description":"d"}}],"store":{{"k":[1,2]}}}}"#,
            limits_json()
        );
        match parse_host_frame(&line).unwrap() {
            HostFrame::Init(init) => {
                assert_eq!(init.limits.cpu_ms, 30000);
                assert_eq!(init.catalog.len(), 1);
                assert_eq!(init.store, vec![("k".to_string(), "[1,2]".to_string())]);
            }
            other => panic!("{other:?}"),
        }
    }

    #[test]
    fn rejects_missing_limit() {
        let line = r#"{"type":"init","limits":{"wall_ms":1},"catalog":[],"store":{}}"#;
        assert!(parse_host_frame(line).unwrap_err().contains("cpu_ms"));
    }

    #[test]
    fn rejects_heap_above_ceiling() {
        let limits = limits_json().replace("268435456", "4294967296");
        let line = format!(r#"{{"type":"init","limits":{limits},"catalog":[],"store":{{}}}}"#);
        assert!(parse_host_frame(&line).unwrap_err().contains("heap_bytes"));
    }

    #[test]
    fn parses_results() {
        let ok = parse_host_frame(r#"{"type":"result","id":3,"ok":true,"payload":{"a":1},"credit_ms":40}"#).unwrap();
        match ok {
            HostFrame::Result(r) => {
                assert_eq!(r.id, 3);
                assert_eq!(r.outcome, Ok(r#"{"a":1}"#.to_string()));
                assert_eq!(r.credit_ms, 40);
            }
            other => panic!("{other:?}"),
        }
        let failed = parse_host_frame(
            r#"{"type":"result","id":4,"ok":false,"payload":{"message":"no","status":"denied"}}"#,
        )
        .unwrap();
        match failed {
            HostFrame::Result(r) => {
                assert_eq!(r.outcome, Err(("no".to_string(), Some("denied".to_string()))));
            }
            other => panic!("{other:?}"),
        }
    }

    #[test]
    fn rejects_unknown_type_and_garbage() {
        assert!(parse_host_frame(r#"{"type":"eval"}"#).is_err());
        assert!(parse_host_frame("nope").is_err());
        assert!(parse_host_frame("[]").is_err());
    }

    #[test]
    fn escapes_script_text() {
        let f = text_frame("a\"\n\u{2028}b");
        let v: Value = serde_json::from_str(&f).unwrap();
        assert_eq!(v["text"], "a\"\n\u{2028}b");
        assert!(!f.contains('\n'));
    }

    #[test]
    fn done_frame_shapes() {
        let f = done_frame(None, None, Stats::default());
        let v: Value = serde_json::from_str(&f).unwrap();
        assert_eq!(v["ok"], true);
        assert!(v.get("value").is_none());
        assert!(v.get("error").is_none());
        let e = ScriptError {
            kind: ErrorKind::CpuExceeded,
            name: "n".into(),
            message: "m".into(),
            stack: String::new(),
            line: Some(2),
            column: None,
        };
        let f = done_frame(Some(Value::from(1)), Some(&e), Stats::default());
        let v: Value = serde_json::from_str(&f).unwrap();
        assert_eq!(v["ok"], false);
        assert_eq!(v["error"]["kind"], "cpu_exceeded");
        assert_eq!(v["error"]["line"], 2);
        assert!(v["error"]["column"].is_null());
    }
}
