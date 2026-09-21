// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get succeeded => 'Úspěšně';

  @override
  String agentRunRetryLabel(int number, String time) {
    return 'Opakování #$number · $time';
  }

  @override
  String agentRunStarting(String time) {
    return 'Spouštění · $time';
  }

  @override
  String get agentActivityFollowingLive => 'Sledování živé aktivity';

  @override
  String get agentActivityJumpToLatest => 'Přejít na nejnovější';

  @override
  String get agentActivityLoadFailed =>
      'Aktivitu tohoto běhu se nepodařilo načíst';

  @override
  String get agentActivityNotRecorded =>
      'Pro tento běh nebyla zaznamenána žádná aktivita';

  @override
  String get agentActivityNotRecordedHint =>
      'Běhy, které skončily před zapnutím zachytávání aktivity, nemají časovou osu.';

  @override
  String get agentActivityRunUnavailable => 'Tento běh už není k dispozici';

  @override
  String agentActivitySubagentOf(String agent) {
    return 'Subagent agenta $agent';
  }

  @override
  String get agentActivityUnsupported =>
      'Zachytávání aktivity není na připojeném serveru k dispozici';

  @override
  String get agentActivityUnsupportedHint =>
      'Restartujte aplikaci, aby načetla nejnovější sestavení serveru.';

  @override
  String get agentActivityWaiting => 'Čeká se na aktivitu…';

  @override
  String get created => 'Vytvořeno';

  @override
  String get dictationStart => 'Spustit diktování';

  @override
  String get dictationListening => 'Poslouchám…';

  @override
  String get dictationUnavailable =>
      'Diktování potřebuje hlasový model na hostiteli serveru. Nastavte ho v nastavení hlasu.';

  @override
  String get dictationFailedToStart => 'Diktování se nepodařilo spustit';

  @override
  String get dictationHoldToTalkTitle => 'Držet a mluvit';

  @override
  String get dictationHoldToTalkDescription =>
      'Držte tlačítko mikrofonu nebo zkratku pro diktování a pusťte pro zastavení. Když je vypnuto, stiskněte jednou pro spuštění a znovu pro zastavení.';

  @override
  String get focusConversation => 'Zaměřit konverzaci';

  @override
  String get ideAgentActivity => 'Aktivita agenta';

  @override
  String get keybindingPushToTalk => 'Stisknout a mluvit';

  @override
  String get keybindingPushToTalkDescription =>
      'Držte nebo přepínejte hlasové diktování v poli zprávy';

  @override
  String get agentPermissions => 'Oprávnění agentů';

  @override
  String get agentPermissionsSettingsDescription =>
      'Určete, co agenti smí dělat sami, na co se musí nejdřív zeptat a co nesmí nikdy — podle pracovního prostoru, agenta nebo prostoru.';

  @override
  String get agentPermissionsMatrixDescription =>
      'Nastavte rozhodnutí pro každý druh efektu. Pravidla se kaskádově přepisují: prostor přepisuje agenta, agent pracovní prostor, pracovní prostor předvolbu režimu. Platí nejkonkrétnější pravidlo.';

  @override
  String get guardrailLoading => 'Načítání pravidel…';

  @override
  String get guardrailRulesLoadFailed =>
      'Pravidla oprávnění se nepodařilo načíst.';

  @override
  String get guardrailScopeWorkspace => 'Pracovní prostor';

  @override
  String get guardrailScopeAgent => 'Agent';

  @override
  String get guardrailScopeSpace => 'Prostor';

  @override
  String get guardrailSelectAgent => 'Vyberte agenta';

  @override
  String get guardrailSelectSpace => 'Vyberte prostor';

  @override
  String get guardrailNoAgents =>
      'V tomto pracovním prostoru zatím nejsou žádní agenti.';

  @override
  String get guardrailNoSpaces =>
      'V tomto pracovním prostoru zatím nejsou žádné prostory.';

  @override
  String get guardrailClassFileDelete => 'Smazat soubor';

  @override
  String get guardrailClassFileWriteOutsideWorktree => 'Zápis mimo worktree';

  @override
  String get guardrailClassGitCommit => 'Vytvořit commit';

  @override
  String get guardrailClassGitPush => 'Odeslat na remote';

  @override
  String get guardrailClassPrCreate => 'Otevřít pull request';

  @override
  String get guardrailClassPrPublish => 'Zveřejnit kontrolu nebo sloučení';

  @override
  String get guardrailClassVendorSyncWrite => 'Zápis do externího trackeru';

  @override
  String get guardrailClassNetworkEgress => 'Přístup k síti';

  @override
  String get guardrailClassSecretAccess => 'Číst tajemství';

  @override
  String get guardrailClassPackageInstall => 'Nainstalovat balíček';

  @override
  String get guardrailClassProcessSpawn => 'Spustit proces';

  @override
  String get guardrailClassWorkspaceMutation =>
      'Změnit strukturu pracovního prostoru';

  @override
  String get guardrailClassEnclosureControl =>
      'Ovládat izolované prostředí (stanici)';

  @override
  String get navRigs => 'Stanice';

  @override
  String get rigsUnsupportedServer =>
      'Tento server nemůže hostovat žádné plochy rig. Zkontrolujte požadavky na hostitele pro počítač, který chcete použít.';

  @override
  String get rigSurfaceComputer => 'Počítač';

  @override
  String get rigSurfaceBrowser => 'Prohlížeč';

  @override
  String get rigSurfaceAndroid => 'Android';

  @override
  String get rigSurfaceIosSimulator => 'Simulátor iOS';

  @override
  String rigSurfaceBrowserEngine(String engine) {
    return '$engine';
  }

  @override
  String rigBrowserEngineHint(String engine) {
    return 'Jednorázový $engine, izolovaný od vašeho stroje. Otevřete jiný engine a porovnejte stejnou stránku vedle sebe.';
  }

  @override
  String get rigPhaseReady => 'Připraveno';

  @override
  String get rigPhaseStarting => 'Spouštění';

  @override
  String get rigPhaseParked => 'Zaparkováno';

  @override
  String get rigPhaseClosing => 'Zavírání';

  @override
  String get rigPhaseClosed => 'Zavřeno';

  @override
  String get rigPhaseFailed => 'Selhalo';

  @override
  String get rigPhaseUnknown => 'Neznámé';

  @override
  String get rigNotAccelerated => 'Emulováno';

  @override
  String get rigAudioListen => 'Poslouchat stroj';

  @override
  String get rigAudioMute => 'Ztlumit stroj';

  @override
  String get rigYouHaveControl => 'Máte řízení';

  @override
  String get rigBackendAvailable => 'Dostupné';

  @override
  String get rigBackendUnavailable => 'Nedostupné';

  @override
  String get rigEgressNotEnforced =>
      'Síť na tomto backendu není izolovaná — konektivitu si spravuje sám.';

  @override
  String get rigStartMachine => 'Spustit stroj';

  @override
  String get rigStartHint =>
      'Spustí jednorázové VM, které v této konverzaci sdílíte s agenty. Po zavření se zničí a nic v něm se nedotkne vašeho počítače.';

  @override
  String get rigStartAndroidHint =>
      'Připojí se k emulátoru Androidu, který je již spuštěný na serveru. Přístup k síti není izolovaný.';

  @override
  String get rigStartIosHint =>
      'Vytvoří dočasný simulátor iOS na serveru s macOS. Po ukončení testovacího prostředí bude odstraněn; přístup k síti není izolovaný.';

  @override
  String get rigTechnicalDetails => 'Technické podrobnosti';

  @override
  String get rigStopMachine => 'Zastavit stroj';

  @override
  String get rigHomeButton => 'Plocha';

  @override
  String get rigRotateClockwise => 'Otočit po směru hodin';

  @override
  String get rigRotateCounterclockwise => 'Otočit proti směru hodin';

  @override
  String get rigTakeScreenshot => 'Pořídit snímek obrazovky';

  @override
  String get rigScreenshotSaved => 'Snímek obrazovky uložen';

  @override
  String rigScreenshotSaveFailed(String error) {
    return 'Snímek obrazovky se nepodařilo uložit: $error';
  }

  @override
  String get rigSurfaceUnavailable =>
      'Tento server nemůže hostovat tento druh stroje.';

  @override
  String get rigTabNeedsConversation =>
      'Nejprve otevřete konverzaci — stroj k ní patří, abyste vy i agenti viděli stejnou obrazovku.';

  @override
  String get ideMenuSectionTools => 'Nástroje';

  @override
  String get ideMenuSectionMachines => 'Počítače';

  @override
  String get ideMenuSectionReopen => 'Znovu otevřít';

  @override
  String get ideMenuSearchHint => 'Hledat';

  @override
  String get ideMenuNoMatches => 'Žádné shody';

  @override
  String get rigMenuComputer => 'Počítač';

  @override
  String get rigMenuBrowser => 'Prohlížeč';

  @override
  String get rigMenuAndroid => 'Android';

  @override
  String get rigMenuIosSimulator => 'Simulátor iOS';

  @override
  String rigLabelNumbered(String label, String suffix) {
    return '$label $suffix';
  }

  @override
  String ideCloseKeepTitle(String name) {
    return 'Zavřít $name?';
  }

  @override
  String get ideCloseKeepBodyMachine =>
      'Stroj dál běží na pozadí — kdykoli ho znovu otevřete z postranního panelu. Chcete-li uvolnit paměť hned, vypněte ho.';

  @override
  String get ideCloseKeepBodyShell =>
      'Příkaz dál běží na pozadí — shell kdykoli znovu otevřete z postranního panelu. Chcete-li ho zastavit, ukončete ho.';

  @override
  String get ideCloseKeepBodyAgent =>
      'Agent dál pracuje na pozadí — konverzaci kdykoli znovu otevřete z postranního panelu. Chcete-li běh ukončit hned, zastavte ho.';

  @override
  String get ideCloseKeepRunning => 'Nechat běžet';

  @override
  String get ideCloseShutDownMachine => 'Vypnout';

  @override
  String get ideCloseEndShell => 'Ukončit shell';

  @override
  String get ideCloseStopAgent => 'Zastavit agenta';

  @override
  String get rigsSettingsSubtitle =>
      'Co tento server umí spustit, jaké základní obrazy potřebuje a které stroje právě běží';

  @override
  String get rigsCapabilitiesTitle => 'Tento server';

  @override
  String get rigInstallIosAutomation =>
      'Nainstalovat můstek pro automatizaci iOS';

  @override
  String get rigInstallingIosAutomation =>
      'Instaluje se můstek pro automatizaci iOS…';

  @override
  String get rigIosAutomationInstalled =>
      'Můstek pro automatizaci iOS byl nainstalován';

  @override
  String get rigsImagesTitle => 'Základní obrazy';

  @override
  String get rigsImagesHint =>
      'Každá stanice nabootuje jeden z těchto obrazů jen pro čtení. Relace zapisuje do dočasné overlay vrstvy, takže jedna stanice nemůže změnit, z čeho nabootuje další.';

  @override
  String get rigsRunningTitle => 'Právě běží';

  @override
  String get rigsNoneRunning => 'Žádné stroje neběží.';

  @override
  String get rigsCustomImagesTitle => 'Vlastní obrazy (tento pracovní prostor)';

  @override
  String get rigsCustomImagesHint =>
      'Nasměrujte Terminal (VM) nebo Browser (VM) na vlastní obraz — rozšiřte výchozí o nástroje, které projekt potřebuje, nebo použijte kompatibilní obraz z registru. Nové stroje ho použijí, běžící si nechají svůj. Co musí obraz poskytovat, najdete v příručce ke stanicím.';

  @override
  String get rigsCustomTerminalImageLabel => 'Obraz Terminal (VM)';

  @override
  String get rigsCustomBrowserImageLabel => 'Obraz Browser (VM)';

  @override
  String get rigsCustomImagePlaceholder =>
      'např. ghcr.io/acme/dev-shell:1.2 — pro výchozí nechte prázdné';

  @override
  String get rigsCustomImageInvalid =>
      'Zadejte odkaz registru ve tvaru repo/name:tag. Místní cesty a archivy nejsou povoleny.';

  @override
  String get rigsCustomImageSaved =>
      'Uloženo. Nové stroje nabootují tento obraz, běžící si nechají svůj.';

  @override
  String get rigsEgressTitle => 'Egress prohlížeče (tento pracovní prostor)';

  @override
  String get rigsEgressHint =>
      'Další hostitelé, které izolovaný prohlížeč smí kontaktovat — jeden na řádek: přesný hostitel (api.example.com) nebo zástupný znak pro subdomény (*.example.com). Web produktu zůstává povolen vždy. Nové stroje dostanou seznam, běžící si nechají ten, se kterým nabootovaly.';

  @override
  String rigsEgressInvalid(String host) {
    return '„$host“ není platný záznam hostitele.';
  }

  @override
  String get rigsEgressSaved =>
      'Uloženo. Nové stroje prohlížeče tyto hostitele povolí, běžící si nechají své.';

  @override
  String get rigImageInstalled => 'Nainstalováno';

  @override
  String get rigImageNotDownloaded => 'Nestaženo';

  @override
  String get rigImageNotPublished => 'Nezveřejněno';

  @override
  String get rigImageNotPublishedHint =>
      'Pro toto ještě nebyl zveřejněn žádný obraz, takže není co stáhnout. Importujte kompatibilní diskový obraz, abyste to povolili.';

  @override
  String get rigImageDownload => 'Stáhnout';

  @override
  String get rigImageDownloading => 'Stahování…';

  @override
  String get rigImageImport => 'Importovat';

  @override
  String get rigImageImportMessage =>
      'Cesta k diskovému obrazu qcow2 na souborovém systému serveru. Zkopíruje se do úložiště obrazů, soubor se potom může přesunout.';

  @override
  String get rigConnectingStream => 'Připojování ke stanici';

  @override
  String get rigStreamNotAllowed => 'K této stanici nemáte přístup.';

  @override
  String get rigStreamNotRunning => 'Tato stanice už neběží.';

  @override
  String get rigStreamNeedsFfmpeg =>
      'Živý náhled na tomto hostiteli potřebuje ffmpeg. Nainstalujte ffmpeg a znovu otevřete kartu.';

  @override
  String get rigStreamEnded => 'Živý náhled skončil.';

  @override
  String get rigStreamFailed => 'Živý náhled se nepodařilo otevřít.';

  @override
  String get rigStreamDisconnected => 'Nepřipojeno k serveru.';

  @override
  String rigDropSendingOne(String name) {
    return 'Kopírování „$name“ do stroje…';
  }

  @override
  String rigDropSendingMany(int count) {
    return 'Kopírování $count souborů do stroje…';
  }

  @override
  String get rigTerminalDropSending => 'Kopírování do stroje…';

  @override
  String get rigTerminalPasteImage => 'Vložený obrázek uložen ve stroji';

  @override
  String get rigPortsTitle => 'Předané porty';

  @override
  String get rigPortsTooltip => 'Porty otevřené uvnitř tohoto stroje';

  @override
  String get rigPortsEmpty =>
      'Zatím nic nenaslouchá. Spusťte server v terminálu — vývojový server na portu 3000 se tu objeví.';

  @override
  String get rigPortsAdd => 'Přidat port';

  @override
  String get rigPortsAddHint => 'Port hosta k předání (např. 3000)';

  @override
  String get rigPortsAutoForward => 'Automaticky předávat porty';

  @override
  String get rigPortsCopyUrl => 'Kopírovat místní URL';

  @override
  String rigPortsCopiedUrl(String url) {
    return 'Zkopírováno $url';
  }

  @override
  String get rigPortsStopForward => 'Zastavit předávání';

  @override
  String get rigPortsExposeLan => 'Sdílet v místní síti';

  @override
  String get rigPortsLanPrivate => 'Jen místně';

  @override
  String get rigPortsLanShared => 'V síti';

  @override
  String get rigPortsSetDomain => 'Nastavit doménu prohlížeče (.test)';

  @override
  String get rigPortsDomainHint =>
      'Doména pro Browser (VM), např. myapp.test — dostupná tam, ne na hostiteli';

  @override
  String get rigPortsProcessUnknown => 'neznámý proces';

  @override
  String get rigPortsInactive => 'nenaslouchá';

  @override
  String get rigPortsTooltipHost => 'Porty otevřené v tomto terminálu';

  @override
  String get rigPortsEmptyHost =>
      'V tomto terminálu zatím nic nenaslouchá. Spusťte server a objeví se tu.';

  @override
  String get rigPortsAddHintHost => 'Port k namapování (např. 5173)';

  @override
  String get rigPortsLocalPortHint => 'Místní port (volitelné)';

  @override
  String rigPortsDestDesktop(int port) {
    return 'localhost:$port';
  }

  @override
  String rigPortsDestBrowser(int port) {
    return 'localhost:$port v prohlížeči (VM)';
  }

  @override
  String get rigPortsDestBrowserUnreachable => 'prohlížeč (VM) není připojen';

  @override
  String rigPortsDestAndroid(int port) {
    return 'localhost:$port na Androidu';
  }

  @override
  String get rigPortsDestAndroidUnreachable => 'Android není připojen';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zbývá stáhnout $count základních obrazů',
      many: 'Zbývá stáhnout $count základních obrazů',
      few: 'Zbývá stáhnout $count základní obrazy',
      one: 'Zbývá stáhnout 1 základní obraz',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => 'Povolit';

  @override
  String get guardrailDecisionPrompt => 'Nejdřív se zeptat';

  @override
  String get guardrailDecisionDeny => 'Zakázat';

  @override
  String get guardrailSourceThisScope => 'Tento rozsah';

  @override
  String get guardrailSourceDefault => 'Vestavěný výchozí';

  @override
  String get guardrailSourcePreset => 'Předvolba režimu';

  @override
  String get guardrailSourceInherited => 'Zděděno';

  @override
  String get guardrailClearToInherited => 'Obnovit zděděné';

  @override
  String get guardrailWhatIf => 'Co kdyby?';

  @override
  String get guardrailWhatIfDescription =>
      'Podívejte se, jak by aktuální pravidla vyřešila akci, stejnou logikou, kterou agenti používají.';

  @override
  String get guardrailProbeActionLabel => 'Akce';

  @override
  String get guardrailProbeCommandLabel => 'Příkaz (volitelné)';

  @override
  String get guardrailProbeCommandHint => 'např. git push origin main';

  @override
  String get guardrailProbeAgentLabel => 'Agent (volitelné)';

  @override
  String get guardrailProbeSpaceLabel => 'Prostor (volitelné)';

  @override
  String get guardrailProbeNone => 'Žádný';

  @override
  String get guardrailProbeModeLabel => 'Režim';

  @override
  String get guardrailProbeResult => 'Výsledek';

  @override
  String get guardrailProbeSource => 'Zdroj:';

  @override
  String get guardrailAdapterMatrix => 'Kde se pravidla vynucují';

  @override
  String get guardrailAdapterMatrixDescription =>
      'Upřímný přehled: kde se každý efekt skutečně zachytí, podle runneru agenta. Dokumentuje realitu, ne záruku — efekty, které runner provede mimo pásmo, nelze zachytit.';

  @override
  String get guardrailEffectColumn => 'Efekt';

  @override
  String get guardrailAdapterHarness => 'Vestavěný harness';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => 'Podlaha sandboxu';

  @override
  String get guardrailEnforcementPolicyGate => 'Brána politiky';

  @override
  String get guardrailEnforcementSandbox => 'Jen sandbox';

  @override
  String get guardrailEnforcementNone => 'Nelze vynutit';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      'Rozhodnutí o oprávnění se kontroluje před spuštěním efektu a může ho zablokovat.';

  @override
  String get guardrailEnforcementSandboxHelp =>
      'Omezuje ho jen sandbox; pravidlo oprávnění se nekonzultuje.';

  @override
  String get guardrailEnforcementNoneHelp =>
      'Rozhodnutí je jen doporučení — tady ho nelze zachytit.';

  @override
  String get obsStatCost => 'náklady';

  @override
  String obsStatDelegatedCost(String amount) {
    return '+$amount delegováno';
  }

  @override
  String get obsStatDuration => 'trvání';

  @override
  String get obsStatTokens => 'tokeny';

  @override
  String get obsStatTools => 'nástroje';

  @override
  String get openAgentActivity => 'Otevřít aktivitu';

  @override
  String get orgChart => 'Organizační schéma';

  @override
  String get orgChartEmpty => 'Zatím žádní agenti';

  @override
  String get navCalendar => 'Kalendář';

  @override
  String get serverConnection => 'Připojení k serveru';

  @override
  String get serverModeLocal => 'Spustit v této aplikaci';

  @override
  String get serverModeLocalDescription =>
      'Control Center spustí vlastní server na tomto stroji a data drží lokálně.';

  @override
  String get serverModeRemote => 'Připojit ke vzdálené instanci';

  @override
  String get serverModeRemoteDescription =>
      'Připojte se k serveru Control Center jinde. Data žijí na tom serveru.';

  @override
  String get serverRemoteUrl => 'URL serveru';

  @override
  String get serverRemoteDeviceId => 'ID zařízení';

  @override
  String get serverRemotePairingKey => 'Párovací klíč';

  @override
  String get serverRemotePairingKeyHint =>
      'Vložte párovací klíč ze vzdáleného serveru';

  @override
  String get serverSetupInviteCode => 'Kód pozvánky';

  @override
  String get serverSetupInviteCodeHint =>
      'Vložte jednorázový kód pozvánky (nechte prázdné pro párovací klíč)';

  @override
  String get serverDiscoveryTooltip => 'Najít servery v síti';

  @override
  String get serverDiscoveryTitle => 'Servery ve vaší síti';

  @override
  String get serverDiscoverySearching => 'Hledání serverů…';

  @override
  String get serverDiscoveryEmpty =>
      'Žádné servery nenalezeny. Zkontrolujte, že server běží a toto zařízení ho dosáhne, a hledejte znovu.';

  @override
  String get serverDiscoveryRefresh => 'Hledat znovu';

  @override
  String get serverListActive => 'Aktivní';

  @override
  String get serverListSwitch => 'Přepnout';

  @override
  String get serverListAddTitle => 'Přidat server';

  @override
  String get serverListRemoveActiveHint =>
      'Než tento server odeberete, přepněte na jiný.';

  @override
  String get serverSwitchFailedTitle => 'Server se nepodařilo přepnout';

  @override
  String get serverListInsecureBadge => 'Nezabezpečené';

  @override
  String get connectionPathLocal => 'Místní';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => 'Vypínání';

  @override
  String get shutdownSubtitle => 'Zavírání místního serveru';

  @override
  String get shutdownServiceApprovals => 'Schválení';

  @override
  String get shutdownServiceBackgroundJobs => 'Úlohy na pozadí';

  @override
  String get shutdownServiceScheduler => 'Plánovač úloh';

  @override
  String get shutdownServiceCalendar => 'Synchronizace kalendáře';

  @override
  String get shutdownServiceWeather => 'Počasí';

  @override
  String get shutdownServiceSoundscape => 'Soundscape';

  @override
  String get shutdownServiceMeetings => 'Schůzky';

  @override
  String get shutdownServiceVoiceModels => 'Hlasové modely';

  @override
  String get shutdownServiceNetworking => 'Síť';

  @override
  String get shutdownServicePresence => 'Přítomnost';

  @override
  String get shutdownServiceDataSync => 'Synchronizace dat';

  @override
  String get shutdownServiceDeviceRelay => 'Relé zařízení';

  @override
  String get shutdownServiceMcpConnections => 'Připojení MCP';

  @override
  String get shutdownServiceCodeEditors => 'Editory kódu';

  @override
  String get serverSharingTitle => 'Sdílet tento server';

  @override
  String get serverSharingDescription =>
      'Zpřístupněte tento server z ostatních zařízení. Nic se veřejně neodhalí, dokud níže nezapnete tunel. Pozvánky k párování automaticky vkládají aktuální adresy serveru — vytvářejte je v nastavení pracovního prostoru.';

  @override
  String get serverSharingUnavailable =>
      'Ovládání sdílení na tomto serveru není k dispozici.';

  @override
  String get serverSharingMdnsLabel => 'Objevování v LAN';

  @override
  String get serverSharingMdnsOn =>
      'Tento server se inzeruje v místní síti (mDNS)';

  @override
  String get serverSharingMdnsOff => 'Neinzeruje se v místní síti (mDNS)';

  @override
  String get serverSharingTunnelLabel => 'Tunel';

  @override
  String get serverSharingTunnelHelper =>
      'Zapnutím tunelu je tento server dostupný z internetu. Veřejné vystavení je volitelné a ve výchozím stavu vypnuté.';

  @override
  String get serverSharingProviderOff => 'Vypnuto';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => 'Veřejné URL';

  @override
  String get serverSharingTunnelStarting => 'Spouštění tunelu…';

  @override
  String serverSharingTunnelError(String error) {
    return 'Chyba tunelu: $error';
  }

  @override
  String get serverSharingTunnelUpNoUrl =>
      'Tunel běží. Dostanete se k němu na nastaveném DNS hostname.';

  @override
  String get serverSharingRelayLabel => 'Relé';

  @override
  String serverSharingRelayUsage(String amount) {
    return 'Relé za tento měsíc: $amount';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return 'Aktivní relé relace: $count';
  }

  @override
  String get serverSharingUpdateFailedTitle =>
      'Sdílení se nepodařilo aktualizovat';

  @override
  String get pairNewClient => 'Spárovat nového klienta';

  @override
  String get pairClientNameHint =>
      'Označte tohoto klienta (např. Pracovní notebook)';

  @override
  String get pairClientTypeWeb => 'Webový prohlížeč';

  @override
  String get pairClientTypeDesktop => 'Desktopová aplikace';

  @override
  String get pairClientTypePhone => 'Telefon';

  @override
  String get pairAction => 'Spárovat';

  @override
  String get revoke => 'Odvolat';

  @override
  String get pairCredentialsIntro =>
      'Nového klienta připojte těmito údaji, nebo v něm otevřete odkaz.';

  @override
  String get pairLinkLabel => 'Odkaz';

  @override
  String get pairScanQr =>
      'Naskenujte tento QR kód fotoaparátem telefonu pro spárování.';

  @override
  String get pairServerUnreachableTitle => 'Nedostupné';

  @override
  String get pairServerUnreachable =>
      'Ostatní zařízení tento server přímo nedosáhnou, takže se nový klient nemůže připojit. Nastavte veřejné URL serveru, abyste mohli párovat další klienty.';

  @override
  String get serverSetupTitle => 'Jak má Control Center běžet?';

  @override
  String get serverSetupSubtitle =>
      'Control Center potřebuje server, který vlastní vaše data. Spusťte ho v této aplikaci, nebo se připojte k instanci jinde.';

  @override
  String get serverSetupRunLocal => 'Spustit v této aplikaci';

  @override
  String get serverSetupConnect => 'Připojit';

  @override
  String get serverSetupInvalidUrl =>
      'Zadejte platné URL serveru ws:// nebo wss://.';

  @override
  String get serverSetupCouldNotConnect => 'Připojení se nezdařilo';

  @override
  String get serverSetupErrorUnreachable =>
      'Server se nepodařilo dosáhnout. Zkontrolujte, že běží a toto zařízení ho dosáhne (stejná síť nebo relé).';

  @override
  String get serverSetupErrorIdentityMismatch =>
      'Identita serveru se neshoduje s tou uloženou na tomto zařízení. Pokud byl server přeinstalován nebo resetován, odeberte uložený server a spárujte znovu.';

  @override
  String get serverSetupErrorAuthRejected =>
      'Server toto zařízení odmítl. Zkontrolujte, že párovací klíč a ID zařízení odpovídají tomu, co server vydal.';

  @override
  String get serverSetupErrorInviteRejected =>
      'Tento kód pozvánky je neplatný nebo vypršel. Požádejte o nový.';

  @override
  String get serverSetupErrorGeneric =>
      'Při připojování se něco pokazilo. Technické detaily rozbalíte níže.';

  @override
  String get serverSetupErrorDetails => 'Technické detaily';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dalších',
      many: '$count dalších',
      few: '$count další',
      one: '1 další',
    );
    return '$_temp0';
  }

  @override
  String get calendarAllDayGutter => 'Celodenní';

  @override
  String calendarAllDayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count událostí',
      many: '$count událostí',
      few: '$count události',
      one: '1 událost',
    );
    return '$_temp0';
  }

  @override
  String get calendarCollapseAllDay => 'Sbalit celodenní události';

  @override
  String get calendarExpandAllDay => 'Rozbalit celodenní události';

  @override
  String get calendarViewMonth => 'Měsíc';

  @override
  String get calendarViewWeek => 'Týden';

  @override
  String get calendarViewAgenda => 'Agenda';

  @override
  String get calendarConnectGoogle => 'Připojit Google Calendar';

  @override
  String get calendarConnectDescription =>
      'Synchronizujte Google Calendar, abyste tu viděli události a dostávali upozornění před začátkem schůzek.';

  @override
  String get calendarDisconnect => 'Odpojit';

  @override
  String get calendarReconnect => 'Znovu připojit';

  @override
  String get calendarEmptyNoEvents => 'V tomto rozsahu nejsou žádné události';

  @override
  String get calendarStartRecording => 'Spustit nahrávání';

  @override
  String get calendarStartRecordingAndLink => 'Spustit nahrávání a propojit';

  @override
  String get calendarJoinMeet => 'Připojit se ke schůzce';

  @override
  String get calendarFromCalendar => 'Z kalendáře';

  @override
  String get calendarLinkedMeeting => 'Propojená schůzka';

  @override
  String get calendarToday => 'Dnes';

  @override
  String get calendarAllDay => 'Celý den';

  @override
  String calendarWeekNumber(int number) {
    return 'Týden $number';
  }

  @override
  String get calendarPreviousPeriod => 'Předchozí';

  @override
  String get calendarNextPeriod => 'Další';

  @override
  String calendarLastSynced(String time) {
    return 'Synchronizováno $time';
  }

  @override
  String get calendarNeverSynced => 'Zatím nesynchronizováno';

  @override
  String get calendarSyncing => 'Synchronizace…';

  @override
  String get calendarViewDay => 'Den';

  @override
  String get calendarShow => 'Zobrazit';

  @override
  String get calendarHide => 'Skrýt';

  @override
  String get calendarRsvpGoing => 'Zúčastníte se?';

  @override
  String get calendarRsvpYes => 'Ano';

  @override
  String get calendarRsvpNo => 'Ne';

  @override
  String get calendarRsvpMaybe => 'Možná';

  @override
  String get calendarRsvpFailed => 'Odpověď se nepodařilo aktualizovat';

  @override
  String get calendarAddAccount => 'Přidat účet kalendáře';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Propojte účet Google a synchronizujte události do tohoto workspace. Tyto kalendáře jsou tady vaše.';

  @override
  String get calendarConnecting => 'Připojování…';

  @override
  String get calendarSyncNow => 'Synchronizovat teď';

  @override
  String get calendarNoWorkspace =>
      'Vyberte pracovní prostor pro zobrazení jeho kalendáře';

  @override
  String get calendarConnectError => 'Google Calendar se nepodařilo připojit';

  @override
  String get calendarClientIdLabel => 'Client ID';

  @override
  String get calendarClientSecretLabel => 'Client secret';

  @override
  String get calendarConnectCredsHint =>
      'Zadejte Google OAuth device-code client ID a secret svého projektu. Připojení a synchronizaci provádí server — prohlížeč tokeny nikdy nedrží.';

  @override
  String get calendarConnectApproveInstruction =>
      'Otevřete ověřovací stránku na libovolném zařízení, přihlaste se a zadejte tento kód:';

  @override
  String get calendarConnectOpenPage => 'Otevřít ověřovací stránku';

  @override
  String get calendarConnectWaiting => 'Čeká se na schválení…';

  @override
  String get calendarConnectDenied =>
      'Autorizace byla odmítnuta. Zkuste to znovu.';

  @override
  String get calendarConnectExpired => 'Kód vypršel. Zkuste to znovu.';

  @override
  String get notificationMeetingStartsSoon => 'Schůzka brzy začíná';

  @override
  String get notifyMeetingStartsSoon =>
      'Když má schůzka v kalendáři brzy začít';

  @override
  String get notificationCalendarAuthExpiredTitle => 'Kalendář odpojen';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'Znovu připojte $email a obnovte synchronizaci';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'Znovu připojte kalendář a obnovte synchronizaci';

  @override
  String get notifyCalendarAuthExpired =>
      'Když je potřeba znovu připojit účet kalendáře';

  @override
  String get notificationRigStatusChanged =>
      'Aktualizace izolovaného prostředí';

  @override
  String get notifyRigStatusChanged =>
      'Když někdo převezme izolované prostředí, je uvolněno nebo selže';

  @override
  String get notificationRigTakenOver => 'Izolované prostředí převzato';

  @override
  String get notificationRigTakenOverBody =>
      'Stroj ovládá člověk; agent může sledovat, ale ne jednat.';

  @override
  String get notificationRigReleased => 'Řízení izolovaného prostředí uvolněno';

  @override
  String get notificationRigReleasedBody => 'Agent má stroj zpět.';

  @override
  String get notificationRigReclaimed => 'Izolované prostředí uvolněno';

  @override
  String get notificationRigReclaimedBodyIdle =>
      'Stroj byl nečinný, proto se zavřel a uvolnil paměť.';

  @override
  String get notificationRigReclaimedBodyTtl =>
      'Dosáhl časového limitu a byl zavřen.';

  @override
  String get notificationRigFailed => 'Izolované prostředí selhalo';

  @override
  String get notificationRigFailedBody =>
      'Hypervisor pod ním spadl. Stroj znovu otevřete a pokračujte.';

  @override
  String get calendarAlertLeadTime => 'Předstih upozornění';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'Jak dlouho před schůzkou vás upozornit';

  @override
  String calendarConnectedAs(String email) {
    return 'Připojeno jako $email';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count účastníků';
  }

  @override
  String get calendarEventLabel => 'Událost';

  @override
  String get calendarRecurring => 'Opakovaná událost';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'Organizátor';

  @override
  String get calendarYou => 'Vy';

  @override
  String get calendarShowFewer => 'Zobrazit méně';

  @override
  String get calendarRsvpAwaiting => 'Čeká se';

  @override
  String calendarParticipantsCount(int count) {
    return '$count účastníků';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'Zobrazit všech $count účastníků';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count ano';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count ne';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count možná';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count čeká';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count min';
  }

  @override
  String get openInEditorPrompt => 'Otevřít v kterém editoru?';

  @override
  String get ideNotInstalled => 'Není nainstalováno';

  @override
  String openInIde(String editor) {
    return 'Otevřít v $editor';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return '$editor se nepodařilo otevřít: $error';
  }

  @override
  String get profileSearchHint => 'Hledat pull requesty…';

  @override
  String get stopAgentRun => 'Zastavit běh';

  @override
  String get stopAgentRunConfirm =>
      'Zastavit tento běh? Rozpracovaná práce se ztratí.';

  @override
  String get inProgress => 'Probíhá';

  @override
  String get drafts => 'Koncepty';

  @override
  String get sortOldest => 'Nejstarší';

  @override
  String get sortLargest => 'Největší';

  @override
  String get prFilterTooltip => 'Filtr';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aktivních filtrů',
      many: '$count aktivních filtrů',
      few: '$count aktivní filtry',
      one: '1 aktivní filtr',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => 'Přidat filtr…';

  @override
  String get prFilterFieldHint => 'Filtrovat…';

  @override
  String get prFilterCategoryStatus => 'Stav';

  @override
  String get prFilterCategoryAuthor => 'Autor';

  @override
  String get prFilterCategoryReviewer => 'Recenzenti';

  @override
  String get prFilterCategoryContent => 'Obsah';

  @override
  String get prFilterCategoryRepoOwner => 'Vlastník repozitáře';

  @override
  String get prFilterCategoryRepoName => 'Název repozitáře';

  @override
  String get prFilterCategoryOpenedDate => 'Datum otevření';

  @override
  String get prFilterCategoryUpdatedDate => 'Datum aktualizace';

  @override
  String get prFilterQuickToReview => 'Rychlé ke kontrole';

  @override
  String get prFilterClearAll => 'Vymazat filtry';

  @override
  String prFilterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requestů',
      many: '$count pull requestů',
      few: '$count pull requesty',
      one: '1 pull request',
    );
    return '$_temp0';
  }

  @override
  String prFilterHiddenOptions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count možností neodpovídá žádným pull requestům',
      many: '$count možností neodpovídá žádným pull requestům',
      few: '$count možnosti neodpovídají žádným pull requestům',
      one: '1 možnost neodpovídá žádnému pull requestu',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => 'Název nebo tělo obsahuje…';

  @override
  String get prFilterNoOptions => 'Žádné odpovídající možnosti';

  @override
  String get prFilterChipIs => 'je';

  @override
  String get prFilterChipIsAnyOf => 'je některé z';

  @override
  String get prFilterChipContains => 'obsahuje';

  @override
  String get prFilterChipSince => 'od';

  @override
  String get prFilterAddFilterButton => 'Přidat filtr';

  @override
  String prFilterClearCategory(String category) {
    return 'Vymazat filtr $category';
  }

  @override
  String get prFilterCurrentUser => 'Aktuální uživatel';

  @override
  String get prStatusDraft => 'Koncept';

  @override
  String get prStatusOpen => 'Otevřený';

  @override
  String get prStatusInReview => 'V kontrole';

  @override
  String get prStatusChangesRequested => 'Vyžádány změny';

  @override
  String get prStatusApproved => 'Schváleno';

  @override
  String get prStatusMerged => 'Sloučeno';

  @override
  String get prStatusClosed => 'Zavřeno';

  @override
  String get prDateWindowDay => 'před 1 dnem';

  @override
  String get prDateWindowThreeDays => 'před 3 dny';

  @override
  String get prDateWindowWeek => 'před 1 týdnem';

  @override
  String get prDateWindowMonth => 'před 1 měsícem';

  @override
  String get prDateWindowThreeMonths => 'před 3 měsíci';

  @override
  String get prDateWindowSixMonths => 'před 6 měsíci';

  @override
  String get prDateWindowYear => 'před 1 rokem';

  @override
  String get prDisplayOptions => 'Možnosti zobrazení';

  @override
  String get prDisplayGrouping => 'Seskupení';

  @override
  String get prDisplayOrdering => 'Řazení';

  @override
  String get prDisplayShowDrafts => 'Zobrazit koncepty';

  @override
  String get prDisplayMergedWindow => 'Okno sloučení';

  @override
  String get prDisplayMergedWindowDay => 'Poslední den';

  @override
  String get prDisplayMergedWindowWeek => 'Poslední týden';

  @override
  String get prDisplayMergedWindowMonth => 'Poslední měsíc';

  @override
  String get prDisplayProperties => 'Zobrazené vlastnosti';

  @override
  String get prGroupingRepository => 'Repozitář';

  @override
  String get prGroupingAuthor => 'Autor';

  @override
  String get prGroupingStatus => 'Stav';

  @override
  String get prGroupingNone => 'Bez seskupení';

  @override
  String get prPropertyRepository => 'Repozitář';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => 'Větev';

  @override
  String get prPropertyUpdated => 'Aktualizováno';

  @override
  String get prPropertyAuthor => 'Autor';

  @override
  String get prPropertyChecks => 'Kontroly';

  @override
  String get prPropertyDiff => 'Diff';

  @override
  String get prPropertyComments => 'Komentáře';

  @override
  String get keybindingOpenFilterMenu => 'Otevřít nabídku filtrů';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'Otevřít nabídku filtrů pull requestů';

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vybráno',
      many: '$count vybráno',
      few: '$count vybrány',
      one: '1 vybráno',
    );
    return '$_temp0';
  }

  @override
  String get summary => 'Shrnutí';

  @override
  String get kbMove => 'pohyb';

  @override
  String get kbTabs => 'karty';

  @override
  String get kbSearch => 'hledat';

  @override
  String get kbViewed => 'zhlédnuto';

  @override
  String get kbCollapse => 'sbalit';

  @override
  String get appearance => 'Vzhled';

  @override
  String get appearanceSettingsDescription => 'Motiv, jazyk a typografie.';

  @override
  String get notificationsSettingsDescription =>
      'Vyberte, která oznámení agenta a pracovního prostoru chcete dostávat.';

  @override
  String get advanced => 'Pokročilé';

  @override
  String get accounts => 'Účty';

  @override
  String get mcpServers => 'Servery MCP';

  @override
  String get mcpServersSettingsDescription =>
      'Vestavěný server MCP a externí servery MCP.';

  @override
  String get remoteControlAndDevices => 'Vzdálené ovládání a zařízení';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'Spárujte telefony a nastavte server vzdáleného ovládání.';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'Modely řeči a diarizace, které tento server hostuje.';

  @override
  String get needsSetupLabel => 'Vyžaduje nastavení';

  @override
  String get collapseSidebar => 'Sbalit postranní panel';

  @override
  String get expandSidebar => 'Rozbalit postranní panel';

  @override
  String get filterSpacesHint => 'Filtrovat prostory';

  @override
  String noSpacesMatch(String query) {
    return 'Žádné prostory neodpovídají „$query“';
  }

  @override
  String get privacy => 'Soukromí';

  @override
  String get sendDiffContentTitle => 'Odesílat obsah diffu do AI adaptéru';

  @override
  String get diffSharingOnSubtitle =>
      'Do promptů agenta se pro hlubší kontrolu vkládají surové řádky diffu.';

  @override
  String get diffSharingOffSubtitle =>
      'Agenti používají jen strukturovaná metadata (cesty k souborům, čísla řádků, popis PR); surový kód aplikaci neopustí.';

  @override
  String get errorReportingTitle => 'Sdílet hlášení pádů';

  @override
  String get errorReportingOnSubtitle =>
      'Diagnostika pádů, chyb a výkonu se odesílá kvůli opravám (jen vydané sestavení).';

  @override
  String get errorReportingOffSubtitle =>
      'Diagnostika je vypnutá. Hlášení pádů ani chyb se neodesílají.';

  @override
  String get onboardingDiagnosticsTitle => 'Pomozte vylepšit Control Center';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'Odesílejte diagnostiku pádů, chyb a výkonu, abychom problémy opravili rychleji (jen vydané sestavení). Změnit to můžete kdykoli v Nastavení → Soukromí.';

  @override
  String get blocked => 'Blokováno';

  @override
  String get idle => 'Nečinný';

  @override
  String get noRunsYet => 'Zatím žádné běhy';

  @override
  String get copyPath => 'Kopírovat cestu';

  @override
  String get copyRelativePath => 'Kopírovat relativní cestu';

  @override
  String get nameRequired => 'Název je povinný';

  @override
  String get import => 'Importovat';

  @override
  String get noMatchingAgents => 'Žádní agenti neodpovídají filtru';

  @override
  String watchVideoOn(String provider) {
    return 'Sledovat video na $provider';
  }

  @override
  String get branchTemplate => 'Šablona názvu větve';

  @override
  String get branchTemplateDescription =>
      'Vzor větve vytvořené při spuštění ticketu v izolovaném worktree.';

  @override
  String branchTemplatePreview(String example) {
    return 'Příklad: $example';
  }

  @override
  String get deletePipelineRun => 'Smazat běh pipeline';

  @override
  String deletePipelineRunConfirm(String template) {
    return 'Smazat tento běh „$template“? Tuto akci nelze vrátit zpět.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'Chyba při mazání běhu pipeline: $error';
  }

  @override
  String get deleteTicket => 'Smazat ticket';

  @override
  String deleteTicketConfirm(String title) {
    return 'Smazat „$title“? Tuto akci nelze vrátit zpět.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'Chyba při mazání ticketu: $error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return 'Smazat „$name“? Propojené repozitáře na disku zůstanou nedotčené.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'Chyba při mazání pracovního prostoru: $error';
  }

  @override
  String get indexCode => 'Indexovat kód';

  @override
  String get indexNoGrammars => 'Gramatiky kódu nejsou nainstalované';

  @override
  String get indexFailed => 'Indexování selhalo';

  @override
  String indexedSymbolsCount(int count) {
    return 'Indexováno $count symbolů';
  }

  @override
  String get nodeConfigAdvanced => 'Pokročilé';

  @override
  String get nodeConfigReducer => 'Reducer';

  @override
  String get nodeConfigReducerHelp =>
      'Jak sloučit, když tento výstupní klíč už má hodnotu';

  @override
  String get nodeConfigTimeoutMs => 'Časový limit (ms)';

  @override
  String get nodeConfigRetryAttempts => 'Počet pokusů';

  @override
  String get nodeConfigContinueOnFail => 'Pokračovat, pokud tento krok selže';

  @override
  String get nodeConfigTeamId => 'ID týmu';

  @override
  String get nodeConfigDispatchMode => 'Režim dispatch';

  @override
  String get nodeConfigOutputSchema => 'Výstupní schéma (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'JSON Schema, které musí výstup kroku splnit';

  @override
  String get diffLineDisplay => 'Dlouhé řádky v diffech';

  @override
  String get diffLineDisplayDescription =>
      'Zalamovat dlouhé řádky, nebo je posouvat vodorovně';

  @override
  String get diffLineWrap => 'Zalamovat';

  @override
  String get diffLineScroll => 'Posouvat vodorovně';

  @override
  String get actions => 'Akce';

  @override
  String get activate => 'Aktivovat';

  @override
  String get activity => 'Aktivita';

  @override
  String get activityLabel => 'AKTIVITA';

  @override
  String get activitySearchHint => 'Hledat v aktivitě';

  @override
  String get activityNoMatches => 'Žádná aktivita neodpovídá filtrům';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$start–$end z $total';
  }

  @override
  String get activityPreviousPage => 'Předchozí stránka';

  @override
  String get activityNextPage => 'Další stránka';

  @override
  String get activityNetworkLocal => 'Localhost';

  @override
  String get activityClearFilter => 'Vymazat filtr';

  @override
  String activityFilterIp(String ip) {
    return 'IP $ip';
  }

  @override
  String activityFilterCountry(String country) {
    return 'Země $country';
  }

  @override
  String get activitySavedWorkspaceLogo => 'Logo pracovního prostoru uloženo';

  @override
  String activityVerbCreated(String target) {
    return 'Vytvořeno: $target';
  }

  @override
  String activityVerbUpdated(String target) {
    return 'Aktualizováno: $target';
  }

  @override
  String activityVerbDeleted(String target) {
    return 'Smazáno: $target';
  }

  @override
  String activityVerbAdded(String target) {
    return 'Přidáno: $target';
  }

  @override
  String activityVerbRemoved(String target) {
    return 'Odebráno: $target';
  }

  @override
  String activityVerbInvited(String target) {
    return 'Pozváno: $target';
  }

  @override
  String activityVerbChanged(String target) {
    return 'Změněno: $target';
  }

  @override
  String activityVerbStarted(String target) {
    return 'Spuštěno: $target';
  }

  @override
  String activityVerbStopped(String target) {
    return 'Zastaveno: $target';
  }

  @override
  String activityVerbWrote(String target) {
    return 'Zapsáno: $target';
  }

  @override
  String get activityTargetAgent => 'agent';

  @override
  String get activityTargetTicket => 'ticket';

  @override
  String get activityTargetWorkspace => 'pracovní prostor';

  @override
  String get activityTargetRepository => 'repozitář';

  @override
  String get activityTargetMember => 'člen';

  @override
  String get activityTargetInvite => 'pozvánka';

  @override
  String get activityTargetSpace => 'prostor';

  @override
  String get activityTargetMessage => 'zpráva';

  @override
  String get activityTargetCache => 'cache';

  @override
  String get activityTargetFile => 'soubor';

  @override
  String get activityTargetPipeline => 'pipeline';

  @override
  String get activityTargetTemplate => 'šablona';

  @override
  String get activityTargetProvider => 'poskytovatel';

  @override
  String get activityTargetModel => 'model';

  @override
  String get activityTargetSkill => 'dovednost';

  @override
  String get activityTargetTodo => 'úkol';

  @override
  String get activityTargetMeeting => 'schůzka';

  @override
  String get activityTargetProject => 'projekt';

  @override
  String get activityTargetTeam => 'tým';

  @override
  String get activityTargetDevice => 'zařízení';

  @override
  String get activityTargetPreference => 'předvolba';

  @override
  String get activityTargetBudget => 'rozpočet';

  @override
  String activityVerbApproved(String target) {
    return 'Schváleno: $target';
  }

  @override
  String activityVerbArchived(String target) {
    return 'Archivováno: $target';
  }

  @override
  String activityVerbAssigned(String target) {
    return 'Přiřazeno: $target';
  }

  @override
  String activityVerbBackedUp(String target) {
    return 'Zálohováno: $target';
  }

  @override
  String activityVerbCancelled(String target) {
    return 'Zrušeno: $target';
  }

  @override
  String activityVerbCleared(String target) {
    return 'Vymazáno: $target';
  }

  @override
  String activityVerbClosed(String target) {
    return 'Zavřeno: $target';
  }

  @override
  String activityVerbCommitted(String target) {
    return 'Commitnuto: $target';
  }

  @override
  String activityVerbCompacted(String target) {
    return 'Zkomprimováno: $target';
  }

  @override
  String activityVerbCompleted(String target) {
    return 'Dokončeno: $target';
  }

  @override
  String activityVerbConnected(String target) {
    return 'Připojeno: $target';
  }

  @override
  String activityVerbContinued(String target) {
    return 'Pokračováno: $target';
  }

  @override
  String activityVerbDisconnected(String target) {
    return 'Odpojeno: $target';
  }

  @override
  String activityVerbDispatched(String target) {
    return 'Odesláno: $target';
  }

  @override
  String activityVerbDrained(String target) {
    return 'Vyprázdněno: $target';
  }

  @override
  String activityVerbEnrolled(String target) {
    return 'Zaregistrováno: $target';
  }

  @override
  String activityVerbEstimated(String target) {
    return 'Odhadnuto: $target';
  }

  @override
  String activityVerbImported(String target) {
    return 'Importováno: $target';
  }

  @override
  String activityVerbInstalled(String target) {
    return 'Nainstalováno: $target';
  }

  @override
  String activityVerbKilled(String target) {
    return 'Ukončeno: $target';
  }

  @override
  String activityVerbMarked(String target) {
    return 'Označeno: $target';
  }

  @override
  String activityVerbMerged(String target) {
    return 'Sloučeno: $target';
  }

  @override
  String activityVerbOpened(String target) {
    return 'Otevřeno: $target';
  }

  @override
  String activityVerbPaused(String target) {
    return 'Pozastaveno: $target';
  }

  @override
  String activityVerbPolled(String target) {
    return 'Dotázáno: $target';
  }

  @override
  String activityVerbPrepared(String target) {
    return 'Připraveno: $target';
  }

  @override
  String activityVerbProcessed(String target) {
    return 'Zpracováno: $target';
  }

  @override
  String activityVerbPublished(String target) {
    return 'Zveřejněno: $target';
  }

  @override
  String activityVerbRefined(String target) {
    return 'Upřesněno: $target';
  }

  @override
  String activityVerbRefreshed(String target) {
    return 'Obnoveno: $target';
  }

  @override
  String activityVerbRegistered(String target) {
    return 'Zaregistrováno: $target';
  }

  @override
  String activityVerbRenamed(String target) {
    return 'Přejmenováno: $target';
  }

  @override
  String activityVerbReordered(String target) {
    return 'Přeuspořádáno: $target';
  }

  @override
  String activityVerbResponded(String target) {
    return 'Odpovězeno na $target';
  }

  @override
  String activityVerbRestored(String target) {
    return 'Obnoveno: $target';
  }

  @override
  String activityVerbResumed(String target) {
    return 'Pokračováno: $target';
  }

  @override
  String activityVerbRetried(String target) {
    return 'Zopakováno: $target';
  }

  @override
  String activityVerbReverted(String target) {
    return 'Vráceno: $target';
  }

  @override
  String activityVerbReviewed(String target) {
    return 'Zkontrolováno: $target';
  }

  @override
  String activityVerbRan(String target) {
    return 'Spuštěno: $target';
  }

  @override
  String activityVerbSelected(String target) {
    return 'Vybráno: $target';
  }

  @override
  String activityVerbSent(String target) {
    return 'Odesláno: $target';
  }

  @override
  String activityVerbStaged(String target) {
    return 'Zařazeno do stage: $target';
  }

  @override
  String activityVerbSteered(String target) {
    return 'Usměrněno: $target';
  }

  @override
  String activityVerbSubmitted(String target) {
    return 'Odesláno: $target';
  }

  @override
  String activityVerbSynced(String target) {
    return 'Synchronizováno: $target';
  }

  @override
  String activityVerbToggled(String target) {
    return 'Přepnuto: $target';
  }

  @override
  String activityVerbUninstalled(String target) {
    return 'Odinstalováno: $target';
  }

  @override
  String activityVerbUnstaged(String target) {
    return 'Odebráno ze stage: $target';
  }

  @override
  String get activityTargetActionPolicy => 'politika akcí';

  @override
  String get activityTargetGoalRun => 'běh cíle';

  @override
  String get activityTargetRunLog => 'protokol běhu';

  @override
  String get activityTargetWorkingMemory => 'pracovní paměť';

  @override
  String get activityTargetRoutingPolicy => 'politika směrování';

  @override
  String get activityTargetAutonomy => 'autonomie';

  @override
  String get activityTargetCalendar => 'kalendář';

  @override
  String get activityTargetChecker => 'kontrola';

  @override
  String get activityTargetEditor => 'editor';

  @override
  String get activityTargetConfirmation => 'potvrzení';

  @override
  String get activityTargetTunnel => 'tunel';

  @override
  String get activityTargetConversation => 'konverzace';

  @override
  String get activityTargetCredentials => 'přihlašovací údaje';

  @override
  String get activityTargetDictation => 'diktování';

  @override
  String get activityTargetAgentRun => 'běh agenta';

  @override
  String get activityTargetEvalSuite => 'sada eval';

  @override
  String get activityTargetWorker => 'worker';

  @override
  String get activityTargetWorktree => 'worktree';

  @override
  String get activityTargetMcpServer => 'server MCP';

  @override
  String get activityTargetMemoryAccessGrant => 'přístup k paměti';

  @override
  String get activityTargetMemoryDomain => 'doména paměti';

  @override
  String get activityTargetMemoryFact => 'fakt paměti';

  @override
  String get activityTargetMemoryPolicy => 'politika paměti';

  @override
  String get activityTargetFeed => 'kanál';

  @override
  String get activityTargetNote => 'poznámka';

  @override
  String get activityTargetOrchestration => 'orchestrace';

  @override
  String get activityTargetPipelineRun => 'běh pipeline';

  @override
  String get activityTargetPipelineTrigger => 'spouštěč pipeline';

  @override
  String get activityTargetPlan => 'plán';

  @override
  String get activityTargetPlaybook => 'playbook';

  @override
  String get activityTargetPullRequest => 'pull request';

  @override
  String get activityTargetReview => 'kontrola';

  @override
  String get activityTargetProcess => 'proces';

  @override
  String get activityTargetProviderPolicy => 'politika poskytovatele';

  @override
  String get activityTargetReaction => 'reakce';

  @override
  String get activityTargetReviewSpace => 'prostor kontroly';

  @override
  String get activityTargetReviewStudio => 'studio kontroly';

  @override
  String get activityTargetServerData => 'data serveru';

  @override
  String get activityTargetSoundscape => 'soundscape';

  @override
  String get activityTargetSession => 'relace';

  @override
  String get activityTargetTerminal => 'terminál';

  @override
  String get activityTargetTicketLink => 'odkaz ticketu';

  @override
  String get activityTargetTicketSync => 'synchronizace ticketu';

  @override
  String get activityTargetProfile => 'profil';

  @override
  String get activityTargetVoiceProfile => 'hlasový profil';

  @override
  String get activityTargetWeather => 'předpověď počasí';

  @override
  String get activityTargetWorkProduct => 'pracovní produkt';

  @override
  String get activityChangedMemberRole => 'Změněna role člena';

  @override
  String get activityChangedMemberRepoAccess =>
      'Změněn přístup člena k repozitáři';

  @override
  String get activityUpdatedGitHubToken => 'Aktualizován token GitHub';

  @override
  String get activityRefreshedWeather => 'Obnovena předpověď počasí';

  @override
  String get activitySetWeatherLocation => 'Nastaveno místo počasí';

  @override
  String get activityClearedWeatherLocation => 'Vymazáno místo počasí';

  @override
  String get activityMarkedAllArticlesRead =>
      'Všechny články označeny jako přečtené';

  @override
  String get activityMarkedArticleRead => 'Článek označen jako přečtený';

  @override
  String get activityUpdatedSavedArticle => 'Aktualizován uložený článek';

  @override
  String get activityTookOverSession => 'Relace převzata';

  @override
  String get activityHandedBackSession => 'Relace vrácena';

  @override
  String get activityCommittedAndPushed => 'Commitnuto a odesláno';

  @override
  String get activityBackedUpServer => 'Zálohována data serveru';

  @override
  String get activityMarkedSpaceRead => 'Prostor označen jako přečtený';

  @override
  String get activityRespondedToInvitation =>
      'Odpovězeno na pozvánku k události';

  @override
  String get activityStartedCalendarConnect => 'Zahájeno připojení kalendáře';

  @override
  String get activityDisconnectedCalendar => 'Kalendář odpojen';

  @override
  String get activityMarkedFileViewed => 'Soubor označen jako zhlédnutý';

  @override
  String get activityRespondedToApproval => 'Odpovězeno na žádost o schválení';

  @override
  String get activityChangedTunnel => 'Změněno nastavení tunelu';

  @override
  String get activitySentMessageToAgent => 'Odeslána zpráva agentovi';

  @override
  String get activityOpenedReviewSpace => 'Otevřen prostor kontroly';

  @override
  String get activityOpenedStandingConversation => 'Otevřena stálá konverzace';

  @override
  String get activityStartedRecording => 'Nahrávání spuštěno';

  @override
  String get activityStoppedRecording => 'Nahrávání zastaveno';

  @override
  String get activityToggledMcpServer => 'Přepnut server MCP';

  @override
  String get activityUpdatedMcpToken => 'Aktualizován token MCP';

  @override
  String get activitySavedApiKey => 'Uložen API klíč';

  @override
  String get activityRemovedProviderCredential =>
      'Odebrány přihlašovací údaje poskytovatele';

  @override
  String get activityUpdatedLinkedRepos => 'Aktualizovány propojené repozitáře';

  @override
  String get activityUnlinkedRepo => 'Odpojen repozitář';

  @override
  String get activityUpdatedActionItem => 'Aktualizována akční položka';

  @override
  String adRulesCount(int count) {
    return '$count pravidel reklam';
  }

  @override
  String get adapter => 'Adaptér';

  @override
  String get adapterLabel => 'Adaptér';

  @override
  String get adapters => 'Adaptéry';

  @override
  String get adaptersAutoDetected =>
      'Automaticky zjištění runneri agentů na tomto stroji. Nainstalujte chybějící nástroje CLI a povolíte další.';

  @override
  String get add => 'Přidat';

  @override
  String get addAComment => 'Přidat komentář';

  @override
  String get addAReaction => 'Přidat reakci';

  @override
  String get addASuggestion => 'Přidat návrh';

  @override
  String get addAgents => 'Přidat agenty';

  @override
  String get addEmoji => 'Přidat emoji';

  @override
  String get addFeed => 'Přidat kanál';

  @override
  String get addressBarHint => 'Zadejte URL';

  @override
  String get addFromFile => 'Přidat ze souboru';

  @override
  String get addGif => 'Přidat GIF';

  @override
  String get addGithubRepoPrompt =>
      'Přidejte alespoň jeden GitHub repozitář, abyste viděli pull requesty';

  @override
  String get addLocalCheckoutDescription =>
      'Přidejte místní checkout a začněte ho v tomto pracovním prostoru cílit.';

  @override
  String get addRepository => 'Přidat repozitář';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Přidat $count repozitářů',
      many: 'Přidat $count repozitářů',
      few: 'Přidat $count repozitáře',
      one: 'Přidat repozitář',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro =>
      'Procházejte složky na stroji se serverem a vyberte git checkouty k registraci.';

  @override
  String get selectThisFolder => 'Vybrat tuto složku';

  @override
  String get deselectThisFolder => 'Zrušit výběr této složky';

  @override
  String get goUp => 'Nahoru';

  @override
  String get noSubfoldersHere => 'Tady nejsou žádné podsložky';

  @override
  String get notAGitRepository => 'Tato složka není git repozitář.';

  @override
  String get addToken => 'Přidat token';

  @override
  String get addWorkspace => 'Přidat pracovní prostor';

  @override
  String get addWorkspaceEllipsis => 'Přidat pracovní prostor…';

  @override
  String get added => 'Přidáno';

  @override
  String get addingEllipsis => 'Přidávání…';

  @override
  String get advancedLabel => 'Pokročilé';

  @override
  String get agent => 'Agent';

  @override
  String agentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agentů',
      many: '$count agentů',
      few: '$count agenti',
      one: '$count agent',
    );
    return '$_temp0';
  }

  @override
  String get agentMdPath => 'Cesta k Agent MD';

  @override
  String get agentName => 'Název agenta';

  @override
  String get agentTitle => 'Titul agenta';

  @override
  String get agentUpdated => 'Agent aktualizován.';

  @override
  String get agents => 'Agenti';

  @override
  String get agentsMentionSection => 'Agenti';

  @override
  String get usersMentionSection => 'Lidé';

  @override
  String get ticketsMentionSection => 'Tickety';

  @override
  String get pullRequestsMentionSection => 'Pull requesty';

  @override
  String get meetingsMentionSection => 'Schůzky';

  @override
  String get entityRefTicketFallback => 'Ticket';

  @override
  String get entityRefPrFallback => 'Pull request';

  @override
  String get entityRefMeetingFallback => 'Schůzka';

  @override
  String get aiReview => 'AI kontrola';

  @override
  String get all => 'Vše';

  @override
  String get allAgentsAlreadyInSpace =>
      'Všichni agenti už jsou v tomto prostoru.';

  @override
  String get allCommits => 'Všechny commity';

  @override
  String get allSources => 'Všechny zdroje';

  @override
  String get allow => 'Povolit';

  @override
  String get allowGitPush => 'Povolit git push';

  @override
  String get allowGithubApi => 'Povolit volání GitHub API';

  @override
  String get allowNetwork => 'Povolit obecný přístup k síti';

  @override
  String get apiKeys => 'API klíče';

  @override
  String get appFont => 'Písmo aplikace';

  @override
  String get appLogLevelDebugDescription => 'Přidá podrobné stopy — pro vývoj.';

  @override
  String get appLogLevelDebugLabel => 'Ladění';

  @override
  String get appLogLevelErrorDescription => 'Jen neočekávané chyby a výjimky.';

  @override
  String get appLogLevelErrorLabel => 'Chyba';

  @override
  String get appLogLevelInfoDescription =>
      'Přidá zprávy o životním cyklu a stavu.';

  @override
  String get appLogLevelInfoLabel => 'Info';

  @override
  String get appLogLevelNoneDescription => 'Žádný výstup do konzole.';

  @override
  String get appLogLevelNoneLabel => 'Žádný';

  @override
  String get appLogLevelVerboseDescription =>
      'Všechno. Extrémně hlučné — jen pro ladění.';

  @override
  String get appLogLevelVerboseLabel => 'Podrobné';

  @override
  String get appLogLevelWarningDescription =>
      'Přidá varování a obnovitelné problémy.';

  @override
  String get appLogLevelWarningLabel => 'Varování';

  @override
  String get appearanceLanguage => 'Vzhled a jazyk';

  @override
  String get apply => 'Použít';

  @override
  String get approve => 'Schválit';

  @override
  String get agentApprovalRequired => 'Vyžadováno schválení';

  @override
  String agentApprovalsMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dalších čeká',
      many: '$count dalších čeká',
      few: '$count další čekají',
      one: '1 další čeká',
    );
    return '$_temp0';
  }

  @override
  String get approved => 'Schváleno';

  @override
  String get articleNoun => 'Článek';

  @override
  String get articlesSubscribed => 'Články z odebíraných kanálů.';

  @override
  String get askAi => 'Zeptat se AI';

  @override
  String get askAiReviewDescription => 'Požádat AI o kontrolu tohoto PR';

  @override
  String get assignees => 'Přiřazení';

  @override
  String get attachImage => 'Přiložit obrázek';

  @override
  String get attachedAgents => 'Připojení agenti';

  @override
  String get audioInput => 'Zvukový vstup';

  @override
  String get audioOutput => 'Zvukový výstup';

  @override
  String get authenticationToken => 'Autentizační token';

  @override
  String authoredByLabel(String role) {
    return 'Od: $role';
  }

  @override
  String get autoRecommended => 'Auto (doporučeno)';

  @override
  String get available => 'Dostupné';

  @override
  String get awaitingYourReview => 'Čeká na vaši kontrolu';

  @override
  String get back => 'Zpět';

  @override
  String get backLabel => 'Zpět';

  @override
  String get backend => 'Backend';

  @override
  String get blockAdsTrackers => 'Blokovat reklamy, trackery a cookie bannery';

  @override
  String get blocking => 'Blokování';

  @override
  String get bookmarkLabel => 'Záložka';

  @override
  String get briefDescription => 'Stručný popis';

  @override
  String get bugLabel => 'CHYBA';

  @override
  String get bundledDefaultsNeverUpdated =>
      'Balené výchozí — nikdy neaktualizováno';

  @override
  String get cancel => 'Zrušit';

  @override
  String get cancelEdit => 'Zrušit úpravy';

  @override
  String get categoryCreation => 'Vytváření';

  @override
  String get categoryEditing => 'Úpravy';

  @override
  String get categoryNavigation => 'Navigace';

  @override
  String get categorySystem => 'Systém';

  @override
  String get categoryView => 'Zobrazení kategorie';

  @override
  String get change => 'Změnit';

  @override
  String get changesRequested => 'Vyžádány změny';

  @override
  String get spacesMentionSection => 'Prostory';

  @override
  String get checkForUpdates => 'Zkontrolovat aktualizace';

  @override
  String get checking => 'Kontrola';

  @override
  String get checkingEllipsis => 'Kontrola…';

  @override
  String get chooseAppFont => 'Vybrat písmo aplikace';

  @override
  String get chooseCodeFont => 'Vybrat písmo kódu';

  @override
  String get chooseRunner => 'Vyberte runner agenta.';

  @override
  String get clear => 'Vymazat';

  @override
  String get clickToRetry => 'Klikněte pro opakování';

  @override
  String get close => 'Zavřít';

  @override
  String get closeEsc => 'Zavřít (Esc)';

  @override
  String get closeReader => 'Zavřít čtečku';

  @override
  String get closed => 'Zavřeno';

  @override
  String get codeFont => 'Písmo kódu';

  @override
  String get codeFontLigatures => 'Ligatury písma kódu';

  @override
  String get codeFontLigaturesDescription =>
      'Vykreslit programátorské ligatury (=>, !=, ->) jako sloučené glyfy v kódu a diffech';

  @override
  String get collapse => 'Sbalit';

  @override
  String get commandPalette => 'Paleta příkazů';

  @override
  String get commandPaletteOrgMembers => 'Členové organizace';

  @override
  String get commandPaletteBrowseTeam => 'Procházet tým';

  @override
  String get commandPaletteBrowseTeamDesc =>
      'Zobrazit všechny členy organizace';

  @override
  String get compactDone =>
      'Konverzace zkomprimována. Starší historie byla sbalena do shrnutí.';

  @override
  String get compactNothing =>
      'Zatím není co komprimovat. Konverzace je ještě krátká.';

  @override
  String get compactBusy =>
      'Agent ještě pracuje. Komprimujte až po dokončení tahu.';

  @override
  String get compactUnavailable =>
      'Komprimace na tomto serveru není k dispozici.';

  @override
  String get commandsMentionSection => 'Příkazy';

  @override
  String get comment => 'Komentář';

  @override
  String get commentOnThisFile => 'Komentovat tento soubor';

  @override
  String get commented => 'Okomentováno';

  @override
  String get commits => 'Commity';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'Zobrazeno nejnovějších $loaded z $total commitů';
  }

  @override
  String get prCloneProgressCloningTitle => 'Klonování repozitáře';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'Tento PR mění $fileCount souborů, což překračuje limit GitHub API. Repozitář se klonuje lokálně…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'Tento PR překračuje limit souborů GitHub API. Repozitář se klonuje lokálně…';

  @override
  String get prCloneProgressFetchingTitle => 'Načítání refů PR';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'Načítání základní větve a head ref PR…';

  @override
  String get prCloneProgressComputingTitle => 'Výpočet diffu';

  @override
  String get prCloneProgressComputingSubtitle => 'Lokální spuštění git diff…';

  @override
  String get prCloneProgressErrorTitle => 'Diff se nepodařilo načíst';

  @override
  String get prCloneProgressErrorSubtitle =>
      'Při klonování nebo výpočtu diffu nastala chyba. Zkuste obnovit.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'Stále probíhá… uplynulo $elapsed';
  }

  @override
  String confidenceLabel(int percent) {
    return 'Jistota: $percent %';
  }

  @override
  String get configureAgentIdentities =>
      'Nastavte identity agentů, prompty, dovednosti a prohlížejte běhy.';

  @override
  String get configureDefaultRunners =>
      'Nastavte, který adaptér a model se použije pro nové prostory a generování názvů.';

  @override
  String get configuredLabel => 'Nastaveno.';

  @override
  String get confirmedBy => 'Potvrdil';

  @override
  String get consensus => 'Konsenzus';

  @override
  String get contentHint => 'Co si zapamatovat';

  @override
  String get contentLabel => 'Obsah';

  @override
  String get contentMarkdown => 'Obsah (Markdown)';

  @override
  String get contextWindowSize => 'Velikost kontextového okna';

  @override
  String modelContextChip(String size) {
    return 'Model · $size';
  }

  @override
  String get continueLabel => 'Pokračovat';

  @override
  String get conversationMode => 'Režim';

  @override
  String cookieRulesCount(int count) {
    return '$count pravidel cookies';
  }

  @override
  String get copied => 'Zkopírováno!';

  @override
  String get copy => 'Kopírovat';

  @override
  String get copyAddress => 'Kopírovat adresu';

  @override
  String get copyBaseBranchTooltip => 'Kopírovat název základní větve';

  @override
  String get copyHeadBranchTooltip => 'Kopírovat název head větve';

  @override
  String couldNotListDevices(String error) {
    return 'Zařízení se nepodařilo vypsat: $error';
  }

  @override
  String get create => 'Vytvořit';

  @override
  String get createOrSelectWorkspace =>
      'Než přidáte repozitáře, vytvořte nebo vyberte pracovní prostor.';

  @override
  String get createPullRequest => 'Vytvořit pull request';

  @override
  String get createdByMe => 'Vytvořeno mnou';

  @override
  String createdLabel(String date) {
    return 'Vytvořeno: $date';
  }

  @override
  String get currentParticipants => 'Aktuální účastníci';

  @override
  String get customCapabilitiesDescription => 'Vlastní popis schopností';

  @override
  String get customSystemPrompt =>
      'Vlastní systémový prompt pro tohoto agenta…';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'před $count dny',
      many: 'před $count dny',
      few: 'před $count dny',
      one: 'před 1 dnem',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'Deaktivovat';

  @override
  String get defaultCapabilities => 'Výchozí schopnosti · nové prostory';

  @override
  String get defaultChat => 'Výchozí chat';

  @override
  String get defaultRunners => 'Výchozí runnery';

  @override
  String get delete => 'Smazat';

  @override
  String get deleteAgent => 'Smazat agenta';

  @override
  String deleteAgentConfirm(String name) {
    return 'Smazat „$name“? Tuto akci nelze vrátit zpět.';
  }

  @override
  String get deleteSpace => 'Smazat prostor';

  @override
  String deleteConfirmName(String name) {
    return 'Smazat „$name“?';
  }

  @override
  String get archiveConversation => 'Archivovat konverzaci';

  @override
  String get deleteFact => 'Smazat fakt';

  @override
  String get deleteFeedBody =>
      'Tím se odebere kanál a všechny jeho uložené články. Záložky z tohoto kanálu se také odeberou.';

  @override
  String deleteFeedConfirm(String name) {
    return 'Smazat „$name“?';
  }

  @override
  String get deletePolicy => 'Smazat politiku';

  @override
  String get deletePolicyConfirm =>
      'Smazat tuto politiku? Tuto akci nelze vrátit zpět.';

  @override
  String deleteTopicConfirm(String topic) {
    return 'Smazat „$topic“? Tuto akci nelze vrátit zpět.';
  }

  @override
  String get deleteWorkspace => 'Smazat pracovní prostor';

  @override
  String get deny => 'Zakázat';

  @override
  String get detailsLabel => 'Podrobnosti';

  @override
  String get descriptionLabel => 'Popis';

  @override
  String detectedBackend(String label) {
    return 'Zjištěno: $label';
  }

  @override
  String get detectedRunners => 'Zjištění runneři';

  @override
  String get detectingAdapters => 'Zjišťování adaptérů…';

  @override
  String get detectingInputDevices => 'Zjišťování vstupních zařízení…';

  @override
  String detectionFailed(String error) {
    return 'Zjištění selhalo: $error';
  }

  @override
  String get disabled => 'Vypnuto';

  @override
  String get discover => 'Objevit';

  @override
  String get dismissed => 'Zamítnuto';

  @override
  String get domainHint => 'např. api-performance';

  @override
  String get domainLabel => 'Doména';

  @override
  String get download => 'Stáhnout';

  @override
  String get downloadingLabel => 'Stahování';

  @override
  String downloadingModel(int pct) {
    return 'Stahování modelu… $pct %';
  }

  @override
  String get draft => 'Koncept';

  @override
  String get draftLabel => 'Koncept';

  @override
  String get edit => 'Upravit';

  @override
  String get edited => 'upraveno';

  @override
  String get editMessage => 'Upravit zprávu';

  @override
  String get deleteMessage => 'Smazat zprávu';

  @override
  String get deleteMessageConfirm =>
      'Smazat tuto zprávu? Tuto akci nelze vrátit zpět.';

  @override
  String get messageDeleted => 'Zpráva smazána';

  @override
  String get searchInConversation => 'Hledat v konverzaci';

  @override
  String get searchMessagesHint => 'Hledat zprávy…';

  @override
  String get noMessagesFound => 'Žádné zprávy nenalezeny';

  @override
  String get editFact => 'Upravit fakt';

  @override
  String get editPolicy => 'Upravit politiku';

  @override
  String get editSuggestedCodeHint => 'Upravit navržený kód…';

  @override
  String get editSuggestion => 'Upravit návrh';

  @override
  String get egArchitect => 'např. architect';

  @override
  String get egControlCenter => 'např. control-center';

  @override
  String get egPlatform => 'např. Platform';

  @override
  String get egSamuelAlev => 'např. SamuelAlev';

  @override
  String get egSoftwareArchitect => 'např. Software Architect';

  @override
  String get egTheVerge => 'např. The Verge';

  @override
  String get egTokenLimit => 'např. 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'Instalace selhala: $error';
  }

  @override
  String get embeddingInstalled =>
      'Místní embedding model nainstalován. Hybridní vyhledávání je zapnuté.';

  @override
  String get embeddingModel => 'Embedding model (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'Není nainstalováno. Vyhledávání používá jen klíčová slova, dokud to nezapnete.';

  @override
  String get embeddingRedownloadBody =>
      'Stávající soubory modelu se smažou a stáhnou znovu. Sémantické vyhledávání nebude dostupné, dokud stahování neskončí.';

  @override
  String get embeddingRemoveBody =>
      'Sémantické vyhledávání bude vypnuté, dokud ho znovu nenainstalujete. Nainstalovat ho můžete kdykoli.';

  @override
  String get speakerDiarization => 'Diarizace řečníků';

  @override
  String get diarizationModel => 'Model diarizace';

  @override
  String get diarizationInstalled =>
      'Nainstalováno — v přepisech schůzek pojmenuje jednotlivé řečníky';

  @override
  String get diarizationNotInstalled =>
      'Není nainstalováno — řečníci na schůzkách se neoddělí';

  @override
  String diarizationInstallFailed(String error) {
    return 'Instalace selhala: $error';
  }

  @override
  String get redownloadDiarizationModel => 'Znovu stáhnout model diarizace';

  @override
  String get diarizationRedownloadBody =>
      'Tím se odeberou aktuální modely diarizace a stáhnou se znovu.';

  @override
  String get removeDiarizationModel => 'Odebrat model diarizace';

  @override
  String get diarizationRemoveBody =>
      'Tím se smažou místní modely diarizace. Už vytvořené přepisy schůzek zůstanou beze změny.';

  @override
  String get enableNotifications => 'Zapnout oznámení';

  @override
  String get enableSandboxing => 'Zapnout sandboxing';

  @override
  String get enabled => 'Zapnuto';

  @override
  String errorCreatingAgent(String error) {
    return 'Chyba při vytváření agenta: $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'Chyba při mazání agenta: $error';
  }

  @override
  String errorWithDetail(String error) {
    return 'Chyba: $error';
  }

  @override
  String get expand => 'Rozbalit';

  @override
  String extractingModel(int pct) {
    return 'Rozbalování modelu… $pct %';
  }

  @override
  String get fact => 'Fakt';

  @override
  String factCount(int count) {
    return '$count fakt';
  }

  @override
  String factCountPlural(int count) {
    return '$count faktů';
  }

  @override
  String get facts => 'Fakta';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount faktů · $policyCount politik';
  }

  @override
  String get failed => 'Selhalo';

  @override
  String failedToDispatch(String error) {
    return 'Odeslání selhalo: $error';
  }

  @override
  String get failedToLoad => 'Načtení selhalo';

  @override
  String failedToLoadAgents(String error) {
    return 'Agenty se nepodařilo načíst: $error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'Kanály se nepodařilo načíst: $error';
  }

  @override
  String get failedToLoadGifs => 'GIF se nepodařilo načíst';

  @override
  String failedToLoadLogs(String error) {
    return 'Protokoly se nepodařilo načíst: $error';
  }

  @override
  String get failedToLoadRepos => 'Repozitáře se nepodařilo načíst';

  @override
  String get failedToLoadWorkspaces => 'Pracovní prostory se nepodařilo načíst';

  @override
  String failedToStartAiReview(String error) {
    return 'AI kontrolu se nepodařilo spustit: $error';
  }

  @override
  String get failedToStartMicTest => 'Test mikrofonu se nepodařilo spustit.';

  @override
  String failedToSubmitReview(String error) {
    return 'Kontrolu se nepodařilo odeslat: $error';
  }

  @override
  String failedToUpload(String name, String error) {
    return 'Nahrání $name selhalo: $error';
  }

  @override
  String failedWithError(String error) {
    return 'Selhalo: $error';
  }

  @override
  String get failure => 'Selhání';

  @override
  String get feedAlreadyExists => 'Kanál s touto URL už existuje.';

  @override
  String get feedUrlExample => 'např. https://example.com/feed.xml';

  @override
  String get feedUrlLabel => 'URL kanálu';

  @override
  String feedsCount(int count) {
    return 'Kanály ($count)';
  }

  @override
  String get filesChanged => 'Změněné soubory';

  @override
  String filesCount(int count) {
    return '$count soubor(ů)';
  }

  @override
  String get filesMentionSection => 'Soubory';

  @override
  String get filterAgents => 'Filtrovat agenty…';

  @override
  String get filterFilesHint => 'Filtrovat soubory…';

  @override
  String get filterLists => 'Seznamy filtrů';

  @override
  String get filterSkillsPlaceholder => 'Filtrovat dovednosti…';

  @override
  String get finish => 'Dokončit';

  @override
  String get fix => 'Opravit';

  @override
  String get forward => 'Vpřed';

  @override
  String get gatesGithubPatPush =>
      'Řídí vložení GitHub PAT. Potřebné, aby agent mohl pushovat.';

  @override
  String get general => 'Obecné';

  @override
  String get githubLink => 'Odkaz GitHub';

  @override
  String get claudeStatusFetchFailed =>
      'status.claude.com se nepodařilo dosáhnout';

  @override
  String get claudeStatusOpenInBrowser => 'Otevřít status.claude.com';

  @override
  String get githubStatusFetchFailed =>
      'githubstatus.com se nepodařilo dosáhnout';

  @override
  String get githubDegradedTitle => 'GitHub hlásí problémy';

  @override
  String githubDegradedStatusLine(String status) {
    return 'Stav GitHub: $status.';
  }

  @override
  String githubDegradedBody(String status) {
    return 'Stav GitHub: $status. Data pull requestů mohou být zastaralá nebo neúplná, dokud se služba neobnoví.';
  }

  @override
  String get githubStatusOpenInBrowser => 'Otevřít githubstatus.com';

  @override
  String get githubStatusRefresh => 'Obnovit';

  @override
  String githubStatusUpdated(String time) {
    return 'Aktualizováno $time';
  }

  @override
  String get kimiStatusFetchFailed =>
      'status.moonshot.cn se nepodařilo dosáhnout';

  @override
  String get kimiStatusOpenInBrowser => 'Otevřít status.moonshot.cn';

  @override
  String get openaiStatusFetchFailed =>
      'status.openai.com se nepodařilo dosáhnout';

  @override
  String get openaiStatusOpenInBrowser => 'Otevřít status.openai.com';

  @override
  String get serviceStatusMaintenance => 'Údržba';

  @override
  String get serviceStatusMajorIssues => 'Závažné problémy';

  @override
  String get serviceStatusMinorIssues => 'Drobné problémy';

  @override
  String get serviceStatusOperational => 'V provozu';

  @override
  String get serviceStatusOutage => 'Výpadek';

  @override
  String get serviceStatusTitle => 'Stav služeb';

  @override
  String get serviceStatusUnknown => 'Neznámý';

  @override
  String lastChecked(String time) {
    return 'Zkontrolováno $time';
  }

  @override
  String get lastCheckedRecently => 'Zkontrolováno nedávno';

  @override
  String get giveYourWorkAHome => 'Dejte své práci domov.';

  @override
  String get goBack => 'Zpět';

  @override
  String get goForward => 'Vpřed';

  @override
  String get googleFonts => 'Google fonts';

  @override
  String get high => 'Vysoká';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'před $count hodinami',
      many: 'před $count hodinami',
      few: 'před $count hodinami',
      one: 'před 1 hodinou',
    );
    return '$_temp0';
  }

  @override
  String get images => 'Obrázky';

  @override
  String get inactive => 'Neaktivní';

  @override
  String get install => 'Nainstalovat';

  @override
  String get installRequired => 'Vyžadována instalace';

  @override
  String installedVersion(String version) {
    return 'Nainstalováno $version';
  }

  @override
  String get invite => 'Pozvat';

  @override
  String get inviteAgent => 'Pozvat agenta';

  @override
  String get isolateAgentExecution => 'Izolovat spouštění agentů.';

  @override
  String get justNow => 'Právě teď';

  @override
  String get keepSandboxing => 'Ponechat sandboxing';

  @override
  String get keybindingAddARepositoryDescription => 'Přidat repozitář';

  @override
  String get keybindingAddRepository => 'Přidat repozitář';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'Přidat nebo odebrat záložku vybraného článku';

  @override
  String get keybindingCommandPalette => 'Paleta příkazů';

  @override
  String get keybindingCreateANewAgentDescription => 'Vytvořit nového agenta';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'Vytvořit nový pracovní prostor';

  @override
  String get keybindingFocusSearch => 'Zaměřit hledání';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'Zaměřit pole hledání pull requestů';

  @override
  String get keybindingNewAgent => 'Nový agent';

  @override
  String get keybindingNewWorkspace => 'Nový pracovní prostor';

  @override
  String get keybindingNextArticle => 'Další článek';

  @override
  String get keybindingNextSpace => 'Další prostor';

  @override
  String get keybindingNextWorkspace => 'Další pracovní prostor';

  @override
  String get keybindingOpenArticle => 'Otevřít článek';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'Otevřít nebo zavřít přepínač pracovních prostorů v postranním panelu';

  @override
  String get keybindingOpenPr => 'Otevřít PR';

  @override
  String get keybindingOpenSettings => 'Otevřít nastavení';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'Otevřít nastavení aplikace';

  @override
  String get keybindingOpenTheCommandPaletteDescription =>
      'Otevřít paletu příkazů';

  @override
  String get keybindingOpenTheSelectedArticleDescription =>
      'Otevřít vybraný článek';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'Otevřít vybraný pull request';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'Otevřít vybraný pracovní prostor';

  @override
  String get keybindingOpenWorkspace => 'Otevřít pracovní prostor';

  @override
  String get keybindingPreviousArticle => 'Předchozí článek';

  @override
  String get keybindingPreviousSpace => 'Předchozí prostor';

  @override
  String get keybindingPreviousWorkspace => 'Předchozí pracovní prostor';

  @override
  String get keybindingRefresh => 'Obnovit';

  @override
  String get keybindingRefreshAllFeedsDescription => 'Obnovit všechny kanály';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'Obnovit seznam pull requestů';

  @override
  String get keybindingRescanForAdaptersDescription =>
      'Znovu vyhledat adaptéry';

  @override
  String get keybindingSelectTheNextArticleDescription => 'Vybrat další článek';

  @override
  String get keybindingSelectTheNextSpaceDescription => 'Vybrat další prostor';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'Vybrat předchozí článek';

  @override
  String get keybindingSelectThePreviousSpaceDescription =>
      'Vybrat předchozí prostor';

  @override
  String get keybindingSendMessage => 'Odeslat zprávu';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'Odeslat aktuální zprávu';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Přepnout mezi světlým a tmavým režimem';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Přepnout na osmý pracovní prostor';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Přepnout na pátý pracovní prostor';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'Přepnout na první pracovní prostor';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'Přepnout na čtvrtý pracovní prostor';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'Přepnout na další pracovní prostor';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'Přepnout na devátý pracovní prostor';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'Přepnout na předchozí pracovní prostor';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'Přepnout na druhý pracovní prostor';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'Přepnout na sedmý pracovní prostor';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'Přepnout na šestý pracovní prostor';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'Přepnout na třetí pracovní prostor';

  @override
  String get keybindingToggleBookmark => 'Přepnout záložku';

  @override
  String get keybindingToggleTheme => 'Přepnout motiv';

  @override
  String get keybindingToggleWorkspaceSwitcher =>
      'Přepnout přepínač pracovních prostorů';

  @override
  String get keybindingWorkspace1 => 'Pracovní prostor 1';

  @override
  String get keybindingWorkspace2 => 'Pracovní prostor 2';

  @override
  String get keybindingWorkspace3 => 'Pracovní prostor 3';

  @override
  String get keybindingWorkspace4 => 'Pracovní prostor 4';

  @override
  String get keybindingWorkspace5 => 'Pracovní prostor 5';

  @override
  String get keybindingWorkspace6 => 'Pracovní prostor 6';

  @override
  String get keybindingWorkspace7 => 'Pracovní prostor 7';

  @override
  String get keybindingWorkspace8 => 'Pracovní prostor 8';

  @override
  String get keybindingWorkspace9 => 'Pracovní prostor 9';

  @override
  String get keybindings => 'Klávesové zkratky';

  @override
  String get keybindingsDescription =>
      'Všechny klávesové zkratky. Zkratky jsou pevné a nelze je měnit.';

  @override
  String get killRunning => 'Ukončit běžící';

  @override
  String get languageSystem => 'Systém';

  @override
  String get leaveACommentEllipsis => 'Napsat komentář…';

  @override
  String get legendLabel => 'Legenda';

  @override
  String get lessLabel => 'Méně';

  @override
  String get letsPluginTools => 'Zapojme vaše nástroje.';

  @override
  String get level => 'Úroveň';

  @override
  String get loadingAgents => 'Načítání agentů…';

  @override
  String get loadingModels => 'Načítání modelů…';

  @override
  String get loadingProviders => 'Načítání poskytovatelů…';

  @override
  String get logLevel => 'Úroveň protokolu';

  @override
  String get logs => 'Protokoly';

  @override
  String get low => 'Nízká';

  @override
  String get maintenance => 'Údržba';

  @override
  String get manageParticipants => 'Spravovat účastníky';

  @override
  String get manageWorkspaces => 'Spravovat pracovní prostory';

  @override
  String get reorderWorkspace => 'Změnit pořadí pracovního prostoru';

  @override
  String get matchOsAppearance =>
      'Sjednotit se vzhledem OS, nebo zvolit pevný režim.';

  @override
  String get mcpAuthToken => 'Autentizační token MCP';

  @override
  String get mcpNotAvailableOnServer =>
      'Ovládání serveru MCP není na připojeném serveru k dispozici.';

  @override
  String get modelManagedOnServer =>
      'Tento model běží na hostiteli serveru a spravuje se tam.';

  @override
  String get mcpServer => 'Server MCP';

  @override
  String get medium => 'Střední';

  @override
  String get memoryDataHint =>
      'Fakta a politiky se tu objeví, jak agenti pracují.';

  @override
  String get memoryLabel => 'Paměť';

  @override
  String get merge => 'Sloučit';

  @override
  String get merged => 'Sloučeno';

  @override
  String get messagePlaceholder => 'Zpráva… (@ pro zmínku, / pro příkazy)';

  @override
  String get navConversations => 'Prostory';

  @override
  String get microphonePermissionDenied => 'Přístup k mikrofonu byl odepřen.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'před $count minutami',
      many: 'před $count minutami',
      few: 'před $count minutami',
      one: 'před 1 minutou',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'Model';

  @override
  String get modified => 'Upraveno';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'před $count měsíci',
      many: 'před $count měsíci',
      few: 'před $count měsíci',
      one: 'před 1 měsícem',
    );
    return '$_temp0';
  }

  @override
  String get moreLabel => 'Více';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'Název';

  @override
  String get nameAndTitleRequired => 'Název a titul jsou povinné.';

  @override
  String get nameAndUrlRequired => 'Název a URL jsou povinné';

  @override
  String get nameLabel => 'Název';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'Nativní sandbox je na $platform k dispozici.';
  }

  @override
  String get nativeSandboxNeedsInstall =>
      'Vyžadována instalace nativního sandboxu';

  @override
  String get navObservability => 'Observabilita';

  @override
  String get navSettings => 'Nastavení';

  @override
  String networkBlockCount(int count) {
    return '$count síťových bloků';
  }

  @override
  String get neutral => 'Neutrální';

  @override
  String get newCommitsPushed =>
      'Byly odeslány nové commity — klikněte pro znovunačtení diffu';

  @override
  String get newFact => 'Nový fakt';

  @override
  String get newPolicy => 'Nová politika';

  @override
  String get newsfeed => 'Kanál novinek';

  @override
  String get newsfeedLabel => 'Kanál novinek';

  @override
  String get newsfeedSettingsDescription =>
      'Spravujte odebírané kanály a předvolby čtečky.';

  @override
  String get newsfeedSettingsTitle => 'Nastavení kanálu novinek';

  @override
  String get nextMatch => 'Další shoda (↵)';

  @override
  String get noActiveWorkspace =>
      'Není vybrán aktivní pracovní prostor ani repo.';

  @override
  String get noActiveWorkspaceCreate => 'Žádný aktivní pracovní prostor';

  @override
  String get noActiveWorkspaceGithub =>
      'Žádný aktivní pracovní prostor s GitHub repem.';

  @override
  String get noAgents => 'Žádní agenti';

  @override
  String get noArticlesYet => 'Zatím žádné články';

  @override
  String get noArticlesYetBody => 'Články z vašich kanálů se tu objeví.';

  @override
  String get noExecutionLogsYet => 'Zatím žádné protokoly spuštění';

  @override
  String get noFacts => 'Zatím žádná fakta';

  @override
  String get noFeedsYet => 'Zatím žádné kanály';

  @override
  String get noFileAnchor =>
      'Žádná kotva souboru — inline komentář nelze odeslat.';

  @override
  String get noFileChangesInScope =>
      'V tomto rozsahu nejsou žádné změny souborů';

  @override
  String get noGifsFound => 'Žádné GIF nenalezeny';

  @override
  String get noInputDevicesDetected =>
      'Nebyla zjištěna žádná vstupní zařízení — použije se systémové výchozí.';

  @override
  String get noMatchingFiles => 'Žádné odpovídající soubory';

  @override
  String get noMatchingGoogleFonts => 'Žádné odpovídající Google Fonts.';

  @override
  String get noMemoryData => 'Zatím žádná data paměti';

  @override
  String get noMessagesYet => 'Zatím žádné zprávy';

  @override
  String get noModelsAdvertised => 'Tento adaptér nenabízí žádné modely.';

  @override
  String get noOpenPullRequests => 'Žádné otevřené pull requesty';

  @override
  String get noPolicies => 'Zatím žádné politiky';

  @override
  String get noReposInWorkspaceYet =>
      'V tomto pracovním prostoru zatím nejsou žádné repozitáře';

  @override
  String get noRunnersDetected =>
      'Zatím nebyli zjištěni žádní runneři. Obnovte a naskenujte znovu.';

  @override
  String get noSavedArticles => 'Žádné uložené články';

  @override
  String get noSavedArticlesBody => 'Články, které uložíte, se tu objeví.';

  @override
  String noShortcutsMatch(String query) {
    return 'Žádné zkratky neodpovídají „$query“';
  }

  @override
  String get noSystemFonts => 'Nebyla zjištěna žádná systémová písma.';

  @override
  String get noTokenSet => 'Žádný token nastaven — přístup je neomezený.';

  @override
  String get noWorkingMemory => 'Zatím žádné poznámky pracovní paměti.';

  @override
  String get noneAllRoles => 'Žádná (všechny role)';

  @override
  String get notAvailable => 'Není k dispozici';

  @override
  String get notConfiguredLabel => 'Nenastaveno.';

  @override
  String get notFoundLabel => 'Nenalezeno';

  @override
  String get notes => 'Poznámky';

  @override
  String get notificationAgentFinished => 'Agent dokončil';

  @override
  String get notificationPrMentioned => 'Zmíněn v pull requestu';

  @override
  String get notificationNewMessages => 'Nové zprávy';

  @override
  String get notificationPrMerged => 'PR sloučen';

  @override
  String get notificationPrPublished => 'PR zveřejněn';

  @override
  String get notificationReviewRequested => 'Vyžádána kontrola';

  @override
  String get notifications => 'Oznámení';

  @override
  String get notifyAgentRunCompleted => 'Upozornit, když agent dokončí běh.';

  @override
  String get notifyPrMentioned =>
      'Upozornit, když vás někdo zmíní v pull requestu.';

  @override
  String get notifyNewMessages =>
      'Upozornit na nové zprávy agenta v jiných prostorech.';

  @override
  String get notifyPrMerged => 'Upozornit, když je pull request sloučen.';

  @override
  String get notifyPrPublished =>
      'Upozornit, když agent zveřejní pull request.';

  @override
  String get notifyReviewRequested =>
      'Upozornit, když je na pull requestu vyžádána vaše kontrola.';

  @override
  String get notificationReviewStale => 'Kontrola je zastaralá';

  @override
  String get notifyReviewStale =>
      'Když na pull request, který už jste zkontrolovali, přijdou nové commity';

  @override
  String get notificationPrMergeReadiness => 'Připraveno ke sloučení';

  @override
  String get notifyPrMergeReadiness =>
      'Upozornit, když se váš pull request stane sloučitelným, nebo přestane být.';

  @override
  String get notificationPrReviewDecision => 'Rozhodnutí o kontrole';

  @override
  String get notifyPrReviewDecision =>
      'Upozornit, když recenzent schválí, vyžádá změny nebo je schválení zrušeno.';

  @override
  String get notificationPrChecksStatus => 'Kontroly';

  @override
  String get notifyPrChecksStatus =>
      'Upozornit, když CI na vašem pull requestu selže, a když se obnoví.';

  @override
  String get notificationPrThreadActivity => 'Vlákna kontroly';

  @override
  String get notifyPrThreadActivity =>
      'Upozornit, když někdo odpoví nebo vyřeší vlákno, ve kterém jste.';

  @override
  String get notificationPrReadyToMerge => 'Připraveno ke sloučení';

  @override
  String notificationPrReadyToMergeBody(String prTitle) {
    return '$prTitle má vše, co potřebuje.';
  }

  @override
  String get notificationPrMergeBlocked => 'Už nelze sloučit';

  @override
  String notificationPrMergeBlockedBodyConflicts(String prTitle) {
    return '$prTitle je v konfliktu se základní větví.';
  }

  @override
  String notificationPrMergeBlockedBodyBehind(String prTitle) {
    return '$prTitle zaostává za základní větví.';
  }

  @override
  String notificationPrMergeBlockedBodyReviews(String prTitle) {
    return '$prTitle čeká na povinnou kontrolu.';
  }

  @override
  String notificationPrMergeBlockedBodyChanges(String prTitle) {
    return 'Recenzent vyžádal změny u $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyChecks(String prTitle) {
    return 'Kontroly u $prTitle selhávají.';
  }

  @override
  String notificationPrMergeBlockedBodyOther(String prTitle) {
    return '$prTitle už nelze sloučit.';
  }

  @override
  String get notificationPrApproved => 'Pull request schválen';

  @override
  String notificationPrApprovedBodyBy(String login, String prTitle) {
    return '$login schválil $prTitle';
  }

  @override
  String notificationPrApprovedBody(String prTitle) {
    return '$prTitle byl schválen';
  }

  @override
  String notificationPrReviewersRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recenzentů ještě musí odpovědět',
      many: '$count recenzentů ještě musí odpovědět',
      few: '$count recenzenti ještě musí odpovědět',
      one: '1 recenzent ještě musí odpovědět',
      zero: 'žádní recenzenti nezbývají',
    );
    return '$_temp0';
  }

  @override
  String get notificationPrChangesRequested => 'Vyžádány změny';

  @override
  String notificationPrChangesRequestedBodyBy(String login, String prTitle) {
    return '$login vyžádal změny u $prTitle';
  }

  @override
  String notificationPrChangesRequestedBody(String prTitle) {
    return 'U $prTitle byly vyžádány změny';
  }

  @override
  String get notificationPrReviewDismissed => 'Schválení zrušeno';

  @override
  String notificationPrReviewDismissedBody(String prTitle) {
    return '$prTitle potřebuje kontrolu znovu.';
  }

  @override
  String get notificationPrChecksFailed => 'Kontroly selhaly';

  @override
  String notificationPrChecksFailedBody(String checkName, String prTitle) {
    return '$checkName selhalo u $prTitle';
  }

  @override
  String notificationPrChecksFailedBodyUnnamed(String prTitle) {
    return 'Kontroly u $prTitle selhávají';
  }

  @override
  String get notificationPrChecksRecovered => 'Kontroly procházejí';

  @override
  String notificationPrChecksRecoveredBody(String prTitle) {
    return '$prTitle je znovu zelený.';
  }

  @override
  String notificationPrMentionedInCommentBody(String login, String location) {
    return '$login vás zmínil v $location';
  }

  @override
  String get notificationPrThreadReplied => 'Nová odpověď';

  @override
  String notificationPrThreadRepliedBody(String login, String location) {
    return '$login odpověděl v $location';
  }

  @override
  String get notificationPrThreadResolved => 'Vlákno vyřešeno';

  @override
  String notificationPrThreadResolvedBody(String location) {
    return 'Vaše vlákno v $location bylo vyřešeno.';
  }

  @override
  String get notificationGroupAgents => 'Agenti';

  @override
  String get notificationGroupPullRequests => 'Pull requesty';

  @override
  String get notificationGroupMessages => 'Zprávy';

  @override
  String get notificationGroupTickets => 'Tickety';

  @override
  String get notificationGroupCalendar => 'Kalendář';

  @override
  String get notificationGroupMachines => 'Stroje';

  @override
  String get notificationsMutedRepos => 'Ztlumené repozitáře';

  @override
  String notificationsMutedReposCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ztlumených repozitářů',
      many: '$count ztlumených repozitářů',
      few: '$count ztlumené repozitáře',
      one: '1 ztlumený repozitář',
      zero: 'Žádné ztlumené repozitáře',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMuteRepo => 'Ztlumit tento repozitář';

  @override
  String get onboardingLinuxDescription =>
      'Control Center může k izolaci spouštění agentů použít Linux kontejnery.';

  @override
  String get onboardingMacosDescription =>
      'Control Center na macOS používá nativní sandbox k izolaci spouštění agentů.';

  @override
  String get onboardingUnsupportedDescription =>
      'Sandbox na této platformě není k dispozici. Agenti poběží bez izolace.';

  @override
  String get openArticlesInApp => 'Otevírat články v aplikaci';

  @override
  String get openInBrowser => 'Otevřít v prohlížeči';

  @override
  String get openedInYourBrowser => 'Otevřeno v prohlížeči.';

  @override
  String get openLabel => 'Otevřít';

  @override
  String get openOnGithub => 'Otevřít na GitHub';

  @override
  String get openStatus => 'Otevřený';

  @override
  String get optionalPersonaDescription => 'Volitelný popis persony';

  @override
  String get otherLabel => 'Ostatní';

  @override
  String get ownerOrganization => 'Vlastník / organizace';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get passed => 'Prošlo';

  @override
  String get pasteValueHere => 'Sem vložte hodnotu';

  @override
  String get persona => 'Persona';

  @override
  String get policies => 'Politiky';

  @override
  String get policiesHint => 'Politiky se tu objeví, až agenti povýší fakta.';

  @override
  String get policy => 'Politika';

  @override
  String get popular => 'Oblíbené';

  @override
  String get port => 'Port';

  @override
  String get postingEllipsis => 'Odesílání…';

  @override
  String get prCommits => 'Commity';

  @override
  String get prMergedBody => 'Pull request byl sloučen';

  @override
  String get prMoreActions => 'Další akce';

  @override
  String get prTitle => 'Název PR';

  @override
  String get reviewCommentHint =>
      'Stačí kliknout na schválit, nebo přidat komentář či reakci…';

  @override
  String get nothingToPreview => 'Není co náhlednout';

  @override
  String get previousMatch => 'Předchozí shoda (⇧↵)';

  @override
  String get priorityReviewsDescription =>
      'Prioritní kontroly a přehled repozitáře.';

  @override
  String get prsCreated => 'Vytvořené PR';

  @override
  String get prsMerged => 'Sloučené PR';

  @override
  String get publishToGithub => 'Zveřejnit na GitHub';

  @override
  String get published => 'Zveřejněno';

  @override
  String get pullRequestApproved => 'Pull request schválen';

  @override
  String get pullRequests => 'Pull requesty';

  @override
  String get questionLabel => 'OTÁZKA';

  @override
  String get queued => 'Ve frontě';

  @override
  String get react => 'Reagovat';

  @override
  String get readPrsIssuesMetadata =>
      'Umožní agentovi číst PR, issues a metadata repozitáře.';

  @override
  String get readerPreferences => 'Předvolby čtečky';

  @override
  String get reasoningEffort => 'Úsilí uvažování';

  @override
  String get recommendLabel => 'DOPORUČIT';

  @override
  String recordingFromDevice(String device) {
    return 'Nahrávání z $device.';
  }

  @override
  String get redownload => 'Stáhnout znovu';

  @override
  String get redownloadEmbeddingModel => 'Znovu stáhnout embedding model?';

  @override
  String get redownloadVoiceModel => 'Znovu stáhnout hlasový model?';

  @override
  String get refinePlan => 'Upřesnit plán';

  @override
  String get refresh => 'Obnovit';

  @override
  String get refreshAll => 'Obnovit vše';

  @override
  String get refreshAllFeeds => 'Obnovit všechny kanály';

  @override
  String get reject => 'Odmítnout';

  @override
  String get rejected => 'Odmítnuto';

  @override
  String get reload => 'Znovu načíst';

  @override
  String get remove => 'Odebrat';

  @override
  String get removeBookmark => 'Odebrat záložku';

  @override
  String get removeEmbeddingModel => 'Odebrat embedding model?';

  @override
  String get removeLogo => 'Odebrat logo';

  @override
  String get removeRepoFromWorkspace =>
      'Odebrat repozitář z pracovního prostoru?';

  @override
  String get removeVoiceModel => 'Odebrat hlasový model?';

  @override
  String get removed => 'Odebráno';

  @override
  String get renamed => 'Přejmenováno';

  @override
  String get reopen => 'Znovu otevřít';

  @override
  String get resolve => 'Vyřešit';

  @override
  String get replyEllipsis => 'Odpovědět…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$name bude odebrán z tohoto pracovního prostoru. Místní soubory na disku zůstanou nedotčené.';
  }

  @override
  String repoAccessNoticeBody(String repos) {
    return 'Přihlašovací údaje GitHub serveru nevidí $repos. Pokud repozitář patří organizaci, nainstalujte tam GitHub App, nebo připojte token s přístupem.';
  }

  @override
  String repoAccessNoticeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repozitářů není přístupných',
      many: '$count repozitářů není přístupných',
      few: '$count repozitáře nejsou přístupné',
      one: 'Repozitář není přístupný',
    );
    return '$_temp0';
  }

  @override
  String get repoAccessNoticeSuspendedTitle =>
      'Instalace GitHub App je pozastavena';

  @override
  String repoAccessNoticeSuspendedBody(String repos) {
    return 'Zobrazují se naposledy známá data pro $repos. Obnovte instalaci na GitHubu, nebo připojte token s přístupem.';
  }

  @override
  String get repoNoAccessBadge => 'Bez přístupu';

  @override
  String get reportsTo => 'Nadřízený';

  @override
  String reposCount(int count) {
    return 'Repozitáře ($count)';
  }

  @override
  String get reposDescription =>
      'Místní checkouty, které tento pracovní prostor cílí.';

  @override
  String get repositories => 'Repozitáře';

  @override
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repozitářů',
      many: '$count repozitářů',
      few: '$count repozitáře',
      one: '1 repozitář',
    );
    return 'Nepodařilo se přidat $_temp0: $error';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repozitářů přidáno',
      many: '$count repozitářů přidáno',
      few: '$count repozitáře přidány',
      one: 'Repozitář přidán',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => 'Nastavení repozitářů';

  @override
  String get repositoryName => 'Název repozitáře';

  @override
  String get requestChanges => 'Vyžádat změny';

  @override
  String get requested => 'Vyžádáno';

  @override
  String get requestedChanges => 'Vyžádané změny';

  @override
  String requiredRoleLabel(String role) {
    return 'Požadovaná role: $role';
  }

  @override
  String get requiredRoleOptional => 'Požadovaná role (volitelné)';

  @override
  String get requirements => 'Požadavky';

  @override
  String get reset => 'Resetovat';

  @override
  String get resolved => 'Vyřešeno';

  @override
  String get enclosedTerminalTitle => 'Izolovaný terminál';

  @override
  String get enclosedTerminalStart => 'Otevřít shell';

  @override
  String get enclosedTerminalStartHint =>
      'Tento shell běží uvnitř jednorázového VM této konverzace. Nabootuje, až ho otevřete, ne při startu aplikace.';

  @override
  String get terminalStreamReconnecting =>
      'stream přerušen — znovu připojování…';

  @override
  String get terminalStreamError => 'chyba streamu:';

  @override
  String get terminalShellExited => 'shell skončil';

  @override
  String get restartShell => 'Restartovat shell';

  @override
  String get retry => 'Zopakovat';

  @override
  String get review => 'Kontrola';

  @override
  String get reviewedByMe => 'Zkontrolováno mnou';

  @override
  String get reviewers => 'Recenzenti';

  @override
  String get roleLabel => 'Role';

  @override
  String get ruleHint => 'Pravidlo politiky (Markdown je podporován)';

  @override
  String get ruleLabel => 'Pravidlo';

  @override
  String get runCompleted => 'Běh dokončen';

  @override
  String get running => 'Běží';

  @override
  String get runningLabel => 'běží';

  @override
  String get runs => 'Běhy';

  @override
  String get runsLabel => 'Běhy';

  @override
  String get sandboxBackendNativeLabel => 'Nativní sandbox';

  @override
  String get sandboxBackendMicrovmLabel => 'Izolované VM';

  @override
  String get sandboxBackendNoneLabel => 'Bez izolace';

  @override
  String get sandboxLinuxInstall =>
      'Nativní sandbox na Linux/WSL2 používá bubblewrap. Instalace:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'Nativní sandbox je na macOS vestavěný — používá Apple Seatbelt (`sandbox-exec`). Instalace není potřeba.';

  @override
  String get sandboxPermissions => 'Oprávnění sandboxu';

  @override
  String get sandboxUnsupported =>
      'Nativní sandbox na této platformě zatím není podporován. Přepne se na „Bez izolace“.';

  @override
  String get sandboxingDisabledDescription =>
      'Agenti běží přímo na hostiteli s plným prostředím — nedoporučeno.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'Všechna volání agentů jdou přes $backend.';
  }

  @override
  String get save => 'Uložit';

  @override
  String get saveChanges => 'Uložit změny';

  @override
  String get adapterArguments => 'Další argumenty';

  @override
  String get adapterArgumentsHint => 'Další příznaky CLI (např. --yolo)';

  @override
  String get addVariable => 'Přidat proměnnou';

  @override
  String get environmentVariables => 'Proměnné prostředí';

  @override
  String get environmentVariablesDescription =>
      'Vlastní proměnné prostředí předané tomuto adaptéru (např. API klíče). Uloženy v keychainu.';

  @override
  String get variableKey => 'Klíč';

  @override
  String get variableValue => 'Hodnota';

  @override
  String get savingEllipsis => 'Ukládání…';

  @override
  String get scopeDiffToCommits =>
      'Omezit diff na commity — Shift-klik pro rozsah';

  @override
  String get noPrsMatchSearch => 'Žádné odpovídající pull requesty';

  @override
  String get searchFactsHint => 'Hledat fakta…';

  @override
  String get searchFonts => 'Hledat písma…';

  @override
  String get searchGifs => 'Hledat GIF';

  @override
  String get searchGifsHint => 'Hledat GIF…';

  @override
  String get searchInDiffHint => 'Hledat v diffu…';

  @override
  String get searchOrTypeModel => 'Hledat nebo zadat název modelu…';

  @override
  String get searchPlaceholder => 'Hledat…';

  @override
  String get searchShortcuts => 'Hledat zkratky…';

  @override
  String get shortcutUnavailableInBrowser => 'V prohlížeči není k dispozici';

  @override
  String get searching => 'Hledání…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'před $count sekundami',
      many: 'před $count sekundami',
      few: 'před $count sekundami',
      one: 'před 1 sekundou',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'Vybrat adaptér';

  @override
  String get selectAdapterFirst => 'Nejprve vyberte adaptér';

  @override
  String get selectAgentToReportTo => 'Vyberte agenta, kterému hlásit…';

  @override
  String get selectAnAgent => 'Vyberte agenta';

  @override
  String get selectConversation => 'Vyberte konverzaci';

  @override
  String get selectLabel => 'Vybrat';

  @override
  String get selectRunner => 'Vyberte runner';

  @override
  String get semanticSearch => 'Sémantické vyhledávání';

  @override
  String get send => 'Odeslat';

  @override
  String get sendFirstMessage => 'Odeslat první zprávu';

  @override
  String get sendMessage => 'Odeslat zprávu';

  @override
  String sentFindingsToAgent(int count) {
    return 'Odesláno $count zjištění agentovi.';
  }

  @override
  String setGithubLinkDescription(String name) {
    return 'Nastavte vlastníka GitHub a název repozitáře pro $name. Používá se k rozlišení odkazů na PR a issue jako #123 v Markdownu.';
  }

  @override
  String get setLabel => 'Nastavit';

  @override
  String get setToken => 'Nastavit token';

  @override
  String get settingsLabel => 'Nastavení';

  @override
  String get settingsLanguage => 'Jazyk';

  @override
  String get settingsLanguageDescription => 'Vyberte jazyk aplikace.';

  @override
  String get shortTask => 'Krátký úkol';

  @override
  String get showNativeNotifications =>
      'Zobrazovat systémová oznámení u událostí.';

  @override
  String get showSuperseded => 'Zobrazit nahrazené';

  @override
  String get signedIn => 'Přihlášeno.';

  @override
  String signedInAs(String username) {
    return 'Přihlášeno jako $username.';
  }

  @override
  String get skillNameRequired => 'Název dovednosti je povinný.';

  @override
  String skillSaved(String name) {
    return 'Dovednost „$name“ uložena.';
  }

  @override
  String get skillsSourcesTab => 'Zdroje';

  @override
  String get skillSourcesDisclaimer =>
      'Dovednosti se instalují z GitHub repozitářů, které přidáte. Metadata repozitáře jsou nedůvěryhodná — skutečný bezpečnostní signál je antivirový sken.';

  @override
  String get skillSourcesEmpty => 'Žádné repozitáře dovedností';

  @override
  String get skillSourcesEmptyHint =>
      'Přidejte GitHub repozitář a procházejte jeho dovednosti.';

  @override
  String get skillSourceAdd => 'Přidat repozitář';

  @override
  String get skillSourceAddTitle => 'Přidat repozitář dovedností';

  @override
  String get skillSourceAddHint => 'https://github.com/owner/repo';

  @override
  String get skillSourceInvalidUrl =>
      'Zadejte URL GitHub repozitáře (https://github.com/owner/repo).';

  @override
  String skillSourceAdded(String repo) {
    return 'Repozitář $repo přidán.';
  }

  @override
  String skillSourceAlreadyAdded(String repo) {
    return 'Repozitář $repo už je přidán.';
  }

  @override
  String skillSourceRemoved(String repo) {
    return 'Repozitář $repo odebrán.';
  }

  @override
  String get skillSourceRemove => 'Odebrat';

  @override
  String skillSourceRemoveConfirmTitle(String repo) {
    return 'Odebrat $repo?';
  }

  @override
  String get skillSourceRemoveConfirmBody =>
      'Nainstalované dovednosti zůstanou. Odebere se jen katalog repozitáře.';

  @override
  String get skillSourceNoSkills =>
      'V tomto repozitáři nebyly nalezeny žádné dovednosti (dovednost je adresář se souborem SKILL.md).';

  @override
  String get skillSourceRefresh => 'Obnovit';

  @override
  String get skillSourceInstalledBadge => 'Nainstalováno';

  @override
  String get skillSourceUpdateBadge => 'Dostupná aktualizace';

  @override
  String get skillSourceSlugTaken => 'Název se používá';

  @override
  String skillSourceFilesCount(num count) {
    return '$count souborů';
  }

  @override
  String get skillSourceReadme => 'README';

  @override
  String get skillSourceNoReadme => 'Tato dovednost nemá README.';

  @override
  String get skillSourceNoMatches => 'Žádné dovednosti neodpovídají filtru.';

  @override
  String get skillUpdateAction => 'Aktualizovat';

  @override
  String get skillUninstallAction => 'Odinstalovat';

  @override
  String skillUninstallConfirmTitle(String slug) {
    return 'Odinstalovat „$slug“?';
  }

  @override
  String skillUninstalled(String slug) {
    return 'Dovednost „$slug“ odinstalována.';
  }

  @override
  String get skillFindingLine => 'řádek';

  @override
  String get skillInstallAnywayOverride =>
      'Rozumím riziku — přesto nainstalovat';

  @override
  String skillInstalled(String slug) {
    return 'Dovednost „$slug“ nainstalována.';
  }

  @override
  String get skillPreviewCapabilities => 'Schopnosti';

  @override
  String get skillPreviewFindings => 'Zjištění';

  @override
  String get skillPreviewGuardedActions => 'Střežené akce';

  @override
  String get skillPreviewLlmReviewed => 'Zkontrolováno LLM';

  @override
  String get skillPreviewNoCapabilities =>
      'Žádné schopnosti nejsou deklarovány.';

  @override
  String get skillPreviewNoFindings => 'Žádná zjištění.';

  @override
  String get skillPreviewScanning => 'Skenování dovednosti…';

  @override
  String get skillPreviewVerdictLabel => 'Verdikt skenu';

  @override
  String get skillPreviewVerdictPass => 'Prošlo';

  @override
  String get skillPreviewVerdictQuarantine => 'V karanténě';

  @override
  String get skillPreviewVerdictWarn => 'Varování';

  @override
  String get skillQuarantineWarning =>
      'Tuto dovednost skener dal do karantény. Instalace spustí kód na vašem stroji. Pokračujte, jen pokud zdroji důvěřujete a zjistění jste zkontrolovali.';

  @override
  String skillDetachedFromAgents(String agents) {
    return 'V karanténě a odpojeno od agentů: $agents';
  }

  @override
  String get skillNotScanned => 'Neskenováno';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => 'Ručně';

  @override
  String get skillOriginRegistry => 'Registr';

  @override
  String get skillOriginRuntimeLocal => 'Lokální runtime';

  @override
  String get skillRulesStale => 'Sken zastaralý';

  @override
  String get skillSaveAnywayOverride => 'Rozumím riziku — přesto uložit';

  @override
  String get skillSaveBlockedBody =>
      'Obsah byl zablokován dřív, než se cokoli zapsalo.';

  @override
  String get skillSaveBlockedTitle => 'Uložení zablokovala brána skenu';

  @override
  String get skillScanAction => 'Skenovat';

  @override
  String get skillScanAll => 'Skenovat vše';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass prošlo · $warn varování · $quarantine v karanténě';
  }

  @override
  String get skillStateDrifted => 'Změněno od instalace';

  @override
  String get skillStateUnmanaged => 'Nespravováno';

  @override
  String get skillSeverityBlocked => 'Blokováno';

  @override
  String get skillSeverityWarn => 'Varování';

  @override
  String get skillsInstalledTab => 'Nainstalované';

  @override
  String get skills => 'Dovednosti';

  @override
  String get skipAcceptRisk => 'Přeskočit — přijímám riziko';

  @override
  String get skipForNow => 'Zatím přeskočit';

  @override
  String get skipSandboxing => 'Přeskočit sandboxing';

  @override
  String get skipSandboxingDialogContent =>
      'Opravdu chcete přeskočit sandboxing? Agenti pak můžou spouštět kód na vašem systému bez izolace.';

  @override
  String get somethingWentWrong => 'Něco se pokazilo';

  @override
  String sourceCount(int count) {
    return '$count zdroj';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count zdrojů';
  }

  @override
  String get sourceFacts => 'Zdrojová fakta:';

  @override
  String get splitDiff => 'Rozdělený (vedle sebe) diff';

  @override
  String get startLabel => 'Start';

  @override
  String get startOnAppLaunch => 'Spustit při startu aplikace';

  @override
  String get statusLabel => 'Stav';

  @override
  String get onboardingStepConnect => 'Připojit';

  @override
  String get onboardingStepWorkspace => 'Pracovní prostor';

  @override
  String get onboardingStepSandbox => 'Sandbox';

  @override
  String get onboardingStepAdapter => 'Adaptér';

  @override
  String get onboardingStepVoice => 'Hlas';

  @override
  String get stop => 'Zastavit';

  @override
  String get stopped => 'Zastaveno';

  @override
  String get strictIdentityCheck => 'Přísná kontrola identity';

  @override
  String get success => 'Úspěch';

  @override
  String get successLabel => 'Úspěch';

  @override
  String get suggestAChange => 'Navrhnout změnu';

  @override
  String get suggestLabel => 'NAVRHNOUT';

  @override
  String get superseded => 'Nahrazeno';

  @override
  String get synced => 'Synchronizováno';

  @override
  String get systemDefault => 'Systémové výchozí';

  @override
  String get systemFonts => 'Systémová písma';

  @override
  String get systemPrompt => 'Systémový prompt';

  @override
  String get systemPromptLabel => 'Systémový prompt';

  @override
  String get talkToControlCenter => 'Mluvte s Control Center.';

  @override
  String get taskMentionSection => 'Úkol';

  @override
  String get testLabel => 'Test';

  @override
  String get theme => 'Motiv';

  @override
  String get themeDark => 'Tmavý';

  @override
  String get themeLight => 'Světlý';

  @override
  String get themeSystem => 'Systém';

  @override
  String get thisCannotBeUndone => 'Tuto akci nelze vrátit zpět.';

  @override
  String get ticketLabel => 'TICKET';

  @override
  String get titleLabel => 'Název';

  @override
  String get todayLabel => 'Dnes';

  @override
  String get toggleTheme => 'Přepnout motiv';

  @override
  String get tokenConfigured =>
      'Nastaveno — klienti musí tento token předložit.';

  @override
  String get topic => 'Téma';

  @override
  String get topicHint => 'např. Tech Stack, Design System';

  @override
  String get totalRuns => 'Celkem běhů';

  @override
  String trackingParamsCount(int count) {
    return '$count sledovacích parametrů';
  }

  @override
  String get typeCommandOrSearch => 'Zadejte příkaz nebo hledejte…';

  @override
  String get typography => 'Typografie';

  @override
  String get unavailable => 'Nedostupné';

  @override
  String get unifiedDiff => 'Jednotný diff';

  @override
  String get unknownAuthor => 'Neznámý';

  @override
  String get unnamedAgent => 'Nepojmenovaný agent';

  @override
  String get updateKey => 'Aktualizovat klíč';

  @override
  String get updateLabel => 'Aktualizovat';

  @override
  String get updateToken => 'Aktualizovat token';

  @override
  String updatedDaysAgo(int count) {
    return 'Aktualizováno před $count d';
  }

  @override
  String updatedHoursAgo(int count) {
    return 'Aktualizováno před $count h';
  }

  @override
  String get updatedJustNow => 'Aktualizováno právě teď';

  @override
  String updatedMinutesAgo(int count) {
    return 'Aktualizováno před $count min';
  }

  @override
  String get useSandbox => 'Použít sandbox';

  @override
  String get useWorkspaceDefault => 'Použít výchozí pracovního prostoru';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      'Nechte prázdné pro výchozí User-Agent aplikace. Některé weby blokují User-Agent, který není prohlížeč.';

  @override
  String get usingSystemDefaultMicrophone =>
      'Používá se systémový výchozí mikrofon.';

  @override
  String get viewLabel => 'Zobrazit';

  @override
  String get viewLogs => 'Zobrazit protokoly';

  @override
  String voiceInstallFailed(String error) {
    return 'Instalace selhala: $error';
  }

  @override
  String get voiceModelNotInstalled =>
      'Není nainstalováno. Jednorázově stáhne ~200 MB; běží plně na zařízení.';

  @override
  String get voiceModelNotInstalledLabel => 'Hlasový model není nainstalován.';

  @override
  String get voiceRedownloadBody =>
      'Stávající soubory modelu se smažou a znovu se stáhne archiv ~200 MB. Přepis hlasu nebude dostupný, dokud stahování neskončí.';

  @override
  String get voiceRemoveBody =>
      'Přepis hlasu bude vypnutý, dokud ho znovu nenainstalujete. Nainstalovat ho můžete kdykoli.';

  @override
  String get voiceTranscription => 'Přepis hlasu';

  @override
  String get weakIsolationDescription =>
      'Slabá izolace — jen hranice namespace, bez hranice jádra.';

  @override
  String get whenOffNoDefaultRoute =>
      'Když je vypnuto, sandbox nabootuje bez výchozí trasy.';

  @override
  String get whenOffServerStaysStopped =>
      'Když je vypnuto, server zůstane zastavený, dokud ho nespustíte.';

  @override
  String get speechModel => 'Řečový model';

  @override
  String get speechModelHint =>
      'Používá se pro přepis schůzek a mikrofon v poli zprávy.';

  @override
  String get voiceModelInstalled =>
      'Nainstalováno. Pohání přepis schůzek a tlačítko mikrofonu v poli zprávy.';

  @override
  String get meetingMicSilentWarning =>
      'Mikrofon může být ztlumený — ostatní mluví, ale k mikrofonu nic nedochází.';

  @override
  String get meetingSummaryPrivacyNotice =>
      'Nahrávání a přepis zůstávají na tomto stroji. Shrnutí píše agent, takže pokud používá cloudový model, přepis a poznámky jdou k tomuto poskytovateli.';

  @override
  String get meetingTemplates => 'Šablony poznámek ze schůzky';

  @override
  String get meetingTemplatesHint =>
      'Utvářte AI shrnutí pro druh schůzky. Aktivní šablona platí pro nová i znovu spuštěná shrnutí.';

  @override
  String get meetingTemplateActive => 'Aktivní šablona';

  @override
  String get meetingTemplateAdd => 'Přidat šablonu';

  @override
  String get meetingTemplateNewTitle => 'Nová šablona';

  @override
  String get meetingTemplateEditTitle => 'Upravit šablonu';

  @override
  String get meetingTemplateNameLabel => 'Název';

  @override
  String get meetingTemplateNameHint => 'např. Sprint review';

  @override
  String get meetingTemplateInstructionsLabel => 'Pokyny';

  @override
  String get meetingTemplateInstructionsHint =>
      'Jak má AI tyto poznámky strukturovat a na co klást důraz?';

  @override
  String get workingMemory => 'Pracovní paměť';

  @override
  String get workspaceName => 'Název pracovního prostoru';

  @override
  String get workspaceScopedSkills =>
      'Soubory dovedností vázané na pracovní prostor, připojené k agentům.';

  @override
  String get workspaces => 'Pracovní prostory';

  @override
  String get writePrivateNotes => 'Pište soukromé poznámky, postřehy, plány…';

  @override
  String get writeSkillContent => 'Sem napište obsah dovednosti (Markdown)…';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'před $count lety',
      many: 'před $count lety',
      few: 'před $count lety',
      one: 'před 1 rokem',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'Včera';

  @override
  String get focusModeStart => 'Spustit soustředěnou relaci';

  @override
  String get focusModeConfigTitle => 'Spustit soustředěnou relaci';

  @override
  String get focusModeGoalLabel => 'Cíl';

  @override
  String get focusModeGoalHint => 'Na čem pracujete?';

  @override
  String get focusModeDurationLabel => 'Délka';

  @override
  String get focusModeBlockNotifications => 'Blokovat oznámení';

  @override
  String get focusModeStartButton => 'Spustit';

  @override
  String get focusModeFloat => 'Minimalizovat na lištu';

  @override
  String get focusModeActiveTooltip =>
      'Režim soustředění je aktivní — klepněte pro ukončení';

  @override
  String get dismiss => 'Zavřít';

  @override
  String get acceptAndResolve => 'Přijmout a vyřešit';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'Kontrolujete už $minutes min — výzkum naznačuje, že kvalita kontroly může po 60 min klesat. Zvažte přestávku.';
  }

  @override
  String get notificationSound => 'Zvuk oznámení';

  @override
  String get notificationSoundDescription =>
      'Zvuk přehrávaný při zobrazení oznámení.';

  @override
  String get notificationSoundNone => 'Žádný';

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
  String get notificationSoundMigrosSoft => 'Migros (měkký)';

  @override
  String get notificationSoundMigrosHard => 'Migros (tvrdý)';

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
  String get notificationVolume => 'Hlasitost';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'Žádné PR od @$login v tomto pracovním prostoru';
  }

  @override
  String get usersLabel => 'Uživatelé';

  @override
  String get mergePullRequest => 'Sloučit pull request';

  @override
  String get forceMergePullRequest => 'Vynutit sloučení pull requestu';

  @override
  String get closePullRequest => 'Zavřít pull request';

  @override
  String get closePullRequestConfirm =>
      'Opravdu chcete zavřít tento pull request?';

  @override
  String get stackedPullRequests => 'Skládané pull requesty';

  @override
  String partOfStack(int position, int total) {
    return 'Součást zásobníku ($position z $total)';
  }

  @override
  String get createStack => 'Vytvořit zásobník';

  @override
  String get createStackDialogTitle => 'Vytvořit zásobník pull requestů';

  @override
  String createStackDialogBody(int count) {
    return 'Těchto $count pull requestů se poskládá zdola nahoru:';
  }

  @override
  String get createStackInvalidSelection =>
      'Pro vytvoření zásobníku vyberte alespoň dva pull requesty ze stejného repozitáře';

  @override
  String get createStackNotAChain =>
      'Vybrané pull requesty netvoří řetěz: základní větev každého musí být head větev předchozího';

  @override
  String get createStackAlreadyStacked =>
      'Jeden nebo více vybraných pull requestů už je v zásobníku';

  @override
  String get stackCreated => 'Zásobník vytvořen';

  @override
  String get stackCreationFailed => 'Zásobník se nepodařilo vytvořit';

  @override
  String get squashAndMerge => 'Squash a sloučení';

  @override
  String get createMergeCommit => 'Vytvořit merge commit';

  @override
  String get rebaseAndMerge => 'Rebase a sloučení';

  @override
  String get commitTitle => 'Název commitu';

  @override
  String get commitDescription => 'Popis commitu';

  @override
  String get pullRequestMerged => 'Pull request sloučen';

  @override
  String get pullRequestClosed => 'Pull request zavřen';

  @override
  String failedToMergePr(String error) {
    return 'Sloučení selhalo: $error';
  }

  @override
  String failedToClosePr(String error) {
    return 'Zavření selhalo: $error';
  }

  @override
  String get markReadyForReview => 'Připraveno ke kontrole';

  @override
  String get markReadyForReviewConfirm =>
      'Tento pull request opustí koncept. Recenzenti dostanou oznámení, povinné kontroly začnou bránit sloučení a spustí se automatizace sledující připravené pull requesty.';

  @override
  String get convertToDraft => 'Převést na koncept';

  @override
  String get convertToDraftConfirm =>
      'Tento pull request se vrátí do konceptu. Čekající žádosti o kontrolu se zruší a nelze ho sloučit, dokud ho znovu neoznačíte jako připravený.';

  @override
  String get pullRequestMarkedReady =>
      'Pull request označen jako připravený ke kontrole';

  @override
  String get pullRequestConvertedToDraft => 'Pull request převeden na koncept';

  @override
  String failedToMarkPrReady(String error) {
    return 'Označení jako připravený ke kontrole selhalo: $error';
  }

  @override
  String failedToConvertPrToDraft(String error) {
    return 'Převod na koncept selhal: $error';
  }

  @override
  String get checksFailing => 'Kontroly selhávají';

  @override
  String get reviewsPending => 'Některé kontroly čekají';

  @override
  String get mergeConflictsWithBase =>
      'Tato větev má konflikty, které je nutné vyřešit';

  @override
  String get branchOutOfDateWithBase =>
      'Tato větev je zastaralá vůči základní větvi';

  @override
  String get mergeBlockedByBranchProtection =>
      'Ochrana větve toto sloučení blokuje';

  @override
  String get confirm => 'Potvrdit';

  @override
  String get trustedSitesSectionTitle => 'Důvěryhodné weby';

  @override
  String get trustedSitesEmpty =>
      'Žádné důvěryhodné weby. Přidejte doménu a vypněte na ní blokování.';

  @override
  String get addTrustedSite => 'Přidat důvěryhodný web';

  @override
  String get removeTrustedSite => 'Odebrat';

  @override
  String get disableBlockingForThisSite => 'Vypnout blokování na tomto webu';

  @override
  String get enableBlockingForThisSite => 'Zapnout blokování na tomto webu';

  @override
  String get enterDomainHint => 'např. example.com';

  @override
  String get invalidDomain => 'Zadejte platnou doménu (např. example.com)';

  @override
  String get pageLoadTimedOut =>
      'Načtení stránky vypršelo. Načtěte znovu nebo otevřete v prohlížeči.';

  @override
  String get pipelinesScreenTitle => 'Pipelines';

  @override
  String get pipelinesScreenSubtitle =>
      'Deklarativní vícestupňové workflow agentů';

  @override
  String get pipelinesRunPipeline => 'Spustit pipeline';

  @override
  String get pipelineRunLauncherTitle => 'Spustit pipeline';

  @override
  String get pipelineRunSubtitle =>
      'Vyberte pipeline a vyplňte vstupy pro spuštění běhu.';

  @override
  String get pipelineRunNoInputsBadge => 'Žádné vstupy';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vstupů',
      many: '$count vstupů',
      few: '$count vstupy',
      one: '1 vstup',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'Tato pipeline nemá žádné vstupy.';

  @override
  String get pipelineRunSubmit => 'Spustit pipeline';

  @override
  String get pipelineRunCouldNotStart => 'Běh se nepodařilo spustit.';

  @override
  String pipelineRunStarted(String name) {
    return 'Spuštěno $name';
  }

  @override
  String get pipelineRunEmptyTitle => 'Žádné pipeline připravené ke spuštění';

  @override
  String get pipelineRunEmptyHint =>
      'Povolte pipeline a v editoru zapněte ruční spuštění, abyste ji tu mohli spustit.';

  @override
  String get pipelineRunManageTemplates => 'Spravovat pipeline';

  @override
  String get pipelineRunSettingsTitle => 'Ruční spuštění';

  @override
  String get pipelineRunSettingsAllow => 'Povolit ruční spuštění';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'Zobrazit tuto pipeline na stránce běhů, aby šla spustit ručně.';

  @override
  String get pipelineRunSettingsConcurrencyTitle => 'Souběh';

  @override
  String get pipelineRunSettingsMaxParallel => 'Max. souběžných běhů';

  @override
  String get pipelineRunSettingsMaxParallelHelp =>
      'Nechte prázdné pro neomezeno. Další běhy čekají ve frontě a startují, jak se uvolní sloty.';

  @override
  String get pipelineRunSettingsMaxParallelHint => 'Neomezeno';

  @override
  String get pipelineRunSettingsMaxParallelInvalid =>
      'Zadejte celé číslo 1 nebo více, nebo nechte prázdné pro neomezeno.';

  @override
  String get pipelineRunSettingsInputsTitle => 'Vstupy';

  @override
  String get pipelineRunSettingsAddInput => 'Přidat vstup';

  @override
  String get pipelineRunSettingsNoInputs => 'Zatím žádné vstupy.';

  @override
  String get pipelineInputEditTitle => 'Vstupní pole';

  @override
  String get pipelineInputKeyLabel => 'Klíč';

  @override
  String get pipelineInputKeyHelp =>
      'Klíč stavu, pod kterým se hodnota uloží (např. repo_full_name).';

  @override
  String get pipelineInputLabelLabel => 'Popisek';

  @override
  String get pipelineInputTypeLabel => 'Typ';

  @override
  String get pipelineInputOptionsLabel => 'Možnosti (oddělené čárkou)';

  @override
  String get pipelineInputDefaultLabel => 'Výchozí hodnota';

  @override
  String get pipelineInputPlaceholderLabel => 'Zástupný text';

  @override
  String get pipelineInputHelpLabel => 'Nápověda';

  @override
  String get pipelineInputRequiredLabel => 'Povinné';

  @override
  String get pipelineInputTypeText => 'Text';

  @override
  String get pipelineInputTypeMultiline => 'Víceřádkový text';

  @override
  String get pipelineInputTypeNumber => 'Číslo';

  @override
  String get pipelineInputTypeBoolean => 'Přepínač';

  @override
  String get pipelineInputTypeSelect => 'Výběr';

  @override
  String get pipelinesEmpty => 'Zatím žádné běhy pipeline';

  @override
  String get pipelinesEmptyHint =>
      'Klikněte na „Spustit pipeline“ a spusťte jeden.';

  @override
  String get pipelinesNoSteps => 'Zatím nejsou zaznamenány žádné kroky';

  @override
  String get pipelinesNoActiveWorkspace =>
      'Vyberte pracovní prostor pro zobrazení jeho pipeline';

  @override
  String pipelinesLoadError(String error) {
    return 'Pipeline se nepodařilo načíst: $error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'Pipeline se nepodařilo spustit: $error';
  }

  @override
  String get pipelineStatusPending => 'Čeká';

  @override
  String get pipelineStatusQueued => 'Ve frontě';

  @override
  String get pipelineStatusRunning => 'Běží';

  @override
  String get pipelineStatusSuspended => 'Pozastaveno';

  @override
  String get pipelineStatusCompleted => 'Dokončeno';

  @override
  String get pipelineStatusFailed => 'Selhalo';

  @override
  String get pipelineStatusCancelled => 'Zrušeno';

  @override
  String get pipelineStatusSkipped => 'Přeskočeno';

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed z $total kroků';
  }

  @override
  String get pipelineWaterfallTimeline => 'Časová osa';

  @override
  String pipelineWaterfallActive(String duration) {
    return 'Aktivní $duration';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return 'nečinné $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip =>
      'Čas vyloučený z aktivního součtu: běh byl zastaven nebo čekal mezi kroky.';

  @override
  String get pipelineStepStarted => 'Spuštěno';

  @override
  String get pipelineStepFinished => 'Dokončeno';

  @override
  String get pipelineStepDurationLabel => 'Trvání';

  @override
  String get pipelineStepBranch => 'Větev';

  @override
  String get pipelineStepViewConversation => 'Zobrazit konverzaci';

  @override
  String get pipelineStepError => 'Chyba';

  @override
  String get pipelineStepInput => 'Vstup';

  @override
  String get pipelineStepOutput => 'Výstup';

  @override
  String get pipelineStepNotExecuted => 'Zatím nespustěno';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'Selhalo u $step';
  }

  @override
  String get pipelineRunTriggerManual => 'Ručně';

  @override
  String get pipelineStepSkippedReason => 'Přeskočeno';

  @override
  String get pipelineStepPriorAttempts => 'Předchozí pokusy';

  @override
  String get pipelineStepAttemptLabel => 'Pokus';

  @override
  String pipelineStepAttemptN(int number) {
    return 'Pokus $number';
  }

  @override
  String get pipelineStepAttemptInterrupted => 'Přerušeno';

  @override
  String get pipelineRunColumnPipeline => 'Pipeline';

  @override
  String get pipelineRunColumnDuration => 'Trvání';

  @override
  String get pipelineRunQueueNext => 'Další';

  @override
  String pipelineRunQueuePosition(int position) {
    return '$position ve frontě';
  }

  @override
  String get pipelineRunColumnStarted => 'Spuštěno';

  @override
  String get pipelineRunHistory => 'Historie běhů';

  @override
  String get pipelineRunHistoryEmpty => 'Zatím žádné další běhy';

  @override
  String pipelineRunRerunAgo(String time) {
    return 'Znovuspuštění $time';
  }

  @override
  String pipelineRunAttempt(int number) {
    return 'Pokus $number';
  }

  @override
  String pipelineRunFirstStarted(String time) {
    return 'první spuštění $time';
  }

  @override
  String get pipelineRunFilterAll => 'Vše';

  @override
  String get pipelineRunFilterEmpty => 'Žádné běhy neodpovídají tomuto filtru';

  @override
  String get relativeJustNow => 'právě teď';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'před $count min',
      many: 'před $count min',
      few: 'před $count min',
      one: 'před 1 min',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'před $count hodinami',
      many: 'před $count hodinami',
      few: 'před $count hodinami',
      one: 'před 1 hodinou',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'před $count dny',
      many: 'před $count dny',
      few: 'před $count dny',
      one: 'před 1 dnem',
    );
    return '$_temp0';
  }

  @override
  String get teamsTitle => 'Týmy';

  @override
  String get teamsAddTeam => 'Přidat tým';

  @override
  String get teamsLoadError => 'Týmy se nepodařilo načíst';

  @override
  String get teamsEmptyTitle => 'Zatím žádné týmy';

  @override
  String get teamsEmptyDescription =>
      'Seskupte agenty do týmů, aby práci přiřazenou týmu směroval vedoucí, který deleguje.';

  @override
  String get teamCreateTitle => 'Nový tým';

  @override
  String get teamEditTitle => 'Upravit tým';

  @override
  String get teamNameLabel => 'Název týmu';

  @override
  String get teamNameHint => 'např. Frontend';

  @override
  String get teamDescriptionLabel => 'Popis';

  @override
  String get teamDescriptionHint => 'Za co je tento tým zodpovědný';

  @override
  String get teamLeaderLabel => 'Vedoucí';

  @override
  String get teamLeaderHelp =>
      'Koordinátor, který přijímá práci přiřazenou týmu a deleguje na nejvhodnějšího člena.';

  @override
  String get teamNoLeader => 'Bez vedoucího';

  @override
  String get teamInstructionsLabel => 'Provozní pokyny';

  @override
  String get teamInstructionsHelp =>
      'Připojí se k briefingu vedoucího — konvence týmu, eskalace, tón.';

  @override
  String get teamInstructionsHint => 'Volitelné';

  @override
  String get teamSaved => 'Tým uložen';

  @override
  String get teamMembersError => 'Členy se nepodařilo načíst';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count členů',
      many: '$count členů',
      few: '$count členové',
      one: '1 člen',
      zero: 'Žádní členové',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => 'Přidat člena';

  @override
  String get teamAddMemberTitle => 'Přidat členy';

  @override
  String teamAddMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Přidat $count',
      many: 'Přidat $count',
      few: 'Přidat $count',
      one: 'Přidat 1',
      zero: 'Přidat',
    );
    return '$_temp0';
  }

  @override
  String get teamNoAgentsToAdd => 'Každý agent už je v tomto týmu.';

  @override
  String get teamRemoveMember => 'Odebrat z týmu';

  @override
  String get teamLeaderBadge => 'Vedoucí';

  @override
  String get teamUnknownAgent => 'Neznámý agent';

  @override
  String get teamMembersEmpty => 'Zatím žádní členové';

  @override
  String get teamMembersEmptyDescription =>
      'Přidejte agenty, aby měl vedoucí koho delegovat.';

  @override
  String get teamSelectPrompt => 'Vyberte tým';

  @override
  String get teamSelectPromptDescription =>
      'Vyberte tým ze seznamu, nebo vytvořte nový.';

  @override
  String get teamDeleteTitle => 'Smazat tým?';

  @override
  String teamDeleteBody(String name) {
    return '$name bude smazán. Jeho agenti zůstanou nedotčeni.';
  }

  @override
  String get teamHasLeaderTooltip => 'Má vedoucího';

  @override
  String get pipelineTemplatesNav => 'Šablony pipeline';

  @override
  String get pipelineTemplatesTitle => 'Šablony pipeline';

  @override
  String get pipelineTemplatesSubtitle =>
      'Editor přetahováním pro pipeline, které orchestrují vaše agenty.';

  @override
  String get pipelineTemplatesNew => 'Nová šablona';

  @override
  String get pipelineTemplatesEmpty =>
      'Zatím žádné šablony pipeline. Vytvořte jednu a začněte.';

  @override
  String get pipelineTemplateBuiltInBadge => 'Vestavěná';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'Smazat šablonu?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'Smazat šablonu pipeline $name? Tuto akci nelze vrátit zpět.';
  }

  @override
  String get pipelineTemplateEditorSubtitle =>
      'Přetáhněte typy uzlů z postranního panelu na plátno a propojte je.';

  @override
  String get unsavedChanges => 'Neuložené změny';

  @override
  String get nodeLibraryTitle => 'Knihovna uzlů';

  @override
  String get nodeLibraryHint =>
      'Přetáhněte libovolnou položku na plátno a přidejte uzel.';

  @override
  String get editorEmptyCanvas => 'Začněte přetažením uzlu z knihovny.';

  @override
  String get pipelineWhenThisHappens => 'Když se to stane';

  @override
  String get pipelineDoThis => 'Proveďte toto';

  @override
  String get pipelineAddStep => 'Přidat krok';

  @override
  String get pipelineTidyUp => 'Uklidit rozložení';

  @override
  String get pipelineEditorHint =>
      'Přetáhněte kroky pro uspořádání · přetáhněte úchyt pro propojení';

  @override
  String get pipelineRemoveConnection => 'Odebrat spojení';

  @override
  String get pipelineDragToConnect => 'Přetáhněte pro propojení';

  @override
  String get pipelineNewDefaultName => 'Nový pipeline';

  @override
  String get nodeCategoryTriggers => 'Spouštěče';

  @override
  String get triggerEventWebhook => 'Webhook';

  @override
  String get pipelineAddTrigger => 'Přidat spouštěč';

  @override
  String get pipelineOnEvent => 'Při události';

  @override
  String get nodeConfigTitle => 'Konfigurace uzlu';

  @override
  String get nodeConfigKind => 'Druh';

  @override
  String get nodeConfigLabel => 'Popisek';

  @override
  String get nodeConfigAgent => 'Agent';

  @override
  String get nodeConfigAgentHint => 'Vyberte agenta…';

  @override
  String get nodeConfigInputKeys => 'Vstupní klíče (oddělené čárkou)';

  @override
  String get nodeConfigInputKeysHelp =>
      'Klíče stavu, které tento uzel spotřebovává. Používají se pro zástupný text v promptu.';

  @override
  String get nodeConfigRepos => 'Repozitáře ke klonování';

  @override
  String get nodeConfigReposHelp =>
      'Repozitáře naklonované a indexované, když tento uzel spustí konverzaci. Výběr všech je naklonuje (výchozí).';

  @override
  String get nodeConfigRepoBranchHint => 'Větev (výchozí)';

  @override
  String get nodeConfigRepoBranchHelp =>
      'Větev, ze které se checkout odřízne. Nechte prázdné pro vlastní výchozí větev repozitáře — worktree stejně dostane vlastní větev, takže nic, co agent commitne, na tuto neskončí.';

  @override
  String nodeConfigReposDynamic(String entries) {
    return 'Zachované dynamické položky: $entries';
  }

  @override
  String get nodeConfigCreateConversation => 'Otevřít v ní konverzaci';

  @override
  String get nodeConfigCreateConversationHelp =>
      'Nechte vypnuté, když následuje několik uzlů agentů — každý otevře vlastní pojmenovaný stream. Zapněte, když následuje jeden uzel agenta, aby místnost neukazovala vedle něj nepojmenovanou konverzaci.';

  @override
  String get nodeConfigConversationTitle => 'Název konverzace';

  @override
  String get nodeConfigConversationTitleHelp =>
      'Dejte uzlu agenta po proudu stejný název a oba pracují v jednom streamu. Výchozí je popisek uzlu.';

  @override
  String get nodeConfigSpaceName => 'Název prostoru';

  @override
  String get nodeConfigSpaceNameHelp =>
      'Jak se jmenuje místnost, kterou tento uzel otevře. Podporuje stejné zástupné znaky stavu jako prompt. Nechte prázdné a použije se popisek uzlu.';

  @override
  String get nodeConfigSpaceNameHint => 'Kontrola pr_number';

  @override
  String get nodeConfigStreamTitle => 'Název konverzace';

  @override
  String get nodeConfigStreamTitleHelp =>
      'Pojmenovaný stream, ve kterém agent tohoto uzlu pracuje v místnosti. Podporuje stejné zástupné znaky stavu jako prompt. Nechte prázdné a tah skončí ve stálé konverzaci místnosti, kde se agenti prokládají.';

  @override
  String get nodeConfigConversationTitleHint => 'Analýza architektury';

  @override
  String get nodeConfigOutputKey => 'Výstupní klíč';

  @override
  String get nodeConfigPrompt => 'Šablona promptu';

  @override
  String get nodeConfigPromptHelp =>
      'Použijte zástupné znaky ve dvojitých složených závorkách a za běhu vytáhněte hodnoty ze stavu.';

  @override
  String get nodeConfigScript => 'Bash skript';

  @override
  String get nodeConfigScriptHelp =>
      'Běží přes bash -c. GITHUB_TOKEN je nastaven. Zástupné znaky se nahradí před spuštěním.';

  @override
  String get nodeConfigRouteKeys => 'Klíče trasy';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'Klíč trasy z $source';
  }

  @override
  String get conditionSectionTitle => 'Podmínka';

  @override
  String get conditionMode => 'Režim';

  @override
  String get conditionModeFilesAny => 'Soubor(y) existují — libovolný';

  @override
  String get conditionModeFilesAll => 'Soubory existují — všechny';

  @override
  String get conditionModeComparison => 'Porovnání';

  @override
  String get conditionModeSwitch => 'Přepínač';

  @override
  String get conditionFilePaths => 'Cesty k souborům';

  @override
  String get conditionFilePathsAnyHelp =>
      'Jedna cesta na řádek, relativně k základnímu adresáři. Trasa true, když existuje libovolná.';

  @override
  String get conditionFilePathsAllHelp =>
      'Jedna cesta na řádek, relativně k základnímu adresáři. Trasa true, jen když existují všechny.';

  @override
  String get conditionBaseKey => 'Klíč základního adresáře';

  @override
  String get conditionBaseKeyHelp =>
      'Klíč stavu s adresářem, vůči kterému se cesty řeší (výchozí repo_local_path).';

  @override
  String get conditionRecursive => 'Prohledávat podadresáře';

  @override
  String get conditionNegate => 'Obrátit: trasa true, když chybí';

  @override
  String get conditionLeft => 'Levá hodnota';

  @override
  String get conditionOperator => 'Operátor';

  @override
  String get conditionRight => 'Pravá hodnota';

  @override
  String get conditionSwitchKey => 'Přepnout podle klíče stavu';

  @override
  String get conditionCases => 'Případy (oddělené čárkou)';

  @override
  String get conditionCasesHelp =>
      'Klíče trasy k porovnání s hodnotou, v pořadí.';

  @override
  String get conditionDefaultCase => 'Výchozí případ';

  @override
  String get triggerManualHelp => 'Zobrazit na stránce běhů a spustit ručně.';

  @override
  String get triggerKindSchedule => 'Podle plánu';

  @override
  String get triggerScheduleExprLabel => 'Plán (cron nebo every:seconds)';

  @override
  String get triggerTimezoneLabel => 'Časové pásmo (volitelné)';

  @override
  String get triggerCatchUpLabel => 'Při zmeškaných bězích';

  @override
  String get triggerCatchUpRunOnce => 'Spustit jednou';

  @override
  String get triggerCatchUpSkip => 'Přeskočit';

  @override
  String get syncHealthTitle => 'Zdraví synchronizace';

  @override
  String get syncHealthNoConfigs => 'Zatím žádná připojení synchronizace';

  @override
  String get syncHealthNeverSynced => 'Nikdy nesynchronizováno';

  @override
  String get syncOutcomeOk => 'Synchronizováno';

  @override
  String get syncOutcomeFailed => 'Selhalo';

  @override
  String get syncOutcomeSkipped => 'Přeskočeno';

  @override
  String syncHealthFailedStreak(int count) {
    return '$count po sobě jdoucích selhání';
  }

  @override
  String get triggerWebhookHelp =>
      'Vygeneruje se podepsané URL webhooku. Externí systémy na něj POSTují a spustí tuto pipeline.';

  @override
  String get triggerWebhookPathLabel => 'Cesta webhooku';

  @override
  String get triggerMatchStatusLabel => 'Jen když stav je';

  @override
  String get triggerSummaryNone => 'Žádné spouštěče';

  @override
  String triggerEverySeconds(int seconds) {
    return 'Každých $seconds s';
  }

  @override
  String get triggerEventManual => 'Ruční spuštění';

  @override
  String get triggerEventSchedule => 'Plán';

  @override
  String get triggerEventPrStatusChanged => 'Změna stavu PR';

  @override
  String get triggerEventExternalPr => 'Otevřen externí PR';

  @override
  String get triggerEventPrPublished => 'PR zveřejněn';

  @override
  String get triggerEventPrMerged => 'PR sloučen';

  @override
  String get triggerEventRepoAdded => 'Přidán repozitář';

  @override
  String get triggerEventCodeGraphWatch => 'Změna souboru';

  @override
  String pipelineRunCauseChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count změněných souborů',
      many: '$count změněných souborů',
      few: '$count změněné soubory',
      one: '1 změněný soubor',
    );
    return '$_temp0';
  }

  @override
  String pipelineRunCauseMorePaths(int count) {
    return '+$count dalších';
  }

  @override
  String get pipelineRunCauseRescan => 'Změněno na disku';

  @override
  String get pipelineRunCauseInitial => 'První index tohoto checkoutu';

  @override
  String get triggerEventMessageReceived => 'Přijata zpráva';

  @override
  String get triggerEventTicketCompleted => 'Ticket dokončen';

  @override
  String get triggerEventTicketFailed => 'Ticket selhal';

  @override
  String get triggerEventTicketCancelled => 'Ticket zrušen';

  @override
  String get triggerEventBudgetCrossed => 'Překročen práh rozpočtu';

  @override
  String get nodeLibrarySearchHint => 'Hledat uzly';

  @override
  String get nodeLibraryNoMatches => 'Žádné odpovídající uzly';

  @override
  String get nodeCategoryFlow => 'Tok a logika';

  @override
  String get nodeCategoryPr => 'Kontrola PR';

  @override
  String get nodeCategoryAgents => 'Agenti';

  @override
  String get nodeCategoryMessaging => 'Zprávy';

  @override
  String get nodeCategoryCode => 'Kód';

  @override
  String get triggerDisabledTag => 'vyp';

  @override
  String get pipelineInputTypeRepo => 'Repozitář';

  @override
  String get pipelineRunNoRepos =>
      'V tomto pracovním prostoru zatím nejsou žádné repozitáře.';

  @override
  String get allowTicketingApi => 'Povolit volání ticketing API';

  @override
  String get ticketingApiKey => 'API klíč ticketingu';

  @override
  String get ticketingApiKeySubtitle =>
      'Vloží API klíč poskytovatele ticketingu do sandboxu.';

  @override
  String get ticketingProvider => 'Poskytovatel ticketingu';

  @override
  String get connectGitHubAndTicketing =>
      'Připojte hostitele kódu, aby Control Center mohl číst vaše pull requesty, issues a kontroly. Volitelně připojte poskytovatele ticketingu. Přihlašovací údaje drží server, nikoli tento stroj.';

  @override
  String get triggerEventTicketAssigned => 'Ticket přiřazen';

  @override
  String get triggerEventTicketCreated => 'Ticket vytvořen';

  @override
  String get triggerEventTicketStatusChanged => 'Stav ticketu se změnil';

  @override
  String get triggerEventMeetingRecordingStopped =>
      'Nahrávání schůzky zastaveno';

  @override
  String get triggerEventSkillUpdated => 'Dovednost aktualizována';

  @override
  String get triggerEventSpaceDeleted => 'Prostor smazán';

  @override
  String get triggerExternalPrHelp =>
      'Pull request otevřený na hostiteli kódu, ne z Control Center.';

  @override
  String get triggerPrPublishedHelp =>
      'Pull request otevřený z Control Center nebo agentem.';

  @override
  String get triggerPrStatusChangedHelp =>
      'Sloučený, uzavřený, otevřený, znovu otevřený nebo schválený. Stav vyfiltrujete v inspectoru.';

  @override
  String get triggerPrMergedHelp =>
      'Jen když je pull request sloučen, ne uzavřen nebo znovu otevřen.';

  @override
  String get triggerRepoAddedHelp =>
      'K tomuto pracovnímu prostoru se připojí repozitář.';

  @override
  String get triggerCodeGraphWatchHelp =>
      'Soubor v připojeném repozitáři se změní na disku.';

  @override
  String get triggerMessageReceivedHelp => 'Do prostoru dorazí nová zpráva.';

  @override
  String get triggerTicketCreatedHelp =>
      'V tomto pracovním prostoru se vytvoří tiket.';

  @override
  String get triggerTicketStatusChangedHelp => 'Tiket se přesune mezi stavy.';

  @override
  String get triggerTicketCompletedHelp => 'Tiket úspěšně skončí.';

  @override
  String get triggerTicketFailedHelp =>
      'Běh agenta selhal a tiket je označen jako neúspěšný.';

  @override
  String get triggerTicketCancelledHelp =>
      'Tiket je zrušen a nebude pokračovat.';

  @override
  String get triggerBudgetCrossedHelp =>
      'Je překročen limit výdajů pracovního prostoru nebo agenta.';

  @override
  String get triggerTicketAssignedHelp =>
      'Tiket je přiřazen osobě, agentovi nebo týmu.';

  @override
  String get triggerMeetingRecordingStoppedHelp => 'Nahrávání schůzky skončí.';

  @override
  String get triggerSkillUpdatedHelp =>
      'Dovednost je nainstalována nebo aktualizována.';

  @override
  String get triggerSpaceDeletedHelp => 'Konverzační prostor je smazán.';

  @override
  String get navTickets => 'Tickety';

  @override
  String get ticketsTitle => 'Tickety';

  @override
  String get newTicket => 'Nový ticket';

  @override
  String get noTicketsYet => 'Zatím žádné tickety';

  @override
  String get addCollaborator => 'Přidat spolupracovníka';

  @override
  String get noCollaborators => 'Zatím žádní spolupracovníci';

  @override
  String get linkedPullRequests => 'Propojené pull requesty';

  @override
  String get noLinkedPullRequests => 'Zatím žádné propojené pull requesty';

  @override
  String get stopAgent => 'Zastavit agenta';

  @override
  String get ticketProperties => 'Vlastnosti';

  @override
  String get ticketTabIssue => 'Issue';

  @override
  String get ticketSelectPrompt => 'Vyberte ticket a zobrazte jeho detaily';

  @override
  String get unassigned => 'Nepřiřazeno';

  @override
  String get ticketStatusBacklog => 'Backlog';

  @override
  String get ticketStatusOpen => 'K udělání';

  @override
  String get ticketStatusInProgress => 'Probíhá';

  @override
  String get ticketStatusInReview => 'V kontrole';

  @override
  String get ticketStatusDone => 'Hotovo';

  @override
  String get ticketStatusBlocked => 'Blokováno';

  @override
  String get ticketStatusFailed => 'Selhalo';

  @override
  String get ticketStatusCancelled => 'Zrušeno';

  @override
  String get notificationTicketAssigned => 'Ticket přiřazen';

  @override
  String get notificationTicketStatusChanged => 'Stav ticketu změněn';

  @override
  String get priority => 'Priorita';

  @override
  String get status => 'Stav';

  @override
  String get assignee => 'Přiřazený';

  @override
  String get labels => 'Štítky';

  @override
  String get noLabelsYet => 'Zatím žádné štítky';

  @override
  String get clearLabels => 'Vymazat štítky';

  @override
  String get pipelineStepAgentActivity => 'Aktivita agenta';

  @override
  String get runStatusCompleted => 'Dokončeno';

  @override
  String get runStatusQueued => 'Ve frontě';

  @override
  String get ticketDescription => 'Popis';

  @override
  String get ticketPriorityNone => 'Žádná';

  @override
  String get ticketPriorityUrgent => 'Urgentní';

  @override
  String get ticketPriorityHigh => 'Vysoká';

  @override
  String get ticketPriorityMedium => 'Střední';

  @override
  String get ticketPriorityLow => 'Nízká';

  @override
  String get ticketViewList => 'Seznam';

  @override
  String get ticketViewBoard => 'Tabule';

  @override
  String get ticketTitlePlaceholder => 'Název issue';

  @override
  String get ticketDescriptionPlaceholder => 'Přidat popis…';

  @override
  String get createMore => 'Vytvořit další';

  @override
  String selectedCount(int count) {
    return '$count vybráno';
  }

  @override
  String get clearSelection => 'Zrušit výběr';

  @override
  String get bulkDeleteTitle => 'Smazat tickety';

  @override
  String bulkDeleteMessage(int count) {
    return 'Smazat $count vybraných ticketů? Tuto akci nelze vrátit zpět.';
  }

  @override
  String get assignTo => 'Přiřadit…';

  @override
  String get sectionMembers => 'Členové';

  @override
  String get sectionAgents => 'Agenti';

  @override
  String get sidebarGroupWorkspace => 'Pracovní prostor';

  @override
  String get notificationsTitle => 'Oznámení';

  @override
  String get notificationsTooltip => 'Oznámení';

  @override
  String get notificationsEmpty => 'Máte všechno přečtené';

  @override
  String notificationsUnreadCount(int count) {
    return '$count nepřečtených';
  }

  @override
  String get notificationsMarkRead => 'Označit jako přečtené';

  @override
  String get notificationsMarkUnread => 'Označit jako nepřečtené';

  @override
  String get notificationsEntryActions => 'Akce oznámení';

  @override
  String get markAllRead => 'Označit vše jako přečtené';

  @override
  String get teamsNav => 'Týmy';

  @override
  String get noWorkspace => 'Žádný pracovní prostor';

  @override
  String get selectWorkspace => 'Vyberte pracovní prostor';

  @override
  String get navMemory => 'Paměť';

  @override
  String get memoryTabFacts => 'Fakta';

  @override
  String get memoryTabPolicies => 'Politiky';

  @override
  String get memoryGraphShowFacts => 'Zobrazit fakta';

  @override
  String get memoryGraphHideFacts => 'Skrýt fakta';

  @override
  String get memoryGraphExpandAll => 'Rozbalit všechna fakta';

  @override
  String get memoryGraphCollapseAll => 'Sbalit všechna fakta';

  @override
  String get memoryTabGraph => 'Graf znalostí';

  @override
  String get memoryNoWorkspace =>
      'Vyberte pracovní prostor pro zobrazení jeho paměti.';

  @override
  String get searchArticles => 'Hledat články';

  @override
  String get filterAll => 'Vše';

  @override
  String get filterUnread => 'Nepřečtené';

  @override
  String get filterSaved => 'Uložené';

  @override
  String get saveArticle => 'Uložit článek';

  @override
  String get removeFromSaved => 'Odebrat z uložených';

  @override
  String get filterBySource => 'Filtrovat podle zdroje';

  @override
  String get viewAsList => 'Zobrazení seznamu';

  @override
  String get viewAsGrid => 'Zobrazení mřížky';

  @override
  String get noMatchingArticles => 'Žádné odpovídající články';

  @override
  String get noMatchingArticlesBody => 'Zkuste jiné hledání nebo filtr zdroje.';

  @override
  String get allCaughtUp => 'Máte všechno přečtené';

  @override
  String get allCaughtUpBody => 'Žádné nepřečtené články — zkuste to později.';

  @override
  String get openArticlesInAppDescription =>
      'Otevírat odkazy ve vestavěné čtečce místo výchozího prohlížeče.';

  @override
  String get blockAdsTrackersDescription =>
      'Odstraňovat reklamy, trackery a cookie bannery z článků otevřených ve čtečce.';

  @override
  String get agentQuestionHeader => 'Otázka pro vás';

  @override
  String get agentQuestionAnsweredLabel => 'Zodpovězeno';

  @override
  String get agentQuestionFreeformHint => 'Napište odpověď…';

  @override
  String agentQuestionProgress(int index, int count) {
    return 'Otázka $index z $count';
  }

  @override
  String get agentQuestionSkip => 'Přeskočit';

  @override
  String get agentQuestionSkippedLabel => 'Přeskočeno';

  @override
  String get agentQuestionFreeformOptionHint => 'Popište to vlastními slovy…';

  @override
  String get reviewRequested => 'Vyžádána kontrola';

  @override
  String get connectGitHubHint =>
      'Přihlaste se na GitHub nebo přidejte token v Nastavení → Pracovní prostor → Profil a identita → Hostování kódu';

  @override
  String get connectGitHubToLoadPrs =>
      'Připojte GitHub a načtěte pull requesty';

  @override
  String get noRepositoriesConfigured => 'Žádné nakonfigurované repozitáře';

  @override
  String openedAgo(String age) {
    return 'Otevřeno $age';
  }

  @override
  String prTimelineOpened(String author) {
    return '$author otevřel tento pull request';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commity',
      many: '$count commity',
      few: '$count commity',
      one: '1 commitem',
    );
    return '$author otevřel tento pull request s $_temp0';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return '$actor požádal o kontrolu od $reviewers';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '$actor odebral žádost o kontrolu pro $reviewers';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '$actor požádal o kontrolu od $requested a odebral žádost o kontrolu pro $removed';
  }

  @override
  String prTimelineAddedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'štítky',
      one: 'štítek',
    );
    return '$actor přidal $_temp0 $labels';
  }

  @override
  String prTimelineRemovedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'štítky',
      one: 'štítek',
    );
    return '$actor odebral $_temp0 $labels';
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
      other: 'štítky',
      one: 'štítek',
    );
    String _temp1 = intl.Intl.pluralLogic(
      removedCount,
      locale: localeName,
      other: 'štítky',
      one: 'štítek',
    );
    return '$actor přidal $_temp0 $added a odebral $_temp1 $removed';
  }

  @override
  String prTimelineCommitted(String author) {
    return '$author commitnul';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commitů',
      many: '$count commitů',
      few: '$count commity',
      one: '1 commit',
    );
    return '$author odeslal $_temp0';
  }

  @override
  String prTimelineApproved(String author) {
    return '$author schválil tyto změny';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return '$author vyžádal změny';
  }

  @override
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count komentářů ke kódu',
      many: '$count komentářů ke kódu',
      few: '$count komentáře ke kódu',
      one: '1 komentář ke kódu',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '$author zkontroloval';
  }

  @override
  String get prTimelineSomeone => 'Někdo';

  @override
  String get prTimelineBotBadge => 'bot';

  @override
  String updatedAgo(String age) {
    return 'Aktualizováno $age';
  }

  @override
  String get checksPassing => 'Kontroly procházejí';

  @override
  String get checksRunning => 'Kontroly běží';

  @override
  String get needsYourReview => 'Potřebuje vaši kontrolu';

  @override
  String get checks => 'Kontroly';

  @override
  String get noReviewersAssigned => 'Žádní přiřazení recenzenti';

  @override
  String get noAssignees => 'Žádní přiřazení';

  @override
  String get loadingEllipsis => 'Načítání…';

  @override
  String get loadingChecks => 'Načítání kontrol…';

  @override
  String get noChecksYet => 'Zatím neběžely žádné kontroly';

  @override
  String get noChangesToReview => 'Žádné změny k recenzi';

  @override
  String checksFailingCount(int count) {
    return '$count selhává';
  }

  @override
  String get showMore => 'Zobrazit více';

  @override
  String get showLess => 'Zobrazit méně';

  @override
  String get backToPullRequests => 'Zpět na pull requesty';

  @override
  String get pullRequestNotFound => 'Pull request nenalezen';

  @override
  String get pullRequestNotFoundBody =>
      'Možná byl sloučen, zavřen nebo přesunut.';

  @override
  String get couldntLoadPullRequest =>
      'Tento pull request se nepodařilo načíst';

  @override
  String get showDetails => 'Zobrazit detaily';

  @override
  String get noDescriptionProvided => 'Nebyl uveden žádný popis.';

  @override
  String get factsHint => 'Fakta se tu objeví, jak se agenti učí.';

  @override
  String get noFactsMatch => 'Žádná fakta neodpovídají hledání';

  @override
  String get memoryLoadError => 'Paměť se nepodařilo načíst';

  @override
  String get sortRecent => 'Nedávné';

  @override
  String get sortConfidence => 'Jistota';

  @override
  String get confidenceTooltip =>
      'Jak si jsou agenti jistí, že je tento fakt pravdivý, od 0 do 100 %.';

  @override
  String get supersededTooltip => 'Tento fakt nahradil novější.';

  @override
  String get domain => 'Doména';

  @override
  String get fitToView => 'Přizpůsobit zobrazení';

  @override
  String get project => 'Projekt';

  @override
  String get newProject => 'Nový projekt';

  @override
  String get editProject => 'Upravit projekt';

  @override
  String get deleteProject => 'Smazat projekt';

  @override
  String get noProject => 'Žádný projekt';

  @override
  String get allTickets => 'Všechny tickety';

  @override
  String get projectNamePlaceholder => 'Název projektu';

  @override
  String get projectDescriptionPlaceholder => 'Popis (volitelné)';

  @override
  String get projectColorLabel => 'Barva';

  @override
  String get noProjectsYet => 'Zatím žádné projekty';

  @override
  String get projectTicketsEmpty =>
      'V tomto projektu zatím nejsou žádné tickety';

  @override
  String get createProject => 'Vytvořit projekt';

  @override
  String projectProgress(int done, int total) {
    return '$done z $total hotovo';
  }

  @override
  String deleteProjectConfirm(String name) {
    return 'Smazat „$name“? Tickety zůstanou a z projektu se odeberou.';
  }

  @override
  String get projectStatusActive => 'Aktivní';

  @override
  String get projectStatusCompleted => 'Dokončeno';

  @override
  String get projectStatusArchived => 'Archivováno';

  @override
  String get markProjectCompleted => 'Označit jako dokončené';

  @override
  String get markProjectActive => 'Označit jako aktivní';

  @override
  String get archiveProject => 'Archivovat';

  @override
  String get restoreProject => 'Obnovit';

  @override
  String get relations => 'Vztahy';

  @override
  String get relateTo => 'Propojit s';

  @override
  String get relationSubIssueOf => 'Podúkol…';

  @override
  String get relationParentOf => 'Nadřazený…';

  @override
  String get relationBlockedBy => 'Blokováno…';

  @override
  String get relationBlocking => 'Blokuje…';

  @override
  String get relationRelatedTo => 'Související s…';

  @override
  String get relationDuplicateOf => 'Duplicita…';

  @override
  String get relationGroupParent => 'Nadřazený';

  @override
  String get relationGroupSubIssues => 'Podúkoly';

  @override
  String get relationGroupBlockedBy => 'Blokováno';

  @override
  String get relationGroupBlocking => 'Blokuje';

  @override
  String get relationGroupRelated => 'Související';

  @override
  String get relationGroupDuplicateOf => 'Duplicita';

  @override
  String get relationGroupDuplicatedBy => 'Duplikováno';

  @override
  String get copyId => 'Kopírovat ID';

  @override
  String get ticketIdCopied => 'ID ticketu zkopírováno';

  @override
  String get searchTicketsHint => 'Hledat tickety…';

  @override
  String get noMatchingTickets => 'Žádné tickety neodpovídají';

  @override
  String get clearAll => 'Vymazat vše';

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs PR čeká',
      many: '$prs PR čeká',
      few: '$prs PR čekají',
      one: '1 PR čeká',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos repozitáři',
      many: '$repos repozitáři',
      few: '$repos repozitáři',
      one: '1 repozitářem',
    );
    return '$_temp0 na vaši kontrolu napříč $_temp1';
  }

  @override
  String get manageWorkspacesSubtitle =>
      'Přejmenujte pracovní prostor a změňte jeho značku — vyberte jeden vlevo a upravte ho.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pracovních prostorů',
      many: '$count pracovních prostorů',
      few: '$count pracovní prostory',
      one: '1 pracovní prostor',
      zero: 'Žádné pracovní prostory',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos repozitářů',
      many: '$repos repozitářů',
      few: '$repos repozitáře',
      one: '1 repo',
      zero: 'Žádné repozitáře',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents agentů',
      many: '$agents agentů',
      few: '$agents agenti',
      one: '1 agent',
      zero: '0 agentů',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'Identita';

  @override
  String get uploadImage => 'Nahrát obrázek';

  @override
  String get failedToSaveLogo =>
      'Obrázek loga se nepodařilo uložit. Ověřte, že aplikace může vybraný soubor číst.';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG nebo GIF do 2 MB. Jinak použijeme iniciálu pracovního prostoru.';

  @override
  String get workspaceNameFieldHelp =>
      'Zobrazuje se v přepínači, drobečkové navigaci a na každé obrazovce.';

  @override
  String get dangerZone => 'Nebezpečná zóna';

  @override
  String get deleteThisWorkspace => 'Smazat tento pracovní prostor';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return 'Trvale odstraní $name, jeho připojení k repozitářům, agenty a paměť. Tuto akci nelze vrátit zpět.';
  }

  @override
  String get discard => 'Zahodit';

  @override
  String discardChangesQuestion(String name) {
    return 'Zahodit neuložené změny v $name?';
  }

  @override
  String get workspaceUpdated => 'Pracovní prostor aktualizován';

  @override
  String get editTitle => 'Upravit název';

  @override
  String get editDescription => 'Upravit popis';

  @override
  String get addDescription => 'Přidat popis';

  @override
  String get prTitlePlaceholder => 'Název';

  @override
  String get prBodyPlaceholder => 'Napište popis';

  @override
  String get write => 'Psát';

  @override
  String get overview => 'Přehled';

  @override
  String get noFilesChanged => 'Žádné změněné soubory';

  @override
  String get diff => 'Diff';

  @override
  String get preview => 'Náhled';

  @override
  String get imageDiffBefore => 'Předtím';

  @override
  String get imageDiffAfter => 'Potom';

  @override
  String get imageDiffModeTwoUp => 'Vedle sebe';

  @override
  String get imageDiffModeSwipe => 'Potáhnout';

  @override
  String get imageDiffModeDifference => 'Rozdíl';

  @override
  String imageDiffChangedPercent(String percent) {
    return 'Změněno $percent %';
  }

  @override
  String get imageDiffPictures => 'Obrázky';

  @override
  String get imageDiffSource => 'Zdroj';

  @override
  String get imageDiffDeleted => 'Odstraněno';

  @override
  String get imageDiffAdded => 'Přidáno';

  @override
  String imageDiffDimensions(int width, int height) {
    return 'Š: ${width}px | V: ${height}px';
  }

  @override
  String get outdated => 'Zastaralé';

  @override
  String get outdatedComments => 'Zastaralé komentáře';

  @override
  String outdatedCountLabel(int count) {
    return '$count zastaralých';
  }

  @override
  String get prTemplateLabel => 'Šablona';

  @override
  String get prTemplateDefault => 'Výchozí';

  @override
  String get addReviewers => 'Přidat recenzenty';

  @override
  String get addAssignees => 'Přidat přiřazené';

  @override
  String get searchUsers => 'Hledat lidi…';

  @override
  String get searchReviewers => 'Hledat lidi a týmy…';

  @override
  String get usersSectionLabel => 'Lidé';

  @override
  String get userStatusBusy => 'Zaneprázdněn';

  @override
  String get teamsSectionLabel => 'Týmy';

  @override
  String get suggestedReviewers => 'Navrhovaní recenzenti';

  @override
  String get noMatchingUsers => 'Žádní odpovídající lidé';

  @override
  String get noMatchingReviewers => 'Žádné shody';

  @override
  String get requiredByCodeOwners => 'Vyžadováno code owners';

  @override
  String reviewedOnBehalfOf(String login) {
    return 'přes $login';
  }

  @override
  String get team => 'Tým';

  @override
  String get markdownBold => 'Tučné';

  @override
  String get markdownItalic => 'Kurzíva';

  @override
  String get markdownHeading => 'Nadpis';

  @override
  String get markdownBulletList => 'Odrážkový seznam';

  @override
  String get markdownChecklist => 'Checklist';

  @override
  String get markdownCode => 'Kód';

  @override
  String get markdownLink => 'Odkaz';

  @override
  String get markdownQuote => 'Citace';

  @override
  String get markdownSupported => 'Markdown je podporován';

  @override
  String get markdownAttachImages => 'Klikněte pro přidání obrázků';

  @override
  String failedToUpdateTitle(String error) {
    return 'Název se nepodařilo aktualizovat: $error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'Popis se nepodařilo aktualizovat: $error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'Recenzenty se nepodařilo aktualizovat: $error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'Přiřazené se nepodařilo aktualizovat: $error';
  }

  @override
  String get discardChangesConfirm => 'Zahodit změny?';

  @override
  String get newPr => 'Nový PR';

  @override
  String get openPullRequest => 'Otevřít pull request';

  @override
  String get composePrSubtitle =>
      'Z větve, kterou jste odeslali — bez agentů a ticketů';

  @override
  String get createAsDraft => 'Vytvořit jako koncept';

  @override
  String get composePrNoRepo => 'Není vybrán GitHub repozitář';

  @override
  String get composePrNoRepoHint =>
      'Vyberte pracovní prostor s GitHub-propojeným repozitářem a otevřete pull request.';

  @override
  String get composePrPickBranches =>
      'Vyberte základní a porovnávanou větev pro náhled změn.';

  @override
  String get composePrNothingToCompare =>
      'Mezi těmito větvemi nejsou žádné změny.';

  @override
  String get repository => 'Repozitář';

  @override
  String get baseBranchLabel => 'Základ';

  @override
  String get compareBranchLabel => 'Porovnat';

  @override
  String get selectBranch => 'Vyberte větev';

  @override
  String get navMeetings => 'Schůzky';

  @override
  String get meetingsNoWorkspace =>
      'Vyberte pracovní prostor pro zobrazení schůzek.';

  @override
  String get meetingsEmpty => 'Zatím žádné schůzky';

  @override
  String get meetingsEmptyHint =>
      'Nahrajte první schůzku — zvuk zůstane na tomto zařízení a agent z něj udělá poznámky, rozhodnutí a akční položky.';

  @override
  String get meetingNotesHint =>
      'Pište rychlé poznámky — agent je po schůzce rozvede.';

  @override
  String get meetingSpeakerMe => 'Vy';

  @override
  String get meetingStatusRecording => 'Nahrávání';

  @override
  String get meetingStatusProcessing => 'Zpracování';

  @override
  String get meetingStatusDone => 'Hotovo';

  @override
  String get meetingStatusFailed => 'Selhalo';

  @override
  String get meetingsSubtitle =>
      'Zachyceno a přepsáno na tomto zařízení, pak shrnuto agentem.';

  @override
  String get meetingsRecordMeeting => 'Nahrát schůzku';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count se právě zpracovává',
      many: '$count se právě zpracovává',
      few: '$count se právě zpracovávají',
      one: '1 se právě zpracovává',
    );
    return '$_temp0';
  }

  @override
  String meetingsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count schůzek',
      many: '$count schůzek',
      few: '$count schůzky',
      one: '1 schůzka',
      zero: 'Žádné schůzky',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLedgerOpenActions => 'Otevřené akce';

  @override
  String get meetingsLedgerDecisions => 'Rozhodnutí';

  @override
  String get meetingsLiveOpen => 'Otevřít nahrávání';

  @override
  String get meetingTemplateShort => 'Šablona';

  @override
  String get meetingsStatThisWeek => 'Tento týden';

  @override
  String get meetingsStatRecorded => 'Nahráno';

  @override
  String get meetingsFilterAll => 'Vše';

  @override
  String get meetingsFilterDone => 'Hotovo';

  @override
  String get meetingsFilterProcessing => 'Zpracování';

  @override
  String get meetingsSearchHint => 'Filtrovat podle názvu, osoby, aplikace…';

  @override
  String get meetingsBucketToday => 'Dnes';

  @override
  String get meetingsBucketYesterday => 'Včera';

  @override
  String get meetingsBucketEarlierThisWeek => 'Dříve tento týden';

  @override
  String get meetingsBucketLastWeek => 'Minulý týden';

  @override
  String get meetingsBucketOlder => 'Starší';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rozhodnutí',
      many: '$count rozhodnutí',
      few: '$count rozhodnutí',
      one: '1 rozhodnutí',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total akčních položek';
  }

  @override
  String get meetingsEnhancedPill => 'vylepšeno';

  @override
  String get meetingsTranscribing => 'přepis a shrnutí…';

  @override
  String get meetingsOpenAction => 'Otevřít';

  @override
  String get meetingsStopProcessing => 'Zastavit';

  @override
  String get meetingsStillTranscribing =>
      'Stále se přepisuje — shrnutí se objeví po dokončení.';

  @override
  String get meetingsNoMatch => 'Žádné schůzky neodpovídají';

  @override
  String get meetingsNoMatchHint => 'Zkuste jiný filtr nebo hledaný výraz.';

  @override
  String get meetingBackAllMeetings => 'Všechny schůzky';

  @override
  String get meetingReRunSummary => 'Znovu spustit shrnutí';

  @override
  String get meetingExport => 'Exportovat';

  @override
  String get meetingAugmentingBanner =>
      'Doplňování poznámek z přepisu — extrahování rozhodnutí a akčních položek…';

  @override
  String get meetingTabNotes => 'Poznámky';

  @override
  String get meetingTabTranscript => 'Přepis';

  @override
  String get meetingTabActionItems => 'Akční položky';

  @override
  String get meetingTabDecisions => 'Rozhodnutí';

  @override
  String get meetingNotesEnhancedToggle => 'Vylepšené';

  @override
  String get meetingNotesYoursToggle => 'Vaše poznámky';

  @override
  String get meetingEnhancedByAgent => 'Vylepšeno agentem · z přepisu';

  @override
  String get meetingEnhancedPending => 'Agent na tomto shrnutí ještě pracuje.';

  @override
  String get meetingNotesEmpty => 'Zatím žádné vylepšené poznámky.';

  @override
  String get meetingNotesSavedLocally => 'Uloženo lokálně';

  @override
  String get meetingNotesSaving => 'Ukládání…';

  @override
  String get meetingViewFullTranscript => 'Zobrazit celý přepis';

  @override
  String get meetingTranscriptSearchHint => 'Hledat v přepisu…';

  @override
  String get meetingSpeakerEveryone => 'Všichni';

  @override
  String get meetingSpeakerOthers => 'Ostatní';

  @override
  String get meetingTranscriptEmpty => 'Zatím žádný přepis.';

  @override
  String get meetingActionItemsEmpty =>
      'Žádné akční položky nebyly extrahovány.';

  @override
  String get meetingActionItemFrom => 'z této schůzky';

  @override
  String get meetingCreateTicket => 'Vytvořit ticket';

  @override
  String meetingTicketCreated(String key) {
    return 'Ticket $key vytvořen a odeslán.';
  }

  @override
  String get meetingTicketFailed => 'Ticket se nepodařilo vytvořit.';

  @override
  String get meetingDecisionsEmpty => 'Žádná rozhodnutí nejsou zaznamenána.';

  @override
  String get meetingEditTitle => 'Upravit název';

  @override
  String get meetingTitleLabel => 'Název';

  @override
  String get meetingAddActionItem => 'Přidat akční položku';

  @override
  String get meetingEditActionItem => 'Upravit akční položku';

  @override
  String get meetingDeleteActionItem => 'Smazat akční položku';

  @override
  String get meetingActionItemContentLabel => 'Akční položka';

  @override
  String get meetingActionItemContentHint => 'Co se má stát?';

  @override
  String get meetingActionItemOwnerLabel => 'Vlastník';

  @override
  String get meetingActionItemOwnerHint => 'Kdo je zodpovědný? (volitelné)';

  @override
  String get meetingAddDecision => 'Přidat rozhodnutí';

  @override
  String get meetingEditDecision => 'Upravit rozhodnutí';

  @override
  String get meetingDeleteDecision => 'Smazat rozhodnutí';

  @override
  String get meetingDecisionContentLabel => 'Rozhodnutí';

  @override
  String get meetingDecisionContentHint => 'Co bylo rozhodnuto?';

  @override
  String get meetingReRunStarted => 'Znovu se spouští shrnovač na přepisu…';

  @override
  String get meetingReRunNoTranscript => 'Zatím není žádný přepis ke shrnutí.';

  @override
  String get meetingExportCopied =>
      'Poznámky zkopírovány do schránky jako Markdown.';

  @override
  String get meetingExportSaved => 'Schůzka exportována.';

  @override
  String meetingExportFailed(String error) {
    return 'Export selhal: $error';
  }

  @override
  String get meetingExportNothing => 'Zatím není co exportovat.';

  @override
  String get meetingPlaybackPlay => 'Přehrát';

  @override
  String get meetingPlaybackPause => 'Pozastavit';

  @override
  String get meetingPlaybackUnavailable =>
      'Přehrávání zvuku na tomto zařízení není k dispozici.';

  @override
  String get meetingDetectedTitle => 'Zjištěna schůzka';

  @override
  String meetingDetectedSubtitle(String label) {
    return 'Vypadá to, že probíhá „$label“. Nahrát?';
  }

  @override
  String get meetingDetectedSubtitleGeneric =>
      'Vypadá to, že probíhá schůzka. Nahrát?';

  @override
  String get meetingDetectedRecord => 'Nahrát';

  @override
  String get meetingDetectedDismiss => 'Zavřít';

  @override
  String get meetingAutoStopTitle =>
      'Tato schůzka vypadá, že skončila. Zastavit nahrávání?';

  @override
  String get meetingAutoStopStop => 'Zastavit';

  @override
  String get meetingAutoStopKeep => 'Pokračovat v nahrávání';

  @override
  String get meetingAutoDetect => 'Automaticky zjišťovat schůzky';

  @override
  String get meetingAutoDetectDescription =>
      'Sledovat kalendář a konferenční aplikace a nabídnout nahrávání, když schůzka začne.';

  @override
  String get meetingsRecordingCrumb => 'Nahrávání…';

  @override
  String get meetingRecordTitleHint => 'Název schůzky';

  @override
  String get meetingRecordTappingLabel => 'Snímá se:';

  @override
  String get meetingRecordMic => 'Mikrofon';

  @override
  String get meetingRecordSystemAudio => 'Systémový zvuk';

  @override
  String get meetingRecordPause => 'Pozastavit';

  @override
  String get meetingRecordResume => 'Pokračovat';

  @override
  String get meetingRecordStop => 'Zastavit a shrnout';

  @override
  String get meetingRecordYourNotes => 'Vaše poznámky';

  @override
  String get meetingRecordNotesPlaceholder =>
      'Pište, zatímco posloucháte. Stačí pár útržků — po zastavení je agent rozvede podle přepisu.';

  @override
  String get meetingRecordLiveTranscript => 'Živý přepis';

  @override
  String get meetingRecordDecoding => 'dekódování na zařízení';

  @override
  String get meetingRecordListening =>
      'Poslouchám… řeč se tu objeví během vteřiny nebo dvou, označená Vy / Ostatní.';

  @override
  String get meetingRecordPausedHint =>
      'Pozastaveno — zvuk se ignoruje, dokud nebudete pokračovat.';

  @override
  String get meetingRecordNotActive => 'Žádné aktivní nahrávání.';

  @override
  String get meetingHudRecording => 'nahrávání';

  @override
  String get meetingHudPaused => 'pozastaveno';

  @override
  String get meetingHudOpen => 'Otevřít';

  @override
  String get meetingHudStop => 'Zastavit';

  @override
  String get meetingToolbarPopOut => 'Vysunout';

  @override
  String get meetingToolbarHoldToStop => 'Podržte pro zastavení nahrávání';

  @override
  String get meetingToolbarSemanticLabel => 'Lišta nahrávání schůzky';

  @override
  String get orchestrate => 'Orchestrace';

  @override
  String get orchestrationUnavailable => 'Orchestrace není k dispozici';

  @override
  String get orchestrationApprove => 'Schválit plán';

  @override
  String get orchestrationReject => 'Odmítnout';

  @override
  String get orchestrationCancel => 'Zrušit orchestraci';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count rolí — $hires nových náborů';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count podticketů';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'Odhadované náklady: \$$amount';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total podticketů hotovo';
  }

  @override
  String get orchestrationStatusProposed => 'Navrženo';

  @override
  String get orchestrationStatusApproved => 'Schváleno';

  @override
  String get orchestrationStatusExecuting => 'Provádění';

  @override
  String get orchestrationStatusSynthesizing => 'Syntéza';

  @override
  String get orchestrationStatusCompleted => 'Dokončeno';

  @override
  String get orchestrationStatusFailed => 'Selhalo';

  @override
  String get orchestrationStatusCancelled => 'Zrušeno';

  @override
  String get messageFailed => 'Běh selhal';

  @override
  String get turnLimitReached =>
      'Zastaveno na limitu tahů — odpovězte a pokračujte';

  @override
  String get retried => 'Zopakováno';

  @override
  String replyingTo(String name) {
    return 'odpovídá $name';
  }

  @override
  String get silenceTimeoutLabel => 'Časový limit ticha (minuty)';

  @override
  String get silenceTimeoutHint =>
      'např. 15 — ukončit běh po této době bez výstupu';

  @override
  String get capabilityJsonMode => 'Režim JSON';

  @override
  String get capabilityModelSelection => 'Výběr modelu';

  @override
  String get transcriptThinking => 'Přemýšlí…';

  @override
  String transcriptThoughtFor(String duration) {
    return 'Přemýšlel $duration';
  }

  @override
  String get transcriptStatusMakingEdits => 'Provádění úprav…';

  @override
  String get transcriptStatusReadingFiles => 'Čtení souborů…';

  @override
  String get transcriptStatusSearching => 'Prohledávání kódu…';

  @override
  String get transcriptStatusRunningCommands => 'Spouštění příkazů…';

  @override
  String get transcriptStatusResponding => 'Odpovídání…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return 'Spouštění $tool…';
  }

  @override
  String get transcriptInput => 'Vstup';

  @override
  String get transcriptOutput => 'Výstup';

  @override
  String get transcriptErrorLabel => 'Chyba';

  @override
  String get transcriptSandboxBlocked => 'Sandbox zablokoval akci';

  @override
  String transcriptShowFullOutput(int kb) {
    return 'Zobrazit celý výstup (+$kb KB)';
  }

  @override
  String transcriptShowAllLines(int count) {
    return 'Zobrazit všech $count řádků';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return 'Zobrazeno prvních $count řádků';
  }

  @override
  String get transcriptGrepNoMatches => 'Žádné shody';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '$matches shod',
      many: '$matches shod',
      few: '$matches shody',
      one: '1 shoda',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files souborů',
      many: '$files souborů',
      few: '$files soubory',
      one: '1 soubor',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return 'Osoba $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => 'Přejmenovat řečníka';

  @override
  String get meetingRenameSpeakerTitle => 'Přejmenovat řečníka';

  @override
  String get meetingSpeakerNameLabel => 'Jméno';

  @override
  String get meetingSpeakerSuggestFromCalendar => 'Z pozvaných této schůzky';

  @override
  String get meetingRenameSpeakerApplyAll =>
      'Použít na všechny bloky tohoto řečníka';

  @override
  String get meetingRenameSpeakerScopeHint =>
      'Když je vypnuto, přejmenuje se jen vybraný řádek.';

  @override
  String get meetingLinkEvent => 'Propojit s událostí';

  @override
  String get meetingChangeEvent => 'Změnit událost';

  @override
  String get meetingLinkEventTitle => 'Propojit s událostí kalendáře';

  @override
  String get meetingLinkEventSearchHint => 'Hledat události';

  @override
  String get meetingLinkEventEmpty => 'Žádné blízké události kalendáře';

  @override
  String get meetingUnlinkEvent => 'Odebrat odkaz';

  @override
  String get calendarLinkExistingMeeting => 'Propojit s existující schůzkou';

  @override
  String get calendarLinkMeetingTitle => 'Propojit schůzku';

  @override
  String get calendarLinkMeetingSearchHint => 'Hledat schůzky';

  @override
  String get calendarLinkMeetingEmpty => 'Žádné schůzky k propojení';

  @override
  String get meetingRenameSpeakerFailed => 'Řečníka se nepodařilo přejmenovat';

  @override
  String get calendarLinkUpdateFailed =>
      'Odkaz kalendáře se nepodařilo aktualizovat';

  @override
  String get rename => 'Přejmenovat';

  @override
  String get notNow => 'Teď ne';

  @override
  String get meetingSaveVoiceProfileTitle => 'Uložit hlasový profil?';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return 'Rozpoznávat $name automaticky na budoucích schůzkách uložením hlasového otisku.';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return 'Hlasový profil pro $name uložen';
  }

  @override
  String get meetingVoiceProfileSaveFailed =>
      'Hlasový profil se nepodařilo uložit';

  @override
  String get voiceProfilesSection => 'Hlasové profily';

  @override
  String get voiceProfilesDescription =>
      'Uložené hlasy se na budoucích schůzkách rozpoznají automaticky.';

  @override
  String get voiceProfilesEmpty =>
      'Zatím žádné uložené hlasy. Pojmenujte řečníka v přepisu schůzky a zvolte „Uložit hlasový profil“.';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vzorků',
      many: '$count vzorků',
      few: '$count vzorky',
      one: '1 vzorek',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => 'Přejmenovat hlasový profil';

  @override
  String get deleteVoiceProfileTitle => 'Smazat hlasový profil?';

  @override
  String deleteVoiceProfileBody(String name) {
    return 'Přestat rozpoznávat $name? Uložený hlasový otisk se odebere. Jména už použitá v minulých schůzkách zůstanou.';
  }

  @override
  String get connectedLabel => 'Připojeno';

  @override
  String get ideTabGeneral => 'Obecné';

  @override
  String get ideTabExplorer => 'Průzkumník';

  @override
  String get ideTabSourceControl => 'Správa zdrojového kódu';

  @override
  String get generalSectionTodos => 'Úkoly';

  @override
  String get generalSectionGoals => 'Cíle';

  @override
  String get goalRunStatusActive => 'Aktivní';

  @override
  String get goalRunStatusPaused => 'Pozastaveno';

  @override
  String get goalRunStatusCompleted => 'Dokončeno';

  @override
  String get goalRunStatusFailed => 'Selhalo';

  @override
  String get goalRunStatusCancelled => 'Zrušeno';

  @override
  String get goalRunStatusBudgetExhausted => 'Rozpočet vyčerpán';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return 'Běh $run z $max · $cost z $cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return 'Běh $run · $cost z $cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return 'Termín $deadline';
  }

  @override
  String get goalRunPause => 'Pozastavit cíl';

  @override
  String get goalRunResume => 'Obnovit cíl';

  @override
  String goalRunResumeRaise(String cap) {
    return 'Obnovit · zvýšit strop na $cap';
  }

  @override
  String get goalRunStop => 'Zastavit cíl';

  @override
  String get generalSectionAgents => 'Agenti';

  @override
  String get generalSectionTerminals => 'Terminály';

  @override
  String get generalTodosEmpty => 'Zatím žádné úkoly';

  @override
  String get generalAgentsEmpty => 'Žádní agenti neběží';

  @override
  String get generalTerminalsEmpty => 'Žádné otevřené terminály';

  @override
  String get generalSectionBrowsers => 'Prohlížeče';

  @override
  String get generalSectionComputers => 'Počítače';

  @override
  String get generalBrowsersEmpty => 'Žádné otevřené prohlížeče';

  @override
  String get generalComputersEmpty => 'Žádné otevřené počítače';

  @override
  String get generalSectionPhones => 'Telefony';

  @override
  String get generalPhonesEmpty => 'Žádné otevřené telefony';

  @override
  String get pauseAgent => 'Pozastavit agenta';

  @override
  String get resumeAgent => 'Obnovit agenta';

  @override
  String get agentCannotPause =>
      'Tento agent nejde pozastavit — místo toho ho zastavte.';

  @override
  String get goalClear => 'Vymazat cíl';

  @override
  String get undoLabelGoalClear => 'vymazat cíl';

  @override
  String get todoStatusPending => 'Nezahájeno';

  @override
  String get todoStatusInProgress => 'Probíhá';

  @override
  String get todoStatusCompleted => 'Hotovo';

  @override
  String get reorderTodo => 'Změnit pořadí úkolu';

  @override
  String get focusTerminal => 'Zaměřit terminál';

  @override
  String get focusMachine => 'Zaměřit stroj';

  @override
  String get focusBrowser => 'Zaměřit prohlížeč';

  @override
  String get todoEditorTitle => 'Upravit úkoly';

  @override
  String get todoEditorHint =>
      'Jedna položka na řádek. Použijte - [ ] pro čekající, - [~] pro probíhající, - [x] pro hotové.';

  @override
  String get todoNeedsText => 'Za příkaz přidejte text';

  @override
  String get todoNotFound => 'Žádný odpovídající úkol';

  @override
  String get todoCleared => 'Seznam úkolů vymazán';

  @override
  String get todoNothingToCopy => 'Není co kopírovat';

  @override
  String todoAdded(String content) {
    return 'Přidáno „$content“';
  }

  @override
  String todoStarted(String content) {
    return 'Zahájeno „$content“';
  }

  @override
  String todoCompleted(String content) {
    return 'Dokončeno „$content“';
  }

  @override
  String todoRemoved(String content) {
    return 'Odebráno „$content“';
  }

  @override
  String todoCopied(int count) {
    return 'Zkopírováno $count položek';
  }

  @override
  String todoImported(int count) {
    return 'Importováno $count položek';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return 'Neznámý příkaz úkolu „$name“';
  }

  @override
  String get terminal => 'Terminál';

  @override
  String get ideCloseTab => 'Zavřít kartu';

  @override
  String get ideSplitEditor => 'Rozdělit editor';

  @override
  String get ideSplitRight => 'Rozdělit vpravo';

  @override
  String get ideSplitDown => 'Rozdělit dolů';

  @override
  String get ideSplitLeft => 'Rozdělit vlevo';

  @override
  String get ideSplitUp => 'Rozdělit nahoru';

  @override
  String get ideCloseGroup => 'Zavřít skupinu';

  @override
  String get ideCloseOthers => 'Zavřít ostatní';

  @override
  String get ideCloseToRight => 'Zavřít vpravo';

  @override
  String get ideCloseSaved => 'Zavřít uložené';

  @override
  String get ideCloseAll => 'Zavřít vše';

  @override
  String get ideSplit => 'Rozdělit';

  @override
  String get ideToggleSidebar => 'Přepnout postranní panel';

  @override
  String get ideNewTab => 'Otevřít editor';

  @override
  String get ideNewTabMenu => 'Nová karta';

  @override
  String get ideReviewCode => 'Zkontrolovat kód';

  @override
  String get ideRevertConfirmTitle => 'Vrátit změny';

  @override
  String get ideRevertUntracked => 'Nesledované soubory nelze vrátit';

  @override
  String get ideRevertFailed =>
      'Soubory se nepodařilo vrátit. Worktree konverzace může být nedostupný.';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count souborů',
      many: '$count souborů',
      few: '$count soubory',
      one: '1 soubor',
    );
    return '$_temp0 se nepodařilo vrátit (nesledované).';
  }

  @override
  String get ideSearchMatchCase => 'Rozlišovat velikost';

  @override
  String get ideSearchWholeWord => 'Celé slovo';

  @override
  String get ideSearchRegex => 'Regex';

  @override
  String get ideSearchFilters => 'Filtry hledání';

  @override
  String get ideSearchFilesToInclude => 'Soubory k zahrnutí';

  @override
  String get ideSearchFilesToExclude => 'Soubory k vyloučení';

  @override
  String get ideNoOpenTabs => 'Žádné otevřené karty — použijte + k otevření';

  @override
  String get ideBrowserAddressHint => 'Zadejte adresu nebo hledejte';

  @override
  String get ideSimpleWebBrowser => 'Jednoduchý webový prohlížeč';

  @override
  String get ideWebBrowser => 'Webový prohlížeč';

  @override
  String get ideBrowserEnterUrl =>
      'Zadejte URL do adresního řádku a začněte procházet';

  @override
  String get ideCodeServer => 'Editor';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return 'Uložit změny v $fileName?';
  }

  @override
  String get ideUnsavedChangesBody => 'Změny se ztratí, pokud je neuložíte.';

  @override
  String get ideDontSave => 'Neukládat';

  @override
  String get editorAutoSave => 'Automatické ukládání';

  @override
  String get editorAutoSaveDescription =>
      'Automaticky ukládat změny ve vestavěném editoru.';

  @override
  String get editorAutoSaveOff => 'Vypnuto';

  @override
  String get editorAutoSaveAfterDelay => 'Po prodlevě';

  @override
  String get editorAutoSaveOnFocusChange => 'Při změně fokusu';

  @override
  String get ideCodeServerUnavailable =>
      'Code-server na tomto serveru není k dispozici';

  @override
  String get ideCodeServerUnavailableHint =>
      'Nainstalujte code-server (coder/code-server) na hostitele serveru a editor znovu otevřete.';

  @override
  String get ideCodeServerInstalling => 'Příprava editoru…';

  @override
  String get ideCodeServerOpenInBrowser => 'Otevřít editor v prohlížeči';

  @override
  String get ideCodeServerError => 'Editor se nepodařilo otevřít';

  @override
  String get paneSuspendedCaption =>
      'Pozastaveno kvůli úspoře zdrojů — znovu se načte po zaměření';

  @override
  String get ideFolderLoadFailed => 'Tuto složku se nepodařilo načíst';

  @override
  String get ideFileSearchFailed => 'Soubory se nepodařilo vyhledat';

  @override
  String get ideSearchInFiles => 'Hledat v souborech';

  @override
  String get ideNoContentMatches => 'Žádné shody';

  @override
  String get ideSourceControlCreatePr => 'Vytvořit pull request';

  @override
  String ideSourceControlViewPr(int number) {
    return 'Zobrazit pull request #$number';
  }

  @override
  String get ideSourceControlNoChanges => 'Žádné změny';

  @override
  String get noReposInConversation =>
      'V této konverzaci nejsou žádné repozitáře';

  @override
  String get ideSourceControlNoSpace =>
      'Otevřete konverzaci a uvidíte její změny';

  @override
  String get ideFileLoading => 'Načítání…';

  @override
  String get ideFileBinary => 'Binární soubor';

  @override
  String get mcpExternalServers => 'Externí servery MCP';

  @override
  String get mcpExternalServersDescription =>
      'Připojte se k externím serverům MCP (GitHub, Sentry, Postgres, automatizace prohlížeče). Servery nastavené pro Claude, Cursor, VS Code a další nástroje se zjistí automaticky.';

  @override
  String get mcpApprovalMode => 'Schvalování nástrojů';

  @override
  String get mcpApprovalModeDescription =>
      'Které akce nástrojů běží bez ptaní. Čtení je vždy povoleno; vyšší úrovně se zeptají.';

  @override
  String get mcpApprovalAlwaysAsk => 'Vždy se zeptat';

  @override
  String get mcpApprovalWrite => 'Automaticky schvalovat zápisy';

  @override
  String get mcpApprovalYolo => 'Automaticky schvalovat vše';

  @override
  String get mcpNoExternalServers =>
      'Nebyly zjištěny žádné externí servery MCP.';

  @override
  String get mcpAuthorize => 'Autorizovat';

  @override
  String get mcpReconnect => 'Znovu připojit';

  @override
  String get mcpExternalConnectionsNote =>
      'Externí servery MCP běží na serveru agenta (sdílené desktopem i webem). Autorizace OAuth serverů je jen na desktopu.';

  @override
  String get mcpStatusConnected => 'Připojeno';

  @override
  String get mcpStatusConnecting => 'Připojování…';

  @override
  String get mcpStatusNeedsAuth => 'Vyžaduje autorizaci';

  @override
  String get mcpStatusFailed => 'Selhalo';

  @override
  String get mcpStatusCircuitOpen => 'Pozastaveno';

  @override
  String get mcpStatusDisabled => 'Vypnuto';

  @override
  String get providersAndModels => 'Poskytovatelé a modely';

  @override
  String get providersAndModelsDescription =>
      'Seznam všech poskytovatelů, které vestavěný agent může použít — nastavte API klíč nebo se přihlaste v prohlížeči, prohlédněte modely a ceny každého připojeného poskytovatele a určete, které poskytovatele tento pracovní prostor smí používat.';

  @override
  String get syncNow => 'Synchronizovat teď';

  @override
  String syncNowResult(int applied, int failed) {
    return 'Synchronizace dokončena — $applied použito, $failed selhalo';
  }

  @override
  String syncNowFailed(String error) {
    return 'Synchronizace selhala: $error';
  }

  @override
  String get denied => 'Zakázáno';

  @override
  String get allowed => 'Povoleno';

  @override
  String allowProviderSemantic(String provider) {
    return 'Povolit $provider';
  }

  @override
  String enabledViaEnv(String key) {
    return 'Zapnuto přes $key';
  }

  @override
  String costPerMillion(String input, String output) {
    return '$input / $output za 1M';
  }

  @override
  String contextTokens(String tokens) {
    return '$tokens kontextu';
  }

  @override
  String get usageAndCost => 'Využití a náklady';

  @override
  String get usageAndCostDescription =>
      'Výdaje agentů za posledních 7 dní z pozorovaných nákladů běhů.';

  @override
  String get noUsageYet => 'Zatím není zaznamenáno žádné využití.';

  @override
  String get spentThisWeek => 'utraceno tento týden';

  @override
  String get subscriptionUsage => 'Využití předplatného';

  @override
  String get subscriptionUsageUnavailable => 'Nedostupné';

  @override
  String get subscriptionUsageExhausted => 'Kvóta vyčerpána';

  @override
  String get subscriptionUsageSignInRequired => 'Přihlaste se znovu';

  @override
  String get subscriptionUsageSignInExpired =>
      'Přihlášení vypršelo, obnoví se při dalším běhu';

  @override
  String get subscriptionUsagePartiallyAvailable => 'Částečně dostupné';

  @override
  String resetsIn(String duration) {
    return 'Obnoví se za $duration';
  }

  @override
  String get feedbackHelpful => 'Bylo to užitečné';

  @override
  String get feedbackNotHelpful => 'Nebylo to užitečné';

  @override
  String get modeChat => 'Chat';

  @override
  String get modePlan => 'Plán';

  @override
  String get modeReview => 'Kontrola';

  @override
  String get modeOrchestrate => 'Orchestrace';

  @override
  String get editorTheme => 'Motiv editoru';

  @override
  String get editorThemeDescription =>
      'Importujte barevný motiv VS Code, aby vestavěný diff a editor odpovídaly vašemu IDE.';

  @override
  String get editorThemePasteHint =>
      'Vložte obsah JSON souboru barevného motivu VS Code';

  @override
  String get editorThemeImported => 'Motiv importován';

  @override
  String get editorThemeInvalid => 'To nevypadá jako platný motiv VS Code';

  @override
  String get importTheme => 'Importovat motiv';

  @override
  String get clearTheme => 'Vymazat motiv';

  @override
  String get openInDiffViewer => 'Otevřít v prohlížeči diffu';

  @override
  String get shellCommand => 'Příkaz';

  @override
  String get shellOutput => 'Výstup';

  @override
  String get revertToHere => 'Vrátit sem';

  @override
  String get revertConfirmBody =>
      'Skrýt zprávy po tomto bodu a vrátit změny souborů agenta k tomuto tahu? Tuto akci lze vrátit zpět.';

  @override
  String get revert => 'Vrátit';

  @override
  String get revertedToHere => 'Vráceno sem';

  @override
  String get nothingToRevert => 'Není co vrátit';

  @override
  String get undoRevert => 'Vrátit zpět vrácení';

  @override
  String get revertUndone => 'Vrácení zrušeno';

  @override
  String get systemBehavior => 'Chování systému';

  @override
  String get keepAwakeTitle => 'Nenechat počítač usnout, dokud agenti běží';

  @override
  String get keepAwakeOnSubtitle => 'Počítač neusne, dokud agent pracuje';

  @override
  String get keepAwakeOffSubtitle =>
      'Počítač může usnout i tehdy, když agent pracuje';

  @override
  String get syncEngineSectionTitle => 'Synchronizační engine';

  @override
  String get syncEngineDescription =>
      'Tickety, zprávy a poznámky se aktualizují živě malými přírůstkovými změnami místo celých snímků. Vypnutím přepínače se toto úložiště vrátí k režimu celých snímků — aby se změna projevila, znovu načtěte aplikaci.';

  @override
  String get syncEngineTicketsTitle => 'Tickety';

  @override
  String get syncEngineMessagingTitle => 'Zprávy';

  @override
  String get syncEngineNotesTitle => 'Poznámky';

  @override
  String get syncEngineOnSubtitle => 'Živá delta synchronizace je aktivní';

  @override
  String get syncEngineOffSubtitle => 'Používá se synchronizace celých snímků';

  @override
  String get spaces => 'Prostory';

  @override
  String get spacesHomeDescription =>
      'Vyberte prostor ze seznamu, nebo začněte nový.';

  @override
  String get noSpacesYet => 'Zatím žádné prostory';

  @override
  String get newSpace => 'Nový prostor';

  @override
  String get spaceName => 'Název prostoru';

  @override
  String get spaceReposHint => 'Repozitáře k zahrnutí';

  @override
  String get ideSourceControl => 'Správa zdrojového kódu';

  @override
  String get stagedChanges => 'Zařazené změny';

  @override
  String get changes => 'Změny';

  @override
  String get stageFile => 'Zařadit';

  @override
  String get unstageFile => 'Odebrat ze stage';

  @override
  String get stageAll => 'Zařadit všechny změny';

  @override
  String get unstageAll => 'Odebrat vše ze stage';

  @override
  String get stageChangesToCommit => 'Zařadit změny k commitu';

  @override
  String get syncToPrHead => 'Stáhnout nejnovější commity PR';

  @override
  String get syncedToPrHead => 'Synchronizováno s nejnovějšími commity PR';

  @override
  String get syncPrHeadDirty =>
      'Před synchronizací commitněte nebo zahoďte změny';

  @override
  String get syncPrHeadFailed => 'Synchronizace s head PR se nezdařila';

  @override
  String get spaceLabel => 'Prostor';

  @override
  String get keybindingNewSpace => 'Nový prostor';

  @override
  String get keybindingCreateANewSpaceDescription => 'Vytvořit nový prostor';

  @override
  String get jumpToLatest => 'Přejít na nejnovější';

  @override
  String get streaming => 'Streamování';

  @override
  String get newMessages => 'Nové';

  @override
  String get copyLink => 'Kopírovat odkaz';

  @override
  String get linkCopied => 'Odkaz zkopírován';

  @override
  String get agentResponding => 'Agent odpovídá';

  @override
  String get agentFinished => 'Agent dokončil';

  @override
  String get harnessConnectProviderForModels =>
      'Připojte poskytovatele a uvidíte modely.';

  @override
  String get providerSignOut => 'Odhlásit se';

  @override
  String get providerWaitingForDeviceCode =>
      'Čeká se, až kód potvrdíte v prohlížeči…';

  @override
  String get providerDeviceCodeHint =>
      'Ověřte, že tento kód odpovídá tomu v prohlížeči, a schvalte.';

  @override
  String get providerPlanUsageLoading => 'Kontrola využití tarifu…';

  @override
  String get providerPlanUsageUnavailable => 'Tento tarif nevykázal využití.';

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return 'Odebrat API klíč $provider?';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return 'Uložený klíč se smaže a už ho nelze zobrazit. Agenti používající modely $provider přestanou pracovat, dokud nevložíte nový.';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return 'Odebrat $provider?';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return '$provider i jeho uložený klíč se smažou. Agenti připnutí na jeho modely přestanou pracovat.';
  }

  @override
  String get providerApiKeyHint => 'Vložte API klíč';

  @override
  String get providerApiKeyStoredHint => 'Vložte další API klíč a přidejte ho';

  @override
  String get providerAddAnotherAccount => 'Přidat další účet';

  @override
  String get providerActiveBadge => 'Aktivní';

  @override
  String get providerOauthAccountFallback => 'Účet OAuth';

  @override
  String get providerApiKeyFallback => 'API klíč';

  @override
  String get providerRemoveCredentialConfirmTitle =>
      'Odebrat tyto přihlašovací údaje?';

  @override
  String get providerSignOutAccountConfirmTitle => 'Odhlásit se z tohoto účtu?';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return 'Agenti používající $provider přepnou na jeho ostatní klíče a účty. Když žádné nezůstanou, zastaví se, dokud jeden nepřidáte.';
  }

  @override
  String get providerBaseUrlHint => 'Základní URL (volitelné)';

  @override
  String get addProvider => 'Přidat poskytovatele';

  @override
  String get noCustomProviders => 'Zatím žádní vlastní poskytovatelé.';

  @override
  String get providerNameLabel => 'Název';

  @override
  String get apiTypeLabel => 'Typ API';

  @override
  String get providerBaseUrlLabel => 'Základní URL';

  @override
  String get providerApiKeyOptionalHint => 'API klíč (volitelné)';

  @override
  String get dialectOpenAiCompatible => 'Kompatibilní s OpenAI';

  @override
  String get dialectAnthropicCompatible => 'Kompatibilní s Anthropic';

  @override
  String get removeProviderTooltip => 'Odebrat poskytovatele';

  @override
  String get providerLogInWithBrowser => 'Přihlásit se prohlížečem';

  @override
  String providerLoginDialogTitle(String provider) {
    return 'Přihlásit se k $provider';
  }

  @override
  String get providerLabel => 'Poskytovatel';

  @override
  String get selectProviderToLogin => 'Vyberte poskytovatele k přihlášení';

  @override
  String providerLoginFailed(String error) {
    return 'Přihlášení selhalo: $error';
  }

  @override
  String get providerWaitingForBrowser => 'Čeká se na autorizaci v prohlížeči…';

  @override
  String get providerPasteCodeHint => 'Nebo vložte kód z prohlížeče';

  @override
  String get providerCompleteLogin => 'Dokončit';

  @override
  String get providerConnectedApiKey => 'Připojeno přes API klíč';

  @override
  String get providerConnectedOauth => 'Připojeno';

  @override
  String providerConnectedAccount(String account) {
    return 'Připojeno · $account';
  }

  @override
  String get providerLocalReady => 'Místní · připraveno';

  @override
  String get providerNotConnected => 'Nepřipojeno';

  @override
  String get preparingWorkspace => 'Příprava pracovního prostoru…';

  @override
  String provisioningRunningSetupScript(String repo) {
    return 'Spouštění setup skriptu pro $repo…';
  }

  @override
  String get repoScriptsTitle => 'Skripty';

  @override
  String get repoScriptsTooltip => 'Nastavit skripty životního cyklu';

  @override
  String get repoScriptsSetupLabel => 'Setup skript';

  @override
  String get repoScriptsSetupHelp =>
      'Běží ve worktree prostoru hned po vytvoření — nainstaluje závislosti, vygeneruje soubory. Selhání označí prostor jako selhaný; opakování ho spustí znovu.';

  @override
  String get repoScriptsArchiveLabel => 'Archive skript';

  @override
  String get repoScriptsArchiveHelp =>
      'Běží těsně před smazáním worktree prostoru — uklidí zdroje mimo worktree. Selhání smazání nikdy neblokuje.';

  @override
  String get repoScriptsEnvHelp =>
      'Běží přes bash z worktree s nastavenými CC_WORKSPACE_PATH (worktree), CC_ROOT_PATH (kořen repa), CC_SPACE_ID, CC_SPACE_NAME a CC_REPO_NAME.';

  @override
  String get repoScriptsSetupPlaceholder => 'např. pnpm install';

  @override
  String get repoScriptsArchivePlaceholder =>
      'např. docker compose -p \$CC_SPACE_ID down';

  @override
  String get repoScriptsRecentRuns => 'Nedávné běhy';

  @override
  String get repoScriptsNoRuns => 'Zatím žádné běhy';

  @override
  String get repoScriptsSaved => 'Skripty uloženy';

  @override
  String get repoScriptsRunKindSetup => 'Setup';

  @override
  String get repoScriptsRunKindArchive => 'Archive';

  @override
  String get repoScriptsRunStatusRunning => 'Běží';

  @override
  String get repoScriptsRunStatusSucceeded => 'Úspěšně';

  @override
  String get repoScriptsRunStatusFailed => 'Selhalo';

  @override
  String get repoScriptsRunStatusTimedOut => 'Vypršel čas';

  @override
  String repoScriptsExitCode(int code) {
    return 'Exit kód $code';
  }

  @override
  String provisioningCloningRepo(String repo) {
    return 'Klonování $repo…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return 'Checkout pull requestu v $repo…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return 'Nastavení agenta $agent…';
  }

  @override
  String get workspacePrepFailed => 'Nastavení pracovního prostoru selhalo';

  @override
  String get workspacePrepStopped => 'Nastavení pracovního prostoru zastaveno';

  @override
  String get stopWorkspacePrep => 'Zastavit přípravu';

  @override
  String get stopWorkspacePrepTooltip =>
      'Zastavit přípravu tohoto pracovního prostoru';

  @override
  String get stopWorkspacePrepConfirm =>
      'Zastavit přípravu tohoto pracovního prostoru? Probíhající klon se zahodí — odsud ho můžete spustit znovu.';

  @override
  String messageWillSendWhenReady(int count) {
    return '$count zpráva(y) se odešle, až bude připraveno';
  }

  @override
  String get membersNav => 'Členové';

  @override
  String get membersSettingsDescription =>
      'Lidé s přístupem k tomuto pracovnímu prostoru: seznam, pozvánky a auditní stopa';

  @override
  String get memberRosterLabel => 'Seznam členů';

  @override
  String get memberRepoAccessAction => 'Přístup k repům';

  @override
  String memberRepoAccessTitle(String name) {
    return 'Přístup k repům pro $name';
  }

  @override
  String get roleOwner => 'Vlastník';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleMember => 'Člen';

  @override
  String get roleViewer => 'Prohlížeč';

  @override
  String get roleGuest => 'Host';

  @override
  String get removeMemberTitle => 'Odebrat člena';

  @override
  String removeMemberConfirm(String name) {
    return 'Odebrat $name z tohoto pracovního prostoru? Okamžitě ztratí přístup.';
  }

  @override
  String get transferOwnershipAction => 'Přenést vlastnictví';

  @override
  String get transferOwnershipTitle => 'Přenést vlastnictví';

  @override
  String transferOwnershipConfirm(String name) {
    return 'Udělat z $name vlastníka tohoto pracovního prostoru? Stanete se adminem. Jen vlastník může pracovní prostor smazat nebo změnit roli jiného admina.';
  }

  @override
  String get transferOwnershipCta => 'Přenést';

  @override
  String get auditTrailLabel => 'Auditní stopa autorizací';

  @override
  String get auditTrailDescription =>
      'Každé povolení a odmítnutí, zřetězené hashem, aby šlo odhalit upravený nebo smazaný záznam.';

  @override
  String get auditVerifyChain => 'Ověřit řetěz';

  @override
  String auditChainIntact(int count) {
    return 'Řetěz v pořádku — ověřeno $count záznamů';
  }

  @override
  String auditChainBroken(int seq, String reason) {
    return 'Řetěz přerušen u záznamu $seq: $reason';
  }

  @override
  String get auditEmpty => 'Zatím nejsou zaznamenána žádná rozhodnutí.';

  @override
  String get auditDenied => 'Zakázáno';

  @override
  String get auditAllowed => 'Povoleno';

  @override
  String auditOnBehalfOf(String user) {
    return 'za $user';
  }

  @override
  String get policyTemplatesLabel => 'Šablony politik';

  @override
  String get policyTemplatesDescription =>
      'Použijte výchozí postoj, nebo ho přesuňte mezi pracovními prostory.';

  @override
  String get policyTemplateStrict => 'Přísná';

  @override
  String get policyTemplateBalanced => 'Vyvážená';

  @override
  String get policyTemplatePermissive => 'Permisivní';

  @override
  String get policyTemplateApply => 'Použít';

  @override
  String policyTemplateApplied(int count) {
    return 'Použito $count pravidel';
  }

  @override
  String get policyExport => 'Kopírovat politiku';

  @override
  String get policyExported => 'Politika zkopírována do schránky';

  @override
  String get policyImport => 'Vložit politiku';

  @override
  String policyImported(int count) {
    return 'Importováno $count pravidel';
  }

  @override
  String get approveAndRemember => 'Schválit na 8 hodin';

  @override
  String get approveAndRememberTooltip =>
      'Schválí tuto akci a 8 hodin se na podobné v tomto prostoru nebude ptát. Vyprší samo.';

  @override
  String get unknownUserLabel => 'Neznámý uživatel';

  @override
  String get inviteMember => 'Pozvat člena';

  @override
  String get inviteRepoAccessHeader => 'Přístup k repozitářům';

  @override
  String get inviteRepoAccessExplainer =>
      'Pozvanému se sdílejí jen zaškrtnuté repozitáře, na zvolené úrovni. Vše ostatní zůstane skryté.';

  @override
  String get grantLevelRead => 'Čtení';

  @override
  String get grantLevelReview => 'Kontrola';

  @override
  String get grantLevelWrite => 'Zápis';

  @override
  String get inviteExpiryLabel => 'Vyprší za';

  @override
  String get expiryOneDay => '1 den';

  @override
  String get expirySevenDays => '7 dní';

  @override
  String get expiryThirtyDays => '30 dní';

  @override
  String get createInviteAction => 'Vytvořit pozvánku';

  @override
  String get inviteOneTimeCodeLabel => 'Jednorázový kód';

  @override
  String get inviteCodeShownOnce =>
      'Tento kód se zobrazí jen jednou — zkopírujte ho teď.';

  @override
  String get inviteLinkLabel => 'Odkaz pozvánky';

  @override
  String get inviteRedeemHint =>
      'Sdílejte kód s pozvaným; uplatní ho vůči URL vašeho serveru.';

  @override
  String get inviteScanQr => 'Nebo naskenujte k uplatnění';

  @override
  String get inviteLoopbackWarningTitle => 'Pozvánka míří na místní adresu';

  @override
  String get inviteLoopbackWarningBody =>
      'Spolupracovníci na jiných strojích tento server nedosáhnou. Spusťte tunel (Nastavení → Integrace → Sdílet tento server) nebo se navažte na síť, aby se uživatelé mimo hostitele mohli připojit.';

  @override
  String get inviteStatusOpen => 'Otevřená';

  @override
  String get inviteStatusUsed => 'Použitá';

  @override
  String get inviteStatusRevoked => 'Odvolaná';

  @override
  String get inviteStatusExpired => 'Vypršela';

  @override
  String inviteCreatedTime(String time) {
    return 'Vytvořeno $time';
  }

  @override
  String inviteExpiresOn(String date) {
    return 'vyprší $date';
  }

  @override
  String get noActivityYet => 'Zatím žádná aktivita';

  @override
  String get couldNotLoadMembers => 'Členy se nepodařilo načíst';

  @override
  String get couldNotLoadInvites => 'Pozvánky se nepodařilo načíst';

  @override
  String get couldNotLoadActivity => 'Aktivitu se nepodařilo načíst';

  @override
  String get yourDevices => 'Vaše zařízení';

  @override
  String get yourDevicesDescription =>
      'Klienti spárovaní s vaším účtem na tomto serveru.';

  @override
  String get noOwnDevices =>
      'K vašemu účtu zatím nejsou spárována žádná zařízení';

  @override
  String get renameDeviceTitle => 'Přejmenovat zařízení';

  @override
  String get revokeDeviceTitle => 'Odvolat zařízení';

  @override
  String revokeDeviceConfirm(String label) {
    return 'Odvolat $label? Okamžitě se odpojí a tento server už nedosáhne.';
  }

  @override
  String devicePairedTime(String time) {
    return 'Spárováno $time';
  }

  @override
  String deviceLastSeenTime(String time) {
    return 'Naposledy viděno $time';
  }

  @override
  String get deviceNeverSeen => 'Nikdy nepřipojeno';

  @override
  String get profileSectionLabel => 'Profil';

  @override
  String get profileSectionDescription =>
      'Jak vás vidí tým a autorství git commitů v tomto workspace. Prázdná pole zdědí jméno a e-mail účtu.';

  @override
  String get displayNameLabel => 'Zobrazované jméno';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get gitAuthorNameLabel => 'Jméno autora Git';

  @override
  String get gitAuthorEmailLabel => 'E-mail autora Git';

  @override
  String get profileSaved => 'Profil uložen';

  @override
  String get presenceOnline => 'Online';

  @override
  String get presenceIdle => 'Nečinný';

  @override
  String get presenceTyping => 'Píše…';

  @override
  String get presenceAgentThinking => 'Přemýšlí';

  @override
  String get presenceAgentRunning => 'Běží';

  @override
  String get presenceAgentBlocked => 'Blokováno';

  @override
  String get presenceAgentDone => 'Hotovo';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String presenceNameStatusCost(String name, String status, String cost) {
    return '$name — $status ($cost)';
  }

  @override
  String get presenceRailLabel => 'Kdo je online';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => 'Zapnout nerušit';

  @override
  String get dndTooltipOff => 'Vypnout nerušit';

  @override
  String get startPresenting => 'Začít prezentovat';

  @override
  String get stopPresenting => 'Ukončit prezentaci';

  @override
  String spotlightPresentingBanner(String name) {
    return '$name prezentuje';
  }

  @override
  String get spotlightLeave => 'Opustit';

  @override
  String typingIndicator(String name) {
    return '$name píše…';
  }

  @override
  String get ideTabNotes => 'Poznámky';

  @override
  String get ideSidebarAllViews => 'Všechna zobrazení';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return 'Všechna zobrazení ($count skrytých)';
  }

  @override
  String get ideSidebarPinView => 'Připnout na postranní panel';

  @override
  String get ideSidebarUnpinView => 'Odepnout z postranního panelu';

  @override
  String get notesEmptyHint =>
      'Přidejte poznámku pro kohokoli, kdo tuto konverzaci převezme…';

  @override
  String get notesEditTooltip => 'Upravit poznámku';

  @override
  String notesUpdatedBy(String name, String time) {
    return 'Aktualizoval $name · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '$name upravuje';
  }

  @override
  String get notesSaveFailed => 'Poznámku se nepodařilo uložit';

  @override
  String get reactionAddTooltip => 'Přidat reakci';

  @override
  String reactionToggleTooltip(String emoji) {
    return 'Reagovat $emoji';
  }

  @override
  String get autonomyDialLabel => 'Autonomie';

  @override
  String get autonomyProposeOnly => 'Jen navrhovat';

  @override
  String get autonomyActWithApproval => 'Jednat se schválením';

  @override
  String get autonomyActFreely => 'Jednat volně';

  @override
  String get autonomyDefaultOption => 'Výchozí';

  @override
  String get checkerLabel => 'Kontrolor';

  @override
  String get checkerNone => 'Žádný';

  @override
  String get checkerCaption =>
      'Kontrolor kontroluje dokončené běhy ostatních agentů.';

  @override
  String get takeoverTooltip => 'Převzít worktree';

  @override
  String get takeoverBannerSelf => 'Převzali jste worktree této konverzace';

  @override
  String takeoverBannerOther(String name) {
    return '$name převzal worktree této konverzace';
  }

  @override
  String get handBackButton => 'Vrátit';

  @override
  String get handBackDialogTitle => 'Vrátit worktree';

  @override
  String get handBackDialogNoteHint => 'Volitelná poznámka pro agenta…';

  @override
  String takeoverFailed(String message) {
    return 'Převzetí se nezdařilo: $message';
  }

  @override
  String handBackFailed(String message) {
    return 'Vrácení se nezdařilo: $message';
  }

  @override
  String get planStudioTitle => 'Plan Studio';

  @override
  String get plansTitle => 'Plány';

  @override
  String get plansSubtitle => 'Aktivní plány, dokumenty plánů a playbooky';

  @override
  String get plansActiveSection => 'Aktivní plány';

  @override
  String get plansDocumentsSection => 'Dokumenty plánů';

  @override
  String get plansPlaybooksSection => 'Playbooky';

  @override
  String get plansNoActive => 'Zatím žádné aktivní plány.';

  @override
  String get plansNoDocuments => 'Zatím žádné dokumenty plánů.';

  @override
  String get plansNoPlaybooks => 'Zatím žádné playbooky.';

  @override
  String get planNotFound => 'Plán nenalezen.';

  @override
  String get planOpenInStudio => 'Otevřít';

  @override
  String get planNodeTitle => 'Název';

  @override
  String get planNodeDescription => 'Popis';

  @override
  String get planNodeDescriptionHint => 'Co má tento krok udělat…';

  @override
  String get planNodeApplyDescription => 'Použít';

  @override
  String get planNodeRole => 'Role';

  @override
  String get planNodeDependencies => 'Závisí na';

  @override
  String get planNodeDependenciesHint => 'Přidat závislost';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count závislostí',
      many: '$count závislostí',
      few: '$count závislosti',
      one: '1 závislost',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies =>
      'Žádné závislosti, takže to běží hned po startu plánu';

  @override
  String get planNodeOutputSchema => 'Výstupní schéma (JSON)';

  @override
  String get planNodeEstimate => 'Odhad';

  @override
  String get planNodeProvenance => 'Původ';

  @override
  String get planNodeAlreadyExecuted =>
      'Už provedeno — úprava odtud plán rozvětví.';

  @override
  String get planNewNodeTitle => 'Nový krok';

  @override
  String get planEstimateNoHistory => 'Zatím žádná historie';

  @override
  String get planEstimateBlastUnknown => 'Dosah dopadu: neznámý';

  @override
  String get planEstimatePartial => 'částečný';

  @override
  String get planEstimateAction => 'Odhadnout';

  @override
  String planEstimateDuration(String range) {
    return 'Trvání $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return 'Dosah dopadu: $files souborů, $symbols symbolů';
  }

  @override
  String get planApprove => 'Schválit plán';

  @override
  String get planApproveSelectedNodes => 'Schválit vybrané';

  @override
  String get planReject => 'Odmítnout';

  @override
  String get planCancel => 'Zrušit běh';

  @override
  String get planContinueNode => 'Pokračovat v uzlu';

  @override
  String get planTotalNotEstimated => 'Zatím neodhadnuto';

  @override
  String get planBudgetExceeded => 'nad rozpočtem';

  @override
  String planBudgetCeiling(String amount) {
    return 'rozpočet ≤ \$$amount';
  }

  @override
  String get planVersionsTitle => 'Verze';

  @override
  String get planNoRevisions => 'Zatím žádné revize.';

  @override
  String get planDiffIdentical => 'Žádné změny.';

  @override
  String get planDiffGoalChanged => 'Cíl změněn';

  @override
  String get planDiffBudgetChanged => 'Rozpočet změněn';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'Změny z v$fromRev na v$toRev';
  }

  @override
  String planDiffAdded(String node) {
    return 'Přidáno $node';
  }

  @override
  String planDiffRemoved(String node) {
    return 'Odebráno $node';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return 'Změněno $node: $fields';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return 'Hrana přidána: $edge';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return 'Hrana odebrána: $edge';
  }

  @override
  String planDiffRoleAdded(String role) {
    return 'Role přidána: $role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return 'Role odebrána: $role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return 'Role přeřazena: $role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return 'Plán přeplánován: schválili jste v$approved, teď je v$current. Před pokračováním zkontrolujte diff.';
  }

  @override
  String planLiveActualCost(String amount) {
    return 'Skutečné náklady: \$$amount';
  }

  @override
  String get planPlaybookRun => 'Spustit';

  @override
  String get planPlaybookDelete => 'Smazat playbook';

  @override
  String get planPlaybookProposed =>
      'Plán navržen — schvalte ho v Plan Studio.';

  @override
  String get planPlaybookAnchorTicket => 'Kotvicí ticket';

  @override
  String get planPlaybookPickTicket => 'Vyberte ticket…';

  @override
  String get planPlaybookProposeRun => 'Navrhnout plán';

  @override
  String get planPlaybookRepoHint => 'ID repozitáře';

  @override
  String get planPlaybookAgentHint => 'ID agenta';

  @override
  String planPlaybookRunTitle(String name) {
    return 'Spustit $name';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '$count parametrů';
  }

  @override
  String get recentLabel => 'Nedávné';

  @override
  String get cheatSheetTitle => 'Klávesové zkratky';

  @override
  String get cheatSheetGlobal => 'Globální';

  @override
  String get cheatSheetThisScreen => 'Tato obrazovka';

  @override
  String get cheatSheetReservedInBrowser => 'Vyhrazeno prohlížečem';

  @override
  String get keybindingCheatSheet => 'Klávesové zkratky';

  @override
  String get keybindingShowKeyboardShortcutsDescription =>
      'Zobrazit přehled klávesových zkratek aktuální obrazovky';

  @override
  String get runPlaybookLabel => 'Spustit playbook';

  @override
  String get playbooksLabel => 'Playbooky';

  @override
  String get keybindingUndo => 'Zpět';

  @override
  String get keybindingRedo => 'Znovu';

  @override
  String get keybindingUndoLastActionDescription =>
      'Vrátit poslední vratnou akci';

  @override
  String get keybindingRedoLastActionDescription =>
      'Znovu provést poslední vrácenou akci';

  @override
  String get undone => 'Vráceno';

  @override
  String get redone => 'Znovu provedeno';

  @override
  String get undoFailed => 'Vrácení se nezdařilo';

  @override
  String get undoLabelTicketEdit => 'úprava ticketu';

  @override
  String get undoLabelMessageEdit => 'úprava zprávy';

  @override
  String get undoLabelTodoStatus => 'stav úkolu';

  @override
  String get inboxTitle => 'Doručená pošta';

  @override
  String get inboxReview => 'Kontrola';

  @override
  String get inboxOpen => 'Otevřít';

  @override
  String get inboxAllCaughtUp => 'Máte všechno přečtené';

  @override
  String get inboxGitHubDownTitle => 'GitHub může být mimo provoz';

  @override
  String inboxGitHubDownBody(String status) {
    return 'GitHub hlásí $status, takže pull requesty v tomto seznamu můžou chybět, i když ve skutečnosti hotové nejsou.';
  }

  @override
  String get inboxGitHubIdentityTitle =>
      'Váš účet GitHub se nepodařilo potvrdit';

  @override
  String get inboxGitHubIdentityBody =>
      'Doručená pošta se řadí podle toho, kdo jste na GitHub. Dokud se to nenačte, zůstane prázdná, i když na vás pull requesty čekají.';

  @override
  String get inboxSeverityBlocking => 'Blokováno';

  @override
  String get inboxSeverityWaiting => 'Čeká';

  @override
  String get inboxSeverityInfo => 'Info';

  @override
  String get inboxSyncFailed => 'Synchronizace selhala';

  @override
  String get inboxNeedsYourAttention => 'Vyžaduje vaši pozornost';

  @override
  String get inboxSectionNeedsYourReview => 'Potřebuje vaši kontrolu';

  @override
  String get inboxSectionReturnedToYou => 'Vráceno vám';

  @override
  String get inboxSectionApproved => 'Schváleno';

  @override
  String get inboxSectionDrafts => 'Koncepty';

  @override
  String get inboxSectionWaitingForReviewers => 'Čeká na recenzenty';

  @override
  String get inboxSectionMergingAndMerged => 'Slučuje se a nedávno sloučené';

  @override
  String get inboxSectionWaitingForAuthor => 'Čeká na autora';

  @override
  String get inboxColumnTitle => 'Název';

  @override
  String get inboxColumnChanges => 'Změny';

  @override
  String get inboxColumnUpdated => 'Aktualizováno';

  @override
  String get inboxReviewApproved => 'Schváleno';

  @override
  String get inboxReviewChangesRequested => 'Vyžádány změny';

  @override
  String get inboxHeroSubtitle =>
      'Každý pull request, který se vás týká, seřazený podle toho, co má následovat.';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requestů potřebuje vaši kontrolu',
      many: '$count pull requestů potřebuje vaši kontrolu',
      few: '$count pull requesty potřebují vaši kontrolu',
      one: '1 pull request potřebuje vaši kontrolu',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vráceno vám',
      many: '$count vráceno vám',
      few: '$count vráceny vám',
      one: '1 vrácen vám',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted =>
      'Tato změna se neuložila a byla vrácena';

  @override
  String get offlinePendingLabel => 'čeká';

  @override
  String get offlineSyncingLabel => 'synchronizace';

  @override
  String get copyLinkLabel => 'Kopírovat odkaz na tuto stránku';

  @override
  String get agentsSectionLabel => 'Agenti';

  @override
  String get fleetWorkersTitle => 'Workeři';

  @override
  String get fleetWorkersSubtitle => 'Stroje dostupné ke spouštění úloh';

  @override
  String get fleetJobsTitle => 'Úlohy';

  @override
  String get fleetJobsSubtitle => 'Práce rozdělená po flotile';

  @override
  String get fleetNoWorkers =>
      'Zatím žádní workeři — druhý stroj s `cc_worker --server <url>` se k flotile připojí.';

  @override
  String get fleetNoJobs => 'Žádné úlohy.';

  @override
  String get fleetError => 'Flotilu se nepodařilo načíst';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jader',
      many: '$count jader',
      few: '$count jádra',
      one: '1 jádro',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return 'Heartbeat $time';
  }

  @override
  String get fleetNoHeartbeat => 'Zatím žádný heartbeat';

  @override
  String fleetLastErrorLabel(String error) {
    return 'Poslední chyba: $error';
  }

  @override
  String get fleetDrain => 'Vypustit';

  @override
  String get fleetResume => 'Obnovit';

  @override
  String get fleetRevoke => 'Odvolat';

  @override
  String get fleetRemove => 'Odebrat';

  @override
  String get fleetRevokeTitle => 'Odvolat workera?';

  @override
  String fleetRevokeBody(String name) {
    return 'Odvolat $name? Relace skončí a aktivní úlohy se přeřadí.';
  }

  @override
  String get fleetRemoveTitle => 'Odebrat workera?';

  @override
  String fleetRemoveBody(String name) {
    return 'Odebrat $name z flotily? Tím se smaže jeho záznam.';
  }

  @override
  String get fleetActionFailed => 'Akce selhala';

  @override
  String get fleetJobUnassigned => 'Nepřiřazeno';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '$attempts/$max pokusů';
  }

  @override
  String get fleetPlacementReasons => 'Rozhodnutí o umístění';

  @override
  String get fleetNoPlacements => 'Zatím žádná rozhodnutí o umístění.';

  @override
  String get fleetStatusOnline => 'Online';

  @override
  String get fleetStatusDraining => 'Vypouštění';

  @override
  String get fleetStatusOffline => 'Offline';

  @override
  String get fleetStatusIncompatible => 'Nekompatibilní';

  @override
  String get fleetStatusRevoked => 'Odvoláno';

  @override
  String get fleetJobStatusQueued => 'Ve frontě';

  @override
  String get fleetJobStatusRunning => 'Běží';

  @override
  String get fleetJobStatusSucceeded => 'Úspěšně';

  @override
  String get fleetJobStatusFailed => 'Selhalo';

  @override
  String get fleetJobStatusCancelled => 'Zrušeno';

  @override
  String get evalsNoSuites => 'Zatím žádné sady eval.';

  @override
  String get evalsError => 'Evaly se nepodařilo načíst';

  @override
  String get evalsStarterBadge => 'Startovní';

  @override
  String evalsDefaultBatch(int count) {
    return 'Výchozí dávka $count';
  }

  @override
  String get evalsRecentRuns => 'Nedávné běhy';

  @override
  String get evalsNoRuns => 'Zatím žádné běhy.';

  @override
  String get evalsPassRate => 'Úspěšnost';

  @override
  String evalsBatchTimes(int count) {
    return '× $count';
  }

  @override
  String evalsTriggeredBy(String who) {
    return 'od $who';
  }

  @override
  String evalsRunFinished(String rate) {
    return 'Eval dokončen — $rate prošlo';
  }

  @override
  String get evalsRunFailed => 'Sadu se nepodařilo spustit';

  @override
  String get evalsRun => 'Spustit';

  @override
  String get evalsStatusQueued => 'Ve frontě';

  @override
  String get evalsStatusRunning => 'Běží';

  @override
  String get evalsStatusPassed => 'Prošlo';

  @override
  String get evalsStatusFailed => 'Selhalo';

  @override
  String get bannerMeetingJoin => 'Připojit se';

  @override
  String get bannerMeetingRecordAndLink => 'Nahrát a propojit';

  @override
  String get bannerCalendarReconnect => 'Znovu připojit';

  @override
  String get bannerView => 'Zobrazit';

  @override
  String get soundscapeTitle => 'Soundscapes';

  @override
  String get soundscapePlay => 'Přehrát';

  @override
  String get soundscapePause => 'Pozastavit';

  @override
  String get soundscapeMoodLabel => 'Nálada';

  @override
  String get soundscapeMoodFocus => 'Soustředění';

  @override
  String get soundscapeMoodRelax => 'Relaxace';

  @override
  String get soundscapeMoodSleep => 'Spánek';

  @override
  String get soundscapeMoodRise => 'Vzestup';

  @override
  String get soundscapeVolumeLabel => 'Hlasitost';

  @override
  String get soundscapeTuneLabel => 'Ladění';

  @override
  String get soundscapeTuneMellow => 'Mellow';

  @override
  String get soundscapeTuneBright => 'Bright';

  @override
  String get soundscapeTuneEnergetic => 'Energetic';

  @override
  String get soundscapeTuneSpacy => 'Spacy';

  @override
  String get soundscapeTuneResetHint => 'Dvojité klepnutí obnoví';

  @override
  String get soundscapeSceneLabel => 'Právě hraje';

  @override
  String get soundscapeSceneLoading => 'Ladění atmosféry…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees °C';
  }

  @override
  String get soundscapeLocationLabel => 'Místo';

  @override
  String get soundscapeLocationDetecting => 'Zjišťování polohy…';

  @override
  String get soundscapeLocationAutoNote => 'Poloha pochází z tohoto zařízení.';

  @override
  String get soundscapeRefreshWeather => 'Obnovit počasí';

  @override
  String get soundscapeAutoStartLabel => 'Spustit s režimem soustředění';

  @override
  String get soundscapeAutoStartDescription =>
      'Při spuštění soustředěné relace automaticky přehrát soundscape.';

  @override
  String get soundscapeReturnToApp => 'Zpět do aplikace';

  @override
  String get soundscapePopOut => 'Vysunout přehrávač';

  @override
  String get discussion => 'Diskuze';

  @override
  String get chat => 'Chat';

  @override
  String get saving => 'Ukládání…';

  @override
  String get saved => 'Uloženo';

  @override
  String get saveFailed => 'Uložení se nezdařilo';

  @override
  String get commitAndPush => 'Commit a push';

  @override
  String get commit => 'Commit';

  @override
  String get commitAmend => 'Commit (amend)';

  @override
  String get commitAndSync => 'Commit a synchronizace';

  @override
  String get committed => 'Commitnuto';

  @override
  String get commitAmended => 'Commit upraven (amend)';

  @override
  String get commitFailed => 'Commit selhal';

  @override
  String get moreCommitActions => 'Další akce commitu';

  @override
  String get sourceControl => 'Správa zdrojového kódu';

  @override
  String fixFindingTitle(String location) {
    return 'Opravit: $location';
  }

  @override
  String get openInEditor => 'Otevřít v editoru';

  @override
  String get regexTesterTitle => 'Otestovat regulární výraz';

  @override
  String get regexTesterHint => 'Napište vzorek';

  @override
  String get regexMatch => 'Shoda';

  @override
  String get regexNoMatch => 'Žádná shoda';

  @override
  String get regexInvalidPattern => 'Neplatný vzor';

  @override
  String get symbolLookupNone =>
      'V indexu ani v tomto pull requestu není žádná definice';

  @override
  String get symbolLookupInDiff => 'Nalezeno v tomto pull requestu';

  @override
  String get symbolLookupFromBase =>
      'Z výchozího checkoutu — worktree tohoto PR ještě není indexovaný';

  @override
  String get symbolImplementations => 'Implementace';

  @override
  String symbolCallersCount(int count) {
    return '$count volajících';
  }

  @override
  String get commitMessageHint => 'Zpráva commitu';

  @override
  String get pushedToPr => 'Odesláno do PR';

  @override
  String get pushFailed => 'Push selhal';

  @override
  String get reviewFindings => 'Zjištění';

  @override
  String get treeLabel => 'Strom';

  @override
  String get toggleFileTree => 'Zobrazit nebo skrýt strom souborů';

  @override
  String get diffViewSettings => 'Nastavení zobrazení diffu';

  @override
  String get splitViewLabel => 'Rozdělený';

  @override
  String get unifiedViewLabel => 'Jednotný';

  @override
  String get wrapLines => 'Zalamovat řádky';

  @override
  String get shiftClickSelectRange => 'Shift-klik vybere rozsah';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count souborů',
      many: '$count souborů',
      few: '$count soubory',
      one: '1 soubor',
    );
    return '$_temp0';
  }

  @override
  String prComplexityLoc(String loc) {
    return '$loc LOC';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return 'Malý PR — $files, ~$minutes min ke kontrole';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return 'Střední PR — $files, vyhraďte ~$minutes min ke kontrole';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return 'Velký PR — $files, před kontrolou zvažte rozdělení';
  }

  @override
  String get searchInFiles => 'Hledat v souborech';

  @override
  String get showFileList => 'Zobrazit seznam souborů';

  @override
  String get searchInFilesHintField => 'Hledat v souborech…';

  @override
  String get searchInFilesHint => 'Hledat napříč soubory pull requestu';

  @override
  String get searchInWholeRepo => 'Hledat v celém repozitáři';

  @override
  String get searchInThisPullRequest => 'Hledat v tomto pull requestu';

  @override
  String get searchNoResults => 'Žádné výsledky';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count výsledků',
      many: '$count výsledků',
      few: '$count výsledky',
      one: '1 výsledek',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files souborech',
      many: '$files souborech',
      few: '$files souborech',
      one: '1 souboru',
    );
    return '$_temp0 v $_temp1';
  }

  @override
  String get discardChangesTitle => 'Zahodit změny?';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count souborů',
      many: '$count souborů',
      few: '$count soubory',
      one: '1 soubor',
    );
    return 'Zahodit $_temp0 na HEAD? Tuto akci nelze vrátit zpět.';
  }

  @override
  String get discardAll => 'Zahodit vše';

  @override
  String get discardFailed => 'Zahození změn selhalo';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count souborů',
      many: '$count souborů',
      few: '$count soubory',
      one: '1 soubor',
    );
    return 'Zahozeno $_temp0';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '$reverted souborů',
      many: '$reverted souborů',
      few: '$reverted soubory',
      one: '1 soubor',
    );
    return 'Zahozeno $_temp0; $skipped přeskočeno (nesledované)';
  }

  @override
  String get prWorktreeUnavailable => 'Pracovní prostor není připraven';

  @override
  String get prWorktreeUnavailableHint =>
      'Příprava souborů pull requestu selhala. Otevřete pull request znovu a zkuste to.';

  @override
  String get timestampRelativeLabel => 'Relativní';

  @override
  String get timestampRawLabel => 'Časová značka';

  @override
  String get copyTimestamp => 'Kopírovat časovou značku';

  @override
  String get copiedTimestamp => 'Časová značka zkopírována';

  @override
  String get previewDeployment => 'Náhled nasazení';

  @override
  String previewDeploymentTab(String site) {
    return 'Náhled: $site';
  }

  @override
  String get askForReview => 'Požádat o kontrolu…';

  @override
  String get closePrsConfirmTitle => 'Zavřít pull requesty?';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zavřít $count pull requestů?',
      many: 'Zavřít $count pull requestů?',
      few: 'Zavřít $count pull requesty?',
      one: 'Zavřít 1 pull request?',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zavřeno $count pull requestů',
      many: 'Zavřeno $count pull requestů',
      few: 'Zavřeny $count pull requesty',
      one: 'Zavřen 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Přiřazeno $count pull requestů',
      many: 'Přiřazeno $count pull requestů',
      few: 'Přiřazeny $count pull requesty',
      one: 'Přiřazen 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vyžádána kontrola u $count pull requestů',
      many: 'Vyžádána kontrola u $count pull requestů',
      few: 'Vyžádána kontrola u $count pull requestů',
      one: 'Vyžádána kontrola u 1 pull requestu',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count akcí selhalo',
      many: '$count akcí selhalo',
      few: '$count akce selhaly',
      one: '1 akce selhala',
    );
    return '$_temp0';
  }

  @override
  String get diagram => 'Diagram';

  @override
  String get diagramViewSource => 'Zobrazit zdroj';

  @override
  String get diagramHideSource => 'Skrýt zdroj';

  @override
  String diagramPreviewUnavailable(String reason) {
    return 'Náhled diagramu není k dispozici ($reason)';
  }

  @override
  String get planUnavailable => 'Plán není k dispozici';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kroků',
      many: '$count kroků',
      few: '$count kroky',
      one: '1 krok',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => 'Schválit a spustit';

  @override
  String get planStatusDraft => 'Koncept';

  @override
  String get planStatusProposed => 'Plán';

  @override
  String get planStatusApproved => 'Plán schválen';

  @override
  String get planStatusRejected => 'Plán odmítnut';

  @override
  String get planStatusSuperseded => 'Plán nahrazen';

  @override
  String planRevisionLabel(int revision) {
    return 'Revize $revision';
  }

  @override
  String get adapterEnforcementTitle => 'Co tento adaptér vynucuje';

  @override
  String get enforcementFiltersToolSurface => 'Control Center vybírá nástroje';

  @override
  String get enforcementInterceptsToolCalls =>
      'Každé volání se před spuštěním brání';

  @override
  String get enforcementObservesCompletionContract =>
      'Běh se drží svého výstupu';

  @override
  String get enforcementNativeToolsInterceptable =>
      'Vlastní nástroje runneru jsou viditelné';

  @override
  String get enforcementInProcessToolsSandboxed =>
      'In-process nástroje jsou v sandboxu';

  @override
  String get enforcementYes => 'Ano';

  @override
  String get enforcementNo => 'Ne';

  @override
  String get adapterEnforcementCaveats => 'Výhrady';

  @override
  String get enforcementSummaryModesEnforced => 'Režimy vynuceny';

  @override
  String get enforcementSummaryModesNotEnforced => 'Režimy nevynuceny';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count výhrad',
      many: '$count výhrad',
      few: '$count výhrady',
      one: '1 výhrada',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      'Režimy jen pro čtení nejsou strukturální: Control Center nemůže odebrat vlastní nástroje tohoto runneru.';

  @override
  String get caveatToolCallsNotIntercepted =>
      'Žádná brána před spuštěním: Control Center procházejí jen volání nástrojů MCP.';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      'Vlastní souborové a shell nástroje runneru k Control Center nikdy nedorazí; jedinou podlahou pod nimi je OS sandbox.';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      'In-process souborové nástroje běží mimo sandbox, takže jedinou hranicí souborového systému je povrch nástrojů.';

  @override
  String get caveatCompletionContractUnobservable =>
      'Control Center nemůže popostrčit ani selhat běh, který skončí bez svého výstupu.';

  @override
  String get modeDegraded => 'Omezeno';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return 'Režim $mode na $adapter se spoléhá jen na sandbox; vlastní souborové nástroje agenta se nezachytávají.';
  }

  @override
  String get artifactUnavailable => 'Artefakt není k dispozici';

  @override
  String artifactRevisionLabel(int count) {
    return '$count revizí';
  }

  @override
  String get artifactShowMore => 'Zobrazit více';

  @override
  String get artifactShowLess => 'Zobrazit méně';

  @override
  String get artifactCopy => 'Kopírovat';

  @override
  String get artifactCopied => 'Artefakt zkopírován';

  @override
  String get artifactsTabLabel => 'Artefakty';

  @override
  String get artifactsEmptyTitle => 'Zatím žádné artefakty';

  @override
  String get artifactsEmptyBody =>
      'Až agent zveřejní tabulku, graf nebo diagram, objeví se v tomto seznamu.';

  @override
  String get artifactRevisionPickerLabel => 'Revize';

  @override
  String get artifactRestoreRevision => 'Obnovit tuto revizi';

  @override
  String get artifactOpenInTab => 'Otevřít na kartě';

  @override
  String get artifactTitleFallback => 'Artefakt';

  @override
  String get providerGenerationLabel => 'Výchozí generování';

  @override
  String get providerGenerationHint =>
      'Pole nechte prázdné a použije se vlastní výchozí endpointu. Modely zveřejňují vlastní stropy výstupu a recepty vzorkování; servírování s jinými hodnotami je může zhoršit.';

  @override
  String get providerMaxTokensLabel => 'Max. výstupních tokenů';

  @override
  String get addModel => 'Přidat model';

  @override
  String get modelListTitle => 'Seznam modelů';

  @override
  String get railProvidersGroup => 'Poskytovatelé';

  @override
  String get railCustomProvidersGroup => 'Vlastní poskytovatelé';

  @override
  String get editModelSettings => 'Upravit nastavení modelu';

  @override
  String get modelIdLabel => 'ID modelu';

  @override
  String get modelIdImmutableHint =>
      'ID, které endpoint servíruje; po zařazení je pevné.';

  @override
  String get contextWindowLabel => 'Kontextové okno';

  @override
  String get inputTypesLabel => 'Typy vstupu';

  @override
  String get outputTypesLabel => 'Typy výstupu';

  @override
  String get modalityText => 'Text';

  @override
  String get modalityImage => 'Obrázek';

  @override
  String get modalityAudio => 'Zvuk';

  @override
  String get modalityVideo => 'Video';

  @override
  String get modalityPdf => 'PDF';

  @override
  String get modelOverrideReset => 'Obnovit automatické';

  @override
  String get modelOverrideEdited => 'Upraveno';

  @override
  String get manualModelBadge => 'Přidáno ručně';

  @override
  String get modelIdRequired => 'Zadejte ID modelu.';

  @override
  String get modelTokensInvalid => 'Zadejte kladné celé číslo tokenů.';

  @override
  String get removeModelAction => 'Odebrat model';

  @override
  String removeModelConfirmTitle(String model) {
    return 'Odebrat $model?';
  }

  @override
  String get removeModelConfirmBody =>
      'Model opustí seznam a agenti k němu připnutí přestanou pracovat. Poskytovatel zůstane nedotčen.';

  @override
  String get addModelProviderTitle => 'Přidat poskytovatele modelů';

  @override
  String get addModelProviderDescription =>
      'Nastavte vlastní API endpoint a jeho modely.';

  @override
  String get modelListEmptyHint =>
      'Žádné modely nejsou nastaveny. Přidejte model a použijte ho v chatu.';

  @override
  String get addProviderModelsHint =>
      'Modely se načítají živě, jakmile endpoint odpoví. Ručně přidejte jen ten, který se sám vypsat neumí.';

  @override
  String get providerTemperatureLabel => 'Temperature';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved => 'Výchozí generování uloženo';

  @override
  String get providerGenerationInvalid =>
      'Zkontrolujte hodnoty: max. výstupních tokenů a top-k musí být kladné, temperature 0–2, top-p 0–1.';

  @override
  String get providerGenerationOverridden => 'Přepsáno';

  @override
  String get branchNotPushed => 'neodesláno';

  @override
  String branchNotOnRemote(String branch) {
    return '„$branch“ existuje jen v této konverzaci';
  }

  @override
  String get branchNotOnRemoteHint =>
      'GitHub tuto větev nikdy neviděl, takže ji pull request zatím nemůže použít. Zveřejnění odešle commity už ve worktree — necommitnuté změny zůstanou.';

  @override
  String get publishBranch => 'Zveřejnit větev';

  @override
  String branchPublished(String branch) {
    return '„$branch“ zveřejněna na origin';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return 'Větev zveřejněna. $count necommitnutých změn nebylo zahrnuto.';
  }

  @override
  String get composePrLoadingBranches => 'Načítání větví z GitHub…';

  @override
  String get composePrBranchesFailed =>
      'Větve z GitHub se nepodařilo načíst. Zadejte název větve, nebo zkontrolujte připojení k GitHub.';

  @override
  String get composePrSubtitleFromSpace =>
      'Z větve této konverzace — nejprve ji zveřejněte, pokud ji GitHub ještě neviděl';

  @override
  String get obsTabInsights => 'Přehledy';

  @override
  String get obsTabLive => 'Živé';

  @override
  String get obsTabQuality => 'Kvalita';

  @override
  String get obsTabUsage => 'Využití';

  @override
  String get obsUsageTotalTokens => 'Celkem tokenů';

  @override
  String get obsUsagePeakTokens => 'Špička tokenů';

  @override
  String get obsUsageLongestSession => 'Nejdelší relace';

  @override
  String get obsUsageCurrentStreak => 'Aktuální série';

  @override
  String get obsUsageLongestStreak => 'Nejdelší série';

  @override
  String obsUsageDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dní',
      many: '$count dní',
      few: '$count dny',
      one: '1 den',
      zero: '0 dní',
    );
    return '$_temp0';
  }

  @override
  String get obsUsageTokenActivity => 'Aktivita tokenů';

  @override
  String get obsUsageActivityModeLabel => 'Režim aktivity tokenů';

  @override
  String get obsUsageModeDaily => 'Denní';

  @override
  String get obsUsageModeWeekly => 'Týdenní';

  @override
  String get obsUsageModeCumulative => 'Kumulativní';

  @override
  String get obsUsageTimeRange => 'Časové rozmezí';

  @override
  String get obsUsageTrendTitle => 'Denní trend tokenů';

  @override
  String get obsUsageModelUsage => 'Využití modelů';

  @override
  String get obsUsageTokensLabel => 'tokeny';

  @override
  String get obsUsageNoActivity =>
      'Zatím není zaznamenáno žádné využití tokenů';

  @override
  String get obsUsageOtherModels => 'Ostatní';

  @override
  String obsUsageCellReadout(String date, String tokens) {
    return '$date · $tokens tokenů';
  }

  @override
  String obsUsageActivitySummary(
    String start,
    String end,
    int activeDays,
    String peak,
  ) {
    return 'Aktivita tokenů od $start do $end. $activeDays aktivních dní. Nejrušnější den $peak tokenů.';
  }

  @override
  String get obsScreenSubtitle =>
      'Živé řízení agentů, přiřazení nákladů, kvóty a signály kvality';

  @override
  String get obsRangeLast24h => 'Posledních 24 hodin';

  @override
  String get obsRangeLast7d => 'Posledních 7 dní';

  @override
  String get obsRangeLast30d => 'Posledních 30 dní';

  @override
  String get obsRangeAll => 'Celá doba';

  @override
  String get obsAddFilter => 'Přidat filtr';

  @override
  String get obsFilterAgent => 'Agent';

  @override
  String get obsFilterModel => 'Model';

  @override
  String get obsFilterStatus => 'Stav';

  @override
  String get obsFilterRole => 'Role';

  @override
  String get obsKpiTotalRuns => 'Celkem běhů';

  @override
  String get obsKpiTotalCost => 'Celkové náklady';

  @override
  String get obsKpiErrorRate => 'Míra chyb';

  @override
  String get obsKpiCacheRate => 'Míra cache';

  @override
  String get obsKpiTokensPerSec => 'Tokeny / s';

  @override
  String get obsKpiAvgLatency => 'Prům. latence';

  @override
  String get obsKpiTtft => 'Čas k prvnímu tokenu';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '$delta vůči předchozímu období';
  }

  @override
  String get obsChartActivity => 'Aktivita';

  @override
  String get obsChartCost => 'Náklady v čase';

  @override
  String get obsLegendRuns => 'Běhy';

  @override
  String get obsLegendErrors => 'Chyby';

  @override
  String get obsAgentsTitle => 'Agenti';

  @override
  String obsShowAllAgents(int count) {
    return 'Zobrazit všech $count agentů';
  }

  @override
  String get obsShowFewerAgents => 'Zobrazit méně';

  @override
  String get obsRunsTitle => 'Běhy';

  @override
  String get obsNoRunsInRange => 'V tomto rozsahu žádné běhy';

  @override
  String get obsColTime => 'Čas';

  @override
  String get obsColAgent => 'Agent';

  @override
  String get obsColStatus => 'Stav';

  @override
  String get obsColModel => 'Model';

  @override
  String get obsColDuration => 'Trvání';

  @override
  String get obsColTokens => 'Tokeny';

  @override
  String get obsColCost => 'Náklady';

  @override
  String get obsColErrors => 'Chyby';

  @override
  String get obsColRuns => 'Běhy';

  @override
  String get obsColAvgLatency => 'Prům. latence';

  @override
  String get obsColLastActive => 'Naposledy aktivní';

  @override
  String get obsStatusPending => 'Čeká';

  @override
  String get obsStatusRunning => 'Běží';

  @override
  String get obsStatusCompleted => 'Dokončeno';

  @override
  String get obsStatusError => 'Chyba';

  @override
  String get obsRosterLoadError => 'Seznam agentů se nepodařilo načíst.';

  @override
  String get obsRosterEmpty => 'Zatím žádní agenti';

  @override
  String get obsRosterEmptyDescription =>
      'Odešlete agenta a objeví se tu živě — stav, aktuální nástroj, tokeny, náklady.';

  @override
  String get obsKillAgent => 'Ukončit agenta';

  @override
  String get obsRosterTokensLabel => 'tok';

  @override
  String get obsCostByRoleTitle => 'Náklady podle role';

  @override
  String get obsCostByRoleSubtitle =>
      'Kam tento pracovní prostor utrácí, podle role agenta';

  @override
  String get obsRoleMain => 'Hlavní';

  @override
  String get obsRoleSubagents => 'Subagenti';

  @override
  String get obsRoleAdvisor => 'Poradce';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return 'Hlavní: $main · subagenti: $sub · poradce: $advisor';
  }

  @override
  String get obsTotal => 'Celkem';

  @override
  String get obsTokenModelTitle => 'Model tokenů (5 os)';

  @override
  String get obsTokenModelSubtitle =>
      'Každý token, který tento pracovní prostor utratil, podle osy';

  @override
  String get obsAxisInput => 'Vstup';

  @override
  String get obsAxisOutput => 'Výstup';

  @override
  String get obsAxisReasoning => 'Uvažování';

  @override
  String get obsAxisCacheRead => 'Čtení cache';

  @override
  String get obsAxisCacheWrite => 'Zápis cache';

  @override
  String get obsTotalTokens => 'Celkem tokenů';

  @override
  String get obsCacheDiscountNote =>
      'Tokeny čtení cache se účtují se slevou, takže stojí výrazně méně než stejný objem čerstvého vstupu.';

  @override
  String get obsByModelTitle => 'Podle modelu';

  @override
  String get obsByModelSubtitle => 'Využití tokenů a nákladů na model';

  @override
  String get obsNoModelUsage => 'Zatím není zaznamenáno žádné využití modelu.';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count běhů',
      many: '$count běhů',
      few: '$count běhy',
      one: '1 běh',
    );
    return '$_temp0';
  }

  @override
  String get obsPerRunTitle => 'Na běh';

  @override
  String get obsPerRunSubtitle => 'Typické tokenové náklady jednoho běhu';

  @override
  String get obsMedianRunTokens => 'Medián tokenů běhu';

  @override
  String get obsMedianRunTokensSub => 'Střed napříč všemi běhy';

  @override
  String get obsRunsInWorkspace => 'V tomto pracovním prostoru';

  @override
  String get obsCostShare => 'Podíl nákladů';

  @override
  String get obsQuotaConfiguredLimits => 'Nastavené limity';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      'Využití vůči stropům, které jste nastavili, nejhorší stav první.';

  @override
  String get obsQuotaAddLimit => 'Přidat limit';

  @override
  String get obsQuotaNoLimits =>
      'Zatím nejsou nastaveny žádné limity kvót — přidejte jeden a sledujte využití vůči stropu.';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return 'Odebrat limit $title';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return 'Obnoví se za $duration · $status';
  }

  @override
  String get obsQuotaUsageWindows => 'Okna využití';

  @override
  String get obsQuotaUsageWindowsSubtitle =>
      'Pozorované využití napříč všemi poskytovateli, bez stropu.';

  @override
  String get obsQuotaNoUsage => 'Zatím není zaznamenáno žádné využití.';

  @override
  String get obsQuotaTokensUsed => 'Použité tokeny';

  @override
  String get obsQuotaRequests => 'Požadavky';

  @override
  String get obsQuotaUnitTokens => 'tokeny';

  @override
  String get obsQuotaUnitRequests => 'požadavky';

  @override
  String get obsQuotaUnitCost => 'náklady';

  @override
  String get obsQuotaAddLimitTitle => 'Přidat limit kvóty';

  @override
  String get obsQuotaProviderLabel => 'Poskytovatel';

  @override
  String get obsQuotaWindowLabel => 'Okno';

  @override
  String get obsQuotaUnitLabel => 'Jednotka';

  @override
  String obsQuotaLimitLabel(String unit) {
    return 'Limit ($unit)';
  }

  @override
  String get obsQuotaCentsHint => 'V amerických centech (500 = \$5.00).';

  @override
  String get obsQuotaStatusOk => 'Ok';

  @override
  String get obsQuotaStatusWarning => 'Varování';

  @override
  String get obsQuotaStatusExhausted => 'Vyčerpáno';

  @override
  String get obsQuotaStatusUnknown => 'Neznámý';

  @override
  String get obsGoalNoActiveTitle => 'Žádný aktivní cíl';

  @override
  String get obsGoalNoActiveBody =>
      'Nastavte cíl a dejte agentům úkol a volitelný rozpočet tokenů. Jak běhy končí, rozpočet se plní a agenti se popostrčí k uzavření, až je skoro vyčerpaný.';

  @override
  String get obsGoalSetGoal => 'Nastavit cíl';

  @override
  String get obsGoalTokenBudget => 'Rozpočet tokenů';

  @override
  String obsGoalTokensLeft(String tokens) {
    return 'zbývá $tokens';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens (rozpočet není nastaven)';
  }

  @override
  String get obsGoalTokensUsed => 'Použité tokeny';

  @override
  String get obsGoalElapsed => 'Uplynulo';

  @override
  String get obsGoalWrapUp => 'Uzavřít';

  @override
  String get obsGoalClear => 'Vymazat cíl';

  @override
  String get obsGoalFallbackTitle => 'Cíl';

  @override
  String get obsGoalSubtitle => 'Rozpočet režimu cíle';

  @override
  String get obsGoalStatusActive => 'Aktivní';

  @override
  String get obsGoalStatusPaused => 'Pozastaveno';

  @override
  String get obsGoalStatusBudgetLimited => 'Omezeno rozpočtem';

  @override
  String get obsGoalStatusComplete => 'Dokončeno';

  @override
  String get obsGoalStatusDropped => 'Zrušeno';

  @override
  String get obsGoalObjectiveLabel => 'Cíl';

  @override
  String get obsGoalBudgetLabel => 'Rozpočet tokenů (volitelné)';

  @override
  String get obsGoalSetAction => 'Nastavit cíl';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => 'Úspěch %';

  @override
  String get obsBenchmarkPassed => 'Prošlo';

  @override
  String get obsBenchmarkFailed => 'Selhalo';

  @override
  String get obsBenchmarkErrors => 'Chyby';

  @override
  String get obsBenchmarkSpend => 'Výdaje';

  @override
  String get obsBenchmarkCostPerTask => 'Náklady / úkol';

  @override
  String get obsBenchmarkTrials => 'Pokusy';

  @override
  String get obsBenchmarkNoTrials => 'Zatím žádné běhy k hodnocení.';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'A $count dalších',
      many: 'A $count dalších',
      few: 'A $count další',
      one: 'A 1 další',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => 'Úspěch';

  @override
  String get obsBenchmarkTrialFail => 'Neúspěch';

  @override
  String get obsBenchmarkTrialError => 'Chyba';

  @override
  String get obsBenchmarkTrialRunning => 'Běží';

  @override
  String get obsBenchmarkReward => 'Odměna';

  @override
  String get obsBenchmarkReport => 'Report';

  @override
  String get obsBenchmarkCopyMarkdown => 'Kopírovat Markdown';

  @override
  String get obsBenchmarkCopied => 'Report zkopírován do schránky';

  @override
  String get obsBehaviorCaption =>
      'Tohle jsou signály frustrace z vašich vlastních zpráv — čtení zdraví konverzace, ne skóre agentů. Počítá se lokálně; nic toto zařízení neopustí.';

  @override
  String get obsBehaviorMessagesAnalyzed => 'Analyzované zprávy';

  @override
  String get obsBehaviorTotalSignals => 'Celkem signálů';

  @override
  String get obsBehaviorYelling => 'Křičení';

  @override
  String get obsBehaviorProfanity => 'Nadávky';

  @override
  String get obsBehaviorAnguish => 'Úzkost';

  @override
  String get obsBehaviorNegation => 'Negace';

  @override
  String get obsBehaviorRepetition => 'Opakování';

  @override
  String get obsBehaviorBlame => 'Obviňování';

  @override
  String get obsBehaviorConversationsTitle => 'Nejfrustrovanější konverzace';

  @override
  String get obsBehaviorConversationsSubtitle =>
      'Řazeno podle hustoty signálů ve vašich zprávách.';

  @override
  String get obsBehaviorNoSignals => 'Žádné signály frustrace — hladká plavba.';

  @override
  String obsBehaviorMessagesCount(String count) {
    return 'Analyzováno $count zpráv';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '$count signálů';
  }

  @override
  String get obsAgentStatusIdle => 'Nečinný';

  @override
  String get obsAgentStatusParked => 'Zaparkováno';

  @override
  String get obsAgentStatusAborted => 'Přerušeno';

  @override
  String get obsAgentKindSub => 'Sub';

  @override
  String get noChecksOnCommit => 'Na tomto commitu neběžely žádné kontroly.';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Běží — $count úloh',
      many: 'Běží — $count úloh',
      few: 'Běží — $count úlohy',
      one: 'Běží — 1 úloha',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Všechny kontroly prošly — $count úloh',
      many: 'Všechny kontroly prošly — $count úloh',
      few: 'Všechny kontroly prošly — $count úlohy',
      one: 'Všechny kontroly prošly — 1 úloha',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dokončeno — $count úloh',
      many: 'Dokončeno — $count úloh',
      few: 'Dokončeno — $count úlohy',
      one: 'Dokončeno — 1 úloha',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total úloh',
      many: '$total úloh',
      few: '$total úloh',
      one: '1 úlohy',
    );
    return '$failed z $_temp0 selhalo';
  }

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count úloh',
      many: '$count úloh',
      few: '$count úlohy',
      one: '1 úloha',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return 'Matrix: $jobId';
  }

  @override
  String get jobLogsPending => 'Protokoly se tu objeví, až úloha skončí.';

  @override
  String get jobLogsUnavailable => 'Protokoly této úlohy nejsou k dispozici.';

  @override
  String get noLogsForStep =>
      'Pro tento krok nebyly zachyceny žádné protokoly.';

  @override
  String get jobLogsTruncated =>
      'Protokol zkrácen — zobrazen nejnovější výstup.';

  @override
  String get fullLog => 'Celý protokol';

  @override
  String get copyLogs => 'Kopírovat protokoly';

  @override
  String get resizeGraph => 'Přetažením změňte velikost grafu';

  @override
  String workflowRunStartedAgo(String time) {
    return 'Spuštěno $time';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return 'Dokončeno $time';
  }

  @override
  String get chatBridgesTitle => 'Mosty chatu';

  @override
  String chatProviderDescription(String provider, String command) {
    return 'Zmiňte bota v $provider a nasaďte agenta na něco, nebo zakládejte tickety příkazem $command.';
  }

  @override
  String chatConnectProvider(String provider) {
    return 'Připojit $provider';
  }

  @override
  String get chatDisconnectProvider => 'Odpojit';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$botName v $teamName';
  }

  @override
  String get chatStateLive => 'Živě';

  @override
  String get chatStateConnecting => 'Připojování…';

  @override
  String get chatStateError => 'Chyba připojení';

  @override
  String get chatNotConnected => 'Nepřipojeno';

  @override
  String chatStreamingUnavailable(String provider) {
    return 'Živé streamování je pro tuto aplikaci $provider vypnuté — odpovědi přijdou jako jedna zpráva.';
  }

  @override
  String chatAdminOnly(String provider) {
    return 'Připojit $provider k tomuto pracovnímu prostoru může jen admin.';
  }

  @override
  String chatConnectHint(String provider) {
    return 'Vytvořte aplikaci $provider a sem vložte její přihlašovací údaje. Control Center se k $provider připojuje ven, takže tento server nepotřebuje veřejnou adresu.';
  }

  @override
  String chatOpenConsole(String provider) {
    return 'Otevřít konzoli $provider';
  }

  @override
  String get chatOpenSetupGuide => 'Průvodce nastavením';

  @override
  String get chatFieldBotToken => 'Token bota';

  @override
  String get chatFieldAppToken => 'Token na úrovni aplikace';

  @override
  String get chatFieldConfigRefreshToken => 'Token konfigurace aplikace';

  @override
  String chatFieldOptional(String label) {
    return '$label (volitelné)';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return 'Propojit můj účet $provider';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return 'Propojte účet $provider, aby se zprávy, které tam odešlete, přiřadily vám.';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return 'Propojeno s $externalUserId';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return 'Propojit účet $provider';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return 'Pošlete tento příkaz botovi v $provider. Funguje jednou a vyprší za 15 minut.';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return 'Váš účet $provider je teď propojený — zprávy, které tam odešlete, se přiřadí vám.';
  }

  @override
  String get chatLinkedAccounts => 'Propojené účty';

  @override
  String chatNoLinkedAccounts(String provider) {
    return 'Zatím nikdo nepropojil účet $provider.';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count propojených účtů',
      many: '$count propojených účtů',
      few: '$count propojené účty',
      one: '1 propojený účet',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '$externalUserId · spárováno podle e-mailu';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '$externalUserId · propojeno kódem';
  }

  @override
  String get chatUnlink => 'Odpojit';

  @override
  String get chatCustomizeBot => 'Přizpůsobit bota';

  @override
  String get chatCustomizeBotDescription =>
      'Přejmenujte bota, změňte, co o sobě říká, nebo přejmenujte slash příkaz.';

  @override
  String get chatCustomizeBotUnavailable =>
      'Control Center k úpravě bota potřebuje token konfigurace aplikace. Připojte znovu a jeden přidejte.';

  @override
  String chatCreateAppTitle(String provider) {
    return 'Vytvořit aplikaci $provider';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'Control Center může aplikaci $provider vytvořit za vás, se správnými oprávněními a událostmi. Dokončíte to v $provider a sem vložíte přihlašovací údaje.';
  }

  @override
  String get chatCreateApp => 'Vytvořit aplikaci';

  @override
  String get chatCreateAppCta => 'Vytvořit aplikaci za mě';

  @override
  String get chatAppNameLabel => 'Název aplikace';

  @override
  String get chatBotDisplayNameLabel => 'Jméno bota (co členové píší za @)';

  @override
  String get chatDescriptionLabel => 'Krátký popis';

  @override
  String get chatAgentDescriptionLabel => 'Co bot říká, že umí';

  @override
  String get chatCommandLabel => 'Slash příkaz';

  @override
  String get chatDirectMessages => 'Přímé zprávy';

  @override
  String chatDirectMessagesHint(String provider) {
    return 'Umožní členům chatovat s botem v DM. Může vyžadovat placený tarif $provider.';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return '$provider vytvořil aplikaci $appId.';
  }

  @override
  String chatRemainingSteps(String provider) {
    return 'Zbývá pár kroků a může je udělat jen $provider:';
  }

  @override
  String get chatStepAppToken => 'Vygenerovat token na úrovni aplikace';

  @override
  String get chatStepInstall => 'Nainstalovat aplikaci';

  @override
  String get chatOpenAppSettings => 'Otevřít nastavení aplikace';

  @override
  String get chatContinueToCredentials => 'Vložit přihlašovací údaje';

  @override
  String chatBotUpdated(String provider) {
    return 'Bot aktualizován v $provider.';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return '$provider změnil oprávnění aplikace. Aplikaci znovu nainstalujte, aby se projevila.';
  }

  @override
  String get chatReinstallApp => 'Znovu nainstalovat aplikaci';

  @override
  String chatIconNotEditable(String provider) {
    return 'Ikonu bota lze změnit jen ve vlastním nastavení aplikace $provider.';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return 'Můžete ji také vytvořit sami v $provider — token není potřeba. Nastavení výše se s odkazem přenesou.';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return 'Vytvořit v $provider';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return '$provider se otevřel v prohlížeči s touto konfigurací předvyplněnou. Vytvořte tam aplikaci, dokončete tyto kroky a vraťte se s tokeny.';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return '$provider nehlásí, kterou aplikaci vytvořil, takže přizpůsobení bota odsud později potřebuje token konfigurace aplikace.';
  }

  @override
  String get chatStepCreateApp =>
      'Vytvořit aplikaci z předvyplněné konfigurace';

  @override
  String chatStepCreateAppHint(String provider) {
    return 'Vyberte pracovní prostor v $provider a potvrďte.';
  }

  @override
  String get chatStepAppTokenHint =>
      'Basic information → app-level tokens, s rozsahem connections:write.';

  @override
  String get chatStepInstallHint =>
      'Install app → zkopírujte OAuth token uživatelského bota.';

  @override
  String get calendarUseBuiltinApp => 'Použít Google aplikaci Control Center';

  @override
  String get calendarUseBuiltinAppHint =>
      'Schvalte účtem Google. V Google Cloud není co nastavovat.';

  @override
  String get calendarUseOwnClient => 'Použít vlastní klienta Google Cloud';

  @override
  String get calendarUseOwnClientHint =>
      'Zadejte OAuth klienta z vlastního projektu Google Cloud.';

  @override
  String get aboutTitle => 'O aplikaci';

  @override
  String get aboutAppVersion => 'Verze aplikace';

  @override
  String get aboutServerVersion => 'Připojený server';

  @override
  String get aboutRpcCatalog => 'Katalog RPC';

  @override
  String get aboutServerUnknown => 'Nenahlášeno';

  @override
  String get serverStaleTitle => 'Balený server je starší než tato aplikace';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return 'Běžící cc_server je $serverVersion, zatímco tato aplikace je $appVersion. Restartujte aplikaci, aby načetla nejnovější balené sestavení serveru; ve vývoji ho přestavte pomocí `dart build cli` v apps/cc_server.';
  }

  @override
  String get updateCheckButton => 'Zkontrolovat aktualizace';

  @override
  String get updateChecking => 'Kontrola aktualizací…';

  @override
  String get updateUpToDate => 'Máte aktuální verzi';

  @override
  String get updateDeferredBusy =>
      'Aktualizace je připravená, ale nahrává se schůzka — výzva přijde po jejím skončení.';

  @override
  String get updateOpenedReleasesPage =>
      'Stránka vydání se otevřela v prohlížeči.';

  @override
  String get updateCheckFailed => 'Kontrola aktualizací selhala';

  @override
  String updateAvailableVersion(String version) {
    return 'Je dostupná verze $version.';
  }

  @override
  String get updateBannerTitle => 'Je dostupný nový Control Center';

  @override
  String get updateBannerRefresh => 'Obnovit';

  @override
  String get updateBlockedRecording =>
      'Obnovení je pozastaveno, dokud se nahrává schůzka — po skončení se znovu načte.';

  @override
  String get settingsScopeYou => 'Vy';

  @override
  String get settingsScopeWorkspace => 'Pracovní prostor';

  @override
  String get settingsScopeServer => 'Server';

  @override
  String get settingsProfile => 'Profil a identita';

  @override
  String get settingsYourDevices => 'Vaše zařízení';

  @override
  String get settingsWorkspaceGeneral => 'Obecné';

  @override
  String get settingsServerConnection => 'Připojení a stav';

  @override
  String get settingsModelProviders => 'Poskytovatelé modelů';

  @override
  String get settingsVoiceModels => 'Hlasové a schůzkové modely';

  @override
  String get settingsDiagnostics => 'Diagnostika a soukromí';

  @override
  String get settingsAbout => 'O aplikaci';

  @override
  String get settingsScopeBadgeYou => 'VY';

  @override
  String get settingsScopeBadgeDevice => 'TOTO ZAŘÍZENÍ';

  @override
  String get settingsScopeBadgeWorkspace => 'PRACOVNÍ PROSTOR';

  @override
  String get settingsScopeBadgeServer => 'SERVER';

  @override
  String get settingsProfileDescription =>
      'Vaše jméno, e-mail a git identita v tomto workspace. Přepnutí workspace přepne tuto vrstvu; handle, přihlášení a zařízení zůstanou na účtu.';

  @override
  String get settingsServerConnectionDescription =>
      'Ke kterému serveru tento klient mluví a jak se tento server sdílí (mDNS, tunely, relé).';

  @override
  String get settingsAboutDescription => 'Identita sestavení a aktualizace.';

  @override
  String get settingsDiagnosticsDescription =>
      'Izolace, indexování, synchronizace, protokolování a hlášení pádů této instalace.';

  @override
  String get settingsWorkspaceGeneralDescription =>
      'Identita, politika a konvence sdílené všemi v tomto pracovním prostoru.';

  @override
  String get settingsWorkspaceMeetingsDescription =>
      'Šablony poznámek a uložené hlasy pro schůzky v tomto pracovním prostoru.';

  @override
  String get settingsWorkspacePolicyLabel => 'Politika pracovního prostoru';

  @override
  String get settingsWorkspacePolicyDescription =>
      'Platí pro každého člena a každého agenta v tomto pracovním prostoru.';

  @override
  String get settingsSecretGlobsLabel => 'Vyloučení cest k tajemstvím';

  @override
  String get settingsSecretGlobsHelp =>
      'Jeden glob na řádek. Tyto cesty jsou skryté prohlížečům a hostům na površích s kódem, navíc k vestavěným výchozím.';

  @override
  String get settingsReviewConcurrencyLabel => 'Souběh kontrol';

  @override
  String get settingsReviewConcurrencyHelp =>
      'Kolik recenzentů se odešle paralelně, když není zadán explicitní počet.';

  @override
  String get settingsReviewLevelLabel => 'Úroveň kontroly';

  @override
  String get settingsReviewLevelHelp =>
      'Jak hluboko AI kontrola jde a kolik z toho, co najde, se nahlásí hned. Nic se nezahazuje — lehčí úroveň drobnější zjištění seskupí místo jejich vynechání.';

  @override
  String get reviewLevelLight => 'Lehká';

  @override
  String get reviewLevelBalanced => 'Vyvážená';

  @override
  String get reviewLevelThorough => 'Důkladná';

  @override
  String get reviewLevelLightHint =>
      'Jeden recenzent. Hned se nahlásí jen to, co podstatně záleží.';

  @override
  String get reviewLevelBalancedHint =>
      'Tři recenzenti pokrývající QA, architekturu a implementaci.';

  @override
  String get reviewLevelThoroughHint =>
      'Přidá specialisty na bezpečnost a výkon a nahlásí vše nalezené.';

  @override
  String get askAiReviewAtLevel => 'Kontrola na jiné úrovni';

  @override
  String reviewNitpicksGroup(int count) {
    return 'Drobnosti ($count)';
  }

  @override
  String get reviewFindingResolve => 'Opraveno';

  @override
  String get reviewFindingResolveHint =>
      'Označit toto zjištění jako opravené. Přestane se počítat proti kontrole.';

  @override
  String get reviewFindingDismiss => 'Zamítnout';

  @override
  String get reviewFindingDismissHint =>
      'Není to skutečný problém. Recenzenti tento vzor na budoucích PR přestanou hlásit.';

  @override
  String get reviewFindingReopen => 'Znovu otevřít';

  @override
  String get reviewFindingStatusUndoLabel => 'Stav zjištění';

  @override
  String get reviewFindingDismissTitle => 'Zamítnout toto zjištění';

  @override
  String get reviewFindingDismissReasonHint =>
      'Proč to neplatí? Recenzenti to budou číst.';

  @override
  String reviewFindingStatusFailed(String error) {
    return 'Zjištění se nepodařilo aktualizovat: $error';
  }

  @override
  String get reviewStaleTitle => 'Tato kontrola je zastaralá';

  @override
  String get reviewStaleBody =>
      'Pull request se od této kontroly posunul. Zjištění můžou ukazovat na kód, který už neexistuje.';

  @override
  String reviewStaleReviewedAt(String sha) {
    return 'Zkontrolováno u $sha';
  }

  @override
  String get reviewStaleRerun => 'Zkontrolovat znovu';

  @override
  String reviewStaleNotificationTitle(int prNumber) {
    return 'Zastaralá kontrola u #$prNumber';
  }

  @override
  String reviewStaleNotificationBody(String title) {
    return '$title má nové commity od poslední kontroly.';
  }

  @override
  String get reviewCategorySecurity => 'Bezpečnost';

  @override
  String get reviewCategoryStability => 'Stabilita';

  @override
  String get reviewCategoryDataIntegrity => 'Integrita dat';

  @override
  String get reviewCategoryCorrectness => 'Správnost';

  @override
  String get reviewCategoryPerformance => 'Výkon';

  @override
  String get reviewCategoryMaintainability => 'Udržovatelnost';

  @override
  String get reviewEffortQuickWin => 'Rychlá výhra';

  @override
  String get reviewEffortModerate => 'Střední';

  @override
  String get reviewEffortHeavyLift => 'Těžká práce';

  @override
  String get reviewProposedFix => 'Navržená oprava';

  @override
  String get reviewAiAgentPrompt => 'Prompt pro AI agenty';

  @override
  String get reviewCopyAiPrompt => 'Kopírovat prompt';

  @override
  String get settingsWorkspaceAdminOnly =>
      'Tyto položky můžou měnit jen admini pracovního prostoru.';

  @override
  String get chatMyAccountsTitle => 'Propojené účty chatu';

  @override
  String get settingsServerSso => 'Jednotné přihlášení';

  @override
  String get settingsServerSsoDescription =>
      'Přihlášení SAML a OpenID Connect s provisionováním uživatelů';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabledDescription =>
      'Uživatelé se můžou přihlásit tímto poskytovatelem';

  @override
  String get ssoEnabledDescriptionOn =>
      'Přihlášení u tohoto poskytovatele je živé';

  @override
  String get ssoIdpMetadataLabel => 'XML metadat IdP';

  @override
  String get ssoIdpMetadataHint => 'vložte XML EntityDescriptor IdP';

  @override
  String get ssoEmailAttributeLabel => 'Atribut e-mailu';

  @override
  String get ssoDisplayNameAttributeLabel => 'Atribut zobrazovaného jména';

  @override
  String get ssoGroupsAttributeLabel => 'Atribut skupin';

  @override
  String get ssoIssuerLabel => 'URL vydavatele';

  @override
  String get ssoClientIdLabel => 'Client ID';

  @override
  String get ssoGroupsClaimLabel => 'Claim skupin';

  @override
  String get ssoAutoMemberLabel =>
      'Přidat uživatele do každého pracovního prostoru při prvním přihlášení';

  @override
  String get ssoAutoMemberDescription =>
      'Vypněte, pokud je k pracovnímu prostoru potřeba pozvánka';

  @override
  String get ssoAllowJitLabel =>
      'Provisionovat neznámé uživatele při prvním přihlášení';

  @override
  String get ssoAllowJitDescription =>
      'Vypněte a odmítnete uživatele bez existujícího účtu';

  @override
  String get ssoAllowIdpInitiatedLabel =>
      'Přijímat nevyžádané (IdP-iniciované) přihlášení';

  @override
  String get ssoAllowIdpInitiatedDescription =>
      'Jen pro portály IdP, které spouštějí aplikace přímo';

  @override
  String get ssoWantResponseSignedLabel =>
      'Vyžadovat podepsanou obálku odpovědi';

  @override
  String get ssoWantResponseSignedDescription =>
      'Podpisy assertion jsou vždy povinné';

  @override
  String get ssoTestConnectionButton => 'Otestovat připojení';

  @override
  String get ssoTestConnectionOk => 'Připojení funguje:';

  @override
  String get ssoCopySpMetadata => 'Kopírovat metadata SP';

  @override
  String get ssoCopySpMetadataDone => 'Metadata SP zkopírována do schránky';

  @override
  String get ssoSavedToast => 'Nastavení jednotného přihlášení uloženo';

  @override
  String get ssoUnavailable =>
      'Tento server nenabízí nastavení jednotného přihlášení. Aktualizujte binárku serveru a zkuste to znovu.';

  @override
  String get ssoScimCardTitle => 'Provisionování uživatelů (SCIM)';

  @override
  String get ssoScimDescription =>
      'Nasměrujte SCIM konektor identity poskytovatele na endpoint níže s bearer tokenem. Deprovisionování odvolá relace a přístup k pracovnímu prostoru během sekund. Server musí být pro IdP dosažitelný (tunel nebo veřejné URL).';

  @override
  String get ssoScimEndpoint => 'Endpoint SCIM';

  @override
  String get ssoScimEndpointUnknownOrigin =>
      'Nejprve nastavte veřejné URL serveru nebo zapněte tunel';

  @override
  String get ssoScimRegenerate => 'Znovu vygenerovat token';

  @override
  String get ssoScimRegenerateConfirm =>
      'Vygenerovat nový bearer token SCIM? Předchozí token okamžitě přestane fungovat.';

  @override
  String get ssoScimTokenTitle => 'Bearer token';

  @override
  String get ssoScimTokenPresent => 'Token je nastaven';

  @override
  String get ssoScimTokenAbsent =>
      'Zatím žádný token — vygenerujte jeden a zapněte SCIM';

  @override
  String get ssoScimTokenOnce => 'Token SCIM (zobrazen jednou)';

  @override
  String ssoSignInWith(String provider) {
    return 'Přihlásit se přes $provider';
  }

  @override
  String get ssoProbeFailed =>
      'Tento server se pro jednotné přihlášení nepodařilo dosáhnout';

  @override
  String get ssoOpensBrowser => 'Otevře prohlížeč k dokončení přihlášení';

  @override
  String get ssoWaitingForBrowser =>
      'Čeká se, až prohlížeč dokončí přihlášení…';

  @override
  String get ssoBrowserOpenFailed =>
      'Prohlížeč se pro jednotné přihlášení nepodařilo otevřít';

  @override
  String get ssoUseManualPairing =>
      'Místo toho se přihlásit pozvánkou nebo párovacím klíčem';

  @override
  String get ssoHideManualPairing => 'Skrýt ruční párování';

  @override
  String get ssoClientIdHint => 'Veřejný (PKCE) klient — secret není potřeba';

  @override
  String get ssoClientSecretLabel => 'Client secret (volitelné)';

  @override
  String get ssoClientSecretHintUnset => 'Potřeba jen u důvěrných klientů IdP';

  @override
  String get ssoClientSecretHintSet =>
      'Secret je uložen — nechte prázdné a zůstane';

  @override
  String get ssoPairingToggle =>
      'Povolit ruční párování (kódy pozvánek a párovací klíče)';

  @override
  String get ssoPairingToggleDescription =>
      'Vypněte a připojování bude jen přes jednotné přihlášení — nová zařízení přijdou přes SSO; stávající zůstanou funkční';

  @override
  String get ssoPairConfirmTitle => 'Připojit k serveru?';

  @override
  String ssoPairConfirmBody(String server) {
    return 'Přišly přihlašovací údaje k $server, ale z této aplikace se přihlášení nespustilo. Připojit k tomuto serveru?';
  }

  @override
  String get ssoPairConfirmConnect => 'Připojit';

  @override
  String get ssoPairConfirmCancel => 'Ignorovat';

  @override
  String get forgeConnections => 'Hostování kódu';

  @override
  String get connect => 'Připojit';

  @override
  String get disconnect => 'Odpojit';

  @override
  String get notConnected => 'Nepřipojeno';

  @override
  String get checkingConnection => 'Kontrola připojení…';

  @override
  String get fromEnvironment => 'z prostředí';

  @override
  String forgeTokenTitle(String forge) {
    return 'Token $forge';
  }

  @override
  String get settingsAudio => 'Zvuk';

  @override
  String get settingsAudioDescription =>
      'Mikrofon, diktování, zjišťování schůzek a výstup soundscape.';

  @override
  String get audioDevicesSection => 'Zvuková zařízení';

  @override
  String get voiceInputBehaviorSection => 'Diktování a schůzky';

  @override
  String get audioOutputDeviceTitle => 'Výstupní zařízení';

  @override
  String get audioOutputDefaultHint =>
      'Veškerý zvuk aplikace jde přes systémový výchozí výstup.';

  @override
  String get audioOutputGone =>
      'Vybrané výstupní zařízení už není připojené — dokud nevyberete jiné, použije se systémové výchozí.';

  @override
  String get reviewHubIntroBody =>
      'Agenti analyzují diff, zmapují oblasti změn a dospějí ke konsenzuálnímu verdiktu.';

  @override
  String get reviewHubAlreadyRunning =>
      'Pro tento pull request už běží kontrola';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return 'Od poslední kontroly: $resolved vyřešeno · $added nových · $open stále otevřených';
  }

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return 'Naposledy zkontrolováno u $sha';
  }

  @override
  String reviewArtifactFixAll(int count) {
    return 'Opravit $count zjištění';
  }

  @override
  String reviewArtifactFixSelected(int count) {
    return 'Opravit $count vybraných';
  }

  @override
  String reviewArtifactCommentSelected(int count) {
    return 'Okomentovat $count vybraných';
  }

  @override
  String get webConnectTitle => 'Připojit k Control Center';

  @override
  String get webConnectSubtitle =>
      'Vytočte běžící cc-server přes WebSocket. Klíč zůstane na tomto zařízení.';

  @override
  String get webConnectServerLabel => 'Server';

  @override
  String get webConnectDeviceIdLabel => 'ID zařízení';

  @override
  String get webConnectPairingKeyLabel => 'Párovací klíč';

  @override
  String get webConnectPairingKeyHint => 'vložte PSK';

  @override
  String get webConnectStayConnected => 'Zůstat připojen na tomto zařízení';

  @override
  String get webConnectStayConnectedDetail =>
      'Zůstat připojen na tomto zařízení (uloží klíč v tomto prohlížeči)';

  @override
  String failedToCreateWorkspace(String error) {
    return 'Pracovní prostor se nepodařilo vytvořit: $error';
  }

  @override
  String committedRelative(String relative) {
    return 'commitnuto $relative';
  }

  @override
  String get selectAgents => 'Vybrat agenty';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agentů',
      many: '$count agentů',
      few: '$count agenti',
      one: '1 agent',
    );
    return '$_temp0';
  }

  @override
  String get newConversation => 'Nová konverzace';

  @override
  String get untitledConversation => 'Nepojmenovaná konverzace';

  @override
  String get conversationTitleOptionalHint =>
      'Volitelné — nechte prázdné a model názvu ho pojmenuje automaticky';

  @override
  String get conversationTitlesSectionTitle => 'Názvy konverzací';

  @override
  String get conversationTitlesSectionCaption =>
      'Vyberte runner, který v tomto pracovním prostoru automaticky pojmenuje nové konverzace. Názvy zůstanou vypnuté, dokud není zvolen adaptér, a platí pro každého člena.';

  @override
  String get conversationTitlesModelLabel => 'Model názvu';

  @override
  String get conversationTitlesAdapterLabel => 'Adaptér';

  @override
  String get conversationTitlesAdapterHint => 'Vypnuto';

  @override
  String get conversationTitlesAdapterOff => 'Vypnuto';

  @override
  String get startThread => 'Začít vlákno';

  @override
  String get deleteSpaceConfirm =>
      'Smazat tento prostor? Všechny zprávy se ztratí.';

  @override
  String threadTabTitle(String title) {
    return 'Vlákno: $title';
  }

  @override
  String threadReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count odpovědí',
      many: '$count odpovědí',
      few: '$count odpovědi',
      one: '1 odpověď',
    );
    return '$_temp0';
  }

  @override
  String threadLastReply(String time) {
    return 'Poslední odpověď $time';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Přihlásit se přes $provider';
  }

  @override
  String get signInAgain => 'Přihlásit se znovu';

  @override
  String get signInNotFinished =>
      'Přihlášení se ještě nevrátilo. Dokončete ho v prohlížeči a zkontrolujte znovu.';

  @override
  String get signedOutTitle => 'Jste odhlášeni';

  @override
  String get signedOutSubtitle =>
      'Připojení k hostiteli kódu už není platné — token vypršel, nebo byl přístup odvolán. Nic jiného se nezměnilo: přihlaste se zpět a vše je tam, kde jste to nechali.';

  @override
  String get viaServerApp => 'přes aplikaci tohoto serveru';

  @override
  String get ticketing => 'Ticketing';

  @override
  String get ticketingProviderHelp =>
      'Kde žijí vaše tickety. Místní je drží v Control Center.';

  @override
  String providerComingSoon(String provider) {
    return '$provider (brzy)';
  }

  @override
  String get ticketProviderLocal => 'Místní';

  @override
  String get addKey => 'Přidat klíč';

  @override
  String get providerApps => 'Aplikace poskytovatelů';

  @override
  String get providerAppsDescription =>
      'Workspacy dědí tuto GitHub App, pokud si nevyberou jinou App nebo osobní přístupový token. Práce na pozadí — webhooky, polling, sync — běží na app, nikdy na tokenu osoby.';

  @override
  String get providerAppId => 'ID aplikace';

  @override
  String get providerPrivateKey => 'Soukromý klíč';

  @override
  String get providerClientId => 'Client id';

  @override
  String get providerClientSecret => 'Client secret';

  @override
  String get providerApiKey => 'API klíč';

  @override
  String get providerCallbackUrl => 'Callback URL';

  @override
  String get providerAppFullyConfigured =>
      'Server může jednat jako on sám a lidé se můžou přihlásit.';

  @override
  String get providerAppServerOnly =>
      'Server může jednat jako on sám. Přidejte client id a secret, aby se lidé mohli přihlásit.';

  @override
  String get providerAppSignInOnly =>
      'Lidé se můžou přihlásit. Práce na pozadí spadne na jejich přihlašovací údaje.';

  @override
  String providerAppInstalledOn(String accounts) {
    return 'Přihlašovací údaje fungují. Nainstalováno na: $accounts';
  }

  @override
  String deviceCodeInstructions(String provider) {
    return 'Zadejte tento kód na stránce $provider, která se právě otevřela. Byl zkopírován do schránky.';
  }

  @override
  String get deviceCodeWaiting => 'Čeká se, až dokončíte v prohlížeči…';

  @override
  String get copyCodeAndOpen => 'Kopírovat kód a otevřít';

  @override
  String get couldNotOpenBrowser =>
      'Žádný prohlížeč se nepodařilo otevřít. Zkopírujte odkaz a přihlášení dokončete sami.';

  @override
  String get contextUsage => 'Využití kontextu';

  @override
  String get contextUsageFull => 'plné';

  @override
  String get contextUsageTokens => 'tokeny';

  @override
  String get contextSeeMore => 'Zobrazit více';

  @override
  String get contextSegmentSystemPrompt => 'Systémový prompt';

  @override
  String get contextSegmentRules => 'Pravidla';

  @override
  String get contextSegmentSkills => 'Dovednosti';

  @override
  String get contextSegmentToolDefinitions => 'Definice nástrojů';

  @override
  String get contextSegmentMcpTools => 'MCP a dynamické nástroje';

  @override
  String get contextSegmentDeferredTools => 'Nástroje načtené na vyžádání';

  @override
  String get contextSegmentSubagents => 'Definice subagentů';

  @override
  String get contextSegmentMemory => 'Paměť';

  @override
  String get contextSegmentConversation => 'Konverzace';

  @override
  String get contextExplorerTitle => 'Kontext';

  @override
  String get contextExplorerEverything => 'Všechno';

  @override
  String get contextExplorerSelectPart =>
      'Vyberte část a prohlédněte její obsah';

  @override
  String get contextExplorerUnavailable => 'Rozklad kontextu není k dispozici';

  @override
  String get contextRetry => 'Zopakovat';

  @override
  String get settingsFieldOptional => 'Volitelné';

  @override
  String get settingsFilterHint => 'Filtrovat tento seznam';

  @override
  String get settingsValueNotAvailable => 'Zatím není k dispozici';

  @override
  String get settingsNoEntriesYet => 'Zatím nic';

  @override
  String get settingsChangedBadge => 'Změněno';

  @override
  String get ssoConnectionCardDescription =>
      'Zvolte, jak se lidé k tomuto serveru přihlašují, a pak to připojení zapněte.';

  @override
  String get ssoUseSamlForSignIn => 'Použít SAML k přihlášení';

  @override
  String get ssoUseOidcForSignIn => 'Použít OpenID Connect k přihlášení';

  @override
  String get ssoSaveConnection => 'Uložit připojení';

  @override
  String get ssoStateLive => 'Živé';

  @override
  String get ssoStateConfiguredOff => 'Nastaveno, vypnuto';

  @override
  String get ssoStateOnIncomplete => 'Zapnuto, neúplné';

  @override
  String get ssoStateActive => 'Aktivní';

  @override
  String get ssoStateAllowed => 'Povoleno';

  @override
  String get ssoStateNoToken => 'Žádný token';

  @override
  String get ssoSummaryDirectorySync => 'Synchronizace adresáře';

  @override
  String get ssoSummaryManualPairing => 'Ruční párování';

  @override
  String get ssoNoMethodLiveNote =>
      'Žádná metoda přihlášení není živá. Nová zařízení se připojí pozvánkou nebo párovacím klíčem, dokud nenastavíte připojení a nezapnete ho.';

  @override
  String get ssoMethodSamlBlurb =>
      'Pro poskytovatele identity, kteří mluví SAML 2.0, například Okta, Entra ID nebo Google Workspace.';

  @override
  String get ssoMethodOidcBlurb =>
      'Pro poskytovatele identity, kteří mluví OpenID Connect. Obvykle jednodušší ze dvou na nastavení.';

  @override
  String get ssoGroupIdentityProvider => 'Poskytovatel identity';

  @override
  String get ssoGroupIdentityProviderSamlDescription =>
      'Odkud assertion přicházejí a jak je tento server ověřuje.';

  @override
  String get ssoGroupIdentityProviderOidcDescription =>
      'Kterému vydavateli tento server důvěřuje a jako který klient se autentizuje.';

  @override
  String get ssoSpEntityIdShortLabel => 'SP entity ID';

  @override
  String get ssoSpEntityIdDescription =>
      'Nechte prázdné a odvodí se z URL serveru.';

  @override
  String get ssoIssuerDescription =>
      'Základní URL, které servíruje discovery dokument poskytovatele.';

  @override
  String get ssoSecretStored => 'Uloženo';

  @override
  String get ssoGroupHandoff => 'Co váš poskytovatel identity potřebuje';

  @override
  String get ssoGroupHandoffDescription =>
      'Vložte je do aplikace, kterou jste u poskytovatele vytvořili.';

  @override
  String get ssoOriginUnknownTitle => 'Tento server nezná své veřejné URL';

  @override
  String get ssoOriginUnknownBody =>
      'URL přihlášení a callback se z něj skládají, takže poskytovatel tento server nedosáhne, dokud jedno nenastavíte. Přidejte veřejné URL nebo zapněte tunel pod Server → Připojení.';

  @override
  String get ssoAcsUrlLabel => 'URL assertion consumer service (ACS)';

  @override
  String get ssoAcsUrlDescription =>
      'Kam poskytovatel POSTuje podepsanou assertion.';

  @override
  String get ssoSpEntityIdResolvedLabel => 'Entity ID poskytovatele služby';

  @override
  String get ssoMetadataUrlLabel => 'URL metadat SP';

  @override
  String get ssoMetadataUrlDescription =>
      'Poskytovatelé, kteří importují metadata, je můžou stáhnout odtud.';

  @override
  String get ssoRedirectUriLabel => 'Redirect URI';

  @override
  String get ssoRedirectUriDescription =>
      'Přidejte toto k povoleným redirect URI aplikace poskytovatele.';

  @override
  String get ssoSignInUrlLabel => 'URL přihlášení';

  @override
  String get ssoSignInUrlDescription =>
      'Sem posílejte lidi, aby zahájili jednotné přihlášení.';

  @override
  String get ssoGroupAttributeMapping => 'Mapování atributů';

  @override
  String get ssoGroupAttributeMappingDescription =>
      'Který claim nese každé pole. Výchozí ponechte, pokud je poskytovatel nepřejmenoval.';

  @override
  String get ssoGroupAccess => 'Přístup a role';

  @override
  String get ssoGroupAccessDescription =>
      'Co smí ten, kdo se úspěšně přihlásí.';

  @override
  String get ssoDefaultRoleShortLabel => 'Výchozí role';

  @override
  String get ssoDefaultRoleDescription =>
      'Dostane ji kdokoli, jehož skupiny se neshodují s mapováním níže.';

  @override
  String get ssoRoleMapShortLabel => 'Mapování skupiny na roli';

  @override
  String get ssoRoleMapDescription =>
      'Platí první shodující se skupina. Vlastníka takto udělit nelze.';

  @override
  String get ssoRoleMapGroupHint => 'Název skupiny od poskytovatele';

  @override
  String get ssoRoleMapAdd => 'Přidat mapování';

  @override
  String get ssoRoleMapEmpty =>
      'Žádná mapování — všichni dostanou výchozí roli.';

  @override
  String get ssoAdvancedSummary =>
      'Odchylka hodin, IdP-iniciované přihlášení, politika podpisů';

  @override
  String get ssoClockSkewShortLabel => 'Odchylka hodin';

  @override
  String get ssoClockSkewDescription =>
      'Sekundy tolerance u časových razítek assertion. 90 vyhoví většině poskytovatelů.';

  @override
  String get ssoScimGenerate => 'Vygenerovat token';

  @override
  String get ssoScimTokenOnceBody =>
      'Zkopírováno do schránky. Zobrazí se jednou a nelze ho obnovit, takže ho teď vložte k poskytovateli.';

  @override
  String get ssoPairingCardTitle => 'Ruční párování';

  @override
  String get ssoPairingCardDescription =>
      'Druhá cesta na tento server: kódy pozvánek a párovací klíče, pro zařízení, která nejdou přes jednotné přihlášení.';

  @override
  String settingsCountOfTotal(int count, int total) {
    return '$count z $total';
  }

  @override
  String get providersNoneConnectedNote =>
      'Žádný poskytovatel není připojen, takže vestavěný runtime agenta nemá na čem běžet. Přidejte API klíč nebo se k jednomu níže přihlaste.';

  @override
  String get providersFilterHint => 'Filtrovat poskytovatele';

  @override
  String get providersNoneMatch => 'Nic neodpovídá tomuto filtru';

  @override
  String get providerDeniedHereTitle => 'V tomto pracovním prostoru zakázáno';

  @override
  String get providerDeniedHereBody =>
      'Agenti tady tohoto poskytovatele nemůžou použít, i když je připojen. Ostatní pracovní prostory zůstanou nedotčené.';

  @override
  String get providerNeedsSignIn =>
      'Přihlaste se a použijte tohoto poskytovatele';

  @override
  String get providerNeedsApiKey =>
      'Přidejte API klíč a použijte tohoto poskytovatele';

  @override
  String get providerApiKeyLabel => 'API klíč';

  @override
  String get providerGenerationDefaults => 'Výchozí poskytovatele';

  @override
  String get providerNoModelsYet =>
      'Zatím nejsou nahlášeny žádné modely. Připojte poskytovatele a synchronizujte.';

  @override
  String get providerModelsFilterHint => 'Filtrovat modely';

  @override
  String get adaptersNoneReadyNote =>
      'Na tomto stroji nebyl nalezen žádný katalogový CLI runner. Nainstalujte jeden a obnovte.';

  @override
  String get adaptersFilterHint => 'Filtrovat runnery';

  @override
  String get adaptersLaunchGroup => 'Spuštění';

  @override
  String get adaptersLaunchGroupDescription =>
      'Co tento runner dostane, když ho agent spustí. Můžete to nastavit ještě před instalací CLI.';

  @override
  String get adaptersEnvNone => 'Nic nastaveno';

  @override
  String adaptersEnvCount(int count) {
    return '$count nastaveno';
  }

  @override
  String get adapterArgumentsDescription =>
      'Připojí se k příkazové řádce runneru při každém spuštění.';

  @override
  String get defaultChatDescription =>
      'Spouští nové konverzace a každého agenta bez vlastního runneru.';

  @override
  String get shortTaskDescription =>
      'Spouští rychlou práci na pozadí, například názvy a shrnutí. Patří sem menší model.';

  @override
  String get settingsStateFailed => 'Selhalo';

  @override
  String get providerAppsGroupServer => 'Jednání jako server';

  @override
  String get providerAppsGroupServerDescription =>
      'Pro workspacy, které dědí GitHub App této instalace. Workspace s vlastní App nebo PAT se nastavuje v Workspace → Obecné.';

  @override
  String get providerAppsGroupPrConversations => 'Konverzace pull requestů';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      'Jak vývojáři mluví s tímto serverem na GitHubu v děděných workspacích. Workspace s vlastní App má bota v Workspace → Obecné. Funguje bez webhooku a veřejné URL — server polluje.';

  @override
  String get providerAppBotLogin => 'Přihlášení bota';

  @override
  String get providerAppBotLoginEmpty =>
      'Otestujte připojení a vyřešte přihlášení bota.';

  @override
  String get providerAppAskOnGitHub => 'Ptaní na GitHub';

  @override
  String get providerAppAskOnGitHubHint =>
      'Zmiňte přihlášení bota výše v komentáři pull requestu — přípona [bot] je volitelná — a požádejte o kontrolu nebo položte otázku, odpovězte v jeho vláknech kontroly, nebo přidejte štítek `ai-review` a požádejte o kontrolu.';

  @override
  String get providerAppsGroupSignIn => 'Přihlašování lidí';

  @override
  String get providerAppsGroupSignInDescription =>
      'Umožní každému členovi připojit vlastní účet a získat vlastní přihlašovací údaje.';

  @override
  String get providerAppCapActsAsServer => 'Jedná jako server';

  @override
  String get providerAppCapSignsIn => 'Přihlašuje lidi';

  @override
  String get portLabel => 'Port';

  @override
  String get mcpNoTokenWarning =>
      'Bez tokenu může cokoli, co dosáhne tohoto portu, volat každý nástroj.';

  @override
  String get mcpBridgedToolsLabel => 'Nástroje';

  @override
  String get guardrailFamilyFiles => 'Soubory';

  @override
  String get guardrailFamilyGit => 'Git a pull requesty';

  @override
  String get guardrailFamilyMachine => 'Stroj a síť';

  @override
  String get guardrailFamilyControl => 'Tajemství a pracovní prostor';

  @override
  String get guardrailScopeFieldLabel => 'Úprava pravidel pro';

  @override
  String get guardrailScopeFieldDescription =>
      'Užší rozsah vyhraje nad širším. Pravidla nastavená tady platí navíc ke zděděným.';

  @override
  String get guardrailSetHere => 'Nastaveno tady';

  @override
  String get guardrailClearAllHere => 'Vymazat vše';

  @override
  String get sandboxingCardLabel => 'Sandboxing';

  @override
  String get sandboxingCardDescription =>
      'Zda práce agenta běží izolovaně od tohoto hostitele a co izolovaný agent ještě může dosáhnout.';

  @override
  String get sandboxBackendNoneActive => 'Hostitel, bez izolace';

  @override
  String get sandboxSummaryHost => 'Hostitel';

  @override
  String get sandboxGroupIsolation => 'Izolace';

  @override
  String get sandboxGroupIsolationDescription =>
      'Kde se procesy agenta a zápisy souborů skutečně dějí.';

  @override
  String get sandboxBackendFieldDescription =>
      'Auto vybere nejsilnější, který tento hostitel podporuje. Připněte jeden, aby se pod vámi neměnil.';

  @override
  String get sandboxCapabilitiesDescription =>
      'Díry proražené hranicí. Každá je něco, co izolovaný agent pořád může udělat vnějšímu světu.';

  @override
  String get sandboxSummaryInForce => 'V platnosti';

  @override
  String get rigsInstallHintLabel => 'Jak to nainstalovat';

  @override
  String get rigsStarting => 'Spouštění';

  @override
  String get rigsResidentMemory => 'Rezidentní paměť';

  @override
  String get installedLabel => 'Nainstalováno';

  @override
  String get notInstalledLabel => 'Není nainstalováno';

  @override
  String ssoOtherKindUnsaved(String method) {
    return '$method má neuložené změny';
  }

  @override
  String get collapseComment => 'Sbalit komentář';

  @override
  String get expandComment => 'Rozbalit komentář';

  @override
  String get suggestedChange => 'Navržená změna';

  @override
  String get emptyComment => 'Prázdný komentář';

  @override
  String repliesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count odpovědí',
      many: '$count odpovědí',
      few: '$count odpovědi',
      one: '1 odpověď',
    );
    return '$_temp0';
  }

  @override
  String get pendingReview => 'Čekající kontrola';

  @override
  String failedToResolveConversation(String error) {
    return 'Konverzaci se nepodařilo aktualizovat: $error';
  }

  @override
  String get addSingleComment => 'Přidat jeden komentář';

  @override
  String get addToReview => 'Přidat ke kontrole';

  @override
  String get startAReview => 'Zahájit kontrolu';

  @override
  String get reviewNeedsABody =>
      'Nejprve napište shrnutí nebo zařaďte inline komentář';

  @override
  String get reviewSubmitted => 'Kontrola odeslána';

  @override
  String get finishYourReview => 'Dokončit kontrolu';

  @override
  String get commentVerdict => 'Komentář';

  @override
  String pendingCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count čekajících komentářů',
      many: '$count čekajících komentářů',
      few: '$count čekající komentáře',
      one: '1 čekající komentář',
    );
    return '$_temp0';
  }

  @override
  String andNMore(int count) {
    return 'a $count dalších';
  }

  @override
  String get queuedCommentHint =>
      'Tento komentář se odešle, až odešlete kontrolu.';

  @override
  String commentOnLinesRange(int start, int end) {
    return 'Řádky $start až $end';
  }

  @override
  String get claudeAccountsTitle => 'Účty Claude Code';

  @override
  String get claudeAccountsDescription =>
      'Každý účet je samostatné přihlášení Claude Code. Běhy používají účty připojené níže, v tomto pořadí.';

  @override
  String get claudeAccountsEmpty => 'Zatím žádné účty';

  @override
  String get claudeAccountAdd => 'Přidat účet';

  @override
  String get claudeAccountSignIn => 'Přihlásit se';

  @override
  String get claudeAccountSignInAgain => 'Přihlásit se znovu';

  @override
  String get claudeAccountSignInHint =>
      'Spusťte toto v terminálu na serveru. Otevře prohlížeč k dokončení přihlášení a zapíše přihlašovací údaje do adresáře tohoto účtu.';

  @override
  String get claudeAccountSignedOut => 'Odhlášeno';

  @override
  String get claudeAccountExpired => 'Přihlášení vypršelo';

  @override
  String claudeAccountExpiredDetail(String when) {
    return 'Přihlášení vypršelo v $when. Přihlaste se znovu a tento účet použijte.';
  }

  @override
  String get claudeAccountMakeDefault => 'Nastavit jako výchozí';

  @override
  String get claudeAccountDefault => 'Výchozí';

  @override
  String claudeAccountRemoveConfirm(String label) {
    return 'Odebrat $label?';
  }

  @override
  String get claudeAccountRemoveDetail =>
      'Tím se účet odhlásí a smaže se jeho adresář na serveru. Samotné přihlášení to neovlivní.';

  @override
  String claudeAccountStatusUnknown(String error) {
    return 'Tento účet se nepodařilo zkontrolovat: $error';
  }

  @override
  String claudeAccountUsedPercent(String percent) {
    return 'využito $percent %';
  }

  @override
  String get accountPoolStrategy => 'Rotace';

  @override
  String get accountPoolPinned => 'Připnuto';

  @override
  String get accountPoolRoundRobin => 'Round robin';

  @override
  String get accountPoolSerial => 'Jeden po druhém';

  @override
  String get accountPoolPinnedHint =>
      'Vždy začít na prvním účtu. Ostatní zůstanou jako záloha, pokud selže.';

  @override
  String get accountPoolRoundRobinHint =>
      'Rozložit běhy mezi účty a při každém odeslání přejít na další.';

  @override
  String get accountPoolSerialHint =>
      'Vyčerpat první účet, než se sáhne na další.';

  @override
  String get accountPoolMoveUp => 'Posunout nahoru';

  @override
  String get accountPoolMoveDown => 'Posunout dolů';

  @override
  String get accountPoolUsingAll =>
      'Zatím nic není připojeno — použijí se všechny účty, v tomto pořadí.';

  @override
  String get accountPoolInheriting => 'Dědí účty pracovního prostoru.';

  @override
  String get accountPoolResetToWorkspace => 'Obnovit účty pracovního prostoru';

  @override
  String accountPoolCoolingOff(String when) {
    return 'mimo kvótu do $when';
  }

  @override
  String get accountPoolSignedOut => 'odhlášeno';

  @override
  String get accountPoolExpired => 'přihlášení vypršelo';

  @override
  String accountPoolLoadFailed(String error) {
    return 'Rotaci se nepodařilo načíst: $error';
  }

  @override
  String get providerSignedInAccount => 'přihlášený účet';

  @override
  String get agentAccountsTab => 'Účty';

  @override
  String get agentClaudeAccountsNoticeTitle => 'Více účtů Claude Code';

  @override
  String agentClaudeAccountsNoticeBody(int count) {
    return 'Tento runner se přihlašuje jako jeden z $count účtů Claude Code na tomto hostiteli. Který, nebo rotaci mezi nimi, vyberte na kartě Účty.';
  }

  @override
  String get agentAccountsDescription =>
      'Které účty používají běhy tohoto agenta. Každý blok začíná děděním volby pracovního prostoru.';

  @override
  String get agentAccountsNothingToRotate =>
      'Není co rotovat — nejprve připojte druhý účet nebo klíč.';

  @override
  String failedToPostReply(String error) {
    return 'Odpověď se nepodařilo odeslat: $error';
  }

  @override
  String commentOnLine(int line) {
    return 'Řádek $line';
  }

  @override
  String get viewInDiff => 'Zobrazit v diffu';

  @override
  String get subscriptionUsagePreviousAccount => 'Předchozí účet';

  @override
  String get subscriptionUsageNextAccount => 'Další účet';

  @override
  String inReplyTo(String path) {
    return 'V odpovědi na $path';
  }

  @override
  String get subscriptionUsageNoneReported =>
      'Pro tento účet není nahlášeno žádné využití.';

  @override
  String get subscriptionUsageCredits => 'Kredity';

  @override
  String get reviewHubStaticRule => 'Statické pravidlo';

  @override
  String get reviewHubStarted => 'Kontrola spuštěna';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return 'Nalezeno deterministickým pravidlem ($rule) na řádku, který tento pull request přidává — ne recenzentem-agentem.';
  }

  @override
  String get prReviewArtifactTab => 'Kontrola PR';

  @override
  String get prReviewRunning => 'Kontrola tohoto pull requestu…';

  @override
  String get prReviewStarting => 'Spouštění kontroly…';

  @override
  String get prReviewStartingBody =>
      'Příprava worktree tohoto pull requestu. Recenzenti startují, jakmile bude připravený.';

  @override
  String get prReviewFailed => 'Kontrola selhala.';

  @override
  String get prReviewRerunning => 'Opakovaná kontrola…';

  @override
  String get prReviewNoOpenFindings => 'Žádná otevřená zjištění';

  @override
  String prReviewOpenFindings(int count) {
    return '$count otevřených zjištění';
  }

  @override
  String subscriptionUsageSpend(String used, String limit) {
    return '$used z $limit';
  }

  @override
  String reviewCommentsPosted(int posted, int skipped, int failed) {
    return 'Odesláno $posted komentář(ů) jako bot. $skipped přeskočeno (žádná kotva souboru), $failed selhalo.';
  }

  @override
  String reviewFindingsOutOfDiff(int count, String files) {
    return '$count zjištění cílí na kód, který tento pull request nemění ($files). GitHub přijímá inline komentáře jen na diff.';
  }

  @override
  String get reviewRailReport => 'Report';

  @override
  String get reviewNoFindingsTitle => 'Zatím žádná zjištění kontroly';

  @override
  String get reviewNoFindingsHint =>
      'Zjištění se tu objeví, jak je agenti odešlou.';

  @override
  String reviewShowDismissed(int count) {
    return 'Zobrazit $count zamítnutých';
  }

  @override
  String reviewHideDismissed(int count) {
    return 'Skrýt $count zamítnutých';
  }

  @override
  String reviewDisagreementsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zjištěno $count nesouhlasů recenzentů',
      many: 'Zjištěno $count nesouhlasů recenzentů',
      few: 'Zjištěny $count nesouhlasy recenzentů',
      one: 'Zjištěn 1 nesouhlas recenzentů',
    );
    return '$_temp0';
  }

  @override
  String get reviewFilterKind => 'Druh';

  @override
  String get reviewFilterStatus => 'Stav';

  @override
  String get reviewKindBug => 'Chyba';

  @override
  String get reviewKindSuggestion => 'Návrh';

  @override
  String get reviewKindRecommendation => 'Doporučení';

  @override
  String get reviewKindQuestion => 'Otázka';

  @override
  String get reviewKindTicket => 'Ticket';

  @override
  String get archiveSpace => 'Archivovat prostor';

  @override
  String get archivedSpaces => 'Archivované prostory';

  @override
  String get archivedSpacesEmpty => 'Žádné archivované prostory';

  @override
  String get restoreSpace => 'Obnovit';

  @override
  String archivedWhen(String time) {
    return 'Archivováno $time';
  }

  @override
  String get deleteSpacePermanently => 'Smazat trvale';

  @override
  String get renameSpace => 'Přejmenovat prostor';

  @override
  String get renameConversation => 'Přejmenovat konverzaci';

  @override
  String get spaceActions => 'Akce prostoru';

  @override
  String get conversationActions => 'Akce konverzace';

  @override
  String get editSpaceRepos => 'Upravit repozitáře';

  @override
  String get editSpaceReposTitle => 'Repozitáře prostoru';

  @override
  String get editSpaceReposWarning =>
      'Přidání repozitáře ho checkne do tohoto prostoru; odebrání smaže jeho složku.';

  @override
  String get agentSectionIdentity => 'Identita';

  @override
  String get agentSectionRuntime => 'Runtime';

  @override
  String get agentSectionGuardrails => 'Ochranná pravidla';

  @override
  String orgChartReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count podřízených',
      many: '$count podřízených',
      few: '$count podřízení',
      one: '1 podřízený',
    );
    return '$_temp0';
  }

  @override
  String get teamsFilterHint => 'Filtrovat týmy…';

  @override
  String get teamsSummaryWithLeader => 'S vedoucím';

  @override
  String teamCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count týmů',
      many: '$count týmů',
      few: '$count týmy',
      one: '1 tým',
      zero: 'Žádné týmy',
    );
    return '$_temp0';
  }

  @override
  String agentDeleteLongDescription(String name) {
    return 'Smazání $name odebere jeho profil, odkazy na dovednosti a historii běhů. Tuto akci nelze vrátit zpět.';
  }

  @override
  String get resetToDefault => 'Obnovit výchozí';

  @override
  String get newAgent => 'Nový agent';

  @override
  String get newSkill => 'Nová dovednost';

  @override
  String get zoomIn => 'Přiblížit';

  @override
  String get zoomOut => 'Oddálit';

  @override
  String get resetZoom => 'Obnovit přiblížení';

  @override
  String get imageHostedOnGitHub => 'Obrázek hostovaný na GitHub';

  @override
  String get imageOpenExternally => 'Obrázek · otevřít externě';

  @override
  String get memoryScopeAll => 'Všechny rozsahy';

  @override
  String get memoryScopeWorkspace => 'Celý pracovní prostor';

  @override
  String get memoryScopeFilterLabel => 'Filtrovat podle rozsahu';

  @override
  String memoryScopeRepoTooltip(String repo) {
    return 'Rozsah omezen na repozitář $repo';
  }

  @override
  String get toolScreenshot => 'Snímek obrazovky od agenta';

  @override
  String get toolImageUnavailable => 'Obrázek není k dispozici';

  @override
  String toolImagesUnavailable(int count) {
    return '$count obrázků není k dispozici';
  }

  @override
  String get shakeUnavailable => 'Protřepání na tomto serveru není k dispozici';

  @override
  String get shakeNothing => 'Není co protřepat — nedávné tahy jsou chráněné';

  @override
  String shakeDone(int tokens) {
    return 'Uvolněno asi $tokens tokenů';
  }

  @override
  String get compactionDivider => 'Zkomprimováno';

  @override
  String compactionDividerCount(int count) {
    return 'Zkomprimováno · sbaleno $count zpráv';
  }

  @override
  String get composerDropToAttach => 'Pusťte pro přiložení';

  @override
  String get attachmentUnavailable => 'Příloha není k dispozici';

  @override
  String get attachmentUnavailableDetail =>
      'Tato příloha už není v paměti. Přiložte ji znovu a uvidíte náhled.';

  @override
  String get attachmentPreviewFailed => 'Tento soubor se nepodařilo otevřít';

  @override
  String get attachmentPreviewUnsupported =>
      'Pro tento typ souboru není náhled';

  @override
  String get attachmentTooLargeToPreview => 'Příliš velké k náhledu';

  @override
  String get attachmentOpenExternally => 'Otevřít ve výchozí aplikaci';

  @override
  String get asideUnavailable =>
      'Pro použití nastavte jednorázový model v nastavení pracovního prostoru';

  @override
  String get asideEmpty => 'Zatím není z čeho vycházet';

  @override
  String get asideFailed => 'Odpověď se nepodařilo získat';

  @override
  String get handoffTitle => 'Předání';

  @override
  String get asideTitle => 'Vedlejší otázka';

  @override
  String get attachFilesOrDrop => 'Přiložit soubory — nebo je sem pusťte';

  @override
  String get guidedGoalTitle => 'Zpřesnit cíl';

  @override
  String get guidedGoalIntro =>
      'Agent pracující bez dohledu musí přesně vědět, kdy je hotovo. Nejdřív pár otázek.';

  @override
  String get guidedGoalAnswerHint => 'Vaše odpověď';

  @override
  String get guidedGoalNext => 'Další';

  @override
  String get guidedGoalStart => 'Spustit cíl';

  @override
  String get guidedGoalSkip => 'Přeskočit a spustit jak je napsáno';

  @override
  String guidedGoalStillMissing(String items) {
    return 'Stále nespecifikováno: $items';
  }

  @override
  String get conversationTreeTitle => 'Strom konverzace';

  @override
  String conversationTreeBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count větví',
      many: '$count větví',
      few: '$count větve',
      one: '1 větev',
    );
    return '$_temp0';
  }

  @override
  String get conversationTreeSwitch => 'Pokračovat odtud';

  @override
  String get conversationTreeFork => 'Rozvětvit do nové konverzace';

  @override
  String get conversationTreeCurrent => 'Na této větvi';

  @override
  String get conversationTreeEmpty => 'Zatím nic';

  @override
  String get conversationTreeForked => 'Rozvětveno do nové konverzace';

  @override
  String get conversationTreeSwitched => 'Teď se pokračuje od té zprávy';

  @override
  String exportSaved(String path) {
    return 'Uloženo do $path';
  }

  @override
  String get exportFailed => 'Export se nepodařilo zapsat';

  @override
  String get contextCommandNoAgent =>
      'V této konverzaci není agent, takže není co otevřít jako kontextové okno';

  @override
  String contextCommandNoSuchAgent(String name, String names) {
    return 'V této konverzaci není agent jménem „$name“. Zkuste: $names';
  }

  @override
  String get dumpCopied => 'Přepis zkopírován do schránky';

  @override
  String get messageQueueHint => 'Pište dál a zařaďte následné změny';

  @override
  String get steerNow => 'Usměrnit';

  @override
  String get steeringQueueLabel => 'Zařazené usměrňující zprávy';

  @override
  String get steeringDeliverUnavailable =>
      'Žádný běžící agent to teď nemůže přijmout — zůstane ve frontě.';

  @override
  String get reorderSteeringCard => 'Změnit pořadí zařazené zprávy';

  @override
  String get editSteeringCard => 'Upravit zařazenou zprávu';

  @override
  String get deleteSteeringCard => 'Smazat zařazenou zprávu';

  @override
  String get steeringBadge => 'Usměrněno';

  @override
  String get settingsSandboxLabel => 'Sandbox';

  @override
  String get sandboxExecGrantsTitle => 'Povolení spustitelných souborů';

  @override
  String get sandboxExecGrantsSubtitle =>
      'Programy, které agenti smí spouštět ze své pracovní kopie vašich repozitářů. Každou položku jste schválili, když se sandbox zeptal.';

  @override
  String get sandboxExecGrantsEmpty =>
      'Zatím žádná rozhodnutí. Zeptáme se, až agent bude poprvé potřebovat spustit program ze své pracovní kopie.';

  @override
  String get sandboxExecGrantRevoke => 'Odvolat';

  @override
  String get sandboxExecGrantAllowed => 'Povoleno';

  @override
  String get sandboxExecGrantBlocked => 'Blokováno';

  @override
  String get sandboxExecGrantRevokeConfirmTitle => 'Odvolat toto rozhodnutí?';

  @override
  String get sandboxExecGrantRevokeConfirmBody =>
      'Příště, až agent bude potřebovat spustit program z této kopie, se zeptáme znovu.';

  @override
  String get repoScriptsTest => 'Test';

  @override
  String get repoScriptsTestTooltip =>
      'Spustit tento koncept v jednorázovém klonu repozitáře';

  @override
  String get repoScriptsRunKindTest => 'Test';

  @override
  String get demoBadgeLabel => 'Demo';

  @override
  String get demoFilePickerTitle => 'Soubory dema';

  @override
  String get demoFilePickerBody =>
      'Demo nahrávání předstírá: vyberte kterýkoli a přiloží se ke zprávě, aniž by se sahalo na disk.';

  @override
  String get demoFilePickerAttach => 'Přiložit';

  @override
  String get demoReadOnlySave => 'V demu jen pro čtení';

  @override
  String get demoBadgeTooltip =>
      'Prohlížíte demo. Data jsou fiktivní a agenti jsou skriptovaní.';

  @override
  String get demoFirstRunTitle => 'Jste v živém demu';

  @override
  String demoFirstRunBody(int minutes) {
    return 'Tohle je skutečná aplikace na skutečném kódu — vymyšlená jsou jen data. Agenti streamují skutečné běhy ze skriptu, takže nic nedojde k modelu a nic neběží na stroji. Váš pracovní prostor je jen váš a po $minutes minutách zmizí.';
  }

  @override
  String get demoFirstRunDismiss => 'Rozumím';

  @override
  String get demoTourTitle => 'Kam se podívat nejdřív';

  @override
  String get demoTourSubtitle =>
      'Čtyři místa, která ukazují, co aplikace skutečně dělá.';

  @override
  String get demoTourSkip => 'Přeskočit';

  @override
  String get demoTourStarRepo => 'Označit hvězdou na GitHub';

  @override
  String get demoTourOpen => 'Otevřít';

  @override
  String get demoTourSpacesTitle => 'Mluvit s agentem';

  @override
  String get demoTourSpacesBody =>
      'Pošlete zprávu v prostoru a sledujte stream běhu — přemýšlení, volání nástrojů a náklady, přesně jak se vykresluje skutečný běh.';

  @override
  String get demoTourReviewTitle => 'Zkontrolovat pull request';

  @override
  String get demoTourReviewBody =>
      'Otevřete #412. Nechte inline komentář nebo odešlete kontrolu; vaše slova skončí ve vlákně a zůstanou tam.';

  @override
  String get demoTourTicketsTitle => 'Sledovat práci';

  @override
  String get demoTourTicketsBody =>
      'Tickety, úkoly a plány jsou propojené se stejnými konverzacemi, které agenti vedou.';

  @override
  String get demoTourInboxTitle => 'Vidět celý provoz';

  @override
  String get demoTourInboxBody =>
      'Každé upozornění z každého pilíře skončí v jedné doručené poště — kontroly, tickety, běhy a schůzky.';

  @override
  String get demoUnavailableTitle => 'V demu není k dispozici';

  @override
  String get demoUnavailableTerminal =>
      'Terminál spouští skutečný shell na hostiteli serveru. Demo nemá žádný povrch spouštění — proto je bezpečné ho otevřít veřejnosti.';

  @override
  String get demoUnavailableRig =>
      'Izolované prostředí je jednorázový virtuální stroj, který agent řídí. Demo žádný nespustí: veřejný endpoint, který umí startovat VM, není demo.';

  @override
  String get demoUnavailableEditor =>
      'Editor v prohlížeči spouští proces code-server proti skutečnému checkoutu. Demo nemá ani jedno.';

  @override
  String get demoUnavailableFeeds =>
      'Demo čte skutečné kanály, ale seznam odběrů je pevný. Přidávání nebo odebírání je tady vypnuté.';

  @override
  String get demoUnavailableForge =>
      'Demo nedrží žádné přihlašovací údaje a nikdy nekontaktuje GitHub, GitLab ani Linear. Jeho pull requesty jsou fixture a vaše komentáře k nim se ukládají lokálně.';

  @override
  String get demoUnavailableModels =>
      'Demo nevolá žádný model. Běhy agentů jsou skriptované přehrávání, proto nic nestojí a k žádnému poskytovateli nedojdou.';

  @override
  String get demoUnavailableMcp =>
      'Povrch nástrojů MCP na demu není namontovaný, takže se k němu nemůže připojit žádný externí klient.';

  @override
  String get demoUnavailableRepos =>
      'Demo necheckuje žádný kód a nespouští git. Repozitář, který vidíte, je fixture za pull requesty.';

  @override
  String get demoUnavailableSkills =>
      'Instalace dovednosti stáhne a naskenuje kód. Demo nic nenačítá.';

  @override
  String get demoUnavailableSso =>
      'Jednotné přihlášení je konfigurace serveru. Demo vás místo toho přihlásí jako dočasného hosta.';

  @override
  String get demoUnavailableAudio =>
      'Nahrávání a diktování potřebují snímání zvuku a řečový model na hostiteli. Demo nemá ani jedno, takže jeho schůzky jsou přepisy bez přehrávání.';

  @override
  String get demoUnavailableServerAdmin =>
      'Tohle je správa serveru. Demo dá každému návštěvníkovi vlastní jednorázový pracovní prostor a nic mimo něj.';

  @override
  String get demoUnavailablePipelines =>
      'Pipeline zde nelze spouštět. Návštěvník, který dokáže napsat krok bash a spustit ho — ručně nebo přes spouštěč události — spouští kód na tomto hostiteli.';

  @override
  String get settingsBackupRestore => 'Záloha a obnovení';

  @override
  String get settingsBackupRestoreDescription =>
      'Snímky každé databáze na tomto serveru plus export, import a smazání jednoho pracovního prostoru.';

  @override
  String get backupSnapshotsLabel => 'Snímky instalace';

  @override
  String get backupSnapshotsExplainer =>
      'Snímek zkopíruje každou databázi do složky s časovým razítkem na hostiteli serveru. Obnovení celé instalace znamená zkopírovat tu složku zpět se zastaveným serverem; jeden pracovní prostor lze obnovit odtud.';

  @override
  String get backupNowAction => 'Zálohovat teď';

  @override
  String backupSnapshotWritten(String path) {
    return 'Snímek zapsán do $path';
  }

  @override
  String get backupNoSnapshots =>
      'Zatím žádné snímky. Jeden se pořídí, jen když o něj požádáte — nic se neplánuje.';

  @override
  String get backupSnapshotComplete => 'Úplný';

  @override
  String get backupSnapshotIncomplete => 'Neúplný';

  @override
  String get backupSnapshotIncompleteNote =>
      'Manifest chybí nebo jmenuje soubory, které tam nejsou, takže tento snímek nemůže obnovit celou instalaci. Soubory pracovních prostorů, které má, lze pořád převzít jeden po druhém.';

  @override
  String backupSnapshotWorkspaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pracovních prostorů',
      many: '$count pracovních prostorů',
      few: '$count pracovní prostory',
      one: '1 pracovní prostor',
      zero: 'Žádné pracovní prostory',
    );
    return '$_temp0';
  }

  @override
  String backupSnapshotSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pracovních prostorů nezachyceno',
      many: '$count pracovních prostorů nezachyceno',
      few: '$count pracovní prostory nezachyceny',
      one: '1 pracovní prostor nezachycen',
    );
    return '$_temp0';
  }

  @override
  String get backupServerPathLabel => 'Cesta na serveru';

  @override
  String get backupRestoreAction => 'Obnovit';

  @override
  String get backupRestoreTitle => 'Obnovit pracovní prostor';

  @override
  String backupRestoreBody(String name) {
    return 'Tím se všechno v $name nahradí kopií z tohoto snímku. Cokoli, co ten pracovní prostor od pořízení snímku udělal, se ztratí a nelze to vrátit zpět.';
  }

  @override
  String backupRestoreDone(String name) {
    return '$name obnoven ze snímku.';
  }

  @override
  String get backupWorkspaceUnknown => 'Na tomto serveru už není';

  @override
  String get backupWorkspaceDataLabel => 'Data pracovního prostoru';

  @override
  String get backupWorkspaceDataExplainer =>
      'Jeden pracovní prostor je jeden databázový soubor, takže export ho zkopíruje celý, ne tabulku po tabulce. Import nahradí všechno v cílovém pracovním prostoru souborem, který pojmenujete.';

  @override
  String get backupExportAction => 'Exportovat';

  @override
  String backupExportDone(String path) {
    return 'Exportováno do $path';
  }

  @override
  String get backupExportedFileLabel => 'Exportovaný soubor na serveru';

  @override
  String get backupImportAction => 'Importovat';

  @override
  String backupImportTitle(String name) {
    return 'Importovat do $name';
  }

  @override
  String backupImportBody(String name) {
    return 'Tím se všechno v $name nahradí obsahem souboru. Cokoli, co ten pracovní prostor teď drží, se ztratí a nelze to vrátit zpět.';
  }

  @override
  String get backupImportSourceLabel => 'Soubor databáze pracovního prostoru';

  @override
  String get backupImportSourceDescription =>
      'Soubor .db, který server umí číst. Cesty se řeší na hostiteli serveru, ne na tomto zařízení.';

  @override
  String backupImportDone(String name) {
    return 'Importováno do $name.';
  }

  @override
  String backupDeleteBody(String name) {
    return '$name zmizí z každého seznamu a vyhledávání. Jeho databázový soubor zůstane na disku, zálohy ho pořád obsahují a nic prostor automaticky neuvolní.';
  }

  @override
  String get backupExportDescription =>
      'Zapsat kopii na server, nebo stáhnout jednu na toto zařízení.';

  @override
  String get backupExportOnServerAction => 'Uložit na server';

  @override
  String get backupDownloadAction => 'Stáhnout';

  @override
  String backupDownloadSaved(String path) {
    return 'Uloženo do $path';
  }

  @override
  String get backupDownloadInBrowser => 'Prohlížeč to stahuje.';

  @override
  String get backupRestoreFromDeviceLabel => 'Obnovit z tohoto zařízení';

  @override
  String get backupRestoreFromDeviceDescription =>
      'Vyberte soubor databáze pracovního prostoru tady a Control Center ho nahraje na server. Tohle je ta cesta, která funguje, když server není tento stroj.';

  @override
  String get backupUploadAction => 'Vybrat soubor a nahrát';

  @override
  String get backupTransferUnavailable =>
      'Toto připojení dosahuje server přes relé, které nepřenáší soubory. Připojte se k serveru přímo a stáhněte nebo nahrajte zálohu.';

  @override
  String get backupTransferForbidden =>
      'Server odmítl. Stažení pracovního prostoru potřebuje roli admin, obnovení potřebuje vlastníka a celý snímek potřebuje operátora instalace.';

  @override
  String get backupTransferUnsupported => 'Tento server nemá povrch záloh.';

  @override
  String get backupTransferTooLarge => 'Soubor je větší, než server přijímá.';

  @override
  String get credentialGateWaitingTitle => 'Čeká se na přihlašovací údaje';

  @override
  String credentialGateHarnessTitle(String provider) {
    return '$provider nemá přihlašovací údaje';
  }

  @override
  String get credentialGateSignedOutTitle => 'Claude Code je odhlášen';

  @override
  String get credentialGateExpiredTitle =>
      'Vaše přihlášení Claude Code vypršelo';

  @override
  String get credentialGatePlanSpentTitle => 'Dosažen limit tarifu Claude Code';

  @override
  String credentialGateWaitingAgent(String agent) {
    return '$agent čeká na pokračování.';
  }

  @override
  String get credentialGateWaitingRun => 'Běh čeká na pokračování.';

  @override
  String get credentialGateWatching => 'Sleduje se oprava — běh pokračuje sám.';

  @override
  String credentialGateFreesUpAt(String time) {
    return 'Uvolní se v $time';
  }

  @override
  String credentialGateGivesUpAt(String time) {
    return 'Běh to vzdá v $time';
  }

  @override
  String get credentialGateCheckAgain => 'Zkontrolovat znovu';

  @override
  String get credentialGateCancelRun => 'Zrušit běh';

  @override
  String get credentialGateAccountsTried => 'Vyzkoušené účty';

  @override
  String get credentialGateClaudeSignInHint =>
      'Přihlaste se z Nastavení → Adaptéry → Claude Code, nebo spusťte přihlašovací příkaz v terminálu. Běh to zachytí sám.';

  @override
  String get credentialGateOpenSettings => 'Otevřít nastavení';

  @override
  String get selectModel => 'Vybrat model';

  @override
  String get allModels => 'Všechny modely';

  @override
  String get noModelsMatchSearch => 'Vašemu hledání neodpovídají žádné modely';

  @override
  String useCustomModelId(String id) {
    return 'Použít „$id“';
  }

  @override
  String get modelFree => 'Zdarma';

  @override
  String modelOutputTokens(String tokens) {
    return '$tokens výstup';
  }

  @override
  String modelPricePerMTokens(String input, String output) {
    return '$input vstup / $output výstup za 1M tokenů';
  }

  @override
  String modelEffortLevels(String levels) {
    return 'Úsilí uvažování: $levels';
  }

  @override
  String get modelSupportsReasoning => 'Podporuje úsilí uvažování';

  @override
  String get profileDeliveryMetrics => 'Metriky doručování';

  @override
  String profileMetricsSample(int count) {
    return 'Analyzované PR: $count';
  }

  @override
  String get profileMergeRate => 'Míra sloučení';

  @override
  String get profileReviewCoverage => 'Pokrytí kontrolami';

  @override
  String get profilePrSize => 'Velikost PR';

  @override
  String get profileTimeToMerge => 'Doba do sloučení';

  @override
  String get profileMergeTimeTrend => 'Trend doby sloučení';

  @override
  String get profileWeeklyMedian => 'Týdenní medián, logaritmická stupnice';

  @override
  String get profilePrOpeningPattern => 'Den v týdnu × hodina, místní čas';

  @override
  String get profileFirstReview => 'Doba do první kontroly';

  @override
  String get profileMetricsTruncated =>
      'Percentily používají omezený vzorek dostupných požadavků na přijetí změn.';

  @override
  String profileLinesChanged(String count) {
    return '$count řádků';
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
    return '$days d $hours h';
  }

  @override
  String profilePercentiles(String median, String p90) {
    return 'p50 $median · p90 $p90';
  }

  @override
  String profileTeamMembers(int count) {
    return 'Členové: $count';
  }

  @override
  String noPrsByTeamInWorkspace(String team) {
    return 'V tomto pracovním prostoru nejsou žádné pull requesty od týmu $team';
  }

  @override
  String get profilePrStateFilterLabel => 'Filtrovat pull requesty podle stavu';

  @override
  String get noProfilePrsMatchSearchHint =>
      'Zkuste jiný název nebo číslo pull requestu';

  @override
  String get rigNetworkUnrestricted => 'Síť bez omezení';

  @override
  String get rigNetworkAllowAllHosts => 'Povolit všechny hostitele';

  @override
  String get rigBrowserPermissionsTitle => 'Oprávnění webu';

  @override
  String get rigBrowserPermissionsTooltip => 'Oprávnění webu a síť';

  @override
  String get rigBrowserPermissionEmpty =>
      'Zatím žádný web nepožádal o oprávnění';

  @override
  String rigBrowserPermissionPrompt(String origin, String permission) {
    return '$origin chce použít $permission';
  }

  @override
  String get rigBrowserPermissionBlock => 'Blokovat';

  @override
  String get rigBrowserPermissionCamera => 'Kameru';

  @override
  String get rigBrowserPermissionMicrophone => 'Mikrofon';

  @override
  String get rigBrowserPermissionNotifications => 'Oznámení';

  @override
  String get rigBrowserPermissionGeolocation => 'Polohu';

  @override
  String get rigBrowserPermissionPersistentStorage => 'Trvalé úložiště';

  @override
  String get rigBrowserPermissionClipboard => 'Schránku';

  @override
  String get rigBrowserPermissionDisplayCapture => 'Snímek obrazovky';

  @override
  String get rigBrowserPermissionMidi => 'MIDI';

  @override
  String get rigNetworkBypassTitle => 'Povolit všechny síťové hostitele?';

  @override
  String get rigNetworkBypassBody =>
      'Tímto se restartuje izolované prostředí a zahodí se nepotvrzená práce uvnitř. Host pak bude moci přistupovat ke všem síťovým hostitelům, dokud nebude prostředí zavřeno.';

  @override
  String get rigNetworkRestartUnrestricted => 'Restartovat bez omezení';

  @override
  String get rigNetworkUnrestrictedBody =>
      'Toto izolované prostředí může přistupovat ke všem síťovým hostitelům. Zavřete ho a otevřete nové, chcete-li obnovit výchozí omezení.';

  @override
  String get rigNetworkAlreadyUnrestrictedBody =>
      'Tento emulátor Androidu už spravuje vlastní síť, takže Control Center nemůže vynutit seznam povolených hostitelů. Restart není potřeba.';

  @override
  String get rigClipboardPermissionHostToRigTitle =>
      'Vložit schránku do tohoto kontejneru?';

  @override
  String get rigClipboardPermissionHostToRigBody =>
      'Control Center přečte schránku vašeho zařízení a odešle její obsah do kontejneru. Obsah schránky může obsahovat hesla nebo jiné tajné údaje.';

  @override
  String get rigClipboardPermissionRigToHostTitle =>
      'Zkopírovat schránku z tohoto kontejneru?';

  @override
  String get rigClipboardPermissionRigToHostBody =>
      'Control Center přečte schránku kontejneru a nahradí schránku vašeho zařízení jejím obsahem. S obsahem z kontejneru zacházejte jako s nedůvěryhodným.';

  @override
  String get rigClipboardAllowTenMinutes => 'Povolit na 10 minut';

  @override
  String get rigClipboardAlwaysAllow => 'Vždy povolit';

  @override
  String get rigClipboardSettingsTitle => 'Přístup ke schránce';

  @override
  String get rigClipboardSettingsHint =>
      'Vyberte, které přenosy schránky mohou probíhat bez dotazu. Dočasná oprávnění vyprší po 10 minutách.';

  @override
  String get rigClipboardAlwaysPasteTitle =>
      'Vždy povolit vložení do kontejnerů';

  @override
  String get rigClipboardAlwaysPasteDescription =>
      'Odesílat schránku tohoto zařízení do libovolného kontejneru bez dotazu.';

  @override
  String get rigClipboardAlwaysCopyTitle =>
      'Vždy povolit kopírování z kontejnerů';

  @override
  String get rigClipboardAlwaysCopyDescription =>
      'Vložit obsah schránky z libovolného kontejneru do tohoto zařízení bez dotazu.';

  @override
  String get workspaceGitHubIdentity => 'Identita GitHub';

  @override
  String get workspaceGitHubIdentityDescription =>
      'Jak se v tomto workspace ověřuje práce na GitHubu na pozadí. Zdění App této instalace, jiná App, nebo jen osobní přístupový token.';

  @override
  String get workspaceGitHubModeInherit => 'Použít GitHub App této instalace';

  @override
  String get workspaceGitHubModeApp => 'Použít jinou GitHub App';

  @override
  String get workspaceGitHubModePat => 'Pouze osobní přístupový token';

  @override
  String get workspaceGitHubInheritHint =>
      'Používá GitHub App v Server → Aplikace poskytovatelů.';

  @override
  String get workspaceGitHubAppHint =>
      'Bot a identita pollingu tohoto workspace. Členové se na You přihlašují přes tuto App.';

  @override
  String get workspaceGitHubPatLabel => 'Token na pozadí';

  @override
  String get workspaceGitHubPatDescription =>
      'Pro polling a agenty v tomto workspace. Nejde o profilový token člena.';

  @override
  String get workspaceGitHubHasPat => 'Token na pozadí je uložen.';

  @override
  String get workspaceGitHubNoPat => 'Žádný token na pozadí není uložen.';

  @override
  String get profileOverlayHint =>
      'Tato pole jste vy v tomto workspace. Prázdná pole zdědí jméno a e-mail účtu. Přepnutí workspace přepne tuto vrstvu.';

  @override
  String get forgeConnectionsThisWorkspace =>
      'Přihlaste se nebo vložte token pro tento workspace.';
}
