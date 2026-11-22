// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String steeringForceSendFailed(String error) {
    return 'ابھی بھیجا نہیں جا سکا: $error';
  }

  @override
  String get questionAnswerNotDelivered =>
      'آپ کا جواب نہیں پہنچا۔ ہو سکتا ہے اس کا جواب پہلے ہی دیا جا چکا ہو، یا ایجنٹ نے انتظار ختم کر دیا ہو۔';

  @override
  String get succeeded => 'کامیاب';

  @override
  String agentRunRetryLabel(int number, String time) {
    return 'دوبارہ کوشش ⁨#$number⁩ · $time';
  }

  @override
  String agentRunStarting(String time) {
    return 'شروع ہو رہا ہے · $time';
  }

  @override
  String get agentActivityFollowingLive => 'براہِ راست سرگرمی کی پیروی';

  @override
  String get agentActivityJumpToLatest => 'تازہ ترین پر جائیں';

  @override
  String get agentActivityLoadFailed => 'اس رن کی سرگرمی لوڈ نہیں ہو سکی';

  @override
  String get agentActivityNotRecorded =>
      'اس رن کے لیے کوئی سرگرمی ریکارڈ نہیں ہوئی';

  @override
  String get agentActivityNotRecordedHint =>
      'جو رنز سرگرمی کیپچر فعال ہونے سے پہلے ختم ہو گئے، ان کی کوئی ٹائم لائن نہیں۔';

  @override
  String get agentActivityRunUnavailable => 'یہ رن اب دستیاب نہیں';

  @override
  String agentActivitySubagentOf(String agent) {
    return '⁨$agent⁩ کا ذیلی ایجنٹ';
  }

  @override
  String get agentActivityUnsupported =>
      'منسلک سرور پر سرگرمی کیپچر دستیاب نہیں';

  @override
  String get agentActivityUnsupportedHint =>
      'ایپ دوبارہ شروع کریں تاکہ تازہ ترین سرور بلڈ ملے۔';

  @override
  String get agentActivityWaiting => 'سرگرمی کا انتظار…';

  @override
  String get created => 'بنایا گیا';

  @override
  String get dictationStart => 'ڈکٹیشن شروع کریں';

  @override
  String get dictationListening => 'سن رہا ہے…';

  @override
  String get dictationUnavailable =>
      'ڈکٹیشن کے لیے سرور ہوسٹ پر وائس ماڈل چاہیے۔ آواز کی ترتیبات میں سیٹ اپ کریں۔';

  @override
  String get dictationFailedToStart => 'ڈکٹیشن شروع نہیں ہو سکی';

  @override
  String get dictationHoldToTalkTitle => 'دبا کر بولیں';

  @override
  String get dictationHoldToTalkDescription =>
      'مائیک بٹن یا شارٹ کٹ دبا کر رکھیں تاکہ ڈکٹیشن کریں، چھوڑ کر روکیں۔ بند ہونے پر ایک بار دبائیں شروع کرنے کے لیے اور دوبارہ روکنے کے لیے۔';

  @override
  String get focusConversation => 'گفتگو پر فوکس';

  @override
  String get ideAgentActivity => 'ایجنٹ سرگرمی';

  @override
  String get keybindingPushToTalk => 'دبا کر بولیں';

  @override
  String get agentPermissions => 'ایجنٹ اجازتیں';

  @override
  String get agentPermissionsSettingsDescription =>
      'طے کریں کہ ایجنٹ خود کیا کر سکتے ہیں، پہلے کس بارے میں پوچھیں، یا کبھی نہ کریں — فی ورک اسپیس، ایجنٹ، یا اسپیس۔';

  @override
  String get agentPermissionsMatrixDescription =>
      'ہر قسم کے اثر کے لیے فیصلہ سیٹ کریں۔ قواعد کی ترتیب: اسپیس ایجنٹ پر غالب، ایجنٹ ورک اسپیس پر، ورک اسپیس موڈ پری سیٹ پر۔ سب سے مخصوص قاعدہ لاگو ہوتا ہے۔';

  @override
  String get guardrailLoading => 'قواعد لوڈ ہو رہے ہیں…';

  @override
  String get guardrailRulesLoadFailed => 'اجازت کے قواعد لوڈ نہیں ہو سکے۔';

  @override
  String get guardrailScopeWorkspace => 'ورک اسپیس';

  @override
  String get guardrailScopeAgent => 'ایجنٹ';

  @override
  String get guardrailScopeSpace => 'اسپیس';

  @override
  String get guardrailSelectAgent => 'ایجنٹ منتخب کریں';

  @override
  String get guardrailSelectSpace => 'اسپیس منتخب کریں';

  @override
  String get guardrailNoAgents => 'اس ورک اسپیس میں ابھی کوئی ایجنٹ نہیں۔';

  @override
  String get guardrailNoSpaces => 'اس ورک اسپیس میں ابھی کوئی اسپیس نہیں۔';

  @override
  String get guardrailClassFileDelete => 'فائل حذف کریں';

  @override
  String get guardrailClassFileWriteOutsideWorktree => 'worktree سے باہر لکھیں';

  @override
  String get guardrailClassGitCommit => 'کمیٹ بنائیں';

  @override
  String get guardrailClassGitPush => 'ریموٹ پر پش کریں';

  @override
  String get guardrailClassPrCreate => 'pull request کھولیں';

  @override
  String get guardrailClassPrPublish =>
      'ایک pull request کو اپ ڈیٹ یا merge کریں';

  @override
  String get guardrailClassVendorSyncWrite => 'بیرونی ٹریکر پر لکھیں';

  @override
  String get guardrailClassNetworkEgress => 'نیٹ ورک تک رسائی';

  @override
  String get guardrailClassSecretAccess => 'راز پڑھیں';

  @override
  String get guardrailClassPackageInstall => 'پیکیج انسٹال کریں';

  @override
  String get guardrailClassProcessSpawn => 'پراسیس چلائیں';

  @override
  String get guardrailClassWorkspaceMutation => 'ورک اسپیس کا ڈھانچہ بدلیں';

  @override
  String get guardrailClassEnclosureControl => 'انکلوژر چلائیں (رگ)';

  @override
  String get navRigs => 'رگز';

  @override
  String get rigsUnsupportedServer =>
      'یہ سرور کسی بھی rig سطح کی میزبانی نہیں کر سکتا۔ آپ جس مشین کو استعمال کرنا چاہتے ہیں، اس کے لیے میزبان کے تقاضے چیک کریں۔';

  @override
  String get rigSurfaceComputer => 'کمپیوٹر';

  @override
  String get rigSurfaceBrowser => 'براؤزر';

  @override
  String get rigSurfaceAndroid => 'Android';

  @override
  String get rigSurfaceIosSimulator => 'iOS سمیولیٹر';

  @override
  String get rigSurfaceAppWindow => 'ایپ ونڈو';

  @override
  String rigSurfaceBrowserEngine(String engine) {
    return '$engine';
  }

  @override
  String rigBrowserEngineHint(String engine) {
    return 'ایک عارضی ⁨$engine⁩، آپ کی مشین سے الگ۔ وہی صفحہ ساتھ ساتھ موازنہ کرنے کے لیے دوسرا انجن کھولیں۔';
  }

  @override
  String get rigPhaseReady => 'تیار';

  @override
  String get rigPhaseStarting => 'شروع ہو رہا ہے';

  @override
  String get rigPhaseParked => 'پارک شدہ';

  @override
  String get rigPhaseClosing => 'بند ہو رہا ہے';

  @override
  String get rigPhaseClosed => 'بند';

  @override
  String get rigPhaseFailed => 'ناکام';

  @override
  String get rigPhaseUnknown => 'نامعلوم';

  @override
  String get rigNotAccelerated => 'ایمولیٹڈ';

  @override
  String get rigAudioListen => 'مشین سنیں';

  @override
  String get rigAudioMute => 'مشین خاموش کریں';

  @override
  String get rigYouHaveControl => 'کنٹرول آپ کے پاس ہے';

  @override
  String get rigBackendAvailable => 'دستیاب';

  @override
  String get rigBackendUnavailable => 'دستیاب نہیں';

  @override
  String get rigEgressNotEnforced =>
      'اس بیک اینڈ پر نیٹ ورک بند نہیں — یہ اپنی کنیکٹیویٹی خود سنبھالتا ہے۔';

  @override
  String get rigStartMachine => 'مشین شروع کریں';

  @override
  String get rigStartHint =>
      'ایک عارضی VM شروع کرتا ہے جسے آپ اور آپ کے ایجنٹ اس گفتگو کے لیے شیئر کرتے ہیں۔ بند ہونے پر یہ تباہ ہو جاتا ہے، اور اس کے اندر کچھ بھی آپ کے کمپیوٹر کو نہیں چھوتا۔';

  @override
  String get rigStartAndroidHint =>
      'سرور پر پہلے سے چلنے والے Android ایمولیٹر سے منسلک ہوتا ہے۔ نیٹ ورک تک رسائی الگ تھلگ نہیں ہے۔';

  @override
  String get rigStartIosHint =>
      'macOS سرور پر ایک عارضی iOS Simulator بناتا ہے۔ ٹیسٹ ماحول بند ہونے پر اسے حذف کر دیا جاتا ہے؛ نیٹ ورک تک رسائی الگ تھلگ نہیں ہے۔';

  @override
  String get rigTechnicalDetails => 'تکنیکی تفصیلات';

  @override
  String get rigStopMachine => 'مشین روکیں';

  @override
  String get rigHomeButton => 'ہوم';

  @override
  String get rigRotateClockwise => 'گھڑی وار گھمائیں';

  @override
  String get rigRotateCounterclockwise => 'گھڑی کے خلاف گھمائیں';

  @override
  String get rigTakeScreenshot => 'اسکرین شاٹ لیں';

  @override
  String get rigScreenshotSaved => 'اسکرین شاٹ محفوظ ہو گیا';

  @override
  String rigScreenshotSaveFailed(String error) {
    return 'اسکرین شاٹ محفوظ نہیں ہو سکا: ⁨$error⁩';
  }

  @override
  String get rigSurfaceUnavailable =>
      'یہ سرور اس قسم کی مشین ہوسٹ نہیں کر سکتا۔';

  @override
  String get rigTabNeedsConversation =>
      'پہلے گفتگو کھولیں — مشین ایک ہی گفتگو کی ہوتی ہے، تاکہ آپ اور آپ کے ایجنٹ ایک ہی اسکرین دیکھیں۔';

  @override
  String get ideMenuSectionTools => 'ٹولز';

  @override
  String get ideMenuSectionMachines => 'مشینیں';

  @override
  String get ideMenuSectionReopen => 'دوبارہ کھولیں';

  @override
  String get ideMenuSearchHint => 'تلاش';

  @override
  String get ideMenuNoMatches => 'کوئی مماثل نہیں';

  @override
  String get rigMenuComputer => 'کمپیوٹر';

  @override
  String get rigMenuBrowser => 'براؤزر';

  @override
  String get rigMenuAndroid => 'Android';

  @override
  String get rigMenuIosSimulator => 'iOS سمیولیٹر';

  @override
  String rigLabelNumbered(String label, String suffix) {
    return '$label $suffix';
  }

  @override
  String ideCloseKeepTitle(String name) {
    return '⁨$name⁩ بند کریں؟';
  }

  @override
  String get ideCloseKeepBodyMachine =>
      'مشین پس منظر میں چلتی رہتی ہے — سائڈ بار سے کسی بھی وقت دوبارہ کھولیں۔ ابھی میموری خالی کرنے کے لیے اسے بند کر دیں۔';

  @override
  String get ideCloseKeepBodyShell =>
      'کمانڈ پس منظر میں چلتی رہتی ہے — سائڈ بار سے کسی بھی وقت شیل دوبارہ کھولیں۔ ابھی جو ہو رہا ہے اسے روکنے کے لیے ختم کر دیں۔';

  @override
  String get ideCloseKeepBodyAgent =>
      'ایجنٹ پس منظر میں کام کرتا رہتا ہے — سائڈ بار سے کسی بھی وقت گفتگو دوبارہ کھولیں۔ ابھی رن ختم کرنے کے لیے اسے روک دیں۔';

  @override
  String get ideCloseKeepRunning => 'چلتا رہنے دیں';

  @override
  String get ideCloseShutDownMachine => 'بند کریں';

  @override
  String get ideCloseEndShell => 'شیل ختم کریں';

  @override
  String get ideCloseStopAgent => 'ایجنٹ روکیں';

  @override
  String get rigsSettingsSubtitle =>
      'یہ سرور کیا بوٹ کر سکتا ہے، جن بیس امیجز کی اسے ضرورت ہے، اور اب چلنے والی مشینیں';

  @override
  String get rigsCapabilitiesTitle => 'یہ سرور';

  @override
  String get rigInstallIosAutomation => 'iOS آٹومیشن برج انسٹال کریں';

  @override
  String get rigInstallingIosAutomation => 'iOS آٹومیشن برج انسٹال ہو رہا ہے…';

  @override
  String get rigIosAutomationInstalled => 'iOS آٹومیشن برج انسٹال ہو گیا';

  @override
  String get rigsImagesTitle => 'بیس امیجز';

  @override
  String get rigsImagesHint =>
      'ہر رگ ان ریڈ اونلی امیجز میں سے ایک بوٹ کرتا ہے۔ ہر سیشن ایک عارضی اوورلے پر لکھتا ہے، اس لیے ایک رگ اگلے کے آغاز کو کبھی نہیں بدل سکتا۔';

  @override
  String get rigsRunningTitle => 'اب چل رہی ہیں';

  @override
  String get rigsNoneRunning => 'کوئی مشین نہیں چل رہی۔';

  @override
  String get rigsCustomImagesTitle => 'حسبِ ضرورت امیجز (یہ ورک اسپیس)';

  @override
  String get rigsCustomImagesHint =>
      'Terminal (VM) یا Browser (VM) کو اپنی امیج پر سیٹ کریں — ڈیفالٹس میں اپنے پروجیکٹ کے ٹولز شامل کریں، یا رجسٹری سے کوئی موافق امیج استعمال کریں۔ نئی مشینیں اسے استعمال کرتی ہیں؛ چلتی ہوئی اپنی رکھتی ہیں۔ امیج میں کیا ہونا چاہیے، رگز گائیڈ دیکھیں۔';

  @override
  String get rigsCustomTerminalImageLabel => 'Terminal (VM) امیج';

  @override
  String get rigsCustomBrowserImageLabel => 'Browser (VM) امیج';

  @override
  String get rigsCustomImagePlaceholder =>
      'مثال: ⁨ghcr.io/acme/dev-shell:1.2⁩ — ڈیفالٹ کے لیے خالی چھوڑیں';

  @override
  String get rigsCustomImageInvalid =>
      'رجسٹری ریفرنس درج کریں جیسے ⁨repo/name:tag⁩۔ مقامی پاتھ اور آرکائیوز کی اجازت نہیں۔';

  @override
  String get rigsCustomImageSaved =>
      'محفوظ ہو گیا۔ نئی مشینیں یہ امیج بوٹ کرتی ہیں؛ چلتی ہوئی اپنی رکھتی ہیں۔';

  @override
  String get rigsEgressTitle => 'براؤزر ایگریس (یہ ورک اسپیس)';

  @override
  String get rigsEgressHint =>
      'اضافی ہوسٹس جن تک بند براؤزر پہنچ سکتا ہے — فی لائن ایک: قطعی ہوسٹ (⁨api.example.com⁩) یا اس کے سب ڈومینز کے لیے وائلڈ کارڈ (⁨*.example.com⁩)۔ پروڈکٹ سائٹ دونوں صورتوں میں اجازت یافتہ رہتی ہے۔ نئی مشینوں کو فہرست ملتی ہے؛ چلتی ہوئی وہی رکھتی ہیں جس کے ساتھ بوٹ ہوئیں۔';

  @override
  String rigsEgressInvalid(String host) {
    return '\"⁨$host⁩\" درست ہوسٹ انٹری نہیں۔';
  }

  @override
  String get rigsEgressSaved =>
      'محفوظ ہو گیا۔ نئی براؤزر مشینیں ان ہوسٹس کو قبول کرتی ہیں؛ چلتی ہوئی اپنی رکھتی ہیں۔';

  @override
  String get rigImageInstalled => 'انسٹال شدہ';

  @override
  String get rigImageNotDownloaded => 'ڈاؤن لوڈ نہیں ہوئی';

  @override
  String get rigImageNotPublished => 'شائع نہیں ہوئی';

  @override
  String get rigImageNotPublishedHint =>
      'ابھی اس کے لیے کوئی امیج شائع نہیں ہوئی، اس لیے ڈاؤن لوڈ کرنے کو کچھ نہیں۔ فعال کرنے کے لیے موافق ڈسک امیج درآمد کریں۔';

  @override
  String get rigImageDownload => 'ڈاؤن لوڈ';

  @override
  String get rigImageDownloading => 'ڈاؤن لوڈ ہو رہا ہے…';

  @override
  String get rigImageImport => 'درآمد';

  @override
  String get rigImageImportMessage =>
      'سرور کی فائل سسٹم پر ⁨qcow2⁩ ڈسک امیج کا پاتھ۔ اسے امیج اسٹور میں کاپی کیا جاتا ہے، اس لیے فائل بعد میں منتقل ہو سکتی ہے۔';

  @override
  String get rigConnectingStream => 'رگ سے منسلک ہو رہا ہے';

  @override
  String get rigStreamNotAllowed => 'آپ کو اس رگ تک رسائی نہیں۔';

  @override
  String get rigStreamNotRunning => 'یہ رگ اب نہیں چل رہی۔';

  @override
  String get rigStreamNeedsFfmpeg =>
      'لائیو ویو کے لیے اس ہوسٹ پر ⁨ffmpeg⁩ چاہیے۔ ⁨ffmpeg⁩ انسٹال کریں اور ٹیب دوبارہ کھولیں۔';

  @override
  String get rigStreamNeedsScreenCapture =>
      'لائیو ویو کے لیے اسکرین ریکارڈنگ درکار ہے۔ سسٹم سیٹنگز میں Control Center کو اجازت دیں اور ٹیب دوبارہ کھولیں۔';

  @override
  String get rigStreamEnded => 'لائیو ویو ختم ہو گیا۔';

  @override
  String get rigStreamFailed => 'لائیو ویو نہیں کھل سکا۔';

  @override
  String get rigStreamDisconnected => 'سرور سے منسلک نہیں۔';

  @override
  String rigDropSendingOne(String name) {
    return '\"⁨$name⁩\" مشین میں کاپی ہو رہا ہے…';
  }

  @override
  String rigDropSendingMany(int count) {
    return '$count فائلیں مشین میں کاپی ہو رہی ہیں…';
  }

  @override
  String get rigTerminalDropSending => 'مشین میں کاپی ہو رہا ہے…';

  @override
  String get rigTerminalPasteImage => 'پیسٹ کی گئی تصویر مشین میں محفوظ ہو گئی';

  @override
  String get rigPortsTitle => 'فارورڈ شدہ پورٹس';

  @override
  String get rigPortsTooltip => 'اس مشین کے اندر کھلے پورٹس';

  @override
  String get rigPortsEmpty =>
      'ابھی کچھ سن نہیں رہا۔ ٹرمینل میں سرور شروع کریں — پورٹ 3000 پر ڈیو سرور یہاں نظر آئے گا۔';

  @override
  String get rigPortsAdd => 'پورٹ شامل کریں';

  @override
  String get rigPortsAddHint => 'فارورڈ کرنے کے لیے گیسٹ پورٹ (مثلاً 3000)';

  @override
  String get rigPortsAutoForward => 'پورٹس خود فارورڈ کریں';

  @override
  String get rigPortsCopyUrl => 'مقامی URL کاپی کریں';

  @override
  String rigPortsCopiedUrl(String url) {
    return '⁨$url⁩ کاپی ہو گیا';
  }

  @override
  String get rigPortsStopForward => 'فارورڈنگ روکیں';

  @override
  String get rigPortsExposeLan => 'مقامی نیٹ ورک پر شیئر کریں';

  @override
  String get rigPortsLanPrivate => 'صرف مقامی';

  @override
  String get rigPortsLanShared => 'نیٹ ورک پر';

  @override
  String get rigPortsSetDomain => 'براؤزر ڈومین سیٹ کریں (⁨.test⁩)';

  @override
  String get rigPortsDomainHint =>
      'Browser (VM) کے لیے ڈومین، مثلاً ⁨myapp.test⁩ — وہاں پہنچتا ہے، ہوسٹ پر نہیں';

  @override
  String get rigPortsProcessUnknown => 'نامعلوم پراسیس';

  @override
  String get rigPortsInactive => 'سن نہیں رہا';

  @override
  String get rigPortsTooltipHost => 'اس ٹرمینل میں کھلے پورٹس';

  @override
  String get rigPortsEmptyHost =>
      'اس ٹرمینل میں ابھی کچھ سن نہیں رہا۔ سرور چلائیں تو یہاں دکھائی دے گا۔';

  @override
  String get rigPortsAddHintHost => 'میپ کرنے کا پورٹ (مثلاً 5173)';

  @override
  String get rigPortsLocalPortHint => 'مقامی پورٹ (اختیاری)';

  @override
  String rigPortsDestDesktop(int port) {
    return 'localhost:$port';
  }

  @override
  String rigPortsDestBrowser(int port) {
    return 'localhost:$port براؤزر میں (وی ایم)';
  }

  @override
  String get rigPortsDestBrowserUnreachable => 'براؤزر (وی ایم) منسلک نہیں';

  @override
  String rigPortsDestAndroid(int port) {
    return 'localhost:$port اینڈرائیڈ پر';
  }

  @override
  String get rigPortsDestAndroidUnreachable => 'اینڈرائیڈ منسلک نہیں';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بیس امیجز ابھی ڈاؤن لوڈ کرنی ہیں',
      one: '1 بیس امیج ابھی ڈاؤن لوڈ کرنی ہے',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => 'اجازت دیں';

  @override
  String get guardrailDecisionPrompt => 'پہلے پوچھیں';

  @override
  String get guardrailDecisionDeny => 'منع کریں';

  @override
  String get guardrailSourceThisScope => 'یہ دائرہ';

  @override
  String get guardrailSourceDefault => 'بلٹ اِن ڈیفالٹ';

  @override
  String get guardrailSourcePreset => 'موڈ پری سیٹ';

  @override
  String get guardrailSourceInherited => 'وراثت میں ملا';

  @override
  String get guardrailClearToInherited => 'وراثت پر صاف کریں';

  @override
  String get guardrailWhatIf => 'اگر؟';

  @override
  String get guardrailWhatIfDescription =>
      'دیکھیں کہ موجودہ قواعد کسی ایکشن کو کیسے حل کریں گے، وہی منطق جو ایجنٹ چلاتے ہیں۔';

  @override
  String get guardrailProbeActionLabel => 'ایکشن';

  @override
  String get guardrailProbeCommandLabel => 'کمانڈ (اختیاری)';

  @override
  String get guardrailProbeCommandHint => 'مثال: ⁨git push origin main⁩';

  @override
  String get guardrailProbeAgentLabel => 'ایجنٹ (اختیاری)';

  @override
  String get guardrailProbeSpaceLabel => 'اسپیس (اختیاری)';

  @override
  String get guardrailProbeNone => 'کوئی نہیں';

  @override
  String get guardrailProbeModeLabel => 'موڈ';

  @override
  String get guardrailProbeResult => 'نتیجہ';

  @override
  String get guardrailProbeSource => 'ماخذ:';

  @override
  String get guardrailAdapterMatrix => 'قواعد کہاں نافذ ہوتے ہیں';

  @override
  String get guardrailAdapterMatrixDescription =>
      'ایماندار حوالہ: ہر اثر اصل میں کہاں پکڑا جاتا ہے، فی ایجنٹ رنر۔ یہ حقیقت بیان کرتا ہے، ضمانت نہیں — جو اثر رنر بینڈ سے باہر کرے اسے روکا نہیں جا سکتا۔';

  @override
  String get guardrailEffectColumn => 'اثر';

  @override
  String get guardrailAdapterHarness => 'بلٹ اِن ہارنس';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => 'سینڈ باکس فلور';

  @override
  String get guardrailEnforcementPolicyGate => 'پالیسی گیٹ';

  @override
  String get guardrailEnforcementSandbox => 'صرف سینڈ باکس';

  @override
  String get guardrailEnforcementNone => 'نافذ نہیں ہو سکتا';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      'اثر چلنے سے پہلے اجازت کا فیصلہ چیک ہوتا ہے اور اسے روک سکتا ہے۔';

  @override
  String get guardrailEnforcementSandboxHelp =>
      'صرف سینڈ باکس اسے محدود کرتا ہے؛ اجازت کا قاعدہ نہیں دیکھا جاتا۔';

  @override
  String get guardrailEnforcementNoneHelp =>
      'فیصلہ صرف مشورہ ہے — یہاں اسے روکا نہیں جا سکتا۔';

  @override
  String get obsStatCost => 'لاگت';

  @override
  String obsStatDelegatedCost(String amount) {
    return '⁨+$amount⁩ تفویض شدہ';
  }

  @override
  String get obsStatDuration => 'مدت';

  @override
  String get obsStatTokens => 'ٹوکنز';

  @override
  String get obsStatTools => 'ٹولز';

  @override
  String get openAgentActivity => 'سرگرمی کھولیں';

  @override
  String get orgChart => 'آرگ چارٹ';

  @override
  String get orgChartEmpty => 'ابھی کوئی ایجنٹ نہیں';

  @override
  String get navCalendar => 'کیلنڈر';

  @override
  String get serverConnection => 'سرور کنکشن';

  @override
  String get serverModeLocal => 'اس ایپ میں چلائیں';

  @override
  String get serverModeLocalDescription =>
      'Control Center اس مشین پر اپنا سرور چلاتا ہے اور آپ کا ڈیٹا مقامی طور پر رکھتا ہے۔';

  @override
  String get serverRemoteUrl => 'سرور URL';

  @override
  String get serverRemoteDeviceId => 'ڈیوائس ID';

  @override
  String get serverRemotePairingKey => 'پیئرنگ کلید';

  @override
  String get serverRemotePairingKeyHint =>
      'ریموٹ سرور سے پیئرنگ کلید پیسٹ کریں';

  @override
  String get serverSetupInviteCode => 'دعوتی کوڈ';

  @override
  String get serverSetupInviteCodeHint =>
      'ایک بار استعمال ہونے والا دعوتی کوڈ پیسٹ کریں (پیئرنگ کلید کے لیے خالی چھوڑیں)';

  @override
  String get serverDiscoveryTooltip => 'اپنے نیٹ ورک پر سرور تلاش کریں';

  @override
  String get serverDiscoveryTitle => 'آپ کے نیٹ ورک پر سرورز';

  @override
  String get serverDiscoverySearching => 'سرورز تلاش ہو رہے ہیں…';

  @override
  String get serverDiscoveryEmpty =>
      'کوئی سرور نہیں ملا۔ چیک کریں کہ سرور چل رہا ہے اور یہ ڈیوائس اسے پہنچ سکتی ہے، پھر دوبارہ تلاش کریں۔';

  @override
  String get serverDiscoveryRefresh => 'دوبارہ تلاش کریں';

  @override
  String get serverListActive => 'فعال';

  @override
  String get serverListSwitch => 'تبدیل کریں';

  @override
  String get serverListAddTitle => 'سرور شامل کریں';

  @override
  String get serverListRemoveActiveHint =>
      'اسے ہٹانے سے پہلے دوسرے سرور پر سوئچ کریں۔';

  @override
  String get serverSwitchFailedTitle => 'سرور تبدیل نہیں ہو سکا';

  @override
  String get serverListInsecureBadge => 'غیر محفوظ';

  @override
  String get connectionPathLocal => 'مقامی';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => 'بند ہو رہا ہے';

  @override
  String get shutdownSubtitle => 'مقامی سرور بند ہو رہا ہے';

  @override
  String get shutdownServiceApprovals => 'منظوریاں';

  @override
  String get shutdownServiceBackgroundJobs => 'پس منظر جابز';

  @override
  String get shutdownServiceScheduler => 'جاب شیڈیولر';

  @override
  String get shutdownServiceCalendar => 'کیلنڈر سنک';

  @override
  String get shutdownServiceWeather => 'موسم';

  @override
  String get shutdownServiceSoundscape => 'ساؤنڈ اسکیپ';

  @override
  String get shutdownServiceMeetings => 'میٹنگز';

  @override
  String get shutdownServiceVoiceModels => 'وائس ماڈلز';

  @override
  String get shutdownServiceNetworking => 'نیٹ ورکنگ';

  @override
  String get shutdownServicePresence => 'موجودگی';

  @override
  String get shutdownServiceDataSync => 'ڈیٹا سنک';

  @override
  String get shutdownServiceDeviceRelay => 'ڈیوائس ریلے';

  @override
  String get shutdownServiceMcpConnections => 'MCP کنکشنز';

  @override
  String get shutdownServiceCodeEditors => 'کوڈ ایڈیٹرز';

  @override
  String get serverSharingTitle => 'یہ سرور شیئر کریں';

  @override
  String get serverSharingDescription =>
      'اس سرور کو اپنی دوسری ڈیوائسز سے پہنچنے کے قابل بنائیں۔ نیچے ٹنل آن کیے بغیر کچھ پبلک نہیں ہوتا۔ پیئرنگ دعوتیں سرور کے موجودہ ایڈریس خود شامل کرتی ہیں — انہیں ورک اسپیس ترتیبات میں بنائیں۔';

  @override
  String get serverSharingUnavailable =>
      'اس سرور پر شیئرنگ کنٹرولز دستیاب نہیں۔';

  @override
  String get serverSharingMdnsLabel => 'LAN دریافت';

  @override
  String get serverSharingMdnsOn =>
      'اس سرور کو مقامی نیٹ ورک پر اشتہار دیا جا رہا ہے (mDNS)';

  @override
  String get serverSharingMdnsOff => 'مقامی نیٹ ورک پر اشتہار نہیں (mDNS)';

  @override
  String get serverSharingTunnelLabel => 'ٹنل';

  @override
  String get serverSharingTunnelHelper =>
      'ٹنل آن کرنے سے یہ سرور انٹرنیٹ سے پہنچنے کے قابل ہو جاتا ہے۔ پبلک نمائش اختیاری ہے اور ڈیفالٹ آف ہے۔';

  @override
  String get serverSharingProviderOff => 'آف';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => 'پبلک URL';

  @override
  String get serverSharingTunnelStarting => 'ٹنل شروع ہو رہی ہے…';

  @override
  String serverSharingTunnelError(String error) {
    return 'ٹنل خرابی: ⁨$error⁩';
  }

  @override
  String get serverSharingTunnelUpNoUrl =>
      'ٹنل چل رہی ہے۔ اپنے کنفیگرڈ DNS ہوسٹ نیم پر پہنچیں۔';

  @override
  String get serverSharingRelayLabel => 'ریلے';

  @override
  String serverSharingRelayUsage(String amount) {
    return 'اس مہینے ریلے ہوا: ⁨$amount⁩';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return 'فعال ریلے سیشنز: $count';
  }

  @override
  String get serverSharingUpdateFailedTitle => 'شیئرنگ اپ ڈیٹ نہیں ہو سکی';

  @override
  String get pairNewClient => 'نیا کلائنٹ پیئر کریں';

  @override
  String get pairClientNameHint => 'اس کلائنٹ کا لیبل (مثلاً ورک لیپ ٹاپ)';

  @override
  String get pairClientTypeWeb => 'ویب براؤزر';

  @override
  String get pairClientTypeDesktop => 'ڈیسک ٹاپ ایپ';

  @override
  String get pairClientTypePhone => 'فون';

  @override
  String get pairAction => 'پیئر کریں';

  @override
  String get revoke => 'منسوخ کریں';

  @override
  String get pairCredentialsIntro =>
      'نئے کلائنٹ کو ان تفصیلات سے منسلک کریں، یا اس میں لنک کھولیں۔';

  @override
  String get pairLinkLabel => 'لنک';

  @override
  String get pairScanQr =>
      'پیئر کرنے کے لیے اپنے فون کے کیمرے سے یہ QR کوڈ اسکین کریں۔';

  @override
  String get pairServerUnreachableTitle => 'پہنچ سے باہر';

  @override
  String get pairServerUnreachable =>
      'دوسری ڈیوائسز اس سرور تک براہِ راست نہیں پہنچ سکتیں، اس لیے نیا کلائنٹ منسلک نہیں ہو سکتا۔ مزید کلائنٹس پیئر کرنے کے لیے سرور کا پبلک URL سیٹ کریں۔';

  @override
  String get serverSetupRunLocal => 'اس ایپ میں چلائیں';

  @override
  String get serverSetupConnect => 'منسلک ہوں';

  @override
  String get serverSetupInvalidUrl =>
      'درست ⁨ws://⁩ یا ⁨wss://⁩ سرور URL درج کریں۔';

  @override
  String get serverSetupCouldNotConnect => 'منسلک نہیں ہو سکا';

  @override
  String get serverSetupErrorUnreachable =>
      'سرور تک نہیں پہنچ سکے۔ چیک کریں کہ یہ چل رہا ہے اور یہ ڈیوائس اسے پہنچ سکتی ہے (وہی نیٹ ورک یا ریلے)۔';

  @override
  String get serverSetupErrorIdentityMismatch =>
      'سرور کی شناخت اس ڈیوائس پر محفوظ شناخت سے میل نہیں کھاتی۔ اگر سرور دوبارہ انسٹال یا ری سیٹ ہوا ہو تو محفوظ سرور ہٹا کر دوبارہ پیئر کریں۔';

  @override
  String get serverSetupErrorAuthRejected =>
      'سرور نے اس ڈیوائس کو مسترد کر دیا۔ چیک کریں کہ پیئرنگ کلید اور ڈیوائس ID وہی ہیں جو سرور نے جاری کیے۔';

  @override
  String get serverSetupErrorInviteRejected =>
      'وہ دعوتی کوڈ غلط ہے یا ختم ہو گیا ہے۔ نیا مانگیں۔';

  @override
  String get serverSetupErrorGeneric =>
      'منسلک ہوتے ہوئے کچھ غلط ہو گیا۔ مزید معلومات کے لیے نیچے تکنیکی تفصیلات پھیلائیں۔';

  @override
  String get serverSetupErrorDetails => 'تکنیکی تفصیلات';

  @override
  String get serverActivityTitle => 'سرور کی سرگرمی';

  @override
  String get serverActivityStarting => 'مقامی سرور شروع ہو رہا ہے…';

  @override
  String get serverActivityConnecting => 'سرور سے منسلک ہو رہا ہے…';

  @override
  String get serverActivityStartFailed => 'سرور شروع نہیں ہو سکا';

  @override
  String get serverActivityDownloadFailed => 'ڈاؤن لوڈ ناکام رہا';

  @override
  String get serverActivityStatusUnavailable => 'ماڈل کی حالت نہیں پڑھی جا سکی';

  @override
  String get serverActivityPreparingModel => 'ماڈل تیار ہو رہا ہے…';

  @override
  String get serverActivityPortInUse =>
      'سرور کا پورٹ پہلے سے استعمال میں ہے۔ دوسرا عمل بند کریں یا سرور پر کوئی اور پورٹ منتخب کریں۔';

  @override
  String get serverActivityStartFailedHint =>
      'تکنیکی تفصیلات دیکھیں، پھر سرور کی ترتیب سے دوبارہ کوشش کریں۔';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مزید',
      one: '1 مزید',
    );
    return '$_temp0';
  }

  @override
  String calendarAllDayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ایونٹس',
      one: '1 ایونٹ',
    );
    return '$_temp0';
  }

  @override
  String get calendarCollapseAllDay => 'پورے دن کے ایونٹس سکیڑیں';

  @override
  String get calendarExpandAllDay => 'پورے دن کے ایونٹس پھیلائیں';

  @override
  String get calendarViewMonth => 'مہینہ';

  @override
  String get calendarViewWeek => 'ہفتہ';

  @override
  String get calendarViewAgenda => 'ایجنڈا';

  @override
  String get calendarConnectGoogle => 'Google Calendar منسلک کریں';

  @override
  String get calendarConnectDescription =>
      'اپنا Google Calendar سنک کریں تاکہ ایونٹس یہاں دیکھیں اور میٹنگز سے پہلے الرٹ ملیں۔';

  @override
  String get calendarDisconnect => 'منقطع کریں';

  @override
  String get calendarReconnect => 'دوبارہ منسلک کریں';

  @override
  String get calendarEmptyNoEvents => 'اس رینج میں کوئی ایونٹ نہیں';

  @override
  String get calendarStartRecording => 'ریکارڈنگ شروع کریں';

  @override
  String get calendarStartRecordingAndLink => 'ریکارڈنگ شروع کریں اور لنک کریں';

  @override
  String get calendarJoinMeet => 'میٹنگ میں شامل ہوں';

  @override
  String get calendarFromCalendar => 'کیلنڈر سے';

  @override
  String get calendarLinkedMeeting => 'لنک شدہ میٹنگ';

  @override
  String get calendarToday => 'آج';

  @override
  String get calendarAllDay => 'پورے دن';

  @override
  String calendarWeekNumber(int number) {
    return 'ہفتہ $number';
  }

  @override
  String get calendarPreviousPeriod => 'پچھلا';

  @override
  String get calendarNextPeriod => 'اگلا';

  @override
  String calendarLastSynced(String time) {
    return '$time سنک ہوا';
  }

  @override
  String get calendarNeverSynced => 'ابھی سنک نہیں ہوا';

  @override
  String get calendarSyncing => 'سنک ہو رہا ہے…';

  @override
  String get calendarViewDay => 'دن';

  @override
  String get calendarShow => 'دکھائیں';

  @override
  String get calendarHide => 'چھپائیں';

  @override
  String get calendarRsvpGoing => 'جائیں گے؟';

  @override
  String get calendarRsvpYes => 'ہاں';

  @override
  String get calendarRsvpNo => 'نہیں';

  @override
  String get calendarRsvpMaybe => 'شاید';

  @override
  String get calendarRsvpFailed => 'آپ کا جواب اپ ڈیٹ نہیں ہو سکا';

  @override
  String get calendarNewEvent => 'نیا ایونٹ';

  @override
  String get calendarComposerTitleHint => 'عنوان شامل کریں';

  @override
  String get calendarComposerStarts => 'شروع';

  @override
  String get calendarComposerEnds => 'ختم';

  @override
  String get calendarComposerDate => 'تاریخ';

  @override
  String get calendarComposerEndDate => 'آخری دن';

  @override
  String get calendarComposerGuestsHint => 'ای میل کے ذریعے مہمان شامل کریں';

  @override
  String get calendarComposerMeet => 'Google Meet لنک شامل کریں';

  @override
  String get calendarComposerLocationHint => 'مقام شامل کریں';

  @override
  String get calendarComposerDescriptionHint => 'تفصیل شامل کریں';

  @override
  String get calendarComposerCalendar => 'کیلنڈر';

  @override
  String get calendarComposerTitleRequired =>
      'ایونٹ محفوظ کرنے کے لیے عنوان شامل کریں';

  @override
  String get calendarComposerInvalidGuests =>
      'مہمانوں کی ای میلز میں سے ایک درست نہیں ہے';

  @override
  String get calendarComposerEndBeforeStart =>
      'ایونٹ کا شروع ہونے کے بعد ختم ہونا ضروری ہے';

  @override
  String get calendarComposerSaveFailed =>
      'ایونٹ نہیں بن سکا۔ دوبارہ کوشش کریں۔';

  @override
  String get calendarComposerGuestsNotified =>
      'مہمانوں کو Google کی طرف سے ای میل دعوت ملتی ہے۔';

  @override
  String get calendarDeleteEvent => 'ایونٹ حذف کریں';

  @override
  String calendarDeleteConfirmTitle(String title) {
    return '“$title” حذف کریں؟';
  }

  @override
  String get calendarDeleteConfirmBody =>
      'یہ Google Calendar سے ہٹا دیا جاتا ہے۔';

  @override
  String get calendarDeleteConfirmGuests =>
      'یہ Google Calendar سے ہٹا دیا جاتا ہے، اور ہر مہمان کو اس کے منسوخ ہونے کی اطلاع دی جاتی ہے۔';

  @override
  String get calendarDeleteConfirmInvite =>
      'یہ صرف آپ کے کیلنڈر سے ہٹتا ہے۔ منتظم اور دوسرے مہمان اسے برقرار رکھتے ہیں۔';

  @override
  String get calendarDeleteConfirmRecurring =>
      'صرف یہ واقعہ حذف ہوگا؛ باقی سلسلہ برقرار رہے گا۔';

  @override
  String get calendarDeleteFailed => 'ایونٹ حذف نہیں ہو سکا۔ دوبارہ کوشش کریں۔';

  @override
  String get calendarMoveFailed =>
      'ایونٹ منتقل نہیں ہو سکا۔ یہ دوبارہ اپنی پرانی جگہ پر چلا گیا۔';

  @override
  String get activityCreatedCalendarEvent => 'کیلنڈر ایونٹ بنایا';

  @override
  String get activityMovedCalendarEvent => 'کیلنڈر ایونٹ منتقل کیا';

  @override
  String get activityDeletedCalendarEvent => 'کیلنڈر ایونٹ حذف کیا';

  @override
  String get calendarAddAccount => 'کیلنڈر اکاؤنٹ شامل کریں';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'اس ورک اسپیس میں ایونٹس ہم آہنگ کرنے کے لیے Google اکاؤنٹ جوڑیں۔ یہ کیلنڈرز یہاں آپ کے ہیں۔';

  @override
  String get calendarSyncNow => 'اب سنک کریں';

  @override
  String get calendarNoWorkspace =>
      'اس کا کیلنڈر دیکھنے کے لیے ورک اسپیس منتخب کریں';

  @override
  String get calendarConnectError => 'Google Calendar منسلک نہیں ہو سکا';

  @override
  String get notificationMeetingStartsSoon => 'میٹنگ جلد شروع ہو رہی ہے';

  @override
  String get notifyMeetingStartsSoon => 'جب کیلنڈر میٹنگ شروع ہونے والی ہو';

  @override
  String get notificationCalendarAuthExpiredTitle => 'کیلنڈر منقطع ہو گیا';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'سنک دوبارہ شروع کرنے کے لیے ⁨$email⁩ دوبارہ منسلک کریں';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'سنک دوبارہ شروع کرنے کے لیے اپنا کیلنڈر دوبارہ منسلک کریں';

  @override
  String get notifyCalendarAuthExpired =>
      'جب کیلنڈر اکاؤنٹ دوبارہ منسلک کرنا ہو';

  @override
  String get notificationRigStatusChanged => 'انکلوژر اپ ڈیٹس';

  @override
  String get notifyRigStatusChanged =>
      'جب انکلوژر لیا جائے، واپس لیا جائے یا ناکام ہو';

  @override
  String get notificationRigTakenOver => 'انکلوژر لیا گیا';

  @override
  String get notificationRigTakenOverBody =>
      'ایک شخص مشین چلا رہا ہے؛ ایجنٹ دیکھ سکتا ہے مگر عمل نہیں کر سکتا۔';

  @override
  String get notificationRigReleased => 'انکلوژر کنٹرول چھوڑ دیا گیا';

  @override
  String get notificationRigReleasedBody => 'ایجنٹ کے پاس مشین واپس آ گئی۔';

  @override
  String get notificationRigReclaimed => 'انکلوژر واپس لیا گیا';

  @override
  String get notificationRigReclaimedBodyIdle =>
      'یہ بیکار بیٹھا رہا، اس لیے میموری خالی کرنے کے لیے مشین بند کر دی گئی۔';

  @override
  String get notificationRigReclaimedBodyTtl =>
      'وقت کی حد پوری ہو گئی اور اسے بند کر دیا گیا۔';

  @override
  String get notificationRigFailed => 'انکلوژر ناکام';

  @override
  String get notificationRigFailedBody =>
      'اس کے نیچے hypervisor ختم ہو گیا۔ جاری رکھنے کے لیے مشین دوبارہ کھولیں۔';

  @override
  String get calendarAlertLeadTime => 'الرٹ لیڈ ٹائم';

  @override
  String get calendarAlertLeadTimeSubtitle => 'میٹنگ سے کتنی دیر پہلے الرٹ دیں';

  @override
  String calendarConnectedAs(String email) {
    return '⁨$email⁩ کے طور پر منسلک';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count حاضرین';
  }

  @override
  String get calendarEventLabel => 'ایونٹ';

  @override
  String get calendarRecurring => 'بار بار ہونے والا ایونٹ';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'منظم';

  @override
  String get calendarYou => 'آپ';

  @override
  String get calendarShowFewer => 'کم دکھائیں';

  @override
  String get calendarRsvpAwaiting => 'انتظار میں';

  @override
  String calendarParticipantsCount(int count) {
    return '$count شرکاء';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'تمام $count شرکاء دیکھیں';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count ہاں';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count نہیں';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count شاید';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count انتظار میں';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count منٹ';
  }

  @override
  String get openInEditorPrompt => 'کس ایڈیٹر میں کھولیں؟';

  @override
  String get ideNotInstalled => 'انسٹال نہیں';

  @override
  String openInIde(String editor) {
    return '⁨$editor⁩ میں کھولیں';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return '⁨$editor⁩ نہیں کھل سکا: ⁨$error⁩';
  }

  @override
  String get profileSearchHint => 'pull requests تلاش کریں…';

  @override
  String get stopAgentRun => 'رن روکیں';

  @override
  String get stopAgentRunConfirm => 'یہ رن روکیں؟ جاری کام ضائع ہو جائے گا۔';

  @override
  String get inProgress => 'جاری';

  @override
  String get drafts => 'ڈرافٹس';

  @override
  String get sortOldest => 'قدیم ترین';

  @override
  String get sortLargest => 'سب سے بڑا';

  @override
  String get prFilterTooltip => 'فلٹر';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فعال فلٹرز',
      one: '1 فعال فلٹر',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => 'فلٹر شامل کریں…';

  @override
  String get prFilterFieldHint => 'فلٹر…';

  @override
  String get prFilterCategoryStatus => 'اسٹیٹس';

  @override
  String get prFilterCategoryAuthor => 'مصنف';

  @override
  String get prFilterCategoryReviewer => 'ریویوورز';

  @override
  String get prFilterCategoryContent => 'مواد';

  @override
  String get prFilterCategoryRepoOwner => 'ریپوزٹری مالک';

  @override
  String get prFilterCategoryRepoName => 'ریپوزٹری نام';

  @override
  String get prFilterCategoryOpenedDate => 'کھلنے کی تاریخ';

  @override
  String get prFilterCategoryUpdatedDate => 'اپ ڈیٹ کی تاریخ';

  @override
  String get prFilterQuickToReview => 'جلدی ریویو';

  @override
  String get prFilterClearAll => 'فلٹرز صاف کریں';

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
      other: '$count آپشنز کسی pull request سے میل نہیں کھاتے',
      one: '1 آپشن کسی pull request سے میل نہیں کھاتا',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => 'عنوان یا باڈی میں…';

  @override
  String get prFilterNoOptions => 'کوئی مماثل آپشن نہیں';

  @override
  String get prFilterChipIs => 'ہے';

  @override
  String get prFilterChipIsAnyOf => 'ان میں سے کوئی';

  @override
  String get prFilterChipContains => 'شامل ہے';

  @override
  String get prFilterChipSince => 'سے';

  @override
  String get prFilterAddFilterButton => 'فلٹر شامل کریں';

  @override
  String prFilterClearCategory(String category) {
    return '⁨$category⁩ فلٹر صاف کریں';
  }

  @override
  String get prFilterCurrentUser => 'موجودہ صارف';

  @override
  String get prStatusDraft => 'ڈرافٹ';

  @override
  String get prStatusOpen => 'کھلا';

  @override
  String get prStatusInReview => 'ریویو میں';

  @override
  String get prStatusChangesRequested => 'تبدیلیاں مانگی گئیں';

  @override
  String get prStatusApproved => 'منظور';

  @override
  String get prStatusMerged => 'مرج شدہ';

  @override
  String get prStatusClosed => 'بند';

  @override
  String get prDateWindowDay => '1 دن پہلے';

  @override
  String get prDateWindowThreeDays => '3 دن پہلے';

  @override
  String get prDateWindowWeek => '1 ہفتہ پہلے';

  @override
  String get prDateWindowMonth => '1 مہینہ پہلے';

  @override
  String get prDateWindowThreeMonths => '3 مہینے پہلے';

  @override
  String get prDateWindowSixMonths => '6 مہینے پہلے';

  @override
  String get prDateWindowYear => '1 سال پہلے';

  @override
  String get prDisplayOptions => 'ڈسپلے آپشنز';

  @override
  String get prDisplayGrouping => 'گروپنگ';

  @override
  String get prDisplayOrdering => 'ترتیب';

  @override
  String get prDisplayShowDrafts => 'ڈرافٹس دکھائیں';

  @override
  String get prDisplayMergedWindow => 'مرج ونڈو';

  @override
  String get prDisplayMergedWindowDay => 'گزشتہ دن';

  @override
  String get prDisplayMergedWindowWeek => 'گزشتہ ہفتہ';

  @override
  String get prDisplayMergedWindowMonth => 'گزشتہ مہینہ';

  @override
  String get prDisplayProperties => 'ڈسپلے پراپرٹیز';

  @override
  String get prGroupingRepository => 'ریپوزٹری';

  @override
  String get prGroupingAuthor => 'مصنف';

  @override
  String get prGroupingStatus => 'اسٹیٹس';

  @override
  String get prGroupingNone => 'کوئی گروپنگ نہیں';

  @override
  String get prPropertyRepository => 'ریپوزٹری';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => 'برانچ';

  @override
  String get prPropertyUpdated => 'اپ ڈیٹ شدہ';

  @override
  String get prPropertyAuthor => 'مصنف';

  @override
  String get prPropertyChecks => 'چیکس';

  @override
  String get prPropertyDiff => 'Diff';

  @override
  String get prPropertyComments => 'تبصرے';

  @override
  String get keybindingOpenFilterMenu => 'فلٹر مینو کھولیں';

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count منتخب',
      one: '1 منتخب',
    );
    return '$_temp0';
  }

  @override
  String get summary => 'خلاصہ';

  @override
  String get kbMove => 'منتقل';

  @override
  String get kbTabs => 'ٹیبز';

  @override
  String get kbSearch => 'تلاش';

  @override
  String get kbViewed => 'دیکھا گیا';

  @override
  String get kbCollapse => 'سکیڑیں';

  @override
  String get appearance => 'ظاہری شکل';

  @override
  String get appearanceSettingsDescription => 'تھیم، زبان اور ٹائپوگرافی۔';

  @override
  String get notificationsSettingsDescription =>
      'منتخب کریں کہ کون سے ایجنٹ اور ورک اسپیس ایونٹس آپ کو مطلع کریں۔';

  @override
  String get advanced => 'اعلیٰ';

  @override
  String get accounts => 'اکاؤنٹس';

  @override
  String get mcpServers => 'MCP سرورز';

  @override
  String get mcpServersSettingsDescription =>
      'بلٹ اِن MCP سرور اور بیرونی MCP سرورز۔';

  @override
  String get remoteControlAndDevices => 'ریموٹ کنٹرول اور ڈیوائسز';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'فونز پیئر کریں اور ریموٹ کنٹرول سرور کنفیگر کریں۔';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'اس سرور کے اسپیچ اور ڈائرائزیشن ماڈلز۔';

  @override
  String get needsSetupLabel => 'سیٹ اپ درکار';

  @override
  String get collapseSidebar => 'سائڈ بار سکیڑیں';

  @override
  String get expandSidebar => 'سائڈ بار پھیلائیں';

  @override
  String get filterSpacesHint => 'اسپیسز فلٹر کریں';

  @override
  String noSpacesMatch(String query) {
    return 'کوئی اسپیس \"⁨$query⁩\" سے میل نہیں کھاتی';
  }

  @override
  String get privacy => 'پرائیویسی';

  @override
  String get sendDiffContentTitle => 'Diff مواد AI اڈاپٹر کو بھیجیں';

  @override
  String get diffSharingOnSubtitle =>
      'گہری ریویو کے لیے خام diff لائنز ایجنٹ پرامپٹس میں شامل ہوتی ہیں۔';

  @override
  String get diffSharingOffSubtitle =>
      'ایجنٹ صرف ساختی میٹا ڈیٹا استعمال کرتے ہیں (فائل پاتھ، لائن نمبرز، PR تفصیل)؛ کوئی خام کوڈ ایپ سے باہر نہیں جاتا۔';

  @override
  String get errorReportingTitle => 'کریش رپورٹس شیئر کریں';

  @override
  String get errorReportingOnSubtitle =>
      'بگز ٹھیک کرنے میں مدد کے لیے کریش، خرابی اور پرفارمنس تشخیص بھیجے جاتے ہیں (صرف ریلیز بلڈز)۔';

  @override
  String get errorReportingOffSubtitle =>
      'تشخیص بند ہے۔ کوئی کریش یا خرابی کی رپورٹ نہیں بھیجی جاتی۔';

  @override
  String get onboardingDiagnosticsTitle =>
      'Control Center بہتر بنانے میں مدد کریں';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'کریش، خرابی اور پرفارمنس تشخیص بھیجیں تاکہ مسائل تیزی سے ٹھیک ہوں (صرف ریلیز بلڈز)۔ آپ یہ کسی بھی وقت ترتیبات ← پرائیویسی میں بدل سکتے ہیں۔';

  @override
  String get usageAnalyticsTitle => 'استعمال کے تجزیات شیئر کریں';

  @override
  String get usageAnalyticsOnSubtitle =>
      'اس سرور کے تمام کلائنٹس فرضی شناخت والے استعمال کے واقعات (اسکرینز، کارروائیاں، گنتیاں) بھیجتے ہیں، صرف ریلیز بلڈز میں۔ نام، پیغام کا مواد، فائل پاتھ یا ای میل پتے کبھی نہیں بھیجے جاتے۔';

  @override
  String get usageAnalyticsOffSubtitle =>
      'استعمال کے تجزیات بند ہیں۔ اس سرور کا کوئی کلائنٹ استعمال کے واقعات نہیں بھیجتا۔';

  @override
  String get usageAnalyticsManagedOnSubtitle =>
      'اس سرور کے کلائنٹس فرضی شناخت والے استعمال کے واقعات بھیجتے ہیں۔ اسے صرف سرور آپریٹر بدل سکتا ہے۔';

  @override
  String get usageAnalyticsManagedOffSubtitle =>
      'اس سرور پر استعمال کے تجزیات بند ہیں۔ اسے صرف سرور آپریٹر بدل سکتا ہے۔';

  @override
  String get onboardingUsageAnalyticsSubtitle =>
      'اس سرور کے تمام کلائنٹس سے فرضی شناخت والے استعمال کے واقعات بھیجیں تاکہ ہم جان سکیں کہ کون سی خصوصیات مددگار ہیں (صرف ریلیز بلڈز)۔ نام، پیغام کا مواد، فائل پاتھ یا ای میل پتے کبھی نہیں بھیجے جاتے۔ آپ یہ کسی بھی وقت ترتیبات ← پرائیویسی میں بدل سکتے ہیں۔';

  @override
  String get blocked => 'بلاک';

  @override
  String get idle => 'بیکار';

  @override
  String get noRunsYet => 'ابھی کوئی رن نہیں';

  @override
  String get copyPath => 'پاتھ کاپی کریں';

  @override
  String get copyRelativePath => 'نسبتی پاتھ کاپی کریں';

  @override
  String get nameRequired => 'نام ضروری ہے';

  @override
  String get import => 'درآمد';

  @override
  String get noMatchingAgents => 'آپ کے فلٹر سے کوئی ایجنٹ میل نہیں کھاتا';

  @override
  String watchVideoOn(String provider) {
    return 'ویڈیو ⁨$provider⁩ پر دیکھیں';
  }

  @override
  String get branchTemplate => 'برانچ نام ٹیمپلیٹ';

  @override
  String get branchTemplateDescription =>
      'الگ worktree میں ٹکٹ شروع ہونے پر بننے والی برانچ کا پیٹرن۔';

  @override
  String branchTemplatePreview(String example) {
    return 'مثال: ⁨$example⁩';
  }

  @override
  String get deletePipelineRun => 'پائپ لائن رن حذف کریں';

  @override
  String deletePipelineRunConfirm(String template) {
    return '\"⁨$template⁩\" کا یہ رن حذف کریں؟ یہ واپس نہیں ہو سکتا۔';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'پائپ لائن رن حذف کرتے ہوئے خرابی: ⁨$error⁩';
  }

  @override
  String get deleteTicket => 'ٹکٹ حذف کریں';

  @override
  String deleteTicketConfirm(String title) {
    return '\"⁨$title⁩\" حذف کریں؟ یہ واپس نہیں ہو سکتا۔';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'ٹکٹ حذف کرتے ہوئے خرابی: ⁨$error⁩';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return '\"⁨$name⁩\" حذف کریں؟ ڈسک پر لنک شدہ ریپوزٹریز نہیں چھوتے۔';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'ورک اسپیس حذف کرتے ہوئے خرابی: ⁨$error⁩';
  }

  @override
  String get indexCode => 'کوڈ انڈیکس کریں';

  @override
  String get indexNoGrammars => 'کوڈ گرامرز انسٹال نہیں';

  @override
  String get indexFailed => 'انڈیکسنگ ناکام';

  @override
  String indexedSymbolsCount(int count) {
    return '$count سمبلز انڈیکس ہوئے';
  }

  @override
  String get nodeConfigAdvanced => 'اعلیٰ';

  @override
  String get nodeConfigReducer => 'ریڈیوسر';

  @override
  String get nodeConfigReducerHelp =>
      'جب اس آؤٹ پٹ کلید کی پہلے سے ویلیو ہو تو کیسے مرج کریں';

  @override
  String get nodeConfigTimeoutMs => 'ٹائم آؤٹ (ms)';

  @override
  String get nodeConfigRetryAttempts => 'دوبارہ کوششیں';

  @override
  String get nodeConfigContinueOnFail => 'اگر یہ مرحلہ ناکام ہو تو جاری رکھیں';

  @override
  String get nodeConfigTeamId => 'Team ID';

  @override
  String get nodeConfigDispatchMode => 'ڈسپیچ موڈ';

  @override
  String get nodeConfigOutputSchema => 'آؤٹ پٹ اسکیما (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'JSON Schema جسے مرحلے کے آؤٹ پٹ کو پورا کرنا چاہیے';

  @override
  String get nodeConfigBackupRetentionDays =>
      'اتنے دن سے پرانے بیک اپ حذف کریں';

  @override
  String get nodeConfigBackupRetentionDaysHelp =>
      'صرف اسی ورک اسپیس کے بیک اپ حذف ہوں گے۔ دنوں کی مثبت تعداد درج کریں۔';

  @override
  String get diffLineDisplay => 'Diff میں لمبی لائنیں';

  @override
  String get diffLineDisplayDescription =>
      'لمبی لائنیں لپیٹیں یا افقی سکرول کریں';

  @override
  String get diffLineWrap => 'لپیٹیں';

  @override
  String get diffLineScroll => 'افقی سکرول';

  @override
  String get actions => 'ایکشنز';

  @override
  String get activate => 'فعال کریں';

  @override
  String get activity => 'سرگرمی';

  @override
  String get activityLabel => 'سرگرمی';

  @override
  String get activitySearchHint => 'سرگرمی تلاش کریں';

  @override
  String get activityNoMatches => 'آپ کے فلٹرز سے کوئی سرگرمی میل نہیں کھاتی';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$start–$end از $total';
  }

  @override
  String get activityPreviousPage => 'پچھلا صفحہ';

  @override
  String get activityNextPage => 'اگلا صفحہ';

  @override
  String get activityNetworkLocal => 'Localhost';

  @override
  String get activityClearFilter => 'فلٹر صاف کریں';

  @override
  String activityFilterIp(String ip) {
    return 'IP ⁨$ip⁩';
  }

  @override
  String activityFilterCountry(String country) {
    return 'ملک ⁨$country⁩';
  }

  @override
  String get activitySavedWorkspaceLogo => 'ورک اسپیس لوگو محفوظ ہو گیا';

  @override
  String activityVerbCreated(String target) {
    return '$target بنایا';
  }

  @override
  String activityVerbUpdated(String target) {
    return '$target اپ ڈیٹ کیا';
  }

  @override
  String activityVerbDeleted(String target) {
    return '$target حذف کیا';
  }

  @override
  String activityVerbAdded(String target) {
    return '$target شامل کیا';
  }

  @override
  String activityVerbRemoved(String target) {
    return '$target ہٹایا';
  }

  @override
  String activityVerbInvited(String target) {
    return '$target کو مدعو کیا';
  }

  @override
  String activityVerbChanged(String target) {
    return '$target بدلا';
  }

  @override
  String activityVerbStarted(String target) {
    return '$target شروع کیا';
  }

  @override
  String activityVerbStopped(String target) {
    return '$target روکا';
  }

  @override
  String activityVerbWrote(String target) {
    return '$target لکھا';
  }

  @override
  String get activityTargetAgent => 'ایجنٹ';

  @override
  String get activityTargetTicket => 'ٹکٹ';

  @override
  String get activityTargetWorkspace => 'ورک اسپیس';

  @override
  String get activityTargetRepository => 'ریپوزٹری';

  @override
  String get activityTargetMember => 'رکن';

  @override
  String get activityTargetInvite => 'دعوت';

  @override
  String get activityTargetSpace => 'اسپیس';

  @override
  String get activityTargetMessage => 'پیغام';

  @override
  String get activityTargetCache => 'کیش';

  @override
  String get activityTargetFile => 'فائل';

  @override
  String get activityTargetPipeline => 'پائپ لائن';

  @override
  String get activityTargetTemplate => 'ٹیمپلیٹ';

  @override
  String get activityTargetProvider => 'فراہم کنندہ';

  @override
  String get activityTargetModel => 'ماڈل';

  @override
  String get activityTargetSkill => 'مہارت';

  @override
  String get activityTargetTodo => 'to-do';

  @override
  String get activityTargetMeeting => 'میٹنگ';

  @override
  String get activityTargetProject => 'پروجیکٹ';

  @override
  String get activityTargetTeam => 'ٹیم';

  @override
  String get activityTargetDevice => 'ڈیوائس';

  @override
  String get activityTargetPreference => 'ترجیح';

  @override
  String get activityTargetBudget => 'بجٹ';

  @override
  String activityVerbApproved(String target) {
    return '$target منظور کیا';
  }

  @override
  String activityVerbArchived(String target) {
    return '$target آرکائیو کیا';
  }

  @override
  String activityVerbAssigned(String target) {
    return '$target تفویض کیا';
  }

  @override
  String activityVerbBackedUp(String target) {
    return '$target کا بیک اپ لیا';
  }

  @override
  String activityVerbCancelled(String target) {
    return '$target منسوخ کیا';
  }

  @override
  String activityVerbCleared(String target) {
    return '$target صاف کیا';
  }

  @override
  String activityVerbClosed(String target) {
    return '$target بند کیا';
  }

  @override
  String activityVerbCommitted(String target) {
    return '$target کمیٹ کیا';
  }

  @override
  String activityVerbCompacted(String target) {
    return '$target کمپیکٹ کیا';
  }

  @override
  String activityVerbCompleted(String target) {
    return '$target مکمل کیا';
  }

  @override
  String activityVerbConnected(String target) {
    return '$target منسلک کیا';
  }

  @override
  String activityVerbContinued(String target) {
    return '$target جاری رکھا';
  }

  @override
  String activityVerbDisconnected(String target) {
    return '$target منقطع کیا';
  }

  @override
  String activityVerbDispatched(String target) {
    return '$target ڈسپیچ کیا';
  }

  @override
  String activityVerbDrained(String target) {
    return '$target ڈرین کیا';
  }

  @override
  String activityVerbEnrolled(String target) {
    return '$target اندراج کیا';
  }

  @override
  String activityVerbEstimated(String target) {
    return '$target کا تخمینہ لگایا';
  }

  @override
  String activityVerbImported(String target) {
    return '$target درآمد کیا';
  }

  @override
  String activityVerbInstalled(String target) {
    return '$target انسٹال کیا';
  }

  @override
  String activityVerbKilled(String target) {
    return '$target ختم کیا';
  }

  @override
  String activityVerbMarked(String target) {
    return '$target نشان زد کیا';
  }

  @override
  String activityVerbMerged(String target) {
    return '$target مرج کیا';
  }

  @override
  String activityVerbOpened(String target) {
    return '$target کھولا';
  }

  @override
  String activityVerbPaused(String target) {
    return '$target توقف کیا';
  }

  @override
  String activityVerbPolled(String target) {
    return '$target پول کیا';
  }

  @override
  String activityVerbPrepared(String target) {
    return '$target تیار کیا';
  }

  @override
  String activityVerbProcessed(String target) {
    return '$target پروسیس کیا';
  }

  @override
  String activityVerbPublished(String target) {
    return '$target شائع کیا';
  }

  @override
  String activityVerbRefined(String target) {
    return '$target بہتر کیا';
  }

  @override
  String activityVerbRefreshed(String target) {
    return '$target تازہ کیا';
  }

  @override
  String activityVerbRegistered(String target) {
    return '$target رجسٹر کیا';
  }

  @override
  String activityVerbRenamed(String target) {
    return '$target کا نام بدلا';
  }

  @override
  String activityVerbReordered(String target) {
    return '$target کی ترتیب بدلی';
  }

  @override
  String activityVerbResponded(String target) {
    return '$target کا جواب دیا';
  }

  @override
  String activityVerbRestored(String target) {
    return '$target بحال کیا';
  }

  @override
  String activityVerbResumed(String target) {
    return '$target دوبارہ شروع کیا';
  }

  @override
  String activityVerbRetried(String target) {
    return '$target دوبارہ کوشش کی';
  }

  @override
  String activityVerbReverted(String target) {
    return '$target واپس کیا';
  }

  @override
  String activityVerbReviewed(String target) {
    return '$target کا ریویو کیا';
  }

  @override
  String activityVerbRan(String target) {
    return '$target چلایا';
  }

  @override
  String activityVerbSelected(String target) {
    return '$target منتخب کیا';
  }

  @override
  String activityVerbSent(String target) {
    return '$target بھیجا';
  }

  @override
  String activityVerbStaged(String target) {
    return '$target سٹیج کیا';
  }

  @override
  String activityVerbSteered(String target) {
    return '$target اسٹیئر کیا';
  }

  @override
  String activityVerbSubmitted(String target) {
    return '$target جمع کرایا';
  }

  @override
  String activityVerbSynced(String target) {
    return '$target سنک کیا';
  }

  @override
  String activityVerbToggled(String target) {
    return '$target ٹوگل کیا';
  }

  @override
  String activityVerbUninstalled(String target) {
    return '$target ان انسٹال کیا';
  }

  @override
  String activityVerbUnstaged(String target) {
    return '$target ان سٹیج کیا';
  }

  @override
  String get activityTargetActionPolicy => 'ایکشن پالیسی';

  @override
  String get activityTargetGoalRun => 'گول رن';

  @override
  String get activityTargetRunLog => 'رن لاگ';

  @override
  String get activityTargetWorkingMemory => 'ورکنگ میموری';

  @override
  String get activityTargetRoutingPolicy => 'راؤٹنگ پالیسی';

  @override
  String get activityTargetAutonomy => 'خود مختاری';

  @override
  String get activityTargetCalendar => 'کیلنڈر';

  @override
  String get activityTargetChecker => 'چیکر';

  @override
  String get activityTargetEditor => 'ایڈیٹر';

  @override
  String get activityTargetConfirmation => 'تصدیق';

  @override
  String get activityTargetTunnel => 'ٹنل';

  @override
  String get activityTargetConversation => 'گفتگو';

  @override
  String get activityTargetCredentials => 'کریڈینشلز';

  @override
  String get activityTargetDictation => 'ڈکٹیشن';

  @override
  String get activityTargetAgentRun => 'ایجنٹ رن';

  @override
  String get activityTargetEvalSuite => 'ایول سوٹ';

  @override
  String get activityTargetWorker => 'ورکر';

  @override
  String get activityTargetWorktree => 'worktree';

  @override
  String get activityTargetMcpServer => 'MCP سرور';

  @override
  String get activityTargetMemoryAccessGrant => 'میموری رسائی گرانٹ';

  @override
  String get activityTargetMemoryDomain => 'میموری ڈومین';

  @override
  String get activityTargetMemoryFact => 'میموری فیکٹ';

  @override
  String get activityTargetMemoryPolicy => 'میموری پالیسی';

  @override
  String get activityTargetFeed => 'فیڈ';

  @override
  String get activityTargetNote => 'نوٹ';

  @override
  String get activityTargetOrchestration => 'آرکیسٹریشن';

  @override
  String get activityTargetPipelineRun => 'پائپ لائن رن';

  @override
  String get activityTargetPipelineTrigger => 'پائپ لائن ٹرگر';

  @override
  String get activityTargetPlan => 'پلان';

  @override
  String get activityTargetPlaybook => 'پلے بک';

  @override
  String get activityTargetPullRequest => 'pull request';

  @override
  String get activityTargetReview => 'ریویو';

  @override
  String get activityTargetProcess => 'پراسیس';

  @override
  String get activityTargetProviderPolicy => 'فراہم کنندہ پالیسی';

  @override
  String get activityTargetReaction => 'ردعمل';

  @override
  String get activityTargetReviewSpace => 'ریویو اسپیس';

  @override
  String get activityTargetReviewStudio => 'ریویو اسٹوڈیو';

  @override
  String get activityTargetServerData => 'سرور ڈیٹا';

  @override
  String get activityTargetSoundscape => 'ساؤنڈ اسکیپ';

  @override
  String get activityTargetSession => 'سیشن';

  @override
  String get activityTargetTerminal => 'ٹرمینل';

  @override
  String get activityTargetTicketLink => 'ٹکٹ لنک';

  @override
  String get activityTargetTicketSync => 'ٹکٹ سنک';

  @override
  String get activityTargetProfile => 'پروفائل';

  @override
  String get activityTargetVoiceProfile => 'وائس پروفائل';

  @override
  String get activityTargetWeather => 'موسم کی پیش گوئی';

  @override
  String get activityTargetWorkProduct => 'ورک پروڈکٹ';

  @override
  String get activityChangedMemberRole => 'رکن کا کردار بدلا';

  @override
  String get activityChangedMemberRepoAccess => 'رکن کی ریپوزٹری رسائی بدلی';

  @override
  String get activityRefreshedWeather => 'موسم کی پیش گوئی تازہ کی';

  @override
  String get activitySetWeatherLocation => 'موسم کا مقام سیٹ کیا';

  @override
  String get activityClearedWeatherLocation => 'موسم کا مقام صاف کیا';

  @override
  String get activityMarkedAllArticlesRead =>
      'تمام مضامین پڑھا ہوا نشان زد کیے';

  @override
  String get activityMarkedArticleRead => 'ایک مضمون پڑھا ہوا نشان زد کیا';

  @override
  String get activityUpdatedSavedArticle => 'محفوظ مضمون اپ ڈیٹ کیا';

  @override
  String get activityTookOverSession => 'سیشن سنبھال لیا';

  @override
  String get activityHandedBackSession => 'سیشن واپس کر دیا';

  @override
  String get activityCommittedAndPushed => 'کمیٹ اور پش کیا';

  @override
  String get activityBackedUpServer => 'سرور ڈیٹا کا بیک اپ لیا';

  @override
  String get activityRespondedToInvitation => 'ایونٹ دعوت کا جواب دیا';

  @override
  String get activityDisconnectedCalendar => 'کیلنڈر منقطع کیا';

  @override
  String get activityMarkedFileViewed => 'فائل دیکھی ہوئی نشان زد کی';

  @override
  String get activityRespondedToApproval => 'منظوری کی درخواست کا جواب دیا';

  @override
  String get activityChangedTunnel => 'ٹنل سیٹنگ بدلی';

  @override
  String get activitySentMessageToAgent => 'ایجنٹ کو پیغام بھیجا';

  @override
  String get activityOpenedReviewSpace => 'ریویو اسپیس کھولی';

  @override
  String get activityOpenedStandingConversation => 'مستقل گفتگو کھولی';

  @override
  String get activityStartedRecording => 'ریکارڈنگ شروع کی';

  @override
  String get activityStoppedRecording => 'ریکارڈنگ روکی';

  @override
  String get activityToggledMcpServer => 'MCP سرور ٹوگل کیا';

  @override
  String get activitySavedApiKey => 'API کلید محفوظ کی';

  @override
  String get activityRemovedProviderCredential => 'فراہم کنندہ کریڈینشل ہٹایا';

  @override
  String get activityUpdatedLinkedRepos => 'لنک شدہ ریپوزٹریز اپ ڈیٹ کیں';

  @override
  String get activityUnlinkedRepo => 'ریپوزٹری ان لنک کی';

  @override
  String get activityUpdatedActionItem => 'ایکشن آئٹم اپ ڈیٹ کیا';

  @override
  String adRulesCount(int count) {
    return '$count اشتہاری قواعد';
  }

  @override
  String get adapter => 'اڈاپٹر';

  @override
  String get adapterLabel => 'اڈاپٹر';

  @override
  String get adapters => 'اڈاپٹرز';

  @override
  String get adaptersAutoDetected =>
      'اس مشین پر خود دریافت شدہ ایجنٹ رنرز۔ اضافی رنرز فعال کرنے کے لیے کوئی غائب CLI ٹول انسٹال کریں۔';

  @override
  String get add => 'شامل کریں';

  @override
  String get addAComment => 'تبصرہ شامل کریں';

  @override
  String get addAReaction => 'ردعمل شامل کریں';

  @override
  String get addASuggestion => 'تجویز شامل کریں';

  @override
  String get addAgents => 'ایجنٹس شامل کریں';

  @override
  String get addEmoji => 'ایموجی شامل کریں';

  @override
  String get addFeed => 'فیڈ شامل کریں';

  @override
  String get addressBarHint => 'URL درج کریں';

  @override
  String get addFromFile => 'فائل سے شامل کریں';

  @override
  String get addGif => 'GIF شامل کریں';

  @override
  String get addLocalCheckoutDescription =>
      'اس ورک اسپیس سے نشانہ بنانے کے لیے مقامی چیک آؤٹ شامل کریں۔';

  @override
  String get addRepository => 'ریپوزٹری شامل کریں';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ریپوزٹریز شامل کریں',
      one: 'ریپوزٹری شامل کریں',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro =>
      'سرور چلانے والی مشین کے فولڈرز دیکھیں اور رجسٹر کرنے کے لیے git چیک آؤٹس منتخب کریں۔';

  @override
  String get selectThisFolder => 'یہ فولڈر منتخب کریں';

  @override
  String get deselectThisFolder => 'یہ فولڈر غیر منتخب کریں';

  @override
  String get goUp => 'اوپر';

  @override
  String get noSubfoldersHere => 'یہاں کوئی سب فولڈر نہیں';

  @override
  String get notAGitRepository => 'یہ فولڈر git ریپوزٹری نہیں۔';

  @override
  String get addToken => 'ٹوکن شامل کریں';

  @override
  String get addWorkspace => 'ورک اسپیس شامل کریں';

  @override
  String get addWorkspaceEllipsis => 'ورک اسپیس شامل کریں…';

  @override
  String get added => 'شامل ہوا';

  @override
  String get addingEllipsis => 'شامل ہو رہا ہے…';

  @override
  String get advancedLabel => 'اعلیٰ';

  @override
  String get agent => 'ایجنٹ';

  @override
  String conversationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count گفتگوئیں',
      one: '$count گفتگو',
    );
    return '$_temp0';
  }

  @override
  String agentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ایجنٹس',
      one: '$count ایجنٹ',
    );
    return '$_temp0';
  }

  @override
  String get agentMdPath => 'ایجنٹ MD پاتھ';

  @override
  String get agentName => 'ایجنٹ کا نام';

  @override
  String get agentTitle => 'ایجنٹ کا عنوان';

  @override
  String get agentUpdated => 'ایجنٹ اپ ڈیٹ ہو گیا۔';

  @override
  String get agents => 'ایجنٹس';

  @override
  String get agentsMentionSection => 'ایجنٹس';

  @override
  String get usersMentionSection => 'لوگ';

  @override
  String get ticketsMentionSection => 'ٹکٹس';

  @override
  String get pullRequestsMentionSection => 'Pull requests';

  @override
  String get meetingsMentionSection => 'میٹنگز';

  @override
  String get entityRefTicketFallback => 'ٹکٹ';

  @override
  String get entityRefPrFallback => 'Pull request';

  @override
  String get entityRefMeetingFallback => 'میٹنگ';

  @override
  String get aiReview => 'AI ریویو';

  @override
  String get all => 'سب';

  @override
  String get allAgentsAlreadyInSpace => 'تمام ایجنٹس پہلے سے اس اسپیس میں ہیں۔';

  @override
  String get allCommits => 'تمام کمیٹس';

  @override
  String get allSources => 'تمام ذرائع';

  @override
  String get allow => 'اجازت دیں';

  @override
  String get apiKeys => 'API کلیدیں';

  @override
  String get appFont => 'ایپ فونٹ';

  @override
  String get appLogLevelDebugDescription =>
      'تفصیلی ٹریسز شامل کرتا ہے — ڈیولپمنٹ کے لیے۔';

  @override
  String get appLogLevelDebugLabel => 'ڈیبگ';

  @override
  String get appLogLevelErrorDescription => 'صرف غیر متوقع خرابیاں اور استثنا۔';

  @override
  String get appLogLevelErrorLabel => 'خرابی';

  @override
  String get appLogLevelInfoDescription =>
      'لائف سائیکل اور اسٹیٹس پیغامات شامل کرتا ہے۔';

  @override
  String get appLogLevelInfoLabel => 'معلومات';

  @override
  String get appLogLevelNoneDescription => 'کنسول پر بالکل آؤٹ پٹ نہیں۔';

  @override
  String get appLogLevelNoneLabel => 'کوئی نہیں';

  @override
  String get appLogLevelVerboseDescription =>
      'سب کچھ۔ بہت زیادہ شور — صرف ڈیبگنگ کے لیے۔';

  @override
  String get appLogLevelVerboseLabel => 'تفصیلی';

  @override
  String get appLogLevelWarningDescription =>
      'تنبیہات اور قابلِ اصلاح مسائل شامل کرتا ہے۔';

  @override
  String get appLogLevelWarningLabel => 'تنبیہ';

  @override
  String get appearanceLanguage => 'ظاہری شکل اور زبان';

  @override
  String get apply => 'لاگو کریں';

  @override
  String get approve => 'منظور کریں';

  @override
  String get agentApprovalRequired => 'منظوری درکار';

  @override
  String agentApprovalsMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مزید انتظار میں',
      one: '1 مزید انتظار میں',
    );
    return '$_temp0';
  }

  @override
  String get approved => 'منظور';

  @override
  String get articleNoun => 'مضمون';

  @override
  String get articlesSubscribed => 'آپ کی سبسکرائب شدہ فیڈز کے مضامین۔';

  @override
  String get askAi => 'AI سے پوچھیں';

  @override
  String get askAiReviewDescription => 'اس PR کا ریویو AI سے پوچھیں';

  @override
  String get assignees => 'تفویض شدہ';

  @override
  String get attachImage => 'تصویر منسلک کریں';

  @override
  String get attachedAgents => 'منسلک ایجنٹس';

  @override
  String get audioInput => 'آڈیو ان پٹ';

  @override
  String get audioOutput => 'آڈیو آؤٹ پٹ';

  @override
  String get authenticationToken => 'تصدیقی ٹوکن';

  @override
  String authoredByLabel(String role) {
    return 'از: $role';
  }

  @override
  String get autoRecommended => 'آٹو (تجویز کردہ)';

  @override
  String get available => 'دستیاب';

  @override
  String get awaitingYourReview => 'آپ کے ریویو کا انتظار';

  @override
  String get back => 'واپس';

  @override
  String get backLabel => 'واپس';

  @override
  String get backend => 'بیک اینڈ';

  @override
  String get blockAdsTrackers => 'اشتہارات، ٹریکرز اور کوکی بینرز بلاک کریں';

  @override
  String get blocking => 'بلاک کر رہا ہے';

  @override
  String get bookmarkLabel => 'بک مارک';

  @override
  String get briefDescription => 'مختصر تفصیل';

  @override
  String get bugLabel => 'BUG';

  @override
  String get bundledDefaultsNeverUpdated =>
      'بنڈل شدہ ڈیفالٹس — کبھی اپ ڈیٹ نہیں ہوئے';

  @override
  String get cancel => 'منسوخ';

  @override
  String get cancelEdit => 'ترمیم منسوخ کریں';

  @override
  String get categoryNavigation => 'نیویگیشن';

  @override
  String get change => 'بدلیں';

  @override
  String get changesRequested => 'تبدیلیاں مانگی گئیں';

  @override
  String get spacesMentionSection => 'اسپیسز';

  @override
  String get checkForUpdates => 'اپ ڈیٹس چیک کریں';

  @override
  String get checking => 'چیک ہو رہا ہے';

  @override
  String get checkingEllipsis => 'چیک ہو رہا ہے…';

  @override
  String get chooseAppFont => 'ایپ فونٹ منتخب کریں';

  @override
  String get chooseCodeFont => 'کوڈ فونٹ منتخب کریں';

  @override
  String get chooseRunner => 'اپنا ایجنٹ رنر منتخب کریں۔';

  @override
  String get clear => 'صاف کریں';

  @override
  String get clickToRetry => 'دوبارہ کوشش کے لیے کلک کریں';

  @override
  String get close => 'بند کریں';

  @override
  String get closeEsc => 'بند کریں (Esc)';

  @override
  String get closeReader => 'ریڈر بند کریں';

  @override
  String get closed => 'بند';

  @override
  String get codeFont => 'کوڈ فونٹ';

  @override
  String get codeFontLigatures => 'کوڈ فونٹ لیگیچرز';

  @override
  String get codeFontLigaturesDescription =>
      'پروگرامنگ لیگیچرز (⁨=>⁩, ⁨!=⁩, ⁨->⁩) کو کوڈ اور diffs میں مشترکہ گلفس کے طور پر دکھائیں';

  @override
  String get collapse => 'سکیڑیں';

  @override
  String get commandPalette => 'کمانڈ پیلیٹ';

  @override
  String get commandPaletteOrgMembers => 'آرگنائزیشن اراکین';

  @override
  String get commandPaletteBrowseTeam => 'ٹیم دیکھیں';

  @override
  String get commandPaletteBrowseTeamDesc => 'تمام آرگنائزیشن اراکین دیکھیں';

  @override
  String get compactDone =>
      'گفتگو کمپیکٹ ہو گئی۔ پہلے کی ہسٹری خلاصے میں سمیٹ دی گئی۔';

  @override
  String get compactNothing =>
      'ابھی کمپیکٹ کرنے کو کچھ نہیں۔ گفتگو ابھی چھوٹی ہے۔';

  @override
  String get compactBusy =>
      'ایجنٹ ابھی کام کر رہا ہے۔ باری ختم ہونے پر کمپیکٹ کریں۔';

  @override
  String get compactUnavailable => 'اس سرور پر کمپیکشن دستیاب نہیں۔';

  @override
  String get commandsMentionSection => 'کمانڈز';

  @override
  String get comment => 'تبصرہ';

  @override
  String get commentOnThisFile => 'اس فائل پر تبصرہ';

  @override
  String get commented => 'تبصرہ کیا';

  @override
  String get commits => 'کمیٹس';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'تازہ ترین $loaded از $total کمیٹس دکھا رہے ہیں';
  }

  @override
  String get prCloneProgressCloningTitle => 'ریپوزٹری کلون ہو رہی ہے';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'یہ PR $fileCount فائلیں بدلتا ہے، جو GitHub کی API حد سے زیادہ ہے۔ ریپوزٹری مقامی طور پر کلون ہو رہی ہے…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'یہ PR GitHub کی API فائل حد سے زیادہ ہے۔ ریپوزٹری مقامی طور پر کلون ہو رہی ہے…';

  @override
  String get prCloneProgressFetchingTitle => 'PR refs حاصل ہو رہے ہیں';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'بیس برانچ اور PR ہیڈ ref حاصل ہو رہے ہیں…';

  @override
  String get prCloneProgressComputingTitle => 'Diff حساب ہو رہا ہے';

  @override
  String get prCloneProgressComputingSubtitle =>
      'مقامی طور پر git diff چل رہا ہے…';

  @override
  String get prCloneProgressErrorTitle => 'Diff لوڈ نہیں ہو سکا';

  @override
  String get prCloneProgressErrorSubtitle =>
      'کلون یا diff حساب کے دوران خرابی ہوئی۔ تازہ کرنے کی کوشش کریں۔';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'ابھی کام جاری… $elapsed گزر چکے';
  }

  @override
  String confidenceLabel(int percent) {
    return 'اعتماد: $percent%';
  }

  @override
  String get configureAgentIdentities =>
      'ایجنٹ شناختیں، پرامپٹس، مہارتیں کنفیگر کریں اور رنز دیکھیں۔';

  @override
  String get configuredLabel => 'کنفیگر شدہ۔';

  @override
  String get confirmedBy => 'تصدیق از';

  @override
  String get consensus => 'اتفاق';

  @override
  String get contentHint => 'کیا یاد رکھا جائے';

  @override
  String get contentLabel => 'مواد';

  @override
  String get contentMarkdown => 'مواد (Markdown)';

  @override
  String get contextWindowSize => 'سیاق ونڈو سائز';

  @override
  String modelContextChip(String size) {
    return 'ماڈل · ⁨$size⁩';
  }

  @override
  String get continueLabel => 'جاری رکھیں';

  @override
  String get conversationMode => 'موڈ';

  @override
  String cookieRulesCount(int count) {
    return '$count کوکی قواعد';
  }

  @override
  String typeToConfirmPrompt(String value) {
    return 'تصدیق کے لیے $value ٹائپ کریں۔';
  }

  @override
  String get copied => 'کاپی ہو گیا!';

  @override
  String get copy => 'کاپی';

  @override
  String get copyAddress => 'ایڈریس کاپی کریں';

  @override
  String get copyBaseBranchTooltip => 'بیس برانچ کا نام کاپی کریں';

  @override
  String get copyHeadBranchTooltip => 'ہیڈ برانچ کا نام کاپی کریں';

  @override
  String couldNotListDevices(String error) {
    return 'ڈیوائسز فہرست نہیں ہو سکیں: ⁨$error⁩';
  }

  @override
  String get create => 'بنائیں';

  @override
  String get createOrSelectWorkspace =>
      'ریپوزٹریز شامل کرنے سے پہلے ورک اسپیس بنائیں یا منتخب کریں۔';

  @override
  String get createPullRequest => 'pull request بنائیں';

  @override
  String get createdByMe => 'میرے بنائے ہوئے';

  @override
  String createdLabel(String date) {
    return 'بنایا گیا: $date';
  }

  @override
  String get currentParticipants => 'موجودہ شرکاء';

  @override
  String get customSystemPrompt => 'اس ایجنٹ کے لیے حسبِ ضرورت سسٹم پرامپٹ...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دن پہلے',
      one: '1 دن پہلے',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'غیر فعال کریں';

  @override
  String get delete => 'حذف کریں';

  @override
  String get deleteAgent => 'ایجنٹ حذف کریں';

  @override
  String deleteAgentConfirm(String name) {
    return '\"⁨$name⁩\" حذف کریں؟ یہ واپس نہیں ہو سکتا۔';
  }

  @override
  String get deleteSpace => 'اسپیس حذف کریں';

  @override
  String deleteConfirmName(String name) {
    return '\"⁨$name⁩\" حذف کریں؟';
  }

  @override
  String get deleteFact => 'فیکٹ حذف کریں';

  @override
  String get deleteFeedBody =>
      'اس سے فیڈ اور اس کے تمام کیش شدہ مضامین ہٹ جاتے ہیں۔ اس فیڈ کے بک مارک شدہ مضامین بھی ہٹ جائیں گے۔';

  @override
  String deleteFeedConfirm(String name) {
    return '\"⁨$name⁩\" حذف کریں؟';
  }

  @override
  String get deletePolicy => 'پالیسی حذف کریں';

  @override
  String get deletePolicyConfirm => 'یہ پالیسی حذف کریں؟ یہ واپس نہیں ہو سکتا۔';

  @override
  String deleteTopicConfirm(String topic) {
    return '\"⁨$topic⁩\" حذف کریں؟ یہ واپس نہیں ہو سکتا۔';
  }

  @override
  String get deleteWorkspace => 'ورک اسپیس حذف کریں';

  @override
  String get deny => 'منع کریں';

  @override
  String get detailsLabel => 'تفصیلات';

  @override
  String get descriptionLabel => 'تفصیل';

  @override
  String detectedBackend(String label) {
    return 'دریافت شدہ: ⁨$label⁩';
  }

  @override
  String get detectedRunners => 'دریافت شدہ رنرز';

  @override
  String get detectingAdapters => 'اڈاپٹرز دریافت ہو رہے ہیں…';

  @override
  String get detectingInputDevices => 'ان پٹ ڈیوائسز دریافت ہو رہی ہیں…';

  @override
  String detectionFailed(String error) {
    return 'دریافت ناکام: ⁨$error⁩';
  }

  @override
  String get disabled => 'غیر فعال';

  @override
  String get discover => 'دریافت کریں';

  @override
  String get dismissed => 'برطرف';

  @override
  String get domainHint => 'مثال: ⁨api-performance⁩';

  @override
  String get domainLabel => 'ڈومین';

  @override
  String get download => 'ڈاؤن لوڈ';

  @override
  String get downloadingLabel => 'ڈاؤن لوڈ ہو رہا ہے';

  @override
  String downloadingModel(int pct) {
    return 'ماڈل ڈاؤن لوڈ ہو رہا ہے… $pct%';
  }

  @override
  String get draft => 'ڈرافٹ';

  @override
  String get draftLabel => 'ڈرافٹ';

  @override
  String get edit => 'ترمیم';

  @override
  String get edited => 'ترمیم شدہ';

  @override
  String get editMessage => 'پیغام میں ترمیم';

  @override
  String get revertToThere => 'وہاں واپس کریں';

  @override
  String get sendAsNewMessage => 'نئے پیغام کے طور پر بھیجیں';

  @override
  String get editMessageChoiceBody =>
      'واپسی اس پیغام کے بعد والے پیغامات چھپاتی ہے اور ایجنٹ کی فائلیں واپس کرتی ہے۔ آپ اسے کالعدم کر سکتے ہیں۔ نئے پیغام کے طور پر بھیجنا گفتگو کو ویسا ہی چھوڑ دیتا ہے۔';

  @override
  String get deleteMessage => 'پیغام حذف کریں';

  @override
  String get deleteMessageConfirm => 'یہ پیغام حذف کریں؟ یہ واپس نہیں ہو سکتا۔';

  @override
  String get messageDeleted => 'پیغام حذف ہو گیا';

  @override
  String get searchInConversation => 'گفتگو میں تلاش';

  @override
  String get searchMessagesHint => 'پیغامات تلاش کریں…';

  @override
  String get noMessagesFound => 'کوئی پیغام نہیں ملا';

  @override
  String get editFact => 'فیکٹ میں ترمیم';

  @override
  String get editPolicy => 'پالیسی میں ترمیم';

  @override
  String get editSuggestedCodeHint => 'تجویز کردہ کوڈ میں ترمیم…';

  @override
  String get editSuggestion => 'تجویز میں ترمیم';

  @override
  String get egArchitect => 'مثال: ⁨architect⁩';

  @override
  String get egControlCenter => 'مثال: ⁨control-center⁩';

  @override
  String get egPlatform => 'مثال: Platform';

  @override
  String get egSamuelAlev => 'مثال: ⁨SamuelAlev⁩';

  @override
  String get egSoftwareArchitect => 'مثال: ⁨Software Architect⁩';

  @override
  String get egTheVerge => 'مثال: ⁨The Verge⁩';

  @override
  String get egTokenLimit => 'مثال: ⁨128000⁩';

  @override
  String embeddingInstallFailed(String error) {
    return 'انسٹال ناکام: ⁨$error⁩';
  }

  @override
  String get embeddingInstalled =>
      'مقامی ایمبیڈنگ ماڈل انسٹال ہو گیا۔ ہائبرڈ تلاش فعال ہے۔';

  @override
  String get embeddingModel => 'ایمبیڈنگ ماڈل (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'انسٹال نہیں۔ فعال ہونے تک تلاش صرف کلیدی الفاظ پر رہتی ہے۔';

  @override
  String get embeddingRedownloadBody =>
      'موجودہ ماڈل فائلیں حذف ہو کر دوبارہ ڈاؤن لوڈ ہوں گی۔ ڈاؤن لوڈ مکمل ہونے تک سیمانٹک تلاش دستیاب نہیں ہو گی۔';

  @override
  String get embeddingRemoveBody =>
      'دوبارہ انسٹال کرنے تک سیمانٹک تلاش بند رہے گی۔ آپ اسے کسی بھی وقت دوبارہ انسٹال کر سکتے ہیں۔';

  @override
  String get speakerDiarization => 'اسپیکر ڈائرائزیشن';

  @override
  String get diarizationModel => 'ڈائرائزیشن ماڈل';

  @override
  String get diarizationInstalled =>
      'انسٹال شدہ — میٹنگ ٹرانسکرپٹس میں الگ الگ سپیکرز کے نام';

  @override
  String get diarizationNotInstalled =>
      'انسٹال نہیں — میٹنگ سپیکرز الگ نہیں ہوں گے';

  @override
  String diarizationInstallFailed(String error) {
    return 'انسٹال ناکام: ⁨$error⁩';
  }

  @override
  String get redownloadDiarizationModel =>
      'ڈائرائزیشن ماڈل دوبارہ ڈاؤن لوڈ کریں';

  @override
  String get diarizationRedownloadBody =>
      'اس سے موجودہ ڈائرائزیشن ماڈلز ہٹ کر دوبارہ ڈاؤن لوڈ ہوتے ہیں۔';

  @override
  String get removeDiarizationModel => 'ڈائرائزیشن ماڈل ہٹائیں';

  @override
  String get diarizationRemoveBody =>
      'اس سے ڈیوائس پر ڈائرائزیشن ماڈلز حذف ہوتے ہیں۔ پہلے سے بنی میٹنگ ٹرانسکرپٹس متاثر نہیں ہوتیں۔';

  @override
  String get enableNotifications => 'اطلاعات فعال کریں';

  @override
  String get enableSandboxing => 'سینڈ باکسنگ فعال کریں';

  @override
  String get enabled => 'فعال';

  @override
  String errorCreatingAgent(String error) {
    return 'ایجنٹ بناتے ہوئے خرابی: ⁨$error⁩';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'ایجنٹ حذف کرتے ہوئے خرابی: ⁨$error⁩';
  }

  @override
  String errorWithDetail(String error) {
    return 'خرابی: ⁨$error⁩';
  }

  @override
  String get expand => 'پھیلائیں';

  @override
  String extractingModel(int pct) {
    return 'ماڈل نکالا جا رہا ہے… $pct%';
  }

  @override
  String get fact => 'فیکٹ';

  @override
  String factCount(int count) {
    return '$count فیکٹ';
  }

  @override
  String factCountPlural(int count) {
    return '$count فیکٹس';
  }

  @override
  String get facts => 'فیکٹس';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount فیکٹس · $policyCount پالیسیاں';
  }

  @override
  String get failed => 'ناکام';

  @override
  String failedToDispatch(String error) {
    return 'ڈسپیچ ناکام: ⁨$error⁩';
  }

  @override
  String get failedToLoad => 'لوڈ نہیں ہو سکا';

  @override
  String failedToLoadAgents(String error) {
    return 'ایجنٹس لوڈ نہیں ہو سکے: ⁨$error⁩';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'فیڈز لوڈ نہیں ہو سکیں: ⁨$error⁩';
  }

  @override
  String get failedToLoadGifs => 'GIFs لوڈ نہیں ہو سکیں';

  @override
  String failedToLoadLogs(String error) {
    return 'لاگز لوڈ نہیں ہو سکے: ⁨$error⁩';
  }

  @override
  String get failedToLoadRepos => 'ریپوزٹریز لوڈ نہیں ہو سکیں';

  @override
  String get failedToLoadWorkspaces => 'ورک اسپیسز لوڈ نہیں ہو سکیں';

  @override
  String failedToStartAiReview(String error) {
    return 'AI ریویو شروع نہیں ہو سکا: ⁨$error⁩';
  }

  @override
  String get failedToStartMicTest => 'مائیک ٹیسٹ شروع نہیں ہو سکا۔';

  @override
  String failedToSubmitReview(String error) {
    return 'ریویو جمع نہیں ہو سکا: ⁨$error⁩';
  }

  @override
  String failedToUpload(String name, String error) {
    return '⁨$name⁩ اپ لوڈ نہیں ہو سکی: ⁨$error⁩';
  }

  @override
  String failedWithError(String error) {
    return 'ناکام: ⁨$error⁩';
  }

  @override
  String get failure => 'ناکامی';

  @override
  String get feedAlreadyExists => 'اس URL کی فیڈ پہلے سے موجود ہے۔';

  @override
  String get feedUrlExample => 'مثال: ⁨https://example.com/feed.xml⁩';

  @override
  String get feedUrlLabel => 'فیڈ URL';

  @override
  String feedsCount(int count) {
    return 'فیڈز ($count)';
  }

  @override
  String get filesChanged => 'بدلی ہوئی فائلیں';

  @override
  String filesCount(int count) {
    return '$count فائل(یں)';
  }

  @override
  String get filesMentionSection => 'فائلیں';

  @override
  String get filterAgents => 'ایجنٹس فلٹر کریں...';

  @override
  String get filterFilesHint => 'فائلیں فلٹر کریں…';

  @override
  String get filterLists => 'فہرستیں فلٹر کریں';

  @override
  String get filterSkillsPlaceholder => 'مہارتیں فلٹر کریں…';

  @override
  String get finish => 'مکمل کریں';

  @override
  String get fix => 'درست کریں';

  @override
  String get forward => 'آگے';

  @override
  String get general => 'عام';

  @override
  String get githubLink => 'GitHub لنک';

  @override
  String get claudeStatusFetchFailed => '⁨status.claude.com⁩ تک نہیں پہنچ سکے';

  @override
  String get claudeStatusOpenInBrowser => '⁨status.claude.com⁩ کھولیں';

  @override
  String get githubStatusFetchFailed => '⁨githubstatus.com⁩ تک نہیں پہنچ سکے';

  @override
  String get githubDegradedTitle => 'GitHub مسائل رپورٹ کر رہا ہے';

  @override
  String githubDegradedStatusLine(String status) {
    return 'GitHub اسٹیٹس: ⁨$status⁩۔';
  }

  @override
  String githubDegradedBody(String status) {
    return 'GitHub اسٹیٹس: ⁨$status⁩۔ بحالی تک pull request ڈیٹا پرانا یا نامکمل ہو سکتا ہے۔';
  }

  @override
  String get githubStatusOpenInBrowser => '⁨githubstatus.com⁩ کھولیں';

  @override
  String get githubStatusRefresh => 'تازہ کریں';

  @override
  String githubStatusUpdated(String time) {
    return '$time اپ ڈیٹ ہوا';
  }

  @override
  String get kimiStatusFetchFailed => '⁨status.moonshot.cn⁩ تک نہیں پہنچ سکے';

  @override
  String get kimiStatusOpenInBrowser => '⁨status.moonshot.cn⁩ کھولیں';

  @override
  String get openaiStatusFetchFailed => '⁨status.openai.com⁩ تک نہیں پہنچ سکے';

  @override
  String get openaiStatusOpenInBrowser => '⁨status.openai.com⁩ کھولیں';

  @override
  String get serviceStatusMaintenance => 'مینٹیننس';

  @override
  String get serviceStatusMajorIssues => 'بڑے مسائل';

  @override
  String get serviceStatusMinorIssues => 'چھوٹے مسائل';

  @override
  String get serviceStatusOperational => 'فعال';

  @override
  String get serviceStatusOutage => 'خلل';

  @override
  String serviceStatusOverflowCount(int count) {
    return '⁨$count+⁩';
  }

  @override
  String get serviceStatusTitle => 'سروس اسٹیٹس';

  @override
  String get serviceStatusUnknown => 'نامعلوم';

  @override
  String lastChecked(String time) {
    return '$time چیک ہوا';
  }

  @override
  String get lastCheckedRecently => 'حال ہی میں چیک ہوا';

  @override
  String get giveYourWorkAHome => 'اپنے کام کو گھر دیں۔';

  @override
  String get goBack => 'واپس جائیں';

  @override
  String get goForward => 'آگے جائیں';

  @override
  String get googleFonts => 'Google fonts';

  @override
  String get high => 'زیادہ';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count گھنٹے پہلے',
      one: '1 گھنٹہ پہلے',
    );
    return '$_temp0';
  }

  @override
  String get sidebarAgeNow => 'ابھی';

  @override
  String sidebarAgeMinutes(int count) {
    return '$count منٹ';
  }

  @override
  String sidebarAgeHours(int count) {
    return '$count گھ';
  }

  @override
  String sidebarAgeDays(int count) {
    return '$count دن';
  }

  @override
  String sidebarAgeMonths(int count) {
    return '$count مہ';
  }

  @override
  String sidebarAgeYears(int count) {
    return '$count سال';
  }

  @override
  String get images => 'تصاویر';

  @override
  String get inactive => 'غیر فعال';

  @override
  String get install => 'انسٹال';

  @override
  String installedVersion(String version) {
    return 'انسٹال شدہ ⁨$version⁩';
  }

  @override
  String get invite => 'مدعو کریں';

  @override
  String get inviteAgent => 'ایجنٹ مدعو کریں';

  @override
  String get isolateAgentExecution => 'ایجنٹ عمل درآمد الگ کریں۔';

  @override
  String get justNow => 'ابھی';

  @override
  String get keepSandboxing => 'سینڈ باکسنگ رکھیں';

  @override
  String get keybindingAddRepository => 'ریپوزٹری شامل کریں';

  @override
  String get keybindingCommandPalette => 'کمانڈ پیلیٹ';

  @override
  String get keybindingFocusSearch => 'تلاش پر فوکس';

  @override
  String get keybindingNewAgent => 'نیا ایجنٹ';

  @override
  String get keybindingNewWorkspace => 'نیا ورک اسپیس';

  @override
  String get keybindingNextArticle => 'اگلا مضمون';

  @override
  String get keybindingNextSpace => 'اگلی اسپیس';

  @override
  String get keybindingNextWorkspace => 'اگلا ورک اسپیس';

  @override
  String get keybindingOpenArticle => 'مضمون کھولیں';

  @override
  String get keybindingOpenPr => 'PR کھولیں';

  @override
  String get keybindingOpenSettings => 'ترتیبات کھولیں';

  @override
  String get keybindingOpenWorkspace => 'ورک اسپیس کھولیں';

  @override
  String get keybindingPreviousArticle => 'پچھلا مضمون';

  @override
  String get keybindingPreviousSpace => 'پچھلی اسپیس';

  @override
  String get keybindingPreviousWorkspace => 'پچھلا ورک اسپیس';

  @override
  String get keybindingRefresh => 'تازہ کریں';

  @override
  String get keybindingSendMessage => 'پیغام بھیجیں';

  @override
  String get keybindingToggleBookmark => 'بک مارک ٹوگل کریں';

  @override
  String get keybindingToggleTheme => 'تھیم ٹوگل کریں';

  @override
  String get keybindingToggleWorkspaceSwitcher => 'ورک اسپیس سوئچر ٹوگل کریں';

  @override
  String get keybindingWorkspace1 => 'ورک اسپیس 1';

  @override
  String get keybindingWorkspace2 => 'ورک اسپیس 2';

  @override
  String get keybindingWorkspace3 => 'ورک اسپیس 3';

  @override
  String get keybindingWorkspace4 => 'ورک اسپیس 4';

  @override
  String get keybindingWorkspace5 => 'ورک اسپیس 5';

  @override
  String get keybindingWorkspace6 => 'ورک اسپیس 6';

  @override
  String get keybindingWorkspace7 => 'ورک اسپیس 7';

  @override
  String get keybindingWorkspace8 => 'ورک اسپیس 8';

  @override
  String get keybindingWorkspace9 => 'ورک اسپیس 9';

  @override
  String get killRunning => 'چلتے ہوئے ختم کریں';

  @override
  String get languageSystem => 'سسٹم';

  @override
  String get leaveACommentEllipsis => 'تبصرہ لکھیں…';

  @override
  String get legendLabel => 'لیجنڈ';

  @override
  String get lessLabel => 'کم';

  @override
  String get letsPluginTools => 'آئیے آپ کے ٹولز جوڑیں۔';

  @override
  String get level => 'سطح';

  @override
  String get loadingAgents => 'ایجنٹس لوڈ ہو رہے ہیں…';

  @override
  String get loadingModels => 'ماڈلز لوڈ ہو رہے ہیں…';

  @override
  String get loadingProviders => 'فراہم کنندگان لوڈ ہو رہے ہیں…';

  @override
  String get logLevel => 'لاگ لیول';

  @override
  String get logs => 'لاگز';

  @override
  String get low => 'کم';

  @override
  String get maintenance => 'مینٹیننس';

  @override
  String get manageParticipants => 'شرکاء منظم کریں';

  @override
  String get manageWorkspaces => 'ورک اسپیسز منظم کریں';

  @override
  String get reorderWorkspace => 'ورک اسپیس کی ترتیب بدلیں';

  @override
  String get matchOsAppearance =>
      'اپنے OS کی ظاہری شکل سے میل کھائیں یا مقرر موڈ منتخب کریں۔';

  @override
  String get mcpNotAvailableOnServer =>
      'منسلک سرور پر MCP سرور کنٹرول دستیاب نہیں۔';

  @override
  String get modelManagedOnServer =>
      'یہ ماڈل سرور ہوسٹ پر چلتا ہے اور وہیں منظم ہوتا ہے۔';

  @override
  String get mcpServer => 'MCP سرور';

  @override
  String get medium => 'درمیانہ';

  @override
  String get memoryDataHint =>
      'ایجنٹس کے کام کے ساتھ فیکٹس اور پالیسیاں یہاں نظر آئیں گی۔';

  @override
  String get memoryLabel => 'میموری';

  @override
  String get merge => 'مرج';

  @override
  String get merged => 'مرج شدہ';

  @override
  String get messagePlaceholder => 'پیغام… (ذکر کے لیے @، کمانڈز کے لیے /)';

  @override
  String get navConversations => 'اسپیسز';

  @override
  String get microphonePermissionDenied => 'مائیکروفون کی اجازت مسترد۔';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count منٹ پہلے',
      one: '1 منٹ پہلے',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'ماڈل';

  @override
  String get modified => 'ترمیم شدہ';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مہینے پہلے',
      one: '1 مہینہ پہلے',
    );
    return '$_temp0';
  }

  @override
  String get moreLabel => 'مزید';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'نام';

  @override
  String get nameAndTitleRequired => 'نام اور عنوان ضروری ہیں۔';

  @override
  String get nameAndUrlRequired => 'نام اور URL ضروری';

  @override
  String get nameLabel => 'نام';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'نیٹو سینڈ باکس ⁨$platform⁩ پر دستیاب ہے۔';
  }

  @override
  String get nativeSandboxNeedsInstall => 'نیٹو سینڈ باکس انسٹالیشن درکار';

  @override
  String get navObservability => 'آبزرویبلٹی';

  @override
  String get navSettings => 'ترتیبات';

  @override
  String get exitSettings => 'ترتیبات سے باہر نکلیں';

  @override
  String networkBlockCount(int count) {
    return '$count نیٹ ورک بلاکس';
  }

  @override
  String get neutral => 'غیر جانبدار';

  @override
  String get newCommitsPushed =>
      'نئے کمیٹس پش ہوئے — diff دوبارہ لوڈ کرنے کے لیے کلک کریں';

  @override
  String get newFact => 'نیا فیکٹ';

  @override
  String get newPolicy => 'نئی پالیسی';

  @override
  String get newsfeed => 'نیوز فیڈ';

  @override
  String get newsfeedLabel => 'نیوز فیڈ';

  @override
  String get newsfeedSettingsDescription =>
      'اپنی سبسکرائب شدہ فیڈز اور ریڈر ترجیحات منظم کریں۔';

  @override
  String get newsfeedSettingsTitle => 'نیوز فیڈ ترتیبات';

  @override
  String get nextMatch => 'اگلا میچ (↵)';

  @override
  String get noActiveWorkspace => 'کوئی فعال ورک اسپیس یا ریپو منتخب نہیں۔';

  @override
  String get noActiveWorkspaceCreate => 'کوئی فعال ورک اسپیس نہیں';

  @override
  String get noActiveWorkspaceGithub =>
      'GitHub ریپو والا کوئی فعال ورک اسپیس نہیں۔';

  @override
  String get noAgents => 'کوئی ایجنٹ نہیں';

  @override
  String get noArticlesYet => 'ابھی کوئی مضمون نہیں';

  @override
  String get noArticlesYetBody => 'آپ کی فیڈز کے مضامین یہاں نظر آئیں گے۔';

  @override
  String get noExecutionLogsYet => 'ابھی کوئی عمل درآمد لاگز نہیں';

  @override
  String get noFacts => 'ابھی کوئی فیکٹ نہیں';

  @override
  String get noFeedsYet => 'ابھی کوئی فیڈ نہیں';

  @override
  String get noFileAnchor =>
      'کوئی فائل اینکر نہیں — ان لائن تبصرہ پوسٹ نہیں ہو سکتا۔';

  @override
  String get noFileChangesInScope => 'اس دائرے میں کوئی فائل تبدیلی نہیں';

  @override
  String get noGifsFound => 'کوئی GIF نہیں ملا';

  @override
  String get noInputDevicesDetected =>
      'کوئی ان پٹ ڈیوائس نہیں ملی — سسٹم ڈیفالٹ استعمال ہو رہا ہے۔';

  @override
  String get noMatchingFiles => 'کوئی مماثل فائل نہیں';

  @override
  String get noMatchingGoogleFonts => 'کوئی مماثل Google Fonts نہیں۔';

  @override
  String get noMemoryData => 'ابھی کوئی میموری ڈیٹا نہیں';

  @override
  String get noMessagesYet => 'ابھی کوئی پیغام نہیں';

  @override
  String get noModelsAdvertised => 'اس اڈاپٹر نے کوئی ماڈل نہیں بتایا۔';

  @override
  String get noOpenPullRequests => 'کوئی کھلا pull request نہیں';

  @override
  String get noPolicies => 'ابھی کوئی پالیسی نہیں';

  @override
  String get noReposInWorkspaceYet =>
      'اس ورک اسپیس میں ابھی کوئی ریپوزٹری نہیں';

  @override
  String get noRunnersDetected =>
      'ابھی کوئی رنر نہیں ملا۔ دوبارہ اسکین کے لیے تازہ کریں۔';

  @override
  String get noSavedArticles => 'کوئی محفوظ مضمون نہیں';

  @override
  String get noSavedArticlesBody =>
      'جو مضامین آپ محفوظ کریں گے وہ یہاں نظر آئیں گے۔';

  @override
  String get noSystemFonts => 'کوئی سسٹم فونٹ نہیں ملا۔';

  @override
  String get noWorkingMemory => 'ابھی کوئی ورکنگ میموری نوٹس نہیں۔';

  @override
  String get noneAllRoles => 'کوئی نہیں (تمام کردار)';

  @override
  String get notAvailable => 'دستیاب نہیں';

  @override
  String get notConfiguredLabel => 'کنفیگر نہیں۔';

  @override
  String get notFoundLabel => 'نہیں ملا';

  @override
  String get notes => 'نوٹس';

  @override
  String get notificationAgentFinished => 'ایجنٹ ختم ہوا';

  @override
  String get notificationPrMentioned => 'pull request میں ذکر';

  @override
  String get notificationNewMessages => 'نئے پیغامات';

  @override
  String get notificationPrMerged => 'PR مرج ہو گیا';

  @override
  String get notificationPrPublished => 'PR شائع ہوا';

  @override
  String get notificationReviewRequested => 'ریویو کی درخواست';

  @override
  String get notifications => 'اطلاعات';

  @override
  String get notifyAgentRunCompleted => 'جب ایجنٹ رن مکمل کرے تو مطلع کریں۔';

  @override
  String get notifyPrMentioned =>
      'جب آپ کا ذکر pull request میں ہو تو مطلع کریں۔';

  @override
  String get notifyNewMessages => 'جب کسی اسپیس میں آپ کا ذکر ہو تو مطلع کریں۔';

  @override
  String get notifyPrMerged => 'جب pull request مرج ہو تو مطلع کریں۔';

  @override
  String get notifyPrPublished =>
      'جب ایجنٹ pull request شائع کرے تو مطلع کریں۔';

  @override
  String get notifyReviewRequested =>
      'جب آپ کے ریویو کی درخواست pull request پر ہو تو مطلع کریں۔';

  @override
  String get notificationReviewStale => 'ریویو پرانا';

  @override
  String get notifyReviewStale =>
      'جب نئے کمیٹس اس pull request پر آئیں جس کا آپ نے پہلے ریویو کیا';

  @override
  String get notificationPrMergeReadiness => 'مرج کے لیے تیار';

  @override
  String get notifyPrMergeReadiness =>
      'جب آپ کا لکھا pull request مرج کے قابل بنے، یا رہے۔';

  @override
  String get notificationPrReviewDecision => 'ریویو فیصلے';

  @override
  String get notifyPrReviewDecision =>
      'جب ریویوور منظور کرے، تبدیلیاں مانگے، یا منظوری برطرف ہو۔';

  @override
  String get notificationPrChecksStatus => 'چیکس';

  @override
  String get notifyPrChecksStatus =>
      'جب آپ کے لکھے pull request پر CI ناکام ہو، اور جب بحال ہو۔';

  @override
  String get notificationPrThreadActivity => 'ریویو تھریڈز';

  @override
  String get notifyPrThreadActivity =>
      'جب کوئی آپ کے تھریڈ میں جواب دے یا اسے حل کرے۔';

  @override
  String get notificationPrReadyToMerge => 'مرج کے لیے تیار';

  @override
  String notificationPrReadyToMergeBody(String prTitle) {
    return '⁨$prTitle⁩ کے پاس سب کچھ ہے۔';
  }

  @override
  String get notificationPrMergeBlocked => 'اب مرج کے قابل نہیں';

  @override
  String notificationPrMergeBlockedBodyConflicts(String prTitle) {
    return '⁨$prTitle⁩ بیس برانچ سے کنفلکٹ کرتا ہے۔';
  }

  @override
  String notificationPrMergeBlockedBodyBehind(String prTitle) {
    return '⁨$prTitle⁩ بیس برانچ سے پیچھے ہے۔';
  }

  @override
  String notificationPrMergeBlockedBodyReviews(String prTitle) {
    return '⁨$prTitle⁩ ضروری ریویو کا انتظار کر رہا ہے۔';
  }

  @override
  String notificationPrMergeBlockedBodyChanges(String prTitle) {
    return 'ایک ریویوور نے ⁨$prTitle⁩ پر تبدیلیاں مانگیں۔';
  }

  @override
  String notificationPrMergeBlockedBodyChecks(String prTitle) {
    return '⁨$prTitle⁩ پر چیکس ناکام ہو رہے ہیں۔';
  }

  @override
  String notificationPrMergeBlockedBodyOther(String prTitle) {
    return '⁨$prTitle⁩ اب مرج نہیں ہو سکتا۔';
  }

  @override
  String get notificationPrApproved => 'Pull request منظور';

  @override
  String notificationPrApprovedBodyBy(String login, String prTitle) {
    return '⁨$login⁩ نے ⁨$prTitle⁩ منظور کیا';
  }

  @override
  String notificationPrApprovedBody(String prTitle) {
    return '⁨$prTitle⁩ منظور ہو گیا';
  }

  @override
  String notificationPrReviewersRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ریویوورز کا جواب باقی',
      one: '1 ریویوور کا جواب باقی',
      zero: 'کوئی ریویوور باقی نہیں',
    );
    return '$_temp0';
  }

  @override
  String get notificationPrChangesRequested => 'تبدیلیاں مانگی گئیں';

  @override
  String notificationPrChangesRequestedBodyBy(String login, String prTitle) {
    return '⁨$login⁩ نے ⁨$prTitle⁩ پر تبدیلیاں مانگیں';
  }

  @override
  String notificationPrChangesRequestedBody(String prTitle) {
    return '⁨$prTitle⁩ پر تبدیلیاں مانگی گئیں';
  }

  @override
  String get notificationPrReviewDismissed => 'منظوری برطرف';

  @override
  String notificationPrReviewDismissedBody(String prTitle) {
    return '⁨$prTitle⁩ کو دوبارہ ریویو چاہیے۔';
  }

  @override
  String get notificationPrChecksFailed => 'چیکس ناکام';

  @override
  String notificationPrChecksFailedBody(String checkName, String prTitle) {
    return '⁨$checkName⁩ ⁨$prTitle⁩ پر ناکام';
  }

  @override
  String notificationPrChecksFailedBodyUnnamed(String prTitle) {
    return '⁨$prTitle⁩ پر چیکس ناکام ہو رہے ہیں';
  }

  @override
  String get notificationPrChecksRecovered => 'چیکس پاس';

  @override
  String notificationPrChecksRecoveredBody(String prTitle) {
    return '⁨$prTitle⁩ پھر سبز ہے۔';
  }

  @override
  String notificationPrMentionedInCommentBody(String login, String location) {
    return '⁨$login⁩ نے آپ کا ذکر ⁨$location⁩ میں کیا';
  }

  @override
  String get notificationPrThreadReplied => 'نیا جواب';

  @override
  String notificationPrThreadRepliedBody(String login, String location) {
    return '⁨$login⁩ نے ⁨$location⁩ میں جواب دیا';
  }

  @override
  String get notificationPrThreadResolved => 'تھریڈ حل ہوا';

  @override
  String notificationPrThreadResolvedBody(String location) {
    return '⁨$location⁩ میں آپ کا تھریڈ حل ہو گیا۔';
  }

  @override
  String get notificationGroupAgents => 'ایجنٹس';

  @override
  String get notificationGroupPullRequests => 'Pull requests';

  @override
  String get notificationGroupMessages => 'پیغامات';

  @override
  String get notificationGroupTickets => 'ٹکٹس';

  @override
  String get notificationGroupCalendar => 'کیلنڈر';

  @override
  String get notificationGroupMachines => 'مشینیں';

  @override
  String get notificationSectionSound => 'آواز';

  @override
  String get notificationSectionSchedule => 'شیڈول';

  @override
  String get notificationSectionEvents => 'واقعات';

  @override
  String get notificationsMutedRepos => 'خاموش ریپوزٹریز';

  @override
  String notificationsMutedReposCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ریپوزٹریز خاموش',
      one: '1 ریپوزٹری خاموش',
      zero: 'کوئی ریپوزٹری خاموش نہیں',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMuteRepo => 'اس ریپوزٹری کو خاموش کریں';

  @override
  String get onboardingLinuxDescription =>
      'Control Center ایجنٹ عمل درآمد الگ کرنے کے لیے Linux کنٹینرز استعمال کر سکتا ہے۔';

  @override
  String get onboardingMacosDescription =>
      'Control Center macOS پر ایجنٹ عمل درآمد الگ کرنے کے لیے نیٹو سینڈ باکس استعمال کرتا ہے۔';

  @override
  String get onboardingUnsupportedDescription =>
      'اس پلیٹ فارم پر سینڈ باکس دستیاب نہیں۔ ایجنٹ عمل درآمد بغیر علیحدگی کے ہو گا۔';

  @override
  String get openArticlesInApp => 'مضامین ایپ میں کھولیں';

  @override
  String get openInBrowser => 'براؤزر میں کھولیں';

  @override
  String get openedInYourBrowser => 'آپ کے براؤزر میں کھل گیا۔';

  @override
  String get openLabel => 'کھولیں';

  @override
  String get openOnGithub => 'GitHub پر کھولیں';

  @override
  String get openStatus => 'کھلا';

  @override
  String get optionalPersonaDescription => 'اختیاری شخصیت کی تفصیل';

  @override
  String get otherLabel => 'دیگر';

  @override
  String get ownerOrganization => 'مالک / آرگنائزیشن';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get passed => 'پاس';

  @override
  String get pasteValueHere => 'ویلیو یہاں پیسٹ کریں';

  @override
  String get persona => 'شخصیت';

  @override
  String get policies => 'پالیسیاں';

  @override
  String get policiesHint =>
      'ایجنٹس فیکٹس کو فروغ دیں تو پالیسیاں یہاں نظر آئیں گی۔';

  @override
  String get policy => 'پالیسی';

  @override
  String get popular => 'مقبول';

  @override
  String get port => 'پورٹ';

  @override
  String get postingEllipsis => 'پوسٹ ہو رہا ہے…';

  @override
  String get prCommits => 'کمیٹس';

  @override
  String get prMergedBody => 'ایک pull request مرج ہو گیا';

  @override
  String get prMoreActions => 'مزید ایکشنز';

  @override
  String get prTitle => 'PR عنوان';

  @override
  String get reviewCommentHint =>
      'بس منظور پر کلک کریں، یا اگر جی چاہے تو تبصرہ یا ردعمل شامل کریں…';

  @override
  String get nothingToPreview => 'پیش منظر کے لیے کچھ نہیں';

  @override
  String get previousMatch => 'پچھلا میچ (⇧↵)';

  @override
  String get priorityReviewsDescription => 'ترجیحی ریویوز اور ریپوزٹری جائزہ۔';

  @override
  String get prsCreated => 'بنائے گئے PRs';

  @override
  String get prsMerged => 'مرج شدہ PRs';

  @override
  String get publishToGithub => 'GitHub پر شائع کریں';

  @override
  String get published => 'شائع شدہ';

  @override
  String get pullRequestApproved => 'Pull request منظور';

  @override
  String get pullRequests => 'Pull requests';

  @override
  String get questionLabel => 'سوال';

  @override
  String get queued => 'قطار میں';

  @override
  String get react => 'ردعمل';

  @override
  String get readerPreferences => 'ریڈر ترجیحات';

  @override
  String get reasoningEffort => 'ریزننگ کا زور';

  @override
  String get recommendLabel => 'تجویز';

  @override
  String recordingFromDevice(String device) {
    return '⁨$device⁩ سے ریکارڈ ہو رہا ہے۔';
  }

  @override
  String get redownload => 'دوبارہ ڈاؤن لوڈ';

  @override
  String get redownloadEmbeddingModel => 'ایمبیڈنگ ماڈل دوبارہ ڈاؤن لوڈ کریں؟';

  @override
  String get redownloadVoiceModel => 'وائس ماڈل دوبارہ ڈاؤن لوڈ کریں؟';

  @override
  String get refinePlan => 'پلان بہتر کریں';

  @override
  String get refresh => 'تازہ کریں';

  @override
  String get refreshAll => 'سب تازہ کریں';

  @override
  String get refreshAllFeeds => 'تمام فیڈز تازہ کریں';

  @override
  String get reject => 'مسترد کریں';

  @override
  String get rejected => 'مسترد';

  @override
  String get reload => 'دوبارہ لوڈ';

  @override
  String get remove => 'ہٹائیں';

  @override
  String get removeBookmark => 'بک مارک ہٹائیں';

  @override
  String get removeEmbeddingModel => 'ایمبیڈنگ ماڈل ہٹائیں؟';

  @override
  String get removeLogo => 'لوگو ہٹائیں';

  @override
  String get removeRepoFromWorkspace => 'ریپوزٹری ورک اسپیس سے ہٹائیں؟';

  @override
  String get removeVoiceModel => 'وائس ماڈل ہٹائیں؟';

  @override
  String get removed => 'ہٹایا گیا';

  @override
  String get renamed => 'نام بدلا گیا';

  @override
  String get reopen => 'دوبارہ کھولیں';

  @override
  String get resolve => 'حل کریں';

  @override
  String get replyEllipsis => 'جواب…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '⁨$name⁩ اس ورک اسپیس سے ہٹ جائے گی۔ ڈسک پر مقامی فائلیں نہیں چھوتیں۔';
  }

  @override
  String get repoNoAccessBadge => 'رسائی نہیں';

  @override
  String get reportsTo => 'رپورٹ کرتا ہے';

  @override
  String reposCount(int count) {
    return 'ریپوزٹریز ($count)';
  }

  @override
  String get reposDescription => 'اس ورک اسپیس کے مقامی چیک آؤٹس۔';

  @override
  String get repositories => 'ریپوزٹریز';

  @override
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ریپوزٹریز',
      one: '1 ریپوزٹری',
    );
    return '$_temp0 شامل نہیں ہو سکیں: ⁨$error⁩';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ریپوزٹریز شامل ہو گئیں',
      one: 'ریپوزٹری شامل ہو گئی',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => 'ریپوزٹریز ترتیبات';

  @override
  String get repositoryName => 'ریپوزٹری کا نام';

  @override
  String get requestChanges => 'تبدیلیاں مانگیں';

  @override
  String get requested => 'درخواست شدہ';

  @override
  String get requestedChanges => 'مانگی گئی تبدیلیاں';

  @override
  String requiredRoleLabel(String role) {
    return 'ضروری کردار: $role';
  }

  @override
  String get requiredRoleOptional => 'ضروری کردار (اختیاری)';

  @override
  String get requirements => 'ضروریات';

  @override
  String get reset => 'ری سیٹ';

  @override
  String get resolved => 'حل شدہ';

  @override
  String get enclosedTerminalTitle => 'بند ٹرمینل';

  @override
  String get enclosedTerminalStart => 'شیل کھولیں';

  @override
  String get enclosedTerminalStartHint =>
      'یہ شیل اس گفتگو کے عارضی VM کے اندر چلتا ہے۔ کھولنے پر بوٹ ہوتا ہے، ایپ شروع ہونے پر نہیں۔';

  @override
  String get terminalStreamReconnecting =>
      'اسٹریم ٹوٹ گئی — دوبارہ منسلک ہو رہا ہے…';

  @override
  String get terminalStreamError => 'اسٹریم خرابی:';

  @override
  String get terminalShellExited => 'شیل ختم ہو گیا';

  @override
  String get restartShell => 'شیل دوبارہ شروع کریں';

  @override
  String get retry => 'دوبارہ کوشش';

  @override
  String get review => 'ریویو';

  @override
  String get reviewedByMe => 'میرے ریویو شدہ';

  @override
  String get reviewers => 'ریویوورز';

  @override
  String get roleLabel => 'کردار';

  @override
  String get ruleHint => 'پالیسی قاعدہ (markdown معاون)';

  @override
  String get ruleLabel => 'قاعدہ';

  @override
  String get running => 'چل رہا ہے';

  @override
  String get runningLabel => 'چل رہا ہے';

  @override
  String get runs => 'رنز';

  @override
  String get runsLabel => 'رنز';

  @override
  String get sandboxBackendNativeLabel => 'نیٹو سینڈ باکس';

  @override
  String get sandboxBackendMicrovmLabel => 'بند VM';

  @override
  String get sandboxBackendNoneLabel => 'کوئی علیحدگی نہیں';

  @override
  String get sandboxLinuxInstall =>
      'Linux/WSL2 پر نیٹو سینڈ باکس ⁨bubblewrap⁩ استعمال کرتا ہے۔ انسٹال کریں:\n\n  ⁨sudo apt-get install bubblewrap socat ripgrep⁩   # Debian/Ubuntu\n  ⁨sudo dnf install bubblewrap socat ripgrep⁩       # Fedora/RHEL\n  ⁨sudo pacman -S bubblewrap socat ripgrep⁩         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'نیٹو سینڈ باکس macOS پر بلٹ اِن ہے — Apple Seatbelt (`sandbox-exec`) استعمال کرتا ہے۔ انسٹال کی ضرورت نہیں۔';

  @override
  String get sandboxUnsupported =>
      'اس پلیٹ فارم پر نیٹو سینڈ باکس ابھی معاون نہیں۔ \"کوئی علیحدگی نہیں\" پر واپس جاتا ہے۔';

  @override
  String get sandboxingDisabledDescription =>
      'ایجنٹس ہوسٹ پر پوری env کے ساتھ براہِ راست چلتے ہیں — تجویز نہیں۔';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'تمام ایجنٹ کالز ⁨$backend⁩ سے گزرتی ہیں۔';
  }

  @override
  String get save => 'محفوظ کریں';

  @override
  String get saveChanges => 'تبدیلیاں محفوظ کریں';

  @override
  String get adapterArguments => 'اضافی آرگومنٹس';

  @override
  String get adapterArgumentsHint => 'اضافی CLI فلیگز (مثلاً ⁨--yolo⁩)';

  @override
  String get addVariable => 'ویری ایبل شامل کریں';

  @override
  String get environmentVariables => 'ماحول کے ویری ایبلز';

  @override
  String get environmentVariablesDescription =>
      'اس اڈاپٹر کو دیے گئے حسبِ ضرورت ماحول کے ویری ایبلز (مثلاً API کلیدیں)۔ کی چین میں محفوظ۔';

  @override
  String get variableKey => 'کلید';

  @override
  String get variableValue => 'ویلیو';

  @override
  String get savingEllipsis => 'محفوظ ہو رہا ہے…';

  @override
  String get scopeDiffToCommits =>
      'Diff کو کمیٹس تک محدود کریں — رینج کے لیے Shift-کلک';

  @override
  String get noPrsMatchSearch => 'کوئی مماثل pull request نہیں';

  @override
  String get searchFactsHint => 'فیکٹس تلاش کریں...';

  @override
  String get searchFonts => 'فونٹس تلاش کریں…';

  @override
  String get searchGifs => 'GIFs تلاش کریں';

  @override
  String get searchGifsHint => 'KLIPY میں تلاش کریں';

  @override
  String get searchInDiffHint => 'Diff میں تلاش…';

  @override
  String get searchOrTypeModel => 'ماڈل نام تلاش کریں یا ٹائپ کریں…';

  @override
  String get searchPlaceholder => 'تلاش…';

  @override
  String get searching => 'تلاش ہو رہی ہے…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سیکنڈ پہلے',
      one: '1 سیکنڈ پہلے',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'اڈاپٹر منتخب کریں';

  @override
  String get selectAdapterFirst => 'پہلے اڈاپٹر منتخب کریں';

  @override
  String get selectAgentToReportTo => 'رپورٹ کرنے کے لیے ایجنٹ منتخب کریں…';

  @override
  String get selectAnAgent => 'ایجنٹ منتخب کریں';

  @override
  String get selectConversation => 'گفتگو منتخب کریں';

  @override
  String get selectLabel => 'منتخب کریں';

  @override
  String get selectRunner => 'رنر منتخب کریں';

  @override
  String get semanticSearch => 'سیمانٹک تلاش';

  @override
  String get send => 'بھیجیں';

  @override
  String get sendFirstMessage => 'پہلا پیغام بھیجیں';

  @override
  String get sendMessage => 'پیغام بھیجیں';

  @override
  String sentFindingsToAgent(int count) {
    return '$count نتیجہ(نتائج) ایجنٹ کو بھیجے گئے۔';
  }

  @override
  String setGithubLinkDescription(String name) {
    return '⁨$name⁩ کے لیے GitHub مالک اور ریپوزٹری نام سیٹ کریں۔ یہ markdown میں ⁨#123⁩ جیسے PR اور ایشو حوالے حل کرنے کے لیے استعمال ہوتا ہے۔';
  }

  @override
  String get setLabel => 'سیٹ کریں';

  @override
  String get settingsLabel => 'ترتیبات';

  @override
  String get settingsLanguage => 'زبان';

  @override
  String get settingsLanguageDescription => 'ایپ کی زبان منتخب کریں۔';

  @override
  String get showNativeNotifications => 'ایونٹس کے لیے سسٹم اطلاعات دکھائیں۔';

  @override
  String get showSuperseded => 'منسوخ شدہ دکھائیں';

  @override
  String get signedIn => 'سائن اِن۔';

  @override
  String signedInAs(String username) {
    return '⁨$username⁩ کے طور پر سائن اِن۔';
  }

  @override
  String get skillNameRequired => 'مہارت کا نام ضروری ہے۔';

  @override
  String skillSaved(String name) {
    return 'مہارت \"⁨$name⁩\" محفوظ ہو گئی۔';
  }

  @override
  String get skillsSourcesTab => 'ذرائع';

  @override
  String get skillSourcesDisclaimer =>
      'مہارتیں آپ کی شامل کردہ GitHub ریپوزٹریز سے انسٹال ہوتی ہیں۔ ریپوزٹری میٹا ڈیٹا غیر معتبر ہے — اینٹی وائرس اسکین اصل حفاظتی اشارہ ہے۔';

  @override
  String get skillSourcesEmpty => 'کوئی مہارت ریپوزٹری نہیں';

  @override
  String get skillSourcesEmptyHint =>
      'مہارتیں دیکھنے کے لیے GitHub ریپوزٹری شامل کریں۔';

  @override
  String get skillSourceAdd => 'ریپوزٹری شامل کریں';

  @override
  String get skillSourceAddTitle => 'مہارت ریپوزٹری شامل کریں';

  @override
  String get skillSourceAddHint => 'https://github.com/owner/repo';

  @override
  String get skillSourceInvalidUrl =>
      'GitHub ریپوزٹری URL درج کریں (⁨https://github.com/owner/repo⁩)۔';

  @override
  String skillSourceAdded(String repo) {
    return 'ریپوزٹری ⁨$repo⁩ شامل ہو گئی۔';
  }

  @override
  String skillSourceAlreadyAdded(String repo) {
    return 'ریپوزٹری ⁨$repo⁩ پہلے سے شامل ہے۔';
  }

  @override
  String skillSourceRemoved(String repo) {
    return 'ریپوزٹری ⁨$repo⁩ ہٹا دی گئی۔';
  }

  @override
  String get skillSourceRemove => 'ہٹائیں';

  @override
  String skillSourceRemoveConfirmTitle(String repo) {
    return '⁨$repo⁩ ہٹائیں؟';
  }

  @override
  String get skillSourceRemoveConfirmBody =>
      'انسٹال مہارتیں انسٹال رہتی ہیں۔ صرف ریپوزٹری کیٹلاگ ہٹتا ہے۔';

  @override
  String get skillSourceNoSkills =>
      'اس ریپوزٹری میں کوئی مہارت نہیں ملی (مہارت وہ ڈائریکٹری ہے جس میں ⁨SKILL.md⁩ ہو)۔';

  @override
  String get skillSourceRefresh => 'تازہ کریں';

  @override
  String get skillSourceInstalledBadge => 'انسٹال شدہ';

  @override
  String get skillSourceUpdateBadge => 'اپ ڈیٹ دستیاب';

  @override
  String get skillSourceSlugTaken => 'نام استعمال میں ہے';

  @override
  String skillSourceFilesCount(num count) {
    return '$count فائلیں';
  }

  @override
  String get skillSourceReadme => 'README';

  @override
  String get skillSourceNoReadme => 'اس مہارت کا کوئی README نہیں۔';

  @override
  String get skillSourceNoMatches => 'آپ کے فلٹر سے کوئی مہارت میل نہیں کھاتی۔';

  @override
  String get skillUpdateAction => 'اپ ڈیٹ';

  @override
  String get skillUninstallAction => 'ان انسٹال';

  @override
  String skillUninstallConfirmTitle(String slug) {
    return '\"⁨$slug⁩\" ان انسٹال کریں؟';
  }

  @override
  String skillUninstalled(String slug) {
    return 'مہارت \"⁨$slug⁩\" ان انسٹال ہو گئی۔';
  }

  @override
  String get skillFindingLine => 'لائن';

  @override
  String get skillInstallAnywayOverride =>
      'میں خطرہ سمجھتا ہوں — پھر بھی انسٹال کریں';

  @override
  String skillInstalled(String slug) {
    return 'مہارت \"⁨$slug⁩\" انسٹال ہو گئی۔';
  }

  @override
  String get skillPreviewCapabilities => 'صلاحیتیں';

  @override
  String get skillPreviewFindings => 'نتائج';

  @override
  String get skillPreviewGuardedActions => 'محفوظ ایکشنز';

  @override
  String get skillPreviewLlmReviewed => 'LLM-ریویو شدہ';

  @override
  String get skillPreviewNoCapabilities => 'کوئی صلاحیت بیان نہیں۔';

  @override
  String get skillPreviewNoFindings => 'کوئی نتیجہ نہیں۔';

  @override
  String get skillPreviewScanning => 'مہارت اسکین ہو رہی ہے…';

  @override
  String get skillPreviewVerdictLabel => 'اسکین فیصلہ';

  @override
  String get skillPreviewVerdictPass => 'پاس';

  @override
  String get skillPreviewVerdictQuarantine => 'قرنطینہ';

  @override
  String get skillPreviewVerdictWarn => 'تنبیہ';

  @override
  String get skillQuarantineWarning =>
      'اسکینر نے اس مہارت کو قرنطینہ کیا۔ انسٹال کرنے سے آپ کی مشین پر کوڈ چلتا ہے۔ صرف اس صورت میں جاری رکھیں جب آپ ماخذ پر بھروسہ کریں اور نتائج دیکھ چکے ہوں۔';

  @override
  String skillDetachedFromAgents(String agents) {
    return 'قرنطینہ اور ایجنٹس سے الگ: ⁨$agents⁩';
  }

  @override
  String get skillNotScanned => 'اسکین نہیں ہوا';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => 'دستی';

  @override
  String get skillOriginRuntimeLocal => 'رن ٹائم مقامی';

  @override
  String get skillRulesStale => 'اسکین پرانا';

  @override
  String get skillSaveAnywayOverride =>
      'میں خطرہ سمجھتا ہوں — پھر بھی محفوظ کریں';

  @override
  String get skillSaveBlockedBody => 'لکھنے سے پہلے مواد روک دیا گیا۔';

  @override
  String get skillSaveBlockedTitle => 'اسکین گیٹ نے محفوظ کرنا روکا';

  @override
  String get skillScanAction => 'اسکین';

  @override
  String get skillScanAll => 'سب اسکین کریں';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass پاس · $warn تنبیہات · $quarantine قرنطینہ';
  }

  @override
  String get skillStateDrifted => 'انسٹال کے بعد تبدیل';

  @override
  String get skillStateUnmanaged => 'غیر منظم';

  @override
  String get skillSeverityBlocked => 'بلاک';

  @override
  String get skillSeverityWarn => 'تنبیہ';

  @override
  String get skillsInstalledTab => 'انسٹال شدہ';

  @override
  String get skills => 'مہارتیں';

  @override
  String get skipAcceptRisk => 'چھوڑیں — میں خطرہ قبول کرتا ہوں';

  @override
  String get skipForNow => 'ابھی چھوڑیں';

  @override
  String get skipSandboxing => 'سینڈ باکسنگ چھوڑیں';

  @override
  String get skipSandboxingDialogContent =>
      'کیا آپ واقعی سینڈ باکسنگ چھوڑنا چاہتے ہیں؟ اس سے ایجنٹس بغیر علیحدگی کے آپ کے سسٹم پر کوڈ چلا سکتے ہیں۔';

  @override
  String get somethingWentWrong => 'کچھ غلط ہو گیا';

  @override
  String sourceCount(int count) {
    return '$count ماخذ';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count ذرائع';
  }

  @override
  String get sourceFacts => 'ماخذ فیکٹس:';

  @override
  String get splitDiff => 'تقسیم (ساتھ ساتھ) diff';

  @override
  String get startLabel => 'شروع';

  @override
  String get startOnAppLaunch => 'ایپ لانچ پر شروع کریں';

  @override
  String get statusLabel => 'اسٹیٹس';

  @override
  String get onboardingStepConnect => 'منسلک کریں';

  @override
  String get onboardingStepWorkspace => 'ورک اسپیس';

  @override
  String get onboardingStepSandbox => 'سینڈ باکس';

  @override
  String get onboardingStepAdapter => 'اڈاپٹر';

  @override
  String get onboardingStepVoice => 'آواز';

  @override
  String get stop => 'روکیں';

  @override
  String get stopped => 'رک گیا';

  @override
  String get strictIdentityCheck => 'سخت شناخت چیک';

  @override
  String get success => 'کامیابی';

  @override
  String get successLabel => 'کامیابی';

  @override
  String get suggestion => 'تجویز';

  @override
  String get suggestLabel => 'تجویز';

  @override
  String get superseded => 'منسوخ شدہ';

  @override
  String get synced => 'سنک شدہ';

  @override
  String get systemDefault => 'سسٹم ڈیفالٹ';

  @override
  String get systemFonts => 'سسٹم فونٹس';

  @override
  String get systemPrompt => 'سسٹم پرامپٹ';

  @override
  String get systemPromptLabel => 'سسٹم پرامپٹ';

  @override
  String get talkToControlCenter => 'Control Center سے بات کریں۔';

  @override
  String get taskMentionSection => 'کام';

  @override
  String get testLabel => 'ٹیسٹ';

  @override
  String get theme => 'تھیم';

  @override
  String get themeDark => 'تاریک';

  @override
  String get themeLight => 'روشن';

  @override
  String get themeSystem => 'سسٹم';

  @override
  String get thisCannotBeUndone => 'یہ واپس نہیں ہو سکتا۔';

  @override
  String get ticketLabel => 'ٹکٹ';

  @override
  String get titleLabel => 'عنوان';

  @override
  String get todayLabel => 'آج';

  @override
  String get toggleTheme => 'تھیم ٹوگل کریں';

  @override
  String get topic => 'موضوع';

  @override
  String get topicHint => 'مثال: ٹیک اسٹیک، ڈیزائن سسٹم';

  @override
  String get totalRuns => 'کل رنز';

  @override
  String trackingParamsCount(int count) {
    return '$count ٹریکنگ پیرامز';
  }

  @override
  String get typeCommandOrSearch => 'کمانڈ ٹائپ کریں یا تلاش کریں…';

  @override
  String get typography => 'ٹائپوگرافی';

  @override
  String get unavailable => 'دستیاب نہیں';

  @override
  String get unifiedDiff => 'یکجا diff';

  @override
  String get unknownAuthor => 'نامعلوم';

  @override
  String get unnamedAgent => 'بے نام ایجنٹ';

  @override
  String get updateLabel => 'اپ ڈیٹ';

  @override
  String get updateToken => 'ٹوکن اپ ڈیٹ کریں';

  @override
  String updatedDaysAgo(int count) {
    return '$countد پہلے اپ ڈیٹ';
  }

  @override
  String updatedHoursAgo(int count) {
    return '$countگھ پہلے اپ ڈیٹ';
  }

  @override
  String get updatedJustNow => 'ابھی اپ ڈیٹ ہوا';

  @override
  String updatedMinutesAgo(int count) {
    return '$countمنٹ پہلے اپ ڈیٹ';
  }

  @override
  String get useSandbox => 'سینڈ باکس استعمال کریں';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      'ڈیفالٹ ایپ User-Agent کے لیے خالی چھوڑیں۔ کچھ سائٹس غیر براؤزر User-Agents بلاک کرتی ہیں۔';

  @override
  String get usingSystemDefaultMicrophone =>
      'سسٹم ڈیفالٹ مائیکروفون استعمال ہو رہا ہے۔';

  @override
  String get viewLabel => 'دیکھیں';

  @override
  String get viewLogs => 'لاگز دیکھیں';

  @override
  String voiceInstallFailed(String error) {
    return 'انسٹال ناکام: ⁨$error⁩';
  }

  @override
  String get voiceModelNotInstalled =>
      'انسٹال نہیں۔ ایک بار ~200 MB ڈاؤن لوڈ؛ مکمل طور پر ڈیوائس پر چلتا ہے۔';

  @override
  String get voiceModelNotInstalledLabel => 'وائس ماڈل انسٹال نہیں۔';

  @override
  String get voiceRedownloadBody =>
      'موجودہ ماڈل فائلیں حذف ہو کر ~200 MB آرکائیو دوبارہ ڈاؤن لوڈ ہوگا۔ ڈاؤن لوڈ مکمل ہونے تک وائس ٹرانسکرپشن دستیاب نہیں ہو گی۔';

  @override
  String get voiceRemoveBody =>
      'دوبارہ انسٹال کرنے تک وائس ٹرانسکرپشن بند رہے گی۔ آپ اسے کسی بھی وقت دوبارہ انسٹال کر سکتے ہیں۔';

  @override
  String get voiceTranscription => 'وائس ٹرانسکرپشن';

  @override
  String get weakIsolationDescription =>
      'کمزور علیحدگی — صرف نیم اسپیس حد، کوئی کرنل حد نہیں۔';

  @override
  String get whenOffServerStaysStopped =>
      'بند ہونے پر سرور اس وقت تک بند رہتا ہے جب تک آپ اسے شروع نہ کریں۔';

  @override
  String get speechModel => 'اسپیچ ماڈل';

  @override
  String get speechModelHint => 'میٹنگ ٹرانسکرپشن اور کمپوزر مائیک کے لیے۔';

  @override
  String get voiceModelInstalled =>
      'انسٹال شدہ۔ میٹنگ ٹرانسکرپشن اور کمپوزر مائیک بٹن چلاتا ہے۔';

  @override
  String get meetingMicSilentWarning =>
      'آپ کا مائیک خاموش ہو سکتا ہے — دوسرے بول رہے ہیں مگر آپ کے مائیکروفون تک کچھ نہیں پہنچ رہا۔';

  @override
  String get meetingSummaryPrivacyNotice =>
      'ریکارڈنگ اور ٹرانسکرپشن اس مشین پر رہتی ہے۔ خلاصہ ایجنٹ لکھتا ہے، اس لیے اگر وہ کلاؤڈ ماڈل استعمال کرے تو آپ کی ٹرانسکرپٹ اور نوٹس اس فراہم کنندہ کو بھیجے جاتے ہیں۔';

  @override
  String get meetingTemplates => 'میٹنگ نوٹ ٹیمپلیٹس';

  @override
  String get meetingTemplatesHint =>
      'میٹنگ کی قسم کے مطابق AI خلاصہ کی شکل دیں۔ فعال ٹیمپلیٹ نئے اور دوبارہ چلنے والے خلاصوں پر لاگو ہوتا ہے۔';

  @override
  String get meetingTemplateActive => 'فعال ٹیمپلیٹ';

  @override
  String get meetingTemplateAdd => 'ٹیمپلیٹ شامل کریں';

  @override
  String get meetingTemplateNewTitle => 'نیا ٹیمپلیٹ';

  @override
  String get meetingTemplateEditTitle => 'ٹیمپلیٹ میں ترمیم';

  @override
  String get meetingTemplateNameLabel => 'نام';

  @override
  String get meetingTemplateNameHint => 'مثال: سپرنٹ ریویو';

  @override
  String get meetingTemplateInstructionsLabel => 'ہدایات';

  @override
  String get meetingTemplateInstructionsHint =>
      'AI ان نوٹس کو کیسے ترتیب دے اور کس پر زور دے؟';

  @override
  String get workingMemory => 'ورکنگ میموری';

  @override
  String get workspaceName => 'ورک اسپیس کا نام';

  @override
  String get workspaceScopedSkills =>
      'ایجنٹس سے منسلک ورک اسپیس کی مہارت فائلیں۔';

  @override
  String get workspaces => 'ورک اسپیسز';

  @override
  String get writePrivateNotes => 'نجی نوٹس، مشاہدات، پلانز لکھیں...';

  @override
  String get writeSkillContent => 'اپنی مہارت کا مواد یہاں لکھیں (Markdown)…';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سال پہلے',
      one: '1 سال پہلے',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'کل';

  @override
  String get focusModeStart => 'فوکس سیشن شروع کریں';

  @override
  String get focusModeConfigTitle => 'فوکس سیشن شروع کریں';

  @override
  String get focusModeGoalLabel => 'ہدف';

  @override
  String get focusModeGoalHint => 'آپ کس پر کام کر رہے ہیں؟';

  @override
  String get focusModeDurationLabel => 'مدت';

  @override
  String get focusModeBlockNotifications => 'اطلاعات بلاک کریں';

  @override
  String get focusModeStartButton => 'شروع';

  @override
  String get focusModeFloat => 'بار پر چھوٹا کریں';

  @override
  String get dismiss => 'برطرف کریں';

  @override
  String get acceptAndResolve => 'قبول کریں اور حل کریں';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'آپ $minutesمنٹ سے ریویو کر رہے ہیں — تحقیق کے مطابق 60 منٹ کے بعد ریویو معیار گر سکتا ہے۔ وقفہ لیں۔';
  }

  @override
  String get notificationSound => 'اطلاع کی آواز';

  @override
  String get notificationSoundDescription => 'اطلاع دکھنے پر بجنے والی آواز۔';

  @override
  String get notificationSoundNone => 'کوئی نہیں';

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
  String get notificationSoundMigrosSoft => 'Migros (نرم)';

  @override
  String get notificationSoundMigrosHard => 'Migros (سخت)';

  @override
  String get notificationSoundSbb => 'SBB';

  @override
  String get notificationSoundCff => 'CFF';

  @override
  String get notificationSoundFfs => 'FFS';

  @override
  String get notificationSoundPost => 'Post';

  @override
  String get notificationSoundTest => 'ٹیسٹ';

  @override
  String get notificationVolume => 'والیوم';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'اس ورک اسپیس میں ⁨@$login⁩ کے کوئی PRs نہیں';
  }

  @override
  String get usersLabel => 'صارفین';

  @override
  String get mergePullRequest => 'pull request مرج کریں';

  @override
  String get forceMergePullRequest => 'pull request زبردستی مرج کریں';

  @override
  String get closePullRequest => 'pull request بند کریں';

  @override
  String get closePullRequestConfirm =>
      'کیا آپ واقعی یہ pull request بند کرنا چاہتے ہیں؟';

  @override
  String get stackedPullRequests => 'اسٹیک شدہ pull requests';

  @override
  String partOfStack(int position, int total) {
    return 'اسٹیک کا حصہ ($position از $total)';
  }

  @override
  String get createStack => 'اسٹیک بنائیں';

  @override
  String get createStackDialogTitle => 'pull request اسٹیک بنائیں';

  @override
  String createStackDialogBody(int count) {
    return 'یہ $count pull requests نیچے سے اوپر اسٹیک ہوں گے:';
  }

  @override
  String get createStackInvalidSelection =>
      'اسٹیک بنانے کے لیے ایک ہی ریپوزٹری سے کم از کم دو pull requests منتخب کریں';

  @override
  String get createStackNotAChain =>
      'منتخب pull requests زنجیر نہیں بناتے: ہر pull request کی بیس برانچ پچھلے کی ہیڈ برانچ ہونی چاہیے';

  @override
  String get createStackAlreadyStacked =>
      'ایک یا زیادہ منتخب pull requests پہلے سے اسٹیک میں ہیں';

  @override
  String get stackCreated => 'اسٹیک بن گیا';

  @override
  String get stackCreationFailed => 'اسٹیک نہیں بن سکا';

  @override
  String get squashAndMerge => 'Squash and merge';

  @override
  String get createMergeCommit => 'مرج کمیٹ بنائیں';

  @override
  String get rebaseAndMerge => 'Rebase and merge';

  @override
  String get mergeMethod => 'انضمام کا طریقہ';

  @override
  String get commitTitle => 'کمیٹ عنوان';

  @override
  String get commitDescription => 'کمیٹ تفصیل';

  @override
  String get pullRequestMerged => 'Pull request مرج ہو گیا';

  @override
  String get pullRequestClosed => 'Pull request بند ہو گیا';

  @override
  String failedToMergePr(String error) {
    return 'مرج ناکام: ⁨$error⁩';
  }

  @override
  String failedToClosePr(String error) {
    return 'بند نہیں ہو سکا: ⁨$error⁩';
  }

  @override
  String get markReadyForReview => 'ریویو کے لیے تیار';

  @override
  String get markReadyForReviewConfirm =>
      'یہ pull request ڈرافٹ چھوڑ دے گا۔ ریویوورز مطلع ہوں گے، ضروری چیکس مرج گیٹ کریں گے اور تیار pull requests دیکھنے والی آٹومیشن چلے گی۔';

  @override
  String get convertToDraft => 'ڈرافٹ میں تبدیل کریں';

  @override
  String get convertToDraftConfirm =>
      'یہ pull request دوبارہ ڈرافٹ ہو جائے گا۔ اس کی زیرِ التوا ریویو درخواستیں برطرف ہوں گی اور دوبارہ تیار نشان زد کرنے تک مرج نہیں ہو سکتا۔';

  @override
  String get pullRequestMarkedReady => 'Pull request ریویو کے لیے تیار نشان زد';

  @override
  String get pullRequestConvertedToDraft => 'Pull request ڈرافٹ میں تبدیل';

  @override
  String failedToMarkPrReady(String error) {
    return 'ریویو کے لیے تیار نشان زد نہیں ہو سکا: ⁨$error⁩';
  }

  @override
  String failedToConvertPrToDraft(String error) {
    return 'ڈرافٹ میں تبدیل نہیں ہو سکا: ⁨$error⁩';
  }

  @override
  String get checksFailing => 'چیکس ناکام';

  @override
  String get reviewsPending => 'کچھ ریویوز زیرِ التوا ہیں';

  @override
  String get mergeConflictsWithBase =>
      'اس برانچ میں کنفلکٹس ہیں جنہیں حل کرنا ضروری ہے';

  @override
  String get branchOutOfDateWithBase => 'یہ برانچ بیس برانچ سے پرانی ہے';

  @override
  String get mergeBlockedByBranchProtection =>
      'برانچ پروٹیکشن اس مرج کو روکتی ہے';

  @override
  String get confirm => 'تصدیق کریں';

  @override
  String get trustedSitesSectionTitle => 'قابلِ اعتماد سائٹس';

  @override
  String get trustedSitesEmpty =>
      'کوئی قابلِ اعتماد سائٹ نہیں۔ اس پر بلاکنگ بند کرنے کے لیے ڈومین شامل کریں۔';

  @override
  String get addTrustedSite => 'قابلِ اعتماد سائٹ شامل کریں';

  @override
  String get removeTrustedSite => 'ہٹائیں';

  @override
  String get disableBlockingForThisSite => 'اس سائٹ پر بلاکنگ بند کریں';

  @override
  String get enableBlockingForThisSite => 'اس سائٹ پر بلاکنگ فعال کریں';

  @override
  String get enterDomainHint => 'مثال: ⁨example.com⁩';

  @override
  String get invalidDomain => 'درست ڈومین درج کریں (مثلاً ⁨example.com⁩)';

  @override
  String get pageLoadTimedOut =>
      'صفحہ لوڈ کا وقت ختم۔ دوبارہ لوڈ کریں یا براؤزر میں کھولیں۔';

  @override
  String get pipelinesScreenTitle => 'پائپ لائنز';

  @override
  String get pipelinesScreenSubtitle => 'اعلانیہ کثیر مرحلہ ایجنٹ ورک فلو';

  @override
  String get pipelinesRunPipeline => 'پائپ لائن چلائیں';

  @override
  String get pipelineRunLauncherTitle => 'پائپ لائن چلائیں';

  @override
  String get pipelineRunSubtitle =>
      'پائپ لائن منتخب کریں اور رن شروع کرنے کے لیے اس کے ان پٹس بھریں۔';

  @override
  String get pipelineRunNoInputsBadge => 'کوئی ان پٹ نہیں';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ان پٹس',
      one: '1 ان پٹ',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'اس پائپ لائن کو کوئی ان پٹ نہیں چاہیے۔';

  @override
  String get pipelineRunSubmit => 'پائپ لائن چلائیں';

  @override
  String get pipelineRunCouldNotStart => 'رن شروع نہیں ہو سکا۔';

  @override
  String pipelineRunStarted(String name) {
    return '⁨$name⁩ شروع ہو گیا';
  }

  @override
  String get pipelineRunEmptyTitle => 'چلانے کے لیے کوئی پائپ لائن تیار نہیں';

  @override
  String get pipelineRunEmptyHint =>
      'پائپ لائن فعال کریں اور اس کے ایڈیٹر میں دستی رن آن کریں تاکہ یہاں لانچ ہو۔';

  @override
  String get pipelineRunManageTemplates => 'پائپ لائنز منظم کریں';

  @override
  String get pipelineRunSettingsTitle => 'دستی رن';

  @override
  String get pipelineRunSettingsAllow => 'دستی رن کی اجازت دیں';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'اس پائپ لائن کو رن صفحے پر دکھائیں تاکہ ہاتھ سے شروع ہو سکے۔';

  @override
  String get pipelineRunSettingsConcurrencyTitle => 'ہم وقتی';

  @override
  String get pipelineRunSettingsMaxParallel => 'زیادہ سے زیادہ متوازی رنز';

  @override
  String get pipelineRunSettingsMaxParallelHelp =>
      'لامحدود کے لیے خالی چھوڑیں۔ اضافی رنز قطار میں انتظار کرتے ہیں اور سلاٹ خالی ہونے پر شروع ہوتے ہیں۔';

  @override
  String get pipelineRunSettingsMaxParallelHint => 'لامحدود';

  @override
  String get pipelineRunSettingsMaxParallelInvalid =>
      '1 یا اس سے زیادہ کا پورا عدد درج کریں، یا لامحدود کے لیے خالی چھوڑیں۔';

  @override
  String get pipelineRunSettingsInputsTitle => 'ان پٹس';

  @override
  String get pipelineRunSettingsAddInput => 'ان پٹ شامل کریں';

  @override
  String get pipelineRunSettingsNoInputs => 'ابھی کوئی ان پٹ نہیں۔';

  @override
  String get pipelineInputEditTitle => 'ان پٹ فیلڈ';

  @override
  String get pipelineInputKeyLabel => 'کلید';

  @override
  String get pipelineInputKeyHelp =>
      'اسٹیٹ کلید جس کے تحت ویلیو محفوظ ہوتی ہے (مثلاً ⁨repo_full_name⁩)۔';

  @override
  String get pipelineInputLabelLabel => 'لیبل';

  @override
  String get pipelineInputTypeLabel => 'قسم';

  @override
  String get pipelineInputOptionsLabel => 'آپشنز (کاما سے جدا)';

  @override
  String get pipelineInputDefaultLabel => 'ڈیفالٹ ویلیو';

  @override
  String get pipelineInputPlaceholderLabel => 'پلیس ہولڈر';

  @override
  String get pipelineInputHelpLabel => 'مدد کا متن';

  @override
  String get pipelineInputRequiredLabel => 'ضروری';

  @override
  String get pipelineInputTypeText => 'متن';

  @override
  String get pipelineInputTypeMultiline => 'کثیر سطری متن';

  @override
  String get pipelineInputTypeNumber => 'عدد';

  @override
  String get pipelineInputTypeBoolean => 'ٹوگل';

  @override
  String get pipelineInputTypeSelect => 'منتخب';

  @override
  String get pipelinesEmpty => 'ابھی کوئی پائپ لائن رن نہیں';

  @override
  String get pipelinesEmptyHint =>
      'ایک شروع کرنے کے لیے \'پائپ لائن چلائیں\' کلک کریں۔';

  @override
  String get pipelinesNoSteps => 'ابھی کوئی مرحلہ ریکارڈ نہیں';

  @override
  String get pipelinesNoActiveWorkspace =>
      'اس کی پائپ لائنز دیکھنے کے لیے ورک اسپیس منتخب کریں';

  @override
  String pipelinesLoadError(String error) {
    return 'پائپ لائنز لوڈ نہیں ہو سکیں: ⁨$error⁩';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'پائپ لائن شروع نہیں ہو سکی: ⁨$error⁩';
  }

  @override
  String get pipelineStatusPending => 'زیرِ التوا';

  @override
  String get pipelineStatusQueued => 'قطار میں';

  @override
  String get pipelineStatusRunning => 'چل رہا ہے';

  @override
  String get pipelineStatusSuspended => 'معطل';

  @override
  String get pipelineStatusCompleted => 'مکمل';

  @override
  String get pipelineStatusFailed => 'ناکام';

  @override
  String get pipelineStatusCancelled => 'منسوخ';

  @override
  String get pipelineStatusSkipped => 'چھوڑا گیا';

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed از $total مراحل';
  }

  @override
  String get pipelineWaterfallTimeline => 'ٹائم لائن';

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
      'فعال کل سے خارج وقت: رن رک گیا یا مراحل کے درمیان انتظار کر رہا تھا۔';

  @override
  String get pipelineStepStarted => 'شروع ہوا';

  @override
  String get pipelineStepFinished => 'ختم ہوا';

  @override
  String get pipelineStepDurationLabel => 'مدت';

  @override
  String get pipelineStepViewConversation => 'گفتگو دیکھیں';

  @override
  String get pipelineStepError => 'خرابی';

  @override
  String get pipelineStepInput => 'ان پٹ';

  @override
  String get pipelineStepOutput => 'آؤٹ پٹ';

  @override
  String get pipelineStepNotExecuted => 'ابھی نہیں چلا';

  @override
  String pipelineRunFailedAtStep(String step) {
    return '⁨$step⁩ پر ناکام';
  }

  @override
  String get pipelineRunTriggerManual => 'دستی';

  @override
  String get pipelineStepSkippedReason => 'چھوڑا گیا';

  @override
  String get pipelineStepPriorAttempts => 'پچھلی کوششیں';

  @override
  String get pipelineStepAttemptLabel => 'کوشش';

  @override
  String pipelineStepAttemptN(int number) {
    return 'کوشش $number';
  }

  @override
  String get pipelineStepAttemptInterrupted => 'روکا گیا';

  @override
  String get pipelineRunColumnPipeline => 'پائپ لائن';

  @override
  String get pipelineRunColumnDuration => 'مدت';

  @override
  String get pipelineRunQueueNext => 'اگلا';

  @override
  String pipelineRunQueuePosition(int position) {
    return 'قطار میں $position';
  }

  @override
  String get pipelineRunColumnStarted => 'شروع ہوا';

  @override
  String get pipelineRunHistory => 'رن ہسٹری';

  @override
  String get pipelineRunHistoryEmpty => 'ابھی کوئی اور رن نہیں';

  @override
  String pipelineRunRerunAgo(String time) {
    return 'دوبارہ چلائیں $time';
  }

  @override
  String pipelineRunAttempt(int number) {
    return 'کوشش $number';
  }

  @override
  String pipelineRunFirstStarted(String time) {
    return 'پہلی بار شروع $time';
  }

  @override
  String get pipelineRunFilterAll => 'سب';

  @override
  String get pipelineRunFilterEmpty => 'اس فلٹر سے کوئی رن میل نہیں کھاتا';

  @override
  String get relativeJustNow => 'ابھی';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count منٹ پہلے',
      one: '1 منٹ پہلے',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count گھنٹے پہلے',
      one: '1 گھنٹہ پہلے',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دن پہلے',
      one: '1 دن پہلے',
    );
    return '$_temp0';
  }

  @override
  String get teamsTitle => 'ٹیمز';

  @override
  String get teamsAddTeam => 'ٹیم شامل کریں';

  @override
  String get teamsLoadError => 'ٹیمز لوڈ نہیں ہو سکیں';

  @override
  String get teamsEmptyTitle => 'ابھی کوئی ٹیم نہیں';

  @override
  String get teamsEmptyDescription =>
      'ایجنٹس کو ٹیموں میں گروپ کریں تاکہ ٹیم کو تفویض کام لیڈر کے ذریعے جائے جو تفویض کرے۔';

  @override
  String get teamCreateTitle => 'نئی ٹیم';

  @override
  String get teamEditTitle => 'ٹیم میں ترمیم';

  @override
  String get teamNameLabel => 'ٹیم کا نام';

  @override
  String get teamNameHint => 'مثال: فرنٹ اینڈ';

  @override
  String get teamDescriptionLabel => 'تفصیل';

  @override
  String get teamDescriptionHint => 'اس ٹیم کی ذمہ داری کیا ہے';

  @override
  String get teamLeaderLabel => 'لیڈر';

  @override
  String get teamLeaderHelp =>
      'کوآرڈینیٹر جو ٹیم کو تفویض کام وصول کرتا ہے اور موزوں رکن کو تفویض کرتا ہے۔';

  @override
  String get teamNoLeader => 'کوئی لیڈر نہیں';

  @override
  String get teamInstructionsLabel => 'عملی ہدایات';

  @override
  String get teamInstructionsHelp =>
      'لیڈر کی بریفنگ کے ساتھ جڑتی ہیں — ٹیم روایات، اسکیلیشن قواعد، لہجہ۔';

  @override
  String get teamInstructionsHint => 'اختیاری';

  @override
  String get teamSaved => 'ٹیم محفوظ ہو گئی';

  @override
  String get teamMembersError => 'اراکین لوڈ نہیں ہو سکے';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count اراکین',
      one: '1 رکن',
      zero: 'کوئی رکن نہیں',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => 'رکن شامل کریں';

  @override
  String get teamAddMemberTitle => 'اراکین شامل کریں';

  @override
  String teamAddMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شامل کریں',
      one: '1 شامل کریں',
      zero: 'شامل کریں',
    );
    return '$_temp0';
  }

  @override
  String get teamNoAgentsToAdd => 'ہر ایجنٹ پہلے سے اس ٹیم میں ہے۔';

  @override
  String get teamRemoveMember => 'ٹیم سے ہٹائیں';

  @override
  String get teamLeaderBadge => 'لیڈر';

  @override
  String get teamUnknownAgent => 'نامعلوم ایجنٹ';

  @override
  String get teamMembersEmpty => 'ابھی کوئی رکن نہیں';

  @override
  String get teamMembersEmptyDescription =>
      'ایجنٹس شامل کریں تاکہ لیڈر کے پاس تفویض کرنے والے ہوں۔';

  @override
  String get teamSelectPrompt => 'ٹیم منتخب کریں';

  @override
  String get teamSelectPromptDescription =>
      'فہرست سے ٹیم منتخب کریں، یا نئی بنائیں۔';

  @override
  String get teamDeleteTitle => 'ٹیم حذف کریں؟';

  @override
  String teamDeleteBody(String name) {
    return '⁨$name⁩ حذف ہو جائے گی۔ اس کے ایجنٹس متاثر نہیں ہوتے۔';
  }

  @override
  String get teamHasLeaderTooltip => 'لیڈر ہے';

  @override
  String get pipelineTemplatesNav => 'پائپ لائن ٹیمپلیٹس';

  @override
  String get pipelineTemplatesTitle => 'پائپ لائن ٹیمپلیٹس';

  @override
  String get pipelineTemplatesSubtitle =>
      'آپ کے ایجنٹس کو آرکیسٹریٹ کرنے والی پائپ لائنز کے لیے ڈریگ اینڈ ڈراپ ایڈیٹر۔';

  @override
  String get pipelineTemplatesNew => 'نیا ٹیمپلیٹ';

  @override
  String get pipelineTemplatesEmpty =>
      'ابھی کوئی پائپ لائن ٹیمپلیٹ نہیں۔ شروع کرنے کے لیے ایک بنائیں۔';

  @override
  String get pipelineTemplateBuiltInBadge => 'بلٹ اِن';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'ٹیمپلیٹ حذف کریں؟';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'پائپ لائن ٹیمپلیٹ ⁨$name⁩ حذف کریں؟ یہ واپس نہیں ہو سکتا۔';
  }

  @override
  String get pipelineTemplateEditorSubtitle =>
      'سائڈ بار سے نوڈ اقسام کینوس پر گھسیٹیں، پھر انہیں جوڑیں۔';

  @override
  String get unsavedChanges => 'غیر محفوظ تبدیلیاں';

  @override
  String get nodeLibraryTitle => 'نوڈ لائبریری';

  @override
  String get nodeLibraryHint =>
      'نوڈ شامل کرنے کے لیے کوئی اندراج کینوس پر گھسیٹیں۔';

  @override
  String get editorEmptyCanvas => 'شروع کرنے کے لیے لائبریری سے نوڈ گھسیٹیں۔';

  @override
  String get pipelineWhenThisHappens => 'جب یہ ہوتا ہے';

  @override
  String get pipelineDoThis => 'یہ کریں';

  @override
  String get pipelineAddStep => 'مرحلہ شامل کریں';

  @override
  String get pipelineTidyUp => 'لے آؤٹ سنواریں';

  @override
  String get pipelineEditorHint =>
      'مرحلے گھسیٹ کر ترتیب دیں · ہینڈل گھسیٹ کر جوڑیں';

  @override
  String get pipelineRemoveConnection => 'رابطہ ہٹائیں';

  @override
  String get pipelineDragToConnect => 'جوڑنے کے لیے گھسیٹیں';

  @override
  String get pipelineNewDefaultName => 'نئی پائپ لائن';

  @override
  String get nodeCategoryTriggers => 'ٹرگرز';

  @override
  String get triggerEventWebhook => 'ویب ہک';

  @override
  String get pipelineAddTrigger => 'ٹرگر شامل کریں';

  @override
  String get pipelineOnEvent => 'ایونٹ پر';

  @override
  String get nodeConfigTitle => 'نوڈ کنفیگ';

  @override
  String get nodeConfigKind => 'قسم';

  @override
  String get nodeConfigLabel => 'لیبل';

  @override
  String get nodeConfigAgent => 'ایجنٹ';

  @override
  String get nodeConfigAgentHint => 'ایجنٹ منتخب کریں…';

  @override
  String get nodeConfigInputKeys => 'ان پٹ کلیدیں (کاما سے جدا)';

  @override
  String get nodeConfigInputKeysHelp =>
      'اسٹیٹ کلیدیں جو یہ نوڈ استعمال کرتا ہے۔ پرامپٹ میں پلیس ہولڈر کی جگہ کے لیے۔';

  @override
  String get nodeConfigRepos => 'کلون کرنے کی ریپوزٹریز';

  @override
  String get nodeConfigReposHelp =>
      'جب یہ نوڈ گفتگو شروع کرے تو کلون اور کوڈ انڈیکس ہونے والے ریپوز۔ ہر ریپو منتخب کرنے سے سب کلون ہوتے ہیں (ڈیفالٹ)۔';

  @override
  String get nodeConfigRepoBranchHint => 'برانچ (ڈیفالٹ)';

  @override
  String get nodeConfigRepoBranchHelp =>
      'ہر چیک آؤٹ جس برانچ سے کاٹا جاتا ہے۔ ریپو کی اپنی ڈیفالٹ برانچ کے لیے خالی چھوڑیں — worktree پھر بھی اپنی برانچ لیتا ہے، اس لیے ایجنٹ کا کمیٹ اس پر نہیں لگتا۔';

  @override
  String nodeConfigReposDynamic(String entries) {
    return 'ڈائنامک اندراجات رکھے گئے: ⁨$entries⁩';
  }

  @override
  String get nodeConfigCreateConversation => 'اس میں گفتگو کھولیں';

  @override
  String get nodeConfigCreateConversationHelp =>
      'جب کئی ایجنٹ نوڈز پیچھے ہوں تو اسے بند رکھیں — ہر ایک اپنی نامی سٹریم کھولتا ہے۔ جب ایک ہی ایجنٹ نوڈ پیچھے ہو تو آن کریں، تاکہ کمرے میں بغیر عنوان کی گفتگو ساتھ نہ دکھے۔';

  @override
  String get nodeConfigConversationTitle => 'گفتگو کا نام';

  @override
  String get nodeConfigConversationTitleHelp =>
      'نیچے والے ایجنٹ نوڈ کو وہی نام دیں تاکہ دونوں ایک سٹریم میں کام کریں۔ ڈیفالٹ نوڈ کا لیبل ہے۔';

  @override
  String get nodeConfigSpaceName => 'اسپیس کا نام';

  @override
  String get nodeConfigSpaceNameHelp =>
      'اس نوڈ کا کھلا کمرہ کیا کہلاتا ہے۔ پرامپٹ جیسے ہی اسٹیٹ پلیس ہولڈرز۔ نوڈ کے لیبل کے لیے خالی چھوڑیں۔';

  @override
  String get nodeConfigSpaceNameHint => '⁨pr_number⁩ کا ریویو';

  @override
  String get nodeConfigStreamTitle => 'گفتگو کا نام';

  @override
  String get nodeConfigStreamTitleHelp =>
      'کمرے کے اندر اس نوڈ کے ایجنٹ کی نامی سٹریم۔ پرامپٹ جیسے ہی اسٹیٹ پلیس ہولڈرز۔ خالی چھوڑیں تو باری کمرے کی مستقل گفتگو میں جاتی ہے، جہاں فین آؤٹ ہر ایجنٹ کو ملا دیتا ہے۔';

  @override
  String get nodeConfigConversationTitleHint => 'آرکیٹیکچر تجزیہ';

  @override
  String get nodeConfigOutputKey => 'آؤٹ پٹ کلید';

  @override
  String get nodeConfigPrompt => 'پرامپٹ ٹیمپلیٹ';

  @override
  String get nodeConfigPromptHelp =>
      'رن ٹائم پر اسٹیٹ سے ویلیوز لینے کے لیے ڈبل بریس پلیس ہولڈرز استعمال کریں۔';

  @override
  String get nodeConfigScript => 'Bash اسکرپٹ';

  @override
  String get nodeConfigScriptHelp =>
      '⁨bash -c⁩ سے آپریٹنگ سسٹم کے سینڈ باکس میں چلتا ہے۔ ⁨GH_TOKEN⁩ اور ⁨GITHUB_TOKEN⁩ میں منسلک ریپوزٹری کے لیے صرف پڑھنے والا ٹوکن ہوتا ہے۔ عمل سے پہلے پلیس ہولڈرز کو اقتباس میں رکھ کر بدلا جاتا ہے۔';

  @override
  String get nodeConfigRouteKeys => 'روٹ کلیدیں';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return '⁨$source⁩ سے روٹ کلید';
  }

  @override
  String get conditionSectionTitle => 'شرط';

  @override
  String get conditionMode => 'موڈ';

  @override
  String get conditionModeFilesAny => 'فائل(یں) موجود — کوئی بھی';

  @override
  String get conditionModeFilesAll => 'فائلیں موجود — سب';

  @override
  String get conditionModeComparison => 'موازنہ';

  @override
  String get conditionModeSwitch => 'سوئچ';

  @override
  String get conditionFilePaths => 'فائل پاتھ';

  @override
  String get conditionFilePathsAnyHelp =>
      'فی لائن ایک پاتھ، بیس ڈائریکٹری کے نسبت۔ کوئی بھی موجود ہو تو true روٹ ہوتا ہے۔';

  @override
  String get conditionFilePathsAllHelp =>
      'فی لائن ایک پاتھ، بیس ڈائریکٹری کے نسبت۔ سب موجود ہوں تب ہی true روٹ ہوتا ہے۔';

  @override
  String get conditionBaseKey => 'بیس ڈائریکٹری کلید';

  @override
  String get conditionBaseKeyHelp =>
      'اسٹیٹ کلید جس میں وہ ڈائریکٹری ہے جس کے مقابل پاتھ حل ہوتے ہیں (ڈیفالٹ ⁨repo_local_path⁩)۔';

  @override
  String get conditionRecursive => 'سب ڈائریکٹریز تلاش کریں';

  @override
  String get conditionNegate => 'الٹ: غائب ہونے پر true روٹ';

  @override
  String get conditionLeft => 'بائیں ویلیو';

  @override
  String get conditionOperator => 'آپریٹر';

  @override
  String get conditionRight => 'دائیں ویلیو';

  @override
  String get conditionSwitchKey => 'اسٹیٹ کلید پر سوئچ';

  @override
  String get conditionCases => 'کیسز (کاما سے جدا)';

  @override
  String get conditionCasesHelp =>
      'ویلیو سے میل کھانے والی روٹ کلیدیں، ترتیب سے۔';

  @override
  String get conditionDefaultCase => 'ڈیفالٹ کیس';

  @override
  String get triggerManualHelp => 'رن صفحے پر دکھائیں اور ہاتھ سے شروع کریں۔';

  @override
  String get triggerKindSchedule => 'شیڈول پر';

  @override
  String get triggerScheduleExprLabel => 'شیڈول (cron یا ⁨every:seconds⁩)';

  @override
  String get triggerTimezoneLabel => 'ٹائم زون (اختیاری)';

  @override
  String get triggerCatchUpLabel => 'چھوٹے رنز پر';

  @override
  String get triggerCatchUpRunOnce => 'ایک بار چلائیں';

  @override
  String get triggerCatchUpSkip => 'چھوڑیں';

  @override
  String get syncHealthTitle => 'سنک صحت';

  @override
  String get syncHealthNoConfigs => 'ابھی کوئی سنک کنکشن نہیں';

  @override
  String get syncHealthNeverSynced => 'کبھی سنک نہیں ہوا';

  @override
  String get syncOutcomeOk => 'سنک ہوا';

  @override
  String get syncOutcomeFailed => 'ناکام';

  @override
  String get syncOutcomeSkipped => 'چھوڑا گیا';

  @override
  String syncHealthFailedStreak(int count) {
    return '$count لگاتار ناکامیاں';
  }

  @override
  String get triggerWebhookHelp =>
      'دستخط شدہ ویب ہک URL بنتا ہے۔ بیرونی سسٹمز اس پائپ لائن شروع کرنے کے لیے اس پر POST کرتے ہیں۔';

  @override
  String get triggerWebhookPathLabel => 'ویب ہُک کا راستہ';

  @override
  String get triggerMatchStatusLabel => 'صرف جب اسٹیٹس ہو';

  @override
  String get triggerSummaryNone => 'کوئی ٹرگر نہیں';

  @override
  String triggerEverySeconds(int seconds) {
    return 'ہر $secondsس';
  }

  @override
  String get triggerEventManual => 'دستی رن';

  @override
  String get triggerEventSchedule => 'شیڈول';

  @override
  String get triggerEventPrStatusChanged => 'PR اسٹیٹس بدلا';

  @override
  String get triggerEventExternalPr => 'بیرونی PR کھلا';

  @override
  String get triggerEventPrPublished => 'PR شائع ہوا';

  @override
  String get triggerEventPrMerged => 'PR مرج ہوا';

  @override
  String get triggerEventRepoAdded => 'ریپوزٹری شامل ہوئی';

  @override
  String get triggerEventCodeGraphWatch => 'فائل تبدیلی';

  @override
  String pipelineRunCauseChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بدلی ہوئی فائلیں',
      one: '1 بدلی ہوئی فائل',
    );
    return '$_temp0';
  }

  @override
  String pipelineRunCauseMorePaths(int count) {
    return '⁨+$count⁩ مزید';
  }

  @override
  String get pipelineRunCauseRescan => 'ڈسک پر بدلا';

  @override
  String get pipelineRunCauseInitial => 'اس چیک آؤٹ کا پہلا انڈیکس';

  @override
  String get triggerEventMessageReceived => 'پیغام موصول';

  @override
  String get triggerEventTicketCompleted => 'ٹکٹ مکمل';

  @override
  String get triggerEventTicketFailed => 'ٹکٹ ناکام';

  @override
  String get triggerEventTicketCancelled => 'ٹکٹ منسوخ';

  @override
  String get triggerEventBudgetCrossed => 'بجٹ حد پار ہوئی';

  @override
  String get nodeLibrarySearchHint => 'نوڈز تلاش کریں';

  @override
  String get nodeLibraryNoMatches => 'کوئی مماثل نوڈ نہیں';

  @override
  String get nodeCategoryFlow => 'فلو اور منطق';

  @override
  String get nodeCategoryPr => 'PR ریویو';

  @override
  String get nodeCategoryAgents => 'ایجنٹس';

  @override
  String get nodeCategoryMessaging => 'میسجنگ';

  @override
  String get nodeCategoryCode => 'کوڈ';

  @override
  String get triggerDisabledTag => 'آف';

  @override
  String get pipelineInputTypeRepo => 'ریپوزٹری';

  @override
  String get pipelineRunNoRepos => 'اس ورک اسپیس میں ابھی کوئی ریپوزٹری نہیں۔';

  @override
  String get ticketingApiKey => 'ٹکٹنگ API کلید';

  @override
  String get ticketingProvider => 'ٹکٹنگ فراہم کنندہ';

  @override
  String get connectGitHubAndTicketing =>
      'کوڈ ہوسٹ منسلک کریں تاکہ Control Center آپ کے pull requests، ایشوز اور ریویوز پڑھ سکے۔ اختیاری طور پر ٹکٹنگ فراہم کنندہ منسلک کریں۔ کریڈینشلز آپ کے سرور پر رہتے ہیں، اس مشین پر نہیں۔';

  @override
  String get triggerEventTicketAssigned => 'ٹکٹ تفویض ہوا';

  @override
  String get triggerEventTicketCreated => 'ٹکٹ بن گیا';

  @override
  String get triggerEventTicketStatusChanged => 'ٹکٹ کی حیثیت بدل گئی';

  @override
  String get triggerEventMeetingRecordingStopped => 'میٹنگ ریکارڈنگ رک گئی';

  @override
  String get triggerEventSkillUpdated => 'مہارت اپ ڈیٹ ہوئی';

  @override
  String get triggerEventSpaceDeleted => 'اسپیس حذف ہو گئی';

  @override
  String get triggerEventSpaceArchived => 'اسپیس آرکائیو ہو گئی';

  @override
  String get triggerEventSpaceProvisioningChanged => 'اسپیس کی تیاری بدل گئی';

  @override
  String get triggerEventPrHeadChanged => 'PR کا head بدل گیا';

  @override
  String get triggerEventEnvironmentStatusChanged => 'ماحول کی حیثیت بدل گئی';

  @override
  String get triggerEventEnvironmentReady => 'ماحول تیار ہے';

  @override
  String get triggerEventEnvironmentDestroyed => 'ماحول ختم کر دیا گیا';

  @override
  String get triggerEventEnvironmentProcessExited =>
      'ماحول کا پراسیس ختم ہو گیا';

  @override
  String get triggerExternalPrHelp =>
      'کوڈ ہوسٹ پر کھلی پل ریکویسٹ، Control Center سے نہیں۔';

  @override
  String get triggerPrPublishedHelp =>
      'Control Center یا کسی ایجنٹ کی کھلی پل ریکویسٹ۔';

  @override
  String get triggerPrStatusChangedHelp =>
      'ضم، بند، کھلی، دوبارہ کھلی یا منظور۔ انسپکٹر میں حیثیت سے فلٹر کریں۔';

  @override
  String get triggerPrMergedHelp =>
      'صرف جب پل ریکویسٹ ضم ہو، بند یا دوبارہ کھلی ہونے پر نہیں۔';

  @override
  String get triggerRepoAddedHelp =>
      'اس ورک اسپیس سے ایک ریپوزٹری منسلک ہوتی ہے۔';

  @override
  String get triggerCodeGraphWatchHelp =>
      'منسلک ریپوزٹری کی فائل ڈسک پر بدل جاتی ہے۔';

  @override
  String get triggerMessageReceivedHelp => 'ایک اسپیس میں نیا پیغام آتا ہے۔';

  @override
  String get triggerTicketCreatedHelp => 'اس ورک اسپیس میں ایک ٹکٹ بنتی ہے۔';

  @override
  String get triggerTicketStatusChangedHelp =>
      'ٹکٹ حیثیتوں کے درمیان منتقل ہوتی ہے۔';

  @override
  String get triggerTicketCompletedHelp => 'ٹکٹ کامیابی سے مکمل ہوتی ہے۔';

  @override
  String get triggerTicketFailedHelp =>
      'ایجنٹ رن ناکام ہوا اور ٹکٹ ناکام نشان زد ہوتی ہے۔';

  @override
  String get triggerTicketCancelledHelp =>
      'ٹکٹ منسوخ ہوتی ہے اور جاری نہیں رہے گی۔';

  @override
  String get triggerBudgetCrossedHelp =>
      'ورک اسپیس یا ایجنٹ کی خرچ حد پار ہوتی ہے۔';

  @override
  String get triggerTicketAssignedHelp =>
      'ٹکٹ کسی شخص، ایجنٹ یا ٹیم کو سونپی جاتی ہے۔';

  @override
  String get triggerMeetingRecordingStoppedHelp =>
      'میٹنگ ریکارڈنگ ختم ہوتی ہے۔';

  @override
  String get triggerSkillUpdatedHelp => 'مہارت نصب یا تازہ ہوتی ہے۔';

  @override
  String get triggerSpaceDeletedHelp => 'گفتگو کی اسپیس حذف ہوتی ہے۔';

  @override
  String get triggerSpaceArchivedHelp => 'گفتگو کی اسپیس آرکائیو ہوتی ہے۔';

  @override
  String get triggerSpaceProvisioningChangedHelp =>
      'اسپیس کے worktree کی تیاری شروع، مکمل یا ناکام ہوتی ہے۔';

  @override
  String get triggerPrHeadChangedHelp =>
      'کھلی pull request میں نئی کمٹس پش ہوتی ہیں۔';

  @override
  String get triggerEnvironmentStatusChangedHelp =>
      'اسپیس کا ماحول نئی حیثیت میں جاتا ہے۔';

  @override
  String get triggerEnvironmentReadyHelp =>
      'اسپیس کا ماحول شروع ہو گیا ہے اور استعمال کے قابل ہے۔';

  @override
  String get triggerEnvironmentDestroyedHelp => 'اسپیس کا ماحول ہٹایا جاتا ہے۔';

  @override
  String get triggerEnvironmentProcessExitedHelp =>
      'ماحول کا چلایا ہوا پراسیس ختم ہوتا ہے۔';

  @override
  String get navTickets => 'ٹکٹس';

  @override
  String get ticketsTitle => 'ٹکٹس';

  @override
  String get newTicket => 'نیا ٹکٹ';

  @override
  String get noTicketsYet => 'ابھی کوئی ٹکٹ نہیں';

  @override
  String get addCollaborator => 'تعاون کنندہ شامل کریں';

  @override
  String get noCollaborators => 'ابھی کوئی تعاون کنندہ نہیں';

  @override
  String get linkedPullRequests => 'لنک شدہ pull requests';

  @override
  String get noLinkedPullRequests => 'ابھی کوئی لنک شدہ pull request نہیں';

  @override
  String get stopAgent => 'ایجنٹ روکیں';

  @override
  String get ticketProperties => 'پراپرٹیز';

  @override
  String get ticketTabIssue => 'ایشو';

  @override
  String get ticketSelectPrompt => 'تفصیلات دیکھنے کے لیے ٹکٹ منتخب کریں';

  @override
  String get unassigned => 'غیر تفویض';

  @override
  String get ticketStatusBacklog => 'بیک لاگ';

  @override
  String get ticketStatusOpen => 'کرنا ہے';

  @override
  String get ticketStatusInProgress => 'جاری';

  @override
  String get ticketStatusInReview => 'ریویو میں';

  @override
  String get ticketStatusDone => 'مکمل';

  @override
  String get ticketStatusBlocked => 'بلاک';

  @override
  String get ticketStatusFailed => 'ناکام';

  @override
  String get ticketStatusCancelled => 'منسوخ';

  @override
  String get notificationTicketAssigned => 'ٹکٹ تفویض ہوا';

  @override
  String get notificationTicketStatusChanged => 'ٹکٹ اسٹیٹس بدلا';

  @override
  String get priority => 'ترجیح';

  @override
  String get status => 'اسٹیٹس';

  @override
  String get assignee => 'تفویض شدہ';

  @override
  String get labels => 'لیبلز';

  @override
  String get noLabelsYet => 'ابھی کوئی لیبل نہیں';

  @override
  String get clearLabels => 'لیبلز صاف کریں';

  @override
  String get pipelineStepAgentActivity => 'ایجنٹ سرگرمی';

  @override
  String get runStatusCompleted => 'مکمل';

  @override
  String get runStatusQueued => 'قطار میں';

  @override
  String get ticketDescription => 'تفصیل';

  @override
  String get ticketPriorityNone => 'کوئی نہیں';

  @override
  String get ticketPriorityUrgent => 'فوری';

  @override
  String get ticketPriorityHigh => 'زیادہ';

  @override
  String get ticketPriorityMedium => 'درمیانہ';

  @override
  String get ticketPriorityLow => 'کم';

  @override
  String get ticketViewList => 'فہرست';

  @override
  String get ticketViewBoard => 'بورڈ';

  @override
  String get ticketTitlePlaceholder => 'ایشو عنوان';

  @override
  String get ticketDescriptionPlaceholder => 'تفصیل شامل کریں…';

  @override
  String get createMore => 'مزید بنائیں';

  @override
  String selectedCount(int count) {
    return '$count منتخب';
  }

  @override
  String get clearSelection => 'انتخاب صاف کریں';

  @override
  String get bulkDeleteTitle => 'ٹکٹس حذف کریں';

  @override
  String bulkDeleteMessage(int count) {
    return '$count منتخب ٹکٹس حذف کریں؟ یہ واپس نہیں ہو سکتا۔';
  }

  @override
  String get assignTo => 'تفویض کریں…';

  @override
  String get sectionMembers => 'اراکین';

  @override
  String get sectionAgents => 'ایجنٹس';

  @override
  String get sidebarGroupWorkspace => 'ورک اسپیس';

  @override
  String get notificationsTitle => 'اطلاعات';

  @override
  String get notificationsTooltip => 'اطلاعات';

  @override
  String get notificationsEmpty => 'آپ سب دیکھ چکے ہیں';

  @override
  String notificationsUnreadCount(int count) {
    return '$count ان پڑھے';
  }

  @override
  String get notificationsMarkRead => 'پڑھا ہوا نشان زد کریں';

  @override
  String get notificationsMarkUnread => 'ان پڑھا نشان زد کریں';

  @override
  String get notificationsEntryActions => 'اطلاع کے ایکشنز';

  @override
  String get markAllRead => 'سب پڑھا ہوا نشان زد کریں';

  @override
  String get teamsNav => 'ٹیمز';

  @override
  String get noWorkspace => 'کوئی ورک اسپیس نہیں';

  @override
  String get selectWorkspace => 'ورک اسپیس منتخب کریں';

  @override
  String get navMemory => 'میموری';

  @override
  String get memoryTabFacts => 'فیکٹس';

  @override
  String get memoryTabPolicies => 'پالیسیاں';

  @override
  String get memoryGraphShowFacts => 'فیکٹس دکھائیں';

  @override
  String get memoryGraphHideFacts => 'فیکٹس چھپائیں';

  @override
  String get memoryGraphExpandAll => 'تمام فیکٹس پھیلائیں';

  @override
  String get memoryGraphCollapseAll => 'تمام فیکٹس سکیڑیں';

  @override
  String get memoryTabGraph => 'نالج گراف';

  @override
  String get memoryNoWorkspace =>
      'اس کی میموری دیکھنے کے لیے ورک اسپیس منتخب کریں۔';

  @override
  String get searchArticles => 'مضامین تلاش کریں';

  @override
  String get filterAll => 'سب';

  @override
  String get filterUnread => 'ان پڑھے';

  @override
  String get filterSaved => 'محفوظ';

  @override
  String get saveArticle => 'مضمون محفوظ کریں';

  @override
  String get removeFromSaved => 'محفوظ سے ہٹائیں';

  @override
  String get filterBySource => 'ماخذ سے فلٹر';

  @override
  String get viewAsList => 'فہرست منظر';

  @override
  String get viewAsGrid => 'گرڈ منظر';

  @override
  String get noMatchingArticles => 'کوئی مماثل مضمون نہیں';

  @override
  String get noMatchingArticlesBody => 'دوسری تلاش یا ماخذ فلٹر آزمائیں۔';

  @override
  String get allCaughtUp => 'سب دیکھ لیا';

  @override
  String get allCaughtUpBody => 'کوئی ان پڑھا مضمون نہیں — بعد میں چیک کریں۔';

  @override
  String get openArticlesInAppDescription =>
      'لنکس بلٹ اِن ریڈر میں کھولیں، ڈیفالٹ براؤزر میں نہیں۔';

  @override
  String get blockAdsTrackersDescription =>
      'ریڈر میں کھلے مضامین سے اشتہارات، ٹریکرز اور کوکی بینرز ہٹائیں۔';

  @override
  String get agentQuestionHeader => 'آپ کے لیے سوال';

  @override
  String get agentQuestionAnsweredLabel => 'جواب دیا گیا';

  @override
  String get agentQuestionFreeformHint => 'اپنا جواب ٹائپ کریں…';

  @override
  String agentQuestionProgress(int index, int count) {
    return 'سوال $index از $count';
  }

  @override
  String get agentQuestionSkip => 'چھوڑیں';

  @override
  String get agentQuestionSkippedLabel => 'چھوڑ دیا گیا';

  @override
  String get agentQuestionTimedOutLabel => 'وقت ختم ہو گیا';

  @override
  String get agentQuestionTimeLeft => 'جواب دینے کے لیے باقی وقت';

  @override
  String get agentQuestionFreeformOptionHint => 'اپنے الفاظ میں بیان کریں…';

  @override
  String get reviewRequested => 'ریویو کی درخواست';

  @override
  String get noRepositoriesConfigured => 'کوئی ریپوزٹری کنفیگر نہیں';

  @override
  String openedAgo(String age) {
    return '$age کھلا';
  }

  @override
  String prTimelineOpened(String author) {
    return '⁨$author⁩ نے یہ pull request کھولا';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کمیٹس',
      one: '1 کمیٹ',
    );
    return '⁨$author⁩ نے یہ pull request $_temp0 کے ساتھ کھولا';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return '⁨$actor⁩ نے ⁨$reviewers⁩ سے ریویو مانگا';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '⁨$actor⁩ نے ⁨$reviewers⁩ کی ریویو درخواست ہٹا دی';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '⁨$actor⁩ نے ⁨$requested⁩ سے ریویو مانگا اور ⁨$removed⁩ کی ریویو درخواست ہٹا دی';
  }

  @override
  String prTimelineAddedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'لیبلز',
      one: 'لیبل',
    );
    return '⁨$actor⁩ نے ⁨$labels⁩ $_temp0 شامل کیا';
  }

  @override
  String prTimelineRemovedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'لیبلز',
      one: 'لیبل',
    );
    return '⁨$actor⁩ نے ⁨$labels⁩ $_temp0 ہٹایا';
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
      other: 'لیبلز',
      one: 'لیبل',
    );
    String _temp1 = intl.Intl.pluralLogic(
      removedCount,
      locale: localeName,
      other: 'لیبلز',
      one: 'لیبل',
    );
    return '⁨$actor⁩ نے ⁨$added⁩ $_temp0 شامل کیے اور ⁨$removed⁩ $_temp1 ہٹائے';
  }

  @override
  String prTimelineCommitted(String author) {
    return '⁨$author⁩ نے کمیٹ کیا';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کمیٹس',
      one: '1 کمیٹ',
    );
    return '⁨$author⁩ نے $_temp0 پش کیے';
  }

  @override
  String prTimelineApproved(String author) {
    return '⁨$author⁩ نے یہ تبدیلیاں منظور کیں';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return '⁨$author⁩ نے تبدیلیاں مانگیں';
  }

  @override
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کوڈ تبصرے',
      one: '1 کوڈ تبصرہ',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '⁨$author⁩ نے ریویو کیا';
  }

  @override
  String get prTimelineSomeone => 'کوئی';

  @override
  String get prTimelineBotBadge => 'بوٹ';

  @override
  String updatedAgo(String age) {
    return '$age اپ ڈیٹ';
  }

  @override
  String get checksPassing => 'چیکس پاس';

  @override
  String get checksRunning => 'چیکس چل رہے ہیں';

  @override
  String get needsYourReview => 'آپ کے ریویو کی ضرورت';

  @override
  String get checks => 'چیکس';

  @override
  String get noReviewersAssigned => 'کوئی ریویوور تفویض نہیں';

  @override
  String get noAssignees => 'کوئی تفویض شدہ نہیں';

  @override
  String get loadingEllipsis => 'لوڈ ہو رہا ہے…';

  @override
  String get loadingChecks => 'چیکس لوڈ ہو رہے ہیں…';

  @override
  String get noChecksYet => 'ابھی کوئی چیک نہیں چلا';

  @override
  String get noChangesToReview => 'جائزے کے لیے کوئی تبدیلی نہیں';

  @override
  String checksFailingCount(int count) {
    return '$count ناکام';
  }

  @override
  String get showMore => 'مزید دکھائیں';

  @override
  String get showLess => 'کم دکھائیں';

  @override
  String get backToPullRequests => 'pull requests پر واپس';

  @override
  String get pullRequestNotFound => 'Pull request نہیں ملا';

  @override
  String get pullRequestNotFoundBody =>
      'یہ مرج، بند، یا منتقل ہو چکا ہو سکتا ہے۔';

  @override
  String get couldntLoadPullRequest => 'یہ pull request لوڈ نہیں ہو سکا';

  @override
  String get showDetails => 'تفصیلات دکھائیں';

  @override
  String get noDescriptionProvided => 'کوئی تفصیل نہیں دی گئی۔';

  @override
  String get factsHint => 'آپ کے ایجنٹس سیکھتے ہی فیکٹس یہاں نظر آئیں گے۔';

  @override
  String get noFactsMatch => 'آپ کی تلاش سے کوئی فیکٹ میل نہیں کھاتا';

  @override
  String get memoryLoadError => 'میموری لوڈ نہیں ہو سکی';

  @override
  String get sortRecent => 'حالیہ';

  @override
  String get sortConfidence => 'اعتماد';

  @override
  String get confidenceTooltip =>
      'ایجنٹس کتنے یقین سے کہتے ہیں کہ یہ فیکٹ درست ہے، 0 سے 100%۔';

  @override
  String get supersededTooltip => 'ایک نئے فیکٹ نے اس کی جگہ لے لی ہے۔';

  @override
  String get domain => 'ڈومین';

  @override
  String get fitToView => 'منظر میں فٹ کریں';

  @override
  String get project => 'پروجیکٹ';

  @override
  String get newProject => 'نیا پروجیکٹ';

  @override
  String get editProject => 'پروجیکٹ میں ترمیم';

  @override
  String get deleteProject => 'پروجیکٹ حذف کریں';

  @override
  String get noProject => 'کوئی پروجیکٹ نہیں';

  @override
  String get allTickets => 'تمام ٹکٹس';

  @override
  String get projectNamePlaceholder => 'پروجیکٹ کا نام';

  @override
  String get projectDescriptionPlaceholder => 'تفصیل (اختیاری)';

  @override
  String get projectColorLabel => 'رنگ';

  @override
  String get noProjectsYet => 'ابھی کوئی پروجیکٹ نہیں';

  @override
  String get projectTicketsEmpty => 'اس پروجیکٹ میں ابھی کوئی ٹکٹ نہیں';

  @override
  String get createProject => 'پروجیکٹ بنائیں';

  @override
  String projectProgress(int done, int total) {
    return '$done از $total مکمل';
  }

  @override
  String deleteProjectConfirm(String name) {
    return '\"⁨$name⁩\" حذف کریں؟ اس کے ٹکٹس رہتے ہیں اور پروجیکٹ سے ہٹ جاتے ہیں۔';
  }

  @override
  String get projectStatusActive => 'فعال';

  @override
  String get projectStatusCompleted => 'مکمل';

  @override
  String get projectStatusArchived => 'آرکائیو';

  @override
  String get markProjectCompleted => 'مکمل نشان زد کریں';

  @override
  String get markProjectActive => 'فعال نشان زد کریں';

  @override
  String get archiveProject => 'آرکائیو';

  @override
  String get restoreProject => 'بحال کریں';

  @override
  String get relations => 'تعلقات';

  @override
  String get relateTo => 'جوڑیں';

  @override
  String get relationSubIssueOf => 'ذیلی ایشو از…';

  @override
  String get relationParentOf => 'والد از…';

  @override
  String get relationBlockedBy => 'بلاک از…';

  @override
  String get relationBlocking => 'بلاک کر رہا ہے…';

  @override
  String get relationRelatedTo => 'متعلقہ از…';

  @override
  String get relationDuplicateOf => 'نقل از…';

  @override
  String get relationGroupParent => 'والد';

  @override
  String get relationGroupSubIssues => 'ذیلی ایشوز';

  @override
  String get relationGroupBlockedBy => 'بلاک از';

  @override
  String get relationGroupBlocking => 'بلاک کر رہا ہے';

  @override
  String get relationGroupRelated => 'متعلقہ';

  @override
  String get relationGroupDuplicateOf => 'نقل از';

  @override
  String get relationGroupDuplicatedBy => 'اس کی نقل';

  @override
  String get copyId => 'ID کاپی کریں';

  @override
  String get ticketIdCopied => 'ٹکٹ ID کاپی ہو گئی';

  @override
  String get searchTicketsHint => 'ٹکٹس تلاش کریں…';

  @override
  String get noMatchingTickets => 'کوئی ٹکٹ میل نہیں کھاتا';

  @override
  String get clearAll => 'سب صاف کریں';

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs PRs',
      one: '1 PR',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos ریپوز',
      one: '1 ریپو',
    );
    return '$_temp0 آپ کے ریویو کے انتظار میں، $_temp1 میں';
  }

  @override
  String get manageWorkspacesSubtitle =>
      'ورک اسپیس کا نام بدلیں اور اس کا نشان تبدیل کریں — ترمیم کے لیے بائیں سے ایک منتخب کریں۔';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ورک اسپیسز',
      one: '1 ورک اسپیس',
      zero: 'کوئی ورک اسپیس نہیں',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos ریپوز',
      one: '1 ریپو',
      zero: 'کوئی ریپو نہیں',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents ایجنٹس',
      one: '1 ایجنٹ',
      zero: '0 ایجنٹس',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'شناخت';

  @override
  String get uploadImage => 'تصویر اپ لوڈ کریں';

  @override
  String get failedToSaveLogo =>
      'لوگو تصویر محفوظ نہیں ہو سکی۔ یقینی بنائیں کہ ایپ منتخب فائل پڑھ سکتی ہے۔';

  @override
  String get workspaceLogoHint =>
      'PNG، JPG یا GIF، 2 MB تک۔ ورنہ ورک اسپیس کا ابتدائی حرف استعمال ہوگا۔';

  @override
  String get workspaceNameFieldHelp =>
      'سوئچر، بریڈ کرمب اور ہر اسکرین پر دکھتا ہے۔';

  @override
  String get dangerZone => 'خطرناک زون';

  @override
  String get deleteThisWorkspace => 'یہ ورک اسپیس حذف کریں';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return '⁨$name⁩، اس کے ریپوزٹری کنکشنز، ایجنٹس اور میموری مستقل طور پر ہٹ جاتے ہیں۔ یہ واپس نہیں ہو سکتا۔';
  }

  @override
  String get discard => 'مسترد کریں';

  @override
  String discardChangesQuestion(String name) {
    return '⁨$name⁩ کی غیر محفوظ تبدیلیاں مسترد کریں؟';
  }

  @override
  String get workspaceUpdated => 'ورک اسپیس اپ ڈیٹ ہو گیا';

  @override
  String get editTitle => 'عنوان میں ترمیم';

  @override
  String get editDescription => 'تفصیل میں ترمیم';

  @override
  String get addDescription => 'تفصیل شامل کریں';

  @override
  String get prTitlePlaceholder => 'عنوان';

  @override
  String get prBodyPlaceholder => 'تفصیل لکھیں';

  @override
  String get write => 'لکھیں';

  @override
  String get overview => 'جائزہ';

  @override
  String get noFilesChanged => 'کوئی فائل نہیں بدلی';

  @override
  String get diff => 'Diff';

  @override
  String get preview => 'پیش منظر';

  @override
  String get imageDiffBefore => 'پہلے';

  @override
  String get imageDiffAfter => 'بعد';

  @override
  String get imageDiffModeTwoUp => 'دو کالم';

  @override
  String get imageDiffModeSwipe => 'سوائپ';

  @override
  String get imageDiffModeDifference => 'فرق';

  @override
  String imageDiffChangedPercent(String percent) {
    return '$percent٪ تبدیل';
  }

  @override
  String get imageDiffPictures => 'تصاویر';

  @override
  String get imageDiffSource => 'ماخذ';

  @override
  String get imageDiffDeleted => 'حذف شدہ';

  @override
  String get imageDiffAdded => 'شامل کیا گیا';

  @override
  String imageDiffDimensions(int width, int height) {
    return 'چ: ${width}px | ا: ${height}px';
  }

  @override
  String get outdated => 'پرانا';

  @override
  String get outdatedComments => 'پرانے تبصرے';

  @override
  String outdatedCountLabel(int count) {
    return '$count پرانے';
  }

  @override
  String get prTemplateLabel => 'ٹیمپلیٹ';

  @override
  String get prTemplateDefault => 'ڈیفالٹ';

  @override
  String get addReviewers => 'ریویوورز شامل کریں';

  @override
  String get addAssignees => 'تفویض شدہ شامل کریں';

  @override
  String get addLabels => 'لیبل شامل کریں';

  @override
  String get searchLabels => 'لیبل تلاش کریں…';

  @override
  String get noMatchingLabels => 'کوئی مماثل لیبل نہیں';

  @override
  String removeLabel(String label) {
    return '$label ہٹائیں';
  }

  @override
  String get searchUsers => 'لوگ تلاش کریں…';

  @override
  String get searchReviewers => 'لوگ اور ٹیمز تلاش کریں…';

  @override
  String get usersSectionLabel => 'لوگ';

  @override
  String get userStatusBusy => 'مصروف';

  @override
  String get teamsSectionLabel => 'ٹیمز';

  @override
  String get suggestedReviewers => 'تجویز کردہ ریویوورز';

  @override
  String get noMatchingUsers => 'کوئی مماثل شخص نہیں';

  @override
  String get noMatchingReviewers => 'کوئی میل نہیں';

  @override
  String get requiredByCodeOwners => 'کوڈ اونرز کی ضرورت';

  @override
  String reviewedOnBehalfOf(String login) {
    return '⁨$login⁩ کے ذریعے';
  }

  @override
  String get team => 'ٹیم';

  @override
  String get markdownBold => 'موٹا';

  @override
  String get markdownItalic => 'ترچھا';

  @override
  String get markdownHeading => 'سرخی';

  @override
  String get markdownBulletList => 'نقطہ دار فہرست';

  @override
  String get markdownChecklist => 'چیک لسٹ';

  @override
  String get markdownCode => 'کوڈ';

  @override
  String get markdownLink => 'لنک';

  @override
  String get markdownQuote => 'اقتباس';

  @override
  String get markdownSupported => 'Markdown معاون ہے';

  @override
  String get markdownAttachImages => 'تصاویر شامل کرنے کے لیے کلک کریں';

  @override
  String failedToUpdateTitle(String error) {
    return 'عنوان اپ ڈیٹ نہیں ہو سکا: ⁨$error⁩';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'تفصیل اپ ڈیٹ نہیں ہو سکی: ⁨$error⁩';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'ریویوورز اپ ڈیٹ نہیں ہو سکے: ⁨$error⁩';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'تفویض شدہ اپ ڈیٹ نہیں ہو سکے: ⁨$error⁩';
  }

  @override
  String failedToUpdateLabels(String error) {
    return 'لیبل اپ ڈیٹ نہیں ہو سکے: $error';
  }

  @override
  String get discardChangesConfirm => 'اپنی تبدیلیاں مسترد کریں؟';

  @override
  String get newPr => 'نیا PR';

  @override
  String get openPullRequest => 'pull request کھولیں';

  @override
  String get composePrSubtitle =>
      'آپ کی پش شدہ برانچ سے — کوئی ایجنٹ یا ٹکٹ شامل نہیں';

  @override
  String get createAsDraft => 'ڈرافٹ کے طور پر بنائیں';

  @override
  String get composePrPickBranches =>
      'تبدیلیوں کا پیش منظر دیکھنے کے لیے بیس اور کمپئیر برانچ منتخب کریں۔';

  @override
  String get composePrNothingToCompare =>
      'ان برانچز کے درمیان کوئی تبدیلی نہیں۔';

  @override
  String get repository => 'ریپوزٹری';

  @override
  String get baseBranchLabel => 'بیس';

  @override
  String get compareBranchLabel => 'کمپئیر';

  @override
  String get selectBranch => 'برانچ منتخب کریں';

  @override
  String get navMeetings => 'میٹنگز';

  @override
  String get meetingsNoWorkspace =>
      'میٹنگز دیکھنے کے لیے ورک اسپیس منتخب کریں۔';

  @override
  String get meetingsEmpty => 'ابھی کوئی میٹنگ نہیں';

  @override
  String get meetingsEmptyHint =>
      'اپنی پہلی میٹنگ ریکارڈ کریں — آڈیو اس ڈیوائس پر رہتی ہے اور ایجنٹ اسے نوٹس، فیصلوں اور ایکشن آئٹمز میں بدل دیتا ہے۔';

  @override
  String get meetingNotesHint =>
      'جلدی نوٹس لکھیں — میٹنگ کے بعد ایجنٹ انہیں پھیلا دیتا ہے۔';

  @override
  String get meetingSpeakerMe => 'آپ';

  @override
  String get meetingStatusRecording => 'ریکارڈ ہو رہا ہے';

  @override
  String get meetingStatusProcessing => 'پروسیس ہو رہا ہے';

  @override
  String get meetingStatusDone => 'مکمل';

  @override
  String get meetingStatusFailed => 'ناکام';

  @override
  String get meetingsSubtitle =>
      'اس ڈیوائس پر کیپچر اور ٹرانسکرائب، پھر ایجنٹ خلاصہ کرتا ہے۔';

  @override
  String get meetingsRecordMeeting => 'میٹنگ ریکارڈ کریں';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count اب پروسیس ہو رہی ہیں',
      one: '1 اب پروسیس ہو رہی ہے',
    );
    return '$_temp0';
  }

  @override
  String meetingsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count میٹنگز',
      one: '1 میٹنگ',
      zero: 'کوئی میٹنگ نہیں',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLedgerOpenActions => 'کھلے ایکشنز';

  @override
  String get meetingsLedgerDecisions => 'فیصلے';

  @override
  String get meetingsLiveOpen => 'ریکارڈنگ کھولیں';

  @override
  String get meetingTemplateShort => 'ٹیمپلیٹ';

  @override
  String get meetingsStatThisWeek => 'اس ہفتے';

  @override
  String get meetingsStatRecorded => 'ریکارڈ شدہ';

  @override
  String get meetingsFilterAll => 'سب';

  @override
  String get meetingsFilterDone => 'مکمل';

  @override
  String get meetingsFilterProcessing => 'پروسیس';

  @override
  String get meetingsSearchHint => 'عنوان، شخص، ایپ سے فلٹر…';

  @override
  String get meetingsBucketToday => 'آج';

  @override
  String get meetingsBucketYesterday => 'کل';

  @override
  String get meetingsBucketEarlierThisWeek => 'اس ہفتے پہلے';

  @override
  String get meetingsBucketLastWeek => 'گزشتہ ہفتہ';

  @override
  String get meetingsBucketOlder => 'پرانا';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فیصلے',
      one: '1 فیصلہ',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total ایکشن آئٹمز';
  }

  @override
  String get meetingsEnhancedPill => 'بہتر';

  @override
  String get meetingsTranscribing => 'ٹرانسکرائب اور خلاصہ ہو رہا ہے…';

  @override
  String get meetingsOpenAction => 'کھولیں';

  @override
  String get meetingsStopProcessing => 'روکیں';

  @override
  String get meetingsStillTranscribing =>
      'ابھی ٹرانسکرائب ہو رہا ہے — ختم ہونے پر خلاصہ نظر آئے گا۔';

  @override
  String get meetingsNoMatch => 'کوئی میٹنگ میل نہیں کھاتی';

  @override
  String get meetingsNoMatchHint => 'دوسرا فلٹر یا تلاش کا لفظ آزمائیں۔';

  @override
  String get meetingBackAllMeetings => 'تمام میٹنگز';

  @override
  String get meetingReRunSummary => 'خلاصہ دوبارہ چلائیں';

  @override
  String get meetingExport => 'برآمد';

  @override
  String get meetingAugmentingBanner =>
      'ٹرانسکرپٹ سے نوٹس بڑھائے جا رہے ہیں — فیصلے اور ایکشن آئٹمز نکالے جا رہے ہیں…';

  @override
  String get meetingTabNotes => 'نوٹس';

  @override
  String get meetingTabTranscript => 'ٹرانسکرپٹ';

  @override
  String get meetingTabActionItems => 'ایکشن آئٹمز';

  @override
  String get meetingTabDecisions => 'فیصلے';

  @override
  String get meetingNotesEnhancedToggle => 'بہتر';

  @override
  String get meetingNotesYoursToggle => 'آپ کے نوٹس';

  @override
  String get meetingEnhancedByAgent => 'ایجنٹ نے بہتر کیا · ٹرانسکرپٹ سے';

  @override
  String get meetingEnhancedPending => 'ایجنٹ ابھی اس خلاصے پر کام کر رہا ہے۔';

  @override
  String get meetingNotesEmpty => 'ابھی کوئی بہتر نوٹس نہیں۔';

  @override
  String get meetingNotesSavedLocally => 'مقامی طور پر محفوظ';

  @override
  String get meetingNotesSaving => 'محفوظ ہو رہا ہے…';

  @override
  String get meetingViewFullTranscript => 'پوری ٹرانسکرپٹ دیکھیں';

  @override
  String get meetingTranscriptSearchHint => 'ٹرانسکرپٹ تلاش کریں…';

  @override
  String get meetingSpeakerEveryone => 'سب';

  @override
  String get meetingSpeakerOthers => 'دیگر';

  @override
  String get meetingTranscriptEmpty => 'ابھی کوئی ٹرانسکرپٹ نہیں۔';

  @override
  String get meetingActionItemsEmpty => 'کوئی ایکشن آئٹم نہیں نکلا۔';

  @override
  String get meetingActionItemFrom => 'اس میٹنگ سے';

  @override
  String get meetingCreateTicket => 'ٹکٹ بنائیں';

  @override
  String meetingTicketCreated(String key) {
    return 'ٹکٹ ⁨$key⁩ بنا اور ڈسپیچ ہو گیا۔';
  }

  @override
  String get meetingTicketFailed => 'ٹکٹ نہیں بن سکا۔';

  @override
  String get meetingDecisionsEmpty => 'کوئی فیصلہ لاگ نہیں۔';

  @override
  String get meetingEditTitle => 'عنوان میں ترمیم';

  @override
  String get meetingTitleLabel => 'عنوان';

  @override
  String get meetingAddActionItem => 'ایکشن آئٹم شامل کریں';

  @override
  String get meetingEditActionItem => 'ایکشن آئٹم میں ترمیم';

  @override
  String get meetingDeleteActionItem => 'ایکشن آئٹم حذف کریں';

  @override
  String get meetingActionItemContentLabel => 'ایکشن آئٹم';

  @override
  String get meetingActionItemContentHint => 'کیا ہونا چاہیے؟';

  @override
  String get meetingActionItemOwnerLabel => 'مالک';

  @override
  String get meetingActionItemOwnerHint => 'ذمہ دار کون ہے؟ (اختیاری)';

  @override
  String get meetingAddDecision => 'فیصلہ شامل کریں';

  @override
  String get meetingEditDecision => 'فیصلے میں ترمیم';

  @override
  String get meetingDeleteDecision => 'فیصلہ حذف کریں';

  @override
  String get meetingDecisionContentLabel => 'فیصلہ';

  @override
  String get meetingDecisionContentHint => 'کیا فیصلہ ہوا؟';

  @override
  String get meetingReRunStarted => 'ٹرانسکرپٹ پر سمریزر دوبارہ چل رہا ہے…';

  @override
  String get meetingReRunNoTranscript =>
      'خلاصہ کرنے کے لیے ابھی کوئی ٹرانسکرپٹ نہیں۔';

  @override
  String get meetingNotesEmptyDescription =>
      'انہیں ٹرانسکرپٹ سے بنائیں، یا اپنے نوٹس لکھیں۔';

  @override
  String get meetingNotesGenerate => 'نوٹس بنائیں';

  @override
  String get meetingNotesWriteOwn => 'اپنے نوٹس لکھیں';

  @override
  String get meetingNothingTranscribed => 'کچھ بھی ٹرانسکرائب نہیں ہوا۔';

  @override
  String get meetingNothingTranscribedDescription =>
      'خلاصہ کرنے کے لیے کوئی ٹرانسکرپٹ نہیں، لیکن آپ اب بھی اپنے نوٹس رکھ سکتے ہیں۔';

  @override
  String get meetingOverviewSpeakers => 'بولنے والے';

  @override
  String get meetingOverviewSpeakersEmpty =>
      'ہر بولنے والے کا وقت ٹرانسکرپٹ دستیاب ہونے پر دکھایا جائے گا۔';

  @override
  String meetingOverviewMoreSpeakers(int count) {
    return '+$count مزید';
  }

  @override
  String meetingOverviewSpeakerShare(
    String name,
    String share,
    String duration,
  ) {
    return '$name: بولنے کے وقت کا $share، $duration';
  }

  @override
  String get meetingOverviewActionItemsAllDone =>
      'تمام ایکشن آئٹمز مکمل ہو گئے۔';

  @override
  String meetingOverviewViewAll(int count) {
    return 'سب دیکھیں ($count)';
  }

  @override
  String get meetingExportCopied =>
      'نوٹس Markdown کے طور پر کلپ بورڈ پر کاپی ہو گئے۔';

  @override
  String get meetingExportSaved => 'میٹنگ برآمد ہو گئی۔';

  @override
  String meetingExportFailed(String error) {
    return 'برآمد ناکام: ⁨$error⁩';
  }

  @override
  String get meetingExportNothing => 'ابھی برآمد کرنے کو کچھ نہیں۔';

  @override
  String get meetingPlaybackPlay => 'چلائیں';

  @override
  String get meetingPlaybackPause => 'توقف';

  @override
  String get meetingPlaybackUnavailable =>
      'اس ڈیوائس پر آڈیو پلے بیک دستیاب نہیں۔';

  @override
  String get meetingDetectedTitle => 'میٹنگ ملی';

  @override
  String meetingDetectedSubtitle(String label) {
    return 'لگتا ہے \"⁨$label⁩\" ہو رہی ہے۔ ریکارڈ کریں؟';
  }

  @override
  String get meetingDetectedSubtitleGeneric =>
      'لگتا ہے میٹنگ ہو رہی ہے۔ ریکارڈ کریں؟';

  @override
  String get meetingDetectedRecord => 'ریکارڈ';

  @override
  String get meetingDetectedDismiss => 'برطرف کریں';

  @override
  String get meetingAutoStopTitle => 'یہ میٹنگ ختم لگتی ہے۔ ریکارڈنگ روکیں؟';

  @override
  String get meetingAutoStopStop => 'روکیں';

  @override
  String get meetingAutoStopKeep => 'ریکارڈنگ جاری رکھیں';

  @override
  String get meetingAutoDetect => 'میٹنگز خود دریافت کریں';

  @override
  String get meetingAutoDetectDescription =>
      'کیلنڈر اور کانفرنسنگ ایپس دیکھیں اور میٹنگ شروع ہونے پر ریکارڈ کی پیشکش کریں۔';

  @override
  String get meetingsRecordingCrumb => 'ریکارڈ ہو رہا ہے…';

  @override
  String get meetingRecordTitleHint => 'میٹنگ عنوان';

  @override
  String get meetingRecordTappingLabel => 'کیپچر:';

  @override
  String get meetingRecordMic => 'مائیک';

  @override
  String get meetingRecordSystemAudio => 'سسٹم آڈیو';

  @override
  String get meetingRecordPause => 'توقف';

  @override
  String get meetingRecordResume => 'جاری رکھیں';

  @override
  String get meetingRecordStop => 'روکیں اور خلاصہ';

  @override
  String get meetingRecordYourNotes => 'آپ کے نوٹس';

  @override
  String get meetingRecordNotesPlaceholder =>
      'سنتے ہوئے ٹائپ کریں۔ چند ٹکڑے کافی ہیں — روکنے کے بعد ایجنٹ انہیں ٹرانسکرپٹ سے پھیلا دیتا ہے۔';

  @override
  String get meetingRecordLiveTranscript => 'لائیو ٹرانسکرپٹ';

  @override
  String get meetingRecordDecoding => 'ڈیوائس پر ڈی کوڈ ہو رہا ہے';

  @override
  String get meetingRecordListening =>
      'سن رہا ہے… تقریر ایک دو سیکنڈ میں یہاں آتی ہے، آپ / دیگر کے ٹیگ کے ساتھ۔';

  @override
  String get meetingRecordPausedHint =>
      'توقف — دوبارہ شروع کرنے تک آڈیو نظر انداز۔';

  @override
  String get meetingRecordNotActive => 'کوئی فعال ریکارڈنگ نہیں۔';

  @override
  String get meetingHudRecording => 'ریکارڈ ہو رہا ہے';

  @override
  String get meetingHudPaused => 'توقف';

  @override
  String get meetingHudOpen => 'کھولیں';

  @override
  String get meetingHudStop => 'روکیں';

  @override
  String get meetingToolbarPopOut => 'الگ کھولیں';

  @override
  String get meetingToolbarHoldToStop => 'ریکارڈنگ روکنے کے لیے دبا کر رکھیں';

  @override
  String get meetingToolbarSemanticLabel => 'میٹنگ ریکارڈنگ ٹول بار';

  @override
  String get orchestrate => 'آرکیسٹریٹ';

  @override
  String get orchestrationUnavailable => 'آرکیسٹریشن دستیاب نہیں';

  @override
  String get orchestrationApprove => 'پلان منظور کریں';

  @override
  String get orchestrationReject => 'مسترد کریں';

  @override
  String get orchestrationCancel => 'آرکیسٹریشن منسوخ کریں';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count کردار — $hires نئی بھرتیاں';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count ذیلی ٹکٹس';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'تخمینی لاگت: ⁨\$$amount⁩';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total ذیلی ٹکٹس مکمل';
  }

  @override
  String get orchestrationStatusProposed => 'تجویز کردہ';

  @override
  String get orchestrationStatusApproved => 'منظور';

  @override
  String get orchestrationStatusExecuting => 'عمل درآمد';

  @override
  String get orchestrationStatusSynthesizing => 'ترکیب';

  @override
  String get orchestrationStatusCompleted => 'مکمل';

  @override
  String get orchestrationStatusFailed => 'ناکام';

  @override
  String get orchestrationStatusCancelled => 'منسوخ';

  @override
  String get messageFailed => 'رن ناکام';

  @override
  String get turnLimitReached =>
      'باری کی حد پر رک گیا — جاری رکھنے کے لیے جواب دیں';

  @override
  String get retried => 'دوبارہ کوشش ہوئی';

  @override
  String replyingTo(String name) {
    return '⁨$name⁩ کو جواب';
  }

  @override
  String get silenceTimeoutLabel => 'خاموشی ٹائم آؤٹ (منٹ)';

  @override
  String get silenceTimeoutHint =>
      'مثال: 15 — اتنے دیر بغیر آؤٹ پٹ کے رن ختم کریں';

  @override
  String get capabilityJsonMode => 'JSON موڈ';

  @override
  String get capabilityModelSelection => 'ماڈل انتخاب';

  @override
  String get transcriptThinking => 'سوچ رہا ہے…';

  @override
  String transcriptThoughtFor(String duration) {
    return '$duration سوچا';
  }

  @override
  String get transcriptStatusMakingEdits => 'ترمیم ہو رہی ہے…';

  @override
  String get transcriptStatusReadingFiles => 'فائلیں پڑھی جا رہی ہیں…';

  @override
  String get transcriptStatusSearching => 'کوڈ بیس تلاش ہو رہا ہے…';

  @override
  String get transcriptStatusRunningCommands => 'کمانڈز چل رہی ہیں…';

  @override
  String get transcriptStatusResponding => 'جواب دے رہا ہے…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return '⁨$tool⁩ چل رہا ہے…';
  }

  @override
  String get transcriptInput => 'ان پٹ';

  @override
  String get transcriptOutput => 'آؤٹ پٹ';

  @override
  String get transcriptErrorLabel => 'خرابی';

  @override
  String get transcriptSandboxBlocked => 'سینڈ باکس نے ایک ایکشن روکا';

  @override
  String transcriptShowFullOutput(int kb) {
    return 'پورا آؤٹ پٹ دکھائیں (+⁨$kb⁩ KB)';
  }

  @override
  String transcriptShowAllLines(int count) {
    return 'تمام $count لائنیں دکھائیں';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return 'پہلی $count لائنیں دکھا رہے ہیں';
  }

  @override
  String get transcriptGrepNoMatches => 'کوئی میل نہیں';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '$matches میلز',
      one: '1 میل',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files فائلیں',
      one: '1 فائل',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return 'شخص $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => 'سپیکر کا نام بدلیں';

  @override
  String get meetingRenameSpeakerTitle => 'سپیکر کا نام بدلیں';

  @override
  String get meetingSpeakerNameLabel => 'نام';

  @override
  String get meetingSpeakerSuggestFromCalendar => 'اس میٹنگ کے مدعو افراد سے';

  @override
  String get meetingRenameSpeakerApplyAll =>
      'اس سپیکر کے تمام بلاکس پر لاگو کریں';

  @override
  String get meetingRenameSpeakerScopeHint =>
      'بند ہونے پر صرف منتخب لائن کا نام بدلتا ہے۔';

  @override
  String get meetingLinkEvent => 'ایونٹ سے لنک کریں';

  @override
  String get meetingChangeEvent => 'ایونٹ بدلیں';

  @override
  String get meetingLinkEventTitle => 'کیلنڈر ایونٹ سے لنک کریں';

  @override
  String get meetingLinkEventSearchHint => 'ایونٹس تلاش کریں';

  @override
  String get meetingLinkEventEmpty => 'قریب کوئی کیلنڈر ایونٹ نہیں';

  @override
  String get meetingUnlinkEvent => 'لنک ہٹائیں';

  @override
  String get calendarLinkExistingMeeting => 'موجودہ میٹنگ سے لنک کریں';

  @override
  String get calendarLinkMeetingTitle => 'میٹنگ لنک کریں';

  @override
  String get calendarLinkMeetingSearchHint => 'میٹنگز تلاش کریں';

  @override
  String get calendarLinkMeetingEmpty => 'لنک کرنے کے لیے کوئی میٹنگ نہیں';

  @override
  String get meetingRenameSpeakerFailed => 'سپیکر کا نام نہیں بدل سکا';

  @override
  String get calendarLinkUpdateFailed => 'کیلنڈر لنک اپ ڈیٹ نہیں ہو سکا';

  @override
  String get rename => 'نام بدلیں';

  @override
  String get notNow => 'ابھی نہیں';

  @override
  String get meetingSaveVoiceProfileTitle => 'وائس پروفائل محفوظ کریں؟';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return 'ان کا وائس پرنٹ محفوظ کر کے مستقبل کی میٹنگز میں ⁨$name⁩ کو خود پہچانیں۔';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return '⁨$name⁩ کا وائس پروفائل محفوظ ہو گیا';
  }

  @override
  String get meetingVoiceProfileSaveFailed => 'وائس پروفائل محفوظ نہیں ہو سکا';

  @override
  String get voiceProfilesSection => 'وائس پروفائلز';

  @override
  String get voiceProfilesDescription =>
      'محفوظ آوازیں مستقبل کی میٹنگز میں خود پہچانی جاتی ہیں۔';

  @override
  String get voiceProfilesEmpty =>
      'ابھی کوئی محفوظ آواز نہیں۔ میٹنگ ٹرانسکرپٹ میں سپیکر کا نام دیں، پھر \"وائس پروفائل محفوظ کریں\" منتخب کریں۔';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نمونے',
      one: '1 نمونہ',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => 'وائس پروفائل کا نام بدلیں';

  @override
  String get deleteVoiceProfileTitle => 'وائس پروفائل حذف کریں؟';

  @override
  String deleteVoiceProfileBody(String name) {
    return '⁨$name⁩ کو پہچاننا بند کریں؟ ان کا محفوظ وائس پرنٹ ہٹ جاتا ہے۔ ماضی کی میٹنگز میں لگے نام رہتے ہیں۔';
  }

  @override
  String get connectedLabel => 'منسلک';

  @override
  String get ideTabGeneral => 'عام';

  @override
  String get ideTabExplorer => 'ایکسپلورر';

  @override
  String get ideTabSourceControl => 'سورس کنٹرول';

  @override
  String get generalSectionTodos => 'Todos';

  @override
  String get generalSectionGoals => 'اہداف';

  @override
  String get goalRunStatusActive => 'فعال';

  @override
  String get goalRunStatusPaused => 'توقف';

  @override
  String get goalRunStatusCompleted => 'مکمل';

  @override
  String get goalRunStatusFailed => 'ناکام';

  @override
  String get goalRunStatusCancelled => 'منسوخ';

  @override
  String get goalRunStatusBudgetExhausted => 'بجٹ ختم';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return 'رن $run از $max · $cost از $cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return 'رن $run · $cost از $cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return 'آخری تاریخ $deadline';
  }

  @override
  String get goalRunPause => 'ہدف توقف';

  @override
  String get goalRunResume => 'ہدف جاری رکھیں';

  @override
  String goalRunResumeRaise(String cap) {
    return 'جاری رکھیں · حد ⁨$cap⁩ تک بڑھائیں';
  }

  @override
  String get goalRunStop => 'ہدف روکیں';

  @override
  String get generalSectionAgents => 'ایجنٹس';

  @override
  String get generalSectionTerminals => 'ٹرمینلز';

  @override
  String get generalTodosEmpty => 'ابھی کوئی todo نہیں';

  @override
  String get generalAgentsEmpty => 'کوئی ایجنٹ نہیں چل رہا';

  @override
  String get generalTerminalsEmpty => 'کوئی ٹرمینل کھلا نہیں';

  @override
  String get generalSectionBrowsers => 'براؤزرز';

  @override
  String get generalSectionComputers => 'کمپیوٹرز';

  @override
  String get generalBrowsersEmpty => 'کوئی براؤزر کھلا نہیں';

  @override
  String get generalComputersEmpty => 'کوئی کمپیوٹر کھلا نہیں';

  @override
  String get generalSectionPhones => 'فونز';

  @override
  String get generalPhonesEmpty => 'کوئی فون کھلا نہیں';

  @override
  String get pauseAgent => 'ایجنٹ توقف';

  @override
  String get resumeAgent => 'ایجنٹ جاری رکھیں';

  @override
  String get agentCannotPause =>
      'اس ایجنٹ کو توقف نہیں کیا جا سکتا — اسے روک دیں۔';

  @override
  String get goalClear => 'ہدف صاف کریں';

  @override
  String get undoLabelGoalClear => 'ہدف صاف کریں';

  @override
  String get todoStatusPending => 'شروع نہیں';

  @override
  String get todoStatusInProgress => 'جاری';

  @override
  String get todoStatusCompleted => 'مکمل';

  @override
  String get reorderTodo => 'Todo کی ترتیب بدلیں';

  @override
  String get focusTerminal => 'ٹرمینل پر فوکس';

  @override
  String get focusMachine => 'مشین پر فوکس';

  @override
  String get focusBrowser => 'براؤزر پر فوکس';

  @override
  String get todoEditorTitle => 'Todos میں ترمیم';

  @override
  String get todoEditorHint =>
      'فی لائن ایک آئٹم۔ زیرِ التوا کے لیے ⁨- [ ]⁩، جاری کے لیے ⁨- [~]⁩، مکمل کے لیے ⁨- [x]⁩۔';

  @override
  String get todoNeedsText => 'کمانڈ کے بعد کچھ متن شامل کریں';

  @override
  String get todoNotFound => 'کوئی مماثل todo نہیں';

  @override
  String get todoCleared => 'Todo فہرست صاف ہو گئی';

  @override
  String get todoNothingToCopy => 'کاپی کرنے کو کچھ نہیں';

  @override
  String todoAdded(String content) {
    return '\"⁨$content⁩\" شامل ہوا';
  }

  @override
  String todoStarted(String content) {
    return '\"⁨$content⁩\" شروع ہوا';
  }

  @override
  String todoCompleted(String content) {
    return '\"⁨$content⁩\" مکمل ہوا';
  }

  @override
  String todoRemoved(String content) {
    return '\"⁨$content⁩\" ہٹا دیا گیا';
  }

  @override
  String todoCopied(int count) {
    return '$count آئٹمز کاپی ہوئے';
  }

  @override
  String todoImported(int count) {
    return '$count آئٹمز درآمد ہوئے';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return 'نامعلوم todo کمانڈ \"⁨$name⁩\"';
  }

  @override
  String get terminal => 'ٹرمینل';

  @override
  String get ideCloseTab => 'ٹیب بند کریں';

  @override
  String get ideSplitEditor => 'ایڈیٹر تقسیم کریں';

  @override
  String get ideSplitRight => 'دائیں تقسیم';

  @override
  String get ideSplitDown => 'نیچے تقسیم';

  @override
  String get ideSplitLeft => 'بائیں تقسیم';

  @override
  String get ideSplitUp => 'اوپر تقسیم';

  @override
  String get ideCloseGroup => 'گروپ بند کریں';

  @override
  String get ideCloseOthers => 'دیگر بند کریں';

  @override
  String get ideCloseToRight => 'دائیں والے بند کریں';

  @override
  String get ideCloseSaved => 'محفوظ بند کریں';

  @override
  String get ideCloseAll => 'سب بند کریں';

  @override
  String get ideSplit => 'تقسیم';

  @override
  String get ideToggleSidebar => 'سائڈ بار ٹوگل کریں';

  @override
  String get ideNewTab => 'ایڈیٹر کھولیں';

  @override
  String get ideNewTabMenu => 'نیا ٹیب';

  @override
  String get ideReviewCode => 'کوڈ ریویو';

  @override
  String ideReviewCodeInRepo(String repo) {
    return 'کوڈ ریویو (⁨$repo⁩)';
  }

  @override
  String get ideRevertConfirmTitle => 'تبدیلیاں واپس کریں';

  @override
  String get ideRevertUntracked => 'ان ٹریکڈ فائلیں واپس نہیں ہو سکتیں';

  @override
  String get ideRevertFailed =>
      'فائلیں واپس نہیں ہو سکیں۔ گفتگو کا worktree دستیاب نہ ہو۔';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فائلیں',
      one: '1 فائل',
    );
    return '$_temp0 واپس نہیں ہو سکیں (ان ٹریکڈ)۔';
  }

  @override
  String get ideSearchMatchCase => 'کیس میل';

  @override
  String get ideSearchWholeWord => 'پورا لفظ';

  @override
  String get ideSearchRegex => 'Regex';

  @override
  String get ideSearchFilters => 'تلاش فلٹرز';

  @override
  String get ideSearchFilesToInclude => 'شامل کرنے کی فائلیں';

  @override
  String get ideSearchFilesToExclude => 'خارج کرنے کی فائلیں';

  @override
  String get ideNoOpenTabs =>
      'کوئی کھلا ٹیب نہیں — کھولنے کے لیے + استعمال کریں';

  @override
  String get ideBrowserAddressHint => 'ایڈریس درج کریں یا تلاش کریں';

  @override
  String get ideSimpleWebBrowser => 'سادہ ویب براؤزر';

  @override
  String get ideWebBrowser => 'ویب براؤزر';

  @override
  String get ideBrowserEnterUrl =>
      'براؤزنگ شروع کرنے کے لیے ایڈریس بار میں URL درج کریں';

  @override
  String get ideCodeServer => 'ایڈیٹر';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return '⁨$fileName⁩ کی تبدیلیاں محفوظ کریں؟';
  }

  @override
  String get ideUnsavedChangesBody =>
      'اگر محفوظ نہ کریں تو تبدیلیاں ضائع ہو جائیں گی۔';

  @override
  String get ideDontSave => 'محفوظ نہ کریں';

  @override
  String get editorAutoSave => 'آٹو سیو';

  @override
  String get editorAutoSaveDescription =>
      'ایمبیڈڈ ایڈیٹر میں تبدیلیاں خود محفوظ کریں۔';

  @override
  String get editorAutoSaveOff => 'آف';

  @override
  String get editorAutoSaveAfterDelay => 'وقفے کے بعد';

  @override
  String get editorAutoSaveOnFocusChange => 'فوکس بدلنے پر';

  @override
  String get ideCodeServerUnavailable => 'اس سرور پر code-server دستیاب نہیں';

  @override
  String get ideCodeServerUnavailableHint =>
      'سرور ہوسٹ پر code-server (⁨coder/code-server⁩) انسٹال کریں، پھر ایڈیٹر دوبارہ کھولیں۔';

  @override
  String get ideCodeServerInstalling => 'ایڈیٹر تیار ہو رہا ہے…';

  @override
  String get ideCodeServerOpenInBrowser => 'ایڈیٹر براؤزر میں کھولیں';

  @override
  String get ideCodeServerError => 'ایڈیٹر نہیں کھل سکا';

  @override
  String get paneSuspendedCaption =>
      'وسائل بچانے کے لیے معطل — فوکس پر دوبارہ لوڈ ہوتا ہے';

  @override
  String get ideFolderLoadFailed => 'یہ فولڈر لوڈ نہیں ہو سکا';

  @override
  String get ideFileSearchFailed => 'فائلیں تلاش نہیں ہو سکیں';

  @override
  String get ideSearchInFiles => 'فائلوں میں تلاش';

  @override
  String get ideNoContentMatches => 'کوئی میل نہیں';

  @override
  String get ideSourceControlCreatePr => 'pull request بنائیں';

  @override
  String get ideSourceControlNoChanges => 'کوئی تبدیلی نہیں';

  @override
  String get noReposInConversation => 'اس گفتگو میں کوئی ریپوزٹری نہیں';

  @override
  String get ideSourceControlNoSpace =>
      'اس کی تبدیلیاں دیکھنے کے لیے گفتگو کھولیں';

  @override
  String get ideFileLoading => 'لوڈ ہو رہا ہے…';

  @override
  String get ideFileBinary => 'بائنری فائل';

  @override
  String get mcpExternalServers => 'بیرونی MCP سرورز';

  @override
  String get mcpExternalServersDescription =>
      'بیرونی MCP سرورز سے منسلک ہوں (GitHub، Sentry، Postgres، براؤزر آٹومیشن)۔ Claude، Cursor، VS Code اور دیگر ٹولز کے لیے کنفیگر سرورز خود دریافت ہوتے ہیں۔';

  @override
  String get mcpApprovalMode => 'ٹول منظوری';

  @override
  String get mcpApprovalModeDescription =>
      'Control Center کے اپنے ٹولز کے کون سے اعمال، جو اس کے MCP اینڈ پوائنٹ کے ذریعے یا اس کے ایجنٹس کے ذریعے بلائے جاتے ہیں، بغیر پوچھے چلیں۔ پڑھنا ہمیشہ اجازت یافتہ ہے؛ اعلیٰ درجے پوچھتے ہیں۔ کسی رن کے اندر کے سرورز اس رن کی ایکشن پالیسی پر چلتے ہیں۔';

  @override
  String get mcpApprovalAlwaysAsk => 'ہمیشہ پوچھیں';

  @override
  String get mcpApprovalWrite => 'تحریر خود منظور';

  @override
  String get mcpApprovalYolo => 'سب خود منظور';

  @override
  String get mcpNoExternalServers => 'کوئی بیرونی MCP سرور نہیں ملا۔';

  @override
  String get mcpAuthorize => 'اجازت دیں';

  @override
  String get mcpReconnect => 'دوبارہ منسلک ہوں';

  @override
  String get mcpExternalConnectionsNote =>
      'بیرونی MCP سرورز ایجنٹ سرور پر چلتے ہیں (ڈیسک ٹاپ اور ویب شیئر)۔ OAuth سرورز کی اجازت صرف ڈیسک ٹاپ پر دستیاب ہے۔';

  @override
  String get mcpStatusConnected => 'منسلک';

  @override
  String get mcpStatusConnecting => 'منسلک ہو رہا ہے…';

  @override
  String get mcpStatusNeedsAuth => 'اجازت درکار';

  @override
  String get mcpStatusFailed => 'ناکام';

  @override
  String get mcpStatusCircuitOpen => 'توقف';

  @override
  String get mcpStatusDisabled => 'غیر فعال';

  @override
  String get providersAndModels => 'فراہم کنندگان اور ماڈلز';

  @override
  String get providersAndModelsDescription =>
      'بلٹ اِن ایجنٹ کے ہر فراہم کنندہ کی فہرست — API کلید سیٹ کریں یا براؤزر سے لاگ اِن، ہر منسلک فراہم کنندہ کے ماڈلز اور قیمت دیکھیں اور طے کریں کہ یہ ورک اسپیس کون سے استعمال کرے۔';

  @override
  String get syncNow => 'اب سنک کریں';

  @override
  String syncNowResult(int applied, int failed) {
    return 'سنک مکمل — $applied لاگو، $failed ناکام';
  }

  @override
  String syncNowFailed(String error) {
    return 'سنک ناکام: ⁨$error⁩';
  }

  @override
  String get denied => 'منع';

  @override
  String get allowed => 'اجازت';

  @override
  String allowProviderSemantic(String provider) {
    return '⁨$provider⁩ کی اجازت دیں';
  }

  @override
  String enabledViaEnv(String key) {
    return '⁨$key⁩ سے فعال';
  }

  @override
  String costPerMillion(String input, String output) {
    return '$input / $output فی 1M';
  }

  @override
  String contextTokens(String tokens) {
    return '$tokens سیاق';
  }

  @override
  String get subscriptionUsage => 'سبسکرپشن استعمال';

  @override
  String get subscriptionUsageUnavailable => 'دستیاب نہیں';

  @override
  String get subscriptionUsageExhausted => 'کوٹا ختم';

  @override
  String get subscriptionUsageSignInRequired => 'دوبارہ سائن اِن کریں';

  @override
  String get subscriptionUsageSignInExpired => 'سائن اِن ختم، اگلے رن پر تجدید';

  @override
  String subscriptionUsagePercentUsed(int percent) {
    return '$percent% استعمال';
  }

  @override
  String resetsIn(String duration) {
    return '$duration میں ری سیٹ';
  }

  @override
  String get feedbackHelpful => 'یہ مفید تھا';

  @override
  String get feedbackNotHelpful => 'یہ مفید نہیں تھا';

  @override
  String get modeChat => 'چیٹ';

  @override
  String get modePlan => 'پلان';

  @override
  String get modeReview => 'ریویو';

  @override
  String get modeOrchestrate => 'آرکیسٹریٹ';

  @override
  String get editorTheme => 'ایڈیٹر تھیم';

  @override
  String get editorThemeDescription =>
      'VS Code کلر تھیم درآمد کریں تاکہ ایمبیڈڈ diff اور ایڈیٹر آپ کے IDE سے میل کھائیں۔';

  @override
  String get editorThemePasteHint =>
      'VS Code کلر تھیم JSON فائل کا مواد پیسٹ کریں';

  @override
  String get editorThemeImported => 'تھیم درآمد ہو گئی';

  @override
  String get editorThemeInvalid => 'یہ درست VS Code تھیم نہیں لگتی';

  @override
  String get importTheme => 'تھیم درآمد کریں';

  @override
  String get clearTheme => 'تھیم صاف کریں';

  @override
  String get openInDiffViewer => 'Diff ویوور میں کھولیں';

  @override
  String get shellCommand => 'کمانڈ';

  @override
  String get shellOutput => 'آؤٹ پٹ';

  @override
  String get revertToHere => 'یہاں واپس کریں';

  @override
  String get revertConfirmBody =>
      'اس نقطے کے بعد پیغامات چھپائیں اور ایجنٹ کی فائل تبدیلیاں اس باری تک واپس کریں؟ آپ اسے انڈو کر سکتے ہیں۔';

  @override
  String get revert => 'واپس کریں';

  @override
  String get revertedToHere => 'یہاں واپس ہو گیا';

  @override
  String get nothingToRevert => 'واپس کرنے کو کچھ نہیں';

  @override
  String get undoRevert => 'واپسی انڈو کریں';

  @override
  String get revertUndone => 'واپسی انڈو ہو گئی';

  @override
  String get systemBehavior => 'سسٹم رویہ';

  @override
  String get keepAwakeTitle => 'ایجنٹس چلتے ہوئے کمپیوٹر جاگتا رکھیں';

  @override
  String get keepAwakeOnSubtitle => 'ایجنٹ کام کرتے ہوئے کمپیوٹر سوت نہیں';

  @override
  String get keepAwakeOffSubtitle =>
      'ایجنٹ کام کرتے ہوئے بھی کمپیوٹر سو سکتا ہے';

  @override
  String get spaces => 'اسپیسز';

  @override
  String get spacesHomeDescription =>
      'فہرست سے اسپیس منتخب کریں، یا نئی شروع کریں۔';

  @override
  String get noSpacesYet => 'ابھی کوئی اسپیس نہیں';

  @override
  String get newSpace => 'نئی اسپیس';

  @override
  String get spaceName => 'اسپیس کا نام';

  @override
  String get spaceReposHint => 'شامل کرنے کے ریپوز';

  @override
  String get newSpaceFolder => 'نیا فولڈر';

  @override
  String get folderName => 'فولڈر کا نام';

  @override
  String get renameSpaceFolder => 'فولڈر کا نام تبدیل کریں';

  @override
  String get deleteSpaceFolder => 'فولڈر حذف کریں';

  @override
  String get moveSpaceToFolder => 'فولڈر میں منتقل کریں';

  @override
  String get removeSpaceFromFolder => 'فولڈر سے ہٹائیں';

  @override
  String get spaceFolderActions => 'فولڈر کے اقدامات';

  @override
  String get deleteFolderWithSpacesWarning =>
      'اسپیسز کو مستقل طور پر حذف کرنے سے ان کے پیغامات اور ورک ٹریز سب کے لیے ختم ہو جاتے ہیں۔ اسے واپس نہیں کیا جا سکتا۔';

  @override
  String get deleteSpacesInFolder =>
      'اس فولڈر میں موجود اسپیسز مستقل طور پر حذف کریں';

  @override
  String get deleteFolderAndSpaces => 'فولڈر اور اسپیسز حذف کریں';

  @override
  String get keepSpacesInFolder =>
      'بصورتِ دیگر، اسپیسز کسی فولڈر میں نہیں رہیں گی۔';

  @override
  String get noSpaceFoldersYet => 'ابھی کوئی فولڈر نہیں';

  @override
  String get ideSourceControl => 'سورس کنٹرول';

  @override
  String get stagedChanges => 'سٹیج شدہ تبدیلیاں';

  @override
  String get changes => 'تبدیلیاں';

  @override
  String get stageFile => 'سٹیج';

  @override
  String get unstageFile => 'ان سٹیج';

  @override
  String get stageAll => 'تمام تبدیلیاں سٹیج کریں';

  @override
  String get unstageAll => 'سب ان سٹیج کریں';

  @override
  String get stageChangesToCommit => 'کمیٹ کے لیے تبدیلیاں سٹیج کریں';

  @override
  String get syncToPrHead => 'تازہ ترین PR کمیٹس پُل کریں';

  @override
  String get syncedToPrHead => 'تازہ ترین PR کمیٹس سے سنک';

  @override
  String get syncPrHeadDirty => 'سنک سے پہلے تبدیلیاں کمیٹ یا مسترد کریں';

  @override
  String get syncPrHeadFailed => 'PR ہیڈ سے سنک نہیں ہو سکا';

  @override
  String get spaceLabel => 'اسپیس';

  @override
  String get keybindingNewSpace => 'نئی اسپیس';

  @override
  String get jumpToLatest => 'تازہ ترین پر جائیں';

  @override
  String get streaming => 'اسٹریمنگ';

  @override
  String get newMessages => 'نیا';

  @override
  String get copyLink => 'لنک کاپی کریں';

  @override
  String get linkCopied => 'لنک کاپی ہو گیا';

  @override
  String get agentResponding => 'ایجنٹ جواب دے رہا ہے';

  @override
  String get agentFinished => 'ایجنٹ ختم ہوا';

  @override
  String get harnessConnectProviderForModels =>
      'ماڈلز دیکھنے کے لیے فراہم کنندہ منسلک کریں۔';

  @override
  String get providerSignOut => 'سائن آؤٹ';

  @override
  String get providerWaitingForDeviceCode =>
      'براؤزر میں کوڈ کی تصدیق کا انتظار…';

  @override
  String get providerDeviceCodeHint =>
      'چیک کریں کہ یہ کوڈ براؤزر والے سے میل کھاتا ہے، پھر منظور کریں۔';

  @override
  String get providerPlanUsageLoading => 'پلان استعمال چیک ہو رہا ہے…';

  @override
  String get providerPlanUsageUnavailable => 'اس پلان نے استعمال نہیں بتایا۔';

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return '⁨$provider⁩ API کلید ہٹائیں؟';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return 'محفوظ کلید حذف ہو جاتی ہے اور دوبارہ نہیں دکھائی جا سکتی۔ ⁨$provider⁩ ماڈلز استعمال کرنے والے ایجنٹس نئی کلید پیسٹ کرنے تک رک جاتے ہیں۔';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return '⁨$provider⁩ ہٹائیں؟';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return 'فراہم کنندہ ⁨$provider⁩ اور اس کی محفوظ کلید حذف ہو جاتے ہیں۔ اس کے ماڈلز پر پن ایجنٹس رک جاتے ہیں۔';
  }

  @override
  String get providerApiKeyHint => 'API کلید پیسٹ کریں';

  @override
  String get providerApiKeyStoredHint =>
      'شامل کرنے کے لیے دوسری API کلید پیسٹ کریں';

  @override
  String get providerAddAnotherAccount => 'دوسرا اکاؤنٹ شامل کریں';

  @override
  String get providerActiveBadge => 'فعال';

  @override
  String get providerOauthAccountFallback => 'OAuth اکاؤنٹ';

  @override
  String get providerApiKeyFallback => 'API کلید';

  @override
  String get providerRemoveCredentialConfirmTitle => 'یہ کریڈینشل ہٹائیں؟';

  @override
  String get providerSignOutAccountConfirmTitle => 'اس اکاؤنٹ سے سائن آؤٹ؟';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return '⁨$provider⁩ استعمال کرنے والے ایجنٹس اس کی دوسری کلیدوں اور اکاؤنٹس پر واپس جاتے ہیں۔ کوئی نہ بچے تو شامل کرنے تک رک جاتے ہیں۔';
  }

  @override
  String get providerBaseUrlHint => 'بیس URL (اختیاری)';

  @override
  String get addProvider => 'فراہم کنندہ شامل کریں';

  @override
  String get noCustomProviders => 'ابھی کوئی حسبِ ضرورت فراہم کنندہ نہیں۔';

  @override
  String get providerNameLabel => 'نام';

  @override
  String get apiTypeLabel => 'API قسم';

  @override
  String get providerBaseUrlLabel => 'بیس URL';

  @override
  String get providerApiKeyOptionalHint => 'API کلید (اختیاری)';

  @override
  String get dialectOpenAiCompatible => 'OpenAI موافق';

  @override
  String get dialectAnthropicCompatible => 'Anthropic موافق';

  @override
  String get removeProviderTooltip => 'فراہم کنندہ ہٹائیں';

  @override
  String get providerLogInWithBrowser => 'براؤزر سے لاگ اِن';

  @override
  String providerLoginDialogTitle(String provider) {
    return '⁨$provider⁩ میں لاگ اِن';
  }

  @override
  String get providerLabel => 'فراہم کنندہ';

  @override
  String get selectProviderToLogin => 'لاگ اِن کے لیے فراہم کنندہ منتخب کریں';

  @override
  String providerLoginFailed(String error) {
    return 'لاگ اِن ناکام: ⁨$error⁩';
  }

  @override
  String get providerWaitingForBrowser => 'براؤزر میں اجازت کا انتظار…';

  @override
  String get providerPasteCodeHint => 'یا براؤزر سے کوڈ پیسٹ کریں';

  @override
  String get providerCompleteLogin => 'مکمل کریں';

  @override
  String get providerConnectedApiKey => 'API کلید سے منسلک';

  @override
  String get providerConnectedOauth => 'منسلک';

  @override
  String providerConnectedAccount(String account) {
    return 'منسلک · ⁨$account⁩';
  }

  @override
  String get providerLocalReady => 'مقامی · تیار';

  @override
  String get providerNotConnected => 'منسلک نہیں';

  @override
  String get preparingWorkspace => 'ورک اسپیس تیار ہو رہا ہے…';

  @override
  String provisioningRunningTasks(String repo) {
    return '⁨$repo⁩ کے worktree ٹاسک چل رہے ہیں…';
  }

  @override
  String provisioningCloningRepo(String repo) {
    return '⁨$repo⁩ کلون ہو رہا ہے…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return '⁨$repo⁩ میں pull request چیک آؤٹ ہو رہا ہے…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return 'ایجنٹ ⁨$agent⁩ سیٹ اپ ہو رہا ہے…';
  }

  @override
  String get workspacePrepFailed => 'ورک اسپیس سیٹ اپ ناکام';

  @override
  String get workspacePrepStopped => 'ورک اسپیس سیٹ اپ رک گیا';

  @override
  String get stopWorkspacePrep => 'تیاری روکیں';

  @override
  String get stopWorkspacePrepTooltip => 'اس ورک اسپیس کی تیاری روکیں';

  @override
  String get stopWorkspacePrepConfirm =>
      'اس ورک اسپیس کی تیاری روکیں؟ جاری کلون ضائع ہوتا ہے — آپ اسے یہاں سے دوبارہ شروع کر سکتے ہیں۔';

  @override
  String messageWillSendWhenReady(int count) {
    return '$count پیغام(ات) تیار ہونے پر بھیجیں گے';
  }

  @override
  String get membersNav => 'اراکین';

  @override
  String get membersSettingsDescription =>
      'اس ورک اسپیس تک رسائی والے لوگ: روسٹر، دعوتیں اور آڈٹ ٹریل';

  @override
  String get memberRosterLabel => 'رکن روسٹر';

  @override
  String get memberRepoAccessAction => 'ریپو رسائی';

  @override
  String memberRepoAccessTitle(String name) {
    return '⁨$name⁩ کی ریپو رسائی';
  }

  @override
  String get roleOwner => 'مالک';

  @override
  String get roleAdmin => 'ایڈمن';

  @override
  String get roleMember => 'رکن';

  @override
  String get roleViewer => 'ناظر';

  @override
  String get roleGuest => 'مہمان';

  @override
  String get removeMemberTitle => 'رکن ہٹائیں';

  @override
  String removeMemberConfirm(String name) {
    return '⁨$name⁩ کو اس ورک اسپیس سے ہٹائیں؟ انہیں فوراً رسائی نہیں رہے گی۔';
  }

  @override
  String get transferOwnershipAction => 'ملکیت منتقل کریں';

  @override
  String get transferOwnershipTitle => 'ملکیت منتقل کریں';

  @override
  String transferOwnershipConfirm(String name) {
    return '⁨$name⁩ کو اس ورک اسپیس کا مالک بنائیں؟ آپ ایڈمن بن جاتے ہیں۔ صرف مالک ورک اسپیس حذف کر سکتا ہے یا دوسرے ایڈمن کا کردار بدل سکتا ہے۔';
  }

  @override
  String get transferOwnershipCta => 'منتقل کریں';

  @override
  String get auditTrailLabel => 'اجازت آڈٹ ٹریل';

  @override
  String get auditTrailDescription =>
      'ہر اجازت اور انکار، ہیش چین تاکہ تبدیل یا حذف اندراج پکڑا جا سکے۔';

  @override
  String get auditVerifyChain => 'چین تصدیق کریں';

  @override
  String auditChainIntact(int count) {
    return 'چین درست — $count اندراجات تصدیق شدہ';
  }

  @override
  String auditChainBroken(int seq, String reason) {
    return 'چین اندراج $seq پر ٹوٹا: ⁨$reason⁩';
  }

  @override
  String get auditEmpty => 'ابھی کوئی فیصلہ ریکارڈ نہیں۔';

  @override
  String get auditDenied => 'منع';

  @override
  String get auditAllowed => 'اجازت';

  @override
  String auditOnBehalfOf(String user) {
    return '⁨$user⁩ کے لیے';
  }

  @override
  String get policyTemplatesLabel => 'پالیسی ٹیمپلیٹس';

  @override
  String get policyTemplatesDescription =>
      'ابتدائی رویہ لاگو کریں، یا ایک ورک اسپیس سے دوسرے میں منتقل کریں۔';

  @override
  String get policyTemplateStrict => 'سخت';

  @override
  String get policyTemplateBalanced => 'متوازن';

  @override
  String get policyTemplatePermissive => 'نرم';

  @override
  String get policyTemplateApply => 'لاگو کریں';

  @override
  String policyTemplateApplied(int count) {
    return '$count قواعد لاگو ہوئے';
  }

  @override
  String get policyExport => 'پالیسی کاپی کریں';

  @override
  String get policyExported => 'پالیسی کلپ بورڈ پر کاپی ہو گئی';

  @override
  String get policyImport => 'پالیسی پیسٹ کریں';

  @override
  String policyImported(int count) {
    return '$count قواعد درآمد ہوئے';
  }

  @override
  String get approveAndRemember => '8 گھنٹے کے لیے منظور';

  @override
  String get approveAndRememberTooltip =>
      'اس ایکشن کو منظور کرتا ہے اور اس اسپیس میں ملتے جلتے 8 گھنٹے تک نہیں پوچھتا۔ خود ختم ہوتا ہے۔';

  @override
  String get unknownUserLabel => 'نامعلوم صارف';

  @override
  String get inviteMember => 'رکن مدعو کریں';

  @override
  String get inviteRepoAccessHeader => 'ریپوزٹری رسائی';

  @override
  String get inviteRepoAccessExplainer =>
      'صرف وہ ریپوزٹریز شیئر ہوتی ہیں جنہیں آپ چیک کریں، اس سطح پر جو آپ منتخب کریں۔ باقی چھپی رہتی ہیں۔';

  @override
  String get grantLevelRead => 'پڑھیں';

  @override
  String get grantLevelReview => 'ریویو';

  @override
  String get grantLevelWrite => 'لکھیں';

  @override
  String get inviteExpiryLabel => 'ختم ہوتا ہے';

  @override
  String get expiryOneDay => '1 دن';

  @override
  String get expirySevenDays => '7 دن';

  @override
  String get expiryThirtyDays => '30 دن';

  @override
  String get createInviteAction => 'دعوت بنائیں';

  @override
  String get inviteOneTimeCodeLabel => 'ایک بار استعمال کوڈ';

  @override
  String get inviteCodeShownOnce =>
      'یہ کوڈ صرف ایک بار دکھتا ہے — ابھی کاپی کریں۔';

  @override
  String get inviteLinkLabel => 'دعوتی لنک';

  @override
  String get inviteRedeemHint =>
      'مدعو کو کوڈ بھیجیں؛ وہ اسے آپ کے سرور URL پر استعمال کریں۔';

  @override
  String get inviteScanQr => 'یا استعمال کے لیے اسکین کریں';

  @override
  String get inviteLoopbackWarningTitle => 'دعوت مقامی ایڈریس کی طرف ہے';

  @override
  String get inviteLoopbackWarningBody =>
      'دوسری مشینوں کے تعاون کنندگان اس سرور تک نہیں پہنچ سکتے۔ ٹنل شروع کریں (ترتیبات ← انٹیگریشنز ← یہ سرور شیئر کریں) یا نیٹ ورک سے بائنڈ کریں تاکہ باہر کے صارفین منسلک ہوں۔';

  @override
  String get inviteStatusOpen => 'کھلی';

  @override
  String get inviteStatusUsed => 'استعمال شدہ';

  @override
  String get inviteStatusRevoked => 'منسوخ';

  @override
  String get inviteStatusExpired => 'ختم';

  @override
  String inviteCreatedTime(String time) {
    return '$time بنائی گئی';
  }

  @override
  String inviteExpiresOn(String date) {
    return '$date ختم';
  }

  @override
  String get noActivityYet => 'ابھی کوئی سرگرمی نہیں';

  @override
  String get couldNotLoadMembers => 'اراکین لوڈ نہیں ہو سکے';

  @override
  String get couldNotLoadInvites => 'دعوتیں لوڈ نہیں ہو سکیں';

  @override
  String get couldNotLoadActivity => 'سرگرمی لوڈ نہیں ہو سکی';

  @override
  String get yourDevices => 'آپ کی ڈیوائسز';

  @override
  String get yourDevicesDescription =>
      'اس سرور پر آپ کے اکاؤنٹ سے پیئر کلائنٹس۔';

  @override
  String get noOwnDevices => 'آپ کے اکاؤنٹ سے ابھی کوئی ڈیوائس پیئر نہیں';

  @override
  String get renameDeviceTitle => 'ڈیوائس کا نام بدلیں';

  @override
  String get revokeDeviceTitle => 'ڈیوائس منسوخ کریں';

  @override
  String revokeDeviceConfirm(String label) {
    return '⁨$label⁩ منسوخ کریں؟ یہ فوراً منقطع ہو جاتی ہے اور اس سرور تک نہیں پہنچ سکتی۔';
  }

  @override
  String devicePairedTime(String time) {
    return '$time پیئر ہوئی';
  }

  @override
  String deviceLastSeenTime(String time) {
    return 'آخری بار $time';
  }

  @override
  String get deviceNeverSeen => 'کبھی منسلک نہیں';

  @override
  String get profileSectionLabel => 'پروفائل';

  @override
  String get profileSectionDescription =>
      'اس ورک اسپیس میں ٹیم اور git کمیٹ تصنیف میں آپ کیسے نظر آتے ہیں۔ خالی فیلڈز اکاؤنٹ کا نام اور ای میل وراثت میں لیتی ہیں۔';

  @override
  String get displayNameLabel => 'ڈسپلے نام';

  @override
  String get emailLabel => 'ای میل';

  @override
  String get gitAuthorNameLabel => 'Git مصنف نام';

  @override
  String get gitAuthorEmailLabel => 'Git مصنف ای میل';

  @override
  String get profileSaved => 'پروفائل محفوظ ہو گیا';

  @override
  String get presenceOnline => 'آن لائن';

  @override
  String get presenceIdle => 'بیکار';

  @override
  String get presenceTyping => 'ٹائپ کر رہا ہے…';

  @override
  String presenceNameStatus(String name, String status) {
    return '⁨$name⁩ — $status';
  }

  @override
  String get presenceRailLabel => 'کون آن لائن ہے';

  @override
  String presencePlusCount(int count) {
    return '⁨+$count⁩';
  }

  @override
  String get dndTooltipOn => 'ڈو ناٹ ڈسٹرب آن کریں';

  @override
  String get dndTooltipOff => 'ڈو ناٹ ڈسٹرب آف کریں';

  @override
  String get startPresenting => 'پیش کرنا شروع کریں';

  @override
  String get stopPresenting => 'پیش کرنا روکیں';

  @override
  String spotlightPresentingBanner(String name) {
    return '⁨$name⁩ پیش کر رہے ہیں';
  }

  @override
  String get spotlightLeave => 'چھوڑیں';

  @override
  String typingIndicator(String name) {
    return '⁨$name⁩ ٹائپ کر رہے ہیں…';
  }

  @override
  String get ideTabNotes => 'نوٹس';

  @override
  String get ideSidebarAllViews => 'تمام مناظر';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return 'تمام مناظر ($count چھپے)';
  }

  @override
  String get ideSidebarPinView => 'سائڈ بار پر پن کریں';

  @override
  String get ideSidebarUnpinView => 'سائڈ بار سے ان پن';

  @override
  String get notesEmptyHint =>
      'جو بھی یہ گفتگو اٹھائے اس کے لیے نوٹ شامل کریں…';

  @override
  String get notesEditTooltip => 'نوٹ میں ترمیم';

  @override
  String notesUpdatedBy(String name, String time) {
    return '⁨$name⁩ نے اپ ڈیٹ کیا · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '⁨$name⁩ ترمیم کر رہے ہیں';
  }

  @override
  String get notesSaveFailed => 'نوٹ محفوظ نہیں ہو سکا';

  @override
  String get reactionAddTooltip => 'ردعمل شامل کریں';

  @override
  String reactionToggleTooltip(String emoji) {
    return '⁨$emoji⁩ سے ردعمل';
  }

  @override
  String get reactionThumbsUp => 'انگوٹھا اوپر';

  @override
  String get reactionThumbsDown => 'انگوٹھا نیچے';

  @override
  String get reactionLaugh => 'ہنسی';

  @override
  String get reactionHooray => 'واہ';

  @override
  String get reactionConfused => 'الجھن';

  @override
  String get reactionHeart => 'دل';

  @override
  String get reactionRocket => 'راکٹ';

  @override
  String get reactionEyes => 'آنکھیں';

  @override
  String get commentReact => 'ردعمل';

  @override
  String get commentResolveThread => 'تھریڈ حل کریں';

  @override
  String get commentReopenThread => 'تھریڈ دوبارہ کھولیں';

  @override
  String get commentCopyLink => 'تبصرے کا لنک نقل کریں';

  @override
  String get commentCopyMarkdown => 'Markdown کے طور پر نقل کریں';

  @override
  String get commentCopyThreadMarkdown =>
      'تھریڈ کو Markdown کے طور پر نقل کریں';

  @override
  String get commentCopyPrompt => 'پرامپٹ کے طور پر نقل کریں';

  @override
  String get commentCopyThreadPrompt => 'تھریڈ کو پرامپٹ کے طور پر نقل کریں';

  @override
  String get commentSendToAgent => 'ایجنٹ کو بھیجیں';

  @override
  String get commentDelete => 'تبصرہ حذف کریں';

  @override
  String get commentEdit => 'تبصرہ ترمیم کریں';

  @override
  String get commentActions => 'تبصرے کے اقدامات';

  @override
  String get commentDeleteTitle => 'یہ تبصرہ حذف کریں؟';

  @override
  String get commentDeleteBody => 'یہ پل ریکوئسٹ سے ہٹ جاتا ہے۔';

  @override
  String get commentSentToAgent => 'ایجنٹ کو بھیج دیا گیا';

  @override
  String get commentSendFailed => 'یہ تبصرہ ایجنٹ کو نہیں بھیجا جا سکا';

  @override
  String get commentDeleteFailed => 'یہ تبصرہ حذف نہیں ہو سکا';

  @override
  String get autonomyDialLabel => 'خود مختاری';

  @override
  String get autonomyProposeOnly => 'صرف تجویز';

  @override
  String get autonomyActWithApproval => 'منظوری سے عمل';

  @override
  String get autonomyActFreely => 'آزادانہ عمل';

  @override
  String get autonomyDefaultOption => 'ڈیفالٹ';

  @override
  String get checkerLabel => 'چیکر';

  @override
  String get checkerNone => 'کوئی نہیں';

  @override
  String get checkerCaption =>
      'چیکر دوسرے ایجنٹس کے مکمل رنز کا ریویو کرتا ہے۔';

  @override
  String get takeoverTooltip => 'worktree سنبھالیں';

  @override
  String get takeoverBannerSelf => 'آپ نے اس گفتگو کا worktree سنبھال لیا ہے';

  @override
  String takeoverBannerOther(String name) {
    return '⁨$name⁩ نے اس گفتگو کا worktree سنبھال لیا ہے';
  }

  @override
  String get handBackButton => 'واپس کریں';

  @override
  String get handBackDialogTitle => 'worktree واپس کریں';

  @override
  String get handBackDialogNoteHint => 'ایجنٹ کے لیے اختیاری نوٹ…';

  @override
  String takeoverFailed(String message) {
    return 'سنبھال نہیں سکے: ⁨$message⁩';
  }

  @override
  String handBackFailed(String message) {
    return 'واپس نہیں کر سکے: ⁨$message⁩';
  }

  @override
  String get planStudioTitle => 'Plan Studio';

  @override
  String get plansTitle => 'پلانز';

  @override
  String get plansSubtitle => 'فعال پلانز، پلان دستاویزات اور پلی بکس';

  @override
  String get plansActiveSection => 'فعال پلانز';

  @override
  String get plansDocumentsSection => 'پلان دستاویزات';

  @override
  String get plansPlaybooksSection => 'پلے بکس';

  @override
  String get plansNoActive => 'ابھی کوئی فعال پلان نہیں۔';

  @override
  String get plansNoDocuments => 'ابھی کوئی پلان دستاویز نہیں۔';

  @override
  String get plansNoPlaybooks => 'ابھی کوئی پلی بک نہیں۔';

  @override
  String get planNotFound => 'پلان نہیں ملا۔';

  @override
  String get planOpenInStudio => 'کھولیں';

  @override
  String get planNodeTitle => 'عنوان';

  @override
  String get planNodeDescription => 'تفصیل';

  @override
  String get planNodeDescriptionHint => 'اس مرحلے کو کیا کرنا چاہیے…';

  @override
  String get planNodeApplyDescription => 'لاگو کریں';

  @override
  String get planNodeRole => 'کردار';

  @override
  String get planNodeDependencies => 'انحصار';

  @override
  String get planNodeDependenciesHint => 'انحصار شامل کریں';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count انحصار',
      one: '1 انحصار',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies =>
      'کوئی انحصار نہیں، اس لیے پلان شروع ہوتے ہی یہ چلتا ہے';

  @override
  String get planNodeOutputSchema => 'آؤٹ پٹ اسکیما (JSON)';

  @override
  String get planNodeEstimate => 'تخمینہ';

  @override
  String get planNodeProvenance => 'ماخذ';

  @override
  String get planNodeAlreadyExecuted =>
      'پہلے چل چکا ہے — یہاں سے ترمیم پلان کو فورک کرتی ہے۔';

  @override
  String get planNewNodeTitle => 'نیا مرحلہ';

  @override
  String get planEstimateNoHistory => 'ابھی کوئی ہسٹری نہیں';

  @override
  String get planEstimateBlastUnknown => 'اثر کا دائرہ: نامعلوم';

  @override
  String get planEstimatePartial => 'جزوی';

  @override
  String get planEstimateAction => 'تخمینہ';

  @override
  String planEstimateDuration(String range) {
    return 'مدت $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return 'اثر کا دائرہ: $files فائلیں، $symbols سمبلز';
  }

  @override
  String get planApprove => 'پلان منظور کریں';

  @override
  String get planApproveSelectedNodes => 'منتخب منظور کریں';

  @override
  String get planReject => 'مسترد کریں';

  @override
  String get planCancel => 'رن منسوخ کریں';

  @override
  String get planContinueNode => 'نوڈ جاری رکھیں';

  @override
  String get planTotalNotEstimated => 'ابھی تخمینہ نہیں';

  @override
  String get planBudgetExceeded => 'بجٹ سے زیادہ';

  @override
  String planBudgetCeiling(String amount) {
    return 'بجٹ ≤ ⁨\$$amount⁩';
  }

  @override
  String get planVersionsTitle => 'ورژنز';

  @override
  String get planNoRevisions => 'ابھی کوئی ریویژن نہیں۔';

  @override
  String get planDiffIdentical => 'کوئی تبدیلی نہیں۔';

  @override
  String get planDiffGoalChanged => 'ہدف بدلا';

  @override
  String get planDiffBudgetChanged => 'بجٹ بدلا';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'v⁨$fromRev⁩ سے v⁨$toRev⁩ تک تبدیلیاں';
  }

  @override
  String planDiffAdded(String node) {
    return '⁨$node⁩ شامل ہوا';
  }

  @override
  String planDiffRemoved(String node) {
    return '⁨$node⁩ ہٹایا گیا';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return '⁨$node⁩ بدلا: ⁨$fields⁩';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return 'کنارہ شامل: ⁨$edge⁩';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return 'کنارہ ہٹایا: ⁨$edge⁩';
  }

  @override
  String planDiffRoleAdded(String role) {
    return 'کردار شامل: ⁨$role⁩';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return 'کردار ہٹایا: ⁨$role⁩';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return 'کردار دوبارہ تفویض: ⁨$role⁩';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return 'پلان دوبارہ بنا: آپ نے v⁨$approved⁩ منظور کیا، اب v⁨$current⁩ ہے۔ جاری رہنے سے پہلے diff دیکھیں۔';
  }

  @override
  String planLiveActualCost(String amount) {
    return 'اصل لاگت: ⁨\$$amount⁩';
  }

  @override
  String get planPlaybookRun => 'چلائیں';

  @override
  String get planPlaybookDelete => 'پلے بک حذف کریں';

  @override
  String get planPlaybookProposed =>
      'پلان تجویز ہوا — Plan Studio میں منظور کریں۔';

  @override
  String get planPlaybookAnchorTicket => 'اینکر ٹکٹ';

  @override
  String get planPlaybookPickTicket => 'ٹکٹ منتخب کریں…';

  @override
  String get planPlaybookProposeRun => 'پلان تجویز کریں';

  @override
  String get planPlaybookRepoHint => 'ریپوزٹری ID';

  @override
  String get planPlaybookAgentHint => 'ایجنٹ ID';

  @override
  String planPlaybookRunTitle(String name) {
    return '⁨$name⁩ چلائیں';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '$count پیرامز';
  }

  @override
  String get recentLabel => 'حالیہ';

  @override
  String get cheatSheetTitle => 'کی بورڈ شارٹ کٹس';

  @override
  String get cheatSheetGlobal => 'عالمی';

  @override
  String get cheatSheetThisScreen => 'یہ اسکرین';

  @override
  String get cheatSheetReservedInBrowser => 'براؤزر محفوظ';

  @override
  String get keybindingCheatSheet => 'کی بورڈ شارٹ کٹس';

  @override
  String get runPlaybookLabel => 'پلے بک چلائیں';

  @override
  String get playbooksLabel => 'پلے بکس';

  @override
  String get keybindingUndo => 'انڈو';

  @override
  String get keybindingRedo => 'ریڈو';

  @override
  String get undone => 'انڈو ہو گیا';

  @override
  String get redone => 'ریڈو ہو گیا';

  @override
  String get undoFailed => 'انڈو نہیں ہو سکا';

  @override
  String get undoLabelTicketEdit => 'ٹکٹ ترمیم';

  @override
  String get undoLabelMessageEdit => 'پیغام ترمیم';

  @override
  String get undoLabelTodoStatus => 'todo اسٹیٹس';

  @override
  String get inboxTitle => 'ان باکس';

  @override
  String get inboxReview => 'ریویو';

  @override
  String get inboxOpen => 'کھولیں';

  @override
  String get inboxAllCaughtUp => 'آپ سب دیکھ چکے ہیں';

  @override
  String get inboxGitHubDownTitle => 'GitHub بند ہو سکتا ہے';

  @override
  String inboxGitHubDownBody(String status) {
    return 'GitHub ⁨$status⁩ رپورٹ کر رہا ہے، اس لیے اس فہرست سے غائب pull requests ہو سکتا ہے مکمل نہ ہوں۔';
  }

  @override
  String get inboxGitHubIdentityTitle =>
      'آپ کا GitHub اکاؤنٹ تصدیق نہیں ہو سکا';

  @override
  String get inboxGitHubIdentityBody =>
      'ان باکس اس بنیاد پر ترتیب ہوتا ہے کہ GitHub پر آپ کون ہیں۔ لوڈ ہونے تک یہ خالی رہتا ہے، چاہے pull requests آپ کے انتظار میں ہوں۔';

  @override
  String get inboxSeverityBlocking => 'بلاک';

  @override
  String get inboxSeverityWaiting => 'انتظار';

  @override
  String get inboxSeverityInfo => 'معلومات';

  @override
  String get inboxSyncFailed => 'سنک ناکام';

  @override
  String get inboxNeedsYourAttention => 'آپ کی توجہ درکار';

  @override
  String get inboxSectionNeedsYourReview => 'آپ کے ریویو کی ضرورت';

  @override
  String get inboxSectionReturnedToYou => 'آپ کو واپس';

  @override
  String get inboxSectionApproved => 'منظور';

  @override
  String get inboxSectionDrafts => 'ڈرافٹس';

  @override
  String get inboxSectionWaitingForReviewers => 'ریویوورز کا انتظار';

  @override
  String get inboxSectionMergingAndMerged => 'مرج ہو رہا ہے اور حال ہی میں مرج';

  @override
  String get inboxSectionWaitingForAuthor => 'مصنف کا انتظار';

  @override
  String get inboxColumnTitle => 'عنوان';

  @override
  String get inboxColumnChanges => 'تبدیلیاں';

  @override
  String get inboxColumnUpdated => 'اپ ڈیٹ';

  @override
  String get inboxReviewApproved => 'منظور';

  @override
  String get inboxReviewChangesRequested => 'تبدیلیاں مانگی گئیں';

  @override
  String get inboxHeroSubtitle =>
      'ہر pull request جس میں آپ شامل ہیں، اگلے قدم کے حساب سے ترتیب۔';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requests آپ کے ریویو کی ضرورت ہیں',
      one: '1 pull request آپ کے ریویو کی ضرورت ہے',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count آپ کو واپس',
      one: '1 آپ کو واپس',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted =>
      'وہ تبدیلی محفوظ نہیں ہوئی اور واپس ہو گئی';

  @override
  String get offlinePendingLabel => 'زیرِ التوا';

  @override
  String get offlineSyncingLabel => 'سنک ہو رہا ہے';

  @override
  String get copyLinkLabel => 'اس صفحے کا لنک کاپی کریں';

  @override
  String get agentsSectionLabel => 'ایجنٹس';

  @override
  String get fleetWorkersTitle => 'ورکرز';

  @override
  String get fleetWorkersSubtitle => 'جابز چلانے کے لیے دستیاب مشینیں';

  @override
  String get fleetJobsTitle => 'جابز';

  @override
  String get fleetJobsSubtitle => 'فلیٹ پر تقسیم کام';

  @override
  String get fleetNoWorkers =>
      'ابھی کوئی ورکر نہیں — ⁨cc_worker --server <url>⁩ چلانے والی دوسری مشین فلیٹ میں شامل ہوتی ہے۔';

  @override
  String get fleetNoJobs => 'کوئی جاب نہیں۔';

  @override
  String get fleetError => 'فلیٹ لوڈ نہیں ہو سکا';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کورز',
      one: '1 کور',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return 'ہارٹ بیٹ $time';
  }

  @override
  String get fleetNoHeartbeat => 'ابھی کوئی ہارٹ بیٹ نہیں';

  @override
  String fleetLastErrorLabel(String error) {
    return 'آخری خرابی: ⁨$error⁩';
  }

  @override
  String get fleetDrain => 'ڈرین';

  @override
  String get fleetResume => 'جاری رکھیں';

  @override
  String get fleetRevoke => 'منسوخ کریں';

  @override
  String get fleetRemove => 'ہٹائیں';

  @override
  String get fleetRevokeTitle => 'ورکر منسوخ کریں؟';

  @override
  String fleetRevokeBody(String name) {
    return '⁨$name⁩ منسوخ کریں؟ اس کا سیشن ختم ہوتا ہے اور فعال جابز دوبارہ تفویض ہوتے ہیں۔';
  }

  @override
  String get fleetRemoveTitle => 'ورکر ہٹائیں؟';

  @override
  String fleetRemoveBody(String name) {
    return '⁨$name⁩ کو فلیٹ سے ہٹائیں؟ اس کا ریکارڈ حذف ہوتا ہے۔';
  }

  @override
  String get fleetActionFailed => 'ایکشن ناکام';

  @override
  String get fleetJobUnassigned => 'غیر تفویض';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '$attempts/$max کوششیں';
  }

  @override
  String get fleetPlacementReasons => 'پلیسمنٹ فیصلے';

  @override
  String get fleetNoPlacements => 'ابھی کوئی پلیسمنٹ فیصلہ نہیں۔';

  @override
  String get fleetStatusOnline => 'آن لائن';

  @override
  String get fleetStatusDraining => 'ڈرین ہو رہا ہے';

  @override
  String get fleetStatusOffline => 'آف لائن';

  @override
  String get fleetStatusIncompatible => 'غیر موافق';

  @override
  String get fleetStatusRevoked => 'منسوخ';

  @override
  String get fleetJobStatusQueued => 'قطار میں';

  @override
  String get fleetJobStatusRunning => 'چل رہا ہے';

  @override
  String get fleetJobStatusSucceeded => 'کامیاب';

  @override
  String get fleetJobStatusFailed => 'ناکام';

  @override
  String get fleetJobStatusCancelled => 'منسوخ';

  @override
  String get evalsNoSuites => 'ابھی کوئی ایول سوٹ نہیں۔';

  @override
  String get evalsError => 'ایولز لوڈ نہیں ہو سکے';

  @override
  String get evalsStarterBadge => 'اسٹارٹر';

  @override
  String evalsDefaultBatch(int count) {
    return 'ڈیفالٹ بیچ از $count';
  }

  @override
  String get evalsRecentRuns => 'حالیہ رنز';

  @override
  String get evalsNoRuns => 'ابھی کوئی رن نہیں۔';

  @override
  String get evalsPassRate => 'پاس ریٹ';

  @override
  String evalsBatchTimes(int count) {
    return '× $count';
  }

  @override
  String evalsTriggeredBy(String who) {
    return 'از ⁨$who⁩';
  }

  @override
  String evalsRunFinished(String rate) {
    return 'ایول ختم — $rate پاس';
  }

  @override
  String get evalsRunFailed => 'سوٹ نہیں چل سکا';

  @override
  String get evalsRun => 'چلائیں';

  @override
  String get evalsStatusQueued => 'قطار میں';

  @override
  String get evalsStatusRunning => 'چل رہا ہے';

  @override
  String get evalsStatusPassed => 'پاس';

  @override
  String get evalsStatusFailed => 'ناکام';

  @override
  String get bannerMeetingJoin => 'شامل ہوں';

  @override
  String get bannerMeetingRecordAndLink => 'ریکارڈ اور لنک';

  @override
  String get bannerCalendarReconnect => 'دوبارہ منسلک کریں';

  @override
  String get bannerView => 'دیکھیں';

  @override
  String get soundscapeTitle => 'ساؤنڈ اسکیپس';

  @override
  String get soundscapePlay => 'چلائیں';

  @override
  String get soundscapePause => 'توقف';

  @override
  String get soundscapeMoodLabel => 'موڈ';

  @override
  String get soundscapeMoodFocus => 'فوکس';

  @override
  String get soundscapeMoodRelax => 'آرام';

  @override
  String get soundscapeMoodSleep => 'نیند';

  @override
  String get soundscapeMoodRise => 'عروج';

  @override
  String get soundscapeVolumeLabel => 'والیوم';

  @override
  String get soundscapeTuneLabel => 'ٹون';

  @override
  String get soundscapeTuneMellow => 'نرم';

  @override
  String get soundscapeTuneBright => 'روشن';

  @override
  String get soundscapeTuneEnergetic => 'توانا';

  @override
  String get soundscapeTuneSpacy => 'وسیع';

  @override
  String get soundscapeTuneResetHint => 'ری سیٹ کے لیے ڈبل ٹیپ';

  @override
  String get soundscapeSceneLabel => 'اب چل رہا ہے';

  @override
  String get soundscapeSceneLoading => 'امبیئنس ٹون ہو رہا ہے…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees°C';
  }

  @override
  String get soundscapeLocationLabel => 'مقام';

  @override
  String get soundscapeLocationDetecting => 'مقام دریافت ہو رہا ہے…';

  @override
  String get soundscapeLocationAutoNote => 'مقام اس ڈیوائس سے آتا ہے۔';

  @override
  String get soundscapeRefreshWeather => 'موسم تازہ کریں';

  @override
  String get soundscapeAutoStartLabel => 'فوکس موڈ کے ساتھ شروع کریں';

  @override
  String get soundscapeAutoStartDescription =>
      'فوکس سیشن شروع ہونے پر ساؤنڈ اسکیپ خود چلائیں۔';

  @override
  String get soundscapeReturnToApp => 'ایپ پر واپس';

  @override
  String get soundscapePopOut => 'پلیئر الگ کھولیں';

  @override
  String get discussion => 'بحث';

  @override
  String get chat => 'چیٹ';

  @override
  String get saving => 'محفوظ ہو رہا ہے…';

  @override
  String get saved => 'محفوظ';

  @override
  String get saveFailed => 'محفوظ نہیں ہو سکا';

  @override
  String get commitAndPush => 'کمیٹ اور پش';

  @override
  String get commit => 'کمیٹ';

  @override
  String get commitAmend => 'کمیٹ (amend)';

  @override
  String get commitAndSync => 'کمیٹ اور سنک';

  @override
  String get scmSyncChanges => 'تبدیلیاں سنک کریں';

  @override
  String get scmPublishBranch => 'برانچ شائع کریں';

  @override
  String get scmSyncFailed => 'سنک ناکام رہا';

  @override
  String get scmSyncDirty => 'سنک سے پہلے تبدیلیاں کمیٹ کریں یا رد کریں';

  @override
  String get scmSynced => 'سنک ہو گیا';

  @override
  String get scmPushRefused => 'پش مسترد ہو گئی';

  @override
  String get scmPulledPushRefused => 'پل ہو گیا، مگر پش مسترد ہو گئی';

  @override
  String get scmPushRefusedHint => 'ریموٹ یا ہک نے اپ ڈیٹ مسترد کر دی';

  @override
  String get scmSelectBranch => 'چیک آؤٹ کے لیے شاخ منتخب کریں';

  @override
  String get scmCreateBranch => 'نئی شاخ بنائیں…';

  @override
  String get scmCreateBranchFrom => 'سے نئی شاخ بنائیں…';

  @override
  String get scmCheckoutDetached => 'علیحدہ چیک آؤٹ…';

  @override
  String get scmBranchName => 'شاخ کا نام';

  @override
  String get scmCreateBranchTitle => 'شاخ بنائیں';

  @override
  String scmFromRef(String ref) {
    return '⁨$ref⁩ سے';
  }

  @override
  String get scmCheckoutFailed => 'شاخ تبدیل نہیں ہو سکی';

  @override
  String get scmCheckoutDirty =>
      'شاخ بدلنے سے پہلے تبدیلیاں محفوظ کریں یا مسترد کریں';

  @override
  String scmSwitchedToBranch(String branch) {
    return '⁨$branch⁩ پر منتقل';
  }

  @override
  String scmDetachedAt(String ref) {
    return '⁨$ref⁩ پر علیحدہ';
  }

  @override
  String get scmDetachedHead => 'علیحدہ HEAD';

  @override
  String get scmNoBranches => 'کوئی مماثل شاخ نہیں';

  @override
  String get scmBranches => 'شاخیں';

  @override
  String get scmRemoteBranches => 'دور دراز شاخیں';

  @override
  String get scmTags => 'ٹیگز';

  @override
  String get scmPickStartPoint => 'آغاز کا نقطہ منتخب کریں';

  @override
  String get scmSwitchBranch => 'شاخ تبدیل کریں';

  @override
  String get scmPullConflictTitle => 'پل تنازع پیدا کرے گا';

  @override
  String scmPullConflictBody(int count, String branch) {
    return '⁨$branch⁩ پر $count کمٹ پل کرنا اس کاپی کے کام سے ٹکرا جائے گا۔';
  }

  @override
  String get scmAskAi => 'AI سے پوچھیں';

  @override
  String scmResolveConflictPrompt(String branch, String repo, int count) {
    return '⁨$repo⁩ میں ⁨$branch⁩ پل کریں۔ یہ اپ اسٹریم سے $count کمٹ پیچھے ہے اور پل مقامی کام سے ٹکراتا ہے۔ تنازعات حل کریں اور پل مکمل کریں۔';
  }

  @override
  String commitMessageOnBranch(String shortcut, String branch) {
    return 'پیغام ($shortcut سے “$branch” پر کمیٹ)';
  }

  @override
  String get committed => 'کمیٹ ہو گیا';

  @override
  String get commitAmended => 'کمیٹ ترمیم ہوا';

  @override
  String get commitFailed => 'کمیٹ ناکام';

  @override
  String get moreCommitActions => 'مزید کمیٹ ایکشنز';

  @override
  String get sourceControl => 'سورس کنٹرول';

  @override
  String fixFindingTitle(String location) {
    return 'درست کریں: ⁨$location⁩';
  }

  @override
  String get openInEditor => 'ایڈیٹر میں کھولیں';

  @override
  String get regexTesterTitle => 'ریگولر ایکسپریشن آزمائیں';

  @override
  String get regexTesterHint => 'ایک نمونہ لکھیں';

  @override
  String get regexMatch => 'مطابقت';

  @override
  String get regexNoMatch => 'کوئی مطابقت نہیں';

  @override
  String get regexInvalidPattern => 'غلط پیٹرن';

  @override
  String get symbolLookupNone => 'اشاریہ یا اس پل درخواست میں کوئی تعریف نہیں';

  @override
  String get symbolLookupInDiff => 'اس پل درخواست میں ملا';

  @override
  String get symbolLookupFromBase =>
      'بنیادی چیک آؤٹ سے — اس PR کا ورک ٹری ابھی اشاریہ نہیں ہوا';

  @override
  String get symbolImplementations => 'نفاذ';

  @override
  String symbolCallersCount(int count) {
    return '$count کالرز';
  }

  @override
  String get commitMessageHint => 'کمیٹ پیغام';

  @override
  String get pushedToPr => 'PR پر پش ہوا';

  @override
  String get pushFailed => 'پش ناکام';

  @override
  String get reviewFindings => 'نتائج';

  @override
  String get treeLabel => 'ٹری';

  @override
  String get toggleFileTree => 'فائل ٹری دکھائیں یا چھپائیں';

  @override
  String get diffViewSettings => 'Diff منظر ترتیبات';

  @override
  String get splitViewLabel => 'تقسیم';

  @override
  String get unifiedViewLabel => 'یکجا';

  @override
  String get wrapLines => 'لائنیں لپیٹیں';

  @override
  String get shiftClickSelectRange => 'رینج منتخب کرنے کے لیے Shift-کلک';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فائلیں',
      one: '1 فائل',
    );
    return '$_temp0';
  }

  @override
  String prComplexityLoc(String loc) {
    return '⁨$loc⁩ LOC';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return 'چھوٹا PR — $files، ریویو ~$minutes منٹ';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return 'درمیانہ PR — $files، ریویو ~$minutes منٹ بلاک کریں';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return 'بڑا PR — $files، ریویو سے پہلے تقسیم پر غور کریں';
  }

  @override
  String get searchInFiles => 'فائلوں میں تلاش';

  @override
  String get showFileList => 'فائل فہرست دکھائیں';

  @override
  String get searchInFilesHintField => 'فائلوں میں تلاش…';

  @override
  String get searchInFilesHint => 'pull request کی فائلوں میں تلاش';

  @override
  String get searchInWholeRepo => 'پورے ریپوزٹری میں تلاش';

  @override
  String get searchInThisPullRequest => 'اس pull request میں تلاش';

  @override
  String get searchNoResults => 'کوئی نتیجہ نہیں ملا';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نتائج',
      one: '1 نتیجہ',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files فائلوں',
      one: '1 فائل',
    );
    return '$_temp0 $_temp1 میں';
  }

  @override
  String get discardChangesTitle => 'تبدیلیاں مسترد کریں؟';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فائلیں',
      one: '1 فائل',
    );
    return '$_temp0 HEAD پر مسترد کریں؟ یہ واپس نہیں ہو سکتا۔';
  }

  @override
  String get discardAll => 'سب مسترد کریں';

  @override
  String get discardFailed => 'تبدیلیاں مسترد نہیں ہو سکیں';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فائلیں',
      one: '1 فائل',
    );
    return '$_temp0 مسترد ہو گئیں';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '$reverted فائلیں',
      one: '1 فائل',
    );
    return '$_temp0 مسترد؛ $skipped چھوڑی گئیں (ان ٹریکڈ)';
  }

  @override
  String get prWorktreeUnavailable => 'ورک اسپیس تیار نہیں';

  @override
  String get prWorktreeUnavailableHint =>
      'pull request کی فائلیں تیار نہیں ہو سکیں۔ دوبارہ کوشش کے لیے pull request دوبارہ کھولیں۔';

  @override
  String get timestampRelativeLabel => 'نسبتی';

  @override
  String get timestampRawLabel => 'ٹائم سٹیمپ';

  @override
  String get copyTimestamp => 'ٹائم سٹیمپ کاپی کریں';

  @override
  String get copiedTimestamp => 'ٹائم سٹیمپ کاپی ہو گیا';

  @override
  String get previewDeployment => 'پریویو ڈیپلائمنٹ';

  @override
  String previewDeploymentTab(String site) {
    return 'پریویو: ⁨$site⁩';
  }

  @override
  String get askForReview => 'ریویو مانگیں…';

  @override
  String get closePrsConfirmTitle => 'pull requests بند کریں؟';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requests بند کریں؟',
      one: '1 pull request بند کریں؟',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requests بند ہوئے',
      one: '1 pull request بند ہوا',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requests تفویض ہوئے',
      one: '1 pull request تفویض ہوا',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requests پر ریویو مانگا',
      one: '1 pull request پر ریویو مانگا',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ایکشنز ناکام',
      one: '1 ایکشن ناکام',
    );
    return '$_temp0';
  }

  @override
  String get diagram => 'ڈایاگرام';

  @override
  String get diagramViewSource => 'سورس دیکھیں';

  @override
  String get diagramHideSource => 'سورس چھپائیں';

  @override
  String diagramPreviewUnavailable(String reason) {
    return 'ڈایاگرام پیش منظر دستیاب نہیں (⁨$reason⁩)';
  }

  @override
  String get planUnavailable => 'پلان دستیاب نہیں';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مراحل',
      one: '1 مرحلہ',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => 'منظور کریں اور چلائیں';

  @override
  String get planStatusDraft => 'ڈرافٹ';

  @override
  String get planStatusProposed => 'پلان';

  @override
  String get planStatusApproved => 'پلان منظور';

  @override
  String get planStatusRejected => 'پلان مسترد';

  @override
  String get planStatusSuperseded => 'پلان منسوخ';

  @override
  String planRevisionLabel(int revision) {
    return 'ریویژن $revision';
  }

  @override
  String get adapterEnforcementTitle => 'یہ اڈاپٹر کیا نافذ کرتا ہے';

  @override
  String get enforcementFiltersToolSurface =>
      'Control Center ٹولز منتخب کرتا ہے';

  @override
  String get enforcementInterceptsToolCalls =>
      'ہر کال چلنے سے پہلے گیٹ ہوتی ہے';

  @override
  String get enforcementObservesCompletionContract =>
      'رن اپنے ڈیلیوریبل پر رکھا جاتا ہے';

  @override
  String get enforcementNativeToolsInterceptable =>
      'رنر کے اپنے ٹولز نظر آتے ہیں';

  @override
  String get enforcementInProcessToolsSandboxed =>
      'ان پروسیس ٹولز سینڈ باکس میں ہیں';

  @override
  String get enforcementYes => 'ہاں';

  @override
  String get enforcementNo => 'نہیں';

  @override
  String get adapterEnforcementCaveats => 'تحفظات';

  @override
  String get enforcementSummaryModesEnforced => 'موڈز نافذ';

  @override
  String get enforcementSummaryModesNotEnforced => 'موڈز نافذ نہیں';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تحفظات',
      one: '1 تحفظ',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      'ریڈ اونلی موڈز ساختی نہیں: Control Center اس رنر کے اپنے ٹولز ہٹا نہیں سکتا۔';

  @override
  String get caveatToolCallsNotIntercepted =>
      'کوئی پہلے گیٹ نہیں: صرف MCP ٹول کالز Control Center سے گزرتی ہیں۔';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      'رنر کے اپنے فائل اور شیل ٹولز Control Center تک نہیں پہنچتے؛ OS سینڈ باکس ان کے نیچے واحد فلور ہے۔';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      'ان پروسیس فائل ٹولز سینڈ باکس سے باہر چلتے ہیں، اس لیے ٹول سطح واحد فائل سسٹم حد ہے۔';

  @override
  String get caveatCompletionContractUnobservable =>
      'Control Center اس رن کو دھکا یا ناکام نہیں کر سکتا جو ڈیلیوریبل کے بغیر ختم ہو۔';

  @override
  String get modeDegraded => 'کمزور';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return '⁨$adapter⁩ پر ⁨$mode⁩ موڈ صرف سینڈ باکس پر انحصار کرتا ہے؛ ایجنٹ کے اپنے فائل ٹولز نہیں روکے جاتے۔';
  }

  @override
  String get artifactUnavailable => 'آرٹیفیکٹ دستیاب نہیں';

  @override
  String artifactRevisionLabel(int count) {
    return '$count ریویژنز';
  }

  @override
  String get artifactShowMore => 'مزید دکھائیں';

  @override
  String get artifactShowLess => 'کم دکھائیں';

  @override
  String get artifactCopy => 'کاپی';

  @override
  String get artifactCopied => 'آرٹیفیکٹ کاپی ہو گیا';

  @override
  String get artifactsTabLabel => 'آرٹیفیکٹس';

  @override
  String get artifactsEmptyTitle => 'ابھی کوئی آرٹیفیکٹ نہیں';

  @override
  String get artifactsEmptyBody =>
      'جب ایجنٹ یہاں ٹیبل، چارٹ یا ڈایاگرام شائع کرے، وہ اس فہرست میں آتا ہے۔';

  @override
  String get artifactRevisionPickerLabel => 'ریویژن';

  @override
  String get artifactRestoreRevision => 'یہ ریویژن بحال کریں';

  @override
  String get artifactOpenInTab => 'ٹیب میں کھولیں';

  @override
  String get artifactTitleFallback => 'آرٹیفیکٹ';

  @override
  String get providerGenerationLabel => 'جنریشن ڈیفالٹس';

  @override
  String get providerGenerationHint =>
      'اینڈ پوائنٹ کے اپنے ڈیفالٹ کے لیے فیلڈ خالی چھوڑیں۔ ماڈلز اپنی آؤٹ پٹ حدیں اور سیمپلنگ ترکیبیں شائع کرتے ہیں؛ دوسری ویلیوز پر پیش کرنا انہیں کمزور کر سکتا ہے۔';

  @override
  String get providerMaxTokensLabel => 'زیادہ سے زیادہ آؤٹ پٹ ٹوکنز';

  @override
  String get addModel => 'ماڈل شامل کریں';

  @override
  String get modelListTitle => 'ماڈل فہرست';

  @override
  String get railProvidersGroup => 'فراہم کنندگان';

  @override
  String get railCustomProvidersGroup => 'حسبِ ضرورت فراہم کنندگان';

  @override
  String get editModelSettings => 'ماڈل ترتیبات میں ترمیم';

  @override
  String get modelIdLabel => 'Model ID';

  @override
  String get modelIdImmutableHint =>
      'اینڈ پوائنٹ جو ID پیش کرتا ہے؛ فہرست میں آنے کے بعد مقرر۔';

  @override
  String get contextWindowLabel => 'سیاق ونڈو';

  @override
  String get inputTypesLabel => 'ان پٹ اقسام';

  @override
  String get outputTypesLabel => 'آؤٹ پٹ اقسام';

  @override
  String get modalityText => 'متن';

  @override
  String get modalityImage => 'تصویر';

  @override
  String get modalityAudio => 'آڈیو';

  @override
  String get modalityVideo => 'ویڈیو';

  @override
  String get modalityPdf => 'PDF';

  @override
  String get modelOverrideReset => 'خودکار پر ری سیٹ';

  @override
  String get modelOverrideEdited => 'ترمیم شدہ';

  @override
  String get manualModelBadge => 'ہاتھ سے شامل';

  @override
  String get modelIdRequired => 'ماڈل ID درج کریں۔';

  @override
  String get modelTokensInvalid => 'ٹوکنز کا مثبت پورا عدد درج کریں۔';

  @override
  String get removeModelAction => 'ماڈل ہٹائیں';

  @override
  String removeModelConfirmTitle(String model) {
    return '⁨$model⁩ ہٹائیں؟';
  }

  @override
  String get removeModelConfirmBody =>
      'ماڈل فہرست سے نکل جاتا ہے اور اس پر پن ایجنٹس رک جاتے ہیں۔ فراہم کنندہ متاثر نہیں۔';

  @override
  String get addModelProviderTitle => 'ماڈل فراہم کنندہ شامل کریں';

  @override
  String get addModelProviderDescription =>
      'حسبِ ضرورت API اینڈ پوائنٹ اور اس کے ماڈلز کنفیگر کریں۔';

  @override
  String get modelListEmptyHint =>
      'کوئی ماڈل کنفیگر نہیں۔ چیٹ میں استعمال کے لیے ماڈل شامل کریں۔';

  @override
  String get addProviderModelsHint =>
      'اینڈ پوائنٹ جواب دینے پر ماڈلز لائیو حاصل ہوتے ہیں۔ ہاتھ سے صرف تب شامل کریں جب وہ اپنی فہرست نہ دے سکے۔';

  @override
  String get providerTemperatureLabel => 'ٹمپریچر';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved => 'جنریشن ڈیفالٹس محفوظ ہو گئے';

  @override
  String get providerGenerationInvalid =>
      'ویلیوز چیک کریں: زیادہ سے زیادہ آؤٹ پٹ ٹوکنز اور top-k مثبت ہوں، ٹمپریچر 0–2، top-p 0–1۔';

  @override
  String get providerGenerationOverridden => 'اوور رائڈ';

  @override
  String get branchNotPushed => 'پش نہیں ہوا';

  @override
  String branchNotOnRemote(String branch) {
    return '\"⁨$branch⁩\" صرف اس گفتگو میں موجود ہے';
  }

  @override
  String get branchNotOnRemoteHint =>
      'GitHub نے یہ برانچ کبھی نہیں دیکھی، اس لیے pull request ابھی اسے استعمال نہیں کر سکتا۔ شائع کرنے سے worktree کے کمیٹس پش ہوتے ہیں — غیر کمیٹ تبدیلیاں رہتی ہیں۔';

  @override
  String get publishBranch => 'برانچ شائع کریں';

  @override
  String branchPublished(String branch) {
    return '\"⁨$branch⁩\" origin پر شائع ہو گئی';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return 'برانچ شائع ہو گئی۔ $count غیر کمیٹ تبدیلی(یاں) شامل نہیں ہوئیں۔';
  }

  @override
  String get composePrLoadingBranches => 'GitHub سے برانچز لوڈ ہو رہی ہیں…';

  @override
  String get composePrBranchesFailed =>
      'GitHub سے برانچز لوڈ نہیں ہو سکیں۔ برانچ نام ٹائپ کریں، یا GitHub کنکشن چیک کریں۔';

  @override
  String get composePrSubtitleFromSpace =>
      'اس گفتگو کی برانچ سے — اگر GitHub نے نہیں دیکھی تو پہلے شائع کریں';

  @override
  String get obsTabInsights => 'بصیرتیں';

  @override
  String get obsTabLive => 'لائیو';

  @override
  String get obsTabQuality => 'معیار';

  @override
  String get obsTabUsage => 'استعمال';

  @override
  String get obsUsageTotalTokens => 'کل ٹوکنز';

  @override
  String get obsUsagePeakTokens => 'پیک ٹوکنز';

  @override
  String get obsUsageLongestSession => 'طویل ترین سیشن';

  @override
  String get obsUsageCurrentStreak => 'موجودہ سلسلہ';

  @override
  String get obsUsageLongestStreak => 'طویل ترین سلسلہ';

  @override
  String obsUsageDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دن',
      one: '1 دن',
      zero: '0 دن',
    );
    return '$_temp0';
  }

  @override
  String get obsUsageTokenActivity => 'ٹوکن سرگرمی';

  @override
  String get obsUsageActivityModeLabel => 'ٹوکن سرگرمی موڈ';

  @override
  String get obsUsageModeDaily => 'روزانہ';

  @override
  String get obsUsageModeWeekly => 'ہفتہ وار';

  @override
  String get obsUsageModeCumulative => 'مجموعی';

  @override
  String get obsUsageTimeRange => 'وقت کی حد';

  @override
  String get obsUsageTrendTitle => 'روزانہ ٹوکن رجحان';

  @override
  String get obsUsageModelUsage => 'ماڈل استعمال';

  @override
  String get obsUsageTokensLabel => 'ٹوکنز';

  @override
  String get obsUsageNoActivity => 'ابھی کوئی ٹوکن استعمال ریکارڈ نہیں';

  @override
  String get obsUsageOtherModels => 'دیگر';

  @override
  String obsUsageCellReadout(String date, String tokens) {
    return '$date · $tokens ٹوکنز';
  }

  @override
  String obsUsageActivitySummary(
    String start,
    String end,
    int activeDays,
    String peak,
  ) {
    return '$start سے $end تک ٹوکن سرگرمی۔ $activeDays فعال دن۔ مصروف ترین دن $peak ٹوکنز۔';
  }

  @override
  String get obsScreenSubtitle =>
      'لائیو ایجنٹ کنٹرول، لاگت انتساب، کوٹے اور معیار کے اشارے';

  @override
  String get obsRangeLast24h => 'گزشتہ 24 گھنٹے';

  @override
  String get obsRangeLast7d => 'گزشتہ 7 دن';

  @override
  String get obsRangeLast30d => 'گزشتہ 30 دن';

  @override
  String get obsRangeAll => 'تمام وقت';

  @override
  String get obsAddFilter => 'فلٹر شامل کریں';

  @override
  String get obsFilterAgent => 'ایجنٹ';

  @override
  String get obsFilterModel => 'ماڈل';

  @override
  String get obsFilterStatus => 'اسٹیٹس';

  @override
  String get obsFilterRole => 'کردار';

  @override
  String get obsKpiTotalRuns => 'کل رنز';

  @override
  String get obsKpiTotalCost => 'کل لاگت';

  @override
  String get obsKpiErrorRate => 'خرابی کی شرح';

  @override
  String get obsKpiCacheRate => 'کیش ریٹ';

  @override
  String get obsKpiTokensPerSec => 'ٹوکنز / سیکنڈ';

  @override
  String get obsKpiAvgLatency => 'اوسط لیٹنسی';

  @override
  String get obsKpiTtft => 'پہلے ٹوکن تک وقت';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '$delta بمقابلہ پچھلی مدت';
  }

  @override
  String get obsChartActivity => 'سرگرمی';

  @override
  String get obsChartCost => 'وقت کے ساتھ لاگت';

  @override
  String get obsLegendRuns => 'رنز';

  @override
  String get obsLegendErrors => 'خرابیاں';

  @override
  String get obsAgentsTitle => 'ایجنٹس';

  @override
  String obsShowAllAgents(int count) {
    return 'تمام $count ایجنٹس دکھائیں';
  }

  @override
  String get obsShowFewerAgents => 'کم دکھائیں';

  @override
  String get obsRunsTitle => 'رنز';

  @override
  String get obsNoRunsInRange => 'اس حد میں کوئی رن نہیں';

  @override
  String get obsColTime => 'وقت';

  @override
  String get obsColAgent => 'ایجنٹ';

  @override
  String get obsColStatus => 'اسٹیٹس';

  @override
  String get obsColModel => 'ماڈل';

  @override
  String get obsColDuration => 'مدت';

  @override
  String get obsColTokens => 'ٹوکنز';

  @override
  String get obsColCost => 'لاگت';

  @override
  String get obsColErrors => 'خرابیاں';

  @override
  String get obsColRuns => 'رنز';

  @override
  String get obsColAvgLatency => 'اوسط لیٹنسی';

  @override
  String get obsColLastActive => 'آخری فعال';

  @override
  String get obsStatusPending => 'زیرِ التوا';

  @override
  String get obsStatusRunning => 'چل رہا ہے';

  @override
  String get obsStatusCompleted => 'مکمل';

  @override
  String get obsStatusError => 'خرابی';

  @override
  String get obsRosterLoadError => 'ایجنٹ روسٹر لوڈ نہیں ہو سکا۔';

  @override
  String get obsRosterEmpty => 'ابھی کوئی ایجنٹ نہیں';

  @override
  String get obsRosterEmptyDescription =>
      'ایجنٹ ڈسپیچ کریں اور وہ یہاں لائیو نظر آئے گا — اسٹیٹس، موجودہ ٹول، ٹوکنز، لاگت۔';

  @override
  String get obsKillAgent => 'ایجنٹ ختم کریں';

  @override
  String get obsRosterTokensLabel => 'ٹوک';

  @override
  String get obsCostByRoleTitle => 'کردار کے لحاظ سے لاگت';

  @override
  String get obsCostByRoleSubtitle =>
      'اس ورک اسپیس کا خرچ، ایجنٹ کردار کے حساب سے';

  @override
  String get obsRoleMain => 'مین';

  @override
  String get obsRoleSubagents => 'ذیلی ایجنٹس';

  @override
  String get obsRoleAdvisor => 'مشیر';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return 'مین: $main · ذیلی ایجنٹس: $sub · مشیر: $advisor';
  }

  @override
  String get obsTotal => 'کل';

  @override
  String get obsTokenModelTitle => 'ٹوکن ماڈل (5 محور)';

  @override
  String get obsTokenModelSubtitle =>
      'اس ورک اسپیس کے ہر خرچ شدہ ٹوکن، محور کے حساب سے';

  @override
  String get obsAxisInput => 'ان پٹ';

  @override
  String get obsAxisOutput => 'آؤٹ پٹ';

  @override
  String get obsAxisReasoning => 'ریزننگ';

  @override
  String get obsAxisCacheRead => 'کیش ریڈ';

  @override
  String get obsAxisCacheWrite => 'کیش رائٹ';

  @override
  String get obsTotalTokens => 'کل ٹوکنز';

  @override
  String get obsCacheDiscountNote =>
      'کیش ریڈ ٹوکنز رعایتی بل ہوتے ہیں، اس لیے تازہ ان پٹ کے اسی حجم سے بہت سستے پڑتے ہیں۔';

  @override
  String get obsByModelTitle => 'ماڈل کے حساب سے';

  @override
  String get obsByModelSubtitle => 'فی ماڈل ٹوکن اور لاگت استعمال';

  @override
  String get obsNoModelUsage => 'ابھی کوئی ماڈل استعمال ریکارڈ نہیں۔';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رنز',
      one: '1 رن',
    );
    return '$_temp0';
  }

  @override
  String get obsPerRunTitle => 'فی رن';

  @override
  String get obsPerRunSubtitle => 'ایک رن کی عام ٹوکن لاگت';

  @override
  String get obsMedianRunTokens => 'میڈین رن ٹوکنز';

  @override
  String get obsMedianRunTokensSub => 'تمام رنز کا وسط نقطہ';

  @override
  String get obsRunsInWorkspace => 'اس ورک اسپیس میں';

  @override
  String get obsCostShare => 'لاگت کا حصہ';

  @override
  String get obsQuotaConfiguredLimits => 'کنفیگر شدہ حدیں';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      'آپ کی سیٹ کردہ حدوں کے مقابل استعمال، بدترین اسٹیٹس پہلے۔';

  @override
  String get obsQuotaAddLimit => 'حد شامل کریں';

  @override
  String get obsQuotaNoLimits =>
      'ابھی کوئی کوٹا حد کنفیگر نہیں — حد کے مقابل استعمال ٹریک کرنے کے لیے ایک شامل کریں۔';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return '⁨$title⁩ حد ہٹائیں';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return '$duration میں ری سیٹ · $status';
  }

  @override
  String get obsQuotaUsageWindows => 'استعمال کی ونڈوز';

  @override
  String get obsQuotaUsageWindowsSubtitle =>
      'تمام فراہم کنندگان کا مشاہدہ شدہ استعمال، کوئی حد نہیں۔';

  @override
  String get obsQuotaNoUsage => 'ابھی کوئی استعمال ریکارڈ نہیں۔';

  @override
  String get obsQuotaTokensUsed => 'استعمال شدہ ٹوکنز';

  @override
  String get obsQuotaRequests => 'درخواستیں';

  @override
  String get obsQuotaUnitTokens => 'ٹوکنز';

  @override
  String get obsQuotaUnitRequests => 'درخواستیں';

  @override
  String get obsQuotaUnitCost => 'لاگت';

  @override
  String get obsQuotaAddLimitTitle => 'کوٹا حد شامل کریں';

  @override
  String get obsQuotaProviderLabel => 'فراہم کنندہ';

  @override
  String get obsQuotaWindowLabel => 'ونڈو';

  @override
  String get obsQuotaUnitLabel => 'یونٹ';

  @override
  String obsQuotaLimitLabel(String unit) {
    return 'حد ($unit)';
  }

  @override
  String get obsQuotaCentsHint => 'امریکی سینٹس میں (500 = \$5.00)۔';

  @override
  String get obsQuotaStatusOk => 'ٹھیک';

  @override
  String get obsQuotaStatusWarning => 'تنبیہ';

  @override
  String get obsQuotaStatusExhausted => 'ختم';

  @override
  String get obsQuotaStatusUnknown => 'نامعلوم';

  @override
  String get obsGoalNoActiveTitle => 'کوئی فعال ہدف نہیں';

  @override
  String get obsGoalNoActiveBody =>
      'ایجنٹس کو مقصد اور اختیاری ٹوکن بجٹ دینے کے لیے ہدف سیٹ کریں۔ رنز مکمل ہونے پر بجٹ بھرتا ہے اور تقریباً ختم ہونے پر ایجنٹس کو سمیٹنے کا اشارہ ملتا ہے۔';

  @override
  String get obsGoalSetGoal => 'ہدف سیٹ کریں';

  @override
  String get obsGoalTokenBudget => 'ٹوکن بجٹ';

  @override
  String obsGoalTokensLeft(String tokens) {
    return '$tokens باقی';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens (کوئی بجٹ نہیں)';
  }

  @override
  String get obsGoalTokensUsed => 'استعمال شدہ ٹوکنز';

  @override
  String get obsGoalElapsed => 'گزرے';

  @override
  String get obsGoalWrapUp => 'سمیٹیں';

  @override
  String get obsGoalClear => 'ہدف صاف کریں';

  @override
  String get obsGoalFallbackTitle => 'ہدف';

  @override
  String get obsGoalSubtitle => 'گول موڈ بجٹ';

  @override
  String get obsGoalStatusActive => 'فعال';

  @override
  String get obsGoalStatusPaused => 'توقف';

  @override
  String get obsGoalStatusBudgetLimited => 'بجٹ محدود';

  @override
  String get obsGoalStatusComplete => 'مکمل';

  @override
  String get obsGoalStatusDropped => 'چھوڑا گیا';

  @override
  String get obsGoalObjectiveLabel => 'مقصد';

  @override
  String get obsGoalBudgetLabel => 'ٹوکن بجٹ (اختیاری)';

  @override
  String get obsGoalSetAction => 'ہدف سیٹ کریں';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => 'کامیابی %';

  @override
  String get obsBenchmarkPassed => 'پاس';

  @override
  String get obsBenchmarkFailed => 'ناکام';

  @override
  String get obsBenchmarkErrors => 'خرابیاں';

  @override
  String get obsBenchmarkSpend => 'خرچ';

  @override
  String get obsBenchmarkCostPerTask => 'لاگت / کام';

  @override
  String get obsBenchmarkTrials => 'ٹرائلز';

  @override
  String get obsBenchmarkNoTrials => 'اسکور کرنے کے لیے ابھی کوئی رن نہیں۔';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اور $count مزید',
      one: 'اور 1 مزید',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => 'پاس';

  @override
  String get obsBenchmarkTrialFail => 'فیل';

  @override
  String get obsBenchmarkTrialError => 'خرابی';

  @override
  String get obsBenchmarkTrialRunning => 'چل رہا ہے';

  @override
  String get obsBenchmarkReward => 'انعام';

  @override
  String get obsBenchmarkReport => 'رپورٹ';

  @override
  String get obsBenchmarkCopyMarkdown => 'Markdown کاپی کریں';

  @override
  String get obsBenchmarkCopied => 'رپورٹ کلپ بورڈ پر کاپی ہو گئی';

  @override
  String get obsBehaviorCaption =>
      'یہ آپ کے اپنے پیغامات سے پارس فرسٹریشن اشارے ہیں — گفتگو کی صحت کی پڑھت، ایجنٹس کا اسکور نہیں۔ مقامی حساب؛ اس ڈیوائس سے کچھ نہیں جاتا۔';

  @override
  String get obsBehaviorMessagesAnalyzed => 'تجزیہ شدہ پیغامات';

  @override
  String get obsBehaviorTotalSignals => 'کل اشارے';

  @override
  String get obsBehaviorYelling => 'چیخ';

  @override
  String get obsBehaviorProfanity => 'گالی';

  @override
  String get obsBehaviorAnguish => 'اضطراب';

  @override
  String get obsBehaviorNegation => 'نفی';

  @override
  String get obsBehaviorRepetition => 'تکرار';

  @override
  String get obsBehaviorBlame => 'الزام';

  @override
  String get obsBehaviorConversationsTitle => 'سب سے زیادہ مایوس گفتگوئیں';

  @override
  String get obsBehaviorConversationsSubtitle =>
      'آپ کے پیغامات میں اشارے کی کثافت کے حساب سے۔';

  @override
  String get obsBehaviorNoSignals => 'کوئی فرسٹریشن اشارہ نہیں — سب ٹھیک۔';

  @override
  String obsBehaviorMessagesCount(String count) {
    return '$count پیغامات کا تجزیہ';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '$count اشارے';
  }

  @override
  String get obsAgentStatusIdle => 'بیکار';

  @override
  String get obsAgentStatusParked => 'پارک شدہ';

  @override
  String get obsAgentStatusAborted => 'منسوخ';

  @override
  String get obsAgentKindSub => 'ذیلی';

  @override
  String get noChecksOnCommit => 'اس کمیٹ پر کوئی چیک نہیں چلا۔';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'چل رہا ہے — $count جابز',
      one: 'چل رہا ہے — 1 جاب',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تمام چیکس پاس — $count جابز',
      one: 'تمام چیکس پاس — 1 جاب',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'مکمل — $count جابز',
      one: 'مکمل — 1 جاب',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total جابز',
      one: '1 جاب',
    );
    return '$failed از $_temp0 ناکام';
  }

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count جابز',
      one: '1 جاب',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return 'میٹرکس: ⁨$jobId⁩';
  }

  @override
  String get jobLogsPending => 'جاب ختم ہونے پر لاگز یہاں نظر آئیں گے۔';

  @override
  String get jobLogsUnavailable => 'اس جاب کے لاگز دستیاب نہیں۔';

  @override
  String get noLogsForStep => 'اس مرحلے کے لیے کوئی لاگ نہیں۔';

  @override
  String get jobLogsTruncated => 'لاگ کٹا ہوا — تازہ ترین آؤٹ پٹ دکھا رہے ہیں۔';

  @override
  String get fullLog => 'پورا لاگ';

  @override
  String get copyLogs => 'لاگز کاپی کریں';

  @override
  String get resizeGraph => 'گراف کا سائز بدلنے کے لیے گھسیٹیں';

  @override
  String workflowRunStartedAgo(String time) {
    return '$time شروع ہوا';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return '$time مکمل ہوا';
  }

  @override
  String get chatBridgesTitle => 'چیٹ برجز';

  @override
  String chatProviderDescription(String provider, String command) {
    return '⁨$provider⁩ میں بوٹ کا ذکر کریں تاکہ ایجنٹ کو کام دیں، یا ⁨$command⁩ سے ٹکٹ کے مسودے بنائیں۔';
  }

  @override
  String chatConnectProvider(String provider) {
    return '⁨$provider⁩ منسلک کریں';
  }

  @override
  String get chatDisconnectProvider => 'منقطع کریں';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '⁨$teamName⁩ میں ⁨$botName⁩';
  }

  @override
  String get chatStateLive => 'لائیو';

  @override
  String get chatStateConnecting => 'منسلک ہو رہا ہے…';

  @override
  String get chatStateError => 'کنکشن خرابی';

  @override
  String get chatNotConnected => 'منسلک نہیں';

  @override
  String chatStreamingUnavailable(String provider) {
    return 'اس ⁨$provider⁩ ایپ کے لیے لائیو اسٹریمنگ آف ہے — جوابات ایک پیغام میں آتے ہیں۔';
  }

  @override
  String chatAdminOnly(String provider) {
    return 'صرف ایڈمن اس ورک اسپیس کے لیے ⁨$provider⁩ منسلک کر سکتا ہے۔';
  }

  @override
  String chatConnectHint(String provider) {
    return '⁨$provider⁩ ایپ بنائیں، پھر اس کے کریڈینشلز یہاں پیسٹ کریں۔ Control Center ⁨$provider⁩ سے باہر منسلک ہوتا ہے، اس لیے اس سرور کو پبلک ایڈریس نہیں چاہیے۔';
  }

  @override
  String chatOpenConsole(String provider) {
    return '⁨$provider⁩ کنسول کھولیں';
  }

  @override
  String get chatOpenSetupGuide => 'سیٹ اپ گائیڈ';

  @override
  String get chatFieldBotToken => 'بوٹ ٹوکن';

  @override
  String get chatFieldAppToken => 'ایپ لیول ٹوکن';

  @override
  String get chatFieldConfigRefreshToken => 'ایپ کنفیگریشن ٹوکن';

  @override
  String chatFieldOptional(String label) {
    return '$label (اختیاری)';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return 'میرا ⁨$provider⁩ اکاؤنٹ لنک کریں';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return 'اپنا ⁨$provider⁩ اکاؤنٹ لنک کریں تاکہ وہاں بھیجے پیغامات آپ سے منسوب ہوں۔';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return '⁨$externalUserId⁩ سے لنک';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return 'اپنا ⁨$provider⁩ اکاؤنٹ لنک کریں';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return 'یہ کوڈ براہِ راست پیغام میں ⁨$provider⁩ بوٹ کو بھیجیں۔ ایک بار چلتا ہے اور 15 منٹ میں ختم ہو جاتا ہے۔';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return 'آپ کا ⁨$provider⁩ اکاؤنٹ اب لنک ہے — وہاں بھیجے پیغامات آپ سے منسوب ہیں۔';
  }

  @override
  String get chatLinkedAccounts => 'لنک شدہ اکاؤنٹس';

  @override
  String chatNoLinkedAccounts(String provider) {
    return 'ابھی کسی نے اپنا ⁨$provider⁩ اکاؤنٹ لنک نہیں کیا۔';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count لنک شدہ اکاؤنٹس',
      one: '1 لنک شدہ اکاؤنٹ',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '⁨$externalUserId⁩ · ای میل سے میل';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '⁨$externalUserId⁩ · کوڈ سے لنک';
  }

  @override
  String get chatUnlink => 'ان لنک';

  @override
  String get chatCustomizeBot => 'بوٹ حسبِ ضرورت';

  @override
  String get chatCustomizeBotDescription =>
      'بوٹ کا نام بدلیں، وہ اپنے بارے میں کیا کہتا ہے، یا سلیش کمانڈ کا نام بدلیں۔';

  @override
  String get chatCustomizeBotUnavailable =>
      'بوٹ ترمیم کے لیے Control Center کو ایپ کنفیگریشن ٹوکن چاہیے۔ دوبارہ منسلک ہوں اور ایک شامل کریں۔';

  @override
  String chatCreateAppTitle(String provider) {
    return '⁨$provider⁩ ایپ بنائیں';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'Control Center آپ کے لیے ⁨$provider⁩ ایپ بنا سکتا ہے، درست اجازتوں اور ایونٹس کے ساتھ۔ آپ ⁨$provider⁩ میں مکمل کریں گے، پھر کریڈینشلز یہاں پیسٹ کریں گے۔';
  }

  @override
  String get chatCreateApp => 'ایپ بنائیں';

  @override
  String get chatCreateAppCta => 'میرے لیے ایپ بنائیں';

  @override
  String get chatAppNameLabel => 'ایپ کا نام';

  @override
  String get chatBotDisplayNameLabel =>
      'بوٹ نام (اراکین @ کے بعد کیا ٹائپ کریں)';

  @override
  String get chatDescriptionLabel => 'مختصر تفصیل';

  @override
  String get chatAgentDescriptionLabel => 'بوٹ کیا کہتا ہے کہ وہ کر سکتا ہے';

  @override
  String get chatCommandLabel => 'سلیش کمانڈ';

  @override
  String get chatDirectMessages => 'براہِ راست پیغامات';

  @override
  String chatDirectMessagesHint(String provider) {
    return 'اراکین بوٹ سے DM میں چیٹ کر سکتے ہیں۔ ادا شدہ ⁨$provider⁩ پلان درکار ہو سکتا ہے۔';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return '⁨$provider⁩ نے ایپ ⁨$appId⁩ بنائی۔';
  }

  @override
  String chatRemainingSteps(String provider) {
    return 'کچھ مراحل باقی ہیں جو صرف ⁨$provider⁩ کر سکتا ہے:';
  }

  @override
  String get chatStepAppToken => 'ایپ لیول ٹوکن بنائیں';

  @override
  String get chatStepInstall => 'ایپ انسٹال کریں';

  @override
  String get chatOpenAppSettings => 'ایپ ترتیبات کھولیں';

  @override
  String get chatContinueToCredentials => 'کریڈینشلز پیسٹ کریں';

  @override
  String chatBotUpdated(String provider) {
    return 'بوٹ ⁨$provider⁩ میں اپ ڈیٹ ہو گیا۔';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return '⁨$provider⁩ نے ایپ کی اجازتیں بدل دیں۔ اثر کے لیے ایپ دوبارہ انسٹال کریں۔';
  }

  @override
  String get chatReinstallApp => 'ایپ دوبارہ انسٹال کریں';

  @override
  String chatIconNotEditable(String provider) {
    return 'بوٹ کا آئیکن صرف ⁨$provider⁩ کی اپنی ایپ ترتیبات میں بدل سکتا ہے۔';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return 'آپ اسے ⁨$provider⁩ میں خود بھی بنا سکتے ہیں — ٹوکن کی ضرورت نہیں۔ اوپر کی ترتیبات لنک کے ساتھ جاتی ہیں۔';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return '⁨$provider⁩ میں بنائیں';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return '⁨$provider⁩ آپ کے براؤزر میں اس کنفیگریشن کے ساتھ کھلا۔ وہاں ایپ بنائیں، پھر یہ مراحل مکمل کریں اور ٹوکنز لے کر واپس آئیں۔';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return '⁨$provider⁩ نہیں بتاتا کہ کون سی ایپ بنائی، اس لیے یہاں سے بوٹ حسبِ ضرورت کے لیے بعد میں ایپ کنفیگریشن ٹوکن چاہیے۔';
  }

  @override
  String get chatStepCreateApp => 'پہلے سے بھری کنفیگریشن سے ایپ بنائیں';

  @override
  String chatStepCreateAppHint(String provider) {
    return '⁨$provider⁩ میں ورک اسپیس منتخب کریں اور تصدیق کریں۔';
  }

  @override
  String get chatStepAppTokenHint =>
      'Basic information → app-level tokens، ⁨connections:write⁩ اسکوپ کے ساتھ۔';

  @override
  String get chatStepInstallHint =>
      'Install app → بوٹ یوزر OAuth ٹوکن کاپی کریں۔';

  @override
  String get aboutTitle => 'کے بارے میں';

  @override
  String get aboutAppVersion => 'ایپ ورژن';

  @override
  String get aboutServerVersion => 'منسلک سرور';

  @override
  String get aboutRpcCatalog => 'RPC کیٹلاگ';

  @override
  String get aboutServerUnknown => 'رپورٹ نہیں';

  @override
  String get serverStaleTitle => 'بنڈل سرور اس ایپ سے پرانا ہے';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return 'چلتا ⁨cc_server⁩ ⁨$serverVersion⁩ ہے جبکہ یہ ایپ ⁨$appVersion⁩ ہے۔ تازہ ترین بنڈل سرور بلڈ لینے کے لیے ایپ دوبارہ شروع کریں؛ ڈیولپمنٹ میں ⁨apps/cc_server⁩ میں ⁨dart build cli⁩ سے دوبارہ بنائیں۔';
  }

  @override
  String get updateCheckButton => 'اپ ڈیٹس چیک کریں';

  @override
  String get updateChecking => 'اپ ڈیٹس چیک ہو رہے ہیں…';

  @override
  String get updateUpToDate => 'آپ تازہ ترین ہیں';

  @override
  String get updateDeferredBusy =>
      'اپ ڈیٹ تیار ہے مگر میٹنگ ریکارڈ ہو رہی ہے — ختم ہونے کے بعد پوچھے گی۔';

  @override
  String get updateOpenedReleasesPage => 'براؤزر میں ریلیزز صفحہ کھل گیا۔';

  @override
  String get updateCheckFailed => 'اپ ڈیٹ چیک ناکام';

  @override
  String updateAvailableVersion(String version) {
    return 'ورژن ⁨$version⁩ دستیاب ہے۔';
  }

  @override
  String get updateBannerTitle => 'نیا Control Center دستیاب ہے';

  @override
  String get updateBannerRefresh => 'تازہ کریں';

  @override
  String get updateBlockedRecording =>
      'میٹنگ ریکارڈ ہوتے ہوئے تازہ کرنا رک گیا ہے — ختم ہونے پر دوبارہ لوڈ ہوگا۔';

  @override
  String get settingsScopeYou => 'آپ';

  @override
  String get settingsScopeWorkspace => 'ورک اسپیس';

  @override
  String get settingsScopeServer => 'سرور';

  @override
  String get settingsProfile => 'پروفائل اور شناخت';

  @override
  String get settingsYourDevices => 'آپ کی ڈیوائسز';

  @override
  String get settingsWorkspaceGeneral => 'عام';

  @override
  String get settingsServerConnection => 'کنکشن اور اسٹیٹس';

  @override
  String get settingsModelProviders => 'ماڈل فراہم کنندگان';

  @override
  String get settingsVoiceModels => 'آواز اور میٹنگ ماڈلز';

  @override
  String get settingsDiagnostics => 'تشخیص اور پرائیویسی';

  @override
  String get settingsAbout => 'کے بارے میں';

  @override
  String get settingsProfileDescription =>
      'اس ورک اسپیس میں آپ کا نام، ای میل اور git شناخت۔ ورک اسپیس بدلنے سے یہ پرت بدلتی ہے؛ آپ کا یوزر نیم، سائن ان اور ڈیوائسز آپ کے آپ ← پروفائل والے اکاؤنٹ پر رہتے ہیں۔';

  @override
  String get settingsServerConnectionDescription =>
      'یہ کلائنٹ کس سرور سے بات کرتا ہے، اور یہ سرور کیسے شیئر ہوتا ہے (mDNS، ٹنلز، ریلے)۔';

  @override
  String get settingsAboutDescription => 'بلڈ شناخت اور اپ ڈیٹس۔';

  @override
  String get settingsDiagnosticsDescription =>
      'اس انسٹال کے لیے علیحدگی، انڈیکسنگ، سنک، لاگنگ اور کریش رپورٹنگ۔';

  @override
  String get settingsWorkspaceGeneralDescription =>
      'پالیسیاں اور روایات جو اس ورک اسپیس میں سب کے درمیان مشترک ہیں۔';

  @override
  String get settingsWorkspaceMeetingsDescription =>
      'اس ورک اسپیس کی میٹنگز کے لیے نوٹ ٹیمپلیٹس اور محفوظ شدہ آوازیں۔';

  @override
  String get settingsWorkspacePolicyLabel => 'ورک اسپیس پالیسی';

  @override
  String get settingsWorkspacePolicyDescription =>
      'اس ورک اسپیس کے ہر رکن اور ہر ایجنٹ پر لاگو۔';

  @override
  String get settingsSecretGlobsLabel => 'خفیہ پاتھ اخراجات';

  @override
  String get settingsSecretGlobsHelp =>
      'فی لائن ایک glob۔ یہ پاتھ ناظرین اور مہمانوں سے کوڈ سطحوں پر چھپتے ہیں، بلٹ اِن ڈیفالٹس کے علاوہ۔';

  @override
  String get settingsReviewConcurrencyLabel => 'ریویو فین آؤٹ';

  @override
  String get settingsReviewConcurrencyHelp =>
      'جب واضح تعداد نہ ہو تو کتنے ریویوورز متوازی ڈسپیچ ہوتے ہیں۔';

  @override
  String get settingsReviewLevelLabel => 'ریویو سطح';

  @override
  String get settingsReviewLevelHelp =>
      'AI ریویو کتنا گہرا ہے، اور جو ملتا ہے اس میں سے کتنا پہلے رپورٹ ہوتا ہے۔ کچھ ضائع نہیں — ہلکی سطح چھوٹے نتائج گروپ کرتی ہے، ہٹاتی نہیں۔';

  @override
  String get reviewLevelLight => 'ہلکا';

  @override
  String get reviewLevelBalanced => 'متوازن';

  @override
  String get reviewLevelThorough => 'گہرا';

  @override
  String get reviewLevelLightHint =>
      'ایک ریویوور۔ صرف جو حقیقتاً اہم ہے پہلے رپورٹ ہوتا ہے۔';

  @override
  String get reviewLevelBalancedHint =>
      'تین ریویوورز: QA، آرکیٹیکچر اور امپلیمنٹیشن۔';

  @override
  String get reviewLevelThoroughHint =>
      'سیکیورٹی اور پرفارمنس ماہرین شامل، اور جو ملا سب رپورٹ۔';

  @override
  String get askAiReviewAtLevel => 'دوسری سطح پر ریویو';

  @override
  String reviewNitpicksGroup(int count) {
    return 'نٹ پکس ($count)';
  }

  @override
  String get reviewFindingResolve => 'درست';

  @override
  String get reviewFindingResolveHint =>
      'اس نتیجے کو درست نشان زد کریں۔ یہ ریویو کے خلاف گننا بند ہو جاتا ہے۔';

  @override
  String get reviewFindingDismiss => 'برطرف کریں';

  @override
  String get reviewFindingDismissHint =>
      'اصل مسئلہ نہیں۔ ریویوورز مستقبل کے PRs پر اس پیٹرن کو نشان نہیں لگاتے۔';

  @override
  String get reviewFindingReopen => 'دوبارہ کھولیں';

  @override
  String get reviewFindingStatusUndoLabel => 'نتیجے کا اسٹیٹس';

  @override
  String get reviewFindingDismissTitle => 'اس نتیجے کو برطرف کریں';

  @override
  String get reviewFindingDismissReasonHint =>
      'یہ کیوں لاگو نہیں؟ ریویوورز اسے پڑھیں گے۔';

  @override
  String reviewFindingStatusFailed(String error) {
    return 'نتیجہ اپ ڈیٹ نہیں ہو سکا: ⁨$error⁩';
  }

  @override
  String get reviewStaleTitle => 'یہ ریویو پرانا ہے';

  @override
  String get reviewStaleBody =>
      'اس ریویو کے بعد pull request آگے بڑھ چکا ہے۔ نتائج ایسے کوڈ کی طرف اشارہ کر سکتے ہیں جو اب موجود نہیں۔';

  @override
  String reviewStaleReviewedAt(String sha) {
    return '⁨$sha⁩ پر ریویو ہوا';
  }

  @override
  String get reviewStaleRerun => 'دوبارہ ریویو';

  @override
  String reviewStaleNotificationTitle(int prNumber) {
    return '⁨#$prNumber⁩ پر ریویو پرانا';
  }

  @override
  String reviewStaleNotificationBody(String title) {
    return '⁨$title⁩ کے آخری ریویو کے بعد نئے کمیٹس ہیں۔';
  }

  @override
  String get reviewCategorySecurity => 'سیکیورٹی';

  @override
  String get reviewCategoryStability => 'استحکام';

  @override
  String get reviewCategoryDataIntegrity => 'ڈیٹا سالمیت';

  @override
  String get reviewCategoryCorrectness => 'درستگی';

  @override
  String get reviewCategoryPerformance => 'پرفارمنس';

  @override
  String get reviewCategoryMaintainability => 'قابلِ دیکھ بھال';

  @override
  String get reviewEffortQuickWin => 'فوری فائدہ';

  @override
  String get reviewEffortModerate => 'درمیانہ';

  @override
  String get reviewEffortHeavyLift => 'بھاری کام';

  @override
  String get reviewProposedFix => 'تجویز کردہ درستگی';

  @override
  String get reviewAiAgentPrompt => 'AI ایجنٹس کے لیے پرامپٹ';

  @override
  String get reviewCopyAiPrompt => 'پرامپٹ کاپی کریں';

  @override
  String get settingsWorkspaceAdminOnly =>
      'صرف ورک اسپیس ایڈمنز یہ بدل سکتے ہیں۔';

  @override
  String get chatMyAccountsTitle => 'لنک شدہ چیٹ اکاؤنٹس';

  @override
  String get settingsServerSso => 'سنگل سائن آن';

  @override
  String get settingsServerSsoDescription =>
      'SAML اور OpenID Connect لاگ اِن، صارف پروویژنگ کے ساتھ';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabledDescription =>
      'صارفین اس فراہم کنندہ سے سائن اِن کر سکتے ہیں';

  @override
  String get ssoEnabledDescriptionOn =>
      'اس فراہم کنندہ کے لیے سائن اِن لائیو ہے';

  @override
  String get ssoIdpMetadataLabel => 'IdP میٹا ڈیٹا XML';

  @override
  String get ssoIdpMetadataHint => 'IdP کا EntityDescriptor XML پیسٹ کریں';

  @override
  String get ssoEmailAttributeLabel => 'ای میل اٹریبیوٹ';

  @override
  String get ssoDisplayNameAttributeLabel => 'ڈسپلے نام اٹریبیوٹ';

  @override
  String get ssoGroupsAttributeLabel => 'گروپس اٹریبیوٹ';

  @override
  String get ssoIssuerLabel => 'Issuer URL';

  @override
  String get ssoClientIdLabel => 'Client ID';

  @override
  String get ssoGroupsClaimLabel => 'Groups claim';

  @override
  String get ssoAutoMemberLabel =>
      'پہلے لاگ اِن پر صارفین ہر ورک اسپیس میں شامل کریں';

  @override
  String get ssoAutoMemberDescription =>
      'ہر ورک اسپیس کے لیے دعوت درکار رکھنے کے لیے بند کریں';

  @override
  String get ssoAllowJitLabel => 'پہلے لاگ اِن پر نامعلوم صارفین پروویژن کریں';

  @override
  String get ssoAllowJitDescription =>
      'موجودہ اکاؤنٹ کے بغیر صارفین مسترد کرنے کے لیے بند کریں';

  @override
  String get ssoAllowIdpInitiatedLabel =>
      'غیر مانگا (IdP سے شروع) سائن اِن قبول کریں';

  @override
  String get ssoAllowIdpInitiatedDescription =>
      'صرف ان IdP پورٹلز کے لیے جو ایپس براہِ راست کھولتے ہیں';

  @override
  String get ssoWantResponseSignedLabel => 'دستخط شدہ رسپانس اینویلوپ درکار';

  @override
  String get ssoWantResponseSignedDescription =>
      'Assertion دستخط ہمیشہ درکار ہیں';

  @override
  String get ssoTestConnectionButton => 'کنکشن ٹیسٹ کریں';

  @override
  String get ssoTestConnectionOk => 'کنکشن کام کرتا ہے:';

  @override
  String get ssoCopySpMetadata => 'SP میٹا ڈیٹا کاپی کریں';

  @override
  String get ssoCopySpMetadataDone => 'SP میٹا ڈیٹا کلپ بورڈ پر کاپی ہو گیا';

  @override
  String get ssoSavedToast => 'سنگل سائن آن ترتیبات محفوظ ہو گئیں';

  @override
  String get ssoUnavailable =>
      'یہ سرور سنگل سائن آن ترتیبات نہیں دیتا۔ سرور بائنری اپ ڈیٹ کریں اور دوبارہ کوشش کریں۔';

  @override
  String get ssoScimCardTitle => 'صارف پروویژنگ (SCIM)';

  @override
  String get ssoScimDescription =>
      'اپنے شناخت فراہم کنندہ کے SCIM کنیکٹر کو نیچے اینڈ پوائنٹ پر bearer ٹوکن کے ساتھ سیٹ کریں۔ ڈی پروویژنگ سیشنز اور ورک اسپیس رسائی سیکنڈوں میں منسوخ کرتی ہے۔ سرور IdP سے پہنچنے کے قابل ہونا چاہیے (ٹنل یا پبلک URL)۔';

  @override
  String get ssoScimEndpoint => 'SCIM اینڈ پوائنٹ';

  @override
  String get ssoScimEndpointUnknownOrigin =>
      'پہلے سرور کا پبلک URL سیٹ کریں یا ٹنل فعال کریں';

  @override
  String get ssoScimRegenerate => 'ٹوکن دوبارہ بنائیں';

  @override
  String get ssoScimRegenerateConfirm =>
      'نیا SCIM bearer ٹوکن بنائیں؟ پچھلا ٹوکن فوراً کام کرنا بند کر دیتا ہے۔';

  @override
  String get ssoScimTokenTitle => 'Bearer ٹوکن';

  @override
  String get ssoScimTokenPresent => 'ٹوکن کنفیگر ہے';

  @override
  String get ssoScimTokenAbsent =>
      'ابھی کوئی ٹوکن نہیں — SCIM فعال کرنے کے لیے ایک بنائیں';

  @override
  String get ssoScimTokenOnce => 'SCIM ٹوکن (ایک بار دکھتا ہے)';

  @override
  String ssoSignInWith(String provider) {
    return '⁨$provider⁩ سے سائن اِن';
  }

  @override
  String get ssoProbeFailed => 'سنگل سائن آن کے لیے اس سرور تک نہیں پہنچ سکے';

  @override
  String get ssoOpensBrowser =>
      'سائن اِن مکمل کرنے کے لیے آپ کا براؤزر کھلتا ہے';

  @override
  String get ssoWaitingForBrowser => 'براؤزر میں سائن اِن مکمل ہونے کا انتظار…';

  @override
  String get ssoBrowserOpenFailed => 'سنگل سائن آن کے لیے براؤزر نہیں کھل سکا';

  @override
  String get ssoUseManualPairing =>
      'اس کے بجائے دعوت یا پیئرنگ کلید سے سائن اِن کریں';

  @override
  String get ssoHideManualPairing => 'دستی پیئرنگ چھپائیں';

  @override
  String get ssoClientIdHint => 'پبلک (PKCE) کلائنٹ — سیکرٹ کی ضرورت نہیں';

  @override
  String get ssoClientSecretLabel => 'Client secret (اختیاری)';

  @override
  String get ssoClientSecretHintUnset => 'صرف خفیہ IdP کلائنٹس کے لیے درکار';

  @override
  String get ssoClientSecretHintSet =>
      'سیکرٹ محفوظ ہے — رکھنے کے لیے خالی چھوڑیں';

  @override
  String get ssoPairingToggle =>
      'دستی پیئرنگ کی اجازت دیں (دعوتی کوڈز اور پیئرنگ کلیدیں)';

  @override
  String get ssoPairingToggleDescription =>
      'شامل ہونا صرف سنگل سائن آن رکھنے کے لیے بند کریں — نئی ڈیوائسز SSO لاگ اِن سے آتی ہیں؛ موجودہ کام کرتی رہتی ہیں';

  @override
  String get ssoPairConfirmTitle => 'سرور سے منسلک ہوں؟';

  @override
  String ssoPairConfirmBody(String server) {
    return '⁨$server⁩ کے لیے سائن اِن کریڈینشل آیا، مگر اس ایپ سے سائن اِن شروع نہیں ہوا۔ اس سرور سے منسلک ہوں؟';
  }

  @override
  String get ssoPairConfirmConnect => 'منسلک ہوں';

  @override
  String get ssoPairConfirmCancel => 'نظر انداز کریں';

  @override
  String get forgeConnections => 'کوڈ ہوسٹنگ';

  @override
  String get connect => 'منسلک ہوں';

  @override
  String get disconnect => 'منقطع کریں';

  @override
  String get notConnected => 'منسلک نہیں';

  @override
  String get checkingConnection => 'کنکشن چیک ہو رہا ہے…';

  @override
  String forgeTokenTitle(String forge) {
    return '⁨$forge⁩ ٹوکن';
  }

  @override
  String get settingsAudio => 'آڈیو';

  @override
  String get settingsAudioDescription =>
      'مائیکروفون، ڈکٹیشن، میٹنگ دریافت اور ساؤنڈ اسکیپ آؤٹ پٹ۔';

  @override
  String get audioDevicesSection => 'آڈیو ڈیوائسز';

  @override
  String get voiceInputBehaviorSection => 'ڈکٹیشن اور میٹنگز';

  @override
  String get audioOutputDeviceTitle => 'آؤٹ پٹ ڈیوائس';

  @override
  String get audioOutputDefaultHint =>
      'تمام ایپ آواز سسٹم ڈیفالٹ آؤٹ پٹ سے چلتی ہے۔';

  @override
  String get audioOutputGone =>
      'منتخب آؤٹ پٹ ڈیوائس اب منسلک نہیں — دوسری منتخب کرنے تک سسٹم ڈیفالٹ استعمال ہوتا ہے۔';

  @override
  String get reviewHubIntroBody =>
      'ایجنٹس diff کا تجزیہ کرتے ہیں، تبدیلی کے علاقے نقشہ کرتے ہیں اور اتفاق کا فیصلہ تک پہنچتے ہیں۔';

  @override
  String get reviewHubAlreadyRunning =>
      'اس pull request کے لیے ریویو پہلے سے چل رہا ہے';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return 'آخری ریویو سے: $resolved حل · $added نئے · $open ابھی کھلے';
  }

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return 'پہلے ⁨$sha⁩ پر ریویو ہوا';
  }

  @override
  String reviewArtifactFixAll(int count) {
    return '$count نتائج درست کریں';
  }

  @override
  String reviewArtifactFixSelected(int count) {
    return '$count منتخب درست کریں';
  }

  @override
  String reviewArtifactCommentSelected(int count) {
    return '$count منتخب پر تبصرہ';
  }

  @override
  String get webConnectStayConnected => 'اس ڈیوائس پر منسلک رہیں';

  @override
  String get webConnectStayConnectedDetail =>
      'اس ڈیوائس پر منسلک رہیں (اس براؤزر میں آپ کی کلید محفوظ ہوتی ہے)';

  @override
  String failedToCreateWorkspace(String error) {
    return 'ورک اسپیس نہیں بن سکا: ⁨$error⁩';
  }

  @override
  String committedRelative(String relative) {
    return '$relative کمیٹ ہوا';
  }

  @override
  String get selectAgents => 'ایجنٹس منتخب کریں';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ایجنٹس',
      one: '1 ایجنٹ',
    );
    return '$_temp0';
  }

  @override
  String get newConversation => 'نئی گفتگو';

  @override
  String get untitledConversation => 'بے عنوان گفتگو';

  @override
  String get conversationTitleOptionalHint =>
      'اختیاری — خالی چھوڑیں تو عنوان ماڈل خود نام دے گا';

  @override
  String get contentSynthesizerUnavailable =>
      'Content synthesizer ایجنٹ موجود نہیں یا اس کے پاس کام کرنے والا رنر نہیں';

  @override
  String get conversationNeedsAgent =>
      'یہ گفتگو شروع کرنے کے لیے @ سے کسی ایجنٹ کا ذکر کریں';

  @override
  String get conversationTitleGenerate => 'بنائیں';

  @override
  String get conversationTitleNoMessages =>
      'پہلے ایک پیغام بھیجیں۔ عنوان اسی سے بنتا ہے۔';

  @override
  String get conversationTitleGenerateFailed =>
      'عنوان نہیں بن سکا۔ دوبارہ کوشش کریں۔';

  @override
  String get startThread => 'تھریڈ شروع کریں';

  @override
  String get deleteSpaceConfirm =>
      'یہ اسپیس حذف کریں؟ تمام پیغامات ضائع ہو جائیں گے۔';

  @override
  String threadTabTitle(String title) {
    return 'تھریڈ: ⁨$title⁩';
  }

  @override
  String threadReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count جوابات',
      one: '1 جواب',
    );
    return '$_temp0';
  }

  @override
  String threadLastReply(String time) {
    return 'آخری جواب $time';
  }

  @override
  String signInWithProvider(String provider) {
    return '⁨$provider⁩ سے سائن اِن';
  }

  @override
  String get signInAgain => 'دوبارہ سائن اِن کریں';

  @override
  String get forgeSignInBannerTitle =>
      'اس ورک اسپیس میں کوڈ ہوسٹنگ منسلک نہیں ہے';

  @override
  String get forgeSignInBannerBody =>
      'کسی سائن اِن کی میعاد ختم ہو گئی یا اسے منسوخ کر دیا گیا، یا یہ ورک اسپیس اپنا GitHub App استعمال کرتی ہے۔ سائن اِن کرنے تک پُل ریکویسٹس، ریویوز اور ریپوزٹری کی ہم آہنگی رکی ہوئی ہیں۔';

  @override
  String get forgeSignInBannerAction => 'سائن اِن کریں';

  @override
  String get ticketing => 'ٹکٹنگ';

  @override
  String get ticketingProviderHelp =>
      'آپ کے ٹکٹس کہاں رہتے ہیں۔ مقامی انہیں Control Center میں رکھتا ہے۔';

  @override
  String providerComingSoon(String provider) {
    return '⁨$provider⁩ (جلد)';
  }

  @override
  String get ticketProviderLocal => 'مقامی';

  @override
  String get providerApps => 'فراہم کنندہ ایپس';

  @override
  String get providerAppsDescription =>
      'وہ ایپس جو اس سرور نے ہر فراہم کنندہ کے پاس خود رجسٹر کی ہیں۔ لوگ ان کے ذریعے سائن اِن کرتے ہیں، اور پس منظر کا کام جیسے webhooks، پولنگ اور ہم آہنگی انہی پر چلتا ہے، کبھی کسی شخص کے سائن اِن پر نہیں۔';

  @override
  String get providerAppId => 'App id';

  @override
  String get providerPrivateKey => 'پرائیویٹ کلید';

  @override
  String get providerClientId => 'Client id';

  @override
  String get providerClientSecret => 'Client secret';

  @override
  String get providerCallbackUrl => 'Callback URL';

  @override
  String get providerAppFullyConfigured =>
      'سرور خود عمل کر سکتا ہے، اور لوگ سائن اِن کر سکتے ہیں۔';

  @override
  String get providerAppServerOnly =>
      'سرور خود عمل کر سکتا ہے۔ لوگوں کو سائن اِن دینے کے لیے client id اور secret شامل کریں۔';

  @override
  String get providerAppSignInOnly =>
      'لوگ سائن اِن کر سکتے ہیں۔ پس منظر کام ان کے کریڈینشلز پر واپس جاتا ہے۔';

  @override
  String providerAppInstalledOn(String accounts) {
    return 'کریڈینشلز کام کرتے ہیں۔ انسٹال: ⁨$accounts⁩';
  }

  @override
  String get couldNotOpenBrowser =>
      'کوئی براؤزر نہیں کھل سکا۔ لنک کاپی کریں اور سائن اِن خود مکمل کریں۔';

  @override
  String get contextUsage => 'سیاق استعمال';

  @override
  String get contextUsageFull => 'بھرا';

  @override
  String get contextUsageTokens => 'ٹوکنز';

  @override
  String get contextSeeMore => 'مزید دیکھیں';

  @override
  String get contextSegmentSystemPrompt => 'سسٹم پرامپٹ';

  @override
  String get contextSegmentRules => 'قواعد';

  @override
  String get contextSegmentSkills => 'مہارتیں';

  @override
  String get contextSegmentToolDefinitions => 'ٹول تعریفیں';

  @override
  String get contextSegmentMcpTools => 'MCP اور ڈائنامک ٹولز';

  @override
  String get contextSegmentDeferredTools => 'طلب پر لوڈ ٹولز';

  @override
  String get contextSegmentSubagents => 'ذیلی ایجنٹ تعریفیں';

  @override
  String get contextSegmentMemory => 'میموری';

  @override
  String get contextSegmentConversation => 'گفتگو';

  @override
  String get contextSegmentRunner => 'رنر کا پرامپٹ، ٹولز اور باری کا کام';

  @override
  String get contextUsageMeasured => 'ماڈل کی آخری کال کے مطابق';

  @override
  String get contextUsageEstimated =>
      'تخمینہ، جب تک کوئی رن استعمال رپورٹ نہ کرے';

  @override
  String get contextExplorerTitle => 'سیاق';

  @override
  String get contextExplorerEverything => 'سب کچھ';

  @override
  String get contextExplorerSelectPart => 'مواد دیکھنے کے لیے حصہ منتخب کریں';

  @override
  String get contextExplorerUnavailable => 'سیاق تفصیل دستیاب نہیں';

  @override
  String get contextRetry => 'دوبارہ کوشش';

  @override
  String get settingsFieldOptional => 'اختیاری';

  @override
  String get settingsFilterHint => 'یہ فہرست فلٹر کریں';

  @override
  String get settingsValueNotAvailable => 'ابھی دستیاب نہیں';

  @override
  String get settingsNoEntriesYet => 'ابھی یہاں کچھ نہیں';

  @override
  String get settingsChangedBadge => 'بدلا ہوا';

  @override
  String get ssoConnectionCardDescription =>
      'اس سرور پر لوگ کیسے سائن اِن کریں منتخب کریں، پھر وہ کنکشن آن کریں۔';

  @override
  String get ssoUseSamlForSignIn => 'سائن اِن کے لیے SAML استعمال کریں';

  @override
  String get ssoUseOidcForSignIn =>
      'سائن اِن کے لیے OpenID Connect استعمال کریں';

  @override
  String get ssoSaveConnection => 'کنکشن محفوظ کریں';

  @override
  String get ssoStateLive => 'لائیو';

  @override
  String get ssoStateConfiguredOff => 'کنفیگر، آف';

  @override
  String get ssoStateOnIncomplete => 'آن، نامکمل';

  @override
  String get ssoStateActive => 'فعال';

  @override
  String get ssoStateAllowed => 'اجازت';

  @override
  String get ssoStateNoToken => 'کوئی ٹوکن نہیں';

  @override
  String get ssoSummaryDirectorySync => 'ڈائریکٹری سنک';

  @override
  String get ssoSummaryManualPairing => 'دستی پیئرنگ';

  @override
  String get ssoNoMethodLiveNote =>
      'کوئی سائن اِن طریقہ لائیو نہیں۔ کنکشن کنفیگر اور آن کرنے تک نئی ڈیوائسز دعوت یا پیئرنگ کلید سے شامل ہوتی ہیں۔';

  @override
  String get ssoMethodSamlBlurb =>
      'ان شناخت فراہم کنندگان کے لیے جو SAML 2.0 بولتے ہیں، جیسے Okta، Entra ID یا Google Workspace۔';

  @override
  String get ssoMethodOidcBlurb =>
      'ان شناخت فراہم کنندگان کے لیے جو OpenID Connect بولتے ہیں۔ عام طور پر دونوں میں سیٹ اپ آسان۔';

  @override
  String get ssoGroupIdentityProvider => 'شناخت فراہم کنندہ';

  @override
  String get ssoGroupIdentityProviderSamlDescription =>
      'Assertions کہاں سے آتے ہیں، اور یہ سرور انہیں کیسے تصدیق کرتا ہے۔';

  @override
  String get ssoGroupIdentityProviderOidcDescription =>
      'یہ سرور کس issuer پر بھروسہ کرتا ہے، اور کلائنٹ کے طور پر کیسے تصدیق کرتا ہے۔';

  @override
  String get ssoSpEntityIdShortLabel => 'SP entity ID';

  @override
  String get ssoSpEntityIdDescription =>
      'سرور URL سے اخذ کرنے کے لیے خالی چھوڑیں۔';

  @override
  String get ssoIssuerDescription =>
      'بیس URL جو فراہم کنندہ کا discovery دستاویز پیش کرتا ہے۔';

  @override
  String get ssoSecretStored => 'محفوظ';

  @override
  String get ssoGroupHandoff => 'آپ کے شناخت فراہم کنندہ کو کیا چاہیے';

  @override
  String get ssoGroupHandoffDescription =>
      'انہیں اپنے فراہم کنندہ پر بنائی ایپلیکیشن میں پیسٹ کریں۔';

  @override
  String get ssoOriginUnknownTitle => 'اس سرور کو اپنا پبلک URL معلوم نہیں';

  @override
  String get ssoOriginUnknownBody =>
      'سائن اِن اور callback URLs اسی سے بنتے ہیں، اس لیے سیٹ ہونے تک فراہم کنندہ اس سرور تک نہیں پہنچ سکتا۔ پبلک URL شامل کریں یا سرور ← کنکشن کے تحت ٹنل فعال کریں۔';

  @override
  String get ssoAcsUrlLabel => 'Assertion consumer service (ACS) URL';

  @override
  String get ssoAcsUrlDescription =>
      'جہاں آپ کا فراہم کنندہ دستخط شدہ assertion پوسٹ کرتا ہے۔';

  @override
  String get ssoSpEntityIdResolvedLabel => 'سروس فراہم کنندہ entity ID';

  @override
  String get ssoMetadataUrlLabel => 'SP metadata URL';

  @override
  String get ssoMetadataUrlDescription =>
      'جو فراہم کنندگان میٹا ڈیٹا درآمد کرتے ہیں وہ اسے یہاں سے حاصل کر سکتے ہیں۔';

  @override
  String get ssoRedirectUriLabel => 'Redirect URI';

  @override
  String get ssoRedirectUriDescription =>
      'اسے اپنے فراہم کنندہ کی ایپلیکیشن کے اجازت یافتہ redirect URIs میں شامل کریں۔';

  @override
  String get ssoSignInUrlLabel => 'سائن اِن URL';

  @override
  String get ssoSignInUrlDescription =>
      'سنگل سائن آن لاگ اِن شروع کرنے کے لیے لوگوں کو یہاں بھیجیں۔';

  @override
  String get ssoGroupAttributeMapping => 'اٹریبیوٹ میپنگ';

  @override
  String get ssoGroupAttributeMappingDescription =>
      'ہر فیلڈ کون سا claim لے جاتا ہے۔ ڈیفالٹس رکھیں جب تک فراہم کنندہ نام نہ بدلے۔';

  @override
  String get ssoGroupAccess => 'رسائی اور کردار';

  @override
  String get ssoGroupAccessDescription =>
      'کامیاب سائن اِن کرنے والے کو کیا کرنے کی اجازت ہے۔';

  @override
  String get ssoDefaultRoleShortLabel => 'ڈیفالٹ کردار';

  @override
  String get ssoDefaultRoleDescription =>
      'جس کے گروپس نیچے کسی میپنگ سے میل نہ کھائیں اسے ملتا ہے۔';

  @override
  String get ssoRoleMapShortLabel => 'گروپ سے کردار میپنگ';

  @override
  String get ssoRoleMapDescription =>
      'پہلا میل کھانے والا گروپ جیتتا ہے۔ مالک اس طریقے سے نہیں دیا جا سکتا۔';

  @override
  String get ssoRoleMapGroupHint => 'آپ کے فراہم کنندہ کا گروپ نام';

  @override
  String get ssoRoleMapAdd => 'میپنگ شامل کریں';

  @override
  String get ssoRoleMapEmpty => 'کوئی میپنگ نہیں — سب کو ڈیفالٹ کردار ملتا ہے۔';

  @override
  String get ssoAdvancedSummary =>
      'کلاک اسکیو، IdP سے شروع سائن اِن، دستخط پالیسی';

  @override
  String get ssoClockSkewShortLabel => 'کلاک اسکیو';

  @override
  String get ssoClockSkewDescription =>
      'Assertion ٹائم سٹیمپس پر سیکنڈز کی رواداری۔ 90 زیادہ تر فراہم کنندگان کے لیے موزوں۔';

  @override
  String get ssoScimGenerate => 'ٹوکن بنائیں';

  @override
  String get ssoScimTokenOnceBody =>
      'کلپ بورڈ پر کاپی ہو گیا۔ ایک بار دکھتا ہے اور بحال نہیں ہو سکتا، اس لیے ابھی اپنے فراہم کنندہ میں پیسٹ کریں۔';

  @override
  String get ssoPairingCardTitle => 'دستی پیئرنگ';

  @override
  String get ssoPairingCardDescription =>
      'اس سرور میں دوسرا راستہ: دعوتی کوڈز اور پیئرنگ کلیدیں، ان ڈیوائسز کے لیے جو سنگل سائن آن سے نہیں گزرتیں۔';

  @override
  String settingsCountOfTotal(int count, int total) {
    return '$count از $total';
  }

  @override
  String get providersNoneConnectedNote =>
      'کوئی فراہم کنندہ منسلک نہیں، اس لیے بلٹ اِن ایجنٹ رن ٹائم چلانے کو کچھ نہیں۔ نیچے API کلید شامل کریں یا سائن اِن کریں۔';

  @override
  String get providersFilterHint => 'فراہم کنندگان فلٹر کریں';

  @override
  String get providersNoneMatch => 'اس فلٹر سے کچھ میل نہیں کھاتا';

  @override
  String get providerDeniedHereTitle => 'اس ورک اسپیس میں منع';

  @override
  String get providerDeniedHereBody =>
      'یہاں ایجنٹس یہ فراہم کنندہ استعمال نہیں کر سکتے، چاہے منسلک ہو۔ دوسرے ورک اسپیسز متاثر نہیں۔';

  @override
  String get providerNeedsSignIn => 'اس فراہم کنندہ کے لیے سائن اِن کریں';

  @override
  String get providerNeedsApiKey => 'اس فراہم کنندہ کے لیے API کلید شامل کریں';

  @override
  String get providerApiKeyLabel => 'API کلید';

  @override
  String get providerGenerationDefaults => 'فراہم کنندہ ڈیفالٹس';

  @override
  String get providerNoModelsYet =>
      'ابھی کوئی ماڈل رپورٹ نہیں۔ فراہم کنندہ منسلک کریں، پھر سنک کریں۔';

  @override
  String get providerModelsFilterHint => 'ماڈلز فلٹر کریں';

  @override
  String get adaptersNoneReadyNote =>
      'اس مشین پر کیٹلاگ کا کوئی رنر CLI نہیں ملا۔ ایک انسٹال کریں، پھر تازہ کریں۔';

  @override
  String get adaptersFilterHint => 'رنرز فلٹر کریں';

  @override
  String get adaptersLaunchGroup => 'لانچ';

  @override
  String get adaptersLaunchGroupDescription =>
      'ایجنٹ شروع کرنے پر اس رنر کو کیا دیا جاتا ہے۔ CLI انسٹال سے پہلے بھی سیٹ کر سکتے ہیں۔';

  @override
  String get adaptersEnvNone => 'کوئی سیٹ نہیں';

  @override
  String adaptersEnvCount(int count) {
    return '$count سیٹ';
  }

  @override
  String get adapterArgumentsDescription =>
      'ہر لانچ پر رنر کی کمانڈ لائن کے ساتھ جڑتا ہے۔';

  @override
  String get settingsStateFailed => 'ناکام';

  @override
  String get providerAppsGroupServer => 'سرور کے طور پر عمل';

  @override
  String get providerAppsGroupServerDescription =>
      'یہ ان ورک اسپیسز کے لیے ہے جو اس سرور کی سائن ان ایپس کی پیروی کرتے ہیں۔ اپنی ایپس والا ورک اسپیس اپنی App کو ورک اسپیس ← انٹیگریشنز میں ترتیب دیتا ہے۔';

  @override
  String get providerAppsGroupPrConversations => 'Pull request گفتگوئیں';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      'ان ورک اسپیسز میں جو اس سرور کی پیروی کرتے ہیں، ڈیولپرز GitHub پر اس سرور سے کیسے بات کر سکتے ہیں۔ اپنی ایپس والے ورک اسپیس کا اپنا بوٹ ورک اسپیس ← انٹیگریشنز میں ہوتا ہے۔ کسی webhook یا عوامی URL کے بغیر کام کرتا ہے؛ سرور خود پولنگ کرتا ہے۔';

  @override
  String get providerAppBotLogin => 'بوٹ لاگ اِن';

  @override
  String get providerAppBotLoginEmpty =>
      'بوٹ لاگ اِن حل کرنے کے لیے کنکشن ٹیسٹ کریں۔';

  @override
  String get providerAppAskOnGitHub => 'GitHub پر پوچھنا';

  @override
  String get providerAppAskOnGitHubHint =>
      'pull request تبصرے میں اوپر بوٹ لاگ اِن کا ذکر کریں — ⁨[bot]⁩ لاحقہ اختیاری ہے — ریویو مانگنے یا سوال پوچھنے، اس کے ریویو تھریڈز میں جواب دینے، یا ریویو مانگنے کے لیے ⁨ai-review⁩ لیبل شامل کرنے کے لیے۔';

  @override
  String get providerAppsGroupSignIn => 'لوگوں کو سائن اِن کرنا';

  @override
  String get providerAppsGroupSignInDescription =>
      'ہر رکن اپنا اکاؤنٹ منسلک کر کے اپنا کریڈینشل حاصل کر سکتا ہے۔';

  @override
  String get providerAppCapActsAsServer => 'سرور کے طور پر عمل کرتا ہے';

  @override
  String get providerAppCapSignsIn => 'لوگوں کو سائن اِن کرتا ہے';

  @override
  String get portLabel => 'پورٹ';

  @override
  String get mcpBridgedToolsLabel => 'ٹولز';

  @override
  String get guardrailFamilyFiles => 'فائلیں';

  @override
  String get guardrailFamilyGit => 'Git اور pull requests';

  @override
  String get guardrailFamilyMachine => 'مشین اور نیٹ ورک';

  @override
  String get guardrailFamilyControl => 'راز اور ورک اسپیس';

  @override
  String get guardrailScopeFieldLabel => 'قواعد کی ترمیم برائے';

  @override
  String get guardrailScopeFieldDescription =>
      'تنگ دائرہ وسیع پر غالب۔ یہاں سیٹ قواعد وراثت کے اوپر لاگو ہوتے ہیں۔';

  @override
  String get guardrailSetHere => 'یہاں سیٹ';

  @override
  String get guardrailClearAllHere => 'سب صاف کریں';

  @override
  String get guardrailFamilyCommands => 'کمانڈز';

  @override
  String get guardrailStandingApproval => 'جاری منظوری';

  @override
  String guardrailEntryAllow(String what) {
    return 'اجازت دیں: $what';
  }

  @override
  String guardrailEntryPrompt(String what) {
    return 'پہلے پوچھیں: $what';
  }

  @override
  String guardrailEntryDeny(String what) {
    return 'منع کریں: $what';
  }

  @override
  String guardrailCoversBranches(String patterns) {
    return 'برانچز $patterns';
  }

  @override
  String guardrailCoversPaths(String patterns) {
    return 'راستے $patterns';
  }

  @override
  String guardrailCoversHosts(String patterns) {
    return 'ہوسٹس $patterns';
  }

  @override
  String guardrailCoversCommands(String patterns) {
    return 'کمانڈز $patterns';
  }

  @override
  String guardrailCoversTools(String names) {
    return 'ٹولز $names';
  }

  @override
  String guardrailCoversCommandPrefix(String prefix) {
    return 'وہ کمانڈز جو $prefix سے شروع ہوں';
  }

  @override
  String guardrailCoversMaxCount(String count) {
    return 'ایک وقت میں زیادہ سے زیادہ $count';
  }

  @override
  String guardrailCoversMaxCents(String amount) {
    return 'زیادہ سے زیادہ $amount سینٹ';
  }

  @override
  String get guardrailCoversEverything => 'اس قسم کا ہر ایکشن';

  @override
  String guardrailEntryGivenBy(String name) {
    return '$name کی طرف سے';
  }

  @override
  String guardrailEntryEnds(String time) {
    return '$time پر ختم ہوگا';
  }

  @override
  String get guardrailEntryNoEnd => 'منسوخ ہونے تک';

  @override
  String guardrailRevokeEntry(String entry) {
    return 'منسوخ کریں: $entry';
  }

  @override
  String get guardrailRevokeFailed => 'منسوخ نہیں ہو سکا۔ دوبارہ کوشش کریں۔';

  @override
  String get guardrailEntryInactive => 'منع ہونے کے دوران نافذ نہیں';

  @override
  String guardrailClassPartlyAllowed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'نیچے درج $count صورتوں میں اجازت ہے',
      one: 'نیچے درج 1 صورت میں اجازت ہے',
    );
    return '$_temp0';
  }

  @override
  String guardrailStandingFromWorkspace(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'پوری ورک اسپیس کے لیے $count جاری منظوریاں یہاں بھی لاگو ہوتی ہیں۔',
      one: 'پوری ورک اسپیس کے لیے 1 جاری منظوری یہاں بھی لاگو ہوتی ہے۔',
    );
    return '$_temp0';
  }

  @override
  String guardrailStandingInNarrowerScopes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count جاری منظوریاں الگ الگ اسپیسز یا ایجنٹس کے لیے سیٹ ہیں۔ انہیں دیکھنے کے لیے اوپر اسپیس یا ایجنٹ منتخب کریں۔',
      one:
          'ایک جاری منظوری ایک ہی اسپیس یا ایجنٹ کے لیے سیٹ ہے۔ اسے دیکھنے کے لیے اوپر اسپیس یا ایجنٹ منتخب کریں۔',
    );
    return '$_temp0';
  }

  @override
  String get sandboxingCardLabel => 'سینڈ باکسنگ';

  @override
  String get sandboxingCardDescription =>
      'ایجنٹ کام اس ہوسٹ سے الگ چلتا ہے یا نہیں، اور الگ ایجنٹ پھر بھی کیا پہنچ سکتا ہے۔';

  @override
  String get sandboxBackendNoneActive => 'ہوسٹ، کوئی علیحدگی نہیں';

  @override
  String get sandboxSummaryHost => 'ہوسٹ';

  @override
  String get sandboxGroupIsolation => 'علیحدگی';

  @override
  String get sandboxGroupIsolationDescription =>
      'ایجنٹ کے پراسیس اور فائل رائٹس اصل میں کہاں ہوتے ہیں۔';

  @override
  String get sandboxGroupAgentActions => 'ایجنٹ کیا کر سکتے ہیں';

  @override
  String get sandboxGroupAgentActionsDescription =>
      'پش کرنا، pull request کھولنا اور نیٹ ورک تک رسائی کی اجازت ہو، پہلے پوچھا جائے یا منع کیا جائے، یہ ایجنٹ اجازتوں میں طے ہوتا ہے۔';

  @override
  String get sandboxBackendFieldDescription =>
      'آٹو اس ہوسٹ کی سب سے مضبوط معاونت چنتا ہے۔ تبدیل نہ ہونے کے لیے ایک پن کریں۔';

  @override
  String get sandboxSummaryInForce => 'نافذ';

  @override
  String get rigsInstallHintLabel => 'کیسے انسٹال کریں';

  @override
  String get rigsStarting => 'شروع ہو رہا ہے';

  @override
  String get rigsResidentMemory => 'ریذیڈنٹ میموری';

  @override
  String get installedLabel => 'انسٹال شدہ';

  @override
  String get notInstalledLabel => 'انسٹال نہیں';

  @override
  String ssoOtherKindUnsaved(String method) {
    return '⁨$method⁩ میں غیر محفوظ تبدیلیاں ہیں';
  }

  @override
  String get collapseComment => 'تبصرہ سکیڑیں';

  @override
  String get expandComment => 'تبصرہ پھیلائیں';

  @override
  String get suggestedChange => 'تجویز کردہ تبدیلی';

  @override
  String get emptyComment => 'خالی تبصرہ';

  @override
  String repliesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count جوابات',
      one: '1 جواب',
    );
    return '$_temp0';
  }

  @override
  String diffFileUnresolvedConversations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count غیر حل شدہ گفتگوئیں',
      one: '1 غیر حل شدہ گفتگو',
    );
    return '$_temp0';
  }

  @override
  String get pendingReview => 'زیرِ التوا ریویو';

  @override
  String failedToResolveConversation(String error) {
    return 'گفتگو اپ ڈیٹ نہیں ہو سکی: ⁨$error⁩';
  }

  @override
  String get addSingleComment => 'اکیلا تبصرہ شامل کریں';

  @override
  String get addToReview => 'ریویو میں شامل کریں';

  @override
  String get startAReview => 'ریویو شروع کریں';

  @override
  String get commentModeAgent => 'ایجنٹ';

  @override
  String get commentModeComment => 'تبصرہ';

  @override
  String get commentModeReview => 'ریویو';

  @override
  String get commentDestination => 'تبصرے کی منزل';

  @override
  String get commentHintAgent => 'ایجنٹ کو بھیجیں…';

  @override
  String get commentHintReview => 'ریویو میں شامل کریں…';

  @override
  String get reviewNeedsABody =>
      'پہلے خلاصہ لکھیں یا ان لائن تبصرہ قطار میں رکھیں';

  @override
  String get reviewSubmitted => 'ریویو جمع ہو گیا';

  @override
  String get finishYourReview => 'اپنا ریویو مکمل کریں';

  @override
  String get commentVerdict => 'تبصرہ';

  @override
  String pendingCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count زیرِ التوا تبصرے',
      one: '1 زیرِ التوا تبصرہ',
    );
    return '$_temp0';
  }

  @override
  String andNMore(int count) {
    return 'اور $count مزید';
  }

  @override
  String get queuedCommentHint => 'یہ تبصرہ ریویو جمع کرنے پر جاتا ہے۔';

  @override
  String commentOnLinesRange(int start, int end) {
    return 'لائنیں $start سے $end';
  }

  @override
  String get claudeAccountsTitle => 'Claude Code اکاؤنٹس';

  @override
  String get claudeAccountsDescription =>
      'ہر اکاؤنٹ الگ Claude Code لاگ اِن ہے۔ رنز نیچے منسلک اکاؤنٹس اس ترتیب سے استعمال کرتے ہیں۔';

  @override
  String get claudeAccountsEmpty => 'ابھی کوئی اکاؤنٹ نہیں';

  @override
  String get claudeAccountAdd => 'اکاؤنٹ شامل کریں';

  @override
  String get claudeAccountSignIn => 'سائن اِن';

  @override
  String get claudeAccountSignInAgain => 'دوبارہ سائن اِن';

  @override
  String get claudeAccountSignInHint =>
      'سرور پر ٹرمینل میں یہ چلائیں۔ لاگ اِن مکمل کرنے کے لیے براؤزر کھلتا ہے، اور کریڈینشل اس اکاؤنٹ کی ڈائریکٹری میں لکھتا ہے۔';

  @override
  String get claudeAccountSignedOut => 'سائن آؤٹ';

  @override
  String get claudeAccountExpired => 'سائن اِن ختم';

  @override
  String claudeAccountExpiredDetail(String when) {
    return 'سائن اِن $when پر ختم ہوا۔ اس اکاؤنٹ کے لیے دوبارہ سائن اِن کریں۔';
  }

  @override
  String get claudeAccountMakeDefault => 'ڈیفالٹ بنائیں';

  @override
  String get claudeAccountDefault => 'ڈیفالٹ';

  @override
  String claudeAccountRemoveConfirm(String label) {
    return '⁨$label⁩ ہٹائیں؟';
  }

  @override
  String get claudeAccountRemoveDetail =>
      'اس سے اکاؤنٹ سائن آؤٹ ہوتا ہے اور سرور پر اس کی ڈائریکٹری حذف ہوتی ہے۔ لاگ اِن خود متاثر نہیں۔';

  @override
  String claudeAccountStatusUnknown(String error) {
    return 'یہ اکاؤنٹ چیک نہیں ہو سکا: ⁨$error⁩';
  }

  @override
  String claudeAccountUsedPercent(String percent) {
    return '$percent% استعمال';
  }

  @override
  String get accountPoolStrategy => 'روٹیشن';

  @override
  String get accountPoolPinned => 'پن شدہ';

  @override
  String get accountPoolRoundRobin => 'راؤنڈ رابن';

  @override
  String get accountPoolSerial => 'ایک وقت میں ایک';

  @override
  String get accountPoolPinnedHint =>
      'ہمیشہ پہلے اکاؤنٹ سے شروع کریں۔ ناکام ہونے پر دوسرے فال بیک رہتے ہیں۔';

  @override
  String get accountPoolRoundRobinHint =>
      'رنز اکاؤنٹس پر پھیلائیں، ہر ڈسپیچ اگلے پر جائے۔';

  @override
  String get accountPoolSerialHint =>
      'اگلے کو چھونے سے پہلے پہلا اکاؤنٹ ختم کریں۔';

  @override
  String get accountPoolMoveUp => 'اوپر لے جائیں';

  @override
  String get accountPoolMoveDown => 'نیچے لے جائیں';

  @override
  String get accountPoolUsingAll =>
      'ابھی کچھ منسلک نہیں — ہر اکاؤنٹ اس ترتیب سے استعمال ہوتا ہے۔';

  @override
  String get accountPoolInheriting => 'ورک اسپیس کے اکاؤنٹس وراثت میں۔';

  @override
  String get accountPoolResetToWorkspace => 'ورک اسپیس کے اکاؤنٹس پر ری سیٹ';

  @override
  String accountPoolCoolingOff(String when) {
    return 'کوٹا ختم تا $when';
  }

  @override
  String get accountPoolSignedOut => 'سائن آؤٹ';

  @override
  String get accountPoolExpired => 'سائن اِن ختم';

  @override
  String accountPoolLoadFailed(String error) {
    return 'روٹیشن لوڈ نہیں ہو سکی: ⁨$error⁩';
  }

  @override
  String get providerSignedInAccount => 'سائن اِن اکاؤنٹ';

  @override
  String get agentAccountsTab => 'اکاؤنٹس';

  @override
  String get agentClaudeAccountsNoticeTitle => 'متعدد Claude Code اکاؤنٹس';

  @override
  String agentClaudeAccountsNoticeBody(int count) {
    return 'یہ رنر اس ہوسٹ کے $count Claude Code اکاؤنٹس میں سے ایک کے طور پر سائن اِن کرتا ہے۔ کون سا، یا ان کے درمیان روٹیٹ، اکاؤنٹس ٹیب میں منتخب کریں۔';
  }

  @override
  String get agentAccountsDescription =>
      'اس ایجنٹ کے رنز کون سے اکاؤنٹس استعمال کرتے ہیں۔ ہر بلاک ورک اسپیس کا انتخاب وراثت میں شروع ہوتا ہے۔';

  @override
  String get agentAccountsNothingToRotate =>
      'روٹیٹ کرنے کو کچھ نہیں — پہلے دوسرا اکاؤنٹ یا کلید منسلک کریں۔';

  @override
  String failedToPostReply(String error) {
    return 'جواب پوسٹ نہیں ہو سکا: ⁨$error⁩';
  }

  @override
  String commentOnLine(int line) {
    return 'لائن $line';
  }

  @override
  String get viewInDiff => 'Diff میں دیکھیں';

  @override
  String get subscriptionUsagePreviousAccount => 'پچھلا اکاؤنٹ';

  @override
  String get subscriptionUsageNextAccount => 'اگلا اکاؤنٹ';

  @override
  String inReplyTo(String path) {
    return '⁨$path⁩ کے جواب میں';
  }

  @override
  String get subscriptionUsageNoneReported =>
      'اس اکاؤنٹ کا کوئی استعمال رپورٹ نہیں۔';

  @override
  String get subscriptionUsageCredits => 'کریڈٹس';

  @override
  String get reviewHubStaticRule => 'جامد قاعدہ';

  @override
  String get reviewHubStarted => 'ریویو شروع ہوا';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return 'اس pull request کی شامل لائن پر تعیناتی قاعدے (⁨$rule⁩) سے ملا — ریویوور ایجنٹ سے نہیں۔';
  }

  @override
  String get prReviewArtifactTab => 'PR ریویو';

  @override
  String get prReviewRunning => 'اس pull request کا ریویو ہو رہا ہے…';

  @override
  String get prReviewStarting => 'ریویو شروع ہو رہا ہے…';

  @override
  String get prReviewStartingBody =>
      'اس pull request کا worktree تیار ہو رہا ہے۔ تیار ہوتے ہی ریویوورز شروع ہوتے ہیں۔';

  @override
  String get prReviewFailed => 'ریویو ناکام۔';

  @override
  String get prReviewRerunning => 'دوبارہ ریویو…';

  @override
  String get prReviewNoOpenFindings => 'کوئی کھلا نتیجہ نہیں';

  @override
  String prReviewOpenFindings(int count) {
    return '$count کھلے نتائج';
  }

  @override
  String subscriptionUsageSpend(String used, String limit) {
    return '$used از $limit';
  }

  @override
  String reviewCommentsPosted(int posted, int skipped, int failed) {
    return 'بوٹ کے طور پر $posted تبصرہ(ے) پوسٹ ہوئے۔ $skipped چھوڑے گئے (کوئی فائل اینکر نہیں)، $failed ناکام۔';
  }

  @override
  String reviewFindingsOutOfDiff(int count, String files) {
    return '$count نتیجہ(نتائج) ایسے کوڈ کی طرف ہیں جو یہ pull request نہیں بدلتا (⁨$files⁩)۔ GitHub صرف diff پر ان لائن تبصرے قبول کرتا ہے۔';
  }

  @override
  String get reviewRailReport => 'رپورٹ';

  @override
  String get reviewNoFindingsTitle => 'ابھی کوئی ریویو نتائج نہیں';

  @override
  String get reviewNoFindingsHint =>
      'ایجنٹس پوسٹ کرتے ہی نتائج یہاں نظر آتے ہیں۔';

  @override
  String reviewShowDismissed(int count) {
    return '$count برطرف دکھائیں';
  }

  @override
  String reviewHideDismissed(int count) {
    return '$count برطرف چھپائیں';
  }

  @override
  String reviewDisagreementsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ریویوور اختلاف ملے',
      one: '1 ریویوور اختلاف ملا',
    );
    return '$_temp0';
  }

  @override
  String get reviewFilterKind => 'قسم';

  @override
  String get reviewFilterStatus => 'اسٹیٹس';

  @override
  String get reviewKindBug => 'بگ';

  @override
  String get reviewKindSuggestion => 'تجویز';

  @override
  String get reviewKindRecommendation => 'سفارش';

  @override
  String get reviewKindQuestion => 'سوال';

  @override
  String get reviewKindTicket => 'ٹکٹ';

  @override
  String get spaceAllPrsMerged =>
      'اس اسپیس کی تمام پل ریکویسٹیں ضم ہو چکی ہیں۔ کیا اس اسپیس کو آرکائیو کریں؟';

  @override
  String get spaceKeepAfterMerge => 'نہیں، یہ اسپیس برقرار رکھیں';

  @override
  String get spaceKeepAfterMergeHint =>
      'اس اسپیس کے بارے میں دوبارہ نہیں پوچھا جائے گا۔';

  @override
  String get archiveSpace => 'اسپیس آرکائیو کریں';

  @override
  String get archivedSpaces => 'آرکائیو اسپیسز';

  @override
  String get archivedSpacesEmpty => 'کوئی آرکائیو اسپیس نہیں';

  @override
  String get restoreSpace => 'بحال کریں';

  @override
  String get archivedConversations => 'آرکائیو گفتگوئیں';

  @override
  String get archivedConversationsEmpty => 'کوئی آرکائیو گفتگو نہیں';

  @override
  String get restoreConversation => 'بحال کریں';

  @override
  String archivedWhen(String time) {
    return '$time آرکائیو ہوئی';
  }

  @override
  String get deleteSpacePermanently => 'مستقل حذف کریں';

  @override
  String get renameSpace => 'اسپیس کا نام بدلیں';

  @override
  String get renameConversation => 'گفتگو کا نام بدلیں';

  @override
  String get spaceActions => 'اسپیس کے اعمال';

  @override
  String get conversationActions => 'گفتگو کے اعمال';

  @override
  String get editSpaceRepos => 'ریپوزٹریز میں ترمیم';

  @override
  String get editSpaceReposTitle => 'اسپیس ریپوزٹریز';

  @override
  String get editSpaceReposWarning =>
      'ریپوزٹری شامل کرنا اسے اس اسپیس میں چیک آؤٹ کرتا ہے؛ ہٹانا اس کا فولڈر حذف کرتا ہے۔';

  @override
  String get agentSectionIdentity => 'شناخت';

  @override
  String get agentSectionRuntime => 'رن ٹائم';

  @override
  String get agentSectionGuardrails => 'گارڈریلز';

  @override
  String orgChartReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رپورٹس',
      one: '1 رپورٹ',
    );
    return '$_temp0';
  }

  @override
  String get teamsFilterHint => 'ٹیمز فلٹر کریں…';

  @override
  String get teamsSummaryWithLeader => 'لیڈر کے ساتھ';

  @override
  String teamCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ٹیمز',
      one: '1 ٹیم',
      zero: 'کوئی ٹیم نہیں',
    );
    return '$_temp0';
  }

  @override
  String agentDeleteLongDescription(String name) {
    return '⁨$name⁩ حذف کرنے سے اس کا پروفائل، مہارت لنکس اور رن ہسٹری ہٹ جاتی ہے۔ یہ واپس نہیں ہو سکتا۔';
  }

  @override
  String get resetToDefault => 'ڈیفالٹ پر ری سیٹ';

  @override
  String get newAgent => 'نیا ایجنٹ';

  @override
  String get newSkill => 'نئی مہارت';

  @override
  String get newItemAction => 'نیا';

  @override
  String get zoomIn => 'زوم اِن';

  @override
  String get zoomOut => 'زوم آؤٹ';

  @override
  String get resetZoom => 'زوم ری سیٹ';

  @override
  String get imageHostedOnGitHub => 'تصویر GitHub پر ہوسٹ';

  @override
  String get imageOpenExternally => 'تصویر · باہر کھولیں';

  @override
  String get memoryScopeAll => 'تمام دائرے';

  @override
  String get memoryScopeWorkspace => 'پورے ورک اسپیس';

  @override
  String get memoryScopeFilterLabel => 'دائرے سے فلٹر';

  @override
  String memoryScopeRepoTooltip(String repo) {
    return '⁨$repo⁩ ریپوزٹری تک محدود';
  }

  @override
  String get toolScreenshot => 'ایجنٹ سے اسکرین شاٹ';

  @override
  String get toolImageUnavailable => 'تصویر دستیاب نہیں';

  @override
  String toolImagesUnavailable(int count) {
    return '$count تصاویر دستیاب نہیں';
  }

  @override
  String get shakeUnavailable => 'اس سرور پر شیک دستیاب نہیں';

  @override
  String get shakeNothing => 'نکالنے کو کچھ نہیں — حالیہ باریاں محفوظ ہیں';

  @override
  String shakeDone(int tokens) {
    return 'تقریباً $tokens ٹوکنز خالی ہوئے';
  }

  @override
  String get compactionDivider => 'کمپیکٹ';

  @override
  String compactionDividerCount(int count) {
    return 'کمپیکٹ · $count پیغامات سمیٹے گئے';
  }

  @override
  String get composerDropToAttach => 'منسلک کرنے کے لیے چھوڑیں';

  @override
  String get composerAttachmentUploading => 'اپ لوڈ ہو رہا ہے…';

  @override
  String get composerAttachmentReady => 'تیار';

  @override
  String get composerAttachmentUploadFailed => 'اپ لوڈ ناکام ہو گیا';

  @override
  String composerAttachmentTooLarge(String limit) {
    return 'فائل کا حجم $limit کی حد سے زیادہ ہے';
  }

  @override
  String get composerAttachmentUnreadable => 'یہ فائل پڑھی نہیں جا سکی';

  @override
  String get composerAttachmentWaitForUploads =>
      'منسلکات کا اپ لوڈ مکمل ہونے کا انتظار کریں';

  @override
  String get composerAttachmentResolveFailures =>
      'بھیجنے سے پہلے ناکام منسلکات دوبارہ اپ لوڈ کریں یا ہٹا دیں';

  @override
  String get attachmentUnavailable => 'منسلکہ دستیاب نہیں';

  @override
  String get attachmentUnavailableDetail =>
      'یہ منسلکہ اب میموری میں نہیں۔ پیش منظر کے لیے دوبارہ منسلک کریں۔';

  @override
  String get attachmentPreviewFailed => 'یہ فائل نہیں کھل سکی';

  @override
  String get attachmentPreviewUnsupported => 'اس فائل قسم کا پیش منظر نہیں';

  @override
  String get attachmentTooLargeToPreview => 'پیش منظر کے لیے بہت بڑی';

  @override
  String get attachmentOpenExternally => 'ڈیفالٹ ایپ میں کھولیں';

  @override
  String get asideEmpty => 'ابھی کام کرنے کو کچھ نہیں';

  @override
  String get asideFailed => 'جواب نہیں مل سکا';

  @override
  String get handoffTitle => 'ہینڈ آف';

  @override
  String get asideTitle => 'ضمنی سوال';

  @override
  String get attachFilesOrDrop => 'فائلیں منسلک کریں — یا یہاں چھوڑیں';

  @override
  String composerExpand(String shortcut) {
    return 'ایڈیٹر پھیلائیں ($shortcut)';
  }

  @override
  String composerCollapse(String shortcut) {
    return 'ایڈیٹر سمیٹیں ($shortcut)';
  }

  @override
  String get guidedGoalTitle => 'مقصد تیز کریں';

  @override
  String get guidedGoalIntro =>
      'بغیر نگرانی کام کرنے والے ایجنٹ کو بالکل معلوم ہونا چاہیے کہ کب کام مکمل ہے۔ پہلے چند سوالات۔';

  @override
  String get guidedGoalAnswerHint => 'آپ کا جواب';

  @override
  String get guidedGoalNext => 'اگلا';

  @override
  String get guidedGoalStart => 'ہدف شروع کریں';

  @override
  String get guidedGoalSkip => 'چھوڑیں اور جیسا لکھا ہے چلائیں';

  @override
  String guidedGoalStillMissing(String items) {
    return 'ابھی غیر معین: ⁨$items⁩';
  }

  @override
  String get conversationTreeTitle => 'گفتگو کا درخت';

  @override
  String conversationTreeBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count برانچز',
      one: '1 برانچ',
    );
    return '$_temp0';
  }

  @override
  String get conversationTreeSwitch => 'یہاں سے جاری رکھیں';

  @override
  String get conversationTreeFork => 'نئی گفتگو میں فورک کریں';

  @override
  String get conversationTreeCurrent => 'اس برانچ پر';

  @override
  String get conversationTreeEmpty => 'ابھی یہاں کچھ نہیں';

  @override
  String get conversationTreeForked => 'نئی گفتگو میں فورک ہو گیا';

  @override
  String get conversationTreeSwitched => 'اب اس پیغام سے جاری';

  @override
  String exportSaved(String path) {
    return '⁨$path⁩ پر محفوظ';
  }

  @override
  String get exportFailed => 'برآمد نہیں لکھا جا سکا';

  @override
  String get contextCommandNoAgent =>
      'اس گفتگو میں کوئی ایجنٹ نہیں، اس لیے کھولنے کے لیے سیاق ونڈو نہیں';

  @override
  String contextCommandNoSuchAgent(String name, String names) {
    return 'اس گفتگو میں \"⁨$name⁩\" نام کا کوئی ایجنٹ نہیں۔ آزمائیں: ⁨$names⁩';
  }

  @override
  String get dumpCopied => 'ٹرانسکرپٹ کلپ بورڈ پر کاپی ہو گیا';

  @override
  String get messageQueueHint =>
      'فالو اپ تبدیلیاں قطار میں رکھنے کے لیے ٹائپ کرتے رہیں';

  @override
  String get steerNow => 'اسٹیئر';

  @override
  String get steerForce => 'روکیں اور بھیجیں';

  @override
  String get steeringQueueLabel => 'قطار میں اسٹیئرنگ پیغامات';

  @override
  String get steeringDeliverUnavailable =>
      'ابھی کوئی چلتا ایجنٹ اسے نہیں لے سکتا — قطار میں رہتا ہے۔';

  @override
  String get reorderSteeringCard => 'قطار پیغام کی ترتیب بدلیں';

  @override
  String get editSteeringCard => 'قطار پیغام میں ترمیم';

  @override
  String get deleteSteeringCard => 'قطار پیغام حذف کریں';

  @override
  String get steeringBadge => 'اسٹیئرڈ';

  @override
  String get settingsSandboxLabel => 'سینڈ باکس';

  @override
  String get sandboxExecGrantsTitle => 'ایگزیکیوٹیبل گرانٹس';

  @override
  String get sandboxExecGrantsSubtitle =>
      'پروگرام جو ایجنٹس آپ کی ریپوزٹریز کی اپنی کاپی سے چلا سکتے ہیں۔ ہر اندراج سینڈ باکس کے پوچھنے پر آپ نے منظور کیا۔';

  @override
  String get sandboxExecGrantsEmpty =>
      'ابھی کوئی فیصلہ ریکارڈ نہیں۔ پہلی بار ایجنٹ اپنی کاپی سے پروگرام چلانا چاہے تو پوچھا جائے گا۔';

  @override
  String get sandboxExecGrantRevoke => 'منسوخ کریں';

  @override
  String get sandboxExecGrantAllowed => 'اجازت';

  @override
  String get sandboxExecGrantBlocked => 'بلاک';

  @override
  String get sandboxExecGrantRevokeConfirmTitle => 'یہ فیصلہ منسوخ کریں؟';

  @override
  String get sandboxExecGrantRevokeConfirmBody =>
      'اگلی بار ایجنٹ اس کاپی سے پروگرام چلانا چاہے تو دوبارہ پوچھا جائے گا۔';

  @override
  String get sandboxExecGrantsSearchHint => 'راستے تلاش کریں';

  @override
  String get sandboxExecGrantsNoMatch => 'آپ کی تلاش سے کوئی گرانٹ مماثل نہیں';

  @override
  String get demoBadgeLabel => 'ڈیمو';

  @override
  String get demoFilePickerTitle => 'ڈیمو فائلیں';

  @override
  String get demoFilePickerBody =>
      'ڈیمو اپ لوڈ جعلی کرتا ہے: ان میں سے کوئی منتخب کریں اور وہ ڈسک چھوئے بغیر پیغام سے منسلک ہو جاتی ہے۔';

  @override
  String get demoFilePickerAttach => 'منسلک کریں';

  @override
  String get demoReadOnlySave => 'ڈیمو میں صرف پڑھنے کے لیے';

  @override
  String get demoBadgeTooltip =>
      'آپ ڈیمو دیکھ رہے ہیں۔ ڈیٹا فرضی ہے اور ایجنٹس اسکرپٹ شدہ ہیں۔';

  @override
  String get demoFirstRunTitle => 'آپ لائیو ڈیمو میں ہیں';

  @override
  String demoFirstRunBody(int minutes) {
    return 'یہ اصل ایپ اصل کوڈ پر چل رہی ہے — صرف ڈیٹا ایجاد کردہ ہے۔ ایجنٹس اسکرپٹ سے حقیقی رنز اسٹریم کرتے ہیں، اس لیے ماڈل تک کچھ نہیں جاتا اور مشین پر کچھ نہیں چلتا۔ آپ کا ورک اسپیس صرف آپ کا ہے اور $minutes منٹ بعد غائب ہو جاتا ہے۔';
  }

  @override
  String get demoFirstRunDismiss => 'سمجھ گیا';

  @override
  String get demoTourTitle => 'پہلے کہاں دیکھیں';

  @override
  String get demoTourSubtitle =>
      'چار جگہیں جو دکھاتی ہیں کہ ایپ اصل میں کیا کرتی ہے۔';

  @override
  String get demoTourSkip => 'چھوڑیں';

  @override
  String get demoTourStarRepo => 'GitHub پر اسٹار';

  @override
  String get demoTourOpen => 'کھولیں';

  @override
  String get demoTourSpacesTitle => 'ایجنٹ سے بات کریں';

  @override
  String get demoTourSpacesBody =>
      'اسپیس میں پیغام بھیجیں اور رن اسٹریم دیکھیں — سوچ، ٹول کالز اور لاگت، بالکل جیسے حقیقی رن۔';

  @override
  String get demoTourReviewTitle => 'pull request کا ریویو';

  @override
  String get demoTourReviewBody =>
      '⁨#412⁩ کھولیں۔ ان لائن تبصرہ لکھیں یا ریویو جمع کریں؛ آپ کے الفاظ تھریڈ میں رہتے ہیں۔';

  @override
  String get demoTourTicketsTitle => 'کام کی پیروی';

  @override
  String get demoTourTicketsBody =>
      'ٹکٹس، todos اور پلانز انہی گفتگوؤں سے جڑے ہیں جو ایجنٹس کر رہے ہیں۔';

  @override
  String get demoTourInboxTitle => 'پوری کارروائی دیکھیں';

  @override
  String get demoTourInboxBody =>
      'ہر ستون کی ہر الرٹ ایک ان باکس میں آتی ہے — ریویوز، ٹکٹس، رنز اور میٹنگز۔';

  @override
  String get demoUnavailableTitle => 'ڈیمو میں دستیاب نہیں';

  @override
  String get demoUnavailableTerminal =>
      'ٹرمینل سرور ہوسٹ پر حقیقی شیل چلاتا ہے۔ ڈیمو کا کوئی عمل درآمد سطح نہیں — اسی لیے عوام کے لیے کھولنا محفوظ ہے۔';

  @override
  String get demoUnavailableRig =>
      'انکلوژر عارضی ورچوئل مشین ہے جو ایجنٹ چلاتا ہے۔ ڈیمو کوئی نہیں بوٹ کرتا: جو پبلک اینڈ پوائنٹ VM شروع کر سکے وہ ڈیمو نہیں۔';

  @override
  String get demoUnavailableEditor =>
      'ان براؤزر ایڈیٹر حقیقی چیک آؤٹ کے خلاف code-server پراسیس چلاتا ہے۔ ڈیمو کے پاس دونوں نہیں۔';

  @override
  String get demoUnavailableFeeds =>
      'ڈیمو حقیقی فیڈز پڑھتا ہے، مگر اس کی سبسکرپشن فہرست مقرر ہے۔ یہاں شامل یا ہٹانا بند ہے۔';

  @override
  String get demoUnavailableForge =>
      'ڈیمو کوئی کریڈینشل نہیں رکھتا اور GitHub، GitLab یا Linear سے کبھی رابطہ نہیں کرتا۔ اس کے pull requests فکسچر ہیں، اور آپ کے تبصرے مقامی محفوظ ہوتے ہیں۔';

  @override
  String get demoUnavailableModels =>
      'ڈیمو کوئی ماڈل کال نہیں کرتا۔ ایجنٹ رنز اسکرپٹ پلے بیک ہیں، اس لیے لاگت صفر اور کوئی فراہم کنندہ نہیں۔';

  @override
  String get demoUnavailableMcp =>
      'ڈیمو پر MCP ٹول سطح نہیں لگی، اس لیے کوئی بیرونی کلائنٹ نہیں جڑ سکتا۔';

  @override
  String get demoUnavailableRepos =>
      'ڈیمو کوئی کوڈ چیک آؤٹ نہیں کرتا اور git نہیں چلاتا۔ جو ریپوزٹری آپ دیکھتے ہیں وہ pull requests کے پیچھے فکسچر ہے۔';

  @override
  String get demoUnavailableSkills =>
      'مہارت انسٹال کرنا کوڈ ڈاؤن لوڈ اور اسکین کرتا ہے۔ ڈیمو کچھ نہیں لاتا۔';

  @override
  String get demoUnavailableSso =>
      'سنگل سائن آن سرور کنفیگریشن ہے۔ ڈیمو آپ کو عارضی مہمان کے طور پر سائن اِن کرتا ہے۔';

  @override
  String get demoUnavailableAudio =>
      'ریکارڈنگ اور ڈکٹیشن کو آڈیو کیپچر اور ہوسٹ پر اسپیچ ماڈل چاہیے۔ ڈیمو دونوں نہیں بھیجتا، اس لیے اس کی میٹنگز بغیر پلے بیک کی ٹرانسکرپٹس ہیں۔';

  @override
  String get demoUnavailableServerAdmin =>
      'یہ سرور انتظامیہ ہے۔ ڈیمو ہر زائر کو اپنا عارضی ورک اسپیس دیتا ہے اور اس سے آگے کچھ نہیں۔';

  @override
  String get demoUnavailablePipelines =>
      'پائپ لائنز یہاں نہیں چل سکتیں۔ ایک زائر جو bash قدم لکھ کر — ہاتھ سے یا ایونٹ ٹرگر کے ذریعے — شروع کر سکتا ہے، اس میزبان پر کوڈ چلا رہا ہے۔';

  @override
  String get settingsBackupRestore => 'بیک اپ اور بحالی';

  @override
  String get settingsBackupRestoreDescription =>
      'اس سرور کے ہر ڈیٹا بیس کے اسنیپ شاٹس، نیز ایک ورک اسپیس کا برآمد، درآمد اور حذف۔';

  @override
  String get backupSnapshotsLabel => 'انسٹال اسنیپ شاٹس';

  @override
  String get backupSnapshotsExplainer =>
      'اسنیپ شاٹ ہر ڈیٹا بیس کو سرور ہوسٹ پر ٹائم سٹیمپ فولڈر میں کاپی کرتا ہے۔ پورا انسٹال بحال کرنے کا مطلب سرور بند کر کے وہ فولڈر واپس کاپی کرنا ہے؛ ایک ورک اسپیس یہاں سے بحال ہو سکتا ہے۔';

  @override
  String get backupNowAction => 'اب بیک اپ لیں';

  @override
  String backupSnapshotWritten(String path) {
    return 'اسنیپ شاٹ ⁨$path⁩ پر لکھا گیا';
  }

  @override
  String get backupNoSnapshots =>
      'ابھی تنصیب کا کوئی اسنیپ شاٹ نہیں۔ ابھی بنائیں یا ورک اسپیس کے طے شدہ بیک اپ کے لیے پائپ لائن استعمال کریں۔';

  @override
  String get backupSnapshotComplete => 'مکمل';

  @override
  String get backupDeleteSnapshotLabel => 'اسنیپ شاٹ حذف کریں';

  @override
  String get backupDeleteSnapshotDescription =>
      'اس اسنیپ شاٹ کو سرور سے مستقل طور پر ہٹا دیں۔ محفوظ رکھنا ہو تو پہلے ڈاؤن لوڈ کریں۔';

  @override
  String get backupDeleteSnapshotAction => 'اسنیپ شاٹ حذف کریں';

  @override
  String get backupDeleteSnapshotTitle => 'یہ اسنیپ شاٹ حذف کریں؟';

  @override
  String backupDeleteSnapshotBody(String name) {
    return 'سرور سے ⁨$name⁩ حذف کریں؟ اس میں موجود تمام ڈیٹابیس ضائع ہو جائیں گے۔ اسے واپس نہیں لایا جا سکتا۔';
  }

  @override
  String backupDeleteSnapshotDone(String name) {
    return 'اسنیپ شاٹ ⁨$name⁩ حذف ہو گیا۔';
  }

  @override
  String backupSnapshotWorkspaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ورک اسپیسز',
      one: '1 ورک اسپیس',
      zero: 'کوئی ورک اسپیس نہیں',
    );
    return '$_temp0';
  }

  @override
  String backupSnapshotSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ورک اسپیسز کیپچر نہیں ہوئے',
      one: '1 ورک اسپیس کیپچر نہیں ہوا',
    );
    return '$_temp0';
  }

  @override
  String get backupServerPathLabel => 'سرور پر پاتھ';

  @override
  String get backupScheduledLabel => 'طے شدہ بیک اپ';

  @override
  String get backupScheduledExplainer =>
      'ہر ورک اسپیس کی بیک اپ پائپ لائن کی محفوظ کردہ نقول۔ شیڈول اور برقرار رکھنے کی مدت پائپ لائن کے ٹیمپلیٹ میں طے کریں۔';

  @override
  String get backupScheduledNone => 'ابھی کوئی بیک اپ نہیں';

  @override
  String backupScheduledCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بیک اپ',
      one: '1 بیک اپ',
    );
    return '$_temp0';
  }

  @override
  String backupScheduledLast(String time) {
    return 'آخری بیک اپ: $time';
  }

  @override
  String get backupListForbidden =>
      'اس ورک اسپیس کے بیک اپ دیکھنے کے لیے آپ کو ایڈمن کردار درکار ہے۔';

  @override
  String get backupScheduledDeleteTitle => 'یہ بیک اپ حذف کریں؟';

  @override
  String backupScheduledDeleteBody(String date, String name) {
    return '$name کا $date کا بیک اپ سرور سے حذف کریں؟ اسے واپس نہیں کیا جا سکتا۔';
  }

  @override
  String get backupScheduledDeleteDone => 'بیک اپ حذف ہو گیا۔';

  @override
  String get backupScheduledWorkspaceDeleted => 'ورک اسپیس حذف شدہ';

  @override
  String get backupRestoreAction => 'بحال کریں';

  @override
  String get backupRestoreTitle => 'ورک اسپیس بحال کریں';

  @override
  String backupRestoreBody(String name) {
    return 'اس سے ⁨$name⁩ میں سب کچھ اس اسنیپ شاٹ کی کاپی سے بدل جاتا ہے۔ اسنیپ شاٹ کے بعد اس ورک اسپیس نے جو کیا وہ ضائع ہوتا ہے، اور واپس نہیں ہو سکتا۔';
  }

  @override
  String backupRestoreDone(String name) {
    return '⁨$name⁩ اسنیپ شاٹ سے بحال ہو گیا۔';
  }

  @override
  String get backupWorkspaceUnknown => 'اب اس سرور پر نہیں';

  @override
  String get backupWorkspaceDataLabel => 'ورک اسپیس ڈیٹا';

  @override
  String get backupWorkspaceDataExplainer =>
      'ایک ورک اسپیس ایک ڈیٹا بیس فائل ہے، اس لیے برآمد اسے ٹیبل بہ ٹیبل ڈمپ کی بجائے کاپی کرتا ہے۔ درآمد ٹارگٹ ورک اسپیس میں سب کچھ آپ کی نامزد فائل سے بدل دیتا ہے۔';

  @override
  String get backupExportAction => 'برآمد';

  @override
  String backupExportDone(String path) {
    return '⁨$path⁩ پر برآمد ہوا';
  }

  @override
  String get backupExportedFileLabel => 'سرور پر برآمد شدہ فائل';

  @override
  String get backupImportAction => 'درآمد';

  @override
  String backupImportTitle(String name) {
    return '⁨$name⁩ میں درآمد';
  }

  @override
  String backupImportBody(String name) {
    return 'اس سے ⁨$name⁩ میں سب کچھ فائل کے مواد سے بدل جاتا ہے۔ جو اب اس ورک اسپیس میں ہے وہ ضائع ہوتا ہے، اور واپس نہیں ہو سکتا۔';
  }

  @override
  String get backupImportSourceLabel => 'ورک اسپیس ڈیٹا بیس فائل';

  @override
  String get backupImportSourceDescription =>
      'ایک .db فائل جو سرور پڑھ سکے۔ پاتھ اس ڈیوائس پر نہیں، سرور ہوسٹ پر حل ہوتے ہیں۔';

  @override
  String backupImportDone(String name) {
    return '⁨$name⁩ میں درآمد ہو گیا۔';
  }

  @override
  String backupDeleteBody(String name) {
    return '⁨$name⁩ ہر فہرست اور تلاش سے غائب ہو جاتا ہے۔ اس کی ڈیٹا بیس فائل ڈسک پر رہتی ہے، بیک اپس میں شامل رہتی ہے، اور جگہ خود واپس نہیں ہوتی۔';
  }

  @override
  String get backupExportDescription =>
      'سرور پر کاپی لکھیں، یا اس ڈیوائس پر ڈاؤن لوڈ کریں۔';

  @override
  String get backupExportOnServerAction => 'سرور پر محفوظ کریں';

  @override
  String get backupDownloadAction => 'ڈاؤن لوڈ';

  @override
  String backupDownloadSaved(String path) {
    return '⁨$path⁩ پر محفوظ';
  }

  @override
  String get backupDownloadInBrowser => 'آپ کا براؤزر اسے ڈاؤن لوڈ کر رہا ہے۔';

  @override
  String get backupRestoreFromDeviceLabel => 'اس ڈیوائس سے بحال کریں';

  @override
  String get backupRestoreFromDeviceDescription =>
      'یہاں ورک اسپیس ڈیٹا بیس فائل منتخب کریں اور Control Center اسے سرور پر اپ لوڈ کرتا ہے۔ یہ تب کام کرتا ہے جب سرور یہ مشین نہ ہو۔';

  @override
  String get backupUploadAction => 'فائل منتخب کریں اور اپ لوڈ کریں';

  @override
  String get backupTransferUnavailable =>
      'اس کنکشن کے لیے فائل ٹرانسفر ابھی ترتیب نہیں دی گئی۔ بیک اپ ڈاؤن لوڈ یا اپ لوڈ کرنے کے لیے سرور سے دوبارہ منسلک ہوں۔';

  @override
  String get backupTransferForbidden =>
      'سرور نے انکار کیا۔ ورک اسپیس ڈاؤن لوڈ کرنے کے لیے ایڈمن کردار درکار ہے۔ اسے بحال کرنے کے لیے سرور کا مالک درکار ہے، جو اس ورک اسپیس کا مالک بھی ہو۔ پورے اسنیپ شاٹ کے لیے سرور کا مالک درکار ہے۔';

  @override
  String get backupTransferUnsupported => 'اس سرور پر بیک اپ سطح نہیں۔';

  @override
  String get backupTransferTooLarge => 'فائل سرور کی قبول حد سے بڑی ہے۔';

  @override
  String get credentialGateWaitingTitle => 'کریڈینشل کا انتظار';

  @override
  String credentialGateHarnessTitle(String provider) {
    return '⁨$provider⁩ کا کوئی کریڈینشل نہیں';
  }

  @override
  String get credentialGateSignedOutTitle => 'Claude Code سائن آؤٹ ہے';

  @override
  String get credentialGateExpiredTitle =>
      'آپ کا Claude Code سائن اِن ختم ہو گیا';

  @override
  String get credentialGatePlanSpentTitle => 'Claude Code پلان کی حد پوری';

  @override
  String credentialGateWaitingAgent(String agent) {
    return '⁨$agent⁩ جاری رکھنے کا انتظار کر رہا ہے۔';
  }

  @override
  String get credentialGateWaitingRun =>
      'ایک رن جاری رکھنے کا انتظار کر رہا ہے۔';

  @override
  String get credentialGateWatching =>
      'درستگی دیکھ رہا ہے — رن خود جاری رہتا ہے۔';

  @override
  String credentialGateFreesUpAt(String time) {
    return '$time پر خالی ہوتا ہے';
  }

  @override
  String credentialGateGivesUpAt(String time) {
    return 'رن $time پر چھوڑ دیتا ہے';
  }

  @override
  String get credentialGateCheckAgain => 'دوبارہ چیک کریں';

  @override
  String get credentialGateCancelRun => 'رن منسوخ کریں';

  @override
  String get credentialGateAccountsTried => 'آزمائے گئے اکاؤنٹس';

  @override
  String get credentialGateClaudeSignInHint =>
      'ترتیبات ← اڈاپٹرز ← Claude Code سے سائن اِن کریں، یا ٹرمینل میں لاگ اِن کمانڈ چلائیں۔ رن اسے خود پکڑ لیتا ہے۔';

  @override
  String get credentialGateOpenSettings => 'ترتیبات کھولیں';

  @override
  String get credentialGateAccountsRemovedTitle =>
      'منسلک Claude Code اکاؤنٹس ہٹا دیے گئے';

  @override
  String get credentialGateAccountsRemovedHint =>
      'اس ایجنٹ یا ورک اسپیس کی اکاؤنٹ ترتیبات میں کوئی دوسرا اکاؤنٹ منسلک کریں، یا ڈیفالٹ استعمال کرنے کے لیے فہرست صاف کریں۔ رن خود بخود جاری ہو جائے گا۔';

  @override
  String get accountPoolAllRemoved =>
      'اس فہرست کے تمام اکاؤنٹس سرور سے ہٹا دیے گئے ہیں۔ کوئی دوسرا منسلک کریں، یا فہرست صاف کریں۔';

  @override
  String get accountPoolClear => 'فہرست صاف کریں';

  @override
  String get selectModel => 'ماڈل منتخب کریں';

  @override
  String get allModels => 'تمام ماڈلز';

  @override
  String get noModelsMatchSearch => 'آپ کی تلاش سے کوئی ماڈل مماثل نہیں';

  @override
  String useCustomModelId(String id) {
    return '“$id” استعمال کریں';
  }

  @override
  String get modelFree => 'مفت';

  @override
  String modelOutputTokens(String tokens) {
    return '$tokens آؤٹ پٹ';
  }

  @override
  String modelPricePerMTokens(String input, String output) {
    return 'فی 1M ٹوکن $input ان پٹ / $output آؤٹ پٹ';
  }

  @override
  String modelEffortLevels(String levels) {
    return 'ریزننگ کا زور: $levels';
  }

  @override
  String get modelSupportsReasoning => 'ریزننگ کے زور کی معاونت کرتا ہے';

  @override
  String get profileDeliveryMetrics => 'ڈیلیوری میٹرکس';

  @override
  String profileMetricsSample(int count) {
    return 'تجزیہ شدہ PRs: $count';
  }

  @override
  String get profileMergeRate => 'ضم ہونے کی شرح';

  @override
  String get profileReviewCoverage => 'جائزے کی کوریج';

  @override
  String get profilePrSize => 'PR کا سائز';

  @override
  String get profileTimeToMerge => 'ضم ہونے تک کا وقت';

  @override
  String get profileMergeTimeTrend => 'ضم ہونے کے وقت کا رجحان';

  @override
  String get profileWeeklyMedian => 'ہفتہ وار میڈین، لوگارتھمک پیمانہ';

  @override
  String get profilePrOpeningPattern => 'ہفتے کا دن × گھنٹہ، مقامی وقت';

  @override
  String get profileFirstReview => 'پہلے جائزے تک کا وقت';

  @override
  String get profileMetricsTruncated =>
      'فی صد درجات دستیاب پُل ریکوئسٹس کے ایک محدود نمونے پر مبنی ہیں۔';

  @override
  String profileLinesChanged(String count) {
    return '$count لائنیں';
  }

  @override
  String profileDurationMinutes(int count) {
    return '$count منٹ';
  }

  @override
  String profileDurationHours(int count) {
    return '$count گھنٹے';
  }

  @override
  String profileDurationDaysHours(int days, int hours) {
    return '$days دن $hours گھنٹے';
  }

  @override
  String profilePercentiles(String median, String p90) {
    return 'p50 $median · p90 $p90';
  }

  @override
  String profileTeamMembers(int count) {
    return 'اراکین: $count';
  }

  @override
  String noPrsByTeamInWorkspace(String team) {
    return 'اس ورک اسپیس میں $team کی کوئی پل ریکویسٹ نہیں ہے';
  }

  @override
  String get profilePrStateFilterLabel =>
      'پل ریکویسٹس کو حالت کے لحاظ سے فلٹر کریں';

  @override
  String get noProfilePrsMatchSearchHint =>
      'کوئی اور عنوان یا پل ریکویسٹ نمبر آزمائیں';

  @override
  String get rigNetworkUnrestricted => 'نیٹ ورک پر کوئی پابندی نہیں';

  @override
  String get rigNetworkAllowAllHosts => 'تمام میزبانوں کی اجازت دیں';

  @override
  String get rigBrowserPermissionsTitle => 'سائٹ کی اجازتیں';

  @override
  String get rigBrowserPermissionsTooltip => 'سائٹ کی اجازتیں اور نیٹ ورک';

  @override
  String get rigBrowserPermissionEmpty => 'ابھی کسی سائٹ نے اجازت نہیں مانگی';

  @override
  String rigBrowserPermissionPrompt(String origin, String permission) {
    return '$origin $permission استعمال کرنا چاہتا ہے';
  }

  @override
  String get rigBrowserPermissionBlock => 'روکیں';

  @override
  String get rigBrowserPermissionCamera => 'کیمرہ';

  @override
  String get rigBrowserPermissionMicrophone => 'مائیکروفون';

  @override
  String get rigBrowserPermissionNotifications => 'اطلاعات';

  @override
  String get rigBrowserPermissionGeolocation => 'مقام';

  @override
  String get rigBrowserPermissionPersistentStorage => 'مستقل ذخیرہ';

  @override
  String get rigBrowserPermissionClipboard => 'کلپ بورڈ';

  @override
  String get rigBrowserPermissionDisplayCapture => 'اسکرین کیپچر';

  @override
  String get rigBrowserPermissionMidi => 'MIDI';

  @override
  String get rigNetworkBypassTitle => 'کیا ہر نیٹ ورک میزبان کی اجازت دینی ہے؟';

  @override
  String get rigNetworkBypassBody =>
      'اس سے الگ تھلگ ماحول دوبارہ شروع ہو گا اور اس کے اندر غیر کمیٹ شدہ کام ضائع ہو جائے گا۔ اس کے بعد مہمان بند ہونے تک کسی بھی نیٹ ورک میزبان تک رسائی حاصل کر سکے گا۔';

  @override
  String get rigNetworkRestartUnrestricted => 'بغیر پابندی دوبارہ شروع کریں';

  @override
  String get rigNetworkUnrestrictedBody =>
      'یہ الگ تھلگ ماحول ہر نیٹ ورک میزبان تک رسائی حاصل کر سکتا ہے۔ طے شدہ پابندیاں بحال کرنے کے لیے اسے بند کریں اور نیا ماحول کھولیں۔';

  @override
  String get rigNetworkAlreadyUnrestrictedBody =>
      'یہ Android ایمولیٹر پہلے ہی اپنے نیٹ ورک کا انتظام خود کرتا ہے، اس لیے Control Center فی میزبان اجازت کی فہرست نافذ نہیں کر سکتا۔ دوبارہ شروع کرنے کی ضرورت نہیں ہے۔';

  @override
  String get rigClipboardPermissionHostToRigTitle =>
      'کلپ بورڈ کو اس ماحول میں پیسٹ کریں؟';

  @override
  String get rigClipboardPermissionHostToRigBody =>
      'Control Center آپ کے آلے کا کلپ بورڈ پڑھے گا اور اس کا مواد ماحول کو بھیجے گا۔ کلپ بورڈ کے مواد میں پاس ورڈز یا دیگر راز شامل ہو سکتے ہیں۔';

  @override
  String get rigClipboardPermissionRigToHostTitle =>
      'اس ماحول سے کلپ بورڈ کاپی کریں؟';

  @override
  String get rigClipboardPermissionRigToHostBody =>
      'Control Center ماحول کا کلپ بورڈ پڑھے گا اور آپ کے آلے کے کلپ بورڈ کو اس کے مواد سے بدل دے گا۔ ماحول سے آنے والے مواد کو ناقابل اعتماد سمجھیں۔';

  @override
  String get rigClipboardAllowTenMinutes => '10 منٹ کے لیے اجازت دیں';

  @override
  String get rigClipboardAlwaysAllow => 'ہمیشہ اجازت دیں';

  @override
  String get rigClipboardSettingsTitle => 'کلپ بورڈ تک رسائی';

  @override
  String get rigClipboardSettingsHint =>
      'منتخب کریں کہ کلپ بورڈ کی کون سی منتقلیاں پوچھے بغیر چل سکتی ہیں۔ عارضی اجازتیں 10 منٹ بعد ختم ہو جاتی ہیں۔';

  @override
  String get rigClipboardAlwaysPasteTitle =>
      'ماحولوں میں پیسٹ کرنے کی ہمیشہ اجازت دیں';

  @override
  String get rigClipboardAlwaysPasteDescription =>
      'اس آلے کا کلپ بورڈ پوچھے بغیر کسی بھی ماحول کو بھیجیں۔';

  @override
  String get rigClipboardAlwaysCopyTitle =>
      'ماحولوں سے کاپی کرنے کی ہمیشہ اجازت دیں';

  @override
  String get rigClipboardAlwaysCopyDescription =>
      'کسی بھی ماحول سے کلپ بورڈ کا مواد پوچھے بغیر اس آلے پر رکھیں۔';

  @override
  String get profileOverlayHint =>
      'یہ فیلڈز اس ورک اسپیس میں آپ ہیں۔ خالی فیلڈز اکاؤنٹ کا نام اور ای میل وراثت میں لیتی ہیں۔ ورک اسپیس بدلنا یہ تہہ بدلتا ہے۔';

  @override
  String get stackStartNextPart => 'اگلا حصہ شروع کریں';

  @override
  String get stackPartNameTitle => 'حصے کا نام';

  @override
  String get stackPartNameHint => 'مثلاً migration';

  @override
  String get stackPublish => 'اسٹیک شائع کریں';

  @override
  String get stackCurrentPart => 'موجودہ';

  @override
  String get stackSwitchDirty =>
      'حصے بدلنے سے پہلے تبدیلیاں کمٹ کریں یا چھوڑ دیں';

  @override
  String get stackCutFailed => 'اگلا حصہ شروع نہیں ہو سکا';

  @override
  String get stackPublishFailed => 'اسٹیک شائع نہیں ہو سکی';

  @override
  String get stackPublished => 'اسٹیک مسودوں کے طور پر شائع ہو گئی';

  @override
  String get stackOpenPullRequest => 'پل ریکوئسٹ کھولیں';

  @override
  String get stackSection => 'اسٹیک';

  @override
  String get mergeConflictsButton => 'تنازعات';

  @override
  String mergeConflictsFileCount(int count, String base) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فائلیں $base سے متصادم ہیں',
      one: '1 فائل $base سے متصادم ہے',
    );
    return '$_temp0';
  }

  @override
  String get mergeConflictsLoading => 'متصادم فائلیں تلاش کی جا رہی ہیں…';

  @override
  String get mergeConflictsLoadFailed => 'متصادم فائلوں کی فہرست نہیں مل سکی';

  @override
  String get mergeConflictsNoneFound =>
      'کوئی متصادم فائل نہیں ملی۔ ممکن ہے GitHub ابھی اس pull request کو اپ ڈیٹ کر رہا ہو۔';

  @override
  String get askAiToFixConflicts => 'AI سے تنازعات حل کروائیں';

  @override
  String get fixConflictsStarted =>
      'ایک ایجنٹ اس pull request کی چیٹ میں تنازعات حل کر رہا ہے';

  @override
  String failedToStartConflictFix(String error) {
    return 'تنازعات کا حل شروع نہیں ہو سکا: $error';
  }

  @override
  String get settingsLinks => 'لنکس';

  @override
  String get linksSettingsDescription =>
      'منتخب کریں کہ Control Center کے باہر سے آنے والے لنکس کہاں کھلیں، جیسے GitHub سے کھولی گئی pull request۔';

  @override
  String get repoLinkRememberedTitle => 'یاد رکھی گئی ورک اسپیسز';

  @override
  String get repoLinkRememberedHint =>
      'جب کوئی ریپوزٹری ایک سے زیادہ ورک اسپیسز سے منسلک ہو تو اس کا لنک کھولنے پر پوچھا جاتا ہے کہ کون سی ورک اسپیس استعمال کی جائے۔ جن انتخابات کو یاد رکھنے کا آپ نے کہا تھا وہ یہاں درج ہیں۔';

  @override
  String get repoLinkRememberedEmpty =>
      'ابھی تک کوئی انتخاب یاد نہیں رکھا گیا۔';

  @override
  String get repoLinkForget => 'بھول جائیں';

  @override
  String get repoLinkWorkspaceUnavailable => 'ورک اسپیس اب دستیاب نہیں ہے';

  @override
  String get repoLinkWorkspaceDialogTitle => 'ورک اسپیس منتخب کریں';

  @override
  String repoLinkWorkspaceDialogBody(String repo) {
    return '$repo ایک سے زیادہ ورک اسپیسز سے منسلک ہے۔ یہ لنک کس میں کھولا جائے؟';
  }

  @override
  String get repoLinkWorkspaceRemember =>
      'اس ریپوزٹری کے لیے میرا انتخاب یاد رکھیں';

  @override
  String get repoLinkWorkspaceOpen => 'کھولیں';

  @override
  String get repoLinkUnlinkedTitle => 'ریپوزٹری کو ورک اسپیس میں شامل کریں';

  @override
  String repoLinkUnlinkedBody(String repo) {
    return 'ابھی کوئی ورک اسپیس $repo سے منسلک نہیں۔ یہ لنک کھولنے کے لیے اسے کسی ایک میں شامل کریں۔';
  }

  @override
  String repoLinkUnlinkedAddTo(String workspace) {
    return '$workspace میں شامل کریں';
  }

  @override
  String get repoLinkUnlinkedAddToHint => 'سرور پر اس کا چیک آؤٹ منتخب کریں۔';

  @override
  String get repoLinkUnlinkedCreate => 'نئی ورک اسپیس';

  @override
  String get repoLinkUnlinkedCreateHint => 'نام دیں، پھر چیک آؤٹ منتخب کریں۔';

  @override
  String repoLinkChooseCheckout(String repo) {
    return 'سرور چلانے والی مشین پر $repo کا چیک آؤٹ منتخب کریں۔';
  }

  @override
  String repoLinkCheckoutMismatch(String repo) {
    return 'شامل کی گئی ریپوزٹریز میں سے کوئی بھی $repo نہیں، اس لیے لنک اس کے بغیر کھلا۔';
  }

  @override
  String get windowMinimize => 'چھوٹا کریں';

  @override
  String get windowMaximize => 'بڑا کریں';

  @override
  String get windowRestore => 'بحال کریں';

  @override
  String nativeSandboxUnsupported(String platform) {
    return 'نیٹو سینڈ باکس ابھی ⁨$platform⁩ پر معاون نہیں ہے۔';
  }

  @override
  String get continueWithoutSandbox => 'سینڈ باکس کے بغیر جاری رکھیں';

  @override
  String get sandboxCheckAgain => 'دوبارہ چیک کریں';

  @override
  String get ideQuickOpen => 'فائل پر جائیں';

  @override
  String get ideQuickOpenHint => 'نام سے فائلیں تلاش کریں';

  @override
  String get ideQuickOpenRecentlyOpened => 'حال ہی میں کھولی گئی';

  @override
  String get ideQuickOpenOpenToSide => 'ساتھ میں کھولیں';

  @override
  String get ideQuickOpenRemoveRecent =>
      'حال ہی میں کھولی گئی فائلوں سے ہٹائیں';

  @override
  String get ideQuickOpenNoRecent => 'حال ہی میں کوئی فائل نہیں کھولی گئی';

  @override
  String get diffMarkFileViewed => 'دیکھا ہوا کے طور پر نشان زد کریں';

  @override
  String get diffMarkFileNotViewed => 'نہ دیکھا ہوا کے طور پر نشان زد کریں';

  @override
  String diffAdditionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count اضافے',
      one: '1 اضافہ',
    );
    return '$_temp0';
  }

  @override
  String diffDeletionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حذف',
      one: '1 حذف',
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
    return '$path، $status، $additions، $deletions';
  }

  @override
  String diffFileSemanticsViewed(
    String path,
    String status,
    String additions,
    String deletions,
  ) {
    return '$path، $status، $additions، $deletions، دیکھا ہوا';
  }

  @override
  String diffFileRenamedFrom(String previous) {
    return '$previous سے نام تبدیل';
  }

  @override
  String diffTreeFolderSemantics(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فائلیں',
      one: '1 فائل',
    );
    return '$name، فولڈر، $_temp0';
  }

  @override
  String diffTreeFileSemantics(String name, String status) {
    return '$name، $status';
  }

  @override
  String diffTreeFileSemanticsViewed(String name, String status) {
    return '$name، $status، دیکھا ہوا';
  }

  @override
  String diffLineAdded(int line, String code) {
    return 'شامل کردہ سطر $line: $code';
  }

  @override
  String diffLineRemoved(int line, String code) {
    return 'ہٹائی گئی سطر $line: $code';
  }

  @override
  String diffLineContext(int line, String code) {
    return 'سطر $line: $code';
  }

  @override
  String diffLineHunk(String header) {
    return 'حصہ $header';
  }

  @override
  String get diffLineBlank => 'خالی';

  @override
  String get diffCommentOnLineAction => 'اس سطر پر تبصرہ کریں';

  @override
  String diffFileMarkedViewedAnnouncement(String path) {
    return '$path دیکھا ہوا کے طور پر نشان زد';
  }

  @override
  String diffFileMarkedNotViewedAnnouncement(String path) {
    return '$path نہ دیکھا ہوا کے طور پر نشان زد';
  }

  @override
  String prLineChangesSemantics(int additions, int deletions) {
    return 'شامل کی گئی لائنیں: $additions، ہٹائی گئی لائنیں: $deletions';
  }

  @override
  String closeTabNamed(String tab) {
    return '$tab بند کریں';
  }

  @override
  String threadCommentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تبصرے',
      one: '1 تبصرہ',
    );
    return '$_temp0';
  }

  @override
  String get notificationAgentAwaitingInput => 'ایجنٹ کو توجہ درکار ہے';

  @override
  String get notifyAgentAwaitingInput =>
      'جب ایجنٹ کو منظوری، جواب یا درست اسناد درکار ہوں، یا پالیسی کسی کارروائی کو روک دے';

  @override
  String notificationAgentNeedsApproval(String agent) {
    return '$agent کو آپ کی منظوری درکار ہے';
  }

  @override
  String get notificationAgentNeedsApprovalUnnamed =>
      'ایجنٹ کو آپ کی منظوری درکار ہے';

  @override
  String notificationAgentAskedQuestion(String agent) {
    return '$agent کا ایک سوال ہے';
  }

  @override
  String get notificationAgentAskedQuestionUnnamed => 'ایجنٹ کا ایک سوال ہے';

  @override
  String notificationAgentBlockedOnCredential(String agent) {
    return '$agent اسناد کی وجہ سے رکا ہوا ہے';
  }

  @override
  String get notificationAgentBlockedOnCredentialUnnamed =>
      'ایجنٹ اسناد کی وجہ سے رکا ہوا ہے';

  @override
  String notificationWaitReminder(String title) {
    return 'اب بھی منتظر: $title';
  }

  @override
  String get killTerminal => 'ٹرمینل بند کریں';

  @override
  String get stopAgentCommand => 'کمانڈ روکیں';

  @override
  String get agentCommandStopping => 'روکا جا رہا ہے…';

  @override
  String sidebarAgeSeconds(int count) {
    return '$count سیکنڈ';
  }

  @override
  String agentCommandSemantics(String command, String elapsed) {
    return 'ایجنٹ کمانڈ $command، $elapsed سے چل رہی ہے';
  }

  @override
  String get serverLostTitle => 'سرور سے رابطہ منقطع ہو گیا';

  @override
  String get serverLostBody =>
      'Control Center پس منظر میں دوبارہ جڑنے کی کوشش جاری رکھے ہوئے ہے۔ ابھی دوبارہ کوشش کریں، یا سرور منتخب کرنے کے لیے سائن ان اسکرین پر جائیں۔';

  @override
  String get serverLostRetrying => 'دوبارہ جڑ رہا ہے…';

  @override
  String serverLostNextAttempt(int seconds) {
    return 'اگلی کوشش $seconds سیکنڈ میں';
  }

  @override
  String get serverLostReconnect => 'دوبارہ جڑنے کی کوشش کریں';

  @override
  String get serverLostSignIn => 'سائن ان پر جائیں';

  @override
  String get serverEndedTitle => 'سرور سے دوبارہ جڑا نہیں جا سکتا';

  @override
  String get shutdownSubtitleServer => 'سرور بند ہو رہا ہے';

  @override
  String get skillEvalAbsent => 'غیر موجود بمقابلہ دستیاب';

  @override
  String get skillEvalAmbient => 'پس منظر کی اسکلز';

  @override
  String skillEvalArtifactRef(String reference) {
    return 'آرٹیفیکٹ کا حوالہ: $reference';
  }

  @override
  String skillEvalAttempt(String task, String arm, int repeat) {
    final intl.NumberFormat repeatNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String repeatString = repeatNumberFormat.format(repeat);

    return '$task · $arm · تکرار $repeatString';
  }

  @override
  String get skillEvalAttempts => 'کوششیں';

  @override
  String get skillEvalAvailableEvent => 'دستیاب';

  @override
  String get skillEvalBaseline => 'پچھلی ترمیم کا ہیش';

  @override
  String get skillEvalBodyLoad => 'متن لوڈ ہوا';

  @override
  String get skillEvalBudgetCents => 'بجٹ (US cents)';

  @override
  String get skillEvalBudgetNote =>
      'ادائیگی والی جانچ منتخب فراہم کنندہ اور بجٹ استعمال کرتی ہے۔ سیکیورٹی اسکین کے نتائج الگ ہیں۔';

  @override
  String get skillEvalUsageBudgetNote =>
      'سبسکرپشن کا بجٹ بلوں کے بجائے API کی مساوی شرحوں کے مطابق استعمال کو ٹریک کرتا ہے۔ جاری کال بجٹ سے تجاوز کر سکتی ہے؛ حد تک پہنچنے کے بعد نئی کال شروع نہیں ہوتی۔ سیکیورٹی اسکین الگ ہیں۔';

  @override
  String get skillEvalCancel => 'جانچ منسوخ کریں';

  @override
  String get skillEvalCancelled => 'منسوخ ہو گئی';

  @override
  String get skillEvalCancelling => 'منسوخ ہو رہی ہے';

  @override
  String get skillEvalComparison => 'موازنہ';

  @override
  String get skillEvalCompleted => 'مکمل';

  @override
  String get skillEvalComposition => 'ترکیب';

  @override
  String get skillEvalCorpus => 'کاموں کا مجموعہ';

  @override
  String skillEvalCoverage(String corpus, int repeats) {
    final intl.NumberFormat repeatsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String repeatsString = repeatsNumberFormat.format(repeats);

    return '$corpus · $repeatsString تکراریں';
  }

  @override
  String get skillEvalCoverageComplete =>
      'تمام طے شدہ آزمائشوں کے نتائج مل گئے';

  @override
  String skillEvalCurrentHash(String hash) {
    return 'موجودہ پیکیج کا ہیش: $hash';
  }

  @override
  String get skillEvalDisableUpdates => 'اپ ڈیٹ کی جانچ بند کریں';

  @override
  String get skillEvalEnableUpdates => 'اپ ڈیٹ کی جانچ چالو کریں';

  @override
  String get skillEvalExport => 'حذف شدہ حساس معلومات والا JSON کاپی کریں';

  @override
  String get skillEvalFailed => 'ناکام';

  @override
  String get skillEvalForced => 'زبردستی لوڈ بمقابلہ غیر موجود';

  @override
  String get skillEvalForcedEvent => 'زبردستی لوڈ';

  @override
  String get skillEvalHashLabel => 'پیکیج کا ہیش';

  @override
  String get skillEvalProgressLabel => 'پیش رفت';

  @override
  String get skillEvalUpdatesToggle => 'اپ ڈیٹ کی جانچ';

  @override
  String get skillEvalHashUnavailable =>
      'اس سرور پر پیکیج کا ہیش دستیاب نہیں۔ جانچ بند ہے۔';

  @override
  String get skillEvalHistory => 'ترمیمات کی تاریخ';

  @override
  String get skillEvalImproved => 'بہتری آئی';

  @override
  String get skillEvalIncomplete => 'نامکمل';

  @override
  String get skillEvalInconclusive => 'کوئی فیصلہ نہیں (شواہد ناکافی)';

  @override
  String get skillEvalInferred => 'اخذ کردہ';

  @override
  String get skillEvalInterrupted => 'درمیان میں رک گئی';

  @override
  String get skillEvalLoadUnobserved =>
      'اسکل لوڈ ہونے کی تصدیق ممکن نہیں؛ واقعہ درج نہ ہونے سے یہ ثابت نہیں ہوتا کہ اسے نظرانداز کیا گیا۔';

  @override
  String get skillEvalModel => 'منتخب ماڈل';

  @override
  String get skillEvalNoAttempts => 'ابھی کوئی کوشش نہیں ہوئی۔';

  @override
  String get skillEvalNoModels =>
      'کوئی منسلک ماڈل دستیاب نہیں۔ پہلے ترتیبات میں فراہم کنندہ منسلک کریں۔';

  @override
  String get skillEvalNoPrevious =>
      'مہم کی تاریخ میں پچھلا ہیش موجود نہیں۔ اسے بدلنے سے پہلے پچھلی ترمیم کی جانچ کریں۔';

  @override
  String get skillEvalNoReport =>
      'ابھی کوئی رپورٹ نہیں؛ جزوی کوششیں دستیاب ہیں۔';

  @override
  String get skillEvalNoWorkspace => 'کوئی ورک اسپیس منتخب نہیں۔';

  @override
  String get skillEvalNoTasks => 'ابھی کوئی کام رپورٹ نہیں ہوا۔';

  @override
  String get skillEvalNoVerifiers => 'تصدیق کا کوئی ثبوت درج نہیں۔';

  @override
  String get skillEvalNotEvaluated =>
      'ان عین بائٹس کی جانچ نہیں ہوئی۔ اسکین رویے کا ثبوت نہیں ہے۔';

  @override
  String get skillEvalNotVerified => 'تصدیق نہیں ہوئی';

  @override
  String get skillEvalObserved => 'مشاہدہ کیا گیا';

  @override
  String get skillEvalOpenQuality => 'معیار کھولیں';

  @override
  String get skillEvalPolicyNote =>
      'پہلے سے طے شدہ حالت میں اسکل محفوظ کرنے سے ادائیگی والی جانچ شروع نہیں ہوتی۔ اگر آپ اپ ڈیٹ پر خودکار دوبارہ جانچ واضح طور پر فعال کریں تو محفوظ کرنے سے مقررہ بجٹ کے اندر ادائیگی والی دوبارہ جانچ شروع ہوگی۔';

  @override
  String get skillEvalPolicyNeedsCampaign =>
      'اپ ڈیٹ پالیسی ترتیب دینے سے پہلے کسی ترمیم کی جانچ کریں۔';

  @override
  String get skillEvalPolicyTemplate => 'اپ ڈیٹ پالیسی کی ترتیب';

  @override
  String get skillEvalPartial => 'جزوی ثبوت؛ اپنانے کا کوئی فیصلہ نہیں';

  @override
  String skillEvalProgress(int completed, int planned) {
    final intl.NumberFormat completedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String completedString = completedNumberFormat.format(completed);
    final intl.NumberFormat plannedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String plannedString = plannedNumberFormat.format(planned);

    return '$plannedString میں سے $completedString کوششیں';
  }

  @override
  String skillEvalProvider(String provider) {
    return 'فراہم کنندہ: $provider';
  }

  @override
  String get skillEvalQualityIntro =>
      'ورک اسپیس اسکل کی مہمات اور ہر ترمیم کے مخصوص ثبوت۔';

  @override
  String get skillEvalQueued => 'قطار میں';

  @override
  String get skillEvalReconnecting =>
      'مہم کے اسنیپ شاٹس سے دوبارہ منسلک ہو رہا ہے…';

  @override
  String get skillEvalRefresh => 'تازہ کریں';

  @override
  String get skillEvalReferenceLoad => 'حوالہ لوڈ ہوا';

  @override
  String get skillEvalRepetitions => 'فی کام تکراریں';

  @override
  String get skillEvalReport => 'ثبوت کی رپورٹ';

  @override
  String get skillEvalRunning => 'جاری ہے';

  @override
  String get skillEvalScriptExecution => 'اسکرپٹ چلایا گیا';

  @override
  String skillEvalSpend(String spent, String budget) {
    return 'خرچ: $spent / بجٹ $budget';
  }

  @override
  String get skillEvalStart => 'جانچ شروع کریں';

  @override
  String get skillEvalStartTitle => 'اسکل کی ترمیمات کا موازنہ کریں';

  @override
  String get skillEvalStale => 'پرانا';

  @override
  String skillEvalStaleReason(String reason) {
    return 'پرانا: $reason';
  }

  @override
  String skillEvalTaskClusters(String count) {
    return 'الگ الگ کاموں کے گروپ: $count';
  }

  @override
  String skillEvalTaskEvidence(String rate, String passes, String cost) {
    return '$rate ($passes کی تصدیق ہوئی) · $cost';
  }

  @override
  String get skillEvalTasks => 'گروپ کے لحاظ سے کام';

  @override
  String get skillEvalToolError => 'ٹول کی خرابی';

  @override
  String get skillEvalTools => 'ٹول کے واقعات';

  @override
  String get skillEvalTitle => 'اسکل کی جانچ';

  @override
  String skillEvalUnavailable(String reason) {
    return 'دستیاب نہیں: $reason';
  }

  @override
  String get skillEvalUnknown => 'نامعلوم';

  @override
  String get skillEvalUnsaved =>
      'غیر محفوظ شدہ تبدیلیاں شامل نہیں۔ جانچ سے پہلے محفوظ کریں۔';

  @override
  String get skillEvalUncertainty => 'غیر یقینی کی حد';

  @override
  String get skillEvalVerified => 'تصدیق شدہ';

  @override
  String get skillEvalVerifiers => 'تصدیق';

  @override
  String get skillEvalVerdict => 'فیصلہ';

  @override
  String skillEvalExportCopied(String filename) {
    return 'کاپی مکمل: $filename';
  }

  @override
  String get skillEvalPlanViolation => 'منصوبے کی خلاف ورزی';

  @override
  String get skillEvalPreserved => 'معیار برقرار رہا';

  @override
  String get skillEvalPrevious => 'پچھلی بمقابلہ موجودہ';

  @override
  String get skillEvalRegressed => 'کارکردگی میں کمی ثابت ہوئی';

  @override
  String get skillEvalCostRegression => 'لاگت میں اضافہ';

  @override
  String get skillEvalHarnessError => 'ہارنس کی خرابی';

  @override
  String get skillBehaviorRouting => 'مہارت کی راہ بندی';

  @override
  String skillBehaviorRoutingCounts(
    String truePositive,
    String falsePositive,
    String falseNegative,
    String trueNegative,
  ) {
    return '$truePositive متوقع استعمال · $falsePositive غیر متوقع استعمال · $falseNegative چھوٹے ہوئے استعمال · $trueNegative درست نظر انداز';
  }

  @override
  String skillBehaviorUnknownCounts(
    String positive,
    String negative,
    String notOffered,
  ) {
    return '$positive غیر یقینی استعمال · $negative غیر یقینی نظر انداز · $notOffered پیش نہیں کیے گئے';
  }

  @override
  String skillBehaviorRoutingRates(
    String precision,
    String recall,
    String falsePositiveRate,
  ) {
    return 'مشاہدہ شدہ درستی $precision · بازیافت $recall · غلط مثبت کی شرح $falsePositiveRate';
  }

  @override
  String get skillBehaviorForced => 'جبری گروہ · صرف تشخیص کے لیے';

  @override
  String get skillBehaviorRoutingNote =>
      'شرحیں صرف قابل مشاہدہ رسائی پر مبنی ہیں۔ شیل یا تلاش کے ذریعے رسائی نامعلوم رہ سکتی ہے؛ مہارت لوڈ ہونا اس کے اطلاق کا ثبوت نہیں۔';

  @override
  String get skillBehaviorSafety => 'مصنوعی حفاظت';

  @override
  String skillBehaviorSafetyCounts(
    String passes,
    String attempts,
    String denials,
    String violations,
  ) {
    return '$passes/$attempts کامیاب نمونہ جاتی جانچیں · $denials پالیسی کی تردیدیں · $violations محفوظ فائلوں کی خلاف ورزیاں';
  }

  @override
  String get skillBehaviorSafetyNote =>
      'نمونہ جاتی جانچیں مصنوعی ہیں اور حقیقی دنیا میں حملوں کی شرح کو ظاہر نہیں کرتیں؛ حقیقی ضمنی اثرات کی نگرانی نہیں ہوتی۔';

  @override
  String get skillBehaviorUtility => 'خاندان کے لحاظ سے افادیت';

  @override
  String skillBehaviorUtilityCounts(String verified, String attempts) {
    return '$verified/$attempts تصدیق شدہ کامیابیاں';
  }

  @override
  String get skillBehaviorUtilityNote =>
      'تمام کوششیں افادیت کے مخرج میں شمار ہوتی ہیں، بشمول ناکام اور نامکمل کوششیں۔';

  @override
  String get claudeAccountSignInFailed => 'سائن ان ناکام رہا';

  @override
  String get claudeSignInDialogTitle => 'Claude Code میں سائن ان کریں';

  @override
  String get claudeSignInDialogHint =>
      'ہر کمانڈ سرور کے ٹرمینل میں چلائیں۔ یہ لاگ ان مکمل کرنے کے لیے براؤزر کھولتی ہے اور اسناد اس اکاؤنٹ کی ڈائریکٹری میں لکھتی ہے۔';

  @override
  String get claudeSignInNoAccounts =>
      'کوئی منظم اکاؤنٹ سائن آؤٹ نہیں ہے۔ اگر یہ ایجنٹ Claude Code کا اپنا لاگ ان استعمال کرتا ہے تو چلائیں:';

  @override
  String get claudeSignInCommandUnavailable =>
      'سرور اس اکاؤنٹ کے لیے لاگ ان کمانڈ فراہم نہیں کر سکا۔';

  @override
  String get claudeAccountSignedIn => 'سائن اِن ہو گیا';

  @override
  String get claudeSignInClosesItself =>
      'سائن اِن مکمل ہوتے ہی یہ ڈائیلاگ خودبخود بند ہو جائے گا۔';

  @override
  String get claudeSignInClosesItselfAll =>
      'تمام اکاؤنٹس میں سائن اِن مکمل ہوتے ہی یہ ڈائیلاگ خودبخود بند ہو جائے گا۔';

  @override
  String get transcriptClaudeSignInExpiredTitle =>
      'Claude Code سائن ان کی میعاد ختم ہو گئی';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      'رن رک گیا کیونکہ اس کا اکاؤنٹ اب تصدیق نہیں ہوتا۔ دوبارہ سائن ان کریں، پھر یہ باری دوبارہ آزمائیں۔';

  @override
  String get transcriptSignInExpiredTitle =>
      'فراہم کنندہ سائن ان کی میعاد ختم ہو گئی';

  @override
  String get transcriptSignInExpiredBody =>
      'رن رک گیا کیونکہ فراہم کنندہ کی اسناد اب کام نہیں کرتیں۔ اسے ترتیبات ← فراہم کنندگان میں دوبارہ جوڑیں، پھر یہ باری دوبارہ آزمائیں۔';

  @override
  String get helpMenuLabel => 'مدد';

  @override
  String get helpWhatsNew => 'نیا کیا ہے';

  @override
  String get helpReportProblem => 'مسئلے کی اطلاع دیں';

  @override
  String get helpCreateGitHubIssue => 'GitHub پر issue بنائیں';

  @override
  String get changelogInstalled => 'انسٹال شدہ';

  @override
  String get changelogGroupNew => 'نیا';

  @override
  String get changelogGroupImproved => 'بہتر';

  @override
  String get changelogGroupFixed => 'درست شدہ';

  @override
  String get changelogLoadFailed => 'ریلیز نوٹس لوڈ نہیں ہو سکے۔';

  @override
  String get changelogOpenWebsite => 'ویب سائٹ پر کھولیں';

  @override
  String get connectWelcomeTitle => 'Control Center میں خوش آمدید';

  @override
  String get connectWelcomeSubtitle =>
      'اسے یہیں چلائیں، یا اپنے موجودہ سرور سے منسلک ہوں۔';

  @override
  String get connectWelcomeSubtitleWeb =>
      'شروع کرنے کے لیے اپنے سرور سے منسلک ہوں۔';

  @override
  String get connectToServer => 'سرور سے منسلک ہوں';

  @override
  String get connectToServerIntro => 'Control Center سرور کا پتہ درج کریں۔';

  @override
  String get connectUsePairingKey => 'پیئرنگ کلید استعمال کریں';

  @override
  String get connectPasteLink => 'پیئرنگ لنک چسپاں کریں';

  @override
  String get connectPasteLinkIntro =>
      'آپ کو ملا ہوا دعوتی یا پیئرنگ لنک چسپاں کریں۔';

  @override
  String get connectPasteLinkLabel => 'دعوتی یا پیئرنگ لنک';

  @override
  String get connectPasteLinkInvalid =>
      'یہ Control Center کا دعوتی یا پیئرنگ لنک نہیں ہے۔ پورا لنک کاپی کر کے دوبارہ کوشش کریں۔';

  @override
  String get connectPasteLinkTarget => 'اس سے منسلک ہوگا';

  @override
  String get focusModeEnd => 'فوکس سیشن ختم کریں';

  @override
  String focusModeRemaining(int minutes) {
    return '$minutes منٹ باقی';
  }

  @override
  String get demoUnavailableEnvironments =>
      'ماحول میزبان پر حقیقی عمل چلاتے ہیں، اس لیے ڈیمو میں کوئی ماحول نہیں۔';

  @override
  String get environmentChecksFailing => 'سرور پر کچھ جانچیں ناکام ہو رہی ہیں';

  @override
  String environmentCliEndpoints(String names) {
    return 'اینڈ پوائنٹس: $names';
  }

  @override
  String environmentCliServices(String names) {
    return 'سروسز: $names';
  }

  @override
  String get environmentCopied => 'کاپی ہو گیا';

  @override
  String get environmentCopyCommand => 'کمانڈ کاپی کریں';

  @override
  String get environmentCopyUrl => 'URL کاپی کریں';

  @override
  String get environmentDefinition => 'تعریف';

  @override
  String environmentDefinitionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تعریفیں',
      one: '1 تعریف',
    );
    return '$_temp0';
  }

  @override
  String get environmentDestroy => 'تباہ کریں';

  @override
  String environmentDestroyBody(String name) {
    return '$name اور اس کا ڈیٹا ہٹا دیا جائے گا۔ شروع کرنے پر نیا بنے گا۔';
  }

  @override
  String get environmentDestroyTitle => 'کیا یہ ماحول تباہ کرنا ہے؟';

  @override
  String get environmentExec => 'Exec';

  @override
  String get environmentExecTitle => 'سروس میں چلائیں';

  @override
  String environmentExitCode(int code) {
    return 'ایگزٹ کوڈ $code';
  }

  @override
  String get environmentInputNeeded => 'اسے سرور پر سیٹ اپ کرنا ہوگا';

  @override
  String get environmentKindApp => 'ایپ';

  @override
  String get environmentKindCli => 'CLI';

  @override
  String get environmentKindCompose => 'Compose';

  @override
  String get environmentKindProcess => 'عمل';

  @override
  String get environmentKindTask => 'ٹاسک';

  @override
  String get environmentLaunch => 'ایپ کھولیں';

  @override
  String get environmentLogsGone => 'یہ لاگز اب دستیاب نہیں۔';

  @override
  String environmentLogsTab(String name) {
    return 'لاگز: $name';
  }

  @override
  String get environmentLogsWaiting => 'آؤٹ پٹ کا انتظار ہے';

  @override
  String get environmentMoreActions => 'ماحول کے مزید اقدامات';

  @override
  String get environmentNeedsRecreate =>
      'ایک تبدیلی کے باعث اس ماحول کو دوبارہ بنانا ہوگا۔';

  @override
  String get environmentNoStack =>
      'صرف worktree ٹاسک چلاتا ہے، اس لیے شروع کرنے کو کچھ نہیں۔';

  @override
  String get environmentOnTheServer => 'سرور پر';

  @override
  String get environmentOpenInBrowserVm => 'Browser (VM) میں کھولیں';

  @override
  String get environmentOpenViewer => 'ویوئر کھولیں';

  @override
  String get environmentPlacementRig => 'VM میں';

  @override
  String get environmentPreviewTab => 'ماحول';

  @override
  String get environmentRebuildRelaunch => 'دوبارہ بنائیں اور کھولیں';

  @override
  String get environmentRecreate => 'دوبارہ بنائیں';

  @override
  String environmentRecreateBody(String name) {
    return '$name تباہ ہو کر انہی اختیارات کے ساتھ دوبارہ شروع ہوگا۔ اس کا ڈیٹا ضائع ہو جائے گا۔';
  }

  @override
  String get environmentRecreateTitle => 'کیا یہ ماحول دوبارہ بنانا ہے؟';

  @override
  String environmentResetBody(String name) {
    return '$name اپنی بنیادی حالت پر واپس جائے گا۔ اس کے بعد بنا ڈیٹا ضائع ہو جائے گا۔';
  }

  @override
  String get environmentResetData => 'ڈیٹا ری سیٹ کریں';

  @override
  String get environmentResetTitle => 'کیا ڈیٹا ری سیٹ کرنا ہے؟';

  @override
  String get environmentRestart => 'ری اسٹارٹ';

  @override
  String environmentRestarts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ری اسٹارٹس',
      one: '1 ری اسٹارٹ',
    );
    return '$_temp0';
  }

  @override
  String get environmentRun => 'چلائیں';

  @override
  String get environmentRunInTerminal => 'ٹرمینل میں چلائیں';

  @override
  String get environmentSectionTitle => 'ماحول';

  @override
  String get environmentService => 'سروس';

  @override
  String environmentServiceActions(String name) {
    return '$name کے اقدامات';
  }

  @override
  String get environmentStartTitle => 'ماحول شروع کریں';

  @override
  String get environmentStateCrashed => 'کریش ہو گیا';

  @override
  String get environmentStatusDegraded => 'متاثر';

  @override
  String get environmentStatusDestroying => 'تباہ ہو رہا ہے';

  @override
  String get environmentStatusGone => 'ختم';

  @override
  String get environmentStatusStopping => 'رک رہا ہے';

  @override
  String environmentStopDataLoss(String name) {
    return '$name کو روکنے سے اس کا ڈیٹا ضائع ہوگا، اور شروع کرنے سے واپس نہیں آئے گا۔';
  }

  @override
  String get environmentStopLoseData => 'روکیں اور ڈیٹا کھوئیں';

  @override
  String get environmentStopTitle => 'کیا یہ ماحول روکنا ہے؟';

  @override
  String get environmentTaskNeverRun => 'ابھی نہیں چلا';

  @override
  String get environmentsAddCheck => 'جانچ شامل کریں';

  @override
  String get environmentsAddOption => 'اختیار شامل کریں';

  @override
  String get environmentsAddRole => 'کردار شامل کریں';

  @override
  String get environmentsAdminOnly =>
      'صرف ورک اسپیس کے منتظمین تعریفیں بدل سکتے ہیں۔';

  @override
  String get environmentsAfter => 'ان اجزا کا انتظار کریں';

  @override
  String get environmentsAnchor => 'اینکر';

  @override
  String get environmentsAutoCreate => 'خود بخود شروع کریں';

  @override
  String get environmentsAutoCreateAll => 'ہر اہل اسپیس میں';

  @override
  String get environmentsAutoCreateOff => 'کبھی نہیں';

  @override
  String get environmentsAutoCreatePrs => 'پل ریکویسٹ اسپیسز میں';

  @override
  String get environmentsBlank => 'خالی تعریف';

  @override
  String get environmentsCheckFix => 'درستی کی کمانڈ';

  @override
  String get environmentsCheckHint => 'اشارہ';

  @override
  String get environmentsCommandHelp =>
      'دلائل خالی جگہوں سے الگ ہوتے ہیں۔ خالی جگہ والی دلیل کو اقتباس میں رکھیں۔';

  @override
  String environmentsComponentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count اجزا',
      one: '1 جزو',
    );
    return '$_temp0';
  }

  @override
  String get environmentsComponentId => 'ID';

  @override
  String get environmentsComposeBuild => 'شروع پر امیجز بنائیں';

  @override
  String get environmentsComposeFile => 'Compose فائل';

  @override
  String get environmentsComposeHttp => 'HTTP';

  @override
  String get environmentsComposeNoFile =>
      'Compose فائل نہیں پڑھی جا سکی۔ سروس کے نام پھر بھی JSON منظر میں لکھے جا سکتے ہیں۔';

  @override
  String get environmentsComposeServices => 'سروسز';

  @override
  String get environmentsComposeServicesHint =>
      'سب چلانے کے لیے تمام سروسز غیر منتخب رہنے دیں۔';

  @override
  String get environmentsConditionalArgs =>
      'اس کمانڈ میں مشروط دلائل ہیں۔ اسے JSON منظر میں ترمیم کریں۔';

  @override
  String get environmentsCwdPath => 'کام کا راستہ';

  @override
  String get environmentsCwdRole => 'کام کا کردار';

  @override
  String get environmentsDeleteBody =>
      'اسپیسز اسے مزید شروع نہیں کر سکیں گی۔ چلتے ماحول رکنے تک چلتے رہیں گے۔';

  @override
  String environmentsDeleteTitle(String name) {
    return 'کیا $name حذف کرنا ہے؟';
  }

  @override
  String get environmentsDescription =>
      'ہر اسپیس کیا شروع کر سکتی ہے، اور اس کے worktrees کون سے ٹاسک چلاتے ہیں۔';

  @override
  String get environmentsDraftFromRepo => 'ریپو سے مسودہ';

  @override
  String get environmentsEmpty => 'ابھی کوئی تعریف نہیں';

  @override
  String get environmentsEnabledWhen => 'فعال جب';

  @override
  String get environmentsEndpointRole => 'اینڈ پوائنٹ کردار';

  @override
  String get environmentsFollowPrHead => 'پل ریکویسٹ کے head کی پیروی کریں';

  @override
  String get environmentsForkApproval => 'ہر آغاز کے لیے منتظم درکار ہے';

  @override
  String get environmentsForkDeny => 'مسترد';

  @override
  String get environmentsForkPrs => 'فورک پل ریکویسٹس';

  @override
  String get environmentsForkRig => 'VM میں چلائیں';

  @override
  String get environmentsIdleStop => 'فارغ منٹوں کے بعد روکیں';

  @override
  String get environmentsIsolateHome => 'ایپ کو نجی ہوم دیں';

  @override
  String get environmentsIssues => 'محفوظ کرنے سے پہلے انہیں درست کریں';

  @override
  String environmentsJsonInvalid(String error) {
    return 'غلط JSON: $error';
  }

  @override
  String get environmentsKeepsData => 'رکنے پر اپنا ڈیٹا رکھتا ہے';

  @override
  String get environmentsLinkConfirm => 'لنک اور منظور کریں';

  @override
  String get environmentsLinkFile => 'ریپو فائل لنک کریں';

  @override
  String get environmentsLinkHelp =>
      'صرف ڈیفالٹ برانچ سے پڑھا جاتا ہے اور منظوری کے بعد ہی چلتا ہے۔';

  @override
  String get environmentsLinkPath => 'راستہ';

  @override
  String get environmentsMaxRunning => 'ایک ساتھ چل رہے';

  @override
  String get environmentsNamingProject => 'پروجیکٹ';

  @override
  String get environmentsNamingTemplate => 'نام کا سانچہ';

  @override
  String get environmentsNew => 'نئی تعریف';

  @override
  String get environmentsNewDefinitionName => 'نیا ماحول';

  @override
  String get environmentsNoChecks => 'اس تعریف میں کوئی جانچ نہیں۔';

  @override
  String get environmentsNoRuns => 'ابھی کوئی ٹیسٹ رن نہیں';

  @override
  String get environmentsOnChange => 'نگرانی کے راستے';

  @override
  String get environmentsOptionBool => 'ہاں یا نہیں';

  @override
  String get environmentsOptionEnum => 'ان میں سے ایک';

  @override
  String get environmentsOptionMulti => 'ان میں سے کئی';

  @override
  String get environmentsOptionValues => 'قدریں';

  @override
  String get environmentsPlacement => 'مقام';

  @override
  String get environmentsPlacementHost => 'میزبان پر';

  @override
  String get environmentsPlacementRig => 'VM میں';

  @override
  String get environmentsPrepareTask => 'تیاری کا ٹاسک';

  @override
  String get environmentsPrimaryEndpoint => 'بنیادی اینڈ پوائنٹ';

  @override
  String get environmentsReadyHttp => 'تیار جب یہ URL جواب دے';

  @override
  String get environmentsRestartAlways => 'ہمیشہ';

  @override
  String get environmentsRestartNever => 'کبھی نہیں';

  @override
  String get environmentsRestartOn => 'ان راستوں کے بدلنے پر ری اسٹارٹ کریں';

  @override
  String get environmentsRestartOnFailure => 'ناکامی پر';

  @override
  String get environmentsRestartPolicy => 'ری اسٹارٹ';

  @override
  String get environmentsRigTtl => 'VM کی مدت گھنٹوں میں';

  @override
  String get environmentsRunChecks => 'دوبارہ چلائیں';

  @override
  String get environmentsRunTest => 'ٹیسٹ چلائیں';

  @override
  String get environmentsSaved => 'تعریف محفوظ ہو گئی';

  @override
  String get environmentsSectionComponents => 'اجزا';

  @override
  String get environmentsSectionOptions => 'آغاز کے اختیارات';

  @override
  String get environmentsSectionSeedFiles => 'ابتدائی فائلیں';

  @override
  String get environmentsSectionVariables => 'متغیرات';

  @override
  String get environmentsSeedHelp =>
      'ہر سطر میں ایک راستہ، رجسٹرڈ checkout سے کاپی ہوتا ہے۔ فورک پل ریکویسٹس کو یہ کبھی نہیں ملتیں۔';

  @override
  String get environmentsShellHelp =>
      'یہاں پلیس ہولڈرز نہیں پھیلتے۔ اس کے بجائے CC_ENV_* متغیرات پڑھیں۔';

  @override
  String get environmentsSourceApprove => 'یہ ورژن منظور کریں';

  @override
  String environmentsSourceCurrent(String path) {
    return '$path منظور شدہ ورژن سے میل کھاتا ہے۔';
  }

  @override
  String get environmentsSourceNotice =>
      'منظور شدہ ورژن چلتا رہے گا جب تک آپ اسے منظور نہ کریں۔';

  @override
  String get environmentsTabJson => 'JSON';

  @override
  String get environmentsTabSource => 'ماخذ';

  @override
  String get environmentsTestHelp =>
      'ایک عارضی ماحول شروع سے آخر تک چلاتا ہے: جانچ، آغاز، تیاری کا انتظار، تباہی۔';

  @override
  String get environmentsTestSaveFirst => 'پہلے تعریف محفوظ کریں۔';

  @override
  String get environmentsTimeoutSeconds => 'سیکنڈ میں ٹائم آؤٹ';

  @override
  String get environmentsTitle => 'ماحول';

  @override
  String get environmentsTriggerArchive => 'worktree حذف ہونے سے پہلے';

  @override
  String get environmentsTriggerChange => 'جب نگرانی کے راستے بدلیں';

  @override
  String get environmentsTriggerCreate => 'ہر ماحول میں ایک بار';

  @override
  String get environmentsTriggerManual => 'درخواست پر';

  @override
  String get environmentsTriggerProvision => 'جب worktree بنے';

  @override
  String get environmentsTriggerStart => 'ہر آغاز پر';

  @override
  String get environmentsTriggers => 'کب چلتا ہے';

  @override
  String get environmentsUnreadable => 'یہ کلائنٹ اس تعریف کو نہیں پڑھ سکتا۔';

  @override
  String get environmentsUpdateAvailable => 'اپ ڈیٹ دستیاب ہے';

  @override
  String get environmentsUseShell => 'شیل کمانڈ استعمال کریں';

  @override
  String get environmentsUseSourceWarning =>
      'ٹول پھر آپ کے اپنے checkout پر چلتا ہے۔ اسے صرف پڑھنے کے لیے سمجھیں۔';

  @override
  String get environmentsWhenMissing => 'جب اسپیس میں نہ ہو';

  @override
  String get environmentsWhenMissingAdd => 'اسپیس میں شامل کریں';

  @override
  String get environmentsWhenMissingSkip => 'چھوڑ دیں';

  @override
  String get environmentsWhenMissingSource => 'رجسٹرڈ checkout استعمال کریں';

  @override
  String get environmentsUnsupported => 'یہ سرور ماحول کو سپورٹ نہیں کرتا۔';

  @override
  String get environmentViewerUnavailable =>
      'کوئی ویوئر نہیں: سرور اس ونڈو کو کیپچر نہیں کر سکتا۔ سرور پر Control Center کو اسکرین ریکارڈنگ کی اجازت دیں۔';

  @override
  String get environmentHealthHealthy => 'صحت مند';

  @override
  String get environmentHealthUnhealthy => 'خراب';

  @override
  String get environmentTerminalStale =>
      'یہ ٹرمینل ماحول شروع ہونے سے پہلے کھلا تھا، اس لیے اس میں ماحول کے متغیرات نہیں۔';

  @override
  String get environmentTerminalFresh => 'نیا ٹرمینل کھولیں';

  @override
  String get environmentsShellStays =>
      'کئی سطروں والا اسکرپٹ شیل کمانڈ ہی رہتا ہے: سطریں اس کی ساخت ہیں۔';

  @override
  String get environmentsOverrides => 'ورک اسپیس اوور رائیڈز';

  @override
  String get environmentsOverridesHelp =>
      'فائل کی اپنی ترتیبات یہاں صرف پڑھنے کے لیے ہیں۔ اس کے کرداروں کو اس ورک اسپیس کی ریپوز سے جوڑیں یا کسی بھی فیلڈ کو JSON کے طور پر اوور رائیڈ کریں۔';

  @override
  String get environmentsReposHelp =>
      'وہ ریپوزٹریز جو یہ ماحول استعمال کرتا ہے، ہر ایک کسی رول سے منسلک ہے۔';

  @override
  String get environmentsComponentsHelp =>
      'ماحول جو کچھ چلاتا ہے، آغاز کی ترتیب میں۔';

  @override
  String get environmentsOptionsHelp =>
      'ماحول شروع کرتے وقت پیش کیے جانے والے انتخاب۔';

  @override
  String get environmentsVariablesHelp =>
      'ٹاسکس، پروسیسز، ایپس اور اسپیس ٹرمینلز پر سیٹ ہوتے ہیں۔';

  @override
  String get environmentsChecksHelp =>
      'اس ماحول کو چلانے کے لیے ہوسٹ کو کیا درکار ہے۔';

  @override
  String get environmentsIdleStopHelp => '0 اسے کبھی نہیں روکتا۔';

  @override
  String get environmentsAnchorHelp =>
      'جس اسپیس میں یہ ریپوزٹری ہو وہ ماحول شروع کر سکتی ہے۔';

  @override
  String get environmentsRequiredHelp => 'اس کے بغیر ماحول نہیں چل سکتا۔';

  @override
  String get environmentsFollowPrHeadHelp =>
      'پل ریکویسٹ کا head بدلنے پر سنک اور ریفریش کریں۔';

  @override
  String get environmentsRecordNeedsFix => 'درستی درکار ہے';

  @override
  String get environmentsCheckFile => 'فائل';

  @override
  String get environmentsDiscardBody =>
      'اس تعریف میں آپ کی ترامیم ضائع ہو جائیں گی۔';

  @override
  String get environmentsWorktreeRuns => 'worktree ٹاسک رنز';

  @override
  String get environmentsNoWorktreeRuns =>
      'ابھی تک کوئی worktree ٹاسک نہیں چلا۔';

  @override
  String get environmentsLinkRoles => 'اس فائل میں کردار';

  @override
  String get environmentsLinkNoFile =>
      'ریپو سے فائل نہیں پڑھی جا سکی۔ لنک کرنے کے بعد کردار جوڑے جا سکتے ہیں۔';

  @override
  String get guardrailClassHostExecution => 'میزبان پر کمانڈز چلائیں';

  @override
  String get environmentUrls => 'URLs';

  @override
  String get environmentScripts => 'اسکرپٹس';

  @override
  String get environmentNoneForSpace => 'اس اسپیس کے لیے کوئی ماحول نہیں';

  @override
  String get environmentNoneForPr => 'اس پل ریکویسٹ کے لیے کوئی ماحول نہیں';

  @override
  String get environmentSetupBody =>
      'ماحول ایک ریپو کی سروسز، اسکرپٹس اور URLs کو ایک اسپیس کے لیے چلاتا ہے۔ اسے ایک بار سیٹ اپ کریں اور ریپو کی ہر اسپیس اسے شروع کر سکے گی۔';

  @override
  String get environmentSetUp => 'ماحول سیٹ اپ کریں';

  @override
  String get environmentEditDefinition => 'تعریف میں ترمیم کریں';

  @override
  String get environmentOpenPanel => 'ماحول کھولیں';

  @override
  String get environmentStatusBlocked => 'کارروائی درکار ہے';

  @override
  String get environmentStateInTerminal => 'ٹرمینل میں';

  @override
  String get environmentWaitingInTerminal => 'ٹرمینل میں آپ کا منتظر';

  @override
  String get environmentOpenTerminal => 'ٹرمینل کھولیں';

  @override
  String get environmentSignInNeeded => 'آپ کو سائن ان کرنا ہوگا';

  @override
  String get environmentDependencyNeeded => 'اس کی ایک ضروری چیز دستیاب نہیں';

  @override
  String get environmentStartTerminalDone =>
      'یہاں مکمل ہو گیا۔ ماحول اب بھی شروع ہو رہا ہے';

  @override
  String get environmentContinueInTerminal => 'ٹرمینل میں جاری رکھیں';

  @override
  String get environmentStartTerminalHint =>
      'ٹول کو پاس ورڈ یا سوال کے لیے ٹرمینل میں آپ کی ضرورت ہے۔ مکمل ہونے پر آغاز جاری رہے گا۔';

  @override
  String get environmentStartTerminalReason =>
      'یہ ٹرمینل اس لیے کھلا کیونکہ آغاز کو آپ کی ضرورت ہے';

  @override
  String get environmentStartTerminalTab => 'ماحول کا سیٹ اپ';

  @override
  String get environmentsNothingRunning => 'اس تعریف سے کچھ نہیں چل رہا۔';

  @override
  String get searchPoliciesHint => 'پالیسیاں تلاش کریں...';

  @override
  String get noPoliciesMatch => 'آپ کی تلاش سے کوئی پالیسی مماثل نہیں';

  @override
  String get memoryPolicyActive => 'فعال';

  @override
  String get memoryFactType => 'قسم';

  @override
  String get memoryTimesRecalled => 'بازیافت کی تعداد';

  @override
  String get memorySourceFacts => 'ماخذ حقائق';

  @override
  String get spaceSetupLogs => 'سیٹ اپ لاگز';

  @override
  String get claudeCompactionTitle => 'کمپیکشن';

  @override
  String get claudeCompactionDescription =>
      'Claude Code لمبی گفتگوؤں کو اپنی کانٹیکسٹ ونڈو میں کیسے رکھتا ہے۔';

  @override
  String get claudeAutoCompactLabel => 'اس کے بعد خودکار کمپیکٹ کریں';

  @override
  String claudeAutoCompactHint(String min, String max) {
    return 'ٹوکن، $min سے $max تک۔ Claude Code کی ڈیفالٹ قدر استعمال کرنے کے لیے خالی چھوڑ دیں۔';
  }

  @override
  String claudeAutoCompactInvalid(String min, String max) {
    return '$min سے $max تک کوئی عدد درج کریں۔';
  }

  @override
  String get claudeIdleCompactLabel => 'غیر فعال گفتگوئیں کمپیکٹ کریں';

  @override
  String claudeIdleCompactDescription(String threshold) {
    return '$threshold ٹوکن سے زیادہ کی گفتگو کو اس کے پرامپٹ کیش کی میعاد ختم ہونے سے ذرا پہلے کمپیکٹ کرتا ہے، تاکہ اس پر واپس آنا سستا پڑے۔ ہر کمپیکشن آپ کے پلان سے خرچ ہوتا ہے۔';
  }

  @override
  String get claudeCompactionSaveFailed => 'یہ ترتیب محفوظ نہیں ہو سکی۔';

  @override
  String get navDesktopApp => 'ڈیسک ٹاپ ایپ';

  @override
  String get desktopAppSettingsSubtitle =>
      'ٹرے آئیکن، ونڈو بند کرنا اور لاگ اِن پر کھلنا۔';

  @override
  String get desktopSectionMenuBar => 'مینو بار';

  @override
  String get desktopSectionTray => 'سسٹم ٹرے';

  @override
  String get desktopTrayTitleMac => 'مینو بار میں دکھائیں';

  @override
  String get desktopTrayTitle => 'سسٹم ٹرے میں دکھائیں';

  @override
  String get desktopTraySubtitle =>
      'اسٹیٹس، آپ کے منتظر کام، آپ کی اسپیسز اور پلان استعمال، بس ایک کلک پر۔';

  @override
  String get desktopTrayMissingTitle => 'کوئی سسٹم ٹرے نہیں ملی';

  @override
  String get desktopTrayMissingBody =>
      'یہ ڈیسک ٹاپ ٹرے آئیکن نہیں دکھاتا۔ GNOME پر AppIndicator ایکسٹینشن انسٹال کریں، پھر Control Center دوبارہ شروع کریں۔';

  @override
  String get desktopSectionClosing => 'ونڈو بند کرنا';

  @override
  String get desktopCloseTitle => 'جب آپ ونڈو بند کریں';

  @override
  String get desktopCloseKeepRunning => 'چلتا رہنے دیں';

  @override
  String get desktopCloseQuit => 'بند کریں';

  @override
  String get desktopCloseKeepRunningSubtitleMac =>
      'ایجنٹس اور اطلاعات جاری رہتی ہیں۔ ونڈو دوبارہ Dock یا مینو بار سے کھولیں۔';

  @override
  String get desktopCloseKeepRunningSubtitle =>
      'ایجنٹس اور اطلاعات جاری رہتی ہیں۔ ونڈو دوبارہ ٹرے آئیکن سے کھولیں۔';

  @override
  String get desktopCloseQuitSubtitle =>
      'ونڈو بند کرنے سے Control Center بند ہو جاتا ہے۔ دوبارہ کھولنے تک اطلاعات رک جاتی ہیں۔';

  @override
  String get desktopCloseNeedsTray =>
      'ونڈو بند ہونے پر بھی Control Center کو چلتا رکھنے کے لیے ٹرے آئیکن آن کریں۔';

  @override
  String get desktopSectionLogin => 'اسٹارٹ اپ';

  @override
  String get desktopLoginTitle => 'لاگ اِن پر کھولیں';

  @override
  String get desktopLoginSubtitle =>
      'سائن اِن کرتے ہی Control Center شروع کریں، تاکہ اطلاعات شروع سے موصول ہوں۔';

  @override
  String get desktopLoginUnsupported =>
      'یہ سسٹم لاگ اِن پر ایپس کھولنے کی سہولت نہیں دیتا۔';

  @override
  String get desktopLoginNeedsApproval =>
      'اسے آن کرنا مکمل کرنے کے لیے لاگ اِن آئٹمز میں Control Center کو اجازت دیں۔';

  @override
  String get desktopLoginOpenLoginItems => 'لاگ اِن آئٹمز کھولیں';

  @override
  String get desktopLoginRefused =>
      'سسٹم نے تبدیلی قبول نہیں کی۔ ممکن ہے آپ کا ایڈمنسٹریٹر اسے منظم کرتا ہو۔';

  @override
  String get desktopLoginStartHiddenTitle => 'پس منظر میں شروع کریں';

  @override
  String get desktopLoginStartHiddenSubtitleMac =>
      'لاگ اِن پر ونڈو کے بغیر کھلتا ہے۔ اسے Dock یا مینو بار میں تلاش کریں۔';

  @override
  String get desktopLoginStartHiddenSubtitle =>
      'لاگ اِن پر ونڈو کے بغیر کھلتا ہے۔ اسے ٹرے میں تلاش کریں۔';

  @override
  String get desktopLoginStartHiddenNeedsTray =>
      'ٹرے آئیکن درکار ہے، تاکہ ونڈو کھولنے کا کوئی راستہ ہو۔';

  @override
  String get closeToTrayPromptTitle => 'Control Center کو چلتا رہنے دیں؟';

  @override
  String get closeToTrayPromptBody =>
      'ونڈو بند ہونے پر بھی ایجنٹس کام کرتے رہتے ہیں اور اطلاعات آتی رہتی ہیں۔ اسے دوبارہ ٹرے آئیکن سے کھولیں۔ آپ اسے ترتیبات ← ڈیسک ٹاپ ایپ میں تبدیل کر سکتے ہیں۔';

  @override
  String get closeToTrayPromptQuit => 'بند کریں';

  @override
  String get closeToTrayPromptKeepRunning => 'چلتا رہنے دیں';

  @override
  String get trayStatusOffline => 'آف لائن';

  @override
  String get trayStatusReconnecting => 'دوبارہ جڑ رہا ہے…';

  @override
  String trayStatusNeedsYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count آپ کے منتظر',
      one: '1 آپ کا منتظر',
    );
    return '$_temp0';
  }

  @override
  String trayStatusWorking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کام کر رہے ہیں',
      one: '1 کام کر رہا ہے',
    );
    return '$_temp0';
  }

  @override
  String get trayStatusAllQuiet => 'سب پرسکون ہے';

  @override
  String trayTooltip(String status) {
    return 'Control Center · $status';
  }

  @override
  String trayMenuSpaceQuestions(String space, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سوالات',
      one: '1 سوال',
    );
    return '$space · $_temp0';
  }

  @override
  String trayApprovalsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count منظوریاں زیرِ التوا',
      one: '1 منظوری زیرِ التوا',
    );
    return '$_temp0';
  }

  @override
  String get trayMenuOpen => 'Control Center کھولیں';

  @override
  String get trayMenuSettings => 'ترتیبات…';

  @override
  String get trayMenuQuit => 'Control Center بند کریں';

  @override
  String get trayPanelTitle => 'Control Center';

  @override
  String get trayPanelNoWorkspace =>
      'ورک اسپیس منتخب کرنے کے لیے Control Center کھولیں۔';

  @override
  String get trayPanelOpenApp => 'Control Center کھولیں';

  @override
  String get trayPanelSettings => 'ڈیسک ٹاپ ایپ کی ترتیبات';

  @override
  String get trayPanelNeedsYou => 'آپ کے منتظر';

  @override
  String get trayPanelApprovals => 'منظوریاں';

  @override
  String get trayPanelSpaces => 'اسپیسز';

  @override
  String get trayPanelNoSpaces => 'ابھی کوئی اسپیس نہیں۔';

  @override
  String trayPanelAllSpaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تمام $count اسپیسز',
      one: 'تمام اسپیسز',
    );
    return '$_temp0';
  }

  @override
  String get trayPanelUsage => 'استعمال';

  @override
  String get trayPanelSwitchWorkspace => 'ورک اسپیس تبدیل کریں';

  @override
  String signInToProvider(String provider) {
    return '$provider میں سائن اِن کریں';
  }

  @override
  String get linearConnectAutomation => 'آٹومیشن کے لیے Linear منسلک کریں';

  @override
  String signInOpeningBrowser(String provider) {
    return 'براؤزر میں $provider کھولا جا رہا ہے…';
  }

  @override
  String get signInFailedTitle => 'سائن اِن مکمل نہیں ہوا';

  @override
  String get signInReopenPage => 'سائن اِن صفحہ دوبارہ کھولیں';

  @override
  String get signInCodePrompt =>
      'اپنے براؤزر میں تصدیق کریں، پھر جو کوڈ دکھائے وہ درج کریں۔';

  @override
  String get signInCodeMalformed =>
      'یہ سائن اِن کوڈ نہیں لگتا۔ کوڈز میں 8 حروف اور ہندسے ہوتے ہیں۔';

  @override
  String get signInCodeDeepLinkHint =>
      'اگر براؤزر Control Center کھولنے کی پیشکش کرے تو اجازت دیں، پھر کوڈ ٹائپ کرنے کی ضرورت نہیں ہوگی۔';

  @override
  String signInSucceeded(String provider, String account) {
    return '$provider میں $account کے طور پر سائن اِن ہو گیا';
  }

  @override
  String signInSucceededNoAccount(String provider) {
    return '$provider میں سائن اِن ہو گیا';
  }

  @override
  String get signInErrorExpired =>
      'اس سائن اِن کی میعاد ختم ہو گئی۔ دوبارہ شروع کریں۔';

  @override
  String signInErrorAccessDenied(String provider) {
    return '$provider سائن اِن منسوخ یا مسترد کر دیا گیا۔';
  }

  @override
  String signInErrorScopeMismatch(String provider) {
    return '$provider نے Control Center کی ضرورت سے کم اجازتیں دیں۔ دوبارہ سائن اِن کریں اور تمام اجازتیں منظور کریں۔';
  }

  @override
  String get signInErrorInvalidCode =>
      'یہ کوڈ اس سائن اِن سے میل نہیں کھاتا۔ اسے جانچیں اور دوبارہ کوشش کریں۔';

  @override
  String get signInErrorTooManyCodes =>
      'بہت زیادہ غلط کوڈ۔ سائن اِن دوبارہ شروع کریں۔';

  @override
  String get signInErrorStaleRequest =>
      'یہ سائن ان اب کھلا نہیں ہے: یہ منسوخ، استعمال، یا تبدیل ہو چکا ہے۔ اسے دوبارہ شروع کریں۔';

  @override
  String get signInErrorInvalidRequest =>
      'سرور اس سائن اِن کی درخواست نہیں پڑھ سکا۔ اسے دوبارہ شروع کریں۔';

  @override
  String get signInErrorRateLimited =>
      'ابھی درخواستیں بہت زیادہ ہیں۔ کچھ دیر انتظار کریں، پھر دوبارہ کوشش کریں۔';

  @override
  String signInErrorStoreFailed(String provider) {
    return '$provider نے سائن اِن قبول کر لیا، لیکن سرور اسے محفوظ نہیں کر سکا۔ دوبارہ کوشش کریں۔';
  }

  @override
  String signInErrorProviderUnavailable(String provider) {
    return '$provider اس وقت جواب نہیں دے رہا۔ چند منٹ بعد دوبارہ کوشش کریں۔';
  }

  @override
  String signInErrorExchangeFailed(String provider) {
    return '$provider نے سائن اِن قبول کر لیا، لیکن سرور اسے مکمل نہیں کر سکا۔ دوبارہ کوشش کریں۔';
  }

  @override
  String signInErrorMisconfigured(String provider) {
    return 'اس سرور کی $provider ایپ غلط ترتیب دی گئی ہے۔ سرور کے مالک سے ترتیبات ← سرور ← سنگل سائن آن چیک کرنے کو کہیں۔';
  }

  @override
  String signInErrorNeedsSignIn(String provider) {
    return 'آپ کا $provider سائن اِن ختم ہو گیا ہے۔ اپنے نام سے کام جاری رکھنے کے لیے دوبارہ سائن اِن کریں۔';
  }

  @override
  String signInErrorNotInstalled(String provider) {
    return '$provider ایپ وہاں انسٹال نہیں جہاں اس کی ضرورت ہے۔ اسے انسٹال کریں اور دوبارہ کوشش کریں۔';
  }

  @override
  String get signInErrorTeamBoundElsewhere =>
      'یہ Slack ورک اسپیس پہلے ہی کسی اور Control Center سرور سے منسلک ہے۔';

  @override
  String get signInErrorNotAdmin =>
      'Slack ورک اسپیس کو پہلی بار Control Center سے صرف اس کا کوئی ایڈمن یا مالک ہی جوڑ سکتا ہے۔ ان میں سے کسی سے ایپ شامل کرنے کو کہیں۔';

  @override
  String signInErrorSuspended(String provider) {
    return '$provider ایپ معطل ہے۔ $provider پر معطلی ختم کریں اور دوبارہ کوشش کریں۔';
  }

  @override
  String get signInErrorInstallBlocked =>
      'Control Center Connect نے اس سرور کو بلاک کر دیا ہے۔ اپنے Connect سرور کے آپریٹر سے رابطہ کریں۔';

  @override
  String get signInErrorUnknown =>
      'سائن اِن ایسی وجہ سے ناکام ہوا جو سرور نے نہیں بتائی۔ دوبارہ کوشش کریں۔';

  @override
  String get signInPhishingTitle => 'یہ سائن اِن یہاں سے شروع نہیں ہوا';

  @override
  String get signInPhishingBody =>
      'یہ سائن اِن اس ایپ سے شروع نہیں ہوا۔ اگر کسی نے آپ کو یہ لنک بھیجا ہے تو آگے نہ بڑھیں۔';

  @override
  String get signInPhishingDetail =>
      'کچھ نہیں بھیجا گیا۔ کسی اور کا شروع کیا ہوا سائن اِن مکمل کرنے سے آپ کا اکاؤنٹ اس کے سرور سے منسلک ہو جاتا۔';

  @override
  String signInRequiredTitle(String provider) {
    return '$provider سائن اِن درکار ہے';
  }

  @override
  String signInRequiredBody(String provider) {
    return 'یہ $provider پر آپ کے نام سے چلتا ہے، اور آپ سائن اِن نہیں ہیں۔ سائن اِن کریں، پھر دوبارہ کوشش کریں۔';
  }

  @override
  String signInRequiredBanner(String provider) {
    return 'آپ $provider میں سائن اِن نہیں ہیں۔ یہاں آپ جو بھی کرتے ہیں وہ آپ کے نام سے چلتا ہے، اس لیے پہلے سائن اِن کریں۔';
  }

  @override
  String signInUnavailable(String provider) {
    return '$provider سائن اِن ابھی اس سرور پر ترتیب نہیں دیا گیا۔';
  }

  @override
  String get githubInstallations => 'GitHub ایپ کی انسٹالیشنز';

  @override
  String get githubInstallationsDescription =>
      'GitHub ایپ کہاں انسٹال ہے، ان اکاؤنٹس میں سے جن سے اس ورک اسپیس کے ریپوزٹری تعلق رکھتے ہیں۔';

  @override
  String get githubInstallationsEmpty =>
      'GitHub ایپ ان میں سے کسی اکاؤنٹ پر انسٹال نہیں جن سے اس ورک اسپیس کے ریپوزٹری تعلق رکھتے ہیں۔';

  @override
  String get githubInstallApp => 'GitHub ایپ انسٹال کریں';

  @override
  String get githubInstallationSuspended => 'معطل';

  @override
  String get linearAutomationTitle => 'Linear آٹومیشن';

  @override
  String get linearAutomationHint =>
      'اس ورک اسپیس کے ایجنٹس اور پائپ لائنز کو Linear میں کسی شخص کی بجائے ایپ کے طور پر کام کرنے دیتا ہے۔ ورک اسپیس کے ایڈمنز اسے منسلک کرتے ہیں۔';

  @override
  String linearAutomationConnectedAs(String account) {
    return '$account سے منسلک';
  }

  @override
  String get connectModeHosted => 'Control Center کی ایپس استعمال کریں';

  @override
  String get connectModeHostedDisclosure =>
      'سائن اِن Control Center Connect کے ذریعے ہوتے ہیں۔ Connect ہر سائن اِن کو اس طرح سیل کرتا ہے کہ صرف یہی سرور اسے کھول سکے، ایک ریپوزٹری تک محدود GitHub ٹوکن جاری کرتا ہے، کوئی ریپوزٹری کلید نہیں رکھتا، اور آپ کا سورس کوڈ کبھی وصول نہیں کرتا۔';

  @override
  String get connectModeOwn => 'اپنی ایپس استعمال کریں';

  @override
  String get connectModeOwnHint =>
      'GitHub، Google اور Linear ایپس خود ترتیبات ← سرور ← سنگل سائن آن میں رجسٹر کریں، اور ہر ورک اسپیس کی اپنی Slack ایپ ورک اسپیس ← انٹیگریشنز میں جوڑیں، جہاں ورک اسپیس اپنی ایپس یا Connect بھی منتخب کر سکتا ہے۔ «میری GitHub ایپ بنائیں» GitHub کو ایک مرحلے میں ترتیب دیتا ہے۔';

  @override
  String get connectModeCustom => 'اپنا Connect سرور استعمال کریں';

  @override
  String get connectModeCustomHint =>
      'آپ کی تنظیم اپنا Connect سرور چلاتی ہے۔ سائن اِن Control Center کے سرور کی بجائے وہاں جاتے ہیں۔';

  @override
  String get connectModeUnset => 'ابھی ترتیب نہیں دیا گیا';

  @override
  String get connectCustomUrlLabel => 'Connect سرور کا URL';

  @override
  String get connectCustomUrlInvalid =>
      'HTTPS پتہ درج کریں، جیسے https://connect.example.com۔';

  @override
  String get connectCustomUrlLoopbackHint =>
      'سادہ ⁨HTTP⁩ صرف اسی مشین پر موجود Connect تک پہنچتا ہے۔ نیٹ ورک پر کسی بھی چیز کے لیے ⁨HTTPS⁩ استعمال کریں۔';

  @override
  String get connectErrorHostedUnprovisioned =>
      'Control Center کی ہوسٹڈ ایپس ابھی اس بلڈ میں دستیاب نہیں۔ اپنی ایپس یا اپنا Connect سرور استعمال کریں۔';

  @override
  String get connectErrorSignature =>
      'Connect کی کنفیگریشن دستخط کی جانچ میں ناکام رہی۔ Connect کے ذریعے سائن اِن دوبارہ تصدیق تک روک دیے گئے ہیں۔';

  @override
  String get connectErrorRollback =>
      'Connect نے اس سے پرانی کنفیگریشن دی جو یہ سرور پہلے دیکھ چکا ہے، اس لیے اسے مسترد کر دیا گیا۔ Connect کے ذریعے سائن اِن روک دیے گئے ہیں۔';

  @override
  String get connectErrorUnreachable =>
      'یہ سرور اس وقت Connect تک نہیں پہنچ پا رہا۔ اسے استعمال کرنے والے سائن اِن اس کی واپسی تک ناکام ہوں گے۔';

  @override
  String get connectErrorInstallBlocked =>
      'Connect نے اس سرور کی انسٹال آئی ڈی بلاک کر دی ہے۔ اپنے Connect سرور کے آپریٹر سے رابطہ کریں۔';

  @override
  String get connectErrorPinsChanged => 'Connect کی ایپس بدل گئی ہیں';

  @override
  String get connectErrorProtocol =>
      'Connect نے ایسا جواب دیا جو یہ سرور نہیں سمجھتا۔ سرور اپ ڈیٹ کریں یا Connect کا URL چیک کریں۔';

  @override
  String get connectErrorUnknown =>
      'Connect نے بغیر وضاحت کے ایک مسئلہ رپورٹ کیا۔ دوبارہ کوشش کے لیے ٹیسٹ چلائیں۔';

  @override
  String get connectPinsConfirmHint =>
      'آپ کا Connect سرور اب ان سے مختلف GitHub، Google، Linear یا Slack ایپس بتا رہا ہے جو اس سرور نے پہلی بار استعمال پر پن کی تھیں۔ ان پر صرف تب بھروسہ کریں جب اس کے آپریٹر نے آپ کو پہلے سے بتایا ہو۔';

  @override
  String get connectConfirmPins => 'نئی ایپس پر بھروسہ کریں';

  @override
  String get connectStale =>
      'زیرِ استعمال کنفیگریشن توقع سے پرانی ہے۔ اسے تازہ کرنے کے لیے ٹیسٹ چلائیں۔';

  @override
  String get connectLaneSourceOwn => 'اپنی ایپ';

  @override
  String get connectLaneSourceConnect => 'Connect';

  @override
  String get connectLaneSourceOff => 'بند';

  @override
  String get connectTitle => 'Control Center Connect';

  @override
  String get connectDescription =>
      'یہ سرور GitHub، Google Calendar، Linear، Slack اور GIF تلاش کے لیے کس کی ایپس استعمال کرتا ہے۔';

  @override
  String get connectFactMode => 'سائن اِن ایپس';

  @override
  String get connectFactHealth => 'حالت';

  @override
  String get connectFactEpoch => 'کنفیگریشن ورژن';

  @override
  String get connectHealthOff => 'استعمال میں نہیں';

  @override
  String get connectHealthOk => 'کام کر رہا ہے';

  @override
  String get connectHealthDown => 'کام نہیں کر رہا';

  @override
  String get connectLocked =>
      'اسے اس سرور کے ماحول میں CC_CONNECT_URL طے کرتا ہے۔ اسے وہیں بدلیں اور سرور دوبارہ شروع کریں۔';

  @override
  String get connectLanesTitle => 'ہر سائن اِن کہاں چلتا ہے';

  @override
  String get connectLanesDescription =>
      'اپنی ایپ کو اپنے فراہم کنندہ کے لیے ہمیشہ Connect پر ترجیح حاصل ہوتی ہے۔';

  @override
  String get connectServerGroup => 'یہ سرور';

  @override
  String get connectInstallId => 'انسٹال آئی ڈی';

  @override
  String get connectInstallIdHint =>
      'اس سرور کی Connect کے سامنے شناخت کرتی ہے۔ مانگنے پر اسے تنظیم کے مالک یا Connect آپریٹر کو دیں۔';

  @override
  String get connectInstallIdEmpty =>
      'جب یہ سرور پہلی بار Connect استعمال کرے گا تب تفویض ہوگی۔';

  @override
  String get connectTestOk => 'Connect کام کر رہا ہے۔';

  @override
  String get connectRotateKey => 'کلید بدلیں';

  @override
  String get connectRotateKeyTitle => 'اس سرور کی Connect کلید بدلیں؟';

  @override
  String get connectRotateKeyBody =>
      'اس سرور کو نئی کلید اور نئی انسٹال آئی ڈی ملتی ہے، اور پرانی آئی ڈی Connect پر ریٹائر ہو جاتی ہے: اس کے تحت جاری سائن ان، اور پرانی کلید وہاں کام کرنا بند کر دیتی ہے، اس لیے Connect کے ذریعے سائن ان کرنے والے سب کو دوبارہ سائن ان کرنا ہوگا۔ جو ٹوکن پہلے جاری ہو چکے ہیں وہ ختم ہونے تک چلتے رہیں گے۔ آپ کی اپنی ایپس کے ذریعے سائن ان متاثر نہیں ہوتے۔ اگر Connect تک رسائی نہ ہو تو کچھ نہیں بدلتا اور آپ دوبارہ کوشش کر سکتے ہیں۔';

  @override
  String get connectRotateKeyDone =>
      'کلید بدل دی گئی۔ Connect کے ذریعے سائن اِن کرنے والے ہر شخص کو دوبارہ سائن اِن کرنا ہوگا۔';

  @override
  String get connectCliLabel => 'ٹرمینل سے';

  @override
  String get onboardingStepSignIn => 'سائن اِن';

  @override
  String get onboardingConnectTitle => 'منتخب کریں کہ لوگ کیسے سائن اِن کریں';

  @override
  String get onboardingConnectSubtitle =>
      'Control Center ہر فراہم کنندہ کے پاس رجسٹرڈ ایپس کے ذریعے GitHub، Google Calendar، Linear، Slack اور GIF تلاش کے ساتھ کام کرتا ہے۔ منتخب کریں کہ یہ سرور کس کی ایپس استعمال کرے۔ آپ اسے بعد میں ترتیبات ← سرور ← سنگل سائن آن میں بدل سکتے ہیں۔';

  @override
  String get onboardingConnectOwnNext =>
      'ابھی اس سرور کے لیے GitHub ایپ بنائیں، یا اپنی ایپس بعد میں ترتیبات ← سرور ← سنگل سائن آن میں شامل کریں۔';

  @override
  String get providerServiceApiKey => 'سروس API کلید';

  @override
  String get providerAppPartial => 'سیٹ اپ مکمل نہیں ہوا';

  @override
  String providerAppMissingFields(String fields) {
    return 'ابھی کمی ہے: $fields۔ جب تک تمام خانے پُر نہ ہوں، اس فراہم کنندہ کے سائن اِن Connect سے گزرنے کی بجائے مسترد کر دیے جاتے ہیں۔';
  }

  @override
  String get providerAppsGroupSignInLinearDescription =>
      'کلائنٹ آئی ڈی اراکین کو سائن اِن کرتی ہے۔ سروس API کلید اس سرور کو Linear میں خود پڑھنے اور لکھنے دیتی ہے۔';

  @override
  String get providerCallbackUrls => 'کال بیک URLs';

  @override
  String get providerCallbackUrlHint =>
      'اسے فراہم کنندہ کے پاس بالکل اسی طرح رجسٹر کریں جیسا دکھایا گیا ہے۔';

  @override
  String get providerAppCreateGitHubTitle => 'GitHub ایپ بنائیں';

  @override
  String get providerAppCreateGitHubHint =>
      'GitHub درست اجازتوں اور کال بیک کے ساتھ ایک ایپ رجسٹر کرتا ہے، پھر اس کی اسناد اس سرور کے حوالے کرتا ہے۔ ہاتھ سے کچھ کاپی نہیں کرنا۔';

  @override
  String get providerAppCreateGitHub => 'میری GitHub ایپ بنائیں';

  @override
  String get providerAppCreateGitHubOrg => 'تنظیم (اختیاری)';

  @override
  String get providerAppCreateGitHubOrgHint =>
      'ایپ اپنے GitHub اکاؤنٹ کے تحت بنانے کے لیے خالی چھوڑ دیں۔ کسی تنظیم کے تحت بنانے کے لیے اس تنظیم کا مالک ہونا ضروری ہے۔';

  @override
  String get providerAppSignInReady => 'لوگ سائن اِن کر سکتے ہیں۔';

  @override
  String get chatLinkWaiting => 'آپ کے براہِ راست پیغام کا انتظار ہے…';

  @override
  String chatLinkClaimTitle(String provider) {
    return 'کیا یہ آپ کا ⁨$provider⁩ اکاؤنٹ ہے؟';
  }

  @override
  String chatLinkClaimBody(String provider) {
    return 'اس اکاؤنٹ نے آپ کا کوڈ بوٹ کو بھیجا ہے۔ صرف تب تصدیق کریں جب یہ آپ کا ہو: لنک ہونے کے بعد یہ ⁨$provider⁩ میں جو بھیجے گا وہ اس ورک اسپیس میں آپ کے طور پر کام کرے گا۔';
  }

  @override
  String get chatLinkDecline => 'مسترد کریں';

  @override
  String chatLinkDeclined(String provider) {
    return 'کچھ بھی لنک نہیں ہوا۔ اگر آپ اب بھی اپنا ⁨$provider⁩ اکاؤنٹ لنک کرنا چاہتے ہیں تو نیا کوڈ لیں۔';
  }

  @override
  String get chatLinkNewCode => 'نیا کوڈ لیں';

  @override
  String signInAddControlCenter(String provider) {
    return '⁨$provider⁩ میں Control Center شامل کریں';
  }

  @override
  String signInAddedControlCenter(String workspace) {
    return 'Control Center کو ⁨$workspace⁩ میں شامل کر دیا گیا';
  }

  @override
  String chatSharedAppHint(String provider) {
    return 'مشترکہ Control Center ایپ آپ کی ⁨$provider⁩ ورک اسپیس میں انسٹال کرتا ہے۔ نہ کوئی ایپ بنانی ہے نہ کوئی ٹوکن چسپاں کرنا ہے۔';
  }

  @override
  String chatAddToProvider(String provider) {
    return '⁨$provider⁩ میں شامل کریں';
  }

  @override
  String get chatSharedAppConnected =>
      'مشترکہ Control Center ایپ پر چلتا ہے، اس لیے یہاں سنبھالنے کے لیے کوئی ٹوکن یا بوٹ ترتیبات نہیں ہیں۔';

  @override
  String get chatTicketDraftsTitle => 'چیٹ سے ٹکٹ کے مسودے';

  @override
  String get chatTicketDraftsDescription =>
      'مسودہ صرف تب بیک لاگ کا ٹکٹ بنتا ہے جب آپ اسے یہاں بنائیں۔ چھوڑے گئے مسودے ایک دن بعد ہٹا دیے جاتے ہیں۔';

  @override
  String chatTicketDraftFrom(String provider) {
    return '⁨$provider⁩ سے';
  }

  @override
  String get chatTicketDraftCreate => 'ٹکٹ بنائیں';

  @override
  String chatTicketDraftCreated(String key) {
    return '⁨$key⁩ بن گیا';
  }

  @override
  String workspaceProviderAppMissingFields(String fields) {
    return 'ابھی باقی ہے: $fields۔ جب تک تمام فیلڈز مکمل نہ ہوں، یہ پرووائیڈر اس ورک اسپیس میں بند رہتا ہے۔ یہ اس سرور کی ایپ پر واپس نہیں جاتا۔';
  }

  @override
  String get workspaceProviderAppClientChangeHint =>
      'ایپ بدلنے سے اس ورک اسپیس کے ہر فرد کا سائن آؤٹ ہو جاتا ہے۔ وہ نئی ایپ سے دوبارہ سائن ان کریں گے۔';

  @override
  String get workspaceProviderAppKlipyKey => 'ایپ کلید';

  @override
  String get workspaceProviderAppKlipyHint =>
      'اس ورک اسپیس میں GIF سرچ اسی کلید سے ہوتی ہے۔';

  @override
  String get settingsWorkspaceIntegrations => 'انٹیگریشنز';

  @override
  String get settingsWorkspaceIntegrationsDescription =>
      'اس ورک اسپیس میں کوڈ ہوسٹنگ، ٹکٹس، کیلنڈر، چیٹ اور GIF سرچ، اور وہ کن ایپس کے ذریعے سائن ان کرتے ہیں۔';

  @override
  String get workspaceConnectDescription =>
      'یہ ورک اسپیس GitHub، Google Calendar، Linear، Slack اور GIF سرچ کے لیے کون سی ایپس استعمال کرتا ہے۔ جب تک کوئی ایڈمن کچھ اور منتخب نہ کرے، یہ اس سرور کی پیروی کرتا ہے۔';

  @override
  String get workspaceConnectModeInherit => 'اس سرور جیسا';

  @override
  String get workspaceConnectInheritHosted =>
      'یہ سرور Control Center کی ایپس استعمال کرتا ہے۔';

  @override
  String workspaceConnectInheritCustom(String url) {
    return 'یہ سرور $url پر موجود Connect سرور استعمال کرتا ہے۔';
  }

  @override
  String get workspaceConnectInheritOwn => 'یہ سرور اپنی ایپس استعمال کرتا ہے۔';

  @override
  String get workspaceConnectInheritUnset =>
      'سرور کے مالک نے ابھی انتخاب نہیں کیا، اس لیے سرور کی اپنی ایپس لاگو ہوتی ہیں۔';

  @override
  String get workspaceConnectOwnHint =>
      'صرف اس ورک اسپیس کی ایپس استعمال ہوتی ہیں۔ ہر ایک کو نیچے اس کے فراہم کنندہ کے ساتھ شامل کریں۔ جس فراہم کنندہ کی ایپ نہ ہو وہ یہاں بند ہے؛ اس سرور کی ایپس یا Connect اس کی جگہ استعمال نہیں ہوتے۔';

  @override
  String get workspaceConnectCustomUrlHint =>
      'صرف HTTPS۔ نجی یا مقامی نیٹ ورک کے پتے مسترد کیے جاتے ہیں۔';

  @override
  String get workspaceConnectLocked =>
      'اس سرور کے ماحول میں CC_CONNECT_URL طے کرتا ہے کہ سائن ان کہاں جائیں گے، اس لیے یہ ورک اسپیس اپنا Connect منتخب نہیں کر سکتا۔ یہ اس سرور کی پیروی کر سکتا ہے یا اپنی ایپس استعمال کر سکتا ہے۔';

  @override
  String get workspaceConnectSwitchTitle =>
      'اس ورک اسپیس کی سائن ان ایپس تبدیل کریں؟';

  @override
  String get workspaceConnectSwitchBody =>
      'ورک اسپیس میں سب کو نئی ایپس کے ذریعے GitHub، Linear اور Google Calendar میں دوبارہ سائن ان کرنا ہوگا۔ موجودہ ایپس کے ذریعے کیے گئے سائن ان یہاں کام کرنا بند کر دیں گے۔';

  @override
  String get workspaceConnectSwitchAction => 'ایپس تبدیل کریں';

  @override
  String get workspaceConnectLanesDescription =>
      'اوپر والے انتخاب کی پیروی کرتا ہے۔ کوئی فراہم کنندہ کبھی کسی دوسری ایپ پر واپس نہیں جاتا۔';

  @override
  String get workspaceConnectLaneWorkspaceOwn => 'ورک اسپیس کی ایپ';

  @override
  String get workspaceConnectLaneServerOwn => 'سرور کی ایپ';

  @override
  String get workspaceGitHubAppTitle => 'GitHub ایپ';

  @override
  String get workspaceGitHubAppOwnDescription =>
      'اس ورک اسپیس کی اپنی App اس کے ریپوزٹریز کی طرف سے کام کرتی ہے اور ممبران کو سائن ان کرواتی ہے۔ یہ کبھی اس سرور کی App یا Connect پر واپس نہیں جاتی۔';

  @override
  String get workspaceGitHubAppSharedDescription =>
      'یہ ورک اسپیس اس GitHub App کو استعمال کرتا ہے جو اس کی سائن ان ایپس فراہم کرتی ہیں۔ اسے ان اکاؤنٹس پر انسٹال کریں جن کے آپ کے ریپوزٹریز ہیں۔';

  @override
  String get workspaceGitHubAppActingTitle => 'اس ورک اسپیس کی طرف سے کام کرنا';

  @override
  String get workspaceGitHubAppActingDescription =>
      'App کا بوٹ اس ورک اسپیس کے ریپوزٹریز میں pull requests پر تبصرے کرتا، ان کا جائزہ لیتا اور ان کے لیے پولنگ کرتا ہے۔';

  @override
  String workspaceOwnAppTitle(String provider) {
    return '$provider ایپ';
  }

  @override
  String workspaceOwnAppDescription(String provider) {
    return 'اس ورک اسپیس میں $provider کے سائن ان اور درخواستیں صرف اسی ایپ کو استعمال کرتے ہیں۔';
  }

  @override
  String get workspaceGifsTitle => 'GIFs';

  @override
  String get workspaceGifsSourceWorkspaceOwn =>
      'GIF سرچ اس ورک اسپیس کی Klipy کلید استعمال کرتی ہے۔';

  @override
  String get workspaceGifsSourceServerOwn =>
      'GIF سرچ اس سرور کی Klipy کلید استعمال کرتی ہے۔';

  @override
  String get workspaceGifsSourceConnect =>
      'GIF سرچ Control Center Connect کے ذریعے چلتی ہے۔';

  @override
  String get workspaceGifsSourceOff => 'اس ورک اسپیس میں GIF سرچ بند ہے۔';

  @override
  String openOnForge(String forge) {
    return '$forge پر کھولیں';
  }

  @override
  String prFilesTruncatedNotice(String forge, int count) {
    return 'پہلی $count فائلیں دکھائی جا رہی ہیں۔ $forge باقی فائلوں کی فہرست نہیں دیتا۔';
  }

  @override
  String get connectForgeToLoadPrs =>
      'پل ریکویسٹس لوڈ کرنے کے لیے کوڈ ہوسٹ منسلک کریں';

  @override
  String get connectForgeHint =>
      'ترتیبات ← آپ ← پروفائل میں GitHub، GitLab یا Bitbucket منسلک کریں';

  @override
  String get addForgeRepoPrompt =>
      'پل ریکویسٹس دیکھنے کے لیے GitHub، GitLab یا Bitbucket پر کم از کم ایک ریپوزٹری شامل کریں';

  @override
  String get composePrNoForgeRepo => 'کوئی ہوسٹ شدہ ریپوزٹری منتخب نہیں';

  @override
  String get composePrNoForgeRepoHint =>
      'پل ریکویسٹ کھولنے کے لیے ایسی ورک اسپیس منتخب کریں جس میں GitHub، GitLab یا Bitbucket پر ریپوزٹری ہو۔';

  @override
  String composePrForgeNotConnected(String forge) {
    return 'اس ریپوزٹری میں پل ریکویسٹ کھولنے کے لیے $forge منسلک کریں';
  }

  @override
  String connectionNeedsSignInAs(String provider, String account) {
    return '$account کے طور پر آپ کا $provider سائن اِن ختم ہو گیا ہے۔ دوبارہ سائن اِن کریں۔';
  }

  @override
  String get connectionPaused =>
      'موقوف: اس ورک اسپیس کی سائن اِن سروس بدل گئی ہے';

  @override
  String connectionUnreachable(String provider) {
    return 'ابھی $provider تک رسائی نہیں ہو پا رہی۔ دوبارہ کوشش کی جا رہی ہے۔';
  }

  @override
  String get forgeSignInBannerPausedBody =>
      'آپ کا سائن اِن محفوظ ہے اور سروس واپس آتے ہی دوبارہ کام کرے گا۔ ورک اسپیس کا کوئی ایڈمن انٹیگریشنز میں سائن اِن سیٹ اپ دیکھ سکتا ہے۔';

  @override
  String get signInErrorAttemptUnknown =>
      'سرور دوبارہ شروع ہو گیا۔ سائن اِن دوبارہ شروع کریں۔';

  @override
  String signInUnavailableNotConfigured(String provider) {
    return 'اس ورک اسپیس کے لیے $provider سائن اِن سیٹ اپ نہیں ہے۔';
  }

  @override
  String signInUnavailableMisconfigured(String provider, String error) {
    return '$provider سائن اِن غلط سیٹ اپ ہے: $error';
  }

  @override
  String signInUnavailableOwnAppMissing(String provider) {
    return 'یہ ورک اسپیس اپنی ایپس استعمال کرتی ہے لیکن اس کے پاس $provider ایپ نہیں ہے۔';
  }

  @override
  String signInUnavailableConnectUnprovisioned(String provider) {
    return 'یہ بِلڈ Control Center Connect کی تصدیق نہیں کر سکتی، اس لیے $provider سائن اِن بند ہے۔';
  }

  @override
  String get signInUnavailableConnectPinsPending =>
      'اس ورک اسپیس کی سائن اِن سروس نے اپنی شناخت بدل لی ہے۔ کسی ایڈمن کو اس کی تصدیق کرنی ہوگی۔';

  @override
  String get signInUnavailableConnectUnreachable =>
      'ابھی اس ورک اسپیس کی سائن اِن سروس تک رسائی نہیں ہو پا رہی۔';

  @override
  String get signInUnavailableConnectUrlInvalid =>
      'اس ورک اسپیس کی سائن اِن سروس کا پتہ موجود نہیں یا غلط ہے۔';

  @override
  String get signInUnavailableBlockedByEnvironment =>
      'سرور کے آپریٹر نے سائن اِن سروس مقرر کر دی ہے، اس لیے اس ورک اسپیس کا اپنا انتخاب لاگو نہیں ہوتا۔';

  @override
  String signInUnavailableLaneNotOffered(String provider) {
    return 'اس ورک اسپیس کی سائن اِن سروس $provider فراہم نہیں کرتی۔';
  }

  @override
  String get signInOpenIntegrations => 'انٹیگریشنز کھولیں';

  @override
  String get signInOpenServerSettings => 'سائن اِن کی ترتیبات کھولیں';

  @override
  String forgeTokenRequiredBody(String provider) {
    return 'یہ $provider پر آپ کے نام سے چلتا ہے، اور آپ نے ٹوکن شامل نہیں کیا۔ ایک ٹوکن شامل کریں، پھر دوبارہ کوشش کریں۔';
  }

  @override
  String disconnectProviderTitle(String provider) {
    return '$provider منقطع کریں؟';
  }

  @override
  String disconnectProviderBody(String provider) {
    return '$provider کی ریپوزٹریز پر کام کرنے کے لیے آپ کو اسے دوبارہ جوڑنا ہوگا۔';
  }

  @override
  String disconnectScopeWorkspaceBody(String provider) {
    return 'یہ $provider کو صرف اس ورک اسپیس میں منقطع کرتا ہے۔ دوسری ورک اسپیسز اپنا کنکشن رکھتی ہیں۔';
  }

  @override
  String disconnectScopeGlobalBody(String provider) {
    return 'یہ $provider کو ہر اس ورک اسپیس میں منقطع کرتا ہے جو یہ کنکشن شیئر کرتی ہے۔';
  }

  @override
  String disconnectedFromWorkspace(String provider) {
    return '$provider اس ورک اسپیس سے منقطع ہو گیا';
  }

  @override
  String disconnectedFromAllWorkspaces(String provider) {
    return '$provider تمام ورک اسپیسز سے منقطع ہو گیا';
  }

  @override
  String repoAccessInstallTitle(String owner) {
    return '$owner پر GitHub App انسٹال کریں';
  }

  @override
  String repoAccessInstallBody(String repos) {
    return 'جب تک وہاں ایپ انسٹال نہ ہو، آٹومیشن $repos تک نہیں پہنچ سکتی۔';
  }

  @override
  String repoAccessSelectTitle(String repos) {
    return '$repos کو GitHub App کی ریپوزٹریز میں شامل کریں';
  }

  @override
  String get repoAccessSelectBody =>
      'ایپ اس اکاؤنٹ پر انسٹال ہے لیکن ابھی یہ ریپوزٹریز نہیں دیکھ سکتی۔';

  @override
  String get repoAccessChooseRepos => 'ریپوزٹریز منتخب کریں';

  @override
  String get repoAccessSuspendedTitle => 'GitHub App انسٹالیشن معطل ہے';

  @override
  String repoAccessSuspendedBody(String repos) {
    return '$repos کے لیے آٹومیشن اس وقت تک موقوف ہے جب تک اکاؤنٹ کا کوئی مالک GitHub پر انسٹالیشن دوبارہ شروع نہ کرے۔';
  }

  @override
  String get repoAccessAutomationPausedTitle => 'آٹومیشن موقوف ہے';

  @override
  String repoAccessOwnerCannotSeeBody(String repos) {
    return 'اس ورک اسپیس کی آٹومیشن کا ذمہ دار شخص اب $repos نہیں دیکھ سکتا، اس لیے وہاں ان کی طرف سے کچھ نہیں چلتا۔';
  }

  @override
  String repoAccessOwnerNotSignedInBody(String repos) {
    return 'اس ورک اسپیس کی آٹومیشن کا ذمہ دار شخص فورج میں سائن اِن نہیں ہے، اس لیے $repos کی آٹومیشن ان کے سائن اِن کرنے تک انتظار کرتی ہے۔';
  }

  @override
  String repoAccessTransient(String repos) {
    return '$repos تک رسائی کی جانچ نہیں ہو سکی۔ دوبارہ کوشش کی جا رہی ہے۔';
  }

  @override
  String repoAccessAskAdmins(String admins) {
    return 'اسے ٹھیک کرنے کے لیے $admins سے کہیں۔';
  }

  @override
  String get repoAccessAskAnAdmin =>
      'اسے ٹھیک کرنے کے لیے ورک اسپیس کے کسی ایڈمن سے کہیں۔';

  @override
  String hiddenReposSignIn(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'مزید $count ریپوزٹریز کی pull requests دیکھنے کے لیے $forge میں سائن اِن کریں',
      one:
          'مزید 1 ریپوزٹری کی pull requests دیکھنے کے لیے $forge میں سائن اِن کریں',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoForgeAccess(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count ریپوزٹریز چھپی ہوئی ہیں کیونکہ آپ کا $forge اکاؤنٹ انہیں نہیں دیکھ سکتا',
      one:
          '1 ریپوزٹری چھپی ہوئی ہے کیونکہ آپ کا $forge اکاؤنٹ اسے نہیں دیکھ سکتا',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoGrant(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count ریپوزٹریز چھپی ہوئی ہیں کیونکہ اس ورک اسپیس میں آپ کو ان تک رسائی نہیں',
      one:
          '1 ریپوزٹری چھپی ہوئی ہے کیونکہ اس ورک اسپیس میں آپ کو اس تک رسائی نہیں',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposChecking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'مزید $count ریپوزٹریز تک آپ کی رسائی جانچی جا رہی ہے…',
      one: 'مزید 1 ریپوزٹری تک آپ کی رسائی جانچی جا رہی ہے…',
    );
    return '$_temp0';
  }

  @override
  String get repoLinkAccessWarningsTitle =>
      'لنک ہو گیا، لیکن آٹومیشن ابھی ہر جگہ نہیں پہنچ سکتی';

  @override
  String get githubInstallOnAnotherOrganization =>
      'کسی اور تنظیم پر انسٹال کریں';

  @override
  String get forgeTokenEmailLabel => 'Atlassian اکاؤنٹ کی ای میل';

  @override
  String get forgeTokenEmailInvalid =>
      'اپنے Atlassian اکاؤنٹ کا ای میل پتہ درج کریں۔';

  @override
  String get forgeTokenApiTokenLabel => 'API ٹوکن';

  @override
  String get forgeTokenBitbucketHint =>
      'Bitbucket کے API ٹوکن انہیں بنانے والے Atlassian اکاؤنٹ کی ای میل کے ساتھ کام کرتے ہیں۔';

  @override
  String get automationTokensTitle => 'آٹومیشن ٹوکنز';

  @override
  String get automationTokensRepoHint =>
      'GitLab اور Bitbucket پر پس منظر کا کام، جیسے پل ریکویسٹ کی اپ ڈیٹس، AI ریویو کے تبصرے اور ایسی مرج ریکویسٹس جو کسی نے نہیں مانگیں، ایک بوٹ کا رسائی ٹوکن استعمال کرتا ہے، کبھی کسی شخص کا نہیں۔ ریپوزٹری کا اپنا ٹوکن ورک اسپیس کے ٹوکن پر فوقیت رکھتا ہے۔';

  @override
  String get automationTokensWorkspaceHint =>
      'اس ورک اسپیس کی ہر اس GitLab یا Bitbucket ریپوزٹری کے لیے استعمال ہوتا ہے جس کا اپنا آٹومیشن ٹوکن نہیں۔ وہاں پس منظر کا کام اس ٹوکن کے بوٹ کے طور پر دکھایا جاتا ہے۔';

  @override
  String get automationTokenNone => 'کوئی ٹوکن نہیں۔ یہاں آٹومیشن موقوف ہے۔';

  @override
  String get automationTokenFromWorkspace =>
      'ورک اسپیس کا ٹوکن استعمال کرتا ہے';

  @override
  String automationTokenActsAs(String name) {
    return '$name کے طور پر کام کرتا ہے';
  }

  @override
  String get automationTokenStored => 'رسائی ٹوکن شامل کر دیا گیا';

  @override
  String get automationTokenRejected =>
      'پلیٹ فارم نے یہ ٹوکن مسترد کر دیا۔ اسے بدلیں۔';

  @override
  String automationTokenDialogTitle(String forge) {
    return '$forge آٹومیشن ٹوکن';
  }

  @override
  String get automationTokenGitLabHint =>
      'پروجیکٹ یا گروپ رسائی ٹوکن پیسٹ کریں۔ اسے read_api اور read_repository درکار ہیں؛ تبصروں، مرج ریکویسٹس اور پُش کے لیے api اور write_repository شامل کریں۔ GitLab اس کا کام ٹوکن کے بوٹ کے طور پر دکھاتا ہے۔';

  @override
  String get automationTokenBitbucketHint =>
      'ریپوزٹری، پروجیکٹ یا ورک اسپیس کا رسائی ٹوکن پیسٹ کریں جس میں ریپوزٹری پڑھنے کی اجازت ہو، اور تبصروں اور پل ریکویسٹس کے لیے پل ریکویسٹ لکھنے کی اجازت بھی۔ آپ کا اپنا API ٹوکن یہاں نہیں بلکہ ترتیبات ← آپ ← پروفائل میں جاتا ہے۔';

  @override
  String automationTokenUnreadable(String repos) {
    return 'ٹوکن محفوظ ہو گیا، لیکن یہ $repos نہیں پڑھ سکتا۔ وہاں آٹومیشن موقوف رہے گی۔';
  }

  @override
  String get automationTokenRemoveTitle => 'آٹومیشن ٹوکن ہٹائیں؟';

  @override
  String get automationTokenRemoveBody =>
      'اس ٹوکن پر منحصر آٹومیشن اس وقت تک موقوف رہے گی جب تک کوئی دوسرا ٹوکن شامل نہ کیا جائے۔';

  @override
  String automationTokenWorkspaceTarget(String forge) {
    return 'اپنے ٹوکن کے بغیر ہر $forge ریپوزٹری';
  }

  @override
  String repoAccessAutomationTokenMissingBody(String repos) {
    return 'کوئی آٹومیشن ٹوکن $repos نہیں پڑھ سکتا، اس لیے وہاں پس منظر کا کام موقوف ہے۔';
  }

  @override
  String get settingsCommitsDescription =>
      'آپ کے شروع کردہ کام کی کمیٹس میں آپ کا نام ہوتا ہے۔ منتخب کریں کہ اور کن کو کریڈٹ ملے، اور فورجز آپ کی کمیٹس کو تصدیق شدہ دکھائیں یا نہیں۔';

  @override
  String get settingsCommitAuthorshipSection => 'مصنفیت';

  @override
  String get settingsCommitAuthorshipYoursLabel => 'آپ کا شروع کردہ کام';

  @override
  String get settingsCommitAuthorshipYoursBody =>
      'آپ مصنف اور کمیٹر ہیں، اس ای میل کے تحت جو آپ کے سائن ان کے لیے آپ کے فورج نے تصدیق کی ہو۔ اس میں ایجنٹس کے ساتھ چیٹس، آپ کی شروع کردہ پائپ لائنز، اور ایڈیٹر میں آپ کی کی گئی کمیٹس شامل ہیں۔';

  @override
  String get settingsCommitAuthorshipBotLabel => 'خودکار رنز';

  @override
  String get settingsCommitAuthorshipBotBody =>
      'شیڈول یا webhook سے شروع ہونے والے رنز بوٹ کے طور پر کمیٹ ہوتے ہیں، اور کبھی سائن نہیں ہوتے۔';

  @override
  String get settingsCommitAuthorshipSignInNote =>
      'جب تک آپ کسی ورک اسپیس میں کسی فورج پر سائن ان نہیں کرتے، وہاں آپ کے رنز بوٹ کے طور پر کمیٹ ہوں گے۔';

  @override
  String get settingsCoauthorCreditTitle =>
      'Control Center کو شریک مصنف کے طور پر کریڈٹ دیں';

  @override
  String get settingsCoauthorCreditDescription =>
      'آپ کی کمیٹس Control Center (@usectrl) کو شریک مصنف کے طور پر ظاہر کرتی ہیں، اور جن خودکار رنز کو آپ نے فعال کیا ہو وہ آپ کا نام ظاہر کرتے ہیں۔ بند ہونے پر دونوں میں سے کوئی سطر شامل نہیں ہوتی۔';

  @override
  String get settingsCoauthorCreditWorkspaceOverride =>
      'اس ورک اسپیس کی ترتیب آپ کے ذاتی انتخاب پر فوقیت رکھتی ہے۔ آپ کی ترجیح محفوظ ہے مگر یہاں لاگو نہیں ہوتی۔';

  @override
  String get settingsCoauthorCreditLoading => 'نسبت کی ترتیبات لوڈ ہو رہی ہیں…';

  @override
  String get settingsWorkspaceCoauthorCreditTitle => 'شریک مصنف کا کریڈٹ';

  @override
  String get settingsWorkspaceCoauthorCreditDescription =>
      'کمیٹس میں شریک مصنف کی سطریں ہوں گی یا نہیں: ممبر کی اپنی کمیٹس پر Control Center، اور وہ ممبرز جنہوں نے اپنی کمیٹس پر خودکار رن فعال کیا ہو۔ یہاں کا انتخاب ہر ممبر کی اپنی ترجیح پر غالب آتا ہے۔';

  @override
  String get settingsWorkspaceCoauthorCreditInherit =>
      'ہر رکن کی ترجیح استعمال کریں';

  @override
  String get settingsWorkspaceCoauthorCreditAlways =>
      'ہمیشہ شریک مصنف کا کریڈٹ شامل کریں';

  @override
  String get settingsWorkspaceCoauthorCreditNever =>
      'کبھی شریک مصنف کا کریڈٹ شامل نہ کریں';

  @override
  String get settingsCommitSigningSection => 'تصدیق شدہ کمیٹس';

  @override
  String get settingsCommitSigningStatusOn => 'سائننگ';

  @override
  String get settingsCommitSigningStatusOff => 'سائن نہیں ہو رہا';

  @override
  String get settingsCommitSigningIntro =>
      'یہ سرور آپ کی کمیٹس کو آپ کی اپنی کلید سے سائن کر سکتا ہے، تاکہ GitHub اور GitLab انہیں تصدیق شدہ دکھائیں۔ جب تک آپ کلید نہ بنائیں، کچھ بھی سائن نہیں ہوتا۔';

  @override
  String get settingsCommitSigningCreate => 'سائننگ کلید بنائیں';

  @override
  String get settingsCommitSigningCreated =>
      'سائننگ کلید بن گئی۔ اسے اپنے فورج اکاؤنٹ میں شامل کریں۔';

  @override
  String get settingsCommitSigningPublicKeyLabel => 'پبلک کلید';

  @override
  String get settingsCommitSigningKeyCopied => 'پبلک کلید کاپی ہو گئی';

  @override
  String get settingsCommitSigningFingerprintLabel => 'فنگر پرنٹ';

  @override
  String get settingsCommitSigningCreatedLabel => 'بنائی گئی';

  @override
  String get settingsCommitSigningAddTitle =>
      'اسے اپنے فورج اکاؤنٹ میں شامل کریں';

  @override
  String get settingsCommitSigningAddDescription =>
      'کوئی کمیٹ اس وقت تک تصدیق شدہ دکھائی نہیں دیتی جب تک آپ ورک اسپیس میں اسی فورج پر بھی سائن ان نہ ہوں، تاکہ فورج آپ کی ای میل کی تصدیق کرے۔';

  @override
  String get settingsCommitSigningGitHubSteps =>
      'Settings → SSH and GPG keys → New SSH key۔ Key type کو Signing Key پر سیٹ کریں۔';

  @override
  String get settingsCommitSigningGitLabSteps =>
      'Preferences → SSH Keys۔ Usage type کو Signing پر سیٹ کریں۔';

  @override
  String get settingsCommitSigningBitbucketSteps =>
      'Bitbucket پر کمیٹس سائن نہیں ہوتیں۔ یہ کلید اپنے Bitbucket اکاؤنٹ میں شامل نہ کریں: وہاں SSH کلید لاگ اِن کا کام بھی دیتی ہے۔';

  @override
  String get settingsCommitSigningUnsupported => 'سپورٹ نہیں ہے';

  @override
  String get settingsCommitSigningTrustTitle => 'آپ کس پر اعتماد کر رہے ہیں';

  @override
  String get settingsCommitSigningTrustPrivate =>
      'نجی کلید کبھی اس سرور سے باہر نہیں جاتی۔';

  @override
  String get settingsCommitSigningTrustControl =>
      'جو بھی اس سرور کو کنٹرول کرتا ہے، جب تک کلید آپ کے فورج اکاؤنٹ پر ہے، وہ آپ کے نام سے کمیٹس سائن کر سکتا ہے۔';

  @override
  String get settingsCommitSigningTrustVerified =>
      'GitHub پر، جو کمیٹس پہلے سے تصدیق شدہ دکھائی جا چکی ہیں، کلید ہٹانے کے بعد بھی تصدیق شدہ رہتی ہیں۔';

  @override
  String get settingsCommitSigningDelete => 'کلید حذف کریں';

  @override
  String get settingsCommitSigningDeleteTitle => 'اپنی سائننگ کلید حذف کریں؟';

  @override
  String get settingsCommitSigningDeleteBody =>
      'اب سے آپ کی کمیٹس سائن نہیں ہوں گی۔ کلید آپ کے فورج اکاؤنٹس پر اس وقت تک رہے گی جب تک آپ وہاں سے اسے ہٹا نہ دیں۔';

  @override
  String get settingsCommitSigningDeleted => 'سائننگ کلید حذف ہو گئی';

  @override
  String settingsCommitSigningLoadFailed(String error) {
    return 'آپ کی سائننگ کلید لوڈ نہیں ہو سکی: $error';
  }

  @override
  String get accountProfileTitle => 'پروفائل';

  @override
  String get accountProfileDescription =>
      'ہر ورک اسپیس میں آپ کون ہیں، اور آپ کے اپنے کوڈ ہوسٹنگ، ٹکٹنگ، کیلنڈر اور چیٹ اکاؤنٹس۔';

  @override
  String get accountSectionTitle => 'اکاؤنٹ';

  @override
  String get accountSectionDescription =>
      'آپ کا یوزر نیم اور نام ہر ورک اسپیس میں آپ کے ساتھ جاتا ہے۔ کوئی ورک اسپیس مختلف نام یا ای میل دکھا سکتی ہے: اسے ورک اسپیس ← پروفائل اور شناخت میں سیٹ کریں۔';

  @override
  String accountLoadFailed(String error) {
    return 'آپ کا پروفائل لوڈ نہیں ہو سکا: $error';
  }

  @override
  String get accountDisplayNameHint =>
      'وہ نام جو لوگ آپ کے پیغامات اور ریویوز پر دیکھتے ہیں۔';

  @override
  String get accountDisplayNameRequired => 'ڈسپلے نام درج کریں۔';

  @override
  String get accountFieldCannotBeCleared =>
      'اسے تبدیل کیا جا سکتا ہے، مگر ہٹایا نہیں جا سکتا۔';

  @override
  String get accountAvatarLabel => 'تصویر';

  @override
  String get accountAvatarHint =>
      'ایک مربع تصویر کا لنک، جو https:// سے شروع ہو۔';

  @override
  String get accountAvatarInvalid =>
      'ایسا لنک استعمال کریں جو https:// سے شروع ہو۔';

  @override
  String get usernameLabel => 'یوزر نیم';

  @override
  String get usernameRule =>
      '2 سے 32 چھوٹے انگریزی حروف، ہندسے، نقطے، ڈیش یا انڈرسکور۔ لوگ اسی سے آپ کا ذکر کرتے ہیں۔';

  @override
  String get usernameAvailable => 'دستیاب ہے۔';

  @override
  String usernameAvailableAs(String username) {
    return 'دستیاب ہے۔ اسے $username کے طور پر محفوظ کیا جائے گا۔';
  }

  @override
  String get usernameInvalid =>
      '2 سے 32 چھوٹے انگریزی حروف، ہندسے، “.”، “_” یا “-” استعمال کریں، اور نام کا آغاز اور اختتام حرف یا ہندسے سے ہو۔';

  @override
  String get usernameReserved => 'یہ یوزر نیم محفوظ ہے۔';

  @override
  String get usernameTaken => 'یہ یوزر نیم پہلے سے لیا جا چکا ہے۔';

  @override
  String get usernameCheckFailed =>
      'یہ نام ابھی چیک نہیں ہو سکا۔ آپ پھر بھی محفوظ کر سکتے ہیں؛ فیصلہ سرور کرے گا۔';

  @override
  String get linkedAccountsTitle => 'جڑے ہوئے اکاؤنٹس';

  @override
  String get linkedAccountsIdentityProvider => 'شناخت فراہم کنندہ';

  @override
  String get linkedAccountStatusNeedsSignIn => 'سائن ان درکار ہے';

  @override
  String get linkedAccountStatusPaused => 'موقوف';

  @override
  String get linkedAccountStatusUnreachable => 'رسائی سے باہر';

  @override
  String get ssoIdentityDescription =>
      'وہ شناخت فراہم کنندہ جس کے ذریعے آپ کا اکاؤنٹ سائن اِن ہوتا ہے۔ اس سرور کو چلانے والا اسے منظم کرتا ہے۔';

  @override
  String get settingsAccountsDescription =>
      'وہ اکاؤنٹس جو آپ اپنے لیے جوڑتے ہیں۔ Control Center ان کے ذریعے آپ کی طرف سے کام کرتا ہے، اور ان میں تبدیلی صرف آپ پر اثر ڈالتی ہے۔';

  @override
  String get accountReachServer =>
      'اس سرور کی ہر ورک اسپیس میں استعمال ہوتا ہے۔';

  @override
  String accountReachWorkspace(String workspace) {
    return 'صرف $workspace میں استعمال ہوتا ہے۔';
  }

  @override
  String forgeReachGitHubOwnApp(String workspace) {
    return 'GitHub صرف $workspace میں استعمال ہوتا ہے، جس کی اپنی سائن اِن ایپس ہیں۔ GitLab اور Bitbucket اس سرور کی ہر ورک اسپیس میں استعمال ہوتے ہیں۔';
  }

  @override
  String get yourAccountLabel => 'آپ کا اکاؤنٹ';

  @override
  String yourAccountEntry(String provider, String detail) {
    return '$provider: $detail';
  }

  @override
  String yourAccountLineSemantics(String status) {
    return 'آپ کا اکاؤنٹ: $status۔ آپ ← پروفائل کھولتا ہے۔';
  }

  @override
  String get yourForgeAccountNone => 'کوئی کوڈ ہوسٹنگ اکاؤنٹ منسلک نہیں';

  @override
  String yourAccountNotConnected(String provider) {
    return '$provider کا کوئی اکاؤنٹ منسلک نہیں';
  }

  @override
  String yourChatAccountNotLinked(String provider) {
    return 'کوئی $provider اکاؤنٹ لنک نہیں';
  }

  @override
  String get demoUnavailableAccount =>
      'آپ ڈیمو میں عارضی مہمان ہیں، اس لیے تبدیل کرنے کے لیے کوئی اکاؤنٹ نہیں ہے: نہ یوزر نیم، نہ پروفائل، نہ جڑے ہوئے اکاؤنٹس۔';

  @override
  String get onboardingStepYou => 'آپ';

  @override
  String get onboardingYouTitle => 'اپنا یوزر نیم منتخب کریں';

  @override
  String get onboardingYouSubtitle =>
      'آپ کا یوزر نیم وہ ہے جس سے لوگ آپ کا ذکر کرتے ہیں اور آپ کے کام پر لیبل لگتا ہے۔ آپ اسے اور اپنا ڈسپلے نام بعد میں ترتیبات ← آپ ← پروفائل میں بدل سکتے ہیں۔';

  @override
  String signInErrorAccountAlreadyBound(String provider) {
    return 'یہ $provider اکاؤنٹ اس سرور پر پہلے ہی کسی اور شخص سے جڑا ہوا ہے۔ کسی مختلف $provider اکاؤنٹ سے سائن ان کریں۔';
  }

  @override
  String forgeTokenExpiresOn(String date) {
    return 'ٹوکن $date کو ختم ہو جائے گا';
  }

  @override
  String forgeTokenExpiredOn(String date) {
    return 'ٹوکن $date کو ختم ہو گیا۔ کام جاری رکھنے کے لیے نیا ٹوکن چسپاں کریں۔';
  }

  @override
  String personTokenUnreachable(String forge) {
    return 'اس ٹوکن کی جانچ کے لیے $forge تک رسائی نہیں ہو سکی۔ کچھ دیر بعد دوبارہ کوشش کریں۔';
  }

  @override
  String personTokenRejected(String forge) {
    return '$forge یہ ٹوکن قبول نہیں کرتا۔ دیکھیں کہ آپ نے پورا ٹوکن کاپی کیا ہے اور وہ منسوخ نہیں ہوا۔';
  }

  @override
  String personTokenWrongKind(String forge) {
    return 'یہ ذاتی ٹوکن نہیں ہے۔ اپنے $forge اکاؤنٹ کا ذاتی ایکسیس ٹوکن چسپاں کریں، پروجیکٹ، گروپ، ورک اسپیس یا بوٹ کا ٹوکن نہیں۔';
  }

  @override
  String personTokenNarrowScope(String scope) {
    return 'اس ٹوکن میں $scope اسکوپ نہیں ہے، جو ریویو اور تبصروں کے لیے درکار ہے۔ ایسا ٹوکن بنائیں جس میں وہ ہو۔';
  }

  @override
  String get personTokenExpired =>
      'یہ ٹوکن ختم ہو چکا ہے۔ نیا بنائیں اور یہاں چسپاں کریں۔';

  @override
  String get settingsCommitSigningTrustAgents =>
      'آپ کے شروع کردہ ایجنٹس ان ریپوزٹریز میں جہاں وہ کام کرتے ہیں، آپ کے نام سے سائن شدہ کمیٹس بنا سکتے ہیں۔ یہاں کلید حذف کرنے سے یہ فوراً رک جاتا ہے: جو رنز پہلے سے جاری ہیں وہ اس کے بعد کچھ بھی سائن نہیں کریں گے۔';

  @override
  String connectRotateKeyFailed(String error) {
    return 'کلید تبدیل نہیں ہوئی اور کچھ نہیں بدلا: $error دوبارہ کوشش کریں۔';
  }

  @override
  String get noWorkspaceInviteTitle => 'آپ ابھی کسی ورک اسپیس میں نہیں ہیں';

  @override
  String get noWorkspaceInviteBody =>
      'ایک ورک اسپیس ایڈمن کو آپ کو دعوت دینی ہوگی، یا سرور کا مالک آپ کے لیے ورک اسپیس بنا سکتا ہے۔ آپ کے شامل ہوتے ہی یہ یہاں کھل جائے گا۔';

  @override
  String noWorkspaceSignedInAs(String name) {
    return '$name کے طور پر سائن ان';
  }

  @override
  String get noWorkspaceCheckAgain => 'دوبارہ جانچیں';

  @override
  String get noWorkspaceSignOut => 'سائن آؤٹ';

  @override
  String get workspaceCreateOwnerOnly =>
      'صرف سرور کا مالک ورک اسپیس بنا سکتا ہے۔ ان سے ایک بنانے کو کہیں، یا کسی ورک اسپیس ایڈمن سے آپ کو دعوت دینے کو کہیں۔';

  @override
  String repoLinkNoWorkspaceToAddTo(String repo) {
    return '$repo آپ کے کسی ورک اسپیس میں نہیں ہے، اور آپ ایسے ورک اسپیس میں نہیں ہیں جس میں اسے شامل کیا جا سکے۔ کسی ورک اسپیس ایڈمن سے آپ کو دعوت دینے کو کہیں۔';
  }

  @override
  String get serverOwnerOnly => 'یہ صرف سرور کا مالک کر سکتا ہے';

  @override
  String get ideCodeServerOwnerOnlyHint =>
      'مکمل ایڈیٹر سرور کی اپنی مشین پر چلتا ہے، اس لیے اسے صرف سرور کا مالک کھول سکتا ہے۔ آپ پھر بھی ایکسپلورر سے فائلیں کھول اور ترمیم کر سکتے ہیں۔';

  @override
  String get terminalSandboxedBadge => 'سینڈ باکس شدہ';

  @override
  String get terminalSandboxedHint =>
      'یہ اس ورک اسپیس کے فولڈرز کے اندر سینڈ باکس میں چلتا ہے، اس لیے یہاں کچھ ہوسٹ ٹولز اور پاتھس دستیاب نہیں ہیں۔';

  @override
  String get terminalHostShellOwnerOnly =>
      'ہوسٹ شیل سرور پر بغیر سینڈ باکس کے چلتا ہے، اس لیے اسے صرف سرور کا مالک کھول سکتا ہے۔ عام ٹرمینل سینڈ باکس میں چلتا ہے۔';

  @override
  String get terminalOutsideWorkspace =>
      'ٹرمینل صرف اس ورک اسپیس کے اپنے فولڈرز کے اندر کھل سکتا ہے۔';

  @override
  String get environmentHostOwnerOnly =>
      'صرف سرور کا مالک ایسا انوائرنمنٹ محفوظ یا منظور کر سکتا ہے جو سرور ہوسٹ پر چلتا ہے۔ ورک اسپیس ایڈمن وہ انوائرنمنٹ استعمال کر سکتا ہے جو Rig میں چلتا ہو۔';

  @override
  String get settingsCommitsNoHooks =>
      'ایپ کے اپنے ایڈیٹر میں کی گئی کمیٹس ریپوزٹری سے کوئی Git hooks نہیں چلاتیں، جیسے git commit --no-verify کے ساتھ ہوتا ہے: سرور Git اپنے ہوسٹ پر چلاتا ہے، ایسے درخت میں جسے ایجنٹس اور پل ریکوئسٹس بدل سکتے ہیں۔';

  @override
  String get mcpTokenDescription =>
      'MCP کلائنٹس ہر درخواست کے ساتھ یہ ٹوکن Authorization: Bearer ہیڈر میں بھیجتے ہیں۔ سرور اسے پہلی بار شروع ہونے پر بناتا ہے؛ آپ اسے بدل سکتے ہیں مگر ہٹا نہیں سکتے۔';

  @override
  String get mcpShowToken => 'ٹوکن دکھائیں';

  @override
  String get mcpHideToken => 'ٹوکن چھپائیں';

  @override
  String get mcpRotateToken => 'ٹوکن بدلیں';

  @override
  String get mcpRotateTokenTitle => 'MCP ٹوکن بدلیں؟';

  @override
  String get mcpRotateTokenBody =>
      'سرور فوراً نیا ٹوکن استعمال کرنے لگے گا۔ موجودہ ٹوکن استعمال کرنے والا ہر MCP کلائنٹ اس وقت تک رد ہوگا جب تک آپ اسے نیا ٹوکن نہ دیں۔';

  @override
  String get mcpTokenRotated =>
      'ٹوکن بدل دیا گیا۔ اپنے MCP کلائنٹس کو نیا ٹوکن دیں۔';

  @override
  String get mcpOwnerOnlyTitle => 'MCP اینڈ پوائنٹ صرف سرور کے مالک کے لیے ہے';

  @override
  String get mcpOwnerOnlyBody =>
      'اس کا ٹوکن اس سرور کے ہر ٹول کو کھولتا ہے، اس لیے اسے صرف سرور کا مالک دیکھ، بدل، یا اینڈ پوائنٹ شروع اور بند کر سکتا ہے۔';

  @override
  String get activityRotatedMcpToken => 'MCP ٹوکن بدلا گیا';

  @override
  String get connectRotateKeyRetireFailedTitle =>
      'Connect پرانی کلید ختم نہیں کر سکا';

  @override
  String get connectRotateKeyForceBody =>
      'کچھ نہیں بدلا۔ اگر آپ پھر بھی بدلیں تو اس سرور کو نئی کلید مل جائے گی، لیکن پرانی شناخت اس Connect پر اس وقت تک قابلِ استعمال رہے گی جب تک اس کے سائن ان ختم نہ ہوں۔';

  @override
  String get connectRotateKeyAnyway => 'پھر بھی بدلیں';

  @override
  String get settingsAuditLog => 'آڈٹ لاگ';

  @override
  String get settingsAuditLogDescription =>
      'سرور اور آپ کے منظم کردہ ہر ورک اسپیس میں کس نے کیا تبدیل کیا، کہاں، اور نتیجہ کیا رہا۔ سرور کے آپریشنز صرف آرگیومنٹ کے نام ریکارڈ کرتے ہیں، ان کی قدریں نہیں۔';

  @override
  String get auditLogNoAccessTitle => 'صرف ایڈمنز';

  @override
  String get auditLogNoAccess =>
      'آڈٹ لاگ سرور اور ان ورک اسپیسز کا احاطہ کرتا ہے جنہیں آپ منظم کرتے ہیں۔ آپ کوئی ورک اسپیس منظم نہیں کرتے، اس لیے دکھانے کے لیے کچھ نہیں ہے۔';

  @override
  String get auditLogSourceServer => 'سرور';

  @override
  String get auditLogSourceWorkspace => 'ورک اسپیس';

  @override
  String get auditLogAddFilter => 'فلٹر';

  @override
  String get auditLogFilterOptionsHint => 'فلٹر…';

  @override
  String get auditLogFilterActor => 'کرنے والا';

  @override
  String get auditLogFilterSource => 'ورک اسپیس';

  @override
  String get auditLogFilterOutcome => 'نتیجہ';

  @override
  String get auditLogFilterTime => 'وقت';

  @override
  String auditLogFilterChip(String category, String values) {
    return '$category: $values';
  }

  @override
  String auditLogFilterChipMore(String values, int count) {
    return '$values +$count';
  }

  @override
  String get auditLogOutcomeOk => 'کامیاب';

  @override
  String get auditLogOutcomeDenied => 'مسترد';

  @override
  String get auditLogOutcomeFailed => 'ناکام';

  @override
  String get auditLogTimeAtOrAfter => 'یا اس کے بعد';

  @override
  String get auditLogTimeAfter => 'کے بعد';

  @override
  String get auditLogTimeBefore => 'سے پہلے';

  @override
  String get auditLogTimeAtOrBefore => 'یا اس سے پہلے';

  @override
  String auditLogTimeChip(String operator, String time) {
    return 'وقت $operator $time';
  }

  @override
  String get auditLogTimePresetHour => '1 گھنٹہ پہلے';

  @override
  String get auditLogTimePresetDay => '24 گھنٹے پہلے';

  @override
  String get auditLogTimePresetWeek => '7 دن پہلے';

  @override
  String get auditLogTimePresetMonth => '30 دن پہلے';

  @override
  String get auditLogTimeExact => 'درست وقت';

  @override
  String get auditLogTimeInvalid =>
      'YYYY-MM-DD استعمال کریں، اختیاری طور پر HH:MM کے ساتھ';

  @override
  String get auditLogTimeAdd => 'شامل کریں';

  @override
  String repoAccessReplacedTitle(String repo) {
    return '$repo اب ایک مختلف ریپوزٹری کی طرف اشارہ کرتی ہے';
  }

  @override
  String repoAccessReplacedBody(String forge) {
    return 'یہ پاتھ اب $forge پر ایک مختلف ریپوزٹری کی طرف اشارہ کرتا ہے۔ استعمال جاری رکھنے کے لیے اسے دوبارہ لنک کریں۔';
  }

  @override
  String get repoRelink => 'دوبارہ لنک کریں';

  @override
  String repoRelinked(String repo) {
    return '$repo دوبارہ لنک ہو گیا۔';
  }

  @override
  String get repoCodeRepoReplaced =>
      'یہ پاتھ اب ایک مختلف ریپوزٹری کی طرف اشارہ کرتا ہے۔ استعمال سے پہلے ایک ورک اسپیس ایڈمن کو اسے دوبارہ لنک کرنا ہوگا۔';

  @override
  String repoCodeForgeCannotRead(String forge) {
    return 'آپ کا $forge اکاؤنٹ اس ریپوزٹری کو نہیں پڑھ سکتا۔';
  }

  @override
  String repoCodeForgeUnconfirmed(String forge) {
    return 'آپ کی $forge تک رسائی کی تصدیق نہیں ہو سکی۔ دوبارہ کوشش کریں۔';
  }

  @override
  String get repoCodeForgeCannotReadUnnamed =>
      'آپ کا فورج اکاؤنٹ اس ریپوزٹری کو نہیں پڑھ سکتا۔';

  @override
  String get repoCodeForgeUnconfirmedUnnamed =>
      'آپ کی فورج تک رسائی کی تصدیق نہیں ہو سکی۔ دوبارہ کوشش کریں۔';

  @override
  String get repoPathHostPath =>
      'صرف سرور کا مالک اس ورک اسپیس کے اسٹوریج سے باہر کا فولڈر لنک کر سکتا ہے۔';

  @override
  String get repoPathMissing => 'سرور پر اس پاتھ پر کچھ موجود نہیں ہے۔';

  @override
  String get repoPathDataDir =>
      'ریپوزٹری سرور کے ڈیٹا فولڈر کے اندر کی طرف اشارہ نہیں کر سکتی۔';

  @override
  String get repoPathWorkspaceRoot =>
      'ریپوزٹری خود ورک اسپیس کا فولڈر نہیں ہو سکتی۔';

  @override
  String get repoPathOriginMismatch =>
      'اس فولڈر کا اوریجن ایک مختلف ریپوزٹری ہے۔';

  @override
  String repoGrantNeedsSignIn(String forge) {
    return 'محفوظ ہو گیا۔ اس ریپوزٹری کو کھولنے سے پہلے انہیں $forge پر سائن ان کرنا ہوگا۔';
  }

  @override
  String repoGrantCannotRead(String forge) {
    return 'محفوظ ہو گیا۔ ان کا $forge اکاؤنٹ ابھی اس ریپوزٹری کو نہیں پڑھ سکتا، اس لیے یہ ان سے چھپی رہے گی۔';
  }

  @override
  String repoGrantUnconfirmed(String forge) {
    return 'محفوظ ہو گیا۔ ابھی ان کی $forge تک رسائی کی تصدیق نہیں ہو سکی۔';
  }

  @override
  String repoLinkAskOwnerToAdd(String repo) {
    return '$repo آپ کے کسی ورک اسپیس میں لنک نہیں ہے۔ سرور کے مالک سے اسے شامل کرنے کو کہیں۔';
  }

  @override
  String get reposEmptyAskOwner =>
      'سرور کا مالک سرور کے فولڈرز سے ریپوزٹریز شامل کرتا ہے۔';

  @override
  String get accountEmailUnconfirmedHint =>
      'یہ پتہ صرف آپ نے درج کیا ہے۔ جب تک سرور کا مالک اس کی تصدیق نہ کرے، سنگل سائن آن اس سے میچ نہیں کرے گا۔';

  @override
  String get settingsServerPeople => 'لوگ';

  @override
  String get settingsServerPeopleDescription =>
      'اس سرور پر اکاؤنٹ رکھنے والے تمام لوگ، اور یہ کہ ان کی ای میل کی تصدیق ہوئی ہے یا نہیں۔';

  @override
  String get serverPeopleLabel => 'اکاؤنٹس';

  @override
  String get serverPeopleOwnerOnly =>
      'صرف سرور کا مالک سب کے اکاؤنٹس دیکھ سکتا ہے اور ای میل پتے کی تصدیق کر سکتا ہے۔';

  @override
  String get serverPeopleEmailNotConfirmed => 'ای میل کی تصدیق نہیں ہوئی';

  @override
  String get serverPeopleConfirmEmail => 'ای میل کی تصدیق کریں';

  @override
  String serverPeopleConfirmEmailBody(String email, String name) {
    return 'کیا تصدیق کریں کہ $email $name کا ہے؟ سنگل سائن آن اس پتے کو ان کے اکاؤنٹ سے میچ کرے گا۔';
  }

  @override
  String serverPeopleEmailConfirmed(String email) {
    return '$email کی تصدیق ہو گئی۔';
  }

  @override
  String get runSandboxUnavailableTitle =>
      'ایجنٹس کو اس سرور پر سینڈ باکس چاہیے';

  @override
  String get runSandboxUnavailable =>
      'اس سرور پر سینڈ باکس نہیں ہے، اس لیے یہاں صرف اس کا مالک ایجنٹس چلا سکتا ہے۔ مالک سینڈ باکس انسٹال کر سکتا ہے یا سب کے لیے سینڈ باکسنگ بند کر سکتا ہے۔';

  @override
  String get repoPathIssueHostPath =>
      'یہ فولڈر ورک اسپیس کے اسٹوریج سے باہر ہے۔ تصدیق کریں کہ یہ سرور اسے استعمال کر سکتا ہے۔';

  @override
  String get repoPathIssueHostPathAskOwner =>
      'یہ فولڈر ورک اسپیس کے اسٹوریج سے باہر ہے۔ صرف سرور کا مالک اس کی تصدیق کر سکتا ہے۔';

  @override
  String get repoPathIssueMissing =>
      'سرور پر اس پاتھ پر اب کچھ موجود نہیں ہے۔ اس ریپوزٹری کو ہٹائیں اور اس کے موجودہ فولڈر سے دوبارہ شامل کریں۔';

  @override
  String get repoPathIssueUnusable =>
      'یہ فولڈر ریپوزٹری کے طور پر استعمال نہیں ہو سکتا۔ اسے ہٹائیں اور ریپوزٹری کو کسی دوسرے فولڈر سے شامل کریں۔';

  @override
  String get repoPathConfirm => 'تصدیق کریں';

  @override
  String get repoPathConfirmAll => 'سب کی تصدیق کریں';

  @override
  String repoPathConfirmAllTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فولڈرز ورک اسپیس کے اسٹوریج سے باہر ہیں',
      one: '1 فولڈر ورک اسپیس کے اسٹوریج سے باہر ہے',
    );
    return '$_temp0';
  }

  @override
  String get repoPathConfirmAllBody =>
      'تصدیق کریں کہ یہ سرور انہیں استعمال کر سکتا ہے۔ ہر ریپوزٹری آپ کی رسائی کے ساتھ دوبارہ جانچی جائے گی۔';

  @override
  String get mcpExternalServersOwnerRunsOnly =>
      'اس مشین کی اپنی ٹول ترتیبات میں ملنے والے سرورز صرف ان رنز میں دستیاب ہیں جو آپ شروع کریں یا جن کے آپ ذمہ دار ہوں۔ دوسروں کے رنز انہیں کبھی نہیں دیکھتے، اور انہیں Control Center کے MCP اینڈ پوائنٹ کے ذریعے پیش نہیں کیا جاتا۔';

  @override
  String repoCodeNeedsSignIn(String provider) {
    return 'اس ریپوزٹری کا کوڈ دیکھنے کے لیے $provider پر سائن ان کریں۔';
  }

  @override
  String get repoCodeSignIn => 'سائن ان';

  @override
  String get ideContentSearchFailed => 'فائلوں میں تلاش نہیں ہو سکی';

  @override
  String get ideWorktreeFileUnavailable =>
      'یہ فائل اس ورک ٹری میں دستیاب نہیں ہے۔';

  @override
  String get ideChangesLoadFailed => 'تبدیلیاں لوڈ نہیں ہو سکیں';

  @override
  String repoCodeRepoReplacedOn(String forge) {
    return 'یہ پاتھ اب $forge پر ایک مختلف ریپوزٹری کی طرف اشارہ کرتا ہے۔ استعمال سے پہلے ایک ورک اسپیس ایڈمن کو اسے دوبارہ لنک کرنا ہوگا۔';
  }

  @override
  String get backupRestoreServerOwnerOnly =>
      'صرف سرور کا مالک بیک اپ بحال کر سکتا ہے۔ آپ پھر بھی انہیں ڈاؤن لوڈ کر سکتے ہیں۔';

  @override
  String get terminalReadOnlyBadge => 'صرف پڑھنے کے لیے';

  @override
  String get terminalReadOnlyHint =>
      'آپ اس ٹرمینل کو دیکھ سکتے ہیں۔ اس میں ٹائپ کرنے، اس کا سائز بدلنے یا اسے روکنے کے لیے اس گفتگو کی ہر ریپوزٹری پر رائٹ ایکسیس درکار ہے۔';

  @override
  String get environmentOperateNeedsWrite =>
      'آپ اس انوائرنمنٹ کو دیکھ سکتے ہیں۔ اسے شروع، روکنے یا دوبارہ شروع کرنے کے لیے اس گفتگو کی ہر ریپوزٹری پر رائٹ ایکسیس درکار ہے۔';

  @override
  String get environmentHostApprovalOwner =>
      'یہ سرور پر چلتا ہے۔ شروع ہونے کے لیے اسے منظور کریں۔';

  @override
  String get environmentHostApprovalMember =>
      'یہ سرور پر چلتا ہے۔ شروع ہونے سے پہلے سرور کے مالک کو اسے منظور کرنا ہوگا۔';

  @override
  String get environmentHostApprove => 'منظور کریں';

  @override
  String get environmentHostApproveNeedsAdmin =>
      'اسے ورک اسپیس ایڈمن کے طور پر منظور کریں: صرف ایڈمن کی کاپی میں خفیہ قدریں نظر آتی ہیں، اور منظوری انہیں واپس محفوظ کرتی ہے۔';

  @override
  String get environmentHostUnapproved =>
      'سرور کے مالک نے ابھی تک یہ انوائرنمنٹ منظور نہیں کیا، اس لیے یہ اس سرور پر نہیں چل سکتا۔';

  @override
  String get environmentHostUnapprovedOwner =>
      'آپ نے ابھی تک یہ انوائرنمنٹ منظور نہیں کیا۔ یہ اس سرور پر چلتا ہے، اس لیے آپ کے اس کی تعریف منظور کرنے کے بعد یہ شروع ہوگا۔';

  @override
  String get environmentHostApprovalReview => 'جائزہ لیں اور منظور کریں';

  @override
  String spaceAccessNeedsSignIn(String provider) {
    return 'یہ اسپیس کھولنے کے لیے $provider پر سائن ان کریں۔';
  }

  @override
  String spaceAccessForgeCannotRead(String forge) {
    return 'آپ کا $forge اکاؤنٹ اس اسپیس کی استعمال ہونے والی ایک ریپوزٹری کو نہیں پڑھ سکتا۔';
  }

  @override
  String get spaceAccessForgeCannotReadUnnamed =>
      'آپ کا فورج اکاؤنٹ اس اسپیس کی استعمال ہونے والی ایک ریپوزٹری کو نہیں پڑھ سکتا۔';

  @override
  String get spaceAccessNoGrant =>
      'آپ کو اس اسپیس کی استعمال ہونے والی ایک ریپوزٹری کی ریڈ ایکسیس حاصل نہیں ہے۔ ایک ورک اسپیس ایڈمن یہ دے سکتا ہے۔';

  @override
  String get spaceAccessFailed => 'یہ اسپیس نہیں کھل سکی۔';

  @override
  String get contextExplorerRefused =>
      'اس سیشن میں کانٹیکسٹ کی تفصیل دستیاب نہیں ہے۔';

  @override
  String get repoLinkForgeRemoteRequired =>
      'لنک شدہ ریپوزٹری کو مالک اور ریپوزٹری کا نام دونوں درکار ہیں۔';

  @override
  String get repoCodeNoReadGrant =>
      'آپ کو اس ریپوزٹری تک پڑھنے کی رسائی حاصل نہیں۔ ورک اسپیس کا ایڈمن اسے دے سکتا ہے۔';

  @override
  String get repoCodeNoWriteGrant =>
      'آپ اس ریپوزٹری کو پڑھ سکتے ہیں مگر اسے تبدیل نہیں کر سکتے۔ ورک اسپیس کا ایڈمن لکھنے کی رسائی دے سکتا ہے۔';

  @override
  String get repoCodeNoReviewGrant =>
      'آپ اس ریپوزٹری کو پڑھ سکتے ہیں مگر اس کا جائزہ نہیں لے سکتے۔ ورک اسپیس کا ایڈمن جائزے کی رسائی دے سکتا ہے۔';

  @override
  String get rigWatchOnlyBadge => 'صرف دیکھنے کے لیے';

  @override
  String get rigWatchOnlyHint =>
      'آپ اس مشین کو دیکھ سکتے ہیں۔ اسے چلانے، اس کے پورٹس فارورڈ کرنے، اس میں پیسٹ کرنے یا اس پر فائلیں ڈالنے کے لیے اس اسپیس کی ہر ریپوزٹری تک لکھنے کی رسائی درکار ہے۔';

  @override
  String get rigStartNeedsWrite =>
      'یہاں ایک مشین شروع کرنے کے لیے اس اسپیس کی ہر ریپوزٹری تک لکھنے کی رسائی درکار ہے۔ ورک اسپیس کا ایڈمن اسے دے سکتا ہے۔';

  @override
  String get rigViewRefused =>
      'آپ یہ مشین نہیں دیکھ سکتے۔ یہ ایک ایسی اسپیس سے تعلق رکھتی ہے جس تک آپ کی پڑھنے کی رسائی نہیں۔';

  @override
  String get rigPortsWatchOnly =>
      'ان پورٹس کو تبدیل کرنے کے لیے اس اسپیس کی ہر ریپوزٹری تک لکھنے کی رسائی درکار ہے۔';

  @override
  String get rigHolderOnly =>
      'صرف وہ شخص جس کے لیے یہ مشین کھولی گئی تھی اسے چلا سکتا ہے۔ یہ ان کے اپنے سائن ان استعمال کرتی ہے۔';

  @override
  String get rigHolderOnlyHint =>
      'آپ اس مشین کو دیکھ سکتے ہیں۔ یہ اس شخص کے سائن ان استعمال کرتی ہے جس کے لیے یہ کھولی گئی تھی، اس لیے صرف وہی اسے چلا سکتا ہے، اس کے پورٹس فارورڈ کر سکتا ہے، اس میں پیسٹ کر سکتا ہے یا اس پر فائلیں ڈال سکتا ہے۔';

  @override
  String get refusalStorageBusy =>
      'سرور کا ڈیٹا بیس اس وقت مصروف ہے۔ ذرا دیر بعد دوبارہ کوشش کریں۔';

  @override
  String get refusalStorageFull =>
      'سرور کی ڈسک میں جگہ ختم ہو گئی ہے، اس لیے کچھ بھی محفوظ نہیں ہو سکتا۔ سرور کے مالک کو کچھ جگہ خالی کرنی ہوگی۔';

  @override
  String get refusalStorageDamaged =>
      'اس ورک اسپیس کا ڈیٹا خراب ہو گیا ہے۔ سرور کے مالک کو اسے بیک اپ سے بحال کرنا ہوگا۔';

  @override
  String get refusalStorageReadOnly =>
      'یہ ورک اسپیس اس وقت تک صرف پڑھنے کے لیے ہے جب تک سرور کا مالک اسے بیک اپ سے بحال نہ کرے، اس لیے تبدیلیاں محفوظ نہیں ہو سکتیں۔';

  @override
  String get refusalStorageNewerSchema =>
      'یہ ڈیٹا سرور کے ایک نئے ورژن نے لکھا ہے۔ سرور اپ ڈیٹ کریں، پھر دوبارہ کوشش کریں۔';

  @override
  String get refusalStorageForeignFile =>
      'سرور کو ایسی ڈیٹا بیس فائل ملی ہے جو اس نے نہیں لکھی۔ سرور کے مالک کو سرور کا ڈیٹا فولڈر چیک کرنا ہوگا۔';

  @override
  String get refusalWorkspaceDeleted => 'یہ ورک اسپیس حذف کیا جا چکا ہے۔';

  @override
  String get refusalIdempotencyInProgress =>
      'یہ درخواست ابھی تک عمل میں ہے۔ اس کے مکمل ہونے کا انتظار کریں، پھر نتیجہ دیکھیں۔';

  @override
  String get refusalImportMissingSource =>
      'سرور پر اس راستے پر کوئی فائل موجود نہیں۔ کچھ بھی تبدیل نہیں ہوا۔';

  @override
  String get refusalImportDamaged =>
      'یہ فائل خراب ہے، اس لیے اسے بحال نہیں کیا جا سکتا۔ کچھ بھی تبدیل نہیں ہوا۔';

  @override
  String get refusalImportChecksumMismatch =>
      'یہ فائل اس چیک سم سے نہیں ملتی جو اس کے بیک اپ میں درج تھی، اس لیے ہو سکتا ہے یہ بدل گئی ہو یا خراب ہو گئی ہو۔ کچھ بھی تبدیل نہیں ہوا۔';

  @override
  String get refusalImportNewerSchema =>
      'یہ فائل سرور کے ایک نئے ورژن نے لکھی ہے۔ اسے بحال کرنے کے لیے سرور اپ ڈیٹ کریں۔ کچھ بھی تبدیل نہیں ہوا۔';

  @override
  String get refusalImportForeignFile =>
      'یہ فائل ورک اسپیس کا ڈیٹا بیس نہیں ہے۔ کچھ بھی تبدیل نہیں ہوا۔';

  @override
  String get refusalImportSchemaMismatch =>
      'یہ فائل اس سرور کے فارمیٹ میں تبدیل نہیں ہو سکی۔ کچھ بھی تبدیل نہیں ہوا۔';

  @override
  String get refusalImportRouteConflict =>
      'اس فائل میں ایسے لنکس ہیں جو اس سرور پر کسی اور ورک اسپیس کے ہیں، اور اسے بحال کرنے سے وہ لنکس اس سے چھن جائیں گے۔ کچھ بھی تبدیل نہیں ہوا۔';

  @override
  String get workspaceReadOnlyBannerTitle => 'یہ ورک اسپیس صرف پڑھنے کے لیے ہے';

  @override
  String get workspaceReadOnlyBannerBody =>
      'اس کا ڈیٹا انٹیگریٹی چیک میں ناکام ہوا، اس لیے تبدیلیاں محفوظ نہیں ہو سکتیں۔ سب کچھ اب بھی پڑھا جا سکتا ہے۔ سرور کا مالک اسے بیک اپ سے بحال کر سکتا ہے۔';

  @override
  String get workspaceReadOnlyBannerOwnerBody =>
      'اس کا ڈیٹا انٹیگریٹی چیک میں ناکام ہوا، اس لیے تبدیلیاں محفوظ نہیں ہو سکتیں۔ سب کچھ اب بھی پڑھا جا سکتا ہے۔ دوبارہ قابلِ تحریر بنانے کے لیے اسے بیک اپ سے بحال کریں۔';

  @override
  String get workspaceReadOnlyBannerAction => 'بیک اپ کھولیں';

  @override
  String get serverNoticesLabel => 'آپ کی توجہ درکار ہے';

  @override
  String get serverNoticeReadOnlyStatus => 'صرف پڑھنے کے لیے';

  @override
  String serverNoticeSince(String time) {
    return '$time سے';
  }

  @override
  String get serverNoticeReadOnlyBody =>
      'اس کا ڈیٹا بیس انٹیگریٹی چیک میں ناکام ہوا، اس لیے یہ صرف پڑھنے دیتا ہے اور ہر تبدیلی رد کرتا ہے۔ نیچے کی فہرستوں میں سے بیک اپ سے بحال کریں؛ جب تک آپ ایسا نہیں کرتے، اس کی آخری درست کاپی محفوظ رہتی ہے۔';

  @override
  String get serverNoticeDetails => 'تفصیلات';

  @override
  String get backupSnapshotUnverified => 'غیر تصدیق شدہ';

  @override
  String get backupSnapshotUnverifiedNote =>
      'اس اسنیپ شاٹ کی تصدیق نہیں ہو سکتی۔ یا یہ مکمل نہیں ہوا، یا اسنیپ شاٹس کے چیک سم درج کرنے سے پہلے لیا گیا تھا، اس لیے یہ پورا انسٹال بحال نہیں کر سکتا۔ اس میں موجود ورک اسپیس فائلیں اب بھی ایک ایک کر کے بحال ہو سکتی ہیں۔';

  @override
  String get backupSnapshotLastGoodCopy => 'آخری درست کاپی';

  @override
  String get backupSnapshotLastGoodCopyNote =>
      'رکھا گیا ہے کیونکہ اس میں ایک خراب ورک اسپیس کی آخری درست کاپی ہے۔ صفائی اس وقت تک اسے نہیں چھیڑتی جب تک وہ ورک اسپیس بحال نہ ہو۔';

  @override
  String get backupDeleteLastGoodCopyDescription =>
      'یہ ایک خراب ورک اسپیس کی آخری درست کاپی ہے۔ اسے حذف کیا تو اس ورک اسپیس کو بحال کرنے کے لیے کچھ باقی نہیں رہے گا۔';

  @override
  String backupRestoreHeldBack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'آپ کے جائزے کے لیے $count اجازتیں روکی گئیں۔ یہ اس صفحے کے اوپر درج ہیں۔',
      one: 'آپ کے جائزے کے لیے 1 اجازت روکی گئی۔ یہ اس صفحے کے اوپر درج ہے۔',
    );
    return '$_temp0';
  }

  @override
  String get importHoldsLabel => 'بحال شدہ کاپیوں سے روکی گئی';

  @override
  String get importHoldsExplainer =>
      'بحال شدہ کاپی خود سے اس سرور پر کچھ بھی عطا نہیں کر سکتی۔ اس میں یہ اجازتیں تھیں: کسی ایک کو قبول کریں تاکہ وہ دوبارہ دی جائے، یا مسترد کریں تاکہ وہ ہٹ جائے۔';

  @override
  String importHoldPolicyAllow(String action) {
    return 'ایجنٹس بغیر منظوری کے یہ کام کر سکتے ہیں: $action';
  }

  @override
  String importHoldPolicyPrompt(String action) {
    return 'کسی شخص کی منظوری کے بعد ایجنٹس یہ کام کر سکتے ہیں: $action';
  }

  @override
  String importHoldCommand(String command) {
    return '$command سے شروع ہونے والے کمانڈز چلائیں';
  }

  @override
  String get importHoldScopeWorkspace => 'اس ورک اسپیس میں ہر جگہ';

  @override
  String importHoldScopeSpace(String space) {
    return 'اسپیس $space میں';
  }

  @override
  String importHoldScopeAgent(String agent) {
    return 'ایجنٹ $agent کے لیے';
  }

  @override
  String importHoldSandboxExec(String path) {
    return 'سینڈ باکسز $path چلا سکتے ہیں';
  }

  @override
  String importHoldRepoWrite(String person, String repo) {
    return '$person $repo کو تبدیل کر سکتا ہے';
  }

  @override
  String importHoldRepoReview(String person, String repo) {
    return '$person $repo میں Pull request کا جائزہ لے سکتا ہے';
  }

  @override
  String importHoldRepoOther(String person, String repo, String level) {
    return '$person کو $repo تک $level رسائی ملتی ہے';
  }

  @override
  String importHoldMemberRole(String person, String role) {
    return '$person کو $role کا کردار ملتا ہے';
  }

  @override
  String importHoldInvite(String role) {
    return '$role کے کردار کے ساتھ شامل ہونے کی ایک کھلی دعوت';
  }

  @override
  String importHoldInviteWithRepos(int count, String role) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$role کردار کے ساتھ شامل ہونے کی کھلی دعوت، جس میں $count ریپوزٹریز کا جائزہ یا لکھنے کی رسائی ہے',
      one:
          '$role کردار کے ساتھ شامل ہونے کی کھلی دعوت، جس میں 1 ریپوزٹری کا جائزہ یا لکھنے کی رسائی ہے',
    );
    return '$_temp0';
  }

  @override
  String get importHoldUnknown =>
      'ایک اجازت جسے ایپ کا یہ ورژن بیان نہیں کر سکتا';

  @override
  String importHoldRestoredAt(String time) {
    return '$time بحال ہوا';
  }

  @override
  String get importHoldAccept => 'قبول کریں';

  @override
  String get importHoldDismiss => 'مسترد کریں';

  @override
  String get importHoldAcceptTitle => 'یہ اجازت دیں؟';

  @override
  String importHoldAcceptBody(String permission) {
    return '$permission\n\nقبول کرنے سے یہ اجازت فوراً سرور پر دے دی جاتی ہے۔';
  }

  @override
  String get importHoldAccepted => 'اجازت دے دی گئی۔';

  @override
  String get importHoldNotApplied =>
      'کچھ بھی نہیں دیا گیا: جس شخص یا چیز کے لیے یہ تھی وہ اب اس ورک اسپیس میں نہیں ہے۔';

  @override
  String get mcpWorkspaceServers => 'ورک اسپیس کے MCP سرورز';

  @override
  String get mcpWorkspaceServersDescription =>
      'اس ورک اسپیس میں ہر ایجنٹ رن کو ان سرورز کے ٹولز ملتے ہیں، Claude Code میں بھی اور بلٹ اِن ہارنس میں بھی۔ Control Center ہر سرور سے منسلک ہوتا ہے اور اس کے ٹولز آگے پہنچاتا ہے۔';

  @override
  String get mcpWorkspaceServersAdminsOnly =>
      'صرف ورک اسپیس کے ایڈمن اس ورک اسپیس کے MCP سرورز دیکھ اور بدل سکتے ہیں۔';

  @override
  String get mcpWorkspaceServersUnavailable =>
      'ورک اسپیس کے MCP سرورز منسلک سرور پر دستیاب نہیں ہیں۔';

  @override
  String get mcpWorkspaceServersEmpty => 'ابھی تک کوئی ورک اسپیس MCP سرور نہیں';

  @override
  String get mcpWorkspaceServersEmptyDescription =>
      'ایک سرور شامل کریں تاکہ اس ورک اسپیس میں ہر ایجنٹ رن کو اس کے ٹولز ملیں۔';

  @override
  String get mcpAddServer => 'سرور شامل کریں';

  @override
  String get mcpHandAddedSource => 'Control Center میں شامل کیا گیا';

  @override
  String get mcpStatusAwaitingApproval => 'منظوری کا انتظار';

  @override
  String get mcpPublicAddressesOnly => 'صرف عوامی پتے';

  @override
  String get mcpApproveServer => 'منظور کریں';

  @override
  String get mcpApprovalStdioOwner =>
      'یہ سرور سرور کے ہوسٹ پر، سرور کے صارف کے طور پر ایک کمانڈ چلاتا ہے۔ آپ کی منظوری تک یہ شروع نہیں ہوگا۔';

  @override
  String get mcpApprovalStdioMember =>
      'یہ سرور سرور کے ہوسٹ پر کمانڈ چلاتا ہے، اس لیے سرور کا مالک منظوری نہ دے تو یہ شروع نہیں ہوگا۔';

  @override
  String get mcpApprovalRemoteOwner =>
      'یہ سرور صرف عوامی پتوں تک رسائی رکھ سکتا ہے۔ منظور کریں تو یہ ہوسٹ کے نجی نیٹ ورک تک بھی پہنچ سکے گا، جیسے localhost اور مقامی نیٹ ورک۔';

  @override
  String get mcpApprovalRemoteMember =>
      'سرور کا مالک منظوری نہ دے تو یہ سرور صرف عوامی پتوں تک رسائی رکھ سکتا ہے۔';

  @override
  String get mcpRemoveServer => 'سرور ہٹائیں';

  @override
  String mcpRemoveServerTitle(String name) {
    return '$name ہٹائیں؟';
  }

  @override
  String get mcpRemoveServerBody =>
      'ایجنٹ رنز اس سرور کے ٹولز کھو دیں گے، اور اس کی محفوظ شدہ سیکرٹ ویلیوز حذف ہو جائیں گی۔';

  @override
  String mcpServerEnabledToggle(String name) {
    return '$name آن یا آف کریں';
  }

  @override
  String get mcpServerEditorAddTitle => 'MCP سرور شامل کریں';

  @override
  String mcpServerEditorEditTitle(String name) {
    return '$name میں ترمیم کریں';
  }

  @override
  String get mcpServerNameHelper =>
      'حروف، ہندسے، ہائفن اور انڈر اسکور۔ ایجنٹس اس کے ٹولز اسی نام سے دیکھتے ہیں۔';

  @override
  String get mcpServerNameInvalid =>
      'زیادہ سے زیادہ 24 حروف، ہندسے، ہائفن یا انڈر اسکور استعمال کریں، جو حرف یا ہندسے سے شروع ہوں۔';

  @override
  String get mcpServerNameTaken =>
      'یہاں پہلے ہی ایک اور سرور اس نام کے ساتھ موجود ہے۔';

  @override
  String get mcpServerTransportLabel => 'ٹرانسپورٹ';

  @override
  String get mcpServerTransportStdio => 'کمانڈ';

  @override
  String get mcpServerTransportHttp => 'HTTP';

  @override
  String get mcpServerTransportSse => 'SSE';

  @override
  String get mcpServerCommandLabel => 'کمانڈ';

  @override
  String get mcpServerCommandRequired => 'چلانے والی کمانڈ درج کریں۔';

  @override
  String get mcpServerArgsLabel => 'آرگومنٹس';

  @override
  String get mcpServerArgsHelper => 'ہر لائن میں ایک آرگومنٹ۔';

  @override
  String get mcpServerUrlLabel => 'URL';

  @override
  String get mcpServerUrlInvalid =>
      'http یا https URL درج کریں، جس میں صارف نام، پاس ورڈ یا #fragment نہ ہو۔';

  @override
  String get mcpServerEnvLabel => 'ماحولیاتی متغیرات';

  @override
  String get mcpServerHeadersLabel => 'ہیڈرز';

  @override
  String get mcpServerSecretsDescription =>
      'ویلیوز سیکرٹ کے طور پر محفوظ ہوتی ہیں اور دوبارہ کبھی نہیں دکھائی جاتیں۔';

  @override
  String get mcpServerHeadersExample =>
      'مثال کے طور پر، بیئرر ٹوکن کے ساتھ ایک Authorization ہیڈر۔';

  @override
  String get mcpServerEnvAdd => 'متغیر شامل کریں';

  @override
  String get mcpServerHeaderAdd => 'ہیڈر شامل کریں';

  @override
  String get mcpServerSecretValueHint => 'ویلیو';

  @override
  String get mcpServerSecretNewValueHint => 'نئی ویلیو';

  @override
  String get mcpServerSecretReplace => 'ویلیو بدلیں';

  @override
  String get mcpServerSecretUndo => 'واپس کریں';

  @override
  String get mcpServerSecretRemovedOnSave => 'محفوظ کرتے وقت ہٹ جائے گا';

  @override
  String mcpServerEnvNameInvalid(String name) {
    return '$name ایک درست متغیر نام نہیں ہے۔ حروف، ہندسے اور انڈر اسکور استعمال کریں، ہندسے سے شروع نہ کریں۔';
  }

  @override
  String mcpServerHeaderNameInvalid(String name) {
    return '$name سیٹ نہیں کیا جا سکتا۔ ایک درست ہیڈر نام استعمال کریں جسے کنکشن خود نہیں سنبھالتا۔';
  }

  @override
  String get mcpServerTransportDropsValues =>
      'ٹرانسپورٹ بدلنے سے محفوظ شدہ ویلیوز ہٹ جاتی ہیں۔';

  @override
  String get mcpServerEnabledDescription =>
      'آف ہونے پر سرور شروع نہیں ہوتا اور ایجنٹس اس کے ٹولز نہیں دیکھتے۔';

  @override
  String get mcpServerEditorStdioMember =>
      'یہ سرور ہوسٹ پر چلتا ہے، اس لیے سرور کا مالک منظوری نہ دے تو یہ شروع نہیں ہوگا۔ شروع ہونے کا طریقہ بدلنے پر دوبارہ منظوری درکار ہوگی۔';

  @override
  String get mcpServerEditorRemoteMember =>
      'سرور کا مالک منظوری نہ دے تو یہ صرف عوامی پتوں تک رسائی رکھتا ہے۔ کنکشن کا طریقہ بدلنے پر دوبارہ منظوری درکار ہوگی۔';

  @override
  String get mcpServerEditorStdioOwner =>
      'یہ سرور ہوسٹ پر، سرور کے صارف کے طور پر چلتا ہے۔ محفوظ کرنے سے یہ منظور ہو جاتا ہے۔';

  @override
  String get mcpServerEditorRemoteOwner =>
      'محفوظ کرنے سے یہ ہوسٹ کے نجی نیٹ ورک تک بھی رسائی کے لیے منظور ہو جاتا ہے۔';

  @override
  String get mcpServerEditorPersonal =>
      'صرف ان رنز میں استعمال ہوتا ہے جو آپ شروع کرتے ہیں یا جن کے آپ ذمہ دار ہیں۔';

  @override
  String get mcpServerRefusedInvalid =>
      'Control Center یہ سرور محفوظ نہیں کر سکا۔ اس کی ترتیبات دیکھیں اور دوبارہ کوشش کریں۔';

  @override
  String get mcpServerNotFound =>
      'یہ سرور اب موجود نہیں ہے۔ شاید کسی نے اسے ہٹا دیا ہے۔';

  @override
  String get scriptToolCalls => 'ٹول کالز';

  @override
  String scriptCallCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کالز',
      one: '1 کال',
    );
    return '$_temp0';
  }

  @override
  String scriptCallsRunning(int count) {
    return '$count چل رہی ہیں';
  }

  @override
  String scriptCallsOk(int count) {
    return '$count کامیاب';
  }

  @override
  String scriptCallsFailed(int count) {
    return '$count ناکام';
  }

  @override
  String scriptCallsDenied(int count) {
    return '$count منع';
  }

  @override
  String scriptCallsCancelled(int count) {
    return '$count منسوخ';
  }

  @override
  String scriptCallsQueued(int count) {
    return '$count قطار میں';
  }

  @override
  String scriptCallsSkipped(int count) {
    return '$count چھوڑا گیا';
  }

  @override
  String get scriptStepQueued => 'قطار میں';

  @override
  String get scriptStepSkipped => 'چھوڑا گیا';

  @override
  String get scriptGroupLoop => 'لوپ';

  @override
  String get scriptGroupEach => 'ہر ایک کے لیے';

  @override
  String get scriptGroupParallel => 'ایک ساتھ';

  @override
  String get scriptGroupFunction => 'فنکشن';

  @override
  String scriptCallsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مزید کالز دکھائیں',
      one: '1 مزید کال دکھائیں',
    );
    return '$_temp0';
  }

  @override
  String get scriptCallsUnplaced => 'وہ کالز جو اسکرپٹ میں جگہ نہ پا سکیں';

  @override
  String get scriptToolComputed => 'ٹول';

  @override
  String scriptStepSemantics(String subject, String state) {
    return '$subject، $state';
  }

  @override
  String get scriptSourceLabel => 'اسکرپٹ';

  @override
  String scriptSourceLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count لائنیں',
      one: '1 لائن',
    );
    return '$_temp0';
  }

  @override
  String get scriptStateRunning => 'چل رہا ہے';

  @override
  String get scriptStateCompleted => 'مکمل';

  @override
  String get scriptStateFailed => 'ناکام';

  @override
  String get scriptStateTimedOut => 'وقت ختم ہو گیا';

  @override
  String get scriptStateCancelled => 'منسوخ';

  @override
  String get scriptStateMemoryExceeded => 'میموری ختم';

  @override
  String get scriptStateOutputExceeded => 'آؤٹ پٹ بہت زیادہ';

  @override
  String get scriptStateSandboxError => 'سینڈ باکس کی خرابی';

  @override
  String get scriptStateRefused => 'مسترد';

  @override
  String get transcriptToolDenied => 'منع';

  @override
  String get transcriptStatusRunningScript => 'اسکرپٹ چل رہا ہے…';

  @override
  String get scriptOriginLine => 'ایجنٹ کے چلائے ہوئے اسکرپٹ سے';

  @override
  String get scriptOriginShow => 'اسکرپٹ دکھائیں';

  @override
  String get codeModeTitle => 'کوڈ موڈ';

  @override
  String get codeModeSubtitle =>
      'ایجنٹس ایک مختصر اسکرپٹ لکھ سکتے ہیں جو ان کے ٹولز کو کال کرے، ایک ایک کر کے کال کرنے کے بجائے۔';

  @override
  String get codeModeStatusLabel => 'اسٹیٹس';

  @override
  String get codeModeFactAvailability => 'اس سرور پر';

  @override
  String get codeModeAvailable => 'دستیاب';

  @override
  String get codeModeUnavailable => 'دستیاب نہیں';

  @override
  String get codeModeFactRunner => 'رنر';

  @override
  String codeModeUnavailableNote(String reason) {
    return 'یہ سرور اسکرپٹس نہیں چلا سکتا، اس لیے یہاں ایجنٹس اپنے ٹولز ایک ایک کر کے کال کرتے ہیں۔ سرور کہتا ہے: $reason';
  }

  @override
  String get codeModeNoReason => 'کوئی وجہ نہیں دی گئی۔';

  @override
  String get codeModeViewExecutions => 'کوڈ ایگزیکیوشنز دیکھیں';

  @override
  String get codeModeLimitsLabel => 'حدیں';

  @override
  String get codeModeLimitsSubtitle =>
      'ایک اسکرپٹ کتنی دیر اور کہاں تک چل سکتا ہے۔ ڈیفالٹ زیادہ تر ورک اسپیسز کے لیے موزوں ہیں۔';

  @override
  String get codeModeLimitsDisclosure => 'حدیں تبدیل کریں';

  @override
  String get codeModeLimitsAtDefaults => 'ڈیفالٹ';

  @override
  String codeModeLimitsChangedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تبدیل شدہ',
      one: '1 تبدیل شدہ',
    );
    return '$_temp0';
  }

  @override
  String get codeModeLimitsUseDefaults => 'ڈیفالٹ استعمال کریں';

  @override
  String get codeModeLimitWallClock => 'ہر اسکرپٹ کا وقت';

  @override
  String get codeModeLimitWallClockHelp =>
      'کسی شخص کے انتظار کا وقت شمار نہیں ہوتا۔';

  @override
  String get codeModeLimitCpu => 'پروسیسر کا وقت';

  @override
  String get codeModeLimitCpuHelp =>
      'وہ وقت جو اسکرپٹ خود حساب کتاب میں صرف کرتا ہے۔';

  @override
  String get codeModeLimitHeap => 'میموری';

  @override
  String get codeModeLimitHeapHelp =>
      'وہ میموری جو اسکرپٹ چلتے ہوئے استعمال کر سکتا ہے۔';

  @override
  String get codeModeLimitNestedCalls => 'ہر اسکرپٹ کے ٹول کالز';

  @override
  String get codeModeLimitNestedCallsHelp =>
      'اس سے زیادہ کالز مسترد ہوں گی اور اسکرپٹ کو وجہ بتائی جائے گی۔';

  @override
  String get codeModeLimitInFlight => 'ایک وقت میں کالز';

  @override
  String get codeModeLimitInFlightHelp =>
      'ایک اسکرپٹ کی وہ کالز جو ایک ساتھ چل سکتی ہیں۔';

  @override
  String get codeModeLimitOutputTokens => 'ایجنٹ جو آؤٹ پٹ پڑھتا ہے';

  @override
  String get codeModeLimitOutputTokensHelp =>
      'لمبا آؤٹ پٹ مختصر کر دیا جاتا ہے؛ ایجنٹ درخواست پر باقی حصہ پڑھ سکتا ہے۔';

  @override
  String codeModeLimitRange(String defaultValue, String min, String max) {
    return 'ڈیفالٹ $defaultValue۔ $min سے $max تک۔';
  }

  @override
  String codeModeLimitOutOfRange(String min, String max) {
    return '$min سے $max تک ایک مکمل عدد درج کریں۔';
  }

  @override
  String get codeModeSuffixSeconds => 'سیکنڈ';

  @override
  String get codeModeSuffixMebibytes => 'MiB';

  @override
  String get codeModeSuffixCalls => 'کالز';

  @override
  String get codeModeSuffixTokens => 'ٹوکنز';

  @override
  String codeModeServerCap(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'یہ سرور تمام ورک اسپیسز میں ایک وقت میں زیادہ سے زیادہ $count اسکرپٹس چلاتا ہے۔',
      one:
          'یہ سرور تمام ورک اسپیسز میں ایک وقت میں زیادہ سے زیادہ 1 اسکرپٹ چلاتا ہے۔',
    );
    return '$_temp0';
  }

  @override
  String codeModeUnitMilliseconds(String value) {
    return '$value ms';
  }

  @override
  String codeModeUnitSeconds(String value) {
    return '$value سیکنڈ';
  }

  @override
  String codeModeUnitMinutesSeconds(String minutes, String seconds) {
    return '$minutes منٹ $seconds سیکنڈ';
  }

  @override
  String get codeModeRefusedLimitUnknown =>
      'سرور ان حدوں میں سے ایک کو نہیں جانتا۔';

  @override
  String get codeModeRefusedLimitOutOfRange =>
      'ان حدوں میں سے ایک سرور کی اجازت شدہ حد سے باہر ہے۔';

  @override
  String get codeModeRefusedUnknownSetting => 'سرور نے یہ ترتیب نہیں پہچانی۔';

  @override
  String get codeExecutionsTitle => 'کوڈ ایگزیکیوشنز';

  @override
  String get codeExecutionsSubtitle =>
      'ایجنٹس نے اس ورک اسپیس میں جو اسکرپٹس چلائے، ان کی ہر ٹول کال کے ساتھ۔';

  @override
  String get codeExecutionsEmpty => 'یہاں ابھی تک کوئی اسکرپٹ نہیں چلا۔';

  @override
  String get codeExecutionsEmptyFiltered =>
      'ان فلٹرز سے کوئی اسکرپٹ مماثل نہیں۔';

  @override
  String get codeExecutionsStatusFilter => 'نتیجہ';

  @override
  String get codeExecutionsAllOutcomes => 'تمام نتائج';

  @override
  String codeExecutionsOutcomeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نتائج',
      one: '1 نتیجہ',
    );
    return '$_temp0';
  }

  @override
  String get codeExecutionsScopeRun => 'ایک رن کے اسکرپٹس';

  @override
  String get codeExecutionsScopeConversation => 'ایک گفتگو کے اسکرپٹس';

  @override
  String get codeExecutionsScopeAgent => 'ایک ایجنٹ کے اسکرپٹس';

  @override
  String get codeExecutionsShowAll => 'سب دکھائیں';

  @override
  String get codeExecutionUntitled => 'بے نام اسکرپٹ';

  @override
  String get codeExecutionRecord => 'ریکارڈ';

  @override
  String get codeExecutionBackToList => 'کوڈ ایگزیکیوشنز پر واپس';

  @override
  String get codeExecutionNotFound =>
      'یہ کوڈ ایگزیکیوشن اس ورک اسپیس میں نہیں ہے۔ ہو سکتا ہے اسے اس کے رن کے ساتھ ہٹا دیا گیا ہو۔';

  @override
  String get codeExecutionRefusedSpace =>
      'یہ اسکرپٹ ایک ایسی اسپیس میں چلا جسے آپ نہیں کھول سکتے، اس لیے اس کا ریکارڈ چھپا رہے گا۔';

  @override
  String get codeExecutionOpenRecord => 'ریکارڈ کھولیں';

  @override
  String get codeExecutionFactStarted => 'شروع ہوا';

  @override
  String get codeExecutionFactDuration => 'دورانیہ';

  @override
  String get codeExecutionFactCalls => 'ٹول کالز';

  @override
  String get codeExecutionFactAgent => 'ایجنٹ';

  @override
  String get codeExecutionFactSurface => 'کے ذریعے چلا';

  @override
  String get codeExecutionSurfaceHarness => 'بلٹ اِن ایجنٹ';

  @override
  String get codeExecutionSurfaceMcp => 'بیرونی ایجنٹ';

  @override
  String get codeExecutionFactCpu => 'پروسیسر کا وقت';

  @override
  String get codeExecutionFactMemory => 'زیادہ سے زیادہ میموری';

  @override
  String get codeExecutionOpenConversation => 'گفتگو کھولیں';

  @override
  String get codeExecutionRunScripts => 'اس رن کے اسکرپٹس';

  @override
  String get codeExecutionAgentScripts => 'اس ایجنٹ کے اسکرپٹس';

  @override
  String get codeExecutionScript => 'اسکرپٹ';

  @override
  String get codeExecutionConsole => 'کنسول';

  @override
  String get codeExecutionOutputTruncated =>
      'آؤٹ پٹ محفوظ شدہ حصے میں فٹ کرنے کے لیے کاٹ دیا گیا۔';

  @override
  String get codeExecutionNoPayload =>
      'اسکرپٹ اور اس کا آؤٹ پٹ اب محفوظ نہیں رکھے جاتے۔';

  @override
  String codeExecutionCallsHeading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ٹول کالز',
      one: '1 ٹول کال',
      zero: 'ٹول کالز',
    );
    return '$_temp0';
  }

  @override
  String get codeExecutionNoCalls => 'اسکرپٹ نے کوئی ٹول کال نہیں کیا۔';

  @override
  String get codeExecutionCallCompleted => 'مکمل';

  @override
  String get codeExecutionCallFailed => 'ناکام';

  @override
  String get codeExecutionCallDenied => 'منع';

  @override
  String get codeExecutionCallCancelled => 'منسوخ';

  @override
  String get codeExecutionCallTimedOut => 'وقت ختم ہو گیا';

  @override
  String get codeExecutionCallUnknownTool => 'نامعلوم ٹول';

  @override
  String get codeExecutionCallInvalidArgs => 'غلط آرگومنٹس';

  @override
  String get codeExecutionGateAllowed => 'اجازت';

  @override
  String get codeExecutionGateApproved => 'ایک شخص نے منظور کیا';

  @override
  String get codeExecutionGateDenied => 'منع';

  @override
  String get codeExecutionGateNotReached => 'چیک نہیں ہوا';

  @override
  String codeExecutionCallWaited(String duration) {
    return 'ایک شخص کے لیے $duration انتظار کیا';
  }

  @override
  String get codeExecutionCallArguments => 'آرگومنٹس';

  @override
  String get codeExecutionCallResult => 'نتیجہ';

  @override
  String codeExecutionCallResultSize(String size) {
    return '$size واپس آیا';
  }

  @override
  String codeExecutionBytes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بائٹس',
      one: '1 بائٹ',
    );
    return '$_temp0';
  }

  @override
  String get codeExecutionEndedScriptError =>
      'اسکرپٹ نے ایک خرابی پھینکی اور اسے کسی نے نہیں پکڑا۔';

  @override
  String codeExecutionEndedScriptErrorNamed(String name) {
    return 'اسکرپٹ نے $name پھینکا اور اسے کسی نے نہیں پکڑا۔';
  }

  @override
  String get codeExecutionEndedStalled =>
      'اسکرپٹ ایسی چیز کا انتظار کر رہا تھا جو کبھی ختم نہیں ہو سکتی۔';

  @override
  String get codeExecutionEndedCpu => 'اسکرپٹ کا پروسیسر کا وقت ختم ہو گیا۔';

  @override
  String get codeExecutionEndedHeap => 'اسکرپٹ اپنی میموری کی حد تک پہنچ گیا۔';

  @override
  String get codeExecutionEndedOutput =>
      'اسکرپٹ نے اجازت سے زیادہ آؤٹ پٹ لکھا۔';

  @override
  String get codeExecutionEndedDeadline => 'اسکرپٹ کا وقت ختم ہو گیا۔';

  @override
  String get codeExecutionEndedCancelled =>
      'اسکرپٹ ختم ہونے سے پہلے منسوخ ہو گیا۔';

  @override
  String get codeExecutionEndedShutdown => 'اسکرپٹ چلتے ہوئے سرور بند ہو گیا۔';

  @override
  String get codeExecutionEndedServerStopped =>
      'اسکرپٹ چلتے ہوئے سرور رک گیا۔ سرور دوبارہ شروع ہونے پر ریکارڈ بند کر دیا گیا۔';

  @override
  String get codeExecutionEndedInternal =>
      'اسکرپٹ چلانے والا پروگرام خود ناکام ہو گیا۔';

  @override
  String get codeExecutionEndedStart =>
      'اسکرپٹ چلانے والا پروگرام شروع نہیں ہو سکا۔';

  @override
  String get codeExecutionEndedLockdown =>
      'اسکرپٹ چلانے والا پروگرام خود کو مکمل طور پر محدود نہیں کر سکا، اس لیے اسکرپٹ نہیں چلا۔';

  @override
  String get codeExecutionEndedExited =>
      'اسکرپٹ ختم ہونے سے پہلے اسکرپٹ چلانے والا پروگرام رک گیا۔';

  @override
  String get codeExecutionEndedRunnerBrokeRules =>
      'اسکرپٹ چلانے والے پروگرام نے اپنے قواعد توڑے اور اسے روک دیا گیا۔';

  @override
  String get codeExecutionEndedUnresponsive =>
      'اسکرپٹ چلانے والا پروگرام جواب دینا بند کر گیا اور اسے روک دیا گیا۔';

  @override
  String get codeExecutionEndedHostError =>
      'اسکرپٹ چلاتے ہوئے سرور خرابی سے دوچار ہوا۔';

  @override
  String get codeExecutionRunningNote =>
      'ابھی چل رہا ہے۔ اس کی ٹول کالز ختم ہوتے ہی یہاں ظاہر ہوں گی، اور اس کا نتیجہ ختم ہونے پر دکھایا جائے گا۔';

  @override
  String codeModeServerWorkspaceShare(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'ایک ورک اسپیس کے اسکرپٹس زیادہ سے زیادہ ان میں سے $count استعمال کر سکتے ہیں۔',
      one:
          'ایک ورک اسپیس کے اسکرپٹس زیادہ سے زیادہ ان میں سے 1 استعمال کر سکتے ہیں۔',
    );
    return '$_temp0';
  }

  @override
  String get wakeOriginGoal => 'ہدف';

  @override
  String get wakeOriginGoalCheck => 'ہدف کی جانچ';

  @override
  String get wakeOriginGoalReview => 'ہدف کا ریویو';

  @override
  String get wakeOriginSchedule => 'شیڈول';

  @override
  String get wakeOriginWatch => 'نگرانی';

  @override
  String wakeOriginReplyFrom(String agent) {
    return '$agent کا جواب';
  }

  @override
  String get wakeOriginReply => 'جواب';

  @override
  String wakeOriginMessageFrom(String agent) {
    return '$agent کا پیغام';
  }

  @override
  String get wakeOriginMessage => 'پیغام';

  @override
  String wakeOriginWorkFinishedBy(String agent) {
    return '$agent کا مکمل کیا ہوا کام';
  }

  @override
  String get wakeOriginWorkFinished => 'مکمل شدہ کام';

  @override
  String get wakeOriginLimitReset => 'حد ری سیٹ';

  @override
  String get wakeOriginRecovery => 'بحالی';

  @override
  String get wakeOriginAssignment => 'تفویض';

  @override
  String get wakeOriginPipelineStep => 'پائپ لائن کا مرحلہ';

  @override
  String get wakeOriginImprovementReview => 'بہتری کا ریویو';

  @override
  String get wakeKindStopped => 'کسی شخص نے رن روکا تھا، اس لیے یہ روکی گئی۔';

  @override
  String get wakeKindAttempts => 'ڈیلیوری تین بار ناکام ہوئی۔';

  @override
  String get wakeKindAgentDeleted => 'ایجنٹ اب موجود نہیں۔';

  @override
  String get wakeKindAgentNotDispatchable => 'ایجنٹ ریٹائر ہو چکا ہے۔';

  @override
  String get wakeKindAgentPaused => 'ایجنٹ توقف پر ہے۔';

  @override
  String get wakeKindPersonRemoved =>
      'وہ شخص جس کی طرف سے یہ کام کرتا ہے، ورک اسپیس چھوڑ گیا ہے۔';

  @override
  String get wakeKindBudgetBlocked => 'بجٹ رن کو روک رہا ہے۔';

  @override
  String get wakeKindTakeOver => 'ایک شخص نے worktree سنبھال لیا ہے۔';

  @override
  String get wakeKindRateCapConversation =>
      'اس گفتگو نے پچھلے ایک گھنٹے میں بیداریوں سے 30 رن شروع کیے۔';

  @override
  String get wakeKindRateCapWorkspace =>
      'اس ورک اسپیس نے پچھلے ایک گھنٹے میں بیداریوں سے 300 رن شروع کیے۔';

  @override
  String get wakeKindLiveRunNoInput =>
      'ایجنٹ کا جاری رن یہاں ان پٹ قبول نہیں کرتا۔';

  @override
  String get wakeKindLiveRunOtherOptions =>
      'ایجنٹ کا جاری رن یہاں مختلف ترتیبات سے چلتا ہے، اس لیے یہ اس کے بعد اپنا رن شروع کرے گا۔';

  @override
  String get wakeKindLiveRunOtherPerson =>
      'ایجنٹ کا جاری رن یہاں کسی اور کی طرف سے چل رہا ہے، اس لیے یہ اس کے بعد اپنا رن شروع کرے گا۔';

  @override
  String get wakeKindDispatchRefused => 'رن شروع نہیں ہو سکا۔';

  @override
  String get wakeKindSandboxUnavailable =>
      'صرف پڑھنے والے رن کے لیے کوئی سینڈ باکس دستیاب نہیں۔';

  @override
  String get wakeKindReadOnlyUnavailable =>
      'اس ایجنٹ کا بیک اینڈ رن کو صرف پڑھنے تک محدود نہیں رکھ سکتا۔';

  @override
  String get wakeKindServerStopped => 'سرور کے ری اسٹارٹ نے رن روک دیا۔';

  @override
  String get wakeKindServerRestarted =>
      'کسی شخص کے رن کے دوران سرور ری اسٹارٹ ہوا۔';

  @override
  String get wakeKindGuardFailed => 'ڈیلیوری سے پہلے ایک جانچ ناکام ہوئی۔';

  @override
  String get wakeKindLimit => 'فراہم کنندہ کی استعمال کی حد پر انتظار۔';

  @override
  String get wakeKindLimitRunLive => 'استعمال کی حد پر رن ختم ہونے کا انتظار۔';

  @override
  String get wakeKindWakeMissed => 'سرور بند ہونے کے دوران چھوٹ گئی۔';

  @override
  String get wakeKindPipelineRunEnded => 'اس کا پائپ لائن رن ختم ہو چکا ہے۔';

  @override
  String get wakeKindGoalEnded => 'اس کا ہدف ختم ہو چکا ہے۔';

  @override
  String get wakeKindGoalBudgetExhausted => 'اس ہدف کا بجٹ ختم ہو گیا۔';

  @override
  String get wakeKindGoalReviewStale =>
      'اس ریویو کے مانگے جانے کے بعد ہدف بدل گیا ہے۔';

  @override
  String get wakeKindGoalPaused => 'اس کا ہدف توقف پر ہے۔';

  @override
  String get wakeKindGoalHeld => 'اس کا ہدف روکا ہوا ہے۔';

  @override
  String get wakeKindGoalStopped => 'اس کا ہدف روک دیا گیا۔';

  @override
  String get wakeKindAskSettled =>
      'جس سوال کا یہ جواب دیتی تھی، وہ پہلے ہی طے ہو چکا ہے۔';

  @override
  String get wakeKindRuleEnded => 'اس کا شیڈول ختم ہو چکا ہے۔';

  @override
  String get wakeKindUnknown => 'اس ورژن کے لیے یہ وجہ نامعلوم ہے:';

  @override
  String wakeStripHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بیداریاں انتظار میں',
      one: '1 بیداری انتظار میں',
    );
    return '$_temp0';
  }

  @override
  String wakeStripDue(String time) {
    return '$time پر مقرر';
  }

  @override
  String get wakeStripDueNow => 'اب مقرر';

  @override
  String get wakeStripHeld => 'روکی گئی';

  @override
  String wakeStripExpires(String time) {
    return '$time پر ختم';
  }

  @override
  String wakeStripAttempt(int attempt) {
    return 'کوشش $attempt';
  }

  @override
  String get wakeStripCancel => 'بیداری منسوخ کریں';

  @override
  String get wakeStripDeliverNow => 'ابھی بھیجیں';

  @override
  String get wakeStripResume => 'جاری رکھیں';

  @override
  String get wakeStripDismiss => 'برطرف کریں';

  @override
  String get wakeStripResumeAll => 'سب جاری رکھیں';

  @override
  String get wakeStripResumeOnlyTheirs =>
      'صرف وہی شخص جس کا یہ رن ہے، اسے جاری رکھ سکتا ہے۔';

  @override
  String get wakeReceiptStarted => 'ایک رن شروع ہوا۔';

  @override
  String get wakeReceiptPushed => 'جاری رن کو دے دی گئی۔';

  @override
  String wakeReceiptWaiting(String reason) {
    return 'ابھی بھی انتظار میں ہے۔ $reason';
  }

  @override
  String wakeReceiptSkipped(String reason) {
    return 'نہیں بھیجی گئی۔ $reason';
  }

  @override
  String get wakeReceiptDuplicate => 'پہلے ہی بھیجی جا چکی ہے۔';

  @override
  String wakeReleased(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بیداریاں جاری کی گئیں۔',
      one: '1 بیداری جاری کی گئی۔',
      zero: 'کچھ بھی جاری نہیں ہوا۔',
    );
    return '$_temp0';
  }

  @override
  String get wakeRefusalNotYours =>
      'یہ بیداری کسی اور شخص کے لیے کام کرتی ہے۔ صرف وہی اسے بھیج یا جاری رکھ سکتا ہے۔';

  @override
  String get wakeRefusalSettled => 'یہ بیداری پہلے ہی طے ہو چکی ہے۔';

  @override
  String heldSteeringHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count روکے ہوئے پیغامات',
      one: '1 روکا ہوا پیغام',
    );
    return '$_temp0';
  }

  @override
  String get heldSteeringResume => 'روکے ہوئے پیغامات بھیجیں';

  @override
  String get heldSteeringDelete => 'روکا ہوا پیغام حذف کریں';

  @override
  String heldSteeringReleased(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count روکے ہوئے پیغامات بھیجے گئے۔',
      one: '1 روکا ہوا پیغام بھیجا گیا۔',
      zero: 'کوئی پیغام روکا نہیں گیا تھا۔',
    );
    return '$_temp0';
  }

  @override
  String get workAgentUnknown => 'ایک ایجنٹ';

  @override
  String workFeedWoke(int count, String agent) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$agent کو $count انتظار کرنے والی چیزوں کے لیے جگایا گیا',
      one: '$agent کو جگایا گیا',
    );
    return '$_temp0';
  }

  @override
  String workFeedWakeSkipped(String agent) {
    return '$agent کے لیے ایک بیداری نہیں بھیجی گئی۔';
  }

  @override
  String workFeedWakeMissed(String agent) {
    return 'سرور بند ہونے کے دوران $agent کے لیے ایک بیداری چھوٹ گئی۔';
  }

  @override
  String workFeedScheduleCreated(String agent) {
    return '$agent کے لیے شیڈول مقرر کیا گیا۔';
  }

  @override
  String workFeedScheduleEnded(String agent) {
    return '$agent کا شیڈول ختم ہو گیا۔';
  }

  @override
  String get workFeedOpenSchedule => 'شیڈول کھولیں';

  @override
  String workFeedNoteFromAgent(String agent) {
    return '$agent نے اپنے لیے یہ نوٹ اپنے الفاظ میں چھوڑا:';
  }

  @override
  String get workFeedNoteFromPerson => 'ایک شخص کی طرف سے مقرر کردہ یاد دہانی:';

  @override
  String workFeedLimitParkHeld(String provider, String time) {
    return '$provider کی استعمال کی حد پر توقف۔ حد $time پر ری سیٹ ہوگی۔';
  }

  @override
  String workFeedLimitParkPending(String provider, String time) {
    return '$provider کی استعمال کی حد پر توقف۔ $time پر جاری ہوگا۔';
  }

  @override
  String workFeedLimitParkResumed(String provider) {
    return '$provider کی استعمال کی حد کے بعد جاری ہوا۔';
  }

  @override
  String workFeedLimitParkGone(String provider) {
    return '$provider کی استعمال کی حد پر اب انتظار نہیں ہے۔';
  }

  @override
  String get workFeedLimitParkResume => 'جاری رکھیں';

  @override
  String get workFeedLimitParkCancel => 'منسوخ کریں';

  @override
  String workFeedStillInFlight(String agent) {
    return 'کمپیکٹ ہونے کے بعد $agent کو دی گئی حالت';
  }

  @override
  String get workFeedShowDetails => 'تفصیلات دکھائیں';

  @override
  String get workFeedHideDetails => 'تفصیلات چھپائیں';

  @override
  String get workFeedCommandRefused => 'کمانڈ مسترد ہو گئی۔';

  @override
  String get wakeRuleEndFired => 'یہ اپنی ایک بار کی دوڑ مکمل کر چکا ہے۔';

  @override
  String get wakeRuleEndExpired => 'یہ اپنی آخری تاریخ تک پہنچ گیا۔';

  @override
  String get wakeRuleEndRunCap => 'اس نے اپنے رن استعمال کر لیے۔';

  @override
  String get wakeRuleEndCostCap => 'یہ اپنی لاگت کی حد تک پہنچ گیا۔';

  @override
  String get wakeRuleEndGoalEnded => 'اس کا ہدف ختم ہو چکا ہے۔';

  @override
  String get wakeRuleEndCancelled => 'اسے منسوخ کیا گیا۔';

  @override
  String get wakeRuleEndMemberRemoved => 'اس کا شخص ورک اسپیس چھوڑ گیا۔';

  @override
  String get wakeRuleEndInvalidRow =>
      'اس کی محفوظ شدہ ترتیبات پڑھی نہیں جا سکیں۔';

  @override
  String get wakeRuleRefusalIntervalTooShort =>
      'وقفہ بہت چھوٹا ہے۔ کوئی لمبا وقفہ منتخب کریں۔';

  @override
  String get wakeRuleRefusalTooSoon =>
      'وہ وقت بہت قریب ہے۔ کوئی بعد کا وقت منتخب کریں۔';

  @override
  String get wakeRuleRefusalLineageEnded =>
      'بیداریوں کا یہ سلسلہ اپنے رن یا وقت کی حد استعمال کر چکا ہے۔';

  @override
  String get wakeRuleRefusalWatchTargetUnreadable =>
      'آپ یہ نہیں پڑھ سکتے کہ اسے کیا دیکھنا ہے۔';

  @override
  String get wakeRuleRefusalExpiryRequired =>
      'اس کے لیے آخری وقت دیں، مثلاً --days 3۔';

  @override
  String get wakeRuleRefusalLimitReached =>
      'اس گفتگو کے پاس پہلے ہی اتنے شیڈول ہیں جتنے اجازت ہے۔';

  @override
  String get wakeRuleRefusalInvalidWhen => 'وقت پڑھا نہیں جا سکتا۔';

  @override
  String get wakeRuleRefusalNoteTooLong => 'نوٹ بہت لمبا ہے۔';

  @override
  String get wakeRuleRefusalExpiryTooLong => 'آخری وقت بہت دور ہے۔';

  @override
  String get wakeRuleRefusalLimitOutOfRange =>
      'رن، دن یا بجٹ کی حد دائرے سے باہر ہے۔';

  @override
  String get wakeRuleRefusalNextOutsideLoop =>
      'صرف لوپ اپنا اگلا وقت خود طے کر سکتا ہے۔';

  @override
  String get wakeRuleRefusalWatchRefused => 'اسے دیکھا نہیں جا سکتا۔';

  @override
  String get wakeRuleRefusalRuleEnded => 'یہ شیڈول پہلے ہی ختم ہو چکا ہے۔';

  @override
  String get wakeRuleRefusalNotYours => 'یہ شیڈول کسی اور کا ہے۔';

  @override
  String get workRefusalUnknown => 'سرور نے یہ مسترد کیا:';

  @override
  String get goalRefusalAlreadyActive =>
      'اس گفتگو میں پہلے سے ایک فعال ہدف ہے۔';

  @override
  String get goalRefusalNotInReview => 'یہ ہدف ریویو کے انتظار میں نہیں ہے۔';

  @override
  String get goalRefusalEvidenceIncomplete => 'ہدف کے ثبوت نامکمل ہیں۔';

  @override
  String get goalRefusalClaimPending =>
      'یہ دعویٰ کہ ہدف مکمل ہو گیا ہے، ابھی جانچا جا رہا ہے۔';

  @override
  String get goalRefusalNotActiveSegment => 'اس ہدف کا کوئی حصہ نہیں چل رہا۔';

  @override
  String get goalRefusalNotYours =>
      'صرف وہی شخص جس نے یہ ہدف شروع کیا، یہ کر سکتا ہے۔';

  @override
  String get goalRefusalNotPaused => 'پہلے ہدف کو توقف پر رکھیں۔';

  @override
  String get goalRefusalContractInvalid => 'ہدف کا معاہدہ پڑھا نہیں جا سکتا۔';

  @override
  String get goalRefusalCheckerUnknown => 'اس نام کا کوئی ایجنٹ نہیں ہے۔';

  @override
  String get goalRefusalCheckerAmbiguous =>
      'اس نام کے ایک سے زیادہ ایجنٹ ہیں۔ اس کا id استعمال کریں۔';

  @override
  String get goalRefusalCheckerIsGoalAgent =>
      'چیکر کام کرنے والے ایجنٹ کے علاوہ کوئی اور ایجنٹ ہونا چاہیے۔';

  @override
  String get goalRefusalCommandInvalid => 'یہ /goal کمانڈ پڑھی نہیں جا سکتی۔';

  @override
  String goalCardWorking(int segment) {
    return 'کام جاری · حصہ $segment';
  }

  @override
  String get goalCardWaiting => 'اگلی بیداری کا انتظار';

  @override
  String get goalCardVerifying => 'جانچ ہو رہی ہے کہ ہدف مکمل ہوا یا نہیں';

  @override
  String goalCardLimitUntil(String time) {
    return 'استعمال کی حد پر توقف · $time پر جاری';
  }

  @override
  String get goalCardLimit => 'استعمال کی حد پر توقف';

  @override
  String get goalCardPerson => 'کسی شخص کی ضرورت ہے';

  @override
  String get goalCardByPerson => 'ایک شخص نے توقف کیا';

  @override
  String get goalCardNeedsReview =>
      'ریویو کا انتظار: اس نے کہا کہ ہدف مکمل ہے، اور کسی نے تصدیق نہیں کی';

  @override
  String goalCardSegments(int run, int max) {
    return 'حصہ $run از $max';
  }

  @override
  String goalCardSegmentsNoCap(int run) {
    return 'حصہ $run';
  }

  @override
  String goalCardMoney(String spent, String cap) {
    return '$spent از $cap';
  }

  @override
  String goalCardTimeLeft(String time) {
    return '$time باقی';
  }

  @override
  String get goalCardOverdue => 'آخری وقت گزر چکا';

  @override
  String get goalCardDoneMeans => 'مکمل ہونے کا مطلب';

  @override
  String get goalCardChecks => 'چیکس';

  @override
  String get goalCardCheckPassed => 'پاس';

  @override
  String goalCardCheckFailed(int code) {
    return 'ناکام · ایگزٹ کوڈ $code';
  }

  @override
  String get goalCardCheckTimedOut => 'وقت ختم ہو گیا';

  @override
  String get goalCardCheckNotRerun => 'دوبارہ نہیں چلایا: کچھ نہیں بدلا';

  @override
  String get goalCardCheckBroken => 'چل نہیں سکتا';

  @override
  String get goalCardCheckNotRun => 'ابھی تک نہیں چلایا';

  @override
  String get goalCardCriterionMet => 'پورا ہوا';

  @override
  String get goalCardCriterionUnmet => 'پورا نہیں ہوا';

  @override
  String get goalCardCriterionCannotTell => 'کہہ نہیں سکتے';

  @override
  String get goalCardVerdictPass => 'آخری جانچ: مکمل';

  @override
  String get goalCardVerdictFail => 'آخری جانچ: مکمل نہیں';

  @override
  String get goalCardVerdictCannotVerify => 'آخری جانچ: فیصلہ نہ ہو سکا';

  @override
  String get goalCardConcerns => 'تحفظات';

  @override
  String goalCardVerifiedBy(String agent) {
    return '$agent نے تصدیق کی';
  }

  @override
  String get goalCardVerifiedBySelf => 'خود تصدیق کی (کوئی علیحدہ چیکر نہیں)';

  @override
  String get goalCardClosedByPerson => 'ایک شخص نے بغیر کامیاب جانچ کے بند کیا';

  @override
  String get goalCardNoMachineCheck => 'کوئی مشینی جانچ نہیں';

  @override
  String get goalCardAddCheck => 'جانچ شامل کریں';

  @override
  String get goalCardOpen => 'ہدف کھولیں';

  @override
  String get goalCardApprove => 'تکمیل کی منظوری دیں';

  @override
  String get goalCardApproveTitle => 'کیا اس ہدف کو مکمل کے طور پر بند کریں؟';

  @override
  String get goalCardApproveBody =>
      'کسی جانچ نے اس کی تصدیق نہیں کی۔ آپ اپنے کہنے پر اسے بند کر رہے ہیں، اور ہدف ریکارڈ کرے گا کہ ایک شخص نے اسے بغیر تصدیق کے بند کیا۔';

  @override
  String get goalCardApproveConfirm => 'مکمل کے طور پر بند کریں';

  @override
  String get goalCardResumeNotYours =>
      'اسے جاری رکھنا یا اس کا بجٹ بڑھانا اسے شروع کرنے والے شخص کا کام ہے۔';

  @override
  String get goalHoldDetailStalled =>
      'اس کے آخری حصوں میں کوئی پیش رفت نہیں ہوئی۔';

  @override
  String get goalHoldDetailStalledWaiting =>
      'بغیر پیش رفت کے حصوں کے بعد انتظار۔';

  @override
  String get goalHoldDetailVerificationFailed => 'آخری جانچ ناکام ہوئی۔';

  @override
  String get goalHoldDetailCannotVerify =>
      'چیکر یہ نہیں بتا سکا کہ ہدف مکمل ہوا یا نہیں۔';

  @override
  String get goalHoldDetailSandboxUnavailable =>
      'اس کی جانچیں چلانے کے لیے کوئی سینڈ باکس دستیاب نہیں۔';

  @override
  String get goalHoldDetailCheckerUnavailable =>
      'اس کا چیکر ایجنٹ دستیاب نہیں۔ کوئی اور چیکر منتخب کریں، پھر جاری رکھیں۔';

  @override
  String get goalHoldDetailCheckBroken => 'یہ جانچ نہیں چل سکتی:';

  @override
  String get goalHoldDetailWakeSkipped => 'اس کی بیداری نہیں بھیجی گئی۔';

  @override
  String get goalHoldDetailClaimPending =>
      'مکمل ہونے کا اس کا دعویٰ جانچ کا انتظار کر رہا ہے۔';

  @override
  String get goalHoldDetailUnanswered =>
      'کسی شخص سے پوچھا گیا سوال یا منظوری کی درخواست بے جواب رہی۔';

  @override
  String get goalHoldDetailLimitParks =>
      'یہ استعمال کی حدوں پر بار بار رکا۔ اسے دیکھیں، پھر جاری رکھیں۔';

  @override
  String get goalHoldDetailInput => 'گفتگو میں جواب کا انتظار۔';

  @override
  String get peerAsksSection => 'سوالات';

  @override
  String peerAskTo(String agent) {
    return '$agent کو';
  }

  @override
  String get peerAskKindAsk => 'سوال';

  @override
  String get peerAskKindConsult => 'مشورہ';

  @override
  String get peerAskKindReview => 'ریویو';

  @override
  String get peerAskStatusPending => 'انتظار میں';

  @override
  String get peerAskStatusAnswered => 'جواب دیا گیا';

  @override
  String get peerAskStatusFailed => 'ناکام';

  @override
  String get peerAskStatusExpired => 'ختم';

  @override
  String get peerAskStatusCancelled => 'منسوخ';

  @override
  String peerAskAsked(String time) {
    return '$time پر پوچھا';
  }

  @override
  String peerAskExpires(String time) {
    return '$time پر ختم';
  }

  @override
  String get peerAskPromised => 'جواب کا وعدہ کیا';

  @override
  String get peerAskBackground => 'پس منظر میں';

  @override
  String get peerAskCancel => 'سوال منسوخ کریں';

  @override
  String get peerAskAlreadySettled => 'یہ سوال پہلے ہی طے ہو چکا ہے۔';

  @override
  String get slashHintGoal =>
      'ہدف مکمل ہونے تک اس پر کام کریں۔ فلیگز: --check, --checker, --fresh, --unattended';

  @override
  String get slashHintLoop =>
      'ایک کام دہرائیں، ہر وقفے پر یا ایجنٹ کی رفتار سے';

  @override
  String get slashHintSchedule =>
      'کام بعد میں چلائیں: in 2h، at 09:00 یا cron پر';

  @override
  String get slashHintRefine =>
      'اس گفتگو کے کام کا ریویو کریں اور بہتری تجویز کریں';

  @override
  String get notifGoalCompleted => 'ہدف مکمل ہوا';

  @override
  String get notifGoalFailed => 'ہدف ناکام ہوا';

  @override
  String get notifGoalCancelled => 'ہدف منسوخ ہوا';

  @override
  String get notifGoalBudgetExhausted => 'ہدف نے اپنا بجٹ استعمال کر لیا';

  @override
  String get notifGoalNeedsReview => 'ایک ہدف آپ کے ریویو کا منتظر ہے';

  @override
  String get notifGoalNeedsPerson => 'ایک ہدف کو آپ کی ضرورت ہے';

  @override
  String get notifGoalOnHold => 'ایک ہدف روکا ہوا ہے';

  @override
  String get notifWakeRuleEnded => 'ایک شیڈول ختم ہوا';

  @override
  String notifWaitingDigest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count چیزیں آپ کے انتظار میں ہیں',
      one: '1 چیز آپ کے انتظار میں ہے',
    );
    return '$_temp0';
  }

  @override
  String notifImprovementProposed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بہتریاں تجویز کی گئیں',
      one: 'ایک بہتری تجویز کی گئی',
    );
    return '$_temp0';
  }

  @override
  String get notifPipelineRunHeld => 'ایک پائپ لائن رن اپنے بجٹ پر روکا گیا ہے';

  @override
  String notifPipelineRunHeldBody(String spent, String cap) {
    return '$spent از $cap خرچ';
  }

  @override
  String get inboxGoalNeedsReview => 'ہدف ریویو کا منتظر ہے';

  @override
  String get inboxGoalNeedsPerson => 'ہدف کو آپ کی ضرورت ہے';

  @override
  String get inboxImprovementProposed => 'بہتری تجویز کی گئی';

  @override
  String get improvementRefusalAlreadyDecided =>
      'اس تجویز پر کوئی فیصلہ پہلے ہی ہو چکا ہے۔';

  @override
  String get improvementRefusalCampaignRequired =>
      'یہ تبدیلی موجودہ مہارت کے خلاف جانچ پاس نہیں ہوئی، یا جانچ کے بعد مہارت بدل گئی۔ جانچ دوبارہ چلائیں۔';

  @override
  String get improvementRefusalChangedSince =>
      'یہ تجویز پیش کیے جانے کے بعد ہدف بدل گیا ہے۔ اسے مسترد کریں اور ایجنٹ کو دوبارہ تجویز کرنے دیں۔';

  @override
  String get improvementRefusalTargetMissing =>
      'یہ تجویز جس چیز کو بدلتی ہے، وہ اب موجود نہیں۔';

  @override
  String get improvementRefusalCampaignState =>
      'جانچ اپنی موجودہ حالت میں شروع یا مکمل نہیں ہو سکتی۔';

  @override
  String get improvementRefusalReviewCooldown =>
      'اس گفتگو کا ابھی حال ہی میں ریویو ہوا ہے۔ بعد میں دوبارہ کوشش کریں۔';

  @override
  String get improvementRefusalAdminRequired =>
      'اس تجویز پر صرف ورک اسپیس ایڈمن فیصلہ کر سکتا ہے۔';

  @override
  String get improvementKindMemoryFact => 'میموری کی بات';

  @override
  String get improvementKindPolicy => 'پالیسی';

  @override
  String get improvementKindAgentNote => 'ایجنٹ نوٹ';

  @override
  String get improvementKindSkillEdit => 'مہارت میں تبدیلی';

  @override
  String get improvementKindSkillNew => 'نئی مہارت';

  @override
  String get improvementScopeAgent => 'یہ ایجنٹ';

  @override
  String get improvementScopeRepository => 'یہ ریپوزٹری';

  @override
  String get improvementScopeWorkspace => 'پورا ورک اسپیس';

  @override
  String get improvementStatusProposed => 'تجویز کردہ';

  @override
  String get improvementStatusAccepted => 'قبول شدہ';

  @override
  String get improvementStatusRejected => 'مسترد';

  @override
  String get improvementStatusRolledBack => 'واپس لیا گیا';

  @override
  String get improvementStatusExpired => 'ختم';

  @override
  String get improvementOperationAdd => 'شامل کرتا ہے';

  @override
  String get improvementOperationReplace => 'بدلتا ہے';

  @override
  String get improvementOperationRemove => 'ہٹاتا ہے';

  @override
  String scheduleTriggerOnce(String time) {
    return 'ایک بار، $time';
  }

  @override
  String scheduleTriggerEvery(String interval) {
    return 'ہر $interval';
  }

  @override
  String scheduleTriggerCron(String cron, String zone) {
    return 'شیڈول $cron پر ($zone)';
  }

  @override
  String get scheduleTriggerSelfPaced => 'جب ایجنٹ چنے، 1 سے 60 منٹ کے وقفے سے';

  @override
  String get scheduleTriggerPrChecks => 'جب pull request کی چیکس ختم ہوں';

  @override
  String scheduleTriggerPrChecksOf(String pr) {
    return 'جب $pr کی چیکس ختم ہوں';
  }

  @override
  String get scheduleTriggerPrReview => 'جب pull request پر ریویو یا جواب آئے';

  @override
  String scheduleTriggerPrReviewOf(String pr) {
    return 'جب $pr پر ریویو یا جواب آئے';
  }

  @override
  String get scheduleTriggerPrMerged => 'جب pull request مرج ہو';

  @override
  String scheduleTriggerPrMergedOf(String pr) {
    return 'جب $pr مرج ہو';
  }

  @override
  String get scheduleTriggerEnvironment =>
      'جب ماحول کا کوئی کام ختم ہو یا تیار ہو جائے';

  @override
  String scheduleTriggerTicket(String id) {
    return 'جب ٹکٹ $id طے ہو جائے';
  }

  @override
  String scheduleTriggerPipelineRun(String id) {
    return 'جب پائپ لائن رن $id ختم ہو';
  }

  @override
  String get goalNextWaiting =>
      'جب جس چیز کا یہ انتظار کر رہا ہے وہ آ جائے گی، یہ جاری ہو جائے گا۔';

  @override
  String get goalNextVerifying =>
      'جب جانچیں اور ریویو ختم ہوں گے، یہ مکمل ہو جائے گا یا کام جاری رکھے گا۔';

  @override
  String get goalNextLimit =>
      'استعمال کی حد ری سیٹ ہونے پر یہ جاری ہو جائے گا۔';

  @override
  String get goalNextPerson =>
      'کسی شخص کے سوال یا منظوری کی درخواست کا جواب دینے کے بعد یہ جاری ہوگا۔';

  @override
  String get goalNextByPerson => 'کوئی اسے جاری کرنے تک یہ توقف پر رہے گا۔';

  @override
  String get goalNextNeedsReview =>
      'اسے مکمل کے طور پر منظور کریں، یا کام جاری رکھنے کے لیے جاری کریں۔';

  @override
  String get goalNextWorking =>
      'یہ ایک وقت میں ایک حصہ کام کرتا رہے گا، جب تک مکمل نہ ہو یا حد تک نہ پہنچ جائے۔';

  @override
  String get goalContractAddCheck => 'جانچ شامل کریں';

  @override
  String goalContractChecksFull(int max) {
    return 'ایک ہدف میں زیادہ سے زیادہ $max چیکس ہو سکتے ہیں۔';
  }

  @override
  String goalContractChecksCount(int count, int max) {
    return '$max میں سے $count چیکس';
  }

  @override
  String get goalContractCheckTaskHint => 'ماحول کے کام کا نام، جیسے test';

  @override
  String get goalContractCheckCommandHint => 'کمانڈ، جیسے make test';

  @override
  String get goalContractCheckWhere => 'کہاں چلتا ہے';

  @override
  String get goalContractCheckInWorktree => 'worktree میں';

  @override
  String get goalContractCheckInEnvironment => 'ماحول کا کام';

  @override
  String get goalContractSecondsSuffix => 'سیکنڈ';

  @override
  String goalContractTimeoutRange(int max) {
    return '1 سے $max سیکنڈ';
  }

  @override
  String get goalContractRemoveCheck => 'جانچ ہٹائیں';

  @override
  String get goalContractDoneMeans => 'مکمل ہونے کا مطلب';

  @override
  String get goalContractDoneMeansHelp =>
      'ہر معیار ایک ایسی بات ہے جس کی ریویور تصدیق کر سکے۔';

  @override
  String get goalContractCriterionHint =>
      'ریلیز نوٹس میں ہر مرج شدہ تبدیلی درج ہو';

  @override
  String goalContractCriterionTooLong(int max) {
    return 'زیادہ سے زیادہ $max حروف۔';
  }

  @override
  String get goalContractRemoveCriterion => 'معیار ہٹائیں';

  @override
  String get goalContractAddCriterion => 'معیار شامل کریں';

  @override
  String goalContractCriteriaFull(int max) {
    return 'ایک ہدف میں زیادہ سے زیادہ $max معیار ہو سکتے ہیں۔';
  }

  @override
  String goalContractCriteriaCount(int count, int max) {
    return '$max میں سے $count معیار';
  }

  @override
  String get goalContractChecks => 'چیکس';

  @override
  String get goalContractChecksHelp =>
      'سرور یہ اس وقت چلاتا ہے جب ایجنٹ کہے کہ کام مکمل ہو گیا۔ جس ہدف میں جانچ نہ ہو، وہ صرف ریویو پر منحصر ہوتا ہے۔';

  @override
  String get goalContractBoundaries => 'حدود';

  @override
  String get goalContractBoundariesHint => 'عوامی API نہ بدلیں';

  @override
  String get goalContractStopWhen => 'کب رک کر پوچھنا ہے';

  @override
  String get goalContractStopWhenHint => 'مائیگریشن سے ڈیٹا ضائع ہو جائے گا';

  @override
  String get goalContractEditTitle => 'طے کریں کہ مکمل ہونے کا مطلب کیا ہے';

  @override
  String get goalCheckerTitle => 'یہ ہدف کون جانچے گا';

  @override
  String get goalCheckerLabel => 'چیکر';

  @override
  String get goalCheckerNone => 'کوئی علیحدہ چیکر نہیں';

  @override
  String get goalCheckerNoneWeaker =>
      'علیحدہ چیکر کے بغیر ایجنٹ اپنا ہی کام ریویو کرتا ہے، جس سے کم چیزیں پکڑی جاتی ہیں۔';

  @override
  String goalCheckerRecommend(String agent) {
    return 'مثال کے طور پر $agent: مختلف فراہم کنندہ کا چیکر وہی خامیاں شیئر کرنے کا امکان کم رکھتا ہے۔';
  }

  @override
  String get goalCheckerRecommendGeneric =>
      'ہدف کے ایجنٹ سے مختلف فراہم کنندہ کا چیکر وہی خامیاں شیئر کرنے کا امکان کم رکھتا ہے۔';

  @override
  String raiseCapSpentOf(String spent, String cap) {
    return '$spent از $cap خرچ ہو چکا ہے۔';
  }

  @override
  String get raiseCapNewCap => 'ڈالر میں نئی حد';

  @override
  String raiseCapMustExceed(String cap) {
    return '$cap سے زیادہ رقم درج کریں۔';
  }

  @override
  String get raiseCapConfirm => 'حد بڑھائیں';

  @override
  String get goalsBackToList => 'تمام اہداف';

  @override
  String goalPursuedBy(String agent) {
    return '$agent کی طرف سے';
  }

  @override
  String get goalOpenConversation => 'گفتگو کھولیں';

  @override
  String goalStarted(String time) {
    return '$time پر شروع ہوا';
  }

  @override
  String get goalStopTitle => 'کیا یہ ہدف روکنا ہے؟';

  @override
  String get goalStopBody =>
      'ایجنٹ اس پر کام ہمیشہ کے لیے بند کر دیتا ہے۔ اب تک کا کام گفتگو میں رہتا ہے۔';

  @override
  String get goalRaiseBudgetTitle => 'بجٹ بڑھائیں اور جاری رکھیں';

  @override
  String get goalRaiseBudgetAction => 'بجٹ بڑھائیں';

  @override
  String get goalSectionNow => 'ابھی';

  @override
  String get goalFactSegments => 'حصے';

  @override
  String get goalFactMoney => 'خرچ';

  @override
  String get goalFactDeadline => 'آخری وقت';

  @override
  String get goalFactNoProgress => 'کوئی پیش رفت نہیں';

  @override
  String get goalNoDeadline => 'کوئی نہیں';

  @override
  String goalDeadlineWithLeft(String time, String left) {
    return '$time، $left باقی';
  }

  @override
  String goalNoProgressCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'آخری $count حصوں میں کوئی پیش رفت نہیں ہوئی',
      one: 'آخری حصے میں کوئی پیش رفت نہیں ہوئی',
    );
    return '$_temp0';
  }

  @override
  String get goalObjective => 'مقصد';

  @override
  String get goalSectionContract => 'مکمل ہونے کا مطلب';

  @override
  String get goalContractPauseFirst =>
      'مکمل ہونے کا مطلب یا جانچنے والا بدلنے کے لیے ہدف کو توقف پر رکھیں۔';

  @override
  String get goalContractEdit => 'ترمیم';

  @override
  String get goalCheckerChange => 'چیکر بدلیں';

  @override
  String get goalContractNone =>
      'ابھی کچھ لکھا نہیں گیا۔ ایجنٹ طے کرتا ہے کہ کام مکمل ہوا۔';

  @override
  String get goalCheckerSelf =>
      'کوئی علیحدہ چیکر نہیں: ایجنٹ اپنا کام خود جانچتا ہے۔';

  @override
  String goalCheckerIs(String agent) {
    return 'جانچ $agent کرتا ہے';
  }

  @override
  String goalCheckWorktree(int seconds) {
    return 'worktree میں، زیادہ سے زیادہ $seconds سیکنڈ';
  }

  @override
  String goalCheckEnvironmentTask(int seconds) {
    return 'ماحول کا کام، زیادہ سے زیادہ $seconds سیکنڈ';
  }

  @override
  String get goalSectionVerification => 'تصدیق';

  @override
  String get goalNotVerifiedYet =>
      'ابھی تصدیق نہیں ہوئی۔ ایجنٹ نے ابھی تک نہیں کہا کہ کام مکمل ہے۔';

  @override
  String goalVerificationRound(int round, int total, String time) {
    return 'راؤنڈ $round از $total، $time';
  }

  @override
  String get goalVerificationClaim => 'ایجنٹ کا دعویٰ';

  @override
  String get goalCheckOutputTail => 'آؤٹ پٹ (آخری سطریں)';

  @override
  String goalCheckExitCode(int code) {
    return 'پاس · ایگزٹ کوڈ $code';
  }

  @override
  String get goalVerificationReview => 'ریویو';

  @override
  String get goalVerificationNoVerdict => 'ابھی ریویو نہیں ہوا۔';

  @override
  String goalVerdictItem(String criterion, String state) {
    return '$criterion · $state';
  }

  @override
  String get goalSectionSchedules => 'شیڈولز اور بیداریاں';

  @override
  String get goalNoSchedules => 'کوئی شیڈول یا انتظار میں بیداری نہیں۔';

  @override
  String get goalPendingWakes => 'انتظار میں بیداریاں';

  @override
  String workListGroup(String label, int count) {
    return '$label · $count';
  }

  @override
  String get goalNotFound =>
      'یہ ہدف موجود نہیں، یا یہ کسی ایسے اسپیس میں ہے جسے آپ کھول نہیں سکتے۔';

  @override
  String get goalsTitle => 'اہداف';

  @override
  String get goalsSubtitle =>
      'وہ کام جس پر ایجنٹ تب تک لگا رہتا ہے جب تک مکمل ہونے کا مطلب پورا نہ ہو۔';

  @override
  String get goalsEmpty => 'ابھی کوئی ہدف نہیں';

  @override
  String get goalsEmptyHint => 'کسی گفتگو میں /goal سے ایک شروع کریں۔';

  @override
  String get goalsGroupReview => 'ریویو کا انتظار';

  @override
  String get goalsGroupOpen => 'کھلے';

  @override
  String get goalsGroupEnded => 'ختم شدہ';

  @override
  String get scheduleStatusActive => 'فعال';

  @override
  String get scheduleStatusPaused => 'توقف';

  @override
  String get scheduleStatusEnded => 'ختم';

  @override
  String get scheduleWhenBusySkip => 'ایجنٹ مصروف ہو تو یہ چلنا چھوڑ دیتا ہے';

  @override
  String get scheduleWhenBusyQueue => 'ایجنٹ فارغ ہونے تک انتظار کرتا ہے';

  @override
  String get scheduleDeliverRun => 'ایک رن شروع کرتا ہے';

  @override
  String get scheduleDeliverNotify => 'صرف اطلاع دیتا ہے';

  @override
  String get scheduleNew => 'نیا شیڈول';

  @override
  String get schedulesEmpty => 'کوئی شیڈول یا واچ نہیں';

  @override
  String get schedulesEmptyHint =>
      'ایجنٹ انہیں /loop اور /schedule سے مقرر کرتے ہیں، یا آپ ایک بنا سکتے ہیں۔';

  @override
  String scheduleOwnedBy(String name) {
    return 'مالک: $name';
  }

  @override
  String scheduleRunsSkips(int runs, int skips) {
    String _temp0 = intl.Intl.pluralLogic(
      runs,
      locale: localeName,
      other: '$runs رن',
      one: '1 رن',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skips,
      locale: localeName,
      other: '$skips چھوڑے گئے',
      one: '1 چھوڑا گیا',
      zero: 'کوئی چھوڑا نہیں',
    );
    return '$_temp0، $_temp1';
  }

  @override
  String scheduleExpires(String time) {
    return '$time پر ختم';
  }

  @override
  String scheduleNextFires(String times) {
    return 'اگلا: $times';
  }

  @override
  String get schedulesTitle => 'شیڈولز';

  @override
  String get schedulesSubtitle =>
      'شیڈولز، لوپس اور واچز جو ایجنٹس کو جگاتے ہیں۔';

  @override
  String get scheduleWhenLabel => 'کب چلے';

  @override
  String get scheduleWhenEvery => 'بار بار، ہر…';

  @override
  String get scheduleWhenCron => 'cron شیڈول پر';

  @override
  String get scheduleWhenOnceIn => 'ایک بار، ایک وقفے کے بعد…';

  @override
  String get scheduleWhenOnceAt => 'ایک بار، اگلے…';

  @override
  String get scheduleDurationLabel => 'وقفہ';

  @override
  String get scheduleDurationHelp =>
      's، m، h یا d استعمال کریں، جیسے 30m یا 1h30m۔ دہرانے والے وقفے کم از کم 60 سیکنڈ کے فاصلے پر ہوں گے۔';

  @override
  String get scheduleDurationInvalid => 'یہ دورانیہ نہیں ہے، جیسے 30m یا 2h۔';

  @override
  String get scheduleHour => 'گھنٹہ';

  @override
  String get scheduleMinute => 'منٹ';

  @override
  String get scheduleCronLabel => 'Cron (منٹ گھنٹہ دن مہینہ ہفتے کا دن)';

  @override
  String get scheduleCronInvalid => 'یہ پانچ فیلڈز والا cron نہیں جو چل سکے۔';

  @override
  String get scheduleTimeInvalid =>
      'یہ آنے والا وقت نہیں ہے، جیسے 09:00 یا 2026-11-21T09:00Z۔';

  @override
  String scheduleDaysRange(int max) {
    return '1 سے $max دن۔';
  }

  @override
  String scheduleOptionUnknown(String option) {
    return '$option ایک آپشن نہیں ہے۔';
  }

  @override
  String get scheduleLimits => 'حدیں';

  @override
  String get schedulePresetWeekdays => 'ہفتے کے کام کے دنوں میں 09:00 بجے';

  @override
  String get schedulePresetDaily => 'ہر روز 09:00 بجے';

  @override
  String get schedulePresetHourly => 'ہر گھنٹے، ٹھیک گھنٹے پر';

  @override
  String get scheduleZoneLabel => 'ٹائم زون';

  @override
  String get scheduleZoneHelp => 'خالی ہو تو ورک اسپیس کا زون۔';

  @override
  String get scheduleZoneInvalid => 'یہ ٹائم زون نہیں ہے، جیسے Europe/Berlin۔';

  @override
  String get scheduleCreateTitle => 'نیا شیڈول';

  @override
  String get scheduleSpaceLabel => 'اسپیس';

  @override
  String get scheduleSpaceHint => 'ایک اسپیس منتخب کریں';

  @override
  String get scheduleConversationLabel => 'گفتگو';

  @override
  String get scheduleConversationHint => 'ایک گفتگو منتخب کریں';

  @override
  String get scheduleAgentLabel => 'ایجنٹ';

  @override
  String get scheduleAgentHint => 'منتخب کریں کون جاگے';

  @override
  String get scheduleNoteLabel => 'ہر رن کس بات سے شروع ہو';

  @override
  String get scheduleNoteHint =>
      'بتائیں رات بھر کیا بدلا اور جو رکا ہوا ہو اسے نشان زد کریں۔';

  @override
  String get scheduleExpiresInDays => 'کتنے دنوں بعد ختم (دن)';

  @override
  String get scheduleExpiresInDaysHelp => 'خالی: 30 دن، زیادہ سے زیادہ 365۔';

  @override
  String get scheduleMaxRuns => 'رنز کی حد';

  @override
  String scheduleMaxRunsHelp(int max) {
    return 'خالی: کوئی حد نہیں، زیادہ سے زیادہ $max۔';
  }

  @override
  String get scheduleCostCap => 'لاگت کی حد (ڈالر)';

  @override
  String get scheduleCostCapHelp => 'خالی: ورک اسپیس کا ڈیفالٹ۔';

  @override
  String get scheduleWhenBusyLabel => 'اگر ایجنٹ مصروف ہو';

  @override
  String get scheduleWhenBusyDefault => 'اس قسم کے لیے ڈیفالٹ';

  @override
  String get scheduleDeliverLabel => 'ہر بار کیا ہو';

  @override
  String get scheduleCreate => 'شیڈول بنائیں';

  @override
  String get scheduleExtendTitle => 'اس شیڈول کی مدت بڑھائیں';

  @override
  String scheduleExtendNow(String current, String latest) {
    return 'یہ $current پر ختم ہوتا ہے۔ زیادہ سے زیادہ $latest تک چل سکتا ہے۔';
  }

  @override
  String get scheduleExtendDays => 'دن شامل کریں';

  @override
  String scheduleExtendTooLong(String latest) {
    return 'زیادہ سے زیادہ $latest تک ختم ہو سکتا ہے۔';
  }

  @override
  String scheduleMaxRunsRange(int max) {
    return '1 سے $max رنز۔';
  }

  @override
  String scheduleCostCapRange(String max) {
    return 'کم از کم 1 ڈالر اور زیادہ سے زیادہ $max۔';
  }

  @override
  String get scheduleExtend => 'مدت بڑھائیں';

  @override
  String get scheduleRemoveTitle => 'کیا یہ شیڈول ہٹانا ہے؟';

  @override
  String get scheduleDeleteTitle => 'کیا یہ شیڈول حذف کرنا ہے؟';

  @override
  String get scheduleRemoveBody =>
      'یہ فہرست سے ہٹ جائے گا۔ اس کے رنز گفتگو میں رہیں گے۔';

  @override
  String get scheduleDeleteBody =>
      'یہ ہمیشہ کے لیے چلنا بند کر دے گا۔ اس کے رنز گفتگو میں رہیں گے۔';

  @override
  String get scheduleRemove => 'ہٹائیں';

  @override
  String get scheduleDelete => 'حذف کریں';

  @override
  String get scheduleOwnerOnly => 'صرف اس کا مالک اسے جاری یا بڑھا سکتا ہے۔';

  @override
  String get schedulesBackToList => 'تمام شیڈولز';

  @override
  String get scheduleNoteByAgent => 'نوٹ، ایجنٹ کا لکھا ہوا';

  @override
  String get scheduleNoteByPerson => 'نوٹ، ایک شخص کا لکھا ہوا';

  @override
  String scheduleNoteEditedBy(String name) {
    return 'نوٹ، آخری بار $name نے ترمیم کیا';
  }

  @override
  String get scheduleNoNote => 'کوئی نوٹ نہیں۔';

  @override
  String get schedulePause => 'توقف کریں';

  @override
  String get scheduleResume => 'جاری رکھیں';

  @override
  String get scheduleOpenChainRoot => 'اس سلسلے کا پہلا شیڈول کھولیں';

  @override
  String get scheduleSectionFacts => 'تفصیلات';

  @override
  String get scheduleFactAgent => 'جگاتا ہے';

  @override
  String get scheduleFactConversation => 'میں';

  @override
  String get scheduleConversationUnknown => 'ایک گفتگو جو آپ نہیں دیکھ سکتے';

  @override
  String get scheduleFactOwner => 'مالک';

  @override
  String get scheduleNoOwner => 'کوئی نہیں';

  @override
  String get scheduleFactNextFires => 'اگلے رن';

  @override
  String get scheduleFactNext => 'اگلا رن';

  @override
  String get scheduleFactLast => 'آخری بار چلا';

  @override
  String get scheduleFactRuns => 'رنز';

  @override
  String scheduleRunsNoCap(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رنز، کوئی حد نہیں',
      one: '1 رن، کوئی حد نہیں',
    );
    return '$_temp0';
  }

  @override
  String scheduleRunsOfCap(int count, int max) {
    return '$max میں سے $count رنز';
  }

  @override
  String get scheduleFactSkips => 'چھوڑے گئے';

  @override
  String scheduleSkips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بار چلنا چھوڑا',
      one: '1 بار چلنا چھوڑا',
      zero: 'کوئی نہیں',
    );
    return '$_temp0';
  }

  @override
  String get scheduleFactSpent => 'خرچ';

  @override
  String get scheduleFactEnds => 'ختم';

  @override
  String get scheduleFactWhenBusy => 'اگر ایجنٹ مصروف ہو';

  @override
  String get scheduleFactDeliver => 'ہر بار';

  @override
  String get scheduleFactChain => 'سلسلہ';

  @override
  String scheduleChainLeft(int runs, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      runs,
      locale: localeName,
      other: '$runs رنز باقی',
      one: '1 رن باقی',
    );
    return 'سلسلے میں $_temp0، جو $time پر ختم ہوگا';
  }

  @override
  String get scheduleFactCreated => 'بنایا گیا';

  @override
  String get scheduleSectionHistory => 'حالیہ بیداریاں اور رنز';

  @override
  String get scheduleNoRuns => 'ابھی کوئی رن نہیں۔';

  @override
  String scheduleRunLine(String status, String cost) {
    return '$status · $cost';
  }

  @override
  String get scheduleRunPending => 'شروع ہونے کا انتظار';

  @override
  String get scheduleRunRunning => 'چل رہا ہے';

  @override
  String get scheduleRunCompleted => 'مکمل ہوا';

  @override
  String get scheduleRunFailed => 'ناکام';

  @override
  String get scheduleNotFound =>
      'یہ شیڈول موجود نہیں، یا یہ کسی ایسے اسپیس میں ہے جسے آپ کھول نہیں سکتے۔';

  @override
  String get improvementCampaignTitle => 'جانچ چلائیں';

  @override
  String improvementCampaignCost(int repetitions, String budget) {
    String _temp0 = intl.Intl.pluralLogic(
      repetitions,
      locale: localeName,
      other: 'ہر کام $repetitions بار چلتا ہے',
      one: 'ہر کام ایک بار چلتا ہے',
    );
    return '$_temp0 موجودہ مہارت اور تبدیلی دونوں کے ساتھ۔ یہ زیادہ سے زیادہ $budget خرچ کرے گا، جو اس ورک اسپیس پر لگے گا۔';
  }

  @override
  String get improvementCampaignCostUnknown =>
      'یہ جانچ موجودہ مہارت اور تبدیلی دونوں کے ساتھ کارپس چلاتی ہے، اس بجٹ تک جو آپ مقرر کریں۔';

  @override
  String get improvementCampaignUnavailable =>
      'اس وقت اس سرور پر جانچیں نہیں چل سکتیں۔';

  @override
  String get improvementCampaignCorpus => 'کارپس';

  @override
  String get improvementCampaignProvider => 'فراہم کنندہ';

  @override
  String get improvementCampaignModel => 'ماڈل';

  @override
  String get improvementCampaignRepetitions => 'ہر کام کے رنز';

  @override
  String get improvementCampaignBudget => 'بجٹ (ڈالر)';

  @override
  String improvementCampaignRange(int max) {
    return '1 سے $max۔';
  }

  @override
  String get improvementCampaignStart => 'جانچ شروع کریں';

  @override
  String get improvementRollbackTitle => 'کیا یہ تبدیلی واپس لینی ہے؟';

  @override
  String get improvementRollbackBody =>
      'جو متن یہ بدلتی تھی وہ واپس آ جائے گا، بشرطیکہ اس کے بعد کسی نے اسے نہ بدلا ہو۔';

  @override
  String get improvementRollback => 'واپس لیں';

  @override
  String get improvementRolledBackDone => 'واپس لے لیا گیا۔';

  @override
  String get improvementNeedsAdmin =>
      'اس پر صرف ورک اسپیس ایڈمن فیصلہ کر سکتا ہے: یہ پورے ورک اسپیس کے لیے کوئی مہارت یا پالیسی بدلتا ہے۔';

  @override
  String get improvementAdminDecides =>
      'ایڈمن کے طور پر، اس پر فیصلہ آپ کا ہے: یہ پورے ورک اسپیس کے لیے کوئی مہارت یا پالیسی بدلتا ہے۔';

  @override
  String get improvementNeedsCampaign =>
      'اس مہارت کی تبدیلی قبول کرنے سے پہلے کامیاب جانچ چلائیں۔';

  @override
  String get improvementsBackToList => 'تمام بہتریاں';

  @override
  String improvementMeta(String kind, String scope, String agent) {
    return '$kind · $scope · $agent نے تجویز کیا';
  }

  @override
  String get improvementAccept => 'قبول کریں';

  @override
  String get improvementAcceptedDone => 'قبول کر لیا گیا۔';

  @override
  String get improvementReject => 'مسترد کریں';

  @override
  String get improvementRejectedDone => 'مسترد کر دیا گیا۔';

  @override
  String get improvementRunEvaluation => 'جانچ چلائیں';

  @override
  String get improvementSectionChange => 'کیا بدلتا ہے';

  @override
  String get improvementTarget => 'ہدف';

  @override
  String improvementScopeLine(String scope) {
    return 'لاگو ہوتا ہے: $scope';
  }

  @override
  String get improvementNewText => 'نیا متن';

  @override
  String get improvementRemovedText => 'ہٹایا گیا متن';

  @override
  String get improvementExpected => 'متوقع اثر';

  @override
  String get improvementSectionEvidence => 'ثبوت اور فیصلہ';

  @override
  String get improvementNoEvidence => 'کوئی ثبوت منسلک نہیں۔';

  @override
  String get improvementEvidenceRuns => 'رنز';

  @override
  String get improvementEvidenceMessages => 'پیغامات';

  @override
  String improvementOpenMessage(int index) {
    return 'پیغام $index';
  }

  @override
  String get improvementEvidenceChecks => 'چیکس کے نتائج';

  @override
  String get improvementEvaluation => 'جانچ';

  @override
  String get improvementCampaignNone => 'ابھی تک جانچ نہیں ہوئی۔';

  @override
  String get improvementCampaignRunning => 'جانچ چل رہی ہے۔';

  @override
  String get improvementCampaignPassed =>
      'جانچ پاس ہوئی: یہ پوری چلی، اور تبدیلی نے موجودہ مہارت جتنے رنز حل کیے یا اس سے زیادہ، جو یہ ثابت نہیں کرتا کہ یہ بہتر ہے۔ اسے قبول کیا جا سکتا ہے۔';

  @override
  String get improvementCampaignFailed =>
      'جانچ پاس نہیں ہوئی، یا جانچ کے بعد مہارت بدل گئی۔ اسے دوبارہ چلائیں، یا تبدیلی مسترد کریں۔';

  @override
  String improvementDecided(String status, String name, String time) {
    return '$status از $name، $time';
  }

  @override
  String get improvementSomeone => 'کوئی';

  @override
  String improvementExpires(String time) {
    return 'اگر کوئی فیصلہ نہ کرے تو $time پر ختم۔';
  }

  @override
  String get improvementOpenApplied => 'جو بدلا گیا وہ کھولیں';

  @override
  String get improvementsTitle => 'بہتریاں';

  @override
  String get improvementsSubtitle =>
      'ایجنٹس کی طرف سے ان کی میموری، نوٹس، پالیسیوں اور مہارتوں میں تجویز کردہ تبدیلیاں۔';

  @override
  String get improvementsEmpty => 'کوئی تجویز نہیں';

  @override
  String get improvementsEmptyHint =>
      'ایجنٹ اپنا کام ریویو کرنے کے بعد بہتری تجویز کرتے ہیں، مثلاً /refine سے۔';

  @override
  String get improvementRowNeedsAdmin => 'فیصلہ ایک ایڈمن کرتا ہے';

  @override
  String get improvementNotFound =>
      'یہ تجویز موجود نہیں، یا یہ کسی ایسے اسپیس میں ہے جسے آپ کھول نہیں سکتے۔';

  @override
  String get dispatchSettingsTitle => 'شیڈولز';

  @override
  String get dispatchSettingsSubtitle =>
      'شیڈولز اور واچز کی حدیں، اور ان درخواستوں کا کیا ہوگا جن کا کوئی جواب نہ دے۔';

  @override
  String get dispatchLimitsLabel => 'شیڈول کی حدیں';

  @override
  String get dispatchLimitsSubtitle =>
      'ایجنٹ کتنے شیڈول اور واچز رکھ سکتے ہیں، اور ان کے ڈیفالٹ۔';

  @override
  String dispatchLimitRange(int max) {
    return '1 سے $max';
  }

  @override
  String get dispatchLimitPerConversation => 'گفتگو میں فی ایجنٹ';

  @override
  String get dispatchLimitPerConversationHelp =>
      'ایک گفتگو میں ایک ایجنٹ جتنے فعال یا توقف والے شیڈول رکھ سکتا ہے۔';

  @override
  String get dispatchLimitPerAgent => 'فی ایجنٹ';

  @override
  String get dispatchLimitPerAgentHelp =>
      'پورے ورک اسپیس میں ایک ایجنٹ جتنے فعال یا توقف والے شیڈول رکھ سکتا ہے۔';

  @override
  String get dispatchLimitPerWorkspace => 'ورک اسپیس میں';

  @override
  String get dispatchLimitPerWorkspaceHelp =>
      'پورے ورک اسپیس میں فعال یا توقف والے شیڈول۔';

  @override
  String get dispatchLimitCostCap => 'ڈیفالٹ لاگت کی حد (ڈالر)';

  @override
  String get dispatchLimitCostCapHelp =>
      'جب شیڈول اپنی کوئی حد نہ رکھے تو وہ مجموعی طور پر کتنا خرچ کر سکتا ہے۔';

  @override
  String get dispatchLimitZone => 'ٹائم زون';

  @override
  String get dispatchLimitZoneHelp =>
      'وہ زون جس میں cron شیڈول پڑھے جاتے ہیں جب وہ کوئی نام نہ دیں، اور روزانہ خلاصے کا زون۔';

  @override
  String get dispatchUnattendedLabel => 'جب کوئی جواب نہ دے';

  @override
  String get dispatchUnattendedSubtitle =>
      'سرور کا شروع کیا ہوا رن کسی شخص کا کتنی دیر انتظار کرتا ہے، اور انتظار کرنے والی چیزوں کا روزانہ خلاصہ کب جائے گا۔';

  @override
  String get dispatchUnattendedExpiry => 'درخواستیں انتظار کریں (گھنٹے)';

  @override
  String get dispatchUnattendedExpiryHelp =>
      'اس کے بعد کوئی منظوری مسترد سمجھی جائے گی، اور کوئی سوال بے جواب۔ جو ہدف جواب فرض کرنے پر سیٹ ہیں وہ 10 منٹ بعد اپنے سوالوں کے جواب خود دیں گے۔';

  @override
  String dispatchUnattendedExpiryRange(int min, int max) {
    return '$min سے $max گھنٹے';
  }

  @override
  String get dispatchDigestHour => 'روزانہ خلاصہ کس وقت (گھنٹہ)';

  @override
  String dispatchDigestHourHelp(String zone) {
    return '$zone میں، جو اوپر کا ٹائم زون ہے۔';
  }

  @override
  String get dispatchDigestHourRange => '0 سے 23';

  @override
  String get goalRecordCrumb => 'ہدف';

  @override
  String get scheduleRecordCrumb => 'شیڈول';

  @override
  String get improvementRecordCrumb => 'تجویز';

  @override
  String get goalNodeNeedsAgent => 'وہ ایجنٹ چنیں جو ہدف پر کام کرے۔';

  @override
  String get goalNodeNeedsObjective => 'مقصد لکھیں۔';

  @override
  String get goalNodeContractInvalid =>
      'معاہدے کا ایک فیلڈ اپنی حد سے بڑا ہے؛ درست ہونے تک یہ محفوظ نہیں ہوگا۔';

  @override
  String get goalNodeBudget => 'بجٹ (ڈالر)';

  @override
  String get goalNodeBudgetHelp =>
      'ہدف زیادہ سے زیادہ جتنا خرچ کر سکتا ہے۔ جب یہ ختم ہو جائے تو ہدف ایک شخص کے لیے روک دیا جاتا ہے۔';

  @override
  String goalNodeBudgetRange(int max) {
    return 'ضروری: 0 سے زیادہ، زیادہ سے زیادہ $max تک۔';
  }

  @override
  String get goalNodeMaxRuns => 'حصوں کی حد';

  @override
  String get goalNodeMaxRunsHelp =>
      'اختیاری۔ ہدف زیادہ سے زیادہ کتنے حصے (ایجنٹ رنز) لے سکتا ہے۔';

  @override
  String get goalNodeDeadline => 'آخری وقت (گھنٹے)';

  @override
  String get goalNodeDeadlineHelp =>
      'اختیاری۔ جس لمحے مرحلہ ہدف شروع کرے، وہاں سے گھنٹے۔';

  @override
  String goalNodeRange(int max) {
    return '1 سے $max تک، یا خالی۔';
  }

  @override
  String get goalNodeContract => 'معاہدہ';

  @override
  String get goalNodeContractHelp =>
      'مکمل ہونے کا مطلب: وہ معیار جن کی ریویور جانچ کرتا ہے، اور وہ کمانڈز جو پاس ہونی چاہئیں۔';

  @override
  String get nodeConfigObjective => 'مقصد';

  @override
  String pipelineRunGoalStep(String step) {
    return 'مرحلہ $step ایک ہدف پر کام کر رہا ہے';
  }

  @override
  String get pipelineRunOpenGoal => 'ہدف کھولیں';

  @override
  String get pipelineRunHeldBudget =>
      'یہ رن روکا ہوا ہے: اس کی آرکیسٹریشن اپنی لاگت کی حد تک پہنچ گئی۔';

  @override
  String pipelineRunHeldOther(String reason) {
    return 'یہ رن روکا ہوا ہے ($reason)۔';
  }

  @override
  String pipelineRunHeldSpent(String spent, String cap) {
    return '$cap میں سے $spent خرچ ہوئے۔ حد بڑھائیں تو رن جاری رہے گا۔';
  }

  @override
  String get pipelineRunRaiseCap => 'حد بڑھائیں';

  @override
  String get pipelineRunRaiseCapTitle => 'آرکیسٹریشن کی حد بڑھائیں';

  @override
  String get pipelineRunCapRaised => 'حد بڑھا دی گئی۔ رن جلد ہی جاری ہوگا۔';

  @override
  String get goalLaunchChecks => 'چیکس';

  @override
  String get goalLaunchChecksHelp =>
      'وہ کمانڈز جو ہدف ختم ہونے سے پہلے پاس ہونی چاہئیں۔ اختیاری۔';

  @override
  String get goalLaunchFresh => 'ہر حصہ نئے سرے سے شروع کریں';

  @override
  String get goalLaunchFreshHelp =>
      'ہر رن گفتگو کی ہسٹری کے بغیر شروع ہوتا ہے، صرف ہدف اور اس کے نوٹس سے۔';

  @override
  String get goalLaunchAssume =>
      'کوئی جواب نہ دے تو اپنے سوالوں کے جواب خود دیں';

  @override
  String get goalLaunchAssumeHelp =>
      '10 منٹ تک جواب نہ آنے پر، اگر رکنے کی شرائط اجازت دیں تو ایجنٹ اپنا مفروضہ بیان کرکے آگے بڑھتا ہے۔';

  @override
  String workFeedLimitParkOutcomeResumed(String provider, String time) {
    return '$provider کی استعمال کی حد کے بعد $time پر جاری ہوا۔';
  }

  @override
  String workFeedLimitParkOutcomeCancelled(String provider, String time) {
    return '$time پر منسوخ۔ $provider کی استعمال کی حد کے بعد یہ جاری نہیں ہوا۔';
  }

  @override
  String workFeedLimitParkOutcomeExpired(String provider, String time) {
    return '$time پر ختم، $provider کی استعمال کی حد کے بعد جاری ہوئے بغیر۔';
  }

  @override
  String workFeedLimitParkOutcomeSkipped(String provider, String time) {
    return '$provider کی استعمال کی حد کے بعد جاری نہیں ہوا ($time)۔';
  }

  @override
  String workFeedCommandRefusedNamed(String command) {
    return '/$command کمانڈ مسترد ہو گئی۔';
  }

  @override
  String get improvementRefusalQueued =>
      'اس گفتگو کا ایک ریویو پہلے ہی چلنے کے انتظار میں ہے۔';

  @override
  String get improvementRefusalAgentNotFound =>
      'یہ ایجنٹ اس ورک اسپیس کا ایجنٹ نہیں ہے۔';

  @override
  String get workRefusalWakeQueueFull =>
      'یہاں پہلے ہی بہت زیادہ بیداریاں انتظار میں ہیں۔ کچھ چل جانے کے بعد دوبارہ کوشش کریں۔';

  @override
  String get orchestrationRefusalNotYours =>
      'صرف وہ شخص بدل سکتا ہے جس کے لیے یہ رن کام کرتا ہے۔';

  @override
  String get orchestrationRefusalCapInvalid =>
      'نئی حد موجودہ حد اور خرچ شدہ رقم سے زیادہ ہونی چاہیے، اور زیادہ سے زیادہ \$1,000۔';

  @override
  String get orchestrationRefusalCapChanged =>
      'کسی نے پہلے حد بڑھا دی ہے۔ نئی حد دیکھیں اور دوبارہ کوشش کریں۔';

  @override
  String workFeedCapRaised(String person, String oldCap, String newCap) {
    return '$person نے رن کی حد $oldCap سے بڑھا کر $newCap کر دی۔';
  }

  @override
  String get workFeedPersonUnknown => 'ایک شخص';

  @override
  String workFeedApplyIncomplete(String skill) {
    return 'مہارت $skill میں قبول کردہ تبدیلی مکمل نہ ہو سکی، کیونکہ اس دوران مہارت بدل گئی۔ تجویز واپس لے لی گئی۔';
  }

  @override
  String get workFeedOpenImprovement => 'بہتری کھولیں';

  @override
  String get peerAskFailNoOutput => 'یہ بغیر جواب کے ختم ہو گیا۔';

  @override
  String get peerAskFailRunFailed => 'اس کا رن ناکام ہو گیا۔';

  @override
  String get peerAskFailStoppedByPerson => 'ایک شخص نے اس کا رن روک دیا۔';

  @override
  String get peerAskFailBudget => 'اس کا رن اپنے بجٹ تک پہنچ گیا۔';

  @override
  String get peerAskFailSilence => 'اس کا رن خاموش ہو گیا اور روک دیا گیا۔';

  @override
  String get peerAskFailUsageLimit =>
      'اس کا رن فراہم کنندہ کی استعمال کی حد پر رک گیا۔';

  @override
  String get peerAskFailNotDelivered => 'سوال کبھی پہنچایا نہیں گیا۔';

  @override
  String heldSteeringLimitHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count پیغامات استعمال کی حد پر روکے گئے',
      one: '1 پیغام استعمال کی حد پر روکا گیا',
    );
    return '$_temp0';
  }

  @override
  String get heldSteeringLimitNote =>
      'یہ اس وقت بھیجے جاتے ہیں جب وہ شخص جس کے لیے رن کام کرتا ہے اسے جاری رکھے۔ اگر ری سیٹ کے 7 دن کے اندر جاری نہ کیا جائے تو یہ اس شخص کے لیے روکے رہتے ہیں۔';

  @override
  String get wakeKindRuleFolded => 'ایک بعد کے واقعے نے اس کی جگہ لے لی۔';

  @override
  String goalCardWaitingNext(String time) {
    return 'جو کام اس نے طے کیا ہے اس کا انتظار · $time تک دوبارہ دیکھے گا';
  }

  @override
  String raiseCapAtMost(String max) {
    return 'زیادہ سے زیادہ $max درج کریں۔';
  }

  @override
  String raiseCapNowAt(String cap) {
    return 'حد اب $cap ہے۔';
  }

  @override
  String get scheduleWakeReasonSchedule => 'شیڈول شدہ';

  @override
  String get scheduleWakeReasonWatch => 'نگرانی';

  @override
  String get scheduleWakeReasonLimitReset => 'استعمال کی حد ری سیٹ ہونے کے بعد';

  @override
  String get scheduleWakeStatePending => 'انتظار';

  @override
  String get scheduleWakeStateHeld => 'روکی گئی';

  @override
  String get scheduleWakeStateClaimed => 'شروع ہو رہا ہے';

  @override
  String get scheduleWakeStateDelivered => 'بھیجی گئی';

  @override
  String get scheduleWakeStateSkipped => 'چھوڑی گئی';

  @override
  String get scheduleWakeStateExpired => 'ختم';

  @override
  String get scheduleWakeStateCancelled => 'منسوخ';

  @override
  String scheduleWakeLine(String reason, String state) {
    return '$reason · $state';
  }

  @override
  String scheduleWakeExit(int code) {
    return 'ایگزٹ کوڈ $code';
  }

  @override
  String scheduleWakeEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count واقعات',
      one: '1 واقعہ',
    );
    return '$_temp0';
  }

  @override
  String get scheduleWakesNone => 'ابھی کوئی بیداری نہیں۔';

  @override
  String get scheduleWakesOlder => 'پرانی دکھائیں';

  @override
  String get improvementCandidateStaged =>
      'تجویز کردہ مہارت ایک الگ ریویژن کے طور پر محفوظ ہے۔ اس کی جانچ لائیو مہارت کو نہیں بدلتی؛ مہارت صرف تجویز قبول ہونے پر بدلتی ہے۔';

  @override
  String goalNextWaitingFallback(String time) {
    return 'جس کام کا یہ منتظر ہے وہ آئے گا تو یہ جاری ہوگا، ورنہ $time پر دوبارہ دیکھے گا۔';
  }

  @override
  String get steeringRefusalHeldByLimit =>
      'استعمال کی حد کا توقف انتظار کے دوران روکے گئے پیغامات دستی طور پر نہیں بھیجے جا سکتے۔';

  @override
  String steeringRefusalHeldByLimitAt(String time) {
    return 'استعمال کی حد کا توقف انتظار کے دوران روکے گئے پیغامات دستی طور پر نہیں بھیجے جا سکتے۔ حد $time پر ری سیٹ ہوگی۔';
  }

  @override
  String heldSteeringLimitResetsAt(String time) {
    return 'حد $time پر ری سیٹ ہوگی۔ یہ اس وقت بھیجے جاتے ہیں جب وہ شخص جس کے لیے رن کام کرتا ہے اسے جاری رکھے۔';
  }

  @override
  String heldSteeringFromPerson(String name) {
    return '$name کی طرف سے';
  }

  @override
  String get heldSteeringFromSomeoneElse => 'کسی اور کی طرف سے';

  @override
  String get heldSteeringOnlyWriterSends =>
      'روکا ہوا پیغام صرف وہی شخص بھیج سکتا ہے جس نے اسے لکھا ہو۔';

  @override
  String get steeringRefusalNotYours =>
      'یہ روکے ہوئے پیغامات کسی اور کے ہیں۔ انہیں صرف وہی شخص بھیج سکتا ہے جس نے پیغام لکھا ہو۔';

  @override
  String improvementEvaluationSolved(
    int pairedRuns,
    int candidateSolved,
    int baselineSolved,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      pairedRuns,
      locale: localeName,
      other: '$pairedRuns جوڑی والے رنز میں',
      one: '1 جوڑی والے رن میں',
    );
    return '$_temp0، تبدیلی نے $candidateSolved اور موجودہ مہارت نے $baselineSolved حل کیے۔';
  }

  @override
  String improvementEvaluationWorse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کام تبدیلی کے ساتھ خراب ہوئے۔',
      one: '1 کام تبدیلی کے ساتھ خراب ہوا۔',
    );
    return '$_temp0';
  }

  @override
  String improvementEvaluationCostlier(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کام تبدیلی کے ساتھ زیادہ مہنگے پڑے۔',
      one: '1 کام تبدیلی کے ساتھ زیادہ مہنگا پڑا۔',
    );
    return '$_temp0';
  }

  @override
  String improvementEvaluationHarnessErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رنز کو ہارنس کی خرابی آئی۔',
      one: '1 رن کو ہارنس کی خرابی آئی۔',
    );
    return '$_temp0';
  }

  @override
  String get improvementEvaluationIncomplete => 'جانچ پوری نہیں چلی۔';

  @override
  String workFeedLimitParkExpires(String time) {
    return '$time پر ختم';
  }

  @override
  String workFeedSchedulePaused(String person, String agent) {
    return '$person نے $agent کا شیڈول موقوف کیا۔';
  }

  @override
  String get goalCardApproveNotYours =>
      'صرف وہ شخص جس نے پائپ لائن رن شروع کیا تھا اس ہدف کی تکمیل منظور کر سکتا ہے۔';

  @override
  String get goalCardObjective => 'مقصد';

  @override
  String get planNeedsWrite =>
      'اس پلان کی منظوری یا تبدیلی کے لیے اس اسپیس کی ہر ریپوزٹری پر لکھنے کی رسائی درکار ہے۔ ورک اسپیس ایڈمن یہ رسائی دے سکتا ہے۔';

  @override
  String scheduleSpentWithChain(String spent, String cap) {
    return '$spent از $cap، اس کے سلسلے کے ہر شیڈول کو شمار کرتے ہوئے';
  }
}
