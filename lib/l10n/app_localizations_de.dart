// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get succeeded => 'Erfolgreich';

  @override
  String agentRunRetryLabel(int number, String time) {
    return 'Wiederholung #$number · $time';
  }

  @override
  String agentRunStarting(String time) {
    return 'Wird gestartet · $time';
  }

  @override
  String get agentActivityFollowingLive => 'Live-Aktivität wird verfolgt';

  @override
  String get agentActivityJumpToLatest => 'Zum Neuesten springen';

  @override
  String get agentActivityLoadFailed =>
      'Aktivität dieses Laufs konnte nicht geladen werden';

  @override
  String get agentActivityNotRecorded =>
      'Für diesen Lauf wurde keine Aktivität aufgezeichnet';

  @override
  String get agentActivityNotRecordedHint =>
      'Läufe, die vor Aktivierung der Aktivitätsaufzeichnung endeten, haben keine Chronologie.';

  @override
  String get agentActivityRunUnavailable =>
      'Dieser Lauf ist nicht mehr verfügbar';

  @override
  String agentActivitySubagentOf(String agent) {
    return 'Subagent von $agent';
  }

  @override
  String get agentActivityUnsupported =>
      'Aktivitätsaufzeichnung ist auf dem verbundenen Server nicht verfügbar';

  @override
  String get agentActivityUnsupportedHint =>
      'Starte die App neu, damit sie den neuesten Server-Build verwendet.';

  @override
  String get agentActivityWaiting => 'Warten auf Aktivität…';

  @override
  String get created => 'Erstellt';

  @override
  String get dictationStart => 'Diktat starten';

  @override
  String get dictationListening => 'Höre zu…';

  @override
  String get dictationUnavailable =>
      'Für das Diktat wird ein Sprachmodell auf dem Server-Host benötigt. Richte eines in den Spracheinstellungen ein.';

  @override
  String get dictationFailedToStart => 'Diktat konnte nicht gestartet werden';

  @override
  String get dictationHoldToTalkTitle => 'Zum Sprechen halten';

  @override
  String get dictationHoldToTalkDescription =>
      'Halte die Mikrofontaste oder das Tastenkürzel gedrückt, um zu diktieren, und lass los, um zu stoppen. Wenn deaktiviert, einmal drücken zum Starten und erneut zum Stoppen.';

  @override
  String get focusConversation => 'Zur Unterhaltung';

  @override
  String get ideAgentActivity => 'Agent-Aktivität';

  @override
  String get keybindingPushToTalk => 'Zum Sprechen drücken';

  @override
  String get keybindingPushToTalkDescription =>
      'Sprachdiktat im Nachrichteneditor halten oder umschalten';

  @override
  String get agentPermissions => 'Agent-Berechtigungen';

  @override
  String get agentPermissionsSettingsDescription =>
      'Legen Sie fest, was Agenten selbst tun dürfen, vorher erfragen müssen oder nie dürfen — pro Arbeitsbereich, Agent oder Bereich.';

  @override
  String get agentPermissionsMatrixDescription =>
      'Legen Sie für jede Art von Effekt eine Entscheidung fest. Regeln überlagern sich: Bereich übersteuert Agent übersteuert Arbeitsbereich.';

  @override
  String get guardrailLoading => 'Regeln werden geladen…';

  @override
  String get guardrailRulesLoadFailed =>
      'Berechtigungsregeln konnten nicht geladen werden.';

  @override
  String get guardrailScopeWorkspace => 'Arbeitsbereich';

  @override
  String get guardrailScopeAgent => 'Agent';

  @override
  String get guardrailScopeSpace => 'Bereich';

  @override
  String get guardrailSelectAgent => 'Agent auswählen';

  @override
  String get guardrailSelectSpace => 'Bereich auswählen';

  @override
  String get guardrailNoAgents =>
      'Noch keine Agenten in diesem Arbeitsbereich.';

  @override
  String get guardrailNoSpaces =>
      'Noch keine Bereiche in diesem Arbeitsbereich.';

  @override
  String get guardrailClassFileDelete => 'Eine Datei löschen';

  @override
  String get guardrailClassFileWriteOutsideWorktree =>
      'Außerhalb des Arbeitsbaums schreiben';

  @override
  String get guardrailClassGitCommit => 'Einen Commit erstellen';

  @override
  String get guardrailClassGitPush => 'Zu einem Remote pushen';

  @override
  String get guardrailClassPrCreate => 'Einen Pull Request öffnen';

  @override
  String get guardrailClassPrPublish =>
      'Eine Review veröffentlichen oder mergen';

  @override
  String get guardrailClassVendorSyncWrite =>
      'In einen externen Tracker schreiben';

  @override
  String get guardrailClassNetworkEgress => 'Auf das Netzwerk zugreifen';

  @override
  String get guardrailClassSecretAccess => 'Ein Geheimnis lesen';

  @override
  String get guardrailClassPackageInstall => 'Ein Paket installieren';

  @override
  String get guardrailClassProcessSpawn => 'Einen Prozess ausführen';

  @override
  String get guardrailClassWorkspaceMutation =>
      'Arbeitsbereichsstruktur ändern';

  @override
  String get guardrailClassEnclosureControl => 'Eine Kapsel (Rig) steuern';

  @override
  String get navRigs => 'Rigs';

  @override
  String get rigsUnsupportedServer =>
      'Dieser Server kann keine gekapselten VMs betreiben. Rigs brauchen einen Hypervisor auf der Maschine, die cc_server ausführt.';

  @override
  String get rigSurfaceComputer => 'Computer';

  @override
  String get rigSurfaceBrowser => 'Browser';

  @override
  String get rigSurfaceMobile => 'Mobil';

  @override
  String rigSurfaceBrowserEngine(String engine) {
    return '$engine';
  }

  @override
  String rigBrowserEngineHint(String engine) {
    return 'Ein Wegwerf-$engine, isoliert von deinem Rechner. Öffne eine andere Engine, um dieselbe Seite nebeneinander zu vergleichen.';
  }

  @override
  String get rigPhaseReady => 'Bereit';

  @override
  String get rigPhaseStarting => 'Startet';

  @override
  String get rigPhaseParked => 'Pausiert';

  @override
  String get rigPhaseClosing => 'Wird geschlossen';

  @override
  String get rigPhaseClosed => 'Geschlossen';

  @override
  String get rigPhaseFailed => 'Fehlgeschlagen';

  @override
  String get rigPhaseUnknown => 'Unbekannt';

  @override
  String get rigNotAccelerated => 'Emuliert';

  @override
  String get rigAudioListen => 'Maschine anhören';

  @override
  String get rigAudioMute => 'Maschine stummschalten';

  @override
  String get rigYouHaveControl => 'Du hast die Steuerung';

  @override
  String get rigBackendAvailable => 'Verfügbar';

  @override
  String get rigBackendUnavailable => 'Nicht verfügbar';

  @override
  String get rigEgressNotEnforced =>
      'Das Netzwerk ist bei diesem Backend nicht gekapselt — es verwaltet seine eigene Konnektivität.';

  @override
  String get rigStartMachine => 'Maschine starten';

  @override
  String get rigStartHint =>
      'Startet eine Wegwerf-VM, die du dir mit deinen Agenten für diese Unterhaltung teilst. Sie wird beim Schließen zerstört, und nichts darin berührt deinen Rechner.';

  @override
  String get rigStopMachine => 'Maschine stoppen';

  @override
  String get rigSurfaceUnavailable =>
      'Dieser Server kann diese Art von Maschine nicht betreiben.';

  @override
  String get rigTabNeedsConversation =>
      'Öffne zuerst eine Unterhaltung — eine Maschine gehört zu genau einer, damit du und deine Agenten denselben Bildschirm seht.';

  @override
  String get ideMenuSectionTools => 'Werkzeuge';

  @override
  String get ideMenuSectionVirtualMachine => 'Virtuelle Maschine';

  @override
  String get ideMenuSectionReopen => 'Erneut öffnen';

  @override
  String get ideMenuSearchHint => 'Suchen';

  @override
  String get ideMenuNoMatches => 'Keine Treffer';

  @override
  String get rigMenuComputer => 'Computer';

  @override
  String get rigMenuBrowser => 'Browser';

  @override
  String get rigMenuMobile => 'Telefon';

  @override
  String rigLabelNumbered(String label, String suffix) {
    return '$label $suffix';
  }

  @override
  String ideCloseKeepTitle(String name) {
    return '$name schließen?';
  }

  @override
  String get ideCloseKeepBodyMachine =>
      'Die Maschine läuft im Hintergrund weiter — du kannst sie jederzeit über die Seitenleiste wieder öffnen. Fahre sie herunter, um ihren Speicher jetzt freizugeben.';

  @override
  String get ideCloseKeepBodyShell =>
      'Der Befehl läuft im Hintergrund weiter — du kannst die Shell jederzeit über die Seitenleiste wieder öffnen. Beende sie, um zu stoppen, was sie gerade tut.';

  @override
  String get ideCloseKeepBodyAgent =>
      'Der Agent arbeitet im Hintergrund weiter — du kannst die Unterhaltung jederzeit über die Seitenleiste wieder öffnen. Stoppe ihn, um den Lauf jetzt zu beenden.';

  @override
  String get ideCloseKeepRunning => 'Weiterlaufen lassen';

  @override
  String get ideCloseShutDownMachine => 'Herunterfahren';

  @override
  String get ideCloseEndShell => 'Shell beenden';

  @override
  String get ideCloseStopAgent => 'Agent stoppen';

  @override
  String get rigsSettingsSubtitle =>
      'Was dieser Server starten kann, welche Basis-Images er braucht und welche Maschinen gerade laufen';

  @override
  String get rigsCapabilitiesTitle => 'Dieser Server';

  @override
  String get rigsImagesTitle => 'Basis-Images';

  @override
  String get rigsImagesHint =>
      'Jedes Rig startet von einem dieser schreibgeschützten Images. Jede Sitzung schreibt in eine Wegwerf-Schicht, sodass ein Rig nie ändern kann, womit das nächste startet.';

  @override
  String get rigsRunningTitle => 'Läuft gerade';

  @override
  String get rigsNoneRunning => 'Es laufen keine Maschinen.';

  @override
  String get rigsCustomImagesTitle => 'Eigene Images (dieser Arbeitsbereich)';

  @override
  String get rigsCustomImagesHint =>
      'Richte das Terminal (VM) oder den Browser (VM) auf ein eigenes Image — erweitere die Standards um die Werkzeuge deines Projekts oder nutze ein kompatibles aus einer Registry. Neue Maschinen verwenden es; laufende behalten ihres. Was ein Image bereitstellen muss, steht im Rigs-Leitfaden.';

  @override
  String get rigsCustomTerminalImageLabel => 'Terminal-(VM)-Image';

  @override
  String get rigsCustomBrowserImageLabel => 'Browser-(VM)-Image';

  @override
  String get rigsCustomImagePlaceholder =>
      'z. B. ghcr.io/acme/dev-shell:1.2 — leer für den Standard';

  @override
  String get rigsCustomImageInvalid =>
      'Gib eine Registry-Referenz wie repo/name:tag ein. Lokale Pfade und Archive sind nicht erlaubt.';

  @override
  String get rigsCustomImageSaved =>
      'Gespeichert. Neue Maschinen booten dieses Image; laufende behalten ihres.';

  @override
  String get rigsEgressTitle => 'Browser-Ausgang (dieser Workspace)';

  @override
  String get rigsEgressHint =>
      'Zusätzliche Hosts, die der eingeschlossene Browser erreichen darf — einer pro Zeile: ein exakter Host (api.example.com) oder ein Platzhalter für dessen Subdomains (*.example.com). Die Produktseite bleibt in jedem Fall erlaubt. Neue Maschinen übernehmen die Liste; laufende behalten ihre bisherige.';

  @override
  String rigsEgressInvalid(String host) {
    return '„$host“ ist kein gültiger Host-Eintrag.';
  }

  @override
  String get rigsEgressSaved =>
      'Gespeichert. Neue Browser-Maschinen erlauben diese Hosts; laufende behalten ihre.';

  @override
  String get rigImageInstalled => 'Installiert';

  @override
  String get rigImageNotDownloaded => 'Nicht heruntergeladen';

  @override
  String get rigImageNotPublished => 'Nicht veröffentlicht';

  @override
  String get rigImageNotPublishedHint =>
      'Für dieses Ziel wurde noch kein Image veröffentlicht, es gibt also nichts herunterzuladen. Importiere ein kompatibles Datenträger-Image, um es zu aktivieren.';

  @override
  String get rigImageDownload => 'Herunterladen';

  @override
  String get rigImageDownloading => 'Wird heruntergeladen…';

  @override
  String get rigImageImport => 'Importieren';

  @override
  String get rigImageImportMessage =>
      'Pfad zu einem qcow2-Disk-Image im Dateisystem des Servers. Es wird in den Image-Speicher kopiert, die Datei kann danach also verschoben werden.';

  @override
  String get rigConnectingStream => 'Verbindung zum Rig';

  @override
  String get rigStreamNotAllowed => 'Du hast keinen Zugriff auf dieses Rig.';

  @override
  String get rigStreamNotRunning => 'Dieses Rig läuft nicht mehr.';

  @override
  String get rigStreamNeedsFfmpeg =>
      'Die Live-Ansicht benötigt ffmpeg auf diesem Host. Installiere ffmpeg und öffne den Tab erneut.';

  @override
  String get rigStreamEnded => 'Die Live-Ansicht wurde beendet.';

  @override
  String get rigStreamFailed =>
      'Die Live-Ansicht konnte nicht geöffnet werden.';

  @override
  String get rigStreamDisconnected => 'Nicht mit einem Server verbunden.';

  @override
  String rigDropSendingOne(String name) {
    return '„$name“ wird in die Maschine kopiert…';
  }

  @override
  String rigDropSendingMany(int count) {
    return '$count Dateien werden in die Maschine kopiert…';
  }

  @override
  String get rigTerminalDropSending => 'Wird in die Maschine kopiert…';

  @override
  String get rigTerminalPasteImage =>
      'Eingefügtes Bild in der Maschine gespeichert';

  @override
  String get rigPortsTitle => 'Weitergeleitete Ports';

  @override
  String get rigPortsTooltip => 'In dieser Maschine offene Ports';

  @override
  String get rigPortsEmpty =>
      'Es lauscht noch nichts. Starte einen Server im Terminal — ein Dev-Server auf Port 3000 erscheint hier.';

  @override
  String get rigPortsAdd => 'Port hinzufügen';

  @override
  String get rigPortsAddHint => 'Weiterzuleitender Gast-Port (z. B. 3000)';

  @override
  String get rigPortsAutoForward => 'Ports automatisch weiterleiten';

  @override
  String get rigPortsCopyUrl => 'Lokale URL kopieren';

  @override
  String rigPortsCopiedUrl(String url) {
    return '$url kopiert';
  }

  @override
  String get rigPortsStopForward => 'Weiterleitung stoppen';

  @override
  String get rigPortsExposeLan => 'Im lokalen Netzwerk teilen';

  @override
  String get rigPortsLanPrivate => 'Nur lokal';

  @override
  String get rigPortsLanShared => 'Im Netzwerk';

  @override
  String get rigPortsSetDomain => 'Browser-Domain festlegen (.test)';

  @override
  String get rigPortsDomainHint =>
      'Domain für den Browser (VM), z. B. myapp.test — dort erreichbar, nicht auf dem Host';

  @override
  String get rigPortsProcessUnknown => 'unbekannter Prozess';

  @override
  String get rigPortsInactive => 'lauscht nicht';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Basis-Images fehlen noch',
      one: '1 Basis-Image fehlt noch',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => 'Zulassen';

  @override
  String get guardrailDecisionPrompt => 'Zuerst fragen';

  @override
  String get guardrailDecisionDeny => 'Verweigern';

  @override
  String get guardrailSourceThisScope => 'Dieser Bereich';

  @override
  String get guardrailSourceDefault => 'Standardwert';

  @override
  String get guardrailSourcePreset => 'Modus-Voreinstellung';

  @override
  String get guardrailSourceInherited => 'Geerbt';

  @override
  String get guardrailClearToInherited => 'Auf geerbten Wert zurücksetzen';

  @override
  String get guardrailWhatIf => 'Was wäre wenn?';

  @override
  String get guardrailWhatIfDescription =>
      'Sehen Sie, wie die aktuellen Regeln eine Aktion entscheiden würden – mit derselben Logik, die für die Agenten gilt.';

  @override
  String get guardrailProbeActionLabel => 'Aktion';

  @override
  String get guardrailProbeCommandLabel => 'Befehl (optional)';

  @override
  String get guardrailProbeCommandHint => 'z. B. git push origin main';

  @override
  String get guardrailProbeAgentLabel => 'Agent (optional)';

  @override
  String get guardrailProbeSpaceLabel => 'Bereich (optional)';

  @override
  String get guardrailProbeNone => 'Keiner';

  @override
  String get guardrailProbeModeLabel => 'Modus';

  @override
  String get guardrailProbeResult => 'Ergebnis';

  @override
  String get guardrailProbeSource => 'Quelle:';

  @override
  String get guardrailAdapterMatrix => 'Wo Regeln durchgesetzt werden';

  @override
  String get guardrailAdapterMatrixDescription =>
      'Ehrliche Referenz: wo jeder Effekt tatsächlich abgefangen wird, je nach Agent-Runner. Dies beschreibt die Realität, keine Garantie – Effekte, die ein Runner außerhalb ausführt, können nicht abgefangen werden.';

  @override
  String get guardrailEffectColumn => 'Effekt';

  @override
  String get guardrailAdapterHarness => 'Integriertes Harness';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => 'Sandbox-Basis';

  @override
  String get guardrailEnforcementPolicyGate => 'Richtlinienkontrolle';

  @override
  String get guardrailEnforcementSandbox => 'Nur Sandbox';

  @override
  String get guardrailEnforcementNone => 'Nicht durchsetzbar';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      'Die Berechtigungsentscheidung wird vor der Ausführung des Effekts geprüft und kann ihn blockieren.';

  @override
  String get guardrailEnforcementSandboxHelp =>
      'Nur die Sandbox schränkt es ein; die Berechtigungsregel wird nicht herangezogen.';

  @override
  String get guardrailEnforcementNoneHelp =>
      'Die Entscheidung ist nur beratend – sie kann hier nicht abgefangen werden.';

  @override
  String get obsStatCost => 'Kosten';

  @override
  String obsStatDelegatedCost(String amount) {
    return '+$amount delegiert';
  }

  @override
  String get obsStatDuration => 'Dauer';

  @override
  String get obsStatTokens => 'Tokens';

  @override
  String get obsStatTools => 'Tools';

  @override
  String get openAgentActivity => 'Aktivität öffnen';

  @override
  String get orgChart => 'Organigramm';

  @override
  String get orgChartEmpty => 'Noch keine Agenten';

  @override
  String get navCalendar => 'Kalender';

  @override
  String get serverConnection => 'Serververbindung';

  @override
  String get serverModeLocal => 'In dieser App ausführen';

  @override
  String get serverModeLocalDescription =>
      'Control Center führt einen eigenen Server auf diesem Gerät aus und speichert deine Daten lokal.';

  @override
  String get serverModeRemote => 'Mit einer entfernten Instanz verbinden';

  @override
  String get serverModeRemoteDescription =>
      'Verbinde dich mit einem Control Center-Server, der woanders läuft. Deine Daten liegen auf diesem Server.';

  @override
  String get serverRemoteUrl => 'Server-URL';

  @override
  String get serverRemoteDeviceId => 'Geräte-ID';

  @override
  String get serverRemotePairingKey => 'Kopplungsschlüssel';

  @override
  String get serverRemotePairingKeyHint =>
      'Füge den Kopplungsschlüssel des entfernten Servers ein';

  @override
  String get serverSetupInviteCode => 'Einladungscode';

  @override
  String get serverSetupInviteCodeHint =>
      'Einmaligen Einladungscode einfügen (leer lassen, um einen Kopplungsschlüssel zu verwenden)';

  @override
  String get serverDiscoveryTooltip => 'Server in deinem Netzwerk finden';

  @override
  String get serverDiscoveryTitle => 'Server in deinem Netzwerk';

  @override
  String get serverDiscoverySearching => 'Suche nach Servern…';

  @override
  String get serverDiscoveryEmpty =>
      'Keine Server gefunden. Prüfe, ob der Server läuft und dieses Gerät ihn erreichen kann, und suche dann erneut.';

  @override
  String get serverDiscoveryRefresh => 'Erneut suchen';

  @override
  String get serverListActive => 'Aktiv';

  @override
  String get serverListSwitch => 'Wechseln';

  @override
  String get serverListAddTitle => 'Server hinzufügen';

  @override
  String get serverListRemoveActiveHint =>
      'Wechseln Sie zu einem anderen Server, bevor Sie diesen entfernen.';

  @override
  String get serverSwitchFailedTitle => 'Serverwechsel fehlgeschlagen';

  @override
  String get serverListInsecureBadge => 'Unsicher';

  @override
  String get connectionPathLocal => 'Lokal';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => 'Wird heruntergefahren';

  @override
  String get shutdownSubtitle => 'Der lokale Server wird geschlossen';

  @override
  String get shutdownServiceApprovals => 'Genehmigungen';

  @override
  String get shutdownServiceBackgroundJobs => 'Hintergrundaufgaben';

  @override
  String get shutdownServiceScheduler => 'Aufgabenplaner';

  @override
  String get shutdownServiceCalendar => 'Kalendersynchronisierung';

  @override
  String get shutdownServiceWeather => 'Wetter';

  @override
  String get shutdownServiceSoundscape => 'Klanglandschaft';

  @override
  String get shutdownServiceMeetings => 'Meetings';

  @override
  String get shutdownServiceVoiceModels => 'Sprachmodelle';

  @override
  String get shutdownServiceNetworking => 'Netzwerk';

  @override
  String get shutdownServicePresence => 'Anwesenheit';

  @override
  String get shutdownServiceDataSync => 'Datensynchronisierung';

  @override
  String get shutdownServiceDeviceRelay => 'Geräte-Relay';

  @override
  String get shutdownServiceMcpConnections => 'MCP-Verbindungen';

  @override
  String get shutdownServiceCodeEditors => 'Code-Editoren';

  @override
  String get serverSharingTitle => 'Diesen Server teilen';

  @override
  String get serverSharingDescription =>
      'Mache diesen Server von deinen anderen Geräten aus erreichbar. Nichts wird öffentlich zugänglich, solange du unten keinen Tunnel aktivierst. Kopplungseinladungen enthalten automatisch die aktuellen Adressen des Servers – erstelle sie in den Workspace-Einstellungen.';

  @override
  String get serverSharingUnavailable =>
      'Freigabeeinstellungen sind auf diesem Server nicht verfügbar.';

  @override
  String get serverSharingMdnsLabel => 'LAN-Erkennung';

  @override
  String get serverSharingMdnsOn =>
      'Dieser Server wird in deinem lokalen Netzwerk angekündigt (mDNS)';

  @override
  String get serverSharingMdnsOff =>
      'Dieser Server wird nicht in deinem lokalen Netzwerk angekündigt (mDNS)';

  @override
  String get serverSharingTunnelLabel => 'Tunnel';

  @override
  String get serverSharingTunnelHelper =>
      'Ein aktivierter Tunnel macht diesen Server aus dem Internet erreichbar. Die öffentliche Freigabe ist optional und standardmäßig deaktiviert.';

  @override
  String get serverSharingProviderOff => 'Aus';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => 'Öffentliche URL';

  @override
  String get serverSharingTunnelStarting => 'Tunnel wird gestartet…';

  @override
  String serverSharingTunnelError(String error) {
    return 'Tunnelfehler: $error';
  }

  @override
  String get serverSharingTunnelUpNoUrl =>
      'Der Tunnel ist aktiv. Erreiche ihn über deinen konfigurierten DNS-Hostnamen.';

  @override
  String get serverSharingRelayLabel => 'Relay';

  @override
  String serverSharingRelayUsage(String amount) {
    return 'Diesen Monat weitergeleitet: $amount';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return 'Aktive Relay-Sitzungen: $count';
  }

  @override
  String get serverSharingUpdateFailedTitle =>
      'Freigabe konnte nicht aktualisiert werden';

  @override
  String get pairNewClient => 'Neuen Client koppeln';

  @override
  String get pairClientNameHint =>
      'Diesen Client benennen (z. B. Arbeitslaptop)';

  @override
  String get pairClientTypeWeb => 'Webbrowser';

  @override
  String get pairClientTypeDesktop => 'Desktop-App';

  @override
  String get pairClientTypePhone => 'Telefon';

  @override
  String get pairAction => 'Koppeln';

  @override
  String get revoke => 'Widerrufen';

  @override
  String get pairCredentialsIntro =>
      'Verbinde den neuen Client mit diesen Daten oder öffne den Link darauf.';

  @override
  String get pairLinkLabel => 'Link';

  @override
  String get pairScanQr =>
      'Scanne diesen QR-Code mit der Kamera deines Telefons, um es zu koppeln.';

  @override
  String get pairServerUnreachableTitle => 'Nicht erreichbar';

  @override
  String get pairServerUnreachable =>
      'Andere Geräte können diesen Server nicht direkt erreichen, daher kann sich ein neuer Client nicht verbinden. Lege die öffentliche URL des Servers fest, um weitere Clients zu koppeln.';

  @override
  String get serverSetupTitle => 'Wie soll Control Center laufen?';

  @override
  String get serverSetupSubtitle =>
      'Control Center benötigt einen Server, der deine Daten besitzt. Führe einen in dieser App aus oder verbinde dich mit einer Instanz, die woanders läuft.';

  @override
  String get serverSetupRunLocal => 'In dieser App ausführen';

  @override
  String get serverSetupConnect => 'Verbinden';

  @override
  String get serverSetupInvalidUrl =>
      'Gib eine gültige ws://- oder wss://-Server-URL ein.';

  @override
  String get serverSetupCouldNotConnect => 'Verbindung fehlgeschlagen';

  @override
  String get serverSetupErrorUnreachable =>
      'Der Server ist nicht erreichbar. Prüfe, ob er läuft und ob dieses Gerät ihn erreichen kann (gleiches Netzwerk oder Relay).';

  @override
  String get serverSetupErrorIdentityMismatch =>
      'Die Identität des Servers stimmt nicht mit der auf diesem Gerät gespeicherten überein. Wenn der Server neu installiert oder zurückgesetzt wurde, entferne den gespeicherten Server und kopple erneut.';

  @override
  String get serverSetupErrorAuthRejected =>
      'Der Server hat dieses Gerät abgelehnt. Prüfe, ob Kopplungsschlüssel und Geräte-ID mit den vom Server ausgegebenen übereinstimmen.';

  @override
  String get serverSetupErrorInviteRejected =>
      'Dieser Einladungscode ist ungültig oder abgelaufen. Bitte um einen neuen.';

  @override
  String get serverSetupErrorGeneric =>
      'Beim Verbinden ist ein Fehler aufgetreten. Klappe die technischen Details unten auf, um mehr zu erfahren.';

  @override
  String get serverSetupErrorDetails => 'Technische Details';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weitere',
      one: '1 weiterer',
    );
    return '$_temp0';
  }

  @override
  String get calendarAllDayGutter => 'Ganztägig';

  @override
  String calendarAllDayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Termine',
      one: '1 Termin',
    );
    return '$_temp0';
  }

  @override
  String get calendarCollapseAllDay => 'Ganztägige Termine einklappen';

  @override
  String get calendarExpandAllDay => 'Ganztägige Termine ausklappen';

  @override
  String get calendarViewMonth => 'Monat';

  @override
  String get calendarViewWeek => 'Woche';

  @override
  String get calendarViewAgenda => 'Agenda';

  @override
  String get calendarConnectGoogle => 'Google Calendar verbinden';

  @override
  String get calendarConnectDescription =>
      'Synchronisiere deinen Google Calendar, um Termine hier zu sehen und vor Beginn von Meetings benachrichtigt zu werden.';

  @override
  String get calendarDisconnect => 'Trennen';

  @override
  String get calendarReconnect => 'Erneut verbinden';

  @override
  String get calendarEmptyNoEvents => 'Keine Termine in diesem Zeitraum';

  @override
  String get calendarStartRecording => 'Aufnahme starten';

  @override
  String get calendarStartRecordingAndLink => 'Aufnehmen und verknüpfen';

  @override
  String get calendarJoinMeet => 'Meeting beitreten';

  @override
  String get calendarFromCalendar => 'Aus dem Kalender';

  @override
  String get calendarLinkedMeeting => 'Verknüpftes Meeting';

  @override
  String get calendarToday => 'Heute';

  @override
  String get calendarAllDay => 'Ganztägig';

  @override
  String calendarWeekNumber(int number) {
    return 'Woche $number';
  }

  @override
  String get calendarPreviousPeriod => 'Zurück';

  @override
  String get calendarNextPeriod => 'Weiter';

  @override
  String calendarLastSynced(String time) {
    return 'Synchronisiert $time';
  }

  @override
  String get calendarNeverSynced => 'Noch nicht synchronisiert';

  @override
  String get calendarSyncing => 'Wird synchronisiert…';

  @override
  String get calendarViewDay => 'Tag';

  @override
  String get calendarShow => 'Einblenden';

  @override
  String get calendarHide => 'Ausblenden';

  @override
  String get calendarRsvpGoing => 'Dabei?';

  @override
  String get calendarRsvpYes => 'Ja';

  @override
  String get calendarRsvpNo => 'Nein';

  @override
  String get calendarRsvpMaybe => 'Vielleicht';

  @override
  String get calendarRsvpFailed => 'Antwort konnte nicht aktualisiert werden';

  @override
  String get calendarAddAccount => 'Kalenderkonto hinzufügen';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Verbinde ein Google-Konto, um Termine in diesen Workspace zu synchronisieren.';

  @override
  String get calendarConnecting => 'Verbinden…';

  @override
  String get calendarSyncNow => 'Jetzt synchronisieren';

  @override
  String get calendarNoWorkspace =>
      'Wähle einen Workspace, um seinen Kalender zu sehen';

  @override
  String get calendarConnectError =>
      'Google Calendar konnte nicht verbunden werden';

  @override
  String get calendarClientIdLabel => 'Client-ID';

  @override
  String get calendarClientSecretLabel => 'Client-Secret';

  @override
  String get calendarConnectCredsHint =>
      'Gib die OAuth-Client-ID und das Secret (Device-Code) deines Google-Projekts ein. Der Server übernimmt Verbindung und Synchronisierung — dein Browser hält die Tokens nie.';

  @override
  String get calendarConnectApproveInstruction =>
      'Öffne die Bestätigungsseite auf einem beliebigen Gerät, melde dich an und gib diesen Code ein:';

  @override
  String get calendarConnectOpenPage => 'Bestätigungsseite öffnen';

  @override
  String get calendarConnectWaiting => 'Warten auf Bestätigung…';

  @override
  String get calendarConnectDenied =>
      'Die Autorisierung wurde abgelehnt. Bitte versuche es erneut.';

  @override
  String get calendarConnectExpired =>
      'Der Code ist abgelaufen. Bitte versuche es erneut.';

  @override
  String get notificationMeetingStartsSoon => 'Meeting beginnt bald';

  @override
  String get notifyMeetingStartsSoon =>
      'Wenn ein Termin im Kalender gleich beginnt';

  @override
  String get notificationCalendarAuthExpiredTitle => 'Kalender getrennt';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'Verbinde $email erneut, um die Synchronisierung fortzusetzen';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'Verbinde deinen Kalender erneut, um die Synchronisierung fortzusetzen';

  @override
  String get notifyCalendarAuthExpired =>
      'Wenn ein Kalenderkonto erneut verbunden werden muss';

  @override
  String get notificationRigStatusChanged => 'Gehege-Updates';

  @override
  String get notifyRigStatusChanged =>
      'Wenn ein Gehege übernommen, zurückgeholt wird oder ausfällt';

  @override
  String get notificationRigTakenOver => 'Gehege übernommen';

  @override
  String get notificationRigTakenOverBody =>
      'Eine Person steuert die Maschine; der Agent kann zusehen, aber nicht handeln.';

  @override
  String get notificationRigReleased => 'Gehege-Steuerung freigegeben';

  @override
  String get notificationRigReleasedBody =>
      'Der Agent hat die Maschine wieder.';

  @override
  String get notificationRigReclaimed => 'Gehege zurückgeholt';

  @override
  String get notificationRigReclaimedBodyIdle =>
      'Sie war untätig, daher wurde die Maschine geschlossen, um Speicher freizugeben.';

  @override
  String get notificationRigReclaimedBodyTtl =>
      'Sie hat ihr Zeitlimit erreicht und wurde geschlossen.';

  @override
  String get notificationRigFailed => 'Gehege fehlgeschlagen';

  @override
  String get notificationRigFailedBody =>
      'Der Hypervisor ist darunter gestorben. Öffne die Maschine erneut, um fortzufahren.';

  @override
  String get calendarAlertLeadTime => 'Vorlaufzeit der Erinnerung';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'Wie lange vor einem Meeting du benachrichtigt wirst';

  @override
  String calendarConnectedAs(String email) {
    return 'Verbunden als $email';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count Teilnehmer';
  }

  @override
  String get calendarEventLabel => 'Termin';

  @override
  String get calendarRecurring => 'Wiederkehrender Termin';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'Organisator';

  @override
  String get calendarYou => 'Du';

  @override
  String get calendarShowFewer => 'Weniger anzeigen';

  @override
  String get calendarRsvpAwaiting => 'Ausstehend';

  @override
  String calendarParticipantsCount(int count) {
    return '$count Teilnehmer';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'Alle $count Teilnehmer anzeigen';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count zugesagt';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count abgesagt';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count vielleicht';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count ausstehend';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count Minuten';
  }

  @override
  String get openInEditorPrompt => 'In welchem Editor öffnen?';

  @override
  String get ideNotInstalled => 'Nicht installiert';

  @override
  String openInIde(String editor) {
    return 'In $editor öffnen';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return '$editor konnte nicht geöffnet werden: $error';
  }

  @override
  String get profileSearchHint => 'Pull Requests suchen…';

  @override
  String get stopAgentRun => 'Lauf stoppen';

  @override
  String get stopAgentRunConfirm =>
      'Diesen Lauf stoppen? Laufende Arbeit geht verloren.';

  @override
  String get inProgress => 'In Arbeit';

  @override
  String get drafts => 'Entwürfe';

  @override
  String get sortOldest => 'Älteste';

  @override
  String get sortLargest => 'Größte';

  @override
  String get prFilterTooltip => 'Filtern';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aktive Filter',
      one: '1 aktiver Filter',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => 'Filter hinzufügen…';

  @override
  String get prFilterFieldHint => 'Filtern…';

  @override
  String get prFilterCategoryStatus => 'Status';

  @override
  String get prFilterCategoryAuthor => 'Autor';

  @override
  String get prFilterCategoryReviewer => 'Reviewer';

  @override
  String get prFilterCategoryContent => 'Inhalt';

  @override
  String get prFilterCategoryRepoOwner => 'Repository-Eigentümer';

  @override
  String get prFilterCategoryRepoName => 'Repository-Name';

  @override
  String get prFilterCategoryOpenedDate => 'Eröffnungsdatum';

  @override
  String get prFilterCategoryUpdatedDate => 'Aktualisierungsdatum';

  @override
  String get prFilterQuickToReview => 'Schnell zu reviewen';

  @override
  String get prFilterClearAll => 'Filter löschen';

  @override
  String prFilterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pull Requests',
      one: '1 Pull Request',
    );
    return '$_temp0';
  }

  @override
  String prFilterHiddenOptions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Optionen ohne passende Pull Requests',
      one: '1 Option ohne passende Pull Requests',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => 'Titel oder Text enthält…';

  @override
  String get prFilterNoOptions => 'Keine passenden Optionen';

  @override
  String get prFilterChipIs => 'ist';

  @override
  String get prFilterChipIsAnyOf => 'ist eines von';

  @override
  String get prFilterChipContains => 'enthält';

  @override
  String get prFilterChipSince => 'seit';

  @override
  String get prFilterAddFilterButton => 'Filter hinzufügen';

  @override
  String prFilterClearCategory(String category) {
    return '$category-Filter löschen';
  }

  @override
  String get prFilterCurrentUser => 'Aktueller Benutzer';

  @override
  String get prStatusDraft => 'Entwurf';

  @override
  String get prStatusOpen => 'Offen';

  @override
  String get prStatusInReview => 'In Review';

  @override
  String get prStatusChangesRequested => 'Änderungen angefordert';

  @override
  String get prStatusApproved => 'Genehmigt';

  @override
  String get prStatusMerged => 'Zusammengeführt';

  @override
  String get prStatusClosed => 'Geschlossen';

  @override
  String get prDateWindowDay => 'vor 1 Tag';

  @override
  String get prDateWindowThreeDays => 'vor 3 Tagen';

  @override
  String get prDateWindowWeek => 'vor 1 Woche';

  @override
  String get prDateWindowMonth => 'vor 1 Monat';

  @override
  String get prDateWindowThreeMonths => 'vor 3 Monaten';

  @override
  String get prDateWindowSixMonths => 'vor 6 Monaten';

  @override
  String get prDateWindowYear => 'vor 1 Jahr';

  @override
  String get prDisplayOptions => 'Anzeigeoptionen';

  @override
  String get prDisplayGrouping => 'Gruppierung';

  @override
  String get prDisplayOrdering => 'Sortierung';

  @override
  String get prDisplayShowDrafts => 'Entwürfe anzeigen';

  @override
  String get prDisplayMergedWindow => 'Merge-Zeitfenster';

  @override
  String get prDisplayMergedWindowDay => 'Letzter Tag';

  @override
  String get prDisplayMergedWindowWeek => 'Letzte Woche';

  @override
  String get prDisplayMergedWindowMonth => 'Letzter Monat';

  @override
  String get prDisplayProperties => 'Anzeigeeigenschaften';

  @override
  String get prGroupingRepository => 'Repository';

  @override
  String get prGroupingAuthor => 'Autor';

  @override
  String get prGroupingStatus => 'Status';

  @override
  String get prGroupingNone => 'Keine Gruppierung';

  @override
  String get prPropertyRepository => 'Repository';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => 'Branch';

  @override
  String get prPropertyUpdated => 'Aktualisiert';

  @override
  String get prPropertyAuthor => 'Autor';

  @override
  String get prPropertyChecks => 'Prüfungen';

  @override
  String get prPropertyDiff => 'Diff';

  @override
  String get prPropertyComments => 'Kommentare';

  @override
  String get keybindingOpenFilterMenu => 'Filtermenü öffnen';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'Das PR-Filtermenü öffnen';

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ausgewählt',
      one: '1 ausgewählt',
    );
    return '$_temp0';
  }

  @override
  String get summary => 'Zusammenfassung';

  @override
  String get kbMove => 'bewegen';

  @override
  String get kbTabs => 'tabs';

  @override
  String get kbSearch => 'suchen';

  @override
  String get kbViewed => 'gesehen';

  @override
  String get kbCollapse => 'einklappen';

  @override
  String get appearance => 'Darstellung';

  @override
  String get appearanceSettingsDescription => 'Design, Sprache und Typografie.';

  @override
  String get notificationsSettingsDescription =>
      'Wählen Sie, welche Agenten- und Arbeitsbereichsereignisse Sie benachrichtigen.';

  @override
  String get advanced => 'Erweitert';

  @override
  String get accounts => 'Konten';

  @override
  String get mcpServers => 'MCP-Server';

  @override
  String get mcpServersSettingsDescription =>
      'Eingebauter MCP-Server und externe MCP-Server.';

  @override
  String get remoteControlAndDevices => 'Fernsteuerung & Geräte';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'Telefone koppeln und den Fernsteuerungsserver konfigurieren.';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'Die Sprach- und Diarisierungsmodelle, die dieser Server hostet.';

  @override
  String get filterSettingsHint => 'Einstellungen filtern';

  @override
  String get needsSetupLabel => 'Einrichtung erforderlich';

  @override
  String noSettingsMatch(String query) {
    return 'Keine Einstellung entspricht „$query“';
  }

  @override
  String get collapseSidebar => 'Seitenleiste einklappen';

  @override
  String get expandSidebar => 'Seitenleiste ausklappen';

  @override
  String get filterSpacesHint => 'Bereiche filtern';

  @override
  String noSpacesMatch(String query) {
    return 'Keine Bereiche entsprechen „$query“';
  }

  @override
  String get privacy => 'Datenschutz';

  @override
  String get sendDiffContentTitle => 'Diff-Inhalt an KI-Adapter senden';

  @override
  String get diffSharingOnSubtitle =>
      'Rohe Diff-Zeilen werden für eine gründlichere Prüfung in die Agenten-Prompts aufgenommen.';

  @override
  String get diffSharingOffSubtitle =>
      'Agenten verwenden nur strukturierte Metadaten (Dateipfade, Zeilennummern, PR-Beschreibung); kein Rohcode verlässt die App.';

  @override
  String get errorReportingTitle => 'Absturzberichte teilen';

  @override
  String get errorReportingOnSubtitle =>
      'Absturz-, Fehler- und Leistungsdiagnosen werden gesendet, um Fehler zu beheben (nur in Release-Builds).';

  @override
  String get errorReportingOffSubtitle =>
      'Diagnosen sind deaktiviert. Es werden keine Absturz- oder Fehlerberichte gesendet.';

  @override
  String get onboardingDiagnosticsTitle =>
      'Hilf mit, Control Center zu verbessern';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'Sende Absturz-, Fehler- und Leistungsdiagnosen, damit wir Probleme schneller beheben können (nur in Release-Builds). Du kannst dies jederzeit unter Einstellungen → Datenschutz ändern.';

  @override
  String get blocked => 'Blockiert';

  @override
  String get idle => 'Inaktiv';

  @override
  String get noRunsYet => 'Noch keine Ausführungen';

  @override
  String lastActiveAgo(String duration) {
    return 'Vor $duration aktiv';
  }

  @override
  String get copyPath => 'Pfad kopieren';

  @override
  String get copyRelativePath => 'Relativen Pfad kopieren';

  @override
  String get nameRequired => 'Name ist erforderlich';

  @override
  String get import => 'Importieren';

  @override
  String get sortByStatus => 'Status';

  @override
  String get sortByName => 'Name';

  @override
  String get noMatchingAgents => 'Keine Agenten entsprechen deinem Filter';

  @override
  String watchVideoOn(String provider) {
    return 'Video auf $provider ansehen';
  }

  @override
  String get branchTemplate => 'Vorlage für Branch-Namen';

  @override
  String get branchTemplateDescription =>
      'Muster für den Branch, der beim Start eines Tickets in einem isolierten Worktree erstellt wird.';

  @override
  String branchTemplatePreview(String example) {
    return 'Beispiel: $example';
  }

  @override
  String get deletePipelineRun => 'Pipeline-Ausführung löschen';

  @override
  String deletePipelineRunConfirm(String template) {
    return 'Diese Ausführung von „$template“ löschen? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'Fehler beim Löschen der Pipeline-Ausführung: $error';
  }

  @override
  String get deleteTicket => 'Ticket löschen';

  @override
  String deleteTicketConfirm(String title) {
    return '„$title“ löschen? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'Fehler beim Löschen des Tickets: $error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return '„$name“ löschen? Verknüpfte Repositories auf der Festplatte bleiben unberührt.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'Fehler beim Löschen des Arbeitsbereichs: $error';
  }

  @override
  String get indexCode => 'Code indizieren';

  @override
  String get indexNoGrammars => 'Code-Grammatiken nicht installiert';

  @override
  String get indexFailed => 'Indizierung fehlgeschlagen';

  @override
  String indexedSymbolsCount(int count) {
    return '$count Symbole indiziert';
  }

  @override
  String get nodeConfigAdvanced => 'Erweitert';

  @override
  String get nodeConfigReducer => 'Reduzierer';

  @override
  String get nodeConfigReducerHelp =>
      'Wie zusammengeführt wird, wenn dieser Ausgabeschlüssel bereits einen Wert hat';

  @override
  String get nodeConfigTimeoutMs => 'Zeitlimit (ms)';

  @override
  String get nodeConfigRetryAttempts => 'Wiederholungsversuche';

  @override
  String get nodeConfigContinueOnFail =>
      'Fortfahren, wenn dieser Schritt fehlschlägt';

  @override
  String get nodeConfigTeamId => 'Team-ID';

  @override
  String get nodeConfigDispatchMode => 'Verteilungsmodus';

  @override
  String get nodeConfigOutputSchema => 'Ausgabeschema (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'JSON-Schema, das die Schrittausgabe erfüllen muss';

  @override
  String get diffLineDisplay => 'Lange Zeilen in Diffs';

  @override
  String get diffLineDisplayDescription =>
      'Lange Zeilen umbrechen oder horizontal scrollen';

  @override
  String get diffLineWrap => 'Umbrechen';

  @override
  String get diffLineScroll => 'Horizontal scrollen';

  @override
  String get actions => 'Aktionen';

  @override
  String get activate => 'Aktivieren';

  @override
  String get activity => 'Aktivität';

  @override
  String get activityLabel => 'AKTIVITÄT';

  @override
  String get activitySearchHint => 'Aktivität durchsuchen';

  @override
  String get activityNoMatches => 'Keine Aktivität entspricht deinen Filtern';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$start–$end von $total';
  }

  @override
  String get activityPreviousPage => 'Vorherige Seite';

  @override
  String get activityNextPage => 'Nächste Seite';

  @override
  String get activityNetworkLocal => 'Localhost';

  @override
  String get activityClearFilter => 'Filter löschen';

  @override
  String activityFilterIp(String ip) {
    return 'IP $ip';
  }

  @override
  String activityFilterCountry(String country) {
    return 'Land $country';
  }

  @override
  String get activitySavedWorkspaceLogo => 'Workspace-Logo gespeichert';

  @override
  String activityVerbCreated(String target) {
    return '$target erstellt';
  }

  @override
  String activityVerbUpdated(String target) {
    return '$target aktualisiert';
  }

  @override
  String activityVerbDeleted(String target) {
    return '$target gelöscht';
  }

  @override
  String activityVerbAdded(String target) {
    return '$target hinzugefügt';
  }

  @override
  String activityVerbRemoved(String target) {
    return '$target entfernt';
  }

  @override
  String activityVerbInvited(String target) {
    return '$target eingeladen';
  }

  @override
  String activityVerbChanged(String target) {
    return '$target geändert';
  }

  @override
  String activityVerbStarted(String target) {
    return '$target gestartet';
  }

  @override
  String activityVerbStopped(String target) {
    return '$target gestoppt';
  }

  @override
  String activityVerbWrote(String target) {
    return '$target geschrieben';
  }

  @override
  String get activityTargetAgent => 'Agent';

  @override
  String get activityTargetTicket => 'Ticket';

  @override
  String get activityTargetWorkspace => 'Workspace';

  @override
  String get activityTargetRepository => 'Repository';

  @override
  String get activityTargetMember => 'Mitglied';

  @override
  String get activityTargetInvite => 'Einladung';

  @override
  String get activityTargetSpace => 'Bereich';

  @override
  String get activityTargetMessage => 'Nachricht';

  @override
  String get activityTargetCache => 'Cache';

  @override
  String get activityTargetFile => 'Datei';

  @override
  String get activityTargetPipeline => 'Pipeline';

  @override
  String get activityTargetTemplate => 'Template';

  @override
  String get activityTargetProvider => 'Provider';

  @override
  String get activityTargetModel => 'Modell';

  @override
  String get activityTargetSkill => 'Skill';

  @override
  String get activityTargetTodo => 'Aufgabe';

  @override
  String get activityTargetMeeting => 'Meeting';

  @override
  String get activityTargetProject => 'Projekt';

  @override
  String get activityTargetTeam => 'Team';

  @override
  String get activityTargetDevice => 'Gerät';

  @override
  String get activityTargetPreference => 'Einstellung';

  @override
  String get activityTargetBudget => 'Budget';

  @override
  String activityVerbApproved(String target) {
    return '$target genehmigt';
  }

  @override
  String activityVerbArchived(String target) {
    return '$target archiviert';
  }

  @override
  String activityVerbAssigned(String target) {
    return '$target zugewiesen';
  }

  @override
  String activityVerbBackedUp(String target) {
    return '$target gesichert';
  }

  @override
  String activityVerbCancelled(String target) {
    return '$target abgebrochen';
  }

  @override
  String activityVerbCleared(String target) {
    return '$target geleert';
  }

  @override
  String activityVerbClosed(String target) {
    return '$target geschlossen';
  }

  @override
  String activityVerbCommitted(String target) {
    return '$target committet';
  }

  @override
  String activityVerbCompacted(String target) {
    return '$target kompaktiert';
  }

  @override
  String activityVerbCompleted(String target) {
    return '$target abgeschlossen';
  }

  @override
  String activityVerbConnected(String target) {
    return '$target verbunden';
  }

  @override
  String activityVerbContinued(String target) {
    return '$target fortgesetzt';
  }

  @override
  String activityVerbDisconnected(String target) {
    return '$target getrennt';
  }

  @override
  String activityVerbDispatched(String target) {
    return '$target weitergeleitet';
  }

  @override
  String activityVerbDrained(String target) {
    return '$target entleert';
  }

  @override
  String activityVerbEnrolled(String target) {
    return '$target angemeldet';
  }

  @override
  String activityVerbEstimated(String target) {
    return '$target geschätzt';
  }

  @override
  String activityVerbImported(String target) {
    return '$target importiert';
  }

  @override
  String activityVerbInstalled(String target) {
    return '$target installiert';
  }

  @override
  String activityVerbKilled(String target) {
    return '$target beendet';
  }

  @override
  String activityVerbMarked(String target) {
    return '$target markiert';
  }

  @override
  String activityVerbMerged(String target) {
    return '$target gemergt';
  }

  @override
  String activityVerbOpened(String target) {
    return '$target geöffnet';
  }

  @override
  String activityVerbPaused(String target) {
    return '$target pausiert';
  }

  @override
  String activityVerbPolled(String target) {
    return '$target abgefragt';
  }

  @override
  String activityVerbPrepared(String target) {
    return '$target vorbereitet';
  }

  @override
  String activityVerbProcessed(String target) {
    return '$target verarbeitet';
  }

  @override
  String activityVerbPublished(String target) {
    return '$target veröffentlicht';
  }

  @override
  String activityVerbRefined(String target) {
    return '$target verfeinert';
  }

  @override
  String activityVerbRefreshed(String target) {
    return '$target neu geladen';
  }

  @override
  String activityVerbRegistered(String target) {
    return '$target registriert';
  }

  @override
  String activityVerbRenamed(String target) {
    return '$target umbenannt';
  }

  @override
  String activityVerbReordered(String target) {
    return '$target neu sortiert';
  }

  @override
  String activityVerbResponded(String target) {
    return 'Auf $target geantwortet';
  }

  @override
  String activityVerbRestored(String target) {
    return '$target wiederhergestellt';
  }

  @override
  String activityVerbResumed(String target) {
    return '$target wiederaufgenommen';
  }

  @override
  String activityVerbRetried(String target) {
    return '$target erneut versucht';
  }

  @override
  String activityVerbReverted(String target) {
    return '$target rückgängig gemacht';
  }

  @override
  String activityVerbReviewed(String target) {
    return '$target geprüft';
  }

  @override
  String activityVerbRan(String target) {
    return '$target ausgeführt';
  }

  @override
  String activityVerbSelected(String target) {
    return '$target ausgewählt';
  }

  @override
  String activityVerbSent(String target) {
    return '$target gesendet';
  }

  @override
  String activityVerbStaged(String target) {
    return '$target gestagt';
  }

  @override
  String activityVerbSteered(String target) {
    return '$target gesteuert';
  }

  @override
  String activityVerbSubmitted(String target) {
    return '$target eingereicht';
  }

  @override
  String activityVerbSynced(String target) {
    return '$target synchronisiert';
  }

  @override
  String activityVerbToggled(String target) {
    return '$target umgeschaltet';
  }

  @override
  String activityVerbUninstalled(String target) {
    return '$target deinstalliert';
  }

  @override
  String activityVerbUnstaged(String target) {
    return '$target aus dem Index entfernt';
  }

  @override
  String get activityTargetActionPolicy => 'Aktionsrichtlinie';

  @override
  String get activityTargetGoalRun => 'Goal-Run';

  @override
  String get activityTargetRunLog => 'Run-Log';

  @override
  String get activityTargetWorkingMemory => 'Arbeitsgedächtnis';

  @override
  String get activityTargetRoutingPolicy => 'Routing-Richtlinie';

  @override
  String get activityTargetAutonomy => 'Autonomie';

  @override
  String get activityTargetCalendar => 'Kalender';

  @override
  String get activityTargetChecker => 'Checker';

  @override
  String get activityTargetEditor => 'Editor';

  @override
  String get activityTargetConfirmation => 'Bestätigung';

  @override
  String get activityTargetTunnel => 'Tunnel';

  @override
  String get activityTargetConversation => 'Konversation';

  @override
  String get activityTargetCredentials => 'Zugangsdaten';

  @override
  String get activityTargetDictation => 'Diktat';

  @override
  String get activityTargetAgentRun => 'Agent-Run';

  @override
  String get activityTargetEvalSuite => 'Eval-Suite';

  @override
  String get activityTargetWorker => 'Worker';

  @override
  String get activityTargetWorktree => 'Worktree';

  @override
  String get activityTargetMcpServer => 'MCP-Server';

  @override
  String get activityTargetMemoryAccessGrant => 'Speicherzugriffsberechtigung';

  @override
  String get activityTargetMemoryDomain => 'Speicherdomäne';

  @override
  String get activityTargetMemoryFact => 'Speicherfakt';

  @override
  String get activityTargetMemoryPolicy => 'Speicherrichtlinie';

  @override
  String get activityTargetFeed => 'Feed';

  @override
  String get activityTargetNote => 'Notiz';

  @override
  String get activityTargetOrchestration => 'Orchestrierung';

  @override
  String get activityTargetPipelineRun => 'Pipeline-Run';

  @override
  String get activityTargetPipelineTrigger => 'Pipeline-Trigger';

  @override
  String get activityTargetPlan => 'Plan';

  @override
  String get activityTargetPlaybook => 'Playbook';

  @override
  String get activityTargetPullRequest => 'Pull Request';

  @override
  String get activityTargetReview => 'Review';

  @override
  String get activityTargetProcess => 'Prozess';

  @override
  String get activityTargetProviderPolicy => 'Provider-Richtlinie';

  @override
  String get activityTargetReaction => 'Reaktion';

  @override
  String get activityTargetReviewSpace => 'Review-Bereich';

  @override
  String get activityTargetReviewStudio => 'Review-Studio';

  @override
  String get activityTargetServerData => 'Serverdaten';

  @override
  String get activityTargetSoundscape => 'Klanglandschaft';

  @override
  String get activityTargetSession => 'Session';

  @override
  String get activityTargetTerminal => 'Terminal';

  @override
  String get activityTargetTicketLink => 'Ticket-Verknüpfung';

  @override
  String get activityTargetTicketSync => 'Ticket-Sync';

  @override
  String get activityTargetProfile => 'Profil';

  @override
  String get activityTargetVoiceProfile => 'Stimmprofil';

  @override
  String get activityTargetWeather => 'Wettervorhersage';

  @override
  String get activityTargetWorkProduct => 'Arbeitsergebnis';

  @override
  String get activityChangedMemberRole => 'Rolle eines Mitglieds geändert';

  @override
  String get activityChangedMemberRepoAccess =>
      'Repository-Zugriff eines Mitglieds geändert';

  @override
  String get activityUpdatedGitHubToken => 'GitHub-Token aktualisiert';

  @override
  String get activityRefreshedWeather => 'Wettervorhersage neu geladen';

  @override
  String get activitySetWeatherLocation => 'Wetterstandort festgelegt';

  @override
  String get activityClearedWeatherLocation => 'Wetterstandort gelöscht';

  @override
  String get activityMarkedAllArticlesRead =>
      'Alle Artikel als gelesen markiert';

  @override
  String get activityMarkedArticleRead => 'Artikel als gelesen markiert';

  @override
  String get activityUpdatedSavedArticle =>
      'Gespeicherten Artikel aktualisiert';

  @override
  String get activityTookOverSession => 'Session übernommen';

  @override
  String get activityHandedBackSession => 'Session zurückgegeben';

  @override
  String get activityCommittedAndPushed => 'Committet und gepusht';

  @override
  String get activityBackedUpServer => 'Serverdaten gesichert';

  @override
  String get activityMarkedSpaceRead => 'Bereich als gelesen markiert';

  @override
  String get activityRespondedToInvitation =>
      'Auf die Termineinladung geantwortet';

  @override
  String get activityStartedCalendarConnect => 'Kalenderverbindung gestartet';

  @override
  String get activityDisconnectedCalendar => 'Kalender getrennt';

  @override
  String get activityMarkedFileViewed => 'Datei als angesehen markiert';

  @override
  String get activityRespondedToApproval =>
      'Auf eine Genehmigungsanfrage geantwortet';

  @override
  String get activityChangedTunnel => 'Tunnel-Einstellung geändert';

  @override
  String get activitySentMessageToAgent => 'Nachricht an den Agenten gesendet';

  @override
  String get activityOpenedReviewSpace => 'Review-Bereich geöffnet';

  @override
  String get activityOpenedStandingConversation =>
      'Hat die feste Unterhaltung geöffnet';

  @override
  String get activityStartedRecording => 'Aufnahme gestartet';

  @override
  String get activityStoppedRecording => 'Aufnahme gestoppt';

  @override
  String get activityToggledMcpServer => 'MCP-Server umgeschaltet';

  @override
  String get activityUpdatedMcpToken => 'MCP-Token aktualisiert';

  @override
  String get activitySavedApiKey => 'API-Schlüssel gespeichert';

  @override
  String get activityRemovedProviderCredential =>
      'Provider-Zugangsdaten entfernt';

  @override
  String get activityUpdatedLinkedRepos =>
      'Verknüpfte Repositories aktualisiert';

  @override
  String get activityUnlinkedRepo => 'Repository-Verknüpfung aufgehoben';

  @override
  String get activityUpdatedActionItem => 'Aktionspunkt aktualisiert';

  @override
  String adRulesCount(int count) {
    return '$count Werberegeln';
  }

  @override
  String get adapter => 'Adapter';

  @override
  String get adapterLabel => 'Adapter';

  @override
  String get adapters => 'Adapter';

  @override
  String get adaptersAutoDetected =>
      'Automatisch erkannte Agent-Runner auf diesem Computer. Installiere fehlende CLI-Tools, um zusätzliche Runner zu aktivieren.';

  @override
  String get add => 'Hinzufügen';

  @override
  String get addAComment => 'Einen Kommentar hinzufügen';

  @override
  String get addAReaction => 'Eine Reaktion hinzufügen';

  @override
  String get addASuggestion => 'Einen Vorschlag hinzufügen';

  @override
  String get addAgents => 'Agenten hinzufügen';

  @override
  String get addEmoji => 'Emoji hinzufügen';

  @override
  String get addFeed => 'Feed hinzufügen';

  @override
  String get addressBarHint => 'URL eingeben';

  @override
  String get addFromFile => 'Aus Datei hinzufügen';

  @override
  String get addGif => 'GIF hinzufügen';

  @override
  String get addGithubRepoPrompt =>
      'Mindestens ein GitHub-Repository hinzufügen, um Pull Requests zu sehen';

  @override
  String get addLocalCheckoutDescription =>
      'Füge einen lokalen Checkout hinzu, um ihn aus diesem Arbeitsbereich zu steuern.';

  @override
  String get addRepository => 'Repository hinzufügen';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Repositories hinzufügen',
      one: 'Repository hinzufügen',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro =>
      'Durchsuche die Ordner auf dem Rechner, der den Server ausführt, und wähle die zu registrierenden Git-Checkouts aus.';

  @override
  String get selectThisFolder => 'Diesen Ordner auswählen';

  @override
  String get deselectThisFolder => 'Auswahl dieses Ordners aufheben';

  @override
  String get goUp => 'Nach oben';

  @override
  String get noSubfoldersHere => 'Keine Unterordner hier';

  @override
  String get notAGitRepository => 'Dieser Ordner ist kein Git-Repository.';

  @override
  String get addToken => 'Token hinzufügen';

  @override
  String get addWorkspace => 'Arbeitsbereich hinzufügen';

  @override
  String get addWorkspaceEllipsis => 'Arbeitsbereich hinzufügen…';

  @override
  String get added => 'Hinzugefügt';

  @override
  String get addingEllipsis => 'Hinzufügen…';

  @override
  String get advancedLabel => 'Erweitert';

  @override
  String get agent => 'Agent';

  @override
  String agentCount(int count, int plural) {
    String _temp0 = intl.Intl.pluralLogic(
      plural,
      locale: localeName,
      other: 'en',
      one: '',
    );
    return '$count Agent$_temp0';
  }

  @override
  String get agentMdPath => 'Agent-MD-Pfad';

  @override
  String get agentName => 'Agentname';

  @override
  String get agentTitle => 'Agenttitel';

  @override
  String get agentUpdated => 'Agent aktualisiert.';

  @override
  String get agents => 'Agenten';

  @override
  String get agentsMentionSection => 'Agenten';

  @override
  String get usersMentionSection => 'Personen';

  @override
  String get ticketsMentionSection => 'Tickets';

  @override
  String get pullRequestsMentionSection => 'Pull Requests';

  @override
  String get meetingsMentionSection => 'Besprechungen';

  @override
  String get entityRefTicketFallback => 'Ticket';

  @override
  String get entityRefPrFallback => 'Pull Request';

  @override
  String get entityRefMeetingFallback => 'Besprechung';

  @override
  String get aiReview => 'KI-Review';

  @override
  String get all => 'Alle';

  @override
  String get allAgentsAlreadyInSpace =>
      'Alle Agenten sind bereits in diesem Bereich.';

  @override
  String get allCommits => 'Alle Commits';

  @override
  String get allSources => 'Alle Quellen';

  @override
  String get allow => 'Erlauben';

  @override
  String get allowGitPush => 'git push erlauben';

  @override
  String get allowGithubApi => 'GitHub-API-Aufrufe erlauben';

  @override
  String get allowNetwork => 'Allgemeinen Netzwerkzugriff erlauben';

  @override
  String get apiKeys => 'API-Schlüssel';

  @override
  String get appFont => 'App-Schriftart';

  @override
  String get appLogLevelDebugDescription =>
      'Fügt detaillierte Traces hinzu - für Entwicklung.';

  @override
  String get appLogLevelDebugLabel => 'Debug';

  @override
  String get appLogLevelErrorDescription =>
      'Nur Fehler und unerwartete Ausnahmen.';

  @override
  String get appLogLevelErrorLabel => 'Fehler';

  @override
  String get appLogLevelInfoDescription =>
      'Fügt Lebenszyklus- und Statusmeldungen hinzu.';

  @override
  String get appLogLevelInfoLabel => 'Info';

  @override
  String get appLogLevelNoneDescription => 'Keine Konsolenausgabe.';

  @override
  String get appLogLevelNoneLabel => 'Keine';

  @override
  String get appLogLevelVerboseDescription =>
      'Alles. Extrem verbose - nur zum Debuggen verwenden.';

  @override
  String get appLogLevelVerboseLabel => 'Verbose';

  @override
  String get appLogLevelWarningDescription =>
      'Fügt Warnungen und behebbare Probleme hinzu.';

  @override
  String get appLogLevelWarningLabel => 'Warnung';

  @override
  String get appearanceLanguage => 'Erscheinungsbild & Sprache';

  @override
  String get apply => 'Anwenden';

  @override
  String get approve => 'Genehmigen';

  @override
  String get agentApprovalRequired => 'Genehmigung erforderlich';

  @override
  String agentApprovalsMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weitere warten',
      one: '1 weitere wartet',
    );
    return '$_temp0';
  }

  @override
  String get approved => 'Genehmigt';

  @override
  String get articlesSubscribed => 'Artikel aus deinen abonnierten Feeds.';

  @override
  String get askAi => 'Ask AI';

  @override
  String get askAiReviewDescription => 'KI bitten, diesen PR zu reviewen';

  @override
  String get assignees => 'ZUGEWIESENE';

  @override
  String get attachFiles => 'Dateien anhängen';

  @override
  String get attachImage => 'Bild anhängen';

  @override
  String get attachedAgents => 'Zugeordnete Agenten';

  @override
  String get audioInput => 'Audioeingabe';

  @override
  String get audioOutput => 'Audioausgabe';

  @override
  String get authenticationToken => 'Authentifizierungstoken';

  @override
  String authoredByLabel(String role) {
    return 'Von: $role';
  }

  @override
  String get autoRecommended => 'Auto (empfohlen)';

  @override
  String get available => 'Verfügbar';

  @override
  String get awaitingYourReview => 'Wartet auf dein Review';

  @override
  String get back => 'Zurück';

  @override
  String get backLabel => 'Zurück';

  @override
  String get backend => 'Backend';

  @override
  String get blockAdsTrackers => 'Werbung, Tracker & Cookie-Banner blockieren';

  @override
  String get blocking => 'Blockiert';

  @override
  String get bookmarkLabel => 'Lesezeichen';

  @override
  String get briefDescription => 'Kurze Beschreibung';

  @override
  String get bugLabel => 'BUG';

  @override
  String get bundledDefaultsNeverUpdated => 'Vorinstalliert - nie aktualisiert';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get cancelEdit => 'Bearbeitung abbrechen';

  @override
  String get categoryCreation => 'Erstellung';

  @override
  String get categoryEditing => 'Bearbeitung';

  @override
  String get categoryNavigation => 'Navigation';

  @override
  String get categorySystem => 'System';

  @override
  String get categoryView => 'Ansicht';

  @override
  String get change => 'Ändern';

  @override
  String get changesRequested => 'Änderungen angefordert';

  @override
  String get spacesMentionSection => 'Bereiche';

  @override
  String get checkForUpdates => 'Nach Updates suchen';

  @override
  String get checking => 'Überprüfung';

  @override
  String get checkingEllipsis => 'Überprüfung…';

  @override
  String get chooseAppFont => 'App-Schriftart wählen';

  @override
  String get chooseCodeFont => 'Code-Schriftart wählen';

  @override
  String get chooseRunner => 'Wähle deinen Agent-Runner.';

  @override
  String get clear => 'Löschen';

  @override
  String get clickToRetry => 'Klicken, um erneut zu versuchen';

  @override
  String get close => 'Schließen';

  @override
  String get closeEsc => 'Schließen (Esc)';

  @override
  String get closeKeyboardHint => 'Tastenkürzel schließen';

  @override
  String get closeReader => 'Leser schließen';

  @override
  String get closed => 'Geschlossen';

  @override
  String get codeFont => 'Code-Schriftart';

  @override
  String get codeFontLigatures => 'Ligaturen der Code-Schriftart';

  @override
  String get codeFontLigaturesDescription =>
      'Programmier-Ligaturen (=>, !=, ->) als kombinierte Glyphen in Code und Diffs darstellen';

  @override
  String get collapse => 'Einklappen';

  @override
  String get commandPalette => 'Befehlspalette';

  @override
  String get commandPaletteOrgMembers => 'Organization members';

  @override
  String get commandPaletteBrowseTeam => 'Browse team';

  @override
  String get commandPaletteBrowseTeamDesc => 'View all organization members';

  @override
  String get compactDone =>
      'Unterhaltung verdichtet. Der ältere Verlauf wurde zusammengefasst.';

  @override
  String get compactNothing =>
      'Noch nichts zu verdichten. Die Unterhaltung ist noch kurz.';

  @override
  String get compactBusy =>
      'Ein Agent arbeitet noch. Verdichte, wenn der Zug abgeschlossen ist.';

  @override
  String get compactUnavailable =>
      'Verdichten ist auf diesem Server nicht verfügbar.';

  @override
  String get commandsMentionSection => 'Befehle';

  @override
  String get comment => 'Kommentar';

  @override
  String get commentOnThisFile => 'Diese Datei kommentieren';

  @override
  String get commented => 'Kommentiert';

  @override
  String get commits => 'Commits';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'Zeige die letzten $loaded von $total Commits';
  }

  @override
  String get prCloneProgressCloningTitle => 'Repository wird geklont';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'Dieser PR ändert $fileCount Dateien und überschreitet das API-Limit von GitHub. Das Repository wird lokal geklont…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'Dieser PR überschreitet das Datei-Limit der GitHub-API. Das Repository wird lokal geklont…';

  @override
  String get prCloneProgressFetchingTitle => 'Refs werden abgerufen';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'Basis-Branch und PR-Ref werden abgerufen…';

  @override
  String get prCloneProgressComputingTitle => 'Diff wird berechnet';

  @override
  String get prCloneProgressComputingSubtitle =>
      'git diff wird lokal ausgeführt…';

  @override
  String get prCloneProgressErrorTitle => 'Diff konnte nicht geladen werden';

  @override
  String get prCloneProgressErrorSubtitle =>
      'Beim Klonen oder Berechnen des Diffs ist ein Fehler aufgetreten.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'Läuft noch… $elapsed vergangen';
  }

  @override
  String confidenceLabel(int percent) {
    return 'Konfidenz: $percent%';
  }

  @override
  String get configureAgentIdentities =>
      'Agent-Identitäten, Prompts, Fähigkeiten konfigurieren und Läufe anzeigen.';

  @override
  String get configureDefaultRunners =>
      'Konfiguriere, welcher Adapter und welches Modell für neue Konversationen und Titelerstellung verwendet werden.';

  @override
  String get configuredLabel => 'Konfiguriert.';

  @override
  String get confirmedBy => 'Bestätigt von';

  @override
  String get consensus => 'Konsens';

  @override
  String get contentHint => 'Was gespeichert werden soll';

  @override
  String get contentLabel => 'Inhalt';

  @override
  String get contentMarkdown => 'Inhalt (Markdown)';

  @override
  String get contextWindowSize => 'Kontextfenstergröße';

  @override
  String modelContextChip(String size) {
    return 'Modell · $size';
  }

  @override
  String get continueLabel => 'Weiter';

  @override
  String get conversationMode => 'Modus';

  @override
  String cookieRulesCount(int count) {
    return '$count Cookie-Regeln';
  }

  @override
  String get copied => 'Kopiert!';

  @override
  String get copy => 'Kopieren';

  @override
  String get copyAddress => 'Adresse kopieren';

  @override
  String get copyBaseBranchTooltip => 'Namen des Ziel-Branch kopieren';

  @override
  String get copyHeadBranchTooltip => 'Namen des Quell-Branch kopieren';

  @override
  String couldNotListDevices(String error) {
    return 'Geräte konnten nicht aufgelistet werden: $error';
  }

  @override
  String get create => 'Erstellen';

  @override
  String get createOrSelectWorkspace =>
      'Erstelle oder wähle einen Arbeitsbereich, bevor du Repositorys hinzufügst.';

  @override
  String get createPullRequest => 'Pull Request erstellen';

  @override
  String get createdByMe => 'Von mir erstellt';

  @override
  String createdLabel(String date) {
    return 'Erstellt: $date';
  }

  @override
  String get currentParticipants => 'Aktuelle Teilnehmer';

  @override
  String get customCapabilitiesDescription =>
      'Benutzerdefinierte Fähigkeiten für diesen Agenten';

  @override
  String get customSystemPrompt =>
      'Benutzerdefinierter System-Prompt für diesen Agenten...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Tagen',
      one: 'vor 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'Deaktivieren';

  @override
  String get defaultCapabilities => 'Standardfähigkeiten · neue Konversationen';

  @override
  String get defaultChat => 'Standard-Chat';

  @override
  String get defaultRunners => 'Standard-Runner';

  @override
  String get delete => 'Löschen';

  @override
  String get deleteAgent => 'Agent löschen';

  @override
  String deleteAgentConfirm(String name) {
    return '\"$name\" löschen? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get deleteSpace => 'Bereich löschen';

  @override
  String deleteConfirmName(String name) {
    return '\"$name\" löschen?';
  }

  @override
  String get archiveConversation => 'Konversation archivieren';

  @override
  String get deleteFact => 'Fakt löschen';

  @override
  String get deleteFeedBody =>
      'Dies entfernt den Feed und alle seine zwischengespeicherten Artikel. Lesezeichen von Artikeln dieses Feeds werden ebenfalls entfernt.';

  @override
  String deleteFeedConfirm(String name) {
    return '\"$name\" löschen?';
  }

  @override
  String get deletePolicy => 'Richtlinie löschen';

  @override
  String get deletePolicyConfirm =>
      'Diese Richtlinie löschen? Dies kann nicht rückgängig gemacht werden.';

  @override
  String deleteTopicConfirm(String topic) {
    return '\"$topic\" löschen? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get deleteWorkspace => 'Arbeitsbereich löschen';

  @override
  String get deny => 'Verweigern';

  @override
  String get descriptionLabel => 'Beschreibung';

  @override
  String detectedBackend(String label) {
    return 'Erkannt: $label';
  }

  @override
  String get detectedRunners => 'Erkannte Runner';

  @override
  String get detectingAdapters => 'Adapter erkennen…';

  @override
  String get detectingInputDevices => 'Eingabegeräte werden erkannt…';

  @override
  String detectionFailed(String error) {
    return 'Erkennung fehlgeschlagen: $error';
  }

  @override
  String get disabled => 'Deaktiviert';

  @override
  String get discover => 'Entdecken';

  @override
  String get dismissed => 'Verworfen';

  @override
  String get domainHint => 'z.B. api-performance';

  @override
  String get domainLabel => 'Domäne';

  @override
  String get download => 'Herunterladen';

  @override
  String get downloadingLabel => 'Lade herunter';

  @override
  String downloadingModel(int pct) {
    return 'Modell wird heruntergeladen… $pct%';
  }

  @override
  String get draft => 'Entwurf';

  @override
  String get draftLabel => 'Entwurf';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get edited => 'bearbeitet';

  @override
  String get editMessage => 'Nachricht bearbeiten';

  @override
  String get deleteMessage => 'Nachricht löschen';

  @override
  String get deleteMessageConfirm =>
      'Diese Nachricht löschen? Das kann nicht rückgängig gemacht werden.';

  @override
  String get messageDeleted => 'Nachricht gelöscht';

  @override
  String get searchInConversation => 'In Unterhaltung suchen';

  @override
  String get searchMessagesHint => 'Nachrichten durchsuchen…';

  @override
  String get noMessagesFound => 'Keine Nachrichten gefunden';

  @override
  String get editFact => 'Fakt bearbeiten';

  @override
  String get editPolicy => 'Richtlinie bearbeiten';

  @override
  String get editSuggestedCodeHint => 'Vorgeschlagenen Code bearbeiten…';

  @override
  String get editSuggestion => 'Vorschlag bearbeiten';

  @override
  String get egArchitect => 'z.B. Architekt';

  @override
  String get egControlCenter => 'z.B. control-center';

  @override
  String get egPlatform => 'z.B. macOS';

  @override
  String get egSamuelAlev => 'z.B. SamuelAlev';

  @override
  String get egSoftwareArchitect => 'z.B. Software-Architekt';

  @override
  String get egTheVerge => 'z.B. The Verge';

  @override
  String get egTokenLimit => 'z.B. 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'Installation fehlgeschlagen: $error';
  }

  @override
  String get embeddingInstalled =>
      'Lokales Embedding-Modell installiert. Hybride Suche ist aktiviert.';

  @override
  String get embeddingModel => 'Embedding-Modell (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'Nicht installiert. Suche greift auf reine Schlüsselwortsuche zurück, bis aktiviert.';

  @override
  String get embeddingRedownloadBody =>
      'Die vorhandenen Modelldateien werden gelöscht und erneut heruntergeladen. Die semantische Suche steht bis zum Abschluss des Downloads nicht zur Verfügung.';

  @override
  String get embeddingRemoveBody =>
      'Die semantische Suche wird deaktiviert, bis du sie neu installierst. Du kannst sie jederzeit wieder installieren.';

  @override
  String get speakerDiarization => 'Sprecher-Diarisierung';

  @override
  String get diarizationModel => 'Diarisierungsmodell';

  @override
  String get diarizationInstalled =>
      'Installiert — benennt einzelne Sprecher in Meeting-Transkripten';

  @override
  String get diarizationNotInstalled =>
      'Nicht installiert — Meeting-Sprecher werden nicht getrennt';

  @override
  String diarizationInstallFailed(String error) {
    return 'Installation fehlgeschlagen: $error';
  }

  @override
  String get redownloadDiarizationModel =>
      'Diarisierungsmodell erneut herunterladen';

  @override
  String get diarizationRedownloadBody =>
      'Dadurch werden die aktuellen Diarisierungsmodelle entfernt und erneut heruntergeladen.';

  @override
  String get removeDiarizationModel => 'Diarisierungsmodell entfernen';

  @override
  String get diarizationRemoveBody =>
      'Dadurch werden die Diarisierungsmodelle auf dem Gerät gelöscht. Bereits erstellte Meeting-Transkripte sind nicht betroffen.';

  @override
  String get enableNotifications => 'Benachrichtigungen aktivieren';

  @override
  String get enableSandboxing => 'Sandboxing aktivieren';

  @override
  String get enabled => 'Aktiviert';

  @override
  String errorCreatingAgent(String error) {
    return 'Fehler beim Erstellen des Agenten: $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'Fehler beim Löschen des Agenten: $error';
  }

  @override
  String errorWithDetail(String error) {
    return 'Fehler: $error';
  }

  @override
  String get expand => 'Ausklappen';

  @override
  String extractingModel(int pct) {
    return 'Modell wird extrahiert… $pct%';
  }

  @override
  String get fact => 'Fakt';

  @override
  String factCount(int count) {
    return '$count Fakt';
  }

  @override
  String factCountPlural(int count) {
    return '$count Fakten';
  }

  @override
  String get facts => 'Fakten';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount Fakten · $policyCount Richtlinien';
  }

  @override
  String get failed => 'Fehlgeschlagen';

  @override
  String failedToDispatch(String error) {
    return 'Versand fehlgeschlagen: $error';
  }

  @override
  String get failedToLoad => 'Laden fehlgeschlagen';

  @override
  String failedToLoadAgents(String error) {
    return 'Agenten konnten nicht geladen werden: $error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'Feeds konnten nicht geladen werden: $error';
  }

  @override
  String get failedToLoadGifs => 'GIFs konnten nicht geladen werden';

  @override
  String failedToLoadLogs(String error) {
    return 'Protokolle konnten nicht geladen werden: $error';
  }

  @override
  String get failedToLoadRepos => 'Repositorys konnten nicht geladen werden';

  @override
  String get failedToLoadWorkspaces =>
      'Arbeitsbereiche konnten nicht geladen werden';

  @override
  String failedToStartAiReview(String error) {
    return 'KI-Review konnte nicht gestartet werden: $error';
  }

  @override
  String get failedToStartMicTest =>
      'Mikrofontest konnte nicht gestartet werden.';

  @override
  String failedToSubmitReview(String error) {
    return 'Review konnte nicht gesendet werden: $error';
  }

  @override
  String failedToUpload(String name, String error) {
    return 'Upload von $name fehlgeschlagen: $error';
  }

  @override
  String failedWithError(String error) {
    return 'Fehlgeschlagen: $error';
  }

  @override
  String get failure => 'Fehlgeschlagen';

  @override
  String get feedAlreadyExists => 'Ein Feed mit dieser URL existiert bereits.';

  @override
  String get feedUrlExample => 'z.B. https://example.com/feed.xml';

  @override
  String get feedUrlLabel => 'Feed-URL';

  @override
  String feedsCount(int count) {
    return 'Feeds ($count)';
  }

  @override
  String get filesChanged => 'Dateien geändert';

  @override
  String filesCount(int count) {
    return '$count Datei(en)';
  }

  @override
  String get filesMentionSection => 'Dateien';

  @override
  String get filterAgents => 'Agenten filtern...';

  @override
  String get filterFilesHint => 'Dateien filtern…';

  @override
  String get filterLists => 'Filterlisten';

  @override
  String get filterSkillsPlaceholder => 'Fähigkeiten filtern…';

  @override
  String get finish => 'Abschließen';

  @override
  String get fix => 'Korrektur';

  @override
  String get forward => 'Weiterleiten';

  @override
  String get gatesGithubPatPush =>
      'Steuert GitHub PAT-Injektion. Erforderlich, damit der Agent pushen kann.';

  @override
  String get general => 'Allgemein';

  @override
  String get githubLink => 'GitHub-Link';

  @override
  String get claudeStatusFetchFailed =>
      'status.claude.com konnte nicht erreicht werden';

  @override
  String get claudeStatusOpenInBrowser => 'status.claude.com öffnen';

  @override
  String get githubStatusFetchFailed =>
      'githubstatus.com konnte nicht erreicht werden';

  @override
  String get githubDegradedTitle => 'GitHub meldet Probleme';

  @override
  String githubDegradedStatusLine(String status) {
    return 'GitHub-Status: $status.';
  }

  @override
  String githubDegradedBody(String status) {
    return 'GitHub-Status: $status. Pull-Request-Daten können veraltet oder unvollständig sein, bis sich das erholt.';
  }

  @override
  String get githubStatusOpenInBrowser => 'githubstatus.com öffnen';

  @override
  String get githubStatusRefresh => 'Aktualisieren';

  @override
  String githubStatusUpdated(String time) {
    return 'Aktualisiert $time';
  }

  @override
  String get kimiStatusFetchFailed =>
      'status.moonshot.cn konnte nicht erreicht werden';

  @override
  String get kimiStatusOpenInBrowser => 'status.moonshot.cn öffnen';

  @override
  String get openaiStatusFetchFailed =>
      'status.openai.com konnte nicht erreicht werden';

  @override
  String get openaiStatusOpenInBrowser => 'status.openai.com öffnen';

  @override
  String get serviceStatusMaintenance => 'Wartung';

  @override
  String get serviceStatusMajorIssues => 'Größere Probleme';

  @override
  String get serviceStatusMinorIssues => 'Kleinere Probleme';

  @override
  String get serviceStatusOperational => 'Betriebsbereit';

  @override
  String get serviceStatusOutage => 'Ausfall';

  @override
  String get serviceStatusTitle => 'Dienststatus';

  @override
  String get serviceStatusUnknown => 'Unbekannt';

  @override
  String lastChecked(String time) {
    return 'Geprüft $time';
  }

  @override
  String get lastCheckedRecently => 'Kürzlich geprüft';

  @override
  String get giveYourWorkAHome => 'Gib deiner Arbeit ein Zuhause.';

  @override
  String get goBack => 'Zurückgehen';

  @override
  String get goForward => 'Vorwärtsgehen';

  @override
  String get googleFonts => 'Google Fonts';

  @override
  String get high => 'Hoch';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Stunden',
      one: 'vor 1 Stunde',
    );
    return '$_temp0';
  }

  @override
  String get images => 'Bilder';

  @override
  String get inactive => 'Inaktiv';

  @override
  String get install => 'Installieren';

  @override
  String get installRequired => 'Installation erforderlich';

  @override
  String installedVersion(String version) {
    return 'Installiert $version';
  }

  @override
  String get invite => 'Einladen';

  @override
  String get inviteAgent => 'Agenten einladen';

  @override
  String get isolateAgentExecution => 'Agentenausführung isolieren.';

  @override
  String get justNow => 'gerade eben';

  @override
  String get keepSandboxing => 'Sandboxing beibehalten';

  @override
  String get keybindingAddARepositoryDescription => 'Ein Repository hinzufügen';

  @override
  String get keybindingAddRepository => 'Repository hinzufügen';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'Ausgewählten Artikel bookmarken oder entbookmarken';

  @override
  String get keybindingCommandPalette => 'Befehlspalette';

  @override
  String get keybindingCreateANewAgentDescription => 'Neuen Agenten erstellen';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'Neuen Arbeitsbereich erstellen';

  @override
  String get keybindingFocusSearch => 'Suche fokussieren';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'Das Pull-Request-Suchfeld fokussieren';

  @override
  String get keybindingNewAgent => 'Neuer Agent';

  @override
  String get keybindingNewWorkspace => 'Neuer Arbeitsbereich';

  @override
  String get keybindingNextArticle => 'Nächster Artikel';

  @override
  String get keybindingNextSpace => 'Nächster Bereich';

  @override
  String get keybindingNextWorkspace => 'Nächster Arbeitsbereich';

  @override
  String get keybindingOpenArticle => 'Artikel öffnen';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'Arbeitsbereich-Umschalt-Popup in der Seitenleiste öffnen oder schließen';

  @override
  String get keybindingOpenPr => 'PR öffnen';

  @override
  String get keybindingOpenSettings => 'Einstellungen öffnen';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'Anwendungseinstellungen öffnen';

  @override
  String get keybindingOpenTheCommandPaletteDescription =>
      'Befehlspalette öffnen';

  @override
  String get keybindingOpenTheSelectedArticleDescription =>
      'Ausgewählten Artikel öffnen';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'Ausgewählte Pull Request öffnen';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'Ausgewählten Arbeitsbereich öffnen';

  @override
  String get keybindingOpenWorkspace => 'Arbeitsbereich öffnen';

  @override
  String get keybindingPreviousArticle => 'Vorheriger Artikel';

  @override
  String get keybindingPreviousSpace => 'Vorheriger Bereich';

  @override
  String get keybindingPreviousWorkspace => 'Vorheriger Arbeitsbereich';

  @override
  String get keybindingRefresh => 'Aktualisieren';

  @override
  String get keybindingRefreshAllFeedsDescription => 'Alle Feeds aktualisieren';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'Pull-Request-Liste aktualisieren';

  @override
  String get keybindingRescanForAdaptersDescription =>
      'Nach Adaptern neu scannen';

  @override
  String get keybindingSelectTheNextArticleDescription =>
      'Nächsten Artikel auswählen';

  @override
  String get keybindingSelectTheNextSpaceDescription =>
      'Nächsten Bereich auswählen';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'Vorherigen Artikel auswählen';

  @override
  String get keybindingSelectThePreviousSpaceDescription =>
      'Vorherigen Bereich auswählen';

  @override
  String get keybindingSendMessage => 'Nachricht senden';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'Aktuelle Nachricht senden';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Zwischen hellem und dunklem Modus wechseln';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Zum achten Arbeitsbereich wechseln';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Zum fünften Arbeitsbereich wechseln';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'Zum ersten Arbeitsbereich wechseln';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'Zum vierten Arbeitsbereich wechseln';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'Zum nächsten Arbeitsbereich wechseln';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'Zum neunten Arbeitsbereich wechseln';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'Zum vorherigen Arbeitsbereich wechseln';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'Zum zweiten Arbeitsbereich wechseln';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'Zum siebten Arbeitsbereich wechseln';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'Zum sechsten Arbeitsbereich wechseln';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'Zum dritten Arbeitsbereich wechseln';

  @override
  String get keybindingToggleBookmark => 'Bookmark umschalten';

  @override
  String get keybindingToggleTheme => 'Theme umschalten';

  @override
  String get keybindingToggleWorkspaceSwitcher =>
      'Arbeitsbereich-Umschalter umschalten';

  @override
  String get keybindingWorkspace1 => 'Workspace1';

  @override
  String get keybindingWorkspace2 => 'Workspace2';

  @override
  String get keybindingWorkspace3 => 'Workspace3';

  @override
  String get keybindingWorkspace4 => 'Workspace4';

  @override
  String get keybindingWorkspace5 => 'Workspace5';

  @override
  String get keybindingWorkspace6 => 'Workspace6';

  @override
  String get keybindingWorkspace7 => 'Workspace7';

  @override
  String get keybindingWorkspace8 => 'Workspace8';

  @override
  String get keybindingWorkspace9 => 'Workspace9';

  @override
  String get keybindings => 'Tastaturkürzel';

  @override
  String get keybindingsDescription =>
      'Alle Tastaturkürzel. Kürzel sind fest und können nicht neu zugewiesen werden.';

  @override
  String get killRunning => 'Laufenden beenden';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageSystem => 'System';

  @override
  String get leaveACommentEllipsis => 'Kommentar hinterlassen…';

  @override
  String get legendLabel => 'Legende';

  @override
  String get lessLabel => 'Weniger';

  @override
  String get letsPluginTools => 'Lass uns deine Tools einbinden.';

  @override
  String get level => 'Stufe';

  @override
  String get loadingAgents => 'Agenten laden…';

  @override
  String get loadingModels => 'Modelle laden…';

  @override
  String get loadingProviders => 'Anbieter laden…';

  @override
  String get logLevel => 'Log-Level';

  @override
  String get logs => 'Protokolle';

  @override
  String get low => 'Niedrig';

  @override
  String get maintenance => 'Wartung';

  @override
  String get manageParticipants => 'Teilnehmer verwalten';

  @override
  String get manageWorkspaces => 'Arbeitsbereiche verwalten';

  @override
  String get reorderWorkspace => 'Arbeitsbereich neu anordnen';

  @override
  String get matchOsAppearance =>
      'An das Betriebssystem anpassen oder einen festen Modus wählen.';

  @override
  String get mcpAuthToken => 'MCP-Authentifizierungstoken';

  @override
  String get mcpNotAvailableOnServer =>
      'Die MCP-Serversteuerung ist auf dem verbundenen Server nicht verfügbar.';

  @override
  String get modelManagedOnServer =>
      'Dieses Modell läuft auf dem Server-Host und wird dort verwaltet.';

  @override
  String get mcpServer => 'MCP-Server';

  @override
  String get medium => 'Mittel';

  @override
  String get memoryDataHint =>
      'Fakten und Richtlinien erscheinen hier, während Agenten arbeiten.';

  @override
  String get memoryLabel => 'Speicher';

  @override
  String get merge => 'Merge';

  @override
  String get merged => 'Zusammengeführt';

  @override
  String get messagePlaceholder =>
      'Nachricht… (@ für Erwähnung, / für Befehle)';

  @override
  String get navConversations => 'Bereiche';

  @override
  String get microphonePermissionDenied => 'Mikrofonberechtigung verweigert.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Minuten',
      one: 'vor 1 Minute',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'Modell';

  @override
  String get modified => 'Geändert';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Monaten',
      one: 'vor 1 Monat',
    );
    return '$_temp0';
  }

  @override
  String get moreLabel => 'Mehr';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'Name';

  @override
  String get nameAndTitleRequired => 'Name und Titel sind erforderlich.';

  @override
  String get nameAndUrlRequired => 'Name und URL sind erforderlich';

  @override
  String get nameLabel => 'Name';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'Nativer Sandbox ist auf $platform verfügbar.';
  }

  @override
  String get nativeSandboxNeedsInstall =>
      'Installation für nativen Sandbox erforderlich';

  @override
  String get navObservability => 'Observability';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get navigateLabel => 'Navigieren';

  @override
  String networkBlockCount(int count) {
    return '$count Netzwerkblocke';
  }

  @override
  String get neutral => 'Neutral';

  @override
  String get newCommitsPushed =>
      'Neue Commits wurden gepusht — klicke, um den Diff neu zu laden';

  @override
  String get newFact => 'Neuer Fakt';

  @override
  String get newLabel => 'Neu';

  @override
  String get newPolicy => 'Neue Richtlinie';

  @override
  String get newsfeed => 'Newsfeed';

  @override
  String get newsfeedLabel => 'Newsfeed';

  @override
  String get newsfeedSettingsDescription =>
      'Abonnierte Feeds und Leser-Einstellungen verwalten.';

  @override
  String get newsfeedSettingsTitle => 'Newsfeed-Einstellungen';

  @override
  String get nextMatch => 'Nächste Übereinstimmung (↵)';

  @override
  String get noActiveWorkspace =>
      'Kein aktiver Arbeitsbereich oder Repository ausgewählt.';

  @override
  String get noActiveWorkspaceCreate => 'Kein aktiver Arbeitsbereich';

  @override
  String get noActiveWorkspaceGithub =>
      'Kein aktiver Arbeitsbereich mit einem GitHub-Repository.';

  @override
  String get noAgents => 'Keine Agenten';

  @override
  String get noArticlesYet => 'Noch keine Artikel';

  @override
  String get noArticlesYetBody => 'Die Artikel deiner Feeds erscheinen hier.';

  @override
  String get noExecutionLogsYet => 'Noch keine Ausführungsprotokolle';

  @override
  String get noFacts => 'Noch keine Fakten';

  @override
  String get noFeedsYet => 'Noch keine Feeds';

  @override
  String get noFileAnchor =>
      'Kein Dateianker — Inline-Kommentar kann nicht gesendet werden.';

  @override
  String get noFileChangesInScope => 'Keine Dateiänderungen in diesem Bereich';

  @override
  String get noGifsFound => 'Keine GIFs gefunden';

  @override
  String get noInputDevicesDetected =>
      'Keine Eingabegeräte erkannt — Verwendung des Systemstandards.';

  @override
  String get noMatchingFiles => 'Keine passenden Dateien';

  @override
  String get noMatchingGoogleFonts => 'Keine passenden Google Fonts.';

  @override
  String get noMemoryData => 'Noch keine Speicherdaten';

  @override
  String get noMessagesYet => 'Noch keine Nachrichten';

  @override
  String get noModelsAdvertised =>
      'Keine Modelle von diesem Adapter angekündigt.';

  @override
  String get noOpenPullRequests => 'Keine offenen Pull Requests';

  @override
  String get noPolicies => 'Noch keine Richtlinien';

  @override
  String get noReposInWorkspaceYet =>
      'Noch keine Repositorys in diesem Arbeitsbereich';

  @override
  String get noRunnersDetected =>
      'Noch keine Runner erkannt. Aktualisiere, um erneut zu suchen.';

  @override
  String get noSavedArticles => 'Noch keine gespeicherten Artikel';

  @override
  String get noSavedArticlesBody =>
      'Die Artikel, die du speicherst, erscheinen hier.';

  @override
  String noShortcutsMatch(String query) {
    return 'Keine Kürzel entsprechen \"$query\"';
  }

  @override
  String get noSystemFonts => 'Keine Systemschriften erkannt.';

  @override
  String get noTokenSet => 'Kein Token gesetzt — Zugriff ist uneingeschränkt.';

  @override
  String get noWorkingMemory => 'Noch keine Arbeitsgedächtnisnotizen.';

  @override
  String get noneAllRoles => 'Keine (alle Rollen)';

  @override
  String get notAvailable => 'Nicht verfügbar';

  @override
  String get notConfiguredLabel => 'Nicht konfiguriert.';

  @override
  String get notDetected => 'Nicht erkannt';

  @override
  String get notFoundLabel => 'Nicht gefunden';

  @override
  String get notes => 'Notizen';

  @override
  String get notificationAgentFinished => 'Agent abgeschlossen';

  @override
  String get notificationPrMentioned => 'In Pull Request erwähnt';

  @override
  String get notificationNewMessages => 'Neue Nachrichten';

  @override
  String get notificationPrMerged => 'PR zusammengeführt';

  @override
  String get notificationPrPublished => 'PR veröffentlicht';

  @override
  String get notificationReviewRequested => 'Review angefragt';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get notifyAgentRunCompleted =>
      'Benachrichtigen, wenn ein Agent einen Lauf abschließt.';

  @override
  String get notifyPrMentioned =>
      'Benachrichtigen, wenn du in einem Pull Request erwähnt wirst.';

  @override
  String get notifyNewMessages =>
      'Benachrichtigen bei neuen Agent-Nachrichten in anderen Bereichen.';

  @override
  String get notifyPrMerged =>
      'Benachrichtigen, wenn ein Pull Request zusammengeführt wird.';

  @override
  String get notifyPrPublished =>
      'Benachrichtigen, wenn ein Agent einen Pull Request veröffentlicht.';

  @override
  String get notifyReviewRequested =>
      'Benachrichtigen, wenn dein Review für einen Pull Request angefragt wird.';

  @override
  String get notificationReviewStale => 'Prüfung veraltet';

  @override
  String get notifyReviewStale =>
      'Wenn neue Commits in einen bereits geprüften Pull Request kommen';

  @override
  String get notificationPrMergeReadiness => 'Bereit zum Mergen';

  @override
  String get notifyPrMergeReadiness =>
      'Benachrichtigen, wenn ein von dir erstellter Pull Request mergebar wird oder es nicht mehr ist.';

  @override
  String get notificationPrReviewDecision => 'Review-Entscheidungen';

  @override
  String get notifyPrReviewDecision =>
      'Benachrichtigen, wenn jemand freigibt, Änderungen anfordert oder eine Freigabe verworfen wird.';

  @override
  String get notificationPrChecksStatus => 'Prüfungen';

  @override
  String get notifyPrChecksStatus =>
      'Benachrichtigen, wenn CI bei einem deiner Pull Requests fehlschlägt und wenn sie sich erholt.';

  @override
  String get notificationPrThreadActivity => 'Review-Threads';

  @override
  String get notifyPrThreadActivity =>
      'Benachrichtigen, wenn jemand in einem deiner Threads antwortet oder ihn auflöst.';

  @override
  String get notificationPrReadyToMerge => 'Bereit zum Mergen';

  @override
  String notificationPrReadyToMergeBody(String prTitle) {
    return '$prTitle erfüllt alle Anforderungen.';
  }

  @override
  String get notificationPrMergeBlocked => 'Nicht mehr mergebar';

  @override
  String notificationPrMergeBlockedBodyConflicts(String prTitle) {
    return '$prTitle steht im Konflikt mit dem Basis-Branch.';
  }

  @override
  String notificationPrMergeBlockedBodyBehind(String prTitle) {
    return '$prTitle liegt hinter dem Basis-Branch.';
  }

  @override
  String notificationPrMergeBlockedBodyReviews(String prTitle) {
    return '$prTitle wartet auf eine erforderliche Review.';
  }

  @override
  String notificationPrMergeBlockedBodyChanges(String prTitle) {
    return 'Jemand hat Änderungen an $prTitle angefordert.';
  }

  @override
  String notificationPrMergeBlockedBodyChecks(String prTitle) {
    return 'Prüfungen schlagen bei $prTitle fehl.';
  }

  @override
  String notificationPrMergeBlockedBodyOther(String prTitle) {
    return '$prTitle kann nicht mehr gemergt werden.';
  }

  @override
  String get notificationPrApproved => 'Pull Request freigegeben';

  @override
  String notificationPrApprovedBodyBy(String login, String prTitle) {
    return '$login hat $prTitle freigegeben';
  }

  @override
  String notificationPrApprovedBody(String prTitle) {
    return '$prTitle wurde freigegeben';
  }

  @override
  String notificationPrReviewersRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Reviewer stehen noch aus',
      one: '1 Reviewer steht noch aus',
      zero: 'keine Reviewer mehr offen',
    );
    return '$_temp0';
  }

  @override
  String get notificationPrChangesRequested => 'Änderungen angefordert';

  @override
  String notificationPrChangesRequestedBodyBy(String login, String prTitle) {
    return '$login hat Änderungen an $prTitle angefordert';
  }

  @override
  String notificationPrChangesRequestedBody(String prTitle) {
    return 'Für $prTitle wurden Änderungen angefordert';
  }

  @override
  String get notificationPrReviewDismissed => 'Freigabe verworfen';

  @override
  String notificationPrReviewDismissedBody(String prTitle) {
    return '$prTitle braucht wieder eine Review.';
  }

  @override
  String get notificationPrChecksFailed => 'Prüfungen fehlgeschlagen';

  @override
  String notificationPrChecksFailedBody(String checkName, String prTitle) {
    return '$checkName ist bei $prTitle fehlgeschlagen';
  }

  @override
  String notificationPrChecksFailedBodyUnnamed(String prTitle) {
    return 'Prüfungen schlagen bei $prTitle fehl';
  }

  @override
  String get notificationPrChecksRecovered => 'Prüfungen bestanden';

  @override
  String notificationPrChecksRecoveredBody(String prTitle) {
    return '$prTitle ist wieder grün.';
  }

  @override
  String notificationPrMentionedInCommentBody(String login, String location) {
    return '$login hat dich in $location erwähnt';
  }

  @override
  String get notificationPrThreadReplied => 'Neue Antwort';

  @override
  String notificationPrThreadRepliedBody(String login, String location) {
    return '$login hat in $location geantwortet';
  }

  @override
  String get notificationPrThreadResolved => 'Thread aufgelöst';

  @override
  String notificationPrThreadResolvedBody(String location) {
    return 'Dein Thread in $location wurde aufgelöst.';
  }

  @override
  String get notificationGroupAgents => 'Agenten';

  @override
  String get notificationGroupPullRequests => 'Pull Requests';

  @override
  String get notificationGroupMessages => 'Nachrichten';

  @override
  String get notificationGroupTickets => 'Tickets';

  @override
  String get notificationGroupCalendar => 'Kalender';

  @override
  String get notificationGroupMachines => 'Maschinen';

  @override
  String get notificationsMutedRepos => 'Stummgeschaltete Repositories';

  @override
  String notificationsMutedReposCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Repositories stummgeschaltet',
      one: '1 Repository stummgeschaltet',
      zero: 'Keine Repositories stummgeschaltet',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMuteRepo => 'Dieses Repository stummschalten';

  @override
  String get notificationsUnmuteRepo => 'Stummschaltung aufheben';

  @override
  String get onboardingLinuxDescription =>
      'Control Center kann Linux-Container nutzen, um die Ausführung von Agenten zu isolieren.';

  @override
  String get onboardingMacosDescription =>
      'Control Center nutzt den nativen Sandbox auf macOS, um die Ausführung von Agenten zu isolieren.';

  @override
  String get onboardingUnsupportedDescription =>
      'Sandbox ist auf dieser Plattform nicht verfügbar. Die Ausführung von Agenten erfolgt ohne Isolierung.';

  @override
  String get openApplicationSettings => 'Anwendungseinstellungen öffnen';

  @override
  String get openArticlesInApp => 'Artikel in der App öffnen';

  @override
  String get openInBrowser => 'Im Browser öffnen';

  @override
  String get openLabel => 'Offen';

  @override
  String get openOnGithub => 'Auf GitHub öffnen';

  @override
  String get openStatus => 'Offen';

  @override
  String get optionalPersonaDescription => 'Optionale Persona-Beschreibung';

  @override
  String get otherLabel => 'Sonstige';

  @override
  String get ownerOrganization => 'Besitzer / Organisation';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get passed => 'Bestanden';

  @override
  String get pasteValueHere => 'Wert hier einfügen';

  @override
  String get persona => 'Persona';

  @override
  String get policies => 'Richtlinien';

  @override
  String get policiesHint =>
      'Richtlinien erscheinen hier, sobald Agenten Fakten befördern.';

  @override
  String get policy => 'Richtlinie';

  @override
  String get popular => 'Beliebt';

  @override
  String get port => 'Port';

  @override
  String get postingEllipsis => 'Veröffentlichen…';

  @override
  String get prCommits => 'Commits';

  @override
  String get prMergedBody => 'Ein Pull Request wurde zusammengeführt';

  @override
  String get prMoreActions => 'More actions';

  @override
  String get prTitle => 'PR-Titel';

  @override
  String get reviewCommentHint =>
      'Klicke einfach auf Genehmigen oder füge, wenn dir danach ist, einen Kommentar oder eine Reaktion hinzu…';

  @override
  String get nothingToPreview => 'Nichts zum Vorschauen';

  @override
  String get previousMatch => 'Vorherige Übereinstimmung (⇧↵)';

  @override
  String get priorityReviewsDescription =>
      'Prioritäts-Reviews und Repository-Übersicht.';

  @override
  String get prsCreated => 'PRs erstellt';

  @override
  String get prsMerged => 'PRs zusammengeführt';

  @override
  String get publishToGithub => 'Auf GitHub veröffentlichen';

  @override
  String get published => 'Veröffentlicht';

  @override
  String get pullRequestApproved => 'Pull Request genehmigt';

  @override
  String get pullRequests => 'Pull Requests';

  @override
  String get questionLabel => 'FRAGE';

  @override
  String get queued => 'In Warteschlange';

  @override
  String get react => 'Reagieren';

  @override
  String get readPrsIssuesMetadata =>
      'Erlaubt dem Agenten, PRs, Issues und Repository-Metadaten zu lesen.';

  @override
  String get readerPreferences => 'Leser-Einstellungen';

  @override
  String get reasoningEffort => 'Reasoning-Aufwand';

  @override
  String get recommendLabel => 'EMPFEHLUNG';

  @override
  String recordingFromDevice(String device) {
    return 'Aufnahme von $device.';
  }

  @override
  String get redownload => 'Erneut herunterladen';

  @override
  String get redownloadEmbeddingModel =>
      'Embedding-Modell erneut herunterladen?';

  @override
  String get redownloadVoiceModel => 'Sprachmodell erneut herunterladen?';

  @override
  String get refinePlan => 'Plan verfeinern';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get refreshAll => 'Alle aktualisieren';

  @override
  String get refreshAllFeeds => 'Alle Feeds aktualisieren';

  @override
  String get reject => 'Ablehnen';

  @override
  String get rejected => 'Abgelehnt';

  @override
  String get reload => 'Neu laden';

  @override
  String get remove => 'Entfernen';

  @override
  String get removeBookmark => 'Lesezeichen entfernen';

  @override
  String get removeEmbeddingModel => 'Embedding-Modell entfernen?';

  @override
  String get removeLogo => 'Logo entfernen';

  @override
  String get removeRepoFromWorkspace =>
      'Repository aus dem Arbeitsbereich entfernen?';

  @override
  String get removeVoiceModel => 'Sprachmodell entfernen?';

  @override
  String get removed => 'Entfernt';

  @override
  String get renamed => 'Umbenannt';

  @override
  String get reopen => 'Wieder öffnen';

  @override
  String get resolve => 'Lösen';

  @override
  String get replyEllipsis => 'Antworten…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$name wird aus diesem Arbeitsbereich entfernt. Die lokalen Dateien auf der Festplatte bleiben unberührt.';
  }

  @override
  String repoAccessNoticeBody(String repos) {
    return 'Die GitHub-Anmeldedaten des Servers können $repos nicht sehen. Wenn ein Repository zu einer Organisation gehört, installiere dort die GitHub App oder verbinde ein Token mit Zugriff.';
  }

  @override
  String repoAccessNoticeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Auf $count Repositories kann nicht zugegriffen werden',
      one: 'Auf ein Repository kann nicht zugegriffen werden',
    );
    return '$_temp0';
  }

  @override
  String get repoNoAccessBadge => 'Kein Zugriff';

  @override
  String get reportsTo => 'Berichtet an';

  @override
  String reposCount(int count) {
    return 'Repositorys ($count)';
  }

  @override
  String get reposDescription =>
      'Die lokalen Checkouts, die dieser Arbeitsbereich verwendet.';

  @override
  String get repositories => 'Repositorys';

  @override
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Repositorys',
      one: '1 Repository',
    );
    return '$_temp0 konnten nicht hinzugefügt werden: $error';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Repositorys hinzugefügt',
      one: 'Repository hinzugefügt',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => 'Repository-Einstellungen';

  @override
  String get repositoryName => 'Repository-Name';

  @override
  String get requestChanges => 'Änderungen anfordern';

  @override
  String get requested => 'Angefordert';

  @override
  String get requestedChanges => 'Änderungen angefordert';

  @override
  String requiredRoleLabel(String role) {
    return 'Erforderliche Rolle: $role';
  }

  @override
  String get requiredRoleOptional => 'Erforderliche Rolle (optional)';

  @override
  String get requirements => 'Anforderungen';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get resolved => 'Gelöst';

  @override
  String get enclosedTerminalTitle => 'Isoliertes Terminal';

  @override
  String get enclosedTerminalStart => 'Shell öffnen';

  @override
  String get enclosedTerminalStartHint =>
      'Diese Shell läuft in der Wegwerf-VM dieser Unterhaltung. Sie startet, wenn du sie öffnest, nicht beim Start der App.';

  @override
  String get terminalStreamReconnecting =>
      'Stream unterbrochen — Neuverbindung…';

  @override
  String get terminalStreamError => 'Stream-Fehler:';

  @override
  String get terminalShellExited => 'Shell beendet';

  @override
  String get restartShell => 'Shell neu starten';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get review => 'Review';

  @override
  String get reviewedByMe => 'Von mir reviewed';

  @override
  String get reviewers => 'REVIEWER';

  @override
  String get roleLabel => 'Rolle';

  @override
  String get ruleHint => 'Die Regel der Richtlinie (Markdown wird unterstützt)';

  @override
  String get ruleLabel => 'Regel';

  @override
  String get runCompleted => 'Ausführung abgeschlossen';

  @override
  String get running => 'Läuft';

  @override
  String get runningLabel => 'läuft';

  @override
  String get runs => 'Läufe';

  @override
  String get runsLabel => 'Ausführungen';

  @override
  String get sandboxBackendNativeLabel => 'Native sandbox';

  @override
  String get sandboxBackendMicrovmLabel => 'Gekapselte VM';

  @override
  String get sandboxBackendNoneLabel => 'No isolation';

  @override
  String get sandboxLinuxInstall =>
      'Nativer Sandbox auf Linux/WSL2 verwendet bubblewrap. Installiere mit:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'Nativer Sandbox ist in macOS integriert — verwendet Apple Seatbelt (`sandbox-exec`). Keine Installation erforderlich.';

  @override
  String get sandboxPermissions => 'Sandbox-Berechtigungen';

  @override
  String get sandboxUnsupported =>
      'Nativer Sandbox wird auf dieser Plattform noch nicht unterstützt. Fällt zurück auf \"Keine Isolierung\".';

  @override
  String get sandboxingDisabledDescription =>
      'Agenten werden direkt auf dem Host mit vollem Env ausgeführt — nicht empfohlen.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'Alle Agentenaufrufe werden über $backend geleitet.';
  }

  @override
  String get save => 'Speichern';

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get adapterArguments => 'Zusätzliche Argumente';

  @override
  String get adapterArgumentsHint => 'Zusätzliche CLI-Flags (z. B. --yolo)';

  @override
  String get addVariable => 'Variable hinzufügen';

  @override
  String get environmentVariables => 'Umgebungsvariablen';

  @override
  String get environmentVariablesDescription =>
      'Benutzerdefinierte Umgebungsvariablen für diesen Adapter (z. B. API-Schlüssel). Im Schlüsselbund gespeichert.';

  @override
  String get variableKey => 'Schlüssel';

  @override
  String get variableValue => 'Wert';

  @override
  String get savingChanges => 'Änderungen werden gespeichert…';

  @override
  String get savingEllipsis => 'Speichern…';

  @override
  String get scopeDiffToCommits =>
      'Diff auf Commits einschränken — Umschalt+Klick für Bereich';

  @override
  String get noPrsMatchSearch => 'Keine passenden Pull Requests';

  @override
  String get noPrsMatchSearchHint =>
      'Keine offenen PRs entsprechen deiner Suche. Andere Begriffe versuchen oder Suche löschen.';

  @override
  String get searchFactsHint => 'Fakten suchen...';

  @override
  String get searchFonts => 'Schriften suchen…';

  @override
  String get searchGifs => 'GIFs suchen';

  @override
  String get searchGifsHint => 'GIFs suchen...';

  @override
  String get searchInDiffHint => 'Im Diff suchen…';

  @override
  String get searchOrTypeModel => 'Suchen oder Modellnamen eingeben…';

  @override
  String get searchPlaceholder => 'Suchen…';

  @override
  String get searchShortcuts => 'Kürzel suchen…';

  @override
  String get shortcutUnavailableInBrowser => 'Im Browser nicht verfügbar';

  @override
  String get searching => 'Suchen…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Sekunden',
      one: 'vor 1 Sekunde',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'Adapter auswählen';

  @override
  String get selectAdapterFirst => 'Zuerst einen Adapter auswählen';

  @override
  String get selectAgentToReportTo => 'Agent für Berichterstattung auswählen…';

  @override
  String get selectAnAgent => 'Agenten auswählen';

  @override
  String get selectConversation => 'Konversation auswählen';

  @override
  String get selectEffortLevel => 'Aufwandsstufe auswählen';

  @override
  String get selectLabel => 'Auswählen';

  @override
  String get selectRunner => 'Runner auswählen';

  @override
  String get semanticSearch => 'Semantische Suche';

  @override
  String get send => 'Senden';

  @override
  String get sendFirstMessage => 'Sende die erste Nachricht';

  @override
  String get sendMessage => 'Nachricht senden';

  @override
  String sentFindingsToAgent(int count) {
    return '$count Ergebnis(se) an Agent gesendet.';
  }

  @override
  String setGithubLinkDescription(String name) {
    return 'Setze den GitHub-Besitzer und Repository-Namen für $name. Dies wird verwendet, um PR- und Issue-Referenzen wie #123 in Markdown-Inhalten aufzulösen.';
  }

  @override
  String get setLabel => 'Setzen';

  @override
  String get setToken => 'Token setzen';

  @override
  String get settingsLabel => 'Einstellungen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageDescription => 'Wähle die App-Sprache.';

  @override
  String get shortTask => 'Kurze Aufgabe';

  @override
  String get showNativeNotifications =>
      'Native macOS-Benachrichtigungen für Ereignisse anzeigen.';

  @override
  String get showSuperseded => 'Ersetzte anzeigen';

  @override
  String get signedIn => 'Angemeldet.';

  @override
  String signedInAs(String username) {
    return 'Angemeldet als $username.';
  }

  @override
  String get skillEditor => 'Fähigkeiten-Editor';

  @override
  String get skillNameRequired => 'Fähigkeitsname ist erforderlich.';

  @override
  String skillSaved(String name) {
    return 'Fähigkeit \"$name\" gespeichert.';
  }

  @override
  String get skillsSourcesTab => 'Quellen';

  @override
  String get skillSourcesDisclaimer =>
      'Skills werden aus von dir hinzugefügten GitHub-Repositories installiert. Repository-Metadaten sind nicht vertrauenswürdig — der Antivirus-Scan ist das echte Sicherheitssignal.';

  @override
  String get skillSourcesEmpty => 'Keine Skill-Repositories';

  @override
  String get skillSourcesEmptyHint =>
      'Füge ein GitHub-Repository hinzu, um seine Skills zu durchsuchen.';

  @override
  String get skillSourceAdd => 'Repository hinzufügen';

  @override
  String get skillSourceAddTitle => 'Skill-Repository hinzufügen';

  @override
  String get skillSourceAddHint => 'https://github.com/owner/repo';

  @override
  String get skillSourceInvalidUrl =>
      'Gib eine GitHub-Repository-URL ein (https://github.com/owner/repo).';

  @override
  String skillSourceAdded(String repo) {
    return 'Repository $repo hinzugefügt.';
  }

  @override
  String skillSourceAlreadyAdded(String repo) {
    return 'Repository $repo ist bereits hinzugefügt.';
  }

  @override
  String skillSourceRemoved(String repo) {
    return 'Repository $repo entfernt.';
  }

  @override
  String get skillSourceRemove => 'Entfernen';

  @override
  String skillSourceRemoveConfirmTitle(String repo) {
    return '$repo entfernen?';
  }

  @override
  String get skillSourceRemoveConfirmBody =>
      'Installierte Skills bleiben installiert. Nur der Repository-Katalog wird entfernt.';

  @override
  String get skillSourceNoSkills =>
      'Keine Skills in diesem Repository gefunden (ein Skill ist ein Verzeichnis mit einer SKILL.md).';

  @override
  String get skillSourceRefresh => 'Aktualisieren';

  @override
  String get skillSourceInstalledBadge => 'Installiert';

  @override
  String get skillSourceUpdateBadge => 'Update verfügbar';

  @override
  String get skillSourceSlugTaken => 'Name vergeben';

  @override
  String skillSourceFilesCount(num count) {
    return '$count Dateien';
  }

  @override
  String get skillSourceReadme => 'README';

  @override
  String get skillSourceNoReadme => 'Dieser Skill hat kein README.';

  @override
  String get skillSourceNoMatches => 'Keine Skills entsprechen deinem Filter.';

  @override
  String get skillUpdateAction => 'Aktualisieren';

  @override
  String get skillUninstallAction => 'Deinstallieren';

  @override
  String skillUninstallConfirmTitle(String slug) {
    return '\"$slug\" deinstallieren?';
  }

  @override
  String skillUninstalled(String slug) {
    return 'Skill \"$slug\" deinstalliert.';
  }

  @override
  String get skillFindingLine => 'Zeile';

  @override
  String get skillInstallAnywayOverride =>
      'Ich akzeptiere das Risiko — trotzdem installieren';

  @override
  String skillInstalled(String slug) {
    return 'Fähigkeit \"$slug\" installiert.';
  }

  @override
  String get skillPreviewCapabilities => 'Fähigkeiten';

  @override
  String get skillPreviewFindings => 'Ergebnisse';

  @override
  String get skillPreviewGuardedActions => 'Geschützte Aktionen';

  @override
  String get skillPreviewLlmReviewed => 'LLM-geprüft';

  @override
  String get skillPreviewNoCapabilities => 'Keine Fähigkeiten deklariert.';

  @override
  String get skillPreviewNoFindings => 'Keine Ergebnisse.';

  @override
  String get skillPreviewScanning => 'Fähigkeit wird gescannt…';

  @override
  String get skillPreviewVerdictLabel => 'Scan-Urteil';

  @override
  String get skillPreviewVerdictPass => 'Bestanden';

  @override
  String get skillPreviewVerdictQuarantine => 'Unter Quarantäne';

  @override
  String get skillPreviewVerdictWarn => 'Warnung';

  @override
  String get skillQuarantineWarning =>
      'Diese Fähigkeit wurde vom Scanner unter Quarantäne gestellt. Die Installation führt Code auf deinem Rechner aus. Fahre nur fort, wenn du der Quelle vertraust und die Ergebnisse geprüft hast.';

  @override
  String skillDetachedFromAgents(String agents) {
    return 'Unter Quarantäne gestellt und von Agenten getrennt: $agents';
  }

  @override
  String get skillNotScanned => 'Nicht gescannt';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => 'Manuell';

  @override
  String get skillOriginRegistry => 'Registry';

  @override
  String get skillOriginRuntimeLocal => 'Lokale Laufzeit';

  @override
  String get skillRulesStale => 'Scan veraltet';

  @override
  String get skillSaveAnywayOverride =>
      'Ich kenne das Risiko — trotzdem speichern';

  @override
  String get skillSaveBlockedBody =>
      'Der Inhalt wurde blockiert, bevor etwas geschrieben wurde.';

  @override
  String get skillSaveBlockedTitle => 'Speichern durch den Scan blockiert';

  @override
  String get skillScanAction => 'Scannen';

  @override
  String get skillScanAll => 'Alle scannen';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass bestanden · $warn Warnungen · $quarantine unter Quarantäne';
  }

  @override
  String get skillStateDrifted => 'Seit der Installation geändert';

  @override
  String get skillStateUnmanaged => 'Nicht verwaltet';

  @override
  String get skillSeverityBlocked => 'Blockiert';

  @override
  String get skillSeverityWarn => 'Warnung';

  @override
  String get skillsInstalledTab => 'Installiert';

  @override
  String get skills => 'Fähigkeiten';

  @override
  String get skipAcceptRisk => 'Überspringen — Ich akzeptiere das Risiko';

  @override
  String get skipForNow => 'Vorerst überspringen';

  @override
  String get skipSandboxing => 'Sandboxing überspringen';

  @override
  String get skipSandboxingDialogContent =>
      'Bist du sicher, dass du das Sandboxing überspringen möchtest? Dies erlaubt Agenten, Code auf deinem System ohne Isolierung auszuführen.';

  @override
  String get somethingWentWrong => 'Etwas ist schiefgelaufen';

  @override
  String sourceCount(int count) {
    return '$count Quelle';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count Quellen';
  }

  @override
  String get sourceFacts => 'Quellfakten:';

  @override
  String get splitDiff => 'Diff nebeneinander';

  @override
  String get startLabel => 'Starten';

  @override
  String get startOnAppLaunch => 'Beim App-Start starten';

  @override
  String get statusLabel => 'Status';

  @override
  String get onboardingStepConnect => 'Verbinden';

  @override
  String get onboardingStepWorkspace => 'Workspace';

  @override
  String get onboardingStepSandbox => 'Sandbox';

  @override
  String get onboardingStepAdapter => 'Adapter';

  @override
  String get onboardingStepVoice => 'Stimme';

  @override
  String get stop => 'Stoppen';

  @override
  String get stopped => 'Gestoppt';

  @override
  String get strictIdentityCheck => 'Strenge Identitätsprüfung';

  @override
  String get success => 'Erfolg';

  @override
  String get successLabel => 'Erfolg';

  @override
  String get suggestAChange => 'Änderung vorschlagen';

  @override
  String get suggestLabel => 'VORSCHLAG';

  @override
  String get superseded => 'Ersetzt';

  @override
  String get synced => 'Synchronisiert';

  @override
  String get systemDefault => 'Systemstandard';

  @override
  String get systemFonts => 'Systemschriften';

  @override
  String get systemPrompt => 'System-Prompt';

  @override
  String get systemPromptLabel => 'System-Prompt';

  @override
  String get talkToControlCenter => 'Sprich mit Control Center.';

  @override
  String get taskMentionSection => 'Aufgabe';

  @override
  String get testLabel => 'Testen';

  @override
  String get theme => 'Thema';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeSystem => 'System';

  @override
  String get thisCannotBeUndone => 'Dies kann nicht rückgängig gemacht werden.';

  @override
  String get ticketLabel => 'TICKET';

  @override
  String get titleLabel => 'Titel';

  @override
  String get todayLabel => 'Heute';

  @override
  String get toggleTheme => 'Thema umschalten';

  @override
  String get tokenConfigured =>
      'Konfiguriert — Clients müssen diesen Token vorweisen.';

  @override
  String get topic => 'Thema';

  @override
  String get topicHint => 'z.B. Tech Stack, Design System';

  @override
  String get totalRuns => 'Läufe gesamt';

  @override
  String trackingParamsCount(int count) {
    return '$count Tracking-Parameter';
  }

  @override
  String get typeCommandOrSearch => 'Befehl eingeben oder suchen…';

  @override
  String get typography => 'Typografie';

  @override
  String get unavailable => 'Nicht verfügbar';

  @override
  String get unifiedDiff => 'Vereinigter Diff';

  @override
  String get unknownAuthor => 'Unbekannt';

  @override
  String get unnamedAgent => 'Unbenannter Agent';

  @override
  String get updateKey => 'Schlüssel aktualisieren';

  @override
  String get updateLabel => 'Aktualisieren';

  @override
  String get updateToken => 'Token aktualisieren';

  @override
  String updatedDaysAgo(int count) {
    return 'Vor $count Tagen aktualisiert';
  }

  @override
  String updatedHoursAgo(int count) {
    return 'Vor $count Stunden aktualisiert';
  }

  @override
  String get updatedJustNow => 'Gerade aktualisiert';

  @override
  String updatedMinutesAgo(int count) {
    return 'Vor $count Minuten aktualisiert';
  }

  @override
  String get useSandbox => 'Sandbox verwenden';

  @override
  String get useWorkspaceDefault => 'Arbeitsbereichsstandard verwenden';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      'Leer lassen, um den Standard-User-Agent der App zu verwenden. Einige Seiten blockieren Nicht-Browser-User-Agents.';

  @override
  String get usingSystemDefaultMicrophone =>
      'Verwendung des Standardmikrofons des Systems.';

  @override
  String get viewLabel => 'Ansicht';

  @override
  String get viewLogs => 'Logs anzeigen';

  @override
  String voiceInstallFailed(String error) {
    return 'Installation fehlgeschlagen: $error';
  }

  @override
  String get voiceModelNotInstalled =>
      'Nicht installiert. Lädt ca. 200 MB einmal herunter; läuft vollständig auf dem Gerät.';

  @override
  String get voiceModelNotInstalledLabel => 'Sprachmodell nicht installiert.';

  @override
  String get voiceRedownloadBody =>
      'Die vorhandenen Modelldateien werden gelöscht und das ca. 200 MB große Archiv erneut heruntergeladen. Die Sprachtranskription steht bis zum Abschluss des Downloads nicht zur Verfügung.';

  @override
  String get voiceRemoveBody =>
      'Die Sprachtranskription wird deaktiviert, bis du sie erneut installierst. Du kannst sie jederzeit erneut installieren.';

  @override
  String get voiceTranscription => 'Sprachtranskription';

  @override
  String get weakIsolationDescription =>
      'Schwache Isolierung — nur Namespace-Grenze, keine Kernel-Grenze.';

  @override
  String get whenOffNoDefaultRoute =>
      'Wenn deaktiviert, startet die Sandbox ohne Standardroute.';

  @override
  String get whenOffServerStaysStopped =>
      'Wenn deaktiviert, bleibt der Server gestoppt, bis du ihn startest.';

  @override
  String get speechModel => 'Sprachmodell';

  @override
  String get speechModelHint =>
      'Wird für Besprechungstranskription und das Composer-Mikrofon verwendet.';

  @override
  String get voiceModelInstalled =>
      'Installiert. Versorgt Besprechungstranskription und den Mikrofon-Button im Composer.';

  @override
  String get meetingMicSilentWarning =>
      'Dein Mikrofon ist möglicherweise stummgeschaltet — die anderen sprechen, aber es kommt nichts an.';

  @override
  String get meetingSummaryPrivacyNotice =>
      'Aufnahme und Transkription bleiben auf diesem Gerät. Die Zusammenfassung schreibt ein Agent – nutzt er ein Cloud-Modell, werden Transkript und Notizen an diesen Anbieter gesendet.';

  @override
  String get meetingTemplates => 'Vorlagen für Besprechungsnotizen';

  @override
  String get meetingTemplatesHint =>
      'Passe die KI-Zusammenfassung an eine Besprechungsart an. Die aktive Vorlage gilt für neue und erneut erstellte Zusammenfassungen.';

  @override
  String get meetingTemplateActive => 'Aktive Vorlage';

  @override
  String get meetingTemplateAdd => 'Vorlage hinzufügen';

  @override
  String get meetingTemplateNewTitle => 'Neue Vorlage';

  @override
  String get meetingTemplateEditTitle => 'Vorlage bearbeiten';

  @override
  String get meetingTemplateNameLabel => 'Name';

  @override
  String get meetingTemplateNameHint => 'z. B. Sprint-Review';

  @override
  String get meetingTemplateInstructionsLabel => 'Anweisungen';

  @override
  String get meetingTemplateInstructionsHint =>
      'Wie soll die KI diese Notizen strukturieren und gewichten?';

  @override
  String get workingMemory => 'Arbeitsspeicher';

  @override
  String get workspaceName => 'Name des Arbeitsbereichs';

  @override
  String get workspaceScopedSkills =>
      'Arbeitsbereich-bezogene Fähigkeitsdateien, die Agenten zugeordnet sind.';

  @override
  String get workspaces => 'Arbeitsbereiche';

  @override
  String get writePrivateNotes =>
      'Private Notizen, Beobachtungen, Pläne schreiben...';

  @override
  String get writeSkillContent =>
      'Schreibe deinen Fähigkeitsinhalt hier (Markdown)…';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Jahren',
      one: 'vor 1 Jahr',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'gestern';

  @override
  String get focusModeStart => 'Fokus-Sitzung starten';

  @override
  String get focusModeConfigTitle => 'Fokus-Sitzung starten';

  @override
  String get focusModeGoalLabel => 'Ziel';

  @override
  String get focusModeGoalHint => 'Woran arbeitest du?';

  @override
  String get focusModeDurationLabel => 'Dauer';

  @override
  String get focusModeBlockNotifications => 'Benachrichtigungen blockieren';

  @override
  String get focusModeStartButton => 'Starten';

  @override
  String get focusModeFloat => 'In Leiste minimieren';

  @override
  String get focusModeActiveTooltip => 'Fokus-Modus aktiv — zum Beenden tippen';

  @override
  String get dismiss => 'Ablehnen';

  @override
  String get acceptAndResolve => 'Übernehmen und auflösen';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'Es sieht so aus, als ob du viele Reviews hintereinander machst. Mach eine Pause!';
  }

  @override
  String get notificationSound => 'Benachrichtigungston';

  @override
  String get notificationSoundDescription =>
      'Ton, der abgespielt wird, wenn eine Benachrichtigung angezeigt wird.';

  @override
  String get notificationSoundNone => 'Keiner';

  @override
  String get notificationSoundPing => 'Ping';

  @override
  String get notificationSoundChime => 'Chime';

  @override
  String get notificationSoundPop => 'Pop';

  @override
  String get notificationSoundDing => 'Ding';

  @override
  String get notificationSoundWhoosh => 'Whoosh';

  @override
  String get notificationSoundMigrosSoft => 'Migros (soft)';

  @override
  String get notificationSoundMigrosHard => 'Migros (hard)';

  @override
  String get notificationSoundSbb => 'SBB';

  @override
  String get notificationSoundCff => 'CFF';

  @override
  String get notificationSoundFfs => 'FFS';

  @override
  String get notificationSoundPost => 'Post';

  @override
  String get notificationSoundTest => 'Testen';

  @override
  String get notificationVolume => 'Lautstärke';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'Keine PRs von @$login in diesem Arbeitsbereich';
  }

  @override
  String get usersLabel => 'Benutzer';

  @override
  String get mergePullRequest => 'Merge pull request';

  @override
  String get forceMergePullRequest => 'Force merge pull request';

  @override
  String get closePullRequest => 'Close pull request';

  @override
  String get closePullRequestConfirm =>
      'Are you sure you want to close this pull request?';

  @override
  String get stackedPullRequests => 'Gestapelte Pull Requests';

  @override
  String partOfStack(int position, int total) {
    return 'Teil eines Stacks ($position von $total)';
  }

  @override
  String get createStack => 'Stack erstellen';

  @override
  String get createStackDialogTitle => 'Pull-Request-Stack erstellen';

  @override
  String createStackDialogBody(int count) {
    return 'Diese $count Pull Requests werden gestapelt, von unten nach oben:';
  }

  @override
  String get createStackInvalidSelection =>
      'Wähle mindestens zwei Pull Requests desselben Repositorys aus, um einen Stack zu erstellen';

  @override
  String get createStackNotAChain =>
      'Die ausgewählten Pull Requests bilden keine Kette: der Basis-Branch jedes PR muss der Head-Branch des vorherigen sein';

  @override
  String get createStackAlreadyStacked =>
      'Mindestens ein ausgewählter Pull Request ist bereits in einem Stack';

  @override
  String get stackCreated => 'Stack erstellt';

  @override
  String get stackCreationFailed => 'Der Stack konnte nicht erstellt werden';

  @override
  String get squashAndMerge => 'Squash and merge';

  @override
  String get createMergeCommit => 'Create a merge commit';

  @override
  String get rebaseAndMerge => 'Rebase and merge';

  @override
  String get commitTitle => 'Commit title';

  @override
  String get commitDescription => 'Commit description';

  @override
  String get pullRequestMerged => 'Pull request merged';

  @override
  String get pullRequestClosed => 'Pull request closed';

  @override
  String failedToMergePr(String error) {
    return 'Failed to merge: $error';
  }

  @override
  String failedToClosePr(String error) {
    return 'Failed to close: $error';
  }

  @override
  String get markReadyForReview => 'Bereit zur Überprüfung';

  @override
  String get markReadyForReviewConfirm =>
      'Dieser Pull Request verlässt den Entwurfsstatus. Prüfer werden benachrichtigt, erforderliche Checks steuern ab jetzt das Mergen und jede Automatisierung, die auf fertige Pull Requests wartet, läuft an.';

  @override
  String get convertToDraft => 'In Entwurf umwandeln';

  @override
  String get convertToDraftConfirm =>
      'Dieser Pull Request wird wieder zum Entwurf. Seine ausstehenden Überprüfungsanfragen werden verworfen und er kann nicht zusammengeführt werden, bis du ihn erneut als bereit markierst.';

  @override
  String get pullRequestMarkedReady =>
      'Pull Request als bereit zur Überprüfung markiert';

  @override
  String get pullRequestConvertedToDraft =>
      'Pull Request in Entwurf umgewandelt';

  @override
  String failedToMarkPrReady(String error) {
    return 'Markieren als bereit zur Überprüfung fehlgeschlagen: $error';
  }

  @override
  String failedToConvertPrToDraft(String error) {
    return 'Umwandeln in Entwurf fehlgeschlagen: $error';
  }

  @override
  String get checksFailing => 'Prüfungen fehlgeschlagen';

  @override
  String get reviewsPending => 'Some reviews are pending';

  @override
  String get mergeConflictsWithBase =>
      'Dieser Branch hat Konflikte, die gelöst werden müssen';

  @override
  String get branchOutOfDateWithBase =>
      'Dieser Branch ist nicht auf dem Stand des Basis-Branch';

  @override
  String get mergeBlockedByBranchProtection =>
      'Der Branch-Schutz blockiert diesen Merge';

  @override
  String get confirm => 'Confirm';

  @override
  String get trustedSitesSectionTitle => 'Vertrauenswürdige Sites';

  @override
  String get trustedSitesEmpty =>
      'Keine vertrauenswürdigen Sites. Fügen Sie eine Domain hinzu, um die Blockierung dort zu deaktivieren.';

  @override
  String get addTrustedSite => 'Vertrauenswürdige Site hinzufügen';

  @override
  String get removeTrustedSite => 'Entfernen';

  @override
  String get disableBlockingForThisSite =>
      'Blockierung auf dieser Site deaktivieren';

  @override
  String get enableBlockingForThisSite =>
      'Blockierung auf dieser Site aktivieren';

  @override
  String get enterDomainHint => 'z. B. beispiel.com';

  @override
  String get invalidDomain =>
      'Geben Sie eine gültige Domain ein (z. B. beispiel.com)';

  @override
  String get pageLoadTimedOut =>
      'Seitenladezeit überschritten. Neu laden oder im Browser öffnen.';

  @override
  String get pipelinesScreenTitle => 'Pipelines';

  @override
  String get pipelinesScreenSubtitle =>
      'Declarative multi-step agent workflows';

  @override
  String get pipelinesRunPipeline => 'Pipeline ausführen';

  @override
  String get pipelineRunLauncherTitle => 'Pipeline ausführen';

  @override
  String get pipelineRunSubtitle =>
      'Wähle eine Pipeline und fülle ihre Eingaben aus, um eine Ausführung zu starten.';

  @override
  String get pipelineRunNoInputsBadge => 'Keine Eingaben';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Eingaben',
      one: '1 Eingabe',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'Diese Pipeline benötigt keine Eingaben.';

  @override
  String get pipelineRunSubmit => 'Pipeline ausführen';

  @override
  String get pipelineRunCouldNotStart =>
      'Ausführung konnte nicht gestartet werden.';

  @override
  String pipelineRunStarted(String name) {
    return '$name gestartet';
  }

  @override
  String get pipelineRunEmptyTitle => 'Keine Pipelines zum Ausführen bereit';

  @override
  String get pipelineRunEmptyHint =>
      'Aktiviere eine Pipeline und schalte die manuelle Ausführung in ihrem Editor ein, um sie hier zu starten.';

  @override
  String get pipelineRunManageTemplates => 'Pipelines verwalten';

  @override
  String get pipelineRunSettingsTitle => 'Manuelle Ausführung';

  @override
  String get pipelineRunSettingsAllow => 'Manuelle Ausführung zulassen';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'Diese Pipeline auf der Ausführungsseite anzeigen, damit sie manuell gestartet werden kann.';

  @override
  String get pipelineRunSettingsConcurrencyTitle => 'Parallelität';

  @override
  String get pipelineRunSettingsMaxParallel => 'Max. parallele Läufe';

  @override
  String get pipelineRunSettingsMaxParallelHelp =>
      'Leer lassen für unbegrenzt. Weitere Läufe warten in einer Warteschlange und starten, sobald ein Platz frei wird.';

  @override
  String get pipelineRunSettingsMaxParallelHint => 'Unbegrenzt';

  @override
  String get pipelineRunSettingsMaxParallelInvalid =>
      'Geben Sie eine ganze Zahl ab 1 ein oder lassen Sie das Feld für unbegrenzt leer.';

  @override
  String get pipelineRunSettingsInputsTitle => 'Eingaben';

  @override
  String get pipelineRunSettingsAddInput => 'Eingabe hinzufügen';

  @override
  String get pipelineRunSettingsNoInputs => 'Noch keine Eingaben.';

  @override
  String get pipelineInputEditTitle => 'Eingabefeld';

  @override
  String get pipelineInputKeyLabel => 'Schlüssel';

  @override
  String get pipelineInputKeyHelp =>
      'Statusschlüssel, unter dem der Wert gespeichert wird (z. B. repo_full_name).';

  @override
  String get pipelineInputLabelLabel => 'Bezeichnung';

  @override
  String get pipelineInputTypeLabel => 'Typ';

  @override
  String get pipelineInputOptionsLabel => 'Optionen (durch Kommas getrennt)';

  @override
  String get pipelineInputDefaultLabel => 'Standardwert';

  @override
  String get pipelineInputPlaceholderLabel => 'Platzhalter';

  @override
  String get pipelineInputHelpLabel => 'Hilfetext';

  @override
  String get pipelineInputRequiredLabel => 'Erforderlich';

  @override
  String get pipelineInputTypeText => 'Text';

  @override
  String get pipelineInputTypeMultiline => 'Mehrzeiliger Text';

  @override
  String get pipelineInputTypeNumber => 'Zahl';

  @override
  String get pipelineInputTypeBoolean => 'Schalter';

  @override
  String get pipelineInputTypeSelect => 'Auswahl';

  @override
  String get pipelinesEmpty => 'No pipeline runs yet';

  @override
  String get pipelinesEmptyHint =>
      'Klicke auf „Pipeline ausführen“, um eine zu starten.';

  @override
  String get pipelinesNoSteps => 'No steps recorded yet';

  @override
  String get pipelinesNoActiveWorkspace =>
      'Wähle einen Arbeitsbereich, um seine Pipelines anzuzeigen';

  @override
  String pipelinesLoadError(String error) {
    return 'Pipelines konnten nicht geladen werden: $error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'Pipeline konnte nicht gestartet werden: $error';
  }

  @override
  String get pipelineStatusPending => 'Pending';

  @override
  String get pipelineStatusQueued => 'In Warteschlange';

  @override
  String get pipelineStatusRunning => 'Running';

  @override
  String get pipelineStatusSuspended => 'Suspended';

  @override
  String get pipelineStatusCompleted => 'Completed';

  @override
  String get pipelineStatusFailed => 'Failed';

  @override
  String get pipelineStatusCancelled => 'Cancelled';

  @override
  String get pipelineStatusSkipped => 'Skipped';

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed von $total Schritten';
  }

  @override
  String get pipelineWaterfallTimeline => 'Zeitverlauf';

  @override
  String pipelineWaterfallActive(String duration) {
    return 'Aktiv $duration';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return 'inaktiv $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip =>
      'Zeit, die nicht zur aktiven Gesamtzeit zählt: der Lauf war gestoppt oder wartete zwischen Schritten.';

  @override
  String get pipelineStepStarted => 'Gestartet';

  @override
  String get pipelineStepFinished => 'Abgeschlossen';

  @override
  String get pipelineStepDurationLabel => 'Dauer';

  @override
  String get pipelineStepBranch => 'Branch';

  @override
  String get pipelineStepViewConversation => 'Unterhaltung anzeigen';

  @override
  String get pipelineStepError => 'Fehler';

  @override
  String get pipelineStepInput => 'Eingabe';

  @override
  String get pipelineStepOutput => 'Ausgabe';

  @override
  String get pipelineStepNotExecuted => 'Noch nicht ausgeführt';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'Fehlgeschlagen bei $step';
  }

  @override
  String get pipelineRunTriggerManual => 'Manuell';

  @override
  String get pipelineStepSkippedReason => 'Übersprungen';

  @override
  String get pipelineStepPriorAttempts => 'Vorherige Versuche';

  @override
  String get pipelineStepAttemptLabel => 'Versuch';

  @override
  String pipelineStepAttemptN(int number) {
    return 'Versuch $number';
  }

  @override
  String get pipelineStepAttemptInterrupted => 'Unterbrochen';

  @override
  String get pipelineRunColumnPipeline => 'Pipeline';

  @override
  String get pipelineRunColumnDuration => 'Dauer';

  @override
  String get pipelineRunQueueNext => 'Nächste';

  @override
  String pipelineRunQueuePosition(int position) {
    return '$position. in Warteschlange';
  }

  @override
  String get pipelineRunColumnStarted => 'Gestartet';

  @override
  String get pipelineRunHistory => 'Ausführungsverlauf';

  @override
  String get pipelineRunHistoryEmpty => 'Noch keine anderen Ausführungen';

  @override
  String pipelineRunRerunAgo(String time) {
    return 'Erneut ausgeführt $time';
  }

  @override
  String pipelineRunAttempt(int number) {
    return 'Versuch $number';
  }

  @override
  String pipelineRunFirstStarted(String time) {
    return 'erster Start $time';
  }

  @override
  String get pipelineRunFilterAll => 'Alle';

  @override
  String get pipelineRunFilterEmpty =>
      'Keine Ausführungen entsprechen diesem Filter';

  @override
  String get relativeJustNow => 'gerade eben';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Min.',
      one: 'vor 1 Min.',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Stunden',
      one: 'vor 1 Stunde',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Tagen',
      one: 'vor 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get teamsTitle => 'Teams';

  @override
  String get teamsAddTeam => 'Add team';

  @override
  String get teamsLoadError => 'Teams konnten nicht geladen werden';

  @override
  String get teamsEmptyTitle => 'Noch keine Teams';

  @override
  String get teamsEmptyDescription =>
      'Fasse Agenten zu Teams zusammen, damit einem Team zugewiesene Arbeit über eine Leitung läuft, die sie delegiert.';

  @override
  String get teamCreateTitle => 'Neues Team';

  @override
  String get teamEditTitle => 'Team bearbeiten';

  @override
  String get teamNameLabel => 'Teamname';

  @override
  String get teamNameHint => 'z. B. Frontend';

  @override
  String get teamDescriptionLabel => 'Beschreibung';

  @override
  String get teamDescriptionHint => 'Wofür dieses Team verantwortlich ist';

  @override
  String get teamLeaderLabel => 'Leitung';

  @override
  String get teamLeaderHelp =>
      'Die Koordination, die teamzugewiesene Arbeit erhält und an das am besten geeignete Mitglied delegiert.';

  @override
  String get teamNoLeader => 'Keine Leitung';

  @override
  String get teamInstructionsLabel => 'Arbeitsanweisungen';

  @override
  String get teamInstructionsHelp =>
      'Wird dem Briefing der Leitung angehängt – Teamkonventionen, Eskalationsregeln, Tonfall.';

  @override
  String get teamInstructionsHint => 'Optional';

  @override
  String get teamSaved => 'Team gespeichert';

  @override
  String get teamMembersError => 'Mitglieder konnten nicht geladen werden';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mitglieder',
      one: '1 Mitglied',
      zero: 'Keine Mitglieder',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => 'Mitglied hinzufügen';

  @override
  String get teamAddMemberTitle => 'Mitglieder hinzufügen';

  @override
  String teamAddMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hinzufügen',
      one: '1 hinzufügen',
      zero: 'Hinzufügen',
    );
    return '$_temp0';
  }

  @override
  String get teamNoAgentsToAdd => 'Jeder Agent ist bereits in diesem Team.';

  @override
  String get teamRemoveMember => 'Aus Team entfernen';

  @override
  String get teamLeaderBadge => 'Leitung';

  @override
  String get teamUnknownAgent => 'Unbekannter Agent';

  @override
  String get teamMembersEmpty => 'Noch keine Mitglieder';

  @override
  String get teamMembersEmptyDescription =>
      'Füge Agenten hinzu, damit die Leitung Personen zum Delegieren hat.';

  @override
  String get teamSelectPrompt => 'Team auswählen';

  @override
  String get teamSelectPromptDescription =>
      'Wähle ein Team aus der Liste oder erstelle ein neues.';

  @override
  String get teamDeleteTitle => 'Team löschen?';

  @override
  String teamDeleteBody(String name) {
    return '$name wird gelöscht. Die zugehörigen Agenten sind davon nicht betroffen.';
  }

  @override
  String get teamHasLeaderTooltip => 'Hat eine Leitung';

  @override
  String get pipelineTemplatesNav => 'Pipeline-Vorlagen';

  @override
  String get pipelineTemplatesTitle => 'Pipeline-Vorlagen';

  @override
  String get pipelineTemplatesSubtitle =>
      'Drag-and-Drop-Editor für die Pipelines, die deine Agenten orchestrieren.';

  @override
  String get pipelineTemplatesNew => 'Neue Vorlage';

  @override
  String get pipelineTemplatesEmpty =>
      'Noch keine Pipeline-Vorlagen. Erstelle eine, um zu beginnen.';

  @override
  String get pipelineTemplateIdLabel => 'Vorlagen-ID';

  @override
  String get pipelineTemplateBuiltInBadge => 'Integriert';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'Vorlage löschen?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'Pipeline-Vorlage $name löschen? Das kann nicht rückgängig gemacht werden.';
  }

  @override
  String get pipelineTemplateEditorTitle => 'Pipeline bearbeiten';

  @override
  String get pipelineTemplateEditorSubtitle =>
      'Ziehe Knotentypen aus der Seitenleiste auf die Leinwand und verbinde sie.';

  @override
  String get unsavedChanges => 'Nicht gespeicherte Änderungen';

  @override
  String get nodeLibraryTitle => 'Knotenbibliothek';

  @override
  String get nodeLibraryHint =>
      'Ziehe einen Eintrag auf die Leinwand, um einen Knoten hinzuzufügen.';

  @override
  String get editorDragHint =>
      'Aus der Bibliothek ziehen, Knoten anklicken zum Bearbeiten';

  @override
  String get editorEmptyCanvas =>
      'Ziehe einen Knoten aus der Bibliothek, um zu beginnen.';

  @override
  String get nodeConfigTitle => 'Knoten-Konfiguration';

  @override
  String get nodeConfigKind => 'Art';

  @override
  String get nodeConfigLabel => 'Bezeichnung';

  @override
  String get nodeConfigAgent => 'Agent';

  @override
  String get nodeConfigAgentHint => 'Agent auswählen…';

  @override
  String get nodeConfigInputKeys => 'Eingabeschlüssel (kommagetrennt)';

  @override
  String get nodeConfigInputKeysHelp =>
      'State-Schlüssel, die dieser Knoten konsumiert. Werden für die Platzhalter-Substitution im Prompt verwendet.';

  @override
  String get nodeConfigRepos => 'Zu klonende Repositories';

  @override
  String get nodeConfigReposHelp =>
      'Repositories, die geklont und code-indiziert werden, wenn dieser Knoten seine Konversation startet. Alle auszuwählen klont sie alle (Vorgabe).';

  @override
  String get nodeConfigRepoBranchHint => 'Branch (Standard)';

  @override
  String get nodeConfigRepoBranchHelp =>
      'Der Branch, von dem jede Kopie abzweigt. Leer lassen für den Standard-Branch des Repositorys — die Arbeitskopie bekommt einen eigenen Branch, sodass nichts, was ein Agent committet, auf diesem landet.';

  @override
  String nodeConfigReposDynamic(String entries) {
    return 'Dynamische Einträge beibehalten: $entries';
  }

  @override
  String get nodeConfigCreateConversation => 'Darin eine Unterhaltung öffnen';

  @override
  String get nodeConfigCreateConversationHelp =>
      'Lass dies aus, wenn mehrere Agentenknoten folgen — jeder öffnet seinen eigenen benannten Verlauf. Schalte es ein, wenn ein einzelner Agentenknoten folgt, damit der Raum nie eine Unterhaltung ohne Titel daneben zeigt.';

  @override
  String get nodeConfigConversationTitle => 'Name der Unterhaltung';

  @override
  String get nodeConfigConversationTitleHelp =>
      'Gib dem nachgelagerten Agentenknoten denselben Namen, dann arbeiten beide in einem Verlauf. Standardmäßig die Beschriftung des Knotens.';

  @override
  String get nodeConfigSpaceName => 'Name des Raums';

  @override
  String get nodeConfigSpaceNameHelp =>
      'Wie der Raum heißt, den dieser Knoten öffnet. Unterstützt dieselben Zustands-Platzhalter wie ein Prompt. Leer lassen, um die Beschriftung des Knotens zu verwenden.';

  @override
  String get nodeConfigSpaceNameHint => 'Prüfung von pr_number';

  @override
  String get nodeConfigStreamTitle => 'Name der Unterhaltung';

  @override
  String get nodeConfigStreamTitleHelp =>
      'Der benannte Strang, in dem der Agent dieses Knotens im Raum arbeitet. Unterstützt dieselben Zustands-Platzhalter wie ein Prompt. Bleibt er leer, landet der Zug in der ständigen Unterhaltung des Raums, wo ein Fan-out jeden Agenten verschränkt.';

  @override
  String get nodeConfigConversationTitleHint => 'Architekturanalyse';

  @override
  String get nodeConfigOutputKey => 'Ausgabeschlüssel';

  @override
  String get nodeConfigPrompt => 'Prompt-Vorlage';

  @override
  String get nodeConfigPromptHelp =>
      'Verwende Platzhalter in doppelten geschweiften Klammern, um Werte aus dem State zur Laufzeit einzusetzen.';

  @override
  String get nodeConfigScript => 'Bash-Skript';

  @override
  String get nodeConfigScriptHelp =>
      'Wird mit bash -c ausgeführt. GITHUB_TOKEN ist gesetzt. Platzhalter werden vor der Ausführung ersetzt.';

  @override
  String get nodeConfigTriggers => 'Ausgelöst durch';

  @override
  String get nodeConfigNoUpstream => 'Keine anderen Knoten zum Verbinden.';

  @override
  String get nodeConfigRouteKeys => 'Routing-Schlüssel';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'Routing-Schlüssel von $source';
  }

  @override
  String get conditionSectionTitle => 'Bedingung';

  @override
  String get conditionMode => 'Modus';

  @override
  String get conditionModeFilesAny => 'Datei(en) vorhanden — beliebige';

  @override
  String get conditionModeFilesAll => 'Dateien vorhanden — alle';

  @override
  String get conditionModeComparison => 'Vergleich';

  @override
  String get conditionModeSwitch => 'Verzweigung';

  @override
  String get conditionFilePaths => 'Dateipfade';

  @override
  String get conditionFilePathsAnyHelp =>
      'Ein Pfad pro Zeile, relativ zum Basisverzeichnis. Gibt true zurück, wenn einer existiert.';

  @override
  String get conditionFilePathsAllHelp =>
      'Ein Pfad pro Zeile, relativ zum Basisverzeichnis. Gibt true nur zurück, wenn alle existieren.';

  @override
  String get conditionBaseKey => 'Schlüssel des Basisverzeichnisses';

  @override
  String get conditionBaseKeyHelp =>
      'Status-Schlüssel mit dem Verzeichnis, gegen das Pfade aufgelöst werden (Standard repo_local_path).';

  @override
  String get conditionRecursive => 'Unterverzeichnisse durchsuchen';

  @override
  String get conditionNegate => 'Umkehren: true, wenn nicht vorhanden';

  @override
  String get conditionLeft => 'Linker Wert';

  @override
  String get conditionOperator => 'Operator';

  @override
  String get conditionRight => 'Rechter Wert';

  @override
  String get conditionSwitchKey => 'Nach Status-Schlüssel verzweigen';

  @override
  String get conditionCases => 'Fälle (durch Komma getrennt)';

  @override
  String get conditionCasesHelp =>
      'Routing-Schlüssel, die der Reihe nach mit dem Wert verglichen werden.';

  @override
  String get conditionDefaultCase => 'Standardfall';

  @override
  String get triggerPanelTitle => 'Auslöser';

  @override
  String get triggerPanelHelp => 'Was diese Pipeline startet.';

  @override
  String get triggerManualHelp =>
      'Auf der Ausführungsseite anzeigen und manuell starten.';

  @override
  String get triggerSectionAutomatic => 'Automatische Auslöser';

  @override
  String get triggerAddButton => 'Auslöser hinzufügen';

  @override
  String get triggerNoneYet => 'Noch keine automatischen Auslöser.';

  @override
  String get triggerAddDialogTitle => 'Auslöser hinzufügen';

  @override
  String get triggerKindLabel => 'Auslösertyp';

  @override
  String get triggerKindEvent => 'Bei einem Ereignis';

  @override
  String get triggerKindSchedule => 'Nach Zeitplan';

  @override
  String get triggerKindWebhook => 'Über einen Webhook';

  @override
  String get triggerScheduleExprLabel => 'Zeitplan (cron oder every:Sekunden)';

  @override
  String get triggerTimezoneLabel => 'Zeitzone (optional)';

  @override
  String get triggerCatchUpLabel => 'Bei verpassten Läufen';

  @override
  String get triggerCatchUpRunOnce => 'Einmal ausführen';

  @override
  String get triggerCatchUpSkip => 'Überspringen';

  @override
  String get syncHealthTitle => 'Sync-Status';

  @override
  String get syncHealthNoConfigs => 'Noch keine Sync-Verbindungen';

  @override
  String get syncHealthNeverSynced => 'Nie synchronisiert';

  @override
  String get syncOutcomeOk => 'Synchronisiert';

  @override
  String get syncOutcomeFailed => 'Fehlgeschlagen';

  @override
  String get syncOutcomeSkipped => 'Übersprungen';

  @override
  String syncHealthFailedStreak(int count) {
    return '$count aufeinanderfolgende Fehler';
  }

  @override
  String get triggerWebhookHelp =>
      'Eine signierte Webhook-URL wird erzeugt. Externe Systeme senden ein POST, um diese Pipeline zu starten.';

  @override
  String get triggerEventFieldLabel => 'Ereignis';

  @override
  String get triggerNoMoreEvents =>
      'Alle verfügbaren Ereignisse sind bereits eingerichtet.';

  @override
  String get triggerMatchStatusLabel => 'Nur wenn der Status ist';

  @override
  String get triggerSummaryNone => 'Keine Auslöser';

  @override
  String triggerEverySeconds(int seconds) {
    return 'Alle ${seconds}s';
  }

  @override
  String get triggerEventManual => 'Manueller Lauf';

  @override
  String get triggerEventSchedule => 'Zeitplan';

  @override
  String get triggerEventPrStatusChanged => 'PR-Status geändert';

  @override
  String get triggerEventExternalPr => 'Externe PR geöffnet';

  @override
  String get triggerEventPrPublished => 'PR veröffentlicht';

  @override
  String get triggerEventPrMerged => 'PR zusammengeführt';

  @override
  String get triggerEventRepoAdded => 'Repository hinzugefügt';

  @override
  String get triggerEventCodeGraphWatch => 'Dateiänderung';

  @override
  String pipelineRunCauseChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count geänderte Dateien',
      one: '1 geänderte Datei',
    );
    return '$_temp0';
  }

  @override
  String pipelineRunCauseMorePaths(int count) {
    return '+$count weitere';
  }

  @override
  String get pipelineRunCauseRescan => 'Auf der Festplatte geändert';

  @override
  String get pipelineRunCauseInitial => 'Erste Indizierung dieser Arbeitskopie';

  @override
  String get triggerEventMessageReceived => 'Nachricht empfangen';

  @override
  String get triggerEventTicketCompleted => 'Aufgabe abgeschlossen';

  @override
  String get triggerEventTicketFailed => 'Aufgabe fehlgeschlagen';

  @override
  String get triggerEventTicketCancelled => 'Aufgabe abgebrochen';

  @override
  String get triggerEventBudgetCrossed => 'Budgetschwelle überschritten';

  @override
  String get nodeLibrarySearchHint => 'Knoten suchen';

  @override
  String get nodeLibraryNoMatches => 'Keine passenden Knoten';

  @override
  String get nodeCategoryFlow => 'Ablauf und Logik';

  @override
  String get nodeCategoryPr => 'PR-Review';

  @override
  String get nodeCategoryAgents => 'Agenten';

  @override
  String get nodeCategoryMessaging => 'Nachrichten';

  @override
  String get nodeCategoryCode => 'Code';

  @override
  String get triggerDisabledTag => 'aus';

  @override
  String get pipelineInputTypeRepo => 'Repository';

  @override
  String get pipelineRunNoRepos =>
      'Noch keine Repositorys in diesem Workspace.';

  @override
  String get allowTicketingApi => 'Ticketing-API-Aufrufe zulassen';

  @override
  String get ticketingApiKey => 'Ticketing-API-Schlüssel';

  @override
  String get ticketingApiKeySubtitle =>
      'Fügt den API-Schlüssel des Ticketing-Anbieters in die Sandbox ein.';

  @override
  String get ticketingProvider => 'Ticketing-Anbieter';

  @override
  String get connectGitHubAndTicketing =>
      'Verbinde einen Code-Host, damit Control Center deine Pull Requests, Issues und Reviews lesen kann. Optional einen Ticketing-Anbieter verbinden. Zugangsdaten liegen auf deinem Server, nie auf diesem Rechner.';

  @override
  String get triggerEventTicketAssigned => 'Ticket zugewiesen';

  @override
  String get navTickets => 'Tickets';

  @override
  String get ticketsTitle => 'Tickets';

  @override
  String get newTicket => 'Neues Ticket';

  @override
  String get noTicketsYet => 'Noch keine Tickets';

  @override
  String get addCollaborator => 'Mitarbeiter hinzufügen';

  @override
  String get noCollaborators => 'Noch keine Mitarbeiter';

  @override
  String get linkedPullRequests => 'Verknüpfte Pull Requests';

  @override
  String get noLinkedPullRequests => 'Noch keine verknüpften Pull Requests';

  @override
  String get stopAgent => 'Agent stoppen';

  @override
  String get ticketProperties => 'Eigenschaften';

  @override
  String get ticketTabIssue => 'Ticket';

  @override
  String get ticketSelectPrompt =>
      'Wähle ein Ticket, um seine Details anzuzeigen';

  @override
  String get unassigned => 'Nicht zugewiesen';

  @override
  String get ticketStatusBacklog => 'Backlog';

  @override
  String get ticketStatusOpen => 'Zu erledigen';

  @override
  String get ticketStatusInProgress => 'In Bearbeitung';

  @override
  String get ticketStatusInReview => 'In Prüfung';

  @override
  String get ticketStatusDone => 'Erledigt';

  @override
  String get ticketStatusBlocked => 'Blockiert';

  @override
  String get ticketStatusFailed => 'Fehlgeschlagen';

  @override
  String get ticketStatusCancelled => 'Abgebrochen';

  @override
  String get notificationTicketAssigned => 'Ticket zugewiesen';

  @override
  String get notificationTicketStatusChanged => 'Ticket-Status geändert';

  @override
  String get priority => 'Priorität';

  @override
  String get status => 'Status';

  @override
  String get assignee => 'Zugewiesen an';

  @override
  String get labels => 'Labels';

  @override
  String get noLabelsYet => 'Noch keine Labels';

  @override
  String get clearLabels => 'Labels entfernen';

  @override
  String get pipelineStepAgentActivity => 'Agent-Aktivität';

  @override
  String get runStatusCompleted => 'Abgeschlossen';

  @override
  String get runStatusQueued => 'In Warteschlange';

  @override
  String get ticketDescription => 'Beschreibung';

  @override
  String get ticketPriorityNone => 'Keine';

  @override
  String get ticketPriorityUrgent => 'Dringend';

  @override
  String get ticketPriorityHigh => 'Hoch';

  @override
  String get ticketPriorityMedium => 'Mittel';

  @override
  String get ticketPriorityLow => 'Niedrig';

  @override
  String get ticketViewList => 'Liste';

  @override
  String get ticketViewBoard => 'Board';

  @override
  String get ticketTitlePlaceholder => 'Titel des Tickets';

  @override
  String get ticketDescriptionPlaceholder => 'Beschreibung hinzufügen…';

  @override
  String get createMore => 'Weitere erstellen';

  @override
  String selectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get clearSelection => 'Auswahl aufheben';

  @override
  String get bulkDeleteTitle => 'Tickets löschen';

  @override
  String bulkDeleteMessage(int count) {
    return '$count ausgewählte Tickets löschen? Das kann nicht rückgängig gemacht werden.';
  }

  @override
  String get assignTo => 'Zuweisen an…';

  @override
  String get sectionMembers => 'Mitglieder';

  @override
  String get sectionAgents => 'Agenten';

  @override
  String get sidebarGroupWorkspace => 'Workspace';

  @override
  String get notificationsTitle => 'Benachrichtigungen';

  @override
  String get notificationsTooltip => 'Benachrichtigungen';

  @override
  String get notificationsEmpty => 'Alles erledigt';

  @override
  String notificationsUnreadCount(int count) {
    return '$count ungelesen';
  }

  @override
  String get notificationsMarkRead => 'Als gelesen markieren';

  @override
  String get notificationsMarkUnread => 'Als ungelesen markieren';

  @override
  String get notificationsEntryActions => 'Benachrichtigungsaktionen';

  @override
  String get markAllRead => 'Alle als gelesen markieren';

  @override
  String get teamsNav => 'Teams';

  @override
  String get noWorkspace => 'Kein Arbeitsbereich';

  @override
  String get selectWorkspace => 'Arbeitsbereich auswählen';

  @override
  String get navMemory => 'Gedächtnis';

  @override
  String get memoryTabFacts => 'Fakten';

  @override
  String get memoryTabPolicies => 'Richtlinien';

  @override
  String get memoryGraphShowFacts => 'Fakten anzeigen';

  @override
  String get memoryGraphHideFacts => 'Fakten ausblenden';

  @override
  String get memoryGraphExpandAll => 'Alle Fakten anzeigen';

  @override
  String get memoryGraphCollapseAll => 'Alle Fakten ausblenden';

  @override
  String get memoryTabGraph => 'Wissensgraph';

  @override
  String get memoryNoWorkspace =>
      'Wähle einen Arbeitsbereich, um sein Gedächtnis anzuzeigen.';

  @override
  String get searchArticles => 'Artikel suchen';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterUnread => 'Ungelesen';

  @override
  String get filterSaved => 'Gespeichert';

  @override
  String get saveArticle => 'Artikel speichern';

  @override
  String get removeFromSaved => 'Aus Gespeicherten entfernen';

  @override
  String get filterBySource => 'Nach Quelle filtern';

  @override
  String get viewAsList => 'Listenansicht';

  @override
  String get viewAsGrid => 'Rasteransicht';

  @override
  String get noMatchingArticles => 'Keine passenden Artikel';

  @override
  String get noMatchingArticlesBody =>
      'Versuche eine andere Suche oder einen anderen Quellenfilter.';

  @override
  String get allCaughtUp => 'Alles erledigt';

  @override
  String get allCaughtUpBody =>
      'Keine ungelesenen Artikel — schau später wieder vorbei.';

  @override
  String get openArticlesInAppDescription =>
      'Links im integrierten Reader statt im Standardbrowser öffnen.';

  @override
  String get blockAdsTrackersDescription =>
      'Werbung, Tracker und Cookie-Banner aus Artikeln entfernen, die du im Reader öffnest.';

  @override
  String get agentQuestionHeader => 'Frage an dich';

  @override
  String get agentQuestionAnsweredLabel => 'Beantwortet';

  @override
  String get agentQuestionSubmit => 'Antwort senden';

  @override
  String get agentQuestionFreeformHint => 'Gib deine Antwort ein…';

  @override
  String get agentQuestionAnswerLabel => 'Deine Antwort';

  @override
  String get reviewRequested => 'Review angefragt';

  @override
  String get connectGitHubHint =>
      'Melde dich bei GitHub an oder füge ein Token unter Einstellungen → Du → Profil und Identität → Code-Hosting hinzu';

  @override
  String get connectGitHubToLoadPrs =>
      'GitHub verbinden, um Pull Requests zu laden';

  @override
  String get noRepositoriesConfigured => 'Keine Repositories konfiguriert';

  @override
  String openedAgo(String age) {
    return 'Geöffnet $age';
  }

  @override
  String prTimelineOpened(String author) {
    return '$author hat diesen Pull Request geöffnet';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Commits',
      one: '1 Commit',
    );
    return '$author hat diesen Pull Request mit $_temp0 geöffnet';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return '$actor hat ein Review von $reviewers angefordert';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '$actor hat die Review-Anfrage für $reviewers entfernt';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '$actor hat ein Review von $requested angefordert und die Review-Anfrage für $removed entfernt';
  }

  @override
  String prTimelineCommitted(String author) {
    return '$author hat committet';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Commits',
      one: '1 Commit',
    );
    return '$author hat $_temp0 gepusht';
  }

  @override
  String prTimelineApproved(String author) {
    return '$author hat diese Änderungen genehmigt';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return '$author hat Änderungen angefordert';
  }

  @override
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Code-Kommentare',
      one: '1 Code-Kommentar',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '$author hat ein Review hinterlassen';
  }

  @override
  String get prTimelineSomeone => 'Jemand';

  @override
  String get prTimelineBotBadge => 'bot';

  @override
  String updatedAgo(String age) {
    return 'Aktualisiert $age';
  }

  @override
  String get checksPassing => 'Prüfungen bestanden';

  @override
  String get checksRunning => 'Prüfungen laufen';

  @override
  String get needsYourReview => 'Benötigt deine Review';

  @override
  String get checks => 'Prüfungen';

  @override
  String get noReviewersAssigned => 'Keine Prüfer zugewiesen';

  @override
  String get noAssignees => 'Keine Zuständigen';

  @override
  String get loadingEllipsis => 'Wird geladen…';

  @override
  String get loadingChecks => 'Prüfungen laden…';

  @override
  String get noChecksYet => 'Noch keine Prüfungen ausgeführt';

  @override
  String checksFailingCount(int count) {
    return '$count fehlgeschlagen';
  }

  @override
  String get showMore => 'Mehr anzeigen';

  @override
  String get showLess => 'Weniger anzeigen';

  @override
  String get backToPullRequests => 'Zurück zu den Pull Requests';

  @override
  String get pullRequestNotFound => 'Pull Request nicht gefunden';

  @override
  String get pullRequestNotFoundBody =>
      'Sie wurde möglicherweise zusammengeführt, geschlossen oder verschoben.';

  @override
  String get couldntLoadPullRequest =>
      'Diese Pull Request konnte nicht geladen werden';

  @override
  String get showDetails => 'Details anzeigen';

  @override
  String get noDescriptionProvided => 'Keine Beschreibung angegeben.';

  @override
  String get factsHint =>
      'Fakten erscheinen hier, sobald deine Agenten dazulernen.';

  @override
  String get noFactsMatch => 'Keine Fakten entsprechen deiner Suche';

  @override
  String get memoryLoadError => 'Speicher konnte nicht geladen werden';

  @override
  String get sortRecent => 'Neueste';

  @override
  String get sortConfidence => 'Konfidenz';

  @override
  String get confidenceTooltip =>
      'Wie sicher sich Agenten sind, dass dieser Fakt stimmt, von 0 bis 100 %.';

  @override
  String get supersededTooltip => 'Ein neuerer Fakt hat diesen ersetzt.';

  @override
  String get domain => 'Domäne';

  @override
  String get fitToView => 'An Ansicht anpassen';

  @override
  String get project => 'Projekt';

  @override
  String get newProject => 'Neues Projekt';

  @override
  String get editProject => 'Projekt bearbeiten';

  @override
  String get deleteProject => 'Projekt löschen';

  @override
  String get noProject => 'Kein Projekt';

  @override
  String get allTickets => 'Alle Tickets';

  @override
  String get projectNamePlaceholder => 'Projektname';

  @override
  String get projectDescriptionPlaceholder => 'Beschreibung (optional)';

  @override
  String get projectColorLabel => 'Farbe';

  @override
  String get noProjectsYet => 'Noch keine Projekte';

  @override
  String get projectTicketsEmpty => 'Noch keine Tickets in diesem Projekt';

  @override
  String get createProject => 'Projekt erstellen';

  @override
  String projectProgress(int done, int total) {
    return '$done von $total erledigt';
  }

  @override
  String deleteProjectConfirm(String name) {
    return '„$name“ löschen? Die Tickets bleiben erhalten und werden aus dem Projekt entfernt.';
  }

  @override
  String get projectStatusActive => 'Aktiv';

  @override
  String get projectStatusCompleted => 'Abgeschlossen';

  @override
  String get projectStatusArchived => 'Archiviert';

  @override
  String get markProjectCompleted => 'Als abgeschlossen markieren';

  @override
  String get markProjectActive => 'Als aktiv markieren';

  @override
  String get archiveProject => 'Archivieren';

  @override
  String get restoreProject => 'Wiederherstellen';

  @override
  String get relations => 'Beziehungen';

  @override
  String get relateTo => 'Verknüpfen mit';

  @override
  String get relationSubIssueOf => 'Unteraufgabe von…';

  @override
  String get relationParentOf => 'Übergeordnet zu…';

  @override
  String get relationBlockedBy => 'Blockiert von…';

  @override
  String get relationBlocking => 'Blockiert…';

  @override
  String get relationRelatedTo => 'Verwandt mit…';

  @override
  String get relationDuplicateOf => 'Duplikat von…';

  @override
  String get relationGroupParent => 'Übergeordnet';

  @override
  String get relationGroupSubIssues => 'Unteraufgaben';

  @override
  String get relationGroupBlockedBy => 'Blockiert von';

  @override
  String get relationGroupBlocking => 'Blockiert';

  @override
  String get relationGroupRelated => 'Verwandt';

  @override
  String get relationGroupDuplicateOf => 'Duplikat von';

  @override
  String get relationGroupDuplicatedBy => 'Dupliziert von';

  @override
  String get copyId => 'ID kopieren';

  @override
  String get ticketIdCopied => 'Ticket-ID kopiert';

  @override
  String get searchTicketsHint => 'Tickets suchen…';

  @override
  String get noMatchingTickets => 'Keine passenden Tickets';

  @override
  String get clearAll => 'Alle löschen';

  @override
  String agentsRunningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Agenten aktiv',
      one: '1 Agent aktiv',
    );
    return '$_temp0';
  }

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs PRs warten',
      one: '1 PR wartet',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos Repositorys',
      one: '1 Repository',
    );
    return '$_temp0 auf deine Review in $_temp1';
  }

  @override
  String get manageWorkspacesSubtitle =>
      'Benenne einen Workspace um und ändere seine Markierung — wähle links einen aus, um ihn zu bearbeiten.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Workspaces',
      one: '1 Workspace',
      zero: 'Keine Workspaces',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos Repos',
      one: '1 Repo',
      zero: 'Keine Repos',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents Agenten',
      one: '1 Agent',
      zero: '0 Agenten',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'Identität';

  @override
  String get uploadImage => 'Bild hochladen';

  @override
  String get failedToSaveLogo =>
      'Logo konnte nicht gespeichert werden. Stelle sicher, dass die App die ausgewählte Datei lesen kann.';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG oder GIF bis zu 2 MB. Andernfalls verwenden wir den Anfangsbuchstaben des Workspace.';

  @override
  String get workspaceNameFieldHelp =>
      'Wird im Umschalter, im Brotkrümelpfad und auf jedem Bildschirm angezeigt.';

  @override
  String get dangerZone => 'Gefahrenzone';

  @override
  String get deleteThisWorkspace => 'Diesen Workspace löschen';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return 'Entfernt $name, seine Repository-Verbindungen, Agenten und den Speicher dauerhaft. Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get discard => 'Verwerfen';

  @override
  String discardChangesQuestion(String name) {
    return 'Nicht gespeicherte Änderungen an $name verwerfen?';
  }

  @override
  String get workspaceUpdated => 'Workspace aktualisiert';

  @override
  String get editTitle => 'Titel bearbeiten';

  @override
  String get editDescription => 'Beschreibung bearbeiten';

  @override
  String get addDescription => 'Beschreibung hinzufügen';

  @override
  String get prTitlePlaceholder => 'Titel';

  @override
  String get prBodyPlaceholder => 'Beschreibung hinzufügen';

  @override
  String get write => 'Schreiben';

  @override
  String get overview => 'Übersicht';

  @override
  String get noFilesChanged => 'Keine Dateien geändert';

  @override
  String get diff => 'Diff';

  @override
  String get preview => 'Vorschau';

  @override
  String get outdated => 'Veraltet';

  @override
  String get outdatedComments => 'Veraltete Kommentare';

  @override
  String outdatedCountLabel(int count) {
    return '$count veraltet';
  }

  @override
  String get prTemplateLabel => 'Vorlage';

  @override
  String get prTemplateDefault => 'Standard';

  @override
  String get addReviewers => 'Reviewer hinzufügen';

  @override
  String get addAssignees => 'Zuständige hinzufügen';

  @override
  String get searchUsers => 'Personen suchen…';

  @override
  String get searchReviewers => 'Personen und Teams suchen…';

  @override
  String get usersSectionLabel => 'Personen';

  @override
  String get userStatusBusy => 'Beschäftigt';

  @override
  String get teamsSectionLabel => 'Teams';

  @override
  String get suggestedReviewers => 'Vorgeschlagene Prüfer';

  @override
  String get noMatchingUsers => 'Keine passenden Personen';

  @override
  String get noMatchingReviewers => 'Keine Treffer';

  @override
  String get requiredByCodeOwners => 'Von Code-Eigentümern erforderlich';

  @override
  String reviewedOnBehalfOf(String login) {
    return 'über $login';
  }

  @override
  String get team => 'Team';

  @override
  String get markdownBold => 'Fett';

  @override
  String get markdownItalic => 'Kursiv';

  @override
  String get markdownHeading => 'Überschrift';

  @override
  String get markdownBulletList => 'Aufzählung';

  @override
  String get markdownChecklist => 'Checkliste';

  @override
  String get markdownCode => 'Code';

  @override
  String get markdownLink => 'Link';

  @override
  String get markdownQuote => 'Zitat';

  @override
  String get markdownSupported => 'Markdown wird unterstützt';

  @override
  String get markdownAttachImages => 'Klicke, um Bilder hinzuzufügen';

  @override
  String failedToUpdateTitle(String error) {
    return 'Titel konnte nicht aktualisiert werden: $error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'Beschreibung konnte nicht aktualisiert werden: $error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'Reviewer konnten nicht aktualisiert werden: $error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'Zuständige konnten nicht aktualisiert werden: $error';
  }

  @override
  String get discardChangesConfirm => 'Änderungen verwerfen?';

  @override
  String get newPr => 'Neue PR';

  @override
  String get openPullRequest => 'Pull Request öffnen';

  @override
  String get composePrSubtitle =>
      'Aus einem gepushten Branch — ohne Agenten oder Tickets';

  @override
  String get createAsDraft => 'Als Entwurf erstellen';

  @override
  String get composePrNoRepo => 'Kein GitHub-Repository ausgewählt';

  @override
  String get composePrNoRepoHint =>
      'Wähle einen Arbeitsbereich mit einem mit GitHub verknüpften Repository, um eine Pull Request zu öffnen.';

  @override
  String get composePrPickBranches =>
      'Wähle einen Basis- und einen Vergleichsbranch, um die Änderungen anzuzeigen.';

  @override
  String get composePrNothingToCompare =>
      'Es gibt keine Änderungen zwischen diesen Branches.';

  @override
  String get repository => 'Repository';

  @override
  String get baseBranchLabel => 'Basis';

  @override
  String get compareBranchLabel => 'Vergleichen';

  @override
  String get selectBranch => 'Branch auswählen';

  @override
  String get navMeetings => 'Besprechungen';

  @override
  String get meetingsNoWorkspace =>
      'Wähle einen Arbeitsbereich, um Besprechungen zu sehen.';

  @override
  String get meetingsEmpty => 'Noch keine Besprechungen';

  @override
  String get meetingsEmptyHint =>
      'Nimm deine erste Besprechung auf — das Audio bleibt auf diesem Gerät und der Agent macht daraus Notizen, Entscheidungen und Aufgaben.';

  @override
  String get meetingNotesHint =>
      'Notiere kurze Notizen – der Agent erweitert sie nach der Besprechung.';

  @override
  String get meetingSpeakerMe => 'Du';

  @override
  String get meetingStatusRecording => 'Aufnahme';

  @override
  String get meetingStatusProcessing => 'Verarbeitung';

  @override
  String get meetingStatusDone => 'Fertig';

  @override
  String get meetingStatusFailed => 'Fehlgeschlagen';

  @override
  String get meetingsSubtitle =>
      'Auf diesem Gerät aufgenommen und transkribiert, dann von einem Agenten zusammengefasst.';

  @override
  String get meetingsRecordMeeting => 'Besprechung aufnehmen';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count werden gerade verarbeitet',
      one: '1 wird gerade verarbeitet',
    );
    return '$_temp0';
  }

  @override
  String meetingsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Besprechungen',
      one: '1 Besprechung',
      zero: 'Keine Besprechungen',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLedgerOpenActions => 'Offene Aufgaben';

  @override
  String get meetingsLedgerDecisions => 'Entscheidungen';

  @override
  String get meetingsLiveOpen => 'Aufnahme öffnen';

  @override
  String get meetingTemplateShort => 'Vorlage';

  @override
  String get meetingsStatThisWeek => 'Diese Woche';

  @override
  String get meetingsStatRecorded => 'Aufgenommen';

  @override
  String get meetingsFilterAll => 'Alle';

  @override
  String get meetingsFilterDone => 'Erledigt';

  @override
  String get meetingsFilterProcessing => 'In Bearbeitung';

  @override
  String get meetingsSearchHint => 'Nach Titel, Person, App filtern…';

  @override
  String get meetingsBucketToday => 'Heute';

  @override
  String get meetingsBucketYesterday => 'Gestern';

  @override
  String get meetingsBucketEarlierThisWeek => 'Früher diese Woche';

  @override
  String get meetingsBucketLastWeek => 'Letzte Woche';

  @override
  String get meetingsBucketOlder => 'Älter';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Entscheidungen',
      one: '1 Entscheidung',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total Aufgaben';
  }

  @override
  String get meetingsEnhancedPill => 'angereichert';

  @override
  String get meetingsTranscribing => 'transkribieren und zusammenfassen…';

  @override
  String get meetingsOpenAction => 'Öffnen';

  @override
  String get meetingsStopProcessing => 'Stoppen';

  @override
  String get meetingsStillTranscribing =>
      'Wird noch transkribiert — die Zusammenfassung erscheint, sobald sie fertig ist.';

  @override
  String get meetingsNoMatch => 'Keine Besprechung passt';

  @override
  String get meetingsNoMatchHint =>
      'Versuche einen anderen Filter oder Suchbegriff.';

  @override
  String get meetingBackAllMeetings => 'Alle Besprechungen';

  @override
  String get meetingReRunSummary => 'Zusammenfassung neu erstellen';

  @override
  String get meetingExport => 'Exportieren';

  @override
  String get meetingAugmentingBanner =>
      'Notizen werden aus dem Transkript angereichert — Entscheidungen und Aufgaben werden extrahiert…';

  @override
  String get meetingTabNotes => 'Notizen';

  @override
  String get meetingTabTranscript => 'Transkript';

  @override
  String get meetingTabActionItems => 'Aufgaben';

  @override
  String get meetingTabDecisions => 'Entscheidungen';

  @override
  String get meetingNotesEnhancedToggle => 'Angereichert';

  @override
  String get meetingNotesYoursToggle => 'Deine Notizen';

  @override
  String get meetingEnhancedByAgent =>
      'Vom Agenten angereichert · aus dem Transkript';

  @override
  String get meetingEnhancedPending =>
      'Der Agent arbeitet noch an dieser Zusammenfassung.';

  @override
  String get meetingNotesEmpty => 'Noch keine angereicherten Notizen.';

  @override
  String get meetingNotesSavedLocally => 'Lokal gespeichert';

  @override
  String get meetingNotesSaving => 'Speichern…';

  @override
  String get meetingViewFullTranscript => 'Vollständiges Transkript ansehen';

  @override
  String get meetingTranscriptSearchHint => 'Im Transkript suchen…';

  @override
  String get meetingSpeakerEveryone => 'Alle';

  @override
  String get meetingSpeakerOthers => 'Andere';

  @override
  String get meetingTranscriptEmpty => 'Noch kein Transkript.';

  @override
  String get meetingActionItemsEmpty => 'Keine Aufgaben extrahiert.';

  @override
  String get meetingActionItemFrom => 'aus dieser Besprechung';

  @override
  String get meetingCreateTicket => 'Ticket erstellen';

  @override
  String meetingTicketCreated(String key) {
    return 'Ticket $key erstellt und zugewiesen.';
  }

  @override
  String get meetingTicketFailed => 'Ticket konnte nicht erstellt werden.';

  @override
  String get meetingDecisionsEmpty => 'Keine Entscheidungen protokolliert.';

  @override
  String get meetingEditTitle => 'Titel bearbeiten';

  @override
  String get meetingTitleLabel => 'Titel';

  @override
  String get meetingAddActionItem => 'Aufgabe hinzufügen';

  @override
  String get meetingEditActionItem => 'Aufgabe bearbeiten';

  @override
  String get meetingDeleteActionItem => 'Aufgabe löschen';

  @override
  String get meetingActionItemContentLabel => 'Aufgabe';

  @override
  String get meetingActionItemContentHint => 'Was ist zu tun?';

  @override
  String get meetingActionItemOwnerLabel => 'Verantwortlich';

  @override
  String get meetingActionItemOwnerHint => 'Wer ist zuständig? (optional)';

  @override
  String get meetingAddDecision => 'Entscheidung hinzufügen';

  @override
  String get meetingEditDecision => 'Entscheidung bearbeiten';

  @override
  String get meetingDeleteDecision => 'Entscheidung löschen';

  @override
  String get meetingDecisionContentLabel => 'Entscheidung';

  @override
  String get meetingDecisionContentHint => 'Was wurde entschieden?';

  @override
  String get meetingReRunStarted =>
      'Zusammenfassung wird auf dem Transkript neu erstellt…';

  @override
  String get meetingReRunNoTranscript =>
      'Es gibt noch kein Transkript zum Zusammenfassen.';

  @override
  String get meetingExportCopied =>
      'Notizen als Markdown in die Zwischenablage kopiert.';

  @override
  String get meetingExportSaved => 'Besprechung exportiert.';

  @override
  String meetingExportFailed(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String get meetingExportNothing => 'Es gibt noch nichts zu exportieren.';

  @override
  String get meetingPlaybackPlay => 'Abspielen';

  @override
  String get meetingPlaybackPause => 'Pause';

  @override
  String get meetingPlaybackUnavailable =>
      'Die Audiowiedergabe ist auf diesem Gerät nicht verfügbar.';

  @override
  String get meetingDetectedTitle => 'Meeting erkannt';

  @override
  String meetingDetectedSubtitle(String label) {
    return '„$label“ scheint gerade stattzufinden. Aufzeichnen?';
  }

  @override
  String get meetingDetectedSubtitleGeneric =>
      'Es scheint gerade ein Meeting stattzufinden. Aufzeichnen?';

  @override
  String get meetingDetectedRecord => 'Aufzeichnen';

  @override
  String get meetingDetectedDismiss => 'Verwerfen';

  @override
  String get meetingAutoStopTitle =>
      'Dieses Meeting scheint vorbei zu sein. Aufzeichnung stoppen?';

  @override
  String get meetingAutoStopStop => 'Stoppen';

  @override
  String get meetingAutoStopKeep => 'Weiter aufzeichnen';

  @override
  String get meetingAutoDetect => 'Meetings automatisch erkennen';

  @override
  String get meetingAutoDetectDescription =>
      'Beobachtet Kalender und Konferenz-Apps und bietet an, eine Aufzeichnung zu starten, wenn ein Meeting beginnt.';

  @override
  String get meetingsRecordingCrumb => 'Aufnahme…';

  @override
  String get meetingRecordTitleHint => 'Besprechungstitel';

  @override
  String get meetingRecordTappingLabel => 'Abgriff:';

  @override
  String get meetingRecordMic => 'Mikro';

  @override
  String get meetingRecordSystemAudio => 'Systemaudio';

  @override
  String get meetingRecordPause => 'Pause';

  @override
  String get meetingRecordResume => 'Fortsetzen';

  @override
  String get meetingRecordStop => 'Stoppen und zusammenfassen';

  @override
  String get meetingRecordYourNotes => 'Deine Notizen';

  @override
  String get meetingRecordNotesPlaceholder =>
      'Schreib mit, während du zuhörst. Ein paar Fragmente genügen — nach dem Stopp erweitert der Agent sie anhand des Transkripts.';

  @override
  String get meetingRecordLiveTranscript => 'Live-Transkript';

  @override
  String get meetingRecordDecoding => 'Dekodierung auf dem Gerät';

  @override
  String get meetingRecordListening =>
      'Höre zu… Sprache erscheint hier in ein, zwei Sekunden, gekennzeichnet als Du / Andere.';

  @override
  String get meetingRecordPausedHint =>
      'Pausiert — Audio wird ignoriert, bis du fortsetzt.';

  @override
  String get meetingRecordNotActive => 'Keine aktive Aufnahme.';

  @override
  String get meetingHudRecording => 'Aufnahme';

  @override
  String get meetingHudPaused => 'pausiert';

  @override
  String get meetingHudOpen => 'Öffnen';

  @override
  String get meetingHudStop => 'Stoppen';

  @override
  String get meetingToolbarPopOut => 'Ablösen';

  @override
  String get meetingToolbarHoldToStop => 'Zum Stoppen der Aufnahme halten';

  @override
  String get meetingToolbarSemanticLabel => 'Leiste für Besprechungsaufnahme';

  @override
  String get orchestrate => 'Orchestrieren';

  @override
  String get orchestrationUnavailable => 'Orchestrierung nicht verfügbar';

  @override
  String get orchestrationApprove => 'Plan genehmigen';

  @override
  String get orchestrationReject => 'Ablehnen';

  @override
  String get orchestrationCancel => 'Orchestrierung abbrechen';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count Rollen — $hires neue Einstellungen';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count Unter-Tickets';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'Geschätzte Kosten: $amount \$';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total Unter-Tickets erledigt';
  }

  @override
  String get orchestrationStatusProposed => 'Vorgeschlagen';

  @override
  String get orchestrationStatusApproved => 'Genehmigt';

  @override
  String get orchestrationStatusExecuting => 'Läuft';

  @override
  String get orchestrationStatusSynthesizing => 'Synthese';

  @override
  String get orchestrationStatusCompleted => 'Abgeschlossen';

  @override
  String get orchestrationStatusFailed => 'Fehlgeschlagen';

  @override
  String get orchestrationStatusCancelled => 'Abgebrochen';

  @override
  String get messageFailed => 'Lauf fehlgeschlagen';

  @override
  String get turnLimitReached =>
      'Rundenlimit erreicht — antworte, um fortzufahren';

  @override
  String get retried => 'Erneut versucht';

  @override
  String replyingTo(String name) {
    return 'als Antwort an $name';
  }

  @override
  String get silenceTimeoutLabel => 'Stille-Timeout (Minuten)';

  @override
  String get silenceTimeoutHint =>
      'z. B. 15 — beendet einen Lauf nach dieser Zeit ohne Ausgabe';

  @override
  String get capabilityJsonMode => 'JSON-Modus';

  @override
  String get capabilityModelSelection => 'Modellauswahl';

  @override
  String get transcriptThinking => 'Denkt nach…';

  @override
  String transcriptThoughtFor(String duration) {
    return 'Nachgedacht für $duration';
  }

  @override
  String get transcriptStatusMakingEdits => 'Nimmt Änderungen vor…';

  @override
  String get transcriptStatusReadingFiles => 'Liest Dateien…';

  @override
  String get transcriptStatusSearching => 'Durchsucht Codebasis…';

  @override
  String get transcriptStatusRunningCommands => 'Führt Befehle aus…';

  @override
  String get transcriptStatusResponding => 'Antwortet…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return 'Führt $tool aus…';
  }

  @override
  String get transcriptInput => 'Eingabe';

  @override
  String get transcriptOutput => 'Ausgabe';

  @override
  String get transcriptErrorLabel => 'Fehler';

  @override
  String get transcriptSandboxBlocked => 'Sandbox hat eine Aktion blockiert';

  @override
  String transcriptShowFullOutput(int kb) {
    return 'Vollständige Ausgabe anzeigen (+$kb KB)';
  }

  @override
  String transcriptShowAllLines(int count) {
    return 'Alle $count Zeilen anzeigen';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return 'Erste $count Zeilen werden angezeigt';
  }

  @override
  String get transcriptGrepNoMatches => 'Keine Treffer';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '$matches Treffer',
      one: '1 Treffer',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files Dateien',
      one: '1 Datei',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return 'Person $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => 'Sprecher umbenennen';

  @override
  String get meetingRenameSpeakerTitle => 'Sprecher umbenennen';

  @override
  String get meetingSpeakerNameLabel => 'Name';

  @override
  String get meetingSpeakerSuggestFromCalendar =>
      'Aus den Eingeladenen dieses Meetings';

  @override
  String get meetingRenameSpeakerApplyAll =>
      'Auf alle Blöcke dieses Sprechers anwenden';

  @override
  String get meetingRenameSpeakerScopeHint =>
      'Wenn deaktiviert, wird nur die ausgewählte Zeile umbenannt.';

  @override
  String get meetingLinkEvent => 'Mit Termin verknüpfen';

  @override
  String get meetingChangeEvent => 'Termin ändern';

  @override
  String get meetingLinkEventTitle => 'Mit einem Kalendertermin verknüpfen';

  @override
  String get meetingLinkEventSearchHint => 'Termine suchen';

  @override
  String get meetingLinkEventEmpty => 'Keine Kalendertermine in der Nähe';

  @override
  String get meetingUnlinkEvent => 'Verknüpfung entfernen';

  @override
  String get calendarLinkExistingMeeting =>
      'Mit bestehendem Meeting verknüpfen';

  @override
  String get calendarLinkMeetingTitle => 'Meeting verknüpfen';

  @override
  String get calendarLinkMeetingSearchHint => 'Meetings suchen';

  @override
  String get calendarLinkMeetingEmpty => 'Keine Meetings zum Verknüpfen';

  @override
  String get meetingRenameSpeakerFailed =>
      'Sprecher konnte nicht umbenannt werden';

  @override
  String get calendarLinkUpdateFailed =>
      'Kalenderverknüpfung konnte nicht aktualisiert werden';

  @override
  String get rename => 'Umbenennen';

  @override
  String get notNow => 'Jetzt nicht';

  @override
  String get meetingSaveVoiceProfileTitle => 'Stimmprofil speichern?';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return '$name in künftigen Meetings automatisch erkennen, indem der Stimmabdruck gespeichert wird.';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return 'Stimmprofil für $name gespeichert';
  }

  @override
  String get meetingVoiceProfileSaveFailed =>
      'Stimmprofil konnte nicht gespeichert werden';

  @override
  String get voiceProfilesSection => 'Stimmprofile';

  @override
  String get voiceProfilesDescription =>
      'Gespeicherte Stimmen werden in künftigen Meetings automatisch erkannt.';

  @override
  String get voiceProfilesEmpty =>
      'Noch keine gespeicherten Stimmen. Benenne eine sprechende Person in einem Meeting-Transkript und wähle „Stimmprofil speichern“.';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Proben',
      one: '1 Probe',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => 'Stimmprofil umbenennen';

  @override
  String get deleteVoiceProfileTitle => 'Stimmprofil löschen?';

  @override
  String deleteVoiceProfileBody(String name) {
    return '$name nicht mehr erkennen? Der gespeicherte Stimmabdruck wird entfernt. Bereits in vergangenen Meetings angewendete Namen bleiben erhalten.';
  }

  @override
  String get connectedLabel => 'Verbunden';

  @override
  String get ideTabGeneral => 'Allgemein';

  @override
  String get ideTabExplorer => 'Explorer';

  @override
  String get ideTabSourceControl => 'Quellcodeverwaltung';

  @override
  String get generalSectionTodos => 'Aufgaben';

  @override
  String get generalSectionGoals => 'Ziele';

  @override
  String get goalRunStatusActive => 'Aktiv';

  @override
  String get goalRunStatusPaused => 'Pausiert';

  @override
  String get goalRunStatusCompleted => 'Abgeschlossen';

  @override
  String get goalRunStatusFailed => 'Fehlgeschlagen';

  @override
  String get goalRunStatusCancelled => 'Abgebrochen';

  @override
  String get goalRunStatusBudgetExhausted => 'Budget erschöpft';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return 'Lauf $run von $max · $cost von $cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return 'Lauf $run · $cost von $cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return 'Fällig: $deadline';
  }

  @override
  String get goalRunPause => 'Ziel pausieren';

  @override
  String get goalRunResume => 'Ziel fortsetzen';

  @override
  String goalRunResumeRaise(String cap) {
    return 'Fortsetzen · Limit auf $cap erhöhen';
  }

  @override
  String get goalRunStop => 'Ziel stoppen';

  @override
  String get generalSectionAgents => 'Agenten';

  @override
  String get generalSectionTerminals => 'Terminals';

  @override
  String get generalTodosEmpty => 'Noch keine Aufgaben';

  @override
  String get generalAgentsEmpty => 'Keine Agenten aktiv';

  @override
  String get generalTerminalsEmpty => 'Keine Terminals geöffnet';

  @override
  String get generalSectionBrowsers => 'Browser';

  @override
  String get generalSectionComputers => 'Computer';

  @override
  String get generalBrowsersEmpty => 'Keine Browser geöffnet';

  @override
  String get generalComputersEmpty => 'Keine Computer geöffnet';

  @override
  String get generalSectionPhones => 'Telefone';

  @override
  String get generalPhonesEmpty => 'Keine Telefone geöffnet';

  @override
  String get pauseAgent => 'Agent pausieren';

  @override
  String get resumeAgent => 'Agent fortsetzen';

  @override
  String get agentCannotPause =>
      'Dieser Agent kann nicht pausiert werden – stoppe ihn stattdessen.';

  @override
  String get goalClear => 'Ziel löschen';

  @override
  String get undoLabelGoalClear => 'Ziel löschen';

  @override
  String get todoStatusPending => 'Nicht begonnen';

  @override
  String get todoStatusInProgress => 'In Bearbeitung';

  @override
  String get todoStatusCompleted => 'Erledigt';

  @override
  String get reorderTodo => 'Aufgabe neu ordnen';

  @override
  String get focusTerminal => 'Terminal fokussieren';

  @override
  String get focusMachine => 'Maschine fokussieren';

  @override
  String get focusBrowser => 'Browser fokussieren';

  @override
  String get todoEditorTitle => 'Aufgaben bearbeiten';

  @override
  String get todoEditorHint =>
      'Ein Eintrag pro Zeile. Verwende - [ ] für offen, - [~] für in Bearbeitung, - [x] für erledigt.';

  @override
  String get todoNeedsText => 'Füge Text nach dem Befehl hinzu';

  @override
  String get todoNotFound => 'Keine passende Aufgabe';

  @override
  String get todoCleared => 'Aufgabenliste geleert';

  @override
  String get todoNothingToCopy => 'Nichts zu kopieren';

  @override
  String todoAdded(String content) {
    return '\"$content\" hinzugefügt';
  }

  @override
  String todoStarted(String content) {
    return '\"$content\" gestartet';
  }

  @override
  String todoCompleted(String content) {
    return '\"$content\" abgeschlossen';
  }

  @override
  String todoRemoved(String content) {
    return '\"$content\" entfernt';
  }

  @override
  String todoCopied(int count) {
    return '$count Einträge kopiert';
  }

  @override
  String todoImported(int count) {
    return '$count Einträge importiert';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return 'Unbekannter Aufgabenbefehl \"$name\"';
  }

  @override
  String get terminal => 'Terminal';

  @override
  String get ideCloseTab => 'Tab schließen';

  @override
  String get ideSplitEditor => 'Editor teilen';

  @override
  String get ideSplitRight => 'Nach rechts teilen';

  @override
  String get ideSplitDown => 'Nach unten teilen';

  @override
  String get ideSplitLeft => 'Nach links teilen';

  @override
  String get ideSplitUp => 'Nach oben teilen';

  @override
  String get ideCloseGroup => 'Gruppe schließen';

  @override
  String get ideCloseOthers => 'Andere schließen';

  @override
  String get ideCloseToRight => 'Rechts schließen';

  @override
  String get ideCloseSaved => 'Gespeicherte schließen';

  @override
  String get ideCloseAll => 'Alle schließen';

  @override
  String get ideSplit => 'Teilen';

  @override
  String get ideToggleSidebar => 'Seitenleiste ein/ausblenden';

  @override
  String get ideNewTab => 'Editor öffnen';

  @override
  String get ideNewTabMenu => 'Neuer Tab';

  @override
  String get ideReviewCode => 'Code überprüfen';

  @override
  String get ideRevert => 'Zurücksetzen';

  @override
  String get ideRevertConfirmTitle => 'Änderungen zurücksetzen';

  @override
  String ideRevertConfirmMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien',
      one: '1 Datei',
    );
    return '$_temp0 auf HEAD zurücksetzen? Dies verwirft Arbeitsbaum-Änderungen.';
  }

  @override
  String get ideRevertConfirmAction => 'Zurücksetzen';

  @override
  String get ideRevertConfirmCancel => 'Abbrechen';

  @override
  String get ideRevertUntracked =>
      'Nicht versionierte Dateien können nicht zurückgesetzt werden';

  @override
  String get ideRevertFailed =>
      'Dateien konnten nicht zurückgesetzt werden. Der Arbeitsbaum der Konversation ist möglicherweise nicht verfügbar.';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien',
      one: '1 Datei',
    );
    return '$_temp0 konnte(n) nicht zurückgesetzt werden (nicht versioniert).';
  }

  @override
  String get ideViewSource => 'Quelle anzeigen';

  @override
  String get ideSearchMatchCase => 'Groß-/Kleinschreibung';

  @override
  String get ideSearchWholeWord => 'Ganzes Wort';

  @override
  String get ideSearchRegex => 'Regex';

  @override
  String get ideSearchFilters => 'Suchfilter';

  @override
  String get ideSearchFilesToInclude => 'Einzuschließende Dateien';

  @override
  String get ideSearchFilesToExclude => 'Auszuschließende Dateien';

  @override
  String get ideNoOpenTabs => 'Keine offenen Tabs — + zum Öffnen verwenden';

  @override
  String get ideBrowserAddressHint => 'Adresse eingeben oder suchen';

  @override
  String get ideSimpleWebBrowser => 'Einfacher Webbrowser';

  @override
  String get ideWebBrowser => 'Webbrowser';

  @override
  String get ideBrowserEnterUrl =>
      'Gib eine URL in die Adressleiste ein, um zu surfen';

  @override
  String get ideCodeServer => 'Editor';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return 'Änderungen an $fileName speichern?';
  }

  @override
  String get ideUnsavedChangesBody =>
      'Deine Änderungen gehen verloren, wenn du sie nicht speicherst.';

  @override
  String get ideDontSave => 'Nicht speichern';

  @override
  String get editorAutoSave => 'Automatisch speichern';

  @override
  String get editorAutoSaveDescription =>
      'Änderungen im eingebetteten Editor automatisch speichern.';

  @override
  String get editorAutoSaveOff => 'Aus';

  @override
  String get editorAutoSaveAfterDelay => 'Nach Verzögerung';

  @override
  String get editorAutoSaveOnFocusChange => 'Bei Fokuswechsel';

  @override
  String get ideCodeServerUnavailable =>
      'Code-server ist auf diesem Server nicht verfügbar';

  @override
  String get ideCodeServerUnavailableHint =>
      'Installiere code-server (coder/code-server) auf dem Server-Host und öffne den Editor erneut.';

  @override
  String get ideCodeServerInstalling => 'Editor wird vorbereitet…';

  @override
  String get ideCodeServerOpenInBrowser => 'Editor im Browser öffnen';

  @override
  String get ideCodeServerError => 'Editor konnte nicht geöffnet werden';

  @override
  String get paneSuspendedCaption =>
      'Angehalten, um Ressourcen zu sparen — wird beim Fokussieren neu geladen';

  @override
  String get ideFolderLoadFailed => 'Ordner konnte nicht geladen werden';

  @override
  String get ideFileSearchFailed => 'Dateisuche fehlgeschlagen';

  @override
  String get ideSearchInFiles => 'In Dateien suchen';

  @override
  String get ideNoContentMatches => 'Keine Treffer';

  @override
  String get ideSourceControlCreatePr => 'Pull Request erstellen';

  @override
  String ideSourceControlViewPr(int number) {
    return 'Pull Request #$number anzeigen';
  }

  @override
  String get ideSourceControlNoChanges => 'Keine Änderungen';

  @override
  String get noReposInConversation =>
      'Keine Repositorys in dieser Unterhaltung';

  @override
  String get ideSourceControlNoSpace =>
      'Öffne eine Unterhaltung, um ihre Änderungen zu sehen';

  @override
  String get ideFileLoading => 'Laden…';

  @override
  String get ideFileBinary => 'Binärdatei';

  @override
  String get mcpExternalServers => 'Externe MCP-Server';

  @override
  String get mcpExternalServersDescription =>
      'Verbinde dich mit externen MCP-Servern (GitHub, Sentry, Postgres, Browser-Automatisierung). Server, die du für Claude, Cursor, VS Code und andere Tools konfiguriert hast, werden automatisch erkannt.';

  @override
  String get mcpApprovalMode => 'Tool-Freigabe';

  @override
  String get mcpApprovalModeDescription =>
      'Welche Aktionen ohne Rückfrage laufen. Lesezugriffe sind immer erlaubt; höhere Stufen fragen nach.';

  @override
  String get mcpApprovalAlwaysAsk => 'Immer fragen';

  @override
  String get mcpApprovalWrite => 'Schreibzugriffe freigeben';

  @override
  String get mcpApprovalYolo => 'Alles freigeben';

  @override
  String get mcpNoExternalServers => 'Keine externen MCP-Server gefunden.';

  @override
  String get mcpAuthorize => 'Autorisieren';

  @override
  String get mcpReconnect => 'Erneut verbinden';

  @override
  String get mcpExternalConnectionsNote =>
      'Externe MCP-Server laufen auf dem Agent-Server (von Desktop und Web gemeinsam genutzt). Das Autorisieren von OAuth-Servern ist nur auf dem Desktop verfügbar.';

  @override
  String get mcpStatusConnected => 'Verbunden';

  @override
  String get mcpStatusConnecting => 'Verbinden…';

  @override
  String get mcpStatusNeedsAuth => 'Autorisierung erforderlich';

  @override
  String get mcpStatusFailed => 'Fehlgeschlagen';

  @override
  String get mcpStatusCircuitOpen => 'Pausiert';

  @override
  String get mcpStatusDisabled => 'Deaktiviert';

  @override
  String get providersAndModels => 'Anbieter & Modelle';

  @override
  String get providersAndModelsDescription =>
      'Liste jeden Anbieter auf, den der integrierte Agent verwenden kann – lege einen API-Schlüssel fest oder melde dich per Browser an, sieh dir Modelle und Preise jedes verbundenen Anbieters an und steuere, welche Anbieter dieser Workspace verwenden darf.';

  @override
  String get syncNow => 'Jetzt sync.';

  @override
  String syncNowResult(int applied, int failed) {
    return 'Synchronisierung abgeschlossen — $applied angewendet, $failed fehlgeschlagen';
  }

  @override
  String syncNowFailed(String error) {
    return 'Synchronisierung fehlgeschlagen: $error';
  }

  @override
  String get denied => 'Abgelehnt';

  @override
  String get allowed => 'Erlaubt';

  @override
  String allowProviderSemantic(String provider) {
    return '$provider erlauben';
  }

  @override
  String enabledViaEnv(String key) {
    return 'Aktiviert über $key';
  }

  @override
  String costPerMillion(String input, String output) {
    return '$input / $output pro 1M';
  }

  @override
  String contextTokens(String tokens) {
    return '$tokens Kontext';
  }

  @override
  String get usageAndCost => 'Nutzung & Kosten';

  @override
  String get usageAndCostDescription =>
      'Ausgaben deiner Agenten der letzten 7 Tage, basierend auf beobachteten Laufkosten.';

  @override
  String get noUsageYet => 'Noch keine Nutzung erfasst.';

  @override
  String get spentThisWeek => 'diese Woche ausgegeben';

  @override
  String get subscriptionUsage => 'Abo-Nutzung';

  @override
  String get subscriptionUsageUnavailable => 'Nicht verfügbar';

  @override
  String get subscriptionUsageExhausted => 'Kontingent aufgebraucht';

  @override
  String get subscriptionUsageSignInRequired => 'Erneut anmelden';

  @override
  String get subscriptionUsageSignInExpired =>
      'Anmeldung abgelaufen, erneuert sich beim nächsten Lauf';

  @override
  String get subscriptionUsagePartiallyAvailable => 'Teilweise verfügbar';

  @override
  String resetsIn(String duration) {
    return 'Zurücksetzung in $duration';
  }

  @override
  String get feedbackHelpful => 'Das war hilfreich';

  @override
  String get feedbackNotHelpful => 'Das war nicht hilfreich';

  @override
  String get modeChat => 'Chat';

  @override
  String get modePlan => 'Plan';

  @override
  String get modeReview => 'Überprüfung';

  @override
  String get modeOrchestrate => 'Orchestrierung';

  @override
  String get editorTheme => 'Editor-Thema';

  @override
  String get editorThemeDescription =>
      'Importiere ein VS-Code-Farbthema, damit das eingebettete Diff und der Editor zu deiner IDE passen.';

  @override
  String get editorThemePasteHint =>
      'Füge den Inhalt einer VS-Code-Farbthema-JSON-Datei ein';

  @override
  String get editorThemeImported => 'Thema importiert';

  @override
  String get editorThemeInvalid =>
      'Das sieht nicht nach einem gültigen VS-Code-Thema aus';

  @override
  String get importTheme => 'Thema importieren';

  @override
  String get clearTheme => 'Thema löschen';

  @override
  String get openInDiffViewer => 'Im Diff-Viewer öffnen';

  @override
  String get shellCommand => 'Befehl';

  @override
  String get shellOutput => 'Ausgabe';

  @override
  String get revertToHere => 'Hierher zurücksetzen';

  @override
  String get revertConfirmBody =>
      'Die Nachrichten nach diesem Punkt ausblenden und die Dateiänderungen des Agenten auf diesen Schritt zurücksetzen? Du kannst dies rückgängig machen.';

  @override
  String get revert => 'Zurücksetzen';

  @override
  String get revertedToHere => 'Auf diesen Punkt zurückgesetzt';

  @override
  String get nothingToRevert => 'Nichts zum Zurücksetzen';

  @override
  String get undoRevert => 'Zurücksetzen rückgängig machen';

  @override
  String get revertUndone => 'Zurücksetzen rückgängig gemacht';

  @override
  String get systemBehavior => 'Systemverhalten';

  @override
  String get keepAwakeTitle => 'Computer wach halten, während Agenten laufen';

  @override
  String get keepAwakeOnSubtitle =>
      'Der Computer wechselt nicht in den Ruhezustand, während ein Agent arbeitet';

  @override
  String get keepAwakeOffSubtitle =>
      'Der Computer kann in den Ruhezustand wechseln, auch während ein Agent arbeitet';

  @override
  String get syncEngineSectionTitle => 'Sync-Engine';

  @override
  String get syncEngineDescription =>
      'Tickets, Nachrichten und Notizen werden live über kleine inkrementelle Änderungen aktualisiert statt über vollständige Snapshots. Das Deaktivieren eines Schalters versetzt diesen Speicher zurück in den Vollständige-Snapshot-Modus – starte die App neu, damit die Änderung wirksam wird.';

  @override
  String get syncEngineTicketsTitle => 'Tickets';

  @override
  String get syncEngineMessagingTitle => 'Nachrichten';

  @override
  String get syncEngineNotesTitle => 'Notizen';

  @override
  String get syncEngineOnSubtitle => 'Live-Delta-Synchronisierung ist aktiv';

  @override
  String get syncEngineOffSubtitle =>
      'Vollständige Snapshot-Synchronisierung wird verwendet';

  @override
  String get spaces => 'Bereiche';

  @override
  String get spacesHomeDescription =>
      'Wähle einen Bereich aus der Liste oder starte einen neuen.';

  @override
  String get noSpacesYet => 'Noch keine Bereiche';

  @override
  String get newSpace => 'Neuer Bereich';

  @override
  String get spaceName => 'Bereichsname';

  @override
  String get spaceReposHint => 'Einzubeziehende Repos';

  @override
  String get ideSourceControl => 'Quellcodeverwaltung';

  @override
  String get stagedChanges => 'Bereitgestellte Änderungen';

  @override
  String get changes => 'Änderungen';

  @override
  String get stageFile => 'Bereitstellen';

  @override
  String get unstageFile => 'Bereitstellung aufheben';

  @override
  String get stageAll => 'Alle Änderungen bereitstellen';

  @override
  String get unstageAll => 'Gesamte Bereitstellung aufheben';

  @override
  String get stageChangesToCommit => 'Änderungen zum Commit bereitstellen';

  @override
  String get syncToPrHead => 'Neueste PR-Commits abrufen';

  @override
  String get syncedToPrHead => 'Mit den neuesten PR-Commits synchronisiert';

  @override
  String get syncPrHeadDirty =>
      'Änderungen vor dem Synchronisieren committen oder verwerfen';

  @override
  String get syncPrHeadFailed => 'Synchronisierung mit der PR fehlgeschlagen';

  @override
  String get spaceLabel => 'Bereich';

  @override
  String get keybindingNewSpace => 'Neuer Bereich';

  @override
  String get keybindingCreateANewSpaceDescription =>
      'Einen neuen Bereich erstellen';

  @override
  String get jumpToLatest => 'Zum neuesten springen';

  @override
  String get streaming => 'Wird übertragen';

  @override
  String get newMessages => 'Neu';

  @override
  String get copyLink => 'Link kopieren';

  @override
  String get linkCopied => 'Link kopiert';

  @override
  String get agentResponding => 'Agent antwortet';

  @override
  String get agentFinished => 'Agent fertig';

  @override
  String get harnessConnectProviderForModels =>
      'Verbinde einen Anbieter, um Modelle zu sehen.';

  @override
  String get providerSignOut => 'Abmelden';

  @override
  String get providerWaitingForDeviceCode =>
      'Warten auf die Bestätigung des Codes im Browser…';

  @override
  String get providerDeviceCodeHint =>
      'Prüfe, ob dieser Code mit dem im Browser übereinstimmt, und bestätige dann.';

  @override
  String get providerPlanUsageLoading => 'Tarifnutzung wird geprüft…';

  @override
  String get providerPlanUsageUnavailable =>
      'Dieser Tarif hat keine Nutzung gemeldet.';

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return '$provider-API-Schlüssel entfernen?';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return 'Der gespeicherte Schlüssel wird gelöscht und kann nicht erneut angezeigt werden. Agenten mit $provider-Modellen funktionieren erst wieder, wenn du einen neuen einfügst.';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return '$provider entfernen?';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return 'Der Anbieter und sein gespeicherter Schlüssel werden gelöscht. Agenten, die an seine Modelle gebunden sind, funktionieren nicht mehr.';
  }

  @override
  String get providerApiKeyHint => 'API-Schlüssel einfügen';

  @override
  String get providerApiKeyStoredHint =>
      'Füge einen weiteren API-Schlüssel ein, um ihn hinzuzufügen';

  @override
  String get providerAddAnotherAccount => 'Weiteres Konto hinzufügen';

  @override
  String get providerActiveBadge => 'Aktiv';

  @override
  String get providerOauthAccountFallback => 'OAuth-Konto';

  @override
  String get providerApiKeyFallback => 'API-Schlüssel';

  @override
  String get providerRemoveCredentialConfirmTitle =>
      'Diese Zugangsdaten entfernen?';

  @override
  String get providerSignOutAccountConfirmTitle => 'Von diesem Konto abmelden?';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return 'Agenten, die $provider nutzen, weichen auf dessen andere Schlüssel und Konten aus. Ist keines mehr übrig, stoppen sie, bis du eines hinzufügst.';
  }

  @override
  String get providerBaseUrlHint => 'Basis-URL (optional)';

  @override
  String get customProvidersDescription =>
      'Jeder OpenAI- oder Anthropic-kompatible Endpunkt — Ollama, LM Studio, vLLM oder ein privates Deployment — mit optionalem API-Schlüssel.';

  @override
  String get addProvider => 'Anbieter hinzufügen';

  @override
  String get noCustomProviders => 'Noch keine benutzerdefinierten Anbieter.';

  @override
  String get providerNameLabel => 'Name';

  @override
  String get apiTypeLabel => 'API-Typ';

  @override
  String get providerBaseUrlLabel => 'Basis-URL';

  @override
  String get providerApiKeyOptionalHint => 'API-Schlüssel (optional)';

  @override
  String get dialectOpenAiCompatible => 'OpenAI-kompatibel';

  @override
  String get dialectAnthropicCompatible => 'Anthropic-kompatibel';

  @override
  String get removeProviderTooltip => 'Anbieter entfernen';

  @override
  String get providerLogInWithBrowser => 'Mit Browser anmelden';

  @override
  String providerLoginDialogTitle(String provider) {
    return 'Bei $provider anmelden';
  }

  @override
  String get providerLabel => 'Anbieter';

  @override
  String get selectProviderToLogin => 'Wähle einen Anbieter zum Anmelden';

  @override
  String providerLoginFailed(String error) {
    return 'Anmeldung fehlgeschlagen: $error';
  }

  @override
  String get providerWaitingForBrowser =>
      'Warte auf deine Autorisierung im Browser…';

  @override
  String get providerPasteCodeHint =>
      'Oder füge den Code aus deinem Browser ein';

  @override
  String get providerCompleteLogin => 'Abschließen';

  @override
  String get providerConnectedApiKey => 'Verbunden über API-Schlüssel';

  @override
  String get providerConnectedOauth => 'Verbunden';

  @override
  String providerConnectedAccount(String account) {
    return 'Verbunden · $account';
  }

  @override
  String get providerLocalReady => 'Lokal · bereit';

  @override
  String get providerNotConnected => 'Nicht verbunden';

  @override
  String get preparingWorkspace => 'Arbeitsbereich wird vorbereitet…';

  @override
  String provisioningRunningSetupScript(String repo) {
    return 'Setup-Skript für $repo wird ausgeführt…';
  }

  @override
  String get repoScriptsTitle => 'Skripte';

  @override
  String get repoScriptsTooltip => 'Lebenszyklus-Skripte konfigurieren';

  @override
  String get repoScriptsSetupLabel => 'Setup-Skript';

  @override
  String get repoScriptsSetupHelp =>
      'Wird direkt nach dem Erstellen im Worktree des Raums ausgeführt — Abhängigkeiten installieren, Dateien generieren. Ein Fehlschlag markiert den Raum als fehlgeschlagen; ein erneuter Versuch führt es wieder aus.';

  @override
  String get repoScriptsArchiveLabel => 'Archivierungsskript';

  @override
  String get repoScriptsArchiveHelp =>
      'Wird direkt vor dem Löschen des Worktrees eines Raums ausgeführt — räumt Ressourcen außerhalb des Worktrees auf. Ein Fehlschlag blockiert das Löschen nie.';

  @override
  String get repoScriptsEnvHelp =>
      'Wird per bash aus dem Worktree ausgeführt, mit CC_WORKSPACE_PATH (der Worktree), CC_ROOT_PATH (die Repo-Wurzel), CC_SPACE_ID, CC_SPACE_NAME und CC_REPO_NAME.';

  @override
  String get repoScriptsSetupPlaceholder => 'z. B. pnpm install';

  @override
  String get repoScriptsArchivePlaceholder =>
      'z. B. docker compose -p \$CC_SPACE_ID down';

  @override
  String get repoScriptsRecentRuns => 'Letzte Ausführungen';

  @override
  String get repoScriptsNoRuns => 'Noch keine Ausführungen';

  @override
  String get repoScriptsOutput => 'Ausgabe';

  @override
  String get repoScriptsSaved => 'Skripte gespeichert';

  @override
  String get repoScriptsRunKindSetup => 'Setup';

  @override
  String get repoScriptsRunKindArchive => 'Archivierung';

  @override
  String get repoScriptsRunStatusRunning => 'Läuft';

  @override
  String get repoScriptsRunStatusSucceeded => 'Erfolgreich';

  @override
  String get repoScriptsRunStatusFailed => 'Fehlgeschlagen';

  @override
  String get repoScriptsRunStatusTimedOut => 'Zeitüberschreitung';

  @override
  String repoScriptsExitCode(int code) {
    return 'Exit-Code $code';
  }

  @override
  String provisioningCloningRepo(String repo) {
    return '$repo wird geklont…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return 'Pull Request wird in $repo ausgecheckt…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return 'Agent $agent wird eingerichtet…';
  }

  @override
  String get workspacePrepFailed => 'Einrichtung fehlgeschlagen';

  @override
  String get workspacePrepStopped => 'Einrichtung gestoppt';

  @override
  String get stopWorkspacePrep => 'Einrichtung stoppen';

  @override
  String get stopWorkspacePrepTooltip =>
      'Einrichtung dieses Arbeitsbereichs stoppen';

  @override
  String get stopWorkspacePrepConfirm =>
      'Einrichtung dieses Arbeitsbereichs stoppen? Das laufende Klonen wird verworfen – du kannst es hier neu starten.';

  @override
  String messageWillSendWhenReady(int count) {
    return '$count Nachricht(en) gesendet sobald bereit';
  }

  @override
  String get membersNav => 'Mitglieder';

  @override
  String get membersSettingsDescription =>
      'Personen mit Zugriff auf diesen Arbeitsbereich: Liste, Einladungen und Prüfprotokoll';

  @override
  String get memberRosterLabel => 'Mitgliederliste';

  @override
  String get memberRepoAccessAction => 'Repository-Zugriff';

  @override
  String memberRepoAccessTitle(String name) {
    return 'Repository-Zugriff für $name';
  }

  @override
  String get roleOwner => 'Eigentümer';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleMember => 'Mitglied';

  @override
  String get roleViewer => 'Betrachter';

  @override
  String get roleGuest => 'Gast';

  @override
  String get removeMemberTitle => 'Mitglied entfernen';

  @override
  String removeMemberConfirm(String name) {
    return '$name aus diesem Arbeitsbereich entfernen? Der Zugriff geht sofort verloren.';
  }

  @override
  String get transferOwnershipAction => 'Besitz übertragen';

  @override
  String get transferOwnershipTitle => 'Besitz übertragen';

  @override
  String transferOwnershipConfirm(String name) {
    return '$name zum Eigentümer dieses Arbeitsbereichs machen? Sie werden Administrator. Nur ein Eigentümer kann den Arbeitsbereich löschen oder die Rolle eines anderen Administrators ändern.';
  }

  @override
  String get transferOwnershipCta => 'Übertragen';

  @override
  String get auditTrailLabel => 'Audit-Protokoll der Berechtigungen';

  @override
  String get auditTrailDescription =>
      'Jede Freigabe und jede Ablehnung, per Hash verkettet: ein geänderter oder gelöschter Eintrag ist erkennbar.';

  @override
  String get auditVerifyChain => 'Kette prüfen';

  @override
  String auditChainIntact(int count) {
    return 'Kette intakt — $count Einträge geprüft';
  }

  @override
  String auditChainBroken(int seq, String reason) {
    return 'Kette bei Eintrag $seq unterbrochen: $reason';
  }

  @override
  String get auditEmpty => 'Noch keine Entscheidungen aufgezeichnet.';

  @override
  String get auditDenied => 'Abgelehnt';

  @override
  String get auditAllowed => 'Zugelassen';

  @override
  String auditOnBehalfOf(String user) {
    return 'für $user';
  }

  @override
  String get policyTemplatesLabel => 'Richtlinienvorlagen';

  @override
  String get policyTemplatesDescription =>
      'Wenden Sie eine Ausgangskonfiguration an oder übertragen Sie sie zwischen Arbeitsbereichen.';

  @override
  String get policyTemplateStrict => 'Streng';

  @override
  String get policyTemplateBalanced => 'Ausgewogen';

  @override
  String get policyTemplatePermissive => 'Freizügig';

  @override
  String get policyTemplateApply => 'Anwenden';

  @override
  String policyTemplateApplied(int count) {
    return '$count Regeln angewendet';
  }

  @override
  String get policyExport => 'Richtlinie kopieren';

  @override
  String get policyExported => 'Richtlinie in die Zwischenablage kopiert';

  @override
  String get policyImport => 'Richtlinie einfügen';

  @override
  String policyImported(int count) {
    return '$count Regeln importiert';
  }

  @override
  String get approveAndRemember => 'Für 8 Stunden freigeben';

  @override
  String get approveAndRememberTooltip =>
      'Gibt diese Aktion frei und fragt 8 Stunden lang nicht mehr nach ähnlichen Aktionen in diesem Raum. Läuft von selbst ab.';

  @override
  String get unknownUserLabel => 'Unbekannter Benutzer';

  @override
  String get inviteMember => 'Mitglied einladen';

  @override
  String get inviteRepoAccessHeader => 'Repository-Zugriff';

  @override
  String get inviteRepoAccessExplainer =>
      'Nur die angehakten Repositories werden mit der eingeladenen Person geteilt, auf der gewählten Stufe. Alles andere bleibt verborgen.';

  @override
  String get grantLevelRead => 'Lesen';

  @override
  String get grantLevelReview => 'Review';

  @override
  String get grantLevelWrite => 'Schreiben';

  @override
  String get inviteExpiryLabel => 'Läuft ab in';

  @override
  String get expiryOneDay => '1 Tag';

  @override
  String get expirySevenDays => '7 Tage';

  @override
  String get expiryThirtyDays => '30 Tage';

  @override
  String get createInviteAction => 'Einladung erstellen';

  @override
  String get inviteOneTimeCodeLabel => 'Einmalcode';

  @override
  String get inviteCodeShownOnce =>
      'Dieser Code wird nur einmal angezeigt — jetzt kopieren.';

  @override
  String get inviteLinkLabel => 'Einladungslink';

  @override
  String get inviteRedeemHint =>
      'Teilen Sie den Code mit der eingeladenen Person; sie löst ihn über Ihre Server-URL ein.';

  @override
  String get inviteScanQr => 'Oder zum Einlösen scannen';

  @override
  String get inviteLoopbackWarningTitle =>
      'Die Einladung verweist auf eine lokale Adresse';

  @override
  String get inviteLoopbackWarningBody =>
      'Mitwirkende auf anderen Computern können diesen Server nicht erreichen. Starten Sie einen Tunnel (Einstellungen → Integrationen → Diesen Server freigeben) oder binden Sie ihn an Ihr Netzwerk, damit externe Benutzer eine Verbindung herstellen können.';

  @override
  String get inviteStatusOpen => 'Offen';

  @override
  String get inviteStatusUsed => 'Verwendet';

  @override
  String get inviteStatusRevoked => 'Widerrufen';

  @override
  String get inviteStatusExpired => 'Abgelaufen';

  @override
  String inviteCreatedTime(String time) {
    return 'Erstellt $time';
  }

  @override
  String inviteExpiresOn(String date) {
    return 'läuft ab am $date';
  }

  @override
  String get noActivityYet => 'Noch keine Aktivität';

  @override
  String get couldNotLoadMembers => 'Mitglieder konnten nicht geladen werden';

  @override
  String get couldNotLoadInvites => 'Einladungen konnten nicht geladen werden';

  @override
  String get couldNotLoadActivity => 'Aktivität konnte nicht geladen werden';

  @override
  String get yourDevices => 'Ihre Geräte';

  @override
  String get yourDevicesDescription =>
      'Mit Ihrem Konto auf diesem Server gekoppelte Clients.';

  @override
  String get noOwnDevices => 'Noch keine Geräte mit Ihrem Konto gekoppelt';

  @override
  String get renameDeviceTitle => 'Gerät umbenennen';

  @override
  String get revokeDeviceTitle => 'Gerät widerrufen';

  @override
  String revokeDeviceConfirm(String label) {
    return '$label widerrufen? Das Gerät wird sofort getrennt und kann diesen Server nicht mehr erreichen.';
  }

  @override
  String devicePairedTime(String time) {
    return 'Gekoppelt $time';
  }

  @override
  String deviceLastSeenTime(String time) {
    return 'Zuletzt gesehen $time';
  }

  @override
  String get deviceNeverSeen => 'Nie verbunden';

  @override
  String get profileSectionLabel => 'Profil';

  @override
  String get profileSectionDescription =>
      'So erscheinen Sie für Teammitglieder und in der Git-Commit-Urheberschaft.';

  @override
  String get displayNameLabel => 'Anzeigename';

  @override
  String get emailLabel => 'E-Mail';

  @override
  String get gitAuthorNameLabel => 'Git-Autorname';

  @override
  String get gitAuthorEmailLabel => 'Git-Autor-E-Mail';

  @override
  String get profileSaved => 'Profil gespeichert';

  @override
  String get presenceOnline => 'Online';

  @override
  String get presenceIdle => 'Inaktiv';

  @override
  String get presenceTyping => 'Schreibt…';

  @override
  String get presenceAgentThinking => 'Denkt nach';

  @override
  String get presenceAgentRunning => 'Läuft';

  @override
  String get presenceAgentBlocked => 'Blockiert';

  @override
  String get presenceAgentDone => 'Fertig';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String presenceNameStatusCost(String name, String status, String cost) {
    return '$name — $status ($cost)';
  }

  @override
  String get presenceRailLabel => 'Wer ist online';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => 'Nicht stören aktivieren';

  @override
  String get dndTooltipOff => 'Nicht stören deaktivieren';

  @override
  String get startPresenting => 'Präsentation starten';

  @override
  String get stopPresenting => 'Präsentation beenden';

  @override
  String spotlightPresentingBanner(String name) {
    return '$name präsentiert';
  }

  @override
  String get spotlightLeave => 'Verlassen';

  @override
  String typingIndicator(String name) {
    return '$name schreibt gerade…';
  }

  @override
  String get ideTabNotes => 'Notizen';

  @override
  String get ideSidebarAllViews => 'Alle Ansichten';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return 'Alle Ansichten ($count ausgeblendet)';
  }

  @override
  String get ideSidebarPinView => 'An Seitenleiste anheften';

  @override
  String get ideSidebarUnpinView => 'Von Seitenleiste lösen';

  @override
  String get notesEmptyHint =>
      'Füge eine Notiz für alle hinzu, die diese Unterhaltung übernehmen…';

  @override
  String get notesEditTooltip => 'Notiz bearbeiten';

  @override
  String notesUpdatedBy(String name, String time) {
    return 'Aktualisiert von $name · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '$name bearbeitet gerade';
  }

  @override
  String get notesSaveFailed => 'Notiz konnte nicht gespeichert werden';

  @override
  String get reactionAddTooltip => 'Reaktion hinzufügen';

  @override
  String reactionToggleTooltip(String emoji) {
    return 'Mit $emoji reagieren';
  }

  @override
  String get autonomyDialLabel => 'Autonomie';

  @override
  String get autonomyProposeOnly => 'Nur vorschlagen';

  @override
  String get autonomyActWithApproval => 'Mit Genehmigung handeln';

  @override
  String get autonomyActFreely => 'Frei handeln';

  @override
  String get autonomyDefaultOption => 'Standard';

  @override
  String get checkerLabel => 'Prüfer';

  @override
  String get checkerNone => 'Keiner';

  @override
  String get checkerCaption =>
      'Der Prüfer überprüft abgeschlossene Läufe anderer Agenten.';

  @override
  String get takeoverTooltip => 'Arbeitsverzeichnis übernehmen';

  @override
  String get takeoverBannerSelf =>
      'Du hast das Arbeitsverzeichnis dieser Unterhaltung übernommen';

  @override
  String takeoverBannerOther(String name) {
    return '$name hat das Arbeitsverzeichnis dieser Unterhaltung übernommen';
  }

  @override
  String get handBackButton => 'Zurückgeben';

  @override
  String get handBackDialogTitle => 'Arbeitsverzeichnis zurückgeben';

  @override
  String get handBackDialogNoteHint => 'Optionale Notiz für den Agenten…';

  @override
  String takeoverFailed(String message) {
    return 'Übernahme fehlgeschlagen: $message';
  }

  @override
  String handBackFailed(String message) {
    return 'Zurückgeben fehlgeschlagen: $message';
  }

  @override
  String get planStudioTitle => 'Plan-Studio';

  @override
  String get plansTitle => 'Pläne';

  @override
  String get plansSubtitle => 'Aktive Pläne, Plandokumente und Playbooks';

  @override
  String get plansActiveSection => 'Aktive Pläne';

  @override
  String get plansDocumentsSection => 'Plandokumente';

  @override
  String get plansPlaybooksSection => 'Playbooks';

  @override
  String get plansNoActive => 'Noch keine aktiven Pläne.';

  @override
  String get plansNoDocuments => 'Noch keine Plandokumente.';

  @override
  String get plansNoPlaybooks => 'Noch keine Playbooks.';

  @override
  String get planNotFound => 'Plan nicht gefunden.';

  @override
  String get planOpenInStudio => 'Öffnen';

  @override
  String get planNodeTitle => 'Titel';

  @override
  String get planNodeDescription => 'Beschreibung';

  @override
  String get planNodeDescriptionHint => 'Was dieser Schritt tun soll…';

  @override
  String get planNodeApplyDescription => 'Übernehmen';

  @override
  String get planNodeRole => 'Rolle';

  @override
  String get planNodeDependencies => 'Hängt ab von';

  @override
  String get planNodeDependenciesHint => 'Abhängigkeit hinzufügen';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Abhängigkeiten',
      one: '1 Abhängigkeit',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies =>
      'Keine Abhängigkeiten, läuft sobald der Plan startet';

  @override
  String get planNodeOutputSchema => 'Ausgabeschema (JSON)';

  @override
  String get planNodeEstimate => 'Schätzung';

  @override
  String get planNodeProvenance => 'Herkunft';

  @override
  String get planNodeAlreadyExecuted =>
      'Bereits ausgeführt — Bearbeiten verzweigt den Plan ab hier.';

  @override
  String get planNewNodeTitle => 'Neuer Schritt';

  @override
  String get planEstimateNoHistory => 'Noch kein Verlauf';

  @override
  String get planEstimateBlastUnknown => 'Wirkungsradius: unbekannt';

  @override
  String get planEstimatePartial => 'teilweise';

  @override
  String get planEstimateAction => 'Schätzen';

  @override
  String planEstimateDuration(String range) {
    return 'Dauer $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return 'Wirkungsradius: $files Dateien, $symbols Symbole';
  }

  @override
  String get planApprove => 'Plan genehmigen';

  @override
  String get planApproveSelectedNodes => 'Auswahl genehmigen';

  @override
  String get planReject => 'Ablehnen';

  @override
  String get planCancel => 'Lauf abbrechen';

  @override
  String get planContinueNode => 'Knoten fortsetzen';

  @override
  String get planTotalNotEstimated => 'Noch nicht geschätzt';

  @override
  String get planBudgetExceeded => 'über Budget';

  @override
  String planBudgetCeiling(String amount) {
    return 'Budget ≤ $amount \$';
  }

  @override
  String get planVersionsTitle => 'Versionen';

  @override
  String get planNoRevisions => 'Noch keine Änderungen.';

  @override
  String get planDiffIdentical => 'Keine Änderungen.';

  @override
  String get planDiffGoalChanged => 'Ziel geändert';

  @override
  String get planDiffBudgetChanged => 'Budget geändert';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'Änderungen von v$fromRev zu v$toRev';
  }

  @override
  String planDiffAdded(String node) {
    return 'Hinzugefügt $node';
  }

  @override
  String planDiffRemoved(String node) {
    return 'Entfernt $node';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return 'Geändert $node: $fields';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return 'Kante hinzugefügt: $edge';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return 'Kante entfernt: $edge';
  }

  @override
  String planDiffRoleAdded(String role) {
    return 'Rolle hinzugefügt: $role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return 'Rolle entfernt: $role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return 'Rolle neu zugewiesen: $role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return 'Plan neu geplant: Sie haben v$approved genehmigt, jetzt v$current. Prüfen Sie die Änderungen.';
  }

  @override
  String planLiveActualCost(String amount) {
    return 'Tatsächliche Kosten: $amount \$';
  }

  @override
  String get planPlaybookRun => 'Ausführen';

  @override
  String get planPlaybookDelete => 'Playbook löschen';

  @override
  String get planPlaybookProposed =>
      'Plan vorgeschlagen — im Plan-Studio genehmigen.';

  @override
  String get planPlaybookAnchorTicket => 'Anker-Ticket';

  @override
  String get planPlaybookPickTicket => 'Ticket wählen…';

  @override
  String get planPlaybookProposeRun => 'Plan vorschlagen';

  @override
  String get planPlaybookRepoHint => 'Eine Repository-ID';

  @override
  String get planPlaybookAgentHint => 'Eine Agenten-ID';

  @override
  String planPlaybookRunTitle(String name) {
    return '$name ausführen';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '$count Parameter';
  }

  @override
  String get recentLabel => 'Zuletzt verwendet';

  @override
  String get cheatSheetTitle => 'Tastenkürzel';

  @override
  String get cheatSheetGlobal => 'Global';

  @override
  String get cheatSheetThisScreen => 'Dieser Bildschirm';

  @override
  String get cheatSheetReservedInBrowser => 'Vom Browser reserviert';

  @override
  String get keybindingCheatSheet => 'Tastenkürzel';

  @override
  String get keybindingShowKeyboardShortcutsDescription =>
      'Die Tastenkürzelübersicht für den aktuellen Bildschirm anzeigen';

  @override
  String get runPlaybookLabel => 'Playbook ausführen';

  @override
  String get playbooksLabel => 'Playbooks';

  @override
  String get keybindingUndo => 'Rückgängig';

  @override
  String get keybindingRedo => 'Wiederholen';

  @override
  String get keybindingUndoLastActionDescription =>
      'Deine letzte umkehrbare Aktion rückgängig machen';

  @override
  String get keybindingRedoLastActionDescription =>
      'Die zuletzt rückgängig gemachte Aktion wiederholen';

  @override
  String get undone => 'Rückgängig gemacht';

  @override
  String get redone => 'Wiederholt';

  @override
  String get undoFailed => 'Rückgängig machen fehlgeschlagen';

  @override
  String get undoLabelTicketEdit => 'Ticketbearbeitung';

  @override
  String get undoLabelMessageEdit => 'Nachrichtenbearbeitung';

  @override
  String get undoLabelTodoStatus => 'Aufgabenstatus';

  @override
  String get inboxTitle => 'Posteingang';

  @override
  String get inboxReview => 'Prüfen';

  @override
  String get inboxOpen => 'Öffnen';

  @override
  String get inboxAllCaughtUp => 'Alles erledigt';

  @override
  String get inboxGitHubDownTitle =>
      'GitHub ist möglicherweise nicht erreichbar';

  @override
  String inboxGitHubDownBody(String status) {
    return 'GitHub meldet: $status. Es können also Pull Requests in dieser Liste fehlen, statt wirklich erledigt zu sein.';
  }

  @override
  String get inboxGitHubIdentityTitle =>
      'Dein GitHub-Konto konnte nicht bestätigt werden';

  @override
  String get inboxGitHubIdentityBody =>
      'Der Posteingang wird danach sortiert, wer du auf GitHub bist. Solange das nicht geladen ist, bleibt die Liste leer — auch wenn Pull Requests auf dich warten.';

  @override
  String get inboxSeverityBlocking => 'Blockiert';

  @override
  String get inboxSeverityWaiting => 'Wartet';

  @override
  String get inboxSeverityInfo => 'Info';

  @override
  String get inboxSyncFailed => 'Synchronisierung fehlgeschlagen';

  @override
  String get inboxNeedsYourAttention => 'Braucht deine Aufmerksamkeit';

  @override
  String get inboxSectionNeedsYourReview => 'Wartet auf dein Review';

  @override
  String get inboxSectionReturnedToYou => 'An dich zurückgegeben';

  @override
  String get inboxSectionApproved => 'Genehmigt';

  @override
  String get inboxSectionDrafts => 'Entwürfe';

  @override
  String get inboxSectionWaitingForReviewers => 'Wartet auf Reviewer';

  @override
  String get inboxSectionMergingAndMerged =>
      'Wird gemergt und kürzlich gemergt';

  @override
  String get inboxSectionWaitingForAuthor => 'Wartet auf den Autor';

  @override
  String get inboxColumnTitle => 'Titel';

  @override
  String get inboxColumnChanges => 'Änderungen';

  @override
  String get inboxColumnUpdated => 'Aktualisiert';

  @override
  String get inboxReviewApproved => 'Genehmigt';

  @override
  String get inboxReviewChangesRequested => 'Änderungen angefordert';

  @override
  String get inboxHeroSubtitle =>
      'Jeder Pull Request, der dich betrifft, sortiert nach dem nächsten Schritt.';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pull Requests warten auf dein Review',
      one: '1 Pull Request wartet auf dein Review',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count an dich zurück',
      one: '1 an dich zurück',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted =>
      'Diese Änderung wurde nicht gespeichert und zurückgesetzt';

  @override
  String get offlinePendingLabel => 'ausstehend';

  @override
  String get offlineSyncingLabel => 'synchronisiert';

  @override
  String get copyLinkLabel => 'Link zu dieser Seite kopieren';

  @override
  String get agentsSectionLabel => 'Agenten';

  @override
  String get fleetWorkersTitle => 'Worker';

  @override
  String get fleetWorkersSubtitle => 'Maschinen, die für Jobs verfügbar sind';

  @override
  String get fleetJobsTitle => 'Jobs';

  @override
  String get fleetJobsSubtitle => 'Arbeit, die über die Flotte verteilt ist';

  @override
  String get fleetNoWorkers =>
      'Noch keine Worker — eine zweite Maschine, die `cc_worker --server <url>` ausführt, tritt der Flotte bei.';

  @override
  String get fleetNoJobs => 'Keine Jobs.';

  @override
  String get fleetError => 'Flotte konnte nicht geladen werden';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kerne',
      one: '1 Kern',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return 'Heartbeat $time';
  }

  @override
  String get fleetNoHeartbeat => 'Noch kein Heartbeat';

  @override
  String fleetLastErrorLabel(String error) {
    return 'Letzter Fehler: $error';
  }

  @override
  String get fleetDrain => 'Entleeren';

  @override
  String get fleetResume => 'Fortsetzen';

  @override
  String get fleetRevoke => 'Widerrufen';

  @override
  String get fleetRemove => 'Entfernen';

  @override
  String get fleetRevokeTitle => 'Worker widerrufen?';

  @override
  String fleetRevokeBody(String name) {
    return '$name widerrufen? Die Sitzung endet und aktive Jobs werden neu zugewiesen.';
  }

  @override
  String get fleetRemoveTitle => 'Worker entfernen?';

  @override
  String fleetRemoveBody(String name) {
    return '$name aus der Flotte entfernen? Dadurch wird der Datensatz gelöscht.';
  }

  @override
  String get fleetActionFailed => 'Aktion fehlgeschlagen';

  @override
  String get fleetJobUnassigned => 'Nicht zugewiesen';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '$attempts/$max Versuche';
  }

  @override
  String get fleetPlacementReasons => 'Platzierungsentscheidungen';

  @override
  String get fleetNoPlacements => 'Noch keine Platzierungsentscheidungen.';

  @override
  String get fleetStatusOnline => 'Online';

  @override
  String get fleetStatusDraining => 'Wird geleert';

  @override
  String get fleetStatusOffline => 'Offline';

  @override
  String get fleetStatusIncompatible => 'Inkompatibel';

  @override
  String get fleetStatusRevoked => 'Widerrufen';

  @override
  String get fleetJobStatusQueued => 'In Warteschlange';

  @override
  String get fleetJobStatusRunning => 'Läuft';

  @override
  String get fleetJobStatusSucceeded => 'Erfolgreich';

  @override
  String get fleetJobStatusFailed => 'Fehlgeschlagen';

  @override
  String get fleetJobStatusCancelled => 'Abgebrochen';

  @override
  String get evalsNoSuites => 'Noch keine Eval-Suiten.';

  @override
  String get evalsError => 'Evals konnten nicht geladen werden';

  @override
  String get evalsStarterBadge => 'Vorlage';

  @override
  String evalsDefaultBatch(int count) {
    return 'Standard-Batch von $count';
  }

  @override
  String get evalsRecentRuns => 'Letzte Durchläufe';

  @override
  String get evalsNoRuns => 'Noch keine Durchläufe.';

  @override
  String get evalsPassRate => 'Erfolgsquote';

  @override
  String evalsBatchTimes(int count) {
    return '× $count';
  }

  @override
  String evalsTriggeredBy(String who) {
    return 'von $who';
  }

  @override
  String evalsRunFinished(String rate) {
    return 'Eval abgeschlossen — $rate bestanden';
  }

  @override
  String get evalsRunFailed => 'Suite konnte nicht ausgeführt werden';

  @override
  String get evalsRun => 'Ausführen';

  @override
  String get evalsStatusQueued => 'In Warteschlange';

  @override
  String get evalsStatusRunning => 'Läuft';

  @override
  String get evalsStatusPassed => 'Bestanden';

  @override
  String get evalsStatusFailed => 'Fehlgeschlagen';

  @override
  String get bannerMeetingJoin => 'Beitreten';

  @override
  String get bannerMeetingRecordAndLink => 'Aufnehmen und verknüpfen';

  @override
  String get bannerCalendarReconnect => 'Erneut verbinden';

  @override
  String get bannerView => 'Anzeigen';

  @override
  String get soundscapeTitle => 'Klanglandschaften';

  @override
  String get soundscapePlay => 'Wiedergeben';

  @override
  String get soundscapePause => 'Pause';

  @override
  String get soundscapeMoodLabel => 'Stimmung';

  @override
  String get soundscapeMoodFocus => 'Fokus';

  @override
  String get soundscapeMoodRelax => 'Entspannung';

  @override
  String get soundscapeMoodSleep => 'Schlaf';

  @override
  String get soundscapeVolumeLabel => 'Lautstärke';

  @override
  String get soundscapeTuneLabel => 'Abstimmung';

  @override
  String get soundscapeTuneMellow => 'Sanft';

  @override
  String get soundscapeTuneBright => 'Hell';

  @override
  String get soundscapeTuneEnergetic => 'Energisch';

  @override
  String get soundscapeTuneSpacy => 'Sphärisch';

  @override
  String get soundscapeTuneResetHint => 'Zum Zurücksetzen doppelt tippen';

  @override
  String get soundscapeSceneLabel => 'Aktuelle Wiedergabe';

  @override
  String get soundscapeSceneLoading => 'Klangbild wird abgestimmt…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees °C';
  }

  @override
  String get soundscapeLocationLabel => 'Standort';

  @override
  String get soundscapeLocationDetecting => 'Standort wird ermittelt…';

  @override
  String get soundscapeLocationAutoNote =>
      'Der Standort wird automatisch aus diesem Arbeitsbereich ermittelt.';

  @override
  String get soundscapeRefreshWeather => 'Wetter aktualisieren';

  @override
  String get soundscapeAutoStartLabel => 'Mit Fokusmodus starten';

  @override
  String get soundscapeAutoStartDescription =>
      'Automatisch eine Klanglandschaft abspielen, wenn du eine Fokus-Sitzung startest.';

  @override
  String get soundscapeReturnToApp => 'Zurück zur App';

  @override
  String get soundscapePopOut => 'Player abdocken';

  @override
  String get discussion => 'Diskussion';

  @override
  String get chat => 'Chat';

  @override
  String get saving => 'Speichern…';

  @override
  String get saved => 'Gespeichert';

  @override
  String get saveFailed => 'Speichern fehlgeschlagen';

  @override
  String get commitAndPush => 'Commit & Push';

  @override
  String get commit => 'Commit';

  @override
  String get commitAmend => 'Commit (ändern)';

  @override
  String get commitAndSync => 'Commit & synchronisieren';

  @override
  String get committed => 'Commit erstellt';

  @override
  String get commitAmended => 'Commit geändert';

  @override
  String get commitFailed => 'Commit fehlgeschlagen';

  @override
  String get moreCommitActions => 'Weitere Commit-Aktionen';

  @override
  String get sourceControl => 'Versionsverwaltung';

  @override
  String fixFindingTitle(String location) {
    return 'Beheben: $location';
  }

  @override
  String get openInEditor => 'Im Editor öffnen';

  @override
  String get commitMessageHint => 'Commit-Nachricht';

  @override
  String get pushedToPr => 'Zur PR gepusht';

  @override
  String get pushFailed => 'Push fehlgeschlagen';

  @override
  String get reviewFindings => 'Befunde';

  @override
  String get treeLabel => 'Baum';

  @override
  String get toggleFileTree => 'Dateibaum ein- oder ausblenden';

  @override
  String get diffViewSettings => 'Diff-Ansichtseinstellungen';

  @override
  String get splitViewLabel => 'Geteilt';

  @override
  String get unifiedViewLabel => 'Einheitlich';

  @override
  String get wrapLines => 'Zeilenumbruch';

  @override
  String get shiftClickSelectRange => 'Umschalt+Klick für Bereichsauswahl';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien',
      one: '1 Datei',
    );
    return '$_temp0';
  }

  @override
  String prComplexityLoc(String loc) {
    return '$loc LOC';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return 'Kleiner PR — $files, ~$minutes Min. Review';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return 'Mittlerer PR — $files, ~$minutes Min. für das Review einplanen';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return 'Großer PR — $files, vor dem Review aufteilen';
  }

  @override
  String get searchInFiles => 'In Dateien suchen';

  @override
  String get showFileList => 'Dateiliste anzeigen';

  @override
  String get searchInFilesHintField => 'In Dateien suchen…';

  @override
  String get searchInFilesHint => 'In den Dateien des Pull Requests suchen';

  @override
  String get searchNoResults => 'Keine Ergebnisse';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ergebnisse',
      one: '1 Ergebnis',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files Dateien',
      one: '1 Datei',
    );
    return '$_temp0 in $_temp1';
  }

  @override
  String get discardChangesTitle => 'Änderungen verwerfen?';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien',
      one: '1 Datei',
    );
    return '$_temp0 auf HEAD zurücksetzen? Das kann nicht rückgängig gemacht werden.';
  }

  @override
  String get discardAll => 'Alle verwerfen';

  @override
  String get discardFailed => 'Änderungen konnten nicht verworfen werden';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien verworfen',
      one: '1 Datei verworfen',
    );
    return '$_temp0';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '$reverted Dateien verworfen',
      one: '1 Datei verworfen',
    );
    return '$_temp0; $skipped übersprungen (nicht verfolgt)';
  }

  @override
  String get prWorktreeUnavailable => 'Arbeitsbereich nicht bereit';

  @override
  String get prWorktreeUnavailableHint =>
      'Die Dateien des Pull Requests konnten nicht vorbereitet werden. Öffnen Sie den Pull Request erneut, um es noch einmal zu versuchen.';

  @override
  String get timestampRelativeLabel => 'Relativ';

  @override
  String get timestampRawLabel => 'Zeitstempel';

  @override
  String get copyTimestamp => 'Zeitstempel kopieren';

  @override
  String get copiedTimestamp => 'Zeitstempel kopiert';

  @override
  String get previewDeployment => 'Vorschau-Deployment';

  @override
  String previewDeploymentTab(String site) {
    return 'Vorschau: $site';
  }

  @override
  String get askForReview => 'Review anfragen…';

  @override
  String get closePrsConfirmTitle => 'Pull Requests schließen?';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pull Requests schließen?',
      one: '1 Pull Request schließen?',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pull Requests geschlossen',
      one: '1 Pull Request geschlossen',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pull Requests zugewiesen',
      one: '1 Pull Request zugewiesen',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Review für $count Pull Requests angefragt',
      one: 'Review für 1 Pull Request angefragt',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aktionen fehlgeschlagen',
      one: '1 Aktion fehlgeschlagen',
    );
    return '$_temp0';
  }

  @override
  String get diagram => 'Diagramm';

  @override
  String get diagramViewSource => 'Quelltext anzeigen';

  @override
  String get diagramHideSource => 'Quelltext ausblenden';

  @override
  String diagramPreviewUnavailable(String reason) {
    return 'Diagrammvorschau nicht verfügbar ($reason)';
  }

  @override
  String get planUnavailable => 'Plan nicht verfügbar';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schritte',
      one: '1 Schritt',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => 'Genehmigen und starten';

  @override
  String get planStatusDraft => 'Entwurf';

  @override
  String get planStatusProposed => 'Plan';

  @override
  String get planStatusApproved => 'Plan genehmigt';

  @override
  String get planStatusRejected => 'Plan abgelehnt';

  @override
  String get planStatusSuperseded => 'Plan ersetzt';

  @override
  String planRevisionLabel(int revision) {
    return 'Revision $revision';
  }

  @override
  String get adapterEnforcementTitle => 'Was dieser Adapter durchsetzt';

  @override
  String get enforcementFiltersToolSurface =>
      'Control Center wählt die Werkzeuge';

  @override
  String get enforcementInterceptsToolCalls =>
      'Jeder Aufruf wird vor der Ausführung geprüft';

  @override
  String get enforcementObservesCompletionContract =>
      'Der Lauf wird an sein Ergebnis gebunden';

  @override
  String get enforcementNativeToolsInterceptable =>
      'Die eigenen Werkzeuge des Runners sind sichtbar';

  @override
  String get enforcementInProcessToolsSandboxed =>
      'Werkzeuge im Prozess laufen in der Sandbox';

  @override
  String get enforcementYes => 'Ja';

  @override
  String get enforcementNo => 'Nein';

  @override
  String get adapterEnforcementCaveats => 'Einschränkungen';

  @override
  String get enforcementSummaryModesEnforced => 'Modi erzwungen';

  @override
  String get enforcementSummaryModesNotEnforced => 'Modi nicht erzwungen';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einschränkungen',
      one: '1 Einschränkung',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      'Schreibgeschützte Modi sind nicht strukturell: Control Center kann die eigenen Werkzeuge dieses Runners nicht entfernen.';

  @override
  String get caveatToolCallsNotIntercepted =>
      'Keine Prüfung vor der Ausführung: nur MCP-Werkzeugaufrufe laufen über Control Center.';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      'Die eigenen Datei- und Shell-Werkzeuge des Runners erreichen Control Center nie; die Sandbox des Systems ist ihre einzige Grenze.';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      'Dateiwerkzeuge im Prozess laufen außerhalb der Sandbox, daher ist die Werkzeugauswahl die einzige Grenze zum Dateisystem.';

  @override
  String get caveatCompletionContractUnobservable =>
      'Control Center kann einen Lauf, der ohne Ergebnis endet, weder anstoßen noch scheitern lassen.';

  @override
  String get modeDegraded => 'Eingeschränkt';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return 'Der Modus $mode auf $adapter verlässt sich nur auf die Sandbox; die eigenen Dateiwerkzeuge des Agenten werden nicht abgefangen.';
  }

  @override
  String get artifactUnavailable => 'Artefakt nicht verfügbar';

  @override
  String artifactRevisionLabel(int count) {
    return '$count Revisionen';
  }

  @override
  String get artifactShowMore => 'Mehr anzeigen';

  @override
  String get artifactShowLess => 'Weniger anzeigen';

  @override
  String get artifactCopy => 'Kopieren';

  @override
  String get artifactCopied => 'Artefakt kopiert';

  @override
  String get artifactsTabLabel => 'Artefakte';

  @override
  String get artifactsEmptyTitle => 'Noch keine Artefakte';

  @override
  String get artifactsEmptyBody =>
      'Wenn ein Agent hier eine Tabelle, ein Diagramm oder eine Grafik veröffentlicht, erscheint sie in dieser Liste.';

  @override
  String get artifactRevisionPickerLabel => 'Revision';

  @override
  String get artifactRestoreRevision => 'Diese Revision wiederherstellen';

  @override
  String get artifactOpenInTab => 'In Tab öffnen';

  @override
  String get artifactTitleFallback => 'Artefakt';

  @override
  String get providerGenerationLabel => 'Standardwerte für die Generierung';

  @override
  String get providerGenerationHint =>
      'Lass ein Feld leer, um den Standardwert des Endpunkts zu verwenden. Modelle veröffentlichen eigene Ausgabegrenzen und Sampling-Rezepte; andere Werte können sie verschlechtern.';

  @override
  String get providerMaxTokensLabel => 'Max. Ausgabetokens';

  @override
  String get addModel => 'Modell hinzufügen';

  @override
  String get modelListTitle => 'Modellliste';

  @override
  String get railProvidersGroup => 'Anbieter';

  @override
  String get railCustomProvidersGroup => 'Eigene Anbieter';

  @override
  String get editModelSettings => 'Modell bearbeiten';

  @override
  String get modelIdLabel => 'Modell-ID';

  @override
  String get modelIdImmutableHint =>
      'Die Kennung, die der Endpunkt ausliefert; nach dem Auflisten fest.';

  @override
  String get contextWindowLabel => 'Kontextfenster';

  @override
  String get inputTypesLabel => 'Eingabetypen';

  @override
  String get outputTypesLabel => 'Ausgabetypen';

  @override
  String get modalityText => 'Text';

  @override
  String get modalityImage => 'Bild';

  @override
  String get modalityAudio => 'Audio';

  @override
  String get modalityVideo => 'Video';

  @override
  String get modalityPdf => 'PDF';

  @override
  String get modelOverrideReset => 'Auf automatisch zurücksetzen';

  @override
  String get modelOverrideEdited => 'Bearbeitet';

  @override
  String get manualModelBadge => 'Manuell hinzugefügt';

  @override
  String get modelIdRequired => 'Gib eine Modellkennung ein.';

  @override
  String get modelTokensInvalid =>
      'Gib eine positive ganze Zahl von Token ein.';

  @override
  String get removeModelAction => 'Modell entfernen';

  @override
  String removeModelConfirmTitle(String model) {
    return '$model entfernen?';
  }

  @override
  String get removeModelConfirmBody =>
      'Das Modell verlässt die Liste und darauf festgelegte Agenten funktionieren nicht mehr. Der Anbieter bleibt unverändert.';

  @override
  String get addModelProviderTitle => 'Modellanbieter hinzufügen';

  @override
  String get addModelProviderDescription =>
      'Konfiguriere einen eigenen API-Endpunkt und seine Modelle.';

  @override
  String get modelListEmptyHint =>
      'Keine Modelle konfiguriert. Füge ein Modell hinzu, um es im Chat zu nutzen.';

  @override
  String get addProviderModelsHint =>
      'Modelle werden live abgerufen, sobald der Endpunkt antwortet. Füge nur dann eines von Hand hinzu, wenn er seine eigenen nicht auflisten kann.';

  @override
  String get providerTemperatureLabel => 'Temperatur';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved =>
      'Standardwerte für die Generierung gespeichert';

  @override
  String get providerGenerationInvalid =>
      'Prüfe die Werte: max. Ausgabetokens und Top-k müssen positiv sein, Temperatur 0–2, Top-p 0–1.';

  @override
  String get providerGenerationOverridden => 'Überschrieben';

  @override
  String get spaceFlyoutNeedsInput => 'Eingabe erforderlich';

  @override
  String get spaceFlyoutPreparing => 'Wird vorbereitet';

  @override
  String get spaceFlyoutSetupFailed => 'Einrichtung fehlgeschlagen';

  @override
  String get spaceFlyoutSetupStopped => 'Einrichtung gestoppt';

  @override
  String get spaceFlyoutNeverRun => 'Hier hat noch kein Agent gearbeitet';

  @override
  String spaceFlyoutContextUsage(String used, String percent) {
    return 'Kontextfenster: $used genutzt, zu $percent gefüllt';
  }

  @override
  String subagentsRunningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Subagenten',
      one: '1 Subagent',
    );
    return '$_temp0';
  }

  @override
  String get branchNotPushed => 'nicht gepusht';

  @override
  String branchNotOnRemote(String branch) {
    return '„$branch“ existiert nur in dieser Unterhaltung';
  }

  @override
  String get branchNotOnRemoteHint =>
      'GitHub kennt diesen Branch nicht, ein Pull Request kann ihn daher noch nicht verwenden. Beim Veröffentlichen werden die Commits gepusht, die bereits im Worktree liegen — nicht committete Änderungen bleiben unberührt.';

  @override
  String get publishBranch => 'Branch veröffentlichen';

  @override
  String branchPublished(String branch) {
    return '„$branch“ auf origin veröffentlicht';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return 'Branch veröffentlicht. $count nicht committete Änderung(en) wurden nicht einbezogen.';
  }

  @override
  String get composePrLoadingBranches => 'Branches werden von GitHub geladen…';

  @override
  String get composePrBranchesFailed =>
      'Branches konnten nicht von GitHub geladen werden. Gib einen Branch-Namen ein oder prüfe die GitHub-Verbindung.';

  @override
  String get composePrSubtitleFromSpace =>
      'Vom Branch dieser Unterhaltung — zuerst veröffentlichen, wenn GitHub ihn nicht kennt';

  @override
  String get obsTabInsights => 'Übersicht';

  @override
  String get obsTabLive => 'Live';

  @override
  String get obsTabQuality => 'Qualität';

  @override
  String get obsTabUsage => 'Nutzung';

  @override
  String get obsUsageTotalTokens => 'Tokens gesamt';

  @override
  String get obsUsagePeakTokens => 'Spitzenwert Tokens';

  @override
  String get obsUsageLongestSession => 'Längste Sitzung';

  @override
  String get obsUsageCurrentStreak => 'Aktuelle Serie';

  @override
  String get obsUsageLongestStreak => 'Längste Serie';

  @override
  String obsUsageDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
      zero: '0 Tage',
    );
    return '$_temp0';
  }

  @override
  String get obsUsageTokenActivity => 'Token-Aktivität';

  @override
  String get obsUsageActivityModeLabel => 'Modus der Token-Aktivität';

  @override
  String get obsUsageModeDaily => 'Täglich';

  @override
  String get obsUsageModeWeekly => 'Wöchentlich';

  @override
  String get obsUsageModeCumulative => 'Kumuliert';

  @override
  String get obsUsageTimeRange => 'Zeitraum';

  @override
  String get obsUsageTrendTitle => 'Täglicher Token-Verlauf';

  @override
  String get obsUsageModelUsage => 'Nutzung nach Modell';

  @override
  String get obsUsageTokensLabel => 'Tokens';

  @override
  String get obsUsageNoActivity => 'Noch keine Token-Nutzung erfasst';

  @override
  String get obsUsageOtherModels => 'Andere';

  @override
  String obsUsageCellReadout(String date, String tokens) {
    return '$date · $tokens Tokens';
  }

  @override
  String obsUsageActivitySummary(
    String start,
    String end,
    int activeDays,
    String peak,
  ) {
    return 'Token-Aktivität vom $start bis $end. $activeDays aktive Tage. Stärkster Tag: $peak Tokens.';
  }

  @override
  String get obsScreenSubtitle =>
      'Live-Agentensteuerung, Kostenzurechnung, Quotas und Qualitätssignale';

  @override
  String get obsRangeLast24h => 'Letzte 24 Stunden';

  @override
  String get obsRangeLast7d => 'Letzte 7 Tage';

  @override
  String get obsRangeLast30d => 'Letzte 30 Tage';

  @override
  String get obsRangeAll => 'Gesamte Zeit';

  @override
  String get obsAddFilter => 'Filter hinzufügen';

  @override
  String get obsFilterAgent => 'Agent';

  @override
  String get obsFilterModel => 'Modell';

  @override
  String get obsFilterStatus => 'Status';

  @override
  String get obsFilterRole => 'Rolle';

  @override
  String get obsKpiTotalRuns => 'Läufe gesamt';

  @override
  String get obsKpiTotalCost => 'Gesamtkosten';

  @override
  String get obsKpiErrorRate => 'Fehlerrate';

  @override
  String get obsKpiCacheRate => 'Cache-Rate';

  @override
  String get obsKpiTokensPerSec => 'Token / s';

  @override
  String get obsKpiAvgLatency => 'Ø Latenz';

  @override
  String get obsKpiTtft => 'Zeit bis zum ersten Token';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '$delta vs. vorheriger Zeitraum';
  }

  @override
  String get obsChartActivity => 'Aktivität';

  @override
  String get obsChartCost => 'Kosten im Zeitverlauf';

  @override
  String get obsLegendRuns => 'Läufe';

  @override
  String get obsLegendErrors => 'Fehler';

  @override
  String get obsAgentsTitle => 'Agenten';

  @override
  String obsShowAllAgents(int count) {
    return 'Alle $count Agenten anzeigen';
  }

  @override
  String get obsShowFewerAgents => 'Weniger anzeigen';

  @override
  String get obsRunsTitle => 'Läufe';

  @override
  String get obsNoRunsInRange => 'Keine Läufe in diesem Zeitraum';

  @override
  String get obsColTime => 'Zeit';

  @override
  String get obsColAgent => 'Agent';

  @override
  String get obsColStatus => 'Status';

  @override
  String get obsColModel => 'Modell';

  @override
  String get obsColDuration => 'Dauer';

  @override
  String get obsColTokens => 'Token';

  @override
  String get obsColCost => 'Kosten';

  @override
  String get obsColErrors => 'Fehler';

  @override
  String get obsColRuns => 'Läufe';

  @override
  String get obsColAvgLatency => 'Ø Latenz';

  @override
  String get obsColLastActive => 'Zuletzt aktiv';

  @override
  String get obsStatusPending => 'Ausstehend';

  @override
  String get obsStatusRunning => 'Läuft';

  @override
  String get obsStatusCompleted => 'Abgeschlossen';

  @override
  String get obsStatusError => 'Fehler';

  @override
  String get obsRosterLoadError =>
      'Die Agentenliste konnte nicht geladen werden.';

  @override
  String get obsRosterEmpty => 'Noch keine Agenten';

  @override
  String get obsRosterEmptyDescription =>
      'Starte einen Agenten und er erscheint hier live — Status, aktuelles Werkzeug, Token, Kosten.';

  @override
  String get obsKillAgent => 'Agent beenden';

  @override
  String get obsRosterTokensLabel => 'Tok';

  @override
  String get obsCostByRoleTitle => 'Kosten nach Rolle';

  @override
  String get obsCostByRoleSubtitle =>
      'Wofür dieser Workspace ausgibt, nach Agentenrolle';

  @override
  String get obsRoleMain => 'Hauptagent';

  @override
  String get obsRoleSubagents => 'Subagenten';

  @override
  String get obsRoleAdvisor => 'Berater';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return 'Hauptagent: $main · Subagenten: $sub · Berater: $advisor';
  }

  @override
  String get obsTotal => 'Gesamt';

  @override
  String get obsTokenModelTitle => 'Token-Modell (5 Achsen)';

  @override
  String get obsTokenModelSubtitle =>
      'Alle von diesem Workspace verbrauchten Token, nach Achse';

  @override
  String get obsAxisInput => 'Eingabe';

  @override
  String get obsAxisOutput => 'Ausgabe';

  @override
  String get obsAxisReasoning => 'Reasoning';

  @override
  String get obsAxisCacheRead => 'Cache-Lesung';

  @override
  String get obsAxisCacheWrite => 'Cache-Schreibung';

  @override
  String get obsTotalTokens => 'Token gesamt';

  @override
  String get obsCacheDiscountNote =>
      'Aus dem Cache gelesene Token werden vergünstigt abgerechnet und kosten daher deutlich weniger als dasselbe Volumen an neuer Eingabe.';

  @override
  String get obsByModelTitle => 'Nach Modell';

  @override
  String get obsByModelSubtitle => 'Token- und Kostennutzung pro Modell';

  @override
  String get obsNoModelUsage => 'Noch keine Modellnutzung erfasst.';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Läufe',
      one: '1 Lauf',
    );
    return '$_temp0';
  }

  @override
  String get obsPerRunTitle => 'Pro Lauf';

  @override
  String get obsPerRunSubtitle => 'Typische Token-Kosten eines einzelnen Laufs';

  @override
  String get obsMedianRunTokens => 'Median-Token pro Lauf';

  @override
  String get obsMedianRunTokensSub => 'Median über alle Läufe';

  @override
  String get obsRunsInWorkspace => 'In diesem Workspace';

  @override
  String get obsCostShare => 'Kostenanteil';

  @override
  String get obsQuotaConfiguredLimits => 'Konfigurierte Limits';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      'Nutzung gegen die gesetzten Obergrenzen, schlechtester Status zuerst.';

  @override
  String get obsQuotaAddLimit => 'Limit hinzufügen';

  @override
  String get obsQuotaNoLimits =>
      'Noch keine Quota-Limits konfiguriert — füge eines hinzu, um die Nutzung gegen eine Obergrenze zu verfolgen.';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return 'Limit $title entfernen';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return 'Zurücksetzung in $duration · $status';
  }

  @override
  String get obsQuotaUsageWindows => 'Nutzungsfenster';

  @override
  String get obsQuotaUsageWindowsSubtitle =>
      'Beobachtete Nutzung über alle Anbieter, ohne Obergrenze.';

  @override
  String get obsQuotaNoUsage => 'Noch keine Nutzung erfasst.';

  @override
  String get obsQuotaTokensUsed => 'Verbrauchte Token';

  @override
  String get obsQuotaRequests => 'Anfragen';

  @override
  String get obsQuotaUnitTokens => 'Token';

  @override
  String get obsQuotaUnitRequests => 'Anfragen';

  @override
  String get obsQuotaUnitCost => 'Kosten';

  @override
  String get obsQuotaAddLimitTitle => 'Quota-Limit hinzufügen';

  @override
  String get obsQuotaProviderLabel => 'Anbieter';

  @override
  String get obsQuotaWindowLabel => 'Fenster';

  @override
  String get obsQuotaUnitLabel => 'Einheit';

  @override
  String obsQuotaLimitLabel(String unit) {
    return 'Limit ($unit)';
  }

  @override
  String get obsQuotaCentsHint => 'In US-Cent (500 = 5,00 \$).';

  @override
  String get obsQuotaStatusOk => 'Ok';

  @override
  String get obsQuotaStatusWarning => 'Warnung';

  @override
  String get obsQuotaStatusExhausted => 'Erschöpft';

  @override
  String get obsQuotaStatusUnknown => 'Unbekannt';

  @override
  String get obsGoalNoActiveTitle => 'Kein aktives Ziel';

  @override
  String get obsGoalNoActiveBody =>
      'Setze ein Ziel, um den Agenten einen Zweck und ein optionales Token-Budget zu geben. Mit jedem abgeschlossenen Lauf füllt sich das Budget, und die Agenten werden zum Abschluss aufgefordert, sobald es fast aufgebraucht ist.';

  @override
  String get obsGoalSetGoal => 'Ziel setzen';

  @override
  String get obsGoalTokenBudget => 'Token-Budget';

  @override
  String obsGoalTokensLeft(String tokens) {
    return '$tokens übrig';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens (kein Budget gesetzt)';
  }

  @override
  String get obsGoalTokensUsed => 'Verbrauchte Token';

  @override
  String get obsGoalElapsed => 'Verstrichen';

  @override
  String get obsGoalWrapUp => 'Abschließen';

  @override
  String get obsGoalClear => 'Ziel löschen';

  @override
  String get obsGoalFallbackTitle => 'Ziel';

  @override
  String get obsGoalSubtitle => 'Budget im Zielmodus';

  @override
  String get obsGoalStatusActive => 'Aktiv';

  @override
  String get obsGoalStatusPaused => 'Pausiert';

  @override
  String get obsGoalStatusBudgetLimited => 'Budget begrenzt';

  @override
  String get obsGoalStatusComplete => 'Abgeschlossen';

  @override
  String get obsGoalStatusDropped => 'Verworfen';

  @override
  String get obsGoalObjectiveLabel => 'Ziel';

  @override
  String get obsGoalBudgetLabel => 'Token-Budget (optional)';

  @override
  String get obsGoalSetAction => 'Ziel setzen';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => 'Erfolg %';

  @override
  String get obsBenchmarkPassed => 'Bestanden';

  @override
  String get obsBenchmarkFailed => 'Fehlgeschlagen';

  @override
  String get obsBenchmarkErrors => 'Fehler';

  @override
  String get obsBenchmarkSpend => 'Ausgaben';

  @override
  String get obsBenchmarkCostPerTask => 'Kosten / Aufgabe';

  @override
  String get obsBenchmarkTrials => 'Durchläufe';

  @override
  String get obsBenchmarkNoTrials => 'Noch keine Läufe zu bewerten.';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'und $count weitere',
      one: 'und 1 weiterer',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => 'Bestanden';

  @override
  String get obsBenchmarkTrialFail => 'Fehlgeschlagen';

  @override
  String get obsBenchmarkTrialError => 'Fehler';

  @override
  String get obsBenchmarkTrialRunning => 'Läuft';

  @override
  String get obsBenchmarkReward => 'Belohnung';

  @override
  String get obsBenchmarkReport => 'Bericht';

  @override
  String get obsBenchmarkCopyMarkdown => 'Markdown kopieren';

  @override
  String get obsBenchmarkCopied => 'Bericht in die Zwischenablage kopiert';

  @override
  String get obsBehaviorCaption =>
      'Dies sind Frustrationssignale aus deinen eigenen Nachrichten — ein Messwert für die Gesundheit der Konversation, keine Bewertung der Agenten. Lokal berechnet; nichts verlässt dieses Gerät.';

  @override
  String get obsBehaviorMessagesAnalyzed => 'Analysierte Nachrichten';

  @override
  String get obsBehaviorTotalSignals => 'Signale gesamt';

  @override
  String get obsBehaviorYelling => 'Schreien';

  @override
  String get obsBehaviorProfanity => 'Schimpfwörter';

  @override
  String get obsBehaviorAnguish => 'Verzweiflung';

  @override
  String get obsBehaviorNegation => 'Verneinung';

  @override
  String get obsBehaviorRepetition => 'Wiederholung';

  @override
  String get obsBehaviorBlame => 'Vorwurf';

  @override
  String get obsBehaviorConversationsTitle => 'Frustrierteste Konversationen';

  @override
  String get obsBehaviorConversationsSubtitle =>
      'Nach Signaldichte in deinen Nachrichten sortiert.';

  @override
  String get obsBehaviorNoSignals =>
      'Keine Frustrationssignale erkannt — alles ruhig.';

  @override
  String obsBehaviorMessagesCount(String count) {
    return '$count Nachrichten analysiert';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '$count Signale';
  }

  @override
  String get obsAgentStatusIdle => 'Inaktiv';

  @override
  String get obsAgentStatusParked => 'Geparkt';

  @override
  String get obsAgentStatusAborted => 'Abgebrochen';

  @override
  String get obsAgentKindSub => 'Subagent';

  @override
  String get noChecksOnCommit =>
      'Für diesen Commit wurden keine Checks ausgeführt.';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wird ausgeführt — $count Jobs',
      one: 'Wird ausgeführt — 1 Job',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alle Checks bestanden — $count Jobs',
      one: 'Alle Checks bestanden — 1 Job',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Abgeschlossen — $count Jobs',
      one: 'Abgeschlossen — 1 Job',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total Jobs',
      one: '1 Job',
    );
    return '$failed von $_temp0 fehlgeschlagen';
  }

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Jobs',
      one: '1 Job',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return 'Matrix: $jobId';
  }

  @override
  String get jobLogsPending =>
      'Logs erscheinen hier, sobald der Job abgeschlossen ist.';

  @override
  String get jobLogsUnavailable => 'Für diesen Job sind keine Logs verfügbar.';

  @override
  String get noLogsForStep => 'Für diesen Schritt wurden keine Logs erfasst.';

  @override
  String get jobLogsTruncated =>
      'Log gekürzt — die neueste Ausgabe wird angezeigt.';

  @override
  String get fullLog => 'Vollständiges Log';

  @override
  String get copyLogs => 'Logs kopieren';

  @override
  String get resizeGraph => 'Ziehen, um den Graphen anzupassen';

  @override
  String workflowRunStartedAgo(String time) {
    return 'Gestartet $time';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return 'Abgeschlossen $time';
  }

  @override
  String get chatBridgesTitle => 'Chat-Brücken';

  @override
  String chatProviderDescription(String provider, String command) {
    return 'Erwähne den Bot in $provider, um einen Agenten zu beauftragen, oder erstelle Tickets mit $command.';
  }

  @override
  String chatConnectProvider(String provider) {
    return '$provider verbinden';
  }

  @override
  String get chatDisconnectProvider => 'Trennen';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$botName in $teamName';
  }

  @override
  String get chatStateLive => 'Live';

  @override
  String get chatStateConnecting => 'Verbinden…';

  @override
  String get chatStateError => 'Verbindungsfehler';

  @override
  String get chatNotConnected => 'Nicht verbunden';

  @override
  String chatStreamingUnavailable(String provider) {
    return 'Live-Streaming ist für diese $provider-App aus — Antworten kommen als eine Nachricht.';
  }

  @override
  String chatAdminOnly(String provider) {
    return 'Nur ein Admin kann $provider für diesen Workspace verbinden.';
  }

  @override
  String chatConnectHint(String provider) {
    return 'Erstelle eine $provider-App und füge hier ihre Zugangsdaten ein. Control Center verbindet sich nach außen zu $provider, dieser Server braucht also keine öffentliche Adresse.';
  }

  @override
  String chatOpenConsole(String provider) {
    return '$provider-Konsole öffnen';
  }

  @override
  String get chatOpenSetupGuide => 'Einrichtungsanleitung';

  @override
  String get chatFieldBotToken => 'Bot-Token';

  @override
  String get chatFieldAppToken => 'App-Token';

  @override
  String get chatFieldConfigRefreshToken => 'App-Konfigurationstoken';

  @override
  String chatFieldOptional(String label) {
    return '$label (optional)';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return 'Mein $provider-Konto verknüpfen';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return 'Verknüpfe dein $provider-Konto, damit dort gesendete Nachrichten dir zugeordnet werden.';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return 'Verknüpft mit $externalUserId';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return 'Dein $provider-Konto verknüpfen';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return 'Sende diesen Befehl an den Bot in $provider. Er funktioniert einmal und läuft in 15 Minuten ab.';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return 'Dein $provider-Konto ist jetzt verknüpft – Nachrichten, die du dort sendest, werden dir zugeordnet.';
  }

  @override
  String get chatLinkedAccounts => 'Verknüpfte Konten';

  @override
  String chatNoLinkedAccounts(String provider) {
    return 'Noch niemand hat sein $provider-Konto verknüpft.';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verknüpfte Konten',
      one: '1 verknüpftes Konto',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '$externalUserId · per E-Mail zugeordnet';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '$externalUserId · mit einem Code verknüpft';
  }

  @override
  String get chatUnlink => 'Verknüpfung lösen';

  @override
  String get chatCustomizeBot => 'Bot anpassen';

  @override
  String get chatCustomizeBotDescription =>
      'Benenne den Bot um, ändere, was er über sich sagt, oder benenne den Befehl um.';

  @override
  String get chatCustomizeBotUnavailable =>
      'Control Center braucht ein App-Konfigurationstoken, um den Bot zu bearbeiten. Verbinde neu und gib eines mit an.';

  @override
  String chatCreateAppTitle(String provider) {
    return '$provider-App erstellen';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'Control Center kann die $provider-App für dich erstellen, mit den richtigen Berechtigungen und Ereignissen. Den Rest erledigst du in $provider und fügst die Zugangsdaten hier ein.';
  }

  @override
  String get chatCreateApp => 'App erstellen';

  @override
  String get chatCreateAppCta => 'App für mich erstellen';

  @override
  String get chatAppNameLabel => 'App-Name';

  @override
  String get chatBotDisplayNameLabel => 'Bot-Name (was man nach @ tippt)';

  @override
  String get chatDescriptionLabel => 'Kurzbeschreibung';

  @override
  String get chatAgentDescriptionLabel =>
      'Was der Bot über seine Fähigkeiten sagt';

  @override
  String get chatCommandLabel => 'Slash-Befehl';

  @override
  String get chatDirectMessages => 'Direktnachrichten';

  @override
  String chatDirectMessagesHint(String provider) {
    return 'Erlaubt Mitgliedern, mit dem Bot per DM zu chatten. Kann einen bezahlten $provider-Plan erfordern.';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return '$provider hat die App $appId erstellt.';
  }

  @override
  String chatRemainingSteps(String provider) {
    return 'Es bleiben ein paar Schritte, die nur $provider erledigen kann:';
  }

  @override
  String get chatStepAppToken => 'App-Token generieren';

  @override
  String get chatStepInstall => 'App installieren';

  @override
  String get chatOpenAppSettings => 'App-Einstellungen öffnen';

  @override
  String get chatContinueToCredentials => 'Zugangsdaten einfügen';

  @override
  String chatBotUpdated(String provider) {
    return 'Bot in $provider aktualisiert.';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return '$provider hat die Berechtigungen der App geändert. Installiere die App neu, damit sie wirksam werden.';
  }

  @override
  String get chatReinstallApp => 'App neu installieren';

  @override
  String chatIconNotEditable(String provider) {
    return 'Das Bot-Symbol lässt sich nur in den App-Einstellungen von $provider ändern.';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return 'Du kannst sie auch selbst in $provider erstellen – ohne Token. Die Einstellungen oben werden mit dem Link übergeben.';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return 'In $provider erstellen';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return '$provider wurde im Browser mit dieser vorbefüllten Konfiguration geöffnet. Erstelle die App dort, schließe diese Schritte ab und komm mit den Tokens zurück.';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return '$provider meldet nicht, welche App erstellt wurde. Den Bot von hier aus anzupassen, braucht später ein App-Konfigurationstoken.';
  }

  @override
  String get chatStepCreateApp =>
      'App aus der vorbefüllten Konfiguration erstellen';

  @override
  String chatStepCreateAppHint(String provider) {
    return 'Wähle in $provider einen Workspace und bestätige.';
  }

  @override
  String get chatStepAppTokenHint =>
      'Basic information → app-level tokens, mit dem Bereich connections:write.';

  @override
  String get chatStepInstallHint =>
      'Install app → kopiere das OAuth-Token des Bot-Nutzers.';

  @override
  String get calendarUseBuiltinApp => 'Google-App von Control Center verwenden';

  @override
  String get calendarUseBuiltinAppHint =>
      'Mit deinem Google-Konto freigeben. In Google Cloud ist nichts einzurichten.';

  @override
  String get calendarUseOwnClient => 'Eigenen Google-Cloud-Client verwenden';

  @override
  String get calendarUseOwnClientHint =>
      'Gib einen OAuth-Client aus deinem eigenen Google-Cloud-Projekt ein.';

  @override
  String get aboutTitle => 'Info';

  @override
  String get aboutAppVersion => 'App-Version';

  @override
  String get aboutServerVersion => 'Verbundener Server';

  @override
  String get aboutRpcCatalog => 'RPC-Katalog';

  @override
  String get aboutServerUnknown => 'Nicht gemeldet';

  @override
  String get serverStaleTitle =>
      'Der gebündelte Server ist älter als diese App';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return 'Der laufende cc_server ist $serverVersion, während diese App $appVersion ist. Starte die App neu, damit sie den neuesten gebündelten Server-Build verwendet; in der Entwicklung baust du ihn mit `dart build cli` in apps/cc_server neu.';
  }

  @override
  String get updateCheckButton => 'Nach Updates suchen';

  @override
  String get updateChecking => 'Suche nach Updates…';

  @override
  String get updateUpToDate => 'Du bist auf dem neuesten Stand';

  @override
  String get updateDeferredBusy =>
      'Ein Update ist bereit, aber ein Meeting wird aufgenommen — es wird nach dem Ende angezeigt.';

  @override
  String get updateOpenedReleasesPage =>
      'Die Release-Seite wurde in deinem Browser geöffnet.';

  @override
  String get updateCheckFailed => 'Update-Suche fehlgeschlagen';

  @override
  String updateAvailableVersion(String version) {
    return 'Version $version ist verfügbar.';
  }

  @override
  String get updateBannerTitle =>
      'Eine neue Version von Control Center ist verfügbar';

  @override
  String get updateBannerRefresh => 'Aktualisieren';

  @override
  String get updateBlockedRecording =>
      'Das Aktualisieren ist pausiert, während ein Meeting aufgenommen wird — die Seite lädt danach neu.';

  @override
  String get settingsScopeYou => 'Du';

  @override
  String get settingsScopeWorkspace => 'Arbeitsbereich';

  @override
  String get settingsScopeServer => 'Server';

  @override
  String get settingsProfile => 'Profil und Identität';

  @override
  String get settingsYourDevices => 'Deine Geräte';

  @override
  String get settingsWorkspaceGeneral => 'Allgemein';

  @override
  String get settingsServerConnection => 'Verbindung und Status';

  @override
  String get settingsModelProviders => 'Modellanbieter';

  @override
  String get settingsVoiceModels => 'Sprach- und Meeting-Modelle';

  @override
  String get settingsDiagnostics => 'Diagnose und Datenschutz';

  @override
  String get settingsAbout => 'Über';

  @override
  String get settingsScopeBadgeYou => 'DU';

  @override
  String get settingsScopeBadgeDevice => 'DIESES GERÄT';

  @override
  String get settingsScopeBadgeWorkspace => 'ARBEITSBEREICH';

  @override
  String get settingsScopeBadgeServer => 'SERVER';

  @override
  String get settingsProfileDescription =>
      'Dein Name, deine E-Mail und die Git-Identität, die auf Commits in deinem Namen steht.';

  @override
  String get settingsServerConnectionDescription =>
      'Der Server, mit dem dieser Client spricht, und wie dieser Server geteilt wird (mDNS, Tunnel, Relay).';

  @override
  String get settingsAboutDescription => 'Build-Identität und Updates.';

  @override
  String get settingsDiagnosticsDescription =>
      'Isolation, Indizierung, Synchronisierung, Logging und Absturzberichte dieser Installation.';

  @override
  String get settingsWorkspaceGeneralDescription =>
      'Identität, Richtlinien und Konventionen, die alle in diesem Arbeitsbereich teilen.';

  @override
  String get settingsWorkspacePolicyLabel => 'Arbeitsbereichs-Richtlinien';

  @override
  String get settingsWorkspacePolicyDescription =>
      'Gilt für jedes Mitglied und jeden Agenten in diesem Arbeitsbereich.';

  @override
  String get settingsSecretGlobsLabel => 'Ausgeschlossene Geheimnispfade';

  @override
  String get settingsSecretGlobsHelp =>
      'Ein Muster pro Zeile. Diese Pfade werden Betrachtern und Gästen auf Code-Oberflächen verborgen, zusätzlich zu den Standardwerten.';

  @override
  String get settingsReviewConcurrencyLabel => 'Parallele Prüfer';

  @override
  String get settingsReviewConcurrencyHelp =>
      'Wie viele Prüfer parallel gestartet werden, wenn keine Anzahl angegeben ist.';

  @override
  String get settingsReviewLevelLabel => 'Prüftiefe';

  @override
  String get settingsReviewLevelHelp =>
      'Wie tief die KI-Prüfung geht und wie viel davon vorne steht. Nichts wird verworfen — eine leichtere Stufe gruppiert kleinere Befunde, statt sie wegzulassen.';

  @override
  String get reviewLevelLight => 'Leicht';

  @override
  String get reviewLevelBalanced => 'Ausgewogen';

  @override
  String get reviewLevelThorough => 'Gründlich';

  @override
  String get reviewLevelLightHint =>
      'Ein Prüfer. Vorne steht nur, was wirklich zählt.';

  @override
  String get reviewLevelBalancedHint =>
      'Drei Prüfer für Qualität, Architektur und Umsetzung.';

  @override
  String get reviewLevelThoroughHint =>
      'Ergänzt Sicherheits- und Performance-Spezialisten und meldet alles Gefundene.';

  @override
  String get askAiReviewAtLevel => 'Mit anderer Prüftiefe prüfen';

  @override
  String reviewNitpicksGroup(int count) {
    return 'Kleinigkeiten ($count)';
  }

  @override
  String get reviewFindingResolve => 'Behoben';

  @override
  String get reviewFindingResolveHint =>
      'Diesen Befund als behoben markieren. Er zählt nicht mehr für die Prüfung.';

  @override
  String get reviewFindingDismiss => 'Verwerfen';

  @override
  String get reviewFindingDismissHint =>
      'Kein echtes Problem. Prüfer melden dieses Muster künftig nicht mehr.';

  @override
  String get reviewFindingReopen => 'Wieder öffnen';

  @override
  String get reviewFindingStatusUndoLabel => 'Befundstatus';

  @override
  String get reviewFindingDismissTitle => 'Diesen Befund verwerfen';

  @override
  String get reviewFindingDismissReasonHint =>
      'Warum trifft das nicht zu? Prüfer lesen es.';

  @override
  String reviewFindingStatusFailed(String error) {
    return 'Befund konnte nicht aktualisiert werden: $error';
  }

  @override
  String get reviewStaleTitle => 'Diese Prüfung ist veraltet';

  @override
  String get reviewStaleBody =>
      'Der Pull Request hat sich seit dieser Prüfung geändert. Befunde zeigen womöglich auf Code, den es nicht mehr gibt.';

  @override
  String reviewStaleReviewedAt(String sha) {
    return 'Geprüft bei $sha';
  }

  @override
  String get reviewStaleRerun => 'Erneut prüfen';

  @override
  String reviewStaleNotificationTitle(int prNumber) {
    return 'Prüfung veraltet bei #$prNumber';
  }

  @override
  String reviewStaleNotificationBody(String title) {
    return '$title hat neue Commits seit der letzten Prüfung.';
  }

  @override
  String get reviewCategorySecurity => 'Sicherheit';

  @override
  String get reviewCategoryStability => 'Stabilität';

  @override
  String get reviewCategoryDataIntegrity => 'Datenintegrität';

  @override
  String get reviewCategoryCorrectness => 'Korrektheit';

  @override
  String get reviewCategoryPerformance => 'Performance';

  @override
  String get reviewCategoryMaintainability => 'Wartbarkeit';

  @override
  String get reviewEffortQuickWin => 'Schneller Gewinn';

  @override
  String get reviewEffortModerate => 'Mittel';

  @override
  String get reviewEffortHeavyLift => 'Großer Aufwand';

  @override
  String get reviewProposedFix => 'Vorgeschlagene Korrektur';

  @override
  String get reviewAiAgentPrompt => 'Anweisung für KI-Agenten';

  @override
  String get reviewCopyAiPrompt => 'Anweisung kopieren';

  @override
  String get settingsWorkspaceAdminOnly =>
      'Nur Arbeitsbereichs-Admins können das ändern.';

  @override
  String get chatMyAccountsTitle => 'Verknüpfte Chat-Konten';

  @override
  String get settingsServerSso => 'Single sign-on';

  @override
  String get settingsServerSsoDescription =>
      'SAML- und OpenID-Connect-Anmeldung mit Benutzerbereitstellung';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabledDescription =>
      'Benutzer können sich mit diesem Anbieter anmelden';

  @override
  String get ssoEnabledDescriptionOn =>
      'Die Anmeldung ist für diesen Anbieter aktiv';

  @override
  String get ssoIdpMetadataLabel => 'IdP-Metadaten-XML';

  @override
  String get ssoIdpMetadataHint => 'EntityDescriptor-XML des IdP einfügen';

  @override
  String get ssoEmailAttributeLabel => 'E-Mail-Attribut';

  @override
  String get ssoDisplayNameAttributeLabel => 'Anzeigename-Attribut';

  @override
  String get ssoGroupsAttributeLabel => 'Gruppen-Attribut';

  @override
  String get ssoIssuerLabel => 'Aussteller-URL';

  @override
  String get ssoClientIdLabel => 'Client-ID';

  @override
  String get ssoGroupsClaimLabel => 'Gruppen-Claim';

  @override
  String get ssoAutoMemberLabel =>
      'Benutzer bei der ersten Anmeldung zu jedem Workspace hinzufügen';

  @override
  String get ssoAutoMemberDescription =>
      'Ausschalten, um eine Einladung pro Workspace zu verlangen';

  @override
  String get ssoAllowJitLabel =>
      'Unbekannte Benutzer bei der ersten Anmeldung bereitstellen';

  @override
  String get ssoAllowJitDescription =>
      'Ausschalten, um Benutzer ohne bestehendes Konto abzuweisen';

  @override
  String get ssoAllowIdpInitiatedLabel =>
      'Vom IdP initiierte Anmeldungen akzeptieren';

  @override
  String get ssoAllowIdpInitiatedDescription =>
      'Nur für IdP-Portale, die Apps direkt starten';

  @override
  String get ssoWantResponseSignedLabel =>
      'Signierten Antwort-Umschlag verlangen';

  @override
  String get ssoWantResponseSignedDescription =>
      'Assertions-Signaturen sind immer erforderlich';

  @override
  String get ssoTestConnectionButton => 'Verbindung testen';

  @override
  String get ssoTestConnectionOk => 'Verbindung funktioniert:';

  @override
  String get ssoCopySpMetadata => 'SP-Metadaten kopieren';

  @override
  String get ssoCopySpMetadataDone =>
      'SP-Metadaten in die Zwischenablage kopiert';

  @override
  String get ssoSavedToast => 'Single-Sign-on-Einstellungen gespeichert';

  @override
  String get ssoUnavailable =>
      'Dieser Server stellt keine Single-Sign-on-Einstellungen bereit. Aktualisiere die Server-Binärdatei und versuche es erneut.';

  @override
  String get ssoScimCardTitle => 'Benutzerbereitstellung (SCIM)';

  @override
  String get ssoScimDescription =>
      'Richte den SCIM-Connector deines Identitätsanbieters auf den Endpoint unten mit einem Bearer-Token. Beim Deprovisionieren werden Sitzungen und Workspace-Zugriffe in Sekunden entzogen. Der Server muss vom IdP erreichbar sein (Tunnel oder öffentliche URL).';

  @override
  String get ssoScimEndpoint => 'SCIM-Endpoint';

  @override
  String get ssoScimEndpointUnknownOrigin =>
      'Lege zuerst die öffentliche URL des Servers fest oder aktiviere einen Tunnel';

  @override
  String get ssoScimRegenerate => 'Token neu generieren';

  @override
  String get ssoScimRegenerateConfirm =>
      'Neues SCIM-Bearer-Token generieren? Das bisherige Token funktioniert sofort nicht mehr.';

  @override
  String get ssoScimTokenTitle => 'Bearer-Token';

  @override
  String get ssoScimTokenPresent => 'Ein Token ist konfiguriert';

  @override
  String get ssoScimTokenAbsent =>
      'Noch kein Token – generiere eines, um SCIM zu aktivieren';

  @override
  String get ssoScimTokenOnce => 'SCIM-Token (einmalig angezeigt)';

  @override
  String ssoSignInWith(String provider) {
    return 'Mit $provider anmelden';
  }

  @override
  String get ssoProbeFailed => 'Server für Single sign-on nicht erreichbar';

  @override
  String get ssoOpensBrowser =>
      'Öffnet deinen Browser, um die Anmeldung abzuschließen';

  @override
  String get ssoWaitingForBrowser =>
      'Wartet auf deinen Browser, um die Anmeldung abzuschließen…';

  @override
  String get ssoBrowserOpenFailed =>
      'Browser für Single sign-on konnte nicht geöffnet werden';

  @override
  String get ssoUseManualPairing =>
      'Stattdessen mit Einladungscode oder Kopplungsschlüssel anmelden';

  @override
  String get ssoHideManualPairing => 'Manuelle Kopplung ausblenden';

  @override
  String get ssoClientIdHint => 'Public-Client (PKCE) — kein Secret nötig';

  @override
  String get ssoClientSecretLabel => 'Client-Secret (optional)';

  @override
  String get ssoClientSecretHintUnset =>
      'Nur für vertrauliche IdP-Clients nötig';

  @override
  String get ssoClientSecretHintSet =>
      'Ein Secret ist gespeichert — leer lassen, um es zu behalten';

  @override
  String get ssoPairingToggle =>
      'Manuelle Kopplung erlauben (Einladungscodes und Kopplungsschlüssel)';

  @override
  String get ssoPairingToggleDescription =>
      'Ausschalten, damit der Beitritt nur über Single sign-on läuft — neue Geräte kommen über SSO-Logins; bestehende Geräte funktionieren weiter';

  @override
  String get ssoPairConfirmTitle => 'Mit Server verbinden?';

  @override
  String ssoPairConfirmBody(String server) {
    return 'Für $server ist eine Anmeldeberechtigung eingegangen, aber von dieser App wurde keine Anmeldung gestartet. Mit diesem Server verbinden?';
  }

  @override
  String get ssoPairConfirmConnect => 'Verbinden';

  @override
  String get ssoPairConfirmCancel => 'Ignorieren';

  @override
  String get forgeConnections => 'Code-Hosting';

  @override
  String get connect => 'Verbinden';

  @override
  String get disconnect => 'Trennen';

  @override
  String get notConnected => 'Nicht verbunden';

  @override
  String get checkingConnection => 'Verbindung wird geprüft…';

  @override
  String get fromEnvironment => 'aus der Umgebung';

  @override
  String forgeTokenTitle(String forge) {
    return '$forge-Token';
  }

  @override
  String get settingsAudio => 'Audio';

  @override
  String get settingsAudioDescription =>
      'Mikrofon, Diktat, Besprechungserkennung und Klanglandschafts-Ausgabe.';

  @override
  String get audioDevicesSection => 'Audiogeräte';

  @override
  String get voiceInputBehaviorSection => 'Diktat und Besprechungen';

  @override
  String get audioOutputDeviceTitle => 'Ausgabegerät';

  @override
  String get audioOutputDefaultHint =>
      'Der gesamte App-Ton wird über die System-Standardausgabe wiedergegeben.';

  @override
  String get audioOutputGone =>
      'Das ausgewählte Ausgabegerät ist nicht mehr verbunden — bis zur Neuauswahl wird die System-Standardausgabe verwendet.';

  @override
  String get reviewHubIntroBody =>
      'Die Agenten analysieren den Diff, kartieren die Änderungsbereiche und erzielen ein Konsensurteil.';

  @override
  String get reviewHubAlreadyRunning =>
      'Für diesen Pull-Request läuft bereits ein Review';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return 'Seit der letzten Prüfung: $resolved gelöst · $added neu · $open noch offen';
  }

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return 'Zuvor geprüft bei $sha';
  }

  @override
  String reviewArtifactFixAll(int count) {
    return '$count Befunde beheben';
  }

  @override
  String reviewArtifactFixSelected(int count) {
    return '$count ausgewählte korrigieren';
  }

  @override
  String reviewArtifactCommentSelected(int count) {
    return '$count ausgewählte kommentieren';
  }

  @override
  String get webConnectTitle => 'Mit Control Center verbinden';

  @override
  String get webConnectSubtitle =>
      'Einen laufenden cc-server über WebSocket verbinden. Dein Schlüssel bleibt auf diesem Gerät.';

  @override
  String get webConnectServerLabel => 'Server';

  @override
  String get webConnectDeviceIdLabel => 'Geräte-ID';

  @override
  String get webConnectPairingKeyLabel => 'Kopplungsschlüssel';

  @override
  String get webConnectPairingKeyHint => 'PSK einfügen';

  @override
  String get webConnectStayConnected => 'Auf diesem Gerät verbunden bleiben';

  @override
  String get webConnectStayConnectedDetail =>
      'Auf diesem Gerät verbunden bleiben (speichert deinen Schlüssel in diesem Browser)';

  @override
  String failedToCreateWorkspace(String error) {
    return 'Arbeitsbereich konnte nicht erstellt werden: $error';
  }

  @override
  String committedRelative(String relative) {
    return 'committet $relative';
  }

  @override
  String get selectAgents => 'Agenten auswählen';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Agenten',
      one: '1 Agent',
    );
    return '$_temp0';
  }

  @override
  String get newConversation => 'Neue Konversation';

  @override
  String get untitledConversation => 'Unterhaltung ohne Titel';

  @override
  String get conversationTitleOptionalHint =>
      'Optional — leer lassen, dann benennt das Titelmodell sie automatisch';

  @override
  String get conversationTitlesSectionTitle => 'Unterhaltungstitel';

  @override
  String get conversationTitlesSectionCaption =>
      'Wähle den Runner, der neue Unterhaltungen in diesem Arbeitsbereich automatisch benennt. Titel bleiben aus, bis ein Adapter gewählt wird, und gelten für jedes Mitglied.';

  @override
  String get conversationTitlesModelLabel => 'Titelmodell';

  @override
  String get conversationTitlesAdapterLabel => 'Adapter';

  @override
  String get conversationTitlesAdapterHint => 'Aus';

  @override
  String get conversationTitlesAdapterOff => 'Aus';

  @override
  String get startThread => 'Thread starten';

  @override
  String get deleteSpaceConfirm =>
      'Diesen Bereich löschen? Alle Nachrichten gehen verloren.';

  @override
  String threadTabTitle(String title) {
    return 'Thread: $title';
  }

  @override
  String threadReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Antworten',
      one: '1 Antwort',
    );
    return '$_temp0';
  }

  @override
  String threadLastReply(String time) {
    return 'Letzte Antwort $time';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Mit $provider anmelden';
  }

  @override
  String get signInAgain => 'Erneut anmelden';

  @override
  String get signInNotFinished =>
      'Die Anmeldung ist noch nicht zurück. Schließe sie im Browser ab und prüfe dann erneut.';

  @override
  String get signedOutTitle => 'Du bist abgemeldet';

  @override
  String get signedOutSubtitle =>
      'Deine Verbindung zum Code-Host ist nicht mehr gültig — ein Token ist abgelaufen oder sein Zugriff wurde widerrufen. Sonst hat sich nichts geändert: Melde dich wieder an und alles ist da, wo du es verlassen hast.';

  @override
  String get viaServerApp => 'über die App dieses Servers';

  @override
  String get ticketing => 'Tickets';

  @override
  String get ticketingProviderHelp =>
      'Wo deine Tickets leben. Lokal behält sie in Control Center.';

  @override
  String providerComingSoon(String provider) {
    return '$provider (bald)';
  }

  @override
  String get ticketProviderLocal => 'Lokal';

  @override
  String get addKey => 'Schlüssel hinzufügen';

  @override
  String get providerApps => 'Anbieter-Apps';

  @override
  String get providerAppsDescription =>
      'Wie sich dieser Server selbst authentifiziert und womit sich eine Person anmeldet. Hintergrundarbeit — Webhooks, Polling, Sync — läuft über die App, nie über das Token einer Person.';

  @override
  String get providerAppId => 'App-ID';

  @override
  String get providerPrivateKey => 'Privater Schlüssel';

  @override
  String get providerClientId => 'Client-ID';

  @override
  String get providerClientSecret => 'Client-Secret';

  @override
  String get providerApiKey => 'API-Schlüssel';

  @override
  String get providerCallbackUrl => 'Callback-URL';

  @override
  String get providerAppFullyConfigured =>
      'Der Server kann für sich selbst handeln, und Personen können sich anmelden.';

  @override
  String get providerAppServerOnly =>
      'Der Server kann für sich selbst handeln. Füge Client-ID und Secret hinzu, damit sich Personen anmelden können.';

  @override
  String get providerAppSignInOnly =>
      'Personen können sich anmelden. Hintergrundarbeit greift auf ihre Zugangsdaten zurück.';

  @override
  String providerAppInstalledOn(String accounts) {
    return 'Die Zugangsdaten funktionieren. Installiert bei: $accounts';
  }

  @override
  String deviceCodeInstructions(String provider) {
    return 'Gib diesen Code auf der soeben geöffneten $provider-Seite ein. Er liegt bereits in deiner Zwischenablage.';
  }

  @override
  String get deviceCodeWaiting =>
      'Warte darauf, dass du im Browser fertig wirst…';

  @override
  String get copyCodeAndOpen => 'Code kopieren und öffnen';

  @override
  String get couldNotOpenBrowser =>
      'Es konnte kein Browser geöffnet werden. Kopiere den Link und schließe die Anmeldung selbst ab.';

  @override
  String get contextUsage => 'Kontextnutzung';

  @override
  String get contextUsageFull => 'voll';

  @override
  String get contextUsageTokens => 'Token';

  @override
  String get contextSeeMore => 'Mehr anzeigen';

  @override
  String get contextSegmentSystemPrompt => 'System-Prompt';

  @override
  String get contextSegmentRules => 'Regeln';

  @override
  String get contextSegmentSkills => 'Skills';

  @override
  String get contextSegmentToolDefinitions => 'Tool-Definitionen';

  @override
  String get contextSegmentMcpTools => 'MCP & dynamische Tools';

  @override
  String get contextSegmentDeferredTools => 'Bei Bedarf geladene Tools';

  @override
  String get contextSegmentSubagents => 'Subagent-Definitionen';

  @override
  String get contextSegmentMemory => 'Speicher';

  @override
  String get contextSegmentConversation => 'Konversation';

  @override
  String get contextExplorerTitle => 'Kontext';

  @override
  String get contextExplorerEverything => 'Alles';

  @override
  String get contextExplorerSelectPart =>
      'Wähle einen Teil aus, um seinen Inhalt zu prüfen';

  @override
  String get contextExplorerUnavailable =>
      'Kontextaufschlüsselung nicht verfügbar';

  @override
  String get contextRetry => 'Erneut versuchen';

  @override
  String get settingsFieldOptional => 'Optional';

  @override
  String get settingsFilterHint => 'Diese Liste filtern';

  @override
  String get settingsValueNotAvailable => 'Noch nicht verfügbar';

  @override
  String get settingsNoEntriesYet => 'Noch nichts vorhanden';

  @override
  String get settingsChangedBadge => 'Geändert';

  @override
  String get ssoConnectionCardDescription =>
      'Legen Sie fest, wie sich Personen an diesem Server anmelden, und aktivieren Sie dann diese Verbindung.';

  @override
  String get ssoUseSamlForSignIn => 'SAML für die Anmeldung verwenden';

  @override
  String get ssoUseOidcForSignIn =>
      'OpenID Connect für die Anmeldung verwenden';

  @override
  String get ssoSaveConnection => 'Verbindung speichern';

  @override
  String get ssoStateLive => 'Aktiv';

  @override
  String get ssoStateConfiguredOff => 'Konfiguriert, aus';

  @override
  String get ssoStateOnIncomplete => 'Ein, unvollständig';

  @override
  String get ssoStateActive => 'Aktiv';

  @override
  String get ssoStateAllowed => 'Erlaubt';

  @override
  String get ssoStateNoToken => 'Kein Token';

  @override
  String get ssoSummaryDirectorySync => 'Verzeichnisabgleich';

  @override
  String get ssoSummaryManualPairing => 'Manuelle Kopplung';

  @override
  String get ssoNoMethodLiveNote =>
      'Keine Anmeldemethode ist aktiv. Neue Geräte verbinden sich mit einer Einladung oder einem Kopplungsschlüssel, bis Sie eine Verbindung einrichten und aktivieren.';

  @override
  String get ssoMethodSamlBlurb =>
      'Für Identitätsanbieter, die SAML 2.0 sprechen, etwa Okta, Entra ID oder Google Workspace.';

  @override
  String get ssoMethodOidcBlurb =>
      'Für Identitätsanbieter, die OpenID Connect sprechen. Meist die einfachere der beiden Einrichtungen.';

  @override
  String get ssoGroupIdentityProvider => 'Identitätsanbieter';

  @override
  String get ssoGroupIdentityProviderSamlDescription =>
      'Woher die Assertions kommen und wie dieser Server sie prüft.';

  @override
  String get ssoGroupIdentityProviderOidcDescription =>
      'Welchem Issuer dieser Server vertraut und als welcher Client er sich authentifiziert.';

  @override
  String get ssoSpEntityIdShortLabel => 'SP-Entity-ID';

  @override
  String get ssoSpEntityIdDescription =>
      'Leer lassen, um sie aus der Server-URL abzuleiten.';

  @override
  String get ssoIssuerDescription =>
      'Die Basis-URL, die das Discovery-Dokument des Anbieters ausliefert.';

  @override
  String get ssoSecretStored => 'Gespeichert';

  @override
  String get ssoGroupHandoff => 'Was Ihr Identitätsanbieter braucht';

  @override
  String get ssoGroupHandoffDescription =>
      'Fügen Sie diese Werte in die Anwendung ein, die Sie bei Ihrem Anbieter angelegt haben.';

  @override
  String get ssoOriginUnknownTitle =>
      'Dieser Server kennt seine öffentliche URL nicht';

  @override
  String get ssoOriginUnknownBody =>
      'Die Anmelde- und Callback-URLs werden daraus gebildet, daher kann Ihr Anbieter diesen Server erst erreichen, wenn eine gesetzt ist. Fügen Sie unter Server → Verbindung eine öffentliche URL hinzu oder aktivieren Sie einen Tunnel.';

  @override
  String get ssoAcsUrlLabel => 'Assertion-Consumer-Service-URL (ACS)';

  @override
  String get ssoAcsUrlDescription =>
      'Wohin Ihr Anbieter die signierte Assertion sendet.';

  @override
  String get ssoSpEntityIdResolvedLabel => 'Entity-ID des Service Providers';

  @override
  String get ssoMetadataUrlLabel => 'SP-Metadaten-URL';

  @override
  String get ssoMetadataUrlDescription =>
      'Anbieter, die Metadaten importieren, können sie hier abrufen.';

  @override
  String get ssoRedirectUriLabel => 'Redirect-URI';

  @override
  String get ssoRedirectUriDescription =>
      'Tragen Sie sie in die erlaubten Redirect-URIs der Anwendung Ihres Anbieters ein.';

  @override
  String get ssoSignInUrlLabel => 'Anmelde-URL';

  @override
  String get ssoSignInUrlDescription =>
      'Schicken Sie Personen hierher, um eine Single-Sign-on-Anmeldung zu starten.';

  @override
  String get ssoGroupAttributeMapping => 'Attributzuordnung';

  @override
  String get ssoGroupAttributeMappingDescription =>
      'Welcher Claim welches Feld trägt. Belassen Sie die Standardwerte, sofern Ihr Anbieter sie nicht umbenennt.';

  @override
  String get ssoGroupAccess => 'Zugriff und Rollen';

  @override
  String get ssoGroupAccessDescription =>
      'Was jemand darf, der sich erfolgreich anmeldet.';

  @override
  String get ssoDefaultRoleShortLabel => 'Standardrolle';

  @override
  String get ssoDefaultRoleDescription =>
      'Wird jedem zugewiesen, dessen Gruppen keiner Zuordnung unten entsprechen.';

  @override
  String get ssoRoleMapShortLabel => 'Gruppen-zu-Rollen-Zuordnung';

  @override
  String get ssoRoleMapDescription =>
      'Die erste passende Gruppe gewinnt. Die Besitzerrolle lässt sich so nicht vergeben.';

  @override
  String get ssoRoleMapGroupHint => 'Gruppenname bei Ihrem Anbieter';

  @override
  String get ssoRoleMapAdd => 'Zuordnung hinzufügen';

  @override
  String get ssoRoleMapEmpty =>
      'Keine Zuordnungen – alle erhalten die Standardrolle.';

  @override
  String get ssoAdvancedSummary =>
      'Zeitversatz, IdP-initiierte Anmeldung, Signaturrichtlinie';

  @override
  String get ssoClockSkewShortLabel => 'Zeitversatz';

  @override
  String get ssoClockSkewDescription =>
      'Toleranz in Sekunden für Assertion-Zeitstempel. 90 passt für die meisten Anbieter.';

  @override
  String get ssoScimGenerate => 'Token erzeugen';

  @override
  String get ssoScimTokenOnceBody =>
      'In die Zwischenablage kopiert. Er wird nur einmal angezeigt und lässt sich nicht wiederherstellen – fügen Sie ihn jetzt bei Ihrem Anbieter ein.';

  @override
  String get ssoPairingCardTitle => 'Manuelle Kopplung';

  @override
  String get ssoPairingCardDescription =>
      'Der andere Weg auf diesen Server: Einladungscodes und Kopplungsschlüssel für Geräte, die nicht über Single Sign-on kommen.';

  @override
  String settingsCountOfTotal(int count, int total) {
    return '$count von $total';
  }

  @override
  String get providersNoneConnectedNote =>
      'Kein Anbieter ist verbunden, daher hat die integrierte Agentenlaufzeit nichts, worauf sie laufen kann. Fügen Sie unten einen API-Schlüssel hinzu oder melden Sie sich bei einem an.';

  @override
  String get providersFilterHint => 'Anbieter filtern';

  @override
  String get providersFacetNeedsSetup => 'Einrichtung nötig';

  @override
  String get providersFacetCustom => 'Eigene';

  @override
  String get providersNoneMatch => 'Nichts passt zu diesem Filter';

  @override
  String get providerDeniedHereTitle => 'In diesem Workspace verweigert';

  @override
  String get providerDeniedHereBody =>
      'Agenten hier können diesen Anbieter nicht nutzen, obwohl er verbunden ist. Andere Workspaces sind nicht betroffen.';

  @override
  String get providerNeedsSignIn => 'Zum Nutzen dieses Anbieters anmelden';

  @override
  String get providerNeedsApiKey =>
      'Zum Nutzen dieses Anbieters einen API-Schlüssel hinzufügen';

  @override
  String get providerApiKeyLabel => 'API-Schlüssel';

  @override
  String get providerGenerationDefaults => 'Anbieterstandards';

  @override
  String get providerNoModelsYet =>
      'Noch keine Modelle gemeldet. Verbinden Sie den Anbieter und synchronisieren Sie dann.';

  @override
  String get providerModelsFilterHint => 'Modelle filtern';

  @override
  String get adaptersNoneReadyNote =>
      'Keine der katalogisierten Runner-CLIs wurde auf diesem Rechner gefunden. Installieren Sie eine und aktualisieren Sie dann.';

  @override
  String get adaptersFilterHint => 'Runner filtern';

  @override
  String get adaptersFacetReady => 'Bereit';

  @override
  String get adaptersFacetMissing => 'Fehlend';

  @override
  String get adaptersLaunchGroup => 'Start';

  @override
  String get adaptersLaunchGroupDescription =>
      'Was dieser Runner erhält, wenn ein Agent ihn startet. Sie können das auch vor der Installation der CLI festlegen.';

  @override
  String get adaptersEnvNone => 'Keine gesetzt';

  @override
  String adaptersEnvCount(int count) {
    return '$count gesetzt';
  }

  @override
  String get adapterArgumentsDescription =>
      'Wird bei jedem Start an die Befehlszeile des Runners angehängt.';

  @override
  String get defaultChatDescription =>
      'Führt neue Unterhaltungen aus und jeden Agenten ohne eigenen Runner.';

  @override
  String get shortTaskDescription =>
      'Erledigt kurze Hintergrundarbeit wie Titel und Zusammenfassungen. Hier passt ein kleineres Modell.';

  @override
  String get settingsStateFailed => 'Fehlgeschlagen';

  @override
  String get providerAppsGroupServer => 'Als Server handeln';

  @override
  String get providerAppsGroupServerDescription =>
      'Ermöglicht Hintergrundarbeiten den Zugriff auf Repositories ohne Person hinter der Anfrage: Webhooks, Pull-Request-Abfragen, Ticket-Abgleich.';

  @override
  String get providerAppsGroupPrConversations => 'Pull-Request-Konversationen';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      'Wie Entwickler direkt auf GitHub mit diesem Server sprechen können. Funktioniert ohne Webhook und ohne öffentliche URL — der Server fragt regelmäßig ab.';

  @override
  String get providerAppBotLogin => 'Bot-Login';

  @override
  String get providerAppBotLoginEmpty =>
      'Teste die Verbindung, um den Bot-Login zu ermitteln.';

  @override
  String get providerAppAskOnGitHub => 'Auf GitHub fragen';

  @override
  String get providerAppAskOnGitHubHint =>
      'Erwähne den Bot-Login oben in einem Pull-Request-Kommentar — das Suffix [bot] ist optional —, um ein Review anzufordern oder eine Frage zu stellen, antworte in seinen Review-Threads oder füge das Label `ai-review` hinzu, um ein Review anzufordern.';

  @override
  String get providerAppsGroupSignIn => 'Personen anmelden';

  @override
  String get providerAppsGroupSignInDescription =>
      'Erlaubt jedem Mitglied, das eigene Konto zu verbinden und eigene Zugangsdaten zu erhalten.';

  @override
  String get providerAppCapActsAsServer => 'Handelt als Server';

  @override
  String get providerAppCapSignsIn => 'Meldet Personen an';

  @override
  String get portLabel => 'Port';

  @override
  String get mcpNoTokenWarning =>
      'Ohne Token kann alles, was diesen Port erreicht, jedes Werkzeug aufrufen.';

  @override
  String get mcpBridgedToolsLabel => 'Werkzeuge';

  @override
  String get guardrailFamilyFiles => 'Dateien';

  @override
  String get guardrailFamilyGit => 'Git und Pull Requests';

  @override
  String get guardrailFamilyMachine => 'Maschine und Netzwerk';

  @override
  String get guardrailFamilyControl => 'Geheimnisse und Workspace';

  @override
  String get guardrailScopeFieldLabel => 'Regeln bearbeiten für';

  @override
  String get guardrailScopeFieldDescription =>
      'Ein engerer Geltungsbereich schlägt einen weiteren. Hier gesetzte Regeln gelten zusätzlich zum Geerbten.';

  @override
  String get guardrailSetHere => 'Hier gesetzt';

  @override
  String get guardrailClearAllHere => 'Alle löschen';

  @override
  String get sandboxingCardLabel => 'Sandboxing';

  @override
  String get sandboxingCardDescription =>
      'Ob Agentenarbeit isoliert von diesem Host läuft und was ein isolierter Agent trotzdem erreichen kann.';

  @override
  String get sandboxBackendNoneActive => 'Host, keine Isolation';

  @override
  String get sandboxSummaryHost => 'Host';

  @override
  String get sandboxGroupIsolation => 'Isolation';

  @override
  String get sandboxGroupIsolationDescription =>
      'Wo die Prozesse und Dateischreibvorgänge eines Agenten tatsächlich stattfinden.';

  @override
  String get sandboxBackendFieldDescription =>
      'Automatisch wählt den stärksten, den dieser Host unterstützt. Fixieren Sie einen, damit er sich nicht von selbst ändert.';

  @override
  String get sandboxCapabilitiesDescription =>
      'Die Löcher in der Abgrenzung. Jedes ist etwas, das ein isolierter Agent weiterhin nach außen tun kann.';

  @override
  String get sandboxSummaryInForce => 'Aktiv in Kraft';

  @override
  String get rigsInstallHintLabel => 'So installieren Sie es';

  @override
  String get rigsStarting => 'Startet';

  @override
  String get rigsResidentMemory => 'Belegter Speicher';

  @override
  String get installedLabel => 'Installiert';

  @override
  String get notInstalledLabel => 'Nicht installiert';

  @override
  String ssoOtherKindUnsaved(String method) {
    return '$method hat ungespeicherte Änderungen';
  }

  @override
  String get collapseComment => 'Kommentar einklappen';

  @override
  String get expandComment => 'Kommentar ausklappen';

  @override
  String get suggestedChange => 'Vorgeschlagene Änderung';

  @override
  String get emptyComment => 'Leerer Kommentar';

  @override
  String repliesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Antworten',
      one: '1 Antwort',
    );
    return '$_temp0';
  }

  @override
  String get pendingReview => 'Ausstehende Review';

  @override
  String failedToResolveConversation(String error) {
    return 'Konversation konnte nicht aktualisiert werden: $error';
  }

  @override
  String get addSingleComment => 'Einzelnen Kommentar hinzufügen';

  @override
  String get addToReview => 'Zur Review hinzufügen';

  @override
  String get startAReview => 'Review starten';

  @override
  String get reviewNeedsABody =>
      'Schreibe eine Zusammenfassung oder füge zuerst einen Inline-Kommentar hinzu';

  @override
  String get reviewSubmitted => 'Review abgeschickt';

  @override
  String get finishYourReview => 'Review abschließen';

  @override
  String get commentVerdict => 'Kommentieren';

  @override
  String pendingCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ausstehende Kommentare',
      one: '1 ausstehender Kommentar',
    );
    return '$_temp0';
  }

  @override
  String andNMore(int count) {
    return 'und $count weitere';
  }

  @override
  String get queuedCommentHint =>
      'Dieser Kommentar geht raus, wenn du deine Review abschickst.';

  @override
  String commentOnLinesRange(int start, int end) {
    return 'Zeilen $start bis $end';
  }

  @override
  String get claudeAccountsTitle => 'Claude-Code-Konten';

  @override
  String get claudeAccountsDescription =>
      'Jedes Konto ist eine eigene Claude-Code-Anmeldung. Läufe verwenden die unten zugewiesenen Konten, in dieser Reihenfolge.';

  @override
  String get claudeAccountsEmpty => 'Noch keine Konten';

  @override
  String get claudeAccountAdd => 'Konto hinzufügen';

  @override
  String get claudeAccountSignIn => 'Anmelden';

  @override
  String get claudeAccountSignInAgain => 'Erneut anmelden';

  @override
  String get claudeAccountSignInHint =>
      'Führen Sie dies in einem Terminal auf dem Server aus. Ein Browser öffnet sich, um die Anmeldung abzuschließen, und die Zugangsdaten werden in das Verzeichnis dieses Kontos geschrieben.';

  @override
  String get claudeAccountSignedOut => 'Abgemeldet';

  @override
  String get claudeAccountExpired => 'Anmeldung abgelaufen';

  @override
  String claudeAccountExpiredDetail(String when) {
    return 'Die Anmeldung ist um $when abgelaufen. Melde dich erneut an, um dieses Konto zu nutzen.';
  }

  @override
  String get claudeAccountMakeDefault => 'Als Standard festlegen';

  @override
  String get claudeAccountDefault => 'Standard';

  @override
  String claudeAccountRemoveConfirm(String label) {
    return '$label entfernen?';
  }

  @override
  String get claudeAccountRemoveDetail =>
      'Das Konto wird abgemeldet und sein Verzeichnis auf dem Server gelöscht. Die Anmeldung selbst bleibt unberührt.';

  @override
  String claudeAccountStatusUnknown(String error) {
    return 'Dieses Konto konnte nicht geprüft werden: $error';
  }

  @override
  String claudeAccountUsedPercent(String percent) {
    return '$percent % verbraucht';
  }

  @override
  String get accountPoolStrategy => 'Rotation';

  @override
  String get accountPoolPinned => 'Fest';

  @override
  String get accountPoolRoundRobin => 'Reihum';

  @override
  String get accountPoolSerial => 'Nacheinander';

  @override
  String get accountPoolPinnedHint =>
      'Immer mit dem ersten Konto beginnen. Die übrigen bleiben als Reserve, falls es fehlschlägt.';

  @override
  String get accountPoolRoundRobinHint =>
      'Läufe auf die Konten verteilen und bei jedem Start zum nächsten wechseln.';

  @override
  String get accountPoolSerialHint =>
      'Das erste Konto ausschöpfen, bevor das nächste angefasst wird.';

  @override
  String get accountPoolMoveUp => 'Nach oben';

  @override
  String get accountPoolMoveDown => 'Nach unten';

  @override
  String get accountPoolUsingAll =>
      'Noch nichts zugewiesen — es werden alle Konten verwendet, in dieser Reihenfolge.';

  @override
  String get accountPoolInheriting => 'Erbt die Konten des Arbeitsbereichs.';

  @override
  String get accountPoolResetToWorkspace =>
      'Auf die Konten des Arbeitsbereichs zurücksetzen';

  @override
  String accountPoolCoolingOff(String when) {
    return 'kein Kontingent bis $when';
  }

  @override
  String get accountPoolSignedOut => 'abgemeldet';

  @override
  String get accountPoolExpired => 'Anmeldung abgelaufen';

  @override
  String accountPoolLoadFailed(String error) {
    return 'Rotation konnte nicht geladen werden: $error';
  }

  @override
  String get providerSignedInAccount => 'angemeldetes Konto';

  @override
  String get agentAccountsTab => 'Konten';

  @override
  String get agentAccountsDescription =>
      'Welche Konten die Läufe dieses Agenten verwenden. Jeder Block erbt zunächst die Wahl des Arbeitsbereichs.';

  @override
  String get agentAccountsNothingToRotate =>
      'Nichts zu rotieren — verbinden Sie zuerst ein zweites Konto oder einen zweiten Schlüssel.';

  @override
  String failedToPostReply(String error) {
    return 'Antwort konnte nicht gesendet werden: $error';
  }

  @override
  String commentOnLine(int line) {
    return 'Zeile $line';
  }

  @override
  String get viewInDiff => 'Im Diff anzeigen';

  @override
  String get subscriptionUsagePreviousAccount => 'Vorheriges Konto';

  @override
  String get subscriptionUsageNextAccount => 'Nächstes Konto';

  @override
  String inReplyTo(String path) {
    return 'Als Antwort auf $path';
  }

  @override
  String get subscriptionUsageNoneReported =>
      'Für dieses Konto wird keine Nutzung gemeldet.';

  @override
  String get subscriptionUsageCredits => 'Guthaben';

  @override
  String get reviewHubStaticRule => 'Statische Regel';

  @override
  String get reviewHubStarted => 'Review gestartet';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return 'Von einer deterministischen Regel ($rule) in einer von diesem Pull Request hinzugefügten Zeile gefunden — nicht von einem Prüf-Agenten.';
  }

  @override
  String get prReviewArtifactTab => 'PR-Review';

  @override
  String get prReviewRunning => 'Dieser Pull Request wird geprüft…';

  @override
  String get prReviewStarting => 'Review wird gestartet…';

  @override
  String get prReviewStartingBody =>
      'Der Worktree dieses Pull Requests wird vorbereitet. Die Reviewer starten, sobald er bereit ist.';

  @override
  String get prReviewFailed => 'Review fehlgeschlagen.';

  @override
  String get prReviewRerunning => 'Erneute Prüfung…';

  @override
  String get prReviewNoOpenFindings => 'Keine offenen Befunde';

  @override
  String prReviewOpenFindings(int count) {
    return '$count offene Befunde';
  }

  @override
  String subscriptionUsageSpend(String used, String limit) {
    return '$used von $limit';
  }

  @override
  String reviewCommentsPosted(int posted, int skipped, int failed) {
    return '$posted Kommentar(e) vom Bot veröffentlicht. $skipped übersprungen (kein Dateianker), $failed fehlgeschlagen.';
  }

  @override
  String reviewFindingsOutOfDiff(int count, String files) {
    return '$count Befund(e) betreffen Code, den dieser Pull-Request nicht ändert ($files). GitHub akzeptiert Inline-Kommentare nur im Diff.';
  }

  @override
  String get reviewRailReport => 'Bericht';

  @override
  String get reviewNoFindingsTitle => 'Noch keine Befunde';

  @override
  String get reviewNoFindingsHint =>
      'Befunde erscheinen hier, sobald Agenten sie veröffentlichen.';

  @override
  String reviewShowDismissed(int count) {
    return '$count verworfene anzeigen';
  }

  @override
  String reviewHideDismissed(int count) {
    return '$count verworfene ausblenden';
  }

  @override
  String reviewDisagreementsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Abweichungen zwischen Prüfern erkannt',
      one: '1 Abweichung zwischen Prüfern erkannt',
    );
    return '$_temp0';
  }

  @override
  String get reviewFilterKind => 'Art';

  @override
  String get reviewFilterStatus => 'Status';

  @override
  String get reviewKindBug => 'Fehler';

  @override
  String get reviewKindSuggestion => 'Vorschlag';

  @override
  String get reviewKindRecommendation => 'Empfehlung';

  @override
  String get reviewKindQuestion => 'Frage';

  @override
  String get reviewKindTicket => 'Ticket';

  @override
  String get archiveSpace => 'Bereich archivieren';

  @override
  String get archivedSpaces => 'Archivierte Bereiche';

  @override
  String get archivedSpacesEmpty => 'Keine archivierten Bereiche';

  @override
  String get restoreSpace => 'Wiederherstellen';

  @override
  String archivedWhen(String time) {
    return 'Archiviert $time';
  }

  @override
  String get deleteSpacePermanently => 'Endgültig löschen';

  @override
  String get renameSpace => 'Bereich umbenennen';

  @override
  String get renameConversation => 'Konversation umbenennen';

  @override
  String get editSpaceRepos => 'Repositories bearbeiten';

  @override
  String get editSpaceReposTitle => 'Bereichs-Repositories';

  @override
  String get editSpaceReposWarning =>
      'Ein Repository hinzuzufügen checkt es in diesen Bereich aus; eines zu entfernen löscht dessen Ordner.';

  @override
  String get agentSectionIdentity => 'Identität';

  @override
  String get agentSectionRuntime => 'Laufzeit';

  @override
  String get agentSectionGuardrails => 'Schutzregeln';

  @override
  String orgChartReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unterstellt',
      one: '1 unterstellt',
    );
    return '$_temp0';
  }

  @override
  String get teamsFilterHint => 'Teams filtern…';

  @override
  String get teamsSummaryWithLeader => 'Mit Leitung';

  @override
  String teamCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Teams',
      one: '1 Team',
      zero: 'Keine Teams',
    );
    return '$_temp0';
  }

  @override
  String agentDeleteLongDescription(String name) {
    return 'Beim Löschen von $name werden Profil, Skill-Verknüpfungen und Ausführungsverlauf entfernt. Das lässt sich nicht rückgängig machen.';
  }

  @override
  String get resetToDefault => 'Auf Standard zurücksetzen';

  @override
  String get newAgent => 'Neuer Agent';

  @override
  String get newSkill => 'Neuer Skill';

  @override
  String get zoomIn => 'Vergrößern';

  @override
  String get zoomOut => 'Verkleinern';

  @override
  String get resetZoom => 'Zoom zurücksetzen';

  @override
  String get imageHostedOnGitHub => 'Bild auf GitHub gehostet';

  @override
  String get imageOpenExternally => 'Bild · extern öffnen';

  @override
  String get memoryScopeAll => 'Alle Bereiche';

  @override
  String get memoryScopeWorkspace => 'Gesamter Arbeitsbereich';

  @override
  String get memoryScopeFilterLabel => 'Nach Bereich filtern';

  @override
  String memoryScopeRepoTooltip(String repo) {
    return 'Auf das Repository $repo beschränkt';
  }

  @override
  String get toolScreenshot => 'Screenshot vom Agenten';

  @override
  String get toolImageUnavailable => 'Bild nicht verfügbar';

  @override
  String toolImagesUnavailable(int count) {
    return '$count Bilder nicht verfügbar';
  }

  @override
  String get shakeUnavailable =>
      'Ausschütteln ist auf diesem Server nicht verfügbar';

  @override
  String get shakeNothing =>
      'Nichts auszuschütteln — aktuelle Züge sind geschützt';

  @override
  String shakeDone(int tokens) {
    return 'Etwa $tokens Token freigegeben';
  }

  @override
  String get compactionDivider => 'Verdichtet';

  @override
  String compactionDividerCount(int count) {
    return 'Verdichtet · $count Nachrichten zusammengefasst';
  }

  @override
  String get composerDropToAttach => 'Zum Anhängen ablegen';

  @override
  String get attachmentUnavailable => 'Anhang nicht verfügbar';

  @override
  String get attachmentUnavailableDetail =>
      'Dieser Anhang liegt nicht mehr im Speicher. Hänge ihn erneut an, um ihn anzusehen.';

  @override
  String get attachmentPreviewFailed =>
      'Diese Datei konnte nicht geöffnet werden';

  @override
  String get attachmentPreviewUnsupported =>
      'Keine Vorschau für diesen Dateityp';

  @override
  String get attachmentTooLargeToPreview => 'Zu groß für eine Vorschau';

  @override
  String get attachmentOpenExternally => 'In der Standard-App öffnen';

  @override
  String get asideUnavailable =>
      'Lege in den Einstellungen ein One-Shot-Modell fest, um dies zu nutzen';

  @override
  String get asideEmpty => 'Noch nichts, worauf man aufbauen kann';

  @override
  String get asideFailed => 'Keine Antwort erhalten';

  @override
  String get handoffTitle => 'Übergabe';

  @override
  String get asideTitle => 'Nebenfrage';

  @override
  String get attachFilesOrDrop => 'Dateien anhängen — oder hier ablegen';

  @override
  String get guidedGoalTitle => 'Ziel schärfen';

  @override
  String get guidedGoalIntro =>
      'Ein unbeaufsichtigt arbeitender Agent muss genau wissen, wann er fertig ist. Zuerst ein paar Fragen.';

  @override
  String get guidedGoalAnswerHint => 'Deine Antwort';

  @override
  String get guidedGoalNext => 'Weiter';

  @override
  String get guidedGoalStart => 'Ziel starten';

  @override
  String get guidedGoalSkip => 'Überspringen und wie geschrieben ausführen';

  @override
  String guidedGoalStillMissing(String items) {
    return 'Weiterhin offen: $items';
  }

  @override
  String get conversationTreeTitle => 'Gesprächsbaum';

  @override
  String conversationTreeBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zweige',
      one: '1 Zweig',
    );
    return '$_temp0';
  }

  @override
  String get conversationTreeSwitch => 'Von hier fortsetzen';

  @override
  String get conversationTreeFork => 'In neue Unterhaltung abzweigen';

  @override
  String get conversationTreeCurrent => 'Auf diesem Zweig';

  @override
  String get conversationTreeEmpty => 'Noch nichts hier';

  @override
  String get conversationTreeForked => 'In eine neue Unterhaltung abgezweigt';

  @override
  String get conversationTreeSwitched => 'Es geht ab dieser Nachricht weiter';

  @override
  String exportSaved(String path) {
    return 'Gespeichert unter $path';
  }

  @override
  String get exportFailed => 'Export konnte nicht geschrieben werden';

  @override
  String get contextCommandNoAgent =>
      'Kein Agent in dieser Unterhaltung, also gibt es kein Kontextfenster zum Öffnen';

  @override
  String contextCommandNoSuchAgent(String name, String names) {
    return 'Kein Agent namens „$name“ in dieser Unterhaltung. Versuche: $names';
  }

  @override
  String get dumpCopied => 'Transkript in die Zwischenablage kopiert';

  @override
  String get messageQueueHint =>
      'Tippe weiter, um Folgeänderungen in die Warteschlange zu stellen';

  @override
  String get steerNow => 'Steuern';

  @override
  String get steeringQueueLabel => 'Wartende Steuerungsnachrichten';

  @override
  String get steeringDeliverUnavailable =>
      'Kein laufender Agent kann das gerade übernehmen — es bleibt in der Warteschlange.';

  @override
  String get reorderSteeringCard => 'Wartende Nachricht neu anordnen';

  @override
  String get editSteeringCard => 'Wartende Nachricht bearbeiten';

  @override
  String get deleteSteeringCard => 'Wartende Nachricht löschen';

  @override
  String get steeringBadge => 'Gesteuert';

  @override
  String get settingsSandboxLabel => 'Sandbox';

  @override
  String get sandboxExecGrantsTitle => 'Ausführungsberechtigungen';

  @override
  String get sandboxExecGrantsSubtitle =>
      'Programme, die Agenten aus ihrer Arbeitskopie deiner Repositorys ausführen dürfen. Jeder Eintrag wurde von dir freigegeben, als die Sandbox gefragt hat.';

  @override
  String get sandboxExecGrantsEmpty =>
      'Noch keine Entscheidungen erfasst. Du wirst gefragt, sobald ein Agent zum ersten Mal ein Programm aus seiner Arbeitskopie ausführen muss.';

  @override
  String get sandboxExecGrantRevoke => 'Widerrufen';

  @override
  String get sandboxExecGrantAllowed => 'Erlaubt';

  @override
  String get sandboxExecGrantBlocked => 'Blockiert';

  @override
  String get sandboxExecGrantRevokeConfirmTitle =>
      'Diese Entscheidung widerrufen?';

  @override
  String get sandboxExecGrantRevokeConfirmBody =>
      'Du wirst erneut gefragt, wenn ein Agent das nächste Mal ein Programm aus dieser Kopie ausführen muss.';

  @override
  String get repoScriptsTest => 'Testen';

  @override
  String get repoScriptsTestTooltip =>
      'Diesen Entwurf in einem Wegwerf-Klon des Repos ausführen';

  @override
  String get repoScriptsRunKindTest => 'Test';

  @override
  String get demoBadgeLabel => 'Demo';

  @override
  String get demoFilePickerTitle => 'Demo-Dateien';

  @override
  String get demoFilePickerBody =>
      'Die Demo täuscht Uploads nur vor: wähle eine Datei und sie wird an deine Nachricht angehängt, ohne eine Festplatte zu berühren.';

  @override
  String get demoFilePickerAttach => 'Anhängen';

  @override
  String get demoReadOnlySave => 'Schreibgeschützt in der Demo';

  @override
  String get demoBadgeTooltip =>
      'Du erkundest eine Demo. Die Daten sind fiktiv und die Agenten folgen einem Skript.';

  @override
  String get demoFirstRunTitle => 'Du bist in einer Live-Demo';

  @override
  String demoFirstRunBody(int minutes) {
    return 'Das ist die echte App auf echtem Code — nur die Daten sind erfunden. Agenten streamen echte Läufe aus einem Skript, es erreicht also nichts ein Modell und es läuft nichts auf einer Maschine. Dein Arbeitsbereich gehört nur dir und verschwindet nach $minutes Minuten.';
  }

  @override
  String get demoFirstRunDismiss => 'Verstanden';

  @override
  String get demoTourTitle => 'Wo du zuerst hinschaust';

  @override
  String get demoTourSubtitle =>
      'Vier Orte, die zeigen, was die App wirklich kann.';

  @override
  String get demoTourSkip => 'Überspringen';

  @override
  String get demoTourStarRepo => 'Auf GitHub mit Stern versehen';

  @override
  String get demoTourDone => 'Fertig';

  @override
  String get demoTourOpen => 'Öffnen';

  @override
  String get demoTourSpacesTitle => 'Mit einem Agenten sprechen';

  @override
  String get demoTourSpacesBody =>
      'Schick eine Nachricht in einen Space und sieh zu, wie ein Lauf hereinströmt — Denken, Werkzeugaufrufe und Kosten, genau wie bei einem echten Lauf.';

  @override
  String get demoTourReviewTitle => 'Einen Pull Request prüfen';

  @override
  String get demoTourReviewBody =>
      'Öffne #412. Hinterlass einen Inline-Kommentar oder reiche eine Review ein: deine Worte landen im Thread und bleiben dort.';

  @override
  String get demoTourTicketsTitle => 'Der Arbeit folgen';

  @override
  String get demoTourTicketsBody =>
      'Tickets, To-dos und Pläne hängen an denselben Gesprächen, die die Agenten führen.';

  @override
  String get demoTourInboxTitle => 'Den ganzen Betrieb sehen';

  @override
  String get demoTourInboxBody =>
      'Jede Meldung aus jedem Bereich landet in einem einzigen Posteingang — Reviews, Tickets, Läufe und Meetings.';

  @override
  String demoSessionEndingSoon(int minutes) {
    return 'Diese Demo-Sitzung endet in $minutes Minuten.';
  }

  @override
  String get demoSessionEnded =>
      'Diese Demo-Sitzung ist beendet. Lade die Seite neu, um eine neue zu starten.';

  @override
  String get demoUnavailableTitle => 'In der Demo nicht verfügbar';

  @override
  String get demoUnavailableTerminal =>
      'Ein Terminal führt eine echte Shell auf dem Server aus. Die Demo hat gar keine Ausführungsfläche — genau das macht sie öffentlich sicher.';

  @override
  String get demoUnavailableRig =>
      'Ein Enclosure ist eine wegwerfbare VM, die ein Agent steuert. Die Demo startet keine: ein öffentlicher Endpunkt, der eine VM starten kann, ist keine Demo.';

  @override
  String get demoUnavailableEditor =>
      'Der Editor im Browser führt einen code-server-Prozess auf einem echten Checkout aus. Die Demo hat beides nicht.';

  @override
  String get demoUnavailableFeeds =>
      'Die Demo liest echte Feeds, ihre Abonnementliste ist jedoch fest. Hinzufügen oder Entfernen ist hier deaktiviert.';

  @override
  String get demoUnavailableForge =>
      'Die Demo hält keine Zugangsdaten und kontaktiert nie GitHub, GitLab oder Linear. Ihre Pull Requests sind Fixtures, und deine Kommentare bleiben lokal.';

  @override
  String get demoUnavailableModels =>
      'Die Demo ruft kein Modell auf. Agentenläufe sind skriptgesteuerte Wiedergabe — deshalb kosten sie nichts und erreichen keinen Anbieter.';

  @override
  String get demoUnavailableMcp =>
      'Die MCP-Werkzeugfläche ist in der Demo nicht eingehängt, also kann sich kein externer Client verbinden.';

  @override
  String get demoUnavailableRepos =>
      'Die Demo checkt keinen Code aus und führt kein git aus. Das gezeigte Repository ist eine Fixture hinter den Pull Requests.';

  @override
  String get demoUnavailableSkills =>
      'Eine Skill zu installieren lädt Code herunter und prüft ihn. Die Demo lädt nichts.';

  @override
  String get demoUnavailableSso =>
      'Single Sign-on ist Serverkonfiguration. Die Demo meldet dich stattdessen als temporären Gast an.';

  @override
  String get demoUnavailableAudio =>
      'Aufnahme und Diktat brauchen Audioaufnahme und ein Sprachmodell auf dem Host. Die Demo bringt beides nicht mit: ihre Meetings sind Transkripte ohne Wiedergabe.';

  @override
  String get demoUnavailableServerAdmin =>
      'Das ist Serveradministration. Die Demo gibt dir einen Wegwerf-Arbeitsbereich und sonst nichts.';

  @override
  String get settingsBackupRestore => 'Sicherung und Wiederherstellung';

  @override
  String get settingsBackupRestoreDescription =>
      'Momentaufnahmen aller Datenbanken auf diesem Server sowie Export, Import und Löschen eines einzelnen Arbeitsbereichs.';

  @override
  String get backupSnapshotsLabel => 'Momentaufnahmen der Installation';

  @override
  String get backupSnapshotsExplainer =>
      'Eine Momentaufnahme kopiert jede Datenbank in einen Ordner mit Zeitstempel auf dem Server-Host. Die gesamte Installation wiederherzustellen heißt, diesen Ordner bei gestopptem Server zurückzukopieren; ein einzelner Arbeitsbereich lässt sich hier wiederherstellen.';

  @override
  String get backupNowAction => 'Jetzt sichern';

  @override
  String backupSnapshotWritten(String path) {
    return 'Momentaufnahme geschrieben nach $path';
  }

  @override
  String get backupNoSnapshots =>
      'Noch keine Momentaufnahmen. Sie entstehen nur auf Anfrage – es ist nichts geplant.';

  @override
  String get backupSnapshotComplete => 'Vollständig';

  @override
  String get backupSnapshotIncomplete => 'Unvollständig';

  @override
  String get backupSnapshotIncompleteNote =>
      'Das Manifest fehlt oder nennt Dateien, die nicht da sind, deshalb kann diese Momentaufnahme nicht die ganze Installation wiederherstellen. Die vorhandenen Arbeitsbereichsdateien lassen sich weiterhin einzeln übernehmen.';

  @override
  String backupSnapshotWorkspaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Arbeitsbereiche',
      one: '1 Arbeitsbereich',
      zero: 'Keine Arbeitsbereiche',
    );
    return '$_temp0';
  }

  @override
  String backupSnapshotSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Arbeitsbereiche nicht erfasst',
      one: '1 Arbeitsbereich nicht erfasst',
    );
    return '$_temp0';
  }

  @override
  String get backupServerPathLabel => 'Pfad auf dem Server';

  @override
  String get backupRestoreAction => 'Wiederherstellen';

  @override
  String get backupRestoreTitle => 'Arbeitsbereich wiederherstellen';

  @override
  String backupRestoreBody(String name) {
    return 'Das ersetzt alles in $name durch die Kopie aus dieser Momentaufnahme. Alles, was dieser Arbeitsbereich seitdem getan hat, geht verloren und lässt sich nicht rückgängig machen.';
  }

  @override
  String backupRestoreDone(String name) {
    return '$name aus der Momentaufnahme wiederhergestellt.';
  }

  @override
  String get backupWorkspaceUnknown => 'Nicht mehr auf diesem Server';

  @override
  String get backupWorkspaceDataLabel => 'Arbeitsbereichsdaten';

  @override
  String get backupWorkspaceDataExplainer =>
      'Ein Arbeitsbereich ist eine einzige Datenbankdatei, ein Export kopiert also diese Datei, statt Tabelle für Tabelle auszugeben. Ein Import ersetzt alles im Ziel-Arbeitsbereich durch die angegebene Datei.';

  @override
  String get backupExportAction => 'Exportieren';

  @override
  String backupExportDone(String path) {
    return 'Exportiert nach $path';
  }

  @override
  String get backupExportedFileLabel => 'Exportierte Datei auf dem Server';

  @override
  String get backupImportAction => 'Importieren';

  @override
  String backupImportTitle(String name) {
    return 'In $name importieren';
  }

  @override
  String backupImportBody(String name) {
    return 'Das ersetzt alles in $name durch den Inhalt der Datei. Was dieser Arbeitsbereich jetzt enthält, geht verloren und lässt sich nicht rückgängig machen.';
  }

  @override
  String get backupImportSourceLabel => 'Arbeitsbereichs-Datenbankdatei';

  @override
  String get backupImportSourceDescription =>
      'Eine .db-Datei, die der Server lesen kann. Pfade werden auf dem Server-Host aufgelöst, nicht auf diesem Gerät.';

  @override
  String get backupImportChooseFile => 'Datei auswählen';

  @override
  String backupImportDone(String name) {
    return 'In $name importiert.';
  }

  @override
  String backupDeleteBody(String name) {
    return '$name verschwindet aus jeder Liste und jeder Suche. Die Datenbankdatei bleibt auf der Festplatte, Sicherungen enthalten sie weiterhin, und nichts gibt diesen Speicher automatisch frei.';
  }

  @override
  String get backupExportDescription =>
      'Eine Kopie auf dem Server ablegen oder eine auf dieses Gerät herunterladen.';

  @override
  String get backupExportOnServerAction => 'Auf dem Server speichern';

  @override
  String get backupDownloadAction => 'Herunterladen';

  @override
  String backupDownloadSaved(String path) {
    return 'Gespeichert unter $path';
  }

  @override
  String get backupDownloadInBrowser => 'Ihr Browser übernimmt das.';

  @override
  String get backupRestoreFromDeviceLabel =>
      'Von diesem Gerät wiederherstellen';

  @override
  String get backupRestoreFromDeviceDescription =>
      'Wählen Sie hier eine Arbeitsbereichs-Datenbankdatei; Control Center lädt sie auf den Server hoch. Das ist der Weg, der funktioniert, wenn der Server nicht dieser Rechner ist.';

  @override
  String get backupUploadAction => 'Datei auswählen und hochladen';

  @override
  String get backupTransferUnavailable =>
      'Diese Verbindung erreicht den Server über ein Relay, das keine Dateien überträgt. Verbinden Sie sich direkt mit dem Server, um eine Sicherung herunter- oder hochzuladen.';

  @override
  String get backupTransferForbidden =>
      'Der Server hat abgelehnt. Einen Arbeitsbereich herunterzuladen erfordert die Rolle admin, ihn wiederherzustellen owner, und eine ganze Momentaufnahme den Betreiber der Installation.';

  @override
  String get backupTransferUnsupported =>
      'Dieser Server bietet keine Sicherungsschnittstelle.';

  @override
  String get backupTransferTooLarge =>
      'Die Datei ist größer, als der Server annimmt.';

  @override
  String get credentialGateWaitingTitle => 'Warten auf eine Anmeldung';

  @override
  String credentialGateHarnessTitle(String provider) {
    return '$provider hat keine Anmeldedaten';
  }

  @override
  String get credentialGateSignedOutTitle => 'Claude Code ist abgemeldet';

  @override
  String get credentialGateExpiredTitle =>
      'Deine Claude-Code-Anmeldung ist abgelaufen';

  @override
  String get credentialGatePlanSpentTitle =>
      'Limit des Claude-Code-Tarifs erreicht';

  @override
  String credentialGateWaitingAgent(String agent) {
    return '$agent wartet auf die Fortsetzung.';
  }

  @override
  String get credentialGateWaitingRun => 'Ein Lauf wartet auf die Fortsetzung.';

  @override
  String get credentialGateWatching =>
      'Wird überwacht — der Lauf geht von selbst weiter.';

  @override
  String credentialGateFreesUpAt(String time) {
    return 'Wird um $time wieder frei';
  }

  @override
  String credentialGateGivesUpAt(String time) {
    return 'Der Lauf gibt um $time auf';
  }

  @override
  String get credentialGateCheckAgain => 'Erneut prüfen';

  @override
  String get credentialGateCancelRun => 'Lauf abbrechen';

  @override
  String get credentialGateAccountsTried => 'Versuchte Konten';

  @override
  String get credentialGateClaudeSignInHint =>
      'Melde dich unter Einstellungen → Adapter → Claude Code an oder führe den Anmeldebefehl in einem Terminal aus. Der Lauf erkennt das von selbst.';

  @override
  String get credentialGateOpenSettings => 'Einstellungen öffnen';
}
