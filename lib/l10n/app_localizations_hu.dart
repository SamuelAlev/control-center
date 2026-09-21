// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get succeeded => 'Sikeres';

  @override
  String agentRunRetryLabel(int number, String time) {
    return 'Újrapróbálás #$number · $time';
  }

  @override
  String agentRunStarting(String time) {
    return 'Indítás · $time';
  }

  @override
  String get agentActivityFollowingLive => 'Élő tevékenység követése';

  @override
  String get agentActivityJumpToLatest => 'Ugrás a legújabbra';

  @override
  String get agentActivityLoadFailed =>
      'Nem sikerült betölteni ennek a futtatásnak a tevékenységét';

  @override
  String get agentActivityNotRecorded =>
      'Ehhez a futtatáshoz nem került rögzítésre tevékenység';

  @override
  String get agentActivityNotRecordedHint =>
      'A tevékenység rögzítése előtt befejezett futtatásoknak nincs idővonaluk.';

  @override
  String get agentActivityRunUnavailable => 'Ez a futtatás már nem érhető el';

  @override
  String agentActivitySubagentOf(String agent) {
    return '$agent alügynöke';
  }

  @override
  String get agentActivityUnsupported =>
      'A tevékenység rögzítése nem érhető el a csatlakoztatott szerveren';

  @override
  String get agentActivityUnsupportedHint =>
      'Indítsa újra az alkalmazást, hogy felvegye a legújabb szerverbuildet.';

  @override
  String get agentActivityWaiting => 'Várakozás a tevékenységre…';

  @override
  String get created => 'Létrehozva';

  @override
  String get dictationStart => 'Diktálás indítása';

  @override
  String get dictationListening => 'Figyelés…';

  @override
  String get dictationUnavailable =>
      'A diktáláshoz hangmodell kell a szervergépen. Állítson be egyet a hangbeállításokban.';

  @override
  String get dictationFailedToStart => 'Nem sikerült elindítani a diktálást';

  @override
  String get dictationHoldToTalkTitle => 'Nyomva tartva beszélhet';

  @override
  String get dictationHoldToTalkDescription =>
      'Tartsa lenyomva a mikrofon gombot vagy a gyorsbillentyűt a diktáláshoz, és engedje el a leállításhoz. Ha ki van kapcsolva, egyszer nyomja meg az indításhoz, majd újra a leállításhoz.';

  @override
  String get focusConversation => 'Fókusz a beszélgetésre';

  @override
  String get ideAgentActivity => 'Ügynöktevékenység';

  @override
  String get keybindingPushToTalk => 'Nyomva beszélhet';

  @override
  String get keybindingPushToTalkDescription =>
      'Hangdiktálás nyomva tartása vagy váltása az üzenetszerkesztőben';

  @override
  String get agentPermissions => 'Ügynökjogosultságok';

  @override
  String get agentPermissionsSettingsDescription =>
      'Határozza meg, mit tehetnek az ügynökök maguktól, miről kell előbb kérdezniük, és mit soha — munkaterületenként, ügynökönként vagy térenként.';

  @override
  String get agentPermissionsMatrixDescription =>
      'Állítson be döntést minden hatásfajtához. A szabályok kaszkádolnak: a tér felülírja az ügynököt, az ügynök a munkaterületet, a munkaterület a módkészletet. A legspecifikusabb szabály érvényesül.';

  @override
  String get guardrailLoading => 'Szabályok betöltése…';

  @override
  String get guardrailRulesLoadFailed =>
      'Nem sikerült betölteni a jogosultsági szabályokat.';

  @override
  String get guardrailScopeWorkspace => 'Munkaterület';

  @override
  String get guardrailScopeAgent => 'Ügynök';

  @override
  String get guardrailScopeSpace => 'Tér';

  @override
  String get guardrailSelectAgent => 'Ügynök kiválasztása';

  @override
  String get guardrailSelectSpace => 'Tér kiválasztása';

  @override
  String get guardrailNoAgents =>
      'Még nincsenek ügynökök ebben a munkaterületben.';

  @override
  String get guardrailNoSpaces =>
      'Még nincsenek terek ebben a munkaterületben.';

  @override
  String get guardrailClassFileDelete => 'Fájl törlése';

  @override
  String get guardrailClassFileWriteOutsideWorktree =>
      'Írás a worktree-n kívül';

  @override
  String get guardrailClassGitCommit => 'Commit létrehozása';

  @override
  String get guardrailClassGitPush => 'Küldés távoli tárolóra';

  @override
  String get guardrailClassPrCreate => 'Pull request megnyitása';

  @override
  String get guardrailClassPrPublish => 'Átnézés vagy összefésülés közzététele';

  @override
  String get guardrailClassVendorSyncWrite => 'Írás külső követőbe';

  @override
  String get guardrailClassNetworkEgress => 'Hálózati hozzáférés';

  @override
  String get guardrailClassSecretAccess => 'Titok olvasása';

  @override
  String get guardrailClassPackageInstall => 'Csomag telepítése';

  @override
  String get guardrailClassProcessSpawn => 'Folyamat futtatása';

  @override
  String get guardrailClassWorkspaceMutation =>
      'Munkaterület szerkezetének módosítása';

  @override
  String get guardrailClassEnclosureControl =>
      'Elszigetelt környezet (állomás) irányítása';

  @override
  String get navRigs => 'Állomások';

  @override
  String get rigsUnsupportedServer =>
      'Ez a kiszolgáló nem tud rig-felületeket üzemeltetni. Ellenőrizze a használni kívánt gépre vonatkozó gazdagépkövetelményeket.';

  @override
  String get rigSurfaceComputer => 'Számítógép';

  @override
  String get rigSurfaceBrowser => 'Böngésző';

  @override
  String get rigSurfaceAndroid => 'Android';

  @override
  String get rigSurfaceIosSimulator => 'iOS-szimulátor';

  @override
  String rigSurfaceBrowserEngine(String engine) {
    return '$engine';
  }

  @override
  String rigBrowserEngineHint(String engine) {
    return 'Eldobható $engine, elszigetelve a gépétől. Nyisson egy másik motort, hogy ugyanazt az oldalt egymás mellett hasonlítsa össze.';
  }

  @override
  String get rigPhaseReady => 'Kész';

  @override
  String get rigPhaseStarting => 'Indítás';

  @override
  String get rigPhaseParked => 'Parkolva';

  @override
  String get rigPhaseClosing => 'Leállítás';

  @override
  String get rigPhaseClosed => 'Leállítva';

  @override
  String get rigPhaseFailed => 'Sikertelen';

  @override
  String get rigPhaseUnknown => 'Ismeretlen';

  @override
  String get rigNotAccelerated => 'Emulált';

  @override
  String get rigAudioListen => 'Gép hangjának hallgatása';

  @override
  String get rigAudioMute => 'Gép némítása';

  @override
  String get rigYouHaveControl => 'Ön irányít';

  @override
  String get rigBackendAvailable => 'Elérhető';

  @override
  String get rigBackendUnavailable => 'Nem elérhető';

  @override
  String get rigEgressNotEnforced =>
      'A hálózat ezen a háttéren nincs elszigetelve — a saját kapcsolódását kezeli.';

  @override
  String get rigStartMachine => 'Gép indítása';

  @override
  String get rigStartHint =>
      'Eldobható VM-et indít, amelyet Ön és az ügynökei megosztanak ehhez a beszélgetéshez. Bezáráskor megsemmisül, és semmi benne nem érinti a számítógépét.';

  @override
  String get rigStartAndroidHint =>
      'Csatlakozik egy, a szerveren már futó Android-emulátorhoz. A hálózati hozzáférés nincs elkülönítve.';

  @override
  String get rigStartIosHint =>
      'Létrehoz egy ideiglenes iOS-szimulátort egy macOS-kiszolgálón. A tesztkörnyezet bezárásakor törlődik; a hálózati hozzáférés nincs elkülönítve.';

  @override
  String get rigTechnicalDetails => 'Műszaki részletek';

  @override
  String get rigStopMachine => 'Gép leállítása';

  @override
  String get rigHomeButton => 'Kezdőképernyő';

  @override
  String get rigRotateClockwise => 'Forgatás óramutató szerint';

  @override
  String get rigRotateCounterclockwise => 'Forgatás óramutatóval ellentétesen';

  @override
  String get rigTakeScreenshot => 'Képernyőkép készítése';

  @override
  String get rigScreenshotSaved => 'Képernyőkép mentve';

  @override
  String rigScreenshotSaveFailed(String error) {
    return 'A képernyőképet nem sikerült menteni: $error';
  }

  @override
  String get rigSurfaceUnavailable =>
      'Ez a szerver nem tud ilyen gépet futtatni.';

  @override
  String get rigTabNeedsConversation =>
      'Először nyisson beszélgetést — a gép egyhez tartozik, így Ön és az ügynökei ugyanazt a képernyőt látják.';

  @override
  String get ideMenuSectionTools => 'Eszközök';

  @override
  String get ideMenuSectionMachines => 'Gépek';

  @override
  String get ideMenuSectionReopen => 'Újranyitás';

  @override
  String get ideMenuSearchHint => 'Keresés';

  @override
  String get ideMenuNoMatches => 'Nincs találat';

  @override
  String get rigMenuComputer => 'Számítógép';

  @override
  String get rigMenuBrowser => 'Böngésző';

  @override
  String get rigMenuAndroid => 'Android';

  @override
  String get rigMenuIosSimulator => 'iOS-szimulátor';

  @override
  String rigLabelNumbered(String label, String suffix) {
    return '$label $suffix';
  }

  @override
  String ideCloseKeepTitle(String name) {
    return 'Bezárja: $name?';
  }

  @override
  String get ideCloseKeepBodyMachine =>
      'A gép a háttérben tovább fut — bármikor újranyithatja az oldalsávból. Állítsa le, ha most szeretné felszabadítani a memóriáját.';

  @override
  String get ideCloseKeepBodyShell =>
      'A parancs a háttérben tovább fut — a shellt bármikor újranyithatja az oldalsávból. Fejezze be, ha most szeretné leállítani, amit csinál.';

  @override
  String get ideCloseKeepBodyAgent =>
      'Az ügynök a háttérben tovább dolgozik — a beszélgetést bármikor újranyithatja az oldalsávból. Állítsa le, ha most szeretné befejezni a futtatást.';

  @override
  String get ideCloseKeepRunning => 'Futtatás folytatása';

  @override
  String get ideCloseShutDownMachine => 'Leállítás';

  @override
  String get ideCloseEndShell => 'Shell befejezése';

  @override
  String get ideCloseStopAgent => 'Ügynök leállítása';

  @override
  String get rigsSettingsSubtitle =>
      'Mit tud ez a szerver indítani, milyen alapképekre van szüksége, és mely gépek futnak most';

  @override
  String get rigsCapabilitiesTitle => 'Ez a szerver';

  @override
  String get rigInstallIosAutomation => 'Az iOS-automatizálási híd telepítése';

  @override
  String get rigInstallingIosAutomation =>
      'Az iOS-automatizálási híd telepítése folyamatban…';

  @override
  String get rigIosAutomationInstalled => 'Az iOS-automatizálási híd telepítve';

  @override
  String get rigsImagesTitle => 'Alapképek';

  @override
  String get rigsImagesHint =>
      'Minden állomás ezekből az írásvédett képekből indul. Minden munkamenet egy eldobható overlayre ír, így egy állomás soha nem változtathatja meg, amiből a következő indul.';

  @override
  String get rigsRunningTitle => 'Most fut';

  @override
  String get rigsNoneRunning => 'Nincs futó gép.';

  @override
  String get rigsCustomImagesTitle => 'Egyéni képek (ez a munkaterület)';

  @override
  String get rigsCustomImagesHint =>
      'Irányítsa a Terminál (VM) vagy Böngésző (VM) felületet a saját képére — bővítse az alapértelmezetteket a projekt eszközeivel, vagy használjon bármely kompatibilis képet egy registryből. Az új gépek ezt használják; a futók megtartják a sajátjukat. Az állomások útmutatója leírja, mit kell egy képnek nyújtania.';

  @override
  String get rigsCustomTerminalImageLabel => 'Terminál (VM) kép';

  @override
  String get rigsCustomBrowserImageLabel => 'Böngésző (VM) kép';

  @override
  String get rigsCustomImagePlaceholder =>
      'pl. ghcr.io/acme/dev-shell:1.2 — hagyja üresen az alapértelmezetthez';

  @override
  String get rigsCustomImageInvalid =>
      'Adjon meg egy registryhivatkozást, pl. repo/name:tag. Helyi útvonalak és archívumok nem engedélyezettek.';

  @override
  String get rigsCustomImageSaved =>
      'Mentve. Az új gépek ebből a képből indulnak; a futók megtartják a sajátjukat.';

  @override
  String get rigsEgressTitle => 'Böngésző kimenő forgalom (ez a munkaterület)';

  @override
  String get rigsEgressHint =>
      'További hosztok, amelyeket az elszigetelt böngésző elérhet — soronként egy: pontos hoszt (api.example.com) vagy helyettesítő a aldomainekhez (*.example.com). A termékoldal mindkét esetben engedélyezett marad. Az új gépek megkapják a listát; a futók megtartják, amivel indultak.';

  @override
  String rigsEgressInvalid(String host) {
    return 'A(z) „$host” nem érvényes hosztbejegyzés.';
  }

  @override
  String get rigsEgressSaved =>
      'Mentve. Az új böngészőgépek beengedik ezeket a hosztokat; a futók megtartják a sajátjukat.';

  @override
  String get rigImageInstalled => 'Telepítve';

  @override
  String get rigImageNotDownloaded => 'Nincs letöltve';

  @override
  String get rigImageNotPublished => 'Nincs közzétéve';

  @override
  String get rigImageNotPublishedHint =>
      'Ehhez még nem tettek közzé képet, így nincs mit letölteni. Importáljon egy kompatibilis lemezképet az engedélyezéshez.';

  @override
  String get rigImageDownload => 'Letöltés';

  @override
  String get rigImageDownloading => 'Letöltés…';

  @override
  String get rigImageImport => 'Importálás';

  @override
  String get rigImageImportMessage =>
      'Útvonal egy qcow2 lemezképhez a szerver fájlrendszerén. A képtárba másolódik, így a fájl utána elmozdítható.';

  @override
  String get rigConnectingStream => 'Csatlakozás az állomáshoz';

  @override
  String get rigStreamNotAllowed => 'Nincs hozzáférése ehhez az állomáshoz.';

  @override
  String get rigStreamNotRunning => 'Ez az állomás már nem fut.';

  @override
  String get rigStreamNeedsFfmpeg =>
      'Az élő nézethez ffmpeg kell ezen a gépen. Telepítse az ffmpeg-et, és nyissa újra a lapot.';

  @override
  String get rigStreamEnded => 'Az élő nézet véget ért.';

  @override
  String get rigStreamFailed => 'Az élő nézetet nem sikerült megnyitni.';

  @override
  String get rigStreamDisconnected => 'Nincs csatlakozva szerverhez.';

  @override
  String rigDropSendingOne(String name) {
    return '„$name” másolása a gépbe…';
  }

  @override
  String rigDropSendingMany(int count) {
    return '$count fájl másolása a gépbe…';
  }

  @override
  String get rigTerminalDropSending => 'Másolás a gépbe…';

  @override
  String get rigTerminalPasteImage => 'Beillesztett kép mentve a gépen';

  @override
  String get rigPortsTitle => 'Továbbított portok';

  @override
  String get rigPortsTooltip => 'A gépen belül nyitott portok';

  @override
  String get rigPortsEmpty =>
      'Még semmi sem figyel. Indítson egy szervert a terminálban — egy 3000-es porton futó fejlesztői szerver itt jelenik meg.';

  @override
  String get rigPortsAdd => 'Port hozzáadása';

  @override
  String get rigPortsAddHint => 'Továbbítandó vendégport (pl. 3000)';

  @override
  String get rigPortsAutoForward => 'Portok automatikus továbbítása';

  @override
  String get rigPortsCopyUrl => 'Helyi URL másolása';

  @override
  String rigPortsCopiedUrl(String url) {
    return 'Másolva: $url';
  }

  @override
  String get rigPortsStopForward => 'Továbbítás leállítása';

  @override
  String get rigPortsExposeLan => 'Megosztás a helyi hálózaton';

  @override
  String get rigPortsLanPrivate => 'Csak helyi';

  @override
  String get rigPortsLanShared => 'A hálózaton';

  @override
  String get rigPortsSetDomain => 'Böngésződomain beállítása (.test)';

  @override
  String get rigPortsDomainHint =>
      'Domain a Böngésző (VM) számára, pl. myapp.test — ott elérhető, a hoszton nem';

  @override
  String get rigPortsProcessUnknown => 'ismeretlen folyamat';

  @override
  String get rigPortsInactive => 'nem figyel';

  @override
  String get rigPortsTooltipHost => 'Nyitott portok ebben a terminálban';

  @override
  String get rigPortsEmptyHost =>
      'Ebben a terminálban még semmi sem figyel. Indíts egy szervert, és itt megjelenik.';

  @override
  String get rigPortsAddHintHost => 'Leképezendő port (pl. 5173)';

  @override
  String get rigPortsLocalPortHint => 'Helyi port (nem kötelező)';

  @override
  String rigPortsDestDesktop(int port) {
    return 'localhost:$port';
  }

  @override
  String rigPortsDestBrowser(int port) {
    return 'localhost:$port a böngészőben (VM)';
  }

  @override
  String get rigPortsDestBrowserUnreachable => 'böngésző (VM) nincs csatolva';

  @override
  String rigPortsDestAndroid(int port) {
    return 'localhost:$port Androidon';
  }

  @override
  String get rigPortsDestAndroidUnreachable => 'Android nincs csatolva';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# alapkép vár még letöltésre',
      one: '# alapkép vár még letöltésre',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => 'Engedélyezés';

  @override
  String get guardrailDecisionPrompt => 'Előbb kérdezzen';

  @override
  String get guardrailDecisionDeny => 'Tiltás';

  @override
  String get guardrailSourceThisScope => 'Ez a hatókör';

  @override
  String get guardrailSourceDefault => 'Beépített alapértelmezett';

  @override
  String get guardrailSourcePreset => 'Módkészlet';

  @override
  String get guardrailSourceInherited => 'Örökölt';

  @override
  String get guardrailClearToInherited => 'Törlés örököltre';

  @override
  String get guardrailWhatIf => 'Mi lenne, ha?';

  @override
  String get guardrailWhatIfDescription =>
      'Nézze meg, hogyan oldanák meg a jelenlegi szabályok egy műveletet, ugyanazzal a logikával, amit az ügynökök használnak.';

  @override
  String get guardrailProbeActionLabel => 'Művelet';

  @override
  String get guardrailProbeCommandLabel => 'Parancs (nem kötelező)';

  @override
  String get guardrailProbeCommandHint => 'pl. git push origin main';

  @override
  String get guardrailProbeAgentLabel => 'Ügynök (nem kötelező)';

  @override
  String get guardrailProbeSpaceLabel => 'Tér (nem kötelező)';

  @override
  String get guardrailProbeNone => 'Nincs';

  @override
  String get guardrailProbeModeLabel => 'Mód';

  @override
  String get guardrailProbeResult => 'Eredmény';

  @override
  String get guardrailProbeSource => 'Forrás:';

  @override
  String get guardrailAdapterMatrix => 'Hol érvényesülnek a szabályok';

  @override
  String get guardrailAdapterMatrixDescription =>
      'Őszinte referencia: hol akad fenn ténylegesen az egyes hatások, ügynökfuttatónként. Ez a valóságot dokumentálja, nem garanciát — a futtató sávon kívüli hatásait nem lehet elfogni.';

  @override
  String get guardrailEffectColumn => 'Hatás';

  @override
  String get guardrailAdapterHarness => 'Beépített harness';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => 'Homokozó alsó korlát';

  @override
  String get guardrailEnforcementPolicyGate => 'Szabálykapu';

  @override
  String get guardrailEnforcementSandbox => 'Csak homokozó';

  @override
  String get guardrailEnforcementNone => 'Nem érvényesíthető';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      'A jogosultsági döntés a hatás futása előtt ellenőrződik, és blokkolhatja.';

  @override
  String get guardrailEnforcementSandboxHelp =>
      'Csak a homokozó korlátozza; a jogosultsági szabályt nem kérdezik meg.';

  @override
  String get guardrailEnforcementNoneHelp =>
      'A döntés csak tanácsadó — itt nem lehet elfogni.';

  @override
  String get obsStatCost => 'költség';

  @override
  String obsStatDelegatedCost(String amount) {
    return '+$amount delegált';
  }

  @override
  String get obsStatDuration => 'időtartam';

  @override
  String get obsStatTokens => 'tokenek';

  @override
  String get obsStatTools => 'eszközök';

  @override
  String get openAgentActivity => 'Tevékenység megnyitása';

  @override
  String get orgChart => 'Szervezeti ábra';

  @override
  String get orgChartEmpty => 'Még nincsenek ügynökök';

  @override
  String get navCalendar => 'Naptár';

  @override
  String get serverConnection => 'Szerverkapcsolat';

  @override
  String get serverModeLocal => 'Futtatás ebben az alkalmazásban';

  @override
  String get serverModeLocalDescription =>
      'A Control Center saját szervert futtat ezen a gépen, és helyben birtokolja az adatait.';

  @override
  String get serverModeRemote => 'Csatlakozás távoli példányhoz';

  @override
  String get serverModeRemoteDescription =>
      'Csatlakozzon egy máshol futó Control Center szerverhez. Az adatai azon a szerveren élnek.';

  @override
  String get serverRemoteUrl => 'Szerver URL';

  @override
  String get serverRemoteDeviceId => 'Eszköz-ID';

  @override
  String get serverRemotePairingKey => 'Párosítási kulcs';

  @override
  String get serverRemotePairingKeyHint =>
      'Illessze be a távoli szerver párosítási kulcsát';

  @override
  String get serverSetupInviteCode => 'Meghívókód';

  @override
  String get serverSetupInviteCodeHint =>
      'Illesszen be egy egyszeri meghívókódot (hagyja üresen párosítási kulcshoz)';

  @override
  String get serverDiscoveryTooltip => 'Szerverek keresése a hálózaton';

  @override
  String get serverDiscoveryTitle => 'Szerverek a hálózaton';

  @override
  String get serverDiscoverySearching => 'Szerverek keresése…';

  @override
  String get serverDiscoveryEmpty =>
      'Nem található szerver. Ellenőrizze, hogy a szerver fut, és hogy ez az eszköz eléri, majd keressen újra.';

  @override
  String get serverDiscoveryRefresh => 'Keresés újra';

  @override
  String get serverListActive => 'Aktív';

  @override
  String get serverListSwitch => 'Váltás';

  @override
  String get serverListAddTitle => 'Szerver hozzáadása';

  @override
  String get serverListRemoveActiveHint =>
      'Váltson másik szerverre, mielőtt eltávolítja ezt.';

  @override
  String get serverSwitchFailedTitle => 'Nem sikerült szervert váltani';

  @override
  String get serverListInsecureBadge => 'Nem biztonságos';

  @override
  String get connectionPathLocal => 'Helyi';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => 'Leállítás';

  @override
  String get shutdownSubtitle => 'A helyi szerver bezárása';

  @override
  String get shutdownServiceApprovals => 'Jóváhagyások';

  @override
  String get shutdownServiceBackgroundJobs => 'Háttérfeladatok';

  @override
  String get shutdownServiceScheduler => 'Feladatütemező';

  @override
  String get shutdownServiceCalendar => 'Naptár szinkronizálás';

  @override
  String get shutdownServiceWeather => 'Időjárás';

  @override
  String get shutdownServiceSoundscape => 'Hangtáj';

  @override
  String get shutdownServiceMeetings => 'Megbeszélések';

  @override
  String get shutdownServiceVoiceModels => 'Hangmodellek';

  @override
  String get shutdownServiceNetworking => 'Hálózat';

  @override
  String get shutdownServicePresence => 'Jelenlét';

  @override
  String get shutdownServiceDataSync => 'Adatszinkronizálás';

  @override
  String get shutdownServiceDeviceRelay => 'Eszközrelé';

  @override
  String get shutdownServiceMcpConnections => 'MCP-kapcsolatok';

  @override
  String get shutdownServiceCodeEditors => 'Kódszerkesztők';

  @override
  String get serverSharingTitle => 'Szerver megosztása';

  @override
  String get serverSharingDescription =>
      'Tegye ezt a szervert elérhetővé a többi eszközéről. Semmi sem kerül nyilvánosságra, hacsak alább nem kapcsol be egy alagutat. A párosítási meghívók automatikusan beágyazzák a szerver aktuális címeit — hozza létre őket a munkaterület beállításaiban.';

  @override
  String get serverSharingUnavailable =>
      'A megosztási vezérlők nem érhetők el ezen a szerveren.';

  @override
  String get serverSharingMdnsLabel => 'LAN-felderítés';

  @override
  String get serverSharingMdnsOn =>
      'Ez a szerver hirdeti magát a helyi hálózaton (mDNS)';

  @override
  String get serverSharingMdnsOff => 'Nem hirdet a helyi hálózaton (mDNS)';

  @override
  String get serverSharingTunnelLabel => 'Alagút';

  @override
  String get serverSharingTunnelHelper =>
      'Az alagút bekapcsolása internetről is elérhetővé teszi a szervert. A nyilvános kitettség opcionális, és alapból ki van kapcsolva.';

  @override
  String get serverSharingProviderOff => 'Ki';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => 'Nyilvános URL';

  @override
  String get serverSharingTunnelStarting => 'Alagút indítása…';

  @override
  String serverSharingTunnelError(String error) {
    return 'Alagúthiba: $error';
  }

  @override
  String get serverSharingTunnelUpNoUrl =>
      'Az alagút üzemel. Érje el a beállított DNS-hostnéven.';

  @override
  String get serverSharingRelayLabel => 'Relé';

  @override
  String serverSharingRelayUsage(String amount) {
    return 'Relézve ebben a hónapban: $amount';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return 'Aktív relémunkamenetek: $count';
  }

  @override
  String get serverSharingUpdateFailedTitle =>
      'Nem sikerült frissíteni a megosztást';

  @override
  String get pairNewClient => 'Új kliens párosítása';

  @override
  String get pairClientNameHint => 'Címkézze a klienst (pl. Munkalaptop)';

  @override
  String get pairClientTypeWeb => 'Webböngésző';

  @override
  String get pairClientTypeDesktop => 'Asztali alkalmazás';

  @override
  String get pairClientTypePhone => 'Telefon';

  @override
  String get pairAction => 'Párosítás';

  @override
  String get revoke => 'Visszavonás';

  @override
  String get pairCredentialsIntro =>
      'Csatlakoztassa az új klienst ezekkel az adatokkal, vagy nyissa meg benne a hivatkozást.';

  @override
  String get pairLinkLabel => 'Hivatkozás';

  @override
  String get pairScanQr =>
      'Olvassa be ezt a QR-kódot a telefon kamerájával a párosításhoz.';

  @override
  String get pairServerUnreachableTitle => 'Nem elérhető';

  @override
  String get pairServerUnreachable =>
      'Más eszközök nem érik el közvetlenül ezt a szervert, így egy új kliens nem tud csatlakozni. Állítsa be a szerver nyilvános URL-jét további kliensek párosításához.';

  @override
  String get serverSetupTitle => 'Hogyan fusson a Control Center?';

  @override
  String get serverSetupSubtitle =>
      'A Control Centernek szerverre van szüksége, amely birtokolja az adatait. Futtasson egyet ebben az alkalmazásban, vagy csatlakozzon egy máshol futó példányhoz.';

  @override
  String get serverSetupRunLocal => 'Futtatás ebben az alkalmazásban';

  @override
  String get serverSetupConnect => 'Csatlakozás';

  @override
  String get serverSetupInvalidUrl =>
      'Adjon meg érvényes ws:// vagy wss:// szerver-URL-t.';

  @override
  String get serverSetupCouldNotConnect => 'Nem sikerült csatlakozni';

  @override
  String get serverSetupErrorUnreachable =>
      'Nem értük el a szervert. Ellenőrizze, hogy fut, és hogy ez az eszköz eléri (ugyanaz a hálózat vagy relé).';

  @override
  String get serverSetupErrorIdentityMismatch =>
      'A szerver identitása nem egyezik az ezen az eszközön mentettel. Ha a szervert újratelepítették vagy visszaállították, távolítsa el a mentett szervert, és párosítson újra.';

  @override
  String get serverSetupErrorAuthRejected =>
      'A szerver elutasította ezt az eszközt. Ellenőrizze, hogy a párosítási kulcs és az eszköz-ID megegyezik azzal, amit a szerver kiadott.';

  @override
  String get serverSetupErrorInviteRejected =>
      'Ez a meghívókód érvénytelen vagy lejárt. Kérjen egy újat.';

  @override
  String get serverSetupErrorGeneric =>
      'Hiba történt a csatlakozás közben. Nyissa ki az alábbi technikai részleteket a további információért.';

  @override
  String get serverSetupErrorDetails => 'Technikai részletek';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# további',
      one: '# további',
    );
    return '$_temp0';
  }

  @override
  String get calendarAllDayGutter => 'Egész napos';

  @override
  String calendarAllDayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# esemény',
      one: '# esemény',
    );
    return '$_temp0';
  }

  @override
  String get calendarCollapseAllDay => 'Egész napos események összecsukása';

  @override
  String get calendarExpandAllDay => 'Egész napos események kinyitása';

  @override
  String get calendarViewMonth => 'Hónap';

  @override
  String get calendarViewWeek => 'Hét';

  @override
  String get calendarViewAgenda => 'Napirend';

  @override
  String get calendarConnectGoogle => 'Google Calendar csatlakoztatása';

  @override
  String get calendarConnectDescription =>
      'Szinkronizálja a Google Calendar naptárát, hogy itt lássa az eseményeket, és riasztást kapjon a megbeszélések előtt.';

  @override
  String get calendarDisconnect => 'Leválasztás';

  @override
  String get calendarReconnect => 'Újracsatlakozás';

  @override
  String get calendarEmptyNoEvents => 'Nincs esemény ebben a tartományban';

  @override
  String get calendarStartRecording => 'Felvétel indítása';

  @override
  String get calendarStartRecordingAndLink =>
      'Felvétel indítása és összekapcsolás';

  @override
  String get calendarJoinMeet => 'Csatlakozás a megbeszéléshez';

  @override
  String get calendarFromCalendar => 'Naptárból';

  @override
  String get calendarLinkedMeeting => 'Összekapcsolt megbeszélés';

  @override
  String get calendarToday => 'Ma';

  @override
  String get calendarAllDay => 'Egész nap';

  @override
  String calendarWeekNumber(int number) {
    return '$number. hét';
  }

  @override
  String get calendarPreviousPeriod => 'Előző';

  @override
  String get calendarNextPeriod => 'Következő';

  @override
  String calendarLastSynced(String time) {
    return 'Szinkronizálva $time';
  }

  @override
  String get calendarNeverSynced => 'Még nincs szinkronizálva';

  @override
  String get calendarSyncing => 'Szinkronizálás…';

  @override
  String get calendarViewDay => 'Nap';

  @override
  String get calendarShow => 'Megjelenítés';

  @override
  String get calendarHide => 'Elrejtés';

  @override
  String get calendarRsvpGoing => 'Elmegy?';

  @override
  String get calendarRsvpYes => 'Igen';

  @override
  String get calendarRsvpNo => 'Nem';

  @override
  String get calendarRsvpMaybe => 'Talán';

  @override
  String get calendarRsvpFailed => 'Nem sikerült frissíteni a válaszát';

  @override
  String get calendarAddAccount => 'Naptárfiók hozzáadása';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Csatlakoztass Google-fiókot az események szinkronizálásához ebbe a munkaterületbe. Ezek a naptárak itt a tieid.';

  @override
  String get calendarConnecting => 'Csatlakozás…';

  @override
  String get calendarSyncNow => 'Szinkronizálás most';

  @override
  String get calendarNoWorkspace =>
      'Válasszon munkaterületet a naptár megtekintéséhez';

  @override
  String get calendarConnectError =>
      'Nem sikerült csatlakoztatni a Google Calendar naptárat';

  @override
  String get calendarClientIdLabel => 'Kliens-ID';

  @override
  String get calendarClientSecretLabel => 'Kliens titok';

  @override
  String get calendarConnectCredsHint =>
      'Adja meg a projekt Google OAuth eszközkódos kliens-ID-ját és titkát. A szerver futtatja a kapcsolatot és a szinkront — a böngésző soha nem tartja a tokeneket.';

  @override
  String get calendarConnectApproveInstruction =>
      'Nyissa meg az ellenőrző oldalt bármely eszközön, jelentkezzen be, és adja meg ezt a kódot:';

  @override
  String get calendarConnectOpenPage => 'Ellenőrző oldal megnyitása';

  @override
  String get calendarConnectWaiting => 'Várakozás a jóváhagyásra…';

  @override
  String get calendarConnectDenied =>
      'A felhatalmazást elutasították. Próbálja újra.';

  @override
  String get calendarConnectExpired => 'A kód lejárt. Próbálja újra.';

  @override
  String get notificationMeetingStartsSoon => 'Hamarosan kezdődő megbeszélés';

  @override
  String get notifyMeetingStartsSoon =>
      'Amikor egy naptárbeli megbeszélés hamarosan kezdődik';

  @override
  String get notificationCalendarAuthExpiredTitle => 'Naptár leválasztva';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'Csatlakoztassa újra a(z) $email fiókot a szinkronizálás folytatásához';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'Csatlakoztassa újra a naptárát a szinkronizálás folytatásához';

  @override
  String get notifyCalendarAuthExpired =>
      'Amikor egy naptárfiókot újra kell csatlakoztatni';

  @override
  String get notificationRigStatusChanged =>
      'Elszigetelt környezet frissítései';

  @override
  String get notifyRigStatusChanged =>
      'Amikor egy elszigetelt környezetet átvesznek, visszavesznek vagy meghibásodik';

  @override
  String get notificationRigTakenOver => 'Elszigetelt környezet átvéve';

  @override
  String get notificationRigTakenOverBody =>
      'Egy ember irányítja a gépet; az ügynök nézheti, de nem cselekedhet.';

  @override
  String get notificationRigReleased =>
      'Elszigetelt környezet irányítása feladva';

  @override
  String get notificationRigReleasedBody => 'Az ügynök visszakapta a gépet.';

  @override
  String get notificationRigReclaimed => 'Elszigetelt környezet visszavéve';

  @override
  String get notificationRigReclaimedBodyIdle =>
      'Tétlen volt, ezért a gépet leállították a memória felszabadításához.';

  @override
  String get notificationRigReclaimedBodyTtl =>
      'Elérte az időkorlátját, és leállították.';

  @override
  String get notificationRigFailed => 'Elszigetelt környezet meghibásodott';

  @override
  String get notificationRigFailedBody =>
      'A hipervizor alatta leállt. Nyissa újra a gépet a folytatáshoz.';

  @override
  String get calendarAlertLeadTime => 'Riasztás előideje';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'Mennyivel a megbeszélés előtt riasztjon';

  @override
  String calendarConnectedAs(String email) {
    return 'Csatlakoztatva mint $email';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count résztvevő';
  }

  @override
  String get calendarEventLabel => 'Esemény';

  @override
  String get calendarRecurring => 'Ismétlődő esemény';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'Szervező';

  @override
  String get calendarYou => 'Ön';

  @override
  String get calendarShowFewer => 'Kevesebb megjelenítése';

  @override
  String get calendarRsvpAwaiting => 'Várakozik';

  @override
  String calendarParticipantsCount(int count) {
    return '$count résztvevő';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'Mind a $count résztvevő';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count igen';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count nem';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count talán';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count várakozik';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count perc';
  }

  @override
  String get openInEditorPrompt => 'Melyik szerkesztőben nyissa meg?';

  @override
  String get ideNotInstalled => 'Nincs telepítve';

  @override
  String openInIde(String editor) {
    return 'Megnyitás itt: $editor';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return 'Nem sikerült megnyitni a(z) $editor szerkesztőt: $error';
  }

  @override
  String get profileSearchHint => 'Pull requestek keresése…';

  @override
  String get stopAgentRun => 'Futtatás leállítása';

  @override
  String get stopAgentRunConfirm =>
      'Leállítja ezt a futtatást? A folyamatban lévő munka elveszik.';

  @override
  String get inProgress => 'Folyamatban';

  @override
  String get drafts => 'Piszkozatok';

  @override
  String get sortOldest => 'Legrégebbi';

  @override
  String get sortLargest => 'Legnagyobb';

  @override
  String get prFilterTooltip => 'Szűrő';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# aktív szűrő',
      one: '# aktív szűrő',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => 'Szűrő hozzáadása…';

  @override
  String get prFilterFieldHint => 'Szűrés…';

  @override
  String get prFilterCategoryStatus => 'Állapot';

  @override
  String get prFilterCategoryAuthor => 'Szerző';

  @override
  String get prFilterCategoryReviewer => 'Átnézők';

  @override
  String get prFilterCategoryContent => 'Tartalom';

  @override
  String get prFilterCategoryRepoOwner => 'Tároló tulajdonosa';

  @override
  String get prFilterCategoryRepoName => 'Tároló neve';

  @override
  String get prFilterCategoryOpenedDate => 'Megnyitás dátuma';

  @override
  String get prFilterCategoryUpdatedDate => 'Frissítés dátuma';

  @override
  String get prFilterQuickToReview => 'Gyorsan átnézhető';

  @override
  String get prFilterClearAll => 'Szűrők törlése';

  @override
  String prFilterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# pull request',
      one: '# pull request',
    );
    return '$_temp0';
  }

  @override
  String prFilterHiddenOptions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# beállítás nem illeszkedik egy pull requestra sem',
      one: '# beállítás nem illeszkedik egy pull requestra sem',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => 'A cím vagy a törzs tartalmazza…';

  @override
  String get prFilterNoOptions => 'Nincs illeszkedő beállítás';

  @override
  String get prFilterChipIs => 'egyenlő';

  @override
  String get prFilterChipIsAnyOf => 'bármelyike';

  @override
  String get prFilterChipContains => 'tartalmazza';

  @override
  String get prFilterChipSince => 'óta';

  @override
  String get prFilterAddFilterButton => 'Szűrő hozzáadása';

  @override
  String prFilterClearCategory(String category) {
    return '$category szűrő törlése';
  }

  @override
  String get prFilterCurrentUser => 'Jelenlegi felhasználó';

  @override
  String get prStatusDraft => 'Piszkozat';

  @override
  String get prStatusOpen => 'Nyitott';

  @override
  String get prStatusInReview => 'Átnézés alatt';

  @override
  String get prStatusChangesRequested => 'Módosítást kértek';

  @override
  String get prStatusApproved => 'Jóváhagyva';

  @override
  String get prStatusMerged => 'Összefésülve';

  @override
  String get prStatusClosed => 'Lezárva';

  @override
  String get prDateWindowDay => '1 napja';

  @override
  String get prDateWindowThreeDays => '3 napja';

  @override
  String get prDateWindowWeek => '1 hete';

  @override
  String get prDateWindowMonth => '1 hónapja';

  @override
  String get prDateWindowThreeMonths => '3 hónapja';

  @override
  String get prDateWindowSixMonths => '6 hónapja';

  @override
  String get prDateWindowYear => '1 éve';

  @override
  String get prDisplayOptions => 'Megjelenítési beállítások';

  @override
  String get prDisplayGrouping => 'Csoportosítás';

  @override
  String get prDisplayOrdering => 'Rendezés';

  @override
  String get prDisplayShowDrafts => 'Piszkozatok megjelenítése';

  @override
  String get prDisplayMergedWindow => 'Összefésülési ablak';

  @override
  String get prDisplayMergedWindowDay => 'Elmúlt nap';

  @override
  String get prDisplayMergedWindowWeek => 'Elmúlt hét';

  @override
  String get prDisplayMergedWindowMonth => 'Elmúlt hónap';

  @override
  String get prDisplayProperties => 'Megjelenített tulajdonságok';

  @override
  String get prGroupingRepository => 'Tároló';

  @override
  String get prGroupingAuthor => 'Szerző';

  @override
  String get prGroupingStatus => 'Állapot';

  @override
  String get prGroupingNone => 'Nincs csoportosítás';

  @override
  String get prPropertyRepository => 'Tároló';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => 'Ág';

  @override
  String get prPropertyUpdated => 'Frissítve';

  @override
  String get prPropertyAuthor => 'Szerző';

  @override
  String get prPropertyChecks => 'Ellenőrzések';

  @override
  String get prPropertyDiff => 'Diff';

  @override
  String get prPropertyComments => 'Megjegyzések';

  @override
  String get keybindingOpenFilterMenu => 'Szűrőmenü megnyitása';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'A pull request szűrőmenü megnyitása';

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# kijelölve',
      one: '# kijelölve',
    );
    return '$_temp0';
  }

  @override
  String get summary => 'Összefoglaló';

  @override
  String get kbMove => 'mozgatás';

  @override
  String get kbTabs => 'lapok';

  @override
  String get kbSearch => 'keresés';

  @override
  String get kbViewed => 'megtekintve';

  @override
  String get kbCollapse => 'összecsukás';

  @override
  String get appearance => 'Megjelenés';

  @override
  String get appearanceSettingsDescription => 'Téma, nyelv és tipográfia.';

  @override
  String get notificationsSettingsDescription =>
      'Válassza ki, mely ügynök- és munkaterület-eseményekről kapjon értesítést.';

  @override
  String get advanced => 'Haladó';

  @override
  String get accounts => 'Fiókok';

  @override
  String get mcpServers => 'MCP-szerverek';

  @override
  String get mcpServersSettingsDescription =>
      'Beépített MCP-szerver és külső MCP-szerverek.';

  @override
  String get remoteControlAndDevices => 'Távirányítás és eszközök';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'Telefonok párosítása és a távirányító szerver beállítása.';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'A beszéd- és diarizációs modellek, amelyeket ez a szerver hosztol.';

  @override
  String get needsSetupLabel => 'Beállítás szükséges';

  @override
  String get collapseSidebar => 'Oldalsáv összecsukása';

  @override
  String get expandSidebar => 'Oldalsáv kinyitása';

  @override
  String get filterSpacesHint => 'Terek szűrése';

  @override
  String noSpacesMatch(String query) {
    return 'Nincs a(z) „$query” kifejezésre illeszkedő tér';
  }

  @override
  String get privacy => 'Adatvédelem';

  @override
  String get sendDiffContentTitle => 'Diff tartalom küldése az AI-adapternek';

  @override
  String get diffSharingOnSubtitle =>
      'A nyers diff-sorok bekerülnek az ügynök promptjaiba a mélyebb átnézéshez.';

  @override
  String get diffSharingOffSubtitle =>
      'Az ügynökök csak strukturált metaadatokat használnak (fájlútvonalak, sorszámok, PR leírás); nyers kód nem hagyja el az alkalmazást.';

  @override
  String get errorReportingTitle => 'Összeomlásjelentések megosztása';

  @override
  String get errorReportingOnSubtitle =>
      'Összeomlás-, hiba- és teljesítménydiagnosztika kerül elküldésre a hibák javításához (csak kiadási buildek).';

  @override
  String get errorReportingOffSubtitle =>
      'A diagnosztika ki van kapcsolva. Nem kerülnek elküldésre összeomlás- vagy hibajelentések.';

  @override
  String get onboardingDiagnosticsTitle =>
      'Segítsen a Control Center fejlesztésében';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'Küldjön összeomlás-, hiba- és teljesítménydiagnosztikát, hogy gyorsabban javíthassuk a problémákat (csak kiadási buildek). Ezt bármikor módosíthatja: Beállítások → Adatvédelem.';

  @override
  String get blocked => 'Blokkolva';

  @override
  String get idle => 'Tétlen';

  @override
  String get noRunsYet => 'Még nincs futtatás';

  @override
  String get copyPath => 'Útvonal másolása';

  @override
  String get copyRelativePath => 'Relatív útvonal másolása';

  @override
  String get nameRequired => 'A név kötelező';

  @override
  String get import => 'Importálás';

  @override
  String get noMatchingAgents => 'Nincs a szűrőre illeszkedő ügynök';

  @override
  String watchVideoOn(String provider) {
    return 'Videó megtekintése itt: $provider';
  }

  @override
  String get branchTemplate => 'Ágnév sablon';

  @override
  String get branchTemplateDescription =>
      'Minta az ághoz, amely egy jegy elszigetelt worktree-ben való indításakor jön létre.';

  @override
  String branchTemplatePreview(String example) {
    return 'Példa: $example';
  }

  @override
  String get deletePipelineRun => 'Pipeline-futtatás törlése';

  @override
  String deletePipelineRunConfirm(String template) {
    return 'Törli a(z) „$template” ezen futtatását? Ezt nem lehet visszavonni.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'Hiba a pipeline-futtatás törlésekor: $error';
  }

  @override
  String get deleteTicket => 'Jegy törlése';

  @override
  String deleteTicketConfirm(String title) {
    return 'Törli a(z) „$title” jegyet? Ezt nem lehet visszavonni.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'Hiba a jegy törlésekor: $error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return 'Törli a(z) „$name” munkaterületet? A lemezen lévő összekapcsolt tárolókhoz nem nyúl.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'Hiba a munkaterület törlésekor: $error';
  }

  @override
  String get indexCode => 'Kód indexelése';

  @override
  String get indexNoGrammars => 'A kódnyelvtanok nincsenek telepítve';

  @override
  String get indexFailed => 'Az indexelés sikertelen';

  @override
  String indexedSymbolsCount(int count) {
    return '$count szimbólum indexelve';
  }

  @override
  String get nodeConfigAdvanced => 'Haladó';

  @override
  String get nodeConfigReducer => 'Reducer';

  @override
  String get nodeConfigReducerHelp =>
      'Hogyan fésülje össze, ha ez a kimeneti kulcs már rendelkezik értékkel';

  @override
  String get nodeConfigTimeoutMs => 'Időtúllépés (ms)';

  @override
  String get nodeConfigRetryAttempts => 'Újrapróbálkozások';

  @override
  String get nodeConfigContinueOnFail => 'Folytatás, ha ez a lépés sikertelen';

  @override
  String get nodeConfigTeamId => 'Csapat-ID';

  @override
  String get nodeConfigDispatchMode => 'Kiosztási mód';

  @override
  String get nodeConfigOutputSchema => 'Kimeneti séma (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'JSON Schema, amelyet a lépés kimenetének ki kell elégítenie';

  @override
  String get diffLineDisplay => 'Hosszú sorok a diffeekben';

  @override
  String get diffLineDisplayDescription =>
      'Hosszú sorok tördelése vagy vízszintes görgetése';

  @override
  String get diffLineWrap => 'Tördelés';

  @override
  String get diffLineScroll => 'Vízszintes görgetés';

  @override
  String get actions => 'Műveletek';

  @override
  String get activate => 'Aktiválás';

  @override
  String get activity => 'Tevékenység';

  @override
  String get activityLabel => 'TEVÉKENYSÉG';

  @override
  String get activitySearchHint => 'Tevékenység keresése';

  @override
  String get activityNoMatches => 'Nincs a szűrőkre illeszkedő tevékenység';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$start–$end / $total';
  }

  @override
  String get activityPreviousPage => 'Előző oldal';

  @override
  String get activityNextPage => 'Következő oldal';

  @override
  String get activityNetworkLocal => 'Localhost';

  @override
  String get activityClearFilter => 'Szűrő törlése';

  @override
  String activityFilterIp(String ip) {
    return 'IP $ip';
  }

  @override
  String activityFilterCountry(String country) {
    return 'Ország $country';
  }

  @override
  String get activitySavedWorkspaceLogo => 'Munkaterület-logó mentve';

  @override
  String activityVerbCreated(String target) {
    return '$target létrehozva';
  }

  @override
  String activityVerbUpdated(String target) {
    return '$target frissítve';
  }

  @override
  String activityVerbDeleted(String target) {
    return '$target törölve';
  }

  @override
  String activityVerbAdded(String target) {
    return '$target hozzáadva';
  }

  @override
  String activityVerbRemoved(String target) {
    return '$target eltávolítva';
  }

  @override
  String activityVerbInvited(String target) {
    return '$target meghívva';
  }

  @override
  String activityVerbChanged(String target) {
    return '$target módosítva';
  }

  @override
  String activityVerbStarted(String target) {
    return '$target elindítva';
  }

  @override
  String activityVerbStopped(String target) {
    return '$target leállítva';
  }

  @override
  String activityVerbWrote(String target) {
    return '$target írva';
  }

  @override
  String get activityTargetAgent => 'ügynök';

  @override
  String get activityTargetTicket => 'jegy';

  @override
  String get activityTargetWorkspace => 'munkaterület';

  @override
  String get activityTargetRepository => 'tároló';

  @override
  String get activityTargetMember => 'tag';

  @override
  String get activityTargetInvite => 'meghívó';

  @override
  String get activityTargetSpace => 'tér';

  @override
  String get activityTargetMessage => 'üzenet';

  @override
  String get activityTargetCache => 'gyorsítótár';

  @override
  String get activityTargetFile => 'fájl';

  @override
  String get activityTargetPipeline => 'pipeline';

  @override
  String get activityTargetTemplate => 'sablon';

  @override
  String get activityTargetProvider => 'szolgáltató';

  @override
  String get activityTargetModel => 'modell';

  @override
  String get activityTargetSkill => 'készség';

  @override
  String get activityTargetTodo => 'teendő';

  @override
  String get activityTargetMeeting => 'megbeszélés';

  @override
  String get activityTargetProject => 'projekt';

  @override
  String get activityTargetTeam => 'csapat';

  @override
  String get activityTargetDevice => 'eszköz';

  @override
  String get activityTargetPreference => 'beállítás';

  @override
  String get activityTargetBudget => 'költségkeret';

  @override
  String activityVerbApproved(String target) {
    return '$target jóváhagyva';
  }

  @override
  String activityVerbArchived(String target) {
    return '$target archiválva';
  }

  @override
  String activityVerbAssigned(String target) {
    return '$target hozzárendelve';
  }

  @override
  String activityVerbBackedUp(String target) {
    return '$target biztonsági mentése kész';
  }

  @override
  String activityVerbCancelled(String target) {
    return '$target megszakítva';
  }

  @override
  String activityVerbCleared(String target) {
    return '$target törölve';
  }

  @override
  String activityVerbClosed(String target) {
    return '$target lezárva';
  }

  @override
  String activityVerbCommitted(String target) {
    return '$target commitolva';
  }

  @override
  String activityVerbCompacted(String target) {
    return '$target tömörítve';
  }

  @override
  String activityVerbCompleted(String target) {
    return '$target befejezve';
  }

  @override
  String activityVerbConnected(String target) {
    return '$target csatlakoztatva';
  }

  @override
  String activityVerbContinued(String target) {
    return '$target folytatva';
  }

  @override
  String activityVerbDisconnected(String target) {
    return '$target leválasztva';
  }

  @override
  String activityVerbDispatched(String target) {
    return '$target kiosztva';
  }

  @override
  String activityVerbDrained(String target) {
    return '$target kiürítve';
  }

  @override
  String activityVerbEnrolled(String target) {
    return '$target felvéve';
  }

  @override
  String activityVerbEstimated(String target) {
    return '$target becsülve';
  }

  @override
  String activityVerbImported(String target) {
    return '$target importálva';
  }

  @override
  String activityVerbInstalled(String target) {
    return '$target telepítve';
  }

  @override
  String activityVerbKilled(String target) {
    return '$target kilőve';
  }

  @override
  String activityVerbMarked(String target) {
    return '$target megjelölve';
  }

  @override
  String activityVerbMerged(String target) {
    return '$target összefésülve';
  }

  @override
  String activityVerbOpened(String target) {
    return '$target megnyitva';
  }

  @override
  String activityVerbPaused(String target) {
    return '$target szüneteltetve';
  }

  @override
  String activityVerbPolled(String target) {
    return '$target lekérdezve';
  }

  @override
  String activityVerbPrepared(String target) {
    return '$target előkészítve';
  }

  @override
  String activityVerbProcessed(String target) {
    return '$target feldolgozva';
  }

  @override
  String activityVerbPublished(String target) {
    return '$target közzétéve';
  }

  @override
  String activityVerbRefined(String target) {
    return '$target finomítva';
  }

  @override
  String activityVerbRefreshed(String target) {
    return '$target frissítve';
  }

  @override
  String activityVerbRegistered(String target) {
    return '$target regisztrálva';
  }

  @override
  String activityVerbRenamed(String target) {
    return '$target átnevezve';
  }

  @override
  String activityVerbReordered(String target) {
    return '$target átrendezve';
  }

  @override
  String activityVerbResponded(String target) {
    return 'Válaszolva erre: $target';
  }

  @override
  String activityVerbRestored(String target) {
    return '$target visszaállítva';
  }

  @override
  String activityVerbResumed(String target) {
    return '$target folytatva';
  }

  @override
  String activityVerbRetried(String target) {
    return '$target újrapróbálva';
  }

  @override
  String activityVerbReverted(String target) {
    return '$target visszavonva';
  }

  @override
  String activityVerbReviewed(String target) {
    return '$target átnézve';
  }

  @override
  String activityVerbRan(String target) {
    return '$target futtatva';
  }

  @override
  String activityVerbSelected(String target) {
    return '$target kiválasztva';
  }

  @override
  String activityVerbSent(String target) {
    return '$target elküldve';
  }

  @override
  String activityVerbStaged(String target) {
    return '$target előkészítve';
  }

  @override
  String activityVerbSteered(String target) {
    return '$target irányítva';
  }

  @override
  String activityVerbSubmitted(String target) {
    return '$target elküldve';
  }

  @override
  String activityVerbSynced(String target) {
    return '$target szinkronizálva';
  }

  @override
  String activityVerbToggled(String target) {
    return '$target átkapcsolva';
  }

  @override
  String activityVerbUninstalled(String target) {
    return '$target eltávolítva';
  }

  @override
  String activityVerbUnstaged(String target) {
    return '$target kivezetve az előkészítésből';
  }

  @override
  String get activityTargetActionPolicy => 'műveleti szabályzat';

  @override
  String get activityTargetGoalRun => 'célfuttatás';

  @override
  String get activityTargetRunLog => 'futtatási napló';

  @override
  String get activityTargetWorkingMemory => 'munkamemória';

  @override
  String get activityTargetRoutingPolicy => 'útválasztási szabályzat';

  @override
  String get activityTargetAutonomy => 'autonómia';

  @override
  String get activityTargetCalendar => 'naptár';

  @override
  String get activityTargetChecker => 'ellenőrző';

  @override
  String get activityTargetEditor => 'szerkesztő';

  @override
  String get activityTargetConfirmation => 'megerősítés';

  @override
  String get activityTargetTunnel => 'alagút';

  @override
  String get activityTargetConversation => 'beszélgetés';

  @override
  String get activityTargetCredentials => 'hitelesítő adatok';

  @override
  String get activityTargetDictation => 'diktálás';

  @override
  String get activityTargetAgentRun => 'ügynökfuttatás';

  @override
  String get activityTargetEvalSuite => 'kiértékelési csomag';

  @override
  String get activityTargetWorker => 'worker';

  @override
  String get activityTargetWorktree => 'worktree';

  @override
  String get activityTargetMcpServer => 'MCP-szerver';

  @override
  String get activityTargetMemoryAccessGrant => 'memória-hozzáférési engedély';

  @override
  String get activityTargetMemoryDomain => 'memóriaterület';

  @override
  String get activityTargetMemoryFact => 'memóriatény';

  @override
  String get activityTargetMemoryPolicy => 'memóriaszabályzat';

  @override
  String get activityTargetFeed => 'hírfolyam';

  @override
  String get activityTargetNote => 'jegyzet';

  @override
  String get activityTargetOrchestration => 'orchestráció';

  @override
  String get activityTargetPipelineRun => 'pipeline-futtatás';

  @override
  String get activityTargetPipelineTrigger => 'pipeline-trigger';

  @override
  String get activityTargetPlan => 'terv';

  @override
  String get activityTargetPlaybook => 'playbook';

  @override
  String get activityTargetPullRequest => 'pull request';

  @override
  String get activityTargetReview => 'átnézés';

  @override
  String get activityTargetProcess => 'folyamat';

  @override
  String get activityTargetProviderPolicy => 'szolgáltatói szabályzat';

  @override
  String get activityTargetReaction => 'reakció';

  @override
  String get activityTargetReviewSpace => 'átnézési tér';

  @override
  String get activityTargetReviewStudio => 'átnézési stúdió';

  @override
  String get activityTargetServerData => 'szerveradatok';

  @override
  String get activityTargetSoundscape => 'hangtáj';

  @override
  String get activityTargetSession => 'munkamenet';

  @override
  String get activityTargetTerminal => 'terminál';

  @override
  String get activityTargetTicketLink => 'jegylink';

  @override
  String get activityTargetTicketSync => 'jegyszinkron';

  @override
  String get activityTargetProfile => 'profil';

  @override
  String get activityTargetVoiceProfile => 'hangprofil';

  @override
  String get activityTargetWeather => 'időjárás-előrejelzés';

  @override
  String get activityTargetWorkProduct => 'munkatermék';

  @override
  String get activityChangedMemberRole => 'Tag szerepének módosítása';

  @override
  String get activityChangedMemberRepoAccess =>
      'Tag tároló-hozzáférésének módosítása';

  @override
  String get activityUpdatedGitHubToken => 'GitHub-token frissítve';

  @override
  String get activityRefreshedWeather => 'Időjárás-előrejelzés frissítve';

  @override
  String get activitySetWeatherLocation => 'Időjárás helyének beállítása';

  @override
  String get activityClearedWeatherLocation => 'Időjárás helyének törlése';

  @override
  String get activityMarkedAllArticlesRead => 'Minden cikk olvasottnak jelölve';

  @override
  String get activityMarkedArticleRead => 'Cikk olvasottnak jelölve';

  @override
  String get activityUpdatedSavedArticle => 'Mentett cikk frissítve';

  @override
  String get activityTookOverSession => 'Munkamenet átvéve';

  @override
  String get activityHandedBackSession => 'Munkamenet visszaadva';

  @override
  String get activityCommittedAndPushed => 'Commitolva és küldve';

  @override
  String get activityBackedUpServer => 'Szerveradatok biztonsági mentése kész';

  @override
  String get activityMarkedSpaceRead => 'Tér olvasottnak jelölve';

  @override
  String get activityRespondedToInvitation => 'Válasz az eseménymeghívóra';

  @override
  String get activityStartedCalendarConnect => 'Naptárcsatlakozás elindítva';

  @override
  String get activityDisconnectedCalendar => 'Naptár leválasztva';

  @override
  String get activityMarkedFileViewed => 'Fájl megtekintettnek jelölve';

  @override
  String get activityRespondedToApproval => 'Válasz egy jóváhagyási kérésre';

  @override
  String get activityChangedTunnel => 'Alagútbeállítás módosítva';

  @override
  String get activitySentMessageToAgent => 'Üzenet küldve az ügynöknek';

  @override
  String get activityOpenedReviewSpace => 'Átnézési tér megnyitva';

  @override
  String get activityOpenedStandingConversation =>
      'Állandó beszélgetés megnyitva';

  @override
  String get activityStartedRecording => 'Felvétel elindítva';

  @override
  String get activityStoppedRecording => 'Felvétel leállítva';

  @override
  String get activityToggledMcpServer => 'MCP-szerver átkapcsolva';

  @override
  String get activityUpdatedMcpToken => 'MCP-token frissítve';

  @override
  String get activitySavedApiKey => 'API-kulcs mentve';

  @override
  String get activityRemovedProviderCredential =>
      'Szolgáltatói hitelesítő adatok eltávolítva';

  @override
  String get activityUpdatedLinkedRepos => 'Összekapcsolt tárolók frissítve';

  @override
  String get activityUnlinkedRepo => 'Tároló leválasztva';

  @override
  String get activityUpdatedActionItem => 'Teendő frissítve';

  @override
  String adRulesCount(int count) {
    return '$count hirdetési szabály';
  }

  @override
  String get adapter => 'Adapter';

  @override
  String get adapterLabel => 'Adapter';

  @override
  String get adapters => 'Adapterek';

  @override
  String get adaptersAutoDetected =>
      'Ezen a gépen automatikusan felismert ügynökfuttatók. Telepítse a hiányzó CLI-eszközöket további futtatók engedélyezéséhez.';

  @override
  String get add => 'Hozzáadás';

  @override
  String get addAComment => 'Megjegyzés hozzáadása';

  @override
  String get addAReaction => 'Reakció hozzáadása';

  @override
  String get addASuggestion => 'Javaslat hozzáadása';

  @override
  String get addAgents => 'Ügynökök hozzáadása';

  @override
  String get addEmoji => 'Emoji hozzáadása';

  @override
  String get addFeed => 'Hírfolyam hozzáadása';

  @override
  String get addressBarHint => 'URL megadása';

  @override
  String get addFromFile => 'Hozzáadás fájlból';

  @override
  String get addGif => 'GIF hozzáadása';

  @override
  String get addGithubRepoPrompt =>
      'Adjon hozzá legalább egy GitHub-tárolót a pull requestek megtekintéséhez';

  @override
  String get addLocalCheckoutDescription =>
      'Adjon hozzá egy helyi checkoutot, hogy ebből a munkaterületből célozhassa.';

  @override
  String get addRepository => 'Tároló hozzáadása';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tároló hozzáadása',
      one: 'Tároló hozzáadása',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro =>
      'Böngéssze a szervert futtató gép mappáit, és válassza ki a regisztrálandó git checkoutokat.';

  @override
  String get selectThisFolder => 'Mappa kijelölése';

  @override
  String get deselectThisFolder => 'Mappa kijelölésének törlése';

  @override
  String get goUp => 'Fel';

  @override
  String get noSubfoldersHere => 'Nincsenek almappák';

  @override
  String get notAGitRepository => 'Ez a mappa nem git tároló.';

  @override
  String get addToken => 'Token hozzáadása';

  @override
  String get addWorkspace => 'Munkaterület hozzáadása';

  @override
  String get addWorkspaceEllipsis => 'Munkaterület hozzáadása…';

  @override
  String get added => 'Hozzáadva';

  @override
  String get addingEllipsis => 'Hozzáadás…';

  @override
  String get advancedLabel => 'Haladó';

  @override
  String get agent => 'Ügynök';

  @override
  String agentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ügynök',
      one: '$count ügynök',
    );
    return '$_temp0';
  }

  @override
  String get agentMdPath => 'Agent MD útvonal';

  @override
  String get agentName => 'Ügynök neve';

  @override
  String get agentTitle => 'Ügynök címe';

  @override
  String get agentUpdated => 'Ügynök frissítve.';

  @override
  String get agents => 'Ügynökök';

  @override
  String get agentsMentionSection => 'Ügynökök';

  @override
  String get usersMentionSection => 'Emberek';

  @override
  String get ticketsMentionSection => 'Jegyek';

  @override
  String get pullRequestsMentionSection => 'Pull requestek';

  @override
  String get meetingsMentionSection => 'Megbeszélések';

  @override
  String get entityRefTicketFallback => 'Jegy';

  @override
  String get entityRefPrFallback => 'Pull request';

  @override
  String get entityRefMeetingFallback => 'Megbeszélés';

  @override
  String get aiReview => 'AI-átnézés';

  @override
  String get all => 'Mind';

  @override
  String get allAgentsAlreadyInSpace => 'Minden ügynök már ebben a térben van.';

  @override
  String get allCommits => 'Minden commit';

  @override
  String get allSources => 'Minden forrás';

  @override
  String get allow => 'Engedélyezés';

  @override
  String get allowGitPush => 'git push engedélyezése';

  @override
  String get allowGithubApi => 'GitHub API-hívások engedélyezése';

  @override
  String get allowNetwork => 'Általános hálózati hozzáférés engedélyezése';

  @override
  String get apiKeys => 'API-kulcsok';

  @override
  String get appFont => 'Alkalmazás betűtípusa';

  @override
  String get appLogLevelDebugDescription =>
      'Részletes nyomkövetést ad hozzá – fejlesztéshez.';

  @override
  String get appLogLevelDebugLabel => 'Hibakeresés';

  @override
  String get appLogLevelErrorDescription => 'Csak váratlan hibák és kivételek.';

  @override
  String get appLogLevelErrorLabel => 'Hiba';

  @override
  String get appLogLevelInfoDescription =>
      'Életciklus- és állapotüzeneteket ad hozzá.';

  @override
  String get appLogLevelInfoLabel => 'Infó';

  @override
  String get appLogLevelNoneDescription => 'Egyáltalán nincs konzolkimenet.';

  @override
  String get appLogLevelNoneLabel => 'Nincs';

  @override
  String get appLogLevelVerboseDescription =>
      'Minden. Rendkívül zajos – csak hibakereséshez.';

  @override
  String get appLogLevelVerboseLabel => 'Részletes';

  @override
  String get appLogLevelWarningDescription =>
      'Figyelmeztetéseket és helyreállítható problémákat ad hozzá.';

  @override
  String get appLogLevelWarningLabel => 'Figyelmeztetés';

  @override
  String get appearanceLanguage => 'Megjelenés és nyelv';

  @override
  String get apply => 'Alkalmazás';

  @override
  String get approve => 'Jóváhagyás';

  @override
  String get agentApprovalRequired => 'Jóváhagyás szükséges';

  @override
  String agentApprovalsMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# további várakozik',
      one: '# további várakozik',
    );
    return '$_temp0';
  }

  @override
  String get approved => 'Jóváhagyva';

  @override
  String get articleNoun => 'Cikk';

  @override
  String get articlesSubscribed => 'Cikkek a feliratkozott hírfolyamokból.';

  @override
  String get askAi => 'Kérdezze az AI-t';

  @override
  String get askAiReviewDescription =>
      'Kérje meg az AI-t, hogy nézze át ezt a PR-t';

  @override
  String get assignees => 'Hozzárendeltek';

  @override
  String get attachImage => 'Kép csatolása';

  @override
  String get attachedAgents => 'Csatolt ügynökök';

  @override
  String get audioInput => 'Hangbemenet';

  @override
  String get audioOutput => 'Hangkimenet';

  @override
  String get authenticationToken => 'Hitelesítési token';

  @override
  String authoredByLabel(String role) {
    return 'Szerző: $role';
  }

  @override
  String get autoRecommended => 'Automatikus (ajánlott)';

  @override
  String get available => 'Elérhető';

  @override
  String get awaitingYourReview => 'Az Ön átnézésére vár';

  @override
  String get back => 'Vissza';

  @override
  String get backLabel => 'Vissza';

  @override
  String get backend => 'Háttér';

  @override
  String get blockAdsTrackers =>
      'Hirdetések, követők és cookie-sávok blokkolása';

  @override
  String get blocking => 'Blokkolás';

  @override
  String get bookmarkLabel => 'Könyvjelző';

  @override
  String get briefDescription => 'Rövid leírás';

  @override
  String get bugLabel => 'HIBA';

  @override
  String get bundledDefaultsNeverUpdated =>
      'Csomagolt alapértelmezettek — soha nem frissítve';

  @override
  String get cancel => 'Mégse';

  @override
  String get cancelEdit => 'Szerkesztés megszakítása';

  @override
  String get categoryCreation => 'Létrehozás';

  @override
  String get categoryEditing => 'Szerkesztés';

  @override
  String get categoryNavigation => 'Navigáció';

  @override
  String get categorySystem => 'Rendszer';

  @override
  String get categoryView => 'Kategórianézet';

  @override
  String get change => 'Módosítás';

  @override
  String get changesRequested => 'Módosítást kértek';

  @override
  String get spacesMentionSection => 'Terek';

  @override
  String get checkForUpdates => 'Frissítések keresése';

  @override
  String get checking => 'Ellenőrzés';

  @override
  String get checkingEllipsis => 'Ellenőrzés…';

  @override
  String get chooseAppFont => 'Alkalmazás betűtípusának választása';

  @override
  String get chooseCodeFont => 'Kódbetűtípus választása';

  @override
  String get chooseRunner => 'Válassza ki az ügynökfuttatót.';

  @override
  String get clear => 'Törlés';

  @override
  String get clickToRetry => 'Kattintson az újrapróbáláshoz';

  @override
  String get close => 'Bezárás';

  @override
  String get closeEsc => 'Bezárás (Esc)';

  @override
  String get closeReader => 'Olvasó bezárása';

  @override
  String get closed => 'Lezárva';

  @override
  String get codeFont => 'Kódbetűtípus';

  @override
  String get codeFontLigatures => 'Kódbetű ligatúrák';

  @override
  String get codeFontLigaturesDescription =>
      'Programozási ligatúrák (=>, !=, ->) egyesített glifaként a kódban és a diffeekben';

  @override
  String get collapse => 'Összecsukás';

  @override
  String get commandPalette => 'Parancspaletta';

  @override
  String get commandPaletteOrgMembers => 'Szervezeti tagok';

  @override
  String get commandPaletteBrowseTeam => 'Csapat böngészése';

  @override
  String get commandPaletteBrowseTeamDesc =>
      'Az összes szervezeti tag megtekintése';

  @override
  String get compactDone =>
      'Beszélgetés tömörítve. A korábbi előzmény összefoglalóba került.';

  @override
  String get compactNothing =>
      'Még nincs mit tömöríteni. A beszélgetés még rövid.';

  @override
  String get compactBusy =>
      'Egy ügynök még dolgozik. Tömörítsen, amikor a kör befejeződik.';

  @override
  String get compactUnavailable =>
      'A tömörítés nem érhető el ezen a szerveren.';

  @override
  String get commandsMentionSection => 'Parancsok';

  @override
  String get comment => 'Megjegyzés';

  @override
  String get commentOnThisFile => 'Megjegyzés ehhez a fájlhoz';

  @override
  String get commented => 'Megjegyzést fűzött';

  @override
  String get commits => 'Commitok';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'A legújabb $loaded commit a(z) $total közül';
  }

  @override
  String get prCloneProgressCloningTitle => 'Tároló klónozása';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'Ez a PR $fileCount fájlt módosít, ami meghaladja a GitHub API-korlátját. A tároló helyi klónozása…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'Ez a PR meghaladja a GitHub API fájlkorlátját. A tároló helyi klónozása…';

  @override
  String get prCloneProgressFetchingTitle => 'PR-refek lekérése';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'Az alapág és a PR head ref lekérése…';

  @override
  String get prCloneProgressComputingTitle => 'Diff számítása';

  @override
  String get prCloneProgressComputingSubtitle => 'git diff futtatása helyben…';

  @override
  String get prCloneProgressErrorTitle => 'Nem sikerült betölteni a diffet';

  @override
  String get prCloneProgressErrorSubtitle =>
      'Hiba történt a klónozás vagy a diff számítása közben. Próbálja meg frissíteni.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'Még dolgozik… eltelt: $elapsed';
  }

  @override
  String confidenceLabel(int percent) {
    return 'Bizonyosság: $percent%';
  }

  @override
  String get configureAgentIdentities =>
      'Ügynökidentitások, promptok, készségek beállítása és futtatások megtekintése.';

  @override
  String get configureDefaultRunners =>
      'Állítsa be, melyik adaptert és modellt használják az új terek és a címgenerálás.';

  @override
  String get configuredLabel => 'Beállítva.';

  @override
  String get confirmedBy => 'Megerősítette';

  @override
  String get consensus => 'Konszenzus';

  @override
  String get contentHint => 'Mit kell megjegyezni';

  @override
  String get contentLabel => 'Tartalom';

  @override
  String get contentMarkdown => 'Tartalom (Markdown)';

  @override
  String get contextWindowSize => 'Kontextusablak mérete';

  @override
  String modelContextChip(String size) {
    return 'Modell · $size';
  }

  @override
  String get continueLabel => 'Folytatás';

  @override
  String get conversationMode => 'Mód';

  @override
  String cookieRulesCount(int count) {
    return '$count cookie-szabály';
  }

  @override
  String get copied => 'Másolva!';

  @override
  String get copy => 'Másolás';

  @override
  String get copyAddress => 'Cím másolása';

  @override
  String get copyBaseBranchTooltip => 'Alapág nevének másolása';

  @override
  String get copyHeadBranchTooltip => 'Head ág nevének másolása';

  @override
  String couldNotListDevices(String error) {
    return 'Nem sikerült listázni az eszközöket: $error';
  }

  @override
  String get create => 'Létrehozás';

  @override
  String get createOrSelectWorkspace =>
      'Hozzon létre vagy válasszon munkaterületet a tárolók hozzáadása előtt.';

  @override
  String get createPullRequest => 'Pull request létrehozása';

  @override
  String get createdByMe => 'Általam létrehozva';

  @override
  String createdLabel(String date) {
    return 'Létrehozva: $date';
  }

  @override
  String get currentParticipants => 'Jelenlegi résztvevők';

  @override
  String get customCapabilitiesDescription => 'Egyéni képességek leírása';

  @override
  String get customSystemPrompt =>
      'Egyéni rendszerprompt ehhez az ügynökhöz...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# napja',
      one: '# napja',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'Deaktiválás';

  @override
  String get defaultCapabilities => 'Alapértelmezett képességek · új terek';

  @override
  String get defaultChat => 'Alapértelmezett csevegés';

  @override
  String get defaultRunners => 'Alapértelmezett futtatók';

  @override
  String get delete => 'Törlés';

  @override
  String get deleteAgent => 'Ügynök törlése';

  @override
  String deleteAgentConfirm(String name) {
    return 'Törli a(z) „$name” ügynököt? Ezt nem lehet visszavonni.';
  }

  @override
  String get deleteSpace => 'Tér törlése';

  @override
  String deleteConfirmName(String name) {
    return 'Törli: „$name”?';
  }

  @override
  String get archiveConversation => 'Beszélgetés archiválása';

  @override
  String get deleteFact => 'Tény törlése';

  @override
  String get deleteFeedBody =>
      'Ez eltávolítja a hírfolyamot és az összes gyorsítótárazott cikkét. A hírfolyamból könyvjelzőzött cikkek is törlődnek.';

  @override
  String deleteFeedConfirm(String name) {
    return 'Törli a(z) „$name” hírfolyamot?';
  }

  @override
  String get deletePolicy => 'Szabályzat törlése';

  @override
  String get deletePolicyConfirm =>
      'Törli ezt a szabályzatot? Ezt nem lehet visszavonni.';

  @override
  String deleteTopicConfirm(String topic) {
    return 'Törli a(z) „$topic” témát? Ezt nem lehet visszavonni.';
  }

  @override
  String get deleteWorkspace => 'Munkaterület törlése';

  @override
  String get deny => 'Tiltás';

  @override
  String get detailsLabel => 'Részletek';

  @override
  String get descriptionLabel => 'Leírás';

  @override
  String detectedBackend(String label) {
    return 'Felismerve: $label';
  }

  @override
  String get detectedRunners => 'Felismert futtatók';

  @override
  String get detectingAdapters => 'Adapterek felismerése…';

  @override
  String get detectingInputDevices => 'Bemeneti eszközök felismerése…';

  @override
  String detectionFailed(String error) {
    return 'A felismerés sikertelen: $error';
  }

  @override
  String get disabled => 'Letiltva';

  @override
  String get discover => 'Felfedezés';

  @override
  String get dismissed => 'Elutasítva';

  @override
  String get domainHint => 'pl. api-performance';

  @override
  String get domainLabel => 'Tartomány';

  @override
  String get download => 'Letöltés';

  @override
  String get downloadingLabel => 'Letöltés';

  @override
  String downloadingModel(int pct) {
    return 'Modell letöltése… $pct%';
  }

  @override
  String get draft => 'Piszkozat';

  @override
  String get draftLabel => 'Piszkozat';

  @override
  String get edit => 'Szerkesztés';

  @override
  String get edited => 'szerkesztve';

  @override
  String get editMessage => 'Üzenet szerkesztése';

  @override
  String get deleteMessage => 'Üzenet törlése';

  @override
  String get deleteMessageConfirm =>
      'Törli ezt az üzenetet? Ezt nem lehet visszavonni.';

  @override
  String get messageDeleted => 'Üzenet törölve';

  @override
  String get searchInConversation => 'Keresés a beszélgetésben';

  @override
  String get searchMessagesHint => 'Üzenetek keresése…';

  @override
  String get noMessagesFound => 'Nem található üzenet';

  @override
  String get editFact => 'Tény szerkesztése';

  @override
  String get editPolicy => 'Szabályzat szerkesztése';

  @override
  String get editSuggestedCodeHint => 'Javasolt kód szerkesztése…';

  @override
  String get editSuggestion => 'Javaslat szerkesztése';

  @override
  String get egArchitect => 'pl. architect';

  @override
  String get egControlCenter => 'pl. control-center';

  @override
  String get egPlatform => 'pl. Platform';

  @override
  String get egSamuelAlev => 'pl. SamuelAlev';

  @override
  String get egSoftwareArchitect => 'pl. Software Architect';

  @override
  String get egTheVerge => 'pl. The Verge';

  @override
  String get egTokenLimit => 'pl. 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'A telepítés sikertelen: $error';
  }

  @override
  String get embeddingInstalled =>
      'Helyi beágyazási modell telepítve. A hibrid keresés engedélyezve.';

  @override
  String get embeddingModel => 'Beágyazási modell (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'Nincs telepítve. A keresés kulcsszavas marad, amíg nincs engedélyezve.';

  @override
  String get embeddingRedownloadBody =>
      'A meglévő modellfájlok törlődnek, és újra letöltődnek. A szemantikus keresés a letöltés befejezéséig nem lesz elérhető.';

  @override
  String get embeddingRemoveBody =>
      'A szemantikus keresés le lesz tiltva, amíg újra nem telepíti. Bármikor újratelepítheti.';

  @override
  String get speakerDiarization => 'Beszélő-diarizáció';

  @override
  String get diarizationModel => 'Diarizációs modell';

  @override
  String get diarizationInstalled =>
      'Telepítve — egyéni beszélőket nevez meg a megbeszélés-átiratokban';

  @override
  String get diarizationNotInstalled =>
      'Nincs telepítve — a megbeszélés beszélői nem lesznek elválasztva';

  @override
  String diarizationInstallFailed(String error) {
    return 'A telepítés sikertelen: $error';
  }

  @override
  String get redownloadDiarizationModel => 'Diarizációs modell újraletöltése';

  @override
  String get diarizationRedownloadBody =>
      'Ez eltávolítja a jelenlegi diarizációs modelleket, és újra letölti őket.';

  @override
  String get removeDiarizationModel => 'Diarizációs modell eltávolítása';

  @override
  String get diarizationRemoveBody =>
      'Ez törli a készüléken lévő diarizációs modelleket. A már elkészült megbeszélés-átiratokat nem érinti.';

  @override
  String get enableNotifications => 'Értesítések engedélyezése';

  @override
  String get enableSandboxing => 'Homokozó engedélyezése';

  @override
  String get enabled => 'Engedélyezve';

  @override
  String errorCreatingAgent(String error) {
    return 'Hiba az ügynök létrehozásakor: $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'Hiba az ügynök törlésekor: $error';
  }

  @override
  String errorWithDetail(String error) {
    return 'Hiba: $error';
  }

  @override
  String get expand => 'Kinyitás';

  @override
  String extractingModel(int pct) {
    return 'Modell kicsomagolása… $pct%';
  }

  @override
  String get fact => 'Tény';

  @override
  String factCount(int count) {
    return '$count tény';
  }

  @override
  String factCountPlural(int count) {
    return '$count tény';
  }

  @override
  String get facts => 'Tények';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount tény · $policyCount szabályzat';
  }

  @override
  String get failed => 'Sikertelen';

  @override
  String failedToDispatch(String error) {
    return 'Nem sikerült kiosztani: $error';
  }

  @override
  String get failedToLoad => 'Nem sikerült betölteni';

  @override
  String failedToLoadAgents(String error) {
    return 'Nem sikerült betölteni az ügynököket: $error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'Nem sikerült betölteni a hírfolyamokat: $error';
  }

  @override
  String get failedToLoadGifs => 'Nem sikerült betölteni a GIF-eket';

  @override
  String failedToLoadLogs(String error) {
    return 'Nem sikerült betölteni a naplókat: $error';
  }

  @override
  String get failedToLoadRepos => 'Nem sikerült betölteni a tárolókat';

  @override
  String get failedToLoadWorkspaces =>
      'Nem sikerült betölteni a munkaterületeket';

  @override
  String failedToStartAiReview(String error) {
    return 'Nem sikerült elindítani az AI-átnézést: $error';
  }

  @override
  String get failedToStartMicTest =>
      'Nem sikerült elindítani a mikrofontesztet.';

  @override
  String failedToSubmitReview(String error) {
    return 'Nem sikerült elküldeni az átnézést: $error';
  }

  @override
  String failedToUpload(String name, String error) {
    return 'Nem sikerült feltölteni a(z) $name fájlt: $error';
  }

  @override
  String failedWithError(String error) {
    return 'Sikertelen: $error';
  }

  @override
  String get failure => 'Hiba';

  @override
  String get feedAlreadyExists => 'Már létezik hírfolyam ezzel az URL-lel.';

  @override
  String get feedUrlExample => 'pl. https://example.com/feed.xml';

  @override
  String get feedUrlLabel => 'Hírfolyam URL';

  @override
  String feedsCount(int count) {
    return 'Hírfolyamok ($count)';
  }

  @override
  String get filesChanged => 'Módosított fájlok';

  @override
  String filesCount(int count) {
    return '$count fájl';
  }

  @override
  String get filesMentionSection => 'Fájlok';

  @override
  String get filterAgents => 'Ügynökök szűrése...';

  @override
  String get filterFilesHint => 'Fájlok szűrése…';

  @override
  String get filterLists => 'Szűrőlisták';

  @override
  String get filterSkillsPlaceholder => 'Készségek szűrése…';

  @override
  String get finish => 'Befejezés';

  @override
  String get fix => 'Javítás';

  @override
  String get forward => 'Előre';

  @override
  String get gatesGithubPatPush =>
      'A GitHub PAT injektálását kapuzza. Szükséges, hogy az ügynök küldhessen.';

  @override
  String get general => 'Általános';

  @override
  String get githubLink => 'GitHub-hivatkozás';

  @override
  String get claudeStatusFetchFailed =>
      'Nem sikerült elérni a status.claude.com oldalt';

  @override
  String get claudeStatusOpenInBrowser => 'status.claude.com megnyitása';

  @override
  String get githubStatusFetchFailed =>
      'Nem sikerült elérni a githubstatus.com oldalt';

  @override
  String get githubDegradedTitle => 'A GitHub problémákat jelez';

  @override
  String githubDegradedStatusLine(String status) {
    return 'GitHub állapot: $status.';
  }

  @override
  String githubDegradedBody(String status) {
    return 'GitHub állapot: $status. A pull request adatok elavultak vagy hiányosak lehetnek a helyreállásig.';
  }

  @override
  String get githubStatusOpenInBrowser => 'githubstatus.com megnyitása';

  @override
  String get githubStatusRefresh => 'Frissítés';

  @override
  String githubStatusUpdated(String time) {
    return 'Frissítve $time';
  }

  @override
  String get kimiStatusFetchFailed =>
      'Nem sikerült elérni a status.moonshot.cn oldalt';

  @override
  String get kimiStatusOpenInBrowser => 'status.moonshot.cn megnyitása';

  @override
  String get openaiStatusFetchFailed =>
      'Nem sikerült elérni a status.openai.com oldalt';

  @override
  String get openaiStatusOpenInBrowser => 'status.openai.com megnyitása';

  @override
  String get serviceStatusMaintenance => 'Karbantartás';

  @override
  String get serviceStatusMajorIssues => 'Súlyos problémák';

  @override
  String get serviceStatusMinorIssues => 'Enyhe problémák';

  @override
  String get serviceStatusOperational => 'Üzemel';

  @override
  String get serviceStatusOutage => 'Kiesés';

  @override
  String get serviceStatusTitle => 'Szolgáltatás állapota';

  @override
  String get serviceStatusUnknown => 'Ismeretlen';

  @override
  String lastChecked(String time) {
    return 'Ellenőrizve $time';
  }

  @override
  String get lastCheckedRecently => 'Nemrég ellenőrizve';

  @override
  String get giveYourWorkAHome => 'Adjon otthont a munkájának.';

  @override
  String get goBack => 'Vissza';

  @override
  String get goForward => 'Előre';

  @override
  String get googleFonts => 'Google-betűtípusok';

  @override
  String get high => 'Magas';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# órája',
      one: '# órája',
    );
    return '$_temp0';
  }

  @override
  String get images => 'Képek';

  @override
  String get inactive => 'Inaktív';

  @override
  String get install => 'Telepítés';

  @override
  String get installRequired => 'Telepítés szükséges';

  @override
  String installedVersion(String version) {
    return 'Telepítve: $version';
  }

  @override
  String get invite => 'Meghívás';

  @override
  String get inviteAgent => 'Ügynök meghívása';

  @override
  String get isolateAgentExecution => 'Ügynökfuttatás elszigetelése.';

  @override
  String get justNow => 'Épp most';

  @override
  String get keepSandboxing => 'Homokozó megtartása';

  @override
  String get keybindingAddARepositoryDescription => 'Tároló hozzáadása';

  @override
  String get keybindingAddRepository => 'Tároló hozzáadása';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'A kijelölt cikk könyvjelzőzése vagy eltávolítása';

  @override
  String get keybindingCommandPalette => 'Parancspaletta';

  @override
  String get keybindingCreateANewAgentDescription => 'Új ügynök létrehozása';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'Új munkaterület létrehozása';

  @override
  String get keybindingFocusSearch => 'Keresés fókusza';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'A pull request keresőmező fókusza';

  @override
  String get keybindingNewAgent => 'Új ügynök';

  @override
  String get keybindingNewWorkspace => 'Új munkaterület';

  @override
  String get keybindingNextArticle => 'Következő cikk';

  @override
  String get keybindingNextSpace => 'Következő tér';

  @override
  String get keybindingNextWorkspace => 'Következő munkaterület';

  @override
  String get keybindingOpenArticle => 'Cikk megnyitása';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'A munkaterület-váltó felugró ablak megnyitása vagy bezárása az oldalsávban';

  @override
  String get keybindingOpenPr => 'PR megnyitása';

  @override
  String get keybindingOpenSettings => 'Beállítások megnyitása';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'Az alkalmazás beállításainak megnyitása';

  @override
  String get keybindingOpenTheCommandPaletteDescription =>
      'A parancspaletta megnyitása';

  @override
  String get keybindingOpenTheSelectedArticleDescription =>
      'A kijelölt cikk megnyitása';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'A kijelölt pull request megnyitása';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'A kijelölt munkaterület megnyitása';

  @override
  String get keybindingOpenWorkspace => 'Munkaterület megnyitása';

  @override
  String get keybindingPreviousArticle => 'Előző cikk';

  @override
  String get keybindingPreviousSpace => 'Előző tér';

  @override
  String get keybindingPreviousWorkspace => 'Előző munkaterület';

  @override
  String get keybindingRefresh => 'Frissítés';

  @override
  String get keybindingRefreshAllFeedsDescription =>
      'Minden hírfolyam frissítése';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'A pull request lista frissítése';

  @override
  String get keybindingRescanForAdaptersDescription =>
      'Adapterek újraellenőrzése';

  @override
  String get keybindingSelectTheNextArticleDescription =>
      'A következő cikk kijelölése';

  @override
  String get keybindingSelectTheNextSpaceDescription =>
      'A következő tér kijelölése';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'Az előző cikk kijelölése';

  @override
  String get keybindingSelectThePreviousSpaceDescription =>
      'Az előző tér kijelölése';

  @override
  String get keybindingSendMessage => 'Üzenet küldése';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'Az aktuális üzenet küldése';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Váltás világos és sötét mód között';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Váltás a nyolcadik munkaterületre';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Váltás az ötödik munkaterületre';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'Váltás az első munkaterületre';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'Váltás a negyedik munkaterületre';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'Váltás a következő munkaterületre';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'Váltás a kilencedik munkaterületre';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'Váltás az előző munkaterületre';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'Váltás a második munkaterületre';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'Váltás a hetedik munkaterületre';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'Váltás a hatodik munkaterületre';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'Váltás a harmadik munkaterületre';

  @override
  String get keybindingToggleBookmark => 'Könyvjelző váltása';

  @override
  String get keybindingToggleTheme => 'Téma váltása';

  @override
  String get keybindingToggleWorkspaceSwitcher => 'Munkaterület-váltó váltása';

  @override
  String get keybindingWorkspace1 => '1. munkaterület';

  @override
  String get keybindingWorkspace2 => '2. munkaterület';

  @override
  String get keybindingWorkspace3 => '3. munkaterület';

  @override
  String get keybindingWorkspace4 => '4. munkaterület';

  @override
  String get keybindingWorkspace5 => '5. munkaterület';

  @override
  String get keybindingWorkspace6 => '6. munkaterület';

  @override
  String get keybindingWorkspace7 => '7. munkaterület';

  @override
  String get keybindingWorkspace8 => '8. munkaterület';

  @override
  String get keybindingWorkspace9 => '9. munkaterület';

  @override
  String get keybindings => 'Gyorsbillentyűk';

  @override
  String get keybindingsDescription =>
      'Minden billentyűparancs. A parancsok rögzítettek, és nem rendelhetők át.';

  @override
  String get killRunning => 'Futó leállítása';

  @override
  String get languageSystem => 'Rendszer';

  @override
  String get leaveACommentEllipsis => 'Hagyjon megjegyzést…';

  @override
  String get legendLabel => 'Jelmagyarázat';

  @override
  String get lessLabel => 'Kevesebb';

  @override
  String get letsPluginTools => 'Csatlakoztassuk az eszközeit.';

  @override
  String get level => 'Szint';

  @override
  String get loadingAgents => 'Ügynökök betöltése…';

  @override
  String get loadingModels => 'Modellek betöltése…';

  @override
  String get loadingProviders => 'Szolgáltatók betöltése…';

  @override
  String get logLevel => 'Naplózási szint';

  @override
  String get logs => 'Naplók';

  @override
  String get low => 'Alacsony';

  @override
  String get maintenance => 'Karbantartás';

  @override
  String get manageParticipants => 'Résztvevők kezelése';

  @override
  String get manageWorkspaces => 'Munkaterületek kezelése';

  @override
  String get reorderWorkspace => 'Munkaterület átrendezése';

  @override
  String get matchOsAppearance =>
      'Kövesse a rendszer megjelenését, vagy válasszon rögzített módot.';

  @override
  String get mcpAuthToken => 'MCP hitelesítési token';

  @override
  String get mcpNotAvailableOnServer =>
      'Az MCP-szerver vezérlése nem érhető el a csatlakoztatott szerveren.';

  @override
  String get modelManagedOnServer =>
      'Ez a modell a szervergépen fut, és ott van kezelve.';

  @override
  String get mcpServer => 'MCP-szerver';

  @override
  String get medium => 'Közepes';

  @override
  String get memoryDataHint =>
      'A tények és szabályzatok itt jelennek meg, ahogy az ügynökök dolgoznak.';

  @override
  String get memoryLabel => 'Memória';

  @override
  String get merge => 'Összefésülés';

  @override
  String get merged => 'Összefésülve';

  @override
  String get messagePlaceholder => 'Üzenet… (@ említéshez, / parancsokhoz)';

  @override
  String get navConversations => 'Terek';

  @override
  String get microphonePermissionDenied => 'Mikrofonengedély megtagadva.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# perce',
      one: '# perce',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'Modell';

  @override
  String get modified => 'Módosítva';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# hónapja',
      one: '# hónapja',
    );
    return '$_temp0';
  }

  @override
  String get moreLabel => 'Több';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'Név';

  @override
  String get nameAndTitleRequired => 'A név és a cím kötelező.';

  @override
  String get nameAndUrlRequired => 'Név és URL kötelező';

  @override
  String get nameLabel => 'Név';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'A natív homokozó elérhető $platform rendszeren.';
  }

  @override
  String get nativeSandboxNeedsInstall => 'Natív homokozó telepítése szükséges';

  @override
  String get navObservability => 'Megfigyelhetőség';

  @override
  String get navSettings => 'Beállítások';

  @override
  String networkBlockCount(int count) {
    return '$count hálózati blokk';
  }

  @override
  String get neutral => 'Semleges';

  @override
  String get newCommitsPushed =>
      'Új commitok érkeztek — kattintson a diff újratöltéséhez';

  @override
  String get newFact => 'Új tény';

  @override
  String get newPolicy => 'Új szabályzat';

  @override
  String get newsfeed => 'Hírfolyam';

  @override
  String get newsfeedLabel => 'Hírfolyam';

  @override
  String get newsfeedSettingsDescription =>
      'Kezelje a feliratkozott hírfolyamokat és az olvasóbeállításokat.';

  @override
  String get newsfeedSettingsTitle => 'Hírfolyam beállításai';

  @override
  String get nextMatch => 'Következő találat (↵)';

  @override
  String get noActiveWorkspace =>
      'Nincs aktív munkaterület vagy kiválasztott tároló.';

  @override
  String get noActiveWorkspaceCreate => 'Nincs aktív munkaterület';

  @override
  String get noActiveWorkspaceGithub =>
      'Nincs aktív munkaterület GitHub-tárolóval.';

  @override
  String get noAgents => 'Nincsenek ügynökök';

  @override
  String get noArticlesYet => 'Még nincsenek cikkek';

  @override
  String get noArticlesYetBody => 'A hírfolyamok cikkei itt jelennek meg.';

  @override
  String get noExecutionLogsYet => 'Még nincsenek futtatási naplók';

  @override
  String get noFacts => 'Még nincsenek tények';

  @override
  String get noFeedsYet => 'Még nincsenek hírfolyamok';

  @override
  String get noFileAnchor =>
      'Nincs fájlhorgony — nem lehet sorközi megjegyzést közzétenni.';

  @override
  String get noFileChangesInScope =>
      'Nincsenek fájlmódosítások ebben a hatókörben';

  @override
  String get noGifsFound => 'Nem található GIF';

  @override
  String get noInputDevicesDetected =>
      'Nem található bemeneti eszköz — a rendszer alapértelmezettje kerül használatra.';

  @override
  String get noMatchingFiles => 'Nincs illeszkedő fájl';

  @override
  String get noMatchingGoogleFonts => 'Nincs illeszkedő Google Fonts.';

  @override
  String get noMemoryData => 'Még nincsenek memóriaadatok';

  @override
  String get noMessagesYet => 'Még nincsenek üzenetek';

  @override
  String get noModelsAdvertised => 'Ez az adapter nem hirdet modelleket.';

  @override
  String get noOpenPullRequests => 'Nincsenek nyitott pull requestek';

  @override
  String get noPolicies => 'Még nincsenek szabályzatok';

  @override
  String get noReposInWorkspaceYet =>
      'Még nincsenek tárolók ebben a munkaterületben';

  @override
  String get noRunnersDetected =>
      'Még nincsenek felismert futtatók. Frissítsen az újraellenőrzéshez.';

  @override
  String get noSavedArticles => 'Nincsenek mentett cikkek';

  @override
  String get noSavedArticlesBody => 'A mentett cikkek itt jelennek meg.';

  @override
  String noShortcutsMatch(String query) {
    return 'Nincs a(z) „$query” kifejezésre illeszkedő gyorsbillentyű';
  }

  @override
  String get noSystemFonts => 'Nem találhatók rendszerbetűtípusok.';

  @override
  String get noTokenSet => 'Nincs beállított token — a hozzáférés korlátlan.';

  @override
  String get noWorkingMemory => 'Még nincsenek munkamemória-jegyzetek.';

  @override
  String get noneAllRoles => 'Nincs (minden szerep)';

  @override
  String get notAvailable => 'Nem elérhető';

  @override
  String get notConfiguredLabel => 'Nincs beállítva.';

  @override
  String get notFoundLabel => 'Nem található';

  @override
  String get notes => 'Jegyzetek';

  @override
  String get notificationAgentFinished => 'Ügynök befejezte';

  @override
  String get notificationPrMentioned => 'Említve egy pull requestben';

  @override
  String get notificationNewMessages => 'Új üzenetek';

  @override
  String get notificationPrMerged => 'PR összefésülve';

  @override
  String get notificationPrPublished => 'PR közzétéve';

  @override
  String get notificationReviewRequested => 'Átnézést kértek';

  @override
  String get notifications => 'Értesítések';

  @override
  String get notifyAgentRunCompleted =>
      'Értesítés, ha egy ügynök befejez egy futtatást.';

  @override
  String get notifyPrMentioned => 'Értesítés, ha említik egy pull requestben.';

  @override
  String get notifyNewMessages =>
      'Értesítés új ügynöküzenetekről más terekben.';

  @override
  String get notifyPrMerged =>
      'Értesítés, ha egy pull requestet összefésülnek.';

  @override
  String get notifyPrPublished =>
      'Értesítés, ha egy ügynök pull requestet tesz közzé.';

  @override
  String get notifyReviewRequested =>
      'Értesítés, ha az Ön átnézését kérik egy pull requesten.';

  @override
  String get notificationReviewStale => 'Elavult átnézés';

  @override
  String get notifyReviewStale =>
      'Amikor új commitok érkeznek egy már átnézett pull requestre';

  @override
  String get notificationPrMergeReadiness => 'Összefésülésre kész';

  @override
  String get notifyPrMergeReadiness =>
      'Értesítés, ha egy Ön által jegyzett pull request összefésülhetővé válik, vagy megszűnik annak lenni.';

  @override
  String get notificationPrReviewDecision => 'Átnézési döntések';

  @override
  String get notifyPrReviewDecision =>
      'Értesítés, ha egy átnéző jóváhagy, módosítást kér, vagy egy jóváhagyást elutasítanak.';

  @override
  String get notificationPrChecksStatus => 'Ellenőrzések';

  @override
  String get notifyPrChecksStatus =>
      'Értesítés, ha a CI sikertelen egy Ön által jegyzett pull requesten, és amikor helyreáll.';

  @override
  String get notificationPrThreadActivity => 'Átnézési szálak';

  @override
  String get notifyPrThreadActivity =>
      'Értesítés, ha valaki válaszol vagy megold egy szálat, amelyben bent van.';

  @override
  String get notificationPrReadyToMerge => 'Összefésülésre kész';

  @override
  String notificationPrReadyToMergeBody(String prTitle) {
    return 'A(z) $prTitle mindent megkapott, ami kell.';
  }

  @override
  String get notificationPrMergeBlocked => 'Már nem összefésülhető';

  @override
  String notificationPrMergeBlockedBodyConflicts(String prTitle) {
    return 'A(z) $prTitle ütközik az alapággal.';
  }

  @override
  String notificationPrMergeBlockedBodyBehind(String prTitle) {
    return 'A(z) $prTitle lemaradt az alapágtól.';
  }

  @override
  String notificationPrMergeBlockedBodyReviews(String prTitle) {
    return 'A(z) $prTitle kötelező átnézésre vár.';
  }

  @override
  String notificationPrMergeBlockedBodyChanges(String prTitle) {
    return 'Egy átnéző módosítást kért a(z) $prTitle pull requesten.';
  }

  @override
  String notificationPrMergeBlockedBodyChecks(String prTitle) {
    return 'Az ellenőrzések sikertelenek a(z) $prTitle pull requesten.';
  }

  @override
  String notificationPrMergeBlockedBodyOther(String prTitle) {
    return 'A(z) $prTitle már nem fésülhető össze.';
  }

  @override
  String get notificationPrApproved => 'Pull request jóváhagyva';

  @override
  String notificationPrApprovedBodyBy(String login, String prTitle) {
    return '$login jóváhagyta: $prTitle';
  }

  @override
  String notificationPrApprovedBody(String prTitle) {
    return 'A(z) $prTitle jóvá lett hagyva';
  }

  @override
  String notificationPrReviewersRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# átnézőnek kell még válaszolnia',
      one: '# átnézőnek kell még válaszolnia',
      zero: 'nincs hátralévő átnéző',
    );
    return '$_temp0';
  }

  @override
  String get notificationPrChangesRequested => 'Módosítást kértek';

  @override
  String notificationPrChangesRequestedBodyBy(String login, String prTitle) {
    return '$login módosítást kért: $prTitle';
  }

  @override
  String notificationPrChangesRequestedBody(String prTitle) {
    return 'Módosítást kértek a(z) $prTitle pull requesten';
  }

  @override
  String get notificationPrReviewDismissed => 'Jóváhagyás elutasítva';

  @override
  String notificationPrReviewDismissedBody(String prTitle) {
    return 'A(z) $prTitle újra átnézésre szorul.';
  }

  @override
  String get notificationPrChecksFailed => 'Ellenőrzések sikertelenek';

  @override
  String notificationPrChecksFailedBody(String checkName, String prTitle) {
    return '$checkName sikertelen: $prTitle';
  }

  @override
  String notificationPrChecksFailedBodyUnnamed(String prTitle) {
    return 'Az ellenőrzések sikertelenek a(z) $prTitle pull requesten';
  }

  @override
  String get notificationPrChecksRecovered => 'Ellenőrzések rendben';

  @override
  String notificationPrChecksRecoveredBody(String prTitle) {
    return 'A(z) $prTitle újra zöld.';
  }

  @override
  String notificationPrMentionedInCommentBody(String login, String location) {
    return '$login említette itt: $location';
  }

  @override
  String get notificationPrThreadReplied => 'Új válasz';

  @override
  String notificationPrThreadRepliedBody(String login, String location) {
    return '$login válaszolt itt: $location';
  }

  @override
  String get notificationPrThreadResolved => 'Szál megoldva';

  @override
  String notificationPrThreadResolvedBody(String location) {
    return 'A szálát itt megoldották: $location.';
  }

  @override
  String get notificationGroupAgents => 'Ügynökök';

  @override
  String get notificationGroupPullRequests => 'Pull requestek';

  @override
  String get notificationGroupMessages => 'Üzenetek';

  @override
  String get notificationGroupTickets => 'Jegyek';

  @override
  String get notificationGroupCalendar => 'Naptár';

  @override
  String get notificationGroupMachines => 'Gépek';

  @override
  String get notificationsMutedRepos => 'Némított tárolók';

  @override
  String notificationsMutedReposCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# tároló némítva',
      one: '# tároló némítva',
      zero: 'Nincs némított tároló',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMuteRepo => 'Tároló némítása';

  @override
  String get onboardingLinuxDescription =>
      'A Control Center Linux-konténereket használhat az ügynökfuttatás elszigeteléséhez.';

  @override
  String get onboardingMacosDescription =>
      'A Control Center natív homokozót használ macOS-en az ügynökfuttatás elszigeteléséhez.';

  @override
  String get onboardingUnsupportedDescription =>
      'A homokozó nem érhető el ezen a platformon. Az ügynökfuttatás elszigetelés nélkül történik.';

  @override
  String get openArticlesInApp => 'Cikkek megnyitása az alkalmazásban';

  @override
  String get openInBrowser => 'Megnyitás böngészőben';

  @override
  String get openedInYourBrowser => 'Megnyitva a böngészőben.';

  @override
  String get openLabel => 'Megnyitás';

  @override
  String get openOnGithub => 'Megnyitás a GitHubon';

  @override
  String get openStatus => 'Nyitott';

  @override
  String get optionalPersonaDescription => 'Opcionális persona leírása';

  @override
  String get otherLabel => 'Egyéb';

  @override
  String get ownerOrganization => 'Tulajdonos / szervezet';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get passed => 'Sikeres';

  @override
  String get pasteValueHere => 'Illessze be az értéket ide';

  @override
  String get persona => 'Persona';

  @override
  String get policies => 'Szabályzatok';

  @override
  String get policiesHint =>
      'A szabályzatok itt jelennek meg, amikor az ügynökök tényeket emelnek.';

  @override
  String get policy => 'Szabályzat';

  @override
  String get popular => 'Népszerű';

  @override
  String get port => 'Port';

  @override
  String get postingEllipsis => 'Közzététel…';

  @override
  String get prCommits => 'Commitok';

  @override
  String get prMergedBody => 'Egy pull requestet összefésültek';

  @override
  String get prMoreActions => 'További műveletek';

  @override
  String get prTitle => 'PR címe';

  @override
  String get reviewCommentHint =>
      'Egyszerűen kattintson a jóváhagyásra, vagy ha van kedve, adjon megjegyzést vagy reakciót…';

  @override
  String get nothingToPreview => 'Nincs mit előnézni';

  @override
  String get previousMatch => 'Előző találat (⇧↵)';

  @override
  String get priorityReviewsDescription =>
      'Prioritásos átnézések és tárolóáttekintő.';

  @override
  String get prsCreated => 'Létrehozott PR-ek';

  @override
  String get prsMerged => 'Összefésült PR-ek';

  @override
  String get publishToGithub => 'Közzététel a GitHubon';

  @override
  String get published => 'Közzétéve';

  @override
  String get pullRequestApproved => 'Pull request jóváhagyva';

  @override
  String get pullRequests => 'Pull requestek';

  @override
  String get questionLabel => 'KÉRDÉS';

  @override
  String get queued => 'Várólistán';

  @override
  String get react => 'Reagálás';

  @override
  String get readPrsIssuesMetadata =>
      'Lehetővé teszi, hogy az ügynök olvassa a PR-eket, issue-kat és a tároló metaadatait.';

  @override
  String get readerPreferences => 'Olvasóbeállítások';

  @override
  String get reasoningEffort => 'Gondolkodási erőfeszítés';

  @override
  String get recommendLabel => 'AJÁNLÁS';

  @override
  String recordingFromDevice(String device) {
    return 'Felvétel innen: $device.';
  }

  @override
  String get redownload => 'Újraletöltés';

  @override
  String get redownloadEmbeddingModel => 'Újraletölti a beágyazási modellt?';

  @override
  String get redownloadVoiceModel => 'Újraletölti a hangmodellt?';

  @override
  String get refinePlan => 'Terv finomítása';

  @override
  String get refresh => 'Frissítés';

  @override
  String get refreshAll => 'Mind frissítése';

  @override
  String get refreshAllFeeds => 'Minden hírfolyam frissítése';

  @override
  String get reject => 'Elutasítás';

  @override
  String get rejected => 'Elutasítva';

  @override
  String get reload => 'Újratöltés';

  @override
  String get remove => 'Eltávolítás';

  @override
  String get removeBookmark => 'Könyvjelző eltávolítása';

  @override
  String get removeEmbeddingModel => 'Eltávolítja a beágyazási modellt?';

  @override
  String get removeLogo => 'Logó eltávolítása';

  @override
  String get removeRepoFromWorkspace =>
      'Eltávolítja a tárolót a munkaterületről?';

  @override
  String get removeVoiceModel => 'Eltávolítja a hangmodellt?';

  @override
  String get removed => 'Eltávolítva';

  @override
  String get renamed => 'Átnevezve';

  @override
  String get reopen => 'Újranyitás';

  @override
  String get resolve => 'Megoldás';

  @override
  String get replyEllipsis => 'Válasz…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return 'A(z) $name el lesz távolítva ebből a munkaterületből. A lemezen lévő helyi fájlokhoz nem nyúl.';
  }

  @override
  String repoAccessNoticeBody(String repos) {
    return 'A szerver GitHub-hitelesítő adatai nem látják: $repos. Ha a tároló szervezethez tartozik, telepítse ott a GitHub Appet, vagy csatlakoztasson hozzáféréssel rendelkező tokent.';
  }

  @override
  String repoAccessNoticeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tároló nem érhető el',
      one: 'Egy tároló nem érhető el',
    );
    return '$_temp0';
  }

  @override
  String get repoAccessNoticeSuspendedTitle =>
      'A GitHub App telepítése fel van függesztve';

  @override
  String repoAccessNoticeSuspendedBody(String repos) {
    return 'A $repos utoljára ismert adatai jelennek meg. Folytassa a telepítést a GitHubon, vagy csatlakoztasson hozzáféréssel rendelkező tokent.';
  }

  @override
  String get repoNoAccessBadge => 'Nincs hozzáférés';

  @override
  String get reportsTo => 'Felettese';

  @override
  String reposCount(int count) {
    return 'Tárolók ($count)';
  }

  @override
  String get reposDescription =>
      'Azok a helyi checkoutok, amelyeket ez a munkaterület céloz.';

  @override
  String get repositories => 'Tárolók';

  @override
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tároló',
      one: '1 tároló',
    );
    return 'Nem sikerült hozzáadni: $_temp0: $error';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tároló hozzáadva',
      one: 'Tároló hozzáadva',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => 'Tárolók beállításai';

  @override
  String get repositoryName => 'Tároló neve';

  @override
  String get requestChanges => 'Módosítás kérése';

  @override
  String get requested => 'Kérve';

  @override
  String get requestedChanges => 'Kért módosítások';

  @override
  String requiredRoleLabel(String role) {
    return 'Kötelező szerep: $role';
  }

  @override
  String get requiredRoleOptional => 'Kötelező szerep (nem kötelező)';

  @override
  String get requirements => 'Követelmények';

  @override
  String get reset => 'Visszaállítás';

  @override
  String get resolved => 'Megoldva';

  @override
  String get enclosedTerminalTitle => 'Elszigetelt terminál';

  @override
  String get enclosedTerminalStart => 'Shell megnyitása';

  @override
  String get enclosedTerminalStartHint =>
      'Ez a shell a beszélgetés eldobható VM-jében fut. Akkor indul, amikor megnyitja, nem az alkalmazás indításakor.';

  @override
  String get terminalStreamReconnecting =>
      'az adatfolyam megszakadt — újracsatlakozás…';

  @override
  String get terminalStreamError => 'adatfolyamhiba:';

  @override
  String get terminalShellExited => 'a shell kilépett';

  @override
  String get restartShell => 'Shell újraindítása';

  @override
  String get retry => 'Újrapróbálás';

  @override
  String get review => 'Átnézés';

  @override
  String get reviewedByMe => 'Általam átnézve';

  @override
  String get reviewers => 'Átnézők';

  @override
  String get roleLabel => 'Szerep';

  @override
  String get ruleHint => 'A szabályzat (Markdown támogatott)';

  @override
  String get ruleLabel => 'Szabály';

  @override
  String get runCompleted => 'Futtatás befejezve';

  @override
  String get running => 'Fut';

  @override
  String get runningLabel => 'fut';

  @override
  String get runs => 'Futtatások';

  @override
  String get runsLabel => 'Futtatások';

  @override
  String get sandboxBackendNativeLabel => 'Natív homokozó';

  @override
  String get sandboxBackendMicrovmLabel => 'Elszigetelt VM';

  @override
  String get sandboxBackendNoneLabel => 'Nincs elszigetelés';

  @override
  String get sandboxLinuxInstall =>
      'A natív homokozó Linuxon/WSL2-n bubblewrap-ot használ. Telepítés:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'A natív homokozó beépített macOS-en – Apple Seatbeltet (`sandbox-exec`) használ. Nincs szükség telepítésre.';

  @override
  String get sandboxPermissions => 'Homokozó-jogosultságok';

  @override
  String get sandboxUnsupported =>
      'A natív homokozó még nem támogatott ezen a platformon. Visszaáll „Nincs elszigetelés” módra.';

  @override
  String get sandboxingDisabledDescription =>
      'Az ügynökök közvetlenül a hoszton futnak teljes környezettel – nem ajánlott.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'Minden ügynökhívás a(z) $backend háttéren keresztül megy.';
  }

  @override
  String get save => 'Mentés';

  @override
  String get saveChanges => 'Módosítások mentése';

  @override
  String get adapterArguments => 'Extra argumentumok';

  @override
  String get adapterArgumentsHint => 'További CLI-jelzők (pl. --yolo)';

  @override
  String get addVariable => 'Változó hozzáadása';

  @override
  String get environmentVariables => 'Környezeti változók';

  @override
  String get environmentVariablesDescription =>
      'Egyéni környezeti változók, amelyeket ez az adapter kap (pl. API-kulcsok). A kulcstartóban tárolódnak.';

  @override
  String get variableKey => 'Kulcs';

  @override
  String get variableValue => 'Érték';

  @override
  String get savingEllipsis => 'Mentés…';

  @override
  String get scopeDiffToCommits =>
      'Diff hatóköre commitokra — Shift-kattintás tartományhoz';

  @override
  String get noPrsMatchSearch => 'Nincs illeszkedő pull request';

  @override
  String get searchFactsHint => 'Tények keresése...';

  @override
  String get searchFonts => 'Betűtípusok keresése…';

  @override
  String get searchGifs => 'GIF-ek keresése';

  @override
  String get searchGifsHint => 'GIF-ek keresése...';

  @override
  String get searchInDiffHint => 'Keresés a diffben…';

  @override
  String get searchOrTypeModel => 'Modellnév keresése vagy gépelése…';

  @override
  String get searchPlaceholder => 'Keresés…';

  @override
  String get searchShortcuts => 'Gyorsbillentyűk keresése…';

  @override
  String get shortcutUnavailableInBrowser => 'Nem érhető el a böngészőben';

  @override
  String get searching => 'Keresés…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# másodperce',
      one: '# másodperce',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'Adapter kiválasztása';

  @override
  String get selectAdapterFirst => 'Először válasszon adaptert';

  @override
  String get selectAgentToReportTo => 'Felettes ügynök kiválasztása…';

  @override
  String get selectAnAgent => 'Ügynök kiválasztása';

  @override
  String get selectConversation => 'Beszélgetés kiválasztása';

  @override
  String get selectLabel => 'Kiválasztás';

  @override
  String get selectRunner => 'Futtató kiválasztása';

  @override
  String get semanticSearch => 'Szemantikus keresés';

  @override
  String get send => 'Küldés';

  @override
  String get sendFirstMessage => 'Az első üzenet küldése';

  @override
  String get sendMessage => 'Üzenet küldése';

  @override
  String sentFindingsToAgent(int count) {
    return '$count megállapítás elküldve az ügynöknek.';
  }

  @override
  String setGithubLinkDescription(String name) {
    return 'Állítsa be a GitHub-tulajdonost és a tárolónevet ehhez: $name. Ez a PR- és issue-hivatkozások (pl. #123) feloldásához kell a Markdown tartalomban.';
  }

  @override
  String get setLabel => 'Beállítás';

  @override
  String get setToken => 'Token beállítása';

  @override
  String get settingsLabel => 'Beállítások';

  @override
  String get settingsLanguage => 'Nyelv';

  @override
  String get settingsLanguageDescription =>
      'Válassza ki az alkalmazás nyelvét.';

  @override
  String get shortTask => 'Rövid feladat';

  @override
  String get showNativeNotifications =>
      'Rendszerértesítések megjelenítése az eseményekhez.';

  @override
  String get showSuperseded => 'Felülírtak megjelenítése';

  @override
  String get signedIn => 'Bejelentkezve.';

  @override
  String signedInAs(String username) {
    return 'Bejelentkezve mint $username.';
  }

  @override
  String get skillNameRequired => 'A készség neve kötelező.';

  @override
  String skillSaved(String name) {
    return 'A(z) „$name” készség mentve.';
  }

  @override
  String get skillsSourcesTab => 'Források';

  @override
  String get skillSourcesDisclaimer =>
      'A készségek az Ön által hozzáadott GitHub-tárolókból települnek. A tároló metaadatai nem megbízhatók — a valódi biztonsági jel az antivírus-vizsgálat.';

  @override
  String get skillSourcesEmpty => 'Nincsenek készségtárolók';

  @override
  String get skillSourcesEmptyHint =>
      'Adjon hozzá egy GitHub-tárolót a készségeinek böngészéséhez.';

  @override
  String get skillSourceAdd => 'Tároló hozzáadása';

  @override
  String get skillSourceAddTitle => 'Készségtároló hozzáadása';

  @override
  String get skillSourceAddHint => 'https://github.com/owner/repo';

  @override
  String get skillSourceInvalidUrl =>
      'Adjon meg egy GitHub-tároló URL-t (https://github.com/owner/repo).';

  @override
  String skillSourceAdded(String repo) {
    return 'A(z) $repo tároló hozzáadva.';
  }

  @override
  String skillSourceAlreadyAdded(String repo) {
    return 'A(z) $repo tároló már hozzá van adva.';
  }

  @override
  String skillSourceRemoved(String repo) {
    return 'A(z) $repo tároló eltávolítva.';
  }

  @override
  String get skillSourceRemove => 'Eltávolítás';

  @override
  String skillSourceRemoveConfirmTitle(String repo) {
    return 'Eltávolítja: $repo?';
  }

  @override
  String get skillSourceRemoveConfirmBody =>
      'A telepített készségek telepítve maradnak. Csak a tárolókatalógus kerül eltávolításra.';

  @override
  String get skillSourceNoSkills =>
      'Nem találhatók készségek ebben a tárolóban (egy készség egy SKILL.md-t tartalmazó könyvtár).';

  @override
  String get skillSourceRefresh => 'Frissítés';

  @override
  String get skillSourceInstalledBadge => 'Telepítve';

  @override
  String get skillSourceUpdateBadge => 'Frissítés elérhető';

  @override
  String get skillSourceSlugTaken => 'A név foglalt';

  @override
  String skillSourceFilesCount(num count) {
    return '$count fájl';
  }

  @override
  String get skillSourceReadme => 'README';

  @override
  String get skillSourceNoReadme => 'Ennek a készségnek nincs README-je.';

  @override
  String get skillSourceNoMatches => 'Nincs a szűrőre illeszkedő készség.';

  @override
  String get skillUpdateAction => 'Frissítés';

  @override
  String get skillUninstallAction => 'Eltávolítás';

  @override
  String skillUninstallConfirmTitle(String slug) {
    return 'Eltávolítja a(z) „$slug” készséget?';
  }

  @override
  String skillUninstalled(String slug) {
    return 'A(z) „$slug” készség eltávolítva.';
  }

  @override
  String get skillFindingLine => 'sor';

  @override
  String get skillInstallAnywayOverride =>
      'Megértem a kockázatot — telepítés ennek ellenére';

  @override
  String skillInstalled(String slug) {
    return 'A(z) „$slug” készség telepítve.';
  }

  @override
  String get skillPreviewCapabilities => 'Képességek';

  @override
  String get skillPreviewFindings => 'Megállapítások';

  @override
  String get skillPreviewGuardedActions => 'Védett műveletek';

  @override
  String get skillPreviewLlmReviewed => 'LLM által átnézve';

  @override
  String get skillPreviewNoCapabilities => 'Nincsenek bejelentett képességek.';

  @override
  String get skillPreviewNoFindings => 'Nincsenek megállapítások.';

  @override
  String get skillPreviewScanning => 'Készség vizsgálata…';

  @override
  String get skillPreviewVerdictLabel => 'Vizsgálati ítélet';

  @override
  String get skillPreviewVerdictPass => 'Átment';

  @override
  String get skillPreviewVerdictQuarantine => 'Karanténban';

  @override
  String get skillPreviewVerdictWarn => 'Figyelmeztetés';

  @override
  String get skillQuarantineWarning =>
      'Ezt a készséget a vizsgáló karanténba helyezte. A telepítése kódot futtat a gépén. Csak akkor folytassa, ha megbízik a forrásban, és átnézte a megállapításokat.';

  @override
  String skillDetachedFromAgents(String agents) {
    return 'Karanténba helyezve és leválasztva az ügynökökről: $agents';
  }

  @override
  String get skillNotScanned => 'Nincs vizsgálva';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => 'Kézi';

  @override
  String get skillOriginRegistry => 'Registry';

  @override
  String get skillOriginRuntimeLocal => 'Helyi futtatókörnyezet';

  @override
  String get skillRulesStale => 'Elavult vizsgálat';

  @override
  String get skillSaveAnywayOverride =>
      'Megértem a kockázatot — mentés ennek ellenére';

  @override
  String get skillSaveBlockedBody =>
      'A tartalmat blokkolták, mielőtt bármi íródott volna.';

  @override
  String get skillSaveBlockedTitle => 'A mentést a vizsgálati kapu blokkolta';

  @override
  String get skillScanAction => 'Vizsgálat';

  @override
  String get skillScanAll => 'Mind vizsgálata';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass átment · $warn figyelmeztetés · $quarantine karanténban';
  }

  @override
  String get skillStateDrifted => 'Telepítés óta módosítva';

  @override
  String get skillStateUnmanaged => 'Nem kezelt';

  @override
  String get skillSeverityBlocked => 'Blokkolva';

  @override
  String get skillSeverityWarn => 'Figyelmeztetés';

  @override
  String get skillsInstalledTab => 'Telepítve';

  @override
  String get skills => 'Készségek';

  @override
  String get skipAcceptRisk => 'Kihagyás — elfogadom a kockázatot';

  @override
  String get skipForNow => 'Kihagyás egyelőre';

  @override
  String get skipSandboxing => 'Homokozó kihagyása';

  @override
  String get skipSandboxingDialogContent =>
      'Biztosan kihagyja a homokozót? Így az ügynökök elszigetelés nélkül futtathatnak kódot a rendszerén.';

  @override
  String get somethingWentWrong => 'Valami hiba történt';

  @override
  String sourceCount(int count) {
    return '$count forrás';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count forrás';
  }

  @override
  String get sourceFacts => 'Forrástények:';

  @override
  String get splitDiff => 'Osztott (egymás melletti) diff';

  @override
  String get startLabel => 'Indítás';

  @override
  String get startOnAppLaunch => 'Indítás az alkalmazás indításakor';

  @override
  String get statusLabel => 'Állapot';

  @override
  String get onboardingStepConnect => 'Csatlakozás';

  @override
  String get onboardingStepWorkspace => 'Munkaterület';

  @override
  String get onboardingStepSandbox => 'Homokozó';

  @override
  String get onboardingStepAdapter => 'Adapter';

  @override
  String get onboardingStepVoice => 'Hang';

  @override
  String get stop => 'Leállítás';

  @override
  String get stopped => 'Leállítva';

  @override
  String get strictIdentityCheck => 'Szigorú identitásellenőrzés';

  @override
  String get success => 'Siker';

  @override
  String get successLabel => 'Siker';

  @override
  String get suggestAChange => 'Módosítás javaslása';

  @override
  String get suggestLabel => 'JAVASLAT';

  @override
  String get superseded => 'Felülírva';

  @override
  String get synced => 'Szinkronizálva';

  @override
  String get systemDefault => 'Rendszer alapértelmezett';

  @override
  String get systemFonts => 'Rendszerbetűtípusok';

  @override
  String get systemPrompt => 'Rendszerprompt';

  @override
  String get systemPromptLabel => 'Rendszerprompt';

  @override
  String get talkToControlCenter => 'Beszéljen a Control Centerrel.';

  @override
  String get taskMentionSection => 'Feladat';

  @override
  String get testLabel => 'Teszt';

  @override
  String get theme => 'Téma';

  @override
  String get themeDark => 'Sötét';

  @override
  String get themeLight => 'Világos';

  @override
  String get themeSystem => 'Rendszer';

  @override
  String get thisCannotBeUndone => 'Ezt nem lehet visszavonni.';

  @override
  String get ticketLabel => 'JEGY';

  @override
  String get titleLabel => 'Cím';

  @override
  String get todayLabel => 'Ma';

  @override
  String get toggleTheme => 'Téma váltása';

  @override
  String get tokenConfigured =>
      'Beállítva — a klienseknek be kell mutatniuk ezt a tokent.';

  @override
  String get topic => 'Téma';

  @override
  String get topicHint => 'pl. Tech Stack, Design System';

  @override
  String get totalRuns => 'Összes futtatás';

  @override
  String trackingParamsCount(int count) {
    return '$count követési paraméter';
  }

  @override
  String get typeCommandOrSearch => 'Írjon parancsot vagy keressen…';

  @override
  String get typography => 'Tipográfia';

  @override
  String get unavailable => 'Nem elérhető';

  @override
  String get unifiedDiff => 'Egységes diff';

  @override
  String get unknownAuthor => 'Ismeretlen';

  @override
  String get unnamedAgent => 'Névtelen ügynök';

  @override
  String get updateKey => 'Kulcs frissítése';

  @override
  String get updateLabel => 'Frissítés';

  @override
  String get updateToken => 'Token frissítése';

  @override
  String updatedDaysAgo(int count) {
    return 'Frissítve $count n. ezelőtt';
  }

  @override
  String updatedHoursAgo(int count) {
    return 'Frissítve $count ó. ezelőtt';
  }

  @override
  String get updatedJustNow => 'Frissítve épp most';

  @override
  String updatedMinutesAgo(int count) {
    return 'Frissítve $count p. ezelőtt';
  }

  @override
  String get useSandbox => 'Homokozó használata';

  @override
  String get useWorkspaceDefault => 'Munkaterület alapértelmezettje';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      'Hagyja üresen az alkalmazás alapértelmezett User-Agentjéhez. Egyes oldalak blokkolják a nem böngésző User-Agenteket.';

  @override
  String get usingSystemDefaultMicrophone =>
      'A rendszer alapértelmezett mikrofonja van használatban.';

  @override
  String get viewLabel => 'Nézet';

  @override
  String get viewLogs => 'Naplók megtekintése';

  @override
  String voiceInstallFailed(String error) {
    return 'A telepítés sikertelen: $error';
  }

  @override
  String get voiceModelNotInstalled =>
      'Nincs telepítve. Egyszer ~200 MB-ot tölt le; teljesen a készüléken fut.';

  @override
  String get voiceModelNotInstalledLabel => 'Hangmodell nincs telepítve.';

  @override
  String get voiceRedownloadBody =>
      'A meglévő modellfájlok törlődnek, és a ~200 MB-os archívum újra letöltődik. A hangátírás a letöltés befejezéséig nem lesz elérhető.';

  @override
  String get voiceRemoveBody =>
      'A hangátírás le lesz tiltva, amíg újra nem telepíti. Bármikor újratelepítheti.';

  @override
  String get voiceTranscription => 'Hangátírás';

  @override
  String get weakIsolationDescription =>
      'Gyenge elszigetelés – csak névtérhatár, nincs kernelhatár.';

  @override
  String get whenOffNoDefaultRoute =>
      'Ha ki van kapcsolva, a homokozó alapértelmezett útvonal nélkül indul.';

  @override
  String get whenOffServerStaysStopped =>
      'Ha ki van kapcsolva, a szerver leállítva marad, amíg el nem indítja.';

  @override
  String get speechModel => 'Beszédmodell';

  @override
  String get speechModelHint =>
      'Megbeszélés-átíráshoz és a szerkesztő mikrofonjához.';

  @override
  String get voiceModelInstalled =>
      'Telepítve. A megbeszélés-átírást és a szerkesztő mikrofon gombját működteti.';

  @override
  String get meetingMicSilentWarning =>
      'A mikrofonja némítva lehet — a többiek beszélnek, de semmi nem jut el a mikrofonjához.';

  @override
  String get meetingSummaryPrivacyNotice =>
      'A felvétel és az átírás ezen a gépen marad. Az összefoglalót egy ügynök írja, így ha felhőmodellt használ, az átirat és a jegyzetek eljutnak ahhoz a szolgáltatóhoz.';

  @override
  String get meetingTemplates => 'Megbeszélés-jegyzet sablonok';

  @override
  String get meetingTemplatesHint =>
      'Formálja az AI-összefoglalót a megbeszélés típusához. Az aktív sablon az új és az újrafuttatott összefoglalókra vonatkozik.';

  @override
  String get meetingTemplateActive => 'Aktív sablon';

  @override
  String get meetingTemplateAdd => 'Sablon hozzáadása';

  @override
  String get meetingTemplateNewTitle => 'Új sablon';

  @override
  String get meetingTemplateEditTitle => 'Sablon szerkesztése';

  @override
  String get meetingTemplateNameLabel => 'Név';

  @override
  String get meetingTemplateNameHint => 'pl. Sprint review';

  @override
  String get meetingTemplateInstructionsLabel => 'Utasítások';

  @override
  String get meetingTemplateInstructionsHint =>
      'Hogyan strukturálja és hangsúlyozza az AI ezeket a jegyzeteket?';

  @override
  String get workingMemory => 'Munkamemória';

  @override
  String get workspaceName => 'Munkaterület neve';

  @override
  String get workspaceScopedSkills =>
      'Munkaterület-hatókörű készségfájlok, amelyek ügynökökhöz vannak csatolva.';

  @override
  String get workspaces => 'Munkaterületek';

  @override
  String get writePrivateNotes =>
      'Írjon privát jegyzeteket, megfigyeléseket, terveket...';

  @override
  String get writeSkillContent => 'Írja ide a készség tartalmát (Markdown)…';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# éve',
      one: '# éve',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'Tegnap';

  @override
  String get focusModeStart => 'Fókuszmunkamenet indítása';

  @override
  String get focusModeConfigTitle => 'Fókuszmunkamenet indítása';

  @override
  String get focusModeGoalLabel => 'Cél';

  @override
  String get focusModeGoalHint => 'Min dolgozik?';

  @override
  String get focusModeDurationLabel => 'Időtartam';

  @override
  String get focusModeBlockNotifications => 'Értesítések blokkolása';

  @override
  String get focusModeStartButton => 'Indítás';

  @override
  String get focusModeFloat => 'Minimalizálás sávra';

  @override
  String get focusModeActiveTooltip =>
      'Fókuszmód aktív — koppintson a befejezéshez';

  @override
  String get dismiss => 'Elvetés';

  @override
  String get acceptAndResolve => 'Elfogadás és megoldás';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'Már $minutes perce néz át — a kutatások szerint az átnézés minősége 60 perc után romolhat. Fontolja meg a szünetet.';
  }

  @override
  String get notificationSound => 'Értesítési hang';

  @override
  String get notificationSoundDescription =>
      'Az értesítés megjelenésekor lejátszott hang.';

  @override
  String get notificationSoundNone => 'Nincs';

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
  String get notificationSoundMigrosSoft => 'Migros (lágy)';

  @override
  String get notificationSoundMigrosHard => 'Migros (kemény)';

  @override
  String get notificationSoundSbb => 'SBB';

  @override
  String get notificationSoundCff => 'CFF';

  @override
  String get notificationSoundFfs => 'FFS';

  @override
  String get notificationSoundPost => 'Post';

  @override
  String get notificationSoundTest => 'Teszt';

  @override
  String get notificationVolume => 'Hangerő';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'Nincs PR @$login felhasználótól ebben a munkaterületben';
  }

  @override
  String get usersLabel => 'Felhasználók';

  @override
  String get mergePullRequest => 'Pull request összefésülése';

  @override
  String get forceMergePullRequest =>
      'Pull request kényszerített összefésülése';

  @override
  String get closePullRequest => 'Pull request lezárása';

  @override
  String get closePullRequestConfirm =>
      'Biztosan lezárja ezt a pull requestet?';

  @override
  String get stackedPullRequests => 'Halmozott pull requestek';

  @override
  String partOfStack(int position, int total) {
    return 'Halom része ($position / $total)';
  }

  @override
  String get createStack => 'Halom létrehozása';

  @override
  String get createStackDialogTitle => 'Pull request halom létrehozása';

  @override
  String createStackDialogBody(int count) {
    return 'Ez a $count pull request kerül halomba, alulról felfelé:';
  }

  @override
  String get createStackInvalidSelection =>
      'Válasszon legalább két pull requestet ugyanabból a tárolóból a halom létrehozásához';

  @override
  String get createStackNotAChain =>
      'A kijelölt pull requestek nem alkotnak láncot: minden pull request alapágának az előző head ágának kell lennie';

  @override
  String get createStackAlreadyStacked =>
      'Egy vagy több kijelölt pull request már halomban van';

  @override
  String get stackCreated => 'Halom létrehozva';

  @override
  String get stackCreationFailed => 'Nem sikerült létrehozni a halmot';

  @override
  String get squashAndMerge => 'Squash és összefésülés';

  @override
  String get createMergeCommit => 'Összefésülési commit létrehozása';

  @override
  String get rebaseAndMerge => 'Rebase és összefésülés';

  @override
  String get commitTitle => 'Commit címe';

  @override
  String get commitDescription => 'Commit leírása';

  @override
  String get pullRequestMerged => 'Pull request összefésülve';

  @override
  String get pullRequestClosed => 'Pull request lezárva';

  @override
  String failedToMergePr(String error) {
    return 'Nem sikerült összefésülni: $error';
  }

  @override
  String failedToClosePr(String error) {
    return 'Nem sikerült lezárni: $error';
  }

  @override
  String get markReadyForReview => 'Kész az átnézésre';

  @override
  String get markReadyForReviewConfirm =>
      'Ez a pull request kilép a piszkozatból. Az átnézők értesítést kapnak, a kötelező ellenőrzések kapuzni kezdik az összefésülést, és minden, a kész pull requestekre figyelő automatizmus lefut.';

  @override
  String get convertToDraft => 'Átalakítás piszkozattá';

  @override
  String get convertToDraftConfirm =>
      'Ez a pull request visszakerül piszkozatba. A függő átnézési kérései elutasításra kerülnek, és addig nem fésülhető össze, amíg újra késznek nem jelöli.';

  @override
  String get pullRequestMarkedReady =>
      'Pull request késznek jelölve az átnézésre';

  @override
  String get pullRequestConvertedToDraft => 'Pull request piszkozattá alakítva';

  @override
  String failedToMarkPrReady(String error) {
    return 'Nem sikerült késznek jelölni az átnézésre: $error';
  }

  @override
  String failedToConvertPrToDraft(String error) {
    return 'Nem sikerült piszkozattá alakítani: $error';
  }

  @override
  String get checksFailing => 'Ellenőrzések sikertelenek';

  @override
  String get reviewsPending => 'Néhány átnézés függőben van';

  @override
  String get mergeConflictsWithBase =>
      'Ennek az ágnak ütközései vannak, amelyeket meg kell oldani';

  @override
  String get branchOutOfDateWithBase => 'Ez az ág lemaradt az alapágtól';

  @override
  String get mergeBlockedByBranchProtection =>
      'Az ágvédelem blokkolja ezt az összefésülést';

  @override
  String get confirm => 'Megerősítés';

  @override
  String get trustedSitesSectionTitle => 'Megbízható oldalak';

  @override
  String get trustedSitesEmpty =>
      'Nincsenek megbízható oldalak. Adjon hozzá egy domaint a blokkolás kikapcsolásához.';

  @override
  String get addTrustedSite => 'Megbízható oldal hozzáadása';

  @override
  String get removeTrustedSite => 'Eltávolítás';

  @override
  String get disableBlockingForThisSite =>
      'Blokkolás kikapcsolása ezen az oldalon';

  @override
  String get enableBlockingForThisSite =>
      'Blokkolás bekapcsolása ezen az oldalon';

  @override
  String get enterDomainHint => 'pl. example.com';

  @override
  String get invalidDomain => 'Adjon meg érvényes domaint (pl. example.com)';

  @override
  String get pageLoadTimedOut =>
      'Az oldal betöltése időtúllépéssel lejárt. Töltse újra, vagy nyissa meg böngészőben.';

  @override
  String get pipelinesScreenTitle => 'Pipeline-ok';

  @override
  String get pipelinesScreenSubtitle =>
      'Deklaratív, többlépéses ügynök-munkafolyamatok';

  @override
  String get pipelinesRunPipeline => 'Pipeline futtatása';

  @override
  String get pipelineRunLauncherTitle => 'Pipeline futtatása';

  @override
  String get pipelineRunSubtitle =>
      'Válasszon pipeline-t, és töltse ki a bemeneteit a futtatás indításához.';

  @override
  String get pipelineRunNoInputsBadge => 'Nincs bemenet';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# bemenet',
      one: '# bemenet',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'Ez a pipeline nem vár bemenetet.';

  @override
  String get pipelineRunSubmit => 'Pipeline futtatása';

  @override
  String get pipelineRunCouldNotStart => 'Nem sikerült elindítani a futtatást.';

  @override
  String pipelineRunStarted(String name) {
    return '$name elindítva';
  }

  @override
  String get pipelineRunEmptyTitle => 'Nincs futtatásra kész pipeline';

  @override
  String get pipelineRunEmptyHint =>
      'Engedélyezzen egy pipeline-t, és kapcsolja be a kézi futtatást a szerkesztőjében, hogy innen indíthassa.';

  @override
  String get pipelineRunManageTemplates => 'Pipeline-ok kezelése';

  @override
  String get pipelineRunSettingsTitle => 'Kézi futtatás';

  @override
  String get pipelineRunSettingsAllow => 'Kézi futtatás engedélyezése';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'Jelenítse meg ezt a pipeline-t a futtatási oldalon, hogy kézzel indítható legyen.';

  @override
  String get pipelineRunSettingsConcurrencyTitle => 'Párhuzamosság';

  @override
  String get pipelineRunSettingsMaxParallel => 'Max. párhuzamos futtatás';

  @override
  String get pipelineRunSettingsMaxParallelHelp =>
      'Hagyja üresen a korlátlanhoz. A további futtatások várólistára kerülnek, és a helyek felszabadulásakor indulnak.';

  @override
  String get pipelineRunSettingsMaxParallelHint => 'Korlátlan';

  @override
  String get pipelineRunSettingsMaxParallelInvalid =>
      'Adjon meg legalább 1-es egész számot, vagy hagyja üresen a korlátlanhoz.';

  @override
  String get pipelineRunSettingsInputsTitle => 'Bemenetek';

  @override
  String get pipelineRunSettingsAddInput => 'Bemenet hozzáadása';

  @override
  String get pipelineRunSettingsNoInputs => 'Még nincsenek bemenetek.';

  @override
  String get pipelineInputEditTitle => 'Bemeneti mező';

  @override
  String get pipelineInputKeyLabel => 'Kulcs';

  @override
  String get pipelineInputKeyHelp =>
      'Állapotkulcs, amely alatt az érték tárolódik (pl. repo_full_name).';

  @override
  String get pipelineInputLabelLabel => 'Címke';

  @override
  String get pipelineInputTypeLabel => 'Típus';

  @override
  String get pipelineInputOptionsLabel => 'Opciók (vesszővel elválasztva)';

  @override
  String get pipelineInputDefaultLabel => 'Alapértelmezett érték';

  @override
  String get pipelineInputPlaceholderLabel => 'Helyőrző';

  @override
  String get pipelineInputHelpLabel => 'Súgószöveg';

  @override
  String get pipelineInputRequiredLabel => 'Kötelező';

  @override
  String get pipelineInputTypeText => 'Szöveg';

  @override
  String get pipelineInputTypeMultiline => 'Többsoros szöveg';

  @override
  String get pipelineInputTypeNumber => 'Szám';

  @override
  String get pipelineInputTypeBoolean => 'Kapcsoló';

  @override
  String get pipelineInputTypeSelect => 'Választó';

  @override
  String get pipelinesEmpty => 'Még nincsenek pipeline-futtatások';

  @override
  String get pipelinesEmptyHint =>
      'Kattintson a „Pipeline futtatása” gombra egy indításához.';

  @override
  String get pipelinesNoSteps => 'Még nincsenek rögzített lépések';

  @override
  String get pipelinesNoActiveWorkspace =>
      'Válasszon munkaterületet a pipeline-ok megtekintéséhez';

  @override
  String pipelinesLoadError(String error) {
    return 'Nem sikerült betölteni a pipeline-okat: $error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'Nem sikerült elindítani a pipeline-t: $error';
  }

  @override
  String get pipelineStatusPending => 'Függőben';

  @override
  String get pipelineStatusQueued => 'Várólistán';

  @override
  String get pipelineStatusRunning => 'Fut';

  @override
  String get pipelineStatusSuspended => 'Felfüggesztve';

  @override
  String get pipelineStatusCompleted => 'Befejezve';

  @override
  String get pipelineStatusFailed => 'Sikertelen';

  @override
  String get pipelineStatusCancelled => 'Megszakítva';

  @override
  String get pipelineStatusSkipped => 'Kihagyva';

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed / $total lépés';
  }

  @override
  String get pipelineWaterfallTimeline => 'Idővonal';

  @override
  String pipelineWaterfallActive(String duration) {
    return 'Aktív $duration';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return 'tétlen $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip =>
      'Az aktív összesenből kizárt idő: a futtatás leállt, vagy lépések között várt.';

  @override
  String get pipelineStepStarted => 'Elindítva';

  @override
  String get pipelineStepFinished => 'Befejezve';

  @override
  String get pipelineStepDurationLabel => 'Időtartam';

  @override
  String get pipelineStepBranch => 'Ág';

  @override
  String get pipelineStepViewConversation => 'Beszélgetés megtekintése';

  @override
  String get pipelineStepError => 'Hiba';

  @override
  String get pipelineStepInput => 'Bemenet';

  @override
  String get pipelineStepOutput => 'Kimenet';

  @override
  String get pipelineStepNotExecuted => 'Még nincs végrehajtva';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'Sikertelen itt: $step';
  }

  @override
  String get pipelineRunTriggerManual => 'Kézi';

  @override
  String get pipelineStepSkippedReason => 'Kihagyva';

  @override
  String get pipelineStepPriorAttempts => 'Korábbi kísérletek';

  @override
  String get pipelineStepAttemptLabel => 'Kísérlet';

  @override
  String pipelineStepAttemptN(int number) {
    return '$number. kísérlet';
  }

  @override
  String get pipelineStepAttemptInterrupted => 'Megszakítva';

  @override
  String get pipelineRunColumnPipeline => 'Pipeline';

  @override
  String get pipelineRunColumnDuration => 'Időtartam';

  @override
  String get pipelineRunQueueNext => 'Következő';

  @override
  String pipelineRunQueuePosition(int position) {
    return '$position. a várólistán';
  }

  @override
  String get pipelineRunColumnStarted => 'Elindítva';

  @override
  String get pipelineRunHistory => 'Futtatási előzmény';

  @override
  String get pipelineRunHistoryEmpty => 'Még nincs másik futtatás';

  @override
  String pipelineRunRerunAgo(String time) {
    return 'Újrafuttatás $time';
  }

  @override
  String pipelineRunAttempt(int number) {
    return '$number. kísérlet';
  }

  @override
  String pipelineRunFirstStarted(String time) {
    return 'először elindítva $time';
  }

  @override
  String get pipelineRunFilterAll => 'Mind';

  @override
  String get pipelineRunFilterEmpty => 'Nincs a szűrőre illeszkedő futtatás';

  @override
  String get relativeJustNow => 'épp most';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# perce',
      one: '# perce',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# órája',
      one: '# órája',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# napja',
      one: '# napja',
    );
    return '$_temp0';
  }

  @override
  String get teamsTitle => 'Csapatok';

  @override
  String get teamsAddTeam => 'Csapat hozzáadása';

  @override
  String get teamsLoadError => 'Nem sikerült betölteni a csapatokat';

  @override
  String get teamsEmptyTitle => 'Még nincsenek csapatok';

  @override
  String get teamsEmptyDescription =>
      'Csoportosítsa az ügynököket csapatokba, hogy a csapathoz rendelt munka egy vezetőn keresztül fusson, aki delegál.';

  @override
  String get teamCreateTitle => 'Új csapat';

  @override
  String get teamEditTitle => 'Csapat szerkesztése';

  @override
  String get teamNameLabel => 'Csapat neve';

  @override
  String get teamNameHint => 'pl. Frontend';

  @override
  String get teamDescriptionLabel => 'Leírás';

  @override
  String get teamDescriptionHint => 'Mire felelős ez a csapat';

  @override
  String get teamLeaderLabel => 'Vezető';

  @override
  String get teamLeaderHelp =>
      'A koordinátor, aki a csapathoz rendelt munkát kapja, és a legalkalmasabb tagnak delegálja.';

  @override
  String get teamNoLeader => 'Nincs vezető';

  @override
  String get teamInstructionsLabel => 'Működési utasítások';

  @override
  String get teamInstructionsHelp =>
      'A vezető eligazításához fűzve — csapatkonvenciók, eszkalációs szabályok, hangnem.';

  @override
  String get teamInstructionsHint => 'Nem kötelező';

  @override
  String get teamSaved => 'Csapat mentve';

  @override
  String get teamMembersError => 'Nem sikerült betölteni a tagokat';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# tag',
      one: '# tag',
      zero: 'Nincsenek tagok',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => 'Tag hozzáadása';

  @override
  String get teamAddMemberTitle => 'Tagok hozzáadása';

  @override
  String teamAddMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hozzáadása',
      one: '1 hozzáadása',
      zero: 'Hozzáadás',
    );
    return '$_temp0';
  }

  @override
  String get teamNoAgentsToAdd => 'Minden ügynök már ebben a csapatban van.';

  @override
  String get teamRemoveMember => 'Eltávolítás a csapatból';

  @override
  String get teamLeaderBadge => 'Vezető';

  @override
  String get teamUnknownAgent => 'Ismeretlen ügynök';

  @override
  String get teamMembersEmpty => 'Még nincsenek tagok';

  @override
  String get teamMembersEmptyDescription =>
      'Adjon hozzá ügynököket, hogy a vezetőnek legyen kinek delegálnia.';

  @override
  String get teamSelectPrompt => 'Csapat kiválasztása';

  @override
  String get teamSelectPromptDescription =>
      'Válasszon csapatot a listából, vagy hozzon létre egy újat.';

  @override
  String get teamDeleteTitle => 'Törli a csapatot?';

  @override
  String teamDeleteBody(String name) {
    return 'A(z) $name törlődik. Az ügynökeit nem érinti.';
  }

  @override
  String get teamHasLeaderTooltip => 'Van vezetője';

  @override
  String get pipelineTemplatesNav => 'Pipeline-sablonok';

  @override
  String get pipelineTemplatesTitle => 'Pipeline-sablonok';

  @override
  String get pipelineTemplatesSubtitle =>
      'Húzd-és-ejtsd szerkesztő a pipeline-okhoz, amelyek az ügynökeit orchestrálják.';

  @override
  String get pipelineTemplatesNew => 'Új sablon';

  @override
  String get pipelineTemplatesEmpty =>
      'Még nincsenek pipeline-sablonok. Hozzon létre egyet a kezdéshez.';

  @override
  String get pipelineTemplateBuiltInBadge => 'Beépített';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'Törli a sablont?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'Törli a(z) $name pipeline-sablont? Ezt nem lehet visszavonni.';
  }

  @override
  String get pipelineTemplateEditorSubtitle =>
      'Húzza a csomóponttípusokat az oldalsávból a vászonra, majd kösse össze őket.';

  @override
  String get unsavedChanges => 'Mentetlen módosítások';

  @override
  String get nodeLibraryTitle => 'Csomópontkönyvtár';

  @override
  String get nodeLibraryHint =>
      'Húzzon bármely elemet a vászonra egy csomópont hozzáadásához.';

  @override
  String get editorEmptyCanvas =>
      'Húzzon egy csomópontot a könyvtárból a kezdéshez.';

  @override
  String get pipelineWhenThisHappens => 'Amikor ez történik';

  @override
  String get pipelineDoThis => 'Tegye ezt';

  @override
  String get pipelineAddStep => 'Lépés hozzáadása';

  @override
  String get pipelineTidyUp => 'Elrendezés rendezése';

  @override
  String get pipelineEditorHint =>
      'Húzza a lépéseket az elrendezéshez · húzza a fogantyút a csatlakozáshoz';

  @override
  String get pipelineRemoveConnection => 'Kapcsolat eltávolítása';

  @override
  String get pipelineDragToConnect => 'Húzza a csatlakozáshoz';

  @override
  String get pipelineNewDefaultName => 'Új pipeline';

  @override
  String get nodeCategoryTriggers => 'Triggerek';

  @override
  String get triggerEventWebhook => 'Webhook';

  @override
  String get pipelineAddTrigger => 'Trigger hozzáadása';

  @override
  String get pipelineOnEvent => 'Eseményre';

  @override
  String get nodeConfigTitle => 'Csomópont beállítása';

  @override
  String get nodeConfigKind => 'Típus';

  @override
  String get nodeConfigLabel => 'Címke';

  @override
  String get nodeConfigAgent => 'Ügynök';

  @override
  String get nodeConfigAgentHint => 'Ügynök kiválasztása…';

  @override
  String get nodeConfigInputKeys => 'Bemeneti kulcsok (vesszővel elválasztva)';

  @override
  String get nodeConfigInputKeysHelp =>
      'Állapotkulcsok, amelyeket ez a csomópont fogyaszt. A prompt helyőrző-helyettesítéséhez.';

  @override
  String get nodeConfigRepos => 'Klónozandó tárolók';

  @override
  String get nodeConfigReposHelp =>
      'A csomópont beszélgetésének indításakor klónozott és kódindexelt tárolók. Minden tároló kijelölése mindet klónozza (az alapértelmezett).';

  @override
  String get nodeConfigRepoBranchHint => 'Ág (alapértelmezett)';

  @override
  String get nodeConfigRepoBranchHelp =>
      'Az ág, amelyből minden checkout készül. Hagyja üresen a tároló saját alapértelmezett ágához — a worktree ettől függetlenül saját ágat kap, így az ügynök commitjai nem erre kerülnek.';

  @override
  String nodeConfigReposDynamic(String entries) {
    return 'Megtartott dinamikus bejegyzések: $entries';
  }

  @override
  String get nodeConfigCreateConversation => 'Beszélgetés megnyitása benne';

  @override
  String get nodeConfigCreateConversationHelp =>
      'Hagyja ki, ha több ügynökcsomópont követi — mindegyik saját elnevezett adatfolyamot nyit. Kapcsolja be, ha egyetlen ügynökcsomópont követi, hogy a szoba ne mutasson cím nélküli beszélgetést mellette.';

  @override
  String get nodeConfigConversationTitle => 'Beszélgetés neve';

  @override
  String get nodeConfigConversationTitleHelp =>
      'Adja ugyanazt a nevet a lefelé következő ügynökcsomópontnak, és mindketten egy adatfolyamban dolgoznak. Alapértelmezés a csomópont címkéje.';

  @override
  String get nodeConfigSpaceName => 'Tér neve';

  @override
  String get nodeConfigSpaceNameHelp =>
      'Hogyan hívják a szobát, amelyet ez a csomópont nyit. Ugyanazokat az állapothelyőrzőket támogatja, mint egy prompt. Hagyja üresen a csomópont címkéjéhez.';

  @override
  String get nodeConfigSpaceNameHint => 'Review of pr_number';

  @override
  String get nodeConfigStreamTitle => 'Beszélgetés neve';

  @override
  String get nodeConfigStreamTitleHelp =>
      'Az elnevezett adatfolyam, amelyben ennek a csomópontnak az ügynöke dolgozik a szobában. Ugyanazokat az állapothelyőrzőket támogatja, mint egy prompt. Ha üresen hagyja, a kör a szoba állandó beszélgetésébe kerül, ahol a szétosztás minden ügynököt összefésül.';

  @override
  String get nodeConfigConversationTitleHint => 'Architecture analysis';

  @override
  String get nodeConfigOutputKey => 'Kimeneti kulcs';

  @override
  String get nodeConfigPrompt => 'Prompt sablon';

  @override
  String get nodeConfigPromptHelp =>
      'Használjon dupla kapcsos helyőrzőket az állapotértékek futásidejű beemeléséhez.';

  @override
  String get nodeConfigScript => 'Bash szkript';

  @override
  String get nodeConfigScriptHelp =>
      'bash -c-vel fut. A GITHUB_TOKEN be van állítva. A helyőrzők a végrehajtás előtt helyettesítődnek.';

  @override
  String get nodeConfigRouteKeys => 'Útvonalkulcsok';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'Útvonalkulcs innen: $source';
  }

  @override
  String get conditionSectionTitle => 'Feltétel';

  @override
  String get conditionMode => 'Mód';

  @override
  String get conditionModeFilesAny => 'Fájl(ok) léteznek — bármelyik';

  @override
  String get conditionModeFilesAll => 'Fájlok léteznek — mind';

  @override
  String get conditionModeComparison => 'Összehasonlítás';

  @override
  String get conditionModeSwitch => 'Kapcsoló';

  @override
  String get conditionFilePaths => 'Fájlútvonalak';

  @override
  String get conditionFilePathsAnyHelp =>
      'Soronként egy útvonal, a gyökérkönyvtárhoz képest relatív. Igazra visz, ha bármelyik létezik.';

  @override
  String get conditionFilePathsAllHelp =>
      'Soronként egy útvonal, a gyökérkönyvtárhoz képest relatív. Csak akkor visz igazra, ha mind létezik.';

  @override
  String get conditionBaseKey => 'Gyökérkönyvtár kulcsa';

  @override
  String get conditionBaseKeyHelp =>
      'Állapotkulcs, amely a feloldás alapkönyvtárát tartja (alapértelmezett: repo_local_path).';

  @override
  String get conditionRecursive => 'Alkönyvtárak keresése';

  @override
  String get conditionNegate => 'Fordítás: igazra visz, ha hiányzik';

  @override
  String get conditionLeft => 'Bal érték';

  @override
  String get conditionOperator => 'Operátor';

  @override
  String get conditionRight => 'Jobb érték';

  @override
  String get conditionSwitchKey => 'Kapcsolás állapotkulcsra';

  @override
  String get conditionCases => 'Esetek (vesszővel elválasztva)';

  @override
  String get conditionCasesHelp =>
      'Útvonalkulcsok, amelyeket sorrendben az értékhez illeszt.';

  @override
  String get conditionDefaultCase => 'Alapértelmezett eset';

  @override
  String get triggerManualHelp =>
      'Megjelenítés a futtatási oldalon, és kézi indítás.';

  @override
  String get triggerKindSchedule => 'Ütemezésre';

  @override
  String get triggerScheduleExprLabel => 'Ütemezés (cron vagy every:seconds)';

  @override
  String get triggerTimezoneLabel => 'Időzóna (nem kötelező)';

  @override
  String get triggerCatchUpLabel => 'Elmulasztott futtatásoknál';

  @override
  String get triggerCatchUpRunOnce => 'Egyszer futtatás';

  @override
  String get triggerCatchUpSkip => 'Kihagyás';

  @override
  String get syncHealthTitle => 'Szinkron állapota';

  @override
  String get syncHealthNoConfigs => 'Még nincsenek szinkronkapcsolatok';

  @override
  String get syncHealthNeverSynced => 'Még soha nem szinkronizálva';

  @override
  String get syncOutcomeOk => 'Szinkronizálva';

  @override
  String get syncOutcomeFailed => 'Sikertelen';

  @override
  String get syncOutcomeSkipped => 'Kihagyva';

  @override
  String syncHealthFailedStreak(int count) {
    return '$count egymást követő hiba';
  }

  @override
  String get triggerWebhookHelp =>
      'Aláírt webhook-URL jön létre. Külső rendszerek POST-olnak rá a pipeline indításához.';

  @override
  String get triggerWebhookPathLabel => 'Webhook útvonal';

  @override
  String get triggerMatchStatusLabel => 'Csak ha az állapot';

  @override
  String get triggerSummaryNone => 'Nincsenek triggerek';

  @override
  String triggerEverySeconds(int seconds) {
    return 'Minden $seconds mp';
  }

  @override
  String get triggerEventManual => 'Kézi futtatás';

  @override
  String get triggerEventSchedule => 'Ütemezés';

  @override
  String get triggerEventPrStatusChanged => 'PR állapota változott';

  @override
  String get triggerEventExternalPr => 'Külső PR megnyitva';

  @override
  String get triggerEventPrPublished => 'PR közzétéve';

  @override
  String get triggerEventPrMerged => 'PR összefésülve';

  @override
  String get triggerEventRepoAdded => 'Tároló hozzáadva';

  @override
  String get triggerEventCodeGraphWatch => 'Fájlváltozás';

  @override
  String pipelineRunCauseChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# módosított fájl',
      one: '# módosított fájl',
    );
    return '$_temp0';
  }

  @override
  String pipelineRunCauseMorePaths(int count) {
    return '+$count további';
  }

  @override
  String get pipelineRunCauseRescan => 'Lemezen változott';

  @override
  String get pipelineRunCauseInitial => 'A checkout első indexelése';

  @override
  String get triggerEventMessageReceived => 'Üzenet érkezett';

  @override
  String get triggerEventTicketCompleted => 'Jegy befejezve';

  @override
  String get triggerEventTicketFailed => 'Jegy sikertelen';

  @override
  String get triggerEventTicketCancelled => 'Jegy megszakítva';

  @override
  String get triggerEventBudgetCrossed => 'Költségkeret-küszöb átlépve';

  @override
  String get nodeLibrarySearchHint => 'Csomópontok keresése';

  @override
  String get nodeLibraryNoMatches => 'Nincs illeszkedő csomópont';

  @override
  String get nodeCategoryFlow => 'Folyamat és logika';

  @override
  String get nodeCategoryPr => 'PR-átnézés';

  @override
  String get nodeCategoryAgents => 'Ügynökök';

  @override
  String get nodeCategoryMessaging => 'Üzenetküldés';

  @override
  String get nodeCategoryCode => 'Kód';

  @override
  String get triggerDisabledTag => 'ki';

  @override
  String get pipelineInputTypeRepo => 'Tároló';

  @override
  String get pipelineRunNoRepos =>
      'Még nincsenek tárolók ebben a munkaterületben.';

  @override
  String get allowTicketingApi => 'Jegykezelő API-hívások engedélyezése';

  @override
  String get ticketingApiKey => 'Jegykezelő API-kulcs';

  @override
  String get ticketingApiKeySubtitle =>
      'A jegykezelő szolgáltató API-kulcsát injektálja a homokozóba.';

  @override
  String get ticketingProvider => 'Jegykezelő szolgáltató';

  @override
  String get connectGitHubAndTicketing =>
      'Csatlakoztasson egy kódforgalmazót, hogy a Control Center olvashassa a pull requestjeit, issue-jait és átnézéseit. Opcionálisan csatlakoztasson jegykezelő szolgáltatót. A hitelesítő adatokat a szervere tartja, soha nem ez a gép.';

  @override
  String get triggerEventTicketAssigned => 'Jegy hozzárendelve';

  @override
  String get triggerEventTicketCreated => 'Jegy létrehozva';

  @override
  String get triggerEventTicketStatusChanged => 'Jegy állapota megváltozott';

  @override
  String get triggerEventMeetingRecordingStopped =>
      'Értekezlet-felvétel leállítva';

  @override
  String get triggerEventSkillUpdated => 'Készség frissítve';

  @override
  String get triggerEventSpaceDeleted => 'Tér törölve';

  @override
  String get triggerExternalPrHelp =>
      'Egy pull request, amelyet a kódhoston nyitottak, nem a Control Centerből.';

  @override
  String get triggerPrPublishedHelp =>
      'Egy pull request, amelyet a Control Centerből vagy egy ügynök nyitott.';

  @override
  String get triggerPrStatusChangedHelp =>
      'Összevonva, lezárva, megnyitva, újranyitva vagy jóváhagyva. Szűrd állapot szerint a vizsgálóban.';

  @override
  String get triggerPrMergedHelp =>
      'Csak amikor a pull request összevonásra kerül, nem lezáráskor vagy újranyitáskor.';

  @override
  String get triggerRepoAddedHelp =>
      'Egy tároló kapcsolódik ehhez a munkaterülethez.';

  @override
  String get triggerCodeGraphWatchHelp =>
      'Egy fájl a kapcsolt tárolóban megváltozik a lemezen.';

  @override
  String get triggerMessageReceivedHelp => 'Új üzenet érkezik egy térbe.';

  @override
  String get triggerTicketCreatedHelp =>
      'Jegyet hoznak létre ebben a munkaterületben.';

  @override
  String get triggerTicketStatusChangedHelp =>
      'Egy jegy állapotok között mozog.';

  @override
  String get triggerTicketCompletedHelp => 'Egy jegy sikeresen befejeződik.';

  @override
  String get triggerTicketFailedHelp =>
      'Egy ügynökfutás meghiúsult, és a jegyet sikertelennek jelölik.';

  @override
  String get triggerTicketCancelledHelp =>
      'Egy jegyet törölnek, és nem folytatódik.';

  @override
  String get triggerBudgetCrossedHelp =>
      'Egy munkaterület- vagy ügynökköltési limitet átlépnek.';

  @override
  String get triggerTicketAssignedHelp =>
      'Egy jegyet személyhez, ügynökhöz vagy csapathoz rendelnek.';

  @override
  String get triggerMeetingRecordingStoppedHelp =>
      'Egy megbeszélés felvétele véget ér.';

  @override
  String get triggerSkillUpdatedHelp =>
      'Egy készséget telepítenek vagy frissítenek.';

  @override
  String get triggerSpaceDeletedHelp => 'Egy beszélgetési teret törölnek.';

  @override
  String get navTickets => 'Jegyek';

  @override
  String get ticketsTitle => 'Jegyek';

  @override
  String get newTicket => 'Új jegy';

  @override
  String get noTicketsYet => 'Még nincsenek jegyek';

  @override
  String get addCollaborator => 'Közreműködő hozzáadása';

  @override
  String get noCollaborators => 'Még nincsenek közreműködők';

  @override
  String get linkedPullRequests => 'Összekapcsolt pull requestek';

  @override
  String get noLinkedPullRequests =>
      'Még nincsenek összekapcsolt pull requestek';

  @override
  String get stopAgent => 'Ügynök leállítása';

  @override
  String get ticketProperties => 'Tulajdonságok';

  @override
  String get ticketTabIssue => 'Issue';

  @override
  String get ticketSelectPrompt =>
      'Válasszon jegyet a részletek megtekintéséhez';

  @override
  String get unassigned => 'Nincs hozzárendelve';

  @override
  String get ticketStatusBacklog => 'Backlog';

  @override
  String get ticketStatusOpen => 'Teendő';

  @override
  String get ticketStatusInProgress => 'Folyamatban';

  @override
  String get ticketStatusInReview => 'Átnézés alatt';

  @override
  String get ticketStatusDone => 'Kész';

  @override
  String get ticketStatusBlocked => 'Blokkolva';

  @override
  String get ticketStatusFailed => 'Sikertelen';

  @override
  String get ticketStatusCancelled => 'Megszakítva';

  @override
  String get notificationTicketAssigned => 'Jegy hozzárendelve';

  @override
  String get notificationTicketStatusChanged => 'Jegy állapota változott';

  @override
  String get priority => 'Prioritás';

  @override
  String get status => 'Állapot';

  @override
  String get assignee => 'Hozzárendelt';

  @override
  String get labels => 'Címkék';

  @override
  String get noLabelsYet => 'Még nincsenek címkék';

  @override
  String get clearLabels => 'Címkék törlése';

  @override
  String get pipelineStepAgentActivity => 'Ügynöktevékenység';

  @override
  String get runStatusCompleted => 'Befejezve';

  @override
  String get runStatusQueued => 'Várólistán';

  @override
  String get ticketDescription => 'Leírás';

  @override
  String get ticketPriorityNone => 'Nincs';

  @override
  String get ticketPriorityUrgent => 'Sürgős';

  @override
  String get ticketPriorityHigh => 'Magas';

  @override
  String get ticketPriorityMedium => 'Közepes';

  @override
  String get ticketPriorityLow => 'Alacsony';

  @override
  String get ticketViewList => 'Lista';

  @override
  String get ticketViewBoard => 'Tábla';

  @override
  String get ticketTitlePlaceholder => 'Issue címe';

  @override
  String get ticketDescriptionPlaceholder => 'Leírás hozzáadása…';

  @override
  String get createMore => 'Továbbiak létrehozása';

  @override
  String selectedCount(int count) {
    return '$count kijelölve';
  }

  @override
  String get clearSelection => 'Kijelölés törlése';

  @override
  String get bulkDeleteTitle => 'Jegyek törlése';

  @override
  String bulkDeleteMessage(int count) {
    return 'Törli a $count kijelölt jegyet? Ezt nem lehet visszavonni.';
  }

  @override
  String get assignTo => 'Hozzárendelés…';

  @override
  String get sectionMembers => 'Tagok';

  @override
  String get sectionAgents => 'Ügynökök';

  @override
  String get sidebarGroupWorkspace => 'Munkaterület';

  @override
  String get notificationsTitle => 'Értesítések';

  @override
  String get notificationsTooltip => 'Értesítések';

  @override
  String get notificationsEmpty => 'Minden elolvasva';

  @override
  String notificationsUnreadCount(int count) {
    return '$count olvasatlan';
  }

  @override
  String get notificationsMarkRead => 'Olvasottnak jelölés';

  @override
  String get notificationsMarkUnread => 'Olvasatlannak jelölés';

  @override
  String get notificationsEntryActions => 'Értesítési műveletek';

  @override
  String get markAllRead => 'Mind olvasottnak jelölése';

  @override
  String get teamsNav => 'Csapatok';

  @override
  String get noWorkspace => 'Nincs munkaterület';

  @override
  String get selectWorkspace => 'Munkaterület kiválasztása';

  @override
  String get navMemory => 'Memória';

  @override
  String get memoryTabFacts => 'Tények';

  @override
  String get memoryTabPolicies => 'Szabályzatok';

  @override
  String get memoryGraphShowFacts => 'Tények megjelenítése';

  @override
  String get memoryGraphHideFacts => 'Tények elrejtése';

  @override
  String get memoryGraphExpandAll => 'Minden tény kinyitása';

  @override
  String get memoryGraphCollapseAll => 'Minden tény összecsukása';

  @override
  String get memoryTabGraph => 'Tudásgráf';

  @override
  String get memoryNoWorkspace =>
      'Válasszon munkaterületet a memóriájának megtekintéséhez.';

  @override
  String get searchArticles => 'Cikkek keresése';

  @override
  String get filterAll => 'Mind';

  @override
  String get filterUnread => 'Olvasatlan';

  @override
  String get filterSaved => 'Mentett';

  @override
  String get saveArticle => 'Cikk mentése';

  @override
  String get removeFromSaved => 'Eltávolítás a mentettekből';

  @override
  String get filterBySource => 'Szűrés forrás szerint';

  @override
  String get viewAsList => 'Listanézet';

  @override
  String get viewAsGrid => 'Rácsnézet';

  @override
  String get noMatchingArticles => 'Nincs illeszkedő cikk';

  @override
  String get noMatchingArticlesBody =>
      'Próbáljon más keresést vagy forrásszűrőt.';

  @override
  String get allCaughtUp => 'Minden elolvasva';

  @override
  String get allCaughtUpBody =>
      'Nincsenek olvasatlan cikkek — nézzen vissza később.';

  @override
  String get openArticlesInAppDescription =>
      'Hivatkozások megnyitása a beépített olvasóban az alapértelmezett böngésző helyett.';

  @override
  String get blockAdsTrackersDescription =>
      'Hirdetések, követők és cookie-sávok eltávolítása az olvasóban megnyitott cikkekből.';

  @override
  String get agentQuestionHeader => 'Kérdés Önhöz';

  @override
  String get agentQuestionAnsweredLabel => 'Megválaszolva';

  @override
  String get agentQuestionFreeformHint => 'Írja be a válaszát…';

  @override
  String agentQuestionProgress(int index, int count) {
    return 'Kérdés: $index / $count';
  }

  @override
  String get agentQuestionSkip => 'Kihagyás';

  @override
  String get agentQuestionSkippedLabel => 'Kihagyva';

  @override
  String get agentQuestionFreeformOptionHint => 'Írja le saját szavaival…';

  @override
  String get reviewRequested => 'Átnézést kértek';

  @override
  String get connectGitHubHint =>
      'Jelentkezzen be a GitHubra, vagy adjon hozzá tokent: Beállítások → Munkaterület → Profil és identitás → Kódtárhely';

  @override
  String get connectGitHubToLoadPrs =>
      'Csatlakoztassa a GitHubot a pull requestek betöltéséhez';

  @override
  String get noRepositoriesConfigured => 'Nincsenek beállított tárolók';

  @override
  String openedAgo(String age) {
    return 'Megnyitva $age';
  }

  @override
  String prTimelineOpened(String author) {
    return '$author megnyitotta ezt a pull requestet';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# committal',
      one: '# committal',
    );
    return '$author megnyitotta ezt a pull requestet $_temp0';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return '$actor átnézést kért tőle: $reviewers';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '$actor eltávolította az átnézési kérést ettől: $reviewers';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '$actor átnézést kért tőle: $requested, és eltávolította az átnézési kérést ettől: $removed';
  }

  @override
  String prTimelineAddedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'címkéket',
      one: 'címkét',
    );
    return '$actor hozzáadta a(z) $labels $_temp0';
  }

  @override
  String prTimelineRemovedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'címkéket',
      one: 'címkét',
    );
    return '$actor eltávolította a(z) $labels $_temp0';
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
      other: 'címkéket',
      one: 'címkét',
    );
    String _temp1 = intl.Intl.pluralLogic(
      removedCount,
      locale: localeName,
      other: 'címkéket',
      one: 'címkét',
    );
    return '$actor hozzáadta a(z) $added $_temp0 és eltávolította a(z) $removed $_temp1';
  }

  @override
  String prTimelineCommitted(String author) {
    return '$author commitolt';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# commitot',
      one: '# commitot',
    );
    return '$author küldött $_temp0';
  }

  @override
  String prTimelineApproved(String author) {
    return '$author jóváhagyta ezeket a módosításokat';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return '$author módosítást kért';
  }

  @override
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# kódmegjegyzés',
      one: '# kódmegjegyzés',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '$author átnézte';
  }

  @override
  String get prTimelineSomeone => 'Valaki';

  @override
  String get prTimelineBotBadge => 'bot';

  @override
  String updatedAgo(String age) {
    return 'Frissítve $age';
  }

  @override
  String get checksPassing => 'Ellenőrzések rendben';

  @override
  String get checksRunning => 'Ellenőrzések futnak';

  @override
  String get needsYourReview => 'Az Ön átnézésére van szükség';

  @override
  String get checks => 'Ellenőrzések';

  @override
  String get noReviewersAssigned => 'Nincsenek hozzárendelt átnézők';

  @override
  String get noAssignees => 'Nincsenek hozzárendeltek';

  @override
  String get loadingEllipsis => 'Betöltés…';

  @override
  String get loadingChecks => 'Ellenőrzések betöltése…';

  @override
  String get noChecksYet => 'Még nem futott ellenőrzés';

  @override
  String get noChangesToReview => 'Nincs átnézendő változás';

  @override
  String checksFailingCount(int count) {
    return '$count sikertelen';
  }

  @override
  String get showMore => 'Több megjelenítése';

  @override
  String get showLess => 'Kevesebb megjelenítése';

  @override
  String get backToPullRequests => 'Vissza a pull requestekhez';

  @override
  String get pullRequestNotFound => 'A pull request nem található';

  @override
  String get pullRequestNotFoundBody =>
      'Összefésülhették, lezárhatták vagy áthelyezhették.';

  @override
  String get couldntLoadPullRequest =>
      'Nem sikerült betölteni ezt a pull requestet';

  @override
  String get showDetails => 'Részletek megjelenítése';

  @override
  String get noDescriptionProvided => 'Nincs megadva leírás.';

  @override
  String get factsHint =>
      'A tények itt jelennek meg, ahogy az ügynökei tanulnak.';

  @override
  String get noFactsMatch => 'Nincs a keresésre illeszkedő tény';

  @override
  String get memoryLoadError => 'Nem sikerült betölteni a memóriát';

  @override
  String get sortRecent => 'Legújabb';

  @override
  String get sortConfidence => 'Bizonyosság';

  @override
  String get confidenceTooltip =>
      'Mennyire biztosak az ügynökök abban, hogy ez a tény igaz, 0-tól 100%-ig.';

  @override
  String get supersededTooltip => 'Egy újabb tény felülírta ezt.';

  @override
  String get domain => 'Tartomány';

  @override
  String get fitToView => 'Illesztés a nézethez';

  @override
  String get project => 'Projekt';

  @override
  String get newProject => 'Új projekt';

  @override
  String get editProject => 'Projekt szerkesztése';

  @override
  String get deleteProject => 'Projekt törlése';

  @override
  String get noProject => 'Nincs projekt';

  @override
  String get allTickets => 'Minden jegy';

  @override
  String get projectNamePlaceholder => 'Projekt neve';

  @override
  String get projectDescriptionPlaceholder => 'Leírás (nem kötelező)';

  @override
  String get projectColorLabel => 'Szín';

  @override
  String get noProjectsYet => 'Még nincsenek projektek';

  @override
  String get projectTicketsEmpty => 'Még nincsenek jegyek ebben a projektben';

  @override
  String get createProject => 'Projekt létrehozása';

  @override
  String projectProgress(int done, int total) {
    return '$done / $total kész';
  }

  @override
  String deleteProjectConfirm(String name) {
    return 'Törli a(z) „$name” projektet? A jegyei megmaradnak, és kikerülnek a projektből.';
  }

  @override
  String get projectStatusActive => 'Aktív';

  @override
  String get projectStatusCompleted => 'Befejezve';

  @override
  String get projectStatusArchived => 'Archiválva';

  @override
  String get markProjectCompleted => 'Befejezettnek jelölés';

  @override
  String get markProjectActive => 'Aktívnak jelölés';

  @override
  String get archiveProject => 'Archiválás';

  @override
  String get restoreProject => 'Visszaállítás';

  @override
  String get relations => 'Kapcsolatok';

  @override
  String get relateTo => 'Kapcsolás';

  @override
  String get relationSubIssueOf => 'Alissue-ja…';

  @override
  String get relationParentOf => 'Szülője…';

  @override
  String get relationBlockedBy => 'Blokkolja…';

  @override
  String get relationBlocking => 'Blokkol…';

  @override
  String get relationRelatedTo => 'Kapcsolódik…';

  @override
  String get relationDuplicateOf => 'Duplikátuma…';

  @override
  String get relationGroupParent => 'Szülő';

  @override
  String get relationGroupSubIssues => 'Alissue-k';

  @override
  String get relationGroupBlockedBy => 'Blokkolja';

  @override
  String get relationGroupBlocking => 'Blokkol';

  @override
  String get relationGroupRelated => 'Kapcsolódó';

  @override
  String get relationGroupDuplicateOf => 'Duplikátuma';

  @override
  String get relationGroupDuplicatedBy => 'Duplikálja';

  @override
  String get copyId => 'ID másolása';

  @override
  String get ticketIdCopied => 'Jegy-ID másolva';

  @override
  String get searchTicketsHint => 'Jegyek keresése…';

  @override
  String get noMatchingTickets => 'Nincs illeszkedő jegy';

  @override
  String get clearAll => 'Mind törlése';

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '# PR',
      one: '# PR',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '# tárolóban',
      one: '# tárolóban',
    );
    return '$_temp0 vár az átnézésére $_temp1';
  }

  @override
  String get manageWorkspacesSubtitle =>
      'Nevezzen át egy munkaterületet, és módosítsa a jelét — válasszon egyet a bal oldalon a szerkesztéshez.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# munkaterület',
      one: '# munkaterület',
      zero: 'Nincsenek munkaterületek',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '# tároló',
      one: '# tároló',
      zero: 'Nincsenek tárolók',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '# ügynök',
      one: '# ügynök',
      zero: '0 ügynök',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'Identitás';

  @override
  String get uploadImage => 'Kép feltöltése';

  @override
  String get failedToSaveLogo =>
      'Nem sikerült menteni a logóképet. Győződjön meg róla, hogy az alkalmazás olvashatja a kijelölt fájlt.';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG vagy GIF, legfeljebb 2 MB. Egyébként a munkaterület kezdőbetűjét használjuk.';

  @override
  String get workspaceNameFieldHelp =>
      'A váltóban, a morzsában és minden képernyőn megjelenik.';

  @override
  String get dangerZone => 'Veszélyzóna';

  @override
  String get deleteThisWorkspace => 'Munkaterület törlése';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return 'Véglegesen eltávolítja a(z) $name munkaterületet, a tárolókapcsolatait, ügynökeit és memóriáját. Ezt nem lehet visszavonni.';
  }

  @override
  String get discard => 'Elvetés';

  @override
  String discardChangesQuestion(String name) {
    return 'Elveti a(z) $name mentetlen módosításait?';
  }

  @override
  String get workspaceUpdated => 'Munkaterület frissítve';

  @override
  String get editTitle => 'Cím szerkesztése';

  @override
  String get editDescription => 'Leírás szerkesztése';

  @override
  String get addDescription => 'Leírás hozzáadása';

  @override
  String get prTitlePlaceholder => 'Cím';

  @override
  String get prBodyPlaceholder => 'Hagyjon leírást';

  @override
  String get write => 'Írás';

  @override
  String get overview => 'Áttekintés';

  @override
  String get noFilesChanged => 'Nincs módosított fájl';

  @override
  String get diff => 'Diff';

  @override
  String get preview => 'Előnézet';

  @override
  String get imageDiffBefore => 'Előtte';

  @override
  String get imageDiffAfter => 'Utána';

  @override
  String get imageDiffModeTwoUp => 'Kétoszlopos';

  @override
  String get imageDiffModeSwipe => 'Csúsztatás';

  @override
  String get imageDiffModeDifference => 'Eltérés';

  @override
  String imageDiffChangedPercent(String percent) {
    return '$percent% változott';
  }

  @override
  String get imageDiffPictures => 'Képek';

  @override
  String get imageDiffSource => 'Forrás';

  @override
  String get imageDiffDeleted => 'Törölve';

  @override
  String get imageDiffAdded => 'Hozzáadva';

  @override
  String imageDiffDimensions(int width, int height) {
    return 'Sz: ${width}px | M: ${height}px';
  }

  @override
  String get outdated => 'Elavult';

  @override
  String get outdatedComments => 'Elavult megjegyzések';

  @override
  String outdatedCountLabel(int count) {
    return '$count elavult';
  }

  @override
  String get prTemplateLabel => 'Sablon';

  @override
  String get prTemplateDefault => 'Alapértelmezett';

  @override
  String get addReviewers => 'Átnézők hozzáadása';

  @override
  String get addAssignees => 'Hozzárendeltek hozzáadása';

  @override
  String get searchUsers => 'Emberek keresése…';

  @override
  String get searchReviewers => 'Emberek és csapatok keresése…';

  @override
  String get usersSectionLabel => 'Emberek';

  @override
  String get userStatusBusy => 'Elfoglalt';

  @override
  String get teamsSectionLabel => 'Csapatok';

  @override
  String get suggestedReviewers => 'Javasolt átnézők';

  @override
  String get noMatchingUsers => 'Nincs illeszkedő ember';

  @override
  String get noMatchingReviewers => 'Nincs találat';

  @override
  String get requiredByCodeOwners => 'A code ownerek megkövetelik';

  @override
  String reviewedOnBehalfOf(String login) {
    return '$login nevében';
  }

  @override
  String get team => 'Csapat';

  @override
  String get markdownBold => 'Félkövér';

  @override
  String get markdownItalic => 'Dőlt';

  @override
  String get markdownHeading => 'Címsor';

  @override
  String get markdownBulletList => 'Felsorolás';

  @override
  String get markdownChecklist => 'Ellenőrzőlista';

  @override
  String get markdownCode => 'Kód';

  @override
  String get markdownLink => 'Hivatkozás';

  @override
  String get markdownQuote => 'Idézet';

  @override
  String get markdownSupported => 'A Markdown támogatott';

  @override
  String get markdownAttachImages => 'Kattintson képek hozzáadásához';

  @override
  String failedToUpdateTitle(String error) {
    return 'Nem sikerült frissíteni a címet: $error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'Nem sikerült frissíteni a leírást: $error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'Nem sikerült frissíteni az átnézőket: $error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'Nem sikerült frissíteni a hozzárendelteket: $error';
  }

  @override
  String get discardChangesConfirm => 'Elveti a módosításait?';

  @override
  String get newPr => 'Új PR';

  @override
  String get openPullRequest => 'Pull request megnyitása';

  @override
  String get composePrSubtitle =>
      'Egy már küldött ágról — ügynökök vagy jegyek nélkül';

  @override
  String get createAsDraft => 'Létrehozás piszkozatként';

  @override
  String get composePrNoRepo => 'Nincs kiválasztott GitHub-tároló';

  @override
  String get composePrNoRepoHint =>
      'Válasszon GitHubhoz kapcsolt tárolóval rendelkező munkaterületet a pull request megnyitásához.';

  @override
  String get composePrPickBranches =>
      'Válasszon alap- és összehasonlító ágat a módosítások előnézetéhez.';

  @override
  String get composePrNothingToCompare =>
      'Nincs különbség ezek között az ágak között.';

  @override
  String get repository => 'Tároló';

  @override
  String get baseBranchLabel => 'Alap';

  @override
  String get compareBranchLabel => 'Összehasonlítás';

  @override
  String get selectBranch => 'Ág kiválasztása';

  @override
  String get navMeetings => 'Megbeszélések';

  @override
  String get meetingsNoWorkspace =>
      'Válasszon munkaterületet a megbeszélések megtekintéséhez.';

  @override
  String get meetingsEmpty => 'Még nincsenek megbeszélések';

  @override
  String get meetingsEmptyHint =>
      'Vegye fel az első megbeszélését — a hang ezen az eszközön marad, és az ügynök jegyzetekké, döntésekké és teendőkké alakítja.';

  @override
  String get meetingNotesHint =>
      'Vessen fel gyors jegyzeteket — az ügynök a megbeszélés után kibővíti őket.';

  @override
  String get meetingSpeakerMe => 'Ön';

  @override
  String get meetingStatusRecording => 'Felvétel';

  @override
  String get meetingStatusProcessing => 'Feldolgozás';

  @override
  String get meetingStatusDone => 'Kész';

  @override
  String get meetingStatusFailed => 'Sikertelen';

  @override
  String get meetingsSubtitle =>
      'Ezen az eszközön rögzítve és átírva, majd egy ügynök összefoglalja.';

  @override
  String get meetingsRecordMeeting => 'Megbeszélés felvétele';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# feldolgozás alatt',
      one: '# feldolgozás alatt',
    );
    return '$_temp0';
  }

  @override
  String meetingsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# megbeszélés',
      one: '# megbeszélés',
      zero: 'Nincsenek megbeszélések',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLedgerOpenActions => 'Nyitott teendők';

  @override
  String get meetingsLedgerDecisions => 'Döntések';

  @override
  String get meetingsLiveOpen => 'Felvétel megnyitása';

  @override
  String get meetingTemplateShort => 'Sablon';

  @override
  String get meetingsStatThisWeek => 'Ez a hét';

  @override
  String get meetingsStatRecorded => 'Rögzítve';

  @override
  String get meetingsFilterAll => 'Mind';

  @override
  String get meetingsFilterDone => 'Kész';

  @override
  String get meetingsFilterProcessing => 'Feldolgozás';

  @override
  String get meetingsSearchHint => 'Szűrés cím, személy, alkalmazás szerint…';

  @override
  String get meetingsBucketToday => 'Ma';

  @override
  String get meetingsBucketYesterday => 'Tegnap';

  @override
  String get meetingsBucketEarlierThisWeek => 'A hét korábbi része';

  @override
  String get meetingsBucketLastWeek => 'Múlt hét';

  @override
  String get meetingsBucketOlder => 'Régebbi';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# döntés',
      one: '# döntés',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total teendő';
  }

  @override
  String get meetingsEnhancedPill => 'bővített';

  @override
  String get meetingsTranscribing => 'átírás és összefoglalás…';

  @override
  String get meetingsOpenAction => 'Megnyitás';

  @override
  String get meetingsStopProcessing => 'Leállítás';

  @override
  String get meetingsStillTranscribing =>
      'Még átírás alatt — az összefoglaló a befejezéskor jelenik meg.';

  @override
  String get meetingsNoMatch => 'Nincs illeszkedő megbeszélés';

  @override
  String get meetingsNoMatchHint =>
      'Próbáljon más szűrőt vagy keresőkifejezést.';

  @override
  String get meetingBackAllMeetings => 'Minden megbeszélés';

  @override
  String get meetingReRunSummary => 'Összefoglaló újrafuttatása';

  @override
  String get meetingExport => 'Exportálás';

  @override
  String get meetingAugmentingBanner =>
      'Jegyzeteinek bővítése az átiratból — döntések és teendők kinyerése…';

  @override
  String get meetingTabNotes => 'Jegyzetek';

  @override
  String get meetingTabTranscript => 'Átirat';

  @override
  String get meetingTabActionItems => 'Teendők';

  @override
  String get meetingTabDecisions => 'Döntések';

  @override
  String get meetingNotesEnhancedToggle => 'Bővített';

  @override
  String get meetingNotesYoursToggle => 'Az Ön jegyzetei';

  @override
  String get meetingEnhancedByAgent => 'Ügynök által bővítve · átiratból';

  @override
  String get meetingEnhancedPending =>
      'Az ügynök még dolgozik ezen az összefoglalón.';

  @override
  String get meetingNotesEmpty => 'Még nincsenek bővített jegyzetek.';

  @override
  String get meetingNotesSavedLocally => 'Helyben mentve';

  @override
  String get meetingNotesSaving => 'Mentés…';

  @override
  String get meetingViewFullTranscript => 'Teljes átirat megtekintése';

  @override
  String get meetingTranscriptSearchHint => 'Keresés az átiratban…';

  @override
  String get meetingSpeakerEveryone => 'Mindenki';

  @override
  String get meetingSpeakerOthers => 'Mások';

  @override
  String get meetingTranscriptEmpty => 'Még nincs átirat.';

  @override
  String get meetingActionItemsEmpty => 'Nem lettek kinyerve teendők.';

  @override
  String get meetingActionItemFrom => 'ebből a megbeszélésből';

  @override
  String get meetingCreateTicket => 'Jegy létrehozása';

  @override
  String meetingTicketCreated(String key) {
    return 'A(z) $key jegy létrehozva és kiosztva.';
  }

  @override
  String get meetingTicketFailed => 'Nem sikerült létrehozni a jegyet.';

  @override
  String get meetingDecisionsEmpty => 'Nincsenek rögzített döntések.';

  @override
  String get meetingEditTitle => 'Cím szerkesztése';

  @override
  String get meetingTitleLabel => 'Cím';

  @override
  String get meetingAddActionItem => 'Teendő hozzáadása';

  @override
  String get meetingEditActionItem => 'Teendő szerkesztése';

  @override
  String get meetingDeleteActionItem => 'Teendő törlése';

  @override
  String get meetingActionItemContentLabel => 'Teendő';

  @override
  String get meetingActionItemContentHint => 'Mit kell tenni?';

  @override
  String get meetingActionItemOwnerLabel => 'Tulajdonos';

  @override
  String get meetingActionItemOwnerHint => 'Ki a felelős? (nem kötelező)';

  @override
  String get meetingAddDecision => 'Döntés hozzáadása';

  @override
  String get meetingEditDecision => 'Döntés szerkesztése';

  @override
  String get meetingDeleteDecision => 'Döntés törlése';

  @override
  String get meetingDecisionContentLabel => 'Döntés';

  @override
  String get meetingDecisionContentHint => 'Mit döntöttek?';

  @override
  String get meetingReRunStarted =>
      'Az összefoglaló újrafuttatása az átiraton…';

  @override
  String get meetingReRunNoTranscript =>
      'Még nincs átirat, amit összefoglalhatnánk.';

  @override
  String get meetingExportCopied =>
      'Jegyzetek a vágólapra másolva Markdownként.';

  @override
  String get meetingExportSaved => 'Megbeszélés exportálva.';

  @override
  String meetingExportFailed(String error) {
    return 'Az exportálás sikertelen: $error';
  }

  @override
  String get meetingExportNothing => 'Még nincs mit exportálni.';

  @override
  String get meetingPlaybackPlay => 'Lejátszás';

  @override
  String get meetingPlaybackPause => 'Szünet';

  @override
  String get meetingPlaybackUnavailable =>
      'A hanglejátszás nem érhető el ezen az eszközön.';

  @override
  String get meetingDetectedTitle => 'Megbeszélés észlelve';

  @override
  String meetingDetectedSubtitle(String label) {
    return 'Úgy tűnik, a(z) „$label” folyamatban van. Felvegye?';
  }

  @override
  String get meetingDetectedSubtitleGeneric =>
      'Úgy tűnik, megbeszélés van folyamatban. Felvegye?';

  @override
  String get meetingDetectedRecord => 'Felvétel';

  @override
  String get meetingDetectedDismiss => 'Elvetés';

  @override
  String get meetingAutoStopTitle =>
      'Ez a megbeszélés véget értnek tűnik. Leállítja a felvételt?';

  @override
  String get meetingAutoStopStop => 'Leállítás';

  @override
  String get meetingAutoStopKeep => 'Felvétel folytatása';

  @override
  String get meetingAutoDetect => 'Megbeszélések automatikus észlelése';

  @override
  String get meetingAutoDetectDescription =>
      'Figyeli a naptárt és a konferenciaalkalmazásokat, és felajánlja a felvételt, amikor egy megbeszélés kezdődik.';

  @override
  String get meetingsRecordingCrumb => 'Felvétel…';

  @override
  String get meetingRecordTitleHint => 'Megbeszélés címe';

  @override
  String get meetingRecordTappingLabel => 'Rögzítés:';

  @override
  String get meetingRecordMic => 'Mikrofon';

  @override
  String get meetingRecordSystemAudio => 'Rendszerhang';

  @override
  String get meetingRecordPause => 'Szünet';

  @override
  String get meetingRecordResume => 'Folytatás';

  @override
  String get meetingRecordStop => 'Leállítás és összefoglalás';

  @override
  String get meetingRecordYourNotes => 'Az Ön jegyzetei';

  @override
  String get meetingRecordNotesPlaceholder =>
      'Gépeljen, amíg hallgat. Néhány töredék elég — a leállítás után az ügynök kibővíti őket az átiratból.';

  @override
  String get meetingRecordLiveTranscript => 'Élő átirat';

  @override
  String get meetingRecordDecoding => 'helyi dekódolás';

  @override
  String get meetingRecordListening =>
      'Figyelés… a beszéd egy-két másodpercen belül itt jelenik meg, Ön / Mások címkével.';

  @override
  String get meetingRecordPausedHint =>
      'Szüneteltetve — a hangot figyelmen kívül hagyjuk a folytatásig.';

  @override
  String get meetingRecordNotActive => 'Nincs aktív felvétel.';

  @override
  String get meetingHudRecording => 'felvétel';

  @override
  String get meetingHudPaused => 'szüneteltetve';

  @override
  String get meetingHudOpen => 'Megnyitás';

  @override
  String get meetingHudStop => 'Leállítás';

  @override
  String get meetingToolbarPopOut => 'Kiemelés';

  @override
  String get meetingToolbarHoldToStop => 'Nyomva tartva leállítja a felvételt';

  @override
  String get meetingToolbarSemanticLabel => 'Megbeszélésfelvétel eszköztár';

  @override
  String get orchestrate => 'Orchestrálás';

  @override
  String get orchestrationUnavailable => 'Az orchestráció nem elérhető';

  @override
  String get orchestrationApprove => 'Terv jóváhagyása';

  @override
  String get orchestrationReject => 'Elutasítás';

  @override
  String get orchestrationCancel => 'Orchestráció megszakítása';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count szerep — $hires új felvétel';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count aljegy';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'Becsült költség: \$$amount';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total aljegy kész';
  }

  @override
  String get orchestrationStatusProposed => 'Javasolt';

  @override
  String get orchestrationStatusApproved => 'Jóváhagyva';

  @override
  String get orchestrationStatusExecuting => 'Végrehajtás';

  @override
  String get orchestrationStatusSynthesizing => 'Összegzés';

  @override
  String get orchestrationStatusCompleted => 'Befejezve';

  @override
  String get orchestrationStatusFailed => 'Sikertelen';

  @override
  String get orchestrationStatusCancelled => 'Megszakítva';

  @override
  String get messageFailed => 'A futtatás sikertelen';

  @override
  String get turnLimitReached =>
      'Megállt a körkorlátnál — válaszoljon a folytatáshoz';

  @override
  String get retried => 'Újrapróbálva';

  @override
  String replyingTo(String name) {
    return 'válasz neki: $name';
  }

  @override
  String get silenceTimeoutLabel => 'Csend időtúllépés (perc)';

  @override
  String get silenceTimeoutHint =>
      'pl. 15 — futtatás leállítása ennyi ideig tartó kimenet nélkül';

  @override
  String get capabilityJsonMode => 'JSON mód';

  @override
  String get capabilityModelSelection => 'Modellválasztás';

  @override
  String get transcriptThinking => 'Gondolkodás…';

  @override
  String transcriptThoughtFor(String duration) {
    return 'Gondolkodott $duration';
  }

  @override
  String get transcriptStatusMakingEdits => 'Szerkesztés…';

  @override
  String get transcriptStatusReadingFiles => 'Fájlok olvasása…';

  @override
  String get transcriptStatusSearching => 'Kódbázis keresése…';

  @override
  String get transcriptStatusRunningCommands => 'Parancsok futtatása…';

  @override
  String get transcriptStatusResponding => 'Válaszolás…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return '$tool futtatása…';
  }

  @override
  String get transcriptInput => 'Bemenet';

  @override
  String get transcriptOutput => 'Kimenet';

  @override
  String get transcriptErrorLabel => 'Hiba';

  @override
  String get transcriptSandboxBlocked => 'A homokozó blokkolt egy műveletet';

  @override
  String transcriptShowFullOutput(int kb) {
    return 'Teljes kimenet megjelenítése (+$kb KB)';
  }

  @override
  String transcriptShowAllLines(int count) {
    return 'Mind a $count sor megjelenítése';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return 'Az első $count sor';
  }

  @override
  String get transcriptGrepNoMatches => 'Nincs találat';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '# találat',
      one: '# találat',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '# fájl',
      one: '# fájl',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return '$number. személy';
  }

  @override
  String get meetingRenameSpeakerTooltip => 'Beszélő átnevezése';

  @override
  String get meetingRenameSpeakerTitle => 'Beszélő átnevezése';

  @override
  String get meetingSpeakerNameLabel => 'Név';

  @override
  String get meetingSpeakerSuggestFromCalendar =>
      'A megbeszélés meghívottaiból';

  @override
  String get meetingRenameSpeakerApplyAll =>
      'Alkalmazás ennek a beszélőnek minden blokkjára';

  @override
  String get meetingRenameSpeakerScopeHint =>
      'Ha ki van kapcsolva, csak a kijelölt sor kerül átnevezésre.';

  @override
  String get meetingLinkEvent => 'Eseményhez kapcsolás';

  @override
  String get meetingChangeEvent => 'Esemény módosítása';

  @override
  String get meetingLinkEventTitle => 'Naptáreseményhez kapcsolás';

  @override
  String get meetingLinkEventSearchHint => 'Események keresése';

  @override
  String get meetingLinkEventEmpty => 'Nincsenek közeli naptáresemények';

  @override
  String get meetingUnlinkEvent => 'Kapcsolat eltávolítása';

  @override
  String get calendarLinkExistingMeeting => 'Meglévő megbeszéléshez kapcsolás';

  @override
  String get calendarLinkMeetingTitle => 'Megbeszélés kapcsolása';

  @override
  String get calendarLinkMeetingSearchHint => 'Megbeszélések keresése';

  @override
  String get calendarLinkMeetingEmpty => 'Nincs kapcsolható megbeszélés';

  @override
  String get meetingRenameSpeakerFailed => 'Nem sikerült átnevezni a beszélőt';

  @override
  String get calendarLinkUpdateFailed =>
      'Nem sikerült frissíteni a naptárkapcsolatot';

  @override
  String get rename => 'Átnevezés';

  @override
  String get notNow => 'Most nem';

  @override
  String get meetingSaveVoiceProfileTitle => 'Hangprofil mentése?';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return 'Ismerje fel automatikusan $name hangját a jövőbeli megbeszéléseken a hanglenyomat mentésével.';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return 'Hangprofil mentve: $name';
  }

  @override
  String get meetingVoiceProfileSaveFailed =>
      'Nem sikerült menteni a hangprofilt';

  @override
  String get voiceProfilesSection => 'Hangprofilok';

  @override
  String get voiceProfilesDescription =>
      'A mentett hangokat a jövőbeli megbeszéléseken automatikusan felismerik.';

  @override
  String get voiceProfilesEmpty =>
      'Még nincsenek mentett hangok. Nevezzen meg egy beszélőt egy megbeszélés-átiratban, majd válassza a „Hangprofil mentése” lehetőséget.';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# minta',
      one: '# minta',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => 'Hangprofil átnevezése';

  @override
  String get deleteVoiceProfileTitle => 'Törli a hangprofilt?';

  @override
  String deleteVoiceProfileBody(String name) {
    return 'Leállítja $name felismerését? A mentett hanglenyomata törlődik. A korábbi megbeszéléseken már alkalmazott nevek megmaradnak.';
  }

  @override
  String get connectedLabel => 'Csatlakoztatva';

  @override
  String get ideTabGeneral => 'Általános';

  @override
  String get ideTabExplorer => 'Böngésző';

  @override
  String get ideTabSourceControl => 'Verziókezelés';

  @override
  String get generalSectionTodos => 'Teendők';

  @override
  String get generalSectionGoals => 'Célok';

  @override
  String get goalRunStatusActive => 'Aktív';

  @override
  String get goalRunStatusPaused => 'Szüneteltetve';

  @override
  String get goalRunStatusCompleted => 'Befejezve';

  @override
  String get goalRunStatusFailed => 'Sikertelen';

  @override
  String get goalRunStatusCancelled => 'Megszakítva';

  @override
  String get goalRunStatusBudgetExhausted => 'Költségkeret kimerítve';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return '$run. / $max futtatás · $cost / $cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return '$run. futtatás · $cost / $cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return 'Határidő: $deadline';
  }

  @override
  String get goalRunPause => 'Cél szüneteltetése';

  @override
  String get goalRunResume => 'Cél folytatása';

  @override
  String goalRunResumeRaise(String cap) {
    return 'Folytatás · keret emelése $cap értékre';
  }

  @override
  String get goalRunStop => 'Cél leállítása';

  @override
  String get generalSectionAgents => 'Ügynökök';

  @override
  String get generalSectionTerminals => 'Terminálok';

  @override
  String get generalTodosEmpty => 'Még nincsenek teendők';

  @override
  String get generalAgentsEmpty => 'Nincsenek futó ügynökök';

  @override
  String get generalTerminalsEmpty => 'Nincsenek nyitott terminálok';

  @override
  String get generalSectionBrowsers => 'Böngészők';

  @override
  String get generalSectionComputers => 'Számítógépek';

  @override
  String get generalBrowsersEmpty => 'Nincsenek nyitott böngészők';

  @override
  String get generalComputersEmpty => 'Nincsenek nyitott számítógépek';

  @override
  String get generalSectionPhones => 'Telefonok';

  @override
  String get generalPhonesEmpty => 'Nincsenek nyitott telefonok';

  @override
  String get pauseAgent => 'Ügynök szüneteltetése';

  @override
  String get resumeAgent => 'Ügynök folytatása';

  @override
  String get agentCannotPause =>
      'Ez az ügynök nem szüneteltethető — állítsa le helyette.';

  @override
  String get goalClear => 'Cél törlése';

  @override
  String get undoLabelGoalClear => 'cél törlése';

  @override
  String get todoStatusPending => 'Nincs elkezdve';

  @override
  String get todoStatusInProgress => 'Folyamatban';

  @override
  String get todoStatusCompleted => 'Kész';

  @override
  String get reorderTodo => 'Teendő átrendezése';

  @override
  String get focusTerminal => 'Terminál fókusza';

  @override
  String get focusMachine => 'Gép fókusza';

  @override
  String get focusBrowser => 'Böngésző fókusza';

  @override
  String get todoEditorTitle => 'Teendők szerkesztése';

  @override
  String get todoEditorHint =>
      'Soronként egy tétel. Használja: - [ ] függőben, - [~] folyamatban, - [x] kész.';

  @override
  String get todoNeedsText => 'Adjon szöveget a parancs után';

  @override
  String get todoNotFound => 'Nincs illeszkedő teendő';

  @override
  String get todoCleared => 'A teendőlista törölve';

  @override
  String get todoNothingToCopy => 'Nincs mit másolni';

  @override
  String todoAdded(String content) {
    return 'Hozzáadva: „$content”';
  }

  @override
  String todoStarted(String content) {
    return 'Elkezdve: „$content”';
  }

  @override
  String todoCompleted(String content) {
    return 'Befejezve: „$content”';
  }

  @override
  String todoRemoved(String content) {
    return 'Eltávolítva: „$content”';
  }

  @override
  String todoCopied(int count) {
    return '$count tétel másolva';
  }

  @override
  String todoImported(int count) {
    return '$count tétel importálva';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return 'Ismeretlen teendőparancs: „$name”';
  }

  @override
  String get terminal => 'Terminál';

  @override
  String get ideCloseTab => 'Lap bezárása';

  @override
  String get ideSplitEditor => 'Szerkesztő osztása';

  @override
  String get ideSplitRight => 'Osztás jobbra';

  @override
  String get ideSplitDown => 'Osztás lefelé';

  @override
  String get ideSplitLeft => 'Osztás balra';

  @override
  String get ideSplitUp => 'Osztás felfelé';

  @override
  String get ideCloseGroup => 'Csoport bezárása';

  @override
  String get ideCloseOthers => 'Többi bezárása';

  @override
  String get ideCloseToRight => 'Jobbra lévők bezárása';

  @override
  String get ideCloseSaved => 'Mentettek bezárása';

  @override
  String get ideCloseAll => 'Mind bezárása';

  @override
  String get ideSplit => 'Osztás';

  @override
  String get ideToggleSidebar => 'Oldalsáv váltása';

  @override
  String get ideNewTab => 'Szerkesztő megnyitása';

  @override
  String get ideNewTabMenu => 'Új lap';

  @override
  String get ideReviewCode => 'Kód átnézése';

  @override
  String get ideRevertConfirmTitle => 'Módosítások visszavonása';

  @override
  String get ideRevertUntracked => 'A nem követett fájlok nem vonhatók vissza';

  @override
  String get ideRevertFailed =>
      'Nem sikerült visszaállítani a fájlokat. A beszélgetés worktree-je lehet, hogy nem elérhető.';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# fájlt',
      one: '# fájlt',
    );
    return '$_temp0 nem sikerült visszaállítani (nem követett).';
  }

  @override
  String get ideSearchMatchCase => 'Kis- és nagybetű';

  @override
  String get ideSearchWholeWord => 'Teljes szó';

  @override
  String get ideSearchRegex => 'Regex';

  @override
  String get ideSearchFilters => 'Keresési szűrők';

  @override
  String get ideSearchFilesToInclude => 'Bevonandó fájlok';

  @override
  String get ideSearchFilesToExclude => 'Kizárandó fájlok';

  @override
  String get ideNoOpenTabs =>
      'Nincsenek nyitott lapok — használja a + jelet a megnyitáshoz';

  @override
  String get ideBrowserAddressHint => 'Cím vagy keresés';

  @override
  String get ideSimpleWebBrowser => 'Egyszerű webböngésző';

  @override
  String get ideWebBrowser => 'Webböngésző';

  @override
  String get ideBrowserEnterUrl =>
      'Adjon meg egy URL-t a címsorban a böngészés megkezdéséhez';

  @override
  String get ideCodeServer => 'Szerkesztő';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return 'Menti a(z) $fileName módosításait?';
  }

  @override
  String get ideUnsavedChangesBody =>
      'A módosítások elvesznek, ha nem menti őket.';

  @override
  String get ideDontSave => 'Ne mentse';

  @override
  String get editorAutoSave => 'Automatikus mentés';

  @override
  String get editorAutoSaveDescription =>
      'A beágyazott szerkesztő módosításainak automatikus mentése.';

  @override
  String get editorAutoSaveOff => 'Ki';

  @override
  String get editorAutoSaveAfterDelay => 'Késleltetés után';

  @override
  String get editorAutoSaveOnFocusChange => 'Fókuszváltáskor';

  @override
  String get ideCodeServerUnavailable =>
      'A code-server nem érhető el ezen a szerveren';

  @override
  String get ideCodeServerUnavailableHint =>
      'Telepítse a code-servert (coder/code-server) a szervergépen, majd nyissa újra a szerkesztőt.';

  @override
  String get ideCodeServerInstalling => 'Szerkesztő előkészítése…';

  @override
  String get ideCodeServerOpenInBrowser => 'Szerkesztő megnyitása böngészőben';

  @override
  String get ideCodeServerError => 'Nem sikerült megnyitni a szerkesztőt';

  @override
  String get paneSuspendedCaption =>
      'Felfüggesztve az erőforrások kíméléséhez — fókuszáláskor újratöltődik';

  @override
  String get ideFolderLoadFailed => 'Nem sikerült betölteni ezt a mappát';

  @override
  String get ideFileSearchFailed => 'Nem sikerült fájlokat keresni';

  @override
  String get ideSearchInFiles => 'Keresés a fájlokban';

  @override
  String get ideNoContentMatches => 'Nincs találat';

  @override
  String get ideSourceControlCreatePr => 'Pull request létrehozása';

  @override
  String ideSourceControlViewPr(int number) {
    return '#$number pull request megtekintése';
  }

  @override
  String get ideSourceControlNoChanges => 'Nincsenek módosítások';

  @override
  String get noReposInConversation =>
      'Nincsenek tárolók ebben a beszélgetésben';

  @override
  String get ideSourceControlNoSpace =>
      'Nyisson beszélgetést a módosításainak megtekintéséhez';

  @override
  String get ideFileLoading => 'Betöltés…';

  @override
  String get ideFileBinary => 'Bináris fájl';

  @override
  String get mcpExternalServers => 'Külső MCP-szerverek';

  @override
  String get mcpExternalServersDescription =>
      'Csatlakozzon külső MCP-szerverekhez (GitHub, Sentry, Postgres, böngészőautomatizálás). A Claude, Cursor, VS Code és más eszközökhöz beállított szerverek automatikusan felismerésre kerülnek.';

  @override
  String get mcpApprovalMode => 'Eszközjóváhagyás';

  @override
  String get mcpApprovalModeDescription =>
      'Mely eszközműveletek futnak kérdés nélkül. Az olvasás mindig engedélyezett; a magasabb szintek rákérdeznek.';

  @override
  String get mcpApprovalAlwaysAsk => 'Mindig kérdezzen';

  @override
  String get mcpApprovalWrite => 'Írások automatikus jóváhagyása';

  @override
  String get mcpApprovalYolo => 'Minden automatikus jóváhagyása';

  @override
  String get mcpNoExternalServers => 'Nem találhatók külső MCP-szerverek.';

  @override
  String get mcpAuthorize => 'Felhatalmazás';

  @override
  String get mcpReconnect => 'Újracsatlakozás';

  @override
  String get mcpExternalConnectionsNote =>
      'A külső MCP-szerverek az ügynökszerveren futnak (asztali és web megosztja). Az OAuth-szerverek felhatalmazása csak asztalon érhető el.';

  @override
  String get mcpStatusConnected => 'Csatlakoztatva';

  @override
  String get mcpStatusConnecting => 'Csatlakozás…';

  @override
  String get mcpStatusNeedsAuth => 'Felhatalmazás szükséges';

  @override
  String get mcpStatusFailed => 'Sikertelen';

  @override
  String get mcpStatusCircuitOpen => 'Szüneteltetve';

  @override
  String get mcpStatusDisabled => 'Letiltva';

  @override
  String get providersAndModels => 'Szolgáltatók és modellek';

  @override
  String get providersAndModelsDescription =>
      'Listázza a beépített ügynök minden szolgáltatóját — állítson be API-kulcsot, vagy jelentkezzen be a böngészőjével, tekintse meg a csatlakoztatott szolgáltatók modelljeit és árait, és szabályozza, mely szolgáltatókat használhatja ez a munkaterület.';

  @override
  String get syncNow => 'Szinkronizálás most';

  @override
  String syncNowResult(int applied, int failed) {
    return 'Szinkron kész — $applied alkalmazva, $failed sikertelen';
  }

  @override
  String syncNowFailed(String error) {
    return 'A szinkron sikertelen: $error';
  }

  @override
  String get denied => 'Tiltva';

  @override
  String get allowed => 'Engedélyezve';

  @override
  String allowProviderSemantic(String provider) {
    return '$provider engedélyezése';
  }

  @override
  String enabledViaEnv(String key) {
    return 'Engedélyezve $key révén';
  }

  @override
  String costPerMillion(String input, String output) {
    return '$input / $output 1M-ként';
  }

  @override
  String contextTokens(String tokens) {
    return '$tokens kontextus';
  }

  @override
  String get usageAndCost => 'Használat és költség';

  @override
  String get usageAndCostDescription =>
      'Az ügynökei költése az elmúlt 7 napban, a megfigyelt futtatási költségekből.';

  @override
  String get noUsageYet => 'Még nincs rögzített használat.';

  @override
  String get spentThisWeek => 'elköltve ezen a héten';

  @override
  String get subscriptionUsage => 'Előfizetés használata';

  @override
  String get subscriptionUsageUnavailable => 'Nem elérhető';

  @override
  String get subscriptionUsageExhausted => 'Kvóta kimerítve';

  @override
  String get subscriptionUsageSignInRequired => 'Jelentkezzen be újra';

  @override
  String get subscriptionUsageSignInExpired =>
      'A bejelentkezés lejárt, a következő futtatáskor megújul';

  @override
  String get subscriptionUsagePartiallyAvailable => 'Részben elérhető';

  @override
  String resetsIn(String duration) {
    return 'Visszaáll $duration múlva';
  }

  @override
  String get feedbackHelpful => 'Ez hasznos volt';

  @override
  String get feedbackNotHelpful => 'Ez nem volt hasznos';

  @override
  String get modeChat => 'Csevegés';

  @override
  String get modePlan => 'Terv';

  @override
  String get modeReview => 'Átnézés';

  @override
  String get modeOrchestrate => 'Orchestrálás';

  @override
  String get editorTheme => 'Szerkesztőtéma';

  @override
  String get editorThemeDescription =>
      'Importáljon egy VS Code színtémát, hogy a beágyazott diff és szerkesztő illeszkedjen az IDE-jéhez.';

  @override
  String get editorThemePasteHint =>
      'Illessze be egy VS Code színtéma JSON-fájl tartalmát';

  @override
  String get editorThemeImported => 'Téma importálva';

  @override
  String get editorThemeInvalid => 'Ez nem tűnik érvényes VS Code témának';

  @override
  String get importTheme => 'Téma importálása';

  @override
  String get clearTheme => 'Téma törlése';

  @override
  String get openInDiffViewer => 'Megnyitás a diffnézegetőben';

  @override
  String get shellCommand => 'Parancs';

  @override
  String get shellOutput => 'Kimenet';

  @override
  String get revertToHere => 'Visszaállítás ide';

  @override
  String get revertConfirmBody =>
      'Elrejti az ez utáni üzeneteket, és visszavonja az ügynök fájlmódosításait erre a körre? Ezt visszavonhatja.';

  @override
  String get revert => 'Visszavonás';

  @override
  String get revertedToHere => 'Visszaállítva ide';

  @override
  String get nothingToRevert => 'Nincs mit visszavonni';

  @override
  String get undoRevert => 'Visszavonás visszavonása';

  @override
  String get revertUndone => 'Visszavonás visszavonva';

  @override
  String get systemBehavior => 'Rendszer viselkedése';

  @override
  String get keepAwakeTitle =>
      'A számítógép ébren tartása, amíg az ügynökök futnak';

  @override
  String get keepAwakeOnSubtitle =>
      'A számítógép nem alszik el, amíg egy ügynök dolgozik';

  @override
  String get keepAwakeOffSubtitle =>
      'A számítógép elaludhat akkor is, ha egy ügynök dolgozik';

  @override
  String get syncEngineSectionTitle => 'Szinkronmotor';

  @override
  String get syncEngineDescription =>
      'A jegyek, üzenetek és jegyzetek élőben frissülnek kis növekményes változásokkal, a teljes pillanatképek helyett. Egy kapcsoló kikapcsolása az adott tárat teljes pillanatkép módra állítja vissza — töltse újra az alkalmazást, hogy a változás érvényesüljön.';

  @override
  String get syncEngineTicketsTitle => 'Jegyek';

  @override
  String get syncEngineMessagingTitle => 'Üzenetküldés';

  @override
  String get syncEngineNotesTitle => 'Jegyzetek';

  @override
  String get syncEngineOnSubtitle => 'Az élő delta-szinkron aktív';

  @override
  String get syncEngineOffSubtitle =>
      'Teljes pillanatkép-szinkron van használatban';

  @override
  String get spaces => 'Terek';

  @override
  String get spacesHomeDescription =>
      'Válasszon teret a listából, vagy indítson egy újat.';

  @override
  String get noSpacesYet => 'Még nincsenek terek';

  @override
  String get newSpace => 'Új tér';

  @override
  String get spaceName => 'Tér neve';

  @override
  String get spaceReposHint => 'Bevonandó tárolók';

  @override
  String get ideSourceControl => 'Verziókezelés';

  @override
  String get stagedChanges => 'Előkészített módosítások';

  @override
  String get changes => 'Módosítások';

  @override
  String get stageFile => 'Előkészítés';

  @override
  String get unstageFile => 'Előkészítés visszavonása';

  @override
  String get stageAll => 'Minden módosítás előkészítése';

  @override
  String get unstageAll => 'Minden előkészítés visszavonása';

  @override
  String get stageChangesToCommit => 'Módosítások előkészítése commitoláshoz';

  @override
  String get syncToPrHead => 'Legújabb PR-commitok húzása';

  @override
  String get syncedToPrHead => 'Szinkronizálva a legújabb PR-commitokra';

  @override
  String get syncPrHeadDirty =>
      'Commitolja vagy vesse el a módosításait a szinkron előtt';

  @override
  String get syncPrHeadFailed => 'Nem sikerült szinkronizálni a PR headre';

  @override
  String get spaceLabel => 'Tér';

  @override
  String get keybindingNewSpace => 'Új tér';

  @override
  String get keybindingCreateANewSpaceDescription => 'Új tér létrehozása';

  @override
  String get jumpToLatest => 'Ugrás a legújabbra';

  @override
  String get streaming => 'Streamelés';

  @override
  String get newMessages => 'Új';

  @override
  String get copyLink => 'Hivatkozás másolása';

  @override
  String get linkCopied => 'Hivatkozás másolva';

  @override
  String get agentResponding => 'Az ügynök válaszol';

  @override
  String get agentFinished => 'Az ügynök befejezte';

  @override
  String get harnessConnectProviderForModels =>
      'Csatlakoztasson egy szolgáltatót a modellek megtekintéséhez.';

  @override
  String get providerSignOut => 'Kijelentkezés';

  @override
  String get providerWaitingForDeviceCode =>
      'Várakozás, hogy megerősítse a kódot a böngészőjében…';

  @override
  String get providerDeviceCodeHint =>
      'Ellenőrizze, hogy ez a kód megegyezik a böngészőben láthatóval, majd hagyja jóvá.';

  @override
  String get providerPlanUsageLoading => 'Csomaghasználat ellenőrzése…';

  @override
  String get providerPlanUsageUnavailable =>
      'Ez a csomag nem jelentett használatot.';

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return 'Eltávolítja a(z) $provider API-kulcsot?';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return 'A tárolt kulcs törlődik, és nem jeleníthető meg újra. A(z) $provider modelleket használó ügynökök addig nem működnek, amíg nem illeszt be egy újat.';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return 'Eltávolítja: $provider?';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return 'A(z) $provider és a tárolt kulcsa törlődik. A modelljeire rögzített ügynökök leállnak.';
  }

  @override
  String get providerApiKeyHint => 'Illesszen be egy API-kulcsot';

  @override
  String get providerApiKeyStoredHint =>
      'Illesszen be egy másik API-kulcsot a hozzáadáshoz';

  @override
  String get providerAddAnotherAccount => 'További fiók hozzáadása';

  @override
  String get providerActiveBadge => 'Aktív';

  @override
  String get providerOauthAccountFallback => 'OAuth-fiók';

  @override
  String get providerApiKeyFallback => 'API-kulcs';

  @override
  String get providerRemoveCredentialConfirmTitle =>
      'Eltávolítja ezt a hitelesítő adatot?';

  @override
  String get providerSignOutAccountConfirmTitle =>
      'Kijelentkezik ebből a fiókból?';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return 'A(z) $provider ügynökei a többi kulcsára és fiókjára esnek vissza. Ha semmi sem marad, leállnak, amíg hozzá nem ad egyet.';
  }

  @override
  String get providerBaseUrlHint => 'Alap-URL (nem kötelező)';

  @override
  String get addProvider => 'Szolgáltató hozzáadása';

  @override
  String get noCustomProviders => 'Még nincsenek egyéni szolgáltatók.';

  @override
  String get providerNameLabel => 'Név';

  @override
  String get apiTypeLabel => 'API típusa';

  @override
  String get providerBaseUrlLabel => 'Alap-URL';

  @override
  String get providerApiKeyOptionalHint => 'API-kulcs (nem kötelező)';

  @override
  String get dialectOpenAiCompatible => 'OpenAI-kompatibilis';

  @override
  String get dialectAnthropicCompatible => 'Anthropic-kompatibilis';

  @override
  String get removeProviderTooltip => 'Szolgáltató eltávolítása';

  @override
  String get providerLogInWithBrowser => 'Bejelentkezés böngészővel';

  @override
  String providerLoginDialogTitle(String provider) {
    return 'Bejelentkezés ide: $provider';
  }

  @override
  String get providerLabel => 'Szolgáltató';

  @override
  String get selectProviderToLogin =>
      'Válasszon szolgáltatót a bejelentkezéshez';

  @override
  String providerLoginFailed(String error) {
    return 'A bejelentkezés sikertelen: $error';
  }

  @override
  String get providerWaitingForBrowser =>
      'Várakozás a böngészőbeli felhatalmazásra…';

  @override
  String get providerPasteCodeHint => 'Vagy illessze be a kódot a böngészőből';

  @override
  String get providerCompleteLogin => 'Befejezés';

  @override
  String get providerConnectedApiKey => 'Csatlakoztatva API-kulccsal';

  @override
  String get providerConnectedOauth => 'Csatlakoztatva';

  @override
  String providerConnectedAccount(String account) {
    return 'Csatlakoztatva · $account';
  }

  @override
  String get providerLocalReady => 'Helyi · kész';

  @override
  String get providerNotConnected => 'Nincs csatlakoztatva';

  @override
  String get preparingWorkspace => 'Munkaterület előkészítése…';

  @override
  String provisioningRunningSetupScript(String repo) {
    return 'A(z) $repo telepítőszkriptjének futtatása…';
  }

  @override
  String get repoScriptsTitle => 'Szkriptek';

  @override
  String get repoScriptsTooltip => 'Életciklus-szkriptek beállítása';

  @override
  String get repoScriptsSetupLabel => 'Telepítőszkript';

  @override
  String get repoScriptsSetupHelp =>
      'A tér worktree-jében fut, közvetlenül a létrehozása után — függőségek telepítése, fájlok generálása. A hiba sikertelennek jelöli a teret; az újrapróbálás újra futtatja.';

  @override
  String get repoScriptsArchiveLabel => 'Archiválószkript';

  @override
  String get repoScriptsArchiveHelp =>
      'Közvetlenül a tér worktree-jének törlése előtt fut — a worktree-n kívüli erőforrások takarítása. A hiba soha nem blokkolja a törlést.';

  @override
  String get repoScriptsEnvHelp =>
      'bash-sel fut a worktree-ből, a CC_WORKSPACE_PATH (a worktree), CC_ROOT_PATH (a tároló gyökere), CC_SPACE_ID, CC_SPACE_NAME és CC_REPO_NAME beállítva.';

  @override
  String get repoScriptsSetupPlaceholder => 'pl. pnpm install';

  @override
  String get repoScriptsArchivePlaceholder =>
      'pl. docker compose -p \$CC_SPACE_ID down';

  @override
  String get repoScriptsRecentRuns => 'Legutóbbi futtatások';

  @override
  String get repoScriptsNoRuns => 'Még nincs futtatás';

  @override
  String get repoScriptsSaved => 'Szkriptek mentve';

  @override
  String get repoScriptsRunKindSetup => 'Telepítés';

  @override
  String get repoScriptsRunKindArchive => 'Archiválás';

  @override
  String get repoScriptsRunStatusRunning => 'Fut';

  @override
  String get repoScriptsRunStatusSucceeded => 'Sikeres';

  @override
  String get repoScriptsRunStatusFailed => 'Sikertelen';

  @override
  String get repoScriptsRunStatusTimedOut => 'Időtúllépés';

  @override
  String repoScriptsExitCode(int code) {
    return 'Kilépési kód $code';
  }

  @override
  String provisioningCloningRepo(String repo) {
    return '$repo klónozása…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return 'Pull request checkoutja itt: $repo…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return '$agent ügynök beállítása…';
  }

  @override
  String get workspacePrepFailed => 'A munkaterület beállítása sikertelen';

  @override
  String get workspacePrepStopped => 'A munkaterület beállítása leállítva';

  @override
  String get stopWorkspacePrep => 'Előkészítés leállítása';

  @override
  String get stopWorkspacePrepTooltip =>
      'Ennek a munkaterületnek az előkészítése leállítása';

  @override
  String get stopWorkspacePrepConfirm =>
      'Leállítja ennek a munkaterületnek az előkészítését? A folyamatban lévő klón elvész — innen újraindíthatja.';

  @override
  String messageWillSendWhenReady(int count) {
    return '$count üzenet küldésre kerül, ha kész';
  }

  @override
  String get membersNav => 'Tagok';

  @override
  String get membersSettingsDescription =>
      'Azok, akik hozzáférnek ehhez a munkaterülethez: névsor, meghívók és napló';

  @override
  String get memberRosterLabel => 'Tagok névsora';

  @override
  String get memberRepoAccessAction => 'Tároló-hozzáférés';

  @override
  String memberRepoAccessTitle(String name) {
    return 'Tároló-hozzáférés: $name';
  }

  @override
  String get roleOwner => 'Tulajdonos';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleMember => 'Tag';

  @override
  String get roleViewer => 'Megtekintő';

  @override
  String get roleGuest => 'Vendég';

  @override
  String get removeMemberTitle => 'Tag eltávolítása';

  @override
  String removeMemberConfirm(String name) {
    return 'Eltávolítja $name tagot ebből a munkaterületből? Azonnal elveszíti a hozzáférését.';
  }

  @override
  String get transferOwnershipAction => 'Tulajdonjog átadása';

  @override
  String get transferOwnershipTitle => 'Tulajdonjog átadása';

  @override
  String transferOwnershipConfirm(String name) {
    return '$name legyen a munkaterület tulajdonosa? Ön adminná válik. Csak a tulajdonos törölheti a munkaterületet, vagy módosíthatja egy másik admin szerepét.';
  }

  @override
  String get transferOwnershipCta => 'Átadás';

  @override
  String get auditTrailLabel => 'Jogosultsági napló';

  @override
  String get auditTrailDescription =>
      'Minden engedélyezés és elutasítás, hash-láncolva, hogy a módosított vagy törölt bejegyzés észlelhető legyen.';

  @override
  String get auditVerifyChain => 'Lánc ellenőrzése';

  @override
  String auditChainIntact(int count) {
    return 'A lánc ép — $count bejegyzés ellenőrizve';
  }

  @override
  String auditChainBroken(int seq, String reason) {
    return 'A lánc megszakadt a(z) $seq. bejegyzésnél: $reason';
  }

  @override
  String get auditEmpty => 'Még nincsenek rögzített döntések.';

  @override
  String get auditDenied => 'Tiltva';

  @override
  String get auditAllowed => 'Engedélyezve';

  @override
  String auditOnBehalfOf(String user) {
    return 'neki: $user';
  }

  @override
  String get policyTemplatesLabel => 'Szabályzatsablonok';

  @override
  String get policyTemplatesDescription =>
      'Alkalmazzon kiinduló tartást, vagy vigyen át egyet munkaterületek között.';

  @override
  String get policyTemplateStrict => 'Szigorú';

  @override
  String get policyTemplateBalanced => 'Kiegyensúlyozott';

  @override
  String get policyTemplatePermissive => 'Engedékeny';

  @override
  String get policyTemplateApply => 'Alkalmazás';

  @override
  String policyTemplateApplied(int count) {
    return '$count szabály alkalmazva';
  }

  @override
  String get policyExport => 'Szabályzat másolása';

  @override
  String get policyExported => 'Szabályzat a vágólapra másolva';

  @override
  String get policyImport => 'Szabályzat beillesztése';

  @override
  String policyImported(int count) {
    return '$count szabály importálva';
  }

  @override
  String get approveAndRemember => 'Jóváhagyás 8 órára';

  @override
  String get approveAndRememberTooltip =>
      'Jóváhagyja ezt a műveletet, és 8 órán át nem kérdez rá a hasonlóakra ebben a térben. Magától lejár.';

  @override
  String get unknownUserLabel => 'Ismeretlen felhasználó';

  @override
  String get inviteMember => 'Tag meghívása';

  @override
  String get inviteRepoAccessHeader => 'Tároló-hozzáférés';

  @override
  String get inviteRepoAccessExplainer =>
      'Csak a bejelölt tárolók kerülnek megosztásra a meghívottal, az Ön által választott szinten. Minden más rejtve marad.';

  @override
  String get grantLevelRead => 'Olvasás';

  @override
  String get grantLevelReview => 'Átnézés';

  @override
  String get grantLevelWrite => 'Írás';

  @override
  String get inviteExpiryLabel => 'Lejár';

  @override
  String get expiryOneDay => '1 nap';

  @override
  String get expirySevenDays => '7 nap';

  @override
  String get expiryThirtyDays => '30 nap';

  @override
  String get createInviteAction => 'Meghívó létrehozása';

  @override
  String get inviteOneTimeCodeLabel => 'Egyszeri kód';

  @override
  String get inviteCodeShownOnce =>
      'Ez a kód csak egyszer jelenik meg — másolja most.';

  @override
  String get inviteLinkLabel => 'Meghívóhivatkozás';

  @override
  String get inviteRedeemHint =>
      'Ossza meg a kódot a meghívottal; a szerver URL-jénél váltja be.';

  @override
  String get inviteScanQr => 'Vagy olvassa be a beváltáshoz';

  @override
  String get inviteLoopbackWarningTitle => 'A meghívó helyi címre mutat';

  @override
  String get inviteLoopbackWarningBody =>
      'Más gépeken lévő közreműködők nem érik el ezt a szervert. Indítson alagutat (Beállítások → Integrációk → Szerver megosztása), vagy kösse a hálózatához, hogy a gépen kívüli felhasználók csatlakozhassanak.';

  @override
  String get inviteStatusOpen => 'Nyitott';

  @override
  String get inviteStatusUsed => 'Felhasználva';

  @override
  String get inviteStatusRevoked => 'Visszavonva';

  @override
  String get inviteStatusExpired => 'Lejárt';

  @override
  String inviteCreatedTime(String time) {
    return 'Létrehozva $time';
  }

  @override
  String inviteExpiresOn(String date) {
    return 'lejár $date';
  }

  @override
  String get noActivityYet => 'Még nincs tevékenység';

  @override
  String get couldNotLoadMembers => 'Nem sikerült betölteni a tagokat';

  @override
  String get couldNotLoadInvites => 'Nem sikerült betölteni a meghívókat';

  @override
  String get couldNotLoadActivity => 'Nem sikerült betölteni a tevékenységet';

  @override
  String get yourDevices => 'Az Ön eszközei';

  @override
  String get yourDevicesDescription =>
      'A fiókjához párosított kliensek ezen a szerveren.';

  @override
  String get noOwnDevices => 'Még nincsenek a fiókjához párosított eszközök';

  @override
  String get renameDeviceTitle => 'Eszköz átnevezése';

  @override
  String get revokeDeviceTitle => 'Eszköz visszavonása';

  @override
  String revokeDeviceConfirm(String label) {
    return 'Visszavonja a(z) $label eszközt? Azonnal leválasztódik, és többé nem éri el ezt a szervert.';
  }

  @override
  String devicePairedTime(String time) {
    return 'Párosítva $time';
  }

  @override
  String deviceLastSeenTime(String time) {
    return 'Utoljára látva $time';
  }

  @override
  String get deviceNeverSeen => 'Soha nem csatlakozott';

  @override
  String get profileSectionLabel => 'Profil';

  @override
  String get profileSectionDescription =>
      'Hogyan lát a csapat, és hogyan jelenik meg a git commit szerzősége ebben a munkaterületen. Az üres mezők öröklik a fiók nevét és e-mailjét.';

  @override
  String get displayNameLabel => 'Megjelenített név';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get gitAuthorNameLabel => 'Git szerző neve';

  @override
  String get gitAuthorEmailLabel => 'Git szerző e-mailje';

  @override
  String get profileSaved => 'Profil mentve';

  @override
  String get presenceOnline => 'Online';

  @override
  String get presenceIdle => 'Tétlen';

  @override
  String get presenceTyping => 'Gépel…';

  @override
  String get presenceAgentThinking => 'Gondolkodik';

  @override
  String get presenceAgentRunning => 'Fut';

  @override
  String get presenceAgentBlocked => 'Blokkolva';

  @override
  String get presenceAgentDone => 'Kész';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String presenceNameStatusCost(String name, String status, String cost) {
    return '$name — $status ($cost)';
  }

  @override
  String get presenceRailLabel => 'Ki van online';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => 'Ne zavarjanak bekapcsolása';

  @override
  String get dndTooltipOff => 'Ne zavarjanak kikapcsolása';

  @override
  String get startPresenting => 'Bemutató indítása';

  @override
  String get stopPresenting => 'Bemutató leállítása';

  @override
  String spotlightPresentingBanner(String name) {
    return '$name bemutat';
  }

  @override
  String get spotlightLeave => 'Kilépés';

  @override
  String typingIndicator(String name) {
    return '$name gépel…';
  }

  @override
  String get ideTabNotes => 'Jegyzetek';

  @override
  String get ideSidebarAllViews => 'Minden nézet';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return 'Minden nézet ($count rejtett)';
  }

  @override
  String get ideSidebarPinView => 'Rögzítés az oldalsávra';

  @override
  String get ideSidebarUnpinView => 'Levétel az oldalsávról';

  @override
  String get notesEmptyHint =>
      'Adjon jegyzetet annak, aki felveszi ezt a beszélgetést…';

  @override
  String get notesEditTooltip => 'Jegyzet szerkesztése';

  @override
  String notesUpdatedBy(String name, String time) {
    return 'Frissítette $name · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '$name szerkeszt';
  }

  @override
  String get notesSaveFailed => 'Nem sikerült menteni a jegyzetet';

  @override
  String get reactionAddTooltip => 'Reakció hozzáadása';

  @override
  String reactionToggleTooltip(String emoji) {
    return 'Reagálás ezzel: $emoji';
  }

  @override
  String get autonomyDialLabel => 'Autonómia';

  @override
  String get autonomyProposeOnly => 'Csak javaslat';

  @override
  String get autonomyActWithApproval => 'Cselekvés jóváhagyással';

  @override
  String get autonomyActFreely => 'Szabad cselekvés';

  @override
  String get autonomyDefaultOption => 'Alapértelmezett';

  @override
  String get checkerLabel => 'Ellenőrző';

  @override
  String get checkerNone => 'Nincs';

  @override
  String get checkerCaption =>
      'Az ellenőrző átnézi a többi ügynök befejezett futtatásait.';

  @override
  String get takeoverTooltip => 'Worktree átvétele';

  @override
  String get takeoverBannerSelf =>
      'Átvette ennek a beszélgetésnek a worktree-jét';

  @override
  String takeoverBannerOther(String name) {
    return '$name átvette ennek a beszélgetésnek a worktree-jét';
  }

  @override
  String get handBackButton => 'Visszaadás';

  @override
  String get handBackDialogTitle => 'Worktree visszaadása';

  @override
  String get handBackDialogNoteHint => 'Opcionális jegyzet az ügynöknek…';

  @override
  String takeoverFailed(String message) {
    return 'Nem sikerült átvenni: $message';
  }

  @override
  String handBackFailed(String message) {
    return 'Nem sikerült visszaadni: $message';
  }

  @override
  String get planStudioTitle => 'Plan Studio';

  @override
  String get plansTitle => 'Tervek';

  @override
  String get plansSubtitle => 'Aktív tervek, tervdokumentumok és playbookok';

  @override
  String get plansActiveSection => 'Aktív tervek';

  @override
  String get plansDocumentsSection => 'Tervdokumentumok';

  @override
  String get plansPlaybooksSection => 'Playbookok';

  @override
  String get plansNoActive => 'Még nincsenek aktív tervek.';

  @override
  String get plansNoDocuments => 'Még nincsenek tervdokumentumok.';

  @override
  String get plansNoPlaybooks => 'Még nincsenek playbookok.';

  @override
  String get planNotFound => 'A terv nem található.';

  @override
  String get planOpenInStudio => 'Megnyitás';

  @override
  String get planNodeTitle => 'Cím';

  @override
  String get planNodeDescription => 'Leírás';

  @override
  String get planNodeDescriptionHint => 'Mit kell tennie ennek a lépésnek…';

  @override
  String get planNodeApplyDescription => 'Alkalmazás';

  @override
  String get planNodeRole => 'Szerep';

  @override
  String get planNodeDependencies => 'Függ ettől';

  @override
  String get planNodeDependenciesHint => 'Függőség hozzáadása';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# függőség',
      one: '# függőség',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies =>
      'Nincsenek függőségek, ezért ez a terv indításakor azonnal fut';

  @override
  String get planNodeOutputSchema => 'Kimeneti séma (JSON)';

  @override
  String get planNodeEstimate => 'Becslés';

  @override
  String get planNodeProvenance => 'Származás';

  @override
  String get planNodeAlreadyExecuted =>
      'Már végrehajtva — a szerkesztés innen ágaztatja a tervet.';

  @override
  String get planNewNodeTitle => 'Új lépés';

  @override
  String get planEstimateNoHistory => 'Még nincs előzmény';

  @override
  String get planEstimateBlastUnknown => 'Hatósugár: ismeretlen';

  @override
  String get planEstimatePartial => 'részleges';

  @override
  String get planEstimateAction => 'Becslés';

  @override
  String planEstimateDuration(String range) {
    return 'Időtartam $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return 'Hatósugár: $files fájl, $symbols szimbólum';
  }

  @override
  String get planApprove => 'Terv jóváhagyása';

  @override
  String get planApproveSelectedNodes => 'Kijelöltek jóváhagyása';

  @override
  String get planReject => 'Elutasítás';

  @override
  String get planCancel => 'Futtatás megszakítása';

  @override
  String get planContinueNode => 'Csomópont folytatása';

  @override
  String get planTotalNotEstimated => 'Még nincs becsülve';

  @override
  String get planBudgetExceeded => 'túllépi a keretet';

  @override
  String planBudgetCeiling(String amount) {
    return 'keret ≤ \$$amount';
  }

  @override
  String get planVersionsTitle => 'Verziók';

  @override
  String get planNoRevisions => 'Még nincsenek revíziók.';

  @override
  String get planDiffIdentical => 'Nincsenek változások.';

  @override
  String get planDiffGoalChanged => 'A cél változott';

  @override
  String get planDiffBudgetChanged => 'A keret változott';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'Változások v$fromRev → v$toRev';
  }

  @override
  String planDiffAdded(String node) {
    return 'Hozzáadva: $node';
  }

  @override
  String planDiffRemoved(String node) {
    return 'Eltávolítva: $node';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return 'Módosítva $node: $fields';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return 'Él hozzáadva: $edge';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return 'Él eltávolítva: $edge';
  }

  @override
  String planDiffRoleAdded(String role) {
    return 'Szerep hozzáadva: $role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return 'Szerep eltávolítva: $role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return 'Szerep újraosztva: $role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return 'Terv újratervezve: a v$approved verziót hagyta jóvá, most v$current. Nézze át a diffet a folytatás előtt.';
  }

  @override
  String planLiveActualCost(String amount) {
    return 'Tényleges költség: \$$amount';
  }

  @override
  String get planPlaybookRun => 'Futtatás';

  @override
  String get planPlaybookDelete => 'Playbook törlése';

  @override
  String get planPlaybookProposed =>
      'Terv javasolva — hagyja jóvá a Plan Studióban.';

  @override
  String get planPlaybookAnchorTicket => 'Horgonyjegy';

  @override
  String get planPlaybookPickTicket => 'Jegy kiválasztása…';

  @override
  String get planPlaybookProposeRun => 'Terv javaslása';

  @override
  String get planPlaybookRepoHint => 'Egy tároló-ID';

  @override
  String get planPlaybookAgentHint => 'Egy ügynök-ID';

  @override
  String planPlaybookRunTitle(String name) {
    return '$name futtatása';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '$count paraméter';
  }

  @override
  String get recentLabel => 'Legutóbbi';

  @override
  String get cheatSheetTitle => 'Billentyűparancsok';

  @override
  String get cheatSheetGlobal => 'Globális';

  @override
  String get cheatSheetThisScreen => 'Ez a képernyő';

  @override
  String get cheatSheetReservedInBrowser => 'Böngésző által foglalt';

  @override
  String get keybindingCheatSheet => 'Billentyűparancsok';

  @override
  String get keybindingShowKeyboardShortcutsDescription =>
      'Az aktuális képernyő billentyűparancs-táblázatának megjelenítése';

  @override
  String get runPlaybookLabel => 'Playbook futtatása';

  @override
  String get playbooksLabel => 'Playbookok';

  @override
  String get keybindingUndo => 'Visszavonás';

  @override
  String get keybindingRedo => 'Mégis';

  @override
  String get keybindingUndoLastActionDescription =>
      'Az utolsó visszavonható művelet visszavonása';

  @override
  String get keybindingRedoLastActionDescription =>
      'Az utoljára visszavont művelet mégis végrehajtása';

  @override
  String get undone => 'Visszavonva';

  @override
  String get redone => 'Mégis végrehajtva';

  @override
  String get undoFailed => 'Nem sikerült visszavonni';

  @override
  String get undoLabelTicketEdit => 'jegy szerkesztése';

  @override
  String get undoLabelMessageEdit => 'üzenet szerkesztése';

  @override
  String get undoLabelTodoStatus => 'teendő állapota';

  @override
  String get inboxTitle => 'Beérkezett';

  @override
  String get inboxReview => 'Átnézés';

  @override
  String get inboxOpen => 'Megnyitás';

  @override
  String get inboxAllCaughtUp => 'Minden elolvasva';

  @override
  String get inboxGitHubDownTitle => 'A GitHub lehet, hogy nem elérhető';

  @override
  String inboxGitHubDownBody(String status) {
    return 'A GitHub $status állapotot jelez, így a pull requestek hiányozhatnak ebből a listából, nem pedig ténylegesen készen állnak.';
  }

  @override
  String get inboxGitHubIdentityTitle =>
      'Nem sikerült megerősíteni a GitHub-fiókját';

  @override
  String get inboxGitHubIdentityBody =>
      'A beérkezett a GitHub-identitása szerint van rendezve. Amíg az be nem töltődik, üres marad, még akkor is, ha pull requestek várnak Önre.';

  @override
  String get inboxSeverityBlocking => 'Blokkolva';

  @override
  String get inboxSeverityWaiting => 'Várakozik';

  @override
  String get inboxSeverityInfo => 'Infó';

  @override
  String get inboxSyncFailed => 'A szinkron sikertelen';

  @override
  String get inboxNeedsYourAttention => 'Figyelmet igényel';

  @override
  String get inboxSectionNeedsYourReview => 'Az Ön átnézésére van szükség';

  @override
  String get inboxSectionReturnedToYou => 'Visszaküldve Önnek';

  @override
  String get inboxSectionApproved => 'Jóváhagyva';

  @override
  String get inboxSectionDrafts => 'Piszkozatok';

  @override
  String get inboxSectionWaitingForReviewers => 'Átnézőkre vár';

  @override
  String get inboxSectionMergingAndMerged =>
      'Összefésülés és nemrég összefésülve';

  @override
  String get inboxSectionWaitingForAuthor => 'Szerzőre vár';

  @override
  String get inboxColumnTitle => 'Cím';

  @override
  String get inboxColumnChanges => 'Módosítások';

  @override
  String get inboxColumnUpdated => 'Frissítve';

  @override
  String get inboxReviewApproved => 'Jóváhagyva';

  @override
  String get inboxReviewChangesRequested => 'Módosítást kértek';

  @override
  String get inboxHeroSubtitle =>
      'Minden pull request, amelyben érintett, aszerint rendezve, hogy mi a következő lépés.';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# pull request vár az átnézésére',
      one: '# pull request vár az átnézésére',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# visszaküldve Önnek',
      one: '# visszaküldve Önnek',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted =>
      'Ez a módosítás nem mentődött, és visszavonásra került';

  @override
  String get offlinePendingLabel => 'függőben';

  @override
  String get offlineSyncingLabel => 'szinkronizálás';

  @override
  String get copyLinkLabel => 'Hivatkozás másolása erre az oldalra';

  @override
  String get agentsSectionLabel => 'Ügynökök';

  @override
  String get fleetWorkersTitle => 'Workerek';

  @override
  String get fleetWorkersSubtitle => 'A feladatok futtatására elérhető gépek';

  @override
  String get fleetJobsTitle => 'Feladatok';

  @override
  String get fleetJobsSubtitle => 'A flottán szétosztott munka';

  @override
  String get fleetNoWorkers =>
      'Még nincsenek workerek — egy második gép, amely `cc_worker --server <url>` parancsot futtat, csatlakozik a flottához.';

  @override
  String get fleetNoJobs => 'Nincsenek feladatok.';

  @override
  String get fleetError => 'Nem sikerült betölteni a flottát';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# mag',
      one: '# mag',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return 'Heartbeat $time';
  }

  @override
  String get fleetNoHeartbeat => 'Még nincs heartbeat';

  @override
  String fleetLastErrorLabel(String error) {
    return 'Utolsó hiba: $error';
  }

  @override
  String get fleetDrain => 'Kiürítés';

  @override
  String get fleetResume => 'Folytatás';

  @override
  String get fleetRevoke => 'Visszavonás';

  @override
  String get fleetRemove => 'Eltávolítás';

  @override
  String get fleetRevokeTitle => 'Visszavonja a workert?';

  @override
  String fleetRevokeBody(String name) {
    return 'Visszavonja a(z) $name workert? A munkamenete véget ér, és az aktív feladatok újraosztásra kerülnek.';
  }

  @override
  String get fleetRemoveTitle => 'Eltávolítja a workert?';

  @override
  String fleetRemoveBody(String name) {
    return 'Eltávolítja a(z) $name workert a flottából? Ez törli a rekordját.';
  }

  @override
  String get fleetActionFailed => 'A művelet sikertelen';

  @override
  String get fleetJobUnassigned => 'Nincs hozzárendelve';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '$attempts/$max kísérlet';
  }

  @override
  String get fleetPlacementReasons => 'Elhelyezési döntések';

  @override
  String get fleetNoPlacements => 'Még nincsenek elhelyezési döntések.';

  @override
  String get fleetStatusOnline => 'Online';

  @override
  String get fleetStatusDraining => 'Kiürítés';

  @override
  String get fleetStatusOffline => 'Offline';

  @override
  String get fleetStatusIncompatible => 'Nem kompatibilis';

  @override
  String get fleetStatusRevoked => 'Visszavonva';

  @override
  String get fleetJobStatusQueued => 'Várólistán';

  @override
  String get fleetJobStatusRunning => 'Fut';

  @override
  String get fleetJobStatusSucceeded => 'Sikeres';

  @override
  String get fleetJobStatusFailed => 'Sikertelen';

  @override
  String get fleetJobStatusCancelled => 'Megszakítva';

  @override
  String get evalsNoSuites => 'Még nincsenek kiértékelési csomagok.';

  @override
  String get evalsError => 'Nem sikerült betölteni a kiértékeléseket';

  @override
  String get evalsStarterBadge => 'Kezdő';

  @override
  String evalsDefaultBatch(int count) {
    return 'Alapértelmezett köteg, $count db';
  }

  @override
  String get evalsRecentRuns => 'Legutóbbi futtatások';

  @override
  String get evalsNoRuns => 'Még nincs futtatás.';

  @override
  String get evalsPassRate => 'Sikeres arány';

  @override
  String evalsBatchTimes(int count) {
    return '× $count';
  }

  @override
  String evalsTriggeredBy(String who) {
    return 'indította: $who';
  }

  @override
  String evalsRunFinished(String rate) {
    return 'Kiértékelés kész — $rate átment';
  }

  @override
  String get evalsRunFailed => 'Nem sikerült futtatni a csomagot';

  @override
  String get evalsRun => 'Futtatás';

  @override
  String get evalsStatusQueued => 'Várólistán';

  @override
  String get evalsStatusRunning => 'Fut';

  @override
  String get evalsStatusPassed => 'Átment';

  @override
  String get evalsStatusFailed => 'Sikertelen';

  @override
  String get bannerMeetingJoin => 'Csatlakozás';

  @override
  String get bannerMeetingRecordAndLink => 'Felvétel és összekapcsolás';

  @override
  String get bannerCalendarReconnect => 'Újracsatlakozás';

  @override
  String get bannerView => 'Megtekintés';

  @override
  String get soundscapeTitle => 'Hangtájak';

  @override
  String get soundscapePlay => 'Lejátszás';

  @override
  String get soundscapePause => 'Szünet';

  @override
  String get soundscapeMoodLabel => 'Hangulat';

  @override
  String get soundscapeMoodFocus => 'Fókusz';

  @override
  String get soundscapeMoodRelax => 'Lazítás';

  @override
  String get soundscapeMoodSleep => 'Alvás';

  @override
  String get soundscapeMoodRise => 'Emelkedés';

  @override
  String get soundscapeVolumeLabel => 'Hangerő';

  @override
  String get soundscapeTuneLabel => 'Hangolás';

  @override
  String get soundscapeTuneMellow => 'Lágy';

  @override
  String get soundscapeTuneBright => 'Világos';

  @override
  String get soundscapeTuneEnergetic => 'Energikus';

  @override
  String get soundscapeTuneSpacy => 'Tágas';

  @override
  String get soundscapeTuneResetHint => 'Dupla koppintás a visszaállításhoz';

  @override
  String get soundscapeSceneLabel => 'Most szól';

  @override
  String get soundscapeSceneLoading => 'A hangulat hangolása…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees°C';
  }

  @override
  String get soundscapeLocationLabel => 'Helyszín';

  @override
  String get soundscapeLocationDetecting => 'Helyszín észlelése…';

  @override
  String get soundscapeLocationAutoNote =>
      'A helyszín erről az eszközről származik.';

  @override
  String get soundscapeRefreshWeather => 'Időjárás frissítése';

  @override
  String get soundscapeAutoStartLabel => 'Indítás fókuszmóddal';

  @override
  String get soundscapeAutoStartDescription =>
      'Hangtáj automatikus lejátszása fókuszmunkamenet indításakor.';

  @override
  String get soundscapeReturnToApp => 'Vissza az alkalmazáshoz';

  @override
  String get soundscapePopOut => 'Lejátszó kiemelése';

  @override
  String get discussion => 'Beszélgetés';

  @override
  String get chat => 'Csevegés';

  @override
  String get saving => 'Mentés…';

  @override
  String get saved => 'Mentve';

  @override
  String get saveFailed => 'Nem sikerült menteni';

  @override
  String get commitAndPush => 'Commit és küldés';

  @override
  String get commit => 'Commit';

  @override
  String get commitAmend => 'Commit (amend)';

  @override
  String get commitAndSync => 'Commit és szinkron';

  @override
  String get committed => 'Commitolva';

  @override
  String get commitAmended => 'Commit módosítva';

  @override
  String get commitFailed => 'A commit sikertelen';

  @override
  String get moreCommitActions => 'További commitműveletek';

  @override
  String get sourceControl => 'Verziókezelés';

  @override
  String fixFindingTitle(String location) {
    return 'Javítás: $location';
  }

  @override
  String get openInEditor => 'Megnyitás szerkesztőben';

  @override
  String get regexTesterTitle => 'Reguláris kifejezés tesztelése';

  @override
  String get regexTesterHint => 'Írj egy mintát';

  @override
  String get regexMatch => 'Találat';

  @override
  String get regexNoMatch => 'Nincs találat';

  @override
  String get regexInvalidPattern => 'Érvénytelen minta';

  @override
  String get symbolLookupNone =>
      'Nincs definíció az indexben vagy ebben a pull requestben';

  @override
  String get symbolLookupInDiff => 'Megtalálva ebben a pull requestben';

  @override
  String get symbolLookupFromBase =>
      'Az alap checkoutból — ennek a PR-nek a worktree-je még nincs indexelve';

  @override
  String get symbolImplementations => 'Implementációk';

  @override
  String symbolCallersCount(int count) {
    return '$count hívó';
  }

  @override
  String get commitMessageHint => 'Commitüzenet';

  @override
  String get pushedToPr => 'Elküldve a PR-re';

  @override
  String get pushFailed => 'A küldés sikertelen';

  @override
  String get reviewFindings => 'Megállapítások';

  @override
  String get treeLabel => 'Fa';

  @override
  String get toggleFileTree => 'Fájlfa megjelenítése vagy elrejtése';

  @override
  String get diffViewSettings => 'Diffnézet beállításai';

  @override
  String get splitViewLabel => 'Osztott';

  @override
  String get unifiedViewLabel => 'Egységes';

  @override
  String get wrapLines => 'Sorok tördelése';

  @override
  String get shiftClickSelectRange => 'Shift-kattintás tartomány kijelöléséhez';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# fájl',
      one: '# fájl',
    );
    return '$_temp0';
  }

  @override
  String prComplexityLoc(String loc) {
    return '$loc LOC';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return 'Kis PR — $files, ~$minutes perc az átnézéshez';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return 'Közepes PR — $files, szánjon ~$minutes percet az átnézésre';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return 'Nagy PR — $files, fontolja meg a felosztást az átnézés előtt';
  }

  @override
  String get searchInFiles => 'Keresés a fájlokban';

  @override
  String get showFileList => 'Fájllista megjelenítése';

  @override
  String get searchInFilesHintField => 'Keresés a fájlokban…';

  @override
  String get searchInFilesHint => 'Keresés a pull request fájljaiban';

  @override
  String get searchInWholeRepo => 'Keresés a teljes tárolóban';

  @override
  String get searchInThisPullRequest => 'Keresés ebben a pull requestben';

  @override
  String get searchNoResults => 'Nincs találat';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# találat',
      one: '# találat',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '# fájlban',
      one: '# fájlban',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String get discardChangesTitle => 'Elveti a módosításokat?';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# fájl',
      one: '# fájl',
    );
    return '$_temp0 elvetése HEAD-re? Ezt nem lehet visszavonni.';
  }

  @override
  String get discardAll => 'Mind elvetése';

  @override
  String get discardFailed => 'Nem sikerült elvetni a módosításokat';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# fájl',
      one: '# fájl',
    );
    return '$_temp0 elvetve';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '# fájl',
      one: '# fájl',
    );
    return '$_temp0 elvetve; $skipped kihagyva (nem követett)';
  }

  @override
  String get prWorktreeUnavailable => 'A munkaterület nem kész';

  @override
  String get prWorktreeUnavailableHint =>
      'A pull request fájljainak előkészítése sikertelen. Nyissa újra a pull requestet az újrapróbáláshoz.';

  @override
  String get timestampRelativeLabel => 'Relatív';

  @override
  String get timestampRawLabel => 'Időbélyeg';

  @override
  String get copyTimestamp => 'Időbélyeg másolása';

  @override
  String get copiedTimestamp => 'Időbélyeg másolva';

  @override
  String get previewDeployment => 'Előnézeti telepítés';

  @override
  String previewDeploymentTab(String site) {
    return 'Előnézet: $site';
  }

  @override
  String get askForReview => 'Átnézés kérése…';

  @override
  String get closePrsConfirmTitle => 'Lezárja a pull requesteket?';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lezár $count pull requestet?',
      one: 'Lezár 1 pull requestet?',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull request lezárva',
      one: '1 pull request lezárva',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull request hozzárendelve',
      one: '1 pull request hozzárendelve',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Átnézést kértek $count pull requesten',
      one: 'Átnézést kértek 1 pull requesten',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# művelet sikertelen',
      one: '# művelet sikertelen',
    );
    return '$_temp0';
  }

  @override
  String get diagram => 'Diagram';

  @override
  String get diagramViewSource => 'Forrás megtekintése';

  @override
  String get diagramHideSource => 'Forrás elrejtése';

  @override
  String diagramPreviewUnavailable(String reason) {
    return 'A diagram előnézete nem elérhető ($reason)';
  }

  @override
  String get planUnavailable => 'A terv nem elérhető';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# lépés',
      one: '# lépés',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => 'Jóváhagyás és futtatás';

  @override
  String get planStatusDraft => 'Piszkozat';

  @override
  String get planStatusProposed => 'Terv';

  @override
  String get planStatusApproved => 'Terv jóváhagyva';

  @override
  String get planStatusRejected => 'Terv elutasítva';

  @override
  String get planStatusSuperseded => 'Terv felülírva';

  @override
  String planRevisionLabel(int revision) {
    return '$revision. revízió';
  }

  @override
  String get adapterEnforcementTitle => 'Mit érvényesít ez az adapter';

  @override
  String get enforcementFiltersToolSurface =>
      'A Control Center választja az eszközöket';

  @override
  String get enforcementInterceptsToolCalls =>
      'Minden hívás kapuzott, mielőtt futna';

  @override
  String get enforcementObservesCompletionContract =>
      'A futtatás a szállítmányához van kötve';

  @override
  String get enforcementNativeToolsInterceptable =>
      'A futtató saját eszközei láthatók';

  @override
  String get enforcementInProcessToolsSandboxed =>
      'A folyamaton belüli eszközök homokozóban vannak';

  @override
  String get enforcementYes => 'Igen';

  @override
  String get enforcementNo => 'Nem';

  @override
  String get adapterEnforcementCaveats => 'Fenntartások';

  @override
  String get enforcementSummaryModesEnforced => 'Érvényesített módok';

  @override
  String get enforcementSummaryModesNotEnforced => 'Nem érvényesített módok';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# fenntartás',
      one: '# fenntartás',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      'A csak olvasható módok nem strukturálisak: a Control Center nem tudja eltávolítani ennek a futtatónak a saját eszközeit.';

  @override
  String get caveatToolCallsNotIntercepted =>
      'Nincs végrehajtás előtti kapu: csak az MCP-eszközhívások mennek át a Control Centeren.';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      'A futtató saját fájl- és shelleszközei soha nem érik el a Control Centert; az OS-homokozó az egyetlen alsó korlát alattuk.';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      'A folyamaton belüli fájleszközök a homokozón kívül futnak, így az eszközfelület az egyetlen fájlrendszer-határ.';

  @override
  String get caveatCompletionContractUnobservable =>
      'A Control Center nem tudja terelni vagy meghiúsítani a futtatást, amely a szállítmánya nélkül ér véget.';

  @override
  String get modeDegraded => 'Csökkentett';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return 'A(z) $mode mód a(z) $adapter adapteren csak a homokozóra támaszkodik; az ügynök saját fájleszközeit nem fogják el.';
  }

  @override
  String get artifactUnavailable => 'Az artifact nem elérhető';

  @override
  String artifactRevisionLabel(int count) {
    return '$count revízió';
  }

  @override
  String get artifactShowMore => 'Több megjelenítése';

  @override
  String get artifactShowLess => 'Kevesebb megjelenítése';

  @override
  String get artifactCopy => 'Másolás';

  @override
  String get artifactCopied => 'Artifact másolva';

  @override
  String get artifactsTabLabel => 'Artifactok';

  @override
  String get artifactsEmptyTitle => 'Még nincsenek artifactok';

  @override
  String get artifactsEmptyBody =>
      'Ha egy ügynök táblázatot, diagramot vagy ábrát tesz ide közzé, az ebben a listában jelenik meg.';

  @override
  String get artifactRevisionPickerLabel => 'Revízió';

  @override
  String get artifactRestoreRevision => 'Revízió visszaállítása';

  @override
  String get artifactOpenInTab => 'Megnyitás lapon';

  @override
  String get artifactTitleFallback => 'Artifact';

  @override
  String get providerGenerationLabel => 'Generálási alapértelmezettek';

  @override
  String get providerGenerationHint =>
      'Hagyjon egy mezőt üresen a végpont saját alapértelmezettjéhez. A modellek saját kimeneti plafonokat és mintavételezési recepteket közölnek; más értékeken szolgálva romolhatnak.';

  @override
  String get providerMaxTokensLabel => 'Max. kimeneti tokenek';

  @override
  String get addModel => 'Modell hozzáadása';

  @override
  String get modelListTitle => 'Modellista';

  @override
  String get railProvidersGroup => 'Szolgáltatók';

  @override
  String get railCustomProvidersGroup => 'Egyéni szolgáltatók';

  @override
  String get editModelSettings => 'Modellbeállítások szerkesztése';

  @override
  String get modelIdLabel => 'Modell-ID';

  @override
  String get modelIdImmutableHint =>
      'Az ID, amelyet a végpont szolgál; listázás után rögzített.';

  @override
  String get contextWindowLabel => 'Kontextusablak';

  @override
  String get inputTypesLabel => 'Bemenettípusok';

  @override
  String get outputTypesLabel => 'Kimenettípusok';

  @override
  String get modalityText => 'Szöveg';

  @override
  String get modalityImage => 'Kép';

  @override
  String get modalityAudio => 'Hang';

  @override
  String get modalityVideo => 'Videó';

  @override
  String get modalityPdf => 'PDF';

  @override
  String get modelOverrideReset => 'Visszaállítás automatikusra';

  @override
  String get modelOverrideEdited => 'Szerkesztve';

  @override
  String get manualModelBadge => 'Kézzel hozzáadva';

  @override
  String get modelIdRequired => 'Adjon meg egy modell-ID-t.';

  @override
  String get modelTokensInvalid => 'Adjon meg pozitív egész token számot.';

  @override
  String get removeModelAction => 'Modell eltávolítása';

  @override
  String removeModelConfirmTitle(String model) {
    return 'Eltávolítja: $model?';
  }

  @override
  String get removeModelConfirmBody =>
      'A modell kikerül a listából, és a rá rögzített ügynökök leállnak. A szolgáltatót nem érinti.';

  @override
  String get addModelProviderTitle => 'Modellszolgáltató hozzáadása';

  @override
  String get addModelProviderDescription =>
      'Állítson be egyéni API-végpontot és a modelljeit.';

  @override
  String get modelListEmptyHint =>
      'Nincsenek beállított modellek. Adjon hozzá egyet a csevegésben való használathoz.';

  @override
  String get addProviderModelsHint =>
      'A modellek élőben töltődnek, amint a végpont válaszol. Csak akkor adjon hozzá kézzel, ha nem tudja listázni a sajátjait.';

  @override
  String get providerTemperatureLabel => 'Hőmérséklet';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved => 'Generálási alapértelmezettek mentve';

  @override
  String get providerGenerationInvalid =>
      'Ellenőrizze az értékeket: a max. kimeneti tokenek és a top-k pozitívak legyenek, a hőmérséklet 0–2, a top-p 0–1.';

  @override
  String get providerGenerationOverridden => 'Felülírva';

  @override
  String get branchNotPushed => 'nincs elküldve';

  @override
  String branchNotOnRemote(String branch) {
    return 'A(z) „$branch” csak ebben a beszélgetésben létezik';
  }

  @override
  String get branchNotOnRemoteHint =>
      'A GitHub még soha nem látta ezt az ágat, így egy pull request még nem használhatja. A közzététel elküldi a worktree-ben már meglévő commitokat — a nem commitolt módosításokat békén hagyja.';

  @override
  String get publishBranch => 'Ág közzététele';

  @override
  String branchPublished(String branch) {
    return 'A(z) „$branch” közzétéve az originre';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return 'Ág közzétéve. $count nem commitolt módosítás nem került bele.';
  }

  @override
  String get composePrLoadingBranches => 'Ágak betöltése a GitHubról…';

  @override
  String get composePrBranchesFailed =>
      'Nem sikerült betölteni az ágakat a GitHubról. Írjon be egy ágnevet, vagy ellenőrizze a GitHub-kapcsolatot.';

  @override
  String get composePrSubtitleFromSpace =>
      'Ennek a beszélgetésnek az ágáról — előbb tegye közzé, ha a GitHub még nem látta';

  @override
  String get obsTabInsights => 'Betekintések';

  @override
  String get obsTabLive => 'Élő';

  @override
  String get obsTabQuality => 'Minőség';

  @override
  String get obsTabUsage => 'Használat';

  @override
  String get obsUsageTotalTokens => 'Összes token';

  @override
  String get obsUsagePeakTokens => 'Csúcs tokenek';

  @override
  String get obsUsageLongestSession => 'Leghosszabb munkamenet';

  @override
  String get obsUsageCurrentStreak => 'Jelenlegi sorozat';

  @override
  String get obsUsageLongestStreak => 'Leghosszabb sorozat';

  @override
  String obsUsageDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# nap',
      one: '# nap',
      zero: '0 nap',
    );
    return '$_temp0';
  }

  @override
  String get obsUsageTokenActivity => 'Token tevékenység';

  @override
  String get obsUsageActivityModeLabel => 'Token tevékenység módja';

  @override
  String get obsUsageModeDaily => 'Napi';

  @override
  String get obsUsageModeWeekly => 'Heti';

  @override
  String get obsUsageModeCumulative => 'Kumulatív';

  @override
  String get obsUsageTimeRange => 'Időtartomány';

  @override
  String get obsUsageTrendTitle => 'Napi token trend';

  @override
  String get obsUsageModelUsage => 'Modellhasználat';

  @override
  String get obsUsageTokensLabel => 'tokenek';

  @override
  String get obsUsageNoActivity => 'Még nincs rögzített tokenhasználat';

  @override
  String get obsUsageOtherModels => 'Egyéb';

  @override
  String obsUsageCellReadout(String date, String tokens) {
    return '$date · $tokens token';
  }

  @override
  String obsUsageActivitySummary(
    String start,
    String end,
    int activeDays,
    String peak,
  ) {
    return 'Token tevékenység $start és $end között. $activeDays aktív nap. Legforgalmasabb nap $peak token.';
  }

  @override
  String get obsScreenSubtitle =>
      'Élő ügynökvezérlés, költség-hozzárendelés, kvóták és minőségi jelek';

  @override
  String get obsRangeLast24h => 'Elmúlt 24 óra';

  @override
  String get obsRangeLast7d => 'Elmúlt 7 nap';

  @override
  String get obsRangeLast30d => 'Elmúlt 30 nap';

  @override
  String get obsRangeAll => 'Teljes időszak';

  @override
  String get obsAddFilter => 'Szűrő hozzáadása';

  @override
  String get obsFilterAgent => 'Ügynök';

  @override
  String get obsFilterModel => 'Modell';

  @override
  String get obsFilterStatus => 'Állapot';

  @override
  String get obsFilterRole => 'Szerep';

  @override
  String get obsKpiTotalRuns => 'Összes futtatás';

  @override
  String get obsKpiTotalCost => 'Összes költség';

  @override
  String get obsKpiErrorRate => 'Hibaarány';

  @override
  String get obsKpiCacheRate => 'Gyorsítótár-arány';

  @override
  String get obsKpiTokensPerSec => 'Token / mp';

  @override
  String get obsKpiAvgLatency => 'Átl. késleltetés';

  @override
  String get obsKpiTtft => 'Idő az első tokenig';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '$delta az előző időszakhoz képest';
  }

  @override
  String get obsChartActivity => 'Tevékenység';

  @override
  String get obsChartCost => 'Költség időben';

  @override
  String get obsLegendRuns => 'Futtatások';

  @override
  String get obsLegendErrors => 'Hibák';

  @override
  String get obsAgentsTitle => 'Ügynökök';

  @override
  String obsShowAllAgents(int count) {
    return 'Mind a $count ügynök megjelenítése';
  }

  @override
  String get obsShowFewerAgents => 'Kevesebb megjelenítése';

  @override
  String get obsRunsTitle => 'Futtatások';

  @override
  String get obsNoRunsInRange => 'Nincs futtatás ebben a tartományban';

  @override
  String get obsColTime => 'Idő';

  @override
  String get obsColAgent => 'Ügynök';

  @override
  String get obsColStatus => 'Állapot';

  @override
  String get obsColModel => 'Modell';

  @override
  String get obsColDuration => 'Időtartam';

  @override
  String get obsColTokens => 'Tokenek';

  @override
  String get obsColCost => 'Költség';

  @override
  String get obsColErrors => 'Hibák';

  @override
  String get obsColRuns => 'Futtatások';

  @override
  String get obsColAvgLatency => 'Átl. késleltetés';

  @override
  String get obsColLastActive => 'Utoljára aktív';

  @override
  String get obsStatusPending => 'Függőben';

  @override
  String get obsStatusRunning => 'Fut';

  @override
  String get obsStatusCompleted => 'Befejezve';

  @override
  String get obsStatusError => 'Hiba';

  @override
  String get obsRosterLoadError =>
      'Nem sikerült betölteni az ügynökök névsorát.';

  @override
  String get obsRosterEmpty => 'Még nincsenek ügynökök';

  @override
  String get obsRosterEmptyDescription =>
      'Osszon ki egy ügynököt, és élőben megjelenik itt — állapot, aktuális eszköz, tokenek, költség.';

  @override
  String get obsKillAgent => 'Ügynök kilövése';

  @override
  String get obsRosterTokensLabel => 'tok';

  @override
  String get obsCostByRoleTitle => 'Költség szerep szerint';

  @override
  String get obsCostByRoleSubtitle =>
      'Hol költ ez a munkaterület, ügynökszerep szerint';

  @override
  String get obsRoleMain => 'Fő';

  @override
  String get obsRoleSubagents => 'Alügynökök';

  @override
  String get obsRoleAdvisor => 'Tanácsadó';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return 'Fő: $main · alügynökök: $sub · tanácsadó: $advisor';
  }

  @override
  String get obsTotal => 'Összesen';

  @override
  String get obsTokenModelTitle => 'Tokenmodell (5 tengely)';

  @override
  String get obsTokenModelSubtitle =>
      'Minden token, amelyet ez a munkaterület elköltött, tengely szerint';

  @override
  String get obsAxisInput => 'Bemenet';

  @override
  String get obsAxisOutput => 'Kimenet';

  @override
  String get obsAxisReasoning => 'Gondolkodás';

  @override
  String get obsAxisCacheRead => 'Gyorsítótár-olvasás';

  @override
  String get obsAxisCacheWrite => 'Gyorsítótár-írás';

  @override
  String get obsTotalTokens => 'Összes token';

  @override
  String get obsCacheDiscountNote =>
      'A gyorsítótár-olvasási tokenek kedvezményesen számlázódnak, így jóval kevesebbe kerülnek, mint ugyanannyi friss bemenet.';

  @override
  String get obsByModelTitle => 'Modell szerint';

  @override
  String get obsByModelSubtitle => 'Token- és költséghasználat modellenként';

  @override
  String get obsNoModelUsage => 'Még nincs rögzített modellhasználat.';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# futtatás',
      one: '# futtatás',
    );
    return '$_temp0';
  }

  @override
  String get obsPerRunTitle => 'Futtatásonként';

  @override
  String get obsPerRunSubtitle => 'Egy futtatás tipikus tokenköltsége';

  @override
  String get obsMedianRunTokens => 'Medián futtatás tokenek';

  @override
  String get obsMedianRunTokensSub => 'Középpont az összes futtatásban';

  @override
  String get obsRunsInWorkspace => 'Ebben a munkaterületben';

  @override
  String get obsCostShare => 'Költségrészesedés';

  @override
  String get obsQuotaConfiguredLimits => 'Beállított korlátok';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      'Használat a beállított plafonokkal szemben, a legrosszabb állapot előre.';

  @override
  String get obsQuotaAddLimit => 'Korlát hozzáadása';

  @override
  String get obsQuotaNoLimits =>
      'Még nincsenek kvótakorlátok — adjon hozzá egyet a plafonhoz viszonyított követéshez.';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return '$title korlát eltávolítása';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return 'Visszaáll $duration múlva · $status';
  }

  @override
  String get obsQuotaUsageWindows => 'Használati ablakok';

  @override
  String get obsQuotaUsageWindowsSubtitle =>
      'Megfigyelt használat minden szolgáltatónál, plafon nélkül.';

  @override
  String get obsQuotaNoUsage => 'Még nincs rögzített használat.';

  @override
  String get obsQuotaTokensUsed => 'Felhasznált tokenek';

  @override
  String get obsQuotaRequests => 'Kérések';

  @override
  String get obsQuotaUnitTokens => 'tokenek';

  @override
  String get obsQuotaUnitRequests => 'kérések';

  @override
  String get obsQuotaUnitCost => 'költség';

  @override
  String get obsQuotaAddLimitTitle => 'Kvótakorlát hozzáadása';

  @override
  String get obsQuotaProviderLabel => 'Szolgáltató';

  @override
  String get obsQuotaWindowLabel => 'Ablak';

  @override
  String get obsQuotaUnitLabel => 'Egység';

  @override
  String obsQuotaLimitLabel(String unit) {
    return 'Korlát ($unit)';
  }

  @override
  String get obsQuotaCentsHint => 'US centben (500 = \$5.00).';

  @override
  String get obsQuotaStatusOk => 'Rendben';

  @override
  String get obsQuotaStatusWarning => 'Figyelmeztetés';

  @override
  String get obsQuotaStatusExhausted => 'Kimerítve';

  @override
  String get obsQuotaStatusUnknown => 'Ismeretlen';

  @override
  String get obsGoalNoActiveTitle => 'Nincs aktív cél';

  @override
  String get obsGoalNoActiveBody =>
      'Állítson be célt, hogy az ügynököknek legyen objektívjük és opcionális tokenkeretük. A futtatások befejeztével a keret telik, és az ügynököket a lezárásra terelik, ha majdnem elfogyott.';

  @override
  String get obsGoalSetGoal => 'Cél beállítása';

  @override
  String get obsGoalTokenBudget => 'Tokenkeret';

  @override
  String obsGoalTokensLeft(String tokens) {
    return '$tokens maradt';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens (nincs beállított keret)';
  }

  @override
  String get obsGoalTokensUsed => 'Felhasznált tokenek';

  @override
  String get obsGoalElapsed => 'Eltelt';

  @override
  String get obsGoalWrapUp => 'Lezárás';

  @override
  String get obsGoalClear => 'Cél törlése';

  @override
  String get obsGoalFallbackTitle => 'Cél';

  @override
  String get obsGoalSubtitle => 'Célmód kerete';

  @override
  String get obsGoalStatusActive => 'Aktív';

  @override
  String get obsGoalStatusPaused => 'Szüneteltetve';

  @override
  String get obsGoalStatusBudgetLimited => 'Keretkorlátozott';

  @override
  String get obsGoalStatusComplete => 'Kész';

  @override
  String get obsGoalStatusDropped => 'Eldobva';

  @override
  String get obsGoalObjectiveLabel => 'Célkitűzés';

  @override
  String get obsGoalBudgetLabel => 'Tokenkeret (nem kötelező)';

  @override
  String get obsGoalSetAction => 'Cél beállítása';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => 'Siker %';

  @override
  String get obsBenchmarkPassed => 'Átment';

  @override
  String get obsBenchmarkFailed => 'Sikertelen';

  @override
  String get obsBenchmarkErrors => 'Hibák';

  @override
  String get obsBenchmarkSpend => 'Költés';

  @override
  String get obsBenchmarkCostPerTask => 'Költség / feladat';

  @override
  String get obsBenchmarkTrials => 'Próbák';

  @override
  String get obsBenchmarkNoTrials => 'Még nincs értékelhető futtatás.';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'És $count további',
      one: 'És 1 további',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => 'Siker';

  @override
  String get obsBenchmarkTrialFail => 'Hiba';

  @override
  String get obsBenchmarkTrialError => 'Hiba';

  @override
  String get obsBenchmarkTrialRunning => 'Fut';

  @override
  String get obsBenchmarkReward => 'Jutalom';

  @override
  String get obsBenchmarkReport => 'Jelentés';

  @override
  String get obsBenchmarkCopyMarkdown => 'Markdown másolása';

  @override
  String get obsBenchmarkCopied => 'Jelentés a vágólapra másolva';

  @override
  String get obsBehaviorCaption =>
      'Ezek a saját üzeneteiből elemzett frusztrációs jelek — a beszélgetés egészségének olvasata, nem az ügynökök pontszáma. Helyben számolva; semmi nem hagyja el ezt az eszközt.';

  @override
  String get obsBehaviorMessagesAnalyzed => 'Elemzett üzenetek';

  @override
  String get obsBehaviorTotalSignals => 'Összes jel';

  @override
  String get obsBehaviorYelling => 'Kiabálás';

  @override
  String get obsBehaviorProfanity => 'Trágárság';

  @override
  String get obsBehaviorAnguish => 'Gyötrelem';

  @override
  String get obsBehaviorNegation => 'Tagadás';

  @override
  String get obsBehaviorRepetition => 'Ismétlés';

  @override
  String get obsBehaviorBlame => 'Hibáztatás';

  @override
  String get obsBehaviorConversationsTitle => 'Legfrusztráltabb beszélgetések';

  @override
  String get obsBehaviorConversationsSubtitle =>
      'Jelsűrűség szerint rangsorolva az üzeneteiben.';

  @override
  String get obsBehaviorNoSignals =>
      'Nem észlelhető frusztrációs jel — sima vitorlázás.';

  @override
  String obsBehaviorMessagesCount(String count) {
    return '$count üzenet elemezve';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '$count jel';
  }

  @override
  String get obsAgentStatusIdle => 'Tétlen';

  @override
  String get obsAgentStatusParked => 'Parkolva';

  @override
  String get obsAgentStatusAborted => 'Megszakítva';

  @override
  String get obsAgentKindSub => 'Al';

  @override
  String get noChecksOnCommit => 'Ezen a commiton még nem futott ellenőrzés.';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fut — $count feladat',
      one: 'Fut — 1 feladat',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Minden ellenőrzés sikeres — $count feladat',
      one: 'Minden ellenőrzés sikeres — 1 feladat',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Befejezve — $count feladat',
      one: 'Befejezve — 1 feladat',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total feladat',
      one: '1 feladat',
    );
    return '$failed / $_temp0 sikertelen';
  }

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# feladat',
      one: '# feladat',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return 'Mátrix: $jobId';
  }

  @override
  String get jobLogsPending =>
      'A naplók itt jelennek meg, amikor a feladat befejeződik.';

  @override
  String get jobLogsUnavailable => 'Ehhez a feladathoz nem érhetők el naplók.';

  @override
  String get noLogsForStep => 'Ehhez a lépéshez nem rögzült napló.';

  @override
  String get jobLogsTruncated =>
      'Napló csonkolva — a legutóbbi kimenet látható.';

  @override
  String get fullLog => 'Teljes napló';

  @override
  String get copyLogs => 'Naplók másolása';

  @override
  String get resizeGraph => 'Húzza a gráf átméretezéséhez';

  @override
  String workflowRunStartedAgo(String time) {
    return 'Elindítva $time';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return 'Befejezve $time';
  }

  @override
  String get chatBridgesTitle => 'Csevegőhidak';

  @override
  String chatProviderDescription(String provider, String command) {
    return 'Említse a botot a(z) $provider felületen, hogy ügynököt tegyen valamire, vagy nyisson jegyeket a(z) $command paranccsal.';
  }

  @override
  String chatConnectProvider(String provider) {
    return '$provider csatlakoztatása';
  }

  @override
  String get chatDisconnectProvider => 'Leválasztás';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$botName itt: $teamName';
  }

  @override
  String get chatStateLive => 'Élő';

  @override
  String get chatStateConnecting => 'Csatlakozás…';

  @override
  String get chatStateError => 'Kapcsolódási hiba';

  @override
  String get chatNotConnected => 'Nincs csatlakoztatva';

  @override
  String chatStreamingUnavailable(String provider) {
    return 'Az élő streamelés ki van kapcsolva ehhez a(z) $provider alkalmazáshoz — a válaszok egy üzenetként érkeznek.';
  }

  @override
  String chatAdminOnly(String provider) {
    return 'Csak admin csatlakoztathatja a(z) $provider szolgáltatást ehhez a munkaterülethez.';
  }

  @override
  String chatConnectHint(String provider) {
    return 'Hozzon létre egy $provider alkalmazást, majd illessze be a hitelesítő adatait ide. A Control Center kifelé csatlakozik a(z) $provider felülethez, így ennek a szervernek nincs szüksége nyilvános címre.';
  }

  @override
  String chatOpenConsole(String provider) {
    return '$provider konzol megnyitása';
  }

  @override
  String get chatOpenSetupGuide => 'Beállítási útmutató';

  @override
  String get chatFieldBotToken => 'Bot token';

  @override
  String get chatFieldAppToken => 'Alkalmazásszintű token';

  @override
  String get chatFieldConfigRefreshToken => 'Alkalmazáskonfigurációs token';

  @override
  String chatFieldOptional(String label) {
    return '$label (nem kötelező)';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return 'A(z) $provider fiókom összekapcsolása';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return 'Kapcsolja össze a(z) $provider fiókját, hogy az onnan küldött üzenetek Önhöz legyenek rendelve.';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return 'Összekapcsolva: $externalUserId';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return 'A(z) $provider fiók összekapcsolása';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return 'Küldje ezt a parancsot a botnak a(z) $provider felületen. Egyszer használható, és 15 perc múlva lejár.';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return 'A(z) $provider fiókja mostantól össze van kapcsolva — az onnan küldött üzenetek Önhöz rendelődnek.';
  }

  @override
  String get chatLinkedAccounts => 'Összekapcsolt fiókok';

  @override
  String chatNoLinkedAccounts(String provider) {
    return 'Még senki sem kapcsolta össze a(z) $provider fiókját.';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# összekapcsolt fiók',
      one: '# összekapcsolt fiók',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '$externalUserId · e-mail alapján párosítva';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '$externalUserId · kóddal összekapcsolva';
  }

  @override
  String get chatUnlink => 'Leválasztás';

  @override
  String get chatCustomizeBot => 'Bot testreszabása';

  @override
  String get chatCustomizeBotDescription =>
      'Nevezze át a botot, módosítsa, mit mond magáról, vagy nevezze át a slash parancsot.';

  @override
  String get chatCustomizeBotUnavailable =>
      'A Control Centernek alkalmazáskonfigurációs tokenre van szüksége a bot szerkesztéséhez. Csatlakozzon újra, és adjon meg egyet.';

  @override
  String chatCreateAppTitle(String provider) {
    return 'A(z) $provider alkalmazás létrehozása';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'A Control Center létrehozhatja Önnek a(z) $provider alkalmazást, a megfelelő jogosultságokkal és eseményekkel. A(z) $provider felületen fejezi be, majd ide illeszti a hitelesítő adatokat.';
  }

  @override
  String get chatCreateApp => 'Alkalmazás létrehozása';

  @override
  String get chatCreateAppCta => 'Alkalmazás létrehozása helyettem';

  @override
  String get chatAppNameLabel => 'Alkalmazás neve';

  @override
  String get chatBotDisplayNameLabel =>
      'Bot neve (amit a tagok az @ után gépelnek)';

  @override
  String get chatDescriptionLabel => 'Rövid leírás';

  @override
  String get chatAgentDescriptionLabel => 'Mit mond a bot, hogy mire képes';

  @override
  String get chatCommandLabel => 'Slash parancs';

  @override
  String get chatDirectMessages => 'Közvetlen üzenetek';

  @override
  String chatDirectMessagesHint(String provider) {
    return 'Lehetővé teszi, hogy a tagok DM-ben csevegjenek a bottal. Fizetős $provider csomagra lehet szükség.';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return 'A(z) $provider létrehozta a(z) $appId alkalmazást.';
  }

  @override
  String chatRemainingSteps(String provider) {
    return 'Néhány lépés maradt, és csak a(z) $provider tudja megtenni őket:';
  }

  @override
  String get chatStepAppToken => 'Alkalmazásszintű token generálása';

  @override
  String get chatStepInstall => 'Az alkalmazás telepítése';

  @override
  String get chatOpenAppSettings => 'Alkalmazásbeállítások megnyitása';

  @override
  String get chatContinueToCredentials => 'Hitelesítő adatok beillesztése';

  @override
  String chatBotUpdated(String provider) {
    return 'Bot frissítve a(z) $provider felületen.';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return 'A(z) $provider módosította az alkalmazás jogosultságait. Telepítse újra az alkalmazást, hogy érvényesüljenek.';
  }

  @override
  String get chatReinstallApp => 'Alkalmazás újratelepítése';

  @override
  String chatIconNotEditable(String provider) {
    return 'A bot ikonját csak a(z) $provider saját alkalmazásbeállításaiban lehet módosítani.';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return 'Maga is létrehozhatja a(z) $provider felületen — token nélkül. A fenti beállítások a hivatkozással utaznak.';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return 'Létrehozás a(z) $provider felületen';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return 'A(z) $provider a böngészőjében nyílt meg, ezzel a konfigurációval előre kitöltve. Hozza létre ott az alkalmazást, majd fejezze be ezeket a lépéseket, és térjen vissza a tokenekkel.';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return 'A(z) $provider nem jelenti, melyik alkalmazást hozta létre, ezért a bot itteni testreszabásához később alkalmazáskonfigurációs token kell.';
  }

  @override
  String get chatStepCreateApp =>
      'Az alkalmazás létrehozása az előre kitöltött konfigurációból';

  @override
  String chatStepCreateAppHint(String provider) {
    return 'Válasszon munkaterületet a(z) $provider felületen, és erősítse meg.';
  }

  @override
  String get chatStepAppTokenHint =>
      'Basic information → app-level tokens, a connections:write hatókörrel.';

  @override
  String get chatStepInstallHint =>
      'Install app → másolja a bot user OAuth tokent.';

  @override
  String get calendarUseBuiltinApp =>
      'A Control Center Google-alkalmazásának használata';

  @override
  String get calendarUseBuiltinAppHint =>
      'Hagyja jóvá a Google-fiókjával. Semmit sem kell beállítani a Google Cloudon.';

  @override
  String get calendarUseOwnClient => 'Saját Google Cloud kliens használata';

  @override
  String get calendarUseOwnClientHint =>
      'Adjon meg egy OAuth-klienst a saját Google Cloud projektjéből.';

  @override
  String get aboutTitle => 'Névjegy';

  @override
  String get aboutAppVersion => 'Alkalmazásverzió';

  @override
  String get aboutServerVersion => 'Csatlakoztatott szerver';

  @override
  String get aboutRpcCatalog => 'RPC-katalógus';

  @override
  String get aboutServerUnknown => 'Nincs jelentve';

  @override
  String get serverStaleTitle =>
      'A csomagolt szerver régebbi, mint ez az alkalmazás';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return 'A futó cc_server $serverVersion, míg ez az alkalmazás $appVersion. Indítsa újra az alkalmazást, hogy felvegye a legújabb csomagolt szerverbuildet; fejlesztésben építse újra a `dart build cli` paranccsal az apps/cc_server mappában.';
  }

  @override
  String get updateCheckButton => 'Frissítések keresése';

  @override
  String get updateChecking => 'Frissítések keresése…';

  @override
  String get updateUpToDate => 'Naprakész';

  @override
  String get updateDeferredBusy =>
      'Van kész frissítés, de egy megbeszélés felvétel alatt van — a vége után kérdez rá.';

  @override
  String get updateOpenedReleasesPage =>
      'A kiadások oldala megnyílt a böngészőben.';

  @override
  String get updateCheckFailed => 'A frissítéskeresés sikertelen';

  @override
  String updateAvailableVersion(String version) {
    return 'A(z) $version verzió elérhető.';
  }

  @override
  String get updateBannerTitle => 'Új Control Center érhető el';

  @override
  String get updateBannerRefresh => 'Frissítés';

  @override
  String get updateBlockedRecording =>
      'A frissítés szünetel, amíg egy megbeszélés felvétel alatt van — a végekor újratöltődik.';

  @override
  String get settingsScopeYou => 'Ön';

  @override
  String get settingsScopeWorkspace => 'Munkaterület';

  @override
  String get settingsScopeServer => 'Szerver';

  @override
  String get settingsProfile => 'Profil és identitás';

  @override
  String get settingsYourDevices => 'Az Ön eszközei';

  @override
  String get settingsWorkspaceGeneral => 'Általános';

  @override
  String get settingsServerConnection => 'Kapcsolat és állapot';

  @override
  String get settingsModelProviders => 'Modellszolgáltatók';

  @override
  String get settingsVoiceModels => 'Hang- és megbeszélésmodellek';

  @override
  String get settingsDiagnostics => 'Diagnosztika és adatvédelem';

  @override
  String get settingsAbout => 'Névjegy';

  @override
  String get settingsScopeBadgeYou => 'ÖN';

  @override
  String get settingsScopeBadgeDevice => 'EZ AZ ESZKÖZ';

  @override
  String get settingsScopeBadgeWorkspace => 'MUNKATERÜLET';

  @override
  String get settingsScopeBadgeServer => 'SZERVER';

  @override
  String get settingsProfileDescription =>
      'Neved, e-mailed és git-identitásod ebben a munkaterületen. Váltáskor ez a réteg is vált; a kezelőnév, bejelentkezés és eszközök a fiókon maradnak.';

  @override
  String get settingsServerConnectionDescription =>
      'Melyik szerverrel beszél ez a kliens, és hogyan van ez a szerver megosztva (mDNS, alagutak, relé).';

  @override
  String get settingsAboutDescription => 'Build-identitás és frissítések.';

  @override
  String get settingsDiagnosticsDescription =>
      'Elszigetelés, indexelés, szinkronizálás, naplózás és összeomlásjelentés ehhez a telepítéshez.';

  @override
  String get settingsWorkspaceGeneralDescription =>
      'Identitás, szabályzat és konvenciók, amelyeket a munkaterület minden tagja megoszt.';

  @override
  String get settingsWorkspaceMeetingsDescription =>
      'Jegyzetsablonok és mentett hangok a munkaterület megbeszéléseihez.';

  @override
  String get settingsWorkspacePolicyLabel => 'Munkaterület-szabályzat';

  @override
  String get settingsWorkspacePolicyDescription =>
      'A munkaterület minden tagjára és minden ügynökére vonatkozik.';

  @override
  String get settingsSecretGlobsLabel => 'Titkos útvonalak kizárása';

  @override
  String get settingsSecretGlobsHelp =>
      'Soronként egy glob. Ezek az útvonalak rejtve maradnak a megtekintők és vendégek elől a kódot hordozó felületeken, a beépített alapértelmezetteken felül.';

  @override
  String get settingsReviewConcurrencyLabel => 'Átnézési szétosztás';

  @override
  String get settingsReviewConcurrencyHelp =>
      'Hány átnéző kerül párhuzamosan kiosztásra, ha nincs explicit szám megadva.';

  @override
  String get settingsReviewLevelLabel => 'Átnézési szint';

  @override
  String get settingsReviewLevelHelp =>
      'Milyen mély az AI-átnézés, és mennyit jelent belőle eleve. Semmi sem vész el — a könnyebb szint a kisebb megállapításokat csoportosítja, nem dobja el őket.';

  @override
  String get reviewLevelLight => 'Könnyű';

  @override
  String get reviewLevelBalanced => 'Kiegyensúlyozott';

  @override
  String get reviewLevelThorough => 'Alapos';

  @override
  String get reviewLevelLightHint =>
      'Egy átnéző. Csak az kerül előre, ami anyagilag számít.';

  @override
  String get reviewLevelBalancedHint =>
      'Három átnéző: QA, architektúra és implementáció.';

  @override
  String get reviewLevelThoroughHint =>
      'Biztonsági és teljesítmény-szakértőket ad, és mindent jelent, amit talált.';

  @override
  String get askAiReviewAtLevel => 'Átnézés más szinten';

  @override
  String reviewNitpicksGroup(int count) {
    return 'Apróságok ($count)';
  }

  @override
  String get reviewFindingResolve => 'Javítva';

  @override
  String get reviewFindingResolveHint =>
      'Jelölje ezt a megállapítást javítottnak. Többé nem számít az átnézés ellen.';

  @override
  String get reviewFindingDismiss => 'Elvetés';

  @override
  String get reviewFindingDismissHint =>
      'Nem valódi probléma. Az átnézők a jövőbeli PR-eken nem jelzik ezt a mintát.';

  @override
  String get reviewFindingReopen => 'Újranyitás';

  @override
  String get reviewFindingStatusUndoLabel => 'Megállapítás állapota';

  @override
  String get reviewFindingDismissTitle => 'Megállapítás elvetése';

  @override
  String get reviewFindingDismissReasonHint =>
      'Miért nem vonatkozik ez? Az átnézők elolvassák.';

  @override
  String reviewFindingStatusFailed(String error) {
    return 'Nem sikerült frissíteni a megállapítást: $error';
  }

  @override
  String get reviewStaleTitle => 'Ez az átnézés elavult';

  @override
  String get reviewStaleBody =>
      'A pull request továbbment, mióta ez az átnézés lefutott. A megállapítások már nem létező kódra mutathatnak.';

  @override
  String reviewStaleReviewedAt(String sha) {
    return 'Átnézve: $sha';
  }

  @override
  String get reviewStaleRerun => 'Átnézés újra';

  @override
  String reviewStaleNotificationTitle(int prNumber) {
    return 'Elavult átnézés a #$prNumber PR-en';
  }

  @override
  String reviewStaleNotificationBody(String title) {
    return 'A(z) $title új commitokat kapott az utolsó átnézés óta.';
  }

  @override
  String get reviewCategorySecurity => 'Biztonság';

  @override
  String get reviewCategoryStability => 'Stabilitás';

  @override
  String get reviewCategoryDataIntegrity => 'Adatintegritás';

  @override
  String get reviewCategoryCorrectness => 'Helyesség';

  @override
  String get reviewCategoryPerformance => 'Teljesítmény';

  @override
  String get reviewCategoryMaintainability => 'Karbantarthatóság';

  @override
  String get reviewEffortQuickWin => 'Gyors nyereség';

  @override
  String get reviewEffortModerate => 'Közepes';

  @override
  String get reviewEffortHeavyLift => 'Nagy munka';

  @override
  String get reviewProposedFix => 'Javasolt javítás';

  @override
  String get reviewAiAgentPrompt => 'Prompt AI-ügynököknek';

  @override
  String get reviewCopyAiPrompt => 'Prompt másolása';

  @override
  String get settingsWorkspaceAdminOnly =>
      'Csak a munkaterület adminjai módosíthatják ezeket.';

  @override
  String get chatMyAccountsTitle => 'Összekapcsolt csevegőfiókok';

  @override
  String get settingsServerSso => 'Egyszeri bejelentkezés';

  @override
  String get settingsServerSsoDescription =>
      'SAML és OpenID Connect bejelentkezés felhasználó-provisioninggel';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabledDescription =>
      'A felhasználók ezzel a szolgáltatóval jelentkezhetnek be';

  @override
  String get ssoEnabledDescriptionOn =>
      'A bejelentkezés élő ehhez a szolgáltatóhoz';

  @override
  String get ssoIdpMetadataLabel => 'IdP-metaadat XML';

  @override
  String get ssoIdpMetadataHint => 'illesze be az IdP EntityDescriptor XML-jét';

  @override
  String get ssoEmailAttributeLabel => 'E-mail attribútum';

  @override
  String get ssoDisplayNameAttributeLabel => 'Megjelenített név attribútum';

  @override
  String get ssoGroupsAttributeLabel => 'Csoportok attribútum';

  @override
  String get ssoIssuerLabel => 'Kibocsátó URL';

  @override
  String get ssoClientIdLabel => 'Kliens-ID';

  @override
  String get ssoGroupsClaimLabel => 'Csoportok claim';

  @override
  String get ssoAutoMemberLabel =>
      'Felhasználók hozzáadása minden munkaterülethez az első bejelentkezéskor';

  @override
  String get ssoAutoMemberDescription =>
      'Kapcsolja ki, ha munkaterületenként meghívó kell';

  @override
  String get ssoAllowJitLabel =>
      'Ismeretlen felhasználók provisionálása az első bejelentkezéskor';

  @override
  String get ssoAllowJitDescription =>
      'Kapcsolja ki, ha a meglévő fiók nélküli felhasználókat el kell utasítani';

  @override
  String get ssoAllowIdpInitiatedLabel =>
      'Kéretlen (IdP-indított) bejelentkezés elfogadása';

  @override
  String get ssoAllowIdpInitiatedDescription =>
      'Szigorúan azokhoz az IdP-portálokhoz, amelyek közvetlenül indítanak alkalmazásokat';

  @override
  String get ssoWantResponseSignedLabel => 'Aláírt válaszboríték megkövetelése';

  @override
  String get ssoWantResponseSignedDescription =>
      'Az assertion aláírások mindig kötelezők';

  @override
  String get ssoTestConnectionButton => 'Kapcsolat tesztelése';

  @override
  String get ssoTestConnectionOk => 'A kapcsolat működik:';

  @override
  String get ssoCopySpMetadata => 'SP-metaadat másolása';

  @override
  String get ssoCopySpMetadataDone => 'SP-metaadat a vágólapra másolva';

  @override
  String get ssoSavedToast => 'Egyszeri bejelentkezés beállításai mentve';

  @override
  String get ssoUnavailable =>
      'Ez a szerver nem teszi közzé az egyszeri bejelentkezés beállításait. Frissítse a szerverbinárist, és próbálja újra.';

  @override
  String get ssoScimCardTitle => 'Felhasználó-provisioning (SCIM)';

  @override
  String get ssoScimDescription =>
      'Irányítsa az identitásszolgáltató SCIM-csatlakozóját az alábbi végpontra egy bearer tokennel. A deprovisioning másodperceken belül visszavonja a munkameneteket és a munkaterület-hozzáférést. A szervernek elérhetőnek kell lennie az IdP számára (alagút vagy nyilvános URL).';

  @override
  String get ssoScimEndpoint => 'SCIM-végpont';

  @override
  String get ssoScimEndpointUnknownOrigin =>
      'Először állítsa be a szerver nyilvános URL-jét, vagy engedélyezzen alagutat';

  @override
  String get ssoScimRegenerate => 'Token újragenerálása';

  @override
  String get ssoScimRegenerateConfirm =>
      'Új SCIM bearer tokent generál? Az előző token azonnal érvénytelen lesz.';

  @override
  String get ssoScimTokenTitle => 'Bearer token';

  @override
  String get ssoScimTokenPresent => 'Van beállított token';

  @override
  String get ssoScimTokenAbsent =>
      'Még nincs token — generáljon egyet a SCIM engedélyezéséhez';

  @override
  String get ssoScimTokenOnce => 'SCIM-token (egyszer jelenik meg)';

  @override
  String ssoSignInWith(String provider) {
    return 'Bejelentkezés ezzel: $provider';
  }

  @override
  String get ssoProbeFailed =>
      'Nem sikerült elérni azt a szervert az egyszeri bejelentkezéshez';

  @override
  String get ssoOpensBrowser =>
      'Megnyitja a böngészőt a bejelentkezés befejezéséhez';

  @override
  String get ssoWaitingForBrowser =>
      'Várakozás, hogy a böngésző befejezze a bejelentkezést…';

  @override
  String get ssoBrowserOpenFailed =>
      'Nem sikerült megnyitni a böngészőt az egyszeri bejelentkezéshez';

  @override
  String get ssoUseManualPairing =>
      'Bejelentkezés meghívóval vagy párosítási kulccsal helyette';

  @override
  String get ssoHideManualPairing => 'Kézi párosítás elrejtése';

  @override
  String get ssoClientIdHint =>
      'Nyilvános (PKCE) kliens — nincs szükség titokra';

  @override
  String get ssoClientSecretLabel => 'Kliens titok (nem kötelező)';

  @override
  String get ssoClientSecretHintUnset => 'Csak bizalmas IdP-kliensekhez kell';

  @override
  String get ssoClientSecretHintSet =>
      'Van tárolt titok — hagyja üresen a megtartásához';

  @override
  String get ssoPairingToggle =>
      'Kézi párosítás engedélyezése (meghívókódok és párosítási kulcsok)';

  @override
  String get ssoPairingToggleDescription =>
      'Kapcsolja ki, hogy a csatlakozás csak egyszeri bejelentkezéssel történjen — az új eszközök SSO-bejelentkezéseken keresztül érkeznek; a meglévők tovább működnek';

  @override
  String get ssoPairConfirmTitle => 'Csatlakozik a szerverhez?';

  @override
  String ssoPairConfirmBody(String server) {
    return 'Bejelentkezési hitelesítő adat érkezett a(z) $server szerverhez, de ebből az alkalmazásból nem indult bejelentkezés. Csatlakozik ehhez a szerverhez?';
  }

  @override
  String get ssoPairConfirmConnect => 'Csatlakozás';

  @override
  String get ssoPairConfirmCancel => 'Mellőzés';

  @override
  String get forgeConnections => 'Kódtárhely';

  @override
  String get connect => 'Csatlakozás';

  @override
  String get disconnect => 'Leválasztás';

  @override
  String get notConnected => 'Nincs csatlakoztatva';

  @override
  String get checkingConnection => 'Kapcsolat ellenőrzése…';

  @override
  String get fromEnvironment => 'a környezetből';

  @override
  String forgeTokenTitle(String forge) {
    return '$forge token';
  }

  @override
  String get settingsAudio => 'Hang';

  @override
  String get settingsAudioDescription =>
      'Mikrofon, diktálás, megbeszélésészlelés és hangtájkimenet.';

  @override
  String get audioDevicesSection => 'Hangeszközök';

  @override
  String get voiceInputBehaviorSection => 'Diktálás és megbeszélések';

  @override
  String get audioOutputDeviceTitle => 'Kimeneti eszköz';

  @override
  String get audioOutputDefaultHint =>
      'Minden alkalmazáshang a rendszer alapértelmezett kimenetén szól.';

  @override
  String get audioOutputGone =>
      'A kijelölt kimeneti eszköz már nincs csatlakoztatva — a rendszer alapértelmezettje van használatban, amíg másikat nem választ.';

  @override
  String get reviewHubIntroBody =>
      'Az ügynökök elemzik a diffet, feltérképezik a változási területeket, és konszenzusos ítéletre jutnak.';

  @override
  String get reviewHubAlreadyRunning =>
      'Ehhez a pull requesthoz már fut egy átnézés';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return 'Az utolsó átnézés óta: $resolved megoldva · $added új · $open még nyitott';
  }

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return 'Korábban átnézve: $sha';
  }

  @override
  String reviewArtifactFixAll(int count) {
    return '$count megállapítás javítása';
  }

  @override
  String reviewArtifactFixSelected(int count) {
    return '$count kijelölt javítása';
  }

  @override
  String reviewArtifactCommentSelected(int count) {
    return '$count kijelölt megjegyzése';
  }

  @override
  String get webConnectTitle => 'Csatlakozás a Control Centerhez';

  @override
  String get webConnectSubtitle =>
      'Csatlakozzon egy futó cc-serverhez WebSocketen. A kulcsa ezen az eszközön marad.';

  @override
  String get webConnectServerLabel => 'Szerver';

  @override
  String get webConnectDeviceIdLabel => 'Eszköz-ID';

  @override
  String get webConnectPairingKeyLabel => 'Párosítási kulcs';

  @override
  String get webConnectPairingKeyHint => 'illesze be a PSK-t';

  @override
  String get webConnectStayConnected => 'Maradjon csatlakozva ezen az eszközön';

  @override
  String get webConnectStayConnectedDetail =>
      'Maradjon csatlakozva ezen az eszközön (a kulcsot ebben a böngészőben tárolja)';

  @override
  String failedToCreateWorkspace(String error) {
    return 'Nem sikerült létrehozni a munkaterületet: $error';
  }

  @override
  String committedRelative(String relative) {
    return 'commitolva $relative';
  }

  @override
  String get selectAgents => 'Ügynökök kiválasztása';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# ügynök',
      one: '# ügynök',
    );
    return '$_temp0';
  }

  @override
  String get newConversation => 'Új beszélgetés';

  @override
  String get untitledConversation => 'Névtelen beszélgetés';

  @override
  String get conversationTitleOptionalHint =>
      'Nem kötelező — hagyja üresen, és a címmodell automatikusan elnevezi';

  @override
  String get conversationTitlesSectionTitle => 'Beszélgetéscímek';

  @override
  String get conversationTitlesSectionCaption =>
      'Válassza ki a futtatót, amely ebben a munkaterületben automatikusan elnevezi az új beszélgetéseket. A címek ki vannak kapcsolva, amíg nincs adapter kiválasztva, és minden tagra vonatkoznak.';

  @override
  String get conversationTitlesModelLabel => 'Címmodell';

  @override
  String get conversationTitlesAdapterLabel => 'Adapter';

  @override
  String get conversationTitlesAdapterHint => 'Ki';

  @override
  String get conversationTitlesAdapterOff => 'Ki';

  @override
  String get startThread => 'Szál indítása';

  @override
  String get deleteSpaceConfirm => 'Törli ezt a teret? Minden üzenet elvész.';

  @override
  String threadTabTitle(String title) {
    return 'Szál: $title';
  }

  @override
  String threadReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# válasz',
      one: '# válasz',
    );
    return '$_temp0';
  }

  @override
  String threadLastReply(String time) {
    return 'Utolsó válasz $time';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Bejelentkezés ezzel: $provider';
  }

  @override
  String get signInAgain => 'Bejelentkezés újra';

  @override
  String get signInNotFinished =>
      'A bejelentkezés még nem tért vissza. Fejezze be a böngészőjében, majd ellenőrizze újra.';

  @override
  String get signedOutTitle => 'Ki van jelentkezve';

  @override
  String get signedOutSubtitle =>
      'A kódtárhely-kapcsolata már nem érvényes — a token lejárt, vagy a hozzáférését visszavonták. Semmi más nem változott: jelentkezzen be újra, és minden ott van, ahol hagyta.';

  @override
  String get viaServerApp => 'ennek a szervernek az alkalmazásán keresztül';

  @override
  String get ticketing => 'Jegykezelés';

  @override
  String get ticketingProviderHelp =>
      'Hol élnek a jegyei. A helyi a Control Centerben tartja őket.';

  @override
  String providerComingSoon(String provider) {
    return '$provider (hamarosan)';
  }

  @override
  String get ticketProviderLocal => 'Helyi';

  @override
  String get addKey => 'Kulcs hozzáadása';

  @override
  String get providerApps => 'Szolgáltatói alkalmazások';

  @override
  String get providerAppsDescription =>
      'A munkaterületek öröklik ezt a GitHub Appot, hacsak nem másik Appot vagy személyes tokent választanak. A háttérmunka — webhookok, lekérdezés, szinkron — az app-on fut, soha egy személy tokenjén.';

  @override
  String get providerAppId => 'Alkalmazás-ID';

  @override
  String get providerPrivateKey => 'Privát kulcs';

  @override
  String get providerClientId => 'Kliens-ID';

  @override
  String get providerClientSecret => 'Kliens titok';

  @override
  String get providerApiKey => 'API-kulcs';

  @override
  String get providerCallbackUrl => 'Callback URL';

  @override
  String get providerAppFullyConfigured =>
      'A szerver tud magaként viselkedni, és az emberek bejelentkezhetnek.';

  @override
  String get providerAppServerOnly =>
      'A szerver tud magaként viselkedni. Adjon hozzá kliens-ID-t és titkot, hogy az emberek bejelentkezhessenek.';

  @override
  String get providerAppSignInOnly =>
      'Az emberek bejelentkezhetnek. A háttérmunka a hitelesítő adataikra esik vissza.';

  @override
  String providerAppInstalledOn(String accounts) {
    return 'A hitelesítő adatok működnek. Telepítve: $accounts';
  }

  @override
  String deviceCodeInstructions(String provider) {
    return 'Adja meg ezt a kódot a(z) $provider oldalon, amely épp megnyílt. A vágólapra másolódott.';
  }

  @override
  String get deviceCodeWaiting => 'Várakozás, hogy befejezze a böngészőben…';

  @override
  String get copyCodeAndOpen => 'Kód másolása és megnyitás';

  @override
  String get couldNotOpenBrowser =>
      'Nem sikerült böngészőt nyitni. Másolja a hivatkozást, és fejezze be a bejelentkezést maga.';

  @override
  String get contextUsage => 'Kontextushasználat';

  @override
  String get contextUsageFull => 'tele';

  @override
  String get contextUsageTokens => 'tokenek';

  @override
  String get contextSeeMore => 'Több megjelenítése';

  @override
  String get contextSegmentSystemPrompt => 'Rendszerprompt';

  @override
  String get contextSegmentRules => 'Szabályok';

  @override
  String get contextSegmentSkills => 'Készségek';

  @override
  String get contextSegmentToolDefinitions => 'Eszközdefiníciók';

  @override
  String get contextSegmentMcpTools => 'MCP- és dinamikus eszközök';

  @override
  String get contextSegmentDeferredTools => 'Igény szerint betöltött eszközök';

  @override
  String get contextSegmentSubagents => 'Alügynök-definíciók';

  @override
  String get contextSegmentMemory => 'Memória';

  @override
  String get contextSegmentConversation => 'Beszélgetés';

  @override
  String get contextExplorerTitle => 'Kontextus';

  @override
  String get contextExplorerEverything => 'Minden';

  @override
  String get contextExplorerSelectPart =>
      'Válasszon egy részt a tartalmának megtekintéséhez';

  @override
  String get contextExplorerUnavailable => 'A kontextusbontás nem elérhető';

  @override
  String get contextRetry => 'Újrapróbálás';

  @override
  String get settingsFieldOptional => 'Nem kötelező';

  @override
  String get settingsFilterHint => 'Lista szűrése';

  @override
  String get settingsValueNotAvailable => 'Még nem elérhető';

  @override
  String get settingsNoEntriesYet => 'Még nincs itt semmi';

  @override
  String get settingsChangedBadge => 'Módosítva';

  @override
  String get ssoConnectionCardDescription =>
      'Válassza ki, hogyan jelentkeznek be az emberek erre a szerverre, majd kapcsolja be azt a kapcsolatot.';

  @override
  String get ssoUseSamlForSignIn => 'SAML használata a bejelentkezéshez';

  @override
  String get ssoUseOidcForSignIn =>
      'OpenID Connect használata a bejelentkezéshez';

  @override
  String get ssoSaveConnection => 'Kapcsolat mentése';

  @override
  String get ssoStateLive => 'Élő';

  @override
  String get ssoStateConfiguredOff => 'Beállítva, ki';

  @override
  String get ssoStateOnIncomplete => 'Be, hiányos';

  @override
  String get ssoStateActive => 'Aktív';

  @override
  String get ssoStateAllowed => 'Engedélyezve';

  @override
  String get ssoStateNoToken => 'Nincs token';

  @override
  String get ssoSummaryDirectorySync => 'Címtár-szinkron';

  @override
  String get ssoSummaryManualPairing => 'Kézi párosítás';

  @override
  String get ssoNoMethodLiveNote =>
      'Nincs élő bejelentkezési mód. Az új eszközök meghívóval vagy párosítási kulccsal csatlakoznak, amíg be nem állít egy kapcsolatot, és be nem kapcsolja.';

  @override
  String get ssoMethodSamlBlurb =>
      'SAML 2.0-t beszélő identitásszolgáltatókhoz, például Okta, Entra ID vagy Google Workspace.';

  @override
  String get ssoMethodOidcBlurb =>
      'OpenID Connectet beszélő identitásszolgáltatókhoz. Általában a kettő közül az egyszerűbben beállítható.';

  @override
  String get ssoGroupIdentityProvider => 'Identitásszolgáltató';

  @override
  String get ssoGroupIdentityProviderSamlDescription =>
      'Honnan jönnek az assertionök, és hogyan ellenőrzi őket ez a szerver.';

  @override
  String get ssoGroupIdentityProviderOidcDescription =>
      'Melyik kibocsátót bízza meg ez a szerver, és melyik kliensként hitelesít.';

  @override
  String get ssoSpEntityIdShortLabel => 'SP entity ID';

  @override
  String get ssoSpEntityIdDescription =>
      'Hagyja üresen, hogy a szerver URL-jéből származtassa.';

  @override
  String get ssoIssuerDescription =>
      'Az alap-URL, amely a szolgáltató discovery dokumentumát szolgálja.';

  @override
  String get ssoSecretStored => 'Tárolva';

  @override
  String get ssoGroupHandoff =>
      'Amire az identitásszolgáltatójának szüksége van';

  @override
  String get ssoGroupHandoffDescription =>
      'Illessze be ezeket a szolgáltatónál létrehozott alkalmazásba.';

  @override
  String get ssoOriginUnknownTitle =>
      'Ez a szerver nem ismeri a nyilvános URL-jét';

  @override
  String get ssoOriginUnknownBody =>
      'A bejelentkezési és callback URL-ek ebből épülnek, így a szolgáltatója addig nem éri el ezt a szervert, amíg nincs beállítva. Adjon hozzá nyilvános URL-t, vagy engedélyezzen alagutat: Szerver → Kapcsolat.';

  @override
  String get ssoAcsUrlLabel => 'Assertion consumer service (ACS) URL';

  @override
  String get ssoAcsUrlDescription =>
      'Ahová a szolgáltatója az aláírt assertiont POST-olja.';

  @override
  String get ssoSpEntityIdResolvedLabel => 'Szolgáltatói entity ID';

  @override
  String get ssoMetadataUrlLabel => 'SP-metaadat URL';

  @override
  String get ssoMetadataUrlDescription =>
      'A metaadatot importáló szolgáltatók innen is lekérhetik.';

  @override
  String get ssoRedirectUriLabel => 'Redirect URI';

  @override
  String get ssoRedirectUriDescription =>
      'Adja hozzá a szolgáltatója alkalmazásának engedélyezett redirect URI-jaihoz.';

  @override
  String get ssoSignInUrlLabel => 'Bejelentkezési URL';

  @override
  String get ssoSignInUrlDescription =>
      'Küldje ide az embereket az egyszeri bejelentkezés indításához.';

  @override
  String get ssoGroupAttributeMapping => 'Attribútum-leképezés';

  @override
  String get ssoGroupAttributeMappingDescription =>
      'Melyik claim viszi az egyes mezőket. Tartsa az alapértelmezetteket, hacsak a szolgáltatója nem nevezi át őket.';

  @override
  String get ssoGroupAccess => 'Hozzáférés és szerepek';

  @override
  String get ssoGroupAccessDescription =>
      'Mit tehet az, aki sikeresen bejelentkezik.';

  @override
  String get ssoDefaultRoleShortLabel => 'Alapértelmezett szerep';

  @override
  String get ssoDefaultRoleDescription =>
      'Annak jár, akinek a csoportjai egyik alábbi leképezésre sem illeszkednek.';

  @override
  String get ssoRoleMapShortLabel => 'Csoport–szerep leképezés';

  @override
  String get ssoRoleMapDescription =>
      'Az első illeszkedő csoport nyer. Tulajdonos így nem adható.';

  @override
  String get ssoRoleMapGroupHint => 'Csoportnév a szolgáltatójától';

  @override
  String get ssoRoleMapAdd => 'Leképezés hozzáadása';

  @override
  String get ssoRoleMapEmpty =>
      'Nincsenek leképezések — mindenki az alapértelmezett szerepet kapja.';

  @override
  String get ssoAdvancedSummary =>
      'Óraeltérés, IdP-indított bejelentkezés, aláírási szabályzat';

  @override
  String get ssoClockSkewShortLabel => 'Óraeltérés';

  @override
  String get ssoClockSkewDescription =>
      'Tűrés másodpercben az assertion időbélyegein. A 90 a legtöbb szolgáltatónak megfelel.';

  @override
  String get ssoScimGenerate => 'Token generálása';

  @override
  String get ssoScimTokenOnceBody =>
      'A vágólapra másolódott. Egyszer jelenik meg, és nem állítható vissza, ezért illessze be most a szolgáltatójába.';

  @override
  String get ssoPairingCardTitle => 'Kézi párosítás';

  @override
  String get ssoPairingCardDescription =>
      'A másik út erre a szerverre: meghívókódok és párosítási kulcsok, azoknak az eszközöknek, amelyek nem mennek át egyszeri bejelentkezésen.';

  @override
  String settingsCountOfTotal(int count, int total) {
    return '$count / $total';
  }

  @override
  String get providersNoneConnectedNote =>
      'Nincs csatlakoztatott szolgáltató, így a beépített ügynök-futtatókörnyezetnek nincs mire futnia. Adjon hozzá API-kulcsot, vagy jelentkezzen be egyikhez lent.';

  @override
  String get providersFilterHint => 'Szolgáltatók szűrése';

  @override
  String get providersNoneMatch => 'Semmi sem illeszkedik erre a szűrőre';

  @override
  String get providerDeniedHereTitle => 'Tiltva ebben a munkaterületben';

  @override
  String get providerDeniedHereBody =>
      'Az itteni ügynökök nem használhatják ezt a szolgáltatót, még ha csatlakoztatva is van. A többi munkaterületet nem érinti.';

  @override
  String get providerNeedsSignIn =>
      'Jelentkezzen be a szolgáltató használatához';

  @override
  String get providerNeedsApiKey =>
      'Adjon hozzá API-kulcsot a szolgáltató használatához';

  @override
  String get providerApiKeyLabel => 'API-kulcs';

  @override
  String get providerGenerationDefaults => 'Szolgáltatói alapértelmezettek';

  @override
  String get providerNoModelsYet =>
      'Még nincsenek jelentett modellek. Csatlakoztassa a szolgáltatót, majd szinkronizáljon.';

  @override
  String get providerModelsFilterHint => 'Modellek szűrése';

  @override
  String get adaptersNoneReadyNote =>
      'A katalógusban szereplő futtató-CLI-k egyike sem található ezen a gépen. Telepítsen egyet, majd frissítsen.';

  @override
  String get adaptersFilterHint => 'Futtatók szűrése';

  @override
  String get adaptersLaunchGroup => 'Indítás';

  @override
  String get adaptersLaunchGroupDescription =>
      'Mit kap ez a futtató, amikor egy ügynök elindítja. Ezeket a CLI telepítése előtt is beállíthatja.';

  @override
  String get adaptersEnvNone => 'Nincs beállítva';

  @override
  String adaptersEnvCount(int count) {
    return '$count beállítva';
  }

  @override
  String get adapterArgumentsDescription =>
      'Minden indításkor a futtató parancssorához fűződik.';

  @override
  String get defaultChatDescription =>
      'Az új beszélgetéseket és minden saját futtató nélküli ügynököt futtat.';

  @override
  String get shortTaskDescription =>
      'Gyors háttérmunkát futtat, például címeket és összefoglalókat. Ide egy kisebb modell tartozik.';

  @override
  String get settingsStateFailed => 'Sikertelen';

  @override
  String get providerAppsGroupServer => 'A szerverként viselkedés';

  @override
  String get providerAppsGroupServerDescription =>
      'Azok a munkaterületek, amelyek öröklik az installáció GitHub Appját. Saját App vagy PAT a Munkaterület → Általános alatt állítható.';

  @override
  String get providerAppsGroupPrConversations => 'Pull request beszélgetések';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      'Hogyan beszélnek a fejlesztők a szerverrel GitHubon az öröklő munkaterületeken. Saját App-os munkaterület botja a Munkaterület → Általános alatt van. Webhook és nyilvános URL nélkül — a szerver lekérdez.';

  @override
  String get providerAppBotLogin => 'Bot bejelentkezési név';

  @override
  String get providerAppBotLoginEmpty =>
      'Tesztelje a kapcsolatot a bot bejelentkezési nevének feloldásához.';

  @override
  String get providerAppAskOnGitHub => 'Kérés a GitHubon';

  @override
  String get providerAppAskOnGitHubHint =>
      'Említse a fenti bot bejelentkezési nevet egy pull request megjegyzésben — a [bot] utótag opcionális — átnézés vagy kérdés kéréséhez, válaszoljon az átnézési szálaiban, vagy adja hozzá az `ai-review` címkét átnézés kéréséhez.';

  @override
  String get providerAppsGroupSignIn => 'Emberek bejelentkeztetése';

  @override
  String get providerAppsGroupSignInDescription =>
      'Lehetővé teszi, hogy minden tag a saját fiókját csatlakoztassa, és saját hitelesítő adatot kapjon.';

  @override
  String get providerAppCapActsAsServer => 'Szerverként viselkedik';

  @override
  String get providerAppCapSignsIn => 'Bejelentkezteti az embereket';

  @override
  String get portLabel => 'Port';

  @override
  String get mcpNoTokenWarning =>
      'Token nélkül minden, ami eléri ezt a portot, minden eszközt meghívhat.';

  @override
  String get mcpBridgedToolsLabel => 'Eszközök';

  @override
  String get guardrailFamilyFiles => 'Fájlok';

  @override
  String get guardrailFamilyGit => 'Git és pull requestek';

  @override
  String get guardrailFamilyMachine => 'Gép és hálózat';

  @override
  String get guardrailFamilyControl => 'Titkok és munkaterület';

  @override
  String get guardrailScopeFieldLabel => 'Szabályok szerkesztése ehhez';

  @override
  String get guardrailScopeFieldDescription =>
      'A szűkebb hatókör nyer a szélesebbel szemben. Az itt beállított szabályok az örököltekre rakódnak.';

  @override
  String get guardrailSetHere => 'Itt beállítva';

  @override
  String get guardrailClearAllHere => 'Mind törlése';

  @override
  String get sandboxingCardLabel => 'Homokozó';

  @override
  String get sandboxingCardDescription =>
      'Az ügynökmunka el van-e szigetelve ettől a hoszttól, és mit érhet el még egy elszigetelt ügynök.';

  @override
  String get sandboxBackendNoneActive => 'Hoszt, nincs elszigetelés';

  @override
  String get sandboxSummaryHost => 'Hoszt';

  @override
  String get sandboxGroupIsolation => 'Elszigetelés';

  @override
  String get sandboxGroupIsolationDescription =>
      'Hol történnek ténylegesen az ügynök folyamatai és fájlírásai.';

  @override
  String get sandboxBackendFieldDescription =>
      'Az Auto a legerősebbet választja, amit ez a hoszt támogat. Rögzítsen egyet, hogy ne változzon a háta mögött.';

  @override
  String get sandboxCapabilitiesDescription =>
      'A határon ütött lyukak. Mindegyik valami, amit egy elszigetelt ügynök még tehet a külvilággal.';

  @override
  String get sandboxSummaryInForce => 'Érvényben';

  @override
  String get rigsInstallHintLabel => 'Hogyan telepítse';

  @override
  String get rigsStarting => 'Indítás';

  @override
  String get rigsResidentMemory => 'Rezidens memória';

  @override
  String get installedLabel => 'Telepítve';

  @override
  String get notInstalledLabel => 'Nincs telepítve';

  @override
  String ssoOtherKindUnsaved(String method) {
    return 'A(z) $method mentetlen módosításokat tartalmaz';
  }

  @override
  String get collapseComment => 'Megjegyzés összecsukása';

  @override
  String get expandComment => 'Megjegyzés kinyitása';

  @override
  String get suggestedChange => 'Javasolt módosítás';

  @override
  String get emptyComment => 'Üres megjegyzés';

  @override
  String repliesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# válasz',
      one: '# válasz',
    );
    return '$_temp0';
  }

  @override
  String get pendingReview => 'Függő átnézés';

  @override
  String failedToResolveConversation(String error) {
    return 'Nem sikerült frissíteni a beszélgetést: $error';
  }

  @override
  String get addSingleComment => 'Egyetlen megjegyzés hozzáadása';

  @override
  String get addToReview => 'Hozzáadás az átnézéshez';

  @override
  String get startAReview => 'Átnézés indítása';

  @override
  String get reviewNeedsABody =>
      'Először írjon összefoglalót, vagy soroljon fel egy sorközi megjegyzést';

  @override
  String get reviewSubmitted => 'Átnézés elküldve';

  @override
  String get finishYourReview => 'Átnézés befejezése';

  @override
  String get commentVerdict => 'Megjegyzés';

  @override
  String pendingCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# függő megjegyzés',
      one: '# függő megjegyzés',
    );
    return '$_temp0';
  }

  @override
  String andNMore(int count) {
    return 'és $count további';
  }

  @override
  String get queuedCommentHint =>
      'Ez a megjegyzés akkor megy ki, amikor elküldi az átnézését.';

  @override
  String commentOnLinesRange(int start, int end) {
    return '$start–$end. sor';
  }

  @override
  String get claudeAccountsTitle => 'Claude Code fiókok';

  @override
  String get claudeAccountsDescription =>
      'Minden fiók külön Claude Code bejelentkezés. A futtatások a lent csatolt fiókokat használják, ebben a sorrendben.';

  @override
  String get claudeAccountsEmpty => 'Még nincsenek fiókok';

  @override
  String get claudeAccountAdd => 'Fiók hozzáadása';

  @override
  String get claudeAccountSignIn => 'Bejelentkezés';

  @override
  String get claudeAccountSignInAgain => 'Bejelentkezés újra';

  @override
  String get claudeAccountSignInHint =>
      'Futtassa ezt egy terminálban a szerveren. Böngészőt nyit a bejelentkezés befejezéséhez, és a hitelesítő adatot ebbe a fiók könyvtárába írja.';

  @override
  String get claudeAccountSignedOut => 'Kijelentkezve';

  @override
  String get claudeAccountExpired => 'A bejelentkezés lejárt';

  @override
  String claudeAccountExpiredDetail(String when) {
    return 'A bejelentkezés $when időpontban járt le. Jelentkezzen be újra a fiók használatához.';
  }

  @override
  String get claudeAccountMakeDefault => 'Alapértelmezetté tétel';

  @override
  String get claudeAccountDefault => 'Alapértelmezett';

  @override
  String claudeAccountRemoveConfirm(String label) {
    return 'Eltávolítja: $label?';
  }

  @override
  String get claudeAccountRemoveDetail =>
      'Ez kijelentkezteti a fiókot, és törli a könyvtárát a szerveren. Magát a bejelentkezést nem érinti.';

  @override
  String claudeAccountStatusUnknown(String error) {
    return 'Nem sikerült ellenőrizni ezt a fiókot: $error';
  }

  @override
  String claudeAccountUsedPercent(String percent) {
    return '$percent% felhasználva';
  }

  @override
  String get accountPoolStrategy => 'Forgatás';

  @override
  String get accountPoolPinned => 'Rögzített';

  @override
  String get accountPoolRoundRobin => 'Körbenforgó';

  @override
  String get accountPoolSerial => 'Egyszerre egy';

  @override
  String get accountPoolPinnedHint =>
      'Mindig az első fiókon kezd. A többiek tartalékként maradnak, ha az sikertelen.';

  @override
  String get accountPoolRoundRobinHint =>
      'A futtatásokat szétosztja a fiókok között, minden kiosztáskor a következőre lépve.';

  @override
  String get accountPoolSerialHint =>
      'Merítse ki az első fiókot, mielőtt a következőhöz nyúlna.';

  @override
  String get accountPoolMoveUp => 'Mozgatás fel';

  @override
  String get accountPoolMoveDown => 'Mozgatás le';

  @override
  String get accountPoolUsingAll =>
      'Még semmi sincs csatolva — minden fiók használatban van, ebben a sorrendben.';

  @override
  String get accountPoolInheriting => 'A munkaterület fiókjainak öröklése.';

  @override
  String get accountPoolResetToWorkspace =>
      'Visszaállítás a munkaterület fiókjaira';

  @override
  String accountPoolCoolingOff(String when) {
    return 'kvótán kívül eddig: $when';
  }

  @override
  String get accountPoolSignedOut => 'kijelentkezve';

  @override
  String get accountPoolExpired => 'a bejelentkezés lejárt';

  @override
  String accountPoolLoadFailed(String error) {
    return 'Nem sikerült betölteni a forgatást: $error';
  }

  @override
  String get providerSignedInAccount => 'bejelentkezett fiók';

  @override
  String get agentAccountsTab => 'Fiókok';

  @override
  String get agentClaudeAccountsNoticeTitle => 'Több Claude Code fiók';

  @override
  String agentClaudeAccountsNoticeBody(int count) {
    return 'Ez a futtató a hoszt $count Claude Code fiókja közül egyikként jelentkezik be. Válassza ki, melyiket, vagy forogjon közöttük a Fiókok lapon.';
  }

  @override
  String get agentAccountsDescription =>
      'Mely fiókokat használják ennek az ügynöknek a futtatásai. Minden blokk a munkaterület választását örökli kezdetben.';

  @override
  String get agentAccountsNothingToRotate =>
      'Nincs mit forgatni — előbb csatlakoztasson egy második fiókot vagy kulcsot.';

  @override
  String failedToPostReply(String error) {
    return 'Nem sikerült elküldeni a választ: $error';
  }

  @override
  String commentOnLine(int line) {
    return '$line. sor';
  }

  @override
  String get viewInDiff => 'Megtekintés a diffben';

  @override
  String get subscriptionUsagePreviousAccount => 'Előző fiók';

  @override
  String get subscriptionUsageNextAccount => 'Következő fiók';

  @override
  String inReplyTo(String path) {
    return 'Válasz erre: $path';
  }

  @override
  String get subscriptionUsageNoneReported =>
      'Ehhez a fiókhoz nincs jelentett használat.';

  @override
  String get subscriptionUsageCredits => 'Kreditek';

  @override
  String get reviewHubStaticRule => 'Statikus szabály';

  @override
  String get reviewHubStarted => 'Átnézés elindítva';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return 'Determinisztikus szabály ($rule) találta egy ezen a pull requesten hozzáadott soron — nem átnéző ügynök.';
  }

  @override
  String get prReviewArtifactTab => 'PR-átnézés';

  @override
  String get prReviewRunning => 'A pull request átnézése…';

  @override
  String get prReviewStarting => 'Átnézés indítása…';

  @override
  String get prReviewStartingBody =>
      'A pull request worktree-jének előkészítése. Az átnézők azonnal indulnak, amint kész.';

  @override
  String get prReviewFailed => 'Az átnézés sikertelen.';

  @override
  String get prReviewRerunning => 'Újraátnézés…';

  @override
  String get prReviewNoOpenFindings => 'Nincsenek nyitott megállapítások';

  @override
  String prReviewOpenFindings(int count) {
    return '$count nyitott megállapítás';
  }

  @override
  String subscriptionUsageSpend(String used, String limit) {
    return '$used / $limit';
  }

  @override
  String reviewCommentsPosted(int posted, int skipped, int failed) {
    return '$posted megjegyzés közzétéve botként. $skipped kihagyva (nincs fájlhorgony), $failed sikertelen.';
  }

  @override
  String reviewFindingsOutOfDiff(int count, String files) {
    return '$count megállapítás olyan kódra céloz, amelyet ez a pull request nem módosít ($files). A GitHub csak a diff sorközi megjegyzéseit fogadja el.';
  }

  @override
  String get reviewRailReport => 'Jelentés';

  @override
  String get reviewNoFindingsTitle => 'Még nincsenek átnézési megállapítások';

  @override
  String get reviewNoFindingsHint =>
      'A megállapítások itt jelennek meg, ahogy az ügynökök közzéteszik őket.';

  @override
  String reviewShowDismissed(int count) {
    return '$count elvetett megjelenítése';
  }

  @override
  String reviewHideDismissed(int count) {
    return '$count elvetett elrejtése';
  }

  @override
  String reviewDisagreementsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# átnézői egyet nem értés észlelve',
      one: '# átnézői egyet nem értés észlelve',
    );
    return '$_temp0';
  }

  @override
  String get reviewFilterKind => 'Fajta';

  @override
  String get reviewFilterStatus => 'Állapot';

  @override
  String get reviewKindBug => 'Hiba';

  @override
  String get reviewKindSuggestion => 'Javaslat';

  @override
  String get reviewKindRecommendation => 'Ajánlás';

  @override
  String get reviewKindQuestion => 'Kérdés';

  @override
  String get reviewKindTicket => 'Jegy';

  @override
  String get archiveSpace => 'Tér archiválása';

  @override
  String get archivedSpaces => 'Archivált terek';

  @override
  String get archivedSpacesEmpty => 'Nincsenek archivált terek';

  @override
  String get restoreSpace => 'Visszaállítás';

  @override
  String archivedWhen(String time) {
    return 'Archiválva $time';
  }

  @override
  String get deleteSpacePermanently => 'Végleges törlés';

  @override
  String get renameSpace => 'Tér átnevezése';

  @override
  String get renameConversation => 'Beszélgetés átnevezése';

  @override
  String get spaceActions => 'Térműveletek';

  @override
  String get conversationActions => 'Beszélgetési műveletek';

  @override
  String get editSpaceRepos => 'Tárolók szerkesztése';

  @override
  String get editSpaceReposTitle => 'Tér tárolói';

  @override
  String get editSpaceReposWarning =>
      'Egy tároló hozzáadása checkoutolja ebbe a térbe; egy eltávolítása törli a mappáját.';

  @override
  String get agentSectionIdentity => 'Identitás';

  @override
  String get agentSectionRuntime => 'Futtatókörnyezet';

  @override
  String get agentSectionGuardrails => 'Korlátok';

  @override
  String orgChartReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# beosztott',
      one: '# beosztott',
    );
    return '$_temp0';
  }

  @override
  String get teamsFilterHint => 'Csapatok szűrése…';

  @override
  String get teamsSummaryWithLeader => 'Vezetővel';

  @override
  String teamCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# csapat',
      one: '# csapat',
      zero: 'Nincsenek csapatok',
    );
    return '$_temp0';
  }

  @override
  String agentDeleteLongDescription(String name) {
    return 'A(z) $name törlése eltávolítja a profilját, a készséghivatkozásait és a futtatási előzményeit. Ezt nem lehet visszavonni.';
  }

  @override
  String get resetToDefault => 'Visszaállítás az alapértelmezettre';

  @override
  String get newAgent => 'Új ügynök';

  @override
  String get newSkill => 'Új készség';

  @override
  String get zoomIn => 'Nagyítás';

  @override
  String get zoomOut => 'Kicsinyítés';

  @override
  String get resetZoom => 'Nagyítás visszaállítása';

  @override
  String get imageHostedOnGitHub => 'Kép a GitHubon hosztolva';

  @override
  String get imageOpenExternally => 'Kép · megnyitás külsőleg';

  @override
  String get memoryScopeAll => 'Minden hatókör';

  @override
  String get memoryScopeWorkspace => 'Munkaterület-szintű';

  @override
  String get memoryScopeFilterLabel => 'Szűrés hatókör szerint';

  @override
  String memoryScopeRepoTooltip(String repo) {
    return 'A(z) $repo tárolóra korlátozva';
  }

  @override
  String get toolScreenshot => 'Képernyőkép az ügynöktől';

  @override
  String get toolImageUnavailable => 'A kép nem elérhető';

  @override
  String toolImagesUnavailable(int count) {
    return '$count kép nem elérhető';
  }

  @override
  String get shakeUnavailable => 'A rázás nem érhető el ezen a szerveren';

  @override
  String get shakeNothing =>
      'Nincs mit kirázni — a közelmúltbeli körök védettek';

  @override
  String shakeDone(int tokens) {
    return 'Kb. $tokens token felszabadítva';
  }

  @override
  String get compactionDivider => 'Tömörítve';

  @override
  String compactionDividerCount(int count) {
    return 'Tömörítve · $count üzenet összehajtva';
  }

  @override
  String get composerDropToAttach => 'Ejtsen a csatoláshoz';

  @override
  String get attachmentUnavailable => 'A melléklet nem elérhető';

  @override
  String get attachmentUnavailableDetail =>
      'Ez a melléklet már nincs a memóriában. Csatolja újra az előnézethez.';

  @override
  String get attachmentPreviewFailed => 'Nem sikerült megnyitni ezt a fájlt';

  @override
  String get attachmentPreviewUnsupported =>
      'Nincs előnézet ehhez a fájltípushoz';

  @override
  String get attachmentTooLargeToPreview => 'Túl nagy az előnézethez';

  @override
  String get attachmentOpenExternally =>
      'Megnyitás az alapértelmezett alkalmazásban';

  @override
  String get asideUnavailable =>
      'Állítson be egyszeri modellt a munkaterület beállításaiban a használathoz';

  @override
  String get asideEmpty => 'Még nincs miből dolgozni';

  @override
  String get asideFailed => 'Nem sikerült választ kapni';

  @override
  String get handoffTitle => 'Átadás';

  @override
  String get asideTitle => 'Mellékkérdés';

  @override
  String get attachFilesOrDrop => 'Fájlok csatolása — vagy ejtse ide őket';

  @override
  String get guidedGoalTitle => 'A célkitűzés élesítése';

  @override
  String get guidedGoalIntro =>
      'Egy felügyelet nélkül dolgozó ügynöknek pontosan tudnia kell, mikor van kész. Előbb néhány kérdés.';

  @override
  String get guidedGoalAnswerHint => 'Az Ön válasza';

  @override
  String get guidedGoalNext => 'Következő';

  @override
  String get guidedGoalStart => 'Cél indítása';

  @override
  String get guidedGoalSkip => 'Kihagyás és futtatás ahogy írva van';

  @override
  String guidedGoalStillMissing(String items) {
    return 'Még nincs megadva: $items';
  }

  @override
  String get conversationTreeTitle => 'Beszélgetésfa';

  @override
  String conversationTreeBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# ág',
      one: '# ág',
    );
    return '$_temp0';
  }

  @override
  String get conversationTreeSwitch => 'Folytatás innen';

  @override
  String get conversationTreeFork => 'Elágazás új beszélgetésbe';

  @override
  String get conversationTreeCurrent => 'Ezen az ágon';

  @override
  String get conversationTreeEmpty => 'Még nincs itt semmi';

  @override
  String get conversationTreeForked => 'Elágaztatva egy új beszélgetésbe';

  @override
  String get conversationTreeSwitched =>
      'Mostantól attól az üzenettől folytatódik';

  @override
  String exportSaved(String path) {
    return 'Mentve ide: $path';
  }

  @override
  String get exportFailed => 'Nem sikerült megírni az exportot';

  @override
  String get contextCommandNoAgent =>
      'Nincs ügynök ebben a beszélgetésben, így nincs megnyitható kontextusablak';

  @override
  String contextCommandNoSuchAgent(String name, String names) {
    return 'Nincs „$name” nevű ügynök ebben a beszélgetésben. Próbálja: $names';
  }

  @override
  String get dumpCopied => 'Átirat a vágólapra másolva';

  @override
  String get messageQueueHint =>
      'Folytassa a gépelést a további módosítások várólistára tételéhez';

  @override
  String get steerNow => 'Irányítás';

  @override
  String get steeringQueueLabel => 'Várólistás irányítóüzenetek';

  @override
  String get steeringDeliverUnavailable =>
      'Jelenleg egyetlen futó ügynök sem tudja átvenni — várólistán marad.';

  @override
  String get reorderSteeringCard => 'Várólistás üzenet átrendezése';

  @override
  String get editSteeringCard => 'Várólistás üzenet szerkesztése';

  @override
  String get deleteSteeringCard => 'Várólistás üzenet törlése';

  @override
  String get steeringBadge => 'Irányítva';

  @override
  String get settingsSandboxLabel => 'Homokozó';

  @override
  String get sandboxExecGrantsTitle => 'Végrehajtható engedélyek';

  @override
  String get sandboxExecGrantsSubtitle =>
      'Programok, amelyeket az ügynökök a tárolói munkapéldányából futtathatnak. Minden bejegyzést Ön hagyott jóvá, amikor a homokozó kérdezett.';

  @override
  String get sandboxExecGrantsEmpty =>
      'Még nincsenek rögzített döntések. Akkor kérdezünk, amikor egy ügynök először akar programot futtatni a munkapéldányából.';

  @override
  String get sandboxExecGrantRevoke => 'Visszavonás';

  @override
  String get sandboxExecGrantAllowed => 'Engedélyezve';

  @override
  String get sandboxExecGrantBlocked => 'Blokkolva';

  @override
  String get sandboxExecGrantRevokeConfirmTitle => 'Visszavonja ezt a döntést?';

  @override
  String get sandboxExecGrantRevokeConfirmBody =>
      'Újra kérdezünk, amikor egy ügynök következő alkalommal programot akar futtatni ebből a példányból.';

  @override
  String get repoScriptsTest => 'Teszt';

  @override
  String get repoScriptsTestTooltip =>
      'A vázlat futtatása a tároló eldobható klónjában';

  @override
  String get repoScriptsRunKindTest => 'Teszt';

  @override
  String get demoBadgeLabel => 'Demo';

  @override
  String get demoFilePickerTitle => 'Demofájlok';

  @override
  String get demoFilePickerBody =>
      'A demo hamisítja a feltöltéseket: válasszon ezek közül, és csatolódik az üzenetéhez anélkül, hogy lemezt érintene.';

  @override
  String get demoFilePickerAttach => 'Csatolás';

  @override
  String get demoReadOnlySave => 'Csak olvasható a demóban';

  @override
  String get demoBadgeTooltip =>
      'Demót fedez fel. Az adatok kitaláltak, az ügynökök pedig szkripteltek.';

  @override
  String get demoFirstRunTitle => 'Élő demóban van';

  @override
  String demoFirstRunBody(int minutes) {
    return 'Ez a valódi alkalmazás, valódi kódon — csak az adatok kitaláltak. Az ügynökök valódi futtatásokat streamelnek egy szkriptből, így semmi nem ér el modellt, és semmi nem fut gépen. A munkaterülete csak az Öné, és $minutes perc után eltűnik.';
  }

  @override
  String get demoFirstRunDismiss => 'Értem';

  @override
  String get demoTourTitle => 'Hol nézzen először';

  @override
  String get demoTourSubtitle =>
      'Négy hely, amely megmutatja, mit csinál az alkalmazás valójában.';

  @override
  String get demoTourSkip => 'Kihagyás';

  @override
  String get demoTourStarRepo => 'Csillagozás a GitHubon';

  @override
  String get demoTourOpen => 'Megnyitás';

  @override
  String get demoTourSpacesTitle => 'Beszéljen egy ügynökkel';

  @override
  String get demoTourSpacesBody =>
      'Küldjön üzenetet egy térben, és nézze, ahogy a futtatás beáramlik — gondolkodás, eszközhívások és költség, pontosan ahogy egy valódi futtatás jelenik meg.';

  @override
  String get demoTourReviewTitle => 'Nézzen át egy pull requestet';

  @override
  String get demoTourReviewBody =>
      'Nyissa meg a #412-t. Hagyjon sorközi megjegyzést, vagy küldjön átnézést; a szavai a szálban landolnak, és ott maradnak.';

  @override
  String get demoTourTicketsTitle => 'Kövesse a munkát';

  @override
  String get demoTourTicketsBody =>
      'A jegyek, teendők és tervek ugyanazokhoz a beszélgetésekhez kapcsolódnak, amelyeket az ügynökök folytatnak.';

  @override
  String get demoTourInboxTitle => 'Lássa a teljes működést';

  @override
  String get demoTourInboxBody =>
      'Minden riasztás minden pillérből egy beérkezettbe kerül — átnézések, jegyek, futtatások és megbeszélések.';

  @override
  String get demoUnavailableTitle => 'Nem érhető el a demóban';

  @override
  String get demoUnavailableTerminal =>
      'A terminál valódi shellt futtat a szervergépen. A demónak egyáltalán nincs végrehajtási felülete — ez teszi biztonságossá a nyilvános megnyitást.';

  @override
  String get demoUnavailableRig =>
      'Az elszigetelt környezet egy eldobható virtuális gép, amelyet egy ügynök irányít. A demo egyet sem indít: egy nyilvános végpont, amely VM-et indíthat, nem demo.';

  @override
  String get demoUnavailableEditor =>
      'A böngészőbeli szerkesztő egy code-server folyamatot futtat egy valódi checkout ellen. A demónak egyik sincs.';

  @override
  String get demoUnavailableFeeds =>
      'A demo valódi hírfolyamokat olvas, de a feliratkozási listája rögzített. Hozzáadás vagy eltávolítás itt le van tiltva.';

  @override
  String get demoUnavailableForge =>
      'A demo nem tart hitelesítő adatokat, és soha nem lép kapcsolatba a GitHubbal, GitLabbal vagy Linearrel. A pull requestjei fixture-ök, a megjegyzései pedig helyben tárolódnak.';

  @override
  String get demoUnavailableModels =>
      'A demo nem hív modellt. Az ügynökfuttatások szkriptelt lejátszás, ezért semmibe sem kerülnek, és nem érnek el szolgáltatót.';

  @override
  String get demoUnavailableMcp =>
      'Az MCP-eszközfelület nincs felcsatolva a demón, így külső kliens nem csatlakozhat hozzá.';

  @override
  String get demoUnavailableRepos =>
      'A demo nem checkoutol kódot, és nem futtat git-et. A látható tároló a pull requestek mögötti fixture.';

  @override
  String get demoUnavailableSkills =>
      'Egy készség telepítése kódot tölt le és vizsgál. A demo semmit sem tölt le.';

  @override
  String get demoUnavailableSso =>
      'Az egyszeri bejelentkezés szerverbeállítás. A demo ideiglenes vendégként jelentkezteti be.';

  @override
  String get demoUnavailableAudio =>
      'A felvételhez és a diktáláshoz hangrögzítés és beszédmodell kell a hoszton. A demo egyiket sem szállítja, így a megbeszélései lejátszás nélküli átiratok.';

  @override
  String get demoUnavailableServerAdmin =>
      'Ez szerveradminisztráció. A demo minden látogatónak saját eldobható munkaterületet ad, és semmit azon túl.';

  @override
  String get demoUnavailablePipelines =>
      'A folyamatok itt nem futhatnak. Egy látogató, aki bash lépést írhat és elindíthatja — kézzel vagy eseményindítóval — kódot futtat ezen a gazdagépen.';

  @override
  String get settingsBackupRestore => 'Biztonsági mentés és visszaállítás';

  @override
  String get settingsBackupRestoreDescription =>
      'A szerver minden adatbázisának pillanatképei, plusz egyetlen munkaterület exportálása, importálása és törlése.';

  @override
  String get backupSnapshotsLabel => 'Telepítési pillanatképek';

  @override
  String get backupSnapshotsExplainer =>
      'Egy pillanatkép minden adatbázist egy időbélyeges mappába másol a szervergépen. Egy teljes telepítés visszaállítása azt a mappát jelenti vissza, a szerver leállításával; egyetlen munkaterület innen is visszaállítható.';

  @override
  String get backupNowAction => 'Biztonsági mentés most';

  @override
  String backupSnapshotWritten(String path) {
    return 'Pillanatkép ide írva: $path';
  }

  @override
  String get backupNoSnapshots =>
      'Még nincsenek pillanatképek. Csak akkor készül egy, ha kéri — semmi nincs ütemezve.';

  @override
  String get backupSnapshotComplete => 'Teljes';

  @override
  String get backupSnapshotIncomplete => 'Hiányos';

  @override
  String get backupSnapshotIncompleteNote =>
      'A manifest hiányzik, vagy olyan fájlokat nevez meg, amelyek nincsenek ott, így ez a pillanatkép nem tudja visszaállítani a teljes telepítést. A meglévő munkaterület-fájljai egyenként még átvehetők.';

  @override
  String backupSnapshotWorkspaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# munkaterület',
      one: '# munkaterület',
      zero: 'Nincsenek munkaterületek',
    );
    return '$_temp0';
  }

  @override
  String backupSnapshotSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# munkaterület nem került rögzítésre',
      one: '# munkaterület nem került rögzítésre',
    );
    return '$_temp0';
  }

  @override
  String get backupServerPathLabel => 'Útvonal a szerveren';

  @override
  String get backupRestoreAction => 'Visszaállítás';

  @override
  String get backupRestoreTitle => 'Munkaterület visszaállítása';

  @override
  String backupRestoreBody(String name) {
    return 'Ez mindent lecserél a(z) $name munkaterületben a pillanatképben tartott másolatra. Ami a munkaterület a pillanatkép óta csinált, elveszik, és nem vonható vissza.';
  }

  @override
  String backupRestoreDone(String name) {
    return 'A(z) $name visszaállítva a pillanatképből.';
  }

  @override
  String get backupWorkspaceUnknown => 'Már nincs ezen a szerveren';

  @override
  String get backupWorkspaceDataLabel => 'Munkaterület adatai';

  @override
  String get backupWorkspaceDataExplainer =>
      'Egy munkaterület egy adatbázisfájl, így az exportálása azt a fájlt másolja, nem táblánként dumpol. Az importálás mindent lecserél a cél-munkaterületben a megnevezett fájllal.';

  @override
  String get backupExportAction => 'Exportálás';

  @override
  String backupExportDone(String path) {
    return 'Exportálva ide: $path';
  }

  @override
  String get backupExportedFileLabel => 'Exportált fájl a szerveren';

  @override
  String get backupImportAction => 'Importálás';

  @override
  String backupImportTitle(String name) {
    return 'Importálás ide: $name';
  }

  @override
  String backupImportBody(String name) {
    return 'Ez mindent lecserél a(z) $name munkaterületben a fájl tartalmával. Ami a munkaterület most tart, elveszik, és nem vonható vissza.';
  }

  @override
  String get backupImportSourceLabel => 'Munkaterület-adatbázisfájl';

  @override
  String get backupImportSourceDescription =>
      'Egy .db fájl, amelyet a szerver olvashat. Az útvonalak a szervergépen oldódnak fel, nem ezen az eszközön.';

  @override
  String backupImportDone(String name) {
    return 'Importálva ide: $name.';
  }

  @override
  String backupDeleteBody(String name) {
    return 'A(z) $name eltűnik minden listából és keresésből. Az adatbázisfájlja a lemezen marad, a biztonsági mentések továbbra is tartalmazzák, és semmi sem foglalja vissza automatikusan a helyet.';
  }

  @override
  String get backupExportDescription =>
      'Írjon másolatot a szerverre, vagy töltsön le egyet erre az eszközre.';

  @override
  String get backupExportOnServerAction => 'Mentés a szerverre';

  @override
  String get backupDownloadAction => 'Letöltés';

  @override
  String backupDownloadSaved(String path) {
    return 'Mentve ide: $path';
  }

  @override
  String get backupDownloadInBrowser => 'A böngészője letölti.';

  @override
  String get backupRestoreFromDeviceLabel => 'Visszaállítás erről az eszközről';

  @override
  String get backupRestoreFromDeviceDescription =>
      'Válasszon itt egy munkaterület-adatbázisfájlt, és a Control Center feltölti a szerverre. Ez az, amely akkor működik, ha a szerver nem ez a gép.';

  @override
  String get backupUploadAction => 'Fájl választása és feltöltése';

  @override
  String get backupTransferUnavailable =>
      'Ez a kapcsolat relén keresztül éri el a szervert, amely nem visz fájlátvitelt. Csatlakozzon közvetlenül a szerverhez a biztonsági mentés letöltéséhez vagy feltöltéséhez.';

  @override
  String get backupTransferForbidden =>
      'A szerver elutasította. Egy munkaterület letöltéséhez admin szerep kell, a visszaállításához tulajdonos, egy teljes pillanatképhez pedig a telepítés üzemeltetője.';

  @override
  String get backupTransferUnsupported =>
      'Ennek a szervernek nincs biztonsági mentési felülete.';

  @override
  String get backupTransferTooLarge =>
      'A fájl nagyobb, mint amit a szerver elfogad.';

  @override
  String get credentialGateWaitingTitle => 'Hitelesítő adatra vár';

  @override
  String credentialGateHarnessTitle(String provider) {
    return 'A(z) $provider nem rendelkezik hitelesítő adattal';
  }

  @override
  String get credentialGateSignedOutTitle => 'A Claude Code ki van jelentkezve';

  @override
  String get credentialGateExpiredTitle =>
      'A Claude Code bejelentkezése lejárt';

  @override
  String get credentialGatePlanSpentTitle =>
      'A Claude Code csomagkorlátja elérve';

  @override
  String credentialGateWaitingAgent(String agent) {
    return '$agent a folytatásra vár.';
  }

  @override
  String get credentialGateWaitingRun => 'Egy futtatás a folytatásra vár.';

  @override
  String get credentialGateWatching =>
      'A javításra figyel — a futtatás magától folytatódik.';

  @override
  String credentialGateFreesUpAt(String time) {
    return 'Felszabadul $time';
  }

  @override
  String credentialGateGivesUpAt(String time) {
    return 'A futtatás feladja $time';
  }

  @override
  String get credentialGateCheckAgain => 'Ellenőrzés újra';

  @override
  String get credentialGateCancelRun => 'Futtatás megszakítása';

  @override
  String get credentialGateAccountsTried => 'Próbált fiókok';

  @override
  String get credentialGateClaudeSignInHint =>
      'Jelentkezzen be: Beállítások → Adapterek → Claude Code, vagy futtassa a bejelentkezési parancsot egy terminálban. A futtatás magától felveszi.';

  @override
  String get credentialGateOpenSettings => 'Beállítások megnyitása';

  @override
  String get selectModel => 'Modell kiválasztása';

  @override
  String get allModels => 'Összes modell';

  @override
  String get noModelsMatchSearch =>
      'Egyetlen modell sem felel meg a keresésnek';

  @override
  String useCustomModelId(String id) {
    return '„$id” használata';
  }

  @override
  String get modelFree => 'Ingyenes';

  @override
  String modelOutputTokens(String tokens) {
    return '$tokens kimenet';
  }

  @override
  String modelPricePerMTokens(String input, String output) {
    return '$input bemenet / $output kimenet 1M tokenenként';
  }

  @override
  String modelEffortLevels(String levels) {
    return 'Gondolkodási erőfeszítés: $levels';
  }

  @override
  String get modelSupportsReasoning => 'Támogatja a gondolkodási erőfeszítést';

  @override
  String get profileDeliveryMetrics => 'Szállítási mérőszámok';

  @override
  String profileMetricsSample(int count) {
    return 'Elemzett PR-ek: $count';
  }

  @override
  String get profileMergeRate => 'Egyesítési arány';

  @override
  String get profileReviewCoverage => 'Felülvizsgálati lefedettség';

  @override
  String get profilePrSize => 'PR mérete';

  @override
  String get profileTimeToMerge => 'Egyesítésig eltelt idő';

  @override
  String get profileMergeTimeTrend => 'Az összevonási idő trendje';

  @override
  String get profileWeeklyMedian => 'Heti medián, logaritmikus skála';

  @override
  String get profilePrOpeningPattern => 'A hét napja × óra, helyi idő';

  @override
  String get profileFirstReview => 'Első felülvizsgálatig eltelt idő';

  @override
  String get profileMetricsTruncated =>
      'A percentilisek az elérhető lekéréses kérelmek korlátozott mintáját használják.';

  @override
  String profileLinesChanged(String count) {
    return '$count sor';
  }

  @override
  String profileDurationMinutes(int count) {
    return '$count perc';
  }

  @override
  String profileDurationHours(int count) {
    return '$count óra';
  }

  @override
  String profileDurationDaysHours(int days, int hours) {
    return '$days n $hours ó';
  }

  @override
  String profilePercentiles(String median, String p90) {
    return 'p50 $median · p90 $p90';
  }

  @override
  String profileTeamMembers(int count) {
    return 'Tagok: $count';
  }

  @override
  String noPrsByTeamInWorkspace(String team) {
    return 'Nincs pull request a(z) $team csapattól ebben a munkaterületen';
  }

  @override
  String get profilePrStateFilterLabel =>
      'Pull requestek szűrése állapot szerint';

  @override
  String get noProfilePrsMatchSearchHint =>
      'Próbáljon másik címet vagy pull request-számot';

  @override
  String get rigNetworkUnrestricted => 'Korlátozás nélküli hálózat';

  @override
  String get rigNetworkAllowAllHosts => 'Minden gazdagép engedélyezése';

  @override
  String get rigBrowserPermissionsTitle => 'Webhelyengedélyek';

  @override
  String get rigBrowserPermissionsTooltip => 'Webhelyengedélyek és hálózat';

  @override
  String get rigBrowserPermissionEmpty => 'Még egy webhely sem kért engedélyt';

  @override
  String rigBrowserPermissionPrompt(String origin, String permission) {
    return 'A(z) $origin a következőt szeretné használni: $permission';
  }

  @override
  String get rigBrowserPermissionBlock => 'Tiltás';

  @override
  String get rigBrowserPermissionCamera => 'Kamera';

  @override
  String get rigBrowserPermissionMicrophone => 'Mikrofon';

  @override
  String get rigBrowserPermissionNotifications => 'Értesítések';

  @override
  String get rigBrowserPermissionGeolocation => 'Helymeghatározás';

  @override
  String get rigBrowserPermissionPersistentStorage => 'Állandó tárhely';

  @override
  String get rigBrowserPermissionClipboard => 'Vágólap';

  @override
  String get rigBrowserPermissionDisplayCapture => 'Képernyőfelvétel';

  @override
  String get rigBrowserPermissionMidi => 'MIDI';

  @override
  String get rigNetworkBypassTitle =>
      'Engedélyezi az összes hálózati gazdagépet?';

  @override
  String get rigNetworkBypassBody =>
      'Ez újraindítja az elkülönített környezetet, és elveti a benne lévő, még nem véglegesített munkát. Ezután a vendégrendszer a bezárásáig bármely hálózati gazdagépet elérheti.';

  @override
  String get rigNetworkRestartUnrestricted => 'Újraindítás korlátozások nélkül';

  @override
  String get rigNetworkUnrestrictedBody =>
      'Ez az elkülönített környezet minden hálózati gazdagépet elérhet. Az alapértelmezett korlátozások visszaállításához zárja be, és nyisson egy újat.';

  @override
  String get rigNetworkAlreadyUnrestrictedBody =>
      'Ez az Android-emulátor már saját maga kezeli a hálózatát, ezért a Control Center nem tud gazdagépenkénti engedélyezési listát kikényszeríteni. Nincs szükség újraindításra.';

  @override
  String get rigClipboardPermissionHostToRigTitle =>
      'Beilleszti a vágólapot ebbe a környezetbe?';

  @override
  String get rigClipboardPermissionHostToRigBody =>
      'A Control Center beolvassa az eszköz vágólapját, és elküldi annak tartalmát a környezetnek. A vágólap tartalma jelszavakat vagy más titkokat tartalmazhat.';

  @override
  String get rigClipboardPermissionRigToHostTitle =>
      'Kimásolja a vágólapot ebből a környezetből?';

  @override
  String get rigClipboardPermissionRigToHostBody =>
      'A Control Center beolvassa a környezet vágólapját, és lecseréli az eszköz vágólapját annak tartalmára. A környezetből származó tartalmat kezelje nem megbízhatóként.';

  @override
  String get rigClipboardAllowTenMinutes => 'Engedélyezés 10 percig';

  @override
  String get rigClipboardAlwaysAllow => 'Mindig engedélyez';

  @override
  String get rigClipboardSettingsTitle => 'Vágólap-hozzáférés';

  @override
  String get rigClipboardSettingsHint =>
      'Válassza ki, mely vágólap-átvitelek futhatnak rákérdezés nélkül. Az ideiglenes engedélyek 10 perc után lejárnak.';

  @override
  String get rigClipboardAlwaysPasteTitle =>
      'Beillesztés mindig engedélyezése környezetekbe';

  @override
  String get rigClipboardAlwaysPasteDescription =>
      'Az eszköz vágólapjának elküldése bármely környezetbe rákérdezés nélkül.';

  @override
  String get rigClipboardAlwaysCopyTitle =>
      'Másolás mindig engedélyezése környezetekből';

  @override
  String get rigClipboardAlwaysCopyDescription =>
      'Vágólaptartalom elhelyezése bármely környezetből ezen az eszközön rákérdezés nélkül.';

  @override
  String get workspaceGitHubIdentity => 'GitHub-azonosító';

  @override
  String get workspaceGitHubIdentityDescription =>
      'Hogyan hitelesül a háttérbeli GitHub-munka ebben a munkaterületen. Az installáció Appjának öröklése, másik App, vagy csak személyes hozzáférési token.';

  @override
  String get workspaceGitHubModeInherit =>
      'Az installáció GitHub Appjának használata';

  @override
  String get workspaceGitHubModeApp => 'Másik GitHub App használata';

  @override
  String get workspaceGitHubModePat => 'Csak személyes hozzáférési token';

  @override
  String get workspaceGitHubInheritHint =>
      'A GitHub Appot a Szerver → Szolgáltatói alkalmazások alatt használja.';

  @override
  String get workspaceGitHubAppHint =>
      'A munkaterület bot- és lekérdezési identitása. A tagok a Te felületen ezen az App-on keresztül jelentkeznek be.';

  @override
  String get workspaceGitHubPatLabel => 'Háttértoken';

  @override
  String get workspaceGitHubPatDescription =>
      'Lekérdezéshez és ügynökökhöz ebben a munkaterületen. Nem egy tag profiltokenje.';

  @override
  String get workspaceGitHubHasPat => 'Háttértoken van tárolva.';

  @override
  String get workspaceGitHubNoPat => 'Nincs háttértoken tárolva.';

  @override
  String get profileOverlayHint =>
      'Ezek a mezők te vagy ebben a munkaterületen. Az üresek öröklik a fiók nevét és e-mailjét. Munkaterület váltása ezt a réteget is váltja.';

  @override
  String get forgeConnectionsThisWorkspace =>
      'Jelentkezz be, vagy illessz be tokent ehhez a munkaterülethez.';
}
