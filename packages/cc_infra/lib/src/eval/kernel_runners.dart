/// The Python side of the kernel, written into the guest on first use.
///
/// **Vanilla, deliberately.** No Jupyter, no ipykernel, no pip dependency at
/// all — just `python3 -u runner.py` speaking NDJSON on stdio. The reason is
/// not minimalism: a kernel that needs an install is a kernel that fails the
/// first time somebody uses it, in an environment where installing is exactly
/// what the sandbox is there to prevent. This runs on any Python 3 that exists.
///
/// **It still does the things people actually want from a notebook.** A cell's
/// trailing expression is echoed, `display()` works, a pandas DataFrame renders
/// as HTML and a matplotlib figure comes back as a PNG — because those are
/// implemented here (MIME-bundle dispatch, `MPLBACKEND=Agg`, post-cell figure
/// capture) rather than inherited from IPython.
const String pythonKernelRunner = r'''
import base64, io, json, os, signal, sys, traceback

os.environ.setdefault("MPLBACKEND", "Agg")

_state = {}
_out = sys.__stdout__


def _emit(message):
    _out.write(json.dumps(message) + "\n")
    _out.flush()


class _Tee(io.TextIOBase):
    """Streams a cell's output as it is produced, rather than at the end."""

    def __init__(self, stream):
        self.stream = stream

    def write(self, text):
        if text:
            _emit({"type": self.stream, "text": text})
        return len(text)

    def flush(self):
        return None


def _mime_bundle(value):
    """The richest representation an object offers, PNG first.

    Ordered so a chart arrives as an image rather than as its repr: the whole
    point of returning a figure is to look at it.
    """
    for method, kind in (
        ("_repr_png_", "image/png"),
        ("_repr_html_", "text/html"),
    ):
        repr_fn = getattr(value, method, None)
        if callable(repr_fn):
            try:
                data = repr_fn()
                if data:
                    if kind == "image/png" and isinstance(data, bytes):
                        data = base64.b64encode(data).decode("ascii")
                    return {"mime": kind, "data": data}
            except Exception:
                pass
    return None


def display(*values):
    """The `display()` people expect, without importing IPython."""
    for value in values:
        bundle = _mime_bundle(value)
        if bundle:
            _emit({"type": "display", **bundle})
        else:
            _emit({"type": "stdout", "text": repr(value) + "\n"})


_state["display"] = display


def _capture_figures():
    """Emits every open matplotlib figure as a PNG, then closes them.

    Closing matters: an uncollected figure is redrawn and re-sent by the NEXT
    cell too, so a five-cell session ends up emitting the first chart five
    times.
    """
    module = sys.modules.get("matplotlib.pyplot")
    if module is None:
        return
    try:
        for number in module.get_fignums():
            figure = module.figure(number)
            buffer = io.BytesIO()
            figure.savefig(buffer, format="png", bbox_inches="tight")
            _emit({
                "type": "display",
                "mime": "image/png",
                "data": base64.b64encode(buffer.getvalue()).decode("ascii"),
            })
        module.close("all")
    except Exception:
        pass


def _bridge(name, arguments=None):
    """Calls one of the agent's own tools from inside a cell.

    Rides the SAME pipe the cell results travel on rather than a loopback
    socket: no port to open, no secret to mint, no egress rule to widen, and
    the channel is authenticated by being the channel. The host pauses the
    cell's inactivity timeout while this is outstanding.
    """
    _emit({"type": "bridge_call", "name": name, "arguments": arguments or {}})
    line = sys.stdin.readline()
    if not line:
        raise RuntimeError("the host closed the bridge")
    reply = json.loads(line)
    if reply.get("is_error"):
        raise RuntimeError(reply.get("content", "tool call failed"))
    return reply.get("content", "")


_state["tool"] = _bridge


def _run(code):
    """Executes a cell, echoing its trailing expression like a notebook."""
    import ast

    tree = ast.parse(code, mode="exec")
    last = None
    if tree.body and isinstance(tree.body[-1], ast.Expr):
        last = ast.Expression(tree.body.pop().value)
    exec(compile(tree, "<cell>", "exec"), _state)
    if last is not None:
        value = eval(compile(last, "<cell>", "eval"), _state)
        if value is not None:
            bundle = _mime_bundle(value)
            if bundle:
                _emit({"type": "display", **bundle})
            else:
                _emit({"type": "result", "text": repr(value)})


def main():
    # Ignored between requests, so a cancel that arrives after a cell finished
    # cannot kill the kernel and lose every variable in it.
    signal.signal(signal.SIGINT, signal.SIG_IGN)
    _emit({"type": "ready", "version": sys.version.split()[0]})
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            request = json.loads(line)
        except Exception:
            continue
        if request.get("type") == "shutdown":
            return
        if request.get("type") != "exec":
            continue

        request_id = request.get("id")
        _emit({"type": "started", "id": request_id})
        stdout, stderr = sys.stdout, sys.stderr
        sys.stdout, sys.stderr = _Tee("stdout"), _Tee("stderr")
        signal.signal(signal.SIGINT, signal.default_int_handler)
        try:
            _run(request.get("code", ""))
            _capture_figures()
            _emit({"type": "done", "id": request_id})
        except KeyboardInterrupt:
            _emit({"type": "error", "id": request_id, "text": "cancelled"})
        except BaseException:
            _emit({
                "type": "error",
                "id": request_id,
                "text": traceback.format_exc(limit=8),
            })
        finally:
            signal.signal(signal.SIGINT, signal.SIG_IGN)
            sys.stdout, sys.stderr = stdout, stderr


main()
''';

/// The JavaScript side of the kernel.
///
/// Same protocol, same reasoning: plain `node runner.js`, no dependency. State
/// lives in one long-lived `vm` context, so a `const` defined in one cell is
/// still bound in the next.
const String jsKernelRunner = r'''
const vm = require("vm");
const readline = require("readline");

const context = vm.createContext({
  require,
  console: {
    log: (...args) => emit({ type: "stdout", text: args.map(fmt).join(" ") + "\n" }),
    error: (...args) => emit({ type: "stderr", text: args.map(fmt).join(" ") + "\n" }),
  },
  process,
  Buffer,
  setTimeout,
  clearTimeout,
  setInterval,
  clearInterval,
});

function fmt(value) {
  if (typeof value === "string") return value;
  try {
    return JSON.stringify(value, null, 2);
  } catch {
    return String(value);
  }
}

function emit(message) {
  process.stdout.write(JSON.stringify(message) + "\n");
}

emit({ type: "ready", version: process.version });

const rl = readline.createInterface({ input: process.stdin });
rl.on("line", async (line) => {
  line = line.trim();
  if (!line) return;
  let request;
  try {
    request = JSON.parse(line);
  } catch {
    return;
  }
  if (request.type === "shutdown") process.exit(0);
  if (request.type !== "exec") return;

  emit({ type: "started", id: request.id });
  try {
    // Awaited, so a cell whose last expression is a promise reports the value
    // rather than "Promise { <pending> }" — the single most common surprise in
    // a JS REPL.
    const result = await vm.runInContext(request.code, context, {
      filename: "<cell>",
    });
    if (result !== undefined) {
      emit({ type: "result", text: fmt(result) });
    }
    emit({ type: "done", id: request.id });
  } catch (error) {
    emit({
      type: "error",
      id: request.id,
      text: (error && error.stack) || String(error),
    });
  }
});
''';
