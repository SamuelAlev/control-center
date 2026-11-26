// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String steeringForceSendFailed(String error) {
    return 'Nu s-a putut trimite acum: $error';
  }

  @override
  String get questionAnswerNotDelivered =>
      'Răspunsul tău nu a fost livrat. Poate a primit deja un răspuns sau agentul nu mai așteaptă.';

  @override
  String get succeeded => 'Reușit';

  @override
  String agentRunRetryLabel(int number, String time) {
    return 'Reîncercare #$number · $time';
  }

  @override
  String agentRunStarting(String time) {
    return 'Se pornește · $time';
  }

  @override
  String get agentActivityFollowingLive => 'Urmărești activitatea live';

  @override
  String get agentActivityJumpToLatest => 'Sari la cele mai recente';

  @override
  String get agentActivityLoadFailed =>
      'Nu s-a putut încărca activitatea acestei rulări';

  @override
  String get agentActivityNotRecorded =>
      'Nu s-a înregistrat nicio activitate pentru această rulare';

  @override
  String get agentActivityNotRecordedHint =>
      'Rulările terminate înainte de activarea capturii de activitate nu au o cronologie.';

  @override
  String get agentActivityRunUnavailable =>
      'Această rulare nu mai este disponibilă';

  @override
  String agentActivitySubagentOf(String agent) {
    return 'Subagent al $agent';
  }

  @override
  String get agentActivityUnsupported =>
      'Captura de activitate nu este disponibilă pe serverul conectat';

  @override
  String get agentActivityUnsupportedHint =>
      'Repornește aplicația ca să preia cea mai recentă versiune a serverului.';

  @override
  String get agentActivityWaiting => 'Se așteaptă activitatea…';

  @override
  String get created => 'Creat';

  @override
  String get dictationStart => 'Pornește dictarea';

  @override
  String get dictationListening => 'Se ascultă…';

  @override
  String get dictationUnavailable =>
      'Dictarea are nevoie de un model vocal pe gazda serverului. Configurează-l în setările de voce.';

  @override
  String get dictationFailedToStart => 'Nu s-a putut porni dictarea';

  @override
  String get dictationHoldToTalkTitle => 'Ține apăsat pentru a vorbi';

  @override
  String get dictationHoldToTalkDescription =>
      'Ține apăsat butonul de microfon sau scurtătura pentru a dicta și eliberează pentru a opri. Când opțiunea e dezactivată, apasă o dată pentru a porni și din nou pentru a opri.';

  @override
  String get focusConversation => 'Focalizează conversația';

  @override
  String get ideAgentActivity => 'Activitate agent';

  @override
  String get keybindingPushToTalk => 'Apasă pentru a vorbi';

  @override
  String get agentPermissions => 'Permisiuni agent';

  @override
  String get agentPermissionsSettingsDescription =>
      'Decide ce pot face agenții singuri, ce trebuie să întrebe întâi și ce nu pot face niciodată — pe spațiu de lucru, agent sau spațiu.';

  @override
  String get agentPermissionsMatrixDescription =>
      'Setează o decizie pentru fiecare tip de efect. Regulile se suprapun: spațiul prevalează asupra agentului, agentul asupra spațiului de lucru, spațiul de lucru asupra presetării de mod. Cea mai specifică regulă câștigă.';

  @override
  String get guardrailLoading => 'Se încarcă regulile…';

  @override
  String get guardrailRulesLoadFailed =>
      'Nu s-au putut încărca regulile de permisiuni.';

  @override
  String get guardrailScopeWorkspace => 'Spațiu de lucru';

  @override
  String get guardrailScopeAgent => 'Agent';

  @override
  String get guardrailScopeSpace => 'Spațiu';

  @override
  String get guardrailSelectAgent => 'Selectează un agent';

  @override
  String get guardrailSelectSpace => 'Selectează un spațiu';

  @override
  String get guardrailNoAgents =>
      'Nu există încă agenți în acest spațiu de lucru.';

  @override
  String get guardrailNoSpaces =>
      'Nu există încă spații în acest spațiu de lucru.';

  @override
  String get guardrailClassFileDelete => 'Șterge un fișier';

  @override
  String get guardrailClassFileWriteOutsideWorktree =>
      'Scrie în afara worktree-ului';

  @override
  String get guardrailClassGitCommit => 'Creează un commit';

  @override
  String get guardrailClassGitPush => 'Push către un remote';

  @override
  String get guardrailClassPrCreate => 'Deschide un pull request';

  @override
  String get guardrailClassPrPublish =>
      'Actualizează sau unește un pull request';

  @override
  String get guardrailClassVendorSyncWrite => 'Scrie într-un tracker extern';

  @override
  String get guardrailClassNetworkEgress => 'Accesează rețeaua';

  @override
  String get guardrailClassSecretAccess => 'Citește un secret';

  @override
  String get guardrailClassPackageInstall => 'Instalează un pachet';

  @override
  String get guardrailClassProcessSpawn => 'Rulează un proces';

  @override
  String get guardrailClassWorkspaceMutation =>
      'Modifică structura spațiului de lucru';

  @override
  String get guardrailClassEnclosureControl =>
      'Conduce un mediu izolat (stație)';

  @override
  String get navRigs => 'Stații';

  @override
  String get rigsUnsupportedServer =>
      'Acest server nu poate găzdui suprafețe rig. Verificați cerințele pentru gazdă ale computerului pe care doriți să îl utilizați.';

  @override
  String get rigSurfaceComputer => 'Computer';

  @override
  String get rigSurfaceBrowser => 'Browser';

  @override
  String get rigSurfaceAndroid => 'Android';

  @override
  String get rigSurfaceIosSimulator => 'Simulator iOS';

  @override
  String get rigSurfaceAppWindow => 'Fereastra aplicației';

  @override
  String rigSurfaceBrowserEngine(String engine) {
    return '$engine';
  }

  @override
  String rigBrowserEngineHint(String engine) {
    return 'Un $engine de unică folosință, izolat de mașina ta. Deschide un alt motor ca să compari aceeași pagină una lângă alta.';
  }

  @override
  String get rigPhaseReady => 'Pregătit';

  @override
  String get rigPhaseStarting => 'Se pornește';

  @override
  String get rigPhaseParked => 'Parcat';

  @override
  String get rigPhaseClosing => 'Se închide';

  @override
  String get rigPhaseClosed => 'Închis';

  @override
  String get rigPhaseFailed => 'Eșuat';

  @override
  String get rigPhaseUnknown => 'Necunoscut';

  @override
  String get rigNotAccelerated => 'Emulat';

  @override
  String get rigAudioListen => 'Ascultă mașina';

  @override
  String get rigAudioMute => 'Dezactivează sunetul mașinii';

  @override
  String get rigYouHaveControl => 'Ai controlul';

  @override
  String get rigBackendAvailable => 'Disponibil';

  @override
  String get rigBackendUnavailable => 'Indisponibil';

  @override
  String get rigEgressNotEnforced =>
      'Rețeaua nu este izolată pe acest backend — își gestionează propria conectivitate.';

  @override
  String get rigStartMachine => 'Pornește mașina';

  @override
  String get rigStartHint =>
      'Pornește o VM de unică folosință partajată de tine și de agenții tăi pentru această conversație. Este distrusă la închidere și nimic din ea nu atinge computerul tău.';

  @override
  String get rigStartAndroidHint =>
      'Se conectează la un emulator Android care rulează deja pe server. Accesul la rețea nu este izolat.';

  @override
  String get rigStartIosHint =>
      'Creează un simulator iOS temporar pe un server macOS. Acesta este șters când mediul de testare se închide; accesul la rețea nu este izolat.';

  @override
  String get rigTechnicalDetails => 'Detalii tehnice';

  @override
  String get rigStopMachine => 'Oprește mașina';

  @override
  String get rigHomeButton => 'Ecran principal';

  @override
  String get rigRotateClockwise => 'Rotește în sens orar';

  @override
  String get rigRotateCounterclockwise => 'Rotește în sens antiorar';

  @override
  String get rigTakeScreenshot => 'Fă o captură de ecran';

  @override
  String get rigScreenshotSaved => 'Captura de ecran a fost salvată';

  @override
  String rigScreenshotSaveFailed(String error) {
    return 'Nu s-a putut salva captura de ecran: $error';
  }

  @override
  String get rigSurfaceUnavailable =>
      'Acest server nu poate găzdui acest tip de mașină.';

  @override
  String get rigTabNeedsConversation =>
      'Deschide mai întâi o conversație — o mașină aparține uneia, ca tu și agenții tăi să priviți același ecran.';

  @override
  String get ideMenuSectionTools => 'Instrumente';

  @override
  String get ideMenuSectionMachines => 'Mașini';

  @override
  String get ideMenuSectionReopen => 'Redeschide';

  @override
  String get ideMenuSearchHint => 'Caută';

  @override
  String get ideMenuNoMatches => 'Nicio potrivire';

  @override
  String get rigMenuComputer => 'Computer';

  @override
  String get rigMenuBrowser => 'Browser';

  @override
  String get rigMenuAndroid => 'Android';

  @override
  String get rigMenuIosSimulator => 'Simulator iOS';

  @override
  String rigLabelNumbered(String label, String suffix) {
    return '$label $suffix';
  }

  @override
  String ideCloseKeepTitle(String name) {
    return 'Închizi $name?';
  }

  @override
  String get ideCloseKeepBodyMachine =>
      'Mașina continuă să ruleze în fundal — o poți redeschide oricând din bara laterală. Oprește-o ca să eliberezi memoria acum.';

  @override
  String get ideCloseKeepBodyShell =>
      'Comanda continuă să ruleze în fundal — poți redeschide shell-ul oricând din bara laterală. Termină-l ca să oprești ce face acum.';

  @override
  String get ideCloseKeepBodyAgent =>
      'Agentul continuă să lucreze în fundal — poți redeschide conversația oricând din bara laterală. Oprește-l ca să termini rularea acum.';

  @override
  String get ideCloseKeepRunning => 'Continuă rularea';

  @override
  String get ideCloseShutDownMachine => 'Oprește';

  @override
  String get ideCloseEndShell => 'Termină shell-ul';

  @override
  String get ideCloseStopAgent => 'Oprește agentul';

  @override
  String get rigsSettingsSubtitle =>
      'Ce poate porni acest server, imaginile de bază de care are nevoie și mașinile care rulează acum';

  @override
  String get rigsCapabilitiesTitle => 'Acest server';

  @override
  String get rigInstallIosAutomation => 'Instalează puntea de automatizare iOS';

  @override
  String get rigInstallingIosAutomation =>
      'Se instalează puntea de automatizare iOS…';

  @override
  String get rigIosAutomationInstalled =>
      'Puntea de automatizare iOS a fost instalată';

  @override
  String get rigsImagesTitle => 'Imagini de bază';

  @override
  String get rigsImagesHint =>
      'Fiecare stație pornește de pe una dintre aceste imagini doar-citire. Fiecare sesiune scrie pe un overlay de unică folosință, astfel o stație nu poate schimba niciodată de la ce pornește următoarea.';

  @override
  String get rigsRunningTitle => 'Rulează acum';

  @override
  String get rigsNoneRunning => 'Nicio mașină nu rulează.';

  @override
  String get rigsCustomImagesTitle =>
      'Imagini personalizate (acest spațiu de lucru)';

  @override
  String get rigsCustomImagesHint =>
      'Indică Terminal (VM) sau Browser (VM) către propria ta imagine — extinde valorile implicite cu instrumentele de care are nevoie proiectul tău sau folosește una compatibilă dintr-un registry. Mașinile noi o folosesc; cele în rulare își păstrează a lor. Vezi ghidul stațiilor pentru ce trebuie să ofere o imagine.';

  @override
  String get rigsCustomTerminalImageLabel => 'Imagine Terminal (VM)';

  @override
  String get rigsCustomBrowserImageLabel => 'Imagine Browser (VM)';

  @override
  String get rigsCustomImagePlaceholder =>
      'de ex. ghcr.io/acme/dev-shell:1.2 — lasă gol pentru implicit';

  @override
  String get rigsCustomImageInvalid =>
      'Introdu o referință de registry de forma repo/name:tag. Căile locale și arhivele nu sunt permise.';

  @override
  String get rigsCustomImageSaved =>
      'Salvat. Mașinile noi pornesc această imagine; cele în rulare și-o păstrează pe a lor.';

  @override
  String get rigsEgressTitle =>
      'Ieșire de rețea a browserului (acest spațiu de lucru)';

  @override
  String get rigsEgressHint =>
      'Gazde suplimentare pe care browserul izolat le poate atinge — una pe linie: o gazdă exactă (api.example.com) sau un wildcard pentru subdomeniile ei (*.example.com). Site-ul produsului rămâne permis oricum. Mașinile noi primesc lista; cele în rulare păstrează cu ce au pornit.';

  @override
  String rigsEgressInvalid(String host) {
    return '\"$host\" nu este o înregistrare de gazdă validă.';
  }

  @override
  String get rigsEgressSaved =>
      'Salvat. Mașinile browser noi admit aceste gazde; cele în rulare și le păstrează pe ale lor.';

  @override
  String get rigImageInstalled => 'Instalat';

  @override
  String get rigImageNotDownloaded => 'Nedescărcat';

  @override
  String get rigImageNotPublished => 'Nepublicat';

  @override
  String get rigImageNotPublishedHint =>
      'Nu s-a publicat încă nicio imagine pentru aceasta, deci nu e nimic de descărcat. Importă o imagine de disc compatibilă ca să o activezi.';

  @override
  String get rigImageDownload => 'Descarcă';

  @override
  String get rigImageDownloading => 'Se descarcă…';

  @override
  String get rigImageImport => 'Importă';

  @override
  String get rigImageImportMessage =>
      'Calea către o imagine de disc qcow2 pe sistemul de fișiere al serverului. Este copiată în magazia de imagini, astfel fișierul poate fi mutat după aceea.';

  @override
  String get rigConnectingStream => 'Se conectează la stație';

  @override
  String get rigStreamNotAllowed => 'Nu ai acces la această stație.';

  @override
  String get rigStreamNotRunning => 'Această stație nu mai rulează.';

  @override
  String get rigStreamNeedsFfmpeg =>
      'Vizualizarea live are nevoie de ffmpeg pe această gazdă. Instalează ffmpeg și redeschide fila.';

  @override
  String get rigStreamNeedsScreenCapture =>
      'Vizualizarea live necesită Înregistrarea ecranului. Acord-o pentru Control Center în Configurări sistem și redeschide fila.';

  @override
  String get rigStreamEnded => 'Vizualizarea live s-a încheiat.';

  @override
  String get rigStreamFailed => 'Vizualizarea live nu a putut fi deschisă.';

  @override
  String get rigStreamDisconnected => 'Nu ești conectat la un server.';

  @override
  String rigDropSendingOne(String name) {
    return 'Se copiază \"$name\" în mașină…';
  }

  @override
  String rigDropSendingMany(int count) {
    return 'Se copiază $count fișiere în mașină…';
  }

  @override
  String get rigTerminalDropSending => 'Se copiază în mașină…';

  @override
  String get rigTerminalPasteImage =>
      'Imaginea lipită a fost salvată în mașină';

  @override
  String get rigPortsTitle => 'Porturi redirecționate';

  @override
  String get rigPortsTooltip => 'Porturi deschise în această mașină';

  @override
  String get rigPortsEmpty =>
      'Nimic nu ascultă încă. Pornește un server în terminal — un server de dezvoltare pe portul 3000 apare aici.';

  @override
  String get rigPortsAdd => 'Adaugă port';

  @override
  String get rigPortsAddHint => 'Portul guest de redirecționat (de ex. 3000)';

  @override
  String get rigPortsAutoForward => 'Redirecționează porturile automat';

  @override
  String get rigPortsCopyUrl => 'Copiază URL-ul local';

  @override
  String rigPortsCopiedUrl(String url) {
    return 'S-a copiat $url';
  }

  @override
  String get rigPortsStopForward => 'Oprește redirecționarea';

  @override
  String get rigPortsExposeLan => 'Partajează în rețeaua locală';

  @override
  String get rigPortsLanPrivate => 'Doar local';

  @override
  String get rigPortsLanShared => 'În rețea';

  @override
  String get rigPortsSetDomain => 'Setează un domeniu de browser (.test)';

  @override
  String get rigPortsDomainHint =>
      'Domeniu pentru Browser (VM), de ex. myapp.test — accesibil acolo, nu pe gazdă';

  @override
  String get rigPortsProcessUnknown => 'proces necunoscut';

  @override
  String get rigPortsInactive => 'nu ascultă';

  @override
  String get rigPortsTooltipHost => 'Porturi deschise în acest terminal';

  @override
  String get rigPortsEmptyHost =>
      'Nimic nu ascultă încă în acest terminal. Pornește un server și apare aici.';

  @override
  String get rigPortsAddHintHost => 'Port de mapat (ex. 5173)';

  @override
  String get rigPortsLocalPortHint => 'Port local (opțional)';

  @override
  String rigPortsDestDesktop(int port) {
    return 'localhost:$port';
  }

  @override
  String rigPortsDestBrowser(int port) {
    return 'localhost:$port în browser (VM)';
  }

  @override
  String get rigPortsDestBrowserUnreachable => 'browser (VM) neatașat';

  @override
  String rigPortsDestAndroid(int port) {
    return 'localhost:$port pe Android';
  }

  @override
  String get rigPortsDestAndroidUnreachable => 'Android neatașat';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de imagini de bază de descărcat',
      few: '# imagini de bază de descărcat',
      one: '1 imagine de bază de descărcat',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => 'Permite';

  @override
  String get guardrailDecisionPrompt => 'Întreabă întâi';

  @override
  String get guardrailDecisionDeny => 'Refuză';

  @override
  String get guardrailSourceThisScope => 'Acest domeniu';

  @override
  String get guardrailSourceDefault => 'Implicit încorporat';

  @override
  String get guardrailSourcePreset => 'Presetare de mod';

  @override
  String get guardrailSourceInherited => 'Moștenit';

  @override
  String get guardrailClearToInherited => 'Revino la moștenit';

  @override
  String get guardrailWhatIf => 'Ce-ar fi dacă?';

  @override
  String get guardrailWhatIfDescription =>
      'Vezi cum ar rezolva regulile actuale o acțiune, cu aceeași logică pe care o aplică agenții.';

  @override
  String get guardrailProbeActionLabel => 'Acțiune';

  @override
  String get guardrailProbeCommandLabel => 'Comandă (opțional)';

  @override
  String get guardrailProbeCommandHint => 'de ex. git push origin main';

  @override
  String get guardrailProbeAgentLabel => 'Agent (opțional)';

  @override
  String get guardrailProbeSpaceLabel => 'Spațiu (opțional)';

  @override
  String get guardrailProbeNone => 'Niciunul';

  @override
  String get guardrailProbeModeLabel => 'Mod';

  @override
  String get guardrailProbeResult => 'Rezultat';

  @override
  String get guardrailProbeSource => 'Sursă:';

  @override
  String get guardrailAdapterMatrix => 'Unde sunt aplicate regulile';

  @override
  String get guardrailAdapterMatrixDescription =>
      'Referință onestă: unde este interceptat de fapt fiecare efect, pe runner de agent. Documentează realitatea, nu o garanție — efectele pe care un runner le face în afara benzii nu pot fi interceptate.';

  @override
  String get guardrailEffectColumn => 'Efect';

  @override
  String get guardrailAdapterHarness => 'Harness încorporat';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => 'Prag sandbox';

  @override
  String get guardrailEnforcementPolicyGate => 'Poartă de politică';

  @override
  String get guardrailEnforcementSandbox => 'Doar sandbox';

  @override
  String get guardrailEnforcementNone => 'Nu se poate aplica';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      'Decizia de permisiune este verificată înainte ca efectul să ruleze și îl poate bloca.';

  @override
  String get guardrailEnforcementSandboxHelp =>
      'Doar sandbox-ul îl constrânge; regula de permisiune nu este consultată.';

  @override
  String get guardrailEnforcementNoneHelp =>
      'Decizia este doar consultativă — nu poate fi interceptată aici.';

  @override
  String get obsStatCost => 'cost';

  @override
  String obsStatDelegatedCost(String amount) {
    return '+$amount delegat';
  }

  @override
  String get obsStatDuration => 'durată';

  @override
  String get obsStatTokens => 'tokeni';

  @override
  String get obsStatTools => 'instrumente';

  @override
  String get openAgentActivity => 'Deschide activitatea';

  @override
  String get orgChart => 'Organigramă';

  @override
  String get orgChartEmpty => 'Niciun agent încă';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get serverConnection => 'Conexiune la server';

  @override
  String get serverModeLocal => 'Rulează în această aplicație';

  @override
  String get serverModeLocalDescription =>
      'Control Center rulează propriul server pe această mașină și deține datele local.';

  @override
  String get serverRemoteUrl => 'URL server';

  @override
  String get serverRemoteDeviceId => 'ID dispozitiv';

  @override
  String get serverRemotePairingKey => 'Cheie de asociere';

  @override
  String get serverRemotePairingKeyHint =>
      'Lipește cheia de asociere de pe serverul remote';

  @override
  String get serverSetupInviteCode => 'Cod de invitație';

  @override
  String get serverSetupInviteCodeHint =>
      'Lipește un cod de invitație de unică folosință (lasă gol pentru a folosi o cheie de asociere)';

  @override
  String get serverDiscoveryTooltip => 'Găsește servere în rețeaua ta';

  @override
  String get serverDiscoveryTitle => 'Servere în rețeaua ta';

  @override
  String get serverDiscoverySearching => 'Se caută servere…';

  @override
  String get serverDiscoveryEmpty =>
      'Niciun server găsit. Verifică că serverul rulează și că acest dispozitiv îl poate atinge, apoi caută din nou.';

  @override
  String get serverDiscoveryRefresh => 'Caută din nou';

  @override
  String get serverListActive => 'Activ';

  @override
  String get serverListSwitch => 'Comută';

  @override
  String get serverListAddTitle => 'Adaugă server';

  @override
  String get serverListRemoveActiveHint =>
      'Comută pe alt server înainte de a-l elimina pe acesta.';

  @override
  String get serverSwitchFailedTitle => 'Nu s-a putut comuta serverul';

  @override
  String get serverListInsecureBadge => 'Nesigur';

  @override
  String get connectionPathLocal => 'Local';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => 'Se închide';

  @override
  String get shutdownSubtitle => 'Se închide serverul local';

  @override
  String get shutdownServiceApprovals => 'Aprobări';

  @override
  String get shutdownServiceBackgroundJobs => 'Joburi de fundal';

  @override
  String get shutdownServiceScheduler => 'Planificator de joburi';

  @override
  String get shutdownServiceCalendar => 'Sincronizare calendar';

  @override
  String get shutdownServiceWeather => 'Meteo';

  @override
  String get shutdownServiceSoundscape => 'Soundscape';

  @override
  String get shutdownServiceMeetings => 'Întâlniri';

  @override
  String get shutdownServiceVoiceModels => 'Modele vocale';

  @override
  String get shutdownServiceNetworking => 'Rețea';

  @override
  String get shutdownServicePresence => 'Prezență';

  @override
  String get shutdownServiceDataSync => 'Sincronizare date';

  @override
  String get shutdownServiceDeviceRelay => 'Releu dispozitive';

  @override
  String get shutdownServiceMcpConnections => 'Conexiuni MCP';

  @override
  String get shutdownServiceCodeEditors => 'Editoare de cod';

  @override
  String get serverSharingTitle => 'Partajează acest server';

  @override
  String get serverSharingDescription =>
      'Fă acest server accesibil de pe celelalte dispozitive ale tale. Nimic nu e expus public decât dacă activezi un tunel mai jos. Invitațiile de asociere includ automat adresele curente ale serverului — creează-le în setările spațiului de lucru.';

  @override
  String get serverSharingUnavailable =>
      'Controalele de partajare nu sunt disponibile pe acest server.';

  @override
  String get serverSharingMdnsLabel => 'Descoperire LAN';

  @override
  String get serverSharingMdnsOn =>
      'Acest server se anunță în rețeaua ta locală (mDNS)';

  @override
  String get serverSharingMdnsOff => 'Nu se anunță în rețeaua ta locală (mDNS)';

  @override
  String get serverSharingTunnelLabel => 'Tunel';

  @override
  String get serverSharingTunnelHelper =>
      'Activarea unui tunel face acest server accesibil de pe internet. Expunerea publică este opțională și dezactivată implicit.';

  @override
  String get serverSharingProviderOff => 'Oprit';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => 'URL public';

  @override
  String get serverSharingTunnelStarting => 'Se pornește tunelul…';

  @override
  String serverSharingTunnelError(String error) {
    return 'Eroare tunel: $error';
  }

  @override
  String get serverSharingTunnelUpNoUrl =>
      'Tunelul este activ. Accesează-l la numele DNS configurat.';

  @override
  String get serverSharingRelayLabel => 'Releu';

  @override
  String serverSharingRelayUsage(String amount) {
    return 'Retransmis luna aceasta: $amount';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return 'Sesiuni de releu active: $count';
  }

  @override
  String get serverSharingUpdateFailedTitle =>
      'Nu s-a putut actualiza partajarea';

  @override
  String get pairNewClient => 'Asociază un client nou';

  @override
  String get pairClientNameHint =>
      'Etichetează acest client (de ex. Laptop de serviciu)';

  @override
  String get pairClientTypeWeb => 'Browser web';

  @override
  String get pairClientTypeDesktop => 'Aplicație desktop';

  @override
  String get pairClientTypePhone => 'Telefon';

  @override
  String get pairAction => 'Asociază';

  @override
  String get revoke => 'Revocă';

  @override
  String get pairCredentialsIntro =>
      'Conectează noul client cu aceste detalii sau deschide linkul în el.';

  @override
  String get pairLinkLabel => 'Link';

  @override
  String get pairScanQr =>
      'Scanează acest cod QR cu camera telefonului ca să-l asociezi.';

  @override
  String get pairServerUnreachableTitle => 'Inaccesibil';

  @override
  String get pairServerUnreachable =>
      'Alte dispozitive nu pot atinge acest server direct, deci un client nou nu se poate conecta. Setează URL-ul public al serverului ca să asociezi mai mulți clienți.';

  @override
  String get serverSetupRunLocal => 'Rulează în această aplicație';

  @override
  String get serverSetupConnect => 'Conectează';

  @override
  String get serverSetupInvalidUrl =>
      'Introdu un URL de server ws:// sau wss:// valid.';

  @override
  String get serverSetupCouldNotConnect => 'Nu s-a putut conecta';

  @override
  String get serverSetupErrorUnreachable =>
      'Nu am putut atinge serverul. Verifică că rulează și că acest dispozitiv îl poate atinge (aceeași rețea sau releu).';

  @override
  String get serverSetupErrorIdentityMismatch =>
      'Identitatea serverului nu corespunde cu cea salvată pe acest dispozitiv. Dacă serverul a fost reinstalat sau resetat, elimină serverul salvat și asociază din nou.';

  @override
  String get serverSetupErrorAuthRejected =>
      'Serverul a respins acest dispozitiv. Verifică că cheia de asociere și ID-ul dispozitivului coincid cu ce a emis serverul.';

  @override
  String get serverSetupErrorInviteRejected =>
      'Codul de invitație este invalid sau a expirat. Cere unul nou.';

  @override
  String get serverSetupErrorGeneric =>
      'Ceva nu a mers bine la conectare. Extinde detaliile tehnice de mai jos pentru mai multe informații.';

  @override
  String get serverSetupErrorDetails => 'Detalii tehnice';

  @override
  String get serverActivityTitle => 'Activitatea serverului';

  @override
  String get serverActivityStarting => 'Se pornește serverul local…';

  @override
  String get serverActivityConnecting => 'Se conectează la server…';

  @override
  String get serverActivityStartFailed => 'Serverul nu a putut porni';

  @override
  String get serverActivityDownloadFailed => 'Descărcarea a eșuat';

  @override
  String get serverActivityStatusUnavailable =>
      'Nu s-a putut citi starea modelului';

  @override
  String get serverActivityPreparingModel => 'Se pregătește modelul…';

  @override
  String get serverActivityPortInUse =>
      'Portul serverului este deja folosit. Opriți celălalt proces sau alegeți un alt port pe server.';

  @override
  String get serverActivityStartFailedHint =>
      'Verificați detaliile tehnice, apoi încercați din nou din configurarea serverului.';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'încă #',
      few: 'încă #',
      one: 'încă 1',
    );
    return '$_temp0';
  }

  @override
  String calendarAllDayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de evenimente',
      few: '# evenimente',
      one: '1 eveniment',
    );
    return '$_temp0';
  }

  @override
  String get calendarCollapseAllDay => 'Restrânge evenimentele de toată ziua';

  @override
  String get calendarExpandAllDay => 'Extinde evenimentele de toată ziua';

  @override
  String get calendarViewMonth => 'Lună';

  @override
  String get calendarViewWeek => 'Săptămână';

  @override
  String get calendarViewAgenda => 'Agendă';

  @override
  String get calendarConnectGoogle => 'Conectează Google Calendar';

  @override
  String get calendarConnectDescription =>
      'Sincronizează Google Calendar ca să vezi evenimentele aici și să primești alerte înainte de începerea întâlnirilor.';

  @override
  String get calendarDisconnect => 'Deconectează';

  @override
  String get calendarReconnect => 'Reconectează';

  @override
  String get calendarEmptyNoEvents => 'Niciun eveniment în acest interval';

  @override
  String get calendarJoinMeet => 'Intră în întâlnire';

  @override
  String get calendarJoinAndRecord => 'Intră și înregistrează';

  @override
  String get calendarRecordFailed => 'Nu s-a putut porni înregistrarea';

  @override
  String get calendarFromCalendar => 'Din calendar';

  @override
  String get calendarLinkedMeeting => 'Întâlnire legată';

  @override
  String get calendarToday => 'Azi';

  @override
  String get calendarAllDay => 'Toată ziua';

  @override
  String calendarWeekNumber(int number) {
    return 'Săptămâna $number';
  }

  @override
  String get calendarPreviousPeriod => 'Anterior';

  @override
  String get calendarNextPeriod => 'Următor';

  @override
  String calendarLastSynced(String time) {
    return 'Sincronizat $time';
  }

  @override
  String get calendarNeverSynced => 'Nesincronizat încă';

  @override
  String get calendarSyncing => 'Se sincronizează…';

  @override
  String get calendarViewDay => 'Zi';

  @override
  String get calendarShow => 'Afișează';

  @override
  String get calendarHide => 'Ascunde';

  @override
  String get calendarRsvpGoing => 'Participi?';

  @override
  String get calendarRsvpYes => 'Da';

  @override
  String get calendarRsvpNo => 'Nu';

  @override
  String get calendarRsvpMaybe => 'Poate';

  @override
  String get calendarRsvpFailed => 'Nu s-a putut actualiza răspunsul';

  @override
  String get calendarNewEvent => 'Eveniment nou';

  @override
  String get calendarComposerTitleHint => 'Adaugă un titlu';

  @override
  String get calendarComposerStarts => 'Începe';

  @override
  String get calendarComposerEnds => 'Se termină';

  @override
  String get calendarComposerDate => 'Data';

  @override
  String get calendarComposerEndDate => 'Ultima zi';

  @override
  String get calendarComposerGuestsHint => 'Adaugă invitați prin e-mail';

  @override
  String get calendarComposerMeet => 'Adaugă un link Google Meet';

  @override
  String get calendarComposerLocationHint => 'Adaugă o locație';

  @override
  String get calendarComposerDescriptionHint => 'Adaugă o descriere';

  @override
  String get calendarComposerCalendar => 'Calendar';

  @override
  String get calendarComposerTitleRequired =>
      'Adaugă un titlu ca să salvezi evenimentul';

  @override
  String get calendarComposerInvalidGuests =>
      'Una dintre adresele de e-mail ale invitaților nu este validă';

  @override
  String get calendarComposerEndBeforeStart =>
      'Evenimentul trebuie să se termine după ce începe';

  @override
  String get calendarComposerSaveFailed =>
      'Evenimentul nu a putut fi creat. Încearcă din nou.';

  @override
  String get calendarComposerGuestsNotified =>
      'Invitații primesc o invitație pe e-mail de la Google.';

  @override
  String get calendarDeleteEvent => 'Șterge evenimentul';

  @override
  String calendarDeleteConfirmTitle(String title) {
    return 'Ștergi „$title”?';
  }

  @override
  String get calendarDeleteConfirmBody => 'Este șters din Google Calendar.';

  @override
  String get calendarDeleteConfirmGuests =>
      'Este șters din Google Calendar, iar toți invitații sunt anunțați că a fost anulat.';

  @override
  String get calendarDeleteConfirmInvite =>
      'Este șters doar din calendarul tău. Organizatorul și ceilalți invitați îl păstrează.';

  @override
  String get calendarDeleteConfirmRecurring =>
      'Se șterge doar această apariție; restul seriei rămâne.';

  @override
  String get calendarDeleteFailed =>
      'Evenimentul nu a putut fi șters. Încearcă din nou.';

  @override
  String get calendarMoveFailed =>
      'Evenimentul nu a putut fi mutat. A revenit la locul inițial.';

  @override
  String get activityCreatedCalendarEvent =>
      'A creat un eveniment din calendar';

  @override
  String get activityMovedCalendarEvent => 'A mutat un eveniment din calendar';

  @override
  String get activityDeletedCalendarEvent =>
      'A șters un eveniment din calendar';

  @override
  String get calendarAddAccount => 'Adaugă un cont de calendar';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Conectează un cont Google pentru a sincroniza evenimentele în acest spațiu. Aceste calendare sunt ale tale aici.';

  @override
  String get calendarSyncNow => 'Sincronizează acum';

  @override
  String get calendarNoWorkspace =>
      'Selectează un spațiu de lucru ca să-i vezi calendarul';

  @override
  String get calendarConnectError => 'Nu s-a putut conecta Google Calendar';

  @override
  String get notificationMeetingStartsSoon => 'Întâlnirea începe curând';

  @override
  String get notifyMeetingStartsSoon =>
      'Când o întâlnire din calendar e pe cale să înceapă';

  @override
  String get notificationCalendarAuthExpiredTitle => 'Calendar deconectat';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'Reconectează $email ca să reiei sincronizarea';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'Reconectează calendarul ca să reiei sincronizarea';

  @override
  String get notifyCalendarAuthExpired =>
      'Când un cont de calendar trebuie reconectat';

  @override
  String get notificationRigStatusChanged => 'Actualizări mediu izolat';

  @override
  String get notifyRigStatusChanged =>
      'Când un mediu izolat este preluat, recuperat sau eșuează';

  @override
  String get notificationRigTakenOver => 'Mediu izolat preluat';

  @override
  String get notificationRigTakenOverBody =>
      'O persoană conduce mașina; agentul poate urmări, dar nu poate acționa.';

  @override
  String get notificationRigReleased =>
      'Controlul mediului izolat a fost eliberat';

  @override
  String get notificationRigReleasedBody => 'Agentul are din nou mașina.';

  @override
  String get notificationRigReclaimed => 'Mediu izolat recuperat';

  @override
  String get notificationRigReclaimedBodyIdle =>
      'A stat inactiv, deci mașina a fost închisă ca să elibereze memoria.';

  @override
  String get notificationRigReclaimedBodyTtl =>
      'A atins limita de timp și a fost închisă.';

  @override
  String get notificationRigFailed => 'Mediu izolat eșuat';

  @override
  String get notificationRigFailedBody =>
      'Hypervisorul s-a oprit sub ea. Redeschide mașina ca să continui.';

  @override
  String get calendarAlertLeadTime => 'Timp de avans al alertei';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'Cu cât timp înainte de o întâlnire să fii alertat';

  @override
  String calendarConnectedAs(String email) {
    return 'Conectat ca $email';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count participanți';
  }

  @override
  String get calendarEventLabel => 'Eveniment';

  @override
  String get calendarRecurring => 'Eveniment recurent';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'Organizator';

  @override
  String get calendarYou => 'Tu';

  @override
  String get calendarShowFewer => 'Afișează mai puține';

  @override
  String get calendarRsvpAwaiting => 'În așteptare';

  @override
  String calendarParticipantsCount(int count) {
    return '$count participanți';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'Vezi toți cei $count participanți';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count da';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count nu';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count poate';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count în așteptare';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count minute';
  }

  @override
  String get openInEditorPrompt => 'În care editor deschizi?';

  @override
  String get ideNotInstalled => 'Neinstalat';

  @override
  String openInIde(String editor) {
    return 'Deschide în $editor';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return 'Nu s-a putut deschide $editor: $error';
  }

  @override
  String get profileSearchHint => 'Caută pull request-uri…';

  @override
  String get stopAgentRun => 'Oprește rularea';

  @override
  String get stopAgentRunConfirm =>
      'Oprești această rulare? Lucrul în curs se pierde.';

  @override
  String get inProgress => 'În curs';

  @override
  String get drafts => 'Ciorne';

  @override
  String get sortOldest => 'Cele mai vechi';

  @override
  String get sortLargest => 'Cele mai mari';

  @override
  String get prFilterTooltip => 'Filtru';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de filtre active',
      few: '# filtre active',
      one: '1 filtru activ',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => 'Adaugă filtru…';

  @override
  String get prFilterFieldHint => 'Filtrează…';

  @override
  String get prFilterCategoryStatus => 'Stare';

  @override
  String get prFilterCategoryAuthor => 'Autor';

  @override
  String get prFilterCategoryReviewer => 'Recenzenți';

  @override
  String get prFilterCategoryContent => 'Conținut';

  @override
  String get prFilterCategoryRepoOwner => 'Proprietar depozit';

  @override
  String get prFilterCategoryRepoName => 'Nume depozit';

  @override
  String get prFilterCategoryOpenedDate => 'Data deschiderii';

  @override
  String get prFilterCategoryUpdatedDate => 'Data actualizării';

  @override
  String get prFilterQuickToReview => 'Rapid de revizuit';

  @override
  String get prFilterClearAll => 'Șterge filtrele';

  @override
  String prFilterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de pull request-uri',
      few: '# pull request-uri',
      one: '1 pull request',
    );
    return '$_temp0';
  }

  @override
  String prFilterHiddenOptions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de opțiuni care nu se potrivesc cu niciun pull request',
      few: '# opțiuni care nu se potrivesc cu niciun pull request',
      one: '1 opțiune care nu se potrivește cu niciun pull request',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => 'Titlul sau corpul conține…';

  @override
  String get prFilterNoOptions => 'Nicio opțiune potrivită';

  @override
  String get prFilterChipIs => 'este';

  @override
  String get prFilterChipIsAnyOf => 'este oricare dintre';

  @override
  String get prFilterChipContains => 'conține';

  @override
  String get prFilterChipSince => 'de la';

  @override
  String get prFilterAddFilterButton => 'Adaugă filtru';

  @override
  String prFilterClearCategory(String category) {
    return 'Șterge filtrul $category';
  }

  @override
  String get prFilterCurrentUser => 'Utilizator curent';

  @override
  String get prStatusDraft => 'Ciornă';

  @override
  String get prStatusOpen => 'Deschis';

  @override
  String get prStatusInReview => 'În revizuire';

  @override
  String get prStatusChangesRequested => 'Modificări cerute';

  @override
  String get prStatusApproved => 'Aprobat';

  @override
  String get prStatusMerged => 'Fuzionat';

  @override
  String get prStatusClosed => 'Închis';

  @override
  String get prDateWindowDay => 'acum 1 zi';

  @override
  String get prDateWindowThreeDays => 'acum 3 zile';

  @override
  String get prDateWindowWeek => 'acum 1 săptămână';

  @override
  String get prDateWindowMonth => 'acum 1 lună';

  @override
  String get prDateWindowThreeMonths => 'acum 3 luni';

  @override
  String get prDateWindowSixMonths => 'acum 6 luni';

  @override
  String get prDateWindowYear => 'acum 1 an';

  @override
  String get prDisplayOptions => 'Opțiuni de afișare';

  @override
  String get prDisplayGrouping => 'Grupare';

  @override
  String get prDisplayOrdering => 'Ordonare';

  @override
  String get prDisplayShowDrafts => 'Afișează ciornele';

  @override
  String get prDisplayMergedWindow => 'Fereastră fuzionate';

  @override
  String get prDisplayMergedWindowDay => 'Ultima zi';

  @override
  String get prDisplayMergedWindowWeek => 'Ultima săptămână';

  @override
  String get prDisplayMergedWindowMonth => 'Ultima lună';

  @override
  String get prDisplayProperties => 'Proprietăți de afișare';

  @override
  String get prGroupingRepository => 'Depozit';

  @override
  String get prGroupingAuthor => 'Autor';

  @override
  String get prGroupingStatus => 'Stare';

  @override
  String get prGroupingNone => 'Fără grupare';

  @override
  String get prPropertyRepository => 'Depozit';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => 'Ramură';

  @override
  String get prPropertyUpdated => 'Actualizat';

  @override
  String get prPropertyAuthor => 'Autor';

  @override
  String get prPropertyChecks => 'Verificări';

  @override
  String get prPropertyDiff => 'Diff';

  @override
  String get prPropertyComments => 'Comentarii';

  @override
  String get keybindingOpenFilterMenu => 'Deschide meniul de filtre';

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# selectate',
      few: '# selectate',
      one: '1 selectat',
    );
    return '$_temp0';
  }

  @override
  String get summary => 'Rezumat';

  @override
  String get kbMove => 'mută';

  @override
  String get kbTabs => 'file';

  @override
  String get kbSearch => 'caută';

  @override
  String get kbViewed => 'vizualizat';

  @override
  String get kbCollapse => 'restrânge';

  @override
  String get appearance => 'Aspect';

  @override
  String get appearanceSettingsDescription => 'Temă, limbă și tipografie.';

  @override
  String get notificationsSettingsDescription =>
      'Alege ce evenimente de agent și de spațiu de lucru te notifică.';

  @override
  String get advanced => 'Avansat';

  @override
  String get accounts => 'Conturi';

  @override
  String get mcpServers => 'Servere MCP';

  @override
  String get remoteControlAndDevices => 'Control remote și dispozitive';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'Asociază telefoane și configurează serverul de control remote.';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'Modelele de vorbire și diarizare găzduite de acest server.';

  @override
  String get needsSetupLabel => 'Necesită configurare';

  @override
  String get collapseSidebar => 'Restrânge bara laterală';

  @override
  String get expandSidebar => 'Extinde bara laterală';

  @override
  String get filterSpacesHint => 'Filtrează spațiile';

  @override
  String noSpacesMatch(String query) {
    return 'Niciun spațiu nu se potrivește cu \"$query\"';
  }

  @override
  String get privacy => 'Confidențialitate';

  @override
  String get sendDiffContentTitle =>
      'Trimite conținutul diff-ului către adaptorul AI';

  @override
  String get diffSharingOnSubtitle =>
      'Liniile brute din diff sunt incluse în prompturile agenților pentru o revizuire mai profundă.';

  @override
  String get diffSharingOffSubtitle =>
      'Agenții folosesc doar metadate structurate (căi de fișiere, numere de linie, descrierea PR); niciun cod brut nu părăsește aplicația.';

  @override
  String get errorReportingTitle => 'Partajează rapoartele de crash';

  @override
  String get errorReportingOnSubtitle =>
      'Diagnosticările de crash, erori și performanță sunt trimise ca să ajute la remedierea problemelor (doar build-uri de release).';

  @override
  String get errorReportingOffSubtitle =>
      'Diagnosticările sunt oprite. Nu se trimit rapoarte de crash sau erori.';

  @override
  String get onboardingDiagnosticsTitle =>
      'Ajută la îmbunătățirea Control Center';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'Trimite diagnosticări de crash, erori și performanță ca să putem rezolva problemele mai rapid (doar build-uri de release). Poți schimba oricând în Setări → Confidențialitate.';

  @override
  String get usageAnalyticsTitle => 'Partajează statisticile de utilizare';

  @override
  String get usageAnalyticsOnSubtitle =>
      'Toți clienții acestui server trimit evenimente de utilizare pseudonimizate (ecrane, acțiuni, numărători), doar în build-uri de release. Niciodată nume, conținutul mesajelor, căi de fișiere sau adrese de e-mail.';

  @override
  String get usageAnalyticsOffSubtitle =>
      'Statisticile de utilizare sunt dezactivate. Niciun client al acestui server nu trimite evenimente de utilizare.';

  @override
  String get usageAnalyticsManagedOnSubtitle =>
      'Clienții acestui server trimit evenimente de utilizare pseudonimizate. Doar operatorul serverului poate schimba asta.';

  @override
  String get usageAnalyticsManagedOffSubtitle =>
      'Statisticile de utilizare sunt dezactivate pe acest server. Doar operatorul serverului poate schimba asta.';

  @override
  String get onboardingUsageAnalyticsSubtitle =>
      'Trimite evenimente de utilizare pseudonimizate de la toți clienții acestui server, ca să vedem ce funcții ajută (doar build-uri de release). Niciodată nume, conținutul mesajelor, căi de fișiere sau adrese de e-mail. Poți schimba oricând în Setări → Confidențialitate.';

  @override
  String get blocked => 'Blocat';

  @override
  String get idle => 'Inactiv';

  @override
  String get noRunsYet => 'Nicio rulare încă';

  @override
  String get copyPath => 'Copiază calea';

  @override
  String get copyRelativePath => 'Copiază calea relativă';

  @override
  String get nameRequired => 'Numele este obligatoriu';

  @override
  String get import => 'Importă';

  @override
  String get noMatchingAgents => 'Niciun agent nu se potrivește filtrului tău';

  @override
  String watchVideoOn(String provider) {
    return 'Urmărește videoclipul pe $provider';
  }

  @override
  String get branchTemplate => 'Șablon nume de ramură';

  @override
  String get branchTemplateDescription =>
      'Modelul pentru ramura creată când un tichet este pornit într-un worktree izolat.';

  @override
  String branchTemplatePreview(String example) {
    return 'Exemplu: $example';
  }

  @override
  String get deletePipelineRun => 'Șterge rularea pipeline';

  @override
  String deletePipelineRunConfirm(String template) {
    return 'Ștergi această rulare a \"$template\"? Acțiunea nu poate fi anulată.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'Eroare la ștergerea rulării pipeline: $error';
  }

  @override
  String get deleteTicket => 'Șterge tichetul';

  @override
  String deleteTicketConfirm(String title) {
    return 'Ștergi \"$title\"? Acțiunea nu poate fi anulată.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'Eroare la ștergerea tichetului: $error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return 'Ștergi \"$name\"? Depozitele legate de pe disc nu sunt atinse.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'Eroare la ștergerea spațiului de lucru: $error';
  }

  @override
  String get indexCode => 'Indexează codul';

  @override
  String get indexNoGrammars => 'Gramaticile de cod nu sunt instalate';

  @override
  String get indexFailed => 'Indexarea a eșuat';

  @override
  String indexedSymbolsCount(int count) {
    return '$count simboluri indexate';
  }

  @override
  String get nodeConfigAdvanced => 'Avansat';

  @override
  String get nodeConfigReducer => 'Reducer';

  @override
  String get nodeConfigReducerHelp =>
      'Cum se fuzionează când această cheie de ieșire are deja o valoare';

  @override
  String get nodeConfigTimeoutMs => 'Timeout (ms)';

  @override
  String get nodeConfigRetryAttempts => 'Încercări de reîncercare';

  @override
  String get nodeConfigContinueOnFail => 'Continuă dacă acest pas eșuează';

  @override
  String get nodeConfigTeamId => 'ID echipă';

  @override
  String get nodeConfigDispatchMode => 'Mod de dispatch';

  @override
  String get nodeConfigOutputSchema => 'Schemă de ieșire (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'JSON Schema pe care ieșirea pasului trebuie să o îndeplinească';

  @override
  String get nodeConfigBackupRetentionDays =>
      'Șterge copiile mai vechi de (zile)';

  @override
  String get nodeConfigBackupRetentionDaysHelp =>
      'Se șterg doar copiile acestui spațiu de lucru. Introdu un număr pozitiv de zile.';

  @override
  String get diffLineDisplay => 'Linii lungi în diff-uri';

  @override
  String get diffLineDisplayDescription =>
      'Înfășoară liniile lungi sau derulează-le orizontal';

  @override
  String get diffLineWrap => 'Încadrează';

  @override
  String get diffLineScroll => 'Derulează orizontal';

  @override
  String get actions => 'Acțiuni';

  @override
  String get activate => 'Activează';

  @override
  String get activity => 'Activitate';

  @override
  String get activitySearchHint => 'Caută activitate';

  @override
  String get activityNoMatches =>
      'Nicio activitate nu se potrivește filtrelor tale';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$start–$end din $total';
  }

  @override
  String get activityPreviousPage => 'Pagina anterioară';

  @override
  String get activityNextPage => 'Pagina următoare';

  @override
  String get activityNetworkLocal => 'Localhost';

  @override
  String get activityClearFilter => 'Șterge filtrul';

  @override
  String activityFilterIp(String ip) {
    return 'IP $ip';
  }

  @override
  String activityFilterCountry(String country) {
    return 'Țară $country';
  }

  @override
  String get activitySavedWorkspaceLogo =>
      'A salvat logo-ul spațiului de lucru';

  @override
  String activityVerbCreated(String target) {
    return 'A creat $target';
  }

  @override
  String activityVerbUpdated(String target) {
    return 'A actualizat $target';
  }

  @override
  String activityVerbDeleted(String target) {
    return 'A șters $target';
  }

  @override
  String activityVerbAdded(String target) {
    return 'A adăugat $target';
  }

  @override
  String activityVerbRemoved(String target) {
    return 'A eliminat $target';
  }

  @override
  String activityVerbInvited(String target) {
    return 'A invitat $target';
  }

  @override
  String activityVerbChanged(String target) {
    return 'A modificat $target';
  }

  @override
  String activityVerbStarted(String target) {
    return 'A pornit $target';
  }

  @override
  String activityVerbStopped(String target) {
    return 'A oprit $target';
  }

  @override
  String activityVerbWrote(String target) {
    return 'A scris $target';
  }

  @override
  String get activityTargetAgent => 'agent';

  @override
  String get activityTargetTicket => 'tichet';

  @override
  String get activityTargetWorkspace => 'spațiu de lucru';

  @override
  String get activityTargetRepository => 'depozit';

  @override
  String get activityTargetMember => 'membru';

  @override
  String get activityTargetInvite => 'invitație';

  @override
  String get activityTargetSpace => 'spațiu';

  @override
  String get activityTargetMessage => 'mesaj';

  @override
  String get activityTargetCache => 'cache';

  @override
  String get activityTargetFile => 'fișier';

  @override
  String get activityTargetPipeline => 'pipeline';

  @override
  String get activityTargetTemplate => 'șablon';

  @override
  String get activityTargetProvider => 'provider';

  @override
  String get activityTargetModel => 'model';

  @override
  String get activityTargetSkill => 'abilitate';

  @override
  String get activityTargetTodo => 'to-do';

  @override
  String get activityTargetMeeting => 'întâlnire';

  @override
  String get activityTargetProject => 'proiect';

  @override
  String get activityTargetTeam => 'echipă';

  @override
  String get activityTargetDevice => 'dispozitiv';

  @override
  String get activityTargetPreference => 'preferință';

  @override
  String get activityTargetBudget => 'buget';

  @override
  String activityVerbApproved(String target) {
    return 'A aprobat $target';
  }

  @override
  String activityVerbArchived(String target) {
    return 'A arhivat $target';
  }

  @override
  String activityVerbAssigned(String target) {
    return 'A asignat $target';
  }

  @override
  String activityVerbBackedUp(String target) {
    return 'A salvat $target';
  }

  @override
  String activityVerbCancelled(String target) {
    return 'A anulat $target';
  }

  @override
  String activityVerbCleared(String target) {
    return 'A golit $target';
  }

  @override
  String activityVerbClosed(String target) {
    return 'A închis $target';
  }

  @override
  String activityVerbCommitted(String target) {
    return 'A făcut commit pe $target';
  }

  @override
  String activityVerbCompacted(String target) {
    return 'A compactat $target';
  }

  @override
  String activityVerbCompleted(String target) {
    return 'A finalizat $target';
  }

  @override
  String activityVerbConnected(String target) {
    return 'A conectat $target';
  }

  @override
  String activityVerbContinued(String target) {
    return 'A continuat $target';
  }

  @override
  String activityVerbDisconnected(String target) {
    return 'A deconectat $target';
  }

  @override
  String activityVerbDispatched(String target) {
    return 'A trimis $target';
  }

  @override
  String activityVerbDrained(String target) {
    return 'A golit $target';
  }

  @override
  String activityVerbEnrolled(String target) {
    return 'A înscris $target';
  }

  @override
  String activityVerbEstimated(String target) {
    return 'A estimat $target';
  }

  @override
  String activityVerbImported(String target) {
    return 'A importat $target';
  }

  @override
  String activityVerbInstalled(String target) {
    return 'A instalat $target';
  }

  @override
  String activityVerbKilled(String target) {
    return 'A oprit forțat $target';
  }

  @override
  String activityVerbMarked(String target) {
    return 'A marcat $target';
  }

  @override
  String activityVerbMerged(String target) {
    return 'A fuzionat $target';
  }

  @override
  String activityVerbOpened(String target) {
    return 'A deschis $target';
  }

  @override
  String activityVerbPaused(String target) {
    return 'A pus în pauză $target';
  }

  @override
  String activityVerbPolled(String target) {
    return 'A interogat $target';
  }

  @override
  String activityVerbPrepared(String target) {
    return 'A pregătit $target';
  }

  @override
  String activityVerbProcessed(String target) {
    return 'A procesat $target';
  }

  @override
  String activityVerbPublished(String target) {
    return 'A publicat $target';
  }

  @override
  String activityVerbRefined(String target) {
    return 'A rafinat $target';
  }

  @override
  String activityVerbRefreshed(String target) {
    return 'A reîmprospătat $target';
  }

  @override
  String activityVerbRegistered(String target) {
    return 'A înregistrat $target';
  }

  @override
  String activityVerbRenamed(String target) {
    return 'A redenumit $target';
  }

  @override
  String activityVerbReordered(String target) {
    return 'A reordonat $target';
  }

  @override
  String activityVerbResponded(String target) {
    return 'A răspuns la $target';
  }

  @override
  String activityVerbRestored(String target) {
    return 'A restaurat $target';
  }

  @override
  String activityVerbResumed(String target) {
    return 'A reluat $target';
  }

  @override
  String activityVerbRetried(String target) {
    return 'A reîncercat $target';
  }

  @override
  String activityVerbReverted(String target) {
    return 'A revenit $target';
  }

  @override
  String activityVerbReviewed(String target) {
    return 'A revizuit $target';
  }

  @override
  String activityVerbRan(String target) {
    return 'A rulat $target';
  }

  @override
  String activityVerbSelected(String target) {
    return 'A selectat $target';
  }

  @override
  String activityVerbSent(String target) {
    return 'A trimis $target';
  }

  @override
  String activityVerbStaged(String target) {
    return 'A pus în staging $target';
  }

  @override
  String activityVerbSteered(String target) {
    return 'A direcționat $target';
  }

  @override
  String activityVerbSubmitted(String target) {
    return 'A trimis $target';
  }

  @override
  String activityVerbSynced(String target) {
    return 'A sincronizat $target';
  }

  @override
  String activityVerbToggled(String target) {
    return 'A comutat $target';
  }

  @override
  String activityVerbUninstalled(String target) {
    return 'A dezinstalat $target';
  }

  @override
  String activityVerbUnstaged(String target) {
    return 'A scos din staging $target';
  }

  @override
  String get activityTargetActionPolicy => 'politică de acțiune';

  @override
  String get activityTargetGoalRun => 'rulare de obiectiv';

  @override
  String get activityTargetRunLog => 'jurnal de rulare';

  @override
  String get activityTargetWorkingMemory => 'memorie de lucru';

  @override
  String get activityTargetRoutingPolicy => 'politică de rutare';

  @override
  String get activityTargetAutonomy => 'autonomie';

  @override
  String get activityTargetCalendar => 'calendar';

  @override
  String get activityTargetChecker => 'verificator';

  @override
  String get activityTargetEditor => 'editor';

  @override
  String get activityTargetConfirmation => 'confirmare';

  @override
  String get activityTargetTunnel => 'tunel';

  @override
  String get activityTargetConversation => 'conversație';

  @override
  String get activityTargetCredentials => 'date de autentificare';

  @override
  String get activityTargetDictation => 'dictare';

  @override
  String get activityTargetAgentRun => 'rulare agent';

  @override
  String get activityTargetEvalSuite => 'suită eval';

  @override
  String get activityTargetWorker => 'worker';

  @override
  String get activityTargetWorktree => 'worktree';

  @override
  String get activityTargetMcpServer => 'server MCP';

  @override
  String get activityTargetMemoryAccessGrant => 'grant de acces la memorie';

  @override
  String get activityTargetMemoryDomain => 'domeniu de memorie';

  @override
  String get activityTargetMemoryFact => 'fapt de memorie';

  @override
  String get activityTargetMemoryPolicy => 'politică de memorie';

  @override
  String get activityTargetFeed => 'flux';

  @override
  String get activityTargetNote => 'notă';

  @override
  String get activityTargetOrchestration => 'orchestrare';

  @override
  String get activityTargetPipelineRun => 'rulare pipeline';

  @override
  String get activityTargetPipelineTrigger => 'declanșator pipeline';

  @override
  String get activityTargetPlan => 'plan';

  @override
  String get activityTargetPlaybook => 'playbook';

  @override
  String get activityTargetPullRequest => 'pull request';

  @override
  String get activityTargetReview => 'revizuire';

  @override
  String get activityTargetProcess => 'proces';

  @override
  String get activityTargetProviderPolicy => 'politică de provider';

  @override
  String get activityTargetReaction => 'reacție';

  @override
  String get activityTargetReviewSpace => 'spațiu de revizuire';

  @override
  String get activityTargetReviewStudio => 'studio de revizuire';

  @override
  String get activityTargetServerData => 'date server';

  @override
  String get activityTargetSoundscape => 'soundscape';

  @override
  String get activityTargetSession => 'sesiune';

  @override
  String get activityTargetTerminal => 'terminal';

  @override
  String get activityTargetTicketLink => 'legătură tichet';

  @override
  String get activityTargetTicketSync => 'sincronizare tichete';

  @override
  String get activityTargetProfile => 'profil';

  @override
  String get activityTargetVoiceProfile => 'profil vocal';

  @override
  String get activityTargetWeather => 'prognoză meteo';

  @override
  String get activityTargetWorkProduct => 'produs de lucru';

  @override
  String get activityChangedMemberRole => 'A schimbat rolul unui membru';

  @override
  String get activityChangedMemberRepoAccess =>
      'A schimbat accesul unui membru la depozit';

  @override
  String get activityRefreshedWeather => 'A reîmprospătat prognoza meteo';

  @override
  String get activitySetWeatherLocation => 'A setat locația meteo';

  @override
  String get activityClearedWeatherLocation => 'A golit locația meteo';

  @override
  String get activityMarkedAllArticlesRead =>
      'A marcat toate articolele ca citite';

  @override
  String get activityMarkedArticleRead => 'A marcat un articol ca citit';

  @override
  String get activityUpdatedSavedArticle => 'A actualizat un articol salvat';

  @override
  String get activityTookOverSession => 'A preluat sesiunea';

  @override
  String get activityHandedBackSession => 'A predat sesiunea înapoi';

  @override
  String get activityCommittedAndPushed => 'A făcut commit și push';

  @override
  String get activityBackedUpServer => 'A făcut backup la datele serverului';

  @override
  String get activityRespondedToInvitation =>
      'A răspuns la invitația la eveniment';

  @override
  String get activityDisconnectedCalendar => 'A deconectat calendarul';

  @override
  String get activityMarkedFileViewed => 'A marcat un fișier ca vizualizat';

  @override
  String get activityRespondedToApproval => 'A răspuns la o cerere de aprobare';

  @override
  String get activityChangedTunnel => 'A modificat setarea tunelului';

  @override
  String get activitySentMessageToAgent => 'A trimis un mesaj agentului';

  @override
  String get activityOpenedReviewSpace => 'A deschis spațiul de revizuire';

  @override
  String get activityOpenedStandingConversation =>
      'A deschis conversația permanentă';

  @override
  String get activityStartedRecording => 'A pornit înregistrarea';

  @override
  String get activityStoppedRecording => 'A oprit înregistrarea';

  @override
  String get activityToggledMcpServer => 'A comutat serverul MCP';

  @override
  String get activitySavedApiKey => 'A salvat o cheie API';

  @override
  String get activityRemovedProviderCredential =>
      'A eliminat datele de autentificare ale unui provider';

  @override
  String get activityUpdatedLinkedRepos => 'A actualizat depozitele legate';

  @override
  String get activityUnlinkedRepo => 'A dezlegat un depozit';

  @override
  String get activityUpdatedActionItem => 'A actualizat un element de acțiune';

  @override
  String adRulesCount(int count) {
    return '$count reguli de reclame';
  }

  @override
  String get adapter => 'Adaptor';

  @override
  String get adapterLabel => 'Adaptor';

  @override
  String get adapters => 'Adaptori';

  @override
  String get adaptersAutoDetected =>
      'Runnere de agenți detectate automat pe această mașină. Instalează orice CLI lipsă ca să activezi runnere suplimentare.';

  @override
  String get add => 'Adaugă';

  @override
  String get addAComment => 'Adaugă un comentariu';

  @override
  String get addAReaction => 'Adaugă o reacție';

  @override
  String get addASuggestion => 'Adaugă o sugestie';

  @override
  String get addAgents => 'Adaugă agenți';

  @override
  String get addEmoji => 'Adaugă emoji';

  @override
  String get addFeed => 'Adaugă flux';

  @override
  String get addressBarHint => 'Introdu un URL';

  @override
  String get addFromFile => 'Adaugă din fișier';

  @override
  String get addGif => 'Adaugă GIF';

  @override
  String get addLocalCheckoutDescription =>
      'Adaugă un checkout local ca să-l poți viza din acest spațiu de lucru.';

  @override
  String get addRepository => 'Adaugă depozit';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Adaugă # de depozite',
      few: 'Adaugă # depozite',
      one: 'Adaugă depozit',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro =>
      'Răsfoiește folderele de pe mașina care rulează serverul și selectează checkout-urile git de înregistrat.';

  @override
  String get selectThisFolder => 'Selectează acest folder';

  @override
  String get deselectThisFolder => 'Deselectează acest folder';

  @override
  String get goUp => 'Sus';

  @override
  String get noSubfoldersHere => 'Niciun subfolder aici';

  @override
  String get notAGitRepository => 'Acest folder nu este un depozit git.';

  @override
  String get addToken => 'Adaugă token';

  @override
  String get addWorkspace => 'Adaugă spațiu de lucru';

  @override
  String get addWorkspaceEllipsis => 'Adaugă spațiu de lucru…';

  @override
  String get added => 'Adăugat';

  @override
  String get addingEllipsis => 'Se adaugă…';

  @override
  String get advancedLabel => 'Avansat';

  @override
  String get agent => 'Agent';

  @override
  String conversationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de conversații',
      few: '$count conversații',
      one: '$count conversație',
    );
    return '$_temp0';
  }

  @override
  String agentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de agenți',
      few: '$count agenți',
      one: '$count agent',
    );
    return '$_temp0';
  }

  @override
  String get agentMdPath => 'Cale Agent MD';

  @override
  String get agentName => 'Nume agent';

  @override
  String get agentTitle => 'Titlu agent';

  @override
  String get agentUpdated => 'Agent actualizat.';

  @override
  String get agents => 'Agenți';

  @override
  String get agentsMentionSection => 'Agenți';

  @override
  String get usersMentionSection => 'Persoane';

  @override
  String get ticketsMentionSection => 'Tichete';

  @override
  String get pullRequestsMentionSection => 'Pull request-uri';

  @override
  String get meetingsMentionSection => 'Întâlniri';

  @override
  String get entityRefTicketFallback => 'Tichet';

  @override
  String get entityRefPrFallback => 'Pull request';

  @override
  String get entityRefMeetingFallback => 'Întâlnire';

  @override
  String get aiReview => 'Revizuire AI';

  @override
  String get all => 'Toate';

  @override
  String get allAgentsAlreadyInSpace =>
      'Toți agenții sunt deja în acest spațiu.';

  @override
  String get allCommits => 'Toate commit-urile';

  @override
  String get allSources => 'Toate sursele';

  @override
  String get allow => 'Permite';

  @override
  String get apiKeys => 'Chei API';

  @override
  String get appFont => 'Font aplicație';

  @override
  String get appLogLevelDebugDescription =>
      'Adaugă urme detaliate — pentru dezvoltare.';

  @override
  String get appLogLevelDebugLabel => 'Debug';

  @override
  String get appLogLevelErrorDescription =>
      'Doar erori neașteptate și excepții.';

  @override
  String get appLogLevelErrorLabel => 'Eroare';

  @override
  String get appLogLevelInfoDescription =>
      'Adaugă mesaje de ciclu de viață și stare.';

  @override
  String get appLogLevelInfoLabel => 'Info';

  @override
  String get appLogLevelNoneDescription => 'Nicio ieșire în consolă.';

  @override
  String get appLogLevelNoneLabel => 'Niciunul';

  @override
  String get appLogLevelVerboseDescription =>
      'Totul. Extrem de zgomotos — folosește doar pentru depanare.';

  @override
  String get appLogLevelVerboseLabel => 'Verbose';

  @override
  String get appLogLevelWarningDescription =>
      'Adaugă avertismente și probleme recuperabile.';

  @override
  String get appLogLevelWarningLabel => 'Avertisment';

  @override
  String get appearanceLanguage => 'Aspect și limbă';

  @override
  String get apply => 'Aplică';

  @override
  String get approve => 'Aprobă';

  @override
  String get agentApprovalRequired => 'Aprobare necesară';

  @override
  String agentApprovalsMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'încă # în așteptare',
      few: 'încă # în așteptare',
      one: 'încă 1 în așteptare',
    );
    return '$_temp0';
  }

  @override
  String get approved => 'Aprobat';

  @override
  String get articleNoun => 'Articol';

  @override
  String get articlesSubscribed =>
      'Articole din fluxurile la care ești abonat.';

  @override
  String get askAi => 'Întreabă AI';

  @override
  String get askAiReviewDescription => 'Cere AI să revizuiască acest PR';

  @override
  String get assignees => 'Asignați';

  @override
  String get attachImage => 'Atașează imagine';

  @override
  String get attachedAgents => 'Agenți atașați';

  @override
  String get audioInput => 'Intrare audio';

  @override
  String get audioOutput => 'Ieșire audio';

  @override
  String get authenticationToken => 'Token de autentificare';

  @override
  String authoredByLabel(String role) {
    return 'De: $role';
  }

  @override
  String get autoRecommended => 'Auto (recomandat)';

  @override
  String get available => 'Disponibil';

  @override
  String get awaitingYourReview => 'Așteaptă revizuirea ta';

  @override
  String get back => 'Înapoi';

  @override
  String get backLabel => 'Înapoi';

  @override
  String get backend => 'Backend';

  @override
  String get blockAdsTrackers =>
      'Blochează reclame, trackere și bannere de cookie-uri';

  @override
  String get blocking => 'Blochează';

  @override
  String get bookmarkLabel => 'Marcaj';

  @override
  String get briefDescription => 'Descriere scurtă';

  @override
  String get bugLabel => 'Bug';

  @override
  String get bundledDefaultsNeverUpdated =>
      'Implicite incluse — niciodată actualizate';

  @override
  String get cancel => 'Anulează';

  @override
  String get cancelEdit => 'Anulează editarea';

  @override
  String get categoryNavigation => 'Navigare';

  @override
  String get change => 'Schimbă';

  @override
  String get changesRequested => 'Modificări cerute';

  @override
  String get spacesMentionSection => 'Spații';

  @override
  String get checkForUpdates => 'Verifică actualizări';

  @override
  String get checking => 'Se verifică';

  @override
  String get checkingEllipsis => 'Se verifică…';

  @override
  String get chooseAppFont => 'Alege fontul aplicației';

  @override
  String get chooseCodeFont => 'Alege fontul de cod';

  @override
  String get chooseRunner => 'Alege runnerul de agent.';

  @override
  String get clear => 'Golește';

  @override
  String get clickToRetry => 'Apasă pentru a reîncerca';

  @override
  String get close => 'Închide';

  @override
  String get closeEsc => 'Închide (Esc)';

  @override
  String get closeReader => 'Închide cititorul';

  @override
  String get closed => 'Închis';

  @override
  String get codeFont => 'Font de cod';

  @override
  String get codeFontLigatures => 'Ligaturi font de cod';

  @override
  String get codeFontLigaturesDescription =>
      'Afișează ligaturile de programare (=>, !=, ->) ca glife combinate în cod și diff-uri';

  @override
  String get collapse => 'Restrânge';

  @override
  String get commandPalette => 'Paletă de comenzi';

  @override
  String get commandPaletteOrgMembers => 'Membri organizație';

  @override
  String get commandPaletteBrowseTeam => 'Răsfoiește echipa';

  @override
  String get commandPaletteBrowseTeamDesc => 'Vezi toți membrii organizației';

  @override
  String get compactDone =>
      'Conversație compactată. Istoricul anterior a fost pliat într-un rezumat.';

  @override
  String get compactNothing =>
      'Nimic de compactat încă. Conversația e încă scurtă.';

  @override
  String get compactBusy =>
      'Un agent încă lucrează. Compactează după ce turul se termină.';

  @override
  String get compactUnavailable =>
      'Compactarea nu este disponibilă pe acest server.';

  @override
  String get commandsMentionSection => 'Comenzi';

  @override
  String get comment => 'Comentează';

  @override
  String get commentOnThisFile => 'Comentează acest fișier';

  @override
  String get commented => 'A comentat';

  @override
  String get commits => 'Commit-uri';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'Se afișează ultimele $loaded din $total commit-uri';
  }

  @override
  String get prCloneProgressCloningTitle => 'Se clonează depozitul';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'Acest PR modifică $fileCount fișiere, ceea ce depășește limita GitHub API. Se clonează depozitul local…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'Acest PR depășește limita de fișiere a GitHub API. Se clonează depozitul local…';

  @override
  String get prCloneProgressFetchingTitle => 'Se preiau ref-urile PR';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'Se preiau ramura de bază și ref-ul head al PR-ului…';

  @override
  String get prCloneProgressComputingTitle => 'Se calculează diff-ul';

  @override
  String get prCloneProgressComputingSubtitle => 'Se rulează git diff local…';

  @override
  String get prCloneProgressErrorTitle => 'Nu s-a putut încărca diff-ul';

  @override
  String get prCloneProgressErrorSubtitle =>
      'A apărut o eroare la clonare sau la calcularea diff-ului. Încearcă să reîmprospătezi.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'Încă lucrează… $elapsed scurse';
  }

  @override
  String confidenceLabel(int percent) {
    return 'Încredere: $percent%';
  }

  @override
  String get configureAgentIdentities =>
      'Configurează identitățile agenților, prompturile, abilitățile și vezi rulările.';

  @override
  String get configuredLabel => 'Configurat.';

  @override
  String get confirmedBy => 'Confirmat de';

  @override
  String get consensus => 'Consens';

  @override
  String get contentHint => 'Ce ar trebui reținut';

  @override
  String get contentLabel => 'Conținut';

  @override
  String get contentMarkdown => 'Conținut (Markdown)';

  @override
  String get contextWindowSize => 'Dimensiunea ferestrei de context';

  @override
  String modelContextChip(String size) {
    return 'Model · $size';
  }

  @override
  String get continueLabel => 'Continuă';

  @override
  String get conversationMode => 'Mod';

  @override
  String cookieRulesCount(int count) {
    return '$count reguli de cookie-uri';
  }

  @override
  String typeToConfirmPrompt(String value) {
    return 'Tastează $value pentru a confirma.';
  }

  @override
  String get copied => 'Copiat!';

  @override
  String get copy => 'Copiază';

  @override
  String get copyAddress => 'Copiază adresa';

  @override
  String get copyBaseBranchTooltip => 'Copiază numele ramurii de bază';

  @override
  String get copyHeadBranchTooltip => 'Copiază numele ramurii head';

  @override
  String couldNotListDevices(String error) {
    return 'Nu s-au putut lista dispozitivele: $error';
  }

  @override
  String get create => 'Creează';

  @override
  String get createOrSelectWorkspace =>
      'Creează sau selectează un spațiu de lucru înainte de a adăuga depozite.';

  @override
  String get createPullRequest => 'Creează pull request';

  @override
  String get createdByMe => 'Create de mine';

  @override
  String createdLabel(String date) {
    return 'Creat: $date';
  }

  @override
  String get currentParticipants => 'Participanți curenți';

  @override
  String get customSystemPrompt =>
      'Prompt de sistem personalizat pentru acest agent...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'acum # de zile',
      few: 'acum # zile',
      one: 'acum 1 zi',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'Dezactivează';

  @override
  String get delete => 'Șterge';

  @override
  String get deleteAgent => 'Șterge agentul';

  @override
  String deleteAgentConfirm(String name) {
    return 'Ștergi \"$name\"? Acțiunea nu poate fi anulată.';
  }

  @override
  String get deleteSpace => 'Șterge spațiul';

  @override
  String deleteConfirmName(String name) {
    return 'Ștergi \"$name\"?';
  }

  @override
  String get deleteFact => 'Șterge faptul';

  @override
  String get deleteFeedBody =>
      'Elimină fluxul și toate articolele din cache. Articolele marcate din acest flux vor fi și ele eliminate.';

  @override
  String deleteFeedConfirm(String name) {
    return 'Ștergi \"$name\"?';
  }

  @override
  String get deletePolicy => 'Șterge politica';

  @override
  String get deletePolicyConfirm =>
      'Ștergi această politică? Acțiunea nu poate fi anulată.';

  @override
  String deleteTopicConfirm(String topic) {
    return 'Ștergi \"$topic\"? Acțiunea nu poate fi anulată.';
  }

  @override
  String get deleteWorkspace => 'Șterge spațiul de lucru';

  @override
  String get deny => 'Refuză';

  @override
  String get detailsLabel => 'Detalii';

  @override
  String get descriptionLabel => 'Descriere';

  @override
  String detectedBackend(String label) {
    return 'Detectat: $label';
  }

  @override
  String get detectedRunners => 'Runnere detectate';

  @override
  String get detectingAdapters => 'Se detectează adaptorii…';

  @override
  String get detectingInputDevices => 'Se detectează dispozitivele de intrare…';

  @override
  String detectionFailed(String error) {
    return 'Detectarea a eșuat: $error';
  }

  @override
  String get disabled => 'Dezactivat';

  @override
  String get discover => 'Descoperă';

  @override
  String get dismissed => 'Respins';

  @override
  String get domainHint => 'de ex. api-performance';

  @override
  String get domainLabel => 'Domeniu';

  @override
  String get download => 'Descarcă';

  @override
  String get downloadingLabel => 'Se descarcă';

  @override
  String downloadingModel(int pct) {
    return 'Se descarcă modelul… $pct%';
  }

  @override
  String get draft => 'Ciornă';

  @override
  String get draftLabel => 'Ciornă';

  @override
  String get edit => 'Editează';

  @override
  String get edited => 'editat';

  @override
  String get editMessage => 'Editează mesajul';

  @override
  String get revertToThere => 'Revino acolo';

  @override
  String get sendAsNewMessage => 'Trimite ca mesaj nou';

  @override
  String get editMessageChoiceBody =>
      'Revenirea ascunde mesajele de după acesta și readuce fișierele agentului. Poți anula asta. Trimiterea ca mesaj nou lasă conversația neschimbată.';

  @override
  String get deleteMessage => 'Șterge mesajul';

  @override
  String get deleteMessageConfirm =>
      'Ștergi acest mesaj? Acțiunea nu poate fi anulată.';

  @override
  String get messageDeleted => 'Mesaj șters';

  @override
  String get searchInConversation => 'Caută în conversație';

  @override
  String get searchMessagesHint => 'Caută mesaje…';

  @override
  String get noMessagesFound => 'Niciun mesaj găsit';

  @override
  String get editFact => 'Editează faptul';

  @override
  String get editPolicy => 'Editează politica';

  @override
  String get editSuggestedCodeHint => 'Editează codul sugerat…';

  @override
  String get editSuggestion => 'Editează sugestia';

  @override
  String get egArchitect => 'de ex. architect';

  @override
  String get egControlCenter => 'de ex. control-center';

  @override
  String get egPlatform => 'de ex. Platform';

  @override
  String get egSamuelAlev => 'de ex. SamuelAlev';

  @override
  String get egSoftwareArchitect => 'de ex. Software Architect';

  @override
  String get egTheVerge => 'de ex. The Verge';

  @override
  String get egTokenLimit => 'de ex. 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'Instalarea a eșuat: $error';
  }

  @override
  String get embeddingInstalled =>
      'Modelul local de embedding este instalat. Căutarea hibridă este activată.';

  @override
  String get embeddingModel => 'Model de embedding (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'Neinstalat. Căutarea revine la doar cuvinte-cheie până la activare.';

  @override
  String get embeddingRedownloadBody =>
      'Fișierele modelului existente vor fi șterse și descărcate din nou. Căutarea semantică va fi indisponibilă până la finalizarea descărcării.';

  @override
  String get embeddingRemoveBody =>
      'Căutarea semantică va fi dezactivată până o reinstalezi. O poți instala din nou oricând.';

  @override
  String get speakerDiarization => 'Diarizare vorbitori';

  @override
  String get diarizationModel => 'Model de diarizare';

  @override
  String get diarizationInstalled =>
      'Instalat — numește vorbitorii individuali în transcrierile întâlnirilor';

  @override
  String get diarizationNotInstalled =>
      'Neinstalat — vorbitorii din întâlniri nu vor fi separați';

  @override
  String diarizationInstallFailed(String error) {
    return 'Instalarea a eșuat: $error';
  }

  @override
  String get redownloadDiarizationModel => 'Redescarcă modelul de diarizare';

  @override
  String get diarizationRedownloadBody =>
      'Elimină modelele de diarizare curente și le descarcă din nou.';

  @override
  String get removeDiarizationModel => 'Elimină modelul de diarizare';

  @override
  String get diarizationRemoveBody =>
      'Șterge modelele de diarizare de pe dispozitiv. Transcrierile de întâlniri deja produse nu sunt afectate.';

  @override
  String get enableNotifications => 'Activează notificările';

  @override
  String get enableSandboxing => 'Activează sandboxing-ul';

  @override
  String get enabled => 'Activat';

  @override
  String errorCreatingAgent(String error) {
    return 'Eroare la crearea agentului: $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'Eroare la ștergerea agentului: $error';
  }

  @override
  String errorWithDetail(String error) {
    return 'Eroare: $error';
  }

  @override
  String get expand => 'Extinde';

  @override
  String extractingModel(int pct) {
    return 'Se extrage modelul… $pct%';
  }

  @override
  String get fact => 'Fapt';

  @override
  String factCount(int count) {
    return '$count fapt';
  }

  @override
  String factCountPlural(int count) {
    return '$count fapte';
  }

  @override
  String get facts => 'Fapte';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount fapte · $policyCount politici';
  }

  @override
  String get failed => 'Eșuat';

  @override
  String failedToDispatch(String error) {
    return 'Nu s-a putut trimite: $error';
  }

  @override
  String get failedToLoad => 'Nu s-a putut încărca';

  @override
  String failedToLoadAgents(String error) {
    return 'Nu s-au putut încărca agenții: $error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'Nu s-au putut încărca fluxurile: $error';
  }

  @override
  String get failedToLoadGifs => 'Nu s-au putut încărca GIF-urile';

  @override
  String failedToLoadLogs(String error) {
    return 'Nu s-au putut încărca jurnalele: $error';
  }

  @override
  String get failedToLoadRepos => 'Nu s-au putut încărca depozitele';

  @override
  String get failedToLoadWorkspaces =>
      'Nu s-au putut încărca spațiile de lucru';

  @override
  String failedToStartAiReview(String error) {
    return 'Nu s-a putut porni revizuirea AI: $error';
  }

  @override
  String get failedToStartMicTest => 'Nu s-a putut porni testul microfonului.';

  @override
  String failedToSubmitReview(String error) {
    return 'Nu s-a putut trimite revizuirea: $error';
  }

  @override
  String failedToUpload(String name, String error) {
    return 'Nu s-a putut încărca $name: $error';
  }

  @override
  String failedWithError(String error) {
    return 'Eșuat: $error';
  }

  @override
  String get failure => 'Eșec';

  @override
  String get feedAlreadyExists => 'Un flux cu acest URL există deja.';

  @override
  String get feedUrlExample => 'de ex. https://example.com/feed.xml';

  @override
  String get feedUrlLabel => 'URL flux';

  @override
  String feedsCount(int count) {
    return 'Fluxuri ($count)';
  }

  @override
  String get filesChanged => 'Fișiere modificate';

  @override
  String filesCount(int count) {
    return '$count fișier(e)';
  }

  @override
  String get filesMentionSection => 'Fișiere';

  @override
  String get filterAgents => 'Filtrează agenții...';

  @override
  String get filterFilesHint => 'Filtrează fișierele…';

  @override
  String get filterLists => 'Liste de filtre';

  @override
  String get filterSkillsPlaceholder => 'Filtrează abilitățile…';

  @override
  String get finish => 'Finalizează';

  @override
  String get fix => 'Repară';

  @override
  String get forward => 'Înainte';

  @override
  String get general => 'General';

  @override
  String get githubLink => 'Link GitHub';

  @override
  String get claudeStatusFetchFailed => 'Nu s-a putut atinge status.claude.com';

  @override
  String get claudeStatusOpenInBrowser => 'Deschide status.claude.com';

  @override
  String get githubStatusFetchFailed => 'Nu s-a putut atinge githubstatus.com';

  @override
  String get githubDegradedTitle => 'GitHub raportează probleme';

  @override
  String githubDegradedStatusLine(String status) {
    return 'Stare GitHub: $status.';
  }

  @override
  String githubDegradedBody(String status) {
    return 'Stare GitHub: $status. Datele de pull request pot fi învechite sau incomplete până la recuperare.';
  }

  @override
  String get githubStatusOpenInBrowser => 'Deschide githubstatus.com';

  @override
  String get githubStatusRefresh => 'Reîmprospătează';

  @override
  String githubStatusUpdated(String time) {
    return 'Actualizat $time';
  }

  @override
  String get kimiStatusFetchFailed => 'Nu s-a putut atinge status.moonshot.cn';

  @override
  String get kimiStatusOpenInBrowser => 'Deschide status.moonshot.cn';

  @override
  String get openaiStatusFetchFailed => 'Nu s-a putut atinge status.openai.com';

  @override
  String get openaiStatusOpenInBrowser => 'Deschide status.openai.com';

  @override
  String get serviceStatusMaintenance => 'Mentenanță';

  @override
  String get serviceStatusMajorIssues => 'Probleme majore';

  @override
  String get serviceStatusMinorIssues => 'Probleme minore';

  @override
  String get serviceStatusOperational => 'Operațional';

  @override
  String get serviceStatusOutage => 'Întrerupere';

  @override
  String serviceStatusOverflowCount(int count) {
    return '$count+';
  }

  @override
  String get serviceStatusTitle => 'Starea serviciilor';

  @override
  String get serviceStatusUnknown => 'Necunoscut';

  @override
  String lastChecked(String time) {
    return 'Verificat $time';
  }

  @override
  String get lastCheckedRecently => 'Verificat recent';

  @override
  String get giveYourWorkAHome => 'Oferă muncii tale un cămin.';

  @override
  String get goBack => 'Mergi înapoi';

  @override
  String get goForward => 'Mergi înainte';

  @override
  String get googleFonts => 'Google fonts';

  @override
  String get high => 'Ridicat';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'acum # de ore',
      few: 'acum # ore',
      one: 'acum 1 oră',
    );
    return '$_temp0';
  }

  @override
  String get sidebarAgeNow => 'acum';

  @override
  String sidebarAgeMinutes(int count) {
    return '$count min';
  }

  @override
  String sidebarAgeHours(int count) {
    return '$count h';
  }

  @override
  String sidebarAgeDays(int count) {
    return '$count z';
  }

  @override
  String sidebarAgeMonths(int count) {
    return '$count luni';
  }

  @override
  String sidebarAgeYears(int count) {
    return '$count ani';
  }

  @override
  String get images => 'Imagini';

  @override
  String get inactive => 'Inactiv';

  @override
  String get install => 'Instalează';

  @override
  String installedVersion(String version) {
    return 'Instalat $version';
  }

  @override
  String get invite => 'Invită';

  @override
  String get inviteAgent => 'Invită agent';

  @override
  String get isolateAgentExecution => 'Izolează execuția agenților.';

  @override
  String get justNow => 'Chiar acum';

  @override
  String get keepSandboxing => 'Păstrează sandboxing-ul';

  @override
  String get keybindingAddRepository => 'Adaugă depozit';

  @override
  String get keybindingCommandPalette => 'Paletă de comenzi';

  @override
  String get keybindingFocusSearch => 'Focalizează căutarea';

  @override
  String get keybindingNewAgent => 'Agent nou';

  @override
  String get keybindingNewWorkspace => 'Spațiu de lucru nou';

  @override
  String get keybindingNextArticle => 'Articolul următor';

  @override
  String get keybindingNextSpace => 'Spațiul următor';

  @override
  String get keybindingNextWorkspace => 'Spațiul de lucru următor';

  @override
  String get keybindingOpenArticle => 'Deschide articolul';

  @override
  String get keybindingOpenPr => 'Deschide PR';

  @override
  String get keybindingOpenSettings => 'Deschide setările';

  @override
  String get keybindingOpenWorkspace => 'Deschide spațiul de lucru';

  @override
  String get keybindingPreviousArticle => 'Articolul anterior';

  @override
  String get keybindingPreviousSpace => 'Spațiul anterior';

  @override
  String get keybindingPreviousWorkspace => 'Spațiul de lucru anterior';

  @override
  String get keybindingRefresh => 'Reîmprospătează';

  @override
  String get keybindingSendMessage => 'Trimite mesajul';

  @override
  String get keybindingToggleBookmark => 'Comută marcajul';

  @override
  String get keybindingToggleTheme => 'Comută tema';

  @override
  String get keybindingToggleWorkspaceSwitcher =>
      'Comută selectorul de spații de lucru';

  @override
  String get keybindingWorkspace1 => 'Spațiu de lucru 1';

  @override
  String get keybindingWorkspace2 => 'Spațiu de lucru 2';

  @override
  String get keybindingWorkspace3 => 'Spațiu de lucru 3';

  @override
  String get keybindingWorkspace4 => 'Spațiu de lucru 4';

  @override
  String get keybindingWorkspace5 => 'Spațiu de lucru 5';

  @override
  String get keybindingWorkspace6 => 'Spațiu de lucru 6';

  @override
  String get keybindingWorkspace7 => 'Spațiu de lucru 7';

  @override
  String get keybindingWorkspace8 => 'Spațiu de lucru 8';

  @override
  String get keybindingWorkspace9 => 'Spațiu de lucru 9';

  @override
  String get killRunning => 'Oprește forțat ce rulează';

  @override
  String get languageSystem => 'Sistem';

  @override
  String get leaveACommentEllipsis => 'Lasă un comentariu…';

  @override
  String get legendLabel => 'Legendă';

  @override
  String get lessLabel => 'Mai puțin';

  @override
  String get letsPluginTools => 'Hai să-ți conectăm instrumentele.';

  @override
  String get level => 'Nivel';

  @override
  String get loadingAgents => 'Se încarcă agenții…';

  @override
  String get loadingModels => 'Se încarcă modelele…';

  @override
  String get loadingProviders => 'Se încarcă providerii…';

  @override
  String get logLevel => 'Nivel jurnal';

  @override
  String get logs => 'Jurnale';

  @override
  String get low => 'Scăzut';

  @override
  String get maintenance => 'Mentenanță';

  @override
  String get manageParticipants => 'Gestionează participanții';

  @override
  String get manageWorkspaces => 'Gestionează spațiile de lucru';

  @override
  String get reorderWorkspace => 'Reordonează spațiul de lucru';

  @override
  String get matchOsAppearance =>
      'Potrivește aspectul OS-ului sau alege un mod fix.';

  @override
  String get mcpNotAvailableOnServer =>
      'Controlul serverului MCP nu este disponibil pe serverul conectat.';

  @override
  String get modelManagedOnServer =>
      'Acest model rulează pe gazda serverului și este gestionat acolo.';

  @override
  String get mcpServer => 'Server MCP';

  @override
  String get medium => 'Mediu';

  @override
  String get memoryDataHint =>
      'Faptele și politicile vor apărea aici pe măsură ce agenții lucrează.';

  @override
  String get memoryLabel => 'Memorie';

  @override
  String get merge => 'Fuzionează';

  @override
  String get merged => 'Fuzionat';

  @override
  String get messagePlaceholder =>
      'Mesaj… (@ pentru mențiuni, / pentru comenzi)';

  @override
  String get navConversations => 'Spații';

  @override
  String get microphonePermissionDenied =>
      'Permisiunea pentru microfon a fost refuzată.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'acum # de minute',
      few: 'acum # minute',
      one: 'acum 1 minut',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'Model';

  @override
  String get modified => 'Modificat';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'acum # de luni',
      few: 'acum # luni',
      one: 'acum 1 lună',
    );
    return '$_temp0';
  }

  @override
  String get moreLabel => 'Mai mult';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'Nume';

  @override
  String get nameAndTitleRequired => 'Numele și titlul sunt obligatorii.';

  @override
  String get nameAndUrlRequired => 'Numele și URL-ul sunt obligatorii';

  @override
  String get nameLabel => 'Nume';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'Sandbox-ul nativ este disponibil pe $platform.';
  }

  @override
  String get nativeSandboxNeedsInstall =>
      'Este necesară instalarea sandbox-ului nativ';

  @override
  String get navObservability => 'Observabilitate';

  @override
  String get navSettings => 'Setări';

  @override
  String get exitSettings => 'Ieșire din setări';

  @override
  String networkBlockCount(int count) {
    return '$count blocări de rețea';
  }

  @override
  String get neutral => 'Neutru';

  @override
  String get newCommitsPushed =>
      'S-au făcut push de commit-uri noi — apasă pentru a reîncărca diff-ul';

  @override
  String get newFact => 'Fapt nou';

  @override
  String get newPolicy => 'Politică nouă';

  @override
  String get newsfeed => 'Flux de știri';

  @override
  String get newsfeedLabel => 'Flux de știri';

  @override
  String get newsfeedSettingsDescription =>
      'Gestionează fluxurile la care ești abonat și preferințele cititorului.';

  @override
  String get newsfeedSettingsTitle => 'Setări flux de știri';

  @override
  String get nextMatch => 'Potrivirea următoare (↵)';

  @override
  String get noActiveWorkspace =>
      'Niciun spațiu de lucru activ sau depozit selectat.';

  @override
  String get noActiveWorkspaceCreate => 'Niciun spațiu de lucru activ';

  @override
  String get noActiveWorkspaceGithub =>
      'Niciun spațiu de lucru activ cu un depozit GitHub.';

  @override
  String get noAgents => 'Niciun agent';

  @override
  String get noArticlesYet => 'Niciun articol încă';

  @override
  String get noArticlesYetBody =>
      'Articolele din fluxurile tale vor apărea aici.';

  @override
  String get noExecutionLogsYet => 'Niciun jurnal de execuție încă';

  @override
  String get noFacts => 'Niciun fapt încă';

  @override
  String get noFeedsYet => 'Niciun flux încă';

  @override
  String get noFileAnchor =>
      'Nicio ancoră de fișier — nu se poate posta un comentariu inline.';

  @override
  String get noFileChangesInScope =>
      'Nicio modificare de fișier în acest domeniu';

  @override
  String get noGifsFound => 'Niciun GIF găsit';

  @override
  String get noInputDevicesDetected =>
      'Niciun dispozitiv de intrare detectat — se folosește implicitul sistemului.';

  @override
  String get noMatchingFiles => 'Niciun fișier potrivit';

  @override
  String get noMatchingGoogleFonts => 'Niciun Google Fonts potrivit.';

  @override
  String get noMemoryData => 'Nicio dată de memorie încă';

  @override
  String get noMessagesYet => 'Niciun mesaj încă';

  @override
  String get noModelsAdvertised => 'Niciun model anunțat de acest adaptor.';

  @override
  String get noOpenPullRequests => 'Niciun pull request deschis';

  @override
  String get noPolicies => 'Nicio politică încă';

  @override
  String get noReposInWorkspaceYet =>
      'Niciun depozit în acest spațiu de lucru încă';

  @override
  String get noRunnersDetected =>
      'Niciun runner detectat încă. Reîmprospătează ca să scanezi din nou.';

  @override
  String get noSavedArticles => 'Niciun articol salvat';

  @override
  String get noSavedArticlesBody =>
      'Articolele pe care le salvezi vor apărea aici.';

  @override
  String get noSystemFonts => 'Niciun font de sistem detectat.';

  @override
  String get noWorkingMemory => 'Nicio notă de memorie de lucru încă.';

  @override
  String get noneAllRoles => 'Niciunul (toate rolurile)';

  @override
  String get notAvailable => 'Indisponibil';

  @override
  String get notConfiguredLabel => 'Neconfigurat.';

  @override
  String get notFoundLabel => 'Negăsit';

  @override
  String get notes => 'Note';

  @override
  String get notificationAgentFinished => 'Agentul a terminat';

  @override
  String get notificationPrMentioned => 'Menționat într-un pull request';

  @override
  String get notificationNewMessages => 'Mesaje noi';

  @override
  String get notificationPrMerged => 'PR fuzionat';

  @override
  String get notificationPrPublished => 'PR publicat';

  @override
  String get notificationReviewRequested => 'Revizuire solicitată';

  @override
  String get notifications => 'Notificări';

  @override
  String get notifyAgentRunCompleted =>
      'Notifică când un agent finalizează o rulare.';

  @override
  String get notifyPrMentioned =>
      'Notifică când ești menționat într-un pull request.';

  @override
  String get notifyNewMessages =>
      'Notifică când ești menționat într-un spațiu.';

  @override
  String get notifyPrMerged => 'Notifică când un pull request este fuzionat.';

  @override
  String get notifyPrPublished =>
      'Notifică când un agent publică un pull request.';

  @override
  String get notifyReviewRequested =>
      'Notifică când ți se cere revizuirea unui pull request.';

  @override
  String get notificationReviewStale => 'Revizuire învechită';

  @override
  String get notifyReviewStale =>
      'Când ajung commit-uri noi pe un pull request pe care l-ai revizuit deja';

  @override
  String get notificationPrMergeReadiness => 'Gata de fuziune';

  @override
  String get notifyPrMergeReadiness =>
      'Notifică când un pull request creat de tine devine fuzionabil sau nu mai este.';

  @override
  String get notificationPrReviewDecision => 'Decizii de revizuire';

  @override
  String get notifyPrReviewDecision =>
      'Notifică când un recenzent aprobă, cere modificări sau i se respinge o aprobare.';

  @override
  String get notificationPrChecksStatus => 'Verificări';

  @override
  String get notifyPrChecksStatus =>
      'Notifică când CI eșuează pe un pull request creat de tine și când se recuperează.';

  @override
  String get notificationPrThreadActivity => 'Fire de revizuire';

  @override
  String get notifyPrThreadActivity =>
      'Notifică când cineva răspunde sau rezolvă un fir în care ești.';

  @override
  String get notificationPrReadyToMerge => 'Gata de fuziune';

  @override
  String notificationPrReadyToMergeBody(String prTitle) {
    return '$prTitle are tot ce îi trebuie.';
  }

  @override
  String get notificationPrMergeBlocked => 'Nu mai este fuzionabil';

  @override
  String notificationPrMergeBlockedBodyConflicts(String prTitle) {
    return '$prTitle are conflicte cu ramura de bază.';
  }

  @override
  String notificationPrMergeBlockedBodyBehind(String prTitle) {
    return '$prTitle este în urmă față de ramura de bază.';
  }

  @override
  String notificationPrMergeBlockedBodyReviews(String prTitle) {
    return '$prTitle așteaptă o revizuire obligatorie.';
  }

  @override
  String notificationPrMergeBlockedBodyChanges(String prTitle) {
    return 'Un recenzent a cerut modificări pe $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyChecks(String prTitle) {
    return 'Verificările eșuează pe $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyOther(String prTitle) {
    return '$prTitle nu mai poate fi fuzionat.';
  }

  @override
  String get notificationPrApproved => 'Pull request aprobat';

  @override
  String notificationPrApprovedBodyBy(String login, String prTitle) {
    return '$login a aprobat $prTitle';
  }

  @override
  String notificationPrApprovedBody(String prTitle) {
    return '$prTitle a fost aprobat';
  }

  @override
  String notificationPrReviewersRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de recenzenți mai trebuie să răspundă',
      few: '# recenzenți mai trebuie să răspundă',
      one: '1 recenzent mai trebuie să răspundă',
      zero: 'niciun recenzent rămas',
    );
    return '$_temp0';
  }

  @override
  String get notificationPrChangesRequested => 'Modificări cerute';

  @override
  String notificationPrChangesRequestedBodyBy(String login, String prTitle) {
    return '$login a cerut modificări pe $prTitle';
  }

  @override
  String notificationPrChangesRequestedBody(String prTitle) {
    return 'S-au cerut modificări pe $prTitle';
  }

  @override
  String get notificationPrReviewDismissed => 'Aprobare respinsă';

  @override
  String notificationPrReviewDismissedBody(String prTitle) {
    return '$prTitle trebuie revizuit din nou.';
  }

  @override
  String get notificationPrChecksFailed => 'Verificări eșuate';

  @override
  String notificationPrChecksFailedBody(String checkName, String prTitle) {
    return '$checkName a eșuat pe $prTitle';
  }

  @override
  String notificationPrChecksFailedBodyUnnamed(String prTitle) {
    return 'Verificările eșuează pe $prTitle';
  }

  @override
  String get notificationPrChecksRecovered => 'Verificări reușite';

  @override
  String notificationPrChecksRecoveredBody(String prTitle) {
    return '$prTitle este din nou verde.';
  }

  @override
  String notificationPrMentionedInCommentBody(String login, String location) {
    return '$login te-a menționat în $location';
  }

  @override
  String get notificationPrThreadReplied => 'Răspuns nou';

  @override
  String notificationPrThreadRepliedBody(String login, String location) {
    return '$login a răspuns în $location';
  }

  @override
  String get notificationPrThreadResolved => 'Fir rezolvat';

  @override
  String notificationPrThreadResolvedBody(String location) {
    return 'Firul tău din $location a fost rezolvat.';
  }

  @override
  String get notificationGroupAgents => 'Agenți';

  @override
  String get notificationGroupPullRequests => 'Pull request-uri';

  @override
  String get notificationGroupMessages => 'Mesaje';

  @override
  String get notificationGroupTickets => 'Tichete';

  @override
  String get notificationGroupCalendar => 'Calendar';

  @override
  String get notificationGroupMachines => 'Mașini';

  @override
  String get notificationSectionSound => 'Sunet';

  @override
  String get notificationSectionSchedule => 'Program';

  @override
  String get notificationSectionEvents => 'Evenimente';

  @override
  String get notificationsMutedRepos => 'Depozite dezactivate';

  @override
  String notificationsMutedReposCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de depozite dezactivate',
      few: '# depozite dezactivate',
      one: '1 depozit dezactivat',
      zero: 'Niciun depozit dezactivat',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMuteRepo => 'Dezactivează acest depozit';

  @override
  String get onboardingLinuxDescription =>
      'Control Center poate folosi containere Linux pentru a izola execuția agenților.';

  @override
  String get onboardingMacosDescription =>
      'Control Center folosește sandbox-ul nativ pe macOS pentru a izola execuția agenților.';

  @override
  String get onboardingUnsupportedDescription =>
      'Sandbox-ul nu este disponibil pe această platformă. Execuția agenților va fi fără izolare.';

  @override
  String get openArticlesInApp => 'Deschide articolele în aplicație';

  @override
  String get openInBrowser => 'Deschide în browser';

  @override
  String get openedInYourBrowser => 'Deschis în browser.';

  @override
  String get openLabel => 'Deschis';

  @override
  String get openOnGithub => 'Deschide pe GitHub';

  @override
  String get openStatus => 'Deschis';

  @override
  String get optionalPersonaDescription => 'Descriere opțională a personajului';

  @override
  String get otherLabel => 'Altele';

  @override
  String get ownerOrganization => 'Proprietar / organizație';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get passed => 'Reușit';

  @override
  String get pasteValueHere => 'Lipește valoarea aici';

  @override
  String get persona => 'Personaj';

  @override
  String get policies => 'Politici';

  @override
  String get policiesHint =>
      'Politicile vor apărea aici odată ce agenții promovează fapte.';

  @override
  String get policy => 'Politică';

  @override
  String get popular => 'Populare';

  @override
  String get port => 'Port';

  @override
  String get postingEllipsis => 'Se postează…';

  @override
  String get prCommits => 'Commit-uri';

  @override
  String get prMergedBody => 'Un pull request a fost fuzionat';

  @override
  String get prMoreActions => 'Mai multe acțiuni';

  @override
  String get prTitle => 'Titlu PR';

  @override
  String get reviewCommentHint =>
      'Apasă pur și simplu pe aprobă, sau dacă ești în dispoziție adaugă un comentariu sau o reacție…';

  @override
  String get nothingToPreview => 'Nimic de previzualizat';

  @override
  String get previousMatch => 'Potrivirea anterioară (⇧↵)';

  @override
  String get priorityReviewsDescription =>
      'Revizuiri prioritare și prezentare depozit.';

  @override
  String get prsCreated => 'PR-uri create';

  @override
  String get prsMerged => 'PR-uri fuzionate';

  @override
  String get publishToGithub => 'Publică pe GitHub';

  @override
  String get published => 'Publicat';

  @override
  String get pullRequestApproved => 'Pull request aprobat';

  @override
  String get pullRequests => 'Pull request-uri';

  @override
  String get questionLabel => 'Întrebare';

  @override
  String get queued => 'În coadă';

  @override
  String get react => 'Reacționează';

  @override
  String get readerPreferences => 'Preferințe cititor';

  @override
  String get reasoningEffort => 'Efort de raționament';

  @override
  String get recommendLabel => 'Recomandă';

  @override
  String recordingFromDevice(String device) {
    return 'Se înregistrează de pe $device.';
  }

  @override
  String get redownload => 'Redescarcă';

  @override
  String get redownloadEmbeddingModel => 'Redescarci modelul de embedding?';

  @override
  String get redownloadVoiceModel => 'Redescarci modelul vocal?';

  @override
  String get refinePlan => 'Rafinează planul';

  @override
  String get refresh => 'Reîmprospătează';

  @override
  String get refreshAll => 'Reîmprospătează tot';

  @override
  String get refreshAllFeeds => 'Reîmprospătează toate fluxurile';

  @override
  String get reject => 'Respinge';

  @override
  String get rejected => 'Respins';

  @override
  String get reload => 'Reîncarcă';

  @override
  String get remove => 'Elimină';

  @override
  String get removeBookmark => 'Elimină marcajul';

  @override
  String get removeEmbeddingModel => 'Elimini modelul de embedding?';

  @override
  String get removeLogo => 'Elimină logo-ul';

  @override
  String get removeRepoFromWorkspace =>
      'Elimini depozitul din spațiul de lucru?';

  @override
  String get removeVoiceModel => 'Elimini modelul vocal?';

  @override
  String get removed => 'Eliminat';

  @override
  String get renamed => 'Redenumit';

  @override
  String get reopen => 'Redeschide';

  @override
  String get resolve => 'Rezolvă';

  @override
  String get replyEllipsis => 'Răspunde…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$name va fi eliminat din acest spațiu de lucru. Fișierele locale de pe disc nu sunt atinse.';
  }

  @override
  String get repoNoAccessBadge => 'Fără acces';

  @override
  String get reportsTo => 'Raportează către';

  @override
  String reposCount(int count) {
    return 'Depozite ($count)';
  }

  @override
  String get reposDescription =>
      'Checkout-urile locale pe care le vizează acest spațiu de lucru.';

  @override
  String get repositories => 'Depozite';

  @override
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de depozite',
      few: '# depozite',
      one: '1 depozit',
    );
    return 'Nu s-au putut adăuga $_temp0: $error';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de depozite adăugate',
      few: '# depozite adăugate',
      one: 'Depozit adăugat',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => 'Setări depozite';

  @override
  String get repositoryName => 'Nume depozit';

  @override
  String get requestChanges => 'Cere modificări';

  @override
  String get requested => 'Solicitat';

  @override
  String get requestedChanges => 'Modificări solicitate';

  @override
  String requiredRoleLabel(String role) {
    return 'Rol obligatoriu: $role';
  }

  @override
  String get requiredRoleOptional => 'Rol obligatoriu (opțional)';

  @override
  String get requirements => 'Cerințe';

  @override
  String get reset => 'Resetează';

  @override
  String get resolved => 'Rezolvat';

  @override
  String get enclosedTerminalTitle => 'Terminal izolat';

  @override
  String get enclosedTerminalStart => 'Deschide shell-ul';

  @override
  String get enclosedTerminalStartHint =>
      'Acest shell rulează în VM-ul de unică folosință al acestei conversații. Pornește când îl deschizi, nu când pornește aplicația.';

  @override
  String get terminalStreamReconnecting => 'flux întrerupt — se reconectează…';

  @override
  String get terminalStreamError => 'eroare de flux:';

  @override
  String get terminalShellExited => 'shell-ul s-a închis';

  @override
  String get restartShell => 'Repornește shell-ul';

  @override
  String get retry => 'Reîncearcă';

  @override
  String get review => 'Revizuire';

  @override
  String get reviewedByMe => 'Revizuite de mine';

  @override
  String get reviewers => 'Recenzenți';

  @override
  String get roleLabel => 'Rol';

  @override
  String get ruleHint => 'Regula politicii (Markdown acceptat)';

  @override
  String get ruleLabel => 'Regulă';

  @override
  String get running => 'În rulare';

  @override
  String get runningLabel => 'în rulare';

  @override
  String get runs => 'Rulări';

  @override
  String get runsLabel => 'Rulări';

  @override
  String get sandboxBackendNativeLabel => 'Sandbox nativ';

  @override
  String get sandboxBackendMicrovmLabel => 'VM izolată';

  @override
  String get sandboxBackendNoneLabel => 'Fără izolare';

  @override
  String get sandboxLinuxInstall =>
      'Sandbox-ul nativ pe Linux/WSL2 folosește bubblewrap. Instalează cu:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'Sandbox-ul nativ este inclus pe macOS — folosește Apple Seatbelt (`sandbox-exec`). Nu e nevoie de instalare.';

  @override
  String get sandboxUnsupported =>
      'Sandbox-ul nativ nu este încă suportat pe această platformă. Revine la \"Fără izolare\".';

  @override
  String get sandboxingDisabledDescription =>
      'Agenții rulează direct pe gazdă, cu tot mediul — nerecomandat.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'Toate invocările de agenți trec prin $backend.';
  }

  @override
  String get save => 'Salvează';

  @override
  String get saveChanges => 'Salvează modificările';

  @override
  String get adapterArguments => 'Argumente extra';

  @override
  String get adapterArgumentsHint =>
      'Flag-uri CLI suplimentare (de ex. --yolo)';

  @override
  String get addVariable => 'Adaugă variabilă';

  @override
  String get environmentVariables => 'Variabile de mediu';

  @override
  String get environmentVariablesDescription =>
      'Variabile de mediu personalizate transmise acestui adaptor (de ex. chei API). Stocate în keychain.';

  @override
  String get variableKey => 'Cheie';

  @override
  String get variableValue => 'Valoare';

  @override
  String get savingEllipsis => 'Se salvează…';

  @override
  String get scopeDiffToCommits =>
      'Limitează diff-ul la commit-uri — Shift-click pentru interval';

  @override
  String get noPrsMatchSearch => 'Niciun pull request potrivit';

  @override
  String get searchFactsHint => 'Caută fapte...';

  @override
  String get searchFonts => 'Caută fonturi…';

  @override
  String get searchGifs => 'Caută GIF-uri';

  @override
  String get searchGifsHint => 'Caută pe KLIPY';

  @override
  String get searchInDiffHint => 'Caută în diff…';

  @override
  String get searchOrTypeModel => 'Caută sau tastează un nume de model…';

  @override
  String get searchPlaceholder => 'Caută…';

  @override
  String get searching => 'Se caută…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'acum # de secunde',
      few: 'acum # secunde',
      one: 'acum 1 secundă',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'Selectează adaptorul';

  @override
  String get selectAdapterFirst => 'Selectează mai întâi un adaptor';

  @override
  String get selectAgentToReportTo =>
      'Selectează agentul către care raportează…';

  @override
  String get selectAnAgent => 'Selectează un agent';

  @override
  String get selectConversation => 'Selectează o conversație';

  @override
  String get selectLabel => 'Selectează';

  @override
  String get selectRunner => 'Selectează un runner';

  @override
  String get semanticSearch => 'Căutare semantică';

  @override
  String get send => 'Trimite';

  @override
  String get sendFirstMessage => 'Trimite primul mesaj';

  @override
  String get sendMessage => 'Trimite mesajul';

  @override
  String sentFindingsToAgent(int count) {
    return 'S-au trimis $count constatare(ări) către agent.';
  }

  @override
  String setGithubLinkDescription(String name) {
    return 'Setează proprietarul GitHub și numele depozitului pentru $name. Se folosește pentru a rezolva referințele la PR-uri și issue-uri precum #123 în conținutul Markdown.';
  }

  @override
  String get setLabel => 'Setează';

  @override
  String get settingsLabel => 'Setări';

  @override
  String get settingsLanguage => 'Limbă';

  @override
  String get settingsLanguageDescription => 'Alege limba aplicației.';

  @override
  String get showNativeNotifications =>
      'Afișează notificări de sistem pentru evenimente.';

  @override
  String get showSuperseded => 'Afișează înlocuite';

  @override
  String get signedIn => 'Autentificat.';

  @override
  String signedInAs(String username) {
    return 'Autentificat ca $username.';
  }

  @override
  String get skillNameRequired => 'Numele abilității este obligatoriu.';

  @override
  String skillSaved(String name) {
    return 'Abilitatea \"$name\" a fost salvată.';
  }

  @override
  String get skillsSourcesTab => 'Surse';

  @override
  String get skillSourcesDisclaimer =>
      'Abilitățile se instalează din depozite GitHub pe care le adaugi. Metadatele depozitului sunt neîncrezute — scanarea antivirus este semnalul real de siguranță.';

  @override
  String get skillSourcesEmpty => 'Niciun depozit de abilități';

  @override
  String get skillSourcesEmptyHint =>
      'Adaugă un depozit GitHub ca să-i răsfoiești abilitățile.';

  @override
  String get skillSourceAdd => 'Adaugă depozit';

  @override
  String get skillSourceAddTitle => 'Adaugă depozit de abilități';

  @override
  String get skillSourceAddHint => 'https://github.com/owner/repo';

  @override
  String get skillSourceInvalidUrl =>
      'Introdu un URL de depozit GitHub (https://github.com/owner/repo).';

  @override
  String skillSourceAdded(String repo) {
    return 'Depozitul $repo a fost adăugat.';
  }

  @override
  String skillSourceAlreadyAdded(String repo) {
    return 'Depozitul $repo este deja adăugat.';
  }

  @override
  String skillSourceRemoved(String repo) {
    return 'Depozitul $repo a fost eliminat.';
  }

  @override
  String get skillSourceRemove => 'Elimină';

  @override
  String skillSourceRemoveConfirmTitle(String repo) {
    return 'Elimini $repo?';
  }

  @override
  String get skillSourceRemoveConfirmBody =>
      'Abilitățile instalate rămân instalate. Se elimină doar catalogul depozitului.';

  @override
  String get skillSourceNoSkills =>
      'Nicio abilitate găsită în acest depozit (o abilitate este un director care conține un SKILL.md).';

  @override
  String get skillSourceRefresh => 'Reîmprospătează';

  @override
  String get skillSourceInstalledBadge => 'Instalat';

  @override
  String get skillSourceUpdateBadge => 'Actualizare disponibilă';

  @override
  String get skillSourceSlugTaken => 'Nume folosit';

  @override
  String skillSourceFilesCount(num count) {
    return '$count fișiere';
  }

  @override
  String get skillSourceReadme => 'README';

  @override
  String get skillSourceNoReadme => 'Această abilitate nu are README.';

  @override
  String get skillSourceNoMatches =>
      'Nicio abilitate nu se potrivește filtrului tău.';

  @override
  String get skillUpdateAction => 'Actualizează';

  @override
  String get skillUninstallAction => 'Dezinstalează';

  @override
  String skillUninstallConfirmTitle(String slug) {
    return 'Dezinstalezi \"$slug\"?';
  }

  @override
  String skillUninstalled(String slug) {
    return 'Abilitatea \"$slug\" a fost dezinstalată.';
  }

  @override
  String get skillFindingLine => 'linie';

  @override
  String get skillInstallAnywayOverride => 'Înțeleg riscul — instalează oricum';

  @override
  String skillInstalled(String slug) {
    return 'Abilitatea \"$slug\" a fost instalată.';
  }

  @override
  String get skillPreviewCapabilities => 'Capabilități';

  @override
  String get skillPreviewFindings => 'Constatări';

  @override
  String get skillPreviewGuardedActions => 'Acțiuni protejate';

  @override
  String get skillPreviewLlmReviewed => 'Revizuit de LLM';

  @override
  String get skillPreviewNoCapabilities => 'Nicio capabilitate declarată.';

  @override
  String get skillPreviewNoFindings => 'Nicio constatare.';

  @override
  String get skillPreviewScanning => 'Se scanează abilitatea…';

  @override
  String get skillPreviewVerdictLabel => 'Verdict scanare';

  @override
  String get skillPreviewVerdictPass => 'Trecut';

  @override
  String get skillPreviewVerdictQuarantine => 'În carantină';

  @override
  String get skillPreviewVerdictWarn => 'Avertisment';

  @override
  String get skillQuarantineWarning =>
      'Această abilitate a fost pusă în carantină de scanner. Instalarea ei rulează cod pe mașina ta. Continuă doar dacă ai încredere în sursă și ai revizuit constatările.';

  @override
  String skillDetachedFromAgents(String agents) {
    return 'Pusă în carantină și detașată de agenți: $agents';
  }

  @override
  String get skillNotScanned => 'Nescanat';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => 'Manual';

  @override
  String get skillOriginRuntimeLocal => 'Runtime local';

  @override
  String get skillRulesStale => 'Scanare învechită';

  @override
  String get skillSaveAnywayOverride => 'Înțeleg riscul — salvează oricum';

  @override
  String get skillSaveBlockedBody =>
      'Conținutul a fost blocat înainte să se scrie ceva.';

  @override
  String get skillSaveBlockedTitle => 'Salvare blocată de poarta de scanare';

  @override
  String get skillScanAction => 'Scanează';

  @override
  String get skillScanAll => 'Scanează tot';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass trecute · $warn avertismente · $quarantine în carantină';
  }

  @override
  String get skillStateDrifted => 'Modificat de la instalare';

  @override
  String get skillStateUnmanaged => 'Negestionat';

  @override
  String get skillSeverityBlocked => 'Blocat';

  @override
  String get skillSeverityWarn => 'Avertisment';

  @override
  String get skillsInstalledTab => 'Instalate';

  @override
  String get skills => 'Abilități';

  @override
  String get skipAcceptRisk => 'Sari — accept riscul';

  @override
  String get skipForNow => 'Sari deocamdată';

  @override
  String get skipSandboxing => 'Sari peste sandboxing';

  @override
  String get skipSandboxingDialogContent =>
      'Sigur vrei să sari peste sandboxing? Asta permite agenților să execute cod pe sistemul tău fără izolare.';

  @override
  String get somethingWentWrong => 'Ceva nu a mers bine';

  @override
  String sourceCount(int count) {
    return '$count sursă';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count surse';
  }

  @override
  String get sourceFacts => 'Fapte sursă:';

  @override
  String get splitDiff => 'Diff împărțit (alăturat)';

  @override
  String get startLabel => 'Pornește';

  @override
  String get startOnAppLaunch => 'Pornește la lansarea aplicației';

  @override
  String get statusLabel => 'Stare';

  @override
  String get onboardingStepConnect => 'Conectează';

  @override
  String get onboardingStepWorkspace => 'Spațiu de lucru';

  @override
  String get onboardingStepSandbox => 'Sandbox';

  @override
  String get onboardingStepAdapter => 'Adaptor';

  @override
  String get onboardingStepVoice => 'Voce';

  @override
  String get stop => 'Oprește';

  @override
  String get stopped => 'Oprit';

  @override
  String get strictIdentityCheck => 'Verificare strictă a identității';

  @override
  String get success => 'Succes';

  @override
  String get successLabel => 'Succes';

  @override
  String get suggestion => 'Sugestie';

  @override
  String get suggestLabel => 'Sugerează';

  @override
  String get superseded => 'Înlocuit';

  @override
  String get synced => 'Sincronizat';

  @override
  String get systemDefault => 'Implicit sistem';

  @override
  String get systemFonts => 'Fonturi de sistem';

  @override
  String get systemPrompt => 'Prompt de sistem';

  @override
  String get systemPromptLabel => 'Prompt de sistem';

  @override
  String get talkToControlCenter => 'Vorbește cu Control Center.';

  @override
  String get taskMentionSection => 'Sarcină';

  @override
  String get testLabel => 'Test';

  @override
  String get theme => 'Temă';

  @override
  String get themeDark => 'Întunecat';

  @override
  String get themeLight => 'Luminos';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get thisCannotBeUndone => 'Această acțiune nu poate fi anulată.';

  @override
  String get ticketLabel => 'Tichet';

  @override
  String get titleLabel => 'Titlu';

  @override
  String get todayLabel => 'Azi';

  @override
  String get toggleTheme => 'Comută tema';

  @override
  String get topic => 'Subiect';

  @override
  String get topicHint => 'de ex. Tech Stack, Design System';

  @override
  String get totalRuns => 'Total rulări';

  @override
  String trackingParamsCount(int count) {
    return '$count parametri de urmărire';
  }

  @override
  String get typeCommandOrSearch => 'Tastează o comandă sau caută…';

  @override
  String get typography => 'Tipografie';

  @override
  String get unavailable => 'Indisponibil';

  @override
  String get unifiedDiff => 'Diff unificat';

  @override
  String get unknownAuthor => 'Autor necunoscut';

  @override
  String get unnamedAgent => 'Agent fără nume';

  @override
  String get updateLabel => 'Actualizează';

  @override
  String get updateToken => 'Actualizează tokenul';

  @override
  String updatedDaysAgo(int count) {
    return 'Actualizat acum ${count}z';
  }

  @override
  String updatedHoursAgo(int count) {
    return 'Actualizat acum ${count}h';
  }

  @override
  String get updatedJustNow => 'Actualizat chiar acum';

  @override
  String updatedMinutesAgo(int count) {
    return 'Actualizat acum ${count}min';
  }

  @override
  String get useSandbox => 'Folosește sandbox';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      'Lasă gol pentru User-Agent-ul implicit al aplicației. Unele site-uri blochează User-Agent-urile care nu sunt de browser.';

  @override
  String get usingSystemDefaultMicrophone =>
      'Se folosește microfonul implicit al sistemului.';

  @override
  String get viewLabel => 'Vizualizează';

  @override
  String get viewLogs => 'Vezi jurnalele';

  @override
  String voiceInstallFailed(String error) {
    return 'Instalarea a eșuat: $error';
  }

  @override
  String get voiceModelNotInstalled =>
      'Neinstalat. Descarcă ~200 MB o dată; rulează complet pe dispozitiv.';

  @override
  String get voiceModelNotInstalledLabel => 'Modelul vocal nu este instalat.';

  @override
  String get voiceRedownloadBody =>
      'Fișierele modelului existente vor fi șterse și arhiva de ~200 MB descărcată din nou. Transcrierea vocală va fi indisponibilă până la finalizarea descărcării.';

  @override
  String get voiceRemoveBody =>
      'Transcrierea vocală va fi dezactivată până o reinstalezi. O poți instala din nou oricând.';

  @override
  String get voiceTranscription => 'Transcriere vocală';

  @override
  String get weakIsolationDescription =>
      'Izolare slabă — doar graniță de namespace, fără graniță de kernel.';

  @override
  String get whenOffServerStaysStopped =>
      'Când e oprit, serverul rămâne oprit până îl pornești.';

  @override
  String get speechModel => 'Model de vorbire';

  @override
  String get speechModelHint =>
      'Folosit pentru transcrierea întâlnirilor și microfonul din compozitor.';

  @override
  String get voiceModelInstalled =>
      'Instalat. Alimentează transcrierea întâlnirilor și butonul de microfon din compozitor.';

  @override
  String get meetingMicSilentWarning =>
      'Microfonul tău poate fi dezactivat — ceilalți vorbesc, dar nimic nu ajunge la microfon.';

  @override
  String get meetingSummaryPrivacyNotice =>
      'Înregistrarea și transcrierea rămân pe această mașină. Rezumatul este scris de un agent, deci dacă folosește un model cloud transcrierea și notele tale sunt trimise acelui provider.';

  @override
  String get meetingTemplates => 'Șabloane de note pentru întâlniri';

  @override
  String get meetingTemplatesHint =>
      'Modelează rezumatul AI pentru un tip de întâlnire. Șablonul activ se aplică rezumatelor noi și reluate.';

  @override
  String get meetingTemplateActive => 'Șablon activ';

  @override
  String get meetingTemplateAdd => 'Adaugă șablon';

  @override
  String get meetingTemplateNewTitle => 'Șablon nou';

  @override
  String get meetingTemplateEditTitle => 'Editează șablonul';

  @override
  String get meetingTemplateNameLabel => 'Nume';

  @override
  String get meetingTemplateNameHint => 'de ex. Sprint review';

  @override
  String get meetingTemplateInstructionsLabel => 'Instrucțiuni';

  @override
  String get meetingTemplateInstructionsHint =>
      'Cum ar trebui AI-ul să structureze și să evidențieze aceste note?';

  @override
  String get workingMemory => 'Memorie de lucru';

  @override
  String get workspaceName => 'Nume spațiu de lucru';

  @override
  String get workspaceScopedSkills =>
      'Fișiere de abilități din spațiul de lucru, atașate agenților.';

  @override
  String get workspaces => 'Spații de lucru';

  @override
  String get writePrivateNotes => 'Scrie note private, observații, planuri...';

  @override
  String get writeSkillContent =>
      'Scrie aici conținutul abilității (Markdown)…';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'acum # de ani',
      few: 'acum # ani',
      one: 'acum 1 an',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'Ieri';

  @override
  String get focusModeStart => 'Pornește sesiunea de focus';

  @override
  String get focusModeConfigTitle => 'Pornește sesiunea de focus';

  @override
  String get focusModeGoalLabel => 'Obiectiv';

  @override
  String get focusModeGoalHint => 'La ce lucrezi?';

  @override
  String get focusModeDurationLabel => 'Durată';

  @override
  String get focusModeBlockNotifications => 'Blochează notificările';

  @override
  String get focusModeStartButton => 'Pornește';

  @override
  String get focusModeFloat => 'Minimizează în bară';

  @override
  String get dismiss => 'Închide';

  @override
  String get acceptAndResolve => 'Acceptă și rezolvă';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'Revizuiești de $minutes min — cercetările sugerează că calitatea poate scădea după 60 min. Ia o pauză.';
  }

  @override
  String get notificationSound => 'Sunet de notificare';

  @override
  String get notificationSoundDescription =>
      'Sunetul redat când apare o notificare.';

  @override
  String get notificationSoundNone => 'Niciunul';

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
  String get notificationSoundTest => 'Test';

  @override
  String get notificationVolume => 'Volum';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'Niciun PR de @$login în acest spațiu de lucru';
  }

  @override
  String get usersLabel => 'Utilizatori';

  @override
  String get mergePullRequest => 'Fuzionează pull request-ul';

  @override
  String get forceMergePullRequest => 'Forțează fuziunea pull request-ului';

  @override
  String get closePullRequest => 'Închide pull request-ul';

  @override
  String get closePullRequestConfirm =>
      'Sigur vrei să închizi acest pull request?';

  @override
  String get stackedPullRequests => 'Pull request-uri stivuite';

  @override
  String partOfStack(int position, int total) {
    return 'Parte dintr-o stivă ($position din $total)';
  }

  @override
  String get createStack => 'Creează stivă';

  @override
  String get createStackDialogTitle => 'Creează stivă de pull request-uri';

  @override
  String createStackDialogBody(int count) {
    return 'Aceste $count pull request-uri vor fi stivuite, de jos în sus:';
  }

  @override
  String get createStackInvalidSelection =>
      'Selectează cel puțin două pull request-uri din același depozit ca să creezi o stivă';

  @override
  String get createStackNotAChain =>
      'Pull request-urile selectate nu formează un lanț: ramura de bază a fiecărui pull request trebuie să fie ramura head a celui anterior';

  @override
  String get createStackAlreadyStacked =>
      'Unul sau mai multe pull request-uri selectate sunt deja într-o stivă';

  @override
  String get stackCreated => 'Stivă creată';

  @override
  String get stackCreationFailed => 'Nu s-a putut crea stiva';

  @override
  String get squashAndMerge => 'Squash and merge';

  @override
  String get createMergeCommit => 'Creează un commit de fuziune';

  @override
  String get rebaseAndMerge => 'Rebase and merge';

  @override
  String get mergeMethod => 'Metodă de îmbinare';

  @override
  String get commitTitle => 'Titlu commit';

  @override
  String get commitDescription => 'Descriere commit';

  @override
  String get pullRequestMerged => 'Pull request fuzionat';

  @override
  String get pullRequestClosed => 'Pull request închis';

  @override
  String failedToMergePr(String error) {
    return 'Fuziunea a eșuat: $error';
  }

  @override
  String failedToClosePr(String error) {
    return 'Închiderea a eșuat: $error';
  }

  @override
  String get markReadyForReview => 'Gata de revizuire';

  @override
  String get markReadyForReviewConfirm =>
      'Acest pull request va ieși din ciornă. Recenzenții sunt notificați, verificările obligatorii încep să blocheze fuziunea și orice automatizare care așteaptă pull request-uri gata pornește.';

  @override
  String get convertToDraft => 'Convertește în ciornă';

  @override
  String get convertToDraftConfirm =>
      'Acest pull request revine la ciornă. Cererile de revizuire în așteptare sunt respinse și nu mai poate fi fuzionat până îl marchezi din nou gata.';

  @override
  String get pullRequestMarkedReady => 'Pull request marcat gata de revizuire';

  @override
  String get pullRequestConvertedToDraft => 'Pull request convertit în ciornă';

  @override
  String failedToMarkPrReady(String error) {
    return 'Nu s-a putut marca gata de revizuire: $error';
  }

  @override
  String failedToConvertPrToDraft(String error) {
    return 'Nu s-a putut converti în ciornă: $error';
  }

  @override
  String get checksFailing => 'Verificări eșuate';

  @override
  String get reviewsPending => 'Unele revizuiri sunt în așteptare';

  @override
  String get mergeConflictsWithBase =>
      'Această ramură are conflicte care trebuie rezolvate';

  @override
  String get branchOutOfDateWithBase =>
      'Această ramură este învechită față de ramura de bază';

  @override
  String get mergeBlockedByBranchProtection =>
      'Protecția ramurii blochează această fuziune';

  @override
  String get confirm => 'Confirmă';

  @override
  String get trustedSitesSectionTitle => 'Site-uri de încredere';

  @override
  String get trustedSitesEmpty =>
      'Niciun site de încredere. Adaugă un domeniu ca să dezactivezi blocarea pe el.';

  @override
  String get addTrustedSite => 'Adaugă site de încredere';

  @override
  String get removeTrustedSite => 'Elimină';

  @override
  String get disableBlockingForThisSite =>
      'Dezactivează blocarea pe acest site';

  @override
  String get enableBlockingForThisSite => 'Activează blocarea pe acest site';

  @override
  String get enterDomainHint => 'de ex. example.com';

  @override
  String get invalidDomain => 'Introdu un domeniu valid (de ex. example.com)';

  @override
  String get pageLoadTimedOut =>
      'Încărcarea paginii a expirat. Reîncarcă sau deschide în browser.';

  @override
  String get pipelinesScreenTitle => 'Pipeline-uri';

  @override
  String get pipelinesScreenSubtitle =>
      'Fluxuri declarative multi-pas pentru agenți';

  @override
  String get pipelinesRunPipeline => 'Rulează pipeline';

  @override
  String get pipelineRunLauncherTitle => 'Rulează pipeline';

  @override
  String get pipelineRunSubtitle =>
      'Alege un pipeline și completează intrările ca să pornești o rulare.';

  @override
  String get pipelineRunNoInputsBadge => 'Fără intrări';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de intrări',
      few: '# intrări',
      one: '1 intrare',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'Acest pipeline nu are nicio intrare.';

  @override
  String get pipelineRunSubmit => 'Rulează pipeline';

  @override
  String get pipelineRunCouldNotStart => 'Nu s-a putut porni rularea.';

  @override
  String pipelineRunStarted(String name) {
    return 'S-a pornit $name';
  }

  @override
  String get pipelineRunEmptyTitle => 'Niciun pipeline gata de rulare';

  @override
  String get pipelineRunEmptyHint =>
      'Activează un pipeline și pornește rularea manuală în editor ca să-l lansezi aici.';

  @override
  String get pipelineRunManageTemplates => 'Gestionează pipeline-urile';

  @override
  String get pipelineRunSettingsTitle => 'Rulare manuală';

  @override
  String get pipelineRunSettingsAllow => 'Permite rulare manuală';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'Afișează acest pipeline pe pagina de rulare ca să poată fi pornit manual.';

  @override
  String get pipelineRunSettingsConcurrencyTitle => 'Concurență';

  @override
  String get pipelineRunSettingsMaxParallel => 'Max. rulări paralele';

  @override
  String get pipelineRunSettingsMaxParallelHelp =>
      'Lasă gol pentru nelimitat. Rulările extra așteaptă în coadă și pornesc pe măsură ce se eliberează locuri.';

  @override
  String get pipelineRunSettingsMaxParallelHint => 'Nelimitat';

  @override
  String get pipelineRunSettingsMaxParallelInvalid =>
      'Introdu un număr întreg de 1 sau mai mare, sau lasă gol pentru nelimitat.';

  @override
  String get pipelineRunSettingsInputsTitle => 'Intrări';

  @override
  String get pipelineRunSettingsAddInput => 'Adaugă intrare';

  @override
  String get pipelineRunSettingsNoInputs => 'Nicio intrare încă.';

  @override
  String get pipelineInputEditTitle => 'Câmp de intrare';

  @override
  String get pipelineInputKeyLabel => 'Cheie';

  @override
  String get pipelineInputKeyHelp =>
      'Cheia de stare sub care se stochează valoarea (de ex. repo_full_name).';

  @override
  String get pipelineInputLabelLabel => 'Etichetă';

  @override
  String get pipelineInputTypeLabel => 'Tip';

  @override
  String get pipelineInputOptionsLabel => 'Opțiuni (separate prin virgulă)';

  @override
  String get pipelineInputDefaultLabel => 'Valoare implicită';

  @override
  String get pipelineInputPlaceholderLabel => 'Placeholder';

  @override
  String get pipelineInputHelpLabel => 'Text de ajutor';

  @override
  String get pipelineInputRequiredLabel => 'Obligatoriu';

  @override
  String get pipelineInputTypeText => 'Text';

  @override
  String get pipelineInputTypeMultiline => 'Text pe mai multe linii';

  @override
  String get pipelineInputTypeNumber => 'Număr';

  @override
  String get pipelineInputTypeBoolean => 'Comutator';

  @override
  String get pipelineInputTypeSelect => 'Selectare';

  @override
  String get pipelinesEmpty => 'Nicio rulare pipeline încă';

  @override
  String get pipelinesEmptyHint =>
      'Apasă „Rulează pipeline” ca să pornești una.';

  @override
  String get pipelinesNoSteps => 'Niciun pas înregistrat încă';

  @override
  String get pipelinesNoActiveWorkspace =>
      'Selectează un spațiu de lucru ca să-i vezi pipeline-urile';

  @override
  String pipelinesLoadError(String error) {
    return 'Nu s-au putut încărca pipeline-urile: $error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'Nu s-a putut porni pipeline-ul: $error';
  }

  @override
  String get pipelineStatusPending => 'În așteptare';

  @override
  String get pipelineStatusQueued => 'În coadă';

  @override
  String get pipelineStatusRunning => 'În rulare';

  @override
  String get pipelineStatusSuspended => 'Suspendat';

  @override
  String get pipelineStatusCompleted => 'Finalizat';

  @override
  String get pipelineStatusFailed => 'Eșuat';

  @override
  String get pipelineStatusCancelled => 'Anulat';

  @override
  String get pipelineStatusSkipped => 'Sărit';

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed din $total pași';
  }

  @override
  String get pipelineWaterfallTimeline => 'Cronologie';

  @override
  String pipelineWaterfallActive(String duration) {
    return 'Activ $duration';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return 'inactiv $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip =>
      'Timp exclus din totalul activ: rularea a fost oprită sau aștepta între pași.';

  @override
  String get pipelineStepStarted => 'Pornit';

  @override
  String get pipelineStepFinished => 'Terminat';

  @override
  String get pipelineStepDurationLabel => 'Durată';

  @override
  String get pipelineStepViewConversation => 'Vezi conversația';

  @override
  String get pipelineStepError => 'Eroare';

  @override
  String get pipelineStepInput => 'Intrare';

  @override
  String get pipelineStepOutput => 'Ieșire';

  @override
  String get pipelineStepNotExecuted => 'Neexecutat încă';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'A eșuat la $step';
  }

  @override
  String get pipelineRunTriggerManual => 'Manual';

  @override
  String get pipelineStepSkippedReason => 'Sărit';

  @override
  String get pipelineStepPriorAttempts => 'Încercări anterioare';

  @override
  String get pipelineStepAttemptLabel => 'Încercare';

  @override
  String pipelineStepAttemptN(int number) {
    return 'Încercarea $number';
  }

  @override
  String get pipelineStepAttemptInterrupted => 'Întrerupt';

  @override
  String get pipelineRunColumnPipeline => 'Pipeline';

  @override
  String get pipelineRunColumnDuration => 'Durată';

  @override
  String get pipelineRunQueueNext => 'Următorul';

  @override
  String pipelineRunQueuePosition(int position) {
    return '$position în coadă';
  }

  @override
  String get pipelineRunColumnStarted => 'Pornit';

  @override
  String get pipelineRunHistory => 'Istoric rulări';

  @override
  String get pipelineRunHistoryEmpty => 'Nicio altă rulare încă';

  @override
  String pipelineRunRerunAgo(String time) {
    return 'Reluare $time';
  }

  @override
  String pipelineRunAttempt(int number) {
    return 'Încercarea $number';
  }

  @override
  String pipelineRunFirstStarted(String time) {
    return 'prima pornire $time';
  }

  @override
  String get pipelineRunFilterAll => 'Toate';

  @override
  String get pipelineRunFilterEmpty =>
      'Nicio rulare nu se potrivește acestui filtru';

  @override
  String get relativeJustNow => 'chiar acum';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'acum # min',
      few: 'acum # min',
      one: 'acum 1 min',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'acum # de ore',
      few: 'acum # ore',
      one: 'acum 1 oră',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'acum # de zile',
      few: 'acum # zile',
      one: 'acum 1 zi',
    );
    return '$_temp0';
  }

  @override
  String get teamsTitle => 'Echipe';

  @override
  String get teamsAddTeam => 'Adaugă echipă';

  @override
  String get teamsLoadError => 'Nu s-au putut încărca echipele';

  @override
  String get teamsEmptyTitle => 'Nicio echipă încă';

  @override
  String get teamsEmptyDescription =>
      'Grupează agenții în echipe, astfel munca asignată unei echipe trece printr-un lider care deleagă.';

  @override
  String get teamCreateTitle => 'Echipă nouă';

  @override
  String get teamEditTitle => 'Editează echipa';

  @override
  String get teamNameLabel => 'Nume echipă';

  @override
  String get teamNameHint => 'de ex. Frontend';

  @override
  String get teamDescriptionLabel => 'Descriere';

  @override
  String get teamDescriptionHint => 'De ce este responsabilă această echipă';

  @override
  String get teamLeaderLabel => 'Lider';

  @override
  String get teamLeaderHelp =>
      'Coordonatorul care primește munca asignată echipei și o deleagă membrului cel mai potrivit.';

  @override
  String get teamNoLeader => 'Fără lider';

  @override
  String get teamInstructionsLabel => 'Instrucțiuni de operare';

  @override
  String get teamInstructionsHelp =>
      'Adăugate briefingului liderului — convenții de echipă, reguli de escaladare, ton.';

  @override
  String get teamInstructionsHint => 'Opțional';

  @override
  String get teamSaved => 'Echipă salvată';

  @override
  String get teamMembersError => 'Nu s-au putut încărca membrii';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de membri',
      few: '# membri',
      one: '1 membru',
      zero: 'Niciun membru',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => 'Adaugă membru';

  @override
  String get teamAddMemberTitle => 'Adaugă membri';

  @override
  String teamAddMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Adaugă #',
      few: 'Adaugă #',
      one: 'Adaugă 1',
      zero: 'Adaugă',
    );
    return '$_temp0';
  }

  @override
  String get teamNoAgentsToAdd => 'Fiecare agent este deja în această echipă.';

  @override
  String get teamRemoveMember => 'Elimină din echipă';

  @override
  String get teamLeaderBadge => 'Lider';

  @override
  String get teamUnknownAgent => 'Agent necunoscut';

  @override
  String get teamMembersEmpty => 'Niciun membru încă';

  @override
  String get teamMembersEmptyDescription =>
      'Adaugă agenți ca liderul să aibă cui să delege.';

  @override
  String get teamSelectPrompt => 'Selectează o echipă';

  @override
  String get teamSelectPromptDescription =>
      'Alege o echipă din listă sau creează una nouă.';

  @override
  String get teamDeleteTitle => 'Ștergi echipa?';

  @override
  String teamDeleteBody(String name) {
    return '$name va fi ștearsă. Agenții ei nu sunt afectați.';
  }

  @override
  String get teamHasLeaderTooltip => 'Are un lider';

  @override
  String get pipelineTemplatesNav => 'Șabloane pipeline';

  @override
  String get pipelineTemplatesTitle => 'Șabloane pipeline';

  @override
  String get pipelineTemplatesSubtitle =>
      'Editor drag-and-drop pentru pipeline-urile care orchestrează agenții.';

  @override
  String get pipelineTemplatesNew => 'Șablon nou';

  @override
  String get pipelineTemplatesEmpty =>
      'Niciun șablon pipeline încă. Creează unul ca să începi.';

  @override
  String get pipelineTemplateBuiltInBadge => 'Încorporat';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'Ștergi șablonul?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'Ștergi șablonul pipeline $name? Acțiunea nu poate fi anulată.';
  }

  @override
  String get pipelineTemplateEditorSubtitle =>
      'Trage tipuri de noduri din bara laterală pe pânză, apoi leagă-le.';

  @override
  String get unsavedChanges => 'Modificări nesalvate';

  @override
  String get nodeLibraryTitle => 'Bibliotecă de noduri';

  @override
  String get nodeLibraryHint =>
      'Trage orice element pe pânză ca să adaugi un nod.';

  @override
  String get editorEmptyCanvas => 'Trage un nod din bibliotecă ca să începi.';

  @override
  String get pipelineWhenThisHappens => 'Când se întâmplă asta';

  @override
  String get pipelineDoThis => 'Fă asta';

  @override
  String get pipelineAddStep => 'Adaugă pas';

  @override
  String get pipelineTidyUp => 'Ordonează aspectul';

  @override
  String get pipelineEditorHint =>
      'Trage pașii ca să-i aranjezi · trage un mâner ca să conectezi';

  @override
  String get pipelineRemoveConnection => 'Elimină conexiunea';

  @override
  String get pipelineDragToConnect => 'Trage pentru a conecta';

  @override
  String get pipelineNewDefaultName => 'Pipeline nou';

  @override
  String get nodeCategoryTriggers => 'Declanșatori';

  @override
  String get triggerEventWebhook => 'Webhook';

  @override
  String get pipelineAddTrigger => 'Adaugă un declanșator';

  @override
  String get pipelineOnEvent => 'La eveniment';

  @override
  String get nodeConfigTitle => 'Configurare nod';

  @override
  String get nodeConfigKind => 'Tip';

  @override
  String get nodeConfigLabel => 'Etichetă';

  @override
  String get nodeConfigAgent => 'Agent';

  @override
  String get nodeConfigAgentHint => 'Alege un agent…';

  @override
  String get nodeConfigInputKeys => 'Chei de intrare (separate prin virgulă)';

  @override
  String get nodeConfigInputKeysHelp =>
      'Cheile de stare pe care le consumă acest nod. Folosite pentru înlocuirea placeholderelor în prompt.';

  @override
  String get nodeConfigRepos => 'Depozite de clonat';

  @override
  String get nodeConfigReposHelp =>
      'Depozite clonate și indexate când acest nod își pornește conversația. Selectarea tuturor depozitelor le clonează pe toate (implicit).';

  @override
  String get nodeConfigRepoBranchHint => 'Ramură (implicit)';

  @override
  String get nodeConfigRepoBranchHelp =>
      'Ramura din care se taie fiecare checkout. Lasă gol pentru ramura implicită a depozitului — worktree-ul primește totuși propria ramură, deci nimic din ce comite un agent nu ajunge pe aceasta.';

  @override
  String nodeConfigReposDynamic(String entries) {
    return 'Intrări dinamice păstrate: $entries';
  }

  @override
  String get nodeConfigCreateConversation => 'Deschide o conversație în el';

  @override
  String get nodeConfigCreateConversationHelp =>
      'Lasă oprit când urmează mai multe noduri de agent — fiecare își deschide propriul flux numit. Activează când urmează un singur nod de agent, ca sala să nu arate o conversație fără titlu lângă el.';

  @override
  String get nodeConfigConversationTitle => 'Nume conversație';

  @override
  String get nodeConfigConversationTitleHelp =>
      'Dă nodului de agent din aval același nume și ambele lucrează într-un singur flux. Implicit este eticheta nodului.';

  @override
  String get nodeConfigSpaceName => 'Nume spațiu';

  @override
  String get nodeConfigSpaceNameHelp =>
      'Cum se numește sala pe care o deschide acest nod. Acceptă aceleași placeholdere de stare ca un prompt. Lasă gol pentru eticheta nodului.';

  @override
  String get nodeConfigSpaceNameHint => 'Review of pr_number';

  @override
  String get nodeConfigStreamTitle => 'Nume conversație';

  @override
  String get nodeConfigStreamTitleHelp =>
      'Fluxul numit în care lucrează agentul acestui nod, în sală. Acceptă aceleași placeholdere de stare ca un prompt. Lasă gol și turul ajunge în conversația permanentă a sălii, unde un fan-out intercală fiecare agent.';

  @override
  String get nodeConfigConversationTitleHint => 'Architecture analysis';

  @override
  String get nodeConfigOutputKey => 'Cheie de ieșire';

  @override
  String get nodeConfigPrompt => 'Șablon de prompt';

  @override
  String get nodeConfigPromptHelp =>
      'Folosește placeholdere cu acolade duble ca să extragi valori din stare la runtime.';

  @override
  String get nodeConfigScript => 'Script Bash';

  @override
  String get nodeConfigScriptHelp =>
      'Rulează cu bash -c în sandboxul sistemului de operare. GH_TOKEN și GITHUB_TOKEN conțin un token doar pentru citire pentru depozitul asociat. Placeholderele sunt puse între ghilimele și înlocuite înainte de execuție.';

  @override
  String get nodeConfigRouteKeys => 'Chei de rută';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'Cheie de rută de la $source';
  }

  @override
  String get conditionSectionTitle => 'Condiție';

  @override
  String get conditionMode => 'Mod';

  @override
  String get conditionModeFilesAny => 'Fișier(e) există — oricare';

  @override
  String get conditionModeFilesAll => 'Fișierele există — toate';

  @override
  String get conditionModeComparison => 'Comparație';

  @override
  String get conditionModeSwitch => 'Switch';

  @override
  String get conditionFilePaths => 'Căi de fișiere';

  @override
  String get conditionFilePathsAnyHelp =>
      'O cale pe linie, relativă la directorul de bază. Rutează true când există oricare.';

  @override
  String get conditionFilePathsAllHelp =>
      'O cale pe linie, relativă la directorul de bază. Rutează true doar când există toate.';

  @override
  String get conditionBaseKey => 'Cheie director de bază';

  @override
  String get conditionBaseKeyHelp =>
      'Cheia de stare care deține directorul față de care se rezolvă căile (implicit repo_local_path).';

  @override
  String get conditionRecursive => 'Caută în subdirectoare';

  @override
  String get conditionNegate => 'Inversează: rutează true când lipsește';

  @override
  String get conditionLeft => 'Valoare stânga';

  @override
  String get conditionOperator => 'Operator';

  @override
  String get conditionRight => 'Valoare dreapta';

  @override
  String get conditionSwitchKey => 'Switch pe cheia de stare';

  @override
  String get conditionCases => 'Cazuri (separate prin virgulă)';

  @override
  String get conditionCasesHelp =>
      'Chei de rută de potrivit cu valoarea, în ordine.';

  @override
  String get conditionDefaultCase => 'Caz implicit';

  @override
  String get triggerManualHelp =>
      'Afișează pe pagina de rulare și pornește manual.';

  @override
  String get triggerKindSchedule => 'După un program';

  @override
  String get triggerScheduleExprLabel => 'Program (cron sau every:seconds)';

  @override
  String get triggerTimezoneLabel => 'Fus orar (opțional)';

  @override
  String get triggerCatchUpLabel => 'La rulări ratate';

  @override
  String get triggerCatchUpRunOnce => 'Rulează o dată';

  @override
  String get triggerCatchUpSkip => 'Sari';

  @override
  String get syncHealthTitle => 'Sănătate sincronizare';

  @override
  String get syncHealthNoConfigs => 'Nicio conexiune de sincronizare încă';

  @override
  String get syncHealthNeverSynced => 'Nesincronizat niciodată';

  @override
  String get syncOutcomeOk => 'Sincronizat';

  @override
  String get syncOutcomeFailed => 'Eșuat';

  @override
  String get syncOutcomeSkipped => 'Sărit';

  @override
  String syncHealthFailedStreak(int count) {
    return '$count eșecuri consecutive';
  }

  @override
  String get triggerWebhookHelp =>
      'Se generează un URL de webhook semnat. Sistemele externe fac POST către el ca să pornească acest pipeline.';

  @override
  String get triggerWebhookPathLabel => 'Calea webhook-ului';

  @override
  String get triggerMatchStatusLabel => 'Doar când starea este';

  @override
  String get triggerSummaryNone => 'Fără declanșatori';

  @override
  String triggerEverySeconds(int seconds) {
    return 'La fiecare ${seconds}s';
  }

  @override
  String get triggerEventManual => 'Rulare manuală';

  @override
  String get triggerEventSchedule => 'Program';

  @override
  String get triggerEventPrStatusChanged => 'Starea PR s-a schimbat';

  @override
  String get triggerEventExternalPr => 'PR extern deschis';

  @override
  String get triggerEventPrPublished => 'PR publicat';

  @override
  String get triggerEventPrMerged => 'PR fuzionat';

  @override
  String get triggerEventRepoAdded => 'Depozit adăugat';

  @override
  String get triggerEventCodeGraphWatch => 'Modificare de fișier';

  @override
  String pipelineRunCauseChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de fișiere modificate',
      few: '# fișiere modificate',
      one: '1 fișier modificat',
    );
    return '$_temp0';
  }

  @override
  String pipelineRunCauseMorePaths(int count) {
    return '+$count în plus';
  }

  @override
  String get pipelineRunCauseRescan => 'Modificat pe disc';

  @override
  String get pipelineRunCauseInitial => 'Prima indexare a acestui checkout';

  @override
  String get triggerEventMessageReceived => 'Mesaj primit';

  @override
  String get triggerEventTicketCompleted => 'Tichet finalizat';

  @override
  String get triggerEventTicketFailed => 'Tichet eșuat';

  @override
  String get triggerEventTicketCancelled => 'Tichet anulat';

  @override
  String get triggerEventBudgetCrossed => 'Prag de buget depășit';

  @override
  String get nodeLibrarySearchHint => 'Caută noduri';

  @override
  String get nodeLibraryNoMatches => 'Niciun nod potrivit';

  @override
  String get nodeCategoryFlow => 'Flux și logică';

  @override
  String get nodeCategoryPr => 'Revizuire PR';

  @override
  String get nodeCategoryAgents => 'Agenți';

  @override
  String get nodeCategoryMessaging => 'Mesagerie';

  @override
  String get nodeCategoryCode => 'Cod';

  @override
  String get triggerDisabledTag => 'oprit';

  @override
  String get pipelineInputTypeRepo => 'Depozit';

  @override
  String get pipelineRunNoRepos =>
      'Niciun depozit în acest spațiu de lucru încă.';

  @override
  String get ticketingApiKey => 'Cheie API ticketing';

  @override
  String get ticketingProvider => 'Provider de ticketing';

  @override
  String get connectGitHubAndTicketing =>
      'Conectează un host de cod ca Control Center să-ți poată citi pull request-urile, issue-urile și revizuirile. Opțional, conectează un provider de ticketing. Datele de autentificare sunt deținute de serverul tău, niciodată de această mașină.';

  @override
  String get triggerEventTicketAssigned => 'Tichet asignat';

  @override
  String get triggerEventTicketCreated => 'Tichet creat';

  @override
  String get triggerEventTicketStatusChanged =>
      'Starea tichetului s-a schimbat';

  @override
  String get triggerEventMeetingRecordingStopped =>
      'Înregistrarea întâlnirii s-a oprit';

  @override
  String get triggerEventSkillUpdated => 'Abilitate actualizată';

  @override
  String get triggerEventSpaceDeleted => 'Spațiu șters';

  @override
  String get triggerEventSpaceArchived => 'Spațiu arhivat';

  @override
  String get triggerEventSpaceProvisioningChanged =>
      'Pregătirea spațiului s-a schimbat';

  @override
  String get triggerEventPrHeadChanged => 'Head-ul PR s-a schimbat';

  @override
  String get triggerEventEnvironmentStatusChanged =>
      'Starea mediului s-a schimbat';

  @override
  String get triggerEventEnvironmentReady => 'Mediu pregătit';

  @override
  String get triggerEventEnvironmentDestroyed => 'Mediu distrus';

  @override
  String get triggerEventEnvironmentProcessExited =>
      'Procesul mediului s-a încheiat';

  @override
  String get triggerExternalPrHelp =>
      'Un pull request deschis pe gazda de cod, nu din Control Center.';

  @override
  String get triggerPrPublishedHelp =>
      'Un pull request deschis din Control Center sau de un agent.';

  @override
  String get triggerPrStatusChangedHelp =>
      'Fuzionat, închis, deschis, redeschis sau aprobat. Filtrează după stare în inspector.';

  @override
  String get triggerPrMergedHelp =>
      'Doar când pull request-ul este fuzionat, nu închis sau redeschis.';

  @override
  String get triggerRepoAddedHelp =>
      'Un depozit este legat de acest spațiu de lucru.';

  @override
  String get triggerCodeGraphWatchHelp =>
      'Un fișier dintr-un depozit legat se schimbă pe disc.';

  @override
  String get triggerMessageReceivedHelp =>
      'Un mesaj nou ajunge într-un spațiu.';

  @override
  String get triggerTicketCreatedHelp =>
      'Un bilet este creat în acest spațiu de lucru.';

  @override
  String get triggerTicketStatusChangedHelp => 'Un bilet trece între stări.';

  @override
  String get triggerTicketCompletedHelp => 'Un bilet se încheie cu succes.';

  @override
  String get triggerTicketFailedHelp =>
      'O rulare a agentului a eșuat, iar biletul este marcat ca eșuat.';

  @override
  String get triggerTicketCancelledHelp =>
      'Un bilet este anulat și nu va continua.';

  @override
  String get triggerBudgetCrossedHelp =>
      'Se depășește o limită de cheltuieli a spațiului de lucru sau a agentului.';

  @override
  String get triggerTicketAssignedHelp =>
      'Un bilet este atribuit unei persoane, unui agent sau unei echipe.';

  @override
  String get triggerMeetingRecordingStoppedHelp =>
      'Înregistrarea unei întâlniri se încheie.';

  @override
  String get triggerSkillUpdatedHelp =>
      'O abilitate este instalată sau actualizată.';

  @override
  String get triggerSpaceDeletedHelp => 'Un spațiu de conversație este șters.';

  @override
  String get triggerSpaceArchivedHelp =>
      'Un spațiu de conversație este arhivat.';

  @override
  String get triggerSpaceProvisioningChangedHelp =>
      'Pregătirea worktree-urilor unui spațiu începe, se încheie sau eșuează.';

  @override
  String get triggerPrHeadChangedHelp =>
      'Commituri noi sunt împinse într-un pull request deschis.';

  @override
  String get triggerEnvironmentStatusChangedHelp =>
      'Un mediu de spațiu trece într-o stare nouă.';

  @override
  String get triggerEnvironmentReadyHelp =>
      'Un mediu de spațiu a pornit și poate fi folosit.';

  @override
  String get triggerEnvironmentDestroyedHelp =>
      'Un mediu de spațiu este demontat.';

  @override
  String get triggerEnvironmentProcessExitedHelp =>
      'Un proces rulat de un mediu se încheie.';

  @override
  String get navTickets => 'Tichete';

  @override
  String get ticketsTitle => 'Tichete';

  @override
  String get newTicket => 'Tichet nou';

  @override
  String get noTicketsYet => 'Niciun tichet încă';

  @override
  String get addCollaborator => 'Adaugă colaborator';

  @override
  String get noCollaborators => 'Niciun colaborator încă';

  @override
  String get linkedPullRequests => 'Pull request-uri legate';

  @override
  String get noLinkedPullRequests => 'Niciun pull request legat încă';

  @override
  String get stopAgent => 'Oprește agentul';

  @override
  String get ticketProperties => 'Proprietăți';

  @override
  String get ticketTabIssue => 'Issue';

  @override
  String get ticketSelectPrompt =>
      'Selectează un tichet ca să-i vezi detaliile';

  @override
  String get unassigned => 'Neasignat';

  @override
  String get ticketStatusBacklog => 'Backlog';

  @override
  String get ticketStatusOpen => 'De făcut';

  @override
  String get ticketStatusInProgress => 'În curs';

  @override
  String get ticketStatusInReview => 'În revizuire';

  @override
  String get ticketStatusDone => 'Gata';

  @override
  String get ticketStatusBlocked => 'Blocat';

  @override
  String get ticketStatusFailed => 'Eșuat';

  @override
  String get ticketStatusCancelled => 'Anulat';

  @override
  String get notificationTicketAssigned => 'Tichet asignat';

  @override
  String get notificationTicketStatusChanged =>
      'Starea tichetului s-a schimbat';

  @override
  String get priority => 'Prioritate';

  @override
  String get status => 'Stare';

  @override
  String get assignee => 'Asignat';

  @override
  String get labels => 'Etichete';

  @override
  String get noLabelsYet => 'Nicio etichetă încă';

  @override
  String get clearLabels => 'Șterge etichetele';

  @override
  String get pipelineStepAgentActivity => 'Activitate agent';

  @override
  String get runStatusCompleted => 'Finalizat';

  @override
  String get runStatusQueued => 'În coadă';

  @override
  String get ticketDescription => 'Descriere';

  @override
  String get ticketPriorityNone => 'Niciuna';

  @override
  String get ticketPriorityUrgent => 'Urgent';

  @override
  String get ticketPriorityHigh => 'Ridicată';

  @override
  String get ticketPriorityMedium => 'Medie';

  @override
  String get ticketPriorityLow => 'Scăzută';

  @override
  String get ticketViewList => 'Listă';

  @override
  String get ticketViewBoard => 'Tablă';

  @override
  String get ticketTitlePlaceholder => 'Titlu issue';

  @override
  String get ticketDescriptionPlaceholder => 'Adaugă descriere…';

  @override
  String get createMore => 'Creează încă';

  @override
  String selectedCount(int count) {
    return '$count selectate';
  }

  @override
  String get clearSelection => 'Golește selecția';

  @override
  String get bulkDeleteTitle => 'Șterge tichete';

  @override
  String bulkDeleteMessage(int count) {
    return 'Ștergi $count tichete selectate? Acțiunea nu poate fi anulată.';
  }

  @override
  String get assignTo => 'Asignează către…';

  @override
  String get sectionMembers => 'Membri';

  @override
  String get sectionAgents => 'Agenți';

  @override
  String get sidebarGroupWorkspace => 'Spațiu de lucru';

  @override
  String get notificationsTitle => 'Notificări';

  @override
  String get notificationsTooltip => 'Notificări';

  @override
  String get notificationsEmpty => 'Ești la zi';

  @override
  String notificationsUnreadCount(int count) {
    return '$count necitite';
  }

  @override
  String get notificationsMarkRead => 'Marchează ca citit';

  @override
  String get notificationsMarkUnread => 'Marchează ca necitit';

  @override
  String get notificationsEntryActions => 'Acțiuni notificare';

  @override
  String get markAllRead => 'Marchează tot ca citit';

  @override
  String get teamsNav => 'Echipe';

  @override
  String get noWorkspace => 'Niciun spațiu de lucru';

  @override
  String get selectWorkspace => 'Selectează un spațiu de lucru';

  @override
  String get navMemory => 'Memorie';

  @override
  String get memoryTabFacts => 'Fapte';

  @override
  String get memoryTabPolicies => 'Politici';

  @override
  String get memoryGraphShowFacts => 'Afișează faptele';

  @override
  String get memoryGraphHideFacts => 'Ascunde faptele';

  @override
  String get memoryGraphExpandAll => 'Extinde toate faptele';

  @override
  String get memoryGraphCollapseAll => 'Restrânge toate faptele';

  @override
  String get memoryTabGraph => 'Graf de cunoștințe';

  @override
  String get memoryNoWorkspace =>
      'Selectează un spațiu de lucru ca să-i vezi memoria.';

  @override
  String get searchArticles => 'Caută articole';

  @override
  String get filterAll => 'Toate';

  @override
  String get filterUnread => 'Necitite';

  @override
  String get filterSaved => 'Salvate';

  @override
  String get saveArticle => 'Salvează articolul';

  @override
  String get removeFromSaved => 'Elimină din salvate';

  @override
  String get filterBySource => 'Filtrează după sursă';

  @override
  String get viewAsList => 'Vizualizare listă';

  @override
  String get viewAsGrid => 'Vizualizare grilă';

  @override
  String get noMatchingArticles => 'Niciun articol potrivit';

  @override
  String get noMatchingArticlesBody =>
      'Încearcă o altă căutare sau un alt filtru de sursă.';

  @override
  String get allCaughtUp => 'Ești la zi';

  @override
  String get allCaughtUpBody => 'Niciun articol necitit — revino mai târziu.';

  @override
  String get openArticlesInAppDescription =>
      'Deschide linkurile în cititorul încorporat în loc de browserul implicit.';

  @override
  String get blockAdsTrackersDescription =>
      'Elimină reclamele, trackerele și bannerele de cookie-uri din articolele deschise în cititor.';

  @override
  String get agentQuestionHeader => 'Întrebare pentru tine';

  @override
  String get agentQuestionAnsweredLabel => 'Răspuns';

  @override
  String get agentQuestionFreeformHint => 'Tastează răspunsul…';

  @override
  String agentQuestionProgress(int index, int count) {
    return 'Întrebarea $index din $count';
  }

  @override
  String get agentQuestionSkip => 'Omite';

  @override
  String get agentQuestionSkippedLabel => 'Omisă';

  @override
  String get agentQuestionTimedOutLabel => 'Timpul a expirat';

  @override
  String get agentQuestionTimeLeft => 'Timp rămas pentru răspuns';

  @override
  String get agentQuestionFreeformOptionHint => 'Descrie în cuvintele tale…';

  @override
  String get reviewRequested => 'Revizuire solicitată';

  @override
  String get noRepositoriesConfigured => 'Niciun depozit configurat';

  @override
  String openedAgo(String age) {
    return 'Deschis $age';
  }

  @override
  String prTimelineOpened(String author) {
    return '$author a deschis acest pull request';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de commit-uri',
      few: '# commit-uri',
      one: '1 commit',
    );
    return '$author a deschis acest pull request cu $_temp0';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return '$actor a cerut revizuire de la $reviewers';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '$actor a eliminat cererea de revizuire pentru $reviewers';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '$actor a cerut revizuire de la $requested și a eliminat cererea de revizuire pentru $removed';
  }

  @override
  String prTimelineAddedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'etichetele',
      one: 'eticheta',
    );
    return '$actor a adăugat $_temp0 $labels';
  }

  @override
  String prTimelineRemovedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'etichetele',
      one: 'eticheta',
    );
    return '$actor a eliminat $_temp0 $labels';
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
      other: 'etichetele',
      one: 'eticheta',
    );
    String _temp1 = intl.Intl.pluralLogic(
      removedCount,
      locale: localeName,
      other: 'etichetele',
      one: 'eticheta',
    );
    return '$actor a adăugat $_temp0 $added și a eliminat $_temp1 $removed';
  }

  @override
  String prTimelineCommitted(String author) {
    return '$author a făcut commit';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de commit-uri',
      few: '# commit-uri',
      one: '1 commit',
    );
    return '$author a făcut push la $_temp0';
  }

  @override
  String prTimelineApproved(String author) {
    return '$author a aprobat aceste modificări';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return '$author a cerut modificări';
  }

  @override
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de comentarii de cod',
      few: '# comentarii de cod',
      one: '1 comentariu de cod',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '$author a revizuit';
  }

  @override
  String get prTimelineSomeone => 'Cineva';

  @override
  String get prTimelineBotBadge => 'bot';

  @override
  String updatedAgo(String age) {
    return 'Actualizat $age';
  }

  @override
  String get checksPassing => 'Verificări reușite';

  @override
  String get checksRunning => 'Verificări în rulare';

  @override
  String get needsYourReview => 'Necesită revizuirea ta';

  @override
  String get checks => 'Verificări';

  @override
  String get noReviewersAssigned => 'Niciun recenzent asignat';

  @override
  String get noAssignees => 'Niciun asignat';

  @override
  String get loadingEllipsis => 'Se încarcă…';

  @override
  String get loadingChecks => 'Se încarcă verificările…';

  @override
  String get noChecksYet => 'Nicio verificare nu a rulat încă';

  @override
  String get noChangesToReview => 'Nicio modificare de revizuit';

  @override
  String checksFailingCount(int count) {
    return '$count eșuate';
  }

  @override
  String get showMore => 'Afișează mai multe';

  @override
  String get showLess => 'Afișează mai puține';

  @override
  String get backToPullRequests => 'Înapoi la pull request-uri';

  @override
  String get pullRequestNotFound => 'Pull request negăsit';

  @override
  String get pullRequestNotFoundBody =>
      'Poate a fost fuzionat, închis sau mutat.';

  @override
  String get couldntLoadPullRequest =>
      'Nu s-a putut încărca acest pull request';

  @override
  String get showDetails => 'Afișează detaliile';

  @override
  String get noDescriptionProvided => 'Nicio descriere furnizată.';

  @override
  String get factsHint =>
      'Faptele vor apărea aici pe măsură ce agenții tăi învață.';

  @override
  String get noFactsMatch => 'Niciun fapt nu se potrivește căutării';

  @override
  String get memoryLoadError => 'Nu s-a putut încărca memoria';

  @override
  String get sortRecent => 'Recente';

  @override
  String get sortConfidence => 'Încredere';

  @override
  String get confidenceTooltip =>
      'Cât de siguri sunt agenții că acest fapt e adevărat, de la 0 la 100%.';

  @override
  String get supersededTooltip => 'Un fapt mai nou l-a înlocuit pe acesta.';

  @override
  String get domain => 'Domeniu';

  @override
  String get fitToView => 'Potrivește în vizualizare';

  @override
  String get project => 'Proiect';

  @override
  String get newProject => 'Proiect nou';

  @override
  String get editProject => 'Editează proiectul';

  @override
  String get deleteProject => 'Șterge proiectul';

  @override
  String get noProject => 'Fără proiect';

  @override
  String get allTickets => 'Toate tichetele';

  @override
  String get projectNamePlaceholder => 'Nume proiect';

  @override
  String get projectDescriptionPlaceholder => 'Descriere (opțional)';

  @override
  String get projectColorLabel => 'Culoare';

  @override
  String get noProjectsYet => 'Niciun proiect încă';

  @override
  String get projectTicketsEmpty => 'Niciun tichet în acest proiect încă';

  @override
  String get createProject => 'Creează proiect';

  @override
  String projectProgress(int done, int total) {
    return '$done din $total gata';
  }

  @override
  String deleteProjectConfirm(String name) {
    return 'Ștergi \"$name\"? Tichetele sunt păstrate și scoase din proiect.';
  }

  @override
  String get projectStatusActive => 'Activ';

  @override
  String get projectStatusCompleted => 'Finalizat';

  @override
  String get projectStatusArchived => 'Arhivat';

  @override
  String get markProjectCompleted => 'Marchează finalizat';

  @override
  String get markProjectActive => 'Marchează activ';

  @override
  String get archiveProject => 'Arhivează';

  @override
  String get restoreProject => 'Restaurează';

  @override
  String get relations => 'Relații';

  @override
  String get relateTo => 'Leagă de';

  @override
  String get relationSubIssueOf => 'Sub-issue al…';

  @override
  String get relationParentOf => 'Părinte al…';

  @override
  String get relationBlockedBy => 'Blocat de…';

  @override
  String get relationBlocking => 'Blochează…';

  @override
  String get relationRelatedTo => 'Legat de…';

  @override
  String get relationDuplicateOf => 'Duplicat al…';

  @override
  String get relationGroupParent => 'Părinte';

  @override
  String get relationGroupSubIssues => 'Sub-issue-uri';

  @override
  String get relationGroupBlockedBy => 'Blocat de';

  @override
  String get relationGroupBlocking => 'Blochează';

  @override
  String get relationGroupRelated => 'Legate';

  @override
  String get relationGroupDuplicateOf => 'Duplicat al';

  @override
  String get relationGroupDuplicatedBy => 'Duplicat de';

  @override
  String get copyId => 'Copiază ID';

  @override
  String get ticketIdCopied => 'ID tichet copiat';

  @override
  String get searchTicketsHint => 'Caută tichete…';

  @override
  String get noMatchingTickets => 'Niciun tichet potrivit';

  @override
  String get clearAll => 'Golește tot';

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '# de PR-uri',
      few: '# PR-uri',
      one: '1 PR',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '# de depozite',
      few: '# depozite',
      one: '1 depozit',
    );
    return '$_temp0 așteaptă revizuirea ta în $_temp1';
  }

  @override
  String get manageWorkspacesSubtitle =>
      'Redenumește un spațiu de lucru și schimbă-i marca — alege unul din stânga ca să-l editezi.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de spații de lucru',
      few: '# spații de lucru',
      one: '1 spațiu de lucru',
      zero: 'Niciun spațiu de lucru',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '# de depozite',
      few: '# depozite',
      one: '1 depozit',
      zero: 'Niciun depozit',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '# de agenți',
      few: '# agenți',
      one: '1 agent',
      zero: '0 agenți',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'Identitate';

  @override
  String get uploadImage => 'Încarcă imagine';

  @override
  String get failedToSaveLogo =>
      'Nu s-a putut salva imaginea logo-ului. Asigură-te că aplicația poate citi fișierul selectat.';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG sau GIF până la 2 MB. Altfel vom folosi inițiala spațiului de lucru.';

  @override
  String get workspaceNameFieldHelp =>
      'Afișat în selector, în breadcrumb și pe fiecare ecran.';

  @override
  String get dangerZone => 'Zonă periculoasă';

  @override
  String get deleteThisWorkspace => 'Șterge acest spațiu de lucru';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return 'Elimină definitiv $name, conexiunile la depozite, agenții și memoria. Acțiunea nu poate fi anulată.';
  }

  @override
  String get discard => 'Renunță';

  @override
  String discardChangesQuestion(String name) {
    return 'Renunți la modificările nesalvate la $name?';
  }

  @override
  String get workspaceUpdated => 'Spațiu de lucru actualizat';

  @override
  String get editTitle => 'Editează titlul';

  @override
  String get editDescription => 'Editează descrierea';

  @override
  String get addDescription => 'Adaugă o descriere';

  @override
  String get prTitlePlaceholder => 'Titlu';

  @override
  String get prBodyPlaceholder => 'Lasă o descriere';

  @override
  String get write => 'Scrie';

  @override
  String get overview => 'Prezentare';

  @override
  String get noFilesChanged => 'Niciun fișier modificat';

  @override
  String get diff => 'Diff';

  @override
  String get preview => 'Previzualizare';

  @override
  String get imageDiffBefore => 'Înainte';

  @override
  String get imageDiffAfter => 'După';

  @override
  String get imageDiffModeTwoUp => 'Una lângă alta';

  @override
  String get imageDiffModeSwipe => 'Glisează';

  @override
  String get imageDiffModeDifference => 'Diferență';

  @override
  String imageDiffChangedPercent(String percent) {
    return '$percent% modificat';
  }

  @override
  String get imageDiffPictures => 'Imagini';

  @override
  String get imageDiffSource => 'Sursă';

  @override
  String get imageDiffDeleted => 'Șters';

  @override
  String get imageDiffAdded => 'Adăugat';

  @override
  String imageDiffDimensions(int width, int height) {
    return 'L: ${width}px | Î: ${height}px';
  }

  @override
  String get outdated => 'Învechit';

  @override
  String get outdatedComments => 'Comentarii învechite';

  @override
  String outdatedCountLabel(int count) {
    return '$count învechite';
  }

  @override
  String get prTemplateLabel => 'Șablon';

  @override
  String get prTemplateDefault => 'Implicit';

  @override
  String get addReviewers => 'Adaugă recenzenți';

  @override
  String get reRequestReview => 'Solicită din nou recenzia';

  @override
  String reRequestReviewFor(String label) {
    return 'Solicită din nou recenzia de la $label';
  }

  @override
  String get addAssignees => 'Adaugă asignați';

  @override
  String get addLabels => 'Adaugă etichete';

  @override
  String get searchLabels => 'Caută etichete…';

  @override
  String get noMatchingLabels => 'Nicio etichetă potrivită';

  @override
  String removeLabel(String label) {
    return 'Elimină $label';
  }

  @override
  String get searchUsers => 'Caută persoane…';

  @override
  String get searchReviewers => 'Caută persoane și echipe…';

  @override
  String get usersSectionLabel => 'Persoane';

  @override
  String get userStatusBusy => 'Ocupat';

  @override
  String get teamsSectionLabel => 'Echipe';

  @override
  String get suggestedReviewers => 'Recenzenți sugerați';

  @override
  String get noMatchingUsers => 'Nicio persoană potrivită';

  @override
  String get noMatchingReviewers => 'Nicio potrivire';

  @override
  String get requiredByCodeOwners => 'Obligatoriu de code owners';

  @override
  String reviewedOnBehalfOf(String login) {
    return 'prin $login';
  }

  @override
  String get team => 'Echipă';

  @override
  String get markdownBold => 'Aldin';

  @override
  String get markdownItalic => 'Cursiv';

  @override
  String get markdownHeading => 'Titlu';

  @override
  String get markdownBulletList => 'Listă cu puncte';

  @override
  String get markdownChecklist => 'Listă de verificare';

  @override
  String get markdownCode => 'Cod';

  @override
  String get markdownLink => 'Link';

  @override
  String get markdownQuote => 'Citat';

  @override
  String get markdownSupported => 'Markdown este acceptat';

  @override
  String get markdownAttachImages => 'Apasă ca să adaugi imagini';

  @override
  String failedToUpdateTitle(String error) {
    return 'Nu s-a putut actualiza titlul: $error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'Nu s-a putut actualiza descrierea: $error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'Nu s-au putut actualiza recenzenții: $error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'Nu s-au putut actualiza asignații: $error';
  }

  @override
  String failedToUpdateLabels(String error) {
    return 'Nu s-au putut actualiza etichetele: $error';
  }

  @override
  String get discardChangesConfirm => 'Renunți la modificări?';

  @override
  String get newPr => 'PR nou';

  @override
  String get openPullRequest => 'Deschide un pull request';

  @override
  String get composePrSubtitle =>
      'Dintr-o ramură pe care ai făcut push — fără agenți sau tichete';

  @override
  String get createAsDraft => 'Creează ca ciornă';

  @override
  String get composePrPickBranches =>
      'Alege o ramură de bază și una de comparat ca să previzualizezi modificările.';

  @override
  String get composePrNothingToCompare =>
      'Nu există modificări între aceste ramuri.';

  @override
  String get repository => 'Depozit';

  @override
  String get baseBranchLabel => 'Bază';

  @override
  String get compareBranchLabel => 'Compară';

  @override
  String get selectBranch => 'Selectează o ramură';

  @override
  String get navMeetings => 'Întâlniri';

  @override
  String get meetingsNoWorkspace =>
      'Selectează un spațiu de lucru ca să vezi întâlnirile.';

  @override
  String get meetingsEmpty => 'Nicio întâlnire încă';

  @override
  String get meetingsEmptyHint =>
      'Înregistrează prima întâlnire — audio-ul rămâne pe acest dispozitiv, iar agentul îl transformă în note, decizii și elemente de acțiune.';

  @override
  String get meetingNotesHint =>
      'Notează rapid — agentul le dezvoltă după întâlnire.';

  @override
  String get meetingSpeakerMe => 'Tu';

  @override
  String get meetingStatusRecording => 'Se înregistrează';

  @override
  String get meetingStatusPaused => 'Pauză';

  @override
  String get meetingStatusProcessing => 'Se procesează';

  @override
  String get meetingStatusDone => 'Gata';

  @override
  String get meetingStatusFailed => 'Eșuat';

  @override
  String get meetingsSubtitle =>
      'Captate și transcrise pe acest dispozitiv, apoi rezumate de un agent.';

  @override
  String get meetingsRecordMeeting => 'Înregistrează întâlnirea';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# se procesează acum',
      few: '# se procesează acum',
      one: '1 se procesează acum',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLiveOpen => 'Deschide înregistrarea';

  @override
  String get meetingTemplateShort => 'Șablon';

  @override
  String get meetingsFilterAll => 'Toate';

  @override
  String get meetingsFilterDone => 'Gata';

  @override
  String get meetingsFilterProcessing => 'Se procesează';

  @override
  String get meetingsSearchHint => 'Filtrează după titlu, persoană, aplicație…';

  @override
  String get meetingsBucketToday => 'Azi';

  @override
  String get meetingsBucketYesterday => 'Ieri';

  @override
  String get meetingsBucketEarlierThisWeek => 'Mai devreme săptămâna aceasta';

  @override
  String get meetingsBucketLastWeek => 'Săptămâna trecută';

  @override
  String get meetingsBucketOlder => 'Mai vechi';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de decizii',
      few: '# decizii',
      one: '1 decizie',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total elemente de acțiune';
  }

  @override
  String get meetingsTranscribing => 'se transcrie și se rezumă…';

  @override
  String get meetingsOpenAction => 'Deschide';

  @override
  String get meetingsStopProcessing => 'Oprește';

  @override
  String get meetingsStillTranscribing =>
      'Încă se transcrie — rezumatul apare când se termină.';

  @override
  String get meetingsNoMatch => 'Nicio întâlnire potrivită';

  @override
  String get meetingsNoMatchHint =>
      'Încearcă alt filtru sau alt termen de căutare.';

  @override
  String get meetingBackAllMeetings => 'Toate întâlnirile';

  @override
  String get meetingReRunSummary => 'Reia rezumatul';

  @override
  String get meetingExport => 'Exportă';

  @override
  String get meetingAugmentingBanner =>
      'Se îmbunătățesc notele din transcriere — se extrag decizii și elemente de acțiune…';

  @override
  String get meetingTabNotes => 'Note';

  @override
  String get meetingTabTranscript => 'Transcriere';

  @override
  String get meetingTabActionItems => 'Elemente de acțiune';

  @override
  String get meetingTabDecisions => 'Decizii';

  @override
  String get meetingNotesEnhancedToggle => 'Îmbunătățite';

  @override
  String get meetingNotesYoursToggle => 'Notele tale';

  @override
  String get meetingEnhancedByAgent => 'Îmbunătățit de agent · din transcriere';

  @override
  String get meetingEnhancedPending =>
      'Agentul încă lucrează la acest rezumat.';

  @override
  String get meetingNotesEmpty => 'Nicio notă îmbunătățită încă.';

  @override
  String get meetingNotesSavedLocally => 'Salvat local';

  @override
  String get meetingNotesSaving => 'Se salvează…';

  @override
  String get meetingViewFullTranscript => 'Vezi transcrierea completă';

  @override
  String get meetingTranscriptSearchHint => 'Caută în transcriere…';

  @override
  String get meetingSpeakerEveryone => 'Toți';

  @override
  String get meetingSpeakerOthers => 'Alții';

  @override
  String get meetingTranscriptEmpty => 'Nicio transcriere încă.';

  @override
  String get meetingActionItemsEmpty => 'Niciun element de acțiune extras.';

  @override
  String get meetingActionItemFrom => 'din această întâlnire';

  @override
  String get meetingCreateTicket => 'Creează tichet';

  @override
  String meetingTicketCreated(String key) {
    return 'Tichetul $key a fost creat și trimis.';
  }

  @override
  String get meetingTicketFailed => 'Nu s-a putut crea tichetul.';

  @override
  String get meetingDecisionsEmpty => 'Nicio decizie înregistrată.';

  @override
  String get meetingEditTitle => 'Editează titlul';

  @override
  String get meetingTitleLabel => 'Titlu';

  @override
  String get meetingAddActionItem => 'Adaugă element de acțiune';

  @override
  String get meetingEditActionItem => 'Editează elementul de acțiune';

  @override
  String get meetingDeleteActionItem => 'Șterge elementul de acțiune';

  @override
  String get meetingActionItemContentLabel => 'Element de acțiune';

  @override
  String get meetingActionItemContentHint => 'Ce trebuie să se întâmple?';

  @override
  String get meetingActionItemOwnerLabel => 'Proprietar';

  @override
  String get meetingActionItemOwnerHint => 'Cine e responsabil? (opțional)';

  @override
  String get meetingAddDecision => 'Adaugă decizie';

  @override
  String get meetingEditDecision => 'Editează decizia';

  @override
  String get meetingDeleteDecision => 'Șterge decizia';

  @override
  String get meetingDecisionContentLabel => 'Decizie';

  @override
  String get meetingDecisionContentHint => 'Ce s-a decis?';

  @override
  String get meetingReRunStarted => 'Se reia rezumatorul pe transcriere…';

  @override
  String get meetingReRunNoTranscript =>
      'Nu există încă o transcriere de rezumat.';

  @override
  String get meetingNotesEmptyDescription =>
      'Generează-le din transcriere sau scrie-le pe ale tale.';

  @override
  String get meetingNotesGenerate => 'Generează notițe';

  @override
  String get meetingNotesWriteOwn => 'Scrie-le pe ale tale';

  @override
  String get meetingNothingTranscribed => 'Nu s-a transcris nimic.';

  @override
  String get meetingNothingTranscribedDescription =>
      'Nu există o transcriere de rezumat, dar îți poți păstra propriile notițe.';

  @override
  String get meetingOverviewSpeakers => 'Vorbitori';

  @override
  String get meetingOverviewSpeakersEmpty =>
      'Timpul de vorbire al fiecărui vorbitor apare când există o transcriere.';

  @override
  String meetingOverviewMoreSpeakers(int count) {
    return 'Încă $count';
  }

  @override
  String meetingOverviewSpeakerShare(
    String name,
    String share,
    String duration,
  ) {
    return '$name: $share din timpul de vorbire, $duration';
  }

  @override
  String get meetingOverviewActionItemsAllDone =>
      'Toate elementele de acțiune sunt finalizate.';

  @override
  String meetingOverviewViewAll(int count) {
    return 'Vezi toate ($count)';
  }

  @override
  String get meetingExportCopied =>
      'Notele au fost copiate în clipboard ca Markdown.';

  @override
  String get meetingExportSaved => 'Întâlnirea a fost exportată.';

  @override
  String meetingExportFailed(String error) {
    return 'Exportul a eșuat: $error';
  }

  @override
  String get meetingExportNothing => 'Nu e nimic de exportat încă.';

  @override
  String get meetingPlaybackPlay => 'Redă';

  @override
  String get meetingPlaybackPause => 'Pauză';

  @override
  String get meetingPlaybackUnavailable =>
      'Redarea audio nu este disponibilă pe acest dispozitiv.';

  @override
  String get meetingDetectedTitle => 'Întâlnire detectată';

  @override
  String meetingDetectedSubtitle(String label) {
    return 'Se pare că „$label” are loc. O înregistrezi?';
  }

  @override
  String get meetingDetectedSubtitleGeneric =>
      'Se pare că are loc o întâlnire. O înregistrezi?';

  @override
  String get meetingDetectedDismiss => 'Închide';

  @override
  String get meetingAutoStopTitle =>
      'Întâlnirea pare încheiată. Oprești înregistrarea?';

  @override
  String get meetingAutoStopStop => 'Oprește';

  @override
  String get meetingAutoStopKeep => 'Continuă înregistrarea';

  @override
  String get meetingAutoDetect => 'Detectează automat întâlnirile';

  @override
  String get meetingAutoDetectDescription =>
      'Urmărește calendarul și aplicațiile de conferințe și propune înregistrarea când începe o întâlnire.';

  @override
  String get meetingsRecordingCrumb => 'Se înregistrează…';

  @override
  String get meetingRecordTitleHint => 'Titlu întâlnire';

  @override
  String get meetingRecordTappingLabel => 'Se captează:';

  @override
  String get meetingRecordMic => 'Microfon';

  @override
  String get meetingRecordSystemAudio => 'Audio sistem';

  @override
  String get meetingRecordPause => 'Pauză';

  @override
  String get meetingRecordResume => 'Reia';

  @override
  String get meetingRecordStop => 'Oprește și rezumă';

  @override
  String get meetingRecordYourNotes => 'Notele tale';

  @override
  String get meetingRecordNotesPlaceholder =>
      'Tastează în timp ce asculți. Câteva fragmente sunt suficiente — după ce oprești, agentul le dezvoltă folosind transcrierea.';

  @override
  String get meetingRecordLiveTranscript => 'Transcriere live';

  @override
  String get meetingRecordDecoding => 'decodare pe dispozitiv';

  @override
  String get meetingRecordListening =>
      'Se ascultă… vorbirea apare aici în una-două secunde, etichetată Tu / Alții.';

  @override
  String get meetingRecordPausedHint =>
      'Pauză — audio-ul este ignorat până reiei.';

  @override
  String get meetingRecordNotActive => 'Nicio înregistrare activă.';

  @override
  String get meetingHudRecording => 'se înregistrează';

  @override
  String get meetingHudPaused => 'pauză';

  @override
  String get meetingHudOpen => 'Deschide';

  @override
  String get meetingHudStop => 'Oprește';

  @override
  String get meetingToolbarPopOut => 'Desprinde';

  @override
  String get meetingToolbarHoldToStop =>
      'Ține apăsat pentru a opri înregistrarea';

  @override
  String get meetingToolbarSemanticLabel => 'Bară de înregistrare a întâlnirii';

  @override
  String get orchestrate => 'Orchestrează';

  @override
  String get orchestrationUnavailable => 'Orchestrarea nu este disponibilă';

  @override
  String get orchestrationApprove => 'Aprobă planul';

  @override
  String get orchestrationReject => 'Respinge';

  @override
  String get orchestrationCancel => 'Anulează orchestrarea';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count roluri — $hires angajări noi';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count sub-tichete';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'Cost estimat: \$$amount';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total sub-tichete gata';
  }

  @override
  String get orchestrationStatusProposed => 'Propus';

  @override
  String get orchestrationStatusApproved => 'Aprobat';

  @override
  String get orchestrationStatusExecuting => 'Se execută';

  @override
  String get orchestrationStatusSynthesizing => 'Se sintetizează';

  @override
  String get orchestrationStatusCompleted => 'Finalizat';

  @override
  String get orchestrationStatusFailed => 'Eșuat';

  @override
  String get orchestrationStatusCancelled => 'Anulat';

  @override
  String get messageFailed => 'Rularea a eșuat';

  @override
  String get turnLimitReached =>
      'Oprit la limita de tururi — răspunde ca să continui';

  @override
  String get retried => 'Reîncercat';

  @override
  String replyingTo(String name) {
    return 'răspunde lui $name';
  }

  @override
  String get silenceTimeoutLabel => 'Timeout de tăcere (minute)';

  @override
  String get silenceTimeoutHint =>
      'de ex. 15 — termină o rulare după atât timp fără ieșire';

  @override
  String get capabilityJsonMode => 'Mod JSON';

  @override
  String get capabilityModelSelection => 'Selectare model';

  @override
  String get transcriptThinking => 'Se gândește…';

  @override
  String transcriptThoughtFor(String duration) {
    return 'S-a gândit $duration';
  }

  @override
  String get transcriptStatusMakingEdits => 'Se fac modificări…';

  @override
  String get transcriptStatusReadingFiles => 'Se citesc fișierele…';

  @override
  String get transcriptStatusSearching => 'Se caută în codebase…';

  @override
  String get transcriptStatusRunningCommands => 'Se rulează comenzi…';

  @override
  String get transcriptStatusResponding => 'Se răspunde…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return 'Se rulează $tool…';
  }

  @override
  String get transcriptInput => 'Intrare';

  @override
  String get transcriptOutput => 'Ieșire';

  @override
  String get transcriptErrorLabel => 'Eroare';

  @override
  String get transcriptSandboxBlocked => 'Sandbox-ul a blocat o acțiune';

  @override
  String transcriptShowFullOutput(int kb) {
    return 'Afișează ieșirea completă (+$kb KB)';
  }

  @override
  String transcriptShowAllLines(int count) {
    return 'Afișează toate cele $count linii';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return 'Se afișează primele $count linii';
  }

  @override
  String get transcriptGrepNoMatches => 'Nicio potrivire';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '# de potriviri',
      few: '# potriviri',
      one: '1 potrivire',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '# de fișiere',
      few: '# fișiere',
      one: '1 fișier',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return 'Persoana $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => 'Redenumește vorbitorul';

  @override
  String get meetingRenameSpeakerTitle => 'Redenumește vorbitorul';

  @override
  String get meetingSpeakerNameLabel => 'Nume';

  @override
  String get meetingSpeakerSuggestFromCalendar =>
      'Dintre invitații acestei întâlniri';

  @override
  String get meetingRenameSpeakerApplyAll =>
      'Aplică la toate blocurile acestui vorbitor';

  @override
  String get meetingRenameSpeakerScopeHint =>
      'Când e oprit, se redenumește doar linia selectată.';

  @override
  String get meetingLinkEvent => 'Leagă de eveniment';

  @override
  String get meetingChangeEvent => 'Schimbă evenimentul';

  @override
  String get meetingLinkEventTitle => 'Leagă de un eveniment din calendar';

  @override
  String get meetingLinkEventSearchHint => 'Caută evenimente';

  @override
  String get meetingLinkEventEmpty =>
      'Niciun eveniment de calendar în apropiere';

  @override
  String get meetingUnlinkEvent => 'Elimină legătura';

  @override
  String get calendarLinkExistingMeeting => 'Leagă de o întâlnire existentă';

  @override
  String get calendarLinkMeetingTitle => 'Leagă o întâlnire';

  @override
  String get calendarLinkMeetingSearchHint => 'Caută întâlniri';

  @override
  String get calendarLinkMeetingEmpty => 'Nicio întâlnire de legat';

  @override
  String get meetingRenameSpeakerFailed => 'Nu s-a putut redenumi vorbitorul';

  @override
  String get calendarLinkUpdateFailed =>
      'Nu s-a putut actualiza legătura de calendar';

  @override
  String get rename => 'Redenumește';

  @override
  String get notNow => 'Nu acum';

  @override
  String get meetingSaveVoiceProfileTitle => 'Salvezi profilul vocal?';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return 'Recunoaște-l pe $name automat în întâlnirile viitoare salvându-i amprenta vocală.';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return 'Profil vocal salvat pentru $name';
  }

  @override
  String get meetingVoiceProfileSaveFailed =>
      'Nu s-a putut salva profilul vocal';

  @override
  String get voiceProfilesSection => 'Profiluri vocale';

  @override
  String get voiceProfilesDescription =>
      'Vocile salvate sunt recunoscute automat în întâlnirile viitoare.';

  @override
  String get voiceProfilesEmpty =>
      'Nicio voce salvată încă. Numește un vorbitor într-o transcriere de întâlnire, apoi alege „Salvează profilul vocal”.';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de eșantioane',
      few: '# eșantioane',
      one: '1 eșantion',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => 'Redenumește profilul vocal';

  @override
  String get deleteVoiceProfileTitle => 'Ștergi profilul vocal?';

  @override
  String deleteVoiceProfileBody(String name) {
    return 'Oprești recunoașterea lui $name? Amprenta vocală salvată este eliminată. Numele deja aplicate în întâlnirile anterioare sunt păstrate.';
  }

  @override
  String get connectedLabel => 'Conectat';

  @override
  String get ideTabGeneral => 'General';

  @override
  String get ideTabExplorer => 'Explorer';

  @override
  String get ideTabSourceControl => 'Control sursă';

  @override
  String get generalSectionTodos => 'Todo-uri';

  @override
  String get generalSectionGoals => 'Obiective';

  @override
  String get goalRunStatusActive => 'Activ';

  @override
  String get goalRunStatusPaused => 'Pauză';

  @override
  String get goalRunStatusCompleted => 'Finalizat';

  @override
  String get goalRunStatusFailed => 'Eșuat';

  @override
  String get goalRunStatusCancelled => 'Anulat';

  @override
  String get goalRunStatusBudgetExhausted => 'Buget epuizat';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return 'Rularea $run din $max · $cost din $cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return 'Rularea $run · $cost din $cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return 'Termen $deadline';
  }

  @override
  String get goalRunPause => 'Pune obiectivul în pauză';

  @override
  String get goalRunResume => 'Reia obiectivul';

  @override
  String goalRunResumeRaise(String cap) {
    return 'Reia · ridică plafonul la $cap';
  }

  @override
  String get goalRunStop => 'Oprește obiectivul';

  @override
  String get generalSectionAgents => 'Agenți';

  @override
  String get generalSectionTerminals => 'Terminale';

  @override
  String get generalTodosEmpty => 'Niciun todo încă';

  @override
  String get generalAgentsEmpty => 'Niciun agent în rulare';

  @override
  String get generalTerminalsEmpty => 'Niciun terminal deschis';

  @override
  String get generalSectionBrowsers => 'Browsere';

  @override
  String get generalSectionComputers => 'Computere';

  @override
  String get generalBrowsersEmpty => 'Niciun browser deschis';

  @override
  String get generalComputersEmpty => 'Niciun computer deschis';

  @override
  String get generalSectionPhones => 'Telefoane';

  @override
  String get generalPhonesEmpty => 'Niciun telefon deschis';

  @override
  String get pauseAgent => 'Pune agentul în pauză';

  @override
  String get resumeAgent => 'Reia agentul';

  @override
  String get agentCannotPause =>
      'Acest agent nu poate fi pus în pauză — oprește-l în schimb.';

  @override
  String get goalClear => 'Golește obiectivul';

  @override
  String get undoLabelGoalClear => 'golește obiectivul';

  @override
  String get todoStatusPending => 'Nestartat';

  @override
  String get todoStatusInProgress => 'În curs';

  @override
  String get todoStatusCompleted => 'Gata';

  @override
  String get reorderTodo => 'Reordonează todo-ul';

  @override
  String get focusTerminal => 'Focalizează terminalul';

  @override
  String get focusMachine => 'Focalizează mașina';

  @override
  String get focusBrowser => 'Focalizează browserul';

  @override
  String get todoEditorTitle => 'Editează todo-urile';

  @override
  String get todoEditorHint =>
      'Un element pe linie. Folosește - [ ] pentru în așteptare, - [~] pentru în curs, - [x] pentru gata.';

  @override
  String get todoNeedsText => 'Adaugă text după comandă';

  @override
  String get todoNotFound => 'Niciun todo potrivit';

  @override
  String get todoCleared => 'Lista de todo-uri a fost golită';

  @override
  String get todoNothingToCopy => 'Nimic de copiat';

  @override
  String todoAdded(String content) {
    return 'S-a adăugat \"$content\"';
  }

  @override
  String todoStarted(String content) {
    return 'S-a pornit \"$content\"';
  }

  @override
  String todoCompleted(String content) {
    return 'S-a finalizat \"$content\"';
  }

  @override
  String todoRemoved(String content) {
    return 'S-a eliminat \"$content\"';
  }

  @override
  String todoCopied(int count) {
    return 'S-au copiat $count elemente';
  }

  @override
  String todoImported(int count) {
    return 'S-au importat $count elemente';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return 'Comandă todo necunoscută \"$name\"';
  }

  @override
  String get terminal => 'Terminal';

  @override
  String get ideCloseTab => 'Închide fila';

  @override
  String get ideSplitEditor => 'Împarte editorul';

  @override
  String get ideSplitRight => 'Împarte la dreapta';

  @override
  String get ideSplitDown => 'Împarte în jos';

  @override
  String get ideSplitLeft => 'Împarte la stânga';

  @override
  String get ideSplitUp => 'Împarte în sus';

  @override
  String get ideCloseGroup => 'Închide grupul';

  @override
  String get ideCloseOthers => 'Închide celelalte';

  @override
  String get ideCloseToRight => 'Închide spre dreapta';

  @override
  String get ideCloseSaved => 'Închide salvatele';

  @override
  String get ideCloseAll => 'Închide tot';

  @override
  String get ideSplit => 'Împarte';

  @override
  String get ideToggleSidebar => 'Comută bara laterală';

  @override
  String get ideNewTab => 'Deschide editorul';

  @override
  String get ideNewTabMenu => 'Filă nouă';

  @override
  String get ideReviewCode => 'Revizuiește codul';

  @override
  String ideReviewCodeInRepo(String repo) {
    return 'Revizuiește codul ($repo)';
  }

  @override
  String get ideRevertConfirmTitle => 'Revino asupra modificărilor';

  @override
  String get ideRevertUntracked => 'Fișierele untracked nu pot fi revertate';

  @override
  String get ideRevertFailed =>
      'Nu s-au putut reveni asupra fișierelor. Worktree-ul conversației poate fi indisponibil.';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de fișiere',
      few: '# fișiere',
      one: '1 fișier',
    );
    return '$_temp0 nu au putut fi revertate (untracked).';
  }

  @override
  String get ideSearchMatchCase => 'Potrivește majusculele';

  @override
  String get ideSearchWholeWord => 'Cuvânt întreg';

  @override
  String get ideSearchRegex => 'Regex';

  @override
  String get ideSearchFilters => 'Filtre de căutare';

  @override
  String get ideSearchFilesToInclude => 'Fișiere de inclus';

  @override
  String get ideSearchFilesToExclude => 'Fișiere de exclus';

  @override
  String get ideNoOpenTabs =>
      'Nicio filă deschisă — folosește + ca să deschizi';

  @override
  String get ideBrowserAddressHint => 'Introdu adresa sau caută';

  @override
  String get ideSimpleWebBrowser => 'Browser web simplu';

  @override
  String get ideWebBrowser => 'Browser web';

  @override
  String get ideBrowserEnterUrl =>
      'Introdu un URL în bara de adresă ca să începi navigarea';

  @override
  String get ideCodeServer => 'Editor';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return 'Salvezi modificările la $fileName?';
  }

  @override
  String get ideUnsavedChangesBody =>
      'Modificările se vor pierde dacă nu le salvezi.';

  @override
  String get ideDontSave => 'Nu salva';

  @override
  String get editorAutoSave => 'Salvare automată';

  @override
  String get editorAutoSaveDescription =>
      'Salvează automat modificările în editorul încorporat.';

  @override
  String get editorAutoSaveOff => 'Oprit';

  @override
  String get editorAutoSaveAfterDelay => 'După o întârziere';

  @override
  String get editorAutoSaveOnFocusChange => 'La schimbarea focusului';

  @override
  String get ideCodeServerUnavailable =>
      'Code-server nu este disponibil pe acest server';

  @override
  String get ideCodeServerUnavailableHint =>
      'Instalează code-server (coder/code-server) pe gazda serverului, apoi redeschide editorul.';

  @override
  String get ideCodeServerInstalling => 'Se pregătește editorul…';

  @override
  String get ideCodeServerOpenInBrowser => 'Deschide editorul în browser';

  @override
  String get ideCodeServerError => 'Nu s-a putut deschide editorul';

  @override
  String get paneSuspendedCaption =>
      'Suspendat ca să economisească resurse — se reîncarcă la focalizare';

  @override
  String get ideFolderLoadFailed => 'Nu s-a putut încărca acest folder';

  @override
  String get ideFileSearchFailed => 'Nu s-au putut căuta fișierele';

  @override
  String get ideSearchInFiles => 'Caută în fișiere';

  @override
  String get ideNoContentMatches => 'Nicio potrivire';

  @override
  String get ideSourceControlCreatePr => 'Creează pull request';

  @override
  String get ideSourceControlNoChanges => 'Nicio modificare';

  @override
  String get noReposInConversation => 'Niciun depozit în această conversație';

  @override
  String get ideSourceControlNoSpace =>
      'Deschide o conversație ca să-i vezi modificările';

  @override
  String get ideFileLoading => 'Se încarcă…';

  @override
  String get ideFileBinary => 'Fișier binar';

  @override
  String get mcpApprovalMode => 'Aprobare instrumente';

  @override
  String get mcpApprovalModeDescription =>
      'Ce acțiuni ale propriilor unelte ale Control Center, apelate prin endpointul său MCP sau de agenții săi, rulează fără întrebare. Citirile sunt mereu permise; nivelurile superioare cer confirmare. Serverele din interiorul unei rulări urmează politica de acțiuni a acelei rulări.';

  @override
  String get mcpApprovalAlwaysAsk => 'Întreabă întotdeauna';

  @override
  String get mcpApprovalWrite => 'Aprobă automat scrierile';

  @override
  String get mcpApprovalYolo => 'Aprobă tot automat';

  @override
  String get mcpReconnect => 'Reconectează';

  @override
  String get mcpStatusConnected => 'Conectat';

  @override
  String get mcpStatusConnecting => 'Se conectează…';

  @override
  String get mcpStatusNeedsAuth => 'Necesită autorizare';

  @override
  String get mcpStatusFailed => 'Eșuat';

  @override
  String get mcpStatusCircuitOpen => 'Pauză';

  @override
  String get mcpStatusDisabled => 'Dezactivat';

  @override
  String get providersAndModels => 'Provideri și modele';

  @override
  String get providersAndModelsDescription =>
      'Listează fiecare provider pe care îl poate folosi agentul încorporat — setează o cheie API sau autentifică-te în browser, vezi modelele și prețurile fiecărui provider conectat și controlează ce provideri poate folosi acest spațiu de lucru.';

  @override
  String get syncNow => 'Sincronizează acum';

  @override
  String syncNowResult(int applied, int failed) {
    return 'Sincronizare completă — $applied aplicate, $failed eșuate';
  }

  @override
  String syncNowFailed(String error) {
    return 'Sincronizarea a eșuat: $error';
  }

  @override
  String get denied => 'Refuzat';

  @override
  String get allowed => 'Permis';

  @override
  String allowProviderSemantic(String provider) {
    return 'Permite $provider';
  }

  @override
  String enabledViaEnv(String key) {
    return 'Activat prin $key';
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
  String get subscriptionUsage => 'Utilizare abonament';

  @override
  String get subscriptionUsageUnavailable => 'Indisponibil';

  @override
  String get subscriptionUsageExhausted => 'Cotă epuizată';

  @override
  String get subscriptionUsageSignInRequired => 'Autentifică-te din nou';

  @override
  String get subscriptionUsageSignInExpired =>
      'Autentificarea a expirat, se reînnoiește la următoarea rulare';

  @override
  String subscriptionUsagePercentUsed(int percent) {
    return '$percent% folosit';
  }

  @override
  String resetsIn(String duration) {
    return 'Se resetează în $duration';
  }

  @override
  String get feedbackHelpful => 'A fost util';

  @override
  String get feedbackNotHelpful => 'Nu a fost util';

  @override
  String get modeChat => 'Chat';

  @override
  String get modePlan => 'Plan';

  @override
  String get modeReview => 'Revizuire';

  @override
  String get modeOrchestrate => 'Orchestrează';

  @override
  String get editorTheme => 'Temă editor';

  @override
  String get editorThemeDescription =>
      'Importă o temă de culoare VS Code ca diff-ul și editorul încorporat să se potrivească cu IDE-ul tău.';

  @override
  String get editorThemePasteHint =>
      'Lipește conținutul unui fișier JSON de temă de culoare VS Code';

  @override
  String get editorThemeImported => 'Temă importată';

  @override
  String get editorThemeInvalid => 'Asta nu arată ca o temă VS Code validă';

  @override
  String get importTheme => 'Importă tema';

  @override
  String get clearTheme => 'Șterge tema';

  @override
  String get openInDiffViewer => 'Deschide în vizualizatorul de diff';

  @override
  String get shellCommand => 'Comandă';

  @override
  String get shellOutput => 'Ieșire';

  @override
  String get revertToHere => 'Revino aici';

  @override
  String get revertConfirmBody =>
      'Ascunzi mesajele de după acest punct și readuci modificările de fișiere ale agentului la acest tur? Poți anula asta.';

  @override
  String get revert => 'Revino';

  @override
  String get revertedToHere => 'Revenit aici';

  @override
  String get nothingToRevert => 'Nimic de revertat';

  @override
  String get undoRevert => 'Anulează revertul';

  @override
  String get revertUndone => 'Revert anulat';

  @override
  String get systemBehavior => 'Comportament sistem';

  @override
  String get keepAwakeTitle => 'Ține computerul treaz cât rulează agenții';

  @override
  String get keepAwakeOnSubtitle =>
      'Computerul nu va intra în somn cât un agent lucrează';

  @override
  String get keepAwakeOffSubtitle =>
      'Computerul poate intra în somn chiar dacă un agent lucrează';

  @override
  String get spaces => 'Spații';

  @override
  String get spacesHomeDescription =>
      'Alege un spațiu din listă sau pornește unul nou.';

  @override
  String get noSpacesYet => 'Niciun spațiu încă';

  @override
  String get newSpace => 'Spațiu nou';

  @override
  String get spaceName => 'Nume spațiu';

  @override
  String get spaceReposHint => 'Depozite de inclus';

  @override
  String get newSpaceFolder => 'Dosar nou';

  @override
  String get folderName => 'Numele dosarului';

  @override
  String get renameSpaceFolder => 'Redenumește dosarul';

  @override
  String get deleteSpaceFolder => 'Șterge dosarul';

  @override
  String get moveSpaceToFolder => 'Mută în dosar';

  @override
  String get removeSpaceFromFolder => 'Elimină din dosar';

  @override
  String get spaceFolderActions => 'Acțiuni pentru dosar';

  @override
  String get deleteFolderWithSpacesWarning =>
      'Ștergerea definitivă a spațiilor le elimină mesajele și directoarele de lucru pentru toată lumea. Această acțiune nu poate fi anulată.';

  @override
  String get deleteSpacesInFolder =>
      'Șterge definitiv spațiile din acest dosar';

  @override
  String get deleteFolderAndSpaces => 'Șterge dosarul și spațiile';

  @override
  String get keepSpacesInFolder =>
      'Altfel, spațiile vor rămâne în afara dosarelor.';

  @override
  String get noSpaceFoldersYet => 'Nu există încă dosare';

  @override
  String get ideSourceControl => 'Control sursă';

  @override
  String get stagedChanges => 'Modificări în staging';

  @override
  String get changes => 'Modificări';

  @override
  String get stageFile => 'Stage';

  @override
  String get unstageFile => 'Unstage';

  @override
  String get stageAll => 'Pune tot în staging';

  @override
  String get unstageAll => 'Scoate tot din staging';

  @override
  String get stageChangesToCommit =>
      'Pune modificările în staging pentru commit';

  @override
  String get syncToPrHead => 'Fă pull la ultimele commit-uri PR';

  @override
  String get syncedToPrHead => 'Sincronizat cu ultimele commit-uri PR';

  @override
  String get syncPrHeadDirty =>
      'Fă commit sau renunță la modificări înainte de sincronizare';

  @override
  String get syncPrHeadFailed => 'Nu s-a putut sincroniza cu head-ul PR';

  @override
  String get spaceLabel => 'Spațiu';

  @override
  String get keybindingNewSpace => 'Spațiu nou';

  @override
  String get jumpToLatest => 'Sari la cele mai recente';

  @override
  String get streaming => 'Streaming';

  @override
  String get newMessages => 'Noi';

  @override
  String get copyLink => 'Copiază linkul';

  @override
  String get linkCopied => 'Link copiat';

  @override
  String get agentResponding => 'Agentul răspunde';

  @override
  String get agentFinished => 'Agentul a terminat';

  @override
  String get harnessConnectProviderForModels =>
      'Conectează un provider ca să vezi modelele.';

  @override
  String get providerSignOut => 'Deconectează-te';

  @override
  String get providerWaitingForDeviceCode =>
      'Se așteaptă să confirmi codul în browser…';

  @override
  String get providerDeviceCodeHint =>
      'Verifică că acest cod coincide cu cel din browser, apoi aprobă.';

  @override
  String get providerPlanUsageLoading => 'Se verifică utilizarea planului…';

  @override
  String get providerPlanUsageUnavailable =>
      'Acest plan nu a raportat utilizarea.';

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return 'Elimini cheia API $provider?';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return 'Cheia stocată este ștearsă și nu mai poate fi afișată. Agenții care folosesc modele $provider se opresc până lipești una nouă.';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return 'Elimini $provider?';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return '$provider și cheia stocată sunt șterse. Agenții ancorați pe modelele lui se opresc.';
  }

  @override
  String get providerApiKeyHint => 'Lipește o cheie API';

  @override
  String get providerApiKeyStoredHint =>
      'Lipește altă cheie API ca să o adaugi';

  @override
  String get providerAddAnotherAccount => 'Adaugă alt cont';

  @override
  String get providerActiveBadge => 'Activ';

  @override
  String get providerSignInExpired => 'Autentificarea a expirat';

  @override
  String get providerOauthAccountFallback => 'Cont OAuth';

  @override
  String get providerApiKeyFallback => 'Cheie API';

  @override
  String get providerRemoveCredentialConfirmTitle =>
      'Elimini aceste date de autentificare?';

  @override
  String get providerSignOutAccountConfirmTitle =>
      'Te deconectezi din acest cont?';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return 'Agenții care folosesc $provider revin la celelalte chei și conturi. Fără niciuna, se opresc până adaugi una.';
  }

  @override
  String get providerBaseUrlHint => 'URL de bază (opțional)';

  @override
  String get addProvider => 'Adaugă provider';

  @override
  String get noCustomProviders => 'Niciun provider personalizat încă.';

  @override
  String get providerNameLabel => 'Nume';

  @override
  String get apiTypeLabel => 'Tip API';

  @override
  String get providerBaseUrlLabel => 'URL de bază';

  @override
  String get providerApiKeyOptionalHint => 'Cheie API (opțional)';

  @override
  String get dialectOpenAiCompatible => 'Compatibil OpenAI';

  @override
  String get dialectAnthropicCompatible => 'Compatibil Anthropic';

  @override
  String get removeProviderTooltip => 'Elimină providerul';

  @override
  String get providerLogInWithBrowser => 'Autentifică-te în browser';

  @override
  String providerLoginDialogTitle(String provider) {
    return 'Autentifică-te la $provider';
  }

  @override
  String get providerLabel => 'Provider';

  @override
  String get selectProviderToLogin =>
      'Selectează un provider pentru autentificare';

  @override
  String providerLoginFailed(String error) {
    return 'Autentificarea a eșuat: $error';
  }

  @override
  String get providerWaitingForBrowser =>
      'Se așteaptă să autorizezi în browser…';

  @override
  String get providerPasteCodeHint => 'Sau lipește codul din browser';

  @override
  String get providerCompleteLogin => 'Finalizează';

  @override
  String get providerConnectedApiKey => 'Conectat prin cheie API';

  @override
  String get providerConnectedOauth => 'Conectat';

  @override
  String providerConnectedAccount(String account) {
    return 'Conectat · $account';
  }

  @override
  String get providerLocalReady => 'Local · gata';

  @override
  String get providerNotConnected => 'Neconectat';

  @override
  String get preparingWorkspace => 'Se pregătește spațiul de lucru…';

  @override
  String provisioningRunningTasks(String repo) {
    return 'Se rulează sarcinile worktree pentru $repo…';
  }

  @override
  String provisioningCloningRepo(String repo) {
    return 'Se clonează $repo…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return 'Se face checkout la pull request în $repo…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return 'Se configurează agentul $agent…';
  }

  @override
  String get workspacePrepFailed => 'Pregătirea spațiului de lucru a eșuat';

  @override
  String get workspacePrepStopped =>
      'Pregătirea spațiului de lucru a fost oprită';

  @override
  String get stopWorkspacePrep => 'Oprește pregătirea';

  @override
  String get stopWorkspacePrepTooltip =>
      'Oprește pregătirea acestui spațiu de lucru';

  @override
  String get stopWorkspacePrepConfirm =>
      'Oprești pregătirea acestui spațiu de lucru? Clona în curs este aruncată — o poți porni din nou de aici.';

  @override
  String messageWillSendWhenReady(int count) {
    return '$count mesaj(e) se vor trimite când e gata';
  }

  @override
  String get membersNav => 'Membri';

  @override
  String get membersSettingsDescription =>
      'Persoane cu acces la acest spațiu de lucru: listă, invitații și audit';

  @override
  String get memberRosterLabel => 'Listă de membri';

  @override
  String get memberRepoAccessAction => 'Acces depozit';

  @override
  String memberRepoAccessTitle(String name) {
    return 'Acces depozit pentru $name';
  }

  @override
  String get roleOwner => 'Proprietar';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleMember => 'Membru';

  @override
  String get roleViewer => 'Vizualizator';

  @override
  String get roleGuest => 'Invitat';

  @override
  String get removeMemberTitle => 'Elimină membrul';

  @override
  String removeMemberConfirm(String name) {
    return 'Elimini pe $name din acest spațiu de lucru? Pierde accesul imediat.';
  }

  @override
  String get transferOwnershipAction => 'Transferă proprietatea';

  @override
  String get transferOwnershipTitle => 'Transferă proprietatea';

  @override
  String transferOwnershipConfirm(String name) {
    return 'Îl faci pe $name proprietar al acestui spațiu de lucru? Tu devii admin. Doar un proprietar poate șterge spațiul de lucru sau schimba rolul altui admin.';
  }

  @override
  String get transferOwnershipCta => 'Transferă';

  @override
  String get auditTrailLabel => 'Jurnal de audit al autorizărilor';

  @override
  String get auditTrailDescription =>
      'Fiecare permisiune și refuz, înlănțuit prin hash, astfel o înregistrare modificată sau ștearsă este detectabilă.';

  @override
  String get auditVerifyChain => 'Verifică lanțul';

  @override
  String auditChainIntact(int count) {
    return 'Lanț intact — $count înregistrări verificate';
  }

  @override
  String auditChainBroken(int seq, String reason) {
    return 'Lanț rupt la înregistrarea $seq: $reason';
  }

  @override
  String get auditEmpty => 'Nicio decizie înregistrată încă.';

  @override
  String get auditDenied => 'Refuzat';

  @override
  String get auditAllowed => 'Permis';

  @override
  String auditOnBehalfOf(String user) {
    return 'pentru $user';
  }

  @override
  String get policyTemplatesLabel => 'Șabloane de politică';

  @override
  String get policyTemplatesDescription =>
      'Aplică o postură de start sau mută una între spații de lucru.';

  @override
  String get policyTemplateStrict => 'Strict';

  @override
  String get policyTemplateBalanced => 'Echilibrat';

  @override
  String get policyTemplatePermissive => 'Permisiv';

  @override
  String get policyTemplateApply => 'Aplică';

  @override
  String policyTemplateApplied(int count) {
    return 'S-au aplicat $count reguli';
  }

  @override
  String get policyExport => 'Copiază politica';

  @override
  String get policyExported => 'Politica a fost copiată în clipboard';

  @override
  String get policyImport => 'Lipește politica';

  @override
  String policyImported(int count) {
    return 'S-au importat $count reguli';
  }

  @override
  String get approveAndRemember => 'Aprobă pentru 8 ore';

  @override
  String get approveAndRememberTooltip =>
      'Aprobă această acțiune și nu mai întreabă pentru altele similare în acest spațiu timp de 8 ore. Expiră de la sine.';

  @override
  String get unknownUserLabel => 'Utilizator necunoscut';

  @override
  String get inviteMember => 'Invită membru';

  @override
  String get inviteRepoAccessHeader => 'Acces la depozite';

  @override
  String get inviteRepoAccessExplainer =>
      'Doar depozitele pe care le bifezi sunt partajate cu invitatul, la nivelul ales. Restul rămâne ascuns.';

  @override
  String get grantLevelRead => 'Citire';

  @override
  String get grantLevelReview => 'Revizuire';

  @override
  String get grantLevelWrite => 'Scriere';

  @override
  String get inviteExpiryLabel => 'Expiră în';

  @override
  String get expiryOneDay => '1 zi';

  @override
  String get expirySevenDays => '7 zile';

  @override
  String get expiryThirtyDays => '30 de zile';

  @override
  String get createInviteAction => 'Creează invitație';

  @override
  String get inviteOneTimeCodeLabel => 'Cod de unică folosință';

  @override
  String get inviteCodeShownOnce =>
      'Acest cod este afișat o singură dată — copiază-l acum.';

  @override
  String get inviteLinkLabel => 'Link de invitație';

  @override
  String get inviteRedeemHint =>
      'Partajează codul cu invitatul; îl valorifică față de URL-ul serverului tău.';

  @override
  String get inviteScanQr => 'Sau scanează pentru valorificare';

  @override
  String get inviteLoopbackWarningTitle => 'Invitația indică o adresă locală';

  @override
  String get inviteLoopbackWarningBody =>
      'Colaboratorii de pe alte mașini nu vor putea atinge acest server. Pornește un tunel (Setări → Integrări → Partajează acest server) sau leagă-te la rețea ca utilizatorii din afara gazdei să se poată conecta.';

  @override
  String get inviteStatusOpen => 'Deschisă';

  @override
  String get inviteStatusUsed => 'Folosită';

  @override
  String get inviteStatusRevoked => 'Revocată';

  @override
  String get inviteStatusExpired => 'Expirată';

  @override
  String inviteCreatedTime(String time) {
    return 'Creată $time';
  }

  @override
  String inviteExpiresOn(String date) {
    return 'expiră $date';
  }

  @override
  String get noActivityYet => 'Nicio activitate încă';

  @override
  String get couldNotLoadMembers => 'Nu s-au putut încărca membrii';

  @override
  String get couldNotLoadInvites => 'Nu s-au putut încărca invitațiile';

  @override
  String get couldNotLoadActivity => 'Nu s-a putut încărca activitatea';

  @override
  String get yourDevices => 'Dispozitivele tale';

  @override
  String get yourDevicesDescription =>
      'Clienți asociați contului tău pe acest server.';

  @override
  String get noOwnDevices =>
      'Niciun dispozitiv nu este asociat contului tău încă';

  @override
  String get renameDeviceTitle => 'Redenumește dispozitivul';

  @override
  String get revokeDeviceTitle => 'Revocă dispozitivul';

  @override
  String revokeDeviceConfirm(String label) {
    return 'Revoci $label? Este deconectat imediat și nu mai poate atinge acest server.';
  }

  @override
  String devicePairedTime(String time) {
    return 'Asociat $time';
  }

  @override
  String deviceLastSeenTime(String time) {
    return 'Văzut ultima dată $time';
  }

  @override
  String get deviceNeverSeen => 'Niciodată conectat';

  @override
  String get deviceAwaitingApproval => 'Se așteaptă aprobarea';

  @override
  String get profileSectionLabel => 'Profil';

  @override
  String get profileSectionDescription =>
      'Cum apari echipei și în autoratul commit-urilor git în acest spațiu. Câmpurile goale moștenesc numele și e-mailul contului.';

  @override
  String get displayNameLabel => 'Nume afișat';

  @override
  String get emailLabel => 'Email';

  @override
  String get gitAuthorNameLabel => 'Nume autor Git';

  @override
  String get gitAuthorEmailLabel => 'Email autor Git';

  @override
  String get profileSaved => 'Profil salvat';

  @override
  String get presenceOnline => 'Online';

  @override
  String get presenceIdle => 'Inactiv';

  @override
  String get presenceTyping => 'Tastează…';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String get presenceRailLabel => 'Cine e online';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => 'Activează nu deranja';

  @override
  String get dndTooltipOff => 'Dezactivează nu deranja';

  @override
  String get startPresenting => 'Începe prezentarea';

  @override
  String get stopPresenting => 'Oprește prezentarea';

  @override
  String spotlightPresentingBanner(String name) {
    return '$name prezintă';
  }

  @override
  String get spotlightLeave => 'Pleacă';

  @override
  String typingIndicator(String name) {
    return '$name tastează…';
  }

  @override
  String get ideTabNotes => 'Note';

  @override
  String get ideSidebarAllViews => 'Toate vizualizările';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return 'Toate vizualizările ($count ascunse)';
  }

  @override
  String get ideSidebarPinView => 'Fixează în bara laterală';

  @override
  String get ideSidebarUnpinView => 'Defixează din bara laterală';

  @override
  String get notesEmptyHint =>
      'Adaugă o notă pentru oricine preia această conversație…';

  @override
  String get notesEditTooltip => 'Editează nota';

  @override
  String notesUpdatedBy(String name, String time) {
    return 'Actualizat de $name · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '$name editează';
  }

  @override
  String get notesSaveFailed => 'Nu s-a putut salva nota';

  @override
  String get reactionAddTooltip => 'Adaugă reacție';

  @override
  String reactionToggleTooltip(String emoji) {
    return 'Reacționează cu $emoji';
  }

  @override
  String get reactionThumbsUp => 'Degetul mare în sus';

  @override
  String get reactionThumbsDown => 'Degetul mare în jos';

  @override
  String get reactionLaugh => 'Râs';

  @override
  String get reactionHooray => 'Ura';

  @override
  String get reactionConfused => 'Confuz';

  @override
  String get reactionHeart => 'Inimă';

  @override
  String get reactionRocket => 'Rachetă';

  @override
  String get reactionEyes => 'Ochi';

  @override
  String get commentReact => 'Reacționează';

  @override
  String get commentResolveThread => 'Rezolvă firul';

  @override
  String get commentReopenThread => 'Redeschide firul';

  @override
  String get commentCopyLink => 'Copiază linkul comentariului';

  @override
  String get commentCopyMarkdown => 'Copiază ca Markdown';

  @override
  String get commentCopyThreadMarkdown => 'Copiază firul ca Markdown';

  @override
  String get commentCopyPrompt => 'Copiază ca prompt';

  @override
  String get commentCopyThreadPrompt => 'Copiază firul ca prompt';

  @override
  String get commentSendToAgent => 'Trimite agentului';

  @override
  String get commentDelete => 'Șterge comentariul';

  @override
  String get commentEdit => 'Editează comentariul';

  @override
  String get commentActions => 'Acțiuni pentru comentariu';

  @override
  String get commentDeleteTitle => 'Ștergi acest comentariu?';

  @override
  String get commentDeleteBody => 'Este eliminat din pull request.';

  @override
  String get commentSentToAgent => 'Trimis agentului';

  @override
  String get commentSendFailed =>
      'Nu s-a putut trimite acest comentariu unui agent';

  @override
  String get commentDeleteFailed => 'Nu s-a putut șterge acest comentariu';

  @override
  String get autonomyDialLabel => 'Autonomie';

  @override
  String get autonomyProposeOnly => 'Doar propune';

  @override
  String get autonomyActWithApproval => 'Acționează cu aprobare';

  @override
  String get autonomyActFreely => 'Acționează liber';

  @override
  String get autonomyDefaultOption => 'Implicit';

  @override
  String get checkerLabel => 'Verificator';

  @override
  String get checkerNone => 'Niciunul';

  @override
  String get checkerCaption =>
      'Verificatorul revizuiește rulările finalizate ale altor agenți.';

  @override
  String get takeoverTooltip => 'Preia worktree-ul';

  @override
  String get takeoverBannerSelf => 'Ai preluat worktree-ul acestei conversații';

  @override
  String takeoverBannerOther(String name) {
    return '$name a preluat worktree-ul acestei conversații';
  }

  @override
  String get handBackButton => 'Predă înapoi';

  @override
  String get handBackDialogTitle => 'Predă worktree-ul înapoi';

  @override
  String get handBackDialogNoteHint => 'Notă opțională pentru agent…';

  @override
  String takeoverFailed(String message) {
    return 'Nu s-a putut prelua: $message';
  }

  @override
  String handBackFailed(String message) {
    return 'Nu s-a putut preda: $message';
  }

  @override
  String get planStudioTitle => 'Plan Studio';

  @override
  String get plansTitle => 'Planuri';

  @override
  String get plansSubtitle =>
      'Planuri active, documente de plan și playbook-uri';

  @override
  String get plansActiveSection => 'Planuri active';

  @override
  String get plansDocumentsSection => 'Documente de plan';

  @override
  String get plansPlaybooksSection => 'Playbook-uri';

  @override
  String get plansNoActive => 'Niciun plan activ încă.';

  @override
  String get plansNoDocuments => 'Niciun document de plan încă.';

  @override
  String get plansNoPlaybooks => 'Niciun playbook încă.';

  @override
  String get planNotFound => 'Planul nu a fost găsit.';

  @override
  String get planOpenInStudio => 'Deschide';

  @override
  String get planNodeTitle => 'Titlu';

  @override
  String get planNodeDescription => 'Descriere';

  @override
  String get planNodeDescriptionHint => 'Ce ar trebui să facă acest pas…';

  @override
  String get planNodeApplyDescription => 'Aplică';

  @override
  String get planNodeRole => 'Rol';

  @override
  String get planNodeDependencies => 'Depinde de';

  @override
  String get planNodeDependenciesHint => 'Adaugă o dependență';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de dependențe',
      few: '# dependențe',
      one: '1 dependență',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies =>
      'Fără dependențe, deci rulează imediat ce pornește planul';

  @override
  String get planNodeOutputSchema => 'Schemă de ieșire (JSON)';

  @override
  String get planNodeEstimate => 'Estimare';

  @override
  String get planNodeProvenance => 'Proveniență';

  @override
  String get planNodeAlreadyExecuted =>
      'Deja executat — editarea bifurcă planul de aici.';

  @override
  String get planNewNodeTitle => 'Pas nou';

  @override
  String get planEstimateNoHistory => 'Niciun istoric încă';

  @override
  String get planEstimateBlastUnknown => 'Rază de impact: necunoscută';

  @override
  String get planEstimatePartial => 'parțial';

  @override
  String get planEstimateAction => 'Estimează';

  @override
  String planEstimateDuration(String range) {
    return 'Durată $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return 'Rază de impact: $files fișiere, $symbols simboluri';
  }

  @override
  String get planApprove => 'Aprobă planul';

  @override
  String get planApproveSelectedNodes => 'Aprobă selecția';

  @override
  String get planReject => 'Respinge';

  @override
  String get planCancel => 'Anulează rularea';

  @override
  String get planContinueNode => 'Continuă nodul';

  @override
  String get planTotalNotEstimated => 'Neestimat încă';

  @override
  String get planBudgetExceeded => 'peste buget';

  @override
  String planBudgetCeiling(String amount) {
    return 'buget ≤ \$$amount';
  }

  @override
  String get planVersionsTitle => 'Versiuni';

  @override
  String get planNoRevisions => 'Nicio revizie încă.';

  @override
  String get planDiffIdentical => 'Nicio modificare.';

  @override
  String get planDiffGoalChanged => 'Obiectivul s-a schimbat';

  @override
  String get planDiffBudgetChanged => 'Bugetul s-a schimbat';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'Modificări de la v$fromRev la v$toRev';
  }

  @override
  String planDiffAdded(String node) {
    return 'Adăugat $node';
  }

  @override
  String planDiffRemoved(String node) {
    return 'Eliminat $node';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return 'Modificat $node: $fields';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return 'Muchie adăugată: $edge';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return 'Muchie eliminată: $edge';
  }

  @override
  String planDiffRoleAdded(String role) {
    return 'Rol adăugat: $role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return 'Rol eliminat: $role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return 'Rol reasignat: $role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return 'Plan replanificat: ai aprobat v$approved, acum este v$current. Revizuiește diff-ul înainte să continue.';
  }

  @override
  String planLiveActualCost(String amount) {
    return 'Cost real: \$$amount';
  }

  @override
  String get planPlaybookRun => 'Rulează';

  @override
  String get planPlaybookDelete => 'Șterge playbook-ul';

  @override
  String get planPlaybookProposed => 'Plan propus — aprobă-l în Plan Studio.';

  @override
  String get planPlaybookAnchorTicket => 'Tichet ancoră';

  @override
  String get planPlaybookPickTicket => 'Alege un tichet…';

  @override
  String get planPlaybookProposeRun => 'Propune planul';

  @override
  String get planPlaybookRepoHint => 'Un ID de depozit';

  @override
  String get planPlaybookAgentHint => 'Un ID de agent';

  @override
  String planPlaybookRunTitle(String name) {
    return 'Rulează $name';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '$count parametri';
  }

  @override
  String get recentLabel => 'Recente';

  @override
  String get cheatSheetTitle => 'Scurtături de tastatură';

  @override
  String get cheatSheetGlobal => 'Global';

  @override
  String get cheatSheetThisScreen => 'Acest ecran';

  @override
  String get cheatSheetReservedInBrowser => 'Rezervat browserului';

  @override
  String get keybindingCheatSheet => 'Scurtături de tastatură';

  @override
  String get runPlaybookLabel => 'Rulează playbook';

  @override
  String get playbooksLabel => 'Playbook-uri';

  @override
  String get keybindingUndo => 'Anulează';

  @override
  String get keybindingRedo => 'Refă';

  @override
  String get undone => 'Anulat';

  @override
  String get redone => 'Refăcut';

  @override
  String get undoFailed => 'Nu s-a putut anula';

  @override
  String get undoLabelTicketEdit => 'editare tichet';

  @override
  String get undoLabelMessageEdit => 'editare mesaj';

  @override
  String get undoLabelTodoStatus => 'stare todo';

  @override
  String get inboxTitle => 'Inbox';

  @override
  String get inboxReview => 'Revizuire';

  @override
  String get inboxOpen => 'Deschide';

  @override
  String get inboxAllCaughtUp => 'Ești la zi';

  @override
  String get inboxGitHubDownTitle => 'GitHub ar putea fi indisponibil';

  @override
  String inboxGitHubDownBody(String status) {
    return 'GitHub raportează $status, deci pull request-urile pot lipsi din această listă, nu neapărat să fie gata.';
  }

  @override
  String get inboxGitHubIdentityTitle =>
      'Nu s-a putut confirma contul tău GitHub';

  @override
  String get inboxGitHubIdentityBody =>
      'Inbox-ul este sortat după cine ești pe GitHub. Până se încarcă rămâne gol, chiar dacă te așteaptă pull request-uri.';

  @override
  String get inboxSeverityBlocking => 'Blocat';

  @override
  String get inboxSeverityWaiting => 'În așteptare';

  @override
  String get inboxSeverityInfo => 'Info';

  @override
  String get inboxSyncFailed => 'Sincronizarea a eșuat';

  @override
  String get inboxNeedsYourAttention => 'Necesită atenția ta';

  @override
  String get inboxSectionNeedsYourReview => 'Necesită revizuirea ta';

  @override
  String get inboxSectionReturnedToYou => 'Returnate ție';

  @override
  String get inboxSectionApproved => 'Aprobate';

  @override
  String get inboxSectionDrafts => 'Ciorne';

  @override
  String get inboxSectionWaitingForReviewers => 'Așteaptă recenzenți';

  @override
  String get inboxSectionMergingAndMerged => 'În fuziune și fuzionate recent';

  @override
  String get inboxSectionWaitingForAuthor => 'Așteaptă autorul';

  @override
  String get inboxColumnTitle => 'Titlu';

  @override
  String get inboxColumnChanges => 'Modificări';

  @override
  String get inboxColumnUpdated => 'Actualizat';

  @override
  String get inboxReviewApproved => 'Aprobat';

  @override
  String get inboxReviewChangesRequested => 'Modificări cerute';

  @override
  String get inboxHeroSubtitle =>
      'Fiecare pull request în care ești implicat, sortat după ce urmează.';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de pull request-uri necesită revizuirea ta',
      few: '# pull request-uri necesită revizuirea ta',
      one: '1 pull request necesită revizuirea ta',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# returnate ție',
      few: '# returnate ție',
      one: '1 returnat ție',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted =>
      'Modificarea nu s-a salvat și a fost anulată';

  @override
  String get offlinePendingLabel => 'în așteptare';

  @override
  String get offlineSyncingLabel => 'se sincronizează';

  @override
  String get copyLinkLabel => 'Copiază linkul către această pagină';

  @override
  String get agentsSectionLabel => 'Agenți';

  @override
  String get fleetWorkersTitle => 'Workeri';

  @override
  String get fleetWorkersSubtitle => 'Mașini disponibile pentru a rula joburi';

  @override
  String get fleetJobsTitle => 'Joburi';

  @override
  String get fleetJobsSubtitle => 'Lucru distribuit în fleet';

  @override
  String get fleetNoWorkers =>
      'Niciun worker încă — o a doua mașină care rulează `cc_worker --server <url>` se alătură fleet-ului.';

  @override
  String get fleetNoJobs => 'Niciun job.';

  @override
  String get fleetError => 'Nu s-a putut încărca fleet-ul';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de nuclee',
      few: '# nuclee',
      one: '1 nucleu',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return 'Heartbeat $time';
  }

  @override
  String get fleetNoHeartbeat => 'Niciun heartbeat încă';

  @override
  String fleetLastErrorLabel(String error) {
    return 'Ultima eroare: $error';
  }

  @override
  String get fleetDrain => 'Drenează';

  @override
  String get fleetResume => 'Reia';

  @override
  String get fleetRevoke => 'Revocă';

  @override
  String get fleetRemove => 'Elimină';

  @override
  String get fleetRevokeTitle => 'Revoci workerul?';

  @override
  String fleetRevokeBody(String name) {
    return 'Revoci $name? Sesiunea lui se încheie și joburile active sunt reasignate.';
  }

  @override
  String get fleetRemoveTitle => 'Elimini workerul?';

  @override
  String fleetRemoveBody(String name) {
    return 'Elimini $name din fleet? Se șterge înregistrarea lui.';
  }

  @override
  String get fleetActionFailed => 'Acțiunea a eșuat';

  @override
  String get fleetJobUnassigned => 'Neasignat';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '$attempts/$max încercări';
  }

  @override
  String get fleetPlacementReasons => 'Decizii de plasare';

  @override
  String get fleetNoPlacements => 'Nicio decizie de plasare încă.';

  @override
  String get fleetStatusOnline => 'Online';

  @override
  String get fleetStatusDraining => 'Se drenează';

  @override
  String get fleetStatusOffline => 'Offline';

  @override
  String get fleetStatusIncompatible => 'Incompatibil';

  @override
  String get fleetStatusRevoked => 'Revocat';

  @override
  String get fleetJobStatusQueued => 'În coadă';

  @override
  String get fleetJobStatusRunning => 'În rulare';

  @override
  String get fleetJobStatusSucceeded => 'Reușit';

  @override
  String get fleetJobStatusFailed => 'Eșuat';

  @override
  String get fleetJobStatusCancelled => 'Anulat';

  @override
  String get evalsNoSuites => 'Nicio suită eval încă.';

  @override
  String get evalsError => 'Nu s-au putut încărca eval-urile';

  @override
  String get evalsStarterBadge => 'Starter';

  @override
  String evalsDefaultBatch(int count) {
    return 'Lot implicit de $count';
  }

  @override
  String get evalsRecentRuns => 'Rulări recente';

  @override
  String get evalsNoRuns => 'Nicio rulare încă.';

  @override
  String get evalsPassRate => 'Rată de promovare';

  @override
  String evalsBatchTimes(int count) {
    return '× $count';
  }

  @override
  String evalsTriggeredBy(String who) {
    return 'de $who';
  }

  @override
  String evalsRunFinished(String rate) {
    return 'Eval finalizat — $rate promovate';
  }

  @override
  String get evalsRunFailed => 'Nu s-a putut rula suita';

  @override
  String get evalsRun => 'Rulează';

  @override
  String get evalsStatusQueued => 'În coadă';

  @override
  String get evalsStatusRunning => 'În rulare';

  @override
  String get evalsStatusPassed => 'Promovat';

  @override
  String get evalsStatusFailed => 'Eșuat';

  @override
  String get bannerCalendarReconnect => 'Reconectează';

  @override
  String get bannerView => 'Vezi';

  @override
  String get soundscapeTitle => 'Soundscapes';

  @override
  String get soundscapePlay => 'Redă';

  @override
  String get soundscapePause => 'Pauză';

  @override
  String get soundscapeMoodLabel => 'Dispoziție';

  @override
  String get soundscapeMoodFocus => 'Focus';

  @override
  String get soundscapeMoodRelax => 'Relaxare';

  @override
  String get soundscapeMoodSleep => 'Somn';

  @override
  String get soundscapeMoodRise => 'Avânt';

  @override
  String get soundscapeVolumeLabel => 'Volum';

  @override
  String get soundscapeTuneLabel => 'Acordează';

  @override
  String get soundscapeTuneMellow => 'Mellow';

  @override
  String get soundscapeTuneBright => 'Bright';

  @override
  String get soundscapeTuneEnergetic => 'Energetic';

  @override
  String get soundscapeTuneSpacy => 'Spacy';

  @override
  String get soundscapeTuneResetHint => 'Apasă de două ori pentru resetare';

  @override
  String get soundscapeSceneLabel => 'Se redă acum';

  @override
  String get soundscapeSceneLoading => 'Se acordează ambianța…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees°C';
  }

  @override
  String get soundscapeLocationLabel => 'Locație';

  @override
  String get soundscapeLocationDetecting => 'Se detectează locația…';

  @override
  String get soundscapeLocationAutoNote =>
      'Locația provine de pe acest dispozitiv.';

  @override
  String get soundscapeRefreshWeather => 'Reîmprospătează vremea';

  @override
  String get soundscapeAutoStartLabel => 'Pornește cu modul focus';

  @override
  String get soundscapeAutoStartDescription =>
      'Redă automat un soundscape când pornești o sesiune de focus.';

  @override
  String get soundscapeReturnToApp => 'Revino în aplicație';

  @override
  String get soundscapePopOut => 'Desprinde playerul';

  @override
  String get discussion => 'Discuție';

  @override
  String get chat => 'Chat';

  @override
  String get saving => 'Se salvează…';

  @override
  String get saved => 'Salvat';

  @override
  String get saveFailed => 'Nu s-a putut salva';

  @override
  String get commitAndPush => 'Commit & push';

  @override
  String get commit => 'Commit';

  @override
  String get commitAmend => 'Commit (amend)';

  @override
  String get commitAndSync => 'Commit și sincronizare';

  @override
  String get scmSyncChanges => 'Sincronizează modificările';

  @override
  String get scmPublishBranch => 'Publică ramura';

  @override
  String get scmSyncFailed => 'Sincronizarea a eșuat';

  @override
  String get scmSyncDirty =>
      'Fă commit sau renunță la modificări înainte de sincronizare';

  @override
  String get scmSynced => 'Sincronizat';

  @override
  String get scmPushRefused => 'Push-ul a fost refuzat';

  @override
  String get scmPulledPushRefused => 'Preluat, dar push-ul a fost refuzat';

  @override
  String get scmPushRefusedHint =>
      'Remote-ul sau un hook a respins actualizarea';

  @override
  String get scmSelectBranch => 'Selectează o ramură pentru checkout';

  @override
  String get scmCreateBranch => 'Creează o ramură nouă…';

  @override
  String get scmCreateBranchFrom => 'Creează o ramură nouă din…';

  @override
  String get scmCheckoutDetached => 'Checkout detașat…';

  @override
  String get scmBranchName => 'Numele ramurii';

  @override
  String get scmCreateBranchTitle => 'Creează ramura';

  @override
  String scmFromRef(String ref) {
    return 'Din ⁨$ref⁩';
  }

  @override
  String get scmCheckoutFailed => 'Nu s-a putut schimba ramura';

  @override
  String get scmCheckoutDirty =>
      'Fă commit sau renunță la modificări înainte de a schimba ramura';

  @override
  String scmSwitchedToBranch(String branch) {
    return 'Schimbat la ⁨$branch⁩';
  }

  @override
  String scmDetachedAt(String ref) {
    return 'Detașat la ⁨$ref⁩';
  }

  @override
  String get scmDetachedHead => 'HEAD detașat';

  @override
  String get scmNoBranches => 'Nicio ramură potrivită';

  @override
  String get scmBranches => 'Ramuri';

  @override
  String get scmRemoteBranches => 'Ramuri la distanță';

  @override
  String get scmTags => 'Etichete';

  @override
  String get scmPickStartPoint => 'Selectează un punct de pornire';

  @override
  String get scmSwitchBranch => 'Schimbă ramura';

  @override
  String get scmPullConflictTitle => 'Preluarea ar crea un conflict';

  @override
  String scmPullConflictBody(int count, String branch) {
    return 'Preluarea a $count commituri pe ⁨$branch⁩ ar intra în conflict cu lucrul din această copie.';
  }

  @override
  String get scmAskAi => 'Întreabă AI';

  @override
  String scmResolveConflictPrompt(String branch, String repo, int count) {
    return 'Preia ⁨$branch⁩ în ⁨$repo⁩. Este cu $count commituri în urma upstream-ului, iar preluarea intră în conflict cu lucrul local. Rezolvă conflictele și termină preluarea.';
  }

  @override
  String commitMessageOnBranch(String shortcut, String branch) {
    return 'Mesaj ($shortcut pentru commit pe „$branch”)';
  }

  @override
  String get committed => 'Commit făcut';

  @override
  String get commitAmended => 'Commit amendat';

  @override
  String get commitFailed => 'Commit-ul a eșuat';

  @override
  String get moreCommitActions => 'Mai multe acțiuni de commit';

  @override
  String get sourceControl => 'Control sursă';

  @override
  String fixFindingTitle(String location) {
    return 'Repară: $location';
  }

  @override
  String get openInEditor => 'Deschide în editor';

  @override
  String get regexTesterTitle => 'Testează expresia regulată';

  @override
  String get regexTesterHint => 'Tastează un exemplu';

  @override
  String get regexMatch => 'Potrivire';

  @override
  String get regexNoMatch => 'Nicio potrivire';

  @override
  String get regexInvalidPattern => 'Model nevalid';

  @override
  String get symbolLookupNone =>
      'Nicio definiție în index sau în acest pull request';

  @override
  String get symbolLookupInDiff => 'Găsit în acest pull request';

  @override
  String get symbolLookupFromBase =>
      'Din checkout-ul de bază — worktree-ul acestui PR nu este încă indexat';

  @override
  String get symbolImplementations => 'Implementări';

  @override
  String symbolCallersCount(int count) {
    return '$count apelanți';
  }

  @override
  String get commitMessageHint => 'Mesaj de commit';

  @override
  String get pushedToPr => 'Push făcut către PR';

  @override
  String get pushFailed => 'Push-ul a eșuat';

  @override
  String get reviewFindings => 'Constatări';

  @override
  String get treeLabel => 'Arbore';

  @override
  String get toggleFileTree => 'Afișează sau ascunde arborele de fișiere';

  @override
  String get diffViewSettings => 'Setări vizualizare diff';

  @override
  String get splitViewLabel => 'Împărțit';

  @override
  String get unifiedViewLabel => 'Unificat';

  @override
  String get wrapLines => 'Încadrează liniile';

  @override
  String get shiftClickSelectRange =>
      'Shift-click pentru a selecta un interval';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de fișiere',
      few: '# fișiere',
      one: '1 fișier',
    );
    return '$_temp0';
  }

  @override
  String prComplexityLoc(String loc) {
    return '$loc LOC';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return 'PR mic — $files, ~$minutes min de revizuit';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return 'PR mediu — $files, rezervă ~$minutes min de revizuit';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return 'PR mare — $files, ia în considerare împărțirea înainte de revizuire';
  }

  @override
  String get searchInFiles => 'Caută în fișiere';

  @override
  String get showFileList => 'Afișează lista de fișiere';

  @override
  String get searchInFilesHintField => 'Caută în fișiere…';

  @override
  String get searchInFilesHint => 'Caută în fișierele pull request-ului';

  @override
  String get searchInWholeRepo => 'Caută în tot depozitul';

  @override
  String get searchInThisPullRequest => 'Caută în acest pull request';

  @override
  String get searchNoResults => 'Niciun rezultat găsit';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de rezultate',
      few: '# rezultate',
      one: '1 rezultat',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '# de fișiere',
      few: '# fișiere',
      one: '1 fișier',
    );
    return '$_temp0 în $_temp1';
  }

  @override
  String get discardChangesTitle => 'Renunți la modificări?';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de fișiere',
      few: '# fișiere',
      one: '1 fișier',
    );
    return 'Renunți la $_temp0 către HEAD? Acțiunea nu poate fi anulată.';
  }

  @override
  String get discardAll => 'Renunță la tot';

  @override
  String get discardFailed => 'Nu s-a putut renunța la modificări';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de fișiere',
      few: '# fișiere',
      one: '1 fișier',
    );
    return 'S-a renunțat la $_temp0';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '# de fișiere',
      few: '# fișiere',
      one: '1 fișier',
    );
    return 'S-a renunțat la $_temp0; $skipped sărite (untracked)';
  }

  @override
  String get prWorktreeUnavailable => 'Spațiul de lucru nu e gata';

  @override
  String get prWorktreeUnavailableHint =>
      'Pregătirea fișierelor pull request-ului a eșuat. Redeschide pull request-ul ca să încerci din nou.';

  @override
  String get timestampRelativeLabel => 'Relativ';

  @override
  String get timestampRawLabel => 'Timestamp';

  @override
  String get copyTimestamp => 'Copiază timestamp-ul';

  @override
  String get copiedTimestamp => 'Timestamp copiat';

  @override
  String get previewDeployment => 'Previzualizare deployment';

  @override
  String previewDeploymentTab(String site) {
    return 'Previzualizare: $site';
  }

  @override
  String get askForReview => 'Cere revizuire…';

  @override
  String get closePrsConfirmTitle => 'Închizi pull request-urile?';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Închizi # de pull request-uri?',
      few: 'Închizi # pull request-uri?',
      one: 'Închizi 1 pull request?',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'S-au închis # de pull request-uri',
      few: 'S-au închis # pull request-uri',
      one: 'S-a închis 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'S-au asignat # de pull request-uri',
      few: 'S-au asignat # pull request-uri',
      one: 'S-a asignat 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'S-a cerut revizuire pe # de pull request-uri',
      few: 'S-a cerut revizuire pe # pull request-uri',
      one: 'S-a cerut revizuire pe 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de acțiuni au eșuat',
      few: '# acțiuni au eșuat',
      one: '1 acțiune a eșuat',
    );
    return '$_temp0';
  }

  @override
  String get diagram => 'Diagramă';

  @override
  String get diagramViewSource => 'Vezi sursa';

  @override
  String get diagramHideSource => 'Ascunde sursa';

  @override
  String diagramPreviewUnavailable(String reason) {
    return 'Previzualizarea diagramei nu este disponibilă ($reason)';
  }

  @override
  String get planUnavailable => 'Planul nu este disponibil';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de pași',
      few: '# pași',
      one: '1 pas',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => 'Aprobă și rulează';

  @override
  String get planStatusDraft => 'Ciornă';

  @override
  String get planStatusProposed => 'Plan';

  @override
  String get planStatusApproved => 'Plan aprobat';

  @override
  String get planStatusRejected => 'Plan respins';

  @override
  String get planStatusSuperseded => 'Plan înlocuit';

  @override
  String planRevisionLabel(int revision) {
    return 'Revizia $revision';
  }

  @override
  String get adapterEnforcementTitle => 'Ce aplică acest adaptor';

  @override
  String get enforcementFiltersToolSurface =>
      'Control Center alege instrumentele';

  @override
  String get enforcementInterceptsToolCalls =>
      'Fiecare apel este filtrat înainte să ruleze';

  @override
  String get enforcementObservesCompletionContract =>
      'Rularea este ținută la livrabilul ei';

  @override
  String get enforcementNativeToolsInterceptable =>
      'Instrumentele proprii ale runnerului sunt vizibile';

  @override
  String get enforcementInProcessToolsSandboxed =>
      'Instrumentele in-process sunt în sandbox';

  @override
  String get enforcementYes => 'Da';

  @override
  String get enforcementNo => 'Nu';

  @override
  String get adapterEnforcementCaveats => 'Rezerve';

  @override
  String get enforcementSummaryModesEnforced => 'Moduri aplicate';

  @override
  String get enforcementSummaryModesNotEnforced => 'Moduri neaplicate';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de rezerve',
      few: '# rezerve',
      one: '1 rezervă',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      'Modurile doar-citire nu sunt structurale: Control Center nu poate elimina instrumentele proprii ale acestui runner.';

  @override
  String get caveatToolCallsNotIntercepted =>
      'Fără poartă înainte de execuție: doar apelurile de instrumente MCP trec prin Control Center.';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      'Instrumentele proprii de fișiere și shell ale runnerului nu ajung niciodată la Control Center; sandbox-ul OS este singurul prag sub ele.';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      'Instrumentele de fișiere in-process rulează în afara sandbox-ului, deci suprafața de instrumente este singura graniță de sistem de fișiere.';

  @override
  String get caveatCompletionContractUnobservable =>
      'Control Center nu poate îndemna sau eșua o rulare care se termină fără a produce livrabilul.';

  @override
  String get modeDegraded => 'Degradat';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return 'Modul $mode pe $adapter se bazează doar pe sandbox; instrumentele proprii de fișiere ale agentului nu sunt interceptate.';
  }

  @override
  String get artifactUnavailable => 'Artifact indisponibil';

  @override
  String artifactRevisionLabel(int count) {
    return '$count revizii';
  }

  @override
  String get artifactShowMore => 'Afișează mai multe';

  @override
  String get artifactShowLess => 'Afișează mai puține';

  @override
  String get artifactCopy => 'Copiază';

  @override
  String get artifactCopied => 'Artifact copiat';

  @override
  String get artifactsTabLabel => 'Artifacte';

  @override
  String get artifactsEmptyTitle => 'Niciun artifact încă';

  @override
  String get artifactsEmptyBody =>
      'Când un agent publică aici un tabel, un grafic sau o diagramă, apare în această listă.';

  @override
  String get artifactRevisionPickerLabel => 'Revizie';

  @override
  String get artifactRestoreRevision => 'Restaurează această revizie';

  @override
  String get artifactOpenInTab => 'Deschide în filă';

  @override
  String get artifactTitleFallback => 'Artifact';

  @override
  String get providerGenerationLabel => 'Implicite de generare';

  @override
  String get providerGenerationHint =>
      'Lasă un câmp gol ca să folosească implicitul endpointului. Modelele publică propriile plafoane de ieșire și rețete de eșantionare; servirea la alte valori le poate degrada.';

  @override
  String get providerMaxTokensLabel => 'Max. tokeni de ieșire';

  @override
  String get addModel => 'Adaugă model';

  @override
  String get modelListTitle => 'Listă de modele';

  @override
  String get railProvidersGroup => 'Provideri';

  @override
  String get railCustomProvidersGroup => 'Provideri personalizați';

  @override
  String get editModelSettings => 'Editează setările modelului';

  @override
  String get modelIdLabel => 'ID model';

  @override
  String get modelIdImmutableHint =>
      'ID-ul pe care îl servește endpointul; fix odată listat.';

  @override
  String get contextWindowLabel => 'Fereastră de context';

  @override
  String get inputTypesLabel => 'Tipuri de intrare';

  @override
  String get outputTypesLabel => 'Tipuri de ieșire';

  @override
  String get modalityText => 'Text';

  @override
  String get modalityImage => 'Imagine';

  @override
  String get modalityAudio => 'Audio';

  @override
  String get modalityVideo => 'Video';

  @override
  String get modalityPdf => 'PDF';

  @override
  String get modelOverrideReset => 'Resetează la automat';

  @override
  String get modelOverrideEdited => 'Editat';

  @override
  String get manualModelBadge => 'Adăugat manual';

  @override
  String get modelIdRequired => 'Introdu un ID de model.';

  @override
  String get modelTokensInvalid => 'Introdu un număr întreg pozitiv de tokeni.';

  @override
  String get removeModelAction => 'Elimină modelul';

  @override
  String removeModelConfirmTitle(String model) {
    return 'Elimini $model?';
  }

  @override
  String get removeModelConfirmBody =>
      'Modelul iese din listă și agenții ancorați pe el se opresc. Providerul nu este afectat.';

  @override
  String get addModelProviderTitle => 'Adaugă provider de modele';

  @override
  String get addModelProviderDescription =>
      'Configurează un endpoint API personalizat și modelele lui.';

  @override
  String get modelListEmptyHint =>
      'Niciun model configurat. Adaugă un model ca să-l folosești în chat.';

  @override
  String get addProviderModelsHint =>
      'Modelele sunt preluate live odată ce endpointul răspunde. Adaugă unul manual doar dacă nu-și poate lista propriile.';

  @override
  String get providerTemperatureLabel => 'Temperature';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved =>
      'Implicitele de generare au fost salvate';

  @override
  String get providerGenerationInvalid =>
      'Verifică valorile: max. tokeni de ieșire și top-k trebuie să fie pozitive, temperature 0–2, top-p 0–1.';

  @override
  String get providerGenerationOverridden => 'Suprascris';

  @override
  String get branchNotPushed => 'fără push';

  @override
  String branchNotOnRemote(String branch) {
    return '\"$branch\" există doar în această conversație';
  }

  @override
  String get branchNotOnRemoteHint =>
      'GitHub nu a văzut niciodată această ramură, deci un pull request nu o poate folosi încă. Publicarea face push la commit-urile deja din worktree — modificările necommise sunt lăsate în pace.';

  @override
  String get publishBranch => 'Publică ramura';

  @override
  String branchPublished(String branch) {
    return 'S-a publicat \"$branch\" pe origin';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return 'Ramură publicată. $count modificare(ări) necommise nu au fost incluse.';
  }

  @override
  String get composePrLoadingBranches => 'Se încarcă ramurile de pe GitHub…';

  @override
  String get composePrBranchesFailed =>
      'Nu s-au putut încărca ramurile de pe GitHub. Tastează un nume de ramură sau verifică conexiunea GitHub.';

  @override
  String get composePrSubtitleFromSpace =>
      'Din ramura acestei conversații — public-o întâi dacă GitHub nu a văzut-o';

  @override
  String get obsTabInsights => 'Insights';

  @override
  String get obsTabLive => 'Live';

  @override
  String get obsTabQuality => 'Calitate';

  @override
  String get obsTabUsage => 'Utilizare';

  @override
  String get obsUsageTotalTokens => 'Total tokeni';

  @override
  String get obsUsagePeakTokens => 'Vârf tokeni';

  @override
  String get obsUsageLongestSession => 'Cea mai lungă sesiune';

  @override
  String get obsUsageCurrentStreak => 'Serie curentă';

  @override
  String get obsUsageLongestStreak => 'Cea mai lungă serie';

  @override
  String obsUsageDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de zile',
      few: '# zile',
      one: '1 zi',
      zero: '0 zile',
    );
    return '$_temp0';
  }

  @override
  String get obsUsageTokenActivity => 'Activitate tokeni';

  @override
  String get obsUsageActivityModeLabel => 'Mod activitate tokeni';

  @override
  String get obsUsageModeDaily => 'Zilnic';

  @override
  String get obsUsageModeWeekly => 'Săptămânal';

  @override
  String get obsUsageModeCumulative => 'Cumulativ';

  @override
  String get obsUsageTimeRange => 'Interval de timp';

  @override
  String get obsUsageTrendTitle => 'Tendință zilnică de tokeni';

  @override
  String get obsUsageModelUsage => 'Utilizare modele';

  @override
  String get obsUsageTokensLabel => 'tokeni';

  @override
  String get obsUsageNoActivity =>
      'Nicio utilizare de tokeni înregistrată încă';

  @override
  String get obsUsageOtherModels => 'Altele';

  @override
  String obsUsageCellReadout(String date, String tokens) {
    return '$date · $tokens tokeni';
  }

  @override
  String obsUsageActivitySummary(
    String start,
    String end,
    int activeDays,
    String peak,
  ) {
    return 'Activitate tokeni de la $start la $end. $activeDays zile active. Cea mai aglomerată zi $peak tokeni.';
  }

  @override
  String get obsScreenSubtitle =>
      'Control live al agenților, atribuire de cost, cote și semnale de calitate';

  @override
  String get obsRangeLast24h => 'Ultimele 24 de ore';

  @override
  String get obsRangeLast7d => 'Ultimele 7 zile';

  @override
  String get obsRangeLast30d => 'Ultimele 30 de zile';

  @override
  String get obsRangeAll => 'Tot timpul';

  @override
  String get obsAddFilter => 'Adaugă filtru';

  @override
  String get obsFilterAgent => 'Agent';

  @override
  String get obsFilterModel => 'Model';

  @override
  String get obsFilterStatus => 'Stare';

  @override
  String get obsFilterRole => 'Rol';

  @override
  String get obsKpiTotalRuns => 'Total rulări';

  @override
  String get obsKpiTotalCost => 'Cost total';

  @override
  String get obsKpiErrorRate => 'Rată de eroare';

  @override
  String get obsKpiCacheRate => 'Rată cache';

  @override
  String get obsKpiTokensPerSec => 'Tokeni / sec';

  @override
  String get obsKpiAvgLatency => 'Latență medie';

  @override
  String get obsKpiTtft => 'Timp până la primul token';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '$delta față de perioada anterioară';
  }

  @override
  String get obsChartActivity => 'Activitate';

  @override
  String get obsChartCost => 'Cost în timp';

  @override
  String get obsLegendRuns => 'Rulări';

  @override
  String get obsLegendErrors => 'Erori';

  @override
  String get obsAgentsTitle => 'Agenți';

  @override
  String obsShowAllAgents(int count) {
    return 'Afișează toți cei $count agenți';
  }

  @override
  String get obsShowFewerAgents => 'Afișează mai puțini';

  @override
  String get obsRunsTitle => 'Rulări';

  @override
  String get obsNoRunsInRange => 'Nicio rulare în acest interval';

  @override
  String get obsColTime => 'Oră';

  @override
  String get obsColAgent => 'Agent';

  @override
  String get obsColStatus => 'Stare';

  @override
  String get obsColModel => 'Model';

  @override
  String get obsColDuration => 'Durată';

  @override
  String get obsColTokens => 'Tokeni';

  @override
  String get obsColCost => 'Cost';

  @override
  String get obsColErrors => 'Erori';

  @override
  String get obsColRuns => 'Rulări';

  @override
  String get obsColAvgLatency => 'Latență medie';

  @override
  String get obsColLastActive => 'Ultima activitate';

  @override
  String get obsStatusPending => 'În așteptare';

  @override
  String get obsStatusRunning => 'În rulare';

  @override
  String get obsStatusCompleted => 'Finalizat';

  @override
  String get obsStatusError => 'Eroare';

  @override
  String get obsRosterLoadError => 'Nu s-a putut încărca lista de agenți.';

  @override
  String get obsRosterEmpty => 'Niciun agent încă';

  @override
  String get obsRosterEmptyDescription =>
      'Trimite un agent și va apărea aici live — stare, instrument curent, tokeni, cost.';

  @override
  String get obsKillAgent => 'Oprește forțat agentul';

  @override
  String get obsRosterTokensLabel => 'tok';

  @override
  String get obsCostByRoleTitle => 'Cost pe rol';

  @override
  String get obsCostByRoleSubtitle =>
      'Unde cheltuie acest spațiu de lucru, pe rol de agent';

  @override
  String get obsRoleMain => 'Principal';

  @override
  String get obsRoleSubagents => 'Subagenți';

  @override
  String get obsRoleAdvisor => 'Consilier';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return 'Principal: $main · subagenți: $sub · consilier: $advisor';
  }

  @override
  String get obsTotal => 'Total';

  @override
  String get obsTokenModelTitle => 'Model de tokeni (5 axe)';

  @override
  String get obsTokenModelSubtitle =>
      'Fiecare token cheltuit de acest spațiu de lucru, pe axă';

  @override
  String get obsAxisInput => 'Intrare';

  @override
  String get obsAxisOutput => 'Ieșire';

  @override
  String get obsAxisReasoning => 'Raționament';

  @override
  String get obsAxisCacheRead => 'Citire cache';

  @override
  String get obsAxisCacheWrite => 'Scriere cache';

  @override
  String get obsTotalTokens => 'Total tokeni';

  @override
  String get obsCacheDiscountNote =>
      'Tokenii de citire din cache sunt facturați cu reducere, deci costă mult mai puțin decât același volum de input proaspăt.';

  @override
  String get obsByModelTitle => 'Pe model';

  @override
  String get obsByModelSubtitle => 'Utilizare de tokeni și cost pe model';

  @override
  String get obsNoModelUsage => 'Nicio utilizare de model înregistrată încă.';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de rulări',
      few: '# rulări',
      one: '1 rulare',
    );
    return '$_temp0';
  }

  @override
  String get obsPerRunTitle => 'Pe rulare';

  @override
  String get obsPerRunSubtitle =>
      'Costul tipic de tokeni al unei singure rulări';

  @override
  String get obsMedianRunTokens => 'Mediană tokeni pe rulare';

  @override
  String get obsMedianRunTokensSub => 'Punctul de mijloc pe toate rulările';

  @override
  String get obsRunsInWorkspace => 'În acest spațiu de lucru';

  @override
  String get obsCostShare => 'Pondere cost';

  @override
  String get obsQuotaConfiguredLimits => 'Limite configurate';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      'Utilizare față de plafoanele setate, cea mai gravă stare prima.';

  @override
  String get obsQuotaAddLimit => 'Adaugă limită';

  @override
  String get obsQuotaNoLimits =>
      'Nicio limită de cotă configurată încă — adaugă una ca să urmărești utilizarea față de un plafon.';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return 'Elimină limita $title';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return 'Se resetează în $duration · $status';
  }

  @override
  String get obsQuotaUsageWindows => 'Ferestre de utilizare';

  @override
  String get obsQuotaUsageWindowsSubtitle =>
      'Utilizare observată pe toți providerii, fără plafon aplicat.';

  @override
  String get obsQuotaNoUsage => 'Nicio utilizare înregistrată încă.';

  @override
  String get obsQuotaTokensUsed => 'Tokeni folosiți';

  @override
  String get obsQuotaRequests => 'Cereri';

  @override
  String get obsQuotaUnitTokens => 'tokeni';

  @override
  String get obsQuotaUnitRequests => 'cereri';

  @override
  String get obsQuotaUnitCost => 'cost';

  @override
  String get obsQuotaAddLimitTitle => 'Adaugă limită de cotă';

  @override
  String get obsQuotaProviderLabel => 'Provider';

  @override
  String get obsQuotaWindowLabel => 'Fereastră';

  @override
  String get obsQuotaUnitLabel => 'Unitate';

  @override
  String obsQuotaLimitLabel(String unit) {
    return 'Limită ($unit)';
  }

  @override
  String get obsQuotaCentsHint => 'În cenți US (500 = \$5.00).';

  @override
  String get obsQuotaStatusOk => 'Ok';

  @override
  String get obsQuotaStatusWarning => 'Avertisment';

  @override
  String get obsQuotaStatusExhausted => 'Epuizat';

  @override
  String get obsQuotaStatusUnknown => 'Necunoscut';

  @override
  String get obsGoalNoActiveTitle => 'Niciun obiectiv activ';

  @override
  String get obsGoalNoActiveBody =>
      'Setează un obiectiv ca să dai agenților un scop și un buget opțional de tokeni. Pe măsură ce rulările se finalizează, bugetul se umple, iar agenții sunt îndemnați să încheie când e aproape epuizat.';

  @override
  String get obsGoalSetGoal => 'Setează un obiectiv';

  @override
  String get obsGoalTokenBudget => 'Buget de tokeni';

  @override
  String obsGoalTokensLeft(String tokens) {
    return '$tokens rămași';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens (fără buget setat)';
  }

  @override
  String get obsGoalTokensUsed => 'Tokeni folosiți';

  @override
  String get obsGoalElapsed => 'Scurs';

  @override
  String get obsGoalWrapUp => 'Încheie';

  @override
  String get obsGoalClear => 'Golește obiectivul';

  @override
  String get obsGoalFallbackTitle => 'Obiectiv';

  @override
  String get obsGoalSubtitle => 'Buget Goal Mode';

  @override
  String get obsGoalStatusActive => 'Activ';

  @override
  String get obsGoalStatusPaused => 'Pauză';

  @override
  String get obsGoalStatusBudgetLimited => 'Limitat de buget';

  @override
  String get obsGoalStatusComplete => 'Complet';

  @override
  String get obsGoalStatusDropped => 'Abandonat';

  @override
  String get obsGoalObjectiveLabel => 'Obiectiv';

  @override
  String get obsGoalBudgetLabel => 'Buget de tokeni (opțional)';

  @override
  String get obsGoalSetAction => 'Setează obiectivul';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => 'Succes %';

  @override
  String get obsBenchmarkPassed => 'Promovat';

  @override
  String get obsBenchmarkFailed => 'Eșuat';

  @override
  String get obsBenchmarkErrors => 'Erori';

  @override
  String get obsBenchmarkSpend => 'Cheltuială';

  @override
  String get obsBenchmarkCostPerTask => 'Cost / sarcină';

  @override
  String get obsBenchmarkTrials => 'Încercări';

  @override
  String get obsBenchmarkNoTrials => 'Nicio rulare de scorat încă.';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Și încă #',
      few: 'Și încă #',
      one: 'Și încă 1',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => 'Promovat';

  @override
  String get obsBenchmarkTrialFail => 'Eșuat';

  @override
  String get obsBenchmarkTrialError => 'Eroare';

  @override
  String get obsBenchmarkTrialRunning => 'În rulare';

  @override
  String get obsBenchmarkReward => 'Recompensă';

  @override
  String get obsBenchmarkReport => 'Raport';

  @override
  String get obsBenchmarkCopyMarkdown => 'Copiază markdown';

  @override
  String get obsBenchmarkCopied => 'Raport copiat în clipboard';

  @override
  String get obsBehaviorCaption =>
      'Acestea sunt semnale de frustrare extrase din mesajele tale — o citire a sănătății conversației, nu un scor pentru agenți. Calculate local; nimic nu părăsește acest dispozitiv.';

  @override
  String get obsBehaviorMessagesAnalyzed => 'Mesaje analizate';

  @override
  String get obsBehaviorTotalSignals => 'Total semnale';

  @override
  String get obsBehaviorYelling => 'Țipat';

  @override
  String get obsBehaviorProfanity => 'Limbaj vulgar';

  @override
  String get obsBehaviorAnguish => 'Suferință';

  @override
  String get obsBehaviorNegation => 'Negație';

  @override
  String get obsBehaviorRepetition => 'Repetiție';

  @override
  String get obsBehaviorBlame => 'Vină';

  @override
  String get obsBehaviorConversationsTitle =>
      'Conversațiile cele mai frustrate';

  @override
  String get obsBehaviorConversationsSubtitle =>
      'Clasate după densitatea semnalelor din mesajele tale.';

  @override
  String get obsBehaviorNoSignals =>
      'Niciun semnal de frustrare detectat — totul merge bine.';

  @override
  String obsBehaviorMessagesCount(String count) {
    return '$count mesaje analizate';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '$count semnale';
  }

  @override
  String get obsAgentStatusIdle => 'Inactiv';

  @override
  String get obsAgentStatusParked => 'Parcat';

  @override
  String get obsAgentStatusAborted => 'Întrerupt';

  @override
  String get obsAgentKindSub => 'Sub';

  @override
  String get noChecksOnCommit => 'Nicio verificare nu a rulat pe acest commit.';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'În rulare — # de joburi',
      few: 'În rulare — # joburi',
      one: 'În rulare — 1 job',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Toate verificările au trecut — # de joburi',
      few: 'Toate verificările au trecut — # joburi',
      one: 'Toate verificările au trecut — 1 job',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Finalizat — # de joburi',
      few: 'Finalizat — # joburi',
      one: 'Finalizat — 1 job',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '# de joburi',
      few: '# joburi',
      one: '1 job',
    );
    return '$failed din $_temp0 au eșuat';
  }

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de joburi',
      few: '# joburi',
      one: '1 job',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return 'Matrix: $jobId';
  }

  @override
  String get jobLogsPending =>
      'Jurnalele vor apărea aici când jobul se termină.';

  @override
  String get jobLogsUnavailable =>
      'Jurnalele nu sunt disponibile pentru acest job.';

  @override
  String get noLogsForStep => 'Niciun jurnal captat pentru acest pas.';

  @override
  String get jobLogsTruncated =>
      'Jurnal trunchiat — se afișează cea mai recentă ieșire.';

  @override
  String get fullLog => 'Jurnal complet';

  @override
  String get copyLogs => 'Copiază jurnalele';

  @override
  String get resizeGraph => 'Trage pentru a redimensiona graful';

  @override
  String workflowRunStartedAgo(String time) {
    return 'Pornit $time';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return 'Finalizat $time';
  }

  @override
  String get chatBridgesTitle => 'Punți de chat';

  @override
  String chatProviderDescription(String provider, String command) {
    return 'Menționează botul în $provider ca să pui un agent pe ceva sau creează ciorne de tichete cu $command.';
  }

  @override
  String chatConnectProvider(String provider) {
    return 'Conectează $provider';
  }

  @override
  String get chatDisconnectProvider => 'Deconectează';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$botName în $teamName';
  }

  @override
  String get chatStateLive => 'Live';

  @override
  String get chatStateConnecting => 'Se conectează…';

  @override
  String get chatStateError => 'Eroare de conexiune';

  @override
  String get chatNotConnected => 'Neconectat';

  @override
  String chatStreamingUnavailable(String provider) {
    return 'Streamingul live este oprit pentru această aplicație $provider — răspunsurile sosesc ca un singur mesaj.';
  }

  @override
  String chatAdminOnly(String provider) {
    return 'Doar un admin poate conecta $provider pentru acest spațiu de lucru.';
  }

  @override
  String chatConnectHint(String provider) {
    return 'Creează o aplicație $provider, apoi lipește aici datele de autentificare. Control Center se conectează spre $provider, deci acest server nu are nevoie de o adresă publică.';
  }

  @override
  String chatOpenConsole(String provider) {
    return 'Deschide consola $provider';
  }

  @override
  String get chatOpenSetupGuide => 'Ghid de configurare';

  @override
  String get chatFieldBotToken => 'Token bot';

  @override
  String get chatFieldAppToken => 'Token la nivel de aplicație';

  @override
  String get chatFieldConfigRefreshToken => 'Token de configurare a aplicației';

  @override
  String chatFieldOptional(String label) {
    return '$label (opțional)';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return 'Leagă-mi contul $provider';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return 'Leagă-ți contul $provider ca mesajele pe care le trimiți acolo să-ți fie atribuite.';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return 'Legat de $externalUserId';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return 'Leagă-ți contul $provider';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return 'Trimite acest cod botului $provider într-un mesaj direct. Funcționează o dată și expiră în 15 minute.';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return 'Contul tău $provider este acum legat — mesajele pe care le trimiți acolo îți sunt atribuite.';
  }

  @override
  String get chatLinkedAccounts => 'Conturi legate';

  @override
  String chatNoLinkedAccounts(String provider) {
    return 'Nimeni nu și-a legat încă contul $provider.';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de conturi legate',
      few: '# conturi legate',
      one: '1 cont legat',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '$externalUserId · potrivit după email';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '$externalUserId · legat cu un cod';
  }

  @override
  String get chatUnlink => 'Dezleagă';

  @override
  String get chatCustomizeBot => 'Personalizează botul';

  @override
  String get chatCustomizeBotDescription =>
      'Redenumește botul, schimbă ce spune despre el sau redenumește comanda slash.';

  @override
  String get chatCustomizeBotUnavailable =>
      'Control Center are nevoie de un token de configurare a aplicației ca să editeze botul. Reconectează și include unul.';

  @override
  String chatCreateAppTitle(String provider) {
    return 'Creează aplicația $provider';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'Control Center poate crea aplicația $provider pentru tine, cu permisiunile și evenimentele potrivite deja setate. Termini în $provider, apoi lipești aici datele de autentificare.';
  }

  @override
  String get chatCreateApp => 'Creează aplicația';

  @override
  String get chatCreateAppCta => 'Creează aplicația pentru mine';

  @override
  String get chatAppNameLabel => 'Nume aplicație';

  @override
  String get chatBotDisplayNameLabel => 'Nume bot (ce tastează membrii după @)';

  @override
  String get chatDescriptionLabel => 'Descriere scurtă';

  @override
  String get chatAgentDescriptionLabel => 'Ce spune botul că poate face';

  @override
  String get chatCommandLabel => 'Comandă slash';

  @override
  String get chatDirectMessages => 'Mesaje directe';

  @override
  String chatDirectMessagesHint(String provider) {
    return 'Permite membrilor să discute cu botul într-un DM. Poate necesita un plan $provider plătit.';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return '$provider a creat aplicația $appId.';
  }

  @override
  String chatRemainingSteps(String provider) {
    return 'Au rămas câțiva pași pe care doar $provider îi poate face:';
  }

  @override
  String get chatStepAppToken => 'Generează un token la nivel de aplicație';

  @override
  String get chatStepInstall => 'Instalează aplicația';

  @override
  String get chatOpenAppSettings => 'Deschide setările aplicației';

  @override
  String get chatContinueToCredentials => 'Lipește datele de autentificare';

  @override
  String chatBotUpdated(String provider) {
    return 'Bot actualizat în $provider.';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return '$provider a schimbat permisiunile aplicației. Reinstalează aplicația ca să aibă efect.';
  }

  @override
  String get chatReinstallApp => 'Reinstalează aplicația';

  @override
  String chatIconNotEditable(String provider) {
    return 'Iconița botului poate fi schimbată doar în setările proprii ale aplicației $provider.';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return 'O poți crea și tu în $provider — fără token. Setările de mai sus călătoresc cu linkul.';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return 'Creează în $provider';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return '$provider s-a deschis în browser cu această configurație precompletată. Creează aplicația acolo, apoi finalizează acești pași și revino cu tokenii.';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return '$provider nu raportează ce aplicație a creat, deci personalizarea botului de aici va necesita mai târziu un token de configurare a aplicației.';
  }

  @override
  String get chatStepCreateApp =>
      'Creează aplicația din configurația precompletată';

  @override
  String chatStepCreateAppHint(String provider) {
    return 'Alege un spațiu de lucru în $provider și confirmă.';
  }

  @override
  String get chatStepAppTokenHint =>
      'Basic information → app-level tokens, cu scope-ul connections:write.';

  @override
  String get chatStepInstallHint =>
      'Install app → copiază tokenul OAuth al utilizatorului bot.';

  @override
  String get aboutTitle => 'Despre';

  @override
  String get aboutAppVersion => 'Versiune aplicație';

  @override
  String get aboutServerVersion => 'Server conectat';

  @override
  String get aboutRpcCatalog => 'Catalog RPC';

  @override
  String get aboutServerUnknown => 'Neraportat';

  @override
  String get serverStaleTitle =>
      'Serverul inclus este mai vechi decât această aplicație';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return 'cc_server-ul în rulare este $serverVersion, iar această aplicație este $appVersion. Repornește aplicația ca să preia cel mai recent build de server inclus; în dezvoltare, reconstruiește-l cu `dart build cli` în apps/cc_server.';
  }

  @override
  String get updateCheckButton => 'Verifică actualizări';

  @override
  String get updateChecking => 'Se verifică actualizările…';

  @override
  String get updateUpToDate => 'Ești la zi';

  @override
  String get updateDeferredBusy =>
      'O actualizare e gata, dar o întâlnire se înregistrează — va cere după ce se termină.';

  @override
  String get updateOpenedReleasesPage =>
      'S-a deschis pagina de lansări în browser.';

  @override
  String get updateCheckFailed => 'Verificarea actualizărilor a eșuat';

  @override
  String updateAvailableVersion(String version) {
    return 'Versiunea $version este disponibilă.';
  }

  @override
  String get updateBannerTitle => 'Un Control Center nou este disponibil';

  @override
  String get updateBannerRefresh => 'Reîmprospătează';

  @override
  String get updateBlockedRecording =>
      'Reîmprospătarea e în pauză cât se înregistrează o întâlnire — se va reîncărca când se termină.';

  @override
  String get settingsScopeYou => 'Tu';

  @override
  String get settingsScopeWorkspace => 'Spațiu de lucru';

  @override
  String get settingsScopeServer => 'Server';

  @override
  String get settingsProfile => 'Profil și identitate';

  @override
  String get settingsYourDevices => 'Dispozitivele tale';

  @override
  String get settingsWorkspaceGeneral => 'General';

  @override
  String get settingsServerConnection => 'Conexiune și stare';

  @override
  String get settingsModelProviders => 'Provideri de modele';

  @override
  String get settingsVoiceModels => 'Modele vocale și de întâlniri';

  @override
  String get settingsDiagnostics => 'Diagnosticări și confidențialitate';

  @override
  String get settingsAbout => 'Despre';

  @override
  String get settingsProfileDescription =>
      'Numele, e-mailul și identitatea ta git în acest spațiu de lucru. Schimbarea spațiului de lucru schimbă această suprapunere; numele de utilizator, autentificarea și dispozitivele rămân în contul tău, la Tu → Profil.';

  @override
  String get settingsServerConnectionDescription =>
      'La ce server vorbește acest client și cum este partajat acest server (mDNS, tuneluri, releu).';

  @override
  String get settingsAboutDescription =>
      'Identitatea build-ului și actualizări.';

  @override
  String get settingsDiagnosticsDescription =>
      'Izolare, indexare, sincronizare, jurnalizare și rapoarte de crash pentru această instalare.';

  @override
  String get settingsWorkspaceGeneralDescription =>
      'Politici și convenții comune tuturor celor din acest spațiu de lucru.';

  @override
  String get settingsWorkspaceMeetingsDescription =>
      'Șabloane de note și voci salvate pentru întâlnirile din acest spațiu de lucru.';

  @override
  String get settingsWorkspacePolicyLabel => 'Politică spațiu de lucru';

  @override
  String get settingsWorkspacePolicyDescription =>
      'Se aplică fiecărui membru și fiecărui agent din acest spațiu de lucru.';

  @override
  String get settingsSecretGlobsLabel => 'Excluderi de căi secrete';

  @override
  String get settingsSecretGlobsHelp =>
      'Un glob pe linie. Aceste căi sunt ascunse vizualizatorilor și invitaților pe suprafețele cu cod, pe lângă implicitele încorporate.';

  @override
  String get settingsReviewConcurrencyLabel => 'Fan-out revizuire';

  @override
  String get settingsReviewConcurrencyHelp =>
      'Câți recenzenți sunt trimiși în paralel când nu e dat un număr explicit.';

  @override
  String get settingsReviewLevelLabel => 'Nivel de revizuire';

  @override
  String get settingsReviewLevelHelp =>
      'Cât de profundă e revizuirea AI și cât din ce găsește e raportat din start. Nimic nu e aruncat — un nivel mai ușor grupează constatările minore în loc să le elimine.';

  @override
  String get reviewLevelLight => 'Ușor';

  @override
  String get reviewLevelBalanced => 'Echilibrat';

  @override
  String get reviewLevelThorough => 'Temeinic';

  @override
  String get reviewLevelLightHint =>
      'Un recenzent. Doar ce contează material e raportat din start.';

  @override
  String get reviewLevelBalancedHint =>
      'Trei recenzenți care acoperă QA, arhitectură și implementare.';

  @override
  String get reviewLevelThoroughHint =>
      'Adaugă specialiști de securitate și performanță și raportează tot ce s-a găsit.';

  @override
  String get askAiReviewAtLevel => 'Revizuiește la un alt nivel';

  @override
  String reviewNitpicksGroup(int count) {
    return 'Nitpicks ($count)';
  }

  @override
  String get reviewFindingResolve => 'Rezolvat';

  @override
  String get reviewFindingResolveHint =>
      'Marchează această constatare ca rezolvată. Nu se mai numără în revizuire.';

  @override
  String get reviewFindingDismiss => 'Respinge';

  @override
  String get reviewFindingDismissHint =>
      'Nu e o problemă reală. Recenzenții nu vor mai semnala acest pattern pe PR-urile viitoare.';

  @override
  String get reviewFindingReopen => 'Redeschide';

  @override
  String get reviewFindingStatusUndoLabel => 'Stare constatare';

  @override
  String get reviewFindingDismissTitle => 'Respinge această constatare';

  @override
  String get reviewFindingDismissReasonHint =>
      'De ce nu se aplică? Recenzenții o vor citi.';

  @override
  String reviewFindingStatusFailed(String error) {
    return 'Nu s-a putut actualiza constatarea: $error';
  }

  @override
  String get reviewStaleTitle => 'Această revizuire este învechită';

  @override
  String get reviewStaleBody =>
      'Pull request-ul a avansat de când a rulat această revizuire. Constatările pot indica cod care nu mai există.';

  @override
  String reviewStaleReviewedAt(String sha) {
    return 'Revizuit la $sha';
  }

  @override
  String get reviewStaleRerun => 'Revizuiește din nou';

  @override
  String reviewStaleNotificationTitle(int prNumber) {
    return 'Revizuire învechită pe #$prNumber';
  }

  @override
  String reviewStaleNotificationBody(String title) {
    return '$title are commit-uri noi de la ultima revizuire.';
  }

  @override
  String get reviewCategorySecurity => 'Securitate';

  @override
  String get reviewCategoryStability => 'Stabilitate';

  @override
  String get reviewCategoryDataIntegrity => 'Integritate date';

  @override
  String get reviewCategoryCorrectness => 'Corectitudine';

  @override
  String get reviewCategoryPerformance => 'Performanță';

  @override
  String get reviewCategoryMaintainability => 'Mentenanță';

  @override
  String get reviewEffortQuickWin => 'Câștig rapid';

  @override
  String get reviewEffortModerate => 'Moderat';

  @override
  String get reviewEffortHeavyLift => 'Efort mare';

  @override
  String get reviewProposedFix => 'Remediere propusă';

  @override
  String get reviewAiAgentPrompt => 'Prompt pentru agenți AI';

  @override
  String get reviewCopyAiPrompt => 'Copiază promptul';

  @override
  String get settingsWorkspaceAdminOnly =>
      'Doar administratorii spațiului de lucru pot schimba acestea.';

  @override
  String get chatMyAccountsTitle => 'Conturi de chat legate';

  @override
  String get settingsServerSso => 'Autentificare unică';

  @override
  String get settingsServerSsoDescription =>
      'Autentificare SAML și OpenID Connect cu provisionare de utilizatori';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabledDescription =>
      'Utilizatorii se pot autentifica cu acest provider';

  @override
  String get ssoEnabledDescriptionOn =>
      'Autentificarea este activă pentru acest provider';

  @override
  String get ssoIdpMetadataLabel => 'Metadate XML IdP';

  @override
  String get ssoIdpMetadataHint =>
      'lipește XML-ul EntityDescriptor al IdP-ului';

  @override
  String get ssoEmailAttributeLabel => 'Atribut email';

  @override
  String get ssoDisplayNameAttributeLabel => 'Atribut nume afișat';

  @override
  String get ssoGroupsAttributeLabel => 'Atribut grupuri';

  @override
  String get ssoIssuerLabel => 'URL issuer';

  @override
  String get ssoClientIdLabel => 'Client ID';

  @override
  String get ssoGroupsClaimLabel => 'Claim grupuri';

  @override
  String get ssoAutoMemberLabel =>
      'Adaugă utilizatorii în fiecare spațiu de lucru la prima autentificare';

  @override
  String get ssoAutoMemberDescription =>
      'Oprește ca să ceri o invitație per spațiu de lucru';

  @override
  String get ssoAllowJitLabel =>
      'Provisionare utilizatori necunoscuți la prima autentificare';

  @override
  String get ssoAllowJitDescription =>
      'Oprește ca să respingi utilizatorii fără un cont existent';

  @override
  String get ssoAllowIdpInitiatedLabel =>
      'Acceptă autentificare nesolicitată (inițiată de IdP)';

  @override
  String get ssoAllowIdpInitiatedDescription =>
      'Strict pentru portalurile IdP care lansează aplicații direct';

  @override
  String get ssoWantResponseSignedLabel => 'Cere un plic de răspuns semnat';

  @override
  String get ssoWantResponseSignedDescription =>
      'Semnăturile aserțiunilor sunt întotdeauna obligatorii';

  @override
  String get ssoTestConnectionButton => 'Testează conexiunea';

  @override
  String get ssoTestConnectionOk => 'Conexiunea funcționează:';

  @override
  String get ssoCopySpMetadata => 'Copiază metadatele SP';

  @override
  String get ssoCopySpMetadataDone =>
      'Metadatele SP au fost copiate în clipboard';

  @override
  String get ssoSavedToast => 'Setările de autentificare unică au fost salvate';

  @override
  String get ssoUnavailable =>
      'Acest server nu expune setări de autentificare unică. Actualizează binarul serverului și încearcă din nou.';

  @override
  String get ssoScimCardTitle => 'Provisionare utilizatori (SCIM)';

  @override
  String get ssoScimDescription =>
      'Îndreaptă conectorul SCIM al providerului de identitate către endpointul de mai jos cu un bearer token. Deprovisionarea revocă sesiunile și accesul la spațiul de lucru în câteva secunde. Serverul trebuie să fie accesibil de către IdP (tunel sau URL public).';

  @override
  String get ssoScimEndpoint => 'Endpoint SCIM';

  @override
  String get ssoScimEndpointUnknownOrigin =>
      'Setează mai întâi URL-ul public al serverului sau activează un tunel';

  @override
  String get ssoScimRegenerate => 'Regenerează tokenul';

  @override
  String get ssoScimRegenerateConfirm =>
      'Generezi un nou bearer token SCIM? Tokenul anterior încetează imediat să funcționeze.';

  @override
  String get ssoScimTokenTitle => 'Bearer token';

  @override
  String get ssoScimTokenPresent => 'Un token este configurat';

  @override
  String get ssoScimTokenAbsent =>
      'Niciun token încă — generează unul ca să activezi SCIM';

  @override
  String get ssoScimTokenOnce => 'Token SCIM (afișat o dată)';

  @override
  String ssoSignInWith(String provider) {
    return 'Autentifică-te cu $provider';
  }

  @override
  String get ssoProbeFailed =>
      'Nu s-a putut atinge acel server pentru autentificare unică';

  @override
  String get ssoOpensBrowser =>
      'Deschide browserul ca să termini autentificarea';

  @override
  String get ssoWaitingForBrowser =>
      'Se așteaptă ca browserul să termine autentificarea…';

  @override
  String get ssoBrowserOpenFailed =>
      'Nu s-a putut deschide browserul pentru autentificare unică';

  @override
  String get ssoUseManualPairing =>
      'Autentifică-te cu o invitație sau o cheie de asociere în schimb';

  @override
  String get ssoHideManualPairing => 'Ascunde asocierea manuală';

  @override
  String get ssoClientIdHint => 'Client public (PKCE) — nu e nevoie de secret';

  @override
  String get ssoClientSecretLabel => 'Client secret (opțional)';

  @override
  String get ssoClientSecretHintUnset =>
      'Necesar doar pentru clienții IdP confidențiali';

  @override
  String get ssoClientSecretHintSet =>
      'Un secret este stocat — lasă gol ca să-l păstrezi';

  @override
  String get ssoPairingToggle =>
      'Permite asocierea manuală (coduri de invitație și chei de asociere)';

  @override
  String get ssoPairingToggleDescription =>
      'Oprește ca alăturarea să fie doar prin autentificare unică — dispozitivele noi sosesc prin login-uri SSO; cele existente continuă să funcționeze';

  @override
  String get ssoPairConfirmTitle => 'Te conectezi la server?';

  @override
  String ssoPairConfirmBody(String server) {
    return 'A sosit o dată de autentificare pentru $server, dar nicio autentificare nu a fost pornită din această aplicație. Te conectezi la acest server?';
  }

  @override
  String get ssoPairConfirmConnect => 'Conectează';

  @override
  String get ssoPairConfirmCancel => 'Ignoră';

  @override
  String get forgeConnections => 'Găzduire de cod';

  @override
  String get connect => 'Conectează';

  @override
  String get disconnect => 'Deconectează';

  @override
  String get notConnected => 'Neconectat';

  @override
  String get checkingConnection => 'Se verifică conexiunea…';

  @override
  String forgeTokenTitle(String forge) {
    return 'Token $forge';
  }

  @override
  String get settingsAudio => 'Audio';

  @override
  String get settingsAudioDescription =>
      'Microfon, dictare, detectare întâlniri și ieșire soundscape.';

  @override
  String get audioDevicesSection => 'Dispozitive audio';

  @override
  String get voiceInputBehaviorSection => 'Dictare și întâlniri';

  @override
  String get audioOutputDeviceTitle => 'Dispozitiv de ieșire';

  @override
  String get audioOutputDefaultHint =>
      'Tot sunetul aplicației trece prin ieșirea implicită a sistemului.';

  @override
  String get audioOutputGone =>
      'Dispozitivul de ieșire selectat nu mai este conectat — se folosește implicitul sistemului până alegi altul.';

  @override
  String get reviewHubIntroBody =>
      'Agenții analizează diff-ul, mapează zonele de modificare și ajung la un verdict de consens.';

  @override
  String get reviewHubAlreadyRunning =>
      'O revizuire rulează deja pentru acest pull request';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return 'De la ultima revizuire: $resolved rezolvate · $added noi · $open încă deschise';
  }

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return 'Revizuit anterior la $sha';
  }

  @override
  String reviewArtifactFixAll(int count) {
    return 'Repară $count constatări';
  }

  @override
  String reviewArtifactFixSelected(int count) {
    return 'Repară $count selectate';
  }

  @override
  String reviewArtifactCommentSelected(int count) {
    return 'Comentează $count selectate';
  }

  @override
  String get webConnectStayConnected => 'Rămâi conectat pe acest dispozitiv';

  @override
  String get webConnectStayConnectedDetail =>
      'Rămâi conectat pe acest dispozitiv (stochează cheia în acest browser)';

  @override
  String failedToCreateWorkspace(String error) {
    return 'Nu s-a putut crea spațiul de lucru: $error';
  }

  @override
  String committedRelative(String relative) {
    return 'commit $relative';
  }

  @override
  String get selectAgents => 'Selectează agenți';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de agenți',
      few: '# agenți',
      one: '1 agent',
    );
    return '$_temp0';
  }

  @override
  String get newConversation => 'Conversație nouă';

  @override
  String get untitledConversation => 'Conversație fără titlu';

  @override
  String get conversationTitleOptionalHint =>
      'Opțional — lasă gol și modelul de titluri o numește automat';

  @override
  String get contentSynthesizerUnavailable =>
      'Agentul Content synthesizer lipsește sau nu are un runner funcțional';

  @override
  String get conversationNeedsAgent =>
      'Menționează un agent cu @ ca să începi această conversație';

  @override
  String get conversationTitleGenerate => 'Generează';

  @override
  String get conversationTitleNoMessages =>
      'Trimite mai întâi un mesaj. Titlul este generat din el.';

  @override
  String get conversationTitleGenerateFailed =>
      'Nu s-a putut genera un titlu. Încearcă din nou.';

  @override
  String get startThread => 'Pornește fir';

  @override
  String get deleteSpaceConfirm =>
      'Ștergi acest spațiu? Toate mesajele se vor pierde.';

  @override
  String threadTabTitle(String title) {
    return 'Fir: $title';
  }

  @override
  String threadReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de răspunsuri',
      few: '# răspunsuri',
      one: '1 răspuns',
    );
    return '$_temp0';
  }

  @override
  String threadLastReply(String time) {
    return 'Ultimul răspuns $time';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Autentifică-te cu $provider';
  }

  @override
  String get signInAgain => 'Autentifică-te din nou';

  @override
  String get forgeSignInBannerTitle =>
      'Găzduirea de cod nu este conectată în acest spațiu de lucru';

  @override
  String get forgeSignInBannerBody =>
      'O autentificare a expirat sau a fost revocată, ori acest spațiu de lucru folosește propriul GitHub App. Pull request-urile, revizuirile și sincronizarea depozitelor sunt în pauză până când te autentifici.';

  @override
  String get forgeSignInBannerAction => 'Autentifică-te';

  @override
  String get ticketing => 'Ticketing';

  @override
  String get ticketingProviderHelp =>
      'Unde trăiesc tichetele tale. Local le păstrează în Control Center.';

  @override
  String providerComingSoon(String provider) {
    return '$provider (în curând)';
  }

  @override
  String get ticketProviderLocal => 'Local';

  @override
  String get providerApps => 'Aplicații provider';

  @override
  String get providerAppsDescription =>
      'Aplicații pe care acest server le-a înregistrat singur la fiecare furnizor. Oamenii se autentifică prin ele, iar munca de fundal, precum webhook-urile, interogarea și sincronizarea, rulează pe ele, niciodată pe autentificarea unei persoane.';

  @override
  String get providerAppId => 'App id';

  @override
  String get providerPrivateKey => 'Cheie privată';

  @override
  String get providerClientId => 'Client id';

  @override
  String get providerClientSecret => 'Client secret';

  @override
  String get providerCallbackUrl => 'URL de callback';

  @override
  String get providerAppFullyConfigured =>
      'Serverul poate acționa ca el însuși, iar oamenii se pot autentifica.';

  @override
  String get providerAppServerOnly =>
      'Serverul poate acționa ca el însuși. Adaugă un client id și un secret ca oamenii să se poată autentifica.';

  @override
  String get providerAppSignInOnly =>
      'Oamenii se pot autentifica. Munca de fundal revine la datele lor de autentificare.';

  @override
  String providerAppInstalledOn(String accounts) {
    return 'Datele de autentificare funcționează. Instalat pe: $accounts';
  }

  @override
  String get couldNotOpenBrowser =>
      'Niciun browser nu a putut fi deschis. Copiază linkul și termină autentificarea tu.';

  @override
  String get contextUsage => 'Utilizare context';

  @override
  String get contextUsageFull => 'plin';

  @override
  String get contextUsageTokens => 'tokeni';

  @override
  String get contextSeeMore => 'Vezi mai mult';

  @override
  String get contextSegmentSystemPrompt => 'Prompt de sistem';

  @override
  String get contextSegmentRules => 'Reguli';

  @override
  String get contextSegmentSkills => 'Abilități';

  @override
  String get contextSegmentToolDefinitions => 'Definiții de instrumente';

  @override
  String get contextSegmentMcpTools => 'Instrumente MCP și dinamice';

  @override
  String get contextSegmentDeferredTools => 'Instrumente încărcate la cerere';

  @override
  String get contextSegmentSubagents => 'Definiții de subagenți';

  @override
  String get contextSegmentMemory => 'Memorie';

  @override
  String get contextSegmentConversation => 'Conversație';

  @override
  String get contextSegmentRunner =>
      'Promptul executorului, unelte și munca turei';

  @override
  String get contextUsageMeasured => 'Raportat de ultimul apel al modelului';

  @override
  String get contextUsageEstimated =>
      'Estimat până când o rulare raportează utilizarea';

  @override
  String get contextExplorerTitle => 'Context';

  @override
  String get contextExplorerEverything => 'Tot';

  @override
  String get contextExplorerSelectPart =>
      'Selectează o parte ca să-i inspectezi conținutul';

  @override
  String get contextExplorerUnavailable =>
      'Defalcarea contextului nu este disponibilă';

  @override
  String get contextRetry => 'Reîncearcă';

  @override
  String get settingsFieldOptional => 'Opțional';

  @override
  String get settingsFilterHint => 'Filtrează această listă';

  @override
  String get settingsValueNotAvailable => 'Indisponibil încă';

  @override
  String get settingsNoEntriesYet => 'Nimic aici încă';

  @override
  String get settingsChangedBadge => 'Modificat';

  @override
  String get ssoConnectionCardDescription =>
      'Alege cum se autentifică oamenii pe acest server, apoi activează acea conexiune.';

  @override
  String get ssoUseSamlForSignIn => 'Folosește SAML pentru autentificare';

  @override
  String get ssoUseOidcForSignIn =>
      'Folosește OpenID Connect pentru autentificare';

  @override
  String get ssoSaveConnection => 'Salvează conexiunea';

  @override
  String get ssoStateLive => 'Live';

  @override
  String get ssoStateConfiguredOff => 'Configurat, oprit';

  @override
  String get ssoStateOnIncomplete => 'Pornit, incomplet';

  @override
  String get ssoStateActive => 'Activ';

  @override
  String get ssoStateAllowed => 'Permis';

  @override
  String get ssoStateNoToken => 'Fără token';

  @override
  String get ssoSummaryDirectorySync => 'Sincronizare director';

  @override
  String get ssoSummaryManualPairing => 'Asociere manuală';

  @override
  String get ssoNoMethodLiveNote =>
      'Nicio metodă de autentificare nu e live. Dispozitivele noi se alătură cu o invitație sau o cheie de asociere până configurezi o conexiune și o activezi.';

  @override
  String get ssoMethodSamlBlurb =>
      'Pentru providerii de identitate care vorbesc SAML 2.0, precum Okta, Entra ID sau Google Workspace.';

  @override
  String get ssoMethodOidcBlurb =>
      'Pentru providerii de identitate care vorbesc OpenID Connect. De obicei cel mai simplu de configurat dintre cele două.';

  @override
  String get ssoGroupIdentityProvider => 'Provider de identitate';

  @override
  String get ssoGroupIdentityProviderSamlDescription =>
      'De unde vin aserțiunile și cum le verifică acest server.';

  @override
  String get ssoGroupIdentityProviderOidcDescription =>
      'Ce issuer are încredere acest server și clientul ca care se autentifică.';

  @override
  String get ssoSpEntityIdShortLabel => 'SP entity ID';

  @override
  String get ssoSpEntityIdDescription =>
      'Lasă gol ca să-l derive din URL-ul serverului.';

  @override
  String get ssoIssuerDescription =>
      'URL-ul de bază care servește documentul de discovery al providerului.';

  @override
  String get ssoSecretStored => 'Stocat';

  @override
  String get ssoGroupHandoff => 'Ce are nevoie providerul tău de identitate';

  @override
  String get ssoGroupHandoffDescription =>
      'Lipește-le în aplicația pe care ai creat-o la provider.';

  @override
  String get ssoOriginUnknownTitle =>
      'Acest server nu-și cunoaște URL-ul public';

  @override
  String get ssoOriginUnknownBody =>
      'URL-urile de autentificare și callback sunt construite din el, deci providerul tău nu poate atinge acest server până nu e setat unul. Adaugă un URL public sau activează un tunel la Server → Conexiune.';

  @override
  String get ssoAcsUrlLabel => 'URL Assertion consumer service (ACS)';

  @override
  String get ssoAcsUrlDescription =>
      'Unde providerul tău postează aserțiunea semnată.';

  @override
  String get ssoSpEntityIdResolvedLabel => 'Service provider entity ID';

  @override
  String get ssoMetadataUrlLabel => 'URL metadate SP';

  @override
  String get ssoMetadataUrlDescription =>
      'Providerii care importă metadate le pot prelua de aici în schimb.';

  @override
  String get ssoRedirectUriLabel => 'Redirect URI';

  @override
  String get ssoRedirectUriDescription =>
      'Adaugă-l la URI-urile de redirect permise ale aplicației providerului tău.';

  @override
  String get ssoSignInUrlLabel => 'URL de autentificare';

  @override
  String get ssoSignInUrlDescription =>
      'Trimite oamenii aici ca să pornească o autentificare unică.';

  @override
  String get ssoGroupAttributeMapping => 'Mapare atribute';

  @override
  String get ssoGroupAttributeMappingDescription =>
      'Ce claim poartă fiecare câmp. Păstrează implicitele decât dacă providerul le redenumește.';

  @override
  String get ssoGroupAccess => 'Acces și roluri';

  @override
  String get ssoGroupAccessDescription =>
      'Ce are voie să facă cineva care se autentifică cu succes.';

  @override
  String get ssoDefaultRoleShortLabel => 'Rol implicit';

  @override
  String get ssoDefaultRoleDescription =>
      'Dat oricui ale cărui grupuri nu se potrivesc cu nicio mapare de mai jos.';

  @override
  String get ssoRoleMapShortLabel => 'Mapare grup către rol';

  @override
  String get ssoRoleMapDescription =>
      'Primul grup potrivit câștigă. Proprietarul nu poate fi acordat astfel.';

  @override
  String get ssoRoleMapGroupHint => 'Numele grupului de la provider';

  @override
  String get ssoRoleMapAdd => 'Adaugă mapare';

  @override
  String get ssoRoleMapEmpty => 'Nicio mapare — toți primesc rolul implicit.';

  @override
  String get ssoAdvancedSummary =>
      'Decalaj de ceas, autentificare inițiată de IdP, politică de semnătură';

  @override
  String get ssoClockSkewShortLabel => 'Decalaj de ceas';

  @override
  String get ssoClockSkewDescription =>
      'Secunde de toleranță pe timestamp-urile aserțiunilor. 90 se potrivește majorității providerilor.';

  @override
  String get ssoScimGenerate => 'Generează token';

  @override
  String get ssoScimTokenOnceBody =>
      'Copiat în clipboard. Este afișat o dată și nu poate fi recuperat, deci lipește-l acum în provider.';

  @override
  String get ssoPairingCardTitle => 'Asociere manuală';

  @override
  String get ssoPairingCardDescription =>
      'Cealaltă cale către acest server: coduri de invitație și chei de asociere, pentru dispozitive care nu trec prin autentificare unică.';

  @override
  String settingsCountOfTotal(int count, int total) {
    return '$count din $total';
  }

  @override
  String get providersNoneConnectedNote =>
      'Niciun provider nu e conectat, deci runtime-ul încorporat al agentului nu are pe ce să ruleze. Adaugă o cheie API sau autentifică-te la unul mai jos.';

  @override
  String get providersFilterHint => 'Filtrează providerii';

  @override
  String get providersNoneMatch => 'Nimic nu se potrivește acestui filtru';

  @override
  String get providerDeniedHereTitle => 'Refuzat în acest spațiu de lucru';

  @override
  String get providerDeniedHereBody =>
      'Agenții de aici nu pot folosi acest provider, deși e conectat. Celelalte spații de lucru nu sunt afectate.';

  @override
  String get providerNeedsSignIn =>
      'Autentifică-te ca să folosești acest provider';

  @override
  String get providerNeedsApiKey =>
      'Adaugă o cheie API ca să folosești acest provider';

  @override
  String get providerApiKeyLabel => 'Cheie API';

  @override
  String get providerGenerationDefaults => 'Implicite provider';

  @override
  String get providerNoModelsYet =>
      'Niciun model raportat încă. Conectează providerul, apoi sincronizează.';

  @override
  String get providerModelsFilterHint => 'Filtrează modelele';

  @override
  String get adaptersNoneReadyNote =>
      'Niciunul dintre CLI-urile de runner din catalog nu a fost găsit pe această mașină. Instalează unul, apoi reîmprospătează.';

  @override
  String get adaptersFilterHint => 'Filtrează runnerele';

  @override
  String get adaptersLaunchGroup => 'Lansare';

  @override
  String get adaptersLaunchGroupDescription =>
      'Ce i se dă acestui runner când un agent îl pornește. Setează-le înainte de a instala CLI-ul, dacă vrei.';

  @override
  String get adaptersEnvNone => 'Niciuna setată';

  @override
  String adaptersEnvCount(int count) {
    return '$count setate';
  }

  @override
  String get adapterArgumentsDescription =>
      'Adăugate la linia de comandă a runnerului la fiecare lansare.';

  @override
  String get settingsStateFailed => 'Eșuat';

  @override
  String get providerAppsGroupServer => 'Acționează ca serverul';

  @override
  String get providerAppsGroupServerDescription =>
      'Folosit de spațiile de lucru care urmează aplicațiile de autentificare ale acestui server. Un spațiu de lucru cu propriile aplicații își configurează App-ul în Spațiu de lucru → Integrări.';

  @override
  String get providerAppsGroupPrConversations => 'Conversații de pull request';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      'Cum pot dezvoltatorii să comunice cu acest server pe GitHub în spațiile de lucru care urmează acest server. Un spațiu de lucru cu propriile aplicații are un bot propriu în Spațiu de lucru → Integrări. Funcționează fără webhook sau URL public; serverul face polling.';

  @override
  String get providerAppBotLogin => 'Login bot';

  @override
  String get providerAppBotLoginEmpty =>
      'Testează conexiunea ca să rezolvi loginul botului.';

  @override
  String get providerAppAskOnGitHub => 'Întrebări pe GitHub';

  @override
  String get providerAppAskOnGitHubHint =>
      'Menționează loginul botului de mai sus într-un comentariu de pull request — sufixul [bot] e opțional — ca să ceri o revizuire sau să pui o întrebare, să răspunzi în firele lui de revizuire sau să adaugi eticheta `ai-review` ca să ceri o revizuire.';

  @override
  String get providerAppsGroupSignIn => 'Autentificarea oamenilor';

  @override
  String get providerAppsGroupSignInDescription =>
      'Permite fiecărui membru să-și conecteze propriul cont și să obțină date de autentificare proprii.';

  @override
  String get providerAppCapActsAsServer => 'Acționează ca serverul';

  @override
  String get providerAppCapSignsIn => 'Autentifică oamenii';

  @override
  String get portLabel => 'Port';

  @override
  String get mcpBridgedToolsLabel => 'Instrumente';

  @override
  String get guardrailFamilyFiles => 'Fișiere';

  @override
  String get guardrailFamilyGit => 'Git și pull request-uri';

  @override
  String get guardrailFamilyMachine => 'Mașină și rețea';

  @override
  String get guardrailFamilyControl => 'Secrete și spațiu de lucru';

  @override
  String get guardrailScopeFieldLabel => 'Editezi regulile pentru';

  @override
  String get guardrailScopeFieldDescription =>
      'Un domeniu mai îngust câștigă asupra unuia mai larg. Regulile setate aici se aplică peste ce e moștenit.';

  @override
  String get guardrailSetHere => 'Setat aici';

  @override
  String get guardrailClearAllHere => 'Golește tot';

  @override
  String get guardrailFamilyCommands => 'Comenzi';

  @override
  String get guardrailStandingApproval => 'Aprobare temporară';

  @override
  String guardrailEntryAllow(String what) {
    return 'Permis: $what';
  }

  @override
  String guardrailEntryPrompt(String what) {
    return 'Întreabă întâi: $what';
  }

  @override
  String guardrailEntryDeny(String what) {
    return 'Refuzat: $what';
  }

  @override
  String guardrailCoversBranches(String patterns) {
    return 'ramuri $patterns';
  }

  @override
  String guardrailCoversPaths(String patterns) {
    return 'căi $patterns';
  }

  @override
  String guardrailCoversHosts(String patterns) {
    return 'gazde $patterns';
  }

  @override
  String guardrailCoversCommands(String patterns) {
    return 'comenzi $patterns';
  }

  @override
  String guardrailCoversTools(String names) {
    return 'instrumente $names';
  }

  @override
  String guardrailCoversCommandPrefix(String prefix) {
    return 'comenzi care încep cu $prefix';
  }

  @override
  String guardrailCoversMaxCount(String count) {
    return 'cel mult $count simultan';
  }

  @override
  String guardrailCoversMaxCents(String amount) {
    return 'cel mult $amount cenți';
  }

  @override
  String get guardrailCoversEverything => 'orice acțiune de acest tip';

  @override
  String guardrailEntryGivenBy(String name) {
    return 'de $name';
  }

  @override
  String guardrailEntryEnds(String time) {
    return 'expiră la $time';
  }

  @override
  String get guardrailEntryNoEnd => 'până la revocare';

  @override
  String guardrailRevokeEntry(String entry) {
    return 'Revocă: $entry';
  }

  @override
  String get guardrailRevokeFailed => 'Nu s-a putut revoca. Încearcă din nou.';

  @override
  String get guardrailEntryInactive =>
      'fără efect cât acțiunea este setată pe Refuză';

  @override
  String guardrailClassPartlyAllowed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Permis în $count de cazuri listate mai jos',
      few: 'Permis în $count cazuri listate mai jos',
      one: 'Permis în 1 caz listat mai jos',
    );
    return '$_temp0';
  }

  @override
  String guardrailStandingFromWorkspace(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count de aprobări temporare pentru tot spațiul de lucru se aplică și aici.',
      few:
          '$count aprobări temporare pentru tot spațiul de lucru se aplică și aici.',
      one:
          '1 aprobare temporară pentru tot spațiul de lucru se aplică și aici.',
    );
    return '$_temp0';
  }

  @override
  String guardrailStandingInNarrowerScopes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count de aprobări temporare sunt setate pentru spații sau agenți individuali. Alege Spațiu sau Agent mai sus ca să le vezi.',
      few:
          '$count aprobări temporare sunt setate pentru spații sau agenți individuali. Alege Spațiu sau Agent mai sus ca să le vezi.',
      one:
          '1 aprobare temporară este setată pentru un singur spațiu sau agent. Alege Spațiu sau Agent mai sus ca să o vezi.',
    );
    return '$_temp0';
  }

  @override
  String get sandboxingCardLabel => 'Sandboxing';

  @override
  String get sandboxingCardDescription =>
      'Dacă munca agenților rulează izolat de această gazdă și ce poate atinge totuși un agent izolat.';

  @override
  String get sandboxBackendNoneActive => 'Gazdă, fără izolare';

  @override
  String get sandboxSummaryHost => 'Gazdă';

  @override
  String get sandboxGroupIsolation => 'Izolare';

  @override
  String get sandboxGroupIsolationDescription =>
      'Unde se întâmplă de fapt procesele și scrierile de fișiere ale unui agent.';

  @override
  String get sandboxGroupAgentActions => 'Ce pot face agenții';

  @override
  String get sandboxGroupAgentActionsDescription =>
      'Dacă push-ul, deschiderea unui pull request și accesul la rețea sunt permise, necesită confirmare sau sunt refuzate se stabilește în permisiunile agentului.';

  @override
  String get sandboxBackendFieldDescription =>
      'Auto alege cel mai puternic pe care îl suportă această gazdă. Fixează unul ca să nu se schimbe sub tine.';

  @override
  String get sandboxSummaryInForce => 'În vigoare';

  @override
  String get rigsInstallHintLabel => 'Cum se instalează';

  @override
  String get rigsStarting => 'Se pornește';

  @override
  String get rigsResidentMemory => 'Memorie rezidentă';

  @override
  String get installedLabel => 'Instalat';

  @override
  String get notInstalledLabel => 'Neinstalat';

  @override
  String ssoOtherKindUnsaved(String method) {
    return '$method are modificări nesalvate';
  }

  @override
  String get collapseComment => 'Restrânge comentariul';

  @override
  String get expandComment => 'Extinde comentariul';

  @override
  String get suggestedChange => 'Modificare sugerată';

  @override
  String get emptyComment => 'Comentariu gol';

  @override
  String repliesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de răspunsuri',
      few: '# răspunsuri',
      one: '1 răspuns',
    );
    return '$_temp0';
  }

  @override
  String diffFileUnresolvedConversations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de conversații nerezolvate',
      few: '$count conversații nerezolvate',
      one: '1 conversație nerezolvată',
    );
    return '$_temp0';
  }

  @override
  String get pendingReview => 'Revizuire în așteptare';

  @override
  String failedToResolveConversation(String error) {
    return 'Nu s-a putut actualiza conversația: $error';
  }

  @override
  String get addSingleComment => 'Adaugă un singur comentariu';

  @override
  String get addToReview => 'Adaugă la revizuire';

  @override
  String get startAReview => 'Pornește o revizuire';

  @override
  String get commentModeAgent => 'Agent';

  @override
  String get commentModeComment => 'Comentariu';

  @override
  String get commentModeReview => 'Revizuire';

  @override
  String get commentDestination => 'Destinația comentariului';

  @override
  String get commentHintAgent => 'Trimite agentului…';

  @override
  String get commentHintReview => 'Adaugă la revizuire…';

  @override
  String get reviewNeedsABody =>
      'Scrie mai întâi un rezumat sau pune în coadă un comentariu inline';

  @override
  String get reviewSubmitted => 'Revizuire trimisă';

  @override
  String get finishYourReview => 'Finalizează revizuirea';

  @override
  String get commentVerdict => 'Comentează';

  @override
  String pendingCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de comentarii în așteptare',
      few: '# comentarii în așteptare',
      one: '1 comentariu în așteptare',
    );
    return '$_temp0';
  }

  @override
  String andNMore(int count) {
    return 'și încă $count';
  }

  @override
  String get queuedCommentHint =>
      'Acest comentariu pleacă când trimiți revizuirea.';

  @override
  String commentOnLinesRange(int start, int end) {
    return 'Liniile $start până la $end';
  }

  @override
  String get claudeAccountsTitle => 'Conturi Claude Code';

  @override
  String get claudeAccountsDescription =>
      'Fiecare cont este o autentificare Claude Code separată. Rulările folosesc conturile atașate mai jos, în această ordine.';

  @override
  String get claudeAccountsEmpty => 'Niciun cont încă';

  @override
  String get claudeAccountAdd => 'Adaugă cont';

  @override
  String get claudeAccountSignIn => 'Autentifică-te';

  @override
  String get claudeAccountSignInAgain => 'Autentifică-te din nou';

  @override
  String get claudeAccountSignInHint =>
      'Rulează asta într-un terminal pe server. Deschide un browser ca să termini autentificarea și scrie datele de autentificare în directorul acestui cont.';

  @override
  String get claudeAccountSignedOut => 'Deconectat';

  @override
  String get claudeAccountExpired => 'Autentificarea a expirat';

  @override
  String claudeAccountExpiredDetail(String when) {
    return 'Autentificarea a expirat la $when. Autentifică-te din nou ca să folosești acest cont.';
  }

  @override
  String get claudeAccountMakeDefault => 'Fă implicit';

  @override
  String get claudeAccountDefault => 'Implicit';

  @override
  String claudeAccountRemoveConfirm(String label) {
    return 'Elimini $label?';
  }

  @override
  String get claudeAccountRemoveDetail =>
      'Asta deconectează contul și îi șterge directorul de pe server. Autentificarea în sine nu e afectată.';

  @override
  String claudeAccountStatusUnknown(String error) {
    return 'Nu s-a putut verifica acest cont: $error';
  }

  @override
  String claudeAccountUsedPercent(String percent) {
    return '$percent% folosit';
  }

  @override
  String get accountPoolStrategy => 'Rotație';

  @override
  String get accountPoolPinned => 'Fixat';

  @override
  String get accountPoolRoundRobin => 'Round robin';

  @override
  String get accountPoolSerial => 'Unul câte unul';

  @override
  String get accountPoolPinnedHint =>
      'Pornește întotdeauna pe primul cont. Celelalte rămân ca rezervă dacă eșuează.';

  @override
  String get accountPoolRoundRobinHint =>
      'Distribuie rulările pe conturi, trecând la următorul la fiecare dispatch.';

  @override
  String get accountPoolSerialHint =>
      'Epuizează primul cont înainte de a atinge următorul.';

  @override
  String get accountPoolMoveUp => 'Mută în sus';

  @override
  String get accountPoolMoveDown => 'Mută în jos';

  @override
  String get accountPoolUsingAll =>
      'Nimic atașat încă — se folosesc toate conturile, în această ordine.';

  @override
  String get accountPoolInheriting =>
      'Moștenește conturile spațiului de lucru.';

  @override
  String get accountPoolResetToWorkspace =>
      'Resetează la conturile spațiului de lucru';

  @override
  String accountPoolCoolingOff(String when) {
    return 'fără cotă până la $when';
  }

  @override
  String get accountPoolSignedOut => 'deconectat';

  @override
  String get accountPoolExpired => 'autentificarea a expirat';

  @override
  String accountPoolLoadFailed(String error) {
    return 'Nu s-a putut încărca rotația: $error';
  }

  @override
  String get providerSignedInAccount => 'cont autentificat';

  @override
  String get agentAccountsTab => 'Conturi';

  @override
  String get agentClaudeAccountsNoticeTitle => 'Mai multe conturi Claude Code';

  @override
  String agentClaudeAccountsNoticeBody(int count) {
    return 'Acest runner se autentifică ca unul dintre cele $count conturi Claude Code de pe această gazdă. Alege care, sau rotește între ele, în fila Conturi.';
  }

  @override
  String get agentAccountsDescription =>
      'Ce conturi folosesc rulările acestui agent. Fiecare bloc începe moștenind alegerea spațiului de lucru.';

  @override
  String get agentAccountsNothingToRotate =>
      'Nimic de rotit — conectează mai întâi un al doilea cont sau o a doua cheie.';

  @override
  String failedToPostReply(String error) {
    return 'Nu s-a putut posta răspunsul: $error';
  }

  @override
  String failedToPostComment(String error) {
    return 'Nu s-a putut posta comentariul: $error';
  }

  @override
  String commentOnLine(int line) {
    return 'Linia $line';
  }

  @override
  String get viewInDiff => 'Vezi în diff';

  @override
  String get subscriptionUsagePreviousAccount => 'Contul anterior';

  @override
  String get subscriptionUsageNextAccount => 'Contul următor';

  @override
  String inReplyTo(String path) {
    return 'Ca răspuns la $path';
  }

  @override
  String get subscriptionUsageNoneReported =>
      'Nicio utilizare raportată pentru acest cont.';

  @override
  String get subscriptionUsageCredits => 'Credite';

  @override
  String get reviewHubStaticRule => 'Regulă statică';

  @override
  String get reviewHubStarted => 'Revizuirea a pornit';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return 'Găsit de o regulă deterministă ($rule) pe o linie pe care o adaugă acest pull request — nu de un agent recenzent.';
  }

  @override
  String get prReviewArtifactTab => 'Revizuire PR';

  @override
  String get prReviewRunning => 'Se revizuiește acest pull request…';

  @override
  String get prReviewStarting => 'Se pornește revizuirea…';

  @override
  String get prReviewStartingBody =>
      'Se pregătește worktree-ul acestui pull request. Recenzenții pornesc imediat ce e gata.';

  @override
  String get prReviewFailed => 'Revizuirea a eșuat.';

  @override
  String get prReviewRerunning => 'Se re-revizuiește…';

  @override
  String get prReviewNoOpenFindings => 'Nicio constatare deschisă';

  @override
  String prReviewOpenFindings(int count) {
    return '$count constatări deschise';
  }

  @override
  String subscriptionUsageSpend(String used, String limit) {
    return '$used din $limit';
  }

  @override
  String reviewCommentsPosted(int posted, int skipped, int failed) {
    return 'S-au postat $posted comentariu(ii) ca bot. $skipped sărite (fără ancoră de fișier), $failed eșuate.';
  }

  @override
  String reviewFindingsOutOfDiff(int count, String files) {
    return '$count constatare(ări) vizează cod pe care acest pull request nu îl modifică ($files). GitHub acceptă comentarii inline doar pe diff.';
  }

  @override
  String get reviewRailReport => 'Raport';

  @override
  String get reviewNoFindingsTitle => 'Nicio constatare de revizuire încă';

  @override
  String get reviewNoFindingsHint =>
      'Constatările apar aici pe măsură ce agenții le postează.';

  @override
  String reviewShowDismissed(int count) {
    return 'Afișează $count respinse';
  }

  @override
  String reviewHideDismissed(int count) {
    return 'Ascunde $count respinse';
  }

  @override
  String reviewDisagreementsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de dezacorduri între recenzenți detectate',
      few: '# dezacorduri între recenzenți detectate',
      one: '1 dezacord între recenzenți detectat',
    );
    return '$_temp0';
  }

  @override
  String get reviewFilterKind => 'Tip';

  @override
  String get reviewFilterStatus => 'Stare';

  @override
  String get reviewKindBug => 'Bug';

  @override
  String get reviewKindSuggestion => 'Sugestie';

  @override
  String get reviewKindRecommendation => 'Recomandare';

  @override
  String get reviewKindQuestion => 'Întrebare';

  @override
  String get reviewKindTicket => 'Tichet';

  @override
  String get spaceAllPrsMerged =>
      'Toate cererile de integrare din acest spațiu au fost îmbinate. Arhivezi acest spațiu?';

  @override
  String get spaceKeepAfterMerge => 'Nu, păstrează acest spațiu';

  @override
  String get spaceKeepAfterMergeHint =>
      'Nu vei mai fi întrebat despre acest spațiu.';

  @override
  String get archiveSpace => 'Arhivează spațiul';

  @override
  String get archivedSpaces => 'Spații arhivate';

  @override
  String get archivedSpacesEmpty => 'Niciun spațiu arhivat';

  @override
  String get restoreSpace => 'Restaurează';

  @override
  String get archivedConversations => 'Conversații arhivate';

  @override
  String get archivedConversationsEmpty => 'Nicio conversație arhivată';

  @override
  String get restoreConversation => 'Restaurează';

  @override
  String archivedWhen(String time) {
    return 'Arhivat $time';
  }

  @override
  String get deleteSpacePermanently => 'Șterge definitiv';

  @override
  String get renameSpace => 'Redenumește spațiul';

  @override
  String get renameConversation => 'Redenumește conversația';

  @override
  String get spaceActions => 'Acțiuni spațiu';

  @override
  String get conversationActions => 'Acțiuni conversație';

  @override
  String get editSpaceRepos => 'Editează depozitele';

  @override
  String get editSpaceReposTitle => 'Depozitele spațiului';

  @override
  String get editSpaceReposWarning =>
      'Adăugarea unui depozit îl face checkout în acest spațiu; eliminarea unuia îi șterge folderul.';

  @override
  String get agentSectionIdentity => 'Identitate';

  @override
  String get agentSectionRuntime => 'Runtime';

  @override
  String get agentSectionGuardrails => 'Guardrail-uri';

  @override
  String orgChartReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de rapoarte',
      few: '# rapoarte',
      one: '1 raport',
    );
    return '$_temp0';
  }

  @override
  String get teamsFilterHint => 'Filtrează echipele…';

  @override
  String get teamsSummaryWithLeader => 'Cu un lider';

  @override
  String teamCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de echipe',
      few: '# echipe',
      one: '1 echipă',
      zero: 'Nicio echipă',
    );
    return '$_temp0';
  }

  @override
  String agentDeleteLongDescription(String name) {
    return 'Ștergerea lui $name elimină profilul, legăturile de abilități și istoricul de rulări. Acțiunea nu poate fi anulată.';
  }

  @override
  String get resetToDefault => 'Resetează la implicit';

  @override
  String get newAgent => 'Agent nou';

  @override
  String get newSkill => 'Abilitate nouă';

  @override
  String get newItemAction => 'Nou';

  @override
  String get zoomIn => 'Mărește';

  @override
  String get zoomOut => 'Micșorează';

  @override
  String get resetZoom => 'Resetează zoomul';

  @override
  String get imageHostedOnGitHub => 'Imagine găzduită pe GitHub';

  @override
  String get imageOpenExternally => 'Imagine · deschide extern';

  @override
  String get memoryScopeAll => 'Toate domeniile';

  @override
  String get memoryScopeWorkspace => 'La nivel de spațiu de lucru';

  @override
  String get memoryScopeFilterLabel => 'Filtrează după domeniu';

  @override
  String memoryScopeRepoTooltip(String repo) {
    return 'Domeniu: depozitul $repo';
  }

  @override
  String get toolScreenshot => 'Captură de ecran de la agent';

  @override
  String get toolImageUnavailable => 'Imagine indisponibilă';

  @override
  String toolImagesUnavailable(int count) {
    return '$count imagini indisponibile';
  }

  @override
  String get shakeUnavailable =>
      'Scuturarea nu este disponibilă pe acest server';

  @override
  String get shakeNothing =>
      'Nimic de scuturat — tururile recente sunt protejate';

  @override
  String shakeDone(int tokens) {
    return 'S-au eliberat circa $tokens tokeni';
  }

  @override
  String get compactionDivider => 'Compactat';

  @override
  String compactionDividerCount(int count) {
    return 'Compactat · $count mesaje pliate';
  }

  @override
  String get composerDropToAttach => 'Lasă ca să atașezi';

  @override
  String get composerAttachmentUploading => 'Se încarcă…';

  @override
  String get composerAttachmentReady => 'Pregătit';

  @override
  String get composerAttachmentUploadFailed => 'Încărcarea a eșuat';

  @override
  String composerAttachmentTooLarge(String limit) {
    return 'Fișierul depășește limita de $limit';
  }

  @override
  String get composerAttachmentUnreadable => 'Nu s-a putut citi acest fișier';

  @override
  String get composerAttachmentWaitForUploads =>
      'Așteaptă să se termine încărcarea atașamentelor';

  @override
  String get composerAttachmentResolveFailures =>
      'Încearcă din nou sau elimină atașamentele cu încărcare eșuată înainte de trimitere';

  @override
  String get attachmentUnavailable => 'Atașament indisponibil';

  @override
  String get attachmentUnavailableDetail =>
      'Acest atașament nu mai e ținut în memorie. Atașează-l din nou ca să-l previzualizezi.';

  @override
  String get attachmentPreviewFailed => 'Nu s-a putut deschide acest fișier';

  @override
  String get attachmentPreviewUnsupported =>
      'Nicio previzualizare pentru acest tip de fișier';

  @override
  String get attachmentTooLargeToPreview => 'Prea mare pentru previzualizare';

  @override
  String get attachmentOpenExternally => 'Deschide în aplicația implicită';

  @override
  String get asideEmpty => 'Nimic de la care să pornești încă';

  @override
  String get asideFailed => 'Nu s-a putut obține un răspuns';

  @override
  String get handoffTitle => 'Predare';

  @override
  String get asideTitle => 'Întrebare laterală';

  @override
  String get attachFilesOrDrop => 'Atașează fișiere — sau lasă-le aici';

  @override
  String composerExpand(String shortcut) {
    return 'Extinde editorul ($shortcut)';
  }

  @override
  String composerCollapse(String shortcut) {
    return 'Restrânge editorul ($shortcut)';
  }

  @override
  String get guidedGoalTitle => 'Clarifică obiectivul';

  @override
  String get guidedGoalIntro =>
      'Un agent care lucrează nesupravegheat trebuie să știe exact când e gata. Câteva întrebări întâi.';

  @override
  String get guidedGoalAnswerHint => 'Răspunsul tău';

  @override
  String get guidedGoalNext => 'Următorul';

  @override
  String get guidedGoalStart => 'Pornește obiectivul';

  @override
  String get guidedGoalSkip => 'Sari și rulează așa cum e scris';

  @override
  String guidedGoalStillMissing(String items) {
    return 'Încă nespecificat: $items';
  }

  @override
  String get conversationTreeTitle => 'Arbore de conversație';

  @override
  String conversationTreeBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de ramuri',
      few: '# ramuri',
      one: '1 ramură',
    );
    return '$_temp0';
  }

  @override
  String get conversationTreeSwitch => 'Continuă de aici';

  @override
  String get conversationTreeFork => 'Bifurcă într-o conversație nouă';

  @override
  String get conversationTreeCurrent => 'Pe această ramură';

  @override
  String get conversationTreeEmpty => 'Nimic aici încă';

  @override
  String get conversationTreeForked => 'Bifurcat într-o conversație nouă';

  @override
  String get conversationTreeSwitched => 'Se continuă acum de la acel mesaj';

  @override
  String exportSaved(String path) {
    return 'Salvat la $path';
  }

  @override
  String get exportFailed => 'Nu s-a putut scrie exportul';

  @override
  String get contextCommandNoAgent =>
      'Niciun agent în această conversație, deci nu există o fereastră de context de deschis';

  @override
  String contextCommandNoSuchAgent(String name, String names) {
    return 'Niciun agent numit \"$name\" în această conversație. Încearcă: $names';
  }

  @override
  String get dumpCopied => 'Transcrierea a fost copiată în clipboard';

  @override
  String get messageQueueHint =>
      'Continuă să tastezi ca să pui în coadă modificări ulterioare';

  @override
  String get steerNow => 'Direcționează';

  @override
  String get steerForce => 'Oprește și trimite';

  @override
  String get steeringQueueLabel => 'Mesaje de direcționare în coadă';

  @override
  String get steeringDeliverUnavailable =>
      'Niciun agent în rulare nu poate prelua asta acum — rămâne în coadă.';

  @override
  String get reorderSteeringCard => 'Reordonează mesajul din coadă';

  @override
  String get editSteeringCard => 'Editează mesajul din coadă';

  @override
  String get deleteSteeringCard => 'Șterge mesajul din coadă';

  @override
  String get steeringBadge => 'Direcționat';

  @override
  String get settingsSandboxLabel => 'Sandbox';

  @override
  String get sandboxExecGrantsTitle => 'Granturi de executabile';

  @override
  String get sandboxExecGrantsSubtitle =>
      'Programe pe care agenții le pot rula din copia lor de lucru a depozitelor tale. Fiecare înregistrare a fost aprobată de tine când sandbox-ul a cerut.';

  @override
  String get sandboxExecGrantsEmpty =>
      'Nicio decizie înregistrată încă. Vei fi întrebat prima dată când un agent trebuie să ruleze un program din copia lui de lucru.';

  @override
  String get sandboxExecGrantRevoke => 'Revocă';

  @override
  String get sandboxExecGrantAllowed => 'Permis';

  @override
  String get sandboxExecGrantBlocked => 'Blocat';

  @override
  String get sandboxExecGrantRevokeConfirmTitle => 'Revoci această decizie?';

  @override
  String get sandboxExecGrantRevokeConfirmBody =>
      'Vei fi întrebat din nou data viitoare când un agent trebuie să ruleze un program din această copie.';

  @override
  String get sandboxExecGrantsSearchHint => 'Caută căi';

  @override
  String get sandboxExecGrantsNoMatch => 'Niciun grant nu corespunde căutării';

  @override
  String get demoBadgeLabel => 'Demo';

  @override
  String get demoFilePickerTitle => 'Fișiere demo';

  @override
  String get demoFilePickerBody =>
      'Demo-ul simulează încărcările: alege oricare dintre acestea și se atașează mesajului fără să atingă un disc.';

  @override
  String get demoFilePickerAttach => 'Atașează';

  @override
  String get demoReadOnlySave => 'Doar-citire în demo';

  @override
  String get demoBadgeTooltip =>
      'Explorezi un demo. Datele sunt fictive, iar agenții sunt scriși.';

  @override
  String get demoFirstRunTitle => 'Ești într-un demo live';

  @override
  String demoFirstRunBody(int minutes) {
    return 'Aceasta e aplicația reală care rulează pe cod real — doar datele sunt inventate. Agenții streamează rulări autentice dintr-un script, deci nimic nu ajunge la un model și nimic nu rulează pe o mașină. Spațiul tău de lucru e doar al tău și dispare după $minutes minute.';
  }

  @override
  String get demoFirstRunDismiss => 'Am înțeles';

  @override
  String get demoTourTitle => 'Unde să te uiți întâi';

  @override
  String get demoTourSubtitle =>
      'Patru locuri care arată ce face de fapt aplicația.';

  @override
  String get demoTourSkip => 'Sari';

  @override
  String get demoTourStarRepo => 'Star pe GitHub';

  @override
  String get demoTourOpen => 'Deschide';

  @override
  String get demoTourSpacesTitle => 'Vorbește cu un agent';

  @override
  String get demoTourSpacesBody =>
      'Trimite un mesaj într-un spațiu și urmărește o rulare care streamează — gândire, apeluri de instrumente și cost, exact cum se randă o rulare reală.';

  @override
  String get demoTourReviewTitle => 'Revizuiește un pull request';

  @override
  String get demoTourReviewBody =>
      'Deschide #412. Lasă un comentariu inline sau trimite o revizuire; cuvintele tale ajung în fir și rămân acolo.';

  @override
  String get demoTourTicketsTitle => 'Urmărește munca';

  @override
  String get demoTourTicketsBody =>
      'Tichetele, todo-urile și planurile sunt legate de aceleași conversații pe care le au agenții.';

  @override
  String get demoTourInboxTitle => 'Vezi toată operațiunea';

  @override
  String get demoTourInboxBody =>
      'Fiecare alertă din fiecare pilon ajunge într-un singur inbox — revizuiri, tichete, rulări și întâlniri.';

  @override
  String get demoUnavailableTitle => 'Indisponibil în demo';

  @override
  String get demoUnavailableTerminal =>
      'Un terminal rulează un shell real pe gazda serverului. Demo-ul nu are nicio suprafață de execuție — asta îl face sigur de deschis publicului.';

  @override
  String get demoUnavailableRig =>
      'Un mediu izolat este o mașină virtuală de unică folosință pe care o conduce un agent. Demo-ul nu pornește nicio VM: un endpoint public care poate porni o VM nu e un demo.';

  @override
  String get demoUnavailableEditor =>
      'Editorul din browser rulează un proces code-server pe un checkout real. Demo-ul nu are niciunul.';

  @override
  String get demoUnavailableFeeds =>
      'Demo-ul citește fluxuri reale, dar lista de abonamente e fixă. Adăugarea sau eliminarea unuia e dezactivată aici.';

  @override
  String get demoUnavailableForge =>
      'Demo-ul nu deține date de autentificare și nu contactează niciodată GitHub, GitLab sau Linear. Pull request-urile sunt fixture, iar comentariile tale pe ele sunt stocate local.';

  @override
  String get demoUnavailableModels =>
      'Demo-ul nu apelează niciun model. Rulările de agenți sunt redare din script, de aceea nu costă nimic și nu ajung la niciun provider.';

  @override
  String get demoUnavailableMcp =>
      'Suprafața de instrumente MCP nu e montată pe demo, deci niciun client extern nu se poate atașa.';

  @override
  String get demoUnavailableRepos =>
      'Demo-ul nu face checkout de cod și nu rulează git. Depozitul pe care îl vezi e un fixture din spatele pull request-urilor.';

  @override
  String get demoUnavailableSkills =>
      'Instalarea unei abilități descarcă și scanează cod. Demo-ul nu preia nimic.';

  @override
  String get demoUnavailableSso =>
      'Autentificarea unică e configurare de server. Demo-ul te autentifică ca invitat temporar în schimb.';

  @override
  String get demoUnavailableAudio =>
      'Înregistrarea și dictarea au nevoie de captură audio și de un model de vorbire pe gazdă. Demo-ul nu le include, deci întâlnirile lui sunt transcrieri fără redare.';

  @override
  String get demoUnavailableServerAdmin =>
      'Asta e administrare de server. Demo-ul dă fiecărui vizitator propriul spațiu de lucru de unică folosință și nimic dincolo de el.';

  @override
  String get demoUnavailablePipelines =>
      'Pipeline-urile nu pot rula aici. Un vizitator care poate scrie un pas bash și îl poate porni — manual sau printr-un declanșator de eveniment — execută cod pe acest gazdă.';

  @override
  String get settingsBackupRestore => 'Backup și restaurare';

  @override
  String get settingsBackupRestoreDescription =>
      'Snapshot-uri ale fiecărei baze de date de pe acest server, plus export, import și ștergere pentru un singur spațiu de lucru.';

  @override
  String get backupSnapshotsLabel => 'Snapshot-uri de instalare';

  @override
  String get backupSnapshotsExplainer =>
      'Un snapshot copiază fiecare bază de date într-un folder cu timestamp pe gazda serverului. Restaurarea unei instalări întregi înseamnă copierea acelui folder înapoi cu serverul oprit; un singur spațiu de lucru poate fi restaurat de aici.';

  @override
  String get backupNowAction => 'Fă backup acum';

  @override
  String backupSnapshotWritten(String path) {
    return 'Snapshot scris la $path';
  }

  @override
  String get backupNoSnapshots =>
      'Nu există încă snapshoturi ale instalării. Creează unul acum sau folosește un pipeline programat pentru copiile spațiului de lucru.';

  @override
  String get backupSnapshotComplete => 'Complet';

  @override
  String get backupDeleteSnapshotLabel => 'Șterge snapshotul';

  @override
  String get backupDeleteSnapshotDescription =>
      'Elimină permanent acest snapshot de pe server. Descarcă-l mai întâi dacă vrei să-l păstrezi.';

  @override
  String get backupDeleteSnapshotAction => 'Șterge snapshotul';

  @override
  String get backupDeleteSnapshotTitle => 'Ștergi acest snapshot?';

  @override
  String backupDeleteSnapshotBody(String name) {
    return 'Ștergi $name de pe server? Toate bazele de date din acest snapshot vor fi pierdute. Acțiunea nu poate fi anulată.';
  }

  @override
  String backupDeleteSnapshotDone(String name) {
    return 'Snapshotul $name a fost șters.';
  }

  @override
  String backupSnapshotWorkspaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de spații de lucru',
      few: '# spații de lucru',
      one: '1 spațiu de lucru',
      zero: 'Niciun spațiu de lucru',
    );
    return '$_temp0';
  }

  @override
  String backupSnapshotSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de spații de lucru necaptate',
      few: '# spații de lucru necaptate',
      one: '1 spațiu de lucru necaptat',
    );
    return '$_temp0';
  }

  @override
  String get backupServerPathLabel => 'Cale pe server';

  @override
  String get backupScheduledLabel => 'Copii de rezervă programate';

  @override
  String get backupScheduledExplainer =>
      'Copii salvate de pipeline-ul de backup al fiecărui spațiu de lucru. Setează programul și perioada de păstrare în șablonul pipeline-ului.';

  @override
  String get backupScheduledNone => 'Nu există încă copii de rezervă';

  @override
  String backupScheduledCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de copii de rezervă',
      few: '$count copii de rezervă',
      one: '1 copie de rezervă',
    );
    return '$_temp0';
  }

  @override
  String backupScheduledLast(String time) {
    return 'Ultima copie: $time';
  }

  @override
  String get backupListForbidden =>
      'Ai nevoie de rolul de administrator în acest spațiu de lucru pentru a-i vedea copiile.';

  @override
  String get backupScheduledDeleteTitle => 'Ștergi această copie de rezervă?';

  @override
  String backupScheduledDeleteBody(String date, String name) {
    return 'Ștergi de pe server copia din $date a $name? Acțiunea nu poate fi anulată.';
  }

  @override
  String get backupScheduledDeleteDone => 'Copia de rezervă a fost ștearsă.';

  @override
  String get backupScheduledWorkspaceDeleted => 'Spațiu de lucru șters';

  @override
  String get backupRestoreAction => 'Restaurează';

  @override
  String get backupRestoreTitle => 'Restaurează spațiul de lucru';

  @override
  String backupRestoreBody(String name) {
    return 'Asta înlocuiește totul din $name cu copia ținută în acest snapshot. Orice a făcut acel spațiu de lucru de la snapshot se pierde și nu poate fi anulat.';
  }

  @override
  String backupRestoreDone(String name) {
    return 'S-a restaurat $name din snapshot.';
  }

  @override
  String get backupWorkspaceUnknown => 'Nu mai e pe acest server';

  @override
  String get backupWorkspaceDataLabel => 'Date spațiu de lucru';

  @override
  String get backupWorkspaceDataExplainer =>
      'Un spațiu de lucru e un fișier de bază de date, deci exportul îl copiază în loc să dump-uiască tabel cu tabel. Importul înlocuiește totul din spațiul de lucru țintă cu fișierul pe care îl numești.';

  @override
  String get backupExportAction => 'Exportă';

  @override
  String backupExportDone(String path) {
    return 'Exportat la $path';
  }

  @override
  String get backupExportedFileLabel => 'Fișier exportat pe server';

  @override
  String get backupImportAction => 'Importă';

  @override
  String backupImportTitle(String name) {
    return 'Importă în $name';
  }

  @override
  String backupImportBody(String name) {
    return 'Asta înlocuiește totul din $name cu conținutul fișierului. Ce deține acum acel spațiu de lucru se pierde și nu poate fi anulat.';
  }

  @override
  String get backupImportSourceLabel =>
      'Fișier bază de date a spațiului de lucru';

  @override
  String get backupImportSourceDescription =>
      'Un fișier .db pe care serverul îl poate citi. Căile se rezolvă pe gazda serverului, nu pe acest dispozitiv.';

  @override
  String backupImportDone(String name) {
    return 'Importat în $name.';
  }

  @override
  String backupDeleteBody(String name) {
    return '$name dispare din fiecare listă și căutare. Fișierul bazei de date rămâne pe disc, backup-urile îl includ în continuare și nimic nu recuperează spațiul automat.';
  }

  @override
  String get backupExportDescription =>
      'Scrie o copie pe server sau descarcă una pe acest dispozitiv.';

  @override
  String get backupExportOnServerAction => 'Salvează pe server';

  @override
  String get backupDownloadAction => 'Descarcă';

  @override
  String backupDownloadSaved(String path) {
    return 'Salvat la $path';
  }

  @override
  String get backupDownloadInBrowser => 'Browserul tău o descarcă.';

  @override
  String get backupRestoreFromDeviceLabel =>
      'Restaurează de pe acest dispozitiv';

  @override
  String get backupRestoreFromDeviceDescription =>
      'Alege aici un fișier de bază de date a spațiului de lucru și Control Center îl încarcă pe server. Asta e varianta care funcționează când serverul nu e această mașină.';

  @override
  String get backupUploadAction => 'Alege un fișier și încarcă';

  @override
  String get backupTransferUnavailable =>
      'Transferul de fișiere nu este configurat încă pentru această conexiune. Reconectează-te la server ca să descarci sau să încarci un backup.';

  @override
  String get backupTransferForbidden =>
      'Serverul a refuzat. Descărcarea unui spațiu de lucru necesită rolul de admin al spațiului de lucru. Restaurarea unuia necesită proprietarul serverului, care trebuie să fie și proprietarul acelui spațiu de lucru. Un snapshot întreg necesită proprietarul serverului.';

  @override
  String get backupTransferUnsupported =>
      'Acest server nu are o suprafață de backup.';

  @override
  String get backupTransferTooLarge =>
      'Fișierul e mai mare decât acceptă serverul.';

  @override
  String get credentialGateWaitingTitle => 'Se așteaptă date de autentificare';

  @override
  String credentialGateHarnessTitle(String provider) {
    return '$provider nu are date de autentificare';
  }

  @override
  String get credentialGateSignedOutTitle => 'Claude Code este deconectat';

  @override
  String get credentialGateExpiredTitle =>
      'Autentificarea ta Claude Code a expirat';

  @override
  String get credentialGatePlanSpentTitle =>
      'S-a atins limita planului Claude Code';

  @override
  String credentialGateWaitingAgent(String agent) {
    return '$agent așteaptă să continue.';
  }

  @override
  String get credentialGateWaitingRun => 'O rulare așteaptă să continue.';

  @override
  String get credentialGateWatching =>
      'Se urmărește remedierea — rularea continuă de la sine.';

  @override
  String credentialGateFreesUpAt(String time) {
    return 'Se eliberează la $time';
  }

  @override
  String credentialGateGivesUpAt(String time) {
    return 'Rularea renunță la $time';
  }

  @override
  String get credentialGateCheckAgain => 'Verifică din nou';

  @override
  String get credentialGateCancelRun => 'Anulează rularea';

  @override
  String get credentialGateAccountsTried => 'Conturi încercate';

  @override
  String get credentialGateClaudeSignInHint =>
      'Autentifică-te din Setări → Adaptori → Claude Code sau rulează comanda de login într-un terminal. Rularea o preia de la sine.';

  @override
  String get credentialGateOpenSettings => 'Deschide setările';

  @override
  String get credentialGateAccountsRemovedTitle =>
      'Conturile Claude Code atașate au fost eliminate';

  @override
  String get credentialGateAccountsRemovedHint =>
      'Atașează alt cont în setările de conturi ale acestui agent sau ale spațiului de lucru, ori golește lista ca să folosești contul implicit. Rularea continuă singură.';

  @override
  String get accountPoolAllRemoved =>
      'Toate conturile din această listă au fost eliminate de pe server. Atașează altul sau golește lista.';

  @override
  String get accountPoolClear => 'Golește lista';

  @override
  String get selectModel => 'Selectează modelul';

  @override
  String get allModels => 'Toate modelele';

  @override
  String get noModelsMatchSearch => 'Niciun model nu corespunde căutării';

  @override
  String useCustomModelId(String id) {
    return 'Folosește „$id”';
  }

  @override
  String get modelFree => 'Gratuit';

  @override
  String modelOutputTokens(String tokens) {
    return '$tokens ieșire';
  }

  @override
  String modelPricePerMTokens(String input, String output) {
    return '$input intrare / $output ieșire per 1M tokenuri';
  }

  @override
  String modelEffortLevels(String levels) {
    return 'Efort de raționament: $levels';
  }

  @override
  String get modelSupportsReasoning => 'Acceptă efort de raționament';

  @override
  String get profileDeliveryMetrics => 'Indicatori de livrare';

  @override
  String profileMetricsSample(int count) {
    return 'PR-uri analizate: $count';
  }

  @override
  String get profileMergeRate => 'Rată de îmbinare';

  @override
  String get profileReviewCoverage => 'Acoperirea revizuirii';

  @override
  String get profilePrSize => 'Dimensiune PR';

  @override
  String get profileTimeToMerge => 'Timp până la îmbinare';

  @override
  String get profileMergeTimeTrend => 'Tendința timpului de îmbinare';

  @override
  String get profileWeeklyMedian => 'Mediană săptămânală, scară logaritmică';

  @override
  String get profilePrOpeningPattern => 'Ziua săptămânii × ora, ora locală';

  @override
  String get profileFirstReview => 'Timp până la prima revizuire';

  @override
  String get profileMetricsTruncated =>
      'Percentilele folosesc un eșantion limitat din solicitările de extragere disponibile.';

  @override
  String profileLinesChanged(String count) {
    return '$count linii';
  }

  @override
  String profileDurationMinutes(int count) {
    return '$count min';
  }

  @override
  String profileDurationHours(int count) {
    return '$count h';
  }

  @override
  String profileDurationDaysHours(int days, int hours) {
    return '${days}z ${hours}h';
  }

  @override
  String profilePercentiles(String median, String p90) {
    return 'p50 $median · p90 $p90';
  }

  @override
  String profileTeamMembers(int count) {
    return 'Membri: $count';
  }

  @override
  String noPrsByTeamInWorkspace(String team) {
    return 'Niciun pull request de la $team în acest spațiu de lucru';
  }

  @override
  String get profilePrStateFilterLabel =>
      'Filtrează pull request-urile după stare';

  @override
  String get noProfilePrsMatchSearchHint =>
      'Încearcă alt titlu sau număr de pull request';

  @override
  String get rigNetworkUnrestricted => 'Rețea fără restricții';

  @override
  String get rigNetworkAllowAllHosts => 'Permite toate gazdele';

  @override
  String get rigBrowserPermissionsTitle => 'Permisiuni ale site-ului';

  @override
  String get rigBrowserPermissionsTooltip =>
      'Permisiuni ale site-ului și rețea';

  @override
  String get rigBrowserPermissionEmpty =>
      'Niciun site nu a cerut încă o permisiune';

  @override
  String rigBrowserPermissionPrompt(String origin, String permission) {
    return '$origin vrea să folosească $permission';
  }

  @override
  String get rigBrowserPermissionBlock => 'Blochează';

  @override
  String get rigBrowserPermissionCamera => 'Cameră';

  @override
  String get rigBrowserPermissionMicrophone => 'Microfon';

  @override
  String get rigBrowserPermissionNotifications => 'Notificări';

  @override
  String get rigBrowserPermissionGeolocation => 'Locație';

  @override
  String get rigBrowserPermissionPersistentStorage => 'Stocare persistentă';

  @override
  String get rigBrowserPermissionClipboard => 'Clipboard';

  @override
  String get rigBrowserPermissionDisplayCapture => 'Captură de ecran';

  @override
  String get rigBrowserPermissionMidi => 'MIDI';

  @override
  String get rigNetworkBypassTitle => 'Permiți toate gazdele din rețea?';

  @override
  String get rigNetworkBypassBody =>
      'Această acțiune repornește mediul izolat și elimină lucrul neconfirmat din interior. Apoi, sistemul invitat va putea accesa orice gazdă din rețea până când este închis.';

  @override
  String get rigNetworkRestartUnrestricted => 'Repornește fără restricții';

  @override
  String get rigNetworkUnrestrictedBody =>
      'Acest mediu izolat poate accesa orice gazdă din rețea. Închide-l și deschide unul nou pentru a restabili restricțiile implicite.';

  @override
  String get rigNetworkAlreadyUnrestrictedBody =>
      'Acest emulator Android își gestionează deja propria rețea, deci Control Center nu poate impune o listă de gazde permise. Nu este necesară repornirea.';

  @override
  String get rigClipboardPermissionHostToRigTitle =>
      'Lipiți clipboardul în acest mediu?';

  @override
  String get rigClipboardPermissionHostToRigBody =>
      'Control Center va citi clipboardul dispozitivului dvs. și va trimite conținutul acestuia către mediu. Conținutul clipboardului poate conține parole sau alte secrete.';

  @override
  String get rigClipboardPermissionRigToHostTitle =>
      'Copiați clipboardul din acest mediu?';

  @override
  String get rigClipboardPermissionRigToHostBody =>
      'Control Center va citi clipboardul mediului și va înlocui clipboardul dispozitivului dvs. cu conținutul acestuia. Tratați conținutul din mediu ca nefiind de încredere.';

  @override
  String get rigClipboardAllowTenMinutes => 'Permiteți timp de 10 minute';

  @override
  String get rigClipboardAlwaysAllow => 'Permiteți întotdeauna';

  @override
  String get rigClipboardSettingsTitle => 'Acces la clipboard';

  @override
  String get rigClipboardSettingsHint =>
      'Alegeți ce transferuri de clipboard pot rula fără confirmare. Permisiunile temporare expiră după 10 minute.';

  @override
  String get rigClipboardAlwaysPasteTitle =>
      'Permiteți întotdeauna lipirea în medii';

  @override
  String get rigClipboardAlwaysPasteDescription =>
      'Trimiteți clipboardul acestui dispozitiv către orice mediu fără confirmare.';

  @override
  String get rigClipboardAlwaysCopyTitle =>
      'Permiteți întotdeauna copierea din medii';

  @override
  String get rigClipboardAlwaysCopyDescription =>
      'Puneți conținutul clipboardului din orice mediu pe acest dispozitiv fără confirmare.';

  @override
  String get profileOverlayHint =>
      'Aceste câmpuri ești tu în acest spațiu. Câmpurile goale moștenesc numele și e-mailul contului. Schimbarea spațiului schimbă această suprapunere.';

  @override
  String get stackStartNextPart => 'Începe partea următoare';

  @override
  String get stackPartNameTitle => 'Numele părții';

  @override
  String get stackPartNameHint => 'ex. migrare';

  @override
  String get stackPublish => 'Publică stiva';

  @override
  String get stackCurrentPart => 'Curentă';

  @override
  String get stackSwitchDirty =>
      'Confirmă sau renunță la modificări înainte de a schimba partea';

  @override
  String get stackCutFailed => 'Partea următoare nu a putut fi începută';

  @override
  String get stackPublishFailed => 'Stiva nu a putut fi publicată';

  @override
  String get stackPublished => 'Stiva a fost publicată ca ciorne';

  @override
  String get stackOpenPullRequest => 'Deschide pull request';

  @override
  String get stackSection => 'Stivă';

  @override
  String get mergeConflictsButton => 'Conflicte';

  @override
  String mergeConflictsFileCount(int count, String base) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de fișiere sunt în conflict cu $base',
      few: '$count fișiere sunt în conflict cu $base',
      one: '1 fișier este în conflict cu $base',
    );
    return '$_temp0';
  }

  @override
  String get mergeConflictsLoading => 'Se caută fișierele în conflict…';

  @override
  String get mergeConflictsLoadFailed =>
      'Fișierele în conflict nu au putut fi listate';

  @override
  String get mergeConflictsNoneFound =>
      'Nu s-au găsit fișiere în conflict. Este posibil ca GitHub să actualizeze încă acest pull request.';

  @override
  String get askAiToFixConflicts => 'Cere AI-ului să rezolve conflictele';

  @override
  String get fixConflictsStarted =>
      'Un agent rezolvă conflictele în chatul acestui pull request';

  @override
  String failedToStartConflictFix(String error) {
    return 'Rezolvarea conflictelor nu a putut porni: $error';
  }

  @override
  String get settingsLinks => 'Linkuri';

  @override
  String get linksSettingsDescription =>
      'Alege unde se deschid linkurile venite din afara Control Center, de exemplu un pull request deschis din GitHub.';

  @override
  String get repoLinkRememberedTitle => 'Spații de lucru memorate';

  @override
  String get repoLinkRememberedHint =>
      'Când un depozit este asociat cu mai multe spații de lucru, deschiderea unui link către el te întreabă ce spațiu de lucru să folosești. Aici sunt listate alegerile pe care ai cerut să fie memorate.';

  @override
  String get repoLinkRememberedEmpty => 'Nicio alegere memorată încă.';

  @override
  String get repoLinkForget => 'Uită';

  @override
  String get repoLinkWorkspaceUnavailable =>
      'Spațiul de lucru nu mai este disponibil';

  @override
  String get repoLinkWorkspaceDialogTitle => 'Alege un spațiu de lucru';

  @override
  String repoLinkWorkspaceDialogBody(String repo) {
    return '$repo este asociat cu mai multe spații de lucru. În care să se deschidă acest link?';
  }

  @override
  String get repoLinkWorkspaceRemember =>
      'Memorează alegerea mea pentru acest depozit';

  @override
  String get repoLinkWorkspaceOpen => 'Deschide';

  @override
  String get repoLinkUnlinkedTitle =>
      'Adaugă depozitul într-un spațiu de lucru';

  @override
  String repoLinkUnlinkedBody(String repo) {
    return 'Niciun spațiu de lucru nu este asociat încă cu $repo. Adaugă-l într-unul pentru a deschide acest link.';
  }

  @override
  String repoLinkUnlinkedAddTo(String workspace) {
    return 'Adaugă în $workspace';
  }

  @override
  String get repoLinkUnlinkedAddToHint => 'Alege checkout-ul său de pe server.';

  @override
  String get repoLinkUnlinkedCreate => 'Spațiu de lucru nou';

  @override
  String get repoLinkUnlinkedCreateHint =>
      'Denumește-l, apoi alege checkout-ul.';

  @override
  String repoLinkChooseCheckout(String repo) {
    return 'Selectează checkout-ul pentru $repo de pe mașina care rulează serverul.';
  }

  @override
  String repoLinkCheckoutMismatch(String repo) {
    return 'Niciunul dintre depozitele adăugate nu este $repo, așa că linkul s-a deschis fără el.';
  }

  @override
  String get windowMinimize => 'Minimizare';

  @override
  String get windowMaximize => 'Maximizare';

  @override
  String get windowRestore => 'Restabilire';

  @override
  String nativeSandboxUnsupported(String platform) {
    return 'Sandbox-ul nativ nu este încă acceptat pe $platform.';
  }

  @override
  String get continueWithoutSandbox => 'Continuă fără sandbox';

  @override
  String get sandboxCheckAgain => 'Verifică din nou';

  @override
  String get ideQuickOpen => 'Accesează fișierul';

  @override
  String get ideQuickOpenHint => 'Caută fișiere după nume';

  @override
  String get ideQuickOpenRecentlyOpened => 'Deschis recent';

  @override
  String get ideQuickOpenOpenToSide => 'Deschide în lateral';

  @override
  String get ideQuickOpenRemoveRecent => 'Elimină din deschise recent';

  @override
  String get ideQuickOpenNoRecent => 'Niciun fișier deschis recent';

  @override
  String get diffMarkFileViewed => 'Marchează ca văzut';

  @override
  String get diffMarkFileNotViewed => 'Marchează ca nevăzut';

  @override
  String diffAdditionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de adăugări',
      few: '$count adăugări',
      one: '1 adăugare',
    );
    return '$_temp0';
  }

  @override
  String diffDeletionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de ștergeri',
      few: '$count ștergeri',
      one: '1 ștergere',
    );
    return '$_temp0';
  }

  @override
  String diffFileSemantics(
    String path,
    String status,
    String additions,
    String deletions,
  ) {
    return '$path, $status, $additions, $deletions';
  }

  @override
  String diffFileSemanticsViewed(
    String path,
    String status,
    String additions,
    String deletions,
  ) {
    return '$path, $status, $additions, $deletions, văzut';
  }

  @override
  String diffFileRenamedFrom(String previous) {
    return 'redenumit din $previous';
  }

  @override
  String diffTreeFolderSemantics(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de fișiere',
      few: '$count fișiere',
      one: '1 fișier',
    );
    return '$name, dosar, $_temp0';
  }

  @override
  String diffTreeFileSemantics(String name, String status) {
    return '$name, $status';
  }

  @override
  String diffTreeFileSemanticsViewed(String name, String status) {
    return '$name, $status, văzut';
  }

  @override
  String diffLineAdded(int line, String code) {
    return 'Linie adăugată $line: $code';
  }

  @override
  String diffLineRemoved(int line, String code) {
    return 'Linie eliminată $line: $code';
  }

  @override
  String diffLineContext(int line, String code) {
    return 'Linia $line: $code';
  }

  @override
  String diffLineHunk(String header) {
    return 'Secțiune $header';
  }

  @override
  String get diffLineBlank => 'goală';

  @override
  String get diffCommentOnLineAction => 'Comentează această linie';

  @override
  String diffFileMarkedViewedAnnouncement(String path) {
    return '$path marcat ca văzut';
  }

  @override
  String diffFileMarkedNotViewedAnnouncement(String path) {
    return '$path marcat ca nevăzut';
  }

  @override
  String prLineChangesSemantics(int additions, int deletions) {
    return 'Linii adăugate: $additions, linii eliminate: $deletions';
  }

  @override
  String closeTabNamed(String tab) {
    return 'Închide $tab';
  }

  @override
  String get notificationAgentAwaitingInput => 'Un agent necesită atenție';

  @override
  String get notifyAgentAwaitingInput =>
      'Când un agent are nevoie de aprobare, un răspuns sau credențiale valide, ori o politică blochează o acțiune';

  @override
  String notificationAgentNeedsApproval(String agent) {
    return '$agent are nevoie de aprobarea ta';
  }

  @override
  String get notificationAgentNeedsApprovalUnnamed =>
      'Un agent are nevoie de aprobarea ta';

  @override
  String notificationAgentAskedQuestion(String agent) {
    return '$agent are o întrebare';
  }

  @override
  String get notificationAgentAskedQuestionUnnamed =>
      'Un agent are o întrebare';

  @override
  String notificationAgentBlockedOnCredential(String agent) {
    return '$agent este blocat de credențiale';
  }

  @override
  String get notificationAgentBlockedOnCredentialUnnamed =>
      'Un agent este blocat de credențiale';

  @override
  String notificationWaitReminder(String title) {
    return 'Încă așteaptă: $title';
  }

  @override
  String get killTerminal => 'Închide terminalul';

  @override
  String get stopAgentCommand => 'Oprește comanda';

  @override
  String get agentCommandStopping => 'Se oprește…';

  @override
  String sidebarAgeSeconds(int count) {
    return '$count s';
  }

  @override
  String agentCommandSemantics(String command, String elapsed) {
    return 'Comanda agentului $command, rulează de $elapsed';
  }

  @override
  String get serverLostTitle => 'Conexiunea cu serverul s-a pierdut';

  @override
  String get serverLostBody =>
      'Control Center continuă să încerce reconectarea în fundal. Încercați din nou acum sau accesați ecranul de autentificare pentru a alege un server.';

  @override
  String get serverLostRetrying => 'Se reconectează…';

  @override
  String serverLostNextAttempt(int seconds) {
    return 'Următoarea încercare în $seconds s';
  }

  @override
  String get serverLostReconnect => 'Încercați reconectarea';

  @override
  String get serverLostSignIn => 'Mergeți la autentificare';

  @override
  String get serverEndedTitle => 'Nu se poate realiza reconectarea la server';

  @override
  String get shutdownSubtitleServer => 'Serverul se oprește';

  @override
  String get skillEvalAbsent => 'Absent vs disponibil';

  @override
  String get skillEvalAmbient => 'Abilități disponibile implicit';

  @override
  String skillEvalArtifactRef(String reference) {
    return 'Referință artefact: $reference';
  }

  @override
  String skillEvalAttempt(String task, String arm, int repeat) {
    final intl.NumberFormat repeatNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String repeatString = repeatNumberFormat.format(repeat);

    return '$task · $arm · repetarea $repeatString';
  }

  @override
  String get skillEvalAttempts => 'Încercări';

  @override
  String get skillEvalAvailableEvent => 'Disponibil';

  @override
  String get skillEvalBaseline => 'Hash-ul reviziei anterioare';

  @override
  String get skillEvalBodyLoad => 'Conținut încărcat';

  @override
  String get skillEvalBudgetCents => 'Buget (cenți SUA)';

  @override
  String get skillEvalBudgetNote =>
      'Evaluarea plătită folosește furnizorul și bugetul selectate. Rezultatele scanării de securitate sunt separate.';

  @override
  String get skillEvalUsageBudgetNote =>
      'Bugetele abonamentelor urmăresc utilizarea la tarife API echivalente, nu facturile. Un apel în curs poate depăși bugetul; după atingerea limitei nu mai pornesc alte apeluri. Scanările de securitate sunt separate.';

  @override
  String get skillEvalCancel => 'Anulează rularea';

  @override
  String get skillEvalCancelled => 'Anulată';

  @override
  String get skillEvalCancelling => 'Se anulează';

  @override
  String get skillEvalComparison => 'Comparație';

  @override
  String get skillEvalCompleted => 'Finalizată';

  @override
  String get skillEvalComposition => 'Componență';

  @override
  String get skillEvalCorpus => 'Set de sarcini';

  @override
  String skillEvalCoverage(String corpus, int repeats) {
    final intl.NumberFormat repeatsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String repeatsString = repeatsNumberFormat.format(repeats);

    return '$corpus · $repeatsString repetări';
  }

  @override
  String get skillEvalCoverageComplete =>
      'Toate testele planificate au fost observate';

  @override
  String skillEvalCurrentHash(String hash) {
    return 'Hash-ul pachetului curent: $hash';
  }

  @override
  String get skillEvalDisableUpdates =>
      'Dezactivează evaluările la actualizare';

  @override
  String get skillEvalEnableUpdates => 'Activează evaluările la actualizare';

  @override
  String get skillEvalExport => 'Copiază JSON-ul cu date mascate';

  @override
  String get skillEvalFailed => 'Eșuată';

  @override
  String get skillEvalForced => 'Încărcare forțată vs absent';

  @override
  String get skillEvalForcedEvent => 'Încărcare forțată';

  @override
  String get skillEvalHashLabel => 'Hash-ul pachetului';

  @override
  String get skillEvalProgressLabel => 'Progres';

  @override
  String get skillEvalUpdatesToggle => 'Evaluări la actualizare';

  @override
  String get skillEvalHashUnavailable =>
      'Hash-ul pachetului nu este disponibil pe acest server. Evaluarea este dezactivată.';

  @override
  String get skillEvalHistory => 'Istoricul reviziilor';

  @override
  String get skillEvalImproved => 'Îmbunătățită';

  @override
  String get skillEvalIncomplete => 'Incompletă';

  @override
  String get skillEvalInconclusive => 'Nicio decizie (dovezi insuficiente)';

  @override
  String get skillEvalInferred => 'Dedusă';

  @override
  String get skillEvalInterrupted => 'Întreruptă';

  @override
  String get skillEvalLoadUnobserved =>
      'Încărcarea abilității nu poate fi observată; lipsa unui eveniment nu dovedește că a fost ignorată.';

  @override
  String get skillEvalModel => 'Model selectat';

  @override
  String get skillEvalNoAttempts => 'Nicio încercare deocamdată.';

  @override
  String get skillEvalNoModels =>
      'Nu există modele conectate. Conectează mai întâi un furnizor în Setări.';

  @override
  String get skillEvalNoPrevious =>
      'Nu există un hash anterior în istoricul campaniei. Evaluează revizia anterioară înainte de a o înlocui.';

  @override
  String get skillEvalNoReport =>
      'Nu există încă un raport; încercările parțiale rămân disponibile.';

  @override
  String get skillEvalNoWorkspace => 'Niciun spațiu de lucru selectat.';

  @override
  String get skillEvalNoTasks => 'Nicio sarcină raportată deocamdată.';

  @override
  String get skillEvalNoVerifiers =>
      'Nu au fost înregistrate dovezi de verificare.';

  @override
  String get skillEvalNotEvaluated =>
      'Nu a fost evaluată pentru acești octeți exacți. O scanare nu este o dovadă a comportamentului.';

  @override
  String get skillEvalNotVerified => 'Neverificată';

  @override
  String get skillEvalObserved => 'Observată';

  @override
  String get skillEvalOpenQuality => 'Deschide Quality';

  @override
  String get skillEvalPolicyNote =>
      'În mod implicit, salvarea unei abilități nu pornește o evaluare plătită. Dacă activezi explicit reevaluarea automată la actualizare, salvarea pornește o reevaluare plătită în limita bugetului stabilit.';

  @override
  String get skillEvalPolicyNeedsCampaign =>
      'Evaluează mai întâi o revizie pentru a configura politica de actualizare.';

  @override
  String get skillEvalPolicyTemplate => 'Configurarea politicii de actualizare';

  @override
  String get skillEvalPartial =>
      'Dovezi parțiale; fără verdict privind adoptarea';

  @override
  String skillEvalProgress(int completed, int planned) {
    final intl.NumberFormat completedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String completedString = completedNumberFormat.format(completed);
    final intl.NumberFormat plannedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String plannedString = plannedNumberFormat.format(planned);

    return '$completedString din $plannedString încercări';
  }

  @override
  String skillEvalProvider(String provider) {
    return 'Furnizor: $provider';
  }

  @override
  String get skillEvalQualityIntro =>
      'Campanii pentru abilitățile din spațiul de lucru și dovezi specifice fiecărei revizii.';

  @override
  String get skillEvalQueued => 'În așteptare';

  @override
  String get skillEvalReconnecting =>
      'Se reconectează la instantaneele campaniei…';

  @override
  String get skillEvalRefresh => 'Reîmprospătează';

  @override
  String get skillEvalReferenceLoad => 'Referință încărcată';

  @override
  String get skillEvalRepetitions => 'Repetări per sarcină';

  @override
  String get skillEvalReport => 'Raport de dovezi';

  @override
  String get skillEvalRunning => 'În curs';

  @override
  String get skillEvalScriptExecution => 'Script executat';

  @override
  String skillEvalSpend(String spent, String budget) {
    return 'Cheltuit: $spent / buget $budget';
  }

  @override
  String get skillEvalStart => 'Pornește evaluarea';

  @override
  String get skillEvalStartTitle => 'Compară reviziile abilității';

  @override
  String get skillEvalStale => 'Învechită';

  @override
  String skillEvalStaleReason(String reason) {
    return 'Învechită: $reason';
  }

  @override
  String skillEvalTaskClusters(String count) {
    return 'Grupuri distincte de sarcini: $count';
  }

  @override
  String skillEvalTaskEvidence(String rate, String passes, String cost) {
    return '$rate ($passes verificate) · $cost';
  }

  @override
  String get skillEvalTasks => 'Sarcini pe grup';

  @override
  String get skillEvalToolError => 'Eroare de instrument';

  @override
  String get skillEvalTools => 'Evenimente ale instrumentelor';

  @override
  String get skillEvalTitle => 'Evaluarea abilității';

  @override
  String skillEvalUnavailable(String reason) {
    return 'Indisponibilă: $reason';
  }

  @override
  String get skillEvalUnknown => 'Necunoscută';

  @override
  String get skillEvalUnsaved =>
      'Modificările nesalvate nu sunt incluse. Salvează înainte de evaluare.';

  @override
  String get skillEvalUncertainty => 'Interval de incertitudine';

  @override
  String get skillEvalVerified => 'Verificată';

  @override
  String get skillEvalVerifiers => 'Verificare';

  @override
  String get skillEvalVerdict => 'Verdict';

  @override
  String skillEvalExportCopied(String filename) {
    return 'Copiere finalizată: $filename';
  }

  @override
  String get skillEvalPlanViolation => 'Încălcare a planului';

  @override
  String get skillEvalPreserved => 'Calitate menținută';

  @override
  String get skillEvalPrevious => 'Anterior vs curent';

  @override
  String get skillEvalRegressed => 'Regresie demonstrată';

  @override
  String get skillEvalCostRegression => 'Regresia costurilor';

  @override
  String get skillEvalHarnessError => 'Eroare a cadrului de testare';

  @override
  String get skillBehaviorRouting => 'Rutarea abilității';

  @override
  String skillBehaviorRoutingCounts(
    String truePositive,
    String falsePositive,
    String falseNegative,
    String trueNegative,
  ) {
    return '$truePositive utilizări așteptate · $falsePositive utilizări neașteptate · $falseNegative utilizări ratate · $trueNegative omisiuni corecte';
  }

  @override
  String skillBehaviorUnknownCounts(
    String positive,
    String negative,
    String notOffered,
  ) {
    return '$positive utilizări incerte · $negative omisiuni incerte · $notOffered neoferite';
  }

  @override
  String skillBehaviorRoutingRates(
    String precision,
    String recall,
    String falsePositiveRate,
  ) {
    return 'Precizie observată $precision · rată de recuperare $recall · rată de fals pozitive $falsePositiveRate';
  }

  @override
  String get skillBehaviorForced => 'Braț forțat · doar diagnostic';

  @override
  String get skillBehaviorRoutingNote =>
      'Ratele includ doar accesările observabile. Accesul prin shell sau căutare poate rămâne necunoscut; încărcarea unei abilități nu dovedește aplicarea ei.';

  @override
  String get skillBehaviorSafety => 'Siguranță sintetică';

  @override
  String skillBehaviorSafetyCounts(
    String passes,
    String attempts,
    String denials,
    String violations,
  ) {
    return '$passes/$attempts verificări de artefact trecute · $denials refuzuri conform politicii · $violations încălcări ale fișierelor protejate';
  }

  @override
  String get skillBehaviorSafetyNote =>
      'Verificările artefactelor sunt sintetice și nu reflectă ratele atacurilor din lumea reală; efectele secundare reale nu sunt monitorizate.';

  @override
  String get skillBehaviorUtility => 'Utilitate după familie';

  @override
  String skillBehaviorUtilityCounts(String verified, String attempts) {
    return '$verified/$attempts reușite verificate';
  }

  @override
  String get skillBehaviorUtilityNote =>
      'Toate încercările intră în numitorul utilității, inclusiv cele eșuate și incomplete.';

  @override
  String get claudeAccountSignInFailed => 'Autentificarea a eșuat';

  @override
  String get claudeSignInDialogTitle => 'Conectează-te la Claude Code';

  @override
  String get claudeSignInDialogHint =>
      'Rulează fiecare comandă într-un terminal pe server. Deschide un browser pentru a finaliza autentificarea și scrie datele de acces în directorul acelui cont.';

  @override
  String get claudeSignInNoAccounts =>
      'Niciun cont gestionat nu este deconectat. Dacă acest agent folosește autentificarea proprie Claude Code, rulează:';

  @override
  String get claudeSignInCommandUnavailable =>
      'Serverul nu a putut furniza o comandă de autentificare pentru acest cont.';

  @override
  String get claudeAccountSignedIn => 'Autentificat';

  @override
  String get claudeSignInClosesItself =>
      'Această fereastră se închide automat după finalizarea autentificării.';

  @override
  String get claudeSignInClosesItselfAll =>
      'Această fereastră se închide automat după ce toate conturile sunt autentificate.';

  @override
  String get transcriptClaudeSignInExpiredTitle =>
      'Autentificarea Claude Code a expirat';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      'Rularea s-a oprit deoarece contul ei nu se mai autentifică. Conectează-te din nou, apoi reîncearcă tura.';

  @override
  String get transcriptSignInExpiredTitle =>
      'Autentificarea furnizorului a expirat';

  @override
  String get transcriptSignInExpiredBody =>
      'Rularea s-a oprit deoarece datele de acces ale furnizorului nu mai funcționează. Reconectează-l în Setări → Furnizori, apoi reîncearcă tura.';

  @override
  String get helpMenuLabel => 'Ajutor';

  @override
  String get helpWhatsNew => 'Noutăți';

  @override
  String get helpReportProblem => 'Raportează o problemă';

  @override
  String get helpCreateGitHubIssue => 'Creează un issue pe GitHub';

  @override
  String get changelogInstalled => 'Instalată';

  @override
  String get changelogGroupNew => 'Nou';

  @override
  String get changelogGroupImproved => 'Îmbunătățit';

  @override
  String get changelogGroupFixed => 'Remediat';

  @override
  String get changelogLoadFailed =>
      'Notele de lansare nu au putut fi încărcate.';

  @override
  String get changelogOpenWebsite => 'Deschide pe site';

  @override
  String get connectWelcomeTitle => 'Bun venit în Control Center';

  @override
  String get connectWelcomeSubtitle =>
      'Rulează-l aici sau conectează-te la un server pe care îl ai deja.';

  @override
  String get connectWelcomeSubtitleWeb =>
      'Conectează-te la serverul tău pentru a începe.';

  @override
  String get connectToServer => 'Conectează-te la un server';

  @override
  String get connectToServerIntro =>
      'Introdu adresa unui server Control Center.';

  @override
  String get connectUsePairingKey => 'Folosește o cheie de asociere';

  @override
  String get connectPasteLink => 'Lipește un link de asociere';

  @override
  String get connectPasteLinkIntro =>
      'Lipește linkul de invitație sau de asociere pe care l-ai primit.';

  @override
  String get connectPasteLinkLabel => 'Link de invitație sau de asociere';

  @override
  String get connectPasteLinkInvalid =>
      'Acesta nu este un link de invitație sau de asociere Control Center. Copiază linkul întreg și încearcă din nou.';

  @override
  String get connectPasteLinkTarget => 'Se conectează la';

  @override
  String get focusModeEnd => 'Încheie sesiunea de concentrare';

  @override
  String focusModeRemaining(int minutes) {
    return 'Au mai rămas $minutes min';
  }

  @override
  String get demoUnavailableEnvironments =>
      'Mediile rulează procese reale pe gazdă, așa că demo-ul nu are niciunul.';

  @override
  String get environmentChecksFailing => 'Unele verificări eșuează pe server';

  @override
  String environmentCliEndpoints(String names) {
    return 'Puncte finale: $names';
  }

  @override
  String environmentCliServices(String names) {
    return 'Servicii: $names';
  }

  @override
  String get environmentCopied => 'Copiat';

  @override
  String get environmentCopyCommand => 'Copiază comanda';

  @override
  String get environmentCopyUrl => 'Copiază URL-ul';

  @override
  String get environmentDefinition => 'Definiție';

  @override
  String environmentDefinitionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de definiții',
      few: '$count definiții',
      one: '1 definiție',
    );
    return '$_temp0';
  }

  @override
  String get environmentDestroy => 'Distruge';

  @override
  String environmentDestroyBody(String name) {
    return '$name și datele sale sunt eliminate. Pornirea creează unul nou.';
  }

  @override
  String get environmentDestroyTitle => 'Distrugi acest mediu?';

  @override
  String get environmentExec => 'Exec';

  @override
  String get environmentExecTitle => 'Rulează într-un serviciu';

  @override
  String environmentExitCode(int code) {
    return 'Cod de ieșire $code';
  }

  @override
  String get environmentInputNeeded =>
      'Acest lucru trebuie configurat pe server';

  @override
  String get environmentKindApp => 'Aplicație';

  @override
  String get environmentKindCli => 'CLI';

  @override
  String get environmentKindCompose => 'Compose';

  @override
  String get environmentKindProcess => 'Proces';

  @override
  String get environmentKindTask => 'Sarcină';

  @override
  String get environmentLaunch => 'Lansează';

  @override
  String get environmentLogsGone => 'Aceste jurnale nu mai sunt disponibile.';

  @override
  String environmentLogsTab(String name) {
    return 'Jurnale: $name';
  }

  @override
  String get environmentLogsWaiting => 'Se așteaptă ieșirea';

  @override
  String get environmentMoreActions => 'Mai multe acțiuni pentru mediu';

  @override
  String get environmentNeedsRecreate =>
      'O modificare impune recrearea acestui mediu.';

  @override
  String get environmentNoStack =>
      'Rulează doar sarcini de worktree, deci nu este nimic de pornit.';

  @override
  String get environmentOnTheServer => 'Pe server';

  @override
  String get environmentOpenInBrowserVm => 'Deschide în Browser (VM)';

  @override
  String get environmentOpenViewer => 'Deschide vizualizatorul';

  @override
  String get environmentPlacementRig => 'Într-o VM';

  @override
  String get environmentPreviewTab => 'Mediu';

  @override
  String get environmentRebuildRelaunch => 'Recompilează și relansează';

  @override
  String get environmentRecreate => 'Recreează';

  @override
  String environmentRecreateBody(String name) {
    return '$name este distrus și repornit cu aceleași opțiuni. Datele sale se pierd.';
  }

  @override
  String get environmentRecreateTitle => 'Recreezi acest mediu?';

  @override
  String environmentResetBody(String name) {
    return '$name revine la starea de bază. Datele create între timp se pierd.';
  }

  @override
  String get environmentResetData => 'Resetează datele';

  @override
  String get environmentResetTitle => 'Resetezi datele?';

  @override
  String get environmentRestart => 'Repornește';

  @override
  String environmentRestarts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de reporniri',
      few: '$count reporniri',
      one: '1 repornire',
    );
    return '$_temp0';
  }

  @override
  String get environmentRun => 'Rulează';

  @override
  String get environmentRunInTerminal => 'Rulează în terminal';

  @override
  String get environmentSectionTitle => 'Mediu';

  @override
  String get environmentService => 'Serviciu';

  @override
  String environmentServiceActions(String name) {
    return 'Acțiuni pentru $name';
  }

  @override
  String get environmentStartTitle => 'Pornește mediul';

  @override
  String get environmentStateCrashed => 'Blocat';

  @override
  String get environmentStatusDegraded => 'Degradat';

  @override
  String get environmentStatusDestroying => 'Se distruge';

  @override
  String get environmentStatusGone => 'Dispărut';

  @override
  String get environmentStatusStopping => 'Se oprește';

  @override
  String environmentStopDataLoss(String name) {
    return 'Oprirea $name îi pierde datele, iar Pornirea nu le aduce înapoi.';
  }

  @override
  String get environmentStopLoseData => 'Oprește și pierde datele';

  @override
  String get environmentStopTitle => 'Oprești acest mediu?';

  @override
  String get environmentTaskNeverRun => 'Încă nerulată';

  @override
  String get environmentsAddCheck => 'Adaugă verificare';

  @override
  String get environmentsAddOption => 'Adaugă opțiune';

  @override
  String get environmentsAddRole => 'Adaugă rol';

  @override
  String get environmentsAdminOnly =>
      'Doar administratorii spațiului de lucru pot modifica definițiile.';

  @override
  String get environmentsAfter => 'Așteaptă aceste componente';

  @override
  String get environmentsAnchor => 'Ancoră';

  @override
  String get environmentsAutoCreate => 'Pornește automat';

  @override
  String get environmentsAutoCreateAll => 'În fiecare spațiu eligibil';

  @override
  String get environmentsAutoCreateOff => 'Niciodată';

  @override
  String get environmentsAutoCreatePrs => 'În spațiile de pull request';

  @override
  String get environmentsBlank => 'Definiție goală';

  @override
  String get environmentsCheckFix => 'Comandă de remediere';

  @override
  String get environmentsCheckHint => 'Indiciu';

  @override
  String get environmentsCommandHelp =>
      'Argumentele sunt separate prin spații. Pune între ghilimele argumentul care conține un spațiu.';

  @override
  String environmentsComponentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de componente',
      few: '$count componente',
      one: '1 componentă',
    );
    return '$_temp0';
  }

  @override
  String get environmentsComponentId => 'ID';

  @override
  String get environmentsComposeBuild => 'Construiește imaginile la pornire';

  @override
  String get environmentsComposeFile => 'Fișier compose';

  @override
  String get environmentsComposeHttp => 'HTTP';

  @override
  String get environmentsComposeNoFile =>
      'Nu s-a putut citi un fișier compose. Numele serviciilor pot fi totuși trecute în vizualizarea JSON.';

  @override
  String get environmentsComposeServices => 'Servicii';

  @override
  String get environmentsComposeServicesHint =>
      'Lasă toate serviciile nebifate pentru a le rula pe toate.';

  @override
  String get environmentsConditionalArgs =>
      'Această comandă are argumente condiționale. Editeaz-o în vizualizarea JSON.';

  @override
  String get environmentsCwdPath => 'Cale de lucru';

  @override
  String get environmentsCwdRole => 'Rol de lucru';

  @override
  String get environmentsDeleteBody =>
      'Spațiile nu îl mai pot porni. Mediile în execuție continuă până sunt oprite.';

  @override
  String environmentsDeleteTitle(String name) {
    return 'Ștergi $name?';
  }

  @override
  String get environmentsDescription =>
      'Ce poate porni fiecare spațiu și ce sarcini rulează worktree-urile sale.';

  @override
  String get environmentsDraftFromRepo => 'Schiță din repo';

  @override
  String get environmentsEmpty => 'Încă nu există definiții';

  @override
  String get environmentsEnabledWhen => 'Activat când';

  @override
  String get environmentsEndpointRole => 'Rolul punctului final';

  @override
  String get environmentsFollowPrHead => 'Urmărește head-ul pull request-ului';

  @override
  String get environmentsForkApproval =>
      'Fiecare pornire necesită un administrator';

  @override
  String get environmentsForkDeny => 'Refuzat';

  @override
  String get environmentsForkPrs => 'Pull request-uri din fork-uri';

  @override
  String get environmentsForkRig => 'Rulează într-o VM';

  @override
  String get environmentsIdleStop => 'Oprește după minute de inactivitate';

  @override
  String get environmentsIsolateHome => 'Dă aplicației un home privat';

  @override
  String get environmentsIssues => 'Corectează acestea înainte de salvare';

  @override
  String environmentsJsonInvalid(String error) {
    return 'JSON nevalid: $error';
  }

  @override
  String get environmentsKeepsData => 'Își păstrează datele la oprire';

  @override
  String get environmentsLinkConfirm => 'Leagă și aprobă';

  @override
  String get environmentsLinkFile => 'Leagă un fișier din repo';

  @override
  String get environmentsLinkHelp =>
      'Citit doar din ramura implicită și rulat doar după aprobare.';

  @override
  String get environmentsLinkPath => 'Cale';

  @override
  String get environmentsMaxRunning => 'Rulează simultan';

  @override
  String get environmentsNamingProject => 'Proiect';

  @override
  String get environmentsNamingTemplate => 'Șablon de nume';

  @override
  String get environmentsNew => 'Definiție nouă';

  @override
  String get environmentsNewDefinitionName => 'Mediu nou';

  @override
  String get environmentsNoChecks => 'Această definiție nu are verificări.';

  @override
  String get environmentsNoRuns => 'Încă nu există rulări de test';

  @override
  String get environmentsOnChange => 'Căi de urmărit';

  @override
  String get environmentsOptionBool => 'Da sau nu';

  @override
  String get environmentsOptionEnum => 'Unul dintre';

  @override
  String get environmentsOptionMulti => 'Mai multe dintre';

  @override
  String get environmentsOptionValues => 'Valori';

  @override
  String get environmentsPlacement => 'Amplasare';

  @override
  String get environmentsPlacementHost => 'Pe gazdă';

  @override
  String get environmentsPlacementRig => 'Într-o VM';

  @override
  String get environmentsPrepareTask => 'Sarcină de pregătire';

  @override
  String get environmentsPrimaryEndpoint => 'Punct final principal';

  @override
  String get environmentsReadyHttp => 'Gata când răspunde acest URL';

  @override
  String get environmentsRestartAlways => 'Întotdeauna';

  @override
  String get environmentsRestartNever => 'Niciodată';

  @override
  String get environmentsRestartOn => 'Repornește când se schimbă aceste căi';

  @override
  String get environmentsRestartOnFailure => 'La eșec';

  @override
  String get environmentsRestartPolicy => 'Repornește';

  @override
  String get environmentsRigTtl => 'Durata de viață a VM în ore';

  @override
  String get environmentsRunChecks => 'Rulează din nou';

  @override
  String get environmentsRunTest => 'Rulează testul';

  @override
  String get environmentsSaved => 'Definiție salvată';

  @override
  String get environmentsSectionComponents => 'Componente';

  @override
  String get environmentsSectionOptions => 'Opțiuni de pornire';

  @override
  String get environmentsSectionSeedFiles => 'Fișiere inițiale';

  @override
  String get environmentsSectionVariables => 'Variabile';

  @override
  String get environmentsSeedHelp =>
      'O cale pe linie, copiată din checkout-ul înregistrat. Pull request-urile din fork-uri nu le primesc niciodată.';

  @override
  String get environmentsShellHelp =>
      'Substituenții nu sunt extinși aici. Citește în schimb variabilele CC_ENV_*.';

  @override
  String get environmentsSourceApprove => 'Aprobă această versiune';

  @override
  String environmentsSourceCurrent(String path) {
    return '$path corespunde versiunii aprobate.';
  }

  @override
  String get environmentsSourceNotice =>
      'Versiunea aprobată rulează în continuare până o aprobi pe aceasta.';

  @override
  String get environmentsTabJson => 'JSON';

  @override
  String get environmentsTabSource => 'Sursă';

  @override
  String get environmentsTestHelp =>
      'Rulează un mediu de unică folosință cap-coadă: verifică, pornește, așteaptă să fie gata, distruge.';

  @override
  String get environmentsTestSaveFirst => 'Salvează mai întâi definiția.';

  @override
  String get environmentsTimeoutSeconds => 'Timp limită în secunde';

  @override
  String get environmentsTitle => 'Medii';

  @override
  String get environmentsTriggerArchive => 'Înainte de ștergerea worktree-ului';

  @override
  String get environmentsTriggerChange => 'Când se schimbă căile urmărite';

  @override
  String get environmentsTriggerCreate => 'O dată pe mediu';

  @override
  String get environmentsTriggerManual => 'La cerere';

  @override
  String get environmentsTriggerProvision => 'La crearea worktree-ului';

  @override
  String get environmentsTriggerStart => 'La fiecare pornire';

  @override
  String get environmentsTriggers => 'Rulează';

  @override
  String get environmentsUnreadable =>
      'Acest client nu poate citi această definiție.';

  @override
  String get environmentsUpdateAvailable => 'Actualizare disponibilă';

  @override
  String get environmentsUseShell => 'Folosește o comandă shell';

  @override
  String get environmentsUseSourceWarning =>
      'Instrumentul rulează atunci pe propriul tău checkout. Tratează-l ca doar în citire.';

  @override
  String get environmentsWhenMissing => 'Când unui spațiu îi lipsește';

  @override
  String get environmentsWhenMissingAdd => 'Adaugă-l în spațiu';

  @override
  String get environmentsWhenMissingSkip => 'Omite-l';

  @override
  String get environmentsWhenMissingSource =>
      'Folosește checkout-ul înregistrat';

  @override
  String get environmentsUnsupported => 'Acest server nu acceptă medii.';

  @override
  String get environmentViewerUnavailable =>
      'Fără vizualizator: serverul nu poate captura această fereastră. Permite înregistrarea ecranului pentru Control Center pe server.';

  @override
  String get environmentHealthHealthy => 'Sănătos';

  @override
  String get environmentHealthUnhealthy => 'Nesănătos';

  @override
  String get environmentTerminalStale =>
      'Acest terminal a fost deschis înainte de pornirea mediului, deci nu are variabilele lui.';

  @override
  String get environmentTerminalFresh => 'Deschide un terminal nou';

  @override
  String get environmentsShellStays =>
      'Un script pe mai multe linii rămâne o comandă shell: liniile sunt structura lui.';

  @override
  String get environmentsOverrides => 'Suprascrieri ale spațiului de lucru';

  @override
  String get environmentsOverridesHelp =>
      'Setările proprii ale fișierului sunt doar în citire aici. Leagă rolurile lui de repo-urile acestui spațiu de lucru sau suprascrie orice câmp ca JSON.';

  @override
  String get environmentsReposHelp =>
      'Depozitele folosite de acest mediu, fiecare legat de un rol.';

  @override
  String get environmentsComponentsHelp =>
      'Ce rulează mediul, în ordinea pornirii.';

  @override
  String get environmentsOptionsHelp => 'Opțiuni oferite la pornirea mediului.';

  @override
  String get environmentsVariablesHelp =>
      'Setate pentru sarcini, procese, aplicații și terminalele spațiului.';

  @override
  String get environmentsChecksHelp =>
      'De ce are nevoie gazda pentru a rula acest mediu.';

  @override
  String get environmentsIdleStopHelp => '0 nu îl oprește niciodată.';

  @override
  String get environmentsAnchorHelp =>
      'Un spațiu care conține acest depozit poate porni mediul.';

  @override
  String get environmentsRequiredHelp => 'Mediul nu poate rula fără el.';

  @override
  String get environmentsFollowPrHeadHelp =>
      'Sincronizează și reîmprospătează când head-ul pull request-ului se mută.';

  @override
  String get environmentsRecordNeedsFix => 'Necesită corectare';

  @override
  String get environmentsCheckFile => 'Fișier';

  @override
  String get environmentsDiscardBody =>
      'Modificările tale la această definiție se vor pierde.';

  @override
  String get environmentsWorktreeRuns => 'Rulări ale sarcinilor de worktree';

  @override
  String get environmentsNoWorktreeRuns =>
      'Încă nu a rulat nicio sarcină de worktree.';

  @override
  String get environmentsLinkRoles => 'Roluri în acest fișier';

  @override
  String get environmentsLinkNoFile =>
      'Fișierul nu a putut fi citit din repo. Rolurile pot fi legate după conectare.';

  @override
  String get guardrailClassHostExecution => 'Rulează comenzi pe gazdă';

  @override
  String get environmentUrls => 'URL-uri';

  @override
  String get environmentScripts => 'Scripturi';

  @override
  String get environmentNoneForSpace => 'Niciun mediu pentru acest spațiu';

  @override
  String get environmentNoneForPr => 'Niciun mediu pentru acest pull request';

  @override
  String get environmentSetupBody =>
      'Un mediu rulează serviciile, scripturile și URL-urile unui depozit pentru un spațiu. Configurați-l o dată și orice spațiu al depozitului îl poate porni.';

  @override
  String get environmentSetUp => 'Configurează mediul';

  @override
  String get environmentEditDefinition => 'Editează definiția';

  @override
  String get environmentOpenPanel => 'Deschide mediul';

  @override
  String get environmentStatusBlocked => 'Necesită acțiune';

  @override
  String get environmentStateInTerminal => 'În terminal';

  @override
  String get environmentWaitingInTerminal =>
      'Așteaptă după tine într-un terminal';

  @override
  String get environmentOpenTerminal => 'Deschide terminalul';

  @override
  String get environmentSignInNeeded => 'Trebuie să te autentifici';

  @override
  String get environmentDependencyNeeded => 'Ceva necesar nu este disponibil';

  @override
  String get environmentStartTerminalDone => 'Gata aici. Mediul încă pornește';

  @override
  String get environmentContinueInTerminal => 'Continuă în terminal';

  @override
  String get environmentStartTerminalHint =>
      'Instrumentul are nevoie de tine într-un terminal pentru o parolă sau o întrebare. Pornirea continuă după aceea.';

  @override
  String get environmentStartTerminalReason =>
      'Acest terminal s-a deschis deoarece pornirea are nevoie de tine';

  @override
  String get environmentStartTerminalTab => 'Configurare mediu';

  @override
  String get environmentsNothingRunning =>
      'Nimic nu rulează din această definiție.';

  @override
  String get searchPoliciesHint => 'Caută politici...';

  @override
  String get noPoliciesMatch => 'Nicio politică nu corespunde căutării';

  @override
  String get memoryPolicyActive => 'Activă';

  @override
  String get memoryFactType => 'Tip';

  @override
  String get memoryTimesRecalled => 'Număr de reamintiri';

  @override
  String get memorySourceFacts => 'Fapte sursă';

  @override
  String get spaceSetupLogs => 'Jurnale de configurare';

  @override
  String get claudeCompactionTitle => 'Compactare';

  @override
  String get claudeCompactionDescription =>
      'Cum păstrează Claude Code conversațiile lungi în fereastra de context.';

  @override
  String get claudeAutoCompactLabel => 'Compactează automat după';

  @override
  String claudeAutoCompactHint(String min, String max) {
    return 'Tokenuri, de la $min la $max. Lasă gol pentru valoarea implicită din Claude Code.';
  }

  @override
  String claudeAutoCompactInvalid(String min, String max) {
    return 'Introdu un număr de la $min la $max.';
  }

  @override
  String get claudeIdleCompactLabel => 'Compactează conversațiile inactive';

  @override
  String claudeIdleCompactDescription(String threshold) {
    return 'Compactează o conversație de peste $threshold tokenuri chiar înainte să expire memoria cache a promptului, ca revenirea la ea să coste mai puțin. Fiecare compactare consumă din planul tău.';
  }

  @override
  String get claudeCompactionSaveFailed =>
      'Această setare nu a putut fi salvată.';

  @override
  String get navDesktopApp => 'Aplicație desktop';

  @override
  String get desktopAppSettingsSubtitle =>
      'Pictograma din tava de sistem, închiderea ferestrei și deschiderea la autentificare.';

  @override
  String get desktopSectionMenuBar => 'Bara de meniu';

  @override
  String get desktopSectionTray => 'Tava de sistem';

  @override
  String get desktopTrayTitleMac => 'Afișează în bara de meniu';

  @override
  String get desktopTrayTitle => 'Afișează în tava de sistem';

  @override
  String get desktopTraySubtitle =>
      'Starea, ce te așteaptă, spațiile tale și utilizarea abonamentului, la un clic distanță.';

  @override
  String get desktopTrayMissingTitle => 'Nu s-a găsit nicio tavă de sistem';

  @override
  String get desktopTrayMissingBody =>
      'Acest desktop nu afișează pictograme în tava de sistem. Pe GNOME, instalează extensia AppIndicator, apoi repornește Control Center.';

  @override
  String get desktopSectionClosing => 'Închiderea ferestrei';

  @override
  String get desktopCloseTitle => 'Când închizi fereastra';

  @override
  String get desktopCloseKeepRunning => 'Continuă rularea';

  @override
  String get desktopCloseQuit => 'Ieși';

  @override
  String get desktopCloseKeepRunningSubtitleMac =>
      'Agenții și notificările continuă. Redeschide fereastra din Dock sau din bara de meniu.';

  @override
  String get desktopCloseKeepRunningSubtitle =>
      'Agenții și notificările continuă. Redeschide fereastra de la pictograma din tava de sistem.';

  @override
  String get desktopCloseQuitSubtitle =>
      'Închiderea ferestrei oprește Control Center. Notificările se opresc până îl redeschizi.';

  @override
  String get desktopCloseNeedsTray =>
      'Activează pictograma din tava de sistem ca să păstrezi Control Center pornit cu fereastra închisă.';

  @override
  String get desktopSectionLogin => 'Pornire';

  @override
  String get desktopLoginTitle => 'Deschide la autentificare';

  @override
  String get desktopLoginSubtitle =>
      'Pornește Control Center când te autentifici, ca notificările să sosească de la început.';

  @override
  String get desktopLoginUnsupported =>
      'Acest sistem nu permite deschiderea aplicațiilor la autentificare.';

  @override
  String get desktopLoginNeedsApproval =>
      'Permite Control Center în Articole de autentificare ca să finalizezi activarea.';

  @override
  String get desktopLoginOpenLoginItems => 'Deschide Articole de autentificare';

  @override
  String get desktopLoginRefused =>
      'Sistemul nu a acceptat modificarea. Este posibil ca administratorul tău să o gestioneze.';

  @override
  String get desktopLoginStartHiddenTitle => 'Pornește în fundal';

  @override
  String get desktopLoginStartHiddenSubtitleMac =>
      'Se deschide fără fereastră la autentificare. Îl găsești în Dock sau în bara de meniu.';

  @override
  String get desktopLoginStartHiddenSubtitle =>
      'Se deschide fără fereastră la autentificare. Îl găsești în tava de sistem.';

  @override
  String get desktopLoginStartHiddenNeedsTray =>
      'Necesită pictograma din tava de sistem, ca să existe o cale de a deschide fereastra.';

  @override
  String get closeToTrayPromptTitle => 'Păstrezi Control Center pornit?';

  @override
  String get closeToTrayPromptBody =>
      'Cu fereastra închisă, agenții continuă să lucreze și notificările continuă să sosească. Redeschide-o de la pictograma din tava de sistem. Poți schimba asta în Setări → Aplicație desktop.';

  @override
  String get closeToTrayPromptQuit => 'Ieși';

  @override
  String get closeToTrayPromptKeepRunning => 'Continuă rularea';

  @override
  String get trayStatusOffline => 'Offline';

  @override
  String get trayStatusReconnecting => 'Se reconectează…';

  @override
  String trayStatusNeedsYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count te așteaptă',
      few: '$count te așteaptă',
      one: '1 te așteaptă',
    );
    return '$_temp0';
  }

  @override
  String trayStatusWorking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lucrează',
      few: '$count lucrează',
      one: '1 lucrează',
    );
    return '$_temp0';
  }

  @override
  String get trayStatusAllQuiet => 'Totul e liniștit';

  @override
  String trayTooltip(String status) {
    return 'Control Center · $status';
  }

  @override
  String trayMenuSpaceQuestions(String space, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de întrebări',
      few: '$count întrebări',
      one: '1 întrebare',
    );
    return '$space · $_temp0';
  }

  @override
  String trayApprovalsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de aprobări în așteptare',
      few: '$count aprobări în așteptare',
      one: '1 aprobare în așteptare',
    );
    return '$_temp0';
  }

  @override
  String get trayMenuOpen => 'Deschide Control Center';

  @override
  String get trayMenuSettings => 'Setări…';

  @override
  String get trayMenuQuit => 'Ieși din Control Center';

  @override
  String get trayPanelTitle => 'Control Center';

  @override
  String get trayPanelNoWorkspace =>
      'Deschide Control Center ca să alegi un spațiu de lucru.';

  @override
  String get trayPanelOpenApp => 'Deschide Control Center';

  @override
  String get trayPanelSettings => 'Setările aplicației desktop';

  @override
  String get trayPanelNeedsYou => 'Te așteaptă';

  @override
  String get trayPanelApprovals => 'Aprobări';

  @override
  String get trayPanelSpaces => 'Spații';

  @override
  String get trayPanelNoSpaces => 'Încă nu există spații.';

  @override
  String trayPanelAllSpaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Toate cele $count de spații',
      few: 'Toate cele $count spații',
      one: 'Toate spațiile',
    );
    return '$_temp0';
  }

  @override
  String get trayPanelUsage => 'Utilizare';

  @override
  String get trayPanelSwitchWorkspace => 'Schimbă spațiul de lucru';

  @override
  String signInToProvider(String provider) {
    return 'Autentifică-te în $provider';
  }

  @override
  String get linearConnectAutomation => 'Conectează Linear pentru automatizare';

  @override
  String signInOpeningBrowser(String provider) {
    return 'Se deschide $provider în browser…';
  }

  @override
  String get signInFailedTitle => 'Autentificarea nu s-a finalizat';

  @override
  String get signInReopenPage => 'Redeschide pagina de autentificare';

  @override
  String get signInCodePrompt =>
      'Confirmă în browser, apoi introdu codul afișat.';

  @override
  String get signInCodeMalformed =>
      'Nu pare un cod de autentificare. Codurile au 8 litere și cifre.';

  @override
  String get signInCodeDeepLinkHint =>
      'Dacă browserul se oferă să deschidă Control Center, permite-i și nu va mai trebui să tastezi codul.';

  @override
  String signInSucceeded(String provider, String account) {
    return 'Autentificat în $provider ca $account';
  }

  @override
  String signInSucceededNoAccount(String provider) {
    return 'Autentificat în $provider';
  }

  @override
  String get signInErrorExpired =>
      'Această autentificare a expirat. Începe din nou.';

  @override
  String signInErrorAccessDenied(String provider) {
    return 'Autentificarea în $provider a fost anulată sau refuzată.';
  }

  @override
  String signInErrorScopeMismatch(String provider) {
    return '$provider a acordat mai puține permisiuni decât îi trebuie lui Control Center. Autentifică-te din nou și aprobă toate permisiunile.';
  }

  @override
  String get signInErrorInvalidCode =>
      'Codul nu corespunde acestei autentificări. Verifică-l și încearcă din nou.';

  @override
  String get signInErrorTooManyCodes =>
      'Prea multe coduri greșite. Pornește din nou autentificarea.';

  @override
  String get signInErrorStaleRequest =>
      'Această autentificare nu mai este deschisă: a fost anulată, folosită sau înlocuită. Pornește-o din nou.';

  @override
  String get signInErrorInvalidRequest =>
      'Serverul nu a putut citi această cerere de autentificare. Pornește-o din nou.';

  @override
  String get signInErrorRateLimited =>
      'Prea multe cereri acum. Așteaptă puțin, apoi încearcă din nou.';

  @override
  String signInErrorStoreFailed(String provider) {
    return '$provider a acceptat autentificarea, dar serverul nu a putut-o salva. Încearcă din nou.';
  }

  @override
  String signInErrorProviderUnavailable(String provider) {
    return '$provider nu răspunde acum. Încearcă din nou peste câteva minute.';
  }

  @override
  String signInErrorExchangeFailed(String provider) {
    return '$provider a acceptat autentificarea, dar serverul nu a putut-o finaliza. Încearcă din nou.';
  }

  @override
  String signInErrorMisconfigured(String provider) {
    return 'Aplicația $provider a acestui server este configurată greșit. Cere proprietarului serverului să verifice Setări → Server → Autentificare unică.';
  }

  @override
  String signInErrorNeedsSignIn(String provider) {
    return 'Autentificarea ta în $provider a expirat. Autentifică-te din nou ca să lucrezi în continuare în numele tău.';
  }

  @override
  String signInErrorNotInstalled(String provider) {
    return 'Aplicația $provider nu este instalată acolo unde e nevoie de ea. Instaleaz-o și încearcă din nou.';
  }

  @override
  String get signInErrorTeamBoundElsewhere =>
      'Acest spațiu Slack este deja conectat la alt server Control Center.';

  @override
  String get signInErrorNotAdmin =>
      'Doar un administrator sau proprietar al spațiului de lucru Slack îl poate conecta prima dată la Control Center. Cere-i unuia dintre ei să adauge aplicația.';

  @override
  String signInErrorSuspended(String provider) {
    return 'Aplicația $provider este suspendată. Anulează suspendarea în $provider și încearcă din nou.';
  }

  @override
  String get signInErrorInstallBlocked =>
      'Control Center Connect a blocat acest server. Contactează operatorul serverului tău Connect.';

  @override
  String get signInErrorUnknown =>
      'Autentificarea a eșuat dintr-un motiv pe care serverul nu l-a raportat. Încearcă din nou.';

  @override
  String get signInPhishingTitle => 'Autentificare nepornită de aici';

  @override
  String get signInPhishingBody =>
      'Această autentificare nu a fost pornită din această aplicație. Dacă cineva ți-a trimis acest link, nu continua.';

  @override
  String get signInPhishingDetail =>
      'Nu s-a trimis nimic. Finalizarea unei autentificări pornite de altcineva ți-ar conecta contul la serverul acelei persoane.';

  @override
  String signInRequiredTitle(String provider) {
    return 'Este necesară autentificarea în $provider';
  }

  @override
  String signInRequiredBody(String provider) {
    return 'Acțiunea rulează în numele tău în $provider, iar tu nu ești autentificat. Autentifică-te și încearcă din nou.';
  }

  @override
  String signInRequiredBanner(String provider) {
    return 'Nu ești autentificat în $provider. Tot ce faci aici rulează în numele tău, așa că autentifică-te mai întâi.';
  }

  @override
  String signInUnavailable(String provider) {
    return 'Autentificarea în $provider nu este încă configurată pe acest server.';
  }

  @override
  String get githubInstallations => 'Instalări ale aplicației GitHub';

  @override
  String get githubInstallationsDescription =>
      'Unde este instalată aplicația GitHub, printre conturile cărora le aparțin depozitele acestui spațiu de lucru.';

  @override
  String get githubInstallationsEmpty =>
      'Aplicația GitHub nu este instalată pe niciun cont căruia îi aparțin depozitele acestui spațiu de lucru.';

  @override
  String get githubInstallApp => 'Instalează aplicația GitHub';

  @override
  String get githubInstallationSuspended => 'Suspendată';

  @override
  String get linearAutomationTitle => 'Automatizare Linear';

  @override
  String get linearAutomationHint =>
      'Permite agenților și pipeline-urilor din acest spațiu de lucru să acționeze în Linear ca aplicație, nu ca persoană. Administratorii spațiului o conectează.';

  @override
  String linearAutomationConnectedAs(String account) {
    return 'Conectat la $account';
  }

  @override
  String get connectModeHosted => 'Folosește aplicațiile Control Center';

  @override
  String get connectModeHostedDisclosure =>
      'Autentificările trec prin Control Center Connect. Connect sigilează fiecare autentificare astfel încât doar acest server să o poată deschide, emite tokenuri GitHub limitate la un singur depozit, nu păstrează nicio cheie de depozit și nu primește niciodată codul tău sursă.';

  @override
  String get connectModeOwn => 'Folosește aplicațiile mele';

  @override
  String get connectModeOwnHint =>
      'Înregistrează singur aplicațiile GitHub, Google și Linear în Setări → Server → Autentificare unică, și conectează aplicația Slack proprie a fiecărui spațiu de lucru în Spațiu de lucru → Integrări, unde un spațiu de lucru poate alege și propriile aplicații sau Connect. „Creează aplicația mea GitHub” configurează GitHub într-un singur pas.';

  @override
  String get connectModeCustom => 'Folosește un server Connect propriu';

  @override
  String get connectModeCustomHint =>
      'Organizația ta rulează propriul server Connect. Autentificările merg acolo în loc de serverul Control Center.';

  @override
  String get connectModeUnset => 'Încă neconfigurat';

  @override
  String get connectCustomUrlLabel => 'URL-ul serverului Connect';

  @override
  String get connectCustomUrlInvalid =>
      'Introdu o adresă HTTPS, de exemplu https://connect.example.com.';

  @override
  String get connectCustomUrlLoopbackHint =>
      'HTTP simplu ajunge doar la un Connect de pe acest calculator. Folosește HTTPS pentru orice într-o rețea.';

  @override
  String get connectErrorHostedUnprovisioned =>
      'Aplicațiile găzduite ale Control Center nu sunt încă disponibile în această versiune. Folosește aplicațiile tale sau un server Connect propriu.';

  @override
  String get connectErrorSignature =>
      'Configurația Connect nu a trecut verificarea semnăturii. Autentificările prin Connect sunt suspendate până când este verificată din nou.';

  @override
  String get connectErrorRollback =>
      'Connect a furnizat o configurație mai veche decât cea văzută deja de acest server, așa că a fost refuzată. Autentificările prin Connect sunt suspendate.';

  @override
  String get connectErrorUnreachable =>
      'Acest server nu poate contacta Connect acum. Autentificările care îl folosesc vor eșua până revine.';

  @override
  String get connectErrorInstallBlocked =>
      'Connect a blocat ID-ul de instalare al acestui server. Contactează operatorul serverului tău Connect.';

  @override
  String get connectErrorPinsChanged => 'Aplicațiile Connect s-au schimbat';

  @override
  String get connectErrorProtocol =>
      'Connect a răspuns într-un mod pe care acest server nu îl înțelege. Actualizează serverul sau verifică URL-ul Connect.';

  @override
  String get connectErrorUnknown =>
      'Connect a raportat o problemă fără să o explice. Rulează un test ca să reîncerci.';

  @override
  String get connectPinsConfirmHint =>
      'Serverul tău Connect indică acum alte aplicații GitHub, Google, Linear sau Slack decât cele pe care acest server le-a fixat la prima utilizare. Ai încredere în ele doar dacă operatorul te-a anunțat că urmează.';

  @override
  String get connectConfirmPins => 'Acceptă aplicațiile noi';

  @override
  String get connectStale =>
      'Configurația folosită este mai veche decât era de așteptat. Rulează un test ca s-o reîmprospătezi.';

  @override
  String get connectLaneSourceOwn => 'Aplicație proprie';

  @override
  String get connectLaneSourceConnect => 'Connect';

  @override
  String get connectLaneSourceOff => 'Oprit';

  @override
  String get connectTitle => 'Control Center Connect';

  @override
  String get connectDescription =>
      'Ale cui aplicații folosește acest server pentru GitHub, Google Calendar, Linear, Slack și căutarea de GIF-uri.';

  @override
  String get connectFactMode => 'Aplicații de autentificare';

  @override
  String get connectFactHealth => 'Stare';

  @override
  String get connectFactEpoch => 'Versiunea configurației';

  @override
  String get connectHealthOff => 'Nefolosit';

  @override
  String get connectHealthOk => 'Funcționează';

  @override
  String get connectHealthDown => 'Nu funcționează';

  @override
  String get connectLocked =>
      'CC_CONNECT_URL din mediul acestui server stabilește asta. Modifică-l acolo și repornește serverul.';

  @override
  String get connectLanesTitle => 'Unde rulează fiecare autentificare';

  @override
  String get connectLanesDescription =>
      'O aplicație proprie are mereu prioritate față de Connect pentru furnizorul ei.';

  @override
  String get connectServerGroup => 'Acest server';

  @override
  String get connectInstallId => 'ID de instalare';

  @override
  String get connectInstallIdHint =>
      'Identifică acest server în fața Connect. Dă-l proprietarului unei organizații sau operatorului Connect care îl cere.';

  @override
  String get connectInstallIdEmpty =>
      'Se atribuie prima dată când acest server folosește Connect.';

  @override
  String get connectTestOk => 'Connect funcționează.';

  @override
  String get connectRotateKey => 'Schimbă cheia';

  @override
  String get connectRotateKeyTitle => 'Schimbi cheia Connect a acestui server?';

  @override
  String get connectRotateKeyBody =>
      'Serverul primește o cheie nouă și un ID de instalare nou, iar ID-ul vechi este retras la Connect: autentificările sigilate cu el și vechea cheie nu mai funcționează acolo, deci toți cei care s-au autentificat prin Connect trebuie să se autentifice din nou. Tokenurile deja distribuite funcționează până expiră. Autentificările prin propriile aplicații nu sunt afectate. Dacă Connect nu poate fi contactat, nu se schimbă nimic și poți încerca din nou.';

  @override
  String get connectRotateKeyDone =>
      'Cheie schimbată. Toți cei autentificați prin Connect trebuie să se autentifice din nou.';

  @override
  String get connectCliLabel => 'Dintr-un terminal';

  @override
  String get onboardingStepSignIn => 'Autentificare';

  @override
  String get onboardingConnectTitle => 'Alege cum se autentifică oamenii';

  @override
  String get onboardingConnectSubtitle =>
      'Control Center lucrează cu GitHub, Google Calendar, Linear, Slack și căutarea de GIF-uri prin aplicații înregistrate la fiecare furnizor. Alege ale cui aplicații folosește acest server. Poți schimba asta mai târziu în Setări → Server → Autentificare unică.';

  @override
  String get onboardingConnectOwnNext =>
      'Creează acum o aplicație GitHub pentru acest server sau adaugă-ți aplicațiile mai târziu în Setări → Server → Autentificare unică.';

  @override
  String get providerServiceApiKey => 'Cheie API de serviciu';

  @override
  String get providerAppPartial => 'Configurarea nu e terminată';

  @override
  String providerAppMissingFields(String fields) {
    return 'Încă lipsește: $fields. Până când toate câmpurile sunt completate, autentificările pentru acest furnizor sunt refuzate în loc să treacă prin Connect.';
  }

  @override
  String get providerAppsGroupSignInLinearDescription =>
      'ID-ul de client autentifică membrii. Cheia API de serviciu permite acestui server să citească și să scrie singur în Linear.';

  @override
  String get providerCallbackUrls => 'URL-uri de callback';

  @override
  String get providerCallbackUrlHint =>
      'Înregistrează-l la furnizor exact așa cum apare.';

  @override
  String get providerAppCreateGitHubTitle => 'Creează o aplicație GitHub';

  @override
  String get providerAppCreateGitHubHint =>
      'GitHub înregistrează o aplicație cu permisiunile și callbackul corecte, apoi îi predă acestui server datele de autentificare. Nimic de copiat manual.';

  @override
  String get providerAppCreateGitHub => 'Creează aplicația mea GitHub';

  @override
  String get providerAppCreateGitHubOrg => 'Organizație (opțional)';

  @override
  String get providerAppCreateGitHubOrgHint =>
      'Lasă gol pentru a crea aplicația în propriul cont GitHub. Crearea ei într-o organizație necesită un proprietar al acelei organizații.';

  @override
  String get providerAppSignInReady => 'Oamenii se pot autentifica.';

  @override
  String get chatLinkWaiting => 'Se așteaptă mesajul tău direct…';

  @override
  String chatLinkClaimTitle(String provider) {
    return 'Este acesta contul tău $provider?';
  }

  @override
  String chatLinkClaimBody(String provider) {
    return 'Acest cont a trimis codul tău botului. Confirmă doar dacă este al tău: după legare, ce trimite în $provider acționează ca tine în acest spațiu de lucru.';
  }

  @override
  String get chatLinkDecline => 'Refuză';

  @override
  String chatLinkDeclined(String provider) {
    return 'Nu s-a legat nimic. Obține un cod nou dacă tot vrei să-ți legi contul $provider.';
  }

  @override
  String get chatLinkNewCode => 'Obține un cod nou';

  @override
  String signInAddControlCenter(String provider) {
    return 'Adaugă Control Center în $provider';
  }

  @override
  String signInAddedControlCenter(String workspace) {
    return 'Control Center a fost adăugat în $workspace';
  }

  @override
  String chatSharedAppHint(String provider) {
    return 'Instalează aplicația comună Control Center în spațiul tău de lucru $provider. Nu trebuie să creezi nicio aplicație și nici să lipești vreun token.';
  }

  @override
  String chatAddToProvider(String provider) {
    return 'Adaugă în $provider';
  }

  @override
  String get chatSharedAppConnected =>
      'Rulează pe aplicația comună Control Center, așa că aici nu există tokenuri sau setări ale botului de gestionat.';

  @override
  String get chatTicketDraftsTitle => 'Ciorne de tichete din chat';

  @override
  String get chatTicketDraftsDescription =>
      'O ciornă devine tichet în backlog doar când o creezi aici. Ciornele lăsate deoparte sunt șterse după o zi.';

  @override
  String chatTicketDraftFrom(String provider) {
    return 'Din $provider';
  }

  @override
  String get chatTicketDraftCreate => 'Creează tichetul';

  @override
  String chatTicketDraftCreated(String key) {
    return '$key a fost creat';
  }

  @override
  String workspaceProviderAppMissingFields(String fields) {
    return 'Lipsesc încă: $fields. Până când toate câmpurile sunt completate, acest provider este dezactivat în acest spațiu de lucru. Nu revine la aplicația acestui server.';
  }

  @override
  String get workspaceProviderAppClientChangeHint =>
      'Schimbarea aplicației deconectează pe toți din acest spațiu de lucru. Se vor autentifica din nou cu cea nouă.';

  @override
  String get workspaceProviderAppKlipyKey => 'Cheie de aplicație';

  @override
  String get workspaceProviderAppKlipyHint =>
      'Căutarea GIF-urilor din acest spațiu de lucru folosește această cheie.';

  @override
  String get settingsWorkspaceIntegrations => 'Integrări';

  @override
  String get settingsWorkspaceIntegrationsDescription =>
      'Găzduirea codului, tichetele, calendarul, chatul și căutarea GIF-urilor în acest spațiu de lucru și aplicațiile prin care se conectează.';

  @override
  String get workspaceConnectDescription =>
      'Ce aplicații folosește acest spațiu de lucru pentru GitHub, Google Calendar, Linear, Slack și căutarea GIF-urilor. Dacă un administrator nu alege altceva, urmează acest server.';

  @override
  String get workspaceConnectModeInherit => 'Același ca acest server';

  @override
  String get workspaceConnectInheritHosted =>
      'Acest server folosește aplicațiile Control Center.';

  @override
  String workspaceConnectInheritCustom(String url) {
    return 'Acest server folosește serverul Connect de la $url.';
  }

  @override
  String get workspaceConnectInheritOwn =>
      'Acest server folosește propriile aplicații.';

  @override
  String get workspaceConnectInheritUnset =>
      'Proprietarul serverului nu a ales încă, așa că se aplică aplicațiile proprii ale serverului.';

  @override
  String get workspaceConnectOwnHint =>
      'Sunt folosite doar aplicațiile acestui spațiu de lucru. Adaugă fiecare aplicație mai jos, lângă furnizorul ei. Un furnizor fără aplicație este dezactivat aici; aplicațiile acestui server și Connect nu sunt folosite în locul lui.';

  @override
  String get workspaceConnectCustomUrlHint =>
      'Doar HTTPS. Adresele din rețele private sau locale sunt refuzate.';

  @override
  String get workspaceConnectLocked =>
      'CC_CONNECT_URL din mediul acestui server stabilește unde merg autentificările, așa că acest spațiu de lucru nu poate alege un Connect propriu. Poate urma acest server sau poate folosi propriile aplicații.';

  @override
  String get workspaceConnectSwitchTitle =>
      'Schimbi aplicațiile de autentificare ale acestui spațiu de lucru?';

  @override
  String get workspaceConnectSwitchBody =>
      'Toți cei din spațiul de lucru trebuie să se autentifice din nou în GitHub, Linear și Google Calendar prin noile aplicații. Autentificările făcute prin aplicațiile actuale nu mai funcționează aici.';

  @override
  String get workspaceConnectSwitchAction => 'Schimbă aplicațiile';

  @override
  String get workspaceConnectLanesDescription =>
      'Urmează alegerea de mai sus. Un furnizor nu revine niciodată la o altă aplicație.';

  @override
  String get workspaceConnectLaneWorkspaceOwn => 'Aplicația spațiului de lucru';

  @override
  String get workspaceConnectLaneServerOwn => 'Aplicația serverului';

  @override
  String get workspaceGitHubAppTitle => 'Aplicația GitHub';

  @override
  String get workspaceGitHubAppOwnDescription =>
      'Aplicația proprie a acestui spațiu de lucru acționează pentru depozitele sale și autentifică membrii. Nu revine niciodată la aplicația acestui server sau la Connect.';

  @override
  String get workspaceGitHubAppSharedDescription =>
      'Acest spațiu de lucru folosește aplicația GitHub pusă la dispoziție de aplicațiile sale de autentificare. Instaleaz-o pe conturile cărora le aparțin depozitele tale.';

  @override
  String get workspaceGitHubAppActingTitle =>
      'Acționează pentru acest spațiu de lucru';

  @override
  String get workspaceGitHubAppActingDescription =>
      'Botul aplicației comentează, revizuiește și sondează pull requesturile din depozitele acestui spațiu de lucru.';

  @override
  String workspaceOwnAppTitle(String provider) {
    return 'Aplicația $provider';
  }

  @override
  String workspaceOwnAppDescription(String provider) {
    return 'Autentificările și cererile $provider din acest spațiu de lucru folosesc doar această aplicație.';
  }

  @override
  String get workspaceGifsTitle => 'GIF-uri';

  @override
  String get workspaceGifsSourceWorkspaceOwn =>
      'Căutarea GIF-urilor folosește cheia Klipy a acestui spațiu de lucru.';

  @override
  String get workspaceGifsSourceServerOwn =>
      'Căutarea GIF-urilor folosește cheia Klipy a acestui server.';

  @override
  String get workspaceGifsSourceConnect =>
      'Căutarea GIF-urilor rulează prin Control Center Connect.';

  @override
  String get workspaceGifsSourceOff =>
      'Căutarea GIF-urilor este dezactivată în acest spațiu de lucru.';

  @override
  String openOnForge(String forge) {
    return 'Deschide pe $forge';
  }

  @override
  String prFilesTruncatedNotice(String forge, int count) {
    return 'Se afișează primele $count fișiere. $forge nu le listează pe celelalte.';
  }

  @override
  String get connectForgeToLoadPrs =>
      'Conectează un serviciu de găzduire de cod pentru a încărca pull request-urile';

  @override
  String get connectForgeHint =>
      'Conectează GitHub, GitLab sau Bitbucket în Setări → Tu → Profil';

  @override
  String get addForgeRepoPrompt =>
      'Adaugă cel puțin un depozit pe GitHub, GitLab sau Bitbucket pentru a vedea pull request-uri';

  @override
  String get composePrNoForgeRepo => 'Niciun depozit găzduit selectat';

  @override
  String get composePrNoForgeRepoHint =>
      'Selectează un spațiu de lucru cu un depozit pe GitHub, GitLab sau Bitbucket pentru a deschide un pull request.';

  @override
  String composePrForgeNotConnected(String forge) {
    return 'Conectează $forge pentru a deschide un pull request în acest depozit';
  }

  @override
  String connectionNeedsSignInAs(String provider, String account) {
    return 'Autentificarea ta în $provider ca $account a expirat. Autentifică-te din nou.';
  }

  @override
  String get connectionPaused =>
      'În pauză: serviciul de autentificare al acestui spațiu de lucru s-a schimbat';

  @override
  String connectionUnreachable(String provider) {
    return '$provider nu poate fi contactat acum. Se reîncearcă.';
  }

  @override
  String get forgeSignInBannerPausedBody =>
      'Autentificarea ta este păstrată și funcționează din nou când serviciul revine. Un administrator al spațiului de lucru poate verifica configurarea autentificării în Integrări.';

  @override
  String get signInErrorAttemptUnknown =>
      'Serverul a repornit. Începe din nou autentificarea.';

  @override
  String signInUnavailableNotConfigured(String provider) {
    return 'Autentificarea cu $provider nu este configurată pentru acest spațiu de lucru.';
  }

  @override
  String signInUnavailableMisconfigured(String provider, String error) {
    return 'Autentificarea cu $provider este configurată greșit: $error';
  }

  @override
  String signInUnavailableOwnAppMissing(String provider) {
    return 'Acest spațiu de lucru folosește aplicații proprii, dar nu are o aplicație $provider.';
  }

  @override
  String signInUnavailableConnectUnprovisioned(String provider) {
    return 'Această versiune nu poate verifica Control Center Connect, așa că autentificarea cu $provider este dezactivată.';
  }

  @override
  String get signInUnavailableConnectPinsPending =>
      'Serviciul de autentificare al acestui spațiu de lucru și-a schimbat identitatea. Un administrator trebuie să o confirme.';

  @override
  String get signInUnavailableConnectUnreachable =>
      'Serviciul de autentificare al acestui spațiu de lucru nu poate fi contactat acum.';

  @override
  String get signInUnavailableConnectUrlInvalid =>
      'Adresa serviciului de autentificare al acestui spațiu de lucru lipsește sau nu este validă.';

  @override
  String get signInUnavailableBlockedByEnvironment =>
      'Operatorul serverului a fixat serviciul de autentificare, așa că alegerea acestui spațiu de lucru nu se aplică.';

  @override
  String signInUnavailableLaneNotOffered(String provider) {
    return 'Serviciul de autentificare al acestui spațiu de lucru nu oferă $provider.';
  }

  @override
  String get signInOpenIntegrations => 'Deschide integrările';

  @override
  String get signInOpenServerSettings => 'Deschide setările de autentificare';

  @override
  String forgeTokenRequiredBody(String provider) {
    return 'Acțiunea rulează în numele tău în $provider și nu ai adăugat un token. Adaugă unul, apoi încearcă din nou.';
  }

  @override
  String disconnectProviderTitle(String provider) {
    return 'Deconectezi $provider?';
  }

  @override
  String disconnectProviderBody(String provider) {
    return 'Va trebui să conectezi din nou $provider ca să lucrezi la depozitele lui.';
  }

  @override
  String disconnectScopeWorkspaceBody(String provider) {
    return 'Astfel deconectezi $provider doar în acest spațiu de lucru. Celelalte spații de lucru își păstrează propria conexiune.';
  }

  @override
  String disconnectScopeGlobalBody(String provider) {
    return 'Astfel deconectezi $provider în toate spațiile de lucru care folosesc această conexiune.';
  }

  @override
  String disconnectedFromWorkspace(String provider) {
    return '$provider a fost deconectat de la acest spațiu de lucru';
  }

  @override
  String disconnectedFromAllWorkspaces(String provider) {
    return '$provider a fost deconectat de la toate spațiile de lucru';
  }

  @override
  String repoAccessInstallTitle(String owner) {
    return 'Instalează GitHub App pe $owner';
  }

  @override
  String repoAccessInstallBody(String repos) {
    return 'Automatizarea nu poate ajunge la $repos până când aplicația nu este instalată acolo.';
  }

  @override
  String repoAccessSelectTitle(String repos) {
    return 'Adaugă $repos la depozitele GitHub App';
  }

  @override
  String get repoAccessSelectBody =>
      'Aplicația este instalată pe acest cont, dar încă nu vede aceste depozite.';

  @override
  String get repoAccessChooseRepos => 'Alege depozitele';

  @override
  String get repoAccessSuspendedTitle =>
      'Instalarea GitHub App este suspendată';

  @override
  String repoAccessSuspendedBody(String repos) {
    return 'Automatizarea pentru $repos este în pauză până când un proprietar al contului reia instalarea pe GitHub.';
  }

  @override
  String get repoAccessAutomationPausedTitle => 'Automatizarea este în pauză';

  @override
  String repoAccessOwnerCannotSeeBody(String repos) {
    return 'Persoana responsabilă de automatizarea acestui spațiu de lucru nu mai vede $repos, așa că acolo nu rulează nimic în numele ei.';
  }

  @override
  String repoAccessOwnerNotSignedInBody(String repos) {
    return 'Persoana responsabilă de automatizarea acestui spațiu de lucru nu este autentificată în forge, așa că automatizarea pentru $repos așteaptă până se autentifică.';
  }

  @override
  String repoAccessTransient(String repos) {
    return 'Accesul la $repos nu a putut fi verificat. Se reîncearcă.';
  }

  @override
  String repoAccessAskAdmins(String admins) {
    return 'Cere rezolvarea de la: $admins.';
  }

  @override
  String get repoAccessAskAnAdmin =>
      'Cere unui administrator al spațiului de lucru să rezolve asta.';

  @override
  String hiddenReposSignIn(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Autentifică-te în $forge ca să vezi pull request-urile din alte depozite: $count',
      one:
          'Autentifică-te în $forge ca să vezi pull request-urile din încă 1 depozit',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoForgeAccess(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Depozite ascunse pentru că contul tău $forge nu le vede: $count',
      one: '1 depozit este ascuns pentru că contul tău $forge nu îl vede',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoGrant(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Depozite ascunse la care nu ai acces în acest spațiu de lucru: $count',
      one:
          '1 depozit este ascuns pentru că nu ai acces la el în acest spațiu de lucru',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposChecking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se verifică accesul tău la alte depozite: $count…',
      one: 'Se verifică accesul tău la încă 1 depozit…',
    );
    return '$_temp0';
  }

  @override
  String get repoLinkAccessWarningsTitle =>
      'Legat, dar automatizarea nu ajunge încă peste tot';

  @override
  String get githubInstallOnAnotherOrganization =>
      'Instalează în altă organizație';

  @override
  String get forgeTokenEmailLabel => 'E-mailul contului Atlassian';

  @override
  String get forgeTokenEmailInvalid =>
      'Introdu adresa de e-mail a contului tău Atlassian.';

  @override
  String get forgeTokenApiTokenLabel => 'Token API';

  @override
  String get forgeTokenBitbucketHint =>
      'Tokenurile API Bitbucket funcționează împreună cu e-mailul contului Atlassian care le-a creat.';

  @override
  String get automationTokensTitle => 'Tokenuri de automatizare';

  @override
  String get automationTokensRepoHint =>
      'Munca din fundal pe GitLab și Bitbucket, precum actualizările pull request-urilor, comentariile de revizuire AI și merge request-urile pe care nu le-a cerut nimeni, folosește un token de acces al unui bot, niciodată pe al unei persoane. Tokenul propriu al unui depozit are prioritate față de cel al spațiului de lucru.';

  @override
  String get automationTokensWorkspaceHint =>
      'Folosit pentru fiecare depozit GitLab sau Bitbucket din acest spațiu de lucru care nu are propriul token de automatizare. Munca din fundal de acolo apare ca botul acestui token.';

  @override
  String get automationTokenNone =>
      'Niciun token. Automatizarea este în pauză aici.';

  @override
  String get automationTokenFromWorkspace =>
      'Folosește tokenul spațiului de lucru';

  @override
  String automationTokenActsAs(String name) {
    return 'Acționează ca $name';
  }

  @override
  String get automationTokenStored => 'Token de acces adăugat';

  @override
  String get automationTokenRejected =>
      'Platforma a refuzat acest token. Înlocuiește-l.';

  @override
  String automationTokenDialogTitle(String forge) {
    return 'Token de automatizare $forge';
  }

  @override
  String get automationTokenGitLabHint =>
      'Lipește un token de acces de proiect sau de grup. Are nevoie de read_api și read_repository; adaugă api și write_repository pentru comentarii, merge request-uri și push-uri. GitLab îi afișează munca drept botul tokenului.';

  @override
  String get automationTokenBitbucketHint =>
      'Lipește un token de acces de depozit, proiect sau spațiu de lucru cu citire a depozitului, plus scriere pentru pull request-uri pentru comentarii și pull request-uri. Propriul tău token API se pune la Tu → Profil, nu aici.';

  @override
  String automationTokenUnreadable(String repos) {
    return 'Token salvat, dar nu poate citi $repos. Automatizarea rămâne în pauză acolo.';
  }

  @override
  String get automationTokenRemoveTitle => 'Elimini tokenul de automatizare?';

  @override
  String get automationTokenRemoveBody =>
      'Automatizarea care depinde de acest token intră în pauză până se adaugă altul.';

  @override
  String automationTokenWorkspaceTarget(String forge) {
    return 'Fiecare depozit $forge fără token propriu';
  }

  @override
  String repoAccessAutomationTokenMissingBody(String repos) {
    return 'Niciun token de automatizare nu poate citi $repos, așa că munca din fundal de acolo este în pauză.';
  }

  @override
  String get settingsCommitsDescription =>
      'Commit-urile din munca pe care o pornești poartă numele tău. Alege cine mai primește creditul și dacă forge-urile arată commit-urile tale ca verificate.';

  @override
  String get settingsCommitAuthorshipSection => 'Autorat';

  @override
  String get settingsCommitAuthorshipYoursLabel => 'Munca pe care o pornești';

  @override
  String get settingsCommitAuthorshipYoursBody =>
      'Ești autorul și committer-ul, sub adresa de e-mail verificată de forge pentru autentificarea ta. Aici intră conversațiile cu agenții, pipeline-urile pe care le pornești și commit-urile pe care le faci în editor.';

  @override
  String get settingsCommitAuthorshipBotLabel => 'Rulări automate';

  @override
  String get settingsCommitAuthorshipBotBody =>
      'Rulările pornite de un program sau de un webhook fac commit ca bot și nu sunt niciodată semnate.';

  @override
  String get settingsCommitAuthorshipSignInNote =>
      'Până te autentifici într-un forge din spațiul de lucru, rulările tale de acolo fac commit ca bot.';

  @override
  String get settingsCoauthorCreditTitle =>
      'Creditează Control Center ca co-autor';

  @override
  String get settingsCoauthorCreditDescription =>
      'Commit-urile tale menționează Control Center (@usectrl) ca co-autor, iar rulările automate pe care le-ai activat te menționează pe tine. Când este dezactivat, nu se adaugă niciuna dintre linii.';

  @override
  String get settingsCoauthorCreditWorkspaceOverride =>
      'Setarea acestui spațiu de lucru îți suprascrie alegerea personală. Preferința ta rămâne salvată, dar nu se aplică aici.';

  @override
  String get settingsCoauthorCreditLoading =>
      'Se încarcă setările de atribuire a autorului…';

  @override
  String get settingsWorkspaceCoauthorCreditTitle => 'Credit de co-autor';

  @override
  String get settingsWorkspaceCoauthorCreditDescription =>
      'Dacă commit-urile au linii de co-autor: Control Center pentru commit-urile proprii ale unui membru și membrii care au activat o rulare automată pentru commit-urile ei. Alegerea de aici înlocuiește setarea fiecărui membru.';

  @override
  String get settingsWorkspaceCoauthorCreditInherit =>
      'Folosește preferința fiecărui membru';

  @override
  String get settingsWorkspaceCoauthorCreditAlways =>
      'Adaugă mereu creditul de co-autor';

  @override
  String get settingsWorkspaceCoauthorCreditNever =>
      'Nu adăuga niciodată creditul de co-autor';

  @override
  String get settingsCommitSigningSection => 'Commit-uri verificate';

  @override
  String get settingsCommitSigningStatusOn => 'Semnare';

  @override
  String get settingsCommitSigningStatusOff => 'Fără semnare';

  @override
  String get settingsCommitSigningIntro =>
      'Acest server poate semna commit-urile tale cu o cheie proprie, astfel încât GitHub și GitLab să le arate ca verificate. Nimic nu este semnat până nu creezi cheia.';

  @override
  String get settingsCommitSigningCreate => 'Creează cheia de semnare';

  @override
  String get settingsCommitSigningCreated =>
      'Cheia de semnare a fost creată. Adaug-o în contul tău de pe forge.';

  @override
  String get settingsCommitSigningPublicKeyLabel => 'Cheie publică';

  @override
  String get settingsCommitSigningKeyCopied => 'Cheie publică copiată';

  @override
  String get settingsCommitSigningFingerprintLabel => 'Amprentă';

  @override
  String get settingsCommitSigningCreatedLabel => 'Creată';

  @override
  String get settingsCommitSigningAddTitle =>
      'Adaugă-o în contul tău de pe forge';

  @override
  String get settingsCommitSigningAddDescription =>
      'Un commit apare ca verificat doar cât timp ești autentificat și în acel forge din spațiul de lucru, astfel încât forge-ul garantează adresa ta de e-mail.';

  @override
  String get settingsCommitSigningGitHubSteps =>
      'Settings → SSH and GPG keys → New SSH key. Setează Key type la Signing Key.';

  @override
  String get settingsCommitSigningGitLabSteps =>
      'Preferences → SSH Keys. Setează Usage type la Signing.';

  @override
  String get settingsCommitSigningBitbucketSteps =>
      'Commit-urile de pe Bitbucket nu sunt semnate. Nu adăuga această cheie în contul tău Bitbucket: o cheie SSH de acolo este și o autentificare.';

  @override
  String get settingsCommitSigningUnsupported => 'Neacceptat';

  @override
  String get settingsCommitSigningTrustTitle => 'Ce acorzi încredere';

  @override
  String get settingsCommitSigningTrustPrivate =>
      'Cheia privată nu părăsește niciodată acest server.';

  @override
  String get settingsCommitSigningTrustControl =>
      'Oricine controlează acest server poate semna commit-uri în numele tău atâta timp cât cheia se află în contul tău de pe forge.';

  @override
  String get settingsCommitSigningTrustVerified =>
      'Pe GitHub, commit-urile deja arătate ca verificate rămân verificate după ce elimini cheia.';

  @override
  String get settingsCommitSigningDelete => 'Șterge cheia';

  @override
  String get settingsCommitSigningDeleteTitle => 'Ștergi cheia ta de semnare?';

  @override
  String get settingsCommitSigningDeleteBody =>
      'De acum, commit-urile tale nu mai sunt semnate. Cheia rămâne în conturile tale de pe forge până o elimini și de acolo.';

  @override
  String get settingsCommitSigningDeleted => 'Cheia de semnare a fost ștearsă';

  @override
  String settingsCommitSigningLoadFailed(String error) {
    return 'Nu s-a putut încărca cheia ta de semnare: $error';
  }

  @override
  String get accountProfileTitle => 'Profil';

  @override
  String get accountProfileDescription =>
      'Cine ești în fiecare spațiu de lucru și ce conturi proprii ai pentru găzduire de cod, ticketing, calendar și chat.';

  @override
  String get accountSectionTitle => 'Cont';

  @override
  String get accountSectionDescription =>
      'Numele de utilizator și numele tău te urmează în fiecare spațiu de lucru. Un spațiu de lucru poate afișa alt nume sau alt e-mail: setează-le în Spațiu de lucru → Profil și identitate.';

  @override
  String accountLoadFailed(String error) {
    return 'Nu s-a putut încărca profilul tău: $error';
  }

  @override
  String get accountDisplayNameHint =>
      'Numele pe care îl văd oamenii în mesajele și revizuirile tale.';

  @override
  String get accountDisplayNameRequired => 'Introdu un nume afișat.';

  @override
  String get accountFieldCannotBeCleared =>
      'Acesta poate fi modificat, dar nu șters.';

  @override
  String get accountAvatarLabel => 'Poză';

  @override
  String get accountAvatarHint =>
      'Un link către o imagine pătrată, care începe cu https://.';

  @override
  String get accountAvatarInvalid =>
      'Folosește un link care începe cu https://.';

  @override
  String get usernameLabel => 'Nume de utilizator';

  @override
  String get usernameRule =>
      '2 până la 32 de litere mici, cifre, puncte, liniuțe sau underscore-uri. Oamenii te menționează cu el.';

  @override
  String get usernameAvailable => 'Disponibil.';

  @override
  String usernameAvailableAs(String username) {
    return 'Disponibil. Va fi salvat ca $username.';
  }

  @override
  String get usernameInvalid =>
      'Folosește 2 până la 32 de litere mici, cifre, „.”, „_” sau „-”, începând și terminând cu o literă sau o cifră.';

  @override
  String get usernameReserved => 'Acest nume de utilizator este rezervat.';

  @override
  String get usernameTaken => 'Acest nume de utilizator este deja luat.';

  @override
  String get usernameCheckFailed =>
      'Nu se poate verifica acest nume acum. Poți salva oricum; decide serverul.';

  @override
  String get linkedAccountsTitle => 'Conturi conectate';

  @override
  String get linkedAccountsIdentityProvider => 'Furnizor de identitate';

  @override
  String get linkedAccountStatusNeedsSignIn => 'Necesită autentificare';

  @override
  String get linkedAccountStatusPaused => 'În pauză';

  @override
  String get linkedAccountStatusUnreachable => 'Inaccesibil';

  @override
  String get ssoIdentityDescription =>
      'Furnizorul de identitate prin care se autentifică contul tău. Cine administrează serverul îl gestionează.';

  @override
  String get settingsAccountsDescription =>
      'Conturile pe care le conectezi pentru tine. Control Center acționează în numele tău prin ele, iar modificările le afectează doar pe ale tale.';

  @override
  String get accountReachServer =>
      'Folosit în fiecare spațiu de lucru de pe acest server.';

  @override
  String accountReachWorkspace(String workspace) {
    return 'Folosit doar în $workspace.';
  }

  @override
  String forgeReachGitHubOwnApp(String workspace) {
    return 'GitHub se folosește doar în $workspace, care are propriile aplicații de autentificare. GitLab și Bitbucket se folosesc în fiecare spațiu de lucru de pe acest server.';
  }

  @override
  String get yourAccountLabel => 'Contul tău';

  @override
  String yourAccountEntry(String provider, String detail) {
    return '$provider: $detail';
  }

  @override
  String yourAccountLineSemantics(String status) {
    return 'Contul tău: $status. Deschide Tu → Profil.';
  }

  @override
  String get yourForgeAccountNone => 'Niciun cont de găzduire de cod conectat';

  @override
  String yourAccountNotConnected(String provider) {
    return 'Niciun cont $provider conectat';
  }

  @override
  String yourChatAccountNotLinked(String provider) {
    return 'Niciun cont $provider legat';
  }

  @override
  String get demoUnavailableAccount =>
      'În demo ești un oaspete temporar, deci nu există un cont de modificat: nici nume de utilizator, profil sau conturi conectate.';

  @override
  String get onboardingStepYou => 'Tu';

  @override
  String get onboardingYouTitle => 'Alege-ți numele de utilizator';

  @override
  String get onboardingYouSubtitle =>
      'Numele tău de utilizator este cum te menționează oamenii și cum este etichetată munca ta. Îl poți schimba mai târziu, la fel ca numele afișat, în Setări → Tu → Profil.';

  @override
  String signInErrorAccountAlreadyBound(String provider) {
    return 'Acest cont $provider este deja conectat la altă persoană de pe acest server. Autentifică-te cu alt cont $provider.';
  }

  @override
  String forgeTokenExpiresOn(String date) {
    return 'Tokenul expiră la $date';
  }

  @override
  String forgeTokenExpiredOn(String date) {
    return 'Tokenul a expirat la $date. Lipește unul nou ca să continue să funcționeze.';
  }

  @override
  String personTokenUnreachable(String forge) {
    return '$forge nu a putut fi contactat pentru a verifica acest token. Încearcă din nou peste puțin.';
  }

  @override
  String personTokenRejected(String forge) {
    return '$forge nu acceptă acest token. Verifică dacă l-ai copiat complet și dacă nu a fost revocat.';
  }

  @override
  String personTokenWrongKind(String forge) {
    return 'Acesta nu este un token personal. Lipește un token de acces personal din contul tău $forge, nu un token de proiect, grup, spațiu de lucru sau bot.';
  }

  @override
  String personTokenNarrowScope(String scope) {
    return 'Acestui token îi lipsește scope-ul $scope, necesar pentru revizuire și comentarii. Creează unul care îl are.';
  }

  @override
  String get personTokenExpired =>
      'Acest token a expirat. Creează unul nou și lipește-l aici.';

  @override
  String get settingsCommitSigningTrustAgents =>
      'Agenții pe care îi pornești pot face commit-uri semnate în numele tău, în orice depozit în care lucrează. Dacă ștergi cheia aici, asta se oprește imediat: rulările deja în curs nu mai semnează nimic.';

  @override
  String connectRotateKeyFailed(String error) {
    return 'Cheia nu a fost rotită și nu s-a schimbat nimic: $error Încearcă din nou.';
  }

  @override
  String get noWorkspaceInviteTitle => 'Nu ești încă într-un spațiu de lucru';

  @override
  String get noWorkspaceInviteBody =>
      'Un administrator al spațiului de lucru trebuie să te invite, sau proprietarul serverului poate crea un spațiu de lucru pentru tine. Se deschide aici imediat ce ești adăugat.';

  @override
  String noWorkspaceSignedInAs(String name) {
    return 'Autentificat ca $name';
  }

  @override
  String get noWorkspaceCheckAgain => 'Verifică din nou';

  @override
  String get noWorkspaceSignOut => 'Deconectare';

  @override
  String get workspaceCreateOwnerOnly =>
      'Doar proprietarul serverului poate crea spații de lucru. Cere-i să creeze unul sau cere unui administrator al spațiului de lucru să te invite.';

  @override
  String repoLinkNoWorkspaceToAddTo(String repo) {
    return '$repo nu se află în niciunul dintre spațiile tale de lucru, iar tu nu ești într-un spațiu de lucru în care să-l adaugi. Cere unui administrator al spațiului de lucru să te invite.';
  }

  @override
  String get serverOwnerOnly => 'Doar proprietarul serverului poate face asta';

  @override
  String get ideCodeServerOwnerOnlyHint =>
      'Editorul complet rulează pe mașina serverului, așa că doar proprietarul serverului îl poate deschide. Poți totuși să deschizi și să editezi fișiere din Explorer.';

  @override
  String get terminalSandboxedBadge => 'În sandbox';

  @override
  String get terminalSandboxedHint =>
      'Rulează într-un sandbox, în folderele acestui spațiu de lucru, deci unele instrumente și căi de pe gazdă nu sunt disponibile aici.';

  @override
  String get terminalHostShellOwnerOnly =>
      'Shell-ul gazdei rulează pe server fără sandbox, deci doar proprietarul serverului îl poate deschide. Un terminal obișnuit rulează în sandbox.';

  @override
  String get terminalOutsideWorkspace =>
      'Un terminal se poate deschide doar în folderele proprii ale acestui spațiu de lucru.';

  @override
  String get environmentHostOwnerOnly =>
      'Doar proprietarul serverului poate salva sau aproba un mediu care rulează pe gazda serverului. Un administrator al spațiului de lucru poate folosi unul care rulează într-o stație.';

  @override
  String get settingsCommitsNoHooks =>
      'Commit-urile pe care le faci în editorul aplicației nu rulează hook-urile Git din depozit, ca în cazul git commit --no-verify: serverul rulează Git pe propria gazdă, într-un arbore pe care agenții și pull request-urile îl pot modifica.';

  @override
  String get mcpTokenDescription =>
      'Clienții MCP trimit acest token cu fiecare cerere, ca header Authorization: Bearer. Serverul îl creează la prima pornire; îl poți roti, dar nu îl poți elimina.';

  @override
  String get mcpShowToken => 'Afișează tokenul';

  @override
  String get mcpHideToken => 'Ascunde tokenul';

  @override
  String get mcpRotateToken => 'Rotește tokenul';

  @override
  String get mcpRotateTokenTitle => 'Rotești tokenul MCP?';

  @override
  String get mcpRotateTokenBody =>
      'Serverul trece imediat la un token nou. Fiecare client MCP care folosește încă cel curent este refuzat până îi dai cel nou.';

  @override
  String get mcpTokenRotated =>
      'Token rotit. Dă clienților tăi MCP pe cel nou.';

  @override
  String get mcpOwnerOnlyTitle =>
      'Endpointul MCP este pentru proprietarul serverului';

  @override
  String get mcpOwnerOnlyBody =>
      'Tokenul său deschide toate instrumentele de pe acest server, deci doar proprietarul serverului îl poate vedea, roti, porni sau opri endpointul.';

  @override
  String get activityRotatedMcpToken => 'A rotit tokenul MCP';

  @override
  String get connectRotateKeyRetireFailedTitle =>
      'Connect nu a putut retrage cheia veche';

  @override
  String get connectRotateKeyForceBody =>
      'Nu s-a schimbat nimic. Dacă rotești oricum, serverul primește cheia nouă, dar identitatea veche rămâne utilizabilă la acel Connect până expiră autentificările ei.';

  @override
  String get connectRotateKeyAnyway => 'Rotește oricum';

  @override
  String get settingsAuditLog => 'Jurnal de audit';

  @override
  String get settingsAuditLogDescription =>
      'Cine a schimbat ce, unde și cum s-a încheiat, pe server și în fiecare spațiu de lucru pe care îl administrezi. Operațiunile de pe server înregistrează numele argumentelor, niciodată valorile lor.';

  @override
  String get auditLogNoAccessTitle => 'Doar pentru administratori';

  @override
  String get auditLogNoAccess =>
      'Jurnalul de audit acoperă serverul și spațiile de lucru pe care le administrezi. Nu administrezi niciun spațiu de lucru, deci nu există nimic de afișat.';

  @override
  String get auditLogSourceServer => 'Server';

  @override
  String get auditLogSourceWorkspace => 'Spațiu de lucru';

  @override
  String get auditLogAddFilter => 'Filtru';

  @override
  String get auditLogFilterOptionsHint => 'Filtrează…';

  @override
  String get auditLogFilterActor => 'Utilizator';

  @override
  String get auditLogFilterSource => 'Spațiu de lucru';

  @override
  String get auditLogFilterOutcome => 'Rezultat';

  @override
  String get auditLogFilterTime => 'Timp';

  @override
  String auditLogFilterChip(String category, String values) {
    return '$category: $values';
  }

  @override
  String auditLogFilterChipMore(String values, int count) {
    return '$values +$count';
  }

  @override
  String get auditLogOutcomeOk => 'Reușit';

  @override
  String get auditLogOutcomeDenied => 'Refuzat';

  @override
  String get auditLogOutcomeFailed => 'Eșuat';

  @override
  String get auditLogTimeAtOrAfter => 'La sau după';

  @override
  String get auditLogTimeAfter => 'După';

  @override
  String get auditLogTimeBefore => 'Înainte de';

  @override
  String get auditLogTimeAtOrBefore => 'La sau înainte de';

  @override
  String auditLogTimeChip(String operator, String time) {
    return 'Timp $operator $time';
  }

  @override
  String get auditLogTimePresetHour => 'Acum 1 oră';

  @override
  String get auditLogTimePresetDay => 'Acum 24 de ore';

  @override
  String get auditLogTimePresetWeek => 'Acum 7 zile';

  @override
  String get auditLogTimePresetMonth => 'Acum 30 de zile';

  @override
  String get auditLogTimeExact => 'Oră exactă';

  @override
  String get auditLogTimeInvalid => 'Folosește YYYY-MM-DD, opțional cu HH:MM';

  @override
  String get auditLogTimeAdd => 'Adaugă';

  @override
  String repoAccessReplacedTitle(String repo) {
    return '$repo indică acum către un alt depozit';
  }

  @override
  String repoAccessReplacedBody(String forge) {
    return 'Această cale indică acum către un alt depozit de pe $forge. Reconectează-l ca să-l poți folosi în continuare.';
  }

  @override
  String get repoRelink => 'Reconectează';

  @override
  String repoRelinked(String repo) {
    return '$repo a fost reconectat.';
  }

  @override
  String get repoCodeRepoReplaced =>
      'Această cale indică acum către un alt depozit. Un administrator al spațiului de lucru trebuie să îl reconecteze înainte de a putea fi folosit.';

  @override
  String repoCodeForgeCannotRead(String forge) {
    return 'Contul tău $forge nu poate citi acest depozit.';
  }

  @override
  String repoCodeForgeUnconfirmed(String forge) {
    return 'Nu s-a putut confirma accesul tău la $forge. Încearcă din nou.';
  }

  @override
  String get repoCodeForgeCannotReadUnnamed =>
      'Contul tău de pe forge nu poate citi acest depozit.';

  @override
  String get repoCodeForgeUnconfirmedUnnamed =>
      'Nu s-a putut confirma accesul tău la forge. Încearcă din nou.';

  @override
  String get repoPathHostPath =>
      'Doar proprietarul serverului poate lega un folder din afara spațiului de stocare al acestui spațiu de lucru.';

  @override
  String get repoPathMissing => 'Nu există nimic la această cale de pe server.';

  @override
  String get repoPathDataDir =>
      'Un depozit nu poate indica spre folderul de date al serverului.';

  @override
  String get repoPathWorkspaceRoot =>
      'Un depozit nu poate fi chiar folderul spațiului de lucru.';

  @override
  String get repoPathOriginMismatch =>
      'Originea acestui folder indică un alt depozit.';

  @override
  String repoGrantNeedsSignIn(String forge) {
    return 'Salvat. Trebuie să se autentifice în $forge înainte să poată deschide acest depozit.';
  }

  @override
  String repoGrantCannotRead(String forge) {
    return 'Salvat. Contul lor $forge nu poate citi încă acest depozit, deci rămâne ascuns pentru ei.';
  }

  @override
  String repoGrantUnconfirmed(String forge) {
    return 'Salvat. Nu s-a putut confirma acum accesul lor la $forge.';
  }

  @override
  String repoLinkAskOwnerToAdd(String repo) {
    return '$repo nu este legat în niciunul dintre spațiile tale de lucru. Cere proprietarului serverului să îl adauge.';
  }

  @override
  String get reposEmptyAskOwner =>
      'Proprietarul serverului adaugă depozite din folderele serverului.';

  @override
  String get accountEmailUnconfirmedHint =>
      'Doar tu ai introdus această adresă. Single sign-on nu o va potrivi până când proprietarul serverului o confirmă.';

  @override
  String get settingsServerPeople => 'Persoane';

  @override
  String get settingsServerPeopleDescription =>
      'Toți cei care au cont pe acest server și dacă adresa lor de e-mail este confirmată.';

  @override
  String get serverPeopleLabel => 'Conturi';

  @override
  String get serverPeopleOwnerOnly =>
      'Doar proprietarul serverului poate vedea conturile tuturor și poate confirma adresele de e-mail.';

  @override
  String get serverPeopleEmailNotConfirmed => 'E-mail neconfirmat';

  @override
  String get serverPeopleConfirmEmail => 'Confirmă e-mailul';

  @override
  String serverPeopleConfirmEmailBody(String email, String name) {
    return 'Confirmi că $email aparține lui $name? Single sign-on va potrivi această adresă cu contul acestuia.';
  }

  @override
  String serverPeopleEmailConfirmed(String email) {
    return '$email a fost confirmat.';
  }

  @override
  String get runSandboxUnavailableTitle =>
      'Agenții au nevoie de un sandbox pe acest server';

  @override
  String get runSandboxUnavailable =>
      'Acest server nu are sandbox, deci doar proprietarul lui poate rula aici agenți. Proprietarul poate instala sandbox-ul sau poate dezactiva sandboxing-ul pentru toată lumea.';

  @override
  String get repoPathIssueHostPath =>
      'Acest folder este în afara spațiului de stocare al spațiului de lucru. Confirmă că acest server îl poate folosi.';

  @override
  String get repoPathIssueHostPathAskOwner =>
      'Acest folder este în afara spațiului de stocare al spațiului de lucru. Doar proprietarul serverului îl poate confirma.';

  @override
  String get repoPathIssueMissing =>
      'Nu mai există nimic la această cale de pe server. Șterge acest depozit și adaugă-l din nou din folderul său actual.';

  @override
  String get repoPathIssueUnusable =>
      'Acest folder nu poate fi folosit ca depozit. Șterge-l și adaugă depozitul dintr-un alt folder.';

  @override
  String get repoPathConfirm => 'Confirmă';

  @override
  String get repoPathConfirmAll => 'Confirmă toate';

  @override
  String repoPathConfirmAllTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count de foldere sunt în afara spațiului de stocare al spațiului de lucru',
      one: '1 folder este în afara spațiului de stocare al spațiului de lucru',
    );
    return '$_temp0';
  }

  @override
  String get repoPathConfirmAllBody =>
      'Confirmă că acest server le poate folosi. Fiecare depozit este verificat din nou cu accesul tău.';

  @override
  String repoCodeNeedsSignIn(String provider) {
    return 'Autentifică-te în $provider ca să vezi codul acestui depozit.';
  }

  @override
  String get repoCodeSignIn => 'Autentificare';

  @override
  String get ideContentSearchFailed => 'Nu s-a putut căuta în fișiere';

  @override
  String get ideWorktreeFileUnavailable =>
      'Acest fișier nu este disponibil în acest worktree.';

  @override
  String get ideChangesLoadFailed => 'Nu s-au putut încărca modificările';

  @override
  String repoCodeRepoReplacedOn(String forge) {
    return 'Această cale indică acum către un alt depozit de pe $forge. Un administrator al spațiului de lucru trebuie să îl reconecteze înainte de a putea fi folosit.';
  }

  @override
  String get backupRestoreServerOwnerOnly =>
      'Doar proprietarul serverului poate restaura copiile de rezervă. Le poți descărca în continuare.';

  @override
  String get terminalReadOnlyBadge => 'Doar citire';

  @override
  String get terminalReadOnlyHint =>
      'Poți urmări acest terminal, dar a scrie în el, a-i schimba dimensiunea sau a-l opri necesită acces de scriere la fiecare depozit din această conversație.';

  @override
  String get environmentOperateNeedsWrite =>
      'Poți vedea acest mediu, dar a-l porni, opri sau reporni necesită acces de scriere la fiecare depozit din această conversație.';

  @override
  String get environmentHostApprovalOwner =>
      'Rulează pe acest server. Aprobă-l ca să poată porni.';

  @override
  String get environmentHostApprovalMember =>
      'Rulează pe acest server. Proprietarul serverului trebuie să îl aprobe înainte să poată porni.';

  @override
  String get environmentHostApprove => 'Aprobă';

  @override
  String get environmentHostApproveNeedsAdmin =>
      'Aprobă-l ca administrator al spațiului de lucru: doar copia unui administrator arată valorile secrete, iar aprobarea le salvează înapoi.';

  @override
  String get environmentHostUnapproved =>
      'Proprietarul serverului nu a aprobat încă acest mediu, deci nu poate rula pe acest server.';

  @override
  String get environmentHostUnapprovedOwner =>
      'Nu ai aprobat încă acest mediu. Rulează pe acest server, deci pornește după ce aprobi definiția lui.';

  @override
  String get environmentHostApprovalReview => 'Revizuiește și aprobă';

  @override
  String spaceAccessNeedsSignIn(String provider) {
    return 'Autentifică-te în $provider ca să deschizi acest spațiu.';
  }

  @override
  String spaceAccessForgeCannotRead(String forge) {
    return 'Contul tău $forge nu poate citi un depozit folosit de acest spațiu.';
  }

  @override
  String get spaceAccessForgeCannotReadUnnamed =>
      'Contul tău de pe forge nu poate citi un depozit folosit de acest spațiu.';

  @override
  String get spaceAccessNoGrant =>
      'Nu ai acces de citire la un depozit folosit de acest spațiu. Un administrator al spațiului de lucru îți poate acorda acces.';

  @override
  String get spaceAccessFailed => 'Acest spațiu nu a putut fi deschis.';

  @override
  String get contextExplorerRefused =>
      'Defalcarea contextului nu este disponibilă în această sesiune.';

  @override
  String get repoLinkForgeRemoteRequired =>
      'Un depozit legat are nevoie atât de un proprietar, cât și de un nume de depozit.';

  @override
  String get repoCodeNoReadGrant =>
      'Nu ai acces de citire la acest depozit. Un administrator al spațiului de lucru îl poate acorda.';

  @override
  String get repoCodeNoWriteGrant =>
      'Poți citi acest depozit, dar nu îl poți modifica. Un administrator al spațiului de lucru poate acorda accesul de scriere.';

  @override
  String get repoCodeNoReviewGrant =>
      'Poți citi acest depozit, dar nu îl poți revizui. Un administrator al spațiului de lucru poate acorda accesul de revizuire.';

  @override
  String get rigWatchOnlyBadge => 'Doar vizualizare';

  @override
  String get rigWatchOnlyHint =>
      'Poți urmări această mașină. Controlarea ei, redirecționarea porturilor, lipirea în ea sau plasarea fișierelor pe ea necesită acces de scriere la toate depozitele din acest spațiu.';

  @override
  String get rigStartNeedsWrite =>
      'Pornirea unei mașini aici necesită acces de scriere la toate depozitele din acest spațiu. Un administrator al spațiului de lucru îl poate acorda.';

  @override
  String get rigViewRefused =>
      'Nu poți vedea această mașină. Aparține unui spațiu la care nu ai acces de citire.';

  @override
  String get rigPortsWatchOnly =>
      'Modificarea acestor porturi necesită acces de scriere la toate depozitele din acest spațiu.';

  @override
  String get rigHolderOnly =>
      'Doar persoana pentru care a fost deschisă această mașină o poate controla. Mașina folosește conectările proprii ale acesteia.';

  @override
  String get rigHolderOnlyHint =>
      'Poți urmări această mașină. Folosește conectările persoanei pentru care a fost deschisă, așa că doar ea poate controla mașina, redirecționa porturile ei, lipi conținut în ea sau plasa fișiere pe ea.';

  @override
  String get refusalStorageBusy =>
      'Baza de date a serverului este ocupată acum. Încearcă din nou peste puțin timp.';

  @override
  String get refusalStorageFull =>
      'Serverul nu mai are spațiu pe disc, așa că nimic nu poate fi salvat. Proprietarul serverului trebuie să elibereze spațiu.';

  @override
  String get refusalStorageDamaged =>
      'Datele acestui spațiu de lucru sunt deteriorate. Proprietarul serverului trebuie să le restaureze dintr-o copie de rezervă.';

  @override
  String get refusalStorageReadOnly =>
      'Acest spațiu de lucru este doar pentru citire până când proprietarul serverului îl restaurează dintr-o copie de rezervă, așa că modificările nu pot fi salvate.';

  @override
  String get refusalStorageNewerSchema =>
      'Aceste date au fost scrise de o versiune mai nouă a serverului. Actualizează serverul, apoi încearcă din nou.';

  @override
  String get refusalStorageForeignFile =>
      'Serverul a găsit un fișier de bază de date pe care nu l-a scris el. Proprietarul serverului trebuie să verifice folderul de date al serverului.';

  @override
  String get refusalWorkspaceDeleted => 'Acest spațiu de lucru a fost șters.';

  @override
  String get refusalIdempotencyInProgress =>
      'Această cerere este încă procesată. Așteaptă să se termine, apoi verifică rezultatul.';

  @override
  String get refusalImportMissingSource =>
      'Nu există niciun fișier la această cale pe server. Nimic nu a fost înlocuit.';

  @override
  String get refusalImportDamaged =>
      'Fișierul este deteriorat, așa că nu poate fi restaurat. Nimic nu a fost înlocuit.';

  @override
  String get refusalImportChecksumMismatch =>
      'Fișierul nu corespunde sumei de control înregistrate în copia de rezervă, așa că poate fi modificat sau deteriorat. Nimic nu a fost înlocuit.';

  @override
  String get refusalImportNewerSchema =>
      'Fișierul a fost scris de o versiune mai nouă a serverului. Actualizează serverul ca să-l restaurezi. Nimic nu a fost înlocuit.';

  @override
  String get refusalImportForeignFile =>
      'Fișierul nu este o bază de date de spațiu de lucru. Nimic nu a fost înlocuit.';

  @override
  String get refusalImportSchemaMismatch =>
      'Fișierul nu a putut fi adus la formatul acestui server. Nimic nu a fost înlocuit.';

  @override
  String get refusalImportRouteConflict =>
      'Fișierul conține linkuri care aparțin altui spațiu de lucru de pe acest server, iar restaurarea lui le-ar prelua. Nimic nu a fost înlocuit.';

  @override
  String get workspaceReadOnlyBannerTitle =>
      'Acest spațiu de lucru este doar pentru citire';

  @override
  String get workspaceReadOnlyBannerBody =>
      'Datele sale au eșuat la o verificare de integritate, așa că modificările nu pot fi salvate. Totul rămâne lizibil. Proprietarul serverului îl poate restaura dintr-o copie de rezervă.';

  @override
  String get workspaceReadOnlyBannerOwnerBody =>
      'Datele sale au eșuat la o verificare de integritate, așa că modificările nu pot fi salvate. Totul rămâne lizibil. Restaurează-l dintr-o copie de rezervă ca să poată fi din nou modificat.';

  @override
  String get workspaceReadOnlyBannerAction => 'Deschide copiile de rezervă';

  @override
  String get serverNoticesLabel => 'Necesită atenția ta';

  @override
  String get serverNoticeReadOnlyStatus => 'Doar citire';

  @override
  String serverNoticeSince(String time) {
    return 'Din $time';
  }

  @override
  String get serverNoticeReadOnlyBody =>
      'Baza sa de date a eșuat la o verificare de integritate, așa că permite doar citirea și refuză orice modificare. Restaureaz-o dintr-o copie de rezervă din listele de mai jos; ultima copie bună este păstrată până o faci.';

  @override
  String get serverNoticeDetails => 'Detalii';

  @override
  String get backupSnapshotUnverified => 'Neverificat';

  @override
  String get backupSnapshotUnverifiedNote =>
      'Acest snapshot nu poate fi verificat. Nu s-a încheiat niciodată sau a fost făcut înainte ca snapshot-urile să înregistreze sume de control, așa că nu poate restaura întreaga instalare. Fișierele spațiilor de lucru pe care le conține pot fi totuși restaurate unul câte unul.';

  @override
  String get backupSnapshotLastGoodCopy => 'Ultima copie bună';

  @override
  String get backupSnapshotLastGoodCopyNote =>
      'Păstrat pentru că conține ultima copie bună a unui spațiu de lucru deteriorat. Curățarea nu-l atinge până când spațiul de lucru respectiv este restaurat.';

  @override
  String get backupDeleteLastGoodCopyDescription =>
      'Aceasta este ultima copie bună a unui spațiu de lucru deteriorat. Dacă o ștergi, nu mai rămâne nimic din care să restaurezi spațiul de lucru respectiv.';

  @override
  String backupRestoreHeldBack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count de permisiuni au fost reținute pentru verificarea ta. Sunt listate în partea de sus a paginii.',
      few:
          '$count permisiuni au fost reținute pentru verificarea ta. Sunt listate în partea de sus a paginii.',
      one:
          '1 permisiune a fost reținută pentru verificarea ta. Este listată în partea de sus a paginii.',
    );
    return '$_temp0';
  }

  @override
  String get importHoldsLabel => 'Reținute din copiile restaurate';

  @override
  String get importHoldsExplainer =>
      'O copie restaurată nu poate acorda nimic pe acest server de una singură. Aceste permisiuni erau în ea: acceptă una ca să o acorzi din nou sau respinge-o ca s-o elimini.';

  @override
  String importHoldPolicyAllow(String action) {
    return 'Agenții pot face asta fără aprobare: $action';
  }

  @override
  String importHoldPolicyPrompt(String action) {
    return 'Agenții pot face asta după ce o persoană aprobă: $action';
  }

  @override
  String importHoldCommand(String command) {
    return 'Rulează comenzi care încep cu $command';
  }

  @override
  String get importHoldScopeWorkspace => 'Peste tot în acest spațiu de lucru';

  @override
  String importHoldScopeSpace(String space) {
    return 'În spațiul $space';
  }

  @override
  String importHoldScopeAgent(String agent) {
    return 'Pentru agentul $agent';
  }

  @override
  String importHoldSandboxExec(String path) {
    return 'Sandbox-urile pot rula $path';
  }

  @override
  String importHoldRepoWrite(String person, String repo) {
    return '$person poate modifica $repo';
  }

  @override
  String importHoldRepoReview(String person, String repo) {
    return '$person poate revizui pull request-urile din $repo';
  }

  @override
  String importHoldRepoOther(String person, String repo, String level) {
    return '$person are acces $level la $repo';
  }

  @override
  String importHoldMemberRole(String person, String role) {
    return '$person primește rolul $role';
  }

  @override
  String importHoldInvite(String role) {
    return 'O invitație deschisă pentru a intra cu rolul $role';
  }

  @override
  String importHoldInviteWithRepos(int count, String role) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'O invitație deschisă pentru a intra cu rolul $role și acces de revizuire sau scriere la $count de depozite',
      few:
          'O invitație deschisă pentru a intra cu rolul $role și acces de revizuire sau scriere la $count depozite',
      one:
          'O invitație deschisă pentru a intra cu rolul $role și acces de revizuire sau scriere la 1 depozit',
    );
    return '$_temp0';
  }

  @override
  String get importHoldUnknown =>
      'O permisiune pe care această versiune a aplicației nu o poate descrie';

  @override
  String importHoldRestoredAt(String time) {
    return 'Restaurat $time';
  }

  @override
  String get importHoldAccept => 'Acceptă';

  @override
  String get importHoldDismiss => 'Respinge';

  @override
  String get importHoldAcceptTitle => 'Acorzi această permisiune?';

  @override
  String importHoldAcceptBody(String permission) {
    return '$permission\n\nAcceptarea acordă asta imediat pe server.';
  }

  @override
  String get importHoldAccepted => 'Permisiune acordată.';

  @override
  String get importHoldNotApplied =>
      'Nimic nu a fost acordat: cel pentru care era nu mai există în acest spațiu de lucru.';

  @override
  String get mcpWorkspaceServers => 'Servere MCP ale spațiului de lucru';

  @override
  String get mcpWorkspaceServersDescription =>
      'Fiecare rulare de agent din acest spațiu de lucru primește uneltele acestor servere, atât în Claude Code, cât și în harness-ul integrat. Control Center se conectează la fiecare server și trimite mai departe uneltele sale.';

  @override
  String get mcpWorkspaceServersAdminsOnly =>
      'Doar administratorii spațiului de lucru pot vedea și modifica serverele MCP ale acestui spațiu de lucru.';

  @override
  String get mcpWorkspaceServersUnavailable =>
      'Serverele MCP ale spațiului de lucru nu sunt disponibile pe serverul conectat.';

  @override
  String get mcpWorkspaceServersEmpty =>
      'Încă nu există servere MCP ale spațiului de lucru';

  @override
  String get mcpWorkspaceServersEmptyDescription =>
      'Adaugă un server ca fiecare rulare de agent din acest spațiu de lucru să primească uneltele sale.';

  @override
  String get mcpAddServer => 'Adaugă server';

  @override
  String get mcpStatusAwaitingApproval => 'Se așteaptă aprobarea';

  @override
  String get mcpPublicAddressesOnly => 'Doar adrese publice';

  @override
  String get mcpApproveServer => 'Aprobă';

  @override
  String get mcpApprovalStdioOwner =>
      'Acest server rulează o comandă pe gazda serverului, ca utilizatorul serverului. Nu pornește până nu îl aprobi.';

  @override
  String get mcpApprovalStdioMember =>
      'Acest server rulează o comandă pe gazda serverului, așa că nu pornește până nu o aprobă proprietarul serverului.';

  @override
  String get mcpApprovalRemoteOwner =>
      'Acest server poate ajunge doar la adrese publice. Aprobă-l ca să poată ajunge și în rețeaua privată a gazdei, cum ar fi localhost și rețeaua locală.';

  @override
  String get mcpApprovalRemoteMember =>
      'Acest server poate ajunge doar la adrese publice până când îl aprobă proprietarul serverului.';

  @override
  String get mcpServersSettingsSubtitle =>
      'Serverul MCP integrat și serverele MCP ale căror unelte le primesc rulările de agent din acest spațiu de lucru.';

  @override
  String get mcpPersonalServers => 'Serverele tale MCP';

  @override
  String get mcpPersonalServersDescription =>
      'Doar tu vezi aceste servere, iar doar rulările de agent pe care le pornești în acest spațiu de lucru le primesc uneltele.';

  @override
  String get mcpPersonalServersUnavailable =>
      'Serverele tale MCP nu sunt disponibile pe serverul conectat.';

  @override
  String get mcpPersonalServersEmpty => 'Încă nu ai servere MCP';

  @override
  String get mcpPersonalServersEmptyDescription =>
      'Adaugă un server ca rulările de agent pe care le pornești în acest spațiu de lucru să primească uneltele lui.';

  @override
  String get mcpServerEditorPersonalOwner =>
      'Îl folosesc doar rulările pe care le pornești în acest spațiu de lucru. Ca proprietar al serverului, salvarea lui îl aprobă.';

  @override
  String get mcpServerEditorPersonalMember =>
      'Îl folosesc doar rulările pe care le pornești în acest spațiu de lucru. Poate ajunge doar la adrese publice.';

  @override
  String get mcpServerSignInNeeded =>
      'Autentifică-te ca să folosești uneltele acestui server.';

  @override
  String get mcpServerSignIn => 'Autentifică-te';

  @override
  String mcpServerSignInTitle(String name) {
    return 'Autentificare la $name';
  }

  @override
  String mcpServerSignInWrongCode(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mai ai $count de încercări.',
      few: 'Mai ai $count încercări.',
      one: 'Mai ai 1 încercare.',
    );
    return 'Nu este codul afișat de browser. $_temp0';
  }

  @override
  String get mcpServerSignInEnded =>
      'A durat prea mult, a fost refuzată sau ai introdus prea multe coduri greșite. Începe din nou ca să primești o pagină nouă de autentificare.';

  @override
  String get mcpServerSignInStartAgain => 'Începe din nou';

  @override
  String mcpServerSignedIn(String name) {
    return 'Te-ai autentificat la $name.';
  }

  @override
  String get mcpRemoveServer => 'Elimină serverul';

  @override
  String mcpRemoveServerTitle(String name) {
    return 'Ștergi $name?';
  }

  @override
  String get mcpRemoveServerBody =>
      'Rulările agenților pierd uneltele acestui server, iar valorile lui secrete salvate se șterg.';

  @override
  String mcpServerEnabledToggle(String name) {
    return 'Activează sau dezactivează $name';
  }

  @override
  String get mcpServerEditorAddTitle => 'Adaugă server MCP';

  @override
  String mcpServerEditorEditTitle(String name) {
    return 'Editează $name';
  }

  @override
  String get mcpServerNameHelper =>
      'Litere, cifre, cratime și liniuțe de subliniere. Agenții văd uneltele lui sub acest nume.';

  @override
  String get mcpServerNameInvalid =>
      'Folosește până la 24 de litere, cifre, cratime sau liniuțe de subliniere, începând cu o literă sau o cifră.';

  @override
  String get mcpServerNameTaken => 'Un alt server de aici are deja acest nume.';

  @override
  String get mcpServerTransportLabel => 'Tip de conexiune';

  @override
  String get mcpServerTransportStdio => 'Comandă';

  @override
  String get mcpServerTransportHttp => 'HTTP';

  @override
  String get mcpServerTransportSse => 'SSE';

  @override
  String get mcpServerCommandLabel => 'Comandă';

  @override
  String get mcpServerCommandRequired => 'Introdu comanda de rulat.';

  @override
  String get mcpServerArgsLabel => 'Argumente';

  @override
  String get mcpServerArgsHelper => 'Un argument pe linie.';

  @override
  String get mcpServerUrlLabel => 'URL';

  @override
  String get mcpServerUrlInvalid =>
      'Introdu un URL http sau https fără nume de utilizator, parolă sau #fragment.';

  @override
  String get mcpServerEnvLabel => 'Variabile de mediu';

  @override
  String get mcpServerHeadersLabel => 'Anteturi';

  @override
  String get mcpServerSecretsDescription =>
      'Valorile sunt salvate ca secrete și nu mai sunt afișate.';

  @override
  String get mcpServerHeadersExample =>
      'De exemplu, un antet Authorization cu un token bearer.';

  @override
  String get mcpServerEnvAdd => 'Adaugă variabilă';

  @override
  String get mcpServerHeaderAdd => 'Adaugă antet';

  @override
  String get mcpServerSecretValueHint => 'Valoare';

  @override
  String get mcpServerSecretNewValueHint => 'Valoare nouă';

  @override
  String get mcpServerSecretReplace => 'Înlocuiește valoarea';

  @override
  String get mcpServerSecretUndo => 'Anulează';

  @override
  String get mcpServerSecretRemovedOnSave => 'Se elimină la salvare';

  @override
  String mcpServerEnvNameInvalid(String name) {
    return '$name nu este un nume de variabilă valid. Folosește litere, cifre și liniuțe de subliniere, fără să începi cu o cifră.';
  }

  @override
  String mcpServerHeaderNameInvalid(String name) {
    return '$name nu poate fi setat. Folosește un nume de antet valid pe care conexiunea nu îl gestionează singură.';
  }

  @override
  String get mcpServerTransportDropsValues =>
      'Schimbarea transportului elimină valorile salvate.';

  @override
  String get mcpServerEnabledDescription =>
      'Când este oprit, serverul nu pornește și agenții nu îi văd uneltele.';

  @override
  String get mcpServerEditorStdioMember =>
      'Rulează pe gazda serverului, așa că nu pornește până nu îl aprobă proprietarul serverului. Schimbarea modului de pornire cere din nou aprobare.';

  @override
  String get mcpServerEditorRemoteMember =>
      'Poate ajunge doar la adrese publice până îl aprobă proprietarul serverului. Schimbarea modului de conectare cere din nou aprobare.';

  @override
  String get mcpServerEditorStdioOwner =>
      'Rulează pe gazda serverului ca utilizatorul serverului. Salvarea îl aprobă.';

  @override
  String get mcpServerEditorRemoteOwner =>
      'Salvarea îl aprobă ca să poată ajunge și în rețeaua privată a gazdei.';

  @override
  String get mcpServerRefusedInvalid =>
      'Control Center nu a putut salva acest server. Verifică setările lui și încearcă din nou.';

  @override
  String get mcpServerNotFound =>
      'Acest server nu mai există. Poate l-a eliminat cineva.';

  @override
  String get scriptToolCalls => 'Apeluri de instrumente';

  @override
  String scriptCallCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de apeluri',
      few: '$count apeluri',
      one: '1 apel',
    );
    return '$_temp0';
  }

  @override
  String scriptCallsRunning(int count) {
    return '$count în rulare';
  }

  @override
  String scriptCallsOk(int count) {
    return '$count reușite';
  }

  @override
  String scriptCallsFailed(int count) {
    return '$count eșuate';
  }

  @override
  String scriptCallsDenied(int count) {
    return '$count refuzate';
  }

  @override
  String scriptCallsCancelled(int count) {
    return '$count anulate';
  }

  @override
  String scriptCallsQueued(int count) {
    return '$count în coadă';
  }

  @override
  String scriptCallsSkipped(int count) {
    return '$count sărite';
  }

  @override
  String get scriptStepQueued => 'În coadă';

  @override
  String get scriptStepSkipped => 'Sărit';

  @override
  String get scriptGroupLoop => 'Buclă';

  @override
  String get scriptGroupEach => 'Pentru fiecare';

  @override
  String get scriptGroupParallel => 'În paralel';

  @override
  String get scriptGroupFunction => 'Funcție';

  @override
  String scriptCallsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Afișează $count de apeluri în plus',
      few: 'Afișează $count apeluri în plus',
      one: 'Afișează 1 apel în plus',
    );
    return '$_temp0';
  }

  @override
  String get scriptCallsUnplaced => 'Apeluri nepoziționate în script';

  @override
  String get scriptToolComputed => 'Instrument';

  @override
  String scriptStepSemantics(String subject, String state) {
    return '$subject, $state';
  }

  @override
  String get scriptSourceLabel => 'Script';

  @override
  String scriptSourceLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de linii',
      few: '$count linii',
      one: '1 linie',
    );
    return '$_temp0';
  }

  @override
  String get scriptStateRunning => 'În rulare';

  @override
  String get scriptStateCompleted => 'Finalizat';

  @override
  String get scriptStateFailed => 'Eșuat';

  @override
  String get scriptStateTimedOut => 'Timpul a expirat';

  @override
  String get scriptStateCancelled => 'Anulat';

  @override
  String get scriptStateMemoryExceeded => 'Memorie insuficientă';

  @override
  String get scriptStateOutputExceeded => 'Prea multă ieșire';

  @override
  String get scriptStateSandboxError => 'Eroare sandbox';

  @override
  String get scriptStateRefused => 'Refuzat';

  @override
  String get transcriptToolDenied => 'Refuzat';

  @override
  String get transcriptStatusRunningScript => 'Se rulează un script…';

  @override
  String get scriptOriginLine => 'Dintr-un script pe care îl rulează agentul';

  @override
  String get scriptOriginShow => 'Afișează scriptul';

  @override
  String get codeModeTitle => 'Mod cod';

  @override
  String get codeModeSubtitle =>
      'Agenții pot scrie un script scurt care apelează instrumentele lor, în loc să le apeleze unul câte unul.';

  @override
  String get codeModeStatusLabel => 'Stare';

  @override
  String get codeModeFactAvailability => 'Pe acest server';

  @override
  String get codeModeAvailable => 'Disponibil';

  @override
  String get codeModeUnavailable => 'Indisponibil';

  @override
  String get codeModeFactRunner => 'Runner';

  @override
  String codeModeUnavailableNote(String reason) {
    return 'Acest server nu poate rula scripturi, deci agenții de aici apelează instrumentele unul câte unul. Serverul spune: $reason';
  }

  @override
  String get codeModeNoReason => 'nu a fost dat niciun motiv.';

  @override
  String get codeModeViewExecutions => 'Vezi execuțiile de cod';

  @override
  String get codeModeLimitsLabel => 'Limite';

  @override
  String get codeModeLimitsSubtitle =>
      'Cât de mult și cât de departe poate merge un script. Valorile implicite se potrivesc majorității spațiilor de lucru.';

  @override
  String get codeModeLimitsDisclosure => 'Ajustează limitele';

  @override
  String get codeModeLimitsAtDefaults => 'Implicite';

  @override
  String codeModeLimitsChangedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de modificate',
      few: '$count modificate',
      one: '1 modificată',
    );
    return '$_temp0';
  }

  @override
  String get codeModeLimitsUseDefaults => 'Folosește valorile implicite';

  @override
  String get codeModeLimitWallClock => 'Timp per script';

  @override
  String get codeModeLimitWallClockHelp =>
      'Timpul petrecut așteptând o persoană nu se numără.';

  @override
  String get codeModeLimitCpu => 'Timp de procesor';

  @override
  String get codeModeLimitCpuHelp =>
      'Timpul pe care scriptul însuși îl petrece calculând.';

  @override
  String get codeModeLimitHeap => 'Memorie';

  @override
  String get codeModeLimitHeapHelp =>
      'Memoria pe care o poate folosi scriptul în timpul rulării.';

  @override
  String get codeModeLimitNestedCalls => 'Apeluri de instrumente per script';

  @override
  String get codeModeLimitNestedCallsHelp =>
      'Apelurile peste această limită sunt refuzate, iar scriptul este informat din ce motiv.';

  @override
  String get codeModeLimitInFlight => 'Apeluri simultane';

  @override
  String get codeModeLimitInFlightHelp =>
      'Apelurile pe care un script le poate avea în rulare în același timp.';

  @override
  String get codeModeLimitOutputTokens => 'Ieșirea citită de agent';

  @override
  String get codeModeLimitOutputTokensHelp =>
      'Ieșirea mai lungă este scurtată; agentul poate citi restul la cerere.';

  @override
  String codeModeLimitRange(String defaultValue, String min, String max) {
    return 'Implicit $defaultValue. De la $min la $max.';
  }

  @override
  String codeModeLimitOutOfRange(String min, String max) {
    return 'Introdu un număr întreg de la $min la $max.';
  }

  @override
  String get codeModeSuffixSeconds => 's';

  @override
  String get codeModeSuffixMebibytes => 'MiB';

  @override
  String get codeModeSuffixCalls => 'apeluri';

  @override
  String get codeModeSuffixTokens => 'tokeni';

  @override
  String codeModeServerCap(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Acest server rulează cel mult $count de scripturi odată, pe toate spațiile de lucru.',
      few:
          'Acest server rulează cel mult $count scripturi odată, pe toate spațiile de lucru.',
      one:
          'Acest server rulează cel mult 1 script odată, pe toate spațiile de lucru.',
    );
    return '$_temp0';
  }

  @override
  String codeModeUnitMilliseconds(String value) {
    return '$value ms';
  }

  @override
  String codeModeUnitSeconds(String value) {
    return '$value s';
  }

  @override
  String codeModeUnitMinutesSeconds(String minutes, String seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String get codeModeRefusedLimitUnknown =>
      'Serverul nu cunoaște una dintre aceste limite.';

  @override
  String get codeModeRefusedLimitOutOfRange =>
      'Una dintre aceste limite este în afara intervalului permis de server.';

  @override
  String get codeModeRefusedUnknownSetting =>
      'Serverul nu a recunoscut această setare.';

  @override
  String get codeExecutionsTitle => 'Execuții de cod';

  @override
  String get codeExecutionsSubtitle =>
      'Scripturile rulate de agenți în acest spațiu de lucru, cu fiecare apel de instrument făcut de ele.';

  @override
  String get codeExecutionsEmpty => 'Încă nu a rulat niciun script aici.';

  @override
  String get codeExecutionsEmptyFiltered =>
      'Niciun script nu corespunde acestor filtre.';

  @override
  String get codeExecutionsStatusFilter => 'Rezultat';

  @override
  String get codeExecutionsAllOutcomes => 'Toate rezultatele';

  @override
  String codeExecutionsOutcomeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de rezultate',
      few: '$count rezultate',
      one: '1 rezultat',
    );
    return '$_temp0';
  }

  @override
  String get codeExecutionsScopeRun => 'Scripturi dintr-o rulare';

  @override
  String get codeExecutionsScopeConversation => 'Scripturi dintr-o conversație';

  @override
  String get codeExecutionsScopeAgent => 'Scripturi de la un agent';

  @override
  String get codeExecutionsShowAll => 'Arată tot';

  @override
  String get codeExecutionUntitled => 'Script fără titlu';

  @override
  String get codeExecutionRecord => 'Înregistrare';

  @override
  String get codeExecutionBackToList => 'Înapoi la execuțiile de cod';

  @override
  String get codeExecutionNotFound =>
      'Această execuție de cod nu se află în acest spațiu de lucru. Poate că a fost eliminată odată cu rularea sa.';

  @override
  String get codeExecutionRefusedSpace =>
      'Acest script a rulat într-un spațiu pe care nu îl poți deschide, deci înregistrarea sa rămâne ascunsă.';

  @override
  String get codeExecutionOpenRecord => 'Deschide înregistrarea';

  @override
  String get codeExecutionFactStarted => 'Pornit';

  @override
  String get codeExecutionFactDuration => 'Durată';

  @override
  String get codeExecutionFactCalls => 'Apeluri de instrumente';

  @override
  String get codeExecutionFactAgent => 'Agent';

  @override
  String get codeExecutionFactSurface => 'Rulat prin';

  @override
  String get codeExecutionSurfaceHarness => 'Agent încorporat';

  @override
  String get codeExecutionSurfaceMcp => 'Agent extern';

  @override
  String get codeExecutionFactCpu => 'Timp de procesor';

  @override
  String get codeExecutionFactMemory => 'Memorie de vârf';

  @override
  String get codeExecutionOpenConversation => 'Deschide conversația';

  @override
  String get codeExecutionRunScripts => 'Scripturi din această rulare';

  @override
  String get codeExecutionAgentScripts => 'Scripturi ale acestui agent';

  @override
  String get codeExecutionScript => 'Script';

  @override
  String get codeExecutionConsole => 'Consolă';

  @override
  String get codeExecutionOutputTruncated =>
      'Ieșirea a fost tăiată pentru a încăpea în ce se păstrează.';

  @override
  String get codeExecutionNoPayload =>
      'Scriptul și ieșirea lui nu mai sunt păstrate.';

  @override
  String codeExecutionCallsHeading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de apeluri de instrumente',
      few: '$count apeluri de instrumente',
      one: '1 apel de instrument',
      zero: 'Apeluri de instrumente',
    );
    return '$_temp0';
  }

  @override
  String get codeExecutionNoCalls => 'Scriptul nu a apelat niciun instrument.';

  @override
  String get codeExecutionCallCompleted => 'Finalizat';

  @override
  String get codeExecutionCallFailed => 'Eșuat';

  @override
  String get codeExecutionCallDenied => 'Refuzat';

  @override
  String get codeExecutionCallCancelled => 'Anulat';

  @override
  String get codeExecutionCallTimedOut => 'Timpul a expirat';

  @override
  String get codeExecutionCallUnknownTool => 'Instrument necunoscut';

  @override
  String get codeExecutionCallInvalidArgs => 'Argumente nevalide';

  @override
  String get codeExecutionGateAllowed => 'Permis';

  @override
  String get codeExecutionGateApproved => 'Aprobat de o persoană';

  @override
  String get codeExecutionGateDenied => 'Refuzat';

  @override
  String get codeExecutionGateNotReached => 'Nu a fost verificat';

  @override
  String codeExecutionCallWaited(String duration) {
    return 'A așteptat $duration o persoană';
  }

  @override
  String get codeExecutionCallArguments => 'Argumente';

  @override
  String get codeExecutionCallResult => 'Rezultat';

  @override
  String codeExecutionCallResultSize(String size) {
    return 'A returnat $size';
  }

  @override
  String codeExecutionBytes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de octeți',
      few: '$count octeți',
      one: '1 octet',
    );
    return '$_temp0';
  }

  @override
  String get codeExecutionEndedScriptError =>
      'Scriptul a aruncat o eroare, iar nimic nu a prins-o.';

  @override
  String codeExecutionEndedScriptErrorNamed(String name) {
    return 'Scriptul a aruncat $name, iar nimic nu a prins-o.';
  }

  @override
  String get codeExecutionEndedStalled =>
      'Scriptul a așteptat ceva ce nu se putea încheia niciodată.';

  @override
  String get codeExecutionEndedCpu =>
      'Scriptul și-a consumat timpul de procesor.';

  @override
  String get codeExecutionEndedHeap => 'Scriptul a atins limita sa de memorie.';

  @override
  String get codeExecutionEndedOutput =>
      'Scriptul a produs mai multă ieșire decât este permis.';

  @override
  String get codeExecutionEndedDeadline => 'Scriptul a rămas fără timp.';

  @override
  String get codeExecutionEndedCancelled =>
      'Scriptul a fost anulat înainte de a se termina.';

  @override
  String get codeExecutionEndedShutdown =>
      'Serverul s-a oprit în timp ce rula scriptul.';

  @override
  String get codeExecutionEndedServerStopped =>
      'Serverul s-a oprit în timp ce rula scriptul. Înregistrarea a fost închisă la următoarea pornire a serverului.';

  @override
  String get codeExecutionEndedInternal =>
      'Programul care rulează scripturile a eșuat dintr-o eroare internă.';

  @override
  String get codeExecutionEndedStart =>
      'Programul care rulează scripturile nu a putut porni.';

  @override
  String get codeExecutionEndedLockdown =>
      'Programul care rulează scripturile nu s-a putut restricționa, așa că scriptul nu a fost rulat.';

  @override
  String get codeExecutionEndedExited =>
      'Programul care rulează scripturile s-a oprit înainte ca scriptul să se termine.';

  @override
  String get codeExecutionEndedRunnerBrokeRules =>
      'Programul care rulează scripturile a încălcat regulile de funcționare și a fost oprit.';

  @override
  String get codeExecutionEndedUnresponsive =>
      'Programul care rulează scripturile nu mai răspunde și a fost oprit.';

  @override
  String get codeExecutionEndedHostError =>
      'Serverul a eșuat în timpul rulării scriptului.';

  @override
  String get codeExecutionRunningNote =>
      'Încă în rulare. Apelurile sale de instrumente apar aici pe măsură ce se termină, iar rezultatul la final.';

  @override
  String codeModeServerWorkspaceShare(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Scripturile unui spațiu de lucru folosesc cel mult $count dintre ele.',
      few:
          'Scripturile unui spațiu de lucru folosesc cel mult $count dintre ele.',
      one: 'Scripturile unui spațiu de lucru folosesc cel mult 1 dintre ele.',
    );
    return '$_temp0';
  }

  @override
  String get wakeOriginGoal => 'Obiectiv';

  @override
  String get wakeOriginGoalCheck => 'Verificare obiectiv';

  @override
  String get wakeOriginGoalReview => 'Revizuire obiectiv';

  @override
  String get wakeOriginSchedule => 'Program';

  @override
  String get wakeOriginWatch => 'Urmărire';

  @override
  String wakeOriginReplyFrom(String agent) {
    return 'Răspuns de la $agent';
  }

  @override
  String get wakeOriginReply => 'Răspuns';

  @override
  String wakeOriginMessageFrom(String agent) {
    return 'Mesaj de la $agent';
  }

  @override
  String get wakeOriginMessage => 'Mesaj';

  @override
  String wakeOriginWorkFinishedBy(String agent) {
    return 'Lucru terminat de $agent';
  }

  @override
  String get wakeOriginWorkFinished => 'Lucru terminat';

  @override
  String get wakeOriginLimitReset => 'Limită resetată';

  @override
  String get wakeOriginRecovery => 'Recuperare';

  @override
  String get wakeOriginAssignment => 'Atribuire';

  @override
  String get wakeOriginPipelineStep => 'Pas de pipeline';

  @override
  String get wakeOriginImprovementReview => 'Revizuire de îmbunătățiri';

  @override
  String get wakeKindStopped => 'Reținută deoarece o persoană a oprit rularea.';

  @override
  String get wakeKindAttempts => 'Livrarea a eșuat de trei ori.';

  @override
  String get wakeKindAgentDeleted => 'Agentul nu mai există.';

  @override
  String get wakeKindAgentNotDispatchable => 'Agentul este retras.';

  @override
  String get wakeKindAgentPaused => 'Agentul este pus pe pauză.';

  @override
  String get wakeKindPersonRemoved =>
      'Persoana în numele căreia acționează a părăsit spațiul de lucru.';

  @override
  String get wakeKindBudgetBlocked => 'Un buget blochează o rulare.';

  @override
  String get wakeKindTakeOver => 'O persoană a preluat worktree-ul.';

  @override
  String get wakeKindRateCapConversation =>
      'Această conversație a pornit 30 de rulări din treziri în ultima oră.';

  @override
  String get wakeKindRateCapWorkspace =>
      'Acest spațiu de lucru a pornit 300 de rulări din treziri în ultima oră.';

  @override
  String get wakeKindLiveRunNoInput =>
      'Rularea live a agentului de aici nu primește intrare.';

  @override
  String get wakeKindLiveRunOtherOptions =>
      'Rularea live a agentului de aici rulează altfel, deci aceasta pornește propria rulare după ea.';

  @override
  String get wakeKindLiveRunOtherPerson =>
      'Rularea live a agentului de aici acționează pentru altcineva, deci aceasta pornește propria rulare după ea.';

  @override
  String get wakeKindDispatchRefused => 'Rularea nu a putut porni.';

  @override
  String get wakeKindSandboxUnavailable =>
      'Niciun sandbox nu este disponibil pentru o rulare doar în citire.';

  @override
  String get wakeKindReadOnlyUnavailable =>
      'Backend-ul acestui agent nu poate menține o rulare doar în citire.';

  @override
  String get wakeKindServerStopped =>
      'O repornire a serverului a oprit rularea.';

  @override
  String get wakeKindServerRestarted =>
      'Serverul a fost repornit în timpul rulării unei persoane.';

  @override
  String get wakeKindGuardFailed => 'O verificare înainte de livrare a eșuat.';

  @override
  String get wakeKindLimit =>
      'Se așteaptă până la limita de utilizare a providerului.';

  @override
  String get wakeKindLimitRunLive =>
      'Se așteaptă ca rularea de la limita de utilizare să se încheie.';

  @override
  String get wakeKindWakeMissed => 'Ratată cât timp serverul a fost oprit.';

  @override
  String get wakeKindPipelineRunEnded => 'Rularea sa de pipeline s-a încheiat.';

  @override
  String get wakeKindGoalEnded => 'Obiectivul său s-a încheiat.';

  @override
  String get wakeKindGoalBudgetExhausted =>
      'Obiectivul său și-a consumat bugetul.';

  @override
  String get wakeKindGoalReviewStale =>
      'Obiectivul s-a schimbat de la cererea acestei revizuiri.';

  @override
  String get wakeKindGoalPaused => 'Obiectivul său este pus pe pauză.';

  @override
  String get wakeKindGoalHeld => 'Obiectivul său este reținut.';

  @override
  String get wakeKindGoalStopped => 'Obiectivul său a fost oprit.';

  @override
  String get wakeKindAskSettled =>
      'Întrebarea la care răspunde a fost deja rezolvată.';

  @override
  String get wakeKindRuleEnded => 'Programul său s-a încheiat.';

  @override
  String get wakeKindUnknown =>
      'Pentru un motiv pe care această versiune nu îl numește:';

  @override
  String wakeStripHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de treziri în așteptare',
      few: '$count treziri în așteptare',
      one: '1 trezire în așteptare',
    );
    return '$_temp0';
  }

  @override
  String wakeStripDue(String time) {
    return 'Scadentă $time';
  }

  @override
  String get wakeStripDueNow => 'Scadentă acum';

  @override
  String get wakeStripHeld => 'Reținută';

  @override
  String wakeStripExpires(String time) {
    return 'Expiră $time';
  }

  @override
  String wakeStripAttempt(int attempt) {
    return 'Încercarea $attempt';
  }

  @override
  String get wakeStripCancel => 'Anulează trezirea';

  @override
  String get wakeStripDeliverNow => 'Livrează acum';

  @override
  String get wakeStripResume => 'Reia';

  @override
  String get wakeStripDismiss => 'Renunță';

  @override
  String get wakeStripResumeAll => 'Reia toate';

  @override
  String get wakeStripResumeOnlyTheirs =>
      'Doar persoana a cărei rulare este aceasta o poate relua.';

  @override
  String get wakeReceiptStarted => 'A pornit o rulare.';

  @override
  String get wakeReceiptPushed => 'Predată rulării live.';

  @override
  String wakeReceiptWaiting(String reason) {
    return 'Încă în așteptare. $reason';
  }

  @override
  String wakeReceiptSkipped(String reason) {
    return 'Nelivrată. $reason';
  }

  @override
  String get wakeReceiptDuplicate => 'Deja livrată.';

  @override
  String wakeReleased(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Au fost reluate $count de treziri.',
      few: 'Au fost reluate $count treziri.',
      one: 'A fost reluată 1 trezire.',
      zero: 'Nimic nu a fost reluat.',
    );
    return '$_temp0';
  }

  @override
  String get wakeRefusalNotYours =>
      'Această trezire acționează pentru altă persoană. Doar ea o poate livra sau relua.';

  @override
  String get wakeRefusalSettled => 'Această trezire s-a încheiat deja.';

  @override
  String heldSteeringHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de mesaje reținute',
      few: '$count mesaje reținute',
      one: '1 mesaj reținut',
    );
    return '$_temp0';
  }

  @override
  String get heldSteeringResume => 'Trimite mesajele reținute';

  @override
  String get heldSteeringDelete => 'Șterge mesajul reținut';

  @override
  String heldSteeringReleased(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Au fost trimise $count de mesaje reținute.',
      few: 'Au fost trimise $count mesaje reținute.',
      one: 'A fost trimis 1 mesaj reținut.',
      zero: 'Nimic nu a fost reținut.',
    );
    return '$_temp0';
  }

  @override
  String get workAgentUnknown => 'un agent';

  @override
  String workFeedWoke(int count, String agent) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'A trezit $agent pentru $count de elemente în așteptare',
      few: 'A trezit $agent pentru $count elemente în așteptare',
      one: 'A trezit $agent',
    );
    return '$_temp0';
  }

  @override
  String workFeedWakeSkipped(String agent) {
    return 'O trezire pentru $agent nu a fost livrată.';
  }

  @override
  String workFeedWakeMissed(String agent) {
    return 'O trezire pentru $agent a fost ratată cât timp serverul era oprit.';
  }

  @override
  String workFeedScheduleCreated(String agent) {
    return 'Program setat pentru $agent.';
  }

  @override
  String workFeedScheduleEnded(String agent) {
    return 'Programul pentru $agent s-a încheiat.';
  }

  @override
  String get workFeedOpenSchedule => 'Deschide programul';

  @override
  String workFeedNoteFromAgent(String agent) {
    return '$agent și-a lăsat această notă, în propriile cuvinte:';
  }

  @override
  String get workFeedNoteFromPerson => 'Un memento setat de o persoană:';

  @override
  String workFeedLimitParkHeld(String provider, String time) {
    return 'Pus pe pauză la limita de utilizare a $provider. Limita se resetează la $time.';
  }

  @override
  String workFeedLimitParkPending(String provider, String time) {
    return 'Pus pe pauză la limita de utilizare a $provider. Se reia la $time.';
  }

  @override
  String workFeedLimitParkResumed(String provider) {
    return 'Reluat după limita de utilizare a $provider.';
  }

  @override
  String workFeedLimitParkGone(String provider) {
    return 'Nu mai așteaptă la limita de utilizare a $provider.';
  }

  @override
  String get workFeedLimitParkResume => 'Reia';

  @override
  String get workFeedLimitParkCancel => 'Anulează';

  @override
  String workFeedStillInFlight(String agent) {
    return 'Starea predată $agent după compactare';
  }

  @override
  String get workFeedShowDetails => 'Arată detaliile';

  @override
  String get workFeedHideDetails => 'Ascunde detaliile';

  @override
  String get workFeedCommandRefused => 'Comanda a fost refuzată.';

  @override
  String get wakeRuleEndFired => 'A rulat o singură dată.';

  @override
  String get wakeRuleEndExpired => 'A ajuns la data de sfârșit.';

  @override
  String get wakeRuleEndRunCap => 'Și-a consumat rulările.';

  @override
  String get wakeRuleEndCostCap => 'A ajuns la plafonul de cost.';

  @override
  String get wakeRuleEndGoalEnded => 'Obiectivul său s-a încheiat.';

  @override
  String get wakeRuleEndCancelled => 'A fost anulat.';

  @override
  String get wakeRuleEndMemberRemoved =>
      'Persoana sa a părăsit spațiul de lucru.';

  @override
  String get wakeRuleEndInvalidRow => 'Setările salvate nu au putut fi citite.';

  @override
  String get wakeRuleRefusalIntervalTooShort =>
      'Intervalul este prea scurt. Alege unul mai lung.';

  @override
  String get wakeRuleRefusalTooSoon =>
      'Ora aceasta este prea devreme. Alege una mai târziu.';

  @override
  String get wakeRuleRefusalLineageEnded =>
      'Acest lanț de treziri și-a consumat rulările sau timpul.';

  @override
  String get wakeRuleRefusalWatchTargetUnreadable =>
      'Nu poți citi ce ar urmări asta.';

  @override
  String get wakeRuleRefusalExpiryRequired =>
      'Stabilește un sfârșit, de exemplu --days 3.';

  @override
  String get wakeRuleRefusalLimitReached =>
      'Această conversație are deja câte programe i se permit.';

  @override
  String get wakeRuleRefusalInvalidWhen => 'Ora nu poate fi citită.';

  @override
  String get wakeRuleRefusalNoteTooLong => 'Nota este prea lungă.';

  @override
  String get wakeRuleRefusalExpiryTooLong => 'Sfârșitul este prea departe.';

  @override
  String get wakeRuleRefusalLimitOutOfRange =>
      'O limită de rulări, zile sau buget este în afara intervalului.';

  @override
  String get wakeRuleRefusalNextOutsideLoop =>
      'Doar o buclă își poate alege singură următoarea oră.';

  @override
  String get wakeRuleRefusalWatchRefused => 'Asta nu poate fi urmărită.';

  @override
  String get wakeRuleRefusalRuleEnded => 'Acest program s-a încheiat deja.';

  @override
  String get wakeRuleRefusalNotYours => 'Acest program aparține altcuiva.';

  @override
  String get workRefusalUnknown => 'Serverul a refuzat acest lucru:';

  @override
  String get goalRefusalAlreadyActive =>
      'Această conversație are deja un obiectiv activ.';

  @override
  String get goalRefusalNotInReview => 'Acest obiectiv nu așteaptă revizuire.';

  @override
  String get goalRefusalEvidenceIncomplete =>
      'Dovezile obiectivului sunt incomplete.';

  @override
  String get goalRefusalClaimPending =>
      'Afirmația că este terminat este încă verificată.';

  @override
  String get goalRefusalNotActiveSegment =>
      'Acest obiectiv nu are niciun segment în rulare.';

  @override
  String get goalRefusalNotYours =>
      'Doar persoana care a pornit acest obiectiv poate face asta.';

  @override
  String get goalRefusalNotPaused => 'Pune mai întâi obiectivul pe pauză.';

  @override
  String get goalRefusalContractInvalid =>
      'Contractul obiectivului nu poate fi citit.';

  @override
  String get goalRefusalCheckerUnknown => 'Niciun agent nu are acest nume.';

  @override
  String get goalRefusalCheckerAmbiguous =>
      'Mai mulți agenți au acest nume. Folosește id-ul lui.';

  @override
  String get goalRefusalCheckerIsGoalAgent =>
      'Verificatorul trebuie să fie alt agent decât cel care face lucrul.';

  @override
  String get goalRefusalCommandInvalid =>
      'Această comandă /goal nu poate fi citită.';

  @override
  String goalCardWorking(int segment) {
    return 'Lucrează · segmentul $segment';
  }

  @override
  String get goalCardWaiting => 'Așteaptă următoarea trezire';

  @override
  String get goalCardVerifying => 'Se verifică dacă este terminat';

  @override
  String goalCardLimitUntil(String time) {
    return 'Pus pe pauză la limita de utilizare · se reia la $time';
  }

  @override
  String get goalCardLimit => 'Pus pe pauză la limita de utilizare';

  @override
  String get goalCardPerson => 'Are nevoie de o persoană';

  @override
  String get goalCardByPerson => 'Pus pe pauză de o persoană';

  @override
  String get goalCardNeedsReview =>
      'Așteaptă revizuire: spune că este terminat, iar nimic nu a confirmat asta';

  @override
  String goalCardSegments(int run, int max) {
    return 'Segmentul $run din $max';
  }

  @override
  String goalCardSegmentsNoCap(int run) {
    return 'Segmentul $run';
  }

  @override
  String goalCardMoney(String spent, String cap) {
    return '$spent din $cap';
  }

  @override
  String goalCardTimeLeft(String time) {
    return '$time rămase';
  }

  @override
  String get goalCardOverdue => 'Depășit termenul';

  @override
  String get goalCardDoneMeans => 'Terminat înseamnă';

  @override
  String get goalCardChecks => 'Verificări';

  @override
  String get goalCardCheckPassed => 'Promovată';

  @override
  String goalCardCheckFailed(int code) {
    return 'Eșuată · cod de ieșire $code';
  }

  @override
  String get goalCardCheckTimedOut => 'Timpul a expirat';

  @override
  String get goalCardCheckNotRerun => 'Nerulată din nou: nimic nu s-a schimbat';

  @override
  String get goalCardCheckBroken => 'Nu poate rula';

  @override
  String get goalCardCheckNotRun => 'Nerulată încă';

  @override
  String get goalCardCriterionMet => 'Îndeplinit';

  @override
  String get goalCardCriterionUnmet => 'Neîndeplinit';

  @override
  String get goalCardCriterionCannotTell => 'Nu se poate spune';

  @override
  String get goalCardVerdictPass => 'Ultima verificare: terminat';

  @override
  String get goalCardVerdictFail => 'Ultima verificare: nu este terminat';

  @override
  String get goalCardVerdictCannotVerify =>
      'Ultima verificare: nu s-a putut stabili';

  @override
  String get goalCardConcerns => 'Îngrijorări';

  @override
  String goalCardVerifiedBy(String agent) {
    return 'Verificat de $agent';
  }

  @override
  String get goalCardVerifiedBySelf =>
      'Verificat de el însuși (fără verificator separat)';

  @override
  String get goalCardClosedByPerson =>
      'Închis de o persoană fără o verificare reușită';

  @override
  String get goalCardNoMachineCheck => 'Nicio verificare automată';

  @override
  String get goalCardAddCheck => 'Adaugă o verificare';

  @override
  String get goalCardOpen => 'Deschide obiectivul';

  @override
  String get goalCardApprove => 'Aprobă finalizarea';

  @override
  String get goalCardApproveTitle => 'Închizi acest obiectiv ca terminat?';

  @override
  String get goalCardApproveBody =>
      'Nicio verificare nu l-a confirmat. Îl închizi pe cuvântul tău, iar obiectivul înregistrează că o persoană l-a închis neverificat.';

  @override
  String get goalCardApproveConfirm => 'Închide ca terminat';

  @override
  String get goalCardResumeNotYours =>
      'Reluarea lui sau mărirea bugetului aparțin celui care l-a pornit.';

  @override
  String get goalHoldDetailStalled => 'Niciun progres în ultimele segmente.';

  @override
  String get goalHoldDetailStalledWaiting =>
      'Se așteaptă, după segmente fără progres.';

  @override
  String get goalHoldDetailVerificationFailed => 'Ultima verificare a eșuat.';

  @override
  String get goalHoldDetailCannotVerify =>
      'Verificatorul nu a putut stabili dacă este terminat.';

  @override
  String get goalHoldDetailSandboxUnavailable =>
      'Nu este disponibil niciun sandbox pentru a-și rula verificările.';

  @override
  String get goalHoldDetailCheckerUnavailable =>
      'Agentul verificator nu este disponibil. Alege alt verificator, apoi reia.';

  @override
  String get goalHoldDetailCheckBroken => 'Această verificare nu poate rula:';

  @override
  String get goalHoldDetailWakeSkipped => 'Trezirea sa nu a fost livrată.';

  @override
  String get goalHoldDetailClaimPending =>
      'Afirmația sa că este terminat așteaptă o verificare.';

  @override
  String get goalHoldDetailUnanswered =>
      'O întrebare sau o cerere de aprobare adresată unei persoane a rămas fără răspuns.';

  @override
  String get goalHoldDetailLimitParks =>
      'A atins limitele de utilizare prea des. Verifică-l, apoi reia.';

  @override
  String get goalHoldDetailInput => 'Se așteaptă un răspuns în conversație.';

  @override
  String get peerAsksSection => 'Întrebări';

  @override
  String peerAskTo(String agent) {
    return 'Către $agent';
  }

  @override
  String get peerAskKindAsk => 'Întrebare';

  @override
  String get peerAskKindConsult => 'Consultare';

  @override
  String get peerAskKindReview => 'Revizuire';

  @override
  String get peerAskStatusPending => 'În așteptare';

  @override
  String get peerAskStatusAnswered => 'Cu răspuns';

  @override
  String get peerAskStatusFailed => 'Eșuată';

  @override
  String get peerAskStatusExpired => 'Expirată';

  @override
  String get peerAskStatusCancelled => 'Anulată';

  @override
  String peerAskAsked(String time) {
    return 'Întrebată $time';
  }

  @override
  String peerAskExpires(String time) {
    return 'Expiră $time';
  }

  @override
  String get peerAskPromised => 'A promis un răspuns';

  @override
  String get peerAskBackground => 'În fundal';

  @override
  String get peerAskCancel => 'Anulează întrebarea';

  @override
  String get peerAskAlreadySettled => 'Această întrebare s-a încheiat deja.';

  @override
  String get slashHintGoal =>
      'Lucrează spre un obiectiv până este terminat. Opțiuni: --check, --checker, --fresh, --unattended';

  @override
  String get slashHintLoop =>
      'Repetă o sarcină, la un interval sau în ritmul agentului';

  @override
  String get slashHintSchedule =>
      'Rulează o sarcină mai târziu: in 2h, at 09:00 sau cu cron';

  @override
  String get slashHintRefine =>
      'Revizuiește lucrul din această conversație și propune îmbunătățiri';

  @override
  String get notifGoalCompleted => 'Obiectiv terminat';

  @override
  String get notifGoalFailed => 'Obiectiv eșuat';

  @override
  String get notifGoalCancelled => 'Obiectiv anulat';

  @override
  String get notifGoalBudgetExhausted => 'Obiectivul și-a consumat bugetul';

  @override
  String get notifGoalNeedsReview => 'Un obiectiv așteaptă revizuirea ta';

  @override
  String get notifGoalNeedsPerson => 'Un obiectiv are nevoie de tine';

  @override
  String get notifGoalOnHold => 'Un obiectiv este reținut';

  @override
  String get notifWakeRuleEnded => 'Un program s-a încheiat';

  @override
  String notifWaitingDigest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de lucruri te așteaptă',
      few: '$count lucruri te așteaptă',
      one: '1 lucru te așteaptă',
    );
    return '$_temp0';
  }

  @override
  String notifImprovementProposed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Au fost propuse $count de îmbunătățiri',
      few: 'Au fost propuse $count îmbunătățiri',
      one: 'A fost propusă o îmbunătățire',
    );
    return '$_temp0';
  }

  @override
  String get notifPipelineRunHeld =>
      'O rulare de pipeline este reținută la buget';

  @override
  String notifPipelineRunHeldBody(String spent, String cap) {
    return 'Cheltuit $spent din $cap';
  }

  @override
  String get inboxGoalNeedsReview => 'Obiectivul așteaptă revizuire';

  @override
  String get inboxGoalNeedsPerson => 'Obiectivul are nevoie de tine';

  @override
  String get inboxImprovementProposed => 'Îmbunătățire propusă';

  @override
  String get improvementRefusalAlreadyDecided =>
      'Cineva a decis deja asupra acestei propuneri.';

  @override
  String get improvementRefusalCampaignRequired =>
      'Această modificare nu a trecut o evaluare față de abilitatea actuală, sau abilitatea s-a schimbat după ce a fost măsurată. Rulează din nou evaluarea.';

  @override
  String get improvementRefusalChangedSince =>
      'Ținta s-a schimbat de la propunere. Respinge-o și lasă agentul să propună din nou.';

  @override
  String get improvementRefusalTargetMissing =>
      'Ceea ce modifică această propunere nu mai există.';

  @override
  String get improvementRefusalCampaignState =>
      'Evaluarea nu poate porni sau nu poate fi încheiată în starea ei actuală.';

  @override
  String get improvementRefusalReviewCooldown =>
      'Această conversație a fost revizuită recent. Încearcă din nou mai târziu.';

  @override
  String get improvementRefusalAdminRequired =>
      'Doar un admin al spațiului de lucru poate decide asupra acestei propuneri.';

  @override
  String get improvementKindMemoryFact => 'Fapt din memorie';

  @override
  String get improvementKindPolicy => 'Politică';

  @override
  String get improvementKindAgentNote => 'Notă de agent';

  @override
  String get improvementKindSkillEdit => 'Modificare de abilitate';

  @override
  String get improvementKindSkillNew => 'Abilitate nouă';

  @override
  String get improvementScopeAgent => 'Acest agent';

  @override
  String get improvementScopeRepository => 'Acest repository';

  @override
  String get improvementScopeWorkspace => 'Întregul spațiu de lucru';

  @override
  String get improvementStatusProposed => 'Propusă';

  @override
  String get improvementStatusAccepted => 'Acceptată';

  @override
  String get improvementStatusRejected => 'Respinsă';

  @override
  String get improvementStatusRolledBack => 'Anulată';

  @override
  String get improvementStatusExpired => 'Expirată';

  @override
  String get improvementOperationAdd => 'Adaugă';

  @override
  String get improvementOperationReplace => 'Înlocuiește';

  @override
  String get improvementOperationRemove => 'Elimină';

  @override
  String scheduleTriggerOnce(String time) {
    return 'O dată, $time';
  }

  @override
  String scheduleTriggerEvery(String interval) {
    return 'La fiecare $interval';
  }

  @override
  String scheduleTriggerCron(String cron, String zone) {
    return 'Conform programului $cron ($zone)';
  }

  @override
  String get scheduleTriggerSelfPaced =>
      'Când alege agentul, la 1 până la 60 de minute distanță';

  @override
  String get scheduleTriggerPrChecks =>
      'Când se termină verificările pull request-ului';

  @override
  String scheduleTriggerPrChecksOf(String pr) {
    return 'Când se termină verificările $pr';
  }

  @override
  String get scheduleTriggerPrReview =>
      'Când pull request-ul primește o revizuire sau un răspuns';

  @override
  String scheduleTriggerPrReviewOf(String pr) {
    return 'Când $pr primește o revizuire sau un răspuns';
  }

  @override
  String get scheduleTriggerPrMerged => 'Când pull request-ul este integrat';

  @override
  String scheduleTriggerPrMergedOf(String pr) {
    return 'Când $pr este integrat';
  }

  @override
  String get scheduleTriggerEnvironment =>
      'Când o sarcină a mediului se încheie sau când devine gata';

  @override
  String scheduleTriggerTicket(String id) {
    return 'Când tichetul $id se încheie';
  }

  @override
  String scheduleTriggerPipelineRun(String id) {
    return 'Când rularea de pipeline $id se încheie';
  }

  @override
  String get goalNextWaiting => 'Continuă când sosește ceea ce așteaptă.';

  @override
  String get goalNextVerifying =>
      'Când verificările și revizuirea se termină, se finalizează sau continuă să lucreze.';

  @override
  String get goalNextLimit => 'Se reia când limita de utilizare se resetează.';

  @override
  String get goalNextPerson =>
      'Continuă după ce cineva răspunde la întrebarea sau la cererea de aprobare a lui.';

  @override
  String get goalNextByPerson =>
      'Rămâne pus pe pauză până când cineva îl reia.';

  @override
  String get goalNextNeedsReview =>
      'Aprobă-l ca terminat sau reia-l ca să continue să lucreze.';

  @override
  String get goalNextWorking =>
      'Continuă să lucreze, segment cu segment, până este terminat sau ajunge la o limită.';

  @override
  String get goalContractAddCheck => 'Adaugă verificare';

  @override
  String goalContractChecksFull(int max) {
    return 'Un obiectiv are cel mult $max verificări.';
  }

  @override
  String goalContractChecksCount(int count, int max) {
    return '$count din $max verificări';
  }

  @override
  String get goalContractCheckTaskHint =>
      'Numele sarcinii din mediu, de exemplu test';

  @override
  String get goalContractCheckCommandHint => 'Comandă, de exemplu make test';

  @override
  String get goalContractCheckWhere => 'Unde rulează';

  @override
  String get goalContractCheckInWorktree => 'În worktree';

  @override
  String get goalContractCheckInEnvironment => 'Sarcină de mediu';

  @override
  String get goalContractSecondsSuffix => 's';

  @override
  String goalContractTimeoutRange(int max) {
    return 'De la 1 la $max secunde';
  }

  @override
  String get goalContractRemoveCheck => 'Elimină verificarea';

  @override
  String get goalContractDoneMeans => 'Terminat înseamnă';

  @override
  String get goalContractDoneMeansHelp =>
      'Fiecare criteriu este un lucru pe care un revizor îl poate confirma.';

  @override
  String get goalContractCriterionHint =>
      'Notele de lansare listează fiecare modificare integrată';

  @override
  String goalContractCriterionTooLong(int max) {
    return 'Cel mult $max caractere.';
  }

  @override
  String get goalContractRemoveCriterion => 'Elimină criteriul';

  @override
  String get goalContractAddCriterion => 'Adaugă criteriu';

  @override
  String goalContractCriteriaFull(int max) {
    return 'Un obiectiv are cel mult $max criterii.';
  }

  @override
  String goalContractCriteriaCount(int count, int max) {
    return '$count din $max criterii';
  }

  @override
  String get goalContractChecks => 'Verificări';

  @override
  String get goalContractChecksHelp =>
      'Serverul le rulează când agentul spune că a terminat. Un obiectiv fără verificare se bazează doar pe revizuire.';

  @override
  String get goalContractBoundaries => 'Limite';

  @override
  String get goalContractBoundariesHint => 'Nu modifica API-ul public';

  @override
  String get goalContractStopWhen => 'Oprește-te și întreabă când';

  @override
  String get goalContractStopWhenHint => 'O migrare ar șterge date';

  @override
  String get goalContractEditTitle => 'Editează ce înseamnă terminat';

  @override
  String get goalCheckerTitle => 'Cine verifică acest obiectiv';

  @override
  String get goalCheckerLabel => 'Verificator';

  @override
  String get goalCheckerNone => 'Fără verificator separat';

  @override
  String get goalCheckerNoneWeaker =>
      'Fără un verificator separat, agentul își revizuiește propria muncă, ceea ce prinde mai puține erori.';

  @override
  String goalCheckerRecommend(String agent) {
    return 'De exemplu $agent: un verificator de la alt provider are mai puține șanse să aibă aceleași puncte oarbe.';
  }

  @override
  String get goalCheckerRecommendGeneric =>
      'Un verificator de la alt provider decât agentul obiectivului are mai puține șanse să aibă aceleași puncte oarbe.';

  @override
  String raiseCapSpentOf(String spent, String cap) {
    return 'Cheltuit $spent din $cap.';
  }

  @override
  String get raiseCapNewCap => 'Noul plafon în dolari';

  @override
  String raiseCapMustExceed(String cap) {
    return 'Introdu o valoare mai mare decât $cap.';
  }

  @override
  String get raiseCapConfirm => 'Mărește plafonul';

  @override
  String get goalsBackToList => 'Toate obiectivele';

  @override
  String goalPursuedBy(String agent) {
    return 'Urmărit de $agent';
  }

  @override
  String get goalOpenConversation => 'Deschide conversația';

  @override
  String goalStarted(String time) {
    return 'Pornit $time';
  }

  @override
  String get goalStopTitle => 'Oprești acest obiectiv?';

  @override
  String get goalStopBody =>
      'Agentul nu mai lucrează deloc la el. Lucrul făcut până acum rămâne în conversație.';

  @override
  String get goalRaiseBudgetTitle => 'Mărește bugetul și reia';

  @override
  String get goalRaiseBudgetAction => 'Mărește bugetul';

  @override
  String get goalSectionNow => 'Acum';

  @override
  String get goalFactSegments => 'Segmente';

  @override
  String get goalFactMoney => 'Cheltuit';

  @override
  String get goalFactDeadline => 'Termen';

  @override
  String get goalFactNoProgress => 'Fără progres';

  @override
  String get goalNoDeadline => 'Niciunul';

  @override
  String goalDeadlineWithLeft(String time, String left) {
    return '$time, mai sunt $left';
  }

  @override
  String goalNoProgressCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ultimele $count de segmente nu au adus progres',
      few: 'Ultimele $count segmente nu au adus progres',
      one: 'Ultimul segment nu a adus progres',
    );
    return '$_temp0';
  }

  @override
  String get goalObjective => 'Obiectiv';

  @override
  String get goalSectionContract => 'Ce înseamnă terminat';

  @override
  String get goalContractPauseFirst =>
      'Pune obiectivul pe pauză ca să schimbi ce înseamnă terminat sau cine verifică.';

  @override
  String get goalContractEdit => 'Editează';

  @override
  String get goalCheckerChange => 'Schimbă verificatorul';

  @override
  String get goalContractNone =>
      'Nimic scris încă. Agentul decide când a terminat.';

  @override
  String get goalCheckerSelf =>
      'Fără verificator separat: agentul își verifică singur munca.';

  @override
  String goalCheckerIs(String agent) {
    return 'Verificat de $agent';
  }

  @override
  String goalCheckWorktree(int seconds) {
    return 'În worktree, până la $seconds s';
  }

  @override
  String goalCheckEnvironmentTask(int seconds) {
    return 'Sarcină de mediu, până la $seconds s';
  }

  @override
  String get goalSectionVerification => 'Verificare';

  @override
  String get goalNotVerifiedYet =>
      'Încă neverificat. Agentul nu a spus că a terminat.';

  @override
  String goalVerificationRound(int round, int total, String time) {
    return 'Runda $round din $total, $time';
  }

  @override
  String get goalVerificationClaim => 'Ce afirmă agentul';

  @override
  String get goalCheckOutputTail => 'Ieșirea (ultimele linii)';

  @override
  String goalCheckExitCode(int code) {
    return 'Promovată · cod de ieșire $code';
  }

  @override
  String get goalVerificationReview => 'Revizuire';

  @override
  String get goalVerificationNoVerdict => 'Nicio revizuire încă.';

  @override
  String goalVerdictItem(String criterion, String state) {
    return '$criterion · $state';
  }

  @override
  String get goalSectionSchedules => 'Programe și treziri';

  @override
  String get goalNoSchedules => 'Niciun program și nicio trezire în așteptare.';

  @override
  String get goalPendingWakes => 'Treziri în așteptare';

  @override
  String workListGroup(String label, int count) {
    return '$label · $count';
  }

  @override
  String get goalNotFound =>
      'Acest obiectiv nu există sau se află într-un spațiu la care nu poți accesa.';

  @override
  String get goalsTitle => 'Obiective';

  @override
  String get goalsSubtitle =>
      'Lucrul pe care un agent îl duce până când este îndeplinit ce înseamnă terminat.';

  @override
  String get goalsEmpty => 'Încă niciun obiectiv';

  @override
  String get goalsEmptyHint => 'Pornește unul cu /goal într-o conversație.';

  @override
  String get goalsGroupReview => 'Așteaptă revizuire';

  @override
  String get goalsGroupOpen => 'Deschise';

  @override
  String get goalsGroupEnded => 'Încheiate';

  @override
  String get scheduleStatusActive => 'Activ';

  @override
  String get scheduleStatusPaused => 'Pauză';

  @override
  String get scheduleStatusEnded => 'Încheiat';

  @override
  String get scheduleWhenBusySkip =>
      'Sare peste o pornire cât timp agentul este ocupat';

  @override
  String get scheduleWhenBusyQueue => 'Așteaptă până când agentul este liber';

  @override
  String get scheduleDeliverRun => 'Pornește o rulare';

  @override
  String get scheduleDeliverNotify => 'Doar notifică';

  @override
  String get scheduleNew => 'Program nou';

  @override
  String get schedulesEmpty => 'Niciun program sau urmărire';

  @override
  String get schedulesEmptyHint =>
      'Agenții le setează cu /loop și /schedule, sau poți crea unul.';

  @override
  String scheduleOwnedBy(String name) {
    return 'Proprietar: $name';
  }

  @override
  String scheduleRunsSkips(int runs, int skips) {
    String _temp0 = intl.Intl.pluralLogic(
      runs,
      locale: localeName,
      other: '$runs de rulări',
      few: '$runs rulări',
      one: '1 rulare',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skips,
      locale: localeName,
      other: '$skips de sărituri',
      few: '$skips sărituri',
      one: '1 sărire',
      zero: 'nicio sărire',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String scheduleExpires(String time) {
    return 'Se termină $time';
  }

  @override
  String scheduleNextFires(String times) {
    return 'Următoarele: $times';
  }

  @override
  String get schedulesTitle => 'Programe';

  @override
  String get schedulesSubtitle =>
      'Programe, bucle și urmăriri care trezesc agenți.';

  @override
  String get scheduleWhenLabel => 'Când pornește';

  @override
  String get scheduleWhenEvery => 'Repetat, la fiecare…';

  @override
  String get scheduleWhenCron => 'Pe un program cron';

  @override
  String get scheduleWhenOnceIn => 'O dată, după…';

  @override
  String get scheduleWhenOnceAt => 'O dată, la următoarea…';

  @override
  String get scheduleDurationLabel => 'Interval';

  @override
  String get scheduleDurationHelp =>
      'Folosește s, m, h sau d, de exemplu 30m sau 1h30m. Repetările sunt la cel puțin 60 s distanță.';

  @override
  String get scheduleDurationInvalid =>
      'Aceasta nu este o durată, de exemplu 30m sau 2h.';

  @override
  String get scheduleHour => 'Ora';

  @override
  String get scheduleMinute => 'Minutul';

  @override
  String get scheduleCronLabel => 'Cron (minut oră zi lună zi-din-săptămână)';

  @override
  String get scheduleCronInvalid =>
      'Aceasta nu este o expresie cron de cinci câmpuri care pornește.';

  @override
  String get scheduleTimeInvalid =>
      'Aceasta nu este o oră viitoare, precum 09:00 sau 2026-11-21T09:00Z.';

  @override
  String scheduleDaysRange(int max) {
    return 'De la 1 la $max zile.';
  }

  @override
  String scheduleOptionUnknown(String option) {
    return '$option nu este o opțiune.';
  }

  @override
  String get scheduleLimits => 'Limite';

  @override
  String get schedulePresetWeekdays => 'În zilele lucrătoare la 09:00';

  @override
  String get schedulePresetDaily => 'În fiecare zi la 09:00';

  @override
  String get schedulePresetHourly => 'În fiecare oră, fix la ora exactă';

  @override
  String get scheduleZoneLabel => 'Fus orar';

  @override
  String get scheduleZoneHelp =>
      'Gol înseamnă fusul orar al spațiului de lucru.';

  @override
  String get scheduleZoneInvalid =>
      'Acesta nu este un fus orar, de exemplu Europe/Berlin.';

  @override
  String get scheduleCreateTitle => 'Program nou';

  @override
  String get scheduleSpaceLabel => 'Spațiu';

  @override
  String get scheduleSpaceHint => 'Alege un spațiu';

  @override
  String get scheduleConversationLabel => 'Conversație';

  @override
  String get scheduleConversationHint => 'Alege o conversație';

  @override
  String get scheduleAgentLabel => 'Agent';

  @override
  String get scheduleAgentHint => 'Alege cine se trezește';

  @override
  String get scheduleNoteLabel => 'De unde pornește fiecare rulare';

  @override
  String get scheduleNoteHint =>
      'Rezumă ce s-a schimbat peste noapte și semnalează orice este blocat.';

  @override
  String get scheduleExpiresInDays => 'Se termină după (zile)';

  @override
  String get scheduleExpiresInDaysHelp => 'Gol: 30 de zile, cel mult 365.';

  @override
  String get scheduleMaxRuns => 'Plafon de rulări';

  @override
  String scheduleMaxRunsHelp(int max) {
    return 'Gol: fără plafon, cel mult $max.';
  }

  @override
  String get scheduleCostCap => 'Plafon de cost (dolari)';

  @override
  String get scheduleCostCapHelp =>
      'Gol: valoarea implicită a spațiului de lucru.';

  @override
  String get scheduleWhenBusyLabel => 'Dacă agentul este ocupat';

  @override
  String get scheduleWhenBusyDefault => 'Implicitul pentru acest tip';

  @override
  String get scheduleDeliverLabel => 'Fiecare pornire';

  @override
  String get scheduleCreate => 'Creează programul';

  @override
  String get scheduleExtendTitle => 'Prelungește acest program';

  @override
  String scheduleExtendNow(String current, String latest) {
    return 'Se termină $current. Poate dura cel mult până la $latest.';
  }

  @override
  String get scheduleExtendDays => 'Adaugă zile';

  @override
  String scheduleExtendTooLong(String latest) {
    return 'Poate să se termine cel mult la $latest.';
  }

  @override
  String scheduleMaxRunsRange(int max) {
    return 'De la 1 la $max rulări.';
  }

  @override
  String scheduleCostCapRange(String max) {
    return 'Cel puțin 1 dolar și cel mult $max.';
  }

  @override
  String get scheduleExtend => 'Prelungește';

  @override
  String get scheduleRemoveTitle => 'Elimini acest program?';

  @override
  String get scheduleDeleteTitle => 'Ștergi acest program?';

  @override
  String get scheduleRemoveBody =>
      'Dispare din listă. Rulările lui rămân în conversație.';

  @override
  String get scheduleDeleteBody =>
      'Nu mai pornește niciodată. Rulările lui rămân în conversație.';

  @override
  String get scheduleRemove => 'Elimină';

  @override
  String get scheduleDelete => 'Șterge';

  @override
  String get scheduleOwnerOnly =>
      'Doar proprietarul lui îl poate relua sau prelungi.';

  @override
  String get schedulesBackToList => 'Toate programele';

  @override
  String get scheduleNoteByAgent => 'Notă, scrisă de agent';

  @override
  String get scheduleNoteByPerson => 'Notă, scrisă de o persoană';

  @override
  String scheduleNoteEditedBy(String name) {
    return 'Notă, editată ultima dată de $name';
  }

  @override
  String get scheduleNoNote => 'Nicio notă.';

  @override
  String get schedulePause => 'Pune pe pauză';

  @override
  String get scheduleResume => 'Reia';

  @override
  String get scheduleOpenChainRoot => 'Deschide primul program din acest lanț';

  @override
  String get scheduleSectionFacts => 'Detalii';

  @override
  String get scheduleFactAgent => 'Trezește';

  @override
  String get scheduleFactConversation => 'În';

  @override
  String get scheduleConversationUnknown =>
      'O conversație pe care s-ar putea să nu o vezi';

  @override
  String get scheduleFactOwner => 'Proprietar';

  @override
  String get scheduleNoOwner => 'Nimeni';

  @override
  String get scheduleFactNextFires => 'Următoarele porniri';

  @override
  String get scheduleFactNext => 'Următoarea pornire';

  @override
  String get scheduleFactLast => 'Ultima pornire';

  @override
  String get scheduleFactRuns => 'Rulări';

  @override
  String scheduleRunsNoCap(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de rulări, fără plafon',
      few: '$count rulări, fără plafon',
      one: '1 rulare, fără plafon',
    );
    return '$_temp0';
  }

  @override
  String scheduleRunsOfCap(int count, int max) {
    return '$count din $max rulări';
  }

  @override
  String get scheduleFactSkips => 'Sărituri';

  @override
  String scheduleSkips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de porniri sărite',
      few: '$count porniri sărite',
      one: '1 pornire sărită',
      zero: 'Niciuna',
    );
    return '$_temp0';
  }

  @override
  String get scheduleFactSpent => 'Cheltuit';

  @override
  String get scheduleFactEnds => 'Se termină';

  @override
  String get scheduleFactWhenBusy => 'Dacă agentul este ocupat';

  @override
  String get scheduleFactDeliver => 'Fiecare pornire';

  @override
  String get scheduleFactChain => 'Lanț';

  @override
  String scheduleChainLeft(int runs, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      runs,
      locale: localeName,
      other: '$runs de rulări rămase',
      few: '$runs rulări rămase',
      one: '1 rulare rămasă',
    );
    return '$_temp0 în lanț, care se termină $time';
  }

  @override
  String get scheduleFactCreated => 'Creat';

  @override
  String get scheduleSectionHistory => 'Treziri și rulări recente';

  @override
  String get scheduleNoRuns => 'Încă nicio rulare.';

  @override
  String scheduleRunLine(String status, String cost) {
    return '$status · $cost';
  }

  @override
  String get scheduleRunPending => 'Așteaptă să pornească';

  @override
  String get scheduleRunRunning => 'În rulare';

  @override
  String get scheduleRunCompleted => 'Terminată';

  @override
  String get scheduleRunFailed => 'Eșuată';

  @override
  String get scheduleNotFound =>
      'Acest program nu există sau se află într-un spațiu la care nu poți accesa.';

  @override
  String get improvementCampaignTitle => 'Rulează o evaluare';

  @override
  String improvementCampaignCost(int repetitions, String budget) {
    String _temp0 = intl.Intl.pluralLogic(
      repetitions,
      locale: localeName,
      other: 'Fiecare sarcină rulează de $repetitions de ori',
      few: 'Fiecare sarcină rulează de $repetitions ori',
      one: 'Fiecare sarcină rulează o dată',
    );
    return '$_temp0 cu abilitatea actuală și cu modificarea. Cheltuie cel mult $budget, facturat acestui spațiu de lucru.';
  }

  @override
  String get improvementCampaignCostUnknown =>
      'Evaluarea rulează corpusul cu abilitatea actuală și cu modificarea, până la bugetul pe care îl setezi.';

  @override
  String get improvementCampaignUnavailable =>
      'Evaluările nu pot rula pe acest server acum.';

  @override
  String get improvementCampaignCorpus => 'Corpus';

  @override
  String get improvementCampaignProvider => 'Provider';

  @override
  String get improvementCampaignModel => 'Model';

  @override
  String get improvementCampaignRepetitions => 'Rulări per sarcină';

  @override
  String get improvementCampaignBudget => 'Buget (dolari)';

  @override
  String improvementCampaignRange(int max) {
    return 'De la 1 la $max.';
  }

  @override
  String get improvementCampaignStart => 'Pornește evaluarea';

  @override
  String get improvementRollbackTitle => 'Anulezi această modificare?';

  @override
  String get improvementRollbackBody =>
      'Textul pe care l-a înlocuit revine, atât timp cât nimeni nu l-a schimbat între timp.';

  @override
  String get improvementRollback => 'Anulează modificarea';

  @override
  String get improvementRolledBackDone => 'Modificarea a fost anulată.';

  @override
  String get improvementNeedsAdmin =>
      'Doar un admin al spațiului de lucru poate decide asupra acesteia: modifică o abilitate sau o politică pentru întregul spațiu de lucru.';

  @override
  String get improvementAdminDecides =>
      'Ca admin, decizi asupra acesteia: modifică o abilitate sau o politică pentru întregul spațiu de lucru.';

  @override
  String get improvementNeedsCampaign =>
      'Rulează o evaluare reușită înainte de a accepta această modificare de abilitate.';

  @override
  String get improvementsBackToList => 'Toate îmbunătățirile';

  @override
  String improvementMeta(String kind, String scope, String agent) {
    return '$kind · $scope · propusă de $agent';
  }

  @override
  String get improvementAccept => 'Acceptă';

  @override
  String get improvementAcceptedDone => 'Acceptată.';

  @override
  String get improvementReject => 'Respinge';

  @override
  String get improvementRejectedDone => 'Respinsă.';

  @override
  String get improvementRunEvaluation => 'Rulează evaluarea';

  @override
  String get improvementSectionChange => 'Ce se schimbă';

  @override
  String get improvementTarget => 'Țintă';

  @override
  String improvementScopeLine(String scope) {
    return 'Se aplică la: $scope';
  }

  @override
  String get improvementNewText => 'Text nou';

  @override
  String get improvementRemovedText => 'Text eliminat';

  @override
  String get improvementExpected => 'Efect așteptat';

  @override
  String get improvementSectionEvidence => 'Dovezi și decizie';

  @override
  String get improvementNoEvidence => 'Nicio dovadă atașată.';

  @override
  String get improvementEvidenceRuns => 'Rulări';

  @override
  String get improvementEvidenceMessages => 'Mesaje';

  @override
  String improvementOpenMessage(int index) {
    return 'Mesajul $index';
  }

  @override
  String get improvementEvidenceChecks => 'Rezultatele verificărilor';

  @override
  String get improvementEvaluation => 'Evaluare';

  @override
  String get improvementCampaignNone => 'Neevaluată încă.';

  @override
  String get improvementCampaignRunning => 'Evaluarea rulează.';

  @override
  String get improvementCampaignPassed =>
      'Evaluarea a fost reușită: a rulat complet, iar modificarea a rezolvat cel puțin atâtea rulări câte abilitatea actuală, ceea ce nu dovedește că este mai bună. Poate fi acceptată.';

  @override
  String get improvementCampaignFailed =>
      'Evaluarea nu a fost reușită, sau abilitatea s-a schimbat după ce a fost măsurată. Rulează-o din nou sau respinge modificarea.';

  @override
  String improvementDecided(String status, String name, String time) {
    return '$status de $name, $time';
  }

  @override
  String get improvementSomeone => 'cineva';

  @override
  String improvementExpires(String time) {
    return 'Expiră la $time dacă nimeni nu decide.';
  }

  @override
  String get improvementOpenApplied => 'Deschide ce a modificat';

  @override
  String get improvementsTitle => 'Îmbunătățiri';

  @override
  String get improvementsSubtitle =>
      'Modificări propuse de agenți pentru memoria, notele, politicile și abilitățile lor.';

  @override
  String get improvementsEmpty => 'Nicio propunere';

  @override
  String get improvementsEmptyHint =>
      'Agenții propun îmbunătățiri după ce își revizuiesc lucrul, de exemplu cu /refine.';

  @override
  String get improvementRowNeedsAdmin => 'Decide un admin';

  @override
  String get improvementNotFound =>
      'Această propunere nu există sau se află într-un spațiu la care nu poți accesa.';

  @override
  String get dispatchSettingsTitle => 'Programe';

  @override
  String get dispatchLimitsLabel => 'Limite de programe';

  @override
  String get dispatchLimitsSubtitle =>
      'Plafoane privind câte programe și urmăriri pot avea agenții și valorile lor implicite.';

  @override
  String dispatchLimitRange(int max) {
    return 'De la 1 la $max';
  }

  @override
  String get dispatchLimitPerConversation => 'Per agent într-o conversație';

  @override
  String get dispatchLimitPerConversationHelp =>
      'Programe active sau în pauză pe care le poate avea un agent într-o conversație.';

  @override
  String get dispatchLimitPerAgent => 'Per agent';

  @override
  String get dispatchLimitPerAgentHelp =>
      'Programe active sau în pauză pe care le poate avea un agent în tot spațiul de lucru.';

  @override
  String get dispatchLimitPerWorkspace => 'În spațiul de lucru';

  @override
  String get dispatchLimitPerWorkspaceHelp =>
      'Programe active sau în pauză din tot spațiul de lucru.';

  @override
  String get dispatchLimitCostCap => 'Plafon de cost implicit (dolari)';

  @override
  String get dispatchLimitCostCapHelp =>
      'Cât poate cheltui în total un program dacă nu își setează un plafon propriu.';

  @override
  String get dispatchLimitZone => 'Fus orar';

  @override
  String get dispatchLimitZoneHelp =>
      'Fusul în care se citește un program cron care nu își precizează unul, și fusul digestului zilnic.';

  @override
  String get dispatchUnattendedLabel => 'Când nimeni nu răspunde';

  @override
  String get dispatchUnattendedSubtitle =>
      'Cât timp așteaptă o rulare pornită de server după o persoană și când pleacă digestul zilnic al celor care așteaptă.';

  @override
  String get dispatchUnattendedExpiry => 'Cererile așteaptă (ore)';

  @override
  String get dispatchUnattendedExpiryHelp =>
      'După aceasta, o aprobare se consideră refuzată, iar o întrebare, fără răspuns. Obiectivele setate să-și răspundă singure la întrebări o fac după 10 minute.';

  @override
  String dispatchUnattendedExpiryRange(int min, int max) {
    return 'De la $min la $max ore';
  }

  @override
  String get dispatchDigestHour => 'Digest zilnic la (ora)';

  @override
  String dispatchDigestHourHelp(String zone) {
    return 'În $zone, fusul orar de mai sus.';
  }

  @override
  String get dispatchDigestHourRange => 'De la 0 la 23';

  @override
  String get goalRecordCrumb => 'Obiectiv';

  @override
  String get improvementRecordCrumb => 'Propunere';

  @override
  String get goalNodeNeedsAgent => 'Alege agentul care urmărește obiectivul.';

  @override
  String get goalNodeNeedsObjective => 'Scrie obiectivul.';

  @override
  String get goalNodeContractInvalid =>
      'Contractul are un câmp peste limită; nu se salvează până nu este corectat.';

  @override
  String get goalNodeBudget => 'Buget (dolari)';

  @override
  String get goalNodeBudgetHelp =>
      'Cât poate cheltui cel mult obiectivul. Când se epuizează, obiectivul așteaptă o persoană.';

  @override
  String goalNodeBudgetRange(int max) {
    return 'Obligatoriu: mai mult de 0, până la $max.';
  }

  @override
  String get goalNodeMaxRuns => 'Plafon de segmente';

  @override
  String get goalNodeMaxRunsHelp =>
      'Opțional. Cele mai multe segmente (rulări ale agentului) pe care le poate face obiectivul.';

  @override
  String get goalNodeDeadline => 'Termen (ore)';

  @override
  String get goalNodeDeadlineHelp =>
      'Opțional. Ore de la momentul în care pasul pornește obiectivul.';

  @override
  String goalNodeRange(int max) {
    return 'De la 1 la $max, sau gol.';
  }

  @override
  String get goalNodeContract => 'Contract';

  @override
  String get goalNodeContractHelp =>
      'Ce înseamnă terminat: criteriile pe care le verifică revizorul și comenzile care trebuie să promoveze.';

  @override
  String get nodeConfigObjective => 'Obiectiv';

  @override
  String pipelineRunGoalStep(String step) {
    return 'Pasul $step urmărește un obiectiv';
  }

  @override
  String get pipelineRunOpenGoal => 'Deschide obiectivul';

  @override
  String get pipelineRunHeldBudget =>
      'Această rulare este reținută: orchestrarea ei a atins plafonul de cost.';

  @override
  String pipelineRunHeldOther(String reason) {
    return 'Această rulare este reținută ($reason).';
  }

  @override
  String pipelineRunHeldSpent(String spent, String cap) {
    return 'Cheltuit $spent din $cap. Mărește plafonul și rularea continuă.';
  }

  @override
  String get pipelineRunRaiseCap => 'Mărește plafonul';

  @override
  String get pipelineRunRaiseCapTitle => 'Mărește plafonul de orchestrare';

  @override
  String get pipelineRunCapRaised =>
      'Plafon mărit. Rularea continuă în curând.';

  @override
  String get goalLaunchChecks => 'Verificări';

  @override
  String get goalLaunchChecksHelp =>
      'Comenzi care trebuie să promoveze înainte ca obiectivul să se poată încheia. Opțional.';

  @override
  String get goalLaunchFresh => 'Pornește fiecare segment de la zero';

  @override
  String get goalLaunchFreshHelp =>
      'Fiecare rulare pornește fără istoricul conversației, doar din obiectiv și notele lui.';

  @override
  String get goalLaunchAssume =>
      'Răspunde singur la întrebări când nimeni nu o face';

  @override
  String get goalLaunchAssumeHelp =>
      'După 10 minute fără răspuns, agentul își declară presupunerea și continuă, dacă condițiile de oprire o permit.';

  @override
  String workFeedLimitParkOutcomeResumed(String provider, String time) {
    return 'Reluat la $time după limita de utilizare a $provider.';
  }

  @override
  String workFeedLimitParkOutcomeCancelled(String provider, String time) {
    return 'Anulat la $time. Nu a reluat după limita de utilizare a $provider.';
  }

  @override
  String workFeedLimitParkOutcomeExpired(String provider, String time) {
    return 'A expirat la $time fără să reia după limita de utilizare a $provider.';
  }

  @override
  String workFeedLimitParkOutcomeSkipped(String provider, String time) {
    return 'Nu a reluat după limita de utilizare a $provider ($time).';
  }

  @override
  String workFeedCommandRefusedNamed(String command) {
    return 'Comanda /$command a fost refuzată.';
  }

  @override
  String get improvementRefusalQueued =>
      'O revizuire a acestei conversații așteaptă deja să ruleze.';

  @override
  String get improvementRefusalAgentNotFound =>
      'Acest agent nu face parte din acest spațiu de lucru.';

  @override
  String get workRefusalWakeQueueFull =>
      'Există deja prea multe treziri în așteptare aici. Încearcă din nou după ce unele au rulat.';

  @override
  String get orchestrationRefusalNotYours =>
      'Doar persoana pentru care acționează această rulare o poate modifica.';

  @override
  String get orchestrationRefusalCapInvalid =>
      'Noul plafon trebuie să fie peste plafonul actual și peste ce s-a cheltuit, și cel mult 1.000 \$.';

  @override
  String get orchestrationRefusalCapChanged =>
      'Cineva a mărit plafonul primul. Verifică noul plafon și încearcă din nou.';

  @override
  String workFeedCapRaised(String person, String oldCap, String newCap) {
    return '$person a mărit plafonul rulării de la $oldCap la $newCap.';
  }

  @override
  String get workFeedPersonUnknown => 'O persoană';

  @override
  String workFeedApplyIncomplete(String skill) {
    return 'O modificare acceptată a abilității $skill nu a putut fi finalizată, deoarece abilitatea s-a schimbat între timp. Propunerea a fost anulată.';
  }

  @override
  String get workFeedOpenImprovement => 'Deschide îmbunătățirea';

  @override
  String get peerAskFailNoOutput => 'S-a încheiat fără un răspuns.';

  @override
  String get peerAskFailRunFailed => 'Rularea sa a eșuat.';

  @override
  String get peerAskFailStoppedByPerson => 'O persoană i-a oprit rularea.';

  @override
  String get peerAskFailBudget => 'Rularea sa a atins bugetul.';

  @override
  String get peerAskFailSilence =>
      'Rularea sa a rămas fără activitate și a fost oprită.';

  @override
  String get peerAskFailUsageLimit =>
      'Rularea sa s-a oprit la limita de utilizare a providerului.';

  @override
  String get peerAskFailNotDelivered =>
      'Întrebarea nu a fost livrată niciodată.';

  @override
  String heldSteeringLimitHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de mesaje reținute la limita de utilizare',
      few: '$count mesaje reținute la limita de utilizare',
      one: '1 mesaj reținut la limita de utilizare',
    );
    return '$_temp0';
  }

  @override
  String get heldSteeringLimitNote =>
      'Acestea sunt trimise când persoana pentru care lucrează rularea o reia. Dacă nu este reluată în 7 zile de la resetare, sunt reținute pentru acea persoană.';

  @override
  String get wakeKindRuleFolded => 'A înlocuit-o un eveniment ulterior.';

  @override
  String goalCardWaitingNext(String time) {
    return 'Așteaptă ce a pregătit · se uită din nou până la $time';
  }

  @override
  String raiseCapAtMost(String max) {
    return 'Introdu cel mult $max.';
  }

  @override
  String raiseCapNowAt(String cap) {
    return 'Plafonul este acum $cap.';
  }

  @override
  String get scheduleWakeReasonSchedule => 'Programat';

  @override
  String get scheduleWakeReasonWatch => 'Urmărire';

  @override
  String get scheduleWakeReasonLimitReset => 'După o limită de utilizare';

  @override
  String get scheduleWakeStatePending => 'În așteptare';

  @override
  String get scheduleWakeStateHeld => 'Reținută';

  @override
  String get scheduleWakeStateClaimed => 'Pornește';

  @override
  String get scheduleWakeStateDelivered => 'Livrată';

  @override
  String get scheduleWakeStateSkipped => 'Sărită';

  @override
  String get scheduleWakeStateExpired => 'Expirată';

  @override
  String get scheduleWakeStateCancelled => 'Anulată';

  @override
  String scheduleWakeLine(String reason, String state) {
    return '$reason · $state';
  }

  @override
  String scheduleWakeExit(int code) {
    return 'cod de ieșire $code';
  }

  @override
  String scheduleWakeEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de evenimente',
      few: '$count evenimente',
      one: '1 eveniment',
    );
    return '$_temp0';
  }

  @override
  String get scheduleWakesNone => 'Nicio trezire încă.';

  @override
  String get scheduleWakesOlder => 'Arată mai vechi';

  @override
  String get improvementCandidateStaged =>
      'Abilitatea propusă este salvată ca o revizie separată. Evaluarea ei lasă abilitatea activă neschimbată; abilitatea se schimbă doar când propunerea este acceptată.';

  @override
  String goalNextWaitingFallback(String time) {
    return 'Continuă când sosește ceea ce așteaptă sau se uită din nou la $time dacă nu sosește nimic.';
  }

  @override
  String get steeringRefusalHeldByLimit =>
      'Mesajele reținute de o pauză la limita de utilizare nu pot fi trimise manual cât timp așteaptă.';

  @override
  String steeringRefusalHeldByLimitAt(String time) {
    return 'Mesajele reținute de o pauză la limita de utilizare nu pot fi trimise manual cât timp așteaptă. Limita se resetează la $time.';
  }

  @override
  String heldSteeringLimitResetsAt(String time) {
    return 'Limita se resetează la $time. Acestea sunt trimise când persoana pentru care lucrează rularea o reia.';
  }

  @override
  String heldSteeringFromPerson(String name) {
    return 'De la $name';
  }

  @override
  String get heldSteeringFromSomeoneElse => 'De la altcineva';

  @override
  String get heldSteeringOnlyWriterSends =>
      'Doar persoana care a scris un mesaj reținut îl poate trimite.';

  @override
  String get steeringRefusalNotYours =>
      'Aceste mesaje reținute aparțin altcuiva. Doar persoana care a scris un mesaj îl poate trimite.';

  @override
  String improvementEvaluationSolved(
    int pairedRuns,
    int candidateSolved,
    int baselineSolved,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      pairedRuns,
      locale: localeName,
      other: 'În $pairedRuns de rulări pereche',
      few: 'În $pairedRuns rulări pereche',
      one: 'Într-o rulare pereche',
    );
    return '$_temp0, modificarea a rezolvat $candidateSolved, iar abilitatea actuală a rezolvat $baselineSolved.';
  }

  @override
  String improvementEvaluationWorse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de sarcini au mers mai prost cu modificarea.',
      few: '$count sarcini au mers mai prost cu modificarea.',
      one: '1 sarcină a mers mai prost cu modificarea.',
    );
    return '$_temp0';
  }

  @override
  String improvementEvaluationCostlier(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de sarcini au costat mai mult cu modificarea.',
      few: '$count sarcini au costat mai mult cu modificarea.',
      one: '1 sarcină a costat mai mult cu modificarea.',
    );
    return '$_temp0';
  }

  @override
  String improvementEvaluationHarnessErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de rulări au întâlnit o eroare de harness.',
      few: '$count rulări au întâlnit o eroare de harness.',
      one: '1 rulare a întâlnit o eroare de harness.',
    );
    return '$_temp0';
  }

  @override
  String get improvementEvaluationIncomplete => 'Evaluarea nu a rulat complet.';

  @override
  String workFeedLimitParkExpires(String time) {
    return 'Expiră $time';
  }

  @override
  String workFeedSchedulePaused(String person, String agent) {
    return '$person a pus pe pauză programul pentru $agent.';
  }

  @override
  String get goalCardApproveNotYours =>
      'Doar persoana care a pornit rularea pipeline poate aproba finalizarea acestui obiectiv.';

  @override
  String get goalCardObjective => 'Obiectivul';

  @override
  String get planNeedsWrite =>
      'Aprobarea sau modificarea acestui plan necesită acces de scriere la toate depozitele din acest spațiu. Un administrator al spațiului de lucru îi poate acorda accesul.';

  @override
  String scheduleSpentWithChain(String spent, String cap) {
    return '$spent din $cap, incluzând fiecare program din lanțul său';
  }

  @override
  String get ccLoading => 'Se încarcă';

  @override
  String get ccProgress => 'Progres';

  @override
  String get ccBreadcrumb => 'Cale de navigare';

  @override
  String get ccDialog => 'Casetă de dialog';

  @override
  String get ccResize => 'Redimensionează';

  @override
  String ccUnverifiedLabel(String label) {
    return '$label (neverificat)';
  }

  @override
  String prRowSelect(String title) {
    return 'Selectează $title';
  }

  @override
  String get prTableSelectAll => 'Selectează toate pull request-urile';

  @override
  String planVersionRewind(int version) {
    return 'Revino la versiunea $version';
  }
}
