import 'package:cc_domain/features/ide/domain/code_server_session.dart';

/// Version of the bundled bridge extension. Bump it (here + in the package.json
/// and .vsix manifest below) to force a reinstall of the shipped source; the
/// installer skips work once `extensions.json` lists this version.
const String codeServerBridgeExtensionVersion = '0.0.11';

/// `package.json` for the bundled bridge extension. It runs in code-server's
/// SERVER-SIDE Node extension host (`main`, activated on startup), so it has
/// full Node (`http`/`process`) — no bundling/build step, just plain JS.
const String codeServerBridgeExtensionPackageJson = '''
{
  "name": "cc-ide-bridge",
  "displayName": "Control Center IDE Bridge",
  "description": "Hands in-editor file navigation back to the Control Center app shell so it owns the tabs.",
  "publisher": "control-center",
  "version": "0.0.11",
  "engines": { "vscode": "^1.80.0" },
  "extensionKind": ["workspace"],
  "categories": ["Other"],
  "main": "./extension.js",
  "activationEvents": ["*"]
}
''';

/// Minimal OPC content-types map for the `.vsix` (a ZIP/OPC package). Only the
/// file extensions we ship need declaring.
const String codeServerBridgeVsixContentTypes = '''
<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="json" ContentType="application/json"/>
  <Default Extension="js" ContentType="application/javascript"/>
  <Default Extension="vsixmanifest" ContentType="text/xml"/>
</Types>
''';

/// The `.vsix` package manifest. `code-server --install-extension <vsix>` reads
/// this to register the extension in `extensions.json` (the installed-extensions
/// manifest code-server actually loads from — a bare folder in --extensions-dir
/// is ignored). ExtensionKind `workspace` runs it in the server-side Node host.
const String codeServerBridgeVsixManifest = '''
<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011" xmlns:d="http://schemas.microsoft.com/developer/vsx-schema-design/2011">
  <Metadata>
    <Identity Language="en-US" Id="cc-ide-bridge" Version="0.0.11" Publisher="control-center"/>
    <DisplayName>Control Center IDE Bridge</DisplayName>
    <Description xml:space="preserve">Hands in-editor file navigation to the Control Center app shell.</Description>
    <Tags>__ext_control-center</Tags>
    <Categories>Other</Categories>
    <GalleryFlags>Public</GalleryFlags>
    <Properties>
      <Property Id="Microsoft.VisualStudio.Code.Engine" Value="^1.80.0"/>
      <Property Id="Microsoft.VisualStudio.Code.ExtensionKind" Value="workspace"/>
    </Properties>
  </Metadata>
  <Installation>
    <InstallationTarget Id="Microsoft.VisualStudio.Code"/>
  </Installation>
  <Dependencies/>
  <Assets>
    <Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true"/>
  </Assets>
</PackageManifest>
''';

/// Bundled bridge extension source (CommonJS). Each window pins its entry
/// file; navigation POSTs the target to `CC_IDE_REPORT_URL` (app opens a tab)
/// and closes the drifted editor. Also reports dirty state, consumes
/// `CC_IDE_COMMANDS_URL` SSE (`save`), keeps side bars/panel closed on
/// activate + user editor focus (skips programmatic selection), logs a
/// chrome-hidden marker the app waits on before showing the editor, and
/// registers a working-tree quick-diff provider so the gutter shows git changes.
const String codeServerBridgeExtensionSource =
    r'''
const vscode = require('vscode');
const http = require('http');
const https = require('https');
const { URL } = require('url');

function isFile(uri) {
  return !!uri && (uri.scheme === 'file' || uri.scheme === 'vscode-remote');
}

function report(reportUrl, body) {
  try {
    const u = new URL(reportUrl);
    const data = Buffer.from(JSON.stringify(body));
    const lib = u.protocol === 'https:' ? https : http;
    const req = lib.request({
      hostname: u.hostname,
      port: u.port,
      path: u.pathname + u.search,
      method: 'POST',
      // Loopback POST to our own cc_server; a self-signed TLS cert on a remote
      // server must not block the report.
      rejectUnauthorized: false,
      headers: {
        'content-type': 'application/json',
        'content-length': data.length
      }
    });
    req.on('error', function () {});
    req.write(data);
    req.end();
  } catch (e) {}
}

// Watches every text document's dirty state and reports each dirty↔clean
// transition (edge-triggered, so no per-keystroke spam) to the app. Also serves
// as the ack for a Save command: after a save, onDidSaveTextDocument fires with
// isDirty=false, which reports clean. Returns disposables for the caller to
// register on the extension context.
function installDirtyWatchers(reportUrl) {
  const dirtyByPath = Object.create(null);
  function sync(doc) {
    if (!doc || !isFile(doc.uri)) { return; }
    const path = doc.uri.fsPath;
    const dirty = !!doc.isDirty;
    if (dirtyByPath[path] === dirty) { return; }
    dirtyByPath[path] = dirty;
    report(reportUrl, { type: 'dirty', path: path, dirty: dirty });
  }
  return [
    vscode.workspace.onDidChangeTextDocument(function (e) { sync(e.document); }),
    vscode.workspace.onDidSaveTextDocument(function (doc) { sync(doc); }),
    vscode.workspace.onDidOpenTextDocument(function (doc) { sync(doc); }),
    vscode.workspace.onDidCloseTextDocument(function (doc) {
      // The document (and its buffer) is gone; if it was tracked dirty, report
      // clean so the app clears the dot, then forget it.
      if (!doc || !isFile(doc.uri)) { return; }
      const path = doc.uri.fsPath;
      if (dirtyByPath[path]) {
        report(reportUrl, { type: 'dirty', path: path, dirty: false });
      }
      delete dirtyByPath[path];
    }),
  ];
}

// Saves the open document at [fsPath] to disk. Prefers the modern
// `workspace.save(uri)` (VS Code >=1.86); falls back to focusing the editor and
// running the save command on older builds. Best-effort — a save that can't find
// the document is a no-op (the file may already be clean/closed).
async function saveByPath(fsPath) {
  try {
    const docs = vscode.workspace.textDocuments || [];
    let target;
    for (var i = 0; i < docs.length; i++) {
      if (isFile(docs[i].uri) && docs[i].uri.fsPath === fsPath) {
        target = docs[i];
        break;
      }
    }
    if (!target) { return; }
    if (typeof vscode.workspace.save === 'function') {
      await vscode.workspace.save(target.uri);
    } else {
      await vscode.window.showTextDocument(target, { preview: false });
      await vscode.commands.executeCommand('workbench.action.files.save');
    }
  } catch (e) {}
}

async function handleCommand(msg) {
  if (!msg || typeof msg !== 'object') { return; }
  if (msg.cmd === 'save' && typeof msg.path === 'string') {
    await saveByPath(msg.path);
  }
}

// Opens the reverse command endpoint as a long-lived SSE stream and dispatches
// each `data:` line to handleCommand. Auto-reconnects (1s) on drop so a
// dropped/rebound cc_server socket doesn't permanently sever commands. Returns a
// disposable that stops reconnecting.
function subscribeCommands(commandsUrl) {
  let closed = false;
  function connect() {
    if (closed) { return; }
    let u;
    try { u = new URL(commandsUrl); } catch (e) { return; }
    const lib = u.protocol === 'https:' ? https : http;
    const req = lib.request({
      hostname: u.hostname,
      port: u.port,
      path: u.pathname + u.search,
      method: 'GET',
      rejectUnauthorized: false,
      headers: { 'accept': 'text/event-stream' }
    }, function (res) {
      res.setEncoding('utf8');
      let buf = '';
      res.on('data', function (chunk) {
        buf += chunk;
        let idx;
        while ((idx = buf.indexOf('\n')) >= 0) {
          const line = buf.slice(0, idx).trim();
          buf = buf.slice(idx + 1);
          if (line.indexOf('data:') === 0) {
            const json = line.slice(5).trim();
            if (json) {
              try { handleCommand(JSON.parse(json)); } catch (e) {}
            }
          }
        }
      });
      res.on('end', reconnect);
      res.on('error', reconnect);
    });
    req.on('error', reconnect);
    req.end();
  }
  function reconnect() {
    if (closed) { return; }
    setTimeout(connect, 1000);
  }
  connect();
  return { dispose: function () { closed = true; } };
}

// Logged once the boot-time hide below has settled. The remote extension host
// forwards console output to its own window's renderer console, so the app's
// webview sees it for exactly this window and only then uncovers the editor.
const CHROME_HIDDEN_MARKER = '''
    "'$codeServerChromeHiddenMarker';"
    r'''

function runQuietly(command) {
  return Promise.resolve()
    .then(function () { return vscode.commands.executeCommand(command); })
    .catch(function () {});
}

function closeChrome() {
  // Close the primary (Explorer) and secondary (auxiliary) side bars AND the
  // bottom panel (Problems / Output / Terminal) so the embedded editor is just
  // the code — the app shell owns that chrome. All three commands are CLOSES,
  // not toggles: idempotent (a no-op when already closed), so they can never
  // accidentally re-open. Resolves once all three have run.
  return Promise.all([
    runQuietly('workbench.action.closeSidebar'),
    runQuietly('workbench.action.closeAuxiliaryBar'),
    runQuietly('workbench.action.closePanel'),
  ]);
}

async function hideChromeOnBoot() {
  // Opening a folder (?folder=) restores the Explorer as the workbench finishes
  // booting, the secondary side bar can reappear once a view (e.g. chat)
  // resolves into it, and the panel can pop for a diagnostic. A couple of
  // retries cover that; each is harmless. Later reappearances (Cmd+B, a view
  // resolving after the retries) are handled by the selection listener below.
  closeChrome();
  setTimeout(closeChrome, 250);
  await new Promise(function (resolve) { setTimeout(resolve, 800); });
  await closeChrome();
  console.log(CHROME_HIDDEN_MARKER);
}

function shouldHideFromSelection(e) {
  if (!e || !e.textEditor) { return false; }
  // Output / debug consoles aren't the editor surface; hiding on those would
  // snap chrome shut while the user is reading them.
  const scheme = e.textEditor.document.uri.scheme;
  if (scheme === 'output' || scheme === 'debug') { return false; }
  // Mouse click or caret in the editor = the user is working in the file.
  // Skip Command / undefined so a programmatic reveal (Explorer, SCM, the
  // go-to-definition hand-off below) cannot close chrome as a side effect of
  // clicking a view.
  const Kind = vscode.TextEditorSelectionChangeKind;
  return e.kind === Kind.Mouse || e.kind === Kind.Keyboard;
}

// Pin the active (entry) editor so a preview open — go-to-definition, quick
// open — can't REUSE and REPLACE it; the target instead lands in a separate
// editor the hand-off below closes. `pinEditor` is a pin, not a toggle
// (idempotent — a no-op on an already-pinned editor). Best-effort.
function pinEntry() {
  try {
    vscode.commands.executeCommand('workbench.action.pinEditor');
  } catch (e) {}
}

// Bring the pinned entry file back to the foreground. After the drifted editor
// is closed the pinned entry is usually still open, so this is a cheap focus; it
// reopens (and re-pins) only if the entry was somehow lost. Best-effort.
async function revealEntry(entry) {
  const still = vscode.window.activeTextEditor;
  if (still && isFile(still.document.uri) && still.document.uri.fsPath === entry) {
    return;
  }
  try {
    const doc = await vscode.workspace.openTextDocument(vscode.Uri.file(entry));
    await vscode.window.showTextDocument(doc, { preview: false });
    pinEntry();
  } catch (e) {}
}

// Git's quick-diff provider is scoped to the repository root. In this
// embedded window that root does not match the editor resource, so the
// built-in provider never runs and the gutter stays blank. This one has no
// root filter. The extension host sees the resource as a file URI; the
// original is the git filesystem's HEAD (index for a tracked file, empty
// tree for an untracked one) so added, modified and deleted lines mark
// while the buffer is open.
const GIT_EMPTY_TREE = '4b825dc642cb6eb9a060e54bf8d69288fbee4904';
const GIT_IGNORED = 8;

function gitOriginalUri(fileUri, ref) {
  return fileUri.with({
    scheme: 'git',
    path: fileUri.path + '.git',
    query: JSON.stringify({ path: fileUri.fsPath, ref: ref })
  });
}

function isInsideDotGit(fsPath) {
  const path = require('path');
  const parts = fsPath.split(path.sep);
  for (var i = 0; i < parts.length; i++) {
    if (parts[i] === '.git') return true;
  }
  return false;
}

async function gitApi() {
  const ext = vscode.extensions.getExtension('vscode.git');
  if (!ext) return null;
  const exports = ext.isActive ? ext.exports : await ext.activate();
  if (!exports || typeof exports.getAPI !== 'function') return null;
  try { return exports.getAPI(1); } catch (e) { return null; }
}

async function provideWorkingTreeOriginal(uri) {
  if (!isFile(uri)) return;
  const fsPath = uri.fsPath;
  if (!fsPath || isInsideDotGit(fsPath)) return;
  try {
    const fs = require('fs');
    if (fs.lstatSync(fsPath).isSymbolicLink()) return;
  } catch (e) { return; }
  const api = await gitApi();
  if (!api) return;
  const fileUri = uri.scheme === 'file' ? uri : vscode.Uri.file(fsPath);
  const repo = api.getRepository(fileUri);
  if (!repo || !repo.state) return;
  const state = repo.state;
  const merge = state.mergeChanges || [];
  for (var i = 0; i < merge.length; i++) {
    if (merge[i].uri && merge[i].uri.fsPath === fsPath) return;
  }
  const untracked = state.untrackedChanges || [];
  for (var j = 0; j < untracked.length; j++) {
    if (!untracked[j].uri || untracked[j].uri.fsPath !== fsPath) continue;
    if (untracked[j].status === GIT_IGNORED) return;
    return gitOriginalUri(fileUri, GIT_EMPTY_TREE);
  }
  return gitOriginalUri(fileUri, '');
}

function installQuickDiff(context) {
  let reg;
  function register() {
    if (reg) reg.dispose();
    reg = vscode.window.registerQuickDiffProvider(
      [{ scheme: 'file' }, { scheme: 'vscode-remote' }],
      { provideOriginalResource: provideWorkingTreeOriginal },
      'Working tree'
    );
  }
  register();
  context.subscriptions.push({ dispose: function () { if (reg) reg.dispose(); } });
  gitApi().then(function (api) {
    if (!api || typeof api.onDidOpenRepository !== 'function') return;
    context.subscriptions.push(api.onDidOpenRepository(function () { register(); }));
  }).catch(function () {});
}

function activate(context) {
  installQuickDiff(context);
  hideChromeOnBoot();
  // Chrome can come back after the boot retries. Re-hide when the user actually
  // clicks or moves the caret in the editor — not on programmatic selection
  // changes, so opening a view doesn't immediately snap it shut.
  context.subscriptions.push(
    vscode.window.onDidChangeTextEditorSelection(function (e) {
      if (!shouldHideFromSelection(e)) { return; }
      closeChrome();
    })
  );

  const reportUrl = process.env.CC_IDE_REPORT_URL;

  // Unsaved-changes reporting (drives the app's per-tab dirty dot) rides the
  // same report endpoint, independent of the navigation hand-off below.
  if (reportUrl) {
    const dirtySubs = installDirtyWatchers(reportUrl);
    for (var i = 0; i < dirtySubs.length; i++) {
      context.subscriptions.push(dirtySubs[i]);
    }
  }

  // Reverse command channel (Save-on-close, …): independent of reportUrl.
  const commandsUrl = process.env.CC_IDE_COMMANDS_URL;
  if (commandsUrl) {
    context.subscriptions.push(subscribeCommands(commandsUrl));
  }

  if (!reportUrl) { return; }

  // The file THIS editor window was opened on. The app shell owns tabs, so any
  // navigation to a different file is handed back to the app and this window is
  // pinned to its entry file.
  let entry;
  const initial = vscode.window.activeTextEditor;
  if (initial && isFile(initial.document.uri)) {
    entry = initial.document.uri.fsPath;
    pinEntry();
  }

  let handling = false;
  const sub = vscode.window.onDidChangeActiveTextEditor(async function (editor) {
    if (!editor || handling) { return; }
    const uri = editor.document.uri;
    if (!isFile(uri)) { return; }
    const fsPath = uri.fsPath;
    // The first file this window sees becomes its pinned entry.
    if (entry === undefined) { entry = fsPath; pinEntry(); return; }
    if (fsPath === entry) { return; }
    handling = true;
    try {
      const line = editor.selection ? editor.selection.active.line : 0;
      // Hand the target to the app shell (it opens a NEW app tab), then drop the
      // drifted editor and reveal the pinned entry so this window never shows a
      // file other than the one it was opened on.
      report(reportUrl, { path: fsPath, line: line });
      await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
      await revealEntry(entry);
    } catch (e) {
      // best-effort — never break the editor over a failed hand-off
    } finally {
      handling = false;
    }
  });
  context.subscriptions.push(sub);
}

function deactivate() {}

module.exports = { activate, deactivate };
''';
