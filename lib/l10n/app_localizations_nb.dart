// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Bokmål (`nb`).
class AppLocalizationsNb extends AppLocalizations {
  AppLocalizationsNb([String locale = 'nb']) : super(locale);

  @override
  String get succeeded => 'Lyktes';

  @override
  String agentRunRetryLabel(int number, String time) {
    return 'Prøv på nytt #$number · $time';
  }

  @override
  String agentRunStarting(String time) {
    return 'Starter · $time';
  }

  @override
  String get agentActivityFollowingLive => 'Følger live-aktivitet';

  @override
  String get agentActivityJumpToLatest => 'Hopp til siste';

  @override
  String get agentActivityLoadFailed =>
      'Kunne ikke laste aktiviteten for denne kjøringen';

  @override
  String get agentActivityNotRecorded =>
      'Ingen aktivitet ble registrert for denne kjøringen';

  @override
  String get agentActivityNotRecordedHint =>
      'Kjøringer som ble ferdige før aktivitetsopptak var slått på, har ingen tidslinje.';

  @override
  String get agentActivityRunUnavailable =>
      'Denne kjøringen er ikke lenger tilgjengelig';

  @override
  String agentActivitySubagentOf(String agent) {
    return 'Underagent av $agent';
  }

  @override
  String get agentActivityUnsupported =>
      'Aktivitetsopptak er ikke tilgjengelig på den tilkoblede serveren';

  @override
  String get agentActivityUnsupportedHint =>
      'Start appen på nytt slik at den henter den nyeste serverbyggingen.';

  @override
  String get agentActivityWaiting => 'Venter på aktivitet…';

  @override
  String get created => 'Opprettet';

  @override
  String get dictationStart => 'Start diktering';

  @override
  String get dictationListening => 'Lytter…';

  @override
  String get dictationUnavailable =>
      'Diktering trenger en stemmemodell på serververten. Sett opp én i stemmeinnstillingene.';

  @override
  String get dictationFailedToStart => 'Kunne ikke starte diktering';

  @override
  String get dictationHoldToTalkTitle => 'Hold for å snakke';

  @override
  String get dictationHoldToTalkDescription =>
      'Hold mikrofonknappen eller snarveien for å diktere, og slipp for å stoppe. Når det er av, trykk én gang for å starte og igjen for å stoppe.';

  @override
  String get focusConversation => 'Fokuser samtale';

  @override
  String get ideAgentActivity => 'Agentaktivitet';

  @override
  String get keybindingPushToTalk => 'Trykk for å snakke';

  @override
  String get keybindingPushToTalkDescription =>
      'Hold eller slå av/på stemmediktering i meldingsfeltet';

  @override
  String get agentPermissions => 'Agenttillatelser';

  @override
  String get agentPermissionsSettingsDescription =>
      'Bestem hva agenter kan gjøre selv, må spørre om først, eller aldri kan gjøre — per arbeidsområde, agent eller område.';

  @override
  String get agentPermissionsMatrixDescription =>
      'Sett et vedtak for hver type effekt. Regler kaskader: område overstyrer agent overstyrer arbeidsområde overstyrer modusforhåndsvalg. Den mest spesifikke regelen vinner.';

  @override
  String get guardrailLoading => 'Laster regler…';

  @override
  String get guardrailRulesLoadFailed => 'Kunne ikke laste tillatelsesreglene.';

  @override
  String get guardrailScopeWorkspace => 'Arbeidsområde';

  @override
  String get guardrailScopeAgent => 'Agent';

  @override
  String get guardrailScopeSpace => 'Område';

  @override
  String get guardrailSelectAgent => 'Velg en agent';

  @override
  String get guardrailSelectSpace => 'Velg et område';

  @override
  String get guardrailNoAgents => 'Ingen agenter i dette arbeidsområdet ennå.';

  @override
  String get guardrailNoSpaces => 'Ingen områder i dette arbeidsområdet ennå.';

  @override
  String get guardrailClassFileDelete => 'Slett en fil';

  @override
  String get guardrailClassFileWriteOutsideWorktree => 'Skriv utenfor worktree';

  @override
  String get guardrailClassGitCommit => 'Opprett en commit';

  @override
  String get guardrailClassGitPush => 'Push til en remote';

  @override
  String get guardrailClassPrCreate => 'Åpne en pull request';

  @override
  String get guardrailClassPrPublish =>
      'Publiser en gjennomgang eller sammenslåing';

  @override
  String get guardrailClassVendorSyncWrite =>
      'Skriv til et eksternt oppfølgingssystem';

  @override
  String get guardrailClassNetworkEgress => 'Bruk nettverket';

  @override
  String get guardrailClassSecretAccess => 'Les en hemmelighet';

  @override
  String get guardrailClassPackageInstall => 'Installer en pakke';

  @override
  String get guardrailClassProcessSpawn => 'Kjør en prosess';

  @override
  String get guardrailClassWorkspaceMutation =>
      'Endre strukturen på arbeidsområdet';

  @override
  String get guardrailClassEnclosureControl =>
      'Styre et isolert miljø (stasjon)';

  @override
  String get navRigs => 'Stasjoner';

  @override
  String get rigsUnsupportedServer =>
      'Denne serveren kan ikke være vert for noen rig-overflater. Sjekk vertskravene for maskinen du vil bruke.';

  @override
  String get rigSurfaceComputer => 'Datamaskin';

  @override
  String get rigSurfaceBrowser => 'Nettleser';

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
    return 'En engangs-$engine, isolert fra maskinen din. Åpne en annen motor for å sammenligne samme side side om side.';
  }

  @override
  String get rigPhaseReady => 'Klar';

  @override
  String get rigPhaseStarting => 'Starter';

  @override
  String get rigPhaseParked => 'Parkert';

  @override
  String get rigPhaseClosing => 'Lukker';

  @override
  String get rigPhaseClosed => 'Lukket';

  @override
  String get rigPhaseFailed => 'Mislyktes';

  @override
  String get rigPhaseUnknown => 'Ukjent';

  @override
  String get rigNotAccelerated => 'Emulert';

  @override
  String get rigAudioListen => 'Lytt til maskinen';

  @override
  String get rigAudioMute => 'Demp maskinen';

  @override
  String get rigYouHaveControl => 'Du har kontroll';

  @override
  String get rigBackendAvailable => 'Tilgjengelig';

  @override
  String get rigBackendUnavailable => 'Utilgjengelig';

  @override
  String get rigEgressNotEnforced =>
      'Nettverket er ikke isolert på denne backend-en — den styrer tilkoblingen selv.';

  @override
  String get rigStartMachine => 'Start maskinen';

  @override
  String get rigStartHint =>
      'Starter en engangs-VM som du og agentene dine deler for denne samtalen. Den slettes når den lukkes, og ingenting i den rører datamaskinen din.';

  @override
  String get rigStartAndroidHint =>
      'Kobler til en Android-emulator som allerede kjører på serveren. Nettverkstilgangen er ikke isolert.';

  @override
  String get rigStartIosHint =>
      'Oppretter en midlertidig iOS-simulator på en macOS-server. Den slettes når testmiljøet lukkes; nettverkstilgangen er ikke isolert.';

  @override
  String get rigTechnicalDetails => 'Tekniske detaljer';

  @override
  String get rigStopMachine => 'Stopp maskinen';

  @override
  String get rigHomeButton => 'Hjem';

  @override
  String get rigRotateClockwise => 'Roter med klokken';

  @override
  String get rigRotateCounterclockwise => 'Roter mot klokken';

  @override
  String get rigTakeScreenshot => 'Ta et skjermbilde';

  @override
  String get rigScreenshotSaved => 'Skjermbildet er lagret';

  @override
  String rigScreenshotSaveFailed(String error) {
    return 'Kunne ikke lagre skjermbildet: $error';
  }

  @override
  String get rigSurfaceUnavailable =>
      'Denne serveren kan ikke kjøre denne typen maskin.';

  @override
  String get rigTabNeedsConversation =>
      'Åpne en samtale først — en maskin tilhører én, slik at du og agentene dine ser samme skjerm.';

  @override
  String get ideMenuSectionTools => 'Verktøy';

  @override
  String get ideMenuSectionMachines => 'Maskiner';

  @override
  String get ideMenuSectionReopen => 'Åpne på nytt';

  @override
  String get ideMenuSearchHint => 'Søk';

  @override
  String get ideMenuNoMatches => 'Ingen treff';

  @override
  String get rigMenuComputer => 'Datamaskin';

  @override
  String get rigMenuBrowser => 'Nettleser';

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
    return 'Lukk $name?';
  }

  @override
  String get ideCloseKeepBodyMachine =>
      'Maskinen fortsetter i bakgrunnen — åpne den når som helst fra sidestolpen. Slå den av i stedet for å frigjøre minnet nå.';

  @override
  String get ideCloseKeepBodyShell =>
      'Kommandoen fortsetter i bakgrunnen — åpne skallet når som helst fra sidestolpen. Avslutt den i stedet for å stoppe det den gjør nå.';

  @override
  String get ideCloseKeepBodyAgent =>
      'Agenten fortsetter i bakgrunnen — åpne samtalen når som helst fra sidestolpen. Stopp den i stedet for å avslutte kjøringen nå.';

  @override
  String get ideCloseKeepRunning => 'Fortsett å kjøre';

  @override
  String get ideCloseShutDownMachine => 'Slå av';

  @override
  String get ideCloseEndShell => 'Avslutt skall';

  @override
  String get ideCloseStopAgent => 'Stopp agent';

  @override
  String get rigsSettingsSubtitle =>
      'Hva denne serveren kan starte, basisbildene den trenger, og maskinene som kjører nå';

  @override
  String get rigsCapabilitiesTitle => 'Denne serveren';

  @override
  String get rigInstallIosAutomation => 'Installer bro for iOS-automatisering';

  @override
  String get rigInstallingIosAutomation =>
      'Installerer bro for iOS-automatisering…';

  @override
  String get rigIosAutomationInstalled =>
      'Bro for iOS-automatisering er installert';

  @override
  String get rigsImagesTitle => 'Basisbilder';

  @override
  String get rigsImagesHint =>
      'Hver stasjon starter fra ett av disse skrivebeskyttede bildene. Hver økt skriver til et engangs-overlay, så én stasjon kan aldri endre det den neste starter fra.';

  @override
  String get rigsRunningTitle => 'Kjører nå';

  @override
  String get rigsNoneRunning => 'Ingen maskiner kjører.';

  @override
  String get rigsCustomImagesTitle => 'Egne bilder (dette arbeidsområdet)';

  @override
  String get rigsCustomImagesHint =>
      'Pek Terminal (VM) eller Nettleser (VM) mot ditt eget bilde — utvid standardene med verktøyene prosjektet trenger, eller bruk et kompatibelt fra et register. Nye maskiner bruker det; kjørende beholder sitt. Se stasjonsveiledningen for hva et bilde må tilby.';

  @override
  String get rigsCustomTerminalImageLabel => 'Terminal (VM)-bilde';

  @override
  String get rigsCustomBrowserImageLabel => 'Nettleser (VM)-bilde';

  @override
  String get rigsCustomImagePlaceholder =>
      'f.eks. ghcr.io/acme/dev-shell:1.2 — la stå tomt for standard';

  @override
  String get rigsCustomImageInvalid =>
      'Skriv inn en registerreferanse som repo/name:tag. Lokale stier og arkiver er ikke tillatt.';

  @override
  String get rigsCustomImageSaved =>
      'Lagret. Nye maskiner starter med dette bildet; kjørende beholder sitt.';

  @override
  String get rigsEgressTitle => 'Nettleserutgang (dette arbeidsområdet)';

  @override
  String get rigsEgressHint =>
      'Ekstra verter den isolerte nettleseren kan nå — én per linje: en eksakt vert (api.example.com) eller et jokertegn for underdomener (*.example.com). Produktsiden er alltid tillatt. Nye maskiner får listen; kjørende beholder det de startet med.';

  @override
  String rigsEgressInvalid(String host) {
    return '«$host» er ikke en gyldig vertsoppføring.';
  }

  @override
  String get rigsEgressSaved =>
      'Lagret. Nye nettlesermaskiner tillater disse vertene; kjørende beholder sine.';

  @override
  String get rigImageInstalled => 'Installert';

  @override
  String get rigImageNotDownloaded => 'Ikke lastet ned';

  @override
  String get rigImageNotPublished => 'Ikke publisert';

  @override
  String get rigImageNotPublishedHint =>
      'Ingen bilde er publisert for dette ennå, så det er ingenting å laste ned. Importer et kompatibelt diskbilde for å slå det på.';

  @override
  String get rigImageDownload => 'Last ned';

  @override
  String get rigImageDownloading => 'Laster ned…';

  @override
  String get rigImageImport => 'Importer';

  @override
  String get rigImageImportMessage =>
      'Sti til et qcow2-diskbilde på serverens filsystem. Det kopieres inn i bildelageret, så filen kan flyttes etterpå.';

  @override
  String get rigConnectingStream => 'Kobler til stasjonen';

  @override
  String get rigStreamNotAllowed => 'Du har ikke tilgang til denne stasjonen.';

  @override
  String get rigStreamNotRunning => 'Denne stasjonen kjører ikke lenger.';

  @override
  String get rigStreamNeedsFfmpeg =>
      'Live-visning trenger ffmpeg på denne verten. Installer ffmpeg og åpne fanen på nytt.';

  @override
  String get rigStreamEnded => 'Live-visningen ble avsluttet.';

  @override
  String get rigStreamFailed => 'Live-visningen kunne ikke åpnes.';

  @override
  String get rigStreamDisconnected => 'Ikke tilkoblet en server.';

  @override
  String rigDropSendingOne(String name) {
    return 'Kopierer «$name» inn i maskinen…';
  }

  @override
  String rigDropSendingMany(int count) {
    return 'Kopierer $count filer inn i maskinen…';
  }

  @override
  String get rigTerminalDropSending => 'Kopierer inn i maskinen…';

  @override
  String get rigTerminalPasteImage => 'Innlimt bilde lagret i maskinen';

  @override
  String get rigPortsTitle => 'Videresendte porter';

  @override
  String get rigPortsTooltip => 'Porter som er åpne inne i denne maskinen';

  @override
  String get rigPortsEmpty =>
      'Ingenting lytter ennå. Start en server i terminalen — en utviklerserver på port 3000 vises her.';

  @override
  String get rigPortsAdd => 'Legg til port';

  @override
  String get rigPortsAddHint => 'Gjestport som skal videresendes (f.eks. 3000)';

  @override
  String get rigPortsAutoForward => 'Videresend porter automatisk';

  @override
  String get rigPortsCopyUrl => 'Kopier lokal URL';

  @override
  String rigPortsCopiedUrl(String url) {
    return 'Kopierte $url';
  }

  @override
  String get rigPortsStopForward => 'Stopp videresending';

  @override
  String get rigPortsExposeLan => 'Del på lokalt nettverk';

  @override
  String get rigPortsLanPrivate => 'Bare lokalt';

  @override
  String get rigPortsLanShared => 'På nettverket';

  @override
  String get rigPortsSetDomain => 'Sett et nettleserdomene (.test)';

  @override
  String get rigPortsDomainHint =>
      'Domene for Nettleser (VM), f.eks. myapp.test — nås der, ikke på verten';

  @override
  String get rigPortsProcessUnknown => 'ukjent prosess';

  @override
  String get rigPortsInactive => 'lytter ikke';

  @override
  String get rigPortsTooltipHost => 'Porter åpne i denne terminalen';

  @override
  String get rigPortsEmptyHost =>
      'Ingenting lytter i denne terminalen ennå. Start en server, så vises den her.';

  @override
  String get rigPortsAddHintHost => 'Port å mappe (f.eks. 5173)';

  @override
  String get rigPortsLocalPortHint => 'Lokal port (valgfritt)';

  @override
  String rigPortsDestDesktop(int port) {
    return 'localhost:$port';
  }

  @override
  String rigPortsDestBrowser(int port) {
    return 'localhost:$port i nettleseren (VM)';
  }

  @override
  String get rigPortsDestBrowserUnreachable => 'nettleser (VM) ikke tilkoblet';

  @override
  String rigPortsDestAndroid(int port) {
    return 'localhost:$port på Android';
  }

  @override
  String get rigPortsDestAndroidUnreachable => 'Android ikke tilkoblet';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count basisbilder gjenstår å laste ned',
      one: '1 basisbilde gjenstår å laste ned',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => 'Tillat';

  @override
  String get guardrailDecisionPrompt => 'Spør først';

  @override
  String get guardrailDecisionDeny => 'Nekt';

  @override
  String get guardrailSourceThisScope => 'Dette omfanget';

  @override
  String get guardrailSourceDefault => 'Innebygd standard';

  @override
  String get guardrailSourcePreset => 'Modusforhåndsvalg';

  @override
  String get guardrailSourceInherited => 'Arvet';

  @override
  String get guardrailClearToInherited => 'Tilbakestill til arvet';

  @override
  String get guardrailWhatIf => 'Hva om?';

  @override
  String get guardrailWhatIfDescription =>
      'Se hvordan gjeldende regler ville løst en handling, med samme logikk som agentene kjører mot.';

  @override
  String get guardrailProbeActionLabel => 'Handling';

  @override
  String get guardrailProbeCommandLabel => 'Kommando (valgfritt)';

  @override
  String get guardrailProbeCommandHint => 'f.eks. git push origin main';

  @override
  String get guardrailProbeAgentLabel => 'Agent (valgfritt)';

  @override
  String get guardrailProbeSpaceLabel => 'Område (valgfritt)';

  @override
  String get guardrailProbeNone => 'Ingen';

  @override
  String get guardrailProbeModeLabel => 'Modus';

  @override
  String get guardrailProbeResult => 'Resultat';

  @override
  String get guardrailProbeSource => 'Kilde:';

  @override
  String get guardrailAdapterMatrix => 'Hvor regler håndheves';

  @override
  String get guardrailAdapterMatrixDescription =>
      'Ærlig oversikt: hvor hver effekt faktisk fanges, per agentkjører. Dette dokumenterer virkeligheten, ikke en garanti — effekter en kjører utfører utenom båndet kan ikke avskjæres.';

  @override
  String get guardrailEffectColumn => 'Effekt';

  @override
  String get guardrailAdapterHarness => 'Innebygd harness';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => 'Sandkassegulv';

  @override
  String get guardrailEnforcementPolicyGate => 'Policyport';

  @override
  String get guardrailEnforcementSandbox => 'Bare sandkasse';

  @override
  String get guardrailEnforcementNone => 'Kan ikke håndheves';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      'Tillatelsesvedtaket sjekkes før effekten kjører og kan blokkere den.';

  @override
  String get guardrailEnforcementSandboxHelp =>
      'Bare sandkassen begrenser den; tillatelsesregelen brukes ikke.';

  @override
  String get guardrailEnforcementNoneHelp =>
      'Vedtaket er bare veiledende — det kan ikke avskjæres her.';

  @override
  String get obsStatCost => 'kostnad';

  @override
  String obsStatDelegatedCost(String amount) {
    return '+$amount delegert';
  }

  @override
  String get obsStatDuration => 'varighet';

  @override
  String get obsStatTokens => 'tokens';

  @override
  String get obsStatTools => 'verktøy';

  @override
  String get openAgentActivity => 'Åpne aktivitet';

  @override
  String get orgChart => 'Organisasjonskart';

  @override
  String get orgChartEmpty => 'Ingen agenter ennå';

  @override
  String get navCalendar => 'Kalender';

  @override
  String get serverConnection => 'Servertilkobling';

  @override
  String get serverModeLocal => 'Kjør i denne appen';

  @override
  String get serverModeLocalDescription =>
      'Control Center kjører sin egen server på denne maskinen og eier dataene dine lokalt.';

  @override
  String get serverModeRemote => 'Koble til en ekstern instans';

  @override
  String get serverModeRemoteDescription =>
      'Koble til en Control Center-server som kjører et annet sted. Dataene dine ligger på den serveren.';

  @override
  String get serverRemoteUrl => 'Server-URL';

  @override
  String get serverRemoteDeviceId => 'Enhets-id';

  @override
  String get serverRemotePairingKey => 'Paringsnøkkel';

  @override
  String get serverRemotePairingKeyHint =>
      'Lim inn paringsnøkkelen fra den eksterne serveren';

  @override
  String get serverSetupInviteCode => 'Invitasjonskode';

  @override
  String get serverSetupInviteCodeHint =>
      'Lim inn en engangskode (la stå tomt for å bruke paringsnøkkel)';

  @override
  String get serverDiscoveryTooltip => 'Finn servere på nettverket ditt';

  @override
  String get serverDiscoveryTitle => 'Servere på nettverket ditt';

  @override
  String get serverDiscoverySearching => 'Søker etter servere…';

  @override
  String get serverDiscoveryEmpty =>
      'Ingen servere funnet. Sjekk at serveren kjører og at denne enheten kan nå den, og søk på nytt.';

  @override
  String get serverDiscoveryRefresh => 'Søk på nytt';

  @override
  String get serverListActive => 'Aktiv';

  @override
  String get serverListSwitch => 'Bytt';

  @override
  String get serverListAddTitle => 'Legg til server';

  @override
  String get serverListRemoveActiveHint =>
      'Bytt til en annen server før du fjerner denne.';

  @override
  String get serverSwitchFailedTitle => 'Kunne ikke bytte server';

  @override
  String get serverListInsecureBadge => 'Usikker';

  @override
  String get connectionPathLocal => 'Lokal';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => 'Avslutter';

  @override
  String get shutdownSubtitle => 'Lukker den lokale serveren';

  @override
  String get shutdownServiceApprovals => 'Godkjenninger';

  @override
  String get shutdownServiceBackgroundJobs => 'Bakgrunnsjobber';

  @override
  String get shutdownServiceScheduler => 'Jobbplanlegger';

  @override
  String get shutdownServiceCalendar => 'Kalendersynkronisering';

  @override
  String get shutdownServiceWeather => 'Vær';

  @override
  String get shutdownServiceSoundscape => 'Lydlandskap';

  @override
  String get shutdownServiceMeetings => 'Møter';

  @override
  String get shutdownServiceVoiceModels => 'Stemmemodeller';

  @override
  String get shutdownServiceNetworking => 'Nettverk';

  @override
  String get shutdownServicePresence => 'Tilstedeværelse';

  @override
  String get shutdownServiceDataSync => 'Datasynkronisering';

  @override
  String get shutdownServiceDeviceRelay => 'Enhetsrelé';

  @override
  String get shutdownServiceMcpConnections => 'MCP-tilkoblinger';

  @override
  String get shutdownServiceCodeEditors => 'Koderedigerere';

  @override
  String get serverSharingTitle => 'Del denne serveren';

  @override
  String get serverSharingDescription =>
      'Gjør denne serveren tilgjengelig fra de andre enhetene dine. Ingenting eksponeres offentlig med mindre du slår på en tunnel nedenfor. Paringsinvitasjoner tar med serverens gjeldende adresser automatisk — opprett dem under innstillinger for arbeidsområde.';

  @override
  String get serverSharingUnavailable =>
      'Delingskontroller er ikke tilgjengelige på denne serveren.';

  @override
  String get serverSharingMdnsLabel => 'LAN-oppdagelse';

  @override
  String get serverSharingMdnsOn =>
      'Annonserer denne serveren på det lokale nettverket (mDNS)';

  @override
  String get serverSharingMdnsOff =>
      'Annonserer ikke på det lokale nettverket (mDNS)';

  @override
  String get serverSharingTunnelLabel => 'Tunnel';

  @override
  String get serverSharingTunnelHelper =>
      'Å slå på en tunnel gjør denne serveren tilgjengelig fra internett. Offentlig eksponering er valgfritt og av som standard.';

  @override
  String get serverSharingProviderOff => 'Av';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => 'Offentlig URL';

  @override
  String get serverSharingTunnelStarting => 'Starter tunnelen…';

  @override
  String serverSharingTunnelError(String error) {
    return 'Tunnelfeil: $error';
  }

  @override
  String get serverSharingTunnelUpNoUrl =>
      'Tunnelen er oppe. Nå den på det konfigurerte DNS-vertsnavnet.';

  @override
  String get serverSharingRelayLabel => 'Relé';

  @override
  String serverSharingRelayUsage(String amount) {
    return 'Reléert denne måneden: $amount';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return 'Aktive reléøkter: $count';
  }

  @override
  String get serverSharingUpdateFailedTitle => 'Kunne ikke oppdatere deling';

  @override
  String get pairNewClient => 'Par en ny klient';

  @override
  String get pairClientNameHint => 'Gi klienten et navn (f.eks. Jobb-laptop)';

  @override
  String get pairClientTypeWeb => 'Nettleser';

  @override
  String get pairClientTypeDesktop => 'Skrivebordsapp';

  @override
  String get pairClientTypePhone => 'Telefon';

  @override
  String get pairAction => 'Par';

  @override
  String get revoke => 'Tilbakekall';

  @override
  String get pairCredentialsIntro =>
      'Koble den nye klienten med disse opplysningene, eller åpne lenken i den.';

  @override
  String get pairLinkLabel => 'Lenke';

  @override
  String get pairScanQr =>
      'Skann denne QR-koden med telefonens kamera for å pare den.';

  @override
  String get pairServerUnreachableTitle => 'Ikke tilgjengelig';

  @override
  String get pairServerUnreachable =>
      'Andre enheter kan ikke nå denne serveren direkte, så en ny klient kan ikke koble til. Sett serverens offentlige URL for å pare flere klienter.';

  @override
  String get serverSetupTitle => 'Hvordan skal Control Center kjøre?';

  @override
  String get serverSetupSubtitle =>
      'Control Center trenger en server som eier dataene dine. Kjør én inne i denne appen, eller koble til en instans som kjører et annet sted.';

  @override
  String get serverSetupRunLocal => 'Kjør i denne appen';

  @override
  String get serverSetupConnect => 'Koble til';

  @override
  String get serverSetupInvalidUrl =>
      'Skriv inn en gyldig ws://- eller wss://-server-URL.';

  @override
  String get serverSetupCouldNotConnect => 'Kunne ikke koble til';

  @override
  String get serverSetupErrorUnreachable =>
      'Vi nådde ikke serveren. Sjekk at den kjører og at denne enheten kan nå den (samme nettverk eller relé).';

  @override
  String get serverSetupErrorIdentityMismatch =>
      'Serverens identitet samsvarer ikke med den som er lagret på denne enheten. Hvis serveren ble installert på nytt eller tilbakestilt, fjern den lagrede serveren og par på nytt.';

  @override
  String get serverSetupErrorAuthRejected =>
      'Serveren avviste denne enheten. Sjekk at paringsnøkkelen og enhets-id samsvarer med det serveren utstedte.';

  @override
  String get serverSetupErrorInviteRejected =>
      'Den invitasjonskoden er ugyldig eller har utløpt. Be om en ny.';

  @override
  String get serverSetupErrorGeneric =>
      'Noe gikk galt under tilkoblingen. Utvid de tekniske detaljene nedenfor for mer informasjon.';

  @override
  String get serverSetupErrorDetails => 'Tekniske detaljer';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count til',
      one: '1 til',
    );
    return '$_temp0';
  }

  @override
  String get calendarAllDayGutter => 'Heldags';

  @override
  String calendarAllDayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hendelser',
      one: '1 hendelse',
    );
    return '$_temp0';
  }

  @override
  String get calendarCollapseAllDay => 'Skjul heldagshendelser';

  @override
  String get calendarExpandAllDay => 'Vis heldagshendelser';

  @override
  String get calendarViewMonth => 'Måned';

  @override
  String get calendarViewWeek => 'Uke';

  @override
  String get calendarViewAgenda => 'Agenda';

  @override
  String get calendarConnectGoogle => 'Koble til Google Calendar';

  @override
  String get calendarConnectDescription =>
      'Synkroniser Google Calendar for å se hendelser her og få varsler før møter starter.';

  @override
  String get calendarDisconnect => 'Koble fra';

  @override
  String get calendarReconnect => 'Koble til på nytt';

  @override
  String get calendarEmptyNoEvents => 'Ingen hendelser i dette intervallet';

  @override
  String get calendarStartRecording => 'Start opptak';

  @override
  String get calendarStartRecordingAndLink => 'Start opptak og knytt';

  @override
  String get calendarJoinMeet => 'Bli med i møte';

  @override
  String get calendarFromCalendar => 'Fra kalender';

  @override
  String get calendarLinkedMeeting => 'Tilknyttet møte';

  @override
  String get calendarToday => 'I dag';

  @override
  String get calendarAllDay => 'Hele dagen';

  @override
  String calendarWeekNumber(int number) {
    return 'Uke $number';
  }

  @override
  String get calendarPreviousPeriod => 'Forrige';

  @override
  String get calendarNextPeriod => 'Neste';

  @override
  String calendarLastSynced(String time) {
    return 'Synkronisert $time';
  }

  @override
  String get calendarNeverSynced => 'Ikke synkronisert ennå';

  @override
  String get calendarSyncing => 'Synkroniserer…';

  @override
  String get calendarViewDay => 'Dag';

  @override
  String get calendarShow => 'Vis';

  @override
  String get calendarHide => 'Skjul';

  @override
  String get calendarRsvpGoing => 'Kommer du?';

  @override
  String get calendarRsvpYes => 'Ja';

  @override
  String get calendarRsvpNo => 'Nei';

  @override
  String get calendarRsvpMaybe => 'Kanskje';

  @override
  String get calendarRsvpFailed => 'Kunne ikke oppdatere svaret ditt';

  @override
  String get calendarAddAccount => 'Legg til kalenderkonto';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Koble en Google-konto for å synkronisere hendelser inn i dette arbeidsområdet. Disse kalenderne er dine her.';

  @override
  String get calendarConnecting => 'Kobler til…';

  @override
  String get calendarSyncNow => 'Synkroniser nå';

  @override
  String get calendarNoWorkspace => 'Velg et arbeidsområde for å se kalenderen';

  @override
  String get calendarConnectError => 'Kunne ikke koble til Google Calendar';

  @override
  String get calendarClientIdLabel => 'Client ID';

  @override
  String get calendarClientSecretLabel => 'Client secret';

  @override
  String get calendarConnectCredsHint =>
      'Skriv inn Google OAuth device-code client ID og secret for prosjektet ditt. Serveren kjører tilkoblingen og synkroniseringen — nettleseren din holder aldri tokenene.';

  @override
  String get calendarConnectApproveInstruction =>
      'Åpne bekreftelsessiden på en hvilken som helst enhet, logg inn og skriv inn denne koden:';

  @override
  String get calendarConnectOpenPage => 'Åpne bekreftelsesside';

  @override
  String get calendarConnectWaiting => 'Venter på godkjenning…';

  @override
  String get calendarConnectDenied =>
      'Autorisasjonen ble avslått. Prøv på nytt.';

  @override
  String get calendarConnectExpired => 'Koden utløp. Prøv på nytt.';

  @override
  String get notificationMeetingStartsSoon => 'Møte starter snart';

  @override
  String get notifyMeetingStartsSoon =>
      'Når et kalendermøte er i ferd med å starte';

  @override
  String get notificationCalendarAuthExpiredTitle => 'Kalender koblet fra';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'Koble til $email på nytt for å fortsette synkroniseringen';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'Koble til kalenderen på nytt for å fortsette synkroniseringen';

  @override
  String get notifyCalendarAuthExpired =>
      'Når en kalenderkonto må kobles til på nytt';

  @override
  String get notificationRigStatusChanged => 'Oppdateringer for isolert miljø';

  @override
  String get notifyRigStatusChanged =>
      'Når et isolert miljø overtas, tas tilbake eller feiler';

  @override
  String get notificationRigTakenOver => 'Isolert miljø overtatt';

  @override
  String get notificationRigTakenOverBody =>
      'En person styrer maskinen; agenten kan se, men ikke handle.';

  @override
  String get notificationRigReleased => 'Kontroll over isolert miljø sluppet';

  @override
  String get notificationRigReleasedBody => 'Agenten har maskinen tilbake.';

  @override
  String get notificationRigReclaimed => 'Isolert miljø tatt tilbake';

  @override
  String get notificationRigReclaimedBodyIdle =>
      'Den sto inaktiv, så maskinen ble lukket for å frigjøre minne.';

  @override
  String get notificationRigReclaimedBodyTtl =>
      'Den nådde tidsgrensen og ble lukket.';

  @override
  String get notificationRigFailed => 'Isolert miljø feilet';

  @override
  String get notificationRigFailedBody =>
      'Hypervisoren døde under den. Åpne maskinen på nytt for å fortsette.';

  @override
  String get calendarAlertLeadTime => 'Varslingsforvarsel';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'Hvor lenge før et møte du skal varsles';

  @override
  String calendarConnectedAs(String email) {
    return 'Tilkoblet som $email';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count deltakere';
  }

  @override
  String get calendarEventLabel => 'Hendelse';

  @override
  String get calendarRecurring => 'Gjentakende hendelse';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'Arrangør';

  @override
  String get calendarYou => 'Deg';

  @override
  String get calendarShowFewer => 'Vis færre';

  @override
  String get calendarRsvpAwaiting => 'Venter';

  @override
  String calendarParticipantsCount(int count) {
    return '$count deltakere';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'Se alle $count deltakere';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count ja';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count nei';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count kanskje';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count venter';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count minutter';
  }

  @override
  String get openInEditorPrompt => 'Åpne i hvilken redigerer?';

  @override
  String get ideNotInstalled => 'Ikke installert';

  @override
  String openInIde(String editor) {
    return 'Åpne i $editor';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return 'Kunne ikke åpne $editor: $error';
  }

  @override
  String get profileSearchHint => 'Søk i pull requests…';

  @override
  String get stopAgentRun => 'Stopp kjøring';

  @override
  String get stopAgentRunConfirm =>
      'Stoppe denne kjøringen? Pågående arbeid går tapt.';

  @override
  String get inProgress => 'Pågår';

  @override
  String get drafts => 'Utkast';

  @override
  String get sortOldest => 'Eldst';

  @override
  String get sortLargest => 'Størst';

  @override
  String get prFilterTooltip => 'Filter';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aktive filtre',
      one: '1 aktivt filter',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => 'Legg til filter…';

  @override
  String get prFilterFieldHint => 'Filtrer…';

  @override
  String get prFilterCategoryStatus => 'Status';

  @override
  String get prFilterCategoryAuthor => 'Forfatter';

  @override
  String get prFilterCategoryReviewer => 'Reviewere';

  @override
  String get prFilterCategoryContent => 'Innhold';

  @override
  String get prFilterCategoryRepoOwner => 'Arkiveier';

  @override
  String get prFilterCategoryRepoName => 'Arkivnavn';

  @override
  String get prFilterCategoryOpenedDate => 'Åpnet dato';

  @override
  String get prFilterCategoryUpdatedDate => 'Oppdatert dato';

  @override
  String get prFilterQuickToReview => 'Rask å gjennomgå';

  @override
  String get prFilterClearAll => 'Fjern filtre';

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
      other: '$count alternativer som ikke matcher noen pull requests',
      one: '1 alternativ som ikke matcher noen pull requests',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => 'Tittel eller brødtekst inneholder…';

  @override
  String get prFilterNoOptions => 'Ingen matchende alternativer';

  @override
  String get prFilterChipIs => 'er';

  @override
  String get prFilterChipIsAnyOf => 'er en av';

  @override
  String get prFilterChipContains => 'inneholder';

  @override
  String get prFilterChipSince => 'siden';

  @override
  String get prFilterAddFilterButton => 'Legg til filter';

  @override
  String prFilterClearCategory(String category) {
    return 'Fjern $category-filter';
  }

  @override
  String get prFilterCurrentUser => 'Gjeldende bruker';

  @override
  String get prStatusDraft => 'Utkast';

  @override
  String get prStatusOpen => 'Åpen';

  @override
  String get prStatusInReview => 'Til gjennomgang';

  @override
  String get prStatusChangesRequested => 'Endringer forespurt';

  @override
  String get prStatusApproved => 'Godkjent';

  @override
  String get prStatusMerged => 'Sammenslått';

  @override
  String get prStatusClosed => 'Lukket';

  @override
  String get prDateWindowDay => '1 dag siden';

  @override
  String get prDateWindowThreeDays => '3 dager siden';

  @override
  String get prDateWindowWeek => '1 uke siden';

  @override
  String get prDateWindowMonth => '1 måned siden';

  @override
  String get prDateWindowThreeMonths => '3 måneder siden';

  @override
  String get prDateWindowSixMonths => '6 måneder siden';

  @override
  String get prDateWindowYear => '1 år siden';

  @override
  String get prDisplayOptions => 'Visningsvalg';

  @override
  String get prDisplayGrouping => 'Gruppering';

  @override
  String get prDisplayOrdering => 'Sortering';

  @override
  String get prDisplayShowDrafts => 'Vis utkast';

  @override
  String get prDisplayMergedWindow => 'Sammenslått vindu';

  @override
  String get prDisplayMergedWindowDay => 'Siste dag';

  @override
  String get prDisplayMergedWindowWeek => 'Siste uke';

  @override
  String get prDisplayMergedWindowMonth => 'Siste måned';

  @override
  String get prDisplayProperties => 'Visningsegenskaper';

  @override
  String get prGroupingRepository => 'Arkiv';

  @override
  String get prGroupingAuthor => 'Forfatter';

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
  String get prPropertyUpdated => 'Oppdatert';

  @override
  String get prPropertyAuthor => 'Forfatter';

  @override
  String get prPropertyChecks => 'Sjekker';

  @override
  String get prPropertyDiff => 'Diff';

  @override
  String get prPropertyComments => 'Kommentarer';

  @override
  String get keybindingOpenFilterMenu => 'Åpne filtermeny';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'Åpne filtermenyen for pull requests';

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count valgt',
      one: '1 valgt',
    );
    return '$_temp0';
  }

  @override
  String get summary => 'Sammendrag';

  @override
  String get kbMove => 'flytt';

  @override
  String get kbTabs => 'faner';

  @override
  String get kbSearch => 'søk';

  @override
  String get kbViewed => 'sett';

  @override
  String get kbCollapse => 'skjul';

  @override
  String get appearance => 'Utseende';

  @override
  String get appearanceSettingsDescription => 'Tema, språk og typografi.';

  @override
  String get notificationsSettingsDescription =>
      'Velg hvilke agent- og arbeidsområdehendelser som varsler deg.';

  @override
  String get advanced => 'Avansert';

  @override
  String get accounts => 'Kontoer';

  @override
  String get mcpServers => 'MCP-servere';

  @override
  String get mcpServersSettingsDescription =>
      'Innebygd MCP-server og eksterne MCP-servere.';

  @override
  String get remoteControlAndDevices => 'Fjernstyring og enheter';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'Par telefoner og konfigurer fjernstyringsserveren.';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'Tale- og diariseringsmodellene denne serveren kjører.';

  @override
  String get needsSetupLabel => 'Trenger oppsett';

  @override
  String get collapseSidebar => 'Skjul sidestolpe';

  @override
  String get expandSidebar => 'Vis sidestolpe';

  @override
  String get filterSpacesHint => 'Filtrer områder';

  @override
  String noSpacesMatch(String query) {
    return 'Ingen områder matcher «$query»';
  }

  @override
  String get privacy => 'Personvern';

  @override
  String get sendDiffContentTitle => 'Send diff-innhold til AI-adapter';

  @override
  String get diffSharingOnSubtitle =>
      'Rå diff-linjer tas med i agentpromptene for dypere gjennomgang.';

  @override
  String get diffSharingOffSubtitle =>
      'Agenter bruker bare strukturert metadata (filstier, linjenumre, PR-beskrivelse); ingen rå kode forlater appen.';

  @override
  String get errorReportingTitle => 'Del krasjrapporter';

  @override
  String get errorReportingOnSubtitle =>
      'Krasj-, feil- og ytelsesdiagnostikk sendes for å hjelpe å rette feil (kun utgivelsesbygg).';

  @override
  String get errorReportingOffSubtitle =>
      'Diagnostikk er av. Ingen krasj- eller feilrapporter sendes.';

  @override
  String get onboardingDiagnosticsTitle =>
      'Hjelp til å forbedre Control Center';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'Send krasj-, feil- og ytelsesdiagnostikk slik at vi kan rette problemer raskere (kun utgivelsesbygg). Du kan endre dette når som helst i Innstillinger → Personvern.';

  @override
  String get blocked => 'Blokkert';

  @override
  String get idle => 'Inaktiv';

  @override
  String get noRunsYet => 'Ingen kjøringer ennå';

  @override
  String get copyPath => 'Kopier sti';

  @override
  String get copyRelativePath => 'Kopier relativ sti';

  @override
  String get nameRequired => 'Navn er påkrevd';

  @override
  String get import => 'Importer';

  @override
  String get noMatchingAgents => 'Ingen agenter matcher filteret ditt';

  @override
  String watchVideoOn(String provider) {
    return 'Se video på $provider';
  }

  @override
  String get branchTemplate => 'Mal for grenavn';

  @override
  String get branchTemplateDescription =>
      'Mønster for grenen som opprettes når en sak startes i et isolert worktree.';

  @override
  String branchTemplatePreview(String example) {
    return 'Eksempel: $example';
  }

  @override
  String get deletePipelineRun => 'Slett pipeline-kjøring';

  @override
  String deletePipelineRunConfirm(String template) {
    return 'Slette denne kjøringen av «$template»? Dette kan ikke angres.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'Feil ved sletting av pipeline-kjøring: $error';
  }

  @override
  String get deleteTicket => 'Slett sak';

  @override
  String deleteTicketConfirm(String title) {
    return 'Slette «$title»? Dette kan ikke angres.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'Feil ved sletting av sak: $error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return 'Slette «$name»? Tilknyttede arkiv på disk røres ikke.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'Feil ved sletting av arbeidsområde: $error';
  }

  @override
  String get indexCode => 'Indekser kode';

  @override
  String get indexNoGrammars => 'Kodegrammatikker er ikke installert';

  @override
  String get indexFailed => 'Indeksering mislyktes';

  @override
  String indexedSymbolsCount(int count) {
    return '$count symboler indeksert';
  }

  @override
  String get nodeConfigAdvanced => 'Avansert';

  @override
  String get nodeConfigReducer => 'Reducer';

  @override
  String get nodeConfigReducerHelp =>
      'Hvordan slå sammen når denne utdatanøkkelen allerede har en verdi';

  @override
  String get nodeConfigTimeoutMs => 'Tidsavbrudd (ms)';

  @override
  String get nodeConfigRetryAttempts => 'Nye forsøk';

  @override
  String get nodeConfigContinueOnFail => 'Fortsett hvis dette steget feiler';

  @override
  String get nodeConfigTeamId => 'Team-ID';

  @override
  String get nodeConfigDispatchMode => 'Dispatch-modus';

  @override
  String get nodeConfigOutputSchema => 'Utdataskjema (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'JSON Schema som stegoutputen må oppfylle';

  @override
  String get diffLineDisplay => 'Lange linjer i diffs';

  @override
  String get diffLineDisplayDescription =>
      'Bryt lange linjer eller rull dem horisontalt';

  @override
  String get diffLineWrap => 'Bryt linjer';

  @override
  String get diffLineScroll => 'Rull horisontalt';

  @override
  String get actions => 'Handlinger';

  @override
  String get activate => 'Aktiver';

  @override
  String get activity => 'Aktivitet';

  @override
  String get activityLabel => 'AKTIVITET';

  @override
  String get activitySearchHint => 'Søk i aktivitet';

  @override
  String get activityNoMatches => 'Ingen aktivitet matcher filtrene dine';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$start–$end av $total';
  }

  @override
  String get activityPreviousPage => 'Forrige side';

  @override
  String get activityNextPage => 'Neste side';

  @override
  String get activityNetworkLocal => 'Localhost';

  @override
  String get activityClearFilter => 'Fjern filter';

  @override
  String activityFilterIp(String ip) {
    return 'IP $ip';
  }

  @override
  String activityFilterCountry(String country) {
    return 'Land $country';
  }

  @override
  String get activitySavedWorkspaceLogo => 'Lagret logoen for arbeidsområdet';

  @override
  String activityVerbCreated(String target) {
    return 'Opprettet $target';
  }

  @override
  String activityVerbUpdated(String target) {
    return 'Oppdaterte $target';
  }

  @override
  String activityVerbDeleted(String target) {
    return 'Slettet $target';
  }

  @override
  String activityVerbAdded(String target) {
    return 'La til $target';
  }

  @override
  String activityVerbRemoved(String target) {
    return 'Fjernet $target';
  }

  @override
  String activityVerbInvited(String target) {
    return 'Inviterte $target';
  }

  @override
  String activityVerbChanged(String target) {
    return 'Endret $target';
  }

  @override
  String activityVerbStarted(String target) {
    return 'Startet $target';
  }

  @override
  String activityVerbStopped(String target) {
    return 'Stoppet $target';
  }

  @override
  String activityVerbWrote(String target) {
    return 'Skrev $target';
  }

  @override
  String get activityTargetAgent => 'agent';

  @override
  String get activityTargetTicket => 'sak';

  @override
  String get activityTargetWorkspace => 'arbeidsområde';

  @override
  String get activityTargetRepository => 'arkiv';

  @override
  String get activityTargetMember => 'medlem';

  @override
  String get activityTargetInvite => 'invitasjon';

  @override
  String get activityTargetSpace => 'område';

  @override
  String get activityTargetMessage => 'melding';

  @override
  String get activityTargetCache => 'cache';

  @override
  String get activityTargetFile => 'fil';

  @override
  String get activityTargetPipeline => 'pipeline';

  @override
  String get activityTargetTemplate => 'mal';

  @override
  String get activityTargetProvider => 'leverandør';

  @override
  String get activityTargetModel => 'modell';

  @override
  String get activityTargetSkill => 'ferdighet';

  @override
  String get activityTargetTodo => 'gjøremål';

  @override
  String get activityTargetMeeting => 'møte';

  @override
  String get activityTargetProject => 'prosjekt';

  @override
  String get activityTargetTeam => 'team';

  @override
  String get activityTargetDevice => 'enhet';

  @override
  String get activityTargetPreference => 'innstilling';

  @override
  String get activityTargetBudget => 'budsjett';

  @override
  String activityVerbApproved(String target) {
    return 'Godkjente $target';
  }

  @override
  String activityVerbArchived(String target) {
    return 'Arkiverte $target';
  }

  @override
  String activityVerbAssigned(String target) {
    return 'Tildelte $target';
  }

  @override
  String activityVerbBackedUp(String target) {
    return 'Tok sikkerhetskopi av $target';
  }

  @override
  String activityVerbCancelled(String target) {
    return 'Avbrøt $target';
  }

  @override
  String activityVerbCleared(String target) {
    return 'Tømte $target';
  }

  @override
  String activityVerbClosed(String target) {
    return 'Lukket $target';
  }

  @override
  String activityVerbCommitted(String target) {
    return 'Commitet $target';
  }

  @override
  String activityVerbCompacted(String target) {
    return 'Kompakterte $target';
  }

  @override
  String activityVerbCompleted(String target) {
    return 'Fullførte $target';
  }

  @override
  String activityVerbConnected(String target) {
    return 'Koblet til $target';
  }

  @override
  String activityVerbContinued(String target) {
    return 'Fortsatte $target';
  }

  @override
  String activityVerbDisconnected(String target) {
    return 'Koblet fra $target';
  }

  @override
  String activityVerbDispatched(String target) {
    return 'Dispatchert $target';
  }

  @override
  String activityVerbDrained(String target) {
    return 'Tømte $target';
  }

  @override
  String activityVerbEnrolled(String target) {
    return 'Registrerte $target';
  }

  @override
  String activityVerbEstimated(String target) {
    return 'Estimerte $target';
  }

  @override
  String activityVerbImported(String target) {
    return 'Importerte $target';
  }

  @override
  String activityVerbInstalled(String target) {
    return 'Installerte $target';
  }

  @override
  String activityVerbKilled(String target) {
    return 'Avsluttet $target';
  }

  @override
  String activityVerbMarked(String target) {
    return 'Merket $target';
  }

  @override
  String activityVerbMerged(String target) {
    return 'Slo sammen $target';
  }

  @override
  String activityVerbOpened(String target) {
    return 'Åpnet $target';
  }

  @override
  String activityVerbPaused(String target) {
    return 'Satte $target på pause';
  }

  @override
  String activityVerbPolled(String target) {
    return 'Pollerte $target';
  }

  @override
  String activityVerbPrepared(String target) {
    return 'Forberedte $target';
  }

  @override
  String activityVerbProcessed(String target) {
    return 'Behandlet $target';
  }

  @override
  String activityVerbPublished(String target) {
    return 'Publiserte $target';
  }

  @override
  String activityVerbRefined(String target) {
    return 'Forfinet $target';
  }

  @override
  String activityVerbRefreshed(String target) {
    return 'Oppfrisket $target';
  }

  @override
  String activityVerbRegistered(String target) {
    return 'Registrerte $target';
  }

  @override
  String activityVerbRenamed(String target) {
    return 'Endret navn på $target';
  }

  @override
  String activityVerbReordered(String target) {
    return 'Endret rekkefølge på $target';
  }

  @override
  String activityVerbResponded(String target) {
    return 'Svarte på $target';
  }

  @override
  String activityVerbRestored(String target) {
    return 'Gjenopprettet $target';
  }

  @override
  String activityVerbResumed(String target) {
    return 'Gjenopptok $target';
  }

  @override
  String activityVerbRetried(String target) {
    return 'Prøvde $target på nytt';
  }

  @override
  String activityVerbReverted(String target) {
    return 'Tilbakestilte $target';
  }

  @override
  String activityVerbReviewed(String target) {
    return 'Gjennomgikk $target';
  }

  @override
  String activityVerbRan(String target) {
    return 'Kjørte $target';
  }

  @override
  String activityVerbSelected(String target) {
    return 'Valgte $target';
  }

  @override
  String activityVerbSent(String target) {
    return 'Sendte $target';
  }

  @override
  String activityVerbStaged(String target) {
    return 'Staget $target';
  }

  @override
  String activityVerbSteered(String target) {
    return 'Styrte $target';
  }

  @override
  String activityVerbSubmitted(String target) {
    return 'Sendte inn $target';
  }

  @override
  String activityVerbSynced(String target) {
    return 'Synkroniserte $target';
  }

  @override
  String activityVerbToggled(String target) {
    return 'Vekslet $target';
  }

  @override
  String activityVerbUninstalled(String target) {
    return 'Avinstallerte $target';
  }

  @override
  String activityVerbUnstaged(String target) {
    return 'Fjernet $target fra stage';
  }

  @override
  String get activityTargetActionPolicy => 'handlingspolicy';

  @override
  String get activityTargetGoalRun => 'mål-kjøring';

  @override
  String get activityTargetRunLog => 'kjøringslogg';

  @override
  String get activityTargetWorkingMemory => 'arbeidsminne';

  @override
  String get activityTargetRoutingPolicy => 'rute-policy';

  @override
  String get activityTargetAutonomy => 'autonomi';

  @override
  String get activityTargetCalendar => 'kalender';

  @override
  String get activityTargetChecker => 'sjekker';

  @override
  String get activityTargetEditor => 'redigerer';

  @override
  String get activityTargetConfirmation => 'bekreftelse';

  @override
  String get activityTargetTunnel => 'tunnel';

  @override
  String get activityTargetConversation => 'samtale';

  @override
  String get activityTargetCredentials => 'påloggingsinformasjon';

  @override
  String get activityTargetDictation => 'diktering';

  @override
  String get activityTargetAgentRun => 'agentkjøring';

  @override
  String get activityTargetEvalSuite => 'eval-suite';

  @override
  String get activityTargetWorker => 'worker';

  @override
  String get activityTargetWorktree => 'worktree';

  @override
  String get activityTargetMcpServer => 'MCP-server';

  @override
  String get activityTargetMemoryAccessGrant => 'minnetilgang';

  @override
  String get activityTargetMemoryDomain => 'minnedomene';

  @override
  String get activityTargetMemoryFact => 'minnefaktum';

  @override
  String get activityTargetMemoryPolicy => 'minnepolicy';

  @override
  String get activityTargetFeed => 'strøm';

  @override
  String get activityTargetNote => 'notat';

  @override
  String get activityTargetOrchestration => 'orkestrering';

  @override
  String get activityTargetPipelineRun => 'pipeline-kjøring';

  @override
  String get activityTargetPipelineTrigger => 'pipeline-utløser';

  @override
  String get activityTargetPlan => 'plan';

  @override
  String get activityTargetPlaybook => 'playbook';

  @override
  String get activityTargetPullRequest => 'pull request';

  @override
  String get activityTargetReview => 'gjennomgang';

  @override
  String get activityTargetProcess => 'prosess';

  @override
  String get activityTargetProviderPolicy => 'leverandørpolicy';

  @override
  String get activityTargetReaction => 'reaksjon';

  @override
  String get activityTargetReviewSpace => 'gjennomgangsområde';

  @override
  String get activityTargetReviewStudio => 'gjennomgangsstudio';

  @override
  String get activityTargetServerData => 'serverdata';

  @override
  String get activityTargetSoundscape => 'lydlandskap';

  @override
  String get activityTargetSession => 'økt';

  @override
  String get activityTargetTerminal => 'terminal';

  @override
  String get activityTargetTicketLink => 'sakslenke';

  @override
  String get activityTargetTicketSync => 'sakssynkronisering';

  @override
  String get activityTargetProfile => 'profil';

  @override
  String get activityTargetVoiceProfile => 'stemmeprofil';

  @override
  String get activityTargetWeather => 'værmelding';

  @override
  String get activityTargetWorkProduct => 'arbeidsprodukt';

  @override
  String get activityChangedMemberRole => 'Endret en medlemsrolle';

  @override
  String get activityChangedMemberRepoAccess =>
      'Endret et medlems arkivtilgang';

  @override
  String get activityUpdatedGitHubToken => 'Oppdaterte GitHub-tokenet';

  @override
  String get activityRefreshedWeather => 'Oppfrisket værmeldingen';

  @override
  String get activitySetWeatherLocation => 'Satte værstedet';

  @override
  String get activityClearedWeatherLocation => 'Fjernet værstedet';

  @override
  String get activityMarkedAllArticlesRead => 'Merket alle artikler som lest';

  @override
  String get activityMarkedArticleRead => 'Merket en artikkel som lest';

  @override
  String get activityUpdatedSavedArticle => 'Oppdaterte en lagret artikkel';

  @override
  String get activityTookOverSession => 'Tok over økten';

  @override
  String get activityHandedBackSession => 'Ga økten tilbake';

  @override
  String get activityCommittedAndPushed => 'Commitet og pushet';

  @override
  String get activityBackedUpServer => 'Tok sikkerhetskopi av serverdataene';

  @override
  String get activityMarkedSpaceRead => 'Merket området som lest';

  @override
  String get activityRespondedToInvitation => 'Svarte på hendelsesinvitasjonen';

  @override
  String get activityStartedCalendarConnect => 'Startet kalendertilkoblingen';

  @override
  String get activityDisconnectedCalendar => 'Koblet fra kalenderen';

  @override
  String get activityMarkedFileViewed => 'Merket en fil som sett';

  @override
  String get activityRespondedToApproval =>
      'Svarte på en godkjenningsforespørsel';

  @override
  String get activityChangedTunnel => 'Endret tunnelinnstillingen';

  @override
  String get activitySentMessageToAgent => 'Sendte en melding til agenten';

  @override
  String get activityOpenedReviewSpace => 'Åpnet gjennomgangsområdet';

  @override
  String get activityOpenedStandingConversation => 'Åpnet den stående samtalen';

  @override
  String get activityStartedRecording => 'Startet opptaket';

  @override
  String get activityStoppedRecording => 'Stoppet opptaket';

  @override
  String get activityToggledMcpServer => 'Vekslet MCP-serveren';

  @override
  String get activityUpdatedMcpToken => 'Oppdaterte MCP-tokenet';

  @override
  String get activitySavedApiKey => 'Lagret en API-nøkkel';

  @override
  String get activityRemovedProviderCredential =>
      'Fjernet påloggingsinformasjon for en leverandør';

  @override
  String get activityUpdatedLinkedRepos => 'Oppdaterte de tilknyttede arkivene';

  @override
  String get activityUnlinkedRepo => 'Fjernet tilknytning til et arkiv';

  @override
  String get activityUpdatedActionItem => 'Oppdaterte et tiltak';

  @override
  String adRulesCount(int count) {
    return '$count annonseregler';
  }

  @override
  String get adapter => 'Adapter';

  @override
  String get adapterLabel => 'Adapter';

  @override
  String get adapters => 'Adaptere';

  @override
  String get adaptersAutoDetected =>
      'Automatisk oppdagede agentkjørere tilgjengelige på denne maskinen. Installer manglende CLI-verktøy for å slå på flere kjørere.';

  @override
  String get add => 'Legg til';

  @override
  String get addAComment => 'Legg til en kommentar';

  @override
  String get addAReaction => 'Legg til en reaksjon';

  @override
  String get addASuggestion => 'Legg til et forslag';

  @override
  String get addAgents => 'Legg til agenter';

  @override
  String get addEmoji => 'Legg til emoji';

  @override
  String get addFeed => 'Legg til strøm';

  @override
  String get addressBarHint => 'Skriv inn en URL';

  @override
  String get addFromFile => 'Legg til fra fil';

  @override
  String get addGif => 'Legg til GIF';

  @override
  String get addGithubRepoPrompt =>
      'Legg til minst ett GitHub-arkiv for å se pull requests';

  @override
  String get addLocalCheckoutDescription =>
      'Legg til en lokal utsjekking for å begynne å rette mot den fra dette arbeidsområdet.';

  @override
  String get addRepository => 'Legg til arkiv';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Legg til $count arkiv',
      one: 'Legg til arkiv',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro =>
      'Bla gjennom mappene på maskinen som kjører serveren, og velg git-utsjekkingene som skal registreres.';

  @override
  String get selectThisFolder => 'Velg denne mappen';

  @override
  String get deselectThisFolder => 'Fjern valg av denne mappen';

  @override
  String get goUp => 'Opp';

  @override
  String get noSubfoldersHere => 'Ingen undermapper her';

  @override
  String get notAGitRepository => 'Denne mappen er ikke et git-arkiv.';

  @override
  String get addToken => 'Legg til token';

  @override
  String get addWorkspace => 'Legg til arbeidsområde';

  @override
  String get addWorkspaceEllipsis => 'Legg til arbeidsområde…';

  @override
  String get added => 'Lagt til';

  @override
  String get addingEllipsis => 'Legger til…';

  @override
  String get advancedLabel => 'Avansert';

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
  String get agentMdPath => 'Agent-MD-sti';

  @override
  String get agentName => 'Agentnavn';

  @override
  String get agentTitle => 'Agenttittel';

  @override
  String get agentUpdated => 'Agent oppdatert.';

  @override
  String get agents => 'Agenter';

  @override
  String get agentsMentionSection => 'Agenter';

  @override
  String get usersMentionSection => 'Personer';

  @override
  String get ticketsMentionSection => 'Saker';

  @override
  String get pullRequestsMentionSection => 'Pull requests';

  @override
  String get meetingsMentionSection => 'Møter';

  @override
  String get entityRefTicketFallback => 'Sak';

  @override
  String get entityRefPrFallback => 'Pull request';

  @override
  String get entityRefMeetingFallback => 'Møte';

  @override
  String get aiReview => 'AI-gjennomgang';

  @override
  String get all => 'Alle';

  @override
  String get allAgentsAlreadyInSpace =>
      'Alle agenter er allerede i dette området.';

  @override
  String get allCommits => 'Alle commits';

  @override
  String get allSources => 'Alle kilder';

  @override
  String get allow => 'Tillat';

  @override
  String get allowGitPush => 'Tillat git push';

  @override
  String get allowGithubApi => 'Tillat GitHub API-kall';

  @override
  String get allowNetwork => 'Tillat generell nettverkstilgang';

  @override
  String get apiKeys => 'API-nøkler';

  @override
  String get appFont => 'App-skrift';

  @override
  String get appLogLevelDebugDescription =>
      'Legger til detaljerte spor — for utvikling.';

  @override
  String get appLogLevelDebugLabel => 'Debug';

  @override
  String get appLogLevelErrorDescription => 'Bare uventede feil og unntak.';

  @override
  String get appLogLevelErrorLabel => 'Error';

  @override
  String get appLogLevelInfoDescription =>
      'Legger til livssyklus- og statusmeldinger.';

  @override
  String get appLogLevelInfoLabel => 'Info';

  @override
  String get appLogLevelNoneDescription =>
      'Ingen konsollutdata i det hele tatt.';

  @override
  String get appLogLevelNoneLabel => 'Ingen';

  @override
  String get appLogLevelVerboseDescription =>
      'Alt. Svært støyende — bruk bare til feilsøking.';

  @override
  String get appLogLevelVerboseLabel => 'Verbose';

  @override
  String get appLogLevelWarningDescription =>
      'Legger til advarsler og gjenopprettbare problemer.';

  @override
  String get appLogLevelWarningLabel => 'Warning';

  @override
  String get appearanceLanguage => 'Utseende og språk';

  @override
  String get apply => 'Bruk';

  @override
  String get approve => 'Godkjenn';

  @override
  String get agentApprovalRequired => 'Godkjenning kreves';

  @override
  String agentApprovalsMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count til venter',
      one: '1 til venter',
    );
    return '$_temp0';
  }

  @override
  String get approved => 'Godkjent';

  @override
  String get articleNoun => 'Artikkel';

  @override
  String get articlesSubscribed => 'Artikler fra strømmene du abonnerer på.';

  @override
  String get askAi => 'Spør AI';

  @override
  String get askAiReviewDescription => 'Be AI om å gjennomgå denne PR-en';

  @override
  String get assignees => 'Tildelte';

  @override
  String get attachImage => 'Legg ved bilde';

  @override
  String get attachedAgents => 'Tilknyttede agenter';

  @override
  String get audioInput => 'Lydinngang';

  @override
  String get audioOutput => 'Lydutgang';

  @override
  String get authenticationToken => 'Autentiseringstoken';

  @override
  String authoredByLabel(String role) {
    return 'Av: $role';
  }

  @override
  String get autoRecommended => 'Auto (anbefalt)';

  @override
  String get available => 'Tilgjengelig';

  @override
  String get awaitingYourReview => 'Venter på din gjennomgang';

  @override
  String get back => 'Tilbake';

  @override
  String get backLabel => 'Tilbake';

  @override
  String get backend => 'Backend';

  @override
  String get blockAdsTrackers => 'Blokker annonser, sporere og infokapsler';

  @override
  String get blocking => 'Blokkerer';

  @override
  String get bookmarkLabel => 'Bokmerke';

  @override
  String get briefDescription => 'Kort beskrivelse';

  @override
  String get bugLabel => 'FEIL';

  @override
  String get bundledDefaultsNeverUpdated =>
      'Medfølgende standarder — aldri oppdatert';

  @override
  String get cancel => 'Avbryt';

  @override
  String get cancelEdit => 'Avbryt redigering';

  @override
  String get categoryCreation => 'Oppretting';

  @override
  String get categoryEditing => 'Redigering';

  @override
  String get categoryNavigation => 'Navigasjon';

  @override
  String get categorySystem => 'System';

  @override
  String get categoryView => 'Kategorivisning';

  @override
  String get change => 'Endre';

  @override
  String get changesRequested => 'Endringer forespurt';

  @override
  String get spacesMentionSection => 'Områder';

  @override
  String get checkForUpdates => 'Se etter oppdateringer';

  @override
  String get checking => 'Sjekker';

  @override
  String get checkingEllipsis => 'Sjekker…';

  @override
  String get chooseAppFont => 'Velg app-skrift';

  @override
  String get chooseCodeFont => 'Velg kodeskift';

  @override
  String get chooseRunner => 'Velg agentkjøreren din.';

  @override
  String get clear => 'Tøm';

  @override
  String get clickToRetry => 'Klikk for å prøve på nytt';

  @override
  String get close => 'Lukk';

  @override
  String get closeEsc => 'Lukk (Esc)';

  @override
  String get closeReader => 'Lukk leser';

  @override
  String get closed => 'Lukket';

  @override
  String get codeFont => 'Kodeskift';

  @override
  String get codeFontLigatures => 'Kodeskift-ligaturer';

  @override
  String get codeFontLigaturesDescription =>
      'Vis programmeringsligaturer (=>, !=, ->) som sammenslåtte glyfer i kode og diffs';

  @override
  String get collapse => 'Skjul';

  @override
  String get commandPalette => 'Kommandopalett';

  @override
  String get commandPaletteOrgMembers => 'Organisasjonsmedlemmer';

  @override
  String get commandPaletteBrowseTeam => 'Bla gjennom team';

  @override
  String get commandPaletteBrowseTeamDesc => 'Se alle organisasjonsmedlemmer';

  @override
  String get compactDone =>
      'Samtalen ble kompaktert. Tidligere historikk ble foldet inn i et sammendrag.';

  @override
  String get compactNothing =>
      'Ingenting å kompaktere ennå. Samtalen er fortsatt kort.';

  @override
  String get compactBusy =>
      'En agent jobber fortsatt. Kompakter når turen er ferdig.';

  @override
  String get compactUnavailable =>
      'Kompaktering er ikke tilgjengelig på denne serveren.';

  @override
  String get commandsMentionSection => 'Kommandoer';

  @override
  String get comment => 'Kommentar';

  @override
  String get commentOnThisFile => 'Kommenter denne filen';

  @override
  String get commented => 'Kommenterte';

  @override
  String get commits => 'Commits';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'Viser de siste $loaded av $total commits';
  }

  @override
  String get prCloneProgressCloningTitle => 'Kloner arkiv';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'Denne PR-en endrer $fileCount filer, som overskrider GitHubs API-grense. Kloner arkivet lokalt…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'Denne PR-en overskrider GitHubs API-filgrense. Kloner arkivet lokalt…';

  @override
  String get prCloneProgressFetchingTitle => 'Henter PR-refs';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'Henter basegrenen og PR head-ref…';

  @override
  String get prCloneProgressComputingTitle => 'Beregner diff';

  @override
  String get prCloneProgressComputingSubtitle => 'Kjører git diff lokalt…';

  @override
  String get prCloneProgressErrorTitle => 'Kunne ikke laste diff';

  @override
  String get prCloneProgressErrorSubtitle =>
      'Det oppstod en feil under kloning eller beregning av diff. Prøv å oppdatere.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'Jobber fortsatt… $elapsed brukt';
  }

  @override
  String confidenceLabel(int percent) {
    return 'Sikkerhet: $percent %';
  }

  @override
  String get configureAgentIdentities =>
      'Konfigurer agentidentiteter, prompts, ferdigheter og se kjøringer.';

  @override
  String get configureDefaultRunners =>
      'Konfigurer hvilken adapter og modell som brukes for nye områder og tittelgenerering.';

  @override
  String get configuredLabel => 'Konfigurert.';

  @override
  String get confirmedBy => 'Bekreftet av';

  @override
  String get consensus => 'Konsensus';

  @override
  String get contentHint => 'Hva som skal huskes';

  @override
  String get contentLabel => 'Innhold';

  @override
  String get contentMarkdown => 'Innhold (Markdown)';

  @override
  String get contextWindowSize => 'Størrelse på kontekstvindu';

  @override
  String modelContextChip(String size) {
    return 'Modell · $size';
  }

  @override
  String get continueLabel => 'Fortsett';

  @override
  String get conversationMode => 'Modus';

  @override
  String cookieRulesCount(int count) {
    return '$count infokapselregler';
  }

  @override
  String get copied => 'Kopiert!';

  @override
  String get copy => 'Kopier';

  @override
  String get copyAddress => 'Kopier adresse';

  @override
  String get copyBaseBranchTooltip => 'Kopier navn på basegren';

  @override
  String get copyHeadBranchTooltip => 'Kopier navn på head-gren';

  @override
  String couldNotListDevices(String error) {
    return 'Kunne ikke liste enheter: $error';
  }

  @override
  String get create => 'Opprett';

  @override
  String get createOrSelectWorkspace =>
      'Opprett eller velg et arbeidsområde før du legger til arkiv.';

  @override
  String get createPullRequest => 'Opprett pull request';

  @override
  String get createdByMe => 'Opprettet av meg';

  @override
  String createdLabel(String date) {
    return 'Opprettet: $date';
  }

  @override
  String get currentParticipants => 'Nåværende deltakere';

  @override
  String get customCapabilitiesDescription =>
      'Beskrivelse av egendefinerte evner';

  @override
  String get customSystemPrompt =>
      'Egendefinert systemprompt for denne agenten…';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dager siden',
      one: '1 dag siden',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'Deaktiver';

  @override
  String get defaultCapabilities => 'Standardkapasiteter · nye områder';

  @override
  String get defaultChat => 'Standardchat';

  @override
  String get defaultRunners => 'Standardkjørere';

  @override
  String get delete => 'Slett';

  @override
  String get deleteAgent => 'Slett agent';

  @override
  String deleteAgentConfirm(String name) {
    return 'Slette «$name»? Dette kan ikke angres.';
  }

  @override
  String get deleteSpace => 'Slett område';

  @override
  String deleteConfirmName(String name) {
    return 'Slette «$name»?';
  }

  @override
  String get archiveConversation => 'Arkiver samtale';

  @override
  String get deleteFact => 'Slett faktum';

  @override
  String get deleteFeedBody =>
      'Dette fjerner strømmen og alle bufrede artikler. Bokmerkede artikler fra denne strømmen fjernes også.';

  @override
  String deleteFeedConfirm(String name) {
    return 'Slette «$name»?';
  }

  @override
  String get deletePolicy => 'Slett policy';

  @override
  String get deletePolicyConfirm =>
      'Slette denne policyen? Dette kan ikke angres.';

  @override
  String deleteTopicConfirm(String topic) {
    return 'Slette «$topic»? Dette kan ikke angres.';
  }

  @override
  String get deleteWorkspace => 'Slett arbeidsområde';

  @override
  String get deny => 'Nekt';

  @override
  String get detailsLabel => 'Detaljer';

  @override
  String get descriptionLabel => 'Beskrivelse';

  @override
  String detectedBackend(String label) {
    return 'Oppdaget: $label';
  }

  @override
  String get detectedRunners => 'Oppdagede kjørere';

  @override
  String get detectingAdapters => 'Oppdager adaptere…';

  @override
  String get detectingInputDevices => 'Oppdager inngangsenheter…';

  @override
  String detectionFailed(String error) {
    return 'Oppdagelse mislyktes: $error';
  }

  @override
  String get disabled => 'Av';

  @override
  String get discover => 'Oppdag';

  @override
  String get dismissed => 'Avvist';

  @override
  String get domainHint => 'f.eks. api-performance';

  @override
  String get domainLabel => 'Domene';

  @override
  String get download => 'Last ned';

  @override
  String get downloadingLabel => 'Laster ned';

  @override
  String downloadingModel(int pct) {
    return 'Laster ned modell… $pct %';
  }

  @override
  String get draft => 'Utkast';

  @override
  String get draftLabel => 'Utkast';

  @override
  String get edit => 'Rediger';

  @override
  String get edited => 'redigert';

  @override
  String get editMessage => 'Rediger melding';

  @override
  String get revertToThere => 'Tilbakestill dit';

  @override
  String get sendAsNewMessage => 'Send som ny melding';

  @override
  String get editMessageChoiceBody =>
      'Tilbakestilling skjuler meldingene etter denne og ruller agentens filer tilbake. Du kan angre det. Å sende den som en ny melding lar samtalen stå.';

  @override
  String get deleteMessage => 'Slett melding';

  @override
  String get deleteMessageConfirm =>
      'Slette denne meldingen? Dette kan ikke angres.';

  @override
  String get messageDeleted => 'Melding slettet';

  @override
  String get searchInConversation => 'Søk i samtalen';

  @override
  String get searchMessagesHint => 'Søk i meldinger…';

  @override
  String get noMessagesFound => 'Ingen meldinger funnet';

  @override
  String get editFact => 'Rediger faktum';

  @override
  String get editPolicy => 'Rediger policy';

  @override
  String get editSuggestedCodeHint => 'Rediger foreslått kode…';

  @override
  String get editSuggestion => 'Rediger forslag';

  @override
  String get egArchitect => 'f.eks. architect';

  @override
  String get egControlCenter => 'f.eks. control-center';

  @override
  String get egPlatform => 'f.eks. Platform';

  @override
  String get egSamuelAlev => 'f.eks. SamuelAlev';

  @override
  String get egSoftwareArchitect => 'f.eks. Software Architect';

  @override
  String get egTheVerge => 'f.eks. The Verge';

  @override
  String get egTokenLimit => 'f.eks. 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'Installasjon mislyktes: $error';
  }

  @override
  String get embeddingInstalled =>
      'Lokal innbyggingsmodell installert. Hybridsøk er slått på.';

  @override
  String get embeddingModel => 'Innbyggingsmodell (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'Ikke installert. Søk faller tilbake til bare nøkkelord til den slås på.';

  @override
  String get embeddingRedownloadBody =>
      'De eksisterende modellfilene slettes og lastes ned på nytt. Semantisk søk er utilgjengelig til nedlastingen er ferdig.';

  @override
  String get embeddingRemoveBody =>
      'Semantisk søk slås av til du installerer det på nytt. Du kan installere det når som helst.';

  @override
  String get speakerDiarization => 'Talerdiarisering';

  @override
  String get diarizationModel => 'Diariseringsmodell';

  @override
  String get diarizationInstalled =>
      'Installert — navngir individuelle talere i møtetranskript';

  @override
  String get diarizationNotInstalled =>
      'Ikke installert — møtetalere skilles ikke';

  @override
  String diarizationInstallFailed(String error) {
    return 'Installasjon mislyktes: $error';
  }

  @override
  String get redownloadDiarizationModel =>
      'Last ned diariseringsmodell på nytt';

  @override
  String get diarizationRedownloadBody =>
      'Dette fjerner de nåværende diariseringsmodellene og laster dem ned på nytt.';

  @override
  String get removeDiarizationModel => 'Fjern diariseringsmodell';

  @override
  String get diarizationRemoveBody =>
      'Dette sletter diariseringsmodellene på enheten. Møtetranskript som allerede er produsert, påvirkes ikke.';

  @override
  String get enableNotifications => 'Slå på varslinger';

  @override
  String get enableSandboxing => 'Slå på sandkasse';

  @override
  String get enabled => 'På';

  @override
  String errorCreatingAgent(String error) {
    return 'Feil ved oppretting av agent: $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'Feil ved sletting av agent: $error';
  }

  @override
  String errorWithDetail(String error) {
    return 'Feil: $error';
  }

  @override
  String get expand => 'Utvid';

  @override
  String extractingModel(int pct) {
    return 'Pakker ut modell… $pct %';
  }

  @override
  String get fact => 'Faktum';

  @override
  String factCount(int count) {
    return '$count faktum';
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
  String get failed => 'Mislyktes';

  @override
  String failedToDispatch(String error) {
    return 'Kunne ikke sende: $error';
  }

  @override
  String get failedToLoad => 'Kunne ikke laste';

  @override
  String failedToLoadAgents(String error) {
    return 'Kunne ikke laste agenter: $error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'Kunne ikke laste strømmer: $error';
  }

  @override
  String get failedToLoadGifs => 'Kunne ikke laste GIF-er';

  @override
  String failedToLoadLogs(String error) {
    return 'Kunne ikke laste logger: $error';
  }

  @override
  String get failedToLoadRepos => 'Kunne ikke laste arkiv';

  @override
  String get failedToLoadWorkspaces => 'Kunne ikke laste arbeidsområder';

  @override
  String failedToStartAiReview(String error) {
    return 'Kunne ikke starte AI-gjennomgang: $error';
  }

  @override
  String get failedToStartMicTest => 'Kunne ikke starte mikrofontest.';

  @override
  String failedToSubmitReview(String error) {
    return 'Kunne ikke sende inn gjennomgang: $error';
  }

  @override
  String failedToUpload(String name, String error) {
    return 'Kunne ikke laste opp $name: $error';
  }

  @override
  String failedWithError(String error) {
    return 'Mislyktes: $error';
  }

  @override
  String get failure => 'Feil';

  @override
  String get feedAlreadyExists => 'En strøm med denne URL-en finnes allerede.';

  @override
  String get feedUrlExample => 'f.eks. https://example.com/feed.xml';

  @override
  String get feedUrlLabel => 'Strøm-URL';

  @override
  String feedsCount(int count) {
    return 'Strømmer ($count)';
  }

  @override
  String get filesChanged => 'Endrede filer';

  @override
  String filesCount(int count) {
    return '$count fil(er)';
  }

  @override
  String get filesMentionSection => 'Filer';

  @override
  String get filterAgents => 'Filtrer agenter…';

  @override
  String get filterFilesHint => 'Filtrer filer…';

  @override
  String get filterLists => 'Filterlister';

  @override
  String get filterSkillsPlaceholder => 'Filtrer ferdigheter…';

  @override
  String get finish => 'Fullfør';

  @override
  String get fix => 'Rett';

  @override
  String get forward => 'Fremover';

  @override
  String get gatesGithubPatPush =>
      'Styrer injeksjon av GitHub PAT. Påkrevd for at agenten skal kunne pushe.';

  @override
  String get general => 'Generelt';

  @override
  String get githubLink => 'GitHub-lenke';

  @override
  String get claudeStatusFetchFailed => 'Nådde ikke status.claude.com';

  @override
  String get claudeStatusOpenInBrowser => 'Åpne status.claude.com';

  @override
  String get githubStatusFetchFailed => 'Nådde ikke githubstatus.com';

  @override
  String get githubDegradedTitle => 'GitHub rapporterer problemer';

  @override
  String githubDegradedStatusLine(String status) {
    return 'GitHub-status: $status.';
  }

  @override
  String githubDegradedBody(String status) {
    return 'GitHub-status: $status. Pull request-data kan være utdaterte eller ufullstendige til det er gjenopprettet.';
  }

  @override
  String get githubStatusOpenInBrowser => 'Åpne githubstatus.com';

  @override
  String get githubStatusRefresh => 'Oppdater';

  @override
  String githubStatusUpdated(String time) {
    return 'Oppdatert $time';
  }

  @override
  String get kimiStatusFetchFailed => 'Nådde ikke status.moonshot.cn';

  @override
  String get kimiStatusOpenInBrowser => 'Åpne status.moonshot.cn';

  @override
  String get openaiStatusFetchFailed => 'Nådde ikke status.openai.com';

  @override
  String get openaiStatusOpenInBrowser => 'Åpne status.openai.com';

  @override
  String get serviceStatusMaintenance => 'Vedlikehold';

  @override
  String get serviceStatusMajorIssues => 'Alvorlige problemer';

  @override
  String get serviceStatusMinorIssues => 'Mindre problemer';

  @override
  String get serviceStatusOperational => 'Operativ';

  @override
  String get serviceStatusOutage => 'Avbrudd';

  @override
  String get serviceStatusTitle => 'Tjenestestatus';

  @override
  String get serviceStatusUnknown => 'Ukjent';

  @override
  String lastChecked(String time) {
    return 'Sjekket $time';
  }

  @override
  String get lastCheckedRecently => 'Sjekket nylig';

  @override
  String get giveYourWorkAHome => 'Gi arbeidet ditt et hjem.';

  @override
  String get goBack => 'Gå tilbake';

  @override
  String get goForward => 'Gå fremover';

  @override
  String get googleFonts => 'Google fonts';

  @override
  String get high => 'Høy';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count timer siden',
      one: '1 time siden',
    );
    return '$_temp0';
  }

  @override
  String get images => 'Bilder';

  @override
  String get inactive => 'Inaktiv';

  @override
  String get install => 'Installer';

  @override
  String get installRequired => 'Installasjon kreves';

  @override
  String installedVersion(String version) {
    return 'Installert $version';
  }

  @override
  String get invite => 'Inviter';

  @override
  String get inviteAgent => 'Inviter agent';

  @override
  String get isolateAgentExecution => 'Isoler agentkjøring.';

  @override
  String get justNow => 'Akkurat nå';

  @override
  String get keepSandboxing => 'Behold sandkasse';

  @override
  String get keybindingAddARepositoryDescription => 'Legg til et arkiv';

  @override
  String get keybindingAddRepository => 'Legg til arkiv';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'Bokmerk eller fjern bokmerke for valgt artikkel';

  @override
  String get keybindingCommandPalette => 'Kommandopalett';

  @override
  String get keybindingCreateANewAgentDescription => 'Opprett en ny agent';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'Opprett et nytt arbeidsområde';

  @override
  String get keybindingFocusSearch => 'Fokuser søk';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'Fokuser søkefeltet for pull requests';

  @override
  String get keybindingNewAgent => 'Ny agent';

  @override
  String get keybindingNewWorkspace => 'Nytt arbeidsområde';

  @override
  String get keybindingNextArticle => 'Neste artikkel';

  @override
  String get keybindingNextSpace => 'Neste område';

  @override
  String get keybindingNextWorkspace => 'Neste arbeidsområde';

  @override
  String get keybindingOpenArticle => 'Åpne artikkel';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'Åpne eller lukk arbeidsområdebytteren i sidestolpen';

  @override
  String get keybindingOpenPr => 'Åpne PR';

  @override
  String get keybindingOpenSettings => 'Åpne innstillinger';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'Åpne appinnstillingene';

  @override
  String get keybindingOpenTheCommandPaletteDescription =>
      'Åpne kommandopaletten';

  @override
  String get keybindingOpenTheSelectedArticleDescription =>
      'Åpne den valgte artikkelen';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'Åpne den valgte pull requesten';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'Åpne det valgte arbeidsområdet';

  @override
  String get keybindingOpenWorkspace => 'Åpne arbeidsområde';

  @override
  String get keybindingPreviousArticle => 'Forrige artikkel';

  @override
  String get keybindingPreviousSpace => 'Forrige område';

  @override
  String get keybindingPreviousWorkspace => 'Forrige arbeidsområde';

  @override
  String get keybindingRefresh => 'Oppdater';

  @override
  String get keybindingRefreshAllFeedsDescription => 'Oppdater alle strømmer';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'Oppdater listen over pull requests';

  @override
  String get keybindingRescanForAdaptersDescription =>
      'Skann på nytt etter adaptere';

  @override
  String get keybindingSelectTheNextArticleDescription => 'Velg neste artikkel';

  @override
  String get keybindingSelectTheNextSpaceDescription => 'Velg neste område';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'Velg forrige artikkel';

  @override
  String get keybindingSelectThePreviousSpaceDescription =>
      'Velg forrige område';

  @override
  String get keybindingSendMessage => 'Send melding';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'Send gjeldende melding';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Bytt mellom lyst og mørkt modus';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Bytt til det åttende arbeidsområdet';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Bytt til det femte arbeidsområdet';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'Bytt til det første arbeidsområdet';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'Bytt til det fjerde arbeidsområdet';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'Bytt til neste arbeidsområde';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'Bytt til det niende arbeidsområdet';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'Bytt til forrige arbeidsområde';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'Bytt til det andre arbeidsområdet';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'Bytt til det sjuende arbeidsområdet';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'Bytt til det sjette arbeidsområdet';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'Bytt til det tredje arbeidsområdet';

  @override
  String get keybindingToggleBookmark => 'Slå bokmerke av/på';

  @override
  String get keybindingToggleTheme => 'Bytt tema';

  @override
  String get keybindingToggleWorkspaceSwitcher =>
      'Slå arbeidsområdebytter av/på';

  @override
  String get keybindingWorkspace1 => 'Arbeidsområde 1';

  @override
  String get keybindingWorkspace2 => 'Arbeidsområde 2';

  @override
  String get keybindingWorkspace3 => 'Arbeidsområde 3';

  @override
  String get keybindingWorkspace4 => 'Arbeidsområde 4';

  @override
  String get keybindingWorkspace5 => 'Arbeidsområde 5';

  @override
  String get keybindingWorkspace6 => 'Arbeidsområde 6';

  @override
  String get keybindingWorkspace7 => 'Arbeidsområde 7';

  @override
  String get keybindingWorkspace8 => 'Arbeidsområde 8';

  @override
  String get keybindingWorkspace9 => 'Arbeidsområde 9';

  @override
  String get keybindings => 'Hurtigtaster';

  @override
  String get keybindingsDescription =>
      'Alle hurtigtaster. Snarveiene er faste og kan ikke tilordnes på nytt.';

  @override
  String get killRunning => 'Avslutt kjørende';

  @override
  String get languageSystem => 'System';

  @override
  String get leaveACommentEllipsis => 'Skriv en kommentar…';

  @override
  String get legendLabel => 'Forklaring';

  @override
  String get lessLabel => 'Mindre';

  @override
  String get letsPluginTools => 'La oss koble til verktøyene dine.';

  @override
  String get level => 'Nivå';

  @override
  String get loadingAgents => 'Laster agenter…';

  @override
  String get loadingModels => 'Laster modeller…';

  @override
  String get loadingProviders => 'Laster leverandører…';

  @override
  String get logLevel => 'Loggnivå';

  @override
  String get logs => 'Logger';

  @override
  String get low => 'Lav';

  @override
  String get maintenance => 'Vedlikehold';

  @override
  String get manageParticipants => 'Administrer deltakere';

  @override
  String get manageWorkspaces => 'Administrer arbeidsområder';

  @override
  String get reorderWorkspace => 'Endre rekkefølge på arbeidsområde';

  @override
  String get matchOsAppearance => 'Følg OS-utseendet eller velg en fast modus.';

  @override
  String get mcpAuthToken => 'MCP-autentiseringstoken';

  @override
  String get mcpNotAvailableOnServer =>
      'MCP-serverstyring er ikke tilgjengelig på den tilkoblede serveren.';

  @override
  String get modelManagedOnServer =>
      'Denne modellen kjører på serververten og administreres der.';

  @override
  String get mcpServer => 'MCP-server';

  @override
  String get medium => 'Middels';

  @override
  String get memoryDataHint =>
      'Fakta og policyer vises her etter hvert som agenter jobber.';

  @override
  String get memoryLabel => 'Minne';

  @override
  String get merge => 'Slå sammen';

  @override
  String get merged => 'Sammenslått';

  @override
  String get messagePlaceholder => 'Melding… (@ for å nevne, / for kommandoer)';

  @override
  String get navConversations => 'Områder';

  @override
  String get microphonePermissionDenied => 'Mikrofontillatelse avslått.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutter siden',
      one: '1 minutt siden',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'Modell';

  @override
  String get modified => 'Endret';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count måneder siden',
      one: '1 måned siden',
    );
    return '$_temp0';
  }

  @override
  String get moreLabel => 'Mer';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'Navn';

  @override
  String get nameAndTitleRequired => 'Navn og tittel er påkrevd.';

  @override
  String get nameAndUrlRequired => 'Navn og URL påkrevd';

  @override
  String get nameLabel => 'Navn';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'Innebygd sandkasse er tilgjengelig på $platform.';
  }

  @override
  String get nativeSandboxNeedsInstall =>
      'Installasjon av innebygd sandkasse kreves';

  @override
  String get navObservability => 'Observabilitet';

  @override
  String get navSettings => 'Innstillinger';

  @override
  String networkBlockCount(int count) {
    return '$count nettverksblokker';
  }

  @override
  String get neutral => 'Nøytral';

  @override
  String get newCommitsPushed =>
      'Nye commits ble pushet — klikk for å laste inn diff på nytt';

  @override
  String get newFact => 'Nytt faktum';

  @override
  String get newPolicy => 'Ny policy';

  @override
  String get newsfeed => 'Nyhetsstrøm';

  @override
  String get newsfeedLabel => 'Nyhetsstrøm';

  @override
  String get newsfeedSettingsDescription =>
      'Administrer abonnerte strømmer og leserinnstillinger.';

  @override
  String get newsfeedSettingsTitle => 'Innstillinger for nyhetsstrøm';

  @override
  String get nextMatch => 'Neste treff (↵)';

  @override
  String get noActiveWorkspace =>
      'Ingen aktivt arbeidsområde eller arkiv valgt.';

  @override
  String get noActiveWorkspaceCreate => 'Ingen aktivt arbeidsområde';

  @override
  String get noActiveWorkspaceGithub =>
      'Ingen aktivt arbeidsområde med et GitHub-arkiv.';

  @override
  String get noAgents => 'Ingen agenter';

  @override
  String get noArticlesYet => 'Ingen artikler ennå';

  @override
  String get noArticlesYetBody => 'Artikler fra strømmene dine vises her.';

  @override
  String get noExecutionLogsYet => 'Ingen kjørelogger ennå';

  @override
  String get noFacts => 'Ingen fakta ennå';

  @override
  String get noFeedsYet => 'Ingen strømmer ennå';

  @override
  String get noFileAnchor =>
      'Ingen filanker — kan ikke legge inn innlinjekommentar.';

  @override
  String get noFileChangesInScope => 'Ingen filendringer i dette omfanget';

  @override
  String get noGifsFound => 'Ingen GIF-er funnet';

  @override
  String get noInputDevicesDetected =>
      'Ingen inngangsenheter oppdaget — bruker systemstandard.';

  @override
  String get noMatchingFiles => 'Ingen matchende filer';

  @override
  String get noMatchingGoogleFonts => 'Ingen matchende Google Fonts.';

  @override
  String get noMemoryData => 'Ingen minnedata ennå';

  @override
  String get noMessagesYet => 'Ingen meldinger ennå';

  @override
  String get noModelsAdvertised =>
      'Ingen modeller annonsert av denne adapteren.';

  @override
  String get noOpenPullRequests => 'Ingen åpne pull requests';

  @override
  String get noPolicies => 'Ingen policyer ennå';

  @override
  String get noReposInWorkspaceYet => 'Ingen arkiv i dette arbeidsområdet ennå';

  @override
  String get noRunnersDetected =>
      'Ingen kjørere oppdaget ennå. Oppdater for å skanne på nytt.';

  @override
  String get noSavedArticles => 'Ingen lagrede artikler';

  @override
  String get noSavedArticlesBody => 'Artikler du lagrer vises her.';

  @override
  String noShortcutsMatch(String query) {
    return 'Ingen snarveier matcher «$query»';
  }

  @override
  String get noSystemFonts => 'Ingen systemskrifter oppdaget.';

  @override
  String get noTokenSet => 'Ingen token satt — tilgangen er uten begrensning.';

  @override
  String get noWorkingMemory => 'Ingen arbeidsminnenotater ennå.';

  @override
  String get noneAllRoles => 'Ingen (alle roller)';

  @override
  String get notAvailable => 'Ikke tilgjengelig';

  @override
  String get notConfiguredLabel => 'Ikke konfigurert.';

  @override
  String get notFoundLabel => 'Ikke funnet';

  @override
  String get notes => 'Notater';

  @override
  String get notificationAgentFinished => 'Agent ferdig';

  @override
  String get notificationPrMentioned => 'Nevnt i pull request';

  @override
  String get notificationNewMessages => 'Nye meldinger';

  @override
  String get notificationPrMerged => 'PR sammenslått';

  @override
  String get notificationPrPublished => 'PR publisert';

  @override
  String get notificationReviewRequested => 'Gjennomgang forespurt';

  @override
  String get notifications => 'Varslinger';

  @override
  String get notifyAgentRunCompleted =>
      'Varsle når en agent fullfører en kjøring.';

  @override
  String get notifyPrMentioned => 'Varsle når du blir nevnt i en pull request.';

  @override
  String get notifyNewMessages =>
      'Varsle om nye agentmeldinger i andre områder.';

  @override
  String get notifyPrMerged => 'Varsle når en pull request slås sammen.';

  @override
  String get notifyPrPublished =>
      'Varsle når en agent publiserer en pull request.';

  @override
  String get notifyReviewRequested =>
      'Varsle når gjennomgangen din blir forespurt på en pull request.';

  @override
  String get notificationReviewStale => 'Gjennomgang utdatert';

  @override
  String get notifyReviewStale =>
      'Når nye commits lander på en pull request du allerede har gjennomgått';

  @override
  String get notificationPrMergeReadiness => 'Klar til sammenslåing';

  @override
  String get notifyPrMergeReadiness =>
      'Varsle når en pull request du har skrevet blir sammenslåbar, eller slutter å være det.';

  @override
  String get notificationPrReviewDecision => 'Gjennomgangsvedtak';

  @override
  String get notifyPrReviewDecision =>
      'Varsle når en reviewer godkjenner, ber om endringer eller får en godkjenning avvist.';

  @override
  String get notificationPrChecksStatus => 'Sjekker';

  @override
  String get notifyPrChecksStatus =>
      'Varsle når CI feiler på en pull request du har skrevet, og når den kommer seg.';

  @override
  String get notificationPrThreadActivity => 'Gjennomgangstråder';

  @override
  String get notifyPrThreadActivity =>
      'Varsle når noen svarer i eller løser en tråd du er i.';

  @override
  String get notificationPrReadyToMerge => 'Klar til sammenslåing';

  @override
  String notificationPrReadyToMergeBody(String prTitle) {
    return '$prTitle har alt den trenger.';
  }

  @override
  String get notificationPrMergeBlocked => 'Ikke lenger sammenslåbar';

  @override
  String notificationPrMergeBlockedBodyConflicts(String prTitle) {
    return '$prTitle har konflikter mot basegrenen.';
  }

  @override
  String notificationPrMergeBlockedBodyBehind(String prTitle) {
    return '$prTitle ligger bak basegrenen.';
  }

  @override
  String notificationPrMergeBlockedBodyReviews(String prTitle) {
    return '$prTitle venter på en påkrevd gjennomgang.';
  }

  @override
  String notificationPrMergeBlockedBodyChanges(String prTitle) {
    return 'En reviewer ba om endringer på $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyChecks(String prTitle) {
    return 'Sjekker feiler på $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyOther(String prTitle) {
    return '$prTitle kan ikke lenger slås sammen.';
  }

  @override
  String get notificationPrApproved => 'Pull request godkjent';

  @override
  String notificationPrApprovedBodyBy(String login, String prTitle) {
    return '$login godkjente $prTitle';
  }

  @override
  String notificationPrApprovedBody(String prTitle) {
    return '$prTitle ble godkjent';
  }

  @override
  String notificationPrReviewersRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviewere som fortsatt skal svare',
      one: '1 reviewer som fortsatt skal svare',
      zero: 'ingen reviewere igjen',
    );
    return '$_temp0';
  }

  @override
  String get notificationPrChangesRequested => 'Endringer forespurt';

  @override
  String notificationPrChangesRequestedBodyBy(String login, String prTitle) {
    return '$login ba om endringer på $prTitle';
  }

  @override
  String notificationPrChangesRequestedBody(String prTitle) {
    return 'Det ble bedt om endringer på $prTitle';
  }

  @override
  String get notificationPrReviewDismissed => 'Godkjenning avvist';

  @override
  String notificationPrReviewDismissedBody(String prTitle) {
    return '$prTitle trenger gjennomgang på nytt.';
  }

  @override
  String get notificationPrChecksFailed => 'Sjekker feilet';

  @override
  String notificationPrChecksFailedBody(String checkName, String prTitle) {
    return '$checkName feilet på $prTitle';
  }

  @override
  String notificationPrChecksFailedBodyUnnamed(String prTitle) {
    return 'Sjekker feiler på $prTitle';
  }

  @override
  String get notificationPrChecksRecovered => 'Sjekker består';

  @override
  String notificationPrChecksRecoveredBody(String prTitle) {
    return '$prTitle er grønn igjen.';
  }

  @override
  String notificationPrMentionedInCommentBody(String login, String location) {
    return '$login nevnte deg i $location';
  }

  @override
  String get notificationPrThreadReplied => 'Nytt svar';

  @override
  String notificationPrThreadRepliedBody(String login, String location) {
    return '$login svarte i $location';
  }

  @override
  String get notificationPrThreadResolved => 'Tråd løst';

  @override
  String notificationPrThreadResolvedBody(String location) {
    return 'Tråden din i $location ble løst.';
  }

  @override
  String get notificationGroupAgents => 'Agenter';

  @override
  String get notificationGroupPullRequests => 'Pull requests';

  @override
  String get notificationGroupMessages => 'Meldinger';

  @override
  String get notificationGroupTickets => 'Saker';

  @override
  String get notificationGroupCalendar => 'Kalender';

  @override
  String get notificationGroupMachines => 'Maskiner';

  @override
  String get notificationsMutedRepos => 'Dempede arkiv';

  @override
  String notificationsMutedReposCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arkiv dempet',
      one: '1 arkiv dempet',
      zero: 'Ingen arkiv dempet',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMuteRepo => 'Demp dette arkivet';

  @override
  String get onboardingLinuxDescription =>
      'Control Center kan bruke Linux-containere for å isolere agentkjøring.';

  @override
  String get onboardingMacosDescription =>
      'Control Center bruker innebygd sandkasse på macOS for å isolere agentkjøring.';

  @override
  String get onboardingUnsupportedDescription =>
      'Sandkasse er ikke tilgjengelig på denne plattformen. Agentkjøring skjer uten isolasjon.';

  @override
  String get openArticlesInApp => 'Åpne artikler i appen';

  @override
  String get openInBrowser => 'Åpne i nettleser';

  @override
  String get openedInYourBrowser => 'Åpnet i nettleseren din.';

  @override
  String get openLabel => 'Åpne';

  @override
  String get openOnGithub => 'Åpne på GitHub';

  @override
  String get openStatus => 'Åpen';

  @override
  String get optionalPersonaDescription => 'Valgfri personabeskrivelse';

  @override
  String get otherLabel => 'Annet';

  @override
  String get ownerOrganization => 'Eier / organisasjon';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get passed => 'Bestått';

  @override
  String get pasteValueHere => 'Lim inn verdi her';

  @override
  String get persona => 'Persona';

  @override
  String get policies => 'Policyer';

  @override
  String get policiesHint => 'Policyer vises her når agenter fremmer fakta.';

  @override
  String get policy => 'Policy';

  @override
  String get popular => 'Populært';

  @override
  String get port => 'Port';

  @override
  String get postingEllipsis => 'Sender…';

  @override
  String get prCommits => 'Commits';

  @override
  String get prMergedBody => 'En pull request ble slått sammen';

  @override
  String get prMoreActions => 'Flere handlinger';

  @override
  String get prTitle => 'PR-tittel';

  @override
  String get reviewCommentHint =>
      'Klikk godkjenn, eller legg til en kommentar eller reaksjon om du har mer på hjertet…';

  @override
  String get nothingToPreview => 'Ingenting å forhåndsvise';

  @override
  String get previousMatch => 'Forrige treff (⇧↵)';

  @override
  String get priorityReviewsDescription =>
      'Prioriterte gjennomganger og arkivoversikt.';

  @override
  String get prsCreated => 'PR-er opprettet';

  @override
  String get prsMerged => 'PR-er sammenslått';

  @override
  String get publishToGithub => 'Publiser til GitHub';

  @override
  String get published => 'Publisert';

  @override
  String get pullRequestApproved => 'Pull request godkjent';

  @override
  String get pullRequests => 'Pull requests';

  @override
  String get questionLabel => 'SPØRSMÅL';

  @override
  String get queued => 'I kø';

  @override
  String get react => 'Reager';

  @override
  String get readPrsIssuesMetadata =>
      'Lar agenten lese PR-er, issues og arkivmetadata.';

  @override
  String get readerPreferences => 'Leserinnstillinger';

  @override
  String get reasoningEffort => 'Resonneringsinnsats';

  @override
  String get recommendLabel => 'ANBEFAL';

  @override
  String recordingFromDevice(String device) {
    return 'Tar opp fra $device.';
  }

  @override
  String get redownload => 'Last ned på nytt';

  @override
  String get redownloadEmbeddingModel =>
      'Laste ned innbyggingsmodellen på nytt?';

  @override
  String get redownloadVoiceModel => 'Laste ned stemmemodellen på nytt?';

  @override
  String get refinePlan => 'Forbedre plan';

  @override
  String get refresh => 'Oppdater';

  @override
  String get refreshAll => 'Oppdater alle';

  @override
  String get refreshAllFeeds => 'Oppdater alle strømmer';

  @override
  String get reject => 'Avvis';

  @override
  String get rejected => 'Avvist';

  @override
  String get reload => 'Last inn på nytt';

  @override
  String get remove => 'Fjern';

  @override
  String get removeBookmark => 'Fjern bokmerke';

  @override
  String get removeEmbeddingModel => 'Fjerne innbyggingsmodellen?';

  @override
  String get removeLogo => 'Fjern logo';

  @override
  String get removeRepoFromWorkspace => 'Fjerne arkiv fra arbeidsområde?';

  @override
  String get removeVoiceModel => 'Fjerne stemmemodellen?';

  @override
  String get removed => 'Fjernet';

  @override
  String get renamed => 'Navn endret';

  @override
  String get reopen => 'Åpne på nytt';

  @override
  String get resolve => 'Løs';

  @override
  String get replyEllipsis => 'Svar…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$name fjernes fra dette arbeidsområdet. De lokale filene på disk røres ikke.';
  }

  @override
  String repoAccessNoticeBody(String repos) {
    return 'Serverens GitHub-påloggingsinformasjon kan ikke se $repos. Hvis et arkiv tilhører en organisasjon, installer GitHub App der eller koble til et token som har tilgang.';
  }

  @override
  String repoAccessNoticeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arkiv kan ikke nås',
      one: 'Et arkiv kan ikke nås',
    );
    return '$_temp0';
  }

  @override
  String get repoAccessNoticeSuspendedTitle =>
      'GitHub App-installasjonen er suspendert';

  @override
  String repoAccessNoticeSuspendedBody(String repos) {
    return 'Viser sist kjente data for $repos. Gjenoppta installasjonen på GitHub, eller koble til et token som har tilgang.';
  }

  @override
  String get repoNoAccessBadge => 'Ingen tilgang';

  @override
  String get reportsTo => 'Rapporterer til';

  @override
  String reposCount(int count) {
    return 'Arkiv ($count)';
  }

  @override
  String get reposDescription =>
      'De lokale utsjekkingene dette arbeidsområdet retter seg mot.';

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
    return 'Kunne ikke legge til $_temp0: $error';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arkiv lagt til',
      one: 'Arkiv lagt til',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => 'Arkivinnstillinger';

  @override
  String get repositoryName => 'Arkivnavn';

  @override
  String get requestChanges => 'Be om endringer';

  @override
  String get requested => 'Forespurt';

  @override
  String get requestedChanges => 'Ba om endringer';

  @override
  String requiredRoleLabel(String role) {
    return 'Påkrevd rolle: $role';
  }

  @override
  String get requiredRoleOptional => 'Påkrevd rolle (valgfritt)';

  @override
  String get requirements => 'Krav';

  @override
  String get reset => 'Tilbakestill';

  @override
  String get resolved => 'Løst';

  @override
  String get enclosedTerminalTitle => 'Isolert terminal';

  @override
  String get enclosedTerminalStart => 'Åpne skallet';

  @override
  String get enclosedTerminalStartHint =>
      'Dette skallet kjører inne i samtalens engangs-VM. Det starter når du åpner det, ikke når appen starter.';

  @override
  String get terminalStreamReconnecting =>
      'strøm avbrutt — kobler til på nytt…';

  @override
  String get terminalStreamError => 'strømfeil:';

  @override
  String get terminalShellExited => 'skall avsluttet';

  @override
  String get restartShell => 'Start skall på nytt';

  @override
  String get retry => 'Prøv på nytt';

  @override
  String get review => 'Gjennomgang';

  @override
  String get reviewedByMe => 'Gjennomgått av meg';

  @override
  String get reviewers => 'Reviewere';

  @override
  String get roleLabel => 'Rolle';

  @override
  String get ruleHint => 'Policyregelen (markdown støttes)';

  @override
  String get ruleLabel => 'Regel';

  @override
  String get runCompleted => 'Kjøring fullført';

  @override
  String get running => 'Kjører';

  @override
  String get runningLabel => 'kjører';

  @override
  String get runs => 'Kjøringer';

  @override
  String get runsLabel => 'Kjøringer';

  @override
  String get sandboxBackendNativeLabel => 'Innebygd sandkasse';

  @override
  String get sandboxBackendMicrovmLabel => 'Isolert VM';

  @override
  String get sandboxBackendNoneLabel => 'Ingen isolasjon';

  @override
  String get sandboxLinuxInstall =>
      'Innebygd sandkasse på Linux/WSL2 bruker bubblewrap. Installer med:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'Innebygd sandkasse er innebygd på macOS — bruker Apple Seatbelt (`sandbox-exec`). Ingen installasjon kreves.';

  @override
  String get sandboxPermissions => 'Sandkassetillatelser';

  @override
  String get sandboxUnsupported =>
      'Innebygd sandkasse støttes ikke på denne plattformen ennå. Faller tilbake til «Ingen isolasjon».';

  @override
  String get sandboxingDisabledDescription =>
      'Agenter kjører direkte på verten med fullt env — ikke anbefalt.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'Alle agentkall rutes gjennom $backend.';
  }

  @override
  String get save => 'Lagre';

  @override
  String get saveChanges => 'Lagre endringer';

  @override
  String get adapterArguments => 'Ekstra argumenter';

  @override
  String get adapterArgumentsHint => 'Flere CLI-flagg (f.eks. --yolo)';

  @override
  String get addVariable => 'Legg til variabel';

  @override
  String get environmentVariables => 'Miljøvariabler';

  @override
  String get environmentVariablesDescription =>
      'Egendefinerte miljøvariabler som sendes til denne adapteren (f.eks. API-nøkler). Lagres i nøkkelringen.';

  @override
  String get variableKey => 'Nøkkel';

  @override
  String get variableValue => 'Verdi';

  @override
  String get savingEllipsis => 'Lagrer…';

  @override
  String get scopeDiffToCommits =>
      'Avgrens diff til commits — Shift-klikk for intervall';

  @override
  String get noPrsMatchSearch => 'Ingen matchende pull requests';

  @override
  String get searchFactsHint => 'Søk i fakta…';

  @override
  String get searchFonts => 'Søk i skrifter…';

  @override
  String get searchGifs => 'Søk i GIF-er';

  @override
  String get searchGifsHint => 'Søk i GIF-er…';

  @override
  String get searchInDiffHint => 'Søk i diff…';

  @override
  String get searchOrTypeModel => 'Søk eller skriv et modellnavn…';

  @override
  String get searchPlaceholder => 'Søk…';

  @override
  String get searchShortcuts => 'Søk i snarveier…';

  @override
  String get shortcutUnavailableInBrowser => 'Utilgjengelig i nettleseren';

  @override
  String get searching => 'Søker…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sekunder siden',
      one: '1 sekund siden',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'Velg adapter';

  @override
  String get selectAdapterFirst => 'Velg en adapter først';

  @override
  String get selectAgentToReportTo => 'Velg agent å rapportere til…';

  @override
  String get selectAnAgent => 'Velg en agent';

  @override
  String get selectConversation => 'Velg en samtale';

  @override
  String get selectLabel => 'Velg';

  @override
  String get selectRunner => 'Velg en kjører';

  @override
  String get semanticSearch => 'Semantisk søk';

  @override
  String get send => 'Send';

  @override
  String get sendFirstMessage => 'Send den første meldingen';

  @override
  String get sendMessage => 'Send melding';

  @override
  String sentFindingsToAgent(int count) {
    return 'Sendte $count funn til agent.';
  }

  @override
  String setGithubLinkDescription(String name) {
    return 'Sett GitHub-eier og arkivnavn for $name. Dette brukes til å løse PR- og issue-referanser som #123 i markdown-innhold.';
  }

  @override
  String get setLabel => 'Sett';

  @override
  String get setToken => 'Sett token';

  @override
  String get settingsLabel => 'Innstillinger';

  @override
  String get settingsLanguage => 'Språk';

  @override
  String get settingsLanguageDescription => 'Velg appspråk.';

  @override
  String get shortTask => 'Kort oppgave';

  @override
  String get showNativeNotifications => 'Vis systemvarslinger for hendelser.';

  @override
  String get showSuperseded => 'Vis erstattede';

  @override
  String get signedIn => 'Logget inn.';

  @override
  String signedInAs(String username) {
    return 'Logget inn som $username.';
  }

  @override
  String get skillNameRequired => 'Ferdighetsnavn er påkrevd.';

  @override
  String skillSaved(String name) {
    return 'Ferdighet «$name» lagret.';
  }

  @override
  String get skillsSourcesTab => 'Kilder';

  @override
  String get skillSourcesDisclaimer =>
      'Ferdigheter installeres fra GitHub-arkiv du legger til. Arkivmetadata er ikke til å stole på — antivirus-skanningen er det egentlige sikkerhetssignalet.';

  @override
  String get skillSourcesEmpty => 'Ingen ferdighetsarkiv';

  @override
  String get skillSourcesEmptyHint =>
      'Legg til et GitHub-arkiv for å bla i ferdighetene.';

  @override
  String get skillSourceAdd => 'Legg til arkiv';

  @override
  String get skillSourceAddTitle => 'Legg til ferdighetsarkiv';

  @override
  String get skillSourceAddHint => 'https://github.com/owner/repo';

  @override
  String get skillSourceInvalidUrl =>
      'Skriv inn en GitHub-arkiv-URL (https://github.com/owner/repo).';

  @override
  String skillSourceAdded(String repo) {
    return 'Arkiv $repo lagt til.';
  }

  @override
  String skillSourceAlreadyAdded(String repo) {
    return 'Arkiv $repo er allerede lagt til.';
  }

  @override
  String skillSourceRemoved(String repo) {
    return 'Arkiv $repo fjernet.';
  }

  @override
  String get skillSourceRemove => 'Fjern';

  @override
  String skillSourceRemoveConfirmTitle(String repo) {
    return 'Fjerne $repo?';
  }

  @override
  String get skillSourceRemoveConfirmBody =>
      'Installerte ferdigheter forblir installert. Bare arkivkatalogen fjernes.';

  @override
  String get skillSourceNoSkills =>
      'Ingen ferdigheter funnet i dette arkivet (en ferdighet er en mappe som inneholder en SKILL.md).';

  @override
  String get skillSourceRefresh => 'Oppdater';

  @override
  String get skillSourceInstalledBadge => 'Installert';

  @override
  String get skillSourceUpdateBadge => 'Oppdatering tilgjengelig';

  @override
  String get skillSourceSlugTaken => 'Navn i bruk';

  @override
  String skillSourceFilesCount(num count) {
    return '$count filer';
  }

  @override
  String get skillSourceReadme => 'README';

  @override
  String get skillSourceNoReadme => 'Denne ferdigheten har ingen README.';

  @override
  String get skillSourceNoMatches => 'Ingen ferdigheter matcher filteret ditt.';

  @override
  String get skillUpdateAction => 'Oppdater';

  @override
  String get skillUninstallAction => 'Avinstaller';

  @override
  String skillUninstallConfirmTitle(String slug) {
    return 'Avinstallere «$slug»?';
  }

  @override
  String skillUninstalled(String slug) {
    return 'Ferdighet «$slug» avinstallert.';
  }

  @override
  String get skillFindingLine => 'linje';

  @override
  String get skillInstallAnywayOverride =>
      'Jeg forstår risikoen — installer likevel';

  @override
  String skillInstalled(String slug) {
    return 'Ferdighet «$slug» installert.';
  }

  @override
  String get skillPreviewCapabilities => 'Kapasiteter';

  @override
  String get skillPreviewFindings => 'Funn';

  @override
  String get skillPreviewGuardedActions => 'Beskyttede handlinger';

  @override
  String get skillPreviewLlmReviewed => 'LLM-gjennomgått';

  @override
  String get skillPreviewNoCapabilities => 'Ingen kapasiteter oppgitt.';

  @override
  String get skillPreviewNoFindings => 'Ingen funn.';

  @override
  String get skillPreviewScanning => 'Skanner ferdighet…';

  @override
  String get skillPreviewVerdictLabel => 'Skanningsutfall';

  @override
  String get skillPreviewVerdictPass => 'Bestått';

  @override
  String get skillPreviewVerdictQuarantine => 'I karantene';

  @override
  String get skillPreviewVerdictWarn => 'Advarsel';

  @override
  String get skillQuarantineWarning =>
      'Denne ferdigheten ble satt i karantene av skanneren. Å installere den kjører kode på maskinen din. Fortsett bare hvis du stoler på kilden og har gjennomgått funnene.';

  @override
  String skillDetachedFromAgents(String agents) {
    return 'I karantene og frakoblet agenter: $agents';
  }

  @override
  String get skillNotScanned => 'Ikke skannet';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => 'Manuell';

  @override
  String get skillOriginRegistry => 'Register';

  @override
  String get skillOriginRuntimeLocal => 'Lokal kjøretid';

  @override
  String get skillRulesStale => 'Skanning utdatert';

  @override
  String get skillSaveAnywayOverride => 'Jeg forstår risikoen — lagre likevel';

  @override
  String get skillSaveBlockedBody =>
      'Innholdet ble blokkert før noe ble skrevet.';

  @override
  String get skillSaveBlockedTitle => 'Lagring blokkert av skanningsporten';

  @override
  String get skillScanAction => 'Skann';

  @override
  String get skillScanAll => 'Skann alle';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass bestått · $warn advarsler · $quarantine i karantene';
  }

  @override
  String get skillStateDrifted => 'Endret siden installasjon';

  @override
  String get skillStateUnmanaged => 'Uadministrert';

  @override
  String get skillSeverityBlocked => 'Blokkert';

  @override
  String get skillSeverityWarn => 'Advarsel';

  @override
  String get skillsInstalledTab => 'Installert';

  @override
  String get skills => 'Ferdigheter';

  @override
  String get skipAcceptRisk => 'Hopp over — jeg tar risikoen';

  @override
  String get skipForNow => 'Hopp over for nå';

  @override
  String get skipSandboxing => 'Hopp over sandkasse';

  @override
  String get skipSandboxingDialogContent =>
      'Er du sikker på at du vil hoppe over sandkasse? Dette lar agenter kjøre kode på systemet ditt uten isolasjon.';

  @override
  String get somethingWentWrong => 'Noe gikk galt';

  @override
  String sourceCount(int count) {
    return '$count kilde';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count kilder';
  }

  @override
  String get sourceFacts => 'Kildefakta:';

  @override
  String get splitDiff => 'Delt (side om side) diff';

  @override
  String get startLabel => 'Start';

  @override
  String get startOnAppLaunch => 'Start ved appstart';

  @override
  String get statusLabel => 'Status';

  @override
  String get onboardingStepConnect => 'Koble til';

  @override
  String get onboardingStepWorkspace => 'Arbeidsområde';

  @override
  String get onboardingStepSandbox => 'Sandkasse';

  @override
  String get onboardingStepAdapter => 'Adapter';

  @override
  String get onboardingStepVoice => 'Stemme';

  @override
  String get stop => 'Stopp';

  @override
  String get stopped => 'Stoppet';

  @override
  String get strictIdentityCheck => 'Streng identitetssjekk';

  @override
  String get success => 'Vellykket';

  @override
  String get successLabel => 'Vellykket';

  @override
  String get suggestAChange => 'Foreslå en endring';

  @override
  String get suggestLabel => 'FORESLÅ';

  @override
  String get superseded => 'Erstattet';

  @override
  String get synced => 'Synkronisert';

  @override
  String get systemDefault => 'Systemstandard';

  @override
  String get systemFonts => 'Systemskrifter';

  @override
  String get systemPrompt => 'Systemprompt';

  @override
  String get systemPromptLabel => 'Systemprompt';

  @override
  String get talkToControlCenter => 'Snakk med Control Center.';

  @override
  String get taskMentionSection => 'Oppgave';

  @override
  String get testLabel => 'Test';

  @override
  String get theme => 'Tema';

  @override
  String get themeDark => 'Mørk';

  @override
  String get themeLight => 'Lys';

  @override
  String get themeSystem => 'System';

  @override
  String get thisCannotBeUndone => 'Dette kan ikke angres.';

  @override
  String get ticketLabel => 'SAK';

  @override
  String get titleLabel => 'Tittel';

  @override
  String get todayLabel => 'I dag';

  @override
  String get toggleTheme => 'Bytt tema';

  @override
  String get tokenConfigured => 'Konfigurert — klienter må vise dette tokenet.';

  @override
  String get topic => 'Emne';

  @override
  String get topicHint => 'f.eks. Tech Stack, Design System';

  @override
  String get totalRuns => 'Totalt antall kjøringer';

  @override
  String trackingParamsCount(int count) {
    return '$count sporingsparametre';
  }

  @override
  String get typeCommandOrSearch => 'Skriv en kommando eller søk…';

  @override
  String get typography => 'Typografi';

  @override
  String get unavailable => 'Utilgjengelig';

  @override
  String get unifiedDiff => 'Samlet diff';

  @override
  String get unknownAuthor => 'Ukjent';

  @override
  String get unnamedAgent => 'Navnløs agent';

  @override
  String get updateKey => 'Oppdater nøkkel';

  @override
  String get updateLabel => 'Oppdater';

  @override
  String get updateToken => 'Oppdater token';

  @override
  String updatedDaysAgo(int count) {
    return 'Oppdatert for ${count}d siden';
  }

  @override
  String updatedHoursAgo(int count) {
    return 'Oppdatert for ${count}t siden';
  }

  @override
  String get updatedJustNow => 'Oppdatert akkurat nå';

  @override
  String updatedMinutesAgo(int count) {
    return 'Oppdatert for ${count}min siden';
  }

  @override
  String get useSandbox => 'Bruk sandkasse';

  @override
  String get useWorkspaceDefault => 'Bruk standard for arbeidsområde';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      'La stå tomt for å bruke appens standard-User-Agent. Noen nettsteder blokkerer User-Agents som ikke er nettlesere.';

  @override
  String get usingSystemDefaultMicrophone =>
      'Bruker systemets standardmikrofon.';

  @override
  String get viewLabel => 'Vis';

  @override
  String get viewLogs => 'Vis logger';

  @override
  String voiceInstallFailed(String error) {
    return 'Installasjon mislyktes: $error';
  }

  @override
  String get voiceModelNotInstalled =>
      'Ikke installert. Laster ned ~200 MB én gang; kjører helt på enheten.';

  @override
  String get voiceModelNotInstalledLabel => 'Stemmemodell ikke installert.';

  @override
  String get voiceRedownloadBody =>
      'De eksisterende modellfilene slettes og ~200 MB-arkivet lastes ned på nytt. Stemmetranskripsjon er utilgjengelig til nedlastingen er ferdig.';

  @override
  String get voiceRemoveBody =>
      'Stemmetranskripsjon slås av til du installerer den på nytt. Du kan installere den når som helst.';

  @override
  String get voiceTranscription => 'Stemmetranskripsjon';

  @override
  String get weakIsolationDescription =>
      'Svak isolasjon — bare navneromsgrense, ingen kjernegrense.';

  @override
  String get whenOffNoDefaultRoute =>
      'Når av, starter sandkassen uten en standardrute.';

  @override
  String get whenOffServerStaysStopped =>
      'Når av, forblir serveren stoppet til du starter den.';

  @override
  String get speechModel => 'Talemodell';

  @override
  String get speechModelHint =>
      'Brukes til møtetranskripsjon og mikrofonen i meldingsfeltet.';

  @override
  String get voiceModelInstalled =>
      'Installert. Driver møtetranskripsjon og mikrofonknappen i meldingsfeltet.';

  @override
  String get meetingMicSilentWarning =>
      'Mikrofonen din kan være dempet — de andre snakker, men ingenting når mikrofonen din.';

  @override
  String get meetingSummaryPrivacyNotice =>
      'Opptak og transkripsjon blir på denne maskinen. Sammendraget skrives av en agent, så hvis den bruker en sky-modell sendes transkriptet og notatene dine til den leverandøren.';

  @override
  String get meetingTemplates => 'Maler for møtenotater';

  @override
  String get meetingTemplatesHint =>
      'Form AI-sammendraget for en type møte. Den aktive malen gjelder for nye og kjørte-på-nytt sammendrag.';

  @override
  String get meetingTemplateActive => 'Aktiv mal';

  @override
  String get meetingTemplateAdd => 'Legg til mal';

  @override
  String get meetingTemplateNewTitle => 'Ny mal';

  @override
  String get meetingTemplateEditTitle => 'Rediger mal';

  @override
  String get meetingTemplateNameLabel => 'Navn';

  @override
  String get meetingTemplateNameHint => 'f.eks. Sprintgjennomgang';

  @override
  String get meetingTemplateInstructionsLabel => 'Instruksjoner';

  @override
  String get meetingTemplateInstructionsHint =>
      'Hvordan skal AI-en strukturere og vektlegge disse notatene?';

  @override
  String get workingMemory => 'Arbeidsminne';

  @override
  String get workspaceName => 'Navn på arbeidsområde';

  @override
  String get workspaceScopedSkills =>
      'Arbeidsområde-avgrensede ferdighetsfiler knyttet til agenter.';

  @override
  String get workspaces => 'Arbeidsområder';

  @override
  String get writePrivateNotes =>
      'Skriv private notater, observasjoner, planer…';

  @override
  String get writeSkillContent => 'Skriv ferdighetsinnholdet her (Markdown)…';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count år siden',
      one: '1 år siden',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'I går';

  @override
  String get focusModeStart => 'Start fokusøkt';

  @override
  String get focusModeConfigTitle => 'Start fokusøkt';

  @override
  String get focusModeGoalLabel => 'Mål';

  @override
  String get focusModeGoalHint => 'Hva jobber du med?';

  @override
  String get focusModeDurationLabel => 'Varighet';

  @override
  String get focusModeBlockNotifications => 'Blokker varslinger';

  @override
  String get focusModeStartButton => 'Start';

  @override
  String get focusModeFloat => 'Minimer til linje';

  @override
  String get focusModeActiveTooltip =>
      'Fokusmodus aktiv — trykk for å avslutte';

  @override
  String get dismiss => 'Avvis';

  @override
  String get acceptAndResolve => 'Godta og løs';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'Du har gjennomgått i $minutes min — forskning tyder på at gjennomgangskvaliteten kan synke etter 60 min. Vurder en pause.';
  }

  @override
  String get notificationSound => 'Varslingslyd';

  @override
  String get notificationSoundDescription =>
      'Lyd som spilles når en varsling vises.';

  @override
  String get notificationSoundNone => 'Ingen';

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
  String get notificationSoundMigrosSoft => 'Migros (myk)';

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
  String get notificationSoundTest => 'Test';

  @override
  String get notificationVolume => 'Volum';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'Ingen PR-er av @$login i dette arbeidsområdet';
  }

  @override
  String get usersLabel => 'Brukere';

  @override
  String get mergePullRequest => 'Slå sammen pull request';

  @override
  String get forceMergePullRequest => 'Tvangssammenslå pull request';

  @override
  String get closePullRequest => 'Lukk pull request';

  @override
  String get closePullRequestConfirm =>
      'Er du sikker på at du vil lukke denne pull requesten?';

  @override
  String get stackedPullRequests => 'Stablede pull requests';

  @override
  String partOfStack(int position, int total) {
    return 'Del av en stabel ($position av $total)';
  }

  @override
  String get createStack => 'Opprett stabel';

  @override
  String get createStackDialogTitle => 'Opprett pull request-stabel';

  @override
  String createStackDialogBody(int count) {
    return 'Disse $count pull requestene stables, nedenfra og opp:';
  }

  @override
  String get createStackInvalidSelection =>
      'Velg minst to pull requests fra samme arkiv for å opprette en stabel';

  @override
  String get createStackNotAChain =>
      'De valgte pull requestene danner ikke en kjede: hver pull requests basegren må være den forriges head-gren';

  @override
  String get createStackAlreadyStacked =>
      'Én eller flere valgte pull requests er allerede i en stabel';

  @override
  String get stackCreated => 'Stabel opprettet';

  @override
  String get stackCreationFailed => 'Kunne ikke opprette stabelen';

  @override
  String get squashAndMerge => 'Squash og slå sammen';

  @override
  String get createMergeCommit => 'Opprett en merge-commit';

  @override
  String get rebaseAndMerge => 'Rebase og slå sammen';

  @override
  String get commitTitle => 'Commit-tittel';

  @override
  String get commitDescription => 'Commit-beskrivelse';

  @override
  String get pullRequestMerged => 'Pull request sammenslått';

  @override
  String get pullRequestClosed => 'Pull request lukket';

  @override
  String failedToMergePr(String error) {
    return 'Kunne ikke slå sammen: $error';
  }

  @override
  String failedToClosePr(String error) {
    return 'Kunne ikke lukke: $error';
  }

  @override
  String get markReadyForReview => 'Klar for gjennomgang';

  @override
  String get markReadyForReviewConfirm =>
      'Denne pull requesten forlater utkast. Reviewere varsles, påkrevde sjekker begynner å styre sammenslåingen, og automatisering som venter på klare pull requests kjører.';

  @override
  String get convertToDraft => 'Konverter til utkast';

  @override
  String get convertToDraftConfirm =>
      'Denne pull requesten går tilbake til utkast. Ventende gjennomgangsforespørsler avvises, og den kan ikke slås sammen før du merker den som klar igjen.';

  @override
  String get pullRequestMarkedReady =>
      'Pull request merket som klar for gjennomgang';

  @override
  String get pullRequestConvertedToDraft =>
      'Pull request konvertert til utkast';

  @override
  String failedToMarkPrReady(String error) {
    return 'Kunne ikke merke som klar for gjennomgang: $error';
  }

  @override
  String failedToConvertPrToDraft(String error) {
    return 'Kunne ikke konvertere til utkast: $error';
  }

  @override
  String get checksFailing => 'Sjekker feiler';

  @override
  String get reviewsPending => 'Noen gjennomganger venter';

  @override
  String get mergeConflictsWithBase =>
      'Denne grenen har konflikter som må løses';

  @override
  String get branchOutOfDateWithBase =>
      'Denne grenen er utdatert i forhold til basegrenen';

  @override
  String get mergeBlockedByBranchProtection =>
      'Grenbeskyttelse blokkerer denne sammenslåingen';

  @override
  String get confirm => 'Bekreft';

  @override
  String get trustedSitesSectionTitle => 'Pålitelige nettsteder';

  @override
  String get trustedSitesEmpty =>
      'Ingen pålitelige nettsteder. Legg til et domene for å slå av blocking der.';

  @override
  String get addTrustedSite => 'Legg til pålitelig nettsted';

  @override
  String get removeTrustedSite => 'Fjern';

  @override
  String get disableBlockingForThisSite =>
      'Slå av blocking på dette nettstedet';

  @override
  String get enableBlockingForThisSite => 'Slå på blocking på dette nettstedet';

  @override
  String get enterDomainHint => 'f.eks. example.com';

  @override
  String get invalidDomain => 'Skriv inn et gyldig domene (f.eks. example.com)';

  @override
  String get pageLoadTimedOut =>
      'Innlasting av siden tidsavbrutt. Last inn på nytt eller åpne i nettleser.';

  @override
  String get pipelinesScreenTitle => 'Pipelines';

  @override
  String get pipelinesScreenSubtitle =>
      'Deklarative flertrinns agentarbeidsflyter';

  @override
  String get pipelinesRunPipeline => 'Kjør pipeline';

  @override
  String get pipelineRunLauncherTitle => 'Kjør pipeline';

  @override
  String get pipelineRunSubtitle =>
      'Velg en pipeline og fyll inn inndataene for å starte en kjøring.';

  @override
  String get pipelineRunNoInputsBadge => 'Ingen inndata';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count inndata',
      one: '1 inndata',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'Denne pipelinen tar ingen inndata.';

  @override
  String get pipelineRunSubmit => 'Kjør pipeline';

  @override
  String get pipelineRunCouldNotStart => 'Kunne ikke starte kjøringen.';

  @override
  String pipelineRunStarted(String name) {
    return 'Startet $name';
  }

  @override
  String get pipelineRunEmptyTitle => 'Ingen pipelines klare til å kjøre';

  @override
  String get pipelineRunEmptyHint =>
      'Slå på en pipeline og manuell kjøring i redigereren for å starte den her.';

  @override
  String get pipelineRunManageTemplates => 'Administrer pipelines';

  @override
  String get pipelineRunSettingsTitle => 'Manuell kjøring';

  @override
  String get pipelineRunSettingsAllow => 'Tillat manuell kjøring';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'Vis denne pipelinen på kjøringssiden slik at den kan startes for hånd.';

  @override
  String get pipelineRunSettingsConcurrencyTitle => 'Samtidighet';

  @override
  String get pipelineRunSettingsMaxParallel => 'Maks parallelle kjøringer';

  @override
  String get pipelineRunSettingsMaxParallelHelp =>
      'La stå tomt for ubegrenset. Ekstra kjøringer venter i kø og starter når plasser blir ledige.';

  @override
  String get pipelineRunSettingsMaxParallelHint => 'Ubegrenset';

  @override
  String get pipelineRunSettingsMaxParallelInvalid =>
      'Skriv inn et heltall på 1 eller mer, eller la stå tomt for ubegrenset.';

  @override
  String get pipelineRunSettingsInputsTitle => 'Inndata';

  @override
  String get pipelineRunSettingsAddInput => 'Legg til inndata';

  @override
  String get pipelineRunSettingsNoInputs => 'Ingen inndata ennå.';

  @override
  String get pipelineInputEditTitle => 'Inndatafelt';

  @override
  String get pipelineInputKeyLabel => 'Nøkkel';

  @override
  String get pipelineInputKeyHelp =>
      'Tilstandsnøkkelen verdien lagres under (f.eks. repo_full_name).';

  @override
  String get pipelineInputLabelLabel => 'Etikett';

  @override
  String get pipelineInputTypeLabel => 'Type';

  @override
  String get pipelineInputOptionsLabel => 'Alternativer (kommaseparert)';

  @override
  String get pipelineInputDefaultLabel => 'Standardverdi';

  @override
  String get pipelineInputPlaceholderLabel => 'Plassholder';

  @override
  String get pipelineInputHelpLabel => 'Hjelpetekst';

  @override
  String get pipelineInputRequiredLabel => 'Påkrevd';

  @override
  String get pipelineInputTypeText => 'Tekst';

  @override
  String get pipelineInputTypeMultiline => 'Flerlinjetekst';

  @override
  String get pipelineInputTypeNumber => 'Tall';

  @override
  String get pipelineInputTypeBoolean => 'Bryter';

  @override
  String get pipelineInputTypeSelect => 'Velg';

  @override
  String get pipelinesEmpty => 'Ingen pipeline-kjøringer ennå';

  @override
  String get pipelinesEmptyHint => 'Klikk «Kjør pipeline» for å starte én.';

  @override
  String get pipelinesNoSteps => 'Ingen steg registrert ennå';

  @override
  String get pipelinesNoActiveWorkspace =>
      'Velg et arbeidsområde for å se pipelinene';

  @override
  String pipelinesLoadError(String error) {
    return 'Kunne ikke laste pipelines: $error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'Kunne ikke starte pipeline: $error';
  }

  @override
  String get pipelineStatusPending => 'Venter';

  @override
  String get pipelineStatusQueued => 'I kø';

  @override
  String get pipelineStatusRunning => 'Kjører';

  @override
  String get pipelineStatusSuspended => 'Suspendert';

  @override
  String get pipelineStatusCompleted => 'Fullført';

  @override
  String get pipelineStatusFailed => 'Mislyktes';

  @override
  String get pipelineStatusCancelled => 'Avbrutt';

  @override
  String get pipelineStatusSkipped => 'Hoppet over';

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
    return 'inaktiv $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip =>
      'Tid holdt utenfor aktivt totalt: kjøringen var stoppet eller ventet mellom steg.';

  @override
  String get pipelineStepStarted => 'Startet';

  @override
  String get pipelineStepFinished => 'Ferdig';

  @override
  String get pipelineStepDurationLabel => 'Varighet';

  @override
  String get pipelineStepBranch => 'Gren';

  @override
  String get pipelineStepViewConversation => 'Vis samtale';

  @override
  String get pipelineStepError => 'Feil';

  @override
  String get pipelineStepInput => 'Inndata';

  @override
  String get pipelineStepOutput => 'Utdata';

  @override
  String get pipelineStepNotExecuted => 'Ikke kjørt ennå';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'Mislyktes ved $step';
  }

  @override
  String get pipelineRunTriggerManual => 'Manuell';

  @override
  String get pipelineStepSkippedReason => 'Hoppet over';

  @override
  String get pipelineStepPriorAttempts => 'Tidligere forsøk';

  @override
  String get pipelineStepAttemptLabel => 'Forsøk';

  @override
  String pipelineStepAttemptN(int number) {
    return 'Forsøk $number';
  }

  @override
  String get pipelineStepAttemptInterrupted => 'Avbrutt';

  @override
  String get pipelineRunColumnPipeline => 'Pipeline';

  @override
  String get pipelineRunColumnDuration => 'Varighet';

  @override
  String get pipelineRunQueueNext => 'Neste';

  @override
  String pipelineRunQueuePosition(int position) {
    return '$position i kø';
  }

  @override
  String get pipelineRunColumnStarted => 'Startet';

  @override
  String get pipelineRunHistory => 'Kjøringshistorikk';

  @override
  String get pipelineRunHistoryEmpty => 'Ingen andre kjøringer ennå';

  @override
  String pipelineRunRerunAgo(String time) {
    return 'Kjør på nytt $time';
  }

  @override
  String pipelineRunAttempt(int number) {
    return 'Forsøk $number';
  }

  @override
  String pipelineRunFirstStarted(String time) {
    return 'først startet $time';
  }

  @override
  String get pipelineRunFilterAll => 'Alle';

  @override
  String get pipelineRunFilterEmpty => 'Ingen kjøringer matcher dette filteret';

  @override
  String get relativeJustNow => 'akkurat nå';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min siden',
      one: '1 min siden',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count timer siden',
      one: '1 time siden',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dager siden',
      one: '1 dag siden',
    );
    return '$_temp0';
  }

  @override
  String get teamsTitle => 'Team';

  @override
  String get teamsAddTeam => 'Legg til team';

  @override
  String get teamsLoadError => 'Kunne ikke laste team';

  @override
  String get teamsEmptyTitle => 'Ingen team ennå';

  @override
  String get teamsEmptyDescription =>
      'Grupper agenter i team slik at arbeid tildelt et team går via en leder som delegerer.';

  @override
  String get teamCreateTitle => 'Nytt team';

  @override
  String get teamEditTitle => 'Rediger team';

  @override
  String get teamNameLabel => 'Teamnavn';

  @override
  String get teamNameHint => 'f.eks. Frontend';

  @override
  String get teamDescriptionLabel => 'Beskrivelse';

  @override
  String get teamDescriptionHint => 'Hva dette teamet er ansvarlig for';

  @override
  String get teamLeaderLabel => 'Leder';

  @override
  String get teamLeaderHelp =>
      'Koordinatoren som tar imot teamtildelt arbeid og delegerer til det best egnede medlemmet.';

  @override
  String get teamNoLeader => 'Ingen leder';

  @override
  String get teamInstructionsLabel => 'Driftsinstruksjoner';

  @override
  String get teamInstructionsHelp =>
      'Legges til lederens briefing — teamkonvensjoner, eskaleringsregler, tone.';

  @override
  String get teamInstructionsHint => 'Valgfritt';

  @override
  String get teamSaved => 'Team lagret';

  @override
  String get teamMembersError => 'Kunne ikke laste medlemmer';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count medlemmer',
      one: '1 medlem',
      zero: 'Ingen medlemmer',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => 'Legg til medlem';

  @override
  String get teamAddMemberTitle => 'Legg til medlemmer';

  @override
  String teamAddMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Legg til $count',
      one: 'Legg til 1',
      zero: 'Legg til',
    );
    return '$_temp0';
  }

  @override
  String get teamNoAgentsToAdd => 'Alle agenter er allerede på dette teamet.';

  @override
  String get teamRemoveMember => 'Fjern fra team';

  @override
  String get teamLeaderBadge => 'Leder';

  @override
  String get teamUnknownAgent => 'Ukjent agent';

  @override
  String get teamMembersEmpty => 'Ingen medlemmer ennå';

  @override
  String get teamMembersEmptyDescription =>
      'Legg til agenter slik at lederen har noen å delegere til.';

  @override
  String get teamSelectPrompt => 'Velg et team';

  @override
  String get teamSelectPromptDescription =>
      'Velg et team fra listen, eller opprett et nytt.';

  @override
  String get teamDeleteTitle => 'Slette team?';

  @override
  String teamDeleteBody(String name) {
    return '$name slettes. Agentene påvirkes ikke.';
  }

  @override
  String get teamHasLeaderTooltip => 'Har en leder';

  @override
  String get pipelineTemplatesNav => 'Pipeline-maler';

  @override
  String get pipelineTemplatesTitle => 'Pipeline-maler';

  @override
  String get pipelineTemplatesSubtitle =>
      'Dra-og-slipp-redigerer for pipelinene som orkestrerer agentene dine.';

  @override
  String get pipelineTemplatesNew => 'Ny mal';

  @override
  String get pipelineTemplatesEmpty =>
      'Ingen pipeline-maler ennå. Opprett én for å komme i gang.';

  @override
  String get pipelineTemplateBuiltInBadge => 'Innebygd';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'Slette mal?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'Slette pipeline-malen $name? Dette kan ikke angres.';
  }

  @override
  String get pipelineTemplateEditorSubtitle =>
      'Dra nodetyper fra sidestolpen til lerretet, og kople dem sammen.';

  @override
  String get unsavedChanges => 'Ulagrede endringer';

  @override
  String get nodeLibraryTitle => 'Nodebibliotek';

  @override
  String get nodeLibraryHint =>
      'Dra en oppføring til lerretet for å legge til en node.';

  @override
  String get editorEmptyCanvas => 'Dra en node fra biblioteket for å starte.';

  @override
  String get pipelineWhenThisHappens => 'Når dette skjer';

  @override
  String get pipelineDoThis => 'Gjør dette';

  @override
  String get pipelineAddStep => 'Legg til steg';

  @override
  String get pipelineTidyUp => 'Rydd opp i oppsettet';

  @override
  String get pipelineEditorHint =>
      'Dra steg for å ordne · dra et håndtak for å koble';

  @override
  String get pipelineRemoveConnection => 'Fjern tilkobling';

  @override
  String get pipelineDragToConnect => 'Dra for å koble';

  @override
  String get pipelineNewDefaultName => 'Ny pipeline';

  @override
  String get nodeCategoryTriggers => 'Utløsere';

  @override
  String get triggerEventWebhook => 'Webhook';

  @override
  String get pipelineAddTrigger => 'Legg til en utløser';

  @override
  String get pipelineOnEvent => 'Ved hendelse';

  @override
  String get nodeConfigTitle => 'Nodekonfig';

  @override
  String get nodeConfigKind => 'Type';

  @override
  String get nodeConfigLabel => 'Etikett';

  @override
  String get nodeConfigAgent => 'Agent';

  @override
  String get nodeConfigAgentHint => 'Velg en agent…';

  @override
  String get nodeConfigInputKeys => 'Inndatanøkler (kommaseparert)';

  @override
  String get nodeConfigInputKeysHelp =>
      'Tilstandsnøkler denne noden bruker. Brukes til plassholdererstatning i prompten.';

  @override
  String get nodeConfigRepos => 'Arkiv som skal klones';

  @override
  String get nodeConfigReposHelp =>
      'Arkiv som klones og kodeindekseres når denne noden starter samtalen. Å velge alle arkiv kloner alle (standarden).';

  @override
  String get nodeConfigRepoBranchHint => 'Gren (standard)';

  @override
  String get nodeConfigRepoBranchHelp =>
      'Grenen hver utsjekking kuttes fra. La stå tomt for arkivets egen standardgren — worktree får fortsatt sin egen gren, så ingenting en agent commiter lander på denne.';

  @override
  String nodeConfigReposDynamic(String entries) {
    return 'Dynamiske oppføringer beholdt: $entries';
  }

  @override
  String get nodeConfigCreateConversation => 'Åpne en samtale i det';

  @override
  String get nodeConfigCreateConversationHelp =>
      'La dette være av når flere agentnoder følger — hver åpner sin egen navngitte strøm. Slå det på når én agentnode følger, slik at rommet aldri viser en uten tittel ved siden av.';

  @override
  String get nodeConfigConversationTitle => 'Samtalenavn';

  @override
  String get nodeConfigConversationTitleHelp =>
      'Gi agentnoden nedstrøms samme navn, så jobber begge i én strøm. Standard er nodens etikett.';

  @override
  String get nodeConfigSpaceName => 'Områdenavn';

  @override
  String get nodeConfigSpaceNameHelp =>
      'Hva rommet denne noden åpner heter. Støtter de samme tilstandsplassholderne som en prompt. La stå tomt for å bruke nodens etikett.';

  @override
  String get nodeConfigSpaceNameHint => 'Review of pr_number';

  @override
  String get nodeConfigStreamTitle => 'Samtalenavn';

  @override
  String get nodeConfigStreamTitleHelp =>
      'Den navngitte strømmen denne nodens agent jobber i inne i rommet. Støtter de samme tilstandsplassholderne som en prompt. La den stå tom, så lander turen i rommets stående samtale, der en fan-out fletter alle agenter.';

  @override
  String get nodeConfigConversationTitleHint => 'Arkitekturanalyse';

  @override
  String get nodeConfigOutputKey => 'Utdatanøkkel';

  @override
  String get nodeConfigPrompt => 'Promptmal';

  @override
  String get nodeConfigPromptHelp =>
      'Bruk dobbeltkrøllparentes-plassholdere for å hente verdier fra tilstand ved kjøretid.';

  @override
  String get nodeConfigScript => 'Bash-skript';

  @override
  String get nodeConfigScriptHelp =>
      'Kjører med bash -c. GITHUB_TOKEN er satt. Plassholdere erstattes før kjøring.';

  @override
  String get nodeConfigRouteKeys => 'Rutenøkler';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'Rutenøkkel fra $source';
  }

  @override
  String get conditionSectionTitle => 'Betingelse';

  @override
  String get conditionMode => 'Modus';

  @override
  String get conditionModeFilesAny => 'Fil(er) finnes — hvilken som helst';

  @override
  String get conditionModeFilesAll => 'Filer finnes — alle';

  @override
  String get conditionModeComparison => 'Sammenligning';

  @override
  String get conditionModeSwitch => 'Bryter';

  @override
  String get conditionFilePaths => 'Filstier';

  @override
  String get conditionFilePathsAnyHelp =>
      'Én sti per linje, relativt til basismappen. Ruter true når minst én finnes.';

  @override
  String get conditionFilePathsAllHelp =>
      'Én sti per linje, relativt til basismappen. Ruter true bare når alle finnes.';

  @override
  String get conditionBaseKey => 'Nøkkel for basismappe';

  @override
  String get conditionBaseKeyHelp =>
      'Tilstandsnøkkel som holder mappen stiene løses mot (standard repo_local_path).';

  @override
  String get conditionRecursive => 'Søk i undermapper';

  @override
  String get conditionNegate => 'Inverter: ruter true når mangler';

  @override
  String get conditionLeft => 'Venstre verdi';

  @override
  String get conditionOperator => 'Operator';

  @override
  String get conditionRight => 'Høyre verdi';

  @override
  String get conditionSwitchKey => 'Bytt på tilstandsnøkkel';

  @override
  String get conditionCases => 'Tilfeller (kommaseparert)';

  @override
  String get conditionCasesHelp =>
      'Rutenøkler som skal matches mot verdien, i rekkefølge.';

  @override
  String get conditionDefaultCase => 'Standardtilfelle';

  @override
  String get triggerManualHelp => 'Vis på kjøringssiden og start for hånd.';

  @override
  String get triggerKindSchedule => 'Etter en tidsplan';

  @override
  String get triggerScheduleExprLabel => 'Tidsplan (cron eller every:seconds)';

  @override
  String get triggerTimezoneLabel => 'Tidssone (valgfritt)';

  @override
  String get triggerCatchUpLabel => 'Ved tapte kjøringer';

  @override
  String get triggerCatchUpRunOnce => 'Kjør én gang';

  @override
  String get triggerCatchUpSkip => 'Hopp over';

  @override
  String get syncHealthTitle => 'Synkroniseringshelse';

  @override
  String get syncHealthNoConfigs => 'Ingen synkroniseringstilkoblinger ennå';

  @override
  String get syncHealthNeverSynced => 'Aldri synkronisert';

  @override
  String get syncOutcomeOk => 'Synkronisert';

  @override
  String get syncOutcomeFailed => 'Mislyktes';

  @override
  String get syncOutcomeSkipped => 'Hoppet over';

  @override
  String syncHealthFailedStreak(int count) {
    return '$count feil på rad';
  }

  @override
  String get triggerWebhookHelp =>
      'En signert webhook-URL genereres. Eksterne systemer POSTer til den for å starte denne pipelinen.';

  @override
  String get triggerWebhookPathLabel => 'Webhook-sti';

  @override
  String get triggerMatchStatusLabel => 'Bare når statusen er';

  @override
  String get triggerSummaryNone => 'Ingen utløsere';

  @override
  String triggerEverySeconds(int seconds) {
    return 'Hver ${seconds}s';
  }

  @override
  String get triggerEventManual => 'Manuell kjøring';

  @override
  String get triggerEventSchedule => 'Tidsplan';

  @override
  String get triggerEventPrStatusChanged => 'PR-status endret';

  @override
  String get triggerEventExternalPr => 'Ekstern PR åpnet';

  @override
  String get triggerEventPrPublished => 'PR publisert';

  @override
  String get triggerEventPrMerged => 'PR sammenslått';

  @override
  String get triggerEventRepoAdded => 'Arkiv lagt til';

  @override
  String get triggerEventCodeGraphWatch => 'Filendring';

  @override
  String pipelineRunCauseChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count endrede filer',
      one: '1 endret fil',
    );
    return '$_temp0';
  }

  @override
  String pipelineRunCauseMorePaths(int count) {
    return '+$count til';
  }

  @override
  String get pipelineRunCauseRescan => 'Endret på disk';

  @override
  String get pipelineRunCauseInitial => 'Første indeks av denne utsjekkingen';

  @override
  String get triggerEventMessageReceived => 'Melding mottatt';

  @override
  String get triggerEventTicketCompleted => 'Sak fullført';

  @override
  String get triggerEventTicketFailed => 'Sak mislyktes';

  @override
  String get triggerEventTicketCancelled => 'Sak avbrutt';

  @override
  String get triggerEventBudgetCrossed => 'Budsjettgrense krysset';

  @override
  String get nodeLibrarySearchHint => 'Søk i noder';

  @override
  String get nodeLibraryNoMatches => 'Ingen matchende noder';

  @override
  String get nodeCategoryFlow => 'Flyt og logikk';

  @override
  String get nodeCategoryPr => 'PR-gjennomgang';

  @override
  String get nodeCategoryAgents => 'Agenter';

  @override
  String get nodeCategoryMessaging => 'Meldinger';

  @override
  String get nodeCategoryCode => 'Kode';

  @override
  String get triggerDisabledTag => 'av';

  @override
  String get pipelineInputTypeRepo => 'Arkiv';

  @override
  String get pipelineRunNoRepos => 'Ingen arkiv i dette arbeidsområdet ennå.';

  @override
  String get allowTicketingApi => 'Tillat API-kall for saker';

  @override
  String get ticketingApiKey => 'API-nøkkel for saker';

  @override
  String get ticketingApiKeySubtitle =>
      'Injiserer saksleverandørens API-nøkkel i sandkassen.';

  @override
  String get ticketingProvider => 'Saksleverandør';

  @override
  String get connectGitHubAndTicketing =>
      'Koble til en kodevert slik at Control Center kan lese pull requests, issues og gjennomganger. Koble eventuelt til en saksleverandør. Påloggingsinformasjon holdes av serveren din, aldri av denne maskinen.';

  @override
  String get triggerEventTicketAssigned => 'Sak tildelt';

  @override
  String get triggerEventTicketCreated => 'Sak opprettet';

  @override
  String get triggerEventTicketStatusChanged => 'Sakstatus endret';

  @override
  String get triggerEventMeetingRecordingStopped => 'Møteopptak stoppet';

  @override
  String get triggerEventSkillUpdated => 'Ferdighet oppdatert';

  @override
  String get triggerEventSpaceDeleted => 'Område slettet';

  @override
  String get triggerExternalPrHelp =>
      'En pull-forespørsel åpnet på kodeverten, ikke fra Control Center.';

  @override
  String get triggerPrPublishedHelp =>
      'En pull-forespørsel åpnet fra Control Center eller av en agent.';

  @override
  String get triggerPrStatusChangedHelp =>
      'Flettet, lukket, åpnet, gjenåpnet eller godkjent. Filtrer etter status i inspektøren.';

  @override
  String get triggerPrMergedHelp =>
      'Bare når pull-forespørselen flettes, ikke når den lukkes eller gjenåpnes.';

  @override
  String get triggerRepoAddedHelp =>
      'Et depot knyttes til dette arbeidsområdet.';

  @override
  String get triggerCodeGraphWatchHelp =>
      'En fil i et tilknyttet depot endres på disken.';

  @override
  String get triggerMessageReceivedHelp => 'En ny melding kommer i et område.';

  @override
  String get triggerTicketCreatedHelp =>
      'En sak opprettes i dette arbeidsområdet.';

  @override
  String get triggerTicketStatusChangedHelp =>
      'En sak flytter mellom statuser.';

  @override
  String get triggerTicketCompletedHelp => 'En sak fullføres uten feil.';

  @override
  String get triggerTicketFailedHelp =>
      'Et agentkjøring mislyktes, og saken merkes som mislykket.';

  @override
  String get triggerTicketCancelledHelp =>
      'En sak avbrytes og fortsetter ikke.';

  @override
  String get triggerBudgetCrossedHelp =>
      'En utgiftsgrense for arbeidsområde eller agent overskrides.';

  @override
  String get triggerTicketAssignedHelp =>
      'En sak tildeles en person, agent eller et team.';

  @override
  String get triggerMeetingRecordingStoppedHelp => 'Et møteopptak avsluttes.';

  @override
  String get triggerSkillUpdatedHelp =>
      'En ferdighet installeres eller oppdateres.';

  @override
  String get triggerSpaceDeletedHelp => 'Et samtalerom slettes.';

  @override
  String get navTickets => 'Saker';

  @override
  String get ticketsTitle => 'Saker';

  @override
  String get newTicket => 'Ny sak';

  @override
  String get noTicketsYet => 'Ingen saker ennå';

  @override
  String get addCollaborator => 'Legg til samarbeidspartner';

  @override
  String get noCollaborators => 'Ingen samarbeidspartnere ennå';

  @override
  String get linkedPullRequests => 'Tilknyttede pull requests';

  @override
  String get noLinkedPullRequests => 'Ingen tilknyttede pull requests ennå';

  @override
  String get stopAgent => 'Stopp agent';

  @override
  String get ticketProperties => 'Egenskaper';

  @override
  String get ticketTabIssue => 'Issue';

  @override
  String get ticketSelectPrompt => 'Velg en sak for å se detaljene';

  @override
  String get unassigned => 'Ikke tildelt';

  @override
  String get ticketStatusBacklog => 'Backlog';

  @override
  String get ticketStatusOpen => 'Å gjøre';

  @override
  String get ticketStatusInProgress => 'Pågår';

  @override
  String get ticketStatusInReview => 'Til gjennomgang';

  @override
  String get ticketStatusDone => 'Ferdig';

  @override
  String get ticketStatusBlocked => 'Blokkert';

  @override
  String get ticketStatusFailed => 'Mislyktes';

  @override
  String get ticketStatusCancelled => 'Avbrutt';

  @override
  String get notificationTicketAssigned => 'Sak tildelt';

  @override
  String get notificationTicketStatusChanged => 'Saksstatus endret';

  @override
  String get priority => 'Prioritet';

  @override
  String get status => 'Status';

  @override
  String get assignee => 'Tildelt';

  @override
  String get labels => 'Etiketter';

  @override
  String get noLabelsYet => 'Ingen etiketter ennå';

  @override
  String get clearLabels => 'Fjern etiketter';

  @override
  String get pipelineStepAgentActivity => 'Agentaktivitet';

  @override
  String get runStatusCompleted => 'Fullført';

  @override
  String get runStatusQueued => 'I kø';

  @override
  String get ticketDescription => 'Beskrivelse';

  @override
  String get ticketPriorityNone => 'Ingen';

  @override
  String get ticketPriorityUrgent => 'Haster';

  @override
  String get ticketPriorityHigh => 'Høy';

  @override
  String get ticketPriorityMedium => 'Middels';

  @override
  String get ticketPriorityLow => 'Lav';

  @override
  String get ticketViewList => 'Liste';

  @override
  String get ticketViewBoard => 'Tavle';

  @override
  String get ticketTitlePlaceholder => 'Issue-tittel';

  @override
  String get ticketDescriptionPlaceholder => 'Legg til beskrivelse…';

  @override
  String get createMore => 'Opprett flere';

  @override
  String selectedCount(int count) {
    return '$count valgt';
  }

  @override
  String get clearSelection => 'Fjern utvalg';

  @override
  String get bulkDeleteTitle => 'Slett saker';

  @override
  String bulkDeleteMessage(int count) {
    return 'Slette $count valgte saker? Dette kan ikke angres.';
  }

  @override
  String get assignTo => 'Tildel til…';

  @override
  String get sectionMembers => 'Medlemmer';

  @override
  String get sectionAgents => 'Agenter';

  @override
  String get sidebarGroupWorkspace => 'Arbeidsområde';

  @override
  String get notificationsTitle => 'Varslinger';

  @override
  String get notificationsTooltip => 'Varslinger';

  @override
  String get notificationsEmpty => 'Du er ajour';

  @override
  String notificationsUnreadCount(int count) {
    return '$count ulest';
  }

  @override
  String get notificationsMarkRead => 'Merk som lest';

  @override
  String get notificationsMarkUnread => 'Merk som ulest';

  @override
  String get notificationsEntryActions => 'Varslingshandlinger';

  @override
  String get markAllRead => 'Merk alle som lest';

  @override
  String get teamsNav => 'Team';

  @override
  String get noWorkspace => 'Ingen arbeidsområde';

  @override
  String get selectWorkspace => 'Velg et arbeidsområde';

  @override
  String get navMemory => 'Minne';

  @override
  String get memoryTabFacts => 'Fakta';

  @override
  String get memoryTabPolicies => 'Policyer';

  @override
  String get memoryGraphShowFacts => 'Vis fakta';

  @override
  String get memoryGraphHideFacts => 'Skjul fakta';

  @override
  String get memoryGraphExpandAll => 'Utvid alle fakta';

  @override
  String get memoryGraphCollapseAll => 'Skjul alle fakta';

  @override
  String get memoryTabGraph => 'Kunnskapsgraf';

  @override
  String get memoryNoWorkspace => 'Velg et arbeidsområde for å se minnet.';

  @override
  String get searchArticles => 'Søk i artikler';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterUnread => 'Ulest';

  @override
  String get filterSaved => 'Lagret';

  @override
  String get saveArticle => 'Lagre artikkel';

  @override
  String get removeFromSaved => 'Fjern fra lagret';

  @override
  String get filterBySource => 'Filtrer etter kilde';

  @override
  String get viewAsList => 'Listevisning';

  @override
  String get viewAsGrid => 'Rutenettvisning';

  @override
  String get noMatchingArticles => 'Ingen matchende artikler';

  @override
  String get noMatchingArticlesBody => 'Prøv et annet søk eller kildefilter.';

  @override
  String get allCaughtUp => 'Ajour';

  @override
  String get allCaughtUpBody => 'Ingen uleste artikler — kom tilbake senere.';

  @override
  String get openArticlesInAppDescription =>
      'Åpne lenker i den innebygde leseren i stedet for standardnettleseren.';

  @override
  String get blockAdsTrackersDescription =>
      'Fjern annonser, sporere og infokapsler fra artikler du åpner i leseren.';

  @override
  String get agentQuestionHeader => 'Spørsmål til deg';

  @override
  String get agentQuestionAnsweredLabel => 'Besvart';

  @override
  String get agentQuestionFreeformHint => 'Skriv svaret ditt…';

  @override
  String agentQuestionProgress(int index, int count) {
    return 'Spørsmål $index av $count';
  }

  @override
  String get agentQuestionSkip => 'Hopp over';

  @override
  String get agentQuestionSkippedLabel => 'Hoppet over';

  @override
  String get agentQuestionFreeformOptionHint => 'Beskriv med egne ord…';

  @override
  String get reviewRequested => 'Gjennomgang forespurt';

  @override
  String get connectGitHubHint =>
      'Logg inn på GitHub eller legg til et token i Innstillinger → Arbeidsområde → Profil og identitet → Kodevert';

  @override
  String get connectGitHubToLoadPrs =>
      'Koble til GitHub for å laste pull requests';

  @override
  String get noRepositoriesConfigured => 'Ingen arkiv konfigurert';

  @override
  String openedAgo(String age) {
    return 'Åpnet $age';
  }

  @override
  String prTimelineOpened(String author) {
    return '$author åpnet denne pull requesten';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$author åpnet denne pull requesten med $_temp0';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return '$actor ba om gjennomgang fra $reviewers';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '$actor fjernet gjennomgangsforespørselen for $reviewers';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '$actor ba om gjennomgang fra $requested og fjernet gjennomgangsforespørselen for $removed';
  }

  @override
  String prTimelineAddedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'etikettene',
      one: 'etiketten',
    );
    return '$actor la til $_temp0 $labels';
  }

  @override
  String prTimelineRemovedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'etikettene',
      one: 'etiketten',
    );
    return '$actor fjernet $_temp0 $labels';
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
      other: 'etikettene',
      one: 'etiketten',
    );
    String _temp1 = intl.Intl.pluralLogic(
      removedCount,
      locale: localeName,
      other: 'etikettene',
      one: 'etiketten',
    );
    return '$actor la til $_temp0 $added og fjernet $_temp1 $removed';
  }

  @override
  String prTimelineCommitted(String author) {
    return '$author commitet';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$author pushet $_temp0';
  }

  @override
  String prTimelineApproved(String author) {
    return '$author godkjente disse endringene';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return '$author ba om endringer';
  }

  @override
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kodekommentarer',
      one: '1 kodekommentar',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '$author gjennomgikk';
  }

  @override
  String get prTimelineSomeone => 'Noen';

  @override
  String get prTimelineBotBadge => 'bot';

  @override
  String updatedAgo(String age) {
    return 'Oppdatert $age';
  }

  @override
  String get checksPassing => 'Sjekker består';

  @override
  String get checksRunning => 'Sjekker kjører';

  @override
  String get needsYourReview => 'Trenger din gjennomgang';

  @override
  String get checks => 'Sjekker';

  @override
  String get noReviewersAssigned => 'Ingen reviewere tildelt';

  @override
  String get noAssignees => 'Ingen tildelte';

  @override
  String get loadingEllipsis => 'Laster…';

  @override
  String get loadingChecks => 'Laster sjekker…';

  @override
  String get noChecksYet => 'Ingen sjekker har kjørt ennå';

  @override
  String get noChangesToReview => 'Ingen endringer å gjennomgå';

  @override
  String checksFailingCount(int count) {
    return '$count feiler';
  }

  @override
  String get showMore => 'Vis mer';

  @override
  String get showLess => 'Vis mindre';

  @override
  String get backToPullRequests => 'Tilbake til pull requests';

  @override
  String get pullRequestNotFound => 'Pull request ikke funnet';

  @override
  String get pullRequestNotFoundBody =>
      'Den kan ha blitt slått sammen, lukket eller flyttet.';

  @override
  String get couldntLoadPullRequest => 'Kunne ikke laste denne pull requesten';

  @override
  String get showDetails => 'Vis detaljer';

  @override
  String get noDescriptionProvided => 'Ingen beskrivelse oppgitt.';

  @override
  String get factsHint =>
      'Fakta vises her etter hvert som agentene dine lærer.';

  @override
  String get noFactsMatch => 'Ingen fakta matcher søket ditt';

  @override
  String get memoryLoadError => 'Kunne ikke laste minne';

  @override
  String get sortRecent => 'Nylig';

  @override
  String get sortConfidence => 'Sikkerhet';

  @override
  String get confidenceTooltip =>
      'Hvor sikre agenter er på at dette faktumet er sant, fra 0 til 100 %.';

  @override
  String get supersededTooltip => 'Et nyere faktum har erstattet dette.';

  @override
  String get domain => 'Domene';

  @override
  String get fitToView => 'Tilpass til visning';

  @override
  String get project => 'Prosjekt';

  @override
  String get newProject => 'Nytt prosjekt';

  @override
  String get editProject => 'Rediger prosjekt';

  @override
  String get deleteProject => 'Slett prosjekt';

  @override
  String get noProject => 'Ingen prosjekt';

  @override
  String get allTickets => 'Alle saker';

  @override
  String get projectNamePlaceholder => 'Prosjektnavn';

  @override
  String get projectDescriptionPlaceholder => 'Beskrivelse (valgfritt)';

  @override
  String get projectColorLabel => 'Farge';

  @override
  String get noProjectsYet => 'Ingen prosjekter ennå';

  @override
  String get projectTicketsEmpty => 'Ingen saker i dette prosjektet ennå';

  @override
  String get createProject => 'Opprett prosjekt';

  @override
  String projectProgress(int done, int total) {
    return '$done av $total ferdig';
  }

  @override
  String deleteProjectConfirm(String name) {
    return 'Slette «$name»? Sakene beholdes og fjernes fra prosjektet.';
  }

  @override
  String get projectStatusActive => 'Aktiv';

  @override
  String get projectStatusCompleted => 'Fullført';

  @override
  String get projectStatusArchived => 'Arkivert';

  @override
  String get markProjectCompleted => 'Merk som fullført';

  @override
  String get markProjectActive => 'Merk som aktiv';

  @override
  String get archiveProject => 'Arkiver';

  @override
  String get restoreProject => 'Gjenopprett';

  @override
  String get relations => 'Relasjoner';

  @override
  String get relateTo => 'Relater til';

  @override
  String get relationSubIssueOf => 'Underissue av…';

  @override
  String get relationParentOf => 'Overordnet av…';

  @override
  String get relationBlockedBy => 'Blokkert av…';

  @override
  String get relationBlocking => 'Blokkerer…';

  @override
  String get relationRelatedTo => 'Relatert til…';

  @override
  String get relationDuplicateOf => 'Duplikat av…';

  @override
  String get relationGroupParent => 'Overordnet';

  @override
  String get relationGroupSubIssues => 'Underissues';

  @override
  String get relationGroupBlockedBy => 'Blokkert av';

  @override
  String get relationGroupBlocking => 'Blokkerer';

  @override
  String get relationGroupRelated => 'Relatert';

  @override
  String get relationGroupDuplicateOf => 'Duplikat av';

  @override
  String get relationGroupDuplicatedBy => 'Duplisert av';

  @override
  String get copyId => 'Kopier ID';

  @override
  String get ticketIdCopied => 'Kopierte saks-ID';

  @override
  String get searchTicketsHint => 'Søk i saker…';

  @override
  String get noMatchingTickets => 'Ingen saker matcher';

  @override
  String get clearAll => 'Fjern alle';

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs PR-er',
      one: '1 PR',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos arkiv',
      one: '1 arkiv',
    );
    return '$_temp0 venter på gjennomgangen din på tvers av $_temp1';
  }

  @override
  String get manageWorkspacesSubtitle =>
      'Gi et arbeidsområde nytt navn og endre merket — velg ett til venstre for å redigere det.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arbeidsområder',
      one: '1 arbeidsområde',
      zero: 'Ingen arbeidsområder',
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
      zero: 'Ingen arkiv',
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
  String get uploadImage => 'Last opp bilde';

  @override
  String get failedToSaveLogo =>
      'Kunne ikke lagre logobildet. Sørg for at appen kan lese den valgte filen.';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG eller GIF opptil 2 MB. Ellers bruker vi initialen til arbeidsområdet.';

  @override
  String get workspaceNameFieldHelp =>
      'Vises i bytteren, brødsmulen og på hver skjerm.';

  @override
  String get dangerZone => 'Faresone';

  @override
  String get deleteThisWorkspace => 'Slett dette arbeidsområdet';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return 'Fjerner $name permanent, inkludert arkivtilkoblinger, agenter og minne. Dette kan ikke angres.';
  }

  @override
  String get discard => 'Forkast';

  @override
  String discardChangesQuestion(String name) {
    return 'Forkaste ulagrede endringer i $name?';
  }

  @override
  String get workspaceUpdated => 'Arbeidsområde oppdatert';

  @override
  String get editTitle => 'Rediger tittel';

  @override
  String get editDescription => 'Rediger beskrivelse';

  @override
  String get addDescription => 'Legg til en beskrivelse';

  @override
  String get prTitlePlaceholder => 'Tittel';

  @override
  String get prBodyPlaceholder => 'Skriv en beskrivelse';

  @override
  String get write => 'Skriv';

  @override
  String get overview => 'Oversikt';

  @override
  String get noFilesChanged => 'Ingen filer endret';

  @override
  String get diff => 'Diff';

  @override
  String get preview => 'Forhåndsvisning';

  @override
  String get imageDiffBefore => 'Før';

  @override
  String get imageDiffAfter => 'Etter';

  @override
  String get imageDiffModeTwoUp => 'Side om side';

  @override
  String get imageDiffModeSwipe => 'Sveip';

  @override
  String get imageDiffModeDifference => 'Differanse';

  @override
  String imageDiffChangedPercent(String percent) {
    return '$percent % endret';
  }

  @override
  String get imageDiffPictures => 'Bilder';

  @override
  String get imageDiffSource => 'Kilde';

  @override
  String get imageDiffDeleted => 'Slettet';

  @override
  String get imageDiffAdded => 'Lagt til';

  @override
  String imageDiffDimensions(int width, int height) {
    return 'B: ${width}px | H: ${height}px';
  }

  @override
  String get outdated => 'Utdatert';

  @override
  String get outdatedComments => 'Utdaterte kommentarer';

  @override
  String outdatedCountLabel(int count) {
    return '$count utdaterte';
  }

  @override
  String get prTemplateLabel => 'Mal';

  @override
  String get prTemplateDefault => 'Standard';

  @override
  String get addReviewers => 'Legg til reviewere';

  @override
  String get addAssignees => 'Legg til tildelte';

  @override
  String get searchUsers => 'Søk etter personer…';

  @override
  String get searchReviewers => 'Søk etter personer og team…';

  @override
  String get usersSectionLabel => 'Personer';

  @override
  String get userStatusBusy => 'Opptatt';

  @override
  String get teamsSectionLabel => 'Team';

  @override
  String get suggestedReviewers => 'Foreslåtte reviewere';

  @override
  String get noMatchingUsers => 'Ingen matchende personer';

  @override
  String get noMatchingReviewers => 'Ingen treff';

  @override
  String get requiredByCodeOwners => 'Påkrevd av code owners';

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
  String get markdownHeading => 'Overskrift';

  @override
  String get markdownBulletList => 'Punktliste';

  @override
  String get markdownChecklist => 'Sjekkliste';

  @override
  String get markdownCode => 'Kode';

  @override
  String get markdownLink => 'Lenke';

  @override
  String get markdownQuote => 'Sitat';

  @override
  String get markdownSupported => 'Markdown støttes';

  @override
  String get markdownAttachImages => 'Klikk for å legge til bilder';

  @override
  String failedToUpdateTitle(String error) {
    return 'Kunne ikke oppdatere tittel: $error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'Kunne ikke oppdatere beskrivelse: $error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'Kunne ikke oppdatere reviewere: $error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'Kunne ikke oppdatere tildelte: $error';
  }

  @override
  String get discardChangesConfirm => 'Forkaste endringene dine?';

  @override
  String get newPr => 'Ny PR';

  @override
  String get openPullRequest => 'Åpne en pull request';

  @override
  String get composePrSubtitle =>
      'Fra en gren du har pushet — ingen agenter eller saker involvert';

  @override
  String get createAsDraft => 'Opprett som utkast';

  @override
  String get composePrNoRepo => 'Ingen GitHub-arkiv valgt';

  @override
  String get composePrNoRepoHint =>
      'Velg et arbeidsområde med et GitHub-tilknyttet arkiv for å åpne en pull request.';

  @override
  String get composePrPickBranches =>
      'Velg en base- og sammenligningsgren for å forhåndsvise endringene.';

  @override
  String get composePrNothingToCompare =>
      'Det er ingen endringer mellom disse grenene.';

  @override
  String get repository => 'Arkiv';

  @override
  String get baseBranchLabel => 'Base';

  @override
  String get compareBranchLabel => 'Sammenlign';

  @override
  String get selectBranch => 'Velg en gren';

  @override
  String get navMeetings => 'Møter';

  @override
  String get meetingsNoWorkspace => 'Velg et arbeidsområde for å se møter.';

  @override
  String get meetingsEmpty => 'Ingen møter ennå';

  @override
  String get meetingsEmptyHint =>
      'Ta opp det første møtet — lyden blir på denne enheten, og agenten gjør det om til notater, beslutninger og tiltak.';

  @override
  String get meetingNotesHint =>
      'Skriv raske notater — agenten utvider dem etter møtet.';

  @override
  String get meetingSpeakerMe => 'Deg';

  @override
  String get meetingStatusRecording => 'Tar opp';

  @override
  String get meetingStatusProcessing => 'Behandler';

  @override
  String get meetingStatusDone => 'Ferdig';

  @override
  String get meetingStatusFailed => 'Mislyktes';

  @override
  String get meetingsSubtitle =>
      'Tatt opp og transkribert på denne enheten, deretter oppsummert av en agent.';

  @override
  String get meetingsRecordMeeting => 'Ta opp møte';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count behandles nå',
      one: '1 behandles nå',
    );
    return '$_temp0';
  }

  @override
  String meetingsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count møter',
      one: '1 møte',
      zero: 'Ingen møter',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLedgerOpenActions => 'Åpne tiltak';

  @override
  String get meetingsLedgerDecisions => 'Beslutninger';

  @override
  String get meetingsLiveOpen => 'Åpne opptak';

  @override
  String get meetingTemplateShort => 'Mal';

  @override
  String get meetingsStatThisWeek => 'Denne uken';

  @override
  String get meetingsStatRecorded => 'Tatt opp';

  @override
  String get meetingsFilterAll => 'Alle';

  @override
  String get meetingsFilterDone => 'Ferdig';

  @override
  String get meetingsFilterProcessing => 'Behandler';

  @override
  String get meetingsSearchHint => 'Filtrer etter tittel, person, app…';

  @override
  String get meetingsBucketToday => 'I dag';

  @override
  String get meetingsBucketYesterday => 'I går';

  @override
  String get meetingsBucketEarlierThisWeek => 'Tidligere denne uken';

  @override
  String get meetingsBucketLastWeek => 'Forrige uke';

  @override
  String get meetingsBucketOlder => 'Eldre';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count beslutninger',
      one: '1 beslutning',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total tiltak';
  }

  @override
  String get meetingsEnhancedPill => 'forbedret';

  @override
  String get meetingsTranscribing => 'transkriberer og oppsummerer…';

  @override
  String get meetingsOpenAction => 'Åpne';

  @override
  String get meetingsStopProcessing => 'Stopp';

  @override
  String get meetingsStillTranscribing =>
      'Transkriberer fortsatt — sammendraget vises når det er ferdig.';

  @override
  String get meetingsNoMatch => 'Ingen møter matcher';

  @override
  String get meetingsNoMatchHint => 'Prøv et annet filter eller søkeord.';

  @override
  String get meetingBackAllMeetings => 'Alle møter';

  @override
  String get meetingReRunSummary => 'Kjør sammendrag på nytt';

  @override
  String get meetingExport => 'Eksporter';

  @override
  String get meetingAugmentingBanner =>
      'Utvider notatene dine fra transkriptet — henter ut beslutninger og tiltak…';

  @override
  String get meetingTabNotes => 'Notater';

  @override
  String get meetingTabTranscript => 'Transkript';

  @override
  String get meetingTabActionItems => 'Tiltak';

  @override
  String get meetingTabDecisions => 'Beslutninger';

  @override
  String get meetingNotesEnhancedToggle => 'Forbedret';

  @override
  String get meetingNotesYoursToggle => 'Dine notater';

  @override
  String get meetingEnhancedByAgent => 'Forbedret av agent · fra transkript';

  @override
  String get meetingEnhancedPending =>
      'Agenten jobber fortsatt med dette sammendraget.';

  @override
  String get meetingNotesEmpty => 'Ingen forbedrede notater ennå.';

  @override
  String get meetingNotesSavedLocally => 'Lagret lokalt';

  @override
  String get meetingNotesSaving => 'Lagrer…';

  @override
  String get meetingViewFullTranscript => 'Vis hele transkriptet';

  @override
  String get meetingTranscriptSearchHint => 'Søk i transkriptet…';

  @override
  String get meetingSpeakerEveryone => 'Alle';

  @override
  String get meetingSpeakerOthers => 'Andre';

  @override
  String get meetingTranscriptEmpty => 'Ingen transkript ennå.';

  @override
  String get meetingActionItemsEmpty => 'Ingen tiltak hentet ut.';

  @override
  String get meetingActionItemFrom => 'fra dette møtet';

  @override
  String get meetingCreateTicket => 'Opprett sak';

  @override
  String meetingTicketCreated(String key) {
    return 'Sak $key opprettet og sendt.';
  }

  @override
  String get meetingTicketFailed => 'Kunne ikke opprette saken.';

  @override
  String get meetingDecisionsEmpty => 'Ingen beslutninger logget.';

  @override
  String get meetingEditTitle => 'Rediger tittel';

  @override
  String get meetingTitleLabel => 'Tittel';

  @override
  String get meetingAddActionItem => 'Legg til tiltak';

  @override
  String get meetingEditActionItem => 'Rediger tiltak';

  @override
  String get meetingDeleteActionItem => 'Slett tiltak';

  @override
  String get meetingActionItemContentLabel => 'Tiltak';

  @override
  String get meetingActionItemContentHint => 'Hva må skje?';

  @override
  String get meetingActionItemOwnerLabel => 'Eier';

  @override
  String get meetingActionItemOwnerHint => 'Hvem er ansvarlig? (valgfritt)';

  @override
  String get meetingAddDecision => 'Legg til beslutning';

  @override
  String get meetingEditDecision => 'Rediger beslutning';

  @override
  String get meetingDeleteDecision => 'Slett beslutning';

  @override
  String get meetingDecisionContentLabel => 'Beslutning';

  @override
  String get meetingDecisionContentHint => 'Hva ble besluttet?';

  @override
  String get meetingReRunStarted =>
      'Kjører oppsummereren på transkriptet på nytt…';

  @override
  String get meetingReRunNoTranscript =>
      'Det er ingen transkript å oppsummere ennå.';

  @override
  String get meetingExportCopied =>
      'Notater kopiert til utklippstavlen som Markdown.';

  @override
  String get meetingExportSaved => 'Møte eksportert.';

  @override
  String meetingExportFailed(String error) {
    return 'Eksport mislyktes: $error';
  }

  @override
  String get meetingExportNothing => 'Det er ingenting å eksportere ennå.';

  @override
  String get meetingPlaybackPlay => 'Spill av';

  @override
  String get meetingPlaybackPause => 'Pause';

  @override
  String get meetingPlaybackUnavailable =>
      'Lydavspilling er utilgjengelig på denne enheten.';

  @override
  String get meetingDetectedTitle => 'Møte oppdaget';

  @override
  String meetingDetectedSubtitle(String label) {
    return 'Ser ut som «$label» pågår. Ta det opp?';
  }

  @override
  String get meetingDetectedSubtitleGeneric =>
      'Ser ut som et møte pågår. Ta det opp?';

  @override
  String get meetingDetectedRecord => 'Ta opp';

  @override
  String get meetingDetectedDismiss => 'Avvis';

  @override
  String get meetingAutoStopTitle =>
      'Dette møtet ser ut til å være over. Stoppe opptaket?';

  @override
  String get meetingAutoStopStop => 'Stopp';

  @override
  String get meetingAutoStopKeep => 'Fortsett opptak';

  @override
  String get meetingAutoDetect => 'Oppdag møter automatisk';

  @override
  String get meetingAutoDetectDescription =>
      'Følg med på kalenderen og konferanseapper og tilby å ta opp når et møte starter.';

  @override
  String get meetingsRecordingCrumb => 'Tar opp…';

  @override
  String get meetingRecordTitleHint => 'Møtetittel';

  @override
  String get meetingRecordTappingLabel => 'Tar opp:';

  @override
  String get meetingRecordMic => 'Mikrofon';

  @override
  String get meetingRecordSystemAudio => 'Systemlyd';

  @override
  String get meetingRecordPause => 'Pause';

  @override
  String get meetingRecordResume => 'Fortsett';

  @override
  String get meetingRecordStop => 'Stopp og oppsummer';

  @override
  String get meetingRecordYourNotes => 'Dine notater';

  @override
  String get meetingRecordNotesPlaceholder =>
      'Skriv mens du lytter. Noen fragmenter er nok — når du stopper, utvider agenten dem med transkriptet.';

  @override
  String get meetingRecordLiveTranscript => 'Live-transkript';

  @override
  String get meetingRecordDecoding => 'dekoder på enheten';

  @override
  String get meetingRecordListening =>
      'Lytter… tale vises her innen et sekund eller to, merket Deg / Andre.';

  @override
  String get meetingRecordPausedHint =>
      'På pause — lyd ignoreres til du fortsetter.';

  @override
  String get meetingRecordNotActive => 'Ingen aktivt opptak.';

  @override
  String get meetingHudRecording => 'tar opp';

  @override
  String get meetingHudPaused => 'på pause';

  @override
  String get meetingHudOpen => 'Åpne';

  @override
  String get meetingHudStop => 'Stopp';

  @override
  String get meetingToolbarPopOut => 'Løsne';

  @override
  String get meetingToolbarHoldToStop => 'Hold for å stoppe opptak';

  @override
  String get meetingToolbarSemanticLabel => 'Verktøylinje for møteopptak';

  @override
  String get orchestrate => 'Orkestrer';

  @override
  String get orchestrationUnavailable => 'Orkestrering utilgjengelig';

  @override
  String get orchestrationApprove => 'Godkjenn plan';

  @override
  String get orchestrationReject => 'Avvis';

  @override
  String get orchestrationCancel => 'Avbryt orkestrering';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count roller — $hires nye ansettelser';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count undersaker';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'Estimert kostnad: \$$amount';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total undersaker ferdig';
  }

  @override
  String get orchestrationStatusProposed => 'Foreslått';

  @override
  String get orchestrationStatusApproved => 'Godkjent';

  @override
  String get orchestrationStatusExecuting => 'Kjører';

  @override
  String get orchestrationStatusSynthesizing => 'Syntetiserer';

  @override
  String get orchestrationStatusCompleted => 'Fullført';

  @override
  String get orchestrationStatusFailed => 'Mislyktes';

  @override
  String get orchestrationStatusCancelled => 'Avbrutt';

  @override
  String get messageFailed => 'Kjøring mislyktes';

  @override
  String get turnLimitReached =>
      'Stoppet ved turgrensen — svar for å fortsette';

  @override
  String get retried => 'Prøvd på nytt';

  @override
  String replyingTo(String name) {
    return 'svarer $name';
  }

  @override
  String get silenceTimeoutLabel => 'Stillhetstidsavbrudd (minutter)';

  @override
  String get silenceTimeoutHint =>
      'f.eks. 15 — avslutt en kjøring etter så lang tid uten utdata';

  @override
  String get capabilityJsonMode => 'JSON-modus';

  @override
  String get capabilityModelSelection => 'Modellvalg';

  @override
  String get transcriptThinking => 'Tenker…';

  @override
  String transcriptThoughtFor(String duration) {
    return 'Tenkte i $duration';
  }

  @override
  String get transcriptStatusMakingEdits => 'Gjør endringer…';

  @override
  String get transcriptStatusReadingFiles => 'Leser filer…';

  @override
  String get transcriptStatusSearching => 'Søker i kodebasen…';

  @override
  String get transcriptStatusRunningCommands => 'Kjører kommandoer…';

  @override
  String get transcriptStatusResponding => 'Svarer…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return 'Kjører $tool…';
  }

  @override
  String get transcriptInput => 'Inndata';

  @override
  String get transcriptOutput => 'Utdata';

  @override
  String get transcriptErrorLabel => 'Feil';

  @override
  String get transcriptSandboxBlocked => 'Sandkassen blokkerte en handling';

  @override
  String transcriptShowFullOutput(int kb) {
    return 'Vis all utdata (+$kb KB)';
  }

  @override
  String transcriptShowAllLines(int count) {
    return 'Vis alle $count linjer';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return 'Viser de første $count linjene';
  }

  @override
  String get transcriptGrepNoMatches => 'Ingen treff';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '$matches treff',
      one: '1 treff',
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
  String get meetingRenameSpeakerTooltip => 'Gi taler nytt navn';

  @override
  String get meetingRenameSpeakerTitle => 'Gi taler nytt navn';

  @override
  String get meetingSpeakerNameLabel => 'Navn';

  @override
  String get meetingSpeakerSuggestFromCalendar => 'Fra dette møtets inviterte';

  @override
  String get meetingRenameSpeakerApplyAll =>
      'Bruk på alle blokker fra denne taleren';

  @override
  String get meetingRenameSpeakerScopeHint =>
      'Når av, omdøpes bare den valgte linjen.';

  @override
  String get meetingLinkEvent => 'Knytt til hendelse';

  @override
  String get meetingChangeEvent => 'Bytt hendelse';

  @override
  String get meetingLinkEventTitle => 'Knytt til en kalenderhendelse';

  @override
  String get meetingLinkEventSearchHint => 'Søk i hendelser';

  @override
  String get meetingLinkEventEmpty => 'Ingen nærliggende kalenderhendelser';

  @override
  String get meetingUnlinkEvent => 'Fjern tilknytning';

  @override
  String get calendarLinkExistingMeeting => 'Knytt til eksisterende møte';

  @override
  String get calendarLinkMeetingTitle => 'Knytt et møte';

  @override
  String get calendarLinkMeetingSearchHint => 'Søk i møter';

  @override
  String get calendarLinkMeetingEmpty => 'Ingen møter å knytte';

  @override
  String get meetingRenameSpeakerFailed => 'Kunne ikke gi taleren nytt navn';

  @override
  String get calendarLinkUpdateFailed => 'Kunne ikke oppdatere kalenderlenken';

  @override
  String get rename => 'Gi nytt navn';

  @override
  String get notNow => 'Ikke nå';

  @override
  String get meetingSaveVoiceProfileTitle => 'Lagre stemmeprofil?';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return 'Gjenkjenn $name automatisk i fremtidige møter ved å lagre stemmeavtrykket.';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return 'Lagret stemmeprofil for $name';
  }

  @override
  String get meetingVoiceProfileSaveFailed => 'Kunne ikke lagre stemmeprofilen';

  @override
  String get voiceProfilesSection => 'Stemmeprofiler';

  @override
  String get voiceProfilesDescription =>
      'Lagrede stemmer gjenkjennes automatisk i fremtidige møter.';

  @override
  String get voiceProfilesEmpty =>
      'Ingen lagrede stemmer ennå. Gi en taler navn i et møtetranskript, og velg «Lagre stemmeprofil».';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prøver',
      one: '1 prøve',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => 'Gi stemmeprofil nytt navn';

  @override
  String get deleteVoiceProfileTitle => 'Slette stemmeprofil?';

  @override
  String deleteVoiceProfileBody(String name) {
    return 'Stoppe gjenkjenning av $name? Det lagrede stemmeavtrykket fjernes. Navn som allerede er brukt i tidligere møter, beholdes.';
  }

  @override
  String get connectedLabel => 'Tilkoblet';

  @override
  String get ideTabGeneral => 'Generelt';

  @override
  String get ideTabExplorer => 'Utforsker';

  @override
  String get ideTabSourceControl => 'Kildekontroll';

  @override
  String get generalSectionTodos => 'Gjøremål';

  @override
  String get generalSectionGoals => 'Mål';

  @override
  String get goalRunStatusActive => 'Aktiv';

  @override
  String get goalRunStatusPaused => 'På pause';

  @override
  String get goalRunStatusCompleted => 'Fullført';

  @override
  String get goalRunStatusFailed => 'Mislyktes';

  @override
  String get goalRunStatusCancelled => 'Avbrutt';

  @override
  String get goalRunStatusBudgetExhausted => 'Budsjett brukt opp';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return 'Kjøring $run av $max · $cost av $cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return 'Kjøring $run · $cost av $cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return 'Frist $deadline';
  }

  @override
  String get goalRunPause => 'Sett mål på pause';

  @override
  String get goalRunResume => 'Fortsett mål';

  @override
  String goalRunResumeRaise(String cap) {
    return 'Fortsett · hev taket til $cap';
  }

  @override
  String get goalRunStop => 'Stopp mål';

  @override
  String get generalSectionAgents => 'Agenter';

  @override
  String get generalSectionTerminals => 'Terminaler';

  @override
  String get generalTodosEmpty => 'Ingen gjøremål ennå';

  @override
  String get generalAgentsEmpty => 'Ingen agenter kjører';

  @override
  String get generalTerminalsEmpty => 'Ingen terminaler åpne';

  @override
  String get generalSectionBrowsers => 'Nettlesere';

  @override
  String get generalSectionComputers => 'Datamaskiner';

  @override
  String get generalBrowsersEmpty => 'Ingen nettlesere åpne';

  @override
  String get generalComputersEmpty => 'Ingen datamaskiner åpne';

  @override
  String get generalSectionPhones => 'Telefoner';

  @override
  String get generalPhonesEmpty => 'Ingen telefoner åpne';

  @override
  String get pauseAgent => 'Sett agent på pause';

  @override
  String get resumeAgent => 'Fortsett agent';

  @override
  String get agentCannotPause =>
      'Denne agenten kan ikke settes på pause — stopp den i stedet.';

  @override
  String get goalClear => 'Fjern mål';

  @override
  String get undoLabelGoalClear => 'fjern mål';

  @override
  String get todoStatusPending => 'Ikke startet';

  @override
  String get todoStatusInProgress => 'Pågår';

  @override
  String get todoStatusCompleted => 'Ferdig';

  @override
  String get reorderTodo => 'Endre rekkefølge på gjøremål';

  @override
  String get focusTerminal => 'Fokuser terminal';

  @override
  String get focusMachine => 'Fokuser maskin';

  @override
  String get focusBrowser => 'Fokuser nettleser';

  @override
  String get todoEditorTitle => 'Rediger gjøremål';

  @override
  String get todoEditorHint =>
      'Ett punkt per linje. Bruk - [ ] for ventende, - [~] for pågår, - [x] for ferdig.';

  @override
  String get todoNeedsText => 'Legg til noe tekst etter kommandoen';

  @override
  String get todoNotFound => 'Ingen matchende gjøremål';

  @override
  String get todoCleared => 'Tømte gjøremålslisten';

  @override
  String get todoNothingToCopy => 'Ingenting å kopiere';

  @override
  String todoAdded(String content) {
    return 'La til «$content»';
  }

  @override
  String todoStarted(String content) {
    return 'Startet «$content»';
  }

  @override
  String todoCompleted(String content) {
    return 'Fullførte «$content»';
  }

  @override
  String todoRemoved(String content) {
    return 'Fjernet «$content»';
  }

  @override
  String todoCopied(int count) {
    return 'Kopierte $count elementer';
  }

  @override
  String todoImported(int count) {
    return 'Importerte $count elementer';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return 'Ukjent gjøremålskommando «$name»';
  }

  @override
  String get terminal => 'Terminal';

  @override
  String get ideCloseTab => 'Lukk fane';

  @override
  String get ideSplitEditor => 'Del redigerer';

  @override
  String get ideSplitRight => 'Del til høyre';

  @override
  String get ideSplitDown => 'Del ned';

  @override
  String get ideSplitLeft => 'Del til venstre';

  @override
  String get ideSplitUp => 'Del opp';

  @override
  String get ideCloseGroup => 'Lukk gruppe';

  @override
  String get ideCloseOthers => 'Lukk andre';

  @override
  String get ideCloseToRight => 'Lukk til høyre';

  @override
  String get ideCloseSaved => 'Lukk lagrede';

  @override
  String get ideCloseAll => 'Lukk alle';

  @override
  String get ideSplit => 'Del';

  @override
  String get ideToggleSidebar => 'Slå sidestolpe av/på';

  @override
  String get ideNewTab => 'Åpne redigerer';

  @override
  String get ideNewTabMenu => 'Ny fane';

  @override
  String get ideReviewCode => 'Gjennomgå kode';

  @override
  String ideReviewCodeInRepo(String repo) {
    return 'Gjennomgå kode ($repo)';
  }

  @override
  String get ideRevertConfirmTitle => 'Tilbakestill endringer';

  @override
  String get ideRevertUntracked => 'Usporede filer kan ikke tilbakestilles';

  @override
  String get ideRevertFailed =>
      'Kunne ikke tilbakestille filene. Samtalens worktree kan være utilgjengelig.';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filer',
      one: '1 fil',
    );
    return '$_temp0 kunne ikke tilbakestilles (usporet).';
  }

  @override
  String get ideSearchMatchCase => 'Skill mellom store og små bokstaver';

  @override
  String get ideSearchWholeWord => 'Hele ord';

  @override
  String get ideSearchRegex => 'Regex';

  @override
  String get ideSearchFilters => 'Søkefiltre';

  @override
  String get ideSearchFilesToInclude => 'Filer som skal tas med';

  @override
  String get ideSearchFilesToExclude => 'Filer som skal utelates';

  @override
  String get ideNoOpenTabs => 'Ingen åpne faner — bruk + for å åpne';

  @override
  String get ideBrowserAddressHint => 'Skriv inn adresse eller søk';

  @override
  String get ideSimpleWebBrowser => 'Enkel nettleser';

  @override
  String get ideWebBrowser => 'Nettleser';

  @override
  String get ideBrowserEnterUrl =>
      'Skriv inn en URL i adressefeltet for å begynne å surfe';

  @override
  String get ideCodeServer => 'Redigerer';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return 'Lagre endringer i $fileName?';
  }

  @override
  String get ideUnsavedChangesBody =>
      'Endringene dine går tapt hvis du ikke lagrer dem.';

  @override
  String get ideDontSave => 'Ikke lagre';

  @override
  String get editorAutoSave => 'Autolagre';

  @override
  String get editorAutoSaveDescription =>
      'Lagre endringer automatisk i den innebygde redigereren.';

  @override
  String get editorAutoSaveOff => 'Av';

  @override
  String get editorAutoSaveAfterDelay => 'Etter en forsinkelse';

  @override
  String get editorAutoSaveOnFocusChange => 'Ved fokusendring';

  @override
  String get ideCodeServerUnavailable =>
      'Code-server er ikke tilgjengelig på denne serveren';

  @override
  String get ideCodeServerUnavailableHint =>
      'Installer code-server (coder/code-server) på serververten, og åpne redigereren på nytt.';

  @override
  String get ideCodeServerInstalling => 'Forbereder redigerer…';

  @override
  String get ideCodeServerOpenInBrowser => 'Åpne redigerer i nettleser';

  @override
  String get ideCodeServerError => 'Kunne ikke åpne redigereren';

  @override
  String get paneSuspendedCaption =>
      'Suspendert for å spare ressurser — lastes inn på nytt når den får fokus';

  @override
  String get ideFolderLoadFailed => 'Kunne ikke laste denne mappen';

  @override
  String get ideFileSearchFailed => 'Kunne ikke søke i filer';

  @override
  String get ideSearchInFiles => 'Søk i filer';

  @override
  String get ideNoContentMatches => 'Ingen treff';

  @override
  String get ideSourceControlCreatePr => 'Opprett pull request';

  @override
  String ideSourceControlViewPr(int number) {
    return 'Vis pull request #$number';
  }

  @override
  String get ideSourceControlNoChanges => 'Ingen endringer';

  @override
  String get noReposInConversation => 'Ingen arkiv i denne samtalen';

  @override
  String get ideSourceControlNoSpace => 'Åpne en samtale for å se endringene';

  @override
  String get ideFileLoading => 'Laster…';

  @override
  String get ideFileBinary => 'Binærfil';

  @override
  String get mcpExternalServers => 'Eksterne MCP-servere';

  @override
  String get mcpExternalServersDescription =>
      'Koble til eksterne MCP-servere (GitHub, Sentry, Postgres, nettleserautomatisering). Servere du har konfigurert for Claude, Cursor, VS Code og andre verktøy oppdages automatisk.';

  @override
  String get mcpApprovalMode => 'Verktøygodkjenning';

  @override
  String get mcpApprovalModeDescription =>
      'Hvilke verktøyhandlinger som kjører uten å spørre. Leser er alltid tillatt; høyere nivåer spør.';

  @override
  String get mcpApprovalAlwaysAsk => 'Spør alltid';

  @override
  String get mcpApprovalWrite => 'Godkjenn skriving automatisk';

  @override
  String get mcpApprovalYolo => 'Godkjenn alt automatisk';

  @override
  String get mcpNoExternalServers => 'Ingen eksterne MCP-servere oppdaget.';

  @override
  String get mcpAuthorize => 'Autoriser';

  @override
  String get mcpReconnect => 'Koble til på nytt';

  @override
  String get mcpExternalConnectionsNote =>
      'Eksterne MCP-servere kjører på agentserveren (delt av skrivebord og web). Å autorisere OAuth-servere er bare tilgjengelig på skrivebordet.';

  @override
  String get mcpStatusConnected => 'Tilkoblet';

  @override
  String get mcpStatusConnecting => 'Kobler til…';

  @override
  String get mcpStatusNeedsAuth => 'Trenger autorisasjon';

  @override
  String get mcpStatusFailed => 'Mislyktes';

  @override
  String get mcpStatusCircuitOpen => 'På pause';

  @override
  String get mcpStatusDisabled => 'Av';

  @override
  String get providersAndModels => 'Leverandører og modeller';

  @override
  String get providersAndModelsDescription =>
      'List alle leverandører den innebygde agenten kan bruke — sett en API-nøkkel eller logg inn med nettleseren, se hver tilkoblede leverandørs modeller og priser, og styr hvilke leverandører dette arbeidsområdet kan bruke.';

  @override
  String get syncNow => 'Synkroniser nå';

  @override
  String syncNowResult(int applied, int failed) {
    return 'Synkronisering ferdig — $applied brukt, $failed mislyktes';
  }

  @override
  String syncNowFailed(String error) {
    return 'Synkronisering mislyktes: $error';
  }

  @override
  String get denied => 'Nektet';

  @override
  String get allowed => 'Tillatt';

  @override
  String allowProviderSemantic(String provider) {
    return 'Tillat $provider';
  }

  @override
  String enabledViaEnv(String key) {
    return 'Slått på via $key';
  }

  @override
  String costPerMillion(String input, String output) {
    return '$input / $output per 1M';
  }

  @override
  String contextTokens(String tokens) {
    return '$tokens kontekst';
  }

  @override
  String get usageAndCost => 'Bruk og kostnad';

  @override
  String get usageAndCostDescription =>
      'Forbruk på tvers av agentene dine de siste 7 dagene, fra observerte kjøringskostnader.';

  @override
  String get noUsageYet => 'Ingen bruk registrert ennå.';

  @override
  String get spentThisWeek => 'brukt denne uken';

  @override
  String get subscriptionUsage => 'Abonnementsbruk';

  @override
  String get subscriptionUsageUnavailable => 'Utilgjengelig';

  @override
  String get subscriptionUsageExhausted => 'Kvote brukt opp';

  @override
  String get subscriptionUsageSignInRequired => 'Logg inn på nytt';

  @override
  String get subscriptionUsageSignInExpired =>
      'Innlogging utløpt, fornyes ved neste kjøring';

  @override
  String get subscriptionUsagePartiallyAvailable => 'Delvis tilgjengelig';

  @override
  String resetsIn(String duration) {
    return 'Tilbakestilles om $duration';
  }

  @override
  String get feedbackHelpful => 'Dette var nyttig';

  @override
  String get feedbackNotHelpful => 'Dette var ikke nyttig';

  @override
  String get modeChat => 'Chat';

  @override
  String get modePlan => 'Plan';

  @override
  String get modeReview => 'Gjennomgang';

  @override
  String get modeOrchestrate => 'Orkestrer';

  @override
  String get editorTheme => 'Redigerertema';

  @override
  String get editorThemeDescription =>
      'Importer et VS Code-fargetema slik at den innebygde diffen og redigereren matcher IDE-en din.';

  @override
  String get editorThemePasteHint =>
      'Lim inn innholdet i en VS Code color-theme JSON-fil';

  @override
  String get editorThemeImported => 'Tema importert';

  @override
  String get editorThemeInvalid => 'Det ser ikke ut som et gyldig VS Code-tema';

  @override
  String get importTheme => 'Importer tema';

  @override
  String get clearTheme => 'Fjern tema';

  @override
  String get openInDiffViewer => 'Åpne i diff-visning';

  @override
  String get shellCommand => 'Kommando';

  @override
  String get shellOutput => 'Utdata';

  @override
  String get revertToHere => 'Tilbakestill hit';

  @override
  String get revertConfirmBody =>
      'Skjule meldingene etter dette punktet og rulle tilbake agentens filendringer til denne turen? Du kan angre dette.';

  @override
  String get revert => 'Tilbakestill';

  @override
  String get revertedToHere => 'Tilbakestilt hit';

  @override
  String get nothingToRevert => 'Ingenting å tilbakestille';

  @override
  String get undoRevert => 'Angre tilbakestilling';

  @override
  String get revertUndone => 'Tilbakestilling angret';

  @override
  String get systemBehavior => 'Systematferd';

  @override
  String get keepAwakeTitle => 'Hold datamaskinen våken mens agenter kjører';

  @override
  String get keepAwakeOnSubtitle =>
      'Datamaskinen sover ikke mens en agent jobber';

  @override
  String get keepAwakeOffSubtitle =>
      'Datamaskinen kan sove selv om en agent jobber';

  @override
  String get syncEngineSectionTitle => 'Synkroniseringsmotor';

  @override
  String get syncEngineDescription =>
      'Saker, meldinger og notater oppdateres live via små inkrementelle endringer i stedet for fulle øyeblikksbilder. Når du slår av en bryter, faller det lageret tilbake til full-øyeblikksbilde-modus — last appen på nytt for at endringen skal tre i kraft.';

  @override
  String get syncEngineTicketsTitle => 'Saker';

  @override
  String get syncEngineMessagingTitle => 'Meldinger';

  @override
  String get syncEngineNotesTitle => 'Notater';

  @override
  String get syncEngineOnSubtitle => 'Live delta-synkronisering er aktiv';

  @override
  String get syncEngineOffSubtitle =>
      'Bruker full-øyeblikksbilde-synkronisering';

  @override
  String get spaces => 'Områder';

  @override
  String get spacesHomeDescription =>
      'Velg et område fra listen, eller start et nytt.';

  @override
  String get noSpacesYet => 'Ingen områder ennå';

  @override
  String get newSpace => 'Nytt område';

  @override
  String get spaceName => 'Områdenavn';

  @override
  String get spaceReposHint => 'Arkiv som skal tas med';

  @override
  String get ideSourceControl => 'Kildekontroll';

  @override
  String get stagedChanges => 'Staged endringer';

  @override
  String get changes => 'Endringer';

  @override
  String get stageFile => 'Stage';

  @override
  String get unstageFile => 'Unstage';

  @override
  String get stageAll => 'Stage alle endringer';

  @override
  String get unstageAll => 'Unstage alle';

  @override
  String get stageChangesToCommit => 'Stage endringer for commit';

  @override
  String get syncToPrHead => 'Hent siste PR-committer';

  @override
  String get syncedToPrHead => 'Synkronisert til de siste PR-committene';

  @override
  String get syncPrHeadDirty =>
      'Commit eller forkast endringene dine før synkronisering';

  @override
  String get syncPrHeadFailed => 'Kunne ikke synkronisere til PR-hodet';

  @override
  String get spaceLabel => 'Område';

  @override
  String get keybindingNewSpace => 'Nytt område';

  @override
  String get keybindingCreateANewSpaceDescription => 'Opprett et nytt område';

  @override
  String get jumpToLatest => 'Hopp til siste';

  @override
  String get streaming => 'Strømmer';

  @override
  String get newMessages => 'Nye';

  @override
  String get copyLink => 'Kopier lenke';

  @override
  String get linkCopied => 'Lenke kopiert';

  @override
  String get agentResponding => 'Agenten svarer';

  @override
  String get agentFinished => 'Agent ferdig';

  @override
  String get harnessConnectProviderForModels =>
      'Koble til en leverandør for å se modeller.';

  @override
  String get providerSignOut => 'Logg ut';

  @override
  String get providerWaitingForDeviceCode =>
      'Venter på at du bekrefter koden i nettleseren…';

  @override
  String get providerDeviceCodeHint =>
      'Sjekk at denne koden matcher den som vises i nettleseren, og godkjenn deretter.';

  @override
  String get providerPlanUsageLoading => 'Sjekker planbruk…';

  @override
  String get providerPlanUsageUnavailable =>
      'Denne planen rapporterte ikke bruk.';

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return 'Fjerne $provider API-nøkkelen?';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return 'Den lagrede nøkkelen slettes og kan ikke vises igjen. Agenter som bruker $provider-modeller slutter å virke til du limer inn en ny.';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return 'Fjerne $provider?';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return '$provider og den lagrede nøkkelen slettes. Agenter festet til modellene dens slutter å virke.';
  }

  @override
  String get providerApiKeyHint => 'Lim inn en API-nøkkel';

  @override
  String get providerApiKeyStoredHint =>
      'Lim inn en annen API-nøkkel for å legge den til';

  @override
  String get providerAddAnotherAccount => 'Legg til en annen konto';

  @override
  String get providerActiveBadge => 'Aktiv';

  @override
  String get providerOauthAccountFallback => 'OAuth-konto';

  @override
  String get providerApiKeyFallback => 'API-nøkkel';

  @override
  String get providerRemoveCredentialConfirmTitle =>
      'Fjerne denne påloggingsinformasjonen?';

  @override
  String get providerSignOutAccountConfirmTitle => 'Logge ut av denne kontoen?';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return 'Agenter som bruker $provider faller tilbake til de andre nøklene og kontoene. Når ingen er igjen, stopper de til du legger til én.';
  }

  @override
  String get providerBaseUrlHint => 'Base-URL (valgfritt)';

  @override
  String get addProvider => 'Legg til leverandør';

  @override
  String get noCustomProviders => 'Ingen egendefinerte leverandører ennå.';

  @override
  String get providerNameLabel => 'Navn';

  @override
  String get apiTypeLabel => 'API-type';

  @override
  String get providerBaseUrlLabel => 'Base-URL';

  @override
  String get providerApiKeyOptionalHint => 'API-nøkkel (valgfritt)';

  @override
  String get dialectOpenAiCompatible => 'OpenAI-kompatibel';

  @override
  String get dialectAnthropicCompatible => 'Anthropic-kompatibel';

  @override
  String get removeProviderTooltip => 'Fjern leverandør';

  @override
  String get providerLogInWithBrowser => 'Logg inn med nettleser';

  @override
  String providerLoginDialogTitle(String provider) {
    return 'Logg inn på $provider';
  }

  @override
  String get providerLabel => 'Leverandør';

  @override
  String get selectProviderToLogin => 'Velg en leverandør å logge inn på';

  @override
  String providerLoginFailed(String error) {
    return 'Innlogging mislyktes: $error';
  }

  @override
  String get providerWaitingForBrowser =>
      'Venter på at du autoriserer i nettleseren…';

  @override
  String get providerPasteCodeHint => 'Eller lim inn koden fra nettleseren';

  @override
  String get providerCompleteLogin => 'Fullfør';

  @override
  String get providerConnectedApiKey => 'Tilkoblet via API-nøkkel';

  @override
  String get providerConnectedOauth => 'Tilkoblet';

  @override
  String providerConnectedAccount(String account) {
    return 'Tilkoblet · $account';
  }

  @override
  String get providerLocalReady => 'Lokal · klar';

  @override
  String get providerNotConnected => 'Ikke tilkoblet';

  @override
  String get preparingWorkspace => 'Forbereder arbeidsområde…';

  @override
  String provisioningRunningSetupScript(String repo) {
    return 'Kjører oppsettskriptet for $repo…';
  }

  @override
  String get repoScriptsTitle => 'Skript';

  @override
  String get repoScriptsTooltip => 'Konfigurer livssyklusskript';

  @override
  String get repoScriptsSetupLabel => 'Oppsettskript';

  @override
  String get repoScriptsSetupHelp =>
      'Kjører i områdets worktree rett etter at det er opprettet — installer avhengigheter, generer filer. En feil merker området som mislykket; nytt forsøk kjører det igjen.';

  @override
  String get repoScriptsArchiveLabel => 'Arkiveringsskript';

  @override
  String get repoScriptsArchiveHelp =>
      'Kjører like før et områdes worktree slettes — rydd opp i ressurser utenfor worktree. En feil blokkerer aldri sletting.';

  @override
  String get repoScriptsEnvHelp =>
      'Kjører via bash fra worktree, med CC_WORKSPACE_PATH (worktree), CC_ROOT_PATH (arkivroten), CC_SPACE_ID, CC_SPACE_NAME og CC_REPO_NAME satt.';

  @override
  String get repoScriptsSetupPlaceholder => 'e.g. pnpm install';

  @override
  String get repoScriptsArchivePlaceholder =>
      'e.g. docker compose -p \$CC_SPACE_ID down';

  @override
  String get repoScriptsRecentRuns => 'Nylige kjøringer';

  @override
  String get repoScriptsNoRuns => 'Ingen kjøringer ennå';

  @override
  String get repoScriptsSaved => 'Skript lagret';

  @override
  String get repoScriptsRunKindSetup => 'Oppsett';

  @override
  String get repoScriptsRunKindArchive => 'Arkiver';

  @override
  String get repoScriptsRunStatusRunning => 'Kjører';

  @override
  String get repoScriptsRunStatusSucceeded => 'Lyktes';

  @override
  String get repoScriptsRunStatusFailed => 'Mislyktes';

  @override
  String get repoScriptsRunStatusTimedOut => 'Tidsavbrudd';

  @override
  String repoScriptsExitCode(int code) {
    return 'Avslutningskode $code';
  }

  @override
  String provisioningCloningRepo(String repo) {
    return 'Kloner $repo…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return 'Sjekker ut pull request i $repo…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return 'Setter opp agent $agent…';
  }

  @override
  String get workspacePrepFailed => 'Oppsett av arbeidsområde mislyktes';

  @override
  String get workspacePrepStopped => 'Oppsett av arbeidsområde stoppet';

  @override
  String get stopWorkspacePrep => 'Stopp forberedelse';

  @override
  String get stopWorkspacePrepTooltip =>
      'Stopp forberedelse av dette arbeidsområdet';

  @override
  String get stopWorkspacePrepConfirm =>
      'Stoppe forberedelsen av dette arbeidsområdet? Klonen som pågår forkastes — du kan starte den igjen herfra.';

  @override
  String messageWillSendWhenReady(int count) {
    return '$count melding(er) sendes når det er klart';
  }

  @override
  String get membersNav => 'Medlemmer';

  @override
  String get membersSettingsDescription =>
      'Personer med tilgang til dette arbeidsområdet: oversikt, invitasjoner og revisjonsspor';

  @override
  String get memberRosterLabel => 'Medlemsoversikt';

  @override
  String get memberRepoAccessAction => 'Arkivtilgang';

  @override
  String memberRepoAccessTitle(String name) {
    return 'Arkivtilgang for $name';
  }

  @override
  String get roleOwner => 'Eier';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleMember => 'Medlem';

  @override
  String get roleViewer => 'Leser';

  @override
  String get roleGuest => 'Gjest';

  @override
  String get removeMemberTitle => 'Fjern medlem';

  @override
  String removeMemberConfirm(String name) {
    return 'Fjerne $name fra dette arbeidsområdet? De mister tilgangen umiddelbart.';
  }

  @override
  String get transferOwnershipAction => 'Overfør eierskap';

  @override
  String get transferOwnershipTitle => 'Overfør eierskap';

  @override
  String transferOwnershipConfirm(String name) {
    return 'Gjøre $name til eier av dette arbeidsområdet? Du blir admin. Bare en eier kan slette arbeidsområdet eller endre en annen admins rolle.';
  }

  @override
  String get transferOwnershipCta => 'Overfør';

  @override
  String get auditTrailLabel => 'Autorisasjonsrevisjonsspor';

  @override
  String get auditTrailDescription =>
      'Hver tillatelse og avvisning, hash-kjedet slik at en endret eller slettet oppføring kan oppdages.';

  @override
  String get auditVerifyChain => 'Verifiser kjede';

  @override
  String auditChainIntact(int count) {
    return 'Kjede intakt — $count oppføringer verifisert';
  }

  @override
  String auditChainBroken(int seq, String reason) {
    return 'Kjede brutt ved oppføring $seq: $reason';
  }

  @override
  String get auditEmpty => 'Ingen beslutninger registrert ennå.';

  @override
  String get auditDenied => 'Nektet';

  @override
  String get auditAllowed => 'Tillatt';

  @override
  String auditOnBehalfOf(String user) {
    return 'for $user';
  }

  @override
  String get policyTemplatesLabel => 'Policymal';

  @override
  String get policyTemplatesDescription =>
      'Bruk en startposisjon, eller flytt én mellom arbeidsområder.';

  @override
  String get policyTemplateStrict => 'Streng';

  @override
  String get policyTemplateBalanced => 'Balansert';

  @override
  String get policyTemplatePermissive => 'Tillatende';

  @override
  String get policyTemplateApply => 'Bruk';

  @override
  String policyTemplateApplied(int count) {
    return 'Brukte $count regler';
  }

  @override
  String get policyExport => 'Kopier policy';

  @override
  String get policyExported => 'Policy kopiert til utklippstavlen';

  @override
  String get policyImport => 'Lim inn policy';

  @override
  String policyImported(int count) {
    return 'Importerte $count regler';
  }

  @override
  String get approveAndRemember => 'Godkjenn i 8 timer';

  @override
  String get approveAndRememberTooltip =>
      'Godkjenner denne handlingen og slutter å spørre om lignende i dette området i 8 timer. Den utløper av seg selv.';

  @override
  String get unknownUserLabel => 'Ukjent bruker';

  @override
  String get inviteMember => 'Inviter medlem';

  @override
  String get inviteRepoAccessHeader => 'Arkivtilgang';

  @override
  String get inviteRepoAccessExplainer =>
      'Bare arkivene du krysser av, deles med den inviterte, på nivået du velger. Alt annet forblir skjult.';

  @override
  String get grantLevelRead => 'Les';

  @override
  String get grantLevelReview => 'Gjennomgang';

  @override
  String get grantLevelWrite => 'Skriv';

  @override
  String get inviteExpiryLabel => 'Utløper om';

  @override
  String get expiryOneDay => '1 dag';

  @override
  String get expirySevenDays => '7 dager';

  @override
  String get expiryThirtyDays => '30 dager';

  @override
  String get createInviteAction => 'Opprett invitasjon';

  @override
  String get inviteOneTimeCodeLabel => 'Engangskode';

  @override
  String get inviteCodeShownOnce =>
      'Denne koden vises bare én gang — kopier den nå.';

  @override
  String get inviteLinkLabel => 'Invitasjonslenke';

  @override
  String get inviteRedeemHint =>
      'Del koden med den inviterte; de løser den inn mot server-URL-en din.';

  @override
  String get inviteScanQr => 'Eller skann for å løse inn';

  @override
  String get inviteLoopbackWarningTitle =>
      'Invitasjonen peker på en lokal adresse';

  @override
  String get inviteLoopbackWarningBody =>
      'Samarbeidspartnere på andre maskiner kan ikke nå denne serveren. Start en tunnel (Innstillinger → Integrasjoner → Del denne serveren) eller bind til nettverket slik at brukere utenfor verten kan koble til.';

  @override
  String get inviteStatusOpen => 'Åpen';

  @override
  String get inviteStatusUsed => 'Brukt';

  @override
  String get inviteStatusRevoked => 'Tilbakekalt';

  @override
  String get inviteStatusExpired => 'Utløpt';

  @override
  String inviteCreatedTime(String time) {
    return 'Opprettet $time';
  }

  @override
  String inviteExpiresOn(String date) {
    return 'utløper $date';
  }

  @override
  String get noActivityYet => 'Ingen aktivitet ennå';

  @override
  String get couldNotLoadMembers => 'Kunne ikke laste medlemmer';

  @override
  String get couldNotLoadInvites => 'Kunne ikke laste invitasjoner';

  @override
  String get couldNotLoadActivity => 'Kunne ikke laste aktivitet';

  @override
  String get yourDevices => 'Dine enheter';

  @override
  String get yourDevicesDescription =>
      'Klienter paret til kontoen din på denne serveren.';

  @override
  String get noOwnDevices => 'Ingen enheter er paret til kontoen din ennå';

  @override
  String get renameDeviceTitle => 'Gi enhet nytt navn';

  @override
  String get revokeDeviceTitle => 'Tilbakekall enhet';

  @override
  String revokeDeviceConfirm(String label) {
    return 'Tilbakekalle $label? Den kobles fra umiddelbart og kan ikke lenger nå denne serveren.';
  }

  @override
  String devicePairedTime(String time) {
    return 'Paret $time';
  }

  @override
  String deviceLastSeenTime(String time) {
    return 'Sist sett $time';
  }

  @override
  String get deviceNeverSeen => 'Aldri tilkoblet';

  @override
  String get profileSectionLabel => 'Profil';

  @override
  String get profileSectionDescription =>
      'Hvordan du vises for teamet og i git-commit-forfatterskap i dette arbeidsområdet. Tomme felt arver kontonavn og e-post.';

  @override
  String get displayNameLabel => 'Visningsnavn';

  @override
  String get emailLabel => 'E-post';

  @override
  String get gitAuthorNameLabel => 'Git-forfatternavn';

  @override
  String get gitAuthorEmailLabel => 'Git-forfatter-e-post';

  @override
  String get profileSaved => 'Profil lagret';

  @override
  String get presenceOnline => 'Pålogget';

  @override
  String get presenceIdle => 'Inaktiv';

  @override
  String get presenceTyping => 'Skriver…';

  @override
  String get presenceAgentThinking => 'Tenker';

  @override
  String get presenceAgentRunning => 'Kjører';

  @override
  String get presenceAgentBlocked => 'Blokkert';

  @override
  String get presenceAgentDone => 'Ferdig';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String presenceNameStatusCost(String name, String status, String cost) {
    return '$name — $status ($cost)';
  }

  @override
  String get presenceRailLabel => 'Hvem er pålogget';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => 'Slå på ikke forstyrr';

  @override
  String get dndTooltipOff => 'Slå av ikke forstyrr';

  @override
  String get startPresenting => 'Start presentasjon';

  @override
  String get stopPresenting => 'Stopp presentasjon';

  @override
  String spotlightPresentingBanner(String name) {
    return '$name presenterer';
  }

  @override
  String get spotlightLeave => 'Forlat';

  @override
  String typingIndicator(String name) {
    return '$name skriver…';
  }

  @override
  String get ideTabNotes => 'Notater';

  @override
  String get ideSidebarAllViews => 'Alle visninger';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return 'Alle visninger ($count skjult)';
  }

  @override
  String get ideSidebarPinView => 'Fest til sidestolpe';

  @override
  String get ideSidebarUnpinView => 'Løsne fra sidestolpe';

  @override
  String get notesEmptyHint =>
      'Legg til et notat for den som tar over denne samtalen…';

  @override
  String get notesEditTooltip => 'Rediger notat';

  @override
  String notesUpdatedBy(String name, String time) {
    return 'Oppdatert av $name · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '$name redigerer';
  }

  @override
  String get notesSaveFailed => 'Kunne ikke lagre notatet';

  @override
  String get reactionAddTooltip => 'Legg til reaksjon';

  @override
  String reactionToggleTooltip(String emoji) {
    return 'Reager med $emoji';
  }

  @override
  String get autonomyDialLabel => 'Autonomi';

  @override
  String get autonomyProposeOnly => 'Bare foreslå';

  @override
  String get autonomyActWithApproval => 'Handle med godkjenning';

  @override
  String get autonomyActFreely => 'Handle fritt';

  @override
  String get autonomyDefaultOption => 'Standard';

  @override
  String get checkerLabel => 'Kontrollør';

  @override
  String get checkerNone => 'Ingen';

  @override
  String get checkerCaption =>
      'Kontrolløren gjennomgår andre agenters fullførte kjøringer.';

  @override
  String get takeoverTooltip => 'Ta over worktree';

  @override
  String get takeoverBannerSelf => 'Du har tatt over denne samtalens worktree';

  @override
  String takeoverBannerOther(String name) {
    return '$name har tatt over denne samtalens worktree';
  }

  @override
  String get handBackButton => 'Gi tilbake';

  @override
  String get handBackDialogTitle => 'Gi worktree tilbake';

  @override
  String get handBackDialogNoteHint => 'Valgfritt notat til agenten…';

  @override
  String takeoverFailed(String message) {
    return 'Kunne ikke ta over: $message';
  }

  @override
  String handBackFailed(String message) {
    return 'Kunne ikke gi tilbake: $message';
  }

  @override
  String get planStudioTitle => 'Plan Studio';

  @override
  String get plansTitle => 'Planer';

  @override
  String get plansSubtitle => 'Aktive planer, plandokumenter og playbooks';

  @override
  String get plansActiveSection => 'Aktive planer';

  @override
  String get plansDocumentsSection => 'Plandokumenter';

  @override
  String get plansPlaybooksSection => 'Playbooks';

  @override
  String get plansNoActive => 'Ingen aktive planer ennå.';

  @override
  String get plansNoDocuments => 'Ingen plandokumenter ennå.';

  @override
  String get plansNoPlaybooks => 'Ingen playbooks ennå.';

  @override
  String get planNotFound => 'Plan ikke funnet.';

  @override
  String get planOpenInStudio => 'Åpne';

  @override
  String get planNodeTitle => 'Tittel';

  @override
  String get planNodeDescription => 'Beskrivelse';

  @override
  String get planNodeDescriptionHint => 'Hva dette steget skal gjøre…';

  @override
  String get planNodeApplyDescription => 'Bruk';

  @override
  String get planNodeRole => 'Rolle';

  @override
  String get planNodeDependencies => 'Avhenger av';

  @override
  String get planNodeDependenciesHint => 'Legg til en avhengighet';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avhengigheter',
      one: '1 avhengighet',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies =>
      'Ingen avhengigheter, så dette kjører så snart planen starter';

  @override
  String get planNodeOutputSchema => 'Utdataskjema (JSON)';

  @override
  String get planNodeEstimate => 'Estimat';

  @override
  String get planNodeProvenance => 'Opphav';

  @override
  String get planNodeAlreadyExecuted =>
      'Allerede utført — redigering forgrener planen herfra.';

  @override
  String get planNewNodeTitle => 'Nytt steg';

  @override
  String get planEstimateNoHistory => 'Ingen historikk ennå';

  @override
  String get planEstimateBlastUnknown => 'Sprengningsradius: ukjent';

  @override
  String get planEstimatePartial => 'delvis';

  @override
  String get planEstimateAction => 'Estimer';

  @override
  String planEstimateDuration(String range) {
    return 'Varighet $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return 'Sprengningsradius: $files filer, $symbols symboler';
  }

  @override
  String get planApprove => 'Godkjenn plan';

  @override
  String get planApproveSelectedNodes => 'Godkjenn valgte';

  @override
  String get planReject => 'Avvis';

  @override
  String get planCancel => 'Avbryt kjøring';

  @override
  String get planContinueNode => 'Fortsett node';

  @override
  String get planTotalNotEstimated => 'Ikke estimert ennå';

  @override
  String get planBudgetExceeded => 'over budsjett';

  @override
  String planBudgetCeiling(String amount) {
    return 'budsjett ≤ \$$amount';
  }

  @override
  String get planVersionsTitle => 'Versjoner';

  @override
  String get planNoRevisions => 'Ingen revisjoner ennå.';

  @override
  String get planDiffIdentical => 'Ingen endringer.';

  @override
  String get planDiffGoalChanged => 'Mål endret';

  @override
  String get planDiffBudgetChanged => 'Budsjett endret';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'Endringer fra v$fromRev til v$toRev';
  }

  @override
  String planDiffAdded(String node) {
    return 'La til $node';
  }

  @override
  String planDiffRemoved(String node) {
    return 'Fjernet $node';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return 'Endret $node: $fields';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return 'Kant lagt til: $edge';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return 'Kant fjernet: $edge';
  }

  @override
  String planDiffRoleAdded(String role) {
    return 'Rolle lagt til: $role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return 'Rolle fjernet: $role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return 'Rolle tildelt på nytt: $role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return 'Plan omplanlagt: du godkjente v$approved, den er nå v$current. Gå gjennom diffen før den fortsetter.';
  }

  @override
  String planLiveActualCost(String amount) {
    return 'Faktisk kostnad: \$$amount';
  }

  @override
  String get planPlaybookRun => 'Kjør';

  @override
  String get planPlaybookDelete => 'Slett playbook';

  @override
  String get planPlaybookProposed =>
      'Plan foreslått — godkjenn den i Plan Studio.';

  @override
  String get planPlaybookAnchorTicket => 'Ankersak';

  @override
  String get planPlaybookPickTicket => 'Velg en sak…';

  @override
  String get planPlaybookProposeRun => 'Foreslå plan';

  @override
  String get planPlaybookRepoHint => 'En arkiv-id';

  @override
  String get planPlaybookAgentHint => 'En agent-id';

  @override
  String planPlaybookRunTitle(String name) {
    return 'Kjør $name';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '$count parametere';
  }

  @override
  String get recentLabel => 'Nylig';

  @override
  String get cheatSheetTitle => 'Tastatursnarveier';

  @override
  String get cheatSheetGlobal => 'Globalt';

  @override
  String get cheatSheetThisScreen => 'Denne skjermen';

  @override
  String get cheatSheetReservedInBrowser => 'Reservert i nettleser';

  @override
  String get keybindingCheatSheet => 'Tastatursnarveier';

  @override
  String get keybindingShowKeyboardShortcutsDescription =>
      'Vis tastatursnarveioversikten for gjeldende skjerm';

  @override
  String get runPlaybookLabel => 'Kjør playbook';

  @override
  String get playbooksLabel => 'Playbooks';

  @override
  String get keybindingUndo => 'Angre';

  @override
  String get keybindingRedo => 'Gjør om';

  @override
  String get keybindingUndoLastActionDescription =>
      'Angre den siste reversible handlingen din';

  @override
  String get keybindingRedoLastActionDescription =>
      'Gjør om den sist angrede handlingen';

  @override
  String get undone => 'Angret';

  @override
  String get redone => 'Gjort om';

  @override
  String get undoFailed => 'Kunne ikke angre';

  @override
  String get undoLabelTicketEdit => 'saksredigering';

  @override
  String get undoLabelMessageEdit => 'meldingsredigering';

  @override
  String get undoLabelTodoStatus => 'gjøremålsstatus';

  @override
  String get inboxTitle => 'Innboks';

  @override
  String get inboxReview => 'Gjennomgang';

  @override
  String get inboxOpen => 'Åpne';

  @override
  String get inboxAllCaughtUp => 'Du er à jour';

  @override
  String get inboxGitHubDownTitle => 'GitHub kan være nede';

  @override
  String inboxGitHubDownBody(String status) {
    return 'GitHub rapporterer $status, så pull requests kan mangle fra denne listen i stedet for å faktisk være ferdig.';
  }

  @override
  String get inboxGitHubIdentityTitle =>
      'Kunne ikke bekrefte GitHub-kontoen din';

  @override
  String get inboxGitHubIdentityBody =>
      'Innboksen sorteres etter hvem du er på GitHub. Til det lastes, forblir den tom, selv når pull requests venter på deg.';

  @override
  String get inboxSeverityBlocking => 'Blokkert';

  @override
  String get inboxSeverityWaiting => 'Venter';

  @override
  String get inboxSeverityInfo => 'Info';

  @override
  String get inboxSyncFailed => 'Synkronisering mislyktes';

  @override
  String get inboxNeedsYourAttention => 'Trenger oppmerksomheten din';

  @override
  String get inboxSectionNeedsYourReview => 'Trenger gjennomgangen din';

  @override
  String get inboxSectionReturnedToYou => 'Returnert til deg';

  @override
  String get inboxSectionApproved => 'Godkjent';

  @override
  String get inboxSectionDrafts => 'Utkast';

  @override
  String get inboxSectionWaitingForReviewers => 'Venter på reviewere';

  @override
  String get inboxSectionMergingAndMerged =>
      'Sammenslåing og nylig slått sammen';

  @override
  String get inboxSectionWaitingForAuthor => 'Venter på forfatter';

  @override
  String get inboxColumnTitle => 'Tittel';

  @override
  String get inboxColumnChanges => 'Endringer';

  @override
  String get inboxColumnUpdated => 'Oppdatert';

  @override
  String get inboxReviewApproved => 'Godkjent';

  @override
  String get inboxReviewChangesRequested => 'Endringer forespurt';

  @override
  String get inboxHeroSubtitle =>
      'Hver pull request du er involvert i, sortert etter hva som skjer videre.';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requests trenger gjennomgangen din',
      one: '1 pull request trenger gjennomgangen din',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count returnert til deg',
      one: '1 returnert til deg',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted =>
      'Den endringen ble ikke lagret og ble tilbakestilt';

  @override
  String get offlinePendingLabel => 'ventende';

  @override
  String get offlineSyncingLabel => 'synkroniserer';

  @override
  String get copyLinkLabel => 'Kopier lenke til denne siden';

  @override
  String get agentsSectionLabel => 'Agenter';

  @override
  String get fleetWorkersTitle => 'Workere';

  @override
  String get fleetWorkersSubtitle =>
      'Maskiner tilgjengelige for å kjøre jobber';

  @override
  String get fleetJobsTitle => 'Jobber';

  @override
  String get fleetJobsSubtitle => 'Arbeid fordelt på tvers av flåten';

  @override
  String get fleetNoWorkers =>
      'Ingen workere ennå — en annen maskin som kjører `cc_worker --server <url>` slutter seg til flåten.';

  @override
  String get fleetNoJobs => 'Ingen jobber.';

  @override
  String get fleetError => 'Kunne ikke laste flåten';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kjerner',
      one: '1 kjerne',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return 'Heartbeat $time';
  }

  @override
  String get fleetNoHeartbeat => 'Ingen heartbeat ennå';

  @override
  String fleetLastErrorLabel(String error) {
    return 'Siste feil: $error';
  }

  @override
  String get fleetDrain => 'Tøm';

  @override
  String get fleetResume => 'Fortsett';

  @override
  String get fleetRevoke => 'Tilbakekall';

  @override
  String get fleetRemove => 'Fjern';

  @override
  String get fleetRevokeTitle => 'Tilbakekalle worker?';

  @override
  String fleetRevokeBody(String name) {
    return 'Tilbakekalle $name? Økten avsluttes, og aktive jobber tildeles på nytt.';
  }

  @override
  String get fleetRemoveTitle => 'Fjerne worker?';

  @override
  String fleetRemoveBody(String name) {
    return 'Fjerne $name fra flåten? Dette sletter oppføringen.';
  }

  @override
  String get fleetActionFailed => 'Handling mislyktes';

  @override
  String get fleetJobUnassigned => 'Ikke tildelt';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '$attempts/$max forsøk';
  }

  @override
  String get fleetPlacementReasons => 'Plasseringsbeslutninger';

  @override
  String get fleetNoPlacements => 'Ingen plasseringsbeslutninger ennå.';

  @override
  String get fleetStatusOnline => 'Pålogget';

  @override
  String get fleetStatusDraining => 'Tømmes';

  @override
  String get fleetStatusOffline => 'Frakoblet';

  @override
  String get fleetStatusIncompatible => 'Inkompatibel';

  @override
  String get fleetStatusRevoked => 'Tilbakekalt';

  @override
  String get fleetJobStatusQueued => 'I kø';

  @override
  String get fleetJobStatusRunning => 'Kjører';

  @override
  String get fleetJobStatusSucceeded => 'Lyktes';

  @override
  String get fleetJobStatusFailed => 'Mislyktes';

  @override
  String get fleetJobStatusCancelled => 'Avbrutt';

  @override
  String get evalsNoSuites => 'Ingen eval-suiter ennå.';

  @override
  String get evalsError => 'Kunne ikke laste evals';

  @override
  String get evalsStarterBadge => 'Start';

  @override
  String evalsDefaultBatch(int count) {
    return 'Standardbatch på $count';
  }

  @override
  String get evalsRecentRuns => 'Nylige kjøringer';

  @override
  String get evalsNoRuns => 'Ingen kjøringer ennå.';

  @override
  String get evalsPassRate => 'Bestått-rate';

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
    return 'Eval ferdig — $rate bestått';
  }

  @override
  String get evalsRunFailed => 'Kunne ikke kjøre suiten';

  @override
  String get evalsRun => 'Kjør';

  @override
  String get evalsStatusQueued => 'I kø';

  @override
  String get evalsStatusRunning => 'Kjører';

  @override
  String get evalsStatusPassed => 'Bestått';

  @override
  String get evalsStatusFailed => 'Mislyktes';

  @override
  String get bannerMeetingJoin => 'Bli med';

  @override
  String get bannerMeetingRecordAndLink => 'Ta opp og knytt';

  @override
  String get bannerCalendarReconnect => 'Koble til på nytt';

  @override
  String get bannerView => 'Vis';

  @override
  String get soundscapeTitle => 'Lydlandskap';

  @override
  String get soundscapePlay => 'Spill av';

  @override
  String get soundscapePause => 'Pause';

  @override
  String get soundscapeMoodLabel => 'Stemning';

  @override
  String get soundscapeMoodFocus => 'Fokus';

  @override
  String get soundscapeMoodRelax => 'Avslapp';

  @override
  String get soundscapeMoodSleep => 'Søvn';

  @override
  String get soundscapeMoodRise => 'Stigning';

  @override
  String get soundscapeVolumeLabel => 'Volum';

  @override
  String get soundscapeTuneLabel => 'Tone';

  @override
  String get soundscapeTuneMellow => 'Myk';

  @override
  String get soundscapeTuneBright => 'Lys';

  @override
  String get soundscapeTuneEnergetic => 'Energisk';

  @override
  String get soundscapeTuneSpacy => 'Romlig';

  @override
  String get soundscapeTuneResetHint => 'Dobbelttrykk for å tilbakestille';

  @override
  String get soundscapeSceneLabel => 'Spilles nå';

  @override
  String get soundscapeSceneLoading => 'Stiller inn atmosfæren…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees°C';
  }

  @override
  String get soundscapeLocationLabel => 'Sted';

  @override
  String get soundscapeLocationDetecting => 'Oppdager sted…';

  @override
  String get soundscapeLocationAutoNote => 'Stedet kommer fra denne enheten.';

  @override
  String get soundscapeRefreshWeather => 'Oppdater været';

  @override
  String get soundscapeAutoStartLabel => 'Start med fokusmodus';

  @override
  String get soundscapeAutoStartDescription =>
      'Spill et lydlandskap automatisk når du starter en fokusøkt.';

  @override
  String get soundscapeReturnToApp => 'Tilbake til appen';

  @override
  String get soundscapePopOut => 'Løsne avspiller';

  @override
  String get discussion => 'Diskusjon';

  @override
  String get chat => 'Chat';

  @override
  String get saving => 'Lagrer…';

  @override
  String get saved => 'Lagret';

  @override
  String get saveFailed => 'Kunne ikke lagre';

  @override
  String get commitAndPush => 'Commit og push';

  @override
  String get commit => 'Commit';

  @override
  String get commitAmend => 'Commit (amend)';

  @override
  String get commitAndSync => 'Commit og synkroniser';

  @override
  String get scmSyncChanges => 'Synkroniser endringer';

  @override
  String get scmPublishBranch => 'Publiser gren';

  @override
  String get scmSyncFailed => 'Synkronisering mislyktes';

  @override
  String get scmSyncDirty =>
      'Commit eller forkast endringer før du synkroniserer';

  @override
  String get scmSynced => 'Synkronisert';

  @override
  String get scmSelectBranch => 'Velg en gren å sjekke ut';

  @override
  String get scmCreateBranch => 'Opprett ny gren…';

  @override
  String get scmCreateBranchFrom => 'Opprett ny gren fra…';

  @override
  String get scmCheckoutDetached => 'Sjekk ut frakoblet…';

  @override
  String get scmBranchName => 'Grennavn';

  @override
  String get scmCreateBranchTitle => 'Opprett gren';

  @override
  String scmFromRef(String ref) {
    return 'Fra ⁨$ref⁩';
  }

  @override
  String get scmCheckoutFailed => 'Kunne ikke bytte gren';

  @override
  String get scmCheckoutDirty =>
      'Sjekk inn eller forkast endringer før du bytter gren';

  @override
  String scmSwitchedToBranch(String branch) {
    return 'Byttet til ⁨$branch⁩';
  }

  @override
  String scmDetachedAt(String ref) {
    return 'Frakoblet ved ⁨$ref⁩';
  }

  @override
  String get scmDetachedHead => 'Frakoblet HEAD';

  @override
  String get scmNoBranches => 'Ingen samsvarende grener';

  @override
  String get scmBranches => 'Grener';

  @override
  String get scmRemoteBranches => 'Eksterne grener';

  @override
  String get scmTags => 'Tagger';

  @override
  String get scmPickStartPoint => 'Velg et startpunkt';

  @override
  String get scmSwitchBranch => 'Bytt gren';

  @override
  String commitMessageOnBranch(String shortcut, String branch) {
    return 'Melding ($shortcut for å committe på «$branch»)';
  }

  @override
  String get committed => 'Committet';

  @override
  String get commitAmended => 'Commit amendet';

  @override
  String get commitFailed => 'Commit mislyktes';

  @override
  String get moreCommitActions => 'Flere commit-handlinger';

  @override
  String get sourceControl => 'Kildekontroll';

  @override
  String fixFindingTitle(String location) {
    return 'Fiks: $location';
  }

  @override
  String get openInEditor => 'Åpne i redigerer';

  @override
  String get regexTesterTitle => 'Test regulært uttrykk';

  @override
  String get regexTesterHint => 'Skriv et eksempel';

  @override
  String get regexMatch => 'Treff';

  @override
  String get regexNoMatch => 'Ingen treff';

  @override
  String get regexInvalidPattern => 'Ugyldig mønster';

  @override
  String get symbolLookupNone =>
      'Ingen definisjon i indeksen eller denne pull-forespørselen';

  @override
  String get symbolLookupInDiff => 'Funnet i denne pull-forespørselen';

  @override
  String get symbolLookupFromBase =>
      'Fra grunnsjekkouten — worktreet til denne PR-en er ikke indeksert ennå';

  @override
  String get symbolImplementations => 'Implementasjoner';

  @override
  String symbolCallersCount(int count) {
    return '$count kallere';
  }

  @override
  String get commitMessageHint => 'Commit-melding';

  @override
  String get pushedToPr => 'Pushet til PR-en';

  @override
  String get pushFailed => 'Push mislyktes';

  @override
  String get reviewFindings => 'Funnet';

  @override
  String get treeLabel => 'Tre';

  @override
  String get toggleFileTree => 'Vis eller skjul filtreet';

  @override
  String get diffViewSettings => 'Innstillinger for diff-visning';

  @override
  String get splitViewLabel => 'Delt';

  @override
  String get unifiedViewLabel => 'Samlet';

  @override
  String get wrapLines => 'Bryt linjer';

  @override
  String get shiftClickSelectRange => 'Shift-klikk for å velge et område';

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
    return 'Liten PR — $files, ~$minutes min å gjennomgå';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return 'Middels PR — $files, sett av ~$minutes min til gjennomgang';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return 'Stor PR — $files, vurder å dele før gjennomgang';
  }

  @override
  String get searchInFiles => 'Søk i filer';

  @override
  String get showFileList => 'Vis filliste';

  @override
  String get searchInFilesHintField => 'Søk i filer…';

  @override
  String get searchInFilesHint => 'Søk på tvers av pull requestens filer';

  @override
  String get searchInWholeRepo => 'Søk i hele depotet';

  @override
  String get searchInThisPullRequest => 'Søk i denne pull requesten';

  @override
  String get searchNoResults => 'Ingen resultater funnet';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultater',
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
  String get discardChangesTitle => 'Forkaste endringer?';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filer',
      one: '1 fil',
    );
    return 'Forkaste $_temp0 til HEAD? Dette kan ikke angres.';
  }

  @override
  String get discardAll => 'Forkast alle';

  @override
  String get discardFailed => 'Kunne ikke forkaste endringer';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filer',
      one: '1 fil',
    );
    return 'Forkastet $_temp0';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '$reverted filer',
      one: '1 fil',
    );
    return 'Forkastet $_temp0; $skipped hoppet over (usporet)';
  }

  @override
  String get prWorktreeUnavailable => 'Arbeidsområde ikke klart';

  @override
  String get prWorktreeUnavailableHint =>
      'Forberedelse av pull requestens filer mislyktes. Åpne pull requesten på nytt for å prøve igjen.';

  @override
  String get timestampRelativeLabel => 'Relativ';

  @override
  String get timestampRawLabel => 'Tidsstempel';

  @override
  String get copyTimestamp => 'Kopier tidsstempel';

  @override
  String get copiedTimestamp => 'Kopierte tidsstempel';

  @override
  String get previewDeployment => 'Forhåndsvisning av utplassering';

  @override
  String previewDeploymentTab(String site) {
    return 'Forhåndsvisning: $site';
  }

  @override
  String get askForReview => 'Be om gjennomgang…';

  @override
  String get closePrsConfirmTitle => 'Lukke pull requests?';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lukke $count pull requests?',
      one: 'Lukke 1 pull request?',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lukket $count pull requests',
      one: 'Lukket 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tildelte $count pull requests',
      one: 'Tildelte 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ba om gjennomgang på $count pull requests',
      one: 'Ba om gjennomgang på 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count handlinger mislyktes',
      one: '1 handling mislyktes',
    );
    return '$_temp0';
  }

  @override
  String get diagram => 'Diagram';

  @override
  String get diagramViewSource => 'Vis kilde';

  @override
  String get diagramHideSource => 'Skjul kilde';

  @override
  String diagramPreviewUnavailable(String reason) {
    return 'Diagramforhåndsvisning utilgjengelig ($reason)';
  }

  @override
  String get planUnavailable => 'Plan utilgjengelig';

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
  String get planApproveAndRun => 'Godkjenn og kjør';

  @override
  String get planStatusDraft => 'Utkast';

  @override
  String get planStatusProposed => 'Plan';

  @override
  String get planStatusApproved => 'Plan godkjent';

  @override
  String get planStatusRejected => 'Plan avvist';

  @override
  String get planStatusSuperseded => 'Plan erstattet';

  @override
  String planRevisionLabel(int revision) {
    return 'Revisjon $revision';
  }

  @override
  String get adapterEnforcementTitle => 'Hva denne adapteren håndhever';

  @override
  String get enforcementFiltersToolSurface =>
      'Control Center velger verktøyene';

  @override
  String get enforcementInterceptsToolCalls =>
      'Hvert kall portes før det kjører';

  @override
  String get enforcementObservesCompletionContract =>
      'Kjøringen holdes til leveransen sin';

  @override
  String get enforcementNativeToolsInterceptable =>
      'Kjørerens egne verktøy er synlige';

  @override
  String get enforcementInProcessToolsSandboxed =>
      'In-process-verktøy er sandkasset';

  @override
  String get enforcementYes => 'Ja';

  @override
  String get enforcementNo => 'Nei';

  @override
  String get adapterEnforcementCaveats => 'Forbehold';

  @override
  String get enforcementSummaryModesEnforced => 'Moduser håndhevet';

  @override
  String get enforcementSummaryModesNotEnforced => 'Moduser ikke håndhevet';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count forbehold',
      one: '1 forbehold',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      'Skrivebeskyttede moduser er ikke strukturelle: Control Center kan ikke fjerne denne kjørerens egne verktøy.';

  @override
  String get caveatToolCallsNotIntercepted =>
      'Ingen forhåndskjøringssperre: bare MCP-verktøykall går gjennom Control Center.';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      'Kjørerens egne fil- og skallverktøy når aldri Control Center; OS-sandkassen er det eneste gulvet under dem.';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      'In-process-filverktøy kjører utenfor sandkassen, så verktøyflaten er den eneste filsystemgrensen.';

  @override
  String get caveatCompletionContractUnobservable =>
      'Control Center kan ikke dytte eller feile en kjøring som avsluttes uten å produsere leveransen.';

  @override
  String get modeDegraded => 'Redusert';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return '$mode-modus på $adapter baserer seg bare på sandkassen; agentens egne filverktøy fanges ikke opp.';
  }

  @override
  String get artifactUnavailable => 'Artefakt utilgjengelig';

  @override
  String artifactRevisionLabel(int count) {
    return '$count revisjoner';
  }

  @override
  String get artifactShowMore => 'Vis mer';

  @override
  String get artifactShowLess => 'Vis mindre';

  @override
  String get artifactCopy => 'Kopier';

  @override
  String get artifactCopied => 'Artefakt kopiert';

  @override
  String get artifactsTabLabel => 'Artefakter';

  @override
  String get artifactsEmptyTitle => 'Ingen artefakter ennå';

  @override
  String get artifactsEmptyBody =>
      'Når en agent publiserer en tabell, et diagram eller en graf her, vises den i denne listen.';

  @override
  String get artifactRevisionPickerLabel => 'Revisjon';

  @override
  String get artifactRestoreRevision => 'Gjenopprett denne revisjonen';

  @override
  String get artifactOpenInTab => 'Åpne i fane';

  @override
  String get artifactTitleFallback => 'Artefakt';

  @override
  String get providerGenerationLabel => 'Genereringsstandarder';

  @override
  String get providerGenerationHint =>
      'La et felt stå tomt for å bruke endepunktets egen standard. Modeller publiserer egne utdatatak og samplingoppskrifter; å servere én med andre verdier kan forringe den.';

  @override
  String get providerMaxTokensLabel => 'Maks utdata-tokens';

  @override
  String get addModel => 'Legg til modell';

  @override
  String get modelListTitle => 'Modelliste';

  @override
  String get railProvidersGroup => 'Leverandører';

  @override
  String get railCustomProvidersGroup => 'Egendefinerte leverandører';

  @override
  String get editModelSettings => 'Rediger modellinnstillinger';

  @override
  String get modelIdLabel => 'Modell-ID';

  @override
  String get modelIdImmutableHint =>
      'ID-en endepunktet serverer; fast når den er listet.';

  @override
  String get contextWindowLabel => 'Kontekstvindu';

  @override
  String get inputTypesLabel => 'Inndatatyper';

  @override
  String get outputTypesLabel => 'Utdatatyper';

  @override
  String get modalityText => 'Tekst';

  @override
  String get modalityImage => 'Bilde';

  @override
  String get modalityAudio => 'Lyd';

  @override
  String get modalityVideo => 'Video';

  @override
  String get modalityPdf => 'PDF';

  @override
  String get modelOverrideReset => 'Tilbakestill til automatisk';

  @override
  String get modelOverrideEdited => 'Redigert';

  @override
  String get manualModelBadge => 'Lagt til manuelt';

  @override
  String get modelIdRequired => 'Skriv inn en modell-id.';

  @override
  String get modelTokensInvalid => 'Skriv inn et positivt heltall av tokens.';

  @override
  String get removeModelAction => 'Fjern modell';

  @override
  String removeModelConfirmTitle(String model) {
    return 'Fjerne $model?';
  }

  @override
  String get removeModelConfirmBody =>
      'Modellen forlater listen, og agenter festet til den slutter å virke. Leverandøren påvirkes ikke.';

  @override
  String get addModelProviderTitle => 'Legg til modellleverandør';

  @override
  String get addModelProviderDescription =>
      'Konfigurer et egendefinert API-endepunkt og modellene dets.';

  @override
  String get modelListEmptyHint =>
      'Ingen modeller konfigurert. Legg til en modell for å bruke den i chat.';

  @override
  String get addProviderModelsHint =>
      'Modeller hentes live når endepunktet svarer. Legg til én manuelt bare hvis den ikke kan liste sine egne.';

  @override
  String get providerTemperatureLabel => 'Temperatur';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved => 'Genereringsstandarder lagret';

  @override
  String get providerGenerationInvalid =>
      'Sjekk verdiene: maks utdata-tokens og top-k må være positive, temperatur 0–2, top-p 0–1.';

  @override
  String get providerGenerationOverridden => 'Overstyrt';

  @override
  String get branchNotPushed => 'ikke pushet';

  @override
  String branchNotOnRemote(String branch) {
    return '«$branch» finnes bare i denne samtalen';
  }

  @override
  String get branchNotOnRemoteHint =>
      'GitHub har aldri sett denne grenen, så en pull request kan ikke bruke den ennå. Publisering pusher committene som allerede er i worktree — ulagrede endringer blir stående.';

  @override
  String get publishBranch => 'Publiser gren';

  @override
  String branchPublished(String branch) {
    return 'Publiserte «$branch» til origin';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return 'Gren publisert. $count ucommittete endring(er) ble ikke tatt med.';
  }

  @override
  String get composePrLoadingBranches => 'Laster grener fra GitHub…';

  @override
  String get composePrBranchesFailed =>
      'Kunne ikke laste grener fra GitHub. Skriv inn et grenavn, eller sjekk GitHub-tilkoblingen.';

  @override
  String get composePrSubtitleFromSpace =>
      'Fra denne samtalens gren — publiser den først hvis GitHub ikke har sett den';

  @override
  String get obsTabInsights => 'Innsikt';

  @override
  String get obsTabLive => 'Live';

  @override
  String get obsTabQuality => 'Kvalitet';

  @override
  String get obsTabUsage => 'Bruk';

  @override
  String get obsUsageTotalTokens => 'Totale tokens';

  @override
  String get obsUsagePeakTokens => 'Maks tokens';

  @override
  String get obsUsageLongestSession => 'Lengste økt';

  @override
  String get obsUsageCurrentStreak => 'Nåværende rekke';

  @override
  String get obsUsageLongestStreak => 'Lengste rekke';

  @override
  String obsUsageDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dager',
      one: '1 dag',
      zero: '0 dager',
    );
    return '$_temp0';
  }

  @override
  String get obsUsageTokenActivity => 'Tokenaktivitet';

  @override
  String get obsUsageActivityModeLabel => 'Tokenaktivitetsmodus';

  @override
  String get obsUsageModeDaily => 'Daglig';

  @override
  String get obsUsageModeWeekly => 'Ukentlig';

  @override
  String get obsUsageModeCumulative => 'Kumulativ';

  @override
  String get obsUsageTimeRange => 'Tidsperiode';

  @override
  String get obsUsageTrendTitle => 'Daglig tokentrend';

  @override
  String get obsUsageModelUsage => 'Modellbruk';

  @override
  String get obsUsageTokensLabel => 'tokens';

  @override
  String get obsUsageNoActivity => 'Ingen tokenbruk registrert ennå';

  @override
  String get obsUsageOtherModels => 'Andre';

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
    return 'Tokenaktivitet fra $start til $end. $activeDays aktive dager. Travleste dag $peak tokens.';
  }

  @override
  String get obsScreenSubtitle =>
      'Live agentkontroll, kostnadsattribusjon, kvoter og kvalitetssignaler';

  @override
  String get obsRangeLast24h => 'Siste 24 timer';

  @override
  String get obsRangeLast7d => 'Siste 7 dager';

  @override
  String get obsRangeLast30d => 'Siste 30 dager';

  @override
  String get obsRangeAll => 'All tid';

  @override
  String get obsAddFilter => 'Legg til filter';

  @override
  String get obsFilterAgent => 'Agent';

  @override
  String get obsFilterModel => 'Modell';

  @override
  String get obsFilterStatus => 'Status';

  @override
  String get obsFilterRole => 'Rolle';

  @override
  String get obsKpiTotalRuns => 'Totale kjøringer';

  @override
  String get obsKpiTotalCost => 'Total kostnad';

  @override
  String get obsKpiErrorRate => 'Feilrate';

  @override
  String get obsKpiCacheRate => 'Cache-rate';

  @override
  String get obsKpiTokensPerSec => 'Tokens / sek';

  @override
  String get obsKpiAvgLatency => 'Snitt latenstid';

  @override
  String get obsKpiTtft => 'Tid til første token';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '$delta mot forrige periode';
  }

  @override
  String get obsChartActivity => 'Aktivitet';

  @override
  String get obsChartCost => 'Kostnad over tid';

  @override
  String get obsLegendRuns => 'Kjøringer';

  @override
  String get obsLegendErrors => 'Feil';

  @override
  String get obsAgentsTitle => 'Agenter';

  @override
  String obsShowAllAgents(int count) {
    return 'Vis alle $count agenter';
  }

  @override
  String get obsShowFewerAgents => 'Vis færre';

  @override
  String get obsRunsTitle => 'Kjøringer';

  @override
  String get obsNoRunsInRange => 'Ingen kjøringer i dette intervallet';

  @override
  String get obsColTime => 'Tid';

  @override
  String get obsColAgent => 'Agent';

  @override
  String get obsColStatus => 'Status';

  @override
  String get obsColModel => 'Modell';

  @override
  String get obsColDuration => 'Varighet';

  @override
  String get obsColTokens => 'Tokens';

  @override
  String get obsColCost => 'Kostnad';

  @override
  String get obsColErrors => 'Feil';

  @override
  String get obsColRuns => 'Kjøringer';

  @override
  String get obsColAvgLatency => 'Snitt latenstid';

  @override
  String get obsColLastActive => 'Sist aktiv';

  @override
  String get obsStatusPending => 'Ventende';

  @override
  String get obsStatusRunning => 'Kjører';

  @override
  String get obsStatusCompleted => 'Fullført';

  @override
  String get obsStatusError => 'Feil';

  @override
  String get obsRosterLoadError => 'Kunne ikke laste agentoversikten.';

  @override
  String get obsRosterEmpty => 'Ingen agenter ennå';

  @override
  String get obsRosterEmptyDescription =>
      'Send en agent, så vises den her live — status, gjeldende verktøy, tokens, kostnad.';

  @override
  String get obsKillAgent => 'Avslutt agent';

  @override
  String get obsRosterTokensLabel => 'tok';

  @override
  String get obsCostByRoleTitle => 'Kostnad etter rolle';

  @override
  String get obsCostByRoleSubtitle =>
      'Hvor dette arbeidsområdet bruker, etter agentrolle';

  @override
  String get obsRoleMain => 'Hoved';

  @override
  String get obsRoleSubagents => 'Underagenter';

  @override
  String get obsRoleAdvisor => 'Rådgiver';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return 'Hoved: $main · underagenter: $sub · rådgiver: $advisor';
  }

  @override
  String get obsTotal => 'Totalt';

  @override
  String get obsTokenModelTitle => 'Tokenmodell (5 akser)';

  @override
  String get obsTokenModelSubtitle =>
      'Hver token dette arbeidsområdet har brukt, etter akse';

  @override
  String get obsAxisInput => 'Inndata';

  @override
  String get obsAxisOutput => 'Utdata';

  @override
  String get obsAxisReasoning => 'Resonnering';

  @override
  String get obsAxisCacheRead => 'Cache-lesing';

  @override
  String get obsAxisCacheWrite => 'Cache-skriving';

  @override
  String get obsTotalTokens => 'Totale tokens';

  @override
  String get obsCacheDiscountNote =>
      'Cache-lese-tokens faktureres med rabatt, så de koster langt mindre enn samme volum ferske inndata.';

  @override
  String get obsByModelTitle => 'Etter modell';

  @override
  String get obsByModelSubtitle => 'Token- og kostnadsbruk per modell';

  @override
  String get obsNoModelUsage => 'Ingen modellbruk registrert ennå.';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kjøringer',
      one: '1 kjøring',
    );
    return '$_temp0';
  }

  @override
  String get obsPerRunTitle => 'Per kjøring';

  @override
  String get obsPerRunSubtitle => 'Typisk tokenkostnad for en enkelt kjøring';

  @override
  String get obsMedianRunTokens => 'Median kjøringstokens';

  @override
  String get obsMedianRunTokensSub => 'Midtpunkt på tvers av alle kjøringer';

  @override
  String get obsRunsInWorkspace => 'I dette arbeidsområdet';

  @override
  String get obsCostShare => 'Kostnadsandel';

  @override
  String get obsQuotaConfiguredLimits => 'Konfigurerte grenser';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      'Bruk mot takene du satte, verste status først.';

  @override
  String get obsQuotaAddLimit => 'Legg til grense';

  @override
  String get obsQuotaNoLimits =>
      'Ingen kvotegrenser konfigurert ennå — legg til én for å følge bruk mot et tak.';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return 'Fjern $title-grense';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return 'Tilbakestilles om $duration · $status';
  }

  @override
  String get obsQuotaUsageWindows => 'Bruksvinduer';

  @override
  String get obsQuotaUsageWindowsSubtitle =>
      'Observert bruk på tvers av alle leverandører, uten tak.';

  @override
  String get obsQuotaNoUsage => 'Ingen bruk registrert ennå.';

  @override
  String get obsQuotaTokensUsed => 'Tokens brukt';

  @override
  String get obsQuotaRequests => 'Forespørsler';

  @override
  String get obsQuotaUnitTokens => 'tokens';

  @override
  String get obsQuotaUnitRequests => 'forespørsler';

  @override
  String get obsQuotaUnitCost => 'kostnad';

  @override
  String get obsQuotaAddLimitTitle => 'Legg til kvotegrense';

  @override
  String get obsQuotaProviderLabel => 'Leverandør';

  @override
  String get obsQuotaWindowLabel => 'Vindu';

  @override
  String get obsQuotaUnitLabel => 'Enhet';

  @override
  String obsQuotaLimitLabel(String unit) {
    return 'Grense ($unit)';
  }

  @override
  String get obsQuotaCentsHint => 'I amerikanske cent (500 = \$5.00).';

  @override
  String get obsQuotaStatusOk => 'Ok';

  @override
  String get obsQuotaStatusWarning => 'Advarsel';

  @override
  String get obsQuotaStatusExhausted => 'Oppbrukt';

  @override
  String get obsQuotaStatusUnknown => 'Ukjent';

  @override
  String get obsGoalNoActiveTitle => 'Ingen aktivt mål';

  @override
  String get obsGoalNoActiveBody =>
      'Sett et mål for å gi agentene et objektiv og et valgfritt tokenbudsjett. Når kjøringer fullføres, fylles budsjettet, og agentene dyttes til å avslutte når det nesten er brukt opp.';

  @override
  String get obsGoalSetGoal => 'Sett et mål';

  @override
  String get obsGoalTokenBudget => 'Tokenbudsjett';

  @override
  String obsGoalTokensLeft(String tokens) {
    return '$tokens igjen';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens (ingen budsjett satt)';
  }

  @override
  String get obsGoalTokensUsed => 'Tokens brukt';

  @override
  String get obsGoalElapsed => 'Forløpt';

  @override
  String get obsGoalWrapUp => 'Avslutt';

  @override
  String get obsGoalClear => 'Fjern mål';

  @override
  String get obsGoalFallbackTitle => 'Mål';

  @override
  String get obsGoalSubtitle => 'Målmodus-budsjett';

  @override
  String get obsGoalStatusActive => 'Aktiv';

  @override
  String get obsGoalStatusPaused => 'På pause';

  @override
  String get obsGoalStatusBudgetLimited => 'Budsjettbegrenset';

  @override
  String get obsGoalStatusComplete => 'Ferdig';

  @override
  String get obsGoalStatusDropped => 'Avbrutt';

  @override
  String get obsGoalObjectiveLabel => 'Objektiv';

  @override
  String get obsGoalBudgetLabel => 'Tokenbudsjett (valgfritt)';

  @override
  String get obsGoalSetAction => 'Sett mål';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => 'Suksess %';

  @override
  String get obsBenchmarkPassed => 'Bestått';

  @override
  String get obsBenchmarkFailed => 'Mislyktes';

  @override
  String get obsBenchmarkErrors => 'Feil';

  @override
  String get obsBenchmarkSpend => 'Forbruk';

  @override
  String get obsBenchmarkCostPerTask => 'Kostnad / oppgave';

  @override
  String get obsBenchmarkTrials => 'Forsøk';

  @override
  String get obsBenchmarkNoTrials => 'Ingen kjøringer å score ennå.';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Og $count til',
      one: 'Og 1 til',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => 'Bestått';

  @override
  String get obsBenchmarkTrialFail => 'Ikke bestått';

  @override
  String get obsBenchmarkTrialError => 'Feil';

  @override
  String get obsBenchmarkTrialRunning => 'Kjører';

  @override
  String get obsBenchmarkReward => 'Belønning';

  @override
  String get obsBenchmarkReport => 'Rapport';

  @override
  String get obsBenchmarkCopyMarkdown => 'Kopier markdown';

  @override
  String get obsBenchmarkCopied => 'Rapport kopiert til utklippstavlen';

  @override
  String get obsBehaviorCaption =>
      'Dette er frustrasjonssignaler hentet fra dine egne meldinger — en avlesning av samtalehelse, ikke en poengsum for agentene. Beregnes lokalt; ingenting forlater denne enheten.';

  @override
  String get obsBehaviorMessagesAnalyzed => 'Meldinger analysert';

  @override
  String get obsBehaviorTotalSignals => 'Totale signaler';

  @override
  String get obsBehaviorYelling => 'Roping';

  @override
  String get obsBehaviorProfanity => 'Banning';

  @override
  String get obsBehaviorAnguish => 'Fortvilelse';

  @override
  String get obsBehaviorNegation => 'Negasjon';

  @override
  String get obsBehaviorRepetition => 'Gjentakelse';

  @override
  String get obsBehaviorBlame => 'Skyld';

  @override
  String get obsBehaviorConversationsTitle => 'Mest frustrerte samtaler';

  @override
  String get obsBehaviorConversationsSubtitle =>
      'Rangert etter signaltetthet på tvers av meldingene dine.';

  @override
  String get obsBehaviorNoSignals =>
      'Ingen frustrasjonssignaler oppdaget — smult vann.';

  @override
  String obsBehaviorMessagesCount(String count) {
    return '$count meldinger analysert';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '$count signaler';
  }

  @override
  String get obsAgentStatusIdle => 'Inaktiv';

  @override
  String get obsAgentStatusParked => 'Parkert';

  @override
  String get obsAgentStatusAborted => 'Avbrutt';

  @override
  String get obsAgentKindSub => 'Under';

  @override
  String get noChecksOnCommit => 'Ingen sjekker har kjørt på denne committen.';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kjører — $count jobber',
      one: 'Kjører — 1 jobb',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alle sjekker bestått — $count jobber',
      one: 'Alle sjekker bestått — 1 jobb',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fullført — $count jobber',
      one: 'Fullført — 1 jobb',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total jobber',
      one: '1 jobb',
    );
    return '$failed av $_temp0 mislyktes';
  }

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jobber',
      one: '1 jobb',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return 'Matrise: $jobId';
  }

  @override
  String get jobLogsPending => 'Logger vises her når jobben er ferdig.';

  @override
  String get jobLogsUnavailable =>
      'Logger er ikke tilgjengelige for denne jobben.';

  @override
  String get noLogsForStep => 'Ingen logger fanget for dette steget.';

  @override
  String get jobLogsTruncated => 'Logg avkortet — viser den nyeste utdataen.';

  @override
  String get fullLog => 'Full logg';

  @override
  String get copyLogs => 'Kopier logger';

  @override
  String get resizeGraph => 'Dra for å endre størrelse på grafen';

  @override
  String workflowRunStartedAgo(String time) {
    return 'Startet $time';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return 'Fullført $time';
  }

  @override
  String get chatBridgesTitle => 'Chat-broer';

  @override
  String chatProviderDescription(String provider, String command) {
    return 'Nevn boten i $provider for å sette en agent på noe, eller opprett saker med $command.';
  }

  @override
  String chatConnectProvider(String provider) {
    return 'Koble til $provider';
  }

  @override
  String get chatDisconnectProvider => 'Koble fra';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$botName i $teamName';
  }

  @override
  String get chatStateLive => 'Live';

  @override
  String get chatStateConnecting => 'Kobler til…';

  @override
  String get chatStateError => 'Tilkoblingsfeil';

  @override
  String get chatNotConnected => 'Ikke tilkoblet';

  @override
  String chatStreamingUnavailable(String provider) {
    return 'Live-strømming er av for denne $provider-appen — svar kommer som én melding.';
  }

  @override
  String chatAdminOnly(String provider) {
    return 'Bare en admin kan koble til $provider for dette arbeidsområdet.';
  }

  @override
  String chatConnectHint(String provider) {
    return 'Opprett en $provider-app, og lim inn påloggingsinformasjonen her. Control Center kobler ut til $provider, så denne serveren trenger ingen offentlig adresse.';
  }

  @override
  String chatOpenConsole(String provider) {
    return 'Åpne $provider-konsoll';
  }

  @override
  String get chatOpenSetupGuide => 'Oppsettsveiledning';

  @override
  String get chatFieldBotToken => 'Bot-token';

  @override
  String get chatFieldAppToken => 'App-nivå-token';

  @override
  String get chatFieldConfigRefreshToken => 'Appkonfigurasjonstoken';

  @override
  String chatFieldOptional(String label) {
    return '$label (valgfritt)';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return 'Knytt $provider-kontoen min';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return 'Knytt $provider-kontoen din slik at meldinger du sender der, attribueres til deg.';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return 'Knyttet til $externalUserId';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return 'Knytt $provider-kontoen din';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return 'Send denne kommandoen til boten i $provider. Den virker én gang og utløper om 15 minutter.';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return '$provider-kontoen din er nå knyttet — meldinger du sender der, attribueres til deg.';
  }

  @override
  String get chatLinkedAccounts => 'Knyttede kontoer';

  @override
  String chatNoLinkedAccounts(String provider) {
    return 'Ingen har knyttet $provider-kontoen sin ennå.';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count knyttede kontoer',
      one: '1 knyttet konto',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '$externalUserId · matchet på e-post';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '$externalUserId · knyttet med en kode';
  }

  @override
  String get chatUnlink => 'Fjern tilknytning';

  @override
  String get chatCustomizeBot => 'Tilpass bot';

  @override
  String get chatCustomizeBotDescription =>
      'Gi boten nytt navn, endre hva den sier om seg selv, eller gi slash-kommandoen nytt navn.';

  @override
  String get chatCustomizeBotUnavailable =>
      'Control Center trenger et appkonfigurasjonstoken for å redigere boten. Koble til på nytt og inkluder ett.';

  @override
  String chatCreateAppTitle(String provider) {
    return 'Opprett $provider-appen';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'Control Center kan opprette $provider-appen for deg, med riktige tillatelser og hendelser allerede satt. Du fullfører i $provider, og limer deretter inn påloggingsinformasjonen her.';
  }

  @override
  String get chatCreateApp => 'Opprett app';

  @override
  String get chatCreateAppCta => 'Opprett app for meg';

  @override
  String get chatAppNameLabel => 'Appnavn';

  @override
  String get chatBotDisplayNameLabel =>
      'Botnavn (det medlemmene skriver etter @)';

  @override
  String get chatDescriptionLabel => 'Kort beskrivelse';

  @override
  String get chatAgentDescriptionLabel => 'Hva boten sier den kan gjøre';

  @override
  String get chatCommandLabel => 'Slash-kommando';

  @override
  String get chatDirectMessages => 'Direktemeldinger';

  @override
  String chatDirectMessagesHint(String provider) {
    return 'Lar medlemmer chatte med boten i en DM. Kan kreve et betalt $provider-abonnement.';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return '$provider opprettet appen $appId.';
  }

  @override
  String chatRemainingSteps(String provider) {
    return 'Noen steg gjenstår, og bare $provider kan gjøre dem:';
  }

  @override
  String get chatStepAppToken => 'Generer et app-nivå-token';

  @override
  String get chatStepInstall => 'Installer appen';

  @override
  String get chatOpenAppSettings => 'Åpne appinnstillinger';

  @override
  String get chatContinueToCredentials => 'Lim inn påloggingsinformasjonen';

  @override
  String chatBotUpdated(String provider) {
    return 'Bot oppdatert i $provider.';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return '$provider endret appens tillatelser. Installer appen på nytt for at de skal tre i kraft.';
  }

  @override
  String get chatReinstallApp => 'Installer app på nytt';

  @override
  String chatIconNotEditable(String provider) {
    return 'Botens ikon kan bare endres i ${provider}s egne appinnstillinger.';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return 'Du kan også opprette den i $provider selv — ingen token nødvendig. Innstillingene over følger med lenken.';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return 'Opprett i $provider';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return '$provider åpnet i nettleseren med denne konfigurasjonen forhåndsutfylt. Opprett appen der, fullfør deretter disse stegene og kom tilbake med tokenene.';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return '$provider rapporterer ikke hvilken app den opprettet, så å tilpasse boten herfra trenger et appkonfigurasjonstoken senere.';
  }

  @override
  String get chatStepCreateApp =>
      'Opprett appen fra den forhåndsutfylte konfigurasjonen';

  @override
  String chatStepCreateAppHint(String provider) {
    return 'Velg et arbeidsområde i $provider og bekreft.';
  }

  @override
  String get chatStepAppTokenHint =>
      'Basic information → app-level tokens, med connections:write-skopet.';

  @override
  String get chatStepInstallHint =>
      'Install app → kopier bot user OAuth-tokenet.';

  @override
  String get calendarUseBuiltinApp => 'Bruk Control Centers Google-app';

  @override
  String get calendarUseBuiltinAppHint =>
      'Godkjenn med Google-kontoen din. Ingenting å sette opp i Google Cloud.';

  @override
  String get calendarUseOwnClient => 'Bruk min egen Google Cloud-klient';

  @override
  String get calendarUseOwnClientHint =>
      'Skriv inn en OAuth-klient fra ditt eget Google Cloud-prosjekt.';

  @override
  String get aboutTitle => 'Om';

  @override
  String get aboutAppVersion => 'Appversjon';

  @override
  String get aboutServerVersion => 'Tilkoblet server';

  @override
  String get aboutRpcCatalog => 'RPC-katalog';

  @override
  String get aboutServerUnknown => 'Ikke rapportert';

  @override
  String get serverStaleTitle =>
      'Den medfølgende serveren er eldre enn denne appen';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return 'Den kjørende cc_server er $serverVersion mens denne appen er $appVersion. Start appen på nytt slik at den tar i bruk den nyeste medfølgende serverbyggen; under utvikling, bygg den på nytt med `dart build cli` i apps/cc_server.';
  }

  @override
  String get updateCheckButton => 'Se etter oppdateringer';

  @override
  String get updateChecking => 'Ser etter oppdateringer…';

  @override
  String get updateUpToDate => 'Du er à jour';

  @override
  String get updateDeferredBusy =>
      'En oppdatering er klar, men et møte tar opp — den spør etter at det er ferdig.';

  @override
  String get updateOpenedReleasesPage => 'Åpnet utgivelsessiden i nettleseren.';

  @override
  String get updateCheckFailed => 'Oppdateringssjekk mislyktes';

  @override
  String updateAvailableVersion(String version) {
    return 'Versjon $version er tilgjengelig.';
  }

  @override
  String get updateBannerTitle => 'En ny Control Center er tilgjengelig';

  @override
  String get updateBannerRefresh => 'Oppdater';

  @override
  String get updateBlockedRecording =>
      'Oppdatering er satt på pause mens et møte tar opp — den lastes på nytt når det er ferdig.';

  @override
  String get settingsScopeYou => 'Deg';

  @override
  String get settingsScopeWorkspace => 'Arbeidsområde';

  @override
  String get settingsScopeServer => 'Server';

  @override
  String get settingsProfile => 'Profil og identitet';

  @override
  String get settingsYourDevices => 'Dine enheter';

  @override
  String get settingsWorkspaceGeneral => 'Generelt';

  @override
  String get settingsServerConnection => 'Tilkobling og status';

  @override
  String get settingsModelProviders => 'Modellleverandører';

  @override
  String get settingsVoiceModels => 'Stemme- og møtemodeller';

  @override
  String get settingsDiagnostics => 'Diagnostikk og personvern';

  @override
  String get settingsAbout => 'Om';

  @override
  String get settingsScopeBadgeYou => 'DEG';

  @override
  String get settingsScopeBadgeDevice => 'DENNE ENHETEN';

  @override
  String get settingsScopeBadgeWorkspace => 'ARBEIDSOMRÅDE';

  @override
  String get settingsScopeBadgeServer => 'SERVER';

  @override
  String get settingsProfileDescription =>
      'Navn, e-post og git-identitet i dette arbeidsområdet. Å bytte arbeidsområde bytter dette overlegget; kallenavn, innlogging og enheter blir på kontoen.';

  @override
  String get settingsServerConnectionDescription =>
      'Hvilken server denne klienten snakker med, og hvordan denne serveren deles (mDNS, tunneler, relé).';

  @override
  String get settingsAboutDescription => 'Byggidentitet og oppdateringer.';

  @override
  String get settingsDiagnosticsDescription =>
      'Isolering, indeksering, synkronisering, logging og krasjrapportering for denne installasjonen.';

  @override
  String get settingsWorkspaceGeneralDescription =>
      'Identitet, policy og konvensjoner delt av alle i dette arbeidsområdet.';

  @override
  String get settingsWorkspaceMeetingsDescription =>
      'Notatmaler og lagrede stemmer for møter i dette arbeidsområdet.';

  @override
  String get settingsWorkspacePolicyLabel => 'Arbeidsområdepolicy';

  @override
  String get settingsWorkspacePolicyDescription =>
      'Gjelder for hvert medlem og hver agent i dette arbeidsområdet.';

  @override
  String get settingsSecretGlobsLabel => 'Hemmelige stiutelatelser';

  @override
  String get settingsSecretGlobsHelp =>
      'Én glob per linje. Disse stiene er skjult for lesere og gjester på kodebærende flater, i tillegg til de innebygde standardene.';

  @override
  String get settingsReviewConcurrencyLabel => 'Gjennomgangs-fan-out';

  @override
  String get settingsReviewConcurrencyHelp =>
      'Hvor mange reviewere som sendes parallelt når ingen eksplisitt antall er gitt.';

  @override
  String get settingsReviewLevelLabel => 'Gjennomgangsnivå';

  @override
  String get settingsReviewLevelHelp =>
      'Hvor dypt AI-gjennomgangen går, og hvor mye av det den finner som rapporteres først. Ingenting kastes — et lettere nivå grupperer mindre funn i stedet for å droppe dem.';

  @override
  String get reviewLevelLight => 'Lett';

  @override
  String get reviewLevelBalanced => 'Balansert';

  @override
  String get reviewLevelThorough => 'Grundig';

  @override
  String get reviewLevelLightHint =>
      'Én reviewer. Bare det som materielt teller, rapporteres først.';

  @override
  String get reviewLevelBalancedHint =>
      'Tre reviewere som dekker QA, arkitektur og implementering.';

  @override
  String get reviewLevelThoroughHint =>
      'Legger til sikkerhets- og ytelsesspesialister, og rapporterer alt som ble funnet.';

  @override
  String get askAiReviewAtLevel => 'Gjennomgå på et annet nivå';

  @override
  String reviewNitpicksGroup(int count) {
    return 'Nitpicks ($count)';
  }

  @override
  String get reviewFindingResolve => 'Fikset';

  @override
  String get reviewFindingResolveHint =>
      'Merk dette funnet som fikset. Det teller ikke lenger mot gjennomgangen.';

  @override
  String get reviewFindingDismiss => 'Avvis';

  @override
  String get reviewFindingDismissHint =>
      'Ikke et reelt problem. Reviewere slutter å flagge dette mønsteret på fremtidige PR-er.';

  @override
  String get reviewFindingReopen => 'Gjenåpne';

  @override
  String get reviewFindingStatusUndoLabel => 'Funnstatus';

  @override
  String get reviewFindingDismissTitle => 'Avvis dette funnet';

  @override
  String get reviewFindingDismissReasonHint =>
      'Hvorfor gjelder dette ikke? Reviewere leser det.';

  @override
  String reviewFindingStatusFailed(String error) {
    return 'Kunne ikke oppdatere funnet: $error';
  }

  @override
  String get reviewStaleTitle => 'Denne gjennomgangen er utdatert';

  @override
  String get reviewStaleBody =>
      'Pull requesten har gått videre siden denne gjennomgangen kjørte. Funn kan peke på kode som ikke lenger finnes.';

  @override
  String reviewStaleReviewedAt(String sha) {
    return 'Gjennomgått ved $sha';
  }

  @override
  String get reviewStaleRerun => 'Gjennomgå på nytt';

  @override
  String reviewStaleNotificationTitle(int prNumber) {
    return 'Gjennomgang utdatert på #$prNumber';
  }

  @override
  String reviewStaleNotificationBody(String title) {
    return '$title har nye committer siden siste gjennomgang.';
  }

  @override
  String get reviewCategorySecurity => 'Sikkerhet';

  @override
  String get reviewCategoryStability => 'Stabilitet';

  @override
  String get reviewCategoryDataIntegrity => 'Dataintegritet';

  @override
  String get reviewCategoryCorrectness => 'Korrekthet';

  @override
  String get reviewCategoryPerformance => 'Ytelse';

  @override
  String get reviewCategoryMaintainability => 'Vedlikeholdbarhet';

  @override
  String get reviewEffortQuickWin => 'Rask gevinst';

  @override
  String get reviewEffortModerate => 'Moderat';

  @override
  String get reviewEffortHeavyLift => 'Tungt løft';

  @override
  String get reviewProposedFix => 'Foreslått fiks';

  @override
  String get reviewAiAgentPrompt => 'Prompt for AI-agenter';

  @override
  String get reviewCopyAiPrompt => 'Kopier prompt';

  @override
  String get settingsWorkspaceAdminOnly =>
      'Bare arbeidsområdeadminer kan endre disse.';

  @override
  String get chatMyAccountsTitle => 'Knyttede chat-kontoer';

  @override
  String get settingsServerSso => 'Enkel pålogging';

  @override
  String get settingsServerSsoDescription =>
      'SAML- og OpenID Connect-innlogging med brukerprovisjonering';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabledDescription =>
      'Brukere kan logge inn med denne leverandøren';

  @override
  String get ssoEnabledDescriptionOn =>
      'Innlogging er aktiv for denne leverandøren';

  @override
  String get ssoIdpMetadataLabel => 'IdP-metadata-XML';

  @override
  String get ssoIdpMetadataHint => 'lim inn IdP-ens EntityDescriptor XML';

  @override
  String get ssoEmailAttributeLabel => 'E-postattributt';

  @override
  String get ssoDisplayNameAttributeLabel => 'Visningsnavnattributt';

  @override
  String get ssoGroupsAttributeLabel => 'Gruppeattributt';

  @override
  String get ssoIssuerLabel => 'Utsteder-URL';

  @override
  String get ssoClientIdLabel => 'Client ID';

  @override
  String get ssoGroupsClaimLabel => 'Gruppeclaim';

  @override
  String get ssoAutoMemberLabel =>
      'Legg brukere til hvert arbeidsområde ved første innlogging';

  @override
  String get ssoAutoMemberDescription =>
      'Slå av for å kreve en invitasjon per arbeidsområde';

  @override
  String get ssoAllowJitLabel =>
      'Provisjoner ukjente brukere ved første innlogging';

  @override
  String get ssoAllowJitDescription =>
      'Slå av for å avvise brukere uten en eksisterende konto';

  @override
  String get ssoAllowIdpInitiatedLabel =>
      'Godta uoppfordret (IdP-initiert) innlogging';

  @override
  String get ssoAllowIdpInitiatedDescription =>
      'Strengt for IdP-portaler som starter apper direkte';

  @override
  String get ssoWantResponseSignedLabel => 'Krev en signert svarkonvolutt';

  @override
  String get ssoWantResponseSignedDescription =>
      'Assertion-signaturer kreves alltid';

  @override
  String get ssoTestConnectionButton => 'Test tilkobling';

  @override
  String get ssoTestConnectionOk => 'Tilkoblingen virker:';

  @override
  String get ssoCopySpMetadata => 'Kopier SP-metadata';

  @override
  String get ssoCopySpMetadataDone => 'SP-metadata kopiert til utklippstavlen';

  @override
  String get ssoSavedToast => 'Innstillinger for enkel pålogging lagret';

  @override
  String get ssoUnavailable =>
      'Denne serveren eksponerer ikke innstillinger for enkel pålogging. Oppdater serverbinæren og prøv igjen.';

  @override
  String get ssoScimCardTitle => 'Brukerprovisjonering (SCIM)';

  @override
  String get ssoScimDescription =>
      'Pek identitetsleverandørens SCIM-kobling mot endepunktet under med et bearer-token. Deprovisjonering tilbakekaller økter og arbeidsområdetilgang innen sekunder. Serveren må være nåbar for IdP-en (tunnel eller offentlig URL).';

  @override
  String get ssoScimEndpoint => 'SCIM-endepunkt';

  @override
  String get ssoScimEndpointUnknownOrigin =>
      'Sett serverens offentlige URL eller slå på en tunnel først';

  @override
  String get ssoScimRegenerate => 'Regenerer token';

  @override
  String get ssoScimRegenerateConfirm =>
      'Generere et nytt SCIM bearer-token? Det forrige tokenet slutter å virke umiddelbart.';

  @override
  String get ssoScimTokenTitle => 'Bearer-token';

  @override
  String get ssoScimTokenPresent => 'Et token er konfigurert';

  @override
  String get ssoScimTokenAbsent =>
      'Ingen token ennå — generer ett for å slå på SCIM';

  @override
  String get ssoScimTokenOnce => 'SCIM-token (vises én gang)';

  @override
  String ssoSignInWith(String provider) {
    return 'Logg inn med $provider';
  }

  @override
  String get ssoProbeFailed => 'Kunne ikke nå den serveren for enkel pålogging';

  @override
  String get ssoOpensBrowser => 'Åpner nettleseren for å fullføre innloggingen';

  @override
  String get ssoWaitingForBrowser =>
      'Venter på at nettleseren skal fullføre innloggingen…';

  @override
  String get ssoBrowserOpenFailed =>
      'Kunne ikke åpne nettleseren for enkel pålogging';

  @override
  String get ssoUseManualPairing =>
      'Logg inn med en invitasjon eller paringsnøkkel i stedet';

  @override
  String get ssoHideManualPairing => 'Skjul manuell paring';

  @override
  String get ssoClientIdHint =>
      'Offentlig (PKCE) klient — ingen hemmelighet nødvendig';

  @override
  String get ssoClientSecretLabel => 'Klienthemmelighet (valgfritt)';

  @override
  String get ssoClientSecretHintUnset =>
      'Trengs bare for konfidensielle IdP-klienter';

  @override
  String get ssoClientSecretHintSet =>
      'En hemmelighet er lagret — la stå tomt for å beholde den';

  @override
  String get ssoPairingToggle =>
      'Tillat manuell paring (invitasjonskoder og paringsnøkler)';

  @override
  String get ssoPairingToggleDescription =>
      'Slå av for å gjøre tilslutning til kun enkel pålogging — nye enheter kommer via SSO-innlogginger; eksisterende enheter fortsetter å virke';

  @override
  String get ssoPairConfirmTitle => 'Koble til server?';

  @override
  String ssoPairConfirmBody(String server) {
    return 'Påloggingsinformasjon for $server kom inn, men ingen innlogging ble startet fra denne appen. Koble til denne serveren?';
  }

  @override
  String get ssoPairConfirmConnect => 'Koble til';

  @override
  String get ssoPairConfirmCancel => 'Ignorer';

  @override
  String get forgeConnections => 'Kodehosting';

  @override
  String get connect => 'Koble til';

  @override
  String get disconnect => 'Koble fra';

  @override
  String get notConnected => 'Ikke tilkoblet';

  @override
  String get checkingConnection => 'Sjekker tilkobling…';

  @override
  String get fromEnvironment => 'fra miljøet';

  @override
  String forgeTokenTitle(String forge) {
    return '$forge-token';
  }

  @override
  String get settingsAudio => 'Lyd';

  @override
  String get settingsAudioDescription =>
      'Mikrofon, diktering, møteoppdagelse og lydlandskapsutdata.';

  @override
  String get audioDevicesSection => 'Lydenheter';

  @override
  String get voiceInputBehaviorSection => 'Diktering og møter';

  @override
  String get audioOutputDeviceTitle => 'Utdataenhet';

  @override
  String get audioOutputDefaultHint =>
      'All app-lyd spilles gjennom systemets standardutgang.';

  @override
  String get audioOutputGone =>
      'Den valgte utdataenheten er ikke lenger tilkoblet — systemstandarden brukes til du velger en annen.';

  @override
  String get reviewHubIntroBody =>
      'Agenter analyserer diffen, kartlegger endringsområdene og kommer til en konsensusdom.';

  @override
  String get reviewHubAlreadyRunning =>
      'En gjennomgang kjører allerede for denne pull requesten';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return 'Siden siste gjennomgang: $resolved løst · $added nye · $open fortsatt åpne';
  }

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return 'Tidligere gjennomgått ved $sha';
  }

  @override
  String reviewArtifactFixAll(int count) {
    return 'Fiks $count funn';
  }

  @override
  String reviewArtifactFixSelected(int count) {
    return 'Fiks $count valgte';
  }

  @override
  String reviewArtifactCommentSelected(int count) {
    return 'Kommenter $count valgte';
  }

  @override
  String get webConnectTitle => 'Koble til Control Center';

  @override
  String get webConnectSubtitle =>
      'Koble til en kjørende cc-server over WebSocket. Nøkkelen din blir på denne enheten.';

  @override
  String get webConnectServerLabel => 'Server';

  @override
  String get webConnectDeviceIdLabel => 'Enhets-id';

  @override
  String get webConnectPairingKeyLabel => 'Paringsnøkkel';

  @override
  String get webConnectPairingKeyHint => 'lim inn PSK-en';

  @override
  String get webConnectStayConnected => 'Hold tilkoblingen på denne enheten';

  @override
  String get webConnectStayConnectedDetail =>
      'Hold tilkoblingen på denne enheten (lagrer nøkkelen din i denne nettleseren)';

  @override
  String failedToCreateWorkspace(String error) {
    return 'Kunne ikke opprette arbeidsområde: $error';
  }

  @override
  String committedRelative(String relative) {
    return 'committet $relative';
  }

  @override
  String get selectAgents => 'Velg agenter';

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
  String get newConversation => 'Ny samtale';

  @override
  String get untitledConversation => 'Samtale uten tittel';

  @override
  String get conversationTitleOptionalHint =>
      'Valgfritt — la stå tomt, så navngir tittelmodellen den automatisk';

  @override
  String get conversationTitlesSectionTitle => 'Samtaletitler';

  @override
  String get conversationTitlesSectionCaption =>
      'Velg kjøreren som navngir nye samtaler i dette arbeidsområdet automatisk. Titler er av til en adapter er valgt, og gjelder for alle medlemmer.';

  @override
  String get conversationTitlesModelLabel => 'Tittelmodell';

  @override
  String get conversationTitlesAdapterLabel => 'Adapter';

  @override
  String get conversationTitlesAdapterHint => 'Av';

  @override
  String get conversationTitlesAdapterOff => 'Av';

  @override
  String get startThread => 'Start tråd';

  @override
  String get deleteSpaceConfirm =>
      'Slette dette området? Alle meldinger går tapt.';

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
    return 'Siste svar $time';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Logg inn med $provider';
  }

  @override
  String get signInAgain => 'Logg inn på nytt';

  @override
  String get signInNotFinished =>
      'Innloggingen har ikke kommet tilbake ennå. Fullfør den i nettleseren, og sjekk deretter på nytt.';

  @override
  String get signedOutTitle => 'Du er logget ut';

  @override
  String get signedOutSubtitle =>
      'Kodehosting-tilkoblingen din er ikke lenger gyldig — et token utløp, eller tilgangen ble tilbakekalt. Ingenting annet er endret: logg inn igjen, så er alt der du lot det.';

  @override
  String get viaServerApp => 'via denne serverens app';

  @override
  String get ticketing => 'Saker';

  @override
  String get ticketingProviderHelp =>
      'Hvor sakene dine bor. Lokal holder dem i Control Center.';

  @override
  String providerComingSoon(String provider) {
    return '$provider (snart)';
  }

  @override
  String get ticketProviderLocal => 'Lokal';

  @override
  String get addKey => 'Legg til nøkkel';

  @override
  String get providerApps => 'Leverandørapper';

  @override
  String get providerAppsDescription =>
      'Arbeidsområder arver denne GitHub-appen med mindre de velger en annen app eller et personlig tilgangstoken. Bakgrunnsarbeid — webhooks, polling, synk — kjører på appen, aldri på noens token.';

  @override
  String get providerAppId => 'App-id';

  @override
  String get providerPrivateKey => 'Privat nøkkel';

  @override
  String get providerClientId => 'Client id';

  @override
  String get providerClientSecret => 'Client secret';

  @override
  String get providerApiKey => 'API-nøkkel';

  @override
  String get providerCallbackUrl => 'Callback-URL';

  @override
  String get providerAppFullyConfigured =>
      'Serveren kan opptre som seg selv, og folk kan logge inn.';

  @override
  String get providerAppServerOnly =>
      'Serveren kan opptre som seg selv. Legg til en client id og secret for å la folk logge inn.';

  @override
  String get providerAppSignInOnly =>
      'Folk kan logge inn. Bakgrunnsarbeid faller tilbake til påloggingsinformasjonen deres.';

  @override
  String providerAppInstalledOn(String accounts) {
    return 'Påloggingsinformasjonen virker. Installert på: $accounts';
  }

  @override
  String deviceCodeInstructions(String provider) {
    return 'Skriv inn denne koden på $provider-siden som nettopp åpnet. Den er kopiert til utklippstavlen.';
  }

  @override
  String get deviceCodeWaiting => 'Venter på at du fullfører i nettleseren…';

  @override
  String get copyCodeAndOpen => 'Kopier kode og åpne';

  @override
  String get couldNotOpenBrowser =>
      'Ingen nettleser kunne åpnes. Kopier lenken og fullfør innloggingen selv.';

  @override
  String get contextUsage => 'Kontekstbruk';

  @override
  String get contextUsageFull => 'fullt';

  @override
  String get contextUsageTokens => 'tokens';

  @override
  String get contextSeeMore => 'Se mer';

  @override
  String get contextSegmentSystemPrompt => 'Systemprompt';

  @override
  String get contextSegmentRules => 'Regler';

  @override
  String get contextSegmentSkills => 'Ferdigheter';

  @override
  String get contextSegmentToolDefinitions => 'Verktøydefinisjoner';

  @override
  String get contextSegmentMcpTools => 'MCP- og dynamiske verktøy';

  @override
  String get contextSegmentDeferredTools => 'Verktøy lastet ved behov';

  @override
  String get contextSegmentSubagents => 'Underagentdefinisjoner';

  @override
  String get contextSegmentMemory => 'Minne';

  @override
  String get contextSegmentConversation => 'Samtale';

  @override
  String get contextExplorerTitle => 'Kontekst';

  @override
  String get contextExplorerEverything => 'Alt';

  @override
  String get contextExplorerSelectPart =>
      'Velg en del for å inspisere innholdet';

  @override
  String get contextExplorerUnavailable => 'Kontekstoversikt utilgjengelig';

  @override
  String get contextRetry => 'Prøv på nytt';

  @override
  String get settingsFieldOptional => 'Valgfritt';

  @override
  String get settingsFilterHint => 'Filtrer denne listen';

  @override
  String get settingsValueNotAvailable => 'Ikke tilgjengelig ennå';

  @override
  String get settingsNoEntriesYet => 'Ingenting her ennå';

  @override
  String get settingsChangedBadge => 'Endret';

  @override
  String get ssoConnectionCardDescription =>
      'Velg hvordan folk logger inn på denne serveren, og slå deretter på den tilkoblingen.';

  @override
  String get ssoUseSamlForSignIn => 'Bruk SAML til innlogging';

  @override
  String get ssoUseOidcForSignIn => 'Bruk OpenID Connect til innlogging';

  @override
  String get ssoSaveConnection => 'Lagre tilkobling';

  @override
  String get ssoStateLive => 'Live';

  @override
  String get ssoStateConfiguredOff => 'Konfigurert, av';

  @override
  String get ssoStateOnIncomplete => 'På, ufullstendig';

  @override
  String get ssoStateActive => 'Aktiv';

  @override
  String get ssoStateAllowed => 'Tillatt';

  @override
  String get ssoStateNoToken => 'Ingen token';

  @override
  String get ssoSummaryDirectorySync => 'Katalogsynkronisering';

  @override
  String get ssoSummaryManualPairing => 'Manuell paring';

  @override
  String get ssoNoMethodLiveNote =>
      'Ingen innloggingsmetode er live. Nye enheter slutter seg til med en invitasjon eller paringsnøkkel til du konfigurerer en tilkobling og slår den på.';

  @override
  String get ssoMethodSamlBlurb =>
      'For identitetsleverandører som snakker SAML 2.0, som Okta, Entra ID eller Google Workspace.';

  @override
  String get ssoMethodOidcBlurb =>
      'For identitetsleverandører som snakker OpenID Connect. Vanligvis den enkleste av de to å sette opp.';

  @override
  String get ssoGroupIdentityProvider => 'Identitetsleverandør';

  @override
  String get ssoGroupIdentityProviderSamlDescription =>
      'Hvor assertions kommer fra, og hvordan denne serveren verifiserer dem.';

  @override
  String get ssoGroupIdentityProviderOidcDescription =>
      'Hvilken utsteder denne serveren stoler på, og klienten den autentiserer som.';

  @override
  String get ssoSpEntityIdShortLabel => 'SP entity ID';

  @override
  String get ssoSpEntityIdDescription =>
      'La stå tomt for å utlede den fra server-URL-en.';

  @override
  String get ssoIssuerDescription =>
      'Base-URL-en som serverer leverandørens discovery-dokument.';

  @override
  String get ssoSecretStored => 'Lagret';

  @override
  String get ssoGroupHandoff => 'Hva identitetsleverandøren din trenger';

  @override
  String get ssoGroupHandoffDescription =>
      'Lim inn disse i applikasjonen du opprettet hos leverandøren din.';

  @override
  String get ssoOriginUnknownTitle =>
      'Denne serveren kjenner ikke sin offentlige URL';

  @override
  String get ssoOriginUnknownBody =>
      'Innloggings- og callback-URL-ene bygges fra den, så leverandøren din kan ikke nå denne serveren før én er satt. Legg til en offentlig URL eller slå på en tunnel under Server → Tilkobling.';

  @override
  String get ssoAcsUrlLabel => 'Assertion consumer service (ACS) URL';

  @override
  String get ssoAcsUrlDescription =>
      'Der leverandøren din poster den signerte assertionen.';

  @override
  String get ssoSpEntityIdResolvedLabel => 'Service provider entity ID';

  @override
  String get ssoMetadataUrlLabel => 'SP-metadata-URL';

  @override
  String get ssoMetadataUrlDescription =>
      'Leverandører som importerer metadata kan hente den herfra i stedet.';

  @override
  String get ssoRedirectUriLabel => 'Redirect URI';

  @override
  String get ssoRedirectUriDescription =>
      'Legg denne til blant tillatte redirect URI-er for leverandørens applikasjon.';

  @override
  String get ssoSignInUrlLabel => 'Innloggings-URL';

  @override
  String get ssoSignInUrlDescription =>
      'Send folk hit for å starte en enkel pålogging.';

  @override
  String get ssoGroupAttributeMapping => 'Attributtkartlegging';

  @override
  String get ssoGroupAttributeMappingDescription =>
      'Hvilket claim som bærer hvert felt. Behold standardene med mindre leverandøren din gir dem nytt navn.';

  @override
  String get ssoGroupAccess => 'Tilgang og roller';

  @override
  String get ssoGroupAccessDescription =>
      'Hva noen som logger inn vellykket, får lov til å gjøre.';

  @override
  String get ssoDefaultRoleShortLabel => 'Standardrolle';

  @override
  String get ssoDefaultRoleDescription =>
      'Gis til alle hvis grupper ikke matcher noen kartlegging under.';

  @override
  String get ssoRoleMapShortLabel => 'Gruppe-til-rolle-kartlegging';

  @override
  String get ssoRoleMapDescription =>
      'Den første matchende gruppen vinner. Eier kan ikke tildeles på denne måten.';

  @override
  String get ssoRoleMapGroupHint => 'Gruppenavn fra leverandøren din';

  @override
  String get ssoRoleMapAdd => 'Legg til kartlegging';

  @override
  String get ssoRoleMapEmpty =>
      'Ingen kartlegginger — alle får standardrollen.';

  @override
  String get ssoAdvancedSummary =>
      'Klokkeforskjell, IdP-initiert innlogging, signaturpolicy';

  @override
  String get ssoClockSkewShortLabel => 'Klokkeforskjell';

  @override
  String get ssoClockSkewDescription =>
      'Sekunder toleranse på assertion-tidsstempler. 90 passer de fleste leverandører.';

  @override
  String get ssoScimGenerate => 'Generer token';

  @override
  String get ssoScimTokenOnceBody =>
      'Kopiert til utklippstavlen. Den vises én gang og kan ikke gjenopprettes, så lim den inn hos leverandøren din nå.';

  @override
  String get ssoPairingCardTitle => 'Manuell paring';

  @override
  String get ssoPairingCardDescription =>
      'Den andre veien inn på denne serveren: invitasjonskoder og paringsnøkler, for enheter som ikke går gjennom enkel pålogging.';

  @override
  String settingsCountOfTotal(int count, int total) {
    return '$count av $total';
  }

  @override
  String get providersNoneConnectedNote =>
      'Ingen leverandør er tilkoblet, så den innebygde agentkjøretiden har ingenting å kjøre på. Legg til en API-nøkkel eller logg inn på én under.';

  @override
  String get providersFilterHint => 'Filtrer leverandører';

  @override
  String get providersNoneMatch => 'Ingenting matcher dette filteret';

  @override
  String get providerDeniedHereTitle => 'Nektet i dette arbeidsområdet';

  @override
  String get providerDeniedHereBody =>
      'Agenter her kan ikke bruke denne leverandøren, selv om den er tilkoblet. Andre arbeidsområder påvirkes ikke.';

  @override
  String get providerNeedsSignIn => 'Logg inn for å bruke denne leverandøren';

  @override
  String get providerNeedsApiKey =>
      'Legg til en API-nøkkel for å bruke denne leverandøren';

  @override
  String get providerApiKeyLabel => 'API-nøkkel';

  @override
  String get providerGenerationDefaults => 'Leverandørstandarder';

  @override
  String get providerNoModelsYet =>
      'Ingen modeller rapportert ennå. Koble til leverandøren, og synkroniser deretter.';

  @override
  String get providerModelsFilterHint => 'Filtrer modeller';

  @override
  String get adaptersNoneReadyNote =>
      'Ingen av de katalogiserte kjører-CLI-ene ble funnet på denne maskinen. Installer én, og oppdater deretter.';

  @override
  String get adaptersFilterHint => 'Filtrer kjørere';

  @override
  String get adaptersLaunchGroup => 'Start';

  @override
  String get adaptersLaunchGroupDescription =>
      'Hva denne kjøreren får når en agent starter den. Sett disse før du installerer CLI-en om du vil.';

  @override
  String get adaptersEnvNone => 'Ingen satt';

  @override
  String adaptersEnvCount(int count) {
    return '$count satt';
  }

  @override
  String get adapterArgumentsDescription =>
      'Tilføyes kjørerens kommandolinje ved hver start.';

  @override
  String get defaultChatDescription =>
      'Kjører nye samtaler og enhver agent uten egen kjører.';

  @override
  String get shortTaskDescription =>
      'Kjører raskt bakgrunnsarbeid som titler og sammendrag. En mindre modell hører hjemme her.';

  @override
  String get settingsStateFailed => 'Mislyktes';

  @override
  String get providerAppsGroupServer => 'Opptre som serveren';

  @override
  String get providerAppsGroupServerDescription =>
      'For arbeidsområder som arver GitHub-appen til denne installasjonen. Et arbeidsområde med egen app eller PAT settes opp under Arbeidsområde → Generelt.';

  @override
  String get providerAppsGroupPrConversations => 'Pull request-samtaler';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      'Hvordan utviklere snakker med denne serveren på GitHub i arvede arbeidsområder. Et arbeidsområde med egen app har sin bot under Arbeidsområde → Generelt. Fungerer uten webhook eller offentlig URL — serveren poller.';

  @override
  String get providerAppBotLogin => 'Bot-innlogging';

  @override
  String get providerAppBotLoginEmpty =>
      'Test tilkoblingen for å løse bot-innloggingen.';

  @override
  String get providerAppAskOnGitHub => 'Spørre på GitHub';

  @override
  String get providerAppAskOnGitHubHint =>
      'Nevn bot-innloggingen over i en pull request-kommentar — [bot]-suffikset er valgfritt — for å be om en gjennomgang eller stille et spørsmål, svare i gjennomgangstrådene dens, eller legge til `ai-review`-etiketten for å be om en gjennomgang.';

  @override
  String get providerAppsGroupSignIn => 'Logge inn folk';

  @override
  String get providerAppsGroupSignInDescription =>
      'Lar hvert medlem koble til sin egen konto og få sin egen påloggingsinformasjon.';

  @override
  String get providerAppCapActsAsServer => 'Opptre som serveren';

  @override
  String get providerAppCapSignsIn => 'Logger inn folk';

  @override
  String get portLabel => 'Port';

  @override
  String get mcpNoTokenWarning =>
      'Uten et token kan alt som når denne porten, kalle hvert verktøy.';

  @override
  String get mcpBridgedToolsLabel => 'Verktøy';

  @override
  String get guardrailFamilyFiles => 'Filer';

  @override
  String get guardrailFamilyGit => 'Git og pull requests';

  @override
  String get guardrailFamilyMachine => 'Maskin og nettverk';

  @override
  String get guardrailFamilyControl => 'Hemmeligheter og arbeidsområde';

  @override
  String get guardrailScopeFieldLabel => 'Redigerer regler for';

  @override
  String get guardrailScopeFieldDescription =>
      'Et smalere omfang vinner over et bredere. Regler satt her gjelder i tillegg til det som arves.';

  @override
  String get guardrailSetHere => 'Satt her';

  @override
  String get guardrailClearAllHere => 'Fjern alle';

  @override
  String get sandboxingCardLabel => 'Sandkasse';

  @override
  String get sandboxingCardDescription =>
      'Om agentarbeid kjører isolert fra denne verten, og hva en isolert agent fortsatt kan nå.';

  @override
  String get sandboxBackendNoneActive => 'Vert, ingen isolering';

  @override
  String get sandboxSummaryHost => 'Vert';

  @override
  String get sandboxGroupIsolation => 'Isolering';

  @override
  String get sandboxGroupIsolationDescription =>
      'Hvor en agents prosesser og filskrivinger faktisk skjer.';

  @override
  String get sandboxBackendFieldDescription =>
      'Auto velger den sterkeste denne verten støtter. Fest én for å hindre at den endres under deg.';

  @override
  String get sandboxCapabilitiesDescription =>
      'Hullene slått gjennom grensen. Hver er noe en isolert agent fortsatt kan gjøre mot omverdenen.';

  @override
  String get sandboxSummaryInForce => 'I kraft';

  @override
  String get rigsInstallHintLabel => 'Hvordan installere den';

  @override
  String get rigsStarting => 'Starter';

  @override
  String get rigsResidentMemory => 'Resident minne';

  @override
  String get installedLabel => 'Installert';

  @override
  String get notInstalledLabel => 'Ikke installert';

  @override
  String ssoOtherKindUnsaved(String method) {
    return '$method har ulagrede endringer';
  }

  @override
  String get collapseComment => 'Skjul kommentar';

  @override
  String get expandComment => 'Utvid kommentar';

  @override
  String get suggestedChange => 'Foreslått endring';

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
  String get pendingReview => 'Ventende gjennomgang';

  @override
  String failedToResolveConversation(String error) {
    return 'Kunne ikke oppdatere samtalen: $error';
  }

  @override
  String get addSingleComment => 'Legg til enkeltkommentar';

  @override
  String get addToReview => 'Legg til i gjennomgang';

  @override
  String get startAReview => 'Start en gjennomgang';

  @override
  String get reviewNeedsABody =>
      'Skriv et sammendrag eller kø en innebygd kommentar først';

  @override
  String get reviewSubmitted => 'Gjennomgang sendt inn';

  @override
  String get finishYourReview => 'Fullfør gjennomgangen din';

  @override
  String get commentVerdict => 'Kommentar';

  @override
  String pendingCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ventende kommentarer',
      one: '1 ventende kommentar',
    );
    return '$_temp0';
  }

  @override
  String andNMore(int count) {
    return 'og $count til';
  }

  @override
  String get queuedCommentHint =>
      'Denne kommentaren går ut når du sender inn gjennomgangen.';

  @override
  String commentOnLinesRange(int start, int end) {
    return 'Linjer $start til $end';
  }

  @override
  String get claudeAccountsTitle => 'Claude Code-kontoer';

  @override
  String get claudeAccountsDescription =>
      'Hver konto er en separat Claude Code-innlogging. Kjøringer bruker kontoene knyttet under, i denne rekkefølgen.';

  @override
  String get claudeAccountsEmpty => 'Ingen kontoer ennå';

  @override
  String get claudeAccountAdd => 'Legg til konto';

  @override
  String get claudeAccountSignIn => 'Logg inn';

  @override
  String get claudeAccountSignInAgain => 'Logg inn på nytt';

  @override
  String get claudeAccountSignInHint =>
      'Kjør dette i en terminal på serveren. Det åpner en nettleser for å fullføre innloggingen, og skriver påloggingsinformasjonen inn i denne kontoens mappe.';

  @override
  String get claudeAccountSignedOut => 'Logget ut';

  @override
  String get claudeAccountExpired => 'Innlogging utløpt';

  @override
  String claudeAccountExpiredDetail(String when) {
    return 'Innloggingen utløp $when. Logg inn på nytt for å bruke denne kontoen.';
  }

  @override
  String get claudeAccountMakeDefault => 'Gjør til standard';

  @override
  String get claudeAccountDefault => 'Standard';

  @override
  String claudeAccountRemoveConfirm(String label) {
    return 'Fjerne $label?';
  }

  @override
  String get claudeAccountRemoveDetail =>
      'Dette logger kontoen ut og sletter mappen dens på serveren. Selve innloggingen påvirkes ikke.';

  @override
  String claudeAccountStatusUnknown(String error) {
    return 'Kunne ikke sjekke denne kontoen: $error';
  }

  @override
  String claudeAccountUsedPercent(String percent) {
    return '$percent % brukt';
  }

  @override
  String get accountPoolStrategy => 'Rotasjon';

  @override
  String get accountPoolPinned => 'Festet';

  @override
  String get accountPoolRoundRobin => 'Round robin';

  @override
  String get accountPoolSerial => 'Én om gangen';

  @override
  String get accountPoolPinnedHint =>
      'Start alltid på den første kontoen. De andre forblir som reserve hvis den feiler.';

  @override
  String get accountPoolRoundRobinHint =>
      'Fordel kjøringer på tvers av kontoene, og gå til den neste ved hver dispatch.';

  @override
  String get accountPoolSerialHint =>
      'Tøm den første kontoen før du rører den neste.';

  @override
  String get accountPoolMoveUp => 'Flytt opp';

  @override
  String get accountPoolMoveDown => 'Flytt ned';

  @override
  String get accountPoolUsingAll =>
      'Ingenting knyttet ennå — hver konto brukes, i denne rekkefølgen.';

  @override
  String get accountPoolInheriting => 'Arver arbeidsområdets kontoer.';

  @override
  String get accountPoolResetToWorkspace =>
      'Tilbakestill til arbeidsområdets kontoer';

  @override
  String accountPoolCoolingOff(String when) {
    return 'uten kvote til $when';
  }

  @override
  String get accountPoolSignedOut => 'logget ut';

  @override
  String get accountPoolExpired => 'innlogging utløpt';

  @override
  String accountPoolLoadFailed(String error) {
    return 'Kunne ikke laste rotasjonen: $error';
  }

  @override
  String get providerSignedInAccount => 'innlogget konto';

  @override
  String get agentAccountsTab => 'Kontoer';

  @override
  String get agentClaudeAccountsNoticeTitle => 'Flere Claude Code-kontoer';

  @override
  String agentClaudeAccountsNoticeBody(int count) {
    return 'Denne kjøreren logger inn som én av de $count Claude Code-kontoene på denne verten. Velg hvilken, eller roter mellom dem, i Kontoer-fanen.';
  }

  @override
  String get agentAccountsDescription =>
      'Hvilke kontoer denne agentens kjøringer bruker. Hver blokk starter med å arve arbeidsområdets valg.';

  @override
  String get agentAccountsNothingToRotate =>
      'Ingenting å rotere — koble til en andre konto eller nøkkel først.';

  @override
  String failedToPostReply(String error) {
    return 'Kunne ikke sende svaret: $error';
  }

  @override
  String commentOnLine(int line) {
    return 'Linje $line';
  }

  @override
  String get viewInDiff => 'Vis i diff';

  @override
  String get subscriptionUsagePreviousAccount => 'Forrige konto';

  @override
  String get subscriptionUsageNextAccount => 'Neste konto';

  @override
  String inReplyTo(String path) {
    return 'Som svar på $path';
  }

  @override
  String get subscriptionUsageNoneReported =>
      'Ingen bruk rapportert for denne kontoen.';

  @override
  String get subscriptionUsageCredits => 'Kreditter';

  @override
  String get reviewHubStaticRule => 'Statisk regel';

  @override
  String get reviewHubStarted => 'Gjennomgang startet';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return 'Funnet av en deterministisk regel ($rule) på en linje denne pull requesten legger til — ikke av en reviewer-agent.';
  }

  @override
  String get prReviewArtifactTab => 'PR-gjennomgang';

  @override
  String get prReviewRunning => 'Gjennomgår denne pull requesten…';

  @override
  String get prReviewStarting => 'Starter gjennomgang…';

  @override
  String get prReviewStartingBody =>
      'Forbereder denne pull requestens worktree. Reviewerne starter så snart den er klar.';

  @override
  String get prReviewFailed => 'Gjennomgang mislyktes.';

  @override
  String get prReviewRerunning => 'Gjennomgår på nytt…';

  @override
  String get prReviewNoOpenFindings => 'Ingen åpne funn';

  @override
  String prReviewOpenFindings(int count) {
    return '$count åpne funn';
  }

  @override
  String subscriptionUsageSpend(String used, String limit) {
    return '$used av $limit';
  }

  @override
  String reviewCommentsPosted(int posted, int skipped, int failed) {
    return 'Postet $posted kommentar(er) som boten. $skipped hoppet over (ingen filanker), $failed mislyktes.';
  }

  @override
  String reviewFindingsOutOfDiff(int count, String files) {
    return '$count funn rammer kode denne pull requesten ikke endrer ($files). GitHub godtar bare innebygde kommentarer på diffen.';
  }

  @override
  String get reviewRailReport => 'Rapport';

  @override
  String get reviewNoFindingsTitle => 'Ingen gjennomgangsfunn ennå';

  @override
  String get reviewNoFindingsHint => 'Funn vises her når agenter poster dem.';

  @override
  String reviewShowDismissed(int count) {
    return 'Vis $count avviste';
  }

  @override
  String reviewHideDismissed(int count) {
    return 'Skjul $count avviste';
  }

  @override
  String reviewDisagreementsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviewer-uenigheter oppdaget',
      one: '1 reviewer-uenighet oppdaget',
    );
    return '$_temp0';
  }

  @override
  String get reviewFilterKind => 'Type';

  @override
  String get reviewFilterStatus => 'Status';

  @override
  String get reviewKindBug => 'Feil';

  @override
  String get reviewKindSuggestion => 'Forslag';

  @override
  String get reviewKindRecommendation => 'Anbefaling';

  @override
  String get reviewKindQuestion => 'Spørsmål';

  @override
  String get reviewKindTicket => 'Sak';

  @override
  String get archiveSpace => 'Arkiver område';

  @override
  String get archivedSpaces => 'Arkiverte områder';

  @override
  String get archivedSpacesEmpty => 'Ingen arkiverte områder';

  @override
  String get restoreSpace => 'Gjenopprett';

  @override
  String archivedWhen(String time) {
    return 'Arkivert $time';
  }

  @override
  String get deleteSpacePermanently => 'Slett permanent';

  @override
  String get renameSpace => 'Gi område nytt navn';

  @override
  String get renameConversation => 'Gi samtale nytt navn';

  @override
  String get spaceActions => 'Handlinger for område';

  @override
  String get conversationActions => 'Handlinger for samtale';

  @override
  String get editSpaceRepos => 'Rediger arkiv';

  @override
  String get editSpaceReposTitle => 'Områdearkiv';

  @override
  String get editSpaceReposWarning =>
      'Å legge til et arkiv sjekker det ut i dette området; å fjerne ett sletter mappen.';

  @override
  String get agentSectionIdentity => 'Identitet';

  @override
  String get agentSectionRuntime => 'Kjøretid';

  @override
  String get agentSectionGuardrails => 'Rekkverk';

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
  String get teamsFilterHint => 'Filtrer team…';

  @override
  String get teamsSummaryWithLeader => 'Med en leder';

  @override
  String teamCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count team',
      one: '1 team',
      zero: 'Ingen team',
    );
    return '$_temp0';
  }

  @override
  String agentDeleteLongDescription(String name) {
    return 'Å slette $name fjerner profilen, ferdighetslenkene og kjøringshistorikken. Dette kan ikke angres.';
  }

  @override
  String get resetToDefault => 'Tilbakestill til standard';

  @override
  String get newAgent => 'Ny agent';

  @override
  String get newSkill => 'Ny ferdighet';

  @override
  String get zoomIn => 'Zoom inn';

  @override
  String get zoomOut => 'Zoom ut';

  @override
  String get resetZoom => 'Tilbakestill zoom';

  @override
  String get imageHostedOnGitHub => 'Bilde hostet på GitHub';

  @override
  String get imageOpenExternally => 'Bilde · åpne eksternt';

  @override
  String get memoryScopeAll => 'Alle omfang';

  @override
  String get memoryScopeWorkspace => 'Arbeidsområdeomfattende';

  @override
  String get memoryScopeFilterLabel => 'Filtrer etter omfang';

  @override
  String memoryScopeRepoTooltip(String repo) {
    return 'Avgrenset til $repo-arkivet';
  }

  @override
  String get toolScreenshot => 'Skjermbilde fra agenten';

  @override
  String get toolImageUnavailable => 'Bilde utilgjengelig';

  @override
  String toolImagesUnavailable(int count) {
    return '$count bilder utilgjengelige';
  }

  @override
  String get shakeUnavailable =>
      'Risting er ikke tilgjengelig på denne serveren';

  @override
  String get shakeNothing => 'Ingenting å riste ut — nylige turer er beskyttet';

  @override
  String shakeDone(int tokens) {
    return 'Frigjorde omtrent $tokens tokens';
  }

  @override
  String get compactionDivider => 'Komprimert';

  @override
  String compactionDividerCount(int count) {
    return 'Komprimert · $count meldinger foldet';
  }

  @override
  String get composerDropToAttach => 'Slipp for å legge ved';

  @override
  String get attachmentUnavailable => 'Vedlegg utilgjengelig';

  @override
  String get attachmentUnavailableDetail =>
      'Dette vedlegget holdes ikke lenger i minnet. Legg det ved på nytt for å forhåndsvise det.';

  @override
  String get attachmentPreviewFailed => 'Kunne ikke åpne denne filen';

  @override
  String get attachmentPreviewUnsupported =>
      'Ingen forhåndsvisning for denne filtypen';

  @override
  String get attachmentTooLargeToPreview => 'For stor til å forhåndsvise';

  @override
  String get attachmentOpenExternally => 'Åpne i standardapp';

  @override
  String get asideUnavailable =>
      'Sett en engangsmodell i arbeidsområdeinnstillingene for å bruke dette';

  @override
  String get asideEmpty => 'Ingenting å jobbe ut fra ennå';

  @override
  String get asideFailed => 'Kunne ikke få et svar';

  @override
  String get handoffTitle => 'Overlevering';

  @override
  String get asideTitle => 'Sidespørsmål';

  @override
  String get attachFilesOrDrop => 'Legg ved filer — eller slipp dem her';

  @override
  String get guidedGoalTitle => 'Skjerp objektivet';

  @override
  String get guidedGoalIntro =>
      'En agent som jobber uten tilsyn, må vite nøyaktig når den er ferdig. Noen spørsmål først.';

  @override
  String get guidedGoalAnswerHint => 'Svaret ditt';

  @override
  String get guidedGoalNext => 'Neste';

  @override
  String get guidedGoalStart => 'Start målet';

  @override
  String get guidedGoalSkip => 'Hopp over og kjør som skrevet';

  @override
  String guidedGoalStillMissing(String items) {
    return 'Fortsatt uspesifisert: $items';
  }

  @override
  String get conversationTreeTitle => 'Samtaletre';

  @override
  String conversationTreeBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grener',
      one: '1 gren',
    );
    return '$_temp0';
  }

  @override
  String get conversationTreeSwitch => 'Fortsett herfra';

  @override
  String get conversationTreeFork => 'Forgren til en ny samtale';

  @override
  String get conversationTreeCurrent => 'På denne grenen';

  @override
  String get conversationTreeEmpty => 'Ingenting her ennå';

  @override
  String get conversationTreeForked => 'Forgrenet til en ny samtale';

  @override
  String get conversationTreeSwitched => 'Fortsetter nå fra den meldingen';

  @override
  String exportSaved(String path) {
    return 'Lagret til $path';
  }

  @override
  String get exportFailed => 'Kunne ikke skrive eksporten';

  @override
  String get contextCommandNoAgent =>
      'Ingen agent i denne samtalen, så det er ingen kontekstvindu å åpne';

  @override
  String contextCommandNoSuchAgent(String name, String names) {
    return 'Ingen agent med navnet «$name» i denne samtalen. Prøv: $names';
  }

  @override
  String get dumpCopied => 'Transkript kopiert til utklippstavlen';

  @override
  String get messageQueueHint =>
      'Fortsett å skrive for å kølegge oppfølgingsendringer';

  @override
  String get steerNow => 'Styr';

  @override
  String get steeringQueueLabel => 'Kølagte styringsmeldinger';

  @override
  String get steeringDeliverUnavailable =>
      'Ingen kjørende agent kan ta det akkurat nå — det forblir i kø.';

  @override
  String get reorderSteeringCard => 'Endre rekkefølge på kølagt melding';

  @override
  String get editSteeringCard => 'Rediger kølagt melding';

  @override
  String get deleteSteeringCard => 'Slett kølagt melding';

  @override
  String get steeringBadge => 'Styrt';

  @override
  String get settingsSandboxLabel => 'Sandkasse';

  @override
  String get sandboxExecGrantsTitle => 'Kjørbare tillatelser';

  @override
  String get sandboxExecGrantsSubtitle =>
      'Programmer agenter kan kjøre fra arbeidskopien av arkivene dine. Hver oppføring ble godkjent av deg da sandkassen spurte.';

  @override
  String get sandboxExecGrantsEmpty =>
      'Ingen beslutninger registrert ennå. Du blir spurt første gang en agent trenger å kjøre et program fra arbeidskopien.';

  @override
  String get sandboxExecGrantRevoke => 'Tilbakekall';

  @override
  String get sandboxExecGrantAllowed => 'Tillatt';

  @override
  String get sandboxExecGrantBlocked => 'Blokkert';

  @override
  String get sandboxExecGrantRevokeConfirmTitle =>
      'Tilbakekalle denne beslutningen?';

  @override
  String get sandboxExecGrantRevokeConfirmBody =>
      'Du blir spurt igjen neste gang en agent trenger å kjøre et program fra denne kopien.';

  @override
  String get repoScriptsTest => 'Test';

  @override
  String get repoScriptsTestTooltip =>
      'Kjør dette utkastet i en engangsklon av arkivet';

  @override
  String get repoScriptsRunKindTest => 'Test';

  @override
  String get demoBadgeLabel => 'Demo';

  @override
  String get demoFilePickerTitle => 'Demofiler';

  @override
  String get demoFilePickerBody =>
      'Demoen later som opplastinger: velg hvilken som helst av disse, så legges den ved meldingen uten å røre en disk.';

  @override
  String get demoFilePickerAttach => 'Legg ved';

  @override
  String get demoReadOnlySave => 'Skrivebeskyttet i demoen';

  @override
  String get demoBadgeTooltip =>
      'Du utforsker en demo. Dataene er fiktive, og agentene er skriptet.';

  @override
  String get demoFirstRunTitle => 'Du er i en live demo';

  @override
  String demoFirstRunBody(int minutes) {
    return 'Dette er den ekte appen som kjører på ekte kode — bare dataene er oppdiktet. Agenter strømmer ekte kjøringer fra et skript, så ingenting når en modell og ingenting kjører på en maskin. Arbeidsområdet ditt er bare ditt og forsvinner etter $minutes minutter.';
  }

  @override
  String get demoFirstRunDismiss => 'Skjønner';

  @override
  String get demoTourTitle => 'Hvor du skal se først';

  @override
  String get demoTourSubtitle =>
      'Fire steder som viser hva appen faktisk gjør.';

  @override
  String get demoTourSkip => 'Hopp over';

  @override
  String get demoTourStarRepo => 'Stjerne på GitHub';

  @override
  String get demoTourOpen => 'Åpne';

  @override
  String get demoTourSpacesTitle => 'Snakk med en agent';

  @override
  String get demoTourSpacesBody =>
      'Send en melding i et område og se en kjøring strømme inn — tenkning, verktøykall og kostnad, nøyaktig slik en ekte kjøring vises.';

  @override
  String get demoTourReviewTitle => 'Gjennomgå en pull request';

  @override
  String get demoTourReviewBody =>
      'Åpne #412. Legg igjen en innebygd kommentar eller send inn en gjennomgang; ordene dine lander i tråden og blir der.';

  @override
  String get demoTourTicketsTitle => 'Følg arbeidet';

  @override
  String get demoTourTicketsBody =>
      'Saker, gjøremål og planer er knyttet til de samme samtalene agentene har.';

  @override
  String get demoTourInboxTitle => 'Se hele operasjonen';

  @override
  String get demoTourInboxBody =>
      'Hvert varsel fra hver søyle lander i én innboks — gjennomganger, saker, kjøringer og møter.';

  @override
  String get demoUnavailableTitle => 'Ikke tilgjengelig i demoen';

  @override
  String get demoUnavailableTerminal =>
      'En terminal kjører et ekte skall på serververten. Demoen har ingen kjøreflate i det hele tatt — det er det som gjør den trygg å åpne for offentligheten.';

  @override
  String get demoUnavailableRig =>
      'Et isolert miljø er en engangs virtuell maskin en agent styrer. Demoen starter ingen: et offentlig endepunkt som kan starte en VM, er ikke en demo.';

  @override
  String get demoUnavailableEditor =>
      'Nettleserredigereren kjører en code-server-prosess mot en ekte sjekk-ut. Demoen har verken.';

  @override
  String get demoUnavailableFeeds =>
      'Demoen leser ekte strømmer, men abonnementslisten er fast. Å legge til eller fjerne én er deaktivert her.';

  @override
  String get demoUnavailableForge =>
      'Demoen holder ingen påloggingsinformasjon og kontakter aldri GitHub, GitLab eller Linear. Pull requestene er fiksturer, og kommentarene dine på dem lagres lokalt.';

  @override
  String get demoUnavailableModels =>
      'Demoen kaller ingen modell. Agentkjøringer er skriptet avspilling, derfor koster de ingenting og når ingen leverandør.';

  @override
  String get demoUnavailableMcp =>
      'MCP-verktøyflaten er ikke montert på demoen, så ingen ekstern klient kan koble til den.';

  @override
  String get demoUnavailableRepos =>
      'Demoen sjekker ikke ut kode og kjører ingen git. Arkivet du ser er en fikstur bak pull requestene.';

  @override
  String get demoUnavailableSkills =>
      'Å installere en ferdighet laster ned og skanner kode. Demoen henter ingenting.';

  @override
  String get demoUnavailableSso =>
      'Enkel pålogging er serverkonfigurasjon. Demoen logger deg inn som en midlertidig gjest i stedet.';

  @override
  String get demoUnavailableAudio =>
      'Opptak og diktering trenger lydfangst og en talemodell på verten. Demoen leverer ingen av delene, så møtene er transkripter uten avspilling.';

  @override
  String get demoUnavailableServerAdmin =>
      'Dette er serveradministrasjon. Demoen gir hver besøkende sitt eget engangsarbeidsområde og ingenting utover det.';

  @override
  String get demoUnavailablePipelines =>
      'Pipelines kan ikke kjøre her. En besøkende som kan skrive et bash-steg og starte det — manuelt eller via en hendelsestrigger — kjører kode på denne verten.';

  @override
  String get settingsBackupRestore => 'Sikkerhetskopi og gjenoppretting';

  @override
  String get settingsBackupRestoreDescription =>
      'Øyeblikksbilder av hver database på denne serveren, pluss eksport, import og sletting for ett arbeidsområde.';

  @override
  String get backupSnapshotsLabel => 'Installasjonsøyeblikksbilder';

  @override
  String get backupSnapshotsExplainer =>
      'Et øyeblikksbilde kopierer hver database til en tidsstemplet mappe på serververten. Å gjenopprette en hel installasjon betyr å kopiere den mappen tilbake med serveren stoppet; ett arbeidsområde kan gjenopprettes herfra.';

  @override
  String get backupNowAction => 'Sikkerhetskopier nå';

  @override
  String backupSnapshotWritten(String path) {
    return 'Øyeblikksbilde skrevet til $path';
  }

  @override
  String get backupNoSnapshots =>
      'Ingen øyeblikksbilder ennå. Ett tas bare når du ber om det — ingenting er planlagt.';

  @override
  String get backupSnapshotComplete => 'Fullstendig';

  @override
  String get backupSnapshotIncomplete => 'Ufullstendig';

  @override
  String get backupSnapshotIncompleteNote =>
      'Manifestet mangler eller navngir filer som ikke er der, så dette øyeblikksbildet kan ikke gjenopprette hele installasjonen. Arbeidsområdefilene det har, kan fortsatt tas i bruk én og én.';

  @override
  String backupSnapshotWorkspaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arbeidsområder',
      one: '1 arbeidsområde',
      zero: 'Ingen arbeidsområder',
    );
    return '$_temp0';
  }

  @override
  String backupSnapshotSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arbeidsområder ikke fanget',
      one: '1 arbeidsområde ikke fanget',
    );
    return '$_temp0';
  }

  @override
  String get backupServerPathLabel => 'Sti på serveren';

  @override
  String get backupRestoreAction => 'Gjenopprett';

  @override
  String get backupRestoreTitle => 'Gjenopprett arbeidsområde';

  @override
  String backupRestoreBody(String name) {
    return 'Dette erstatter alt i $name med kopien holdt i dette øyeblikksbildet. Det arbeidsområdet har gjort siden øyeblikksbildet ble tatt, går tapt, og det kan ikke angres.';
  }

  @override
  String backupRestoreDone(String name) {
    return 'Gjenopprettet $name fra øyeblikksbildet.';
  }

  @override
  String get backupWorkspaceUnknown => 'Ikke lenger på denne serveren';

  @override
  String get backupWorkspaceDataLabel => 'Arbeidsområdedata';

  @override
  String get backupWorkspaceDataExplainer =>
      'Ett arbeidsområde er én databasefil, så å eksportere det kopierer den filen i stedet for å dumpe tabell for tabell. Import erstatter alt i mål-arbeidsområdet med filen du navngir.';

  @override
  String get backupExportAction => 'Eksporter';

  @override
  String backupExportDone(String path) {
    return 'Eksportert til $path';
  }

  @override
  String get backupExportedFileLabel => 'Eksportert fil på serveren';

  @override
  String get backupImportAction => 'Importer';

  @override
  String backupImportTitle(String name) {
    return 'Importer inn i $name';
  }

  @override
  String backupImportBody(String name) {
    return 'Dette erstatter alt i $name med innholdet i filen. Det arbeidsområdet holder nå, går tapt, og det kan ikke angres.';
  }

  @override
  String get backupImportSourceLabel => 'Arbeidsområdets databasefil';

  @override
  String get backupImportSourceDescription =>
      'En .db-fil serveren kan lese. Stier løses på serververten, ikke på denne enheten.';

  @override
  String backupImportDone(String name) {
    return 'Importert inn i $name.';
  }

  @override
  String backupDeleteBody(String name) {
    return '$name forsvinner fra hver liste og hvert oppslag. Databasefilen blir på disken, sikkerhetskopier inkluderer den fortsatt, og ingenting tar tilbake plassen automatisk.';
  }

  @override
  String get backupExportDescription =>
      'Skriv en kopi på serveren, eller last ned én til denne enheten.';

  @override
  String get backupExportOnServerAction => 'Lagre på server';

  @override
  String get backupDownloadAction => 'Last ned';

  @override
  String backupDownloadSaved(String path) {
    return 'Lagret til $path';
  }

  @override
  String get backupDownloadInBrowser => 'Nettleseren din laster den ned.';

  @override
  String get backupRestoreFromDeviceLabel => 'Gjenopprett fra denne enheten';

  @override
  String get backupRestoreFromDeviceDescription =>
      'Velg en arbeidsområde-databasefil her, så laster Control Center den opp til serveren. Dette er den som virker når serveren ikke er denne maskinen.';

  @override
  String get backupUploadAction => 'Velg en fil og last opp';

  @override
  String get backupTransferUnavailable =>
      'Denne tilkoblingen når serveren via et relé, som ikke bærer filoverføringer. Koble til serveren direkte for å laste ned eller opp en sikkerhetskopi.';

  @override
  String get backupTransferForbidden =>
      'Serveren nektet. Å laste ned et arbeidsområde krever admin-rollen, å gjenopprette ett krever eier, og et helt øyeblikksbilde krever installasjonens operatør.';

  @override
  String get backupTransferUnsupported =>
      'Denne serveren har ingen sikkerhetskopiflate.';

  @override
  String get backupTransferTooLarge => 'Filen er større enn serveren godtar.';

  @override
  String get credentialGateWaitingTitle => 'Venter på påloggingsinformasjon';

  @override
  String credentialGateHarnessTitle(String provider) {
    return '$provider har ingen påloggingsinformasjon';
  }

  @override
  String get credentialGateSignedOutTitle => 'Claude Code er logget ut';

  @override
  String get credentialGateExpiredTitle =>
      'Claude Code-innloggingen din har utløpt';

  @override
  String get credentialGatePlanSpentTitle => 'Claude Code-plangrense nådd';

  @override
  String credentialGateWaitingAgent(String agent) {
    return '$agent venter på å fortsette.';
  }

  @override
  String get credentialGateWaitingRun => 'En kjøring venter på å fortsette.';

  @override
  String get credentialGateWatching =>
      'Ser etter fiksen — kjøringen fortsetter av seg selv.';

  @override
  String credentialGateFreesUpAt(String time) {
    return 'Frigjøres $time';
  }

  @override
  String credentialGateGivesUpAt(String time) {
    return 'Kjøringen gir opp $time';
  }

  @override
  String get credentialGateCheckAgain => 'Sjekk på nytt';

  @override
  String get credentialGateCancelRun => 'Avbryt kjøring';

  @override
  String get credentialGateAccountsTried => 'Kontoer prøvd';

  @override
  String get credentialGateClaudeSignInHint =>
      'Logg inn fra Innstillinger → Adaptere → Claude Code, eller kjør innloggingskommandoen i en terminal. Kjøringen tar den opp av seg selv.';

  @override
  String get credentialGateOpenSettings => 'Åpne innstillinger';

  @override
  String get selectModel => 'Velg modell';

  @override
  String get allModels => 'Alle modeller';

  @override
  String get noModelsMatchSearch => 'Ingen modeller samsvarer med søket';

  @override
  String useCustomModelId(String id) {
    return 'Bruk «$id»';
  }

  @override
  String get modelFree => 'Gratis';

  @override
  String modelOutputTokens(String tokens) {
    return '$tokens utdata';
  }

  @override
  String modelPricePerMTokens(String input, String output) {
    return '$input inndata / $output utdata per 1M tokener';
  }

  @override
  String modelEffortLevels(String levels) {
    return 'Resonneringsinnsats: $levels';
  }

  @override
  String get modelSupportsReasoning => 'Støtter resonneringsinnsats';

  @override
  String get profileDeliveryMetrics => 'Leveringsmålinger';

  @override
  String profileMetricsSample(int count) {
    return 'Analyserte PR-er: $count';
  }

  @override
  String get profileMergeRate => 'Flettegrad';

  @override
  String get profileReviewCoverage => 'Gjennomgangsdekning';

  @override
  String get profilePrSize => 'PR-størrelse';

  @override
  String get profileTimeToMerge => 'Tid til fletting';

  @override
  String get profileMergeTimeTrend => 'Trend for flettetid';

  @override
  String get profileWeeklyMedian => 'Ukentlig median, logaritmisk skala';

  @override
  String get profilePrOpeningPattern => 'Ukedag × time, lokal tid';

  @override
  String get profileFirstReview => 'Tid til første gjennomgang';

  @override
  String get profileMetricsTruncated =>
      'Persentilene bruker et begrenset utvalg av de tilgjengelige pull-forespørslene.';

  @override
  String profileLinesChanged(String count) {
    return '$count linjer';
  }

  @override
  String profileDurationMinutes(int count) {
    return '$count min';
  }

  @override
  String profileDurationHours(int count) {
    return '$count t';
  }

  @override
  String profileDurationDaysHours(int days, int hours) {
    return '${days}d ${hours}t';
  }

  @override
  String profilePercentiles(String median, String p90) {
    return 'p50 $median · p90 $p90';
  }

  @override
  String profileTeamMembers(int count) {
    return 'Medlemmer: $count';
  }

  @override
  String noPrsByTeamInWorkspace(String team) {
    return 'Ingen pull requests fra $team i dette arbeidsområdet';
  }

  @override
  String get profilePrStateFilterLabel => 'Filtrer pull requests etter status';

  @override
  String get noProfilePrsMatchSearchHint =>
      'Prøv en annen tittel eller et annet pull request-nummer';

  @override
  String get rigNetworkUnrestricted => 'Nettverk uten begrensninger';

  @override
  String get rigNetworkAllowAllHosts => 'Tillat alle verter';

  @override
  String get rigBrowserPermissionsTitle => 'Nettstedstillatelser';

  @override
  String get rigBrowserPermissionsTooltip => 'Nettstedstillatelser og nettverk';

  @override
  String get rigBrowserPermissionEmpty =>
      'Ingen nettsteder har bedt om tillatelse ennå';

  @override
  String rigBrowserPermissionPrompt(String origin, String permission) {
    return '$origin vil bruke $permission';
  }

  @override
  String get rigBrowserPermissionBlock => 'Blokker';

  @override
  String get rigBrowserPermissionCamera => 'Kamera';

  @override
  String get rigBrowserPermissionMicrophone => 'Mikrofon';

  @override
  String get rigBrowserPermissionNotifications => 'Varsler';

  @override
  String get rigBrowserPermissionGeolocation => 'Plassering';

  @override
  String get rigBrowserPermissionPersistentStorage => 'Vedvarende lagring';

  @override
  String get rigBrowserPermissionClipboard => 'Utklippstavle';

  @override
  String get rigBrowserPermissionDisplayCapture => 'Skjermopptak';

  @override
  String get rigBrowserPermissionMidi => 'MIDI';

  @override
  String get rigNetworkBypassTitle => 'Vil du tillate alle nettverksverter?';

  @override
  String get rigNetworkBypassBody =>
      'Dette starter det isolerte miljøet på nytt og forkaster arbeid som ikke er sjekket inn. Gjesten kan deretter nå alle nettverksverter frem til den lukkes.';

  @override
  String get rigNetworkRestartUnrestricted =>
      'Start på nytt uten begrensninger';

  @override
  String get rigNetworkUnrestrictedBody =>
      'Dette isolerte miljøet kan nå alle nettverksverter. Lukk det og åpne et nytt for å gjenopprette standardbegrensningene.';

  @override
  String get rigNetworkAlreadyUnrestrictedBody =>
      'Denne Android-emulatoren administrerer allerede sitt eget nettverk, så Control Center kan ikke håndheve en liste over tillatte verter. Ingen omstart er nødvendig.';

  @override
  String get rigClipboardPermissionHostToRigTitle =>
      'Lim inn utklippstavlen i dette miljøet?';

  @override
  String get rigClipboardPermissionHostToRigBody =>
      'Control Center leser utklippstavlen på enheten din og sender innholdet til miljøet. Innholdet på utklippstavlen kan inneholde passord eller andre hemmeligheter.';

  @override
  String get rigClipboardPermissionRigToHostTitle =>
      'Kopiere utklippstavlen ut av dette miljøet?';

  @override
  String get rigClipboardPermissionRigToHostBody =>
      'Control Center leser utklippstavlen i miljøet og erstatter utklippstavlen på enheten din med innholdet. Behandle innhold fra miljøet som ikke klarert.';

  @override
  String get rigClipboardAllowTenMinutes => 'Tillat i 10 minutter';

  @override
  String get rigClipboardAlwaysAllow => 'Tillat alltid';

  @override
  String get rigClipboardSettingsTitle => 'Tilgang til utklippstavle';

  @override
  String get rigClipboardSettingsHint =>
      'Velg hvilke utklippstavleoverføringer som kan kjøres uten å spørre. Midlertidige tillatelser utløper etter 10 minutter.';

  @override
  String get rigClipboardAlwaysPasteTitle =>
      'Tillat alltid innliming i miljøer';

  @override
  String get rigClipboardAlwaysPasteDescription =>
      'Send utklippstavlen på denne enheten til et hvilket som helst miljø uten å spørre.';

  @override
  String get rigClipboardAlwaysCopyTitle =>
      'Tillat alltid kopiering fra miljøer';

  @override
  String get rigClipboardAlwaysCopyDescription =>
      'Legg innhold fra utklippstavlen i et hvilket som helst miljø på denne enheten uten å spørre.';

  @override
  String get workspaceGitHubIdentity => 'GitHub-identitet';

  @override
  String get workspaceGitHubIdentityDescription =>
      'Hvordan bakgrunnsarbeid mot GitHub autentiserer i dette arbeidsområdet. Arv installasjonens App, bruk en annen App, eller bare et personlig tilgangstoken.';

  @override
  String get workspaceGitHubModeInherit =>
      'Bruk GitHub-appen til denne installasjonen';

  @override
  String get workspaceGitHubModeApp => 'Bruk en annen GitHub-app';

  @override
  String get workspaceGitHubModePat => 'Bare personlig tilgangstoken';

  @override
  String get workspaceGitHubInheritHint =>
      'Bruker GitHub-appen under Server → Leverandørapper.';

  @override
  String get workspaceGitHubAppHint =>
      'Bot- og polling-identitet for dette arbeidsområdet. Medlemmer logger inn under Deg via denne appen.';

  @override
  String get workspaceGitHubPatLabel => 'Bakgrunnstoken';

  @override
  String get workspaceGitHubPatDescription =>
      'Til polling og agenter i dette arbeidsområdet. Ikke et medlems profiltoken.';

  @override
  String get workspaceGitHubHasPat => 'Et bakgrunnstoken er lagret.';

  @override
  String get workspaceGitHubNoPat => 'Ingen bakgrunnstoken er lagret.';

  @override
  String get profileOverlayHint =>
      'Disse feltene er deg i dette arbeidsområdet. Tomme felt arver kontonavn og e-post. Å bytte arbeidsområde bytter dette overlegget.';

  @override
  String get forgeConnectionsThisWorkspace =>
      'Logg inn eller lim inn et token for dette arbeidsområdet.';
}
