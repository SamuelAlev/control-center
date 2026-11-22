// cc_codemode prelude. Evaluated once, before `ready`, as a strict-mode
// function expression. The runner calls it with the native bridge and keeps
// the returned hooks; neither ever becomes reachable from script code.
//
// Order matters: capture every intrinsic the bridge relies on, install the
// override shims, freeze the intrinsics, make the built-in globals
// read-only, then add the script globals and freeze those too.
(function (bridge) {
  'use strict';

  // ---- Captures -------------------------------------------------------
  const bridgeCall = bridge.call;
  const bridgeText = bridge.text;
  const bridgeLog = bridge.log;
  const bridgeImage = bridge.image;
  const bridgeStore = bridge.store;
  const bridgeLimits = bridge.limits;
  const bridgeExit = bridge.exit;
  const bridgeSetTimer = bridge.setTimer;
  const bridgeClearTimer = bridge.clearTimer;
  const bridgeSettle = bridge.settle;
  const bridgeCompile = bridge.compile;

  const global = globalThis;
  const JSONparse = JSON.parse;
  const JSONstringify = JSON.stringify;
  const ReflectApply = Reflect.apply;
  const ReflectOwnKeys = Reflect.ownKeys;
  const ObjectFreeze = Object.freeze;
  const ObjectCreate = Object.create;
  const ObjectDefineProperty = Object.defineProperty;
  const ObjectGetOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;
  const ObjectGetPrototypeOf = Object.getPrototypeOf;
  const ObjectHasOwn = Object.hasOwn;
  const ObjectKeys = Object.keys;
  const ObjectIsFrozen = Object.isFrozen;
  const ArrayIsArray = Array.isArray;
  const ErrorIsError = Error.isError;
  const NumberIsFinite = Number.isFinite;
  const MathFloor = Math.floor;
  const MathMin = Math.min;
  const StringCtor = String;
  const ErrorCtor = Error;
  const TypeErrorCtor = TypeError;
  const RangeErrorCtor = RangeError;
  const PromiseCtor = Promise;
  const ProxyCtor = Proxy;
  const MapCtor = Map;
  const SetCtor = Set;
  const WeakSetCtor = WeakSet;
  // Error's accessors stay usable after the property is deleted or the
  // constructor frozen: they read and write engine state, not the property.
  const stackLimitAccessors = ObjectGetOwnPropertyDescriptor(Error, 'stackTraceLimit');
  const prepareAccessors = ObjectGetOwnPropertyDescriptor(Error, 'prepareStackTrace');
  if (stackLimitAccessors === undefined || typeof stackLimitAccessors.get !== 'function' ||
      typeof stackLimitAccessors.set !== 'function' || prepareAccessors === undefined ||
      typeof prepareAccessors.set !== 'function') {
    throw new Error('Error.stackTraceLimit or Error.prepareStackTrace is not an accessor');
  }
  const getStackLimit = stackLimitAccessors.get;
  const setStackLimit = stackLimitAccessors.set;
  const setPrepareStack = prepareAccessors.set;

  const uncurry = (fn) => (self, ...args) => ReflectApply(fn, self, args);
  const PromiseThen = uncurry(Promise.prototype.then);
  const MapGet = uncurry(Map.prototype.get);
  const MapSet = uncurry(Map.prototype.set);
  const MapHas = uncurry(Map.prototype.has);
  const MapDelete = uncurry(Map.prototype.delete);
  const MapForEach = uncurry(Map.prototype.forEach);
  const StringCharCodeAt = uncurry(String.prototype.charCodeAt);
  const SetAdd = uncurry(Set.prototype.add);
  const SetHas = uncurry(Set.prototype.has);
  const WeakSetAdd = uncurry(WeakSet.prototype.add);
  const WeakSetHas = uncurry(WeakSet.prototype.has);
  const ArrayPush = uncurry(Array.prototype.push);
  const ArrayJoin = uncurry(Array.prototype.join);
  const ArrayMap = uncurry(Array.prototype.map);
  const ArraySort = uncurry(Array.prototype.sort);
  const ArraySlice = uncurry(Array.prototype.slice);
  const ArrayFilter = uncurry(Array.prototype.filter);
  const StringSplit = uncurry(String.prototype.split);
  const StringReplace = uncurry(String.prototype.replace);
  const StringIncludes = uncurry(String.prototype.includes);
  const StringToLowerCase = uncurry(String.prototype.toLowerCase);
  const StringToWellFormed = uncurry(String.prototype.toWellFormed);
  const StringSlice = uncurry(String.prototype.slice);
  const RegExpExec = uncurry(RegExp.prototype.exec);
  const SymbolToString = uncurry(Symbol.prototype.toString);
  const FunctionToString = uncurry(Function.prototype.toString);
  const ObjectToString = uncurry(Object.prototype.toString);

  const wellFormed = (s) => StringToWellFormed(s);

  // ---- Stack mapping --------------------------------------------------
  // bridge.compile compiles `(async function anonymous(\n) {\n` + body +
  // `\n})` with the file name `<script>` (as the AsyncFunction constructor
  // would, under its own name), so script line N is reported as line N + 2;
  // reported stacks read `repl.js:N:C`. Code the script makes with eval or
  // Function is compiled as `<input>`; its frames read `eval:L:C`, numbered
  // within that code. Prelude frames are dropped.
  const SCRIPT_FILE = '<script>';
  const SCRIPT_FRAME = /<script>:(\d+):(\d+)/;
  const SCRIPT_FRAME_ALL = /<script>:(\d+):(\d+)/g;
  const EVAL_FRAME_ALL = /<input>:(\d+):(\d+)/g;

  function mapLine(line) {
    const n = +line - 2;
    return n < 1 ? 1 : n;
  }

  function mapStack(stack) {
    const lines = StringSplit(stack, '\n');
    const out = [];
    for (let i = 0; i < lines.length; i++) {
      const l = lines[i];
      if (l === '') continue;
      if (StringIncludes(l, 'prelude.js:')) continue;
      let mapped = StringReplace(l, SCRIPT_FRAME_ALL, (_, line, col) => 'repl.js:' + mapLine(line) + ':' + col);
      mapped = StringReplace(mapped, EVAL_FRAME_ALL, 'eval:$1:$2');
      mapped = StringReplace(mapped, /at anonymous \((repl\.js:\d+:\d+)\)/, 'at $1');
      ArrayPush(out, mapped);
    }
    return ArrayJoin(out, '\n');
  }

  function firstScriptLocation(stack) {
    const m = RegExpExec(SCRIPT_FRAME, stack);
    if (m === null) return null;
    return { line: mapLine(m[1]), column: +m[2] };
  }

  function safeString(read) {
    try {
      const v = read();
      if (v === undefined) return '';
      return typeof v === 'string' ? v : StringCtor(v);
    } catch (e) {
      return '';
    }
  }

  // Describes a thrown value for `done.error` and for console output.
  // An error's texts are capped before they are encoded, so a thrown
  // error carrying a huge message costs the runner no more than its frame.
  const ERROR_TEXT_MAX = 65536;
  const capText = (t) => (t.length > ERROR_TEXT_MAX ? StringSlice(t, 0, ERROR_TEXT_MAX) : t);

  function describe(e) {
    let name, message, rawStack = '';
    if (ErrorIsError(e)) {
      name = safeString(() => e.name) || 'Error';
      message = safeString(() => e.message);
      rawStack = safeString(() => e.stack);
    } else {
      name = 'Uncaught';
      message = inspect(e, true);
    }
    name = capText(name);
    message = capText(message);
    rawStack = capText(rawStack);
    const loc = firstScriptLocation(rawStack);
    return {
      name: wellFormed(name),
      message: wellFormed(message),
      stack: wellFormed(mapStack(rawStack)),
      line: loc === null ? null : loc.line,
      column: loc === null ? null : loc.column,
    };
  }

  // ---- Formatting -----------------------------------------------------
  function inspect(v, top) {
    switch (typeof v) {
      case 'string':
        return top ? v : JSONstringify(v);
      case 'number':
      case 'boolean':
      case 'undefined':
        return StringCtor(v);
      case 'bigint':
        return StringCtor(v) + 'n';
      case 'symbol':
        return SymbolToString(v);
      case 'function': {
        const n = safeString(() => v.name);
        return n ? '[Function: ' + n + ']' : '[Function (anonymous)]';
      }
    }
    if (v === null) return 'null';
    if (ErrorIsError(v)) {
      const d = describe(v);
      const head = d.message ? d.name + ': ' + d.message : d.name;
      return d.stack ? head + '\n' + d.stack : head;
    }
    const seen = new WeakSetCtor();
    try {
      const s = JSONstringify(v, function (key, value) {
        if (typeof value === 'bigint') return StringCtor(value) + 'n';
        if (typeof value === 'function') return inspect(value, false);
        if (typeof value === 'symbol') return SymbolToString(value);
        if (value === undefined) return value;
        if (typeof value === 'object' && value !== null) {
          if (WeakSetHas(seen, value)) return '[Circular]';
          WeakSetAdd(seen, value);
          if (ErrorIsError(value)) return inspect(value, false);
        }
        return value;
      }, 2);
      return s === undefined ? StringCtor(v) : s;
    } catch (err) {
      return safeString(() => ObjectToString(v));
    }
  }

  // ---- Call sites -----------------------------------------------------
  // Where in the script a call was made: the line and column QuickJS
  // reports for the innermost frame compiled from the script itself
  // (file `<script>`), read from the engine's structured call sites, never
  // from a stack string (a function's name, which a script controls, is
  // part of that string). Frames of prelude code and of code the script
  // made with eval or Function have other file names and are skipped, so
  // the site is always a position in the script's own text. For the
  // capture only, the prelude installs its own prepareStackTrace and frame
  // limit and then puts the script's limit back: `Error.stackTraceLimit`
  // set by the script neither hides nor moves a site, and no script code
  // runs in between. bridge.call turns QuickJS's position into the
  // protocol's (see README.md, `call`); no frame found means no site.
  const SITE_FRAMES = 10;
  let callSiteFile, callSiteLine, callSiteColumn;
  ReflectApply(setPrepareStack, ErrorCtor, [(_, sites) => {
    const proto = ObjectGetPrototypeOf(sites[0]);
    callSiteFile = proto.getFileName;
    callSiteLine = proto.getLineNumber;
    callSiteColumn = proto.getColumnNumber;
    // Only the prelude ever holds a CallSite; freezing its prototype is
    // belt and braces. (A deep freeze here would freeze Object.prototype
    // before the shims below are installed.)
    ObjectFreeze(proto);
    return '';
  }]);
  try {
    new ErrorCtor();
  } finally {
    ReflectApply(setPrepareStack, ErrorCtor, [undefined]);
  }
  if (typeof callSiteFile !== 'function' || typeof callSiteLine !== 'function' ||
      typeof callSiteColumn !== 'function') {
    throw new ErrorCtor('cannot read call sites');
  }

  let siteLine = 0;
  let siteColumn = 0;

  function collectSite(_, sites) {
    for (let i = 0; i < sites.length; i++) {
      const s = sites[i];
      if (ReflectApply(callSiteFile, s, []) === SCRIPT_FILE) {
        siteLine = ReflectApply(callSiteLine, s, []);
        siteColumn = ReflectApply(callSiteColumn, s, []);
        break;
      }
    }
    return '';
  }

  // Leaves the engine's position in siteLine and siteColumn, or 0 and 0.
  function captureSite() {
    siteLine = 0;
    siteColumn = 0;
    const saved = ReflectApply(getStackLimit, ErrorCtor, []);
    try {
      ReflectApply(setStackLimit, ErrorCtor, [SITE_FRAMES]);
      ReflectApply(setPrepareStack, ErrorCtor, [collectSite]);
      new ErrorCtor();
    } catch (e) {
      siteLine = 0;
      siteColumn = 0;
    } finally {
      ReflectApply(setPrepareStack, ErrorCtor, [undefined]);
      ReflectApply(setStackLimit, ErrorCtor, [saved]);
    }
  }

  // ---- Bridge calls ---------------------------------------------------
  const pending = new MapCtor(); // id -> { resolve, reject }

  function startCall(target, name, args) {
    captureSite();
    const line = siteLine;
    const column = siteColumn;
    return new PromiseCtor((resolve, reject) => {
      const json = JSONstringify(args === undefined ? {} : args);
      if (json === undefined) {
        throw new TypeErrorCtor('Arguments must be JSON-serialisable');
      }
      const id = bridgeCall(target, wellFormed(name), json, line, column);
      MapSet(pending, id, { resolve, reject });
    });
  }

  function settleCall(id, ok, payload, status) {
    const p = MapGet(pending, id);
    if (p === undefined) return;
    MapDelete(pending, id);
    if (ok) {
      p.resolve(JSONparse(payload));
    } else {
      const err = new ErrorCtor(payload);
      if (status !== undefined) err.status = status;
      p.reject(err);
    }
  }

  // ---- Catalog and tools ----------------------------------------------
  let catalog = [];
  const byKey = new MapCtor(); // id or raw name -> raw name
  const toolFns = new MapCtor(); // raw name -> function
  const RESERVED = new SetCtor(['then', 'toJSON', 'toString', 'valueOf', 'constructor', 'inspect']);

  function distance(a, b) {
    a = StringToLowerCase(a);
    b = StringToLowerCase(b);
    const m = a.length, n = b.length;
    if (m > 64 || n > 64) return m > n ? m - n : n - m;
    let prev = [];
    for (let j = 0; j <= n; j++) prev[j] = j;
    for (let i = 1; i <= m; i++) {
      const cur = [i];
      for (let j = 1; j <= n; j++) {
        const cost = a[i - 1] === b[j - 1] ? 0 : 1;
        cur[j] = MathMin(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost);
      }
      prev = cur;
    }
    return prev[n];
  }

  function closest(name) {
    const scored = [];
    for (let i = 0; i < catalog.length; i++) {
      const t = catalog[i];
      let d = MathMin(distance(name, t.id), distance(name, t.name));
      if (StringIncludes(StringToLowerCase(t.name), StringToLowerCase(name))) d = 0;
      ArrayPush(scored, { d, id: t.id });
    }
    ArraySort(scored, (x, y) => x.d - y.d);
    return ArrayMap(ArraySlice(scored, 0, 3), (s) => s.id);
  }

  function toolFunction(rawName) {
    let fn = MapGet(toolFns, rawName);
    if (fn === undefined) {
      fn = (...args) => {
        if (args.length > 1) {
          return Promise.reject(new TypeErrorCtor('tools.' + rawName + ' takes one argument object'));
        }
        return startCall('tool', rawName, args[0]);
      };
      ObjectFreeze(fn);
      MapSet(toolFns, rawName, fn);
    }
    return fn;
  }

  function unknownTool(name) {
    return (...args) => {
      const near = closest(name);
      const hint = near.length ? ' Closest: ' + ArrayJoin(near, ', ') + '.' : '';
      return Promise.reject(new TypeErrorCtor('Unknown tool "' + name + '".' + hint +
        ' Use searchTools(query) to find tools.'));
    };
  }

  const toolsTarget = ObjectFreeze(ObjectCreate(null));
  const tools = new ProxyCtor(toolsTarget, ObjectFreeze({
    get(_, key) {
      if (typeof key !== 'string') return undefined;
      const raw = MapGet(byKey, key);
      if (raw !== undefined) return toolFunction(raw);
      if (SetHas(RESERVED, key)) return undefined;
      return unknownTool(key);
    },
    has(_, key) {
      return typeof key === 'string' && MapHas(byKey, key);
    },
    set() { return false; },
    defineProperty() { return false; },
    deleteProperty() { return false; },
    setPrototypeOf() { return false; },
  }));

  // ---- Output ---------------------------------------------------------
  function text(value) {
    bridgeText(wellFormed(typeof value === 'string' ? value : inspect(value, true)));
  }

  function image(block) {
    if (block === null || typeof block !== 'object' || block.type !== 'image' ||
        typeof block.mediaType !== 'string' || typeof block.data !== 'string') {
      throw new TypeErrorCtor('image() takes an image block { type: "image", mediaType, data } returned by a tool');
    }
    bridgeImage(wellFormed(block.mediaType), wellFormed(block.data));
  }

  function makeLog(level) {
    return (...args) => {
      bridgeLog(level, wellFormed(ArrayJoin(ArrayMap(args, (a) => inspect(a, true)), ' ')));
    };
  }

  const console = {
    log: makeLog('log'),
    info: makeLog('info'),
    warn: makeLog('warn'),
    error: makeLog('error'),
    debug: makeLog('debug'),
  };

  // ---- Store ----------------------------------------------------------
  const stored = new MapCtor(); // key -> JSON text

  function store(key, value) {
    if (typeof key !== 'string' || key === '') {
      throw new TypeErrorCtor('store(key, value) needs a non-empty string key');
    }
    if (value === undefined) {
      bridgeStore(wellFormed(key), undefined);
      MapDelete(stored, key);
      return;
    }
    const json = JSONstringify(value);
    if (json === undefined) {
      throw new TypeErrorCtor('store() takes a JSON-serialisable value');
    }
    bridgeStore(wellFormed(key), json);
    MapSet(stored, key, json);
  }

  function load(key) {
    if (typeof key !== 'string') {
      throw new TypeErrorCtor('load(key) needs a string key');
    }
    const json = MapGet(stored, key);
    return json === undefined ? undefined : JSONparse(json);
  }

  // UTF-8 bytes of JSON text (well formed: JSON.stringify escapes a lone
  // surrogate), as the host and the runner charge a stored value.
  function utf8Bytes(text) {
    let n = 0;
    for (let i = 0; i < text.length; i++) {
      const c = StringCharCodeAt(text, i);
      if (c < 0x80) n += 1;
      else if (c < 0x800) n += 2;
      else if (c >= 0xd800 && c <= 0xdbff) { n += 4; i++; }
      else n += 3;
    }
    return n;
  }

  function storedKeys() {
    const out = [];
    MapForEach(stored, (json, key) => { ArrayPush(out, { key, bytes: utf8Bytes(json) }); });
    return ArraySort(out, (a, b) => (a.key < b.key ? -1 : a.key > b.key ? 1 : 0));
  }

  // ---- Timers ---------------------------------------------------------
  const timers = new MapCtor(); // id -> { fn, args }

  function delayOf(ms) {
    const n = +ms;
    return NumberIsFinite(n) && n > 0 ? MathFloor(n) : 0;
  }

  function setTimeout(fn, ms, ...args) {
    if (typeof fn !== 'function') {
      throw new TypeErrorCtor('setTimeout needs a function');
    }
    const id = bridgeSetTimer(delayOf(ms));
    MapSet(timers, id, { fn, args });
    return id;
  }

  function clearTimeout(id) {
    if (MapDelete(timers, id)) bridgeClearTimer(id);
  }

  function sleep(ms) {
    return new PromiseCtor((resolve) => { setTimeout(resolve, ms); });
  }

  function fireTimer(id) {
    const t = MapGet(timers, id);
    if (t === undefined) return;
    MapDelete(timers, id);
    ReflectApply(t.fn, undefined, t.args);
  }

  // ---- Discovery and models -------------------------------------------
  function host(name, args) {
    return startCall('host', name, args);
  }

  function searchTools(query, options) {
    if (typeof query !== 'string') {
      return Promise.reject(new TypeErrorCtor('searchTools(query, { limit, namespace }) needs a string query'));
    }
    const o = options === undefined ? {} : options;
    return host('searchTools', { query, limit: o.limit === undefined ? 8 : o.limit, namespace: o.namespace });
  }

  function describeTool(name) {
    if (typeof name !== 'string') {
      return Promise.reject(new TypeErrorCtor('describeTool(nameOrId) needs a string'));
    }
    return host('describeTool', { name });
  }

  function describeNamespace(name) {
    if (typeof name !== 'string') {
      return Promise.reject(new TypeErrorCtor('describeNamespace(name) needs a string'));
    }
    return host('describeNamespace', { name });
  }

  const models = {
    embed(texts) {
      return host('models.embed', { texts });
    },
    rank(query, candidates, options) {
      const o = options === undefined ? {} : options;
      return host('models.rank', { query, candidates, top: o.top });
    },
    classify(texts, labels) {
      return host('models.classify', { texts, labels });
    },
  };

  // The run's past and kept values: answered by the host, which binds them
  // to the run; every argument is checked there.
  function optionsOf(name, options) {
    if (options === undefined) return {};
    if (options === null || typeof options !== 'object') {
      throw new TypeErrorCtor(name + ' options must be an object');
    }
    return options;
  }

  function history(options) {
    let o;
    try { o = optionsOf('history({ start, limit, role, tool })', options); } catch (e) { return PromiseCtor.reject(e); }
    return host('history', { start: o.start, limit: o.limit, role: o.role, tool: o.tool, row: o.row, offset: o.offset });
  }

  function outputs(options) {
    let o;
    try { o = optionsOf('outputs({ limit, tool })', options); } catch (e) { return PromiseCtor.reject(e); }
    return host('outputs', { limit: o.limit, tool: o.tool });
  }

  function loadOutput(handle, options) {
    if (typeof handle !== 'string') {
      return PromiseCtor.reject(new TypeErrorCtor('loadOutput(handle, { offset, limit }) needs a string handle'));
    }
    let o;
    try { o = optionsOf('loadOutput(handle, { offset, limit })', options); } catch (e) { return PromiseCtor.reject(e); }
    return host('loadOutput', { handle, offset: o.offset, limit: o.limit });
  }

  function keep(value, label) {
    if (typeof label !== 'string') {
      return PromiseCtor.reject(new TypeErrorCtor('keep(value, label) needs a string label'));
    }
    return host('keep', { value, label });
  }

  function limits() {
    return JSONparse(bridgeLimits());
  }

  function exit() {
    bridgeExit();
  }

  // ---- Freeze ---------------------------------------------------------
  // Error.prepareStackTrace is an accessor in QuickJS-NG that freezing does
  // not disable; with it, a script could receive call-site objects. Remove
  // it so stacks are plain strings.
  if (!delete Error.prepareStackTrace || 'prepareStackTrace' in Error) {
    throw new ErrorCtor('cannot remove Error.prepareStackTrace');
  }

  // Override shims. Freezing a prototype makes assignments of the same key
  // on ordinary instances fail. For keys scripts commonly assign on their own
  // objects, swap the data property for an accessor whose setter defines an
  // own property on the receiver, and refuses on the prototype itself.
  function shim(proto, key) {
    const d = ObjectGetOwnPropertyDescriptor(proto, key);
    if (d === undefined || !('value' in d) || !d.writable) return;
    const value = d.value;
    ObjectDefineProperty(proto, key, {
      get() { return value; },
      set(next) {
        if (this === proto) {
          throw new TypeErrorCtor('Cannot assign to read only property \'' + StringCtor(key) + '\' of a frozen built-in');
        }
        if (ObjectHasOwn(this, key)) {
          ObjectDefineProperty(this, key, { value: next });
        } else {
          ObjectDefineProperty(this, key, { value: next, writable: true, enumerable: true, configurable: true });
        }
      },
      enumerable: d.enumerable,
      configurable: false,
    });
  }

  const shims = [
    [Object.prototype, ['constructor', 'toString', 'toLocaleString', 'valueOf', 'hasOwnProperty', 'isPrototypeOf', 'propertyIsEnumerable']],
    [Function.prototype, ['constructor', 'toString']],
    [Array.prototype, ['constructor', 'toString', 'toLocaleString']],
    [Date.prototype, ['constructor', 'toJSON', 'toString']],
    [Promise.prototype, ['constructor']],
    [RegExp.prototype, ['constructor']],
    [Map.prototype, ['constructor']],
    [Set.prototype, ['constructor']],
    [Error.prototype, ['constructor', 'message', 'name', 'toString']],
  ];
  const errorCtors = [EvalError, RangeError, ReferenceError, SyntaxError, TypeError, URIError,
    InternalError, AggregateError, SuppressedError];
  for (let i = 0; i < errorCtors.length; i++) {
    ArrayPush(shims, [errorCtors[i].prototype, ['constructor', 'message', 'name']]);
  }
  for (let i = 0; i < shims.length; i++) {
    const keys = shims[i][1];
    for (let j = 0; j < keys.length; j++) shim(shims[i][0], keys[j]);
  }

  function deepFreeze(root) {
    const seen = new WeakSetCtor();
    const stack = [root];
    while (stack.length > 0) {
      const o = stack.pop();
      if ((typeof o !== 'object' && typeof o !== 'function') || o === null) continue;
      // The global object stays extensible; its properties are handled below.
      if (o === global || WeakSetHas(seen, o)) continue;
      WeakSetAdd(seen, o);
      ObjectFreeze(o);
      ArrayPush(stack, ObjectGetPrototypeOf(o));
      const keys = ReflectOwnKeys(o);
      for (let i = 0; i < keys.length; i++) {
        const d = ObjectGetOwnPropertyDescriptor(o, keys[i]);
        if (d === undefined) continue;
        if ('value' in d) {
          ArrayPush(stack, d.value);
        } else {
          ArrayPush(stack, d.get);
          ArrayPush(stack, d.set);
        }
      }
    }
  }

  // Every built-in global becomes read-only and non-configurable, and every
  // object reachable from them is frozen. globalThis itself stays
  // extensible, so a script may still create its own globals.
  const builtinKeys = ReflectOwnKeys(global);
  for (let i = 0; i < builtinKeys.length; i++) {
    const key = builtinKeys[i];
    const d = ObjectGetOwnPropertyDescriptor(global, key);
    if ('value' in d) {
      ObjectDefineProperty(global, key, { writable: false, configurable: false });
    } else {
      ObjectDefineProperty(global, key, { configurable: false });
    }
    deepFreeze(d.value !== undefined ? d.value : d.get);
  }
  deepFreeze(ObjectGetPrototypeOf(global));

  // Intrinsics that no global property leads to: the constructors and
  // prototypes behind function kinds and the built-in iterators.
  const hidden = [
    () => (async function () {}).constructor,
    () => (function* () {}).constructor,
    () => (async function* () {}).constructor,
    () => ObjectGetPrototypeOf([][Symbol.iterator]()),
    () => ObjectGetPrototypeOf(new MapCtor()[Symbol.iterator]()),
    () => ObjectGetPrototypeOf(new SetCtor()[Symbol.iterator]()),
    () => ObjectGetPrototypeOf(''[Symbol.iterator]()),
    () => ObjectGetPrototypeOf(/a/[Symbol.matchAll]('')),
    () => ObjectGetPrototypeOf([].values().map((x) => x)),
    () => ObjectGetPrototypeOf(Iterator.from({ next() { return { done: true }; } })),
    () => ObjectGetPrototypeOf(Iterator.concat()),
    () => ObjectGetPrototypeOf(Iterator.zip([])),
    () => ObjectGetPrototypeOf(Iterator.zipKeyed({})),
    () => ObjectGetPrototypeOf(ObjectGetPrototypeOf((async function* () {})())),
  ];
  for (let i = 0; i < hidden.length; i++) {
    let root;
    try {
      root = hidden[i]();
    } catch (e) {
      // Not every engine build has every iterator helper.
      continue;
    }
    deepFreeze(root);
  }

  // Script globals: read-only and frozen.
  function define(name, value) {
    deepFreeze(value);
    ObjectDefineProperty(global, name, { value, writable: false, enumerable: false, configurable: false });
  }
  ObjectDefineProperty(global, 'tools', { value: tools, writable: false, enumerable: false, configurable: false });
  define('text', text);
  define('image', image);
  define('console', console);
  define('exit', exit);
  define('store', store);
  define('load', load);
  define('searchTools', searchTools);
  define('describeTool', describeTool);
  define('describeNamespace', describeNamespace);
  define('limits', limits);
  define('sleep', sleep);
  define('setTimeout', setTimeout);
  define('clearTimeout', clearTimeout);
  define('models', models);
  define('storedKeys', storedKeys);
  define('history', history);
  define('outputs', outputs);
  define('loadOutput', loadOutput);
  define('keep', keep);

  // ---- Script lifecycle -----------------------------------------------
  function settleValue(v) {
    if (v === undefined) {
      bridgeSettle(true, undefined);
      return;
    }
    let json;
    try {
      json = JSONstringify(v);
    } catch (e) {
      settleError(new TypeErrorCtor('The return value is not JSON-serialisable: ' + describe(e).message));
      return;
    }
    if (json === undefined) {
      settleError(new TypeErrorCtor('The return value is not JSON-serialisable (' + typeof v + ')'));
      return;
    }
    bridgeSettle(true, json);
  }

  function settleError(e) {
    bridgeSettle(false, JSONstringify(describe(e)));
  }

  const hooks = {
    // Called once with `init`, before `exec`.
    init(catalogJson, storeJson) {
      const list = JSONparse(catalogJson);
      const entries = [];
      for (let i = 0; i < list.length; i++) {
        const t = list[i];
        const entry = ObjectFreeze({ id: t.id, name: t.name, namespace: t.namespace, description: t.description });
        ArrayPush(entries, entry);
        if (!MapHas(byKey, t.id)) MapSet(byKey, t.id, t.name);
        if (!MapHas(byKey, t.name)) MapSet(byKey, t.name, t.name);
      }
      catalog = ObjectFreeze(entries);
      define('ALL_TOOLS', catalog);
      const s = JSONparse(storeJson);
      const keys = ObjectKeys(s);
      for (let i = 0; i < keys.length; i++) MapSet(stored, keys[i], JSONstringify(s[keys[i]]));
    },
    // Called once, after `exec`; the runner holds the script's text.
    run() {
      let fn;
      try {
        fn = bridgeCompile();
      } catch (e) {
        settleError(e);
        return;
      }
      const p = fn();
      PromiseThen(p, settleValue, settleError);
    },
    settleCall,
    fireTimer,
    describe(e) {
      return JSONstringify(describe(e));
    },
  };
  return ObjectFreeze(hooks);
})
