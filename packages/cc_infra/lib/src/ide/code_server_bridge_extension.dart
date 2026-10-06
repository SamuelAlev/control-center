import 'package:cc_domain/features/ide/domain/code_server_session.dart';

/// Version of the bundled bridge extension. Bump it (here + in the package.json
/// and .vsix manifest below) to force a reinstall of the shipped source; the
/// installer skips work once `extensions.json` lists this version.
const String codeServerBridgeExtensionVersion = '0.0.12';

/// `package.json` for the bundled bridge extension. It runs in code-server's
/// SERVER-SIDE Node extension host (`main`, activated on startup), so it has
/// full Node (`http`/`process`) — no bundling/build step, just plain JS.
const String codeServerBridgeExtensionPackageJson = '''
{
  "name": "cc-ide-bridge",
  "displayName": "Control Center IDE Bridge",
  "description": "Hands in-editor file navigation back to the Control Center app shell so it owns the tabs.",
  "publisher": "control-center",
  "version": "0.0.12",
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
    <Identity Language="en-US" Id="cc-ide-bridge" Version="0.0.12" Publisher="control-center"/>
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

/// Bundled bridge extension source (CommonJS). One window serves every app tab
/// of a worktree: it logs a random window id the app addresses `open` commands
/// to, switches files on `open`, closes them on `close`, and POSTs in-editor
/// navigation to `CC_IDE_REPORT_URL` (with its window id) so the app focuses
/// or opens that file's tab. Also reports dirty state, consumes
/// `CC_IDE_COMMANDS_URL` SSE (`open` / `close` / `save`), keeps side bars and
/// panel closed on activate + user editor focus (skips programmatic
/// selection), logs a chrome-hidden marker the app waits on before showing the
/// editor, and registers a working-tree quick-diff provider so the gutter
/// shows git changes.
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

// Random id of THIS editor window. Every window of a worktree shares one
// command stream, so an `open` names the window it is for.
const WINDOW_ID = require('crypto').randomUUID();

// The file this window last showed for the app. Active-editor changes to any
// other file are user navigation and get reported; changes while a command
// runs (quietDepth > 0) are our own and only update it.
let current;
let quietDepth = 0;

function activeFsPath() {
  const editor = vscode.window.activeTextEditor;
  return editor && isFile(editor.document.uri) ? editor.document.uri.fsPath : undefined;
}

// Runs fn with navigation reporting muted. The unmute is delayed a beat: the
// workbench can deliver the active-editor change after the command resolves.
async function quietly(fn) {
  quietDepth++;
  try {
    await fn();
  } catch (e) {
  } finally {
    setTimeout(function () {
      quietDepth--;
      if (quietDepth === 0) { current = activeFsPath() || current; }
    }, 150);
  }
}

// The URI fsPath is already open under, else a file URI. The window's boot
// file arrives through the URL payload with its own remote authority; a fresh
// Uri.file for the same path would open a second, separate editor (and buffer)
// beside it.
function uriFor(fsPath) {
  const docs = vscode.workspace.textDocuments || [];
  for (var i = 0; i < docs.length; i++) {
    if (isFile(docs[i].uri) && docs[i].uri.fsPath === fsPath) { return docs[i].uri; }
  }
  const tabs = tabsFor(fsPath);
  return tabs.length > 0 ? tabs[0].input.uri : vscode.Uri.file(fsPath);
}

// Shows fsPath in this window (switching from whatever file the previous app
// tab had), revealing the 1-based line when given. A file VS Code can't open
// as text (an image) goes through the generic open command instead.
async function openByPath(fsPath, line) {
  await quietly(async function () {
    current = fsPath;
    const uri = uriFor(fsPath);
    const options = { preview: false, preserveFocus: false };
    if (typeof line === 'number' && line > 0) {
      const pos = new vscode.Position(line - 1, 0);
      options.selection = new vscode.Range(pos, pos);
    }
    try {
      const doc = await vscode.workspace.openTextDocument(uri);
      await vscode.window.showTextDocument(doc, options);
    } catch (e) {
      await vscode.commands.executeCommand('vscode.open', uri, options);
    }
  });
}

function tabsFor(fsPath) {
  const out = [];
  const groups = vscode.window.tabGroups.all;
  for (var i = 0; i < groups.length; i++) {
    const tabs = groups[i].tabs;
    for (var j = 0; j < tabs.length; j++) {
      const input = tabs[j].input;
      if (input && input.uri && isFile(input.uri) && input.uri.fsPath === fsPath) {
        out.push(tabs[j]);
      }
    }
  }
  return out;
}

// Closes fsPath's editors once its app tab closed. revert discards unsaved
// edits first ("Don't save"); otherwise a dirty editor stays open so nothing
// is lost.
async function closeByPath(fsPath, revert) {
  if (tabsFor(fsPath).length === 0) { return; }
  await quietly(async function () {
    if (revert) {
      const docs = vscode.workspace.textDocuments || [];
      for (var i = 0; i < docs.length; i++) {
        if (isFile(docs[i].uri) && docs[i].uri.fsPath === fsPath && docs[i].isDirty) {
          await vscode.window.showTextDocument(docs[i], { preview: false });
          await vscode.commands.executeCommand('workbench.action.files.revert');
        }
      }
    }
    const clean = tabsFor(fsPath).filter(function (t) { return !t.isDirty; });
    if (clean.length > 0) {
      await vscode.window.tabGroups.close(clean, true);
    }
  });
}

async function handleCommand(msg) {
  if (!msg || typeof msg !== 'object') { return; }
  if (msg.cmd === 'save' && typeof msg.path === 'string') {
    await saveByPath(msg.path);
  } else if (msg.cmd === 'open' && msg.window === WINDOW_ID &&
      typeof msg.path === 'string') {
    await openByPath(msg.path, msg.line);
  } else if (msg.cmd === 'close' && typeof msg.path === 'string') {
    await closeByPath(msg.path, msg.revert === true);
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
    "'$codeServerChromeHiddenMarker';\n"
    "const WINDOW_MARKER = '$codeServerBridgeWindowMarker';"
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
  console.log(WINDOW_MARKER + WINDOW_ID);
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

  // The file the window booted on (the opening app tab's) is not news to the
  // app; any later switch the user makes inside the editor (go to definition,
  // quick open) is reported so the app focuses or opens that file's tab, which
  // then shows this same window.
  current = activeFsPath();
  const sub = vscode.window.onDidChangeActiveTextEditor(function (editor) {
    if (!editor || !isFile(editor.document.uri)) { return; }
    const fsPath = editor.document.uri.fsPath;
    if (quietDepth > 0 || current === undefined) { current = fsPath; return; }
    if (fsPath === current) { return; }
    current = fsPath;
    const line = editor.selection ? editor.selection.active.line : 0;
    report(reportUrl, { path: fsPath, line: line, window: WINDOW_ID });
  });
  context.subscriptions.push(sub);
}

function deactivate() {}

module.exports = { activate, deactivate };
''';
