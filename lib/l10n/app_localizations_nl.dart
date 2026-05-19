// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get succeeded => 'Geslaagd';

  @override
  String agentRunRetryLabel(int number, String time) {
    return 'Nieuwe poging #$number · $time';
  }

  @override
  String agentRunStarting(String time) {
    return 'Wordt gestart · $time';
  }

  @override
  String get agentActivityFollowingLive => 'Live activiteit volgen';

  @override
  String get agentActivityJumpToLatest => 'Naar nieuwste';

  @override
  String get agentActivityLoadFailed =>
      'Kon de activiteit van deze run niet laden';

  @override
  String get agentActivityNotRecorded =>
      'Er is geen activiteit vastgelegd voor deze run';

  @override
  String get agentActivityNotRecordedHint =>
      'Runs die eindigden voordat activiteitsvastlegging aan stond, hebben geen tijdlijn.';

  @override
  String get agentActivityRunUnavailable =>
      'Deze run is niet langer beschikbaar';

  @override
  String agentActivitySubagentOf(String agent) {
    return 'Subagent van $agent';
  }

  @override
  String get agentActivityUnsupported =>
      'Activiteitsvastlegging is niet beschikbaar op de verbonden server';

  @override
  String get agentActivityUnsupportedHint =>
      'Herstart de app zodat de nieuwste serverbuild wordt gebruikt.';

  @override
  String get agentActivityWaiting => 'Wachten op activiteit…';

  @override
  String get created => 'Aangemaakt';

  @override
  String get dictationStart => 'Dictaat starten';

  @override
  String get dictationListening => 'Aan het luisteren…';

  @override
  String get dictationUnavailable =>
      'Dictaat vereist een spraakmodel op de serverhost. Stel er een in bij de spraakinstellingen.';

  @override
  String get dictationFailedToStart => 'Kan dictaat niet starten';

  @override
  String get dictationHoldToTalkTitle => 'Houd vast om te spreken';

  @override
  String get dictationHoldToTalkDescription =>
      'Houd de microfoonknop of de sneltoets ingedrukt om te dicteren en laat los om te stoppen. Wanneer uit, druk één keer om te starten en nogmaals om te stoppen.';

  @override
  String get focusConversation => 'Naar gesprek';

  @override
  String get ideAgentActivity => 'Agentactiviteit';

  @override
  String get keybindingPushToTalk => 'Druk om te spreken';

  @override
  String get keybindingPushToTalkDescription =>
      'Spraakdictaat in de berichteneditor vasthouden of omschakelen';

  @override
  String get agentPermissions => 'Agentmachtigingen';

  @override
  String get agentPermissionsSettingsDescription =>
      'Bepaal wat agents zelf mogen doen, eerst moeten vragen of nooit mogen doen — per werkruimte, agent of ruimte.';

  @override
  String get agentPermissionsMatrixDescription =>
      'Stel per soort effect een beslissing in. Regels overschrijven elkaar: ruimte gaat vóór agent gaat vóór werkruimte.';

  @override
  String get guardrailLoading => 'Regels laden…';

  @override
  String get guardrailRulesLoadFailed => 'Kon de machtigingsregels niet laden.';

  @override
  String get guardrailScopeWorkspace => 'Werkruimte';

  @override
  String get guardrailScopeAgent => 'Agent';

  @override
  String get guardrailScopeSpace => 'Ruimte';

  @override
  String get guardrailSelectAgent => 'Selecteer een agent';

  @override
  String get guardrailSelectSpace => 'Selecteer een ruimte';

  @override
  String get guardrailNoAgents => 'Nog geen agents in deze werkruimte.';

  @override
  String get guardrailNoSpaces => 'Nog geen ruimtes in deze werkruimte.';

  @override
  String get guardrailClassFileDelete => 'Een bestand verwijderen';

  @override
  String get guardrailClassFileWriteOutsideWorktree =>
      'Buiten de worktree schrijven';

  @override
  String get guardrailClassGitCommit => 'Een commit maken';

  @override
  String get guardrailClassGitPush => 'Naar een remote pushen';

  @override
  String get guardrailClassPrCreate => 'Een pull request openen';

  @override
  String get guardrailClassPrPublish => 'Een review publiceren of mergen';

  @override
  String get guardrailClassVendorSyncWrite =>
      'Naar een externe tracker schrijven';

  @override
  String get guardrailClassNetworkEgress => 'Toegang tot het netwerk';

  @override
  String get guardrailClassSecretAccess => 'Een secret lezen';

  @override
  String get guardrailClassPackageInstall => 'Een pakket installeren';

  @override
  String get guardrailClassProcessSpawn => 'Een proces uitvoeren';

  @override
  String get guardrailClassWorkspaceMutation => 'Werkruimtestructuur wijzigen';

  @override
  String get guardrailClassEnclosureControl => 'Een omhulling (rig) aansturen';

  @override
  String get navRigs => 'Rigs';

  @override
  String get rigsUnsupportedServer =>
      'Deze server kan geen afgeschermde VM\'s draaien. Rigs hebben een hypervisor nodig op de machine waarop cc_server draait.';

  @override
  String get rigSurfaceComputer => 'Computer';

  @override
  String get rigSurfaceBrowser => 'Browser';

  @override
  String get rigSurfaceMobile => 'Mobiel';

  @override
  String rigSurfaceBrowserEngine(String engine) {
    return '$engine';
  }

  @override
  String rigBrowserEngineHint(String engine) {
    return 'Een wegwerp-$engine, geïsoleerd van je machine. Open een andere engine om dezelfde pagina naast elkaar te vergelijken.';
  }

  @override
  String get rigPhaseReady => 'Klaar';

  @override
  String get rigPhaseStarting => 'Starten';

  @override
  String get rigPhaseParked => 'Gepauzeerd';

  @override
  String get rigPhaseClosing => 'Afsluiten';

  @override
  String get rigPhaseClosed => 'Gesloten';

  @override
  String get rigPhaseFailed => 'Mislukt';

  @override
  String get rigPhaseUnknown => 'Onbekend';

  @override
  String get rigNotAccelerated => 'Geëmuleerd';

  @override
  String get rigAudioListen => 'Naar de machine luisteren';

  @override
  String get rigAudioMute => 'De machine dempen';

  @override
  String get rigYouHaveControl => 'Jij hebt de besturing';

  @override
  String get rigBackendAvailable => 'Beschikbaar';

  @override
  String get rigBackendUnavailable => 'Niet beschikbaar';

  @override
  String get rigEgressNotEnforced =>
      'Het netwerk is niet afgeschermd op deze backend — die regelt zijn eigen verbinding.';

  @override
  String get rigStartMachine => 'Machine starten';

  @override
  String get rigStartHint =>
      'Start een wegwerp-VM die je met je agents deelt voor dit gesprek. Hij wordt bij het sluiten vernietigd en niets erin raakt jouw computer.';

  @override
  String get rigStopMachine => 'Machine stoppen';

  @override
  String get rigSurfaceUnavailable =>
      'Deze server kan dit soort machine niet draaien.';

  @override
  String get rigTabNeedsConversation =>
      'Open eerst een gesprek — een machine hoort bij één gesprek, zodat jij en je agents naar hetzelfde scherm kijken.';

  @override
  String get ideMenuSectionTools => 'Gereedschap';

  @override
  String get ideMenuSectionVirtualMachine => 'Virtuele machine';

  @override
  String get ideMenuSectionReopen => 'Opnieuw openen';

  @override
  String get ideMenuSearchHint => 'Zoeken';

  @override
  String get ideMenuNoMatches => 'Geen resultaten';

  @override
  String get rigMenuComputer => 'Computer';

  @override
  String get rigMenuBrowser => 'Browser';

  @override
  String get rigMenuMobile => 'Telefoon';

  @override
  String rigLabelNumbered(String label, String suffix) {
    return '$label $suffix';
  }

  @override
  String ideCloseKeepTitle(String name) {
    return '$name sluiten?';
  }

  @override
  String get ideCloseKeepBodyMachine =>
      'De machine blijft op de achtergrond draaien — open hem wanneer je wilt weer via de zijbalk. Zet hem uit om zijn geheugen nu vrij te maken.';

  @override
  String get ideCloseKeepBodyShell =>
      'De opdracht draait op de achtergrond door — open de shell wanneer je wilt weer via de zijbalk. Beëindig hem om te stoppen waar hij mee bezig is.';

  @override
  String get ideCloseKeepBodyAgent =>
      'De agent werkt op de achtergrond door — open het gesprek wanneer je wilt weer via de zijbalk. Stop hem om de run nu te beëindigen.';

  @override
  String get ideCloseKeepRunning => 'Laten doorlopen';

  @override
  String get ideCloseShutDownMachine => 'Uitzetten';

  @override
  String get ideCloseEndShell => 'Shell beëindigen';

  @override
  String get ideCloseStopAgent => 'Agent stoppen';

  @override
  String get rigsSettingsSubtitle =>
      'Wat deze server kan starten, welke basis-images hij nodig heeft en welke machines nu draaien';

  @override
  String get rigsCapabilitiesTitle => 'Deze server';

  @override
  String get rigsImagesTitle => 'Basis-images';

  @override
  String get rigsImagesHint =>
      'Elke rig start vanaf een van deze alleen-lezen images. Elke sessie schrijft naar een wegwerplaag, zodat een rig nooit kan veranderen waarmee de volgende start.';

  @override
  String get rigsRunningTitle => 'Draait nu';

  @override
  String get rigsNoneRunning => 'Er draaien geen machines.';

  @override
  String get rigsCustomImagesTitle => 'Aangepaste images (deze werkruimte)';

  @override
  String get rigsCustomImagesHint =>
      'Wijs de Terminal (VM) of Browser (VM) naar je eigen image — breid de standaarden uit met de tools van je project, of gebruik een compatibele uit een registry. Nieuwe machines gebruiken die; draaiende houden hun eigen. Zie de rigs-gids voor wat een image moet bieden.';

  @override
  String get rigsCustomTerminalImageLabel => 'Terminal (VM)-image';

  @override
  String get rigsCustomBrowserImageLabel => 'Browser (VM)-image';

  @override
  String get rigsCustomImagePlaceholder =>
      'bijv. ghcr.io/acme/dev-shell:1.2 — leeg voor de standaard';

  @override
  String get rigsCustomImageInvalid =>
      'Voer een registry-referentie in zoals repo/naam:tag. Lokale paden en archieven zijn niet toegestaan.';

  @override
  String get rigsCustomImageSaved =>
      'Opgeslagen. Nieuwe machines booten deze image; draaiende houden hun eigen.';

  @override
  String get rigsEgressTitle => 'Browser-egress (deze workspace)';

  @override
  String get rigsEgressHint =>
      'Extra hosts die de ingesloten browser mag bereiken — één per regel: een exacte host (api.example.com) of een wildcard voor de subdomeinen (*.example.com). De productsite blijft altijd toegestaan. Nieuwe machines gebruiken de lijst; draaiende behouden de hunne.';

  @override
  String rigsEgressInvalid(String host) {
    return '\"$host\" is geen geldige host.';
  }

  @override
  String get rigsEgressSaved =>
      'Opgeslagen. Nieuwe browsermachines staan deze hosts toe; draaiende behouden de hunne.';

  @override
  String get rigImageInstalled => 'Geïnstalleerd';

  @override
  String get rigImageNotDownloaded => 'Niet gedownload';

  @override
  String get rigImageNotPublished => 'Niet gepubliceerd';

  @override
  String get rigImageNotPublishedHint =>
      'Er is nog geen image gepubliceerd hiervoor, dus er is niets te downloaden. Importeer een compatibele schijf-image om dit in te schakelen.';

  @override
  String get rigImageDownload => 'Downloaden';

  @override
  String get rigImageDownloading => 'Downloaden…';

  @override
  String get rigImageImport => 'Importeren';

  @override
  String get rigImageImportMessage =>
      'Pad naar een qcow2-schijfimage op het bestandssysteem van de server. Het wordt naar de image-opslag gekopieerd, dus het bestand mag daarna verplaatst worden.';

  @override
  String get rigConnectingStream => 'Verbinden met de rig';

  @override
  String get rigStreamNotAllowed => 'Je hebt geen toegang tot deze rig.';

  @override
  String get rigStreamNotRunning => 'Deze rig draait niet meer.';

  @override
  String get rigStreamNeedsFfmpeg =>
      'Live weergave heeft ffmpeg op deze host nodig. Installeer ffmpeg en open het tabblad opnieuw.';

  @override
  String get rigStreamEnded => 'De live weergave is beëindigd.';

  @override
  String get rigStreamFailed => 'De live weergave kon niet worden geopend.';

  @override
  String get rigStreamDisconnected => 'Niet verbonden met een server.';

  @override
  String rigDropSendingOne(String name) {
    return '\"$name\" wordt naar de machine gekopieerd…';
  }

  @override
  String rigDropSendingMany(int count) {
    return '$count bestanden worden naar de machine gekopieerd…';
  }

  @override
  String get rigTerminalDropSending => 'Wordt naar de machine gekopieerd…';

  @override
  String get rigTerminalPasteImage =>
      'Geplakte afbeelding opgeslagen in de machine';

  @override
  String get rigPortsTitle => 'Doorgestuurde poorten';

  @override
  String get rigPortsTooltip => 'Poorten die openstaan in deze machine';

  @override
  String get rigPortsEmpty =>
      'Er luistert nog niets. Start een server in de terminal — een dev-server op poort 3000 verschijnt hier.';

  @override
  String get rigPortsAdd => 'Poort toevoegen';

  @override
  String get rigPortsAddHint => 'Gastpoort om door te sturen (bijv. 3000)';

  @override
  String get rigPortsAutoForward => 'Poorten automatisch doorsturen';

  @override
  String get rigPortsCopyUrl => 'Lokale URL kopiëren';

  @override
  String rigPortsCopiedUrl(String url) {
    return '$url gekopieerd';
  }

  @override
  String get rigPortsStopForward => 'Doorsturen stoppen';

  @override
  String get rigPortsExposeLan => 'Delen op lokaal netwerk';

  @override
  String get rigPortsLanPrivate => 'Alleen lokaal';

  @override
  String get rigPortsLanShared => 'Op het netwerk';

  @override
  String get rigPortsSetDomain => 'Een browserdomein instellen (.test)';

  @override
  String get rigPortsDomainHint =>
      'Domein voor de Browser (VM), bijv. myapp.test — daar bereikbaar, niet op de host';

  @override
  String get rigPortsProcessUnknown => 'onbekend proces';

  @override
  String get rigPortsInactive => 'luistert niet';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'nog $count basis-images te downloaden',
      one: 'nog 1 basis-image te downloaden',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => 'Toestaan';

  @override
  String get guardrailDecisionPrompt => 'Eerst vragen';

  @override
  String get guardrailDecisionDeny => 'Weigeren';

  @override
  String get guardrailSourceThisScope => 'Dit bereik';

  @override
  String get guardrailSourceDefault => 'Standaardwaarde';

  @override
  String get guardrailSourcePreset => 'Modusvoorinstelling';

  @override
  String get guardrailSourceInherited => 'Overgenomen';

  @override
  String get guardrailClearToInherited => 'Terug naar overgenomen waarde';

  @override
  String get guardrailWhatIf => 'Wat als?';

  @override
  String get guardrailWhatIfDescription =>
      'Bekijk hoe de huidige regels een actie zouden afhandelen, met dezelfde logica die voor de agents geldt.';

  @override
  String get guardrailProbeActionLabel => 'Actie';

  @override
  String get guardrailProbeCommandLabel => 'Opdracht (optioneel)';

  @override
  String get guardrailProbeCommandHint => 'bijv. git push origin main';

  @override
  String get guardrailProbeAgentLabel => 'Agent (optioneel)';

  @override
  String get guardrailProbeSpaceLabel => 'Ruimte (optioneel)';

  @override
  String get guardrailProbeNone => 'Geen';

  @override
  String get guardrailProbeModeLabel => 'Modus';

  @override
  String get guardrailProbeResult => 'Resultaat';

  @override
  String get guardrailProbeSource => 'Bron:';

  @override
  String get guardrailAdapterMatrix => 'Waar regels worden afgedwongen';

  @override
  String get guardrailAdapterMatrixDescription =>
      'Eerlijke referentie: waar elk effect daadwerkelijk wordt onderschept, per agent-runner. Dit beschrijft de werkelijkheid, geen garantie — effecten die een runner buiten het circuit uitvoert, kunnen niet worden onderschept.';

  @override
  String get guardrailEffectColumn => 'Effect';

  @override
  String get guardrailAdapterHarness => 'Ingebouwde harness';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => 'Sandbox-basis';

  @override
  String get guardrailEnforcementPolicyGate => 'Beleidscontrole';

  @override
  String get guardrailEnforcementSandbox => 'Alleen sandbox';

  @override
  String get guardrailEnforcementNone => 'Niet afdwingbaar';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      'De machtigingsbeslissing wordt gecontroleerd voordat het effect wordt uitgevoerd en kan het blokkeren.';

  @override
  String get guardrailEnforcementSandboxHelp =>
      'Alleen de sandbox beperkt het; de machtigingsregel wordt niet geraadpleegd.';

  @override
  String get guardrailEnforcementNoneHelp =>
      'De beslissing is alleen adviserend — deze kan hier niet worden onderschept.';

  @override
  String get obsStatCost => 'kosten';

  @override
  String obsStatDelegatedCost(String amount) {
    return '+$amount gedelegeerd';
  }

  @override
  String get obsStatDuration => 'duur';

  @override
  String get obsStatTokens => 'tokens';

  @override
  String get obsStatTools => 'tools';

  @override
  String get openAgentActivity => 'Activiteit openen';

  @override
  String get orgChart => 'Organigram';

  @override
  String get orgChartEmpty => 'Nog geen agents';

  @override
  String get navCalendar => 'Agenda';

  @override
  String get serverConnection => 'Serververbinding';

  @override
  String get serverModeLocal => 'In deze app uitvoeren';

  @override
  String get serverModeLocalDescription =>
      'Control Center draait een eigen server op dit apparaat en bewaart je gegevens lokaal.';

  @override
  String get serverModeRemote => 'Verbinden met een externe instantie';

  @override
  String get serverModeRemoteDescription =>
      'Maak verbinding met een Control Center-server die elders draait. Je gegevens staan op die server.';

  @override
  String get serverRemoteUrl => 'Server-URL';

  @override
  String get serverRemoteDeviceId => 'Apparaat-id';

  @override
  String get serverRemotePairingKey => 'Koppelingssleutel';

  @override
  String get serverRemotePairingKeyHint =>
      'Plak de koppelingssleutel van de externe server';

  @override
  String get serverSetupInviteCode => 'Uitnodigingscode';

  @override
  String get serverSetupInviteCodeHint =>
      'Plak een eenmalige uitnodigingscode (laat leeg om een koppelingssleutel te gebruiken)';

  @override
  String get serverDiscoveryTooltip => 'Zoek servers op je netwerk';

  @override
  String get serverDiscoveryTitle => 'Servers op je netwerk';

  @override
  String get serverDiscoverySearching => 'Zoeken naar servers…';

  @override
  String get serverDiscoveryEmpty =>
      'Geen servers gevonden. Controleer of de server draait en dat dit apparaat hem kan bereiken, en zoek daarna opnieuw.';

  @override
  String get serverDiscoveryRefresh => 'Opnieuw zoeken';

  @override
  String get serverListActive => 'Actief';

  @override
  String get serverListSwitch => 'Wisselen';

  @override
  String get serverListAddTitle => 'Server toevoegen';

  @override
  String get serverListRemoveActiveHint =>
      'Wissel naar een andere server voordat je deze verwijdert.';

  @override
  String get serverSwitchFailedTitle => 'Kon niet van server wisselen';

  @override
  String get serverListInsecureBadge => 'Onveilig';

  @override
  String get connectionPathLocal => 'Lokaal';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => 'Afsluiten';

  @override
  String get shutdownSubtitle => 'Lokale server wordt gesloten';

  @override
  String get shutdownServiceApprovals => 'Goedkeuringen';

  @override
  String get shutdownServiceBackgroundJobs => 'Achtergrondtaken';

  @override
  String get shutdownServiceScheduler => 'Taakplanner';

  @override
  String get shutdownServiceCalendar => 'Agenda-synchronisatie';

  @override
  String get shutdownServiceWeather => 'Weer';

  @override
  String get shutdownServiceSoundscape => 'Geluidslandschap';

  @override
  String get shutdownServiceMeetings => 'Vergaderingen';

  @override
  String get shutdownServiceVoiceModels => 'Spraakmodellen';

  @override
  String get shutdownServiceNetworking => 'Netwerk';

  @override
  String get shutdownServicePresence => 'Aanwezigheid';

  @override
  String get shutdownServiceDataSync => 'Gegevenssynchronisatie';

  @override
  String get shutdownServiceDeviceRelay => 'Apparaat-relay';

  @override
  String get shutdownServiceMcpConnections => 'MCP-verbindingen';

  @override
  String get shutdownServiceCodeEditors => 'Code-editors';

  @override
  String get serverSharingTitle => 'Deze server delen';

  @override
  String get serverSharingDescription =>
      'Maak deze server bereikbaar vanaf je andere apparaten. Er wordt niets openbaar gemaakt totdat je hieronder een tunnel inschakelt. Koppelingsuitnodigingen bevatten automatisch de actuele adressen van de server; maak ze aan in de werkruimte-instellingen.';

  @override
  String get serverSharingUnavailable =>
      'Deelinstellingen zijn niet beschikbaar op deze server.';

  @override
  String get serverSharingMdnsLabel => 'LAN-detectie';

  @override
  String get serverSharingMdnsOn =>
      'Deze server wordt aangekondigd op je lokale netwerk (mDNS)';

  @override
  String get serverSharingMdnsOff =>
      'Deze server wordt niet aangekondigd op je lokale netwerk (mDNS)';

  @override
  String get serverSharingTunnelLabel => 'Tunnel';

  @override
  String get serverSharingTunnelHelper =>
      'Een ingeschakelde tunnel maakt deze server bereikbaar vanaf het internet. Openbare toegang is opt-in en staat standaard uit.';

  @override
  String get serverSharingProviderOff => 'Uit';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => 'Openbare URL';

  @override
  String get serverSharingTunnelStarting => 'Tunnel wordt gestart…';

  @override
  String serverSharingTunnelError(String error) {
    return 'Tunnelfout: $error';
  }

  @override
  String get serverSharingTunnelUpNoUrl =>
      'De tunnel is actief. Bereik hem via je geconfigureerde DNS-hostnaam.';

  @override
  String get serverSharingRelayLabel => 'Doorsturen';

  @override
  String serverSharingRelayUsage(String amount) {
    return 'Doorgestuurd deze maand: $amount';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return 'Actieve doorstuursessies: $count';
  }

  @override
  String get serverSharingUpdateFailedTitle => 'Kon delen niet bijwerken';

  @override
  String get pairNewClient => 'Een nieuwe client koppelen';

  @override
  String get pairClientNameHint =>
      'Geef deze client een naam (bijv. Werklaptop)';

  @override
  String get pairClientTypeWeb => 'Webbrowser';

  @override
  String get pairClientTypeDesktop => 'Desktop-app';

  @override
  String get pairClientTypePhone => 'Telefoon';

  @override
  String get pairAction => 'Koppelen';

  @override
  String get revoke => 'Intrekken';

  @override
  String get pairCredentialsIntro =>
      'Verbind de nieuwe client met deze gegevens, of open de link erop.';

  @override
  String get pairLinkLabel => 'Link';

  @override
  String get pairScanQr =>
      'Scan deze QR-code met de camera van je telefoon om te koppelen.';

  @override
  String get pairServerUnreachableTitle => 'Niet bereikbaar';

  @override
  String get pairServerUnreachable =>
      'Andere apparaten kunnen deze server niet rechtstreeks bereiken, dus een nieuwe client kan geen verbinding maken. Stel de publieke URL van de server in om meer clients te koppelen.';

  @override
  String get serverSetupTitle => 'Hoe moet Control Center draaien?';

  @override
  String get serverSetupSubtitle =>
      'Control Center heeft een server nodig die je gegevens bezit. Voer er een uit in deze app of maak verbinding met een instantie die elders draait.';

  @override
  String get serverSetupRunLocal => 'In deze app uitvoeren';

  @override
  String get serverSetupConnect => 'Verbinden';

  @override
  String get serverSetupInvalidUrl =>
      'Voer een geldige ws:// of wss:// server-URL in.';

  @override
  String get serverSetupCouldNotConnect => 'Verbinden mislukt';

  @override
  String get serverSetupErrorUnreachable =>
      'We konden de server niet bereiken. Controleer of deze draait en of dit apparaat hem kan bereiken (zelfde netwerk of relay).';

  @override
  String get serverSetupErrorIdentityMismatch =>
      'De identiteit van de server komt niet overeen met de op dit apparaat opgeslagen identiteit. Als de server opnieuw is geïnstalleerd of gereset, verwijder dan de opgeslagen server en koppel opnieuw.';

  @override
  String get serverSetupErrorAuthRejected =>
      'De server heeft dit apparaat geweigerd. Controleer of de koppelsleutel en het apparaat-id overeenkomen met wat de server heeft uitgegeven.';

  @override
  String get serverSetupErrorInviteRejected =>
      'Die uitnodigingscode is ongeldig of verlopen. Vraag om een nieuwe.';

  @override
  String get serverSetupErrorGeneric =>
      'Er is iets misgegaan tijdens het verbinden. Klap de technische details hieronder uit voor meer informatie.';

  @override
  String get serverSetupErrorDetails => 'Technische details';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'nog $count',
      one: 'nog 1',
    );
    return '$_temp0';
  }

  @override
  String get calendarAllDayGutter => 'Hele dag';

  @override
  String calendarAllDayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count afspraken',
      one: '1 afspraak',
    );
    return '$_temp0';
  }

  @override
  String get calendarCollapseAllDay => 'Afspraken voor de hele dag samenvouwen';

  @override
  String get calendarExpandAllDay => 'Afspraken voor de hele dag uitvouwen';

  @override
  String get calendarViewMonth => 'Maand';

  @override
  String get calendarViewWeek => 'Week';

  @override
  String get calendarViewAgenda => 'Agenda';

  @override
  String get calendarConnectGoogle => 'Google Agenda verbinden';

  @override
  String get calendarConnectDescription =>
      'Synchroniseer je Google Agenda om afspraken hier te zien en meldingen te krijgen voordat vergaderingen beginnen.';

  @override
  String get calendarDisconnect => 'Verbinding verbreken';

  @override
  String get calendarReconnect => 'Opnieuw verbinden';

  @override
  String get calendarEmptyNoEvents => 'Geen afspraken in dit bereik';

  @override
  String get calendarStartRecording => 'Opname starten';

  @override
  String get calendarStartRecordingAndLink => 'Opnemen en koppelen';

  @override
  String get calendarJoinMeet => 'Deelnemen aan vergadering';

  @override
  String get calendarFromCalendar => 'Uit de agenda';

  @override
  String get calendarLinkedMeeting => 'Gekoppelde vergadering';

  @override
  String get calendarToday => 'Vandaag';

  @override
  String get calendarAllDay => 'Hele dag';

  @override
  String calendarWeekNumber(int number) {
    return 'Week $number';
  }

  @override
  String get calendarPreviousPeriod => 'Vorige';

  @override
  String get calendarNextPeriod => 'Volgende';

  @override
  String calendarLastSynced(String time) {
    return 'Gesynchroniseerd $time';
  }

  @override
  String get calendarNeverSynced => 'Nog niet gesynchroniseerd';

  @override
  String get calendarSyncing => 'Synchroniseren…';

  @override
  String get calendarViewDay => 'Dag';

  @override
  String get calendarShow => 'Tonen';

  @override
  String get calendarHide => 'Verbergen';

  @override
  String get calendarRsvpGoing => 'Aanwezig?';

  @override
  String get calendarRsvpYes => 'Ja';

  @override
  String get calendarRsvpNo => 'Nee';

  @override
  String get calendarRsvpMaybe => 'Misschien';

  @override
  String get calendarRsvpFailed => 'Kon je reactie niet bijwerken';

  @override
  String get calendarAddAccount => 'Agenda-account toevoegen';

  @override
  String get calendarSettingsTitle => 'Google Agenda';

  @override
  String get calendarSettingsDescription =>
      'Verbind een Google-account om afspraken in deze werkruimte te synchroniseren.';

  @override
  String get calendarConnecting => 'Verbinden…';

  @override
  String get calendarSyncNow => 'Nu synchroniseren';

  @override
  String get calendarNoWorkspace =>
      'Selecteer een werkruimte om de agenda te bekijken';

  @override
  String get calendarConnectError => 'Kan Google Agenda niet verbinden';

  @override
  String get calendarClientIdLabel => 'Client-ID';

  @override
  String get calendarClientSecretLabel => 'Client-secret';

  @override
  String get calendarConnectCredsHint =>
      'Voer de OAuth-client-ID en het secret (device-code) van je Google-project in. De server verzorgt de verbinding en synchronisatie — je browser bewaart de tokens nooit.';

  @override
  String get calendarConnectApproveInstruction =>
      'Open de verificatiepagina op een willekeurig apparaat, log in en voer deze code in:';

  @override
  String get calendarConnectOpenPage => 'Verificatiepagina openen';

  @override
  String get calendarConnectWaiting => 'Wachten op goedkeuring…';

  @override
  String get calendarConnectDenied =>
      'De autorisatie is geweigerd. Probeer het opnieuw.';

  @override
  String get calendarConnectExpired =>
      'De code is verlopen. Probeer het opnieuw.';

  @override
  String get notificationMeetingStartsSoon => 'Vergadering begint zo';

  @override
  String get notifyMeetingStartsSoon =>
      'Wanneer een afspraak in de agenda bijna begint';

  @override
  String get notificationCalendarAuthExpiredTitle => 'Agenda losgekoppeld';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'Verbind $email opnieuw om het synchroniseren te hervatten';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'Verbind je agenda opnieuw om het synchroniseren te hervatten';

  @override
  String get notifyCalendarAuthExpired =>
      'Wanneer een agenda-account opnieuw moet worden verbonden';

  @override
  String get notificationRigStatusChanged => 'Omheining-updates';

  @override
  String get notifyRigStatusChanged =>
      'Wanneer een omheining wordt overgenomen, teruggehaald of faalt';

  @override
  String get notificationRigTakenOver => 'Omheining overgenomen';

  @override
  String get notificationRigTakenOverBody =>
      'Een persoon bestuurt de machine; de agent kan meekijken maar niet handelen.';

  @override
  String get notificationRigReleased => 'Besturing van omheining vrijgegeven';

  @override
  String get notificationRigReleasedBody => 'De agent heeft de machine weer.';

  @override
  String get notificationRigReclaimed => 'Omheining teruggehaald';

  @override
  String get notificationRigReclaimedBodyIdle =>
      'Ze stond stil, dus de machine is gesloten om geheugen vrij te maken.';

  @override
  String get notificationRigReclaimedBodyTtl =>
      'Ze heeft haar tijdslimiet bereikt en is gesloten.';

  @override
  String get notificationRigFailed => 'Omheining mislukt';

  @override
  String get notificationRigFailedBody =>
      'De hypervisor is eronder overleden. Open de machine opnieuw om verder te gaan.';

  @override
  String get calendarAlertLeadTime => 'Voorlooptijd melding';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'Hoe lang voor een vergadering je een melding krijgt';

  @override
  String calendarConnectedAs(String email) {
    return 'Verbonden als $email';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count deelnemers';
  }

  @override
  String get calendarEventLabel => 'Afspraak';

  @override
  String get calendarRecurring => 'Terugkerende afspraak';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'Organisator';

  @override
  String get calendarYou => 'Jij';

  @override
  String get calendarShowFewer => 'Minder tonen';

  @override
  String get calendarRsvpAwaiting => 'In afwachting';

  @override
  String calendarParticipantsCount(int count) {
    return '$count deelnemers';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'Alle $count deelnemers tonen';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count ja';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count nee';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count misschien';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count in afwachting';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count minuten';
  }

  @override
  String get openInEditorPrompt => 'In welke editor openen?';

  @override
  String get ideNotInstalled => 'Niet geïnstalleerd';

  @override
  String openInIde(String editor) {
    return 'Openen in $editor';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return 'Kan $editor niet openen: $error';
  }

  @override
  String get profileSearchHint => 'Pull requests zoeken…';

  @override
  String get stopAgentRun => 'Run stoppen';

  @override
  String get stopAgentRunConfirm =>
      'Deze run stoppen? Werk in uitvoering gaat verloren.';

  @override
  String get inProgress => 'Bezig';

  @override
  String get drafts => 'Concepten';

  @override
  String get sortOldest => 'Oudste';

  @override
  String get sortLargest => 'Grootste';

  @override
  String get prFilterTooltip => 'Filteren';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actieve filters',
      one: '1 actief filter',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => 'Filter toevoegen…';

  @override
  String get prFilterFieldHint => 'Filteren…';

  @override
  String get prFilterCategoryStatus => 'Status';

  @override
  String get prFilterCategoryAuthor => 'Auteur';

  @override
  String get prFilterCategoryReviewer => 'Reviewers';

  @override
  String get prFilterCategoryContent => 'Inhoud';

  @override
  String get prFilterCategoryRepoOwner => 'Repository-eigenaar';

  @override
  String get prFilterCategoryRepoName => 'Repositorynaam';

  @override
  String get prFilterCategoryOpenedDate => 'Geopend op';

  @override
  String get prFilterCategoryUpdatedDate => 'Bijgewerkt op';

  @override
  String get prFilterQuickToReview => 'Snel te reviewen';

  @override
  String get prFilterClearAll => 'Filters wissen';

  @override
  String prFilterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requests',
      one: '1 pull request',
    );
    return '$_temp0';
  }

  @override
  String prFilterHiddenOptions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opties zonder overeenkomende pull requests',
      one: '1 optie zonder overeenkomende pull requests',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => 'Titel of tekst bevat…';

  @override
  String get prFilterNoOptions => 'Geen overeenkomende opties';

  @override
  String get prFilterChipIs => 'is';

  @override
  String get prFilterChipIsAnyOf => 'is een van';

  @override
  String get prFilterChipContains => 'bevat';

  @override
  String get prFilterChipSince => 'sinds';

  @override
  String get prFilterAddFilterButton => 'Filter toevoegen';

  @override
  String prFilterClearCategory(String category) {
    return '$category-filter wissen';
  }

  @override
  String get prFilterCurrentUser => 'Huidige gebruiker';

  @override
  String get prStatusDraft => 'Concept';

  @override
  String get prStatusOpen => 'Open';

  @override
  String get prStatusInReview => 'In review';

  @override
  String get prStatusChangesRequested => 'Wijzigingen aangevraagd';

  @override
  String get prStatusApproved => 'Goedgekeurd';

  @override
  String get prStatusMerged => 'Samengevoegd';

  @override
  String get prStatusClosed => 'Gesloten';

  @override
  String get prDateWindowDay => '1 dag geleden';

  @override
  String get prDateWindowThreeDays => '3 dagen geleden';

  @override
  String get prDateWindowWeek => '1 week geleden';

  @override
  String get prDateWindowMonth => '1 maand geleden';

  @override
  String get prDateWindowThreeMonths => '3 maanden geleden';

  @override
  String get prDateWindowSixMonths => '6 maanden geleden';

  @override
  String get prDateWindowYear => '1 jaar geleden';

  @override
  String get prDisplayOptions => 'Weergaveopties';

  @override
  String get prDisplayGrouping => 'Groepering';

  @override
  String get prDisplayOrdering => 'Sortering';

  @override
  String get prDisplayShowDrafts => 'Concepten tonen';

  @override
  String get prDisplayMergedWindow => 'Mergevenster';

  @override
  String get prDisplayMergedWindowDay => 'Afgelopen dag';

  @override
  String get prDisplayMergedWindowWeek => 'Afgelopen week';

  @override
  String get prDisplayMergedWindowMonth => 'Afgelopen maand';

  @override
  String get prDisplayProperties => 'Weergave-eigenschappen';

  @override
  String get prGroupingRepository => 'Repository';

  @override
  String get prGroupingAuthor => 'Auteur';

  @override
  String get prGroupingStatus => 'Status';

  @override
  String get prGroupingNone => 'Geen groepering';

  @override
  String get prPropertyRepository => 'Repository';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => 'Branch';

  @override
  String get prPropertyUpdated => 'Bijgewerkt';

  @override
  String get prPropertyAuthor => 'Auteur';

  @override
  String get prPropertyChecks => 'Controles';

  @override
  String get prPropertyDiff => 'Diff';

  @override
  String get prPropertyComments => 'Reacties';

  @override
  String get keybindingOpenFilterMenu => 'Filtermenu openen';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'Het PR-filtermenu openen';

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count geselecteerd',
      one: '1 geselecteerd',
    );
    return '$_temp0';
  }

  @override
  String get summary => 'Samenvatting';

  @override
  String get kbMove => 'verplaatsen';

  @override
  String get kbTabs => 'tabbladen';

  @override
  String get kbSearch => 'zoeken';

  @override
  String get kbViewed => 'bekeken';

  @override
  String get kbCollapse => 'inklappen';

  @override
  String get appearance => 'Weergave';

  @override
  String get appearanceSettingsDescription => 'Thema, taal en typografie.';

  @override
  String get notificationsSettingsDescription =>
      'Kies welke agent- en werkruimtegebeurtenissen je een melding sturen.';

  @override
  String get advanced => 'Geavanceerd';

  @override
  String get accounts => 'Accounts';

  @override
  String get mcpServers => 'MCP-servers';

  @override
  String get mcpServersSettingsDescription =>
      'Ingebouwde MCP-server en externe MCP-servers.';

  @override
  String get remoteControlAndDevices => 'Afstandsbediening en apparaten';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'Koppel telefoons en configureer de afstandsbedieningsserver.';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'De spraak- en diarisatiemodellen die deze server host.';

  @override
  String get filterSettingsHint => 'Instellingen filteren';

  @override
  String get needsSetupLabel => 'Configuratie vereist';

  @override
  String noSettingsMatch(String query) {
    return 'Geen instelling komt overeen met \"$query\"';
  }

  @override
  String get collapseSidebar => 'Zijbalk samenvouwen';

  @override
  String get expandSidebar => 'Zijbalk uitvouwen';

  @override
  String get filterSpacesHint => 'Ruimtes filteren';

  @override
  String noSpacesMatch(String query) {
    return 'Geen ruimtes komen overeen met \"$query\"';
  }

  @override
  String get privacy => 'Privacy';

  @override
  String get sendDiffContentTitle => 'Diff-inhoud naar AI-adapter sturen';

  @override
  String get diffSharingOnSubtitle =>
      'Ruwe diff-regels worden opgenomen in agentprompts voor een grondigere review.';

  @override
  String get diffSharingOffSubtitle =>
      'Agenten gebruiken alleen gestructureerde metadata (bestandspaden, regelnummers, PR-beschrijving); er verlaat geen ruwe code de app.';

  @override
  String get errorReportingTitle => 'Crashrapporten delen';

  @override
  String get errorReportingOnSubtitle =>
      'Crash-, fout- en prestatiediagnostiek wordt verzonden om bugs te helpen oplossen (alleen in release-builds).';

  @override
  String get errorReportingOffSubtitle =>
      'Diagnostiek is uitgeschakeld. Er worden geen crash- of foutrapporten verzonden.';

  @override
  String get onboardingDiagnosticsTitle => 'Help Control Center verbeteren';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'Verzend crash-, fout- en prestatiediagnostiek zodat we problemen sneller kunnen oplossen (alleen in release-builds). Je kunt dit altijd wijzigen in Instellingen → Privacy.';

  @override
  String get blocked => 'Geblokkeerd';

  @override
  String get idle => 'Inactief';

  @override
  String get noRunsYet => 'Nog geen uitvoeringen';

  @override
  String lastActiveAgo(String duration) {
    return '$duration geleden actief';
  }

  @override
  String get copyPath => 'Pad kopiëren';

  @override
  String get copyRelativePath => 'Relatief pad kopiëren';

  @override
  String get nameRequired => 'Naam is verplicht';

  @override
  String get import => 'Importeren';

  @override
  String get sortByStatus => 'Status';

  @override
  String get sortByName => 'Naam';

  @override
  String get noMatchingAgents => 'Geen agenten komen overeen met je filter';

  @override
  String watchVideoOn(String provider) {
    return 'Bekijk video op $provider';
  }

  @override
  String get branchTemplate => 'Sjabloon voor branchnaam';

  @override
  String get branchTemplateDescription =>
      'Patroon voor de branch die wordt aangemaakt wanneer een ticket in een geïsoleerde worktree wordt gestart.';

  @override
  String branchTemplatePreview(String example) {
    return 'Voorbeeld: $example';
  }

  @override
  String get deletePipelineRun => 'Pipelineuitvoering verwijderen';

  @override
  String deletePipelineRunConfirm(String template) {
    return 'Deze uitvoering van \"$template\" verwijderen? Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'Fout bij het verwijderen van de pipelineuitvoering: $error';
  }

  @override
  String get deleteTicket => 'Ticket verwijderen';

  @override
  String deleteTicketConfirm(String title) {
    return '\"$title\" verwijderen? Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'Fout bij het verwijderen van het ticket: $error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return '\"$name\" verwijderen? Gekoppelde repository\'s op schijf blijven onaangeroerd.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'Fout bij het verwijderen van de werkruimte: $error';
  }

  @override
  String get indexCode => 'Code indexeren';

  @override
  String get indexNoGrammars => 'Codegrammatica\'s niet geïnstalleerd';

  @override
  String get indexFailed => 'Indexeren mislukt';

  @override
  String indexedSymbolsCount(int count) {
    return '$count symbolen geïndexeerd';
  }

  @override
  String get nodeConfigAdvanced => 'Geavanceerd';

  @override
  String get nodeConfigReducer => 'Reducer';

  @override
  String get nodeConfigReducerHelp =>
      'Hoe samen te voegen wanneer deze uitvoersleutel al een waarde heeft';

  @override
  String get nodeConfigTimeoutMs => 'Time-out (ms)';

  @override
  String get nodeConfigRetryAttempts => 'Nieuwe pogingen';

  @override
  String get nodeConfigContinueOnFail => 'Doorgaan als deze stap mislukt';

  @override
  String get nodeConfigTeamId => 'Team-ID';

  @override
  String get nodeConfigDispatchMode => 'Verzendmodus';

  @override
  String get nodeConfigOutputSchema => 'Uitvoerschema (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'JSON-schema waaraan de stapuitvoer moet voldoen';

  @override
  String get diffLineDisplay => 'Lange regels in diffs';

  @override
  String get diffLineDisplayDescription =>
      'Lange regels afbreken of horizontaal scrollen';

  @override
  String get diffLineWrap => 'Afbreken';

  @override
  String get diffLineScroll => 'Horizontaal scrollen';

  @override
  String get actions => 'Acties';

  @override
  String get activate => 'Activeren';

  @override
  String get activity => 'Activiteit';

  @override
  String get activityLabel => 'ACTIVITEIT';

  @override
  String get activitySearchHint => 'Activiteit zoeken';

  @override
  String get activityNoMatches => 'Geen activiteit komt overeen met je filters';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$start–$end van $total';
  }

  @override
  String get activityPreviousPage => 'Vorige pagina';

  @override
  String get activityNextPage => 'Volgende pagina';

  @override
  String get activityNetworkLocal => 'Localhost';

  @override
  String get activityClearFilter => 'Filter wissen';

  @override
  String activityFilterIp(String ip) {
    return 'IP $ip';
  }

  @override
  String activityFilterCountry(String country) {
    return 'Land $country';
  }

  @override
  String get activitySavedWorkspaceLogo => 'Workspace-logo opgeslagen';

  @override
  String activityVerbCreated(String target) {
    return '$target aangemaakt';
  }

  @override
  String activityVerbUpdated(String target) {
    return '$target bijgewerkt';
  }

  @override
  String activityVerbDeleted(String target) {
    return '$target verwijderd';
  }

  @override
  String activityVerbAdded(String target) {
    return '$target toegevoegd';
  }

  @override
  String activityVerbRemoved(String target) {
    return '$target weggehaald';
  }

  @override
  String activityVerbInvited(String target) {
    return '$target uitgenodigd';
  }

  @override
  String activityVerbChanged(String target) {
    return '$target gewijzigd';
  }

  @override
  String activityVerbStarted(String target) {
    return '$target gestart';
  }

  @override
  String activityVerbStopped(String target) {
    return '$target gestopt';
  }

  @override
  String activityVerbWrote(String target) {
    return '$target geschreven';
  }

  @override
  String get activityTargetAgent => 'agent';

  @override
  String get activityTargetTicket => 'ticket';

  @override
  String get activityTargetWorkspace => 'workspace';

  @override
  String get activityTargetRepository => 'repository';

  @override
  String get activityTargetMember => 'lid';

  @override
  String get activityTargetInvite => 'uitnodiging';

  @override
  String get activityTargetSpace => 'ruimte';

  @override
  String get activityTargetMessage => 'bericht';

  @override
  String get activityTargetCache => 'cache';

  @override
  String get activityTargetFile => 'bestand';

  @override
  String get activityTargetPipeline => 'pipeline';

  @override
  String get activityTargetTemplate => 'template';

  @override
  String get activityTargetProvider => 'provider';

  @override
  String get activityTargetModel => 'model';

  @override
  String get activityTargetSkill => 'skill';

  @override
  String get activityTargetTodo => 'taak';

  @override
  String get activityTargetMeeting => 'vergadering';

  @override
  String get activityTargetProject => 'project';

  @override
  String get activityTargetTeam => 'team';

  @override
  String get activityTargetDevice => 'apparaat';

  @override
  String get activityTargetPreference => 'voorkeur';

  @override
  String get activityTargetBudget => 'budget';

  @override
  String activityVerbApproved(String target) {
    return '$target goedgekeurd';
  }

  @override
  String activityVerbArchived(String target) {
    return '$target gearchiveerd';
  }

  @override
  String activityVerbAssigned(String target) {
    return '$target toegewezen';
  }

  @override
  String activityVerbBackedUp(String target) {
    return 'back-up van $target gemaakt';
  }

  @override
  String activityVerbCancelled(String target) {
    return '$target geannuleerd';
  }

  @override
  String activityVerbCleared(String target) {
    return '$target gewist';
  }

  @override
  String activityVerbClosed(String target) {
    return '$target gesloten';
  }

  @override
  String activityVerbCommitted(String target) {
    return '$target gecommit';
  }

  @override
  String activityVerbCompacted(String target) {
    return '$target gecompact';
  }

  @override
  String activityVerbCompleted(String target) {
    return '$target voltooid';
  }

  @override
  String activityVerbConnected(String target) {
    return '$target verbonden';
  }

  @override
  String activityVerbContinued(String target) {
    return '$target voortgezet';
  }

  @override
  String activityVerbDisconnected(String target) {
    return '$target losgekoppeld';
  }

  @override
  String activityVerbDispatched(String target) {
    return '$target doorgestuurd';
  }

  @override
  String activityVerbDrained(String target) {
    return '$target leeggemaakt';
  }

  @override
  String activityVerbEnrolled(String target) {
    return '$target ingeschreven';
  }

  @override
  String activityVerbEstimated(String target) {
    return '$target geschat';
  }

  @override
  String activityVerbImported(String target) {
    return '$target geïmporteerd';
  }

  @override
  String activityVerbInstalled(String target) {
    return '$target geïnstalleerd';
  }

  @override
  String activityVerbKilled(String target) {
    return '$target beëindigd';
  }

  @override
  String activityVerbMarked(String target) {
    return '$target gemarkeerd';
  }

  @override
  String activityVerbMerged(String target) {
    return '$target gemerged';
  }

  @override
  String activityVerbOpened(String target) {
    return '$target geopend';
  }

  @override
  String activityVerbPaused(String target) {
    return '$target gepauzeerd';
  }

  @override
  String activityVerbPolled(String target) {
    return '$target gepolld';
  }

  @override
  String activityVerbPrepared(String target) {
    return '$target voorbereid';
  }

  @override
  String activityVerbProcessed(String target) {
    return '$target verwerkt';
  }

  @override
  String activityVerbPublished(String target) {
    return '$target gepubliceerd';
  }

  @override
  String activityVerbRefined(String target) {
    return '$target verfijnd';
  }

  @override
  String activityVerbRefreshed(String target) {
    return '$target vernieuwd';
  }

  @override
  String activityVerbRegistered(String target) {
    return '$target geregistreerd';
  }

  @override
  String activityVerbRenamed(String target) {
    return '$target hernoemd';
  }

  @override
  String activityVerbReordered(String target) {
    return '$target herschikt';
  }

  @override
  String activityVerbResponded(String target) {
    return 'op $target gereageerd';
  }

  @override
  String activityVerbRestored(String target) {
    return '$target hersteld';
  }

  @override
  String activityVerbResumed(String target) {
    return '$target hervat';
  }

  @override
  String activityVerbRetried(String target) {
    return '$target opnieuw geprobeerd';
  }

  @override
  String activityVerbReverted(String target) {
    return '$target teruggedraaid';
  }

  @override
  String activityVerbReviewed(String target) {
    return '$target beoordeeld';
  }

  @override
  String activityVerbRan(String target) {
    return '$target uitgevoerd';
  }

  @override
  String activityVerbSelected(String target) {
    return '$target geselecteerd';
  }

  @override
  String activityVerbSent(String target) {
    return '$target verzonden';
  }

  @override
  String activityVerbStaged(String target) {
    return '$target gestaged';
  }

  @override
  String activityVerbSteered(String target) {
    return '$target gestuurd';
  }

  @override
  String activityVerbSubmitted(String target) {
    return '$target ingediend';
  }

  @override
  String activityVerbSynced(String target) {
    return '$target gesynchroniseerd';
  }

  @override
  String activityVerbToggled(String target) {
    return '$target omgeschakeld';
  }

  @override
  String activityVerbUninstalled(String target) {
    return '$target gedeïnstalleerd';
  }

  @override
  String activityVerbUnstaged(String target) {
    return '$target uit staging gehaald';
  }

  @override
  String get activityTargetActionPolicy => 'actiebeleid';

  @override
  String get activityTargetGoalRun => 'goal-run';

  @override
  String get activityTargetRunLog => 'run-log';

  @override
  String get activityTargetWorkingMemory => 'werkgeheugen';

  @override
  String get activityTargetRoutingPolicy => 'routeringsbeleid';

  @override
  String get activityTargetAutonomy => 'autonomie';

  @override
  String get activityTargetCalendar => 'agenda';

  @override
  String get activityTargetChecker => 'checker';

  @override
  String get activityTargetEditor => 'editor';

  @override
  String get activityTargetConfirmation => 'bevestiging';

  @override
  String get activityTargetTunnel => 'tunnel';

  @override
  String get activityTargetConversation => 'gesprek';

  @override
  String get activityTargetCredentials => 'inloggegevens';

  @override
  String get activityTargetDictation => 'dictee';

  @override
  String get activityTargetAgentRun => 'agent-run';

  @override
  String get activityTargetEvalSuite => 'eval-suite';

  @override
  String get activityTargetWorker => 'worker';

  @override
  String get activityTargetWorktree => 'worktree';

  @override
  String get activityTargetMcpServer => 'MCP-server';

  @override
  String get activityTargetMemoryAccessGrant => 'geheugentoegangsverlening';

  @override
  String get activityTargetMemoryDomain => 'geheugendomein';

  @override
  String get activityTargetMemoryFact => 'geheugenfeit';

  @override
  String get activityTargetMemoryPolicy => 'geheugenbeleid';

  @override
  String get activityTargetFeed => 'feed';

  @override
  String get activityTargetNote => 'notitie';

  @override
  String get activityTargetOrchestration => 'orkestratie';

  @override
  String get activityTargetPipelineRun => 'pipeline-run';

  @override
  String get activityTargetPipelineTrigger => 'pipeline-trigger';

  @override
  String get activityTargetPlan => 'plan';

  @override
  String get activityTargetPlaybook => 'playbook';

  @override
  String get activityTargetPullRequest => 'pull request';

  @override
  String get activityTargetReview => 'review';

  @override
  String get activityTargetProcess => 'proces';

  @override
  String get activityTargetProviderPolicy => 'providerbeleid';

  @override
  String get activityTargetReaction => 'reactie';

  @override
  String get activityTargetReviewSpace => 'reviewruimte';

  @override
  String get activityTargetReviewStudio => 'reviewstudio';

  @override
  String get activityTargetServerData => 'servergegevens';

  @override
  String get activityTargetSoundscape => 'geluidslandschap';

  @override
  String get activityTargetSession => 'sessie';

  @override
  String get activityTargetTerminal => 'terminal';

  @override
  String get activityTargetTicketLink => 'ticketkoppeling';

  @override
  String get activityTargetTicketSync => 'ticketsynchronisatie';

  @override
  String get activityTargetProfile => 'profiel';

  @override
  String get activityTargetVoiceProfile => 'stemprofiel';

  @override
  String get activityTargetWeather => 'weersverwachting';

  @override
  String get activityTargetWorkProduct => 'werkproduct';

  @override
  String get activityChangedMemberRole => 'Rol van een lid gewijzigd';

  @override
  String get activityChangedMemberRepoAccess =>
      'Repositorytoegang van een lid gewijzigd';

  @override
  String get activityUpdatedGitHubToken => 'GitHub-token bijgewerkt';

  @override
  String get activityRefreshedWeather => 'Weersverwachting vernieuwd';

  @override
  String get activitySetWeatherLocation => 'Weerlocatie ingesteld';

  @override
  String get activityClearedWeatherLocation => 'Weerlocatie gewist';

  @override
  String get activityMarkedAllArticlesRead =>
      'Alle artikelen als gelezen gemarkeerd';

  @override
  String get activityMarkedArticleRead => 'Artikel als gelezen gemarkeerd';

  @override
  String get activityUpdatedSavedArticle => 'Opgeslagen artikel bijgewerkt';

  @override
  String get activityTookOverSession => 'Sessie overgenomen';

  @override
  String get activityHandedBackSession => 'Sessie teruggegeven';

  @override
  String get activityCommittedAndPushed => 'Gecommit en gepusht';

  @override
  String get activityBackedUpServer => 'Back-up van servergegevens gemaakt';

  @override
  String get activityMarkedSpaceRead => 'Ruimte als gelezen gemarkeerd';

  @override
  String get activityRespondedToInvitation =>
      'Op de uitnodiging voor het evenement gereageerd';

  @override
  String get activityStartedCalendarConnect => 'Agendakoppeling gestart';

  @override
  String get activityDisconnectedCalendar => 'Agenda losgekoppeld';

  @override
  String get activityMarkedFileViewed => 'Bestand als bekeken gemarkeerd';

  @override
  String get activityRespondedToApproval =>
      'Op een goedkeuringsverzoek gereageerd';

  @override
  String get activityChangedTunnel => 'Tunnelinstelling gewijzigd';

  @override
  String get activitySentMessageToAgent => 'Bericht naar de agent gestuurd';

  @override
  String get activityOpenedReviewSpace => 'Reviewruimte geopend';

  @override
  String get activityOpenedStandingConversation => 'Opende het vaste gesprek';

  @override
  String get activityStartedRecording => 'Opname gestart';

  @override
  String get activityStoppedRecording => 'Opname gestopt';

  @override
  String get activityToggledMcpServer => 'MCP-server omgeschakeld';

  @override
  String get activityUpdatedMcpToken => 'MCP-token bijgewerkt';

  @override
  String get activitySavedApiKey => 'API-sleutel opgeslagen';

  @override
  String get activityRemovedProviderCredential =>
      'Provider-inloggegevens weggehaald';

  @override
  String get activityUpdatedLinkedRepos => 'Gekoppelde repositories bijgewerkt';

  @override
  String get activityUnlinkedRepo => 'Repository losgekoppeld';

  @override
  String get activityUpdatedActionItem => 'Actiepunt bijgewerkt';

  @override
  String adRulesCount(int count) {
    return '$count advertentieregels';
  }

  @override
  String get adapter => 'Adapter';

  @override
  String get adapterLabel => 'Adapter';

  @override
  String get adapters => 'Adapters';

  @override
  String get adaptersAutoDetected =>
      'Automatisch gedetecteerde agent-runners beschikbaar op deze machine. Installeer ontbrekende CLI-tools om extra runners in te schakelen.';

  @override
  String get add => 'Toevoegen';

  @override
  String get addAComment => 'Een reactie toevoegen';

  @override
  String get addAReaction => 'Een reactie toevoegen';

  @override
  String get addASuggestion => 'Een suggestie toevoegen';

  @override
  String get addAgents => 'Agenten toevoegen';

  @override
  String get addEmoji => 'Emoji toevoegen';

  @override
  String get addFeed => 'Feed toevoegen';

  @override
  String get addressBarHint => 'Voer een URL in';

  @override
  String get addFromFile => 'Uit bestand toevoegen';

  @override
  String get addGif => 'GIF toevoegen';

  @override
  String get addGithubRepoPrompt =>
      'Voeg minimaal één GitHub-repository toe om pull requests te zien';

  @override
  String get addLocalCheckoutDescription =>
      'Voeg een lokale checkout toe om er vanuit deze werkruimte op te richten.';

  @override
  String get addRepository => 'Repository toevoegen';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repositories toevoegen',
      one: 'Repository toevoegen',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro =>
      'Blader door de mappen op de machine die de server draait en selecteer de git-checkouts om te registreren.';

  @override
  String get selectThisFolder => 'Deze map selecteren';

  @override
  String get deselectThisFolder => 'Deze map deselecteren';

  @override
  String get goUp => 'Omhoog';

  @override
  String get noSubfoldersHere => 'Geen submappen hier';

  @override
  String get notAGitRepository => 'Deze map is geen git-repository.';

  @override
  String get addToken => 'Token toevoegen';

  @override
  String get addWorkspace => 'Werkruimte toevoegen';

  @override
  String get addWorkspaceEllipsis => 'Werkruimte toevoegen…';

  @override
  String get added => 'Toegevoegd';

  @override
  String get addingEllipsis => 'Toevoegen…';

  @override
  String get advancedLabel => 'Geavanceerd';

  @override
  String get agent => 'Agent';

  @override
  String agentCount(int count, int plural) {
    String _temp0 = intl.Intl.pluralLogic(
      plural,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count agent$_temp0';
  }

  @override
  String get agentMdPath => 'Agent-MD-pad';

  @override
  String get agentName => 'Agentnaam';

  @override
  String get agentTitle => 'Agenttitel';

  @override
  String get agentUpdated => 'Agent bijgewerkt.';

  @override
  String get agents => 'Agenten';

  @override
  String get agentsMentionSection => 'Agenten';

  @override
  String get usersMentionSection => 'Personen';

  @override
  String get ticketsMentionSection => 'Tickets';

  @override
  String get pullRequestsMentionSection => 'Pull requests';

  @override
  String get meetingsMentionSection => 'Vergaderingen';

  @override
  String get entityRefTicketFallback => 'Ticket';

  @override
  String get entityRefPrFallback => 'Pull request';

  @override
  String get entityRefMeetingFallback => 'Vergadering';

  @override
  String get aiReview => 'AI-review';

  @override
  String get all => 'Alles';

  @override
  String get allAgentsAlreadyInSpace =>
      'Alle agenten zitten al in deze ruimte.';

  @override
  String get allCommits => 'Alle commits';

  @override
  String get allSources => 'Alle bronnen';

  @override
  String get allow => 'Toestaan';

  @override
  String get allowGitPush => 'git push toestaan';

  @override
  String get allowGithubApi => 'GitHub API-aanroepen toestaan';

  @override
  String get allowNetwork => 'Algemene netwerktoegang toestaan';

  @override
  String get apiKeys => 'API-sleutels';

  @override
  String get appFont => 'App-lettertype';

  @override
  String get appLogLevelDebugDescription =>
      'Voegt gedetailleerde traces toe - voor ontwikkeling.';

  @override
  String get appLogLevelDebugLabel => 'Debug';

  @override
  String get appLogLevelErrorDescription =>
      'Alleen fouten en onverwachte uitzonderingen.';

  @override
  String get appLogLevelErrorLabel => 'Fout';

  @override
  String get appLogLevelInfoDescription =>
      'Voegt levenscyclus- en statusberichten toe.';

  @override
  String get appLogLevelInfoLabel => 'Info';

  @override
  String get appLogLevelNoneDescription => 'Geen console-uitvoer.';

  @override
  String get appLogLevelNoneLabel => 'Geen';

  @override
  String get appLogLevelVerboseDescription =>
      'Alles. Extreem verbose - alleen voor debugging gebruiken.';

  @override
  String get appLogLevelVerboseLabel => 'Verbose';

  @override
  String get appLogLevelWarningDescription =>
      'Voegt waarschuwingen en herstelbare problemen toe.';

  @override
  String get appLogLevelWarningLabel => 'Waarschuwing';

  @override
  String get appearanceLanguage => 'Weergave en taal';

  @override
  String get apply => 'Toepassen';

  @override
  String get approve => 'Goedkeuren';

  @override
  String get agentApprovalRequired => 'Goedkeuring vereist';

  @override
  String agentApprovalsMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nog $count in de wachtrij',
      one: 'Nog 1 in de wachtrij',
    );
    return '$_temp0';
  }

  @override
  String get approved => 'Goedgekeurd';

  @override
  String get articlesSubscribed => 'Artikelen uit je geabonneerde feeds.';

  @override
  String get askAi => 'Ask AI';

  @override
  String get askAiReviewDescription => 'Vraag de AI om deze PR te reviewen';

  @override
  String get assignees => 'TOEGEWEZENEN';

  @override
  String get attachFiles => 'Bestanden bijvoegen';

  @override
  String get attachImage => 'Afbeelding bijvoegen';

  @override
  String get attachedAgents => 'Gekoppelde agenten';

  @override
  String get audioInput => 'Audio-invoer';

  @override
  String get audioOutput => 'Audio-uitvoer';

  @override
  String get authenticationToken => 'Authenticatietoken';

  @override
  String authoredByLabel(String role) {
    return 'Door: $role';
  }

  @override
  String get autoRecommended => 'Automatisch (aanbevolen)';

  @override
  String get available => 'Beschikbaar';

  @override
  String get awaitingYourReview => 'Wachtend op jouw review';

  @override
  String get back => 'Terug';

  @override
  String get backLabel => 'Terug';

  @override
  String get backend => 'Backend';

  @override
  String get blockAdsTrackers =>
      'Advertenties, trackers en cookiebanners blokkeren';

  @override
  String get blocking => 'Blokkerend';

  @override
  String get bookmarkLabel => 'Bladwijzer';

  @override
  String get briefDescription => 'Korte beschrijving';

  @override
  String get bugLabel => 'BUG';

  @override
  String get bundledDefaultsNeverUpdated =>
      'Vooraf geïnstalleerd - nooit bijgewerkt';

  @override
  String get cancel => 'Annuleren';

  @override
  String get cancelEdit => 'Bewerking annuleren';

  @override
  String get categoryCreation => 'Aanmaken';

  @override
  String get categoryEditing => 'Bewerken';

  @override
  String get categoryNavigation => 'Navigatie';

  @override
  String get categorySystem => 'Systeem';

  @override
  String get categoryView => 'Weergave';

  @override
  String get change => 'Wijzigen';

  @override
  String get changesRequested => 'Wijzigingen aangevraagd';

  @override
  String get spacesMentionSection => 'Ruimtes';

  @override
  String get checkForUpdates => 'Controleren op updates';

  @override
  String get checking => 'Controleren';

  @override
  String get checkingEllipsis => 'Controleren…';

  @override
  String get chooseAppFont => 'App-lettertype kiezen';

  @override
  String get chooseCodeFont => 'Codelettertype kiezen';

  @override
  String get chooseRunner => 'Kies je agent-runner.';

  @override
  String get clear => 'Wissen';

  @override
  String get clickToRetry => 'Klik om opnieuw te proberen';

  @override
  String get close => 'Sluiten';

  @override
  String get closeEsc => 'Sluiten (Esc)';

  @override
  String get closeKeyboardHint => 'Sneltoetsen sluiten';

  @override
  String get closeReader => 'Lezer sluiten';

  @override
  String get closed => 'Gesloten';

  @override
  String get codeFont => 'Codelettertype';

  @override
  String get codeFontLigatures => 'Ligaturen van het codelettertype';

  @override
  String get codeFontLigaturesDescription =>
      'Programmeerligaturen (=>, !=, ->) als gecombineerde glyphs tonen in code en diffs';

  @override
  String get collapse => 'Samenvouwen';

  @override
  String get commandPalette => 'Commandopalet';

  @override
  String get commandPaletteOrgMembers => 'Organization members';

  @override
  String get commandPaletteBrowseTeam => 'Browse team';

  @override
  String get commandPaletteBrowseTeamDesc => 'View all organization members';

  @override
  String get compactDone =>
      'Gesprek gecomprimeerd. De eerdere geschiedenis is samengevat.';

  @override
  String get compactNothing =>
      'Nog niets te comprimeren. Het gesprek is nog kort.';

  @override
  String get compactBusy =>
      'Een agent is nog bezig. Comprimeer zodra de beurt klaar is.';

  @override
  String get compactUnavailable =>
      'Comprimeren is niet beschikbaar op deze server.';

  @override
  String get commandsMentionSection => 'Commando\'s';

  @override
  String get comment => 'Reactie';

  @override
  String get commentOnThisFile => 'Reageren op dit bestand';

  @override
  String get commented => 'Gereageerd';

  @override
  String get commits => 'Commits';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'Toont de laatste $loaded van $total commits';
  }

  @override
  String get prCloneProgressCloningTitle => 'Repository klonen';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'Deze PR wijzigt $fileCount bestanden, wat het API-limiet van GitHub overschrijdt. Repository wordt lokaal gekloond…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'Deze PR overschrijdt het bestandslimiet van de GitHub-API. Repository wordt lokaal gekloond…';

  @override
  String get prCloneProgressFetchingTitle => 'Refs ophalen';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'Basistak en PR-ref worden opgehaald…';

  @override
  String get prCloneProgressComputingTitle => 'Diff berekenen';

  @override
  String get prCloneProgressComputingSubtitle =>
      'Git diff wordt lokaal uitgevoerd…';

  @override
  String get prCloneProgressErrorTitle => 'Laden van diff mislukt';

  @override
  String get prCloneProgressErrorSubtitle =>
      'Er is een fout opgetreden bij het klonen of berekenen van de diff.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'Nog bezig… $elapsed verstreken';
  }

  @override
  String confidenceLabel(int percent) {
    return 'Betrouwbaarheid: $percent%';
  }

  @override
  String get configureAgentIdentities =>
      'Configureer agent-identiteiten, prompts, vaardigheden en bekijk runs.';

  @override
  String get configureDefaultRunners =>
      'Configureer welke adapter en model worden gebruikt voor nieuwe gesprekken en titelgeneratie.';

  @override
  String get configuredLabel => 'Geconfigureerd.';

  @override
  String get confirmedBy => 'Bevestigd door';

  @override
  String get consensus => 'Consensus';

  @override
  String get contentHint => 'Wat moet worden onthouden';

  @override
  String get contentLabel => 'Inhoud';

  @override
  String get contentMarkdown => 'Inhoud (Markdown)';

  @override
  String get contextWindowSize => 'Contextvenstergrootte';

  @override
  String modelContextChip(String size) {
    return 'Model · $size';
  }

  @override
  String get continueLabel => 'Doorgaan';

  @override
  String get conversationMode => 'Modus';

  @override
  String cookieRulesCount(int count) {
    return '$count cookieregels';
  }

  @override
  String get copied => 'Gekopieerd!';

  @override
  String get copy => 'Kopiëren';

  @override
  String get copyAddress => 'Adres kopiëren';

  @override
  String get copyBaseBranchTooltip => 'Naam van doelbranch kopiëren';

  @override
  String get copyHeadBranchTooltip => 'Naam van bronbranch kopiëren';

  @override
  String couldNotListDevices(String error) {
    return 'Kan apparaten niet weergeven: $error';
  }

  @override
  String get create => 'Aanmaken';

  @override
  String get createOrSelectWorkspace =>
      'Maak of selecteer een werkruimte voordat je repository\'s toevoegt.';

  @override
  String get createPullRequest => 'Pull request aanmaken';

  @override
  String get createdByMe => 'Door mij aangemaakt';

  @override
  String createdLabel(String date) {
    return 'Aangemaakt: $date';
  }

  @override
  String get currentParticipants => 'Huidige deelnemers';

  @override
  String get customCapabilitiesDescription =>
      'Aangepaste mogelijkheden voor deze agent';

  @override
  String get customSystemPrompt =>
      'Aangepaste systeem-prompt voor deze agent...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagen geleden',
      one: '1 dag geleden',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'Deactiveren';

  @override
  String get defaultCapabilities =>
      'Standaardmogelijkheden · nieuwe gesprekken';

  @override
  String get defaultChat => 'Standaard-chat';

  @override
  String get defaultRunners => 'Standaard-runners';

  @override
  String get delete => 'Verwijderen';

  @override
  String get deleteAgent => 'Agent verwijderen';

  @override
  String deleteAgentConfirm(String name) {
    return '\\\"$name\\\" verwijderen? Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String get deleteSpace => 'Ruimte verwijderen';

  @override
  String deleteConfirmName(String name) {
    return '\\\"$name\\\" verwijderen?';
  }

  @override
  String get archiveConversation => 'Gesprek archiveren';

  @override
  String get deleteFact => 'Feit verwijderen';

  @override
  String get deleteFeedBody =>
      'Dit verwijdert de feed en alle gecachte artikelen. Opgeslagen artikelen uit deze feed worden ook verwijderd.';

  @override
  String deleteFeedConfirm(String name) {
    return '\\\"$name\\\" verwijderen?';
  }

  @override
  String get deletePolicy => 'Beleidsregel verwijderen';

  @override
  String get deletePolicyConfirm =>
      'Deze beleidsregel verwijderen? Dit kan niet ongedaan worden gemaakt.';

  @override
  String deleteTopicConfirm(String topic) {
    return '\"$topic\" verwijderen? Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String get deleteWorkspace => 'Werkruimte verwijderen';

  @override
  String get deny => 'Weigeren';

  @override
  String get descriptionLabel => 'Beschrijving';

  @override
  String detectedBackend(String label) {
    return 'Gedetecteerd: $label';
  }

  @override
  String get detectedRunners => 'Gedetecteerde runners';

  @override
  String get detectingAdapters => 'Adapters detecteren…';

  @override
  String get detectingInputDevices => 'Invoerapparaten detecteren…';

  @override
  String detectionFailed(String error) {
    return 'Detectie mislukt: $error';
  }

  @override
  String get disabled => 'Uitgeschakeld';

  @override
  String get discover => 'Ontdekken';

  @override
  String get dismissed => 'Gesloten';

  @override
  String get domainHint => 'bijv. api-performance';

  @override
  String get domainLabel => 'Domein';

  @override
  String get download => 'Downloaden';

  @override
  String get downloadingLabel => 'Downloaden';

  @override
  String downloadingModel(int pct) {
    return 'Model downloaden… $pct%';
  }

  @override
  String get draft => 'Concept';

  @override
  String get draftLabel => 'Concept';

  @override
  String get edit => 'Bewerken';

  @override
  String get edited => 'bewerkt';

  @override
  String get editMessage => 'Bericht bewerken';

  @override
  String get deleteMessage => 'Bericht verwijderen';

  @override
  String get deleteMessageConfirm =>
      'Dit bericht verwijderen? Dit kan niet ongedaan worden gemaakt.';

  @override
  String get messageDeleted => 'Bericht verwijderd';

  @override
  String get searchInConversation => 'Zoeken in gesprek';

  @override
  String get searchMessagesHint => 'Berichten zoeken…';

  @override
  String get noMessagesFound => 'Geen berichten gevonden';

  @override
  String get editFact => 'Feit bewerken';

  @override
  String get editPolicy => 'Beleidsregel bewerken';

  @override
  String get editSuggestedCodeHint => 'Voorgestelde code bewerken…';

  @override
  String get editSuggestion => 'Suggestie bewerken';

  @override
  String get egArchitect => 'bijv. architect';

  @override
  String get egControlCenter => 'bijv. control-center';

  @override
  String get egPlatform => 'bijv. macOS';

  @override
  String get egSamuelAlev => 'bijv. SamuelAlev';

  @override
  String get egSoftwareArchitect => 'bijv. Software Architect';

  @override
  String get egTheVerge => 'bijv. The Verge';

  @override
  String get egTokenLimit => 'bijv. 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'Installatie mislukt: $error';
  }

  @override
  String get embeddingInstalled =>
      'Lokaal embedding-model geïnstalleerd. Hybride zoeken is ingeschakeld.';

  @override
  String get embeddingModel => 'Embedding-model (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'Niet geïnstalleerd. Zoeken valt terug op alleen trefwoorden tot dit is ingeschakeld.';

  @override
  String get embeddingRedownloadBody =>
      'De bestaande modelbestanden worden verwijderd en opnieuw gedownload. Semantisch zoeken is niet beschikbaar tot de download is voltooid.';

  @override
  String get embeddingRemoveBody =>
      'Semantisch zoeken wordt uitgeschakeld tot je het opnieuw installeert. Je kunt het op elk moment opnieuw installeren.';

  @override
  String get speakerDiarization => 'Sprekerdiarisatie';

  @override
  String get diarizationModel => 'Diarisatiemodel';

  @override
  String get diarizationInstalled =>
      'Geïnstalleerd — benoemt afzonderlijke sprekers in vergadertranscripties';

  @override
  String get diarizationNotInstalled =>
      'Niet geïnstalleerd — sprekers in vergaderingen worden niet gescheiden';

  @override
  String diarizationInstallFailed(String error) {
    return 'Installatie mislukt: $error';
  }

  @override
  String get redownloadDiarizationModel => 'Diarisatiemodel opnieuw downloaden';

  @override
  String get diarizationRedownloadBody =>
      'Hiermee worden de huidige diarisatiemodellen verwijderd en opnieuw gedownload.';

  @override
  String get removeDiarizationModel => 'Diarisatiemodel verwijderen';

  @override
  String get diarizationRemoveBody =>
      'Hiermee worden de diarisatiemodellen op het apparaat verwijderd. Reeds geproduceerde vergadertranscripties blijven onaangetast.';

  @override
  String get enableNotifications => 'Meldingen inschakelen';

  @override
  String get enableSandboxing => 'Sandboxing inschakelen';

  @override
  String get enabled => 'Ingeschakeld';

  @override
  String errorCreatingAgent(String error) {
    return 'Fout bij aanmaken agent: $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'Fout bij verwijderen agent: $error';
  }

  @override
  String errorWithDetail(String error) {
    return 'Fout: $error';
  }

  @override
  String get expand => 'Uitvouwen';

  @override
  String extractingModel(int pct) {
    return 'Model uitpakken… $pct%';
  }

  @override
  String get fact => 'Feit';

  @override
  String factCount(int count) {
    return '$count feit';
  }

  @override
  String factCountPlural(int count) {
    return '$count feiten';
  }

  @override
  String get facts => 'Feiten';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount feiten · $policyCount beleidsregels';
  }

  @override
  String get failed => 'Mislukt';

  @override
  String failedToDispatch(String error) {
    return 'Verzenden mislukt: $error';
  }

  @override
  String get failedToLoad => 'Laden mislukt';

  @override
  String failedToLoadAgents(String error) {
    return 'Agenten laden mislukt: $error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'Feeds laden mislukt: $error';
  }

  @override
  String get failedToLoadGifs => 'GIFs laden mislukt';

  @override
  String failedToLoadLogs(String error) {
    return 'Logboeken laden mislukt: $error';
  }

  @override
  String get failedToLoadRepos => 'Repository\'s laden mislukt';

  @override
  String get failedToLoadWorkspaces => 'Werkruimtes laden mislukt';

  @override
  String failedToStartAiReview(String error) {
    return 'AI-review starten mislukt: $error';
  }

  @override
  String get failedToStartMicTest => 'Microfoontest starten mislukt.';

  @override
  String failedToSubmitReview(String error) {
    return 'Review indienen mislukt: $error';
  }

  @override
  String failedToUpload(String name, String error) {
    return '$name uploaden mislukt: $error';
  }

  @override
  String failedWithError(String error) {
    return 'Mislukt: $error';
  }

  @override
  String get failure => 'Mislukt';

  @override
  String get feedAlreadyExists => 'Er bestaat al een feed met deze URL.';

  @override
  String get feedUrlExample => 'bijv. https://example.com/feed.xml';

  @override
  String get feedUrlLabel => 'Feed-URL';

  @override
  String feedsCount(int count) {
    return 'Feeds ($count)';
  }

  @override
  String get filesChanged => 'Bestanden gewijzigd';

  @override
  String filesCount(int count) {
    return '$count bestand(en)';
  }

  @override
  String get filesMentionSection => 'Bestanden';

  @override
  String get filterAgents => 'Agenten filteren...';

  @override
  String get filterFilesHint => 'Bestanden filteren…';

  @override
  String get filterLists => 'Filterlijsten';

  @override
  String get filterSkillsPlaceholder => 'Vaardigheden filteren…';

  @override
  String get finish => 'Afronden';

  @override
  String get fix => 'Repareren';

  @override
  String get forward => 'Doorsturen';

  @override
  String get gatesGithubPatPush =>
      'Stuurt GitHub PAT-injectie aan. Vereist om de agent te laten pushen.';

  @override
  String get general => 'Algemeen';

  @override
  String get githubLink => 'GitHub-link';

  @override
  String get claudeStatusFetchFailed => 'Kon status.claude.com niet bereiken';

  @override
  String get claudeStatusOpenInBrowser => 'status.claude.com openen';

  @override
  String get githubStatusFetchFailed => 'Kon githubstatus.com niet bereiken';

  @override
  String get githubDegradedTitle => 'GitHub meldt problemen';

  @override
  String githubDegradedStatusLine(String status) {
    return 'GitHub-status: $status.';
  }

  @override
  String githubDegradedBody(String status) {
    return 'GitHub-status: $status. Pull request-gegevens kunnen verouderd of onvolledig zijn tot het herstelt.';
  }

  @override
  String get githubStatusOpenInBrowser => 'Openen in browser';

  @override
  String get githubStatusRefresh => 'Vernieuwen';

  @override
  String githubStatusUpdated(String time) {
    return 'Bijgewerkt $time';
  }

  @override
  String get kimiStatusFetchFailed => 'Kon status.moonshot.cn niet bereiken';

  @override
  String get kimiStatusOpenInBrowser => 'status.moonshot.cn openen';

  @override
  String get openaiStatusFetchFailed => 'Kon status.openai.com niet bereiken';

  @override
  String get openaiStatusOpenInBrowser => 'status.openai.com openen';

  @override
  String get serviceStatusMaintenance => 'Onderhoud';

  @override
  String get serviceStatusMajorIssues => 'Grote problemen';

  @override
  String get serviceStatusMinorIssues => 'Kleine problemen';

  @override
  String get serviceStatusOperational => 'Operationeel';

  @override
  String get serviceStatusOutage => 'Storing';

  @override
  String get serviceStatusTitle => 'Servicestatus';

  @override
  String get serviceStatusUnknown => 'Onbekend';

  @override
  String lastChecked(String time) {
    return 'Gecontroleerd $time';
  }

  @override
  String get lastCheckedRecently => 'Recent gecontroleerd';

  @override
  String get giveYourWorkAHome => 'Geef je werk een thuis.';

  @override
  String get goBack => 'Ga terug';

  @override
  String get goForward => 'Ga vooruit';

  @override
  String get googleFonts => 'Google Fonts';

  @override
  String get high => 'Hoog';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uur geleden',
      one: '1 uur geleden',
    );
    return '$_temp0';
  }

  @override
  String get images => 'Afbeeldingen';

  @override
  String get inactive => 'Inactief';

  @override
  String get install => 'Installeren';

  @override
  String get installRequired => 'Installatie vereist';

  @override
  String installedVersion(String version) {
    return 'Geïnstalleerd $version';
  }

  @override
  String get invite => 'Uitnodigen';

  @override
  String get inviteAgent => 'Agent uitnodigen';

  @override
  String get isolateAgentExecution => 'Agentuitvoering isoleren.';

  @override
  String get justNow => 'zojuist';

  @override
  String get keepSandboxing => 'Sandboxing behouden';

  @override
  String get keybindingAddARepositoryDescription => 'Een repository toevoegen';

  @override
  String get keybindingAddRepository => 'Repository toevoegen';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'Geselecteerd artikel bookmarken of verwijderen';

  @override
  String get keybindingCommandPalette => 'Commandopalet';

  @override
  String get keybindingCreateANewAgentDescription => 'Nieuwe agent aanmaken';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'Nieuwe werkruimte aanmaken';

  @override
  String get keybindingFocusSearch => 'Zoeken focussen';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'Het zoekveld voor pull requests focussen';

  @override
  String get keybindingNewAgent => 'Nieuwe agent';

  @override
  String get keybindingNewWorkspace => 'Nieuwe werkruimte';

  @override
  String get keybindingNextArticle => 'Volgend artikel';

  @override
  String get keybindingNextSpace => 'Volgend ruimte';

  @override
  String get keybindingNextWorkspace => 'Volgende werkruimte';

  @override
  String get keybindingOpenArticle => 'Artikel openen';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'Werkruimte-wisselaar-popup in zijbalk openen of sluiten';

  @override
  String get keybindingOpenPr => 'PR openen';

  @override
  String get keybindingOpenSettings => 'Instellingen openen';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'Applicatie-instellingen openen';

  @override
  String get keybindingOpenTheCommandPaletteDescription =>
      'Commandopalet openen';

  @override
  String get keybindingOpenTheSelectedArticleDescription =>
      'Geselecteerd artikel openen';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'Geselecteerde pull request openen';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'Geselecteerde werkruimte openen';

  @override
  String get keybindingOpenWorkspace => 'Werkruimte openen';

  @override
  String get keybindingPreviousArticle => 'Vorig artikel';

  @override
  String get keybindingPreviousSpace => 'Vorig ruimte';

  @override
  String get keybindingPreviousWorkspace => 'Vorige werkruimte';

  @override
  String get keybindingRefresh => 'Vernieuwen';

  @override
  String get keybindingRefreshAllFeedsDescription => 'Alle feeds vernieuwen';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'Pull request-lijst vernieuwen';

  @override
  String get keybindingRescanForAdaptersDescription =>
      'Opnieuw scannen naar adapters';

  @override
  String get keybindingSelectTheNextArticleDescription =>
      'Volgend artikel selecteren';

  @override
  String get keybindingSelectTheNextSpaceDescription =>
      'Volgend ruimte selecteren';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'Vorig artikel selecteren';

  @override
  String get keybindingSelectThePreviousSpaceDescription =>
      'Vorig ruimte selecteren';

  @override
  String get keybindingSendMessage => 'Bericht versturen';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'Huidige bericht versturen';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Wisselen tussen lichte en donkere modus';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Wisselen naar achtste werkruimte';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Wisselen naar vijfde werkruimte';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'Wisselen naar eerste werkruimte';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'Wisselen naar vierde werkruimte';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'Wisselen naar volgende werkruimte';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'Wisselen naar negende werkruimte';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'Wisselen naar vorige werkruimte';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'Wisselen naar tweede werkruimte';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'Wisselen naar zevende werkruimte';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'Wisselen naar zesde werkruimte';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'Wisselen naar derde werkruimte';

  @override
  String get keybindingToggleBookmark => 'Bookmark wisselen';

  @override
  String get keybindingToggleTheme => 'Thema wisselen';

  @override
  String get keybindingToggleWorkspaceSwitcher =>
      'Werkruimte-wisselaar wisselen';

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
  String get keybindings => 'Sneltoetsen';

  @override
  String get keybindingsDescription =>
      'Alle sneltoetsen. Sneltoetsen zijn vast en kunnen niet opnieuw worden toegewezen.';

  @override
  String get killRunning => 'Actieve stoppen';

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
  String get languageSystem => 'Systeem';

  @override
  String get leaveACommentEllipsis => 'Reactie achterlaten…';

  @override
  String get legendLabel => 'Legenda';

  @override
  String get lessLabel => 'Minder';

  @override
  String get letsPluginTools => 'Laten we je tools aansluiten.';

  @override
  String get level => 'Niveau';

  @override
  String get loadingAgents => 'Agenten laden…';

  @override
  String get loadingModels => 'Modellen laden…';

  @override
  String get loadingProviders => 'Providers laden…';

  @override
  String get logLevel => 'Logniveau';

  @override
  String get logs => 'Logboeken';

  @override
  String get low => 'Laag';

  @override
  String get maintenance => 'Onderhoud';

  @override
  String get manageParticipants => 'Deelnemers beheren';

  @override
  String get manageWorkspaces => 'Werkruimtes beheren';

  @override
  String get reorderWorkspace => 'Werkruimte herordenen';

  @override
  String get matchOsAppearance =>
      'Pas het uiterlijk aan aan je OS of kies een vaste modus.';

  @override
  String get mcpAuthToken => 'MCP-authenticatietoken';

  @override
  String get mcpNotAvailableOnServer =>
      'MCP-serverbeheer is niet beschikbaar op de verbonden server.';

  @override
  String get modelManagedOnServer =>
      'Dit model draait op de serverhost en wordt daar beheerd.';

  @override
  String get mcpServer => 'MCP-server';

  @override
  String get medium => 'Middel';

  @override
  String get memoryDataHint =>
      'Feiten en beleidsregels verschijnen hier terwijl agenten werken.';

  @override
  String get memoryLabel => 'GEHEUGEN';

  @override
  String get merge => 'Merge';

  @override
  String get merged => 'Samengevoegd';

  @override
  String get messagePlaceholder =>
      'Bericht… (@ om te noemen, / voor commando\'s)';

  @override
  String get navConversations => 'Ruimtes';

  @override
  String get microphonePermissionDenied => 'Microfoontoestemming geweigerd.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuten geleden',
      one: '1 minuut geleden',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'Model';

  @override
  String get modified => 'Gewijzigd';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count maanden geleden',
      one: '1 maand geleden',
    );
    return '$_temp0';
  }

  @override
  String get moreLabel => 'Meer';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'Naam';

  @override
  String get nameAndTitleRequired => 'Naam en titel zijn vereist.';

  @override
  String get nameAndUrlRequired => 'Naam en URL zijn vereist';

  @override
  String get nameLabel => 'Naam';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'Native sandbox is beschikbaar op $platform.';
  }

  @override
  String get nativeSandboxNeedsInstall =>
      'Installatie vereist voor native sandbox';

  @override
  String get navObservability => 'Observeerbaarheid';

  @override
  String get navSettings => 'Instellingen';

  @override
  String get navigateLabel => 'Navigeren';

  @override
  String networkBlockCount(int count) {
    return '$count netwerkblokkades';
  }

  @override
  String get neutral => 'Neutraal';

  @override
  String get newCommitsPushed =>
      'Nieuwe commits zijn gepusht — klik om de diff opnieuw te laden';

  @override
  String get newFact => 'Nieuw feit';

  @override
  String get newLabel => 'Nieuw';

  @override
  String get newPolicy => 'Nieuwe beleidsregel';

  @override
  String get newsfeed => 'Nieuwsfeed';

  @override
  String get newsfeedLabel => 'Nieuwsfeed';

  @override
  String get newsfeedSettingsDescription =>
      'Beheer je geabonneerde feeds en lezersvoorkeuren.';

  @override
  String get newsfeedSettingsTitle => 'Nieuwsfeed-instellingen';

  @override
  String get nextMatch => 'Volgende overeenkomst (↵)';

  @override
  String get noActiveWorkspace =>
      'Geen actieve werkruimte of repository geselecteerd.';

  @override
  String get noActiveWorkspaceCreate => 'Geen actieve werkruimte';

  @override
  String get noActiveWorkspaceGithub =>
      'Geen actieve werkruimte met een GitHub-repository.';

  @override
  String get noAgents => 'Geen agenten';

  @override
  String get noArticlesYet => 'Nog geen artikelen';

  @override
  String get noArticlesYetBody => 'De artikelen van je feeds verschijnen hier.';

  @override
  String get noExecutionLogsYet => 'Nog geen uitvoeringslogboeken';

  @override
  String get noFacts => 'Nog geen feiten';

  @override
  String get noFeedsYet => 'Nog geen feeds';

  @override
  String get noFileAnchor =>
      'Geen bestandsanker — kan geen inline-reactie plaatsen.';

  @override
  String get noFileChangesInScope => 'Geen bestandswijzigingen in dit bereik';

  @override
  String get noGifsFound => 'Geen GIFs gevonden';

  @override
  String get noInputDevicesDetected =>
      'Geen invoerapparaten gedetecteerd — systeemstandaard wordt gebruikt.';

  @override
  String get noMatchingFiles => 'Geen overeenkomende bestanden';

  @override
  String get noMatchingGoogleFonts => 'Geen overeenkomstige Google Fonts.';

  @override
  String get noMemoryData => 'Nog geen geheugengegevens';

  @override
  String get noMessagesYet => 'Nog geen berichten';

  @override
  String get noModelsAdvertised =>
      'Geen modellen aangeboden door deze adapter.';

  @override
  String get noOpenPullRequests => 'Geen open pull requests';

  @override
  String get noPolicies => 'Nog geen beleidsregels';

  @override
  String get noReposInWorkspaceYet =>
      'Nog geen repository\'s in deze werkruimte';

  @override
  String get noRunnersDetected =>
      'Nog geen runners gedetecteerd. Vernieuw om opnieuw te scannen.';

  @override
  String get noSavedArticles => 'Nog geen opgeslagen artikelen';

  @override
  String get noSavedArticlesBody =>
      'De artikelen die je opslaat verschijnen hier.';

  @override
  String noShortcutsMatch(String query) {
    return 'Geen sneltoetsen komen overeen met \\\"$query\\\"';
  }

  @override
  String get noSystemFonts => 'Geen systeemlettertypen gedetecteerd.';

  @override
  String get noTokenSet => 'Geen token ingesteld — toegang is onbeperkt.';

  @override
  String get noWorkingMemory => 'Nog geen werkgeheugennotities.';

  @override
  String get noneAllRoles => 'Geen (alle rollen)';

  @override
  String get notAvailable => 'Niet beschikbaar';

  @override
  String get notConfiguredLabel => 'Niet geconfigureerd.';

  @override
  String get notDetected => 'Niet gedetecteerd';

  @override
  String get notFoundLabel => 'Niet gevonden';

  @override
  String get notes => 'Notities';

  @override
  String get notificationAgentFinished => 'Agent voltooid';

  @override
  String get notificationPrMentioned => 'Vermeld in een pull request';

  @override
  String get notificationNewMessages => 'Nieuwe berichten';

  @override
  String get notificationPrMerged => 'PR samengevoegd';

  @override
  String get notificationPrPublished => 'PR gepubliceerd';

  @override
  String get notificationReviewRequested => 'Review aangevraagd';

  @override
  String get notifications => 'Meldingen';

  @override
  String get notifyAgentRunCompleted =>
      'Melding wanneer een agent een run voltooit.';

  @override
  String get notifyPrMentioned =>
      'Melding wanneer je wordt vermeld in een pull request.';

  @override
  String get notifyNewMessages =>
      'Melding bij nieuwe agent-berichten in andere ruimtes.';

  @override
  String get notifyPrMerged =>
      'Melding wanneer een pull request wordt samengevoegd.';

  @override
  String get notifyPrPublished =>
      'Melding wanneer een agent een pull request publiceert.';

  @override
  String get notifyReviewRequested =>
      'Melden wanneer je review wordt gevraagd voor een pull request.';

  @override
  String get notificationReviewStale => 'Review verouderd';

  @override
  String get notifyReviewStale =>
      'Wanneer er nieuwe commits landen op een al gereviewde pull request';

  @override
  String get notificationPrMergeReadiness => 'Klaar om te mergen';

  @override
  String get notifyPrMergeReadiness =>
      'Melden wanneer een pull request van jou mergebaar wordt, of dat niet meer is.';

  @override
  String get notificationPrReviewDecision => 'Reviewbeslissingen';

  @override
  String get notifyPrReviewDecision =>
      'Melden wanneer iemand goedkeurt, wijzigingen vraagt of een goedkeuring vervalt.';

  @override
  String get notificationPrChecksStatus => 'Controles';

  @override
  String get notifyPrChecksStatus =>
      'Melden wanneer CI faalt op een pull request van jou, en wanneer die weer groen wordt.';

  @override
  String get notificationPrThreadActivity => 'Reviewdraden';

  @override
  String get notifyPrThreadActivity =>
      'Melden wanneer iemand reageert in of een draad sluit waarin je zit.';

  @override
  String get notificationPrReadyToMerge => 'Klaar om te mergen';

  @override
  String notificationPrReadyToMergeBody(String prTitle) {
    return '$prTitle voldoet aan alles.';
  }

  @override
  String get notificationPrMergeBlocked => 'Niet meer mergebaar';

  @override
  String notificationPrMergeBlockedBodyConflicts(String prTitle) {
    return '$prTitle conflicteert met de basisbranch.';
  }

  @override
  String notificationPrMergeBlockedBodyBehind(String prTitle) {
    return '$prTitle loopt achter op de basisbranch.';
  }

  @override
  String notificationPrMergeBlockedBodyReviews(String prTitle) {
    return '$prTitle wacht op een verplichte review.';
  }

  @override
  String notificationPrMergeBlockedBodyChanges(String prTitle) {
    return 'Iemand vroeg wijzigingen op $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyChecks(String prTitle) {
    return 'Controles falen op $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyOther(String prTitle) {
    return '$prTitle kan niet meer gemerged worden.';
  }

  @override
  String get notificationPrApproved => 'Pull request goedgekeurd';

  @override
  String notificationPrApprovedBodyBy(String login, String prTitle) {
    return '$login keurde $prTitle goed';
  }

  @override
  String notificationPrApprovedBody(String prTitle) {
    return '$prTitle is goedgekeurd';
  }

  @override
  String notificationPrReviewersRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviewers moeten nog reageren',
      one: '1 reviewer moet nog reageren',
      zero: 'geen reviewers meer',
    );
    return '$_temp0';
  }

  @override
  String get notificationPrChangesRequested => 'Wijzigingen gevraagd';

  @override
  String notificationPrChangesRequestedBodyBy(String login, String prTitle) {
    return '$login vroeg wijzigingen op $prTitle';
  }

  @override
  String notificationPrChangesRequestedBody(String prTitle) {
    return 'Er zijn wijzigingen gevraagd op $prTitle';
  }

  @override
  String get notificationPrReviewDismissed => 'Goedkeuring vervallen';

  @override
  String notificationPrReviewDismissedBody(String prTitle) {
    return '$prTitle moet opnieuw beoordeeld worden.';
  }

  @override
  String get notificationPrChecksFailed => 'Controles mislukt';

  @override
  String notificationPrChecksFailedBody(String checkName, String prTitle) {
    return '$checkName faalde op $prTitle';
  }

  @override
  String notificationPrChecksFailedBodyUnnamed(String prTitle) {
    return 'Controles falen op $prTitle';
  }

  @override
  String get notificationPrChecksRecovered => 'Controles geslaagd';

  @override
  String notificationPrChecksRecoveredBody(String prTitle) {
    return '$prTitle is weer groen.';
  }

  @override
  String notificationPrMentionedInCommentBody(String login, String location) {
    return '$login noemde je in $location';
  }

  @override
  String get notificationPrThreadReplied => 'Nieuwe reactie';

  @override
  String notificationPrThreadRepliedBody(String login, String location) {
    return '$login reageerde in $location';
  }

  @override
  String get notificationPrThreadResolved => 'Draad opgelost';

  @override
  String notificationPrThreadResolvedBody(String location) {
    return 'Je draad in $location is opgelost.';
  }

  @override
  String get notificationGroupAgents => 'Agents';

  @override
  String get notificationGroupPullRequests => 'Pull requests';

  @override
  String get notificationGroupMessages => 'Berichten';

  @override
  String get notificationGroupTickets => 'Tickets';

  @override
  String get notificationGroupCalendar => 'Agenda';

  @override
  String get notificationGroupMachines => 'Machines';

  @override
  String get notificationsMutedRepos => 'Gedempte repositories';

  @override
  String notificationsMutedReposCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repositories gedempt',
      one: '1 repository gedempt',
      zero: 'Geen repositories gedempt',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMuteRepo => 'Deze repository dempen';

  @override
  String get notificationsUnmuteRepo => 'Demping opheffen';

  @override
  String get onboardingLinuxDescription =>
      'Control Center kan Linux-containers gebruiken om de uitvoering van agenten te isoleren.';

  @override
  String get onboardingMacosDescription =>
      'Control Center gebruikt native sandbox op macOS om de uitvoering van agenten te isoleren.';

  @override
  String get onboardingUnsupportedDescription =>
      'Sandbox is niet beschikbaar op dit platform. De uitvoering van agenten zal zonder isolatie plaatsvinden.';

  @override
  String get openApplicationSettings => 'Toepassingsinstellingen openen';

  @override
  String get openArticlesInApp => 'Artikelen in app openen';

  @override
  String get openInBrowser => 'Openen in browser';

  @override
  String get openLabel => 'Open';

  @override
  String get openOnGithub => 'Openen op GitHub';

  @override
  String get openStatus => 'Open';

  @override
  String get optionalPersonaDescription => 'Optionele persona-beschrijving';

  @override
  String get otherLabel => 'Overig';

  @override
  String get ownerOrganization => 'Eigenaar / Organisatie';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get passed => 'Geslaagd';

  @override
  String get pasteValueHere => 'Waarde hier plakken';

  @override
  String get persona => 'Persona';

  @override
  String get policies => 'Beleidsregels';

  @override
  String get policiesHint =>
      'Beleidsregels verschijnen hier zodra agenten feiten promoveren.';

  @override
  String get policy => 'Beleidsregel';

  @override
  String get popular => 'Populair';

  @override
  String get port => 'Poort';

  @override
  String get postingEllipsis => 'Publiceren…';

  @override
  String get prCommits => 'Commits';

  @override
  String get prMergedBody => 'Een pull request is samengevoegd';

  @override
  String get prMoreActions => 'More actions';

  @override
  String get prTitle => 'PR-titel';

  @override
  String get reviewCommentHint =>
      'Klik gewoon op goedkeuren, of voeg als je zin hebt een reactie of emoji toe…';

  @override
  String get nothingToPreview => 'Niets om te previewen';

  @override
  String get previousMatch => 'Vorige overeenkomst (⇧↵)';

  @override
  String get priorityReviewsDescription =>
      'Prioriteitsreviews en overzicht van repository\'s.';

  @override
  String get prsCreated => 'PR\'s aangemaakt';

  @override
  String get prsMerged => 'PR\'s samengevoegd';

  @override
  String get publishToGithub => 'Publiceren naar GitHub';

  @override
  String get published => 'Gepubliceerd';

  @override
  String get pullRequestApproved => 'Pull request goedgekeurd';

  @override
  String get pullRequests => 'Pull requests';

  @override
  String get questionLabel => 'VRAAG';

  @override
  String get queued => 'In wachtrij';

  @override
  String get react => 'Reageren';

  @override
  String get readPrsIssuesMetadata =>
      'Stelt de agent in staat PR\'s, issues en repository-metadata te lezen.';

  @override
  String get readerPreferences => 'Lezersvoorkeuren';

  @override
  String get reasoningEffort => 'Reasoning-inspanning';

  @override
  String get recommendLabel => 'AANBEVELEN';

  @override
  String recordingFromDevice(String device) {
    return 'Opname van $device.';
  }

  @override
  String get redownload => 'Opnieuw downloaden';

  @override
  String get redownloadEmbeddingModel => 'Embedding-model opnieuw downloaden?';

  @override
  String get redownloadVoiceModel => 'Spraakmodel opnieuw downloaden?';

  @override
  String get refinePlan => 'Plan verfijnen';

  @override
  String get refresh => 'Vernieuwen';

  @override
  String get refreshAll => 'Alles vernieuwen';

  @override
  String get refreshAllFeeds => 'Alle feeds vernieuwen';

  @override
  String get reject => 'Afwijzen';

  @override
  String get rejected => 'Afgewezen';

  @override
  String get reload => 'Herladen';

  @override
  String get remove => 'Verwijderen';

  @override
  String get removeBookmark => 'Bladwijzer verwijderen';

  @override
  String get removeEmbeddingModel => 'Embedding-model verwijderen?';

  @override
  String get removeLogo => 'Logo verwijderen';

  @override
  String get removeRepoFromWorkspace =>
      'Repository uit werkruimte verwijderen?';

  @override
  String get removeVoiceModel => 'Spraakmodel verwijderen?';

  @override
  String get removed => 'Verwijderd';

  @override
  String get renamed => 'Hernoemd';

  @override
  String get reopen => 'Heropenen';

  @override
  String get resolve => 'Oplossen';

  @override
  String get replyEllipsis => 'Beantwoorden…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$name wordt verwijderd uit deze werkruimte. De lokale bestanden op schijf worden niet aangeraakt.';
  }

  @override
  String repoAccessNoticeBody(String repos) {
    return 'De GitHub-inloggegevens van de server kunnen $repos niet zien. Als een repository bij een organisatie hoort, installeer daar de GitHub App of koppel een token met toegang.';
  }

  @override
  String repoAccessNoticeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repositories zijn niet toegankelijk',
      one: 'Eén repository is niet toegankelijk',
    );
    return '$_temp0';
  }

  @override
  String get repoNoAccessBadge => 'Geen toegang';

  @override
  String get reportsTo => 'Rapporteert aan';

  @override
  String reposCount(int count) {
    return 'Repository\'s ($count)';
  }

  @override
  String get reposDescription =>
      'De lokale checkouts waar deze werkruimte op gericht is.';

  @override
  String get repositories => 'Repository\'s';

  @override
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repository\'s',
      one: '1 repository',
    );
    return 'Kon $_temp0 niet toevoegen: $error';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repository\'s toegevoegd',
      one: 'Repository toegevoegd',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => 'Repository-instellingen';

  @override
  String get repositoryName => 'Repository-naam';

  @override
  String get requestChanges => 'Wijzigingen aanvragen';

  @override
  String get requested => 'Aangevraagd';

  @override
  String get requestedChanges => 'Wijzigingen aangevraagd';

  @override
  String requiredRoleLabel(String role) {
    return 'Vereiste rol: $role';
  }

  @override
  String get requiredRoleOptional => 'Vereiste rol (optioneel)';

  @override
  String get requirements => 'Vereisten';

  @override
  String get reset => 'Resetten';

  @override
  String get resolved => 'Opgelost';

  @override
  String get enclosedTerminalTitle => 'Afgeschermde terminal';

  @override
  String get enclosedTerminalStart => 'Shell openen';

  @override
  String get enclosedTerminalStartHint =>
      'Deze shell draait in de wegwerp-VM van dit gesprek. Die start wanneer je hem opent, niet bij het starten van de app.';

  @override
  String get terminalStreamReconnecting =>
      'stream onderbroken — opnieuw verbinden…';

  @override
  String get terminalStreamError => 'streamfout:';

  @override
  String get terminalShellExited => 'shell beëindigd';

  @override
  String get restartShell => 'Shell herstarten';

  @override
  String get retry => 'Opnieuw proberen';

  @override
  String get review => 'Review';

  @override
  String get reviewedByMe => 'Door mij gereviewd';

  @override
  String get reviewers => 'REVIEWERS';

  @override
  String get roleLabel => 'Rol';

  @override
  String get ruleHint =>
      'De regel van de beleidsregel (markdown wordt ondersteund)';

  @override
  String get ruleLabel => 'Regel';

  @override
  String get runCompleted => 'Uitvoering voltooid';

  @override
  String get running => 'Actief';

  @override
  String get runningLabel => 'actief';

  @override
  String get runs => 'Runs';

  @override
  String get runsLabel => 'Runs';

  @override
  String get sandboxBackendNativeLabel => 'Native sandbox';

  @override
  String get sandboxBackendMicrovmLabel => 'Afgeschermde VM';

  @override
  String get sandboxBackendNoneLabel => 'No isolation';

  @override
  String get sandboxLinuxInstall =>
      'Native sandbox op Linux/WSL2 gebruikt bubblewrap. Installeer met:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'Native sandbox is ingebouwd in macOS — gebruikt Apple Seatbelt (`sandbox-exec`). Geen installatie vereist.';

  @override
  String get sandboxPermissions => 'Sandbox-machtigingen';

  @override
  String get sandboxUnsupported =>
      'Native sandbox wordt op dit platform nog niet ondersteund. Val terug op \"Geen isolatie\".';

  @override
  String get sandboxingDisabledDescription =>
      'Agenten worden direct op de host uitgevoerd met volledige env — niet aanbevolen.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'Alle agentaanroepen worden gerouteerd via $backend.';
  }

  @override
  String get save => 'Opslaan';

  @override
  String get saveChanges => 'Wijzigingen opslaan';

  @override
  String get adapterArguments => 'Extra argumenten';

  @override
  String get adapterArgumentsHint => 'Extra CLI-vlaggen (bijv. --yolo)';

  @override
  String get addVariable => 'Variabele toevoegen';

  @override
  String get environmentVariables => 'Omgevingsvariabelen';

  @override
  String get environmentVariablesDescription =>
      'Aangepaste omgevingsvariabelen voor deze adapter (bijv. API-sleutels). Opgeslagen in de sleutelhanger.';

  @override
  String get variableKey => 'Sleutel';

  @override
  String get variableValue => 'Waarde';

  @override
  String get savingChanges => 'Wijzigingen opslaan…';

  @override
  String get savingEllipsis => 'Opslaan…';

  @override
  String get scopeDiffToCommits =>
      'Diff beperken tot commits — Shift-klik voor bereik';

  @override
  String get noPrsMatchSearch => 'Geen overeenkomende pull requests';

  @override
  String get noPrsMatchSearchHint =>
      'Geen open PR\'s komen overeen met je zoekopdracht. Probeer andere termen of wis de zoekopdracht.';

  @override
  String get searchFactsHint => 'Feiten zoeken...';

  @override
  String get searchFonts => 'Lettertypen zoeken…';

  @override
  String get searchGifs => 'GIFs zoeken';

  @override
  String get searchGifsHint => 'GIFs zoeken...';

  @override
  String get searchInDiffHint => 'Zoeken in diff…';

  @override
  String get searchOrTypeModel => 'Zoek of typ een modelnaam…';

  @override
  String get searchPlaceholder => 'Zoeken…';

  @override
  String get searchShortcuts => 'Sneltoetsen zoeken…';

  @override
  String get shortcutUnavailableInBrowser => 'Niet beschikbaar in de browser';

  @override
  String get searching => 'Zoeken…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconden geleden',
      one: '1 seconde geleden',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'Adapter selecteren';

  @override
  String get selectAdapterFirst => 'Selecteer eerst een adapter';

  @override
  String get selectAgentToReportTo => 'Selecteer agent om aan te rapporteren…';

  @override
  String get selectAnAgent => 'Een agent selecteren';

  @override
  String get selectConversation => 'Een gesprek selecteren';

  @override
  String get selectEffortLevel => 'Inspanningsniveau selecteren';

  @override
  String get selectLabel => 'Selecteren';

  @override
  String get selectRunner => 'Een runner selecteren';

  @override
  String get semanticSearch => 'Semantisch zoeken';

  @override
  String get send => 'Verzenden';

  @override
  String get sendFirstMessage => 'Verstuur het eerste bericht';

  @override
  String get sendMessage => 'Bericht verzenden';

  @override
  String sentFindingsToAgent(int count) {
    return '$count bevinding(en) naar agent gestuurd.';
  }

  @override
  String setGithubLinkDescription(String name) {
    return 'Stel de GitHub-eigenaar en repository-naam in voor $name. Dit wordt gebruikt om PR- en issue-referenties zoals #123 in markdown-inhoud op te lossen.';
  }

  @override
  String get setLabel => 'Instellen';

  @override
  String get setToken => 'Token instellen';

  @override
  String get settingsLabel => 'Instellingen';

  @override
  String get settingsLanguage => 'Taal';

  @override
  String get settingsLanguageDescription => 'Kies de taal van de app.';

  @override
  String get shortTask => 'Korte taak';

  @override
  String get showNativeNotifications =>
      'Systeemmeldingen van macOS tonen voor gebeurtenissen.';

  @override
  String get showSuperseded => 'Vervangen tonen';

  @override
  String get signedIn => 'Ingelogd.';

  @override
  String signedInAs(String username) {
    return 'Ingelogd als $username.';
  }

  @override
  String get skillEditor => 'Vaardighedeneditor';

  @override
  String get skillNameRequired => 'Vaardigheidsnaam is vereist.';

  @override
  String skillSaved(String name) {
    return 'Vaardigheid \\\"$name\\\" opgeslagen.';
  }

  @override
  String get skillsSourcesTab => 'Bronnen';

  @override
  String get skillSourcesDisclaimer =>
      'Skills worden geïnstalleerd uit GitHub-repository\'s die je toevoegt. Repository-metadata is onbetrouwbaar — de antivirusscan is het echte veiligheidssignaal.';

  @override
  String get skillSourcesEmpty => 'Geen skill-repository\'s';

  @override
  String get skillSourcesEmptyHint =>
      'Voeg een GitHub-repository toe om de skills erin te bekijken.';

  @override
  String get skillSourceAdd => 'Repository toevoegen';

  @override
  String get skillSourceAddTitle => 'Skill-repository toevoegen';

  @override
  String get skillSourceAddHint => 'https://github.com/eigenaar/repo';

  @override
  String get skillSourceInvalidUrl =>
      'Voer een GitHub-repository-URL in (https://github.com/eigenaar/repo).';

  @override
  String skillSourceAdded(String repo) {
    return 'Repository $repo toegevoegd.';
  }

  @override
  String skillSourceAlreadyAdded(String repo) {
    return 'Repository $repo is al toegevoegd.';
  }

  @override
  String skillSourceRemoved(String repo) {
    return 'Repository $repo verwijderd.';
  }

  @override
  String get skillSourceRemove => 'Verwijderen';

  @override
  String skillSourceRemoveConfirmTitle(String repo) {
    return '$repo verwijderen?';
  }

  @override
  String get skillSourceRemoveConfirmBody =>
      'Geïnstalleerde skills blijven geïnstalleerd. Alleen de repositorycatalogus wordt verwijderd.';

  @override
  String get skillSourceNoSkills =>
      'Geen skills gevonden in deze repository (een skill is een map met een SKILL.md).';

  @override
  String get skillSourceRefresh => 'Vernieuwen';

  @override
  String get skillSourceInstalledBadge => 'Geïnstalleerd';

  @override
  String get skillSourceUpdateBadge => 'Update beschikbaar';

  @override
  String get skillSourceSlugTaken => 'Naam in gebruik';

  @override
  String skillSourceFilesCount(num count) {
    return '$count bestanden';
  }

  @override
  String get skillSourceReadme => 'README';

  @override
  String get skillSourceNoReadme => 'Deze skill heeft geen README.';

  @override
  String get skillSourceNoMatches => 'Geen skills matchen je filter.';

  @override
  String get skillUpdateAction => 'Bijwerken';

  @override
  String get skillUninstallAction => 'Verwijderen';

  @override
  String skillUninstallConfirmTitle(String slug) {
    return '\"$slug\" verwijderen?';
  }

  @override
  String skillUninstalled(String slug) {
    return 'Skill \"$slug\" verwijderd.';
  }

  @override
  String get skillFindingLine => 'regel';

  @override
  String get skillInstallAnywayOverride =>
      'Ik begrijp het risico — toch installeren';

  @override
  String skillInstalled(String slug) {
    return 'Vaardigheid \"$slug\" geïnstalleerd.';
  }

  @override
  String get skillPreviewCapabilities => 'Mogelijkheden';

  @override
  String get skillPreviewFindings => 'Bevindingen';

  @override
  String get skillPreviewGuardedActions => 'Beveiligde acties';

  @override
  String get skillPreviewLlmReviewed => 'LLM-beoordeeld';

  @override
  String get skillPreviewNoCapabilities => 'Geen mogelijkheden opgegeven.';

  @override
  String get skillPreviewNoFindings => 'Geen bevindingen.';

  @override
  String get skillPreviewScanning => 'Vaardigheid scannen…';

  @override
  String get skillPreviewVerdictLabel => 'Scanvonnis';

  @override
  String get skillPreviewVerdictPass => 'Geslaagd';

  @override
  String get skillPreviewVerdictQuarantine => 'In quarantaine';

  @override
  String get skillPreviewVerdictWarn => 'Waarschuwing';

  @override
  String get skillQuarantineWarning =>
      'Deze vaardigheid is in quarantaine geplaatst door de scanner. Installeren voert code uit op jouw machine. Ga alleen door als je de bron vertrouwt en de bevindingen hebt beoordeeld.';

  @override
  String skillDetachedFromAgents(String agents) {
    return 'In quarantaine geplaatst en losgemaakt van agenten: $agents';
  }

  @override
  String get skillNotScanned => 'Niet gescand';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => 'Handmatig';

  @override
  String get skillOriginRegistry => 'Registry';

  @override
  String get skillOriginRuntimeLocal => 'Lokale runtime';

  @override
  String get skillRulesStale => 'Scan verouderd';

  @override
  String get skillSaveAnywayOverride => 'Ik begrijp het risico — toch opslaan';

  @override
  String get skillSaveBlockedBody =>
      'De inhoud is geblokkeerd voordat er iets is weggeschreven.';

  @override
  String get skillSaveBlockedTitle => 'Opslaan geblokkeerd door de scan';

  @override
  String get skillScanAction => 'Scannen';

  @override
  String get skillScanAll => 'Alles scannen';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass geslaagd · $warn waarschuwingen · $quarantine in quarantaine';
  }

  @override
  String get skillStateDrifted => 'Gewijzigd sinds installatie';

  @override
  String get skillStateUnmanaged => 'Niet beheerd';

  @override
  String get skillSeverityBlocked => 'Geblokkeerd';

  @override
  String get skillSeverityWarn => 'Waarschuwing';

  @override
  String get skillsInstalledTab => 'Geïnstalleerd';

  @override
  String get skills => 'Vaardigheden';

  @override
  String get skipAcceptRisk => 'Overslaan — Ik accepteer het risico';

  @override
  String get skipForNow => 'Voorlopig overslaan';

  @override
  String get skipSandboxing => 'Sandboxing overslaan';

  @override
  String get skipSandboxingDialogContent =>
      'Weet je zeker dat je sandboxing wilt overslaan? Dit staat agenten toe om code op je systeem uit te voeren zonder isolatie.';

  @override
  String get somethingWentWrong => 'Er is iets misgegaan';

  @override
  String sourceCount(int count) {
    return '$count bron';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count bronnen';
  }

  @override
  String get sourceFacts => 'Bronfeiten:';

  @override
  String get splitDiff => 'Diff naast elkaar';

  @override
  String get startLabel => 'Starten';

  @override
  String get startOnAppLaunch => 'Starten bij app-lancering';

  @override
  String get statusLabel => 'Status';

  @override
  String get onboardingStepConnect => 'Verbinden';

  @override
  String get onboardingStepWorkspace => 'Werkruimte';

  @override
  String get onboardingStepSandbox => 'Sandbox';

  @override
  String get onboardingStepAdapter => 'Adapter';

  @override
  String get onboardingStepVoice => 'Stem';

  @override
  String get stop => 'Stoppen';

  @override
  String get stopped => 'Gestopt';

  @override
  String get strictIdentityCheck => 'Strikte identiteitscontrole';

  @override
  String get success => 'Succes';

  @override
  String get successLabel => 'Succes';

  @override
  String get suggestAChange => 'Wijziging voorstellen';

  @override
  String get suggestLabel => 'SUGGESTIE';

  @override
  String get superseded => 'Vervangen';

  @override
  String get synced => 'Gesynchroniseerd';

  @override
  String get systemDefault => 'Systeemstandaard';

  @override
  String get systemFonts => 'Systeemlettertypen';

  @override
  String get systemPrompt => 'Systeem-prompt';

  @override
  String get systemPromptLabel => 'Systeem-prompt';

  @override
  String get talkToControlCenter => 'Praat met Control Center.';

  @override
  String get taskMentionSection => 'Taak';

  @override
  String get testLabel => 'Testen';

  @override
  String get theme => 'Thema';

  @override
  String get themeDark => 'Donker';

  @override
  String get themeLight => 'Licht';

  @override
  String get themeSystem => 'Systeem';

  @override
  String get thisCannotBeUndone => 'Dit kan niet ongedaan worden gemaakt.';

  @override
  String get ticketLabel => 'TICKET';

  @override
  String get titleLabel => 'Titel';

  @override
  String get todayLabel => 'Vandaag';

  @override
  String get toggleTheme => 'Thema wisselen';

  @override
  String get tokenConfigured =>
      'Geconfigureerd — clients moeten dit token presenteren.';

  @override
  String get topic => 'Onderwerp';

  @override
  String get topicHint => 'bijv. Tech Stack, Design System';

  @override
  String get totalRuns => 'Totaal runs';

  @override
  String trackingParamsCount(int count) {
    return '$count trackingparameters';
  }

  @override
  String get typeCommandOrSearch => 'Typ een commando of zoek…';

  @override
  String get typography => 'Typografie';

  @override
  String get unavailable => 'Niet beschikbaar';

  @override
  String get unifiedDiff => 'Uniforme diff';

  @override
  String get unknownAuthor => 'Onbekend';

  @override
  String get unnamedAgent => 'Naamloze agent';

  @override
  String get updateKey => 'Sleutel bijwerken';

  @override
  String get updateLabel => 'Bijwerken';

  @override
  String get updateToken => 'Token bijwerken';

  @override
  String updatedDaysAgo(int count) {
    return '$count dagen geleden bijgewerkt';
  }

  @override
  String updatedHoursAgo(int count) {
    return '$count uur geleden bijgewerkt';
  }

  @override
  String get updatedJustNow => 'Zojuist bijgewerkt';

  @override
  String updatedMinutesAgo(int count) {
    return '$count minuten geleden bijgewerkt';
  }

  @override
  String get useSandbox => 'Sandbox gebruiken';

  @override
  String get useWorkspaceDefault => 'Werkruimtestandaard gebruiken';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      'Laat leeg om de standaard app User-Agent te gebruiken. Sommige sites blokkeren niet-browser User-Agents.';

  @override
  String get usingSystemDefaultMicrophone =>
      'Standaardmicrofoon van het systeem wordt gebruikt.';

  @override
  String get viewLabel => 'Bekijken';

  @override
  String get viewLogs => 'Logs bekijken';

  @override
  String voiceInstallFailed(String error) {
    return 'Installatie mislukt: $error';
  }

  @override
  String get voiceModelNotInstalled =>
      'Niet geïnstalleerd. Download ~200 MB eenmalig; draait volledig op het apparaat.';

  @override
  String get voiceModelNotInstalledLabel => 'Spraakmodel niet geïnstalleerd.';

  @override
  String get voiceRedownloadBody =>
      'De bestaande modelbestanden worden verwijderd en het ~200 MB-archief opnieuw gedownload. Spraaktranscriptie is niet beschikbaar tot de download is voltooid.';

  @override
  String get voiceRemoveBody =>
      'Spraaktranscriptie wordt uitgeschakeld totdat je het opnieuw installeert. Je kunt het op elk moment opnieuw installeren.';

  @override
  String get voiceTranscription => 'Spraaktranscriptie';

  @override
  String get weakIsolationDescription =>
      'Zwakke isolatie — alleen namespace-grens, geen kernel-grens.';

  @override
  String get whenOffNoDefaultRoute =>
      'Als dit uit staat, start de sandbox zonder een standaardroute.';

  @override
  String get whenOffServerStaysStopped =>
      'Als dit uit staat, blijft de server gestopt totdat je hem start.';

  @override
  String get speechModel => 'Spraakmodel';

  @override
  String get speechModelHint =>
      'Gebruikt voor vergadertranscriptie en de composer-microfoon.';

  @override
  String get voiceModelInstalled =>
      'Geïnstalleerd. Voedt vergadertranscriptie en de microfoonknop in de composer.';

  @override
  String get meetingMicSilentWarning =>
      'Je microfoon staat mogelijk uit — de anderen praten, maar er komt niets binnen.';

  @override
  String get meetingSummaryPrivacyNotice =>
      'Opname en transcriptie blijven op dit apparaat. De samenvatting wordt geschreven door een agent, dus als die een cloudmodel gebruikt, worden je transcript en notities naar die aanbieder gestuurd.';

  @override
  String get meetingTemplates => 'Sjablonen voor vergadernotities';

  @override
  String get meetingTemplatesHint =>
      'Stem de AI-samenvatting af op een soort vergadering. Het actieve sjabloon geldt voor nieuwe en opnieuw uitgevoerde samenvattingen.';

  @override
  String get meetingTemplateActive => 'Actief sjabloon';

  @override
  String get meetingTemplateAdd => 'Sjabloon toevoegen';

  @override
  String get meetingTemplateNewTitle => 'Nieuw sjabloon';

  @override
  String get meetingTemplateEditTitle => 'Sjabloon bewerken';

  @override
  String get meetingTemplateNameLabel => 'Naam';

  @override
  String get meetingTemplateNameHint => 'bijv. Sprintreview';

  @override
  String get meetingTemplateInstructionsLabel => 'Instructies';

  @override
  String get meetingTemplateInstructionsHint =>
      'Hoe moet de AI deze notities structureren en benadrukken?';

  @override
  String get workingMemory => 'Werkgeheugen';

  @override
  String get workspaceName => 'Naam van werkruimte';

  @override
  String get workspaceScopedSkills =>
      'Vaardigheidsbestanden toegewezen aan werkruimte, gekoppeld aan agenten.';

  @override
  String get workspaces => 'Werkruimtes';

  @override
  String get writePrivateNotes =>
      'Schrijf privénotities, observaties, plannen...';

  @override
  String get writeSkillContent =>
      'Schrijf hier je vaardigheidsinhoud (Markdown)…';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jaar geleden',
      one: '1 jaar geleden',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'gisteren';

  @override
  String get focusModeStart => 'Focussessie starten';

  @override
  String get focusModeConfigTitle => 'Focussessie starten';

  @override
  String get focusModeGoalLabel => 'Doel';

  @override
  String get focusModeGoalHint => 'Waar werk je aan?';

  @override
  String get focusModeDurationLabel => 'Duur';

  @override
  String get focusModeBlockNotifications => 'Meldingen blokkeren';

  @override
  String get focusModeStartButton => 'Starten';

  @override
  String get focusModeFloat => 'Naar balk minimaliseren';

  @override
  String get focusModeActiveTooltip =>
      'Focusmodus actief — tik om te beëindigen';

  @override
  String get dismiss => 'Afwijzen';

  @override
  String get acceptAndResolve => 'Accepteren en oplossen';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'Het lijkt erop dat je veel reviews achter elkaar doet. Neem even pauze!';
  }

  @override
  String get notificationSound => 'Meldingsgeluid';

  @override
  String get notificationSoundDescription =>
      'Geluid dat wordt afgespeeld wanneer een melding wordt weergegeven.';

  @override
  String get notificationSoundNone => 'Geen';

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
  String get notificationVolume => 'Volume';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'Geen PRs van @$login in deze werkruimte';
  }

  @override
  String get usersLabel => 'Gebruikers';

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
  String get stackedPullRequests => 'Gestapelde pull requests';

  @override
  String partOfStack(int position, int total) {
    return 'Onderdeel van een stack ($position van $total)';
  }

  @override
  String get createStack => 'Stack maken';

  @override
  String get createStackDialogTitle => 'Pull-request-stack maken';

  @override
  String createStackDialogBody(int count) {
    return 'Deze $count pull requests worden gestapeld, van onder naar boven:';
  }

  @override
  String get createStackInvalidSelection =>
      'Selecteer minstens twee pull requests uit dezelfde repository om een stack te maken';

  @override
  String get createStackNotAChain =>
      'De geselecteerde pull requests vormen geen keten: de basisbranch van elke PR moet de head-branch van de vorige zijn';

  @override
  String get createStackAlreadyStacked =>
      'Een of meer geselecteerde pull requests zitten al in een stack';

  @override
  String get stackCreated => 'Stack gemaakt';

  @override
  String get stackCreationFailed => 'De stack kon niet worden gemaakt';

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
  String get markReadyForReview => 'Klaar voor review';

  @override
  String get markReadyForReviewConfirm =>
      'Deze pull request verlaat de conceptstatus. Reviewers krijgen een melding, vereiste checks gaan de merge bewaken en elke automatisering die op gereede pull requests wacht, start.';

  @override
  String get convertToDraft => 'Omzetten naar concept';

  @override
  String get convertToDraftConfirm =>
      'Deze pull request wordt weer een concept. De openstaande reviewverzoeken worden ingetrokken en hij kan niet worden samengevoegd totdat je hem opnieuw als klaar markeert.';

  @override
  String get pullRequestMarkedReady =>
      'Pull request gemarkeerd als klaar voor review';

  @override
  String get pullRequestConvertedToDraft => 'Pull request omgezet naar concept';

  @override
  String failedToMarkPrReady(String error) {
    return 'Markeren als klaar voor review mislukt: $error';
  }

  @override
  String failedToConvertPrToDraft(String error) {
    return 'Omzetten naar concept mislukt: $error';
  }

  @override
  String get checksFailing => 'Controles mislukt';

  @override
  String get reviewsPending => 'Some reviews are pending';

  @override
  String get mergeConflictsWithBase =>
      'Deze branch heeft conflicten die opgelost moeten worden';

  @override
  String get branchOutOfDateWithBase =>
      'Deze branch loopt achter op de basisbranch';

  @override
  String get mergeBlockedByBranchProtection =>
      'Branchbeveiliging blokkeert deze merge';

  @override
  String get confirm => 'Confirm';

  @override
  String get trustedSitesSectionTitle => 'Vertrouwde sites';

  @override
  String get trustedSitesEmpty =>
      'Geen vertrouwde sites. Voeg een domein toe om blokkeren daar uit te schakelen.';

  @override
  String get addTrustedSite => 'Vertrouwde site toevoegen';

  @override
  String get removeTrustedSite => 'Verwijderen';

  @override
  String get disableBlockingForThisSite =>
      'Blokkeren uitschakelen op deze site';

  @override
  String get enableBlockingForThisSite => 'Blokkeren inschakelen op deze site';

  @override
  String get enterDomainHint => 'bijv. voorbeeld.com';

  @override
  String get invalidDomain => 'Voer een geldig domein in (bijv. voorbeeld.com)';

  @override
  String get pageLoadTimedOut =>
      'Pagina laden duurde te lang. Herlaad of open in browser.';

  @override
  String get pipelinesScreenTitle => 'Pipelines';

  @override
  String get pipelinesScreenSubtitle =>
      'Declarative multi-step agent workflows';

  @override
  String get pipelinesRunPipeline => 'Pipeline uitvoeren';

  @override
  String get pipelineRunLauncherTitle => 'Pipeline uitvoeren';

  @override
  String get pipelineRunSubtitle =>
      'Kies een pipeline en vul de invoer in om een uitvoering te starten.';

  @override
  String get pipelineRunNoInputsBadge => 'Geen invoer';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invoervelden',
      one: '1 invoerveld',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'Deze pipeline heeft geen invoer nodig.';

  @override
  String get pipelineRunSubmit => 'Pipeline uitvoeren';

  @override
  String get pipelineRunCouldNotStart => 'Kan de uitvoering niet starten.';

  @override
  String pipelineRunStarted(String name) {
    return '$name gestart';
  }

  @override
  String get pipelineRunEmptyTitle => 'Geen pipelines klaar om uit te voeren';

  @override
  String get pipelineRunEmptyHint =>
      'Schakel een pipeline in en zet handmatige uitvoering aan in de editor om deze hier te starten.';

  @override
  String get pipelineRunManageTemplates => 'Pipelines beheren';

  @override
  String get pipelineRunSettingsTitle => 'Handmatige uitvoering';

  @override
  String get pipelineRunSettingsAllow => 'Handmatige uitvoering toestaan';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'Toon deze pipeline op de uitvoeringspagina zodat deze handmatig gestart kan worden.';

  @override
  String get pipelineRunSettingsConcurrencyTitle => 'Gelijktijdigheid';

  @override
  String get pipelineRunSettingsMaxParallel => 'Max. parallelle runs';

  @override
  String get pipelineRunSettingsMaxParallelHelp =>
      'Laat leeg voor onbeperkt. Extra runs wachten in een wachtrij en starten zodra er ruimte vrijkomt.';

  @override
  String get pipelineRunSettingsMaxParallelHint => 'Onbeperkt';

  @override
  String get pipelineRunSettingsMaxParallelInvalid =>
      'Voer een geheel getal van 1 of hoger in, of laat leeg voor onbeperkt.';

  @override
  String get pipelineRunSettingsInputsTitle => 'Invoer';

  @override
  String get pipelineRunSettingsAddInput => 'Invoer toevoegen';

  @override
  String get pipelineRunSettingsNoInputs => 'Nog geen invoer.';

  @override
  String get pipelineInputEditTitle => 'Invoerveld';

  @override
  String get pipelineInputKeyLabel => 'Sleutel';

  @override
  String get pipelineInputKeyHelp =>
      'Statussleutel waaronder de waarde wordt opgeslagen (bijv. repo_full_name).';

  @override
  String get pipelineInputLabelLabel => 'Label';

  @override
  String get pipelineInputTypeLabel => 'Type';

  @override
  String get pipelineInputOptionsLabel => 'Opties (door komma\'s gescheiden)';

  @override
  String get pipelineInputDefaultLabel => 'Standaardwaarde';

  @override
  String get pipelineInputPlaceholderLabel => 'Tijdelijke aanduiding';

  @override
  String get pipelineInputHelpLabel => 'Helptekst';

  @override
  String get pipelineInputRequiredLabel => 'Verplicht';

  @override
  String get pipelineInputTypeText => 'Tekst';

  @override
  String get pipelineInputTypeMultiline => 'Tekst met meerdere regels';

  @override
  String get pipelineInputTypeNumber => 'Getal';

  @override
  String get pipelineInputTypeBoolean => 'Schakelaar';

  @override
  String get pipelineInputTypeSelect => 'Selectie';

  @override
  String get pipelinesEmpty => 'No pipeline runs yet';

  @override
  String get pipelinesEmptyHint =>
      'Klik op \'Pipeline uitvoeren\' om er een te starten.';

  @override
  String get pipelinesNoSteps => 'No steps recorded yet';

  @override
  String get pipelinesNoActiveWorkspace =>
      'Selecteer een werkruimte om de pipelines te bekijken';

  @override
  String pipelinesLoadError(String error) {
    return 'Pipelines konden niet worden geladen: $error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'Pipeline kon niet worden gestart: $error';
  }

  @override
  String get pipelineStatusPending => 'Pending';

  @override
  String get pipelineStatusQueued => 'In wachtrij';

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
    return '$completed van $total stappen';
  }

  @override
  String get pipelineWaterfallTimeline => 'Tijdlijn';

  @override
  String pipelineWaterfallActive(String duration) {
    return 'Actief $duration';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return 'inactief $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip =>
      'Tijd die niet meetelt in het actieve totaal: de run was gestopt of wachtte tussen stappen.';

  @override
  String get pipelineStepStarted => 'Gestart';

  @override
  String get pipelineStepFinished => 'Voltooid';

  @override
  String get pipelineStepDurationLabel => 'Duur';

  @override
  String get pipelineStepBranch => 'Tak';

  @override
  String get pipelineStepViewConversation => 'Gesprek tonen';

  @override
  String get pipelineStepError => 'Fout';

  @override
  String get pipelineStepInput => 'Invoer';

  @override
  String get pipelineStepOutput => 'Uitvoer';

  @override
  String get pipelineStepNotExecuted => 'Nog niet uitgevoerd';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'Mislukt bij $step';
  }

  @override
  String get pipelineRunTriggerManual => 'Handmatig';

  @override
  String get pipelineStepSkippedReason => 'Overgeslagen';

  @override
  String get pipelineStepPriorAttempts => 'Vorige pogingen';

  @override
  String get pipelineStepAttemptLabel => 'Poging';

  @override
  String pipelineStepAttemptN(int number) {
    return 'Poging $number';
  }

  @override
  String get pipelineStepAttemptInterrupted => 'Onderbroken';

  @override
  String get pipelineRunColumnPipeline => 'Pipeline';

  @override
  String get pipelineRunColumnDuration => 'Duur';

  @override
  String get pipelineRunQueueNext => 'Volgende';

  @override
  String pipelineRunQueuePosition(int position) {
    return '${position}e in wachtrij';
  }

  @override
  String get pipelineRunColumnStarted => 'Gestart';

  @override
  String get pipelineRunHistory => 'Uitvoeringsgeschiedenis';

  @override
  String get pipelineRunHistoryEmpty => 'Nog geen andere uitvoeringen';

  @override
  String pipelineRunRerunAgo(String time) {
    return 'Opnieuw uitgevoerd $time';
  }

  @override
  String pipelineRunAttempt(int number) {
    return 'Poging $number';
  }

  @override
  String pipelineRunFirstStarted(String time) {
    return 'eerste start $time';
  }

  @override
  String get pipelineRunFilterAll => 'Alle';

  @override
  String get pipelineRunFilterEmpty => 'Geen runs komen overeen met dit filter';

  @override
  String get relativeJustNow => 'zojuist';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min geleden',
      one: '1 min geleden',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uur geleden',
      one: '1 uur geleden',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagen geleden',
      one: '1 dag geleden',
    );
    return '$_temp0';
  }

  @override
  String get teamsTitle => 'Teams';

  @override
  String get teamsAddTeam => 'Add team';

  @override
  String get teamsLoadError => 'Kon teams niet laden';

  @override
  String get teamsEmptyTitle => 'Nog geen teams';

  @override
  String get teamsEmptyDescription =>
      'Groepeer agents in teams zodat werk dat aan een team wordt toegewezen via een leider loopt die delegeert.';

  @override
  String get teamCreateTitle => 'Nieuw team';

  @override
  String get teamEditTitle => 'Team bewerken';

  @override
  String get teamNameLabel => 'Teamnaam';

  @override
  String get teamNameHint => 'bijv. Frontend';

  @override
  String get teamDescriptionLabel => 'Beschrijving';

  @override
  String get teamDescriptionHint => 'Waar dit team verantwoordelijk voor is';

  @override
  String get teamLeaderLabel => 'Leider';

  @override
  String get teamLeaderHelp =>
      'De coördinator die aan het team toegewezen werk ontvangt en delegeert aan het best passende lid.';

  @override
  String get teamNoLeader => 'Geen leider';

  @override
  String get teamInstructionsLabel => 'Werkinstructies';

  @override
  String get teamInstructionsHelp =>
      'Toegevoegd aan de briefing van de leider — teamconventies, escalatieregels, toon.';

  @override
  String get teamInstructionsHint => 'Optioneel';

  @override
  String get teamSaved => 'Team opgeslagen';

  @override
  String get teamMembersError => 'Kon leden niet laden';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count leden',
      one: '1 lid',
      zero: 'Geen leden',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => 'Lid toevoegen';

  @override
  String get teamAddMemberTitle => 'Leden toevoegen';

  @override
  String teamAddMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count toevoegen',
      one: '1 toevoegen',
      zero: 'Toevoegen',
    );
    return '$_temp0';
  }

  @override
  String get teamNoAgentsToAdd => 'Elke agent zit al in dit team.';

  @override
  String get teamRemoveMember => 'Verwijderen uit team';

  @override
  String get teamLeaderBadge => 'Leider';

  @override
  String get teamUnknownAgent => 'Onbekende agent';

  @override
  String get teamMembersEmpty => 'Nog geen leden';

  @override
  String get teamMembersEmptyDescription =>
      'Voeg agents toe zodat de leider mensen heeft om aan te delegeren.';

  @override
  String get teamSelectPrompt => 'Selecteer een team';

  @override
  String get teamSelectPromptDescription =>
      'Kies een team uit de lijst of maak een nieuw team aan.';

  @override
  String get teamDeleteTitle => 'Team verwijderen?';

  @override
  String teamDeleteBody(String name) {
    return '$name wordt verwijderd. De bijbehorende agents worden niet beïnvloed.';
  }

  @override
  String get teamHasLeaderTooltip => 'Heeft een leider';

  @override
  String get pipelineTemplatesNav => 'Pipelinesjablonen';

  @override
  String get pipelineTemplatesTitle => 'Pipeline-templates';

  @override
  String get pipelineTemplatesSubtitle =>
      'Drag-and-drop-editor voor de pipelines die je agents orkestreren.';

  @override
  String get pipelineTemplatesNew => 'Nieuwe template';

  @override
  String get pipelineTemplatesEmpty =>
      'Nog geen pipeline-templates. Maak er een om te beginnen.';

  @override
  String get pipelineTemplateIdLabel => 'Template-ID';

  @override
  String get pipelineTemplateBuiltInBadge => 'Ingebouwd';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'Template verwijderen?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'Pipeline-template $name verwijderen? Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String get pipelineTemplateEditorTitle => 'Pipeline bewerken';

  @override
  String get pipelineTemplateEditorSubtitle =>
      'Sleep node-types vanuit de zijbalk naar het canvas en verbind ze.';

  @override
  String get unsavedChanges => 'Niet-opgeslagen wijzigingen';

  @override
  String get nodeLibraryTitle => 'Node-bibliotheek';

  @override
  String get nodeLibraryHint =>
      'Sleep een item naar het canvas om een node toe te voegen.';

  @override
  String get editorDragHint =>
      'Sleep vanuit de bibliotheek, klik een node om te bewerken';

  @override
  String get editorEmptyCanvas =>
      'Sleep een node vanuit de bibliotheek om te beginnen.';

  @override
  String get nodeConfigTitle => 'Node-configuratie';

  @override
  String get nodeConfigKind => 'Type';

  @override
  String get nodeConfigLabel => 'Label';

  @override
  String get nodeConfigAgent => 'Agent';

  @override
  String get nodeConfigAgentHint => 'Kies een agent…';

  @override
  String get nodeConfigInputKeys => 'Invoersleutels (door komma\'s gescheiden)';

  @override
  String get nodeConfigInputKeysHelp =>
      'State-sleutels die deze node gebruikt. Gebruikt voor placeholder-substitutie in de prompt.';

  @override
  String get nodeConfigRepos => 'Te klonen repositories';

  @override
  String get nodeConfigReposHelp =>
      'Repositories die worden gekloond en geïndexeerd wanneer deze node zijn conversatie start. Alles selecteren kloont ze allemaal (de standaard).';

  @override
  String get nodeConfigRepoBranchHint => 'Branch (standaard)';

  @override
  String get nodeConfigRepoBranchHelp =>
      'De branch waarvan elke kopie wordt afgetakt. Laat leeg voor de standaardbranch van de repo — de werkkopie krijgt een eigen branch, dus niets wat een agent commit belandt op deze.';

  @override
  String nodeConfigReposDynamic(String entries) {
    return 'Dynamische items behouden: $entries';
  }

  @override
  String get nodeConfigCreateConversation => 'Er een gesprek in openen';

  @override
  String get nodeConfigCreateConversationHelp =>
      'Laat dit uit wanneer er meerdere agentknooppunten volgen — elk opent zijn eigen benoemde stroom. Zet het aan wanneer er één agentknooppunt volgt, zodat de ruimte er nooit een gesprek zonder titel naast toont.';

  @override
  String get nodeConfigConversationTitle => 'Naam van het gesprek';

  @override
  String get nodeConfigConversationTitleHelp =>
      'Geef het agentknooppunt stroomafwaarts dezelfde naam en beide werken in één stroom. Standaard het label van het knooppunt.';

  @override
  String get nodeConfigSpaceName => 'Naam van de ruimte';

  @override
  String get nodeConfigSpaceNameHelp =>
      'Hoe de ruimte heet die deze node opent. Ondersteunt dezelfde statusplaatshouders als een prompt. Laat leeg om het label van de node te gebruiken.';

  @override
  String get nodeConfigSpaceNameHint => 'Beoordeling van pr_number';

  @override
  String get nodeConfigStreamTitle => 'Naam van het gesprek';

  @override
  String get nodeConfigStreamTitleHelp =>
      'De benoemde stroom waarin de agent van deze node in de ruimte werkt. Ondersteunt dezelfde statusplaatshouders als een prompt. Blijft dit leeg, dan belandt de beurt in het vaste gesprek van de ruimte, waar een fan-out elke agent door elkaar weeft.';

  @override
  String get nodeConfigConversationTitleHint => 'Architectuuranalyse';

  @override
  String get nodeConfigOutputKey => 'Uitvoersleutel';

  @override
  String get nodeConfigPrompt => 'Prompt-template';

  @override
  String get nodeConfigPromptHelp =>
      'Gebruik placeholders met dubbele accolades om waarden uit de state in te voegen op runtime.';

  @override
  String get nodeConfigScript => 'Bash-script';

  @override
  String get nodeConfigScriptHelp =>
      'Uitgevoerd met bash -c. GITHUB_TOKEN is ingesteld. Placeholders worden vóór uitvoering vervangen.';

  @override
  String get nodeConfigTriggers => 'Geactiveerd door';

  @override
  String get nodeConfigNoUpstream =>
      'Er zijn geen andere nodes om vanaf te verbinden.';

  @override
  String get nodeConfigRouteKeys => 'Routesleutels';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'Routesleutel van $source';
  }

  @override
  String get conditionSectionTitle => 'Voorwaarde';

  @override
  String get conditionMode => 'Modus';

  @override
  String get conditionModeFilesAny => 'Bestand(en) aanwezig — een';

  @override
  String get conditionModeFilesAll => 'Bestanden aanwezig — alle';

  @override
  String get conditionModeComparison => 'Vergelijking';

  @override
  String get conditionModeSwitch => 'Schakelaar';

  @override
  String get conditionFilePaths => 'Bestandspaden';

  @override
  String get conditionFilePathsAnyHelp =>
      'Eén pad per regel, relatief aan de basismap. Geeft true als er een bestaat.';

  @override
  String get conditionFilePathsAllHelp =>
      'Eén pad per regel, relatief aan de basismap. Geeft true alleen als alle bestaan.';

  @override
  String get conditionBaseKey => 'Sleutel van de basismap';

  @override
  String get conditionBaseKeyHelp =>
      'Statussleutel met de map waartegen paden worden opgelost (standaard repo_local_path).';

  @override
  String get conditionRecursive => 'Submappen doorzoeken';

  @override
  String get conditionNegate => 'Omkeren: true als ontbreekt';

  @override
  String get conditionLeft => 'Linkerwaarde';

  @override
  String get conditionOperator => 'Operator';

  @override
  String get conditionRight => 'Rechterwaarde';

  @override
  String get conditionSwitchKey => 'Schakelen op statussleutel';

  @override
  String get conditionCases => 'Gevallen (door komma\'s gescheiden)';

  @override
  String get conditionCasesHelp =>
      'Routesleutels om met de waarde te vergelijken, op volgorde.';

  @override
  String get conditionDefaultCase => 'Standaardgeval';

  @override
  String get triggerPanelTitle => 'Triggers';

  @override
  String get triggerPanelHelp => 'Wat deze pipeline start.';

  @override
  String get triggerManualHelp =>
      'Toon op de uitvoerpagina en start handmatig.';

  @override
  String get triggerSectionAutomatic => 'Automatische triggers';

  @override
  String get triggerAddButton => 'Trigger toevoegen';

  @override
  String get triggerNoneYet => 'Nog geen automatische triggers.';

  @override
  String get triggerAddDialogTitle => 'Trigger toevoegen';

  @override
  String get triggerKindLabel => 'Triggertype';

  @override
  String get triggerKindEvent => 'Bij een gebeurtenis';

  @override
  String get triggerKindSchedule => 'Volgens een schema';

  @override
  String get triggerKindWebhook => 'Via een webhook';

  @override
  String get triggerScheduleExprLabel => 'Planning (cron of every:seconden)';

  @override
  String get triggerTimezoneLabel => 'Tijdzone (optioneel)';

  @override
  String get triggerCatchUpLabel => 'Bij gemiste uitvoeringen';

  @override
  String get triggerCatchUpRunOnce => 'Eén keer uitvoeren';

  @override
  String get triggerCatchUpSkip => 'Overslaan';

  @override
  String get syncHealthTitle => 'Synchronisatiestatus';

  @override
  String get syncHealthNoConfigs => 'Nog geen synchronisatieverbindingen';

  @override
  String get syncHealthNeverSynced => 'Nooit gesynchroniseerd';

  @override
  String get syncOutcomeOk => 'Gesynchroniseerd';

  @override
  String get syncOutcomeFailed => 'Mislukt';

  @override
  String get syncOutcomeSkipped => 'Overgeslagen';

  @override
  String syncHealthFailedStreak(int count) {
    return '$count opeenvolgende fouten';
  }

  @override
  String get triggerWebhookHelp =>
      'Er wordt een ondertekende webhook-URL gegenereerd. Externe systemen sturen een POST om deze pipeline te starten.';

  @override
  String get triggerEventFieldLabel => 'Gebeurtenis';

  @override
  String get triggerNoMoreEvents =>
      'Alle beschikbare gebeurtenissen zijn al gekoppeld.';

  @override
  String get triggerMatchStatusLabel => 'Alleen wanneer de status is';

  @override
  String get triggerSummaryNone => 'Geen triggers';

  @override
  String triggerEverySeconds(int seconds) {
    return 'Elke ${seconds}s';
  }

  @override
  String get triggerEventManual => 'Handmatige uitvoering';

  @override
  String get triggerEventSchedule => 'Schema';

  @override
  String get triggerEventPrStatusChanged => 'PR-status gewijzigd';

  @override
  String get triggerEventExternalPr => 'Externe PR geopend';

  @override
  String get triggerEventPrPublished => 'PR gepubliceerd';

  @override
  String get triggerEventPrMerged => 'PR samengevoegd';

  @override
  String get triggerEventRepoAdded => 'Repository toegevoegd';

  @override
  String get triggerEventCodeGraphWatch => 'Bestandswijziging';

  @override
  String pipelineRunCauseChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gewijzigde bestanden',
      one: '1 gewijzigd bestand',
    );
    return '$_temp0';
  }

  @override
  String pipelineRunCauseMorePaths(int count) {
    return '+$count meer';
  }

  @override
  String get pipelineRunCauseRescan => 'Gewijzigd op schijf';

  @override
  String get pipelineRunCauseInitial => 'Eerste indexering van deze werkkopie';

  @override
  String get triggerEventMessageReceived => 'Bericht ontvangen';

  @override
  String get triggerEventTicketCompleted => 'Taak voltooid';

  @override
  String get triggerEventTicketFailed => 'Taak mislukt';

  @override
  String get triggerEventTicketCancelled => 'Taak geannuleerd';

  @override
  String get triggerEventBudgetCrossed => 'Budgetdrempel overschreden';

  @override
  String get nodeLibrarySearchHint => 'Knooppunten zoeken';

  @override
  String get nodeLibraryNoMatches => 'Geen overeenkomende knooppunten';

  @override
  String get nodeCategoryFlow => 'Flow en logica';

  @override
  String get nodeCategoryPr => 'PR-review';

  @override
  String get nodeCategoryAgents => 'Agents';

  @override
  String get nodeCategoryMessaging => 'Berichten';

  @override
  String get nodeCategoryCode => 'Code';

  @override
  String get triggerDisabledTag => 'uit';

  @override
  String get pipelineInputTypeRepo => 'Repository';

  @override
  String get pipelineRunNoRepos => 'Nog geen repository\'s in deze werkruimte.';

  @override
  String get allowTicketingApi => 'Ticketing-API-aanroepen toestaan';

  @override
  String get ticketingApiKey => 'Ticketing-API-sleutel';

  @override
  String get ticketingApiKeySubtitle =>
      'Injecteert de API-sleutel van de ticketingprovider in de sandbox.';

  @override
  String get ticketingProvider => 'Ticketingprovider';

  @override
  String get connectGitHubAndTicketing =>
      'Verbind een codehost zodat Control Center je pull requests, issues en reviews kan lezen. Verbind optioneel een ticketingprovider. Gegevens staan op je server, nooit op deze machine.';

  @override
  String get triggerEventTicketAssigned => 'Ticket toegewezen';

  @override
  String get navTickets => 'Tickets';

  @override
  String get ticketsTitle => 'Tickets';

  @override
  String get newTicket => 'Nieuw ticket';

  @override
  String get noTicketsYet => 'Nog geen tickets';

  @override
  String get addCollaborator => 'Medewerker toevoegen';

  @override
  String get noCollaborators => 'Nog geen medewerkers';

  @override
  String get linkedPullRequests => 'Gekoppelde pull requests';

  @override
  String get noLinkedPullRequests => 'Nog geen gekoppelde pull requests';

  @override
  String get stopAgent => 'Agent stoppen';

  @override
  String get ticketProperties => 'Eigenschappen';

  @override
  String get ticketTabIssue => 'Ticket';

  @override
  String get ticketSelectPrompt =>
      'Selecteer een ticket om de details te bekijken';

  @override
  String get unassigned => 'Niet toegewezen';

  @override
  String get ticketStatusBacklog => 'Backlog';

  @override
  String get ticketStatusOpen => 'Te doen';

  @override
  String get ticketStatusInProgress => 'Bezig';

  @override
  String get ticketStatusInReview => 'In review';

  @override
  String get ticketStatusDone => 'Klaar';

  @override
  String get ticketStatusBlocked => 'Geblokkeerd';

  @override
  String get ticketStatusFailed => 'Mislukt';

  @override
  String get ticketStatusCancelled => 'Geannuleerd';

  @override
  String get notificationTicketAssigned => 'Ticket toegewezen';

  @override
  String get notificationTicketStatusChanged => 'Ticketstatus gewijzigd';

  @override
  String get priority => 'Prioriteit';

  @override
  String get status => 'Status';

  @override
  String get assignee => 'Toegewezen aan';

  @override
  String get labels => 'Labels';

  @override
  String get noLabelsYet => 'Nog geen labels';

  @override
  String get clearLabels => 'Labels wissen';

  @override
  String get pipelineStepAgentActivity => 'Agentactiviteit';

  @override
  String get runStatusCompleted => 'Voltooid';

  @override
  String get runStatusQueued => 'In wachtrij';

  @override
  String get ticketDescription => 'Beschrijving';

  @override
  String get ticketPriorityNone => 'Geen';

  @override
  String get ticketPriorityUrgent => 'Urgent';

  @override
  String get ticketPriorityHigh => 'Hoog';

  @override
  String get ticketPriorityMedium => 'Gemiddeld';

  @override
  String get ticketPriorityLow => 'Laag';

  @override
  String get ticketViewList => 'Lijst';

  @override
  String get ticketViewBoard => 'Bord';

  @override
  String get ticketTitlePlaceholder => 'Tickettitel';

  @override
  String get ticketDescriptionPlaceholder => 'Beschrijving toevoegen…';

  @override
  String get createMore => 'Meer aanmaken';

  @override
  String selectedCount(int count) {
    return '$count geselecteerd';
  }

  @override
  String get clearSelection => 'Selectie wissen';

  @override
  String get bulkDeleteTitle => 'Tickets verwijderen';

  @override
  String bulkDeleteMessage(int count) {
    return '$count geselecteerde tickets verwijderen? Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String get assignTo => 'Toewijzen aan…';

  @override
  String get sectionMembers => 'Leden';

  @override
  String get sectionAgents => 'Agenten';

  @override
  String get sidebarGroupWorkspace => 'Werkruimte';

  @override
  String get notificationsTitle => 'Meldingen';

  @override
  String get notificationsTooltip => 'Meldingen';

  @override
  String get notificationsEmpty => 'Je bent helemaal bij';

  @override
  String notificationsUnreadCount(int count) {
    return '$count ongelezen';
  }

  @override
  String get notificationsMarkRead => 'Markeren als gelezen';

  @override
  String get notificationsMarkUnread => 'Markeren als ongelezen';

  @override
  String get notificationsEntryActions => 'Meldingsacties';

  @override
  String get markAllRead => 'Alles als gelezen markeren';

  @override
  String get teamsNav => 'Teams';

  @override
  String get noWorkspace => 'Geen werkruimte';

  @override
  String get selectWorkspace => 'Selecteer een werkruimte';

  @override
  String get navMemory => 'Geheugen';

  @override
  String get memoryTabFacts => 'Feiten';

  @override
  String get memoryTabPolicies => 'Beleid';

  @override
  String get memoryGraphShowFacts => 'Feiten tonen';

  @override
  String get memoryGraphHideFacts => 'Feiten verbergen';

  @override
  String get memoryGraphExpandAll => 'Alle feiten tonen';

  @override
  String get memoryGraphCollapseAll => 'Alle feiten verbergen';

  @override
  String get memoryTabGraph => 'Kennisgrafiek';

  @override
  String get memoryNoWorkspace =>
      'Selecteer een werkruimte om het geheugen te bekijken.';

  @override
  String get searchArticles => 'Artikelen zoeken';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterUnread => 'Ongelezen';

  @override
  String get filterSaved => 'Opgeslagen';

  @override
  String get saveArticle => 'Artikel opslaan';

  @override
  String get removeFromSaved => 'Verwijderen uit opgeslagen';

  @override
  String get filterBySource => 'Filteren op bron';

  @override
  String get viewAsList => 'Lijstweergave';

  @override
  String get viewAsGrid => 'Rasterweergave';

  @override
  String get noMatchingArticles => 'Geen overeenkomende artikelen';

  @override
  String get noMatchingArticlesBody =>
      'Probeer een andere zoekopdracht of bronfilter.';

  @override
  String get allCaughtUp => 'Helemaal bij';

  @override
  String get allCaughtUpBody => 'Geen ongelezen artikelen — kom later terug.';

  @override
  String get openArticlesInAppDescription =>
      'Links openen in de ingebouwde lezer in plaats van je standaardbrowser.';

  @override
  String get blockAdsTrackersDescription =>
      'Advertenties, trackers en cookiebanners verwijderen uit artikelen die je in de lezer opent.';

  @override
  String get agentQuestionHeader => 'Vraag voor jou';

  @override
  String get agentQuestionAnsweredLabel => 'Beantwoord';

  @override
  String get agentQuestionSubmit => 'Antwoord versturen';

  @override
  String get agentQuestionFreeformHint => 'Typ je antwoord…';

  @override
  String get agentQuestionAnswerLabel => 'Jouw antwoord';

  @override
  String get reviewRequested => 'Review aangevraagd';

  @override
  String get connectGitHubHint =>
      'Log in bij GitHub of voeg een token toe in Instellingen → Jij → Profiel en identiteit → Codehosting';

  @override
  String get connectGitHubToLoadPrs =>
      'Verbind GitHub om pull requests te laden';

  @override
  String get noRepositoriesConfigured => 'Geen repository\'s geconfigureerd';

  @override
  String openedAgo(String age) {
    return 'Geopend $age';
  }

  @override
  String prTimelineOpened(String author) {
    return '$author heeft deze pull request geopend';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$author heeft deze pull request geopend met $_temp0';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return '$actor heeft review aangevraagd van $reviewers';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '$actor heeft het reviewverzoek voor $reviewers verwijderd';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '$actor heeft review aangevraagd van $requested en het reviewverzoek voor $removed verwijderd';
  }

  @override
  String prTimelineCommitted(String author) {
    return '$author heeft gecommit';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$author heeft $_temp0 gepusht';
  }

  @override
  String prTimelineApproved(String author) {
    return '$author heeft deze wijzigingen goedgekeurd';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return '$author heeft wijzigingen aangevraagd';
  }

  @override
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count codeopmerkingen',
      one: '1 codeopmerking',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '$author heeft een review achtergelaten';
  }

  @override
  String get prTimelineSomeone => 'Iemand';

  @override
  String get prTimelineBotBadge => 'bot';

  @override
  String updatedAgo(String age) {
    return 'Bijgewerkt $age';
  }

  @override
  String get checksPassing => 'Controles geslaagd';

  @override
  String get checksRunning => 'Controles bezig';

  @override
  String get needsYourReview => 'Vereist jouw review';

  @override
  String get checks => 'Controles';

  @override
  String get noReviewersAssigned => 'Geen reviewers toegewezen';

  @override
  String get noAssignees => 'Geen toegewezen personen';

  @override
  String get loadingEllipsis => 'Laden…';

  @override
  String get loadingChecks => 'Controles laden…';

  @override
  String get noChecksYet => 'Nog geen controles uitgevoerd';

  @override
  String checksFailingCount(int count) {
    return '$count mislukt';
  }

  @override
  String get showMore => 'Meer tonen';

  @override
  String get showLess => 'Minder tonen';

  @override
  String get backToPullRequests => 'Terug naar pull requests';

  @override
  String get pullRequestNotFound => 'Pull request niet gevonden';

  @override
  String get pullRequestNotFoundBody =>
      'Mogelijk is deze samengevoegd, gesloten of verplaatst.';

  @override
  String get couldntLoadPullRequest => 'Kan deze pull request niet laden';

  @override
  String get showDetails => 'Details tonen';

  @override
  String get noDescriptionProvided => 'Geen beschrijving opgegeven.';

  @override
  String get factsHint => 'Feiten verschijnen hier naarmate je agents leren.';

  @override
  String get noFactsMatch => 'Geen feiten komen overeen met je zoekopdracht';

  @override
  String get memoryLoadError => 'Kan geheugen niet laden';

  @override
  String get sortRecent => 'Recent';

  @override
  String get sortConfidence => 'Vertrouwen';

  @override
  String get confidenceTooltip =>
      'Hoe zeker agents zijn dat dit feit klopt, van 0 tot 100%.';

  @override
  String get supersededTooltip => 'Een nieuwer feit heeft dit vervangen.';

  @override
  String get domain => 'Domein';

  @override
  String get fitToView => 'Passend maken';

  @override
  String get project => 'Project';

  @override
  String get newProject => 'Nieuw project';

  @override
  String get editProject => 'Project bewerken';

  @override
  String get deleteProject => 'Project verwijderen';

  @override
  String get noProject => 'Geen project';

  @override
  String get allTickets => 'Alle tickets';

  @override
  String get projectNamePlaceholder => 'Projectnaam';

  @override
  String get projectDescriptionPlaceholder => 'Beschrijving (optioneel)';

  @override
  String get projectColorLabel => 'Kleur';

  @override
  String get noProjectsYet => 'Nog geen projecten';

  @override
  String get projectTicketsEmpty => 'Nog geen tickets in dit project';

  @override
  String get createProject => 'Project aanmaken';

  @override
  String projectProgress(int done, int total) {
    return '$done van $total klaar';
  }

  @override
  String deleteProjectConfirm(String name) {
    return '\"$name\" verwijderen? De tickets blijven behouden en worden uit het project verwijderd.';
  }

  @override
  String get projectStatusActive => 'Actief';

  @override
  String get projectStatusCompleted => 'Voltooid';

  @override
  String get projectStatusArchived => 'Gearchiveerd';

  @override
  String get markProjectCompleted => 'Markeren als voltooid';

  @override
  String get markProjectActive => 'Markeren als actief';

  @override
  String get archiveProject => 'Archiveren';

  @override
  String get restoreProject => 'Herstellen';

  @override
  String get relations => 'Relaties';

  @override
  String get relateTo => 'Koppelen aan';

  @override
  String get relationSubIssueOf => 'Subtaak van…';

  @override
  String get relationParentOf => 'Bovenliggend van…';

  @override
  String get relationBlockedBy => 'Geblokkeerd door…';

  @override
  String get relationBlocking => 'Blokkeert…';

  @override
  String get relationRelatedTo => 'Gerelateerd aan…';

  @override
  String get relationDuplicateOf => 'Duplicaat van…';

  @override
  String get relationGroupParent => 'Bovenliggend';

  @override
  String get relationGroupSubIssues => 'Subtaken';

  @override
  String get relationGroupBlockedBy => 'Geblokkeerd door';

  @override
  String get relationGroupBlocking => 'Blokkeert';

  @override
  String get relationGroupRelated => 'Gerelateerd';

  @override
  String get relationGroupDuplicateOf => 'Duplicaat van';

  @override
  String get relationGroupDuplicatedBy => 'Gedupliceerd door';

  @override
  String get copyId => 'ID kopiëren';

  @override
  String get ticketIdCopied => 'Ticket-ID gekopieerd';

  @override
  String get searchTicketsHint => 'Tickets zoeken…';

  @override
  String get noMatchingTickets => 'Geen overeenkomende tickets';

  @override
  String get clearAll => 'Alles wissen';

  @override
  String agentsRunningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agents actief',
      one: '1 agent actief',
    );
    return '$_temp0';
  }

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs PRs wachten',
      one: '1 PR wacht',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos repo\'s',
      one: '1 repo',
    );
    return '$_temp0 op je review in $_temp1';
  }

  @override
  String get manageWorkspacesSubtitle =>
      'Hernoem een werkruimte en wijzig het merkteken — kies er links een om te bewerken.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count werkruimtes',
      one: '1 werkruimte',
      zero: 'Geen werkruimtes',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos repo\'s',
      one: '1 repo',
      zero: 'Geen repo\'s',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents agents',
      one: '1 agent',
      zero: '0 agents',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'Identiteit';

  @override
  String get uploadImage => 'Afbeelding uploaden';

  @override
  String get failedToSaveLogo =>
      'Logo opslaan mislukt. Zorg dat de app het geselecteerde bestand kan lezen.';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG of GIF tot 2 MB. Anders gebruiken we de eerste letter van de werkruimte.';

  @override
  String get workspaceNameFieldHelp =>
      'Wordt getoond in de wisselaar, het broodkruimelpad en op elk scherm.';

  @override
  String get dangerZone => 'Gevarenzone';

  @override
  String get deleteThisWorkspace => 'Deze werkruimte verwijderen';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return 'Verwijdert $name, de bijbehorende repositorykoppelingen, agents en geheugen definitief. Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String get discard => 'Negeren';

  @override
  String discardChangesQuestion(String name) {
    return 'Niet-opgeslagen wijzigingen aan $name negeren?';
  }

  @override
  String get workspaceUpdated => 'Werkruimte bijgewerkt';

  @override
  String get editTitle => 'Titel bewerken';

  @override
  String get editDescription => 'Beschrijving bewerken';

  @override
  String get addDescription => 'Een beschrijving toevoegen';

  @override
  String get prTitlePlaceholder => 'Titel';

  @override
  String get prBodyPlaceholder => 'Voeg een beschrijving toe';

  @override
  String get write => 'Schrijven';

  @override
  String get overview => 'Overzicht';

  @override
  String get noFilesChanged => 'Geen bestanden gewijzigd';

  @override
  String get diff => 'Diff';

  @override
  String get preview => 'Voorbeeld';

  @override
  String get outdated => 'Verouderd';

  @override
  String get outdatedComments => 'Verouderde opmerkingen';

  @override
  String outdatedCountLabel(int count) {
    return '$count verouderd';
  }

  @override
  String get prTemplateLabel => 'Sjabloon';

  @override
  String get prTemplateDefault => 'Standaard';

  @override
  String get addReviewers => 'Reviewers toevoegen';

  @override
  String get addAssignees => 'Toegewezenen toevoegen';

  @override
  String get searchUsers => 'Personen zoeken…';

  @override
  String get searchReviewers => 'Personen en teams zoeken…';

  @override
  String get usersSectionLabel => 'Personen';

  @override
  String get userStatusBusy => 'Bezig';

  @override
  String get teamsSectionLabel => 'Teams';

  @override
  String get suggestedReviewers => 'Voorgestelde reviewers';

  @override
  String get noMatchingUsers => 'Geen overeenkomende personen';

  @override
  String get noMatchingReviewers => 'Geen overeenkomsten';

  @override
  String get requiredByCodeOwners => 'Vereist door code-eigenaren';

  @override
  String reviewedOnBehalfOf(String login) {
    return 'via $login';
  }

  @override
  String get team => 'Team';

  @override
  String get markdownBold => 'Vet';

  @override
  String get markdownItalic => 'Cursief';

  @override
  String get markdownHeading => 'Kop';

  @override
  String get markdownBulletList => 'Opsommingslijst';

  @override
  String get markdownChecklist => 'Checklist';

  @override
  String get markdownCode => 'Code';

  @override
  String get markdownLink => 'Link';

  @override
  String get markdownQuote => 'Citaat';

  @override
  String get markdownSupported => 'Markdown wordt ondersteund';

  @override
  String get markdownAttachImages => 'Klik om afbeeldingen toe te voegen';

  @override
  String failedToUpdateTitle(String error) {
    return 'Kan titel niet bijwerken: $error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'Kan beschrijving niet bijwerken: $error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'Kan reviewers niet bijwerken: $error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'Kan toegewezenen niet bijwerken: $error';
  }

  @override
  String get discardChangesConfirm => 'Wijzigingen negeren?';

  @override
  String get newPr => 'Nieuwe PR';

  @override
  String get openPullRequest => 'Een pull request openen';

  @override
  String get composePrSubtitle =>
      'Vanaf een branch die je hebt gepusht — zonder agents of tickets';

  @override
  String get createAsDraft => 'Als concept aanmaken';

  @override
  String get composePrNoRepo => 'Geen GitHub-repository geselecteerd';

  @override
  String get composePrNoRepoHint =>
      'Selecteer een werkruimte met een aan GitHub gekoppelde repository om een pull request te openen.';

  @override
  String get composePrPickBranches =>
      'Kies een basis- en vergelijkingsbranch om de wijzigingen te bekijken.';

  @override
  String get composePrNothingToCompare =>
      'Er zijn geen wijzigingen tussen deze branches.';

  @override
  String get repository => 'Repository';

  @override
  String get baseBranchLabel => 'Basis';

  @override
  String get compareBranchLabel => 'Vergelijken';

  @override
  String get selectBranch => 'Selecteer een branch';

  @override
  String get navMeetings => 'Vergaderingen';

  @override
  String get meetingsNoWorkspace =>
      'Selecteer een werkruimte om vergaderingen te zien.';

  @override
  String get meetingsEmpty => 'Nog geen vergaderingen';

  @override
  String get meetingsEmptyHint =>
      'Neem je eerste vergadering op — de audio blijft op dit apparaat en de agent maakt er notities, beslissingen en actiepunten van.';

  @override
  String get meetingNotesHint =>
      'Maak korte notities — de agent werkt ze na de vergadering uit.';

  @override
  String get meetingSpeakerMe => 'Jij';

  @override
  String get meetingStatusRecording => 'Opname';

  @override
  String get meetingStatusProcessing => 'Verwerken';

  @override
  String get meetingStatusDone => 'Klaar';

  @override
  String get meetingStatusFailed => 'Mislukt';

  @override
  String get meetingsSubtitle =>
      'Opgenomen en getranscribeerd op dit apparaat, daarna samengevat door een agent.';

  @override
  String get meetingsRecordMeeting => 'Vergadering opnemen';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count worden nu verwerkt',
      one: '1 wordt nu verwerkt',
    );
    return '$_temp0';
  }

  @override
  String meetingsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vergaderingen',
      one: '1 vergadering',
      zero: 'Geen vergaderingen',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLedgerOpenActions => 'Open actiepunten';

  @override
  String get meetingsLedgerDecisions => 'Beslissingen';

  @override
  String get meetingsLiveOpen => 'Opname openen';

  @override
  String get meetingTemplateShort => 'Sjabloon';

  @override
  String get meetingsStatThisWeek => 'Deze week';

  @override
  String get meetingsStatRecorded => 'Opgenomen';

  @override
  String get meetingsFilterAll => 'Alle';

  @override
  String get meetingsFilterDone => 'Klaar';

  @override
  String get meetingsFilterProcessing => 'Bezig';

  @override
  String get meetingsSearchHint => 'Filter op titel, persoon, app…';

  @override
  String get meetingsBucketToday => 'Vandaag';

  @override
  String get meetingsBucketYesterday => 'Gisteren';

  @override
  String get meetingsBucketEarlierThisWeek => 'Eerder deze week';

  @override
  String get meetingsBucketLastWeek => 'Vorige week';

  @override
  String get meetingsBucketOlder => 'Ouder';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count beslissingen',
      one: '1 beslissing',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total actiepunten';
  }

  @override
  String get meetingsEnhancedPill => 'verrijkt';

  @override
  String get meetingsTranscribing => 'transcriberen en samenvatten…';

  @override
  String get meetingsOpenAction => 'Openen';

  @override
  String get meetingsStopProcessing => 'Stoppen';

  @override
  String get meetingsStillTranscribing =>
      'Nog aan het transcriberen — de samenvatting verschijnt zodra het klaar is.';

  @override
  String get meetingsNoMatch => 'Geen vergadering komt overeen';

  @override
  String get meetingsNoMatchHint => 'Probeer een ander filter of zoekterm.';

  @override
  String get meetingBackAllMeetings => 'Alle vergaderingen';

  @override
  String get meetingReRunSummary => 'Samenvatting opnieuw maken';

  @override
  String get meetingExport => 'Exporteren';

  @override
  String get meetingAugmentingBanner =>
      'Je notities worden verrijkt vanuit het transcript — beslissingen en actiepunten worden geëxtraheerd…';

  @override
  String get meetingTabNotes => 'Notities';

  @override
  String get meetingTabTranscript => 'Transcript';

  @override
  String get meetingTabActionItems => 'Actiepunten';

  @override
  String get meetingTabDecisions => 'Beslissingen';

  @override
  String get meetingNotesEnhancedToggle => 'Verrijkt';

  @override
  String get meetingNotesYoursToggle => 'Jouw notities';

  @override
  String get meetingEnhancedByAgent =>
      'Verrijkt door de agent · uit het transcript';

  @override
  String get meetingEnhancedPending =>
      'De agent werkt nog aan deze samenvatting.';

  @override
  String get meetingNotesEmpty => 'Nog geen verrijkte notities.';

  @override
  String get meetingNotesSavedLocally => 'Lokaal opgeslagen';

  @override
  String get meetingNotesSaving => 'Opslaan…';

  @override
  String get meetingViewFullTranscript => 'Volledig transcript bekijken';

  @override
  String get meetingTranscriptSearchHint => 'Zoek in het transcript…';

  @override
  String get meetingSpeakerEveryone => 'Iedereen';

  @override
  String get meetingSpeakerOthers => 'Anderen';

  @override
  String get meetingTranscriptEmpty => 'Nog geen transcript.';

  @override
  String get meetingActionItemsEmpty => 'Geen actiepunten geëxtraheerd.';

  @override
  String get meetingActionItemFrom => 'uit deze vergadering';

  @override
  String get meetingCreateTicket => 'Ticket aanmaken';

  @override
  String meetingTicketCreated(String key) {
    return 'Ticket $key aangemaakt en verstuurd.';
  }

  @override
  String get meetingTicketFailed => 'Kon het ticket niet aanmaken.';

  @override
  String get meetingDecisionsEmpty => 'Geen beslissingen vastgelegd.';

  @override
  String get meetingEditTitle => 'Titel bewerken';

  @override
  String get meetingTitleLabel => 'Titel';

  @override
  String get meetingAddActionItem => 'Actiepunt toevoegen';

  @override
  String get meetingEditActionItem => 'Actiepunt bewerken';

  @override
  String get meetingDeleteActionItem => 'Actiepunt verwijderen';

  @override
  String get meetingActionItemContentLabel => 'Actiepunt';

  @override
  String get meetingActionItemContentHint => 'Wat moet er gebeuren?';

  @override
  String get meetingActionItemOwnerLabel => 'Eigenaar';

  @override
  String get meetingActionItemOwnerHint =>
      'Wie is verantwoordelijk? (optioneel)';

  @override
  String get meetingAddDecision => 'Beslissing toevoegen';

  @override
  String get meetingEditDecision => 'Beslissing bewerken';

  @override
  String get meetingDeleteDecision => 'Beslissing verwijderen';

  @override
  String get meetingDecisionContentLabel => 'Beslissing';

  @override
  String get meetingDecisionContentHint => 'Wat is er besloten?';

  @override
  String get meetingReRunStarted =>
      'Samenvatting wordt opnieuw op het transcript gemaakt…';

  @override
  String get meetingReRunNoTranscript =>
      'Er is nog geen transcript om samen te vatten.';

  @override
  String get meetingExportCopied =>
      'Notities als Markdown naar het klembord gekopieerd.';

  @override
  String get meetingExportSaved => 'Vergadering geëxporteerd.';

  @override
  String meetingExportFailed(String error) {
    return 'Exporteren mislukt: $error';
  }

  @override
  String get meetingExportNothing => 'Er is nog niets om te exporteren.';

  @override
  String get meetingPlaybackPlay => 'Afspelen';

  @override
  String get meetingPlaybackPause => 'Pauzeren';

  @override
  String get meetingPlaybackUnavailable =>
      'Audioweergave is niet beschikbaar op dit apparaat.';

  @override
  String get meetingDetectedTitle => 'Vergadering gedetecteerd';

  @override
  String meetingDetectedSubtitle(String label) {
    return 'Het lijkt erop dat \"$label\" bezig is. Opnemen?';
  }

  @override
  String get meetingDetectedSubtitleGeneric =>
      'Het lijkt erop dat er een vergadering bezig is. Opnemen?';

  @override
  String get meetingDetectedRecord => 'Opnemen';

  @override
  String get meetingDetectedDismiss => 'Negeren';

  @override
  String get meetingAutoStopTitle =>
      'Deze vergadering lijkt voorbij. Opname stoppen?';

  @override
  String get meetingAutoStopStop => 'Stoppen';

  @override
  String get meetingAutoStopKeep => 'Blijven opnemen';

  @override
  String get meetingAutoDetect => 'Vergaderingen automatisch detecteren';

  @override
  String get meetingAutoDetectDescription =>
      'Houdt de agenda en vergader-apps in de gaten en biedt aan om op te nemen wanneer een vergadering begint.';

  @override
  String get meetingsRecordingCrumb => 'Opnemen…';

  @override
  String get meetingRecordTitleHint => 'Vergaderingstitel';

  @override
  String get meetingRecordTappingLabel => 'Aftappen:';

  @override
  String get meetingRecordMic => 'Microfoon';

  @override
  String get meetingRecordSystemAudio => 'Systeemaudio';

  @override
  String get meetingRecordPause => 'Pauzeren';

  @override
  String get meetingRecordResume => 'Hervatten';

  @override
  String get meetingRecordStop => 'Stoppen en samenvatten';

  @override
  String get meetingRecordYourNotes => 'Jouw notities';

  @override
  String get meetingRecordNotesPlaceholder =>
      'Typ terwijl je luistert. Een paar fragmenten is genoeg — na het stoppen breidt de agent ze uit met het transcript.';

  @override
  String get meetingRecordLiveTranscript => 'Live transcript';

  @override
  String get meetingRecordDecoding => 'decoderen op het apparaat';

  @override
  String get meetingRecordListening =>
      'Aan het luisteren… spraak verschijnt hier binnen een seconde of twee, gelabeld als Jij / Anderen.';

  @override
  String get meetingRecordPausedHint =>
      'Gepauzeerd — audio wordt genegeerd tot je hervat.';

  @override
  String get meetingRecordNotActive => 'Geen actieve opname.';

  @override
  String get meetingHudRecording => 'opnemen';

  @override
  String get meetingHudPaused => 'gepauzeerd';

  @override
  String get meetingHudOpen => 'Openen';

  @override
  String get meetingHudStop => 'Stoppen';

  @override
  String get meetingToolbarPopOut => 'Losmaken';

  @override
  String get meetingToolbarHoldToStop =>
      'Houd ingedrukt om de opname te stoppen';

  @override
  String get meetingToolbarSemanticLabel => 'Werkbalk voor vergaderopname';

  @override
  String get orchestrate => 'Orkestreren';

  @override
  String get orchestrationUnavailable => 'Orkestratie niet beschikbaar';

  @override
  String get orchestrationApprove => 'Plan goedkeuren';

  @override
  String get orchestrationReject => 'Afwijzen';

  @override
  String get orchestrationCancel => 'Orkestratie annuleren';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count rollen — $hires nieuwe aanstellingen';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count subtickets';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'Geschatte kosten: $amount \$';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total subtickets klaar';
  }

  @override
  String get orchestrationStatusProposed => 'Voorgesteld';

  @override
  String get orchestrationStatusApproved => 'Goedgekeurd';

  @override
  String get orchestrationStatusExecuting => 'Bezig';

  @override
  String get orchestrationStatusSynthesizing => 'Synthese';

  @override
  String get orchestrationStatusCompleted => 'Voltooid';

  @override
  String get orchestrationStatusFailed => 'Mislukt';

  @override
  String get orchestrationStatusCancelled => 'Geannuleerd';

  @override
  String get messageFailed => 'Run mislukt';

  @override
  String get turnLimitReached =>
      'Beurtlimiet bereikt — antwoord om verder te gaan';

  @override
  String get retried => 'Opnieuw geprobeerd';

  @override
  String replyingTo(String name) {
    return 'in reactie op $name';
  }

  @override
  String get silenceTimeoutLabel => 'Stilte-time-out (minuten)';

  @override
  String get silenceTimeoutHint =>
      'bijv. 15 — beëindigt een run na deze tijd zonder uitvoer';

  @override
  String get capabilityJsonMode => 'JSON-modus';

  @override
  String get capabilityModelSelection => 'Modelselectie';

  @override
  String get transcriptThinking => 'Aan het denken…';

  @override
  String transcriptThoughtFor(String duration) {
    return 'Heeft $duration nagedacht';
  }

  @override
  String get transcriptStatusMakingEdits => 'Bewerkingen aanbrengen…';

  @override
  String get transcriptStatusReadingFiles => 'Bestanden lezen…';

  @override
  String get transcriptStatusSearching => 'Codebase doorzoeken…';

  @override
  String get transcriptStatusRunningCommands => 'Opdrachten uitvoeren…';

  @override
  String get transcriptStatusResponding => 'Aan het antwoorden…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return '$tool uitvoeren…';
  }

  @override
  String get transcriptInput => 'Invoer';

  @override
  String get transcriptOutput => 'Uitvoer';

  @override
  String get transcriptErrorLabel => 'Fout';

  @override
  String get transcriptSandboxBlocked => 'Sandbox heeft een actie geblokkeerd';

  @override
  String transcriptShowFullOutput(int kb) {
    return 'Volledige uitvoer tonen (+$kb KB)';
  }

  @override
  String transcriptShowAllLines(int count) {
    return 'Alle $count regels tonen';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return 'Eerste $count regels worden getoond';
  }

  @override
  String get transcriptGrepNoMatches => 'Geen overeenkomsten';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '$matches overeenkomsten',
      one: '1 overeenkomst',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files bestanden',
      one: '1 bestand',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return 'Persoon $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => 'Spreker hernoemen';

  @override
  String get meetingRenameSpeakerTitle => 'Spreker hernoemen';

  @override
  String get meetingSpeakerNameLabel => 'Naam';

  @override
  String get meetingSpeakerSuggestFromCalendar =>
      'Uit de genodigden van deze vergadering';

  @override
  String get meetingRenameSpeakerApplyAll =>
      'Toepassen op alle blokken van deze spreker';

  @override
  String get meetingRenameSpeakerScopeHint =>
      'Indien uit, wordt alleen de geselecteerde regel hernoemd.';

  @override
  String get meetingLinkEvent => 'Koppelen aan gebeurtenis';

  @override
  String get meetingChangeEvent => 'Gebeurtenis wijzigen';

  @override
  String get meetingLinkEventTitle => 'Koppelen aan een agendagebeurtenis';

  @override
  String get meetingLinkEventSearchHint => 'Gebeurtenissen zoeken';

  @override
  String get meetingLinkEventEmpty => 'Geen agendagebeurtenissen in de buurt';

  @override
  String get meetingUnlinkEvent => 'Koppeling verwijderen';

  @override
  String get calendarLinkExistingMeeting =>
      'Koppelen aan bestaande vergadering';

  @override
  String get calendarLinkMeetingTitle => 'Een vergadering koppelen';

  @override
  String get calendarLinkMeetingSearchHint => 'Vergaderingen zoeken';

  @override
  String get calendarLinkMeetingEmpty => 'Geen vergaderingen om te koppelen';

  @override
  String get meetingRenameSpeakerFailed => 'Kan de spreker niet hernoemen';

  @override
  String get calendarLinkUpdateFailed =>
      'Kan de agendakoppeling niet bijwerken';

  @override
  String get rename => 'Naam wijzigen';

  @override
  String get notNow => 'Niet nu';

  @override
  String get meetingSaveVoiceProfileTitle => 'Stemprofiel opslaan?';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return 'Herken $name automatisch in toekomstige vergaderingen door hun stemafdruk op te slaan.';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return 'Stemprofiel opgeslagen voor $name';
  }

  @override
  String get meetingVoiceProfileSaveFailed =>
      'Kan het stemprofiel niet opslaan';

  @override
  String get voiceProfilesSection => 'Stemprofielen';

  @override
  String get voiceProfilesDescription =>
      'Opgeslagen stemmen worden automatisch herkend in toekomstige vergaderingen.';

  @override
  String get voiceProfilesEmpty =>
      'Nog geen opgeslagen stemmen. Geef een spreker een naam in een vergadertranscriptie en kies ‘Stemprofiel opslaan’.';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count monsters',
      one: '1 monster',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => 'Stemprofiel hernoemen';

  @override
  String get deleteVoiceProfileTitle => 'Stemprofiel verwijderen?';

  @override
  String deleteVoiceProfileBody(String name) {
    return '$name niet meer herkennen? Hun opgeslagen stemafdruk wordt verwijderd. Namen die al in eerdere vergaderingen zijn toegepast, blijven behouden.';
  }

  @override
  String get connectedLabel => 'Verbonden';

  @override
  String get ideTabGeneral => 'Algemeen';

  @override
  String get ideTabExplorer => 'Verkenner';

  @override
  String get ideTabSourceControl => 'Broncodebeheer';

  @override
  String get generalSectionTodos => 'Taken';

  @override
  String get generalSectionGoals => 'Doelen';

  @override
  String get goalRunStatusActive => 'Actief';

  @override
  String get goalRunStatusPaused => 'Gepauzeerd';

  @override
  String get goalRunStatusCompleted => 'Voltooid';

  @override
  String get goalRunStatusFailed => 'Mislukt';

  @override
  String get goalRunStatusCancelled => 'Geannuleerd';

  @override
  String get goalRunStatusBudgetExhausted => 'Budget uitgeput';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return 'Run $run van $max · $cost van $cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return 'Run $run · $cost van $cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return 'Vervalt: $deadline';
  }

  @override
  String get goalRunPause => 'Doel pauzeren';

  @override
  String get goalRunResume => 'Doel hervatten';

  @override
  String goalRunResumeRaise(String cap) {
    return 'Hervatten · limiet naar $cap';
  }

  @override
  String get goalRunStop => 'Doel stoppen';

  @override
  String get generalSectionAgents => 'Agenten';

  @override
  String get generalSectionTerminals => 'Terminals';

  @override
  String get generalTodosEmpty => 'Nog geen taken';

  @override
  String get generalAgentsEmpty => 'Geen agenten actief';

  @override
  String get generalTerminalsEmpty => 'Geen terminals open';

  @override
  String get generalSectionBrowsers => 'Browsers';

  @override
  String get generalSectionComputers => 'Computers';

  @override
  String get generalBrowsersEmpty => 'Geen browsers open';

  @override
  String get generalComputersEmpty => 'Geen computers open';

  @override
  String get generalSectionPhones => 'Telefoons';

  @override
  String get generalPhonesEmpty => 'Geen telefoons open';

  @override
  String get pauseAgent => 'Agent pauzeren';

  @override
  String get resumeAgent => 'Agent hervatten';

  @override
  String get agentCannotPause =>
      'Deze agent kan niet worden gepauzeerd — stop hem in plaats daarvan.';

  @override
  String get goalClear => 'Doel wissen';

  @override
  String get undoLabelGoalClear => 'doel wissen';

  @override
  String get todoStatusPending => 'Niet gestart';

  @override
  String get todoStatusInProgress => 'Bezig';

  @override
  String get todoStatusCompleted => 'Klaar';

  @override
  String get reorderTodo => 'Taak herordenen';

  @override
  String get focusTerminal => 'Terminal focussen';

  @override
  String get focusMachine => 'Machine focussen';

  @override
  String get focusBrowser => 'Browser focussen';

  @override
  String get todoEditorTitle => 'Taken bewerken';

  @override
  String get todoEditorHint =>
      'Eén item per regel. Gebruik - [ ] voor open, - [~] voor bezig, - [x] voor klaar.';

  @override
  String get todoNeedsText => 'Voeg tekst toe na de opdracht';

  @override
  String get todoNotFound => 'Geen overeenkomende taak';

  @override
  String get todoCleared => 'Takenlijst gewist';

  @override
  String get todoNothingToCopy => 'Niets om te kopiëren';

  @override
  String todoAdded(String content) {
    return '\"$content\" toegevoegd';
  }

  @override
  String todoStarted(String content) {
    return '\"$content\" gestart';
  }

  @override
  String todoCompleted(String content) {
    return '\"$content\" voltooid';
  }

  @override
  String todoRemoved(String content) {
    return '\"$content\" verwijderd';
  }

  @override
  String todoCopied(int count) {
    return '$count items gekopieerd';
  }

  @override
  String todoImported(int count) {
    return '$count items geïmporteerd';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return 'Onbekende taakopdracht \"$name\"';
  }

  @override
  String get terminal => 'Terminal';

  @override
  String get ideCloseTab => 'Tabblad sluiten';

  @override
  String get ideSplitEditor => 'Editor splitsen';

  @override
  String get ideSplitRight => 'Naar rechts splitsen';

  @override
  String get ideSplitDown => 'Naar beneden splitsen';

  @override
  String get ideSplitLeft => 'Naar links splitsen';

  @override
  String get ideSplitUp => 'Naar boven splitsen';

  @override
  String get ideCloseGroup => 'Groep sluiten';

  @override
  String get ideCloseOthers => 'Andere sluiten';

  @override
  String get ideCloseToRight => 'Rechts sluiten';

  @override
  String get ideCloseSaved => 'Opgeslagen sluiten';

  @override
  String get ideCloseAll => 'Alles sluiten';

  @override
  String get ideSplit => 'Splitsen';

  @override
  String get ideToggleSidebar => 'Zijbalk in/uitschakelen';

  @override
  String get ideNewTab => 'Editor openen';

  @override
  String get ideNewTabMenu => 'Nieuw tabblad';

  @override
  String get ideReviewCode => 'Code beoordelen';

  @override
  String get ideRevert => 'Terugdraaien';

  @override
  String get ideRevertConfirmTitle => 'Wijzigingen terugdraaien';

  @override
  String ideRevertConfirmMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden',
      one: '1 bestand',
    );
    return '$_temp0 terugdraaien naar HEAD? Dit verwijdert werkboom-wijzigingen.';
  }

  @override
  String get ideRevertConfirmAction => 'Terugdraaien';

  @override
  String get ideRevertConfirmCancel => 'Annuleren';

  @override
  String get ideRevertUntracked =>
      'Niet-gevolgde bestanden kunnen niet worden teruggezet';

  @override
  String get ideRevertFailed =>
      'Kon de bestanden niet terugdraaien. De werkboom van het gesprek is mogelijk niet beschikbaar.';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden',
      one: '1 bestand',
    );
    return '$_temp0 kon(den) niet worden teruggezet (niet-gevolgd).';
  }

  @override
  String get ideViewSource => 'Bron weergeven';

  @override
  String get ideSearchMatchCase => 'Hoofdlettergevoelig';

  @override
  String get ideSearchWholeWord => 'Heel woord';

  @override
  String get ideSearchRegex => 'Regex';

  @override
  String get ideSearchFilters => 'Zoekfilters';

  @override
  String get ideSearchFilesToInclude => 'Bestanden om op te nemen';

  @override
  String get ideSearchFilesToExclude => 'Bestanden om uit te sluiten';

  @override
  String get ideNoOpenTabs => 'Geen open tabbladen — gebruik + om te openen';

  @override
  String get ideBrowserAddressHint => 'Adres invoeren of zoeken';

  @override
  String get ideSimpleWebBrowser => 'Eenvoudige webbrowser';

  @override
  String get ideWebBrowser => 'Webbrowser';

  @override
  String get ideBrowserEnterUrl =>
      'Voer een URL in de adresbalk in om te browsen';

  @override
  String get ideCodeServer => 'Editor';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return 'Wijzigingen in $fileName opslaan?';
  }

  @override
  String get ideUnsavedChangesBody =>
      'Je wijzigingen gaan verloren als je ze niet opslaat.';

  @override
  String get ideDontSave => 'Niet opslaan';

  @override
  String get editorAutoSave => 'Automatisch opslaan';

  @override
  String get editorAutoSaveDescription =>
      'Wijzigingen in de ingebouwde editor automatisch opslaan.';

  @override
  String get editorAutoSaveOff => 'Uit';

  @override
  String get editorAutoSaveAfterDelay => 'Na een vertraging';

  @override
  String get editorAutoSaveOnFocusChange => 'Bij focuswijziging';

  @override
  String get ideCodeServerUnavailable =>
      'Code-server is niet beschikbaar op deze server';

  @override
  String get ideCodeServerUnavailableHint =>
      'Installeer code-server (coder/code-server) op de server-host en open de editor opnieuw.';

  @override
  String get ideCodeServerInstalling => 'Editor voorbereiden…';

  @override
  String get ideCodeServerOpenInBrowser => 'Editor openen in browser';

  @override
  String get ideCodeServerError => 'Kon de editor niet openen';

  @override
  String get paneSuspendedCaption =>
      'Onderbroken om bronnen te besparen — wordt opnieuw geladen bij focus';

  @override
  String get ideFolderLoadFailed => 'Kon deze map niet laden';

  @override
  String get ideFileSearchFailed => 'Kon bestanden niet doorzoeken';

  @override
  String get ideSearchInFiles => 'In bestanden zoeken';

  @override
  String get ideNoContentMatches => 'Geen overeenkomsten';

  @override
  String get ideSourceControlCreatePr => 'Pull request maken';

  @override
  String ideSourceControlViewPr(int number) {
    return 'Pull request #$number bekijken';
  }

  @override
  String get ideSourceControlNoChanges => 'Geen wijzigingen';

  @override
  String get noReposInConversation => 'Geen repository’s in dit gesprek';

  @override
  String get ideSourceControlNoSpace =>
      'Open een gesprek om de wijzigingen te zien';

  @override
  String get ideFileLoading => 'Laden…';

  @override
  String get ideFileBinary => 'Binair bestand';

  @override
  String get mcpExternalServers => 'Externe MCP-servers';

  @override
  String get mcpExternalServersDescription =>
      'Verbind met externe MCP-servers (GitHub, Sentry, Postgres, browserautomatisering). Servers die je voor Claude, Cursor, VS Code en andere tools hebt geconfigureerd, worden automatisch gedetecteerd.';

  @override
  String get mcpApprovalMode => 'Toolgoedkeuring';

  @override
  String get mcpApprovalModeDescription =>
      'Welke acties zonder vragen worden uitgevoerd. Lezen is altijd toegestaan; hogere niveaus vragen om bevestiging.';

  @override
  String get mcpApprovalAlwaysAsk => 'Altijd vragen';

  @override
  String get mcpApprovalWrite => 'Schrijfacties goedkeuren';

  @override
  String get mcpApprovalYolo => 'Alles goedkeuren';

  @override
  String get mcpNoExternalServers => 'Geen externe MCP-servers gevonden.';

  @override
  String get mcpAuthorize => 'Autoriseren';

  @override
  String get mcpReconnect => 'Opnieuw verbinden';

  @override
  String get mcpExternalConnectionsNote =>
      'Externe MCP-servers draaien op de agentserver (gedeeld door desktop en web). OAuth-servers autoriseren kan alleen op de desktop.';

  @override
  String get mcpStatusConnected => 'Verbonden';

  @override
  String get mcpStatusConnecting => 'Verbinden…';

  @override
  String get mcpStatusNeedsAuth => 'Autorisatie vereist';

  @override
  String get mcpStatusFailed => 'Mislukt';

  @override
  String get mcpStatusCircuitOpen => 'Gepauzeerd';

  @override
  String get mcpStatusDisabled => 'Uitgeschakeld';

  @override
  String get providersAndModels => 'Providers en modellen';

  @override
  String get providersAndModelsDescription =>
      'Toon elke provider die de ingebouwde agent kan gebruiken — stel een API-sleutel in of log in via de browser, bekijk de modellen en prijzen van elke verbonden provider, en bepaal welke providers deze werkruimte mag gebruiken.';

  @override
  String get syncNow => 'Nu synchroniseren';

  @override
  String syncNowResult(int applied, int failed) {
    return 'Synchronisatie voltooid — $applied toegepast, $failed mislukt';
  }

  @override
  String syncNowFailed(String error) {
    return 'Synchronisatie mislukt: $error';
  }

  @override
  String get denied => 'Geweigerd';

  @override
  String get allowed => 'Toegestaan';

  @override
  String allowProviderSemantic(String provider) {
    return '$provider toestaan';
  }

  @override
  String enabledViaEnv(String key) {
    return 'Ingeschakeld via $key';
  }

  @override
  String costPerMillion(String input, String output) {
    return '$input / $output per 1M';
  }

  @override
  String contextTokens(String tokens) {
    return '$tokens context';
  }

  @override
  String get usageAndCost => 'Gebruik en kosten';

  @override
  String get usageAndCostDescription =>
      'Uitgaven van je agents over de laatste 7 dagen, op basis van waargenomen runkosten.';

  @override
  String get noUsageYet => 'Nog geen gebruik geregistreerd.';

  @override
  String get spentThisWeek => 'deze week besteed';

  @override
  String get subscriptionUsage => 'Abonnementsgebruik';

  @override
  String get subscriptionUsageUnavailable => 'Niet beschikbaar';

  @override
  String get subscriptionUsageExhausted => 'Quotum uitgeput';

  @override
  String get subscriptionUsageSignInRequired => 'Meld je opnieuw aan';

  @override
  String get subscriptionUsageSignInExpired =>
      'Aanmelding verlopen, wordt vernieuwd bij de volgende run';

  @override
  String get subscriptionUsagePartiallyAvailable => 'Gedeeltelijk beschikbaar';

  @override
  String resetsIn(String duration) {
    return 'Reset over $duration';
  }

  @override
  String get feedbackHelpful => 'Dit was nuttig';

  @override
  String get feedbackNotHelpful => 'Dit was niet nuttig';

  @override
  String get modeChat => 'Chat';

  @override
  String get modePlan => 'Plan';

  @override
  String get modeReview => 'Review';

  @override
  String get modeOrchestrate => 'Orkestratie';

  @override
  String get editorTheme => 'Editorthema';

  @override
  String get editorThemeDescription =>
      'Importeer een VS Code-kleurthema zodat de ingebouwde diff en editor bij je IDE passen.';

  @override
  String get editorThemePasteHint =>
      'Plak de inhoud van een VS Code-kleurthema-JSON-bestand';

  @override
  String get editorThemeImported => 'Thema geïmporteerd';

  @override
  String get editorThemeInvalid => 'Dit lijkt geen geldig VS Code-thema';

  @override
  String get importTheme => 'Thema importeren';

  @override
  String get clearTheme => 'Thema wissen';

  @override
  String get openInDiffViewer => 'Openen in diff-viewer';

  @override
  String get shellCommand => 'Commando';

  @override
  String get shellOutput => 'Uitvoer';

  @override
  String get revertToHere => 'Terug naar hier';

  @override
  String get revertConfirmBody =>
      'De berichten na dit punt verbergen en de bestandswijzigingen van de agent terugdraaien naar deze beurt? Je kunt dit ongedaan maken.';

  @override
  String get revert => 'Terugzetten';

  @override
  String get revertedToHere => 'Teruggezet naar dit punt';

  @override
  String get nothingToRevert => 'Niets om terug te zetten';

  @override
  String get undoRevert => 'Terugzetten ongedaan maken';

  @override
  String get revertUndone => 'Terugzetten ongedaan gemaakt';

  @override
  String get systemBehavior => 'Systeemgedrag';

  @override
  String get keepAwakeTitle => 'Computer wakker houden terwijl agents draaien';

  @override
  String get keepAwakeOnSubtitle =>
      'De computer gaat niet in slaapstand terwijl een agent werkt';

  @override
  String get keepAwakeOffSubtitle =>
      'De computer kan in slaapstand gaan, zelfs terwijl een agent werkt';

  @override
  String get syncEngineSectionTitle => 'Synchronisatie-engine';

  @override
  String get syncEngineDescription =>
      'Tickets, berichten en notities worden live bijgewerkt via kleine incrementele wijzigingen in plaats van volledige snapshots. Als je een schakelaar uitzet, valt dat onderdeel terug op de volledige-snapshotmodus — herlaad de app om de wijziging door te voeren.';

  @override
  String get syncEngineTicketsTitle => 'Tickets';

  @override
  String get syncEngineMessagingTitle => 'Berichten';

  @override
  String get syncEngineNotesTitle => 'Notities';

  @override
  String get syncEngineOnSubtitle => 'Live delta-synchronisatie is actief';

  @override
  String get syncEngineOffSubtitle =>
      'Volledige-snapshotsynchronisatie wordt gebruikt';

  @override
  String get spaces => 'Ruimtes';

  @override
  String get spacesHomeDescription =>
      'Kies een ruimte uit de lijst of start een nieuwe.';

  @override
  String get noSpacesYet => 'Nog geen ruimtes';

  @override
  String get newSpace => 'Nieuw ruimte';

  @override
  String get spaceName => 'Ruimtenaam';

  @override
  String get spaceReposHint => 'Repo\'s om op te nemen';

  @override
  String get ideSourceControl => 'Broncodebeheer';

  @override
  String get stagedChanges => 'Klaargezette wijzigingen';

  @override
  String get changes => 'Wijzigingen';

  @override
  String get stageFile => 'Klaarzetten';

  @override
  String get unstageFile => 'Klaarzetten ongedaan maken';

  @override
  String get stageAll => 'Alle wijzigingen klaarzetten';

  @override
  String get unstageAll => 'Alles klaarzetten ongedaan maken';

  @override
  String get stageChangesToCommit => 'Zet wijzigingen klaar om te committen';

  @override
  String get syncToPrHead => 'Nieuwste PR-commits ophalen';

  @override
  String get syncedToPrHead => 'Gesynchroniseerd met de nieuwste PR-commits';

  @override
  String get syncPrHeadDirty =>
      'Commit of verwijder je wijzigingen voordat je synchroniseert';

  @override
  String get syncPrHeadFailed => 'Kon niet synchroniseren met de PR';

  @override
  String get spaceLabel => 'Ruimte';

  @override
  String get keybindingNewSpace => 'Nieuw ruimte';

  @override
  String get keybindingCreateANewSpaceDescription => 'Een nieuw ruimte maken';

  @override
  String get jumpToLatest => 'Naar nieuwste';

  @override
  String get streaming => 'Actief';

  @override
  String get newMessages => 'Nieuw';

  @override
  String get copyLink => 'Link kopiëren';

  @override
  String get linkCopied => 'Link gekopieerd';

  @override
  String get agentResponding => 'Agent reageert';

  @override
  String get agentFinished => 'Agent klaar';

  @override
  String get harnessConnectProviderForModels =>
      'Verbind een provider om modellen te zien.';

  @override
  String get providerSignOut => 'Afmelden';

  @override
  String get providerWaitingForDeviceCode =>
      'Wachten tot je de code in je browser bevestigt…';

  @override
  String get providerDeviceCodeHint =>
      'Controleer of deze code overeenkomt met die in je browser en keur hem dan goed.';

  @override
  String get providerPlanUsageLoading => 'Plangebruik controleren…';

  @override
  String get providerPlanUsageUnavailable =>
      'Dit plan heeft geen gebruik gemeld.';

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return '$provider-API-sleutel verwijderen?';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return 'De opgeslagen sleutel wordt verwijderd en kan niet opnieuw worden getoond. Agents die $provider-modellen gebruiken werken pas weer als je een nieuwe plakt.';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return '$provider verwijderen?';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return 'De provider en de opgeslagen sleutel worden verwijderd. Agents die aan zijn modellen zijn gekoppeld werken niet meer.';
  }

  @override
  String get providerApiKeyHint => 'Plak een API-sleutel';

  @override
  String get providerApiKeyStoredHint =>
      'Plak nog een API-sleutel om die toe te voegen';

  @override
  String get providerAddAnotherAccount => 'Nog een account toevoegen';

  @override
  String get providerActiveBadge => 'Actief';

  @override
  String get providerOauthAccountFallback => 'OAuth-account';

  @override
  String get providerApiKeyFallback => 'API-sleutel';

  @override
  String get providerRemoveCredentialConfirmTitle =>
      'Deze inloggegevens verwijderen?';

  @override
  String get providerSignOutAccountConfirmTitle => 'Afmelden bij dit account?';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return 'Agents die $provider gebruiken, vallen terug op de andere sleutels en accounts. Zijn die op, dan stoppen ze totdat je er een toevoegt.';
  }

  @override
  String get providerBaseUrlHint => 'Basis-URL (optioneel)';

  @override
  String get customProvidersDescription =>
      'Elk OpenAI- of Anthropic-compatibel endpoint — Ollama, LM Studio, vLLM of een privé-implementatie — met een optionele API-sleutel.';

  @override
  String get addProvider => 'Provider toevoegen';

  @override
  String get noCustomProviders => 'Nog geen aangepaste providers.';

  @override
  String get providerNameLabel => 'Naam';

  @override
  String get apiTypeLabel => 'API-type';

  @override
  String get providerBaseUrlLabel => 'Basis-URL';

  @override
  String get providerApiKeyOptionalHint => 'API-sleutel (optioneel)';

  @override
  String get dialectOpenAiCompatible => 'Compatibel met OpenAI';

  @override
  String get dialectAnthropicCompatible => 'Compatibel met Anthropic';

  @override
  String get removeProviderTooltip => 'Provider verwijderen';

  @override
  String get providerLogInWithBrowser => 'Inloggen via browser';

  @override
  String providerLoginDialogTitle(String provider) {
    return 'Inloggen bij $provider';
  }

  @override
  String get providerLabel => 'Provider';

  @override
  String get selectProviderToLogin => 'Selecteer een provider om in te loggen';

  @override
  String providerLoginFailed(String error) {
    return 'Inloggen mislukt: $error';
  }

  @override
  String get providerWaitingForBrowser =>
      'Wachten tot je autoriseert in de browser…';

  @override
  String get providerPasteCodeHint => 'Of plak de code uit je browser';

  @override
  String get providerCompleteLogin => 'Voltooien';

  @override
  String get providerConnectedApiKey => 'Verbonden via API-sleutel';

  @override
  String get providerConnectedOauth => 'Verbonden';

  @override
  String providerConnectedAccount(String account) {
    return 'Verbonden · $account';
  }

  @override
  String get providerLocalReady => 'Lokaal · gereed';

  @override
  String get providerNotConnected => 'Niet verbonden';

  @override
  String get preparingWorkspace => 'Werkruimte voorbereiden…';

  @override
  String provisioningRunningSetupScript(String repo) {
    return 'Installatiescript voor $repo wordt uitgevoerd…';
  }

  @override
  String get repoScriptsTitle => 'Scripts';

  @override
  String get repoScriptsTooltip => 'Levenscyclusscripts configureren';

  @override
  String get repoScriptsSetupLabel => 'Installatiescript';

  @override
  String get repoScriptsSetupHelp =>
      'Draait direct na het aanmaken in de worktree van de ruimte — dependencies installeren, bestanden genereren. Bij een fout wordt de ruimte als mislukt gemarkeerd; opnieuw proberen draait het weer.';

  @override
  String get repoScriptsArchiveLabel => 'Archiveringsscript';

  @override
  String get repoScriptsArchiveHelp =>
      'Draait vlak voordat de worktree van een ruimte wordt verwijderd — ruimt bronnen buiten de worktree op. Een fout blokkeert het verwijderen nooit.';

  @override
  String get repoScriptsEnvHelp =>
      'Draait via bash vanuit de worktree, met CC_WORKSPACE_PATH (de worktree), CC_ROOT_PATH (de repo-root), CC_SPACE_ID, CC_SPACE_NAME en CC_REPO_NAME ingesteld.';

  @override
  String get repoScriptsSetupPlaceholder => 'bijv. pnpm install';

  @override
  String get repoScriptsArchivePlaceholder =>
      'bijv. docker compose -p \$CC_SPACE_ID down';

  @override
  String get repoScriptsRecentRuns => 'Recente uitvoeringen';

  @override
  String get repoScriptsNoRuns => 'Nog geen uitvoeringen';

  @override
  String get repoScriptsOutput => 'Uitvoer';

  @override
  String get repoScriptsSaved => 'Scripts opgeslagen';

  @override
  String get repoScriptsRunKindSetup => 'Installatie';

  @override
  String get repoScriptsRunKindArchive => 'Archivering';

  @override
  String get repoScriptsRunStatusRunning => 'Bezig';

  @override
  String get repoScriptsRunStatusSucceeded => 'Geslaagd';

  @override
  String get repoScriptsRunStatusFailed => 'Mislukt';

  @override
  String get repoScriptsRunStatusTimedOut => 'Verlopen';

  @override
  String repoScriptsExitCode(int code) {
    return 'Exitcode $code';
  }

  @override
  String provisioningCloningRepo(String repo) {
    return '$repo klonen…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return 'Pull request uitchecken in $repo…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return 'Agent $agent instellen…';
  }

  @override
  String get workspacePrepFailed => 'Instellen mislukt';

  @override
  String get workspacePrepStopped => 'Instellen gestopt';

  @override
  String get stopWorkspacePrep => 'Instellen stoppen';

  @override
  String get stopWorkspacePrepTooltip =>
      'Het instellen van deze werkruimte stoppen';

  @override
  String get stopWorkspacePrepConfirm =>
      'Het instellen van deze werkruimte stoppen? De lopende kloon wordt weggegooid — je kunt het hier opnieuw starten.';

  @override
  String messageWillSendWhenReady(int count) {
    return '$count bericht(en) verzonden wanneer klaar';
  }

  @override
  String get membersNav => 'Leden';

  @override
  String get membersSettingsDescription =>
      'Mensen met toegang tot deze werkruimte: overzicht, uitnodigingen en auditlogboek';

  @override
  String get memberRosterLabel => 'Ledenlijst';

  @override
  String get memberRepoAccessAction => 'Toegang tot repository\'s';

  @override
  String memberRepoAccessTitle(String name) {
    return 'Toegang tot repository\'s van $name';
  }

  @override
  String get roleOwner => 'Eigenaar';

  @override
  String get roleAdmin => 'Beheerder';

  @override
  String get roleMember => 'Lid';

  @override
  String get roleViewer => 'Kijker';

  @override
  String get roleGuest => 'Gast';

  @override
  String get removeMemberTitle => 'Lid verwijderen';

  @override
  String removeMemberConfirm(String name) {
    return '$name uit deze werkruimte verwijderen? De toegang vervalt direct.';
  }

  @override
  String get transferOwnershipAction => 'Eigenaarschap overdragen';

  @override
  String get transferOwnershipTitle => 'Eigenaarschap overdragen';

  @override
  String transferOwnershipConfirm(String name) {
    return '$name eigenaar van deze werkruimte maken? Je wordt beheerder. Alleen een eigenaar kan de werkruimte verwijderen of de rol van een andere beheerder wijzigen.';
  }

  @override
  String get transferOwnershipCta => 'Overdragen';

  @override
  String get auditTrailLabel => 'Auditlogboek van autorisaties';

  @override
  String get auditTrailDescription =>
      'Elke toestemming en elke weigering, aan elkaar gehasht: een gewijzigde of verwijderde regel is detecteerbaar.';

  @override
  String get auditVerifyChain => 'Keten verifiëren';

  @override
  String auditChainIntact(int count) {
    return 'Keten intact — $count regels geverifieerd';
  }

  @override
  String auditChainBroken(int seq, String reason) {
    return 'Keten verbroken bij regel $seq: $reason';
  }

  @override
  String get auditEmpty => 'Nog geen beslissingen vastgelegd.';

  @override
  String get auditDenied => 'Geweigerd';

  @override
  String get auditAllowed => 'Toegestaan';

  @override
  String auditOnBehalfOf(String user) {
    return 'voor $user';
  }

  @override
  String get policyTemplatesLabel => 'Beleidssjablonen';

  @override
  String get policyTemplatesDescription =>
      'Pas een startconfiguratie toe of verplaats die tussen werkruimtes.';

  @override
  String get policyTemplateStrict => 'Strikt';

  @override
  String get policyTemplateBalanced => 'Gebalanceerd';

  @override
  String get policyTemplatePermissive => 'Ruim';

  @override
  String get policyTemplateApply => 'Toepassen';

  @override
  String policyTemplateApplied(int count) {
    return '$count regels toegepast';
  }

  @override
  String get policyExport => 'Beleid kopiëren';

  @override
  String get policyExported => 'Beleid naar het klembord gekopieerd';

  @override
  String get policyImport => 'Beleid plakken';

  @override
  String policyImported(int count) {
    return '$count regels geïmporteerd';
  }

  @override
  String get approveAndRemember => 'Goedkeuren voor 8 uur';

  @override
  String get approveAndRememberTooltip =>
      'Keurt deze actie goed en vraagt 8 uur lang niet meer naar vergelijkbare acties in deze ruimte. Verloopt vanzelf.';

  @override
  String get unknownUserLabel => 'Onbekende gebruiker';

  @override
  String get inviteMember => 'Lid uitnodigen';

  @override
  String get inviteRepoAccessHeader => 'Toegang tot repository\'s';

  @override
  String get inviteRepoAccessExplainer =>
      'Alleen de aangevinkte repository\'s worden gedeeld met de genodigde, op het gekozen niveau. Al het andere blijft verborgen.';

  @override
  String get grantLevelRead => 'Lezen';

  @override
  String get grantLevelReview => 'Review';

  @override
  String get grantLevelWrite => 'Schrijven';

  @override
  String get inviteExpiryLabel => 'Verloopt over';

  @override
  String get expiryOneDay => '1 dag';

  @override
  String get expirySevenDays => '7 dagen';

  @override
  String get expiryThirtyDays => '30 dagen';

  @override
  String get createInviteAction => 'Uitnodiging aanmaken';

  @override
  String get inviteOneTimeCodeLabel => 'Eenmalige code';

  @override
  String get inviteCodeShownOnce =>
      'Deze code wordt maar één keer getoond — kopieer hem nu.';

  @override
  String get inviteLinkLabel => 'Uitnodigingslink';

  @override
  String get inviteRedeemHint =>
      'Deel de code met de genodigde; die wisselt hem in via je server-URL.';

  @override
  String get inviteScanQr => 'Of scan om in te wisselen';

  @override
  String get inviteLoopbackWarningTitle =>
      'De uitnodiging verwijst naar een lokaal adres';

  @override
  String get inviteLoopbackWarningBody =>
      'Medewerkers op andere machines kunnen deze server niet bereiken. Start een tunnel (Instellingen → Integraties → Deze server delen) of verbind met uw netwerk zodat externe gebruikers kunnen verbinden.';

  @override
  String get inviteStatusOpen => 'Open';

  @override
  String get inviteStatusUsed => 'Gebruikt';

  @override
  String get inviteStatusRevoked => 'Ingetrokken';

  @override
  String get inviteStatusExpired => 'Verlopen';

  @override
  String inviteCreatedTime(String time) {
    return 'Aangemaakt $time';
  }

  @override
  String inviteExpiresOn(String date) {
    return 'verloopt op $date';
  }

  @override
  String get noActivityYet => 'Nog geen activiteit';

  @override
  String get couldNotLoadMembers => 'Kan leden niet laden';

  @override
  String get couldNotLoadInvites => 'Kan uitnodigingen niet laden';

  @override
  String get couldNotLoadActivity => 'Kan activiteit niet laden';

  @override
  String get yourDevices => 'Je apparaten';

  @override
  String get yourDevicesDescription =>
      'Clients gekoppeld aan je account op deze server.';

  @override
  String get noOwnDevices =>
      'Er zijn nog geen apparaten aan je account gekoppeld';

  @override
  String get renameDeviceTitle => 'Apparaat hernoemen';

  @override
  String get revokeDeviceTitle => 'Apparaat intrekken';

  @override
  String revokeDeviceConfirm(String label) {
    return '$label intrekken? Het wordt direct losgekoppeld en kan deze server niet meer bereiken.';
  }

  @override
  String devicePairedTime(String time) {
    return 'Gekoppeld $time';
  }

  @override
  String deviceLastSeenTime(String time) {
    return 'Laatst gezien $time';
  }

  @override
  String get deviceNeverSeen => 'Nooit verbonden';

  @override
  String get profileSectionLabel => 'Profiel';

  @override
  String get profileSectionDescription =>
      'Hoe je verschijnt voor teamgenoten en in git-commit-auteurschap.';

  @override
  String get displayNameLabel => 'Weergavenaam';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get gitAuthorNameLabel => 'Git-auteursnaam';

  @override
  String get gitAuthorEmailLabel => 'Git-auteurs-e-mail';

  @override
  String get profileSaved => 'Profiel opgeslagen';

  @override
  String get presenceOnline => 'Online';

  @override
  String get presenceIdle => 'Inactief';

  @override
  String get presenceTyping => 'Typt…';

  @override
  String get presenceAgentThinking => 'Denkt na';

  @override
  String get presenceAgentRunning => 'Actief';

  @override
  String get presenceAgentBlocked => 'Geblokkeerd';

  @override
  String get presenceAgentDone => 'Klaar';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String presenceNameStatusCost(String name, String status, String cost) {
    return '$name — $status ($cost)';
  }

  @override
  String get presenceRailLabel => 'Wie is online';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => 'Niet storen inschakelen';

  @override
  String get dndTooltipOff => 'Niet storen uitschakelen';

  @override
  String get startPresenting => 'Presentatie starten';

  @override
  String get stopPresenting => 'Presentatie stoppen';

  @override
  String spotlightPresentingBanner(String name) {
    return '$name presenteert';
  }

  @override
  String get spotlightLeave => 'Verlaten';

  @override
  String typingIndicator(String name) {
    return '$name is aan het typen…';
  }

  @override
  String get ideTabNotes => 'Notities';

  @override
  String get ideSidebarAllViews => 'Alle weergaven';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return 'Alle weergaven ($count verborgen)';
  }

  @override
  String get ideSidebarPinView => 'Vastmaken aan zijbalk';

  @override
  String get ideSidebarUnpinView => 'Losmaken van zijbalk';

  @override
  String get notesEmptyHint =>
      'Voeg een notitie toe voor iedereen die dit gesprek overneemt…';

  @override
  String get notesEditTooltip => 'Notitie bewerken';

  @override
  String notesUpdatedBy(String name, String time) {
    return 'Bijgewerkt door $name · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '$name is aan het bewerken';
  }

  @override
  String get notesSaveFailed => 'Notitie kon niet worden opgeslagen';

  @override
  String get reactionAddTooltip => 'Reactie toevoegen';

  @override
  String reactionToggleTooltip(String emoji) {
    return 'Reageren met $emoji';
  }

  @override
  String get autonomyDialLabel => 'Autonomie';

  @override
  String get autonomyProposeOnly => 'Alleen voorstellen';

  @override
  String get autonomyActWithApproval => 'Handelen met goedkeuring';

  @override
  String get autonomyActFreely => 'Vrij handelen';

  @override
  String get autonomyDefaultOption => 'Standaard';

  @override
  String get checkerLabel => 'Controleur';

  @override
  String get checkerNone => 'Geen';

  @override
  String get checkerCaption =>
      'De controleur beoordeelt voltooide runs van andere agents.';

  @override
  String get takeoverTooltip => 'Werkmap overnemen';

  @override
  String get takeoverBannerSelf =>
      'Je hebt de werkmap van dit gesprek overgenomen';

  @override
  String takeoverBannerOther(String name) {
    return '$name heeft de werkmap van dit gesprek overgenomen';
  }

  @override
  String get handBackButton => 'Teruggeven';

  @override
  String get handBackDialogTitle => 'Werkmap teruggeven';

  @override
  String get handBackDialogNoteHint => 'Optionele notitie voor de agent…';

  @override
  String takeoverFailed(String message) {
    return 'Overnemen mislukt: $message';
  }

  @override
  String handBackFailed(String message) {
    return 'Teruggeven mislukt: $message';
  }

  @override
  String get planStudioTitle => 'Planstudio';

  @override
  String get plansTitle => 'Plannen';

  @override
  String get plansSubtitle => 'Actieve plannen, plandocumenten en playbooks';

  @override
  String get plansActiveSection => 'Actieve plannen';

  @override
  String get plansDocumentsSection => 'Plandocumenten';

  @override
  String get plansPlaybooksSection => 'Playbooks';

  @override
  String get plansNoActive => 'Nog geen actieve plannen.';

  @override
  String get plansNoDocuments => 'Nog geen plandocumenten.';

  @override
  String get plansNoPlaybooks => 'Nog geen playbooks.';

  @override
  String get planNotFound => 'Plan niet gevonden.';

  @override
  String get planOpenInStudio => 'Openen';

  @override
  String get planNodeTitle => 'Titel';

  @override
  String get planNodeDescription => 'Beschrijving';

  @override
  String get planNodeDescriptionHint => 'Wat deze stap moet doen…';

  @override
  String get planNodeApplyDescription => 'Toepassen';

  @override
  String get planNodeRole => 'Rol';

  @override
  String get planNodeDependencies => 'Hangt af van';

  @override
  String get planNodeDependenciesHint => 'Afhankelijkheid toevoegen';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count afhankelijkheden',
      one: '1 afhankelijkheid',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies =>
      'Geen afhankelijkheden, start zodra het plan begint';

  @override
  String get planNodeOutputSchema => 'Uitvoerschema (JSON)';

  @override
  String get planNodeEstimate => 'Schatting';

  @override
  String get planNodeProvenance => 'Herkomst';

  @override
  String get planNodeAlreadyExecuted =>
      'Al uitgevoerd — bewerken vertakt het plan vanaf hier.';

  @override
  String get planNewNodeTitle => 'Nieuwe stap';

  @override
  String get planEstimateNoHistory => 'Nog geen geschiedenis';

  @override
  String get planEstimateBlastUnknown => 'Impactstraal: onbekend';

  @override
  String get planEstimatePartial => 'gedeeltelijk';

  @override
  String get planEstimateAction => 'Schatten';

  @override
  String planEstimateDuration(String range) {
    return 'Duur $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return 'Impactstraal: $files bestanden, $symbols symbolen';
  }

  @override
  String get planApprove => 'Plan goedkeuren';

  @override
  String get planApproveSelectedNodes => 'Selectie goedkeuren';

  @override
  String get planReject => 'Afwijzen';

  @override
  String get planCancel => 'Uitvoering annuleren';

  @override
  String get planContinueNode => 'Knooppunt hervatten';

  @override
  String get planTotalNotEstimated => 'Nog niet geschat';

  @override
  String get planBudgetExceeded => 'boven budget';

  @override
  String planBudgetCeiling(String amount) {
    return 'budget ≤ $amount \$';
  }

  @override
  String get planVersionsTitle => 'Versies';

  @override
  String get planNoRevisions => 'Nog geen revisies.';

  @override
  String get planDiffIdentical => 'Geen wijzigingen.';

  @override
  String get planDiffGoalChanged => 'Doel gewijzigd';

  @override
  String get planDiffBudgetChanged => 'Budget gewijzigd';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'Wijzigingen van v$fromRev naar v$toRev';
  }

  @override
  String planDiffAdded(String node) {
    return 'Toegevoegd $node';
  }

  @override
  String planDiffRemoved(String node) {
    return 'Verwijderd $node';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return 'Gewijzigd $node: $fields';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return 'Rand toegevoegd: $edge';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return 'Rand verwijderd: $edge';
  }

  @override
  String planDiffRoleAdded(String role) {
    return 'Rol toegevoegd: $role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return 'Rol verwijderd: $role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return 'Rol opnieuw toegewezen: $role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return 'Plan opnieuw gepland: je keurde v$approved goed, nu v$current. Bekijk de verschillen.';
  }

  @override
  String planLiveActualCost(String amount) {
    return 'Werkelijke kosten: $amount \$';
  }

  @override
  String get planPlaybookRun => 'Uitvoeren';

  @override
  String get planPlaybookDelete => 'Playbook verwijderen';

  @override
  String get planPlaybookProposed =>
      'Plan voorgesteld — keur het goed in Planstudio.';

  @override
  String get planPlaybookAnchorTicket => 'Anker-ticket';

  @override
  String get planPlaybookPickTicket => 'Kies een ticket…';

  @override
  String get planPlaybookProposeRun => 'Plan voorstellen';

  @override
  String get planPlaybookRepoHint => 'Een repository-id';

  @override
  String get planPlaybookAgentHint => 'Een agent-id';

  @override
  String planPlaybookRunTitle(String name) {
    return '$name uitvoeren';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '$count parameters';
  }

  @override
  String get recentLabel => 'Recent';

  @override
  String get cheatSheetTitle => 'Sneltoetsen';

  @override
  String get cheatSheetGlobal => 'Globaal';

  @override
  String get cheatSheetThisScreen => 'Dit scherm';

  @override
  String get cheatSheetReservedInBrowser => 'Gereserveerd door browser';

  @override
  String get keybindingCheatSheet => 'Sneltoetsen';

  @override
  String get keybindingShowKeyboardShortcutsDescription =>
      'Het sneltoetsenoverzicht voor het huidige scherm tonen';

  @override
  String get runPlaybookLabel => 'Playbook uitvoeren';

  @override
  String get playbooksLabel => 'Playbooks';

  @override
  String get keybindingUndo => 'Ongedaan maken';

  @override
  String get keybindingRedo => 'Opnieuw';

  @override
  String get keybindingUndoLastActionDescription =>
      'Je laatste omkeerbare actie ongedaan maken';

  @override
  String get keybindingRedoLastActionDescription =>
      'De laatst ongedaan gemaakte actie opnieuw uitvoeren';

  @override
  String get undone => 'Ongedaan gemaakt';

  @override
  String get redone => 'Opnieuw uitgevoerd';

  @override
  String get undoFailed => 'Kan niet ongedaan maken';

  @override
  String get undoLabelTicketEdit => 'ticketbewerking';

  @override
  String get undoLabelMessageEdit => 'berichtbewerking';

  @override
  String get undoLabelTodoStatus => 'taakstatus';

  @override
  String get inboxTitle => 'Postvak in';

  @override
  String get inboxReview => 'Beoordelen';

  @override
  String get inboxOpen => 'Openen';

  @override
  String get inboxAllCaughtUp => 'Je bent helemaal bij';

  @override
  String get inboxGitHubDownTitle => 'GitHub is mogelijk offline';

  @override
  String inboxGitHubDownBody(String status) {
    return 'GitHub meldt: $status. Er kunnen dus pull requests in deze lijst ontbreken in plaats van echt afgerond te zijn.';
  }

  @override
  String get inboxGitHubIdentityTitle =>
      'Kon je GitHub-account niet bevestigen';

  @override
  String get inboxGitHubIdentityBody =>
      'De inbox is gesorteerd op wie je bent op GitHub. Zolang dat niet is geladen blijft de lijst leeg, ook als er pull requests op je wachten.';

  @override
  String get inboxSeverityBlocking => 'Geblokkeerd';

  @override
  String get inboxSeverityWaiting => 'Wachtend';

  @override
  String get inboxSeverityInfo => 'Info';

  @override
  String get inboxSyncFailed => 'Synchronisatie mislukt';

  @override
  String get inboxNeedsYourAttention => 'Vraagt je aandacht';

  @override
  String get inboxSectionNeedsYourReview => 'Wacht op jouw review';

  @override
  String get inboxSectionReturnedToYou => 'Terug naar jou';

  @override
  String get inboxSectionApproved => 'Goedgekeurd';

  @override
  String get inboxSectionDrafts => 'Concepten';

  @override
  String get inboxSectionWaitingForReviewers => 'Wacht op reviewers';

  @override
  String get inboxSectionMergingAndMerged =>
      'Bezig met mergen en recent gemerged';

  @override
  String get inboxSectionWaitingForAuthor => 'Wacht op de auteur';

  @override
  String get inboxColumnTitle => 'Titel';

  @override
  String get inboxColumnChanges => 'Wijzigingen';

  @override
  String get inboxColumnUpdated => 'Bijgewerkt';

  @override
  String get inboxReviewApproved => 'Goedgekeurd';

  @override
  String get inboxReviewChangesRequested => 'Wijzigingen gevraagd';

  @override
  String get inboxHeroSubtitle =>
      'Elke pull request die jou aangaat, gesorteerd op wat hierna komt.';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requests wachten op jouw review',
      one: '1 pull request wacht op jouw review',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count terug bij jou',
      one: '1 terug bij jou',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted =>
      'Die wijziging is niet opgeslagen en teruggedraaid';

  @override
  String get offlinePendingLabel => 'in behandeling';

  @override
  String get offlineSyncingLabel => 'synchroniseren';

  @override
  String get copyLinkLabel => 'Link naar deze pagina kopiëren';

  @override
  String get agentsSectionLabel => 'Agenten';

  @override
  String get fleetWorkersTitle => 'Workers';

  @override
  String get fleetWorkersSubtitle =>
      'Machines beschikbaar om taken uit te voeren';

  @override
  String get fleetJobsTitle => 'Jobs';

  @override
  String get fleetJobsSubtitle => 'Werk verdeeld over de vloot';

  @override
  String get fleetNoWorkers =>
      'Nog geen workers — een tweede machine die `cc_worker --server <url>` draait, sluit zich aan bij de vloot.';

  @override
  String get fleetNoJobs => 'Geen jobs.';

  @override
  String get fleetError => 'Kan de vloot niet laden';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cores',
      one: '1 core',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return 'Hartslag $time';
  }

  @override
  String get fleetNoHeartbeat => 'Nog geen hartslag';

  @override
  String fleetLastErrorLabel(String error) {
    return 'Laatste fout: $error';
  }

  @override
  String get fleetDrain => 'Leegmaken';

  @override
  String get fleetResume => 'Hervatten';

  @override
  String get fleetRevoke => 'Intrekken';

  @override
  String get fleetRemove => 'Verwijderen';

  @override
  String get fleetRevokeTitle => 'Worker intrekken?';

  @override
  String fleetRevokeBody(String name) {
    return '$name intrekken? De sessie eindigt en actieve jobs worden opnieuw toegewezen.';
  }

  @override
  String get fleetRemoveTitle => 'Worker verwijderen?';

  @override
  String fleetRemoveBody(String name) {
    return '$name uit de vloot verwijderen? Hiermee wordt het record verwijderd.';
  }

  @override
  String get fleetActionFailed => 'Actie mislukt';

  @override
  String get fleetJobUnassigned => 'Niet toegewezen';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '$attempts/$max pogingen';
  }

  @override
  String get fleetPlacementReasons => 'Plaatsingsbeslissingen';

  @override
  String get fleetNoPlacements => 'Nog geen plaatsingsbeslissingen.';

  @override
  String get fleetStatusOnline => 'Online';

  @override
  String get fleetStatusDraining => 'Leegmaken';

  @override
  String get fleetStatusOffline => 'Offline';

  @override
  String get fleetStatusIncompatible => 'Incompatibel';

  @override
  String get fleetStatusRevoked => 'Ingetrokken';

  @override
  String get fleetJobStatusQueued => 'In wachtrij';

  @override
  String get fleetJobStatusRunning => 'Actief';

  @override
  String get fleetJobStatusSucceeded => 'Geslaagd';

  @override
  String get fleetJobStatusFailed => 'Mislukt';

  @override
  String get fleetJobStatusCancelled => 'Geannuleerd';

  @override
  String get evalsNoSuites => 'Nog geen evaluatiesuites.';

  @override
  String get evalsError => 'Kan evaluaties niet laden';

  @override
  String get evalsStarterBadge => 'Starter';

  @override
  String evalsDefaultBatch(int count) {
    return 'Standaardbatch van $count';
  }

  @override
  String get evalsRecentRuns => 'Recente runs';

  @override
  String get evalsNoRuns => 'Nog geen runs.';

  @override
  String get evalsPassRate => 'Slagingspercentage';

  @override
  String evalsBatchTimes(int count) {
    return '× $count';
  }

  @override
  String evalsTriggeredBy(String who) {
    return 'door $who';
  }

  @override
  String evalsRunFinished(String rate) {
    return 'Evaluatie voltooid — $rate geslaagd';
  }

  @override
  String get evalsRunFailed => 'Kan de suite niet uitvoeren';

  @override
  String get evalsRun => 'Uitvoeren';

  @override
  String get evalsStatusQueued => 'In wachtrij';

  @override
  String get evalsStatusRunning => 'Actief';

  @override
  String get evalsStatusPassed => 'Geslaagd';

  @override
  String get evalsStatusFailed => 'Mislukt';

  @override
  String get bannerMeetingJoin => 'Deelnemen';

  @override
  String get bannerMeetingRecordAndLink => 'Opnemen en koppelen';

  @override
  String get bannerCalendarReconnect => 'Opnieuw verbinden';

  @override
  String get bannerView => 'Weergeven';

  @override
  String get soundscapeTitle => 'Klanklandschappen';

  @override
  String get soundscapePlay => 'Afspelen';

  @override
  String get soundscapePause => 'Pauzeren';

  @override
  String get soundscapeMoodLabel => 'Sfeer';

  @override
  String get soundscapeMoodFocus => 'Focus';

  @override
  String get soundscapeMoodRelax => 'Ontspanning';

  @override
  String get soundscapeMoodSleep => 'Slaap';

  @override
  String get soundscapeVolumeLabel => 'Volume';

  @override
  String get soundscapeTuneLabel => 'Afstemming';

  @override
  String get soundscapeTuneMellow => 'Zacht';

  @override
  String get soundscapeTuneBright => 'Helder';

  @override
  String get soundscapeTuneEnergetic => 'Energiek';

  @override
  String get soundscapeTuneSpacy => 'Ruimtelijk';

  @override
  String get soundscapeTuneResetHint => 'Dubbeltik om te herstellen';

  @override
  String get soundscapeSceneLabel => 'Speelt nu af';

  @override
  String get soundscapeSceneLoading => 'De sfeer wordt afgestemd…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees °C';
  }

  @override
  String get soundscapeLocationLabel => 'Locatie';

  @override
  String get soundscapeLocationDetecting => 'Locatie detecteren…';

  @override
  String get soundscapeLocationAutoNote =>
      'De locatie wordt automatisch gedetecteerd op basis van deze werkruimte.';

  @override
  String get soundscapeRefreshWeather => 'Weer vernieuwen';

  @override
  String get soundscapeAutoStartLabel => 'Starten met focusmodus';

  @override
  String get soundscapeAutoStartDescription =>
      'Speel automatisch een klanklandschap af wanneer je een focussessie start.';

  @override
  String get soundscapeReturnToApp => 'Terug naar app';

  @override
  String get soundscapePopOut => 'Speler losmaken';

  @override
  String get discussion => 'Discussie';

  @override
  String get chat => 'Chat';

  @override
  String get saving => 'Opslaan…';

  @override
  String get saved => 'Opgeslagen';

  @override
  String get saveFailed => 'Opslaan mislukt';

  @override
  String get commitAndPush => 'Committen & pushen';

  @override
  String get commit => 'Committen';

  @override
  String get commitAmend => 'Committen (wijzigen)';

  @override
  String get commitAndSync => 'Committen & synchroniseren';

  @override
  String get committed => 'Gecommit';

  @override
  String get commitAmended => 'Commit gewijzigd';

  @override
  String get commitFailed => 'Committen mislukt';

  @override
  String get moreCommitActions => 'Meer commit-acties';

  @override
  String get sourceControl => 'Broncodebeheer';

  @override
  String fixFindingTitle(String location) {
    return 'Herstellen: $location';
  }

  @override
  String get openInEditor => 'Openen in editor';

  @override
  String get commitMessageHint => 'Commitbericht';

  @override
  String get pushedToPr => 'Naar de PR gepusht';

  @override
  String get pushFailed => 'Pushen mislukt';

  @override
  String get reviewFindings => 'Bevindingen';

  @override
  String get treeLabel => 'Structuur';

  @override
  String get toggleFileTree => 'Bestandsboom tonen of verbergen';

  @override
  String get diffViewSettings => 'Diff-weergave-instellingen';

  @override
  String get splitViewLabel => 'Gesplitst';

  @override
  String get unifiedViewLabel => 'Samengevoegd';

  @override
  String get wrapLines => 'Regelterugloop';

  @override
  String get shiftClickSelectRange => 'Shift-klik om een bereik te selecteren';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden',
      one: '1 bestand',
    );
    return '$_temp0';
  }

  @override
  String prComplexityLoc(String loc) {
    return '$loc LOC';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return 'Kleine PR — $files, ~$minutes min review';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return 'Middelgrote PR — $files, reserveer ~$minutes min review';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return 'Grote PR — $files, overweeg te splitsen voor de review';
  }

  @override
  String get searchInFiles => 'Zoeken in bestanden';

  @override
  String get showFileList => 'Bestandenlijst tonen';

  @override
  String get searchInFilesHintField => 'Zoeken in bestanden…';

  @override
  String get searchInFilesHint => 'Zoeken in de bestanden van de pull request';

  @override
  String get searchNoResults => 'Geen resultaten';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultaten',
      one: '1 resultaat',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files bestanden',
      one: '1 bestand',
    );
    return '$_temp0 in $_temp1';
  }

  @override
  String get discardChangesTitle => 'Wijzigingen verwerpen?';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden',
      one: '1 bestand',
    );
    return '$_temp0 terugzetten naar HEAD? Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String get discardAll => 'Alles verwerpen';

  @override
  String get discardFailed => 'Wijzigingen konden niet worden verworpen';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden verworpen',
      one: '1 bestand verworpen',
    );
    return '$_temp0';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '$reverted bestanden verworpen',
      one: '1 bestand verworpen',
    );
    return '$_temp0; $skipped overgeslagen (niet gevolgd)';
  }

  @override
  String get prWorktreeUnavailable => 'Werkruimte niet gereed';

  @override
  String get prWorktreeUnavailableHint =>
      'Het voorbereiden van de bestanden van de pull request is mislukt. Open de pull request opnieuw om het nog eens te proberen.';

  @override
  String get timestampRelativeLabel => 'Relatief';

  @override
  String get timestampRawLabel => 'Tijdstempel';

  @override
  String get copyTimestamp => 'Tijdstempel kopiëren';

  @override
  String get copiedTimestamp => 'Tijdstempel gekopieerd';

  @override
  String get previewDeployment => 'Preview-implementatie';

  @override
  String previewDeploymentTab(String site) {
    return 'Preview: $site';
  }

  @override
  String get askForReview => 'Review vragen…';

  @override
  String get closePrsConfirmTitle => 'Pull requests sluiten?';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requests sluiten?',
      one: '1 pull request sluiten?',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requests gesloten',
      one: '1 pull request gesloten',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requests toegewezen',
      one: '1 pull request toegewezen',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Review gevraagd voor $count pull requests',
      one: 'Review gevraagd voor 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count acties mislukt',
      one: '1 actie mislukt',
    );
    return '$_temp0';
  }

  @override
  String get diagram => 'Diagram';

  @override
  String get diagramViewSource => 'Bron weergeven';

  @override
  String get diagramHideSource => 'Bron verbergen';

  @override
  String diagramPreviewUnavailable(String reason) {
    return 'Diagramvoorbeeld niet beschikbaar ($reason)';
  }

  @override
  String get planUnavailable => 'Plan niet beschikbaar';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stappen',
      one: '1 stap',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => 'Goedkeuren en uitvoeren';

  @override
  String get planStatusDraft => 'Concept';

  @override
  String get planStatusProposed => 'Plan';

  @override
  String get planStatusApproved => 'Plan goedgekeurd';

  @override
  String get planStatusRejected => 'Plan afgewezen';

  @override
  String get planStatusSuperseded => 'Plan vervangen';

  @override
  String planRevisionLabel(int revision) {
    return 'Revisie $revision';
  }

  @override
  String get adapterEnforcementTitle => 'Wat deze adapter afdwingt';

  @override
  String get enforcementFiltersToolSurface => 'Control Center kiest de tools';

  @override
  String get enforcementInterceptsToolCalls =>
      'Elke aanroep wordt vóór uitvoering gecontroleerd';

  @override
  String get enforcementObservesCompletionContract =>
      'De run wordt aan zijn oplevering gehouden';

  @override
  String get enforcementNativeToolsInterceptable =>
      'De eigen tools van de runner zijn zichtbaar';

  @override
  String get enforcementInProcessToolsSandboxed =>
      'Tools in het proces staan in de sandbox';

  @override
  String get enforcementYes => 'Ja';

  @override
  String get enforcementNo => 'Nee';

  @override
  String get adapterEnforcementCaveats => 'Voorbehouden';

  @override
  String get enforcementSummaryModesEnforced => 'Modi afgedwongen';

  @override
  String get enforcementSummaryModesNotEnforced => 'Modi niet afgedwongen';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voorbehouden',
      one: '1 voorbehoud',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      'Alleen-lezen modi zijn niet structureel: Control Center kan de eigen tools van deze runner niet verwijderen.';

  @override
  String get caveatToolCallsNotIntercepted =>
      'Geen controle vóór uitvoering: alleen MCP-toolaanroepen gaan via Control Center.';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      'De eigen bestands- en shell-tools van de runner bereiken Control Center nooit; de sandbox van het systeem is hun enige grens.';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      'Bestandstools in het proces lopen buiten de sandbox, dus het toolaanbod is de enige grens naar het bestandssysteem.';

  @override
  String get caveatCompletionContractUnobservable =>
      'Control Center kan een run die zonder oplevering eindigt niet aansporen of laten falen.';

  @override
  String get modeDegraded => 'Beperkt';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return 'De modus $mode op $adapter vertrouwt alleen op de sandbox; de eigen bestandstools van de agent worden niet onderschept.';
  }

  @override
  String get artifactUnavailable => 'Artefact niet beschikbaar';

  @override
  String artifactRevisionLabel(int count) {
    return '$count revisies';
  }

  @override
  String get artifactShowMore => 'Meer weergeven';

  @override
  String get artifactShowLess => 'Minder weergeven';

  @override
  String get artifactCopy => 'Kopiëren';

  @override
  String get artifactCopied => 'Artefact gekopieerd';

  @override
  String get artifactsTabLabel => 'Artefacten';

  @override
  String get artifactsEmptyTitle => 'Nog geen artefacten';

  @override
  String get artifactsEmptyBody =>
      'Wanneer een agent hier een tabel, diagram of grafiek publiceert, verschijnt die in deze lijst.';

  @override
  String get artifactRevisionPickerLabel => 'Revisie';

  @override
  String get artifactRestoreRevision => 'Deze revisie herstellen';

  @override
  String get artifactOpenInTab => 'In tabblad openen';

  @override
  String get artifactTitleFallback => 'Artefact';

  @override
  String get providerGenerationLabel => 'Standaardwaarden voor generatie';

  @override
  String get providerGenerationHint =>
      'Laat een veld leeg om de standaardwaarde van het endpoint te gebruiken. Modellen publiceren hun eigen uitvoerlimieten en sampling-recepten; andere waarden kunnen ze verslechteren.';

  @override
  String get providerMaxTokensLabel => 'Max. uitvoertokens';

  @override
  String get addModel => 'Model toevoegen';

  @override
  String get modelListTitle => 'Modellijst';

  @override
  String get railProvidersGroup => 'Providers';

  @override
  String get railCustomProvidersGroup => 'Aangepaste providers';

  @override
  String get editModelSettings => 'Model bewerken';

  @override
  String get modelIdLabel => 'Model-ID';

  @override
  String get modelIdImmutableHint =>
      'De identifier die het endpoint serveert; vast zodra vermeld.';

  @override
  String get contextWindowLabel => 'Contextvenster';

  @override
  String get inputTypesLabel => 'Invoertypen';

  @override
  String get outputTypesLabel => 'Uitvoertypen';

  @override
  String get modalityText => 'Tekst';

  @override
  String get modalityImage => 'Afbeelding';

  @override
  String get modalityAudio => 'Audio';

  @override
  String get modalityVideo => 'Video';

  @override
  String get modalityPdf => 'PDF';

  @override
  String get modelOverrideReset => 'Terugzetten naar automatisch';

  @override
  String get modelOverrideEdited => 'Bewerkt';

  @override
  String get manualModelBadge => 'Handmatig toegevoegd';

  @override
  String get modelIdRequired => 'Voer een model-ID in.';

  @override
  String get modelTokensInvalid => 'Voer een positief geheel aantal tokens in.';

  @override
  String get removeModelAction => 'Model verwijderen';

  @override
  String removeModelConfirmTitle(String model) {
    return '$model verwijderen?';
  }

  @override
  String get removeModelConfirmBody =>
      'Het model verdwijnt uit de lijst en agents die eraan zijn vastgezet werken niet meer. De provider blijft ongewijzigd.';

  @override
  String get addModelProviderTitle => 'Modelprovider toevoegen';

  @override
  String get addModelProviderDescription =>
      'Configureer een aangepast API-endpoint en zijn modellen.';

  @override
  String get modelListEmptyHint =>
      'Geen modellen geconfigureerd. Voeg een model toe om het in de chat te gebruiken.';

  @override
  String get addProviderModelsHint =>
      'Modellen worden live opgehaald zodra het endpoint antwoordt. Voeg er alleen met de hand een toe als het zijn eigen modellen niet kan opsommen.';

  @override
  String get providerTemperatureLabel => 'Temperatuur';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved =>
      'Standaardwaarden voor generatie opgeslagen';

  @override
  String get providerGenerationInvalid =>
      'Controleer de waarden: max. uitvoertokens en top-k moeten positief zijn, temperatuur 0–2, top-p 0–1.';

  @override
  String get providerGenerationOverridden => 'Aangepast';

  @override
  String get spaceFlyoutNeedsInput => 'Invoer nodig';

  @override
  String get spaceFlyoutPreparing => 'Voorbereiden';

  @override
  String get spaceFlyoutSetupFailed => 'Instellen mislukt';

  @override
  String get spaceFlyoutSetupStopped => 'Instellen gestopt';

  @override
  String get spaceFlyoutNeverRun => 'Hier heeft nog geen agent gewerkt';

  @override
  String spaceFlyoutContextUsage(String used, String percent) {
    return 'Contextvenster: $used gebruikt, $percent vol';
  }

  @override
  String subagentsRunningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subagents',
      one: '1 subagent',
    );
    return '$_temp0';
  }

  @override
  String get branchNotPushed => 'niet gepusht';

  @override
  String branchNotOnRemote(String branch) {
    return '“$branch” bestaat alleen in dit gesprek';
  }

  @override
  String get branchNotOnRemoteHint =>
      'GitHub heeft deze branch nooit gezien, dus een pull request kan hem nog niet gebruiken. Publiceren pusht de commits die al in de worktree staan — niet-gecommitte wijzigingen blijven ongemoeid.';

  @override
  String get publishBranch => 'Branch publiceren';

  @override
  String branchPublished(String branch) {
    return '“$branch” gepubliceerd naar origin';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return 'Branch gepubliceerd. $count niet-gecommitte wijziging(en) zijn niet meegenomen.';
  }

  @override
  String get composePrLoadingBranches => 'Branches laden van GitHub…';

  @override
  String get composePrBranchesFailed =>
      'Kon branches niet laden van GitHub. Typ een branchnaam of controleer de GitHub-verbinding.';

  @override
  String get composePrSubtitleFromSpace =>
      'Vanuit de branch van dit gesprek — publiceer hem eerst als GitHub hem niet kent';

  @override
  String get obsTabInsights => 'Overzicht';

  @override
  String get obsTabLive => 'Live';

  @override
  String get obsTabQuality => 'Kwaliteit';

  @override
  String get obsTabUsage => 'Gebruik';

  @override
  String get obsUsageTotalTokens => 'Totaal aantal tokens';

  @override
  String get obsUsagePeakTokens => 'Piek aan tokens';

  @override
  String get obsUsageLongestSession => 'Langste sessie';

  @override
  String get obsUsageCurrentStreak => 'Huidige reeks';

  @override
  String get obsUsageLongestStreak => 'Langste reeks';

  @override
  String obsUsageDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagen',
      one: '1 dag',
      zero: '0 dagen',
    );
    return '$_temp0';
  }

  @override
  String get obsUsageTokenActivity => 'Tokenactiviteit';

  @override
  String get obsUsageActivityModeLabel => 'Modus voor tokenactiviteit';

  @override
  String get obsUsageModeDaily => 'Dagelijks';

  @override
  String get obsUsageModeWeekly => 'Wekelijks';

  @override
  String get obsUsageModeCumulative => 'Cumulatief';

  @override
  String get obsUsageTimeRange => 'Tijdsbereik';

  @override
  String get obsUsageTrendTitle => 'Dagelijkse tokentrend';

  @override
  String get obsUsageModelUsage => 'Gebruik per model';

  @override
  String get obsUsageTokensLabel => 'tokens';

  @override
  String get obsUsageNoActivity => 'Nog geen tokengebruik geregistreerd';

  @override
  String get obsUsageOtherModels => 'Overige';

  @override
  String obsUsageCellReadout(String date, String tokens) {
    return '$date · $tokens tokens';
  }

  @override
  String obsUsageActivitySummary(
    String start,
    String end,
    int activeDays,
    String peak,
  ) {
    return 'Tokenactiviteit van $start tot $end. $activeDays actieve dagen. Drukste dag: $peak tokens.';
  }

  @override
  String get obsScreenSubtitle =>
      'Live agentbesturing, kostentoerekening, quota\'s en kwaliteitssignalen';

  @override
  String get obsRangeLast24h => 'Laatste 24 uur';

  @override
  String get obsRangeLast7d => 'Laatste 7 dagen';

  @override
  String get obsRangeLast30d => 'Laatste 30 dagen';

  @override
  String get obsRangeAll => 'Alles';

  @override
  String get obsAddFilter => 'Filter toevoegen';

  @override
  String get obsFilterAgent => 'Agent';

  @override
  String get obsFilterModel => 'Model';

  @override
  String get obsFilterStatus => 'Status';

  @override
  String get obsFilterRole => 'Rol';

  @override
  String get obsKpiTotalRuns => 'Totaal runs';

  @override
  String get obsKpiTotalCost => 'Totale kosten';

  @override
  String get obsKpiErrorRate => 'Foutpercentage';

  @override
  String get obsKpiCacheRate => 'Cache-percentage';

  @override
  String get obsKpiTokensPerSec => 'Tokens / s';

  @override
  String get obsKpiAvgLatency => 'Gem. latentie';

  @override
  String get obsKpiTtft => 'Tijd tot eerste token';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '$delta vs vorige periode';
  }

  @override
  String get obsChartActivity => 'Activiteit';

  @override
  String get obsChartCost => 'Kosten in de tijd';

  @override
  String get obsLegendRuns => 'Runs';

  @override
  String get obsLegendErrors => 'Fouten';

  @override
  String get obsAgentsTitle => 'Agents';

  @override
  String obsShowAllAgents(int count) {
    return 'Alle $count agents tonen';
  }

  @override
  String get obsShowFewerAgents => 'Minder tonen';

  @override
  String get obsRunsTitle => 'Runs';

  @override
  String get obsNoRunsInRange => 'Geen runs in deze periode';

  @override
  String get obsColTime => 'Tijd';

  @override
  String get obsColAgent => 'Agent';

  @override
  String get obsColStatus => 'Status';

  @override
  String get obsColModel => 'Model';

  @override
  String get obsColDuration => 'Duur';

  @override
  String get obsColTokens => 'Tokens';

  @override
  String get obsColCost => 'Kosten';

  @override
  String get obsColErrors => 'Fouten';

  @override
  String get obsColRuns => 'Runs';

  @override
  String get obsColAvgLatency => 'Gem. latentie';

  @override
  String get obsColLastActive => 'Laatst actief';

  @override
  String get obsStatusPending => 'In wachtrij';

  @override
  String get obsStatusRunning => 'Actief';

  @override
  String get obsStatusCompleted => 'Voltooid';

  @override
  String get obsStatusError => 'Fout';

  @override
  String get obsRosterLoadError => 'De agentlijst kon niet worden geladen.';

  @override
  String get obsRosterEmpty => 'Nog geen agents';

  @override
  String get obsRosterEmptyDescription =>
      'Start een agent en deze verschijnt hier live — status, huidig hulpmiddel, tokens, kosten.';

  @override
  String get obsKillAgent => 'Agent stoppen';

  @override
  String get obsRosterTokensLabel => 'tok';

  @override
  String get obsCostByRoleTitle => 'Kosten per rol';

  @override
  String get obsCostByRoleSubtitle =>
      'Waar deze werkruimte aan besteedt, per agentrol';

  @override
  String get obsRoleMain => 'Hoofdagent';

  @override
  String get obsRoleSubagents => 'Subagents';

  @override
  String get obsRoleAdvisor => 'Adviseur';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return 'Hoofdagent: $main · subagents: $sub · adviseur: $advisor';
  }

  @override
  String get obsTotal => 'Totaal';

  @override
  String get obsTokenModelTitle => 'Tokenmodel (5 assen)';

  @override
  String get obsTokenModelSubtitle =>
      'Alle tokens die deze werkruimte heeft besteed, per as';

  @override
  String get obsAxisInput => 'Invoer';

  @override
  String get obsAxisOutput => 'Uitvoer';

  @override
  String get obsAxisReasoning => 'Redenering';

  @override
  String get obsAxisCacheRead => 'Cache-lezing';

  @override
  String get obsAxisCacheWrite => 'Cache-schrijving';

  @override
  String get obsTotalTokens => 'Totaal tokens';

  @override
  String get obsCacheDiscountNote =>
      'Uit de cache gelezen tokens worden met korting gefactureerd en kosten daarom veel minder dan hetzelfde volume nieuwe invoer.';

  @override
  String get obsByModelTitle => 'Per model';

  @override
  String get obsByModelSubtitle => 'Token- en kostengebruik per model';

  @override
  String get obsNoModelUsage => 'Nog geen modelgebruik geregistreerd.';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count runs',
      one: '1 run',
    );
    return '$_temp0';
  }

  @override
  String get obsPerRunTitle => 'Per run';

  @override
  String get obsPerRunSubtitle => 'Typische tokenkosten van één run';

  @override
  String get obsMedianRunTokens => 'Mediaan tokens per run';

  @override
  String get obsMedianRunTokensSub => 'Mediaan over alle runs';

  @override
  String get obsRunsInWorkspace => 'In deze werkruimte';

  @override
  String get obsCostShare => 'Kostenaandeel';

  @override
  String get obsQuotaConfiguredLimits => 'Geconfigureerde limieten';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      'Gebruik ten opzichte van de ingestelde grenzen, slechtste status eerst.';

  @override
  String get obsQuotaAddLimit => 'Limiet toevoegen';

  @override
  String get obsQuotaNoLimits =>
      'Nog geen quotalimieten geconfigureerd — voeg er een toe om het gebruik ten opzichte van een grens te volgen.';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return 'Limiet $title verwijderen';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return 'Reset over $duration · $status';
  }

  @override
  String get obsQuotaUsageWindows => 'Gebruiksvensters';

  @override
  String get obsQuotaUsageWindowsSubtitle =>
      'Waargenomen gebruik over alle providers, zonder grens.';

  @override
  String get obsQuotaNoUsage => 'Nog geen gebruik geregistreerd.';

  @override
  String get obsQuotaTokensUsed => 'Gebruikte tokens';

  @override
  String get obsQuotaRequests => 'Verzoeken';

  @override
  String get obsQuotaUnitTokens => 'tokens';

  @override
  String get obsQuotaUnitRequests => 'verzoeken';

  @override
  String get obsQuotaUnitCost => 'kosten';

  @override
  String get obsQuotaAddLimitTitle => 'Quotalimiet toevoegen';

  @override
  String get obsQuotaProviderLabel => 'Provider';

  @override
  String get obsQuotaWindowLabel => 'Venster';

  @override
  String get obsQuotaUnitLabel => 'Eenheid';

  @override
  String obsQuotaLimitLabel(String unit) {
    return 'Limiet ($unit)';
  }

  @override
  String get obsQuotaCentsHint => 'In Amerikaanse centen (500 = \$5,00).';

  @override
  String get obsQuotaStatusOk => 'Ok';

  @override
  String get obsQuotaStatusWarning => 'Waarschuwing';

  @override
  String get obsQuotaStatusExhausted => 'Uitgeput';

  @override
  String get obsQuotaStatusUnknown => 'Onbekend';

  @override
  String get obsGoalNoActiveTitle => 'Geen actief doel';

  @override
  String get obsGoalNoActiveBody =>
      'Stel een doel in om de agents een opdracht en een optioneel tokenbudget te geven. Naarmate runs worden voltooid, vult het budget zich en worden de agents aangespoord af te ronden zodra het bijna op is.';

  @override
  String get obsGoalSetGoal => 'Doel instellen';

  @override
  String get obsGoalTokenBudget => 'Tokenbudget';

  @override
  String obsGoalTokensLeft(String tokens) {
    return '$tokens over';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens (geen budget ingesteld)';
  }

  @override
  String get obsGoalTokensUsed => 'Gebruikte tokens';

  @override
  String get obsGoalElapsed => 'Verstreken';

  @override
  String get obsGoalWrapUp => 'Afronden';

  @override
  String get obsGoalClear => 'Doel wissen';

  @override
  String get obsGoalFallbackTitle => 'Doel';

  @override
  String get obsGoalSubtitle => 'Budget in doelmodus';

  @override
  String get obsGoalStatusActive => 'Actief';

  @override
  String get obsGoalStatusPaused => 'Gepauzeerd';

  @override
  String get obsGoalStatusBudgetLimited => 'Budget beperkt';

  @override
  String get obsGoalStatusComplete => 'Voltooid';

  @override
  String get obsGoalStatusDropped => 'Afgebroken';

  @override
  String get obsGoalObjectiveLabel => 'Doel';

  @override
  String get obsGoalBudgetLabel => 'Tokenbudget (optioneel)';

  @override
  String get obsGoalSetAction => 'Doel instellen';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => 'Succes %';

  @override
  String get obsBenchmarkPassed => 'Geslaagd';

  @override
  String get obsBenchmarkFailed => 'Mislukt';

  @override
  String get obsBenchmarkErrors => 'Fouten';

  @override
  String get obsBenchmarkSpend => 'Uitgaven';

  @override
  String get obsBenchmarkCostPerTask => 'Kosten / taak';

  @override
  String get obsBenchmarkTrials => 'Pogingen';

  @override
  String get obsBenchmarkNoTrials => 'Nog geen runs om te beoordelen.';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'en nog $count',
      one: 'en nog 1',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => 'Geslaagd';

  @override
  String get obsBenchmarkTrialFail => 'Mislukt';

  @override
  String get obsBenchmarkTrialError => 'Fout';

  @override
  String get obsBenchmarkTrialRunning => 'Actief';

  @override
  String get obsBenchmarkReward => 'Beloning';

  @override
  String get obsBenchmarkReport => 'Rapport';

  @override
  String get obsBenchmarkCopyMarkdown => 'Markdown kopiëren';

  @override
  String get obsBenchmarkCopied => 'Rapport naar klembord gekopieerd';

  @override
  String get obsBehaviorCaption =>
      'Dit zijn frustratiesignalen uit je eigen berichten — een meting van de gezondheid van het gesprek, geen cijfer voor de agents. Lokaal berekend; niets verlaat dit apparaat.';

  @override
  String get obsBehaviorMessagesAnalyzed => 'Geanalyseerde berichten';

  @override
  String get obsBehaviorTotalSignals => 'Totaal signalen';

  @override
  String get obsBehaviorYelling => 'Schreeuwen';

  @override
  String get obsBehaviorProfanity => 'Vloeken';

  @override
  String get obsBehaviorAnguish => 'Wanhoop';

  @override
  String get obsBehaviorNegation => 'Ontkenning';

  @override
  String get obsBehaviorRepetition => 'Herhaling';

  @override
  String get obsBehaviorBlame => 'Verwijt';

  @override
  String get obsBehaviorConversationsTitle => 'Meest gefrustreerde gesprekken';

  @override
  String get obsBehaviorConversationsSubtitle =>
      'Gerangschikt op signaaldichtheid in je berichten.';

  @override
  String get obsBehaviorNoSignals =>
      'Geen frustratiesignalen gedetecteerd — alles loopt soepel.';

  @override
  String obsBehaviorMessagesCount(String count) {
    return '$count berichten geanalyseerd';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '$count signalen';
  }

  @override
  String get obsAgentStatusIdle => 'Inactief';

  @override
  String get obsAgentStatusParked => 'Geparkeerd';

  @override
  String get obsAgentStatusAborted => 'Afgebroken';

  @override
  String get obsAgentKindSub => 'Subagent';

  @override
  String get noChecksOnCommit =>
      'Er zijn geen checks uitgevoerd op deze commit.';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bezig — $count jobs',
      one: 'Bezig — 1 job',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alle checks geslaagd — $count jobs',
      one: 'Alle checks geslaagd — 1 job',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Voltooid — $count jobs',
      one: 'Voltooid — 1 job',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total jobs',
      one: '1 job',
    );
    return '$failed van $_temp0 mislukt';
  }

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jobs',
      one: '1 job',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return 'Matrix: $jobId';
  }

  @override
  String get jobLogsPending => 'Logs verschijnen hier zodra de job klaar is.';

  @override
  String get jobLogsUnavailable =>
      'Er zijn geen logs beschikbaar voor deze job.';

  @override
  String get noLogsForStep => 'Geen logs vastgelegd voor deze stap.';

  @override
  String get jobLogsTruncated =>
      'Log ingekort — de meest recente uitvoer wordt getoond.';

  @override
  String get fullLog => 'Volledig log';

  @override
  String get copyLogs => 'Logs kopiëren';

  @override
  String get resizeGraph => 'Sleep om de grafiek te vergroten of te verkleinen';

  @override
  String workflowRunStartedAgo(String time) {
    return 'Gestart $time';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return 'Voltooid $time';
  }

  @override
  String get chatBridgesTitle => 'Chatbruggen';

  @override
  String chatProviderDescription(String provider, String command) {
    return 'Vermeld de bot in $provider om een agent iets te laten doen, of maak tickets met $command.';
  }

  @override
  String chatConnectProvider(String provider) {
    return '$provider verbinden';
  }

  @override
  String get chatDisconnectProvider => 'Verbinding verbreken';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$botName in $teamName';
  }

  @override
  String get chatStateLive => 'Live';

  @override
  String get chatStateConnecting => 'Verbinden…';

  @override
  String get chatStateError => 'Verbindingsfout';

  @override
  String get chatNotConnected => 'Niet verbonden';

  @override
  String chatStreamingUnavailable(String provider) {
    return 'Live streamen staat uit voor deze $provider-app — antwoorden komen als één bericht.';
  }

  @override
  String chatAdminOnly(String provider) {
    return 'Alleen een beheerder kan $provider voor deze werkruimte verbinden.';
  }

  @override
  String chatConnectHint(String provider) {
    return 'Maak een $provider-app en plak hier de inloggegevens. Control Center verbindt naar buiten met $provider, dus deze server heeft geen publiek adres nodig.';
  }

  @override
  String chatOpenConsole(String provider) {
    return '$provider-console openen';
  }

  @override
  String get chatOpenSetupGuide => 'Installatiegids';

  @override
  String get chatFieldBotToken => 'Bot-token';

  @override
  String get chatFieldAppToken => 'App-token';

  @override
  String get chatFieldConfigRefreshToken => 'App-configuratietoken';

  @override
  String chatFieldOptional(String label) {
    return '$label (optioneel)';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return 'Mijn $provider-account koppelen';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return 'Koppel je $provider-account zodat berichten die je daar stuurt aan jou worden toegeschreven.';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return 'Gekoppeld aan $externalUserId';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return 'Koppel je $provider-account';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return 'Stuur dit commando naar de bot in $provider. Het werkt één keer en verloopt over 15 minuten.';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return 'Je $provider-account is nu gekoppeld — berichten die je daar stuurt, worden aan jou toegeschreven.';
  }

  @override
  String get chatLinkedAccounts => 'Gekoppelde accounts';

  @override
  String chatNoLinkedAccounts(String provider) {
    return 'Niemand heeft zijn $provider-account nog gekoppeld.';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gekoppelde accounts',
      one: '1 gekoppeld account',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '$externalUserId · gematcht via e-mail';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '$externalUserId · gekoppeld met een code';
  }

  @override
  String get chatUnlink => 'Ontkoppelen';

  @override
  String get chatCustomizeBot => 'Bot aanpassen';

  @override
  String get chatCustomizeBotDescription =>
      'Geef de bot een andere naam, wijzig wat hij over zichzelf zegt of hernoem het commando.';

  @override
  String get chatCustomizeBotUnavailable =>
      'Control Center heeft een app-configuratietoken nodig om de bot te bewerken. Verbind opnieuw en geef er een mee.';

  @override
  String chatCreateAppTitle(String provider) {
    return 'De $provider-app maken';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'Control Center kan de $provider-app voor je maken, met de juiste rechten en gebeurtenissen al ingesteld. Je rondt het af in $provider en plakt de inloggegevens hier.';
  }

  @override
  String get chatCreateApp => 'App maken';

  @override
  String get chatCreateAppCta => 'Maak de app voor mij';

  @override
  String get chatAppNameLabel => 'App-naam';

  @override
  String get chatBotDisplayNameLabel => 'Botnaam (wat leden na @ typen)';

  @override
  String get chatDescriptionLabel => 'Korte beschrijving';

  @override
  String get chatAgentDescriptionLabel => 'Wat de bot zegt te kunnen';

  @override
  String get chatCommandLabel => 'Slash-commando';

  @override
  String get chatDirectMessages => 'Directe berichten';

  @override
  String chatDirectMessagesHint(String provider) {
    return 'Laat leden met de bot chatten in een DM. Vereist mogelijk een betaald $provider-abonnement.';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return '$provider heeft de app $appId gemaakt.';
  }

  @override
  String chatRemainingSteps(String provider) {
    return 'Er blijven een paar stappen over die alleen $provider kan doen:';
  }

  @override
  String get chatStepAppToken => 'Een app-token genereren';

  @override
  String get chatStepInstall => 'De app installeren';

  @override
  String get chatOpenAppSettings => 'App-instellingen openen';

  @override
  String get chatContinueToCredentials => 'Inloggegevens plakken';

  @override
  String chatBotUpdated(String provider) {
    return 'Bot bijgewerkt in $provider.';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return '$provider heeft de rechten van de app gewijzigd. Installeer de app opnieuw zodat ze van kracht worden.';
  }

  @override
  String get chatReinstallApp => 'App opnieuw installeren';

  @override
  String chatIconNotEditable(String provider) {
    return 'Het pictogram van de bot kan alleen in de app-instellingen van $provider worden gewijzigd.';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return 'Je kunt hem ook zelf in $provider maken — zonder token. De instellingen hierboven gaan mee met de link.';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return 'Maken in $provider';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return '$provider is in je browser geopend met deze configuratie al ingevuld. Maak de app daar, rond deze stappen af en kom terug met de tokens.';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return '$provider meldt niet welke app is gemaakt, dus de bot vanaf hier aanpassen vraagt later een app-configuratietoken.';
  }

  @override
  String get chatStepCreateApp =>
      'De app maken vanuit de vooraf ingevulde configuratie';

  @override
  String chatStepCreateAppHint(String provider) {
    return 'Kies een werkruimte in $provider en bevestig.';
  }

  @override
  String get chatStepAppTokenHint =>
      'Basic information → app-level tokens, met de scope connections:write.';

  @override
  String get chatStepInstallHint =>
      'Install app → kopieer het OAuth-token van de botgebruiker.';

  @override
  String get calendarUseBuiltinApp => 'Google-app van Control Center gebruiken';

  @override
  String get calendarUseBuiltinAppHint =>
      'Geef toegang met je Google-account. Niets in te stellen in Google Cloud.';

  @override
  String get calendarUseOwnClient => 'Mijn eigen Google Cloud-client gebruiken';

  @override
  String get calendarUseOwnClientHint =>
      'Voer een OAuth-client uit je eigen Google Cloud-project in.';

  @override
  String get aboutTitle => 'Over';

  @override
  String get aboutAppVersion => 'App-versie';

  @override
  String get aboutServerVersion => 'Verbonden server';

  @override
  String get aboutRpcCatalog => 'RPC-catalogus';

  @override
  String get aboutServerUnknown => 'Niet gerapporteerd';

  @override
  String get serverStaleTitle => 'De gebundelde server is ouder dan deze app';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return 'De draaiende cc_server is $serverVersion, terwijl deze app $appVersion is. Start de app opnieuw op zodat de nieuwste gebundelde server-build wordt gebruikt; bouw hem tijdens de ontwikkeling opnieuw met `dart build cli` in apps/cc_server.';
  }

  @override
  String get updateCheckButton => 'Naar updates zoeken';

  @override
  String get updateChecking => 'Updates zoeken…';

  @override
  String get updateUpToDate => 'Je bent up-to-date';

  @override
  String get updateDeferredBusy =>
      'Er is een update klaar, maar een vergadering wordt opgenomen — deze verschijnt na afloop.';

  @override
  String get updateOpenedReleasesPage =>
      'De releasepagina is geopend in je browser.';

  @override
  String get updateCheckFailed => 'Updatecontrole mislukt';

  @override
  String updateAvailableVersion(String version) {
    return 'Versie $version is beschikbaar.';
  }

  @override
  String get updateBannerTitle =>
      'Er is een nieuwe versie van Control Center beschikbaar';

  @override
  String get updateBannerRefresh => 'Vernieuwen';

  @override
  String get updateBlockedRecording =>
      'Vernieuwen is gepauzeerd terwijl een vergadering wordt opgenomen — de pagina laadt opnieuw zodra die klaar is.';

  @override
  String get settingsScopeYou => 'Jij';

  @override
  String get settingsScopeWorkspace => 'Werkruimte';

  @override
  String get settingsScopeServer => 'Server';

  @override
  String get settingsProfile => 'Profiel en identiteit';

  @override
  String get settingsYourDevices => 'Je apparaten';

  @override
  String get settingsWorkspaceGeneral => 'Algemeen';

  @override
  String get settingsServerConnection => 'Verbinding en status';

  @override
  String get settingsModelProviders => 'Modelaanbieders';

  @override
  String get settingsVoiceModels => 'Spraak- en vergadermodellen';

  @override
  String get settingsDiagnostics => 'Diagnose en privacy';

  @override
  String get settingsAbout => 'Over';

  @override
  String get settingsScopeBadgeYou => 'JIJ';

  @override
  String get settingsScopeBadgeDevice => 'DIT APPARAAT';

  @override
  String get settingsScopeBadgeWorkspace => 'WERKRUIMTE';

  @override
  String get settingsScopeBadgeServer => 'SERVER';

  @override
  String get settingsProfileDescription =>
      'Je naam, e-mail en de git-identiteit die op commits namens jou komt te staan.';

  @override
  String get settingsServerConnectionDescription =>
      'Met welke server deze client verbinding maakt en hoe deze server wordt gedeeld (mDNS, tunnels, relay).';

  @override
  String get settingsAboutDescription => 'Build-identiteit en updates.';

  @override
  String get settingsDiagnosticsDescription =>
      'Isolatie, indexering, synchronisatie, logging en crashrapportage van deze installatie.';

  @override
  String get settingsWorkspaceGeneralDescription =>
      'Identiteit, beleid en conventies die iedereen in deze werkruimte deelt.';

  @override
  String get settingsWorkspacePolicyLabel => 'Werkruimtebeleid';

  @override
  String get settingsWorkspacePolicyDescription =>
      'Geldt voor elk lid en elke agent in deze werkruimte.';

  @override
  String get settingsSecretGlobsLabel => 'Uitgesloten geheime paden';

  @override
  String get settingsSecretGlobsHelp =>
      'Eén patroon per regel. Deze paden blijven verborgen voor kijkers en gasten op codeoppervlakken, bovenop de standaardwaarden.';

  @override
  String get settingsReviewConcurrencyLabel => 'Reviewers parallel';

  @override
  String get settingsReviewConcurrencyHelp =>
      'Hoeveel reviewers parallel worden gestart als er geen aantal is opgegeven.';

  @override
  String get settingsReviewLevelLabel => 'Reviewniveau';

  @override
  String get settingsReviewLevelHelp =>
      'Hoe diep de AI-review gaat en hoeveel van wat ze vindt vooraan komt te staan. Er gaat niets verloren — een lichter niveau groepeert kleinere bevindingen in plaats van ze weg te laten.';

  @override
  String get reviewLevelLight => 'Licht';

  @override
  String get reviewLevelBalanced => 'Gebalanceerd';

  @override
  String get reviewLevelThorough => 'Grondig';

  @override
  String get reviewLevelLightHint =>
      'Eén reviewer. Alleen wat er echt toe doet komt vooraan.';

  @override
  String get reviewLevelBalancedHint =>
      'Drie reviewers voor kwaliteit, architectuur en implementatie.';

  @override
  String get reviewLevelThoroughHint =>
      'Voegt beveiligings- en performancespecialisten toe en meldt alles wat ze vindt.';

  @override
  String get askAiReviewAtLevel => 'Reviewen op een ander niveau';

  @override
  String reviewNitpicksGroup(int count) {
    return 'Kleine punten ($count)';
  }

  @override
  String get reviewFindingResolve => 'Opgelost';

  @override
  String get reviewFindingResolveHint =>
      'Markeer deze bevinding als opgelost. Ze telt niet langer mee in de review.';

  @override
  String get reviewFindingDismiss => 'Verwerpen';

  @override
  String get reviewFindingDismissHint =>
      'Geen echt probleem. Reviewers melden dit patroon voortaan niet meer.';

  @override
  String get reviewFindingReopen => 'Heropenen';

  @override
  String get reviewFindingStatusUndoLabel => 'Status van bevinding';

  @override
  String get reviewFindingDismissTitle => 'Deze bevinding verwerpen';

  @override
  String get reviewFindingDismissReasonHint =>
      'Waarom geldt dit niet? Reviewers lezen het.';

  @override
  String reviewFindingStatusFailed(String error) {
    return 'Kon de bevinding niet bijwerken: $error';
  }

  @override
  String get reviewStaleTitle => 'Deze review is verouderd';

  @override
  String get reviewStaleBody =>
      'De pull request is veranderd sinds deze review. Bevindingen wijzen mogelijk naar code die niet meer bestaat.';

  @override
  String reviewStaleReviewedAt(String sha) {
    return 'Gereviewd op $sha';
  }

  @override
  String get reviewStaleRerun => 'Opnieuw reviewen';

  @override
  String reviewStaleNotificationTitle(int prNumber) {
    return 'Review verouderd op #$prNumber';
  }

  @override
  String reviewStaleNotificationBody(String title) {
    return '$title heeft nieuwe commits sinds de laatste review.';
  }

  @override
  String get reviewCategorySecurity => 'Beveiliging';

  @override
  String get reviewCategoryStability => 'Stabiliteit';

  @override
  String get reviewCategoryDataIntegrity => 'Data-integriteit';

  @override
  String get reviewCategoryCorrectness => 'Correctheid';

  @override
  String get reviewCategoryPerformance => 'Performance';

  @override
  String get reviewCategoryMaintainability => 'Onderhoudbaarheid';

  @override
  String get reviewEffortQuickWin => 'Snelle winst';

  @override
  String get reviewEffortModerate => 'Gemiddeld';

  @override
  String get reviewEffortHeavyLift => 'Zwaar werk';

  @override
  String get reviewProposedFix => 'Voorgestelde oplossing';

  @override
  String get reviewAiAgentPrompt => 'Prompt voor AI-agents';

  @override
  String get reviewCopyAiPrompt => 'Prompt kopiëren';

  @override
  String get settingsWorkspaceAdminOnly =>
      'Alleen beheerders van de werkruimte kunnen dit wijzigen.';

  @override
  String get chatMyAccountsTitle => 'Gekoppelde chataccounts';

  @override
  String get settingsServerSso => 'Single sign-on';

  @override
  String get settingsServerSsoDescription =>
      'SAML- en OpenID Connect-login met gebruikersvoorziening';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabledDescription =>
      'Gebruikers kunnen inloggen met deze provider';

  @override
  String get ssoEnabledDescriptionOn => 'Inloggen is actief voor deze provider';

  @override
  String get ssoIdpMetadataLabel => 'IdP-metadata-XML';

  @override
  String get ssoIdpMetadataHint => 'plak de EntityDescriptor-XML van de IdP';

  @override
  String get ssoEmailAttributeLabel => 'E-mailattribuut';

  @override
  String get ssoDisplayNameAttributeLabel => 'Weergavenaam-attribuut';

  @override
  String get ssoGroupsAttributeLabel => 'Groepenattribuut';

  @override
  String get ssoIssuerLabel => 'Issuer-URL';

  @override
  String get ssoClientIdLabel => 'Client-ID';

  @override
  String get ssoGroupsClaimLabel => 'Groepen-claim';

  @override
  String get ssoAutoMemberLabel =>
      'Gebruikers bij eerste login aan elke workspace toevoegen';

  @override
  String get ssoAutoMemberDescription =>
      'Zet uit om per workspace een uitnodiging te vereisen';

  @override
  String get ssoAllowJitLabel =>
      'Onbekende gebruikers voorzien bij eerste login';

  @override
  String get ssoAllowJitDescription =>
      'Zet uit om gebruikers zonder bestaand account te weigeren';

  @override
  String get ssoAllowIdpInitiatedLabel =>
      'Door IdP geïnitieerde logins accepteren';

  @override
  String get ssoAllowIdpInitiatedDescription =>
      'Alleen voor IdP-portalen die apps direct starten';

  @override
  String get ssoWantResponseSignedLabel =>
      'Ondertekende respons-envelope vereisen';

  @override
  String get ssoWantResponseSignedDescription =>
      'Assertion-handtekeningen zijn altijd verplicht';

  @override
  String get ssoTestConnectionButton => 'Verbinding testen';

  @override
  String get ssoTestConnectionOk => 'Verbinding werkt:';

  @override
  String get ssoCopySpMetadata => 'SP-metadata kopiëren';

  @override
  String get ssoCopySpMetadataDone =>
      'SP-metadata naar het klembord gekopieerd';

  @override
  String get ssoSavedToast => 'Single sign-on-instellingen opgeslagen';

  @override
  String get ssoUnavailable =>
      'Deze server stelt geen single sign-on-instellingen beschikbaar. Werk de serverbinary bij en probeer het opnieuw.';

  @override
  String get ssoScimCardTitle => 'Gebruikersvoorziening (SCIM)';

  @override
  String get ssoScimDescription =>
      'Wijs de SCIM-connector van je identiteitsprovider naar het endpoint hieronder met een bearer-token. Bij onvoorziening worden sessies en workspace-toegang binnen seconden ingetrokken. De server moet bereikbaar zijn voor de IdP (tunnel of openbare URL).';

  @override
  String get ssoScimEndpoint => 'SCIM-endpoint';

  @override
  String get ssoScimEndpointUnknownOrigin =>
      'Stel eerst de openbare URL van de server in of schakel een tunnel in';

  @override
  String get ssoScimRegenerate => 'Token opnieuw genereren';

  @override
  String get ssoScimRegenerateConfirm =>
      'Nieuw SCIM-bearer-token genereren? Het vorige token werkt direct niet meer.';

  @override
  String get ssoScimTokenTitle => 'Bearer-token';

  @override
  String get ssoScimTokenPresent => 'Er is een token geconfigureerd';

  @override
  String get ssoScimTokenAbsent =>
      'Nog geen token — genereer er een om SCIM te activeren';

  @override
  String get ssoScimTokenOnce => 'SCIM-token (eenmalig getoond)';

  @override
  String ssoSignInWith(String provider) {
    return 'Inloggen met $provider';
  }

  @override
  String get ssoProbeFailed =>
      'Kon die server niet bereiken voor single sign-on';

  @override
  String get ssoOpensBrowser => 'Opent je browser om het inloggen af te ronden';

  @override
  String get ssoWaitingForBrowser =>
      'Wachten tot je browser het inloggen afrondt…';

  @override
  String get ssoBrowserOpenFailed =>
      'Kon de browser niet openen voor single sign-on';

  @override
  String get ssoUseManualPairing =>
      'Log in met een uitnodigingscode of koppelingssleutel';

  @override
  String get ssoHideManualPairing => 'Handmatige koppeling verbergen';

  @override
  String get ssoClientIdHint => 'Public client (PKCE) — geen secret nodig';

  @override
  String get ssoClientSecretLabel => 'Clientsecret (optioneel)';

  @override
  String get ssoClientSecretHintUnset =>
      'Alleen nodig voor vertrouwelijke IdP-clients';

  @override
  String get ssoClientSecretHintSet =>
      'Er is een secret opgeslagen — laat leeg om het te behouden';

  @override
  String get ssoPairingToggle =>
      'Handmatige koppeling toestaan (uitnodigingscodes en koppelingssleutels)';

  @override
  String get ssoPairingToggleDescription =>
      'Zet uit om lid worden alleen via single sign-on te laten verlopen — nieuwe apparaten komen via SSO-logins; bestaande apparaten blijven werken';

  @override
  String get ssoPairConfirmTitle => 'Verbinden met server?';

  @override
  String ssoPairConfirmBody(String server) {
    return 'Er is een inlogreferentie voor $server binnengekomen, maar er is geen inlogsessie vanuit deze app gestart. Verbinden met deze server?';
  }

  @override
  String get ssoPairConfirmConnect => 'Verbinden';

  @override
  String get ssoPairConfirmCancel => 'Negeren';

  @override
  String get forgeConnections => 'Codehosting';

  @override
  String get connect => 'Verbinden';

  @override
  String get disconnect => 'Loskoppelen';

  @override
  String get notConnected => 'Niet verbonden';

  @override
  String get checkingConnection => 'Verbinding controleren…';

  @override
  String get fromEnvironment => 'uit de omgeving';

  @override
  String forgeTokenTitle(String forge) {
    return '$forge-token';
  }

  @override
  String get settingsAudio => 'Audio';

  @override
  String get settingsAudioDescription =>
      'Microfoon, dicteren, vergaderingsdetectie en klanklandschap-uitvoer.';

  @override
  String get audioDevicesSection => 'Audioapparaten';

  @override
  String get voiceInputBehaviorSection => 'Dicteren en vergaderingen';

  @override
  String get audioOutputDeviceTitle => 'Uitvoerapparaat';

  @override
  String get audioOutputDefaultHint =>
      'Al het geluid van de app klinkt via de standaarduitvoer van het systeem.';

  @override
  String get audioOutputGone =>
      'Het gekozen uitvoerapparaat is niet meer verbonden — tot je een ander kiest, klinkt alles via de standaarduitvoer van het systeem.';

  @override
  String get reviewHubIntroBody =>
      'Agents analyseren de diff, brengen de wijzigingsgebieden in kaart en komen tot een consensusoordeel.';

  @override
  String get reviewHubAlreadyRunning =>
      'Er is al een review bezig voor deze pull request';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return 'Sinds de vorige review: $resolved opgelost · $added nieuw · $open nog open';
  }

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return 'Eerder gereviewd op $sha';
  }

  @override
  String reviewArtifactFixAll(int count) {
    return '$count bevindingen oplossen';
  }

  @override
  String reviewArtifactFixSelected(int count) {
    return '$count geselecteerde repareren';
  }

  @override
  String reviewArtifactCommentSelected(int count) {
    return '$count geselecteerde becommentariëren';
  }

  @override
  String get webConnectTitle => 'Verbinden met Control Center';

  @override
  String get webConnectSubtitle =>
      'Verbind via WebSocket met een draaiende cc-server. Je sleutel blijft op dit apparaat.';

  @override
  String get webConnectServerLabel => 'Server';

  @override
  String get webConnectDeviceIdLabel => 'Apparaat-id';

  @override
  String get webConnectPairingKeyLabel => 'Koppelsleutel';

  @override
  String get webConnectPairingKeyHint => 'plak de PSK';

  @override
  String get webConnectStayConnected => 'Verbonden blijven op dit apparaat';

  @override
  String get webConnectStayConnectedDetail =>
      'Verbonden blijven op dit apparaat (bewaart je sleutel in deze browser)';

  @override
  String failedToCreateWorkspace(String error) {
    return 'Werkruimte maken is mislukt: $error';
  }

  @override
  String committedRelative(String relative) {
    return 'vastgelegd $relative';
  }

  @override
  String get selectAgents => 'Agents selecteren';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agents',
      one: '1 agent',
    );
    return '$_temp0';
  }

  @override
  String get newConversation => 'Nieuw gesprek';

  @override
  String get untitledConversation => 'Gesprek zonder titel';

  @override
  String get conversationTitleOptionalHint =>
      'Optioneel — laat leeg en het titelmodel geeft automatisch een naam';

  @override
  String get conversationTitlesSectionTitle => 'Gesprekstitels';

  @override
  String get conversationTitlesSectionCaption =>
      'Kies de runner die nieuwe gesprekken in deze werkruimte automatisch een naam geeft. Titels staan uit tot er een adapter is gekozen en gelden voor elk lid.';

  @override
  String get conversationTitlesModelLabel => 'Titelmodel';

  @override
  String get conversationTitlesAdapterLabel => 'Adapter';

  @override
  String get conversationTitlesAdapterHint => 'Uit';

  @override
  String get conversationTitlesAdapterOff => 'Uit';

  @override
  String get startThread => 'Thread starten';

  @override
  String get deleteSpaceConfirm =>
      'Deze ruimte verwijderen? Alle berichten gaan verloren.';

  @override
  String threadTabTitle(String title) {
    return 'Thread: $title';
  }

  @override
  String threadReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reacties',
      one: '1 reactie',
    );
    return '$_temp0';
  }

  @override
  String threadLastReply(String time) {
    return 'Laatste reactie $time';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Inloggen met $provider';
  }

  @override
  String get signInAgain => 'Opnieuw inloggen';

  @override
  String get signInNotFinished =>
      'De aanmelding is nog niet terug. Rond die af in je browser en controleer het daarna opnieuw.';

  @override
  String get signedOutTitle => 'Je bent afgemeld';

  @override
  String get signedOutSubtitle =>
      'Je verbinding met de codehost is niet meer geldig — een token is verlopen of de toegang is ingetrokken. Er is verder niets veranderd: meld je weer aan en alles staat waar je het achterliet.';

  @override
  String get viaServerApp => 'via de app van deze server';

  @override
  String get ticketing => 'Tickets';

  @override
  String get ticketingProviderHelp =>
      'Waar je tickets leven. Lokaal houdt ze in Control Center.';

  @override
  String providerComingSoon(String provider) {
    return '$provider (binnenkort)';
  }

  @override
  String get ticketProviderLocal => 'Lokaal';

  @override
  String get addKey => 'Sleutel toevoegen';

  @override
  String get providerApps => 'Provider-apps';

  @override
  String get providerAppsDescription =>
      'Hoe deze server zichzelf authenticeert, en waarmee iemand inlogt. Achtergrondwerk — webhooks, polling, synchronisatie — loopt via de app, nooit via iemands token.';

  @override
  String get providerAppId => 'App-id';

  @override
  String get providerPrivateKey => 'Privésleutel';

  @override
  String get providerClientId => 'Client-id';

  @override
  String get providerClientSecret => 'Client-secret';

  @override
  String get providerApiKey => 'API-sleutel';

  @override
  String get providerCallbackUrl => 'Callback-URL';

  @override
  String get providerAppFullyConfigured =>
      'De server kan namens zichzelf handelen en mensen kunnen inloggen.';

  @override
  String get providerAppServerOnly =>
      'De server kan namens zichzelf handelen. Voeg een client-id en secret toe zodat mensen kunnen inloggen.';

  @override
  String get providerAppSignInOnly =>
      'Mensen kunnen inloggen. Achtergrondwerk valt terug op hun gegevens.';

  @override
  String providerAppInstalledOn(String accounts) {
    return 'De gegevens werken. Geïnstalleerd op: $accounts';
  }

  @override
  String deviceCodeInstructions(String provider) {
    return 'Voer deze code in op de $provider-pagina die net is geopend. Hij staat al op je klembord.';
  }

  @override
  String get deviceCodeWaiting => 'Wachten tot je klaar bent in de browser…';

  @override
  String get copyCodeAndOpen => 'Code kopiëren en openen';

  @override
  String get couldNotOpenBrowser =>
      'Er kon geen browser worden geopend. Kopieer de link en rond de aanmelding zelf af.';

  @override
  String get contextUsage => 'Contextgebruik';

  @override
  String get contextUsageFull => 'vol';

  @override
  String get contextUsageTokens => 'tokens';

  @override
  String get contextSeeMore => 'Meer weergeven';

  @override
  String get contextSegmentSystemPrompt => 'Systeemprompt';

  @override
  String get contextSegmentRules => 'Regels';

  @override
  String get contextSegmentSkills => 'Skills';

  @override
  String get contextSegmentToolDefinitions => 'Tooldefinities';

  @override
  String get contextSegmentMcpTools => 'MCP & dynamische tools';

  @override
  String get contextSegmentDeferredTools => 'Tools die op aanvraag laden';

  @override
  String get contextSegmentSubagents => 'Subagentdefinities';

  @override
  String get contextSegmentMemory => 'Geheugen';

  @override
  String get contextSegmentConversation => 'Gesprek';

  @override
  String get contextExplorerTitle => 'Context';

  @override
  String get contextExplorerEverything => 'Alles';

  @override
  String get contextExplorerSelectPart =>
      'Selecteer een deel om de inhoud te inspecteren';

  @override
  String get contextExplorerUnavailable => 'Contextverdeling niet beschikbaar';

  @override
  String get contextRetry => 'Opnieuw proberen';

  @override
  String get settingsFieldOptional => 'Optioneel';

  @override
  String get settingsFilterHint => 'Deze lijst filteren';

  @override
  String get settingsValueNotAvailable => 'Nog niet beschikbaar';

  @override
  String get settingsNoEntriesYet => 'Hier is nog niets';

  @override
  String get settingsChangedBadge => 'Gewijzigd';

  @override
  String get ssoConnectionCardDescription =>
      'Kies hoe mensen zich bij deze server aanmelden en zet die verbinding daarna aan.';

  @override
  String get ssoUseSamlForSignIn => 'SAML gebruiken om aan te melden';

  @override
  String get ssoUseOidcForSignIn => 'OpenID Connect gebruiken om aan te melden';

  @override
  String get ssoSaveConnection => 'Verbinding opslaan';

  @override
  String get ssoStateLive => 'Actief';

  @override
  String get ssoStateConfiguredOff => 'Ingesteld, uit';

  @override
  String get ssoStateOnIncomplete => 'Aan, onvolledig';

  @override
  String get ssoStateActive => 'Actief';

  @override
  String get ssoStateAllowed => 'Toegestaan';

  @override
  String get ssoStateNoToken => 'Geen token';

  @override
  String get ssoSummaryDirectorySync => 'Directorysynchronisatie';

  @override
  String get ssoSummaryManualPairing => 'Handmatig koppelen';

  @override
  String get ssoNoMethodLiveNote =>
      'Er is geen aanmeldmethode actief. Nieuwe apparaten sluiten aan met een uitnodiging of koppelsleutel totdat je een verbinding instelt en aanzet.';

  @override
  String get ssoMethodSamlBlurb =>
      'Voor identityproviders die SAML 2.0 spreken, zoals Okta, Entra ID of Google Workspace.';

  @override
  String get ssoMethodOidcBlurb =>
      'Voor identityproviders die OpenID Connect spreken. Meestal de eenvoudigste van de twee om in te stellen.';

  @override
  String get ssoGroupIdentityProvider => 'Identityprovider';

  @override
  String get ssoGroupIdentityProviderSamlDescription =>
      'Waar assertions vandaan komen en hoe deze server ze verifieert.';

  @override
  String get ssoGroupIdentityProviderOidcDescription =>
      'Welke issuer deze server vertrouwt en als welke client hij zich authenticeert.';

  @override
  String get ssoSpEntityIdShortLabel => 'SP-entiteits-id';

  @override
  String get ssoSpEntityIdDescription =>
      'Laat leeg om hem af te leiden uit de server-URL.';

  @override
  String get ssoIssuerDescription =>
      'De basis-URL die het discovery-document van de provider levert.';

  @override
  String get ssoSecretStored => 'Opgeslagen';

  @override
  String get ssoGroupHandoff => 'Wat je identityprovider nodig heeft';

  @override
  String get ssoGroupHandoffDescription =>
      'Plak deze waarden in de applicatie die je bij je provider hebt aangemaakt.';

  @override
  String get ssoOriginUnknownTitle => 'Deze server kent zijn publieke URL niet';

  @override
  String get ssoOriginUnknownBody =>
      'De aanmeld- en callback-URL’s worden hieruit opgebouwd, dus je provider kan deze server pas bereiken als er één is ingesteld. Voeg een publieke URL toe of zet een tunnel aan bij Server → Verbinding.';

  @override
  String get ssoAcsUrlLabel => 'Assertion consumer service (ACS)-URL';

  @override
  String get ssoAcsUrlDescription =>
      'Waar je provider de ondertekende assertion naartoe stuurt.';

  @override
  String get ssoSpEntityIdResolvedLabel =>
      'Entiteits-id van de serviceprovider';

  @override
  String get ssoMetadataUrlLabel => 'SP-metadata-URL';

  @override
  String get ssoMetadataUrlDescription =>
      'Providers die metadata importeren, kunnen die hier ophalen.';

  @override
  String get ssoRedirectUriLabel => 'Redirect-URI';

  @override
  String get ssoRedirectUriDescription =>
      'Voeg deze toe aan de toegestane redirect-URI’s van de applicatie bij je provider.';

  @override
  String get ssoSignInUrlLabel => 'Aanmeld-URL';

  @override
  String get ssoSignInUrlDescription =>
      'Stuur mensen hierheen om een single sign-on-aanmelding te starten.';

  @override
  String get ssoGroupAttributeMapping => 'Attributentoewijzing';

  @override
  String get ssoGroupAttributeMappingDescription =>
      'Welke claim welk veld draagt. Houd de standaardwaarden aan, tenzij je provider ze anders noemt.';

  @override
  String get ssoGroupAccess => 'Toegang en rollen';

  @override
  String get ssoGroupAccessDescription =>
      'Wat iemand die succesvol aanmeldt mag doen.';

  @override
  String get ssoDefaultRoleShortLabel => 'Standaardrol';

  @override
  String get ssoDefaultRoleDescription =>
      'Wordt gegeven aan iedereen wiens groepen met geen enkele toewijzing hieronder overeenkomen.';

  @override
  String get ssoRoleMapShortLabel => 'Groep-naar-roltoewijzing';

  @override
  String get ssoRoleMapDescription =>
      'De eerste overeenkomende groep wint. De eigenaarsrol kan zo niet worden toegekend.';

  @override
  String get ssoRoleMapGroupHint => 'Groepsnaam bij je provider';

  @override
  String get ssoRoleMapAdd => 'Toewijzing toevoegen';

  @override
  String get ssoRoleMapEmpty =>
      'Geen toewijzingen: iedereen krijgt de standaardrol.';

  @override
  String get ssoAdvancedSummary =>
      'Klokafwijking, door de IdP gestarte aanmelding, handtekeningbeleid';

  @override
  String get ssoClockSkewShortLabel => 'Klokafwijking';

  @override
  String get ssoClockSkewDescription =>
      'Seconden speling op assertion-tijdstempels. 90 volstaat voor de meeste providers.';

  @override
  String get ssoScimGenerate => 'Token genereren';

  @override
  String get ssoScimTokenOnceBody =>
      'Naar je klembord gekopieerd. Hij wordt één keer getoond en is niet te herstellen, dus plak hem nu bij je provider.';

  @override
  String get ssoPairingCardTitle => 'Handmatig koppelen';

  @override
  String get ssoPairingCardDescription =>
      'De andere ingang naar deze server: uitnodigingscodes en koppelsleutels, voor apparaten die niet via single sign-on binnenkomen.';

  @override
  String settingsCountOfTotal(int count, int total) {
    return '$count van $total';
  }

  @override
  String get providersNoneConnectedNote =>
      'Er is geen provider verbonden, dus de ingebouwde agent-runtime heeft niets om op te draaien. Voeg hieronder een API-sleutel toe of meld je bij een provider aan.';

  @override
  String get providersFilterHint => 'Providers filteren';

  @override
  String get providersFacetNeedsSetup => 'Nog instellen';

  @override
  String get providersFacetCustom => 'Eigen';

  @override
  String get providersNoneMatch => 'Niets komt overeen met dit filter';

  @override
  String get providerDeniedHereTitle => 'Geweigerd in deze werkruimte';

  @override
  String get providerDeniedHereBody =>
      'Agents hier kunnen deze provider niet gebruiken, ook al is hij verbonden. Andere werkruimtes blijven ongemoeid.';

  @override
  String get providerNeedsSignIn => 'Meld je aan om deze provider te gebruiken';

  @override
  String get providerNeedsApiKey =>
      'Voeg een API-sleutel toe om deze provider te gebruiken';

  @override
  String get providerApiKeyLabel => 'API-sleutel';

  @override
  String get providerGenerationDefaults => 'Standaarden van de provider';

  @override
  String get providerNoModelsYet =>
      'Nog geen modellen gemeld. Verbind de provider en synchroniseer daarna.';

  @override
  String get providerModelsFilterHint => 'Modellen filteren';

  @override
  String get adaptersNoneReadyNote =>
      'Geen van de runner-CLI’s uit de catalogus is op deze machine gevonden. Installeer er een en ververs daarna.';

  @override
  String get adaptersFilterHint => 'Runners filteren';

  @override
  String get adaptersFacetReady => 'Klaar';

  @override
  String get adaptersFacetMissing => 'Ontbrekend';

  @override
  String get adaptersLaunchGroup => 'Starten';

  @override
  String get adaptersLaunchGroupDescription =>
      'Wat deze runner meekrijgt wanneer een agent hem start. Je kunt dit ook instellen voordat je de CLI installeert.';

  @override
  String get adaptersEnvNone => 'Geen ingesteld';

  @override
  String adaptersEnvCount(int count) {
    return '$count ingesteld';
  }

  @override
  String get adapterArgumentsDescription =>
      'Worden bij elke start aan de opdrachtregel van de runner toegevoegd.';

  @override
  String get defaultChatDescription =>
      'Draait nieuwe gesprekken en elke agent zonder eigen runner.';

  @override
  String get shortTaskDescription =>
      'Doet kort achtergrondwerk zoals titels en samenvattingen. Een kleiner model past hier.';

  @override
  String get settingsStateFailed => 'Mislukt';

  @override
  String get providerAppsGroupServer => 'Handelen als de server';

  @override
  String get providerAppsGroupServerDescription =>
      'Laat achtergrondwerk repositories bereiken zonder mens achter het verzoek: webhooks, pull request-polling, ticketsynchronisatie.';

  @override
  String get providerAppsGroupPrConversations => 'Pullrequest-gesprekken';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      'Hoe ontwikkelaars direct op GitHub met deze server kunnen praten. Werkt zonder webhook en zonder openbare URL — de server pollt periodiek.';

  @override
  String get providerAppBotLogin => 'Bot-login';

  @override
  String get providerAppBotLoginEmpty =>
      'Test de verbinding om de bot-login te achterhalen.';

  @override
  String get providerAppAskOnGitHub => 'Vragen op GitHub';

  @override
  String get providerAppAskOnGitHubHint =>
      'Noem de bot-login hierboven in een reactie op een pullrequest — het achtervoegsel [bot] is optioneel — om een review aan te vragen of een vraag te stellen, reageer in zijn review-threads, of voeg het label `ai-review` toe om een review aan te vragen.';

  @override
  String get providerAppsGroupSignIn => 'Mensen aanmelden';

  @override
  String get providerAppsGroupSignInDescription =>
      'Laat elk lid het eigen account koppelen en eigen inloggegevens krijgen.';

  @override
  String get providerAppCapActsAsServer => 'Handelt als de server';

  @override
  String get providerAppCapSignsIn => 'Meldt mensen aan';

  @override
  String get portLabel => 'Poort';

  @override
  String get mcpNoTokenWarning =>
      'Zonder token kan alles wat deze poort bereikt elke tool aanroepen.';

  @override
  String get mcpBridgedToolsLabel => 'Tools';

  @override
  String get guardrailFamilyFiles => 'Bestanden';

  @override
  String get guardrailFamilyGit => 'Git en pull requests';

  @override
  String get guardrailFamilyMachine => 'Machine en netwerk';

  @override
  String get guardrailFamilyControl => 'Geheimen en werkruimte';

  @override
  String get guardrailScopeFieldLabel => 'Regels bewerken voor';

  @override
  String get guardrailScopeFieldDescription =>
      'Een smaller bereik wint van een breder bereik. Regels die je hier instelt gelden boven op wat is overgeërfd.';

  @override
  String get guardrailSetHere => 'Hier ingesteld';

  @override
  String get guardrailClearAllHere => 'Alles wissen';

  @override
  String get sandboxingCardLabel => 'Sandboxing';

  @override
  String get sandboxingCardDescription =>
      'Of agentwerk geïsoleerd van deze host draait, en wat een geïsoleerde agent nog kan bereiken.';

  @override
  String get sandboxBackendNoneActive => 'Host, geen isolatie';

  @override
  String get sandboxSummaryHost => 'Host';

  @override
  String get sandboxGroupIsolation => 'Isolatie';

  @override
  String get sandboxGroupIsolationDescription =>
      'Waar de processen en bestandsschrijfacties van een agent daadwerkelijk plaatsvinden.';

  @override
  String get sandboxBackendFieldDescription =>
      'Automatisch kiest de sterkste die deze host ondersteunt. Zet er een vast zodat hij niet onder je vandaan verandert.';

  @override
  String get sandboxCapabilitiesDescription =>
      'De gaten die in de grens zijn geprikt. Elk daarvan is iets wat een geïsoleerde agent nog met de buitenwereld kan doen.';

  @override
  String get sandboxSummaryInForce => 'Van kracht';

  @override
  String get rigsInstallHintLabel => 'Zo installeer je het';

  @override
  String get rigsStarting => 'Starten';

  @override
  String get rigsResidentMemory => 'Resident geheugen';

  @override
  String get installedLabel => 'Geïnstalleerd';

  @override
  String get notInstalledLabel => 'Niet geïnstalleerd';

  @override
  String ssoOtherKindUnsaved(String method) {
    return '$method heeft niet-opgeslagen wijzigingen';
  }

  @override
  String get collapseComment => 'Reactie invouwen';

  @override
  String get expandComment => 'Reactie uitvouwen';

  @override
  String get suggestedChange => 'Voorgestelde wijziging';

  @override
  String get emptyComment => 'Lege reactie';

  @override
  String repliesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reacties',
      one: '1 reactie',
    );
    return '$_temp0';
  }

  @override
  String get pendingReview => 'Review in wachtrij';

  @override
  String failedToResolveConversation(String error) {
    return 'Kon het gesprek niet bijwerken: $error';
  }

  @override
  String get addSingleComment => 'Losse reactie toevoegen';

  @override
  String get addToReview => 'Aan review toevoegen';

  @override
  String get startAReview => 'Review starten';

  @override
  String get reviewNeedsABody =>
      'Schrijf eerst een samenvatting of zet een inline reactie in de wachtrij';

  @override
  String get reviewSubmitted => 'Review verstuurd';

  @override
  String get finishYourReview => 'Review afronden';

  @override
  String get commentVerdict => 'Reageren';

  @override
  String pendingCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reacties in wachtrij',
      one: '1 reactie in wachtrij',
    );
    return '$_temp0';
  }

  @override
  String andNMore(int count) {
    return 'en nog $count';
  }

  @override
  String get queuedCommentHint =>
      'Deze reactie gaat mee wanneer je je review verstuurt.';

  @override
  String commentOnLinesRange(int start, int end) {
    return 'Regels $start tot $end';
  }

  @override
  String get claudeAccountsTitle => 'Claude Code-accounts';

  @override
  String get claudeAccountsDescription =>
      'Elk account is een aparte Claude Code-aanmelding. Runs gebruiken de hieronder gekoppelde accounts, in deze volgorde.';

  @override
  String get claudeAccountsEmpty => 'Nog geen accounts';

  @override
  String get claudeAccountAdd => 'Account toevoegen';

  @override
  String get claudeAccountSignIn => 'Aanmelden';

  @override
  String get claudeAccountSignInAgain => 'Opnieuw aanmelden';

  @override
  String get claudeAccountSignInHint =>
      'Voer dit uit in een terminal op de server. Er wordt een browser geopend om het aanmelden te voltooien en de referentie wordt in de map van dit account geschreven.';

  @override
  String get claudeAccountSignedOut => 'Afgemeld';

  @override
  String get claudeAccountExpired => 'Aanmelding verlopen';

  @override
  String claudeAccountExpiredDetail(String when) {
    return 'De aanmelding is om $when verlopen. Meld je opnieuw aan om dit account te gebruiken.';
  }

  @override
  String get claudeAccountMakeDefault => 'Als standaard instellen';

  @override
  String get claudeAccountDefault => 'Standaard';

  @override
  String claudeAccountRemoveConfirm(String label) {
    return '$label verwijderen?';
  }

  @override
  String get claudeAccountRemoveDetail =>
      'Het account wordt afgemeld en de map ervan op de server verwijderd. De aanmelding zelf blijft ongemoeid.';

  @override
  String claudeAccountStatusUnknown(String error) {
    return 'Kan dit account niet controleren: $error';
  }

  @override
  String claudeAccountUsedPercent(String percent) {
    return '$percent% gebruikt';
  }

  @override
  String get accountPoolStrategy => 'Rotatie';

  @override
  String get accountPoolPinned => 'Vast';

  @override
  String get accountPoolRoundRobin => 'Om de beurt';

  @override
  String get accountPoolSerial => 'Een voor een';

  @override
  String get accountPoolPinnedHint =>
      'Altijd met het eerste account beginnen. De rest blijft als reserve als het mislukt.';

  @override
  String get accountPoolRoundRobinHint =>
      'Runs over de accounts verdelen en bij elke start naar het volgende gaan.';

  @override
  String get accountPoolSerialHint =>
      'Het eerste account opmaken voordat het volgende aan de beurt is.';

  @override
  String get accountPoolMoveUp => 'Omhoog';

  @override
  String get accountPoolMoveDown => 'Omlaag';

  @override
  String get accountPoolUsingAll =>
      'Nog niets gekoppeld — alle accounts worden gebruikt, in deze volgorde.';

  @override
  String get accountPoolInheriting =>
      'Neemt de accounts van de werkruimte over.';

  @override
  String get accountPoolResetToWorkspace =>
      'Terug naar de accounts van de werkruimte';

  @override
  String accountPoolCoolingOff(String when) {
    return 'geen quotum tot $when';
  }

  @override
  String get accountPoolSignedOut => 'afgemeld';

  @override
  String get accountPoolExpired => 'aanmelding verlopen';

  @override
  String accountPoolLoadFailed(String error) {
    return 'Kan de rotatie niet laden: $error';
  }

  @override
  String get providerSignedInAccount => 'aangemeld account';

  @override
  String get agentAccountsTab => 'Accounts';

  @override
  String get agentAccountsDescription =>
      'Welke accounts de runs van deze agent gebruiken. Elk blok neemt eerst de keuze van de werkruimte over.';

  @override
  String get agentAccountsNothingToRotate =>
      'Niets om te rouleren — koppel eerst een tweede account of sleutel.';

  @override
  String failedToPostReply(String error) {
    return 'Kon de reactie niet plaatsen: $error';
  }

  @override
  String commentOnLine(int line) {
    return 'Regel $line';
  }

  @override
  String get viewInDiff => 'In diff bekijken';

  @override
  String get subscriptionUsagePreviousAccount => 'Vorig account';

  @override
  String get subscriptionUsageNextAccount => 'Volgend account';

  @override
  String inReplyTo(String path) {
    return 'Als antwoord op $path';
  }

  @override
  String get subscriptionUsageNoneReported =>
      'Voor dit account wordt geen gebruik gerapporteerd.';

  @override
  String get subscriptionUsageCredits => 'Tegoed';

  @override
  String get reviewHubStaticRule => 'Statische regel';

  @override
  String get reviewHubStarted => 'Review gestart';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return 'Gevonden door een deterministische regel ($rule) op een regel die deze pull request toevoegt — niet door een reviewagent.';
  }

  @override
  String get prReviewArtifactTab => 'PR-review';

  @override
  String get prReviewRunning => 'Deze pull request wordt beoordeeld…';

  @override
  String get prReviewStarting => 'Beoordeling starten…';

  @override
  String get prReviewStartingBody =>
      'De worktree van deze pull request wordt voorbereid. De beoordelaars starten zodra die klaar is.';

  @override
  String get prReviewFailed => 'Review mislukt.';

  @override
  String get prReviewRerunning => 'Opnieuw beoordelen…';

  @override
  String get prReviewNoOpenFindings => 'Geen open bevindingen';

  @override
  String prReviewOpenFindings(int count) {
    return '$count open bevindingen';
  }

  @override
  String subscriptionUsageSpend(String used, String limit) {
    return '$used van $limit';
  }

  @override
  String reviewCommentsPosted(int posted, int skipped, int failed) {
    return '$posted reactie(s) door de bot geplaatst. $skipped overgeslagen (geen bestandsanker), $failed mislukt.';
  }

  @override
  String reviewFindingsOutOfDiff(int count, String files) {
    return '$count bevinding(en) verwijzen naar code die deze pull request niet wijzigt ($files). GitHub accepteert inline reacties alleen op de diff.';
  }

  @override
  String get reviewRailReport => 'Rapport';

  @override
  String get reviewNoFindingsTitle => 'Nog geen bevindingen';

  @override
  String get reviewNoFindingsHint =>
      'Bevindingen verschijnen hier zodra agents ze plaatsen.';

  @override
  String reviewShowDismissed(int count) {
    return '$count gesloten tonen';
  }

  @override
  String reviewHideDismissed(int count) {
    return '$count gesloten verbergen';
  }

  @override
  String reviewDisagreementsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meningsverschillen tussen reviewers gevonden',
      one: '1 meningsverschil tussen reviewers gevonden',
    );
    return '$_temp0';
  }

  @override
  String get reviewFilterKind => 'Soort';

  @override
  String get reviewFilterStatus => 'Status';

  @override
  String get reviewKindBug => 'Bug';

  @override
  String get reviewKindSuggestion => 'Suggestie';

  @override
  String get reviewKindRecommendation => 'Aanbeveling';

  @override
  String get reviewKindQuestion => 'Vraag';

  @override
  String get reviewKindTicket => 'Ticket';

  @override
  String get archiveSpace => 'Ruimte archiveren';

  @override
  String get archivedSpaces => 'Gearchiveerde ruimtes';

  @override
  String get archivedSpacesEmpty => 'Geen gearchiveerde ruimtes';

  @override
  String get restoreSpace => 'Herstellen';

  @override
  String archivedWhen(String time) {
    return 'Gearchiveerd $time';
  }

  @override
  String get deleteSpacePermanently => 'Definitief verwijderen';

  @override
  String get renameSpace => 'Ruimte hernoemen';

  @override
  String get renameConversation => 'Gesprek hernoemen';

  @override
  String get editSpaceRepos => 'Repositories bewerken';

  @override
  String get editSpaceReposTitle => 'Repositories van ruimte';

  @override
  String get editSpaceReposWarning =>
      'Een repository toevoegen haalt hem op in deze ruimte; er een verwijderen verwijdert de map.';

  @override
  String get agentSectionIdentity => 'Identiteit';

  @override
  String get agentSectionRuntime => 'Uitvoering';

  @override
  String get agentSectionGuardrails => 'Beveiligingen';

  @override
  String orgChartReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count medewerkers',
      one: '1 medewerker',
    );
    return '$_temp0';
  }

  @override
  String get teamsFilterHint => 'Teams filteren…';

  @override
  String get teamsSummaryWithLeader => 'Met leider';

  @override
  String teamCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count teams',
      one: '1 team',
      zero: 'Geen teams',
    );
    return '$_temp0';
  }

  @override
  String agentDeleteLongDescription(String name) {
    return 'Het verwijderen van $name wist het profiel, de skill-koppelingen en de uitvoeringsgeschiedenis. Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String get resetToDefault => 'Standaard herstellen';

  @override
  String get newAgent => 'Nieuwe agent';

  @override
  String get newSkill => 'Nieuwe skill';

  @override
  String get zoomIn => 'Inzoomen';

  @override
  String get zoomOut => 'Uitzoomen';

  @override
  String get resetZoom => 'Zoom herstellen';

  @override
  String get imageHostedOnGitHub => 'Afbeelding gehost op GitHub';

  @override
  String get imageOpenExternally => 'Afbeelding · extern openen';

  @override
  String get memoryScopeAll => 'Alle bereiken';

  @override
  String get memoryScopeWorkspace => 'Hele werkruimte';

  @override
  String get memoryScopeFilterLabel => 'Filteren op bereik';

  @override
  String memoryScopeRepoTooltip(String repo) {
    return 'Beperkt tot de repository $repo';
  }

  @override
  String get toolScreenshot => 'Schermafbeelding van de agent';

  @override
  String get toolImageUnavailable => 'Afbeelding niet beschikbaar';

  @override
  String toolImagesUnavailable(int count) {
    return '$count afbeeldingen niet beschikbaar';
  }

  @override
  String get shakeUnavailable =>
      'Uitschudden is niet beschikbaar op deze server';

  @override
  String get shakeNothing =>
      'Niets uit te schudden — recente beurten zijn beschermd';

  @override
  String shakeDone(int tokens) {
    return 'Ongeveer $tokens tokens vrijgemaakt';
  }

  @override
  String get compactionDivider => 'Gecomprimeerd';

  @override
  String compactionDividerCount(int count) {
    return 'Gecomprimeerd · $count berichten samengevouwen';
  }

  @override
  String get composerDropToAttach => 'Neerzetten om bij te voegen';

  @override
  String get attachmentUnavailable => 'Bijlage niet beschikbaar';

  @override
  String get attachmentUnavailableDetail =>
      'Deze bijlage staat niet meer in het geheugen. Voeg hem opnieuw toe om een voorbeeld te zien.';

  @override
  String get attachmentPreviewFailed => 'Kon dit bestand niet openen';

  @override
  String get attachmentPreviewUnsupported =>
      'Geen voorbeeld voor dit bestandstype';

  @override
  String get attachmentTooLargeToPreview => 'Te groot voor een voorbeeld';

  @override
  String get attachmentOpenExternally => 'Openen in standaardapp';

  @override
  String get asideUnavailable =>
      'Stel een one-shot model in bij de instellingen om dit te gebruiken';

  @override
  String get asideEmpty => 'Nog niets om mee te werken';

  @override
  String get asideFailed => 'Kon geen antwoord krijgen';

  @override
  String get handoffTitle => 'Overdracht';

  @override
  String get asideTitle => 'Zijvraag';

  @override
  String get attachFilesOrDrop => 'Bestanden toevoegen — of sleep ze hierheen';

  @override
  String get guidedGoalTitle => 'Doel aanscherpen';

  @override
  String get guidedGoalIntro =>
      'Een agent die zonder toezicht werkt moet precies weten wanneer hij klaar is. Eerst een paar vragen.';

  @override
  String get guidedGoalAnswerHint => 'Jouw antwoord';

  @override
  String get guidedGoalNext => 'Volgende';

  @override
  String get guidedGoalStart => 'Doel starten';

  @override
  String get guidedGoalSkip => 'Overslaan en uitvoeren zoals geschreven';

  @override
  String guidedGoalStillMissing(String items) {
    return 'Nog niet gespecificeerd: $items';
  }

  @override
  String get conversationTreeTitle => 'Gespreksboom';

  @override
  String conversationTreeBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count takken',
      one: '1 tak',
    );
    return '$_temp0';
  }

  @override
  String get conversationTreeSwitch => 'Vanaf hier verdergaan';

  @override
  String get conversationTreeFork => 'Aftakken naar een nieuw gesprek';

  @override
  String get conversationTreeCurrent => 'Op deze tak';

  @override
  String get conversationTreeEmpty => 'Nog niets hier';

  @override
  String get conversationTreeForked => 'Afgetakt naar een nieuw gesprek';

  @override
  String get conversationTreeSwitched => 'Gaat nu verder vanaf dat bericht';

  @override
  String exportSaved(String path) {
    return 'Opgeslagen in $path';
  }

  @override
  String get exportFailed => 'Kon de export niet schrijven';

  @override
  String get contextCommandNoAgent =>
      'Geen agent in dit gesprek, dus er is geen contextvenster om te openen';

  @override
  String contextCommandNoSuchAgent(String name, String names) {
    return 'Geen agent met de naam ‘$name’ in dit gesprek. Probeer: $names';
  }

  @override
  String get dumpCopied => 'Transcript naar het klembord gekopieerd';

  @override
  String get messageQueueHint =>
      'Blijf typen om vervolgaanpassingen in de wachtrij te zetten';

  @override
  String get steerNow => 'Sturen';

  @override
  String get steeringQueueLabel => 'Wachtende stuurberichten';

  @override
  String get steeringDeliverUnavailable =>
      'Geen actieve agent kan dit nu oppakken — het blijft in de wachtrij.';

  @override
  String get reorderSteeringCard => 'Wachtend bericht herschikken';

  @override
  String get editSteeringCard => 'Wachtend bericht bewerken';

  @override
  String get deleteSteeringCard => 'Wachtend bericht verwijderen';

  @override
  String get steeringBadge => 'Gestuurd';

  @override
  String get settingsSandboxLabel => 'Sandbox';

  @override
  String get sandboxExecGrantsTitle => 'Uitvoeringsrechten';

  @override
  String get sandboxExecGrantsSubtitle =>
      'Programma\'s die agents mogen uitvoeren vanuit hun werkkopie van je repository\'s. Elke vermelding is door jou goedgekeurd toen de sandbox erom vroeg.';

  @override
  String get sandboxExecGrantsEmpty =>
      'Nog geen beslissingen vastgelegd. Je wordt gevraagd zodra een agent voor het eerst een programma vanuit zijn werkkopie moet uitvoeren.';

  @override
  String get sandboxExecGrantRevoke => 'Intrekken';

  @override
  String get sandboxExecGrantAllowed => 'Toegestaan';

  @override
  String get sandboxExecGrantBlocked => 'Geblokkeerd';

  @override
  String get sandboxExecGrantRevokeConfirmTitle => 'Deze beslissing intrekken?';

  @override
  String get sandboxExecGrantRevokeConfirmBody =>
      'Je wordt opnieuw gevraagd wanneer een agent de volgende keer een programma vanuit deze kopie moet uitvoeren.';

  @override
  String get repoScriptsTest => 'Testen';

  @override
  String get repoScriptsTestTooltip =>
      'Voer dit concept uit in een wegwerp-kloon van de repo';

  @override
  String get repoScriptsRunKindTest => 'Test';

  @override
  String get demoBadgeLabel => 'Demo';

  @override
  String get demoFilePickerTitle => 'Demobestanden';

  @override
  String get demoFilePickerBody =>
      'De demo faket uploads: kies er een en hij wordt aan je bericht toegevoegd zonder een schijf te raken.';

  @override
  String get demoFilePickerAttach => 'Bijvoegen';

  @override
  String get demoReadOnlySave => 'Alleen-lezen in de demo';

  @override
  String get demoBadgeTooltip =>
      'Je verkent een demo. De gegevens zijn fictief en de agents volgen een script.';

  @override
  String get demoFirstRunTitle => 'Je zit in een live demo';

  @override
  String demoFirstRunBody(int minutes) {
    return 'Dit is de echte app op echte code — alleen de gegevens zijn verzonnen. Agents streamen echte runs vanuit een script, dus er bereikt niets een model en er draait niets op een machine. Je werkruimte is alleen van jou en verdwijnt na $minutes minuten.';
  }

  @override
  String get demoFirstRunDismiss => 'Duidelijk';

  @override
  String get demoTourTitle => 'Waar je begint';

  @override
  String get demoTourSubtitle =>
      'Vier plekken die laten zien wat de app echt doet.';

  @override
  String get demoTourSkip => 'Overslaan';

  @override
  String get demoTourStarRepo => 'Een ster geven op GitHub';

  @override
  String get demoTourDone => 'Klaar';

  @override
  String get demoTourOpen => 'Openen';

  @override
  String get demoTourSpacesTitle => 'Praat met een agent';

  @override
  String get demoTourSpacesBody =>
      'Stuur een bericht in een space en zie een run binnenkomen — denkwerk, tool-aanroepen en kosten, precies zoals een echte run.';

  @override
  String get demoTourReviewTitle => 'Beoordeel een pull request';

  @override
  String get demoTourReviewBody =>
      'Open #412. Laat een inline-opmerking achter of dien een review in: je woorden komen in de thread en blijven daar.';

  @override
  String get demoTourTicketsTitle => 'Volg het werk';

  @override
  String get demoTourTicketsBody =>
      'Tickets, taken en plannen hangen aan dezelfde gesprekken die de agents voeren.';

  @override
  String get demoTourInboxTitle => 'Zie de hele operatie';

  @override
  String get demoTourInboxBody =>
      'Elke melding van elke pijler belandt in één postvak — reviews, tickets, runs en vergaderingen.';

  @override
  String demoSessionEndingSoon(int minutes) {
    return 'Deze demosessie eindigt over $minutes minuten.';
  }

  @override
  String get demoSessionEnded =>
      'Deze demosessie is beëindigd. Herlaad de pagina om een nieuwe te starten.';

  @override
  String get demoUnavailableTitle => 'Niet beschikbaar in de demo';

  @override
  String get demoUnavailableTerminal =>
      'Een terminal draait een echte shell op de server. De demo heeft helemaal geen uitvoeringsoppervlak — juist daardoor kun je hem veilig openbaar zetten.';

  @override
  String get demoUnavailableRig =>
      'Een enclosure is een wegwerp-VM die een agent bestuurt. De demo start er geen: een openbaar endpoint dat een VM kan starten is geen demo.';

  @override
  String get demoUnavailableEditor =>
      'De editor in de browser draait een code-server-proces op een echte checkout. De demo heeft geen van beide.';

  @override
  String get demoUnavailableFeeds =>
      'De demo leest echte feeds, maar de abonnementenlijst ligt vast. Toevoegen of verwijderen is hier uitgeschakeld.';

  @override
  String get demoUnavailableForge =>
      'De demo bewaart geen inloggegevens en benadert nooit GitHub, GitLab of Linear. De pull requests zijn fixtures en je opmerkingen blijven lokaal.';

  @override
  String get demoUnavailableModels =>
      'De demo roept geen model aan. Agent-runs zijn gescripte weergave — daarom kosten ze niets en bereiken ze geen provider.';

  @override
  String get demoUnavailableMcp =>
      'Het MCP-gereedschapsoppervlak is niet gemount in de demo, dus geen enkele externe client kan verbinden.';

  @override
  String get demoUnavailableRepos =>
      'De demo haalt geen code op en voert geen git uit. De repository die je ziet is een fixture achter de pull requests.';

  @override
  String get demoUnavailableSkills =>
      'Een skill installeren downloadt en scant code. De demo haalt niets op.';

  @override
  String get demoUnavailableSso =>
      'Single sign-on is serverconfiguratie. De demo logt je in als tijdelijke gast.';

  @override
  String get demoUnavailableAudio =>
      'Opnemen en dicteren vereisen audio-opname en een spraakmodel op de host. De demo levert geen van beide: vergaderingen zijn transcripties zonder weergave.';

  @override
  String get demoUnavailableServerAdmin =>
      'Dit is serverbeheer. De demo geeft je een wegwerpwerkruimte en verder niets.';

  @override
  String get settingsBackupRestore => 'Back-up en herstel';

  @override
  String get settingsBackupRestoreDescription =>
      'Momentopnamen van elke database op deze server, plus exporteren, importeren en verwijderen van één werkruimte.';

  @override
  String get backupSnapshotsLabel => 'Momentopnamen van de installatie';

  @override
  String get backupSnapshotsExplainer =>
      'Een momentopname kopieert elke database naar een map met tijdstempel op de serverhost. De hele installatie herstellen betekent die map terugkopiëren met de server gestopt; één werkruimte kun je hier herstellen.';

  @override
  String get backupNowAction => 'Nu back-uppen';

  @override
  String backupSnapshotWritten(String path) {
    return 'Momentopname weggeschreven naar $path';
  }

  @override
  String get backupNoSnapshots =>
      'Nog geen momentopnamen. Er wordt er alleen een gemaakt als je erom vraagt — er staat niets ingepland.';

  @override
  String get backupSnapshotComplete => 'Volledig';

  @override
  String get backupSnapshotIncomplete => 'Onvolledig';

  @override
  String get backupSnapshotIncompleteNote =>
      'Het manifest ontbreekt of noemt bestanden die er niet zijn, dus deze momentopname kan de hele installatie niet herstellen. De werkruimtebestanden die er wel zijn, kun je nog steeds één voor één overnemen.';

  @override
  String backupSnapshotWorkspaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count werkruimten',
      one: '1 werkruimte',
      zero: 'Geen werkruimten',
    );
    return '$_temp0';
  }

  @override
  String backupSnapshotSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count werkruimten niet vastgelegd',
      one: '1 werkruimte niet vastgelegd',
    );
    return '$_temp0';
  }

  @override
  String get backupServerPathLabel => 'Pad op de server';

  @override
  String get backupRestoreAction => 'Herstellen';

  @override
  String get backupRestoreTitle => 'Werkruimte herstellen';

  @override
  String backupRestoreBody(String name) {
    return 'Dit vervangt alles in $name door de kopie in deze momentopname. Alles wat die werkruimte sindsdien heeft gedaan, gaat verloren en is niet terug te draaien.';
  }

  @override
  String backupRestoreDone(String name) {
    return '$name hersteld vanuit de momentopname.';
  }

  @override
  String get backupWorkspaceUnknown => 'Staat niet meer op deze server';

  @override
  String get backupWorkspaceDataLabel => 'Werkruimtegegevens';

  @override
  String get backupWorkspaceDataExplainer =>
      'Eén werkruimte is één databasebestand, dus exporteren kopieert dat bestand in plaats van tabel voor tabel te dumpen. Importeren vervangt alles in de doelwerkruimte door het bestand dat je noemt.';

  @override
  String get backupExportAction => 'Exporteren';

  @override
  String backupExportDone(String path) {
    return 'Geëxporteerd naar $path';
  }

  @override
  String get backupExportedFileLabel => 'Geëxporteerd bestand op de server';

  @override
  String get backupImportAction => 'Importeren';

  @override
  String backupImportTitle(String name) {
    return 'Importeren in $name';
  }

  @override
  String backupImportBody(String name) {
    return 'Dit vervangt alles in $name door de inhoud van het bestand. Wat die werkruimte nu bevat, gaat verloren en is niet terug te draaien.';
  }

  @override
  String get backupImportSourceLabel => 'Databasebestand van de werkruimte';

  @override
  String get backupImportSourceDescription =>
      'Een .db-bestand dat de server kan lezen. Paden worden op de serverhost opgelost, niet op dit apparaat.';

  @override
  String get backupImportChooseFile => 'Bestand kiezen';

  @override
  String backupImportDone(String name) {
    return 'Geïmporteerd in $name.';
  }

  @override
  String backupDeleteBody(String name) {
    return '$name verdwijnt uit elke lijst en zoekopdracht. Het databasebestand blijft op schijf staan, back-ups nemen het nog steeds mee, en niets maakt die ruimte automatisch vrij.';
  }

  @override
  String get backupExportDescription =>
      'Zet een kopie op de server, of download er een naar dit apparaat.';

  @override
  String get backupExportOnServerAction => 'Op server opslaan';

  @override
  String get backupDownloadAction => 'Downloaden';

  @override
  String backupDownloadSaved(String path) {
    return 'Opgeslagen in $path';
  }

  @override
  String get backupDownloadInBrowser => 'Je browser doet de rest.';

  @override
  String get backupRestoreFromDeviceLabel => 'Herstellen vanaf dit apparaat';

  @override
  String get backupRestoreFromDeviceDescription =>
      'Kies hier een databasebestand van een werkruimte; Control Center uploadt het naar de server. Dit is de weg die werkt als de server niet deze machine is.';

  @override
  String get backupUploadAction => 'Bestand kiezen en uploaden';

  @override
  String get backupTransferUnavailable =>
      'Deze verbinding bereikt de server via een relay, dat geen bestanden vervoert. Verbind rechtstreeks met de server om een back-up te downloaden of te uploaden.';

  @override
  String get backupTransferForbidden =>
      'De server weigerde. Een werkruimte downloaden vereist de rol admin, er een herstellen vereist owner, en een hele momentopname vereist de beheerder van de installatie.';

  @override
  String get backupTransferUnsupported =>
      'Deze server heeft geen back-upoppervlak.';

  @override
  String get backupTransferTooLarge =>
      'Het bestand is groter dan de server accepteert.';

  @override
  String get credentialGateWaitingTitle => 'Wachten op een inloggegeven';

  @override
  String credentialGateHarnessTitle(String provider) {
    return '$provider heeft geen inloggegevens';
  }

  @override
  String get credentialGateSignedOutTitle => 'Claude Code is afgemeld';

  @override
  String get credentialGateExpiredTitle =>
      'Je Claude Code-aanmelding is verlopen';

  @override
  String get credentialGatePlanSpentTitle =>
      'Limiet van het Claude Code-abonnement bereikt';

  @override
  String credentialGateWaitingAgent(String agent) {
    return '$agent wacht om verder te gaan.';
  }

  @override
  String get credentialGateWaitingRun => 'Een run wacht om verder te gaan.';

  @override
  String get credentialGateWatching =>
      'We letten op de oplossing — de run gaat vanzelf verder.';

  @override
  String credentialGateFreesUpAt(String time) {
    return 'Komt om $time weer vrij';
  }

  @override
  String credentialGateGivesUpAt(String time) {
    return 'De run geeft om $time op';
  }

  @override
  String get credentialGateCheckAgain => 'Opnieuw controleren';

  @override
  String get credentialGateCancelRun => 'Run annuleren';

  @override
  String get credentialGateAccountsTried => 'Geprobeerde accounts';

  @override
  String get credentialGateClaudeSignInHint =>
      'Meld je aan via Instellingen → Adapters → Claude Code, of voer de aanmeldopdracht uit in een terminal. De run pikt het vanzelf op.';

  @override
  String get credentialGateOpenSettings => 'Instellingen openen';
}
