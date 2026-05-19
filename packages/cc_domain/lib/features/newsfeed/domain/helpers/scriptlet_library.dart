import 'dart:convert';

/// Generates the JavaScript body for a uBO-style scriptlet by name +
/// args. Returns null if [name] isn't in our library — caller drops the
/// rule silently.
///
/// These are **clean-room re-implementations** of uBlock Origin's
/// scriptlets, not copies. uBO's `scriptlets.js` is GPL-3 and we don't
/// want to inherit that license into this codebase; we mirror the
/// behavior contract (same rule names + same arg conventions so existing
/// filter rules work) but the implementation is ours.
///
/// Each generated script is wrapped in an IIFE with `try/catch` so a
/// failure inside one scriptlet cannot break either the host page or
/// other scriptlets running on the same page.
///
/// Supported scriptlets (with common aliases):
/// - `prevent-addEventListener` / `aeld` / `prevent-addeventlistener`
/// - `set-constant` / `set`
/// - `abort-on-property-read` / `aopr`
/// - `no-setInterval-if` / `nostif` / `setInterval-defuser` /
///   `prevent-setInterval`
/// - `no-setTimeout-if` / `nosttf` / `setTimeout-defuser` /
///   `prevent-setTimeout`
/// - `abort-current-script` / `acs` / `acis`
/// - `remove-node-text` / `rmnt`
/// - `set-attr` / `sa`
/// - `trusted-click-element` / `click-element`
/// - `cookie-remover` / `remove-cookie`
/// - `set-local-storage-item` / `set-localStorage-item` /
///   `set-localstorage-item`
String? generateScriptletJs(String name, List<String> args) {
  switch (name) {
    case 'prevent-addEventListener':
    case 'aeld':
    case 'prevent-addeventlistener':
      return _preventAddEventListener(args);
    case 'set-constant':
    case 'set':
      return _setConstant(args);
    case 'abort-on-property-read':
    case 'aopr':
      return _abortOnPropertyRead(args);
    case 'no-setInterval-if':
    case 'nostif':
    case 'setInterval-defuser':
    case 'prevent-setInterval':
      return _noSetIntervalIf(args);
    case 'no-setTimeout-if':
    case 'nosttf':
    case 'setTimeout-defuser':
    case 'prevent-setTimeout':
      return _noSetTimeoutIf(args);
    case 'abort-current-script':
    case 'acs':
    case 'acis':
      return _abortCurrentScript(args);
    case 'remove-node-text':
    case 'rmnt':
      return _removeNodeText(args);
    case 'set-attr':
    case 'sa':
      return _setAttr(args);
    case 'trusted-click-element':
    case 'click-element':
      return _trustedClickElement(args);
    case 'cookie-remover':
    case 'remove-cookie':
      return _cookieRemover(args);
    case 'set-local-storage-item':
    case 'set-localStorage-item':
    case 'set-localstorage-item':
      return _setLocalStorageItem(args);
    default:
      return null;
  }
}

/// `prevent-addEventListener(type, pattern)` — block matching event
/// listener registrations. Both args are optional substrings; if either
/// is a `/regex/` literal it's compiled to RegExp.
String _preventAddEventListener(List<String> args) {
  final type = jsonEncode(args.isNotEmpty ? args[0] : '');
  final pattern = jsonEncode(args.length > 1 ? args[1] : '');
  return '''
(function(){try{
  var T=$type, P=$pattern, R=null;
  if (P && P.length>2 && P[0]==='/' && P[P.length-1]==='/') {
    try { R = new RegExp(P.slice(1,-1)); } catch(e){}
  }
  var orig = EventTarget.prototype.addEventListener;
  EventTarget.prototype.addEventListener = function(type, listener){
    try {
      var typeOk = !T || (typeof type==='string' && type.indexOf(T)!==-1);
      var src = '';
      try { src = String(listener); } catch(e){}
      var srcOk = !P || (R ? R.test(src) : src.indexOf(P)!==-1);
      if (typeOk && srcOk) return;
    } catch(e){}
    return orig.apply(this, arguments);
  };
}catch(e){}})();''';
}

/// `set-constant(chain, value)` — lock a property at the dotted path
/// to the given constant value. Supports uBO's special value tokens:
/// `undefined`, `null`, `true`, `false`, `''`, `noopFunc`, `trueFunc`,
/// `falseFunc`, or any numeric literal.
String _setConstant(List<String> args) {
  if (args.isEmpty) {
    return '(function(){})();';
  }
  final chain = jsonEncode(args[0]);
  final raw = jsonEncode(args.length > 1 ? args[1] : '');
  return '''
(function(){try{
  var CHAIN=$chain, RAW=$raw, value;
  switch(RAW){
    case 'undefined': value=undefined; break;
    case 'null': value=null; break;
    case 'true': value=true; break;
    case 'false': value=false; break;
    case '': value=''; break;
    case 'noopFunc': value=function(){}; break;
    case 'trueFunc': value=function(){return true;}; break;
    case 'falseFunc': value=function(){return false;}; break;
    case 'noopArray': value=[]; break;
    case 'emptyObj': value={}; break;
    default:
      if (/^-?\\d+(\\.\\d+)?\$/.test(RAW)) value=Number(RAW);
      else value=RAW;
  }
  var parts=CHAIN.split('.');
  var obj=window;
  for (var i=0; i<parts.length-1; i++){
    var k=parts[i];
    if (typeof obj[k]!=='object' || obj[k]===null) {
      try { obj[k] = {}; } catch(e){ return; }
    }
    obj=obj[k];
  }
  var last=parts[parts.length-1];
  try {
    Object.defineProperty(obj, last, {
      get: function(){ return value; },
      set: function(){},
      configurable: false,
    });
  } catch(e){
    try { obj[last] = value; } catch(e2){}
  }
}catch(e){}})();''';
}

/// `abort-on-property-read(chain)` — throw a ReferenceError when the
/// property at the dotted chain is read. Defeats anti-adblock probes
/// like `if (window.canRunAds) { ... }`.
String _abortOnPropertyRead(List<String> args) {
  if (args.isEmpty) {
    return '(function(){})();';
  }
  final chain = jsonEncode(args[0]);
  return '''
(function(){try{
  var CHAIN=$chain;
  var parts=CHAIN.split('.');
  var last=parts.pop();
  var obj=window;
  for (var i=0; i<parts.length; i++){
    var k=parts[i];
    if (typeof obj[k]!=='object' || obj[k]===null) {
      try { obj[k] = {}; } catch(e){ return; }
    }
    obj=obj[k];
  }
  var msg='aopr-'+Math.random().toString(36).slice(2);
  try {
    Object.defineProperty(obj, last, {
      get: function(){ throw new ReferenceError(msg); },
      set: function(){},
      configurable: false,
    });
  } catch(e){}
}catch(e){}})();''';
}

/// `no-setInterval-if(pattern, delay?)` — drop setInterval calls whose
/// handler source matches the pattern. Pattern may be a substring or a
/// `/regex/` literal; a leading `!` negates the match. The optional
/// delay arg further constrains by interval length.
String _noSetIntervalIf(List<String> args) {
  return _noTimerIf(args, isInterval: true);
}

/// `no-setTimeout-if(pattern, delay?)` — same as [_noSetIntervalIf] but
/// for `setTimeout`.
String _noSetTimeoutIf(List<String> args) {
  return _noTimerIf(args, isInterval: false);
}

/// `abort-current-script(target, needle, magic?)` — installs a getter
/// on the dotted property path `target` that, when read, inspects the
/// currently-executing inline script. If its source contains `needle`
/// (or matches the regex if `needle` is `/.../`) the getter throws to
/// abort the calling script. Defeats anti-adblock probes that branch on
/// `document.getElementsByTagName`, `Object.defineProperty`, etc.
String _abortCurrentScript(List<String> args) {
  if (args.isEmpty) {
    return '(function(){})();';
  }
  final target = jsonEncode(args[0]);
  final needle = jsonEncode(args.length > 1 ? args[1] : '');
  return '''
(function(){try{
  var TARGET=$target, N=$needle, R=null;
  if (N && N.length>2 && N[0]==='/' && N[N.length-1]==='/') {
    try { R = new RegExp(N.slice(1,-1)); } catch(e){}
  }
  var parts=TARGET.split('.');
  var last=parts.pop();
  var obj=window;
  for (var i=0; i<parts.length; i++){
    var k=parts[i];
    if (obj==null || (typeof obj[k]!=='object' && typeof obj[k]!=='function')) return;
    obj=obj[k];
  }
  if (obj==null) return;
  var original = obj[last];
  var validate = function(){
    var cs = document.currentScript;
    if (!cs) return;
    var src='';
    try { src = (cs.textContent || '') + ' ' + (cs.src || ''); } catch(e){}
    if (!src) return;
    var match = !N || (R ? R.test(src) : src.indexOf(N)!==-1);
    if (match) throw new ReferenceError('acs-abort');
  };
  try {
    Object.defineProperty(obj, last, {
      get: function(){ validate(); return original; },
      set: function(v){ original = v; },
      configurable: false,
    });
  } catch(e){}
}catch(e){}})();''';
}

/// `remove-node-text(tagName, pattern, attrName?, attrValue?)` — strips
/// `textContent` from nodes matching the given tag name (and optionally
/// an attribute) when the text matches the pattern (substring or
/// `/regex/` literal).
///
/// Best-effort for inline `<script>` elements: hooks the
/// `textContent` / `text` / `innerText` setters on the relevant
/// prototype so JS-created scripts can be neutralised before insertion,
/// and falls back to a MutationObserver for nodes added by the parser.
/// HTML-parser-inserted inline scripts that execute synchronously can
/// still slip through — that's a limitation of running in user-land
/// without access to a `beforescriptexecute` hook on modern browsers.
String _removeNodeText(List<String> args) {
  if (args.length < 2) {
    return '(function(){})();';
  }
  final tag = jsonEncode(args[0].toLowerCase());
  final pattern = jsonEncode(args[1]);
  final attrName = jsonEncode(args.length > 2 ? args[2] : '');
  final attrValue = jsonEncode(args.length > 3 ? args[3] : '');
  return '''
(function(){try{
  var TAG=$tag, P=$pattern, AN=$attrName, AV=$attrValue, R=null;
  if (P && P.length>2 && P[0]==='/' && P[P.length-1]==='/') {
    try { R = new RegExp(P.slice(1,-1)); } catch(e){}
  }
  var matchText = function(t){
    if (!t) return false;
    return R ? R.test(t) : (t.indexOf(P)!==-1);
  };
  var matchEl = function(el){
    if (!el || !el.tagName || el.tagName.toLowerCase() !== TAG) return false;
    if (AN && el.getAttribute(AN) !== AV) return false;
    return true;
  };
  // 1) Hook the textContent setter on HTMLScriptElement so JS-built
  //    scripts with matching bodies get blanked before insertion.
  if (TAG === 'script') {
    try {
      var proto = HTMLScriptElement.prototype;
      var desc = Object.getOwnPropertyDescriptor(proto, 'textContent') ||
                 Object.getOwnPropertyDescriptor(Node.prototype, 'textContent');
      if (desc && desc.set) {
        var origSet = desc.set;
        Object.defineProperty(proto, 'textContent', {
          configurable: true,
          enumerable: desc.enumerable,
          get: desc.get,
          set: function(v){
            try {
              if (typeof v === 'string' && matchText(v)) return;
            } catch(e){}
            return origSet.call(this, v);
          },
        });
      }
    } catch(e){}
  }
  // 2) MutationObserver to catch nodes inserted by the parser.
  var sweep = function(root){
    try {
      if (!root || !root.querySelectorAll) return;
      var els = root.querySelectorAll(TAG);
      for (var i=0; i<els.length; i++){
        var el = els[i];
        if (matchEl(el) && matchText(el.textContent)) {
          try { el.textContent = ''; } catch(e){}
          try { el.remove(); } catch(e){}
        }
      }
    } catch(e){}
  };
  try { sweep(document); } catch(e){}
  try {
    new MutationObserver(function(muts){
      for (var i=0; i<muts.length; i++){
        var added = muts[i].addedNodes;
        for (var j=0; j<added.length; j++){
          var n = added[j];
          if (n.nodeType !== 1) continue;
          if (matchEl(n) && matchText(n.textContent)) {
            try { n.textContent = ''; } catch(e){}
            try { n.remove(); } catch(e){}
          } else {
            sweep(n);
          }
        }
      }
    }).observe(document.documentElement, {childList: true, subtree: true});
  } catch(e){}
}catch(e){}})();''';
}

/// `set-attr(selector, attr, value)` — sets `attr=value` on every
/// element matching the given selector, applied at injection time and
/// re-run when new matching nodes appear via MutationObserver.
String _setAttr(List<String> args) {
  if (args.length < 2) {
    return '(function(){})();';
  }
  final selector = jsonEncode(args[0]);
  final attr = jsonEncode(args[1]);
  final value = jsonEncode(args.length > 2 ? args[2] : '');
  return '''
(function(){try{
  var SEL=$selector, ATTR=$attr, VAL=$value;
  if (!SEL || !ATTR) return;
  var apply = function(){
    try {
      var els = document.querySelectorAll(SEL);
      for (var i=0; i<els.length; i++){
        try { els[i].setAttribute(ATTR, VAL); } catch(e){}
      }
    } catch(e){}
  };
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', apply, {once: true});
  } else {
    apply();
  }
  try {
    new MutationObserver(apply).observe(
      document.documentElement,
      {childList: true, subtree: true}
    );
  } catch(e){}
}catch(e){}})();''';
}

String _noTimerIf(List<String> args, {required bool isInterval}) {
  final pattern = jsonEncode(args.isNotEmpty ? args[0] : '');
  final delay = jsonEncode(args.length > 1 ? args[1] : '');
  final fn = isInterval ? 'setInterval' : 'setTimeout';
  return '''
(function(){try{
  var P=$pattern, D=$delay, NEG=false;
  if (P && P[0]==='!') { NEG=true; P=P.slice(1); }
  var R=null;
  if (P && P.length>2 && P[0]==='/' && P[P.length-1]==='/') {
    try { R = new RegExp(P.slice(1,-1)); } catch(e){}
  }
  var delayMatch = function(actual){
    if (!D) return true;
    var d = D;
    var neg = false;
    if (d[0]==='!') { neg = true; d = d.slice(1); }
    var ok = String(actual) === d;
    return neg ? !ok : ok;
  };
  var orig=window.$fn;
  window.$fn = function(handler, t){
    try {
      var src=''; try { src=String(handler); } catch(e){}
      var srcOk = !P || (R ? R.test(src) : src.indexOf(P)!==-1);
      var d = delayMatch(t);
      var match = srcOk && d;
      if (NEG ? !match : match) return 0;
    } catch(e){}
    return orig.apply(this, arguments);
  };
}catch(e){}})();''';
}

/// `trusted-click-element(selector, text?, delay?)` — programmatically
/// clicks every element matching `selector` as soon as it appears AND
/// is visible. Waits `delay` ms (default 0) after DOM ready before the
/// first attempt, then keeps a MutationObserver running for the full
/// page lifetime so banners that:
/// - are injected long after DOMContentLoaded (TechCrunch / Didomi
///   often defer banner mount by several seconds),
/// - are pre-rendered hidden and revealed later via a CSS class flip
///   (matched by the `attributes: true` observer option),
/// - re-appear after a first click is rejected (CMPs that detect
///   `isTrusted: false` and re-show themselves),
/// all still get dismissed.
///
/// Click attempts are throttled to once per 500 ms so a stubborn page
/// can't pin the CPU. Only elements with a non-zero bounding box are
/// clicked — CMP buttons usually live in the DOM long before they're
/// shown, and clicking them while hidden does nothing useful.
String _trustedClickElement(List<String> args) {
  if (args.isEmpty) {
    return '(function(){})();';
  }
  final selector = jsonEncode(args[0]);
  final text = jsonEncode(args.length > 1 ? args[1] : '');
  final delayMs = args.length > 2 ? int.tryParse(args[2].trim()) ?? 0 : 0;
  return '''
(function(){try{
  var SEL=$selector, TXT=$text, DELAY=$delayMs;
  if (!SEL) return;
  var THROTTLE_MS = 500;
  var lastClickAt = 0;
  var fireClick = function(el){
    // Belt-and-braces: dispatch a full pointer/mouse event sequence
    // *and* call .click(). Some CMP buttons (Didomi included) hook
    // pointerdown/mouseup rather than the click handler.
    var rect, cx = 0, cy = 0;
    try { rect = el.getBoundingClientRect(); } catch(e){}
    if (rect) { cx = rect.left + rect.width/2; cy = rect.top + rect.height/2; }
    var fire = function(type){
      try {
        var ev = new MouseEvent(type, {
          bubbles: true, cancelable: true, view: window,
          button: 0, buttons: 1, clientX: cx, clientY: cy,
        });
        el.dispatchEvent(ev);
      } catch(e){}
    };
    fire('pointerdown');
    fire('mousedown');
    fire('pointerup');
    fire('mouseup');
    fire('click');
    try { el.click(); } catch(e){}
  };
  var isClickable = function(el){
    try {
      var r = el.getBoundingClientRect();
      if (r.width === 0 || r.height === 0) return false;
      var s = window.getComputedStyle ? window.getComputedStyle(el) : null;
      if (s && (s.visibility === 'hidden' || s.display === 'none')) return false;
      return true;
    } catch(e){ return true; }
  };
  var tryClick = function(){
    var now = Date.now();
    if (now - lastClickAt < THROTTLE_MS) return;
    var els;
    try { els = document.querySelectorAll(SEL); } catch(e){ return; }
    for (var i=0; i<els.length; i++){
      var el = els[i];
      if (TXT) {
        var t = '';
        try { t = el.textContent || ''; } catch(e){}
        if (t.indexOf(TXT) === -1) continue;
      }
      if (!isClickable(el)) continue;
      try { fireClick(el); lastClickAt = now; return; } catch(e){}
    }
  };
  var start = function(){
    setTimeout(function(){
      tryClick();
      try {
        new MutationObserver(function(){ tryClick(); }).observe(
          document.documentElement,
          {childList: true, subtree: true, attributes: true}
        );
      } catch(e){}
    }, DELAY);
  };
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start, {once: true});
  } else {
    start();
  }
}catch(e){}})();''';
}

/// `cookie-remover(name)` — periodically clears cookies whose name
/// matches the given substring or `/regex/` literal. Expires the cookie
/// on the current path *and* every parent-domain suffix (CMPs often set
/// the consent cookie at the apex domain like `.theverge.com` rather
/// than at the page host, so we need to attack all suffixes).
String _cookieRemover(List<String> args) {
  if (args.isEmpty) {
    return '(function(){})();';
  }
  final name = jsonEncode(args[0]);
  return '''
(function(){try{
  var N=$name, R=null;
  if (N && N.length>2 && N[0]==='/' && N[N.length-1]==='/') {
    try { R = new RegExp(N.slice(1,-1)); } catch(e){}
  }
  var EPOCH = 'Thu, 01 Jan 1970 00:00:00 GMT';
  var sweep = function(){
    try {
      var raw = document.cookie || '';
      if (!raw) return;
      var entries = raw.split(';');
      var parts = location.hostname.split('.');
      for (var i=0; i<entries.length; i++){
        var c = entries[i].trim();
        var eq = c.indexOf('=');
        var k = eq > 0 ? c.slice(0, eq) : c;
        if (!k) continue;
        var match = R ? R.test(k) : k.indexOf(N) !== -1;
        if (!match) continue;
        try { document.cookie = k + '=; expires='+EPOCH+'; path=/'; } catch(e){}
        for (var j=0; j<parts.length-1; j++){
          var dom = '.' + parts.slice(j).join('.');
          try {
            document.cookie = k + '=; expires='+EPOCH+'; path=/; domain=' + dom;
          } catch(e){}
        }
      }
    } catch(e){}
  };
  sweep();
  try { setInterval(sweep, 1000); } catch(e){}
}catch(e){}})();''';
}

/// `set-local-storage-item(key, value)` — writes a value into
/// `localStorage[key]`. Supports the same special tokens as
/// `set-constant` (`true`, `false`, `null`, `''`, numeric literals…)
/// plus the uBO sentinel `\$remove\$` which deletes the key instead.
/// Used to short-circuit CMP self-checks like
/// `if (localStorage.getItem('consent') === 'true') skipBanner()`.
String _setLocalStorageItem(List<String> args) {
  if (args.length < 2) {
    return '(function(){})();';
  }
  final key = jsonEncode(args[0]);
  final raw = jsonEncode(args[1]);
  return '''
(function(){try{
  var K=$key, RAW=$raw;
  if (!K) return;
  if (RAW === '\$remove\$') {
    try { localStorage.removeItem(K); } catch(e){}
    return;
  }
  var v;
  switch(RAW){
    case 'undefined': v='undefined'; break;
    case 'null': v='null'; break;
    case 'true': v='true'; break;
    case 'false': v='false'; break;
    case '': v=''; break;
    case 'emptyObj': v='{}'; break;
    case 'emptyArr': v='[]'; break;
    case 'yes': v='yes'; break;
    case 'no': v='no'; break;
    default:
      if (/^-?\\d+(\\.\\d+)?\$/.test(RAW)) v=RAW;
      else v=RAW;
  }
  try { localStorage.setItem(K, v); } catch(e){}
}catch(e){}})();''';
}
