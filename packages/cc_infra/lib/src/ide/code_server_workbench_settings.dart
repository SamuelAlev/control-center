part of 'code_server_service.dart';

// Workbench settings belong to the editor session service but do not involve
// process lifecycle or device-bound authorization.
extension _CodeServerWorkbenchSettings on CodeServerService {
  /// Seeds code-server User `settings.json`: trusted + editor-only chrome.
  ///
  /// Trust avoids language-server/tasks/debug prompts the embed cannot answer.
  /// Hides activity/status/tab/menu/chat chrome (app shell owns those); bridge
  /// closes side bars/panel on activation and editor focus. `showTabs: none` so
  /// navigation replaces the single editor (no competing VS Code tabs).
  /// [autoSave] written verbatim after sanitise; merges existing settings.
  Future<void> _ensureWorkbenchSettings(
    String workspaceId,
    String autoSave,
  ) async {
    final userDir = Directory(p.join(_userDataDir(workspaceId), 'User'));
    await userDir.create(recursive: true);
    final file = File(p.join(userDir.path, 'settings.json'));
    var settings = <String, dynamic>{};
    if (file.existsSync()) {
      try {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map<String, dynamic>) {
          settings = decoded;
        }
      } catch (_) {
        // Corrupt / hand-edited — overwrite rather than fail the open.
      }
    }
    // Trust: open the worktree without Restricted Mode.
    settings['security.workspace.trust.enabled'] = false;
    settings['security.workspace.trust.startupPrompt'] = 'never';
    settings['security.workspace.trust.banner'] = 'never';
    settings['security.workspace.trust.emptyWindow'] = false;
    // Editor-only chrome: hide code-server's own shell parts that duplicate the
    // app's (tabs / activity / status / terminal-panel toggle / menus).
    settings['workbench.activityBar.location'] = 'hidden';
    settings['workbench.statusBar.visible'] = false;
    settings['workbench.editor.showTabs'] = 'none';
    settings['window.menuBarVisibility'] = 'hidden';
    settings['window.commandCenter'] = false;
    settings['workbench.layoutControl.enabled'] = false;
    settings['workbench.startupEditor'] = 'none';
    settings['workbench.tips.enabled'] = false;
    settings['workbench.editor.editorActionsLocation'] = 'hidden';
    settings['workbench.editor.emptyWindowText'] = 'none';
    settings['breadcrumbs.enabled'] = false;
    settings['explorer.autoReveal'] = false;
    settings['explorer.openEditors.visible'] = 0;
    settings['chat.showHomeChatButton'] = false;
    settings['chat.editing.alwaysShowCopilotBanner'] = false;
    // Chat toolbar: recent VS Code renders a standalone Copilot/Chat control in
    // the title bar that survives `window.commandCenter: false`. Disable it so
    // no chat toolbar appears in the embedded editor's chrome.
    settings['chat.commandCenter.enabled'] = false;
    // A new workspace opens the secondary side bar (chat) by default. Keep it
    // closed from the first paint instead of waiting for the bridge to close
    // it after the extension host activates.
    settings['workbench.secondarySideBar.defaultVisibility'] = 'hidden';

    // The app shell owns tabs: one editor window serves every app tab of the
    // worktree, and the bridge switches its file as tabs switch. Force
    // permanent (non-preview) opens so a go-to-definition / quick-open adds an
    // editor rather than REPLACING the one another app tab still shows.
    settings['workbench.editor.enablePreview'] = false;
    settings['workbench.editor.enablePreviewFromQuickOpen'] = false;

    // Silence IDE notifications the embedded editor can't sensibly act on:
    // extension-install recommendations ("do you want to install …"),
    // update/experiment prompts and telemetry. Anything actionable is surfaced
    // by the app shell, not code-server.
    settings['extensions.ignoreRecommendations'] = true;
    settings['extensions.autoCheckUpdates'] = false;
    settings['extensions.autoUpdate'] = false;
    settings['workbench.enableExperiments'] = false;
    settings['telemetry.telemetryLevel'] = 'off';
    settings['update.mode'] = 'none';
    settings['workbench.welcomePage.walkthroughs.openOnInstall'] = false;

    // Save behaviour: honour the client's auto-save preference (pushed on every
    // open). `hotExit: off` makes the app's Save / Don't-save tab-close dialog
    // authoritative — a "don't save" that disposes the editor window genuinely
    // drops the buffer instead of code-server silently restoring it on reopen.
    settings['files.autoSave'] = CodeServerService._sanitizeAutoSave(autoSave);
    settings['files.autoSaveDelay'] = 1000;
    settings['files.hotExit'] = 'off';

    // Gutter diff stays on. The bridge extension supplies the original
    // resource (git's own provider never matches this window's editor URIs).
    settings['scm.diffDecorations'] = 'all';
    settings['scm.diffDecorationsGutterVisibility'] = 'always';

    // Use the app's code font (Fira Code, with ligatures) so the embedded editor
    // matches the rest of the app; fall back to platform monospaces if the user
    // doesn't have Fira Code installed for the webview to pick up.
    const codeFont =
        "'Fira Code', 'Fira Code VF', 'FiraCode Nerd Font', ui-monospace, "
        'SFMono-Regular, Menlo, Consolas, monospace';
    settings['editor.fontFamily'] = codeFont;
    settings['editor.fontLigatures'] = true;
    settings['terminal.integrated.fontFamily'] = codeFont;
    settings['chat.editor.fontFamily'] = codeFont;

    // Follow the OS/app appearance (light ↔ dark) instead of a fixed theme and
    // tint both base themes with Control Center's palette: warm near-white /
    // ink-black surfaces, warm borders and the single orange accent
    // (brand500 #FB6224). autoDetectColorScheme picks light/dark from the
    // webview's `prefers-color-scheme`, which tracks the OS appearance.
    settings['window.autoDetectColorScheme'] = true;
    settings['workbench.preferredLightColorTheme'] = 'Default Light Modern';
    settings['workbench.preferredDarkColorTheme'] = 'Default Dark Modern';
    const accent = '#FB6224'; // brand500
    const accentHover = '#FA500F'; // brand600
    settings['workbench.colorCustomizations'] = <String, dynamic>{
      // Accent-driven chrome (applies in both light and dark).
      'focusBorder': accent,
      'editorCursor.foreground': accent,
      'progressBar.background': accent,
      'button.background': accent,
      'button.hoverBackground': accentHover,
      'button.foreground': '#FFFFFF',
      'activityBarBadge.background': accent,
      'textLink.foreground': accentHover,
      'textLink.activeForeground': accent,
      'editorLink.activeForeground': accent,
      'selection.background': '#FB622455',
      // Light: warm near-white surfaces (gray25/50/100), warm borders (gray200),
      // ink text (gray900), muted line numbers (gray400).
      '[Default Light Modern]': <String, dynamic>{
        'editor.background': '#FDFCFA',
        'editor.foreground': '#1F1F1F',
        'editorGutter.background': '#FDFCFA',
        'editorLineNumber.foreground': '#B8B2A4',
        'editorLineNumber.activeForeground': '#3D3D3D',
        'editor.lineHighlightBackground': '#F2F0E9',
        'editor.selectionBackground': '#FDDDD2',
        'editor.selectionHighlightBackground': '#FEEFEA',
        'editorWidget.background': '#FCFBF9',
        'editorHoverWidget.background': '#FCFBF9',
        'editorGroupHeader.tabsBackground': '#FCFBF9',
        'editorGroup.border': '#E8E5DC',
        'sideBar.background': '#FCFBF9',
        'sideBar.border': '#E8E5DC',
        'panel.background': '#FCFBF9',
        'panel.border': '#E8E5DC',
        'terminal.background': '#FDFCFA',
        'terminal.foreground': '#1F1F1F',
        'input.background': '#FFFFFF',
        'input.border': '#E8E5DC',
        'scrollbarSlider.background': '#D8D3C680',
      },
      // Dark: ink-black surfaces (gray950/900/800), warm-neutral borders,
      // near-white text (gray100).
      '[Default Dark Modern]': <String, dynamic>{
        'editor.background': '#171614',
        'editor.foreground': '#F2F0E9',
        'editorGutter.background': '#171614',
        'editorLineNumber.foreground': '#3D3D3D',
        'editorLineNumber.activeForeground': '#B8B2A4',
        'editor.lineHighlightBackground': '#1F1F1F',
        'editor.selectionBackground': '#7A280966',
        'editor.selectionHighlightBackground': '#7A280940',
        'editorWidget.background': '#1F1F1F',
        'editorHoverWidget.background': '#1F1F1F',
        'editorGroupHeader.tabsBackground': '#1F1F1F',
        'editorGroup.border': '#2C2C2A',
        'sideBar.background': '#1F1F1F',
        'sideBar.border': '#2C2C2A',
        'panel.background': '#1F1F1F',
        'panel.border': '#2C2C2A',
        'terminal.background': '#171614',
        'terminal.foreground': '#F2F0E9',
        'input.background': '#262522',
        'input.border': '#2C2C2A',
        'scrollbarSlider.background': '#3D3D3D80',
      },
    };

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(settings),
    );
  }
}
