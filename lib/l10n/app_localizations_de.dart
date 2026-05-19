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
      'Legen Sie fest, was Agenten selbst tun dürfen, vorher erfragen müssen oder nie tun dürfen – pro Arbeitsbereich, Agent oder Kanal.';

  @override
  String get agentPermissionsMatrixDescription =>
      'Legen Sie für jede Art von Effekt eine Entscheidung fest. Regeln überlagern sich: Kanal übersteuert Agent übersteuert Arbeitsbereich.';

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
  String get guardrailScopeChannel => 'Kanal';

  @override
  String get guardrailSelectAgent => 'Agent auswählen';

  @override
  String get guardrailSelectChannel => 'Kanal auswählen';

  @override
  String get guardrailNoAgents =>
      'Noch keine Agenten in diesem Arbeitsbereich.';

  @override
  String get guardrailNoChannels =>
      'Noch keine Kanäle in diesem Arbeitsbereich.';

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
  String get rigTakeControl => 'Steuerung übernehmen';

  @override
  String get rigAudioListen => 'Maschine anhören';

  @override
  String get rigAudioMute => 'Maschine stummschalten';

  @override
  String get rigHandBack => 'Steuerung zurückgeben';

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
  String get rigTabComputer => 'Computer (VM)';

  @override
  String get rigTabBrowser => 'Browser (VM)';

  @override
  String get rigTabMobile => 'Telefon (VM)';

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
  String get rigClipboardUnreadable =>
      'Die Maschine hat nicht geantwortet, als ihre Zwischenablage abgefragt wurde.';

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
  String get guardrailProbeChannelLabel => 'Kanal (optional)';

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
  String get serverConnectionMode => 'Modus';

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
  String get serverConnectionRestartHint =>
      'Starte Control Center neu, um die Verbindungsänderungen zu übernehmen.';

  @override
  String get serverConnectionReloadHint =>
      'Lade die Seite neu, um dich mit diesen Änderungen erneut zu verbinden.';

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
  String get calendarSectionCalendars => 'Kalender';

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
  String get calendarNotConnected => 'Kein Google-Konto verbunden';

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
  String get calendarNotConfigured =>
      'Google Calendar ist nicht konfiguriert. Lege GOOGLE_OAUTH_CLIENT_ID fest, um ein Konto zu verbinden.';

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
  String get profileClickToLoad => 'Zum Laden klicken';

  @override
  String get byAuthorPrefix => 'von';

  @override
  String get stopAgentRun => 'Lauf stoppen';

  @override
  String get stopAgentRunConfirm =>
      'Diesen Lauf stoppen? Laufende Arbeit geht verloren.';

  @override
  String get youLabel => 'du';

  @override
  String get readyToMerge => 'Bereit zum Mergen';

  @override
  String get inProgress => 'In Arbeit';

  @override
  String get needsAttention => 'Erfordert Aufmerksamkeit';

  @override
  String get drafts => 'Entwürfe';

  @override
  String get allOpenPrs => 'Alle offenen PRs';

  @override
  String showAllCount(int count) {
    return 'Alle anzeigen ($count)';
  }

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
  String get prGroupUnknownAuthor => 'Unbekannter Autor';

  @override
  String get keybindingOpenFilterMenu => 'Filtermenü öffnen';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'Das PR-Filtermenü öffnen';

  @override
  String get selectAction => 'Auswählen';

  @override
  String mergeCountReady(int count) {
    return '$count bereite mergen';
  }

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
  String get openFullDiff => 'Vollständigen Diff öffnen';

  @override
  String get viewFiles => 'Dateien anzeigen';

  @override
  String get checksLabel => 'Checks';

  @override
  String get commentsLabel => 'Kommentare';

  @override
  String get keybindingSelectPr => 'PR auswählen';

  @override
  String get keybindingMergePr => 'PR mergen';

  @override
  String get keybindingPeekPr => 'PR-Vorschau';

  @override
  String get keybindingToggleSelectionOfTheFocusedPullRequestDescription =>
      'Auswahl der fokussierten PR umschalten';

  @override
  String get keybindingMergeTheFocusedPullRequestDescription =>
      'Die fokussierte PR mergen, wenn sie bereit ist';

  @override
  String get keybindingExpandOrCollapseTheFocusedPullRequestPeekDescription =>
      'Vorschaufenster der fokussierten PR ein- oder ausklappen';

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
  String get integrationsSettingsDescription =>
      'Verbinden Sie GitHub, Ticketing und den MCP-Server.';

  @override
  String get advanced => 'Erweitert';

  @override
  String get advancedSettingsDescription =>
      'Branch-Benennung, semantische Suche, Serververbindung, Systemverhalten und Protokollierung.';

  @override
  String get agentRegistry => 'Agenten-Registry';

  @override
  String get settingsGroupGeneral => 'Allgemein';

  @override
  String get settingsGroupAgents => 'Agenten';

  @override
  String get settingsGroupResources => 'Ressourcen';

  @override
  String get settingsGroupWorkspace => 'Workspace';

  @override
  String get settingsGroupSystem => 'System';

  @override
  String get settingsGroupIntegrations => 'Integrationen';

  @override
  String get accounts => 'Konten';

  @override
  String get accountsSettingsDescription =>
      'GitHub-, Ticketing-, Kalender- und Chat-Konten.';

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
  String get voiceAndMeetings => 'Sprache & Meetings';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'Die Sprach- und Diarisierungsmodelle, die dieser Server hostet.';

  @override
  String get securityAndPrivacy => 'Sicherheit & Datenschutz';

  @override
  String get securityAndPrivacySettingsDescription =>
      'Sandboxing, Befehlsregeln und Datenschutz.';

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
  String get filterChannelsHint => 'Kanäle filtern';

  @override
  String noChannelsMatch(String query) {
    return 'Keine Kanäle entsprechen „$query“';
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
  String runsInLastSixMonths(String count) {
    return '$count Ausführungen in den letzten 6 Monaten';
  }

  @override
  String lastActiveAgo(String duration) {
    return 'Vor $duration aktiv';
  }

  @override
  String get reportsToNobody => 'Kein Vorgesetzter';

  @override
  String get copyPath => 'Pfad kopieren';

  @override
  String get copyRelativePath => 'Relativen Pfad kopieren';

  @override
  String get pathCopied => 'Pfad in die Zwischenablage kopiert';

  @override
  String get editAgent => 'Agent bearbeiten';

  @override
  String get nameRequired => 'Name ist erforderlich';

  @override
  String get titleRequired => 'Titel ist erforderlich';

  @override
  String get import => 'Importieren';

  @override
  String discoverAgentsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Agentendefinitionen gefunden',
      one: '1 Agentendefinition gefunden',
    );
    return '$_temp0';
  }

  @override
  String get noAgentsToDiscover => 'Keine neuen Agenten zum Importieren';

  @override
  String get noAgentsToDiscoverHint =>
      'Agentendefinitionen in diesem Arbeitsbereich sind bereits importiert.';

  @override
  String get sortByStatus => 'Status';

  @override
  String get sortByName => 'Name';

  @override
  String get noMatchingAgents => 'Keine Agenten entsprechen deinem Filter';

  @override
  String get selectAnAgentHint =>
      'Wähle einen Agenten, um Status, Aktivität und Details zu sehen.';

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
  String get indexing => 'Indizierung…';

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
  String activityVerbRevoked(String target) {
    return '$target widerrufen';
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
  String get activityTargetChannel => 'Kanal';

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
  String get activityTargetReviewChannel => 'Review-Kanal';

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
  String get activityMarkedChannelRead => 'Kanal als gelesen markiert';

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
  String get activityOpenedReviewChannel => 'Review-Kanal geöffnet';

  @override
  String get activityOpenedMainConversation => 'Hauptkonversation geöffnet';

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
  String get addAgent => 'Agent hinzufügen';

  @override
  String get addAgents => 'Agenten hinzufügen';

  @override
  String get addAgentsToEnable =>
      'Agenten hinzufügen, um Multi-Agenten-Orchestrierung zu aktivieren';

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
      other: '# Repositories hinzufügen',
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
  String agentsCount(int count, num plural) {
    return 'Agenten ($count)';
  }

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
  String get allAgentsAlreadyInChannel =>
      'Alle Agenten sind bereits in diesem Kanal.';

  @override
  String get allCommits => 'Alle Commits';

  @override
  String get allSessionsReset => 'Alle Sandbox-Sitzungen zurückgesetzt.';

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
  String get appTitle => 'Control Center';

  @override
  String get appearanceLanguage => 'Erscheinungsbild & Sprache';

  @override
  String get apply => 'Anwenden';

  @override
  String get approve => 'Genehmigen';

  @override
  String get agentApprovalRequired => 'Genehmigung erforderlich';

  @override
  String get approveAndCompact => 'Genehmigen und Kontext komprimieren';

  @override
  String get approveAndExecute => 'Genehmigen und ausführen';

  @override
  String get approveAndHire => 'Genehmigen und einstellen';

  @override
  String get approved => 'Genehmigt';

  @override
  String get articlesSubscribed => 'Artikel aus deinen abonnierten Feeds.';

  @override
  String get askAi => 'Ask AI';

  @override
  String get askAiReview => 'KI-Review anfordern';

  @override
  String get askAiReviewDescription => 'KI bitten, diesen PR zu reviewen';

  @override
  String get askAnything =>
      'Frag alles… (@ für Agenten-Erwähnung, / für Befehle)';

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
  String get authentication => 'Authentifizierung';

  @override
  String get authenticationToken => 'Authentifizierungstoken';

  @override
  String authoredByLabel(String role) {
    return 'Von: $role';
  }

  @override
  String get authorsLabel => 'Autoren';

  @override
  String authorsWithCount(int count) {
    return 'Autoren · $count';
  }

  @override
  String get autoRecommended => 'Auto (empfohlen)';

  @override
  String get available => 'Verfügbar';

  @override
  String get awaitingYourApproval => 'Wartet auf deine Genehmigung';

  @override
  String get awaitingYourReview => 'Wartet auf dein Review';

  @override
  String get back => 'Zurück';

  @override
  String get backLabel => 'Zurück';

  @override
  String get backend => 'Backend';

  @override
  String get blockAdsDescription =>
      'Werbung, Tracker und Cookie-Banner blockieren';

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
  String get cached => 'Zwischengespeichert';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get cancelEdit => 'Bearbeitung abbrechen';

  @override
  String get categoryCreation => 'Erstellung';

  @override
  String get categoryDeletion => 'Löschung';

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
  String get changesSummary => 'Änderungszusammenfassung';

  @override
  String get channelsMentionSection => 'Kanäle';

  @override
  String get checkForUpdates => 'Nach Updates suchen';

  @override
  String get checking => 'Überprüfung';

  @override
  String get checkingEllipsis => 'Überprüfung…';

  @override
  String get checkingGhCli => 'Überprüfe gh CLI…';

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
  String get closePanel => 'Panel schließen';

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
  String get commentOnFile => 'Diese Datei kommentieren';

  @override
  String get commentOnThisFile => 'Diese Datei kommentieren';

  @override
  String get commentSelected => 'Auswahl kommentieren';

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
  String get contentBlockingDescription =>
      'Werbung, Tracker und Cookie-Banner blockieren';

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
  String get couldNotCheckGhCli => 'gh CLI konnte nicht überprüft werden.';

  @override
  String couldNotListDevices(String error) {
    return 'Geräte konnten nicht aufgelistet werden: $error';
  }

  @override
  String get create => 'Erstellen';

  @override
  String get createFirstAgent =>
      'Erstelle deinen ersten Agenten, um loszulegen.';

  @override
  String get createOrSelectWorkspace =>
      'Erstelle oder wähle einen Arbeitsbereich, bevor du Repositorys hinzufügst.';

  @override
  String get createPr => 'PR erstellen';

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
  String defaultPortHint(int port) {
    return 'Standard: $port.';
  }

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
  String get deleteChannel => 'Kanal löschen';

  @override
  String deleteConfirmName(String name) {
    return '\"$name\" löschen?';
  }

  @override
  String get deleteConversation => 'Konversation löschen';

  @override
  String get deleteConversationConfirm =>
      'Diese Konversation löschen? Alle Nachrichten gehen verloren.';

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
  String deleteNamedConversation(String name) {
    return '\"$name\" löschen? Alle Nachrichten gehen verloren.';
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
  String get detailsLabel => 'Details';

  @override
  String detectedBackend(String label) {
    return 'Erkannt: $label';
  }

  @override
  String detectedRunners(int count) {
    return 'Erkannte Runner ($count)';
  }

  @override
  String get detectingAdapters => 'Adapter erkennen…';

  @override
  String get detectingGhCli => 'gh CLI erkennen…';

  @override
  String get detectingInputDevices => 'Eingabegeräte werden erkannt…';

  @override
  String detectionFailed(String error) {
    return 'Erkennung fehlgeschlagen: $error';
  }

  @override
  String diffFailed(String message) {
    return 'Diff fehlgeschlagen: $message';
  }

  @override
  String get disabled => 'Deaktiviert';

  @override
  String get discover => 'Entdecken';

  @override
  String get discoverAgents => 'Agenten entdecken';

  @override
  String get discoverAgentsDescription =>
      'Die Agentenentdeckung durchsucht Arbeitsbereichspfade nach AGENTS.md- und TEAM.md-Dateien und parst sie in das Agentenregister.\n\nKonfiguriere zuerst einen Arbeitsbereich und verwende dann diese Funktion, um Agenten automatisch zu füllen.';

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
  String get editTheSuggestedCodeHint => 'Den vorgeschlagenen Code bearbeiten…';

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
  String get enableMcpServer => 'MCP-Server aktivieren';

  @override
  String get enableNotifications => 'Benachrichtigungen aktivieren';

  @override
  String get enableSandboxing => 'Sandboxing aktivieren';

  @override
  String get enabled => 'Aktiviert';

  @override
  String enterToken(String name) {
    return '$name-Token eingeben';
  }

  @override
  String get enterTokenToAuth =>
      'Token eingeben, um Authentifizierung zu erzwingen';

  @override
  String errorCreatingAgent(String error) {
    return 'Fehler beim Erstellen des Agenten: $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'Fehler beim Löschen des Agenten: $error';
  }

  @override
  String get errorLoadingAgents => 'Fehler beim Laden der Agenten';

  @override
  String errorWithDetail(String error) {
    return 'Fehler: $error';
  }

  @override
  String get errored => 'Fehlerhaft';

  @override
  String get exitSelection => 'Auswahl verlassen';

  @override
  String get expand => 'Ausklappen';

  @override
  String get extractingLabel => 'Extrahiere';

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
  String get feedUrl => 'Feed-URL';

  @override
  String get feedUrlExample => 'z.B. https://example.com/feed.xml';

  @override
  String get feedUrlExists => 'Ein Feed mit dieser URL existiert bereits.';

  @override
  String get feedUrlLabel => 'Feed-URL';

  @override
  String feedsCount(int count) {
    return 'Feeds ($count)';
  }

  @override
  String get feedsLabel => 'Feeds';

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
  String get filterAgentsPlaceholder => 'Agenten filtern…';

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
  String get fixSelected => 'Auswahl korrigieren';

  @override
  String get forward => 'Weiterleiten';

  @override
  String get gatesGithubPatPush =>
      'Steuert GitHub PAT-Injektion. Erforderlich, damit der Agent pushen kann.';

  @override
  String get general => 'Allgemein';

  @override
  String get generalSettingsDescription =>
      'Erscheinungsbild, Typografie, Integrationen und MCP-Server.';

  @override
  String get ghCliAuthButPatOverrideBody =>
      'GitHub CLI ist authentifiziert und bereit, aber ein persönlicher Zugriffstoken ist unten eingestellt und wird stattdessen verwendet. Lösche den PAT, um gh CLI-Authentifizierung zu nutzen.';

  @override
  String get ghCliInstalledAuth =>
      'Installiert. Führe `gh auth login` aus und tippe dann auf Aktualisieren.';

  @override
  String get ghCliNotInstalled =>
      'gh CLI nicht installiert — installiere von cli.github.com.';

  @override
  String get ghCliNotInstalledLabel => 'gh CLI nicht installiert';

  @override
  String get githubCli => 'GitHub CLI';

  @override
  String get githubCliIntegration => 'GitHub CLI-Integration';

  @override
  String get githubCliReady => 'GitHub CLI ist authentifiziert und bereit.';

  @override
  String get githubLink => 'GitHub-Link';

  @override
  String get githubPersonalAccessToken => 'GitHub persönliches Zugriffstoken';

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
  String get githubToken => 'GitHub-Token';

  @override
  String get giveYourWorkAHome => 'Gib deiner Arbeit ein Zuhause.';

  @override
  String get goBack => 'Zurückgehen';

  @override
  String get goForward => 'Vorwärtsgehen';

  @override
  String get googleFonts => 'Google Fonts';

  @override
  String get hideContainerTerminal => 'Container-Terminal ausblenden';

  @override
  String get hideConversationChanges => 'Änderungen ausblenden';

  @override
  String get showConversationChanges => 'Änderungen anzeigen';

  @override
  String get noConversationChanges =>
      'Noch keine ungespeicherten Änderungen in dieser Unterhaltung.';

  @override
  String get conversationChangesTitle => 'Änderungen';

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
  String get installGhCliBody =>
      'Installiere gh von https://cli.github.com/ und führe `gh auth login` aus, dann auf Aktualisieren tippen.';

  @override
  String get installRequired => 'Installation erforderlich';

  @override
  String get installedNotSignedIn => 'Installiert - nicht angemeldet';

  @override
  String installedVersion(String version) {
    return 'Installiert $version';
  }

  @override
  String get integrations => 'Integrationen';

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
  String get keybindingAdapters => 'Adapter';

  @override
  String get keybindingAddARepositoryDescription => 'Ein Repository hinzufügen';

  @override
  String get keybindingAddRepository => 'Repository hinzufügen';

  @override
  String get keybindingAgents => 'Agenten';

  @override
  String get keybindingApprove => 'Genehmigen';

  @override
  String get keybindingApproveThePeerReviewDescription =>
      'Peer-Review genehmigen';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'Ausgewählten Artikel bookmarken oder entbookmarken';

  @override
  String get keybindingCommandPalette => 'Befehlspalette';

  @override
  String get keybindingConversationTab => 'Übersicht-Tab';

  @override
  String get keybindingCreateANewAgentDescription => 'Neuen Agenten erstellen';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'Neuen Arbeitsbereich erstellen';

  @override
  String get keybindingDeleteAgent => 'Agenten löschen';

  @override
  String get keybindingDeleteChannel => 'Kanal löschen';

  @override
  String get keybindingDeleteTheSelectedAgentDescription =>
      'Ausgewählten Agenten löschen';

  @override
  String get keybindingDeleteTheSelectedChannelDescription =>
      'Ausgewählten Kanal löschen';

  @override
  String get keybindingDeleteTheSelectedWorkspaceDescription =>
      'Ausgewählten Arbeitsbereich löschen';

  @override
  String get keybindingDeleteWorkspace => 'Arbeitsbereich löschen';

  @override
  String get keybindingFilesChangedTab => 'Diff-Tab';

  @override
  String get keybindingFocusSearch => 'Suche fokussieren';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'Das Pull-Request-Suchfeld fokussieren';

  @override
  String get keybindingGeneral => 'Allgemein';

  @override
  String get keybindingGoToAgents => 'Zu den Agenten gehen';

  @override
  String get keybindingGoToInbox => 'Zum Posteingang gehen';

  @override
  String get keybindingGoToMemory => 'Zum Speicher gehen';

  @override
  String get keybindingGoToNewsfeed => 'Zum Newsfeed gehen';

  @override
  String get keybindingGoToPipelines => 'Zu Pipelines gehen';

  @override
  String get keybindingGoToPullRequests => 'Zu den Pull Requests gehen';

  @override
  String get keybindingGoToTickets => 'Zu Tickets gehen';

  @override
  String get keybindingKeybindings => 'Tastenkürzel';

  @override
  String get keybindingNavigateToTheAgentsRegistryDescription =>
      'Zum Agentenregister navigieren';

  @override
  String get keybindingNavigateToTheInboxDescription =>
      'Zum Posteingang navigieren';

  @override
  String get keybindingNavigateToTheMemoryDescription =>
      'Zur Wissensdatenbank navigieren';

  @override
  String get keybindingNavigateToTheNewsfeedDescription =>
      'Zum Newsfeed navigieren';

  @override
  String get keybindingNavigateToThePipelinesListDescription =>
      'Zur Pipeline-Liste navigieren';

  @override
  String get keybindingNavigateToThePullRequestListDescription =>
      'Zur Pull-Request-Liste navigieren';

  @override
  String get keybindingNavigateToTheTicketsBoardDescription =>
      'Zur Ticket-Tafel navigieren';

  @override
  String get keybindingNewAgent => 'Neuer Agent';

  @override
  String get keybindingNewWorkspace => 'Neuer Arbeitsbereich';

  @override
  String get keybindingNextArticle => 'Nächster Artikel';

  @override
  String get keybindingNextChannel => 'Nächster Kanal';

  @override
  String get keybindingNextPr => 'Nächste PR';

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
  String get keybindingOpenTheAdaptersSettingsPageDescription =>
      'Adapter-Einstellungsseite öffnen';

  @override
  String get keybindingOpenTheAgentsSettingsPageDescription =>
      'Agenten-Einstellungsseite öffnen';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'Anwendungseinstellungen öffnen';

  @override
  String get keybindingOpenTheCommandPaletteDescription =>
      'Befehlspalette öffnen';

  @override
  String get keybindingOpenTheGeneralSettingsPageDescription =>
      'Allgemeine Einstellungsseite öffnen';

  @override
  String get keybindingOpenTheKeybindingsSettingsPageDescription =>
      'Tastenkürzel-Einstellungsseite öffnen';

  @override
  String get keybindingOpenTheRepositoriesSettingsPageDescription =>
      'Repository-Einstellungsseite öffnen';

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
  String get keybindingOpenTheSkillsSettingsPageDescription =>
      'Fähigkeiten-Einstellungsseite öffnen';

  @override
  String get keybindingOpenWorkspace => 'Arbeitsbereich öffnen';

  @override
  String get keybindingPreviousArticle => 'Vorheriger Artikel';

  @override
  String get keybindingPreviousChannel => 'Vorheriger Kanal';

  @override
  String get keybindingPreviousPr => 'Vorherige PR';

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
  String get keybindingRemoveRepository => 'Repository entfernen';

  @override
  String get keybindingRemoveTheSelectedRepositoryDescription =>
      'Ausgewähltes Repository entfernen';

  @override
  String get keybindingRepositories => 'Repositorys';

  @override
  String get keybindingRequestChanges => 'Änderungen anfordern';

  @override
  String get keybindingRequestChangesOnThePeerReviewDescription =>
      'Änderungen am Peer-Review anfordern';

  @override
  String get keybindingRescanForAdaptersDescription =>
      'Nach Adaptern neu scannen';

  @override
  String get keybindingSearchInDiff => 'In Diff suchen';

  @override
  String get keybindingSearchWithinTheDiffViewDescription =>
      'In der Diff-Ansicht suchen';

  @override
  String get keybindingToggleViewed => 'Gesehen umschalten';

  @override
  String get keybindingMarkTheFocusedFileAsViewedOrUnviewedDescription =>
      'Fokussierte Datei als gesehen oder ungesehen markieren';

  @override
  String get keybindingToggleCollapse => 'Zusammenklappen umschalten';

  @override
  String get keybindingShowFileList => 'Dateiliste anzeigen';

  @override
  String get keybindingShowFileListDescription =>
      'Die Diff-Seitenleiste zurück zum Dateibaum wechseln';

  @override
  String get keybindingCollapseOrExpandTheFocusedFileDescription =>
      'Fokussierte Datei zusammenklappen oder erweitern';

  @override
  String get keybindingSelectTheNextArticleDescription =>
      'Nächsten Artikel auswählen';

  @override
  String get keybindingSelectTheNextChannelDescription =>
      'Nächsten Kanal auswählen';

  @override
  String get keybindingSelectTheNextPullRequestDescription =>
      'Nächste Pull Request auswählen';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'Vorherigen Artikel auswählen';

  @override
  String get keybindingSelectThePreviousChannelDescription =>
      'Vorherigen Kanal auswählen';

  @override
  String get keybindingSelectThePreviousPullRequestDescription =>
      'Vorherige Pull Request auswählen';

  @override
  String get keybindingSendMessage => 'Nachricht senden';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'Aktuelle Nachricht senden';

  @override
  String get keybindingSkills => 'Fähigkeiten';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Zwischen hellem und dunklem Modus wechseln';

  @override
  String get keybindingSwitchToTheConversationTabDescription =>
      'Zum Übersicht-Tab wechseln';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Zum achten Arbeitsbereich wechseln';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Zum fünften Arbeitsbereich wechseln';

  @override
  String get keybindingSwitchToTheFilesChangedTabDescription =>
      'Zum Diff-Tab wechseln';

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
  String get klipyNotConfigured => 'KLIPY_APP_KEY nicht konfiguriert';

  @override
  String get klipyNotConfiguredHint =>
      'Übergebe --dart-define=KLIPY_APP_KEY=...\\noder setze sie in der .env vor dem Starten.';

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
  String get latestLabel => 'Neueste';

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
  String get createTicketFromConversation =>
      'Ticket aus Unterhaltung erstellen';

  @override
  String get manageWorkspaces => 'Arbeitsbereiche verwalten';

  @override
  String get reorderWorkspace => 'Arbeitsbereich neu anordnen';

  @override
  String get masterToggle => 'Hauptschalter';

  @override
  String get matchOsAppearance =>
      'An das Betriebssystem anpassen oder einen festen Modus wählen.';

  @override
  String get mcpActiveAccepting =>
      'MCP-Server ist aktiv und akzeptiert Verbindungen.';

  @override
  String get mcpAuthToken => 'MCP-Authentifizierungstoken';

  @override
  String get mcpAuthentication => 'Authentifizierung';

  @override
  String get mcpAutoStartDescription =>
      'Wenn deaktiviert, bleibt der Server gestoppt, bis du ihn startest.';

  @override
  String mcpDefaultPort(int port) {
    return 'Standard: $port';
  }

  @override
  String mcpListeningOn(int port) {
    return 'Lauscht auf 127.0.0.1:$port';
  }

  @override
  String mcpListeningOnPort(int port) {
    return 'Lauscht auf Port $port, gemeinsam mit cc_server.';
  }

  @override
  String get mcpNotAvailableOnServer =>
      'Die MCP-Serversteuerung ist auf dem verbundenen Server nicht verfügbar.';

  @override
  String get modelManagedOnServer =>
      'Dieses Modell läuft auf dem Server-Host und wird dort verwaltet.';

  @override
  String get mcpNotRunning =>
      'Server läuft nicht. Starte ihn, um MCP-Verbindungen zu aktivieren.';

  @override
  String get mcpRestartPortChanges =>
      'Server muss neu gestartet werden, um Port-Änderungen zu übernehmen.';

  @override
  String get mcpServer => 'MCP-Server';

  @override
  String get mcpServerStopped => 'Server ist gestoppt';

  @override
  String get mcpStatus => 'Status';

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
  String get navConversations => 'Kanäle';

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
  String get more => 'Mehr';

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
  String get navSaved => 'Gespeichert';

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
  String get newAgent => 'Neuer Agent';

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
  String get noAccessGrants => 'Keine Zugriffsberechtigungen konfiguriert';

  @override
  String get noActiveWorkspace =>
      'Kein aktiver Arbeitsbereich oder Repository ausgewählt.';

  @override
  String get noActiveWorkspaceCreate => 'Kein aktiver Arbeitsbereich';

  @override
  String get noActiveWorkspaceGithub =>
      'Kein aktiver Arbeitsbereich mit einem GitHub-Repository.';

  @override
  String get noAgentAssigned => 'Kein Agent zugewiesen';

  @override
  String get noAgentProcessesRunning => 'Keine Agentenprozesse aktiv';

  @override
  String get noAgents => 'Keine Agenten';

  @override
  String get noAgentsDiscovered => 'Keine Agenten gefunden';

  @override
  String get noAgentsDiscoveredHint =>
      'Klicke auf \"Entdecken\", um AGENTS.md-Dateien zu suchen, oder \"Agent hinzufügen\", um einen manuell zu konfigurieren';

  @override
  String get noAgentsRegisteredYet => 'Noch keine Agenten registriert';

  @override
  String get noArticlesYet => 'Noch keine Artikel';

  @override
  String get noArticlesYetBody => 'Die Artikel deiner Feeds erscheinen hier.';

  @override
  String get noData => 'Keine Daten';

  @override
  String get noDomains => 'Noch keine Domains';

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
  String get noTokenSetUnrestricted =>
      'Kein Token gesetzt — Zugriff ist uneingeschränkt.';

  @override
  String get noTokenUnrestricted => 'Kein Token — Zugriff ist uneingeschränkt';

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
      'Benachrichtigen bei neuen Agent-Nachrichten in anderen Kanälen.';

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
  String get openArticlesBrowserFallback => 'Artikel im Browser öffnen';

  @override
  String get openArticlesInApp => 'Artikel in der App öffnen';

  @override
  String get openContainerTerminal => 'Container-Terminal öffnen';

  @override
  String get openFolder => 'Ordner öffnen';

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
  String get parsingDiff => 'Diff wird analysiert…';

  @override
  String get passed => 'Bestanden';

  @override
  String get pasteTokenHere => 'Token hier einfügen';

  @override
  String get pasteValueHere => 'Wert hier einfügen';

  @override
  String get patNotNeededGhCli => 'Nicht erforderlich — gh CLI ist angemeldet.';

  @override
  String get patOverridesGhCli => 'Konfiguriert — überschreibt gh CLI.';

  @override
  String get pathLabel => 'Pfad';

  @override
  String get pendingApproval => 'Wartet auf deine Genehmigung';

  @override
  String get persona => 'Persona';

  @override
  String get personaColon => 'Persona:';

  @override
  String get personaOptional => 'Persona (optional)';

  @override
  String get personalAccessTokenOptional =>
      'Persönliches Zugriffstoken (optional)';

  @override
  String get planLabel => 'Plan';

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
  String get prDescriptionPlaceholder => 'PR-Beschreibung in Markdown...';

  @override
  String get prDraftCreated => 'PR-Entwurf erstellt';

  @override
  String get prMergedBody => 'Ein Pull Request wurde zusammengeführt';

  @override
  String get prMoreActions => 'More actions';

  @override
  String get prTitle => 'PR-Titel';

  @override
  String get previewLabel => 'Vorschau';

  @override
  String get previousArticle => 'Vorheriger Artikel';

  @override
  String get previousChannel => 'Vorheriger Kanal';

  @override
  String get previousMatch => 'Vorherige Übereinstimmung (⇧↵)';

  @override
  String get previousPr => 'Vorherige PR';

  @override
  String get previousWorkspace => 'Vorheriger Arbeitsbereich';

  @override
  String get priorityReviewsDescription =>
      'Prioritäts-Reviews und Repository-Übersicht.';

  @override
  String get proposeToCreateDomain =>
      'Schlage einen Fakt oder eine Richtlinie vor, um eine zu erstellen.';

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
  String get refiningPlan => 'Plan wird verfeinert…';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get refreshAll => 'Alle aktualisieren';

  @override
  String get refreshAllFeeds => 'Alle Feeds aktualisieren';

  @override
  String get refreshLabel => 'Aktualisieren';

  @override
  String get refreshPrData => 'PR-Daten aktualisieren';

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
  String get removeRepository => 'Repository entfernen';

  @override
  String get removeRepositoryConfirm =>
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
  String get reportsTo => 'Berichtet an';

  @override
  String get reportsToOptional => 'Berichtet an (optional)';

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
      other: '# Repositorys',
      one: '1 Repository',
    );
    return '$_temp0 konnten nicht hinzugefügt werden: $error';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# Repositorys hinzugefügt',
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
  String get requiredIfGhCliUnavailable =>
      'Erforderlich, wenn gh CLI nicht verfügbar ist';

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
  String get resetAllSandboxes => 'Alle Sandboxes zurücksetzen';

  @override
  String get resolved => 'Gelöst';

  @override
  String get restartServerToApply =>
      'Starte den Server neu, um die Änderungen anzuwenden.';

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
  String get reviewChanges => 'Änderungen reviewen';

  @override
  String get reviewedByMe => 'Von mir reviewed';

  @override
  String get reviewers => 'REVIEWER';

  @override
  String get reviewersActive => 'Aktive Reviewer';

  @override
  String get roleLabel => 'Rolle';

  @override
  String get ruleHint => 'Die Regel der Richtlinie (Markdown wird unterstützt)';

  @override
  String get ruleLabel => 'Regel';

  @override
  String get runCompleted => 'Ausführung abgeschlossen';

  @override
  String get runGhAuthLoginBody =>
      'Führe `gh auth login` in deinem Terminal aus, dann auf Aktualisieren tippen.';

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
  String get sandboxing => 'Sandboxing';

  @override
  String get sandboxingDescription =>
      'Führe Agenten in einem Sandbox auf Betriebssystemebene aus, damit sie nicht auf deinen Home-Ordner, SSH-Schlüssel oder nicht gewährte Token zugreifen können.';

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
  String get resetToDefault => 'Auf Standard zurücksetzen';

  @override
  String get variableKey => 'Schlüssel';

  @override
  String get variableValue => 'Wert';

  @override
  String get savedArticlesDescription =>
      'Artikel, die du mit einem Lesezeichen versehen hast.';

  @override
  String get savedLabel => 'Gespeichert';

  @override
  String get savingChanges => 'Änderungen werden gespeichert…';

  @override
  String get savingEllipsis => 'Speichern…';

  @override
  String get scopeDiffToCommits =>
      'Diff auf Commits einschränken — Umschalt+Klick für Bereich';

  @override
  String get searchAgents => 'Agenten suchen';

  @override
  String get searchAuthors => 'Autoren suchen…';

  @override
  String get searchPullRequestsHint => 'Suchen… z. B. author:@user';

  @override
  String get noPrsMatchSearch => 'Keine passenden Pull Requests';

  @override
  String get noPrsMatchSearchHint =>
      'Keine offenen PRs entsprechen deiner Suche. Andere Begriffe versuchen oder Suche löschen.';

  @override
  String get searchAuthorsPlaceholder => 'Autoren suchen…';

  @override
  String get searchFactsHint => 'Fakten suchen...';

  @override
  String get searchFonts => 'Schriften suchen…';

  @override
  String get searchGifs => 'GIFs suchen';

  @override
  String get searchGifsHint => 'GIFs suchen...';

  @override
  String get searchInDiff => 'Im Diff suchen';

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
  String get serverRunning => 'Server läuft';

  @override
  String get serverStopped => 'Server gestoppt';

  @override
  String setGithubLinkDescription(String name) {
    return 'Setze den GitHub-Besitzer und Repository-Namen für $name. Dies wird verwendet, um PR- und Issue-Referenzen wie #123 in Markdown-Inhalten aufzulösen.';
  }

  @override
  String get setLabel => 'Setzen';

  @override
  String get setToken => 'Token setzen';

  @override
  String get settingsGeneralDescription =>
      'Erscheinungsbild, Typografie, Integrationen und MCP-Server.';

  @override
  String get settingsLabel => 'Einstellungen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageDescription => 'Wähle die App-Sprache.';

  @override
  String get sharedSecretToken => 'Gemeinsamer geheimer Token';

  @override
  String get shortTask => 'Kurze Aufgabe';

  @override
  String get showNativeNotifications =>
      'Native macOS-Benachrichtigungen für Ereignisse anzeigen.';

  @override
  String get showSuperseded => 'Ersetzte anzeigen';

  @override
  String get signInWithGhAuth =>
      'Mit gh auth login anmelden oder Token unter Einstellungen > API-Schlüssel hinzufügen';

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
  String get skillBrowseDisclaimer =>
      'Die skills.sh-Registry ist nicht vertrauenswürdig. Autor, Installationszahl und das \"Verifizierter Herausgeber\"-Kennzeichen sind nur Hinweise auf die Herkunft — das Scan-Urteil unten ist das eigentliche Sicherheitssignal.';

  @override
  String get skillBrowseNoResults => 'Keine Fähigkeit entspricht deiner Suche.';

  @override
  String get skillBrowsePrompt =>
      'Durchsuche die skills.sh-Registry, um eine Fähigkeit zu installieren.';

  @override
  String get skillBrowseSearchHint => 'skills.sh durchsuchen…';

  @override
  String get skillFindingLine => 'Zeile';

  @override
  String get skillInstallAnywayOverride =>
      'Ich akzeptiere das Risiko — trotzdem installieren';

  @override
  String skillInstallCount(int count) {
    return '$count Installationen';
  }

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
  String get skillVerifiedPublisher => 'Verifizierter Herausgeber';

  @override
  String get skillsBrowseTab => 'Durchsuchen';

  @override
  String get skillsInstalledTab => 'Installiert';

  @override
  String get skills => 'Fähigkeiten';

  @override
  String get skillsColon => 'Fähigkeiten:';

  @override
  String get skillsCommaSeparated => 'Fähigkeiten (durch Komma getrennt)';

  @override
  String get skillsLabel => 'FÄHIGKEITEN';

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
  String get startDmWithAgent => 'Direktnachricht mit Agenten starten';

  @override
  String get startLabel => 'Starten';

  @override
  String get startOnAppLaunch => 'Beim App-Start starten';

  @override
  String get startServerToAccept =>
      'Starte den Server, um MCP-Verbindungen zu akzeptieren.';

  @override
  String get statusLabel => 'Status';

  @override
  String stepConnect(int number) {
    return 'Schritt $number · Verbinden';
  }

  @override
  String get stop => 'Stoppen';

  @override
  String get stopped => 'Gestoppt';

  @override
  String get streaks => 'Serien';

  @override
  String get strictIdentityCheck => 'Strenge Identitätsprüfung';

  @override
  String get success => 'Erfolg';

  @override
  String get successLabel => 'Erfolg';

  @override
  String get suggestAChange => 'Änderung vorschlagen';

  @override
  String get suggestAChangeEllipsis => 'Änderung vorschlagen…';

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
  String get tapBadgeDescription =>
      'Tippe auf ein Badge, um zu sehen, wie du aufsteigst';

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
  String get thisConversation => 'diese Konversation';

  @override
  String get ticketLabel => 'TICKET';

  @override
  String get titleDescription => 'Beschreibung';

  @override
  String get titleLabel => 'Titel';

  @override
  String get todayLabel => 'Heute';

  @override
  String get toggleBookmark => 'Lesezeichen umschalten';

  @override
  String get toggleTheme => 'Thema umschalten';

  @override
  String get toggleWorkspaceSwitcher => 'Arbeitsbereich-Umschalter umschalten';

  @override
  String get tokenConfigured =>
      'Konfiguriert — Clients müssen diesen Token vorweisen.';

  @override
  String get tokenConfiguredClients =>
      'Konfiguriert — Clients müssen dieses Token vorweisen.';

  @override
  String tokenName(String name) {
    return '$name-Token';
  }

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
  String get unexpectedError => 'Ein unerwarteter Fehler ist aufgetreten.';

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
  String get viewAll => 'Alle anzeigen';

  @override
  String get viewLabel => 'Ansicht';

  @override
  String get viewLog => 'Log anzeigen';

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
  String get meetingVad => 'Spracherkennung (Silero VAD)';

  @override
  String get meetingVadDescription =>
      'Ein gelerntes Sprachaktivitätsmodell, das Stille überspringt, sodass nur Sprache transkribiert wird. Greift auf einen Energieschwellenwert zurück, wenn nicht installiert.';

  @override
  String get meetingVadInstalled =>
      'Installiert. Transkription wird auf erkannte Sprache gefiltert.';

  @override
  String get meetingVadNotInstalled =>
      'Nicht installiert – es wird der Energieschwellenwert verwendet.';

  @override
  String get meetingModelIncluded => 'Enthalten';

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
  String get whisperBaseEn => 'Whisper base.en (sherpa-onnx)';

  @override
  String get whisperInstalled =>
      'Whisper base.en installiert. Wird vom Mikrofon-Button im Composer verwendet.';

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
  String get workspaceNotesScratchpad => 'Arbeitsbereich-Notizen & Notizblock';

  @override
  String get workspaceScopedSkills =>
      'Arbeitsbereich-bezogene Fähigkeitsdateien, die Agenten zugeordnet sind.';

  @override
  String get workspaces => 'Arbeitsbereiche';

  @override
  String get writeLabel => 'Schreiben';

  @override
  String get writePrivateNotes =>
      'Private Notizen, Beobachtungen, Pläne schreiben...';

  @override
  String get writeSkillContent =>
      'Schreibe deinen Fähigkeitsinhalt hier (Markdown)…';

  @override
  String get xp => 'XP';

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
  String get focusModeEndSession => 'Sitzung beenden';

  @override
  String get focusModeExpand => 'App erweitern';

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
  String get viewProfile => 'Profil ansehen';

  @override
  String get clearAllFilters => '× Alle löschen';

  @override
  String acrossNRepos(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $countString Repos',
      one: 'In 1 Repo',
    );
    return '$_temp0';
  }

  @override
  String get pullRequestsLabel => 'PRs';

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
  String get checksFailing => 'Prüfungen fehlgeschlagen';

  @override
  String get reviewsPending => 'Some reviews are pending';

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
  String get pipelinesRunHello => 'Run hello pipeline';

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
      'Statusschlüssel, unter dem der Wert gespeichert wird (z. B. repoFullName).';

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
  String get pipelinesSelectRun => 'Select a pipeline run to view steps';

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
  String pipelineRunDuration(int seconds) {
    return '${seconds}s';
  }

  @override
  String pipelineStepDuration(int seconds) {
    return '${seconds}s';
  }

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
  String get pipelineRunViewTimeline => 'Zeitverlauf';

  @override
  String get pipelineRunViewGraph => 'Diagramm';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'Fehlgeschlagen bei $step';
  }

  @override
  String get pipelineRunTriggerManual => 'Manuell';

  @override
  String get pipelineRunTriggerAuto => 'Automatisch';

  @override
  String get pipelineStepSkippedReason => 'Übersprungen';

  @override
  String get pipelineRunColumnPipeline => 'Pipeline';

  @override
  String get pipelineRunColumnDuration => 'Dauer';

  @override
  String get pipelineRunColumnStarted => 'Gestartet';

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
  String get automationsTitle => 'Automatisierungen';

  @override
  String get automationsSubtitle =>
      'Pipelines automatisch starten, wenn Domänenereignisse ausgelöst werden';

  @override
  String get automationsNoTriggers =>
      'Keine Auslöser für dieses Ereignis konfiguriert.';

  @override
  String get automationsAddTrigger => 'Auslöser hinzufügen';

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get taskStatusPending => 'Pending';

  @override
  String get taskStatusInProgress => 'In progress';

  @override
  String get taskStatusCompleted => 'Completed';

  @override
  String get taskStatusFailed => 'Failed';

  @override
  String get taskStatusCancelled => 'Cancelled';

  @override
  String get tasksNoTasks => 'Keine Tickets';

  @override
  String get teamsTitle => 'Teams';

  @override
  String get teamsNoTeams => 'No teams configured';

  @override
  String get teamsAddTeam => 'Add team';

  @override
  String get teamsManageSubtitle =>
      'Fasse Agenten zu Teams zusammen und leite zugewiesene Arbeit über eine Leitung.';

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
  String get pipelineRunTitle => 'Pipeline run';

  @override
  String get pipelineNotFound => 'Pipeline run not found';

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
  String get pipelineTemplateSaved => 'Pipeline-Vorlage gespeichert';

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
  String nodeConfigReposDynamic(String entries) {
    return 'Dynamische Einträge beibehalten: $entries';
  }

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
      'Status-Schlüssel mit dem Verzeichnis, gegen das Pfade aufgelöst werden (Standard repoLocalPath).';

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
  String get triggerIntervalLabel => 'Ausführen alle (Sekunden)';

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
  String get automationsManagedHint =>
      'Auslöser werden pro Pipeline in deren Editor konfiguriert. Hier ein- oder ausschalten.';

  @override
  String get automationsEditInPipeline => 'In Pipeline bearbeiten';

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
  String get nodeCategoryDemo => 'Demo';

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
      'Verbinde GitHub, damit Control Center deine Pull Requests, Issues und Reviews lesen kann. Optional einen Ticketing-Anbieter verbinden. Nichts verlässt diesen Rechner.';

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
  String get assignTicket => 'Ticket zuweisen';

  @override
  String get addCollaborator => 'Mitarbeiter hinzufügen';

  @override
  String get noCollaborators => 'Noch keine Mitarbeiter';

  @override
  String get linkedPullRequests => 'Verknüpfte Pull Requests';

  @override
  String get noLinkedPullRequests => 'Noch keine verknüpften Pull Requests';

  @override
  String get ticketActivity => 'Aktivität';

  @override
  String get ticketDispatchHint =>
      '@erwähne einen Agenten, um ihn zu beauftragen…';

  @override
  String get stopAgent => 'Agent stoppen';

  @override
  String get removeQueuedMessage => 'Eingereihte Nachricht entfernen';

  @override
  String get ticketProperties => 'Eigenschaften';

  @override
  String get ticketTabIssue => 'Ticket';

  @override
  String get ticketTabActivity => 'Aktivität';

  @override
  String get ticketTabChanges => 'Änderungen';

  @override
  String get ticketTabTerminal => 'Terminal';

  @override
  String get ticketSelectPrompt =>
      'Wähle ein Ticket, um seine Details anzuzeigen';

  @override
  String get ticketNoChanges =>
      'Noch keine Änderungen in den verknüpften Repositorys';

  @override
  String get ticketTerminalNoAgent =>
      'Weise einen Agenten zu, um ein Terminal zu öffnen';

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
  String get notificationTicketCollaboratorAdded => 'Mitarbeiter hinzugefügt';

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
  String get markAllRead => 'Alle als gelesen markieren';

  @override
  String get toggleThemeLabel => 'Design wechseln';

  @override
  String get teamsNav => 'Teams';

  @override
  String get noWorkspace => 'Kein Arbeitsbereich';

  @override
  String get selectWorkspace => 'Arbeitsbereich auswählen';

  @override
  String get allAgentsIdle => 'Alle Agenten inaktiv';

  @override
  String get statWorkspaces => 'Arbeitsbereiche';

  @override
  String get statAgents => 'Agenten';

  @override
  String get statRunning => 'Aktiv';

  @override
  String get activeAgentsTitle => 'Aktive Agenten';

  @override
  String get noAgentProcessesSubtitle =>
      'Agentenaktivität erscheint hier, sobald ein Lauf startet.';

  @override
  String agentIdShort(String id) {
    return 'ID $id';
  }

  @override
  String runningProcessesLabel(int count) {
    return 'Aktiv · $count';
  }

  @override
  String get noneLabel => 'Keine';

  @override
  String get navMemory => 'Gedächtnis';

  @override
  String get memoryTabFacts => 'Fakten';

  @override
  String get memoryTabPolicies => 'Richtlinien';

  @override
  String get memoryTabGraph => 'Wissensgraph';

  @override
  String get memoryNoWorkspace =>
      'Wähle einen Arbeitsbereich, um sein Gedächtnis anzuzeigen.';

  @override
  String get topStory => 'Top-Story';

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
  String get loadMorePrs => 'Mehr laden';

  @override
  String get loadingMorePrs => 'Wird geladen…';

  @override
  String get noPrsMatchFilters =>
      'Keine Pull Requests entsprechen den Filtern in diesem Repository';

  @override
  String get connectGitHubToLoadPrs =>
      'GitHub verbinden, um Pull Requests zu laden';

  @override
  String get noRepositoriesConfigured => 'Keine Repositories konfiguriert';

  @override
  String get noAuthors => 'Keine Autoren';

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
  String diffSummary(int additions, int deletions) {
    return '+$additions −$deletions Zeilen';
  }

  @override
  String get checks => 'Prüfungen';

  @override
  String get noReviewersAssigned => 'Keine Prüfer zugewiesen';

  @override
  String get noAssignees => 'Keine Zuständigen';

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
  String loadingPullRequestNumber(int number) {
    return 'Pull Request #$number wird geladen…';
  }

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
  String get projects => 'Projekte';

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
  String get selectTicket => 'Ticket auswählen';

  @override
  String get searchTicketsHint => 'Tickets suchen…';

  @override
  String get noMatchingTickets => 'Keine passenden Tickets';

  @override
  String get addToProject => 'Zum Projekt hinzufügen';

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
  String blockedCountLabel(int count) {
    return '$count blockiert';
  }

  @override
  String needsYouCountLabel(int count) {
    return '$count für dich';
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
  String get staleLabel => 'Veraltet';

  @override
  String stepsProgress(int done, int total) {
    return '$done von $total Schritten';
  }

  @override
  String workspaceEyebrow(String name) {
    return '$name-Workspace';
  }

  @override
  String get pipelineTriggerNode => 'Trigger';

  @override
  String get workspaceSettings => 'Workspace-Einstellungen';

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
  String get filesTabShort => 'Dateien';

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
  String get teamsSectionLabel => 'Teams';

  @override
  String get suggestedReviewers => 'Vorgeschlagene Prüfer';

  @override
  String get noMatchingUsers => 'Keine passenden Personen';

  @override
  String get noMatchingReviewers => 'Keine Treffer';

  @override
  String addCount(int count) {
    return 'Hinzufügen ($count)';
  }

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
  String get meetingsStartRecording => 'Aufnahme starten';

  @override
  String get meetingsStopRecording => 'Aufnahme stoppen';

  @override
  String get meetingsProcessing => 'Zusammenfassung läuft…';

  @override
  String get meetingEnhancedNotes => 'Erweiterte Notizen';

  @override
  String get meetingYourNotes => 'Deine Notizen';

  @override
  String get meetingNotesHint =>
      'Notiere kurze Notizen – der Agent erweitert sie nach der Besprechung.';

  @override
  String get meetingTranscriptTitle => 'Transkript';

  @override
  String get meetingNoTranscriptYet =>
      'Das Transkript erscheint hier, während gesprochen wird.';

  @override
  String get meetingSpeakerMe => 'Du';

  @override
  String get meetingSpeakerThem => 'Andere';

  @override
  String get meetingStatusRecording => 'Aufnahme';

  @override
  String get meetingStatusProcessing => 'Verarbeitung';

  @override
  String get meetingStatusDone => 'Fertig';

  @override
  String get meetingStatusFailed => 'Fehlgeschlagen';

  @override
  String get keybindingGoToMeetings => 'Zu Besprechungen';

  @override
  String get keybindingNavigateToTheMeetingsDescription =>
      'Zur Besprechungsliste navigieren';

  @override
  String get meetingsSubtitle =>
      'Lokale Aufnahme deiner Besprechungen. Wir greifen das Besprechungsaudio und dein Mikrofon ab, transkribieren auf dem Gerät und lassen einen Agenten deine knappen Notizen in Entscheidungen und Aufgaben verwandeln — kein Bot tritt dem Anruf je bei.';

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
  String get meetingsStatThisWeek => 'Diese Woche';

  @override
  String get meetingsStatThisWeekUnit => 'Besprechungen erfasst';

  @override
  String get meetingsStatRecorded => 'Aufgenommen';

  @override
  String get meetingsStatRecordedUnit => 'lokal transkribiert';

  @override
  String get meetingsStatOpen => 'Offen';

  @override
  String get meetingsStatOpenUnit => 'ausstehende Aufgaben';

  @override
  String get meetingsStatLogged => 'Protokolliert';

  @override
  String get meetingsStatLoggedUnit => 'extrahierte Entscheidungen';

  @override
  String get meetingsCaptureTitle =>
      'Treiberlose Systemaudio-Aufnahme ist scharf geschaltet.';

  @override
  String get meetingsCaptureBody =>
      'Control Center greift die Lautsprecherausgabe der App ab, in der du gerade bist — Slack Huddle, Meet, Zoom, Tuple — plus dein Mikrofon, und dekodiert beide Streams auf diesem Gerät.';

  @override
  String get meetingsCapturePermission => 'Berechtigung erteilt';

  @override
  String get meetingsCaptureOnDevice => '100 % auf dem Gerät';

  @override
  String get meetingsCaptureNoBot => 'Kein Bot tritt bei';

  @override
  String get meetingsScopeAll => 'Alle Besprechungen';

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
  String meetingPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personen',
      one: '1 Person',
    );
    return '$_temp0';
  }

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
  String get meetingReRunDone => 'Zusammenfassung aktualisiert.';

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
  String get meetingRecordNotesTagline =>
      'notiere knapp — der Agent füllt den Rest';

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
  String get recentRuns => 'Letzte Läufe';

  @override
  String get runIdCopied => 'Lauf-ID kopiert';

  @override
  String get copyRunId => 'Lauf-ID kopieren';

  @override
  String get copyLogPath => 'Protokollpfad kopieren';

  @override
  String get silenceTimeoutLabel => 'Stille-Timeout (Minuten)';

  @override
  String get silenceTimeoutHint =>
      'z. B. 15 — beendet einen Lauf nach dieser Zeit ohne Ausgabe';

  @override
  String get ticketOutput => 'Ausgabe';

  @override
  String missingRequiredField(String field) {
    return 'Pflichtfeld fehlt: $field';
  }

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
  String get transcriptShowMore => 'Mehr anzeigen';

  @override
  String get transcriptShowLess => 'Weniger anzeigen';

  @override
  String get transcriptErrorLabel => 'Fehler';

  @override
  String get transcriptInterrupted => 'Unterbrochen';

  @override
  String get transcriptSandboxBlocked => 'Sandbox hat eine Aktion blockiert';

  @override
  String get transcriptOutputTruncated => 'Ausgabe gekürzt';

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
  String transcriptDiffStats(int adds, int dels) {
    return '$adds Hinzufügungen, $dels Löschungen';
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
  String get remoteControl => 'Fernsteuerung';

  @override
  String get remoteControlListening => 'Wartet auf Geräte';

  @override
  String get remoteControlListenerStopped => 'Listener gestoppt';

  @override
  String get remoteControlStartToAccept =>
      'Starten Sie den Listener, um Telefonverbindungen zu akzeptieren.';

  @override
  String get remoteControlStartOnLaunch => 'Beim Start starten';

  @override
  String get remoteControlWhenOffStaysStopped =>
      'Wenn aus, bleibt der Listener gestoppt, bis Sie ihn starten.';

  @override
  String get remoteControlRestartToApply =>
      'Starten Sie den Listener neu, um Änderungen zu übernehmen.';

  @override
  String get remoteControlSignalingUrl => 'Signaling-Broker-URL';

  @override
  String get remoteControlSignalingHint =>
      'wss://-Broker, der nur den Pairing-Handshake weiterleitet.';

  @override
  String get remoteControlStunServers => 'STUN-Server';

  @override
  String get remoteControlStunHint =>
      'Durch Kommas getrennte STUN-URLs. Kein TURN by design.';

  @override
  String get remoteControlPwaHost => 'Host der Telefon-App';

  @override
  String get remoteControlPwaHostHint =>
      'Wo die Web-App des Telefons gehostet wird; im Pairing-QR codiert.';

  @override
  String get remoteControlNotConfigured =>
      'Fügen Sie eine Signaling-URL und einen App-Host hinzu, um Pairing zu aktivieren.';

  @override
  String get remoteControlPairDevice => 'Gerät koppeln';

  @override
  String get remoteControlScanQr =>
      'Scannen Sie diesen Code mit der Telefonkamera.';

  @override
  String get remoteControlAllWorkspacesWarning =>
      'Dieses Gerät kann auf alle Workspaces auf diesem Mac zugreifen.';

  @override
  String get remoteControlCopyLink => 'Link kopieren';

  @override
  String get remoteControlWantsToConnect => 'Möchte sich verbinden';

  @override
  String get remoteControlApproveDevice => 'Gerät genehmigen';

  @override
  String get remoteControlDeviceConnected =>
      'Gerät verbunden – genehmigen Sie es, um die Kopplung abzuschließen.';

  @override
  String remoteControlQrExpiresIn(int minutes) {
    return 'Läuft in $minutes Min. ab';
  }

  @override
  String get remoteControlPairedDevices => 'Gekoppelte Geräte';

  @override
  String get remoteControlNoPairedDevices => 'Noch keine gekoppelten Geräte.';

  @override
  String get remoteControlPending => 'Bestätigung ausstehend';

  @override
  String get remoteControlActive => 'Aktiv';

  @override
  String get remoteControlRevoked => 'Widerrufen';

  @override
  String get remoteControlRevoke => 'Widerrufen';

  @override
  String get remoteControlConfirmDevice => 'Gerät bestätigen';

  @override
  String get remoteControlRevokeConfirm =>
      'Dieses Gerät widerrufen? Es wird sofort getrennt.';

  @override
  String get devicesSettingsDescription =>
      'Telefone koppeln und verwalten, die diese App fernsteuern können.';

  @override
  String get connectedLabel => 'Verbunden';

  @override
  String get ideTabGeneral => 'Allgemein';

  @override
  String get ideTabExplorer => 'Explorer';

  @override
  String get ideTabSourceControl => 'Quellcodeverwaltung';

  @override
  String get ideTabPullRequests => 'Pull Requests';

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
  String get generalSectionPlan => 'Plan';

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
  String get focusAgentRun => 'Agent-Lauf fokussieren';

  @override
  String get focusTerminal => 'Terminal fokussieren';

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
  String generalAgentTurns(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Runden',
      one: '1 Runde',
    );
    return '$_temp0';
  }

  @override
  String get terminal => 'Terminal';

  @override
  String get ideNewTerminal => 'Neues Terminal';

  @override
  String get ideNewVmTerminal => 'Neues Terminal (VM)';

  @override
  String get ideOpenChat => 'Chat öffnen';

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
  String get ideReviewCode => 'Code überprüfen';

  @override
  String get ideReviewNoChanges => 'Keine Änderungen zu überprüfen';

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
  String get ideFileSearchFailed => 'Dateisuche fehlgeschlagen';

  @override
  String get ideSearchFilename => 'Dateiname';

  @override
  String get ideSearchContent => 'Inhalt';

  @override
  String get ideSearchInFiles => 'In Dateien suchen';

  @override
  String get ideNoContentMatches => 'Keine Treffer';

  @override
  String get ideSourceControlCreatePr => 'Pull Request erstellen';

  @override
  String get ideSourceControlNoChanges => 'Keine Änderungen';

  @override
  String ideSourceControlChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count geändert',
      one: '1 geändert',
    );
    return '$_temp0';
  }

  @override
  String get ideConnectGithub =>
      'Mit GitHub verbinden, um Pull Requests zu sehen';

  @override
  String get ideNoConversationPr => 'Kein Pull Request für diese Unterhaltung';

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
  String mcpToolsSummary(int count) {
    return '$count Tools';
  }

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
  String modelsCountFromProviders(int count, int providers) {
    return '$count Modelle von $providers Anbietern';
  }

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
  String get toggleDetails => 'Details umschalten';

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
  String enabledViaAccount(String service) {
    return 'Aktiviert über $service';
  }

  @override
  String get enabledLabel => 'Aktiviert';

  @override
  String get disabledLabel => 'Deaktiviert';

  @override
  String disabledSetEnvHint(String keys) {
    return 'Deaktiviert — $keys setzen oder anmelden';
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
  String get capabilityTools => 'Tools';

  @override
  String get capabilityVision => 'Vision';

  @override
  String get capabilityReasoning => 'Reasoning';

  @override
  String get statusDeprecated => 'Veraltet';

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
  String get commandRules => 'Befehlsregeln';

  @override
  String get commandRulesDescription =>
      'Wie Control Center anhand des Konversationsmodus entscheidet, welche Shell-Befehle ein Agent ausführen darf.';

  @override
  String get scopeGlobal => 'Immer';

  @override
  String get ruleDenied => 'Abgelehnt';

  @override
  String get ruleAsk => 'Erst fragen';

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
  String get planReadyToImplement => 'Bereit zur Umsetzung?';

  @override
  String get planContinueHere => 'Hier fortfahren';

  @override
  String get planContinueHereDescription =>
      'Den Plan in dieser Sitzung umsetzen';

  @override
  String get planStartNewSession => 'Neue Sitzung starten';

  @override
  String get planStartNewSessionDescription =>
      'In einer frischen Sitzung mit sauberem Kontext umsetzen';

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
  String get channels => 'Kanäle';

  @override
  String get channelsHomeDescription =>
      'Wähle einen Kanal aus der Liste oder starte einen neuen.';

  @override
  String get noChannelsYet => 'Noch keine Kanäle';

  @override
  String get newChannel => 'Neuer Kanal';

  @override
  String get channelName => 'Kanalname';

  @override
  String get channelReposHint => 'Einzubeziehende Repos';

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
  String get channelLabel => 'Kanal';

  @override
  String get keybindingNewChannel => 'Neuer Kanal';

  @override
  String get keybindingCreateANewChannelDescription =>
      'Einen neuen Kanal erstellen';

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
  String get messageTooFarBack => 'Nachricht ist zu weit oben';

  @override
  String newMessagesCount(int count) {
    return '$count neu';
  }

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
  String providerSignOutConfirmTitle(String provider) {
    return 'Von $provider abmelden?';
  }

  @override
  String providerSignOutConfirmBody(String provider) {
    return 'Agenten, die $provider-Modelle nutzen, funktionieren erst wieder nach einer erneuten Anmeldung — dafür ist der komplette Browser-Login nötig.';
  }

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
  String get customProviders => 'Benutzerdefinierte Anbieter';

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
  String get reviewStudioTitle => 'Review-Studio';

  @override
  String get reviewStudioWalkthrough => 'Rundgang';

  @override
  String get reviewStudioContract => 'API-Vertrag';

  @override
  String get reviewStudioVisual => 'Visueller Diff';

  @override
  String get reviewStudioBlastRadius => 'Auswirkungsradius';

  @override
  String get reviewStudioRecompute => 'Neu berechnen';

  @override
  String get reviewStudioCohortsHeader => 'Kohorten';

  @override
  String get reviewStudioNoCohorts =>
      'Noch keine Kohorten — führe die Analyse aus, um diese PR nach Bedeutung zu gruppieren.';

  @override
  String get reviewStudioGroupedByPath =>
      'Nach Pfad gruppiert (Repo nicht indiziert)';

  @override
  String get reviewStudioIndexRepo => 'Repo indizieren';

  @override
  String reviewStudioFilesCount(int count) {
    return '$count Dateien';
  }

  @override
  String get reviewStudioFilesInCohort => 'Dateien in dieser Kohorte';

  @override
  String get reviewStudioSelectCohort =>
      'Wähle eine Kohorte, um ihre Zusammenfassung zu sehen.';

  @override
  String get reviewStudioSummaryEmpty =>
      'Noch keine Zusammenfassung für diese Kohorte.';

  @override
  String get reviewStudioNoAxes => 'Noch keine Review-Achsen ausgeführt.';

  @override
  String get reviewAxisCorrectness => 'Korrektheit';

  @override
  String get reviewAxisSecurity => 'Sicherheit';

  @override
  String get reviewAxisTestGap => 'Testlücken';

  @override
  String get reviewAxisPerformance => 'Leistung';

  @override
  String get reviewAxisVisual => 'Visuell';

  @override
  String get reviewAxisApiContract => 'API-Vertrag';

  @override
  String get reviewAxisPass => 'Bestanden';

  @override
  String get reviewAxisWarn => 'Warnung';

  @override
  String get reviewAxisFail => 'Fehlgeschlagen';

  @override
  String get reviewAxisPartial => 'Teilweise';

  @override
  String get reviewAxisUnavailable => 'Nicht verfügbar';

  @override
  String get reviewStudioVerdictShip => 'Freigeben';

  @override
  String get reviewStudioVerdictHold => 'Zurückhalten';

  @override
  String get reviewStudioVerdictBlock => 'Blockieren';

  @override
  String get reviewStudioVerdictClear => 'Keine Achse blockiert den Merge.';

  @override
  String reviewStudioBlockingAxes(String axes) {
    return '$axes blockieren den Merge';
  }

  @override
  String get reviewStudioNoContractChanges =>
      'Keine API-Vertragsänderungen in dieser PR.';

  @override
  String get reviewStudioBreaking => 'Breaking';

  @override
  String reviewStudioBreakingCount(int count) {
    return '$count Breaking';
  }

  @override
  String get reviewStudioDerivedContract => 'Abgeleitet (Hinweis)';

  @override
  String get reviewStudioApprove => 'Genehmigen';

  @override
  String get reviewStudioReject => 'Ablehnen';

  @override
  String get reviewStudioApproved => 'Genehmigt';

  @override
  String get reviewStudioRejected => 'Abgelehnt';

  @override
  String get reviewStudioNoVisualChanges =>
      'Keine visuellen Änderungen erkannt.';

  @override
  String get reviewStudioVisualUnavailable => 'Visueller Diff nicht verfügbar';

  @override
  String get reviewStudioApproveChange => 'Beabsichtigte Änderung genehmigen';

  @override
  String reviewStudioChangedRegion(String percent) {
    return '$percent% geändert';
  }

  @override
  String get reviewStudioRenderedOnHost => 'Auf dem Host gerendert';

  @override
  String get reviewStudioVisualAdded => 'Hinzugefügt';

  @override
  String get reviewStudioVisualChanged => 'Geändert';

  @override
  String get reviewStudioVisualRemoved => 'Entfernt';

  @override
  String get reviewStudioVisualApproved => 'Genehmigt';

  @override
  String get reviewStudioVisualUnchanged => 'Unverändert';

  @override
  String get reviewStudioSelectFileForBlast =>
      'Wähle eine geänderte Datei, um ihren Auswirkungsradius zu sehen.';

  @override
  String get reviewStudioNotIndexed =>
      'Repo nicht indiziert — Auswirkungsradius nicht verfügbar.';

  @override
  String reviewStudioAffectedCount(int count) {
    return '$count betroffene Symbole';
  }

  @override
  String get reviewStudioDirectCallers => 'Direkte Aufrufer';

  @override
  String reviewStudioTransitiveAt(int depth) {
    return 'Transitiv (Sprung $depth)';
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
  String get fleetTabLabel => 'Flotte';

  @override
  String get evalsTabLabel => 'Evals';

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
  String get newParenthesis => 'Neue Parenthese';

  @override
  String get parenthesisTitleHint => 'z. B. schnelle Korrektur';

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
  String get reviewSplitLayout => 'Review-Layout';

  @override
  String get openInEditor => 'Im Editor öffnen';

  @override
  String uncommittedChanges(int count) {
    return '$count nicht committete Änderungen';
  }

  @override
  String get commitMessageHint => 'Commit-Nachricht';

  @override
  String get pushedToPr => 'Zur PR gepusht';

  @override
  String get pushFailed => 'Push fehlgeschlagen';

  @override
  String get openAtPrHead => 'Am PR-Head öffnen';

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
  String get channelFlyoutNeedsInput => 'Eingabe erforderlich';

  @override
  String get channelFlyoutPreparing => 'Wird vorbereitet';

  @override
  String get channelFlyoutSetupFailed => 'Einrichtung fehlgeschlagen';

  @override
  String get channelFlyoutNeverRun => 'Hier hat noch kein Agent gearbeitet';

  @override
  String channelFlyoutContextUsage(String used, String percent) {
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
  String get composePrSubtitleFromChannel =>
      'Vom Branch dieser Unterhaltung — zuerst veröffentlichen, wenn GitHub ihn nicht kennt';

  @override
  String get obsTabInsights => 'Übersicht';

  @override
  String get obsTabLive => 'Live';

  @override
  String get obsTabQuality => 'Qualität';

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
  String obsTokensSuffix(String tokens) {
    return '$tokens Token';
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
  String get obsBenchmarkCaption =>
      'Eine bewertete Ansicht der letzten Agentenläufe — bestanden/fehlgeschlagen, Belohnung und Ausgaben pro Aufgabe.';

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
  String get ciCdChecks => 'CI/CD checks';

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
  String checksFailingBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fehlgeschlagen',
      one: '1 fehlgeschlagen',
    );
    return '$_temp0';
  }

  @override
  String get checkCompletedSuccessfully => 'Erfolgreich abgeschlossen';

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
  String get ssoEnabled => 'Diese Verbindung aktivieren';

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
  String get ssoSpEntityIdLabel =>
      'SP-Entity-ID (optional, aus der Server-URL abgeleitet)';

  @override
  String get ssoEmailAttributeLabel => 'E-Mail-Attribut';

  @override
  String get ssoDisplayNameAttributeLabel => 'Anzeigename-Attribut';

  @override
  String get ssoGroupsAttributeLabel => 'Gruppen-Attribut';

  @override
  String get ssoClockSkewLabel => 'Uhrzeit-Toleranz (Sekunden)';

  @override
  String get ssoIssuerLabel => 'Aussteller-URL';

  @override
  String get ssoClientIdLabel => 'Client-ID';

  @override
  String get ssoGroupsClaimLabel => 'Gruppen-Claim';

  @override
  String get ssoDefaultRoleLabel =>
      'Standardrolle (member, admin, viewer, guest)';

  @override
  String get ssoRoleMapLabel => 'Gruppe-zu-Rolle-Zuordnung (JSON)';

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
  String get ssoSaveButton => 'Speichern';

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
  String get fromGhCli => 'aus der gh-CLI';

  @override
  String forgeTokenTitle(String forge) {
    return '$forge-Token';
  }

  @override
  String get connectAForge =>
      'Verbinde einen Code-Host, um Pull Requests zu laden';

  @override
  String get settingsAudio => 'Audio';

  @override
  String get settingsAudioDescription =>
      'Mikrofon, Diktat, Besprechungserkennung und Klanglandschafts-Ausgabe.';

  @override
  String get voiceInputMicrophoneSection => 'Mikrofon';

  @override
  String get voiceInputBehaviorSection => 'Diktat und Besprechungen';

  @override
  String get soundscapeOutputSection => 'Klanglandschafts-Ausgabe';

  @override
  String get soundscapeOutputDevice => 'Ausgabegerät';

  @override
  String get soundscapeOutputDefaultHint =>
      'Umgebungsklang wird über die System-Standardausgabe wiedergegeben.';

  @override
  String get soundscapeOutputGone =>
      'Das ausgewählte Ausgabegerät ist nicht mehr verbunden — bis zur Neuauswahl wird die System-Standardausgabe verwendet.';

  @override
  String get reviewHubOverview => 'Übersicht';

  @override
  String get reviewHubAreas => 'Bereiche';

  @override
  String get reviewHubImpact => 'Auswirkungen';

  @override
  String get reviewHubProvisional => 'Vorläufig';

  @override
  String get reviewHubAiSummary => 'KI-Zusammenfassung';

  @override
  String get reviewHubRisks => 'Risiken';

  @override
  String reviewHubAreaFindingsCount(int count) {
    return '$count Befunde';
  }

  @override
  String reviewHubRepoWideCount(int count) {
    return '+$count repositoryweit';
  }

  @override
  String get reviewHubIntroBody =>
      'Die Agenten analysieren den Diff, kartieren die Änderungsbereiche und erzielen ein Konsensurteil.';

  @override
  String get reviewHubStarted => 'Review gestartet';

  @override
  String get reviewHubAlreadyRunning =>
      'Für diesen Pull-Request läuft bereits ein Review';

  @override
  String get reviewHubAutoPublish => 'Automatisch veröffentlichen';

  @override
  String get reviewHubAutoPublishTooltip =>
      'Abgeschlossene Reviews automatisch auf GitHub veröffentlichen';

  @override
  String get reviewHubChangedSymbols => 'Geänderte Symbole';

  @override
  String get reviewHubReadingOrder => 'Lesereihenfolge';

  @override
  String get reviewHubReadingOrderHint =>
      'Zuerst die Grundlagen, dann ihre Verbraucher, dann die Tests';

  @override
  String get reviewHubOpenInDiff => 'Im Diff öffnen';

  @override
  String reviewHubLayerPosition(int index, int total) {
    return 'Schritt $index von $total';
  }

  @override
  String get reviewHubNoReadingOrder =>
      'Für diesen Bereich wurde keine Lesereihenfolge berechnet';

  @override
  String get reviewHubSymbolsFromBase => 'Aus dem Basis-Index';

  @override
  String get reviewHubSymbolsFromBaseTooltip =>
      'Der Worktree des Pull Requests ist noch nicht indiziert, daher stammen diese Zeilenbereiche vom Basis-Branch und können leicht abweichen.';

  @override
  String reviewHubSymbolLines(int count) {
    return '$count Zeilen';
  }

  @override
  String get reviewHubImpactGraph => 'Graph';

  @override
  String get reviewHubImpactList => 'Liste';

  @override
  String get reviewHubImpactChanged => 'In diesem PR geändert';

  @override
  String reviewHubImpactHops(int hops) {
    return '$hops Sprung/Sprünge entfernt';
  }

  @override
  String reviewHubImpactMore(int count, String file) {
    return '$count weitere in $file';
  }

  @override
  String get reviewHubRisk => 'Risiko';

  @override
  String get reviewHubRiskLow => 'Niedrig';

  @override
  String get reviewHubRiskModerate => 'Mittel';

  @override
  String get reviewHubRiskHigh => 'Hoch';

  @override
  String get reviewHubRiskFactors => 'Was diesen Wert bestimmt';

  @override
  String get reviewHubOrderByRisk => 'Nach Risiko sortieren';

  @override
  String get reviewHubFactorLinesChanged => 'Geänderte Zeilen';

  @override
  String get reviewHubFactorFileCount => 'Dateien';

  @override
  String get reviewHubFactorImpact => 'Abhängige';

  @override
  String get reviewHubFactorBlockingFindings => 'Blockierende Befunde';

  @override
  String get reviewHubFactorCriticalPath => 'Dateien auf kritischem Pfad';

  @override
  String get reviewHubFactorContractBreaking => 'Breaking-API-Änderungen';

  @override
  String get reviewHubFactorVisualChange => 'Visuelle Änderung';

  @override
  String get reviewHubFactorDependencyChurn => 'Abhängigkeitsänderungen';

  @override
  String get reviewHubFactorNoCoveringTests => 'Keine abdeckenden Tests';

  @override
  String get reviewHubStaticRule => 'Statische Regel';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return 'Von einer deterministischen Regel ($rule) in einer von diesem Pull Request hinzugefügten Zeile gefunden — nicht von einem Prüf-Agenten.';
  }

  @override
  String get reviewHubCiSignals => 'CI-Signale';

  @override
  String get reviewHubCiAllPassing => 'Alle Prüfungen bestehen';

  @override
  String get reviewHubCiLogsNotPublished => 'Logs noch nicht veröffentlicht';

  @override
  String get reviewHubCiFailingTests => 'Fehlgeschlagene Tests';

  @override
  String reviewHubCiTouchesFile(String file) {
    return 'Verweist auf $file';
  }

  @override
  String get reviewHubCiUnavailable =>
      'Diese Forge bietet keine CI-Details pro Job';

  @override
  String reviewHubCoveringTests(int count) {
    return 'Abgedeckt von $count Testdatei(en)';
  }

  @override
  String get reviewHubNoCoveringTests =>
      'Keine Testdatei referenziert diesen Bereich';

  @override
  String get reviewHubCoverageUnknown =>
      'Testabdeckung konnte nicht ermittelt werden (Repository nicht indiziert)';

  @override
  String get reviewHubDependencies => 'Abhängigkeiten';

  @override
  String get reviewHubDepsAdded => 'Hinzugefügt';

  @override
  String get reviewHubDepsRemoved => 'Entfernt';

  @override
  String get reviewHubDepsUpgraded => 'Version geändert';

  @override
  String get reviewHubDepsMajorBump => 'Major';

  @override
  String get reviewHubDepsBestEffort =>
      'Dieses Lockfile-Format wird nur näherungsweise gelesen — vor Verwendung prüfen';

  @override
  String get reviewHubDepsNone => 'Keine Abhängigkeit geändert';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return 'Seit der letzten Prüfung: $resolved gelöst · $added neu · $open noch offen';
  }

  @override
  String get reviewHubBadgeNew => 'Neu';

  @override
  String get reviewHubBadgeStillOpen => 'Noch offen';

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return 'Zuvor geprüft bei $sha';
  }

  @override
  String get reviewHubAskArea => 'Frage zu diesem Bereich stellen';

  @override
  String get reviewHubAskPlaceholder =>
      'z. B. warum wird hier eine neue Spalte gebraucht?';

  @override
  String get reviewHubAskSubmit => 'Fragen';

  @override
  String get reviewHubAskSent =>
      'Frage gesendet — die Antwort erscheint in der Unterhaltung';

  @override
  String get reviewHubAskNoAgent =>
      'In diesem Workspace kann kein Agent antworten';

  @override
  String get reviewHubQuestions => 'Fragen';

  @override
  String get reviewHubFixAllInArea =>
      'Alle offenen Befunde in diesem Bereich beheben';

  @override
  String get reviewHubLearnings => 'Gelerntes';

  @override
  String get reviewHubGuidelines => 'Review-Richtlinien';

  @override
  String get reviewHubSuppressions => 'Verworfene Muster';

  @override
  String get reviewHubAddGuideline => 'Richtlinie hinzufügen';

  @override
  String get reviewHubGuidelineGlobHint =>
      'Pfadmuster (optional), z. B. lib/api/**';

  @override
  String get reviewHubGuidelineTextHint => 'Was Prüfende kontrollieren sollen';

  @override
  String reviewHubStatsSummary(int made, int addressed) {
    return '$made Befunde · $addressed bearbeitet';
  }

  @override
  String get reviewHubNoLearnings =>
      'Noch nichts gelernt — verwerfen Sie einen Befund oder fügen Sie eine Richtlinie hinzu';

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
}
