// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get succeeded => 'موفق';

  @override
  String agentRunRetryLabel(int number, String time) {
    return 'تلاش مجدد ⁨#$number⁩ · $time';
  }

  @override
  String agentRunStarting(String time) {
    return 'در حال شروع · $time';
  }

  @override
  String get agentActivityFollowingLive => 'دنبال‌کردن فعالیت زنده';

  @override
  String get agentActivityJumpToLatest => 'پرش به آخرین';

  @override
  String get agentActivityLoadFailed => 'بارگذاری فعالیت این اجرا ممکن نشد';

  @override
  String get agentActivityNotRecorded => 'هیچ فعالیتی برای این اجرا ثبت نشد';

  @override
  String get agentActivityNotRecordedHint =>
      'اجراهایی که پیش از فعال‌شدن ثبت فعالیت تمام شده‌اند خط زمانی ندارند.';

  @override
  String get agentActivityRunUnavailable => 'این اجرا دیگر در دسترس نیست';

  @override
  String agentActivitySubagentOf(String agent) {
    return 'زیرعاملِ ⁨$agent⁩';
  }

  @override
  String get agentActivityUnsupported =>
      'ثبت فعالیت روی سرور متصل در دسترس نیست';

  @override
  String get agentActivityUnsupportedHint =>
      'برنامه را از نو راه‌اندازی کنید تا آخرین ساخت سرور را بردارد.';

  @override
  String get agentActivityWaiting => 'در انتظار فعالیت…';

  @override
  String get created => 'ایجاد شد';

  @override
  String get dictationStart => 'شروع دیکته';

  @override
  String get dictationListening => 'در حال شنیدن…';

  @override
  String get dictationUnavailable =>
      'دیکته به یک مدل صوتی روی میزبان سرور نیاز دارد. آن را در تنظیمات صدا راه‌اندازی کنید.';

  @override
  String get dictationFailedToStart => 'شروع دیکته ممکن نشد';

  @override
  String get dictationHoldToTalkTitle => 'نگه دارید تا صحبت کنید';

  @override
  String get dictationHoldToTalkDescription =>
      'دکمه میکروفون یا میانبر را نگه دارید تا دیکته کنید و رها کنید تا متوقف شود. وقتی خاموش است، یک‌بار فشار دهید تا شروع شود و دوباره فشار دهید تا متوقف شود.';

  @override
  String get focusConversation => 'تمرکز روی گفتگو';

  @override
  String get ideAgentActivity => 'فعالیت عامل';

  @override
  String get keybindingPushToTalk => 'فشار دهید تا صحبت کنید';

  @override
  String get keybindingPushToTalkDescription =>
      'دیکته صوتی را در ویرایشگر پیام نگه دارید یا تغییر وضعیت دهید';

  @override
  String get agentPermissions => 'مجوزهای عامل';

  @override
  String get agentPermissionsSettingsDescription =>
      'تعیین کنید عامل‌ها چه کارهایی را خودشان می‌توانند انجام دهند، دربارهٔ چه چیزی باید اول بپرسند، و چه چیزی را هرگز نمی‌توانند — به‌ازای فضای کاری، عامل یا فضا.';

  @override
  String get agentPermissionsMatrixDescription =>
      'برای هر نوع اثر یک تصمیم بگذارید. قواعد آبشاری‌اند: فضا بر عامل، عامل بر فضای کاری، و فضای کاری بر پیش‌تنظیم حالت غلبه می‌کند. خاص‌ترین قاعده برنده است.';

  @override
  String get guardrailLoading => 'در حال بارگذاری قواعد…';

  @override
  String get guardrailRulesLoadFailed => 'بارگذاری قواعد مجوز ممکن نشد.';

  @override
  String get guardrailScopeWorkspace => 'فضای کاری';

  @override
  String get guardrailScopeAgent => 'عامل';

  @override
  String get guardrailScopeSpace => 'فضا';

  @override
  String get guardrailSelectAgent => 'یک عامل انتخاب کنید';

  @override
  String get guardrailSelectSpace => 'یک فضا انتخاب کنید';

  @override
  String get guardrailNoAgents => 'هنوز عاملی در این فضای کاری نیست.';

  @override
  String get guardrailNoSpaces => 'هنوز فضایی در این فضای کاری نیست.';

  @override
  String get guardrailClassFileDelete => 'حذف یک فایل';

  @override
  String get guardrailClassFileWriteOutsideWorktree =>
      'نوشتن بیرون از ⁨worktree⁩';

  @override
  String get guardrailClassGitCommit => 'ایجاد یک کامیت';

  @override
  String get guardrailClassGitPush => 'پوش به یک ریموت';

  @override
  String get guardrailClassPrCreate => 'باز کردن یک pull request';

  @override
  String get guardrailClassPrPublish => 'انتشار یک بازبینی یا ادغام';

  @override
  String get guardrailClassVendorSyncWrite => 'نوشتن در یک ردیاب خارجی';

  @override
  String get guardrailClassNetworkEgress => 'دسترسی به شبکه';

  @override
  String get guardrailClassSecretAccess => 'خواندن یک راز';

  @override
  String get guardrailClassPackageInstall => 'نصب یک بسته';

  @override
  String get guardrailClassProcessSpawn => 'اجرای یک فرایند';

  @override
  String get guardrailClassWorkspaceMutation => 'تغییر ساختار فضای کاری';

  @override
  String get guardrailClassEnclosureControl => 'راندن یک محفظه (ریگ)';

  @override
  String get navRigs => 'ریگ‌ها';

  @override
  String get rigsUnsupportedServer =>
      'این سرور نمی‌تواند هیچ سطح rig را میزبانی کند. الزامات میزبان را برای دستگاهی که می‌خواهید استفاده کنید بررسی کنید.';

  @override
  String get rigSurfaceComputer => 'رایانه';

  @override
  String get rigSurfaceBrowser => 'مرورگر';

  @override
  String get rigSurfaceAndroid => 'Android';

  @override
  String get rigSurfaceIosSimulator => 'شبیه‌ساز iOS';

  @override
  String rigSurfaceBrowserEngine(String engine) {
    return '$engine';
  }

  @override
  String rigBrowserEngineHint(String engine) {
    return 'یک ⁨$engine⁩ یک‌بارمصرف، جدا از ماشین شما. موتور دیگری باز کنید تا همان صفحه را کنار هم مقایسه کنید.';
  }

  @override
  String get rigPhaseReady => 'آماده';

  @override
  String get rigPhaseStarting => 'در حال شروع';

  @override
  String get rigPhaseParked => 'متوقف';

  @override
  String get rigPhaseClosing => 'در حال بستن';

  @override
  String get rigPhaseClosed => 'بسته';

  @override
  String get rigPhaseFailed => 'ناموفق';

  @override
  String get rigPhaseUnknown => 'ناشناخته';

  @override
  String get rigNotAccelerated => 'شبیه‌سازی‌شده';

  @override
  String get rigAudioListen => 'گوش دادن به ماشین';

  @override
  String get rigAudioMute => 'بی‌صدا کردن ماشین';

  @override
  String get rigYouHaveControl => 'کنترل با شماست';

  @override
  String get rigBackendAvailable => 'در دسترس';

  @override
  String get rigBackendUnavailable => 'در دسترس نیست';

  @override
  String get rigEgressNotEnforced =>
      'شبکه روی این بک‌اند محفظه نشده — خودش اتصالش را مدیریت می‌کند.';

  @override
  String get rigStartMachine => 'شروع ماشین';

  @override
  String get rigStartHint =>
      'یک VM یک‌بارمصرف را شروع می‌کند که شما و عامل‌هایتان در این گفتگو به اشتراک می‌گذارید. با بسته شدن نابود می‌شود و چیزی از آن به رایانهٔ شما دست نمی‌زند.';

  @override
  String get rigStartAndroidHint =>
      'به شبیه‌ساز Android که از قبل روی سرور در حال اجرا است متصل می‌شود. دسترسی به شبکه ایزوله نیست.';

  @override
  String get rigStartIosHint =>
      'یک شبیه‌ساز موقت iOS روی سرور macOS ایجاد می‌کند. با بسته‌شدن محیط آزمایش حذف می‌شود؛ دسترسی به شبکه ایزوله نیست.';

  @override
  String get rigTechnicalDetails => 'جزئیات فنی';

  @override
  String get rigStopMachine => 'توقف ماشین';

  @override
  String get rigHomeButton => 'خانه';

  @override
  String get rigRotateClockwise => 'چرخش ساعت‌گرد';

  @override
  String get rigRotateCounterclockwise => 'چرخش پادساعت‌گرد';

  @override
  String get rigTakeScreenshot => 'گرفتن نماگرفت';

  @override
  String get rigScreenshotSaved => 'نماگرفت ذخیره شد';

  @override
  String rigScreenshotSaveFailed(String error) {
    return 'نماگرفت ذخیره نشد: ⁨$error⁩';
  }

  @override
  String get rigSurfaceUnavailable =>
      'این سرور نمی‌تواند این نوع ماشین را میزبانی کند.';

  @override
  String get rigTabNeedsConversation =>
      'اول یک گفتگو باز کنید — ماشین به یک گفتگو تعلق دارد تا شما و عامل‌هایتان یک صفحه را ببینید.';

  @override
  String get ideMenuSectionTools => 'ابزارها';

  @override
  String get ideMenuSectionMachines => 'دستگاه‌ها';

  @override
  String get ideMenuSectionReopen => 'بازگشایی';

  @override
  String get ideMenuSearchHint => 'جستجو';

  @override
  String get ideMenuNoMatches => 'موردی یافت نشد';

  @override
  String get rigMenuComputer => 'رایانه';

  @override
  String get rigMenuBrowser => 'مرورگر';

  @override
  String get rigMenuAndroid => 'Android';

  @override
  String get rigMenuIosSimulator => 'شبیه‌ساز iOS';

  @override
  String rigLabelNumbered(String label, String suffix) {
    return '$label $suffix';
  }

  @override
  String ideCloseKeepTitle(String name) {
    return '«⁨$name⁩» بسته شود؟';
  }

  @override
  String get ideCloseKeepBodyMachine =>
      'ماشین در پس‌زمینه به کار ادامه می‌دهد — هر وقت از نوار کناری بازش کنید. برای آزاد کردن حافظه همین حالا آن را خاموش کنید.';

  @override
  String get ideCloseKeepBodyShell =>
      'فرمان در پس‌زمینه ادامه می‌یابد — هر وقت پوسته را از نوار کناری باز کنید. برای توقف کار فعلی آن را پایان دهید.';

  @override
  String get ideCloseKeepBodyAgent =>
      'عامل در پس‌زمینه به کار ادامه می‌دهد — هر وقت گفتگو را از نوار کناری باز کنید. برای پایان همین اجرای فعلی آن را متوقف کنید.';

  @override
  String get ideCloseKeepRunning => 'ادامه اجرا';

  @override
  String get ideCloseShutDownMachine => 'خاموش کردن';

  @override
  String get ideCloseEndShell => 'پایان پوسته';

  @override
  String get ideCloseStopAgent => 'توقف عامل';

  @override
  String get rigsSettingsSubtitle =>
      'آنچه این سرور می‌تواند بوت کند، تصاویر پایه‌ای که نیاز دارد، و ماشین‌های در حال اجرا';

  @override
  String get rigsCapabilitiesTitle => 'این سرور';

  @override
  String get rigInstallIosAutomation => 'نصب پل اتوماسیون iOS';

  @override
  String get rigInstallingIosAutomation => 'در حال نصب پل اتوماسیون iOS…';

  @override
  String get rigIosAutomationInstalled => 'پل اتوماسیون iOS نصب شد';

  @override
  String get rigsImagesTitle => 'تصاویر پایه';

  @override
  String get rigsImagesHint =>
      'هر ریگ از یکی از این تصاویر فقط‌خواندنی بوت می‌شود. هر نشست روی یک لایهٔ دورریختنی می‌نویسد، پس یک ریگ هرگز مبدأ ریگ بعدی را عوض نمی‌کند.';

  @override
  String get rigsRunningTitle => 'در حال اجرا';

  @override
  String get rigsNoneRunning => 'ماشینی در حال اجرا نیست.';

  @override
  String get rigsCustomImagesTitle => 'تصاویر سفارشی (این فضای کاری)';

  @override
  String get rigsCustomImagesHint =>
      'ترمینال (VM) یا مرورگر (VM) را به تصویر خودتان وصل کنید — پیش‌فرض‌ها را با ابزارهای پروژه گسترش دهید، یا هر تصویر سازگاری از یک رجیستری. ماشین‌های جدید از آن استفاده می‌کنند؛ در حال اجراها تصویر خود را نگه می‌دارند. راهنمای ریگ‌ها را برای الزامات تصویر ببینید.';

  @override
  String get rigsCustomTerminalImageLabel => 'تصویر ترمینال (VM)';

  @override
  String get rigsCustomBrowserImageLabel => 'تصویر مرورگر (VM)';

  @override
  String get rigsCustomImagePlaceholder =>
      'مثلاً ⁨ghcr.io/acme/dev-shell:1.2⁩ — برای پیش‌فرض خالی بگذارید';

  @override
  String get rigsCustomImageInvalid =>
      'یک مرجع رجیستری مثل ⁨repo/name:tag⁩ وارد کنید. مسیرهای محلی و آرشیوها مجاز نیستند.';

  @override
  String get rigsCustomImageSaved =>
      'ذخیره شد. ماشین‌های جدید از این تصویر بوت می‌شوند؛ در حال اجراها تصویر خود را نگه می‌دارند.';

  @override
  String get rigsEgressTitle => 'خروج مرورگر (این فضای کاری)';

  @override
  String get rigsEgressHint =>
      'میزبان‌های اضافی که مرورگر محفظه‌ای می‌تواند به آن‌ها برسد — یکی در هر خط: میزبان دقیق (⁨api.example.com⁩) یا وایلدکارد زیردامنه‌ها (⁨*.example.com⁩). سایت محصول در هر حال مجاز می‌ماند. ماشین‌های جدید این فهرست را می‌گیرند؛ در حال اجراها همان بوت را نگه می‌دارند.';

  @override
  String rigsEgressInvalid(String host) {
    return '«⁨$host⁩» یک ورودی میزبان معتبر نیست.';
  }

  @override
  String get rigsEgressSaved =>
      'ذخیره شد. ماشین‌های مرورگر جدید این میزبان‌ها را می‌پذیرند؛ در حال اجراها فهرست خود را نگه می‌دارند.';

  @override
  String get rigImageInstalled => 'نصب‌شده';

  @override
  String get rigImageNotDownloaded => 'دانلود نشده';

  @override
  String get rigImageNotPublished => 'منتشر نشده';

  @override
  String get rigImageNotPublishedHint =>
      'هنوز تصویری برای این منتشر نشده، پس چیزی برای دانلود نیست. یک تصویر دیسک سازگار وارد کنید تا فعال شود.';

  @override
  String get rigImageDownload => 'دانلود';

  @override
  String get rigImageDownloading => 'در حال دانلود…';

  @override
  String get rigImageImport => 'وارد کردن';

  @override
  String get rigImageImportMessage =>
      'مسیر یک تصویر دیسک ⁨qcow2⁩ روی فایل‌سیستم سرور. به انبار تصاویر کپی می‌شود، پس فایل بعداً می‌تواند جابه‌جا شود.';

  @override
  String get rigConnectingStream => 'در حال اتصال به ریگ';

  @override
  String get rigStreamNotAllowed => 'به این ریگ دسترسی ندارید.';

  @override
  String get rigStreamNotRunning => 'این ریگ دیگر در حال اجرا نیست.';

  @override
  String get rigStreamNeedsFfmpeg =>
      'نمایش زنده به ⁨ffmpeg⁩ روی این میزبان نیاز دارد. ⁨ffmpeg⁩ را نصب کنید و زبانه را دوباره باز کنید.';

  @override
  String get rigStreamEnded => 'نمایش زنده پایان یافت.';

  @override
  String get rigStreamFailed => 'نمایش زنده باز نشد.';

  @override
  String get rigStreamDisconnected => 'به سروری متصل نیستید.';

  @override
  String rigDropSendingOne(String name) {
    return 'در حال کپی «⁨$name⁩» به ماشین…';
  }

  @override
  String rigDropSendingMany(int count) {
    return 'در حال کپی $count فایل به ماشین…';
  }

  @override
  String get rigTerminalDropSending => 'در حال کپی به ماشین…';

  @override
  String get rigTerminalPasteImage => 'تصویر چسبانده‌شده در ماشین ذخیره شد';

  @override
  String get rigPortsTitle => 'پورت‌های فورواردشده';

  @override
  String get rigPortsTooltip => 'پورت‌های باز داخل این ماشین';

  @override
  String get rigPortsEmpty =>
      'هنوز چیزی گوش نمی‌دهد. در ترمینال یک سرور راه بیندازید — سرور توسعه روی پورت 3000 اینجا ظاهر می‌شود.';

  @override
  String get rigPortsAdd => 'افزودن پورت';

  @override
  String get rigPortsAddHint => 'پورت مهمان برای فوروارد (مثلاً 3000)';

  @override
  String get rigPortsAutoForward => 'فوروارد خودکار پورت‌ها';

  @override
  String get rigPortsCopyUrl => 'کپی URL محلی';

  @override
  String rigPortsCopiedUrl(String url) {
    return '⁨$url⁩ کپی شد';
  }

  @override
  String get rigPortsStopForward => 'توقف فوروارد';

  @override
  String get rigPortsExposeLan => 'اشتراک در شبکهٔ محلی';

  @override
  String get rigPortsLanPrivate => 'فقط محلی';

  @override
  String get rigPortsLanShared => 'روی شبکه';

  @override
  String get rigPortsSetDomain => 'تنظیم دامنهٔ مرورگر (⁨.test⁩)';

  @override
  String get rigPortsDomainHint =>
      'دامنه برای مرورگر (VM)، مثلاً ⁨myapp.test⁩ — آنجا در دسترس است، نه روی میزبان';

  @override
  String get rigPortsProcessUnknown => 'فرایند ناشناخته';

  @override
  String get rigPortsInactive => 'گوش نمی‌دهد';

  @override
  String get rigPortsTooltipHost => 'پورت‌های باز در این پایانه';

  @override
  String get rigPortsEmptyHost =>
      'هنوز چیزی در این پایانه گوش نمی‌دهد. یک سرور راه‌اندازی کنید تا اینجا ظاهر شود.';

  @override
  String get rigPortsAddHintHost => 'پورت برای نگاشت (مثلاً 5173)';

  @override
  String get rigPortsLocalPortHint => 'پورت محلی (اختیاری)';

  @override
  String rigPortsDestDesktop(int port) {
    return 'localhost:$port';
  }

  @override
  String rigPortsDestBrowser(int port) {
    return 'localhost:$port در مرورگر (ماشین مجازی)';
  }

  @override
  String get rigPortsDestBrowserUnreachable => 'مرورگر (ماشین مجازی) متصل نیست';

  @override
  String rigPortsDestAndroid(int port) {
    return 'localhost:$port در اندروید';
  }

  @override
  String get rigPortsDestAndroidUnreachable => 'اندروید متصل نیست';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تصویر پایه هنوز باید دانلود شوند',
      one: '1 تصویر پایه هنوز باید دانلود شود',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => 'اجازه';

  @override
  String get guardrailDecisionPrompt => 'ابتدا بپرس';

  @override
  String get guardrailDecisionDeny => 'رد';

  @override
  String get guardrailSourceThisScope => 'این محدوده';

  @override
  String get guardrailSourceDefault => 'پیش‌فرض داخلی';

  @override
  String get guardrailSourcePreset => 'پیش‌تنظیم حالت';

  @override
  String get guardrailSourceInherited => 'به ارث رسیده';

  @override
  String get guardrailClearToInherited => 'پاک کردن تا مقدار ارثی';

  @override
  String get guardrailWhatIf => 'اگر…؟';

  @override
  String get guardrailWhatIfDescription =>
      'ببینید قواعد فعلی یک کنش را چگونه حل می‌کنند؛ همان منطقی که عامل‌ها با آن اجرا می‌شوند.';

  @override
  String get guardrailProbeActionLabel => 'کنش';

  @override
  String get guardrailProbeCommandLabel => 'فرمان (اختیاری)';

  @override
  String get guardrailProbeCommandHint => 'مثلاً ⁨git push origin main⁩';

  @override
  String get guardrailProbeAgentLabel => 'عامل (اختیاری)';

  @override
  String get guardrailProbeSpaceLabel => 'فضا (اختیاری)';

  @override
  String get guardrailProbeNone => 'هیچ';

  @override
  String get guardrailProbeModeLabel => 'حالت';

  @override
  String get guardrailProbeResult => 'نتیجه';

  @override
  String get guardrailProbeSource => 'منبع:';

  @override
  String get guardrailAdapterMatrix => 'کجا قواعد اعمال می‌شوند';

  @override
  String get guardrailAdapterMatrixDescription =>
      'مرجع صادقانه: هر اثر واقعاً کجا گرفته می‌شود، به‌ازای هر اجراکنندهٔ عامل. این واقعیت را مستند می‌کند، نه تضمین — اثرهایی که اجراکننده خارج از باند انجام می‌دهد قابل رهگیری نیستند.';

  @override
  String get guardrailEffectColumn => 'اثر';

  @override
  String get guardrailAdapterHarness => 'هارنس داخلی';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => 'کف سندباکس';

  @override
  String get guardrailEnforcementPolicyGate => 'دروازهٔ سیاست';

  @override
  String get guardrailEnforcementSandbox => 'فقط سندباکس';

  @override
  String get guardrailEnforcementNone => 'غیرقابل اعمال';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      'تصمیم مجوز پیش از اجرای اثر بررسی می‌شود و می‌تواند آن را مسدود کند.';

  @override
  String get guardrailEnforcementSandboxHelp =>
      'فقط سندباکس محدودش می‌کند؛ قاعدهٔ مجوز مشورت نمی‌شود.';

  @override
  String get guardrailEnforcementNoneHelp =>
      'تصمیم فقط مشورتی است — اینجا قابل رهگیری نیست.';

  @override
  String get obsStatCost => 'هزینه';

  @override
  String obsStatDelegatedCost(String amount) {
    return '⁨+$amount⁩ تفویض‌شده';
  }

  @override
  String get obsStatDuration => 'مدت';

  @override
  String get obsStatTokens => 'توکن‌ها';

  @override
  String get obsStatTools => 'ابزارها';

  @override
  String get openAgentActivity => 'باز کردن فعالیت';

  @override
  String get orgChart => 'نمودار سازمانی';

  @override
  String get orgChartEmpty => 'هنوز عاملی نیست';

  @override
  String get navCalendar => 'تقویم';

  @override
  String get serverConnection => 'اتصال سرور';

  @override
  String get serverModeLocal => 'اجرا در این برنامه';

  @override
  String get serverModeLocalDescription =>
      'Control Center سرور خودش را روی این ماشین اجرا می‌کند و داده‌هایتان را محلی نگه می‌دارد.';

  @override
  String get serverModeRemote => 'اتصال به یک نمونهٔ راه دور';

  @override
  String get serverModeRemoteDescription =>
      'به یک سرور Control Center که جای دیگری اجرا می‌شود وصل شوید. داده‌هایتان روی آن سرور می‌ماند.';

  @override
  String get serverRemoteUrl => 'URL سرور';

  @override
  String get serverRemoteDeviceId => 'شناسهٔ دستگاه';

  @override
  String get serverRemotePairingKey => 'کلید جفت‌سازی';

  @override
  String get serverRemotePairingKeyHint =>
      'کلید جفت‌سازی را از سرور راه دور جای‌گذاری کنید';

  @override
  String get serverSetupInviteCode => 'کد دعوت';

  @override
  String get serverSetupInviteCodeHint =>
      'یک کد دعوت یک‌بارمصرف جای‌گذاری کنید (برای کلید جفت‌سازی خالی بگذارید)';

  @override
  String get serverDiscoveryTooltip => 'یافتن سرورها در شبکه‌تان';

  @override
  String get serverDiscoveryTitle => 'سرورها در شبکه‌تان';

  @override
  String get serverDiscoverySearching => 'در حال جستجوی سرورها…';

  @override
  String get serverDiscoveryEmpty =>
      'سروری یافت نشد. مطمئن شوید سرور در حال اجراست و این دستگاه به آن می‌رسد، سپس دوباره جستجو کنید.';

  @override
  String get serverDiscoveryRefresh => 'جستجوی دوباره';

  @override
  String get serverListActive => 'فعال';

  @override
  String get serverListSwitch => 'تعویض';

  @override
  String get serverListAddTitle => 'افزودن سرور';

  @override
  String get serverListRemoveActiveHint =>
      'پیش از حذف این سرور به سرور دیگری بروید.';

  @override
  String get serverSwitchFailedTitle => 'تعویض سرور ممکن نشد';

  @override
  String get serverListInsecureBadge => 'ناامن';

  @override
  String get connectionPathLocal => 'محلی';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => 'در حال خاموش شدن';

  @override
  String get shutdownSubtitle => 'بستن سرور محلی';

  @override
  String get shutdownServiceApprovals => 'تأییدیه‌ها';

  @override
  String get shutdownServiceBackgroundJobs => 'کارهای پس‌زمینه';

  @override
  String get shutdownServiceScheduler => 'زمان‌بند کار';

  @override
  String get shutdownServiceCalendar => 'همگام‌سازی تقویم';

  @override
  String get shutdownServiceWeather => 'آب‌وهوا';

  @override
  String get shutdownServiceSoundscape => 'منظر صوتی';

  @override
  String get shutdownServiceMeetings => 'جلسات';

  @override
  String get shutdownServiceVoiceModels => 'مدل‌های صوتی';

  @override
  String get shutdownServiceNetworking => 'شبکه';

  @override
  String get shutdownServicePresence => 'حضور';

  @override
  String get shutdownServiceDataSync => 'همگام‌سازی داده';

  @override
  String get shutdownServiceDeviceRelay => 'رلهٔ دستگاه';

  @override
  String get shutdownServiceMcpConnections => 'اتصالات MCP';

  @override
  String get shutdownServiceCodeEditors => 'ویرایشگرهای کد';

  @override
  String get serverSharingTitle => 'اشتراک این سرور';

  @override
  String get serverSharingDescription =>
      'این سرور را از دستگاه‌های دیگر خود در دسترس کنید. چیزی به‌صورت عمومی نمایان نمی‌شود مگر تونلی را در پایین روشن کنید. دعوت‌های جفت‌سازی نشانی‌های فعلی سرور را خودکار جاسازی می‌کنند — آن‌ها را در تنظیمات فضای کاری بسازید.';

  @override
  String get serverSharingUnavailable =>
      'کنترل‌های اشتراک روی این سرور در دسترس نیستند.';

  @override
  String get serverSharingMdnsLabel => 'کشف LAN';

  @override
  String get serverSharingMdnsOn =>
      'این سرور در شبکهٔ محلی شما آگهی می‌شود (⁨mDNS⁩)';

  @override
  String get serverSharingMdnsOff => 'در شبکهٔ محلی شما آگهی نمی‌شود (⁨mDNS⁩)';

  @override
  String get serverSharingTunnelLabel => 'تونل';

  @override
  String get serverSharingTunnelHelper =>
      'روشن کردن تونل این سرور را از اینترنت در دسترس می‌کند. نمایانی عمومی اختیاری است و به‌طور پیش‌فرض خاموش است.';

  @override
  String get serverSharingProviderOff => 'خاموش';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => 'URL عمومی';

  @override
  String get serverSharingTunnelStarting => 'در حال شروع تونل…';

  @override
  String serverSharingTunnelError(String error) {
    return 'خطای تونل: ⁨$error⁩';
  }

  @override
  String get serverSharingTunnelUpNoUrl =>
      'تونل برقرار است. از نام میزبان DNS پیکربندی‌شده به آن برسید.';

  @override
  String get serverSharingRelayLabel => 'رله';

  @override
  String serverSharingRelayUsage(String amount) {
    return 'رله‌شده در این ماه: ⁨$amount⁩';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return 'نشست‌های رلهٔ فعال: $count';
  }

  @override
  String get serverSharingUpdateFailedTitle => 'به‌روزرسانی اشتراک ممکن نشد';

  @override
  String get pairNewClient => 'جفت‌سازی کلاینت جدید';

  @override
  String get pairClientNameHint =>
      'این کلاینت را برچسب بزنید (مثلاً لپ‌تاپ کار)';

  @override
  String get pairClientTypeWeb => 'مرورگر وب';

  @override
  String get pairClientTypeDesktop => 'برنامهٔ دسکتاپ';

  @override
  String get pairClientTypePhone => 'تلفن';

  @override
  String get pairAction => 'جفت‌سازی';

  @override
  String get revoke => 'لغو';

  @override
  String get pairCredentialsIntro =>
      'کلاینت جدید را با این جزئیات وصل کنید، یا پیوند را در آن باز کنید.';

  @override
  String get pairLinkLabel => 'پیوند';

  @override
  String get pairScanQr => 'این کد QR را با دوربین تلفن اسکن کنید تا جفت شود.';

  @override
  String get pairServerUnreachableTitle => 'غیرقابل دسترس';

  @override
  String get pairServerUnreachable =>
      'دستگاه‌های دیگر مستقیم به این سرور نمی‌رسند، پس کلاینت جدید نمی‌تواند وصل شود. URL عمومی سرور را تنظیم کنید تا کلاینت‌های بیشتری جفت کنید.';

  @override
  String get serverSetupTitle => 'Control Center چطور اجرا شود؟';

  @override
  String get serverSetupSubtitle =>
      'Control Center به سروری نیاز دارد که مالک داده‌هایتان باشد. یکی را داخل این برنامه اجرا کنید، یا به نمونه‌ای که جای دیگری اجرا می‌شود وصل شوید.';

  @override
  String get serverSetupRunLocal => 'اجرا در این برنامه';

  @override
  String get serverSetupConnect => 'اتصال';

  @override
  String get serverSetupInvalidUrl =>
      'یک URL معتبر سرور با ⁨ws://⁩ یا ⁨wss://⁩ وارد کنید.';

  @override
  String get serverSetupCouldNotConnect => 'اتصال ممکن نشد';

  @override
  String get serverSetupErrorUnreachable =>
      'به سرور نرسیدیم. مطمئن شوید در حال اجراست و این دستگاه به آن می‌رسد (همان شبکه یا رله).';

  @override
  String get serverSetupErrorIdentityMismatch =>
      'هویت سرور با آنچه روی این دستگاه ذخیره شده جور نیست. اگر سرور دوباره نصب یا بازنشانی شده، سرور ذخیره‌شده را حذف کنید و دوباره جفت کنید.';

  @override
  String get serverSetupErrorAuthRejected =>
      'سرور این دستگاه را رد کرد. مطمئن شوید کلید جفت‌سازی و شناسهٔ دستگاه با آنچه سرور صادر کرده جور است.';

  @override
  String get serverSetupErrorInviteRejected =>
      'آن کد دعوت نامعتبر است یا منقضی شده. یک کد تازه بخواهید.';

  @override
  String get serverSetupErrorGeneric =>
      'هنگام اتصال مشکلی پیش آمد. جزئیات فنی زیر را باز کنید.';

  @override
  String get serverSetupErrorDetails => 'جزئیات فنی';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مورد دیگر',
      one: '1 مورد دیگر',
    );
    return '$_temp0';
  }

  @override
  String get calendarAllDayGutter => 'تمام‌روز';

  @override
  String calendarAllDayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رویداد',
      one: '1 رویداد',
    );
    return '$_temp0';
  }

  @override
  String get calendarCollapseAllDay => 'جمع کردن رویدادهای تمام‌روز';

  @override
  String get calendarExpandAllDay => 'گستردن رویدادهای تمام‌روز';

  @override
  String get calendarViewMonth => 'ماه';

  @override
  String get calendarViewWeek => 'هفته';

  @override
  String get calendarViewAgenda => 'برنامه';

  @override
  String get calendarConnectGoogle => 'اتصال Google Calendar';

  @override
  String get calendarConnectDescription =>
      'Google Calendar را همگام کنید تا رویدادها را اینجا ببینید و پیش از شروع جلسات هشدار بگیرید.';

  @override
  String get calendarDisconnect => 'قطع اتصال';

  @override
  String get calendarReconnect => 'اتصال مجدد';

  @override
  String get calendarEmptyNoEvents => 'رویدادی در این بازه نیست';

  @override
  String get calendarStartRecording => 'شروع ضبط';

  @override
  String get calendarStartRecordingAndLink => 'شروع ضبط و پیوند';

  @override
  String get calendarJoinMeet => 'پیوستن به جلسه';

  @override
  String get calendarFromCalendar => 'از تقویم';

  @override
  String get calendarLinkedMeeting => 'جلسهٔ پیوندشده';

  @override
  String get calendarToday => 'امروز';

  @override
  String get calendarAllDay => 'تمام روز';

  @override
  String calendarWeekNumber(int number) {
    return 'هفتهٔ $number';
  }

  @override
  String get calendarPreviousPeriod => 'قبلی';

  @override
  String get calendarNextPeriod => 'بعدی';

  @override
  String calendarLastSynced(String time) {
    return 'همگام‌شده $time';
  }

  @override
  String get calendarNeverSynced => 'هنوز همگام نشده';

  @override
  String get calendarSyncing => 'در حال همگام‌سازی…';

  @override
  String get calendarViewDay => 'روز';

  @override
  String get calendarShow => 'نمایش';

  @override
  String get calendarHide => 'پنهان';

  @override
  String get calendarRsvpGoing => 'شرکت می‌کنید؟';

  @override
  String get calendarRsvpYes => 'بله';

  @override
  String get calendarRsvpNo => 'خیر';

  @override
  String get calendarRsvpMaybe => 'شاید';

  @override
  String get calendarRsvpFailed => 'به‌روزرسانی پاسخ شما ممکن نشد';

  @override
  String get calendarAddAccount => 'افزودن حساب تقویم';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'حساب گوگل را وصل کنید تا رویدادها به این فضا همگام شوند. این تقویم‌ها اینجا مال شماست.';

  @override
  String get calendarConnecting => 'در حال اتصال…';

  @override
  String get calendarSyncNow => 'همگام‌سازی اکنون';

  @override
  String get calendarNoWorkspace =>
      'یک فضای کاری انتخاب کنید تا تقویمش را ببینید';

  @override
  String get calendarConnectError => 'اتصال Google Calendar ممکن نشد';

  @override
  String get calendarClientIdLabel => 'Client ID';

  @override
  String get calendarClientSecretLabel => 'راز کلاینت';

  @override
  String get calendarConnectCredsHint =>
      'Client ID و راز کلاینت Google OAuth از نوع device-code پروژهٔ خود را وارد کنید. سرور اتصال و همگام‌سازی را اجرا می‌کند — مرورگر هرگز توکن‌ها را نگه نمی‌دارد.';

  @override
  String get calendarConnectApproveInstruction =>
      'صفحهٔ تأیید را روی هر دستگاهی باز کنید، وارد شوید و این کد را وارد کنید:';

  @override
  String get calendarConnectOpenPage => 'باز کردن صفحهٔ تأیید';

  @override
  String get calendarConnectWaiting => 'در انتظار تأیید…';

  @override
  String get calendarConnectDenied => 'مجوز رد شد. دوباره تلاش کنید.';

  @override
  String get calendarConnectExpired => 'کد منقضی شد. دوباره تلاش کنید.';

  @override
  String get notificationMeetingStartsSoon => 'جلسه به‌زودی شروع می‌شود';

  @override
  String get notifyMeetingStartsSoon => 'وقتی جلسه‌ای در تقویم نزدیک شروع است';

  @override
  String get notificationCalendarAuthExpiredTitle => 'تقویم قطع شد';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return '⁨$email⁩ را دوباره وصل کنید تا همگام‌سازی از سر گرفته شود';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'تقویم را دوباره وصل کنید تا همگام‌سازی از سر گرفته شود';

  @override
  String get notifyCalendarAuthExpired => 'وقتی حساب تقویم باید دوباره وصل شود';

  @override
  String get notificationRigStatusChanged => 'به‌روزرسانی‌های محفظه';

  @override
  String get notifyRigStatusChanged =>
      'وقتی محفظه‌ای تصاحب، بازپس‌گرفته یا ناموفق می‌شود';

  @override
  String get notificationRigTakenOver => 'محفظه تصاحب شد';

  @override
  String get notificationRigTakenOverBody =>
      'یک نفر ماشین را می‌راند؛ عامل می‌تواند ببیند اما عمل نکند.';

  @override
  String get notificationRigReleased => 'کنترل محفظه آزاد شد';

  @override
  String get notificationRigReleasedBody => 'عامل دوباره ماشین را دارد.';

  @override
  String get notificationRigReclaimed => 'محفظه بازپس گرفته شد';

  @override
  String get notificationRigReclaimedBodyIdle =>
      'بیکار مانده بود، پس ماشین بسته شد تا حافظه آزاد شود.';

  @override
  String get notificationRigReclaimedBodyTtl =>
      'به محدودیت زمانی رسید و بسته شد.';

  @override
  String get notificationRigFailed => 'محفظه ناموفق شد';

  @override
  String get notificationRigFailedBody =>
      'هایپروایزر زیر آن از کار افتاد. ماشین را دوباره باز کنید تا ادامه دهید.';

  @override
  String get calendarAlertLeadTime => 'زمان پیش‌هشدار';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'چقدر پیش از جلسه به شما هشدار داده شود';

  @override
  String calendarConnectedAs(String email) {
    return 'متصل به‌عنوان ⁨$email⁩';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count شرکت‌کننده';
  }

  @override
  String get calendarEventLabel => 'رویداد';

  @override
  String get calendarRecurring => 'رویداد تکراری';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'برگزارکننده';

  @override
  String get calendarYou => 'شما';

  @override
  String get calendarShowFewer => 'نمایش کمتر';

  @override
  String get calendarRsvpAwaiting => 'در انتظار';

  @override
  String calendarParticipantsCount(int count) {
    return '$count مشارکت‌کننده';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'دیدن هر $count مشارکت‌کننده';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count بله';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count خیر';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count شاید';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count در انتظار';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count دقیقه';
  }

  @override
  String get openInEditorPrompt => 'در کدام ویرایشگر باز شود؟';

  @override
  String get ideNotInstalled => 'نصب نشده';

  @override
  String openInIde(String editor) {
    return 'باز کردن در ⁨$editor⁩';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return 'باز کردن ⁨$editor⁩ ممکن نشد: ⁨$error⁩';
  }

  @override
  String get profileSearchHint => 'جستجوی pull requestها…';

  @override
  String get stopAgentRun => 'توقف اجرا';

  @override
  String get stopAgentRunConfirm =>
      'این اجرا متوقف شود؟ کار در جریان از دست می‌رود.';

  @override
  String get inProgress => 'در جریان';

  @override
  String get drafts => 'پیش‌نویس‌ها';

  @override
  String get sortOldest => 'قدیمی‌ترین';

  @override
  String get sortLargest => 'بزرگ‌ترین';

  @override
  String get prFilterTooltip => 'فیلتر';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فیلتر فعال',
      one: '1 فیلتر فعال',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => 'افزودن فیلتر…';

  @override
  String get prFilterFieldHint => 'فیلتر…';

  @override
  String get prFilterCategoryStatus => 'وضعیت';

  @override
  String get prFilterCategoryAuthor => 'نویسنده';

  @override
  String get prFilterCategoryReviewer => 'بازبین‌ها';

  @override
  String get prFilterCategoryContent => 'محتوا';

  @override
  String get prFilterCategoryRepoOwner => 'مالک مخزن';

  @override
  String get prFilterCategoryRepoName => 'نام مخزن';

  @override
  String get prFilterCategoryOpenedDate => 'تاریخ باز شدن';

  @override
  String get prFilterCategoryUpdatedDate => 'تاریخ به‌روزرسانی';

  @override
  String get prFilterQuickToReview => 'بازبینی سریع';

  @override
  String get prFilterClearAll => 'پاک کردن فیلترها';

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
      other: '$count گزینه با هیچ pull requestی جور نیستند',
      one: '1 گزینه با هیچ pull requestی جور نیست',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => 'عنوان یا متن شامل…';

  @override
  String get prFilterNoOptions => 'گزینهٔ مطابقی نیست';

  @override
  String get prFilterChipIs => 'برابر است با';

  @override
  String get prFilterChipIsAnyOf => 'یکی از';

  @override
  String get prFilterChipContains => 'شامل';

  @override
  String get prFilterChipSince => 'از';

  @override
  String get prFilterAddFilterButton => 'افزودن فیلتر';

  @override
  String prFilterClearCategory(String category) {
    return 'پاک کردن فیلتر ⁨$category⁩';
  }

  @override
  String get prFilterCurrentUser => 'کاربر فعلی';

  @override
  String get prStatusDraft => 'پیش‌نویس';

  @override
  String get prStatusOpen => 'باز';

  @override
  String get prStatusInReview => 'در بازبینی';

  @override
  String get prStatusChangesRequested => 'درخواست تغییرات';

  @override
  String get prStatusApproved => 'تأییدشده';

  @override
  String get prStatusMerged => 'ادغام‌شده';

  @override
  String get prStatusClosed => 'بسته';

  @override
  String get prDateWindowDay => '1 روز پیش';

  @override
  String get prDateWindowThreeDays => '3 روز پیش';

  @override
  String get prDateWindowWeek => '1 هفته پیش';

  @override
  String get prDateWindowMonth => '1 ماه پیش';

  @override
  String get prDateWindowThreeMonths => '3 ماه پیش';

  @override
  String get prDateWindowSixMonths => '6 ماه پیش';

  @override
  String get prDateWindowYear => '1 سال پیش';

  @override
  String get prDisplayOptions => 'گزینه‌های نمایش';

  @override
  String get prDisplayGrouping => 'گروه‌بندی';

  @override
  String get prDisplayOrdering => 'ترتیب';

  @override
  String get prDisplayShowDrafts => 'نمایش پیش‌نویس‌ها';

  @override
  String get prDisplayMergedWindow => 'بازهٔ ادغام‌شده‌ها';

  @override
  String get prDisplayMergedWindowDay => 'روز گذشته';

  @override
  String get prDisplayMergedWindowWeek => 'هفتهٔ گذشته';

  @override
  String get prDisplayMergedWindowMonth => 'ماه گذشته';

  @override
  String get prDisplayProperties => 'ویژگی‌های نمایش';

  @override
  String get prGroupingRepository => 'مخزن';

  @override
  String get prGroupingAuthor => 'نویسنده';

  @override
  String get prGroupingStatus => 'وضعیت';

  @override
  String get prGroupingNone => 'بدون گروه‌بندی';

  @override
  String get prPropertyRepository => 'مخزن';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => 'شاخه';

  @override
  String get prPropertyUpdated => 'به‌روزرسانی‌شده';

  @override
  String get prPropertyAuthor => 'نویسنده';

  @override
  String get prPropertyChecks => 'بررسی‌ها';

  @override
  String get prPropertyDiff => 'دیف';

  @override
  String get prPropertyComments => 'نظرها';

  @override
  String get keybindingOpenFilterMenu => 'باز کردن منوی فیلتر';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'باز کردن منوی فیلتر pull request';

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مورد انتخاب‌شده',
      one: '1 مورد انتخاب‌شده',
    );
    return '$_temp0';
  }

  @override
  String get summary => 'خلاصه';

  @override
  String get kbMove => 'جابه‌جایی';

  @override
  String get kbTabs => 'زبانه‌ها';

  @override
  String get kbSearch => 'جستجو';

  @override
  String get kbViewed => 'دیده‌شده';

  @override
  String get kbCollapse => 'جمع کردن';

  @override
  String get appearance => 'ظاهر';

  @override
  String get appearanceSettingsDescription => 'تم، زبان و تایپوگرافی.';

  @override
  String get notificationsSettingsDescription =>
      'انتخاب کنید کدام رویدادهای عامل و فضای کاری به شما اعلان شوند.';

  @override
  String get advanced => 'پیشرفته';

  @override
  String get accounts => 'حساب‌ها';

  @override
  String get mcpServers => 'سرورهای MCP';

  @override
  String get mcpServersSettingsDescription =>
      'سرور MCP داخلی و سرورهای MCP خارجی.';

  @override
  String get remoteControlAndDevices => 'کنترل از راه دور و دستگاه‌ها';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'تلفن‌ها را جفت کنید و سرور کنترل از راه دور را پیکربندی کنید.';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'مدل‌های گفتار و تفکیک گوینده که این سرور میزبانی می‌کند.';

  @override
  String get needsSetupLabel => 'نیاز به راه‌اندازی';

  @override
  String get collapseSidebar => 'جمع کردن نوار کناری';

  @override
  String get expandSidebar => 'گستردن نوار کناری';

  @override
  String get filterSpacesHint => 'فیلتر فضاها';

  @override
  String noSpacesMatch(String query) {
    return 'هیچ فضایی با «⁨$query⁩» جور نیست';
  }

  @override
  String get privacy => 'حریم خصوصی';

  @override
  String get sendDiffContentTitle => 'ارسال محتوای دیف به آداپتور AI';

  @override
  String get diffSharingOnSubtitle =>
      'خطوط خام دیف برای بازبینی عمیق‌تر در پرامپت عامل‌ها گنجانده می‌شوند.';

  @override
  String get diffSharingOffSubtitle =>
      'عامل‌ها فقط فرادادهٔ ساخت‌یافته (مسیر فایل، شمارهٔ خط، شرح PR) را می‌بینند؛ هیچ کد خامی از برنامه خارج نمی‌شود.';

  @override
  String get errorReportingTitle => 'اشتراک گزارش‌های خرابی';

  @override
  String get errorReportingOnSubtitle =>
      'تشخیص خرابی، خطا و عملکرد برای رفع باگ فرستاده می‌شود (فقط ساخت‌های انتشار).';

  @override
  String get errorReportingOffSubtitle =>
      'تشخیص خاموش است. هیچ گزارش خرابی یا خطایی فرستاده نمی‌شود.';

  @override
  String get onboardingDiagnosticsTitle => 'به بهبود Control Center کمک کنید';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'تشخیص خرابی، خطا و عملکرد را بفرستید تا مشکلات سریع‌تر رفع شوند (فقط ساخت‌های انتشار). هر وقت در تنظیمات ← حریم خصوصی می‌توانید عوضش کنید.';

  @override
  String get blocked => 'مسدود';

  @override
  String get idle => 'بیکار';

  @override
  String get noRunsYet => 'هنوز اجرایی نیست';

  @override
  String get copyPath => 'کپی مسیر';

  @override
  String get copyRelativePath => 'کپی مسیر نسبی';

  @override
  String get nameRequired => 'نام لازم است';

  @override
  String get import => 'وارد کردن';

  @override
  String get noMatchingAgents => 'عاملی با فیلتر شما جور نیست';

  @override
  String watchVideoOn(String provider) {
    return 'تماشای ویدیو در ⁨$provider⁩';
  }

  @override
  String get branchTemplate => 'قالب نام شاخه';

  @override
  String get branchTemplateDescription =>
      'الگوی شاخه‌ای که هنگام شروع تیکت در یک worktree جدا ساخته می‌شود.';

  @override
  String branchTemplatePreview(String example) {
    return 'مثال: ⁨$example⁩';
  }

  @override
  String get deletePipelineRun => 'حذف اجرای پایپ‌لاین';

  @override
  String deletePipelineRunConfirm(String template) {
    return 'این اجرای «⁨$template⁩» حذف شود؟ این کار برگشت‌ناپذیر است.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'خطا در حذف اجرای پایپ‌لاین: ⁨$error⁩';
  }

  @override
  String get deleteTicket => 'حذف تیکت';

  @override
  String deleteTicketConfirm(String title) {
    return '«⁨$title⁩» حذف شود؟ این کار برگشت‌ناپذیر است.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'خطا در حذف تیکت: ⁨$error⁩';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return '«⁨$name⁩» حذف شود؟ مخزن‌های پیوندشده روی دیسک دست نخورده می‌مانند.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'خطا در حذف فضای کاری: ⁨$error⁩';
  }

  @override
  String get indexCode => 'ایندکس کد';

  @override
  String get indexNoGrammars => 'دستور زبان‌های کد نصب نشده‌اند';

  @override
  String get indexFailed => 'ایندکس ناموفق بود';

  @override
  String indexedSymbolsCount(int count) {
    return '$count نماد ایندکس شد';
  }

  @override
  String get nodeConfigAdvanced => 'پیشرفته';

  @override
  String get nodeConfigReducer => 'کاهنده';

  @override
  String get nodeConfigReducerHelp =>
      'چگونه ادغام شود وقتی این کلید خروجی از قبل مقدار دارد';

  @override
  String get nodeConfigTimeoutMs => 'مهلت (ms)';

  @override
  String get nodeConfigRetryAttempts => 'تعداد تلاش مجدد';

  @override
  String get nodeConfigContinueOnFail => 'ادامه اگر این گام ناموفق شد';

  @override
  String get nodeConfigTeamId => 'شناسهٔ تیم';

  @override
  String get nodeConfigDispatchMode => 'حالت اعزام';

  @override
  String get nodeConfigOutputSchema => 'شِمای خروجی (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'JSON Schema که خروجی گام باید برآورده کند';

  @override
  String get diffLineDisplay => 'خطوط بلند در دیف‌ها';

  @override
  String get diffLineDisplayDescription =>
      'خطوط بلند را بپیچید یا افقی پیمایش کنید';

  @override
  String get diffLineWrap => 'شکستن خط';

  @override
  String get diffLineScroll => 'پیمایش افقی';

  @override
  String get actions => 'کنش‌ها';

  @override
  String get activate => 'فعال‌سازی';

  @override
  String get activity => 'فعالیت';

  @override
  String get activityLabel => 'فعالیت';

  @override
  String get activitySearchHint => 'جستجوی فعالیت';

  @override
  String get activityNoMatches => 'هیچ فعالیتی با فیلترهای شما جور نیست';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$start–$end از $total';
  }

  @override
  String get activityPreviousPage => 'صفحهٔ قبلی';

  @override
  String get activityNextPage => 'صفحهٔ بعدی';

  @override
  String get activityNetworkLocal => 'Localhost';

  @override
  String get activityClearFilter => 'پاک کردن فیلتر';

  @override
  String activityFilterIp(String ip) {
    return 'IP ⁨$ip⁩';
  }

  @override
  String activityFilterCountry(String country) {
    return 'کشور ⁨$country⁩';
  }

  @override
  String get activitySavedWorkspaceLogo => 'لوگوی فضای کاری ذخیره شد';

  @override
  String activityVerbCreated(String target) {
    return '⁨$target⁩ ایجاد شد';
  }

  @override
  String activityVerbUpdated(String target) {
    return '⁨$target⁩ به‌روزرسانی شد';
  }

  @override
  String activityVerbDeleted(String target) {
    return '⁨$target⁩ حذف شد';
  }

  @override
  String activityVerbAdded(String target) {
    return '⁨$target⁩ افزوده شد';
  }

  @override
  String activityVerbRemoved(String target) {
    return '⁨$target⁩ برداشته شد';
  }

  @override
  String activityVerbInvited(String target) {
    return '⁨$target⁩ دعوت شد';
  }

  @override
  String activityVerbChanged(String target) {
    return '⁨$target⁩ تغییر کرد';
  }

  @override
  String activityVerbStarted(String target) {
    return '⁨$target⁩ شروع شد';
  }

  @override
  String activityVerbStopped(String target) {
    return '⁨$target⁩ متوقف شد';
  }

  @override
  String activityVerbWrote(String target) {
    return '⁨$target⁩ نوشته شد';
  }

  @override
  String get activityTargetAgent => 'عامل';

  @override
  String get activityTargetTicket => 'تیکت';

  @override
  String get activityTargetWorkspace => 'فضای کاری';

  @override
  String get activityTargetRepository => 'مخزن';

  @override
  String get activityTargetMember => 'عضو';

  @override
  String get activityTargetInvite => 'دعوت';

  @override
  String get activityTargetSpace => 'فضا';

  @override
  String get activityTargetMessage => 'پیام';

  @override
  String get activityTargetCache => 'کش';

  @override
  String get activityTargetFile => 'فایل';

  @override
  String get activityTargetPipeline => 'پایپ‌لاین';

  @override
  String get activityTargetTemplate => 'قالب';

  @override
  String get activityTargetProvider => 'ارائه‌دهنده';

  @override
  String get activityTargetModel => 'مدل';

  @override
  String get activityTargetSkill => 'مهارت';

  @override
  String get activityTargetTodo => 'کار';

  @override
  String get activityTargetMeeting => 'جلسه';

  @override
  String get activityTargetProject => 'پروژه';

  @override
  String get activityTargetTeam => 'تیم';

  @override
  String get activityTargetDevice => 'دستگاه';

  @override
  String get activityTargetPreference => 'ترجیح';

  @override
  String get activityTargetBudget => 'بودجه';

  @override
  String activityVerbApproved(String target) {
    return '⁨$target⁩ تأیید شد';
  }

  @override
  String activityVerbArchived(String target) {
    return '⁨$target⁩ بایگانی شد';
  }

  @override
  String activityVerbAssigned(String target) {
    return '⁨$target⁩ تخصیص یافت';
  }

  @override
  String activityVerbBackedUp(String target) {
    return 'پشتیبان ⁨$target⁩ گرفته شد';
  }

  @override
  String activityVerbCancelled(String target) {
    return '⁨$target⁩ لغو شد';
  }

  @override
  String activityVerbCleared(String target) {
    return '⁨$target⁩ پاک شد';
  }

  @override
  String activityVerbClosed(String target) {
    return '⁨$target⁩ بسته شد';
  }

  @override
  String activityVerbCommitted(String target) {
    return '⁨$target⁩ کامیت شد';
  }

  @override
  String activityVerbCompacted(String target) {
    return '⁨$target⁩ فشرده شد';
  }

  @override
  String activityVerbCompleted(String target) {
    return '⁨$target⁩ کامل شد';
  }

  @override
  String activityVerbConnected(String target) {
    return '⁨$target⁩ متصل شد';
  }

  @override
  String activityVerbContinued(String target) {
    return '⁨$target⁩ ادامه یافت';
  }

  @override
  String activityVerbDisconnected(String target) {
    return '⁨$target⁩ قطع شد';
  }

  @override
  String activityVerbDispatched(String target) {
    return '⁨$target⁩ اعزام شد';
  }

  @override
  String activityVerbDrained(String target) {
    return '⁨$target⁩ تخلیه شد';
  }

  @override
  String activityVerbEnrolled(String target) {
    return '⁨$target⁩ ثبت‌نام شد';
  }

  @override
  String activityVerbEstimated(String target) {
    return '⁨$target⁩ برآورد شد';
  }

  @override
  String activityVerbImported(String target) {
    return '⁨$target⁩ وارد شد';
  }

  @override
  String activityVerbInstalled(String target) {
    return '⁨$target⁩ نصب شد';
  }

  @override
  String activityVerbKilled(String target) {
    return '⁨$target⁩ کشته شد';
  }

  @override
  String activityVerbMarked(String target) {
    return '⁨$target⁩ علامت‌گذاری شد';
  }

  @override
  String activityVerbMerged(String target) {
    return '⁨$target⁩ ادغام شد';
  }

  @override
  String activityVerbOpened(String target) {
    return '⁨$target⁩ باز شد';
  }

  @override
  String activityVerbPaused(String target) {
    return '⁨$target⁩ مکث شد';
  }

  @override
  String activityVerbPolled(String target) {
    return '⁨$target⁩ نظرسنجی شد';
  }

  @override
  String activityVerbPrepared(String target) {
    return '⁨$target⁩ آماده شد';
  }

  @override
  String activityVerbProcessed(String target) {
    return '⁨$target⁩ پردازش شد';
  }

  @override
  String activityVerbPublished(String target) {
    return '⁨$target⁩ منتشر شد';
  }

  @override
  String activityVerbRefined(String target) {
    return '⁨$target⁩ پالایش شد';
  }

  @override
  String activityVerbRefreshed(String target) {
    return '⁨$target⁩ تازه‌سازی شد';
  }

  @override
  String activityVerbRegistered(String target) {
    return '⁨$target⁩ ثبت شد';
  }

  @override
  String activityVerbRenamed(String target) {
    return '⁨$target⁩ تغییر نام یافت';
  }

  @override
  String activityVerbReordered(String target) {
    return 'ترتیب ⁨$target⁩ عوض شد';
  }

  @override
  String activityVerbResponded(String target) {
    return 'به ⁨$target⁩ پاسخ داده شد';
  }

  @override
  String activityVerbRestored(String target) {
    return '⁨$target⁩ بازیابی شد';
  }

  @override
  String activityVerbResumed(String target) {
    return '⁨$target⁩ از سر گرفته شد';
  }

  @override
  String activityVerbRetried(String target) {
    return '⁨$target⁩ دوباره تلاش شد';
  }

  @override
  String activityVerbReverted(String target) {
    return '⁨$target⁩ برگردانده شد';
  }

  @override
  String activityVerbReviewed(String target) {
    return '⁨$target⁩ بازبینی شد';
  }

  @override
  String activityVerbRan(String target) {
    return '⁨$target⁩ اجرا شد';
  }

  @override
  String activityVerbSelected(String target) {
    return '⁨$target⁩ انتخاب شد';
  }

  @override
  String activityVerbSent(String target) {
    return '⁨$target⁩ فرستاده شد';
  }

  @override
  String activityVerbStaged(String target) {
    return '⁨$target⁩ مرحله‌بندی شد';
  }

  @override
  String activityVerbSteered(String target) {
    return '⁨$target⁩ هدایت شد';
  }

  @override
  String activityVerbSubmitted(String target) {
    return '⁨$target⁩ ارسال شد';
  }

  @override
  String activityVerbSynced(String target) {
    return '⁨$target⁩ همگام شد';
  }

  @override
  String activityVerbToggled(String target) {
    return 'وضعیت ⁨$target⁩ عوض شد';
  }

  @override
  String activityVerbUninstalled(String target) {
    return '⁨$target⁩ حذف نصب شد';
  }

  @override
  String activityVerbUnstaged(String target) {
    return '⁨$target⁩ از مرحله خارج شد';
  }

  @override
  String get activityTargetActionPolicy => 'سیاست کنش';

  @override
  String get activityTargetGoalRun => 'اجرای هدف';

  @override
  String get activityTargetRunLog => 'گزارش اجرا';

  @override
  String get activityTargetWorkingMemory => 'حافظهٔ کاری';

  @override
  String get activityTargetRoutingPolicy => 'سیاست مسیریابی';

  @override
  String get activityTargetAutonomy => 'خودمختاری';

  @override
  String get activityTargetCalendar => 'تقویم';

  @override
  String get activityTargetChecker => 'بررسی‌کننده';

  @override
  String get activityTargetEditor => 'ویرایشگر';

  @override
  String get activityTargetConfirmation => 'تأیید';

  @override
  String get activityTargetTunnel => 'تونل';

  @override
  String get activityTargetConversation => 'گفتگو';

  @override
  String get activityTargetCredentials => 'اعتبارنامه‌ها';

  @override
  String get activityTargetDictation => 'دیکته';

  @override
  String get activityTargetAgentRun => 'اجرای عامل';

  @override
  String get activityTargetEvalSuite => 'مجموعهٔ ارزیابی';

  @override
  String get activityTargetWorker => 'کارگر';

  @override
  String get activityTargetWorktree => 'worktree';

  @override
  String get activityTargetMcpServer => 'سرور MCP';

  @override
  String get activityTargetMemoryAccessGrant => 'مجوز دسترسی حافظه';

  @override
  String get activityTargetMemoryDomain => 'دامنهٔ حافظه';

  @override
  String get activityTargetMemoryFact => 'واقعیت حافظه';

  @override
  String get activityTargetMemoryPolicy => 'سیاست حافظه';

  @override
  String get activityTargetFeed => 'خوراک';

  @override
  String get activityTargetNote => 'یادداشت';

  @override
  String get activityTargetOrchestration => 'ارکستراسیون';

  @override
  String get activityTargetPipelineRun => 'اجرای پایپ‌لاین';

  @override
  String get activityTargetPipelineTrigger => 'تریگر پایپ‌لاین';

  @override
  String get activityTargetPlan => 'برنامه';

  @override
  String get activityTargetPlaybook => 'کتابچه';

  @override
  String get activityTargetPullRequest => 'pull request';

  @override
  String get activityTargetReview => 'بازبینی';

  @override
  String get activityTargetProcess => 'فرایند';

  @override
  String get activityTargetProviderPolicy => 'سیاست ارائه‌دهنده';

  @override
  String get activityTargetReaction => 'واکنش';

  @override
  String get activityTargetReviewSpace => 'فضای بازبینی';

  @override
  String get activityTargetReviewStudio => 'استودیوی بازبینی';

  @override
  String get activityTargetServerData => 'دادهٔ سرور';

  @override
  String get activityTargetSoundscape => 'منظر صوتی';

  @override
  String get activityTargetSession => 'نشست';

  @override
  String get activityTargetTerminal => 'ترمینال';

  @override
  String get activityTargetTicketLink => 'پیوند تیکت';

  @override
  String get activityTargetTicketSync => 'همگام‌سازی تیکت';

  @override
  String get activityTargetProfile => 'نمایه';

  @override
  String get activityTargetVoiceProfile => 'نمایهٔ صوتی';

  @override
  String get activityTargetWeather => 'پیش‌بینی هوا';

  @override
  String get activityTargetWorkProduct => 'محصول کار';

  @override
  String get activityChangedMemberRole => 'نقش یک عضو تغییر کرد';

  @override
  String get activityChangedMemberRepoAccess => 'دسترسی مخزن یک عضو تغییر کرد';

  @override
  String get activityUpdatedGitHubToken => 'توکن GitHub به‌روزرسانی شد';

  @override
  String get activityRefreshedWeather => 'پیش‌بینی هوا تازه‌سازی شد';

  @override
  String get activitySetWeatherLocation => 'موقعیت هوا تنظیم شد';

  @override
  String get activityClearedWeatherLocation => 'موقعیت هوا پاک شد';

  @override
  String get activityMarkedAllArticlesRead =>
      'همهٔ مقاله‌ها خوانده‌شده علامت خوردند';

  @override
  String get activityMarkedArticleRead => 'یک مقاله خوانده‌شده علامت خورد';

  @override
  String get activityUpdatedSavedArticle =>
      'یک مقالهٔ ذخیره‌شده به‌روزرسانی شد';

  @override
  String get activityTookOverSession => 'نشست تصاحب شد';

  @override
  String get activityHandedBackSession => 'نشست بازگردانده شد';

  @override
  String get activityCommittedAndPushed => 'کامیت و پوش شد';

  @override
  String get activityBackedUpServer => 'از دادهٔ سرور پشتیبان گرفته شد';

  @override
  String get activityMarkedSpaceRead => 'فضا خوانده‌شده علامت خورد';

  @override
  String get activityRespondedToInvitation => 'به دعوت رویداد پاسخ داده شد';

  @override
  String get activityStartedCalendarConnect => 'اتصال تقویم شروع شد';

  @override
  String get activityDisconnectedCalendar => 'تقویم قطع شد';

  @override
  String get activityMarkedFileViewed => 'یک فایل دیده‌شده علامت خورد';

  @override
  String get activityRespondedToApproval => 'به درخواست تأیید پاسخ داده شد';

  @override
  String get activityChangedTunnel => 'تنظیم تونل تغییر کرد';

  @override
  String get activitySentMessageToAgent => 'پیامی به عامل فرستاده شد';

  @override
  String get activityOpenedReviewSpace => 'فضای بازبینی باز شد';

  @override
  String get activityOpenedStandingConversation => 'گفتگوی پایدار باز شد';

  @override
  String get activityStartedRecording => 'ضبط شروع شد';

  @override
  String get activityStoppedRecording => 'ضبط متوقف شد';

  @override
  String get activityToggledMcpServer => 'وضعیت سرور MCP عوض شد';

  @override
  String get activityUpdatedMcpToken => 'توکن MCP به‌روزرسانی شد';

  @override
  String get activitySavedApiKey => 'یک کلید API ذخیره شد';

  @override
  String get activityRemovedProviderCredential =>
      'یک اعتبارنامهٔ ارائه‌دهنده برداشته شد';

  @override
  String get activityUpdatedLinkedRepos => 'مخزن‌های پیوندشده به‌روزرسانی شدند';

  @override
  String get activityUnlinkedRepo => 'یک مخزن از پیوند خارج شد';

  @override
  String get activityUpdatedActionItem => 'یک مورد اقدام به‌روزرسانی شد';

  @override
  String adRulesCount(int count) {
    return '$count قاعدهٔ تبلیغ';
  }

  @override
  String get adapter => 'آداپتور';

  @override
  String get adapterLabel => 'آداپتور';

  @override
  String get adapters => 'آداپتورها';

  @override
  String get adaptersAutoDetected =>
      'اجراکننده‌های عامل روی این ماشین به‌صورت خودکار تشخیص داده شدند. CLIهای جاافتاده را نصب کنید تا اجراکننده‌های بیشتری فعال شوند.';

  @override
  String get add => 'افزودن';

  @override
  String get addAComment => 'افزودن نظر';

  @override
  String get addAReaction => 'افزودن واکنش';

  @override
  String get addASuggestion => 'افزودن پیشنهاد';

  @override
  String get addAgents => 'افزودن عامل‌ها';

  @override
  String get addEmoji => 'افزودن اموجی';

  @override
  String get addFeed => 'افزودن خوراک';

  @override
  String get addressBarHint => 'یک URL وارد کنید';

  @override
  String get addFromFile => 'افزودن از فایل';

  @override
  String get addGif => 'افزودن GIF';

  @override
  String get addGithubRepoPrompt =>
      'دست‌کم یک مخزن GitHub اضافه کنید تا pull requestها را ببینید';

  @override
  String get addLocalCheckoutDescription =>
      'یک checkout محلی اضافه کنید تا از این فضای کاری هدفش کنید.';

  @override
  String get addRepository => 'افزودن مخزن';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'افزودن $count مخزن',
      one: 'افزودن مخزن',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro =>
      'پوشه‌های ماشینِ در حال اجرای سرور را مرور کنید و checkoutهای git را برای ثبت انتخاب کنید.';

  @override
  String get selectThisFolder => 'انتخاب این پوشه';

  @override
  String get deselectThisFolder => 'لغو انتخاب این پوشه';

  @override
  String get goUp => 'بالا';

  @override
  String get noSubfoldersHere => 'اینجا زیرپوشه‌ای نیست';

  @override
  String get notAGitRepository => 'این پوشه یک مخزن git نیست.';

  @override
  String get addToken => 'افزودن توکن';

  @override
  String get addWorkspace => 'افزودن فضای کاری';

  @override
  String get addWorkspaceEllipsis => 'افزودن فضای کاری…';

  @override
  String get added => 'افزوده شد';

  @override
  String get addingEllipsis => 'در حال افزودن…';

  @override
  String get advancedLabel => 'پیشرفته';

  @override
  String get agent => 'عامل';

  @override
  String agentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عامل‌ها',
      one: '1 عامل',
    );
    return '$_temp0';
  }

  @override
  String get agentMdPath => 'مسیر MD عامل';

  @override
  String get agentName => 'نام عامل';

  @override
  String get agentTitle => 'عنوان عامل';

  @override
  String get agentUpdated => 'عامل به‌روزرسانی شد.';

  @override
  String get agents => 'عامل‌ها';

  @override
  String get agentsMentionSection => 'عامل‌ها';

  @override
  String get usersMentionSection => 'افراد';

  @override
  String get ticketsMentionSection => 'تیکت‌ها';

  @override
  String get pullRequestsMentionSection => 'Pull requestها';

  @override
  String get meetingsMentionSection => 'جلسات';

  @override
  String get entityRefTicketFallback => 'تیکت';

  @override
  String get entityRefPrFallback => 'Pull request';

  @override
  String get entityRefMeetingFallback => 'جلسه';

  @override
  String get aiReview => 'بازبینی AI';

  @override
  String get all => 'همه';

  @override
  String get allAgentsAlreadyInSpace => 'همهٔ عامل‌ها از قبل در این فضا هستند.';

  @override
  String get allCommits => 'همهٔ کامیت‌ها';

  @override
  String get allSources => 'همهٔ منابع';

  @override
  String get allow => 'اجازه';

  @override
  String get allowGitPush => 'اجازهٔ git push';

  @override
  String get allowGithubApi => 'اجازهٔ فراخوانی‌های GitHub API';

  @override
  String get allowNetwork => 'اجازهٔ دسترسی عمومی به شبکه';

  @override
  String get apiKeys => 'کلیدهای API';

  @override
  String get appFont => 'فونت برنامه';

  @override
  String get appLogLevelDebugDescription =>
      'ردهای جزئی اضافه می‌کند — برای توسعه.';

  @override
  String get appLogLevelDebugLabel => 'اشکال‌زدایی';

  @override
  String get appLogLevelErrorDescription => 'فقط خطاها و استثناهای غیرمنتظره.';

  @override
  String get appLogLevelErrorLabel => 'خطا';

  @override
  String get appLogLevelInfoDescription =>
      'پیام‌های چرخهٔ حیات و وضعیت را اضافه می‌کند.';

  @override
  String get appLogLevelInfoLabel => 'اطلاعات';

  @override
  String get appLogLevelNoneDescription => 'هیچ خروجی کنسولی.';

  @override
  String get appLogLevelNoneLabel => 'هیچ';

  @override
  String get appLogLevelVerboseDescription =>
      'همه‌چیز. بسیار پرسر‌و‌صدا — فقط برای اشکال‌زدایی.';

  @override
  String get appLogLevelVerboseLabel => 'پرجزئیات';

  @override
  String get appLogLevelWarningDescription =>
      'هشدارها و مسائل قابل بازیابی را اضافه می‌کند.';

  @override
  String get appLogLevelWarningLabel => 'هشدار';

  @override
  String get appearanceLanguage => 'ظاهر و زبان';

  @override
  String get apply => 'اعمال';

  @override
  String get approve => 'تأیید';

  @override
  String get agentApprovalRequired => 'نیاز به تأیید';

  @override
  String agentApprovalsMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مورد دیگر در انتظار',
      one: '1 مورد دیگر در انتظار',
    );
    return '$_temp0';
  }

  @override
  String get approved => 'تأییدشده';

  @override
  String get articleNoun => 'مقاله';

  @override
  String get articlesSubscribed => 'مقاله‌ها در خوراک‌های اشتراک‌شده.';

  @override
  String get askAi => 'پرسش از AI';

  @override
  String get askAiReviewDescription => 'از AI بخواهید این PR را بازبینی کند';

  @override
  String get assignees => 'تخصیص‌یافته‌ها';

  @override
  String get attachImage => 'پیوست تصویر';

  @override
  String get attachedAgents => 'عامل‌های پیوست‌شده';

  @override
  String get audioInput => 'ورودی صدا';

  @override
  String get audioOutput => 'خروجی صدا';

  @override
  String get authenticationToken => 'توکن احراز هویت';

  @override
  String authoredByLabel(String role) {
    return 'توسط: ⁨$role⁩';
  }

  @override
  String get autoRecommended => 'خودکار (پیشنهادی)';

  @override
  String get available => 'در دسترس';

  @override
  String get awaitingYourReview => 'در انتظار بازبینی شما';

  @override
  String get back => 'بازگشت';

  @override
  String get backLabel => 'بازگشت';

  @override
  String get backend => 'بک‌اند';

  @override
  String get blockAdsTrackers => 'مسدود کردن تبلیغات، ردیاب‌ها و بنرهای کوکی';

  @override
  String get blocking => 'مسدودسازی';

  @override
  String get bookmarkLabel => 'نشانک';

  @override
  String get briefDescription => 'شرح کوتاه';

  @override
  String get bugLabel => 'باگ';

  @override
  String get bundledDefaultsNeverUpdated =>
      'پیش‌فرض‌های همراه — هرگز به‌روزرسانی نشده';

  @override
  String get cancel => 'لغو';

  @override
  String get cancelEdit => 'لغو ویرایش';

  @override
  String get categoryCreation => 'ایجاد';

  @override
  String get categoryEditing => 'ویرایش';

  @override
  String get categoryNavigation => 'ناوبری';

  @override
  String get categorySystem => 'سیستم';

  @override
  String get categoryView => 'نمای دسته';

  @override
  String get change => 'تغییر';

  @override
  String get changesRequested => 'درخواست تغییرات';

  @override
  String get spacesMentionSection => 'فضاها';

  @override
  String get checkForUpdates => 'بررسی به‌روزرسانی';

  @override
  String get checking => 'در حال بررسی';

  @override
  String get checkingEllipsis => 'در حال بررسی…';

  @override
  String get chooseAppFont => 'انتخاب فونت برنامه';

  @override
  String get chooseCodeFont => 'انتخاب فونت کد';

  @override
  String get chooseRunner => 'اجراکنندهٔ عامل را انتخاب کنید.';

  @override
  String get clear => 'پاک کردن';

  @override
  String get clickToRetry => 'برای تلاش مجدد کلیک کنید';

  @override
  String get close => 'بستن';

  @override
  String get closeEsc => 'بستن (Esc)';

  @override
  String get closeReader => 'بستن خواننده';

  @override
  String get closed => 'بسته';

  @override
  String get codeFont => 'فونت کد';

  @override
  String get codeFontLigatures => 'لیگاتور فونت کد';

  @override
  String get codeFontLigaturesDescription =>
      'لیگاتورهای برنامه‌نویسی (⁨=>⁩، ⁨!=⁩، ⁨->⁩) را در کد و دیف به‌صورت گلیف ترکیبی نشان بده';

  @override
  String get collapse => 'جمع کردن';

  @override
  String get commandPalette => 'پالت فرمان';

  @override
  String get commandPaletteOrgMembers => 'اعضای سازمان';

  @override
  String get commandPaletteBrowseTeam => 'مرور تیم';

  @override
  String get commandPaletteBrowseTeamDesc => 'دیدن همهٔ اعضای سازمان';

  @override
  String get compactDone => 'گفتگو فشرده شد. تاریخچهٔ قبلی در یک خلاصه جمع شد.';

  @override
  String get compactNothing =>
      'هنوز چیزی برای فشرده کردن نیست. گفتگو هنوز کوتاه است.';

  @override
  String get compactBusy =>
      'یک عامل هنوز کار می‌کند. پس از پایان نوبت فشرده کنید.';

  @override
  String get compactUnavailable => 'فشرده‌سازی روی این سرور در دسترس نیست.';

  @override
  String get commandsMentionSection => 'فرمان‌ها';

  @override
  String get comment => 'نظر';

  @override
  String get commentOnThisFile => 'نظر روی این فایل';

  @override
  String get commented => 'نظر داده شد';

  @override
  String get commits => 'کامیت‌ها';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'نمایش آخرین ⁨$loaded⁩ از ⁨$total⁩ کامیت';
  }

  @override
  String get prCloneProgressCloningTitle => 'در حال کلون مخزن';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'این PR $fileCount فایل را تغییر می‌دهد که از حد GitHub API بیشتر است. در حال کلون محلی مخزن…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'این PR از حد فایل GitHub API بیشتر است. در حال کلون محلی مخزن…';

  @override
  String get prCloneProgressFetchingTitle => 'در حال واکشی refهای PR';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'در حال واکشی شاخهٔ پایه و ref سر PR…';

  @override
  String get prCloneProgressComputingTitle => 'در حال محاسبهٔ دیف';

  @override
  String get prCloneProgressComputingSubtitle =>
      'در حال اجرای git diff به‌صورت محلی…';

  @override
  String get prCloneProgressErrorTitle => 'بارگذاری دیف ناموفق بود';

  @override
  String get prCloneProgressErrorSubtitle =>
      'هنگام کلون یا محاسبهٔ دیف خطایی رخ داد. تازه‌سازی را امتحان کنید.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'هنوز در حال کار… $elapsed گذشته';
  }

  @override
  String confidenceLabel(int percent) {
    return 'اطمینان: $percent٪';
  }

  @override
  String get configureAgentIdentities =>
      'هویت، پرامپت و مهارت عامل‌ها را پیکربندی کنید و اجراها را ببینید.';

  @override
  String get configureDefaultRunners =>
      'آداپتور و مدل پیش‌فرض برای فضاهای جدید و تولید عنوان را پیکربندی کنید.';

  @override
  String get configuredLabel => 'پیکربندی شد.';

  @override
  String get confirmedBy => 'تأییدشده توسط';

  @override
  String get consensus => 'اجماع';

  @override
  String get contentHint => 'چه چیزی باید به خاطر سپرده شود';

  @override
  String get contentLabel => 'محتوا';

  @override
  String get contentMarkdown => 'محتوا (Markdown)';

  @override
  String get contextWindowSize => 'اندازهٔ پنجرهٔ زمینه';

  @override
  String modelContextChip(String size) {
    return 'مدل · ⁨$size⁩';
  }

  @override
  String get continueLabel => 'ادامه';

  @override
  String get conversationMode => 'حالت';

  @override
  String cookieRulesCount(int count) {
    return '$count قاعدهٔ کوکی';
  }

  @override
  String get copied => 'کپی شد!';

  @override
  String get copy => 'کپی';

  @override
  String get copyAddress => 'کپی نشانی';

  @override
  String get copyBaseBranchTooltip => 'کپی نام شاخهٔ پایه';

  @override
  String get copyHeadBranchTooltip => 'کپی نام شاخهٔ سر';

  @override
  String couldNotListDevices(String error) {
    return 'فهرست دستگاه‌ها ممکن نشد: ⁨$error⁩';
  }

  @override
  String get create => 'ایجاد';

  @override
  String get createOrSelectWorkspace =>
      'پیش از افزودن مخزن، یک فضای کاری ایجاد یا انتخاب کنید.';

  @override
  String get createPullRequest => 'ایجاد pull request';

  @override
  String get createdByMe => 'ایجادشده توسط من';

  @override
  String createdLabel(String date) {
    return 'ایجادشده: $date';
  }

  @override
  String get currentParticipants => 'مشارکت‌کنندگان فعلی';

  @override
  String get customCapabilitiesDescription => 'شرح قابلیت‌های سفارشی';

  @override
  String get customSystemPrompt => 'پرامپت سیستم سفارشی برای این عامل…';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count روز پیش',
      one: '1 روز پیش',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'غیرفعال‌سازی';

  @override
  String get defaultCapabilities => 'قابلیت‌های پیش‌فرض · فضاهای جدید';

  @override
  String get defaultChat => 'گفتگوی پیش‌فرض';

  @override
  String get defaultRunners => 'اجراکننده‌های پیش‌فرض';

  @override
  String get delete => 'حذف';

  @override
  String get deleteAgent => 'حذف عامل';

  @override
  String deleteAgentConfirm(String name) {
    return '«⁨$name⁩» حذف شود؟ این کار برگشت‌ناپذیر است.';
  }

  @override
  String get deleteSpace => 'حذف فضا';

  @override
  String deleteConfirmName(String name) {
    return '«⁨$name⁩» حذف شود؟';
  }

  @override
  String get archiveConversation => 'بایگانی گفتگو';

  @override
  String get deleteFact => 'حذف واقعیت';

  @override
  String get deleteFeedBody =>
      'این خوراک و همهٔ مقاله‌های کش‌شده‌اش حذف می‌شوند. مقاله‌های نشانک‌شده از این خوراک هم برداشته می‌شوند.';

  @override
  String deleteFeedConfirm(String name) {
    return '«⁨$name⁩» حذف شود؟';
  }

  @override
  String get deletePolicy => 'حذف سیاست';

  @override
  String get deletePolicyConfirm =>
      'این سیاست حذف شود؟ این کار برگشت‌ناپذیر است.';

  @override
  String deleteTopicConfirm(String topic) {
    return '«⁨$topic⁩» حذف شود؟ این کار برگشت‌ناپذیر است.';
  }

  @override
  String get deleteWorkspace => 'حذف فضای کاری';

  @override
  String get deny => 'رد';

  @override
  String get detailsLabel => 'جزئیات';

  @override
  String get descriptionLabel => 'شرح';

  @override
  String detectedBackend(String label) {
    return 'تشخیص‌داده‌شده: ⁨$label⁩';
  }

  @override
  String get detectedRunners => 'اجراکننده‌های تشخیص‌داده‌شده';

  @override
  String get detectingAdapters => 'در حال تشخیص آداپتورها…';

  @override
  String get detectingInputDevices => 'در حال تشخیص دستگاه‌های ورودی…';

  @override
  String detectionFailed(String error) {
    return 'تشخیص ناموفق: ⁨$error⁩';
  }

  @override
  String get disabled => 'غیرفعال';

  @override
  String get discover => 'کشف';

  @override
  String get dismissed => 'نادیده گرفته شد';

  @override
  String get domainHint => 'مثلاً ⁨api-performance⁩';

  @override
  String get domainLabel => 'دامنه';

  @override
  String get download => 'دانلود';

  @override
  String get downloadingLabel => 'در حال دانلود';

  @override
  String downloadingModel(int pct) {
    return 'در حال دانلود مدل… $pct٪';
  }

  @override
  String get draft => 'پیش‌نویس';

  @override
  String get draftLabel => 'پیش‌نویس';

  @override
  String get edit => 'ویرایش';

  @override
  String get edited => 'ویرایش‌شده';

  @override
  String get editMessage => 'ویرایش پیام';

  @override
  String get revertToThere => 'بازگردانی تا آنجا';

  @override
  String get sendAsNewMessage => 'ارسال به‌عنوان پیام جدید';

  @override
  String get editMessageChoiceBody =>
      'بازگردانی پیام‌های بعد از این را پنهان می‌کند و فایل‌های عامل را برمی‌گرداند. می‌توانید آن را واگرد کنید. ارسال به‌عنوان پیام جدید گفتگو را همان‌طور که هست نگه می‌دارد.';

  @override
  String get deleteMessage => 'حذف پیام';

  @override
  String get deleteMessageConfirm =>
      'این پیام حذف شود؟ این کار برگشت‌ناپذیر است.';

  @override
  String get messageDeleted => 'پیام حذف شد';

  @override
  String get searchInConversation => 'جستجو در گفتگو';

  @override
  String get searchMessagesHint => 'جستجوی پیام‌ها…';

  @override
  String get noMessagesFound => 'پیامی یافت نشد';

  @override
  String get editFact => 'ویرایش واقعیت';

  @override
  String get editPolicy => 'ویرایش سیاست';

  @override
  String get editSuggestedCodeHint => 'ویرایش کد پیشنهادی…';

  @override
  String get editSuggestion => 'ویرایش پیشنهاد';

  @override
  String get egArchitect => 'مثلاً ⁨architect⁩';

  @override
  String get egControlCenter => 'مثلاً ⁨control-center⁩';

  @override
  String get egPlatform => 'مثلاً Platform';

  @override
  String get egSamuelAlev => 'مثلاً ⁨SamuelAlev⁩';

  @override
  String get egSoftwareArchitect => 'مثلاً معمار نرم‌افزار';

  @override
  String get egTheVerge => 'مثلاً The Verge';

  @override
  String get egTokenLimit => 'مثلاً ⁨128000⁩';

  @override
  String embeddingInstallFailed(String error) {
    return 'نصب ناموفق: ⁨$error⁩';
  }

  @override
  String get embeddingInstalled =>
      'مدل امبدینگ محلی نصب شد. جستجوی ترکیبی فعال است.';

  @override
  String get embeddingModel => 'مدل امبدینگ (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'نصب نشده. جستجو تا فعال‌سازی فقط کلیدواژه‌ای است.';

  @override
  String get embeddingRedownloadBody =>
      'فایل‌های مدل موجود حذف و دوباره دانلود می‌شوند. جستجوی معنایی تا پایان دانلود در دسترس نیست.';

  @override
  String get embeddingRemoveBody =>
      'جستجوی معنایی تا نصب مجدد غیرفعال می‌شود. هر وقت می‌توانید دوباره نصب کنید.';

  @override
  String get speakerDiarization => 'تفکیک گوینده';

  @override
  String get diarizationModel => 'مدل تفکیک گوینده';

  @override
  String get diarizationInstalled =>
      'نصب‌شده — گویندگان را در رونوشت جلسه نام‌گذاری می‌کند';

  @override
  String get diarizationNotInstalled => 'نصب نشده — گویندگان جلسه جدا نمی‌شوند';

  @override
  String diarizationInstallFailed(String error) {
    return 'نصب ناموفق: ⁨$error⁩';
  }

  @override
  String get redownloadDiarizationModel => 'دانلود دوبارهٔ مدل تفکیک گوینده';

  @override
  String get diarizationRedownloadBody =>
      'مدل‌های تفکیک فعلی حذف و دوباره دانلود می‌شوند.';

  @override
  String get removeDiarizationModel => 'حذف مدل تفکیک گوینده';

  @override
  String get diarizationRemoveBody =>
      'مدل‌های تفکیک روی دستگاه حذف می‌شوند. رونوشت‌های از قبل تولیدشده دست نخورده می‌مانند.';

  @override
  String get enableNotifications => 'فعال‌سازی اعلان‌ها';

  @override
  String get enableSandboxing => 'فعال‌سازی سندباکس';

  @override
  String get enabled => 'فعال';

  @override
  String errorCreatingAgent(String error) {
    return 'خطا در ایجاد عامل: ⁨$error⁩';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'خطا در حذف عامل: ⁨$error⁩';
  }

  @override
  String errorWithDetail(String error) {
    return 'خطا: ⁨$error⁩';
  }

  @override
  String get expand => 'گستردن';

  @override
  String extractingModel(int pct) {
    return 'در حال استخراج مدل… $pct٪';
  }

  @override
  String get fact => 'واقعیت';

  @override
  String factCount(int count) {
    return '$count واقعیت';
  }

  @override
  String factCountPlural(int count) {
    return '$count واقعیت';
  }

  @override
  String get facts => 'واقعیت‌ها';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount واقعیت · $policyCount سیاست';
  }

  @override
  String get failed => 'ناموفق';

  @override
  String failedToDispatch(String error) {
    return 'اعزام ناموفق: ⁨$error⁩';
  }

  @override
  String get failedToLoad => 'بارگذاری ناموفق بود';

  @override
  String failedToLoadAgents(String error) {
    return 'بارگذاری عامل‌ها ناموفق: ⁨$error⁩';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'بارگذاری خوراک‌ها ناموفق: ⁨$error⁩';
  }

  @override
  String get failedToLoadGifs => 'بارگذاری GIFها ناموفق بود';

  @override
  String failedToLoadLogs(String error) {
    return 'بارگذاری گزارش‌ها ناموفق: ⁨$error⁩';
  }

  @override
  String get failedToLoadRepos => 'بارگذاری مخزن‌ها ناموفق بود';

  @override
  String get failedToLoadWorkspaces => 'بارگذاری فضاهای کاری ناموفق بود';

  @override
  String failedToStartAiReview(String error) {
    return 'شروع بازبینی AI ناموفق: ⁨$error⁩';
  }

  @override
  String get failedToStartMicTest => 'شروع آزمایش میکروفون ناموفق بود.';

  @override
  String failedToSubmitReview(String error) {
    return 'ارسال بازبینی ناموفق: ⁨$error⁩';
  }

  @override
  String failedToUpload(String name, String error) {
    return 'بارگذاری ⁨$name⁩ ناموفق: ⁨$error⁩';
  }

  @override
  String failedWithError(String error) {
    return 'ناموفق: ⁨$error⁩';
  }

  @override
  String get failure => 'شکست';

  @override
  String get feedAlreadyExists => 'خوراکی با این URL از قبل وجود دارد.';

  @override
  String get feedUrlExample => 'مثلاً ⁨https://example.com/feed.xml⁩';

  @override
  String get feedUrlLabel => 'URL خوراک';

  @override
  String feedsCount(int count) {
    return 'خوراک‌ها ($count)';
  }

  @override
  String get filesChanged => 'فایل‌های تغییرکرده';

  @override
  String filesCount(int count) {
    return '$count فایل';
  }

  @override
  String get filesMentionSection => 'فایل‌ها';

  @override
  String get filterAgents => 'فیلتر عامل‌ها…';

  @override
  String get filterFilesHint => 'فیلتر فایل‌ها…';

  @override
  String get filterLists => 'فهرست‌های فیلتر';

  @override
  String get filterSkillsPlaceholder => 'فیلتر مهارت‌ها…';

  @override
  String get finish => 'پایان';

  @override
  String get fix => 'رفع';

  @override
  String get forward => 'جلو';

  @override
  String get gatesGithubPatPush =>
      'تزریق GitHub PAT را محدود می‌کند. برای پوش عامل لازم است.';

  @override
  String get general => 'عمومی';

  @override
  String get githubLink => 'پیوند GitHub';

  @override
  String get claudeStatusFetchFailed =>
      'دسترسی به ⁨status.claude.com⁩ ممکن نشد';

  @override
  String get claudeStatusOpenInBrowser => 'باز کردن ⁨status.claude.com⁩';

  @override
  String get githubStatusFetchFailed => 'دسترسی به ⁨githubstatus.com⁩ ممکن نشد';

  @override
  String get githubDegradedTitle => 'GitHub مشکلاتی گزارش می‌کند';

  @override
  String githubDegradedStatusLine(String status) {
    return 'وضعیت GitHub: ⁨$status⁩.';
  }

  @override
  String githubDegradedBody(String status) {
    return 'وضعیت GitHub: ⁨$status⁩. دادهٔ pull request تا بازیابی ممکن است کهنه یا ناقص باشد.';
  }

  @override
  String get githubStatusOpenInBrowser => 'باز کردن ⁨githubstatus.com⁩';

  @override
  String get githubStatusRefresh => 'تازه‌سازی';

  @override
  String githubStatusUpdated(String time) {
    return 'به‌روزرسانی $time';
  }

  @override
  String get kimiStatusFetchFailed => 'دسترسی به ⁨status.moonshot.cn⁩ ممکن نشد';

  @override
  String get kimiStatusOpenInBrowser => 'باز کردن ⁨status.moonshot.cn⁩';

  @override
  String get openaiStatusFetchFailed =>
      'دسترسی به ⁨status.openai.com⁩ ممکن نشد';

  @override
  String get openaiStatusOpenInBrowser => 'باز کردن ⁨status.openai.com⁩';

  @override
  String get serviceStatusMaintenance => 'نگهداری';

  @override
  String get serviceStatusMajorIssues => 'مشکلات عمده';

  @override
  String get serviceStatusMinorIssues => 'مشکلات جزئی';

  @override
  String get serviceStatusOperational => 'عملیاتی';

  @override
  String get serviceStatusOutage => 'قطعی';

  @override
  String get serviceStatusTitle => 'وضعیت سرویس';

  @override
  String get serviceStatusUnknown => 'ناشناخته';

  @override
  String lastChecked(String time) {
    return 'بررسی‌شده $time';
  }

  @override
  String get lastCheckedRecently => 'به‌تازگی بررسی شده';

  @override
  String get giveYourWorkAHome => 'برای کارتان خانه‌ای بسازید.';

  @override
  String get goBack => 'بازگشت';

  @override
  String get goForward => 'جلو';

  @override
  String get googleFonts => 'فونت‌های Google';

  @override
  String get high => 'بالا';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ساعت پیش',
      one: '1 ساعت پیش',
    );
    return '$_temp0';
  }

  @override
  String get images => 'تصاویر';

  @override
  String get inactive => 'غیرفعال';

  @override
  String get install => 'نصب';

  @override
  String get installRequired => 'نصب لازم است';

  @override
  String installedVersion(String version) {
    return 'نصب‌شده ⁨$version⁩';
  }

  @override
  String get invite => 'دعوت';

  @override
  String get inviteAgent => 'دعوت عامل';

  @override
  String get isolateAgentExecution => 'اجرای عامل را جدا کنید.';

  @override
  String get justNow => 'همین حالا';

  @override
  String get keepSandboxing => 'نگه داشتن سندباکس';

  @override
  String get keybindingAddARepositoryDescription => 'افزودن یک مخزن';

  @override
  String get keybindingAddRepository => 'افزودن مخزن';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'نشانک‌گذاری یا برداشتن نشانک مقالهٔ انتخاب‌شده';

  @override
  String get keybindingCommandPalette => 'پالت فرمان';

  @override
  String get keybindingCreateANewAgentDescription => 'ایجاد عامل جدید';

  @override
  String get keybindingCreateANewWorkspaceDescription => 'ایجاد فضای کاری جدید';

  @override
  String get keybindingFocusSearch => 'تمرکز روی جستجو';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'تمرکز روی فیلد جستجوی pull request';

  @override
  String get keybindingNewAgent => 'عامل جدید';

  @override
  String get keybindingNewWorkspace => 'فضای کاری جدید';

  @override
  String get keybindingNextArticle => 'مقالهٔ بعدی';

  @override
  String get keybindingNextSpace => 'فضای بعدی';

  @override
  String get keybindingNextWorkspace => 'فضای کاری بعدی';

  @override
  String get keybindingOpenArticle => 'باز کردن مقاله';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'باز یا بستن پنجرهٔ تعویض فضای کاری در نوار کناری';

  @override
  String get keybindingOpenPr => 'باز کردن PR';

  @override
  String get keybindingOpenSettings => 'باز کردن تنظیمات';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'باز کردن تنظیمات برنامه';

  @override
  String get keybindingOpenTheCommandPaletteDescription =>
      'باز کردن پالت فرمان';

  @override
  String get keybindingOpenTheSelectedArticleDescription =>
      'باز کردن مقالهٔ انتخاب‌شده';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'باز کردن pull request انتخاب‌شده';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'باز کردن فضای کاری انتخاب‌شده';

  @override
  String get keybindingOpenWorkspace => 'باز کردن فضای کاری';

  @override
  String get keybindingPreviousArticle => 'مقالهٔ قبلی';

  @override
  String get keybindingPreviousSpace => 'فضای قبلی';

  @override
  String get keybindingPreviousWorkspace => 'فضای کاری قبلی';

  @override
  String get keybindingRefresh => 'تازه‌سازی';

  @override
  String get keybindingRefreshAllFeedsDescription => 'تازه‌سازی همهٔ خوراک‌ها';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'تازه‌سازی فهرست pull request';

  @override
  String get keybindingRescanForAdaptersDescription => 'اسکن دوبارهٔ آداپتورها';

  @override
  String get keybindingSelectTheNextArticleDescription => 'انتخاب مقالهٔ بعدی';

  @override
  String get keybindingSelectTheNextSpaceDescription => 'انتخاب فضای بعدی';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'انتخاب مقالهٔ قبلی';

  @override
  String get keybindingSelectThePreviousSpaceDescription => 'انتخاب فضای قبلی';

  @override
  String get keybindingSendMessage => 'ارسال پیام';

  @override
  String get keybindingSendTheCurrentMessageDescription => 'ارسال پیام فعلی';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'تغییر بین حالت روشن و تاریک';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'رفتن به هشتمین فضای کاری';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'رفتن به پنجمین فضای کاری';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'رفتن به اولین فضای کاری';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'رفتن به چهارمین فضای کاری';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'رفتن به فضای کاری بعدی';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'رفتن به نهمین فضای کاری';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'رفتن به فضای کاری قبلی';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'رفتن به دومین فضای کاری';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'رفتن به هفتمین فضای کاری';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'رفتن به ششمین فضای کاری';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'رفتن به سومین فضای کاری';

  @override
  String get keybindingToggleBookmark => 'تغییر وضعیت نشانک';

  @override
  String get keybindingToggleTheme => 'تغییر تم';

  @override
  String get keybindingToggleWorkspaceSwitcher =>
      'تغییر وضعیت تعویض‌گر فضای کاری';

  @override
  String get keybindingWorkspace1 => 'فضای کاری 1';

  @override
  String get keybindingWorkspace2 => 'فضای کاری 2';

  @override
  String get keybindingWorkspace3 => 'فضای کاری 3';

  @override
  String get keybindingWorkspace4 => 'فضای کاری 4';

  @override
  String get keybindingWorkspace5 => 'فضای کاری 5';

  @override
  String get keybindingWorkspace6 => 'فضای کاری 6';

  @override
  String get keybindingWorkspace7 => 'فضای کاری 7';

  @override
  String get keybindingWorkspace8 => 'فضای کاری 8';

  @override
  String get keybindingWorkspace9 => 'فضای کاری 9';

  @override
  String get keybindings => 'میانبرهای صفحه‌کلید';

  @override
  String get keybindingsDescription =>
      'همهٔ میانبرهای صفحه‌کلید. میانبرها ثابت‌اند و قابل تخصیص مجدد نیستند.';

  @override
  String get killRunning => 'کشتن در حال اجرا';

  @override
  String get languageSystem => 'سیستم';

  @override
  String get leaveACommentEllipsis => 'نظری بگذارید…';

  @override
  String get legendLabel => 'راهنما';

  @override
  String get lessLabel => 'کمتر';

  @override
  String get letsPluginTools => 'ابزارهایتان را وصل کنیم.';

  @override
  String get level => 'سطح';

  @override
  String get loadingAgents => 'در حال بارگذاری عامل‌ها…';

  @override
  String get loadingModels => 'در حال بارگذاری مدل‌ها…';

  @override
  String get loadingProviders => 'در حال بارگذاری ارائه‌دهنده‌ها…';

  @override
  String get logLevel => 'سطح گزارش';

  @override
  String get logs => 'گزارش‌ها';

  @override
  String get low => 'پایین';

  @override
  String get maintenance => 'نگهداری';

  @override
  String get manageParticipants => 'مدیریت مشارکت‌کنندگان';

  @override
  String get manageWorkspaces => 'مدیریت فضاهای کاری';

  @override
  String get reorderWorkspace => 'تغییر ترتیب فضای کاری';

  @override
  String get matchOsAppearance =>
      'با ظاهر سیستم‌عامل هماهنگ کنید یا حالت ثابتی انتخاب کنید.';

  @override
  String get mcpAuthToken => 'توکن احراز هویت MCP';

  @override
  String get mcpNotAvailableOnServer =>
      'کنترل سرور MCP روی سرور متصل در دسترس نیست.';

  @override
  String get modelManagedOnServer =>
      'این مدل روی میزبان سرور اجرا می‌شود و آنجا مدیریت می‌شود.';

  @override
  String get mcpServer => 'سرور MCP';

  @override
  String get medium => 'متوسط';

  @override
  String get memoryDataHint =>
      'با کار عامل‌ها واقعیت‌ها و سیاست‌ها اینجا ظاهر می‌شوند.';

  @override
  String get memoryLabel => 'حافظه';

  @override
  String get merge => 'ادغام';

  @override
  String get merged => 'ادغام‌شده';

  @override
  String get messagePlaceholder => 'پیام… (@ برای منشن، / برای فرمان‌ها)';

  @override
  String get navConversations => 'فضاها';

  @override
  String get microphonePermissionDenied => 'مجوز میکروفون رد شد.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دقیقه پیش',
      one: '1 دقیقه پیش',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'مدل';

  @override
  String get modified => 'تغییریافته';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ماه پیش',
      one: '1 ماه پیش',
    );
    return '$_temp0';
  }

  @override
  String get moreLabel => 'بیشتر';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'نام';

  @override
  String get nameAndTitleRequired => 'نام و عنوان لازم است.';

  @override
  String get nameAndUrlRequired => 'نام و URL لازم است';

  @override
  String get nameLabel => 'نام';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'سندباکس بومی روی ⁨$platform⁩ در دسترس است.';
  }

  @override
  String get nativeSandboxNeedsInstall => 'نصب سندباکس بومی لازم است';

  @override
  String get navObservability => 'مشاهده‌پذیری';

  @override
  String get navSettings => 'تنظیمات';

  @override
  String networkBlockCount(int count) {
    return '$count مسدودسازی شبکه';
  }

  @override
  String get neutral => 'خنثی';

  @override
  String get newCommitsPushed =>
      'کامیت‌های جدید پوش شد — برای بارگذاری دوبارهٔ دیف کلیک کنید';

  @override
  String get newFact => 'واقعیت جدید';

  @override
  String get newPolicy => 'سیاست جدید';

  @override
  String get newsfeed => 'خوراک خبری';

  @override
  String get newsfeedLabel => 'خوراک خبری';

  @override
  String get newsfeedSettingsDescription =>
      'خوراک‌های اشتراک‌شده و ترجیحات خواننده را مدیریت کنید.';

  @override
  String get newsfeedSettingsTitle => 'تنظیمات خوراک خبری';

  @override
  String get nextMatch => 'مورد بعدی (↵)';

  @override
  String get noActiveWorkspace => 'فضای کاری یا مخزن فعالی انتخاب نشده.';

  @override
  String get noActiveWorkspaceCreate => 'فضای کاری فعالی نیست';

  @override
  String get noActiveWorkspaceGithub => 'فضای کاری فعالی با مخزن GitHub نیست.';

  @override
  String get noAgents => 'عاملی نیست';

  @override
  String get noArticlesYet => 'هنوز مقاله‌ای نیست';

  @override
  String get noArticlesYetBody => 'مقاله‌های خوراک‌هایتان اینجا ظاهر می‌شوند.';

  @override
  String get noExecutionLogsYet => 'هنوز گزارش اجرایی نیست';

  @override
  String get noFacts => 'هنوز واقعیتی نیست';

  @override
  String get noFeedsYet => 'هنوز خوراکی نیست';

  @override
  String get noFileAnchor => 'لنگر فایلی نیست — نمی‌توان نظر درون‌خطی گذاشت.';

  @override
  String get noFileChangesInScope => 'تغییر فایلی در این محدوده نیست';

  @override
  String get noGifsFound => 'GIFی یافت نشد';

  @override
  String get noInputDevicesDetected =>
      'دستگاه ورودی تشخیص داده نشد — از پیش‌فرض سیستم استفاده می‌شود.';

  @override
  String get noMatchingFiles => 'فایل مطابقی نیست';

  @override
  String get noMatchingGoogleFonts => 'فونت Google مطابقی نیست.';

  @override
  String get noMemoryData => 'هنوز دادهٔ حافظه نیست';

  @override
  String get noMessagesYet => 'هنوز پیامی نیست';

  @override
  String get noModelsAdvertised => 'این آداپتور مدلی اعلام نکرده است.';

  @override
  String get noOpenPullRequests => 'pull request بازی نیست';

  @override
  String get noPolicies => 'هنوز سیاستی نیست';

  @override
  String get noReposInWorkspaceYet => 'هنوز مخزنی در این فضای کاری نیست';

  @override
  String get noRunnersDetected =>
      'هنوز اجراکننده‌ای تشخیص داده نشده. برای اسکن دوباره تازه‌سازی کنید.';

  @override
  String get noSavedArticles => 'مقالهٔ ذخیره‌شده‌ای نیست';

  @override
  String get noSavedArticlesBody =>
      'مقاله‌هایی که ذخیره می‌کنید اینجا ظاهر می‌شوند.';

  @override
  String noShortcutsMatch(String query) {
    return 'هیچ میانبری با «⁨$query⁩» جور نیست';
  }

  @override
  String get noSystemFonts => 'فونت سیستمی تشخیص داده نشد.';

  @override
  String get noTokenSet => 'توکنی تنظیم نشده — دسترسی نامحدود است.';

  @override
  String get noWorkingMemory => 'هنوز یادداشت حافظهٔ کاری نیست.';

  @override
  String get noneAllRoles => 'هیچ (همهٔ نقش‌ها)';

  @override
  String get notAvailable => 'در دسترس نیست';

  @override
  String get notConfiguredLabel => 'پیکربندی نشده.';

  @override
  String get notFoundLabel => 'یافت نشد';

  @override
  String get notes => 'یادداشت‌ها';

  @override
  String get notificationAgentFinished => 'عامل تمام کرد';

  @override
  String get notificationPrMentioned => 'در pull request منشن شدید';

  @override
  String get notificationNewMessages => 'پیام‌های جدید';

  @override
  String get notificationPrMerged => 'PR ادغام شد';

  @override
  String get notificationPrPublished => 'PR منتشر شد';

  @override
  String get notificationReviewRequested => 'درخواست بازبینی';

  @override
  String get notifications => 'اعلان‌ها';

  @override
  String get notifyAgentRunCompleted =>
      'وقتی عاملی یک اجرا را تمام می‌کند اعلان بده.';

  @override
  String get notifyPrMentioned =>
      'وقتی در یک pull request منشن می‌شوید اعلان بده.';

  @override
  String get notifyNewMessages =>
      'برای پیام‌های جدید عامل در فضاهای دیگر اعلان بده.';

  @override
  String get notifyPrMerged => 'وقتی یک pull request ادغام می‌شود اعلان بده.';

  @override
  String get notifyPrPublished =>
      'وقتی عاملی یک pull request منتشر می‌کند اعلان بده.';

  @override
  String get notifyReviewRequested =>
      'وقتی بازبینی شما روی یک pull request درخواست می‌شود اعلان بده.';

  @override
  String get notificationReviewStale => 'بازبینی کهنه';

  @override
  String get notifyReviewStale =>
      'وقتی کامیت‌های جدید روی pull requestی که بازبینی کرده‌اید می‌نشیند';

  @override
  String get notificationPrMergeReadiness => 'آمادهٔ ادغام';

  @override
  String get notifyPrMergeReadiness =>
      'وقتی pull requestی که نوشته‌اید قابل ادغام می‌شود یا از آن حالت خارج می‌شود اعلان بده.';

  @override
  String get notificationPrReviewDecision => 'تصمیم‌های بازبینی';

  @override
  String get notifyPrReviewDecision =>
      'وقتی بازبینی تأیید می‌کند، تغییر می‌خواهد یا تأییدش رد می‌شود اعلان بده.';

  @override
  String get notificationPrChecksStatus => 'بررسی‌ها';

  @override
  String get notifyPrChecksStatus =>
      'وقتی CI روی pull request شما شکست می‌خورد و وقتی بازیابی می‌شود اعلان بده.';

  @override
  String get notificationPrThreadActivity => 'رشته‌های بازبینی';

  @override
  String get notifyPrThreadActivity =>
      'وقتی کسی در رشته‌ای که در آن هستید پاسخ می‌دهد یا حلش می‌کند اعلان بده.';

  @override
  String get notificationPrReadyToMerge => 'آمادهٔ ادغام';

  @override
  String notificationPrReadyToMergeBody(String prTitle) {
    return '⁨$prTitle⁩ همهٔ چیزهای لازم را دارد.';
  }

  @override
  String get notificationPrMergeBlocked => 'دیگر قابل ادغام نیست';

  @override
  String notificationPrMergeBlockedBodyConflicts(String prTitle) {
    return '⁨$prTitle⁩ با شاخهٔ پایه تعارض دارد.';
  }

  @override
  String notificationPrMergeBlockedBodyBehind(String prTitle) {
    return '⁨$prTitle⁩ از شاخهٔ پایه عقب است.';
  }

  @override
  String notificationPrMergeBlockedBodyReviews(String prTitle) {
    return '⁨$prTitle⁩ منتظر بازبینی لازم است.';
  }

  @override
  String notificationPrMergeBlockedBodyChanges(String prTitle) {
    return 'یک بازبین روی ⁨$prTitle⁩ درخواست تغییر داد.';
  }

  @override
  String notificationPrMergeBlockedBodyChecks(String prTitle) {
    return 'بررسی‌ها روی ⁨$prTitle⁩ ناموفق‌اند.';
  }

  @override
  String notificationPrMergeBlockedBodyOther(String prTitle) {
    return '⁨$prTitle⁩ دیگر قابل ادغام نیست.';
  }

  @override
  String get notificationPrApproved => 'Pull request تأیید شد';

  @override
  String notificationPrApprovedBodyBy(String login, String prTitle) {
    return '⁨$login⁩ ⁨$prTitle⁩ را تأیید کرد';
  }

  @override
  String notificationPrApprovedBody(String prTitle) {
    return '⁨$prTitle⁩ تأیید شد';
  }

  @override
  String notificationPrReviewersRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بازبین هنوز باید پاسخ دهند',
      one: '1 بازبین هنوز باید پاسخ دهد',
      zero: 'بازبینی باقی نمانده',
    );
    return '$_temp0';
  }

  @override
  String get notificationPrChangesRequested => 'درخواست تغییرات';

  @override
  String notificationPrChangesRequestedBodyBy(String login, String prTitle) {
    return '⁨$login⁩ روی ⁨$prTitle⁩ درخواست تغییر داد';
  }

  @override
  String notificationPrChangesRequestedBody(String prTitle) {
    return 'روی ⁨$prTitle⁩ درخواست تغییر شد';
  }

  @override
  String get notificationPrReviewDismissed => 'تأیید رد شد';

  @override
  String notificationPrReviewDismissedBody(String prTitle) {
    return '⁨$prTitle⁩ دوباره به بازبینی نیاز دارد.';
  }

  @override
  String get notificationPrChecksFailed => 'بررسی‌ها ناموفق';

  @override
  String notificationPrChecksFailedBody(String checkName, String prTitle) {
    return '⁨$checkName⁩ روی ⁨$prTitle⁩ ناموفق شد';
  }

  @override
  String notificationPrChecksFailedBodyUnnamed(String prTitle) {
    return 'بررسی‌ها روی ⁨$prTitle⁩ ناموفق‌اند';
  }

  @override
  String get notificationPrChecksRecovered => 'بررسی‌ها موفق';

  @override
  String notificationPrChecksRecoveredBody(String prTitle) {
    return '⁨$prTitle⁩ دوباره سبز است.';
  }

  @override
  String notificationPrMentionedInCommentBody(String login, String location) {
    return '⁨$login⁩ شما را در ⁨$location⁩ منشن کرد';
  }

  @override
  String get notificationPrThreadReplied => 'پاسخ جدید';

  @override
  String notificationPrThreadRepliedBody(String login, String location) {
    return '⁨$login⁩ در ⁨$location⁩ پاسخ داد';
  }

  @override
  String get notificationPrThreadResolved => 'رشته حل شد';

  @override
  String notificationPrThreadResolvedBody(String location) {
    return 'رشتهٔ شما در ⁨$location⁩ حل شد.';
  }

  @override
  String get notificationGroupAgents => 'عامل‌ها';

  @override
  String get notificationGroupPullRequests => 'Pull requestها';

  @override
  String get notificationGroupMessages => 'پیام‌ها';

  @override
  String get notificationGroupTickets => 'تیکت‌ها';

  @override
  String get notificationGroupCalendar => 'تقویم';

  @override
  String get notificationGroupMachines => 'ماشین‌ها';

  @override
  String get notificationsMutedRepos => 'مخزن‌های بی‌صدا';

  @override
  String notificationsMutedReposCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مخزن بی‌صدا هستند',
      one: '1 مخزن بی‌صداست',
      zero: 'هیچ مخزنی بی‌صدا نیست',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMuteRepo => 'بی‌صدا کردن این مخزن';

  @override
  String get onboardingLinuxDescription =>
      'Control Center می‌تواند از کانتینرهای Linux برای جداسازی اجرای عامل استفاده کند.';

  @override
  String get onboardingMacosDescription =>
      'Control Center روی macOS از سندباکس بومی برای جداسازی اجرای عامل استفاده می‌کند.';

  @override
  String get onboardingUnsupportedDescription =>
      'سندباکس روی این سکو در دسترس نیست. اجرای عامل بدون جداسازی خواهد بود.';

  @override
  String get openArticlesInApp => 'باز کردن مقاله‌ها در برنامه';

  @override
  String get openInBrowser => 'باز کردن در مرورگر';

  @override
  String get openedInYourBrowser => 'در مرورگر شما باز شد.';

  @override
  String get openLabel => 'باز';

  @override
  String get openOnGithub => 'باز کردن در GitHub';

  @override
  String get openStatus => 'باز';

  @override
  String get optionalPersonaDescription => 'شرح پرسونای اختیاری';

  @override
  String get otherLabel => 'سایر';

  @override
  String get ownerOrganization => 'مالک / سازمان';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get passed => 'موفق';

  @override
  String get pasteValueHere => 'مقدار را اینجا جای‌گذاری کنید';

  @override
  String get persona => 'پرسونا';

  @override
  String get policies => 'سیاست‌ها';

  @override
  String get policiesHint =>
      'سیاست‌ها وقتی عامل‌ها واقعیت‌ها را ارتقا دهند اینجا ظاهر می‌شوند.';

  @override
  String get policy => 'سیاست';

  @override
  String get popular => 'محبوب';

  @override
  String get port => 'پورت';

  @override
  String get postingEllipsis => 'در حال ارسال…';

  @override
  String get prCommits => 'کامیت‌ها';

  @override
  String get prMergedBody => 'یک pull request ادغام شد';

  @override
  String get prMoreActions => 'کنش‌های بیشتر';

  @override
  String get prTitle => 'عنوان PR';

  @override
  String get reviewCommentHint =>
      'فقط تأیید کنید، یا اگر حوصله دارید نظر یا واکنشی اضافه کنید…';

  @override
  String get nothingToPreview => 'چیزی برای پیش‌نمایش نیست';

  @override
  String get previousMatch => 'مورد قبلی (⇧↵)';

  @override
  String get priorityReviewsDescription =>
      'بازبینی‌های اولویت‌دار و نمای کلی مخزن.';

  @override
  String get prsCreated => 'PRهای ایجادشده';

  @override
  String get prsMerged => 'PRهای ادغام‌شده';

  @override
  String get publishToGithub => 'انتشار در GitHub';

  @override
  String get published => 'منتشرشده';

  @override
  String get pullRequestApproved => 'Pull request تأیید شد';

  @override
  String get pullRequests => 'Pull requestها';

  @override
  String get questionLabel => 'پرسش';

  @override
  String get queued => 'در صف';

  @override
  String get react => 'واکنش';

  @override
  String get readPrsIssuesMetadata =>
      'به عامل اجازه می‌دهد PRها، ایشوها و فرادادهٔ مخزن را بخواند.';

  @override
  String get readerPreferences => 'ترجیحات خواننده';

  @override
  String get reasoningEffort => 'تلاش استدلال';

  @override
  String get recommendLabel => 'پیشنهاد';

  @override
  String recordingFromDevice(String device) {
    return 'ضبط از ⁨$device⁩.';
  }

  @override
  String get redownload => 'دانلود دوباره';

  @override
  String get redownloadEmbeddingModel => 'مدل امبدینگ دوباره دانلود شود؟';

  @override
  String get redownloadVoiceModel => 'مدل صوتی دوباره دانلود شود؟';

  @override
  String get refinePlan => 'پالایش برنامه';

  @override
  String get refresh => 'تازه‌سازی';

  @override
  String get refreshAll => 'تازه‌سازی همه';

  @override
  String get refreshAllFeeds => 'تازه‌سازی همهٔ خوراک‌ها';

  @override
  String get reject => 'رد';

  @override
  String get rejected => 'ردشده';

  @override
  String get reload => 'بارگذاری دوباره';

  @override
  String get remove => 'برداشتن';

  @override
  String get removeBookmark => 'برداشتن نشانک';

  @override
  String get removeEmbeddingModel => 'مدل امبدینگ حذف شود؟';

  @override
  String get removeLogo => 'حذف لوگو';

  @override
  String get removeRepoFromWorkspace => 'مخزن از فضای کاری برداشته شود؟';

  @override
  String get removeVoiceModel => 'مدل صوتی حذف شود؟';

  @override
  String get removed => 'برداشته شد';

  @override
  String get renamed => 'تغییر نام یافت';

  @override
  String get reopen => 'بازگشایی';

  @override
  String get resolve => 'حل';

  @override
  String get replyEllipsis => 'پاسخ…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '⁨$name⁩ از این فضای کاری برداشته می‌شود. فایل‌های محلی روی دیسک دست نخورده می‌مانند.';
  }

  @override
  String repoAccessNoticeBody(String repos) {
    return 'اعتبارنامهٔ GitHub سرور ⁨$repos⁩ را نمی‌بیند. اگر مخزن به سازمانی تعلق دارد، GitHub App را آنجا نصب کنید یا توکنی با دسترسی وصل کنید.';
  }

  @override
  String repoAccessNoticeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'دسترسی به $count مخزن ممکن نیست',
      one: 'دسترسی به یک مخزن ممکن نیست',
    );
    return '$_temp0';
  }

  @override
  String get repoAccessNoticeSuspendedTitle => 'نصب GitHub App معلق شده است';

  @override
  String repoAccessNoticeSuspendedBody(String repos) {
    return 'آخرین داده‌های شناخته‌شده برای ⁨$repos⁩ نمایش داده می‌شود. نصب را در GitHub از سر بگیرید یا توکنی با دسترسی وصل کنید.';
  }

  @override
  String get repoNoAccessBadge => 'بدون دسترسی';

  @override
  String get reportsTo => 'گزارش به';

  @override
  String reposCount(int count) {
    return 'مخزن‌ها ($count)';
  }

  @override
  String get reposDescription =>
      'checkoutهای محلی که این فضای کاری هدف می‌گیرد.';

  @override
  String get repositories => 'مخزن‌ها';

  @override
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'افزودن $count مخزن',
      one: 'افزودن 1 مخزن',
    );
    return '$_temp0 ممکن نشد: ⁨$error⁩';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مخزن افزوده شد',
      one: 'مخزن افزوده شد',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => 'تنظیمات مخزن‌ها';

  @override
  String get repositoryName => 'نام مخزن';

  @override
  String get requestChanges => 'درخواست تغییرات';

  @override
  String get requested => 'درخواست‌شده';

  @override
  String get requestedChanges => 'تغییرات درخواست‌شده';

  @override
  String requiredRoleLabel(String role) {
    return 'نقش لازم: ⁨$role⁩';
  }

  @override
  String get requiredRoleOptional => 'نقش لازم (اختیاری)';

  @override
  String get requirements => 'الزامات';

  @override
  String get reset => 'بازنشانی';

  @override
  String get resolved => 'حل‌شده';

  @override
  String get enclosedTerminalTitle => 'ترمینال محفظه‌ای';

  @override
  String get enclosedTerminalStart => 'باز کردن پوسته';

  @override
  String get enclosedTerminalStartHint =>
      'این پوسته داخل VM یک‌بارمصرف این گفتگو اجرا می‌شود. هنگام باز کردن بوت می‌شود، نه هنگام شروع برنامه.';

  @override
  String get terminalStreamReconnecting =>
      'جریان قطع شد — در حال اتصال دوباره…';

  @override
  String get terminalStreamError => 'خطای جریان:';

  @override
  String get terminalShellExited => 'پوسته خارج شد';

  @override
  String get restartShell => 'راه‌اندازی دوبارهٔ پوسته';

  @override
  String get retry => 'تلاش مجدد';

  @override
  String get review => 'بازبینی';

  @override
  String get reviewedByMe => 'بازبینی‌شده توسط من';

  @override
  String get reviewers => 'بازبین‌ها';

  @override
  String get roleLabel => 'نقش';

  @override
  String get ruleHint => 'قاعدهٔ سیاست (Markdown پشتیبانی می‌شود)';

  @override
  String get ruleLabel => 'قاعده';

  @override
  String get runCompleted => 'اجرا تمام شد';

  @override
  String get running => 'در حال اجرا';

  @override
  String get runningLabel => 'در حال اجرا';

  @override
  String get runs => 'اجراها';

  @override
  String get runsLabel => 'اجراها';

  @override
  String get sandboxBackendNativeLabel => 'سندباکس بومی';

  @override
  String get sandboxBackendMicrovmLabel => 'VM محفظه‌ای';

  @override
  String get sandboxBackendNoneLabel => 'بدون جداسازی';

  @override
  String get sandboxLinuxInstall =>
      'سندباکس بومی روی Linux/WSL2 از bubblewrap استفاده می‌کند. نصب با:\n\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'سندباکس بومی روی macOS داخلی است — از Apple Seatbelt (⁨sandbox-exec⁩) استفاده می‌کند. نصب لازم نیست.';

  @override
  String get sandboxPermissions => 'مجوزهای سندباکس';

  @override
  String get sandboxUnsupported =>
      'سندباکس بومی هنوز روی این سکو پشتیبانی نمی‌شود. به «بدون جداسازی» برمی‌گردد.';

  @override
  String get sandboxingDisabledDescription =>
      'عامل‌ها مستقیم روی میزبان با env کامل اجرا می‌شوند — توصیه نمی‌شود.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'همهٔ فراخوانی‌های عامل از ⁨$backend⁩ می‌گذرند.';
  }

  @override
  String get save => 'ذخیره';

  @override
  String get saveChanges => 'ذخیرهٔ تغییرات';

  @override
  String get adapterArguments => 'آرگومان‌های اضافه';

  @override
  String get adapterArgumentsHint => 'پرچم‌های CLI اضافه (مثلاً ⁨--yolo⁩)';

  @override
  String get addVariable => 'افزودن متغیر';

  @override
  String get environmentVariables => 'متغیرهای محیطی';

  @override
  String get environmentVariablesDescription =>
      'متغیرهای محیطی سفارشی که به این آداپتور پاس می‌شوند (مثلاً کلیدهای API). در keychain ذخیره می‌شوند.';

  @override
  String get variableKey => 'کلید';

  @override
  String get variableValue => 'مقدار';

  @override
  String get savingEllipsis => 'در حال ذخیره…';

  @override
  String get scopeDiffToCommits =>
      'محدود کردن دیف به کامیت‌ها — Shift-کلیک برای بازه';

  @override
  String get noPrsMatchSearch => 'pull request مطابقی نیست';

  @override
  String get searchFactsHint => 'جستجوی واقعیت‌ها…';

  @override
  String get searchFonts => 'جستجوی فونت‌ها…';

  @override
  String get searchGifs => 'جستجوی GIF';

  @override
  String get searchGifsHint => 'جستجوی GIFها…';

  @override
  String get searchInDiffHint => 'جستجو در دیف…';

  @override
  String get searchOrTypeModel => 'جستجو یا تایپ نام مدل…';

  @override
  String get searchPlaceholder => 'جستجو…';

  @override
  String get searchShortcuts => 'جستجوی میانبرها…';

  @override
  String get shortcutUnavailableInBrowser => 'در مرورگر در دسترس نیست';

  @override
  String get searching => 'در حال جستجو…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ثانیه پیش',
      one: '1 ثانیه پیش',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'انتخاب آداپتور';

  @override
  String get selectAdapterFirst => 'ابتدا یک آداپتور انتخاب کنید';

  @override
  String get selectAgentToReportTo => 'عاملی را برای گزارش انتخاب کنید…';

  @override
  String get selectAnAgent => 'یک عامل انتخاب کنید';

  @override
  String get selectConversation => 'یک گفتگو انتخاب کنید';

  @override
  String get selectLabel => 'انتخاب';

  @override
  String get selectRunner => 'یک اجراکننده انتخاب کنید';

  @override
  String get semanticSearch => 'جستجوی معنایی';

  @override
  String get send => 'ارسال';

  @override
  String get sendFirstMessage => 'اولین پیام را بفرستید';

  @override
  String get sendMessage => 'ارسال پیام';

  @override
  String sentFindingsToAgent(int count) {
    return '$count یافته به عامل فرستاده شد.';
  }

  @override
  String setGithubLinkDescription(String name) {
    return 'مالک GitHub و نام مخزن را برای ⁨$name⁩ تنظیم کنید. برای حل ارجاع‌های PR و ایشو مثل ⁨#123⁩ در محتوای Markdown استفاده می‌شود.';
  }

  @override
  String get setLabel => 'تنظیم';

  @override
  String get setToken => 'تنظیم توکن';

  @override
  String get settingsLabel => 'تنظیمات';

  @override
  String get settingsLanguage => 'زبان';

  @override
  String get settingsLanguageDescription => 'زبان برنامه را انتخاب کنید.';

  @override
  String get shortTask => 'کار کوتاه';

  @override
  String get showNativeNotifications =>
      'اعلان‌های سیستم را برای رویدادها نشان بده.';

  @override
  String get showSuperseded => 'نمایش منسوخ‌شده‌ها';

  @override
  String get signedIn => 'وارد شده‌اید.';

  @override
  String signedInAs(String username) {
    return 'وارد شده به‌عنوان ⁨$username⁩.';
  }

  @override
  String get skillNameRequired => 'نام مهارت لازم است.';

  @override
  String skillSaved(String name) {
    return 'مهارت «⁨$name⁩» ذخیره شد.';
  }

  @override
  String get skillsSourcesTab => 'منابع';

  @override
  String get skillSourcesDisclaimer =>
      'مهارت‌ها از مخزن‌های GitHub که اضافه می‌کنید نصب می‌شوند. فرادادهٔ مخزن غیرقابل اعتماد است — اسکن آنتی‌ویروس سیگنال ایمنی واقعی است.';

  @override
  String get skillSourcesEmpty => 'مخزن مهارتی نیست';

  @override
  String get skillSourcesEmptyHint =>
      'یک مخزن GitHub اضافه کنید تا مهارت‌هایش را ببینید.';

  @override
  String get skillSourceAdd => 'افزودن مخزن';

  @override
  String get skillSourceAddTitle => 'افزودن مخزن مهارت';

  @override
  String get skillSourceAddHint => 'https://github.com/owner/repo';

  @override
  String get skillSourceInvalidUrl =>
      'یک URL مخزن GitHub وارد کنید (⁨https://github.com/owner/repo⁩).';

  @override
  String skillSourceAdded(String repo) {
    return 'مخزن ⁨$repo⁩ افزوده شد.';
  }

  @override
  String skillSourceAlreadyAdded(String repo) {
    return 'مخزن ⁨$repo⁩ از قبل افزوده شده.';
  }

  @override
  String skillSourceRemoved(String repo) {
    return 'مخزن ⁨$repo⁩ برداشته شد.';
  }

  @override
  String get skillSourceRemove => 'برداشتن';

  @override
  String skillSourceRemoveConfirmTitle(String repo) {
    return '⁨$repo⁩ برداشته شود؟';
  }

  @override
  String get skillSourceRemoveConfirmBody =>
      'مهارت‌های نصب‌شده نصب می‌مانند. فقط کاتالوگ مخزن برداشته می‌شود.';

  @override
  String get skillSourceNoSkills =>
      'مهارتی در این مخزن یافت نشد (مهارت پوشه‌ای است که ⁨SKILL.md⁩ دارد).';

  @override
  String get skillSourceRefresh => 'تازه‌سازی';

  @override
  String get skillSourceInstalledBadge => 'نصب‌شده';

  @override
  String get skillSourceUpdateBadge => 'به‌روزرسانی موجود';

  @override
  String get skillSourceSlugTaken => 'نام در حال استفاده';

  @override
  String skillSourceFilesCount(num count) {
    return '$count فایل';
  }

  @override
  String get skillSourceReadme => 'README';

  @override
  String get skillSourceNoReadme => 'این مهارت README ندارد.';

  @override
  String get skillSourceNoMatches => 'مهارتی با فیلتر شما جور نیست.';

  @override
  String get skillUpdateAction => 'به‌روزرسانی';

  @override
  String get skillUninstallAction => 'حذف نصب';

  @override
  String skillUninstallConfirmTitle(String slug) {
    return '«⁨$slug⁩» حذف نصب شود؟';
  }

  @override
  String skillUninstalled(String slug) {
    return 'مهارت «⁨$slug⁩» حذف نصب شد.';
  }

  @override
  String get skillFindingLine => 'خط';

  @override
  String get skillInstallAnywayOverride => 'ریسک را می‌فهمم — به‌هرحال نصب کن';

  @override
  String skillInstalled(String slug) {
    return 'مهارت «⁨$slug⁩» نصب شد.';
  }

  @override
  String get skillPreviewCapabilities => 'قابلیت‌ها';

  @override
  String get skillPreviewFindings => 'یافته‌ها';

  @override
  String get skillPreviewGuardedActions => 'کنش‌های محافظت‌شده';

  @override
  String get skillPreviewLlmReviewed => 'بازبینی‌شده با LLM';

  @override
  String get skillPreviewNoCapabilities => 'قابلیتی اعلام نشده.';

  @override
  String get skillPreviewNoFindings => 'یافته‌ای نیست.';

  @override
  String get skillPreviewScanning => 'در حال اسکن مهارت…';

  @override
  String get skillPreviewVerdictLabel => 'حکم اسکن';

  @override
  String get skillPreviewVerdictPass => 'موفق';

  @override
  String get skillPreviewVerdictQuarantine => 'قرنطینه';

  @override
  String get skillPreviewVerdictWarn => 'هشدار';

  @override
  String get skillQuarantineWarning =>
      'اسکنر این مهارت را قرنطینه کرد. نصبش روی ماشین شما کد اجرا می‌کند. فقط اگر به منبع اعتماد دارید و یافته‌ها را دیده‌اید ادامه دهید.';

  @override
  String skillDetachedFromAgents(String agents) {
    return 'قرنطینه و از عامل‌ها جدا شد: ⁨$agents⁩';
  }

  @override
  String get skillNotScanned => 'اسکن نشده';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => 'دستی';

  @override
  String get skillOriginRegistry => 'رجیستری';

  @override
  String get skillOriginRuntimeLocal => 'ران‌تایم محلی';

  @override
  String get skillRulesStale => 'اسکن کهنه';

  @override
  String get skillSaveAnywayOverride => 'ریسک را می‌فهمم — به‌هرحال ذخیره کن';

  @override
  String get skillSaveBlockedBody => 'محتوا پیش از هر نوشتنی مسدود شد.';

  @override
  String get skillSaveBlockedTitle => 'ذخیره با دروازهٔ اسکن مسدود شد';

  @override
  String get skillScanAction => 'اسکن';

  @override
  String get skillScanAll => 'اسکن همه';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass موفق · $warn هشدار · $quarantine قرنطینه';
  }

  @override
  String get skillStateDrifted => 'از زمان نصب تغییر کرده';

  @override
  String get skillStateUnmanaged => 'مدیریت‌نشده';

  @override
  String get skillSeverityBlocked => 'مسدود';

  @override
  String get skillSeverityWarn => 'هشدار';

  @override
  String get skillsInstalledTab => 'نصب‌شده';

  @override
  String get skills => 'مهارت‌ها';

  @override
  String get skipAcceptRisk => 'رد شو — ریسک را می‌پذیرم';

  @override
  String get skipForNow => 'فعلاً رد شو';

  @override
  String get skipSandboxing => 'رد شدن از سندباکس';

  @override
  String get skipSandboxingDialogContent =>
      'مطمئنید می‌خواهید سندباکس را رد کنید؟ این به عامل‌ها اجازه می‌دهد بدون جداسازی روی سیستم شما کد اجرا کنند.';

  @override
  String get somethingWentWrong => 'مشکلی پیش آمد';

  @override
  String sourceCount(int count) {
    return '$count منبع';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count منبع';
  }

  @override
  String get sourceFacts => 'واقعیت‌های منبع:';

  @override
  String get splitDiff => 'دیف شکافته (کنار هم)';

  @override
  String get startLabel => 'شروع';

  @override
  String get startOnAppLaunch => 'شروع هنگام راه‌اندازی برنامه';

  @override
  String get statusLabel => 'وضعیت';

  @override
  String get onboardingStepConnect => 'اتصال';

  @override
  String get onboardingStepWorkspace => 'فضای کاری';

  @override
  String get onboardingStepSandbox => 'سندباکس';

  @override
  String get onboardingStepAdapter => 'آداپتور';

  @override
  String get onboardingStepVoice => 'صدا';

  @override
  String get stop => 'توقف';

  @override
  String get stopped => 'متوقف';

  @override
  String get strictIdentityCheck => 'بررسی هویت سخت‌گیرانه';

  @override
  String get success => 'موفقیت';

  @override
  String get successLabel => 'موفقیت';

  @override
  String get suggestAChange => 'پیشنهاد یک تغییر';

  @override
  String get suggestLabel => 'پیشنهاد';

  @override
  String get superseded => 'منسوخ';

  @override
  String get synced => 'همگام‌شده';

  @override
  String get systemDefault => 'پیش‌فرض سیستم';

  @override
  String get systemFonts => 'فونت‌های سیستم';

  @override
  String get systemPrompt => 'پرامپت سیستم';

  @override
  String get systemPromptLabel => 'پرامپت سیستم';

  @override
  String get talkToControlCenter => 'با Control Center حرف بزنید.';

  @override
  String get taskMentionSection => 'کار';

  @override
  String get testLabel => 'آزمایش';

  @override
  String get theme => 'تم';

  @override
  String get themeDark => 'تاریک';

  @override
  String get themeLight => 'روشن';

  @override
  String get themeSystem => 'سیستم';

  @override
  String get thisCannotBeUndone => 'این کار برگشت‌ناپذیر است.';

  @override
  String get ticketLabel => 'تیکت';

  @override
  String get titleLabel => 'عنوان';

  @override
  String get todayLabel => 'امروز';

  @override
  String get toggleTheme => 'تغییر تم';

  @override
  String get tokenConfigured =>
      'پیکربندی شد — کلاینت‌ها باید این توکن را ارائه کنند.';

  @override
  String get topic => 'موضوع';

  @override
  String get topicHint => 'مثلاً پشتهٔ فنی، نظام طراحی';

  @override
  String get totalRuns => 'کل اجراها';

  @override
  String trackingParamsCount(int count) {
    return '$count پارامتر ردیابی';
  }

  @override
  String get typeCommandOrSearch => 'فرمانی تایپ کنید یا جستجو کنید…';

  @override
  String get typography => 'تایپوگرافی';

  @override
  String get unavailable => 'در دسترس نیست';

  @override
  String get unifiedDiff => 'دیف یکپارچه';

  @override
  String get unknownAuthor => 'ناشناخته';

  @override
  String get unnamedAgent => 'عامل بی‌نام';

  @override
  String get updateKey => 'به‌روزرسانی کلید';

  @override
  String get updateLabel => 'به‌روزرسانی';

  @override
  String get updateToken => 'به‌روزرسانی توکن';

  @override
  String updatedDaysAgo(int count) {
    return '$count روز پیش به‌روزرسانی شد';
  }

  @override
  String updatedHoursAgo(int count) {
    return '$count ساعت پیش به‌روزرسانی شد';
  }

  @override
  String get updatedJustNow => 'همین حالا به‌روزرسانی شد';

  @override
  String updatedMinutesAgo(int count) {
    return '$count دقیقه پیش به‌روزرسانی شد';
  }

  @override
  String get useSandbox => 'استفاده از سندباکس';

  @override
  String get useWorkspaceDefault => 'استفاده از پیش‌فرض فضای کاری';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      'خالی بگذارید تا User-Agent پیش‌فرض برنامه استفاده شود. بعضی سایت‌ها User-Agentهای غیرمرورگر را مسدود می‌کنند.';

  @override
  String get usingSystemDefaultMicrophone =>
      'از میکروفون پیش‌فرض سیستم استفاده می‌شود.';

  @override
  String get viewLabel => 'نمایش';

  @override
  String get viewLogs => 'نمایش گزارش‌ها';

  @override
  String voiceInstallFailed(String error) {
    return 'نصب ناموفق: ⁨$error⁩';
  }

  @override
  String get voiceModelNotInstalled =>
      'نصب نشده. یک‌بار حدود 200 MB دانلود می‌شود؛ کاملاً روی دستگاه اجرا می‌شود.';

  @override
  String get voiceModelNotInstalledLabel => 'مدل صوتی نصب نشده.';

  @override
  String get voiceRedownloadBody =>
      'فایل‌های مدل موجود حذف و آرشیو حدود 200 MB دوباره دانلود می‌شود. رونویسی صدا تا پایان دانلود در دسترس نیست.';

  @override
  String get voiceRemoveBody =>
      'رونویسی صدا تا نصب مجدد غیرفعال می‌شود. هر وقت می‌توانید دوباره نصب کنید.';

  @override
  String get voiceTranscription => 'رونویسی صدا';

  @override
  String get weakIsolationDescription =>
      'جداسازی ضعیف — فقط مرز فضای نام، بدون مرز هسته.';

  @override
  String get whenOffNoDefaultRoute =>
      'وقتی خاموش است، سندباکس بدون مسیر پیش‌فرض بوت می‌شود.';

  @override
  String get whenOffServerStaysStopped =>
      'وقتی خاموش است، سرور تا وقتی خودتان شروعش کنید متوقف می‌ماند.';

  @override
  String get speechModel => 'مدل گفتار';

  @override
  String get speechModelHint =>
      'برای رونویسی جلسه و میکروفون ویرایشگر پیام استفاده می‌شود.';

  @override
  String get voiceModelInstalled =>
      'نصب‌شده. رونویسی جلسه و دکمهٔ میکروفون ویرایشگر را تغذیه می‌کند.';

  @override
  String get meetingMicSilentWarning =>
      'میکروفونتان ممکن است بی‌صدا باشد — دیگران صحبت می‌کنند اما چیزی به میکروفون شما نمی‌رسد.';

  @override
  String get meetingSummaryPrivacyNotice =>
      'ضبط و رونویسی روی این ماشین می‌ماند. خلاصه را یک عامل می‌نویسد؛ اگر مدل ابری باشد رونوشت و یادداشت‌ها به آن ارائه‌دهنده فرستاده می‌شود.';

  @override
  String get meetingTemplates => 'قالب‌های یادداشت جلسه';

  @override
  String get meetingTemplatesHint =>
      'خلاصهٔ AI را برای نوعی جلسه شکل دهید. قالب فعال روی خلاصه‌های جدید و اجرای دوباره اعمال می‌شود.';

  @override
  String get meetingTemplateActive => 'قالب فعال';

  @override
  String get meetingTemplateAdd => 'افزودن قالب';

  @override
  String get meetingTemplateNewTitle => 'قالب جدید';

  @override
  String get meetingTemplateEditTitle => 'ویرایش قالب';

  @override
  String get meetingTemplateNameLabel => 'نام';

  @override
  String get meetingTemplateNameHint => 'مثلاً بازبینی اسپرینت';

  @override
  String get meetingTemplateInstructionsLabel => 'دستورالعمل‌ها';

  @override
  String get meetingTemplateInstructionsHint =>
      'AI چطور این یادداشت‌ها را ساختار دهد و برجسته کند؟';

  @override
  String get workingMemory => 'حافظهٔ کاری';

  @override
  String get workspaceName => 'نام فضای کاری';

  @override
  String get workspaceScopedSkills =>
      'فایل‌های مهارت محدود به فضای کاری که به عامل‌ها پیوست شده‌اند.';

  @override
  String get workspaces => 'فضاهای کاری';

  @override
  String get writePrivateNotes => 'یادداشت خصوصی، مشاهده و برنامه بنویسید…';

  @override
  String get writeSkillContent => 'محتوای مهارت را اینجا بنویسید (Markdown)…';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سال پیش',
      one: '1 سال پیش',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'دیروز';

  @override
  String get focusModeStart => 'شروع نشست تمرکز';

  @override
  String get focusModeConfigTitle => 'شروع نشست تمرکز';

  @override
  String get focusModeGoalLabel => 'هدف';

  @override
  String get focusModeGoalHint => 'روی چه چیزی کار می‌کنید؟';

  @override
  String get focusModeDurationLabel => 'مدت';

  @override
  String get focusModeBlockNotifications => 'مسدود کردن اعلان‌ها';

  @override
  String get focusModeStartButton => 'شروع';

  @override
  String get focusModeFloat => 'کوچک کردن به نوار';

  @override
  String get focusModeActiveTooltip =>
      'حالت تمرکز فعال — برای پایان ضربه بزنید';

  @override
  String get dismiss => 'نادیده گرفتن';

  @override
  String get acceptAndResolve => 'پذیرش و حل';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'حدود $minutes دقیقه در حال بازبینی بوده‌اید — پژوهش نشان می‌دهد کیفیت بازبینی پس از 60 دقیقه افت می‌کند. استراحت کنید.';
  }

  @override
  String get notificationSound => 'صدای اعلان';

  @override
  String get notificationSoundDescription =>
      'صدایی که هنگام نمایش اعلان پخش می‌شود.';

  @override
  String get notificationSoundNone => 'هیچ';

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
  String get notificationSoundMigrosSoft => 'Migros (ملایم)';

  @override
  String get notificationSoundMigrosHard => 'Migros (قوی)';

  @override
  String get notificationSoundSbb => 'SBB';

  @override
  String get notificationSoundCff => 'CFF';

  @override
  String get notificationSoundFfs => 'FFS';

  @override
  String get notificationSoundPost => 'Post';

  @override
  String get notificationSoundTest => 'آزمایش';

  @override
  String get notificationVolume => 'بلندی صدا';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'PRای از ⁨@$login⁩ در این فضای کاری نیست';
  }

  @override
  String get usersLabel => 'کاربران';

  @override
  String get mergePullRequest => 'ادغام pull request';

  @override
  String get forceMergePullRequest => 'ادغام اجباری pull request';

  @override
  String get closePullRequest => 'بستن pull request';

  @override
  String get closePullRequestConfirm =>
      'مطمئنید می‌خواهید این pull request را ببندید؟';

  @override
  String get stackedPullRequests => 'Pull requestهای پشته‌شده';

  @override
  String partOfStack(int position, int total) {
    return 'بخشی از پشته ($position از $total)';
  }

  @override
  String get createStack => 'ایجاد پشته';

  @override
  String get createStackDialogTitle => 'ایجاد پشتهٔ pull request';

  @override
  String createStackDialogBody(int count) {
    return 'این $count pull request از پایین به بالا پشته می‌شوند:';
  }

  @override
  String get createStackInvalidSelection =>
      'دست‌کم دو pull request از یک مخزن انتخاب کنید تا پشته بسازید';

  @override
  String get createStackNotAChain =>
      'pull requestهای انتخاب‌شده زنجیره نمی‌سازند: شاخهٔ پایهٔ هر کدام باید شاخهٔ سر قبلی باشد';

  @override
  String get createStackAlreadyStacked =>
      'یک یا چند pull request انتخاب‌شده از قبل در پشته‌اند';

  @override
  String get stackCreated => 'پشته ایجاد شد';

  @override
  String get stackCreationFailed => 'ایجاد پشته ممکن نشد';

  @override
  String get squashAndMerge => 'اسکواش و ادغام';

  @override
  String get createMergeCommit => 'ایجاد کامیت ادغام';

  @override
  String get rebaseAndMerge => 'ریبیس و ادغام';

  @override
  String get commitTitle => 'عنوان کامیت';

  @override
  String get commitDescription => 'شرح کامیت';

  @override
  String get pullRequestMerged => 'Pull request ادغام شد';

  @override
  String get pullRequestClosed => 'Pull request بسته شد';

  @override
  String failedToMergePr(String error) {
    return 'ادغام ناموفق: ⁨$error⁩';
  }

  @override
  String failedToClosePr(String error) {
    return 'بستن ناموفق: ⁨$error⁩';
  }

  @override
  String get markReadyForReview => 'آماده برای بازبینی';

  @override
  String get markReadyForReviewConfirm =>
      'این pull request از پیش‌نویس خارج می‌شود. بازبین‌ها مطلع می‌شوند، بررسی‌های لازم ادغام را محدود می‌کنند و هر خودکاری که منتظر PR آماده است اجرا می‌شود.';

  @override
  String get convertToDraft => 'تبدیل به پیش‌نویس';

  @override
  String get convertToDraftConfirm =>
      'این pull request به پیش‌نویس برمی‌گردد. درخواست‌های بازبینی در انتظار رد می‌شوند و تا دوباره آماده‌اش نکنید قابل ادغام نیست.';

  @override
  String get pullRequestMarkedReady => 'Pull request برای بازبینی آماده شد';

  @override
  String get pullRequestConvertedToDraft => 'Pull request به پیش‌نویس تبدیل شد';

  @override
  String failedToMarkPrReady(String error) {
    return 'آماده‌سازی برای بازبینی ناموفق: ⁨$error⁩';
  }

  @override
  String failedToConvertPrToDraft(String error) {
    return 'تبدیل به پیش‌نویس ناموفق: ⁨$error⁩';
  }

  @override
  String get checksFailing => 'بررسی‌ها ناموفق';

  @override
  String get reviewsPending => 'بعضی بازبینی‌ها در انتظارند';

  @override
  String get mergeConflictsWithBase =>
      'این شاخه تعارض‌هایی دارد که باید حل شوند';

  @override
  String get branchOutOfDateWithBase =>
      'این شاخه نسبت به شاخهٔ پایه به‌روز نیست';

  @override
  String get mergeBlockedByBranchProtection =>
      'محافظت شاخه این ادغام را مسدود می‌کند';

  @override
  String get confirm => 'تأیید';

  @override
  String get trustedSitesSectionTitle => 'سایت‌های مورد اعتماد';

  @override
  String get trustedSitesEmpty =>
      'سایت مورد اعتمادی نیست. دامنه‌ای اضافه کنید تا مسدودسازی روی آن خاموش شود.';

  @override
  String get addTrustedSite => 'افزودن سایت مورد اعتماد';

  @override
  String get removeTrustedSite => 'برداشتن';

  @override
  String get disableBlockingForThisSite => 'خاموش کردن مسدودسازی روی این سایت';

  @override
  String get enableBlockingForThisSite => 'روشن کردن مسدودسازی روی این سایت';

  @override
  String get enterDomainHint => 'مثلاً ⁨example.com⁩';

  @override
  String get invalidDomain => 'یک دامنهٔ معتبر وارد کنید (مثلاً ⁨example.com⁩)';

  @override
  String get pageLoadTimedOut =>
      'بارگذاری صفحه زمان‌پر شد. دوباره بارگذاری کنید یا در مرورگر باز کنید.';

  @override
  String get pipelinesScreenTitle => 'پایپ‌لاین‌ها';

  @override
  String get pipelinesScreenSubtitle => 'گردش‌کارهای چندگامی اعلانی عامل';

  @override
  String get pipelinesRunPipeline => 'اجرای پایپ‌لاین';

  @override
  String get pipelineRunLauncherTitle => 'اجرای پایپ‌لاین';

  @override
  String get pipelineRunSubtitle =>
      'یک پایپ‌لاین انتخاب کنید و ورودی‌هایش را پر کنید تا اجرا شروع شود.';

  @override
  String get pipelineRunNoInputsBadge => 'بدون ورودی';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ورودی',
      one: '1 ورودی',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'این پایپ‌لاین ورودی نمی‌گیرد.';

  @override
  String get pipelineRunSubmit => 'اجرای پایپ‌لاین';

  @override
  String get pipelineRunCouldNotStart => 'شروع اجرا ممکن نشد.';

  @override
  String pipelineRunStarted(String name) {
    return '⁨$name⁩ شروع شد';
  }

  @override
  String get pipelineRunEmptyTitle => 'پایپ‌لاینی آمادهٔ اجرا نیست';

  @override
  String get pipelineRunEmptyHint =>
      'یک پایپ‌لاین را فعال کنید و اجرای دستی را در ویرایشگرش روشن کنید تا اینجا راه‌اندازی شود.';

  @override
  String get pipelineRunManageTemplates => 'مدیریت پایپ‌لاین‌ها';

  @override
  String get pipelineRunSettingsTitle => 'اجرای دستی';

  @override
  String get pipelineRunSettingsAllow => 'اجازهٔ اجرای دستی';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'این پایپ‌لاین را در صفحهٔ اجرا نشان بده تا دستی شروع شود.';

  @override
  String get pipelineRunSettingsConcurrencyTitle => 'همزمانی';

  @override
  String get pipelineRunSettingsMaxParallel => 'حداکثر اجراهای موازی';

  @override
  String get pipelineRunSettingsMaxParallelHelp =>
      'برای نامحدود خالی بگذارید. اجراهای اضافه در صف می‌مانند و با آزاد شدن جا شروع می‌شوند.';

  @override
  String get pipelineRunSettingsMaxParallelHint => 'نامحدود';

  @override
  String get pipelineRunSettingsMaxParallelInvalid =>
      'یک عدد صحیح 1 یا بیشتر وارد کنید، یا برای نامحدود خالی بگذارید.';

  @override
  String get pipelineRunSettingsInputsTitle => 'ورودی‌ها';

  @override
  String get pipelineRunSettingsAddInput => 'افزودن ورودی';

  @override
  String get pipelineRunSettingsNoInputs => 'هنوز ورودی نیست.';

  @override
  String get pipelineInputEditTitle => 'فیلد ورودی';

  @override
  String get pipelineInputKeyLabel => 'کلید';

  @override
  String get pipelineInputKeyHelp =>
      'کلید حالت که مقدار زیر آن ذخیره می‌شود (مثلاً ⁨repo_full_name⁩).';

  @override
  String get pipelineInputLabelLabel => 'برچسب';

  @override
  String get pipelineInputTypeLabel => 'نوع';

  @override
  String get pipelineInputOptionsLabel => 'گزینه‌ها (جدا با ویرگول)';

  @override
  String get pipelineInputDefaultLabel => 'مقدار پیش‌فرض';

  @override
  String get pipelineInputPlaceholderLabel => 'نگه‌دار متن';

  @override
  String get pipelineInputHelpLabel => 'متن راهنما';

  @override
  String get pipelineInputRequiredLabel => 'الزامی';

  @override
  String get pipelineInputTypeText => 'متن';

  @override
  String get pipelineInputTypeMultiline => 'متن چندخطی';

  @override
  String get pipelineInputTypeNumber => 'عدد';

  @override
  String get pipelineInputTypeBoolean => 'کلید';

  @override
  String get pipelineInputTypeSelect => 'انتخاب';

  @override
  String get pipelinesEmpty => 'هنوز اجرای پایپ‌لاینی نیست';

  @override
  String get pipelinesEmptyHint => 'برای شروع روی «اجرای پایپ‌لاین» کلیک کنید.';

  @override
  String get pipelinesNoSteps => 'هنوز گامی ثبت نشده';

  @override
  String get pipelinesNoActiveWorkspace =>
      'یک فضای کاری انتخاب کنید تا پایپ‌لاین‌هایش را ببینید';

  @override
  String pipelinesLoadError(String error) {
    return 'بارگذاری پایپ‌لاین‌ها ناموفق: ⁨$error⁩';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'شروع پایپ‌لاین ناموفق: ⁨$error⁩';
  }

  @override
  String get pipelineStatusPending => 'در انتظار';

  @override
  String get pipelineStatusQueued => 'در صف';

  @override
  String get pipelineStatusRunning => 'در حال اجرا';

  @override
  String get pipelineStatusSuspended => 'معلق';

  @override
  String get pipelineStatusCompleted => 'کامل‌شده';

  @override
  String get pipelineStatusFailed => 'ناموفق';

  @override
  String get pipelineStatusCancelled => 'لغوشده';

  @override
  String get pipelineStatusSkipped => 'ردشده';

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed از $total گام';
  }

  @override
  String get pipelineWaterfallTimeline => 'خط زمانی';

  @override
  String pipelineWaterfallActive(String duration) {
    return 'فعال $duration';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return 'بیکار $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip =>
      'زمان خارج از مجموع فعال: اجرا متوقف بوده یا بین گام‌ها منتظر مانده.';

  @override
  String get pipelineStepStarted => 'شروع‌شده';

  @override
  String get pipelineStepFinished => 'تمام‌شده';

  @override
  String get pipelineStepDurationLabel => 'مدت';

  @override
  String get pipelineStepBranch => 'شاخه';

  @override
  String get pipelineStepViewConversation => 'نمایش گفتگو';

  @override
  String get pipelineStepError => 'خطا';

  @override
  String get pipelineStepInput => 'ورودی';

  @override
  String get pipelineStepOutput => 'خروجی';

  @override
  String get pipelineStepNotExecuted => 'هنوز اجرا نشده';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'ناموفق در ⁨$step⁩';
  }

  @override
  String get pipelineRunTriggerManual => 'دستی';

  @override
  String get pipelineStepSkippedReason => 'ردشده';

  @override
  String get pipelineStepPriorAttempts => 'تلاش‌های قبلی';

  @override
  String get pipelineStepAttemptLabel => 'تلاش';

  @override
  String pipelineStepAttemptN(int number) {
    return 'تلاش $number';
  }

  @override
  String get pipelineStepAttemptInterrupted => 'قطع‌شده';

  @override
  String get pipelineRunColumnPipeline => 'پایپ‌لاین';

  @override
  String get pipelineRunColumnDuration => 'مدت';

  @override
  String get pipelineRunQueueNext => 'بعدی';

  @override
  String pipelineRunQueuePosition(int position) {
    return '$position در صف';
  }

  @override
  String get pipelineRunColumnStarted => 'شروع‌شده';

  @override
  String get pipelineRunHistory => 'تاریخچهٔ اجرا';

  @override
  String get pipelineRunHistoryEmpty => 'هنوز اجرای دیگری نیست';

  @override
  String pipelineRunRerunAgo(String time) {
    return 'اجرای دوباره $time';
  }

  @override
  String pipelineRunAttempt(int number) {
    return 'تلاش $number';
  }

  @override
  String pipelineRunFirstStarted(String time) {
    return 'اولین شروع $time';
  }

  @override
  String get pipelineRunFilterAll => 'همه';

  @override
  String get pipelineRunFilterEmpty => 'اجرایی با این فیلتر جور نیست';

  @override
  String get relativeJustNow => 'همین حالا';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دقیقه پیش',
      one: '1 دقیقه پیش',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ساعت پیش',
      one: '1 ساعت پیش',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count روز پیش',
      one: '1 روز پیش',
    );
    return '$_temp0';
  }

  @override
  String get teamsTitle => 'تیم‌ها';

  @override
  String get teamsAddTeam => 'افزودن تیم';

  @override
  String get teamsLoadError => 'بارگذاری تیم‌ها ممکن نشد';

  @override
  String get teamsEmptyTitle => 'هنوز تیمی نیست';

  @override
  String get teamsEmptyDescription =>
      'عامل‌ها را در تیم‌ها گروه‌بندی کنید تا کار تخصیص‌یافته به تیم از رهبر بگذرد و تفویض شود.';

  @override
  String get teamCreateTitle => 'تیم جدید';

  @override
  String get teamEditTitle => 'ویرایش تیم';

  @override
  String get teamNameLabel => 'نام تیم';

  @override
  String get teamNameHint => 'مثلاً فرانت‌اند';

  @override
  String get teamDescriptionLabel => 'شرح';

  @override
  String get teamDescriptionHint => 'این تیم مسئول چیست';

  @override
  String get teamLeaderLabel => 'رهبر';

  @override
  String get teamLeaderHelp =>
      'هماهنگ‌کننده‌ای که کار تخصیص‌یافته به تیم را می‌گیرد و به مناسب‌ترین عضو تفویض می‌کند.';

  @override
  String get teamNoLeader => 'بدون رهبر';

  @override
  String get teamInstructionsLabel => 'دستورالعمل عملیاتی';

  @override
  String get teamInstructionsHelp =>
      'به بریفینگ رهبر اضافه می‌شود — قراردادهای تیم، قواعد تشدید، لحن.';

  @override
  String get teamInstructionsHint => 'اختیاری';

  @override
  String get teamSaved => 'تیم ذخیره شد';

  @override
  String get teamMembersError => 'بارگذاری اعضا ممکن نشد';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عضو',
      one: '1 عضو',
      zero: 'بدون عضو',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => 'افزودن عضو';

  @override
  String get teamAddMemberTitle => 'افزودن اعضا';

  @override
  String teamAddMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'افزودن $count',
      one: 'افزودن 1',
      zero: 'افزودن',
    );
    return '$_temp0';
  }

  @override
  String get teamNoAgentsToAdd => 'همهٔ عامل‌ها از قبل در این تیم‌اند.';

  @override
  String get teamRemoveMember => 'برداشتن از تیم';

  @override
  String get teamLeaderBadge => 'رهبر';

  @override
  String get teamUnknownAgent => 'عامل ناشناخته';

  @override
  String get teamMembersEmpty => 'هنوز عضوی نیست';

  @override
  String get teamMembersEmptyDescription =>
      'عامل اضافه کنید تا رهبر کسی برای تفویض داشته باشد.';

  @override
  String get teamSelectPrompt => 'یک تیم انتخاب کنید';

  @override
  String get teamSelectPromptDescription =>
      'تیمی از فهرست انتخاب کنید، یا یکی جدید بسازید.';

  @override
  String get teamDeleteTitle => 'تیم حذف شود؟';

  @override
  String teamDeleteBody(String name) {
    return '⁨$name⁩ حذف می‌شود. عامل‌هایش تحت تأثیر نیستند.';
  }

  @override
  String get teamHasLeaderTooltip => 'رهبر دارد';

  @override
  String get pipelineTemplatesNav => 'قالب‌های پایپ‌لاین';

  @override
  String get pipelineTemplatesTitle => 'قالب‌های پایپ‌لاین';

  @override
  String get pipelineTemplatesSubtitle =>
      'ویرایشگر کشیدن‌ورها کردن برای پایپ‌لاین‌هایی که عامل‌ها را ارکستر می‌کنند.';

  @override
  String get pipelineTemplatesNew => 'قالب جدید';

  @override
  String get pipelineTemplatesEmpty =>
      'هنوز قالب پایپ‌لاینی نیست. یکی بسازید تا شروع کنید.';

  @override
  String get pipelineTemplateBuiltInBadge => 'داخلی';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'قالب حذف شود؟';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'قالب پایپ‌لاین ⁨$name⁩ حذف شود؟ این کار برگشت‌ناپذیر است.';
  }

  @override
  String get pipelineTemplateEditorSubtitle =>
      'انواع گره را از نوار کناری به بوم بکشید، سپس به هم وصل کنید.';

  @override
  String get unsavedChanges => 'تغییرات ذخیره‌نشده';

  @override
  String get nodeLibraryTitle => 'کتابخانهٔ گره';

  @override
  String get nodeLibraryHint => 'هر مورد را به بوم بکشید تا گره اضافه شود.';

  @override
  String get editorEmptyCanvas => 'گرهی از کتابخانه بکشید تا شروع کنید.';

  @override
  String get pipelineWhenThisHappens => 'وقتی این رخ می‌دهد';

  @override
  String get pipelineDoThis => 'این کار را بکن';

  @override
  String get pipelineAddStep => 'افزودن گام';

  @override
  String get pipelineTidyUp => 'مرتب‌سازی چیدمان';

  @override
  String get pipelineEditorHint =>
      'گام‌ها را بکشید تا بچینید · دستگیره‌ای بکشید تا وصل کنید';

  @override
  String get pipelineRemoveConnection => 'برداشتن اتصال';

  @override
  String get pipelineDragToConnect => 'بکشید تا وصل شود';

  @override
  String get pipelineNewDefaultName => 'پایپ‌لاین جدید';

  @override
  String get nodeCategoryTriggers => 'تریگرها';

  @override
  String get triggerEventWebhook => 'Webhook';

  @override
  String get pipelineAddTrigger => 'افزودن تریگر';

  @override
  String get pipelineOnEvent => 'روی رویداد';

  @override
  String get nodeConfigTitle => 'پیکربندی گره';

  @override
  String get nodeConfigKind => 'نوع';

  @override
  String get nodeConfigLabel => 'برچسب';

  @override
  String get nodeConfigAgent => 'عامل';

  @override
  String get nodeConfigAgentHint => 'یک عامل انتخاب کنید…';

  @override
  String get nodeConfigInputKeys => 'کلیدهای ورودی (جدا با ویرگول)';

  @override
  String get nodeConfigInputKeysHelp =>
      'کلیدهای حالتی که این گره مصرف می‌کند. برای جایگزینی نگه‌دار در پرامپت.';

  @override
  String get nodeConfigRepos => 'مخزن‌ها برای کلون';

  @override
  String get nodeConfigReposHelp =>
      'مخزن‌هایی که هنگام شروع گفتگوی این گره کلون و ایندکس می‌شوند. انتخاب همه آن‌ها را کلون می‌کند (پیش‌فرض).';

  @override
  String get nodeConfigRepoBranchHint => 'شاخه (پیش‌فرض)';

  @override
  String get nodeConfigRepoBranchHelp =>
      'شاخه‌ای که هر checkout از آن بریده می‌شود. خالی بگذارید تا شاخهٔ پیش‌فرض خود مخزن؛ worktree باز هم شاخهٔ خودش را می‌گیرد تا کامیت عامل روی این یکی ننشیند.';

  @override
  String nodeConfigReposDynamic(String entries) {
    return 'ورودی‌های پویا نگه داشته شد: ⁨$entries⁩';
  }

  @override
  String get nodeConfigCreateConversation => 'باز کردن گفتگو در آن';

  @override
  String get nodeConfigCreateConversationHelp =>
      'وقتی چند گره عامل دنبال می‌شود خاموش بگذارید — هر کدام جریان نام‌دار خودش را باز می‌کند. وقتی یک گره عامل دنبال می‌شود روشن کنید تا اتاق گفتگوی بی‌عنوان کنارش نشان ندهد.';

  @override
  String get nodeConfigConversationTitle => 'نام گفتگو';

  @override
  String get nodeConfigConversationTitleHelp =>
      'به گره عامل پایین‌دست همان نام را بدهید تا هر دو در یک جریان کار کنند. پیش‌فرض برچسب گره است.';

  @override
  String get nodeConfigSpaceName => 'نام فضا';

  @override
  String get nodeConfigSpaceNameHelp =>
      'نام اتاقی که این گره باز می‌کند. همان نگه‌دارهای حالت پرامپت را پشتیبانی می‌کند. خالی بگذارید تا برچسب گره استفاده شود.';

  @override
  String get nodeConfigSpaceNameHint => 'بازبینی pr_number';

  @override
  String get nodeConfigStreamTitle => 'نام گفتگو';

  @override
  String get nodeConfigStreamTitleHelp =>
      'جریان نام‌داری که عامل این گره داخل اتاق در آن کار می‌کند. همان نگه‌دارهای پرامپت. خالی بگذارید تا نوبت در گفتگوی پایدار اتاق بنشیند، جایی که فن‌اوت عامل‌ها درهم می‌شود.';

  @override
  String get nodeConfigConversationTitleHint => 'تحلیل معماری';

  @override
  String get nodeConfigOutputKey => 'کلید خروجی';

  @override
  String get nodeConfigPrompt => 'قالب پرامپت';

  @override
  String get nodeConfigPromptHelp =>
      'از نگه‌دارهای دوقلاب برای کشیدن مقدار از حالت در زمان اجرا استفاده کنید.';

  @override
  String get nodeConfigScript => 'اسکریپت Bash';

  @override
  String get nodeConfigScriptHelp =>
      'با ⁨bash -c⁩ اجرا می‌شود. ⁨GITHUB_TOKEN⁩ تنظیم است. نگه‌دارها پیش از اجرا جایگزین می‌شوند.';

  @override
  String get nodeConfigRouteKeys => 'کلیدهای مسیر';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'کلید مسیر از ⁨$source⁩';
  }

  @override
  String get conditionSectionTitle => 'شرط';

  @override
  String get conditionMode => 'حالت';

  @override
  String get conditionModeFilesAny => 'فایل(ها) وجود دارند — هر کدام';

  @override
  String get conditionModeFilesAll => 'فایل‌ها وجود دارند — همه';

  @override
  String get conditionModeComparison => 'مقایسه';

  @override
  String get conditionModeSwitch => 'سوییچ';

  @override
  String get conditionFilePaths => 'مسیرهای فایل';

  @override
  String get conditionFilePathsAnyHelp =>
      'یک مسیر در هر خط، نسبی به پوشهٔ پایه. وقتی هر کدام وجود داشته باشد مسیر true می‌رود.';

  @override
  String get conditionFilePathsAllHelp =>
      'یک مسیر در هر خط، نسبی به پوشهٔ پایه. فقط وقتی همه وجود داشته باشند مسیر true می‌رود.';

  @override
  String get conditionBaseKey => 'کلید پوشهٔ پایه';

  @override
  String get conditionBaseKeyHelp =>
      'کلید حالت که مسیرها نسبت به آن حل می‌شوند (پیش‌فرض ⁨repo_local_path⁩).';

  @override
  String get conditionRecursive => 'جستجو در زیرپوشه‌ها';

  @override
  String get conditionNegate => 'وارونه: وقتی نباشد مسیر true';

  @override
  String get conditionLeft => 'مقدار چپ';

  @override
  String get conditionOperator => 'عملگر';

  @override
  String get conditionRight => 'مقدار راست';

  @override
  String get conditionSwitchKey => 'سوییچ روی کلید حالت';

  @override
  String get conditionCases => 'موارد (جدا با ویرگول)';

  @override
  String get conditionCasesHelp =>
      'کلیدهای مسیر برای تطبیق با مقدار، به ترتیب.';

  @override
  String get conditionDefaultCase => 'مورد پیش‌فرض';

  @override
  String get triggerManualHelp => 'در صفحهٔ اجرا نشان بده و دستی شروع کن.';

  @override
  String get triggerKindSchedule => 'روی یک زمان‌بندی';

  @override
  String get triggerScheduleExprLabel =>
      'زمان‌بندی (⁨cron⁩ یا ⁨every:seconds⁩)';

  @override
  String get triggerTimezoneLabel => 'منطقهٔ زمانی (اختیاری)';

  @override
  String get triggerCatchUpLabel => 'روی اجراهای ازدست‌رفته';

  @override
  String get triggerCatchUpRunOnce => 'یک‌بار اجرا';

  @override
  String get triggerCatchUpSkip => 'رد کردن';

  @override
  String get syncHealthTitle => 'سلامت همگام‌سازی';

  @override
  String get syncHealthNoConfigs => 'هنوز اتصال همگام‌سازی نیست';

  @override
  String get syncHealthNeverSynced => 'هرگز همگام نشده';

  @override
  String get syncOutcomeOk => 'همگام‌شده';

  @override
  String get syncOutcomeFailed => 'ناموفق';

  @override
  String get syncOutcomeSkipped => 'ردشده';

  @override
  String syncHealthFailedStreak(int count) {
    return '$count شکست پیاپی';
  }

  @override
  String get triggerWebhookHelp =>
      'یک URL وب‌هوک امضاشده ساخته می‌شود. سیستم‌های خارجی با POST به آن این پایپ‌لاین را شروع می‌کنند.';

  @override
  String get triggerWebhookPathLabel => 'مسیر وب‌هوک';

  @override
  String get triggerMatchStatusLabel => 'فقط وقتی وضعیت برابر است با';

  @override
  String get triggerSummaryNone => 'بدون تریگر';

  @override
  String triggerEverySeconds(int seconds) {
    return 'هر $secondsث';
  }

  @override
  String get triggerEventManual => 'اجرای دستی';

  @override
  String get triggerEventSchedule => 'زمان‌بندی';

  @override
  String get triggerEventPrStatusChanged => 'وضعیت PR تغییر کرد';

  @override
  String get triggerEventExternalPr => 'PR خارجی باز شد';

  @override
  String get triggerEventPrPublished => 'PR منتشر شد';

  @override
  String get triggerEventPrMerged => 'PR ادغام شد';

  @override
  String get triggerEventRepoAdded => 'مخزن افزوده شد';

  @override
  String get triggerEventCodeGraphWatch => 'تغییر فایل';

  @override
  String pipelineRunCauseChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فایل تغییرکرده',
      one: '1 فایل تغییرکرده',
    );
    return '$_temp0';
  }

  @override
  String pipelineRunCauseMorePaths(int count) {
    return '+$count مورد دیگر';
  }

  @override
  String get pipelineRunCauseRescan => 'تغییر روی دیسک';

  @override
  String get pipelineRunCauseInitial => 'اولین ایندکس این checkout';

  @override
  String get triggerEventMessageReceived => 'پیام دریافت شد';

  @override
  String get triggerEventTicketCompleted => 'تیکت کامل شد';

  @override
  String get triggerEventTicketFailed => 'تیکت ناموفق شد';

  @override
  String get triggerEventTicketCancelled => 'تیکت لغو شد';

  @override
  String get triggerEventBudgetCrossed => 'آستانهٔ بودجه رد شد';

  @override
  String get nodeLibrarySearchHint => 'جستجوی گره‌ها';

  @override
  String get nodeLibraryNoMatches => 'گره مطابقی نیست';

  @override
  String get nodeCategoryFlow => 'جریان و منطق';

  @override
  String get nodeCategoryPr => 'بازبینی PR';

  @override
  String get nodeCategoryAgents => 'عامل‌ها';

  @override
  String get nodeCategoryMessaging => 'پیام‌رسانی';

  @override
  String get nodeCategoryCode => 'کد';

  @override
  String get triggerDisabledTag => 'خاموش';

  @override
  String get pipelineInputTypeRepo => 'مخزن';

  @override
  String get pipelineRunNoRepos => 'هنوز مخزنی در این فضای کاری نیست.';

  @override
  String get allowTicketingApi => 'اجازهٔ فراخوانی‌های API تیکتینگ';

  @override
  String get ticketingApiKey => 'کلید API تیکتینگ';

  @override
  String get ticketingApiKeySubtitle =>
      'کلید API ارائه‌دهندهٔ تیکتینگ را به سندباکس تزریق می‌کند.';

  @override
  String get ticketingProvider => 'ارائه‌دهندهٔ تیکتینگ';

  @override
  String get connectGitHubAndTicketing =>
      'یک میزبان کد وصل کنید تا Control Center بتواند pull requestها، ایشوها و بازبینی‌ها را بخواند. اختیاری یک ارائه‌دهندهٔ تیکتینگ وصل کنید. اعتبارنامه‌ها نزد سرور شماست، نه این ماشین.';

  @override
  String get triggerEventTicketAssigned => 'تیکت تخصیص یافت';

  @override
  String get triggerEventTicketCreated => 'تیکت ایجاد شد';

  @override
  String get triggerEventTicketStatusChanged => 'وضعیت تیکت تغییر کرد';

  @override
  String get triggerEventMeetingRecordingStopped => 'ضبط جلسه متوقف شد';

  @override
  String get triggerEventSkillUpdated => 'مهارت به‌روزرسانی شد';

  @override
  String get triggerEventSpaceDeleted => 'فضا حذف شد';

  @override
  String get triggerExternalPrHelp =>
      'یک pull request که روی میزبان کد باز شده، نه از Control Center.';

  @override
  String get triggerPrPublishedHelp =>
      'یک pull request که از Control Center یا توسط یک عامل باز شده است.';

  @override
  String get triggerPrStatusChangedHelp =>
      'ادغام، بسته، باز، بازگشایی یا تأیید شده. وضعیت را در بازرس فیلتر کنید.';

  @override
  String get triggerPrMergedHelp =>
      'فقط وقتی pull request ادغام می‌شود، نه وقتی بسته یا دوباره باز می‌شود.';

  @override
  String get triggerRepoAddedHelp => 'یک مخزن به این فضای کاری پیوند می‌خورد.';

  @override
  String get triggerCodeGraphWatchHelp =>
      'فایلی در مخزن پیوندشده روی دیسک تغییر می‌کند.';

  @override
  String get triggerMessageReceivedHelp => 'پیام جدیدی در یک فضا می‌رسد.';

  @override
  String get triggerTicketCreatedHelp =>
      'یک تیکت در این فضای کاری ساخته می‌شود.';

  @override
  String get triggerTicketStatusChangedHelp =>
      'یک تیکت بین وضعیت‌ها جابه‌جا می‌شود.';

  @override
  String get triggerTicketCompletedHelp => 'یک تیکت با موفقیت تمام می‌شود.';

  @override
  String get triggerTicketFailedHelp =>
      'اجرای عامل شکست خورد و تیکت به‌عنوان ناموفق علامت می‌خورد.';

  @override
  String get triggerTicketCancelledHelp =>
      'یک تیکت لغو می‌شود و ادامه نمی‌یابد.';

  @override
  String get triggerBudgetCrossedHelp =>
      'حد هزینه فضای کاری یا عامل عبور می‌کند.';

  @override
  String get triggerTicketAssignedHelp =>
      'یک تیکت به شخص، عامل یا تیم اختصاص می‌یابد.';

  @override
  String get triggerMeetingRecordingStoppedHelp => 'ضبط یک جلسه تمام می‌شود.';

  @override
  String get triggerSkillUpdatedHelp => 'یک مهارت نصب یا به‌روزرسانی می‌شود.';

  @override
  String get triggerSpaceDeletedHelp => 'یک فضای گفتگو حذف می‌شود.';

  @override
  String get navTickets => 'تیکت‌ها';

  @override
  String get ticketsTitle => 'تیکت‌ها';

  @override
  String get newTicket => 'تیکت جدید';

  @override
  String get noTicketsYet => 'هنوز تیکتی نیست';

  @override
  String get addCollaborator => 'افزودن همکار';

  @override
  String get noCollaborators => 'هنوز همکاری نیست';

  @override
  String get linkedPullRequests => 'Pull requestهای پیوندشده';

  @override
  String get noLinkedPullRequests => 'هنوز pull request پیوندشده‌ای نیست';

  @override
  String get stopAgent => 'توقف عامل';

  @override
  String get ticketProperties => 'ویژگی‌ها';

  @override
  String get ticketTabIssue => 'ایشو';

  @override
  String get ticketSelectPrompt => 'تیکتی انتخاب کنید تا جزئیاتش را ببینید';

  @override
  String get unassigned => 'بدون تخصیص';

  @override
  String get ticketStatusBacklog => 'بک‌لاگ';

  @override
  String get ticketStatusOpen => 'برای انجام';

  @override
  String get ticketStatusInProgress => 'در جریان';

  @override
  String get ticketStatusInReview => 'در بازبینی';

  @override
  String get ticketStatusDone => 'انجام‌شده';

  @override
  String get ticketStatusBlocked => 'مسدود';

  @override
  String get ticketStatusFailed => 'ناموفق';

  @override
  String get ticketStatusCancelled => 'لغوشده';

  @override
  String get notificationTicketAssigned => 'تیکت تخصیص یافت';

  @override
  String get notificationTicketStatusChanged => 'وضعیت تیکت تغییر کرد';

  @override
  String get priority => 'اولویت';

  @override
  String get status => 'وضعیت';

  @override
  String get assignee => 'تخصیص‌یافته';

  @override
  String get labels => 'برچسب‌ها';

  @override
  String get noLabelsYet => 'هنوز برچسبی نیست';

  @override
  String get clearLabels => 'پاک کردن برچسب‌ها';

  @override
  String get pipelineStepAgentActivity => 'فعالیت عامل';

  @override
  String get runStatusCompleted => 'کامل‌شده';

  @override
  String get runStatusQueued => 'در صف';

  @override
  String get ticketDescription => 'شرح';

  @override
  String get ticketPriorityNone => 'هیچ';

  @override
  String get ticketPriorityUrgent => 'فوری';

  @override
  String get ticketPriorityHigh => 'بالا';

  @override
  String get ticketPriorityMedium => 'متوسط';

  @override
  String get ticketPriorityLow => 'پایین';

  @override
  String get ticketViewList => 'فهرست';

  @override
  String get ticketViewBoard => 'تابلو';

  @override
  String get ticketTitlePlaceholder => 'عنوان ایشو';

  @override
  String get ticketDescriptionPlaceholder => 'افزودن شرح…';

  @override
  String get createMore => 'ایجاد بیشتر';

  @override
  String selectedCount(int count) {
    return '$count انتخاب‌شده';
  }

  @override
  String get clearSelection => 'پاک کردن انتخاب';

  @override
  String get bulkDeleteTitle => 'حذف تیکت‌ها';

  @override
  String bulkDeleteMessage(int count) {
    return '$count تیکت انتخاب‌شده حذف شود؟ این کار برگشت‌ناپذیر است.';
  }

  @override
  String get assignTo => 'تخصیص به…';

  @override
  String get sectionMembers => 'اعضا';

  @override
  String get sectionAgents => 'عامل‌ها';

  @override
  String get sidebarGroupWorkspace => 'فضای کاری';

  @override
  String get notificationsTitle => 'اعلان‌ها';

  @override
  String get notificationsTooltip => 'اعلان‌ها';

  @override
  String get notificationsEmpty => 'همه را دیده‌اید';

  @override
  String notificationsUnreadCount(int count) {
    return '$count خوانده‌نشده';
  }

  @override
  String get notificationsMarkRead => 'علامت خوانده‌شده';

  @override
  String get notificationsMarkUnread => 'علامت خوانده‌نشده';

  @override
  String get notificationsEntryActions => 'کنش‌های اعلان';

  @override
  String get markAllRead => 'علامت همه خوانده‌شده';

  @override
  String get teamsNav => 'تیم‌ها';

  @override
  String get noWorkspace => 'بدون فضای کاری';

  @override
  String get selectWorkspace => 'یک فضای کاری انتخاب کنید';

  @override
  String get navMemory => 'حافظه';

  @override
  String get memoryTabFacts => 'واقعیت‌ها';

  @override
  String get memoryTabPolicies => 'سیاست‌ها';

  @override
  String get memoryGraphShowFacts => 'نمایش واقعیت‌ها';

  @override
  String get memoryGraphHideFacts => 'پنهان کردن واقعیت‌ها';

  @override
  String get memoryGraphExpandAll => 'گستردن همهٔ واقعیت‌ها';

  @override
  String get memoryGraphCollapseAll => 'جمع کردن همهٔ واقعیت‌ها';

  @override
  String get memoryTabGraph => 'گراف دانش';

  @override
  String get memoryNoWorkspace =>
      'یک فضای کاری انتخاب کنید تا حافظه‌اش را ببینید.';

  @override
  String get searchArticles => 'جستجوی مقاله‌ها';

  @override
  String get filterAll => 'همه';

  @override
  String get filterUnread => 'خوانده‌نشده';

  @override
  String get filterSaved => 'ذخیره‌شده';

  @override
  String get saveArticle => 'ذخیرهٔ مقاله';

  @override
  String get removeFromSaved => 'برداشتن از ذخیره‌شده‌ها';

  @override
  String get filterBySource => 'فیلتر بر اساس منبع';

  @override
  String get viewAsList => 'نمای فهرست';

  @override
  String get viewAsGrid => 'نمای شبکه';

  @override
  String get noMatchingArticles => 'مقالهٔ مطابقی نیست';

  @override
  String get noMatchingArticlesBody => 'جستجو یا فیلتر منبع دیگری امتحان کنید.';

  @override
  String get allCaughtUp => 'همه را دیده‌اید';

  @override
  String get allCaughtUpBody => 'مقالهٔ خوانده‌نشده‌ای نیست — بعداً سر بزنید.';

  @override
  String get openArticlesInAppDescription =>
      'پیوندها را در خوانندهٔ داخلی باز کنید، نه مرورگر پیش‌فرض.';

  @override
  String get blockAdsTrackersDescription =>
      'تبلیغات، ردیاب‌ها و بنرهای کوکی را از مقاله‌هایی که در خواننده باز می‌کنید حذف کنید.';

  @override
  String get agentQuestionHeader => 'پرسش برای شما';

  @override
  String get agentQuestionAnsweredLabel => 'پاسخ‌داده‌شده';

  @override
  String get agentQuestionFreeformHint => 'پاسختان را بنویسید…';

  @override
  String agentQuestionProgress(int index, int count) {
    return 'پرسش $index از $count';
  }

  @override
  String get agentQuestionSkip => 'رد شدن';

  @override
  String get agentQuestionSkippedLabel => 'رد شد';

  @override
  String get agentQuestionFreeformOptionHint => 'با کلمات خودتان توضیح دهید…';

  @override
  String get reviewRequested => 'بازبینی درخواست شد';

  @override
  String get connectGitHubHint =>
      'وارد GitHub شوید یا در تنظیمات ← فضای کاری ← نمایه و هویت ← میزبانی کد توکن اضافه کنید';

  @override
  String get connectGitHubToLoadPrs =>
      'برای بارگذاری pull requestها GitHub را وصل کنید';

  @override
  String get noRepositoriesConfigured => 'مخزنی پیکربندی نشده';

  @override
  String openedAgo(String age) {
    return 'بازشده $age';
  }

  @override
  String prTimelineOpened(String author) {
    return '⁨$author⁩ این pull request را باز کرد';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کامیت',
      one: '1 کامیت',
    );
    return '⁨$author⁩ این pull request را با $_temp0 باز کرد';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return '⁨$actor⁩ از ⁨$reviewers⁩ درخواست بازبینی کرد';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '⁨$actor⁩ درخواست بازبینی ⁨$reviewers⁩ را برداشت';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '⁨$actor⁩ از ⁨$requested⁩ درخواست بازبینی کرد و درخواست ⁨$removed⁩ را برداشت';
  }

  @override
  String prTimelineAddedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'برچسب‌ها',
      one: 'برچسب',
    );
    return '⁨$actor⁩ ⁨$labels⁩ را $_temp0 افزود';
  }

  @override
  String prTimelineRemovedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'برچسب‌ها',
      one: 'برچسب',
    );
    return '⁨$actor⁩ ⁨$labels⁩ را $_temp0 برداشت';
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
      other: 'برچسب‌ها',
      one: 'برچسب',
    );
    String _temp1 = intl.Intl.pluralLogic(
      removedCount,
      locale: localeName,
      other: 'برچسب‌ها',
      one: 'برچسب',
    );
    return '⁨$actor⁩ ⁨$added⁩ را $_temp0 افزود و ⁨$removed⁩ را $_temp1 برداشت';
  }

  @override
  String prTimelineCommitted(String author) {
    return '⁨$author⁩ کامیت کرد';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کامیت',
      one: '1 کامیت',
    );
    return '⁨$author⁩ $_temp0 پوش کرد';
  }

  @override
  String prTimelineApproved(String author) {
    return '⁨$author⁩ این تغییرات را تأیید کرد';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return '⁨$author⁩ درخواست تغییر داد';
  }

  @override
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نظر کد',
      one: '1 نظر کد',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '⁨$author⁩ بازبینی کرد';
  }

  @override
  String get prTimelineSomeone => 'کسی';

  @override
  String get prTimelineBotBadge => 'بات';

  @override
  String updatedAgo(String age) {
    return 'به‌روزرسانی $age';
  }

  @override
  String get checksPassing => 'بررسی‌ها موفق';

  @override
  String get checksRunning => 'بررسی‌ها در حال اجرا';

  @override
  String get needsYourReview => 'نیاز به بازبینی شما';

  @override
  String get checks => 'بررسی‌ها';

  @override
  String get noReviewersAssigned => 'بازبینی تخصیص نیافته';

  @override
  String get noAssignees => 'بدون تخصیص';

  @override
  String get loadingEllipsis => 'در حال بارگذاری…';

  @override
  String get loadingChecks => 'در حال بارگذاری بررسی‌ها…';

  @override
  String get noChecksYet => 'هنوز بررسی‌ای اجرا نشده';

  @override
  String get noChangesToReview => 'تغییری برای بازبینی نیست';

  @override
  String checksFailingCount(int count) {
    return '$count ناموفق';
  }

  @override
  String get showMore => 'نمایش بیشتر';

  @override
  String get showLess => 'نمایش کمتر';

  @override
  String get backToPullRequests => 'بازگشت به pull requestها';

  @override
  String get pullRequestNotFound => 'Pull request یافت نشد';

  @override
  String get pullRequestNotFoundBody =>
      'ممکن است ادغام، بسته یا جابه‌جا شده باشد.';

  @override
  String get couldntLoadPullRequest => 'بارگذاری این pull request ممکن نشد';

  @override
  String get showDetails => 'نمایش جزئیات';

  @override
  String get noDescriptionProvided => 'شرحی ارائه نشده.';

  @override
  String get factsHint => 'با یادگیری عامل‌ها واقعیت‌ها اینجا ظاهر می‌شوند.';

  @override
  String get noFactsMatch => 'واقعیتی با جستجوی شما جور نیست';

  @override
  String get memoryLoadError => 'بارگذاری حافظه ممکن نشد';

  @override
  String get sortRecent => 'اخیر';

  @override
  String get sortConfidence => 'اطمینان';

  @override
  String get confidenceTooltip =>
      'عامل‌ها چقدر مطمئن‌اند این واقعیت درست است، از 0 تا 100٪.';

  @override
  String get supersededTooltip => 'واقعیت تازه‌تری جایگزین این شده.';

  @override
  String get domain => 'دامنه';

  @override
  String get fitToView => 'جا دادن در نما';

  @override
  String get project => 'پروژه';

  @override
  String get newProject => 'پروژهٔ جدید';

  @override
  String get editProject => 'ویرایش پروژه';

  @override
  String get deleteProject => 'حذف پروژه';

  @override
  String get noProject => 'بدون پروژه';

  @override
  String get allTickets => 'همهٔ تیکت‌ها';

  @override
  String get projectNamePlaceholder => 'نام پروژه';

  @override
  String get projectDescriptionPlaceholder => 'شرح (اختیاری)';

  @override
  String get projectColorLabel => 'رنگ';

  @override
  String get noProjectsYet => 'هنوز پروژه‌ای نیست';

  @override
  String get projectTicketsEmpty => 'هنوز تیکتی در این پروژه نیست';

  @override
  String get createProject => 'ایجاد پروژه';

  @override
  String projectProgress(int done, int total) {
    return '$done از $total انجام‌شده';
  }

  @override
  String deleteProjectConfirm(String name) {
    return '«⁨$name⁩» حذف شود؟ تیکت‌هایش نگه داشته و از پروژه برداشته می‌شوند.';
  }

  @override
  String get projectStatusActive => 'فعال';

  @override
  String get projectStatusCompleted => 'کامل‌شده';

  @override
  String get projectStatusArchived => 'بایگانی‌شده';

  @override
  String get markProjectCompleted => 'علامت کامل‌شده';

  @override
  String get markProjectActive => 'علامت فعال';

  @override
  String get archiveProject => 'بایگانی';

  @override
  String get restoreProject => 'بازیابی';

  @override
  String get relations => 'روابط';

  @override
  String get relateTo => 'ربط دادن به';

  @override
  String get relationSubIssueOf => 'زیرمسئلهٔ…';

  @override
  String get relationParentOf => 'والدِ…';

  @override
  String get relationBlockedBy => 'مسدودشده توسط…';

  @override
  String get relationBlocking => 'مسدودکنندهٔ…';

  @override
  String get relationRelatedTo => 'مرتبط با…';

  @override
  String get relationDuplicateOf => 'تکراری از…';

  @override
  String get relationGroupParent => 'والد';

  @override
  String get relationGroupSubIssues => 'زیرمسئله‌ها';

  @override
  String get relationGroupBlockedBy => 'مسدودشده توسط';

  @override
  String get relationGroupBlocking => 'مسدودکننده';

  @override
  String get relationGroupRelated => 'مرتبط';

  @override
  String get relationGroupDuplicateOf => 'تکراری از';

  @override
  String get relationGroupDuplicatedBy => 'تکراری‌شده توسط';

  @override
  String get copyId => 'کپی ID';

  @override
  String get ticketIdCopied => 'شناسهٔ تیکت کپی شد';

  @override
  String get searchTicketsHint => 'جستجوی تیکت‌ها…';

  @override
  String get noMatchingTickets => 'تیکت مطابقی نیست';

  @override
  String get clearAll => 'پاک کردن همه';

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
      other: '$repos مخزن',
      one: '1 مخزن',
    );
    return '$_temp0 در انتظار بازبینی شما در $_temp1';
  }

  @override
  String get manageWorkspacesSubtitle =>
      'فضای کاری را نام‌گذاری کنید و نشانش را عوض کنید — یکی را در چپ انتخاب کنید تا ویرایش شود.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فضای کاری',
      one: '1 فضای کاری',
      zero: 'بدون فضای کاری',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos مخزن',
      one: '1 مخزن',
      zero: 'بدون مخزن',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents عامل',
      one: '1 عامل',
      zero: '0 عامل',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'هویت';

  @override
  String get uploadImage => 'بارگذاری تصویر';

  @override
  String get failedToSaveLogo =>
      'ذخیرهٔ تصویر لوگو ناموفق بود. مطمئن شوید برنامه می‌تواند فایل انتخاب‌شده را بخواند.';

  @override
  String get workspaceLogoHint =>
      'PNG، JPG یا GIF تا 2 MB. وگرنه از حرف اول فضای کاری استفاده می‌کنیم.';

  @override
  String get workspaceNameFieldHelp =>
      'در تعویض‌گر، نان‌ریزه و هر صفحه نشان داده می‌شود.';

  @override
  String get dangerZone => 'منطقهٔ خطر';

  @override
  String get deleteThisWorkspace => 'حذف این فضای کاری';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return '⁨$name⁩، اتصال‌های مخزن، عامل‌ها و حافظه‌اش برای همیشه حذف می‌شود. این کار برگشت‌ناپذیر است.';
  }

  @override
  String get discard => 'دور انداختن';

  @override
  String discardChangesQuestion(String name) {
    return 'تغییرات ذخیره‌نشدهٔ ⁨$name⁩ دور انداخته شود؟';
  }

  @override
  String get workspaceUpdated => 'فضای کاری به‌روزرسانی شد';

  @override
  String get editTitle => 'ویرایش عنوان';

  @override
  String get editDescription => 'ویرایش شرح';

  @override
  String get addDescription => 'افزودن شرح';

  @override
  String get prTitlePlaceholder => 'عنوان';

  @override
  String get prBodyPlaceholder => 'شرحی بگذارید';

  @override
  String get write => 'نوشتن';

  @override
  String get overview => 'نمای کلی';

  @override
  String get noFilesChanged => 'فایلی تغییر نکرده';

  @override
  String get diff => 'دیف';

  @override
  String get preview => 'پیش‌نمایش';

  @override
  String get imageDiffBefore => 'قبل';

  @override
  String get imageDiffAfter => 'بعد';

  @override
  String get imageDiffModeTwoUp => 'دو ستونه';

  @override
  String get imageDiffModeSwipe => 'کشیدن';

  @override
  String get imageDiffModeDifference => 'تفاوت';

  @override
  String imageDiffChangedPercent(String percent) {
    return '$percent٪ تغییر کرده';
  }

  @override
  String get imageDiffPictures => 'تصاویر';

  @override
  String get imageDiffSource => 'منبع';

  @override
  String get imageDiffDeleted => 'حذف‌شده';

  @override
  String get imageDiffAdded => 'اضافه‌شده';

  @override
  String imageDiffDimensions(int width, int height) {
    return 'ع: ${width}px | ط: ${height}px';
  }

  @override
  String get outdated => 'کهنه';

  @override
  String get outdatedComments => 'نظرهای کهنه';

  @override
  String outdatedCountLabel(int count) {
    return '$count کهنه';
  }

  @override
  String get prTemplateLabel => 'قالب';

  @override
  String get prTemplateDefault => 'پیش‌فرض';

  @override
  String get addReviewers => 'افزودن بازبین';

  @override
  String get addAssignees => 'افزودن تخصیص';

  @override
  String get searchUsers => 'جستجوی افراد…';

  @override
  String get searchReviewers => 'جستجوی افراد و تیم‌ها…';

  @override
  String get usersSectionLabel => 'افراد';

  @override
  String get userStatusBusy => 'مشغول';

  @override
  String get teamsSectionLabel => 'تیم‌ها';

  @override
  String get suggestedReviewers => 'بازبین‌های پیشنهادی';

  @override
  String get noMatchingUsers => 'فرد مطابقی نیست';

  @override
  String get noMatchingReviewers => 'موردی نیست';

  @override
  String get requiredByCodeOwners => 'الزامی توسط مالکان کد';

  @override
  String reviewedOnBehalfOf(String login) {
    return 'از طریق ⁨$login⁩';
  }

  @override
  String get team => 'تیم';

  @override
  String get markdownBold => 'ضخیم';

  @override
  String get markdownItalic => 'ایتالیک';

  @override
  String get markdownHeading => 'عنوان';

  @override
  String get markdownBulletList => 'فهرست گلوله‌ای';

  @override
  String get markdownChecklist => 'چک‌لیست';

  @override
  String get markdownCode => 'کد';

  @override
  String get markdownLink => 'پیوند';

  @override
  String get markdownQuote => 'نقل‌قول';

  @override
  String get markdownSupported => 'Markdown پشتیبانی می‌شود';

  @override
  String get markdownAttachImages => 'برای افزودن تصویر کلیک کنید';

  @override
  String failedToUpdateTitle(String error) {
    return 'به‌روزرسانی عنوان ممکن نشد: ⁨$error⁩';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'به‌روزرسانی شرح ممکن نشد: ⁨$error⁩';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'به‌روزرسانی بازبین‌ها ممکن نشد: ⁨$error⁩';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'به‌روزرسانی تخصیص‌یافته‌ها ممکن نشد: ⁨$error⁩';
  }

  @override
  String get discardChangesConfirm => 'تغییراتتان دور انداخته شود؟';

  @override
  String get newPr => 'PR جدید';

  @override
  String get openPullRequest => 'باز کردن یک pull request';

  @override
  String get composePrSubtitle =>
      'از شاخه‌ای که پوش کرده‌اید — بدون عامل یا تیکت';

  @override
  String get createAsDraft => 'ایجاد به‌عنوان پیش‌نویس';

  @override
  String get composePrNoRepo => 'مخزن GitHub انتخاب نشده';

  @override
  String get composePrNoRepoHint =>
      'فضای کاری با مخزن پیوندشده به GitHub انتخاب کنید تا pull request باز کنید.';

  @override
  String get composePrPickBranches =>
      'شاخهٔ پایه و مقایسه را انتخاب کنید تا تغییرات پیش‌نمایش شود.';

  @override
  String get composePrNothingToCompare => 'بین این شاخه‌ها تغییری نیست.';

  @override
  String get repository => 'مخزن';

  @override
  String get baseBranchLabel => 'پایه';

  @override
  String get compareBranchLabel => 'مقایسه';

  @override
  String get selectBranch => 'یک شاخه انتخاب کنید';

  @override
  String get navMeetings => 'جلسات';

  @override
  String get meetingsNoWorkspace =>
      'یک فضای کاری انتخاب کنید تا جلسات را ببینید.';

  @override
  String get meetingsEmpty => 'هنوز جلسه‌ای نیست';

  @override
  String get meetingsEmptyHint =>
      'اولین جلسه‌تان را ضبط کنید — صدا روی این دستگاه می‌ماند و عامل آن را به یادداشت، تصمیم و موارد اقدام تبدیل می‌کند.';

  @override
  String get meetingNotesHint =>
      'یادداشت سریع بنویسید — عامل پس از جلسه گسترششان می‌دهد.';

  @override
  String get meetingSpeakerMe => 'شما';

  @override
  String get meetingStatusRecording => 'در حال ضبط';

  @override
  String get meetingStatusProcessing => 'در حال پردازش';

  @override
  String get meetingStatusDone => 'انجام‌شده';

  @override
  String get meetingStatusFailed => 'ناموفق';

  @override
  String get meetingsSubtitle =>
      'روی این دستگاه ضبط و رونویسی می‌شود، سپس عامل خلاصه می‌کند.';

  @override
  String get meetingsRecordMeeting => 'ضبط جلسه';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مورد در حال پردازش',
      one: '1 مورد در حال پردازش',
    );
    return '$_temp0';
  }

  @override
  String meetingsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count جلسه',
      one: '1 جلسه',
      zero: 'بدون جلسه',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLedgerOpenActions => 'اقدامات باز';

  @override
  String get meetingsLedgerDecisions => 'تصمیم‌ها';

  @override
  String get meetingsLiveOpen => 'باز کردن ضبط';

  @override
  String get meetingTemplateShort => 'قالب';

  @override
  String get meetingsStatThisWeek => 'این هفته';

  @override
  String get meetingsStatRecorded => 'ضبط‌شده';

  @override
  String get meetingsFilterAll => 'همه';

  @override
  String get meetingsFilterDone => 'انجام‌شده';

  @override
  String get meetingsFilterProcessing => 'در حال پردازش';

  @override
  String get meetingsSearchHint => 'فیلتر بر اساس عنوان، شخص، برنامه…';

  @override
  String get meetingsBucketToday => 'امروز';

  @override
  String get meetingsBucketYesterday => 'دیروز';

  @override
  String get meetingsBucketEarlierThisWeek => 'اوایل این هفته';

  @override
  String get meetingsBucketLastWeek => 'هفتهٔ گذشته';

  @override
  String get meetingsBucketOlder => 'قدیمی‌تر';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تصمیم',
      one: '1 تصمیم',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total مورد اقدام';
  }

  @override
  String get meetingsEnhancedPill => 'غنی‌شده';

  @override
  String get meetingsTranscribing => 'در حال رونویسی و خلاصه‌سازی…';

  @override
  String get meetingsOpenAction => 'باز کردن';

  @override
  String get meetingsStopProcessing => 'توقف';

  @override
  String get meetingsStillTranscribing =>
      'هنوز در حال رونویسی — خلاصه وقتی تمام شود ظاهر می‌شود.';

  @override
  String get meetingsNoMatch => 'جلسهٔ مطابقی نیست';

  @override
  String get meetingsNoMatchHint => 'فیلتر یا عبارت جستجوی دیگری امتحان کنید.';

  @override
  String get meetingBackAllMeetings => 'همهٔ جلسات';

  @override
  String get meetingReRunSummary => 'اجرای دوبارهٔ خلاصه';

  @override
  String get meetingExport => 'برون‌بری';

  @override
  String get meetingAugmentingBanner =>
      'در حال غنی‌سازی یادداشت‌ها از رونوشت — استخراج تصمیم‌ها و موارد اقدام…';

  @override
  String get meetingTabNotes => 'یادداشت‌ها';

  @override
  String get meetingTabTranscript => 'رونوشت';

  @override
  String get meetingTabActionItems => 'موارد اقدام';

  @override
  String get meetingTabDecisions => 'تصمیم‌ها';

  @override
  String get meetingNotesEnhancedToggle => 'غنی‌شده';

  @override
  String get meetingNotesYoursToggle => 'یادداشت‌های شما';

  @override
  String get meetingEnhancedByAgent => 'غنی‌شده توسط عامل · از رونوشت';

  @override
  String get meetingEnhancedPending => 'عامل هنوز روی این خلاصه کار می‌کند.';

  @override
  String get meetingNotesEmpty => 'هنوز یادداشت غنی‌شده‌ای نیست.';

  @override
  String get meetingNotesSavedLocally => 'محلی ذخیره شد';

  @override
  String get meetingNotesSaving => 'در حال ذخیره…';

  @override
  String get meetingViewFullTranscript => 'دیدن رونوشت کامل';

  @override
  String get meetingTranscriptSearchHint => 'جستجو در رونوشت…';

  @override
  String get meetingSpeakerEveryone => 'همه';

  @override
  String get meetingSpeakerOthers => 'دیگران';

  @override
  String get meetingTranscriptEmpty => 'هنوز رونوشتی نیست.';

  @override
  String get meetingActionItemsEmpty => 'مورد اقدامی استخراج نشد.';

  @override
  String get meetingActionItemFrom => 'از این جلسه';

  @override
  String get meetingCreateTicket => 'ایجاد تیکت';

  @override
  String meetingTicketCreated(String key) {
    return 'تیکت ⁨$key⁩ ایجاد و اعزام شد.';
  }

  @override
  String get meetingTicketFailed => 'ایجاد تیکت ممکن نشد.';

  @override
  String get meetingDecisionsEmpty => 'تصمیمی ثبت نشده.';

  @override
  String get meetingEditTitle => 'ویرایش عنوان';

  @override
  String get meetingTitleLabel => 'عنوان';

  @override
  String get meetingAddActionItem => 'افزودن مورد اقدام';

  @override
  String get meetingEditActionItem => 'ویرایش مورد اقدام';

  @override
  String get meetingDeleteActionItem => 'حذف مورد اقدام';

  @override
  String get meetingActionItemContentLabel => 'مورد اقدام';

  @override
  String get meetingActionItemContentHint => 'چه باید رخ دهد؟';

  @override
  String get meetingActionItemOwnerLabel => 'مالک';

  @override
  String get meetingActionItemOwnerHint => 'مسئول کیست؟ (اختیاری)';

  @override
  String get meetingAddDecision => 'افزودن تصمیم';

  @override
  String get meetingEditDecision => 'ویرایش تصمیم';

  @override
  String get meetingDeleteDecision => 'حذف تصمیم';

  @override
  String get meetingDecisionContentLabel => 'تصمیم';

  @override
  String get meetingDecisionContentHint => 'چه تصمیمی گرفته شد؟';

  @override
  String get meetingReRunStarted => 'خلاصه‌ساز دوباره روی رونوشت اجرا می‌شود…';

  @override
  String get meetingReRunNoTranscript => 'هنوز رونوشتی برای خلاصه نیست.';

  @override
  String get meetingExportCopied =>
      'یادداشت‌ها به‌صورت Markdown در کلیپ‌بورد کپی شد.';

  @override
  String get meetingExportSaved => 'جلسه برون‌بری شد.';

  @override
  String meetingExportFailed(String error) {
    return 'برون‌بری ناموفق: ⁨$error⁩';
  }

  @override
  String get meetingExportNothing => 'هنوز چیزی برای برون‌بری نیست.';

  @override
  String get meetingPlaybackPlay => 'پخش';

  @override
  String get meetingPlaybackPause => 'مکث';

  @override
  String get meetingPlaybackUnavailable =>
      'پخش صدا روی این دستگاه در دسترس نیست.';

  @override
  String get meetingDetectedTitle => 'جلسه تشخیص داده شد';

  @override
  String meetingDetectedSubtitle(String label) {
    return 'به نظر می‌رسد «⁨$label⁩» در جریان است. ضبط شود؟';
  }

  @override
  String get meetingDetectedSubtitleGeneric =>
      'به نظر می‌رسد جلسه‌ای در جریان است. ضبط شود؟';

  @override
  String get meetingDetectedRecord => 'ضبط';

  @override
  String get meetingDetectedDismiss => 'نادیده گرفتن';

  @override
  String get meetingAutoStopTitle =>
      'این جلسه تمام به نظر می‌رسد. ضبط متوقف شود؟';

  @override
  String get meetingAutoStopStop => 'توقف';

  @override
  String get meetingAutoStopKeep => 'ادامهٔ ضبط';

  @override
  String get meetingAutoDetect => 'تشخیص خودکار جلسات';

  @override
  String get meetingAutoDetectDescription =>
      'تقویم و برنامه‌های کنفرانس را ببین و وقتی جلسه شروع شد پیشنهاد ضبط بده.';

  @override
  String get meetingsRecordingCrumb => 'در حال ضبط…';

  @override
  String get meetingRecordTitleHint => 'عنوان جلسه';

  @override
  String get meetingRecordTappingLabel => 'در حال دریافت:';

  @override
  String get meetingRecordMic => 'میکروفون';

  @override
  String get meetingRecordSystemAudio => 'صدای سیستم';

  @override
  String get meetingRecordPause => 'مکث';

  @override
  String get meetingRecordResume => 'ازسرگیری';

  @override
  String get meetingRecordStop => 'توقف و خلاصه';

  @override
  String get meetingRecordYourNotes => 'یادداشت‌های شما';

  @override
  String get meetingRecordNotesPlaceholder =>
      'هنگام شنیدن بنویسید. چند تکه کافی است — پس از توقف، عامل با رونوشت گسترششان می‌دهد.';

  @override
  String get meetingRecordLiveTranscript => 'رونوشت زنده';

  @override
  String get meetingRecordDecoding => 'رمزگشایی روی دستگاه';

  @override
  String get meetingRecordListening =>
      'در حال شنیدن… گفتار ظرف یک‌دو ثانیه اینجا ظاهر می‌شود، با برچسب شما / دیگران.';

  @override
  String get meetingRecordPausedHint =>
      'مکث — تا ازسرگیری صدا نادیده گرفته می‌شود.';

  @override
  String get meetingRecordNotActive => 'ضبط فعالی نیست.';

  @override
  String get meetingHudRecording => 'در حال ضبط';

  @override
  String get meetingHudPaused => 'مکث‌شده';

  @override
  String get meetingHudOpen => 'باز کردن';

  @override
  String get meetingHudStop => 'توقف';

  @override
  String get meetingToolbarPopOut => 'جدا کردن';

  @override
  String get meetingToolbarHoldToStop => 'نگه دارید تا ضبط متوقف شود';

  @override
  String get meetingToolbarSemanticLabel => 'نوار ابزار ضبط جلسه';

  @override
  String get orchestrate => 'ارکستر کردن';

  @override
  String get orchestrationUnavailable => 'ارکستراسیون در دسترس نیست';

  @override
  String get orchestrationApprove => 'تأیید برنامه';

  @override
  String get orchestrationReject => 'رد';

  @override
  String get orchestrationCancel => 'لغو ارکستراسیون';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count نقش — $hires استخدام جدید';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count زیرتیکت';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'هزینهٔ برآوردی: ⁨\$$amount⁩';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total زیرتیکت انجام‌شده';
  }

  @override
  String get orchestrationStatusProposed => 'پیشنهادشده';

  @override
  String get orchestrationStatusApproved => 'تأییدشده';

  @override
  String get orchestrationStatusExecuting => 'در حال اجرا';

  @override
  String get orchestrationStatusSynthesizing => 'در حال ترکیب';

  @override
  String get orchestrationStatusCompleted => 'کامل‌شده';

  @override
  String get orchestrationStatusFailed => 'ناموفق';

  @override
  String get orchestrationStatusCancelled => 'لغوشده';

  @override
  String get messageFailed => 'اجرا ناموفق';

  @override
  String get turnLimitReached => 'در حد نوبت متوقف شد — برای ادامه پاسخ دهید';

  @override
  String get retried => 'دوباره تلاش شد';

  @override
  String replyingTo(String name) {
    return 'در پاسخ به ⁨$name⁩';
  }

  @override
  String get silenceTimeoutLabel => 'مهلت سکوت (دقیقه)';

  @override
  String get silenceTimeoutHint =>
      'مثلاً 15 — اجرا را پس از این مدت بدون خروجی پایان بده';

  @override
  String get capabilityJsonMode => 'حالت JSON';

  @override
  String get capabilityModelSelection => 'انتخاب مدل';

  @override
  String get transcriptThinking => 'در حال فکر…';

  @override
  String transcriptThoughtFor(String duration) {
    return 'فکر کرد به مدت $duration';
  }

  @override
  String get transcriptStatusMakingEdits => 'در حال ویرایش…';

  @override
  String get transcriptStatusReadingFiles => 'در حال خواندن فایل‌ها…';

  @override
  String get transcriptStatusSearching => 'در حال جستجوی کدبیس…';

  @override
  String get transcriptStatusRunningCommands => 'در حال اجرای فرمان‌ها…';

  @override
  String get transcriptStatusResponding => 'در حال پاسخ…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return 'در حال اجرای ⁨$tool⁩…';
  }

  @override
  String get transcriptInput => 'ورودی';

  @override
  String get transcriptOutput => 'خروجی';

  @override
  String get transcriptErrorLabel => 'خطا';

  @override
  String get transcriptSandboxBlocked => 'سندباکس کنشی را مسدود کرد';

  @override
  String transcriptShowFullOutput(int kb) {
    return '+$kb KB خروجی کامل';
  }

  @override
  String transcriptShowAllLines(int count) {
    return 'نمایش هر $count خط';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return 'نمایش $count خط اول';
  }

  @override
  String get transcriptGrepNoMatches => 'موردی نیست';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '$matches مورد',
      one: '1 مورد',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files فایل',
      one: '1 فایل',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return 'شخص $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => 'تغییر نام گوینده';

  @override
  String get meetingRenameSpeakerTitle => 'تغییر نام گوینده';

  @override
  String get meetingSpeakerNameLabel => 'نام';

  @override
  String get meetingSpeakerSuggestFromCalendar => 'از دعوت‌شدگان این جلسه';

  @override
  String get meetingRenameSpeakerApplyAll =>
      'اعمال به همهٔ بلوک‌های این گوینده';

  @override
  String get meetingRenameSpeakerScopeHint =>
      'وقتی خاموش است فقط خط انتخاب‌شده تغییر نام می‌یابد.';

  @override
  String get meetingLinkEvent => 'پیوند به رویداد';

  @override
  String get meetingChangeEvent => 'تغییر رویداد';

  @override
  String get meetingLinkEventTitle => 'پیوند به رویداد تقویم';

  @override
  String get meetingLinkEventSearchHint => 'جستجوی رویدادها';

  @override
  String get meetingLinkEventEmpty => 'رویداد تقویم نزدیکی نیست';

  @override
  String get meetingUnlinkEvent => 'برداشتن پیوند';

  @override
  String get calendarLinkExistingMeeting => 'پیوند به جلسهٔ موجود';

  @override
  String get calendarLinkMeetingTitle => 'پیوند یک جلسه';

  @override
  String get calendarLinkMeetingSearchHint => 'جستجوی جلسات';

  @override
  String get calendarLinkMeetingEmpty => 'جلسه‌ای برای پیوند نیست';

  @override
  String get meetingRenameSpeakerFailed => 'تغییر نام گوینده ممکن نشد';

  @override
  String get calendarLinkUpdateFailed => 'به‌روزرسانی پیوند تقویم ممکن نشد';

  @override
  String get rename => 'تغییر نام';

  @override
  String get notNow => 'فعلاً نه';

  @override
  String get meetingSaveVoiceProfileTitle => 'نمایهٔ صوتی ذخیره شود؟';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return '⁨$name⁩ در جلسات آینده با ذخیرهٔ اثر صدا خودکار شناخته شود.';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return 'نمایهٔ صوتی ⁨$name⁩ ذخیره شد';
  }

  @override
  String get meetingVoiceProfileSaveFailed => 'ذخیرهٔ نمایهٔ صوتی ممکن نشد';

  @override
  String get voiceProfilesSection => 'نمایه‌های صوتی';

  @override
  String get voiceProfilesDescription =>
      'صداهای ذخیره‌شده در جلسات آینده خودکار شناخته می‌شوند.';

  @override
  String get voiceProfilesEmpty =>
      'هنوز صدای ذخیره‌شده‌ای نیست. در رونوشت جلسه گوینده را نام‌گذاری کنید، سپس «ذخیرهٔ نمایهٔ صوتی» را انتخاب کنید.';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نمونه',
      one: '1 نمونه',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => 'تغییر نام نمایهٔ صوتی';

  @override
  String get deleteVoiceProfileTitle => 'نمایهٔ صوتی حذف شود؟';

  @override
  String deleteVoiceProfileBody(String name) {
    return 'شناخت ⁨$name⁩ متوقف شود؟ اثر صدای ذخیره‌شده برداشته می‌شود. نام‌های اعمال‌شده در جلسات گذشته می‌مانند.';
  }

  @override
  String get connectedLabel => 'متصل';

  @override
  String get ideTabGeneral => 'عمومی';

  @override
  String get ideTabExplorer => 'کاوشگر';

  @override
  String get ideTabSourceControl => 'کنترل منبع';

  @override
  String get generalSectionTodos => 'کارها';

  @override
  String get generalSectionGoals => 'اهداف';

  @override
  String get goalRunStatusActive => 'فعال';

  @override
  String get goalRunStatusPaused => 'مکث‌شده';

  @override
  String get goalRunStatusCompleted => 'کامل‌شده';

  @override
  String get goalRunStatusFailed => 'ناموفق';

  @override
  String get goalRunStatusCancelled => 'لغوشده';

  @override
  String get goalRunStatusBudgetExhausted => 'بودجه تمام شد';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return 'اجرای $run از $max · $cost از $cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return 'اجرای $run · $cost از $cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return 'موعد $deadline';
  }

  @override
  String get goalRunPause => 'مکث هدف';

  @override
  String get goalRunResume => 'ازسرگیری هدف';

  @override
  String goalRunResumeRaise(String cap) {
    return 'ازسرگیری · سقف تا ⁨$cap⁩';
  }

  @override
  String get goalRunStop => 'توقف هدف';

  @override
  String get generalSectionAgents => 'عامل‌ها';

  @override
  String get generalSectionTerminals => 'ترمینال‌ها';

  @override
  String get generalTodosEmpty => 'هنوز کاری نیست';

  @override
  String get generalAgentsEmpty => 'عاملی در حال اجرا نیست';

  @override
  String get generalTerminalsEmpty => 'ترمینالی باز نیست';

  @override
  String get generalSectionBrowsers => 'مرورگرها';

  @override
  String get generalSectionComputers => 'رایانه‌ها';

  @override
  String get generalBrowsersEmpty => 'مرورگری باز نیست';

  @override
  String get generalComputersEmpty => 'رایانه‌ای باز نیست';

  @override
  String get generalSectionPhones => 'تلفن‌ها';

  @override
  String get generalPhonesEmpty => 'تلفنی باز نیست';

  @override
  String get pauseAgent => 'مکث عامل';

  @override
  String get resumeAgent => 'ازسرگیری عامل';

  @override
  String get agentCannotPause =>
      'این عامل را نمی‌توان مکث کرد — به‌جایش متوقف کنید.';

  @override
  String get goalClear => 'پاک کردن هدف';

  @override
  String get undoLabelGoalClear => 'پاک کردن هدف';

  @override
  String get todoStatusPending => 'شروع‌نشده';

  @override
  String get todoStatusInProgress => 'در جریان';

  @override
  String get todoStatusCompleted => 'انجام‌شده';

  @override
  String get reorderTodo => 'تغییر ترتیب کار';

  @override
  String get focusTerminal => 'تمرکز روی ترمینال';

  @override
  String get focusMachine => 'تمرکز روی ماشین';

  @override
  String get focusBrowser => 'تمرکز روی مرورگر';

  @override
  String get todoEditorTitle => 'ویرایش کارها';

  @override
  String get todoEditorHint =>
      'یک مورد در هر خط. از ⁨- [ ]⁩ برای در انتظار، ⁨- [~]⁩ برای در جریان، ⁨- [x]⁩ برای انجام‌شده.';

  @override
  String get todoNeedsText => 'پس از فرمان متنی اضافه کنید';

  @override
  String get todoNotFound => 'کار مطابقی نیست';

  @override
  String get todoCleared => 'فهرست کارها پاک شد';

  @override
  String get todoNothingToCopy => 'چیزی برای کپی نیست';

  @override
  String todoAdded(String content) {
    return '«⁨$content⁩» افزوده شد';
  }

  @override
  String todoStarted(String content) {
    return '«⁨$content⁩» شروع شد';
  }

  @override
  String todoCompleted(String content) {
    return '«⁨$content⁩» کامل شد';
  }

  @override
  String todoRemoved(String content) {
    return '«⁨$content⁩» برداشته شد';
  }

  @override
  String todoCopied(int count) {
    return '$count مورد کپی شد';
  }

  @override
  String todoImported(int count) {
    return '$count مورد وارد شد';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return 'فرمان کار ناشناخته «⁨$name⁩»';
  }

  @override
  String get terminal => 'ترمینال';

  @override
  String get ideCloseTab => 'بستن زبانه';

  @override
  String get ideSplitEditor => 'تقسیم ویرایشگر';

  @override
  String get ideSplitRight => 'تقسیم به راست';

  @override
  String get ideSplitDown => 'تقسیم به پایین';

  @override
  String get ideSplitLeft => 'تقسیم به چپ';

  @override
  String get ideSplitUp => 'تقسیم به بالا';

  @override
  String get ideCloseGroup => 'بستن گروه';

  @override
  String get ideCloseOthers => 'بستن بقیه';

  @override
  String get ideCloseToRight => 'بستن به راست';

  @override
  String get ideCloseSaved => 'بستن ذخیره‌شده‌ها';

  @override
  String get ideCloseAll => 'بستن همه';

  @override
  String get ideSplit => 'تقسیم';

  @override
  String get ideToggleSidebar => 'تغییر وضعیت نوار کناری';

  @override
  String get ideNewTab => 'باز کردن ویرایشگر';

  @override
  String get ideNewTabMenu => 'زبانهٔ جدید';

  @override
  String get ideReviewCode => 'بازبینی کد';

  @override
  String ideReviewCodeInRepo(String repo) {
    return 'بازبینی کد (⁨$repo⁩)';
  }

  @override
  String get ideRevertConfirmTitle => 'بازگردانی تغییرات';

  @override
  String get ideRevertUntracked => 'فایل‌های ردیابی‌نشده قابل بازگردانی نیستند';

  @override
  String get ideRevertFailed =>
      'بازگردانی فایل‌ها ممکن نشد. worktree گفتگو ممکن است در دسترس نباشد.';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فایل',
      one: '1 فایل',
    );
    return '$_temp0 بازگردانده نشد (ردیابی‌نشده).';
  }

  @override
  String get ideSearchMatchCase => 'تطبیق بزرگ‌کوچک';

  @override
  String get ideSearchWholeWord => 'کلمهٔ کامل';

  @override
  String get ideSearchRegex => 'Regex';

  @override
  String get ideSearchFilters => 'فیلترهای جستجو';

  @override
  String get ideSearchFilesToInclude => 'فایل‌های شامل';

  @override
  String get ideSearchFilesToExclude => 'فایل‌های مستثنی';

  @override
  String get ideNoOpenTabs => 'زبانه‌ای باز نیست — با + باز کنید';

  @override
  String get ideBrowserAddressHint => 'نشانی وارد کنید یا جستجو کنید';

  @override
  String get ideSimpleWebBrowser => 'مرورگر وب ساده';

  @override
  String get ideWebBrowser => 'مرورگر وب';

  @override
  String get ideBrowserEnterUrl =>
      'برای شروع مرور یک URL در نوار نشانی وارد کنید';

  @override
  String get ideCodeServer => 'ویرایشگر';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return 'تغییرات ⁨$fileName⁩ ذخیره شود؟';
  }

  @override
  String get ideUnsavedChangesBody => 'اگر ذخیره نکنید تغییرات از دست می‌رود.';

  @override
  String get ideDontSave => 'ذخیره نشود';

  @override
  String get editorAutoSave => 'ذخیرهٔ خودکار';

  @override
  String get editorAutoSaveDescription =>
      'تغییرات ویرایشگر توکار را خودکار ذخیره کن.';

  @override
  String get editorAutoSaveOff => 'خاموش';

  @override
  String get editorAutoSaveAfterDelay => 'پس از تأخیر';

  @override
  String get editorAutoSaveOnFocusChange => 'با تغییر تمرکز';

  @override
  String get ideCodeServerUnavailable =>
      'code-server روی این سرور در دسترس نیست';

  @override
  String get ideCodeServerUnavailableHint =>
      '⁨code-server⁩ (⁨coder/code-server⁩) را روی میزبان سرور نصب کنید، سپس ویرایشگر را دوباره باز کنید.';

  @override
  String get ideCodeServerInstalling => 'آماده‌سازی ویرایشگر…';

  @override
  String get ideCodeServerOpenInBrowser => 'باز کردن ویرایشگر در مرورگر';

  @override
  String get ideCodeServerError => 'باز کردن ویرایشگر ممکن نشد';

  @override
  String get paneSuspendedCaption =>
      'برای صرفه‌جویی در منابع معلق شد — با تمرکز دوباره بارگذاری می‌شود';

  @override
  String get ideFolderLoadFailed => 'بارگذاری این پوشه ممکن نشد';

  @override
  String get ideFileSearchFailed => 'جستجوی فایل‌ها ممکن نشد';

  @override
  String get ideSearchInFiles => 'جستجو در فایل‌ها';

  @override
  String get ideNoContentMatches => 'موردی نیست';

  @override
  String get ideSourceControlCreatePr => 'ایجاد pull request';

  @override
  String ideSourceControlViewPr(int number) {
    return 'نمایش pull request ⁨#$number⁩';
  }

  @override
  String get ideSourceControlNoChanges => 'بدون تغییر';

  @override
  String get noReposInConversation => 'مخزنی در این گفتگو نیست';

  @override
  String get ideSourceControlNoSpace =>
      'گفتگویی باز کنید تا تغییراتش را ببینید';

  @override
  String get ideFileLoading => 'در حال بارگذاری…';

  @override
  String get ideFileBinary => 'فایل باینری';

  @override
  String get mcpExternalServers => 'سرورهای MCP خارجی';

  @override
  String get mcpExternalServersDescription =>
      'به سرورهای MCP خارجی وصل شوید (GitHub، Sentry، Postgres، خودکارسازی مرورگر). سرورهایی که برای Claude، Cursor، VS Code و ابزارهای دیگر پیکربندی کرده‌اید خودکار کشف می‌شوند.';

  @override
  String get mcpApprovalMode => 'تأیید ابزار';

  @override
  String get mcpApprovalModeDescription =>
      'کدام کنش‌های ابزار بدون پرسش اجرا می‌شوند. خواندن همیشه مجاز است؛ سطوح بالاتر می‌پرسند.';

  @override
  String get mcpApprovalAlwaysAsk => 'همیشه بپرس';

  @override
  String get mcpApprovalWrite => 'تأیید خودکار نوشتن';

  @override
  String get mcpApprovalYolo => 'تأیید خودکار همه';

  @override
  String get mcpNoExternalServers => 'سرور MCP خارجی کشف نشد.';

  @override
  String get mcpAuthorize => 'مجوز دادن';

  @override
  String get mcpReconnect => 'اتصال دوباره';

  @override
  String get mcpExternalConnectionsNote =>
      'سرورهای MCP خارجی روی سرور عامل اجرا می‌شوند (مشترک دسکتاپ و وب). مجوز OAuth فقط روی دسکتاپ در دسترس است.';

  @override
  String get mcpStatusConnected => 'متصل';

  @override
  String get mcpStatusConnecting => 'در حال اتصال…';

  @override
  String get mcpStatusNeedsAuth => 'نیاز به مجوز';

  @override
  String get mcpStatusFailed => 'ناموفق';

  @override
  String get mcpStatusCircuitOpen => 'مکث‌شده';

  @override
  String get mcpStatusDisabled => 'غیرفعال';

  @override
  String get providersAndModels => 'ارائه‌دهنده‌ها و مدل‌ها';

  @override
  String get providersAndModelsDescription =>
      'هر ارائه‌دهنده‌ای که عامل داخلی می‌تواند استفاده کند را فهرست کنید — کلید API بگذارید یا با مرورگر وارد شوید، مدل‌ها و قیمت هر ارائه‌دهندهٔ متصل را ببینید و کنترل کنید این فضای کاری کدام ارائه‌دهنده‌ها را می‌تواند استفاده کند.';

  @override
  String get syncNow => 'همگام‌سازی اکنون';

  @override
  String syncNowResult(int applied, int failed) {
    return 'همگام‌سازی کامل — $applied اعمال شد، $failed ناموفق';
  }

  @override
  String syncNowFailed(String error) {
    return 'همگام‌سازی ناموفق: ⁨$error⁩';
  }

  @override
  String get denied => 'ردشده';

  @override
  String get allowed => 'مجاز';

  @override
  String allowProviderSemantic(String provider) {
    return 'اجازهٔ ⁨$provider⁩';
  }

  @override
  String enabledViaEnv(String key) {
    return 'فعال از طریق ⁨$key⁩';
  }

  @override
  String costPerMillion(String input, String output) {
    return '$input / $output در هر 1M';
  }

  @override
  String contextTokens(String tokens) {
    return '$tokens زمینه';
  }

  @override
  String get usageAndCost => 'مصرف و هزینه';

  @override
  String get usageAndCostDescription =>
      'هزینهٔ عامل‌ها در 7 روز گذشته، از هزینه‌های مشاهده‌شدهٔ اجرا.';

  @override
  String get noUsageYet => 'هنوز مصرفی ثبت نشده.';

  @override
  String get spentThisWeek => 'هزینه‌شده این هفته';

  @override
  String get subscriptionUsage => 'مصرف اشتراک';

  @override
  String get subscriptionUsageUnavailable => 'در دسترس نیست';

  @override
  String get subscriptionUsageExhausted => 'سهمیه تمام شد';

  @override
  String get subscriptionUsageSignInRequired => 'دوباره وارد شوید';

  @override
  String get subscriptionUsageSignInExpired =>
      'ورود منقضی شد، در اجرای بعدی تمدید می‌شود';

  @override
  String get subscriptionUsagePartiallyAvailable => 'تا حدی در دسترس';

  @override
  String resetsIn(String duration) {
    return 'بازنشانی در $duration';
  }

  @override
  String get feedbackHelpful => 'مفید بود';

  @override
  String get feedbackNotHelpful => 'مفید نبود';

  @override
  String get modeChat => 'گفتگو';

  @override
  String get modePlan => 'برنامه';

  @override
  String get modeReview => 'بازبینی';

  @override
  String get modeOrchestrate => 'ارکستر';

  @override
  String get editorTheme => 'تم ویرایشگر';

  @override
  String get editorThemeDescription =>
      'یک تم رنگی VS Code وارد کنید تا دیف و ویرایشگر توکار با IDE شما جور شود.';

  @override
  String get editorThemePasteHint =>
      'محتوای فایل JSON تم رنگی VS Code را جای‌گذاری کنید';

  @override
  String get editorThemeImported => 'تم وارد شد';

  @override
  String get editorThemeInvalid => 'این شبیه تم معتبر VS Code نیست';

  @override
  String get importTheme => 'وارد کردن تم';

  @override
  String get clearTheme => 'پاک کردن تم';

  @override
  String get openInDiffViewer => 'باز کردن در نمایشگر دیف';

  @override
  String get shellCommand => 'فرمان';

  @override
  String get shellOutput => 'خروجی';

  @override
  String get revertToHere => 'بازگردانی تا اینجا';

  @override
  String get revertConfirmBody =>
      'پیام‌های پس از این نقطه پنهان و تغییرات فایل عامل تا این نوبت برگردانده شود؟ می‌توانید این را واگرد کنید.';

  @override
  String get revert => 'بازگردانی';

  @override
  String get revertedToHere => 'تا اینجا بازگردانده شد';

  @override
  String get nothingToRevert => 'چیزی برای بازگردانی نیست';

  @override
  String get undoRevert => 'واگرد بازگردانی';

  @override
  String get revertUndone => 'بازگردانی واگرد شد';

  @override
  String get systemBehavior => 'رفتار سیستم';

  @override
  String get keepAwakeTitle => 'بیدار نگه داشتن رایانه هنگام اجرای عامل‌ها';

  @override
  String get keepAwakeOnSubtitle =>
      'تا وقتی عاملی کار می‌کند رایانه به خواب نمی‌رود';

  @override
  String get keepAwakeOffSubtitle =>
      'حتی هنگام کار عامل رایانه ممکن است بخوابد';

  @override
  String get syncEngineSectionTitle => 'موتور همگام‌سازی';

  @override
  String get syncEngineDescription =>
      'تیکت‌ها، پیام‌رسانی و یادداشت‌ها با تغییرات افزایشی کوچک به‌جای اسنپ‌شات کامل زنده به‌روز می‌شوند. خاموش کردن یک کلید آن فروشگاه را به حالت اسنپ‌شات کامل برمی‌گرداند — برای اعمال، برنامه را دوباره بارگذاری کنید.';

  @override
  String get syncEngineTicketsTitle => 'تیکت‌ها';

  @override
  String get syncEngineMessagingTitle => 'پیام‌رسانی';

  @override
  String get syncEngineNotesTitle => 'یادداشت‌ها';

  @override
  String get syncEngineOnSubtitle => 'همگام‌سازی دلتا زنده فعال است';

  @override
  String get syncEngineOffSubtitle => 'همگام‌سازی اسنپ‌شات کامل';

  @override
  String get spaces => 'فضاها';

  @override
  String get spacesHomeDescription =>
      'فضایی از فهرست انتخاب کنید، یا یکی جدید شروع کنید.';

  @override
  String get noSpacesYet => 'هنوز فضایی نیست';

  @override
  String get newSpace => 'فضای جدید';

  @override
  String get spaceName => 'نام فضا';

  @override
  String get spaceReposHint => 'مخزن‌های شامل';

  @override
  String get ideSourceControl => 'کنترل منبع';

  @override
  String get stagedChanges => 'تغییرات مرحله‌بندی‌شده';

  @override
  String get changes => 'تغییرات';

  @override
  String get stageFile => 'مرحله‌بندی';

  @override
  String get unstageFile => 'خروج از مرحله';

  @override
  String get stageAll => 'مرحله‌بندی همهٔ تغییرات';

  @override
  String get unstageAll => 'خروج همه از مرحله';

  @override
  String get stageChangesToCommit => 'مرحله‌بندی تغییرات برای کامیت';

  @override
  String get syncToPrHead => 'واکشی آخرین کامیت‌های PR';

  @override
  String get syncedToPrHead => 'با آخرین کامیت‌های PR همگام شد';

  @override
  String get syncPrHeadDirty =>
      'پیش از همگام‌سازی کامیت کنید یا تغییرات را دور بیندازید';

  @override
  String get syncPrHeadFailed => 'همگام‌سازی با سر PR ممکن نشد';

  @override
  String get spaceLabel => 'فضا';

  @override
  String get keybindingNewSpace => 'فضای جدید';

  @override
  String get keybindingCreateANewSpaceDescription => 'ایجاد فضای جدید';

  @override
  String get jumpToLatest => 'پرش به آخرین';

  @override
  String get streaming => 'در حال استریم';

  @override
  String get newMessages => 'جدید';

  @override
  String get copyLink => 'کپی پیوند';

  @override
  String get linkCopied => 'پیوند کپی شد';

  @override
  String get agentResponding => 'عامل در حال پاسخ';

  @override
  String get agentFinished => 'عامل تمام کرد';

  @override
  String get harnessConnectProviderForModels =>
      'برای دیدن مدل‌ها یک ارائه‌دهنده وصل کنید.';

  @override
  String get providerSignOut => 'خروج';

  @override
  String get providerWaitingForDeviceCode => 'منتظر تأیید کد در مرورگر شما…';

  @override
  String get providerDeviceCodeHint =>
      'مطمئن شوید این کد با آنچه در مرورگر نشان داده می‌شود یکی است، سپس تأیید کنید.';

  @override
  String get providerPlanUsageLoading => 'در حال بررسی مصرف طرح…';

  @override
  String get providerPlanUsageUnavailable => 'این طرح مصرفی گزارش نکرد.';

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return 'کلید API ⁨$provider⁩ حذف شود؟';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return 'کلید ذخیره‌شده حذف می‌شود و دوباره نشان داده نمی‌شود. عامل‌هایی که از مدل‌های ⁨$provider⁩ استفاده می‌کنند تا جای‌گذاری کلید جدید کار نمی‌کنند.';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return '⁨$provider⁩ حذف شود؟';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return 'ارائه‌دهندهٔ ⁨$provider⁩ و کلید ذخیره‌شده‌اش حذف می‌شوند. عامل‌های قفل‌شده به مدل‌هایش کار را متوقف می‌کنند.';
  }

  @override
  String get providerApiKeyHint => 'یک کلید API جای‌گذاری کنید';

  @override
  String get providerApiKeyStoredHint =>
      'کلید API دیگری جای‌گذاری کنید تا اضافه شود';

  @override
  String get providerAddAnotherAccount => 'افزودن حساب دیگر';

  @override
  String get providerActiveBadge => 'فعال';

  @override
  String get providerOauthAccountFallback => 'حساب OAuth';

  @override
  String get providerApiKeyFallback => 'کلید API';

  @override
  String get providerRemoveCredentialConfirmTitle => 'این اعتبارنامه حذف شود؟';

  @override
  String get providerSignOutAccountConfirmTitle => 'از این حساب خارج شوید؟';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return 'عامل‌های ⁨$provider⁩ به کلیدها و حساب‌های دیگرش برمی‌گردند. اگر هیچ‌کدام نماند تا افزودن یکی کار نمی‌کنند.';
  }

  @override
  String get providerBaseUrlHint => 'URL پایه (اختیاری)';

  @override
  String get addProvider => 'افزودن ارائه‌دهنده';

  @override
  String get noCustomProviders => 'هنوز ارائه‌دهندهٔ سفارشی نیست.';

  @override
  String get providerNameLabel => 'نام';

  @override
  String get apiTypeLabel => 'نوع API';

  @override
  String get providerBaseUrlLabel => 'URL پایه';

  @override
  String get providerApiKeyOptionalHint => 'کلید API (اختیاری)';

  @override
  String get dialectOpenAiCompatible => 'سازگار با OpenAI';

  @override
  String get dialectAnthropicCompatible => 'سازگار با Anthropic';

  @override
  String get removeProviderTooltip => 'حذف ارائه‌دهنده';

  @override
  String get providerLogInWithBrowser => 'ورود با مرورگر';

  @override
  String providerLoginDialogTitle(String provider) {
    return 'ورود به ⁨$provider⁩';
  }

  @override
  String get providerLabel => 'ارائه‌دهنده';

  @override
  String get selectProviderToLogin => 'ارائه‌دهنده‌ای برای ورود انتخاب کنید';

  @override
  String providerLoginFailed(String error) {
    return 'ورود ناموفق: ⁨$error⁩';
  }

  @override
  String get providerWaitingForBrowser => 'منتظر مجوز شما در مرورگر…';

  @override
  String get providerPasteCodeHint => 'یا کد را از مرورگر جای‌گذاری کنید';

  @override
  String get providerCompleteLogin => 'تکمیل';

  @override
  String get providerConnectedApiKey => 'متصل از طریق کلید API';

  @override
  String get providerConnectedOauth => 'متصل';

  @override
  String providerConnectedAccount(String account) {
    return 'متصل · ⁨$account⁩';
  }

  @override
  String get providerLocalReady => 'محلی · آماده';

  @override
  String get providerNotConnected => 'متصل نیست';

  @override
  String get preparingWorkspace => 'آماده‌سازی فضای کاری…';

  @override
  String provisioningRunningSetupScript(String repo) {
    return 'در حال اجرای اسکریپت راه‌اندازی ⁨$repo⁩…';
  }

  @override
  String get repoScriptsTitle => 'اسکریپت‌ها';

  @override
  String get repoScriptsTooltip => 'پیکربندی اسکریپت‌های چرخهٔ حیات';

  @override
  String get repoScriptsSetupLabel => 'اسکریپت راه‌اندازی';

  @override
  String get repoScriptsSetupHelp =>
      'درست پس از ایجاد worktree فضا در آن اجرا می‌شود — نصب وابستگی‌ها، تولید فایل. شکست فضا را ناموفق علامت می‌زند؛ تلاش مجدد دوباره اجرا می‌کند.';

  @override
  String get repoScriptsArchiveLabel => 'اسکریپت بایگانی';

  @override
  String get repoScriptsArchiveHelp =>
      'درست پیش از حذف worktree فضا اجرا می‌شود — پاک‌سازی منابع بیرون از worktree. شکست هرگز حذف را مسدود نمی‌کند.';

  @override
  String get repoScriptsEnvHelp =>
      'از worktree با bash اجرا می‌شود، با ⁨CC_WORKSPACE_PATH⁩ (worktree)، ⁨CC_ROOT_PATH⁩ (ریشهٔ مخزن)، ⁨CC_SPACE_ID⁩، ⁨CC_SPACE_NAME⁩ و ⁨CC_REPO_NAME⁩.';

  @override
  String get repoScriptsSetupPlaceholder => 'مثلاً ⁨pnpm install⁩';

  @override
  String get repoScriptsArchivePlaceholder =>
      'مثلاً ⁨docker compose -p \$CC_SPACE_ID down⁩';

  @override
  String get repoScriptsRecentRuns => 'اجراهای اخیر';

  @override
  String get repoScriptsNoRuns => 'هنوز اجرایی نیست';

  @override
  String get repoScriptsSaved => 'اسکریپت‌ها ذخیره شد';

  @override
  String get repoScriptsRunKindSetup => 'راه‌اندازی';

  @override
  String get repoScriptsRunKindArchive => 'بایگانی';

  @override
  String get repoScriptsRunStatusRunning => 'در حال اجرا';

  @override
  String get repoScriptsRunStatusSucceeded => 'موفق';

  @override
  String get repoScriptsRunStatusFailed => 'ناموفق';

  @override
  String get repoScriptsRunStatusTimedOut => 'زمان‌پر';

  @override
  String repoScriptsExitCode(int code) {
    return 'کد خروج $code';
  }

  @override
  String provisioningCloningRepo(String repo) {
    return 'در حال کلون ⁨$repo⁩…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return 'در حال checkout pull request در ⁨$repo⁩…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return 'در حال راه‌اندازی عامل ⁨$agent⁩…';
  }

  @override
  String get workspacePrepFailed => 'راه‌اندازی فضای کاری ناموفق بود';

  @override
  String get workspacePrepStopped => 'راه‌اندازی فضای کاری متوقف شد';

  @override
  String get stopWorkspacePrep => 'توقف آماده‌سازی';

  @override
  String get stopWorkspacePrepTooltip => 'توقف آماده‌سازی این فضای کاری';

  @override
  String get stopWorkspacePrepConfirm =>
      'آماده‌سازی این فضای کاری متوقف شود؟ کلون در جریان دور ریخته می‌شود — می‌توانید دوباره از اینجا شروع کنید.';

  @override
  String messageWillSendWhenReady(int count) {
    return '$count پیام وقتی آماده شود ارسال می‌شود';
  }

  @override
  String get membersNav => 'اعضا';

  @override
  String get membersSettingsDescription =>
      'افراد با دسترسی به این فضای کاری: فهرست، دعوت‌ها و رد حسابرسی';

  @override
  String get memberRosterLabel => 'فهرست اعضا';

  @override
  String get memberRepoAccessAction => 'دسترسی مخزن';

  @override
  String memberRepoAccessTitle(String name) {
    return 'دسترسی مخزن برای ⁨$name⁩';
  }

  @override
  String get roleOwner => 'مالک';

  @override
  String get roleAdmin => 'ادمین';

  @override
  String get roleMember => 'عضو';

  @override
  String get roleViewer => 'بیننده';

  @override
  String get roleGuest => 'مهمان';

  @override
  String get removeMemberTitle => 'حذف عضو';

  @override
  String removeMemberConfirm(String name) {
    return '⁨$name⁩ از این فضای کاری برداشته شود؟ فوراً دسترسی را از دست می‌دهد.';
  }

  @override
  String get transferOwnershipAction => 'انتقال مالکیت';

  @override
  String get transferOwnershipTitle => 'انتقال مالکیت';

  @override
  String transferOwnershipConfirm(String name) {
    return '⁨$name⁩ مالک این فضای کاری شود؟ شما ادمین می‌شوید. فقط مالک می‌تواند فضای کاری را حذف کند یا نقش ادمین دیگری را عوض کند.';
  }

  @override
  String get transferOwnershipCta => 'انتقال';

  @override
  String get auditTrailLabel => 'رد حسابرسی مجوز';

  @override
  String get auditTrailDescription =>
      'هر اجازه و رد، زنجیره‌شده با هش تا ورودی تغییر یا حذف‌شده قابل تشخیص باشد.';

  @override
  String get auditVerifyChain => 'تأیید زنجیره';

  @override
  String auditChainIntact(int count) {
    return 'زنجیره سالم — $count ورودی تأیید شد';
  }

  @override
  String auditChainBroken(int seq, String reason) {
    return 'زنجیره در ورودی ⁨$seq⁩ شکسته: ⁨$reason⁩';
  }

  @override
  String get auditEmpty => 'هنوز تصمیمی ثبت نشده.';

  @override
  String get auditDenied => 'ردشده';

  @override
  String get auditAllowed => 'مجاز';

  @override
  String auditOnBehalfOf(String user) {
    return 'برای ⁨$user⁩';
  }

  @override
  String get policyTemplatesLabel => 'قالب‌های سیاست';

  @override
  String get policyTemplatesDescription =>
      'یک وضعیت شروع اعمال کنید، یا یکی را بین فضاهای کاری جابه‌جا کنید.';

  @override
  String get policyTemplateStrict => 'سخت‌گیر';

  @override
  String get policyTemplateBalanced => 'متعادل';

  @override
  String get policyTemplatePermissive => 'آزاد';

  @override
  String get policyTemplateApply => 'اعمال';

  @override
  String policyTemplateApplied(int count) {
    return '$count قاعده اعمال شد';
  }

  @override
  String get policyExport => 'کپی سیاست';

  @override
  String get policyExported => 'سیاست در کلیپ‌بورد کپی شد';

  @override
  String get policyImport => 'جای‌گذاری سیاست';

  @override
  String policyImported(int count) {
    return '$count قاعده وارد شد';
  }

  @override
  String get approveAndRemember => 'تأیید برای 8 ساعت';

  @override
  String get approveAndRememberTooltip =>
      'این کنش را تأیید می‌کند و 8 ساعت در این فضا برای موارد مشابه نمی‌پرسد. خودش منقضی می‌شود.';

  @override
  String get unknownUserLabel => 'کاربر ناشناخته';

  @override
  String get inviteMember => 'دعوت عضو';

  @override
  String get inviteRepoAccessHeader => 'دسترسی مخزن';

  @override
  String get inviteRepoAccessExplainer =>
      'فقط مخزن‌هایی که علامت می‌زنید با دعوت‌شده در سطح انتخابی شما به اشتراک گذاشته می‌شود. بقیه پنهان می‌ماند.';

  @override
  String get grantLevelRead => 'خواندن';

  @override
  String get grantLevelReview => 'بازبینی';

  @override
  String get grantLevelWrite => 'نوشتن';

  @override
  String get inviteExpiryLabel => 'انقضا در';

  @override
  String get expiryOneDay => '1 روز';

  @override
  String get expirySevenDays => '7 روز';

  @override
  String get expiryThirtyDays => '30 روز';

  @override
  String get createInviteAction => 'ایجاد دعوت';

  @override
  String get inviteOneTimeCodeLabel => 'کد یک‌بارمصرف';

  @override
  String get inviteCodeShownOnce =>
      'این کد فقط یک‌بار نشان داده می‌شود — همین حالا کپی کنید.';

  @override
  String get inviteLinkLabel => 'پیوند دعوت';

  @override
  String get inviteRedeemHint =>
      'کد را با دعوت‌شده به اشتراک بگذارید؛ آن را در برابر URL سرور شما بازخرید می‌کند.';

  @override
  String get inviteScanQr => 'یا برای بازخرید اسکن کنید';

  @override
  String get inviteLoopbackWarningTitle => 'دعوت به نشانی محلی اشاره دارد';

  @override
  String get inviteLoopbackWarningBody =>
      'همکاران روی ماشین‌های دیگر به این سرور نمی‌رسند. تونلی شروع کنید (تنظیمات ← یکپارچه‌سازی‌ها ← اشتراک این سرور) یا به شبکه وصل شوید تا کاربران خارج از میزبان بتوانند وصل شوند.';

  @override
  String get inviteStatusOpen => 'باز';

  @override
  String get inviteStatusUsed => 'استفاده‌شده';

  @override
  String get inviteStatusRevoked => 'لغوشده';

  @override
  String get inviteStatusExpired => 'منقضی';

  @override
  String inviteCreatedTime(String time) {
    return 'ایجادشده $time';
  }

  @override
  String inviteExpiresOn(String date) {
    return 'انقضا $date';
  }

  @override
  String get noActivityYet => 'هنوز فعالیتی نیست';

  @override
  String get couldNotLoadMembers => 'بارگذاری اعضا ممکن نشد';

  @override
  String get couldNotLoadInvites => 'بارگذاری دعوت‌ها ممکن نشد';

  @override
  String get couldNotLoadActivity => 'بارگذاری فعالیت ممکن نشد';

  @override
  String get yourDevices => 'دستگاه‌های شما';

  @override
  String get yourDevicesDescription =>
      'کلاینت‌های جفت‌شده با حساب شما روی این سرور.';

  @override
  String get noOwnDevices => 'هنوز دستگاهی به حساب شما جفت نشده';

  @override
  String get renameDeviceTitle => 'تغییر نام دستگاه';

  @override
  String get revokeDeviceTitle => 'لغو دستگاه';

  @override
  String revokeDeviceConfirm(String label) {
    return '⁨$label⁩ لغو شود؟ فوراً قطع می‌شود و دیگر به این سرور نمی‌رسد.';
  }

  @override
  String devicePairedTime(String time) {
    return 'جفت‌شده $time';
  }

  @override
  String deviceLastSeenTime(String time) {
    return 'آخرین مشاهده $time';
  }

  @override
  String get deviceNeverSeen => 'هرگز متصل نشده';

  @override
  String get profileSectionLabel => 'نمایه';

  @override
  String get profileSectionDescription =>
      'چگونه در این فضا برای تیم و نویسندگی commit گیت دیده می‌شوید. فیلدهای خالی نام و ایمیل حساب را به ارث می‌برند.';

  @override
  String get displayNameLabel => 'نام نمایشی';

  @override
  String get emailLabel => 'ایمیل';

  @override
  String get gitAuthorNameLabel => 'نام نویسندهٔ Git';

  @override
  String get gitAuthorEmailLabel => 'ایمیل نویسندهٔ Git';

  @override
  String get profileSaved => 'نمایه ذخیره شد';

  @override
  String get presenceOnline => 'آنلاین';

  @override
  String get presenceIdle => 'بیکار';

  @override
  String get presenceTyping => 'در حال تایپ…';

  @override
  String get presenceAgentThinking => 'در حال فکر';

  @override
  String get presenceAgentRunning => 'در حال اجرا';

  @override
  String get presenceAgentBlocked => 'مسدود';

  @override
  String get presenceAgentDone => 'انجام‌شده';

  @override
  String presenceNameStatus(String name, String status) {
    return '⁨$name⁩ — ⁨$status⁩';
  }

  @override
  String presenceNameStatusCost(String name, String status, String cost) {
    return '⁨$name⁩ — ⁨$status⁩ (⁨$cost⁩)';
  }

  @override
  String get presenceRailLabel => 'چه کسی آنلاین است';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => 'روشن کردن مزاحم نشوید';

  @override
  String get dndTooltipOff => 'خاموش کردن مزاحم نشوید';

  @override
  String get startPresenting => 'شروع ارائه';

  @override
  String get stopPresenting => 'توقف ارائه';

  @override
  String spotlightPresentingBanner(String name) {
    return '⁨$name⁩ در حال ارائه است';
  }

  @override
  String get spotlightLeave => 'ترک';

  @override
  String typingIndicator(String name) {
    return '⁨$name⁩ در حال تایپ است…';
  }

  @override
  String get ideTabNotes => 'یادداشت‌ها';

  @override
  String get ideSidebarAllViews => 'همهٔ نماها';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return 'همهٔ نماها ($count پنهان)';
  }

  @override
  String get ideSidebarPinView => 'سنجاق به نوار کناری';

  @override
  String get ideSidebarUnpinView => 'برداشتن سنجاق از نوار کناری';

  @override
  String get notesEmptyHint =>
      'برای هر کسی که این گفتگو را بردارد یادداشتی اضافه کنید…';

  @override
  String get notesEditTooltip => 'ویرایش یادداشت';

  @override
  String notesUpdatedBy(String name, String time) {
    return 'به‌روزرسانی توسط ⁨$name⁩ · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '⁨$name⁩ در حال ویرایش است';
  }

  @override
  String get notesSaveFailed => 'ذخیرهٔ یادداشت ممکن نشد';

  @override
  String get reactionAddTooltip => 'افزودن واکنش';

  @override
  String reactionToggleTooltip(String emoji) {
    return 'واکنش با ⁨$emoji⁩';
  }

  @override
  String get autonomyDialLabel => 'خودمختاری';

  @override
  String get autonomyProposeOnly => 'فقط پیشنهاد';

  @override
  String get autonomyActWithApproval => 'عمل با تأیید';

  @override
  String get autonomyActFreely => 'عمل آزاد';

  @override
  String get autonomyDefaultOption => 'پیش‌فرض';

  @override
  String get checkerLabel => 'بررسی‌کننده';

  @override
  String get checkerNone => 'هیچ';

  @override
  String get checkerCaption =>
      'بررسی‌کننده اجراهای کامل‌شدهٔ عامل‌های دیگر را بازبینی می‌کند.';

  @override
  String get takeoverTooltip => 'تصاحب worktree';

  @override
  String get takeoverBannerSelf => 'worktree این گفتگو را تصاحب کرده‌اید';

  @override
  String takeoverBannerOther(String name) {
    return '⁨$name⁩ worktree این گفتگو را تصاحب کرده';
  }

  @override
  String get handBackButton => 'بازگرداندن';

  @override
  String get handBackDialogTitle => 'بازگرداندن worktree';

  @override
  String get handBackDialogNoteHint => 'یادداشت اختیاری برای عامل…';

  @override
  String takeoverFailed(String message) {
    return 'تصاحب ممکن نشد: ⁨$message⁩';
  }

  @override
  String handBackFailed(String message) {
    return 'بازگرداندن ممکن نشد: ⁨$message⁩';
  }

  @override
  String get planStudioTitle => 'Plan Studio';

  @override
  String get plansTitle => 'برنامه‌ها';

  @override
  String get plansSubtitle => 'برنامه‌های فعال، اسناد برنامه و کتابچه‌ها';

  @override
  String get plansActiveSection => 'برنامه‌های فعال';

  @override
  String get plansDocumentsSection => 'اسناد برنامه';

  @override
  String get plansPlaybooksSection => 'کتابچه‌ها';

  @override
  String get plansNoActive => 'هنوز برنامهٔ فعالی نیست.';

  @override
  String get plansNoDocuments => 'هنوز سند برنامه‌ای نیست.';

  @override
  String get plansNoPlaybooks => 'هنوز کتابچه‌ای نیست.';

  @override
  String get planNotFound => 'برنامه یافت نشد.';

  @override
  String get planOpenInStudio => 'باز کردن';

  @override
  String get planNodeTitle => 'عنوان';

  @override
  String get planNodeDescription => 'شرح';

  @override
  String get planNodeDescriptionHint => 'این گام باید چه کند…';

  @override
  String get planNodeApplyDescription => 'اعمال';

  @override
  String get planNodeRole => 'نقش';

  @override
  String get planNodeDependencies => 'وابسته به';

  @override
  String get planNodeDependenciesHint => 'افزودن وابستگی';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count وابستگی',
      one: '1 وابستگی',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies =>
      'بدون وابستگی، پس به‌محض شروع برنامه اجرا می‌شود';

  @override
  String get planNodeOutputSchema => 'شِمای خروجی (JSON)';

  @override
  String get planNodeEstimate => 'برآورد';

  @override
  String get planNodeProvenance => 'منشأ';

  @override
  String get planNodeAlreadyExecuted =>
      'از قبل اجرا شده — ویرایش برنامه را از اینجا شاخه می‌کند.';

  @override
  String get planNewNodeTitle => 'گام جدید';

  @override
  String get planEstimateNoHistory => 'هنوز تاریخچه‌ای نیست';

  @override
  String get planEstimateBlastUnknown => 'شعاع اثر: ناشناخته';

  @override
  String get planEstimatePartial => 'جزئی';

  @override
  String get planEstimateAction => 'برآورد';

  @override
  String planEstimateDuration(String range) {
    return 'مدت $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return 'شعاع اثر: $files فایل، $symbols نماد';
  }

  @override
  String get planApprove => 'تأیید برنامه';

  @override
  String get planApproveSelectedNodes => 'تأیید انتخاب‌شده‌ها';

  @override
  String get planReject => 'رد';

  @override
  String get planCancel => 'لغو اجرا';

  @override
  String get planContinueNode => 'ادامهٔ گره';

  @override
  String get planTotalNotEstimated => 'هنوز برآورد نشده';

  @override
  String get planBudgetExceeded => 'فراتر از بودجه';

  @override
  String planBudgetCeiling(String amount) {
    return 'بودجه ≤ ⁨\$$amount⁩';
  }

  @override
  String get planVersionsTitle => 'نسخه‌ها';

  @override
  String get planNoRevisions => 'هنوز بازبینی‌ای نیست.';

  @override
  String get planDiffIdentical => 'بدون تغییر.';

  @override
  String get planDiffGoalChanged => 'هدف تغییر کرد';

  @override
  String get planDiffBudgetChanged => 'بودجه تغییر کرد';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'تغییرات از v$fromRev تا v$toRev';
  }

  @override
  String planDiffAdded(String node) {
    return '⁨$node⁩ افزوده شد';
  }

  @override
  String planDiffRemoved(String node) {
    return '⁨$node⁩ برداشته شد';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return '⁨$node⁩ تغییر کرد: ⁨$fields⁩';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return 'یال افزوده شد: ⁨$edge⁩';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return 'یال برداشته شد: ⁨$edge⁩';
  }

  @override
  String planDiffRoleAdded(String role) {
    return 'نقش افزوده شد: ⁨$role⁩';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return 'نقش برداشته شد: ⁨$role⁩';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return 'نقش دوباره تخصیص یافت: ⁨$role⁩';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return 'برنامه دوباره طرح شد: شما v$approved را تأیید کردید، اکنون v$current است. پیش از ادامه دیف را ببینید.';
  }

  @override
  String planLiveActualCost(String amount) {
    return 'هزینهٔ واقعی: ⁨\$$amount⁩';
  }

  @override
  String get planPlaybookRun => 'اجرا';

  @override
  String get planPlaybookDelete => 'حذف کتابچه';

  @override
  String get planPlaybookProposed =>
      'برنامه پیشنهاد شد — در Plan Studio تأییدش کنید.';

  @override
  String get planPlaybookAnchorTicket => 'تیکت لنگر';

  @override
  String get planPlaybookPickTicket => 'یک تیکت انتخاب کنید…';

  @override
  String get planPlaybookProposeRun => 'پیشنهاد برنامه';

  @override
  String get planPlaybookRepoHint => 'شناسهٔ یک مخزن';

  @override
  String get planPlaybookAgentHint => 'شناسهٔ یک عامل';

  @override
  String planPlaybookRunTitle(String name) {
    return 'اجرای ⁨$name⁩';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '$count پارامتر';
  }

  @override
  String get recentLabel => 'اخیر';

  @override
  String get cheatSheetTitle => 'میانبرهای صفحه‌کلید';

  @override
  String get cheatSheetGlobal => 'سراسری';

  @override
  String get cheatSheetThisScreen => 'این صفحه';

  @override
  String get cheatSheetReservedInBrowser => 'رزرو مرورگر';

  @override
  String get keybindingCheatSheet => 'میانبرهای صفحه‌کلید';

  @override
  String get keybindingShowKeyboardShortcutsDescription =>
      'نمایش برگهٔ میانبرهای صفحه‌کلید برای صفحهٔ فعلی';

  @override
  String get runPlaybookLabel => 'اجرای کتابچه';

  @override
  String get playbooksLabel => 'کتابچه‌ها';

  @override
  String get keybindingUndo => 'واگرد';

  @override
  String get keybindingRedo => 'ازنو';

  @override
  String get keybindingUndoLastActionDescription =>
      'واگرد آخرین کنش برگشت‌پذیر';

  @override
  String get keybindingRedoLastActionDescription => 'ازنو آخرین کنش واگردشده';

  @override
  String get undone => 'واگرد شد';

  @override
  String get redone => 'ازنو شد';

  @override
  String get undoFailed => 'واگرد ممکن نشد';

  @override
  String get undoLabelTicketEdit => 'ویرایش تیکت';

  @override
  String get undoLabelMessageEdit => 'ویرایش پیام';

  @override
  String get undoLabelTodoStatus => 'وضعیت کار';

  @override
  String get inboxTitle => 'صندوق ورودی';

  @override
  String get inboxReview => 'بازبینی';

  @override
  String get inboxOpen => 'باز';

  @override
  String get inboxAllCaughtUp => 'همه را دیده‌اید';

  @override
  String get inboxGitHubDownTitle => 'GitHub ممکن است قطع باشد';

  @override
  String inboxGitHubDownBody(String status) {
    return 'GitHub وضعیت ⁨$status⁩ گزارش می‌کند، پس pull requestها ممکن است از این فهرست غایب باشند نه اینکه واقعاً تمام شده باشند.';
  }

  @override
  String get inboxGitHubIdentityTitle => 'تأیید حساب GitHub شما ممکن نشد';

  @override
  String get inboxGitHubIdentityBody =>
      'صندوق ورودی بر اساس هویت شما در GitHub مرتب می‌شود. تا بارگذاری خالی می‌ماند، حتی اگر pull request منتظر شما باشد.';

  @override
  String get inboxSeverityBlocking => 'مسدود';

  @override
  String get inboxSeverityWaiting => 'در انتظار';

  @override
  String get inboxSeverityInfo => 'اطلاعات';

  @override
  String get inboxSyncFailed => 'همگام‌سازی ناموفق';

  @override
  String get inboxNeedsYourAttention => 'نیاز به توجه شما';

  @override
  String get inboxSectionNeedsYourReview => 'نیاز به بازبینی شما';

  @override
  String get inboxSectionReturnedToYou => 'بازگشته به شما';

  @override
  String get inboxSectionApproved => 'تأییدشده';

  @override
  String get inboxSectionDrafts => 'پیش‌نویس‌ها';

  @override
  String get inboxSectionWaitingForReviewers => 'در انتظار بازبین‌ها';

  @override
  String get inboxSectionMergingAndMerged => 'در حال ادغام و اخیراً ادغام‌شده';

  @override
  String get inboxSectionWaitingForAuthor => 'در انتظار نویسنده';

  @override
  String get inboxColumnTitle => 'عنوان';

  @override
  String get inboxColumnChanges => 'تغییرات';

  @override
  String get inboxColumnUpdated => 'به‌روزرسانی';

  @override
  String get inboxReviewApproved => 'تأییدشده';

  @override
  String get inboxReviewChangesRequested => 'درخواست تغییرات';

  @override
  String get inboxHeroSubtitle =>
      'هر pull request که شما را درگیر می‌کند، مرتب بر اساس گام بعدی.';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull request نیاز به بازبینی شما دارند',
      one: '1 pull request نیاز به بازبینی شما دارد',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مورد بازگشته به شما',
      one: '1 مورد بازگشته به شما',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted => 'آن تغییر ذخیره نشد و برگردانده شد';

  @override
  String get offlinePendingLabel => 'در انتظار';

  @override
  String get offlineSyncingLabel => 'در حال همگام‌سازی';

  @override
  String get copyLinkLabel => 'کپی پیوند این صفحه';

  @override
  String get agentsSectionLabel => 'عامل‌ها';

  @override
  String get fleetWorkersTitle => 'کارگران';

  @override
  String get fleetWorkersSubtitle => 'ماشین‌های آماده برای اجرای کار';

  @override
  String get fleetJobsTitle => 'کارها';

  @override
  String get fleetJobsSubtitle => 'کار توزیع‌شده در ناوگان';

  @override
  String get fleetNoWorkers =>
      'هنوز کارگری نیست — ماشین دومی که ⁨cc_worker --server <url>⁩ را اجرا کند به ناوگان می‌پیوندد.';

  @override
  String get fleetNoJobs => 'کاری نیست.';

  @override
  String get fleetError => 'بارگذاری ناوگان ممکن نشد';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count هسته',
      one: '1 هسته',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return 'ضربان $time';
  }

  @override
  String get fleetNoHeartbeat => 'هنوز ضربانی نیست';

  @override
  String fleetLastErrorLabel(String error) {
    return 'آخرین خطا: ⁨$error⁩';
  }

  @override
  String get fleetDrain => 'تخلیه';

  @override
  String get fleetResume => 'ازسرگیری';

  @override
  String get fleetRevoke => 'لغو';

  @override
  String get fleetRemove => 'برداشتن';

  @override
  String get fleetRevokeTitle => 'کارگر لغو شود؟';

  @override
  String fleetRevokeBody(String name) {
    return '⁨$name⁩ لغو شود؟ نشستش تمام می‌شود و کارهای فعال دوباره تخصیص می‌یابند.';
  }

  @override
  String get fleetRemoveTitle => 'کارگر برداشته شود؟';

  @override
  String fleetRemoveBody(String name) {
    return '⁨$name⁩ از ناوگان برداشته شود؟ رکوردش حذف می‌شود.';
  }

  @override
  String get fleetActionFailed => 'کنش ناموفق بود';

  @override
  String get fleetJobUnassigned => 'بدون تخصیص';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '$attempts/$max تلاش';
  }

  @override
  String get fleetPlacementReasons => 'تصمیم‌های جاگذاری';

  @override
  String get fleetNoPlacements => 'هنوز تصمیم جاگذاری نیست.';

  @override
  String get fleetStatusOnline => 'آنلاین';

  @override
  String get fleetStatusDraining => 'در حال تخلیه';

  @override
  String get fleetStatusOffline => 'آفلاین';

  @override
  String get fleetStatusIncompatible => 'ناسازگار';

  @override
  String get fleetStatusRevoked => 'لغوشده';

  @override
  String get fleetJobStatusQueued => 'در صف';

  @override
  String get fleetJobStatusRunning => 'در حال اجرا';

  @override
  String get fleetJobStatusSucceeded => 'موفق';

  @override
  String get fleetJobStatusFailed => 'ناموفق';

  @override
  String get fleetJobStatusCancelled => 'لغوشده';

  @override
  String get evalsNoSuites => 'هنوز مجموعهٔ ارزیابی نیست.';

  @override
  String get evalsError => 'بارگذاری ارزیابی‌ها ممکن نشد';

  @override
  String get evalsStarterBadge => 'شروع';

  @override
  String evalsDefaultBatch(int count) {
    return 'دستهٔ پیش‌فرض $count';
  }

  @override
  String get evalsRecentRuns => 'اجراهای اخیر';

  @override
  String get evalsNoRuns => 'هنوز اجرایی نیست.';

  @override
  String get evalsPassRate => 'نرخ موفقیت';

  @override
  String evalsBatchTimes(int count) {
    return '× $count';
  }

  @override
  String evalsTriggeredBy(String who) {
    return 'توسط ⁨$who⁩';
  }

  @override
  String evalsRunFinished(String rate) {
    return 'ارزیابی تمام شد — $rate موفق';
  }

  @override
  String get evalsRunFailed => 'اجرای مجموعه ممکن نشد';

  @override
  String get evalsRun => 'اجرا';

  @override
  String get evalsStatusQueued => 'در صف';

  @override
  String get evalsStatusRunning => 'در حال اجرا';

  @override
  String get evalsStatusPassed => 'موفق';

  @override
  String get evalsStatusFailed => 'ناموفق';

  @override
  String get bannerMeetingJoin => 'پیوستن';

  @override
  String get bannerMeetingRecordAndLink => 'ضبط و پیوند';

  @override
  String get bannerCalendarReconnect => 'اتصال مجدد';

  @override
  String get bannerView => 'نمایش';

  @override
  String get soundscapeTitle => 'منظرهای صوتی';

  @override
  String get soundscapePlay => 'پخش';

  @override
  String get soundscapePause => 'مکث';

  @override
  String get soundscapeMoodLabel => 'حال‌وهوا';

  @override
  String get soundscapeMoodFocus => 'تمرکز';

  @override
  String get soundscapeMoodRelax => 'آرامش';

  @override
  String get soundscapeMoodSleep => 'خواب';

  @override
  String get soundscapeMoodRise => 'خیز';

  @override
  String get soundscapeVolumeLabel => 'بلندی صدا';

  @override
  String get soundscapeTuneLabel => 'تنظیم';

  @override
  String get soundscapeTuneMellow => 'ملایم';

  @override
  String get soundscapeTuneBright => 'درخشان';

  @override
  String get soundscapeTuneEnergetic => 'پرانرژی';

  @override
  String get soundscapeTuneSpacy => 'فضایی';

  @override
  String get soundscapeTuneResetHint => 'دوبار ضربه برای بازنشانی';

  @override
  String get soundscapeSceneLabel => 'در حال پخش';

  @override
  String get soundscapeSceneLoading => 'در حال تنظیم فضا…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees°C';
  }

  @override
  String get soundscapeLocationLabel => 'موقعیت';

  @override
  String get soundscapeLocationDetecting => 'در حال تشخیص موقعیت…';

  @override
  String get soundscapeLocationAutoNote => 'موقعیت از این دستگاه می‌آید.';

  @override
  String get soundscapeRefreshWeather => 'تازه‌سازی هوا';

  @override
  String get soundscapeAutoStartLabel => 'شروع با حالت تمرکز';

  @override
  String get soundscapeAutoStartDescription =>
      'وقتی نشست تمرکز شروع می‌شود منظر صوتی خودکار پخش شود.';

  @override
  String get soundscapeReturnToApp => 'بازگشت به برنامه';

  @override
  String get soundscapePopOut => 'جدا کردن پخش‌کننده';

  @override
  String get discussion => 'بحث';

  @override
  String get chat => 'گفتگو';

  @override
  String get saving => 'در حال ذخیره…';

  @override
  String get saved => 'ذخیره شد';

  @override
  String get saveFailed => 'ذخیره ممکن نشد';

  @override
  String get commitAndPush => 'کامیت و پوش';

  @override
  String get commit => 'کامیت';

  @override
  String get commitAmend => 'کامیت (اصلاح)';

  @override
  String get commitAndSync => 'کامیت و همگام‌سازی';

  @override
  String get scmSyncChanges => 'همگام‌سازی تغییرات';

  @override
  String get scmPublishBranch => 'انتشار شاخه';

  @override
  String get scmSyncFailed => 'همگام‌سازی ناموفق بود';

  @override
  String get scmSyncDirty =>
      'پیش از همگام‌سازی تغییرات را کامیت کنید یا کنار بگذارید';

  @override
  String get scmSynced => 'همگام شد';

  @override
  String get scmSelectBranch => 'یک شاخه برای چک‌اوت انتخاب کنید';

  @override
  String get scmCreateBranch => 'ایجاد شاخه جدید…';

  @override
  String get scmCreateBranchFrom => 'ایجاد شاخه جدید از…';

  @override
  String get scmCheckoutDetached => 'چک‌اوت جدا…';

  @override
  String get scmBranchName => 'نام شاخه';

  @override
  String get scmCreateBranchTitle => 'ایجاد شاخه';

  @override
  String scmFromRef(String ref) {
    return 'از ⁨$ref⁩';
  }

  @override
  String get scmCheckoutFailed => 'تغییر شاخه ممکن نشد';

  @override
  String get scmCheckoutDirty =>
      'پیش از تغییر شاخه، تغییرات را ثبت یا لغو کنید';

  @override
  String scmSwitchedToBranch(String branch) {
    return 'به ⁨$branch⁩ تغییر کرد';
  }

  @override
  String scmDetachedAt(String ref) {
    return 'جدا در ⁨$ref⁩';
  }

  @override
  String get scmDetachedHead => 'HEAD جدا';

  @override
  String get scmNoBranches => 'شاخه‌ای مطابق نیست';

  @override
  String get scmBranches => 'شاخه‌ها';

  @override
  String get scmRemoteBranches => 'شاخه‌های راه دور';

  @override
  String get scmTags => 'برچسب‌ها';

  @override
  String get scmPickStartPoint => 'یک نقطه شروع انتخاب کنید';

  @override
  String get scmSwitchBranch => 'تغییر شاخه';

  @override
  String commitMessageOnBranch(String shortcut, String branch) {
    return 'پیام ($shortcut برای کامیت روی «$branch»)';
  }

  @override
  String get committed => 'کامیت شد';

  @override
  String get commitAmended => 'کامیت اصلاح شد';

  @override
  String get commitFailed => 'کامیت ناموفق';

  @override
  String get moreCommitActions => 'کنش‌های بیشتر کامیت';

  @override
  String get sourceControl => 'کنترل منبع';

  @override
  String fixFindingTitle(String location) {
    return 'رفع: ⁨$location⁩';
  }

  @override
  String get openInEditor => 'باز کردن در ویرایشگر';

  @override
  String get regexTesterTitle => 'آزمایش عبارت منظم';

  @override
  String get regexTesterHint => 'یک نمونه بنویسید';

  @override
  String get regexMatch => 'مطابقت';

  @override
  String get regexNoMatch => 'بدون مطابقت';

  @override
  String get regexInvalidPattern => 'الگوی نامعتبر';

  @override
  String get symbolLookupNone =>
      'هیچ تعریفی در ایندکس یا این درخواست ادغام نیست';

  @override
  String get symbolLookupInDiff => 'یافت‌شده در این درخواست ادغام';

  @override
  String get symbolLookupFromBase =>
      'از چک‌اوت پایه — درخت کاری این PR هنوز ایندکس نشده است';

  @override
  String get symbolImplementations => 'پیاده‌سازی‌ها';

  @override
  String symbolCallersCount(int count) {
    return '$count فراخوان';
  }

  @override
  String get commitMessageHint => 'پیام کامیت';

  @override
  String get pushedToPr => 'به PR پوش شد';

  @override
  String get pushFailed => 'پوش ناموفق';

  @override
  String get reviewFindings => 'یافته‌ها';

  @override
  String get treeLabel => 'درخت';

  @override
  String get toggleFileTree => 'نمایش یا پنهان کردن درخت فایل';

  @override
  String get diffViewSettings => 'تنظیمات نمای دیف';

  @override
  String get splitViewLabel => 'شکافته';

  @override
  String get unifiedViewLabel => 'یکپارچه';

  @override
  String get wrapLines => 'شکستن خطوط';

  @override
  String get shiftClickSelectRange => 'Shift-کلیک برای انتخاب بازه';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فایل',
      one: '1 فایل',
    );
    return '$_temp0';
  }

  @override
  String prComplexityLoc(String loc) {
    return '$loc LOC';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return 'PR کوچک — $files، حدود $minutes دقیقه برای بازبینی';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return 'PR متوسط — $files، حدود $minutes دقیقه برای بازبینی';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return 'PR بزرگ — $files، پیش از بازبینی تقسیم را در نظر بگیرید';
  }

  @override
  String get searchInFiles => 'جستجو در فایل‌ها';

  @override
  String get showFileList => 'نمایش فهرست فایل';

  @override
  String get searchInFilesHintField => 'جستجو در فایل‌ها…';

  @override
  String get searchInFilesHint => 'جستجو در فایل‌های pull request';

  @override
  String get searchInWholeRepo => 'جستجو در کل مخزن';

  @override
  String get searchInThisPullRequest => 'جستجو در این pull request';

  @override
  String get searchNoResults => 'نتیجه‌ای یافت نشد';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نتیجه',
      one: '1 نتیجه',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files فایل',
      one: '1 فایل',
    );
    return '$_temp0 در $_temp1';
  }

  @override
  String get discardChangesTitle => 'تغییرات دور انداخته شود؟';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فایل',
      one: '1 فایل',
    );
    return '$_temp0 به HEAD دور انداخته شود؟ این کار برگشت‌ناپذیر است.';
  }

  @override
  String get discardAll => 'دور انداختن همه';

  @override
  String get discardFailed => 'دور انداختن تغییرات ناموفق بود';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فایل',
      one: '1 فایل',
    );
    return '$_temp0 دور انداخته شد';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '$reverted فایل',
      one: '1 فایل',
    );
    return '$_temp0 دور انداخته شد؛ $skipped رد شد (ردیابی‌نشده)';
  }

  @override
  String get prWorktreeUnavailable => 'فضای کاری آماده نیست';

  @override
  String get prWorktreeUnavailableHint =>
      'آماده‌سازی فایل‌های pull request ناموفق بود. pull request را دوباره باز کنید.';

  @override
  String get timestampRelativeLabel => 'نسبی';

  @override
  String get timestampRawLabel => 'برچسب زمانی';

  @override
  String get copyTimestamp => 'کپی برچسب زمانی';

  @override
  String get copiedTimestamp => 'برچسب زمانی کپی شد';

  @override
  String get previewDeployment => 'پیش‌نمایش استقرار';

  @override
  String previewDeploymentTab(String site) {
    return 'پیش‌نمایش: ⁨$site⁩';
  }

  @override
  String get askForReview => 'درخواست بازبینی…';

  @override
  String get closePrsConfirmTitle => 'pull requestها بسته شوند؟';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull request بسته شوند؟',
      one: '1 pull request بسته شود؟',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull request بسته شد',
      one: '1 pull request بسته شد',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull request تخصیص یافت',
      one: '1 pull request تخصیص یافت',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بازبینی روی $count pull request درخواست شد',
      one: 'بازبینی روی 1 pull request درخواست شد',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کنش ناموفق',
      one: '1 کنش ناموفق',
    );
    return '$_temp0';
  }

  @override
  String get diagram => 'نمودار';

  @override
  String get diagramViewSource => 'نمایش منبع';

  @override
  String get diagramHideSource => 'پنهان کردن منبع';

  @override
  String diagramPreviewUnavailable(String reason) {
    return 'پیش‌نمایش نمودار در دسترس نیست (⁨$reason⁩)';
  }

  @override
  String get planUnavailable => 'برنامه در دسترس نیست';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count گام',
      one: '1 گام',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => 'تأیید و اجرا';

  @override
  String get planStatusDraft => 'پیش‌نویس';

  @override
  String get planStatusProposed => 'برنامه';

  @override
  String get planStatusApproved => 'برنامه تأیید شد';

  @override
  String get planStatusRejected => 'برنامه رد شد';

  @override
  String get planStatusSuperseded => 'برنامه جایگزین شد';

  @override
  String planRevisionLabel(int revision) {
    return 'بازبینی $revision';
  }

  @override
  String get adapterEnforcementTitle => 'آنچه این آداپتر اعمال می‌کند';

  @override
  String get enforcementFiltersToolSurface =>
      'Control Center ابزارها را انتخاب می‌کند';

  @override
  String get enforcementInterceptsToolCalls =>
      'هر فراخوانی پیش از اجرا دروازه‌بندی می‌شود';

  @override
  String get enforcementObservesCompletionContract =>
      'اجرا به تحویل‌دادنی‌اش مقید می‌ماند';

  @override
  String get enforcementNativeToolsInterceptable =>
      'ابزارهای خود اجراکننده دیده می‌شوند';

  @override
  String get enforcementInProcessToolsSandboxed =>
      'ابزارهای درون‌پردازشی سندباکس می‌شوند';

  @override
  String get enforcementYes => 'بله';

  @override
  String get enforcementNo => 'خیر';

  @override
  String get adapterEnforcementCaveats => 'محدودیت‌ها';

  @override
  String get enforcementSummaryModesEnforced => 'حالت‌ها اعمال می‌شوند';

  @override
  String get enforcementSummaryModesNotEnforced => 'حالت‌ها اعمال نمی‌شوند';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count محدودیت',
      one: '1 محدودیت',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      'حالت‌های فقط‌خواندنی ساختاری نیستند: Control Center نمی‌تواند ابزارهای خود این اجراکننده را بردارد.';

  @override
  String get caveatToolCallsNotIntercepted =>
      'بدون دروازهٔ پیش‌اجرا: فقط فراخوانی‌های ابزار MCP از Control Center می‌گذرند.';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      'ابزارهای فایل و شل خود اجراکننده هرگز به Control Center نمی‌رسند؛ سندباکس سیستم‌عامل تنها کف زیر آن‌هاست.';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      'ابزارهای فایل درون‌پردازشی بیرون از سندباکس اجرا می‌شوند، پس سطح ابزار تنها مرز فایل‌سیستم است.';

  @override
  String get caveatCompletionContractUnobservable =>
      'Control Center نمی‌تواند اجرایی را که بدون تحویل‌دادنی تمام شود هشدار دهد یا شکست دهد.';

  @override
  String get modeDegraded => 'تضعیف‌شده';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return 'حالت ⁨$mode⁩ روی ⁨$adapter⁩ فقط به سندباکس متکی است؛ ابزارهای فایل خود عامل رهگیری نمی‌شوند.';
  }

  @override
  String get artifactUnavailable => 'آرتیفکت در دسترس نیست';

  @override
  String artifactRevisionLabel(int count) {
    return '$count بازبینی';
  }

  @override
  String get artifactShowMore => 'نمایش بیشتر';

  @override
  String get artifactShowLess => 'نمایش کمتر';

  @override
  String get artifactCopy => 'کپی';

  @override
  String get artifactCopied => 'آرتیفکت کپی شد';

  @override
  String get artifactsTabLabel => 'آرتیفکت‌ها';

  @override
  String get artifactsEmptyTitle => 'هنوز آرتیفکتی نیست';

  @override
  String get artifactsEmptyBody =>
      'وقتی عاملی جدول، نمودار یا دیاگرام اینجا منتشر کند، در این فهرست ظاهر می‌شود.';

  @override
  String get artifactRevisionPickerLabel => 'بازبینی';

  @override
  String get artifactRestoreRevision => 'بازیابی این بازبینی';

  @override
  String get artifactOpenInTab => 'باز کردن در زبانه';

  @override
  String get artifactTitleFallback => 'آرتیفکت';

  @override
  String get providerGenerationLabel => 'پیش‌فرض‌های تولید';

  @override
  String get providerGenerationHint =>
      'فیلدی را خالی بگذارید تا پیش‌فرض خود نقطهٔ پایانی استفاده شود. مدل‌ها سقف خروجی و دستور پخت نمونه‌برداری خود را اعلام می‌کنند؛ سرو کردن با مقادیر دیگر ممکن است کیفیت را کم کند.';

  @override
  String get providerMaxTokensLabel => 'حداکثر توکن خروجی';

  @override
  String get addModel => 'افزودن مدل';

  @override
  String get modelListTitle => 'فهرست مدل';

  @override
  String get railProvidersGroup => 'ارائه‌دهندگان';

  @override
  String get railCustomProvidersGroup => 'ارائه‌دهندگان سفارشی';

  @override
  String get editModelSettings => 'ویرایش تنظیمات مدل';

  @override
  String get modelIdLabel => 'شناسهٔ مدل';

  @override
  String get modelIdImmutableHint =>
      'شناسه‌ای که نقطهٔ پایانی سرو می‌کند؛ پس از فهرست شدن ثابت است.';

  @override
  String get contextWindowLabel => 'پنجرهٔ زمینه';

  @override
  String get inputTypesLabel => 'انواع ورودی';

  @override
  String get outputTypesLabel => 'انواع خروجی';

  @override
  String get modalityText => 'متن';

  @override
  String get modalityImage => 'تصویر';

  @override
  String get modalityAudio => 'صدا';

  @override
  String get modalityVideo => 'ویدیو';

  @override
  String get modalityPdf => 'PDF';

  @override
  String get modelOverrideReset => 'بازنشانی به خودکار';

  @override
  String get modelOverrideEdited => 'ویرایش‌شده';

  @override
  String get manualModelBadge => 'دستی افزوده';

  @override
  String get modelIdRequired => 'شناسهٔ مدل را وارد کنید.';

  @override
  String get modelTokensInvalid => 'عدد صحیح مثبت توکن وارد کنید.';

  @override
  String get removeModelAction => 'حذف مدل';

  @override
  String removeModelConfirmTitle(String model) {
    return '⁨$model⁩ حذف شود؟';
  }

  @override
  String get removeModelConfirmBody =>
      'مدل از فهرست خارج می‌شود و عامل‌های قفل‌شده به آن کار را متوقف می‌کنند. ارائه‌دهنده بی‌تأثیر است.';

  @override
  String get addModelProviderTitle => 'افزودن ارائه‌دهندهٔ مدل';

  @override
  String get addModelProviderDescription =>
      'یک نقطهٔ پایانی API سفارشی و مدل‌هایش را پیکربندی کنید.';

  @override
  String get modelListEmptyHint =>
      'مدلی پیکربندی نشده. مدلی اضافه کنید تا در گفتگو استفاده شود.';

  @override
  String get addProviderModelsHint =>
      'مدل‌ها به‌محض پاسخ نقطهٔ پایانی زنده واکشی می‌شوند. فقط اگر نتواند خودش را فهرست کند دستی اضافه کنید.';

  @override
  String get providerTemperatureLabel => 'دما';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved => 'پیش‌فرض‌های تولید ذخیره شد';

  @override
  String get providerGenerationInvalid =>
      'مقادیر را بررسی کنید: حداکثر توکن خروجی و top-k باید مثبت باشند، دما 0–2، top-p 0–1.';

  @override
  String get providerGenerationOverridden => 'بازنویسی‌شده';

  @override
  String get branchNotPushed => 'پوش نشده';

  @override
  String branchNotOnRemote(String branch) {
    return '«⁨$branch⁩» فقط در این گفتگو وجود دارد';
  }

  @override
  String get branchNotOnRemoteHint =>
      'GitHub هرگز این شاخه را ندیده، پس هنوز نمی‌توان pull request از آن ساخت. انتشار کامیت‌های موجود در worktree را پوش می‌کند — تغییرات کامیت‌نشده دست‌نخورده می‌مانند.';

  @override
  String get publishBranch => 'انتشار شاخه';

  @override
  String branchPublished(String branch) {
    return '«⁨$branch⁩» به origin منتشر شد';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return 'شاخه منتشر شد. $count تغییر کامیت‌نشده شامل نشد.';
  }

  @override
  String get composePrLoadingBranches => 'در حال بارگذاری شاخه‌ها از GitHub…';

  @override
  String get composePrBranchesFailed =>
      'بارگذاری شاخه‌ها از GitHub ممکن نشد. نام شاخه را تایپ کنید، یا اتصال GitHub را بررسی کنید.';

  @override
  String get composePrSubtitleFromSpace =>
      'از شاخهٔ این گفتگو — اگر GitHub ندیده‌اش، اول منتشرش کنید';

  @override
  String get obsTabInsights => 'بینش‌ها';

  @override
  String get obsTabLive => 'زنده';

  @override
  String get obsTabQuality => 'کیفیت';

  @override
  String get obsTabUsage => 'مصرف';

  @override
  String get obsUsageTotalTokens => 'کل توکن‌ها';

  @override
  String get obsUsagePeakTokens => 'اوج توکن';

  @override
  String get obsUsageLongestSession => 'طولانی‌ترین نشست';

  @override
  String get obsUsageCurrentStreak => 'رشتهٔ فعلی';

  @override
  String get obsUsageLongestStreak => 'بلندترین رشته';

  @override
  String obsUsageDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count روز',
      one: '1 روز',
      zero: '0 روز',
    );
    return '$_temp0';
  }

  @override
  String get obsUsageTokenActivity => 'فعالیت توکن';

  @override
  String get obsUsageActivityModeLabel => 'حالت فعالیت توکن';

  @override
  String get obsUsageModeDaily => 'روزانه';

  @override
  String get obsUsageModeWeekly => 'هفتگی';

  @override
  String get obsUsageModeCumulative => 'تجمعی';

  @override
  String get obsUsageTimeRange => 'بازهٔ زمانی';

  @override
  String get obsUsageTrendTitle => 'روند روزانهٔ توکن';

  @override
  String get obsUsageModelUsage => 'مصرف مدل';

  @override
  String get obsUsageTokensLabel => 'توکن';

  @override
  String get obsUsageNoActivity => 'هنوز مصرف توکنی ثبت نشده';

  @override
  String get obsUsageOtherModels => 'سایر';

  @override
  String obsUsageCellReadout(String date, String tokens) {
    return '$date · $tokens توکن';
  }

  @override
  String obsUsageActivitySummary(
    String start,
    String end,
    int activeDays,
    String peak,
  ) {
    return 'فعالیت توکن از $start تا $end. $activeDays روز فعال. شلوغ‌ترین روز $peak توکن.';
  }

  @override
  String get obsScreenSubtitle =>
      'کنترل زندهٔ عامل، انتساب هزینه، سهمیه و سیگنال کیفیت';

  @override
  String get obsRangeLast24h => '24 ساعت گذشته';

  @override
  String get obsRangeLast7d => '7 روز گذشته';

  @override
  String get obsRangeLast30d => '30 روز گذشته';

  @override
  String get obsRangeAll => 'همهٔ زمان';

  @override
  String get obsAddFilter => 'افزودن فیلتر';

  @override
  String get obsFilterAgent => 'عامل';

  @override
  String get obsFilterModel => 'مدل';

  @override
  String get obsFilterStatus => 'وضعیت';

  @override
  String get obsFilterRole => 'نقش';

  @override
  String get obsKpiTotalRuns => 'کل اجراها';

  @override
  String get obsKpiTotalCost => 'کل هزینه';

  @override
  String get obsKpiErrorRate => 'نرخ خطا';

  @override
  String get obsKpiCacheRate => 'نرخ کش';

  @override
  String get obsKpiTokensPerSec => 'توکن / ثانیه';

  @override
  String get obsKpiAvgLatency => 'میانگین تأخیر';

  @override
  String get obsKpiTtft => 'زمان تا اولین توکن';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '$delta نسبت به دورهٔ قبل';
  }

  @override
  String get obsChartActivity => 'فعالیت';

  @override
  String get obsChartCost => 'هزینه در زمان';

  @override
  String get obsLegendRuns => 'اجراها';

  @override
  String get obsLegendErrors => 'خطاها';

  @override
  String get obsAgentsTitle => 'عامل‌ها';

  @override
  String obsShowAllAgents(int count) {
    return 'نمایش همهٔ $count عامل';
  }

  @override
  String get obsShowFewerAgents => 'نمایش کمتر';

  @override
  String get obsRunsTitle => 'اجراها';

  @override
  String get obsNoRunsInRange => 'اجرایی در این بازه نیست';

  @override
  String get obsColTime => 'زمان';

  @override
  String get obsColAgent => 'عامل';

  @override
  String get obsColStatus => 'وضعیت';

  @override
  String get obsColModel => 'مدل';

  @override
  String get obsColDuration => 'مدت';

  @override
  String get obsColTokens => 'توکن';

  @override
  String get obsColCost => 'هزینه';

  @override
  String get obsColErrors => 'خطاها';

  @override
  String get obsColRuns => 'اجراها';

  @override
  String get obsColAvgLatency => 'میانگین تأخیر';

  @override
  String get obsColLastActive => 'آخرین فعالیت';

  @override
  String get obsStatusPending => 'در انتظار';

  @override
  String get obsStatusRunning => 'در حال اجرا';

  @override
  String get obsStatusCompleted => 'کامل‌شده';

  @override
  String get obsStatusError => 'خطا';

  @override
  String get obsRosterLoadError => 'بارگذاری فهرست عامل‌ها ممکن نشد.';

  @override
  String get obsRosterEmpty => 'هنوز عاملی نیست';

  @override
  String get obsRosterEmptyDescription =>
      'عاملی را دیسپچ کنید و اینجا زنده ظاهر می‌شود — وضعیت، ابزار فعلی، توکن، هزینه.';

  @override
  String get obsKillAgent => 'کشتن عامل';

  @override
  String get obsRosterTokensLabel => 'توکن';

  @override
  String get obsCostByRoleTitle => 'هزینه بر اساس نقش';

  @override
  String get obsCostByRoleSubtitle =>
      'این فضای کاری کجا خرج می‌کند، بر اساس نقش عامل';

  @override
  String get obsRoleMain => 'اصلی';

  @override
  String get obsRoleSubagents => 'زیرعامل‌ها';

  @override
  String get obsRoleAdvisor => 'مشاور';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return 'اصلی: $main · زیرعامل‌ها: $sub · مشاور: $advisor';
  }

  @override
  String get obsTotal => 'مجموع';

  @override
  String get obsTokenModelTitle => 'مدل توکن (5 محور)';

  @override
  String get obsTokenModelSubtitle =>
      'هر توکنی که این فضای کاری خرج کرده، بر اساس محور';

  @override
  String get obsAxisInput => 'ورودی';

  @override
  String get obsAxisOutput => 'خروجی';

  @override
  String get obsAxisReasoning => 'استدلال';

  @override
  String get obsAxisCacheRead => 'خواندن کش';

  @override
  String get obsAxisCacheWrite => 'نوشتن کش';

  @override
  String get obsTotalTokens => 'کل توکن‌ها';

  @override
  String get obsCacheDiscountNote =>
      'توکن‌های خواندن کش با تخفیف صورتحساب می‌شوند، پس خیلی کمتر از همان حجم ورودی تازه هزینه دارند.';

  @override
  String get obsByModelTitle => 'بر اساس مدل';

  @override
  String get obsByModelSubtitle => 'مصرف توکن و هزینه به ازای مدل';

  @override
  String get obsNoModelUsage => 'هنوز مصرف مدلی ثبت نشده.';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count اجرا',
      one: '1 اجرا',
    );
    return '$_temp0';
  }

  @override
  String get obsPerRunTitle => 'به ازای اجرا';

  @override
  String get obsPerRunSubtitle => 'هزینهٔ معمول توکن یک اجرا';

  @override
  String get obsMedianRunTokens => 'میانهٔ توکن اجرا';

  @override
  String get obsMedianRunTokensSub => 'نقطهٔ میانی همهٔ اجراها';

  @override
  String get obsRunsInWorkspace => 'در این فضای کاری';

  @override
  String get obsCostShare => 'سهم هزینه';

  @override
  String get obsQuotaConfiguredLimits => 'سقف‌های پیکربندی‌شده';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      'مصرف در برابر سقف‌هایی که گذاشته‌اید، بدترین وضعیت اول.';

  @override
  String get obsQuotaAddLimit => 'افزودن سقف';

  @override
  String get obsQuotaNoLimits =>
      'هنوز سقف سهمیه‌ای نیست — یکی اضافه کنید تا مصرف در برابر سقف ردیابی شود.';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return 'حذف سقف ⁨$title⁩';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return 'بازنشانی در $duration · ⁨$status⁩';
  }

  @override
  String get obsQuotaUsageWindows => 'پنجره‌های مصرف';

  @override
  String get obsQuotaUsageWindowsSubtitle =>
      'مصرف مشاهده‌شده در همهٔ ارائه‌دهندگان، بدون سقف.';

  @override
  String get obsQuotaNoUsage => 'هنوز مصرفی ثبت نشده.';

  @override
  String get obsQuotaTokensUsed => 'توکن مصرف‌شده';

  @override
  String get obsQuotaRequests => 'درخواست‌ها';

  @override
  String get obsQuotaUnitTokens => 'توکن';

  @override
  String get obsQuotaUnitRequests => 'درخواست';

  @override
  String get obsQuotaUnitCost => 'هزینه';

  @override
  String get obsQuotaAddLimitTitle => 'افزودن سقف سهمیه';

  @override
  String get obsQuotaProviderLabel => 'ارائه‌دهنده';

  @override
  String get obsQuotaWindowLabel => 'پنجره';

  @override
  String get obsQuotaUnitLabel => 'واحد';

  @override
  String obsQuotaLimitLabel(String unit) {
    return 'سقف ($unit)';
  }

  @override
  String get obsQuotaCentsHint => 'به سنت آمریکا (⁨500 = \$5.00⁩).';

  @override
  String get obsQuotaStatusOk => 'خوب';

  @override
  String get obsQuotaStatusWarning => 'هشدار';

  @override
  String get obsQuotaStatusExhausted => 'تمام‌شده';

  @override
  String get obsQuotaStatusUnknown => 'ناشناخته';

  @override
  String get obsGoalNoActiveTitle => 'هدف فعالی نیست';

  @override
  String get obsGoalNoActiveBody =>
      'هدف بگذارید تا عامل‌ها هدف و بودجهٔ توکن اختیاری داشته باشند. با اتمام اجراها بودجه پر می‌شود و نزدیک اتمام به جمع‌بندی سوق داده می‌شوند.';

  @override
  String get obsGoalSetGoal => 'تعیین هدف';

  @override
  String get obsGoalTokenBudget => 'بودجهٔ توکن';

  @override
  String obsGoalTokensLeft(String tokens) {
    return '$tokens باقی';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens (بودجه‌ای تعیین نشده)';
  }

  @override
  String get obsGoalTokensUsed => 'توکن مصرف‌شده';

  @override
  String get obsGoalElapsed => 'گذشته';

  @override
  String get obsGoalWrapUp => 'جمع‌بندی';

  @override
  String get obsGoalClear => 'پاک کردن هدف';

  @override
  String get obsGoalFallbackTitle => 'هدف';

  @override
  String get obsGoalSubtitle => 'بودجهٔ حالت هدف';

  @override
  String get obsGoalStatusActive => 'فعال';

  @override
  String get obsGoalStatusPaused => 'مکث';

  @override
  String get obsGoalStatusBudgetLimited => 'محدود به بودجه';

  @override
  String get obsGoalStatusComplete => 'کامل';

  @override
  String get obsGoalStatusDropped => 'رهاشده';

  @override
  String get obsGoalObjectiveLabel => 'هدف';

  @override
  String get obsGoalBudgetLabel => 'بودجهٔ توکن (اختیاری)';

  @override
  String get obsGoalSetAction => 'تعیین هدف';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => 'موفقیت ٪';

  @override
  String get obsBenchmarkPassed => 'موفق';

  @override
  String get obsBenchmarkFailed => 'ناموفق';

  @override
  String get obsBenchmarkErrors => 'خطاها';

  @override
  String get obsBenchmarkSpend => 'خرج';

  @override
  String get obsBenchmarkCostPerTask => 'هزینه / کار';

  @override
  String get obsBenchmarkTrials => 'آزمایش‌ها';

  @override
  String get obsBenchmarkNoTrials => 'هنوز اجرایی برای امتیازدهی نیست.';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'و $count مورد دیگر',
      one: 'و 1 مورد دیگر',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => 'قبول';

  @override
  String get obsBenchmarkTrialFail => 'رد';

  @override
  String get obsBenchmarkTrialError => 'خطا';

  @override
  String get obsBenchmarkTrialRunning => 'در حال اجرا';

  @override
  String get obsBenchmarkReward => 'پاداش';

  @override
  String get obsBenchmarkReport => 'گزارش';

  @override
  String get obsBenchmarkCopyMarkdown => 'کپی markdown';

  @override
  String get obsBenchmarkCopied => 'گزارش در کلیپ‌بورد کپی شد';

  @override
  String get obsBehaviorCaption =>
      'این‌ها سیگنال‌های ناامیدی از پیام‌های خود شماست — خوانشی از سلامت گفتگو، نه نمره برای عامل‌ها. محلی محاسبه می‌شود؛ چیزی از این دستگاه خارج نمی‌شود.';

  @override
  String get obsBehaviorMessagesAnalyzed => 'پیام‌های تحلیل‌شده';

  @override
  String get obsBehaviorTotalSignals => 'کل سیگنال‌ها';

  @override
  String get obsBehaviorYelling => 'فریاد';

  @override
  String get obsBehaviorProfanity => 'ناسزا';

  @override
  String get obsBehaviorAnguish => 'رنج';

  @override
  String get obsBehaviorNegation => 'نفی';

  @override
  String get obsBehaviorRepetition => 'تکرار';

  @override
  String get obsBehaviorBlame => 'سرزنش';

  @override
  String get obsBehaviorConversationsTitle => 'ناامیدکننده‌ترین گفتگوها';

  @override
  String get obsBehaviorConversationsSubtitle =>
      'رتبه‌بندی بر اساس چگالی سیگنال در پیام‌های شما.';

  @override
  String get obsBehaviorNoSignals => 'سیگنال ناامیدی نیست — آرام پیش می‌رود.';

  @override
  String obsBehaviorMessagesCount(String count) {
    return '$count پیام تحلیل شد';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '$count سیگنال';
  }

  @override
  String get obsAgentStatusIdle => 'بیکار';

  @override
  String get obsAgentStatusParked => 'پارک‌شده';

  @override
  String get obsAgentStatusAborted => 'سقط‌شده';

  @override
  String get obsAgentKindSub => 'زیر';

  @override
  String get noChecksOnCommit => 'هیچ بررسی‌ای روی این کامیت اجرا نشده.';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'در حال اجرا — $count کار',
      one: 'در حال اجرا — 1 کار',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'همهٔ بررسی‌ها موفق — $count کار',
      one: 'همهٔ بررسی‌ها موفق — 1 کار',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'کامل شد — $count کار',
      one: 'کامل شد — 1 کار',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total کار',
      one: '1 کار',
    );
    return '$failed از $_temp0 ناموفق';
  }

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کار',
      one: '1 کار',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return 'ماتریس: ⁨$jobId⁩';
  }

  @override
  String get jobLogsPending => 'وقتی کار تمام شود گزارش‌ها اینجا ظاهر می‌شوند.';

  @override
  String get jobLogsUnavailable => 'گزارش این کار در دسترس نیست.';

  @override
  String get noLogsForStep => 'گزارشی برای این گام ثبت نشده.';

  @override
  String get jobLogsTruncated =>
      'گزارش کوتاه شده — تازه‌ترین خروجی نمایش داده می‌شود.';

  @override
  String get fullLog => 'گزارش کامل';

  @override
  String get copyLogs => 'کپی گزارش‌ها';

  @override
  String get resizeGraph => 'برای تغییر اندازهٔ گراف بکشید';

  @override
  String workflowRunStartedAgo(String time) {
    return 'شروع $time';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return 'کامل شد $time';
  }

  @override
  String get chatBridgesTitle => 'پل‌های گفتگو';

  @override
  String chatProviderDescription(String provider, String command) {
    return 'ربات را در ⁨$provider⁩ منشن کنید تا عاملی را به کاری بگذارید، یا با ⁨$command⁩ تیکت ثبت کنید.';
  }

  @override
  String chatConnectProvider(String provider) {
    return 'اتصال ⁨$provider⁩';
  }

  @override
  String get chatDisconnectProvider => 'قطع اتصال';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '⁨$botName⁩ در ⁨$teamName⁩';
  }

  @override
  String get chatStateLive => 'زنده';

  @override
  String get chatStateConnecting => 'در حال اتصال…';

  @override
  String get chatStateError => 'خطای اتصال';

  @override
  String get chatNotConnected => 'متصل نیست';

  @override
  String chatStreamingUnavailable(String provider) {
    return 'استریم زنده برای این برنامهٔ ⁨$provider⁩ خاموش است — پاسخ‌ها به‌صورت یک پیام می‌آیند.';
  }

  @override
  String chatAdminOnly(String provider) {
    return 'فقط ادمین می‌تواند ⁨$provider⁩ را برای این فضای کاری وصل کند.';
  }

  @override
  String chatConnectHint(String provider) {
    return 'یک برنامهٔ ⁨$provider⁩ بسازید، سپس اعتبارنامه‌اش را اینجا جای‌گذاری کنید. Control Center به ⁨$provider⁩ وصل می‌شود، پس این سرور به نشانی عمومی نیاز ندارد.';
  }

  @override
  String chatOpenConsole(String provider) {
    return 'باز کردن کنسول ⁨$provider⁩';
  }

  @override
  String get chatOpenSetupGuide => 'راهنمای راه‌اندازی';

  @override
  String get chatFieldBotToken => 'توکن ربات';

  @override
  String get chatFieldAppToken => 'توکن سطح برنامه';

  @override
  String get chatFieldConfigRefreshToken => 'توکن پیکربندی برنامه';

  @override
  String chatFieldOptional(String label) {
    return '$label (اختیاری)';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return 'پیوند حساب ⁨$provider⁩ من';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return 'حساب ⁨$provider⁩ خود را پیوند دهید تا پیام‌هایی که آنجا می‌فرستید به شما نسبت داده شود.';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return 'پیوند به ⁨$externalUserId⁩';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return 'پیوند حساب ⁨$provider⁩ شما';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return 'این فرمان را به ربات در ⁨$provider⁩ بفرستید. یک‌بار کار می‌کند و در 15 دقیقه منقضی می‌شود.';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return 'حساب ⁨$provider⁩ شما اکنون پیوند شده — پیام‌هایی که آنجا می‌فرستید به شما نسبت داده می‌شود.';
  }

  @override
  String get chatLinkedAccounts => 'حساب‌های پیوندشده';

  @override
  String chatNoLinkedAccounts(String provider) {
    return 'هنوز کسی حساب ⁨$provider⁩ خود را پیوند نداده.';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حساب پیوندشده',
      one: '1 حساب پیوندشده',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '⁨$externalUserId⁩ · تطبیق با ایمیل';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '⁨$externalUserId⁩ · پیوند با کد';
  }

  @override
  String get chatUnlink => 'قطع پیوند';

  @override
  String get chatCustomizeBot => 'سفارشی‌سازی ربات';

  @override
  String get chatCustomizeBotDescription =>
      'ربات را تغییر نام دهید، حرفش دربارهٔ خودش را عوض کنید، یا فرمان اسلش را تغییر نام دهید.';

  @override
  String get chatCustomizeBotUnavailable =>
      'Control Center برای ویرایش ربات به توکن پیکربندی برنامه نیاز دارد. دوباره وصل شوید و یکی را شامل کنید.';

  @override
  String chatCreateAppTitle(String provider) {
    return 'ایجاد برنامهٔ ⁨$provider⁩';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'Control Center می‌تواند برنامهٔ ⁨$provider⁩ را با مجوزها و رویدادهای درست برایتان بسازد. کار را در ⁨$provider⁩ تمام می‌کنید، سپس اعتبارنامه‌ها را اینجا جای‌گذاری می‌کنید.';
  }

  @override
  String get chatCreateApp => 'ایجاد برنامه';

  @override
  String get chatCreateAppCta => 'برنامه را برایم بساز';

  @override
  String get chatAppNameLabel => 'نام برنامه';

  @override
  String get chatBotDisplayNameLabel =>
      'نام ربات (آنچه اعضا بعد از @ تایپ می‌کنند)';

  @override
  String get chatDescriptionLabel => 'شرح کوتاه';

  @override
  String get chatAgentDescriptionLabel =>
      'آنچه ربات می‌گوید می‌تواند انجام دهد';

  @override
  String get chatCommandLabel => 'فرمان اسلش';

  @override
  String get chatDirectMessages => 'پیام‌های مستقیم';

  @override
  String chatDirectMessagesHint(String provider) {
    return 'به اعضا اجازه می‌دهد در DM با ربات گفتگو کنند. ممکن است به طرح پولی ⁨$provider⁩ نیاز باشد.';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return '⁨$provider⁩ برنامهٔ ⁨$appId⁩ را ساخت.';
  }

  @override
  String chatRemainingSteps(String provider) {
    return 'چند گام مانده که فقط ⁨$provider⁩ می‌تواند انجام دهد:';
  }

  @override
  String get chatStepAppToken => 'تولید توکن سطح برنامه';

  @override
  String get chatStepInstall => 'نصب برنامه';

  @override
  String get chatOpenAppSettings => 'باز کردن تنظیمات برنامه';

  @override
  String get chatContinueToCredentials => 'جای‌گذاری اعتبارنامه‌ها';

  @override
  String chatBotUpdated(String provider) {
    return 'ربات در ⁨$provider⁩ به‌روز شد.';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return '⁨$provider⁩ مجوزهای برنامه را عوض کرد. برای اعمال، برنامه را دوباره نصب کنید.';
  }

  @override
  String get chatReinstallApp => 'نصب مجدد برنامه';

  @override
  String chatIconNotEditable(String provider) {
    return 'آیکون ربات فقط در تنظیمات خود برنامهٔ ⁨$provider⁩ عوض می‌شود.';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return 'می‌توانید خودتان هم در ⁨$provider⁩ بسازید — توکن لازم نیست. تنظیمات بالا با پیوند می‌روند.';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return 'ایجاد در ⁨$provider⁩';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return '⁨$provider⁩ در مرورگر با این پیکربندی ازپیش‌پر باز شد. برنامه را آنجا بسازید، سپس این گام‌ها را تمام کنید و با توکن‌ها برگردید.';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return '⁨$provider⁩ گزارش نمی‌کند کدام برنامه را ساخته، پس سفارشی‌سازی ربات از اینجا بعداً به توکن پیکربندی برنامه نیاز دارد.';
  }

  @override
  String get chatStepCreateApp => 'ایجاد برنامه از پیکربندی ازپیش‌پر';

  @override
  String chatStepCreateAppHint(String provider) {
    return 'یک فضای کاری در ⁨$provider⁩ انتخاب کنید و تأیید کنید.';
  }

  @override
  String get chatStepAppTokenHint =>
      '⁨Basic information⁩ ← توکن‌های سطح برنامه، با محدودهٔ ⁨connections:write⁩.';

  @override
  String get chatStepInstallHint =>
      '⁨Install app⁩ ← توکن OAuth کاربر ربات را کپی کنید.';

  @override
  String get calendarUseBuiltinApp =>
      'استفاده از برنامهٔ Google متعلق به Control Center';

  @override
  String get calendarUseBuiltinAppHint =>
      'با حساب Google تأیید کنید. چیزی در Google Cloud لازم نیست.';

  @override
  String get calendarUseOwnClient => 'استفاده از کلاینت Google Cloud خودم';

  @override
  String get calendarUseOwnClientHint =>
      'یک کلاینت OAuth از پروژهٔ Google Cloud خود وارد کنید.';

  @override
  String get aboutTitle => 'درباره';

  @override
  String get aboutAppVersion => 'نسخهٔ برنامه';

  @override
  String get aboutServerVersion => 'سرور متصل';

  @override
  String get aboutRpcCatalog => 'کاتالوگ RPC';

  @override
  String get aboutServerUnknown => 'گزارش نشده';

  @override
  String get serverStaleTitle => 'سرور همراه قدیمی‌تر از این برنامه است';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return '⁨cc_server⁩ در حال اجرا ⁨$serverVersion⁩ است در حالی که این برنامه ⁨$appVersion⁩ است. برنامه را دوباره راه‌اندازی کنید تا آخرین بیلد همراه را بردارد؛ در توسعه، با ⁨dart build cli⁩ در ⁨apps/cc_server⁩ دوباره بسازید.';
  }

  @override
  String get updateCheckButton => 'بررسی به‌روزرسانی';

  @override
  String get updateChecking => 'در حال بررسی به‌روزرسانی…';

  @override
  String get updateUpToDate => 'به‌روز هستید';

  @override
  String get updateDeferredBusy =>
      'به‌روزرسانی آماده است اما جلسه‌ای در حال ضبط است — پس از پایان پرسیده می‌شود.';

  @override
  String get updateOpenedReleasesPage => 'صفحهٔ انتشار در مرورگر باز شد.';

  @override
  String get updateCheckFailed => 'بررسی به‌روزرسانی ناموفق';

  @override
  String updateAvailableVersion(String version) {
    return 'نسخهٔ $version در دسترس است.';
  }

  @override
  String get updateBannerTitle => 'Control Center جدید در دسترس است';

  @override
  String get updateBannerRefresh => 'تازه‌سازی';

  @override
  String get updateBlockedRecording =>
      'تازه‌سازی هنگام ضبط جلسه متوقف است — پس از پایان بارگذاری مجدد می‌شود.';

  @override
  String get settingsScopeYou => 'شما';

  @override
  String get settingsScopeWorkspace => 'فضای کاری';

  @override
  String get settingsScopeServer => 'سرور';

  @override
  String get settingsProfile => 'نمایه و هویت';

  @override
  String get settingsYourDevices => 'دستگاه‌های شما';

  @override
  String get settingsWorkspaceGeneral => 'عمومی';

  @override
  String get settingsServerConnection => 'اتصال و وضعیت';

  @override
  String get settingsModelProviders => 'ارائه‌دهندگان مدل';

  @override
  String get settingsVoiceModels => 'مدل‌های صدا و جلسه';

  @override
  String get settingsDiagnostics => 'تشخیص و حریم خصوصی';

  @override
  String get settingsAbout => 'درباره';

  @override
  String get settingsScopeBadgeYou => 'شما';

  @override
  String get settingsScopeBadgeDevice => 'این دستگاه';

  @override
  String get settingsScopeBadgeWorkspace => 'فضای کاری';

  @override
  String get settingsScopeBadgeServer => 'سرور';

  @override
  String get settingsProfileDescription =>
      'نام، ایمیل و هویت git شما در این فضا. تعویض فضا این لایه را عوض می‌کند؛ شناسه، ورود و دستگاه‌ها روی حساب می‌مانند.';

  @override
  String get settingsServerConnectionDescription =>
      'این کلاینت با کدام سرور حرف می‌زند، و این سرور چطور به اشتراک گذاشته می‌شود (mDNS، تونل، رله).';

  @override
  String get settingsAboutDescription => 'هویت بیلد و به‌روزرسانی‌ها.';

  @override
  String get settingsDiagnosticsDescription =>
      'ایزوله‌سازی، ایندکس، همگام‌سازی، ثبت و گزارش کرش این نصب.';

  @override
  String get settingsWorkspaceGeneralDescription =>
      'هویت، سیاست و قراردادهای مشترک همه در این فضای کاری.';

  @override
  String get settingsWorkspaceMeetingsDescription =>
      'الگوهای یادداشت و صداهای ذخیره‌شده برای جلسات این فضای کاری.';

  @override
  String get settingsWorkspacePolicyLabel => 'سیاست فضای کاری';

  @override
  String get settingsWorkspacePolicyDescription =>
      'برای هر عضو و هر عامل این فضای کاری اعمال می‌شود.';

  @override
  String get settingsSecretGlobsLabel => 'استثناهای مسیر محرمانه';

  @override
  String get settingsSecretGlobsHelp =>
      'یک glob در هر خط. این مسیرها روی سطوح حاوی کد از بینندگان و مهمان‌ها پنهان می‌شوند، علاوه بر پیش‌فرض‌های داخلی.';

  @override
  String get settingsReviewConcurrencyLabel => 'گسترش بازبینی';

  @override
  String get settingsReviewConcurrencyHelp =>
      'وقتی تعداد صریحی داده نشده چند بازبین به‌موازات دیسپچ می‌شوند.';

  @override
  String get settingsReviewLevelLabel => 'سطح بازبینی';

  @override
  String get settingsReviewLevelHelp =>
      'بازبینی هوش مصنوعی چقدر عمیق می‌رود، و چقدر از یافته‌ها همان ابتدا گزارش می‌شود. چیزی دور ریخته نمی‌شود — سطح سبک‌تر یافته‌های جزئی را گروه‌بندی می‌کند نه حذف.';

  @override
  String get reviewLevelLight => 'سبک';

  @override
  String get reviewLevelBalanced => 'متعادل';

  @override
  String get reviewLevelThorough => 'جامع';

  @override
  String get reviewLevelLightHint =>
      'یک بازبین. فقط آنچه واقعاً مهم است همان ابتدا گزارش می‌شود.';

  @override
  String get reviewLevelBalancedHint =>
      'سه بازبین برای تضمین کیفیت، معماری و پیاده‌سازی.';

  @override
  String get reviewLevelThoroughHint =>
      'متخصصان امنیت و عملکرد را اضافه می‌کند و همهٔ یافته‌ها را گزارش می‌دهد.';

  @override
  String get askAiReviewAtLevel => 'بازبینی در سطح دیگر';

  @override
  String reviewNitpicksGroup(int count) {
    return 'خرده‌گیری‌ها ($count)';
  }

  @override
  String get reviewFindingResolve => 'رفع شد';

  @override
  String get reviewFindingResolveHint =>
      'این یافته را رفع‌شده علامت بزنید. دیگر در بازبینی شمرده نمی‌شود.';

  @override
  String get reviewFindingDismiss => 'رد کردن';

  @override
  String get reviewFindingDismissHint =>
      'مشکل واقعی نیست. بازبین‌ها این الگو را در PRهای بعدی علامت نمی‌زنند.';

  @override
  String get reviewFindingReopen => 'بازگشایی';

  @override
  String get reviewFindingStatusUndoLabel => 'وضعیت یافته';

  @override
  String get reviewFindingDismissTitle => 'رد این یافته';

  @override
  String get reviewFindingDismissReasonHint =>
      'چرا صدق نمی‌کند؟ بازبین‌ها می‌خوانندش.';

  @override
  String reviewFindingStatusFailed(String error) {
    return 'به‌روزرسانی یافته ممکن نشد: ⁨$error⁩';
  }

  @override
  String get reviewStaleTitle => 'این بازبینی قدیمی است';

  @override
  String get reviewStaleBody =>
      'pull request از زمان این بازبینی جلو رفته. یافته‌ها ممکن است به کدی اشاره کنند که دیگر نیست.';

  @override
  String reviewStaleReviewedAt(String sha) {
    return 'بازبینی در ⁨$sha⁩';
  }

  @override
  String get reviewStaleRerun => 'بازبینی دوباره';

  @override
  String reviewStaleNotificationTitle(int prNumber) {
    return 'بازبینی قدیمی روی ⁨#$prNumber⁩';
  }

  @override
  String reviewStaleNotificationBody(String title) {
    return '⁨$title⁩ از آخرین بازبینی کامیت جدید دارد.';
  }

  @override
  String get reviewCategorySecurity => 'امنیت';

  @override
  String get reviewCategoryStability => 'پایداری';

  @override
  String get reviewCategoryDataIntegrity => 'یکپارچگی داده';

  @override
  String get reviewCategoryCorrectness => 'درستی';

  @override
  String get reviewCategoryPerformance => 'عملکرد';

  @override
  String get reviewCategoryMaintainability => 'نگهداری‌پذیری';

  @override
  String get reviewEffortQuickWin => 'برد سریع';

  @override
  String get reviewEffortModerate => 'متوسط';

  @override
  String get reviewEffortHeavyLift => 'کار سنگین';

  @override
  String get reviewProposedFix => 'رفع پیشنهادی';

  @override
  String get reviewAiAgentPrompt => 'پرامپت برای عامل‌های هوش مصنوعی';

  @override
  String get reviewCopyAiPrompt => 'کپی پرامپت';

  @override
  String get settingsWorkspaceAdminOnly =>
      'فقط ادمین‌های فضای کاری می‌توانند این‌ها را عوض کنند.';

  @override
  String get chatMyAccountsTitle => 'حساب‌های گفتگوی پیوندشده';

  @override
  String get settingsServerSso => 'ورود یکپارچه';

  @override
  String get settingsServerSsoDescription =>
      'ورود SAML و OpenID Connect با تأمین کاربر';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabledDescription =>
      'کاربران می‌توانند با این ارائه‌دهنده وارد شوند';

  @override
  String get ssoEnabledDescriptionOn => 'ورود برای این ارائه‌دهنده زنده است';

  @override
  String get ssoIdpMetadataLabel => 'XML فرادادهٔ IdP';

  @override
  String get ssoIdpMetadataHint =>
      'XML مربوط به EntityDescriptor متعلق به IdP را جای‌گذاری کنید';

  @override
  String get ssoEmailAttributeLabel => 'ویژگی ایمیل';

  @override
  String get ssoDisplayNameAttributeLabel => 'ویژگی نام نمایشی';

  @override
  String get ssoGroupsAttributeLabel => 'ویژگی گروه‌ها';

  @override
  String get ssoIssuerLabel => 'URL صادرکننده';

  @override
  String get ssoClientIdLabel => 'شناسهٔ کلاینت';

  @override
  String get ssoGroupsClaimLabel => 'ادعای گروه‌ها';

  @override
  String get ssoAutoMemberLabel =>
      'افزودن کاربران به همهٔ فضاهای کاری در اولین ورود';

  @override
  String get ssoAutoMemberDescription =>
      'خاموش کنید تا برای هر فضای کاری دعوت لازم باشد';

  @override
  String get ssoAllowJitLabel => 'تأمین کاربران ناشناخته در اولین ورود';

  @override
  String get ssoAllowJitDescription =>
      'خاموش کنید تا کاربران بدون حساب موجود رد شوند';

  @override
  String get ssoAllowIdpInitiatedLabel =>
      'پذیرش ورود ناخواسته (آغازشده از IdP)';

  @override
  String get ssoAllowIdpInitiatedDescription =>
      'فقط برای پورتال‌های IdP که برنامه‌ها را مستقیم راه‌اندازی می‌کنند';

  @override
  String get ssoWantResponseSignedLabel => 'الزام پاکت پاسخ امضاشده';

  @override
  String get ssoWantResponseSignedDescription =>
      'امضای assertion همیشه لازم است';

  @override
  String get ssoTestConnectionButton => 'آزمایش اتصال';

  @override
  String get ssoTestConnectionOk => 'اتصال کار می‌کند:';

  @override
  String get ssoCopySpMetadata => 'کپی فرادادهٔ SP';

  @override
  String get ssoCopySpMetadataDone => 'فرادادهٔ SP در کلیپ‌بورد کپی شد';

  @override
  String get ssoSavedToast => 'تنظیمات ورود یکپارچه ذخیره شد';

  @override
  String get ssoUnavailable =>
      'این سرور تنظیمات ورود یکپارچه را در معرض نمی‌گذارد. باینری سرور را به‌روز کنید و دوباره تلاش کنید.';

  @override
  String get ssoScimCardTitle => 'تأمین کاربر (SCIM)';

  @override
  String get ssoScimDescription =>
      'اتصال‌دهندهٔ SCIM ارائه‌دهندهٔ هویت را با توکن bearer به نقطهٔ پایانی زیر اشاره دهید. لغو تأمین نشست‌ها و دسترسی فضای کاری را ظرف ثانیه‌ها لغو می‌کند. سرور باید برای IdP قابل دسترس باشد (تونل یا URL عمومی).';

  @override
  String get ssoScimEndpoint => 'نقطهٔ پایانی SCIM';

  @override
  String get ssoScimEndpointUnknownOrigin =>
      'ابتدا URL عمومی سرور را بگذارید یا تونل را فعال کنید';

  @override
  String get ssoScimRegenerate => 'تولید مجدد توکن';

  @override
  String get ssoScimRegenerateConfirm =>
      'توکن bearer جدید SCIM ساخته شود؟ توکن قبلی فوراً از کار می‌افتد.';

  @override
  String get ssoScimTokenTitle => 'توکن Bearer';

  @override
  String get ssoScimTokenPresent => 'توکنی پیکربندی شده';

  @override
  String get ssoScimTokenAbsent =>
      'هنوز توکنی نیست — برای فعال‌سازی SCIM یکی بسازید';

  @override
  String get ssoScimTokenOnce => 'توکن SCIM (یک‌بار نمایش)';

  @override
  String ssoSignInWith(String provider) {
    return 'ورود با ⁨$provider⁩';
  }

  @override
  String get ssoProbeFailed => 'دسترسی به آن سرور برای ورود یکپارچه ممکن نشد';

  @override
  String get ssoOpensBrowser => 'مرورگر را برای اتمام ورود باز می‌کند';

  @override
  String get ssoWaitingForBrowser => 'منتظر اتمام ورود در مرورگر…';

  @override
  String get ssoBrowserOpenFailed =>
      'باز کردن مرورگر برای ورود یکپارچه ممکن نشد';

  @override
  String get ssoUseManualPairing =>
      'به‌جای آن با دعوت یا کلید جفت‌سازی وارد شوید';

  @override
  String get ssoHideManualPairing => 'پنهان کردن جفت‌سازی دستی';

  @override
  String get ssoClientIdHint => 'کلاینت عمومی (PKCE) — راز لازم نیست';

  @override
  String get ssoClientSecretLabel => 'راز کلاینت (اختیاری)';

  @override
  String get ssoClientSecretHintUnset =>
      'فقط برای کلاینت‌های محرمانهٔ IdP لازم است';

  @override
  String get ssoClientSecretHintSet =>
      'رازی ذخیره شده — برای نگه‌داشتن خالی بگذارید';

  @override
  String get ssoPairingToggle =>
      'اجازهٔ جفت‌سازی دستی (کد دعوت و کلید جفت‌سازی)';

  @override
  String get ssoPairingToggleDescription =>
      'خاموش کنید تا پیوستن فقط از ورود یکپارچه باشد — دستگاه‌های جدید از ورود SSO می‌آیند؛ دستگاه‌های موجود کار می‌کنند';

  @override
  String get ssoPairConfirmTitle => 'به سرور وصل شود؟';

  @override
  String ssoPairConfirmBody(String server) {
    return 'اعتبارنامهٔ ورود برای ⁨$server⁩ رسید، اما ورودی از این برنامه شروع نشده. به این سرور وصل شوید؟';
  }

  @override
  String get ssoPairConfirmConnect => 'اتصال';

  @override
  String get ssoPairConfirmCancel => 'نادیده گرفتن';

  @override
  String get forgeConnections => 'میزبانی کد';

  @override
  String get connect => 'اتصال';

  @override
  String get disconnect => 'قطع اتصال';

  @override
  String get notConnected => 'متصل نیست';

  @override
  String get checkingConnection => 'در حال بررسی اتصال…';

  @override
  String get fromEnvironment => 'از محیط';

  @override
  String forgeTokenTitle(String forge) {
    return 'توکن ⁨$forge⁩';
  }

  @override
  String get settingsAudio => 'صدا';

  @override
  String get settingsAudioDescription =>
      'میکروفون، دیکته، تشخیص جلسه و خروجی منظر صوتی.';

  @override
  String get audioDevicesSection => 'دستگاه‌های صوتی';

  @override
  String get voiceInputBehaviorSection => 'دیکته و جلسات';

  @override
  String get audioOutputDeviceTitle => 'دستگاه خروجی';

  @override
  String get audioOutputDefaultHint =>
      'همهٔ صدای برنامه از خروجی پیش‌فرض سیستم پخش می‌شود.';

  @override
  String get audioOutputGone =>
      'دستگاه خروجی انتخاب‌شده دیگر وصل نیست — تا انتخاب دیگری پیش‌فرض سیستم استفاده می‌شود.';

  @override
  String get reviewHubIntroBody =>
      'عامل‌ها دیف را تحلیل می‌کنند، نواحی تغییر را نقشه می‌کنند و به حکم اجماع می‌رسند.';

  @override
  String get reviewHubAlreadyRunning =>
      'بازبینی برای این pull request از قبل در حال اجراست';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return 'از آخرین بازبینی: $resolved رفع‌شده · $added جدید · $open هنوز باز';
  }

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return 'قبلاً در ⁨$sha⁩ بازبینی شد';
  }

  @override
  String reviewArtifactFixAll(int count) {
    return 'رفع $count یافته';
  }

  @override
  String reviewArtifactFixSelected(int count) {
    return 'رفع $count انتخاب‌شده';
  }

  @override
  String reviewArtifactCommentSelected(int count) {
    return 'نظر روی $count انتخاب‌شده';
  }

  @override
  String get webConnectTitle => 'اتصال به Control Center';

  @override
  String get webConnectSubtitle =>
      'به ⁨cc-server⁩ در حال اجرا از طریق WebSocket وصل شوید. کلیدتان روی این دستگاه می‌ماند.';

  @override
  String get webConnectServerLabel => 'سرور';

  @override
  String get webConnectDeviceIdLabel => 'شناسهٔ دستگاه';

  @override
  String get webConnectPairingKeyLabel => 'کلید جفت‌سازی';

  @override
  String get webConnectPairingKeyHint => 'PSK را جای‌گذاری کنید';

  @override
  String get webConnectStayConnected => 'روی این دستگاه متصل بمانید';

  @override
  String get webConnectStayConnectedDetail =>
      'روی این دستگاه متصل بمانید (کلیدتان در این مرورگر ذخیره می‌شود)';

  @override
  String failedToCreateWorkspace(String error) {
    return 'ایجاد فضای کاری ناموفق: ⁨$error⁩';
  }

  @override
  String committedRelative(String relative) {
    return 'کامیت شده $relative';
  }

  @override
  String get selectAgents => 'انتخاب عامل‌ها';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عامل',
      one: '1 عامل',
    );
    return '$_temp0';
  }

  @override
  String get newConversation => 'گفتگوی جدید';

  @override
  String get untitledConversation => 'گفتگوی بدون عنوان';

  @override
  String get conversationTitleOptionalHint =>
      'اختیاری — خالی بگذارید تا مدل عنوان خودش نام‌گذاری کند';

  @override
  String get conversationTitlesSectionTitle => 'عناوین گفتگو';

  @override
  String get conversationTitlesSectionCaption =>
      'اجراکننده‌ای را انتخاب کنید که گفتگوهای جدید این فضای کاری را خودکار نام‌گذاری کند. تا انتخاب آداپتر عناوین خاموش می‌مانند و برای همهٔ اعضا اعمال می‌شود.';

  @override
  String get conversationTitlesModelLabel => 'مدل عنوان';

  @override
  String get conversationTitlesAdapterLabel => 'آداپتر';

  @override
  String get conversationTitlesAdapterHint => 'خاموش';

  @override
  String get conversationTitlesAdapterOff => 'خاموش';

  @override
  String get startThread => 'شروع رشته';

  @override
  String get deleteSpaceConfirm =>
      'این فضا حذف شود؟ همهٔ پیام‌ها از دست می‌روند.';

  @override
  String threadTabTitle(String title) {
    return 'رشته: ⁨$title⁩';
  }

  @override
  String threadReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count پاسخ',
      one: '1 پاسخ',
    );
    return '$_temp0';
  }

  @override
  String threadLastReply(String time) {
    return 'آخرین پاسخ $time';
  }

  @override
  String signInWithProvider(String provider) {
    return 'ورود با ⁨$provider⁩';
  }

  @override
  String get signInAgain => 'ورود دوباره';

  @override
  String get signInNotFinished =>
      'ورود هنوز برنگشته. در مرورگر تمامش کنید، سپس دوباره بررسی کنید.';

  @override
  String get signedOutTitle => 'خارج شده‌اید';

  @override
  String get signedOutSubtitle =>
      'اتصال میزبانی کد دیگر معتبر نیست — توکن منقضی شده یا دسترسی‌اش لغو شده. چیز دیگری عوض نشده: دوباره وارد شوید و همه همان‌جا می‌ماند.';

  @override
  String get viaServerApp => 'از طریق برنامهٔ این سرور';

  @override
  String get ticketing => 'تیکتینگ';

  @override
  String get ticketingProviderHelp =>
      'تیکت‌هایتان کجا زندگی می‌کنند. محلی آن‌ها را در Control Center نگه می‌دارد.';

  @override
  String providerComingSoon(String provider) {
    return '⁨$provider⁩ (به‌زودی)';
  }

  @override
  String get ticketProviderLocal => 'محلی';

  @override
  String get addKey => 'افزودن کلید';

  @override
  String get providerApps => 'برنامه‌های ارائه‌دهنده';

  @override
  String get providerAppsDescription =>
      'فضاهای کاری این GitHub App را به ارث می‌برند مگر App دیگر یا رمز دسترسی شخصی انتخاب کنند. کار پس‌زمینه — وب‌هوک، نظرسنجی، همگام‌سازی — روی برنامه اجرا می‌شود، نه روی رمز فرد.';

  @override
  String get providerAppId => 'شناسهٔ برنامه';

  @override
  String get providerPrivateKey => 'کلید خصوصی';

  @override
  String get providerClientId => 'شناسهٔ کلاینت';

  @override
  String get providerClientSecret => 'راز کلاینت';

  @override
  String get providerApiKey => 'کلید API';

  @override
  String get providerCallbackUrl => 'URL بازگشت';

  @override
  String get providerAppFullyConfigured =>
      'سرور می‌تواند به‌عنوان خودش عمل کند، و افراد می‌توانند وارد شوند.';

  @override
  String get providerAppServerOnly =>
      'سرور می‌تواند به‌عنوان خودش عمل کند. برای ورود افراد شناسه و راز کلاینت اضافه کنید.';

  @override
  String get providerAppSignInOnly =>
      'افراد می‌توانند وارد شوند. کار پس‌زمینه به اعتبارنامه‌هایشان برمی‌گردد.';

  @override
  String providerAppInstalledOn(String accounts) {
    return 'اعتبارنامه‌ها کار می‌کنند. نصب‌شده روی: ⁨$accounts⁩';
  }

  @override
  String deviceCodeInstructions(String provider) {
    return 'این کد را در صفحهٔ ⁨$provider⁩ که همین حالا باز شد وارد کنید. در کلیپ‌بورد کپی شده.';
  }

  @override
  String get deviceCodeWaiting => 'منتظر اتمام کار در مرورگر…';

  @override
  String get copyCodeAndOpen => 'کپی کد و باز کردن';

  @override
  String get couldNotOpenBrowser =>
      'مرورگری باز نشد. پیوند را کپی کنید و ورود را خودتان تمام کنید.';

  @override
  String get contextUsage => 'مصرف زمینه';

  @override
  String get contextUsageFull => 'پر';

  @override
  String get contextUsageTokens => 'توکن';

  @override
  String get contextSeeMore => 'مشاهدهٔ بیشتر';

  @override
  String get contextSegmentSystemPrompt => 'پرامپت سیستم';

  @override
  String get contextSegmentRules => 'قواعد';

  @override
  String get contextSegmentSkills => 'مهارت‌ها';

  @override
  String get contextSegmentToolDefinitions => 'تعریف ابزارها';

  @override
  String get contextSegmentMcpTools => 'ابزارهای MCP و پویا';

  @override
  String get contextSegmentDeferredTools => 'ابزارهای بارگذاری‌شده به‌درخواست';

  @override
  String get contextSegmentSubagents => 'تعریف زیرعامل‌ها';

  @override
  String get contextSegmentMemory => 'حافظه';

  @override
  String get contextSegmentConversation => 'گفتگو';

  @override
  String get contextExplorerTitle => 'زمینه';

  @override
  String get contextExplorerEverything => 'همه چیز';

  @override
  String get contextExplorerSelectPart =>
      'بخشی را برای بازرسی محتوایش انتخاب کنید';

  @override
  String get contextExplorerUnavailable => 'تفکیک زمینه در دسترس نیست';

  @override
  String get contextRetry => 'تلاش مجدد';

  @override
  String get settingsFieldOptional => 'اختیاری';

  @override
  String get settingsFilterHint => 'فیلتر این فهرست';

  @override
  String get settingsValueNotAvailable => 'هنوز در دسترس نیست';

  @override
  String get settingsNoEntriesYet => 'هنوز چیزی اینجا نیست';

  @override
  String get settingsChangedBadge => 'تغییرکرده';

  @override
  String get ssoConnectionCardDescription =>
      'چگونگی ورود افراد به این سرور را انتخاب کنید، سپس آن اتصال را روشن کنید.';

  @override
  String get ssoUseSamlForSignIn => 'استفاده از SAML برای ورود';

  @override
  String get ssoUseOidcForSignIn => 'استفاده از OpenID Connect برای ورود';

  @override
  String get ssoSaveConnection => 'ذخیرهٔ اتصال';

  @override
  String get ssoStateLive => 'زنده';

  @override
  String get ssoStateConfiguredOff => 'پیکربندی‌شده، خاموش';

  @override
  String get ssoStateOnIncomplete => 'روشن، ناقص';

  @override
  String get ssoStateActive => 'فعال';

  @override
  String get ssoStateAllowed => 'مجاز';

  @override
  String get ssoStateNoToken => 'بدون توکن';

  @override
  String get ssoSummaryDirectorySync => 'همگام‌سازی دایرکتوری';

  @override
  String get ssoSummaryManualPairing => 'جفت‌سازی دستی';

  @override
  String get ssoNoMethodLiveNote =>
      'هیچ روش ورودی زنده نیست. دستگاه‌های جدید با دعوت یا کلید جفت‌سازی می‌پیوندند تا اتصال را پیکربندی و روشن کنید.';

  @override
  String get ssoMethodSamlBlurb =>
      'برای ارائه‌دهندگان هویتی که SAML 2.0 صحبت می‌کنند، مثل Okta، Entra ID یا Google Workspace.';

  @override
  String get ssoMethodOidcBlurb =>
      'برای ارائه‌دهندگان هویتی که OpenID Connect صحبت می‌کنند. معمولاً ساده‌تر از آن دو برای راه‌اندازی است.';

  @override
  String get ssoGroupIdentityProvider => 'ارائه‌دهندهٔ هویت';

  @override
  String get ssoGroupIdentityProviderSamlDescription =>
      'assertionها از کجا می‌آیند، و این سرور چطور آن‌ها را تأیید می‌کند.';

  @override
  String get ssoGroupIdentityProviderOidcDescription =>
      'کدام صادرکننده مورد اعتماد این سرور است، و کلاینتی که به‌عنوان آن احراز هویت می‌کند.';

  @override
  String get ssoSpEntityIdShortLabel => 'شناسهٔ موجودیت SP';

  @override
  String get ssoSpEntityIdDescription =>
      'خالی بگذارید تا از URL سرور مشتق شود.';

  @override
  String get ssoIssuerDescription =>
      'URL پایه‌ای که سند کشف ارائه‌دهنده را سرو می‌کند.';

  @override
  String get ssoSecretStored => 'ذخیره‌شده';

  @override
  String get ssoGroupHandoff => 'آنچه ارائه‌دهندهٔ هویتتان نیاز دارد';

  @override
  String get ssoGroupHandoffDescription =>
      'این‌ها را در برنامه‌ای که نزد ارائه‌دهنده ساختید جای‌گذاری کنید.';

  @override
  String get ssoOriginUnknownTitle => 'این سرور URL عمومی‌اش را نمی‌داند';

  @override
  String get ssoOriginUnknownBody =>
      'URLهای ورود و بازگشت از آن ساخته می‌شوند، پس ارائه‌دهنده تا تعیین یکی به این سرور نمی‌رسد. URL عمومی اضافه کنید یا تونل را در سرور ← اتصال فعال کنید.';

  @override
  String get ssoAcsUrlLabel => 'URL سرویس مصرف assertion (ACS)';

  @override
  String get ssoAcsUrlDescription =>
      'جایی که ارائه‌دهنده assertion امضاشده را پست می‌کند.';

  @override
  String get ssoSpEntityIdResolvedLabel => 'شناسهٔ موجودیت ارائه‌دهندهٔ خدمت';

  @override
  String get ssoMetadataUrlLabel => 'URL فرادادهٔ SP';

  @override
  String get ssoMetadataUrlDescription =>
      'ارائه‌دهندگانی که فراداده وارد می‌کنند می‌توانند از اینجا واکشی کنند.';

  @override
  String get ssoRedirectUriLabel => 'URI تغییر مسیر';

  @override
  String get ssoRedirectUriDescription =>
      'این را به URIهای تغییر مسیر مجاز برنامهٔ ارائه‌دهنده اضافه کنید.';

  @override
  String get ssoSignInUrlLabel => 'URL ورود';

  @override
  String get ssoSignInUrlDescription =>
      'افراد را برای شروع ورود یکپارچه اینجا بفرستید.';

  @override
  String get ssoGroupAttributeMapping => 'نگاشت ویژگی';

  @override
  String get ssoGroupAttributeMappingDescription =>
      'کدام ادعا هر فیلد را حمل می‌کند. پیش‌فرض‌ها را نگه دارید مگر ارائه‌دهنده نام‌شان را عوض کند.';

  @override
  String get ssoGroupAccess => 'دسترسی و نقش‌ها';

  @override
  String get ssoGroupAccessDescription =>
      'کسی که با موفقیت وارد شود چه کارهایی مجاز است.';

  @override
  String get ssoDefaultRoleShortLabel => 'نقش پیش‌فرض';

  @override
  String get ssoDefaultRoleDescription =>
      'به هر کسی که گروه‌هایش با هیچ نگاشت زیر جور نباشد داده می‌شود.';

  @override
  String get ssoRoleMapShortLabel => 'نگاشت گروه به نقش';

  @override
  String get ssoRoleMapDescription =>
      'اولین گروه منطبق برنده است. مالک از این راه اعطا نمی‌شود.';

  @override
  String get ssoRoleMapGroupHint => 'نام گروه از ارائه‌دهندهٔ شما';

  @override
  String get ssoRoleMapAdd => 'افزودن نگاشت';

  @override
  String get ssoRoleMapEmpty => 'بدون نگاشت — همه نقش پیش‌فرض می‌گیرند.';

  @override
  String get ssoAdvancedSummary =>
      'انحراف ساعت، ورود آغازشده از IdP، سیاست امضا';

  @override
  String get ssoClockSkewShortLabel => 'انحراف ساعت';

  @override
  String get ssoClockSkewDescription =>
      'ثانیهٔ تحمل روی برچسب زمانی assertion. 90 برای بیشتر ارائه‌دهندگان مناسب است.';

  @override
  String get ssoScimGenerate => 'تولید توکن';

  @override
  String get ssoScimTokenOnceBody =>
      'در کلیپ‌بورد کپی شد. یک‌بار نشان داده می‌شود و بازیابی نمی‌شود، پس همین حالا در ارائه‌دهنده جای‌گذاری کنید.';

  @override
  String get ssoPairingCardTitle => 'جفت‌سازی دستی';

  @override
  String get ssoPairingCardDescription =>
      'راه دیگر به این سرور: کد دعوت و کلید جفت‌سازی، برای دستگاه‌هایی که از ورود یکپارچه نمی‌گذرند.';

  @override
  String settingsCountOfTotal(int count, int total) {
    return '$count از $total';
  }

  @override
  String get providersNoneConnectedNote =>
      'هیچ ارائه‌دهنده‌ای وصل نیست، پس زمان اجرای عامل داخلی چیزی برای اجرا ندارد. کلید API اضافه کنید یا به یکی زیر وارد شوید.';

  @override
  String get providersFilterHint => 'فیلتر ارائه‌دهندگان';

  @override
  String get providersNoneMatch => 'چیزی با این فیلتر جور نیست';

  @override
  String get providerDeniedHereTitle => 'در این فضای کاری رد شده';

  @override
  String get providerDeniedHereBody =>
      'عامل‌ها اینجا نمی‌توانند از این ارائه‌دهنده استفاده کنند، حتی اگر وصل باشد. فضاهای کاری دیگر بی‌تأثیرند.';

  @override
  String get providerNeedsSignIn => 'برای استفاده از این ارائه‌دهنده وارد شوید';

  @override
  String get providerNeedsApiKey =>
      'برای استفاده از این ارائه‌دهنده کلید API اضافه کنید';

  @override
  String get providerApiKeyLabel => 'کلید API';

  @override
  String get providerGenerationDefaults => 'پیش‌فرض‌های ارائه‌دهنده';

  @override
  String get providerNoModelsYet =>
      'هنوز مدلی گزارش نشده. ارائه‌دهنده را وصل کنید، سپس همگام کنید.';

  @override
  String get providerModelsFilterHint => 'فیلتر مدل‌ها';

  @override
  String get adaptersNoneReadyNote =>
      'هیچ‌کدام از CLIهای کاتالوگ اجراکننده روی این ماشین یافت نشد. یکی نصب کنید، سپس تازه‌سازی کنید.';

  @override
  String get adaptersFilterHint => 'فیلتر اجراکننده‌ها';

  @override
  String get adaptersLaunchGroup => 'راه‌اندازی';

  @override
  String get adaptersLaunchGroupDescription =>
      'وقتی عاملی این اجراکننده را شروع می‌کند چه چیزی به آن داده می‌شود. اگر بخواهید پیش از نصب CLI تنظیم کنید.';

  @override
  String get adaptersEnvNone => 'هیچ‌کدام تنظیم نشده';

  @override
  String adaptersEnvCount(int count) {
    return '$count تنظیم‌شده';
  }

  @override
  String get adapterArgumentsDescription =>
      'در هر راه‌اندازی به خط فرمان اجراکننده افزوده می‌شود.';

  @override
  String get defaultChatDescription =>
      'گفتگوهای جدید و هر عاملی بدون اجراکنندهٔ خودش را اجرا می‌کند.';

  @override
  String get shortTaskDescription =>
      'کار پس‌زمینهٔ سریع مثل عناوین و خلاصه‌ها را اجرا می‌کند. مدل کوچک‌تر اینجا جا می‌گیرد.';

  @override
  String get settingsStateFailed => 'ناموفق';

  @override
  String get providerAppsGroupServer => 'عمل به‌عنوان سرور';

  @override
  String get providerAppsGroupServerDescription =>
      'برای فضاهایی که GitHub App این نصب را به ارث می‌برند. فضا با App یا PAT خودش در فضای کاری → عمومی پیکربندی می‌شود.';

  @override
  String get providerAppsGroupPrConversations => 'گفتگوهای pull request';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      'چگونه توسعه‌دهندگان در فضاهای ارثی در GitHub با این سرور صحبت می‌کنند. فضای با App خودش رباتش را در فضای کاری → عمومی دارد. بدون وب‌هوک یا نشانی عمومی — سرور نظرسنجی می‌کند.';

  @override
  String get providerAppBotLogin => 'ورود ربات';

  @override
  String get providerAppBotLoginEmpty =>
      'اتصال را آزمایش کنید تا ورود ربات حل شود.';

  @override
  String get providerAppAskOnGitHub => 'پرسیدن در GitHub';

  @override
  String get providerAppAskOnGitHubHint =>
      'ورود ربات بالا را در نظر pull request منشن کنید — پسوند ⁨[bot]⁩ اختیاری است — برای درخواست بازبینی یا سؤال، پاسخ داخل رشته‌های بازبینی‌اش، یا افزودن برچسب ⁨ai-review⁩ برای درخواست بازبینی.';

  @override
  String get providerAppsGroupSignIn => 'ورود افراد';

  @override
  String get providerAppsGroupSignInDescription =>
      'به هر عضو اجازه می‌دهد حساب خودش را وصل کند و اعتبارنامهٔ خودش را بگیرد.';

  @override
  String get providerAppCapActsAsServer => 'به‌عنوان سرور عمل می‌کند';

  @override
  String get providerAppCapSignsIn => 'افراد را وارد می‌کند';

  @override
  String get portLabel => 'پورت';

  @override
  String get mcpNoTokenWarning =>
      'بدون توکن، هر چیزی که به این پورت برسد می‌تواند همهٔ ابزارها را فراخوانی کند.';

  @override
  String get mcpBridgedToolsLabel => 'ابزارها';

  @override
  String get guardrailFamilyFiles => 'فایل‌ها';

  @override
  String get guardrailFamilyGit => 'Git و pull requestها';

  @override
  String get guardrailFamilyMachine => 'ماشین و شبکه';

  @override
  String get guardrailFamilyControl => 'اسرار و فضای کاری';

  @override
  String get guardrailScopeFieldLabel => 'ویرایش قواعد برای';

  @override
  String get guardrailScopeFieldDescription =>
      'محدودهٔ باریک‌تر بر گسترده‌تر می‌برد. قواعد اینجا روی ارث‌بری اعمال می‌شوند.';

  @override
  String get guardrailSetHere => 'تنظیم در اینجا';

  @override
  String get guardrailClearAllHere => 'پاک کردن همه';

  @override
  String get sandboxingCardLabel => 'سندباکس';

  @override
  String get sandboxingCardDescription =>
      'آیا کار عامل از این میزبان ایزوله اجرا می‌شود، و عامل ایزوله هنوز به چه می‌رسد.';

  @override
  String get sandboxBackendNoneActive => 'میزبان، بدون ایزوله';

  @override
  String get sandboxSummaryHost => 'میزبان';

  @override
  String get sandboxGroupIsolation => 'ایزوله‌سازی';

  @override
  String get sandboxGroupIsolationDescription =>
      'فرآیندها و نوشتن فایل عامل واقعاً کجا رخ می‌دهد.';

  @override
  String get sandboxBackendFieldDescription =>
      'خودکار قوی‌ترین مورد پشتیبانی‌شدهٔ این میزبان را برمی‌دارد. یکی را قفل کنید تا زیر پایتان عوض نشود.';

  @override
  String get sandboxCapabilitiesDescription =>
      'سوراخ‌های زده‌شده از مرز. هر کدام چیزی است که عامل ایزوله هنوز می‌تواند به دنیای بیرون بکند.';

  @override
  String get sandboxSummaryInForce => 'در حال اجرا';

  @override
  String get rigsInstallHintLabel => 'چطور نصب شود';

  @override
  String get rigsStarting => 'در حال شروع';

  @override
  String get rigsResidentMemory => 'حافظهٔ مقیم';

  @override
  String get installedLabel => 'نصب‌شده';

  @override
  String get notInstalledLabel => 'نصب نشده';

  @override
  String ssoOtherKindUnsaved(String method) {
    return '⁨$method⁩ تغییرات ذخیره‌نشده دارد';
  }

  @override
  String get collapseComment => 'جمع کردن نظر';

  @override
  String get expandComment => 'گسترش نظر';

  @override
  String get suggestedChange => 'تغییر پیشنهادی';

  @override
  String get emptyComment => 'نظر خالی';

  @override
  String repliesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count پاسخ',
      one: '1 پاسخ',
    );
    return '$_temp0';
  }

  @override
  String get pendingReview => 'بازبینی در انتظار';

  @override
  String failedToResolveConversation(String error) {
    return 'به‌روزرسانی گفتگو ممکن نشد: ⁨$error⁩';
  }

  @override
  String get addSingleComment => 'افزودن نظر تکی';

  @override
  String get addToReview => 'افزودن به بازبینی';

  @override
  String get startAReview => 'شروع بازبینی';

  @override
  String get reviewNeedsABody =>
      'ابتدا خلاصه‌ای بنویسید یا نظر درون‌خطی در صف بگذارید';

  @override
  String get reviewSubmitted => 'بازبینی ارسال شد';

  @override
  String get finishYourReview => 'بازبینی‌تان را تمام کنید';

  @override
  String get commentVerdict => 'نظر';

  @override
  String pendingCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نظر در انتظار',
      one: '1 نظر در انتظار',
    );
    return '$_temp0';
  }

  @override
  String andNMore(int count) {
    return 'و $count مورد دیگر';
  }

  @override
  String get queuedCommentHint =>
      'این نظر وقتی بازبینی را ارسال کنید بیرون می‌رود.';

  @override
  String commentOnLinesRange(int start, int end) {
    return 'خطوط $start تا $end';
  }

  @override
  String get claudeAccountsTitle => 'حساب‌های Claude Code';

  @override
  String get claudeAccountsDescription =>
      'هر حساب ورود جداگانهٔ Claude Code است. اجراها از حساب‌های پیوست‌شدهٔ زیر به همین ترتیب استفاده می‌کنند.';

  @override
  String get claudeAccountsEmpty => 'هنوز حسابی نیست';

  @override
  String get claudeAccountAdd => 'افزودن حساب';

  @override
  String get claudeAccountSignIn => 'ورود';

  @override
  String get claudeAccountSignInAgain => 'ورود دوباره';

  @override
  String get claudeAccountSignInHint =>
      'این را در ترمینال روی سرور اجرا کنید. مرورگر را برای اتمام ورود باز می‌کند و اعتبارنامه را در پوشهٔ این حساب می‌نویسد.';

  @override
  String get claudeAccountSignedOut => 'خارج‌شده';

  @override
  String get claudeAccountExpired => 'ورود منقضی شد';

  @override
  String claudeAccountExpiredDetail(String when) {
    return 'ورود در $when منقضی شد. برای استفاده از این حساب دوباره وارد شوید.';
  }

  @override
  String get claudeAccountMakeDefault => 'پیش‌فرض کردن';

  @override
  String get claudeAccountDefault => 'پیش‌فرض';

  @override
  String claudeAccountRemoveConfirm(String label) {
    return '⁨$label⁩ حذف شود؟';
  }

  @override
  String get claudeAccountRemoveDetail =>
      'این حساب را خارج می‌کند و پوشه‌اش را روی سرور حذف می‌کند. خود ورود تحت تأثیر نیست.';

  @override
  String claudeAccountStatusUnknown(String error) {
    return 'بررسی این حساب ممکن نشد: ⁨$error⁩';
  }

  @override
  String claudeAccountUsedPercent(String percent) {
    return '$percent٪ استفاده‌شده';
  }

  @override
  String get accountPoolStrategy => 'چرخش';

  @override
  String get accountPoolPinned => 'سنجاق‌شده';

  @override
  String get accountPoolRoundRobin => 'نوبت چرخشی';

  @override
  String get accountPoolSerial => 'یکی‌یکی';

  @override
  String get accountPoolPinnedHint =>
      'همیشه از حساب اول شروع کنید. بقیه اگر شکست بخورد پشتیبان می‌مانند.';

  @override
  String get accountPoolRoundRobinHint =>
      'اجراها را بین حساب‌ها پخش کنید، هر دیسپچ به بعدی بروید.';

  @override
  String get accountPoolSerialHint =>
      'حساب اول را تمام کنید پیش از دست زدن به بعدی.';

  @override
  String get accountPoolMoveUp => 'حرکت به بالا';

  @override
  String get accountPoolMoveDown => 'حرکت به پایین';

  @override
  String get accountPoolUsingAll =>
      'هنوز چیزی پیوست نشده — همهٔ حساب‌ها به همین ترتیب استفاده می‌شوند.';

  @override
  String get accountPoolInheriting => 'ارث‌بری حساب‌های فضای کاری.';

  @override
  String get accountPoolResetToWorkspace => 'بازنشانی به حساب‌های فضای کاری';

  @override
  String accountPoolCoolingOff(String when) {
    return 'خارج از سهمیه تا $when';
  }

  @override
  String get accountPoolSignedOut => 'خارج‌شده';

  @override
  String get accountPoolExpired => 'ورود منقضی';

  @override
  String accountPoolLoadFailed(String error) {
    return 'بارگذاری چرخش ممکن نشد: ⁨$error⁩';
  }

  @override
  String get providerSignedInAccount => 'حساب واردشده';

  @override
  String get agentAccountsTab => 'حساب‌ها';

  @override
  String get agentClaudeAccountsNoticeTitle => 'چند حساب Claude Code';

  @override
  String agentClaudeAccountsNoticeBody(int count) {
    return 'این اجراکننده به‌عنوان یکی از $count حساب Claude Code این میزبان وارد می‌شود. کدام را انتخاب کنید، یا بینشان بچرخانید، در زبانهٔ حساب‌ها.';
  }

  @override
  String get agentAccountsDescription =>
      'اجراهای این عامل از کدام حساب‌ها استفاده می‌کنند. هر بلوک ابتدا انتخاب فضای کاری را به ارث می‌برد.';

  @override
  String get agentAccountsNothingToRotate =>
      'چیزی برای چرخش نیست — ابتدا حساب یا کلید دوم را وصل کنید.';

  @override
  String failedToPostReply(String error) {
    return 'ارسال پاسخ ممکن نشد: ⁨$error⁩';
  }

  @override
  String commentOnLine(int line) {
    return 'خط $line';
  }

  @override
  String get viewInDiff => 'نمایش در دیف';

  @override
  String get subscriptionUsagePreviousAccount => 'حساب قبلی';

  @override
  String get subscriptionUsageNextAccount => 'حساب بعدی';

  @override
  String inReplyTo(String path) {
    return 'در پاسخ به ⁨$path⁩';
  }

  @override
  String get subscriptionUsageNoneReported => 'مصرفی برای این حساب گزارش نشده.';

  @override
  String get subscriptionUsageCredits => 'اعتبار';

  @override
  String get reviewHubStaticRule => 'قاعدهٔ ایستا';

  @override
  String get reviewHubStarted => 'بازبینی شروع شد';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return 'یافتهٔ قاعدهٔ قطعی (⁨$rule⁩) روی خطی که این pull request می‌افزاید — نه از عامل بازبین.';
  }

  @override
  String get prReviewArtifactTab => 'بازبینی PR';

  @override
  String get prReviewRunning => 'در حال بازبینی این pull request…';

  @override
  String get prReviewStarting => 'شروع بازبینی…';

  @override
  String get prReviewStartingBody =>
      'آماده‌سازی worktree این pull request. بازبین‌ها به‌محض آمادگی شروع می‌کنند.';

  @override
  String get prReviewFailed => 'بازبینی ناموفق بود.';

  @override
  String get prReviewRerunning => 'در حال بازبینی مجدد…';

  @override
  String get prReviewNoOpenFindings => 'یافتهٔ بازی نیست';

  @override
  String prReviewOpenFindings(int count) {
    return '$count یافتهٔ باز';
  }

  @override
  String subscriptionUsageSpend(String used, String limit) {
    return '$used از $limit';
  }

  @override
  String reviewCommentsPosted(int posted, int skipped, int failed) {
    return 'به‌عنوان ربات $posted نظر ارسال شد. $skipped رد شد (بدون لنگر فایل)، $failed ناموفق.';
  }

  @override
  String reviewFindingsOutOfDiff(int count, String files) {
    return '$count یافته کدهایی را هدف می‌گیرد که این pull request تغییر نمی‌دهد ($files). GitHub فقط نظر درون‌خطی روی دیف می‌پذیرد.';
  }

  @override
  String get reviewRailReport => 'گزارش';

  @override
  String get reviewNoFindingsTitle => 'هنوز یافتهٔ بازبینی نیست';

  @override
  String get reviewNoFindingsHint =>
      'یافته‌ها وقتی عامل‌ها پست کنند اینجا ظاهر می‌شوند.';

  @override
  String reviewShowDismissed(int count) {
    return 'نمایش $count ردشده';
  }

  @override
  String reviewHideDismissed(int count) {
    return 'پنهان کردن $count ردشده';
  }

  @override
  String reviewDisagreementsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count اختلاف بازبین تشخیص داده شد',
      one: '1 اختلاف بازبین تشخیص داده شد',
    );
    return '$_temp0';
  }

  @override
  String get reviewFilterKind => 'نوع';

  @override
  String get reviewFilterStatus => 'وضعیت';

  @override
  String get reviewKindBug => 'باگ';

  @override
  String get reviewKindSuggestion => 'پیشنهاد';

  @override
  String get reviewKindRecommendation => 'توصیه';

  @override
  String get reviewKindQuestion => 'سؤال';

  @override
  String get reviewKindTicket => 'تیکت';

  @override
  String get archiveSpace => 'بایگانی فضا';

  @override
  String get archivedSpaces => 'فضاهای بایگانی‌شده';

  @override
  String get archivedSpacesEmpty => 'فضای بایگانی‌شده‌ای نیست';

  @override
  String get restoreSpace => 'بازیابی';

  @override
  String archivedWhen(String time) {
    return 'بایگانی‌شده $time';
  }

  @override
  String get deleteSpacePermanently => 'حذف دائمی';

  @override
  String get renameSpace => 'تغییر نام فضا';

  @override
  String get renameConversation => 'تغییر نام گفتگو';

  @override
  String get spaceActions => 'کنش‌های فضا';

  @override
  String get conversationActions => 'کنش‌های گفتگو';

  @override
  String get editSpaceRepos => 'ویرایش مخزن‌ها';

  @override
  String get editSpaceReposTitle => 'مخزن‌های فضا';

  @override
  String get editSpaceReposWarning =>
      'افزودن مخزن آن را در این فضا checkout می‌کند؛ برداشتن یکی پوشه‌اش را حذف می‌کند.';

  @override
  String get agentSectionIdentity => 'هویت';

  @override
  String get agentSectionRuntime => 'زمان اجرا';

  @override
  String get agentSectionGuardrails => 'گاردریل‌ها';

  @override
  String orgChartReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count گزارش‌دهنده',
      one: '1 گزارش‌دهنده',
    );
    return '$_temp0';
  }

  @override
  String get teamsFilterHint => 'فیلتر تیم‌ها…';

  @override
  String get teamsSummaryWithLeader => 'با رهبر';

  @override
  String teamCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تیم',
      one: '1 تیم',
      zero: 'بدون تیم',
    );
    return '$_temp0';
  }

  @override
  String agentDeleteLongDescription(String name) {
    return 'حذف ⁨$name⁩ نمایه، پیوند مهارت‌ها و تاریخچهٔ اجرا را برمی‌دارد. برگشت‌ناپذیر است.';
  }

  @override
  String get resetToDefault => 'بازنشانی به پیش‌فرض';

  @override
  String get newAgent => 'عامل جدید';

  @override
  String get newSkill => 'مهارت جدید';

  @override
  String get zoomIn => 'بزرگ‌نمایی';

  @override
  String get zoomOut => 'کوچک‌نمایی';

  @override
  String get resetZoom => 'بازنشانی بزرگ‌نمایی';

  @override
  String get imageHostedOnGitHub => 'تصویر میزبان‌شده در GitHub';

  @override
  String get imageOpenExternally => 'تصویر · باز کردن خارجی';

  @override
  String get memoryScopeAll => 'همهٔ محدوده‌ها';

  @override
  String get memoryScopeWorkspace => 'سراسری فضای کاری';

  @override
  String get memoryScopeFilterLabel => 'فیلتر بر اساس محدوده';

  @override
  String memoryScopeRepoTooltip(String repo) {
    return 'محدود به مخزن ⁨$repo⁩';
  }

  @override
  String get toolScreenshot => 'اسکرین‌شات از عامل';

  @override
  String get toolImageUnavailable => 'تصویر در دسترس نیست';

  @override
  String toolImagesUnavailable(int count) {
    return '$count تصویر در دسترس نیست';
  }

  @override
  String get shakeUnavailable => '⁨/shake⁩ روی این سرور در دسترس نیست';

  @override
  String get shakeNothing =>
      'چیزی برای تکان دادن نیست — نوبت‌های اخیر محافظت شده‌اند';

  @override
  String shakeDone(int tokens) {
    return 'حدود $tokens توکن آزاد شد';
  }

  @override
  String get compactionDivider => 'فشرده شد';

  @override
  String compactionDividerCount(int count) {
    return 'فشرده شد · $count پیام تا شد';
  }

  @override
  String get composerDropToAttach => 'رها کنید تا پیوست شود';

  @override
  String get attachmentUnavailable => 'پیوست در دسترس نیست';

  @override
  String get attachmentUnavailableDetail =>
      'این پیوست دیگر در حافظه نیست. دوباره پیوست کنید تا پیش‌نمایش شود.';

  @override
  String get attachmentPreviewFailed => 'باز کردن این فایل ممکن نشد';

  @override
  String get attachmentPreviewUnsupported =>
      'پیش‌نمایشی برای این نوع فایل نیست';

  @override
  String get attachmentTooLargeToPreview => 'برای پیش‌نمایش خیلی بزرگ است';

  @override
  String get attachmentOpenExternally => 'باز کردن در برنامهٔ پیش‌فرض';

  @override
  String get asideUnavailable =>
      'برای استفاده از این، مدل یک‌بارمصرف را در تنظیمات فضای کاری بگذارید';

  @override
  String get asideEmpty => 'هنوز چیزی برای کار نیست';

  @override
  String get asideFailed => 'پاسخی گرفته نشد';

  @override
  String get handoffTitle => 'تحویل';

  @override
  String get asideTitle => 'سؤال کناری';

  @override
  String get attachFilesOrDrop => 'پیوست فایل — یا اینجا رها کنید';

  @override
  String get guidedGoalTitle => 'تیز کردن هدف';

  @override
  String get guidedGoalIntro =>
      'عاملی که بدون نظارت کار می‌کند باید دقیقاً بداند کی تمام شده. اول چند سؤال.';

  @override
  String get guidedGoalAnswerHint => 'پاسخ شما';

  @override
  String get guidedGoalNext => 'بعدی';

  @override
  String get guidedGoalStart => 'شروع هدف';

  @override
  String get guidedGoalSkip => 'رد کردن و اجرا به‌همان صورت';

  @override
  String guidedGoalStillMissing(String items) {
    return 'هنوز نامشخص: ⁨$items⁩';
  }

  @override
  String get conversationTreeTitle => 'درخت گفتگو';

  @override
  String conversationTreeBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شاخه',
      one: '1 شاخه',
    );
    return '$_temp0';
  }

  @override
  String get conversationTreeSwitch => 'ادامه از اینجا';

  @override
  String get conversationTreeFork => 'شاخه به گفتگوی جدید';

  @override
  String get conversationTreeCurrent => 'روی این شاخه';

  @override
  String get conversationTreeEmpty => 'هنوز چیزی اینجا نیست';

  @override
  String get conversationTreeForked => 'به گفتگوی جدید شاخه شد';

  @override
  String get conversationTreeSwitched => 'اکنون از آن پیام ادامه می‌دهید';

  @override
  String exportSaved(String path) {
    return 'ذخیره در ⁨$path⁩';
  }

  @override
  String get exportFailed => 'نوشتن خروجی ممکن نشد';

  @override
  String get contextCommandNoAgent =>
      'عاملی در این گفتگو نیست، پس پنجرهٔ زمینه‌ای برای باز کردن نیست';

  @override
  String contextCommandNoSuchAgent(String name, String names) {
    return 'عاملی به نام «⁨$name⁩» در این گفتگو نیست. امتحان کنید: ⁨$names⁩';
  }

  @override
  String get dumpCopied => 'رونوشت در کلیپ‌بورد کپی شد';

  @override
  String get messageQueueHint => 'به تایپ ادامه دهید تا تغییرات بعدی صف شوند';

  @override
  String get steerNow => 'هدایت';

  @override
  String get steeringQueueLabel => 'پیام‌های هدایت در صف';

  @override
  String get steeringDeliverUnavailable =>
      'عاملی در حال اجرا الان نمی‌تواند بگیردش — در صف می‌ماند.';

  @override
  String get reorderSteeringCard => 'مرتب‌سازی مجدد پیام در صف';

  @override
  String get editSteeringCard => 'ویرایش پیام در صف';

  @override
  String get deleteSteeringCard => 'حذف پیام در صف';

  @override
  String get steeringBadge => 'هدایت‌شده';

  @override
  String get settingsSandboxLabel => 'سندباکس';

  @override
  String get sandboxExecGrantsTitle => 'مجوزهای اجرایی';

  @override
  String get sandboxExecGrantsSubtitle =>
      'برنامه‌هایی که عامل‌ها می‌توانند از رونوشت کاری مخزن‌هایتان اجرا کنند. هر ورودی وقتی سندباکس پرسید توسط شما تأیید شده.';

  @override
  String get sandboxExecGrantsEmpty =>
      'هنوز تصمیمی ثبت نشده. اولین باری که عاملی بخواهد برنامه‌ای از رونوشت کاری‌اش اجرا کند پرسیده می‌شود.';

  @override
  String get sandboxExecGrantRevoke => 'لغو';

  @override
  String get sandboxExecGrantAllowed => 'مجاز';

  @override
  String get sandboxExecGrantBlocked => 'مسدود';

  @override
  String get sandboxExecGrantRevokeConfirmTitle => 'این تصمیم لغو شود؟';

  @override
  String get sandboxExecGrantRevokeConfirmBody =>
      'دفعهٔ بعد که عاملی بخواهد برنامه‌ای از این رونوشت اجرا کند دوباره پرسیده می‌شود.';

  @override
  String get repoScriptsTest => 'آزمایش';

  @override
  String get repoScriptsTestTooltip =>
      'اجرای این پیش‌نویس در کلون دورریختنی مخزن';

  @override
  String get repoScriptsRunKindTest => 'آزمایش';

  @override
  String get demoBadgeLabel => 'دمو';

  @override
  String get demoFilePickerTitle => 'فایل‌های دمو';

  @override
  String get demoFilePickerBody =>
      'دمو آپلود را جعل می‌کند: هرکدام را انتخاب کنید و بدون دست زدن به دیسک به پیام پیوست می‌شود.';

  @override
  String get demoFilePickerAttach => 'پیوست';

  @override
  String get demoReadOnlySave => 'فقط‌خواندنی در دمو';

  @override
  String get demoBadgeTooltip =>
      'در حال کاوش دمو هستید. داده ساختگی است و عامل‌ها اسکریپت شده‌اند.';

  @override
  String get demoFirstRunTitle => 'در دموی زنده هستید';

  @override
  String demoFirstRunBody(int minutes) {
    return 'این برنامهٔ واقعی روی کد واقعی است — فقط داده ساختگی است. عامل‌ها اجراهای واقعی را از اسکریپت استریم می‌کنند، پس چیزی به مدل نمی‌رسد و چیزی روی ماشین اجرا نمی‌شود. فضای کاری مال شماست و بعد از $minutes دقیقه ناپدید می‌شود.';
  }

  @override
  String get demoFirstRunDismiss => 'متوجه شدم';

  @override
  String get demoTourTitle => 'از کجا شروع کنید';

  @override
  String get demoTourSubtitle =>
      'چهار جا که نشان می‌دهد برنامه واقعاً چه می‌کند.';

  @override
  String get demoTourSkip => 'رد کردن';

  @override
  String get demoTourStarRepo => 'ستاره در GitHub';

  @override
  String get demoTourOpen => 'باز کردن';

  @override
  String get demoTourSpacesTitle => 'با عامل حرف بزنید';

  @override
  String get demoTourSpacesBody =>
      'در فضا پیام بفرستید و استریم اجرا را ببینید — فکر، فراخوانی ابزار و هزینه، دقیقاً مثل اجرای واقعی.';

  @override
  String get demoTourReviewTitle => 'بازبینی یک pull request';

  @override
  String get demoTourReviewBody =>
      '⁨#412⁩ را باز کنید. نظر درون‌خطی بگذارید یا بازبینی ارسال کنید؛ حرف‌تان در رشته می‌ماند.';

  @override
  String get demoTourTicketsTitle => 'کار را دنبال کنید';

  @override
  String get demoTourTicketsBody =>
      'تیکت‌ها، کارها و برنامه‌ها به همان گفتگوهایی که عامل‌ها دارند پیوند شده‌اند.';

  @override
  String get demoTourInboxTitle => 'کل عملیات را ببینید';

  @override
  String get demoTourInboxBody =>
      'هر هشدار از هر ستون در یک صندوق ورودی می‌آید — بازبینی‌ها، تیکت‌ها، اجراها و جلسات.';

  @override
  String get demoUnavailableTitle => 'در دمو در دسترس نیست';

  @override
  String get demoUnavailableTerminal =>
      'ترمینال شل واقعی روی میزبان سرور اجرا می‌کند. دمو هیچ سطح اجرایی ندارد — همان چیزی که باز کردنش برای عموم را امن می‌کند.';

  @override
  String get demoUnavailableRig =>
      'محفظه یک ماشین مجازی دورریختنی است که عامل می‌راند. دمو هیچ‌کدام را بوت نمی‌کند: نقطهٔ پایانی عمومی که بتواند VM شروع کند دمو نیست.';

  @override
  String get demoUnavailableEditor =>
      'ویرایشگر درون‌مرورگر فرآیند ⁨code-server⁩ روی checkout واقعی اجرا می‌کند. دمو هیچ‌کدام را ندارد.';

  @override
  String get demoUnavailableFeeds =>
      'دمو خوراک واقعی می‌خواند، اما فهرست اشتراکش ثابت است. افزودن یا برداشتن اینجا غیرفعال است.';

  @override
  String get demoUnavailableForge =>
      'دمو اعتبارنامه‌ای ندارد و هرگز با GitHub، GitLab یا Linear تماس نمی‌گیرد. pull requestهایش فیکسچرند و نظرهایتان روی آن‌ها محلی ذخیره می‌شود.';

  @override
  String get demoUnavailableModels =>
      'دمو هیچ مدلی را فراخوانی نمی‌کند. اجراهای عامل پخش اسکریپت‌شده‌اند، به همین خاطر هزینه‌ای ندارند و به ارائه‌دهنده‌ای نمی‌رسند.';

  @override
  String get demoUnavailableMcp =>
      'سطح ابزار MCP روی دمو نصب نیست، پس کلاینت خارجی نمی‌تواند به آن وصل شود.';

  @override
  String get demoUnavailableRepos =>
      'دمو کدی checkout نمی‌کند و git اجرا نمی‌کند. مخزنی که می‌بینید فیکسچر پشت pull requestهاست.';

  @override
  String get demoUnavailableSkills =>
      'نصب مهارت کد را دانلود و اسکن می‌کند. دمو چیزی واکشی نمی‌کند.';

  @override
  String get demoUnavailableSso =>
      'ورود یکپارچه پیکربندی سرور است. دمو به‌جای آن شما را به‌عنوان مهمان موقت وارد می‌کند.';

  @override
  String get demoUnavailableAudio =>
      'ضبط و دیکته به گرفتن صدا و مدل گفتار روی میزبان نیاز دارند. دمو هیچ‌کدام را ندارد، پس جلساتش رونوشت بدون پخش‌اند.';

  @override
  String get demoUnavailableServerAdmin =>
      'این مدیریت سرور است. دمو به هر بازدیدکننده فضای کاری دورریختنی خودش را می‌دهد و چیزی فراتر از آن نه.';

  @override
  String get demoUnavailablePipelines =>
      'خط‌لوله‌ها اینجا اجرا نمی‌شوند. بازدیدکننده‌ای که بتواند یک گام bash بنویسد و آن را — دستی یا از طریق یک محرک رویداد — شروع کند، در حال اجرای کد روی این میزبان است.';

  @override
  String get settingsBackupRestore => 'پشتیبان و بازیابی';

  @override
  String get settingsBackupRestoreDescription =>
      'اسنپ‌شات همهٔ پایگاه‌های دادهٔ این سرور، به‌علاوهٔ خروجی، ورود و حذف یک فضای کاری.';

  @override
  String get backupSnapshotsLabel => 'اسنپ‌شات نصب';

  @override
  String get backupSnapshotsExplainer =>
      'اسنپ‌شات هر پایگاه داده را در پوشه‌ای با برچسب زمانی روی میزبان سرور کپی می‌کند. بازیابی کل نصب یعنی کپی آن پوشه با سرور متوقف؛ یک فضای کاری را می‌توان از اینجا بازیابی کرد.';

  @override
  String get backupNowAction => 'پشتیبان همین حالا';

  @override
  String backupSnapshotWritten(String path) {
    return 'اسنپ‌شات در ⁨$path⁩ نوشته شد';
  }

  @override
  String get backupNoSnapshots =>
      'هنوز اسنپ‌شاتی نیست. فقط وقتی بخواهید گرفته می‌شود — زمان‌بندی نشده.';

  @override
  String get backupSnapshotComplete => 'کامل';

  @override
  String get backupSnapshotIncomplete => 'ناقص';

  @override
  String get backupSnapshotIncompleteNote =>
      'مانیفست غایب است یا فایل‌هایی را نام می‌برد که نیستند، پس این اسنپ‌شات کل نصب را بازیابی نمی‌کند. فایل‌های فضای کاری موجود هنوز یکی‌یکی قابل پذیرش‌اند.';

  @override
  String backupSnapshotWorkspaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فضای کاری',
      one: '1 فضای کاری',
      zero: 'بدون فضای کاری',
    );
    return '$_temp0';
  }

  @override
  String backupSnapshotSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فضای کاری ثبت نشد',
      one: '1 فضای کاری ثبت نشد',
    );
    return '$_temp0';
  }

  @override
  String get backupServerPathLabel => 'مسیر روی سرور';

  @override
  String get backupRestoreAction => 'بازیابی';

  @override
  String get backupRestoreTitle => 'بازیابی فضای کاری';

  @override
  String backupRestoreBody(String name) {
    return 'همه چیز در ⁨$name⁩ با رونوشت این اسنپ‌شات جایگزین می‌شود. هر کاری که آن فضای کاری از زمان اسنپ‌شات کرده از دست می‌رود و برگشت‌ناپذیر است.';
  }

  @override
  String backupRestoreDone(String name) {
    return '⁨$name⁩ از اسنپ‌شات بازیابی شد.';
  }

  @override
  String get backupWorkspaceUnknown => 'دیگر روی این سرور نیست';

  @override
  String get backupWorkspaceDataLabel => 'دادهٔ فضای کاری';

  @override
  String get backupWorkspaceDataExplainer =>
      'یک فضای کاری یک فایل پایگاه داده است، پس خروجی آن فایل را کپی می‌کند نه جدول‌به‌جدول. ورود همه چیز فضای کاری هدف را با فایلی که نام می‌برید جایگزین می‌کند.';

  @override
  String get backupExportAction => 'خروجی';

  @override
  String backupExportDone(String path) {
    return 'خروجی در ⁨$path⁩';
  }

  @override
  String get backupExportedFileLabel => 'فایل خروجی روی سرور';

  @override
  String get backupImportAction => 'ورود';

  @override
  String backupImportTitle(String name) {
    return 'ورود به ⁨$name⁩';
  }

  @override
  String backupImportBody(String name) {
    return 'همه چیز در ⁨$name⁩ با محتوای فایل جایگزین می‌شود. آنچه آن فضای کاری حالا دارد از دست می‌رود و برگشت‌ناپذیر است.';
  }

  @override
  String get backupImportSourceLabel => 'فایل پایگاه دادهٔ فضای کاری';

  @override
  String get backupImportSourceDescription =>
      'فایل ⁨.db⁩ که سرور بتواند بخواند. مسیرها روی میزبان سرور حل می‌شوند، نه این دستگاه.';

  @override
  String backupImportDone(String name) {
    return 'به ⁨$name⁩ وارد شد.';
  }

  @override
  String backupDeleteBody(String name) {
    return '⁨$name⁩ از همهٔ فهرست‌ها و جستجوها ناپدید می‌شود. فایل پایگاه داده‌اش روی دیسک می‌ماند، پشتیبان‌ها هنوز شاملش می‌شوند، و چیزی فضا را خودکار پس نمی‌گیرد.';
  }

  @override
  String get backupExportDescription =>
      'رونوشتی روی سرور بنویسید، یا یکی به این دستگاه دانلود کنید.';

  @override
  String get backupExportOnServerAction => 'ذخیره روی سرور';

  @override
  String get backupDownloadAction => 'دانلود';

  @override
  String backupDownloadSaved(String path) {
    return 'ذخیره در ⁨$path⁩';
  }

  @override
  String get backupDownloadInBrowser => 'مرورگر در حال دانلود است.';

  @override
  String get backupRestoreFromDeviceLabel => 'بازیابی از این دستگاه';

  @override
  String get backupRestoreFromDeviceDescription =>
      'فایل پایگاه دادهٔ فضای کاری را اینجا انتخاب کنید و Control Center آن را به سرور آپلود می‌کند. همان است که وقتی سرور این ماشین نیست کار می‌کند.';

  @override
  String get backupUploadAction => 'انتخاب فایل و آپلود';

  @override
  String get backupTransferUnavailable =>
      'این اتصال از رله به سرور می‌رسد، که انتقال فایل ندارد. برای دانلود یا آپلود پشتیبان مستقیم به سرور وصل شوید.';

  @override
  String get backupTransferForbidden =>
      'سرور رد کرد. دانلود فضای کاری نقش ادمین می‌خواهد، بازیابی نقش مالک، و اسنپ‌شات کامل اپراتور نصب را.';

  @override
  String get backupTransferUnsupported => 'این سرور سطح پشتیبانی ندارد.';

  @override
  String get backupTransferTooLarge => 'فایل بزرگ‌تر از پذیرش سرور است.';

  @override
  String get credentialGateWaitingTitle => 'منتظر اعتبارنامه';

  @override
  String credentialGateHarnessTitle(String provider) {
    return '⁨$provider⁩ اعتبارنامه‌ای ندارد';
  }

  @override
  String get credentialGateSignedOutTitle => 'Claude Code خارج شده';

  @override
  String get credentialGateExpiredTitle => 'ورود Claude Code منقضی شده';

  @override
  String get credentialGatePlanSpentTitle => 'سقف طرح Claude Code رسیده';

  @override
  String credentialGateWaitingAgent(String agent) {
    return '⁨$agent⁩ منتظر ادامه است.';
  }

  @override
  String get credentialGateWaitingRun => 'اجرایی منتظر ادامه است.';

  @override
  String get credentialGateWatching =>
      'در حال پایش رفع — اجرا خودش ادامه می‌دهد.';

  @override
  String credentialGateFreesUpAt(String time) {
    return 'آزاد می‌شود در $time';
  }

  @override
  String credentialGateGivesUpAt(String time) {
    return 'اجرا در $time دست می‌کشد';
  }

  @override
  String get credentialGateCheckAgain => 'بررسی دوباره';

  @override
  String get credentialGateCancelRun => 'لغو اجرا';

  @override
  String get credentialGateAccountsTried => 'حساب‌های امتحان‌شده';

  @override
  String get credentialGateClaudeSignInHint =>
      'از تنظیمات ← آداپترها ← Claude Code وارد شوید، یا فرمان ورود را در ترمینال اجرا کنید. اجرا خودش برمی‌دارد.';

  @override
  String get credentialGateOpenSettings => 'باز کردن تنظیمات';

  @override
  String get selectModel => 'انتخاب مدل';

  @override
  String get allModels => 'همه مدل‌ها';

  @override
  String get noModelsMatchSearch => 'هیچ مدلی با جستجوی شما مطابقت ندارد';

  @override
  String useCustomModelId(String id) {
    return 'استفاده از «$id»';
  }

  @override
  String get modelFree => 'رایگان';

  @override
  String modelOutputTokens(String tokens) {
    return '$tokens خروجی';
  }

  @override
  String modelPricePerMTokens(String input, String output) {
    return '$input ورودی / $output خروجی به ازای هر ۱M توکن';
  }

  @override
  String modelEffortLevels(String levels) {
    return 'تلاش استدلال: $levels';
  }

  @override
  String get modelSupportsReasoning => 'از تلاش استدلال پشتیبانی می‌کند';

  @override
  String get profileDeliveryMetrics => 'معیارهای تحویل';

  @override
  String profileMetricsSample(int count) {
    return 'PRهای تحلیل‌شده: $count';
  }

  @override
  String get profileMergeRate => 'نرخ ادغام';

  @override
  String get profileReviewCoverage => 'پوشش بازبینی';

  @override
  String get profilePrSize => 'اندازه PR';

  @override
  String get profileTimeToMerge => 'زمان تا ادغام';

  @override
  String get profileMergeTimeTrend => 'روند زمان ادغام';

  @override
  String get profileWeeklyMedian => 'میانه هفتگی، مقیاس لگاریتمی';

  @override
  String get profilePrOpeningPattern => 'روز هفته × ساعت، زمان محلی';

  @override
  String get profileFirstReview => 'زمان تا اولین بازبینی';

  @override
  String get profileMetricsTruncated =>
      'صدک‌ها از نمونه‌ای محدود از درخواست‌های کشش موجود استفاده می‌کنند.';

  @override
  String profileLinesChanged(String count) {
    return '$count خط';
  }

  @override
  String profileDurationMinutes(int count) {
    return '$count دقیقه';
  }

  @override
  String profileDurationHours(int count) {
    return '$count ساعت';
  }

  @override
  String profileDurationDaysHours(int days, int hours) {
    return '$daysروز $hoursساعت';
  }

  @override
  String profilePercentiles(String median, String p90) {
    return 'p50 $median · p90 $p90';
  }

  @override
  String profileTeamMembers(int count) {
    return 'اعضا: $count';
  }

  @override
  String noPrsByTeamInWorkspace(String team) {
    return 'هیچ pull requestی از $team در این فضای کاری وجود ندارد';
  }

  @override
  String get profilePrStateFilterLabel => 'فیلتر pull requestها بر اساس وضعیت';

  @override
  String get noProfilePrsMatchSearchHint =>
      'عنوان یا شماره pull request دیگری را امتحان کنید';

  @override
  String get rigNetworkUnrestricted => 'شبکه بدون محدودیت';

  @override
  String get rigNetworkAllowAllHosts => 'اجازه به همه میزبان‌ها';

  @override
  String get rigBrowserPermissionsTitle => 'مجوزهای سایت';

  @override
  String get rigBrowserPermissionsTooltip => 'مجوزهای سایت و شبکه';

  @override
  String get rigBrowserPermissionEmpty => 'هنوز هیچ سایتی مجوزی نخواسته است';

  @override
  String rigBrowserPermissionPrompt(String origin, String permission) {
    return '$origin می‌خواهد از $permission استفاده کند';
  }

  @override
  String get rigBrowserPermissionBlock => 'مسدود کردن';

  @override
  String get rigBrowserPermissionCamera => 'دوربین';

  @override
  String get rigBrowserPermissionMicrophone => 'میکروفون';

  @override
  String get rigBrowserPermissionNotifications => 'اعلان‌ها';

  @override
  String get rigBrowserPermissionGeolocation => 'موقعیت';

  @override
  String get rigBrowserPermissionPersistentStorage => 'ذخیره‌سازی پایدار';

  @override
  String get rigBrowserPermissionClipboard => 'کلیپ‌بورد';

  @override
  String get rigBrowserPermissionDisplayCapture => 'ضبط صفحه';

  @override
  String get rigBrowserPermissionMidi => 'MIDI';

  @override
  String get rigNetworkBypassTitle => 'همه میزبان‌های شبکه مجاز باشند؟';

  @override
  String get rigNetworkBypassBody =>
      'این کار محیط ایزوله را دوباره راه‌اندازی می‌کند و کار ثبت‌نشده داخل آن را کنار می‌گذارد. پس از آن، مهمان تا زمان بسته شدن می‌تواند به هر میزبان شبکه دسترسی داشته باشد.';

  @override
  String get rigNetworkRestartUnrestricted => 'راه‌اندازی مجدد بدون محدودیت';

  @override
  String get rigNetworkUnrestrictedBody =>
      'این محیط ایزوله می‌تواند به همه میزبان‌های شبکه دسترسی داشته باشد. برای بازگرداندن محدودیت‌های پیش‌فرض، آن را ببندید و یک محیط جدید باز کنید.';

  @override
  String get rigNetworkAlreadyUnrestrictedBody =>
      'این شبیه‌ساز Android از قبل شبکه خود را مدیریت می‌کند، بنابراین Control Center نمی‌تواند فهرست مجاز جداگانه‌ای برای میزبان‌ها اعمال کند. نیازی به راه‌اندازی مجدد نیست.';

  @override
  String get rigClipboardPermissionHostToRigTitle =>
      'بریده‌دان در این محیط جای‌گذاری شود؟';

  @override
  String get rigClipboardPermissionHostToRigBody =>
      'Control Center بریده‌دان دستگاه شما را می‌خواند و محتوای آن را به محیط می‌فرستد. محتوای بریده‌دان ممکن است شامل گذرواژه‌ها یا اطلاعات محرمانه دیگر باشد.';

  @override
  String get rigClipboardPermissionRigToHostTitle =>
      'بریده‌دان از این محیط کپی شود؟';

  @override
  String get rigClipboardPermissionRigToHostBody =>
      'Control Center بریده‌دان محیط را می‌خواند و بریده‌دان دستگاه شما را با محتوای آن جایگزین می‌کند. با محتوای آمده از محیط مانند محتوای نامطمئن برخورد کنید.';

  @override
  String get rigClipboardAllowTenMinutes => 'اجازه به‌مدت 10 دقیقه';

  @override
  String get rigClipboardAlwaysAllow => 'همیشه اجازه بده';

  @override
  String get rigClipboardSettingsTitle => 'دسترسی به بریده‌دان';

  @override
  String get rigClipboardSettingsHint =>
      'انتخاب کنید کدام انتقال‌های بریده‌دان بدون پرسش انجام شوند. مجوزهای موقت پس از 10 دقیقه منقضی می‌شوند.';

  @override
  String get rigClipboardAlwaysPasteTitle =>
      'همیشه جای‌گذاری در محیط‌ها مجاز باشد';

  @override
  String get rigClipboardAlwaysPasteDescription =>
      'بریده‌دان این دستگاه را بدون پرسش به هر محیطی بفرستد.';

  @override
  String get rigClipboardAlwaysCopyTitle => 'همیشه کپی از محیط‌ها مجاز باشد';

  @override
  String get rigClipboardAlwaysCopyDescription =>
      'محتوای بریده‌دان را از هر محیطی بدون پرسش روی این دستگاه قرار دهد.';

  @override
  String get workspaceGitHubIdentity => 'هویت GitHub';

  @override
  String get workspaceGitHubIdentityDescription =>
      'نحوه احراز هویت کار پس‌زمینه GitHub در این فضای کاری. ارث‌بردن App نصب، App دیگر، یا فقط رمز دسترسی شخصی.';

  @override
  String get workspaceGitHubModeInherit => 'استفاده از GitHub App این نصب';

  @override
  String get workspaceGitHubModeApp => 'استفاده از GitHub App دیگر';

  @override
  String get workspaceGitHubModePat => 'فقط رمز دسترسی شخصی';

  @override
  String get workspaceGitHubInheritHint =>
      'از GitHub App در سرور → برنامه‌های ارائه‌دهنده استفاده می‌کند.';

  @override
  String get workspaceGitHubAppHint =>
      'هویت ربات و نظرسنجی این فضا. اعضا در شما از طریق این App وارد می‌شوند.';

  @override
  String get workspaceGitHubPatLabel => 'رمز پس‌زمینه';

  @override
  String get workspaceGitHubPatDescription =>
      'برای نظرسنجی و عامل‌ها در این فضا. رمز نمایه عضو نیست.';

  @override
  String get workspaceGitHubHasPat => 'رمز پس‌زمینه ذخیره شده است.';

  @override
  String get workspaceGitHubNoPat => 'رمز پس‌زمینه‌ای ذخیره نشده.';

  @override
  String get profileOverlayHint =>
      'این فیلدها شما در این فضای کاری هستید. فیلدهای خالی نام و ایمیل حساب را به ارث می‌برند. تعویض فضا این لایه را عوض می‌کند.';

  @override
  String get forgeConnectionsThisWorkspace =>
      'وارد شوید یا رمزی برای این فضای کاری جای‌گذاری کنید.';
}
