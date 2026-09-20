// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get succeeded => 'Başarılı';

  @override
  String agentRunRetryLabel(int number, String time) {
    return 'Yeniden dene #$number · $time';
  }

  @override
  String agentRunStarting(String time) {
    return 'Başlatılıyor · $time';
  }

  @override
  String get agentActivityFollowingLive => 'Canlı etkinlik takip ediliyor';

  @override
  String get agentActivityJumpToLatest => 'En sona git';

  @override
  String get agentActivityLoadFailed =>
      'Bu çalıştırmanın etkinliği yüklenemedi';

  @override
  String get agentActivityNotRecorded =>
      'Bu çalıştırma için etkinlik kaydedilmedi';

  @override
  String get agentActivityNotRecordedHint =>
      'Etkinlik yakalama açılmadan biten çalıştırmaların zaman çizelgesi yok.';

  @override
  String get agentActivityRunUnavailable =>
      'Bu çalıştırma artık kullanılamıyor';

  @override
  String agentActivitySubagentOf(String agent) {
    return '$agent alt ajanı';
  }

  @override
  String get agentActivityUnsupported =>
      'Bağlı sunucuda etkinlik yakalama kullanılamıyor';

  @override
  String get agentActivityUnsupportedHint =>
      'En son sunucu derlemesini almak için uygulamayı yeniden başlatın.';

  @override
  String get agentActivityWaiting => 'Etkinlik bekleniyor…';

  @override
  String get created => 'Oluşturuldu';

  @override
  String get dictationStart => 'Dikteyi başlat';

  @override
  String get dictationListening => 'Dinleniyor…';

  @override
  String get dictationUnavailable =>
      'Dikte için sunucu makinesinde bir ses modeli gerekir. Ses ayarlarından kurun.';

  @override
  String get dictationFailedToStart => 'Dikte başlatılamadı';

  @override
  String get dictationHoldToTalkTitle => 'Konuşmak için basılı tut';

  @override
  String get dictationHoldToTalkDescription =>
      'Dikte etmek için mikrofon düğmesini veya kısayolu basılı tutun, durdurmak için bırakın. Kapalıyken başlatmak için bir kez, durdurmak için tekrar basın.';

  @override
  String get focusConversation => 'Sohbete odaklan';

  @override
  String get ideAgentActivity => 'Ajan etkinliği';

  @override
  String get keybindingPushToTalk => 'Bas konuş';

  @override
  String get keybindingPushToTalkDescription =>
      'İleti kutusunda sesli dikteyi basılı tutun veya açıp kapatın';

  @override
  String get agentPermissions => 'Ajan izinleri';

  @override
  String get agentPermissionsSettingsDescription =>
      'Ajanların kendi başına neler yapabileceğini, önce sorması gerekenleri veya hiç yapamayacaklarını çalışma alanı, ajan veya space bazında belirleyin.';

  @override
  String get agentPermissionsMatrixDescription =>
      'Her etki türü için bir karar belirleyin. Kurallar basamaklanır: space ajanı, ajan çalışma alanını, çalışma alanı kip ön ayarını geçersiz kılar. En özgül kural geçerli olur.';

  @override
  String get guardrailLoading => 'Kurallar yükleniyor…';

  @override
  String get guardrailRulesLoadFailed => 'İzin kuralları yüklenemedi.';

  @override
  String get guardrailScopeWorkspace => 'Çalışma alanı';

  @override
  String get guardrailScopeAgent => 'Ajan';

  @override
  String get guardrailScopeSpace => 'Space';

  @override
  String get guardrailSelectAgent => 'Bir ajan seçin';

  @override
  String get guardrailSelectSpace => 'Bir space seçin';

  @override
  String get guardrailNoAgents => 'Bu çalışma alanında henüz ajan yok.';

  @override
  String get guardrailNoSpaces => 'Bu çalışma alanında henüz space yok.';

  @override
  String get guardrailClassFileDelete => 'Dosya sil';

  @override
  String get guardrailClassFileWriteOutsideWorktree =>
      'Çalışma ağacının dışına yaz';

  @override
  String get guardrailClassGitCommit => 'Commit oluştur';

  @override
  String get guardrailClassGitPush => 'Uzak depoya push et';

  @override
  String get guardrailClassPrCreate => 'Pull request aç';

  @override
  String get guardrailClassPrPublish => 'İnceleme yayınla veya birleştir';

  @override
  String get guardrailClassVendorSyncWrite => 'Harici takip sistemine yaz';

  @override
  String get guardrailClassNetworkEgress => 'Ağa eriş';

  @override
  String get guardrailClassSecretAccess => 'Bir secret oku';

  @override
  String get guardrailClassPackageInstall => 'Paket kur';

  @override
  String get guardrailClassProcessSpawn => 'Süreç çalıştır';

  @override
  String get guardrailClassWorkspaceMutation =>
      'Çalışma alanı yapısını değiştir';

  @override
  String get guardrailClassEnclosureControl => 'Bir enclosure’ı (rig) yönet';

  @override
  String get navRigs => 'Rigs';

  @override
  String get rigsUnsupportedServer =>
      'Bu sunucu hiçbir rig yüzeyini barındıramaz. Kullanmak istediğiniz makinenin ana makine gereksinimlerini kontrol edin.';

  @override
  String get rigSurfaceComputer => 'Bilgisayar';

  @override
  String get rigSurfaceBrowser => 'Tarayıcı';

  @override
  String get rigSurfaceAndroid => 'Android';

  @override
  String get rigSurfaceIosSimulator => 'iOS Simülatörü';

  @override
  String rigSurfaceBrowserEngine(String engine) {
    return '$engine';
  }

  @override
  String rigBrowserEngineHint(String engine) {
    return 'Makinenizden yalıtılmış, tek kullanımlık bir $engine. Aynı sayfayı yan yana karşılaştırmak için başka bir engine açın.';
  }

  @override
  String get rigPhaseReady => 'Hazır';

  @override
  String get rigPhaseStarting => 'Başlatılıyor';

  @override
  String get rigPhaseParked => 'Park halinde';

  @override
  String get rigPhaseClosing => 'Kapatılıyor';

  @override
  String get rigPhaseClosed => 'Kapalı';

  @override
  String get rigPhaseFailed => 'Başarısız';

  @override
  String get rigPhaseUnknown => 'Bilinmiyor';

  @override
  String get rigNotAccelerated => 'Öykünülmüş';

  @override
  String get rigAudioListen => 'Makineyi dinle';

  @override
  String get rigAudioMute => 'Makineyi sessize al';

  @override
  String get rigYouHaveControl => 'Kontrol sizde';

  @override
  String get rigBackendAvailable => 'Kullanılabilir';

  @override
  String get rigBackendUnavailable => 'Kullanılamıyor';

  @override
  String get rigEgressNotEnforced =>
      'Bu backend\'de ağ kapsüllü değil — bağlantıyı kendi yönetiyor.';

  @override
  String get rigStartMachine => 'Makineyi başlat';

  @override
  String get rigStartHint =>
      'Bu konuşma için sizin ve ajanlarınızın paylaştığı tek kullanımlık bir sanal makine başlatır. Kapandığında yok edilir; içindeki hiçbir şey bilgisayarınıza dokunmaz.';

  @override
  String get rigStartAndroidHint =>
      'Sunucuda zaten çalışan bir Android emülatörüne bağlanır. Ağ erişimi yalıtılmamıştır.';

  @override
  String get rigStartIosHint =>
      'Bir macOS sunucusunda geçici bir iOS Simülatörü oluşturur. Test ortamı kapatıldığında silinir; ağ erişimi yalıtılmamıştır.';

  @override
  String get rigTechnicalDetails => 'Teknik ayrıntılar';

  @override
  String get rigStopMachine => 'Makineyi durdur';

  @override
  String get rigHomeButton => 'Ana ekran';

  @override
  String get rigRotateClockwise => 'Saat yönünde döndür';

  @override
  String get rigRotateCounterclockwise => 'Saat yönünün tersine döndür';

  @override
  String get rigTakeScreenshot => 'Ekran görüntüsü al';

  @override
  String get rigScreenshotSaved => 'Ekran görüntüsü kaydedildi';

  @override
  String rigScreenshotSaveFailed(String error) {
    return 'Ekran görüntüsü kaydedilemedi: $error';
  }

  @override
  String get rigSurfaceUnavailable =>
      'Bu sunucu bu tür bir makine barındıramaz.';

  @override
  String get rigTabNeedsConversation =>
      'Önce bir konuşma açın — makine bir konuşmaya aittir, böylece siz ve ajanlarınız aynı ekrana bakarsınız.';

  @override
  String get ideMenuSectionTools => 'Araçlar';

  @override
  String get ideMenuSectionMachines => 'Makineler';

  @override
  String get ideMenuSectionReopen => 'Yeniden aç';

  @override
  String get ideMenuSearchHint => 'Ara';

  @override
  String get ideMenuNoMatches => 'Eşleşme yok';

  @override
  String get rigMenuComputer => 'Bilgisayar';

  @override
  String get rigMenuBrowser => 'Tarayıcı';

  @override
  String get rigMenuAndroid => 'Android';

  @override
  String get rigMenuIosSimulator => 'iOS Simülatörü';

  @override
  String rigLabelNumbered(String label, String suffix) {
    return '$label $suffix';
  }

  @override
  String ideCloseKeepTitle(String name) {
    return '$name kapatılsın mı?';
  }

  @override
  String get ideCloseKeepBodyMachine =>
      'Makine arka planda çalışmaya devam eder — kenar çubuğundan istediğiniz zaman yeniden açın. Belleğini şimdi boşaltmak için kapatın.';

  @override
  String get ideCloseKeepBodyShell =>
      'Komut arka planda çalışmaya devam eder — kenar çubuğundan shell\'i istediğiniz zaman yeniden açın. Şimdi yaptığını durdurmak için sonlandırın.';

  @override
  String get ideCloseKeepBodyAgent =>
      'Ajan arka planda çalışmaya devam eder — kenar çubuğundan konuşmayı istediğiniz zaman yeniden açın. Çalışmayı şimdi bitirmek için durdurun.';

  @override
  String get ideCloseKeepRunning => 'Çalışmaya devam et';

  @override
  String get ideCloseShutDownMachine => 'Kapat';

  @override
  String get ideCloseEndShell => 'Shell\'i sonlandır';

  @override
  String get ideCloseStopAgent => 'Ajanı durdur';

  @override
  String get rigsSettingsSubtitle =>
      'Bu sunucunun açabilecekleri, ihtiyaç duyduğu temel imajlar ve şu an çalışan makineler';

  @override
  String get rigsCapabilitiesTitle => 'Bu sunucu';

  @override
  String get rigInstallIosAutomation => 'iOS otomasyon köprüsünü yükle';

  @override
  String get rigInstallingIosAutomation => 'iOS otomasyon köprüsü yükleniyor…';

  @override
  String get rigIosAutomationInstalled => 'iOS otomasyon köprüsü yüklendi';

  @override
  String get rigsImagesTitle => 'Temel imajlar';

  @override
  String get rigsImagesHint =>
      'Her rig bu salt okunur imajlardan biriyle açılır. Her oturum atılabilir bir katmana yazar; böylece bir rig, bir sonrakinin neyle başlayacağını değiştiremez.';

  @override
  String get rigsRunningTitle => 'Şu an çalışanlar';

  @override
  String get rigsNoneRunning => 'Çalışan makine yok.';

  @override
  String get rigsCustomImagesTitle => 'Özel imajlar (bu çalışma alanı)';

  @override
  String get rigsCustomImagesHint =>
      'Terminal (VM) veya Tarayıcı (VM) için kendi imajınızı gösterin — varsayılanları projenizin ihtiyaç duyduğu araçlarla genişletin veya bir registry\'den uyumlu herhangi birini kullanın. Yeni makineler bunu kullanır; çalışanlar kendilerininkini korur. Bir imajın neler sağlaması gerektiği için rigs kılavuzuna bakın.';

  @override
  String get rigsCustomTerminalImageLabel => 'Terminal (VM) imajı';

  @override
  String get rigsCustomBrowserImageLabel => 'Tarayıcı (VM) imajı';

  @override
  String get rigsCustomImagePlaceholder =>
      'örn. ghcr.io/acme/dev-shell:1.2 — varsayılan için boş bırakın';

  @override
  String get rigsCustomImageInvalid =>
      'repo/name:tag gibi bir registry referansı girin. Yerel yollar ve arşivler kabul edilmez.';

  @override
  String get rigsCustomImageSaved =>
      'Kaydedildi. Yeni makineler bu imajla açılır; çalışanlar kendilerininkini korur.';

  @override
  String get rigsEgressTitle => 'Tarayıcı çıkışı (bu çalışma alanı)';

  @override
  String get rigsEgressHint =>
      'Kapsüllü tarayıcının erişebileceği ek host\'lar — satır başına bir tane: tam bir host (api.example.com) veya alt alan adları için joker (*.example.com). Ürün sitesi her durumda izinli kalır. Yeni makineler listeyi alır; çalışanlar açıldıkları listeyi korur.';

  @override
  String rigsEgressInvalid(String host) {
    return '\"$host\" geçerli bir host girişi değil.';
  }

  @override
  String get rigsEgressSaved =>
      'Kaydedildi. Yeni tarayıcı makineleri bu host\'lara izin verir; çalışanlar kendilerininkini korur.';

  @override
  String get rigImageInstalled => 'Yüklü';

  @override
  String get rigImageNotDownloaded => 'İndirilmedi';

  @override
  String get rigImageNotPublished => 'Yayımlanmadı';

  @override
  String get rigImageNotPublishedHint =>
      'Bunun için henüz bir imaj yayımlanmadı, indirilecek bir şey yok. Etkinleştirmek için uyumlu bir disk imajı içe aktarın.';

  @override
  String get rigImageDownload => 'İndir';

  @override
  String get rigImageDownloading => 'İndiriliyor…';

  @override
  String get rigImageImport => 'İçe aktar';

  @override
  String get rigImageImportMessage =>
      'Sunucunun dosya sistemindeki bir qcow2 disk imajının yolu. İmaj deposuna kopyalanır, dosya sonra taşınabilir.';

  @override
  String get rigConnectingStream => 'Rig\'e bağlanılıyor';

  @override
  String get rigStreamNotAllowed => 'Bu rig\'e erişiminiz yok.';

  @override
  String get rigStreamNotRunning => 'Bu rig artık çalışmıyor.';

  @override
  String get rigStreamNeedsFfmpeg =>
      'Canlı görünüm bu makinede ffmpeg gerektirir. ffmpeg kurun ve sekmeyi yeniden açın.';

  @override
  String get rigStreamEnded => 'Canlı görünüm sona erdi.';

  @override
  String get rigStreamFailed => 'Canlı görünüm açılamadı.';

  @override
  String get rigStreamDisconnected => 'Bir sunucuya bağlı değil.';

  @override
  String rigDropSendingOne(String name) {
    return '\"$name\" makineye kopyalanıyor…';
  }

  @override
  String rigDropSendingMany(int count) {
    return '$count dosya makineye kopyalanıyor…';
  }

  @override
  String get rigTerminalDropSending => 'Makineye kopyalanıyor…';

  @override
  String get rigTerminalPasteImage =>
      'Yapıştırılan görüntü makineye kaydedildi';

  @override
  String get rigPortsTitle => 'Yönlendirilen portlar';

  @override
  String get rigPortsTooltip => 'Bu makinede açık portlar';

  @override
  String get rigPortsEmpty =>
      'Henüz dinleyen bir şey yok. Terminalde bir sunucu başlatın — 3000 portundaki bir geliştirme sunucusu burada görünür.';

  @override
  String get rigPortsAdd => 'Port ekle';

  @override
  String get rigPortsAddHint => 'Yönlendirilecek konuk portu (ör. 3000)';

  @override
  String get rigPortsAutoForward => 'Portları otomatik yönlendir';

  @override
  String get rigPortsCopyUrl => 'Yerel URL\'yi kopyala';

  @override
  String rigPortsCopiedUrl(String url) {
    return '$url kopyalandı';
  }

  @override
  String get rigPortsStopForward => 'Yönlendirmeyi durdur';

  @override
  String get rigPortsExposeLan => 'Yerel ağda paylaş';

  @override
  String get rigPortsLanPrivate => 'Yalnızca yerel';

  @override
  String get rigPortsLanShared => 'Ağda';

  @override
  String get rigPortsSetDomain => 'Tarayıcı etki alanı ayarla (.test)';

  @override
  String get rigPortsDomainHint =>
      'Tarayıcı (VM) için etki alanı, ör. myapp.test — oradan erişilir, ana makineden değil';

  @override
  String get rigPortsProcessUnknown => 'bilinmeyen süreç';

  @override
  String get rigPortsInactive => 'dinlemiyor';

  @override
  String get rigPortsTooltipHost => 'Bu terminalde açık bağlantı noktaları';

  @override
  String get rigPortsEmptyHost =>
      'Bu terminalde henüz dinleyen yok. Bir sunucu başlatın, burada görünür.';

  @override
  String get rigPortsAddHintHost => 'Eşlenecek bağlantı noktası (ör. 5173)';

  @override
  String get rigPortsLocalPortHint => 'Yerel bağlantı noktası (isteğe bağlı)';

  @override
  String rigPortsDestDesktop(int port) {
    return 'localhost:$port';
  }

  @override
  String rigPortsDestBrowser(int port) {
    return 'localhost:$port tarayıcıda (VM)';
  }

  @override
  String get rigPortsDestBrowserUnreachable => 'tarayıcı (VM) bağlı değil';

  @override
  String rigPortsDestAndroid(int port) {
    return 'localhost:$port Android\'de';
  }

  @override
  String get rigPortsDestAndroidUnreachable => 'Android bağlı değil';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'İndirilecek $count temel imaj kaldı',
      one: 'İndirilecek 1 temel imaj kaldı',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => 'İzin ver';

  @override
  String get guardrailDecisionPrompt => 'Önce sor';

  @override
  String get guardrailDecisionDeny => 'Reddet';

  @override
  String get guardrailSourceThisScope => 'Bu kapsam';

  @override
  String get guardrailSourceDefault => 'Yerleşik varsayılan';

  @override
  String get guardrailSourcePreset => 'Mod ön ayarı';

  @override
  String get guardrailSourceInherited => 'Devralınan';

  @override
  String get guardrailClearToInherited => 'Devralınana sıfırla';

  @override
  String get guardrailWhatIf => 'Ne olur?';

  @override
  String get guardrailWhatIfDescription =>
      'Ajanların kullandığı aynı mantıkla, geçerli kuralların bir eylemi nasıl çözeceğini görün.';

  @override
  String get guardrailProbeActionLabel => 'Eylem';

  @override
  String get guardrailProbeCommandLabel => 'Komut (isteğe bağlı)';

  @override
  String get guardrailProbeCommandHint => 'ör. git push origin main';

  @override
  String get guardrailProbeAgentLabel => 'Ajan (isteğe bağlı)';

  @override
  String get guardrailProbeSpaceLabel => 'Alan (isteğe bağlı)';

  @override
  String get guardrailProbeNone => 'Yok';

  @override
  String get guardrailProbeModeLabel => 'Mod';

  @override
  String get guardrailProbeResult => 'Sonuç';

  @override
  String get guardrailProbeSource => 'Kaynak:';

  @override
  String get guardrailAdapterMatrix => 'Kuralların uygulandığı yer';

  @override
  String get guardrailAdapterMatrixDescription =>
      'Dürüst referans: her etkinin ajan çalıştırıcısına göre gerçekte nerede yakalandığı. Gerçekliği belgeler, garanti değildir — çalıştırıcının bant dışında yaptığı etkiler kesilemez.';

  @override
  String get guardrailEffectColumn => 'Etki';

  @override
  String get guardrailAdapterHarness => 'Yerleşik harness';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => 'Sandbox tabanı';

  @override
  String get guardrailEnforcementPolicyGate => 'İlke kapısı';

  @override
  String get guardrailEnforcementSandbox => 'Yalnızca sandbox';

  @override
  String get guardrailEnforcementNone => 'Uygulanamaz';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      'İzin kararı, etki çalışmadan önce denetlenir ve onu engelleyebilir.';

  @override
  String get guardrailEnforcementSandboxHelp =>
      'Yalnızca sandbox kısıtlar; izin kuralına bakılmaz.';

  @override
  String get guardrailEnforcementNoneHelp =>
      'Karar yalnızca tavsiye niteliğindedir — burada kesilemez.';

  @override
  String get obsStatCost => 'maliyet';

  @override
  String obsStatDelegatedCost(String amount) {
    return '+$amount devredilen';
  }

  @override
  String get obsStatDuration => 'süre';

  @override
  String get obsStatTokens => 'token';

  @override
  String get obsStatTools => 'araçlar';

  @override
  String get openAgentActivity => 'Etkinliği aç';

  @override
  String get orgChart => 'Organizasyon şeması';

  @override
  String get orgChartEmpty => 'Henüz ajan yok';

  @override
  String get navCalendar => 'Takvim';

  @override
  String get serverConnection => 'Sunucu bağlantısı';

  @override
  String get serverModeLocal => 'Bu uygulamada çalıştır';

  @override
  String get serverModeLocalDescription =>
      'Control Center bu makinede kendi sunucusunu çalıştırır ve verileriniz yerelde kalır.';

  @override
  String get serverModeRemote => 'Uzak bir örneğe bağlan';

  @override
  String get serverModeRemoteDescription =>
      'Başka bir yerde çalışan bir Control Center sunucusuna bağlanın. Verileriniz o sunucuda tutulur.';

  @override
  String get serverRemoteUrl => 'Sunucu URL\'si';

  @override
  String get serverRemoteDeviceId => 'Cihaz kimliği';

  @override
  String get serverRemotePairingKey => 'Eşleme anahtarı';

  @override
  String get serverRemotePairingKeyHint =>
      'Uzak sunucudaki eşleme anahtarını yapıştırın';

  @override
  String get serverSetupInviteCode => 'Davet kodu';

  @override
  String get serverSetupInviteCodeHint =>
      'Tek kullanımlık bir davet kodu yapıştırın (eşleme anahtarı kullanmak için boş bırakın)';

  @override
  String get serverDiscoveryTooltip => 'Ağınızdaki sunucuları bulun';

  @override
  String get serverDiscoveryTitle => 'Ağınızdaki sunucular';

  @override
  String get serverDiscoverySearching => 'Sunucular aranıyor…';

  @override
  String get serverDiscoveryEmpty =>
      'Sunucu bulunamadı. Sunucunun çalıştığını ve bu cihazın ona erişebildiğini kontrol edin, ardından yeniden arayın.';

  @override
  String get serverDiscoveryRefresh => 'Yeniden ara';

  @override
  String get serverListActive => 'Etkin';

  @override
  String get serverListSwitch => 'Geç';

  @override
  String get serverListAddTitle => 'Sunucu ekle';

  @override
  String get serverListRemoveActiveHint =>
      'Bunu kaldırmadan önce başka bir sunucuya geçin.';

  @override
  String get serverSwitchFailedTitle => 'Sunucu değiştirilemedi';

  @override
  String get serverListInsecureBadge => 'Güvensiz';

  @override
  String get connectionPathLocal => 'Yerel';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => 'Kapatılıyor';

  @override
  String get shutdownSubtitle => 'Yerel sunucu kapatılıyor';

  @override
  String get shutdownServiceApprovals => 'Onaylar';

  @override
  String get shutdownServiceBackgroundJobs => 'Arka plan işleri';

  @override
  String get shutdownServiceScheduler => 'İş zamanlayıcı';

  @override
  String get shutdownServiceCalendar => 'Takvim senkronizasyonu';

  @override
  String get shutdownServiceWeather => 'Hava durumu';

  @override
  String get shutdownServiceSoundscape => 'Soundscape';

  @override
  String get shutdownServiceMeetings => 'Toplantılar';

  @override
  String get shutdownServiceVoiceModels => 'Ses modelleri';

  @override
  String get shutdownServiceNetworking => 'Ağ';

  @override
  String get shutdownServicePresence => 'Çevrimiçi durum';

  @override
  String get shutdownServiceDataSync => 'Veri senkronizasyonu';

  @override
  String get shutdownServiceDeviceRelay => 'Cihaz aktarımı';

  @override
  String get shutdownServiceMcpConnections => 'MCP bağlantıları';

  @override
  String get shutdownServiceCodeEditors => 'Kod düzenleyiciler';

  @override
  String get serverSharingTitle => 'Bu sunucuyu paylaş';

  @override
  String get serverSharingDescription =>
      'Bu sunucuyu diğer cihazlarınızdan erişilebilir hale getirin. Aşağıdan bir tünel açmadığınız sürece hiçbir şey herkese açık olmaz. Eşleme davetleri sunucunun güncel adreslerini otomatik olarak içerir — bunları çalışma alanı ayarlarından oluşturun.';

  @override
  String get serverSharingUnavailable =>
      'Paylaşım denetimleri bu sunucuda kullanılamıyor.';

  @override
  String get serverSharingMdnsLabel => 'LAN keşfi';

  @override
  String get serverSharingMdnsOn => 'Bu sunucu yerel ağda duyuruluyor (mDNS)';

  @override
  String get serverSharingMdnsOff => 'Yerel ağda duyurulmuyor (mDNS)';

  @override
  String get serverSharingTunnelLabel => 'Tünel';

  @override
  String get serverSharingTunnelHelper =>
      'Tünel açmak bu sunucuyu internetten erişilebilir kılar. Herkese açık erişim isteğe bağlıdır ve varsayılan olarak kapalıdır.';

  @override
  String get serverSharingProviderOff => 'Kapalı';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => 'Herkese açık URL';

  @override
  String get serverSharingTunnelStarting => 'Tünel başlatılıyor…';

  @override
  String serverSharingTunnelError(String error) {
    return 'Tünel hatası: $error';
  }

  @override
  String get serverSharingTunnelUpNoUrl =>
      'Tünel çalışıyor. Yapılandırdığınız DNS ana makine adından erişin.';

  @override
  String get serverSharingRelayLabel => 'Röle';

  @override
  String serverSharingRelayUsage(String amount) {
    return 'Bu ay rölelenen: $amount';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return 'Etkin röle oturumları: $count';
  }

  @override
  String get serverSharingUpdateFailedTitle => 'Paylaşım güncellenemedi';

  @override
  String get pairNewClient => 'Yeni istemci eşle';

  @override
  String get pairClientNameHint => 'Bu istemciye bir ad verin (ör. İş dizüstü)';

  @override
  String get pairClientTypeWeb => 'Web tarayıcısı';

  @override
  String get pairClientTypeDesktop => 'Masaüstü uygulaması';

  @override
  String get pairClientTypePhone => 'Telefon';

  @override
  String get pairAction => 'Eşle';

  @override
  String get revoke => 'İptal et';

  @override
  String get pairCredentialsIntro =>
      'Yeni istemciyi bu bilgilerle bağlayın veya bağlantıyı istemcide açın.';

  @override
  String get pairLinkLabel => 'Bağlantı';

  @override
  String get pairScanQr =>
      'Eşlemek için bu QR kodunu telefonunuzun kamerasıyla tarayın.';

  @override
  String get pairServerUnreachableTitle => 'Erişilemiyor';

  @override
  String get pairServerUnreachable =>
      'Diğer cihazlar bu sunucuya doğrudan erişemediği için yeni bir istemci bağlanamıyor. Daha fazla istemci eşlemek için sunucunun herkese açık URL’sini ayarlayın.';

  @override
  String get serverSetupTitle => 'Control Center nasıl çalışsın?';

  @override
  String get serverSetupSubtitle =>
      'Control Center, verilerinizi barındıran bir sunucuya ihtiyaç duyar. Birini bu uygulama içinde çalıştırın veya başka yerde çalışan bir örneğe bağlanın.';

  @override
  String get serverSetupRunLocal => 'Bu uygulamada çalıştır';

  @override
  String get serverSetupConnect => 'Bağlan';

  @override
  String get serverSetupInvalidUrl =>
      'Geçerli bir ws:// veya wss:// sunucu URL’si girin.';

  @override
  String get serverSetupCouldNotConnect => 'Bağlanılamadı';

  @override
  String get serverSetupErrorUnreachable =>
      'Sunucuya erişilemedi. Çalıştığından ve bu cihazın ona ulaşabildiğinden emin olun (aynı ağ veya röle).';

  @override
  String get serverSetupErrorIdentityMismatch =>
      'Sunucunun kimliği bu cihazda kayıtlı olanla eşleşmiyor. Sunucu yeniden yüklendiyse veya sıfırlandıysa kayıtlı sunucuyu kaldırıp yeniden eşleyin.';

  @override
  String get serverSetupErrorAuthRejected =>
      'Sunucu bu cihazı reddetti. Eşleme anahtarı ve cihaz kimliğinin sunucunun verdiğiyle eşleştiğini kontrol edin.';

  @override
  String get serverSetupErrorInviteRejected =>
      'Bu davet kodu geçersiz veya süresi dolmuş. Yeni bir tane isteyin.';

  @override
  String get serverSetupErrorGeneric =>
      'Bağlanırken bir sorun oluştu. Daha fazla bilgi için aşağıdaki teknik ayrıntıları genişletin.';

  @override
  String get serverSetupErrorDetails => 'Teknik ayrıntılar';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tane daha',
      one: '1 tane daha',
    );
    return '$_temp0';
  }

  @override
  String get calendarAllDayGutter => 'Tüm gün';

  @override
  String calendarAllDayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count etkinlik',
      one: '1 etkinlik',
    );
    return '$_temp0';
  }

  @override
  String get calendarCollapseAllDay => 'Tüm gün etkinliklerini daralt';

  @override
  String get calendarExpandAllDay => 'Tüm gün etkinliklerini genişlet';

  @override
  String get calendarViewMonth => 'Ay';

  @override
  String get calendarViewWeek => 'Hafta';

  @override
  String get calendarViewAgenda => 'Ajanda';

  @override
  String get calendarConnectGoogle => 'Google Calendar’ı bağla';

  @override
  String get calendarConnectDescription =>
      'Etkinlikleri burada görmek ve toplantılar başlamadan önce uyarı almak için Google Calendar’ınızı senkronize edin.';

  @override
  String get calendarDisconnect => 'Bağlantıyı kes';

  @override
  String get calendarReconnect => 'Yeniden bağlan';

  @override
  String get calendarEmptyNoEvents => 'Bu aralıkta etkinlik yok';

  @override
  String get calendarStartRecording => 'Kaydı başlat';

  @override
  String get calendarStartRecordingAndLink => 'Kaydı başlat ve bağla';

  @override
  String get calendarJoinMeet => 'Toplantıya katıl';

  @override
  String get calendarFromCalendar => 'Takvimden';

  @override
  String get calendarLinkedMeeting => 'Bağlı toplantı';

  @override
  String get calendarToday => 'Bugün';

  @override
  String get calendarAllDay => 'Tüm gün';

  @override
  String calendarWeekNumber(int number) {
    return 'Hafta $number';
  }

  @override
  String get calendarPreviousPeriod => 'Önceki';

  @override
  String get calendarNextPeriod => 'Sonraki';

  @override
  String calendarLastSynced(String time) {
    return '$time senkronize edildi';
  }

  @override
  String get calendarNeverSynced => 'Henüz senkronize edilmedi';

  @override
  String get calendarSyncing => 'Senkronize ediliyor…';

  @override
  String get calendarViewDay => 'Gün';

  @override
  String get calendarShow => 'Göster';

  @override
  String get calendarHide => 'Gizle';

  @override
  String get calendarRsvpGoing => 'Katılıyor musunuz?';

  @override
  String get calendarRsvpYes => 'Evet';

  @override
  String get calendarRsvpNo => 'Hayır';

  @override
  String get calendarRsvpMaybe => 'Belki';

  @override
  String get calendarRsvpFailed => 'Yanıtınız güncellenemedi';

  @override
  String get calendarAddAccount => 'Takvim hesabı ekle';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Etkinlikleri bu çalışma alanına eşitlemek için bir Google hesabı bağlayın.';

  @override
  String get calendarConnecting => 'Bağlanıyor…';

  @override
  String get calendarSyncNow => 'Şimdi eşitle';

  @override
  String get calendarNoWorkspace =>
      'Takvimini görmek için bir çalışma alanı seçin';

  @override
  String get calendarConnectError => 'Google Calendar bağlanamadı';

  @override
  String get calendarClientIdLabel => 'Client ID';

  @override
  String get calendarClientSecretLabel => 'Client secret';

  @override
  String get calendarConnectCredsHint =>
      'Projeniz için Google OAuth device-code client ID ve secret değerlerini girin. Bağlantıyı ve eşitlemeyi sunucu yürütür — tarayıcınız token’ları hiçbir zaman tutmaz.';

  @override
  String get calendarConnectApproveInstruction =>
      'Herhangi bir cihazda doğrulama sayfasını açın, oturum açın ve şu kodu girin:';

  @override
  String get calendarConnectOpenPage => 'Doğrulama sayfasını aç';

  @override
  String get calendarConnectWaiting => 'Onay bekleniyor…';

  @override
  String get calendarConnectDenied =>
      'Yetkilendirme reddedildi. Lütfen yeniden deneyin.';

  @override
  String get calendarConnectExpired =>
      'Kodun süresi doldu. Lütfen yeniden deneyin.';

  @override
  String get notificationMeetingStartsSoon => 'Toplantı yakında başlıyor';

  @override
  String get notifyMeetingStartsSoon => 'Takvim toplantısı başlamak üzereyken';

  @override
  String get notificationCalendarAuthExpiredTitle =>
      'Takvim bağlantısı kesildi';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'Eşitlemeye devam etmek için $email hesabını yeniden bağlayın';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'Eşitlemeye devam etmek için takviminizi yeniden bağlayın';

  @override
  String get notifyCalendarAuthExpired =>
      'Bir takvim hesabının yeniden bağlanması gerektiğinde';

  @override
  String get notificationRigStatusChanged => 'Kabin güncellemeleri';

  @override
  String get notifyRigStatusChanged =>
      'Bir kabin devralındığında, geri alındığında veya arızalandığında';

  @override
  String get notificationRigTakenOver => 'Kabin devralındı';

  @override
  String get notificationRigTakenOverBody =>
      'Makineyi bir kişi kullanıyor; ajan izleyebilir ama müdahale edemez.';

  @override
  String get notificationRigReleased => 'Kabin kontrolü bırakıldı';

  @override
  String get notificationRigReleasedBody => 'Ajan makineyi geri aldı.';

  @override
  String get notificationRigReclaimed => 'Kabin geri alındı';

  @override
  String get notificationRigReclaimedBodyIdle =>
      'Boşta kaldığı için bellek boşaltmak üzere makine kapatıldı.';

  @override
  String get notificationRigReclaimedBodyTtl =>
      'Süre sınırına ulaştığı için kapatıldı.';

  @override
  String get notificationRigFailed => 'Kabin arızalandı';

  @override
  String get notificationRigFailedBody =>
      'Alttaki hipervizör durdu. Devam etmek için makineyi yeniden açın.';

  @override
  String get calendarAlertLeadTime => 'Uyarı öncesi süre';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'Toplantıdan ne kadar önce uyarılacağınız';

  @override
  String calendarConnectedAs(String email) {
    return '$email olarak bağlı';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count katılımcı';
  }

  @override
  String get calendarEventLabel => 'Etkinlik';

  @override
  String get calendarRecurring => 'Yinelenen etkinlik';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'Düzenleyen';

  @override
  String get calendarYou => 'Siz';

  @override
  String get calendarShowFewer => 'Daha az göster';

  @override
  String get calendarRsvpAwaiting => 'Bekleniyor';

  @override
  String calendarParticipantsCount(int count) {
    return '$count katılımcı';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'Tüm $count katılımcıyı gör';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count evet';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count hayır';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count belki';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count bekleniyor';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count dakika';
  }

  @override
  String get openInEditorPrompt => 'Hangi düzenleyicide açılsın?';

  @override
  String get ideNotInstalled => 'Yüklü değil';

  @override
  String openInIde(String editor) {
    return '$editor ile aç';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return '$editor açılamadı: $error';
  }

  @override
  String get profileSearchHint => 'Pull request ara…';

  @override
  String get stopAgentRun => 'Çalışmayı durdur';

  @override
  String get stopAgentRunConfirm =>
      'Bu çalışma durdurulsun mu? Devam eden iş kaybolur.';

  @override
  String get inProgress => 'Devam ediyor';

  @override
  String get drafts => 'Taslaklar';

  @override
  String get sortOldest => 'En eski';

  @override
  String get sortLargest => 'En büyük';

  @override
  String get prFilterTooltip => 'Filtre';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count etkin filtre',
      one: '1 etkin filtre',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => 'Filtre ekle…';

  @override
  String get prFilterFieldHint => 'Filtrele…';

  @override
  String get prFilterCategoryStatus => 'Durum';

  @override
  String get prFilterCategoryAuthor => 'Yazar';

  @override
  String get prFilterCategoryReviewer => 'İnceleyenler';

  @override
  String get prFilterCategoryContent => 'İçerik';

  @override
  String get prFilterCategoryRepoOwner => 'Depo sahibi';

  @override
  String get prFilterCategoryRepoName => 'Depo adı';

  @override
  String get prFilterCategoryOpenedDate => 'Açılma tarihi';

  @override
  String get prFilterCategoryUpdatedDate => 'Güncellenme tarihi';

  @override
  String get prFilterQuickToReview => 'Hızlı incelenebilir';

  @override
  String get prFilterClearAll => 'Filtreleri temizle';

  @override
  String prFilterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull request',
      one: '1 pull request',
    );
    return '$_temp0';
  }

  @override
  String prFilterHiddenOptions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hiçbir pull request ile eşleşmeyen $count seçenek',
      one: 'Hiçbir pull request ile eşleşmeyen 1 seçenek',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => 'Başlık veya gövde şunu içerir…';

  @override
  String get prFilterNoOptions => 'Eşleşen seçenek yok';

  @override
  String get prFilterChipIs => 'şudur';

  @override
  String get prFilterChipIsAnyOf => 'şunlardan biri';

  @override
  String get prFilterChipContains => 'içerir';

  @override
  String get prFilterChipSince => 'beri';

  @override
  String get prFilterAddFilterButton => 'Filtre ekle';

  @override
  String prFilterClearCategory(String category) {
    return '$category filtresini temizle';
  }

  @override
  String get prFilterCurrentUser => 'Geçerli kullanıcı';

  @override
  String get prStatusDraft => 'Taslak';

  @override
  String get prStatusOpen => 'Açık';

  @override
  String get prStatusInReview => 'İncelemede';

  @override
  String get prStatusChangesRequested => 'Değişiklik istendi';

  @override
  String get prStatusApproved => 'Onaylandı';

  @override
  String get prStatusMerged => 'Birleştirildi';

  @override
  String get prStatusClosed => 'Kapalı';

  @override
  String get prDateWindowDay => '1 gün önce';

  @override
  String get prDateWindowThreeDays => '3 gün önce';

  @override
  String get prDateWindowWeek => '1 hafta önce';

  @override
  String get prDateWindowMonth => '1 ay önce';

  @override
  String get prDateWindowThreeMonths => '3 ay önce';

  @override
  String get prDateWindowSixMonths => '6 ay önce';

  @override
  String get prDateWindowYear => '1 yıl önce';

  @override
  String get prDisplayOptions => 'Görüntüleme seçenekleri';

  @override
  String get prDisplayGrouping => 'Gruplama';

  @override
  String get prDisplayOrdering => 'Sıralama';

  @override
  String get prDisplayShowDrafts => 'Taslakları göster';

  @override
  String get prDisplayMergedWindow => 'Birleştirme aralığı';

  @override
  String get prDisplayMergedWindowDay => 'Son 1 gün';

  @override
  String get prDisplayMergedWindowWeek => 'Son 1 hafta';

  @override
  String get prDisplayMergedWindowMonth => 'Son 1 ay';

  @override
  String get prDisplayProperties => 'Görüntüleme özellikleri';

  @override
  String get prGroupingRepository => 'Depo';

  @override
  String get prGroupingAuthor => 'Yazar';

  @override
  String get prGroupingStatus => 'Durum';

  @override
  String get prGroupingNone => 'Gruplama yok';

  @override
  String get prPropertyRepository => 'Depo';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => 'Dal';

  @override
  String get prPropertyUpdated => 'Güncellendi';

  @override
  String get prPropertyAuthor => 'Yazar';

  @override
  String get prPropertyChecks => 'Kontroller';

  @override
  String get prPropertyDiff => 'Diff';

  @override
  String get prPropertyComments => 'Yorumlar';

  @override
  String get keybindingOpenFilterMenu => 'Filtre menüsünü aç';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'Pull request filtre menüsünü aç';

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seçili',
      one: '1 seçili',
    );
    return '$_temp0';
  }

  @override
  String get summary => 'Özet';

  @override
  String get kbMove => 'taşı';

  @override
  String get kbTabs => 'sekmeler';

  @override
  String get kbSearch => 'ara';

  @override
  String get kbViewed => 'görüldü';

  @override
  String get kbCollapse => 'daralt';

  @override
  String get appearance => 'Görünüm';

  @override
  String get appearanceSettingsDescription => 'Tema, dil ve tipografi.';

  @override
  String get notificationsSettingsDescription =>
      'Hangi ajan ve çalışma alanı olaylarının bildirim göndereceğini seçin.';

  @override
  String get advanced => 'Gelişmiş';

  @override
  String get accounts => 'Hesaplar';

  @override
  String get mcpServers => 'MCP sunucuları';

  @override
  String get mcpServersSettingsDescription =>
      'Yerleşik MCP sunucusu ve harici MCP sunucuları.';

  @override
  String get remoteControlAndDevices => 'Uzaktan kontrol ve cihazlar';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'Telefonları eşleştirin ve uzaktan kontrol sunucusunu yapılandırın.';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'Bu sunucunun barındırdığı konuşma ve konuşmacı ayırma modelleri.';

  @override
  String get needsSetupLabel => 'Kurulum gerekli';

  @override
  String get collapseSidebar => 'Kenar çubuğunu daralt';

  @override
  String get expandSidebar => 'Kenar çubuğunu genişlet';

  @override
  String get filterSpacesHint => 'Alanları filtrele';

  @override
  String noSpacesMatch(String query) {
    return '\"$query\" ile eşleşen alan yok';
  }

  @override
  String get privacy => 'Gizlilik';

  @override
  String get sendDiffContentTitle =>
      'Diff içeriğini AI bağdaştırıcısına gönder';

  @override
  String get diffSharingOnSubtitle =>
      'Daha derin inceleme için ham diff satırları ajan istemlerine eklenir.';

  @override
  String get diffSharingOffSubtitle =>
      'Ajanlar yalnızca yapılandırılmış üst veriyi kullanır (dosya yolları, satır numaraları, PR açıklaması); ham kod uygulamadan çıkmaz.';

  @override
  String get errorReportingTitle => 'Çökme raporlarını paylaş';

  @override
  String get errorReportingOnSubtitle =>
      'Hataları gidermeye yardımcı olmak için çökme, hata ve performans tanıları gönderilir (yalnızca yayın derlemeleri).';

  @override
  String get errorReportingOffSubtitle =>
      'Tanılama kapalı. Çökme veya hata raporu gönderilmez.';

  @override
  String get onboardingDiagnosticsTitle =>
      'Control Center\'ı geliştirmeye yardımcı olun';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'Sorunları daha hızlı giderebilmemiz için çökme, hata ve performans tanıları gönderin (yalnızca yayın derlemeleri). Bunu istediğiniz zaman Ayarlar → Gizlilik bölümünden değiştirebilirsiniz.';

  @override
  String get blocked => 'Engellendi';

  @override
  String get idle => 'Boşta';

  @override
  String get noRunsYet => 'Henüz çalıştırma yok';

  @override
  String get copyPath => 'Yolu kopyala';

  @override
  String get copyRelativePath => 'Göreli yolu kopyala';

  @override
  String get nameRequired => 'Ad gerekli';

  @override
  String get import => 'İçe aktar';

  @override
  String get noMatchingAgents => 'Filtrenizle eşleşen ajan yok';

  @override
  String watchVideoOn(String provider) {
    return 'Videoyu $provider üzerinde izle';
  }

  @override
  String get branchTemplate => 'Dal adı şablonu';

  @override
  String get branchTemplateDescription =>
      'Yalıtılmış bir çalışma ağacında bilet başlatıldığında oluşturulan dalın kalıbı.';

  @override
  String branchTemplatePreview(String example) {
    return 'Örnek: $example';
  }

  @override
  String get deletePipelineRun => 'Pipeline çalıştırmasını sil';

  @override
  String deletePipelineRunConfirm(String template) {
    return '\"$template\" çalıştırmasını sil? Bu işlem geri alınamaz.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'Pipeline çalıştırması silinirken hata: $error';
  }

  @override
  String get deleteTicket => 'Bileti sil';

  @override
  String deleteTicketConfirm(String title) {
    return '\"$title\" silinsin mi? Bu işlem geri alınamaz.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'Bilet silinirken hata: $error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return '\"$name\" silinsin mi? Diskteki bağlı depolar etkilenmez.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'Çalışma alanı silinirken hata: $error';
  }

  @override
  String get indexCode => 'Kodu indeksle';

  @override
  String get indexNoGrammars => 'Kod gramerleri yüklü değil';

  @override
  String get indexFailed => 'İndeksleme başarısız';

  @override
  String indexedSymbolsCount(int count) {
    return '$count sembol indekslendi';
  }

  @override
  String get nodeConfigAdvanced => 'Gelişmiş';

  @override
  String get nodeConfigReducer => 'Reducer';

  @override
  String get nodeConfigReducerHelp =>
      'Bu çıktı anahtarının zaten bir değeri varken nasıl birleştirileceği';

  @override
  String get nodeConfigTimeoutMs => 'Zaman aşımı (ms)';

  @override
  String get nodeConfigRetryAttempts => 'Yeniden deneme sayısı';

  @override
  String get nodeConfigContinueOnFail => 'Bu adım başarısız olsa da devam et';

  @override
  String get nodeConfigTeamId => 'Takım kimliği';

  @override
  String get nodeConfigDispatchMode => 'Gönderim kipi';

  @override
  String get nodeConfigOutputSchema => 'Çıktı şeması (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'Adım çıktısının uyması gereken JSON Schema';

  @override
  String get diffLineDisplay => 'Farklardaki uzun satırlar';

  @override
  String get diffLineDisplayDescription =>
      'Uzun satırları kaydır veya yatay kaydır';

  @override
  String get diffLineWrap => 'Kaydır';

  @override
  String get diffLineScroll => 'Yatay kaydır';

  @override
  String get actions => 'Eylemler';

  @override
  String get activate => 'Etkinleştir';

  @override
  String get activity => 'Etkinlik';

  @override
  String get activityLabel => 'ETKİNLİK';

  @override
  String get activitySearchHint => 'Etkinlik ara';

  @override
  String get activityNoMatches => 'Filtrelerinize uyan etkinlik yok';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$start–$end / $total';
  }

  @override
  String get activityPreviousPage => 'Önceki sayfa';

  @override
  String get activityNextPage => 'Sonraki sayfa';

  @override
  String get activityNetworkLocal => 'Localhost';

  @override
  String get activityClearFilter => 'Filtreyi temizle';

  @override
  String activityFilterIp(String ip) {
    return 'IP $ip';
  }

  @override
  String activityFilterCountry(String country) {
    return 'Ülke $country';
  }

  @override
  String get activitySavedWorkspaceLogo => 'Çalışma alanı logosunu kaydetti';

  @override
  String activityVerbCreated(String target) {
    return '$target oluşturdu';
  }

  @override
  String activityVerbUpdated(String target) {
    return '$target güncelledi';
  }

  @override
  String activityVerbDeleted(String target) {
    return '$target sildi';
  }

  @override
  String activityVerbAdded(String target) {
    return '$target ekledi';
  }

  @override
  String activityVerbRemoved(String target) {
    return '$target kaldırdı';
  }

  @override
  String activityVerbInvited(String target) {
    return '$target davet etti';
  }

  @override
  String activityVerbChanged(String target) {
    return '$target değiştirdi';
  }

  @override
  String activityVerbStarted(String target) {
    return '$target başlattı';
  }

  @override
  String activityVerbStopped(String target) {
    return '$target durdurdu';
  }

  @override
  String activityVerbWrote(String target) {
    return '$target yazdı';
  }

  @override
  String get activityTargetAgent => 'ajan';

  @override
  String get activityTargetTicket => 'bilet';

  @override
  String get activityTargetWorkspace => 'çalışma alanı';

  @override
  String get activityTargetRepository => 'depo';

  @override
  String get activityTargetMember => 'üye';

  @override
  String get activityTargetInvite => 'davet';

  @override
  String get activityTargetSpace => 'alan';

  @override
  String get activityTargetMessage => 'ileti';

  @override
  String get activityTargetCache => 'önbellek';

  @override
  String get activityTargetFile => 'dosya';

  @override
  String get activityTargetPipeline => 'pipeline';

  @override
  String get activityTargetTemplate => 'şablon';

  @override
  String get activityTargetProvider => 'sağlayıcı';

  @override
  String get activityTargetModel => 'model';

  @override
  String get activityTargetSkill => 'beceri';

  @override
  String get activityTargetTodo => 'yapılacak';

  @override
  String get activityTargetMeeting => 'toplantı';

  @override
  String get activityTargetProject => 'proje';

  @override
  String get activityTargetTeam => 'ekip';

  @override
  String get activityTargetDevice => 'cihaz';

  @override
  String get activityTargetPreference => 'tercih';

  @override
  String get activityTargetBudget => 'bütçe';

  @override
  String activityVerbApproved(String target) {
    return '$target onaylandı';
  }

  @override
  String activityVerbArchived(String target) {
    return '$target arşivlendi';
  }

  @override
  String activityVerbAssigned(String target) {
    return '$target atandı';
  }

  @override
  String activityVerbBackedUp(String target) {
    return '$target yedeklendi';
  }

  @override
  String activityVerbCancelled(String target) {
    return '$target iptal edildi';
  }

  @override
  String activityVerbCleared(String target) {
    return '$target temizlendi';
  }

  @override
  String activityVerbClosed(String target) {
    return '$target kapatıldı';
  }

  @override
  String activityVerbCommitted(String target) {
    return '$target commit edildi';
  }

  @override
  String activityVerbCompacted(String target) {
    return '$target sıkıştırıldı';
  }

  @override
  String activityVerbCompleted(String target) {
    return '$target tamamlandı';
  }

  @override
  String activityVerbConnected(String target) {
    return '$target bağlandı';
  }

  @override
  String activityVerbContinued(String target) {
    return '$target sürdürüldü';
  }

  @override
  String activityVerbDisconnected(String target) {
    return '$target bağlantısı kesildi';
  }

  @override
  String activityVerbDispatched(String target) {
    return '$target sevk edildi';
  }

  @override
  String activityVerbDrained(String target) {
    return '$target boşaltıldı';
  }

  @override
  String activityVerbEnrolled(String target) {
    return '$target kayda alındı';
  }

  @override
  String activityVerbEstimated(String target) {
    return '$target tahmin edildi';
  }

  @override
  String activityVerbImported(String target) {
    return '$target içe aktarıldı';
  }

  @override
  String activityVerbInstalled(String target) {
    return '$target yüklendi';
  }

  @override
  String activityVerbKilled(String target) {
    return '$target sonlandırıldı';
  }

  @override
  String activityVerbMarked(String target) {
    return '$target işaretlendi';
  }

  @override
  String activityVerbMerged(String target) {
    return '$target birleştirildi';
  }

  @override
  String activityVerbOpened(String target) {
    return '$target açıldı';
  }

  @override
  String activityVerbPaused(String target) {
    return '$target duraklatıldı';
  }

  @override
  String activityVerbPolled(String target) {
    return '$target yoklandı';
  }

  @override
  String activityVerbPrepared(String target) {
    return '$target hazırlandı';
  }

  @override
  String activityVerbProcessed(String target) {
    return '$target işlendi';
  }

  @override
  String activityVerbPublished(String target) {
    return '$target yayınlandı';
  }

  @override
  String activityVerbRefined(String target) {
    return '$target iyileştirildi';
  }

  @override
  String activityVerbRefreshed(String target) {
    return '$target yenilendi';
  }

  @override
  String activityVerbRegistered(String target) {
    return '$target kaydedildi';
  }

  @override
  String activityVerbRenamed(String target) {
    return '$target yeniden adlandırıldı';
  }

  @override
  String activityVerbReordered(String target) {
    return '$target yeniden sıralandı';
  }

  @override
  String activityVerbResponded(String target) {
    return '$target yanıtlandı';
  }

  @override
  String activityVerbRestored(String target) {
    return '$target geri yüklendi';
  }

  @override
  String activityVerbResumed(String target) {
    return '$target devam ettirildi';
  }

  @override
  String activityVerbRetried(String target) {
    return '$target yeniden denendi';
  }

  @override
  String activityVerbReverted(String target) {
    return '$target geri alındı';
  }

  @override
  String activityVerbReviewed(String target) {
    return '$target incelendi';
  }

  @override
  String activityVerbRan(String target) {
    return '$target çalıştırıldı';
  }

  @override
  String activityVerbSelected(String target) {
    return '$target seçildi';
  }

  @override
  String activityVerbSent(String target) {
    return '$target gönderildi';
  }

  @override
  String activityVerbStaged(String target) {
    return '$target stage’e alındı';
  }

  @override
  String activityVerbSteered(String target) {
    return '$target yönlendirildi';
  }

  @override
  String activityVerbSubmitted(String target) {
    return '$target iletildi';
  }

  @override
  String activityVerbSynced(String target) {
    return '$target senkronize edildi';
  }

  @override
  String activityVerbToggled(String target) {
    return '$target açılıp kapatıldı';
  }

  @override
  String activityVerbUninstalled(String target) {
    return '$target kaldırıldı';
  }

  @override
  String activityVerbUnstaged(String target) {
    return '$target stage’den çıkarıldı';
  }

  @override
  String get activityTargetActionPolicy => 'eylem politikası';

  @override
  String get activityTargetGoalRun => 'hedef çalıştırması';

  @override
  String get activityTargetRunLog => 'çalıştırma günlüğü';

  @override
  String get activityTargetWorkingMemory => 'çalışma belleği';

  @override
  String get activityTargetRoutingPolicy => 'yönlendirme politikası';

  @override
  String get activityTargetAutonomy => 'özerklik';

  @override
  String get activityTargetCalendar => 'takvim';

  @override
  String get activityTargetChecker => 'denetleyici';

  @override
  String get activityTargetEditor => 'düzenleyici';

  @override
  String get activityTargetConfirmation => 'onay';

  @override
  String get activityTargetTunnel => 'tünel';

  @override
  String get activityTargetConversation => 'konuşma';

  @override
  String get activityTargetCredentials => 'kimlik bilgileri';

  @override
  String get activityTargetDictation => 'dikte';

  @override
  String get activityTargetAgentRun => 'ajan çalıştırması';

  @override
  String get activityTargetEvalSuite => 'eval paketi';

  @override
  String get activityTargetWorker => 'worker';

  @override
  String get activityTargetWorktree => 'çalışma ağacı';

  @override
  String get activityTargetMcpServer => 'MCP sunucusu';

  @override
  String get activityTargetMemoryAccessGrant => 'bellek erişim izni';

  @override
  String get activityTargetMemoryDomain => 'bellek alanı';

  @override
  String get activityTargetMemoryFact => 'bellek olgusu';

  @override
  String get activityTargetMemoryPolicy => 'bellek politikası';

  @override
  String get activityTargetFeed => 'akış';

  @override
  String get activityTargetNote => 'not';

  @override
  String get activityTargetOrchestration => 'orkestrasyon';

  @override
  String get activityTargetPipelineRun => 'pipeline çalıştırması';

  @override
  String get activityTargetPipelineTrigger => 'pipeline tetikleyicisi';

  @override
  String get activityTargetPlan => 'plan';

  @override
  String get activityTargetPlaybook => 'playbook';

  @override
  String get activityTargetPullRequest => 'pull request';

  @override
  String get activityTargetReview => 'inceleme';

  @override
  String get activityTargetProcess => 'süreç';

  @override
  String get activityTargetProviderPolicy => 'sağlayıcı politikası';

  @override
  String get activityTargetReaction => 'tepki';

  @override
  String get activityTargetReviewSpace => 'inceleme alanı';

  @override
  String get activityTargetReviewStudio => 'inceleme stüdyosu';

  @override
  String get activityTargetServerData => 'sunucu verisi';

  @override
  String get activityTargetSoundscape => 'ses ortamı';

  @override
  String get activityTargetSession => 'oturum';

  @override
  String get activityTargetTerminal => 'terminal';

  @override
  String get activityTargetTicketLink => 'bilet bağlantısı';

  @override
  String get activityTargetTicketSync => 'bilet senkronizasyonu';

  @override
  String get activityTargetProfile => 'profil';

  @override
  String get activityTargetVoiceProfile => 'ses profili';

  @override
  String get activityTargetWeather => 'hava durumu tahmini';

  @override
  String get activityTargetWorkProduct => 'iş ürünü';

  @override
  String get activityChangedMemberRole => 'Bir üyenin rolünü değiştirdi';

  @override
  String get activityChangedMemberRepoAccess =>
      'Bir üyenin depo erişimini değiştirdi';

  @override
  String get activityUpdatedGitHubToken => 'GitHub token\'ını güncelledi';

  @override
  String get activityRefreshedWeather => 'Hava durumu tahminini yeniledi';

  @override
  String get activitySetWeatherLocation => 'Hava durumu konumunu ayarladı';

  @override
  String get activityClearedWeatherLocation => 'Hava durumu konumunu temizledi';

  @override
  String get activityMarkedAllArticlesRead =>
      'Tüm makaleleri okundu olarak işaretledi';

  @override
  String get activityMarkedArticleRead =>
      'Bir makaleyi okundu olarak işaretledi';

  @override
  String get activityUpdatedSavedArticle => 'Kayıtlı bir makaleyi güncelledi';

  @override
  String get activityTookOverSession => 'Oturumu devraldı';

  @override
  String get activityHandedBackSession => 'Oturumu geri verdi';

  @override
  String get activityCommittedAndPushed => 'Commit etti ve push etti';

  @override
  String get activityBackedUpServer => 'Sunucu verisini yedekledi';

  @override
  String get activityMarkedSpaceRead => 'Alanı okundu olarak işaretledi';

  @override
  String get activityRespondedToInvitation => 'Etkinlik davetine yanıt verdi';

  @override
  String get activityStartedCalendarConnect => 'Takvim bağlantısını başlattı';

  @override
  String get activityDisconnectedCalendar => 'Takvimin bağlantısını kesti';

  @override
  String get activityMarkedFileViewed =>
      'Bir dosyayı görüntülendi olarak işaretledi';

  @override
  String get activityRespondedToApproval => 'Bir onay isteğine yanıt verdi';

  @override
  String get activityChangedTunnel => 'Tünel ayarını değiştirdi';

  @override
  String get activitySentMessageToAgent => 'Ajana bir mesaj gönderdi';

  @override
  String get activityOpenedReviewSpace => 'İnceleme alanını açtı';

  @override
  String get activityOpenedStandingConversation => 'Kalıcı sohbeti açtı';

  @override
  String get activityStartedRecording => 'Kaydı başlattı';

  @override
  String get activityStoppedRecording => 'Kaydı durdurdu';

  @override
  String get activityToggledMcpServer => 'MCP sunucusunu açıp kapattı';

  @override
  String get activityUpdatedMcpToken => 'MCP token\'ını güncelledi';

  @override
  String get activitySavedApiKey => 'Bir API anahtarı kaydetti';

  @override
  String get activityRemovedProviderCredential =>
      'Bir sağlayıcı kimlik bilgisini kaldırdı';

  @override
  String get activityUpdatedLinkedRepos => 'Bağlı depoları güncelledi';

  @override
  String get activityUnlinkedRepo => 'Bir deponun bağlantısını kesti';

  @override
  String get activityUpdatedActionItem => 'Bir eylem öğesini güncelledi';

  @override
  String adRulesCount(int count) {
    return '$count reklam kuralı';
  }

  @override
  String get adapter => 'Adaptör';

  @override
  String get adapterLabel => 'Adaptör';

  @override
  String get adapters => 'Adaptörler';

  @override
  String get adaptersAutoDetected =>
      'Bu makinede otomatik algılanan ajan çalıştırıcıları mevcut. Ek çalıştırıcıları etkinleştirmek için eksik CLI araçlarını yükleyin.';

  @override
  String get add => 'Ekle';

  @override
  String get addAComment => 'Yorum ekle';

  @override
  String get addAReaction => 'Tepki ekle';

  @override
  String get addASuggestion => 'Öneri ekle';

  @override
  String get addAgents => 'Ajan ekle';

  @override
  String get addEmoji => 'Emoji ekle';

  @override
  String get addFeed => 'Akış ekle';

  @override
  String get addressBarHint => 'Bir URL girin';

  @override
  String get addFromFile => 'Dosyadan ekle';

  @override
  String get addGif => 'GIF ekle';

  @override
  String get addGithubRepoPrompt =>
      'Pull request\'leri görmek için en az bir GitHub deposu ekleyin';

  @override
  String get addLocalCheckoutDescription =>
      'Bu çalışma alanından hedeflemeye başlamak için yerel bir checkout ekleyin.';

  @override
  String get addRepository => 'Depo ekle';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count depo ekle',
      one: 'Depo ekle',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro =>
      'Sunucunun çalıştığı makinedeki klasörlere göz atın ve kaydetmek için git checkout\'larını seçin.';

  @override
  String get selectThisFolder => 'Bu klasörü seç';

  @override
  String get deselectThisFolder => 'Bu klasörün seçimini kaldır';

  @override
  String get goUp => 'Yukarı';

  @override
  String get noSubfoldersHere => 'Burada alt klasör yok';

  @override
  String get notAGitRepository => 'Bu klasör bir git deposu değil.';

  @override
  String get addToken => 'Token ekle';

  @override
  String get addWorkspace => 'Çalışma alanı ekle';

  @override
  String get addWorkspaceEllipsis => 'Çalışma alanı ekle…';

  @override
  String get added => 'Eklendi';

  @override
  String get addingEllipsis => 'Ekleniyor…';

  @override
  String get advancedLabel => 'Gelişmiş';

  @override
  String get agent => 'Ajan';

  @override
  String agentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agents',
      one: '1 agent',
    );
    return '$_temp0';
  }

  @override
  String get agentMdPath => 'Ajan MD yolu';

  @override
  String get agentName => 'Ajan adı';

  @override
  String get agentTitle => 'Ajan başlığı';

  @override
  String get agentUpdated => 'Ajan güncellendi.';

  @override
  String get agents => 'Ajanlar';

  @override
  String get agentsMentionSection => 'Ajanlar';

  @override
  String get usersMentionSection => 'Kişiler';

  @override
  String get ticketsMentionSection => 'Biletler';

  @override
  String get pullRequestsMentionSection => 'Pull requests';

  @override
  String get meetingsMentionSection => 'Toplantılar';

  @override
  String get entityRefTicketFallback => 'Bilet';

  @override
  String get entityRefPrFallback => 'Pull request';

  @override
  String get entityRefMeetingFallback => 'Toplantı';

  @override
  String get aiReview => 'AI incelemesi';

  @override
  String get all => 'Tümü';

  @override
  String get allAgentsAlreadyInSpace => 'Tüm ajanlar zaten bu alanda.';

  @override
  String get allCommits => 'Tüm commit\'ler';

  @override
  String get allSources => 'Tüm kaynaklar';

  @override
  String get allow => 'İzin ver';

  @override
  String get allowGitPush => 'git push\'a izin ver';

  @override
  String get allowGithubApi => 'GitHub API çağrılarına izin ver';

  @override
  String get allowNetwork => 'Genel ağ erişimine izin ver';

  @override
  String get apiKeys => 'API anahtarları';

  @override
  String get appFont => 'Uygulama yazı tipi';

  @override
  String get appLogLevelDebugDescription =>
      'Ayrıntılı izler ekler — geliştirme için.';

  @override
  String get appLogLevelDebugLabel => 'Hata ayıklama';

  @override
  String get appLogLevelErrorDescription =>
      'Yalnızca beklenmeyen hatalar ve istisnalar.';

  @override
  String get appLogLevelErrorLabel => 'Hata';

  @override
  String get appLogLevelInfoDescription =>
      'Yaşam döngüsü ve durum iletileri ekler.';

  @override
  String get appLogLevelInfoLabel => 'Bilgi';

  @override
  String get appLogLevelNoneDescription => 'Hiç konsol çıktısı yok.';

  @override
  String get appLogLevelNoneLabel => 'Yok';

  @override
  String get appLogLevelVerboseDescription =>
      'Her şey. Çok gürültülü — yalnızca hata ayıklama için kullanın.';

  @override
  String get appLogLevelVerboseLabel => 'Ayrıntılı';

  @override
  String get appLogLevelWarningDescription =>
      'Uyarılar ve kurtarılabilir sorunlar ekler.';

  @override
  String get appLogLevelWarningLabel => 'Uyarı';

  @override
  String get appearanceLanguage => 'Görünüm ve dil';

  @override
  String get apply => 'Uygula';

  @override
  String get approve => 'Onayla';

  @override
  String get agentApprovalRequired => 'Onay gerekli';

  @override
  String agentApprovalsMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tane daha bekliyor',
      one: '1 tane daha bekliyor',
    );
    return '$_temp0';
  }

  @override
  String get approved => 'Onaylandı';

  @override
  String get articleNoun => 'Makale';

  @override
  String get articlesSubscribed => 'Abone olduğunuz akışlardaki makaleler.';

  @override
  String get askAi => 'AI\'ya sor';

  @override
  String get askAiReviewDescription => 'Bu PR\'ı AI\'ya incelet';

  @override
  String get assignees => 'Atananlar';

  @override
  String get attachImage => 'Görüntü ekle';

  @override
  String get attachedAgents => 'Ekli ajanlar';

  @override
  String get audioInput => 'Ses girişi';

  @override
  String get audioOutput => 'Ses çıkışı';

  @override
  String get authenticationToken => 'Kimlik doğrulama token\'ı';

  @override
  String authoredByLabel(String role) {
    return 'Yazan: $role';
  }

  @override
  String get autoRecommended => 'Otomatik (önerilen)';

  @override
  String get available => 'Kullanılabilir';

  @override
  String get awaitingYourReview => 'İncelemenizi bekliyor';

  @override
  String get back => 'Geri';

  @override
  String get backLabel => 'Geri';

  @override
  String get backend => 'Backend';

  @override
  String get blockAdsTrackers =>
      'Reklamları, izleyicileri ve çerez bildirimlerini engelle';

  @override
  String get blocking => 'Engelleyici';

  @override
  String get bookmarkLabel => 'Yer imi';

  @override
  String get briefDescription => 'Kısa açıklama';

  @override
  String get bugLabel => 'HATA';

  @override
  String get bundledDefaultsNeverUpdated =>
      'Paketlenmiş varsayılanlar — hiç güncellenmez';

  @override
  String get cancel => 'İptal';

  @override
  String get cancelEdit => 'Düzenlemeyi iptal et';

  @override
  String get categoryCreation => 'Oluşturma';

  @override
  String get categoryEditing => 'Düzenleme';

  @override
  String get categoryNavigation => 'Gezinme';

  @override
  String get categorySystem => 'Sistem';

  @override
  String get categoryView => 'Kategori görünümü';

  @override
  String get change => 'Değiştir';

  @override
  String get changesRequested => 'Değişiklik istendi';

  @override
  String get spacesMentionSection => 'Alanlar';

  @override
  String get checkForUpdates => 'Güncellemeleri denetle';

  @override
  String get checking => 'Denetleniyor';

  @override
  String get checkingEllipsis => 'Denetleniyor…';

  @override
  String get chooseAppFont => 'Uygulama yazı tipini seç';

  @override
  String get chooseCodeFont => 'Kod yazı tipini seç';

  @override
  String get chooseRunner => 'Ajan çalıştırıcınızı seçin.';

  @override
  String get clear => 'Temizle';

  @override
  String get clickToRetry => 'Yeniden denemek için tıklayın';

  @override
  String get close => 'Kapat';

  @override
  String get closeEsc => 'Kapat (Esc)';

  @override
  String get closeReader => 'Okuyucuyu kapat';

  @override
  String get closed => 'Kapalı';

  @override
  String get codeFont => 'Kod yazı tipi';

  @override
  String get codeFontLigatures => 'Kod yazı tipi ligatürleri';

  @override
  String get codeFontLigaturesDescription =>
      'Programlama ligatürlerini (=>, !=, ->) kodda ve diff\'lerde birleşik glifler olarak göster';

  @override
  String get collapse => 'Daralt';

  @override
  String get commandPalette => 'Komut paleti';

  @override
  String get commandPaletteOrgMembers => 'Kuruluş üyeleri';

  @override
  String get commandPaletteBrowseTeam => 'Ekibe göz at';

  @override
  String get commandPaletteBrowseTeamDesc => 'Tüm kuruluş üyelerini görüntüle';

  @override
  String get compactDone =>
      'Sohbet sıkıştırıldı. Önceki geçmiş bir özete indirgendi.';

  @override
  String get compactNothing =>
      'Henüz sıkıştırılacak bir şey yok. Sohbet hâlâ kısa.';

  @override
  String get compactBusy =>
      'Bir ajan hâlâ çalışıyor. Tur bittiğinde sıkıştırın.';

  @override
  String get compactUnavailable => 'Bu sunucuda sıkıştırma kullanılamıyor.';

  @override
  String get commandsMentionSection => 'Komutlar';

  @override
  String get comment => 'Yorum';

  @override
  String get commentOnThisFile => 'Bu dosyaya yorum yap';

  @override
  String get commented => 'Yorumlandı';

  @override
  String get commits => 'Commit\'ler';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'Toplam $total commit\'in son $loaded tanesi gösteriliyor';
  }

  @override
  String get prCloneProgressCloningTitle => 'Depo klonlanıyor';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'Bu PR $fileCount dosyayı değiştiriyor ve GitHub API sınırını aşıyor. Depo yerel olarak klonlanıyor…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'Bu PR GitHub\'ın API dosya sınırını aşıyor. Depo yerel olarak klonlanıyor…';

  @override
  String get prCloneProgressFetchingTitle => 'PR ref\'leri alınıyor';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'Temel dal ve PR head ref\'i alınıyor…';

  @override
  String get prCloneProgressComputingTitle => 'Diff hesaplanıyor';

  @override
  String get prCloneProgressComputingSubtitle =>
      'git diff yerel olarak çalıştırılıyor…';

  @override
  String get prCloneProgressErrorTitle => 'Diff yüklenemedi';

  @override
  String get prCloneProgressErrorSubtitle =>
      'Klonlama veya diff hesaplama sırasında bir hata oluştu. Lütfen yenilemeyi deneyin.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'Hâlâ çalışıyor… $elapsed geçti';
  }

  @override
  String confidenceLabel(int percent) {
    return 'Güven: %$percent';
  }

  @override
  String get configureAgentIdentities =>
      'Ajan kimliklerini, istemleri, becerileri yapılandırın ve çalıştırmaları görüntüleyin.';

  @override
  String get configureDefaultRunners =>
      'Yeni alanlar ve başlık oluşturma için hangi bağdaştırıcı ve modelin kullanılacağını yapılandırın.';

  @override
  String get configuredLabel => 'Yapılandırıldı.';

  @override
  String get confirmedBy => 'Onaylayan';

  @override
  String get consensus => 'Uzlaşı';

  @override
  String get contentHint => 'Nelerin hatırlanması gerektiği';

  @override
  String get contentLabel => 'İçerik';

  @override
  String get contentMarkdown => 'İçerik (Markdown)';

  @override
  String get contextWindowSize => 'Bağlam penceresi boyutu';

  @override
  String modelContextChip(String size) {
    return 'Model · $size';
  }

  @override
  String get continueLabel => 'Devam et';

  @override
  String get conversationMode => 'Mod';

  @override
  String cookieRulesCount(int count) {
    return '$count çerez kuralı';
  }

  @override
  String get copied => 'Kopyalandı!';

  @override
  String get copy => 'Kopyala';

  @override
  String get copyAddress => 'Adresi kopyala';

  @override
  String get copyBaseBranchTooltip => 'Temel dal adını kopyala';

  @override
  String get copyHeadBranchTooltip => 'Head dal adını kopyala';

  @override
  String couldNotListDevices(String error) {
    return 'Cihazlar listelenemedi: $error';
  }

  @override
  String get create => 'Oluştur';

  @override
  String get createOrSelectWorkspace =>
      'Depo eklemeden önce bir çalışma alanı oluşturun veya seçin.';

  @override
  String get createPullRequest => 'Pull request oluştur';

  @override
  String get createdByMe => 'Benim oluşturduklarım';

  @override
  String createdLabel(String date) {
    return 'Oluşturulma: $date';
  }

  @override
  String get currentParticipants => 'Mevcut katılımcılar';

  @override
  String get customCapabilitiesDescription => 'Özel yetenek açıklaması';

  @override
  String get customSystemPrompt => 'Bu ajan için özel sistem promptu...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün önce',
      one: '1 gün önce',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'Devre dışı bırak';

  @override
  String get defaultCapabilities => 'Varsayılan yetenekler · yeni space\'ler';

  @override
  String get defaultChat => 'Varsayılan sohbet';

  @override
  String get defaultRunners => 'Varsayılan runner\'lar';

  @override
  String get delete => 'Sil';

  @override
  String get deleteAgent => 'Ajanı sil';

  @override
  String deleteAgentConfirm(String name) {
    return '\"$name\" silinsin mi? Bu işlem geri alınamaz.';
  }

  @override
  String get deleteSpace => 'Space\'i sil';

  @override
  String deleteConfirmName(String name) {
    return '\"$name\" silinsin mi?';
  }

  @override
  String get archiveConversation => 'Sohbeti arşivle';

  @override
  String get deleteFact => 'Gerçeği sil';

  @override
  String get deleteFeedBody =>
      'Bu, feed\'i ve önbelleğe alınmış tüm makalelerini kaldırır. Bu feed\'den yer imine eklenmiş makaleler de kaldırılır.';

  @override
  String deleteFeedConfirm(String name) {
    return '\"$name\" silinsin mi?';
  }

  @override
  String get deletePolicy => 'Politikayı sil';

  @override
  String get deletePolicyConfirm =>
      'Bu politika silinsin mi? Bu işlem geri alınamaz.';

  @override
  String deleteTopicConfirm(String topic) {
    return '\"$topic\" silinsin mi? Bu işlem geri alınamaz.';
  }

  @override
  String get deleteWorkspace => 'Çalışma alanını sil';

  @override
  String get deny => 'Reddet';

  @override
  String get detailsLabel => 'Ayrıntılar';

  @override
  String get descriptionLabel => 'Açıklama';

  @override
  String detectedBackend(String label) {
    return 'Algılandı: $label';
  }

  @override
  String get detectedRunners => 'Algılanan runner\'lar';

  @override
  String get detectingAdapters => 'Adaptörler algılanıyor…';

  @override
  String get detectingInputDevices => 'Giriş cihazları algılanıyor…';

  @override
  String detectionFailed(String error) {
    return 'Algılama başarısız: $error';
  }

  @override
  String get disabled => 'Devre dışı';

  @override
  String get discover => 'Keşfet';

  @override
  String get dismissed => 'Kapatıldı';

  @override
  String get domainHint => 'ör. api-performance';

  @override
  String get domainLabel => 'Alan';

  @override
  String get download => 'İndir';

  @override
  String get downloadingLabel => 'İndiriliyor';

  @override
  String downloadingModel(int pct) {
    return 'Model indiriliyor… %$pct';
  }

  @override
  String get draft => 'Taslak';

  @override
  String get draftLabel => 'Taslak';

  @override
  String get edit => 'Düzenle';

  @override
  String get edited => 'düzenlendi';

  @override
  String get editMessage => 'Mesajı düzenle';

  @override
  String get deleteMessage => 'Mesajı sil';

  @override
  String get deleteMessageConfirm =>
      'Bu mesaj silinsin mi? Bu işlem geri alınamaz.';

  @override
  String get messageDeleted => 'Mesaj silindi';

  @override
  String get searchInConversation => 'Sohbette ara';

  @override
  String get searchMessagesHint => 'Mesajlarda ara…';

  @override
  String get noMessagesFound => 'Mesaj bulunamadı';

  @override
  String get editFact => 'Gerçeği düzenle';

  @override
  String get editPolicy => 'Politikayı düzenle';

  @override
  String get editSuggestedCodeHint => 'Önerilen kodu düzenle…';

  @override
  String get editSuggestion => 'Düzenleme önerisi';

  @override
  String get egArchitect => 'ör. architect';

  @override
  String get egControlCenter => 'ör. control-center';

  @override
  String get egPlatform => 'ör. Platform';

  @override
  String get egSamuelAlev => 'ör. SamuelAlev';

  @override
  String get egSoftwareArchitect => 'ör. Yazılım Mimarı';

  @override
  String get egTheVerge => 'ör. The Verge';

  @override
  String get egTokenLimit => 'ör. 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'Kurulum başarısız: $error';
  }

  @override
  String get embeddingInstalled =>
      'Yerel embedding modeli kuruldu. Hibrit arama etkin.';

  @override
  String get embeddingModel => 'Embedding modeli (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'Kurulu değil. Etkinleştirilene kadar arama yalnızca anahtar kelimeye düşer.';

  @override
  String get embeddingRedownloadBody =>
      'Mevcut model dosyaları silinip yeniden indirilecek. İndirme tamamlanana kadar semantik arama kullanılamaz.';

  @override
  String get embeddingRemoveBody =>
      'Yeniden kurana kadar semantik arama devre dışı kalır. İstediğiniz zaman yeniden kurabilirsiniz.';

  @override
  String get speakerDiarization => 'Konuşmacı diarizasyonu';

  @override
  String get diarizationModel => 'Diarizasyon modeli';

  @override
  String get diarizationInstalled =>
      'Kurulu — toplantı dökümlerinde konuşmacıları adlandırır';

  @override
  String get diarizationNotInstalled =>
      'Kurulu değil — toplantı konuşmacıları ayrılmaz';

  @override
  String diarizationInstallFailed(String error) {
    return 'Kurulum başarısız: $error';
  }

  @override
  String get redownloadDiarizationModel => 'Diarizasyon modelini yeniden indir';

  @override
  String get diarizationRedownloadBody =>
      'Mevcut diarizasyon modellerini kaldırır ve yeniden indirir.';

  @override
  String get removeDiarizationModel => 'Diarizasyon modelini kaldır';

  @override
  String get diarizationRemoveBody =>
      'Cihazdaki diarizasyon modellerini siler. Daha önce üretilen toplantı dökümleri etkilenmez.';

  @override
  String get enableNotifications => 'Bildirimleri etkinleştir';

  @override
  String get enableSandboxing => 'Korumalı alanı etkinleştir';

  @override
  String get enabled => 'Etkin';

  @override
  String errorCreatingAgent(String error) {
    return 'Ajan oluşturulurken hata: $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'Ajan silinirken hata: $error';
  }

  @override
  String errorWithDetail(String error) {
    return 'Hata: $error';
  }

  @override
  String get expand => 'Genişlet';

  @override
  String extractingModel(int pct) {
    return 'Model çıkarılıyor… $pct%';
  }

  @override
  String get fact => 'Olgu';

  @override
  String factCount(int count) {
    return '$count olgu';
  }

  @override
  String factCountPlural(int count) {
    return '$count olgu';
  }

  @override
  String get facts => 'Olgular';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount olgu · $policyCount politika';
  }

  @override
  String get failed => 'Başarısız';

  @override
  String failedToDispatch(String error) {
    return 'Gönderilemedi: $error';
  }

  @override
  String get failedToLoad => 'Yüklenemedi';

  @override
  String failedToLoadAgents(String error) {
    return 'Ajanlar yüklenemedi: $error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'Akışlar yüklenemedi: $error';
  }

  @override
  String get failedToLoadGifs => 'GIF\'ler yüklenemedi';

  @override
  String failedToLoadLogs(String error) {
    return 'Günlükler yüklenemedi: $error';
  }

  @override
  String get failedToLoadRepos => 'Depolar yüklenemedi';

  @override
  String get failedToLoadWorkspaces => 'Çalışma alanları yüklenemedi';

  @override
  String failedToStartAiReview(String error) {
    return 'AI incelemesi başlatılamadı: $error';
  }

  @override
  String get failedToStartMicTest => 'Mikrofon testi başlatılamadı.';

  @override
  String failedToSubmitReview(String error) {
    return 'İnceleme gönderilemedi: $error';
  }

  @override
  String failedToUpload(String name, String error) {
    return '$name yüklenemedi: $error';
  }

  @override
  String failedWithError(String error) {
    return 'Başarısız: $error';
  }

  @override
  String get failure => 'Başarısızlık';

  @override
  String get feedAlreadyExists => 'Bu URL\'ye sahip bir akış zaten var.';

  @override
  String get feedUrlExample => 'ör. https://example.com/feed.xml';

  @override
  String get feedUrlLabel => 'Akış URL\'si';

  @override
  String feedsCount(int count) {
    return 'Akışlar ($count)';
  }

  @override
  String get filesChanged => 'Değişen dosyalar';

  @override
  String filesCount(int count) {
    return '$count dosya';
  }

  @override
  String get filesMentionSection => 'Dosyalar';

  @override
  String get filterAgents => 'Ajanları filtrele...';

  @override
  String get filterFilesHint => 'Dosyaları filtrele…';

  @override
  String get filterLists => 'Listeleri filtrele';

  @override
  String get filterSkillsPlaceholder => 'Becerileri filtrele…';

  @override
  String get finish => 'Bitir';

  @override
  String get fix => 'Düzelt';

  @override
  String get forward => 'İleri';

  @override
  String get gatesGithubPatPush =>
      'GitHub PAT enjeksiyonunu kısıtlar. Ajanın push yapması için gerekli.';

  @override
  String get general => 'Genel';

  @override
  String get githubLink => 'GitHub bağlantısı';

  @override
  String get claudeStatusFetchFailed => 'status.claude.com\'a ulaşılamadı';

  @override
  String get claudeStatusOpenInBrowser => 'status.claude.com\'u aç';

  @override
  String get githubStatusFetchFailed => 'githubstatus.com\'a ulaşılamadı';

  @override
  String get githubDegradedTitle => 'GitHub sorun bildiriyor';

  @override
  String githubDegradedStatusLine(String status) {
    return 'GitHub durumu: $status.';
  }

  @override
  String githubDegradedBody(String status) {
    return 'GitHub durumu: $status. Kurtulana kadar pull request verileri eski veya eksik olabilir.';
  }

  @override
  String get githubStatusOpenInBrowser => 'githubstatus.com\'u aç';

  @override
  String get githubStatusRefresh => 'Yenile';

  @override
  String githubStatusUpdated(String time) {
    return 'Güncellendi $time';
  }

  @override
  String get kimiStatusFetchFailed => 'status.moonshot.cn\'e ulaşılamadı';

  @override
  String get kimiStatusOpenInBrowser => 'status.moonshot.cn\'i aç';

  @override
  String get openaiStatusFetchFailed => 'status.openai.com\'a ulaşılamadı';

  @override
  String get openaiStatusOpenInBrowser => 'status.openai.com\'u aç';

  @override
  String get serviceStatusMaintenance => 'Bakım';

  @override
  String get serviceStatusMajorIssues => 'Ciddi sorunlar';

  @override
  String get serviceStatusMinorIssues => 'Küçük sorunlar';

  @override
  String get serviceStatusOperational => 'Çalışıyor';

  @override
  String get serviceStatusOutage => 'Kesinti';

  @override
  String get serviceStatusTitle => 'Hizmet durumu';

  @override
  String get serviceStatusUnknown => 'Bilinmiyor';

  @override
  String lastChecked(String time) {
    return 'Kontrol edildi $time';
  }

  @override
  String get lastCheckedRecently => 'Yakın zamanda kontrol edildi';

  @override
  String get giveYourWorkAHome => 'Çalışmana bir yuva ver.';

  @override
  String get goBack => 'Geri git';

  @override
  String get goForward => 'İleri git';

  @override
  String get googleFonts => 'Google Fonts';

  @override
  String get high => 'Yüksek';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saat önce',
      one: '1 saat önce',
    );
    return '$_temp0';
  }

  @override
  String get images => 'Görseller';

  @override
  String get inactive => 'Etkin değil';

  @override
  String get install => 'Yükle';

  @override
  String get installRequired => 'Yükleme gerekli';

  @override
  String installedVersion(String version) {
    return 'Yüklü $version';
  }

  @override
  String get invite => 'Davet et';

  @override
  String get inviteAgent => 'Ajan davet et';

  @override
  String get isolateAgentExecution => 'Ajan yürütmesini yalıt.';

  @override
  String get justNow => 'Az önce';

  @override
  String get keepSandboxing => 'Sandboxing\'i koru';

  @override
  String get keybindingAddARepositoryDescription => 'Depo ekle';

  @override
  String get keybindingAddRepository => 'Depo ekle';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'Seçili makaleyi yer imlerine ekle veya kaldır';

  @override
  String get keybindingCommandPalette => 'Komut paleti';

  @override
  String get keybindingCreateANewAgentDescription => 'Yeni ajan oluştur';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'Yeni çalışma alanı oluştur';

  @override
  String get keybindingFocusSearch => 'Aramaya odaklan';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'Pull request arama alanına odaklan';

  @override
  String get keybindingNewAgent => 'Yeni ajan';

  @override
  String get keybindingNewWorkspace => 'Yeni çalışma alanı';

  @override
  String get keybindingNextArticle => 'Sonraki makale';

  @override
  String get keybindingNextSpace => 'Sonraki space';

  @override
  String get keybindingNextWorkspace => 'Sonraki çalışma alanı';

  @override
  String get keybindingOpenArticle => 'Makaleyi aç';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'Kenar çubuğundaki çalışma alanı değiştirici penceresini aç veya kapat';

  @override
  String get keybindingOpenPr => 'PR aç';

  @override
  String get keybindingOpenSettings => 'Ayarları aç';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'Uygulama ayarlarını aç';

  @override
  String get keybindingOpenTheCommandPaletteDescription => 'Komut paletini aç';

  @override
  String get keybindingOpenTheSelectedArticleDescription =>
      'Seçili makaleyi aç';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'Seçili pull request\'i aç';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'Seçili çalışma alanını aç';

  @override
  String get keybindingOpenWorkspace => 'Çalışma alanını aç';

  @override
  String get keybindingPreviousArticle => 'Önceki makale';

  @override
  String get keybindingPreviousSpace => 'Önceki alan';

  @override
  String get keybindingPreviousWorkspace => 'Önceki çalışma alanı';

  @override
  String get keybindingRefresh => 'Yenile';

  @override
  String get keybindingRefreshAllFeedsDescription => 'Tüm akışları yenile';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'Pull request listesini yenile';

  @override
  String get keybindingRescanForAdaptersDescription =>
      'Bağdaştırıcıları yeniden tara';

  @override
  String get keybindingSelectTheNextArticleDescription =>
      'Sonraki makaleyi seç';

  @override
  String get keybindingSelectTheNextSpaceDescription => 'Sonraki alanı seç';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'Önceki makaleyi seç';

  @override
  String get keybindingSelectThePreviousSpaceDescription => 'Önceki alanı seç';

  @override
  String get keybindingSendMessage => 'Mesaj gönder';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'Geçerli mesajı gönder';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Açık ve koyu tema arasında geç';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Sekizinci çalışma alanına geç';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Beşinci çalışma alanına geç';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'İlk çalışma alanına geç';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'Dördüncü çalışma alanına geç';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'Sonraki çalışma alanına geç';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'Dokuzuncu çalışma alanına geç';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'Önceki çalışma alanına geç';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'İkinci çalışma alanına geç';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'Yedinci çalışma alanına geç';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'Altıncı çalışma alanına geç';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'Üçüncü çalışma alanına geç';

  @override
  String get keybindingToggleBookmark => 'Yer imini aç/kapat';

  @override
  String get keybindingToggleTheme => 'Temayı değiştir';

  @override
  String get keybindingToggleWorkspaceSwitcher =>
      'Çalışma alanı değiştiriciyi aç/kapat';

  @override
  String get keybindingWorkspace1 => 'Çalışma alanı 1';

  @override
  String get keybindingWorkspace2 => 'Çalışma alanı 2';

  @override
  String get keybindingWorkspace3 => 'Çalışma alanı 3';

  @override
  String get keybindingWorkspace4 => 'Çalışma alanı 4';

  @override
  String get keybindingWorkspace5 => 'Çalışma alanı 5';

  @override
  String get keybindingWorkspace6 => 'Çalışma alanı 6';

  @override
  String get keybindingWorkspace7 => 'Çalışma alanı 7';

  @override
  String get keybindingWorkspace8 => 'Çalışma alanı 8';

  @override
  String get keybindingWorkspace9 => 'Çalışma alanı 9';

  @override
  String get keybindings => 'Kısayollar';

  @override
  String get keybindingsDescription =>
      'Tüm klavye kısayolları. Kısayollar sabittir ve yeniden atanamaz.';

  @override
  String get killRunning => 'Çalışanı sonlandır';

  @override
  String get languageSystem => 'Sistem';

  @override
  String get leaveACommentEllipsis => 'Yorum bırak…';

  @override
  String get legendLabel => 'Gösterge';

  @override
  String get lessLabel => 'Daha az';

  @override
  String get letsPluginTools => 'Araçlarını bağlayalım.';

  @override
  String get level => 'Düzey';

  @override
  String get loadingAgents => 'Ajanlar yükleniyor…';

  @override
  String get loadingModels => 'Modeller yükleniyor…';

  @override
  String get loadingProviders => 'Sağlayıcılar yükleniyor…';

  @override
  String get logLevel => 'Log düzeyi';

  @override
  String get logs => 'Loglar';

  @override
  String get low => 'Düşük';

  @override
  String get maintenance => 'Bakım';

  @override
  String get manageParticipants => 'Katılımcıları yönet';

  @override
  String get manageWorkspaces => 'Çalışma alanlarını yönet';

  @override
  String get reorderWorkspace => 'Çalışma alanını yeniden sırala';

  @override
  String get matchOsAppearance =>
      'İşletim sistemi görünümünü kullan veya sabit bir mod seç.';

  @override
  String get mcpAuthToken => 'MCP kimlik doğrulama jetonu';

  @override
  String get mcpNotAvailableOnServer =>
      'Bağlı sunucuda MCP sunucu denetimi kullanılamıyor.';

  @override
  String get modelManagedOnServer =>
      'Bu model sunucu makinesinde çalışır ve orada yönetilir.';

  @override
  String get mcpServer => 'MCP sunucusu';

  @override
  String get medium => 'Orta';

  @override
  String get memoryDataHint =>
      'Ajanlar çalıştıkça olgular ve politikalar burada görünür.';

  @override
  String get memoryLabel => 'Bellek';

  @override
  String get merge => 'Birleştir';

  @override
  String get merged => 'Birleştirildi';

  @override
  String get messagePlaceholder => 'Mesaj… (@ ile bahset, / ile komut)';

  @override
  String get navConversations => 'Alanlar';

  @override
  String get microphonePermissionDenied => 'Mikrofon izni reddedildi.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dakika önce',
      one: '1 dakika önce',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'Model';

  @override
  String get modified => 'Değiştirildi';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ay önce',
      one: '1 ay önce',
    );
    return '$_temp0';
  }

  @override
  String get moreLabel => 'Daha fazla';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'Ad';

  @override
  String get nameAndTitleRequired => 'Ad ve başlık gerekli.';

  @override
  String get nameAndUrlRequired => 'Ad ve URL gerekli';

  @override
  String get nameLabel => 'Ad';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'Yerel sandbox $platform üzerinde kullanılabilir.';
  }

  @override
  String get nativeSandboxNeedsInstall => 'Yerel sandbox kurulumu gerekli';

  @override
  String get navObservability => 'Gözlemlenebilirlik';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String networkBlockCount(int count) {
    return '$count ağ bloğu';
  }

  @override
  String get neutral => 'Nötr';

  @override
  String get newCommitsPushed =>
      'Yeni commit\'ler gönderildi — farkı yeniden yüklemek için tıkla';

  @override
  String get newFact => 'Yeni olgu';

  @override
  String get newPolicy => 'Yeni politika';

  @override
  String get newsfeed => 'Haber akışı';

  @override
  String get newsfeedLabel => 'Haber akışı';

  @override
  String get newsfeedSettingsDescription =>
      'Abone olunan akışları ve okuyucu tercihlerini yönet.';

  @override
  String get newsfeedSettingsTitle => 'Haber akışı ayarları';

  @override
  String get nextMatch => 'Sonraki eşleşme (↵)';

  @override
  String get noActiveWorkspace => 'Etkin çalışma alanı veya depo seçilmedi.';

  @override
  String get noActiveWorkspaceCreate => 'Etkin çalışma alanı yok';

  @override
  String get noActiveWorkspaceGithub =>
      'GitHub deposu olan etkin çalışma alanı yok.';

  @override
  String get noAgents => 'Ajan yok';

  @override
  String get noArticlesYet => 'Henüz makale yok';

  @override
  String get noArticlesYetBody => 'Akışlarınızdaki makaleler burada görünür.';

  @override
  String get noExecutionLogsYet => 'Henüz yürütme günlüğü yok';

  @override
  String get noFacts => 'Henüz olgu yok';

  @override
  String get noFeedsYet => 'Henüz akış yok';

  @override
  String get noFileAnchor =>
      'Dosya çapası yok — satır içi yorum gönderilemiyor.';

  @override
  String get noFileChangesInScope => 'Bu kapsamda dosya değişikliği yok';

  @override
  String get noGifsFound => 'GIF bulunamadı';

  @override
  String get noInputDevicesDetected =>
      'Giriş aygıtı algılanmadı — sistem varsayılanı kullanılıyor.';

  @override
  String get noMatchingFiles => 'Eşleşen dosya yok';

  @override
  String get noMatchingGoogleFonts => 'Eşleşen Google Fonts yok.';

  @override
  String get noMemoryData => 'Henüz bellek verisi yok';

  @override
  String get noMessagesYet => 'Henüz mesaj yok';

  @override
  String get noModelsAdvertised => 'Bu bağdaştırıcının duyurduğu model yok.';

  @override
  String get noOpenPullRequests => 'Açık pull request yok';

  @override
  String get noPolicies => 'Henüz politika yok';

  @override
  String get noReposInWorkspaceYet => 'Bu çalışma alanında henüz depo yok';

  @override
  String get noRunnersDetected =>
      'Henüz runner algılanmadı. Yeniden taramak için yenileyin.';

  @override
  String get noSavedArticles => 'Kayıtlı makale yok';

  @override
  String get noSavedArticlesBody => 'Kaydettiğiniz makaleler burada görünür.';

  @override
  String noShortcutsMatch(String query) {
    return '\"$query\" ile eşleşen kısayol yok';
  }

  @override
  String get noSystemFonts => 'Sistem yazı tipi algılanmadı.';

  @override
  String get noTokenSet => 'Token ayarlanmamış — erişim kısıtsız.';

  @override
  String get noWorkingMemory => 'Henüz çalışma belleği notu yok.';

  @override
  String get noneAllRoles => 'Yok (tüm roller)';

  @override
  String get notAvailable => 'Kullanılamıyor';

  @override
  String get notConfiguredLabel => 'Yapılandırılmamış.';

  @override
  String get notFoundLabel => 'Bulunamadı';

  @override
  String get notes => 'Notlar';

  @override
  String get notificationAgentFinished => 'Ajan tamamlandı';

  @override
  String get notificationPrMentioned => 'Pull request\'te bahsedildi';

  @override
  String get notificationNewMessages => 'Yeni mesajlar';

  @override
  String get notificationPrMerged => 'PR birleştirildi';

  @override
  String get notificationPrPublished => 'PR yayınlandı';

  @override
  String get notificationReviewRequested => 'İnceleme istendi';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get notifyAgentRunCompleted =>
      'Bir ajan çalışmayı tamamladığında bildir.';

  @override
  String get notifyPrMentioned =>
      'Bir pull request\'te sizden bahsedildiğinde bildir.';

  @override
  String get notifyNewMessages =>
      'Diğer alanlardaki yeni ajan mesajlarında bildir.';

  @override
  String get notifyPrMerged => 'Bir pull request birleştirildiğinde bildir.';

  @override
  String get notifyPrPublished =>
      'Bir ajan pull request yayınladığında bildir.';

  @override
  String get notifyReviewRequested =>
      'Bir pull request\'te incelemeniz istendiğinde bildir.';

  @override
  String get notificationReviewStale => 'İnceleme güncel değil';

  @override
  String get notifyReviewStale =>
      'İncelediğiniz bir pull request\'e yeni commit geldiğinde';

  @override
  String get notificationPrMergeReadiness => 'Birleştirmeye hazır';

  @override
  String get notifyPrMergeReadiness =>
      'Yazar olduğunuz bir pull request birleştirilebilir hale geldiğinde veya bu durumu kaybettiğinde bildir.';

  @override
  String get notificationPrReviewDecision => 'İnceleme kararları';

  @override
  String get notifyPrReviewDecision =>
      'Bir inceleyen onayladığında, değişiklik istediğinde veya onayı iptal edildiğinde bildir.';

  @override
  String get notificationPrChecksStatus => 'Kontroller';

  @override
  String get notifyPrChecksStatus =>
      'Yazar olduğunuz bir pull request\'te CI başarısız olduğunda ve düzeldiğinde bildir.';

  @override
  String get notificationPrThreadActivity => 'İnceleme dizileri';

  @override
  String get notifyPrThreadActivity =>
      'İçinde olduğunuz bir dizide biri yanıt verdiğinde veya çözdüğünde bildir.';

  @override
  String get notificationPrReadyToMerge => 'Birleştirmeye hazır';

  @override
  String notificationPrReadyToMergeBody(String prTitle) {
    return '$prTitle için gereken her şey tamam.';
  }

  @override
  String get notificationPrMergeBlocked => 'Artık birleştirilemez';

  @override
  String notificationPrMergeBlockedBodyConflicts(String prTitle) {
    return '$prTitle temel dal ile çakışıyor.';
  }

  @override
  String notificationPrMergeBlockedBodyBehind(String prTitle) {
    return '$prTitle temel dalın gerisinde.';
  }

  @override
  String notificationPrMergeBlockedBodyReviews(String prTitle) {
    return '$prTitle zorunlu bir inceleme bekliyor.';
  }

  @override
  String notificationPrMergeBlockedBodyChanges(String prTitle) {
    return 'Bir inceleyen $prTitle için değişiklik istedi.';
  }

  @override
  String notificationPrMergeBlockedBodyChecks(String prTitle) {
    return '$prTitle üzerinde kontroller başarısız.';
  }

  @override
  String notificationPrMergeBlockedBodyOther(String prTitle) {
    return '$prTitle artık birleştirilemez.';
  }

  @override
  String get notificationPrApproved => 'Pull request onaylandı';

  @override
  String notificationPrApprovedBodyBy(String login, String prTitle) {
    return '$login $prTitle isteğini onayladı';
  }

  @override
  String notificationPrApprovedBody(String prTitle) {
    return '$prTitle onaylandı';
  }

  @override
  String notificationPrReviewersRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'yanıt vermesi gereken $count inceleyen var',
      one: 'yanıt vermesi gereken 1 inceleyen var',
      zero: 'kalan inceleyen yok',
    );
    return '$_temp0';
  }

  @override
  String get notificationPrChangesRequested => 'Değişiklik istendi';

  @override
  String notificationPrChangesRequestedBodyBy(String login, String prTitle) {
    return '$login $prTitle için değişiklik istedi';
  }

  @override
  String notificationPrChangesRequestedBody(String prTitle) {
    return '$prTitle için değişiklik istendi';
  }

  @override
  String get notificationPrReviewDismissed => 'Onay iptal edildi';

  @override
  String notificationPrReviewDismissedBody(String prTitle) {
    return '$prTitle yeniden incelenmeli.';
  }

  @override
  String get notificationPrChecksFailed => 'Kontroller başarısız';

  @override
  String notificationPrChecksFailedBody(String checkName, String prTitle) {
    return '$checkName, $prTitle üzerinde başarısız oldu';
  }

  @override
  String notificationPrChecksFailedBodyUnnamed(String prTitle) {
    return '$prTitle üzerinde kontroller başarısız oluyor';
  }

  @override
  String get notificationPrChecksRecovered => 'Kontroller geçiyor';

  @override
  String notificationPrChecksRecoveredBody(String prTitle) {
    return '$prTitle yeniden yeşil.';
  }

  @override
  String notificationPrMentionedInCommentBody(String login, String location) {
    return '$login senden $location içinde bahsetti';
  }

  @override
  String get notificationPrThreadReplied => 'Yeni yanıt';

  @override
  String notificationPrThreadRepliedBody(String login, String location) {
    return '$login $location içinde yanıt verdi';
  }

  @override
  String get notificationPrThreadResolved => 'Konuşma çözüldü';

  @override
  String notificationPrThreadResolvedBody(String location) {
    return '$location içindeki konuşman çözüldü.';
  }

  @override
  String get notificationGroupAgents => 'Ajanlar';

  @override
  String get notificationGroupPullRequests => 'Pull request\'ler';

  @override
  String get notificationGroupMessages => 'Mesajlar';

  @override
  String get notificationGroupTickets => 'Biletler';

  @override
  String get notificationGroupCalendar => 'Takvim';

  @override
  String get notificationGroupMachines => 'Makineler';

  @override
  String get notificationsMutedRepos => 'Sessize alınan depolar';

  @override
  String notificationsMutedReposCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count depo sessize alındı',
      one: '1 depo sessize alındı',
      zero: 'Sessize alınan depo yok',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMuteRepo => 'Bu depoyu sessize al';

  @override
  String get onboardingLinuxDescription =>
      'Control Center, ajan yürütmesini yalıtmak için Linux konteynerleri kullanabilir.';

  @override
  String get onboardingMacosDescription =>
      'Control Center, ajan yürütmesini yalıtmak için macOS\'ta yerel sandbox kullanır.';

  @override
  String get onboardingUnsupportedDescription =>
      'Sandbox bu platformda kullanılamıyor. Ajan yürütmesi yalıtım olmadan gerçekleşecek.';

  @override
  String get openArticlesInApp => 'Makaleleri uygulamada aç';

  @override
  String get openInBrowser => 'Tarayıcıda aç';

  @override
  String get openedInYourBrowser => 'Tarayıcınızda açıldı.';

  @override
  String get openLabel => 'Aç';

  @override
  String get openOnGithub => 'GitHub\'da aç';

  @override
  String get openStatus => 'Açık';

  @override
  String get optionalPersonaDescription => 'İsteğe bağlı persona açıklaması';

  @override
  String get otherLabel => 'Diğer';

  @override
  String get ownerOrganization => 'Sahip / Kuruluş';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get passed => 'Geçti';

  @override
  String get pasteValueHere => 'Değeri buraya yapıştır';

  @override
  String get persona => 'Persona';

  @override
  String get policies => 'Politikalar';

  @override
  String get policiesHint =>
      'Ajanlar olguları yükselttiğinde politikalar burada görünür.';

  @override
  String get policy => 'Politika';

  @override
  String get popular => 'Popüler';

  @override
  String get port => 'Port';

  @override
  String get postingEllipsis => 'Gönderiliyor…';

  @override
  String get prCommits => 'Commit\'ler';

  @override
  String get prMergedBody => 'Bir pull request birleştirildi';

  @override
  String get prMoreActions => 'Diğer işlemler';

  @override
  String get prTitle => 'PR başlığı';

  @override
  String get reviewCommentHint =>
      'Onayla’ya tıklamanız yeterli; hevesiniz varsa bir yorum veya tepki de ekleyin…';

  @override
  String get nothingToPreview => 'Önizlenecek bir şey yok';

  @override
  String get previousMatch => 'Önceki eşleşme (⇧↵)';

  @override
  String get priorityReviewsDescription =>
      'Öncelikli incelemeler ve depo özeti.';

  @override
  String get prsCreated => 'Oluşturulan PR\'ler';

  @override
  String get prsMerged => 'Birleştirilen PR\'ler';

  @override
  String get publishToGithub => 'GitHub\'a yayınla';

  @override
  String get published => 'Yayınlandı';

  @override
  String get pullRequestApproved => 'Pull request onaylandı';

  @override
  String get pullRequests => 'Pull request\'ler';

  @override
  String get questionLabel => 'SORU';

  @override
  String get queued => 'Kuyrukta';

  @override
  String get react => 'React';

  @override
  String get readPrsIssuesMetadata =>
      'Ajanın PR\'ları, issue\'ları ve depo meta verilerini okumasına izin verir.';

  @override
  String get readerPreferences => 'Okuyucu tercihleri';

  @override
  String get reasoningEffort => 'Akıl yürütme eforu';

  @override
  String get recommendLabel => 'ÖNER';

  @override
  String recordingFromDevice(String device) {
    return '$device cihazından kaydediliyor.';
  }

  @override
  String get redownload => 'Yeniden indir';

  @override
  String get redownloadEmbeddingModel => 'Gömme modeli yeniden indirilsin mi?';

  @override
  String get redownloadVoiceModel => 'Ses modeli yeniden indirilsin mi?';

  @override
  String get refinePlan => 'Planı iyileştir';

  @override
  String get refresh => 'Yenile';

  @override
  String get refreshAll => 'Tümünü yenile';

  @override
  String get refreshAllFeeds => 'Tüm akışları yenile';

  @override
  String get reject => 'Reddet';

  @override
  String get rejected => 'Reddedildi';

  @override
  String get reload => 'Yeniden yükle';

  @override
  String get remove => 'Kaldır';

  @override
  String get removeBookmark => 'Yer imini kaldır';

  @override
  String get removeEmbeddingModel => 'Gömme modeli kaldırılsın mı?';

  @override
  String get removeLogo => 'Logoyu kaldır';

  @override
  String get removeRepoFromWorkspace =>
      'Depo çalışma alanından kaldırılsın mı?';

  @override
  String get removeVoiceModel => 'Ses modeli kaldırılsın mı?';

  @override
  String get removed => 'Kaldırıldı';

  @override
  String get renamed => 'Yeniden adlandırıldı';

  @override
  String get reopen => 'Yeniden aç';

  @override
  String get resolve => 'Çöz';

  @override
  String get replyEllipsis => 'Yanıtla…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$name bu çalışma alanından kaldırılacak. Diskteki yerel dosyalara dokunulmaz.';
  }

  @override
  String repoAccessNoticeBody(String repos) {
    return 'Sunucunun GitHub kimlik bilgisi $repos öğesini göremiyor. Depo bir kuruluşa aitse GitHub App\'i oraya yükleyin veya erişimi olan bir token bağlayın.';
  }

  @override
  String repoAccessNoticeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count depoya erişilemiyor',
      one: 'Bir depoya erişilemiyor',
    );
    return '$_temp0';
  }

  @override
  String get repoAccessNoticeSuspendedTitle =>
      'GitHub App kurulumu askıya alındı';

  @override
  String repoAccessNoticeSuspendedBody(String repos) {
    return '$repos için son bilinen veriler gösteriliyor. GitHub’da kurulumu sürdürün veya erişimi olan bir token bağlayın.';
  }

  @override
  String get repoNoAccessBadge => 'Erişim yok';

  @override
  String get reportsTo => 'Bağlı olduğu kişi';

  @override
  String reposCount(int count) {
    return 'Depolar ($count)';
  }

  @override
  String get reposDescription =>
      'Bu çalışma alanının hedeflediği yerel kopyalar.';

  @override
  String get repositories => 'Depolar';

  @override
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count depo',
      one: '1 depo',
    );
    return '$_temp0 eklenemedi: $error';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count depo eklendi',
      one: 'Depo eklendi',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => 'Depo ayarları';

  @override
  String get repositoryName => 'Depo adı';

  @override
  String get requestChanges => 'Değişiklik iste';

  @override
  String get requested => 'İstendi';

  @override
  String get requestedChanges => 'İstenen değişiklikler';

  @override
  String requiredRoleLabel(String role) {
    return 'Gerekli rol: $role';
  }

  @override
  String get requiredRoleOptional => 'Gerekli rol (isteğe bağlı)';

  @override
  String get requirements => 'Gereksinimler';

  @override
  String get reset => 'Sıfırla';

  @override
  String get resolved => 'Çözüldü';

  @override
  String get enclosedTerminalTitle => 'Kapsüllenmiş terminal';

  @override
  String get enclosedTerminalStart => 'Shell\'i aç';

  @override
  String get enclosedTerminalStartHint =>
      'Bu shell, bu konuşmanın tek kullanımlık sanal makinesinde çalışır. Uygulama başladığında değil, siz açtığınızda başlar.';

  @override
  String get terminalStreamReconnecting =>
      'akış kesildi — yeniden bağlanılıyor…';

  @override
  String get terminalStreamError => 'akış hatası:';

  @override
  String get terminalShellExited => 'shell sonlandı';

  @override
  String get restartShell => 'Shell\'i yeniden başlat';

  @override
  String get retry => 'Yeniden dene';

  @override
  String get review => 'İncele';

  @override
  String get reviewedByMe => 'Benim incelediklerim';

  @override
  String get reviewers => 'İnceleyenler';

  @override
  String get roleLabel => 'Rol';

  @override
  String get ruleHint => 'Politika kuralı (markdown desteklenir)';

  @override
  String get ruleLabel => 'Kural';

  @override
  String get runCompleted => 'Çalıştırma tamamlandı';

  @override
  String get running => 'Çalışıyor';

  @override
  String get runningLabel => 'çalışıyor';

  @override
  String get runs => 'Çalıştırmalar';

  @override
  String get runsLabel => 'Çalıştırmalar';

  @override
  String get sandboxBackendNativeLabel => 'Yerel sandbox';

  @override
  String get sandboxBackendMicrovmLabel => 'Kapalı VM';

  @override
  String get sandboxBackendNoneLabel => 'İzolasyon yok';

  @override
  String get sandboxLinuxInstall =>
      'Linux/WSL2 üzerinde yerel sandbox bubblewrap kullanır. Kurulum:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'macOS\'ta yerel sandbox yerleşiktir — Apple Seatbelt (`sandbox-exec`) kullanır. Kurulum gerekmez.';

  @override
  String get sandboxPermissions => 'Sandbox izinleri';

  @override
  String get sandboxUnsupported =>
      'Yerel sandbox bu platformda henüz desteklenmiyor. \"İzolasyon yok\" seçeneğine düşülür.';

  @override
  String get sandboxingDisabledDescription =>
      'Ajanlar tam ortamla doğrudan ana makinede çalışır — önerilmez.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'Tüm ajan çağrıları $backend üzerinden yönlendirilir.';
  }

  @override
  String get save => 'Kaydet';

  @override
  String get saveChanges => 'Değişiklikleri kaydet';

  @override
  String get adapterArguments => 'Ek argümanlar';

  @override
  String get adapterArgumentsHint => 'Ek CLI bayrakları (ör. --yolo)';

  @override
  String get addVariable => 'Değişken ekle';

  @override
  String get environmentVariables => 'Ortam değişkenleri';

  @override
  String get environmentVariablesDescription =>
      'Bu bağdaştırıcıya iletilen özel ortam değişkenleri (ör. API anahtarları). Anahtar zincirinde saklanır.';

  @override
  String get variableKey => 'Anahtar';

  @override
  String get variableValue => 'Değer';

  @override
  String get savingEllipsis => 'Kaydediliyor…';

  @override
  String get scopeDiffToCommits =>
      'Diff\'i commit\'lere sınırla — aralık için Shift-tıkla';

  @override
  String get noPrsMatchSearch => 'Eşleşen pull request yok';

  @override
  String get searchFactsHint => 'Bilgi ara...';

  @override
  String get searchFonts => 'Yazı tipi ara…';

  @override
  String get searchGifs => 'GIF ara';

  @override
  String get searchGifsHint => 'GIF ara...';

  @override
  String get searchInDiffHint => 'Diff içinde ara…';

  @override
  String get searchOrTypeModel => 'Model adı ara veya yaz…';

  @override
  String get searchPlaceholder => 'Ara…';

  @override
  String get searchShortcuts => 'Kısayol ara…';

  @override
  String get shortcutUnavailableInBrowser => 'Tarayıcıda kullanılamaz';

  @override
  String get searching => 'Aranıyor…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saniye önce',
      one: '1 saniye önce',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'Bağdaştırıcı seç';

  @override
  String get selectAdapterFirst => 'Önce bir bağdaştırıcı seç';

  @override
  String get selectAgentToReportTo => 'Raporlanacak ajanı seç…';

  @override
  String get selectAnAgent => 'Bir ajan seç';

  @override
  String get selectConversation => 'Bir konuşma seç';

  @override
  String get selectLabel => 'Seç';

  @override
  String get selectRunner => 'Bir runner seç';

  @override
  String get semanticSearch => 'Anlamsal arama';

  @override
  String get send => 'Gönder';

  @override
  String get sendFirstMessage => 'İlk mesajı gönder';

  @override
  String get sendMessage => 'Mesaj gönder';

  @override
  String sentFindingsToAgent(int count) {
    return '$count bulgu ajana gönderildi.';
  }

  @override
  String setGithubLinkDescription(String name) {
    return '$name için GitHub sahibi ve depo adını ayarlayın. Markdown içeriğindeki #123 gibi PR ve issue referanslarını çözümlemek için kullanılır.';
  }

  @override
  String get setLabel => 'Ayarla';

  @override
  String get setToken => 'Token ayarla';

  @override
  String get settingsLabel => 'Ayarlar';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsLanguageDescription => 'Uygulama dilini seçin.';

  @override
  String get shortTask => 'Kısa görev';

  @override
  String get showNativeNotifications =>
      'Olaylar için sistem bildirimlerini göster.';

  @override
  String get showSuperseded => 'Geçersiz kılınanları göster';

  @override
  String get signedIn => 'Oturum açıldı.';

  @override
  String signedInAs(String username) {
    return '$username olarak oturum açıldı.';
  }

  @override
  String get skillNameRequired => 'Beceri adı gerekli.';

  @override
  String skillSaved(String name) {
    return '\"$name\" becerisi kaydedildi.';
  }

  @override
  String get skillsSourcesTab => 'Kaynaklar';

  @override
  String get skillSourcesDisclaimer =>
      'Beceriler eklediğiniz GitHub depolarından yüklenir. Depo meta verileri güvenilmezdir — asıl güvenlik sinyali antivirüs taramasıdır.';

  @override
  String get skillSourcesEmpty => 'Beceri deposu yok';

  @override
  String get skillSourcesEmptyHint =>
      'Becerilerini incelemek için bir GitHub deposu ekleyin.';

  @override
  String get skillSourceAdd => 'Depo ekle';

  @override
  String get skillSourceAddTitle => 'Beceri deposu ekle';

  @override
  String get skillSourceAddHint => 'https://github.com/owner/repo';

  @override
  String get skillSourceInvalidUrl =>
      'Bir GitHub depo URL\'si girin (https://github.com/owner/repo).';

  @override
  String skillSourceAdded(String repo) {
    return '$repo deposu eklendi.';
  }

  @override
  String skillSourceAlreadyAdded(String repo) {
    return '$repo deposu zaten ekli.';
  }

  @override
  String skillSourceRemoved(String repo) {
    return '$repo deposu kaldırıldı.';
  }

  @override
  String get skillSourceRemove => 'Kaldır';

  @override
  String skillSourceRemoveConfirmTitle(String repo) {
    return '$repo kaldırılsın mı?';
  }

  @override
  String get skillSourceRemoveConfirmBody =>
      'Yüklü beceriler yüklü kalır. Yalnızca depo kataloğu kaldırılır.';

  @override
  String get skillSourceNoSkills =>
      'Bu depoda beceri bulunamadı (beceri, SKILL.md içeren bir dizindir).';

  @override
  String get skillSourceRefresh => 'Yenile';

  @override
  String get skillSourceInstalledBadge => 'Yüklü';

  @override
  String get skillSourceUpdateBadge => 'Güncelleme var';

  @override
  String get skillSourceSlugTaken => 'Ad kullanımda';

  @override
  String skillSourceFilesCount(num count) {
    return '$count dosya';
  }

  @override
  String get skillSourceReadme => 'README';

  @override
  String get skillSourceNoReadme => 'Bu becerinin README\'si yok.';

  @override
  String get skillSourceNoMatches => 'Filtrenize uyan beceri yok.';

  @override
  String get skillUpdateAction => 'Güncelle';

  @override
  String get skillUninstallAction => 'Yüklemeyi kaldır';

  @override
  String skillUninstallConfirmTitle(String slug) {
    return '\"$slug\" yüklemesi kaldırılsın mı?';
  }

  @override
  String skillUninstalled(String slug) {
    return '\"$slug\" becerisinin yüklemesi kaldırıldı.';
  }

  @override
  String get skillFindingLine => 'satır';

  @override
  String get skillInstallAnywayOverride => 'Riski anlıyorum — yine de yükle';

  @override
  String skillInstalled(String slug) {
    return '\"$slug\" becerisi yüklendi.';
  }

  @override
  String get skillPreviewCapabilities => 'Yetenekler';

  @override
  String get skillPreviewFindings => 'Bulgular';

  @override
  String get skillPreviewGuardedActions => 'Korumalı eylemler';

  @override
  String get skillPreviewLlmReviewed => 'LLM incelemesi';

  @override
  String get skillPreviewNoCapabilities => 'Beyan edilen yetenek yok.';

  @override
  String get skillPreviewNoFindings => 'Bulgu yok.';

  @override
  String get skillPreviewScanning => 'Beceri taranıyor…';

  @override
  String get skillPreviewVerdictLabel => 'Tarama kararı';

  @override
  String get skillPreviewVerdictPass => 'Geçti';

  @override
  String get skillPreviewVerdictQuarantine => 'Karantinada';

  @override
  String get skillPreviewVerdictWarn => 'Uyarı';

  @override
  String get skillQuarantineWarning =>
      'Bu beceri tarayıcı tarafından karantinaya alındı. Yüklemek makinenizde kod çalıştırır. Yalnızca kaynağa güveniyorsanız ve bulguları incelediyseniz devam edin.';

  @override
  String skillDetachedFromAgents(String agents) {
    return 'Karantinada ve ajanlardan ayrıldı: $agents';
  }

  @override
  String get skillNotScanned => 'Taranmadı';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => 'Manuel';

  @override
  String get skillOriginRegistry => 'Kayıt';

  @override
  String get skillOriginRuntimeLocal => 'Yerel runtime';

  @override
  String get skillRulesStale => 'Tarama güncel değil';

  @override
  String get skillSaveAnywayOverride => 'Riski anlıyorum — yine de kaydet';

  @override
  String get skillSaveBlockedBody =>
      'İçerik, herhangi bir şey yazılmadan önce engellendi.';

  @override
  String get skillSaveBlockedTitle =>
      'Kayıt tarama kapısı tarafından engellendi';

  @override
  String get skillScanAction => 'Tara';

  @override
  String get skillScanAll => 'Tümünü tara';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass geçti · $warn uyarı · $quarantine karantinada';
  }

  @override
  String get skillStateDrifted => 'Kurulumdan sonra değiştirildi';

  @override
  String get skillStateUnmanaged => 'Yönetilmiyor';

  @override
  String get skillSeverityBlocked => 'Engellendi';

  @override
  String get skillSeverityWarn => 'Uyarı';

  @override
  String get skillsInstalledTab => 'Yüklü';

  @override
  String get skills => 'Beceriler';

  @override
  String get skipAcceptRisk => 'Atla — riski kabul ediyorum';

  @override
  String get skipForNow => 'Şimdilik atla';

  @override
  String get skipSandboxing => 'Sandboxing\'i atla';

  @override
  String get skipSandboxingDialogContent =>
      'Sandboxing\'i atlamak istediğinizden emin misiniz? Bu, ajanların kodu sisteminizde yalıtım olmadan çalıştırmasına izin verir.';

  @override
  String get somethingWentWrong => 'Bir şeyler ters gitti';

  @override
  String sourceCount(int count) {
    return '$count kaynak';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count kaynak';
  }

  @override
  String get sourceFacts => 'Kaynak bilgileri:';

  @override
  String get splitDiff => 'Bölünmüş (yan yana) diff';

  @override
  String get startLabel => 'Başlat';

  @override
  String get startOnAppLaunch => 'Uygulama açılışında başlat';

  @override
  String get statusLabel => 'Durum';

  @override
  String get onboardingStepConnect => 'Bağlan';

  @override
  String get onboardingStepWorkspace => 'Çalışma alanı';

  @override
  String get onboardingStepSandbox => 'Sandbox';

  @override
  String get onboardingStepAdapter => 'Adaptör';

  @override
  String get onboardingStepVoice => 'Ses';

  @override
  String get stop => 'Durdur';

  @override
  String get stopped => 'Durduruldu';

  @override
  String get strictIdentityCheck => 'Katı kimlik denetimi';

  @override
  String get success => 'Başarılı';

  @override
  String get successLabel => 'Başarılı';

  @override
  String get suggestAChange => 'Değişiklik öner';

  @override
  String get suggestLabel => 'Öner';

  @override
  String get superseded => 'Geçersiz kılındı';

  @override
  String get synced => 'Eşitlendi';

  @override
  String get systemDefault => 'Sistem varsayılanı';

  @override
  String get systemFonts => 'Sistem yazı tipleri';

  @override
  String get systemPrompt => 'Sistem promptu';

  @override
  String get systemPromptLabel => 'Sistem promptu';

  @override
  String get talkToControlCenter => 'Control Center ile konuş.';

  @override
  String get taskMentionSection => 'Görev';

  @override
  String get testLabel => 'Test';

  @override
  String get theme => 'Tema';

  @override
  String get themeDark => 'Koyu';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get thisCannotBeUndone => 'Bu işlem geri alınamaz.';

  @override
  String get ticketLabel => 'Bilet';

  @override
  String get titleLabel => 'Başlık';

  @override
  String get todayLabel => 'Bugün';

  @override
  String get toggleTheme => 'Temayı değiştir';

  @override
  String get tokenConfigured =>
      'Yapılandırıldı — istemcilerin bu token\'ı sunması gerekir.';

  @override
  String get topic => 'Konu';

  @override
  String get topicHint => 'örn. Tech Stack, Design System';

  @override
  String get totalRuns => 'Toplam çalıştırma';

  @override
  String trackingParamsCount(int count) {
    return '$count izleme parametresi';
  }

  @override
  String get typeCommandOrSearch => 'Komut yazın veya arayın…';

  @override
  String get typography => 'Tipografi';

  @override
  String get unavailable => 'Kullanılamıyor';

  @override
  String get unifiedDiff => 'Birleşik diff';

  @override
  String get unknownAuthor => 'Bilinmiyor';

  @override
  String get unnamedAgent => 'Adsız ajan';

  @override
  String get updateKey => 'Anahtarı güncelle';

  @override
  String get updateLabel => 'Güncelle';

  @override
  String get updateToken => 'Token\'ı güncelle';

  @override
  String updatedDaysAgo(int count) {
    return '${count}g önce güncellendi';
  }

  @override
  String updatedHoursAgo(int count) {
    return '${count}sa önce güncellendi';
  }

  @override
  String get updatedJustNow => 'Az önce güncellendi';

  @override
  String updatedMinutesAgo(int count) {
    return '${count}dk önce güncellendi';
  }

  @override
  String get useSandbox => 'Sandbox kullan';

  @override
  String get useWorkspaceDefault => 'Çalışma alanı varsayılanını kullan';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      'Varsayılan uygulama User-Agent\'ını kullanmak için boş bırakın. Bazı siteler tarayıcı olmayan User-Agent\'ları engeller.';

  @override
  String get usingSystemDefaultMicrophone =>
      'Sistem varsayılan mikrofonu kullanılıyor.';

  @override
  String get viewLabel => 'Görünüm';

  @override
  String get viewLogs => 'Günlükleri görüntüle';

  @override
  String voiceInstallFailed(String error) {
    return 'Kurulum başarısız: $error';
  }

  @override
  String get voiceModelNotInstalled =>
      'Kurulu değil. Bir kez ~200 MB indirilir; tamamen cihazda çalışır.';

  @override
  String get voiceModelNotInstalledLabel => 'Ses modeli kurulu değil.';

  @override
  String get voiceRedownloadBody =>
      'Mevcut model dosyaları silinecek ve ~200 MB arşiv yeniden indirilecek. İndirme tamamlanana kadar ses transkripsiyonu kullanılamaz.';

  @override
  String get voiceRemoveBody =>
      'Yeniden kurana kadar ses transkripsiyonu kapatılır. İstediğiniz zaman yeniden kurabilirsiniz.';

  @override
  String get voiceTranscription => 'Ses transkripsiyonu';

  @override
  String get weakIsolationDescription =>
      'Zayıf yalıtım — yalnızca namespace sınırı, çekirdek sınırı yok.';

  @override
  String get whenOffNoDefaultRoute =>
      'Kapalıyken sandbox varsayılan rota olmadan açılır.';

  @override
  String get whenOffServerStaysStopped =>
      'Kapalıyken sunucu siz başlatana kadar durur.';

  @override
  String get speechModel => 'Konuşma modeli';

  @override
  String get speechModelHint =>
      'Toplantı transkripsiyonu ve yazı alanı mikrofonu için kullanılır.';

  @override
  String get voiceModelInstalled =>
      'Kurulu. Toplantı transkripsiyonunu ve yazı alanı mikrofon düğmesini çalıştırır.';

  @override
  String get meetingMicSilentWarning =>
      'Mikrofonunuz sessizde olabilir — diğerleri konuşuyor ama mikrofona ses gelmiyor.';

  @override
  String get meetingSummaryPrivacyNotice =>
      'Kayıt ve transkripsiyon bu makinede kalır. Özeti bir ajan yazar; bulut modeli kullanırsa transkriptiniz ve notlarınız o sağlayıcıya gönderilir.';

  @override
  String get meetingTemplates => 'Toplantı notu şablonları';

  @override
  String get meetingTemplatesHint =>
      'Belirli bir toplantı türü için yapay zeka özetini şekillendirin. Etkin şablon, yeni ve yeniden çalıştırılan özetlere uygulanır.';

  @override
  String get meetingTemplateActive => 'Etkin şablon';

  @override
  String get meetingTemplateAdd => 'Şablon ekle';

  @override
  String get meetingTemplateNewTitle => 'Yeni şablon';

  @override
  String get meetingTemplateEditTitle => 'Şablonu düzenle';

  @override
  String get meetingTemplateNameLabel => 'Ad';

  @override
  String get meetingTemplateNameHint => 'ör. Sprint review';

  @override
  String get meetingTemplateInstructionsLabel => 'Talimatlar';

  @override
  String get meetingTemplateInstructionsHint =>
      'Yapay zeka bu notları nasıl yapılandırmalı ve neyi öne çıkarmalı?';

  @override
  String get workingMemory => 'Çalışma belleği';

  @override
  String get workspaceName => 'Çalışma alanı adı';

  @override
  String get workspaceScopedSkills =>
      'Ajanlara eklenen, çalışma alanı kapsamlı skill dosyaları.';

  @override
  String get workspaces => 'Çalışma alanları';

  @override
  String get writePrivateNotes => 'Özel notlar, gözlemler, planlar yazın...';

  @override
  String get writeSkillContent => 'Skill içeriğini buraya yazın (Markdown)…';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yıl önce',
      one: '1 yıl önce',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'Dün';

  @override
  String get focusModeStart => 'Odak oturumunu başlat';

  @override
  String get focusModeConfigTitle => 'Odak oturumunu başlat';

  @override
  String get focusModeGoalLabel => 'Hedef';

  @override
  String get focusModeGoalHint => 'Ne üzerinde çalışıyorsunuz?';

  @override
  String get focusModeDurationLabel => 'Süre';

  @override
  String get focusModeBlockNotifications => 'Bildirimleri engelle';

  @override
  String get focusModeStartButton => 'Başlat';

  @override
  String get focusModeFloat => 'Çubuğa küçült';

  @override
  String get focusModeActiveTooltip => 'Odak modu açık — bitirmek için dokunun';

  @override
  String get dismiss => 'Kapat';

  @override
  String get acceptAndResolve => 'Kabul et ve çöz';

  @override
  String reviewFatigueWarning(int minutes) {
    return '${minutes}dk\'dır inceleme yapıyorsunuz — araştırmalar, 60 dakikayı geçince inceleme kalitesinin düşebileceğini gösteriyor. Bir mola düşünün.';
  }

  @override
  String get notificationSound => 'Bildirim sesi';

  @override
  String get notificationSoundDescription =>
      'Bildirim gösterildiğinde çalınan ses.';

  @override
  String get notificationSoundNone => 'Yok';

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
  String get notificationSoundMigrosSoft => 'Migros (yumuşak)';

  @override
  String get notificationSoundMigrosHard => 'Migros (sert)';

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
  String get notificationVolume => 'Ses düzeyi';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'Bu çalışma alanında @$login tarafından PR yok';
  }

  @override
  String get usersLabel => 'Kullanıcılar';

  @override
  String get mergePullRequest => 'Pull request\'i birleştir';

  @override
  String get forceMergePullRequest => 'Pull request\'i zorla birleştir';

  @override
  String get closePullRequest => 'Pull request\'i kapat';

  @override
  String get closePullRequestConfirm =>
      'Bu pull request\'i kapatmak istediğinizden emin misiniz?';

  @override
  String get stackedPullRequests => 'Yığınlanmış pull request\'ler';

  @override
  String partOfStack(int position, int total) {
    return 'Bir yığının parçası ($position / $total)';
  }

  @override
  String get createStack => 'Yığın oluştur';

  @override
  String get createStackDialogTitle => 'Pull request yığını oluştur';

  @override
  String createStackDialogBody(int count) {
    return 'Bu $count pull request alttan üste yığınlanacak:';
  }

  @override
  String get createStackInvalidSelection =>
      'Yığın oluşturmak için aynı depodan en az iki pull request seçin';

  @override
  String get createStackNotAChain =>
      'Seçilen pull request\'ler bir zincir oluşturmuyor: her pull request\'in temel dalı bir öncekinin head dalı olmalı';

  @override
  String get createStackAlreadyStacked =>
      'Seçilen pull request\'lerden biri veya daha fazlası zaten bir yığında';

  @override
  String get stackCreated => 'Yığın oluşturuldu';

  @override
  String get stackCreationFailed => 'Yığın oluşturulamadı';

  @override
  String get squashAndMerge => 'Sıkıştır ve birleştir';

  @override
  String get createMergeCommit => 'Birleştirme commit\'i oluştur';

  @override
  String get rebaseAndMerge => 'Yeniden temelle ve birleştir';

  @override
  String get commitTitle => 'Commit başlığı';

  @override
  String get commitDescription => 'Commit açıklaması';

  @override
  String get pullRequestMerged => 'Pull request birleştirildi';

  @override
  String get pullRequestClosed => 'Pull request kapatıldı';

  @override
  String failedToMergePr(String error) {
    return 'Birleştirilemedi: $error';
  }

  @override
  String failedToClosePr(String error) {
    return 'Kapatılamadı: $error';
  }

  @override
  String get markReadyForReview => 'İncelemeye hazır';

  @override
  String get markReadyForReviewConfirm =>
      'Bu pull request taslaktan çıkacak. İnceleyenler bilgilendirilir, zorunlu kontroller birleştirmeyi kısıtlamaya başlar ve hazır pull request\'leri izleyen otomasyonlar çalışır.';

  @override
  String get convertToDraft => 'Taslağa dönüştür';

  @override
  String get convertToDraftConfirm =>
      'Bu pull request yeniden taslak olacak. Bekleyen inceleme istekleri iptal edilir ve tekrar hazır olarak işaretleyene kadar birleştirilemez.';

  @override
  String get pullRequestMarkedReady =>
      'Pull request incelemeye hazır olarak işaretlendi';

  @override
  String get pullRequestConvertedToDraft => 'Pull request taslağa dönüştürüldü';

  @override
  String failedToMarkPrReady(String error) {
    return 'İncelemeye hazır olarak işaretlenemedi: $error';
  }

  @override
  String failedToConvertPrToDraft(String error) {
    return 'Taslağa dönüştürülemedi: $error';
  }

  @override
  String get checksFailing => 'Kontroller başarısız';

  @override
  String get reviewsPending => 'Bazı incelemeler bekliyor';

  @override
  String get mergeConflictsWithBase =>
      'Bu dalın çözülmesi gereken çakışmaları var';

  @override
  String get branchOutOfDateWithBase => 'Bu dal temel dalın gerisinde';

  @override
  String get mergeBlockedByBranchProtection =>
      'Dal koruması bu birleştirmeyi engelliyor';

  @override
  String get confirm => 'Onayla';

  @override
  String get trustedSitesSectionTitle => 'Güvenilir siteler';

  @override
  String get trustedSitesEmpty =>
      'Güvenilir site yok. Engellemeyi kapatmak için bir etki alanı ekleyin.';

  @override
  String get addTrustedSite => 'Güvenilir site ekle';

  @override
  String get removeTrustedSite => 'Kaldır';

  @override
  String get disableBlockingForThisSite => 'Bu sitede engellemeyi kapat';

  @override
  String get enableBlockingForThisSite => 'Bu sitede engellemeyi aç';

  @override
  String get enterDomainHint => 'ör. example.com';

  @override
  String get invalidDomain => 'Geçerli bir alan adı girin (ör. example.com)';

  @override
  String get pageLoadTimedOut =>
      'Sayfa yükleme zaman aşımına uğradı. Yeniden yükleyin veya tarayıcıda açın.';

  @override
  String get pipelinesScreenTitle => 'Pipelines';

  @override
  String get pipelinesScreenSubtitle =>
      'Bildirimsel çok adımlı ajan iş akışları';

  @override
  String get pipelinesRunPipeline => 'Pipeline çalıştır';

  @override
  String get pipelineRunLauncherTitle => 'Pipeline çalıştır';

  @override
  String get pipelineRunSubtitle =>
      'Bir pipeline seçin ve çalıştırmak için girdilerini doldurun.';

  @override
  String get pipelineRunNoInputsBadge => 'Girdi yok';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count girdi',
      one: '1 girdi',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'Bu pipeline girdi almaz.';

  @override
  String get pipelineRunSubmit => 'Pipeline çalıştır';

  @override
  String get pipelineRunCouldNotStart => 'Çalıştırma başlatılamadı.';

  @override
  String pipelineRunStarted(String name) {
    return '$name başlatıldı';
  }

  @override
  String get pipelineRunEmptyTitle => 'Çalıştırılmaya hazır pipeline yok';

  @override
  String get pipelineRunEmptyHint =>
      'Buradan başlatmak için bir pipeline’ı etkinleştirin ve düzenleyicisinde manuel çalıştırmayı açın.';

  @override
  String get pipelineRunManageTemplates => 'Pipeline’ları yönet';

  @override
  String get pipelineRunSettingsTitle => 'Manuel çalıştırma';

  @override
  String get pipelineRunSettingsAllow => 'Manuel çalıştırmaya izin ver';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'Bu pipeline’ı çalıştırma sayfasında gösterin; elle başlatılabilsin.';

  @override
  String get pipelineRunSettingsConcurrencyTitle => 'Eşzamanlılık';

  @override
  String get pipelineRunSettingsMaxParallel => 'Maks. paralel çalıştırma';

  @override
  String get pipelineRunSettingsMaxParallelHelp =>
      'Sınırsız için boş bırakın. Fazla çalıştırmalar kuyrukta bekler ve yer açıldıkça başlar.';

  @override
  String get pipelineRunSettingsMaxParallelHint => 'Sınırsız';

  @override
  String get pipelineRunSettingsMaxParallelInvalid =>
      '1 veya daha büyük bir tam sayı girin ya da sınırsız için boş bırakın.';

  @override
  String get pipelineRunSettingsInputsTitle => 'Girdiler';

  @override
  String get pipelineRunSettingsAddInput => 'Girdi ekle';

  @override
  String get pipelineRunSettingsNoInputs => 'Henüz girdi yok.';

  @override
  String get pipelineInputEditTitle => 'Girdi alanı';

  @override
  String get pipelineInputKeyLabel => 'Anahtar';

  @override
  String get pipelineInputKeyHelp =>
      'Değerin saklandığı durum anahtarı (ör. repo_full_name).';

  @override
  String get pipelineInputLabelLabel => 'Etiket';

  @override
  String get pipelineInputTypeLabel => 'Tür';

  @override
  String get pipelineInputOptionsLabel => 'Seçenekler (virgülle ayrılmış)';

  @override
  String get pipelineInputDefaultLabel => 'Varsayılan değer';

  @override
  String get pipelineInputPlaceholderLabel => 'Yer tutucu';

  @override
  String get pipelineInputHelpLabel => 'Yardım metni';

  @override
  String get pipelineInputRequiredLabel => 'Zorunlu';

  @override
  String get pipelineInputTypeText => 'Metin';

  @override
  String get pipelineInputTypeMultiline => 'Çok satırlı metin';

  @override
  String get pipelineInputTypeNumber => 'Sayı';

  @override
  String get pipelineInputTypeBoolean => 'Geçiş';

  @override
  String get pipelineInputTypeSelect => 'Seçim';

  @override
  String get pipelinesEmpty => 'Henüz pipeline çalıştırması yok';

  @override
  String get pipelinesEmptyHint =>
      'Bir tane başlatmak için ‘Pipeline çalıştır’a tıklayın.';

  @override
  String get pipelinesNoSteps => 'Henüz kaydedilmiş adım yok';

  @override
  String get pipelinesNoActiveWorkspace =>
      'Pipeline’larını görmek için bir çalışma alanı seçin';

  @override
  String pipelinesLoadError(String error) {
    return 'Pipelines yüklenemedi: $error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'Pipeline başlatılamadı: $error';
  }

  @override
  String get pipelineStatusPending => 'Beklemede';

  @override
  String get pipelineStatusQueued => 'Kuyrukta';

  @override
  String get pipelineStatusRunning => 'Çalışıyor';

  @override
  String get pipelineStatusSuspended => 'Askıda';

  @override
  String get pipelineStatusCompleted => 'Tamamlandı';

  @override
  String get pipelineStatusFailed => 'Başarısız';

  @override
  String get pipelineStatusCancelled => 'İptal edildi';

  @override
  String get pipelineStatusSkipped => 'Atlandı';

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed/$total adım';
  }

  @override
  String get pipelineWaterfallTimeline => 'Zaman çizelgesi';

  @override
  String pipelineWaterfallActive(String duration) {
    return 'Aktif $duration';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return 'boşta $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip =>
      'Etkin süreden hariç tutulan zaman: çalıştırma durduruldu veya adımlar arasında bekliyordu.';

  @override
  String get pipelineStepStarted => 'Başladı';

  @override
  String get pipelineStepFinished => 'Bitti';

  @override
  String get pipelineStepDurationLabel => 'Süre';

  @override
  String get pipelineStepBranch => 'Dal';

  @override
  String get pipelineStepViewConversation => 'Konuşmayı görüntüle';

  @override
  String get pipelineStepError => 'Hata';

  @override
  String get pipelineStepInput => 'Girdi';

  @override
  String get pipelineStepOutput => 'Çıktı';

  @override
  String get pipelineStepNotExecuted => 'Henüz çalıştırılmadı';

  @override
  String pipelineRunFailedAtStep(String step) {
    return '$step adımında başarısız';
  }

  @override
  String get pipelineRunTriggerManual => 'Manuel';

  @override
  String get pipelineStepSkippedReason => 'Atlandı';

  @override
  String get pipelineStepPriorAttempts => 'Önceki denemeler';

  @override
  String get pipelineStepAttemptLabel => 'Deneme';

  @override
  String pipelineStepAttemptN(int number) {
    return 'Deneme $number';
  }

  @override
  String get pipelineStepAttemptInterrupted => 'Kesintiye uğradı';

  @override
  String get pipelineRunColumnPipeline => 'Pipeline';

  @override
  String get pipelineRunColumnDuration => 'Süre';

  @override
  String get pipelineRunQueueNext => 'Sıradaki';

  @override
  String pipelineRunQueuePosition(int position) {
    return 'Kuyrukta $position';
  }

  @override
  String get pipelineRunColumnStarted => 'Başlangıç';

  @override
  String get pipelineRunHistory => 'Çalıştırma geçmişi';

  @override
  String get pipelineRunHistoryEmpty => 'Henüz başka çalıştırma yok';

  @override
  String pipelineRunRerunAgo(String time) {
    return 'Yeniden çalıştırma $time';
  }

  @override
  String pipelineRunAttempt(int number) {
    return 'Deneme $number';
  }

  @override
  String pipelineRunFirstStarted(String time) {
    return 'ilk başlatma $time';
  }

  @override
  String get pipelineRunFilterAll => 'Tümü';

  @override
  String get pipelineRunFilterEmpty => 'Bu filtreyle eşleşen çalıştırma yok';

  @override
  String get relativeJustNow => 'az önce';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dk önce',
      one: '1 dk önce',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saat önce',
      one: '1 saat önce',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün önce',
      one: '1 gün önce',
    );
    return '$_temp0';
  }

  @override
  String get teamsTitle => 'Ekipler';

  @override
  String get teamsAddTeam => 'Ekip ekle';

  @override
  String get teamsLoadError => 'Ekipler yüklenemedi';

  @override
  String get teamsEmptyTitle => 'Henüz ekip yok';

  @override
  String get teamsEmptyDescription =>
      'Ajanları ekiplerde gruplayın; ekibe atanan iş, yetki devreden bir lider üzerinden yönlendirilir.';

  @override
  String get teamCreateTitle => 'Yeni ekip';

  @override
  String get teamEditTitle => 'Ekibi düzenle';

  @override
  String get teamNameLabel => 'Ekip adı';

  @override
  String get teamNameHint => 'ör. Frontend';

  @override
  String get teamDescriptionLabel => 'Açıklama';

  @override
  String get teamDescriptionHint => 'Bu ekibin sorumluluk alanı';

  @override
  String get teamLeaderLabel => 'Lider';

  @override
  String get teamLeaderHelp =>
      'Ekibe atanan işi alan ve en uygun üyeye devreden koordinatör.';

  @override
  String get teamNoLeader => 'Lider yok';

  @override
  String get teamInstructionsLabel => 'Çalışma yönergeleri';

  @override
  String get teamInstructionsHelp =>
      'Liderin brifingine eklenir — ekip alışkanlıkları, yükseltme kuralları, üslup.';

  @override
  String get teamInstructionsHint => 'İsteğe bağlı';

  @override
  String get teamSaved => 'Ekip kaydedildi';

  @override
  String get teamMembersError => 'Üyeler yüklenemedi';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count üye',
      one: '1 üye',
      zero: 'Üye yok',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => 'Üye ekle';

  @override
  String get teamAddMemberTitle => 'Üye ekle';

  @override
  String teamAddMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count',
      one: 'Add 1',
      zero: 'Add',
    );
    return '$_temp0';
  }

  @override
  String get teamNoAgentsToAdd => 'Tüm ajanlar zaten bu ekipte.';

  @override
  String get teamRemoveMember => 'Ekipten çıkar';

  @override
  String get teamLeaderBadge => 'Lider';

  @override
  String get teamUnknownAgent => 'Bilinmeyen ajan';

  @override
  String get teamMembersEmpty => 'Henüz üye yok';

  @override
  String get teamMembersEmptyDescription =>
      'Liderin iş devredebileceği ajanlar ekleyin.';

  @override
  String get teamSelectPrompt => 'Bir takım seçin';

  @override
  String get teamSelectPromptDescription =>
      'Listeden bir takım seçin veya yeni bir tane oluşturun.';

  @override
  String get teamDeleteTitle => 'Takım silinsin mi?';

  @override
  String teamDeleteBody(String name) {
    return '$name silinecek. Ajanları etkilenmez.';
  }

  @override
  String get teamHasLeaderTooltip => 'Lideri var';

  @override
  String get pipelineTemplatesNav => 'Pipeline şablonları';

  @override
  String get pipelineTemplatesTitle => 'Pipeline şablonları';

  @override
  String get pipelineTemplatesSubtitle =>
      'Ajanlarınızı orkestre eden pipeline\'lar için sürükle-bırak düzenleyici.';

  @override
  String get pipelineTemplatesNew => 'Yeni şablon';

  @override
  String get pipelineTemplatesEmpty =>
      'Henüz pipeline şablonu yok. Başlamak için bir tane oluşturun.';

  @override
  String get pipelineTemplateBuiltInBadge => 'Yerleşik';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'Şablon silinsin mi?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return '$name pipeline şablonu silinsin mi? Bu işlem geri alınamaz.';
  }

  @override
  String get pipelineTemplateEditorSubtitle =>
      'Kenar çubuğundaki düğüm türlerini tuvale sürükleyin, ardından birbirine bağlayın.';

  @override
  String get unsavedChanges => 'Kaydedilmemiş değişiklikler';

  @override
  String get nodeLibraryTitle => 'Düğüm kitaplığı';

  @override
  String get nodeLibraryHint =>
      'Düğüm eklemek için herhangi bir öğeyi tuvale sürükleyin.';

  @override
  String get editorEmptyCanvas =>
      'Başlamak için kitaplıktan bir düğüm sürükleyin.';

  @override
  String get pipelineWhenThisHappens => 'Bu olduğunda';

  @override
  String get pipelineDoThis => 'Bunu yap';

  @override
  String get pipelineAddStep => 'Adım ekle';

  @override
  String get pipelineTidyUp => 'Yerleşimi düzenle';

  @override
  String get pipelineEditorHint =>
      'Adımları sürükleyerek yerleştirin · tutamacı sürükleyerek bağlayın';

  @override
  String get pipelineRemoveConnection => 'Bağlantıyı kaldır';

  @override
  String get pipelineDragToConnect => 'Bağlamak için sürükleyin';

  @override
  String get pipelineNewDefaultName => 'Yeni pipeline';

  @override
  String get nodeCategoryTriggers => 'Tetikleyiciler';

  @override
  String get triggerEventWebhook => 'Webhook';

  @override
  String get pipelineAddTrigger => 'Tetikleyici ekle';

  @override
  String get pipelineOnEvent => 'Olayda';

  @override
  String get nodeConfigTitle => 'Düğüm yapılandırması';

  @override
  String get nodeConfigKind => 'Tür';

  @override
  String get nodeConfigLabel => 'Etiket';

  @override
  String get nodeConfigAgent => 'Ajan';

  @override
  String get nodeConfigAgentHint => 'Bir ajan seçin…';

  @override
  String get nodeConfigInputKeys => 'Girdi anahtarları (virgülle ayrılmış)';

  @override
  String get nodeConfigInputKeysHelp =>
      'Bu düğümün tükettiği durum anahtarları. Prompt\'taki yer tutucu değişiminde kullanılır.';

  @override
  String get nodeConfigRepos => 'Klonlanacak depolar';

  @override
  String get nodeConfigReposHelp =>
      'Bu düğüm konuşmasını başlattığında klonlanan ve kod dizini oluşturulan depolar. Tüm depoları seçmek hepsini klonlar (varsayılan).';

  @override
  String get nodeConfigRepoBranchHint => 'Dal (varsayılan)';

  @override
  String get nodeConfigRepoBranchHelp =>
      'Her checkout\'un alındığı dal. Deponun kendi varsayılan dalı için boş bırakın — çalışma ağacı yine kendi dalını alır, ajanın commit ettiği hiçbir şey bu dala düşmez.';

  @override
  String nodeConfigReposDynamic(String entries) {
    return 'Korunan dinamik girdiler: $entries';
  }

  @override
  String get nodeConfigCreateConversation => 'İçinde bir konuşma aç';

  @override
  String get nodeConfigCreateConversationHelp =>
      'Ardından birkaç ajan düğümü geliyorsa bunu kapalı bırakın — her biri kendi adlı akışını açar. Tek bir ajan düğümü geliyorsa açın ki oda yanında başlıksız bir konuşma göstermesin.';

  @override
  String get nodeConfigConversationTitle => 'Konuşma adı';

  @override
  String get nodeConfigConversationTitleHelp =>
      'Aşağıdaki ajan düğümüne aynı adı verin, ikisi de tek akışta çalışır. Varsayılan, düğümün etiketidir.';

  @override
  String get nodeConfigSpaceName => 'Alan adı';

  @override
  String get nodeConfigSpaceNameHelp =>
      'Bu düğümün açtığı odanın adı. Prompt ile aynı durum yer tutucularını destekler. Düğümün etiketini kullanmak için boş bırakın.';

  @override
  String get nodeConfigSpaceNameHint => 'pr_number incelemesi';

  @override
  String get nodeConfigStreamTitle => 'Konuşma adı';

  @override
  String get nodeConfigStreamTitleHelp =>
      'Bu düğümün ajanının odada çalıştığı adlı akış. Prompt ile aynı durum yer tutucularını destekler. Boş bırakırsanız tur, odanın kalıcı konuşmasına düşer; orada fan-out her ajanı iç içe işler.';

  @override
  String get nodeConfigConversationTitleHint => 'Mimari analiz';

  @override
  String get nodeConfigOutputKey => 'Çıktı anahtarı';

  @override
  String get nodeConfigPrompt => 'Prompt şablonu';

  @override
  String get nodeConfigPromptHelp =>
      'Çalışma anında durumdan değer çekmek için çift süslü parantezli yer tutucular kullanın.';

  @override
  String get nodeConfigScript => 'Bash betiği';

  @override
  String get nodeConfigScriptHelp =>
      'bash -c ile çalışır. GITHUB_TOKEN ayarlıdır. Yer tutucular çalıştırılmadan önce değiştirilir.';

  @override
  String get nodeConfigRouteKeys => 'Rota anahtarları';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return '$source kaynağından rota anahtarı';
  }

  @override
  String get conditionSectionTitle => 'Koşul';

  @override
  String get conditionMode => 'Mod';

  @override
  String get conditionModeFilesAny => 'Dosya(lar) var — herhangi biri';

  @override
  String get conditionModeFilesAll => 'Dosyalar var — tümü';

  @override
  String get conditionModeComparison => 'Karşılaştırma';

  @override
  String get conditionModeSwitch => 'Switch';

  @override
  String get conditionFilePaths => 'Dosya yolları';

  @override
  String get conditionFilePathsAnyHelp =>
      'Her satıra bir yol, taban dizine göre göreli. Herhangi biri varsa true döner.';

  @override
  String get conditionFilePathsAllHelp =>
      'Her satıra bir yol, taban dizine göre göreli. Yalnızca tümü varsa true döner.';

  @override
  String get conditionBaseKey => 'Taban dizin anahtarı';

  @override
  String get conditionBaseKeyHelp =>
      'Yolların çözümlendiği dizini tutan durum anahtarı (varsayılan repo_local_path).';

  @override
  String get conditionRecursive => 'Alt dizinlerde ara';

  @override
  String get conditionNegate => 'Tersine çevir: yoksa true yönlendir';

  @override
  String get conditionLeft => 'Sol değer';

  @override
  String get conditionOperator => 'Operatör';

  @override
  String get conditionRight => 'Sağ değer';

  @override
  String get conditionSwitchKey => 'Durum anahtarına göre seç';

  @override
  String get conditionCases => 'Durumlar (virgülle ayrılmış)';

  @override
  String get conditionCasesHelp =>
      'Değerle eşleşecek rota anahtarları, sırayla.';

  @override
  String get conditionDefaultCase => 'Varsayılan durum';

  @override
  String get triggerManualHelp =>
      'Çalıştırma sayfasında göster ve elle başlat.';

  @override
  String get triggerKindSchedule => 'Zamanlamayla';

  @override
  String get triggerScheduleExprLabel => 'Zamanlama (cron veya every:seconds)';

  @override
  String get triggerTimezoneLabel => 'Saat dilimi (isteğe bağlı)';

  @override
  String get triggerCatchUpLabel => 'Kaçırılan çalıştırmalarda';

  @override
  String get triggerCatchUpRunOnce => 'Bir kez çalıştır';

  @override
  String get triggerCatchUpSkip => 'Atla';

  @override
  String get syncHealthTitle => 'Senkron sağlığı';

  @override
  String get syncHealthNoConfigs => 'Henüz senkron bağlantısı yok';

  @override
  String get syncHealthNeverSynced => 'Hiç senkronlanmadı';

  @override
  String get syncOutcomeOk => 'Senkronlandı';

  @override
  String get syncOutcomeFailed => 'Başarısız';

  @override
  String get syncOutcomeSkipped => 'Atlandı';

  @override
  String syncHealthFailedStreak(int count) {
    return '$count ardışık hata';
  }

  @override
  String get triggerWebhookHelp =>
      'İmzalı bir webhook URL\'si oluşturulur. Dış sistemler bu pipeline\'ı başlatmak için buna POST gönderir.';

  @override
  String get triggerWebhookPathLabel => 'Webhook yolu';

  @override
  String get triggerMatchStatusLabel => 'Yalnızca durum şu olduğunda';

  @override
  String get triggerSummaryNone => 'Tetikleyici yok';

  @override
  String triggerEverySeconds(int seconds) {
    return 'Her ${seconds}s';
  }

  @override
  String get triggerEventManual => 'Elle çalıştırma';

  @override
  String get triggerEventSchedule => 'Zamanlama';

  @override
  String get triggerEventPrStatusChanged => 'PR durumu değişti';

  @override
  String get triggerEventExternalPr => 'Harici PR açıldı';

  @override
  String get triggerEventPrPublished => 'PR yayınlandı';

  @override
  String get triggerEventPrMerged => 'PR birleştirildi';

  @override
  String get triggerEventRepoAdded => 'Depo eklendi';

  @override
  String get triggerEventCodeGraphWatch => 'Dosya değişikliği';

  @override
  String pipelineRunCauseChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count değişen dosya',
      one: '1 değişen dosya',
    );
    return '$_temp0';
  }

  @override
  String pipelineRunCauseMorePaths(int count) {
    return '+$count daha';
  }

  @override
  String get pipelineRunCauseRescan => 'Diskte değişti';

  @override
  String get pipelineRunCauseInitial => 'Bu checkout\'un ilk indeksi';

  @override
  String get triggerEventMessageReceived => 'Mesaj alındı';

  @override
  String get triggerEventTicketCompleted => 'Bilet tamamlandı';

  @override
  String get triggerEventTicketFailed => 'Bilet başarısız';

  @override
  String get triggerEventTicketCancelled => 'Bilet iptal edildi';

  @override
  String get triggerEventBudgetCrossed => 'Bütçe eşiği aşıldı';

  @override
  String get nodeLibrarySearchHint => 'Düğüm ara';

  @override
  String get nodeLibraryNoMatches => 'Eşleşen düğüm yok';

  @override
  String get nodeCategoryFlow => 'Akış ve mantık';

  @override
  String get nodeCategoryPr => 'PR incelemesi';

  @override
  String get nodeCategoryAgents => 'Ajanlar';

  @override
  String get nodeCategoryMessaging => 'Mesajlaşma';

  @override
  String get nodeCategoryCode => 'Kod';

  @override
  String get triggerDisabledTag => 'kapalı';

  @override
  String get pipelineInputTypeRepo => 'Repository';

  @override
  String get pipelineRunNoRepos => 'Bu çalışma alanında henüz repository yok.';

  @override
  String get allowTicketingApi => 'Bilet API çağrılarına izin ver';

  @override
  String get ticketingApiKey => 'Bilet API anahtarı';

  @override
  String get ticketingApiKeySubtitle =>
      'Bilet sağlayıcısının API anahtarını sandbox\'a enjekte eder.';

  @override
  String get ticketingProvider => 'Bilet sağlayıcısı';

  @override
  String get connectGitHubAndTicketing =>
      'Control Center\'ın pull request\'lerinizi, issue\'larınızı ve incelemelerinizi okuyabilmesi için bir kod barındırıcısı bağlayın. İsteğe bağlı olarak bir bilet sağlayıcısı da bağlayabilirsiniz. Kimlik bilgileri bu makinede değil, sunucunuzda tutulur.';

  @override
  String get triggerEventTicketAssigned => 'Bilet atandı';

  @override
  String get triggerEventTicketCreated => 'Bilet oluşturuldu';

  @override
  String get triggerEventTicketStatusChanged => 'Bilet durumu değişti';

  @override
  String get triggerEventMeetingRecordingStopped => 'Toplantı kaydı durdu';

  @override
  String get triggerEventSkillUpdated => 'Beceri güncellendi';

  @override
  String get triggerEventSpaceDeleted => 'Space silindi';

  @override
  String get triggerExternalPrHelp =>
      'Kod barındırıcısında açılan bir pull request, Control Center\'dan değil.';

  @override
  String get triggerPrPublishedHelp =>
      'Control Center\'dan veya bir aracı tarafından açılan bir pull request.';

  @override
  String get triggerPrStatusChangedHelp =>
      'Birleştirildi, kapatıldı, açıldı, yeniden açıldı veya onaylandı. Denetçide duruma göre süzün.';

  @override
  String get triggerPrMergedHelp =>
      'Yalnızca pull request birleştirildiğinde; kapatıldığında veya yeniden açıldığında değil.';

  @override
  String get triggerRepoAddedHelp => 'Bu çalışma alanına bir depo bağlanır.';

  @override
  String get triggerCodeGraphWatchHelp =>
      'Bağlı bir depodaki dosya diskte değişir.';

  @override
  String get triggerMessageReceivedHelp => 'Bir alana yeni bir ileti gelir.';

  @override
  String get triggerTicketCreatedHelp =>
      'Bu çalışma alanında bir bilet oluşturulur.';

  @override
  String get triggerTicketStatusChangedHelp =>
      'Bir bilet durumlar arasında geçer.';

  @override
  String get triggerTicketCompletedHelp => 'Bir bilet başarıyla biter.';

  @override
  String get triggerTicketFailedHelp =>
      'Bir aracı çalışması başarısız oldu ve bilet başarısız olarak işaretlenir.';

  @override
  String get triggerTicketCancelledHelp =>
      'Bir bilet iptal edilir ve devam etmez.';

  @override
  String get triggerBudgetCrossedHelp =>
      'Bir çalışma alanı veya aracı harcama sınırı aşılır.';

  @override
  String get triggerTicketAssignedHelp =>
      'Bir bilet bir kişiye, aracıya veya ekibe atanır.';

  @override
  String get triggerMeetingRecordingStoppedHelp => 'Bir toplantı kaydı biter.';

  @override
  String get triggerSkillUpdatedHelp => 'Bir beceri kurulur veya güncellenir.';

  @override
  String get triggerSpaceDeletedHelp => 'Bir konuşma alanı silinir.';

  @override
  String get navTickets => 'Biletler';

  @override
  String get ticketsTitle => 'Biletler';

  @override
  String get newTicket => 'Yeni bilet';

  @override
  String get noTicketsYet => 'Henüz bilet yok';

  @override
  String get addCollaborator => 'İşbirlikçi ekle';

  @override
  String get noCollaborators => 'Henüz işbirlikçi yok';

  @override
  String get linkedPullRequests => 'Bağlı pull request\'ler';

  @override
  String get noLinkedPullRequests => 'Henüz bağlı pull request yok';

  @override
  String get stopAgent => 'Ajanı durdur';

  @override
  String get ticketProperties => 'Özellikler';

  @override
  String get ticketTabIssue => 'Issue';

  @override
  String get ticketSelectPrompt => 'Ayrıntılarını görmek için bir bilet seçin';

  @override
  String get unassigned => 'Atanmamış';

  @override
  String get ticketStatusBacklog => 'Backlog';

  @override
  String get ticketStatusOpen => 'Yapılacak';

  @override
  String get ticketStatusInProgress => 'Devam ediyor';

  @override
  String get ticketStatusInReview => 'İncelemede';

  @override
  String get ticketStatusDone => 'Tamamlandı';

  @override
  String get ticketStatusBlocked => 'Engellendi';

  @override
  String get ticketStatusFailed => 'Başarısız';

  @override
  String get ticketStatusCancelled => 'İptal edildi';

  @override
  String get notificationTicketAssigned => 'Bilet atandı';

  @override
  String get notificationTicketStatusChanged => 'Bilet durumu değişti';

  @override
  String get priority => 'Öncelik';

  @override
  String get status => 'Durum';

  @override
  String get assignee => 'Atanan';

  @override
  String get labels => 'Etiketler';

  @override
  String get noLabelsYet => 'Henüz etiket yok';

  @override
  String get clearLabels => 'Etiketleri temizle';

  @override
  String get pipelineStepAgentActivity => 'Ajan etkinliği';

  @override
  String get runStatusCompleted => 'Tamamlandı';

  @override
  String get runStatusQueued => 'Kuyrukta';

  @override
  String get ticketDescription => 'Açıklama';

  @override
  String get ticketPriorityNone => 'Yok';

  @override
  String get ticketPriorityUrgent => 'Acil';

  @override
  String get ticketPriorityHigh => 'Yüksek';

  @override
  String get ticketPriorityMedium => 'Orta';

  @override
  String get ticketPriorityLow => 'Düşük';

  @override
  String get ticketViewList => 'Liste';

  @override
  String get ticketViewBoard => 'Pano';

  @override
  String get ticketTitlePlaceholder => 'Issue başlığı';

  @override
  String get ticketDescriptionPlaceholder => 'Açıklama ekle…';

  @override
  String get createMore => 'Daha fazla oluştur';

  @override
  String selectedCount(int count) {
    return '$count seçili';
  }

  @override
  String get clearSelection => 'Seçimi temizle';

  @override
  String get bulkDeleteTitle => 'Biletleri sil';

  @override
  String bulkDeleteMessage(int count) {
    return '$count seçili bilet silinsin mi? Bu işlem geri alınamaz.';
  }

  @override
  String get assignTo => 'Ata…';

  @override
  String get sectionMembers => 'Üyeler';

  @override
  String get sectionAgents => 'Ajanlar';

  @override
  String get sidebarGroupWorkspace => 'Çalışma alanı';

  @override
  String get notificationsTitle => 'Bildirimler';

  @override
  String get notificationsTooltip => 'Bildirimler';

  @override
  String get notificationsEmpty => 'Güncelsiniz';

  @override
  String notificationsUnreadCount(int count) {
    return '$count okunmamış';
  }

  @override
  String get notificationsMarkRead => 'Okundu olarak işaretle';

  @override
  String get notificationsMarkUnread => 'Okunmadı olarak işaretle';

  @override
  String get notificationsEntryActions => 'Bildirim eylemleri';

  @override
  String get markAllRead => 'Tümünü okundu olarak işaretle';

  @override
  String get teamsNav => 'Ekipler';

  @override
  String get noWorkspace => 'Çalışma alanı yok';

  @override
  String get selectWorkspace => 'Bir çalışma alanı seçin';

  @override
  String get navMemory => 'Bellek';

  @override
  String get memoryTabFacts => 'Olgular';

  @override
  String get memoryTabPolicies => 'Politikalar';

  @override
  String get memoryGraphShowFacts => 'Olguları göster';

  @override
  String get memoryGraphHideFacts => 'Olguları gizle';

  @override
  String get memoryGraphExpandAll => 'Tüm olguları genişlet';

  @override
  String get memoryGraphCollapseAll => 'Tüm olguları daralt';

  @override
  String get memoryTabGraph => 'Bilgi grafiği';

  @override
  String get memoryNoWorkspace =>
      'Belleğini görüntülemek için bir çalışma alanı seçin.';

  @override
  String get searchArticles => 'Makalelerde ara';

  @override
  String get filterAll => 'Tümü';

  @override
  String get filterUnread => 'Okunmamış';

  @override
  String get filterSaved => 'Kaydedilenler';

  @override
  String get saveArticle => 'Makaleyi kaydet';

  @override
  String get removeFromSaved => 'Kaydedilenlerden kaldır';

  @override
  String get filterBySource => 'Kaynağa göre filtrele';

  @override
  String get viewAsList => 'Liste görünümü';

  @override
  String get viewAsGrid => 'Izgara görünümü';

  @override
  String get noMatchingArticles => 'Eşleşen makale yok';

  @override
  String get noMatchingArticlesBody =>
      'Farklı bir arama veya kaynak filtresi deneyin.';

  @override
  String get allCaughtUp => 'Hepsi güncel';

  @override
  String get allCaughtUpBody =>
      'Okunmamış makale yok — daha sonra tekrar bakın.';

  @override
  String get openArticlesInAppDescription =>
      'Bağlantıları varsayılan tarayıcınız yerine yerleşik okuyucuda açın.';

  @override
  String get blockAdsTrackersDescription =>
      'Okuyucuda açtığınız makalelerden reklamları, izleyicileri ve çerez bildirimlerini kaldırın.';

  @override
  String get agentQuestionHeader => 'Sizin için soru';

  @override
  String get agentQuestionAnsweredLabel => 'Yanıtlandı';

  @override
  String get agentQuestionFreeformHint => 'Yanıtınızı yazın…';

  @override
  String agentQuestionProgress(int index, int count) {
    return 'Soru $index / $count';
  }

  @override
  String get agentQuestionSkip => 'Atla';

  @override
  String get agentQuestionSkippedLabel => 'Atlandı';

  @override
  String get agentQuestionFreeformOptionHint => 'Kendi sözlerinizle anlatın…';

  @override
  String get reviewRequested => 'İnceleme istendi';

  @override
  String get connectGitHubHint =>
      'GitHub’a giriş yapın veya Ayarlar → Siz → Profil ve kimlik → Kod barındırma bölümüne bir token ekleyin';

  @override
  String get connectGitHubToLoadPrs =>
      'Pull request’leri yüklemek için GitHub’ı bağlayın';

  @override
  String get noRepositoriesConfigured => 'Yapılandırılmış depo yok';

  @override
  String openedAgo(String age) {
    return '$age açıldı';
  }

  @override
  String prTimelineOpened(String author) {
    return '$author bu pull request’i açtı';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commit',
      one: '1 commit',
    );
    return '$author bu pull request’i $_temp0 ile açtı';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return '$actor, $reviewers kullanıcısından inceleme istedi';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '$actor, $reviewers için inceleme isteğini kaldırdı';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '$actor, $requested kullanıcısından inceleme istedi ve $removed için inceleme isteğini kaldırdı';
  }

  @override
  String prTimelineAddedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'etiketlerini',
      one: 'etiketini',
    );
    return '$actor, $labels $_temp0 ekledi';
  }

  @override
  String prTimelineRemovedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'etiketlerini',
      one: 'etiketini',
    );
    return '$actor, $labels $_temp0 kaldırdı';
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
      other: 'etiketlerini',
      one: 'etiketini',
    );
    String _temp1 = intl.Intl.pluralLogic(
      removedCount,
      locale: localeName,
      other: 'etiketlerini',
      one: 'etiketini',
    );
    return '$actor, $added $_temp0 ekledi ve $removed $_temp1 kaldırdı';
  }

  @override
  String prTimelineCommitted(String author) {
    return '$author commit yaptı';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commit gönderdi',
      one: '1 commit gönderdi',
    );
    return '$author $_temp0';
  }

  @override
  String prTimelineApproved(String author) {
    return '$author bu değişiklikleri onayladı';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return '$author değişiklik istedi';
  }

  @override
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kod yorumu',
      one: '1 kod yorumu',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '$author inceledi';
  }

  @override
  String get prTimelineSomeone => 'Birisi';

  @override
  String get prTimelineBotBadge => 'bot';

  @override
  String updatedAgo(String age) {
    return 'Güncellendi $age';
  }

  @override
  String get checksPassing => 'Kontroller geçiyor';

  @override
  String get checksRunning => 'Kontroller çalışıyor';

  @override
  String get needsYourReview => 'İncelemeniz gerekiyor';

  @override
  String get checks => 'Kontroller';

  @override
  String get noReviewersAssigned => 'İnceleyici atanmadı';

  @override
  String get noAssignees => 'Atanan yok';

  @override
  String get loadingEllipsis => 'Yükleniyor…';

  @override
  String get loadingChecks => 'Kontroller yükleniyor…';

  @override
  String get noChecksYet => 'Henüz kontrol çalışmadı';

  @override
  String get noChangesToReview => 'İncelenecek değişiklik yok';

  @override
  String checksFailingCount(int count) {
    return '$count başarısız';
  }

  @override
  String get showMore => 'Daha fazla göster';

  @override
  String get showLess => 'Daha az göster';

  @override
  String get backToPullRequests => 'Pull request\'lere dön';

  @override
  String get pullRequestNotFound => 'Pull request bulunamadı';

  @override
  String get pullRequestNotFoundBody =>
      'Birleştirilmiş, kapatılmış veya taşınmış olabilir.';

  @override
  String get couldntLoadPullRequest => 'Bu pull request yüklenemedi';

  @override
  String get showDetails => 'Ayrıntıları göster';

  @override
  String get noDescriptionProvided => 'Açıklama yok.';

  @override
  String get factsHint => 'Ajanlarınız öğrendikçe gerçekler burada görünecek.';

  @override
  String get noFactsMatch => 'Aramanızla eşleşen gerçek yok';

  @override
  String get memoryLoadError => 'Bellek yüklenemedi';

  @override
  String get sortRecent => 'En son';

  @override
  String get sortConfidence => 'Güven';

  @override
  String get confidenceTooltip =>
      'Ajanların bu gerçeğin doğru olduğundan ne kadar emin olduğu, %0 ile %100 arasında.';

  @override
  String get supersededTooltip => 'Daha yeni bir gerçek bunun yerini aldı.';

  @override
  String get domain => 'Alan';

  @override
  String get fitToView => 'Görünüme sığdır';

  @override
  String get project => 'Proje';

  @override
  String get newProject => 'Yeni proje';

  @override
  String get editProject => 'Projeyi düzenle';

  @override
  String get deleteProject => 'Projeyi sil';

  @override
  String get noProject => 'Proje yok';

  @override
  String get allTickets => 'Tüm biletler';

  @override
  String get projectNamePlaceholder => 'Proje adı';

  @override
  String get projectDescriptionPlaceholder => 'Açıklama (isteğe bağlı)';

  @override
  String get projectColorLabel => 'Renk';

  @override
  String get noProjectsYet => 'Henüz proje yok';

  @override
  String get projectTicketsEmpty => 'Bu projede henüz bilet yok';

  @override
  String get createProject => 'Proje oluştur';

  @override
  String projectProgress(int done, int total) {
    return '$total üzerinden $done tamamlandı';
  }

  @override
  String deleteProjectConfirm(String name) {
    return '\"$name\" silinsin mi? Biletleri korunur ve projeden çıkarılır.';
  }

  @override
  String get projectStatusActive => 'Aktif';

  @override
  String get projectStatusCompleted => 'Tamamlandı';

  @override
  String get projectStatusArchived => 'Arşivlendi';

  @override
  String get markProjectCompleted => 'Tamamlandı olarak işaretle';

  @override
  String get markProjectActive => 'Aktif olarak işaretle';

  @override
  String get archiveProject => 'Arşivle';

  @override
  String get restoreProject => 'Geri yükle';

  @override
  String get relations => 'İlişkiler';

  @override
  String get relateTo => 'İlişkilendir';

  @override
  String get relationSubIssueOf => 'Alt konusu…';

  @override
  String get relationParentOf => 'Üst konusu…';

  @override
  String get relationBlockedBy => 'Engelleyen…';

  @override
  String get relationBlocking => 'Engelliyor…';

  @override
  String get relationRelatedTo => 'İlişkili…';

  @override
  String get relationDuplicateOf => 'Kopyası…';

  @override
  String get relationGroupParent => 'Üst';

  @override
  String get relationGroupSubIssues => 'Alt biletler';

  @override
  String get relationGroupBlockedBy => 'Engelleyen';

  @override
  String get relationGroupBlocking => 'Engelliyor';

  @override
  String get relationGroupRelated => 'İlişkili';

  @override
  String get relationGroupDuplicateOf => 'Kopyası';

  @override
  String get relationGroupDuplicatedBy => 'Kopyaları';

  @override
  String get copyId => 'Kimliği kopyala';

  @override
  String get ticketIdCopied => 'Bilet kimliği kopyalandı';

  @override
  String get searchTicketsHint => 'Bilet ara…';

  @override
  String get noMatchingTickets => 'Eşleşen bilet yok';

  @override
  String get clearAll => 'Tümünü temizle';

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs PR',
      one: '1 PR',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos depoda',
      one: '1 depoda',
    );
    return '$_temp0, $_temp1 incelemeni bekliyor';
  }

  @override
  String get manageWorkspacesSubtitle =>
      'Çalışma alanını yeniden adlandırın ve işaretini değiştirin — düzenlemek için soldan birini seçin.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count çalışma alanı',
      one: '1 çalışma alanı',
      zero: 'Çalışma alanı yok',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos depo',
      one: '1 depo',
      zero: 'Depo yok',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents ajan',
      one: '1 ajan',
      zero: '0 ajan',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'Kimlik';

  @override
  String get uploadImage => 'Görsel yükle';

  @override
  String get failedToSaveLogo =>
      'Logo görseli kaydedilemedi. Uygulamanın seçilen dosyayı okuyabildiğinden emin olun.';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG veya GIF, en fazla 2 MB. Aksi halde çalışma alanı baş harfi kullanılır.';

  @override
  String get workspaceNameFieldHelp =>
      'Seçicide, içerik yolunda ve her ekranda gösterilir.';

  @override
  String get dangerZone => 'Tehlikeli bölge';

  @override
  String get deleteThisWorkspace => 'Bu çalışma alanını sil';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return '$name kalıcı olarak silinir; depo bağlantıları, ajanlar ve bellek de gider. Bu işlem geri alınamaz.';
  }

  @override
  String get discard => 'At';

  @override
  String discardChangesQuestion(String name) {
    return '$name üzerindeki kaydedilmemiş değişiklikler atılsın mı?';
  }

  @override
  String get workspaceUpdated => 'Çalışma alanı güncellendi';

  @override
  String get editTitle => 'Başlığı düzenle';

  @override
  String get editDescription => 'Açıklamayı düzenle';

  @override
  String get addDescription => 'Açıklama ekle';

  @override
  String get prTitlePlaceholder => 'Başlık';

  @override
  String get prBodyPlaceholder => 'Açıklama yazın';

  @override
  String get write => 'Yaz';

  @override
  String get overview => 'Genel bakış';

  @override
  String get noFilesChanged => 'Değişen dosya yok';

  @override
  String get diff => 'Fark';

  @override
  String get preview => 'Önizleme';

  @override
  String get outdated => 'Eski';

  @override
  String get outdatedComments => 'Eski yorumlar';

  @override
  String outdatedCountLabel(int count) {
    return '$count eski';
  }

  @override
  String get prTemplateLabel => 'Şablon';

  @override
  String get prTemplateDefault => 'Varsayılan';

  @override
  String get addReviewers => 'İnceleyen ekle';

  @override
  String get addAssignees => 'Atanan ekle';

  @override
  String get searchUsers => 'Kişi ara…';

  @override
  String get searchReviewers => 'Kişi ve ekip ara…';

  @override
  String get usersSectionLabel => 'Kişiler';

  @override
  String get userStatusBusy => 'Meşgul';

  @override
  String get teamsSectionLabel => 'Ekipler';

  @override
  String get suggestedReviewers => 'Önerilen inceleyenler';

  @override
  String get noMatchingUsers => 'Eşleşen kişi yok';

  @override
  String get noMatchingReviewers => 'Eşleşme yok';

  @override
  String get requiredByCodeOwners => 'Kod sahipleri tarafından zorunlu';

  @override
  String reviewedOnBehalfOf(String login) {
    return '$login üzerinden';
  }

  @override
  String get team => 'Ekip';

  @override
  String get markdownBold => 'Kalın';

  @override
  String get markdownItalic => 'İtalik';

  @override
  String get markdownHeading => 'Başlık';

  @override
  String get markdownBulletList => 'Madde işaretli liste';

  @override
  String get markdownChecklist => 'Kontrol listesi';

  @override
  String get markdownCode => 'Kod';

  @override
  String get markdownLink => 'Bağlantı';

  @override
  String get markdownQuote => 'Alıntı';

  @override
  String get markdownSupported => 'Markdown desteklenir';

  @override
  String get markdownAttachImages => 'Görsel eklemek için tıklayın';

  @override
  String failedToUpdateTitle(String error) {
    return 'Başlık güncellenemedi: $error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'Açıklama güncellenemedi: $error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'İnceleyenler güncellenemedi: $error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'Atananlar güncellenemedi: $error';
  }

  @override
  String get discardChangesConfirm => 'Değişiklikler silinsin mi?';

  @override
  String get newPr => 'Yeni PR';

  @override
  String get openPullRequest => 'Pull request aç';

  @override
  String get composePrSubtitle =>
      'Push ettiğiniz bir daldan — ajan veya bilet yok';

  @override
  String get createAsDraft => 'Taslak olarak oluştur';

  @override
  String get composePrNoRepo => 'GitHub deposu seçilmedi';

  @override
  String get composePrNoRepoHint =>
      'Pull request açmak için GitHub bağlantılı deposu olan bir çalışma alanı seçin.';

  @override
  String get composePrPickBranches =>
      'Değişiklikleri önizlemek için bir temel ve karşılaştırma dalı seçin.';

  @override
  String get composePrNothingToCompare => 'Bu dallar arasında değişiklik yok.';

  @override
  String get repository => 'Depo';

  @override
  String get baseBranchLabel => 'Temel';

  @override
  String get compareBranchLabel => 'Karşılaştır';

  @override
  String get selectBranch => 'Dal seçin';

  @override
  String get navMeetings => 'Toplantılar';

  @override
  String get meetingsNoWorkspace =>
      'Toplantıları görmek için bir çalışma alanı seçin.';

  @override
  String get meetingsEmpty => 'Henüz toplantı yok';

  @override
  String get meetingsEmptyHint =>
      'İlk toplantınızı kaydedin — ses bu cihazda kalır, ajan notlara, kararlara ve eylem maddelerine dönüştürür.';

  @override
  String get meetingNotesHint =>
      'Hızlı not alın — ajan toplantıdan sonra genişletir.';

  @override
  String get meetingSpeakerMe => 'Siz';

  @override
  String get meetingStatusRecording => 'Kaydediliyor';

  @override
  String get meetingStatusProcessing => 'İşleniyor';

  @override
  String get meetingStatusDone => 'Tamamlandı';

  @override
  String get meetingStatusFailed => 'Başarısız';

  @override
  String get meetingsSubtitle =>
      'Bu cihazda yakalanır ve yazıya dökülür, ardından bir ajan özetler.';

  @override
  String get meetingsRecordMeeting => 'Toplantı kaydet';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Şu anda $count işleniyor',
      one: 'Şu anda 1 işleniyor',
    );
    return '$_temp0';
  }

  @override
  String meetingsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count toplantı',
      one: '1 toplantı',
      zero: 'Toplantı yok',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLedgerOpenActions => 'Açık eylemler';

  @override
  String get meetingsLedgerDecisions => 'Kararlar';

  @override
  String get meetingsLiveOpen => 'Kaydı aç';

  @override
  String get meetingTemplateShort => 'Şablon';

  @override
  String get meetingsStatThisWeek => 'Bu hafta';

  @override
  String get meetingsStatRecorded => 'Kaydedildi';

  @override
  String get meetingsFilterAll => 'Tümü';

  @override
  String get meetingsFilterDone => 'Tamamlandı';

  @override
  String get meetingsFilterProcessing => 'İşleniyor';

  @override
  String get meetingsSearchHint => 'Başlığa, kişiye, uygulamaya göre süzün…';

  @override
  String get meetingsBucketToday => 'Bugün';

  @override
  String get meetingsBucketYesterday => 'Dün';

  @override
  String get meetingsBucketEarlierThisWeek => 'Bu haftanın başı';

  @override
  String get meetingsBucketLastWeek => 'Geçen hafta';

  @override
  String get meetingsBucketOlder => 'Daha eski';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count karar',
      one: '1 karar',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total eylem maddesi';
  }

  @override
  String get meetingsEnhancedPill => 'geliştirilmiş';

  @override
  String get meetingsTranscribing => 'yazıya dökülüyor ve özetleniyor…';

  @override
  String get meetingsOpenAction => 'Aç';

  @override
  String get meetingsStopProcessing => 'Durdur';

  @override
  String get meetingsStillTranscribing =>
      'Hâlâ yazıya dökülüyor — özet bittiğinde görünür.';

  @override
  String get meetingsNoMatch => 'Eşleşen toplantı yok';

  @override
  String get meetingsNoMatchHint =>
      'Farklı bir filtre veya arama terimi deneyin.';

  @override
  String get meetingBackAllMeetings => 'Tüm toplantılar';

  @override
  String get meetingReRunSummary => 'Özeti yeniden çalıştır';

  @override
  String get meetingExport => 'Dışa aktar';

  @override
  String get meetingAugmentingBanner =>
      'Transkriptten notlarınız zenginleştiriliyor — kararlar ve eylem öğeleri çıkarılıyor…';

  @override
  String get meetingTabNotes => 'Notlar';

  @override
  String get meetingTabTranscript => 'Transkript';

  @override
  String get meetingTabActionItems => 'Eylem öğeleri';

  @override
  String get meetingTabDecisions => 'Kararlar';

  @override
  String get meetingNotesEnhancedToggle => 'Zenginleştirilmiş';

  @override
  String get meetingNotesYoursToggle => 'Notlarınız';

  @override
  String get meetingEnhancedByAgent =>
      'Ajan tarafından zenginleştirildi · transkriptten';

  @override
  String get meetingEnhancedPending => 'Ajan bu özet üzerinde hâlâ çalışıyor.';

  @override
  String get meetingNotesEmpty => 'Henüz zenginleştirilmiş not yok.';

  @override
  String get meetingNotesSavedLocally => 'Yerel olarak kaydedildi';

  @override
  String get meetingNotesSaving => 'Kaydediliyor…';

  @override
  String get meetingViewFullTranscript => 'Tam transkripti görüntüle';

  @override
  String get meetingTranscriptSearchHint => 'Transkriptte ara…';

  @override
  String get meetingSpeakerEveryone => 'Herkes';

  @override
  String get meetingSpeakerOthers => 'Diğerleri';

  @override
  String get meetingTranscriptEmpty => 'Henüz transkript yok.';

  @override
  String get meetingActionItemsEmpty => 'Çıkarılan eylem öğesi yok.';

  @override
  String get meetingActionItemFrom => 'bu toplantıdan';

  @override
  String get meetingCreateTicket => 'Bilet oluştur';

  @override
  String meetingTicketCreated(String key) {
    return '$key bileti oluşturuldu ve gönderildi.';
  }

  @override
  String get meetingTicketFailed => 'Bilet oluşturulamadı.';

  @override
  String get meetingDecisionsEmpty => 'Kaydedilmiş karar yok.';

  @override
  String get meetingEditTitle => 'Başlığı düzenle';

  @override
  String get meetingTitleLabel => 'Başlık';

  @override
  String get meetingAddActionItem => 'Eylem öğesi ekle';

  @override
  String get meetingEditActionItem => 'Eylem öğesini düzenle';

  @override
  String get meetingDeleteActionItem => 'Eylem öğesini sil';

  @override
  String get meetingActionItemContentLabel => 'Eylem öğesi';

  @override
  String get meetingActionItemContentHint => 'Ne yapılması gerekiyor?';

  @override
  String get meetingActionItemOwnerLabel => 'Sorumlu';

  @override
  String get meetingActionItemOwnerHint => 'Kim sorumlu? (isteğe bağlı)';

  @override
  String get meetingAddDecision => 'Karar ekle';

  @override
  String get meetingEditDecision => 'Kararı düzenle';

  @override
  String get meetingDeleteDecision => 'Kararı sil';

  @override
  String get meetingDecisionContentLabel => 'Karar';

  @override
  String get meetingDecisionContentHint => 'Ne kararlaştırıldı?';

  @override
  String get meetingReRunStarted =>
      'Transkript özetleyicisi yeniden çalıştırılıyor…';

  @override
  String get meetingReRunNoTranscript => 'Özetlenecek transkript henüz yok.';

  @override
  String get meetingExportCopied => 'Notlar panoya Markdown olarak kopyalandı.';

  @override
  String get meetingExportSaved => 'Toplantı dışa aktarıldı.';

  @override
  String meetingExportFailed(String error) {
    return 'Dışa aktarma başarısız: $error';
  }

  @override
  String get meetingExportNothing => 'Henüz dışa aktarılacak bir şey yok.';

  @override
  String get meetingPlaybackPlay => 'Oynat';

  @override
  String get meetingPlaybackPause => 'Duraklat';

  @override
  String get meetingPlaybackUnavailable =>
      'Bu cihazda ses oynatma kullanılamıyor.';

  @override
  String get meetingDetectedTitle => 'Toplantı algılandı';

  @override
  String meetingDetectedSubtitle(String label) {
    return '\"$label\" devam ediyor gibi görünüyor. Kaydedilsin mi?';
  }

  @override
  String get meetingDetectedSubtitleGeneric =>
      'Bir toplantı devam ediyor gibi görünüyor. Kaydedilsin mi?';

  @override
  String get meetingDetectedRecord => 'Kaydet';

  @override
  String get meetingDetectedDismiss => 'Yoksay';

  @override
  String get meetingAutoStopTitle =>
      'Bu toplantı bitmiş görünüyor. Kayıt durdurulsun mu?';

  @override
  String get meetingAutoStopStop => 'Durdur';

  @override
  String get meetingAutoStopKeep => 'Kaydı sürdür';

  @override
  String get meetingAutoDetect => 'Toplantıları otomatik algıla';

  @override
  String get meetingAutoDetectDescription =>
      'Takvimi ve konferans uygulamalarını izle; bir toplantı başladığında kayıt öner.';

  @override
  String get meetingsRecordingCrumb => 'Kaydediliyor…';

  @override
  String get meetingRecordTitleHint => 'Toplantı başlığı';

  @override
  String get meetingRecordTappingLabel => 'Dinlenen:';

  @override
  String get meetingRecordMic => 'Mikrofon';

  @override
  String get meetingRecordSystemAudio => 'Sistem sesi';

  @override
  String get meetingRecordPause => 'Duraklat';

  @override
  String get meetingRecordResume => 'Sürdür';

  @override
  String get meetingRecordStop => 'Durdur ve özetle';

  @override
  String get meetingRecordYourNotes => 'Notların';

  @override
  String get meetingRecordNotesPlaceholder =>
      'Dinlerken yaz. Birkaç parça yeter — durdurduktan sonra ajan, transkripti kullanarak bunları genişletir.';

  @override
  String get meetingRecordLiveTranscript => 'Canlı transkript';

  @override
  String get meetingRecordDecoding => 'cihazda çözülüyor';

  @override
  String get meetingRecordListening =>
      'Dinleniyor… konuşma bir-iki saniye içinde burada görünür, Sen / Diğerleri olarak etiketlenir.';

  @override
  String get meetingRecordPausedHint =>
      'Duraklatıldı — sürdürünceye kadar ses yok sayılır.';

  @override
  String get meetingRecordNotActive => 'Aktif kayıt yok.';

  @override
  String get meetingHudRecording => 'kaydediliyor';

  @override
  String get meetingHudPaused => 'duraklatıldı';

  @override
  String get meetingHudOpen => 'Aç';

  @override
  String get meetingHudStop => 'Durdur';

  @override
  String get meetingToolbarPopOut => 'Ayır';

  @override
  String get meetingToolbarHoldToStop => 'Kaydı durdurmak için basılı tut';

  @override
  String get meetingToolbarSemanticLabel => 'Toplantı kaydı araç çubuğu';

  @override
  String get orchestrate => 'Orkestre et';

  @override
  String get orchestrationUnavailable => 'Orkestrasyon kullanılamıyor';

  @override
  String get orchestrationApprove => 'Planı onayla';

  @override
  String get orchestrationReject => 'Reddet';

  @override
  String get orchestrationCancel => 'Orkestrasyonu iptal et';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count rol — $hires yeni işe alım';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count alt bilet';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'Tahmini maliyet: \$$amount';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total alt bilet tamamlandı';
  }

  @override
  String get orchestrationStatusProposed => 'Önerildi';

  @override
  String get orchestrationStatusApproved => 'Onaylandı';

  @override
  String get orchestrationStatusExecuting => 'Yürütülüyor';

  @override
  String get orchestrationStatusSynthesizing => 'Sentezleniyor';

  @override
  String get orchestrationStatusCompleted => 'Tamamlandı';

  @override
  String get orchestrationStatusFailed => 'Başarısız';

  @override
  String get orchestrationStatusCancelled => 'İptal edildi';

  @override
  String get messageFailed => 'Çalıştırma başarısız';

  @override
  String get turnLimitReached =>
      'Tur sınırında durduruldu — devam etmek için yanıtla';

  @override
  String get retried => 'Yeniden denendi';

  @override
  String replyingTo(String name) {
    return '$name yanıtlanıyor';
  }

  @override
  String get silenceTimeoutLabel => 'Sessizlik zaman aşımı (dakika)';

  @override
  String get silenceTimeoutHint =>
      'ör. 15 — bu süre boyunca çıktı yoksa çalıştırmayı sonlandır';

  @override
  String get capabilityJsonMode => 'JSON modu';

  @override
  String get capabilityModelSelection => 'Model seçimi';

  @override
  String get transcriptThinking => 'Düşünüyor…';

  @override
  String transcriptThoughtFor(String duration) {
    return '$duration düşündü';
  }

  @override
  String get transcriptStatusMakingEdits => 'Düzenlemeler yapılıyor…';

  @override
  String get transcriptStatusReadingFiles => 'Dosyalar okunuyor…';

  @override
  String get transcriptStatusSearching => 'Kod tabanı aranıyor…';

  @override
  String get transcriptStatusRunningCommands => 'Komutlar çalıştırılıyor…';

  @override
  String get transcriptStatusResponding => 'Yanıtlanıyor…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return '$tool çalıştırılıyor…';
  }

  @override
  String get transcriptInput => 'Girdi';

  @override
  String get transcriptOutput => 'Çıktı';

  @override
  String get transcriptErrorLabel => 'Hata';

  @override
  String get transcriptSandboxBlocked => 'Sandbox bir eylemi engelledi';

  @override
  String transcriptShowFullOutput(int kb) {
    return 'Tüm çıktıyı göster (+$kb KB)';
  }

  @override
  String transcriptShowAllLines(int count) {
    return 'Tüm $count satırı göster';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return 'İlk $count satır gösteriliyor';
  }

  @override
  String get transcriptGrepNoMatches => 'Eşleşme yok';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '$matches eşleşme',
      one: '1 eşleşme',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files dosya',
      one: '1 dosya',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return 'Kişi $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => 'Konuşmacıyı yeniden adlandır';

  @override
  String get meetingRenameSpeakerTitle => 'Konuşmacıyı yeniden adlandır';

  @override
  String get meetingSpeakerNameLabel => 'Ad';

  @override
  String get meetingSpeakerSuggestFromCalendar =>
      'Bu toplantının davetlilerinden';

  @override
  String get meetingRenameSpeakerApplyAll =>
      'Bu konuşmacının tüm bloklarına uygula';

  @override
  String get meetingRenameSpeakerScopeHint =>
      'Kapalıyken yalnızca seçili satır yeniden adlandırılır.';

  @override
  String get meetingLinkEvent => 'Etkinliğe bağla';

  @override
  String get meetingChangeEvent => 'Etkinliği değiştir';

  @override
  String get meetingLinkEventTitle => 'Takvim etkinliğine bağla';

  @override
  String get meetingLinkEventSearchHint => 'Etkinlik ara';

  @override
  String get meetingLinkEventEmpty => 'Yakında takvim etkinliği yok';

  @override
  String get meetingUnlinkEvent => 'Bağlantıyı kaldır';

  @override
  String get calendarLinkExistingMeeting => 'Mevcut toplantıya bağla';

  @override
  String get calendarLinkMeetingTitle => 'Toplantı bağla';

  @override
  String get calendarLinkMeetingSearchHint => 'Toplantı ara';

  @override
  String get calendarLinkMeetingEmpty => 'Bağlanacak toplantı yok';

  @override
  String get meetingRenameSpeakerFailed => 'Konuşmacı yeniden adlandırılamadı';

  @override
  String get calendarLinkUpdateFailed => 'Takvim bağlantısı güncellenemedi';

  @override
  String get rename => 'Yeniden adlandır';

  @override
  String get notNow => 'Şimdi değil';

  @override
  String get meetingSaveVoiceProfileTitle => 'Ses profili kaydedilsin mi?';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return '$name kişisinin ses izini kaydederek gelecekteki toplantılarda otomatik tanınmasını sağla.';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return '$name için ses profili kaydedildi';
  }

  @override
  String get meetingVoiceProfileSaveFailed => 'Ses profili kaydedilemedi';

  @override
  String get voiceProfilesSection => 'Ses profilleri';

  @override
  String get voiceProfilesDescription =>
      'Kaydedilen sesler gelecekteki toplantılarda otomatik tanınır.';

  @override
  String get voiceProfilesEmpty =>
      'Henüz kaydedilmiş ses yok. Bir toplantı dökümünde konuşmacıya ad verin, ardından \"Ses profilini kaydet\"i seçin.';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count örnek',
      one: '1 örnek',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => 'Ses profilini yeniden adlandır';

  @override
  String get deleteVoiceProfileTitle => 'Ses profili silinsin mi?';

  @override
  String deleteVoiceProfileBody(String name) {
    return '$name tanınmasın mı? Kaydedilmiş ses izi kaldırılır. Geçmiş toplantılarda uygulanmış adlar korunur.';
  }

  @override
  String get connectedLabel => 'Bağlı';

  @override
  String get ideTabGeneral => 'Genel';

  @override
  String get ideTabExplorer => 'Gezgin';

  @override
  String get ideTabSourceControl => 'Kaynak denetimi';

  @override
  String get generalSectionTodos => 'Yapılacaklar';

  @override
  String get generalSectionGoals => 'Hedefler';

  @override
  String get goalRunStatusActive => 'Etkin';

  @override
  String get goalRunStatusPaused => 'Duraklatıldı';

  @override
  String get goalRunStatusCompleted => 'Tamamlandı';

  @override
  String get goalRunStatusFailed => 'Başarısız';

  @override
  String get goalRunStatusCancelled => 'İptal edildi';

  @override
  String get goalRunStatusBudgetExhausted => 'Bütçe tükendi';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return 'Çalıştırma $run/$max · $cost/$cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return 'Çalıştırma $run · $cost/$cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return 'Son tarih $deadline';
  }

  @override
  String get goalRunPause => 'Hedefi duraklat';

  @override
  String get goalRunResume => 'Hedefe devam et';

  @override
  String goalRunResumeRaise(String cap) {
    return 'Devam et · tavanı $cap yap';
  }

  @override
  String get goalRunStop => 'Hedefi durdur';

  @override
  String get generalSectionAgents => 'Ajanlar';

  @override
  String get generalSectionTerminals => 'Terminaller';

  @override
  String get generalTodosEmpty => 'Henüz yapılacak yok';

  @override
  String get generalAgentsEmpty => 'Çalışan ajan yok';

  @override
  String get generalTerminalsEmpty => 'Açık terminal yok';

  @override
  String get generalSectionBrowsers => 'Tarayıcılar';

  @override
  String get generalSectionComputers => 'Bilgisayarlar';

  @override
  String get generalBrowsersEmpty => 'Açık tarayıcı yok';

  @override
  String get generalComputersEmpty => 'Açık bilgisayar yok';

  @override
  String get generalSectionPhones => 'Telefonlar';

  @override
  String get generalPhonesEmpty => 'Açık telefon yok';

  @override
  String get pauseAgent => 'Ajanı duraklat';

  @override
  String get resumeAgent => 'Ajanı sürdür';

  @override
  String get agentCannotPause =>
      'Bu ajan duraklatılamaz — bunun yerine durdurun.';

  @override
  String get goalClear => 'Hedefi temizle';

  @override
  String get undoLabelGoalClear => 'hedefi temizle';

  @override
  String get todoStatusPending => 'Başlanmadı';

  @override
  String get todoStatusInProgress => 'Devam ediyor';

  @override
  String get todoStatusCompleted => 'Tamamlandı';

  @override
  String get reorderTodo => 'Yapılacakları yeniden sırala';

  @override
  String get focusTerminal => 'Terminale odaklan';

  @override
  String get focusMachine => 'Makineye odaklan';

  @override
  String get focusBrowser => 'Tarayıcıya odaklan';

  @override
  String get todoEditorTitle => 'Yapılacakları düzenle';

  @override
  String get todoEditorHint =>
      'Her satıra bir öğe. Bekleyen için - [ ], devam eden için - [~], tamamlanan için - [x] kullanın.';

  @override
  String get todoNeedsText => 'Komuttan sonra biraz metin ekleyin';

  @override
  String get todoNotFound => 'Eşleşen yapılacak yok';

  @override
  String get todoCleared => 'Yapılacaklar listesi temizlendi';

  @override
  String get todoNothingToCopy => 'Kopyalanacak bir şey yok';

  @override
  String todoAdded(String content) {
    return '\"$content\" eklendi';
  }

  @override
  String todoStarted(String content) {
    return '\"$content\" başlatıldı';
  }

  @override
  String todoCompleted(String content) {
    return '\"$content\" tamamlandı';
  }

  @override
  String todoRemoved(String content) {
    return '\"$content\" kaldırıldı';
  }

  @override
  String todoCopied(int count) {
    return '$count öğe kopyalandı';
  }

  @override
  String todoImported(int count) {
    return '$count öğe içe aktarıldı';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return 'Bilinmeyen todo komutu \"$name\"';
  }

  @override
  String get terminal => 'Terminal';

  @override
  String get ideCloseTab => 'Sekmeyi kapat';

  @override
  String get ideSplitEditor => 'Editörü böl';

  @override
  String get ideSplitRight => 'Sağa böl';

  @override
  String get ideSplitDown => 'Aşağı böl';

  @override
  String get ideSplitLeft => 'Sola böl';

  @override
  String get ideSplitUp => 'Yukarı böl';

  @override
  String get ideCloseGroup => 'Grubu kapat';

  @override
  String get ideCloseOthers => 'Diğerlerini kapat';

  @override
  String get ideCloseToRight => 'Sağdakileri kapat';

  @override
  String get ideCloseSaved => 'Kaydedilenleri kapat';

  @override
  String get ideCloseAll => 'Tümünü kapat';

  @override
  String get ideSplit => 'Böl';

  @override
  String get ideToggleSidebar => 'Kenar çubuğunu aç/kapat';

  @override
  String get ideNewTab => 'Editörü aç';

  @override
  String get ideNewTabMenu => 'Yeni sekme';

  @override
  String get ideReviewCode => 'Kodu incele';

  @override
  String get ideRevertConfirmTitle => 'Değişiklikleri geri al';

  @override
  String get ideRevertUntracked => 'İzlenmeyen dosyalar geri alınamaz';

  @override
  String get ideRevertFailed =>
      'Dosyalar geri alınamadı. Sohbet çalışma ağacı kullanılamıyor olabilir.';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya',
      one: '1 dosya',
    );
    return '$_temp0 geri alınamadı (izlenmeyen).';
  }

  @override
  String get ideSearchMatchCase => 'Büyük/küçük harf eşleştir';

  @override
  String get ideSearchWholeWord => 'Tam sözcük';

  @override
  String get ideSearchRegex => 'Regex';

  @override
  String get ideSearchFilters => 'Arama filtreleri';

  @override
  String get ideSearchFilesToInclude => 'Dahil edilecek dosyalar';

  @override
  String get ideSearchFilesToExclude => 'Hariç tutulacak dosyalar';

  @override
  String get ideNoOpenTabs => 'Açık sekme yok — açmak için + kullanın';

  @override
  String get ideBrowserAddressHint => 'Adres girin veya arayın';

  @override
  String get ideSimpleWebBrowser => 'Basit web tarayıcısı';

  @override
  String get ideWebBrowser => 'Web tarayıcısı';

  @override
  String get ideBrowserEnterUrl =>
      'Gezinmeye başlamak için adres çubuğuna bir URL girin';

  @override
  String get ideCodeServer => 'Düzenleyici';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return '$fileName dosyasındaki değişiklikler kaydedilsin mi?';
  }

  @override
  String get ideUnsavedChangesBody =>
      'Kaydetmezseniz değişiklikleriniz kaybolur.';

  @override
  String get ideDontSave => 'Kaydetme';

  @override
  String get editorAutoSave => 'Otomatik kaydet';

  @override
  String get editorAutoSaveDescription =>
      'Gömülü düzenleyicideki değişiklikleri otomatik kaydet.';

  @override
  String get editorAutoSaveOff => 'Kapalı';

  @override
  String get editorAutoSaveAfterDelay => 'Bir gecikmeden sonra';

  @override
  String get editorAutoSaveOnFocusChange => 'Odak değişince';

  @override
  String get ideCodeServerUnavailable =>
      'Code-server bu sunucuda kullanılamıyor';

  @override
  String get ideCodeServerUnavailableHint =>
      'Sunucu ana makinesine code-server (coder/code-server) kurun, ardından düzenleyiciyi yeniden açın.';

  @override
  String get ideCodeServerInstalling => 'Düzenleyici hazırlanıyor…';

  @override
  String get ideCodeServerOpenInBrowser => 'Düzenleyiciyi tarayıcıda aç';

  @override
  String get ideCodeServerError => 'Düzenleyici açılamadı';

  @override
  String get paneSuspendedCaption =>
      'Kaynak tasarrufu için askıya alındı — odaklanınca yeniden yüklenir';

  @override
  String get ideFolderLoadFailed => 'Bu klasör yüklenemedi';

  @override
  String get ideFileSearchFailed => 'Dosyalar aranamadı';

  @override
  String get ideSearchInFiles => 'Dosyalarda ara';

  @override
  String get ideNoContentMatches => 'Eşleşme yok';

  @override
  String get ideSourceControlCreatePr => 'Pull request oluştur';

  @override
  String ideSourceControlViewPr(int number) {
    return 'Pull request #$number görüntüle';
  }

  @override
  String get ideSourceControlNoChanges => 'Değişiklik yok';

  @override
  String get noReposInConversation => 'Bu konuşmada depo yok';

  @override
  String get ideSourceControlNoSpace =>
      'Değişikliklerini görmek için bir konuşma açın';

  @override
  String get ideFileLoading => 'Yükleniyor…';

  @override
  String get ideFileBinary => 'İkili dosya';

  @override
  String get mcpExternalServers => 'Harici MCP sunucuları';

  @override
  String get mcpExternalServersDescription =>
      'Harici MCP sunucularına bağlanın (GitHub, Sentry, Postgres, tarayıcı otomasyonu). Claude, Cursor, VS Code ve diğer araçlar için yapılandırdığınız sunucular otomatik keşfedilir.';

  @override
  String get mcpApprovalMode => 'Araç onayı';

  @override
  String get mcpApprovalModeDescription =>
      'Hangi araç eylemlerinin sormadan çalışacağı. Okumalar her zaman izinlidir; üst katmanlar sorar.';

  @override
  String get mcpApprovalAlwaysAsk => 'Her zaman sor';

  @override
  String get mcpApprovalWrite => 'Yazmaları otomatik onayla';

  @override
  String get mcpApprovalYolo => 'Tümünü otomatik onayla';

  @override
  String get mcpNoExternalServers => 'Harici MCP sunucusu bulunamadı.';

  @override
  String get mcpAuthorize => 'Yetkilendir';

  @override
  String get mcpReconnect => 'Yeniden bağlan';

  @override
  String get mcpExternalConnectionsNote =>
      'Harici MCP sunucuları ajan sunucusunda çalışır (masaüstü ve web tarafından paylaşılır). OAuth sunucularını yetkilendirme yalnızca masaüstünde kullanılabilir.';

  @override
  String get mcpStatusConnected => 'Bağlı';

  @override
  String get mcpStatusConnecting => 'Bağlanıyor…';

  @override
  String get mcpStatusNeedsAuth => 'Yetkilendirme gerekli';

  @override
  String get mcpStatusFailed => 'Başarısız';

  @override
  String get mcpStatusCircuitOpen => 'Duraklatıldı';

  @override
  String get mcpStatusDisabled => 'Devre dışı';

  @override
  String get providersAndModels => 'Sağlayıcılar ve modeller';

  @override
  String get providersAndModelsDescription =>
      'Yerleşik ajanın kullanabileceği tüm sağlayıcıları listeler — bir API anahtarı ayarlayın veya tarayıcınızla oturum açın, bağlı her sağlayıcının modellerini ve fiyatlarını görün ve bu çalışma alanının hangi sağlayıcıları kullanabileceğini yönetin.';

  @override
  String get syncNow => 'Şimdi senkronize et';

  @override
  String syncNowResult(int applied, int failed) {
    return 'Senkronizasyon tamamlandı — $applied uygulandı, $failed başarısız';
  }

  @override
  String syncNowFailed(String error) {
    return 'Senkronizasyon başarısız: $error';
  }

  @override
  String get denied => 'Reddedildi';

  @override
  String get allowed => 'İzinli';

  @override
  String allowProviderSemantic(String provider) {
    return '$provider kullanımına izin ver';
  }

  @override
  String enabledViaEnv(String key) {
    return '$key ile etkin';
  }

  @override
  String costPerMillion(String input, String output) {
    return '1M başına $input / $output';
  }

  @override
  String contextTokens(String tokens) {
    return '$tokens bağlam';
  }

  @override
  String get usageAndCost => 'Kullanım ve maliyet';

  @override
  String get usageAndCostDescription =>
      'Ajanlarınızın son 7 gündeki harcaması, gözlemlenen çalışma maliyetlerine göre.';

  @override
  String get noUsageYet => 'Henüz kullanım kaydı yok.';

  @override
  String get spentThisWeek => 'bu hafta harcandı';

  @override
  String get subscriptionUsage => 'Abonelik kullanımı';

  @override
  String get subscriptionUsageUnavailable => 'Kullanılamıyor';

  @override
  String get subscriptionUsageExhausted => 'Kota doldu';

  @override
  String get subscriptionUsageSignInRequired => 'Yeniden oturum aç';

  @override
  String get subscriptionUsageSignInExpired =>
      'Oturum süresi doldu, sonraki çalışmada yenilenir';

  @override
  String get subscriptionUsagePartiallyAvailable => 'Kısmen kullanılabilir';

  @override
  String resetsIn(String duration) {
    return '$duration içinde sıfırlanır';
  }

  @override
  String get feedbackHelpful => 'Bu yardımcı oldu';

  @override
  String get feedbackNotHelpful => 'Bu yardımcı olmadı';

  @override
  String get modeChat => 'Sohbet';

  @override
  String get modePlan => 'Plan';

  @override
  String get modeReview => 'İnceleme';

  @override
  String get modeOrchestrate => 'Orkestrasyon';

  @override
  String get editorTheme => 'Düzenleyici teması';

  @override
  String get editorThemeDescription =>
      'Gömülü diff ve düzenleyicinin IDE\'nizle uyumlu olması için bir VS Code renk teması içe aktarın.';

  @override
  String get editorThemePasteHint =>
      'Bir VS Code renk teması JSON dosyasının içeriğini yapıştırın';

  @override
  String get editorThemeImported => 'Tema içe aktarıldı';

  @override
  String get editorThemeInvalid =>
      'Bu geçerli bir VS Code teması gibi görünmüyor';

  @override
  String get importTheme => 'Temayı içe aktar';

  @override
  String get clearTheme => 'Temayı temizle';

  @override
  String get openInDiffViewer => 'Diff görüntüleyicide aç';

  @override
  String get shellCommand => 'Komut';

  @override
  String get shellOutput => 'Çıktı';

  @override
  String get revertToHere => 'Buraya geri al';

  @override
  String get revertConfirmBody =>
      'Bu noktadan sonraki iletileri gizleyip ajanın dosya değişikliklerini bu tura geri almak istiyor musunuz? Bu işlemi geri alabilirsiniz.';

  @override
  String get revert => 'Geri al';

  @override
  String get revertedToHere => 'Buraya geri alındı';

  @override
  String get nothingToRevert => 'Geri alınacak bir şey yok';

  @override
  String get undoRevert => 'Geri almayı geri al';

  @override
  String get revertUndone => 'Geri alma iptal edildi';

  @override
  String get systemBehavior => 'Sistem davranışı';

  @override
  String get keepAwakeTitle => 'Ajanlar çalışırken bilgisayarı uyanık tut';

  @override
  String get keepAwakeOnSubtitle =>
      'Bir ajan çalışırken bilgisayar uykuya geçmez';

  @override
  String get keepAwakeOffSubtitle =>
      'Bir ajan çalışırken bile bilgisayar uykuya geçebilir';

  @override
  String get syncEngineSectionTitle => 'Senkronizasyon motoru';

  @override
  String get syncEngineDescription =>
      'Biletler, mesajlaşma ve notlar tam anlık görüntüler yerine küçük artımlı değişikliklerle canlı güncellenir. Bir anahtarı kapatmak o depoyu tam anlık görüntü moduna döndürür — değişikliğin geçerli olması için uygulamayı yeniden yükleyin.';

  @override
  String get syncEngineTicketsTitle => 'Biletler';

  @override
  String get syncEngineMessagingTitle => 'Mesajlaşma';

  @override
  String get syncEngineNotesTitle => 'Notlar';

  @override
  String get syncEngineOnSubtitle => 'Canlı delta senkronizasyonu etkin';

  @override
  String get syncEngineOffSubtitle =>
      'Tam anlık görüntü senkronizasyonu kullanılıyor';

  @override
  String get spaces => 'Alanlar';

  @override
  String get spacesHomeDescription =>
      'Listeden bir alan seçin veya yeni bir tane oluşturun.';

  @override
  String get noSpacesYet => 'Henüz alan yok';

  @override
  String get newSpace => 'Yeni alan';

  @override
  String get spaceName => 'Alan adı';

  @override
  String get spaceReposHint => 'Dahil edilecek repolar';

  @override
  String get ideSourceControl => 'Kaynak denetimi';

  @override
  String get stagedChanges => 'Hazırlanan değişiklikler';

  @override
  String get changes => 'Değişiklikler';

  @override
  String get stageFile => 'Hazırla';

  @override
  String get unstageFile => 'Hazırlamayı kaldır';

  @override
  String get stageAll => 'Tüm değişiklikleri stage et';

  @override
  String get unstageAll => 'Tümünü unstage et';

  @override
  String get stageChangesToCommit => 'Commit için değişiklikleri stage et';

  @override
  String get syncToPrHead => 'En son PR commit\'lerini çek';

  @override
  String get syncedToPrHead => 'En son PR commit\'leriyle senkronize';

  @override
  String get syncPrHeadDirty =>
      'Senkronize etmeden önce değişikliklerini commit et veya iptal et';

  @override
  String get syncPrHeadFailed => 'PR head ile senkronize edilemedi';

  @override
  String get spaceLabel => 'Çalışma alanı';

  @override
  String get keybindingNewSpace => 'Yeni çalışma alanı';

  @override
  String get keybindingCreateANewSpaceDescription =>
      'Yeni bir çalışma alanı oluştur';

  @override
  String get jumpToLatest => 'En sona git';

  @override
  String get streaming => 'Yayınlanıyor';

  @override
  String get newMessages => 'Yeni';

  @override
  String get copyLink => 'Bağlantıyı kopyala';

  @override
  String get linkCopied => 'Bağlantı kopyalandı';

  @override
  String get agentResponding => 'Ajan yanıtlıyor';

  @override
  String get agentFinished => 'Ajan tamamlandı';

  @override
  String get harnessConnectProviderForModels =>
      'Modelleri görmek için bir sağlayıcı bağla.';

  @override
  String get providerSignOut => 'Oturumu kapat';

  @override
  String get providerWaitingForDeviceCode =>
      'Tarayıcıda kodu onaylaman bekleniyor…';

  @override
  String get providerDeviceCodeHint =>
      'Bu kodun tarayıcıda gösterilenle eşleştiğini kontrol et, sonra onayla.';

  @override
  String get providerPlanUsageLoading => 'Plan kullanımı kontrol ediliyor…';

  @override
  String get providerPlanUsageUnavailable =>
      'Bu plan kullanım bilgisi bildirmedi.';

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return '$provider API anahtarı kaldırılsın mı?';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return 'Kayıtlı anahtar silinir ve bir daha gösterilemez. Yeni bir tane yapıştırana kadar $provider modellerini kullanan ajanlar çalışmaz.';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return '$provider kaldırılsın mı?';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return 'Sağlayıcı ve kayıtlı anahtarı silinir. Modellerine sabitlenmiş ajanlar çalışmayı durdurur.';
  }

  @override
  String get providerApiKeyHint => 'API anahtarı yapıştır';

  @override
  String get providerApiKeyStoredHint =>
      'Eklemek için başka bir API anahtarı yapıştır';

  @override
  String get providerAddAnotherAccount => 'Başka bir hesap ekle';

  @override
  String get providerActiveBadge => 'Etkin';

  @override
  String get providerOauthAccountFallback => 'OAuth hesabı';

  @override
  String get providerApiKeyFallback => 'API anahtarı';

  @override
  String get providerRemoveCredentialConfirmTitle =>
      'Bu kimlik bilgisi kaldırılsın mı?';

  @override
  String get providerSignOutAccountConfirmTitle => 'Bu hesaptan çıkılsın mı?';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return '$provider kullanan ajanlar diğer anahtarlarına ve hesaplarına düşer. Hiçbiri kalmazsa, bir tane ekleyene kadar dururlar.';
  }

  @override
  String get providerBaseUrlHint => 'Temel URL (isteğe bağlı)';

  @override
  String get addProvider => 'Sağlayıcı ekle';

  @override
  String get noCustomProviders => 'Henüz özel sağlayıcı yok.';

  @override
  String get providerNameLabel => 'Ad';

  @override
  String get apiTypeLabel => 'API türü';

  @override
  String get providerBaseUrlLabel => 'Temel URL';

  @override
  String get providerApiKeyOptionalHint => 'API anahtarı (isteğe bağlı)';

  @override
  String get dialectOpenAiCompatible => 'OpenAI uyumlu';

  @override
  String get dialectAnthropicCompatible => 'Anthropic uyumlu';

  @override
  String get removeProviderTooltip => 'Sağlayıcıyı kaldır';

  @override
  String get providerLogInWithBrowser => 'Tarayıcıyla oturum aç';

  @override
  String providerLoginDialogTitle(String provider) {
    return '$provider oturumu aç';
  }

  @override
  String get providerLabel => 'Sağlayıcı';

  @override
  String get selectProviderToLogin => 'Oturum açmak için bir sağlayıcı seç';

  @override
  String providerLoginFailed(String error) {
    return 'Oturum açılamadı: $error';
  }

  @override
  String get providerWaitingForBrowser =>
      'Tarayıcıda yetkilendirmen bekleniyor…';

  @override
  String get providerPasteCodeHint => 'Veya tarayıcıdaki kodu yapıştır';

  @override
  String get providerCompleteLogin => 'Tamamla';

  @override
  String get providerConnectedApiKey => 'API anahtarıyla bağlı';

  @override
  String get providerConnectedOauth => 'Bağlı';

  @override
  String providerConnectedAccount(String account) {
    return 'Bağlı · $account';
  }

  @override
  String get providerLocalReady => 'Yerel · hazır';

  @override
  String get providerNotConnected => 'Bağlı değil';

  @override
  String get preparingWorkspace => 'Çalışma alanı hazırlanıyor…';

  @override
  String provisioningRunningSetupScript(String repo) {
    return '$repo için kurulum betiği çalıştırılıyor…';
  }

  @override
  String get repoScriptsTitle => 'Betikler';

  @override
  String get repoScriptsTooltip => 'Yaşam döngüsü betiklerini yapılandır';

  @override
  String get repoScriptsSetupLabel => 'Kurulum betiği';

  @override
  String get repoScriptsSetupHelp =>
      'Alan oluşturulduktan hemen sonra çalışma ağacında çalışır — bağımlılıkları yükle, dosya üret. Başarısızlık alanı başarısız işaretler; yeniden deneme betiği tekrar çalıştırır.';

  @override
  String get repoScriptsArchiveLabel => 'Arşiv betiği';

  @override
  String get repoScriptsArchiveHelp =>
      'Alan çalışma ağacı silinmeden hemen önce çalışır — çalışma ağacı dışındaki kaynakları temizle. Başarısızlık silmeyi asla engellemez.';

  @override
  String get repoScriptsEnvHelp =>
      'Çalışma ağacından bash ile çalışır; CC_WORKSPACE_PATH (çalışma ağacı), CC_ROOT_PATH (repo kökü), CC_SPACE_ID, CC_SPACE_NAME ve CC_REPO_NAME tanımlıdır.';

  @override
  String get repoScriptsSetupPlaceholder => 'ör. pnpm install';

  @override
  String get repoScriptsArchivePlaceholder =>
      'ör. docker compose -p \$CC_SPACE_ID down';

  @override
  String get repoScriptsRecentRuns => 'Son çalıştırmalar';

  @override
  String get repoScriptsNoRuns => 'Henüz çalıştırma yok';

  @override
  String get repoScriptsSaved => 'Betikler kaydedildi';

  @override
  String get repoScriptsRunKindSetup => 'Kurulum';

  @override
  String get repoScriptsRunKindArchive => 'Arşiv';

  @override
  String get repoScriptsRunStatusRunning => 'Çalışıyor';

  @override
  String get repoScriptsRunStatusSucceeded => 'Başarılı';

  @override
  String get repoScriptsRunStatusFailed => 'Başarısız';

  @override
  String get repoScriptsRunStatusTimedOut => 'Zaman aşımı';

  @override
  String repoScriptsExitCode(int code) {
    return 'Çıkış kodu $code';
  }

  @override
  String provisioningCloningRepo(String repo) {
    return '$repo kopyalanıyor…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return '$repo içinde pull request alınıyor…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return '$agent ajanı kuruluyor…';
  }

  @override
  String get workspacePrepFailed => 'Çalışma alanı kurulumu başarısız';

  @override
  String get workspacePrepStopped => 'Çalışma alanı kurulumu durduruldu';

  @override
  String get stopWorkspacePrep => 'Hazırlamayı durdur';

  @override
  String get stopWorkspacePrepTooltip =>
      'Bu çalışma alanını hazırlamayı durdur';

  @override
  String get stopWorkspacePrepConfirm =>
      'Bu çalışma alanı hazırlığı durdurulsun mu? Süren kopyalama atılır — buradan yeniden başlatabilirsiniz.';

  @override
  String messageWillSendWhenReady(int count) {
    return '$count ileti hazır olunca gönderilecek';
  }

  @override
  String get membersNav => 'Üyeler';

  @override
  String get membersSettingsDescription =>
      'Bu çalışma alanına erişimi olan kişiler: üye listesi, davetler ve denetim kaydı';

  @override
  String get memberRosterLabel => 'Üye listesi';

  @override
  String get memberRepoAccessAction => 'Repo erişimi';

  @override
  String memberRepoAccessTitle(String name) {
    return '$name için repo erişimi';
  }

  @override
  String get roleOwner => 'Sahip';

  @override
  String get roleAdmin => 'Yönetici';

  @override
  String get roleMember => 'Üye';

  @override
  String get roleViewer => 'İzleyici';

  @override
  String get roleGuest => 'Misafir';

  @override
  String get removeMemberTitle => 'Üyeyi kaldır';

  @override
  String removeMemberConfirm(String name) {
    return '$name bu çalışma alanından kaldırılsın mı? Erişimleri hemen kesilir.';
  }

  @override
  String get transferOwnershipAction => 'Sahipliği devret';

  @override
  String get transferOwnershipTitle => 'Sahipliği devret';

  @override
  String transferOwnershipConfirm(String name) {
    return '$name bu çalışma alanının sahibi olsun mu? Siz yönetici olursunuz. Çalışma alanını silmek veya başka bir yöneticinin rolünü değiştirmek yalnızca sahibe aittir.';
  }

  @override
  String get transferOwnershipCta => 'Devret';

  @override
  String get auditTrailLabel => 'Yetkilendirme denetim kaydı';

  @override
  String get auditTrailDescription =>
      'Her izin ve red, hash zinciriyle bağlanır; değiştirilen veya silinen bir kayıt tespit edilebilir.';

  @override
  String get auditVerifyChain => 'Zinciri doğrula';

  @override
  String auditChainIntact(int count) {
    return 'Zincir sağlam — $count kayıt doğrulandı';
  }

  @override
  String auditChainBroken(int seq, String reason) {
    return 'Zincir $seq kaydında kırık: $reason';
  }

  @override
  String get auditEmpty => 'Henüz karar kaydı yok.';

  @override
  String get auditDenied => 'Reddedildi';

  @override
  String get auditAllowed => 'İzin verildi';

  @override
  String auditOnBehalfOf(String user) {
    return '$user adına';
  }

  @override
  String get policyTemplatesLabel => 'İlke şablonları';

  @override
  String get policyTemplatesDescription =>
      'Bir başlangıç duruşu uygula veya birini çalışma alanları arasında taşı.';

  @override
  String get policyTemplateStrict => 'Katı';

  @override
  String get policyTemplateBalanced => 'Dengeli';

  @override
  String get policyTemplatePermissive => 'İzin verici';

  @override
  String get policyTemplateApply => 'Uygula';

  @override
  String policyTemplateApplied(int count) {
    return '$count kural uygulandı';
  }

  @override
  String get policyExport => 'Politikayı kopyala';

  @override
  String get policyExported => 'Politika panoya kopyalandı';

  @override
  String get policyImport => 'Politikayı yapıştır';

  @override
  String policyImported(int count) {
    return '$count kural içe aktarıldı';
  }

  @override
  String get approveAndRemember => '8 saatliğine onayla';

  @override
  String get approveAndRememberTooltip =>
      'Bu eylemi onaylar ve 8 saat boyunca bu alanda benzerlerini sormaz. Kendiliğinden sona erer.';

  @override
  String get unknownUserLabel => 'Bilinmeyen kullanıcı';

  @override
  String get inviteMember => 'Üye davet et';

  @override
  String get inviteRepoAccessHeader => 'Depo erişimi';

  @override
  String get inviteRepoAccessExplainer =>
      'Yalnızca işaretlediğiniz depolar, seçtiğiniz düzeyde davetliyle paylaşılır. Diğer her şey gizli kalır.';

  @override
  String get grantLevelRead => 'Okuma';

  @override
  String get grantLevelReview => 'İnceleme';

  @override
  String get grantLevelWrite => 'Yazma';

  @override
  String get inviteExpiryLabel => 'Sona erme';

  @override
  String get expiryOneDay => '1 gün';

  @override
  String get expirySevenDays => '7 gün';

  @override
  String get expiryThirtyDays => '30 gün';

  @override
  String get createInviteAction => 'Davet oluştur';

  @override
  String get inviteOneTimeCodeLabel => 'Tek kullanımlık kod';

  @override
  String get inviteCodeShownOnce =>
      'Bu kod yalnızca bir kez gösterilir — şimdi kopyalayın.';

  @override
  String get inviteLinkLabel => 'Davet bağlantısı';

  @override
  String get inviteRedeemHint =>
      'Kodu davetliyle paylaşın; davetli kodu sunucu URL’nizde kullanır.';

  @override
  String get inviteScanQr => 'Veya tarayarak kullanın';

  @override
  String get inviteLoopbackWarningTitle =>
      'Davet yerel bir adrese işaret ediyor';

  @override
  String get inviteLoopbackWarningBody =>
      'Diğer makinelerdeki işbirlikçiler bu sunucuya ulaşamaz. Bir tünel başlatın (Ayarlar → Entegrasyonlar → Bu sunucuyu paylaş) veya ağınıza bağlayın ki dışarıdaki kullanıcılar bağlanabilsin.';

  @override
  String get inviteStatusOpen => 'Açık';

  @override
  String get inviteStatusUsed => 'Kullanıldı';

  @override
  String get inviteStatusRevoked => 'İptal edildi';

  @override
  String get inviteStatusExpired => 'Süresi doldu';

  @override
  String inviteCreatedTime(String time) {
    return 'Oluşturuldu $time';
  }

  @override
  String inviteExpiresOn(String date) {
    return 'süresi $date tarihinde dolar';
  }

  @override
  String get noActivityYet => 'Henüz etkinlik yok';

  @override
  String get couldNotLoadMembers => 'Üyeler yüklenemedi';

  @override
  String get couldNotLoadInvites => 'Davetler yüklenemedi';

  @override
  String get couldNotLoadActivity => 'Etkinlik yüklenemedi';

  @override
  String get yourDevices => 'Cihazlarınız';

  @override
  String get yourDevicesDescription =>
      'Bu sunucuda hesabınıza eşlenmiş istemciler.';

  @override
  String get noOwnDevices => 'Hesabınıza henüz eşlenmiş cihaz yok';

  @override
  String get renameDeviceTitle => 'Cihazı yeniden adlandır';

  @override
  String get revokeDeviceTitle => 'Cihazı iptal et';

  @override
  String revokeDeviceConfirm(String label) {
    return '$label iptal edilsin mi? Hemen bağlantısı kesilir ve bu sunucuya artık erişemez.';
  }

  @override
  String devicePairedTime(String time) {
    return 'Eşlendi $time';
  }

  @override
  String deviceLastSeenTime(String time) {
    return 'Son görülme $time';
  }

  @override
  String get deviceNeverSeen => 'Hiç bağlanmadı';

  @override
  String get profileSectionLabel => 'Profil';

  @override
  String get profileSectionDescription =>
      'Takım arkadaşlarınıza ve git commit yazarlığına nasıl göründüğünüz.';

  @override
  String get displayNameLabel => 'Görünen ad';

  @override
  String get emailLabel => 'E-posta';

  @override
  String get gitAuthorNameLabel => 'Git yazar adı';

  @override
  String get gitAuthorEmailLabel => 'Git yazar e-postası';

  @override
  String get profileSaved => 'Profil kaydedildi';

  @override
  String get presenceOnline => 'Çevrimiçi';

  @override
  String get presenceIdle => 'Boşta';

  @override
  String get presenceTyping => 'Yazıyor…';

  @override
  String get presenceAgentThinking => 'Düşünüyor';

  @override
  String get presenceAgentRunning => 'Çalışıyor';

  @override
  String get presenceAgentBlocked => 'Engellendi';

  @override
  String get presenceAgentDone => 'Bitti';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String presenceNameStatusCost(String name, String status, String cost) {
    return '$name — $status ($cost)';
  }

  @override
  String get presenceRailLabel => 'Kimler çevrimiçi';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => 'Rahatsız etmeyin\'i aç';

  @override
  String get dndTooltipOff => 'Rahatsız etmeyin\'i kapat';

  @override
  String get startPresenting => 'Sunuma başla';

  @override
  String get stopPresenting => 'Sunumu durdur';

  @override
  String spotlightPresentingBanner(String name) {
    return '$name sunum yapıyor';
  }

  @override
  String get spotlightLeave => 'Ayrıl';

  @override
  String typingIndicator(String name) {
    return '$name yazıyor…';
  }

  @override
  String get ideTabNotes => 'Notlar';

  @override
  String get ideSidebarAllViews => 'Tüm görünümler';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return 'Tüm görünümler ($count gizli)';
  }

  @override
  String get ideSidebarPinView => 'Kenar çubuğuna sabitle';

  @override
  String get ideSidebarUnpinView => 'Kenar çubuğundan kaldır';

  @override
  String get notesEmptyHint =>
      'Bu konuşmayı devralan herkes için bir not ekle…';

  @override
  String get notesEditTooltip => 'Notu düzenle';

  @override
  String notesUpdatedBy(String name, String time) {
    return '$name güncelledi · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '$name düzenliyor';
  }

  @override
  String get notesSaveFailed => 'Not kaydedilemedi';

  @override
  String get reactionAddTooltip => 'Tepki ekle';

  @override
  String reactionToggleTooltip(String emoji) {
    return '$emoji ile tepki ver';
  }

  @override
  String get autonomyDialLabel => 'Özerklik';

  @override
  String get autonomyProposeOnly => 'Yalnızca öner';

  @override
  String get autonomyActWithApproval => 'Onayla hareket et';

  @override
  String get autonomyActFreely => 'Serbest hareket et';

  @override
  String get autonomyDefaultOption => 'Varsayılan';

  @override
  String get checkerLabel => 'Denetleyici';

  @override
  String get checkerNone => 'Yok';

  @override
  String get checkerCaption =>
      'Denetleyici, diğer ajanların tamamlanan çalıştırmalarını inceler.';

  @override
  String get takeoverTooltip => 'Çalışma ağacını devral';

  @override
  String get takeoverBannerSelf => 'Bu konuşmanın çalışma ağacını devraldınız';

  @override
  String takeoverBannerOther(String name) {
    return '$name bu konuşmanın çalışma ağacını devraldı';
  }

  @override
  String get handBackButton => 'Geri ver';

  @override
  String get handBackDialogTitle => 'Çalışma ağacını geri ver';

  @override
  String get handBackDialogNoteHint => 'Ajan için isteğe bağlı not…';

  @override
  String takeoverFailed(String message) {
    return 'Devralınamadı: $message';
  }

  @override
  String handBackFailed(String message) {
    return 'Geri verilemedi: $message';
  }

  @override
  String get planStudioTitle => 'Plan Studio';

  @override
  String get plansTitle => 'Planlar';

  @override
  String get plansSubtitle => 'Aktif planlar, plan belgeleri ve playbook\'lar';

  @override
  String get plansActiveSection => 'Aktif planlar';

  @override
  String get plansDocumentsSection => 'Plan belgeleri';

  @override
  String get plansPlaybooksSection => 'Playbook\'lar';

  @override
  String get plansNoActive => 'Henüz aktif plan yok.';

  @override
  String get plansNoDocuments => 'Henüz plan belgesi yok.';

  @override
  String get plansNoPlaybooks => 'Henüz playbook yok.';

  @override
  String get planNotFound => 'Plan bulunamadı.';

  @override
  String get planOpenInStudio => 'Aç';

  @override
  String get planNodeTitle => 'Başlık';

  @override
  String get planNodeDescription => 'Açıklama';

  @override
  String get planNodeDescriptionHint => 'Bu adımın yapması gerekenler…';

  @override
  String get planNodeApplyDescription => 'Uygula';

  @override
  String get planNodeRole => 'Rol';

  @override
  String get planNodeDependencies => 'Bağımlılıklar';

  @override
  String get planNodeDependenciesHint => 'Bağımlılık ekle';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bağımlılık',
      one: '1 bağımlılık',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies =>
      'Bağımlılık yok, plan başlar başlamaz çalışır';

  @override
  String get planNodeOutputSchema => 'Çıktı şeması (JSON)';

  @override
  String get planNodeEstimate => 'Tahmin';

  @override
  String get planNodeProvenance => 'Kaynak';

  @override
  String get planNodeAlreadyExecuted =>
      'Zaten çalıştırıldı — düzenleme planı buradan çatallar.';

  @override
  String get planNewNodeTitle => 'Yeni adım';

  @override
  String get planEstimateNoHistory => 'Henüz geçmiş yok';

  @override
  String get planEstimateBlastUnknown => 'Etki alanı: bilinmiyor';

  @override
  String get planEstimatePartial => 'kısmi';

  @override
  String get planEstimateAction => 'Tahmin et';

  @override
  String planEstimateDuration(String range) {
    return 'Süre $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return 'Etki alanı: $files dosya, $symbols sembol';
  }

  @override
  String get planApprove => 'Planı onayla';

  @override
  String get planApproveSelectedNodes => 'Seçilenleri onayla';

  @override
  String get planReject => 'Reddet';

  @override
  String get planCancel => 'Çalıştırmayı iptal et';

  @override
  String get planContinueNode => 'Düğümü sürdür';

  @override
  String get planTotalNotEstimated => 'Henüz tahmin edilmedi';

  @override
  String get planBudgetExceeded => 'bütçe aşıldı';

  @override
  String planBudgetCeiling(String amount) {
    return 'bütçe ≤ \$$amount';
  }

  @override
  String get planVersionsTitle => 'Sürümler';

  @override
  String get planNoRevisions => 'Henüz revizyon yok.';

  @override
  String get planDiffIdentical => 'Değişiklik yok.';

  @override
  String get planDiffGoalChanged => 'Hedef değişti';

  @override
  String get planDiffBudgetChanged => 'Bütçe değişti';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'v$fromRev ile v$toRev arasındaki değişiklikler';
  }

  @override
  String planDiffAdded(String node) {
    return '$node eklendi';
  }

  @override
  String planDiffRemoved(String node) {
    return '$node kaldırıldı';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return '$node değişti: $fields';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return 'Kenar eklendi: $edge';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return 'Kenar kaldırıldı: $edge';
  }

  @override
  String planDiffRoleAdded(String role) {
    return 'Rol eklendi: $role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return 'Rol kaldırıldı: $role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return 'Rol yeniden atandı: $role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return 'Plan yeniden planlandı: v$approved onayladınız, şu an v$current. Devam etmeden önce farkı inceleyin.';
  }

  @override
  String planLiveActualCost(String amount) {
    return 'Gerçek maliyet: \$$amount';
  }

  @override
  String get planPlaybookRun => 'Çalıştır';

  @override
  String get planPlaybookDelete => 'Playbook\'u sil';

  @override
  String get planPlaybookProposed =>
      'Plan önerildi — Plan Studio\'da onaylayın.';

  @override
  String get planPlaybookAnchorTicket => 'Çapa bilet';

  @override
  String get planPlaybookPickTicket => 'Bir bilet seçin…';

  @override
  String get planPlaybookProposeRun => 'Plan öner';

  @override
  String get planPlaybookRepoHint => 'Bir depo kimliği';

  @override
  String get planPlaybookAgentHint => 'Bir ajan kimliği';

  @override
  String planPlaybookRunTitle(String name) {
    return '$name çalıştır';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '$count parametre';
  }

  @override
  String get recentLabel => 'Son';

  @override
  String get cheatSheetTitle => 'Klavye kısayolları';

  @override
  String get cheatSheetGlobal => 'Genel';

  @override
  String get cheatSheetThisScreen => 'Bu ekran';

  @override
  String get cheatSheetReservedInBrowser => 'Tarayıcıya ayrılmış';

  @override
  String get keybindingCheatSheet => 'Klavye kısayolları';

  @override
  String get keybindingShowKeyboardShortcutsDescription =>
      'Geçerli ekranın klavye kısayolu listesini göster';

  @override
  String get runPlaybookLabel => 'Playbook çalıştır';

  @override
  String get playbooksLabel => 'Playbooks';

  @override
  String get keybindingUndo => 'Geri al';

  @override
  String get keybindingRedo => 'Yinele';

  @override
  String get keybindingUndoLastActionDescription =>
      'Son geri alınabilir eylemi geri al';

  @override
  String get keybindingRedoLastActionDescription =>
      'Son geri alınan eylemi yinele';

  @override
  String get undone => 'Geri alındı';

  @override
  String get redone => 'Yinelendi';

  @override
  String get undoFailed => 'Geri alınamadı';

  @override
  String get undoLabelTicketEdit => 'bilet düzenlemesi';

  @override
  String get undoLabelMessageEdit => 'mesaj düzenlemesi';

  @override
  String get undoLabelTodoStatus => 'todo durumu';

  @override
  String get inboxTitle => 'Gelen kutusu';

  @override
  String get inboxReview => 'İnceleme';

  @override
  String get inboxOpen => 'Açık';

  @override
  String get inboxAllCaughtUp => 'Hepsi tamamlandı';

  @override
  String get inboxGitHubDownTitle => 'GitHub kapalı olabilir';

  @override
  String inboxGitHubDownBody(String status) {
    return 'GitHub $status bildiriyor, bu yüzden pull request\'ler tamamlanmış değil, listede eksik olabilir.';
  }

  @override
  String get inboxGitHubIdentityTitle => 'GitHub hesabın doğrulanamadı';

  @override
  String get inboxGitHubIdentityBody =>
      'Gelen kutusu GitHub\'daki kimliğine göre sıralanır. Bu yüklenene kadar boş kalır, seni bekleyen pull request\'ler olsa bile.';

  @override
  String get inboxSeverityBlocking => 'Engellendi';

  @override
  String get inboxSeverityWaiting => 'Bekliyor';

  @override
  String get inboxSeverityInfo => 'Bilgi';

  @override
  String get inboxSyncFailed => 'Eşitleme başarısız';

  @override
  String get inboxNeedsYourAttention => 'Dikkatin gerekiyor';

  @override
  String get inboxSectionNeedsYourReview => 'İncelemen gerekiyor';

  @override
  String get inboxSectionReturnedToYou => 'Sana iade edildi';

  @override
  String get inboxSectionApproved => 'Onaylandı';

  @override
  String get inboxSectionDrafts => 'Taslaklar';

  @override
  String get inboxSectionWaitingForReviewers => 'İnceleyenler bekleniyor';

  @override
  String get inboxSectionMergingAndMerged =>
      'Birleştiriliyor ve yakın zamanda birleştirilenler';

  @override
  String get inboxSectionWaitingForAuthor => 'Yazar bekleniyor';

  @override
  String get inboxColumnTitle => 'Başlık';

  @override
  String get inboxColumnChanges => 'Değişiklikler';

  @override
  String get inboxColumnUpdated => 'Güncellendi';

  @override
  String get inboxReviewApproved => 'Onaylandı';

  @override
  String get inboxReviewChangesRequested => 'Değişiklik istendi';

  @override
  String get inboxHeroSubtitle =>
      'Seni ilgilendiren her pull request, sıradaki adıma göre sıralanır.';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull request incelemeni bekliyor',
      one: '1 pull request incelemeni bekliyor',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sana iade edildi',
      one: '1 sana iade edildi',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted =>
      'Değişiklik kaydedilemedi ve geri alındı';

  @override
  String get offlinePendingLabel => 'bekliyor';

  @override
  String get offlineSyncingLabel => 'eşitleniyor';

  @override
  String get copyLinkLabel => 'Bu sayfanın bağlantısını kopyala';

  @override
  String get agentsSectionLabel => 'Ajanlar';

  @override
  String get fleetWorkersTitle => 'İşçiler';

  @override
  String get fleetWorkersSubtitle => 'İş çalıştırabilecek makineler';

  @override
  String get fleetJobsTitle => 'İşler';

  @override
  String get fleetJobsSubtitle => 'Filoya dağıtılan işler';

  @override
  String get fleetNoWorkers =>
      'Henüz işçi yok — `cc_worker --server <url>` çalıştıran ikinci bir makine filoya katılır.';

  @override
  String get fleetNoJobs => 'İş yok.';

  @override
  String get fleetError => 'Filo yüklenemedi';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count çekirdek',
      one: '1 çekirdek',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return 'Heartbeat $time';
  }

  @override
  String get fleetNoHeartbeat => 'Henüz heartbeat yok';

  @override
  String fleetLastErrorLabel(String error) {
    return 'Son hata: $error';
  }

  @override
  String get fleetDrain => 'Boşalt';

  @override
  String get fleetResume => 'Sürdür';

  @override
  String get fleetRevoke => 'İptal et';

  @override
  String get fleetRemove => 'Kaldır';

  @override
  String get fleetRevokeTitle => 'İşçi iptal edilsin mi?';

  @override
  String fleetRevokeBody(String name) {
    return '$name iptal edilsin mi? Oturumu sonlanır ve aktif işler yeniden atanır.';
  }

  @override
  String get fleetRemoveTitle => 'İşçi kaldırılsın mı?';

  @override
  String fleetRemoveBody(String name) {
    return '$name filodan kaldırılsın mı? Kaydı silinir.';
  }

  @override
  String get fleetActionFailed => 'İşlem başarısız';

  @override
  String get fleetJobUnassigned => 'Atanmamış';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '$attempts/$max deneme';
  }

  @override
  String get fleetPlacementReasons => 'Yerleştirme kararları';

  @override
  String get fleetNoPlacements => 'Henüz yerleştirme kararı yok.';

  @override
  String get fleetStatusOnline => 'Çevrimiçi';

  @override
  String get fleetStatusDraining => 'Boşaltılıyor';

  @override
  String get fleetStatusOffline => 'Çevrimdışı';

  @override
  String get fleetStatusIncompatible => 'Uyumsuz';

  @override
  String get fleetStatusRevoked => 'İptal edildi';

  @override
  String get fleetJobStatusQueued => 'Kuyrukta';

  @override
  String get fleetJobStatusRunning => 'Çalışıyor';

  @override
  String get fleetJobStatusSucceeded => 'Başarılı';

  @override
  String get fleetJobStatusFailed => 'Başarısız';

  @override
  String get fleetJobStatusCancelled => 'İptal edildi';

  @override
  String get evalsNoSuites => 'Henüz eval paketi yok.';

  @override
  String get evalsError => 'Eval\'ler yüklenemedi';

  @override
  String get evalsStarterBadge => 'Başlangıç';

  @override
  String evalsDefaultBatch(int count) {
    return '$count öğelik varsayılan batch';
  }

  @override
  String get evalsRecentRuns => 'Son çalıştırmalar';

  @override
  String get evalsNoRuns => 'Henüz çalıştırma yok.';

  @override
  String get evalsPassRate => 'Geçme oranı';

  @override
  String evalsBatchTimes(int count) {
    return '× $count';
  }

  @override
  String evalsTriggeredBy(String who) {
    return '$who tarafından';
  }

  @override
  String evalsRunFinished(String rate) {
    return 'Eval bitti — $rate geçti';
  }

  @override
  String get evalsRunFailed => 'Paket çalıştırılamadı';

  @override
  String get evalsRun => 'Çalıştır';

  @override
  String get evalsStatusQueued => 'Kuyrukta';

  @override
  String get evalsStatusRunning => 'Çalışıyor';

  @override
  String get evalsStatusPassed => 'Geçti';

  @override
  String get evalsStatusFailed => 'Başarısız';

  @override
  String get bannerMeetingJoin => 'Katıl';

  @override
  String get bannerMeetingRecordAndLink => 'Kaydet ve bağla';

  @override
  String get bannerCalendarReconnect => 'Yeniden bağlan';

  @override
  String get bannerView => 'Görüntüle';

  @override
  String get soundscapeTitle => 'Ses manzaraları';

  @override
  String get soundscapePlay => 'Oynat';

  @override
  String get soundscapePause => 'Duraklat';

  @override
  String get soundscapeMoodLabel => 'Ruh hali';

  @override
  String get soundscapeMoodFocus => 'Odak';

  @override
  String get soundscapeMoodRelax => 'Rahatla';

  @override
  String get soundscapeMoodSleep => 'Uyku';

  @override
  String get soundscapeVolumeLabel => 'Ses';

  @override
  String get soundscapeTuneLabel => 'Ton';

  @override
  String get soundscapeTuneMellow => 'Yumuşak';

  @override
  String get soundscapeTuneBright => 'Parlak';

  @override
  String get soundscapeTuneEnergetic => 'Enerjik';

  @override
  String get soundscapeTuneSpacy => 'Uzaysı';

  @override
  String get soundscapeTuneResetHint => 'Sıfırlamak için iki kez dokun';

  @override
  String get soundscapeSceneLabel => 'Şimdi çalıyor';

  @override
  String get soundscapeSceneLoading => 'Ortam ayarlanıyor…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees°C';
  }

  @override
  String get soundscapeLocationLabel => 'Konum';

  @override
  String get soundscapeLocationDetecting => 'Konum algılanıyor…';

  @override
  String get soundscapeLocationAutoNote =>
      'Konum bu çalışma alanından otomatik olarak algılanır.';

  @override
  String get soundscapeRefreshWeather => 'Hava durumunu yenile';

  @override
  String get soundscapeAutoStartLabel => 'Odak moduyla başlat';

  @override
  String get soundscapeAutoStartDescription =>
      'Odak oturumu başlattığında bir ses manzarasını otomatik olarak çal.';

  @override
  String get soundscapeReturnToApp => 'Uygulamaya dön';

  @override
  String get soundscapePopOut => 'Oynatıcıyı ayır';

  @override
  String get discussion => 'Tartışma';

  @override
  String get chat => 'Sohbet';

  @override
  String get saving => 'Kaydediliyor…';

  @override
  String get saved => 'Kaydedildi';

  @override
  String get saveFailed => 'Kaydedilemedi';

  @override
  String get commitAndPush => 'Commit ve push';

  @override
  String get commit => 'Commit';

  @override
  String get commitAmend => 'Commit (amend)';

  @override
  String get commitAndSync => 'Commit ve senkronize et';

  @override
  String get committed => 'Commit edildi';

  @override
  String get commitAmended => 'Commit amend edildi';

  @override
  String get commitFailed => 'Commit başarısız';

  @override
  String get moreCommitActions => 'Diğer commit işlemleri';

  @override
  String get sourceControl => 'Kaynak denetimi';

  @override
  String fixFindingTitle(String location) {
    return 'Düzelt: $location';
  }

  @override
  String get openInEditor => 'Düzenleyicide aç';

  @override
  String get regexTesterTitle => 'Düzenli ifadeyi dene';

  @override
  String get regexTesterHint => 'Bir örnek yazın';

  @override
  String get regexMatch => 'Eşleşme';

  @override
  String get regexNoMatch => 'Eşleşme yok';

  @override
  String get regexInvalidPattern => 'Geçersiz desen';

  @override
  String get symbolLookupNone => 'Dizinde veya bu pull request’te tanım yok';

  @override
  String get symbolLookupInDiff => 'Bu pull request’te bulundu';

  @override
  String get symbolLookupFromBase =>
      'Temel checkout\'tan — bu PR\'nin worktree\'si henüz indekslenmedi';

  @override
  String get symbolImplementations => 'Uygulamalar';

  @override
  String symbolCallersCount(int count) {
    return '$count çağıran';
  }

  @override
  String get commitMessageHint => 'Commit mesajı';

  @override
  String get pushedToPr => 'PR’a push edildi';

  @override
  String get pushFailed => 'Push başarısız';

  @override
  String get reviewFindings => 'Bulgular';

  @override
  String get treeLabel => 'Ağaç';

  @override
  String get toggleFileTree => 'Dosya ağacını göster veya gizle';

  @override
  String get diffViewSettings => 'Diff görünümü ayarları';

  @override
  String get splitViewLabel => 'Bölünmüş';

  @override
  String get unifiedViewLabel => 'Birleşik';

  @override
  String get wrapLines => 'Satırları kaydır';

  @override
  String get shiftClickSelectRange => 'Aralık seçmek için Shift-tıkla';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya',
      one: '1 dosya',
    );
    return '$_temp0';
  }

  @override
  String prComplexityLoc(String loc) {
    return '$loc LOC';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return 'Küçük PR — $files, inceleme ~$minutes dk';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return 'Orta PR — $files, inceleme için ~$minutes dk ayır';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return 'Büyük PR — $files, incelemeden önce bölmeyi düşün';
  }

  @override
  String get searchInFiles => 'Dosyalarda ara';

  @override
  String get showFileList => 'Dosya listesini göster';

  @override
  String get searchInFilesHintField => 'Dosyalarda ara…';

  @override
  String get searchInFilesHint => 'Pull request dosyalarında ara';

  @override
  String get searchInWholeRepo => 'Tüm depoda ara';

  @override
  String get searchInThisPullRequest => 'Bu pull request içinde ara';

  @override
  String get searchNoResults => 'Sonuç bulunamadı';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sonuç',
      one: '1 sonuç',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files dosyada',
      one: '1 dosyada',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String get discardChangesTitle => 'Değişiklikler atılsın mı?';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya',
      one: '1 dosya',
    );
    return '$_temp0 HEAD’e atılsın mı? Bu işlem geri alınamaz.';
  }

  @override
  String get discardAll => 'Tümünü at';

  @override
  String get discardFailed => 'Değişiklikler atılamadı';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya',
      one: '1 dosya',
    );
    return '$_temp0 atıldı';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '$reverted dosya',
      one: '1 dosya',
    );
    return '$_temp0 atıldı; $skipped atlandı (izlenmeyen)';
  }

  @override
  String get prWorktreeUnavailable => 'Çalışma alanı hazır değil';

  @override
  String get prWorktreeUnavailableHint =>
      'Pull request dosyaları hazırlanamadı. Yeniden denemek için pull request’i yeniden aç.';

  @override
  String get timestampRelativeLabel => 'Göreli';

  @override
  String get timestampRawLabel => 'Zaman damgası';

  @override
  String get copyTimestamp => 'Zaman damgasını kopyala';

  @override
  String get copiedTimestamp => 'Zaman damgası kopyalandı';

  @override
  String get previewDeployment => 'Önizleme dağıtımı';

  @override
  String previewDeploymentTab(String site) {
    return 'Önizleme: $site';
  }

  @override
  String get askForReview => 'İnceleme iste…';

  @override
  String get closePrsConfirmTitle => 'Pull request’ler kapatılsın mı?';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull request kapatılsın mı?',
      one: '1 pull request kapatılsın mı?',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull request kapatıldı',
      one: '1 pull request kapatıldı',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull request atandı',
      one: '1 pull request atandı',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull request için inceleme istendi',
      one: '1 pull request için inceleme istendi',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count işlem başarısız',
      one: '1 işlem başarısız',
    );
    return '$_temp0';
  }

  @override
  String get diagram => 'Diyagram';

  @override
  String get diagramViewSource => 'Kaynağı göster';

  @override
  String get diagramHideSource => 'Kaynağı gizle';

  @override
  String diagramPreviewUnavailable(String reason) {
    return 'Diyagram önizlemesi kullanılamıyor ($reason)';
  }

  @override
  String get planUnavailable => 'Plan kullanılamıyor';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count adım',
      one: '1 adım',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => 'Onayla ve çalıştır';

  @override
  String get planStatusDraft => 'Taslak';

  @override
  String get planStatusProposed => 'Plan';

  @override
  String get planStatusApproved => 'Plan onaylandı';

  @override
  String get planStatusRejected => 'Plan reddedildi';

  @override
  String get planStatusSuperseded => 'Plan geçersiz kılındı';

  @override
  String planRevisionLabel(int revision) {
    return 'Revizyon $revision';
  }

  @override
  String get adapterEnforcementTitle => 'Bu bağdaştırıcının uyguladıkları';

  @override
  String get enforcementFiltersToolSurface => 'Araçları Control Center seçer';

  @override
  String get enforcementInterceptsToolCalls =>
      'Her çağrı çalışmadan önce denetlenir';

  @override
  String get enforcementObservesCompletionContract =>
      'Çalışma teslimine bağlı tutulur';

  @override
  String get enforcementNativeToolsInterceptable =>
      'Çalıştırıcının kendi araçları görünür';

  @override
  String get enforcementInProcessToolsSandboxed =>
      'Süreç içi araçlar sandbox\'ta çalışır';

  @override
  String get enforcementYes => 'Evet';

  @override
  String get enforcementNo => 'Hayır';

  @override
  String get adapterEnforcementCaveats => 'Uyarılar';

  @override
  String get enforcementSummaryModesEnforced => 'Uygulanan modlar';

  @override
  String get enforcementSummaryModesNotEnforced => 'Uygulanmayan modlar';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uyarı',
      one: '1 uyarı',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      'Salt okunur modlar yapısal değil: Control Center bu çalıştırıcının kendi araçlarını kaldıramaz.';

  @override
  String get caveatToolCallsNotIntercepted =>
      'Çalıştırma öncesi kapı yok: Control Center\'dan yalnızca MCP araç çağrıları geçer.';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      'Çalıştırıcının kendi dosya ve kabuk araçları Control Center\'a hiç ulaşmaz; onları sınırlayan tek katman işletim sistemi sandbox\'ıdır.';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      'Süreç içi dosya araçları sandbox dışında çalışır; dosya sistemi sınırı yalnızca araç yüzeyidir.';

  @override
  String get caveatCompletionContractUnobservable =>
      'Control Center, teslimini üretmeden biten bir çalışmayı yönlendiremez veya başarısız sayamaz.';

  @override
  String get modeDegraded => 'Kısıtlı';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return '$adapter üzerindeki $mode modu yalnızca sandbox\'a dayanır; ajanın kendi dosya araçları denetlenmez.';
  }

  @override
  String get artifactUnavailable => 'Artifakt kullanılamıyor';

  @override
  String artifactRevisionLabel(int count) {
    return '$count revizyon';
  }

  @override
  String get artifactShowMore => 'Daha fazla göster';

  @override
  String get artifactShowLess => 'Daha az göster';

  @override
  String get artifactCopy => 'Kopyala';

  @override
  String get artifactCopied => 'Artifakt kopyalandı';

  @override
  String get artifactsTabLabel => 'Artifaktlar';

  @override
  String get artifactsEmptyTitle => 'Henüz artifakt yok';

  @override
  String get artifactsEmptyBody =>
      'Bir ajan buraya tablo, grafik veya diyagram yayınladığında listede görünür.';

  @override
  String get artifactRevisionPickerLabel => 'Revizyon';

  @override
  String get artifactRestoreRevision => 'Bu revizyonu geri yükle';

  @override
  String get artifactOpenInTab => 'Sekmede aç';

  @override
  String get artifactTitleFallback => 'Artifakt';

  @override
  String get providerGenerationLabel => 'Oluşturma varsayılanları';

  @override
  String get providerGenerationHint =>
      'Uç noktanın kendi varsayılanını kullanmak için alanı boş bırakın. Modeller kendi çıktı tavanlarını ve örnekleme tariflerini yayınlar; başka değerlerle sunmak kaliteyi düşürebilir.';

  @override
  String get providerMaxTokensLabel => 'En fazla çıktı token\'ı';

  @override
  String get addModel => 'Model ekle';

  @override
  String get modelListTitle => 'Model listesi';

  @override
  String get railProvidersGroup => 'Sağlayıcılar';

  @override
  String get railCustomProvidersGroup => 'Özel sağlayıcılar';

  @override
  String get editModelSettings => 'Model ayarlarını düzenle';

  @override
  String get modelIdLabel => 'Model kimliği';

  @override
  String get modelIdImmutableHint =>
      'Uç noktanın sunduğu kimlik; listelendikten sonra değiştirilemez.';

  @override
  String get contextWindowLabel => 'Bağlam penceresi';

  @override
  String get inputTypesLabel => 'Girdi türleri';

  @override
  String get outputTypesLabel => 'Çıktı türleri';

  @override
  String get modalityText => 'Metin';

  @override
  String get modalityImage => 'Görüntü';

  @override
  String get modalityAudio => 'Ses';

  @override
  String get modalityVideo => 'Video';

  @override
  String get modalityPdf => 'PDF';

  @override
  String get modelOverrideReset => 'Otomatiğe sıfırla';

  @override
  String get modelOverrideEdited => 'Düzenlendi';

  @override
  String get manualModelBadge => 'Elle eklendi';

  @override
  String get modelIdRequired => 'Bir model kimliği girin.';

  @override
  String get modelTokensInvalid => 'Pozitif tam sayı bir token sayısı girin.';

  @override
  String get removeModelAction => 'Modeli kaldır';

  @override
  String removeModelConfirmTitle(String model) {
    return '$model kaldırılsın mı?';
  }

  @override
  String get removeModelConfirmBody =>
      'Model listeden çıkar ve ona sabitlenmiş ajanlar çalışmayı durdurur. Sağlayıcı etkilenmez.';

  @override
  String get addModelProviderTitle => 'Model sağlayıcısı ekle';

  @override
  String get addModelProviderDescription =>
      'Özel bir API uç noktası ve modellerini yapılandırın.';

  @override
  String get modelListEmptyHint =>
      'Yapılandırılmış model yok. Sohbette kullanmak için bir model ekleyin.';

  @override
  String get addProviderModelsHint =>
      'Uç nokta yanıt verdiğinde modeller canlı çekilir. Yalnızca kendi listesini veremiyorsa elle ekleyin.';

  @override
  String get providerTemperatureLabel => 'Sıcaklık';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved => 'Üretim varsayılanları kaydedildi';

  @override
  String get providerGenerationInvalid =>
      'Değerleri kontrol edin: en fazla çıktı token’ı ve top-k pozitif olmalı, sıcaklık 0–2, top-p 0–1.';

  @override
  String get providerGenerationOverridden => 'Geçersiz kılındı';

  @override
  String get branchNotPushed => 'gönderilmedi';

  @override
  String branchNotOnRemote(String branch) {
    return '“$branch” yalnızca bu konuşmada var';
  }

  @override
  String get branchNotOnRemoteHint =>
      'GitHub bu dalı hiç görmedi, bu yüzden bir pull request henüz onu kullanamaz. Yayınlamak, çalışma ağacındaki mevcut commit’leri gönderir — commit edilmemiş değişiklikler olduğu gibi kalır.';

  @override
  String get publishBranch => 'Dalı yayınla';

  @override
  String branchPublished(String branch) {
    return '“$branch” origin’e yayınlandı';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return 'Dal yayınlandı. $count commit edilmemiş değişiklik dahil edilmedi.';
  }

  @override
  String get composePrLoadingBranches => 'GitHub’dan dallar yükleniyor…';

  @override
  String get composePrBranchesFailed =>
      'GitHub’dan dallar yüklenemedi. Bir dal adı yazın veya GitHub bağlantısını kontrol edin.';

  @override
  String get composePrSubtitleFromSpace =>
      'Bu konuşmanın dalından — GitHub henüz görmediyse önce yayınlayın';

  @override
  String get obsTabInsights => 'İçgörüler';

  @override
  String get obsTabLive => 'Canlı';

  @override
  String get obsTabQuality => 'Kalite';

  @override
  String get obsTabUsage => 'Kullanım';

  @override
  String get obsUsageTotalTokens => 'Toplam token';

  @override
  String get obsUsagePeakTokens => 'Tepe token';

  @override
  String get obsUsageLongestSession => 'En uzun oturum';

  @override
  String get obsUsageCurrentStreak => 'Mevcut seri';

  @override
  String get obsUsageLongestStreak => 'En uzun seri';

  @override
  String obsUsageDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün',
      one: '1 gün',
      zero: '0 gün',
    );
    return '$_temp0';
  }

  @override
  String get obsUsageTokenActivity => 'Token etkinliği';

  @override
  String get obsUsageActivityModeLabel => 'Token etkinliği modu';

  @override
  String get obsUsageModeDaily => 'Günlük';

  @override
  String get obsUsageModeWeekly => 'Haftalık';

  @override
  String get obsUsageModeCumulative => 'Kümülatif';

  @override
  String get obsUsageTimeRange => 'Zaman aralığı';

  @override
  String get obsUsageTrendTitle => 'Günlük token eğilimi';

  @override
  String get obsUsageModelUsage => 'Model kullanımı';

  @override
  String get obsUsageTokensLabel => 'token';

  @override
  String get obsUsageNoActivity => 'Henüz token kullanımı kaydedilmedi';

  @override
  String get obsUsageOtherModels => 'Diğer';

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
    return '$start ile $end arasındaki token etkinliği. $activeDays aktif gün. En yoğun gün $peak token.';
  }

  @override
  String get obsScreenSubtitle =>
      'Canlı ajan denetimi, maliyet atfı, kotalar ve kalite sinyalleri';

  @override
  String get obsRangeLast24h => 'Son 24 saat';

  @override
  String get obsRangeLast7d => 'Son 7 gün';

  @override
  String get obsRangeLast30d => 'Son 30 gün';

  @override
  String get obsRangeAll => 'Tüm zamanlar';

  @override
  String get obsAddFilter => 'Filtre ekle';

  @override
  String get obsFilterAgent => 'Ajan';

  @override
  String get obsFilterModel => 'Model';

  @override
  String get obsFilterStatus => 'Durum';

  @override
  String get obsFilterRole => 'Rol';

  @override
  String get obsKpiTotalRuns => 'Toplam çalıştırma';

  @override
  String get obsKpiTotalCost => 'Toplam maliyet';

  @override
  String get obsKpiErrorRate => 'Hata oranı';

  @override
  String get obsKpiCacheRate => 'Önbellek oranı';

  @override
  String get obsKpiTokensPerSec => 'Token / sn';

  @override
  String get obsKpiAvgLatency => 'Ort. gecikme';

  @override
  String get obsKpiTtft => 'İlk token süresi';

  @override
  String obsDeltaVsPrevious(String delta) {
    return 'Önceki döneme göre $delta';
  }

  @override
  String get obsChartActivity => 'Etkinlik';

  @override
  String get obsChartCost => 'Zaman içinde maliyet';

  @override
  String get obsLegendRuns => 'Çalıştırmalar';

  @override
  String get obsLegendErrors => 'Hatalar';

  @override
  String get obsAgentsTitle => 'Ajanlar';

  @override
  String obsShowAllAgents(int count) {
    return 'Tüm $count ajanı göster';
  }

  @override
  String get obsShowFewerAgents => 'Daha az göster';

  @override
  String get obsRunsTitle => 'Çalıştırmalar';

  @override
  String get obsNoRunsInRange => 'Bu aralıkta çalıştırma yok';

  @override
  String get obsColTime => 'Zaman';

  @override
  String get obsColAgent => 'Ajan';

  @override
  String get obsColStatus => 'Durum';

  @override
  String get obsColModel => 'Model';

  @override
  String get obsColDuration => 'Süre';

  @override
  String get obsColTokens => 'Token';

  @override
  String get obsColCost => 'Maliyet';

  @override
  String get obsColErrors => 'Hatalar';

  @override
  String get obsColRuns => 'Çalıştırmalar';

  @override
  String get obsColAvgLatency => 'Ort. gecikme';

  @override
  String get obsColLastActive => 'Son etkinlik';

  @override
  String get obsStatusPending => 'Beklemede';

  @override
  String get obsStatusRunning => 'Çalışıyor';

  @override
  String get obsStatusCompleted => 'Tamamlandı';

  @override
  String get obsStatusError => 'Hata';

  @override
  String get obsRosterLoadError => 'Ajan listesi yüklenemedi.';

  @override
  String get obsRosterEmpty => 'Henüz ajan yok';

  @override
  String get obsRosterEmptyDescription =>
      'Bir ajan gönderin, burada canlı görünsün — durum, geçerli araç, token, maliyet.';

  @override
  String get obsKillAgent => 'Ajanı durdur';

  @override
  String get obsRosterTokensLabel => 'tok';

  @override
  String get obsCostByRoleTitle => 'Role göre maliyet';

  @override
  String get obsCostByRoleSubtitle =>
      'Bu çalışma alanının ajan rolüne göre harcaması';

  @override
  String get obsRoleMain => 'Ana';

  @override
  String get obsRoleSubagents => 'Alt ajanlar';

  @override
  String get obsRoleAdvisor => 'Advisor';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return 'Ana: $main · alt ajanlar: $sub · advisor: $advisor';
  }

  @override
  String get obsTotal => 'Toplam';

  @override
  String get obsTokenModelTitle => 'Token modeli (5 eksen)';

  @override
  String get obsTokenModelSubtitle =>
      'Bu çalışma alanının harcadığı tüm token’lar, eksene göre';

  @override
  String get obsAxisInput => 'Girdi';

  @override
  String get obsAxisOutput => 'Çıktı';

  @override
  String get obsAxisReasoning => 'Akıl yürütme';

  @override
  String get obsAxisCacheRead => 'Önbellek okuma';

  @override
  String get obsAxisCacheWrite => 'Önbellek yazma';

  @override
  String get obsTotalTokens => 'Toplam token';

  @override
  String get obsCacheDiscountNote =>
      'Önbellek-okuma token’ları indirimli faturalanır, bu yüzden aynı hacimdeki yeni girdiden çok daha ucuza gelir.';

  @override
  String get obsByModelTitle => 'Modele göre';

  @override
  String get obsByModelSubtitle => 'Modele göre token ve maliyet kullanımı';

  @override
  String get obsNoModelUsage => 'Henüz model kullanımı kaydedilmedi.';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count çalıştırma',
      one: '1 çalıştırma',
    );
    return '$_temp0';
  }

  @override
  String get obsPerRunTitle => 'Çalıştırma başına';

  @override
  String get obsPerRunSubtitle => 'Tek bir çalıştırmanın tipik token maliyeti';

  @override
  String get obsMedianRunTokens => 'Medyan çalıştırma token\'ı';

  @override
  String get obsMedianRunTokensSub => 'Tüm çalıştırmaların orta noktası';

  @override
  String get obsRunsInWorkspace => 'Bu çalışma alanında';

  @override
  String get obsCostShare => 'Maliyet payı';

  @override
  String get obsQuotaConfiguredLimits => 'Yapılandırılmış limitler';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      'Belirlediğiniz tavanlara göre kullanım, en kötü durum önce.';

  @override
  String get obsQuotaAddLimit => 'Limit ekle';

  @override
  String get obsQuotaNoLimits =>
      'Henüz kota limiti yapılandırılmadı — kullanımı bir tavana göre izlemek için bir tane ekleyin.';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return '$title limitini kaldır';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return '$duration içinde sıfırlanır · $status';
  }

  @override
  String get obsQuotaUsageWindows => 'Kullanım pencereleri';

  @override
  String get obsQuotaUsageWindowsSubtitle =>
      'Tüm sağlayıcılarda gözlemlenen kullanım, tavan uygulanmadı.';

  @override
  String get obsQuotaNoUsage => 'Henüz kullanım kaydedilmedi.';

  @override
  String get obsQuotaTokensUsed => 'Kullanılan token';

  @override
  String get obsQuotaRequests => 'İstekler';

  @override
  String get obsQuotaUnitTokens => 'token';

  @override
  String get obsQuotaUnitRequests => 'istek';

  @override
  String get obsQuotaUnitCost => 'maliyet';

  @override
  String get obsQuotaAddLimitTitle => 'Kota limiti ekle';

  @override
  String get obsQuotaProviderLabel => 'Sağlayıcı';

  @override
  String get obsQuotaWindowLabel => 'Pencere';

  @override
  String get obsQuotaUnitLabel => 'Birim';

  @override
  String obsQuotaLimitLabel(String unit) {
    return 'Limit ($unit)';
  }

  @override
  String get obsQuotaCentsHint => 'ABD senti cinsinden (500 = \$5.00).';

  @override
  String get obsQuotaStatusOk => 'Tamam';

  @override
  String get obsQuotaStatusWarning => 'Uyarı';

  @override
  String get obsQuotaStatusExhausted => 'Tükendi';

  @override
  String get obsQuotaStatusUnknown => 'Bilinmiyor';

  @override
  String get obsGoalNoActiveTitle => 'Aktif hedef yok';

  @override
  String get obsGoalNoActiveBody =>
      'Ajanlara bir amaç ve isteğe bağlı bir token bütçesi vermek için bir hedef belirleyin. Çalıştırmalar tamamlandıkça bütçe dolar ve neredeyse tükendiğinde ajanlar işi toparlamaya yönlendirilir.';

  @override
  String get obsGoalSetGoal => 'Hedef belirle';

  @override
  String get obsGoalTokenBudget => 'Token bütçesi';

  @override
  String obsGoalTokensLeft(String tokens) {
    return '$tokens kaldı';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens (bütçe yok)';
  }

  @override
  String get obsGoalTokensUsed => 'Kullanılan token';

  @override
  String get obsGoalElapsed => 'Geçen süre';

  @override
  String get obsGoalWrapUp => 'Toparla';

  @override
  String get obsGoalClear => 'Hedefi temizle';

  @override
  String get obsGoalFallbackTitle => 'Hedef';

  @override
  String get obsGoalSubtitle => 'Hedef modu bütçesi';

  @override
  String get obsGoalStatusActive => 'Aktif';

  @override
  String get obsGoalStatusPaused => 'Duraklatıldı';

  @override
  String get obsGoalStatusBudgetLimited => 'Bütçe sınırlı';

  @override
  String get obsGoalStatusComplete => 'Tamamlandı';

  @override
  String get obsGoalStatusDropped => 'Bırakıldı';

  @override
  String get obsGoalObjectiveLabel => 'Amaç';

  @override
  String get obsGoalBudgetLabel => 'Token bütçesi (isteğe bağlı)';

  @override
  String get obsGoalSetAction => 'Hedefi belirle';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => 'Başarı %';

  @override
  String get obsBenchmarkPassed => 'Geçti';

  @override
  String get obsBenchmarkFailed => 'Başarısız';

  @override
  String get obsBenchmarkErrors => 'Hatalar';

  @override
  String get obsBenchmarkSpend => 'Harcama';

  @override
  String get obsBenchmarkCostPerTask => 'Maliyet / görev';

  @override
  String get obsBenchmarkTrials => 'Denemeler';

  @override
  String get obsBenchmarkNoTrials => 'Henüz puanlanacak çalıştırma yok.';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ve $count tane daha',
      one: 'Ve 1 tane daha',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => 'Geçti';

  @override
  String get obsBenchmarkTrialFail => 'Kaldı';

  @override
  String get obsBenchmarkTrialError => 'Hata';

  @override
  String get obsBenchmarkTrialRunning => 'Çalışıyor';

  @override
  String get obsBenchmarkReward => 'Ödül';

  @override
  String get obsBenchmarkReport => 'Rapor';

  @override
  String get obsBenchmarkCopyMarkdown => 'Markdown kopyala';

  @override
  String get obsBenchmarkCopied => 'Rapor panoya kopyalandı';

  @override
  String get obsBehaviorCaption =>
      'Bunlar kendi iletilerinizden ayrıştırılan hayal kırıklığı sinyalleri — sohbet sağlığına dair bir okuma, ajanlar için bir skor değil. Yerelde hesaplanır; hiçbir şey bu cihazdan çıkmaz.';

  @override
  String get obsBehaviorMessagesAnalyzed => 'Analiz edilen iletiler';

  @override
  String get obsBehaviorTotalSignals => 'Toplam sinyal';

  @override
  String get obsBehaviorYelling => 'Bağırma';

  @override
  String get obsBehaviorProfanity => 'Küfür';

  @override
  String get obsBehaviorAnguish => 'Sıkıntı';

  @override
  String get obsBehaviorNegation => 'Olumsuzlama';

  @override
  String get obsBehaviorRepetition => 'Tekrar';

  @override
  String get obsBehaviorBlame => 'Suçlama';

  @override
  String get obsBehaviorConversationsTitle =>
      'En çok hayal kırıklığı içeren sohbetler';

  @override
  String get obsBehaviorConversationsSubtitle =>
      'İletilerinizdeki sinyal yoğunluğuna göre sıralandı.';

  @override
  String get obsBehaviorNoSignals =>
      'Hayal kırıklığı sinyali yok — her şey yolunda.';

  @override
  String obsBehaviorMessagesCount(String count) {
    return '$count ileti analiz edildi';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '$count sinyal';
  }

  @override
  String get obsAgentStatusIdle => 'Boşta';

  @override
  String get obsAgentStatusParked => 'Park edildi';

  @override
  String get obsAgentStatusAborted => 'İptal edildi';

  @override
  String get obsAgentKindSub => 'Alt';

  @override
  String get noChecksOnCommit => 'Bu commit için henüz kontrol çalıştırılmadı.';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Çalışıyor — $count iş',
      one: 'Çalışıyor — 1 iş',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tüm kontroller geçti — $count iş',
      one: 'Tüm kontroller geçti — 1 iş',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tamamlandı — $count iş',
      one: 'Tamamlandı — 1 iş',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total işten $failed tanesi başarısız',
      one: '1 işten $failed tanesi başarısız',
    );
    return '$_temp0';
  }

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count iş',
      one: '1 iş',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return 'Matris: $jobId';
  }

  @override
  String get jobLogsPending => 'İş bitince loglar burada görünür.';

  @override
  String get jobLogsUnavailable => 'Bu iş için log yok.';

  @override
  String get noLogsForStep => 'Bu adım için log kaydedilmedi.';

  @override
  String get jobLogsTruncated => 'Log kısaltıldı — en son çıktı gösteriliyor.';

  @override
  String get fullLog => 'Tam log';

  @override
  String get copyLogs => 'Logları kopyala';

  @override
  String get resizeGraph => 'Grafiği yeniden boyutlandırmak için sürükle';

  @override
  String workflowRunStartedAgo(String time) {
    return '$time başladı';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return '$time tamamlandı';
  }

  @override
  String get chatBridgesTitle => 'Sohbet köprüleri';

  @override
  String chatProviderDescription(String provider, String command) {
    return '$provider içinde botu etiketleyerek bir ajana iş verin veya $command ile bilet açın.';
  }

  @override
  String chatConnectProvider(String provider) {
    return '$provider bağla';
  }

  @override
  String get chatDisconnectProvider => 'Bağlantıyı kes';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$teamName içinde $botName';
  }

  @override
  String get chatStateLive => 'Canlı';

  @override
  String get chatStateConnecting => 'Bağlanıyor…';

  @override
  String get chatStateError => 'Bağlantı hatası';

  @override
  String get chatNotConnected => 'Bağlı değil';

  @override
  String chatStreamingUnavailable(String provider) {
    return 'Bu $provider uygulamasında canlı akış kapalı — yanıtlar tek ileti olarak gelir.';
  }

  @override
  String chatAdminOnly(String provider) {
    return 'Bu çalışma alanı için $provider yalnızca bir yönetici bağlayabilir.';
  }

  @override
  String chatConnectHint(String provider) {
    return 'Bir $provider uygulaması oluşturun, ardından kimlik bilgilerini buraya yapıştırın. Control Center $provider tarafına bağlanır; bu sunucunun genel adresi olması gerekmez.';
  }

  @override
  String chatOpenConsole(String provider) {
    return '$provider konsolunu aç';
  }

  @override
  String get chatOpenSetupGuide => 'Kurulum kılavuzu';

  @override
  String get chatFieldBotToken => 'Bot token';

  @override
  String get chatFieldAppToken => 'Uygulama düzeyi token';

  @override
  String get chatFieldConfigRefreshToken => 'Uygulama yapılandırma jetonu';

  @override
  String chatFieldOptional(String label) {
    return '$label (isteğe bağlı)';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return '$provider hesabımı bağla';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return '$provider hesabını bağla; orada gönderdiğin iletiler sana atfedilsin.';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return '$externalUserId olarak bağlı';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return '$provider hesabını bağla';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return 'Bu komutu $provider içinde bota gönder. Bir kez çalışır ve 15 dakika sonra süresi dolar.';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return '$provider hesabın artık bağlı — orada gönderdiğin iletiler sana atfedilir.';
  }

  @override
  String get chatLinkedAccounts => 'Bağlı hesaplar';

  @override
  String chatNoLinkedAccounts(String provider) {
    return 'Henüz kimse $provider hesabını bağlamadı.';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bağlı hesap',
      one: '1 bağlı hesap',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '$externalUserId · e-postayla eşleşti';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '$externalUserId · kodla bağlandı';
  }

  @override
  String get chatUnlink => 'Bağlantıyı kaldır';

  @override
  String get chatCustomizeBot => 'Botu özelleştir';

  @override
  String get chatCustomizeBotDescription =>
      'Botun adını değiştir, kendini nasıl tanıttığını güncelle veya slash komutunu yeniden adlandır.';

  @override
  String get chatCustomizeBotUnavailable =>
      'Control Center\'ın botu düzenlemesi için bir uygulama yapılandırma jetonu gerekir. Yeniden bağlan ve bir jeton ekle.';

  @override
  String chatCreateAppTitle(String provider) {
    return '$provider uygulamasını oluştur';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'Control Center, doğru izinler ve olaylar ayarlanmış olarak $provider uygulamasını senin için oluşturabilir. İşlemi $provider içinde tamamla, ardından kimlik bilgilerini buraya yapıştır.';
  }

  @override
  String get chatCreateApp => 'Uygulama oluştur';

  @override
  String get chatCreateAppCta => 'Uygulamayı benim için oluştur';

  @override
  String get chatAppNameLabel => 'Uygulama adı';

  @override
  String get chatBotDisplayNameLabel =>
      'Bot adı (üyelerin @ sonrasında yazdığı ad)';

  @override
  String get chatDescriptionLabel => 'Kısa açıklama';

  @override
  String get chatAgentDescriptionLabel =>
      'Botun neler yapabileceğini söylediği metin';

  @override
  String get chatCommandLabel => 'Slash komutu';

  @override
  String get chatDirectMessages => 'Direkt mesajlar';

  @override
  String chatDirectMessagesHint(String provider) {
    return 'Üyelerin botla DM\'de sohbet etmesini sağlar. Ücretli bir $provider planı gerekebilir.';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return '$provider, $appId uygulamasını oluşturdu.';
  }

  @override
  String chatRemainingSteps(String provider) {
    return 'Birkaç adım kaldı ve bunları yalnızca $provider yapabilir:';
  }

  @override
  String get chatStepAppToken => 'Uygulama düzeyinde bir jeton oluştur';

  @override
  String get chatStepInstall => 'Uygulamayı yükle';

  @override
  String get chatOpenAppSettings => 'Uygulama ayarlarını aç';

  @override
  String get chatContinueToCredentials => 'Kimlik bilgilerini yapıştır';

  @override
  String chatBotUpdated(String provider) {
    return 'Bot $provider içinde güncellendi.';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return '$provider uygulamanın izinlerini değiştirdi. Etkili olması için uygulamayı yeniden yükle.';
  }

  @override
  String get chatReinstallApp => 'Uygulamayı yeniden yükle';

  @override
  String chatIconNotEditable(String provider) {
    return 'Botun simgesi yalnızca $provider uygulamasının kendi ayarlarında değiştirilebilir.';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return 'Bunu $provider içinde kendin de oluşturabilirsin — jeton gerekmez. Yukarıdaki ayarlar bağlantıyla birlikte gider.';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return '$provider içinde oluştur';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return '$provider, bu yapılandırma önceden doldurulmuş olarak tarayıcında açıldı. Uygulamayı orada oluştur, ardından bu adımları tamamla ve jetonlarla geri dön.';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return '$provider hangi uygulamayı oluşturduğunu bildirmiyor, bu yüzden botu buradan özelleştirmek için daha sonra bir uygulama yapılandırma jetonu gerekir.';
  }

  @override
  String get chatStepCreateApp =>
      'Önceden doldurulmuş yapılandırmadan uygulamayı oluştur';

  @override
  String chatStepCreateAppHint(String provider) {
    return '$provider içinde bir çalışma alanı seç ve onayla.';
  }

  @override
  String get chatStepAppTokenHint =>
      'Basic information → app-level tokens, connections:write kapsamıyla.';

  @override
  String get chatStepInstallHint =>
      'Install app → bot user OAuth token\'ı kopyala.';

  @override
  String get calendarUseBuiltinApp =>
      'Control Center\'ın Google uygulamasını kullan';

  @override
  String get calendarUseBuiltinAppHint =>
      'Google hesabınla onayla. Google Cloud\'da kurulum yok.';

  @override
  String get calendarUseOwnClient => 'Kendi Google Cloud istemcimi kullan';

  @override
  String get calendarUseOwnClientHint =>
      'Kendi Google Cloud projenindeki bir OAuth istemcisini gir.';

  @override
  String get aboutTitle => 'Hakkında';

  @override
  String get aboutAppVersion => 'Uygulama sürümü';

  @override
  String get aboutServerVersion => 'Bağlı sunucu';

  @override
  String get aboutRpcCatalog => 'RPC kataloğu';

  @override
  String get aboutServerUnknown => 'Bildirilmedi';

  @override
  String get serverStaleTitle => 'Paketlenmiş sunucu bu uygulamadan daha eski';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return 'Çalışan cc_server $serverVersion sürümünde, bu uygulama $appVersion. En son paketlenmiş sunucu derlemesini alması için uygulamayı yeniden başlat; geliştirmede apps/cc_server içinde `dart build cli` ile yeniden derle.';
  }

  @override
  String get updateCheckButton => 'Güncellemeleri denetle';

  @override
  String get updateChecking => 'Güncellemeler denetleniyor…';

  @override
  String get updateUpToDate => 'Güncelsin';

  @override
  String get updateDeferredBusy =>
      'Güncelleme hazır ama bir toplantı kaydediliyor — kayıt bitince sorulacak.';

  @override
  String get updateOpenedReleasesPage =>
      'Sürümler sayfası tarayıcınızda açıldı.';

  @override
  String get updateCheckFailed => 'Güncelleme denetimi başarısız';

  @override
  String updateAvailableVersion(String version) {
    return '$version sürümü mevcut.';
  }

  @override
  String get updateBannerTitle => 'Yeni bir Control Center mevcut';

  @override
  String get updateBannerRefresh => 'Yenile';

  @override
  String get updateBlockedRecording =>
      'Toplantı kaydı sırasında yenileme duraklatıldı — kayıt bitince yeniden yüklenecek.';

  @override
  String get settingsScopeYou => 'Siz';

  @override
  String get settingsScopeWorkspace => 'Çalışma alanı';

  @override
  String get settingsScopeServer => 'Sunucu';

  @override
  String get settingsProfile => 'Profil ve kimlik';

  @override
  String get settingsYourDevices => 'Cihazlarınız';

  @override
  String get settingsWorkspaceGeneral => 'Genel';

  @override
  String get settingsServerConnection => 'Bağlantı ve durum';

  @override
  String get settingsModelProviders => 'Model sağlayıcıları';

  @override
  String get settingsVoiceModels => 'Ses ve toplantı modelleri';

  @override
  String get settingsDiagnostics => 'Tanılama ve gizlilik';

  @override
  String get settingsAbout => 'Hakkında';

  @override
  String get settingsScopeBadgeYou => 'SİZ';

  @override
  String get settingsScopeBadgeDevice => 'BU CİHAZ';

  @override
  String get settingsScopeBadgeWorkspace => 'ÇALIŞMA ALANI';

  @override
  String get settingsScopeBadgeServer => 'SUNUCU';

  @override
  String get settingsProfileDescription =>
      'Adınız, e-postanız ve sizin adınıza yapılan commit’lere damgalanan git kimliği.';

  @override
  String get settingsServerConnectionDescription =>
      'Bu istemcinin konuştuğu sunucu ve bu sunucunun nasıl paylaşıldığı (mDNS, tüneller, röle).';

  @override
  String get settingsAboutDescription => 'Derleme kimliği ve güncellemeler.';

  @override
  String get settingsDiagnosticsDescription =>
      'Bu kurulum için yalıtım, dizinleme, eşitleme, günlükleme ve çökme raporlama.';

  @override
  String get settingsWorkspaceGeneralDescription =>
      'Bu çalışma alanındaki herkesin paylaştığı kimlik, ilke ve kurallar.';

  @override
  String get settingsWorkspacePolicyLabel => 'Çalışma alanı ilkesi';

  @override
  String get settingsWorkspacePolicyDescription =>
      'Bu çalışma alanındaki her üyeye ve her ajana uygulanır.';

  @override
  String get settingsSecretGlobsLabel => 'Gizli yol dışlamaları';

  @override
  String get settingsSecretGlobsHelp =>
      'Satır başına bir glob. Kod içeren yüzeylerde bu yollar, yerleşik varsayılanlara ek olarak görüntüleyenlerden ve konuklardan gizlenir.';

  @override
  String get settingsReviewConcurrencyLabel => 'İnceleme yayılımı';

  @override
  String get settingsReviewConcurrencyHelp =>
      'Açık bir sayı verilmediğinde kaç incelemenin paralel başlatılacağı.';

  @override
  String get settingsReviewLevelLabel => 'İnceleme düzeyi';

  @override
  String get settingsReviewLevelHelp =>
      'Yapay zeka incelemesinin ne kadar derin gideceği ve bulunanların ne kadarının baştan raporlanacağı. Hiçbir şey atılmaz — daha hafif bir düzey küçük bulguları silmek yerine gruplar.';

  @override
  String get reviewLevelLight => 'Hafif';

  @override
  String get reviewLevelBalanced => 'Dengeli';

  @override
  String get reviewLevelThorough => 'Kapsamlı';

  @override
  String get reviewLevelLightHint =>
      'Tek inceleyen. Yalnızca gerçekten önemli olanlar baştan raporlanır.';

  @override
  String get reviewLevelBalancedHint =>
      'QA, mimari ve uygulamayı kapsayan üç inceleyen.';

  @override
  String get reviewLevelThoroughHint =>
      'Güvenlik ve performans uzmanlarını ekler ve bulunan her şeyi raporlar.';

  @override
  String get askAiReviewAtLevel => 'Farklı bir düzeyde incele';

  @override
  String reviewNitpicksGroup(int count) {
    return 'İnce ayrıntılar ($count)';
  }

  @override
  String get reviewFindingResolve => 'Düzeltildi';

  @override
  String get reviewFindingResolveHint =>
      'Bu bulguyu düzeltilmiş olarak işaretle. İnceleme sayacına dahil edilmez.';

  @override
  String get reviewFindingDismiss => 'Yoksay';

  @override
  String get reviewFindingDismissHint =>
      'Gerçek bir sorun değil. İnceleyenler gelecekteki PR’larda bu kalıbı işaretlemeyi bırakır.';

  @override
  String get reviewFindingReopen => 'Yeniden aç';

  @override
  String get reviewFindingStatusUndoLabel => 'Bulgu durumu';

  @override
  String get reviewFindingDismissTitle => 'Bu bulguyu yoksay';

  @override
  String get reviewFindingDismissReasonHint =>
      'Neden geçerli değil? İnceleyenler bunu okuyacak.';

  @override
  String reviewFindingStatusFailed(String error) {
    return 'Bulgu güncellenemedi: $error';
  }

  @override
  String get reviewStaleTitle => 'Bu inceleme güncel değil';

  @override
  String get reviewStaleBody =>
      'Bu incelemeden sonra pull request ilerlemeye devam etti. Bulgular artık var olmayan koda işaret ediyor olabilir.';

  @override
  String reviewStaleReviewedAt(String sha) {
    return '$sha üzerinde incelendi';
  }

  @override
  String get reviewStaleRerun => 'Yeniden incele';

  @override
  String reviewStaleNotificationTitle(int prNumber) {
    return '#$prNumber incelemesi güncel değil';
  }

  @override
  String reviewStaleNotificationBody(String title) {
    return '$title, son incelemesinden beri yeni commit’ler içeriyor.';
  }

  @override
  String get reviewCategorySecurity => 'Güvenlik';

  @override
  String get reviewCategoryStability => 'Kararlılık';

  @override
  String get reviewCategoryDataIntegrity => 'Veri bütünlüğü';

  @override
  String get reviewCategoryCorrectness => 'Doğruluk';

  @override
  String get reviewCategoryPerformance => 'Performans';

  @override
  String get reviewCategoryMaintainability => 'Sürdürülebilirlik';

  @override
  String get reviewEffortQuickWin => 'Kolay kazanç';

  @override
  String get reviewEffortModerate => 'Orta';

  @override
  String get reviewEffortHeavyLift => 'Büyük iş';

  @override
  String get reviewProposedFix => 'Önerilen düzeltme';

  @override
  String get reviewAiAgentPrompt => 'AI ajanları için prompt';

  @override
  String get reviewCopyAiPrompt => 'Promptu kopyala';

  @override
  String get settingsWorkspaceAdminOnly =>
      'Bunları yalnızca çalışma alanı yöneticileri değiştirebilir.';

  @override
  String get chatMyAccountsTitle => 'Bağlı sohbet hesapları';

  @override
  String get settingsServerSso => 'Tek oturum açma';

  @override
  String get settingsServerSsoDescription =>
      'SAML ve OpenID Connect ile giriş ve kullanıcı sağlama';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabledDescription =>
      'Kullanıcılar bu sağlayıcıyla oturum açabilir';

  @override
  String get ssoEnabledDescriptionOn => 'Bu sağlayıcı için oturum açma etkin';

  @override
  String get ssoIdpMetadataLabel => 'IdP metadata XML';

  @override
  String get ssoIdpMetadataHint =>
      'IdP\'nin EntityDescriptor XML\'ini yapıştırın';

  @override
  String get ssoEmailAttributeLabel => 'E-posta özniteliği';

  @override
  String get ssoDisplayNameAttributeLabel => 'Görünen ad özniteliği';

  @override
  String get ssoGroupsAttributeLabel => 'Gruplar özniteliği';

  @override
  String get ssoIssuerLabel => 'Issuer URL';

  @override
  String get ssoClientIdLabel => 'Client ID';

  @override
  String get ssoGroupsClaimLabel => 'Gruplar claim';

  @override
  String get ssoAutoMemberLabel =>
      'Kullanıcıları ilk girişte her çalışma alanına ekle';

  @override
  String get ssoAutoMemberDescription =>
      'Her çalışma alanı için davet gerektirmek üzere kapatın';

  @override
  String get ssoAllowJitLabel => 'Bilinmeyen kullanıcıları ilk girişte sağla';

  @override
  String get ssoAllowJitDescription =>
      'Mevcut hesabı olmayan kullanıcıları reddetmek üzere kapatın';

  @override
  String get ssoAllowIdpInitiatedLabel =>
      'İstenmeyen (IdP başlatmalı) oturum açmayı kabul et';

  @override
  String get ssoAllowIdpInitiatedDescription =>
      'Yalnızca uygulamaları doğrudan başlatan IdP portalları için';

  @override
  String get ssoWantResponseSignedLabel => 'İmzalı yanıt zarfı zorunlu tut';

  @override
  String get ssoWantResponseSignedDescription =>
      'Assertion imzaları her zaman zorunludur';

  @override
  String get ssoTestConnectionButton => 'Bağlantıyı dene';

  @override
  String get ssoTestConnectionOk => 'Bağlantı çalışıyor:';

  @override
  String get ssoCopySpMetadata => 'SP metadata\'sını kopyala';

  @override
  String get ssoCopySpMetadataDone => 'SP metadata panoya kopyalandı';

  @override
  String get ssoSavedToast => 'Tek oturum açma ayarları kaydedildi';

  @override
  String get ssoUnavailable =>
      'Bu sunucu tek oturum açma ayarlarını sunmuyor. Sunucu ikilisini güncelleyip yeniden deneyin.';

  @override
  String get ssoScimCardTitle => 'Kullanıcı sağlama (SCIM)';

  @override
  String get ssoScimDescription =>
      'Kimlik sağlayıcınızın SCIM bağlayıcısını aşağıdaki uç noktaya bir bearer token ile yönlendirin. Sağlamayı kaldırma, oturumları ve çalışma alanı erişimini saniyeler içinde iptal eder. Sunucuya IdP tarafından erişilebilir olmalıdır (tünel veya herkese açık URL).';

  @override
  String get ssoScimEndpoint => 'SCIM uç noktası';

  @override
  String get ssoScimEndpointUnknownOrigin =>
      'Önce sunucunun herkese açık URL\'sini ayarlayın veya bir tünel etkinleştirin';

  @override
  String get ssoScimRegenerate => 'Tokeni yenile';

  @override
  String get ssoScimRegenerateConfirm =>
      'Yeni bir SCIM bearer token oluşturulsun mu? Önceki token hemen geçersiz olur.';

  @override
  String get ssoScimTokenTitle => 'Bearer token';

  @override
  String get ssoScimTokenPresent => 'Bir token yapılandırılmış';

  @override
  String get ssoScimTokenAbsent =>
      'Henüz token yok — SCIM\'i etkinleştirmek için bir tane oluşturun';

  @override
  String get ssoScimTokenOnce => 'SCIM tokeni (yalnızca bir kez gösterilir)';

  @override
  String ssoSignInWith(String provider) {
    return '$provider ile oturum aç';
  }

  @override
  String get ssoProbeFailed => 'Tek oturum açma için o sunucuya ulaşılamadı';

  @override
  String get ssoOpensBrowser =>
      'Oturum açmayı tamamlamak için tarayıcınızı açar';

  @override
  String get ssoWaitingForBrowser =>
      'Tarayıcınızın oturum açmayı tamamlaması bekleniyor…';

  @override
  String get ssoBrowserOpenFailed =>
      'Tek oturum açma için tarayıcınız açılamadı';

  @override
  String get ssoUseManualPairing =>
      'Bunun yerine davet veya eşleme anahtarıyla oturum aç';

  @override
  String get ssoHideManualPairing => 'Manuel eşlemeyi gizle';

  @override
  String get ssoClientIdHint => 'Herkese açık (PKCE) istemci — secret gerekmez';

  @override
  String get ssoClientSecretLabel => 'Client secret (isteğe bağlı)';

  @override
  String get ssoClientSecretHintUnset =>
      'Yalnızca gizli IdP istemcileri için gerekir';

  @override
  String get ssoClientSecretHintSet =>
      'Bir secret kayıtlı — korumak için boş bırakın';

  @override
  String get ssoPairingToggle =>
      'Elle eşleştirmeye izin ver (davet kodları ve eşleştirme anahtarları)';

  @override
  String get ssoPairingToggleDescription =>
      'Kapatırsanız katılım yalnızca tek oturum açma ile olur — yeni cihazlar SSO girişleriyle gelir; mevcut cihazlar çalışmaya devam eder';

  @override
  String get ssoPairConfirmTitle => 'Sunucuya bağlanılsın mı?';

  @override
  String ssoPairConfirmBody(String server) {
    return '$server için bir oturum açma kimliği geldi, ancak bu uygulamadan bir oturum açma başlatılmadı. Bu sunucuya bağlanılsın mı?';
  }

  @override
  String get ssoPairConfirmConnect => 'Bağlan';

  @override
  String get ssoPairConfirmCancel => 'Yoksay';

  @override
  String get forgeConnections => 'Kod barındırma';

  @override
  String get connect => 'Bağlan';

  @override
  String get disconnect => 'Bağlantıyı kes';

  @override
  String get notConnected => 'Bağlı değil';

  @override
  String get checkingConnection => 'Bağlantı denetleniyor…';

  @override
  String get fromEnvironment => 'ortamdan';

  @override
  String forgeTokenTitle(String forge) {
    return '$forge token';
  }

  @override
  String get settingsAudio => 'Ses';

  @override
  String get settingsAudioDescription =>
      'Mikrofon, dikte, toplantı algılama ve ses manzarası çıkışı.';

  @override
  String get audioDevicesSection => 'Ses aygıtları';

  @override
  String get voiceInputBehaviorSection => 'Dikte ve toplantılar';

  @override
  String get audioOutputDeviceTitle => 'Çıkış aygıtı';

  @override
  String get audioOutputDefaultHint =>
      'Uygulamanın tüm sesi sistem varsayılan çıkışından çalar.';

  @override
  String get audioOutputGone =>
      'Seçili çıkış aygıtı artık bağlı değil — başka birini seçene dek sistem varsayılanı kullanılır.';

  @override
  String get reviewHubIntroBody =>
      'Ajanlar diff’i analiz eder, değişiklik alanlarını haritalar ve ortak bir karara varır.';

  @override
  String get reviewHubAlreadyRunning =>
      'Bu pull request için zaten bir inceleme çalışıyor';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return 'Son incelemeden beri: $resolved çözüldü · $added yeni · $open hâlâ açık';
  }

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return 'Önceki inceleme: $sha';
  }

  @override
  String reviewArtifactFixAll(int count) {
    return '$count bulguyu düzelt';
  }

  @override
  String reviewArtifactFixSelected(int count) {
    return '$count seçiliyi düzelt';
  }

  @override
  String reviewArtifactCommentSelected(int count) {
    return '$count seçiliye yorum yap';
  }

  @override
  String get webConnectTitle => 'Control Center’a bağlan';

  @override
  String get webConnectSubtitle =>
      'Çalışan bir cc-server’a WebSocket üzerinden bağlanın. Anahtarınız bu cihazda kalır.';

  @override
  String get webConnectServerLabel => 'Sunucu';

  @override
  String get webConnectDeviceIdLabel => 'Cihaz kimliği';

  @override
  String get webConnectPairingKeyLabel => 'Eşleştirme anahtarı';

  @override
  String get webConnectPairingKeyHint => 'PSK’yı yapıştırın';

  @override
  String get webConnectStayConnected => 'Bu cihazda bağlı kal';

  @override
  String get webConnectStayConnectedDetail =>
      'Bu cihazda bağlı kal (anahtarınız bu tarayıcıda saklanır)';

  @override
  String failedToCreateWorkspace(String error) {
    return 'Çalışma alanı oluşturulamadı: $error';
  }

  @override
  String committedRelative(String relative) {
    return '$relative commit edildi';
  }

  @override
  String get selectAgents => 'Ajanları seç';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ajan',
      one: '1 ajan',
    );
    return '$_temp0';
  }

  @override
  String get newConversation => 'Yeni sohbet';

  @override
  String get untitledConversation => 'Adsız sohbet';

  @override
  String get conversationTitleOptionalHint =>
      'İsteğe bağlı — boş bırakırsanız başlık modeli otomatik adlandırır';

  @override
  String get conversationTitlesSectionTitle => 'Sohbet başlıkları';

  @override
  String get conversationTitlesSectionCaption =>
      'Bu çalışma alanında yeni sohbetleri otomatik adlandıran runner’ı seçin. Başlıklar bir adapter seçilene dek kapalı kalır ve tüm üyelere uygulanır.';

  @override
  String get conversationTitlesModelLabel => 'Başlık modeli';

  @override
  String get conversationTitlesAdapterLabel => 'Adapter';

  @override
  String get conversationTitlesAdapterHint => 'Kapalı';

  @override
  String get conversationTitlesAdapterOff => 'Kapalı';

  @override
  String get startThread => 'Konu başlat';

  @override
  String get deleteSpaceConfirm =>
      'Bu alan silinsin mi? Tüm iletiler kaybolacak.';

  @override
  String threadTabTitle(String title) {
    return 'Konu: $title';
  }

  @override
  String threadReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yanıt',
      one: '1 yanıt',
    );
    return '$_temp0';
  }

  @override
  String threadLastReply(String time) {
    return 'Son yanıt $time';
  }

  @override
  String signInWithProvider(String provider) {
    return '$provider ile oturum aç';
  }

  @override
  String get signInAgain => 'Yeniden oturum aç';

  @override
  String get signInNotFinished =>
      'Oturum açma henüz dönmedi. Tarayıcınızda tamamlayın, sonra yeniden denetleyin.';

  @override
  String get signedOutTitle => 'Oturumunuz kapatıldı';

  @override
  String get signedOutSubtitle =>
      'Kod barındırma bağlantınız artık geçerli değil — bir token’ın süresi doldu veya erişimi iptal edildi. Başka bir şey değişmedi: yeniden oturum açın, her şey kaldığı yerde.';

  @override
  String get viaServerApp => 'bu sunucunun uygulaması üzerinden';

  @override
  String get ticketing => 'Biletler';

  @override
  String get ticketingProviderHelp =>
      'Biletlerinizin tutulduğu yer. Yerel, bunları Control Center’da tutar.';

  @override
  String providerComingSoon(String provider) {
    return '$provider (yakında)';
  }

  @override
  String get ticketProviderLocal => 'Yerel';

  @override
  String get addKey => 'Anahtar ekle';

  @override
  String get providerApps => 'Sağlayıcı uygulamaları';

  @override
  String get providerAppsDescription =>
      'Bu sunucunun kendisi olarak nasıl kimlik doğruladığı ve kişilerin nereden oturum açtığı. Arka plan işleri — webhook’lar, yoklama, senkronizasyon — uygulamada çalışır, kişinin token’ında değil.';

  @override
  String get providerAppId => 'Uygulama id';

  @override
  String get providerPrivateKey => 'Özel anahtar';

  @override
  String get providerClientId => 'İstemci id';

  @override
  String get providerClientSecret => 'İstemci gizli anahtarı';

  @override
  String get providerApiKey => 'API anahtarı';

  @override
  String get providerCallbackUrl => 'Geri çağırma URL’si';

  @override
  String get providerAppFullyConfigured =>
      'Sunucu kendisi olarak hareket edebilir ve kişiler oturum açabilir.';

  @override
  String get providerAppServerOnly =>
      'Sunucu kendisi olarak hareket edebilir. Kişilerin oturum açması için bir istemci id ve gizli anahtar ekleyin.';

  @override
  String get providerAppSignInOnly =>
      'Kişiler oturum açabilir. Arka plan işleri onların kimlik bilgilerine geri düşer.';

  @override
  String providerAppInstalledOn(String accounts) {
    return 'Kimlik bilgileri çalışıyor. Kurulu olduğu yer: $accounts';
  }

  @override
  String deviceCodeInstructions(String provider) {
    return 'Az önce açılan $provider sayfasına bu kodu girin. Panonuza kopyalandı.';
  }

  @override
  String get deviceCodeWaiting => 'Tarayıcıda işlemi tamamlamanız bekleniyor…';

  @override
  String get copyCodeAndOpen => 'Kodu kopyala ve aç';

  @override
  String get couldNotOpenBrowser =>
      'Tarayıcı açılamadı. Bağlantıyı kopyalayıp oturum açmayı kendiniz tamamlayın.';

  @override
  String get contextUsage => 'Bağlam kullanımı';

  @override
  String get contextUsageFull => 'dolu';

  @override
  String get contextUsageTokens => 'token';

  @override
  String get contextSeeMore => 'Daha fazlasını gör';

  @override
  String get contextSegmentSystemPrompt => 'Sistem prompt’u';

  @override
  String get contextSegmentRules => 'Kurallar';

  @override
  String get contextSegmentSkills => 'Beceriler';

  @override
  String get contextSegmentToolDefinitions => 'Araç tanımları';

  @override
  String get contextSegmentMcpTools => 'MCP ve dinamik araçlar';

  @override
  String get contextSegmentDeferredTools => 'İstek üzerine yüklenen araçlar';

  @override
  String get contextSegmentSubagents => 'Alt ajan tanımları';

  @override
  String get contextSegmentMemory => 'Bellek';

  @override
  String get contextSegmentConversation => 'Sohbet';

  @override
  String get contextExplorerTitle => 'Bağlam';

  @override
  String get contextExplorerEverything => 'Tümü';

  @override
  String get contextExplorerSelectPart =>
      'İçeriğini incelemek için bir bölüm seçin';

  @override
  String get contextExplorerUnavailable => 'Bağlam dökümü kullanılamıyor';

  @override
  String get contextRetry => 'Yeniden dene';

  @override
  String get settingsFieldOptional => 'İsteğe bağlı';

  @override
  String get settingsFilterHint => 'Bu listeyi filtrele';

  @override
  String get settingsValueNotAvailable => 'Henüz kullanılamıyor';

  @override
  String get settingsNoEntriesYet => 'Henüz bir şey yok';

  @override
  String get settingsChangedBadge => 'Değişti';

  @override
  String get ssoConnectionCardDescription =>
      'Kişilerin bu sunucuda nasıl oturum açacağını seçin, ardından o bağlantıyı açın.';

  @override
  String get ssoUseSamlForSignIn => 'Oturum açmak için SAML kullan';

  @override
  String get ssoUseOidcForSignIn => 'Oturum açmak için OpenID Connect kullan';

  @override
  String get ssoSaveConnection => 'Bağlantıyı kaydet';

  @override
  String get ssoStateLive => 'Canlı';

  @override
  String get ssoStateConfiguredOff => 'Yapılandırıldı, kapalı';

  @override
  String get ssoStateOnIncomplete => 'Açık, eksik';

  @override
  String get ssoStateActive => 'Etkin';

  @override
  String get ssoStateAllowed => 'İzinli';

  @override
  String get ssoStateNoToken => 'Token yok';

  @override
  String get ssoSummaryDirectorySync => 'Dizin senkronizasyonu';

  @override
  String get ssoSummaryManualPairing => 'Manuel eşleme';

  @override
  String get ssoNoMethodLiveNote =>
      'Canlı bir oturum açma yöntemi yok. Bir bağlantı yapılandırıp açana kadar yeni cihazlar davet veya eşleme anahtarıyla katılır.';

  @override
  String get ssoMethodSamlBlurb =>
      'Okta, Entra ID veya Google Workspace gibi SAML 2.0 kullanan kimlik sağlayıcıları için.';

  @override
  String get ssoMethodOidcBlurb =>
      'OpenID Connect kullanan kimlik sağlayıcıları için. Genellikle ikisi arasında kurulumu daha basit olanı.';

  @override
  String get ssoGroupIdentityProvider => 'Kimlik sağlayıcı';

  @override
  String get ssoGroupIdentityProviderSamlDescription =>
      'Assertion\'ların nereden geldiği ve bu sunucunun bunları nasıl doğruladığı.';

  @override
  String get ssoGroupIdentityProviderOidcDescription =>
      'Bu sunucunun güvendiği issuer ve kimlik doğrulaması yaptığı istemci.';

  @override
  String get ssoSpEntityIdShortLabel => 'SP entity ID';

  @override
  String get ssoSpEntityIdDescription =>
      'Sunucu URL\'sinden türetilmesi için boş bırakın.';

  @override
  String get ssoIssuerDescription =>
      'Sağlayıcının discovery belgesini sunan temel URL.';

  @override
  String get ssoSecretStored => 'Saklandı';

  @override
  String get ssoGroupHandoff => 'Kimlik sağlayıcınızın ihtiyaç duydukları';

  @override
  String get ssoGroupHandoffDescription =>
      'Bunları sağlayıcınızda oluşturduğunuz uygulamaya yapıştırın.';

  @override
  String get ssoOriginUnknownTitle =>
      'Bu sunucu herkese açık URL\'sini bilmiyor';

  @override
  String get ssoOriginUnknownBody =>
      'Oturum açma ve geri çağırma URL\'leri bundan oluşturulur; biri ayarlanana kadar sağlayıcınız bu sunucuya ulaşamaz. Herkese açık bir URL ekleyin veya Sunucu → Bağlantı altında bir tünel etkinleştirin.';

  @override
  String get ssoAcsUrlLabel => 'Assertion consumer service (ACS) URL\'si';

  @override
  String get ssoAcsUrlDescription =>
      'Sağlayıcınızın imzalı assertion\'ı gönderdiği adres.';

  @override
  String get ssoSpEntityIdResolvedLabel => 'Hizmet sağlayıcı entity ID';

  @override
  String get ssoMetadataUrlLabel => 'SP metadata URL\'si';

  @override
  String get ssoMetadataUrlDescription =>
      'Metadata içe aktaran sağlayıcılar bunu buradan da alabilir.';

  @override
  String get ssoRedirectUriLabel => 'Yönlendirme URI\'si';

  @override
  String get ssoRedirectUriDescription =>
      'Bunu sağlayıcınızın uygulamasındaki izin verilen yönlendirme URI\'lerine ekleyin.';

  @override
  String get ssoSignInUrlLabel => 'Oturum açma URL\'si';

  @override
  String get ssoSignInUrlDescription =>
      'Tek oturum açmayı başlatmak için kişileri buraya yönlendirin.';

  @override
  String get ssoGroupAttributeMapping => 'Öznitelik eşlemesi';

  @override
  String get ssoGroupAttributeMappingDescription =>
      'Her alanı hangi claim\'in taşıdığı. Sağlayıcınız adlarını değiştirmediyse varsayılanları koruyun.';

  @override
  String get ssoGroupAccess => 'Erişim ve roller';

  @override
  String get ssoGroupAccessDescription =>
      'Başarıyla oturum açan birinin neler yapabileceği.';

  @override
  String get ssoDefaultRoleShortLabel => 'Varsayılan rol';

  @override
  String get ssoDefaultRoleDescription =>
      'Aşağıdaki eşlemelerden hiçbiriyle eşleşmeyen herkese verilir.';

  @override
  String get ssoRoleMapShortLabel => 'Grup–rol eşlemesi';

  @override
  String get ssoRoleMapDescription =>
      'İlk eşleşen grup geçerli olur. Owner bu yolla verilemez.';

  @override
  String get ssoRoleMapGroupHint => 'Sağlayıcınızdaki grup adı';

  @override
  String get ssoRoleMapAdd => 'Eşleme ekle';

  @override
  String get ssoRoleMapEmpty => 'Eşleme yok — herkes varsayılan rolü alır.';

  @override
  String get ssoAdvancedSummary =>
      'Saat sapması, IdP başlatmalı oturum açma, imza politikası';

  @override
  String get ssoClockSkewShortLabel => 'Saat sapması';

  @override
  String get ssoClockSkewDescription =>
      'Assertion zaman damgalarındaki tolerans, saniye cinsinden. Çoğu sağlayıcı için 90 yeterlidir.';

  @override
  String get ssoScimGenerate => 'Token oluştur';

  @override
  String get ssoScimTokenOnceBody =>
      'Panoya kopyalandı. Yalnızca bir kez gösterilir ve geri alınamaz; şimdi sağlayıcınıza yapıştırın.';

  @override
  String get ssoPairingCardTitle => 'Manuel eşleştirme';

  @override
  String get ssoPairingCardDescription =>
      'Bu sunucuya diğer giriş yolu: davet kodları ve eşleştirme anahtarları — tek oturum açmadan geçmeyen cihazlar için.';

  @override
  String settingsCountOfTotal(int count, int total) {
    return '$count / $total';
  }

  @override
  String get providersNoneConnectedNote =>
      'Bağlı sağlayıcı yok, bu yüzden yerleşik ajan çalışma zamanının üzerinde çalışacak bir şey yok. Bir API anahtarı ekleyin veya aşağıdakilerden birine oturum açın.';

  @override
  String get providersFilterHint => 'Sağlayıcıları filtrele';

  @override
  String get providersNoneMatch => 'Bu filtreyle eşleşen yok';

  @override
  String get providerDeniedHereTitle => 'Bu çalışma alanında reddedildi';

  @override
  String get providerDeniedHereBody =>
      'Bağlı olsa da buradaki ajanlar bu sağlayıcıyı kullanamaz. Diğer çalışma alanları etkilenmez.';

  @override
  String get providerNeedsSignIn => 'Bu sağlayıcıyı kullanmak için oturum açın';

  @override
  String get providerNeedsApiKey =>
      'Bu sağlayıcıyı kullanmak için bir API anahtarı ekleyin';

  @override
  String get providerApiKeyLabel => 'API anahtarı';

  @override
  String get providerGenerationDefaults => 'Sağlayıcı varsayılanları';

  @override
  String get providerNoModelsYet =>
      'Henüz model bildirilmedi. Sağlayıcıyı bağlayın, ardından senkronize edin.';

  @override
  String get providerModelsFilterHint => 'Modelleri filtrele';

  @override
  String get adaptersNoneReadyNote =>
      'Katalogdaki runner CLI\'larından hiçbiri bu makinede bulunamadı. Birini yükleyin, ardından yenileyin.';

  @override
  String get adaptersFilterHint => 'Runner\'ları filtrele';

  @override
  String get adaptersLaunchGroup => 'Başlatma';

  @override
  String get adaptersLaunchGroupDescription =>
      'Bir ajan bu runner\'ı başlattığında verilenler. İsterseniz CLI\'yı yüklemeden önce bunları ayarlayın.';

  @override
  String get adaptersEnvNone => 'Hiçbiri ayarlı değil';

  @override
  String adaptersEnvCount(int count) {
    return '$count ayarlı';
  }

  @override
  String get adapterArgumentsDescription =>
      'Her başlatmada runner\'ın komut satırına eklenir.';

  @override
  String get defaultChatDescription =>
      'Yeni konuşmaları ve kendi çalıştırıcısı olmayan her ajanı çalıştırır.';

  @override
  String get shortTaskDescription =>
      'Başlık ve özet gibi hızlı arka plan işlerini çalıştırır. Daha küçük bir model buraya aittir.';

  @override
  String get settingsStateFailed => 'Başarısız';

  @override
  String get providerAppsGroupServer => 'Sunucu olarak hareket etme';

  @override
  String get providerAppsGroupServerDescription =>
      'Arka plan işlerinin, isteğin arkasında bir insan olmadan depolara ulaşmasını sağlar: webhook\'lar, pull request yoklaması, bilet senkronizasyonu.';

  @override
  String get providerAppsGroupPrConversations => 'Pull request konuşmaları';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      'Geliştiricilerin GitHub üzerinde bu sunucuyla doğrudan nasıl konuşabileceği. Webhook veya genel URL olmadan çalışır — sunucu yoklama yapar.';

  @override
  String get providerAppBotLogin => 'Bot girişi';

  @override
  String get providerAppBotLoginEmpty =>
      'Bot girişini çözümlemek için bağlantıyı test edin.';

  @override
  String get providerAppAskOnGitHub => 'GitHub\'da sorma';

  @override
  String get providerAppAskOnGitHubHint =>
      'İnceleme istemek veya soru sormak, inceleme dizilerine yanıt vermek ya da inceleme istemek için `ai-review` etiketini eklemek üzere, yukarıdaki bot girişini bir pull request yorumunda anın — [bot] soneki isteğe bağlıdır.';

  @override
  String get providerAppsGroupSignIn => 'Kişileri oturum açtırma';

  @override
  String get providerAppsGroupSignInDescription =>
      'Her üyenin kendi hesabını bağlamasını ve kendi kimlik bilgisini almasını sağlar.';

  @override
  String get providerAppCapActsAsServer => 'Sunucu olarak hareket eder';

  @override
  String get providerAppCapSignsIn => 'Kişileri oturum açtırır';

  @override
  String get portLabel => 'Port';

  @override
  String get mcpNoTokenWarning =>
      'Token olmadan, bu porta ulaşabilen her şey tüm araçları çağırabilir.';

  @override
  String get mcpBridgedToolsLabel => 'Araçlar';

  @override
  String get guardrailFamilyFiles => 'Dosyalar';

  @override
  String get guardrailFamilyGit => 'Git ve pull request\'ler';

  @override
  String get guardrailFamilyMachine => 'Makine ve ağ';

  @override
  String get guardrailFamilyControl => 'Gizli bilgiler ve çalışma alanı';

  @override
  String get guardrailScopeFieldLabel => 'Kuralların düzenlendiği yer';

  @override
  String get guardrailScopeFieldDescription =>
      'Daha dar bir kapsam, daha geniş olana üstün gelir. Burada ayarlanan kurallar, devralınanların üzerine uygulanır.';

  @override
  String get guardrailSetHere => 'Burada ayarla';

  @override
  String get guardrailClearAllHere => 'Tümünü temizle';

  @override
  String get sandboxingCardLabel => 'Korumalı alan';

  @override
  String get sandboxingCardDescription =>
      'Ajan işinin bu hosttan yalıtılmış çalışıp çalışmadığı ve yalıtılmış bir ajanın hâlâ neler erişebildiği.';

  @override
  String get sandboxBackendNoneActive => 'Host, yalıtım yok';

  @override
  String get sandboxSummaryHost => 'Host';

  @override
  String get sandboxGroupIsolation => 'Yalıtım';

  @override
  String get sandboxGroupIsolationDescription =>
      'Bir ajanın süreçlerinin ve dosya yazmalarının gerçekte nerede gerçekleştiği.';

  @override
  String get sandboxBackendFieldDescription =>
      'Bu hostun desteklediği en güçlüsünü otomatik seçer. Değişmesini önlemek için birini sabitleyin.';

  @override
  String get sandboxCapabilitiesDescription =>
      'Sınırda açılan delikler. Her biri, yalıtılmış bir ajanın dış dünyaya hâlâ yapabildiği bir şeydir.';

  @override
  String get sandboxSummaryInForce => 'Yürürlükte';

  @override
  String get rigsInstallHintLabel => 'Nasıl kurulur';

  @override
  String get rigsStarting => 'Başlatılıyor';

  @override
  String get rigsResidentMemory => 'Yerleşik bellek';

  @override
  String get installedLabel => 'Kurulu';

  @override
  String get notInstalledLabel => 'Kurulu değil';

  @override
  String ssoOtherKindUnsaved(String method) {
    return '$method kaydedilmemiş değişiklikler içeriyor';
  }

  @override
  String get collapseComment => 'Yorumu daralt';

  @override
  String get expandComment => 'Yorumu genişlet';

  @override
  String get suggestedChange => 'Önerilen değişiklik';

  @override
  String get emptyComment => 'Boş yorum';

  @override
  String repliesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yanıt',
      one: '1 yanıt',
    );
    return '$_temp0';
  }

  @override
  String get pendingReview => 'İnceleme bekliyor';

  @override
  String failedToResolveConversation(String error) {
    return 'Konuşma güncellenemedi: $error';
  }

  @override
  String get addSingleComment => 'Tek yorum ekle';

  @override
  String get addToReview => 'İncelemeye ekle';

  @override
  String get startAReview => 'İnceleme başlat';

  @override
  String get reviewNeedsABody =>
      'Önce bir özet yazın veya satır içi bir yorum kuyruğa alın';

  @override
  String get reviewSubmitted => 'İnceleme gönderildi';

  @override
  String get finishYourReview => 'İncelemenizi bitirin';

  @override
  String get commentVerdict => 'Yorum';

  @override
  String pendingCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bekleyen yorum',
      one: '1 bekleyen yorum',
    );
    return '$_temp0';
  }

  @override
  String andNMore(int count) {
    return 've $count tane daha';
  }

  @override
  String get queuedCommentHint =>
      'Bu yorum, incelemenizi gönderdiğinizde çıkar.';

  @override
  String commentOnLinesRange(int start, int end) {
    return 'Satır $start–$end';
  }

  @override
  String get claudeAccountsTitle => 'Claude Code hesapları';

  @override
  String get claudeAccountsDescription =>
      'Her hesap ayrı bir Claude Code oturumudur. Çalıştırmalar aşağıdaki bağlı hesapları bu sırayla kullanır.';

  @override
  String get claudeAccountsEmpty => 'Henüz hesap yok';

  @override
  String get claudeAccountAdd => 'Hesap ekle';

  @override
  String get claudeAccountSignIn => 'Oturum aç';

  @override
  String get claudeAccountSignInAgain => 'Yeniden oturum aç';

  @override
  String get claudeAccountSignInHint =>
      'Bunu sunucudaki bir terminalde çalıştırın. Oturumu tamamlamak için bir tarayıcı açar ve kimlik bilgisini bu hesabın dizinine yazar.';

  @override
  String get claudeAccountSignedOut => 'Oturum kapatıldı';

  @override
  String get claudeAccountExpired => 'Oturum süresi doldu';

  @override
  String claudeAccountExpiredDetail(String when) {
    return 'Oturum $when tarihinde doldu. Bu hesabı kullanmak için yeniden oturum açın.';
  }

  @override
  String get claudeAccountMakeDefault => 'Varsayılan yap';

  @override
  String get claudeAccountDefault => 'Varsayılan';

  @override
  String claudeAccountRemoveConfirm(String label) {
    return '$label kaldırılsın mı?';
  }

  @override
  String get claudeAccountRemoveDetail =>
      'Bu, hesabın oturumunu kapatır ve sunucudaki dizinini siler. Girişin kendisi etkilenmez.';

  @override
  String claudeAccountStatusUnknown(String error) {
    return 'Bu hesap denetlenemedi: $error';
  }

  @override
  String claudeAccountUsedPercent(String percent) {
    return '%$percent kullanıldı';
  }

  @override
  String get accountPoolStrategy => 'Döndürme';

  @override
  String get accountPoolPinned => 'Sabitlenmiş';

  @override
  String get accountPoolRoundRobin => 'Sıralı döngü';

  @override
  String get accountPoolSerial => 'Tek tek';

  @override
  String get accountPoolPinnedHint =>
      'Her zaman ilk hesapla başla. Diğerleri, bu hesap başarısız olursa yedek olarak kalır.';

  @override
  String get accountPoolRoundRobinHint =>
      'Çalıştırmaları hesaplara yay, her gönderimde bir sonrakine geç.';

  @override
  String get accountPoolSerialHint =>
      'Sonrakine geçmeden önce ilk hesabı tüket.';

  @override
  String get accountPoolMoveUp => 'Yukarı taşı';

  @override
  String get accountPoolMoveDown => 'Aşağı taşı';

  @override
  String get accountPoolUsingAll =>
      'Henüz hiçbir şey bağlı değil — tüm hesaplar bu sırayla kullanılır.';

  @override
  String get accountPoolInheriting =>
      'Çalışma alanının hesapları devralınıyor.';

  @override
  String get accountPoolResetToWorkspace =>
      'Çalışma alanının hesaplarına sıfırla';

  @override
  String accountPoolCoolingOff(String when) {
    return '$when tarihine kadar kota yok';
  }

  @override
  String get accountPoolSignedOut => 'oturum kapalı';

  @override
  String get accountPoolExpired => 'oturum süresi doldu';

  @override
  String accountPoolLoadFailed(String error) {
    return 'Döndürme yüklenemedi: $error';
  }

  @override
  String get providerSignedInAccount => 'oturum açılmış hesap';

  @override
  String get agentAccountsTab => 'Hesaplar';

  @override
  String get agentClaudeAccountsNoticeTitle =>
      'Birden fazla Claude Code hesabı';

  @override
  String agentClaudeAccountsNoticeBody(int count) {
    return 'Bu çalıştırıcı, bu makinedeki $count Claude Code hesabından biri olarak oturum açar. Hangisini kullanacağınızı veya aralarında döndürmeyi Hesaplar sekmesinden seçin.';
  }

  @override
  String get agentAccountsDescription =>
      'Bu ajanın çalıştırmalarının kullanacağı hesaplar. Her blok çalışma alanının seçimini devralarak başlar.';

  @override
  String get agentAccountsNothingToRotate =>
      'Döndürülecek bir şey yok — önce ikinci bir hesap veya anahtar bağlayın.';

  @override
  String failedToPostReply(String error) {
    return 'Yanıt gönderilemedi: $error';
  }

  @override
  String commentOnLine(int line) {
    return 'Satır $line';
  }

  @override
  String get viewInDiff => 'Diff\'te görüntüle';

  @override
  String get subscriptionUsagePreviousAccount => 'Önceki hesap';

  @override
  String get subscriptionUsageNextAccount => 'Sonraki hesap';

  @override
  String inReplyTo(String path) {
    return '$path yanıtı olarak';
  }

  @override
  String get subscriptionUsageNoneReported =>
      'Bu hesap için kullanım bildirilmedi.';

  @override
  String get subscriptionUsageCredits => 'Krediler';

  @override
  String get reviewHubStaticRule => 'Statik kural';

  @override
  String get reviewHubStarted => 'İnceleme başladı';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return 'Bu pull request\'in eklediği bir satırda belirleyici bir kural ($rule) tarafından bulundu — bir inceleme ajanı tarafından değil.';
  }

  @override
  String get prReviewArtifactTab => 'PR incelemesi';

  @override
  String get prReviewRunning => 'Bu pull request inceleniyor…';

  @override
  String get prReviewStarting => 'İnceleme başlatılıyor…';

  @override
  String get prReviewStartingBody =>
      'Bu pull request\'in çalışma ağacı hazırlanıyor. İnceleyenler hazır olur olmaz başlar.';

  @override
  String get prReviewFailed => 'İnceleme başarısız oldu.';

  @override
  String get prReviewRerunning => 'Yeniden inceleniyor…';

  @override
  String get prReviewNoOpenFindings => 'Açık bulgu yok';

  @override
  String prReviewOpenFindings(int count) {
    return '$count açık bulgu';
  }

  @override
  String subscriptionUsageSpend(String used, String limit) {
    return '$used / $limit';
  }

  @override
  String reviewCommentsPosted(int posted, int skipped, int failed) {
    return 'Bot olarak $posted yorum gönderildi. $skipped atlandı (dosya çapası yok), $failed başarısız oldu.';
  }

  @override
  String reviewFindingsOutOfDiff(int count, String files) {
    return '$count bulgu, bu pull request\'in değiştirmediği kodu hedefliyor ($files). GitHub satır içi yorumları yalnızca diff üzerinde kabul eder.';
  }

  @override
  String get reviewRailReport => 'Rapor';

  @override
  String get reviewNoFindingsTitle => 'Henüz inceleme bulgusu yok';

  @override
  String get reviewNoFindingsHint =>
      'Ajanlar paylaştıkça bulgular burada görünür.';

  @override
  String reviewShowDismissed(int count) {
    return '$count yok sayılanı göster';
  }

  @override
  String reviewHideDismissed(int count) {
    return '$count yok sayılanı gizle';
  }

  @override
  String reviewDisagreementsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count inceleyici anlaşmazlığı tespit edildi',
      one: '1 inceleyici anlaşmazlığı tespit edildi',
    );
    return '$_temp0';
  }

  @override
  String get reviewFilterKind => 'Tür';

  @override
  String get reviewFilterStatus => 'Durum';

  @override
  String get reviewKindBug => 'Hata';

  @override
  String get reviewKindSuggestion => 'Öneri';

  @override
  String get reviewKindRecommendation => 'Tavsiye';

  @override
  String get reviewKindQuestion => 'Soru';

  @override
  String get reviewKindTicket => 'Bilet';

  @override
  String get archiveSpace => 'Çalışma alanını arşivle';

  @override
  String get archivedSpaces => 'Arşivlenmiş çalışma alanları';

  @override
  String get archivedSpacesEmpty => 'Arşivlenmiş çalışma alanı yok';

  @override
  String get restoreSpace => 'Geri yükle';

  @override
  String archivedWhen(String time) {
    return '$time arşivlendi';
  }

  @override
  String get deleteSpacePermanently => 'Kalıcı olarak sil';

  @override
  String get renameSpace => 'Çalışma alanını yeniden adlandır';

  @override
  String get renameConversation => 'Sohbeti yeniden adlandır';

  @override
  String get spaceActions => 'Alan işlemleri';

  @override
  String get conversationActions => 'Konuşma işlemleri';

  @override
  String get editSpaceRepos => 'Depoları düzenle';

  @override
  String get editSpaceReposTitle => 'Çalışma alanı depoları';

  @override
  String get editSpaceReposWarning =>
      'Depo eklemek onu bu çalışma alanına çıkarır; kaldırmak klasörünü siler.';

  @override
  String get agentSectionIdentity => 'Kimlik';

  @override
  String get agentSectionRuntime => 'Çalışma zamanı';

  @override
  String get agentSectionGuardrails => 'Korumalar';

  @override
  String orgChartReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bağlı kişi',
      one: '1 bağlı kişi',
    );
    return '$_temp0';
  }

  @override
  String get teamsFilterHint => 'Ekipleri filtrele…';

  @override
  String get teamsSummaryWithLeader => 'Lideri olan';

  @override
  String teamCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ekip',
      one: '1 ekip',
      zero: 'Ekip yok',
    );
    return '$_temp0';
  }

  @override
  String agentDeleteLongDescription(String name) {
    return '$name silindiğinde profili, beceri bağlantıları ve çalıştırma geçmişi kaldırılır. Bu işlem geri alınamaz.';
  }

  @override
  String get resetToDefault => 'Varsayılana sıfırla';

  @override
  String get newAgent => 'Yeni ajan';

  @override
  String get newSkill => 'Yeni beceri';

  @override
  String get zoomIn => 'Yakınlaştır';

  @override
  String get zoomOut => 'Uzaklaştır';

  @override
  String get resetZoom => 'Yakınlaştırmayı sıfırla';

  @override
  String get imageHostedOnGitHub => 'Görüntü GitHub\'da barındırılıyor';

  @override
  String get imageOpenExternally => 'Görüntü · dışarıda aç';

  @override
  String get memoryScopeAll => 'Tüm kapsamlar';

  @override
  String get memoryScopeWorkspace => 'Çalışma alanı genelinde';

  @override
  String get memoryScopeFilterLabel => 'Kapsama göre filtrele';

  @override
  String memoryScopeRepoTooltip(String repo) {
    return '$repo deposuyla sınırlı';
  }

  @override
  String get toolScreenshot => 'Ajandan ekran görüntüsü';

  @override
  String get toolImageUnavailable => 'Görüntü kullanılamıyor';

  @override
  String toolImagesUnavailable(int count) {
    return '$count görüntü kullanılamıyor';
  }

  @override
  String get shakeUnavailable => 'Sallama bu sunucuda kullanılamıyor';

  @override
  String get shakeNothing => 'Sallanacak bir şey yok — son turlar korumalı';

  @override
  String shakeDone(int tokens) {
    return 'Yaklaşık $tokens token serbest bırakıldı';
  }

  @override
  String get compactionDivider => 'Sıkıştırıldı';

  @override
  String compactionDividerCount(int count) {
    return 'Sıkıştırıldı · $count ileti katlandı';
  }

  @override
  String get composerDropToAttach => 'Eklemek için bırak';

  @override
  String get attachmentUnavailable => 'Ek kullanılamıyor';

  @override
  String get attachmentUnavailableDetail =>
      'Bu ek artık bellekte tutulmuyor. Önizlemek için yeniden ekleyin.';

  @override
  String get attachmentPreviewFailed => 'Bu dosya açılamadı';

  @override
  String get attachmentPreviewUnsupported => 'Bu dosya türü için önizleme yok';

  @override
  String get attachmentTooLargeToPreview => 'Önizlemek için çok büyük';

  @override
  String get attachmentOpenExternally => 'Varsayılan uygulamada aç';

  @override
  String get asideUnavailable =>
      'Bunu kullanmak için çalışma alanı ayarlarında tek seferlik bir model belirleyin';

  @override
  String get asideEmpty => 'Henüz üzerinde çalışılacak bir şey yok';

  @override
  String get asideFailed => 'Yanıt alınamadı';

  @override
  String get handoffTitle => 'Devir';

  @override
  String get asideTitle => 'Yan soru';

  @override
  String get attachFilesOrDrop => 'Dosya ekle — veya buraya bırak';

  @override
  String get guidedGoalTitle => 'Hedefi netleştir';

  @override
  String get guidedGoalIntro =>
      'Gözetimsiz çalışan bir ajanın tam olarak ne zaman bittiğini bilmesi gerekir. Önce birkaç soru.';

  @override
  String get guidedGoalAnswerHint => 'Yanıtınız';

  @override
  String get guidedGoalNext => 'İleri';

  @override
  String get guidedGoalStart => 'Hedefi başlat';

  @override
  String get guidedGoalSkip => 'Atla ve yazıldığı gibi çalıştır';

  @override
  String guidedGoalStillMissing(String items) {
    return 'Hâlâ belirtilmedi: $items';
  }

  @override
  String get conversationTreeTitle => 'Konuşma ağacı';

  @override
  String conversationTreeBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dal',
      one: '1 dal',
    );
    return '$_temp0';
  }

  @override
  String get conversationTreeSwitch => 'Buradan devam et';

  @override
  String get conversationTreeFork => 'Yeni bir konuşmaya çatalla';

  @override
  String get conversationTreeCurrent => 'Bu dalda';

  @override
  String get conversationTreeEmpty => 'Henüz bir şey yok';

  @override
  String get conversationTreeForked => 'Yeni bir konuşmaya çatallandı';

  @override
  String get conversationTreeSwitched => 'Artık o mesajdan devam ediliyor';

  @override
  String exportSaved(String path) {
    return '$path konumuna kaydedildi';
  }

  @override
  String get exportFailed => 'Dışa aktarma yazılamadı';

  @override
  String get contextCommandNoAgent =>
      'Bu konuşmada ajan yok, açılacak bir bağlam penceresi de yok';

  @override
  String contextCommandNoSuchAgent(String name, String names) {
    return 'Bu konuşmada “$name” adlı bir ajan yok. Dene: $names';
  }

  @override
  String get dumpCopied => 'Döküm panoya kopyalandı';

  @override
  String get messageQueueHint =>
      'İzleyen değişiklikleri kuyruğa almak için yazmaya devam et';

  @override
  String get steerNow => 'Yönlendir';

  @override
  String get steeringQueueLabel => 'Kuyruktaki yönlendirme mesajları';

  @override
  String get steeringDeliverUnavailable =>
      'Şu anda bunu alabilecek çalışan bir ajan yok — kuyrukta kalır.';

  @override
  String get reorderSteeringCard => 'Kuyruktaki mesajı yeniden sırala';

  @override
  String get editSteeringCard => 'Kuyruktaki mesajı düzenle';

  @override
  String get deleteSteeringCard => 'Kuyruktaki mesajı sil';

  @override
  String get steeringBadge => 'Yönlendirildi';

  @override
  String get settingsSandboxLabel => 'Sandbox';

  @override
  String get sandboxExecGrantsTitle => 'Çalıştırılabilir izinleri';

  @override
  String get sandboxExecGrantsSubtitle =>
      'Ajanların depolarınızın çalışma kopyasından çalıştırabileceği programlar. Her kayıt, Sandbox sorduğunda sizin tarafınızdan onaylandı.';

  @override
  String get sandboxExecGrantsEmpty =>
      'Henüz kayıtlı bir karar yok. Bir ajanın çalışma kopyasından bir program çalıştırması gerektiğinde ilk kez sorulacak.';

  @override
  String get sandboxExecGrantRevoke => 'Geri al';

  @override
  String get sandboxExecGrantAllowed => 'İzin verildi';

  @override
  String get sandboxExecGrantBlocked => 'Engellendi';

  @override
  String get sandboxExecGrantRevokeConfirmTitle => 'Bu karar geri alınsın mı?';

  @override
  String get sandboxExecGrantRevokeConfirmBody =>
      'Bir ajanın bu kopyadan bir program çalıştırması gerektiğinde yeniden sorulacak.';

  @override
  String get repoScriptsTest => 'Test';

  @override
  String get repoScriptsTestTooltip =>
      'Bu taslağı deponun geçici bir klonunda çalıştır';

  @override
  String get repoScriptsRunKindTest => 'Test';

  @override
  String get demoBadgeLabel => 'Demo';

  @override
  String get demoFilePickerTitle => 'Demo dosyaları';

  @override
  String get demoFilePickerBody =>
      'Demo yüklemeleri taklit eder: bunlardan istediğini seç, diske dokunmadan mesajına eklenir.';

  @override
  String get demoFilePickerAttach => 'Ekle';

  @override
  String get demoReadOnlySave => 'Demoda salt okunur';

  @override
  String get demoBadgeTooltip =>
      'Bir demoyu inceliyorsun. Veriler kurgusal, ajanlar da senaryolu.';

  @override
  String get demoFirstRunTitle => 'Canlı bir demosun';

  @override
  String demoFirstRunBody(int minutes) {
    return 'Bu, gerçek kod üzerinde çalışan gerçek uygulama — yalnızca veriler uydurma. Ajanlar bir senaryodan gerçek çalıştırmalar yayınlar; hiçbir şey bir modele gitmez, hiçbir şey bir makinede çalışmaz. Çalışma alanın yalnızca sana ait ve $minutes dakika sonra kaybolur.';
  }

  @override
  String get demoFirstRunDismiss => 'Anladım';

  @override
  String get demoTourTitle => 'Önce nereye bakmalı';

  @override
  String get demoTourSubtitle =>
      'Uygulamanın gerçekte ne yaptığını gösteren dört yer.';

  @override
  String get demoTourSkip => 'Atla';

  @override
  String get demoTourStarRepo => 'GitHub\'da yıldızla';

  @override
  String get demoTourOpen => 'Aç';

  @override
  String get demoTourSpacesTitle => 'Bir ajanla konuş';

  @override
  String get demoTourSpacesBody =>
      'Bir alanda mesaj gönderin ve bir çalıştırmanın akışını izleyin — düşünme, araç çağrıları ve maliyet, tam olarak gerçek bir çalıştırmanın gösterdiği gibi.';

  @override
  String get demoTourReviewTitle => 'Bir pull request inceleyin';

  @override
  String get demoTourReviewBody =>
      '#412’yi açın. Satır içi yorum bırakın veya bir inceleme gönderin; yazdıklarınız tartışmaya düşer ve orada kalır.';

  @override
  String get demoTourTicketsTitle => 'İşi takip edin';

  @override
  String get demoTourTicketsBody =>
      'Biletler, yapılacaklar ve planlar, ajanların yürüttüğü aynı konuşmalara bağlıdır.';

  @override
  String get demoTourInboxTitle => 'Operasyonun tamamını görün';

  @override
  String get demoTourInboxBody =>
      'Her sütundan gelen her uyarı tek bir gelen kutusuna düşer — incelemeler, biletler, çalıştırmalar ve toplantılar.';

  @override
  String get demoUnavailableTitle => 'Demoda kullanılamaz';

  @override
  String get demoUnavailableTerminal =>
      'Bir terminal, sunucu makinesinde gerçek bir shell çalıştırır. Demoda hiç yürütme yüzeyi yoktur — herkese açık tutulmasını güvenli kılan da budur.';

  @override
  String get demoUnavailableRig =>
      'Bir enclosure, bir ajanın sürdüğü tek kullanımlık bir sanal makinedir. Demo hiçbirini başlatmaz: VM açabilen herkese açık bir uç nokta demo değildir.';

  @override
  String get demoUnavailableEditor =>
      'Tarayıcı içi düzenleyici, gerçek bir checkout üzerinde bir code-server süreci çalıştırır. Demoda ikisi de yoktur.';

  @override
  String get demoUnavailableFeeds =>
      'Demo gerçek akışları okur, ancak abonelik listesi sabittir. Burada ekleme veya kaldırma kapalıdır.';

  @override
  String get demoUnavailableForge =>
      'Demo kimlik bilgisi tutmaz ve GitHub, GitLab veya Linear ile hiç iletişim kurmaz. Pull request’leri sabit örneklerdir; üzerlerindeki yorumlarınız yerel olarak saklanır.';

  @override
  String get demoUnavailableModels =>
      'Demo hiçbir model çağırmaz. Ajan çalıştırmaları senaryolu oynatmadır; bu yüzden maliyeti yoktur ve hiçbir sağlayıcıya ulaşmaz.';

  @override
  String get demoUnavailableMcp =>
      'MCP araç yüzeyi demoya bağlı değildir, bu yüzden hiçbir dış istemci ona bağlanamaz.';

  @override
  String get demoUnavailableRepos =>
      'Demo kod checkout etmez ve git çalıştırmaz. Gördüğünüz depo, pull request’lerin arkasındaki bir örnektir.';

  @override
  String get demoUnavailableSkills =>
      'Bir skill yüklemek kod indirir ve tarar. Demo hiçbir şey çekmez.';

  @override
  String get demoUnavailableSso =>
      'Tek oturum açma sunucu yapılandırmasıdır. Demo sizi bunun yerine geçici bir konuk olarak oturum açtırır.';

  @override
  String get demoUnavailableAudio =>
      'Kayıt ve dikte, ses yakalama ve ana makinede bir konuşma modeli ister. Demo ikisini de içermez; toplantıları oynatma olmadan yalnızca transkripttir.';

  @override
  String get demoUnavailableServerAdmin =>
      'Bu sunucu yönetimidir. Demo her ziyaretçiye kendi tek kullanımlık çalışma alanını verir, ötesinde bir şey vermez.';

  @override
  String get demoUnavailablePipelines =>
      'İş hatları burada çalıştırılamaz. Bir bash adımı yazıp — elle veya bir olay tetikleyicisiyle — başlatabilen bir ziyaretçi bu makinede kod çalıştırıyor demektir.';

  @override
  String get settingsBackupRestore => 'Yedekleme ve geri yükleme';

  @override
  String get settingsBackupRestoreDescription =>
      'Bu sunucudaki her veritabanının anlık görüntüleri; ayrıca tek bir çalışma alanı için dışa aktarma, içe aktarma ve silme.';

  @override
  String get backupSnapshotsLabel => 'Kurulum anlık görüntüleri';

  @override
  String get backupSnapshotsExplainer =>
      'Bir anlık görüntü her veritabanını sunucu makinesinde zaman damgalı bir klasöre kopyalar. Tüm kurulumu geri yüklemek, sunucu durdurulmuşken o klasörü geri kopyalamaktır; tek bir çalışma alanı buradan geri yüklenebilir.';

  @override
  String get backupNowAction => 'Şimdi yedekle';

  @override
  String backupSnapshotWritten(String path) {
    return 'Anlık görüntü $path konumuna yazıldı';
  }

  @override
  String get backupNoSnapshots =>
      'Henüz anlık görüntü yok. Yalnızca siz istediğinizde alınır — zamanlanmış bir iş yoktur.';

  @override
  String get backupSnapshotComplete => 'Tamamlandı';

  @override
  String get backupSnapshotIncomplete => 'Eksik';

  @override
  String get backupSnapshotIncompleteNote =>
      'Manifest eksik veya olmayan dosyaları adlandırıyor, bu yüzden bu anlık görüntü tüm kurulumu geri yükleyemez. Var olan çalışma alanı dosyaları yine de tek tek alınabilir.';

  @override
  String backupSnapshotWorkspaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count çalışma alanı',
      one: '1 çalışma alanı',
      zero: 'Çalışma alanı yok',
    );
    return '$_temp0';
  }

  @override
  String backupSnapshotSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count çalışma alanı yakalanmadı',
      one: '1 çalışma alanı yakalanmadı',
    );
    return '$_temp0';
  }

  @override
  String get backupServerPathLabel => 'Sunucudaki yol';

  @override
  String get backupRestoreAction => 'Geri yükle';

  @override
  String get backupRestoreTitle => 'Çalışma alanını geri yükle';

  @override
  String backupRestoreBody(String name) {
    return 'Bu, $name içindeki her şeyi bu anlık görüntüdeki kopyayla değiştirir. Anlık görüntü alındıktan sonra o çalışma alanında yapılan her şey kaybolur ve geri alınamaz.';
  }

  @override
  String backupRestoreDone(String name) {
    return '$name anlık görüntüden geri yüklendi.';
  }

  @override
  String get backupWorkspaceUnknown => 'Artık bu sunucuda yok';

  @override
  String get backupWorkspaceDataLabel => 'Çalışma alanı verisi';

  @override
  String get backupWorkspaceDataExplainer =>
      'Bir çalışma alanı bir veritabanı dosyasıdır; dışa aktarma tabloları tek tek dökmek yerine o dosyayı kopyalar. İçe aktarma, hedef çalışma alanındaki her şeyi adlandırdığınız dosyayla değiştirir.';

  @override
  String get backupExportAction => 'Dışa aktar';

  @override
  String backupExportDone(String path) {
    return '$path konumuna dışa aktarıldı';
  }

  @override
  String get backupExportedFileLabel => 'Sunucudaki dışa aktarılan dosya';

  @override
  String get backupImportAction => 'İçe aktar';

  @override
  String backupImportTitle(String name) {
    return '$name içine aktar';
  }

  @override
  String backupImportBody(String name) {
    return 'Bu, $name içindeki her şeyi dosyanın içeriğiyle değiştirir. Çalışma alanında şu an bulunan her şey kaybolur ve geri alınamaz.';
  }

  @override
  String get backupImportSourceLabel => 'Çalışma alanı veritabanı dosyası';

  @override
  String get backupImportSourceDescription =>
      'Sunucunun okuyabileceği bir .db dosyası. Yollar bu aygıtta değil, sunucu makinesinde çözülür.';

  @override
  String backupImportDone(String name) {
    return '$name içine aktarıldı.';
  }

  @override
  String backupDeleteBody(String name) {
    return '$name her listeden ve aramadan kaybolur. Veritabanı dosyası diskte kalır, yedekler onu hâlâ içerir ve alan otomatik olarak geri alınmaz.';
  }

  @override
  String get backupExportDescription =>
      'Sunucuya bir kopya yazın veya bu aygıta indirin.';

  @override
  String get backupExportOnServerAction => 'Sunucuya kaydet';

  @override
  String get backupDownloadAction => 'İndir';

  @override
  String backupDownloadSaved(String path) {
    return '$path konumuna kaydedildi';
  }

  @override
  String get backupDownloadInBrowser => 'Tarayıcınız indiriyor.';

  @override
  String get backupRestoreFromDeviceLabel => 'Bu aygıttan geri yükle';

  @override
  String get backupRestoreFromDeviceDescription =>
      'Buradan bir çalışma alanı veritabanı dosyası seçin; Control Center onu sunucuya yükler. Sunucu bu makine olmadığında işe yarayan yol budur.';

  @override
  String get backupUploadAction => 'Bir dosya seçin ve yükleyin';

  @override
  String get backupTransferUnavailable =>
      'Bu bağlantı sunucuya bir relay üzerinden ulaşıyor; dosya aktarımı taşımıyor. Yedek indirmek veya yüklemek için sunucuya doğrudan bağlanın.';

  @override
  String get backupTransferForbidden =>
      'Sunucu reddetti. Bir çalışma alanını indirmek için yönetici rolü, geri yüklemek için sahip, tüm bir anlık görüntü için kurulumun operatörü gerekir.';

  @override
  String get backupTransferUnsupported => 'Bu sunucuda yedekleme yüzeyi yok.';

  @override
  String get backupTransferTooLarge =>
      'Dosya, sunucunun kabul ettiğinden büyük.';

  @override
  String get credentialGateWaitingTitle => 'Kimlik bilgisi bekleniyor';

  @override
  String credentialGateHarnessTitle(String provider) {
    return '$provider için kimlik bilgisi yok';
  }

  @override
  String get credentialGateSignedOutTitle => 'Claude Code oturumu kapatılmış';

  @override
  String get credentialGateExpiredTitle =>
      'Claude Code oturumunuzun süresi doldu';

  @override
  String get credentialGatePlanSpentTitle => 'Claude Code plan limiti doldu';

  @override
  String credentialGateWaitingAgent(String agent) {
    return '$agent devam etmek için bekliyor.';
  }

  @override
  String get credentialGateWaitingRun =>
      'Bir çalıştırma devam etmek için bekliyor.';

  @override
  String get credentialGateWatching =>
      'Düzeltme izleniyor — çalıştırma kendiliğinden devam eder.';

  @override
  String credentialGateFreesUpAt(String time) {
    return '$time saatinde boşalır';
  }

  @override
  String credentialGateGivesUpAt(String time) {
    return 'Çalıştırma $time saatinde vazgeçer';
  }

  @override
  String get credentialGateCheckAgain => 'Yeniden kontrol et';

  @override
  String get credentialGateCancelRun => 'Çalıştırmayı iptal et';

  @override
  String get credentialGateAccountsTried => 'Denenen hesaplar';

  @override
  String get credentialGateClaudeSignInHint =>
      'Ayarlar → Adapters → Claude Code üzerinden oturum açın veya bir terminalde login komutunu çalıştırın. Çalıştırma bunu kendiliğinden alır.';

  @override
  String get credentialGateOpenSettings => 'Ayarları aç';

  @override
  String get selectModel => 'Model seç';

  @override
  String get allModels => 'Tüm modeller';

  @override
  String get noModelsMatchSearch => 'Aramanızla eşleşen model yok';

  @override
  String useCustomModelId(String id) {
    return '“$id” kullan';
  }

  @override
  String get modelFree => 'Ücretsiz';

  @override
  String modelOutputTokens(String tokens) {
    return '$tokens çıktı';
  }

  @override
  String modelPricePerMTokens(String input, String output) {
    return '1M token başına $input girdi / $output çıktı';
  }

  @override
  String modelEffortLevels(String levels) {
    return 'Akıl yürütme eforu: $levels';
  }

  @override
  String get modelSupportsReasoning => 'Akıl yürütme eforunu destekler';

  @override
  String get profileDeliveryMetrics => 'Teslimat metrikleri';

  @override
  String profileMetricsSample(int count) {
    return 'Analiz edilen PR\'ler: $count';
  }

  @override
  String get profileMergeRate => 'Birleştirme oranı';

  @override
  String get profileReviewCoverage => 'İnceleme kapsamı';

  @override
  String get profilePrSize => 'PR boyutu';

  @override
  String get profileTimeToMerge => 'Birleştirme süresi';

  @override
  String get profileMergeTimeTrend => 'Birleştirme süresi eğilimi';

  @override
  String get profileWeeklyMedian => 'Haftalık medyan, logaritmik ölçek';

  @override
  String get profilePrOpeningPattern => 'Haftanın günü × saat, yerel saat';

  @override
  String get profileFirstReview => 'İlk incelemeye kadar geçen süre';

  @override
  String get profileMetricsTruncated =>
      'Yüzdelik dilimler, mevcut çekme isteklerinin sınırlı bir örneklemi kullanılarak hesaplanır.';

  @override
  String profileLinesChanged(String count) {
    return '$count satır';
  }

  @override
  String profileDurationMinutes(int count) {
    return '$count dk';
  }

  @override
  String profileDurationHours(int count) {
    return '$count sa';
  }

  @override
  String profileDurationDaysHours(int days, int hours) {
    return '${days}g ${hours}sa';
  }

  @override
  String profilePercentiles(String median, String p90) {
    return 'p50 $median · p90 $p90';
  }

  @override
  String profileTeamMembers(int count) {
    return 'Üyeler: $count';
  }

  @override
  String noPrsByTeamInWorkspace(String team) {
    return 'Bu çalışma alanında $team tarafından açılmış pull request yok';
  }

  @override
  String get profilePrStateFilterLabel =>
      'Pull request\'leri duruma göre filtrele';

  @override
  String get noProfilePrsMatchSearchHint =>
      'Başka bir başlık veya pull request numarası deneyin';

  @override
  String get rigNetworkUnrestricted => 'Ağ kısıtlamasız';

  @override
  String get rigNetworkAllowAllHosts => 'Tüm ana bilgisayarlara izin ver';

  @override
  String get rigBrowserPermissionsTitle => 'Site izinleri';

  @override
  String get rigBrowserPermissionsTooltip => 'Site izinleri ve ağ';

  @override
  String get rigBrowserPermissionEmpty => 'Henüz hiçbir site izin istemedi';

  @override
  String rigBrowserPermissionPrompt(String origin, String permission) {
    return '$origin şunu kullanmak istiyor: $permission';
  }

  @override
  String get rigBrowserPermissionBlock => 'Engelle';

  @override
  String get rigBrowserPermissionCamera => 'Kamera';

  @override
  String get rigBrowserPermissionMicrophone => 'Mikrofon';

  @override
  String get rigBrowserPermissionNotifications => 'Bildirimler';

  @override
  String get rigBrowserPermissionGeolocation => 'Konum';

  @override
  String get rigBrowserPermissionPersistentStorage => 'Kalıcı depolama';

  @override
  String get rigBrowserPermissionClipboard => 'Pano';

  @override
  String get rigBrowserPermissionDisplayCapture => 'Ekran yakalama';

  @override
  String get rigBrowserPermissionMidi => 'MIDI';

  @override
  String get rigNetworkBypassTitle =>
      'Tüm ağ ana bilgisayarlarına izin verilsin mi?';

  @override
  String get rigNetworkBypassBody =>
      'Bu işlem yalıtılmış ortamı yeniden başlatır ve içindeki işlenmemiş çalışmaları siler. Ardından konuk sistem, kapatılana kadar tüm ağ ana bilgisayarlarına erişebilir.';

  @override
  String get rigNetworkRestartUnrestricted => 'Kısıtlamasız yeniden başlat';

  @override
  String get rigNetworkUnrestrictedBody =>
      'Bu yalıtılmış ortam tüm ağ ana bilgisayarlarına erişebilir. Varsayılan kısıtlamaları geri yüklemek için ortamı kapatın ve yenisini açın.';

  @override
  String get rigNetworkAlreadyUnrestrictedBody =>
      'Bu Android emülatörü kendi ağını zaten yönetiyor. Bu nedenle Control Center, ana bilgisayar başına izin listesi uygulayamaz. Yeniden başlatma gerekmez.';

  @override
  String get rigClipboardPermissionHostToRigTitle =>
      'Panoyu bu ortama yapıştırılsın mı?';

  @override
  String get rigClipboardPermissionHostToRigBody =>
      'Control Center cihazınızın panosunu okuyacak ve içeriğini ortama gönderecek. Pano içeriği parolalar veya başka gizli bilgiler içerebilir.';

  @override
  String get rigClipboardPermissionRigToHostTitle =>
      'Pano bu ortamdan kopyalansın mı?';

  @override
  String get rigClipboardPermissionRigToHostBody =>
      'Control Center ortamın panosunu okuyacak ve cihazınızın panosunu bunun içeriğiyle değiştirecek. Ortamdan gelen içeriği güvenilmeyen olarak değerlendirin.';

  @override
  String get rigClipboardAllowTenMinutes => '10 dakika izin ver';

  @override
  String get rigClipboardAlwaysAllow => 'Her zaman izin ver';

  @override
  String get rigClipboardSettingsTitle => 'Pano erişimi';

  @override
  String get rigClipboardSettingsHint =>
      'Hangi pano aktarımlarının sormadan çalışabileceğini seçin. Geçici izinler 10 dakika sonra sona erer.';

  @override
  String get rigClipboardAlwaysPasteTitle =>
      'Ortamlara yapıştırmaya her zaman izin ver';

  @override
  String get rigClipboardAlwaysPasteDescription =>
      'Bu cihazın panosunu sormadan herhangi bir ortama gönder.';

  @override
  String get rigClipboardAlwaysCopyTitle =>
      'Ortamdan kopyalamaya her zaman izin ver';

  @override
  String get rigClipboardAlwaysCopyDescription =>
      'Herhangi bir ortamdan pano içeriğini sormadan bu cihaza koy.';
}
