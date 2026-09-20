// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get succeeded => 'Lyckades';

  @override
  String agentRunRetryLabel(int number, String time) {
    return 'Försök #$number · $time';
  }

  @override
  String agentRunStarting(String time) {
    return 'Startar · $time';
  }

  @override
  String get agentActivityFollowingLive => 'Följer liveaktivitet';

  @override
  String get agentActivityJumpToLatest => 'Hoppa till senaste';

  @override
  String get agentActivityLoadFailed =>
      'Kunde inte läsa in den här körningens aktivitet';

  @override
  String get agentActivityNotRecorded =>
      'Ingen aktivitet spelades in för den här körningen';

  @override
  String get agentActivityNotRecordedHint =>
      'Körningar som avslutades innan aktivitetsinspelning slogs på har ingen tidslinje.';

  @override
  String get agentActivityRunUnavailable =>
      'Den här körningen finns inte längre';

  @override
  String agentActivitySubagentOf(String agent) {
    return 'Subagent till $agent';
  }

  @override
  String get agentActivityUnsupported =>
      'Aktivitetsinspelning saknas på den anslutna servern';

  @override
  String get agentActivityUnsupportedHint =>
      'Starta om appen så att den tar in den senaste serverversionen.';

  @override
  String get agentActivityWaiting => 'Väntar på aktivitet…';

  @override
  String get created => 'Skapad';

  @override
  String get dictationStart => 'Starta diktering';

  @override
  String get dictationListening => 'Lyssnar…';

  @override
  String get dictationUnavailable =>
      'Diktering behöver en röstmodell på servervärden. Ställ in en under röstinställningar.';

  @override
  String get dictationFailedToStart => 'Kunde inte starta diktering';

  @override
  String get dictationHoldToTalkTitle => 'Håll inne för att tala';

  @override
  String get dictationHoldToTalkDescription =>
      'Håll inne mikrofonknappen eller genvägen för att diktera och släpp för att stoppa. När det är av är det ett tryck för att starta och ett till för att stoppa.';

  @override
  String get focusConversation => 'Fokusera samtalet';

  @override
  String get ideAgentActivity => 'Agentaktivitet';

  @override
  String get keybindingPushToTalk => 'Tryck för att tala';

  @override
  String get keybindingPushToTalkDescription =>
      'Håll inne eller växla röstdiktering i meddelandefältet';

  @override
  String get agentPermissions => 'Agentbehörigheter';

  @override
  String get agentPermissionsSettingsDescription =>
      'Bestäm vad agenter får göra själva, måste fråga om först eller aldrig får göra – per arbetsyta, agent eller yta.';

  @override
  String get agentPermissionsMatrixDescription =>
      'Sätt ett beslut för varje typ av effekt. Regler kaskadar: yta åsidosätter agent åsidosätter arbetsyta åsidosätter lägesförinställning. Den mest specifika regeln vinner.';

  @override
  String get guardrailLoading => 'Läser in regler…';

  @override
  String get guardrailRulesLoadFailed =>
      'Kunde inte läsa in behörighetsreglerna.';

  @override
  String get guardrailScopeWorkspace => 'Arbetsyta';

  @override
  String get guardrailScopeAgent => 'Agent';

  @override
  String get guardrailScopeSpace => 'Yta';

  @override
  String get guardrailSelectAgent => 'Välj en agent';

  @override
  String get guardrailSelectSpace => 'Välj en yta';

  @override
  String get guardrailNoAgents => 'Inga agenter i den här arbetsytan ännu.';

  @override
  String get guardrailNoSpaces => 'Inga ytor i den här arbetsytan ännu.';

  @override
  String get guardrailClassFileDelete => 'Ta bort en fil';

  @override
  String get guardrailClassFileWriteOutsideWorktree => 'Skriv utanför worktree';

  @override
  String get guardrailClassGitCommit => 'Skapa en commit';

  @override
  String get guardrailClassGitPush => 'Pusha till en remote';

  @override
  String get guardrailClassPrCreate => 'Öppna en pull request';

  @override
  String get guardrailClassPrPublish =>
      'Publicera en granskning eller sammanslagning';

  @override
  String get guardrailClassVendorSyncWrite =>
      'Skriv till ett externt ärendesystem';

  @override
  String get guardrailClassNetworkEgress => 'Använd nätverket';

  @override
  String get guardrailClassSecretAccess => 'Läs en hemlighet';

  @override
  String get guardrailClassPackageInstall => 'Installera ett paket';

  @override
  String get guardrailClassProcessSpawn => 'Kör en process';

  @override
  String get guardrailClassWorkspaceMutation => 'Ändra arbetsytans struktur';

  @override
  String get guardrailClassEnclosureControl =>
      'Styr en avskild miljö (station)';

  @override
  String get navRigs => 'Stationer';

  @override
  String get rigsUnsupportedServer =>
      'Den här servern kan inte vara värd för några rig-ytor. Kontrollera värdkraven för datorn du vill använda.';

  @override
  String get rigSurfaceComputer => 'Dator';

  @override
  String get rigSurfaceBrowser => 'Webbläsare';

  @override
  String get rigSurfaceAndroid => 'Android';

  @override
  String get rigSurfaceIosSimulator => 'iOS-simulator';

  @override
  String rigSurfaceBrowserEngine(String engine) {
    return '$engine';
  }

  @override
  String rigBrowserEngineHint(String engine) {
    return 'En tillfällig $engine, isolerad från din maskin. Öppna en annan motor för att jämföra samma sida sida vid sida.';
  }

  @override
  String get rigPhaseReady => 'Redo';

  @override
  String get rigPhaseStarting => 'Startar';

  @override
  String get rigPhaseParked => 'Parkerad';

  @override
  String get rigPhaseClosing => 'Stänger';

  @override
  String get rigPhaseClosed => 'Stängd';

  @override
  String get rigPhaseFailed => 'Misslyckades';

  @override
  String get rigPhaseUnknown => 'Okänd';

  @override
  String get rigNotAccelerated => 'Emulerad';

  @override
  String get rigAudioListen => 'Lyssna på maskinen';

  @override
  String get rigAudioMute => 'Stäng av ljudet från maskinen';

  @override
  String get rigYouHaveControl => 'Du har kontrollen';

  @override
  String get rigBackendAvailable => 'Tillgänglig';

  @override
  String get rigBackendUnavailable => 'Otillgänglig';

  @override
  String get rigEgressNotEnforced =>
      'Nätverket är inte avskilt på den här backend:en – den sköter sin egen anslutning.';

  @override
  String get rigStartMachine => 'Starta maskinen';

  @override
  String get rigStartHint =>
      'Startar en tillfällig VM som du och dina agenter delar för det här samtalet. Den tas bort när den stängs, och ingenting i den rör din dator.';

  @override
  String get rigStartAndroidHint =>
      'Ansluter till en Android-emulator som redan körs på servern. Nätverksåtkomsten är inte isolerad.';

  @override
  String get rigStartIosHint =>
      'Skapar en tillfällig iOS-simulator på serverns Mac. Den tas bort när testmiljön stängs; nätverksåtkomsten är inte isolerad.';

  @override
  String get rigTechnicalDetails => 'Tekniska detaljer';

  @override
  String get rigStopMachine => 'Stoppa maskinen';

  @override
  String get rigSurfaceUnavailable =>
      'Den här servern kan inte köra den här typen av maskin.';

  @override
  String get rigTabNeedsConversation =>
      'Öppna ett samtal först – en maskin hör till ett, så att du och dina agenter tittar på samma skärm.';

  @override
  String get ideMenuSectionTools => 'Verktyg';

  @override
  String get ideMenuSectionMachines => 'Datorer';

  @override
  String get ideMenuSectionReopen => 'Öppna igen';

  @override
  String get ideMenuSearchHint => 'Sök';

  @override
  String get ideMenuNoMatches => 'Inga träffar';

  @override
  String get rigMenuComputer => 'Dator';

  @override
  String get rigMenuBrowser => 'Webbläsare';

  @override
  String get rigMenuAndroid => 'Android';

  @override
  String get rigMenuIosSimulator => 'iOS-simulator';

  @override
  String rigLabelNumbered(String label, String suffix) {
    return '$label $suffix';
  }

  @override
  String ideCloseKeepTitle(String name) {
    return 'Stänga $name?';
  }

  @override
  String get ideCloseKeepBodyMachine =>
      'Maskinen fortsätter i bakgrunden – öppna den när som helst från sidofältet. Stäng av den i stället för att frigöra minnet nu.';

  @override
  String get ideCloseKeepBodyShell =>
      'Kommandot fortsätter i bakgrunden – öppna skalet när som helst från sidofältet. Avsluta det i stället för att stoppa det som körs nu.';

  @override
  String get ideCloseKeepBodyAgent =>
      'Agenten fortsätter i bakgrunden – öppna samtalet när som helst från sidofältet. Stoppa den i stället för att avsluta körningen nu.';

  @override
  String get ideCloseKeepRunning => 'Fortsätt köra';

  @override
  String get ideCloseShutDownMachine => 'Stäng av';

  @override
  String get ideCloseEndShell => 'Avsluta skal';

  @override
  String get ideCloseStopAgent => 'Stoppa agent';

  @override
  String get rigsSettingsSubtitle =>
      'Vad den här servern kan starta, basavbildningarna den behöver och maskinerna som körs nu';

  @override
  String get rigsCapabilitiesTitle => 'Den här servern';

  @override
  String get rigInstallIosAutomation =>
      'Installera brygga för iOS-automatisering';

  @override
  String get rigInstallingIosAutomation =>
      'Installerar brygga för iOS-automatisering…';

  @override
  String get rigIosAutomationInstalled =>
      'Brygga för iOS-automatisering har installerats';

  @override
  String get rigsImagesTitle => 'Basavbildningar';

  @override
  String get rigsImagesHint =>
      'Varje station startar från en av dessa skrivskyddade avbildningar. Varje session skriver till ett tillfälligt överlägg, så en station kan aldrig ändra vad nästa startar från.';

  @override
  String get rigsRunningTitle => 'Körs nu';

  @override
  String get rigsNoneRunning => 'Inga maskiner körs.';

  @override
  String get rigsCustomImagesTitle => 'Egna avbildningar (den här arbetsytan)';

  @override
  String get rigsCustomImagesHint =>
      'Peka Terminal (VM) eller Webbläsare (VM) mot en egen avbildning – utöka standarderna med verktygen projektet behöver, eller använd en kompatibel från ett register. Nya maskiner använder den; redan igång behåller sina. Se stationsguiden för vad en avbildning måste tillhandahålla.';

  @override
  String get rigsCustomTerminalImageLabel => 'Terminal (VM)-avbildning';

  @override
  String get rigsCustomBrowserImageLabel => 'Webbläsare (VM)-avbildning';

  @override
  String get rigsCustomImagePlaceholder =>
      't.ex. ghcr.io/acme/dev-shell:1.2 – lämna tomt för standard';

  @override
  String get rigsCustomImageInvalid =>
      'Ange en registerreferens som repo/name:tag. Lokala sökvägar och arkivfiler tillåts inte.';

  @override
  String get rigsCustomImageSaved =>
      'Sparad. Nya maskiner startar den här avbildningen; redan igång behåller sina.';

  @override
  String get rigsEgressTitle => 'Webbläsarutgång (den här arbetsytan)';

  @override
  String get rigsEgressHint =>
      'Extra värdar den avskilda webbläsaren får nå – en per rad: en exakt värd (api.example.com) eller ett jokertecken för dess underdomäner (*.example.com). Produktsajten är alltid tillåten. Nya maskiner får listan; redan igång behåller det de startade med.';

  @override
  String rigsEgressInvalid(String host) {
    return '\"$host\" är inte en giltig värdpost.';
  }

  @override
  String get rigsEgressSaved =>
      'Sparad. Nya webbläsarmaskiner släpper in de här värdarna; redan igång behåller sina.';

  @override
  String get rigImageInstalled => 'Installerad';

  @override
  String get rigImageNotDownloaded => 'Inte hämtad';

  @override
  String get rigImageNotPublished => 'Inte publicerad';

  @override
  String get rigImageNotPublishedHint =>
      'Ingen avbildning har publicerats för det här ännu, så det finns inget att hämta. Importera en kompatibel diskavbildning för att aktivera den.';

  @override
  String get rigImageDownload => 'Hämta';

  @override
  String get rigImageDownloading => 'Hämtar…';

  @override
  String get rigImageImport => 'Importera';

  @override
  String get rigImageImportMessage =>
      'Sökväg till en qcow2-diskavbildning på serverns filsystem. Den kopieras till avbildningslagret, så filen kan flyttas efteråt.';

  @override
  String get rigConnectingStream => 'Ansluter till stationen';

  @override
  String get rigStreamNotAllowed =>
      'Du har inte åtkomst till den här stationen.';

  @override
  String get rigStreamNotRunning => 'Den här stationen körs inte längre.';

  @override
  String get rigStreamNeedsFfmpeg =>
      'Livevy behöver ffmpeg på den här värden. Installera ffmpeg och öppna fliken igen.';

  @override
  String get rigStreamEnded => 'Livevyn avslutades.';

  @override
  String get rigStreamFailed => 'Livevyn kunde inte öppnas.';

  @override
  String get rigStreamDisconnected => 'Inte ansluten till en server.';

  @override
  String rigDropSendingOne(String name) {
    return 'Kopierar \"$name\" till maskinen…';
  }

  @override
  String rigDropSendingMany(int count) {
    return 'Kopierar $count filer till maskinen…';
  }

  @override
  String get rigTerminalDropSending => 'Kopierar till maskinen…';

  @override
  String get rigTerminalPasteImage => 'Inklistrad bild sparad i maskinen';

  @override
  String get rigPortsTitle => 'Vidarebefordrade portar';

  @override
  String get rigPortsTooltip => 'Portar som är öppna i den här maskinen';

  @override
  String get rigPortsEmpty =>
      'Inget lyssnar ännu. Starta en server i terminalen – en utvecklingserver på port 3000 syns här.';

  @override
  String get rigPortsAdd => 'Lägg till port';

  @override
  String get rigPortsAddHint => 'Gästport att vidarebefordra (t.ex. 3000)';

  @override
  String get rigPortsAutoForward => 'Vidarebefordra portar automatiskt';

  @override
  String get rigPortsCopyUrl => 'Kopiera lokal URL';

  @override
  String rigPortsCopiedUrl(String url) {
    return 'Kopierade $url';
  }

  @override
  String get rigPortsStopForward => 'Stoppa vidarebefordran';

  @override
  String get rigPortsExposeLan => 'Dela på det lokala nätverket';

  @override
  String get rigPortsLanPrivate => 'Endast lokalt';

  @override
  String get rigPortsLanShared => 'På nätverket';

  @override
  String get rigPortsSetDomain => 'Ange en webbläsardomän (.test)';

  @override
  String get rigPortsDomainHint =>
      'Domän för Webbläsare (VM), t.ex. myapp.test – nåbar där, inte på värden';

  @override
  String get rigPortsProcessUnknown => 'okänd process';

  @override
  String get rigPortsInactive => 'lyssnar inte';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count basavbildningar kvar att hämta',
      one: '1 basavbildning kvar att hämta',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => 'Tillåt';

  @override
  String get guardrailDecisionPrompt => 'Fråga först';

  @override
  String get guardrailDecisionDeny => 'Neka';

  @override
  String get guardrailSourceThisScope => 'Det här omfånget';

  @override
  String get guardrailSourceDefault => 'Inbyggd standard';

  @override
  String get guardrailSourcePreset => 'Lägesförinställning';

  @override
  String get guardrailSourceInherited => 'Ärvt';

  @override
  String get guardrailClearToInherited => 'Återställ till ärvt';

  @override
  String get guardrailWhatIf => 'Tänk om?';

  @override
  String get guardrailWhatIfDescription =>
      'Se hur de aktuella reglerna skulle lösa en åtgärd, med samma logik som agenterna kör mot.';

  @override
  String get guardrailProbeActionLabel => 'Åtgärd';

  @override
  String get guardrailProbeCommandLabel => 'Kommando (valfritt)';

  @override
  String get guardrailProbeCommandHint => 't.ex. git push origin main';

  @override
  String get guardrailProbeAgentLabel => 'Agent (valfritt)';

  @override
  String get guardrailProbeSpaceLabel => 'Yta (valfritt)';

  @override
  String get guardrailProbeNone => 'Ingen';

  @override
  String get guardrailProbeModeLabel => 'Läge';

  @override
  String get guardrailProbeResult => 'Resultat';

  @override
  String get guardrailProbeSource => 'Källa:';

  @override
  String get guardrailAdapterMatrix => 'Var regler verkställs';

  @override
  String get guardrailAdapterMatrixDescription =>
      'Ärlig referens: var varje effekt faktiskt fångas, per agentkörare. Det här dokumenterar verkligheten, inte en garanti – effekter en körare gör utanför bandet kan inte fångas.';

  @override
  String get guardrailEffectColumn => 'Effekt';

  @override
  String get guardrailAdapterHarness => 'Inbyggd harness';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => 'Sandlådegolv';

  @override
  String get guardrailEnforcementPolicyGate => 'Policygrind';

  @override
  String get guardrailEnforcementSandbox => 'Endast sandlåda';

  @override
  String get guardrailEnforcementNone => 'Kan inte verkställas';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      'Behörighetsbeslutet kontrolleras innan effekten körs och kan blockera den.';

  @override
  String get guardrailEnforcementSandboxHelp =>
      'Bara sandlådan begränsar den; behörighetsregeln konsulteras inte.';

  @override
  String get guardrailEnforcementNoneHelp =>
      'Beslutet är bara rådgivande – det kan inte fångas här.';

  @override
  String get obsStatCost => 'kostnad';

  @override
  String obsStatDelegatedCost(String amount) {
    return '+$amount delegerat';
  }

  @override
  String get obsStatDuration => 'varaktighet';

  @override
  String get obsStatTokens => 'tokens';

  @override
  String get obsStatTools => 'verktyg';

  @override
  String get openAgentActivity => 'Öppna aktivitet';

  @override
  String get orgChart => 'Organisationsschema';

  @override
  String get orgChartEmpty => 'Inga agenter ännu';

  @override
  String get navCalendar => 'Kalender';

  @override
  String get serverConnection => 'Serveranslutning';

  @override
  String get serverModeLocal => 'Kör i den här appen';

  @override
  String get serverModeLocalDescription =>
      'Control Center kör en egen server på den här maskinen och äger din data lokalt.';

  @override
  String get serverModeRemote => 'Anslut till en fjärrinstans';

  @override
  String get serverModeRemoteDescription =>
      'Anslut till en Control Center-server som körs någon annanstans. Din data ligger på den servern.';

  @override
  String get serverRemoteUrl => 'Server-URL';

  @override
  String get serverRemoteDeviceId => 'Enhets-ID';

  @override
  String get serverRemotePairingKey => 'Parkopplingsnyckel';

  @override
  String get serverRemotePairingKeyHint =>
      'Klistra in parkopplingsnyckeln från fjärrservern';

  @override
  String get serverSetupInviteCode => 'Inbjudningskod';

  @override
  String get serverSetupInviteCodeHint =>
      'Klistra in en engångsinbjudningskod (lämna tomt för att använda en parkopplingsnyckel)';

  @override
  String get serverDiscoveryTooltip => 'Hitta servrar på ditt nätverk';

  @override
  String get serverDiscoveryTitle => 'Servrar på ditt nätverk';

  @override
  String get serverDiscoverySearching => 'Söker efter servrar…';

  @override
  String get serverDiscoveryEmpty =>
      'Inga servrar hittades. Kontrollera att servern körs och att den här enheten når den, och sök sedan igen.';

  @override
  String get serverDiscoveryRefresh => 'Sök igen';

  @override
  String get serverListActive => 'Aktiv';

  @override
  String get serverListSwitch => 'Byt';

  @override
  String get serverListAddTitle => 'Lägg till server';

  @override
  String get serverListRemoveActiveHint =>
      'Byt till en annan server innan du tar bort den här.';

  @override
  String get serverSwitchFailedTitle => 'Kunde inte byta server';

  @override
  String get serverListInsecureBadge => 'Osäker';

  @override
  String get connectionPathLocal => 'Lokal';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => 'Stänger av';

  @override
  String get shutdownSubtitle => 'Stänger den lokala servern';

  @override
  String get shutdownServiceApprovals => 'Godkännanden';

  @override
  String get shutdownServiceBackgroundJobs => 'Bakgrundsjobb';

  @override
  String get shutdownServiceScheduler => 'Jobbschemaläggare';

  @override
  String get shutdownServiceCalendar => 'Kalendersynk';

  @override
  String get shutdownServiceWeather => 'Väder';

  @override
  String get shutdownServiceSoundscape => 'Ljudlandskap';

  @override
  String get shutdownServiceMeetings => 'Möten';

  @override
  String get shutdownServiceVoiceModels => 'Röstmodeller';

  @override
  String get shutdownServiceNetworking => 'Nätverk';

  @override
  String get shutdownServicePresence => 'Närvaro';

  @override
  String get shutdownServiceDataSync => 'Datasynk';

  @override
  String get shutdownServiceDeviceRelay => 'Enhetsrelä';

  @override
  String get shutdownServiceMcpConnections => 'MCP-anslutningar';

  @override
  String get shutdownServiceCodeEditors => 'Kodredigerare';

  @override
  String get serverSharingTitle => 'Dela den här servern';

  @override
  String get serverSharingDescription =>
      'Gör den här servern nåbar från dina andra enheter. Ingenting exponeras publikt om du inte slår på en tunnel nedan. Parkopplingsinbjudningar bäddar in serverns aktuella adresser automatiskt – skapa dem under arbetsyteinställningar.';

  @override
  String get serverSharingUnavailable =>
      'Delningskontroller saknas på den här servern.';

  @override
  String get serverSharingMdnsLabel => 'LAN-upptäckt';

  @override
  String get serverSharingMdnsOn =>
      'Annonserar den här servern på ditt lokala nätverk (mDNS)';

  @override
  String get serverSharingMdnsOff =>
      'Annonserar inte på ditt lokala nätverk (mDNS)';

  @override
  String get serverSharingTunnelLabel => 'Tunnel';

  @override
  String get serverSharingTunnelHelper =>
      'Att slå på en tunnel gör den här servern nåbar från internet. Publik exponering är valfri och av som standard.';

  @override
  String get serverSharingProviderOff => 'Av';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => 'Publik URL';

  @override
  String get serverSharingTunnelStarting => 'Startar tunneln…';

  @override
  String serverSharingTunnelError(String error) {
    return 'Tunnelfel: $error';
  }

  @override
  String get serverSharingTunnelUpNoUrl =>
      'Tunneln är uppe. Nå den på det konfigurerade DNS-värdnamnet.';

  @override
  String get serverSharingRelayLabel => 'Relä';

  @override
  String serverSharingRelayUsage(String amount) {
    return 'Reläat den här månaden: $amount';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return 'Aktiva reläsessioner: $count';
  }

  @override
  String get serverSharingUpdateFailedTitle => 'Kunde inte uppdatera delning';

  @override
  String get pairNewClient => 'Parkoppla en ny klient';

  @override
  String get pairClientNameHint => 'Namnge den här klienten (t.ex. Jobbdator)';

  @override
  String get pairClientTypeWeb => 'Webbläsare';

  @override
  String get pairClientTypeDesktop => 'Skrivbordsapp';

  @override
  String get pairClientTypePhone => 'Telefon';

  @override
  String get pairAction => 'Parkoppla';

  @override
  String get revoke => 'Återkalla';

  @override
  String get pairCredentialsIntro =>
      'Anslut den nya klienten med de här uppgifterna, eller öppna länken i den.';

  @override
  String get pairLinkLabel => 'Länk';

  @override
  String get pairScanQr =>
      'Skanna den här QR-koden med telefonens kamera för att parkoppla den.';

  @override
  String get pairServerUnreachableTitle => 'Inte nåbar';

  @override
  String get pairServerUnreachable =>
      'Andra enheter kan inte nå den här servern direkt, så en ny klient kan inte ansluta. Ange serverns publika URL för att parkoppla fler klienter.';

  @override
  String get serverSetupTitle => 'Hur ska Control Center köras?';

  @override
  String get serverSetupSubtitle =>
      'Control Center behöver en server som äger din data. Kör en i den här appen, eller anslut till en instans som körs någon annanstans.';

  @override
  String get serverSetupRunLocal => 'Kör i den här appen';

  @override
  String get serverSetupConnect => 'Anslut';

  @override
  String get serverSetupInvalidUrl =>
      'Ange en giltig ws://- eller wss://-server-URL.';

  @override
  String get serverSetupCouldNotConnect => 'Kunde inte ansluta';

  @override
  String get serverSetupErrorUnreachable =>
      'Vi kunde inte nå servern. Kontrollera att den körs och att den här enheten når den (samma nätverk eller relä).';

  @override
  String get serverSetupErrorIdentityMismatch =>
      'Serverns identitet stämmer inte med den som sparats på den här enheten. Om servern installerades om eller återställdes, ta bort den sparade servern och parkoppla igen.';

  @override
  String get serverSetupErrorAuthRejected =>
      'Servern avvisade den här enheten. Kontrollera att parkopplingsnyckeln och enhets-ID:t stämmer med vad servern utfärdade.';

  @override
  String get serverSetupErrorInviteRejected =>
      'Den inbjudningskoden är ogiltig eller har gått ut. Be om en ny.';

  @override
  String get serverSetupErrorGeneric =>
      'Något gick fel vid anslutningen. Visa de tekniska detaljerna nedan för mer information.';

  @override
  String get serverSetupErrorDetails => 'Tekniska detaljer';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count till',
      one: '1 till',
    );
    return '$_temp0';
  }

  @override
  String get calendarAllDayGutter => 'Heldag';

  @override
  String calendarAllDayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count händelser',
      one: '1 händelse',
    );
    return '$_temp0';
  }

  @override
  String get calendarCollapseAllDay => 'Fäll ihop heldagshändelser';

  @override
  String get calendarExpandAllDay => 'Visa heldagshändelser';

  @override
  String get calendarViewMonth => 'Månad';

  @override
  String get calendarViewWeek => 'Vecka';

  @override
  String get calendarViewAgenda => 'Agenda';

  @override
  String get calendarConnectGoogle => 'Anslut Google Calendar';

  @override
  String get calendarConnectDescription =>
      'Synka din Google Calendar för att se händelser här och få aviseringar innan möten börjar.';

  @override
  String get calendarDisconnect => 'Koppla från';

  @override
  String get calendarReconnect => 'Återanslut';

  @override
  String get calendarEmptyNoEvents => 'Inga händelser i det här intervallet';

  @override
  String get calendarStartRecording => 'Starta inspelning';

  @override
  String get calendarStartRecordingAndLink => 'Starta inspelning och länka';

  @override
  String get calendarJoinMeet => 'Anslut till mötet';

  @override
  String get calendarFromCalendar => 'Från kalender';

  @override
  String get calendarLinkedMeeting => 'Länkat möte';

  @override
  String get calendarToday => 'Idag';

  @override
  String get calendarAllDay => 'Heldag';

  @override
  String calendarWeekNumber(int number) {
    return 'Vecka $number';
  }

  @override
  String get calendarPreviousPeriod => 'Föregående';

  @override
  String get calendarNextPeriod => 'Nästa';

  @override
  String calendarLastSynced(String time) {
    return 'Synkad $time';
  }

  @override
  String get calendarNeverSynced => 'Inte synkad ännu';

  @override
  String get calendarSyncing => 'Synkar…';

  @override
  String get calendarViewDay => 'Dag';

  @override
  String get calendarShow => 'Visa';

  @override
  String get calendarHide => 'Dölj';

  @override
  String get calendarRsvpGoing => 'Kommer du?';

  @override
  String get calendarRsvpYes => 'Ja';

  @override
  String get calendarRsvpNo => 'Nej';

  @override
  String get calendarRsvpMaybe => 'Kanske';

  @override
  String get calendarRsvpFailed => 'Kunde inte uppdatera ditt svar';

  @override
  String get calendarAddAccount => 'Lägg till kalenderkonto';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Anslut ett Google-konto för att synka händelser till den här arbetsytan.';

  @override
  String get calendarConnecting => 'Ansluter…';

  @override
  String get calendarSyncNow => 'Synka nu';

  @override
  String get calendarNoWorkspace =>
      'Välj en arbetsyta för att se dess kalender';

  @override
  String get calendarConnectError => 'Kunde inte ansluta Google Calendar';

  @override
  String get calendarClientIdLabel => 'Klient-ID';

  @override
  String get calendarClientSecretLabel => 'Klienthemlighet';

  @override
  String get calendarConnectCredsHint =>
      'Ange Google OAuth device-code-klient-ID och hemlighet för ditt projekt. Servern sköter anslutning och synk – webbläsaren håller aldrig tokens.';

  @override
  String get calendarConnectApproveInstruction =>
      'Öppna verifieringssidan på valfri enhet, logga in och ange den här koden:';

  @override
  String get calendarConnectOpenPage => 'Öppna verifieringssida';

  @override
  String get calendarConnectWaiting => 'Väntar på godkännande…';

  @override
  String get calendarConnectDenied => 'Auktoriseringen nekades. Försök igen.';

  @override
  String get calendarConnectExpired => 'Koden har gått ut. Försök igen.';

  @override
  String get notificationMeetingStartsSoon => 'Mötet börjar snart';

  @override
  String get notifyMeetingStartsSoon =>
      'När ett kalendermöte är på väg att börja';

  @override
  String get notificationCalendarAuthExpiredTitle => 'Kalender frånkopplad';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'Återanslut $email för att fortsätta synka';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'Återanslut din kalender för att fortsätta synka';

  @override
  String get notifyCalendarAuthExpired =>
      'När ett kalenderkonto behöver återanslutas';

  @override
  String get notificationRigStatusChanged => 'Uppdateringar av avskild miljö';

  @override
  String get notifyRigStatusChanged =>
      'När en avskild miljö tas över, återtas eller misslyckas';

  @override
  String get notificationRigTakenOver => 'Avskild miljö övertagen';

  @override
  String get notificationRigTakenOverBody =>
      'En person kör maskinen; agenten kan titta men inte agera.';

  @override
  String get notificationRigReleased => 'Kontroll av avskild miljö släppt';

  @override
  String get notificationRigReleasedBody => 'Agenten har maskinen tillbaka.';

  @override
  String get notificationRigReclaimed => 'Avskild miljö återtagen';

  @override
  String get notificationRigReclaimedBodyIdle =>
      'Den stod overksam, så maskinen stängdes för att frigöra minne.';

  @override
  String get notificationRigReclaimedBodyTtl =>
      'Den nådde tidsgränsen och stängdes.';

  @override
  String get notificationRigFailed => 'Avskild miljö misslyckades';

  @override
  String get notificationRigFailedBody =>
      'Hypervisorn dog under den. Öppna maskinen igen för att fortsätta.';

  @override
  String get calendarAlertLeadTime => 'Förvarningstid';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'Hur långt före ett möte du ska aviseras';

  @override
  String calendarConnectedAs(String email) {
    return 'Ansluten som $email';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count deltagare';
  }

  @override
  String get calendarEventLabel => 'Händelse';

  @override
  String get calendarRecurring => 'Återkommande händelse';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'Organisatör';

  @override
  String get calendarYou => 'Du';

  @override
  String get calendarShowFewer => 'Visa färre';

  @override
  String get calendarRsvpAwaiting => 'Väntar';

  @override
  String calendarParticipantsCount(int count) {
    return '$count deltagare';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'Visa alla $count deltagare';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count ja';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count nej';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count kanske';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count väntar';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count minuter';
  }

  @override
  String get openInEditorPrompt => 'Öppna i vilken redigerare?';

  @override
  String get ideNotInstalled => 'Inte installerad';

  @override
  String openInIde(String editor) {
    return 'Öppna i $editor';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return 'Kunde inte öppna $editor: $error';
  }

  @override
  String get profileSearchHint => 'Sök pull requests…';

  @override
  String get stopAgentRun => 'Stoppa körning';

  @override
  String get stopAgentRunConfirm =>
      'Stoppa den här körningen? Pågående arbete går förlorat.';

  @override
  String get inProgress => 'Pågår';

  @override
  String get drafts => 'Utkast';

  @override
  String get sortOldest => 'Äldst';

  @override
  String get sortLargest => 'Störst';

  @override
  String get prFilterTooltip => 'Filter';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aktiva filter',
      one: '1 aktivt filter',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => 'Lägg till filter…';

  @override
  String get prFilterFieldHint => 'Filtrera…';

  @override
  String get prFilterCategoryStatus => 'Status';

  @override
  String get prFilterCategoryAuthor => 'Författare';

  @override
  String get prFilterCategoryReviewer => 'Granskare';

  @override
  String get prFilterCategoryContent => 'Innehåll';

  @override
  String get prFilterCategoryRepoOwner => 'Arkivägare';

  @override
  String get prFilterCategoryRepoName => 'Arkivnamn';

  @override
  String get prFilterCategoryOpenedDate => 'Öppningsdatum';

  @override
  String get prFilterCategoryUpdatedDate => 'Uppdateringsdatum';

  @override
  String get prFilterQuickToReview => 'Snabb att granska';

  @override
  String get prFilterClearAll => 'Rensa filter';

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
      other: '$count alternativ som inte matchar någon pull request',
      one: '1 alternativ som inte matchar någon pull request',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => 'Titel eller brödtext innehåller…';

  @override
  String get prFilterNoOptions => 'Inga matchande alternativ';

  @override
  String get prFilterChipIs => 'är';

  @override
  String get prFilterChipIsAnyOf => 'är någon av';

  @override
  String get prFilterChipContains => 'innehåller';

  @override
  String get prFilterChipSince => 'sedan';

  @override
  String get prFilterAddFilterButton => 'Lägg till filter';

  @override
  String prFilterClearCategory(String category) {
    return 'Rensa $category-filter';
  }

  @override
  String get prFilterCurrentUser => 'Aktuell användare';

  @override
  String get prStatusDraft => 'Utkast';

  @override
  String get prStatusOpen => 'Öppen';

  @override
  String get prStatusInReview => 'Under granskning';

  @override
  String get prStatusChangesRequested => 'Ändringar begärda';

  @override
  String get prStatusApproved => 'Godkänd';

  @override
  String get prStatusMerged => 'Sammanslagen';

  @override
  String get prStatusClosed => 'Stängd';

  @override
  String get prDateWindowDay => '1 dag sedan';

  @override
  String get prDateWindowThreeDays => '3 dagar sedan';

  @override
  String get prDateWindowWeek => '1 vecka sedan';

  @override
  String get prDateWindowMonth => '1 månad sedan';

  @override
  String get prDateWindowThreeMonths => '3 månader sedan';

  @override
  String get prDateWindowSixMonths => '6 månader sedan';

  @override
  String get prDateWindowYear => '1 år sedan';

  @override
  String get prDisplayOptions => 'Visningsalternativ';

  @override
  String get prDisplayGrouping => 'Gruppering';

  @override
  String get prDisplayOrdering => 'Sortering';

  @override
  String get prDisplayShowDrafts => 'Visa utkast';

  @override
  String get prDisplayMergedWindow => 'Sammanslagningsfönster';

  @override
  String get prDisplayMergedWindowDay => 'Senaste dagen';

  @override
  String get prDisplayMergedWindowWeek => 'Senaste veckan';

  @override
  String get prDisplayMergedWindowMonth => 'Senaste månaden';

  @override
  String get prDisplayProperties => 'Visningsegenskaper';

  @override
  String get prGroupingRepository => 'Arkiv';

  @override
  String get prGroupingAuthor => 'Författare';

  @override
  String get prGroupingStatus => 'Status';

  @override
  String get prGroupingNone => 'Ingen gruppering';

  @override
  String get prPropertyRepository => 'Arkiv';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => 'Gren';

  @override
  String get prPropertyUpdated => 'Uppdaterad';

  @override
  String get prPropertyAuthor => 'Författare';

  @override
  String get prPropertyChecks => 'Kontroller';

  @override
  String get prPropertyDiff => 'Diff';

  @override
  String get prPropertyComments => 'Kommentarer';

  @override
  String get keybindingOpenFilterMenu => 'Öppna filtermeny';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'Öppna filtermenyn för pull request';

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count valda',
      one: '1 vald',
    );
    return '$_temp0';
  }

  @override
  String get summary => 'Sammanfattning';

  @override
  String get kbMove => 'flytta';

  @override
  String get kbTabs => 'flikar';

  @override
  String get kbSearch => 'sök';

  @override
  String get kbViewed => 'visad';

  @override
  String get kbCollapse => 'fäll ihop';

  @override
  String get appearance => 'Utseende';

  @override
  String get appearanceSettingsDescription => 'Tema, språk och typografi.';

  @override
  String get notificationsSettingsDescription =>
      'Välj vilka agent- och arbetsytehändelser som aviserar dig.';

  @override
  String get advanced => 'Avancerat';

  @override
  String get accounts => 'Konton';

  @override
  String get mcpServers => 'MCP-servrar';

  @override
  String get mcpServersSettingsDescription =>
      'Inbyggd MCP-server och externa MCP-servrar.';

  @override
  String get remoteControlAndDevices => 'Fjärrstyrning och enheter';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'Parkoppla telefoner och konfigurera fjärrstyrningsservern.';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'Tal- och diariseringsmodellerna den här servern kör.';

  @override
  String get needsSetupLabel => 'Behöver konfigureras';

  @override
  String get collapseSidebar => 'Fäll ihop sidofält';

  @override
  String get expandSidebar => 'Visa sidofält';

  @override
  String get filterSpacesHint => 'Filtrera ytor';

  @override
  String noSpacesMatch(String query) {
    return 'Inga ytor matchar \"$query\"';
  }

  @override
  String get privacy => 'Integritet';

  @override
  String get sendDiffContentTitle => 'Skicka diffinnehåll till AI-adaptern';

  @override
  String get diffSharingOnSubtitle =>
      'Råa diffrader ingår i agentpromptar för djupare granskning.';

  @override
  String get diffSharingOffSubtitle =>
      'Agenter använder bara strukturerad metadata (filsökvägar, radnummer, PR-beskrivning); ingen rå kod lämnar appen.';

  @override
  String get errorReportingTitle => 'Dela kraschrapporter';

  @override
  String get errorReportingOnSubtitle =>
      'Diagnostik för krasch, fel och prestanda skickas för att hjälpa till att rätta buggar (endast releasebyggen).';

  @override
  String get errorReportingOffSubtitle =>
      'Diagnostik är av. Inga krasch- eller felrapporter skickas.';

  @override
  String get onboardingDiagnosticsTitle =>
      'Hjälp till att förbättra Control Center';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'Skicka diagnostik för krasch, fel och prestanda så att vi kan rätta problem snabbare (endast releasebyggen). Du kan ändra det när som helst under Inställningar → Integritet.';

  @override
  String get blocked => 'Blockerad';

  @override
  String get idle => 'Overksam';

  @override
  String get noRunsYet => 'Inga körningar ännu';

  @override
  String get copyPath => 'Kopiera sökväg';

  @override
  String get copyRelativePath => 'Kopiera relativ sökväg';

  @override
  String get nameRequired => 'Namn krävs';

  @override
  String get import => 'Importera';

  @override
  String get noMatchingAgents => 'Inga agenter matchar ditt filter';

  @override
  String watchVideoOn(String provider) {
    return 'Titta på video på $provider';
  }

  @override
  String get branchTemplate => 'Mall för grenamn';

  @override
  String get branchTemplateDescription =>
      'Mönster för grenen som skapas när ett ärende startas i ett isolerat worktree.';

  @override
  String branchTemplatePreview(String example) {
    return 'Exempel: $example';
  }

  @override
  String get deletePipelineRun => 'Ta bort pipelinekörning';

  @override
  String deletePipelineRunConfirm(String template) {
    return 'Ta bort den här körningen av \"$template\"? Det går inte att ångra.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'Fel vid borttagning av pipelinekörning: $error';
  }

  @override
  String get deleteTicket => 'Ta bort ärende';

  @override
  String deleteTicketConfirm(String title) {
    return 'Ta bort \"$title\"? Det går inte att ångra.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'Fel vid borttagning av ärende: $error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return 'Ta bort \"$name\"? Länkade arkiv på disk rörs inte.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'Fel vid borttagning av arbetsyta: $error';
  }

  @override
  String get indexCode => 'Indexera kod';

  @override
  String get indexNoGrammars => 'Kodgrammatik inte installerad';

  @override
  String get indexFailed => 'Indexering misslyckades';

  @override
  String indexedSymbolsCount(int count) {
    return '$count symboler indexerade';
  }

  @override
  String get nodeConfigAdvanced => 'Avancerat';

  @override
  String get nodeConfigReducer => 'Reducerare';

  @override
  String get nodeConfigReducerHelp =>
      'Hur sammanslagning sker när den här utdatanyckeln redan har ett värde';

  @override
  String get nodeConfigTimeoutMs => 'Timeout (ms)';

  @override
  String get nodeConfigRetryAttempts => 'Antal omförsök';

  @override
  String get nodeConfigContinueOnFail =>
      'Fortsätt om det här steget misslyckas';

  @override
  String get nodeConfigTeamId => 'Team-ID';

  @override
  String get nodeConfigDispatchMode => 'Utskicksläge';

  @override
  String get nodeConfigOutputSchema => 'Utdataschema (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'JSON Schema som stegets utdata måste uppfylla';

  @override
  String get diffLineDisplay => 'Långa rader i diffar';

  @override
  String get diffLineDisplayDescription =>
      'Bryt långa rader eller rulla dem vågrätt';

  @override
  String get diffLineWrap => 'Bryt rader';

  @override
  String get diffLineScroll => 'Rulla vågrätt';

  @override
  String get actions => 'Åtgärder';

  @override
  String get activate => 'Aktivera';

  @override
  String get activity => 'Aktivitet';

  @override
  String get activityLabel => 'AKTIVITET';

  @override
  String get activitySearchHint => 'Sök aktivitet';

  @override
  String get activityNoMatches => 'Ingen aktivitet matchar dina filter';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$start–$end av $total';
  }

  @override
  String get activityPreviousPage => 'Föregående sida';

  @override
  String get activityNextPage => 'Nästa sida';

  @override
  String get activityNetworkLocal => 'Localhost';

  @override
  String get activityClearFilter => 'Rensa filter';

  @override
  String activityFilterIp(String ip) {
    return 'IP $ip';
  }

  @override
  String activityFilterCountry(String country) {
    return 'Land $country';
  }

  @override
  String get activitySavedWorkspaceLogo => 'Sparade arbetsytans logotyp';

  @override
  String activityVerbCreated(String target) {
    return 'Skapade $target';
  }

  @override
  String activityVerbUpdated(String target) {
    return 'Uppdaterade $target';
  }

  @override
  String activityVerbDeleted(String target) {
    return 'Tog bort $target';
  }

  @override
  String activityVerbAdded(String target) {
    return 'Lade till $target';
  }

  @override
  String activityVerbRemoved(String target) {
    return 'Tog bort $target';
  }

  @override
  String activityVerbInvited(String target) {
    return 'Bjöd in $target';
  }

  @override
  String activityVerbChanged(String target) {
    return 'Ändrade $target';
  }

  @override
  String activityVerbStarted(String target) {
    return 'Startade $target';
  }

  @override
  String activityVerbStopped(String target) {
    return 'Stoppade $target';
  }

  @override
  String activityVerbWrote(String target) {
    return 'Skrev $target';
  }

  @override
  String get activityTargetAgent => 'agent';

  @override
  String get activityTargetTicket => 'ärende';

  @override
  String get activityTargetWorkspace => 'arbetsyta';

  @override
  String get activityTargetRepository => 'arkiv';

  @override
  String get activityTargetMember => 'medlem';

  @override
  String get activityTargetInvite => 'inbjudan';

  @override
  String get activityTargetSpace => 'yta';

  @override
  String get activityTargetMessage => 'meddelande';

  @override
  String get activityTargetCache => 'cache';

  @override
  String get activityTargetFile => 'fil';

  @override
  String get activityTargetPipeline => 'pipeline';

  @override
  String get activityTargetTemplate => 'mall';

  @override
  String get activityTargetProvider => 'leverantör';

  @override
  String get activityTargetModel => 'modell';

  @override
  String get activityTargetSkill => 'färdighet';

  @override
  String get activityTargetTodo => 'att göra';

  @override
  String get activityTargetMeeting => 'möte';

  @override
  String get activityTargetProject => 'projekt';

  @override
  String get activityTargetTeam => 'team';

  @override
  String get activityTargetDevice => 'enhet';

  @override
  String get activityTargetPreference => 'inställning';

  @override
  String get activityTargetBudget => 'budget';

  @override
  String activityVerbApproved(String target) {
    return 'Godkände $target';
  }

  @override
  String activityVerbArchived(String target) {
    return 'Arkiverade $target';
  }

  @override
  String activityVerbAssigned(String target) {
    return 'Tilldelade $target';
  }

  @override
  String activityVerbBackedUp(String target) {
    return 'Säkerhetskopierade $target';
  }

  @override
  String activityVerbCancelled(String target) {
    return 'Avbröt $target';
  }

  @override
  String activityVerbCleared(String target) {
    return 'Rensade $target';
  }

  @override
  String activityVerbClosed(String target) {
    return 'Stängde $target';
  }

  @override
  String activityVerbCommitted(String target) {
    return 'Committade $target';
  }

  @override
  String activityVerbCompacted(String target) {
    return 'Kompakterade $target';
  }

  @override
  String activityVerbCompleted(String target) {
    return 'Slutförde $target';
  }

  @override
  String activityVerbConnected(String target) {
    return 'Anslöt $target';
  }

  @override
  String activityVerbContinued(String target) {
    return 'Fortsatt $target';
  }

  @override
  String activityVerbDisconnected(String target) {
    return 'Kopplade från $target';
  }

  @override
  String activityVerbDispatched(String target) {
    return 'Skickade ut $target';
  }

  @override
  String activityVerbDrained(String target) {
    return 'Tömde $target';
  }

  @override
  String activityVerbEnrolled(String target) {
    return 'Registrerade $target';
  }

  @override
  String activityVerbEstimated(String target) {
    return 'Uppskattade $target';
  }

  @override
  String activityVerbImported(String target) {
    return 'Importerade $target';
  }

  @override
  String activityVerbInstalled(String target) {
    return 'Installerade $target';
  }

  @override
  String activityVerbKilled(String target) {
    return 'Avslutade $target';
  }

  @override
  String activityVerbMarked(String target) {
    return 'Markerade $target';
  }

  @override
  String activityVerbMerged(String target) {
    return 'Slog samman $target';
  }

  @override
  String activityVerbOpened(String target) {
    return 'Öppnade $target';
  }

  @override
  String activityVerbPaused(String target) {
    return 'Pausade $target';
  }

  @override
  String activityVerbPolled(String target) {
    return 'Frågade $target';
  }

  @override
  String activityVerbPrepared(String target) {
    return 'Förberedde $target';
  }

  @override
  String activityVerbProcessed(String target) {
    return 'Bearbetade $target';
  }

  @override
  String activityVerbPublished(String target) {
    return 'Publicerade $target';
  }

  @override
  String activityVerbRefined(String target) {
    return 'Förfinade $target';
  }

  @override
  String activityVerbRefreshed(String target) {
    return 'Uppdaterade $target';
  }

  @override
  String activityVerbRegistered(String target) {
    return 'Registrerade $target';
  }

  @override
  String activityVerbRenamed(String target) {
    return 'Bytte namn på $target';
  }

  @override
  String activityVerbReordered(String target) {
    return 'Ändrade ordning på $target';
  }

  @override
  String activityVerbResponded(String target) {
    return 'Svarade på $target';
  }

  @override
  String activityVerbRestored(String target) {
    return 'Återställde $target';
  }

  @override
  String activityVerbResumed(String target) {
    return 'Återupptog $target';
  }

  @override
  String activityVerbRetried(String target) {
    return 'Försökte igen med $target';
  }

  @override
  String activityVerbReverted(String target) {
    return 'Ångrade $target';
  }

  @override
  String activityVerbReviewed(String target) {
    return 'Granskade $target';
  }

  @override
  String activityVerbRan(String target) {
    return 'Körde $target';
  }

  @override
  String activityVerbSelected(String target) {
    return 'Valde $target';
  }

  @override
  String activityVerbSent(String target) {
    return 'Skickade $target';
  }

  @override
  String activityVerbStaged(String target) {
    return 'Stagade $target';
  }

  @override
  String activityVerbSteered(String target) {
    return 'Styrde $target';
  }

  @override
  String activityVerbSubmitted(String target) {
    return 'Skickade in $target';
  }

  @override
  String activityVerbSynced(String target) {
    return 'Synkade $target';
  }

  @override
  String activityVerbToggled(String target) {
    return 'Växlade $target';
  }

  @override
  String activityVerbUninstalled(String target) {
    return 'Avinstallerade $target';
  }

  @override
  String activityVerbUnstaged(String target) {
    return 'Avstagade $target';
  }

  @override
  String get activityTargetActionPolicy => 'åtgärdspolicy';

  @override
  String get activityTargetGoalRun => 'målkörning';

  @override
  String get activityTargetRunLog => 'körningslogg';

  @override
  String get activityTargetWorkingMemory => 'arbetsminne';

  @override
  String get activityTargetRoutingPolicy => 'dirigeringspolicy';

  @override
  String get activityTargetAutonomy => 'autonomi';

  @override
  String get activityTargetCalendar => 'kalender';

  @override
  String get activityTargetChecker => 'kontroll';

  @override
  String get activityTargetEditor => 'redigerare';

  @override
  String get activityTargetConfirmation => 'bekräftelse';

  @override
  String get activityTargetTunnel => 'tunnel';

  @override
  String get activityTargetConversation => 'samtal';

  @override
  String get activityTargetCredentials => 'inloggningsuppgifter';

  @override
  String get activityTargetDictation => 'diktering';

  @override
  String get activityTargetAgentRun => 'agentkörning';

  @override
  String get activityTargetEvalSuite => 'eval-svit';

  @override
  String get activityTargetWorker => 'worker';

  @override
  String get activityTargetWorktree => 'worktree';

  @override
  String get activityTargetMcpServer => 'MCP-server';

  @override
  String get activityTargetMemoryAccessGrant => 'minnesåtkomst';

  @override
  String get activityTargetMemoryDomain => 'minnesdomän';

  @override
  String get activityTargetMemoryFact => 'minnesfakta';

  @override
  String get activityTargetMemoryPolicy => 'minnespolicy';

  @override
  String get activityTargetFeed => 'flöde';

  @override
  String get activityTargetNote => 'anteckning';

  @override
  String get activityTargetOrchestration => 'orkestrering';

  @override
  String get activityTargetPipelineRun => 'pipelinekörning';

  @override
  String get activityTargetPipelineTrigger => 'pipelinetrigger';

  @override
  String get activityTargetPlan => 'plan';

  @override
  String get activityTargetPlaybook => 'playbook';

  @override
  String get activityTargetPullRequest => 'pull request';

  @override
  String get activityTargetReview => 'granskning';

  @override
  String get activityTargetProcess => 'process';

  @override
  String get activityTargetProviderPolicy => 'leverantörspolicy';

  @override
  String get activityTargetReaction => 'reaktion';

  @override
  String get activityTargetReviewSpace => 'granskningsyta';

  @override
  String get activityTargetReviewStudio => 'granskningsstudio';

  @override
  String get activityTargetServerData => 'serverdata';

  @override
  String get activityTargetSoundscape => 'ljudlandskap';

  @override
  String get activityTargetSession => 'session';

  @override
  String get activityTargetTerminal => 'terminal';

  @override
  String get activityTargetTicketLink => 'ärendelänk';

  @override
  String get activityTargetTicketSync => 'ärendesynk';

  @override
  String get activityTargetProfile => 'profil';

  @override
  String get activityTargetVoiceProfile => 'röstprofil';

  @override
  String get activityTargetWeather => 'väderprognos';

  @override
  String get activityTargetWorkProduct => 'arbetsprodukt';

  @override
  String get activityChangedMemberRole => 'Ändrade en medlems roll';

  @override
  String get activityChangedMemberRepoAccess =>
      'Ändrade en medlems arkivåtkomst';

  @override
  String get activityUpdatedGitHubToken => 'Uppdaterade GitHub-token';

  @override
  String get activityRefreshedWeather => 'Uppdaterade väderprognosen';

  @override
  String get activitySetWeatherLocation => 'Angav väderplats';

  @override
  String get activityClearedWeatherLocation => 'Rensade väderplats';

  @override
  String get activityMarkedAllArticlesRead =>
      'Markerade alla artiklar som lästa';

  @override
  String get activityMarkedArticleRead => 'Markerade en artikel som läst';

  @override
  String get activityUpdatedSavedArticle => 'Uppdaterade en sparad artikel';

  @override
  String get activityTookOverSession => 'Tog över sessionen';

  @override
  String get activityHandedBackSession => 'Lämnade tillbaka sessionen';

  @override
  String get activityCommittedAndPushed => 'Committade och pushade';

  @override
  String get activityBackedUpServer => 'Säkerhetskopierade serverdatan';

  @override
  String get activityMarkedSpaceRead => 'Markerade ytan som läst';

  @override
  String get activityRespondedToInvitation => 'Svarade på evenemangsinbjudan';

  @override
  String get activityStartedCalendarConnect => 'Startade kalenderanslutningen';

  @override
  String get activityDisconnectedCalendar => 'Kopplade från kalendern';

  @override
  String get activityMarkedFileViewed => 'Markerade en fil som visad';

  @override
  String get activityRespondedToApproval =>
      'Svarade på en godkännandeförfrågan';

  @override
  String get activityChangedTunnel => 'Ändrade tunnelinställningen';

  @override
  String get activitySentMessageToAgent =>
      'Skickade ett meddelande till agenten';

  @override
  String get activityOpenedReviewSpace => 'Öppnade granskningsytan';

  @override
  String get activityOpenedStandingConversation =>
      'Öppnade det stående samtalet';

  @override
  String get activityStartedRecording => 'Startade inspelningen';

  @override
  String get activityStoppedRecording => 'Stoppade inspelningen';

  @override
  String get activityToggledMcpServer => 'Växlade MCP-servern';

  @override
  String get activityUpdatedMcpToken => 'Uppdaterade MCP-token';

  @override
  String get activitySavedApiKey => 'Sparade en API-nyckel';

  @override
  String get activityRemovedProviderCredential =>
      'Tog bort inloggningsuppgifter för en leverantör';

  @override
  String get activityUpdatedLinkedRepos => 'Uppdaterade de länkade arkiven';

  @override
  String get activityUnlinkedRepo => 'Avlänkade ett arkiv';

  @override
  String get activityUpdatedActionItem => 'Uppdaterade en åtgärdspunkt';

  @override
  String adRulesCount(int count) {
    return '$count annonsregler';
  }

  @override
  String get adapter => 'Adapter';

  @override
  String get adapterLabel => 'Adapter';

  @override
  String get adapters => 'Adaptrar';

  @override
  String get adaptersAutoDetected =>
      'Automatiskt hittade agentkörare på den här maskinen. Installera saknade CLI-verktyg för att aktivera fler körare.';

  @override
  String get add => 'Lägg till';

  @override
  String get addAComment => 'Lägg till en kommentar';

  @override
  String get addAReaction => 'Lägg till en reaktion';

  @override
  String get addASuggestion => 'Lägg till ett förslag';

  @override
  String get addAgents => 'Lägg till agenter';

  @override
  String get addEmoji => 'Lägg till emoji';

  @override
  String get addFeed => 'Lägg till flöde';

  @override
  String get addressBarHint => 'Ange en URL';

  @override
  String get addFromFile => 'Lägg till från fil';

  @override
  String get addGif => 'Lägg till GIF';

  @override
  String get addGithubRepoPrompt =>
      'Lägg till minst ett GitHub-arkiv för att se pull requests';

  @override
  String get addLocalCheckoutDescription =>
      'Lägg till en lokal checkout för att börja rikta den från den här arbetsytan.';

  @override
  String get addRepository => 'Lägg till arkiv';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lägg till $count arkiv',
      one: 'Lägg till arkiv',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro =>
      'Bläddra bland mapparna på maskinen som kör servern och välj git-checkouts att registrera.';

  @override
  String get selectThisFolder => 'Välj den här mappen';

  @override
  String get deselectThisFolder => 'Avmarkera den här mappen';

  @override
  String get goUp => 'Upp';

  @override
  String get noSubfoldersHere => 'Inga undermappar här';

  @override
  String get notAGitRepository => 'Den här mappen är inte ett git-arkiv.';

  @override
  String get addToken => 'Lägg till token';

  @override
  String get addWorkspace => 'Lägg till arbetsyta';

  @override
  String get addWorkspaceEllipsis => 'Lägg till arbetsyta…';

  @override
  String get added => 'Tillagd';

  @override
  String get addingEllipsis => 'Lägger till…';

  @override
  String get advancedLabel => 'Avancerat';

  @override
  String get agent => 'Agent';

  @override
  String agentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agenter',
      one: '1 agent',
    );
    return '$_temp0';
  }

  @override
  String get agentMdPath => 'Sökväg till Agent MD';

  @override
  String get agentName => 'Agentnamn';

  @override
  String get agentTitle => 'Agenttitel';

  @override
  String get agentUpdated => 'Agenten uppdaterades.';

  @override
  String get agents => 'Agenter';

  @override
  String get agentsMentionSection => 'Agenter';

  @override
  String get usersMentionSection => 'Personer';

  @override
  String get ticketsMentionSection => 'Ärenden';

  @override
  String get pullRequestsMentionSection => 'Pull requests';

  @override
  String get meetingsMentionSection => 'Möten';

  @override
  String get entityRefTicketFallback => 'Ärende';

  @override
  String get entityRefPrFallback => 'Pull request';

  @override
  String get entityRefMeetingFallback => 'Möte';

  @override
  String get aiReview => 'AI-granskning';

  @override
  String get all => 'Alla';

  @override
  String get allAgentsAlreadyInSpace => 'Alla agenter är redan i den här ytan.';

  @override
  String get allCommits => 'Alla commits';

  @override
  String get allSources => 'Alla källor';

  @override
  String get allow => 'Tillåt';

  @override
  String get allowGitPush => 'Tillåt git push';

  @override
  String get allowGithubApi => 'Tillåt GitHub API-anrop';

  @override
  String get allowNetwork => 'Tillåt allmän nätverksåtkomst';

  @override
  String get apiKeys => 'API-nycklar';

  @override
  String get appFont => 'Appteckensnitt';

  @override
  String get appLogLevelDebugDescription =>
      'Lägger till detaljerade spår – för utveckling.';

  @override
  String get appLogLevelDebugLabel => 'Felsökning';

  @override
  String get appLogLevelErrorDescription => 'Bara oväntade fel och undantag.';

  @override
  String get appLogLevelErrorLabel => 'Fel';

  @override
  String get appLogLevelInfoDescription =>
      'Lägger till livscykel- och statusmeddelanden.';

  @override
  String get appLogLevelInfoLabel => 'Info';

  @override
  String get appLogLevelNoneDescription => 'Ingen konsolutdata alls.';

  @override
  String get appLogLevelNoneLabel => 'Ingen';

  @override
  String get appLogLevelVerboseDescription =>
      'Allt. Extremt pratigt – använd bara vid felsökning.';

  @override
  String get appLogLevelVerboseLabel => 'Utförlig';

  @override
  String get appLogLevelWarningDescription =>
      'Lägger till varningar och återställningsbara problem.';

  @override
  String get appLogLevelWarningLabel => 'Varning';

  @override
  String get appearanceLanguage => 'Utseende och språk';

  @override
  String get apply => 'Tillämpa';

  @override
  String get approve => 'Godkänn';

  @override
  String get agentApprovalRequired => 'Godkännande krävs';

  @override
  String agentApprovalsMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count till väntar',
      one: '1 till väntar',
    );
    return '$_temp0';
  }

  @override
  String get approved => 'Godkänd';

  @override
  String get articleNoun => 'Artikel';

  @override
  String get articlesSubscribed => 'Artiklar från dina prenumererade flöden.';

  @override
  String get askAi => 'Fråga AI';

  @override
  String get askAiReviewDescription => 'Be AI granska den här PR:en';

  @override
  String get assignees => 'Tilldelade';

  @override
  String get attachImage => 'Bifoga bild';

  @override
  String get attachedAgents => 'Bifogade agenter';

  @override
  String get audioInput => 'Ljudingång';

  @override
  String get audioOutput => 'Ljudutgång';

  @override
  String get authenticationToken => 'Autentiseringstoken';

  @override
  String authoredByLabel(String role) {
    return 'Av: $role';
  }

  @override
  String get autoRecommended => 'Auto (rekommenderas)';

  @override
  String get available => 'Tillgänglig';

  @override
  String get awaitingYourReview => 'Väntar på din granskning';

  @override
  String get back => 'Tillbaka';

  @override
  String get backLabel => 'Tillbaka';

  @override
  String get backend => 'Backend';

  @override
  String get blockAdsTrackers => 'Blockera annonser, spårare och cookie-rutor';

  @override
  String get blocking => 'Blockerar';

  @override
  String get bookmarkLabel => 'Bokmärke';

  @override
  String get briefDescription => 'Kort beskrivning';

  @override
  String get bugLabel => 'BUGG';

  @override
  String get bundledDefaultsNeverUpdated =>
      'Medföljande standardvärden – aldrig uppdaterade';

  @override
  String get cancel => 'Avbryt';

  @override
  String get cancelEdit => 'Avbryt redigering';

  @override
  String get categoryCreation => 'Skapande';

  @override
  String get categoryEditing => 'Redigering';

  @override
  String get categoryNavigation => 'Navigering';

  @override
  String get categorySystem => 'System';

  @override
  String get categoryView => 'Kategorivy';

  @override
  String get change => 'Ändra';

  @override
  String get changesRequested => 'Ändringar begärda';

  @override
  String get spacesMentionSection => 'Ytor';

  @override
  String get checkForUpdates => 'Sök efter uppdateringar';

  @override
  String get checking => 'Kontrollerar';

  @override
  String get checkingEllipsis => 'Kontrollerar…';

  @override
  String get chooseAppFont => 'Välj appteckensnitt';

  @override
  String get chooseCodeFont => 'Välj kodteckensnitt';

  @override
  String get chooseRunner => 'Välj din agentkörare.';

  @override
  String get clear => 'Rensa';

  @override
  String get clickToRetry => 'Klicka för att försöka igen';

  @override
  String get close => 'Stäng';

  @override
  String get closeEsc => 'Stäng (Esc)';

  @override
  String get closeReader => 'Stäng läsaren';

  @override
  String get closed => 'Stängd';

  @override
  String get codeFont => 'Kodteckensnitt';

  @override
  String get codeFontLigatures => 'Ligaturer i kodteckensnitt';

  @override
  String get codeFontLigaturesDescription =>
      'Visa programmeringsligaturer (=>, !=, ->) som sammansatta glyfer i kod och diffar';

  @override
  String get collapse => 'Fäll ihop';

  @override
  String get commandPalette => 'Kommandopalett';

  @override
  String get commandPaletteOrgMembers => 'Organisationsmedlemmar';

  @override
  String get commandPaletteBrowseTeam => 'Bläddra i teamet';

  @override
  String get commandPaletteBrowseTeamDesc => 'Visa alla organisationsmedlemmar';

  @override
  String get compactDone =>
      'Samtalet kompakterades. Tidigare historik veks in i en sammanfattning.';

  @override
  String get compactNothing =>
      'Inget att kompaktera ännu. Samtalet är fortfarande kort.';

  @override
  String get compactBusy =>
      'En agent arbetar fortfarande. Kompaktera när turen är klar.';

  @override
  String get compactUnavailable => 'Kompaktering saknas på den här servern.';

  @override
  String get commandsMentionSection => 'Kommandon';

  @override
  String get comment => 'Kommentar';

  @override
  String get commentOnThisFile => 'Kommentera den här filen';

  @override
  String get commented => 'Kommenterade';

  @override
  String get commits => 'Commits';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'Visar de senaste $loaded av $total commits';
  }

  @override
  String get prCloneProgressCloningTitle => 'Klonar arkiv';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'Den här PR:en ändrar $fileCount filer, vilket överskrider GitHubs API-gräns. Klonar arkivet lokalt…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'Den här PR:en överskrider GitHubs API-filgräns. Klonar arkivet lokalt…';

  @override
  String get prCloneProgressFetchingTitle => 'Hämtar PR-refs';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'Hämtar basgrenen och PR-huvudref…';

  @override
  String get prCloneProgressComputingTitle => 'Beräknar diff';

  @override
  String get prCloneProgressComputingSubtitle => 'Kör git diff lokalt…';

  @override
  String get prCloneProgressErrorTitle => 'Kunde inte läsa in diff';

  @override
  String get prCloneProgressErrorSubtitle =>
      'Ett fel uppstod vid kloning eller beräkning av diffen. Försök uppdatera.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'Arbetar fortfarande… $elapsed har gått';
  }

  @override
  String confidenceLabel(int percent) {
    return 'Tillförlitlighet: $percent%';
  }

  @override
  String get configureAgentIdentities =>
      'Konfigurera agentidentiteter, promptar, färdigheter och visa körningar.';

  @override
  String get configureDefaultRunners =>
      'Konfigurera vilken adapter och modell som används för nya ytor och titelgenerering.';

  @override
  String get configuredLabel => 'Konfigurerad.';

  @override
  String get confirmedBy => 'Bekräftad av';

  @override
  String get consensus => 'Konsensus';

  @override
  String get contentHint => 'Vad som ska kommas ihåg';

  @override
  String get contentLabel => 'Innehåll';

  @override
  String get contentMarkdown => 'Innehåll (Markdown)';

  @override
  String get contextWindowSize => 'Storlek på kontextfönster';

  @override
  String modelContextChip(String size) {
    return 'Modell · $size';
  }

  @override
  String get continueLabel => 'Fortsätt';

  @override
  String get conversationMode => 'Läge';

  @override
  String cookieRulesCount(int count) {
    return '$count cookie-regler';
  }

  @override
  String get copied => 'Kopierat!';

  @override
  String get copy => 'Kopiera';

  @override
  String get copyAddress => 'Kopiera adress';

  @override
  String get copyBaseBranchTooltip => 'Kopiera basgrenens namn';

  @override
  String get copyHeadBranchTooltip => 'Kopiera huvudgrenens namn';

  @override
  String couldNotListDevices(String error) {
    return 'Kunde inte lista enheter: $error';
  }

  @override
  String get create => 'Skapa';

  @override
  String get createOrSelectWorkspace =>
      'Skapa eller välj en arbetsyta innan du lägger till arkiv.';

  @override
  String get createPullRequest => 'Skapa pull request';

  @override
  String get createdByMe => 'Skapade av mig';

  @override
  String createdLabel(String date) {
    return 'Skapad: $date';
  }

  @override
  String get currentParticipants => 'Aktuella deltagare';

  @override
  String get customCapabilitiesDescription => 'Beskrivning av egna förmågor';

  @override
  String get customSystemPrompt => 'Egen systemprompt för den här agenten...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagar sedan',
      one: '1 dag sedan',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'Inaktivera';

  @override
  String get defaultCapabilities => 'Standardförmågor · nya ytor';

  @override
  String get defaultChat => 'Standardchatt';

  @override
  String get defaultRunners => 'Standardkörare';

  @override
  String get delete => 'Ta bort';

  @override
  String get deleteAgent => 'Ta bort agent';

  @override
  String deleteAgentConfirm(String name) {
    return 'Ta bort \"$name\"? Det går inte att ångra.';
  }

  @override
  String get deleteSpace => 'Ta bort yta';

  @override
  String deleteConfirmName(String name) {
    return 'Ta bort \"$name\"?';
  }

  @override
  String get archiveConversation => 'Arkivera samtal';

  @override
  String get deleteFact => 'Ta bort fakta';

  @override
  String get deleteFeedBody =>
      'Det här tar bort flödet och alla cachade artiklar. Bokmärkta artiklar från det här flödet tas också bort.';

  @override
  String deleteFeedConfirm(String name) {
    return 'Ta bort \"$name\"?';
  }

  @override
  String get deletePolicy => 'Ta bort policy';

  @override
  String get deletePolicyConfirm =>
      'Ta bort den här policyn? Det går inte att ångra.';

  @override
  String deleteTopicConfirm(String topic) {
    return 'Ta bort \"$topic\"? Det går inte att ångra.';
  }

  @override
  String get deleteWorkspace => 'Ta bort arbetsyta';

  @override
  String get deny => 'Neka';

  @override
  String get detailsLabel => 'Detaljer';

  @override
  String get descriptionLabel => 'Beskrivning';

  @override
  String detectedBackend(String label) {
    return 'Upptäckt: $label';
  }

  @override
  String get detectedRunners => 'Upptäckta körare';

  @override
  String get detectingAdapters => 'Upptäcker adaptrar…';

  @override
  String get detectingInputDevices => 'Upptäcker inmatningsenheter…';

  @override
  String detectionFailed(String error) {
    return 'Upptäckt misslyckades: $error';
  }

  @override
  String get disabled => 'Inaktiverad';

  @override
  String get discover => 'Upptäck';

  @override
  String get dismissed => 'Avfärdad';

  @override
  String get domainHint => 't.ex. api-performance';

  @override
  String get domainLabel => 'Domän';

  @override
  String get download => 'Hämta';

  @override
  String get downloadingLabel => 'Hämtar';

  @override
  String downloadingModel(int pct) {
    return 'Hämtar modell… $pct%';
  }

  @override
  String get draft => 'Utkast';

  @override
  String get draftLabel => 'Utkast';

  @override
  String get edit => 'Redigera';

  @override
  String get edited => 'redigerad';

  @override
  String get editMessage => 'Redigera meddelande';

  @override
  String get deleteMessage => 'Ta bort meddelande';

  @override
  String get deleteMessageConfirm =>
      'Ta bort det här meddelandet? Det går inte att ångra.';

  @override
  String get messageDeleted => 'Meddelandet togs bort';

  @override
  String get searchInConversation => 'Sök i samtalet';

  @override
  String get searchMessagesHint => 'Sök meddelanden…';

  @override
  String get noMessagesFound => 'Inga meddelanden hittades';

  @override
  String get editFact => 'Redigera fakta';

  @override
  String get editPolicy => 'Redigera policy';

  @override
  String get editSuggestedCodeHint => 'Redigera föreslagen kod…';

  @override
  String get editSuggestion => 'Redigera förslag';

  @override
  String get egArchitect => 't.ex. architect';

  @override
  String get egControlCenter => 't.ex. control-center';

  @override
  String get egPlatform => 't.ex. macOS';

  @override
  String get egSamuelAlev => 't.ex. SamuelAlev';

  @override
  String get egSoftwareArchitect => 't.ex. Software Architect';

  @override
  String get egTheVerge => 't.ex. The Verge';

  @override
  String get egTokenLimit => 't.ex. 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'Installationen misslyckades: $error';
  }

  @override
  String get embeddingInstalled =>
      'Lokal inbäddningsmodell installerad. Hybridsökning är aktiverad.';

  @override
  String get embeddingModel => 'Inbäddningsmodell (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'Inte installerad. Sökning faller tillbaka till enbart nyckelord tills den aktiveras.';

  @override
  String get embeddingRedownloadBody =>
      'Befintliga modellfiler tas bort och hämtas igen. Semantisk sökning är otillgänglig tills hämtningen är klar.';

  @override
  String get embeddingRemoveBody =>
      'Semantisk sökning inaktiveras tills du installerar om den. Du kan installera den igen när som helst.';

  @override
  String get speakerDiarization => 'Talarseparation';

  @override
  String get diarizationModel => 'Diariseringsmodell';

  @override
  String get diarizationInstalled =>
      'Installerad – namnger enskilda talare i mötesutskrifter';

  @override
  String get diarizationNotInstalled =>
      'Inte installerad – mötessamtalare separeras inte';

  @override
  String diarizationInstallFailed(String error) {
    return 'Installationen misslyckades: $error';
  }

  @override
  String get redownloadDiarizationModel => 'Hämta diariseringsmodell igen';

  @override
  String get diarizationRedownloadBody =>
      'Det här tar bort de aktuella diariseringsmodellerna och hämtar dem igen.';

  @override
  String get removeDiarizationModel => 'Ta bort diariseringsmodell';

  @override
  String get diarizationRemoveBody =>
      'Det här tar bort diariseringsmodellerna på enheten. Mötesutskrifter som redan producerats påverkas inte.';

  @override
  String get enableNotifications => 'Aktivera aviseringar';

  @override
  String get enableSandboxing => 'Aktivera sandlåda';

  @override
  String get enabled => 'Aktiverad';

  @override
  String errorCreatingAgent(String error) {
    return 'Fel vid skapande av agent: $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'Fel vid borttagning av agent: $error';
  }

  @override
  String errorWithDetail(String error) {
    return 'Fel: $error';
  }

  @override
  String get expand => 'Visa mer';

  @override
  String extractingModel(int pct) {
    return 'Packar upp modell… $pct%';
  }

  @override
  String get fact => 'Fakta';

  @override
  String factCount(int count) {
    return '$count fakta';
  }

  @override
  String factCountPlural(int count) {
    return '$count fakta';
  }

  @override
  String get facts => 'Fakta';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount fakta · $policyCount policyer';
  }

  @override
  String get failed => 'Misslyckades';

  @override
  String failedToDispatch(String error) {
    return 'Kunde inte skicka ut: $error';
  }

  @override
  String get failedToLoad => 'Kunde inte läsa in';

  @override
  String failedToLoadAgents(String error) {
    return 'Kunde inte läsa in agenter: $error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'Kunde inte läsa in flöden: $error';
  }

  @override
  String get failedToLoadGifs => 'Kunde inte läsa in GIF:ar';

  @override
  String failedToLoadLogs(String error) {
    return 'Kunde inte läsa in loggar: $error';
  }

  @override
  String get failedToLoadRepos => 'Kunde inte läsa in arkiv';

  @override
  String get failedToLoadWorkspaces => 'Kunde inte läsa in arbetsytor';

  @override
  String failedToStartAiReview(String error) {
    return 'Kunde inte starta AI-granskning: $error';
  }

  @override
  String get failedToStartMicTest => 'Kunde inte starta mikrofontest.';

  @override
  String failedToSubmitReview(String error) {
    return 'Kunde inte skicka in granskning: $error';
  }

  @override
  String failedToUpload(String name, String error) {
    return 'Kunde inte ladda upp $name: $error';
  }

  @override
  String failedWithError(String error) {
    return 'Misslyckades: $error';
  }

  @override
  String get failure => 'Fel';

  @override
  String get feedAlreadyExists => 'Ett flöde med den här URL:en finns redan.';

  @override
  String get feedUrlExample => 't.ex. https://example.com/feed.xml';

  @override
  String get feedUrlLabel => 'Flödes-URL';

  @override
  String feedsCount(int count) {
    return 'Flöden ($count)';
  }

  @override
  String get filesChanged => 'Ändrade filer';

  @override
  String filesCount(int count) {
    return '$count fil(er)';
  }

  @override
  String get filesMentionSection => 'Filer';

  @override
  String get filterAgents => 'Filtrera agenter...';

  @override
  String get filterFilesHint => 'Filtrera filer…';

  @override
  String get filterLists => 'Filterlistor';

  @override
  String get filterSkillsPlaceholder => 'Filtrera färdigheter…';

  @override
  String get finish => 'Slutför';

  @override
  String get fix => 'Åtgärda';

  @override
  String get forward => 'Framåt';

  @override
  String get gatesGithubPatPush =>
      'Styr injicering av GitHub PAT. Krävs för att agenten ska kunna pusha.';

  @override
  String get general => 'Allmänt';

  @override
  String get githubLink => 'GitHub-länk';

  @override
  String get claudeStatusFetchFailed => 'Kunde inte nå status.claude.com';

  @override
  String get claudeStatusOpenInBrowser => 'Öppna status.claude.com';

  @override
  String get githubStatusFetchFailed => 'Kunde inte nå githubstatus.com';

  @override
  String get githubDegradedTitle => 'GitHub rapporterar problem';

  @override
  String githubDegradedStatusLine(String status) {
    return 'GitHub-status: $status.';
  }

  @override
  String githubDegradedBody(String status) {
    return 'GitHub-status: $status. Pull request-data kan vara inaktuell eller ofullständig tills det återhämtar sig.';
  }

  @override
  String get githubStatusOpenInBrowser => 'Öppna githubstatus.com';

  @override
  String get githubStatusRefresh => 'Uppdatera';

  @override
  String githubStatusUpdated(String time) {
    return 'Uppdaterad $time';
  }

  @override
  String get kimiStatusFetchFailed => 'Kunde inte nå status.moonshot.cn';

  @override
  String get kimiStatusOpenInBrowser => 'Öppna status.moonshot.cn';

  @override
  String get openaiStatusFetchFailed => 'Kunde inte nå status.openai.com';

  @override
  String get openaiStatusOpenInBrowser => 'Öppna status.openai.com';

  @override
  String get serviceStatusMaintenance => 'Underhåll';

  @override
  String get serviceStatusMajorIssues => 'Större problem';

  @override
  String get serviceStatusMinorIssues => 'Mindre problem';

  @override
  String get serviceStatusOperational => 'Fungerar';

  @override
  String get serviceStatusOutage => 'Avbrott';

  @override
  String get serviceStatusTitle => 'Tjänstestatus';

  @override
  String get serviceStatusUnknown => 'Okänd';

  @override
  String lastChecked(String time) {
    return 'Kontrollerad $time';
  }

  @override
  String get lastCheckedRecently => 'Kontrollerad nyligen';

  @override
  String get giveYourWorkAHome => 'Ge ditt arbete ett hem.';

  @override
  String get goBack => 'Gå tillbaka';

  @override
  String get goForward => 'Gå framåt';

  @override
  String get googleFonts => 'Google Fonts';

  @override
  String get high => 'Hög';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count timmar sedan',
      one: '1 timme sedan',
    );
    return '$_temp0';
  }

  @override
  String get images => 'Bilder';

  @override
  String get inactive => 'Inaktiv';

  @override
  String get install => 'Installera';

  @override
  String get installRequired => 'Installation krävs';

  @override
  String installedVersion(String version) {
    return 'Installerad $version';
  }

  @override
  String get invite => 'Bjud in';

  @override
  String get inviteAgent => 'Bjud in agent';

  @override
  String get isolateAgentExecution => 'Isolera agentkörning.';

  @override
  String get justNow => 'Just nu';

  @override
  String get keepSandboxing => 'Behåll sandlåda';

  @override
  String get keybindingAddARepositoryDescription => 'Lägg till ett arkiv';

  @override
  String get keybindingAddRepository => 'Lägg till arkiv';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'Bokmärk eller ta bort bokmärke för den valda artikeln';

  @override
  String get keybindingCommandPalette => 'Kommandopalett';

  @override
  String get keybindingCreateANewAgentDescription => 'Skapa en ny agent';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'Skapa en ny arbetsyta';

  @override
  String get keybindingFocusSearch => 'Fokusera sökfält';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'Fokusera sökfältet för pull request';

  @override
  String get keybindingNewAgent => 'Ny agent';

  @override
  String get keybindingNewWorkspace => 'Ny arbetsyta';

  @override
  String get keybindingNextArticle => 'Nästa artikel';

  @override
  String get keybindingNextSpace => 'Nästa yta';

  @override
  String get keybindingNextWorkspace => 'Nästa arbetsyta';

  @override
  String get keybindingOpenArticle => 'Öppna artikel';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'Öppna eller stäng växlaren för arbetsytor i sidofältet';

  @override
  String get keybindingOpenPr => 'Öppna PR';

  @override
  String get keybindingOpenSettings => 'Öppna inställningar';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'Öppna appinställningarna';

  @override
  String get keybindingOpenTheCommandPaletteDescription =>
      'Öppna kommandopaletten';

  @override
  String get keybindingOpenTheSelectedArticleDescription =>
      'Öppna den valda artikeln';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'Öppna den valda pull requesten';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'Öppna den valda arbetsytan';

  @override
  String get keybindingOpenWorkspace => 'Öppna arbetsyta';

  @override
  String get keybindingPreviousArticle => 'Föregående artikel';

  @override
  String get keybindingPreviousSpace => 'Föregående yta';

  @override
  String get keybindingPreviousWorkspace => 'Föregående arbetsyta';

  @override
  String get keybindingRefresh => 'Uppdatera';

  @override
  String get keybindingRefreshAllFeedsDescription => 'Uppdatera alla flöden';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'Uppdatera listan över pull requests';

  @override
  String get keybindingRescanForAdaptersDescription =>
      'Sök igen efter adaptrar';

  @override
  String get keybindingSelectTheNextArticleDescription => 'Välj nästa artikel';

  @override
  String get keybindingSelectTheNextSpaceDescription => 'Välj nästa yta';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'Välj föregående artikel';

  @override
  String get keybindingSelectThePreviousSpaceDescription =>
      'Välj föregående yta';

  @override
  String get keybindingSendMessage => 'Skicka meddelande';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'Skicka det aktuella meddelandet';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Växla mellan ljust och mörkt läge';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Växla till den åttonde arbetsytan';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Växla till den femte arbetsytan';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'Växla till den första arbetsytan';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'Växla till den fjärde arbetsytan';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'Växla till nästa arbetsyta';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'Växla till den nionde arbetsytan';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'Växla till föregående arbetsyta';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'Växla till den andra arbetsytan';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'Växla till den sjunde arbetsytan';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'Växla till den sjätte arbetsytan';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'Växla till den tredje arbetsytan';

  @override
  String get keybindingToggleBookmark => 'Växla bokmärke';

  @override
  String get keybindingToggleTheme => 'Växla tema';

  @override
  String get keybindingToggleWorkspaceSwitcher => 'Växla arbetsyteväxlare';

  @override
  String get keybindingWorkspace1 => 'Arbetsyta 1';

  @override
  String get keybindingWorkspace2 => 'Arbetsyta 2';

  @override
  String get keybindingWorkspace3 => 'Arbetsyta 3';

  @override
  String get keybindingWorkspace4 => 'Arbetsyta 4';

  @override
  String get keybindingWorkspace5 => 'Arbetsyta 5';

  @override
  String get keybindingWorkspace6 => 'Arbetsyta 6';

  @override
  String get keybindingWorkspace7 => 'Arbetsyta 7';

  @override
  String get keybindingWorkspace8 => 'Arbetsyta 8';

  @override
  String get keybindingWorkspace9 => 'Arbetsyta 9';

  @override
  String get keybindings => 'Kortkommandon';

  @override
  String get keybindingsDescription =>
      'Alla tangentbordsgenvägar. Genvägarna är fasta och kan inte tilldelas om.';

  @override
  String get killRunning => 'Avsluta körning';

  @override
  String get languageSystem => 'System';

  @override
  String get leaveACommentEllipsis => 'Lämna en kommentar…';

  @override
  String get legendLabel => 'Förklaring';

  @override
  String get lessLabel => 'Mindre';

  @override
  String get letsPluginTools => 'Dags att koppla in dina verktyg.';

  @override
  String get level => 'Nivå';

  @override
  String get loadingAgents => 'Läser in agenter…';

  @override
  String get loadingModels => 'Läser in modeller…';

  @override
  String get loadingProviders => 'Läser in leverantörer…';

  @override
  String get logLevel => 'Loggnivå';

  @override
  String get logs => 'Loggar';

  @override
  String get low => 'Låg';

  @override
  String get maintenance => 'Underhåll';

  @override
  String get manageParticipants => 'Hantera deltagare';

  @override
  String get manageWorkspaces => 'Hantera arbetsytor';

  @override
  String get reorderWorkspace => 'Ändra ordning på arbetsyta';

  @override
  String get matchOsAppearance =>
      'Följ operativsystemets utseende eller välj ett fast läge.';

  @override
  String get mcpAuthToken => 'MCP-autentiseringstoken';

  @override
  String get mcpNotAvailableOnServer =>
      'MCP-serverstyrning saknas på den anslutna servern.';

  @override
  String get modelManagedOnServer =>
      'Den här modellen körs på servervärden och hanteras där.';

  @override
  String get mcpServer => 'MCP-server';

  @override
  String get medium => 'Medel';

  @override
  String get memoryDataHint =>
      'Fakta och policyer visas här när agenter arbetar.';

  @override
  String get memoryLabel => 'Minne';

  @override
  String get merge => 'Slå samman';

  @override
  String get merged => 'Sammanslagen';

  @override
  String get messagePlaceholder =>
      'Meddelande… (@ för omnämnande, / för kommandon)';

  @override
  String get navConversations => 'Ytor';

  @override
  String get microphonePermissionDenied => 'Mikrofonbehörighet nekades.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuter sedan',
      one: '1 minut sedan',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'Modell';

  @override
  String get modified => 'Ändrad';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count månader sedan',
      one: '1 månad sedan',
    );
    return '$_temp0';
  }

  @override
  String get moreLabel => 'Mer';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'Namn';

  @override
  String get nameAndTitleRequired => 'Namn och titel krävs.';

  @override
  String get nameAndUrlRequired => 'Namn och URL krävs';

  @override
  String get nameLabel => 'Namn';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'Inbyggd sandlåda är tillgänglig på $platform.';
  }

  @override
  String get nativeSandboxNeedsInstall =>
      'Installation av inbyggd sandlåda krävs';

  @override
  String get navObservability => 'Observability';

  @override
  String get navSettings => 'Inställningar';

  @override
  String networkBlockCount(int count) {
    return '$count nätverksblockeringar';
  }

  @override
  String get neutral => 'Neutral';

  @override
  String get newCommitsPushed =>
      'Nya commits pushades – klicka för att läsa in diffen igen';

  @override
  String get newFact => 'Ny fakta';

  @override
  String get newPolicy => 'Ny policy';

  @override
  String get newsfeed => 'Nyhetsflöde';

  @override
  String get newsfeedLabel => 'Nyhetsflöde';

  @override
  String get newsfeedSettingsDescription =>
      'Hantera dina prenumererade flöden och läsarpreferenser.';

  @override
  String get newsfeedSettingsTitle => 'Inställningar för nyhetsflöde';

  @override
  String get nextMatch => 'Nästa träff (↵)';

  @override
  String get noActiveWorkspace => 'Ingen aktiv arbetsyta eller arkiv valt.';

  @override
  String get noActiveWorkspaceCreate => 'Ingen aktiv arbetsyta';

  @override
  String get noActiveWorkspaceGithub =>
      'Ingen aktiv arbetsyta med ett GitHub-arkiv.';

  @override
  String get noAgents => 'Inga agenter';

  @override
  String get noArticlesYet => 'Inga artiklar ännu';

  @override
  String get noArticlesYetBody => 'Artiklar från dina flöden visas här.';

  @override
  String get noExecutionLogsYet => 'Inga körningsloggar ännu';

  @override
  String get noFacts => 'Inga fakta ännu';

  @override
  String get noFeedsYet => 'Inga flöden ännu';

  @override
  String get noFileAnchor =>
      'Ingen filankare – kan inte lägga en kommentar på rad.';

  @override
  String get noFileChangesInScope => 'Inga filändringar i det här omfånget';

  @override
  String get noGifsFound => 'Inga GIF:ar hittades';

  @override
  String get noInputDevicesDetected =>
      'Inga inmatningsenheter hittades – använder systemets standard.';

  @override
  String get noMatchingFiles => 'Inga matchande filer';

  @override
  String get noMatchingGoogleFonts => 'Inga matchande Google Fonts.';

  @override
  String get noMemoryData => 'Ingen minnesdata ännu';

  @override
  String get noMessagesYet => 'Inga meddelanden ännu';

  @override
  String get noModelsAdvertised =>
      'Inga modeller annonseras av den här adaptern.';

  @override
  String get noOpenPullRequests => 'Inga öppna pull requests';

  @override
  String get noPolicies => 'Inga policyer ännu';

  @override
  String get noReposInWorkspaceYet => 'Inga arkiv i den här arbetsytan ännu';

  @override
  String get noRunnersDetected =>
      'Inga körare hittades ännu. Uppdatera för att söka igen.';

  @override
  String get noSavedArticles => 'Inga sparade artiklar';

  @override
  String get noSavedArticlesBody => 'Artiklar du sparar visas här.';

  @override
  String noShortcutsMatch(String query) {
    return 'Inga genvägar matchar \"$query\"';
  }

  @override
  String get noSystemFonts => 'Inga systemteckensnitt hittades.';

  @override
  String get noTokenSet => 'Ingen token angiven – åtkomsten är obegränsad.';

  @override
  String get noWorkingMemory => 'Inga arbetsminnesanteckningar ännu.';

  @override
  String get noneAllRoles => 'Ingen (alla roller)';

  @override
  String get notAvailable => 'Inte tillgänglig';

  @override
  String get notConfiguredLabel => 'Inte konfigurerad.';

  @override
  String get notFoundLabel => 'Hittades inte';

  @override
  String get notes => 'Anteckningar';

  @override
  String get notificationAgentFinished => 'Agenten är klar';

  @override
  String get notificationPrMentioned => 'Omnämnd i pull request';

  @override
  String get notificationNewMessages => 'Nya meddelanden';

  @override
  String get notificationPrMerged => 'PR sammanslagen';

  @override
  String get notificationPrPublished => 'PR publicerad';

  @override
  String get notificationReviewRequested => 'Granskning begärd';

  @override
  String get notifications => 'Aviseringar';

  @override
  String get notifyAgentRunCompleted =>
      'Avisera när en agent slutför en körning.';

  @override
  String get notifyPrMentioned => 'Avisera när du nämns i en pull request.';

  @override
  String get notifyNewMessages =>
      'Avisera vid nya agentmeddelanden i andra ytor.';

  @override
  String get notifyPrMerged => 'Avisera när en pull request slås samman.';

  @override
  String get notifyPrPublished =>
      'Avisera när en agent publicerar en pull request.';

  @override
  String get notifyReviewRequested =>
      'Avisera när din granskning begärs på en pull request.';

  @override
  String get notificationReviewStale => 'Granskning inaktuell';

  @override
  String get notifyReviewStale =>
      'När nya commits landar på en pull request du redan granskat';

  @override
  String get notificationPrMergeReadiness => 'Redo att slå samman';

  @override
  String get notifyPrMergeReadiness =>
      'Avisera när en pull request du skapat blir sammanslagningsbar, eller slutar vara det.';

  @override
  String get notificationPrReviewDecision => 'Granskningsbeslut';

  @override
  String get notifyPrReviewDecision =>
      'Avisera när en granskare godkänner, begär ändringar eller får ett godkännande avvisat.';

  @override
  String get notificationPrChecksStatus => 'Kontroller';

  @override
  String get notifyPrChecksStatus =>
      'Avisera när CI misslyckas på en pull request du skapat, och när den återhämtar sig.';

  @override
  String get notificationPrThreadActivity => 'Granskningstrådar';

  @override
  String get notifyPrThreadActivity =>
      'Avisera när någon svarar i eller löser en tråd du är med i.';

  @override
  String get notificationPrReadyToMerge => 'Redo att slå samman';

  @override
  String notificationPrReadyToMergeBody(String prTitle) {
    return '$prTitle har allt den behöver.';
  }

  @override
  String get notificationPrMergeBlocked => 'Inte längre sammanslagningsbar';

  @override
  String notificationPrMergeBlockedBodyConflicts(String prTitle) {
    return '$prTitle har konflikter mot basgrenen.';
  }

  @override
  String notificationPrMergeBlockedBodyBehind(String prTitle) {
    return '$prTitle ligger efter basgrenen.';
  }

  @override
  String notificationPrMergeBlockedBodyReviews(String prTitle) {
    return '$prTitle väntar på en obligatorisk granskning.';
  }

  @override
  String notificationPrMergeBlockedBodyChanges(String prTitle) {
    return 'En granskare begärde ändringar på $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyChecks(String prTitle) {
    return 'Kontroller misslyckas på $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyOther(String prTitle) {
    return '$prTitle kan inte längre slås samman.';
  }

  @override
  String get notificationPrApproved => 'Pull request godkänd';

  @override
  String notificationPrApprovedBodyBy(String login, String prTitle) {
    return '$login godkände $prTitle';
  }

  @override
  String notificationPrApprovedBody(String prTitle) {
    return '$prTitle godkändes';
  }

  @override
  String notificationPrReviewersRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count granskare ska fortfarande svara',
      one: '1 granskare ska fortfarande svara',
      zero: 'inga granskare kvar',
    );
    return '$_temp0';
  }

  @override
  String get notificationPrChangesRequested => 'Ändringar begärda';

  @override
  String notificationPrChangesRequestedBodyBy(String login, String prTitle) {
    return '$login begärde ändringar på $prTitle';
  }

  @override
  String notificationPrChangesRequestedBody(String prTitle) {
    return 'Ändringar begärdes på $prTitle';
  }

  @override
  String get notificationPrReviewDismissed => 'Godkännande avvisat';

  @override
  String notificationPrReviewDismissedBody(String prTitle) {
    return '$prTitle behöver granskas igen.';
  }

  @override
  String get notificationPrChecksFailed => 'Kontroller misslyckades';

  @override
  String notificationPrChecksFailedBody(String checkName, String prTitle) {
    return '$checkName misslyckades på $prTitle';
  }

  @override
  String notificationPrChecksFailedBodyUnnamed(String prTitle) {
    return 'Kontroller misslyckas på $prTitle';
  }

  @override
  String get notificationPrChecksRecovered => 'Kontroller går igenom';

  @override
  String notificationPrChecksRecoveredBody(String prTitle) {
    return '$prTitle är grön igen.';
  }

  @override
  String notificationPrMentionedInCommentBody(String login, String location) {
    return '$login nämnde dig i $location';
  }

  @override
  String get notificationPrThreadReplied => 'Nytt svar';

  @override
  String notificationPrThreadRepliedBody(String login, String location) {
    return '$login svarade i $location';
  }

  @override
  String get notificationPrThreadResolved => 'Tråd löst';

  @override
  String notificationPrThreadResolvedBody(String location) {
    return 'Din tråd i $location löstes.';
  }

  @override
  String get notificationGroupAgents => 'Agenter';

  @override
  String get notificationGroupPullRequests => 'Pull requests';

  @override
  String get notificationGroupMessages => 'Meddelanden';

  @override
  String get notificationGroupTickets => 'Ärenden';

  @override
  String get notificationGroupCalendar => 'Kalender';

  @override
  String get notificationGroupMachines => 'Maskiner';

  @override
  String get notificationsMutedRepos => 'Tystade arkiv';

  @override
  String notificationsMutedReposCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arkiv tystade',
      one: '1 arkiv tystat',
      zero: 'Inga arkiv tystade',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMuteRepo => 'Tysta det här arkivet';

  @override
  String get onboardingLinuxDescription =>
      'Control Center kan använda Linux-containrar för att isolera agentkörning.';

  @override
  String get onboardingMacosDescription =>
      'Control Center använder inbyggd sandlåda på macOS för att isolera agentkörning.';

  @override
  String get onboardingUnsupportedDescription =>
      'Sandlåda saknas på den här plattformen. Agentkörning sker utan isolering.';

  @override
  String get openArticlesInApp => 'Öppna artiklar i appen';

  @override
  String get openInBrowser => 'Öppna i webbläsaren';

  @override
  String get openedInYourBrowser => 'Öppnad i din webbläsare.';

  @override
  String get openLabel => 'Öppen';

  @override
  String get openOnGithub => 'Öppna på GitHub';

  @override
  String get openStatus => 'Öppen';

  @override
  String get optionalPersonaDescription => 'Valfri personabeskrivning';

  @override
  String get otherLabel => 'Övrigt';

  @override
  String get ownerOrganization => 'Ägare / organisation';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get passed => 'Godkänd';

  @override
  String get pasteValueHere => 'Klistra in värde här';

  @override
  String get persona => 'Persona';

  @override
  String get policies => 'Policyer';

  @override
  String get policiesHint => 'Policyer visas här när agenter främjar fakta.';

  @override
  String get policy => 'Policy';

  @override
  String get popular => 'Populära';

  @override
  String get port => 'Port';

  @override
  String get postingEllipsis => 'Publicerar…';

  @override
  String get prCommits => 'Commits';

  @override
  String get prMergedBody => 'En pull request slogs samman';

  @override
  String get prMoreActions => 'Fler åtgärder';

  @override
  String get prTitle => 'PR-titel';

  @override
  String get reviewCommentHint =>
      'Klicka bara på godkänn, eller lägg till en kommentar eller reaktion om du vill…';

  @override
  String get nothingToPreview => 'Inget att förhandsgranska';

  @override
  String get previousMatch => 'Föregående träff (⇧↵)';

  @override
  String get priorityReviewsDescription =>
      'Prioriterade granskningar och arkivöversikt.';

  @override
  String get prsCreated => 'PR:ar skapade';

  @override
  String get prsMerged => 'PR:ar sammanslagna';

  @override
  String get publishToGithub => 'Publicera till GitHub';

  @override
  String get published => 'Publicerad';

  @override
  String get pullRequestApproved => 'Pull request godkänd';

  @override
  String get pullRequests => 'Pull requests';

  @override
  String get questionLabel => 'FRÅGA';

  @override
  String get queued => 'I kö';

  @override
  String get react => 'Reagera';

  @override
  String get readPrsIssuesMetadata =>
      'Låter agenten läsa PR:ar, issues och arkivmetadata.';

  @override
  String get readerPreferences => 'Läsarpreferenser';

  @override
  String get reasoningEffort => 'Resonemangsinsats';

  @override
  String get recommendLabel => 'REKOMMENDERA';

  @override
  String recordingFromDevice(String device) {
    return 'Spelar in från $device.';
  }

  @override
  String get redownload => 'Hämta igen';

  @override
  String get redownloadEmbeddingModel => 'Hämta inbäddningsmodellen igen?';

  @override
  String get redownloadVoiceModel => 'Hämta röstmodellen igen?';

  @override
  String get refinePlan => 'Förfina plan';

  @override
  String get refresh => 'Uppdatera';

  @override
  String get refreshAll => 'Uppdatera alla';

  @override
  String get refreshAllFeeds => 'Uppdatera alla flöden';

  @override
  String get reject => 'Avvisa';

  @override
  String get rejected => 'Avvisad';

  @override
  String get reload => 'Läs in igen';

  @override
  String get remove => 'Ta bort';

  @override
  String get removeBookmark => 'Ta bort bokmärke';

  @override
  String get removeEmbeddingModel => 'Ta bort inbäddningsmodellen?';

  @override
  String get removeLogo => 'Ta bort logotyp';

  @override
  String get removeRepoFromWorkspace => 'Ta bort arkiv från arbetsytan?';

  @override
  String get removeVoiceModel => 'Ta bort röstmodellen?';

  @override
  String get removed => 'Borttagen';

  @override
  String get renamed => 'Namnändrad';

  @override
  String get reopen => 'Öppna igen';

  @override
  String get resolve => 'Lös';

  @override
  String get replyEllipsis => 'Svara…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$name tas bort från den här arbetsytan. De lokala filerna på disk rörs inte.';
  }

  @override
  String repoAccessNoticeBody(String repos) {
    return 'Serverns GitHub-inloggningsuppgifter kan inte se $repos. Om ett arkiv tillhör en organisation, installera GitHub-appen där eller anslut en token som har åtkomst.';
  }

  @override
  String repoAccessNoticeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arkiv kan inte nås',
      one: 'Ett arkiv kan inte nås',
    );
    return '$_temp0';
  }

  @override
  String get repoAccessNoticeSuspendedTitle =>
      'GitHub App-installationen är avstängd';

  @override
  String repoAccessNoticeSuspendedBody(String repos) {
    return 'Visar senast kända data för $repos. Återuppta installationen på GitHub, eller anslut en token som har åtkomst.';
  }

  @override
  String get repoNoAccessBadge => 'Ingen åtkomst';

  @override
  String get reportsTo => 'Rapporterar till';

  @override
  String reposCount(int count) {
    return 'Arkiv ($count)';
  }

  @override
  String get reposDescription =>
      'De lokala checkouts den här arbetsytan riktar sig mot.';

  @override
  String get repositories => 'Arkiv';

  @override
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arkiv',
      one: '1 arkiv',
    );
    return 'Kunde inte lägga till $_temp0: $error';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arkiv tillagda',
      one: 'Arkiv tillagt',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => 'Arkivinställningar';

  @override
  String get repositoryName => 'Arkivnamn';

  @override
  String get requestChanges => 'Begär ändringar';

  @override
  String get requested => 'Begärd';

  @override
  String get requestedChanges => 'Ändringar begärda';

  @override
  String requiredRoleLabel(String role) {
    return 'Obligatorisk roll: $role';
  }

  @override
  String get requiredRoleOptional => 'Obligatorisk roll (valfritt)';

  @override
  String get requirements => 'Krav';

  @override
  String get reset => 'Återställ';

  @override
  String get resolved => 'Löst';

  @override
  String get enclosedTerminalTitle => 'Avskild terminal';

  @override
  String get enclosedTerminalStart => 'Öppna skalet';

  @override
  String get enclosedTerminalStartHint =>
      'Det här skalet körs i samtalets tillfälliga VM. Den startar när du öppnar den, inte när appen startar.';

  @override
  String get terminalStreamReconnecting => 'ström avbruten – återansluter…';

  @override
  String get terminalStreamError => 'strömfel:';

  @override
  String get terminalShellExited => 'skalet avslutades';

  @override
  String get restartShell => 'Starta om skal';

  @override
  String get retry => 'Försök igen';

  @override
  String get review => 'Granskning';

  @override
  String get reviewedByMe => 'Granskade av mig';

  @override
  String get reviewers => 'Granskare';

  @override
  String get roleLabel => 'Roll';

  @override
  String get ruleHint => 'Policyregeln (markdown stöds)';

  @override
  String get ruleLabel => 'Regel';

  @override
  String get runCompleted => 'Körning slutförd';

  @override
  String get running => 'Körs';

  @override
  String get runningLabel => 'körs';

  @override
  String get runs => 'Körningar';

  @override
  String get runsLabel => 'Körningar';

  @override
  String get sandboxBackendNativeLabel => 'Inbyggd sandlåda';

  @override
  String get sandboxBackendMicrovmLabel => 'Avskild VM';

  @override
  String get sandboxBackendNoneLabel => 'Ingen isolering';

  @override
  String get sandboxLinuxInstall =>
      'Inbyggd sandlåda på Linux/WSL2 använder bubblewrap. Installera med:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'Inbyggd sandlåda finns på macOS – använder Apple Seatbelt (`sandbox-exec`). Ingen installation krävs.';

  @override
  String get sandboxPermissions => 'Sandlådebehörigheter';

  @override
  String get sandboxUnsupported =>
      'Inbyggd sandlåda stöds inte på den här plattformen ännu. Faller tillbaka till \"Ingen isolering\".';

  @override
  String get sandboxingDisabledDescription =>
      'Agenter körs direkt på värden med full miljö – rekommenderas inte.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'Alla agentanrop går via $backend.';
  }

  @override
  String get save => 'Spara';

  @override
  String get saveChanges => 'Spara ändringar';

  @override
  String get adapterArguments => 'Extra argument';

  @override
  String get adapterArgumentsHint => 'Ytterligare CLI-flaggor (t.ex. --yolo)';

  @override
  String get addVariable => 'Lägg till variabel';

  @override
  String get environmentVariables => 'Miljövariabler';

  @override
  String get environmentVariablesDescription =>
      'Egna miljövariabler som skickas till den här adaptern (t.ex. API-nycklar). Lagras i nyckelringen.';

  @override
  String get variableKey => 'Nyckel';

  @override
  String get variableValue => 'Värde';

  @override
  String get savingEllipsis => 'Sparar…';

  @override
  String get scopeDiffToCommits =>
      'Begränsa diff till commits – Shift-klick för intervall';

  @override
  String get noPrsMatchSearch => 'Inga matchande pull requests';

  @override
  String get searchFactsHint => 'Sök fakta...';

  @override
  String get searchFonts => 'Sök teckensnitt…';

  @override
  String get searchGifs => 'Sök GIF:ar';

  @override
  String get searchGifsHint => 'Sök GIF:ar...';

  @override
  String get searchInDiffHint => 'Sök i diff…';

  @override
  String get searchOrTypeModel => 'Sök eller skriv ett modellnamn…';

  @override
  String get searchPlaceholder => 'Sök…';

  @override
  String get searchShortcuts => 'Sök genvägar…';

  @override
  String get shortcutUnavailableInBrowser => 'Otillgängligt i webbläsaren';

  @override
  String get searching => 'Söker…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sekunder sedan',
      one: '1 sekund sedan',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'Välj adapter';

  @override
  String get selectAdapterFirst => 'Välj en adapter först';

  @override
  String get selectAgentToReportTo => 'Välj agent att rapportera till…';

  @override
  String get selectAnAgent => 'Välj en agent';

  @override
  String get selectConversation => 'Välj ett samtal';

  @override
  String get selectLabel => 'Välj';

  @override
  String get selectRunner => 'Välj en körare';

  @override
  String get semanticSearch => 'Semantisk sökning';

  @override
  String get send => 'Skicka';

  @override
  String get sendFirstMessage => 'Skicka det första meddelandet';

  @override
  String get sendMessage => 'Skicka meddelande';

  @override
  String sentFindingsToAgent(int count) {
    return 'Skickade $count fynd till agenten.';
  }

  @override
  String setGithubLinkDescription(String name) {
    return 'Ange GitHub-ägare och arkivnamn för $name. Används för att lösa PR- och issue-referenser som #123 i markdown.';
  }

  @override
  String get setLabel => 'Ange';

  @override
  String get setToken => 'Ange token';

  @override
  String get settingsLabel => 'Inställningar';

  @override
  String get settingsLanguage => 'Språk';

  @override
  String get settingsLanguageDescription => 'Välj appspråk.';

  @override
  String get shortTask => 'Kort uppgift';

  @override
  String get showNativeNotifications =>
      'Visa inbyggda macOS-aviseringar för händelser.';

  @override
  String get showSuperseded => 'Visa ersatta';

  @override
  String get signedIn => 'Inloggad.';

  @override
  String signedInAs(String username) {
    return 'Inloggad som $username.';
  }

  @override
  String get skillNameRequired => 'Färdighetsnamn krävs.';

  @override
  String skillSaved(String name) {
    return 'Färdigheten \"$name\" sparades.';
  }

  @override
  String get skillsSourcesTab => 'Källor';

  @override
  String get skillSourcesDisclaimer =>
      'Färdigheter installeras från GitHub-arkiv du lägger till. Arkivmetadata är otillförlitlig – virussökningen är den verkliga säkerhetssignalen.';

  @override
  String get skillSourcesEmpty => 'Inga färdighetsarkiv';

  @override
  String get skillSourcesEmptyHint =>
      'Lägg till ett GitHub-arkiv för att bläddra bland dess färdigheter.';

  @override
  String get skillSourceAdd => 'Lägg till arkiv';

  @override
  String get skillSourceAddTitle => 'Lägg till färdighetsarkiv';

  @override
  String get skillSourceAddHint => 'https://github.com/owner/repo';

  @override
  String get skillSourceInvalidUrl =>
      'Ange en GitHub-arkiv-URL (https://github.com/owner/repo).';

  @override
  String skillSourceAdded(String repo) {
    return 'Arkivet $repo lades till.';
  }

  @override
  String skillSourceAlreadyAdded(String repo) {
    return 'Arkivet $repo är redan tillagt.';
  }

  @override
  String skillSourceRemoved(String repo) {
    return 'Arkivet $repo togs bort.';
  }

  @override
  String get skillSourceRemove => 'Ta bort';

  @override
  String skillSourceRemoveConfirmTitle(String repo) {
    return 'Ta bort $repo?';
  }

  @override
  String get skillSourceRemoveConfirmBody =>
      'Installerade färdigheter förblir installerade. Bara arkivkatalogen tas bort.';

  @override
  String get skillSourceNoSkills =>
      'Inga färdigheter hittades i det här arkivet (en färdighet är en katalog som innehåller en SKILL.md).';

  @override
  String get skillSourceRefresh => 'Uppdatera';

  @override
  String get skillSourceInstalledBadge => 'Installerad';

  @override
  String get skillSourceUpdateBadge => 'Uppdatering tillgänglig';

  @override
  String get skillSourceSlugTaken => 'Namnet används';

  @override
  String skillSourceFilesCount(num count) {
    return '$count filer';
  }

  @override
  String get skillSourceReadme => 'README';

  @override
  String get skillSourceNoReadme => 'Den här färdigheten har ingen README.';

  @override
  String get skillSourceNoMatches => 'Inga färdigheter matchar ditt filter.';

  @override
  String get skillUpdateAction => 'Uppdatera';

  @override
  String get skillUninstallAction => 'Avinstallera';

  @override
  String skillUninstallConfirmTitle(String slug) {
    return 'Avinstallera \"$slug\"?';
  }

  @override
  String skillUninstalled(String slug) {
    return 'Färdigheten \"$slug\" avinstallerades.';
  }

  @override
  String get skillFindingLine => 'rad';

  @override
  String get skillInstallAnywayOverride =>
      'Jag förstår risken – installera ändå';

  @override
  String skillInstalled(String slug) {
    return 'Färdigheten \"$slug\" installerades.';
  }

  @override
  String get skillPreviewCapabilities => 'Förmågor';

  @override
  String get skillPreviewFindings => 'Fynd';

  @override
  String get skillPreviewGuardedActions => 'Skyddade åtgärder';

  @override
  String get skillPreviewLlmReviewed => 'LLM-granskad';

  @override
  String get skillPreviewNoCapabilities => 'Inga förmågor deklarerade.';

  @override
  String get skillPreviewNoFindings => 'Inga fynd.';

  @override
  String get skillPreviewScanning => 'Skannar färdighet…';

  @override
  String get skillPreviewVerdictLabel => 'Skanningsutslag';

  @override
  String get skillPreviewVerdictPass => 'Godkänd';

  @override
  String get skillPreviewVerdictQuarantine => 'I karantän';

  @override
  String get skillPreviewVerdictWarn => 'Varning';

  @override
  String get skillQuarantineWarning =>
      'Den här färdigheten sattes i karantän av skannern. Att installera den kör kod på din maskin. Fortsätt bara om du litar på källan och har granskat fynden.';

  @override
  String skillDetachedFromAgents(String agents) {
    return 'I karantän och frånkopplad från agenter: $agents';
  }

  @override
  String get skillNotScanned => 'Inte skannad';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => 'Manuell';

  @override
  String get skillOriginRegistry => 'Register';

  @override
  String get skillOriginRuntimeLocal => 'Lokal runtime';

  @override
  String get skillRulesStale => 'Skanning inaktuell';

  @override
  String get skillSaveAnywayOverride => 'Jag förstår risken – spara ändå';

  @override
  String get skillSaveBlockedBody =>
      'Innehållet blockerades innan något skrevs.';

  @override
  String get skillSaveBlockedTitle =>
      'Sparandet blockerades av skanningsgrinden';

  @override
  String get skillScanAction => 'Skanna';

  @override
  String get skillScanAll => 'Skanna alla';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass godkända · $warn varningar · $quarantine i karantän';
  }

  @override
  String get skillStateDrifted => 'Ändrad sedan installation';

  @override
  String get skillStateUnmanaged => 'Ohanterad';

  @override
  String get skillSeverityBlocked => 'Blockerad';

  @override
  String get skillSeverityWarn => 'Varning';

  @override
  String get skillsInstalledTab => 'Installerade';

  @override
  String get skills => 'Färdigheter';

  @override
  String get skipAcceptRisk => 'Hoppa över – jag accepterar risken';

  @override
  String get skipForNow => 'Hoppa över just nu';

  @override
  String get skipSandboxing => 'Hoppa över sandlåda';

  @override
  String get skipSandboxingDialogContent =>
      'Vill du verkligen hoppa över sandlådan? Då får agenter köra kod på ditt system utan isolering.';

  @override
  String get somethingWentWrong => 'Något gick fel';

  @override
  String sourceCount(int count) {
    return '$count källa';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count källor';
  }

  @override
  String get sourceFacts => 'Källfakta:';

  @override
  String get splitDiff => 'Delad (sida vid sida) diff';

  @override
  String get startLabel => 'Starta';

  @override
  String get startOnAppLaunch => 'Starta vid applansering';

  @override
  String get statusLabel => 'Status';

  @override
  String get onboardingStepConnect => 'Anslut';

  @override
  String get onboardingStepWorkspace => 'Arbetsyta';

  @override
  String get onboardingStepSandbox => 'Sandlåda';

  @override
  String get onboardingStepAdapter => 'Adapter';

  @override
  String get onboardingStepVoice => 'Röst';

  @override
  String get stop => 'Stoppa';

  @override
  String get stopped => 'Stoppad';

  @override
  String get strictIdentityCheck => 'Strikt identitetskontroll';

  @override
  String get success => 'Lyckades';

  @override
  String get successLabel => 'Lyckades';

  @override
  String get suggestAChange => 'Föreslå en ändring';

  @override
  String get suggestLabel => 'FÖRESLÅ';

  @override
  String get superseded => 'Ersatt';

  @override
  String get synced => 'Synkad';

  @override
  String get systemDefault => 'Systemstandard';

  @override
  String get systemFonts => 'Systemteckensnitt';

  @override
  String get systemPrompt => 'Systemprompt';

  @override
  String get systemPromptLabel => 'Systemprompt';

  @override
  String get talkToControlCenter => 'Prata med Control Center.';

  @override
  String get taskMentionSection => 'Uppgift';

  @override
  String get testLabel => 'Test';

  @override
  String get theme => 'Tema';

  @override
  String get themeDark => 'Mörkt';

  @override
  String get themeLight => 'Ljust';

  @override
  String get themeSystem => 'System';

  @override
  String get thisCannotBeUndone => 'Det går inte att ångra.';

  @override
  String get ticketLabel => 'ÄRENDE';

  @override
  String get titleLabel => 'Titel';

  @override
  String get todayLabel => 'Idag';

  @override
  String get toggleTheme => 'Växla tema';

  @override
  String get tokenConfigured =>
      'Konfigurerad – klienter måste visa den här token.';

  @override
  String get topic => 'Ämne';

  @override
  String get topicHint => 't.ex. Tech Stack, Design System';

  @override
  String get totalRuns => 'Totalt antal körningar';

  @override
  String trackingParamsCount(int count) {
    return '$count spårningsparametrar';
  }

  @override
  String get typeCommandOrSearch => 'Skriv ett kommando eller sök…';

  @override
  String get typography => 'Typografi';

  @override
  String get unavailable => 'Otillgänglig';

  @override
  String get unifiedDiff => 'Enhetlig diff';

  @override
  String get unknownAuthor => 'Okänd';

  @override
  String get unnamedAgent => 'Namnlös agent';

  @override
  String get updateKey => 'Uppdatera nyckel';

  @override
  String get updateLabel => 'Uppdatera';

  @override
  String get updateToken => 'Uppdatera token';

  @override
  String updatedDaysAgo(int count) {
    return 'Uppdaterad för $count d sedan';
  }

  @override
  String updatedHoursAgo(int count) {
    return 'Uppdaterad för $count h sedan';
  }

  @override
  String get updatedJustNow => 'Uppdaterad just nu';

  @override
  String updatedMinutesAgo(int count) {
    return 'Uppdaterad för $count min sedan';
  }

  @override
  String get useSandbox => 'Använd sandlåda';

  @override
  String get useWorkspaceDefault => 'Använd arbetsytans standard';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      'Lämna tomt för att använda appens standard-User-Agent. Vissa sajter blockerar User-Agents som inte är webbläsare.';

  @override
  String get usingSystemDefaultMicrophone =>
      'Använder systemets standardmikrofon.';

  @override
  String get viewLabel => 'Visa';

  @override
  String get viewLogs => 'Visa loggar';

  @override
  String voiceInstallFailed(String error) {
    return 'Installationen misslyckades: $error';
  }

  @override
  String get voiceModelNotInstalled =>
      'Inte installerad. Hämtar ~200 MB en gång; körs helt på enheten.';

  @override
  String get voiceModelNotInstalledLabel => 'Röstmodell inte installerad.';

  @override
  String get voiceRedownloadBody =>
      'Befintliga modellfiler tas bort och arkivet på ~200 MB hämtas igen. Rösttranskription är otillgänglig tills hämtningen är klar.';

  @override
  String get voiceRemoveBody =>
      'Rösttranskription inaktiveras tills du installerar om den. Du kan installera den igen när som helst.';

  @override
  String get voiceTranscription => 'Rösttranskription';

  @override
  String get weakIsolationDescription =>
      'Svag isolering – bara namnrymdsgräns, ingen kärngräns.';

  @override
  String get whenOffNoDefaultRoute =>
      'När det är av startar sandlådan utan en standardrutt.';

  @override
  String get whenOffServerStaysStopped =>
      'När det är av förblir servern stoppad tills du startar den.';

  @override
  String get speechModel => 'Talmodell';

  @override
  String get speechModelHint =>
      'Används för mötestranskription och mikrofonen i meddelandefältet.';

  @override
  String get voiceModelInstalled =>
      'Installerad. Driver mötestranskription och mikrofonknappen i meddelandefältet.';

  @override
  String get meetingMicSilentWarning =>
      'Din mikrofon kan vara avstängd – de andra pratar men ingenting når din mikrofon.';

  @override
  String get meetingSummaryPrivacyNotice =>
      'Inspelning och transkription stannar på den här maskinen. Sammanfattningen skrivs av en agent, så om den använder en molnmodell skickas din utskrift och dina anteckningar till den leverantören.';

  @override
  String get meetingTemplates => 'Mallar för mötesanteckningar';

  @override
  String get meetingTemplatesHint =>
      'Forma AI-sammanfattningen för en typ av möte. Den aktiva mallen gäller nya och omkörda sammanfattningar.';

  @override
  String get meetingTemplateActive => 'Aktiv mall';

  @override
  String get meetingTemplateAdd => 'Lägg till mall';

  @override
  String get meetingTemplateNewTitle => 'Ny mall';

  @override
  String get meetingTemplateEditTitle => 'Redigera mall';

  @override
  String get meetingTemplateNameLabel => 'Namn';

  @override
  String get meetingTemplateNameHint => 't.ex. Sprintgranskning';

  @override
  String get meetingTemplateInstructionsLabel => 'Instruktioner';

  @override
  String get meetingTemplateInstructionsHint =>
      'Hur ska AI:n strukturera och betona de här anteckningarna?';

  @override
  String get workingMemory => 'Arbetsminne';

  @override
  String get workspaceName => 'Arbetsytans namn';

  @override
  String get workspaceScopedSkills =>
      'Arbetsytebundna färdighetsfiler kopplade till agenter.';

  @override
  String get workspaces => 'Arbetsytor';

  @override
  String get writePrivateNotes =>
      'Skriv privata anteckningar, observationer, planer...';

  @override
  String get writeSkillContent => 'Skriv färdighetsinnehållet här (Markdown)…';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count år sedan',
      one: '1 år sedan',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'Igår';

  @override
  String get focusModeStart => 'Starta fokussession';

  @override
  String get focusModeConfigTitle => 'Starta fokussession';

  @override
  String get focusModeGoalLabel => 'Mål';

  @override
  String get focusModeGoalHint => 'Vad arbetar du med?';

  @override
  String get focusModeDurationLabel => 'Varaktighet';

  @override
  String get focusModeBlockNotifications => 'Blockera aviseringar';

  @override
  String get focusModeStartButton => 'Starta';

  @override
  String get focusModeFloat => 'Minimera till fältet';

  @override
  String get focusModeActiveTooltip =>
      'Fokusläge aktivt – tryck för att avsluta';

  @override
  String get dismiss => 'Stäng';

  @override
  String get acceptAndResolve => 'Acceptera och lös';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'Du har granskat i $minutes min – forskning tyder på att granskningskvaliteten kan sjunka efter 60 min. Överväg en paus.';
  }

  @override
  String get notificationSound => 'Aviseringsljud';

  @override
  String get notificationSoundDescription =>
      'Ljud som spelas när en avisering visas.';

  @override
  String get notificationSoundNone => 'Inget';

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
  String get notificationSoundMigrosSoft => 'Migros (mjuk)';

  @override
  String get notificationSoundMigrosHard => 'Migros (hård)';

  @override
  String get notificationSoundSbb => 'SBB';

  @override
  String get notificationSoundCff => 'CFF';

  @override
  String get notificationSoundFfs => 'FFS';

  @override
  String get notificationSoundPost => 'Post';

  @override
  String get notificationSoundTest => 'Testa';

  @override
  String get notificationVolume => 'Volym';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'Inga PR:ar av @$login i den här arbetsytan';
  }

  @override
  String get usersLabel => 'Användare';

  @override
  String get mergePullRequest => 'Slå samman pull request';

  @override
  String get forceMergePullRequest => 'Tvinga sammanslagning av pull request';

  @override
  String get closePullRequest => 'Stäng pull request';

  @override
  String get closePullRequestConfirm =>
      'Vill du verkligen stänga den här pull requesten?';

  @override
  String get stackedPullRequests => 'Staplade pull requests';

  @override
  String partOfStack(int position, int total) {
    return 'Del av en stack ($position av $total)';
  }

  @override
  String get createStack => 'Skapa stack';

  @override
  String get createStackDialogTitle => 'Skapa pull request-stack';

  @override
  String createStackDialogBody(int count) {
    return 'De här $count pull requests staplas, underifrån och upp:';
  }

  @override
  String get createStackInvalidSelection =>
      'Välj minst två pull requests från samma arkiv för att skapa en stack';

  @override
  String get createStackNotAChain =>
      'De valda pull requests bildar inte en kedja: varje pull requests basgren måste vara den föregåendes huvudgren';

  @override
  String get createStackAlreadyStacked =>
      'En eller flera valda pull requests ingår redan i en stack';

  @override
  String get stackCreated => 'Stack skapad';

  @override
  String get stackCreationFailed => 'Kunde inte skapa stacken';

  @override
  String get squashAndMerge => 'Squasha och slå samman';

  @override
  String get createMergeCommit => 'Skapa en merge-commit';

  @override
  String get rebaseAndMerge => 'Rebasa och slå samman';

  @override
  String get commitTitle => 'Commit-titel';

  @override
  String get commitDescription => 'Commit-beskrivning';

  @override
  String get pullRequestMerged => 'Pull request sammanslagen';

  @override
  String get pullRequestClosed => 'Pull request stängd';

  @override
  String failedToMergePr(String error) {
    return 'Kunde inte slå samman: $error';
  }

  @override
  String failedToClosePr(String error) {
    return 'Kunde inte stänga: $error';
  }

  @override
  String get markReadyForReview => 'Redo för granskning';

  @override
  String get markReadyForReviewConfirm =>
      'Den här pull requesten lämnar utkast. Granskare aviseras, obligatoriska kontroller börjar styra sammanslagningen och all automatisering som väntar på redo pull requests körs.';

  @override
  String get convertToDraft => 'Konvertera till utkast';

  @override
  String get convertToDraftConfirm =>
      'Den här pull requesten går tillbaka till utkast. Väntande granskningsförfrågningar avvisas och den kan inte slås samman förrän du markerar den som redo igen.';

  @override
  String get pullRequestMarkedReady =>
      'Pull request markerad som redo för granskning';

  @override
  String get pullRequestConvertedToDraft =>
      'Pull request konverterad till utkast';

  @override
  String failedToMarkPrReady(String error) {
    return 'Kunde inte markera som redo för granskning: $error';
  }

  @override
  String failedToConvertPrToDraft(String error) {
    return 'Kunde inte konvertera till utkast: $error';
  }

  @override
  String get checksFailing => 'Kontroller misslyckas';

  @override
  String get reviewsPending => 'Vissa granskningar väntar';

  @override
  String get mergeConflictsWithBase =>
      'Den här grenen har konflikter som måste lösas';

  @override
  String get branchOutOfDateWithBase =>
      'Den här grenen är inaktuell mot basgrenen';

  @override
  String get mergeBlockedByBranchProtection =>
      'Grenskydd blockerar den här sammanslagningen';

  @override
  String get confirm => 'Bekräfta';

  @override
  String get trustedSitesSectionTitle => 'Betrodda sajter';

  @override
  String get trustedSitesEmpty =>
      'Inga betrodda sajter. Lägg till en domän för att stänga av blockering på den.';

  @override
  String get addTrustedSite => 'Lägg till betrodd sajt';

  @override
  String get removeTrustedSite => 'Ta bort';

  @override
  String get disableBlockingForThisSite =>
      'Stäng av blockering på den här sajten';

  @override
  String get enableBlockingForThisSite => 'Slå på blockering på den här sajten';

  @override
  String get enterDomainHint => 't.ex. example.com';

  @override
  String get invalidDomain => 'Ange en giltig domän (t.ex. example.com)';

  @override
  String get pageLoadTimedOut =>
      'Sidinläsningen tog för lång tid. Läs in igen eller öppna i webbläsaren.';

  @override
  String get pipelinesScreenTitle => 'Pipelines';

  @override
  String get pipelinesScreenSubtitle =>
      'Deklarativa flerstegsarbetsflöden för agenter';

  @override
  String get pipelinesRunPipeline => 'Kör pipeline';

  @override
  String get pipelineRunLauncherTitle => 'Kör pipeline';

  @override
  String get pipelineRunSubtitle =>
      'Välj en pipeline och fyll i dess indata för att starta en körning.';

  @override
  String get pipelineRunNoInputsBadge => 'Ingen indata';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count indata',
      one: '1 indata',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'Den här pipelinen tar ingen indata.';

  @override
  String get pipelineRunSubmit => 'Kör pipeline';

  @override
  String get pipelineRunCouldNotStart => 'Kunde inte starta körningen.';

  @override
  String pipelineRunStarted(String name) {
    return 'Startade $name';
  }

  @override
  String get pipelineRunEmptyTitle => 'Inga pipelines redo att köra';

  @override
  String get pipelineRunEmptyHint =>
      'Aktivera en pipeline och slå på manuell körning i dess redigerare för att starta den här.';

  @override
  String get pipelineRunManageTemplates => 'Hantera pipelines';

  @override
  String get pipelineRunSettingsTitle => 'Manuell körning';

  @override
  String get pipelineRunSettingsAllow => 'Tillåt manuell körning';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'Visa den här pipelinen på körningssidan så att den kan startas för hand.';

  @override
  String get pipelineRunSettingsConcurrencyTitle => 'Samtidighet';

  @override
  String get pipelineRunSettingsMaxParallel => 'Max parallella körningar';

  @override
  String get pipelineRunSettingsMaxParallelHelp =>
      'Lämna tomt för obegränsat. Extra körningar väntar i kö och startar när platser blir lediga.';

  @override
  String get pipelineRunSettingsMaxParallelHint => 'Obegränsat';

  @override
  String get pipelineRunSettingsMaxParallelInvalid =>
      'Ange ett heltal på 1 eller mer, eller lämna tomt för obegränsat.';

  @override
  String get pipelineRunSettingsInputsTitle => 'Indata';

  @override
  String get pipelineRunSettingsAddInput => 'Lägg till indata';

  @override
  String get pipelineRunSettingsNoInputs => 'Ingen indata ännu.';

  @override
  String get pipelineInputEditTitle => 'Indatafält';

  @override
  String get pipelineInputKeyLabel => 'Nyckel';

  @override
  String get pipelineInputKeyHelp =>
      'Tillståndsnyckel värdet lagras under (t.ex. repo_full_name).';

  @override
  String get pipelineInputLabelLabel => 'Etikett';

  @override
  String get pipelineInputTypeLabel => 'Typ';

  @override
  String get pipelineInputOptionsLabel => 'Alternativ (kommaseparerade)';

  @override
  String get pipelineInputDefaultLabel => 'Standardvärde';

  @override
  String get pipelineInputPlaceholderLabel => 'Platshållare';

  @override
  String get pipelineInputHelpLabel => 'Hjälptext';

  @override
  String get pipelineInputRequiredLabel => 'Obligatorisk';

  @override
  String get pipelineInputTypeText => 'Text';

  @override
  String get pipelineInputTypeMultiline => 'Flerradig text';

  @override
  String get pipelineInputTypeNumber => 'Nummer';

  @override
  String get pipelineInputTypeBoolean => 'Växel';

  @override
  String get pipelineInputTypeSelect => 'Välj';

  @override
  String get pipelinesEmpty => 'Inga pipelinekörningar ännu';

  @override
  String get pipelinesEmptyHint =>
      'Klicka på \"Kör pipeline\" för att starta en.';

  @override
  String get pipelinesNoSteps => 'Inga steg registrerade ännu';

  @override
  String get pipelinesNoActiveWorkspace =>
      'Välj en arbetsyta för att se dess pipelines';

  @override
  String pipelinesLoadError(String error) {
    return 'Kunde inte läsa in pipelines: $error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'Kunde inte starta pipeline: $error';
  }

  @override
  String get pipelineStatusPending => 'Väntar';

  @override
  String get pipelineStatusQueued => 'I kö';

  @override
  String get pipelineStatusRunning => 'Körs';

  @override
  String get pipelineStatusSuspended => 'Pausad';

  @override
  String get pipelineStatusCompleted => 'Slutförd';

  @override
  String get pipelineStatusFailed => 'Misslyckades';

  @override
  String get pipelineStatusCancelled => 'Avbruten';

  @override
  String get pipelineStatusSkipped => 'Hoppad över';

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed av $total steg';
  }

  @override
  String get pipelineWaterfallTimeline => 'Tidslinje';

  @override
  String pipelineWaterfallActive(String duration) {
    return 'Aktiv $duration';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return 'overksam $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip =>
      'Tid som inte räknas in i aktiv total: körningen var stoppad eller väntade mellan steg.';

  @override
  String get pipelineStepStarted => 'Startad';

  @override
  String get pipelineStepFinished => 'Avslutad';

  @override
  String get pipelineStepDurationLabel => 'Varaktighet';

  @override
  String get pipelineStepBranch => 'Gren';

  @override
  String get pipelineStepViewConversation => 'Visa samtal';

  @override
  String get pipelineStepError => 'Fel';

  @override
  String get pipelineStepInput => 'Indata';

  @override
  String get pipelineStepOutput => 'Utdata';

  @override
  String get pipelineStepNotExecuted => 'Inte körd ännu';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'Misslyckades vid $step';
  }

  @override
  String get pipelineRunTriggerManual => 'Manuell';

  @override
  String get pipelineStepSkippedReason => 'Hoppad över';

  @override
  String get pipelineStepPriorAttempts => 'Tidigare försök';

  @override
  String get pipelineStepAttemptLabel => 'Försök';

  @override
  String pipelineStepAttemptN(int number) {
    return 'Försök $number';
  }

  @override
  String get pipelineStepAttemptInterrupted => 'Avbruten';

  @override
  String get pipelineRunColumnPipeline => 'Pipeline';

  @override
  String get pipelineRunColumnDuration => 'Varaktighet';

  @override
  String get pipelineRunQueueNext => 'Nästa';

  @override
  String pipelineRunQueuePosition(int position) {
    return '$position i kön';
  }

  @override
  String get pipelineRunColumnStarted => 'Startad';

  @override
  String get pipelineRunHistory => 'Körningshistorik';

  @override
  String get pipelineRunHistoryEmpty => 'Inga andra körningar ännu';

  @override
  String pipelineRunRerunAgo(String time) {
    return 'Omkörning $time';
  }

  @override
  String pipelineRunAttempt(int number) {
    return 'Försök $number';
  }

  @override
  String pipelineRunFirstStarted(String time) {
    return 'först startad $time';
  }

  @override
  String get pipelineRunFilterAll => 'Alla';

  @override
  String get pipelineRunFilterEmpty => 'Inga körningar matchar det här filtret';

  @override
  String get relativeJustNow => 'just nu';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min sedan',
      one: '1 min sedan',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count timmar sedan',
      one: '1 timme sedan',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagar sedan',
      one: '1 dag sedan',
    );
    return '$_temp0';
  }

  @override
  String get teamsTitle => 'Team';

  @override
  String get teamsAddTeam => 'Lägg till team';

  @override
  String get teamsLoadError => 'Kunde inte läsa in team';

  @override
  String get teamsEmptyTitle => 'Inga team ännu';

  @override
  String get teamsEmptyDescription =>
      'Gruppera agenter i team så att arbete som tilldelas ett team går via en ledare som delegerar.';

  @override
  String get teamCreateTitle => 'Nytt team';

  @override
  String get teamEditTitle => 'Redigera team';

  @override
  String get teamNameLabel => 'Teamnamn';

  @override
  String get teamNameHint => 't.ex. Frontend';

  @override
  String get teamDescriptionLabel => 'Beskrivning';

  @override
  String get teamDescriptionHint => 'Vad det här teamet ansvarar för';

  @override
  String get teamLeaderLabel => 'Ledare';

  @override
  String get teamLeaderHelp =>
      'Koordinatorn som tar emot teamtilldelat arbete och delegerar till den bäst lämpade medlemmen.';

  @override
  String get teamNoLeader => 'Ingen ledare';

  @override
  String get teamInstructionsLabel => 'Driftsinstruktioner';

  @override
  String get teamInstructionsHelp =>
      'Läggs till i ledarens briefing – teamkonventioner, eskaleringsregler, ton.';

  @override
  String get teamInstructionsHint => 'Valfritt';

  @override
  String get teamSaved => 'Teamet sparades';

  @override
  String get teamMembersError => 'Kunde inte läsa in medlemmar';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count medlemmar',
      one: '1 medlem',
      zero: 'Inga medlemmar',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => 'Lägg till medlem';

  @override
  String get teamAddMemberTitle => 'Lägg till medlemmar';

  @override
  String teamAddMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lägg till $count',
      one: 'Lägg till 1',
      zero: 'Lägg till',
    );
    return '$_temp0';
  }

  @override
  String get teamNoAgentsToAdd => 'Alla agenter är redan i det här teamet.';

  @override
  String get teamRemoveMember => 'Ta bort från team';

  @override
  String get teamLeaderBadge => 'Ledare';

  @override
  String get teamUnknownAgent => 'Okänd agent';

  @override
  String get teamMembersEmpty => 'Inga medlemmar ännu';

  @override
  String get teamMembersEmptyDescription =>
      'Lägg till agenter så att ledaren har någon att delegera till.';

  @override
  String get teamSelectPrompt => 'Välj ett team';

  @override
  String get teamSelectPromptDescription =>
      'Välj ett team från listan, eller skapa ett nytt.';

  @override
  String get teamDeleteTitle => 'Ta bort team?';

  @override
  String teamDeleteBody(String name) {
    return '$name tas bort. Dess agenter påverkas inte.';
  }

  @override
  String get teamHasLeaderTooltip => 'Har en ledare';

  @override
  String get pipelineTemplatesNav => 'Pipelinemallar';

  @override
  String get pipelineTemplatesTitle => 'Pipelinemallar';

  @override
  String get pipelineTemplatesSubtitle =>
      'Dra-och-släpp-redigerare för pipelines som orkestrerar dina agenter.';

  @override
  String get pipelineTemplatesNew => 'Ny mall';

  @override
  String get pipelineTemplatesEmpty =>
      'Inga pipelinemallar ännu. Skapa en för att komma igång.';

  @override
  String get pipelineTemplateBuiltInBadge => 'Inbyggd';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'Ta bort mall?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'Ta bort pipelinemallen $name? Det går inte att ångra.';
  }

  @override
  String get pipelineTemplateEditorSubtitle =>
      'Dra nodtyper från sidofältet till duken och koppla sedan ihop dem.';

  @override
  String get unsavedChanges => 'Osparade ändringar';

  @override
  String get nodeLibraryTitle => 'Nodbibliotek';

  @override
  String get nodeLibraryHint =>
      'Dra en post till duken för att lägga till en nod.';

  @override
  String get editorEmptyCanvas => 'Dra en nod från biblioteket för att börja.';

  @override
  String get pipelineWhenThisHappens => 'När detta händer';

  @override
  String get pipelineDoThis => 'Gör detta';

  @override
  String get pipelineAddStep => 'Lägg till steg';

  @override
  String get pipelineTidyUp => 'Städa upp layouten';

  @override
  String get pipelineEditorHint =>
      'Dra steg för att ordna · dra ett handtag för att koppla';

  @override
  String get pipelineRemoveConnection => 'Ta bort anslutning';

  @override
  String get pipelineDragToConnect => 'Dra för att koppla';

  @override
  String get pipelineNewDefaultName => 'Ny pipeline';

  @override
  String get nodeCategoryTriggers => 'Triggrar';

  @override
  String get triggerEventWebhook => 'Webhook';

  @override
  String get pipelineAddTrigger => 'Lägg till en trigger';

  @override
  String get pipelineOnEvent => 'Vid händelse';

  @override
  String get nodeConfigTitle => 'Nodkonfiguration';

  @override
  String get nodeConfigKind => 'Typ';

  @override
  String get nodeConfigLabel => 'Etikett';

  @override
  String get nodeConfigAgent => 'Agent';

  @override
  String get nodeConfigAgentHint => 'Välj en agent…';

  @override
  String get nodeConfigInputKeys => 'Indatanycklar (kommaseparerade)';

  @override
  String get nodeConfigInputKeysHelp =>
      'Tillståndsnycklar den här noden förbrukar. Används för platshållarersättning i prompten.';

  @override
  String get nodeConfigRepos => 'Arkiv att klona';

  @override
  String get nodeConfigReposHelp =>
      'Arkiv som klonas och kodindexeras när den här noden startar sitt samtal. Att välja alla arkiv klonar dem alla (standard).';

  @override
  String get nodeConfigRepoBranchHint => 'Gren (standard)';

  @override
  String get nodeConfigRepoBranchHelp =>
      'Grenen varje checkout skärs från. Lämna tomt för arkivets egen standardgren – worktree får ändå en egen gren, så ingenting en agent committar landar på den här.';

  @override
  String nodeConfigReposDynamic(String entries) {
    return 'Dynamiska poster behållna: $entries';
  }

  @override
  String get nodeConfigCreateConversation => 'Öppna ett samtal i den';

  @override
  String get nodeConfigCreateConversationHelp =>
      'Lämna det här av när flera agentnoder följer – var och en öppnar en egen namngiven ström. Slå på det när en enda agentnod följer, så att rummet aldrig visar ett namnlöst samtal bredvid.';

  @override
  String get nodeConfigConversationTitle => 'Samtalsnamn';

  @override
  String get nodeConfigConversationTitleHelp =>
      'Ge agentnoden nedströms samma namn så arbetar båda i en ström. Standard är nodens etikett.';

  @override
  String get nodeConfigSpaceName => 'Ytnamn';

  @override
  String get nodeConfigSpaceNameHelp =>
      'Vad rummet den här noden öppnar kallas. Stödjer samma tillståndsplatshållare som en prompt. Lämna tomt för att använda nodens etikett.';

  @override
  String get nodeConfigSpaceNameHint => 'Granskning av pr_number';

  @override
  String get nodeConfigStreamTitle => 'Samtalsnamn';

  @override
  String get nodeConfigStreamTitleHelp =>
      'Den namngivna ström den här nodens agent arbetar i inne i rummet. Stödjer samma tillståndsplatshållare som en prompt. Lämna tomt så landar turen i rummets stående samtal, där en utspridning väver in varje agent.';

  @override
  String get nodeConfigConversationTitleHint => 'Arkitekturanalys';

  @override
  String get nodeConfigOutputKey => 'Utdatanyckel';

  @override
  String get nodeConfigPrompt => 'Promptmall';

  @override
  String get nodeConfigPromptHelp =>
      'Använd dubbelklammerplatshållare för att hämta värden från tillståndet vid körning.';

  @override
  String get nodeConfigScript => 'Bash-skript';

  @override
  String get nodeConfigScriptHelp =>
      'Körs med bash -c. GITHUB_TOKEN är satt. Platshållare ersätts före körning.';

  @override
  String get nodeConfigRouteKeys => 'Ruttnycklar';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'Ruttnyckel från $source';
  }

  @override
  String get conditionSectionTitle => 'Villkor';

  @override
  String get conditionMode => 'Läge';

  @override
  String get conditionModeFilesAny => 'Fil(er) finns – någon';

  @override
  String get conditionModeFilesAll => 'Filer finns – alla';

  @override
  String get conditionModeComparison => 'Jämförelse';

  @override
  String get conditionModeSwitch => 'Växel';

  @override
  String get conditionFilePaths => 'Filsökvägar';

  @override
  String get conditionFilePathsAnyHelp =>
      'En sökväg per rad, relativ till baskatalogen. Ruttar sant när någon finns.';

  @override
  String get conditionFilePathsAllHelp =>
      'En sökväg per rad, relativ till baskatalogen. Ruttar sant bara när alla finns.';

  @override
  String get conditionBaseKey => 'Baskatalognyckel';

  @override
  String get conditionBaseKeyHelp =>
      'Tillståndsnyckel som håller katalogen sökvägar löses mot (standard repo_local_path).';

  @override
  String get conditionRecursive => 'Sök i underkataloger';

  @override
  String get conditionNegate => 'Invertera: rutta sant när de saknas';

  @override
  String get conditionLeft => 'Vänster värde';

  @override
  String get conditionOperator => 'Operator';

  @override
  String get conditionRight => 'Höger värde';

  @override
  String get conditionSwitchKey => 'Växla på tillståndsnyckel';

  @override
  String get conditionCases => 'Fall (kommaseparerade)';

  @override
  String get conditionCasesHelp =>
      'Ruttnycklar att matcha mot värdet, i ordning.';

  @override
  String get conditionDefaultCase => 'Standardfall';

  @override
  String get triggerManualHelp => 'Visa på körningssidan och starta för hand.';

  @override
  String get triggerKindSchedule => 'Enligt schema';

  @override
  String get triggerScheduleExprLabel => 'Schema (cron eller every:seconds)';

  @override
  String get triggerTimezoneLabel => 'Tidszon (valfritt)';

  @override
  String get triggerCatchUpLabel => 'Vid missade körningar';

  @override
  String get triggerCatchUpRunOnce => 'Kör en gång';

  @override
  String get triggerCatchUpSkip => 'Hoppa över';

  @override
  String get syncHealthTitle => 'Synkhälsa';

  @override
  String get syncHealthNoConfigs => 'Inga synkanslutningar ännu';

  @override
  String get syncHealthNeverSynced => 'Aldrig synkad';

  @override
  String get syncOutcomeOk => 'Synkad';

  @override
  String get syncOutcomeFailed => 'Misslyckades';

  @override
  String get syncOutcomeSkipped => 'Hoppad över';

  @override
  String syncHealthFailedStreak(int count) {
    return '$count fel i följd';
  }

  @override
  String get triggerWebhookHelp =>
      'En signerad webhook-URL genereras. Externa system skickar POST till den för att starta den här pipelinen.';

  @override
  String get triggerWebhookPathLabel => 'Webhook-sökväg';

  @override
  String get triggerMatchStatusLabel => 'Bara när statusen är';

  @override
  String get triggerSummaryNone => 'Inga triggrar';

  @override
  String triggerEverySeconds(int seconds) {
    return 'Var $seconds s';
  }

  @override
  String get triggerEventManual => 'Manuell körning';

  @override
  String get triggerEventSchedule => 'Schema';

  @override
  String get triggerEventPrStatusChanged => 'PR-status ändrad';

  @override
  String get triggerEventExternalPr => 'Extern PR öppnad';

  @override
  String get triggerEventPrPublished => 'PR publicerad';

  @override
  String get triggerEventPrMerged => 'PR sammanslagen';

  @override
  String get triggerEventRepoAdded => 'Arkiv tillagt';

  @override
  String get triggerEventCodeGraphWatch => 'Filändring';

  @override
  String pipelineRunCauseChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ändrade filer',
      one: '1 ändrad fil',
    );
    return '$_temp0';
  }

  @override
  String pipelineRunCauseMorePaths(int count) {
    return '+$count till';
  }

  @override
  String get pipelineRunCauseRescan => 'Ändrad på disk';

  @override
  String get pipelineRunCauseInitial =>
      'Första indexeringen av den här checkouten';

  @override
  String get triggerEventMessageReceived => 'Meddelande mottaget';

  @override
  String get triggerEventTicketCompleted => 'Ärende slutfört';

  @override
  String get triggerEventTicketFailed => 'Ärende misslyckades';

  @override
  String get triggerEventTicketCancelled => 'Ärende avbrutet';

  @override
  String get triggerEventBudgetCrossed => 'Budgettröskel passerad';

  @override
  String get nodeLibrarySearchHint => 'Sök noder';

  @override
  String get nodeLibraryNoMatches => 'Inga matchande noder';

  @override
  String get nodeCategoryFlow => 'Flöde och logik';

  @override
  String get nodeCategoryPr => 'PR-granskning';

  @override
  String get nodeCategoryAgents => 'Agenter';

  @override
  String get nodeCategoryMessaging => 'Meddelanden';

  @override
  String get nodeCategoryCode => 'Kod';

  @override
  String get triggerDisabledTag => 'av';

  @override
  String get pipelineInputTypeRepo => 'Arkiv';

  @override
  String get pipelineRunNoRepos => 'Inga arkiv i den här arbetsytan ännu.';

  @override
  String get allowTicketingApi => 'Tillåt API-anrop för ärenden';

  @override
  String get ticketingApiKey => 'API-nyckel för ärenden';

  @override
  String get ticketingApiKeySubtitle =>
      'Injicerar ärendeleverantörens API-nyckel i sandlådan.';

  @override
  String get ticketingProvider => 'Ärendeleverantör';

  @override
  String get connectGitHubAndTicketing =>
      'Anslut en kodvärd så att Control Center kan läsa dina pull requests, issues och granskningar. Anslut valfritt en ärendeleverantör. Inloggningsuppgifter hålls av din server, aldrig av den här maskinen.';

  @override
  String get triggerEventTicketAssigned => 'Ärende tilldelat';

  @override
  String get triggerEventTicketCreated => 'Ärende skapat';

  @override
  String get triggerEventTicketStatusChanged => 'Ärendestatus ändrad';

  @override
  String get triggerEventMeetingRecordingStopped => 'Mötesinspelning stoppad';

  @override
  String get triggerEventSkillUpdated => 'Färdighet uppdaterad';

  @override
  String get triggerEventSpaceDeleted => 'Yta borttagen';

  @override
  String get triggerExternalPrHelp =>
      'En pull request öppnad på kodvärden, inte från Control Center.';

  @override
  String get triggerPrPublishedHelp =>
      'En pull request öppnad från Control Center eller av en agent.';

  @override
  String get triggerPrStatusChangedHelp =>
      'Sammanslagen, stängd, öppnad, återöppnad eller godkänd. Filtrera efter status i inspektören.';

  @override
  String get triggerPrMergedHelp =>
      'Bara när pull requesten slås ihop, inte när den stängs eller öppnas igen.';

  @override
  String get triggerRepoAddedHelp =>
      'Ett arkiv kopplas till det här arbetsområdet.';

  @override
  String get triggerCodeGraphWatchHelp =>
      'En fil i ett kopplat arkiv ändras på disken.';

  @override
  String get triggerMessageReceivedHelp =>
      'Ett nytt meddelande kommer in i ett utrymme.';

  @override
  String get triggerTicketCreatedHelp =>
      'Ett ärende skapas i det här arbetsområdet.';

  @override
  String get triggerTicketStatusChangedHelp => 'Ett ärende byter status.';

  @override
  String get triggerTicketCompletedHelp => 'Ett ärende avslutas utan fel.';

  @override
  String get triggerTicketFailedHelp =>
      'En agentkörning misslyckades och ärendet markeras som misslyckat.';

  @override
  String get triggerTicketCancelledHelp =>
      'Ett ärende avbryts och fortsätter inte.';

  @override
  String get triggerBudgetCrossedHelp =>
      'En utgiftsgräns för arbetsområdet eller agenten överskrids.';

  @override
  String get triggerTicketAssignedHelp =>
      'Ett ärende tilldelas en person, agent eller ett team.';

  @override
  String get triggerMeetingRecordingStoppedHelp =>
      'En mötesinspelning tar slut.';

  @override
  String get triggerSkillUpdatedHelp =>
      'En färdighet installeras eller uppdateras.';

  @override
  String get triggerSpaceDeletedHelp => 'Ett samtalsutrymme tas bort.';

  @override
  String get navTickets => 'Ärenden';

  @override
  String get ticketsTitle => 'Ärenden';

  @override
  String get newTicket => 'Nytt ärende';

  @override
  String get noTicketsYet => 'Inga ärenden ännu';

  @override
  String get addCollaborator => 'Lägg till medarbetare';

  @override
  String get noCollaborators => 'Inga medarbetare ännu';

  @override
  String get linkedPullRequests => 'Länkade pull requests';

  @override
  String get noLinkedPullRequests => 'Inga länkade pull requests ännu';

  @override
  String get stopAgent => 'Stoppa agent';

  @override
  String get ticketProperties => 'Egenskaper';

  @override
  String get ticketTabIssue => 'Issue';

  @override
  String get ticketSelectPrompt => 'Välj ett ärende för att se dess detaljer';

  @override
  String get unassigned => 'Ej tilldelad';

  @override
  String get ticketStatusBacklog => 'Backlog';

  @override
  String get ticketStatusOpen => 'Att göra';

  @override
  String get ticketStatusInProgress => 'Pågår';

  @override
  String get ticketStatusInReview => 'Under granskning';

  @override
  String get ticketStatusDone => 'Klar';

  @override
  String get ticketStatusBlocked => 'Blockerad';

  @override
  String get ticketStatusFailed => 'Misslyckades';

  @override
  String get ticketStatusCancelled => 'Avbruten';

  @override
  String get notificationTicketAssigned => 'Ärende tilldelat';

  @override
  String get notificationTicketStatusChanged => 'Ärendestatus ändrad';

  @override
  String get priority => 'Prioritet';

  @override
  String get status => 'Status';

  @override
  String get assignee => 'Tilldelad';

  @override
  String get labels => 'Etiketter';

  @override
  String get noLabelsYet => 'Inga etiketter ännu';

  @override
  String get clearLabels => 'Rensa etiketter';

  @override
  String get pipelineStepAgentActivity => 'Agentaktivitet';

  @override
  String get runStatusCompleted => 'Slutförd';

  @override
  String get runStatusQueued => 'I kö';

  @override
  String get ticketDescription => 'Beskrivning';

  @override
  String get ticketPriorityNone => 'Ingen';

  @override
  String get ticketPriorityUrgent => 'Brådskande';

  @override
  String get ticketPriorityHigh => 'Hög';

  @override
  String get ticketPriorityMedium => 'Medel';

  @override
  String get ticketPriorityLow => 'Låg';

  @override
  String get ticketViewList => 'Lista';

  @override
  String get ticketViewBoard => 'Tavla';

  @override
  String get ticketTitlePlaceholder => 'Issue-titel';

  @override
  String get ticketDescriptionPlaceholder => 'Lägg till beskrivning…';

  @override
  String get createMore => 'Skapa fler';

  @override
  String selectedCount(int count) {
    return '$count valda';
  }

  @override
  String get clearSelection => 'Rensa urval';

  @override
  String get bulkDeleteTitle => 'Ta bort ärenden';

  @override
  String bulkDeleteMessage(int count) {
    return 'Ta bort $count valda ärenden? Det går inte att ångra.';
  }

  @override
  String get assignTo => 'Tilldela till…';

  @override
  String get sectionMembers => 'Medlemmar';

  @override
  String get sectionAgents => 'Agenter';

  @override
  String get sidebarGroupWorkspace => 'Arbetsyta';

  @override
  String get notificationsTitle => 'Aviseringar';

  @override
  String get notificationsTooltip => 'Aviseringar';

  @override
  String get notificationsEmpty => 'Du är ikapp';

  @override
  String notificationsUnreadCount(int count) {
    return '$count olästa';
  }

  @override
  String get notificationsMarkRead => 'Markera som läst';

  @override
  String get notificationsMarkUnread => 'Markera som oläst';

  @override
  String get notificationsEntryActions => 'Aviseringsåtgärder';

  @override
  String get markAllRead => 'Markera alla som lästa';

  @override
  String get teamsNav => 'Team';

  @override
  String get noWorkspace => 'Ingen arbetsyta';

  @override
  String get selectWorkspace => 'Välj en arbetsyta';

  @override
  String get navMemory => 'Minne';

  @override
  String get memoryTabFacts => 'Fakta';

  @override
  String get memoryTabPolicies => 'Policyer';

  @override
  String get memoryGraphShowFacts => 'Visa fakta';

  @override
  String get memoryGraphHideFacts => 'Dölj fakta';

  @override
  String get memoryGraphExpandAll => 'Visa alla fakta';

  @override
  String get memoryGraphCollapseAll => 'Fäll ihop alla fakta';

  @override
  String get memoryTabGraph => 'Kunskapsgraf';

  @override
  String get memoryNoWorkspace => 'Välj en arbetsyta för att se dess minne.';

  @override
  String get searchArticles => 'Sök artiklar';

  @override
  String get filterAll => 'Alla';

  @override
  String get filterUnread => 'Olästa';

  @override
  String get filterSaved => 'Sparade';

  @override
  String get saveArticle => 'Spara artikel';

  @override
  String get removeFromSaved => 'Ta bort från sparade';

  @override
  String get filterBySource => 'Filtrera efter källa';

  @override
  String get viewAsList => 'Listvy';

  @override
  String get viewAsGrid => 'Rutnätsvy';

  @override
  String get noMatchingArticles => 'Inga matchande artiklar';

  @override
  String get noMatchingArticlesBody =>
      'Prova en annan sökning eller källfilter.';

  @override
  String get allCaughtUp => 'Du är ikapp';

  @override
  String get allCaughtUpBody => 'Inga olästa artiklar – kom tillbaka senare.';

  @override
  String get openArticlesInAppDescription =>
      'Öppna länkar i den inbyggda läsaren i stället för din standardwebbläsare.';

  @override
  String get blockAdsTrackersDescription =>
      'Ta bort annonser, spårare och cookie-rutor från artiklar du öppnar i läsaren.';

  @override
  String get agentQuestionHeader => 'Fråga till dig';

  @override
  String get agentQuestionAnsweredLabel => 'Besvarad';

  @override
  String get agentQuestionFreeformHint => 'Skriv ditt svar…';

  @override
  String agentQuestionProgress(int index, int count) {
    return 'Fråga $index av $count';
  }

  @override
  String get agentQuestionSkip => 'Hoppa över';

  @override
  String get agentQuestionSkippedLabel => 'Överhoppad';

  @override
  String get agentQuestionFreeformOptionHint => 'Beskriv med egna ord…';

  @override
  String get reviewRequested => 'Granskning begärd';

  @override
  String get connectGitHubHint =>
      'Logga in på GitHub eller lägg till en token i Inställningar → Du → Profil och identitet → Kodvärd';

  @override
  String get connectGitHubToLoadPrs =>
      'Anslut GitHub för att läsa in pull requests';

  @override
  String get noRepositoriesConfigured => 'Inga arkiv konfigurerade';

  @override
  String openedAgo(String age) {
    return 'Öppnad $age';
  }

  @override
  String prTimelineOpened(String author) {
    return '$author öppnade den här pull requesten';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$author öppnade den här pull requesten med $_temp0';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return '$actor begärde granskning från $reviewers';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '$actor tog bort granskningsförfrågan för $reviewers';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '$actor begärde granskning från $requested och tog bort granskningsförfrågan för $removed';
  }

  @override
  String prTimelineAddedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'etiketterna',
      one: 'etiketten',
    );
    return '$actor lade till $_temp0 $labels';
  }

  @override
  String prTimelineRemovedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'etiketterna',
      one: 'etiketten',
    );
    return '$actor tog bort $_temp0 $labels';
  }

  @override
  String prTimelineAddedAndRemovedLabels(
    String actor,
    String added,
    int addedCount,
    String removed,
    int removedCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      addedCount,
      locale: localeName,
      other: 'etiketterna',
      one: 'etiketten',
    );
    String _temp1 = intl.Intl.pluralLogic(
      removedCount,
      locale: localeName,
      other: 'etiketterna',
      one: 'etiketten',
    );
    return '$actor lade till $_temp0 $added och tog bort $_temp1 $removed';
  }

  @override
  String prTimelineCommitted(String author) {
    return '$author committade';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$author pushade $_temp0';
  }

  @override
  String prTimelineApproved(String author) {
    return '$author godkände de här ändringarna';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return '$author begärde ändringar';
  }

  @override
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kodkommentarer',
      one: '1 kodkommentar',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '$author granskade';
  }

  @override
  String get prTimelineSomeone => 'Någon';

  @override
  String get prTimelineBotBadge => 'bot';

  @override
  String updatedAgo(String age) {
    return 'Uppdaterad $age';
  }

  @override
  String get checksPassing => 'Kontroller går igenom';

  @override
  String get checksRunning => 'Kontroller körs';

  @override
  String get needsYourReview => 'Behöver din granskning';

  @override
  String get checks => 'Kontroller';

  @override
  String get noReviewersAssigned => 'Inga granskare tilldelade';

  @override
  String get noAssignees => 'Inga tilldelade';

  @override
  String get loadingEllipsis => 'Läser in…';

  @override
  String get loadingChecks => 'Läser in kontroller…';

  @override
  String get noChecksYet => 'Inga kontroller har körts ännu';

  @override
  String get noChangesToReview => 'Inga ändringar att granska';

  @override
  String checksFailingCount(int count) {
    return '$count misslyckas';
  }

  @override
  String get showMore => 'Visa mer';

  @override
  String get showLess => 'Visa mindre';

  @override
  String get backToPullRequests => 'Tillbaka till pull requests';

  @override
  String get pullRequestNotFound => 'Pull request hittades inte';

  @override
  String get pullRequestNotFoundBody =>
      'Den kan ha slagits samman, stängts eller flyttats.';

  @override
  String get couldntLoadPullRequest =>
      'Kunde inte läsa in den här pull requesten';

  @override
  String get showDetails => 'Visa detaljer';

  @override
  String get noDescriptionProvided => 'Ingen beskrivning angiven.';

  @override
  String get factsHint => 'Fakta visas här när dina agenter lär sig.';

  @override
  String get noFactsMatch => 'Inga fakta matchar din sökning';

  @override
  String get memoryLoadError => 'Kunde inte läsa in minne';

  @override
  String get sortRecent => 'Senaste';

  @override
  String get sortConfidence => 'Tillförlitlighet';

  @override
  String get confidenceTooltip =>
      'Hur säkra agenter är på att den här faktan är sann, från 0 till 100 %.';

  @override
  String get supersededTooltip => 'En nyare fakta har ersatt den här.';

  @override
  String get domain => 'Domän';

  @override
  String get fitToView => 'Anpassa till vyn';

  @override
  String get project => 'Projekt';

  @override
  String get newProject => 'Nytt projekt';

  @override
  String get editProject => 'Redigera projekt';

  @override
  String get deleteProject => 'Ta bort projekt';

  @override
  String get noProject => 'Inget projekt';

  @override
  String get allTickets => 'Alla ärenden';

  @override
  String get projectNamePlaceholder => 'Projektnamn';

  @override
  String get projectDescriptionPlaceholder => 'Beskrivning (valfritt)';

  @override
  String get projectColorLabel => 'Färg';

  @override
  String get noProjectsYet => 'Inga projekt ännu';

  @override
  String get projectTicketsEmpty => 'Inga ärenden i det här projektet ännu';

  @override
  String get createProject => 'Skapa projekt';

  @override
  String projectProgress(int done, int total) {
    return '$done av $total klara';
  }

  @override
  String deleteProjectConfirm(String name) {
    return 'Ta bort \"$name\"? Dess ärenden behålls och tas bort från projektet.';
  }

  @override
  String get projectStatusActive => 'Aktivt';

  @override
  String get projectStatusCompleted => 'Slutfört';

  @override
  String get projectStatusArchived => 'Arkiverat';

  @override
  String get markProjectCompleted => 'Markera som slutfört';

  @override
  String get markProjectActive => 'Markera som aktivt';

  @override
  String get archiveProject => 'Arkivera';

  @override
  String get restoreProject => 'Återställ';

  @override
  String get relations => 'Relationer';

  @override
  String get relateTo => 'Relatera till';

  @override
  String get relationSubIssueOf => 'Underärende till…';

  @override
  String get relationParentOf => 'Förälder till…';

  @override
  String get relationBlockedBy => 'Blockerad av…';

  @override
  String get relationBlocking => 'Blockerar…';

  @override
  String get relationRelatedTo => 'Relaterad till…';

  @override
  String get relationDuplicateOf => 'Dubblett av…';

  @override
  String get relationGroupParent => 'Förälder';

  @override
  String get relationGroupSubIssues => 'Underärenden';

  @override
  String get relationGroupBlockedBy => 'Blockerad av';

  @override
  String get relationGroupBlocking => 'Blockerar';

  @override
  String get relationGroupRelated => 'Relaterade';

  @override
  String get relationGroupDuplicateOf => 'Dubblett av';

  @override
  String get relationGroupDuplicatedBy => 'Duplicerad av';

  @override
  String get copyId => 'Kopiera ID';

  @override
  String get ticketIdCopied => 'Ärende-ID kopierat';

  @override
  String get searchTicketsHint => 'Sök ärenden…';

  @override
  String get noMatchingTickets => 'Inga ärenden matchar';

  @override
  String get clearAll => 'Rensa alla';

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs PR:ar',
      one: '1 PR',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos arkiv',
      one: '1 arkiv',
    );
    return '$_temp0 väntar på din granskning i $_temp1';
  }

  @override
  String get manageWorkspacesSubtitle =>
      'Byt namn på en arbetsyta och ändra dess märke – välj en till vänster för att redigera den.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arbetsytor',
      one: '1 arbetsyta',
      zero: 'Inga arbetsytor',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos arkiv',
      one: '1 arkiv',
      zero: 'Inga arkiv',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents agenter',
      one: '1 agent',
      zero: '0 agenter',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'Identitet';

  @override
  String get uploadImage => 'Ladda upp bild';

  @override
  String get failedToSaveLogo =>
      'Kunde inte spara logotypbilden. Kontrollera att appen kan läsa den valda filen.';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG eller GIF upp till 2 MB. Annars använder vi arbetsytans initial.';

  @override
  String get workspaceNameFieldHelp =>
      'Visas i växlaren, brödsmulan och på varje skärm.';

  @override
  String get dangerZone => 'Farozon';

  @override
  String get deleteThisWorkspace => 'Ta bort den här arbetsytan';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return 'Tar bort $name permanent, dess arkivanslutningar, agenter och minne. Det går inte att ångra.';
  }

  @override
  String get discard => 'Kasta';

  @override
  String discardChangesQuestion(String name) {
    return 'Kasta osparade ändringar i $name?';
  }

  @override
  String get workspaceUpdated => 'Arbetsytan uppdaterades';

  @override
  String get editTitle => 'Redigera titel';

  @override
  String get editDescription => 'Redigera beskrivning';

  @override
  String get addDescription => 'Lägg till en beskrivning';

  @override
  String get prTitlePlaceholder => 'Titel';

  @override
  String get prBodyPlaceholder => 'Lämna en beskrivning';

  @override
  String get write => 'Skriv';

  @override
  String get overview => 'Översikt';

  @override
  String get noFilesChanged => 'Inga filer ändrade';

  @override
  String get diff => 'Diff';

  @override
  String get preview => 'Förhandsgranska';

  @override
  String get outdated => 'Inaktuell';

  @override
  String get outdatedComments => 'Inaktuella kommentarer';

  @override
  String outdatedCountLabel(int count) {
    return '$count inaktuella';
  }

  @override
  String get prTemplateLabel => 'Mall';

  @override
  String get prTemplateDefault => 'Standard';

  @override
  String get addReviewers => 'Lägg till granskare';

  @override
  String get addAssignees => 'Lägg till tilldelade';

  @override
  String get searchUsers => 'Sök personer…';

  @override
  String get searchReviewers => 'Sök personer och team…';

  @override
  String get usersSectionLabel => 'Personer';

  @override
  String get userStatusBusy => 'Upptagen';

  @override
  String get teamsSectionLabel => 'Team';

  @override
  String get suggestedReviewers => 'Föreslagna granskare';

  @override
  String get noMatchingUsers => 'Inga matchande personer';

  @override
  String get noMatchingReviewers => 'Inga träffar';

  @override
  String get requiredByCodeOwners => 'Krävs av code owners';

  @override
  String reviewedOnBehalfOf(String login) {
    return 'via $login';
  }

  @override
  String get team => 'Team';

  @override
  String get markdownBold => 'Fet';

  @override
  String get markdownItalic => 'Kursiv';

  @override
  String get markdownHeading => 'Rubrik';

  @override
  String get markdownBulletList => 'Punktlista';

  @override
  String get markdownChecklist => 'Checklista';

  @override
  String get markdownCode => 'Kod';

  @override
  String get markdownLink => 'Länk';

  @override
  String get markdownQuote => 'Citat';

  @override
  String get markdownSupported => 'Markdown stöds';

  @override
  String get markdownAttachImages => 'Klicka för att lägga till bilder';

  @override
  String failedToUpdateTitle(String error) {
    return 'Kunde inte uppdatera titel: $error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'Kunde inte uppdatera beskrivning: $error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'Kunde inte uppdatera granskare: $error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'Kunde inte uppdatera tilldelade: $error';
  }

  @override
  String get discardChangesConfirm => 'Kasta dina ändringar?';

  @override
  String get newPr => 'Ny PR';

  @override
  String get openPullRequest => 'Öppna en pull request';

  @override
  String get composePrSubtitle =>
      'Från en gren du har pushat – inga agenter eller ärenden inblandade';

  @override
  String get createAsDraft => 'Skapa som utkast';

  @override
  String get composePrNoRepo => 'Inget GitHub-arkiv valt';

  @override
  String get composePrNoRepoHint =>
      'Välj en arbetsyta med ett GitHub-länkat arkiv för att öppna en pull request.';

  @override
  String get composePrPickBranches =>
      'Välj en bas- och jämförelsegren för att förhandsgranska ändringarna.';

  @override
  String get composePrNothingToCompare =>
      'Det finns inga ändringar mellan de här grenarna.';

  @override
  String get repository => 'Arkiv';

  @override
  String get baseBranchLabel => 'Bas';

  @override
  String get compareBranchLabel => 'Jämför';

  @override
  String get selectBranch => 'Välj en gren';

  @override
  String get navMeetings => 'Möten';

  @override
  String get meetingsNoWorkspace => 'Välj en arbetsyta för att se möten.';

  @override
  String get meetingsEmpty => 'Inga möten ännu';

  @override
  String get meetingsEmptyHint =>
      'Spela in ditt första möte – ljudet stannar på den här enheten och agenten gör det till anteckningar, beslut och åtgärdspunkter.';

  @override
  String get meetingNotesHint =>
      'Skriv korta anteckningar – agenten utökar dem efter mötet.';

  @override
  String get meetingSpeakerMe => 'Du';

  @override
  String get meetingStatusRecording => 'Spelar in';

  @override
  String get meetingStatusProcessing => 'Bearbetar';

  @override
  String get meetingStatusDone => 'Klar';

  @override
  String get meetingStatusFailed => 'Misslyckades';

  @override
  String get meetingsSubtitle =>
      'Fångade och transkriberade på den här enheten, sedan sammanfattade av en agent.';

  @override
  String get meetingsRecordMeeting => 'Spela in möte';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bearbetas nu',
      one: '1 bearbetas nu',
    );
    return '$_temp0';
  }

  @override
  String meetingsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count möten',
      one: '1 möte',
      zero: 'Inga möten',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLedgerOpenActions => 'Öppna åtgärder';

  @override
  String get meetingsLedgerDecisions => 'Beslut';

  @override
  String get meetingsLiveOpen => 'Öppna inspelning';

  @override
  String get meetingTemplateShort => 'Mall';

  @override
  String get meetingsStatThisWeek => 'Den här veckan';

  @override
  String get meetingsStatRecorded => 'Inspelade';

  @override
  String get meetingsFilterAll => 'Alla';

  @override
  String get meetingsFilterDone => 'Klara';

  @override
  String get meetingsFilterProcessing => 'Bearbetas';

  @override
  String get meetingsSearchHint => 'Filtrera efter titel, person, app…';

  @override
  String get meetingsBucketToday => 'Idag';

  @override
  String get meetingsBucketYesterday => 'Igår';

  @override
  String get meetingsBucketEarlierThisWeek => 'Tidigare den här veckan';

  @override
  String get meetingsBucketLastWeek => 'Förra veckan';

  @override
  String get meetingsBucketOlder => 'Äldre';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count beslut',
      one: '1 beslut',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total åtgärdspunkter';
  }

  @override
  String get meetingsEnhancedPill => 'förbättrad';

  @override
  String get meetingsTranscribing => 'transkriberar och sammanfattar…';

  @override
  String get meetingsOpenAction => 'Öppna';

  @override
  String get meetingsStopProcessing => 'Stoppa';

  @override
  String get meetingsStillTranscribing =>
      'Transkriberar fortfarande – sammanfattningen visas när den är klar.';

  @override
  String get meetingsNoMatch => 'Inga möten matchar';

  @override
  String get meetingsNoMatchHint => 'Prova ett annat filter eller sökord.';

  @override
  String get meetingBackAllMeetings => 'Alla möten';

  @override
  String get meetingReRunSummary => 'Kör om sammanfattning';

  @override
  String get meetingExport => 'Exportera';

  @override
  String get meetingAugmentingBanner =>
      'Förstärker dina anteckningar från utskriften – extraherar beslut och åtgärdspunkter…';

  @override
  String get meetingTabNotes => 'Anteckningar';

  @override
  String get meetingTabTranscript => 'Utskrift';

  @override
  String get meetingTabActionItems => 'Åtgärdspunkter';

  @override
  String get meetingTabDecisions => 'Beslut';

  @override
  String get meetingNotesEnhancedToggle => 'Förbättrade';

  @override
  String get meetingNotesYoursToggle => 'Dina anteckningar';

  @override
  String get meetingEnhancedByAgent => 'Förbättrad av agent · från utskrift';

  @override
  String get meetingEnhancedPending =>
      'Agenten arbetar fortfarande med den här sammanfattningen.';

  @override
  String get meetingNotesEmpty => 'Inga förbättrade anteckningar ännu.';

  @override
  String get meetingNotesSavedLocally => 'Sparad lokalt';

  @override
  String get meetingNotesSaving => 'Sparar…';

  @override
  String get meetingViewFullTranscript => 'Visa hela utskriften';

  @override
  String get meetingTranscriptSearchHint => 'Sök i utskriften…';

  @override
  String get meetingSpeakerEveryone => 'Alla';

  @override
  String get meetingSpeakerOthers => 'Andra';

  @override
  String get meetingTranscriptEmpty => 'Ingen utskrift ännu.';

  @override
  String get meetingActionItemsEmpty => 'Inga åtgärdspunkter extraherade.';

  @override
  String get meetingActionItemFrom => 'från det här mötet';

  @override
  String get meetingCreateTicket => 'Skapa ärende';

  @override
  String meetingTicketCreated(String key) {
    return 'Ärendet $key skapades och skickades ut.';
  }

  @override
  String get meetingTicketFailed => 'Kunde inte skapa ärendet.';

  @override
  String get meetingDecisionsEmpty => 'Inga beslut loggade.';

  @override
  String get meetingEditTitle => 'Redigera titel';

  @override
  String get meetingTitleLabel => 'Titel';

  @override
  String get meetingAddActionItem => 'Lägg till åtgärdspunkt';

  @override
  String get meetingEditActionItem => 'Redigera åtgärdspunkt';

  @override
  String get meetingDeleteActionItem => 'Ta bort åtgärdspunkt';

  @override
  String get meetingActionItemContentLabel => 'Åtgärdspunkt';

  @override
  String get meetingActionItemContentHint => 'Vad behöver göras?';

  @override
  String get meetingActionItemOwnerLabel => 'Ägare';

  @override
  String get meetingActionItemOwnerHint => 'Vem ansvarar? (valfritt)';

  @override
  String get meetingAddDecision => 'Lägg till beslut';

  @override
  String get meetingEditDecision => 'Redigera beslut';

  @override
  String get meetingDeleteDecision => 'Ta bort beslut';

  @override
  String get meetingDecisionContentLabel => 'Beslut';

  @override
  String get meetingDecisionContentHint => 'Vad beslutades?';

  @override
  String get meetingReRunStarted => 'Kör om sammanfattaren på utskriften…';

  @override
  String get meetingReRunNoTranscript =>
      'Det finns ingen utskrift att sammanfatta ännu.';

  @override
  String get meetingExportCopied =>
      'Anteckningar kopierade till urklipp som Markdown.';

  @override
  String get meetingExportSaved => 'Mötet exporterades.';

  @override
  String meetingExportFailed(String error) {
    return 'Exporten misslyckades: $error';
  }

  @override
  String get meetingExportNothing => 'Det finns inget att exportera ännu.';

  @override
  String get meetingPlaybackPlay => 'Spela';

  @override
  String get meetingPlaybackPause => 'Pausa';

  @override
  String get meetingPlaybackUnavailable =>
      'Ljuduppspelning saknas på den här enheten.';

  @override
  String get meetingDetectedTitle => 'Möte upptäckt';

  @override
  String meetingDetectedSubtitle(String label) {
    return 'Det ser ut som att \"$label\" pågår. Spela in det?';
  }

  @override
  String get meetingDetectedSubtitleGeneric =>
      'Det ser ut som att ett möte pågår. Spela in det?';

  @override
  String get meetingDetectedRecord => 'Spela in';

  @override
  String get meetingDetectedDismiss => 'Avfärda';

  @override
  String get meetingAutoStopTitle =>
      'Det här mötet ser ut att vara över. Stoppa inspelningen?';

  @override
  String get meetingAutoStopStop => 'Stoppa';

  @override
  String get meetingAutoStopKeep => 'Fortsätt spela in';

  @override
  String get meetingAutoDetect => 'Upptäck möten automatiskt';

  @override
  String get meetingAutoDetectDescription =>
      'Bevaka kalendern och konferensappar och erbjud att spela in när ett möte startar.';

  @override
  String get meetingsRecordingCrumb => 'Spelar in…';

  @override
  String get meetingRecordTitleHint => 'Mötestitel';

  @override
  String get meetingRecordTappingLabel => 'Tar upp:';

  @override
  String get meetingRecordMic => 'Mikrofon';

  @override
  String get meetingRecordSystemAudio => 'Systemljud';

  @override
  String get meetingRecordPause => 'Pausa';

  @override
  String get meetingRecordResume => 'Återuppta';

  @override
  String get meetingRecordStop => 'Stoppa och sammanfatta';

  @override
  String get meetingRecordYourNotes => 'Dina anteckningar';

  @override
  String get meetingRecordNotesPlaceholder =>
      'Skriv medan du lyssnar. Några fragment räcker – när du stoppar utökar agenten dem med utskriften.';

  @override
  String get meetingRecordLiveTranscript => 'Liveutskrift';

  @override
  String get meetingRecordDecoding => 'avkodar på enheten';

  @override
  String get meetingRecordListening =>
      'Lyssnar… tal syns här inom en sekund eller två, märkt Du / Andra.';

  @override
  String get meetingRecordPausedHint =>
      'Pausad – ljud ignoreras tills du återupptar.';

  @override
  String get meetingRecordNotActive => 'Ingen aktiv inspelning.';

  @override
  String get meetingHudRecording => 'spelar in';

  @override
  String get meetingHudPaused => 'pausad';

  @override
  String get meetingHudOpen => 'Öppna';

  @override
  String get meetingHudStop => 'Stoppa';

  @override
  String get meetingToolbarPopOut => 'Poppa ut';

  @override
  String get meetingToolbarHoldToStop =>
      'Håll inne för att stoppa inspelningen';

  @override
  String get meetingToolbarSemanticLabel => 'Verktygsfält för mötesinspelning';

  @override
  String get orchestrate => 'Orkestrera';

  @override
  String get orchestrationUnavailable => 'Orkestrering otillgänglig';

  @override
  String get orchestrationApprove => 'Godkänn plan';

  @override
  String get orchestrationReject => 'Avvisa';

  @override
  String get orchestrationCancel => 'Avbryt orkestrering';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count roller – $hires nya anställningar';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count underärenden';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'Uppskattad kostnad: \$$amount';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total underärenden klara';
  }

  @override
  String get orchestrationStatusProposed => 'Föreslagen';

  @override
  String get orchestrationStatusApproved => 'Godkänd';

  @override
  String get orchestrationStatusExecuting => 'Körs';

  @override
  String get orchestrationStatusSynthesizing => 'Syntetiserar';

  @override
  String get orchestrationStatusCompleted => 'Slutförd';

  @override
  String get orchestrationStatusFailed => 'Misslyckades';

  @override
  String get orchestrationStatusCancelled => 'Avbruten';

  @override
  String get messageFailed => 'Körningen misslyckades';

  @override
  String get turnLimitReached =>
      'Stoppad vid turgränsen – svara för att fortsätta';

  @override
  String get retried => 'Försökt igen';

  @override
  String replyingTo(String name) {
    return 'svarar $name';
  }

  @override
  String get silenceTimeoutLabel => 'Tystnadstimeout (minuter)';

  @override
  String get silenceTimeoutHint =>
      't.ex. 15 – avsluta en körning efter så här länge utan utdata';

  @override
  String get capabilityJsonMode => 'JSON-läge';

  @override
  String get capabilityModelSelection => 'Modellval';

  @override
  String get transcriptThinking => 'Tänker…';

  @override
  String transcriptThoughtFor(String duration) {
    return 'Tänkte i $duration';
  }

  @override
  String get transcriptStatusMakingEdits => 'Gör redigeringar…';

  @override
  String get transcriptStatusReadingFiles => 'Läser filer…';

  @override
  String get transcriptStatusSearching => 'Söker i kodbasen…';

  @override
  String get transcriptStatusRunningCommands => 'Kör kommandon…';

  @override
  String get transcriptStatusResponding => 'Svarar…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return 'Kör $tool…';
  }

  @override
  String get transcriptInput => 'Indata';

  @override
  String get transcriptOutput => 'Utdata';

  @override
  String get transcriptErrorLabel => 'Fel';

  @override
  String get transcriptSandboxBlocked => 'Sandlådan blockerade en åtgärd';

  @override
  String transcriptShowFullOutput(int kb) {
    return 'Visa all utdata (+$kb KB)';
  }

  @override
  String transcriptShowAllLines(int count) {
    return 'Visa alla $count rader';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return 'Visar de första $count raderna';
  }

  @override
  String get transcriptGrepNoMatches => 'Inga träffar';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '$matches träffar',
      one: '1 träff',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files filer',
      one: '1 fil',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return 'Person $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => 'Byt namn på talare';

  @override
  String get meetingRenameSpeakerTitle => 'Byt namn på talare';

  @override
  String get meetingSpeakerNameLabel => 'Namn';

  @override
  String get meetingSpeakerSuggestFromCalendar =>
      'Från det här mötets inbjudna';

  @override
  String get meetingRenameSpeakerApplyAll =>
      'Tillämpa på alla block från den här talaren';

  @override
  String get meetingRenameSpeakerScopeHint =>
      'När det är av byts bara den valda raden namn.';

  @override
  String get meetingLinkEvent => 'Länka till händelse';

  @override
  String get meetingChangeEvent => 'Byt händelse';

  @override
  String get meetingLinkEventTitle => 'Länka till en kalenderhändelse';

  @override
  String get meetingLinkEventSearchHint => 'Sök händelser';

  @override
  String get meetingLinkEventEmpty => 'Inga närliggande kalenderhändelser';

  @override
  String get meetingUnlinkEvent => 'Ta bort länk';

  @override
  String get calendarLinkExistingMeeting => 'Länka till befintligt möte';

  @override
  String get calendarLinkMeetingTitle => 'Länka ett möte';

  @override
  String get calendarLinkMeetingSearchHint => 'Sök möten';

  @override
  String get calendarLinkMeetingEmpty => 'Inga möten att länka';

  @override
  String get meetingRenameSpeakerFailed => 'Kunde inte byta namn på talaren';

  @override
  String get calendarLinkUpdateFailed => 'Kunde inte uppdatera kalenderlänken';

  @override
  String get rename => 'Byt namn';

  @override
  String get notNow => 'Inte nu';

  @override
  String get meetingSaveVoiceProfileTitle => 'Spara röstprofil?';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return 'Känn igen $name automatiskt i framtida möten genom att spara deras röstavtryck.';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return 'Sparade röstprofil för $name';
  }

  @override
  String get meetingVoiceProfileSaveFailed => 'Kunde inte spara röstprofilen';

  @override
  String get voiceProfilesSection => 'Röstprofiler';

  @override
  String get voiceProfilesDescription =>
      'Sparade röster känns igen automatiskt i framtida möten.';

  @override
  String get voiceProfilesEmpty =>
      'Inga sparade röster ännu. Namnge en talare i en mötesutskrift och välj sedan \"Spara röstprofil\".';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sampel',
      one: '1 sampel',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => 'Byt namn på röstprofil';

  @override
  String get deleteVoiceProfileTitle => 'Ta bort röstprofil?';

  @override
  String deleteVoiceProfileBody(String name) {
    return 'Sluta känna igen $name? Deras sparade röstavtryck tas bort. Namn som redan tillämpats i tidigare möten behålls.';
  }

  @override
  String get connectedLabel => 'Ansluten';

  @override
  String get ideTabGeneral => 'Allmänt';

  @override
  String get ideTabExplorer => 'Utforskare';

  @override
  String get ideTabSourceControl => 'Källkontroll';

  @override
  String get generalSectionTodos => 'Att göra';

  @override
  String get generalSectionGoals => 'Mål';

  @override
  String get goalRunStatusActive => 'Aktivt';

  @override
  String get goalRunStatusPaused => 'Pausat';

  @override
  String get goalRunStatusCompleted => 'Slutfört';

  @override
  String get goalRunStatusFailed => 'Misslyckades';

  @override
  String get goalRunStatusCancelled => 'Avbrutet';

  @override
  String get goalRunStatusBudgetExhausted => 'Budgeten är slut';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return 'Körning $run av $max · $cost av $cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return 'Körning $run · $cost av $cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return 'Förfaller $deadline';
  }

  @override
  String get goalRunPause => 'Pausa mål';

  @override
  String get goalRunResume => 'Återuppta mål';

  @override
  String goalRunResumeRaise(String cap) {
    return 'Återuppta · höj taket till $cap';
  }

  @override
  String get goalRunStop => 'Stoppa mål';

  @override
  String get generalSectionAgents => 'Agenter';

  @override
  String get generalSectionTerminals => 'Terminaler';

  @override
  String get generalTodosEmpty => 'Inga att-göra ännu';

  @override
  String get generalAgentsEmpty => 'Inga agenter körs';

  @override
  String get generalTerminalsEmpty => 'Inga terminaler öppna';

  @override
  String get generalSectionBrowsers => 'Webbläsare';

  @override
  String get generalSectionComputers => 'Datorer';

  @override
  String get generalBrowsersEmpty => 'Inga webbläsare öppna';

  @override
  String get generalComputersEmpty => 'Inga datorer öppna';

  @override
  String get generalSectionPhones => 'Telefoner';

  @override
  String get generalPhonesEmpty => 'Inga telefoner öppna';

  @override
  String get pauseAgent => 'Pausa agent';

  @override
  String get resumeAgent => 'Återuppta agent';

  @override
  String get agentCannotPause =>
      'Den här agenten kan inte pausas – stoppa den i stället.';

  @override
  String get goalClear => 'Rensa mål';

  @override
  String get undoLabelGoalClear => 'rensa mål';

  @override
  String get todoStatusPending => 'Inte startad';

  @override
  String get todoStatusInProgress => 'Pågår';

  @override
  String get todoStatusCompleted => 'Klar';

  @override
  String get reorderTodo => 'Ändra ordning på att-göra';

  @override
  String get focusTerminal => 'Fokusera terminal';

  @override
  String get focusMachine => 'Fokusera maskin';

  @override
  String get focusBrowser => 'Fokusera webbläsare';

  @override
  String get todoEditorTitle => 'Redigera att-göra';

  @override
  String get todoEditorHint =>
      'En post per rad. Använd - [ ] för väntande, - [~] för pågående, - [x] för klar.';

  @override
  String get todoNeedsText => 'Lägg till text efter kommandot';

  @override
  String get todoNotFound => 'Ingen matchande att-göra';

  @override
  String get todoCleared => 'Rensade att-göra-listan';

  @override
  String get todoNothingToCopy => 'Inget att kopiera';

  @override
  String todoAdded(String content) {
    return 'Lade till \"$content\"';
  }

  @override
  String todoStarted(String content) {
    return 'Startade \"$content\"';
  }

  @override
  String todoCompleted(String content) {
    return 'Slutförde \"$content\"';
  }

  @override
  String todoRemoved(String content) {
    return 'Tog bort \"$content\"';
  }

  @override
  String todoCopied(int count) {
    return 'Kopierade $count poster';
  }

  @override
  String todoImported(int count) {
    return 'Importerade $count poster';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return 'Okänt att-göra-kommando \"$name\"';
  }

  @override
  String get terminal => 'Terminal';

  @override
  String get ideCloseTab => 'Stäng flik';

  @override
  String get ideSplitEditor => 'Dela redigerare';

  @override
  String get ideSplitRight => 'Dela åt höger';

  @override
  String get ideSplitDown => 'Dela nedåt';

  @override
  String get ideSplitLeft => 'Dela åt vänster';

  @override
  String get ideSplitUp => 'Dela uppåt';

  @override
  String get ideCloseGroup => 'Stäng grupp';

  @override
  String get ideCloseOthers => 'Stäng övriga';

  @override
  String get ideCloseToRight => 'Stäng till höger';

  @override
  String get ideCloseSaved => 'Stäng sparade';

  @override
  String get ideCloseAll => 'Stäng alla';

  @override
  String get ideSplit => 'Dela';

  @override
  String get ideToggleSidebar => 'Växla sidofält';

  @override
  String get ideNewTab => 'Öppna redigerare';

  @override
  String get ideNewTabMenu => 'Ny flik';

  @override
  String get ideReviewCode => 'Granska kod';

  @override
  String get ideRevertConfirmTitle => 'Ångra ändringar';

  @override
  String get ideRevertUntracked => 'Ospårade filer kan inte återställas';

  @override
  String get ideRevertFailed =>
      'Kunde inte återställa filerna. Samtalets worktree kan saknas.';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filer',
      one: '1 fil',
    );
    return '$_temp0 kunde inte återställas (ospårade).';
  }

  @override
  String get ideSearchMatchCase => 'Matcha skiftläge';

  @override
  String get ideSearchWholeWord => 'Helt ord';

  @override
  String get ideSearchRegex => 'Regex';

  @override
  String get ideSearchFilters => 'Sökfilter';

  @override
  String get ideSearchFilesToInclude => 'Filer att inkludera';

  @override
  String get ideSearchFilesToExclude => 'Filer att utesluta';

  @override
  String get ideNoOpenTabs => 'Inga öppna flikar – använd + för att öppna';

  @override
  String get ideBrowserAddressHint => 'Ange adress eller sök';

  @override
  String get ideSimpleWebBrowser => 'Enkel webbläsare';

  @override
  String get ideWebBrowser => 'Webbläsare';

  @override
  String get ideBrowserEnterUrl =>
      'Ange en URL i adressfältet för att börja surfa';

  @override
  String get ideCodeServer => 'Redigerare';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return 'Spara ändringar i $fileName?';
  }

  @override
  String get ideUnsavedChangesBody =>
      'Dina ändringar går förlorade om du inte sparar dem.';

  @override
  String get ideDontSave => 'Spara inte';

  @override
  String get editorAutoSave => 'Spara automatiskt';

  @override
  String get editorAutoSaveDescription =>
      'Spara ändringar automatiskt i den inbäddade redigeraren.';

  @override
  String get editorAutoSaveOff => 'Av';

  @override
  String get editorAutoSaveAfterDelay => 'Efter en fördröjning';

  @override
  String get editorAutoSaveOnFocusChange => 'Vid fokusbyte';

  @override
  String get ideCodeServerUnavailable =>
      'Code-server saknas på den här servern';

  @override
  String get ideCodeServerUnavailableHint =>
      'Installera code-server (coder/code-server) på servervärden och öppna sedan redigeraren igen.';

  @override
  String get ideCodeServerInstalling => 'Förbereder redigerare…';

  @override
  String get ideCodeServerOpenInBrowser => 'Öppna redigerare i webbläsaren';

  @override
  String get ideCodeServerError => 'Kunde inte öppna redigeraren';

  @override
  String get paneSuspendedCaption =>
      'Vilande för att spara resurser – den läses in igen när den får fokus';

  @override
  String get ideFolderLoadFailed => 'Kunde inte läsa in den här mappen';

  @override
  String get ideFileSearchFailed => 'Kunde inte söka i filer';

  @override
  String get ideSearchInFiles => 'Sök i filer';

  @override
  String get ideNoContentMatches => 'Inga träffar';

  @override
  String get ideSourceControlCreatePr => 'Skapa pull request';

  @override
  String ideSourceControlViewPr(int number) {
    return 'Visa pull request #$number';
  }

  @override
  String get ideSourceControlNoChanges => 'Inga ändringar';

  @override
  String get noReposInConversation => 'Inga arkiv i det här samtalet';

  @override
  String get ideSourceControlNoSpace =>
      'Öppna ett samtal för att se dess ändringar';

  @override
  String get ideFileLoading => 'Läser in…';

  @override
  String get ideFileBinary => 'Binärfil';

  @override
  String get mcpExternalServers => 'Externa MCP-servrar';

  @override
  String get mcpExternalServersDescription =>
      'Anslut till externa MCP-servrar (GitHub, Sentry, Postgres, webbläsarautomatisering). Servrar du konfigurerat för Claude, Cursor, VS Code och andra verktyg upptäcks automatiskt.';

  @override
  String get mcpApprovalMode => 'Verktygsgodkännande';

  @override
  String get mcpApprovalModeDescription =>
      'Vilka verktygsåtgärder som körs utan att fråga. Läsningar tillåts alltid; högre nivåer frågar.';

  @override
  String get mcpApprovalAlwaysAsk => 'Fråga alltid';

  @override
  String get mcpApprovalWrite => 'Godkänn skrivningar automatiskt';

  @override
  String get mcpApprovalYolo => 'Godkänn allt automatiskt';

  @override
  String get mcpNoExternalServers => 'Inga externa MCP-servrar hittades.';

  @override
  String get mcpAuthorize => 'Auktorisera';

  @override
  String get mcpReconnect => 'Återanslut';

  @override
  String get mcpExternalConnectionsNote =>
      'Externa MCP-servrar körs på agentservern (delad av skrivbord och webb). Att auktorisera OAuth-servrar finns bara på skrivbordet.';

  @override
  String get mcpStatusConnected => 'Ansluten';

  @override
  String get mcpStatusConnecting => 'Ansluter…';

  @override
  String get mcpStatusNeedsAuth => 'Behöver auktorisering';

  @override
  String get mcpStatusFailed => 'Misslyckades';

  @override
  String get mcpStatusCircuitOpen => 'Pausad';

  @override
  String get mcpStatusDisabled => 'Inaktiverad';

  @override
  String get providersAndModels => 'Leverantörer och modeller';

  @override
  String get providersAndModelsDescription =>
      'Lista varje leverantör den inbyggda agenten kan använda – ange en API-nyckel eller logga in med webbläsaren, se varje ansluten leverantörs modeller och priser och styr vilka leverantörer den här arbetsytan får använda.';

  @override
  String get syncNow => 'Synka nu';

  @override
  String syncNowResult(int applied, int failed) {
    return 'Synk klar – $applied tillämpade, $failed misslyckades';
  }

  @override
  String syncNowFailed(String error) {
    return 'Synken misslyckades: $error';
  }

  @override
  String get denied => 'Nekad';

  @override
  String get allowed => 'Tillåten';

  @override
  String allowProviderSemantic(String provider) {
    return 'Tillåt $provider';
  }

  @override
  String enabledViaEnv(String key) {
    return 'Aktiverad via $key';
  }

  @override
  String costPerMillion(String input, String output) {
    return '$input / $output per 1M';
  }

  @override
  String contextTokens(String tokens) {
    return '$tokens kontext';
  }

  @override
  String get usageAndCost => 'Användning och kostnad';

  @override
  String get usageAndCostDescription =>
      'Utgifter över dina agenter de senaste 7 dagarna, från observerade körningskostnader.';

  @override
  String get noUsageYet => 'Ingen användning registrerad ännu.';

  @override
  String get spentThisWeek => 'spenderat den här veckan';

  @override
  String get subscriptionUsage => 'Prenumerationsanvändning';

  @override
  String get subscriptionUsageUnavailable => 'Otillgänglig';

  @override
  String get subscriptionUsageExhausted => 'Kvoten är slut';

  @override
  String get subscriptionUsageSignInRequired => 'Logga in igen';

  @override
  String get subscriptionUsageSignInExpired =>
      'Inloggningen har gått ut, förnyas vid nästa körning';

  @override
  String get subscriptionUsagePartiallyAvailable => 'Delvis tillgänglig';

  @override
  String resetsIn(String duration) {
    return 'Återställs om $duration';
  }

  @override
  String get feedbackHelpful => 'Det här var hjälpsamt';

  @override
  String get feedbackNotHelpful => 'Det här var inte hjälpsamt';

  @override
  String get modeChat => 'Chatt';

  @override
  String get modePlan => 'Plan';

  @override
  String get modeReview => 'Granskning';

  @override
  String get modeOrchestrate => 'Orkestrera';

  @override
  String get editorTheme => 'Redigerartema';

  @override
  String get editorThemeDescription =>
      'Importera ett VS Code-färgtema så att den inbäddade diffen och redigeraren matchar din IDE.';

  @override
  String get editorThemePasteHint =>
      'Klistra in innehållet i en VS Code-färgtema-JSON-fil';

  @override
  String get editorThemeImported => 'Tema importerat';

  @override
  String get editorThemeInvalid =>
      'Det ser inte ut som ett giltigt VS Code-tema';

  @override
  String get importTheme => 'Importera tema';

  @override
  String get clearTheme => 'Rensa tema';

  @override
  String get openInDiffViewer => 'Öppna i diffvisaren';

  @override
  String get shellCommand => 'Kommando';

  @override
  String get shellOutput => 'Utdata';

  @override
  String get revertToHere => 'Återställ hit';

  @override
  String get revertConfirmBody =>
      'Dölj meddelandena efter den här punkten och rulla tillbaka agentens filändringar till den här turen? Du kan ångra det här.';

  @override
  String get revert => 'Återställ';

  @override
  String get revertedToHere => 'Återställd hit';

  @override
  String get nothingToRevert => 'Inget att återställa';

  @override
  String get undoRevert => 'Ångra återställning';

  @override
  String get revertUndone => 'Återställning ångrad';

  @override
  String get systemBehavior => 'Systembeteende';

  @override
  String get keepAwakeTitle => 'Håll datorn vaken medan agenter körs';

  @override
  String get keepAwakeOnSubtitle => 'Datorn sover inte medan en agent arbetar';

  @override
  String get keepAwakeOffSubtitle =>
      'Datorn kan somna även medan en agent arbetar';

  @override
  String get syncEngineSectionTitle => 'Synkmotor';

  @override
  String get syncEngineDescription =>
      'Ärenden, meddelanden och anteckningar uppdateras live via små inkrementella ändringar i stället för hela ögonblicksbilder. Att slå av en växel faller det lagret tillbaka till ögonblicksbildsläge – läs in appen igen för att ändringen ska gälla.';

  @override
  String get syncEngineTicketsTitle => 'Ärenden';

  @override
  String get syncEngineMessagingTitle => 'Meddelanden';

  @override
  String get syncEngineNotesTitle => 'Anteckningar';

  @override
  String get syncEngineOnSubtitle => 'Live deltasynk är aktiv';

  @override
  String get syncEngineOffSubtitle => 'Använder synk med hela ögonblicksbilder';

  @override
  String get spaces => 'Ytor';

  @override
  String get spacesHomeDescription =>
      'Välj en yta från listan, eller starta en ny.';

  @override
  String get noSpacesYet => 'Inga ytor ännu';

  @override
  String get newSpace => 'Ny yta';

  @override
  String get spaceName => 'Ytnamn';

  @override
  String get spaceReposHint => 'Arkiv att ta med';

  @override
  String get ideSourceControl => 'Källkontroll';

  @override
  String get stagedChanges => 'Stagade ändringar';

  @override
  String get changes => 'Ändringar';

  @override
  String get stageFile => 'Staga';

  @override
  String get unstageFile => 'Avstaga';

  @override
  String get stageAll => 'Staga alla ändringar';

  @override
  String get unstageAll => 'Avstaga alla';

  @override
  String get stageChangesToCommit => 'Staga ändringar för commit';

  @override
  String get syncToPrHead => 'Hämta senaste PR-commits';

  @override
  String get syncedToPrHead => 'Synkad till de senaste PR-commits';

  @override
  String get syncPrHeadDirty =>
      'Committa eller kasta dina ändringar innan du synkar';

  @override
  String get syncPrHeadFailed => 'Kunde inte synka till PR-huvudet';

  @override
  String get spaceLabel => 'Yta';

  @override
  String get keybindingNewSpace => 'Ny yta';

  @override
  String get keybindingCreateANewSpaceDescription => 'Skapa en ny yta';

  @override
  String get jumpToLatest => 'Hoppa till senaste';

  @override
  String get streaming => 'Strömmar';

  @override
  String get newMessages => 'Nya';

  @override
  String get copyLink => 'Kopiera länk';

  @override
  String get linkCopied => 'Länk kopierad';

  @override
  String get agentResponding => 'Agenten svarar';

  @override
  String get agentFinished => 'Agenten är klar';

  @override
  String get harnessConnectProviderForModels =>
      'Anslut en leverantör för att se modeller.';

  @override
  String get providerSignOut => 'Logga ut';

  @override
  String get providerWaitingForDeviceCode =>
      'Väntar på att du ska bekräfta koden i webbläsaren…';

  @override
  String get providerDeviceCodeHint =>
      'Kontrollera att den här koden stämmer med den som visas i webbläsaren, och godkänn sedan.';

  @override
  String get providerPlanUsageLoading => 'Kontrollerar plananvändning…';

  @override
  String get providerPlanUsageUnavailable =>
      'Den här planen rapporterade ingen användning.';

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return 'Ta bort $provider-API-nyckeln?';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return 'Den lagrade nyckeln tas bort och kan inte visas igen. Agenter som använder $provider-modeller slutar fungera tills du klistrar in en ny.';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return 'Ta bort $provider?';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return '$provider och dess lagrade nyckel tas bort. Agenter knutna till dess modeller slutar fungera.';
  }

  @override
  String get providerApiKeyHint => 'Klistra in en API-nyckel';

  @override
  String get providerApiKeyStoredHint =>
      'Klistra in en annan API-nyckel för att lägga till den';

  @override
  String get providerAddAnotherAccount => 'Lägg till ett annat konto';

  @override
  String get providerActiveBadge => 'Aktiv';

  @override
  String get providerOauthAccountFallback => 'OAuth-konto';

  @override
  String get providerApiKeyFallback => 'API-nyckel';

  @override
  String get providerRemoveCredentialConfirmTitle =>
      'Ta bort de här inloggningsuppgifterna?';

  @override
  String get providerSignOutAccountConfirmTitle =>
      'Logga ut från det här kontot?';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return 'Agenter som använder $provider faller tillbaka till dess andra nycklar och konton. Utan några kvar slutar de tills du lägger till en.';
  }

  @override
  String get providerBaseUrlHint => 'Bas-URL (valfritt)';

  @override
  String get addProvider => 'Lägg till leverantör';

  @override
  String get noCustomProviders => 'Inga egna leverantörer ännu.';

  @override
  String get providerNameLabel => 'Namn';

  @override
  String get apiTypeLabel => 'API-typ';

  @override
  String get providerBaseUrlLabel => 'Bas-URL';

  @override
  String get providerApiKeyOptionalHint => 'API-nyckel (valfritt)';

  @override
  String get dialectOpenAiCompatible => 'OpenAI-kompatibel';

  @override
  String get dialectAnthropicCompatible => 'Anthropic-kompatibel';

  @override
  String get removeProviderTooltip => 'Ta bort leverantör';

  @override
  String get providerLogInWithBrowser => 'Logga in med webbläsare';

  @override
  String providerLoginDialogTitle(String provider) {
    return 'Logga in på $provider';
  }

  @override
  String get providerLabel => 'Leverantör';

  @override
  String get selectProviderToLogin => 'Välj en leverantör att logga in på';

  @override
  String providerLoginFailed(String error) {
    return 'Inloggningen misslyckades: $error';
  }

  @override
  String get providerWaitingForBrowser =>
      'Väntar på att du ska auktorisera i webbläsaren…';

  @override
  String get providerPasteCodeHint => 'Eller klistra in koden från webbläsaren';

  @override
  String get providerCompleteLogin => 'Slutför';

  @override
  String get providerConnectedApiKey => 'Ansluten via API-nyckel';

  @override
  String get providerConnectedOauth => 'Ansluten';

  @override
  String providerConnectedAccount(String account) {
    return 'Ansluten · $account';
  }

  @override
  String get providerLocalReady => 'Lokal · redo';

  @override
  String get providerNotConnected => 'Inte ansluten';

  @override
  String get preparingWorkspace => 'Förbereder arbetsyta…';

  @override
  String provisioningRunningSetupScript(String repo) {
    return 'Kör setup-skriptet för $repo…';
  }

  @override
  String get repoScriptsTitle => 'Skript';

  @override
  String get repoScriptsTooltip => 'Konfigurera livscykelskript';

  @override
  String get repoScriptsSetupLabel => 'Setup-skript';

  @override
  String get repoScriptsSetupHelp =>
      'Körs i ytans worktree direkt efter att det skapats – installera beroenden, generera filer. Ett fel markerar ytan som misslyckad; försök igen kör det på nytt.';

  @override
  String get repoScriptsArchiveLabel => 'Arkivskript';

  @override
  String get repoScriptsArchiveHelp =>
      'Körs just innan en ytas worktree tas bort – städa upp resurser utanför worktree. Ett fel blockerar aldrig borttagning.';

  @override
  String get repoScriptsEnvHelp =>
      'Körs via bash från worktree, med CC_WORKSPACE_PATH (worktree), CC_ROOT_PATH (arkivroten), CC_SPACE_ID, CC_SPACE_NAME och CC_REPO_NAME satta.';

  @override
  String get repoScriptsSetupPlaceholder => 't.ex. pnpm install';

  @override
  String get repoScriptsArchivePlaceholder =>
      't.ex. docker compose -p \$CC_SPACE_ID down';

  @override
  String get repoScriptsRecentRuns => 'Senaste körningar';

  @override
  String get repoScriptsNoRuns => 'Inga körningar ännu';

  @override
  String get repoScriptsSaved => 'Skripten sparades';

  @override
  String get repoScriptsRunKindSetup => 'Setup';

  @override
  String get repoScriptsRunKindArchive => 'Arkiv';

  @override
  String get repoScriptsRunStatusRunning => 'Körs';

  @override
  String get repoScriptsRunStatusSucceeded => 'Lyckades';

  @override
  String get repoScriptsRunStatusFailed => 'Misslyckades';

  @override
  String get repoScriptsRunStatusTimedOut => 'Timeout';

  @override
  String repoScriptsExitCode(int code) {
    return 'Avslutskod $code';
  }

  @override
  String provisioningCloningRepo(String repo) {
    return 'Klonar $repo…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return 'Checkar ut pull request i $repo…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return 'Ställer in agent $agent…';
  }

  @override
  String get workspacePrepFailed => 'Förberedelse av arbetsyta misslyckades';

  @override
  String get workspacePrepStopped => 'Förberedelse av arbetsyta stoppad';

  @override
  String get stopWorkspacePrep => 'Stoppa förberedelse';

  @override
  String get stopWorkspacePrepTooltip =>
      'Stoppa förberedelsen av den här arbetsytan';

  @override
  String get stopWorkspacePrepConfirm =>
      'Stoppa förberedelsen av den här arbetsytan? Kloningen som pågår kastas – du kan starta den igen härifrån.';

  @override
  String messageWillSendWhenReady(int count) {
    return '$count meddelande(n) skickas när det är redo';
  }

  @override
  String get membersNav => 'Medlemmar';

  @override
  String get membersSettingsDescription =>
      'Personer med åtkomst till den här arbetsytan: lista, inbjudningar och granskningskedja';

  @override
  String get memberRosterLabel => 'Medlemslista';

  @override
  String get memberRepoAccessAction => 'Arkivåtkomst';

  @override
  String memberRepoAccessTitle(String name) {
    return 'Arkivåtkomst för $name';
  }

  @override
  String get roleOwner => 'Ägare';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleMember => 'Medlem';

  @override
  String get roleViewer => 'Visare';

  @override
  String get roleGuest => 'Gäst';

  @override
  String get removeMemberTitle => 'Ta bort medlem';

  @override
  String removeMemberConfirm(String name) {
    return 'Ta bort $name från den här arbetsytan? De förlorar åtkomsten omedelbart.';
  }

  @override
  String get transferOwnershipAction => 'Överför ägarskap';

  @override
  String get transferOwnershipTitle => 'Överför ägarskap';

  @override
  String transferOwnershipConfirm(String name) {
    return 'Gör $name till ägare av den här arbetsytan? Du blir admin. Bara en ägare kan ta bort arbetsytan eller ändra en annan admins roll.';
  }

  @override
  String get transferOwnershipCta => 'Överför';

  @override
  String get auditTrailLabel => 'Auktoriseringsgranskningskedja';

  @override
  String get auditTrailDescription =>
      'Varje tillåtelse och avslag, hashkedjad så att en ändrad eller borttagen post går att upptäcka.';

  @override
  String get auditVerifyChain => 'Verifiera kedja';

  @override
  String auditChainIntact(int count) {
    return 'Kedjan är intakt – $count poster verifierade';
  }

  @override
  String auditChainBroken(int seq, String reason) {
    return 'Kedjan bruten vid post $seq: $reason';
  }

  @override
  String get auditEmpty => 'Inga beslut registrerade ännu.';

  @override
  String get auditDenied => 'Nekad';

  @override
  String get auditAllowed => 'Tillåten';

  @override
  String auditOnBehalfOf(String user) {
    return 'för $user';
  }

  @override
  String get policyTemplatesLabel => 'Policymallar';

  @override
  String get policyTemplatesDescription =>
      'Tillämpa en startställning, eller flytta en mellan arbetsytor.';

  @override
  String get policyTemplateStrict => 'Strikt';

  @override
  String get policyTemplateBalanced => 'Balanserad';

  @override
  String get policyTemplatePermissive => 'Tillåtande';

  @override
  String get policyTemplateApply => 'Tillämpa';

  @override
  String policyTemplateApplied(int count) {
    return 'Tillämpade $count regler';
  }

  @override
  String get policyExport => 'Kopiera policy';

  @override
  String get policyExported => 'Policy kopierad till urklipp';

  @override
  String get policyImport => 'Klistra in policy';

  @override
  String policyImported(int count) {
    return 'Importerade $count regler';
  }

  @override
  String get approveAndRemember => 'Godkänn i 8 timmar';

  @override
  String get approveAndRememberTooltip =>
      'Godkänner den här åtgärden och slutar fråga om liknande i den här ytan i 8 timmar. Den går ut av sig själv.';

  @override
  String get unknownUserLabel => 'Okänd användare';

  @override
  String get inviteMember => 'Bjud in medlem';

  @override
  String get inviteRepoAccessHeader => 'Arkivåtkomst';

  @override
  String get inviteRepoAccessExplainer =>
      'Bara arkiven du kryssar i delas med den inbjudna, på den nivå du väljer. Allt annat förblir dolt.';

  @override
  String get grantLevelRead => 'Läs';

  @override
  String get grantLevelReview => 'Granska';

  @override
  String get grantLevelWrite => 'Skriv';

  @override
  String get inviteExpiryLabel => 'Går ut om';

  @override
  String get expiryOneDay => '1 dag';

  @override
  String get expirySevenDays => '7 dagar';

  @override
  String get expiryThirtyDays => '30 dagar';

  @override
  String get createInviteAction => 'Skapa inbjudan';

  @override
  String get inviteOneTimeCodeLabel => 'Engångskod';

  @override
  String get inviteCodeShownOnce =>
      'Den här koden visas bara en gång – kopiera den nu.';

  @override
  String get inviteLinkLabel => 'Inbjudningslänk';

  @override
  String get inviteRedeemHint =>
      'Dela koden med den inbjudna; de löser in den mot din server-URL.';

  @override
  String get inviteScanQr => 'Eller skanna för att lösa in';

  @override
  String get inviteLoopbackWarningTitle => 'Inbjudan pekar på en lokal adress';

  @override
  String get inviteLoopbackWarningBody =>
      'Medarbetare på andra maskiner kan inte nå den här servern. Starta en tunnel (Inställningar → Integrationer → Dela den här servern) eller bind till ditt nätverk så att användare utanför värden kan ansluta.';

  @override
  String get inviteStatusOpen => 'Öppen';

  @override
  String get inviteStatusUsed => 'Använd';

  @override
  String get inviteStatusRevoked => 'Återkallad';

  @override
  String get inviteStatusExpired => 'Utgången';

  @override
  String inviteCreatedTime(String time) {
    return 'Skapad $time';
  }

  @override
  String inviteExpiresOn(String date) {
    return 'går ut $date';
  }

  @override
  String get noActivityYet => 'Ingen aktivitet ännu';

  @override
  String get couldNotLoadMembers => 'Kunde inte läsa in medlemmar';

  @override
  String get couldNotLoadInvites => 'Kunde inte läsa in inbjudningar';

  @override
  String get couldNotLoadActivity => 'Kunde inte läsa in aktivitet';

  @override
  String get yourDevices => 'Dina enheter';

  @override
  String get yourDevicesDescription =>
      'Klienter parkopplade till ditt konto på den här servern.';

  @override
  String get noOwnDevices => 'Inga enheter är parkopplade till ditt konto ännu';

  @override
  String get renameDeviceTitle => 'Byt namn på enhet';

  @override
  String get revokeDeviceTitle => 'Återkalla enhet';

  @override
  String revokeDeviceConfirm(String label) {
    return 'Återkalla $label? Den kopplas från omedelbart och kan inte längre nå den här servern.';
  }

  @override
  String devicePairedTime(String time) {
    return 'Parkopplad $time';
  }

  @override
  String deviceLastSeenTime(String time) {
    return 'Sågs senast $time';
  }

  @override
  String get deviceNeverSeen => 'Aldrig ansluten';

  @override
  String get profileSectionLabel => 'Profil';

  @override
  String get profileSectionDescription =>
      'Hur du syns för kollegor och i git commit-författarskap.';

  @override
  String get displayNameLabel => 'Visningsnamn';

  @override
  String get emailLabel => 'E-post';

  @override
  String get gitAuthorNameLabel => 'Git-författarnamn';

  @override
  String get gitAuthorEmailLabel => 'E-post för git-författare';

  @override
  String get profileSaved => 'Profilen sparades';

  @override
  String get presenceOnline => 'Online';

  @override
  String get presenceIdle => 'Overksam';

  @override
  String get presenceTyping => 'Skriver…';

  @override
  String get presenceAgentThinking => 'Tänker';

  @override
  String get presenceAgentRunning => 'Körs';

  @override
  String get presenceAgentBlocked => 'Blockerad';

  @override
  String get presenceAgentDone => 'Klar';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String presenceNameStatusCost(String name, String status, String cost) {
    return '$name — $status ($cost)';
  }

  @override
  String get presenceRailLabel => 'Vem är online';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => 'Slå på stör ej';

  @override
  String get dndTooltipOff => 'Slå av stör ej';

  @override
  String get startPresenting => 'Börja presentera';

  @override
  String get stopPresenting => 'Sluta presentera';

  @override
  String spotlightPresentingBanner(String name) {
    return '$name presenterar';
  }

  @override
  String get spotlightLeave => 'Lämna';

  @override
  String typingIndicator(String name) {
    return '$name skriver…';
  }

  @override
  String get ideTabNotes => 'Anteckningar';

  @override
  String get ideSidebarAllViews => 'Alla vyer';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return 'Alla vyer ($count dolda)';
  }

  @override
  String get ideSidebarPinView => 'Fäst i sidofältet';

  @override
  String get ideSidebarUnpinView => 'Lossa från sidofältet';

  @override
  String get notesEmptyHint =>
      'Lägg till en anteckning för den som tar upp det här samtalet…';

  @override
  String get notesEditTooltip => 'Redigera anteckning';

  @override
  String notesUpdatedBy(String name, String time) {
    return 'Uppdaterad av $name · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '$name redigerar';
  }

  @override
  String get notesSaveFailed => 'Kunde inte spara anteckningen';

  @override
  String get reactionAddTooltip => 'Lägg till reaktion';

  @override
  String reactionToggleTooltip(String emoji) {
    return 'Reagera med $emoji';
  }

  @override
  String get autonomyDialLabel => 'Autonomi';

  @override
  String get autonomyProposeOnly => 'Bara föreslå';

  @override
  String get autonomyActWithApproval => 'Agera med godkännande';

  @override
  String get autonomyActFreely => 'Agera fritt';

  @override
  String get autonomyDefaultOption => 'Standard';

  @override
  String get checkerLabel => 'Kontrollant';

  @override
  String get checkerNone => 'Ingen';

  @override
  String get checkerCaption =>
      'Kontrollanten granskar andra agenters slutförda körningar.';

  @override
  String get takeoverTooltip => 'Ta över worktree';

  @override
  String get takeoverBannerSelf =>
      'Du har tagit över det här samtalets worktree';

  @override
  String takeoverBannerOther(String name) {
    return '$name har tagit över det här samtalets worktree';
  }

  @override
  String get handBackButton => 'Lämna tillbaka';

  @override
  String get handBackDialogTitle => 'Lämna tillbaka worktree';

  @override
  String get handBackDialogNoteHint => 'Valfri anteckning till agenten…';

  @override
  String takeoverFailed(String message) {
    return 'Kunde inte ta över: $message';
  }

  @override
  String handBackFailed(String message) {
    return 'Kunde inte lämna tillbaka: $message';
  }

  @override
  String get planStudioTitle => 'Plan Studio';

  @override
  String get plansTitle => 'Planer';

  @override
  String get plansSubtitle => 'Aktiva planer, plandokument och playbooks';

  @override
  String get plansActiveSection => 'Aktiva planer';

  @override
  String get plansDocumentsSection => 'Plandokument';

  @override
  String get plansPlaybooksSection => 'Playbooks';

  @override
  String get plansNoActive => 'Inga aktiva planer ännu.';

  @override
  String get plansNoDocuments => 'Inga plandokument ännu.';

  @override
  String get plansNoPlaybooks => 'Inga playbooks ännu.';

  @override
  String get planNotFound => 'Planen hittades inte.';

  @override
  String get planOpenInStudio => 'Öppna';

  @override
  String get planNodeTitle => 'Titel';

  @override
  String get planNodeDescription => 'Beskrivning';

  @override
  String get planNodeDescriptionHint => 'Vad det här steget ska göra…';

  @override
  String get planNodeApplyDescription => 'Tillämpa';

  @override
  String get planNodeRole => 'Roll';

  @override
  String get planNodeDependencies => 'Beror på';

  @override
  String get planNodeDependenciesHint => 'Lägg till ett beroende';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count beroenden',
      one: '1 beroende',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies =>
      'Inga beroenden, så det här körs så fort planen startar';

  @override
  String get planNodeOutputSchema => 'Utdataschema (JSON)';

  @override
  String get planNodeEstimate => 'Uppskattning';

  @override
  String get planNodeProvenance => 'Härkomst';

  @override
  String get planNodeAlreadyExecuted =>
      'Redan körd – redigering förgrenar planen härifrån.';

  @override
  String get planNewNodeTitle => 'Nytt steg';

  @override
  String get planEstimateNoHistory => 'Ingen historik ännu';

  @override
  String get planEstimateBlastUnknown => 'Spridningsradie: okänd';

  @override
  String get planEstimatePartial => 'delvis';

  @override
  String get planEstimateAction => 'Uppskatta';

  @override
  String planEstimateDuration(String range) {
    return 'Varaktighet $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return 'Spridningsradie: $files filer, $symbols symboler';
  }

  @override
  String get planApprove => 'Godkänn plan';

  @override
  String get planApproveSelectedNodes => 'Godkänn valda';

  @override
  String get planReject => 'Avvisa';

  @override
  String get planCancel => 'Avbryt körning';

  @override
  String get planContinueNode => 'Fortsätt nod';

  @override
  String get planTotalNotEstimated => 'Inte uppskattad ännu';

  @override
  String get planBudgetExceeded => 'över budget';

  @override
  String planBudgetCeiling(String amount) {
    return 'budget ≤ \$$amount';
  }

  @override
  String get planVersionsTitle => 'Versioner';

  @override
  String get planNoRevisions => 'Inga revisioner ännu.';

  @override
  String get planDiffIdentical => 'Inga ändringar.';

  @override
  String get planDiffGoalChanged => 'Målet ändrades';

  @override
  String get planDiffBudgetChanged => 'Budgeten ändrades';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'Ändringar från v$fromRev till v$toRev';
  }

  @override
  String planDiffAdded(String node) {
    return 'Lade till $node';
  }

  @override
  String planDiffRemoved(String node) {
    return 'Tog bort $node';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return 'Ändrade $node: $fields';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return 'Kant tillagd: $edge';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return 'Kant borttagen: $edge';
  }

  @override
  String planDiffRoleAdded(String role) {
    return 'Roll tillagd: $role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return 'Roll borttagen: $role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return 'Roll omfördelad: $role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return 'Planen omplanerad: du godkände v$approved, den är nu v$current. Granska diffen innan den fortsätter.';
  }

  @override
  String planLiveActualCost(String amount) {
    return 'Faktisk kostnad: \$$amount';
  }

  @override
  String get planPlaybookRun => 'Kör';

  @override
  String get planPlaybookDelete => 'Ta bort playbook';

  @override
  String get planPlaybookProposed =>
      'Plan föreslagen – godkänn den i Plan Studio.';

  @override
  String get planPlaybookAnchorTicket => 'Ankarärende';

  @override
  String get planPlaybookPickTicket => 'Välj ett ärende…';

  @override
  String get planPlaybookProposeRun => 'Föreslå plan';

  @override
  String get planPlaybookRepoHint => 'Ett arkiv-ID';

  @override
  String get planPlaybookAgentHint => 'Ett agent-ID';

  @override
  String planPlaybookRunTitle(String name) {
    return 'Kör $name';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '$count parametrar';
  }

  @override
  String get recentLabel => 'Senaste';

  @override
  String get cheatSheetTitle => 'Tangentbordsgenvägar';

  @override
  String get cheatSheetGlobal => 'Globalt';

  @override
  String get cheatSheetThisScreen => 'Den här skärmen';

  @override
  String get cheatSheetReservedInBrowser => 'Reserverat i webbläsaren';

  @override
  String get keybindingCheatSheet => 'Tangentbordsgenvägar';

  @override
  String get keybindingShowKeyboardShortcutsDescription =>
      'Visa genvägsöversikten för den aktuella skärmen';

  @override
  String get runPlaybookLabel => 'Kör playbook';

  @override
  String get playbooksLabel => 'Playbooks';

  @override
  String get keybindingUndo => 'Ångra';

  @override
  String get keybindingRedo => 'Gör om';

  @override
  String get keybindingUndoLastActionDescription =>
      'Ångra din senast reversibla åtgärd';

  @override
  String get keybindingRedoLastActionDescription =>
      'Gör om den senast ångrade åtgärden';

  @override
  String get undone => 'Ångrad';

  @override
  String get redone => 'Gjordes om';

  @override
  String get undoFailed => 'Kunde inte ångra';

  @override
  String get undoLabelTicketEdit => 'ärenderedigering';

  @override
  String get undoLabelMessageEdit => 'meddelanderedigering';

  @override
  String get undoLabelTodoStatus => 'att-göra-status';

  @override
  String get inboxTitle => 'Inkorg';

  @override
  String get inboxReview => 'Granska';

  @override
  String get inboxOpen => 'Öppna';

  @override
  String get inboxAllCaughtUp => 'Du är ikapp';

  @override
  String get inboxGitHubDownTitle => 'GitHub kan vara nere';

  @override
  String inboxGitHubDownBody(String status) {
    return 'GitHub rapporterar $status, så pull requests kan saknas i den här listan i stället för att faktiskt vara klara.';
  }

  @override
  String get inboxGitHubIdentityTitle =>
      'Kunde inte bekräfta ditt GitHub-konto';

  @override
  String get inboxGitHubIdentityBody =>
      'Inkorgen sorteras efter vem du är på GitHub. Tills det laddas förblir den tom, även när pull requests väntar på dig.';

  @override
  String get inboxSeverityBlocking => 'Blockerad';

  @override
  String get inboxSeverityWaiting => 'Väntar';

  @override
  String get inboxSeverityInfo => 'Info';

  @override
  String get inboxSyncFailed => 'Synken misslyckades';

  @override
  String get inboxNeedsYourAttention => 'Behöver din uppmärksamhet';

  @override
  String get inboxSectionNeedsYourReview => 'Behöver din granskning';

  @override
  String get inboxSectionReturnedToYou => 'Åter till dig';

  @override
  String get inboxSectionApproved => 'Godkända';

  @override
  String get inboxSectionDrafts => 'Utkast';

  @override
  String get inboxSectionWaitingForReviewers => 'Väntar på granskare';

  @override
  String get inboxSectionMergingAndMerged =>
      'Sammanslås och nyligen sammanslagna';

  @override
  String get inboxSectionWaitingForAuthor => 'Väntar på författare';

  @override
  String get inboxColumnTitle => 'Titel';

  @override
  String get inboxColumnChanges => 'Ändringar';

  @override
  String get inboxColumnUpdated => 'Uppdaterad';

  @override
  String get inboxReviewApproved => 'Godkänd';

  @override
  String get inboxReviewChangesRequested => 'Ändringar begärda';

  @override
  String get inboxHeroSubtitle =>
      'Varje pull request som rör dig, sorterad efter vad som händer härnäst.';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requests behöver din granskning',
      one: '1 pull request behöver din granskning',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tillbaka till dig',
      one: '1 tillbaka till dig',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted =>
      'Den ändringen sparades inte och ångrades';

  @override
  String get offlinePendingLabel => 'väntar';

  @override
  String get offlineSyncingLabel => 'synkar';

  @override
  String get copyLinkLabel => 'Kopiera länk till den här sidan';

  @override
  String get agentsSectionLabel => 'Agenter';

  @override
  String get fleetWorkersTitle => 'Workers';

  @override
  String get fleetWorkersSubtitle => 'Maskiner som kan köra jobb';

  @override
  String get fleetJobsTitle => 'Jobb';

  @override
  String get fleetJobsSubtitle => 'Arbete fördelat över flottan';

  @override
  String get fleetNoWorkers =>
      'Inga workers ännu – en andra maskin som kör `cc_worker --server <url>` ansluter till flottan.';

  @override
  String get fleetNoJobs => 'Inga jobb.';

  @override
  String get fleetError => 'Kunde inte läsa in flottan';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kärnor',
      one: '1 kärna',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return 'Heartbeat $time';
  }

  @override
  String get fleetNoHeartbeat => 'Ingen heartbeat ännu';

  @override
  String fleetLastErrorLabel(String error) {
    return 'Senaste fel: $error';
  }

  @override
  String get fleetDrain => 'Töm';

  @override
  String get fleetResume => 'Återuppta';

  @override
  String get fleetRevoke => 'Återkalla';

  @override
  String get fleetRemove => 'Ta bort';

  @override
  String get fleetRevokeTitle => 'Återkalla worker?';

  @override
  String fleetRevokeBody(String name) {
    return 'Återkalla $name? Dess session avslutas och aktiva jobb omfördelas.';
  }

  @override
  String get fleetRemoveTitle => 'Ta bort worker?';

  @override
  String fleetRemoveBody(String name) {
    return 'Ta bort $name från flottan? Det tar bort dess post.';
  }

  @override
  String get fleetActionFailed => 'Åtgärden misslyckades';

  @override
  String get fleetJobUnassigned => 'Ej tilldelad';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '$attempts/$max försök';
  }

  @override
  String get fleetPlacementReasons => 'Placeringsbeslut';

  @override
  String get fleetNoPlacements => 'Inga placeringsbeslut ännu.';

  @override
  String get fleetStatusOnline => 'Online';

  @override
  String get fleetStatusDraining => 'Töms';

  @override
  String get fleetStatusOffline => 'Offline';

  @override
  String get fleetStatusIncompatible => 'Inkompatibel';

  @override
  String get fleetStatusRevoked => 'Återkallad';

  @override
  String get fleetJobStatusQueued => 'I kö';

  @override
  String get fleetJobStatusRunning => 'Körs';

  @override
  String get fleetJobStatusSucceeded => 'Lyckades';

  @override
  String get fleetJobStatusFailed => 'Misslyckades';

  @override
  String get fleetJobStatusCancelled => 'Avbruten';

  @override
  String get evalsNoSuites => 'Inga eval-sviter ännu.';

  @override
  String get evalsError => 'Kunde inte läsa in evals';

  @override
  String get evalsStarterBadge => 'Start';

  @override
  String evalsDefaultBatch(int count) {
    return 'Standardbatch på $count';
  }

  @override
  String get evalsRecentRuns => 'Senaste körningar';

  @override
  String get evalsNoRuns => 'Inga körningar ännu.';

  @override
  String get evalsPassRate => 'Godkännandefrekvens';

  @override
  String evalsBatchTimes(int count) {
    return '× $count';
  }

  @override
  String evalsTriggeredBy(String who) {
    return 'av $who';
  }

  @override
  String evalsRunFinished(String rate) {
    return 'Eval klar – $rate godkända';
  }

  @override
  String get evalsRunFailed => 'Kunde inte köra sviten';

  @override
  String get evalsRun => 'Kör';

  @override
  String get evalsStatusQueued => 'I kö';

  @override
  String get evalsStatusRunning => 'Körs';

  @override
  String get evalsStatusPassed => 'Godkänd';

  @override
  String get evalsStatusFailed => 'Misslyckades';

  @override
  String get bannerMeetingJoin => 'Anslut';

  @override
  String get bannerMeetingRecordAndLink => 'Spela in och länka';

  @override
  String get bannerCalendarReconnect => 'Återanslut';

  @override
  String get bannerView => 'Visa';

  @override
  String get soundscapeTitle => 'Ljudlandskap';

  @override
  String get soundscapePlay => 'Spela';

  @override
  String get soundscapePause => 'Pausa';

  @override
  String get soundscapeMoodLabel => 'Stämning';

  @override
  String get soundscapeMoodFocus => 'Fokus';

  @override
  String get soundscapeMoodRelax => 'Avslappning';

  @override
  String get soundscapeMoodSleep => 'Sömn';

  @override
  String get soundscapeVolumeLabel => 'Volym';

  @override
  String get soundscapeTuneLabel => 'Ton';

  @override
  String get soundscapeTuneMellow => 'Mjuk';

  @override
  String get soundscapeTuneBright => 'Ljus';

  @override
  String get soundscapeTuneEnergetic => 'Energisk';

  @override
  String get soundscapeTuneSpacy => 'Rymlig';

  @override
  String get soundscapeTuneResetHint => 'Dubbeltryck för att återställa';

  @override
  String get soundscapeSceneLabel => 'Spelas nu';

  @override
  String get soundscapeSceneLoading => 'Stämmer in stämningen…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees°C';
  }

  @override
  String get soundscapeLocationLabel => 'Plats';

  @override
  String get soundscapeLocationDetecting => 'Upptäcker plats…';

  @override
  String get soundscapeLocationAutoNote =>
      'Platsen upptäcks automatiskt från den här arbetsytan.';

  @override
  String get soundscapeRefreshWeather => 'Uppdatera väder';

  @override
  String get soundscapeAutoStartLabel => 'Starta med fokusläge';

  @override
  String get soundscapeAutoStartDescription =>
      'Spela ett ljudlandskap automatiskt när du startar en fokussession.';

  @override
  String get soundscapeReturnToApp => 'Tillbaka till appen';

  @override
  String get soundscapePopOut => 'Poppa ut spelaren';

  @override
  String get discussion => 'Diskussion';

  @override
  String get chat => 'Chatt';

  @override
  String get saving => 'Sparar…';

  @override
  String get saved => 'Sparad';

  @override
  String get saveFailed => 'Kunde inte spara';

  @override
  String get commitAndPush => 'Committa och pusha';

  @override
  String get commit => 'Commit';

  @override
  String get commitAmend => 'Commit (amend)';

  @override
  String get commitAndSync => 'Committa och synka';

  @override
  String get committed => 'Committad';

  @override
  String get commitAmended => 'Commit amendad';

  @override
  String get commitFailed => 'Commit misslyckades';

  @override
  String get moreCommitActions => 'Fler commit-åtgärder';

  @override
  String get sourceControl => 'Källkontroll';

  @override
  String fixFindingTitle(String location) {
    return 'Åtgärda: $location';
  }

  @override
  String get openInEditor => 'Öppna i redigeraren';

  @override
  String get regexTesterTitle => 'Testa reguljärt uttryck';

  @override
  String get regexTesterHint => 'Skriv ett exempel';

  @override
  String get regexMatch => 'Träff';

  @override
  String get regexNoMatch => 'Ingen träff';

  @override
  String get regexInvalidPattern => 'Ogiltigt mönster';

  @override
  String get symbolLookupNone =>
      'Ingen definition i indexet eller den här pull requesten';

  @override
  String get symbolLookupInDiff => 'Hittades i den här pull requesten';

  @override
  String get symbolLookupFromBase =>
      'Från baskommando — den här PR:ns worktree är inte indexerad ännu';

  @override
  String get symbolImplementations => 'Implementationer';

  @override
  String symbolCallersCount(int count) {
    return '$count anropare';
  }

  @override
  String get commitMessageHint => 'Commit-meddelande';

  @override
  String get pushedToPr => 'Pushad till PR:en';

  @override
  String get pushFailed => 'Push misslyckades';

  @override
  String get reviewFindings => 'Fynd';

  @override
  String get treeLabel => 'Träd';

  @override
  String get toggleFileTree => 'Visa eller dölj filträdet';

  @override
  String get diffViewSettings => 'Inställningar för diffvy';

  @override
  String get splitViewLabel => 'Delad';

  @override
  String get unifiedViewLabel => 'Enhetlig';

  @override
  String get wrapLines => 'Bryt rader';

  @override
  String get shiftClickSelectRange => 'Shift-klick för att välja ett intervall';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filer',
      one: '1 fil',
    );
    return '$_temp0';
  }

  @override
  String prComplexityLoc(String loc) {
    return '$loc LOC';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return 'Liten PR – $files, ~$minutes min att granska';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return 'Medelstor PR – $files, avsätt ~$minutes min att granska';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return 'Stor PR – $files, överväg att dela innan granskning';
  }

  @override
  String get searchInFiles => 'Sök i filer';

  @override
  String get showFileList => 'Visa fillista';

  @override
  String get searchInFilesHintField => 'Sök i filer…';

  @override
  String get searchInFilesHint => 'Sök i pull requestens filer';

  @override
  String get searchInWholeRepo => 'Sök i hela arkivet';

  @override
  String get searchInThisPullRequest => 'Sök i den här pull requesten';

  @override
  String get searchNoResults => 'Inga resultat';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultat',
      one: '1 resultat',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files filer',
      one: '1 fil',
    );
    return '$_temp0 i $_temp1';
  }

  @override
  String get discardChangesTitle => 'Kasta ändringar?';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filer',
      one: '1 fil',
    );
    return 'Kasta $_temp0 till HEAD? Det går inte att ångra.';
  }

  @override
  String get discardAll => 'Kasta alla';

  @override
  String get discardFailed => 'Kunde inte kasta ändringar';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filer',
      one: '1 fil',
    );
    return 'Kastade $_temp0';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '$reverted filer',
      one: '1 fil',
    );
    return 'Kastade $_temp0; $skipped hoppades över (ospårade)';
  }

  @override
  String get prWorktreeUnavailable => 'Arbetsytan är inte redo';

  @override
  String get prWorktreeUnavailableHint =>
      'Förberedelsen av pull requestens filer misslyckades. Öppna pull requesten igen för att försöka.';

  @override
  String get timestampRelativeLabel => 'Relativ';

  @override
  String get timestampRawLabel => 'Tidsstämpel';

  @override
  String get copyTimestamp => 'Kopiera tidsstämpel';

  @override
  String get copiedTimestamp => 'Tidsstämpel kopierad';

  @override
  String get previewDeployment => 'Förhandsgranska driftsättning';

  @override
  String previewDeploymentTab(String site) {
    return 'Förhandsgranska: $site';
  }

  @override
  String get askForReview => 'Be om granskning…';

  @override
  String get closePrsConfirmTitle => 'Stäng pull requests?';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Stänga $count pull requests?',
      one: 'Stänga 1 pull request?',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Stängde $count pull requests',
      one: 'Stängde 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tilldelade $count pull requests',
      one: 'Tilldelade 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Begärde granskning på $count pull requests',
      one: 'Begärde granskning på 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count åtgärder misslyckades',
      one: '1 åtgärd misslyckades',
    );
    return '$_temp0';
  }

  @override
  String get diagram => 'Diagram';

  @override
  String get diagramViewSource => 'Visa källa';

  @override
  String get diagramHideSource => 'Dölj källa';

  @override
  String diagramPreviewUnavailable(String reason) {
    return 'Diagramförhandsgranskning otillgänglig ($reason)';
  }

  @override
  String get planUnavailable => 'Plan otillgänglig';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count steg',
      one: '1 steg',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => 'Godkänn och kör';

  @override
  String get planStatusDraft => 'Utkast';

  @override
  String get planStatusProposed => 'Plan';

  @override
  String get planStatusApproved => 'Plan godkänd';

  @override
  String get planStatusRejected => 'Plan avvisad';

  @override
  String get planStatusSuperseded => 'Plan ersatt';

  @override
  String planRevisionLabel(int revision) {
    return 'Revision $revision';
  }

  @override
  String get adapterEnforcementTitle => 'Vad den här adaptern verkställer';

  @override
  String get enforcementFiltersToolSurface => 'Control Center väljer verktygen';

  @override
  String get enforcementInterceptsToolCalls =>
      'Varje anrop grindas innan det körs';

  @override
  String get enforcementObservesCompletionContract =>
      'Körningen hålls till sitt leverabel';

  @override
  String get enforcementNativeToolsInterceptable =>
      'Körarens egna verktyg är synliga';

  @override
  String get enforcementInProcessToolsSandboxed =>
      'Verktyg i processen körs i sandlåda';

  @override
  String get enforcementYes => 'Ja';

  @override
  String get enforcementNo => 'Nej';

  @override
  String get adapterEnforcementCaveats => 'Förbehåll';

  @override
  String get enforcementSummaryModesEnforced => 'Lägen verkställda';

  @override
  String get enforcementSummaryModesNotEnforced => 'Lägen inte verkställda';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count förbehåll',
      one: '1 förbehåll',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      'Skrivskyddade lägen är inte strukturella: Control Center kan inte ta bort den här körarens egna verktyg.';

  @override
  String get caveatToolCallsNotIntercepted =>
      'Ingen grind före körning: bara MCP-verktygsanrop går genom Control Center.';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      'Körarens egna fil- och skalverktyg når aldrig Control Center; OS-sandlådan är det enda golvet under dem.';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      'Filverktyg i processen körs utanför sandlådan, så verktygsytan är den enda filsystemsgränsen.';

  @override
  String get caveatCompletionContractUnobservable =>
      'Control Center kan inte puffa eller fälla en körning som slutar utan att producera sitt leverabel.';

  @override
  String get modeDegraded => 'Försämrad';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return '$mode-läge på $adapter förlitar sig bara på sandlådan; agentens egna filverktyg fångas inte.';
  }

  @override
  String get artifactUnavailable => 'Artefakt otillgänglig';

  @override
  String artifactRevisionLabel(int count) {
    return '$count revisioner';
  }

  @override
  String get artifactShowMore => 'Visa mer';

  @override
  String get artifactShowLess => 'Visa mindre';

  @override
  String get artifactCopy => 'Kopiera';

  @override
  String get artifactCopied => 'Artefakt kopierad';

  @override
  String get artifactsTabLabel => 'Artefakter';

  @override
  String get artifactsEmptyTitle => 'Inga artefakter ännu';

  @override
  String get artifactsEmptyBody =>
      'När en agent publicerar en tabell, ett diagram eller en figur här visas den i den här listan.';

  @override
  String get artifactRevisionPickerLabel => 'Revision';

  @override
  String get artifactRestoreRevision => 'Återställ den här revisionen';

  @override
  String get artifactOpenInTab => 'Öppna i flik';

  @override
  String get artifactTitleFallback => 'Artefakt';

  @override
  String get providerGenerationLabel => 'Genereringsstandard';

  @override
  String get providerGenerationHint =>
      'Lämna ett fält tomt för att använda endpointens egen standard. Modeller publicerar egna utdatatak och samplingrecept; att servera en vid andra värden kan försämra den.';

  @override
  String get providerMaxTokensLabel => 'Max utdata-tokens';

  @override
  String get addModel => 'Lägg till modell';

  @override
  String get modelListTitle => 'Modellista';

  @override
  String get railProvidersGroup => 'Leverantörer';

  @override
  String get railCustomProvidersGroup => 'Egna leverantörer';

  @override
  String get editModelSettings => 'Redigera modellinställningar';

  @override
  String get modelIdLabel => 'Modell-ID';

  @override
  String get modelIdImmutableHint =>
      'ID:t som endpointen serverar; fast när den är listad.';

  @override
  String get contextWindowLabel => 'Kontextfönster';

  @override
  String get inputTypesLabel => 'Indatatyper';

  @override
  String get outputTypesLabel => 'Utdatatyper';

  @override
  String get modalityText => 'Text';

  @override
  String get modalityImage => 'Bild';

  @override
  String get modalityAudio => 'Ljud';

  @override
  String get modalityVideo => 'Video';

  @override
  String get modalityPdf => 'PDF';

  @override
  String get modelOverrideReset => 'Återställ till automatisk';

  @override
  String get modelOverrideEdited => 'Redigerad';

  @override
  String get manualModelBadge => 'Tillagd för hand';

  @override
  String get modelIdRequired => 'Ange ett modell-ID.';

  @override
  String get modelTokensInvalid => 'Ange ett positivt heltal tokens.';

  @override
  String get removeModelAction => 'Ta bort modell';

  @override
  String removeModelConfirmTitle(String model) {
    return 'Ta bort $model?';
  }

  @override
  String get removeModelConfirmBody =>
      'Modellen lämnar listan och agenter knutna till den slutar fungera. Leverantören påverkas inte.';

  @override
  String get addModelProviderTitle => 'Lägg till modellleverantör';

  @override
  String get addModelProviderDescription =>
      'Konfigurera en egen API-endpoint och dess modeller.';

  @override
  String get modelListEmptyHint =>
      'Inga modeller konfigurerade. Lägg till en modell för att använda den i chatten.';

  @override
  String get addProviderModelsHint =>
      'Modeller hämtas live när endpointen svarar. Lägg till en för hand bara om den inte kan lista sina egna.';

  @override
  String get providerTemperatureLabel => 'Temperatur';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved => 'Genereringsstandard sparad';

  @override
  String get providerGenerationInvalid =>
      'Kontrollera värdena: max utdata-tokens och top-k måste vara positiva, temperatur 0–2, top-p 0–1.';

  @override
  String get providerGenerationOverridden => 'Åsidosatt';

  @override
  String get branchNotPushed => 'inte pushad';

  @override
  String branchNotOnRemote(String branch) {
    return '“$branch” finns bara i det här samtalet';
  }

  @override
  String get branchNotOnRemoteHint =>
      'GitHub har aldrig sett den här grenen, så en pull request kan inte använda den ännu. Publicering pushar commits som redan finns i worktree – osparade ändringar lämnas orörda.';

  @override
  String get publishBranch => 'Publicera gren';

  @override
  String branchPublished(String branch) {
    return 'Publicerade “$branch” till origin';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return 'Grenen publicerades. $count osparade ändring(ar) togs inte med.';
  }

  @override
  String get composePrLoadingBranches => 'Läser in grenar från GitHub…';

  @override
  String get composePrBranchesFailed =>
      'Kunde inte läsa in grenar från GitHub. Skriv ett grenamn, eller kontrollera GitHub-anslutningen.';

  @override
  String get composePrSubtitleFromSpace =>
      'Från det här samtalets gren – publicera den först om GitHub inte har sett den';

  @override
  String get obsTabInsights => 'Insikter';

  @override
  String get obsTabLive => 'Live';

  @override
  String get obsTabQuality => 'Kvalitet';

  @override
  String get obsTabUsage => 'Användning';

  @override
  String get obsUsageTotalTokens => 'Totalt tokens';

  @override
  String get obsUsagePeakTokens => 'Maxtokens';

  @override
  String get obsUsageLongestSession => 'Längsta session';

  @override
  String get obsUsageCurrentStreak => 'Aktuell svit';

  @override
  String get obsUsageLongestStreak => 'Längsta svit';

  @override
  String obsUsageDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagar',
      one: '1 dag',
      zero: '0 dagar',
    );
    return '$_temp0';
  }

  @override
  String get obsUsageTokenActivity => 'Tokenaktivitet';

  @override
  String get obsUsageActivityModeLabel => 'Läge för tokenaktivitet';

  @override
  String get obsUsageModeDaily => 'Daglig';

  @override
  String get obsUsageModeWeekly => 'Veckovis';

  @override
  String get obsUsageModeCumulative => 'Kumulativ';

  @override
  String get obsUsageTimeRange => 'Tidsintervall';

  @override
  String get obsUsageTrendTitle => 'Daglig tokentrend';

  @override
  String get obsUsageModelUsage => 'Modellanvändning';

  @override
  String get obsUsageTokensLabel => 'tokens';

  @override
  String get obsUsageNoActivity => 'Ingen tokenanvändning registrerad ännu';

  @override
  String get obsUsageOtherModels => 'Övriga';

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
    return 'Tokenaktivitet från $start till $end. $activeDays aktiva dagar. Mest aktiv dag $peak tokens.';
  }

  @override
  String get obsScreenSubtitle =>
      'Live agentstyrning, kostnadsattribution, kvoter och kvalitetssignaler';

  @override
  String get obsRangeLast24h => 'Senaste 24 timmarna';

  @override
  String get obsRangeLast7d => 'Senaste 7 dagarna';

  @override
  String get obsRangeLast30d => 'Senaste 30 dagarna';

  @override
  String get obsRangeAll => 'All tid';

  @override
  String get obsAddFilter => 'Lägg till filter';

  @override
  String get obsFilterAgent => 'Agent';

  @override
  String get obsFilterModel => 'Modell';

  @override
  String get obsFilterStatus => 'Status';

  @override
  String get obsFilterRole => 'Roll';

  @override
  String get obsKpiTotalRuns => 'Totalt körningar';

  @override
  String get obsKpiTotalCost => 'Total kostnad';

  @override
  String get obsKpiErrorRate => 'Felfrekvens';

  @override
  String get obsKpiCacheRate => 'Cachefrekvens';

  @override
  String get obsKpiTokensPerSec => 'Tokens / s';

  @override
  String get obsKpiAvgLatency => 'Snittlatens';

  @override
  String get obsKpiTtft => 'Tid till första token';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '$delta mot föregående period';
  }

  @override
  String get obsChartActivity => 'Aktivitet';

  @override
  String get obsChartCost => 'Kostnad över tid';

  @override
  String get obsLegendRuns => 'Körningar';

  @override
  String get obsLegendErrors => 'Fel';

  @override
  String get obsAgentsTitle => 'Agenter';

  @override
  String obsShowAllAgents(int count) {
    return 'Visa alla $count agenter';
  }

  @override
  String get obsShowFewerAgents => 'Visa färre';

  @override
  String get obsRunsTitle => 'Körningar';

  @override
  String get obsNoRunsInRange => 'Inga körningar i det här intervallet';

  @override
  String get obsColTime => 'Tid';

  @override
  String get obsColAgent => 'Agent';

  @override
  String get obsColStatus => 'Status';

  @override
  String get obsColModel => 'Modell';

  @override
  String get obsColDuration => 'Varaktighet';

  @override
  String get obsColTokens => 'Tokens';

  @override
  String get obsColCost => 'Kostnad';

  @override
  String get obsColErrors => 'Fel';

  @override
  String get obsColRuns => 'Körningar';

  @override
  String get obsColAvgLatency => 'Snittlatens';

  @override
  String get obsColLastActive => 'Senast aktiv';

  @override
  String get obsStatusPending => 'Väntar';

  @override
  String get obsStatusRunning => 'Körs';

  @override
  String get obsStatusCompleted => 'Slutförd';

  @override
  String get obsStatusError => 'Fel';

  @override
  String get obsRosterLoadError => 'Kunde inte läsa in agentlistan.';

  @override
  String get obsRosterEmpty => 'Inga agenter ännu';

  @override
  String get obsRosterEmptyDescription =>
      'Skicka ut en agent så syns den här live – status, aktuellt verktyg, tokens, kostnad.';

  @override
  String get obsKillAgent => 'Avsluta agent';

  @override
  String get obsRosterTokensLabel => 'tok';

  @override
  String get obsCostByRoleTitle => 'Kostnad per roll';

  @override
  String get obsCostByRoleSubtitle =>
      'Var den här arbetsytan spenderar, per agentroll';

  @override
  String get obsRoleMain => 'Huvud';

  @override
  String get obsRoleSubagents => 'Subagenter';

  @override
  String get obsRoleAdvisor => 'Rådgivare';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return 'Huvud: $main · subagenter: $sub · rådgivare: $advisor';
  }

  @override
  String get obsTotal => 'Totalt';

  @override
  String get obsTokenModelTitle => 'Tokenmodell (5 axlar)';

  @override
  String get obsTokenModelSubtitle =>
      'Varje token den här arbetsytan har spenderat, per axel';

  @override
  String get obsAxisInput => 'Indata';

  @override
  String get obsAxisOutput => 'Utdata';

  @override
  String get obsAxisReasoning => 'Resonemang';

  @override
  String get obsAxisCacheRead => 'Cache-läsning';

  @override
  String get obsAxisCacheWrite => 'Cache-skrivning';

  @override
  String get obsTotalTokens => 'Totalt tokens';

  @override
  String get obsCacheDiscountNote =>
      'Cache-lästa tokens faktureras till rabatt, så de kostar mycket mindre än samma volym ny indata.';

  @override
  String get obsByModelTitle => 'Per modell';

  @override
  String get obsByModelSubtitle => 'Token- och kostnadsanvändning per modell';

  @override
  String get obsNoModelUsage => 'Ingen modellanvändning registrerad ännu.';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count körningar',
      one: '1 körning',
    );
    return '$_temp0';
  }

  @override
  String get obsPerRunTitle => 'Per körning';

  @override
  String get obsPerRunSubtitle => 'Typisk tokenkostnad för en enda körning';

  @override
  String get obsMedianRunTokens => 'Median tokens per körning';

  @override
  String get obsMedianRunTokensSub => 'Mittpunkt över alla körningar';

  @override
  String get obsRunsInWorkspace => 'I den här arbetsytan';

  @override
  String get obsCostShare => 'Kostnadsandel';

  @override
  String get obsQuotaConfiguredLimits => 'Konfigurerade gränser';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      'Användning mot taken du satt, sämsta status först.';

  @override
  String get obsQuotaAddLimit => 'Lägg till gräns';

  @override
  String get obsQuotaNoLimits =>
      'Inga kvotgränser konfigurerade ännu – lägg till en för att följa användning mot ett tak.';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return 'Ta bort $title-gräns';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return 'Återställs om $duration · $status';
  }

  @override
  String get obsQuotaUsageWindows => 'Användningsfönster';

  @override
  String get obsQuotaUsageWindowsSubtitle =>
      'Observerad användning över alla leverantörer, inget tak tillämpat.';

  @override
  String get obsQuotaNoUsage => 'Ingen användning registrerad ännu.';

  @override
  String get obsQuotaTokensUsed => 'Tokens använda';

  @override
  String get obsQuotaRequests => 'Förfrågningar';

  @override
  String get obsQuotaUnitTokens => 'tokens';

  @override
  String get obsQuotaUnitRequests => 'förfrågningar';

  @override
  String get obsQuotaUnitCost => 'kostnad';

  @override
  String get obsQuotaAddLimitTitle => 'Lägg till kvotgräns';

  @override
  String get obsQuotaProviderLabel => 'Leverantör';

  @override
  String get obsQuotaWindowLabel => 'Fönster';

  @override
  String get obsQuotaUnitLabel => 'Enhet';

  @override
  String obsQuotaLimitLabel(String unit) {
    return 'Gräns ($unit)';
  }

  @override
  String get obsQuotaCentsHint => 'I US-cent (500 = \$5.00).';

  @override
  String get obsQuotaStatusOk => 'Ok';

  @override
  String get obsQuotaStatusWarning => 'Varning';

  @override
  String get obsQuotaStatusExhausted => 'Slut';

  @override
  String get obsQuotaStatusUnknown => 'Okänd';

  @override
  String get obsGoalNoActiveTitle => 'Inget aktivt mål';

  @override
  String get obsGoalNoActiveBody =>
      'Sätt ett mål för att ge agenterna ett syfte och en valfri tokenbudget. När körningar slutförs fylls budgeten och agenterna puffas att runda av när den nästan är slut.';

  @override
  String get obsGoalSetGoal => 'Sätt ett mål';

  @override
  String get obsGoalTokenBudget => 'Tokenbudget';

  @override
  String obsGoalTokensLeft(String tokens) {
    return '$tokens kvar';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens (ingen budget satt)';
  }

  @override
  String get obsGoalTokensUsed => 'Tokens använda';

  @override
  String get obsGoalElapsed => 'Förfluten';

  @override
  String get obsGoalWrapUp => 'Runda av';

  @override
  String get obsGoalClear => 'Rensa mål';

  @override
  String get obsGoalFallbackTitle => 'Mål';

  @override
  String get obsGoalSubtitle => 'Budget för målläge';

  @override
  String get obsGoalStatusActive => 'Aktivt';

  @override
  String get obsGoalStatusPaused => 'Pausat';

  @override
  String get obsGoalStatusBudgetLimited => 'Budgetbegränsat';

  @override
  String get obsGoalStatusComplete => 'Klar';

  @override
  String get obsGoalStatusDropped => 'Avbrutet';

  @override
  String get obsGoalObjectiveLabel => 'Mål';

  @override
  String get obsGoalBudgetLabel => 'Tokenbudget (valfritt)';

  @override
  String get obsGoalSetAction => 'Sätt mål';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => 'Lyckandefrekvens %';

  @override
  String get obsBenchmarkPassed => 'Godkända';

  @override
  String get obsBenchmarkFailed => 'Misslyckade';

  @override
  String get obsBenchmarkErrors => 'Fel';

  @override
  String get obsBenchmarkSpend => 'Utgift';

  @override
  String get obsBenchmarkCostPerTask => 'Kostnad / uppgift';

  @override
  String get obsBenchmarkTrials => 'Försök';

  @override
  String get obsBenchmarkNoTrials => 'Inga körningar att poängsätta ännu.';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Och $count till',
      one: 'Och 1 till',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => 'Godkänd';

  @override
  String get obsBenchmarkTrialFail => 'Underkänd';

  @override
  String get obsBenchmarkTrialError => 'Fel';

  @override
  String get obsBenchmarkTrialRunning => 'Körs';

  @override
  String get obsBenchmarkReward => 'Belöning';

  @override
  String get obsBenchmarkReport => 'Rapport';

  @override
  String get obsBenchmarkCopyMarkdown => 'Kopiera markdown';

  @override
  String get obsBenchmarkCopied => 'Rapport kopierad till urklipp';

  @override
  String get obsBehaviorCaption =>
      'Det här är frustrationstecken tolkade från dina egna meddelanden – en avläsning av samtalshälsa, inte ett betyg för agenterna. Beräknas lokalt; ingenting lämnar den här enheten.';

  @override
  String get obsBehaviorMessagesAnalyzed => 'Meddelanden analyserade';

  @override
  String get obsBehaviorTotalSignals => 'Totalt signaler';

  @override
  String get obsBehaviorYelling => 'Skrik';

  @override
  String get obsBehaviorProfanity => 'Svordomar';

  @override
  String get obsBehaviorAnguish => 'Ångest';

  @override
  String get obsBehaviorNegation => 'Negation';

  @override
  String get obsBehaviorRepetition => 'Upprepning';

  @override
  String get obsBehaviorBlame => 'Skuld';

  @override
  String get obsBehaviorConversationsTitle => 'Mest frustrerade samtal';

  @override
  String get obsBehaviorConversationsSubtitle =>
      'Rankade efter signaltäthet i dina meddelanden.';

  @override
  String get obsBehaviorNoSignals =>
      'Inga frustrationstecken upptäckta – lugnt vatten.';

  @override
  String obsBehaviorMessagesCount(String count) {
    return '$count meddelanden analyserade';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '$count signaler';
  }

  @override
  String get obsAgentStatusIdle => 'Overksam';

  @override
  String get obsAgentStatusParked => 'Parkerad';

  @override
  String get obsAgentStatusAborted => 'Avbruten';

  @override
  String get obsAgentKindSub => 'Sub';

  @override
  String get noChecksOnCommit =>
      'Inga kontroller har körts på den här commiten.';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Körs — $count jobb',
      one: 'Körs — 1 jobb',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alla kontroller godkända — $count jobb',
      one: 'Alla kontroller godkända — 1 jobb',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Slutförd — $count jobb',
      one: 'Slutförd — 1 jobb',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total jobb',
      one: '1 jobb',
    );
    return '$failed av $_temp0 misslyckades';
  }

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jobb',
      one: '1 jobb',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return 'Matris: $jobId';
  }

  @override
  String get jobLogsPending => 'Loggar visas här när jobbet är klart.';

  @override
  String get jobLogsUnavailable => 'Loggar saknas för det här jobbet.';

  @override
  String get noLogsForStep => 'Inga loggar fångades för det här steget.';

  @override
  String get jobLogsTruncated => 'Logg avkortad – visar den senaste utdatan.';

  @override
  String get fullLog => 'Full logg';

  @override
  String get copyLogs => 'Kopiera loggar';

  @override
  String get resizeGraph => 'Dra för att ändra storlek på grafen';

  @override
  String workflowRunStartedAgo(String time) {
    return 'Startad $time';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return 'Slutförd $time';
  }

  @override
  String get chatBridgesTitle => 'Chattbryggor';

  @override
  String chatProviderDescription(String provider, String command) {
    return 'Nämn boten i $provider för att sätta en agent på något, eller skapa ärenden med $command.';
  }

  @override
  String chatConnectProvider(String provider) {
    return 'Anslut $provider';
  }

  @override
  String get chatDisconnectProvider => 'Koppla från';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$botName i $teamName';
  }

  @override
  String get chatStateLive => 'Live';

  @override
  String get chatStateConnecting => 'Ansluter…';

  @override
  String get chatStateError => 'Anslutningsfel';

  @override
  String get chatNotConnected => 'Inte ansluten';

  @override
  String chatStreamingUnavailable(String provider) {
    return 'Liveströmning är av för den här $provider-appen – svar kommer som ett meddelande.';
  }

  @override
  String chatAdminOnly(String provider) {
    return 'Bara en admin kan ansluta $provider för den här arbetsytan.';
  }

  @override
  String chatConnectHint(String provider) {
    return 'Skapa en $provider-app och klistra sedan in dess inloggningsuppgifter här. Control Center ansluter ut till $provider, så den här servern behöver ingen publik adress.';
  }

  @override
  String chatOpenConsole(String provider) {
    return 'Öppna $provider-konsolen';
  }

  @override
  String get chatOpenSetupGuide => 'Installationsguide';

  @override
  String get chatFieldBotToken => 'Bot-token';

  @override
  String get chatFieldAppToken => 'Appnivå-token';

  @override
  String get chatFieldConfigRefreshToken => 'Token för appkonfiguration';

  @override
  String chatFieldOptional(String label) {
    return '$label (valfritt)';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return 'Länka mitt $provider-konto';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return 'Länka ditt $provider-konto så att meddelanden du skickar där tillskrivs dig.';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return 'Länkad till $externalUserId';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return 'Länka ditt $provider-konto';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return 'Skicka det här kommandot till boten i $provider. Det fungerar en gång och går ut om 15 minuter.';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return 'Ditt $provider-konto är nu länkat – meddelanden du skickar där tillskrivs dig.';
  }

  @override
  String get chatLinkedAccounts => 'Länkade konton';

  @override
  String chatNoLinkedAccounts(String provider) {
    return 'Ingen har länkat sitt $provider-konto ännu.';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count länkade konton',
      one: '1 länkat konto',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '$externalUserId · matchad via e-post';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '$externalUserId · länkad med en kod';
  }

  @override
  String get chatUnlink => 'Avlänka';

  @override
  String get chatCustomizeBot => 'Anpassa bot';

  @override
  String get chatCustomizeBotDescription =>
      'Byt namn på boten, ändra vad den säger om sig själv eller byt namn på slash-kommandot.';

  @override
  String get chatCustomizeBotUnavailable =>
      'Control Center behöver en token för appkonfiguration för att redigera boten. Återanslut och ta med en.';

  @override
  String chatCreateAppTitle(String provider) {
    return 'Skapa $provider-appen';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'Control Center kan skapa $provider-appen åt dig, med rätt behörigheter och händelser redan satta. Du avslutar i $provider och klistrar sedan in inloggningsuppgifterna här.';
  }

  @override
  String get chatCreateApp => 'Skapa app';

  @override
  String get chatCreateAppCta => 'Skapa app åt mig';

  @override
  String get chatAppNameLabel => 'Appnamn';

  @override
  String get chatBotDisplayNameLabel =>
      'Botnamn (vad medlemmar skriver efter @)';

  @override
  String get chatDescriptionLabel => 'Kort beskrivning';

  @override
  String get chatAgentDescriptionLabel => 'Vad boten säger att den kan göra';

  @override
  String get chatCommandLabel => 'Slash-kommando';

  @override
  String get chatDirectMessages => 'Direktmeddelanden';

  @override
  String chatDirectMessagesHint(String provider) {
    return 'Låter medlemmar chatta med boten i ett DM. Kan kräva en betald $provider-plan.';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return '$provider skapade appen $appId.';
  }

  @override
  String chatRemainingSteps(String provider) {
    return 'Några steg återstår och bara $provider kan göra dem:';
  }

  @override
  String get chatStepAppToken => 'Generera en appnivå-token';

  @override
  String get chatStepInstall => 'Installera appen';

  @override
  String get chatOpenAppSettings => 'Öppna appinställningar';

  @override
  String get chatContinueToCredentials => 'Klistra in inloggningsuppgifterna';

  @override
  String chatBotUpdated(String provider) {
    return 'Boten uppdaterades i $provider.';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return '$provider ändrade appens behörigheter. Installera om appen för att de ska gälla.';
  }

  @override
  String get chatReinstallApp => 'Installera om app';

  @override
  String chatIconNotEditable(String provider) {
    return 'Botens ikon kan bara ändras i ${provider}s egna appinställningar.';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return 'Du kan också skapa den i $provider själv – ingen token behövs. Inställningarna ovan följer med länken.';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return 'Skapa i $provider';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return '$provider öppnades i webbläsaren med den här konfigurationen ifylld. Skapa appen där, slutför sedan de här stegen och kom tillbaka med tokens.';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return '$provider rapporterar inte vilken app den skapade, så att anpassa boten härifrån behöver en token för appkonfiguration senare.';
  }

  @override
  String get chatStepCreateApp =>
      'Skapa appen från den ifyllda konfigurationen';

  @override
  String chatStepCreateAppHint(String provider) {
    return 'Välj en arbetsyta i $provider och bekräfta.';
  }

  @override
  String get chatStepAppTokenHint =>
      'Basic information → app-level tokens, med connections:write-omfånget.';

  @override
  String get chatStepInstallHint =>
      'Install app → kopiera bot user OAuth-token.';

  @override
  String get calendarUseBuiltinApp => 'Använd Control Centers Google-app';

  @override
  String get calendarUseBuiltinAppHint =>
      'Godkänn med ditt Google-konto. Inget att ställa in i Google Cloud.';

  @override
  String get calendarUseOwnClient => 'Använd min egen Google Cloud-klient';

  @override
  String get calendarUseOwnClientHint =>
      'Ange en OAuth-klient från ditt eget Google Cloud-projekt.';

  @override
  String get aboutTitle => 'Om';

  @override
  String get aboutAppVersion => 'Appversion';

  @override
  String get aboutServerVersion => 'Ansluten server';

  @override
  String get aboutRpcCatalog => 'RPC-katalog';

  @override
  String get aboutServerUnknown => 'Inte rapporterad';

  @override
  String get serverStaleTitle =>
      'Den medföljande servern är äldre än den här appen';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return 'Den körande cc_server är $serverVersion medan den här appen är $appVersion. Starta om appen så att den tar in den senaste medföljande serverversionen; under utveckling, bygg om den med `dart build cli` i apps/cc_server.';
  }

  @override
  String get updateCheckButton => 'Sök efter uppdateringar';

  @override
  String get updateChecking => 'Söker efter uppdateringar…';

  @override
  String get updateUpToDate => 'Du är uppdaterad';

  @override
  String get updateDeferredBusy =>
      'En uppdatering är redo men ett möte spelas in – den frågar när det är slut.';

  @override
  String get updateOpenedReleasesPage =>
      'Öppnade sidan för utgåvor i webbläsaren.';

  @override
  String get updateCheckFailed => 'Uppdateringskontrollen misslyckades';

  @override
  String updateAvailableVersion(String version) {
    return 'Version $version är tillgänglig.';
  }

  @override
  String get updateBannerTitle => 'En ny Control Center är tillgänglig';

  @override
  String get updateBannerRefresh => 'Uppdatera';

  @override
  String get updateBlockedRecording =>
      'Uppdatering är pausad medan ett möte spelas in – den läses in när det är slut.';

  @override
  String get settingsScopeYou => 'Du';

  @override
  String get settingsScopeWorkspace => 'Arbetsyta';

  @override
  String get settingsScopeServer => 'Server';

  @override
  String get settingsProfile => 'Profil och identitet';

  @override
  String get settingsYourDevices => 'Dina enheter';

  @override
  String get settingsWorkspaceGeneral => 'Allmänt';

  @override
  String get settingsServerConnection => 'Anslutning och status';

  @override
  String get settingsModelProviders => 'Modellleverantörer';

  @override
  String get settingsVoiceModels => 'Röst- och mötesmodeller';

  @override
  String get settingsDiagnostics => 'Diagnostik och integritet';

  @override
  String get settingsAbout => 'Om';

  @override
  String get settingsScopeBadgeYou => 'DU';

  @override
  String get settingsScopeBadgeDevice => 'DEN HÄR ENHETEN';

  @override
  String get settingsScopeBadgeWorkspace => 'ARBETSYTA';

  @override
  String get settingsScopeBadgeServer => 'SERVER';

  @override
  String get settingsProfileDescription =>
      'Ditt namn, e-post och git-identiteten som stämplas på commits som görs åt dig.';

  @override
  String get settingsServerConnectionDescription =>
      'Vilken server den här klienten pratar med, och hur den här servern delas (mDNS, tunnlar, relä).';

  @override
  String get settingsAboutDescription => 'Byggidentitet och uppdateringar.';

  @override
  String get settingsDiagnosticsDescription =>
      'Isolering, indexering, synkning, loggning och kraschrapportering för den här installationen.';

  @override
  String get settingsWorkspaceGeneralDescription =>
      'Identitet, policy och konventioner som delas av alla i den här arbetsytan.';

  @override
  String get settingsWorkspacePolicyLabel => 'Arbetsytepolicy';

  @override
  String get settingsWorkspacePolicyDescription =>
      'Gäller varje medlem och varje agent i den här arbetsytan.';

  @override
  String get settingsSecretGlobsLabel => 'Uteslutningar för hemliga sökvägar';

  @override
  String get settingsSecretGlobsHelp =>
      'Ett glob per rad. De här sökvägarna döljs för visare och gäster på kodbärande ytor, utöver de inbyggda standarderna.';

  @override
  String get settingsReviewConcurrencyLabel => 'Granskningsutspridning';

  @override
  String get settingsReviewConcurrencyHelp =>
      'Hur många granskare som skickas ut parallellt när inget explicit antal anges.';

  @override
  String get settingsReviewLevelLabel => 'Granskningsnivå';

  @override
  String get settingsReviewLevelHelp =>
      'Hur djupt AI-granskningen går, och hur mycket av det den hittar som rapporteras direkt. Inget kastas – en lättare nivå grupperar mindre fynd i stället för att släppa dem.';

  @override
  String get reviewLevelLight => 'Lätt';

  @override
  String get reviewLevelBalanced => 'Balanserad';

  @override
  String get reviewLevelThorough => 'Grundlig';

  @override
  String get reviewLevelLightHint =>
      'En granskare. Bara det som spelar materiell roll rapporteras direkt.';

  @override
  String get reviewLevelBalancedHint =>
      'Tre granskare som täcker QA, arkitektur och implementation.';

  @override
  String get reviewLevelThoroughHint =>
      'Lägger till säkerhets- och prestandaspecialister och rapporterar allt som hittas.';

  @override
  String get askAiReviewAtLevel => 'Granska på en annan nivå';

  @override
  String reviewNitpicksGroup(int count) {
    return 'Nitpicks ($count)';
  }

  @override
  String get reviewFindingResolve => 'Åtgärdad';

  @override
  String get reviewFindingResolveHint =>
      'Markera det här fyndet som åtgärdat. Det slutar räknas mot granskningen.';

  @override
  String get reviewFindingDismiss => 'Avfärda';

  @override
  String get reviewFindingDismissHint =>
      'Inte ett riktigt problem. Granskare slutar flagga det här mönstret på framtida PR:ar.';

  @override
  String get reviewFindingReopen => 'Öppna igen';

  @override
  String get reviewFindingStatusUndoLabel => 'Fyndstatus';

  @override
  String get reviewFindingDismissTitle => 'Avfärda det här fyndet';

  @override
  String get reviewFindingDismissReasonHint =>
      'Varför gäller det inte? Granskare kommer att läsa det.';

  @override
  String reviewFindingStatusFailed(String error) {
    return 'Kunde inte uppdatera fyndet: $error';
  }

  @override
  String get reviewStaleTitle => 'Den här granskningen är inaktuell';

  @override
  String get reviewStaleBody =>
      'Pull requesten har rört sig sedan den här granskningen kördes. Fynd kan peka på kod som inte längre finns.';

  @override
  String reviewStaleReviewedAt(String sha) {
    return 'Granskad vid $sha';
  }

  @override
  String get reviewStaleRerun => 'Granska igen';

  @override
  String reviewStaleNotificationTitle(int prNumber) {
    return 'Granskning inaktuell på #$prNumber';
  }

  @override
  String reviewStaleNotificationBody(String title) {
    return '$title har nya commits sedan senaste granskningen.';
  }

  @override
  String get reviewCategorySecurity => 'Säkerhet';

  @override
  String get reviewCategoryStability => 'Stabilitet';

  @override
  String get reviewCategoryDataIntegrity => 'Dataintegritet';

  @override
  String get reviewCategoryCorrectness => 'Korrekthet';

  @override
  String get reviewCategoryPerformance => 'Prestanda';

  @override
  String get reviewCategoryMaintainability => 'Underhållbarhet';

  @override
  String get reviewEffortQuickWin => 'Snabb vinst';

  @override
  String get reviewEffortModerate => 'Måttlig';

  @override
  String get reviewEffortHeavyLift => 'Tungt lyft';

  @override
  String get reviewProposedFix => 'Föreslagen åtgärd';

  @override
  String get reviewAiAgentPrompt => 'Prompt för AI-agenter';

  @override
  String get reviewCopyAiPrompt => 'Kopiera prompt';

  @override
  String get settingsWorkspaceAdminOnly =>
      'Bara arbetsyteadmins kan ändra de här.';

  @override
  String get chatMyAccountsTitle => 'Länkade chattkonton';

  @override
  String get settingsServerSso => 'Enkel inloggning';

  @override
  String get settingsServerSsoDescription =>
      'SAML- och OpenID Connect-inloggning med användarprovisionering';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabledDescription =>
      'Användare kan logga in med den här leverantören';

  @override
  String get ssoEnabledDescriptionOn =>
      'Inloggning är live för den här leverantören';

  @override
  String get ssoIdpMetadataLabel => 'IdP-metadata-XML';

  @override
  String get ssoIdpMetadataHint => 'klistra in IdP:ns EntityDescriptor-XML';

  @override
  String get ssoEmailAttributeLabel => 'E-postattribut';

  @override
  String get ssoDisplayNameAttributeLabel => 'Attribut för visningsnamn';

  @override
  String get ssoGroupsAttributeLabel => 'Gruppattribut';

  @override
  String get ssoIssuerLabel => 'Utfärdar-URL';

  @override
  String get ssoClientIdLabel => 'Klient-ID';

  @override
  String get ssoGroupsClaimLabel => 'Gruppclaim';

  @override
  String get ssoAutoMemberLabel =>
      'Lägg till användare i varje arbetsyta vid första inloggningen';

  @override
  String get ssoAutoMemberDescription =>
      'Slå av för att kräva en inbjudan per arbetsyta';

  @override
  String get ssoAllowJitLabel =>
      'Provisionera okända användare vid första inloggningen';

  @override
  String get ssoAllowJitDescription =>
      'Slå av för att avvisa användare utan ett befintligt konto';

  @override
  String get ssoAllowIdpInitiatedLabel =>
      'Acceptera oombett (IdP-initierad) inloggning';

  @override
  String get ssoAllowIdpInitiatedDescription =>
      'Strikt för IdP-portaler som startar appar direkt';

  @override
  String get ssoWantResponseSignedLabel => 'Kräv ett signerat svarskuvert';

  @override
  String get ssoWantResponseSignedDescription =>
      'Assertion-signaturer krävs alltid';

  @override
  String get ssoTestConnectionButton => 'Testa anslutning';

  @override
  String get ssoTestConnectionOk => 'Anslutningen fungerar:';

  @override
  String get ssoCopySpMetadata => 'Kopiera SP-metadata';

  @override
  String get ssoCopySpMetadataDone => 'SP-metadata kopierad till urklipp';

  @override
  String get ssoSavedToast => 'Inställningar för enkel inloggning sparade';

  @override
  String get ssoUnavailable =>
      'Den här servern exponerar inte inställningar för enkel inloggning. Uppdatera serverbinären och försök igen.';

  @override
  String get ssoScimCardTitle => 'Användarprovisionering (SCIM)';

  @override
  String get ssoScimDescription =>
      'Peka identitetsleverantörens SCIM-koppling mot endpointen nedan med en bearer-token. Avprovisionering återkallar sessioner och arbetsyteåtkomst inom sekunder. Servern måste vara nåbar av IdP:n (tunnel eller publik URL).';

  @override
  String get ssoScimEndpoint => 'SCIM-endpoint';

  @override
  String get ssoScimEndpointUnknownOrigin =>
      'Ange serverns publika URL eller slå på en tunnel först';

  @override
  String get ssoScimRegenerate => 'Generera om token';

  @override
  String get ssoScimRegenerateConfirm =>
      'Generera en ny SCIM-bearer-token? Den föregående token slutar fungera omedelbart.';

  @override
  String get ssoScimTokenTitle => 'Bearer-token';

  @override
  String get ssoScimTokenPresent => 'En token är konfigurerad';

  @override
  String get ssoScimTokenAbsent =>
      'Ingen token ännu – generera en för att aktivera SCIM';

  @override
  String get ssoScimTokenOnce => 'SCIM-token (visas en gång)';

  @override
  String ssoSignInWith(String provider) {
    return 'Logga in med $provider';
  }

  @override
  String get ssoProbeFailed => 'Kunde inte nå den servern för enkel inloggning';

  @override
  String get ssoOpensBrowser =>
      'Öppnar webbläsaren för att slutföra inloggningen';

  @override
  String get ssoWaitingForBrowser =>
      'Väntar på att webbläsaren ska slutföra inloggningen…';

  @override
  String get ssoBrowserOpenFailed =>
      'Kunde inte öppna webbläsaren för enkel inloggning';

  @override
  String get ssoUseManualPairing =>
      'Logga in med en inbjudan eller parkopplingsnyckel i stället';

  @override
  String get ssoHideManualPairing => 'Dölj manuell parkoppling';

  @override
  String get ssoClientIdHint => 'Publik (PKCE) klient – ingen hemlighet behövs';

  @override
  String get ssoClientSecretLabel => 'Klienthemlighet (valfritt)';

  @override
  String get ssoClientSecretHintUnset =>
      'Behövs bara för konfidentiella IdP-klienter';

  @override
  String get ssoClientSecretHintSet =>
      'En hemlighet är lagrad – lämna tomt för att behålla den';

  @override
  String get ssoPairingToggle =>
      'Tillåt manuell parkoppling (inbjudningskoder och parkopplingsnycklar)';

  @override
  String get ssoPairingToggleDescription =>
      'Slå av för att göra anslutning endast via enkel inloggning – nya enheter kommer via SSO-inloggningar; befintliga enheter fortsätter fungera';

  @override
  String get ssoPairConfirmTitle => 'Ansluta till servern?';

  @override
  String ssoPairConfirmBody(String server) {
    return 'En inloggningsuppgift för $server kom fram, men ingen inloggning startades från den här appen. Ansluta till den här servern?';
  }

  @override
  String get ssoPairConfirmConnect => 'Anslut';

  @override
  String get ssoPairConfirmCancel => 'Ignorera';

  @override
  String get forgeConnections => 'Kodvärd';

  @override
  String get connect => 'Anslut';

  @override
  String get disconnect => 'Koppla från';

  @override
  String get notConnected => 'Inte ansluten';

  @override
  String get checkingConnection => 'Kontrollerar anslutning…';

  @override
  String get fromEnvironment => 'från miljön';

  @override
  String forgeTokenTitle(String forge) {
    return '$forge-token';
  }

  @override
  String get settingsAudio => 'Ljud';

  @override
  String get settingsAudioDescription =>
      'Mikrofon, diktering, mötesupptäckt och ljudlandskapsutgång.';

  @override
  String get audioDevicesSection => 'Ljudenheter';

  @override
  String get voiceInputBehaviorSection => 'Diktering och möten';

  @override
  String get audioOutputDeviceTitle => 'Utenhet';

  @override
  String get audioOutputDefaultHint =>
      'Allt appljud spelas genom systemets standardutgång.';

  @override
  String get audioOutputGone =>
      'Den valda utenheten är inte längre ansluten – systemets standard används tills du väljer en annan.';

  @override
  String get reviewHubIntroBody =>
      'Agenter analyserar diffen, kartlägger ändringsområdena och når ett konsensusutslag.';

  @override
  String get reviewHubAlreadyRunning =>
      'En granskning körs redan för den här pull requesten';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return 'Sedan senaste granskningen: $resolved lösta · $added nya · $open fortfarande öppna';
  }

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return 'Tidigare granskad vid $sha';
  }

  @override
  String reviewArtifactFixAll(int count) {
    return 'Åtgärda $count fynd';
  }

  @override
  String reviewArtifactFixSelected(int count) {
    return 'Åtgärda $count valda';
  }

  @override
  String reviewArtifactCommentSelected(int count) {
    return 'Kommentera $count valda';
  }

  @override
  String get webConnectTitle => 'Anslut till Control Center';

  @override
  String get webConnectSubtitle =>
      'Ring en körande cc-server över WebSocket. Din nyckel stannar på den här enheten.';

  @override
  String get webConnectServerLabel => 'Server';

  @override
  String get webConnectDeviceIdLabel => 'Enhets-ID';

  @override
  String get webConnectPairingKeyLabel => 'Parkopplingsnyckel';

  @override
  String get webConnectPairingKeyHint => 'klistra in PSK';

  @override
  String get webConnectStayConnected => 'Förbli ansluten på den här enheten';

  @override
  String get webConnectStayConnectedDetail =>
      'Förbli ansluten på den här enheten (lagrar din nyckel i den här webbläsaren)';

  @override
  String failedToCreateWorkspace(String error) {
    return 'Kunde inte skapa arbetsyta: $error';
  }

  @override
  String committedRelative(String relative) {
    return 'committad $relative';
  }

  @override
  String get selectAgents => 'Välj agenter';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agenter',
      one: '1 agent',
    );
    return '$_temp0';
  }

  @override
  String get newConversation => 'Nytt samtal';

  @override
  String get untitledConversation => 'Namnlöst samtal';

  @override
  String get conversationTitleOptionalHint =>
      'Valfritt – lämna tomt så namnger titelmodellen den automatiskt';

  @override
  String get conversationTitlesSectionTitle => 'Samtalstitlar';

  @override
  String get conversationTitlesSectionCaption =>
      'Välj köraren som namnger nya samtal i den här arbetsytan automatiskt. Titlar är av tills en adapter väljs, och gäller varje medlem.';

  @override
  String get conversationTitlesModelLabel => 'Titelmodell';

  @override
  String get conversationTitlesAdapterLabel => 'Adapter';

  @override
  String get conversationTitlesAdapterHint => 'Av';

  @override
  String get conversationTitlesAdapterOff => 'Av';

  @override
  String get startThread => 'Starta tråd';

  @override
  String get deleteSpaceConfirm =>
      'Ta bort den här ytan? Alla meddelanden går förlorade.';

  @override
  String threadTabTitle(String title) {
    return 'Tråd: $title';
  }

  @override
  String threadReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count svar',
      one: '1 svar',
    );
    return '$_temp0';
  }

  @override
  String threadLastReply(String time) {
    return 'Senaste svaret $time';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Logga in med $provider';
  }

  @override
  String get signInAgain => 'Logga in igen';

  @override
  String get signInNotFinished =>
      'Inloggningen har inte kommit tillbaka ännu. Slutför den i webbläsaren och kontrollera sedan igen.';

  @override
  String get signedOutTitle => 'Du är utloggad';

  @override
  String get signedOutSubtitle =>
      'Din kodvärdsanslutning är inte längre giltig – en token gick ut, eller dess åtkomst återkallades. Ingenting annat ändrades: logga in igen så är allt där du lämnade det.';

  @override
  String get viaServerApp => 'via den här serverns app';

  @override
  String get ticketing => 'Ärenden';

  @override
  String get ticketingProviderHelp =>
      'Var dina ärenden ligger. Lokal behåller dem i Control Center.';

  @override
  String providerComingSoon(String provider) {
    return '$provider (snart)';
  }

  @override
  String get ticketProviderLocal => 'Lokal';

  @override
  String get addKey => 'Lägg till nyckel';

  @override
  String get providerApps => 'Leverantörsappar';

  @override
  String get providerAppsDescription =>
      'Hur den här servern autentiserar som sig själv, och vad en person loggar in genom. Bakgrundsarbete – webhooks, polling, synk – körs på appen, aldrig på en persons token.';

  @override
  String get providerAppId => 'App-ID';

  @override
  String get providerPrivateKey => 'Privat nyckel';

  @override
  String get providerClientId => 'Klient-ID';

  @override
  String get providerClientSecret => 'Klienthemlighet';

  @override
  String get providerApiKey => 'API-nyckel';

  @override
  String get providerCallbackUrl => 'Callback-URL';

  @override
  String get providerAppFullyConfigured =>
      'Servern kan agera som sig själv, och personer kan logga in.';

  @override
  String get providerAppServerOnly =>
      'Servern kan agera som sig själv. Lägg till ett klient-ID och en hemlighet för att låta personer logga in.';

  @override
  String get providerAppSignInOnly =>
      'Personer kan logga in. Bakgrundsarbete faller tillbaka till deras inloggningsuppgifter.';

  @override
  String providerAppInstalledOn(String accounts) {
    return 'Inloggningsuppgifterna fungerar. Installerad på: $accounts';
  }

  @override
  String deviceCodeInstructions(String provider) {
    return 'Ange den här koden på $provider-sidan som just öppnades. Den har kopierats till urklipp.';
  }

  @override
  String get deviceCodeWaiting =>
      'Väntar på att du ska slutföra i webbläsaren…';

  @override
  String get copyCodeAndOpen => 'Kopiera kod och öppna';

  @override
  String get couldNotOpenBrowser =>
      'Ingen webbläsare kunde öppnas. Kopiera länken och slutför inloggningen själv.';

  @override
  String get contextUsage => 'Kontextanvändning';

  @override
  String get contextUsageFull => 'full';

  @override
  String get contextUsageTokens => 'tokens';

  @override
  String get contextSeeMore => 'Visa mer';

  @override
  String get contextSegmentSystemPrompt => 'Systemprompt';

  @override
  String get contextSegmentRules => 'Regler';

  @override
  String get contextSegmentSkills => 'Färdigheter';

  @override
  String get contextSegmentToolDefinitions => 'Verktygsdefinitioner';

  @override
  String get contextSegmentMcpTools => 'MCP och dynamiska verktyg';

  @override
  String get contextSegmentDeferredTools => 'Verktyg som läses in vid behov';

  @override
  String get contextSegmentSubagents => 'Subagentdefinitioner';

  @override
  String get contextSegmentMemory => 'Minne';

  @override
  String get contextSegmentConversation => 'Samtal';

  @override
  String get contextExplorerTitle => 'Kontext';

  @override
  String get contextExplorerEverything => 'Allt';

  @override
  String get contextExplorerSelectPart =>
      'Välj en del för att inspektera dess innehåll';

  @override
  String get contextExplorerUnavailable => 'Kontextuppdelning otillgänglig';

  @override
  String get contextRetry => 'Försök igen';

  @override
  String get settingsFieldOptional => 'Valfritt';

  @override
  String get settingsFilterHint => 'Filtrera den här listan';

  @override
  String get settingsValueNotAvailable => 'Inte tillgänglig ännu';

  @override
  String get settingsNoEntriesYet => 'Inget här ännu';

  @override
  String get settingsChangedBadge => 'Ändrad';

  @override
  String get ssoConnectionCardDescription =>
      'Välj hur personer loggar in på den här servern, och slå sedan på den anslutningen.';

  @override
  String get ssoUseSamlForSignIn => 'Använd SAML för inloggning';

  @override
  String get ssoUseOidcForSignIn => 'Använd OpenID Connect för inloggning';

  @override
  String get ssoSaveConnection => 'Spara anslutning';

  @override
  String get ssoStateLive => 'Live';

  @override
  String get ssoStateConfiguredOff => 'Konfigurerad, av';

  @override
  String get ssoStateOnIncomplete => 'På, ofullständig';

  @override
  String get ssoStateActive => 'Aktiv';

  @override
  String get ssoStateAllowed => 'Tillåten';

  @override
  String get ssoStateNoToken => 'Ingen token';

  @override
  String get ssoSummaryDirectorySync => 'Katalogsynk';

  @override
  String get ssoSummaryManualPairing => 'Manuell parkoppling';

  @override
  String get ssoNoMethodLiveNote =>
      'Ingen inloggningsmetod är live. Nya enheter ansluter med en inbjudan eller parkopplingsnyckel tills du konfigurerar en anslutning och slår på den.';

  @override
  String get ssoMethodSamlBlurb =>
      'För identitetsleverantörer som talar SAML 2.0, som Okta, Entra ID eller Google Workspace.';

  @override
  String get ssoMethodOidcBlurb =>
      'För identitetsleverantörer som talar OpenID Connect. Oftast den enklare av de två att ställa in.';

  @override
  String get ssoGroupIdentityProvider => 'Identitetsleverantör';

  @override
  String get ssoGroupIdentityProviderSamlDescription =>
      'Var assertions kommer ifrån, och hur den här servern verifierar dem.';

  @override
  String get ssoGroupIdentityProviderOidcDescription =>
      'Vilken utfärdare den här servern litar på, och klienten den autentiserar som.';

  @override
  String get ssoSpEntityIdShortLabel => 'SP entity ID';

  @override
  String get ssoSpEntityIdDescription =>
      'Lämna tomt för att härleda det från server-URL:en.';

  @override
  String get ssoIssuerDescription =>
      'Bas-URL:en som serverar leverantörens discovery-dokument.';

  @override
  String get ssoSecretStored => 'Lagrad';

  @override
  String get ssoGroupHandoff => 'Vad din identitetsleverantör behöver';

  @override
  String get ssoGroupHandoffDescription =>
      'Klistra in de här i applikationen du skapade hos din leverantör.';

  @override
  String get ssoOriginUnknownTitle =>
      'Den här servern känner inte till sin publika URL';

  @override
  String get ssoOriginUnknownBody =>
      'Inloggnings- och callback-URL:er byggs från den, så din leverantör kan inte nå den här servern förrän en är satt. Lägg till en publik URL eller slå på en tunnel under Server → Anslutning.';

  @override
  String get ssoAcsUrlLabel => 'Assertion consumer service (ACS)-URL';

  @override
  String get ssoAcsUrlDescription =>
      'Dit din leverantör postar den signerade assertionen.';

  @override
  String get ssoSpEntityIdResolvedLabel => 'Service provider entity ID';

  @override
  String get ssoMetadataUrlLabel => 'SP-metadata-URL';

  @override
  String get ssoMetadataUrlDescription =>
      'Leverantörer som importerar metadata kan hämta den härifrån i stället.';

  @override
  String get ssoRedirectUriLabel => 'Redirect URI';

  @override
  String get ssoRedirectUriDescription =>
      'Lägg till den här bland tillåtna redirect URI:er för din leverantörs applikation.';

  @override
  String get ssoSignInUrlLabel => 'Inloggnings-URL';

  @override
  String get ssoSignInUrlDescription =>
      'Skicka personer hit för att starta en enkel inloggning.';

  @override
  String get ssoGroupAttributeMapping => 'Attributmappning';

  @override
  String get ssoGroupAttributeMappingDescription =>
      'Vilket claim som bär varje fält. Behåll standardvärdena om inte din leverantör byter namn på dem.';

  @override
  String get ssoGroupAccess => 'Åtkomst och roller';

  @override
  String get ssoGroupAccessDescription =>
      'Vad någon som loggar in framgångsrikt får göra.';

  @override
  String get ssoDefaultRoleShortLabel => 'Standardroll';

  @override
  String get ssoDefaultRoleDescription =>
      'Ges till den vars grupper inte matchar någon mappning nedan.';

  @override
  String get ssoRoleMapShortLabel => 'Grupp-till-roll-mappning';

  @override
  String get ssoRoleMapDescription =>
      'Den första matchande gruppen vinner. Ägare kan inte ges på det här sättet.';

  @override
  String get ssoRoleMapGroupHint => 'Gruppnamn från din leverantör';

  @override
  String get ssoRoleMapAdd => 'Lägg till mappning';

  @override
  String get ssoRoleMapEmpty => 'Inga mappningar – alla får standardrollen.';

  @override
  String get ssoAdvancedSummary =>
      'Klockskevning, IdP-initierad inloggning, signaturpolicy';

  @override
  String get ssoClockSkewShortLabel => 'Klockskevning';

  @override
  String get ssoClockSkewDescription =>
      'Sekunder tolerans på assertion-tidsstämplar. 90 passar de flesta leverantörer.';

  @override
  String get ssoScimGenerate => 'Generera token';

  @override
  String get ssoScimTokenOnceBody =>
      'Kopierad till urklipp. Den visas en gång och kan inte återskapas, så klistra in den i din leverantör nu.';

  @override
  String get ssoPairingCardTitle => 'Manuell parkoppling';

  @override
  String get ssoPairingCardDescription =>
      'Det andra sättet in på den här servern: inbjudningskoder och parkopplingsnycklar, för enheter som inte går via enkel inloggning.';

  @override
  String settingsCountOfTotal(int count, int total) {
    return '$count av $total';
  }

  @override
  String get providersNoneConnectedNote =>
      'Ingen leverantör är ansluten, så den inbyggda agentruntimen har inget att köra på. Lägg till en API-nyckel eller logga in på en nedan.';

  @override
  String get providersFilterHint => 'Filtrera leverantörer';

  @override
  String get providersNoneMatch => 'Inget matchar det här filtret';

  @override
  String get providerDeniedHereTitle => 'Nekad i den här arbetsytan';

  @override
  String get providerDeniedHereBody =>
      'Agenter här kan inte använda den här leverantören, även om den är ansluten. Andra arbetsytor påverkas inte.';

  @override
  String get providerNeedsSignIn =>
      'Logga in för att använda den här leverantören';

  @override
  String get providerNeedsApiKey =>
      'Lägg till en API-nyckel för att använda den här leverantören';

  @override
  String get providerApiKeyLabel => 'API-nyckel';

  @override
  String get providerGenerationDefaults => 'Leverantörsstandard';

  @override
  String get providerNoModelsYet =>
      'Inga modeller rapporterade ännu. Anslut leverantören och synka sedan.';

  @override
  String get providerModelsFilterHint => 'Filtrera modeller';

  @override
  String get adaptersNoneReadyNote =>
      'Ingen av de katalogiserade körar-CLI:erna hittades på den här maskinen. Installera en och uppdatera sedan.';

  @override
  String get adaptersFilterHint => 'Filtrera körare';

  @override
  String get adaptersLaunchGroup => 'Start';

  @override
  String get adaptersLaunchGroupDescription =>
      'Vad den här köraren får när en agent startar den. Sätt de här innan du installerar CLI:t om du vill.';

  @override
  String get adaptersEnvNone => 'Inga satta';

  @override
  String adaptersEnvCount(int count) {
    return '$count satta';
  }

  @override
  String get adapterArgumentsDescription =>
      'Läggs till på körarens kommandorad vid varje start.';

  @override
  String get defaultChatDescription =>
      'Kör nya samtal och alla agenter utan egen körare.';

  @override
  String get shortTaskDescription =>
      'Kör snabbt bakgrundsarbete som titlar och sammanfattningar. En mindre modell hör hemma här.';

  @override
  String get settingsStateFailed => 'Misslyckades';

  @override
  String get providerAppsGroupServer => 'Agerar som servern';

  @override
  String get providerAppsGroupServerDescription =>
      'Låter bakgrundsarbete nå arkiv utan en människa bakom förfrågan: webhooks, pull request-polling, ärendesynk.';

  @override
  String get providerAppsGroupPrConversations => 'Pull request-samtal';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      'Hur utvecklare kan prata med den här servern direkt på GitHub. Fungerar utan webhook eller publik URL – servern pollar.';

  @override
  String get providerAppBotLogin => 'Bot-inloggning';

  @override
  String get providerAppBotLoginEmpty =>
      'Testa anslutningen för att lösa bot-inloggningen.';

  @override
  String get providerAppAskOnGitHub => 'Fråga på GitHub';

  @override
  String get providerAppAskOnGitHubHint =>
      'Nämn bot-inloggningen ovan i en pull request-kommentar – [bot]-suffixet är valfritt – för att begära en granskning eller ställa en fråga, svara i dess granskningstrådar, eller lägg till etiketten `ai-review` för att begära en granskning.';

  @override
  String get providerAppsGroupSignIn => 'Logga in personer';

  @override
  String get providerAppsGroupSignInDescription =>
      'Låter varje medlem ansluta sitt eget konto och få egna inloggningsuppgifter.';

  @override
  String get providerAppCapActsAsServer => 'Agerar som servern';

  @override
  String get providerAppCapSignsIn => 'Loggar in personer';

  @override
  String get portLabel => 'Port';

  @override
  String get mcpNoTokenWarning =>
      'Utan en token kan allt som når den här porten anropa varje verktyg.';

  @override
  String get mcpBridgedToolsLabel => 'Verktyg';

  @override
  String get guardrailFamilyFiles => 'Filer';

  @override
  String get guardrailFamilyGit => 'Git och pull requests';

  @override
  String get guardrailFamilyMachine => 'Maskin och nätverk';

  @override
  String get guardrailFamilyControl => 'Hemligheter och arbetsyta';

  @override
  String get guardrailScopeFieldLabel => 'Redigerar regler för';

  @override
  String get guardrailScopeFieldDescription =>
      'Ett snävare omfång vinner över ett bredare. Regler satta här gäller ovanpå det som ärvs.';

  @override
  String get guardrailSetHere => 'Satt här';

  @override
  String get guardrailClearAllHere => 'Rensa alla';

  @override
  String get sandboxingCardLabel => 'Sandlåda';

  @override
  String get sandboxingCardDescription =>
      'Om agentarbete körs isolerat från den här värden, och vad en isolerad agent fortfarande kan nå.';

  @override
  String get sandboxBackendNoneActive => 'Värd, ingen isolering';

  @override
  String get sandboxSummaryHost => 'Värd';

  @override
  String get sandboxGroupIsolation => 'Isolering';

  @override
  String get sandboxGroupIsolationDescription =>
      'Var en agents processer och filskrivningar faktiskt sker.';

  @override
  String get sandboxBackendFieldDescription =>
      'Auto väljer den starkaste den här värden stöder. Fäst en för att stoppa den från att bytas under dig.';

  @override
  String get sandboxCapabilitiesDescription =>
      'Hålen som slås genom gränsen. Varje ett är något en isolerad agent fortfarande kan göra mot omvärlden.';

  @override
  String get sandboxSummaryInForce => 'I kraft';

  @override
  String get rigsInstallHintLabel => 'Hur du installerar den';

  @override
  String get rigsStarting => 'Startar';

  @override
  String get rigsResidentMemory => 'Resident minne';

  @override
  String get installedLabel => 'Installerad';

  @override
  String get notInstalledLabel => 'Inte installerad';

  @override
  String ssoOtherKindUnsaved(String method) {
    return '$method har osparade ändringar';
  }

  @override
  String get collapseComment => 'Fäll ihop kommentar';

  @override
  String get expandComment => 'Visa kommentar';

  @override
  String get suggestedChange => 'Föreslagen ändring';

  @override
  String get emptyComment => 'Tom kommentar';

  @override
  String repliesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count svar',
      one: '1 svar',
    );
    return '$_temp0';
  }

  @override
  String get pendingReview => 'Väntande granskning';

  @override
  String failedToResolveConversation(String error) {
    return 'Kunde inte uppdatera samtalet: $error';
  }

  @override
  String get addSingleComment => 'Lägg till en kommentar';

  @override
  String get addToReview => 'Lägg till i granskning';

  @override
  String get startAReview => 'Starta en granskning';

  @override
  String get reviewNeedsABody =>
      'Skriv en sammanfattning eller köa en radkommentar först';

  @override
  String get reviewSubmitted => 'Granskning skickad';

  @override
  String get finishYourReview => 'Slutför din granskning';

  @override
  String get commentVerdict => 'Kommentar';

  @override
  String pendingCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count väntande kommentarer',
      one: '1 väntande kommentar',
    );
    return '$_temp0';
  }

  @override
  String andNMore(int count) {
    return 'och $count till';
  }

  @override
  String get queuedCommentHint =>
      'Den här kommentaren går ut när du skickar in din granskning.';

  @override
  String commentOnLinesRange(int start, int end) {
    return 'Rader $start till $end';
  }

  @override
  String get claudeAccountsTitle => 'Claude Code-konton';

  @override
  String get claudeAccountsDescription =>
      'Varje konto är en separat Claude Code-inloggning. Körningar använder kontona som är kopplade nedan, i den här ordningen.';

  @override
  String get claudeAccountsEmpty => 'Inga konton ännu';

  @override
  String get claudeAccountAdd => 'Lägg till konto';

  @override
  String get claudeAccountSignIn => 'Logga in';

  @override
  String get claudeAccountSignInAgain => 'Logga in igen';

  @override
  String get claudeAccountSignInHint =>
      'Kör det här i en terminal på servern. Det öppnar en webbläsare för att slutföra inloggningen och skriver inloggningsuppgifterna till det här kontots katalog.';

  @override
  String get claudeAccountSignedOut => 'Utloggad';

  @override
  String get claudeAccountExpired => 'Inloggningen har gått ut';

  @override
  String claudeAccountExpiredDetail(String when) {
    return 'Inloggningen gick ut $when. Logga in igen för att använda det här kontot.';
  }

  @override
  String get claudeAccountMakeDefault => 'Gör till standard';

  @override
  String get claudeAccountDefault => 'Standard';

  @override
  String claudeAccountRemoveConfirm(String label) {
    return 'Ta bort $label?';
  }

  @override
  String get claudeAccountRemoveDetail =>
      'Det här loggar ut kontot och tar bort dess katalog på servern. Själva inloggningen påverkas inte.';

  @override
  String claudeAccountStatusUnknown(String error) {
    return 'Kunde inte kontrollera det här kontot: $error';
  }

  @override
  String claudeAccountUsedPercent(String percent) {
    return '$percent % använt';
  }

  @override
  String get accountPoolStrategy => 'Rotation';

  @override
  String get accountPoolPinned => 'Fäst';

  @override
  String get accountPoolRoundRobin => 'Round robin';

  @override
  String get accountPoolSerial => 'En i taget';

  @override
  String get accountPoolPinnedHint =>
      'Börja alltid på det första kontot. De andra är reserv om det misslyckas.';

  @override
  String get accountPoolRoundRobinHint =>
      'Sprid körningar över kontona och gå till nästa vid varje utskick.';

  @override
  String get accountPoolSerialHint => 'Töm det första kontot innan nästa rörs.';

  @override
  String get accountPoolMoveUp => 'Flytta upp';

  @override
  String get accountPoolMoveDown => 'Flytta ner';

  @override
  String get accountPoolUsingAll =>
      'Inget kopplat ännu – varje konto används, i den här ordningen.';

  @override
  String get accountPoolInheriting => 'Ärver arbetsytans konton.';

  @override
  String get accountPoolResetToWorkspace => 'Återställ till arbetsytans konton';

  @override
  String accountPoolCoolingOff(String when) {
    return 'utanför kvot till $when';
  }

  @override
  String get accountPoolSignedOut => 'utloggad';

  @override
  String get accountPoolExpired => 'inloggningen har gått ut';

  @override
  String accountPoolLoadFailed(String error) {
    return 'Kunde inte läsa in rotationen: $error';
  }

  @override
  String get providerSignedInAccount => 'inloggat konto';

  @override
  String get agentAccountsTab => 'Konton';

  @override
  String get agentClaudeAccountsNoticeTitle => 'Flera Claude Code-konton';

  @override
  String agentClaudeAccountsNoticeBody(int count) {
    return 'Den här köraren loggar in som ett av de $count Claude Code-kontona på den här värden. Välj vilket, eller rotera mellan dem, under fliken Konton.';
  }

  @override
  String get agentAccountsDescription =>
      'Vilka konton den här agentens körningar använder. Varje block börjar med att ärva arbetsytans val.';

  @override
  String get agentAccountsNothingToRotate =>
      'Inget att rotera – anslut ett andra konto eller en nyckel först.';

  @override
  String failedToPostReply(String error) {
    return 'Kunde inte skicka svaret: $error';
  }

  @override
  String commentOnLine(int line) {
    return 'Rad $line';
  }

  @override
  String get viewInDiff => 'Visa i diff';

  @override
  String get subscriptionUsagePreviousAccount => 'Föregående konto';

  @override
  String get subscriptionUsageNextAccount => 'Nästa konto';

  @override
  String inReplyTo(String path) {
    return 'Som svar på $path';
  }

  @override
  String get subscriptionUsageNoneReported =>
      'Ingen användning rapporterad för det här kontot.';

  @override
  String get subscriptionUsageCredits => 'Krediter';

  @override
  String get reviewHubStaticRule => 'Statisk regel';

  @override
  String get reviewHubStarted => 'Granskning startad';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return 'Hittad av en deterministisk regel ($rule) på en rad den här pull requesten lägger till – inte av en granskaragent.';
  }

  @override
  String get prReviewArtifactTab => 'PR-granskning';

  @override
  String get prReviewRunning => 'Granskar den här pull requesten…';

  @override
  String get prReviewStarting => 'Startar granskning…';

  @override
  String get prReviewStartingBody =>
      'Förbereder den här pull requestens worktree. Granskarna startar så fort den är redo.';

  @override
  String get prReviewFailed => 'Granskningen misslyckades.';

  @override
  String get prReviewRerunning => 'Granskar om…';

  @override
  String get prReviewNoOpenFindings => 'Inga öppna fynd';

  @override
  String prReviewOpenFindings(int count) {
    return '$count öppna fynd';
  }

  @override
  String subscriptionUsageSpend(String used, String limit) {
    return '$used av $limit';
  }

  @override
  String reviewCommentsPosted(int posted, int skipped, int failed) {
    return 'Publicerade $posted kommentar(er) som boten. $skipped hoppades över (ingen filankare), $failed misslyckades.';
  }

  @override
  String reviewFindingsOutOfDiff(int count, String files) {
    return '$count fynd pekar på kod den här pull requesten inte ändrar ($files). GitHub accepterar bara radkommentarer på diffen.';
  }

  @override
  String get reviewRailReport => 'Rapport';

  @override
  String get reviewNoFindingsTitle => 'Inga granskningsfynd ännu';

  @override
  String get reviewNoFindingsHint =>
      'Fynd visas här när agenter publicerar dem.';

  @override
  String reviewShowDismissed(int count) {
    return 'Visa $count avfärdade';
  }

  @override
  String reviewHideDismissed(int count) {
    return 'Dölj $count avfärdade';
  }

  @override
  String reviewDisagreementsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count granskarosämjor upptäckta',
      one: '1 granskarosämja upptäckt',
    );
    return '$_temp0';
  }

  @override
  String get reviewFilterKind => 'Typ';

  @override
  String get reviewFilterStatus => 'Status';

  @override
  String get reviewKindBug => 'Bugg';

  @override
  String get reviewKindSuggestion => 'Förslag';

  @override
  String get reviewKindRecommendation => 'Rekommendation';

  @override
  String get reviewKindQuestion => 'Fråga';

  @override
  String get reviewKindTicket => 'Ärende';

  @override
  String get archiveSpace => 'Arkivera yta';

  @override
  String get archivedSpaces => 'Arkiverade ytor';

  @override
  String get archivedSpacesEmpty => 'Inga arkiverade ytor';

  @override
  String get restoreSpace => 'Återställ';

  @override
  String archivedWhen(String time) {
    return 'Arkiverad $time';
  }

  @override
  String get deleteSpacePermanently => 'Ta bort permanent';

  @override
  String get renameSpace => 'Byt namn på yta';

  @override
  String get renameConversation => 'Byt namn på samtal';

  @override
  String get spaceActions => 'Åtgärder för ytan';

  @override
  String get conversationActions => 'Åtgärder för konversationen';

  @override
  String get editSpaceRepos => 'Redigera arkiv';

  @override
  String get editSpaceReposTitle => 'Ytans arkiv';

  @override
  String get editSpaceReposWarning =>
      'Att lägga till ett arkiv checkar ut det i den här ytan; att ta bort ett tar bort dess mapp.';

  @override
  String get agentSectionIdentity => 'Identitet';

  @override
  String get agentSectionRuntime => 'Runtime';

  @override
  String get agentSectionGuardrails => 'Räcken';

  @override
  String orgChartReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rapporter',
      one: '1 rapport',
    );
    return '$_temp0';
  }

  @override
  String get teamsFilterHint => 'Filtrera team…';

  @override
  String get teamsSummaryWithLeader => 'Med en ledare';

  @override
  String teamCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count team',
      one: '1 team',
      zero: 'Inga team',
    );
    return '$_temp0';
  }

  @override
  String agentDeleteLongDescription(String name) {
    return 'Att ta bort $name tar bort dess profil, dess färdighetslänkar och dess körningshistorik. Det går inte att ångra.';
  }

  @override
  String get resetToDefault => 'Återställ till standard';

  @override
  String get newAgent => 'Ny agent';

  @override
  String get newSkill => 'Ny färdighet';

  @override
  String get zoomIn => 'Zooma in';

  @override
  String get zoomOut => 'Zooma ut';

  @override
  String get resetZoom => 'Återställ zoom';

  @override
  String get imageHostedOnGitHub => 'Bild hostad på GitHub';

  @override
  String get imageOpenExternally => 'Bild · öppna externt';

  @override
  String get memoryScopeAll => 'Alla omfång';

  @override
  String get memoryScopeWorkspace => 'Hela arbetsytan';

  @override
  String get memoryScopeFilterLabel => 'Filtrera efter omfång';

  @override
  String memoryScopeRepoTooltip(String repo) {
    return 'Begränsad till arkivet $repo';
  }

  @override
  String get toolScreenshot => 'Skärmbild från agenten';

  @override
  String get toolImageUnavailable => 'Bild otillgänglig';

  @override
  String toolImagesUnavailable(int count) {
    return '$count bilder otillgängliga';
  }

  @override
  String get shakeUnavailable => 'Skakning saknas på den här servern';

  @override
  String get shakeNothing => 'Inget att skaka ut – senaste turerna är skyddade';

  @override
  String shakeDone(int tokens) {
    return 'Frigjorde ungefär $tokens tokens';
  }

  @override
  String get compactionDivider => 'Kompakterad';

  @override
  String compactionDividerCount(int count) {
    return 'Kompakterad · $count meddelanden vikta';
  }

  @override
  String get composerDropToAttach => 'Släpp för att bifoga';

  @override
  String get attachmentUnavailable => 'Bilaga otillgänglig';

  @override
  String get attachmentUnavailableDetail =>
      'Den här bilagan hålls inte längre i minnet. Bifoga den igen för att förhandsgranska den.';

  @override
  String get attachmentPreviewFailed => 'Kunde inte öppna den här filen';

  @override
  String get attachmentPreviewUnsupported =>
      'Ingen förhandsgranskning för den här filtypen';

  @override
  String get attachmentTooLargeToPreview => 'För stor att förhandsgranska';

  @override
  String get attachmentOpenExternally => 'Öppna i standardappen';

  @override
  String get asideUnavailable =>
      'Sätt en engångsmodell i arbetsyteinställningarna för att använda det här';

  @override
  String get asideEmpty => 'Inget att arbeta från ännu';

  @override
  String get asideFailed => 'Kunde inte få ett svar';

  @override
  String get handoffTitle => 'Överlämning';

  @override
  String get asideTitle => 'Sidfråga';

  @override
  String get attachFilesOrDrop => 'Bifoga filer – eller släpp dem här';

  @override
  String get guidedGoalTitle => 'Skärp målet';

  @override
  String get guidedGoalIntro =>
      'En agent som arbetar utan tillsyn behöver veta exakt när den är klar. Några frågor först.';

  @override
  String get guidedGoalAnswerHint => 'Ditt svar';

  @override
  String get guidedGoalNext => 'Nästa';

  @override
  String get guidedGoalStart => 'Starta målet';

  @override
  String get guidedGoalSkip => 'Hoppa över och kör som det är skrivet';

  @override
  String guidedGoalStillMissing(String items) {
    return 'Fortfarande ospecificerat: $items';
  }

  @override
  String get conversationTreeTitle => 'Samtalsträd';

  @override
  String conversationTreeBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grenar',
      one: '1 gren',
    );
    return '$_temp0';
  }

  @override
  String get conversationTreeSwitch => 'Fortsätt härifrån';

  @override
  String get conversationTreeFork => 'Förgrena till ett nytt samtal';

  @override
  String get conversationTreeCurrent => 'På den här grenen';

  @override
  String get conversationTreeEmpty => 'Inget här ännu';

  @override
  String get conversationTreeForked => 'Förgrenad till ett nytt samtal';

  @override
  String get conversationTreeSwitched => 'Fortsätter nu från det meddelandet';

  @override
  String exportSaved(String path) {
    return 'Sparad till $path';
  }

  @override
  String get exportFailed => 'Kunde inte skriva exporten';

  @override
  String get contextCommandNoAgent =>
      'Ingen agent i det här samtalet, så det finns inget kontextfönster att öppna';

  @override
  String contextCommandNoSuchAgent(String name, String names) {
    return 'Ingen agent med namnet “$name” i det här samtalet. Prova: $names';
  }

  @override
  String get dumpCopied => 'Utskrift kopierad till urklipp';

  @override
  String get messageQueueHint =>
      'Fortsätt skriva för att köa uppföljande ändringar';

  @override
  String get steerNow => 'Styr';

  @override
  String get steeringQueueLabel => 'Köade styrningsmeddelanden';

  @override
  String get steeringDeliverUnavailable =>
      'Ingen körande agent kan ta det just nu – det stannar i kön.';

  @override
  String get reorderSteeringCard => 'Ändra ordning på köat meddelande';

  @override
  String get editSteeringCard => 'Redigera köat meddelande';

  @override
  String get deleteSteeringCard => 'Ta bort köat meddelande';

  @override
  String get steeringBadge => 'Styrd';

  @override
  String get settingsSandboxLabel => 'Sandlåda';

  @override
  String get sandboxExecGrantsTitle => 'Exekveringsbeviljanden';

  @override
  String get sandboxExecGrantsSubtitle =>
      'Program agenter får köra från sin arbetskopia av dina arkiv. Varje post godkändes av dig när sandlådan frågade.';

  @override
  String get sandboxExecGrantsEmpty =>
      'Inga beslut registrerade ännu. Du frågas första gången en agent behöver köra ett program från sin arbetskopia.';

  @override
  String get sandboxExecGrantRevoke => 'Återkalla';

  @override
  String get sandboxExecGrantAllowed => 'Tillåten';

  @override
  String get sandboxExecGrantBlocked => 'Blockerad';

  @override
  String get sandboxExecGrantRevokeConfirmTitle =>
      'Återkalla det här beslutet?';

  @override
  String get sandboxExecGrantRevokeConfirmBody =>
      'Du frågas igen nästa gång en agent behöver köra ett program från den här kopian.';

  @override
  String get repoScriptsTest => 'Testa';

  @override
  String get repoScriptsTestTooltip =>
      'Kör det här utkastet i en tillfällig klon av arkivet';

  @override
  String get repoScriptsRunKindTest => 'Test';

  @override
  String get demoBadgeLabel => 'Demo';

  @override
  String get demoFilePickerTitle => 'Demofiler';

  @override
  String get demoFilePickerBody =>
      'Demon fejkar uppladdningar: välj vilken som helst av de här så bifogas den till ditt meddelande utan att röra en disk.';

  @override
  String get demoFilePickerAttach => 'Bifoga';

  @override
  String get demoReadOnlySave => 'Skrivskyddad i demon';

  @override
  String get demoBadgeTooltip =>
      'Du utforskar en demo. Datat är fiktivt och agenterna är skriptade.';

  @override
  String get demoFirstRunTitle => 'Du är i en livedemo';

  @override
  String demoFirstRunBody(int minutes) {
    return 'Det här är den riktiga appen som körs på riktig kod – bara datat är påhittat. Agenter strömmar genuina körningar från ett skript, så ingenting når en modell och ingenting körs på en maskin. Din arbetsyta är bara din och försvinner efter $minutes minuter.';
  }

  @override
  String get demoFirstRunDismiss => 'Uppfattat';

  @override
  String get demoTourTitle => 'Var du ska titta först';

  @override
  String get demoTourSubtitle =>
      'Fyra ställen som visar vad appen faktiskt gör.';

  @override
  String get demoTourSkip => 'Hoppa över';

  @override
  String get demoTourStarRepo => 'Stjärnmärk på GitHub';

  @override
  String get demoTourOpen => 'Öppna';

  @override
  String get demoTourSpacesTitle => 'Prata med en agent';

  @override
  String get demoTourSpacesBody =>
      'Skicka ett meddelande i en yta och se en körning strömma in – tänkande, verktygsanrop och kostnad, precis som en riktig körning ritas.';

  @override
  String get demoTourReviewTitle => 'Granska en pull request';

  @override
  String get demoTourReviewBody =>
      'Öppna #412. Lämna en radkommentar eller skicka in en granskning; dina ord landar i tråden och stannar där.';

  @override
  String get demoTourTicketsTitle => 'Följ arbetet';

  @override
  String get demoTourTicketsBody =>
      'Ärenden, att-göra och planer är länkade till samma samtal som agenterna har.';

  @override
  String get demoTourInboxTitle => 'Se hela operationen';

  @override
  String get demoTourInboxBody =>
      'Varje avisering från varje pelare landar i en inkorg – granskningar, ärenden, körningar och möten.';

  @override
  String get demoUnavailableTitle => 'Inte tillgängligt i demon';

  @override
  String get demoUnavailableTerminal =>
      'En terminal kör ett riktigt skal på servervärden. Demon har ingen körningsyta alls – det är det som gör den säker att öppna för allmänheten.';

  @override
  String get demoUnavailableRig =>
      'En avskild miljö är en tillfällig virtuell maskin som en agent kör. Demon startar inga: en publik endpoint som kan starta en VM är inte en demo.';

  @override
  String get demoUnavailableEditor =>
      'Webbläsarredigeraren kör en code-server-process mot en riktig checkout. Demon har ingetdera.';

  @override
  String get demoUnavailableFeeds =>
      'Demon läser riktiga flöden, men dess prenumerationslista är fast. Att lägga till eller ta bort ett är inaktiverat här.';

  @override
  String get demoUnavailableForge =>
      'Demon håller inga inloggningsuppgifter och kontaktar aldrig GitHub, GitLab eller Linear. Dess pull requests är fixtures, och dina kommentarer på dem lagras lokalt.';

  @override
  String get demoUnavailableModels =>
      'Demon anropar ingen modell. Agentkörningar är skriptad uppspelning, vilket är varför de inte kostar något och inte når någon leverantör.';

  @override
  String get demoUnavailableMcp =>
      'MCP-verktygsytan är inte monterad på demon, så ingen extern klient kan ansluta till den.';

  @override
  String get demoUnavailableRepos =>
      'Demon checkar inte ut kod och kör ingen git. Arkivet du ser är en fixture bakom pull requests.';

  @override
  String get demoUnavailableSkills =>
      'Att installera en färdighet hämtar och skannar kod. Demon hämtar ingenting.';

  @override
  String get demoUnavailableSso =>
      'Enkel inloggning är serverkonfiguration. Demon loggar in dig som en tillfällig gäst i stället.';

  @override
  String get demoUnavailableAudio =>
      'Inspelning och diktering behöver ljudupptagning och en talmodell på värden. Demon skeppar ingetdera, så dess möten är utskrifter utan uppspelning.';

  @override
  String get demoUnavailableServerAdmin =>
      'Det här är serveradministration. Demon ger varje besökare en egen tillfällig arbetsyta och ingenting bortom den.';

  @override
  String get settingsBackupRestore => 'Säkerhetskopiering och återställning';

  @override
  String get settingsBackupRestoreDescription =>
      'Ögonblicksbilder av varje databas på den här servern, plus export, import och borttagning för en enskild arbetsyta.';

  @override
  String get backupSnapshotsLabel => 'Installationsögonblicksbilder';

  @override
  String get backupSnapshotsExplainer =>
      'En ögonblicksbild kopierar varje databas till en tidsstämplad mapp på servervärden. Att återställa en hel installation betyder att kopiera tillbaka den mappen med servern stoppad; en enskild arbetsyta kan återställas härifrån.';

  @override
  String get backupNowAction => 'Säkerhetskopiera nu';

  @override
  String backupSnapshotWritten(String path) {
    return 'Ögonblicksbild skriven till $path';
  }

  @override
  String get backupNoSnapshots =>
      'Inga ögonblicksbilder ännu. En tas bara när du ber om den – ingenting är schemalagt.';

  @override
  String get backupSnapshotComplete => 'Komplett';

  @override
  String get backupSnapshotIncomplete => 'Ofullständig';

  @override
  String get backupSnapshotIncompleteNote =>
      'Manifestet saknas eller namnger filer som inte finns, så den här ögonblicksbilden kan inte återställa hela installationen. Arbetsytefilerna den har kan fortfarande antas en i taget.';

  @override
  String backupSnapshotWorkspaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arbetsytor',
      one: '1 arbetsyta',
      zero: 'Inga arbetsytor',
    );
    return '$_temp0';
  }

  @override
  String backupSnapshotSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arbetsytor inte fångade',
      one: '1 arbetsyta inte fångad',
    );
    return '$_temp0';
  }

  @override
  String get backupServerPathLabel => 'Sökväg på servern';

  @override
  String get backupRestoreAction => 'Återställ';

  @override
  String get backupRestoreTitle => 'Återställ arbetsyta';

  @override
  String backupRestoreBody(String name) {
    return 'Det här ersätter allt i $name med kopian i den här ögonblicksbilden. Vad den arbetsytan har gjort sedan ögonblicksbilden togs går förlorat, och det går inte att ångra.';
  }

  @override
  String backupRestoreDone(String name) {
    return 'Återställde $name från ögonblicksbilden.';
  }

  @override
  String get backupWorkspaceUnknown => 'Inte på den här servern längre';

  @override
  String get backupWorkspaceDataLabel => 'Arbetsytedata';

  @override
  String get backupWorkspaceDataExplainer =>
      'En arbetsyta är en databasfil, så att exportera den kopierar den filen i stället för att dumpa tabell för tabell. Import ersätter allt i målarbetsytan med filen du namnger.';

  @override
  String get backupExportAction => 'Exportera';

  @override
  String backupExportDone(String path) {
    return 'Exporterad till $path';
  }

  @override
  String get backupExportedFileLabel => 'Exporterad fil på servern';

  @override
  String get backupImportAction => 'Importera';

  @override
  String backupImportTitle(String name) {
    return 'Importera till $name';
  }

  @override
  String backupImportBody(String name) {
    return 'Det här ersätter allt i $name med innehållet i filen. Vad den arbetsytan håller nu går förlorat, och det går inte att ångra.';
  }

  @override
  String get backupImportSourceLabel => 'Arbetsytans databasfil';

  @override
  String get backupImportSourceDescription =>
      'En .db-fil servern kan läsa. Sökvägar löses på servervärden, inte på den här enheten.';

  @override
  String backupImportDone(String name) {
    return 'Importerad till $name.';
  }

  @override
  String backupDeleteBody(String name) {
    return '$name försvinner från varje lista och uppslag. Dess databasfil stannar på disk, säkerhetskopior tar fortfarande med den, och ingenting återtar utrymmet automatiskt.';
  }

  @override
  String get backupExportDescription =>
      'Skriv en kopia på servern, eller hämta en till den här enheten.';

  @override
  String get backupExportOnServerAction => 'Spara på servern';

  @override
  String get backupDownloadAction => 'Hämta';

  @override
  String backupDownloadSaved(String path) {
    return 'Sparad till $path';
  }

  @override
  String get backupDownloadInBrowser => 'Webbläsaren hämtar den.';

  @override
  String get backupRestoreFromDeviceLabel => 'Återställ från den här enheten';

  @override
  String get backupRestoreFromDeviceDescription =>
      'Välj en arbetsytedatabasfil här så laddar Control Center upp den till servern. Det här är den som fungerar när servern inte är den här maskinen.';

  @override
  String get backupUploadAction => 'Välj en fil och ladda upp';

  @override
  String get backupTransferUnavailable =>
      'Den här anslutningen når servern via ett relä, som inte bär filöverföringar. Anslut till servern direkt för att hämta eller ladda upp en säkerhetskopia.';

  @override
  String get backupTransferForbidden =>
      'Servern vägrade. Att hämta en arbetsyta kräver adminrollen, att återställa en kräver ägare, och en hel ögonblicksbild kräver installationens operatör.';

  @override
  String get backupTransferUnsupported =>
      'Den här servern har ingen säkerhetskopieringsyta.';

  @override
  String get backupTransferTooLarge => 'Filen är större än servern accepterar.';

  @override
  String get credentialGateWaitingTitle => 'Väntar på inloggningsuppgifter';

  @override
  String credentialGateHarnessTitle(String provider) {
    return '$provider har inga inloggningsuppgifter';
  }

  @override
  String get credentialGateSignedOutTitle => 'Claude Code är utloggad';

  @override
  String get credentialGateExpiredTitle =>
      'Din Claude Code-inloggning har gått ut';

  @override
  String get credentialGatePlanSpentTitle => 'Claude Code-plangränsen är nådd';

  @override
  String credentialGateWaitingAgent(String agent) {
    return '$agent väntar på att fortsätta.';
  }

  @override
  String get credentialGateWaitingRun => 'En körning väntar på att fortsätta.';

  @override
  String get credentialGateWatching =>
      'Bevakar åtgärden – körningen fortsätter av sig själv.';

  @override
  String credentialGateFreesUpAt(String time) {
    return 'Frigörs $time';
  }

  @override
  String credentialGateGivesUpAt(String time) {
    return 'Körningen ger upp $time';
  }

  @override
  String get credentialGateCheckAgain => 'Kontrollera igen';

  @override
  String get credentialGateCancelRun => 'Avbryt körning';

  @override
  String get credentialGateAccountsTried => 'Konton som prövats';

  @override
  String get credentialGateClaudeSignInHint =>
      'Logga in från Inställningar → Adaptrar → Claude Code, eller kör inloggningskommandot i en terminal. Körningen tar upp det av sig själv.';

  @override
  String get credentialGateOpenSettings => 'Öppna inställningar';

  @override
  String get selectModel => 'Välj modell';

  @override
  String get allModels => 'Alla modeller';

  @override
  String get noModelsMatchSearch => 'Inga modeller matchar din sökning';

  @override
  String useCustomModelId(String id) {
    return 'Använd ”$id”';
  }

  @override
  String get modelFree => 'Gratis';

  @override
  String modelOutputTokens(String tokens) {
    return '$tokens utdata';
  }

  @override
  String modelPricePerMTokens(String input, String output) {
    return '$input indata / $output utdata per 1M tokens';
  }

  @override
  String modelEffortLevels(String levels) {
    return 'Resonemangsinsats: $levels';
  }

  @override
  String get modelSupportsReasoning => 'Stöder resonemangsinsats';

  @override
  String get profileDeliveryMetrics => 'Leveransmått';

  @override
  String profileMetricsSample(int count) {
    return 'Analyserade PR: $count';
  }

  @override
  String get profileMergeRate => 'Sammanslagningsgrad';

  @override
  String get profileReviewCoverage => 'Granskningsgrad';

  @override
  String get profilePrSize => 'PR-storlek';

  @override
  String get profileTimeToMerge => 'Tid till sammanslagning';

  @override
  String get profileMergeTimeTrend => 'Trend för sammanslagningstid';

  @override
  String get profileWeeklyMedian => 'Veckomedian, logaritmisk skala';

  @override
  String get profilePrOpeningPattern => 'Veckodag × timme, lokal tid';

  @override
  String get profileFirstReview => 'Tid till första granskning';

  @override
  String get profileMetricsTruncated =>
      'Percentilerna använder ett begränsat urval av de tillgängliga pull-begärandena.';

  @override
  String profileLinesChanged(String count) {
    return '$count rader';
  }

  @override
  String profileDurationMinutes(int count) {
    return '$count min';
  }

  @override
  String profileDurationHours(int count) {
    return '$count tim';
  }

  @override
  String profileDurationDaysHours(int days, int hours) {
    return '$days d $hours tim';
  }

  @override
  String profilePercentiles(String median, String p90) {
    return 'p50 $median · p90 $p90';
  }

  @override
  String profileTeamMembers(int count) {
    return 'Medlemmar: $count';
  }

  @override
  String noPrsByTeamInWorkspace(String team) {
    return 'Inga pull request-begäranden från $team i den här arbetsytan';
  }

  @override
  String get profilePrStateFilterLabel =>
      'Filtrera pull request-begäranden efter status';

  @override
  String get noProfilePrsMatchSearchHint =>
      'Prova en annan titel eller ett annat pull request-nummer';

  @override
  String get rigNetworkUnrestricted => 'Nätverk utan begränsningar';

  @override
  String get rigNetworkAllowAllHosts => 'Tillåt alla värdar';

  @override
  String get rigNetworkBypassTitle => 'Vill du tillåta alla nätverksvärdar?';

  @override
  String get rigNetworkBypassBody =>
      'Detta startar om den isolerade miljön och tar bort arbete som inte har checkats in. Gästen kan därefter nå alla nätverksvärdar tills miljön stängs.';

  @override
  String get rigNetworkRestartUnrestricted => 'Starta om utan begränsningar';

  @override
  String get rigNetworkUnrestrictedBody =>
      'Den här isolerade miljön kan nå alla nätverksvärdar. Stäng den och öppna en ny för att återställa standardbegränsningarna.';

  @override
  String get rigNetworkAlreadyUnrestrictedBody =>
      'Den här Android-emulatorn hanterar redan sitt eget nätverk, så Control Center kan inte tillämpa en lista över tillåtna värdar. Ingen omstart behövs.';

  @override
  String get rigClipboardPermissionHostToRigTitle =>
      'Klistra in urklipp i den här miljön?';

  @override
  String get rigClipboardPermissionHostToRigBody =>
      'Control Center läser urklipp på din enhet och skickar innehållet till miljön. Urklippsinnehåll kan innehålla lösenord eller andra hemligheter.';

  @override
  String get rigClipboardPermissionRigToHostTitle =>
      'Kopiera urklipp från den här miljön?';

  @override
  String get rigClipboardPermissionRigToHostBody =>
      'Control Center läser urklipp i miljön och ersätter urklipp på din enhet med dess innehåll. Behandla innehåll från miljön som opålitligt.';

  @override
  String get rigClipboardAllowTenMinutes => 'Tillåt i 10 minuter';

  @override
  String get rigClipboardAlwaysAllow => 'Tillåt alltid';

  @override
  String get rigClipboardSettingsTitle => 'Urklippsåtkomst';

  @override
  String get rigClipboardSettingsHint =>
      'Välj vilka urklippsöverföringar som kan köras utan att fråga. Tillfälliga behörigheter upphör efter 10 minuter.';

  @override
  String get rigClipboardAlwaysPasteTitle =>
      'Tillåt alltid inklistring i miljöer';

  @override
  String get rigClipboardAlwaysPasteDescription =>
      'Skicka urklipp från den här enheten till valfri miljö utan att fråga.';

  @override
  String get rigClipboardAlwaysCopyTitle =>
      'Tillåt alltid kopiering från miljöer';

  @override
  String get rigClipboardAlwaysCopyDescription =>
      'Lägg urklippsinnehåll från valfri miljö på den här enheten utan att fråga.';
}
