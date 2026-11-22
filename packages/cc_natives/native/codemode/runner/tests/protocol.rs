//! Starts the built `cc_codemode` with its real lockdown and speaks the wire
//! protocol to it, the way the host does.

use std::io::{BufRead, BufReader, Read, Write};
use std::process::{Child, ChildStdin, ChildStdout, Command, ExitStatus, Stdio};
use std::time::{Duration, Instant};

use serde_json::{json, Value};

const BIN: &str = env!("CARGO_BIN_EXE_cc_codemode");

fn limits() -> Value {
    json!({
        "wall_ms": 300000,
        "cpu_ms": 1500,
        "heap_bytes": 64u64 << 20,
        "stack_bytes": 512u64 << 10,
        "max_calls": 500,
        "max_call_args_bytes": 1u64 << 20,
        "max_output_chars": 1u64 << 20,
        "max_output_items": 1000,
        "store_value_bytes": 1024,
        "store_total_bytes": 4096,
        "return_budget_chars": 30400,
    })
}

fn catalog() -> Value {
    json!([
        {"id": "search", "name": "search", "namespace": "builtin", "description": "Search files"},
        {"id": "read_file", "name": "read_file", "namespace": "builtin", "description": "Read a file"},
        {"id": "mcp__docs__get_page", "name": "mcp__docs__get-page", "namespace": "docs", "description": "Get a page"},
        {"id": "__proto__", "name": "__proto__", "namespace": "odd", "description": "Odd name"},
        {"id": "class", "name": "class", "namespace": "odd", "description": "Keyword name"},
    ])
}

struct Host {
    child: Child,
    stdin: Option<ChildStdin>,
    out: BufReader<ChildStdout>,
    ready: Value,
}

impl Host {
    fn start() -> Host {
        let mut child = Command::new(BIN)
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .env_clear()
            .spawn()
            .expect("spawn cc_codemode");
        let mut err = child.stderr.take().unwrap();
        std::thread::spawn(move || {
            let mut s = String::new();
            let _ = err.read_to_string(&mut s);
            if !s.is_empty() {
                eprintln!("runner stderr: {s}");
            }
        });
        #[cfg(unix)]
        {
            // Watchdog: no test may hang the suite.
            let pid = child.id() as i32;
            std::thread::spawn(move || {
                std::thread::sleep(Duration::from_secs(30));
                // SAFETY: signalling a pid we spawned; harmless if it exited.
                unsafe { libc::kill(pid, libc::SIGKILL) };
            });
        }
        let stdin = child.stdin.take();
        let out = BufReader::new(child.stdout.take().unwrap());
        let mut host = Host {
            child,
            stdin,
            out,
            ready: Value::Null,
        };
        let ready = host.next().expect("ready frame");
        assert_eq!(ready["type"], "ready", "{ready}");
        assert_eq!(ready["lockdown"]["level"], "full", "lockdown not full: {ready}");
        host.ready = ready;
        host
    }

    fn send(&mut self, v: Value) {
        let stdin = self.stdin.as_mut().expect("stdin open");
        let mut line = serde_json::to_vec(&v).unwrap();
        line.push(b'\n');
        let _ = stdin.write_all(&line);
        let _ = stdin.flush();
    }

    fn send_raw(&mut self, bytes: &[u8]) {
        let stdin = self.stdin.as_mut().expect("stdin open");
        let _ = stdin.write_all(bytes);
        let _ = stdin.flush();
    }

    fn next(&mut self) -> Option<Value> {
        let mut line = String::new();
        match self.out.read_line(&mut line) {
            Ok(0) | Err(_) => None,
            Ok(_) => Some(serde_json::from_str(&line).expect("runner frame is JSON")),
        }
    }

    fn init_with(&mut self, limits: Value, store: Value) {
        self.send(json!({"type": "init", "limits": limits, "catalog": catalog(), "store": store}));
    }

    fn exec(&mut self, code: &str) {
        self.send(json!({"type": "exec", "code": code}));
    }

    fn close_stdin(&mut self) {
        self.stdin = None;
    }

    fn wait(mut self) -> ExitStatus {
        self.stdin = None;
        self.child.wait().unwrap()
    }
}

struct Outcome {
    frames: Vec<Value>,
    done: Value,
    status: ExitStatus,
}

impl Outcome {
    fn of_type(&self, t: &str) -> Vec<&Value> {
        self.frames.iter().filter(|f| f["type"] == t).collect()
    }
    fn texts(&self) -> Vec<String> {
        self.of_type("output")
            .iter()
            .map(|f| f["text"].as_str().unwrap_or("").to_string())
            .collect()
    }
    fn kind(&self) -> &str {
        self.done["error"]["kind"].as_str().unwrap_or("")
    }
}

/// Runs `code`, answering every call with `respond(call)` (a `result`
/// frame without id), until `done`.
fn run_with(code: &str, limits: Value, mut respond: impl FnMut(&Value) -> Value) -> Outcome {
    let mut host = Host::start();
    host.init_with(limits, json!({"greeting": "hello"}));
    host.exec(code);
    let mut frames = Vec::new();
    let done = loop {
        let f = host.next().expect("frame before done");
        frames.push(f.clone());
        match f["type"].as_str().unwrap() {
            "call" => {
                let mut r = respond(&f);
                r["type"] = json!("result");
                r["id"] = f["id"].clone();
                host.send(r);
            }
            "done" => break f,
            _ => {}
        }
    };
    let status = host.wait();
    Outcome {
        frames,
        done,
        status,
    }
}

fn echo(call: &Value) -> Value {
    json!({"ok": true, "payload": {"tool": call["name"], "args": call["args"]}})
}

fn run(code: &str) -> Outcome {
    run_with(code, limits(), echo)
}

/// [`limits`] with a 60 s CPU budget, for tests about another limit whose
/// scripts do seconds of native work before they reach it on a slow host
/// (an emulated CPU). The watchdog holds the budget even inside long native
/// calls, so 1.5 s would end them as `cpu_exceeded` there.
fn roomy_cpu() -> Value {
    let mut l = limits();
    l["cpu_ms"] = json!(60000);
    l
}

// ---- Behaviour ------------------------------------------------------------

#[test]
fn ready_reports_engine_and_protocol() {
    let host = Host::start();
    assert_eq!(host.ready["protocol"], 2);
    assert_eq!(host.ready["engine"], "quickjs-ng 0.16.2");
    assert!(host.ready["lockdown"]["controls"].as_array().unwrap().len() >= 2);
    assert!(host.ready["lockdown"]["failed"].as_array().unwrap().is_empty());
}

#[test]
fn returns_a_value() {
    let o = run("const r = await tools.search({ pattern: 'x' }); return { got: r.args.pattern, n: 1 + 1 }");
    assert_eq!(o.done["ok"], true, "{}", o.done);
    assert_eq!(o.done["value"], json!({"got": "x", "n": 2}));
    assert_eq!(o.done["stats"]["calls"], 1);
    assert!(o.status.success());
}

#[test]
fn undefined_return_has_no_value() {
    let o = run("text('only output')");
    assert_eq!(o.done["ok"], true);
    assert!(o.done.get("value").is_none());
}

#[test]
fn output_keeps_call_order() {
    let o = run(
        "console.log('one'); text('two'); await tools.search({}); console.error('three'); text({ four: 4 }); console.info(5, 'six')",
    );
    let outputs: Vec<(String, String)> = o
        .of_type("output")
        .iter()
        .map(|f| {
            (
                f["level"].as_str().unwrap_or(f["kind"].as_str().unwrap()).to_string(),
                f["text"].as_str().unwrap().to_string(),
            )
        })
        .collect();
    assert_eq!(
        outputs,
        vec![
            ("log".into(), "one".into()),
            ("text".into(), "two".into()),
            ("error".into(), "three".into()),
            ("text".into(), "{\n  \"four\": 4\n}".into()),
            ("info".into(), "5 six".into()),
        ]
    );
    // The call frame sits between the second and third output.
    let types: Vec<&str> = o.frames.iter().map(|f| f["type"].as_str().unwrap()).collect();
    assert_eq!(types, vec!["output", "output", "call", "output", "output", "output", "done"]);
}

#[test]
fn partial_output_survives_a_failure() {
    let o = run("text('before'); await tools.search({}); text('after call'); null.boom; text('never')");
    assert_eq!(o.texts(), vec!["before", "after call"]);
    assert_eq!(o.kind(), "script_error");
    assert_eq!(o.done["error"]["name"], "TypeError");
    assert_eq!(o.done["error"]["line"], 1);
}

#[test]
fn line_numbers_refer_to_the_script() {
    let o = run("const a = 1;\nconst b = 2;\n\nfunction f() {\n  throw new RangeError('deep');\n}\nf();");
    assert_eq!(o.done["error"]["name"], "RangeError");
    assert_eq!(o.done["error"]["message"], "deep");
    assert_eq!(o.done["error"]["line"], 5);
    let stack = o.done["error"]["stack"].as_str().unwrap();
    assert!(stack.contains("at f (repl.js:5:"), "{stack}");
    assert!(stack.contains("at repl.js:7:"), "{stack}");
    assert!(!stack.contains("prelude.js"), "{stack}");
    assert!(!stack.contains("<input>"), "{stack}");
}

#[test]
fn syntax_errors_are_mapped() {
    let o = run("const ok = 1;\nconst bad = ;");
    assert_eq!(o.kind(), "script_error");
    assert_eq!(o.done["error"]["name"], "SyntaxError");
    assert_eq!(o.done["error"]["line"], 2);
}

// ---- Call sites -------------------------------------------------------------

/// Each call frame's `at`, or `null` when it has none.
fn sites(o: &Outcome) -> Vec<Value> {
    o.of_type("call").iter().map(|c| c.get("at").cloned().unwrap_or(Value::Null)).collect()
}

/// `[line, column]` of the first `needle` on 1-based `line` of `code`, the
/// column in UTF-16 units (1-based), as `at` carries it.
fn at(code: &str, line: usize, needle: &str) -> Value {
    let text = code.split('\n').nth(line - 1).expect("line");
    let byte = text.find(needle).unwrap_or_else(|| panic!("{needle:?} not on line {line}: {text}"));
    json!([line, text[..byte].encode_utf16().count() + 1])
}

#[test]
fn call_sites_locate_each_call_in_the_script() {
    let code = [
        "await tools.search({});",
        "await Promise.all([tools.search({}), tools.read_file({})]);",
        "await tools",
        "  .search({",
        "    q: 1,",
        "  });",
        "await Promise.all(['a', 'b'].map((f) => tools.read_file({ f })));",
        "async function later() {",
        "  await sleep(0);",
        "  await tools.search({});",
        "}",
        "await later();",
        "function helper() { return tools.read_file({}); }",
        "await helper();",
        "await helper();",
        "const r = tools.search; await r({});",
        "await Reflect.apply(tools.search, undefined, [{}]);",
        "const refused = await Promise.all(['x'].map(tools.read_file)).then(() => 'resolved', (e) => e.message);",
        "await searchTools('files');",
        "await tools['search']({}); await tools.search?.({});",
        "return refused;",
    ]
    .join("\n");
    let o = run(&code);
    assert_eq!(o.done["ok"], true, "{}", o.done);
    // `map` passes three arguments, which a tool function refuses before
    // any frame is written.
    assert_eq!(o.done["value"], "tools.read_file takes one argument object");
    let helper = at(&code, 13, "read_file");
    assert_eq!(
        sites(&o),
        vec![
            at(&code, 1, "search"),
            at(&code, 2, "search"),
            at(&code, 2, "read_file"),
            // A call spread over lines is placed on the callee's name.
            at(&code, 4, "search"),
            at(&code, 7, "read_file"),
            at(&code, 7, "read_file"),
            // After an await: the frame is the resumed function's.
            at(&code, 10, "search"),
            // A helper called from two places: the helper's line, twice.
            helper.clone(),
            helper,
            // Through an alias: the alias's call.
            at(&code, 16, "r({"),
            // Through a native: the script frame that called the native.
            // QuickJS records the last located token of the call, here an
            // argument (README.md, `call`).
            at(&code, 17, "undefined"),
            at(&code, 19, "searchTools"),
            // A computed name: the start of `tools`; an optional call: the
            // member name.
            at(&code, 20, "tools"),
            at(&code, 20, "search?."),
        ]
    );
}

#[test]
fn a_call_site_column_counts_utf16_units_on_the_scripts_own_lines() {
    let code = "const s = 'é€😀'; await tools.search({});\r\nawait tools.search({});\r0; await tools.read_file({});";
    let o = run(code);
    assert_eq!(o.done["ok"], true, "{}", o.done);
    // 11 units, then 4 for é€😀 (9 UTF-8 bytes), then 15: column 31, where
    // QuickJS itself reports byte 36.
    assert_eq!(sites(&o), vec![json!([1, 31]), json!([2, 13]), json!([3, 16])]);
}

#[test]
fn a_script_cannot_hide_or_forge_its_call_sites() {
    let code = [
        "Error.stackTraceLimit = 0;",
        "await tools.search({});",
        "Error.stackTraceLimit = { valueOf() { throw new TypeError('limit'); } };",
        "await tools.search({});",
        "const kept = typeof Error.stackTraceLimit;",
        "Error.stackTraceLimit = 10;",
        "{ const Error = function () { throw new globalThis.Error('shadowed'); }; await tools.search({}); }",
        // Function names in the shapes the engine's own stack lines take.
        "const named = [",
        "  { ['x (<script>:4:1)']: () => tools.search({}) },",
        "  { ['x\\n    at y (<script>:5:1)']: () => tools.search({}) },",
        "  { ['z (repl.js:900:1)\\n    at z (<script>:6:1)']: () => tools.search({}) },",
        "  { ['w (<input>:3:1)']: () => tools.search({}) },",
        "].map((o) => Object.values(o)[0]);",
        "for (const f of named) await f();",
        "await eval('\\n\\n\\n\\ntools.search({})');",
        "await (new Function('\\n\\n\\nreturn tools.search({})'))();",
        "const stack = new Error('after').stack;",
        "return { kept, stack, present: 'prepareStackTrace' in Error };",
    ]
    .join("\n");
    let o = run(&code);
    assert_eq!(o.done["ok"], true, "{}", o.done);
    assert_eq!(
        sites(&o),
        vec![
            // The prelude sets its own frame limit for the capture.
            at(&code, 2, "search"),
            // A limit whose conversion throws is never converted.
            at(&code, 4, "search"),
            // A shadowed Error is not the one the prelude uses.
            at(&code, 7, "search"),
            // A function's name is never read, whatever it looks like: each
            // arrow's own position. A parser of stack strings would take
            // the forged `<script>:L:C` in the first two names instead.
            at(&code, 9, "search"),
            at(&code, 10, "search"),
            at(&code, 11, "search"),
            at(&code, 12, "search"),
            // Code made by eval or Function is not the script: the site is
            // the script's own call that ran it.
            at(&code, 15, "eval"),
            at(&code, 16, "Function"),
        ]
    );
    // The script's own limit is put back, and its errors keep string stacks
    // (unmapped, as a script reads them: line 17 is the engine's 19).
    assert_eq!(o.done["value"]["kept"], "object");
    assert_eq!(o.done["value"]["present"], false);
    let stack = o.done["value"]["stack"].as_str().expect("string stack");
    assert!(stack.contains("(<script>:19:"), "{stack}");
}

#[test]
fn a_call_whose_arguments_hold_a_call_can_share_its_site() {
    let code = [
        "const x = 1, y = 2;",
        "await tools.search({ v: await tools.read_file({ q: x }) });",
        "await tools.search({ v: await tools.read_file({}) });",
        "await tools.search({ v: await tools.read_file({ q: x }), w: y });",
    ]
    .join("\n");
    let o = run(&code);
    assert_eq!(o.done["ok"], true, "{}", o.done);
    // The outer call's last located token is inside the inner call, so both
    // report the same position, unless a later argument is read after it.
    // Calls are written inner first.
    assert_eq!(
        sites(&o),
        vec![
            at(&code, 2, "x"),
            at(&code, 2, "x"),
            at(&code, 3, "read_file"),
            at(&code, 3, "read_file"),
            at(&code, 4, "x"),
            at(&code, 4, "y"),
        ]
    );
}

#[test]
fn calls_the_runtime_makes_have_no_site() {
    let o = run("await Promise.resolve({}).then(tools.search); setTimeout(tools.read_file, 0, {}); await sleep(20);");
    assert_eq!(o.done["ok"], true, "{}", o.done);
    assert_eq!(sites(&o), vec![Value::Null, Value::Null]);
}

#[test]
fn a_script_with_unicode_line_separators_has_no_call_sites() {
    let o = run("await tools.search({});\u{2028}await tools.search({}); // \u{2029}");
    assert_eq!(o.done["ok"], true, "{}", o.done);
    assert_eq!(sites(&o), vec![Value::Null, Value::Null]);
}

#[test]
fn frames_of_evaluated_code_are_not_the_scripts() {
    let o = run("const a = 1;\neval('\\n\\nnull.boom');");
    assert_eq!(o.done["error"]["name"], "TypeError");
    // The error is placed on the script's eval call, not on line 3 of the
    // evaluated code.
    assert_eq!(o.done["error"]["line"], 2);
    let stack = o.done["error"]["stack"].as_str().unwrap();
    assert!(stack.contains("(eval:3:"), "{stack}");
    assert!(stack.contains("repl.js:2:"), "{stack}");
    assert!(!stack.contains("<input>"), "{stack}");
}

#[test]
fn cpu_loop_is_stopped() {
    let start = Instant::now();
    let o = run("let i = 0; try { while (true) { i++ } } catch (e) {} finally { text('finally ran') } return i");
    assert_eq!(o.kind(), "cpu_exceeded", "{}", o.done);
    assert!(o.texts().is_empty(), "catch/finally must not run");
    assert!(o.done["stats"]["cpu_ms"].as_u64().unwrap() >= 1500);
    assert!(start.elapsed() < Duration::from_secs(10));
}

#[test]
fn await_loop_is_stopped() {
    let o = run("while (true) { try { await null } catch (e) {} }");
    assert_eq!(o.kind(), "cpu_exceeded", "{}", o.done);
}

#[test]
fn never_settling_promise_fails_at_once() {
    let start = Instant::now();
    let o = run("await new Promise(() => {})");
    assert_eq!(o.kind(), "stalled", "{}", o.done);
    assert!(start.elapsed() < Duration::from_secs(2));
}

#[test]
fn heap_exhaustion_is_memory_even_when_caught() {
    let o = run_with(
        "const keep = []; for (let round = 0; round < 1000; round++) { try { while (true) keep.push('x'.repeat(65536) + keep.length) } catch (e) { keep.length = 0 } } return 'survived'",
        roomy_cpu(),
        echo,
    );
    assert_eq!(o.kind(), "memory_exceeded", "{}", o.done);
    assert!(o.done.get("value").is_none());
    assert!(o.done["stats"]["peak_heap_bytes"].as_u64().unwrap() >= 60 << 20);
}

#[test]
fn single_huge_allocation_is_memory() {
    let o = run("try { const s = 'y'.repeat(200 * 1024 * 1024); return s.length } catch (e) { return 'caught ' + e.message }");
    assert_eq!(o.kind(), "memory_exceeded", "{}", o.done);
}

#[test]
fn deep_recursion_is_a_catchable_range_error() {
    let o = run("function f(n) { return f(n + 1) + 1 } try { f(0) } catch (e) { return [e.name, e.message] }");
    assert_eq!(o.done["ok"], true, "{}", o.done);
    assert_eq!(o.done["value"], json!(["RangeError", "Maximum call stack size exceeded"]));
}

#[test]
fn output_flood_ends_the_script_even_when_caught() {
    let o = run("for (;;) { try { console.log('flood'.repeat(100)) } catch (e) {} }");
    assert_eq!(o.kind(), "output_exceeded", "{}", o.done);
    assert_eq!(o.of_type("output").len(), 1000);
    assert_eq!(o.done["stats"]["output_items"], 1000);
}

#[test]
fn output_character_cap() {
    let mut l = limits();
    l["max_output_chars"] = json!(10);
    let o = run_with("text('12345'); text('67890'); try { text('x') } catch (e) {} return 1", l, echo);
    assert_eq!(o.kind(), "output_exceeded");
    assert_eq!(o.texts(), vec!["12345", "67890"]);
}

#[test]
fn cancel_ends_a_running_script() {
    let mut host = Host::start();
    host.init_with(limits(), json!({}));
    host.exec("text('started'); while (true) {}");
    let first = host.next().unwrap();
    assert_eq!(first["text"], "started");
    host.send(json!({"type": "cancel"}));
    let done = host.next().unwrap();
    assert_eq!(done["type"], "done");
    assert_eq!(done["error"]["kind"], "cancelled");
    assert!(done["stats"]["cpu_ms"].as_u64().unwrap() < 1500);
    assert!(host.wait().success());
}

#[test]
fn cancel_ends_a_script_waiting_on_a_call() {
    let mut host = Host::start();
    host.init_with(limits(), json!({}));
    host.exec("await tools.search({})");
    let call = host.next().unwrap();
    assert_eq!(call["type"], "call");
    host.send(json!({"type": "cancel"}));
    let done = host.next().unwrap();
    assert_eq!(done["error"]["kind"], "cancelled");
}

#[test]
fn closing_stdin_ends_the_process() {
    let mut host = Host::start();
    host.init_with(limits(), json!({}));
    host.exec("await tools.search({})");
    let call = host.next().unwrap();
    assert_eq!(call["type"], "call");
    let start = Instant::now();
    host.close_stdin();
    assert!(host.next().is_none());
    let status = host.wait();
    assert_eq!(status.code(), Some(5));
    assert!(start.elapsed() < Duration::from_secs(2));
}

#[test]
fn closing_stdin_ends_a_busy_process() {
    let mut host = Host::start();
    host.init_with(limits(), json!({}));
    host.exec("text('go'); while (true) {}");
    assert_eq!(host.next().unwrap()["text"], "go");
    host.close_stdin();
    assert_eq!(host.wait().code(), Some(5));
}

#[test]
fn promise_all_puts_calls_in_flight_together() {
    let mut host = Host::start();
    host.init_with(limits(), json!({}));
    host.exec("const r = await Promise.all([tools.search({ i: 1 }), tools.read_file({ i: 2 }), tools.search({ i: 3 })]); return r.map(x => x.i)");
    let calls: Vec<Value> = (0..3).map(|_| host.next().unwrap()).collect();
    for c in &calls {
        assert_eq!(c["type"], "call", "{c}");
    }
    // Answer out of order.
    for c in calls.iter().rev() {
        host.send(json!({"type": "result", "id": c["id"], "ok": true, "payload": {"i": c["args"]["i"]}}));
    }
    let done = host.next().unwrap();
    assert_eq!(done["value"], json!([1, 2, 3]), "{done}");
}

#[test]
fn failed_results_reject_with_status() {
    let o = run_with(
        "const r = await Promise.allSettled([tools.search({}), tools.read_file({})]); return r.map(x => x.status === 'fulfilled' ? 'ok' : [x.reason.message, x.reason.status, x.reason instanceof Error])",
        limits(),
        |call| {
            if call["name"] == "read_file" {
                json!({"ok": false, "payload": {"message": "Denied by policy", "status": "denied"}})
            } else {
                json!({"ok": true, "payload": 1})
            }
        },
    );
    assert_eq!(o.done["value"], json!(["ok", ["Denied by policy", "denied", true]]), "{}", o.done);
}

#[test]
fn unknown_tools_reject_with_closest_matches() {
    let o = run("try { await tools.serch({}) } catch (e) { return e.message }");
    let msg = o.done["value"].as_str().unwrap();
    assert!(msg.contains("Unknown tool \"serch\""), "{msg}");
    assert!(msg.contains("search"), "{msg}");
    assert!(o.of_type("call").is_empty());
}

#[test]
fn tools_resolve_by_id_and_raw_name() {
    let o = run("await tools.mcp__docs__get_page({ a: 1 }); await tools['mcp__docs__get-page']({ a: 2 }); return 'mcp__docs__get_page' in tools");
    let names: Vec<&str> = o.of_type("call").iter().map(|c| c["name"].as_str().unwrap()).collect();
    assert_eq!(names, vec!["mcp__docs__get-page", "mcp__docs__get-page"]);
    assert_eq!(o.done["value"], true);
}

#[test]
fn host_calls_carry_target_host() {
    let o = run("await searchTools('files', { limit: 3 }); await describeTool('search'); await describeNamespace('builtin'); await models.embed(['a']); await models.rank('q', ['a', 'b'], { top: 1 }); await models.classify(['a'], ['x', 'y']); await history({ start: 2, limit: 5, role: 'tool', tool: ['bash'] }); await outputs({ limit: 3, tool: 'bash' }); await loadOutput('out_abc', { offset: 10 }); await keep({ n: 1 }, 'counts')");
    let calls: Vec<(String, String)> = o
        .of_type("call")
        .iter()
        .map(|c| (c["target"].as_str().unwrap().into(), c["name"].as_str().unwrap().into()))
        .collect();
    let expect: Vec<(String, String)> = [
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
    ]
    .iter()
    .map(|n| ("host".to_string(), n.to_string()))
    .collect();
    assert_eq!(calls, expect);
    assert_eq!(o.of_type("call")[0]["args"], json!({"query": "files", "limit": 3}));
    assert_eq!(o.of_type("call")[4]["args"], json!({"query": "q", "candidates": ["a", "b"], "top": 1}));
    assert_eq!(o.of_type("call")[6]["args"], json!({"start": 2, "limit": 5, "role": "tool", "tool": ["bash"]}));
    assert_eq!(o.of_type("call")[7]["args"], json!({"limit": 3, "tool": "bash"}));
    assert_eq!(o.of_type("call")[8]["args"], json!({"handle": "out_abc", "offset": 10}));
    assert_eq!(o.of_type("call")[9]["args"], json!({"value": {"n": 1}, "label": "counts"}));
}

#[test]
fn all_tools_lists_the_catalog() {
    let o = run("return ALL_TOOLS.map(t => t.id)");
    assert_eq!(o.done["value"], json!(["search", "read_file", "mcp__docs__get_page", "__proto__", "class"]));
}

#[test]
fn call_limits_reject_without_sending() {
    let mut l = limits();
    l["max_calls"] = json!(2);
    l["max_call_args_bytes"] = json!(100);
    let o = run_with(
        "const big = await tools.search({ s: 'x'.repeat(200) }).catch(e => e.name); await tools.search({}); await tools.search({}); const third = await tools.search({}).catch(e => e.message); return [big, third, limits().callsRemaining]",
        l,
        echo,
    );
    assert_eq!(o.of_type("call").len(), 2);
    assert_eq!(o.done["value"][0], "RangeError");
    assert!(o.done["value"][1].as_str().unwrap().contains("limit of 2 calls"));
    assert_eq!(o.done["value"][2], 0);
}

#[test]
fn limits_report_remaining_and_credit() {
    let o = run_with(
        "const a = limits(); await tools.search({}); const b = limits(); return { a, b }",
        limits(),
        |_| json!({"ok": true, "payload": null, "credit_ms": 60000}),
    );
    let a = &o.done["value"]["a"];
    let b = &o.done["value"]["b"];
    assert!(a["wallMsRemaining"].as_u64().unwrap() <= 300000);
    assert!(b["wallMsRemaining"].as_u64().unwrap() > 300000, "{b}");
    assert_eq!(b["callsRemaining"], 499);
    assert!(a["cpuMsRemaining"].as_u64().unwrap() <= 1500);
    assert_eq!(a["outputItemsRemaining"], 1000);
    // The host's return budget, as it sent it; nothing the runner counts.
    assert_eq!(a["returnBudgetChars"], 30400);
    assert!(a.get("outputCharsRemaining").is_none(), "{a}");
}

#[test]
fn stored_keys_list_what_load_reads_with_utf8_sizes() {
    let o = run("const before = storedKeys(); store('z', 'é'); store('a', { v: [1, 2] }); store('greeting', undefined); return [before, storedKeys()]");
    assert_eq!(
        o.done["value"],
        json!([
            [{"key": "greeting", "bytes": 7}],
            [{"key": "a", "bytes": 11}, {"key": "z", "bytes": 4}]
        ]),
        "{}",
        o.done
    );
}

#[test]
fn a_read_only_store_still_lists_and_loads() {
    let mut l = limits();
    l["store_value_bytes"] = json!(0);
    l["store_total_bytes"] = json!(0);
    let o = run_with("let e; try { store('n', 1) } catch (x) { e = x.name } return [storedKeys(), load('greeting'), e]", l, echo);
    assert_eq!(o.done["value"], json!([[{"key": "greeting", "bytes": 7}], "hello", "RangeError"]), "{}", o.done);
    assert!(o.of_type("store").is_empty());
}

#[test]
fn past_calls_refuse_bad_arguments_before_any_call() {
    let o = run("const r = []; for (const f of [() => history(null), () => outputs(3), () => loadOutput(1), () => keep(1, 2)]) { try { await f(); r.push('ok') } catch (e) { r.push(e.name) } } return r");
    assert_eq!(o.done["value"], json!(["TypeError", "TypeError", "TypeError", "TypeError"]), "{}", o.done);
    assert!(o.of_type("call").is_empty());
}

#[test]
fn store_and_load() {
    let o = run("const g = load('greeting'); store('n', { v: [1, 2] }); const n = load('n'); n.v.push(3); store('greeting', undefined); return [g, load('n'), load('greeting') === undefined]");
    assert_eq!(o.done["value"], json!(["hello", {"v": [1, 2]}, true]), "{}", o.done);
    let stores = o.of_type("store");
    assert_eq!(stores.len(), 2);
    assert_eq!(stores[0]["key"], "n");
    assert_eq!(stores[0]["value"], json!({"v": [1, 2]}));
    assert_eq!(stores[1]["key"], "greeting");
    assert_eq!(stores[1]["delete"], true);
}

#[test]
fn store_limits_are_catchable() {
    let o = run("const r = []; try { store('a', 'x'.repeat(2000)) } catch (e) { r.push(e.name) } store('b', 'y'.repeat(1000)); store('c', 'y'.repeat(1000)); store('d', 'y'.repeat(1000)); try { store('e', 'y'.repeat(1000)) } catch (e) { r.push(e.name) } try { store('f', 'y'.repeat(1000)) } catch (e) { r.push(e.name) } return r");
    // 7 bytes stored already + 4 x 1002 exceeds 4096; the fifth write is refused.
    assert_eq!(o.done["value"], json!(["RangeError", "RangeError"]), "{}", o.done);
    assert_eq!(o.of_type("store").len(), 4);
}

#[test]
fn store_keys_are_capped_at_512_utf8_bytes() {
    // 'é' is two bytes, so 257 of them (514 bytes) are refused although the
    // key is only 257 characters long.
    let o = run("const r = []; store('k'.repeat(512), 1); for (const k of ['k'.repeat(513), '\\u00e9'.repeat(257)]) { try { store(k, 1) } catch (e) { r.push([e.name, e.message]) } } return r");
    assert_eq!(
        o.done["value"],
        json!([
            ["RangeError", "Store key is 513 bytes; the limit is 512"],
            ["RangeError", "Store key is 514 bytes; the limit is 512"],
        ]),
        "{}",
        o.done
    );
    let stores = o.of_type("store");
    assert_eq!(stores.len(), 1);
    assert_eq!(stores[0]["key"].as_str().unwrap().len(), 512);
}

#[test]
fn store_operations_are_counted() {
    // Overwriting one key stays within the byte budget, so only the count
    // stops it; deletes count too.
    let o = run("let n = 0; try { for (;;) { store('k', 1); store('k', undefined); n += 2 } } catch (e) { return [n, e.name, e.message] }");
    assert_eq!(
        o.done["value"],
        json!([2000, "RangeError", "This script reached its limit of 2000 store operations"]),
        "{}",
        o.done
    );
    assert_eq!(o.of_type("store").len(), 2000);
}

#[test]
fn bytes_written_are_capped_at_sixteen_times_the_budget() {
    // 1002-byte values, budget 4096: overwriting one key never exceeds the
    // budget, but 16 x 4096 bytes written in all is the end.
    let o = run("let n = 0; try { for (;;) { store('k', 'v'.repeat(1000)); n++ } } catch (e) { return [n, e.name, e.message] }");
    assert_eq!(
        o.done["value"],
        json!([65, "RangeError", "Values written by this script would total 66132 bytes; the limit is 65536 (16 times the store budget)"]),
        "{}",
        o.done
    );
    assert_eq!(o.of_type("store").len(), 65);
}

#[test]
fn deletes_are_refused_when_the_store_is_read_only() {
    let mut l = limits();
    l["store_total_bytes"] = json!(0);
    let o = run_with("try { store('greeting', undefined) } catch (e) { return [e.name, e.message, load('greeting')] }", l, echo);
    assert_eq!(
        o.done["value"],
        json!(["RangeError", "Stored values cannot change in this session; the limit is 0 bytes", "hello"]),
        "{}",
        o.done
    );
    assert!(o.of_type("store").is_empty());
}

#[test]
fn oversized_output_is_refused_by_length() {
    // Escaping makes each control character six bytes: 1.5 M of them fit the
    // character budget but not one frame.
    let mut l = roomy_cpu();
    l["max_output_chars"] = json!(16u64 << 20);
    for code in [
        "text('\\x01'.repeat(1.5e6))",
        "console.log('\\x01'.repeat(1.5e6))",
        "text('x'.repeat(9e6))",
        "text('\\x01'.repeat(5e7))",
    ] {
        let o = run_with(code, l.clone(), echo);
        assert_eq!(o.kind(), "output_exceeded", "{code}: {}", o.done);
        assert!(o.done["error"]["message"].as_str().unwrap().contains("frame limit"), "{code}: {}", o.done);
        assert!(o.of_type("output").is_empty());
    }
    // A string far over the character budget is refused by its length too.
    let o = run("text('x'.repeat(3e6))");
    assert_eq!(o.kind(), "output_exceeded", "{}", o.done);
    assert_eq!(o.done["error"]["message"], "Output exceeded 1048576 characters");
}

#[test]
fn bridge_strings_are_capped_before_copying() {
    let o = run_with(
        r#"
        const r = [];
        for (const f of [
          () => image({ type: 'image', mediaType: 'm'.repeat(3e6), data: '' }),
          () => store('k'.repeat(3e6), 1),
          () => store('k', 'v'.repeat(3e6)),
        ]) { try { f() } catch (e) { r.push(e.message) } }
        return r;
        "#,
        roomy_cpu(),
        echo,
    );
    let v = o.done["value"].as_array().unwrap_or_else(|| panic!("{}", o.done));
    assert_eq!(v[0], "image() media type must be image/png, image/jpeg, image/gif or image/webp");
    assert_eq!(v[1], "Store key is at least 3000000 bytes; the limit is 512");
    assert_eq!(v[2], "Stored value is at least 3000002 bytes; the limit is 1024");
    assert!(o.of_type("call").is_empty() && o.of_type("store").is_empty(), "{}", o.done);
}

#[test]
fn oversized_return_value_is_output_exceeded() {
    let mut l = roomy_cpu();
    l["heap_bytes"] = json!(256u64 << 20);
    let o = run_with("return 'x'.repeat(9e6)", l, echo);
    assert_eq!(o.kind(), "output_exceeded", "{}", o.done);
}

#[test]
fn huge_error_messages_are_capped() {
    let o = run("throw new Error('m'.repeat(1e6))");
    assert_eq!(o.kind(), "script_error", "{}", o.done);
    assert_eq!(o.done["error"]["message"].as_str().unwrap().len(), 65536);
}

/// Scripts whose every step is one long native call reach QuickJS's
/// interrupt poll seconds apart; the watchdog ends them shortly after the
/// budget instead.
#[test]
fn long_native_calls_keep_the_cpu_budget() {
    let mut l = limits();
    l["cpu_ms"] = json!(1000);
    l["heap_bytes"] = json!(1u64 << 30);
    for code in [
        "const a = new Float64Array(6e7); for (let i = 0; i < a.length; i++) a[i] = (i * 7919) % 1000003; a.sort();",
        "for (;;) 'x'.repeat(1e8);",
        "const a = new Uint8Array(2e8); for (;;) a.fill(1);",
        "const a = new Float64Array(3e7); for (;;) a.includes(1);",
    ] {
        let start = Instant::now();
        let o = run_with(code, l.clone(), echo);
        assert_eq!(o.kind(), "cpu_exceeded", "{code}: {}", o.done);
        assert!(o.done["stats"]["cpu_ms"].as_u64().unwrap() < 2000, "{code}: {}", o.done);
        assert!(start.elapsed() < Duration::from_secs(5), "{code}: took {:?}", start.elapsed());
    }
}

/// When the watchdog ends a script stuck in one native call, it reports why
/// the script was stopping, not just that it overran: CPU for a plain
/// overrun, memory when the heap had already run out (sticky even when the
/// script caught it), output when an output limit had been hit. The
/// watchdog's error has no line or stack, which tells it from the
/// interpreter's.
#[test]
fn the_watchdog_reports_the_right_kind_inside_a_long_native_call() {
    let mut l = limits();
    l["cpu_ms"] = json!(1000);
    // One `indexOf` of a 10,000-character needle in a megabyte of the same
    // letter: about 10^10 comparisons in one native call (6 s in a release
    // build), on about a megabyte of heap and next to no preparation, so it
    // outlasts the budget on every machine and the setup does not use it up
    // on an emulated one.
    let search = "const h = 'a'.repeat(1e6), n = 'a'.repeat(1e4) + 'b';";
    for (code, kind, message) in [
        (format!("{search} h.indexOf(n);"), "cpu_exceeded", "The script used more than its 1000 ms CPU budget"),
        (
            format!("{search} try {{ 'y'.repeat(2e8) }} catch (e) {{}} h.indexOf(n);"),
            "memory_exceeded",
            "The script exceeded its heap limit of 67108864 bytes",
        ),
    ] {
        let start = Instant::now();
        let o = run_with(&code, l.clone(), echo);
        assert_eq!(o.kind(), kind, "{}", o.done);
        assert_eq!(o.done["error"]["message"], message, "{}", o.done);
        assert!(o.done["error"]["line"].is_null() && o.done["error"]["stack"] == "", "not the watchdog: {}", o.done);
        assert!(start.elapsed() < Duration::from_secs(10), "took {:?}", start.elapsed());
    }
    // A typed array's sort swallows its comparator's error and finishes
    // sorting natively before it rethrows, so an output limit hit in the
    // comparator leaves the script in a native call; nothing else can, as
    // the refusal is uncatchable. The budget leaves room for the 120 MB the
    // sort sets up before its first comparison (seconds on an emulated CPU,
    // where the rest of the sort then outlasts the budget and the watchdog
    // ends it; elsewhere the sort finishes first and the interpreter does).
    // Either way it ends as output.
    let mut l = limits();
    l["cpu_ms"] = json!(5000);
    l["heap_bytes"] = json!(1u64 << 30);
    let o = run_with(
        "const a = new Uint8Array(1.2e8); a.sort((x, y) => { text('x'.repeat(2e6)); return 0 });",
        l,
        echo,
    );
    assert_eq!(o.kind(), "output_exceeded", "{}", o.done);
    assert_eq!(o.done["error"]["message"], "Output exceeded 1048576 characters", "{}", o.done);
    assert!(o.of_type("output").is_empty());
}

#[test]
fn cancel_ends_long_native_calls() {
    let mut l = limits();
    l["cpu_ms"] = json!(60000);
    l["heap_bytes"] = json!(1u64 << 30);
    for code in [
        // The data is copied in with native `set`, so it is ready in well
        // under the host's 30 s even on an emulated CPU.
        "const b = new Float64Array(1e6); for (let i = 0; i < b.length; i++) b[i] = (i * 7919) % 1000003; const a = new Float64Array(6e7); for (let i = 0; i < 60; i++) a.set(b, i * 1e6); text('ready'); a.sort();",
        "text('ready'); for (;;) 'x'.repeat(1e8);",
    ] {
        let mut host = Host::start();
        host.init_with(l.clone(), json!({}));
        host.exec(code);
        let first = host.next().unwrap();
        assert_eq!(first["type"], "output", "{first}");
        std::thread::sleep(Duration::from_millis(200));
        let sent = Instant::now();
        host.send(json!({"type": "cancel"}));
        let done = host.next().unwrap();
        assert_eq!(done["error"]["kind"], "cancelled", "{done}");
        assert!(sent.elapsed() < Duration::from_secs(1), "cancel took {:?}", sent.elapsed());
        assert!(host.next().is_none(), "a frame followed done");
        assert!(host.wait().success());
    }
}

#[test]
fn local_time_works_inside_the_lockdown() {
    // Local time needs the time zone, which libc would otherwise load from a
    // file after the lockdown (on Linux, a kill by seccomp).
    let o = run("return [new Date(0).getTimezoneOffset(), typeof String(new Date(0)), new Date(2020, 0, 1).getTime() - Date.UTC(2020, 0, 1), new Date(0).toLocaleString().length > 0]");
    let v = &o.done["value"];
    assert_eq!(o.done["ok"], true, "{}", o.done);
    assert_eq!(v[1], "string");
    assert_eq!(v[3], true);
    if cfg!(any(target_os = "linux", target_os = "macos")) {
        // UTC: fixed before confinement on Linux, the sandbox's fallback on macOS.
        assert_eq!(v[0], 0, "{}", o.done);
        assert_eq!(v[2], 0, "{}", o.done);
    }
}

#[test]
fn exit_ends_successfully() {
    let o = run("text('a'); try { exit() } catch (e) { text('caught') } finally { text('finally') } text('b')");
    assert_eq!(o.done["ok"], true, "{}", o.done);
    assert!(o.done.get("error").is_none() && o.done.get("value").is_none(), "{}", o.done);
    assert_eq!(o.texts(), vec!["a"]);
}

/// `exit()` from a typed-array sort's comparator records the script's own
/// ending, but the sort goes on natively without calling the comparator
/// again. What actually stopped the script decides: a CPU overrun or a
/// cancel during the rest of the sort is reported as such, not as success.
#[test]
fn exit_cannot_hide_an_overrun_or_a_cancel() {
    let code = "const a = new Uint8Array(1e8); text('started'); a.sort((x, y) => { exit(); return 0 }); return 'unreachable';";
    // Sorting 10^8 bytes takes a quarter of a second or more after the
    // comparator's one call, far past a 50 ms budget.
    let mut l = limits();
    l["cpu_ms"] = json!(50);
    l["heap_bytes"] = json!(1u64 << 30);
    let o = run_with(code, l, echo);
    assert_eq!(o.kind(), "cpu_exceeded", "{}", o.done);
    assert_eq!(o.done["error"]["message"], "The script used more than its 50 ms CPU budget", "{}", o.done);

    // A cancel sent once the script has started, during the sort.
    let mut l = limits();
    l["cpu_ms"] = json!(60000);
    l["heap_bytes"] = json!(1u64 << 30);
    let mut host = Host::start();
    host.init_with(l, json!({}));
    host.exec(code);
    let first = host.next().unwrap();
    assert_eq!(first["text"], "started", "{first}");
    host.send(json!({"type": "cancel"}));
    let done = host.next().unwrap();
    assert_eq!(done["type"], "done", "{done}");
    assert_eq!(done["error"]["kind"], "cancelled", "{done}");
    assert!(host.wait().success());
}

#[test]
fn timers_run_in_order() {
    let start = Instant::now();
    let o = run("const out = []; setTimeout(() => out.push('b'), 60); setTimeout(() => out.push('a'), 10); const t = setTimeout(() => out.push('never'), 20); clearTimeout(t); await sleep(100); return out");
    assert_eq!(o.done["value"], json!(["a", "b"]), "{}", o.done);
    assert!(start.elapsed() >= Duration::from_millis(100));
}

#[test]
fn image_output() {
    let o = run("const img = { type: 'image', mediaType: 'image/png', data: 'iVBORw0KGgo=' }; image(img); try { image({ type: 'text' }) } catch (e) { return e.name }");
    let out = o.of_type("output");
    assert_eq!(out[0]["kind"], "image");
    assert_eq!(out[0]["image"], json!({"type": "image", "mediaType": "image/png", "data": "iVBORw0KGgo="}));
    assert_eq!(o.done["value"], "TypeError");
}

/// One small file of each type `image()` accepts, as base64: a 1x1 PNG,
/// a JPEG and two GIF and a WEBP header. The host's `imageProblem` accepts
/// each of them (checked against it with the code mode Dart tests).
const IMAGES: [(&str, &str); 5] = [
    ("image/png", "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="),
    ("image/jpeg", "/9j/4AAQSkZJRgABAQ=="),
    ("image/gif", "R0lGODlhAQABAAAAACw="),
    ("image/gif", "R0lGODdhAQABAAAAACw="),
    ("image/webp", "UklGRiQAAABXRUJQVlA4IA=="),
];

/// Runs `image()` on each `[mediaType, data]` pair of the JavaScript
/// expression `cases` and returns, per pair, "ok" or the error's name and
/// message. A refusal is catchable and the script goes on.
fn image_verdicts(cases: &str, limits: Value) -> (Vec<String>, Outcome) {
    let code = format!(
        "const r = []; for (const [mediaType, data] of {cases}) {{ try {{ image({{ type: 'image', mediaType, data }}); r.push('ok') }} catch (e) {{ r.push(e.name + ': ' + e.message) }} }} return r;"
    );
    let o = run_with(&code, limits, echo);
    let v = o.done["value"].as_array().unwrap_or_else(|| panic!("{}", o.done));
    (v.iter().map(|x| x.as_str().unwrap().to_string()).collect(), o)
}

#[test]
fn every_accepted_image_type_goes_through() {
    let cases: Vec<Value> = IMAGES.iter().map(|(t, d)| json!([t, d])).collect();
    let (verdicts, o) = image_verdicts(&json!(cases).to_string(), limits());
    assert_eq!(verdicts, vec!["ok"; IMAGES.len()]);
    let out = o.of_type("output");
    assert_eq!(out.len(), IMAGES.len());
    for (frame, (t, d)) in out.iter().zip(IMAGES) {
        assert_eq!(frame["image"], json!({"type": "image", "mediaType": t, "data": d}));
    }
}

#[test]
fn images_of_other_types_are_a_catchable_type_error() {
    let png = IMAGES[0].1;
    let cases = json!([
        ["image/svg+xml", png], ["image/PNG", png], ["image/jpg", png], ["text/plain", png],
        ["", png], ["image/png ", png], ["image/bmp", png],
    ]);
    let (verdicts, o) = image_verdicts(&cases.to_string(), limits());
    assert_eq!(verdicts.len(), 7);
    for v in &verdicts {
        assert_eq!(v, "TypeError: image() media type must be image/png, image/jpeg, image/gif or image/webp");
    }
    assert!(o.of_type("output").is_empty());
}

#[test]
fn image_data_must_be_strict_base64() {
    let cases = json!([
        // No padding, too much padding, padding inside.
        ["image/png", "iVBORw0KGgo"], ["image/png", "iVBORw0KGgo==="], ["image/png", "iVBO=w0KGgo="],
        ["image/png", "iVBORw0KGgo=iVBORw0KGgo="],
        // Bits after the last byte that are not zero (Dart refuses them).
        ["image/png", "iVBORw0KGgp="],
        // The URL-safe alphabet and percent-encoded padding (both of which
        // Dart's decoder takes), whitespace, non-ASCII: each a multiple of
        // four long.
        ["image/jpeg", "_9j_4AAQ"], ["image/png", "iVBORw0KGgo%3D=="], ["image/png", "iVBORw0K Ggo"],
        ["image/png", "iVBORw0K\nGgo"], ["image/png", "iVBORw0KGgé="],
    ]);
    // Control characters, which would also be too long once escaped for a
    // frame: still the script's catchable mistake.
    let (verdicts, o) = image_verdicts(&format!("{cases}.concat([['image/png', '\\x01'.repeat(1.5e6)]])"), roomy_cpu());
    assert_eq!(verdicts.len(), 11);
    for v in &verdicts {
        assert_eq!(v, "TypeError: image() data must be standard base64: A-Z, a-z, 0-9, + and /, padded with = to a multiple of 4");
    }
    assert!(o.of_type("output").is_empty());
}

#[test]
fn image_size_is_the_hosts_five_mib() {
    // The host: at most (5 MiB + 2) / 3 * 4 characters, then at most 5 MiB
    // decoded. A PNG header, then zero bytes.
    let mut l = roomy_cpu();
    l["max_output_chars"] = json!(16u64 << 20);
    let max_chars = (5 * 1024 * 1024usize).div_ceil(3) * 4;
    let code = format!(
        r#"
        const head = 'iVBORw0KGgoAAAAA';
        const r = [];
        for (const data of [
          // Exactly 5 MiB: 1747627 groups, the last one holding 2 bytes.
          head + 'A'.repeat({max_chars} - head.length - 4) + 'AAA=',
          // One byte more: 1747627 full groups, still {max_chars} characters.
          head + 'A'.repeat({max_chars} - head.length),
          // One group more.
          head + 'A'.repeat({max_chars} - head.length + 4),
        ]) {{ try {{ image({{ type: 'image', mediaType: 'image/png', data }}); r.push('ok ' + data.length) }} catch (e) {{ r.push(e.name + ': ' + e.message) }} }}
        return r;
        "#
    );
    let o = run_with(&code, l, echo);
    let v = o.done["value"].as_array().unwrap_or_else(|| panic!("{}", o.done));
    assert_eq!(v[0], format!("ok {max_chars}"));
    assert_eq!(v[1], "RangeError: image() data decodes to 5242881 bytes; the limit is 5242880");
    assert_eq!(v[2], format!("RangeError: image() data is {} base64 characters; the limit is {max_chars} (5242880 bytes decoded)", max_chars + 4));
    let out = o.of_type("output");
    assert_eq!(out.len(), 1);
    assert_eq!(out[0]["image"]["data"].as_str().unwrap().len(), max_chars);
}

#[test]
fn image_data_must_start_with_its_types_header() {
    let (png, jpeg, gif, webp) = (IMAGES[0].1, IMAGES[1].1, IMAGES[2].1, IMAGES[4].1);
    let cases = json!([
        ["image/png", jpeg], ["image/jpeg", png], ["image/gif", webp], ["image/webp", gif],
        // Headers cut short, an unknown GIF version, RIFF without WEBP.
        ["image/png", "iVBORw0K"], ["image/jpeg", "/9g="], ["image/png", ""],
        ["image/gif", "R0lGODhhAQABAAAAACw="], ["image/webp", "UklGRiQAAABBVkkgTElTVA=="],
    ]);
    let (verdicts, o) = image_verdicts(&cases.to_string(), limits());
    let types = ["image/png", "image/jpeg", "image/gif", "image/webp", "image/png", "image/jpeg", "image/png", "image/gif", "image/webp"];
    for (v, t) in verdicts.iter().zip(types) {
        assert_eq!(v, &format!("TypeError: image() data is not {t}: it does not start with that format's file header"));
    }
    assert_eq!(verdicts.len(), types.len());
    assert!(o.of_type("output").is_empty());
}

#[test]
fn call_names_are_the_hosts_256_bytes_and_never_empty() {
    // An unknown name rejects before the bridge, so the bridge's own rule
    // (the host's: 1 to 256 UTF-8 bytes) is reached through catalog names.
    let mut host = Host::start();
    let long = "n".repeat(256);
    let longer = "é".repeat(129);
    host.send(json!({"type": "init", "limits": limits(), "store": {}, "catalog": [
        {"id": long, "name": long, "namespace": "n", "description": ""},
        {"id": longer, "name": longer, "namespace": "n", "description": ""},
        {"id": "", "name": "", "namespace": "n", "description": ""},
    ]}));
    host.exec(&format!(
        "const r = []; for (const n of ['{long}', '{longer}', '']) {{ try {{ await tools[n]({{}}); r.push('ok') }} catch (e) {{ r.push(e.name + ': ' + e.message) }} }} return r;"
    ));
    let mut calls = Vec::new();
    let done = loop {
        let f = host.next().expect("frame before done");
        match f["type"].as_str().unwrap() {
            "call" => {
                calls.push(f["name"].as_str().unwrap().to_string());
                host.send(json!({"type": "result", "id": f["id"], "ok": true, "payload": null}));
            }
            "done" => break f,
            _ => {}
        }
    };
    assert_eq!(calls, vec![long]);
    assert_eq!(done["value"], json!(["ok", "RangeError: Call name is 258 bytes; the limit is 256", "TypeError: A call name cannot be empty"]), "{done}");
    assert!(host.wait().success());
}

#[test]
fn call_arguments_must_be_an_object() {
    let o = run(
        "const r = []; for (const a of ['str', [1, 2], 3, null, true]) { try { await tools.search(a); r.push('ok') } catch (e) { r.push(e.name + ': ' + e.message) } } await tools.search(); await tools.search({}); return r;",
    );
    assert_eq!(
        o.done["value"],
        json!([
            "TypeError: Call arguments must be a JSON object, not a string",
            "TypeError: Call arguments must be a JSON object, not an array",
            "TypeError: Call arguments must be a JSON object, not a number",
            "TypeError: Call arguments must be a JSON object, not null",
            "TypeError: Call arguments must be a JSON object, not a boolean",
        ]),
        "{}",
        o.done
    );
    let calls = o.of_type("call");
    assert_eq!(calls.len(), 2);
    assert!(calls.iter().all(|c| c["args"] == json!({})));
}

/// The host measures arguments and stored values as Dart re-encodes them.
/// `1e20` is 21 characters in JavaScript's JSON and 23 in Dart's
/// (`100000000000000000000.0`), so 46 of them fit 1024 bytes the first way
/// (1019 or 1013 bytes) and not the second (1111 or 1105).
#[test]
fn sizes_are_measured_as_the_host_measures_them() {
    let mut l = limits();
    l["max_call_args_bytes"] = json!(1024);
    let o = run_with(
        r#"
        const xs = Array(46).fill(1e20);
        const r = [JSON.stringify({ a: xs }).length, JSON.stringify(xs).length];
        try { await tools.search({ a: xs }) } catch (e) { r.push(e.message) }
        try { store('k', xs) } catch (e) { r.push(e.message) }
        await tools.search({ a: xs.slice(0, 42) });
        store('k', xs.slice(0, 42));
        return r;
        "#,
        l,
        echo,
    );
    assert_eq!(
        o.done["value"],
        json!([
            1019,
            1013,
            "Call arguments are 1111 bytes as the host measures them; the limit is 1024",
            "Stored value is 1105 bytes as the host measures it; the limit is 1024",
        ]),
        "{}",
        o.done
    );
    assert_eq!(o.of_type("call").len(), 1);
    assert_eq!(o.of_type("store").len(), 1);
}

/// Numbers reach tools and the store as the script wrote them, including
/// ones whose shortest form has 17 significant digits.
#[test]
fn numbers_are_passed_on_exactly() {
    let o = run(
        "const xs = [-5.91253273447554e+293, -2.62582893073312e-187, 4.4130929196150413e+21, 0.1 + 0.2, 2 ** 53 + 2, 5e-324]; const r = await tools.search({ xs }); return [JSON.stringify(xs), JSON.stringify(r.args.xs)];",
    );
    let v = o.done["value"].as_array().unwrap_or_else(|| panic!("{}", o.done));
    assert_eq!(v[0], v[1]);
    let written: Value = serde_json::from_str(v[0].as_str().unwrap()).unwrap();
    assert_eq!(o.of_type("call")[0]["args"]["xs"], written);
}

#[test]
fn non_serialisable_return_is_an_error() {
    let o = run("const a = {}; a.self = a; return a");
    assert_eq!(o.kind(), "script_error");
    assert!(o.done["error"]["message"].as_str().unwrap().contains("JSON"));
}

#[test]
fn uncaught_non_error_values() {
    let o = run("throw { code: 7 }");
    assert_eq!(o.done["error"]["name"], "Uncaught");
    assert!(o.done["error"]["message"].as_str().unwrap().contains("\"code\": 7"));
}

// ---- Protocol violations ----------------------------------------------------

#[test]
fn result_for_unknown_id_is_a_violation() {
    let mut host = Host::start();
    host.init_with(limits(), json!({}));
    host.exec("await tools.search({})");
    let call = host.next().unwrap();
    let id = call["id"].as_u64().unwrap() + 100;
    host.send(json!({"type": "result", "id": id, "ok": true, "payload": 1}));
    let done = host.next().unwrap();
    assert_eq!(done["error"]["kind"], "internal");
    assert!(done["error"]["message"].as_str().unwrap().contains("unknown call id"));
    assert_eq!(host.wait().code(), Some(1));
}

#[test]
fn oversized_frame_is_a_violation() {
    let mut host = Host::start();
    let big = vec![b'x'; 9 * 1024 * 1024];
    host.send_raw(&big);
    host.send_raw(b"\n");
    let done = host.next().unwrap();
    assert_eq!(done["error"]["kind"], "internal");
    assert!(done["error"]["message"].as_str().unwrap().contains("exceeds"));
    assert_eq!(host.wait().code(), Some(1));
}

#[test]
fn exec_before_init_is_a_violation() {
    let mut host = Host::start();
    host.exec("return 1");
    let done = host.next().unwrap();
    assert_eq!(done["error"]["kind"], "internal");
    assert_eq!(host.wait().code(), Some(1));
}

#[test]
fn invalid_limits_are_a_violation() {
    let mut host = Host::start();
    let mut l = limits();
    l["heap_bytes"] = json!(8u64 << 30);
    host.init_with(l, json!({}));
    let done = host.next().unwrap();
    assert_eq!(done["error"]["kind"], "internal");
    assert!(done["error"]["message"].as_str().unwrap().contains("heap_bytes"));
}

// ---- Containment --------------------------------------------------------------

#[test]
fn no_host_globals_by_any_route() {
    let o = run(
        r#"
        const names = ['process', 'require', 'fetch', 'Buffer', 'WebAssembly', 'module', 'exports',
                       'std', 'os', 'print', 'scriptArgs', 'performance', 'navigator', 'XMLHttpRequest',
                       'Deno', 'Bun', '__bridge', 'bridge', 'hooks'];
        const direct = names.filter(n => typeof globalThis[n] !== 'undefined');
        const viaFunction = names.filter(n => Function('return typeof ' + n)() !== 'undefined');
        const viaEval = names.filter(n => (0, eval)('typeof ' + n) !== 'undefined');
        const AsyncFunction = (async () => {}).constructor;
        const viaAsync = [];
        for (const n of names) if ((await new AsyncFunction('return typeof ' + n)()) !== 'undefined') viaAsync.push(n);
        let dynamicImport;
        try { await import('fs'); dynamicImport = 'loaded' } catch (e) { dynamicImport = e.name }
        let staticImport;
        try { Function("import fs from 'fs'"); staticImport = 'compiled' } catch (e) { staticImport = e.name }
        return { direct, viaFunction, viaEval, viaAsync, dynamicImport, staticImport };
        "#,
    );
    let v = &o.done["value"];
    assert_eq!(v["direct"], json!([]), "{v}");
    assert_eq!(v["viaFunction"], json!([]), "{v}");
    assert_eq!(v["viaEval"], json!([]), "{v}");
    assert_eq!(v["viaAsync"], json!([]), "{v}");
    assert_ne!(v["dynamicImport"], "loaded", "{v}");
    assert_eq!(v["staticImport"], "SyntaxError", "{v}");
}

#[test]
fn globals_are_exactly_the_documented_set() {
    let o = run("return Object.getOwnPropertyNames(globalThis).sort()");
    let got: Vec<String> = o.done["value"]
        .as_array()
        .unwrap()
        .iter()
        .map(|v| v.as_str().unwrap().to_string())
        .collect();
    let script_globals = [
        "ALL_TOOLS", "clearTimeout", "console", "describeNamespace", "describeTool", "exit", "image",
        "history", "keep", "limits", "load", "loadOutput", "models", "outputs", "searchTools",
        "setTimeout", "sleep", "store", "storedKeys", "text", "tools",
    ];
    for g in script_globals {
        assert!(got.contains(&g.to_string()), "missing {g}");
    }
    let builtins = [
        "AggregateError", "Array", "ArrayBuffer", "AsyncDisposableStack", "Atomics", "BigInt",
        "BigInt64Array", "BigUint64Array", "Boolean", "DataView", "Date", "DisposableStack", "Error",
        "EvalError", "FinalizationRegistry", "Float16Array", "Float32Array", "Float64Array", "Function",
        "Infinity", "Int16Array", "Int32Array", "Int8Array", "InternalError", "Iterator", "JSON", "Map",
        "Math", "NaN", "Number", "Object", "Promise", "Proxy", "RangeError", "ReferenceError", "Reflect",
        "RegExp", "Set", "SharedArrayBuffer", "String", "SuppressedError", "Symbol", "SyntaxError",
        "TypeError", "URIError", "Uint16Array", "Uint32Array", "Uint8Array", "Uint8ClampedArray",
        "WeakMap", "WeakRef", "WeakSet", "decodeURI", "decodeURIComponent", "encodeURI",
        "encodeURIComponent", "escape", "eval", "globalThis", "isFinite", "isNaN", "parseFloat",
        "parseInt", "queueMicrotask", "undefined", "unescape",
    ];
    for g in &got {
        assert!(
            script_globals.contains(&g.as_str()) || builtins.contains(&g.as_str()),
            "unexpected global {g}"
        );
    }
}

#[test]
fn bridge_is_not_reachable() {
    let o = run(
        r#"
        const found = [];
        // Walk everything reachable from the global object: own properties,
        // accessors and prototypes. No function the prelude keeps private
        // may turn up, and no object may expose a 'settle' or 'fireTimer'.
        const seen = new Set();
        const queue = [globalThis];
        while (queue.length) {
          const o = queue.pop();
          if ((typeof o !== 'object' && typeof o !== 'function') || o === null || seen.has(o)) continue;
          seen.add(o);
          if (o === tools) continue;
          for (const k of Reflect.ownKeys(o)) {
            if (k === 'settle' || k === 'fireTimer' || k === 'settleCall' || k === 'setTimer') found.push(String(k));
            let d;
            try { d = Object.getOwnPropertyDescriptor(o, k) } catch (e) { continue }
            if (!d) continue;
            if ('value' in d) queue.push(d.value); else { queue.push(d.get); queue.push(d.set) }
          }
          queue.push(Object.getPrototypeOf(o));
        }
        const restricted = [];
        for (const f of [text, console.log, store, setTimeout, tools.search, exit]) {
          try { f.caller; restricted.push('caller readable') } catch (e) {}
          try { f.arguments; restricted.push('arguments readable') } catch (e) {}
        }
        let viaCallee = 'blocked';
        await new Promise(r => setTimeout(function () { try { viaCallee = String(arguments.callee.caller) } catch (e) {} r() }, 0));
        return { found, restricted, viaCallee, walked: seen.size > 500 };
        "#,
    );
    let v = &o.done["value"];
    assert_eq!(v["found"], json!([]), "{v}");
    assert_eq!(v["restricted"], json!([]), "{v}");
    // QuickJS reports no caller for sloppy functions at all.
    assert!(["blocked", "null", "undefined"].contains(&v["viaCallee"].as_str().unwrap()), "{v}");
    assert_eq!(v["walked"], true, "{v}");
}

#[test]
fn overriding_json_and_prototypes_does_not_change_frames() {
    let o = run(
        r#"
        const tryIt = (f) => { try { f() } catch (e) {} };
        tryIt(() => { Array.prototype.toJSON = () => 'pwned' });
        tryIt(() => Object.defineProperty(Array.prototype, 'toJSON', { value: () => 'pwned' }));
        tryIt(() => { Object.prototype.toJSON = () => 'pwned' });
        tryIt(() => { JSON.stringify = () => '"pwned"' });
        tryIt(() => { globalThis.JSON = { stringify: () => '"pwned"', parse: () => 'pwned' } });
        tryIt(() => { String.prototype.toWellFormed = () => 'pwned' });
        tryIt(() => { Promise.prototype.then = () => 'pwned' });
        tryIt(() => { Map.prototype.get = () => 'pwned' });
        tryIt(() => { Reflect.apply = () => 'pwned' });
        const attempts = [
          'toJSON' in Array.prototype, 'toJSON' in Object.prototype,
          JSON.stringify([1]) !== '[1]', String.prototype.toWellFormed.name !== 'toWellFormed',
          Promise.prototype.then.name !== 'then', Map.prototype.get.name !== 'get', Reflect.apply.name !== 'apply',
        ];
        const r = await tools.search({ list: [1, 2], nested: { s: 'ok' } });
        text([1, 2]);
        return { attempts, echoed: r.args, json: typeof JSON.stringify };
        "#,
    );
    assert_eq!(o.done["ok"], true, "{}", o.done);
    let call = o.of_type("call")[0];
    assert_eq!(call["args"], json!({"list": [1, 2], "nested": {"s": "ok"}}));
    assert_eq!(o.texts(), vec!["[\n  1,\n  2\n]"]);
    assert_eq!(o.done["value"]["echoed"], json!({"list": [1, 2], "nested": {"s": "ok"}}));
    assert_eq!(o.done["value"]["attempts"], json!([false, false, false, false, false, false, false]));
}

#[test]
fn instance_overrides_still_work() {
    let o = run(
        r#"
        const o = { a: 1 };
        o.toString = () => 'custom';
        o.toJSON = () => ({ replaced: true });
        const e = new Error('original');
        e.message = 'changed';
        e.name = 'MyError';
        class Thing { constructor() { this.constructor = 'own' } }
        const d = new Date(0);
        d.toJSON = () => 'date';
        return [String(o), JSON.stringify(o), e.message, e.name, new Thing().constructor, JSON.stringify(d)];
        "#,
    );
    assert_eq!(
        o.done["value"],
        json!(["custom", "{\"replaced\":true}", "changed", "MyError", "own", "\"date\""]),
        "{}",
        o.done
    );
}

#[test]
fn odd_tool_names_are_callable_without_side_effects() {
    let o = run(
        r#"
        const a = await tools['__proto__']({ x: 1 });
        const b = await tools['class']({ y: 2 });
        const c = await tools.class({ y: 3 });
        return {
          proto: Object.getPrototypeOf(tools) === null,
          keys: Object.keys(tools).length,
          hasProto: '__proto__' in tools,
          sameFn: tools['__proto__'] === tools['__proto__'],
          frozen: Object.isFrozen(tools),
          a: a.tool, b: b.tool, c: c.tool,
          setRejected: (() => { tools.search = 1; return typeof tools.search })(),
        };
        "#,
    );
    let v = &o.done["value"];
    assert_eq!(v["proto"], true, "{v}");
    assert_eq!(v["keys"], 0, "{v}");
    assert_eq!(v["hasProto"], true, "{v}");
    assert_eq!(v["sameFn"], true, "{v}");
    assert_eq!(v["a"], "__proto__", "{v}");
    assert_eq!(v["b"], "class", "{v}");
    assert_eq!(v["c"], "class", "{v}");
    assert_eq!(v["setRejected"], "function", "{v}");
    let names: Vec<&str> = o.of_type("call").iter().map(|c| c["name"].as_str().unwrap()).collect();
    assert_eq!(names, vec!["__proto__", "class", "class"]);
}

#[test]
fn prepare_stack_trace_is_gone() {
    let o = run(
        r#"
        let hooked = false;
        try { Error.prepareStackTrace = () => { hooked = true; return [] } } catch (e) {}
        const s = new Error('x').stack;
        return { hooked, type: typeof s, present: 'prepareStackTrace' in Error };
        "#,
    );
    assert_eq!(o.done["value"], json!({"hooked": false, "type": "string", "present": false}), "{}", o.done);
}

#[test]
fn intrinsics_are_frozen() {
    let o = run(
        r#"
        const proto = Object.getPrototypeOf;
        return [Object, Array.prototype, Object.prototype, Function.prototype, JSON, Math, Promise.prototype,
                Error.prototype, Iterator.prototype,
                (async () => {}).constructor, (async () => {}).constructor.prototype,
                (function* () {}).constructor.prototype, proto(proto((function* () {})())),
                proto(proto((async function* () {})())), proto([][Symbol.iterator]()),
                proto(new Map().entries()), proto('x'[Symbol.iterator]()), proto([].values().map(x => x))]
          .map(Object.isFrozen);
        "#,
    );
    for v in o.done["value"].as_array().unwrap() {
        assert_eq!(v, true, "{}", o.done);
    }
}

#[test]
fn script_can_still_make_globals() {
    let o = run("globalThis.mine = 1; leaked = 2; return [mine, leaked]");
    assert_eq!(o.done["value"], json!([1, 2]), "{}", o.done);
}

#[test]
fn lone_surrogates_do_not_break_frames() {
    let o = run("text('a\\uD800b'); console.log('\\uDC00'); return 'ok'");
    assert_eq!(o.done["ok"], true, "{}", o.done);
    assert_eq!(o.texts(), vec!["a\u{FFFD}b", "\u{FFFD}"]);
}

#[test]
fn catastrophic_regex_is_stopped() {
    let o = run("try { return /^(a+)+$/.test('a'.repeat(40) + 'b') } catch (e) { return 'caught' }");
    assert_eq!(o.kind(), "cpu_exceeded", "{}", o.done);
}

#[test]
fn microtask_exceptions_fail_the_script() {
    let o = run("queueMicrotask(() => { throw new TypeError('in a microtask') }); await sleep(10); return 'kept going'");
    assert_eq!(o.kind(), "script_error", "{}", o.done);
    assert_eq!(o.done["error"]["message"], "in a microtask");
}

#[test]
fn timer_callback_exceptions_fail_the_script() {
    let o = run("setTimeout(() => { throw new Error('in a timer') }, 0); await sleep(20); return 'kept going'");
    assert_eq!(o.kind(), "script_error", "{}", o.done);
    assert_eq!(o.done["error"]["message"], "in a timer");
}

#[test]
fn lone_surrogates_in_results_are_replaced() {
    let mut host = Host::start();
    host.init_with(limits(), json!({}));
    host.exec("const r = await tools.search({}); return [r, r.length]");
    let call = host.next().unwrap();
    assert_eq!(call["type"], "call");
    let frame = format!(
        "{{\"type\":\"result\",\"id\":{},\"ok\":true,\"payload\":\"a\\ud800b\"}}\n",
        call["id"]
    );
    host.send_raw(frame.as_bytes());
    let done = host.next().unwrap();
    assert_eq!(done["value"], json!(["a\u{fffd}b", 3]), "{done}");
    assert!(host.wait().success());
}

/// Unknown arguments are a usage error, exit 2, and `--grant-runner-access`
/// (the Windows installer's step) is one everywhere else.
#[test]
fn unknown_arguments_are_a_usage_error() {
    let mut cases = vec![vec!["--nope"], vec!["--version", "x"]];
    let usage = if cfg!(windows) {
        cases.push(vec!["--grant-runner-access", "x"]);
        "usage: cc_codemode [--version | --self-test | --grant-runner-access]\n"
    } else {
        cases.push(vec!["--grant-runner-access"]);
        cases.push(vec!["--contained-child"]);
        "usage: cc_codemode [--version | --self-test]\n"
    };
    for args in cases {
        let out = Command::new(BIN).args(&args).stdin(Stdio::null()).output().unwrap();
        assert_eq!(out.status.code(), Some(2), "{args:?}");
        assert!(out.stdout.is_empty(), "{args:?}");
        let err = String::from_utf8_lossy(&out.stderr);
        assert_eq!(err, usage, "{args:?}");
    }
}

#[test]
fn self_test_proves_denials_and_working_sessions() {
    // Through a pipe: the lockdown's zero file-size limit kills a runner
    // whose stdout is a regular file.
    let out = Command::new(BIN)
        .arg("--self-test")
        .env_clear()
        .envs(std::env::vars_os().filter(|(k, _)| {
            ["SystemRoot", "SystemDrive", "windir", "TMPDIR", "TEMP", "TMP"]
                .iter()
                .any(|n| k.eq_ignore_ascii_case(n))
        }))
        .stdin(Stdio::null())
        .output()
        .expect("run --self-test");
    let text = String::from_utf8_lossy(&out.stdout);
    let line: Value = serde_json::from_str(text.trim()).expect("one JSON line");
    let st = &line["selftest"];
    assert_eq!(st["ok"], true, "{line}");
    assert!(out.status.success(), "{line}");
    assert_eq!(st["lockdown"]["level"], "full");
    // The profile the runner was built with; the test binary shares it.
    assert_eq!(st["build"], if cfg!(debug_assertions) { "debug" } else { "release" }, "{line}");
    assert!(st["checks"].as_array().unwrap().iter().all(|c| c["denied"] == true), "{line}");
    let names: Vec<&str> = st["checks"].as_array().unwrap().iter().map(|c| c["name"].as_str().unwrap()).collect();
    let expected: Vec<&str> = lockdown::selftest::all_checks().collect();
    assert_eq!(names, expected, "{line}");
    assert_eq!(st["session"]["passed"], true, "{line}");
    // Eight happy sessions, then one per bad ending.
    assert_eq!(st["session"]["runs"], 13);
}

/// The runner has three threads (main, stdin reader, watchdog) from `ready`
/// on and creates none while a script runs. The filter denies clone, and
/// the `madvise` allowlist relies on it: recent glibc may install a new
/// thread's stack guard with `MADV_GUARD_INSTALL` (102), which the filter
/// refuses. Counted from outside through `/proc/<pid>/status`.
#[cfg(target_os = "linux")]
#[test]
fn threads_stay_at_three() {
    fn threads(pid: u32) -> u32 {
        let status = std::fs::read_to_string(format!("/proc/{pid}/status")).expect("read the runner's status");
        status
            .lines()
            .find_map(|l| l.strip_prefix("Threads:"))
            .and_then(|n| n.trim().parse().ok())
            .expect("Threads line")
    }
    let mut host = Host::start();
    let pid = host.child.id();
    assert_eq!(threads(pid), 3, "after ready");
    host.init_with(limits(), json!({}));
    // Timers, a tool call and a promise chain: everything a script can ask
    // of the runtime that might want a thread.
    host.exec("setTimeout(() => {}, 5); const r = await tools.search({}); await Promise.all([sleep(10), sleep(20)]); text('mid'); await sleep(300); return r.ok");
    let mut counted = false;
    let done = loop {
        let f = host.next().expect("frame before done");
        match f["type"].as_str().unwrap() {
            "call" => host.send(json!({"type": "result", "id": f["id"], "ok": true, "payload": {"ok": true}})),
            "output" if f["text"] == "mid" => {
                assert_eq!(threads(pid), 3, "while the script runs");
                counted = true;
            }
            "done" => break f,
            _ => {}
        }
    };
    assert_eq!(done["value"], true, "{done}");
    assert!(counted, "no output frame 'mid'");
    assert!(host.wait().success());
}
