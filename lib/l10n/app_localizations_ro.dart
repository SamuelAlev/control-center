// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

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
  String get keybindingPushToTalkDescription =>
      'Ține apăsat sau comută dictarea vocală în compozitorul de mesaje';

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
  String get guardrailClassPrPublish => 'Publică o revizuire sau o fuziune';

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
  String get serverModeRemote => 'Conectează-te la o instanță remote';

  @override
  String get serverModeRemoteDescription =>
      'Conectează-te la un server Control Center care rulează în altă parte. Datele tale trăiesc pe acel server.';

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
  String get serverSetupTitle => 'Cum ar trebui să ruleze Control Center?';

  @override
  String get serverSetupSubtitle =>
      'Control Center are nevoie de un server care deține datele tale. Rulează unul în această aplicație sau conectează-te la o instanță care rulează în altă parte.';

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
  String get calendarAllDayGutter => 'Toată ziua';

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
  String get calendarStartRecording => 'Pornește înregistrarea';

  @override
  String get calendarStartRecordingAndLink => 'Pornește înregistrarea și leagă';

  @override
  String get calendarJoinMeet => 'Intră în întâlnire';

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
  String get calendarAddAccount => 'Adaugă un cont de calendar';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Conectează un cont Google pentru a sincroniza evenimentele în acest spațiu. Aceste calendare sunt ale tale aici.';

  @override
  String get calendarConnecting => 'Se conectează…';

  @override
  String get calendarSyncNow => 'Sincronizează acum';

  @override
  String get calendarNoWorkspace =>
      'Selectează un spațiu de lucru ca să-i vezi calendarul';

  @override
  String get calendarConnectError => 'Nu s-a putut conecta Google Calendar';

  @override
  String get calendarClientIdLabel => 'Client ID';

  @override
  String get calendarClientSecretLabel => 'Client secret';

  @override
  String get calendarConnectCredsHint =>
      'Introdu Client ID-ul și secretul Google OAuth device-code pentru proiectul tău. Serverul rulează conexiunea și sincronizarea — browserul tău nu deține niciodată tokenii.';

  @override
  String get calendarConnectApproveInstruction =>
      'Deschide pagina de verificare pe orice dispozitiv, autentifică-te și introdu acest cod:';

  @override
  String get calendarConnectOpenPage => 'Deschide pagina de verificare';

  @override
  String get calendarConnectWaiting => 'Se așteaptă aprobarea…';

  @override
  String get calendarConnectDenied =>
      'Autorizarea a fost refuzată. Încearcă din nou.';

  @override
  String get calendarConnectExpired => 'Codul a expirat. Încearcă din nou.';

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
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'Deschide meniul de filtre pentru pull request-uri';

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
  String get mcpServersSettingsDescription =>
      'Server MCP încorporat și servere MCP externe.';

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
  String get activityLabel => 'ACTIVITATE';

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
  String get activityUpdatedGitHubToken => 'A actualizat tokenul GitHub';

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
  String get activityMarkedSpaceRead => 'A marcat spațiul ca citit';

  @override
  String get activityRespondedToInvitation =>
      'A răspuns la invitația la eveniment';

  @override
  String get activityStartedCalendarConnect =>
      'A pornit conexiunea la calendar';

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
  String get activityUpdatedMcpToken => 'A actualizat tokenul MCP';

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
  String get addGithubRepoPrompt =>
      'Adaugă cel puțin un depozit GitHub ca să vezi pull request-uri';

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
  String get allowGitPush => 'Permite git push';

  @override
  String get allowGithubApi => 'Permite apeluri GitHub API';

  @override
  String get allowNetwork => 'Permite accesul general la rețea';

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
  String get bugLabel => 'BUG';

  @override
  String get bundledDefaultsNeverUpdated =>
      'Implicite incluse — niciodată actualizate';

  @override
  String get cancel => 'Anulează';

  @override
  String get cancelEdit => 'Anulează editarea';

  @override
  String get categoryCreation => 'Creare';

  @override
  String get categoryEditing => 'Editare';

  @override
  String get categoryNavigation => 'Navigare';

  @override
  String get categorySystem => 'Sistem';

  @override
  String get categoryView => 'Vizualizare categorie';

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
  String get configureDefaultRunners =>
      'Configurează ce adaptor și model se folosesc pentru spațiile noi și generarea de titluri.';

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
  String get customCapabilitiesDescription =>
      'Descriere personalizată a capabilităților';

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
  String get defaultCapabilities => 'Capabilități implicite · spații noi';

  @override
  String get defaultChat => 'Chat implicit';

  @override
  String get defaultRunners => 'Runnere implicite';

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
  String get archiveConversation => 'Arhivează conversația';

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
  String get gatesGithubPatPush =>
      'Controlează injectarea GitHub PAT. Necesar ca agentul să poată face push.';

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
  String get images => 'Imagini';

  @override
  String get inactive => 'Inactiv';

  @override
  String get install => 'Instalează';

  @override
  String get installRequired => 'Instalare necesară';

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
  String get keybindingAddARepositoryDescription => 'Adaugă un depozit';

  @override
  String get keybindingAddRepository => 'Adaugă depozit';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'Marchează sau demarchează articolul selectat';

  @override
  String get keybindingCommandPalette => 'Paletă de comenzi';

  @override
  String get keybindingCreateANewAgentDescription => 'Creează un agent nou';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'Creează un spațiu de lucru nou';

  @override
  String get keybindingFocusSearch => 'Focalizează căutarea';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'Focalizează câmpul de căutare al pull request-urilor';

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
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'Deschide sau închide popup-ul de comutare a spațiilor de lucru din bara laterală';

  @override
  String get keybindingOpenPr => 'Deschide PR';

  @override
  String get keybindingOpenSettings => 'Deschide setările';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'Deschide setările aplicației';

  @override
  String get keybindingOpenTheCommandPaletteDescription =>
      'Deschide paleta de comenzi';

  @override
  String get keybindingOpenTheSelectedArticleDescription =>
      'Deschide articolul selectat';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'Deschide pull request-ul selectat';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'Deschide spațiul de lucru selectat';

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
  String get keybindingRefreshAllFeedsDescription =>
      'Reîmprospătează toate fluxurile';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'Reîmprospătează lista de pull request-uri';

  @override
  String get keybindingRescanForAdaptersDescription => 'Rescanează adaptorii';

  @override
  String get keybindingSelectTheNextArticleDescription =>
      'Selectează articolul următor';

  @override
  String get keybindingSelectTheNextSpaceDescription =>
      'Selectează spațiul următor';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'Selectează articolul anterior';

  @override
  String get keybindingSelectThePreviousSpaceDescription =>
      'Selectează spațiul anterior';

  @override
  String get keybindingSendMessage => 'Trimite mesajul';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'Trimite mesajul curent';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Comută între modul luminos și cel întunecat';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Comută la al optulea spațiu de lucru';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Comută la al cincilea spațiu de lucru';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'Comută la primul spațiu de lucru';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'Comută la al patrulea spațiu de lucru';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'Comută la spațiul de lucru următor';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'Comută la al nouălea spațiu de lucru';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'Comută la spațiul de lucru anterior';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'Comută la al doilea spațiu de lucru';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'Comută la al șaptelea spațiu de lucru';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'Comută la al șaselea spațiu de lucru';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'Comută la al treilea spațiu de lucru';

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
  String get keybindings => 'Scurtături';

  @override
  String get keybindingsDescription =>
      'Toate scurtăturile de tastatură. Scurtăturile sunt fixe și nu pot fi reatribuite.';

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
  String get mcpAuthToken => 'Token de autentificare MCP';

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
  String noShortcutsMatch(String query) {
    return 'Nicio scurtătură nu se potrivește cu \"$query\"';
  }

  @override
  String get noSystemFonts => 'Niciun font de sistem detectat.';

  @override
  String get noTokenSet => 'Niciun token setat — accesul este nerestricționat.';

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
      'Notifică la mesaje noi de agent în alte spații.';

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
  String get questionLabel => 'ÎNTREBARE';

  @override
  String get queued => 'În coadă';

  @override
  String get react => 'Reacționează';

  @override
  String get readPrsIssuesMetadata =>
      'Permite agentului să citească PR-uri, issue-uri și metadatele depozitului.';

  @override
  String get readerPreferences => 'Preferințe cititor';

  @override
  String get reasoningEffort => 'Efort de raționament';

  @override
  String get recommendLabel => 'RECOMANDĂ';

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
  String repoAccessNoticeBody(String repos) {
    return 'Datele de autentificare GitHub ale serverului nu pot vedea $repos. Dacă un depozit aparține unei organizații, instalează GitHub App acolo sau conectează un token care are acces.';
  }

  @override
  String repoAccessNoticeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de depozite nu pot fi accesate',
      few: '# depozite nu pot fi accesate',
      one: 'Un depozit nu poate fi accesat',
    );
    return '$_temp0';
  }

  @override
  String get repoAccessNoticeSuspendedTitle =>
      'Instalarea GitHub App este suspendată';

  @override
  String repoAccessNoticeSuspendedBody(String repos) {
    return 'Se afișează ultimele date cunoscute pentru $repos. Reia instalarea pe GitHub sau conectează un token cu acces.';
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
  String get runCompleted => 'Rulare finalizată';

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
  String get sandboxPermissions => 'Permisiuni sandbox';

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
  String get searchGifsHint => 'Caută GIF-uri...';

  @override
  String get searchInDiffHint => 'Caută în diff…';

  @override
  String get searchOrTypeModel => 'Caută sau tastează un nume de model…';

  @override
  String get searchPlaceholder => 'Caută…';

  @override
  String get searchShortcuts => 'Caută scurtături…';

  @override
  String get shortcutUnavailableInBrowser => 'Indisponibil în browser';

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
  String get setToken => 'Setează tokenul';

  @override
  String get settingsLabel => 'Setări';

  @override
  String get settingsLanguage => 'Limbă';

  @override
  String get settingsLanguageDescription => 'Alege limba aplicației.';

  @override
  String get shortTask => 'Sarcină scurtă';

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
  String get skillOriginRegistry => 'Registry';

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
  String get suggestAChange => 'Sugerează o modificare';

  @override
  String get suggestLabel => 'SUGEREAZĂ';

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
  String get ticketLabel => 'TICHET';

  @override
  String get titleLabel => 'Titlu';

  @override
  String get todayLabel => 'Azi';

  @override
  String get toggleTheme => 'Comută tema';

  @override
  String get tokenConfigured =>
      'Configurat — clienții trebuie să prezinte acest token.';

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
  String get updateKey => 'Actualizează cheia';

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
  String get useWorkspaceDefault => 'Folosește implicitul spațiului de lucru';

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
  String get whenOffNoDefaultRoute =>
      'Când e oprit, sandbox-ul pornește fără o rută implicită.';

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
  String get focusModeActiveTooltip =>
      'Modul focus este activ — apasă pentru a încheia';

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
  String get pipelineStepBranch => 'Ramură';

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
      'Rulează cu bash -c. GITHUB_TOKEN este setat. Placeholderele sunt înlocuite înainte de execuție.';

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
  String get allowTicketingApi => 'Permite apeluri ticketing API';

  @override
  String get ticketingApiKey => 'Cheie API ticketing';

  @override
  String get ticketingApiKeySubtitle =>
      'Injectează cheia API a providerului de ticketing în sandbox.';

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
  String get agentQuestionFreeformOptionHint => 'Descrie în cuvintele tale…';

  @override
  String get reviewRequested => 'Revizuire solicitată';

  @override
  String get connectGitHubHint =>
      'Autentifică-te pe GitHub sau adaugă un token în Setări → Spațiu de lucru → Profil și identitate → Găzduire cod';

  @override
  String get connectGitHubToLoadPrs =>
      'Conectează GitHub ca să încarci pull request-uri';

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
  String get addAssignees => 'Adaugă asignați';

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
  String get composePrNoRepo => 'Niciun depozit GitHub selectat';

  @override
  String get composePrNoRepoHint =>
      'Selectează un spațiu de lucru cu un depozit legat de GitHub ca să deschizi un pull request.';

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
  String meetingsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# de întâlniri',
      few: '# întâlniri',
      one: '1 întâlnire',
      zero: 'Nicio întâlnire',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLedgerOpenActions => 'Acțiuni deschise';

  @override
  String get meetingsLedgerDecisions => 'Decizii';

  @override
  String get meetingsLiveOpen => 'Deschide înregistrarea';

  @override
  String get meetingTemplateShort => 'Șablon';

  @override
  String get meetingsStatThisWeek => 'Săptămâna aceasta';

  @override
  String get meetingsStatRecorded => 'Înregistrate';

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
  String get meetingsEnhancedPill => 'îmbunătățit';

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
  String get meetingDetectedRecord => 'Înregistrează';

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
  String ideSourceControlViewPr(int number) {
    return 'Vezi pull request-ul #$number';
  }

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
  String get mcpExternalServers => 'Servere MCP externe';

  @override
  String get mcpExternalServersDescription =>
      'Conectează-te la servere MCP externe (GitHub, Sentry, Postgres, automatizare browser). Servere pe care le-ai configurat pentru Claude, Cursor, VS Code și alte instrumente sunt descoperite automat.';

  @override
  String get mcpApprovalMode => 'Aprobare instrumente';

  @override
  String get mcpApprovalModeDescription =>
      'Ce acțiuni de instrumente rulează fără să întrebe. Citirile sunt întotdeauna permise; nivelurile superioare cer confirmare.';

  @override
  String get mcpApprovalAlwaysAsk => 'Întreabă întotdeauna';

  @override
  String get mcpApprovalWrite => 'Aprobă automat scrierile';

  @override
  String get mcpApprovalYolo => 'Aprobă tot automat';

  @override
  String get mcpNoExternalServers => 'Niciun server MCP extern descoperit.';

  @override
  String get mcpAuthorize => 'Autorizează';

  @override
  String get mcpReconnect => 'Reconectează';

  @override
  String get mcpExternalConnectionsNote =>
      'Serverele MCP externe rulează pe serverul de agenți (partajat de desktop și web). Autorizarea serverelor OAuth este disponibilă doar pe desktop.';

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
  String get usageAndCost => 'Utilizare și cost';

  @override
  String get usageAndCostDescription =>
      'Cheltuieli pe agenții tăi din ultimele 7 zile, din costurile observate ale rulărilor.';

  @override
  String get noUsageYet => 'Nicio utilizare înregistrată încă.';

  @override
  String get spentThisWeek => 'cheltuit săptămâna aceasta';

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
  String get subscriptionUsagePartiallyAvailable => 'Parțial disponibil';

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
  String get syncEngineSectionTitle => 'Motor de sincronizare';

  @override
  String get syncEngineDescription =>
      'Tichetele, mesageria și notele se actualizează live prin modificări incrementale mici, nu prin snapshot-uri complete. Oprirea unui comutator readuce acel depozit la modul snapshot complet — reîncarcă aplicația ca modificarea să aibă efect.';

  @override
  String get syncEngineTicketsTitle => 'Tichete';

  @override
  String get syncEngineMessagingTitle => 'Mesagerie';

  @override
  String get syncEngineNotesTitle => 'Note';

  @override
  String get syncEngineOnSubtitle =>
      'Sincronizarea live prin delta este activă';

  @override
  String get syncEngineOffSubtitle =>
      'Se folosește sincronizarea prin snapshot complet';

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
  String get keybindingCreateANewSpaceDescription => 'Creează un spațiu nou';

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
  String provisioningRunningSetupScript(String repo) {
    return 'Se rulează scriptul de setup pentru $repo…';
  }

  @override
  String get repoScriptsTitle => 'Scripturi';

  @override
  String get repoScriptsTooltip => 'Configurează scripturile de ciclu de viață';

  @override
  String get repoScriptsSetupLabel => 'Script de setup';

  @override
  String get repoScriptsSetupHelp =>
      'Rulează în worktree-ul spațiului imediat după creare — instalează dependențe, generează fișiere. Un eșec marchează spațiul ca eșuat; reîncercarea îl rulează din nou.';

  @override
  String get repoScriptsArchiveLabel => 'Script de arhivare';

  @override
  String get repoScriptsArchiveHelp =>
      'Rulează chiar înainte de ștergerea worktree-ului unui spațiu — curăță resursele din afara worktree-ului. Un eșec nu blochează niciodată ștergerea.';

  @override
  String get repoScriptsEnvHelp =>
      'Rulează prin bash din worktree, cu CC_WORKSPACE_PATH (worktree-ul), CC_ROOT_PATH (rădăcina depozitului), CC_SPACE_ID, CC_SPACE_NAME și CC_REPO_NAME setate.';

  @override
  String get repoScriptsSetupPlaceholder => 'de ex. pnpm install';

  @override
  String get repoScriptsArchivePlaceholder =>
      'de ex. docker compose -p \$CC_SPACE_ID down';

  @override
  String get repoScriptsRecentRuns => 'Rulări recente';

  @override
  String get repoScriptsNoRuns => 'Nicio rulare încă';

  @override
  String get repoScriptsSaved => 'Scripturi salvate';

  @override
  String get repoScriptsRunKindSetup => 'Setup';

  @override
  String get repoScriptsRunKindArchive => 'Arhivare';

  @override
  String get repoScriptsRunStatusRunning => 'În rulare';

  @override
  String get repoScriptsRunStatusSucceeded => 'Reușit';

  @override
  String get repoScriptsRunStatusFailed => 'Eșuat';

  @override
  String get repoScriptsRunStatusTimedOut => 'Expirat';

  @override
  String repoScriptsExitCode(int code) {
    return 'Cod de ieșire $code';
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
  String get presenceAgentThinking => 'Se gândește';

  @override
  String get presenceAgentRunning => 'În rulare';

  @override
  String get presenceAgentBlocked => 'Blocat';

  @override
  String get presenceAgentDone => 'Gata';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String presenceNameStatusCost(String name, String status, String cost) {
    return '$name — $status ($cost)';
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
  String get keybindingShowKeyboardShortcutsDescription =>
      'Afișează foaia de scurtături pentru ecranul curent';

  @override
  String get runPlaybookLabel => 'Rulează playbook';

  @override
  String get playbooksLabel => 'Playbook-uri';

  @override
  String get keybindingUndo => 'Anulează';

  @override
  String get keybindingRedo => 'Refă';

  @override
  String get keybindingUndoLastActionDescription =>
      'Anulează ultima acțiune reversibilă';

  @override
  String get keybindingRedoLastActionDescription =>
      'Refă ultima acțiune anulată';

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
  String get bannerMeetingJoin => 'Intră';

  @override
  String get bannerMeetingRecordAndLink => 'Înregistrează și leagă';

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
    return 'Menționează botul în $provider ca să pui un agent pe ceva sau creează tichete cu $command.';
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
    return 'Trimite această comandă botului în $provider. Funcționează o dată și expiră în 15 minute.';
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
  String get calendarUseBuiltinApp =>
      'Folosește aplicația Google a Control Center';

  @override
  String get calendarUseBuiltinAppHint =>
      'Aprobă cu contul tău Google. Nimic de configurat în Google Cloud.';

  @override
  String get calendarUseOwnClient => 'Folosește propriul client Google Cloud';

  @override
  String get calendarUseOwnClientHint =>
      'Introdu un client OAuth din propriul proiect Google Cloud.';

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
  String get settingsScopeBadgeYou => 'TU';

  @override
  String get settingsScopeBadgeDevice => 'ACEST DISPOZITIV';

  @override
  String get settingsScopeBadgeWorkspace => 'SPAȚIU DE LUCRU';

  @override
  String get settingsScopeBadgeServer => 'SERVER';

  @override
  String get settingsProfileDescription =>
      'Numele, e-mailul și identitatea git în acest spațiu. Schimbarea spațiului schimbă această suprapunere; identificatorul, autentificarea și dispozitivele rămân pe cont.';

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
      'Identitate, politică și convenții partajate de toți din acest spațiu de lucru.';

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
  String get fromEnvironment => 'din mediu';

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
  String get webConnectTitle => 'Conectează-te la Control Center';

  @override
  String get webConnectSubtitle =>
      'Apelează un cc-server în rulare prin WebSocket. Cheia rămâne pe acest dispozitiv.';

  @override
  String get webConnectServerLabel => 'Server';

  @override
  String get webConnectDeviceIdLabel => 'ID dispozitiv';

  @override
  String get webConnectPairingKeyLabel => 'Cheie de asociere';

  @override
  String get webConnectPairingKeyHint => 'lipește PSK-ul';

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
  String get conversationTitlesSectionTitle => 'Titluri de conversații';

  @override
  String get conversationTitlesSectionCaption =>
      'Alege runnerul care numește automat conversațiile noi din acest spațiu de lucru. Titlurile rămân oprite până se alege un adaptor și se aplică fiecărui membru.';

  @override
  String get conversationTitlesModelLabel => 'Model de titluri';

  @override
  String get conversationTitlesAdapterLabel => 'Adaptor';

  @override
  String get conversationTitlesAdapterHint => 'Oprit';

  @override
  String get conversationTitlesAdapterOff => 'Oprit';

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
  String get signInNotFinished =>
      'Autentificarea nu s-a întors încă. Termin-o în browser, apoi verifică din nou.';

  @override
  String get signedOutTitle => 'Ești deconectat';

  @override
  String get signedOutSubtitle =>
      'Conexiunea ta de găzduire de cod nu mai este validă — un token a expirat sau accesul i-a fost revocat. Nimic altceva nu s-a schimbat: autentifică-te din nou și totul e unde l-ai lăsat.';

  @override
  String get viaServerApp => 'prin aplicația acestui server';

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
  String get addKey => 'Adaugă cheie';

  @override
  String get providerApps => 'Aplicații provider';

  @override
  String get providerAppsDescription =>
      'Spațiile moștenesc acest GitHub App decât dacă aleg alt App sau un token de acces personal. Munca din fundal — webhook-uri, interogare, sync — rulează pe app, niciodată pe tokenul unei persoane.';

  @override
  String get providerAppId => 'App id';

  @override
  String get providerPrivateKey => 'Cheie privată';

  @override
  String get providerClientId => 'Client id';

  @override
  String get providerClientSecret => 'Client secret';

  @override
  String get providerApiKey => 'Cheie API';

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
  String deviceCodeInstructions(String provider) {
    return 'Introdu acest cod pe pagina $provider care tocmai s-a deschis. A fost copiat în clipboard.';
  }

  @override
  String get deviceCodeWaiting => 'Se așteaptă să termini în browser…';

  @override
  String get copyCodeAndOpen => 'Copiază codul și deschide';

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
  String get defaultChatDescription =>
      'Rulează conversațiile noi și orice agent fără un runner propriu.';

  @override
  String get shortTaskDescription =>
      'Rulează lucrul rapid de fundal, precum titluri și rezumate. Un model mai mic aparține aici.';

  @override
  String get settingsStateFailed => 'Eșuat';

  @override
  String get providerAppsGroupServer => 'Acționează ca serverul';

  @override
  String get providerAppsGroupServerDescription =>
      'Pentru spațiile care moștenesc GitHub App-ul acestei instalații. Un spațiu cu App sau PAT propriu se configurează în Spațiu de lucru → General.';

  @override
  String get providerAppsGroupPrConversations => 'Conversații de pull request';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      'Cum vorbesc dezvoltatorii cu acest server pe GitHub în spațiile moștenite. Un spațiu cu App propriu își are botul în Spațiu de lucru → General. Funcționează fără webhook sau URL public — serverul interoghează.';

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
  String get mcpNoTokenWarning =>
      'Fără un token, orice poate atinge acest port poate apela fiecare instrument.';

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
  String get sandboxBackendFieldDescription =>
      'Auto alege cel mai puternic pe care îl suportă această gazdă. Fixează unul ca să nu se schimbe sub tine.';

  @override
  String get sandboxCapabilitiesDescription =>
      'Găurile perforate prin graniță. Fiecare e ceva ce un agent izolat poate totuși face către lumea de afară.';

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
  String get archiveSpace => 'Arhivează spațiul';

  @override
  String get archivedSpaces => 'Spații arhivate';

  @override
  String get archivedSpacesEmpty => 'Niciun spațiu arhivat';

  @override
  String get restoreSpace => 'Restaurează';

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
  String get asideUnavailable =>
      'Setează un model one-shot în setările spațiului de lucru ca să folosești asta';

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
  String get repoScriptsTest => 'Test';

  @override
  String get repoScriptsTestTooltip =>
      'Rulează acest draft într-o clonă de unică folosință a depozitului';

  @override
  String get repoScriptsRunKindTest => 'Test';

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
      'Niciun snapshot încă. Unul e făcut doar când îl ceri — nimic nu e programat.';

  @override
  String get backupSnapshotComplete => 'Complet';

  @override
  String get backupSnapshotIncomplete => 'Incomplet';

  @override
  String get backupSnapshotIncompleteNote =>
      'Manifestul lipsește sau numește fișiere care nu sunt acolo, deci acest snapshot nu poate restaura întreaga instalare. Fișierele de spațiu de lucru pe care le are pot fi totuși adoptate unul câte unul.';

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
      'Această conexiune atinge serverul printr-un releu, care nu transportă fișiere. Conectează-te direct la server ca să descarci sau să încarci un backup.';

  @override
  String get backupTransferForbidden =>
      'Serverul a refuzat. Descărcarea unui spațiu de lucru necesită rolul de admin, restaurarea unuia necesită proprietar, iar un snapshot întreg necesită operatorul instalării.';

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
  String get workspaceGitHubIdentity => 'Identitate GitHub';

  @override
  String get workspaceGitHubIdentityDescription =>
      'Cum se autentifică munca GitHub din fundal în acest spațiu de lucru. Moștenește App-ul instalației, folosește alt App sau doar un token de acces personal.';

  @override
  String get workspaceGitHubModeInherit =>
      'Folosește GitHub App-ul acestei instalații';

  @override
  String get workspaceGitHubModeApp => 'Folosește un alt GitHub App';

  @override
  String get workspaceGitHubModePat => 'Doar token de acces personal';

  @override
  String get workspaceGitHubInheritHint =>
      'Folosește GitHub App-ul din Server → Aplicații furnizor.';

  @override
  String get workspaceGitHubAppHint =>
      'Identitatea de bot și de interogare a acestui spațiu. Membrii se autentifică în Tu prin acest App.';

  @override
  String get workspaceGitHubPatLabel => 'Token de fundal';

  @override
  String get workspaceGitHubPatDescription =>
      'Pentru interogare și agenți în acest spațiu. Nu este tokenul de profil al unui membru.';

  @override
  String get workspaceGitHubHasPat => 'Un token de fundal este stocat.';

  @override
  String get workspaceGitHubNoPat => 'Niciun token de fundal stocat.';

  @override
  String get profileOverlayHint =>
      'Aceste câmpuri ești tu în acest spațiu. Câmpurile goale moștenesc numele și e-mailul contului. Schimbarea spațiului schimbă această suprapunere.';

  @override
  String get forgeConnectionsThisWorkspace =>
      'Autentifică-te sau lipește un token pentru acest spațiu de lucru.';
}
