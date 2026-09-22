// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get succeeded => 'نجح';

  @override
  String agentRunRetryLabel(int number, String time) {
    return 'إعادة المحاولة #$number · $time';
  }

  @override
  String agentRunStarting(String time) {
    return 'جارٍ البدء · $time';
  }

  @override
  String get agentActivityFollowingLive => 'متابعة النشاط المباشر';

  @override
  String get agentActivityJumpToLatest => 'الانتقال إلى الأحدث';

  @override
  String get agentActivityLoadFailed => 'تعذّر تحميل نشاط هذا التشغيل';

  @override
  String get agentActivityNotRecorded => 'لم يُسجَّل أي نشاط لهذا التشغيل';

  @override
  String get agentActivityNotRecordedHint =>
      'عمليات التشغيل التي انتهت قبل تفعيل تسجيل النشاط ليس لها مخطط زمني.';

  @override
  String get agentActivityRunUnavailable => 'هذا التشغيل لم يعد متاحًا';

  @override
  String agentActivitySubagentOf(String agent) {
    return 'وكيل فرعي تابع لـ $agent';
  }

  @override
  String get agentActivityUnsupported =>
      'تسجيل النشاط غير متاح على الخادم المتصل';

  @override
  String get agentActivityUnsupportedHint =>
      'أعد تشغيل التطبيق ليلتقط أحدث إصدار من الخادم.';

  @override
  String get agentActivityWaiting => 'في انتظار النشاط…';

  @override
  String get created => 'أُنشئ';

  @override
  String get dictationStart => 'بدء الإملاء';

  @override
  String get dictationListening => 'جارٍ الاستماع…';

  @override
  String get dictationUnavailable =>
      'يحتاج الإملاء إلى نموذج صوتي على مضيف الخادم. قم بإعداده في إعدادات الصوت.';

  @override
  String get dictationFailedToStart => 'تعذّر بدء الإملاء';

  @override
  String get dictationHoldToTalkTitle => 'اضغط مطولًا للتحدث';

  @override
  String get dictationHoldToTalkDescription =>
      'اضغط مطولًا على زر الميكروفون أو الاختصار للإملاء وحرّره للتوقف. عند إيقاف هذا الخيار، اضغط مرة للبدء ومرة أخرى للتوقف.';

  @override
  String get focusConversation => 'التركيز على المحادثة';

  @override
  String get ideAgentActivity => 'نشاط الوكيل';

  @override
  String get keybindingPushToTalk => 'اضغط للتحدث';

  @override
  String get keybindingPushToTalkDescription =>
      'اضغط مطولًا أو بدّل الإملاء الصوتي في محرر الرسائل';

  @override
  String get agentPermissions => 'أذونات الوكلاء';

  @override
  String get agentPermissionsSettingsDescription =>
      'حدد ما يمكن للوكلاء فعله من تلقاء أنفسهم، وما يجب أن يستأذنوا بشأنه أولًا، وما لا يمكنهم فعله أبدًا — لكل مساحة عمل أو وكيل أو مساحة.';

  @override
  String get agentPermissionsMatrixDescription =>
      'عيّن قرارًا لكل نوع من التأثيرات. القواعد متسلسلة: المساحة تتجاوز الوكيل، والوكيل يتجاوز مساحة العمل، ومساحة العمل تتجاوز الإعداد المسبق للوضع. القاعدة الأكثر تحديدًا هي التي تسري.';

  @override
  String get guardrailLoading => 'جارٍ تحميل القواعد…';

  @override
  String get guardrailRulesLoadFailed => 'تعذّر تحميل قواعد الأذونات.';

  @override
  String get guardrailScopeWorkspace => 'مساحة العمل';

  @override
  String get guardrailScopeAgent => 'الوكيل';

  @override
  String get guardrailScopeSpace => 'المساحة';

  @override
  String get guardrailSelectAgent => 'اختر وكيلًا';

  @override
  String get guardrailSelectSpace => 'اختر مساحة';

  @override
  String get guardrailNoAgents => 'لا يوجد وكلاء في مساحة العمل هذه بعد.';

  @override
  String get guardrailNoSpaces => 'لا توجد مساحات في مساحة العمل هذه بعد.';

  @override
  String get guardrailClassFileDelete => 'حذف ملف';

  @override
  String get guardrailClassFileWriteOutsideWorktree =>
      'الكتابة خارج شجرة العمل';

  @override
  String get guardrailClassGitCommit => 'إنشاء إيداع';

  @override
  String get guardrailClassGitPush => 'الدفع إلى مستودع بعيد';

  @override
  String get guardrailClassPrCreate => 'فتح طلب سحب';

  @override
  String get guardrailClassPrPublish => 'نشر مراجعة أو إجراء دمج';

  @override
  String get guardrailClassVendorSyncWrite => 'الكتابة إلى متتبع خارجي';

  @override
  String get guardrailClassNetworkEgress => 'الوصول إلى الشبكة';

  @override
  String get guardrailClassSecretAccess => 'قراءة سر';

  @override
  String get guardrailClassPackageInstall => 'تثبيت حزمة';

  @override
  String get guardrailClassProcessSpawn => 'تشغيل عملية';

  @override
  String get guardrailClassWorkspaceMutation => 'تغيير بنية مساحة العمل';

  @override
  String get guardrailClassEnclosureControl => 'قيادة حاوية معزولة (منصة)';

  @override
  String get navRigs => 'المنصات';

  @override
  String get rigsUnsupportedServer =>
      'لا يمكن لهذا الخادم استضافة أي أسطح rig. تحقّق من متطلبات المضيف للجهاز الذي تريد استخدامه.';

  @override
  String get rigSurfaceComputer => 'الحاسوب';

  @override
  String get rigSurfaceBrowser => 'المتصفح';

  @override
  String get rigSurfaceAndroid => 'Android';

  @override
  String get rigSurfaceIosSimulator => 'محاكي iOS';

  @override
  String rigSurfaceBrowserEngine(String engine) {
    return '$engine';
  }

  @override
  String rigBrowserEngineHint(String engine) {
    return 'نسخة ⁨$engine⁩ مؤقتة يمكن التخلص منها، معزولة عن جهازك. افتح محركًا آخر لمقارنة الصفحة نفسها جنبًا إلى جنب.';
  }

  @override
  String get rigPhaseReady => 'جاهز';

  @override
  String get rigPhaseStarting => 'قيد البدء';

  @override
  String get rigPhaseParked => 'موقوف مؤقتًا';

  @override
  String get rigPhaseClosing => 'قيد الإغلاق';

  @override
  String get rigPhaseClosed => 'مغلق';

  @override
  String get rigPhaseFailed => 'فشل';

  @override
  String get rigPhaseUnknown => 'غير معروف';

  @override
  String get rigNotAccelerated => 'محاكى';

  @override
  String get rigAudioListen => 'الاستماع إلى الجهاز';

  @override
  String get rigAudioMute => 'كتم صوت الجهاز';

  @override
  String get rigYouHaveControl => 'التحكم بيدك';

  @override
  String get rigBackendAvailable => 'متاح';

  @override
  String get rigBackendUnavailable => 'غير متاح';

  @override
  String get rigEgressNotEnforced =>
      'الشبكة غير معزولة على هذه الواجهة الخلفية — فهي تدير اتصالها بنفسها.';

  @override
  String get rigStartMachine => 'تشغيل الجهاز';

  @override
  String get rigStartHint =>
      'يشغّل جهاز VM مؤقتًا تتشاركه أنت ووكلاؤك في هذه المحادثة. يُدمَّر عند إغلاقه، ولا شيء بداخله يمس حاسوبك.';

  @override
  String get rigStartAndroidHint =>
      'يتصل بمحاكي Android يعمل بالفعل على الخادم. الوصول إلى الشبكة غير معزول.';

  @override
  String get rigStartIosHint =>
      'ينشئ محاكي iOS مؤقتًا على خادم macOS. يُحذف عند إغلاق بيئة الاختبار؛ الوصول إلى الشبكة غير معزول.';

  @override
  String get rigTechnicalDetails => 'التفاصيل التقنية';

  @override
  String get rigStopMachine => 'إيقاف الجهاز';

  @override
  String get rigHomeButton => 'الرئيسية';

  @override
  String get rigRotateClockwise => 'تدوير باتجاه عقارب الساعة';

  @override
  String get rigRotateCounterclockwise => 'تدوير عكس عقارب الساعة';

  @override
  String get rigTakeScreenshot => 'التقاط لقطة شاشة';

  @override
  String get rigScreenshotSaved => 'تم حفظ لقطة الشاشة';

  @override
  String rigScreenshotSaveFailed(String error) {
    return 'تعذر حفظ لقطة الشاشة: ⁨$error⁩';
  }

  @override
  String get rigSurfaceUnavailable =>
      'لا يمكن لهذا الخادم استضافة هذا النوع من الأجهزة.';

  @override
  String get rigTabNeedsConversation =>
      'افتح محادثة أولًا — فالجهاز يتبع محادثة واحدة، لتنظر أنت ووكلاؤك إلى الشاشة نفسها.';

  @override
  String get ideMenuSectionTools => 'الأدوات';

  @override
  String get ideMenuSectionMachines => 'الأجهزة';

  @override
  String get ideMenuSectionReopen => 'إعادة فتح';

  @override
  String get ideMenuSearchHint => 'بحث';

  @override
  String get ideMenuNoMatches => 'لا توجد نتائج مطابقة';

  @override
  String get rigMenuComputer => 'الحاسوب';

  @override
  String get rigMenuBrowser => 'المتصفح';

  @override
  String get rigMenuAndroid => 'Android';

  @override
  String get rigMenuIosSimulator => 'محاكي iOS';

  @override
  String rigLabelNumbered(String label, String suffix) {
    return '$label $suffix';
  }

  @override
  String ideCloseKeepTitle(String name) {
    return 'إغلاق $name؟';
  }

  @override
  String get ideCloseKeepBodyMachine =>
      'يستمر الجهاز في العمل في الخلفية — أعد فتحه في أي وقت من الشريط الجانبي. أوقف تشغيله بدلًا من ذلك لتحرير ذاكرته الآن.';

  @override
  String get ideCloseKeepBodyShell =>
      'يستمر الأمر في العمل في الخلفية — أعد فتح الصدفة في أي وقت من الشريط الجانبي. أنهِها بدلًا من ذلك لإيقاف ما تفعله الآن.';

  @override
  String get ideCloseKeepBodyAgent =>
      'يستمر الوكيل في العمل في الخلفية — أعد فتح المحادثة في أي وقت من الشريط الجانبي. أوقفه بدلًا من ذلك لإنهاء التشغيل الآن.';

  @override
  String get ideCloseKeepRunning => 'الإبقاء قيد التشغيل';

  @override
  String get ideCloseShutDownMachine => 'إيقاف التشغيل';

  @override
  String get ideCloseEndShell => 'إنهاء الصدفة';

  @override
  String get ideCloseStopAgent => 'إيقاف الوكيل';

  @override
  String get rigsSettingsSubtitle =>
      'ما يمكن لهذا الخادم إقلاعه، والصور الأساسية التي يحتاجها، والأجهزة قيد التشغيل الآن';

  @override
  String get rigsCapabilitiesTitle => 'هذا الخادم';

  @override
  String get rigInstallIosAutomation => 'تثبيت جسر أتمتة iOS';

  @override
  String get rigInstallingIosAutomation => 'جارٍ تثبيت جسر أتمتة iOS…';

  @override
  String get rigIosAutomationInstalled => 'تم تثبيت جسر أتمتة iOS';

  @override
  String get rigsImagesTitle => 'الصور الأساسية';

  @override
  String get rigsImagesHint =>
      'تُقلع كل منصة من إحدى هذه الصور المخصصة للقراءة فقط. تكتب كل جلسة إلى طبقة مؤقتة تُهمل لاحقًا، لذا لا يمكن لأي منصة تغيير ما تبدأ منه المنصة التالية.';

  @override
  String get rigsRunningTitle => 'قيد التشغيل الآن';

  @override
  String get rigsNoneRunning => 'لا توجد أجهزة قيد التشغيل.';

  @override
  String get rigsCustomImagesTitle => 'صور مخصصة (مساحة العمل هذه)';

  @override
  String get rigsCustomImagesHint =>
      'وجّه الطرفية (VM) أو المتصفح (VM) إلى صورتك الخاصة — وسّع الصور الافتراضية بالأدوات التي يحتاجها مشروعك، أو استخدم أي صورة متوافقة من سجلّ. تستخدمها الأجهزة الجديدة؛ وتحتفظ الأجهزة قيد التشغيل بصورها. راجع دليل المنصات لمعرفة ما يجب أن توفره الصورة.';

  @override
  String get rigsCustomTerminalImageLabel => 'صورة الطرفية (VM)';

  @override
  String get rigsCustomBrowserImageLabel => 'صورة المتصفح (VM)';

  @override
  String get rigsCustomImagePlaceholder =>
      'مثال: ⁨ghcr.io/acme/dev-shell:1.2⁩ — اتركه فارغًا لاستخدام الافتراضي';

  @override
  String get rigsCustomImageInvalid =>
      'أدخل مرجع سجلّ مثل ⁨repo/name:tag⁩. المسارات المحلية والأرشيفات غير مسموح بها.';

  @override
  String get rigsCustomImageSaved =>
      'تم الحفظ. تُقلع الأجهزة الجديدة من هذه الصورة؛ وتحتفظ الأجهزة قيد التشغيل بصورها.';

  @override
  String get rigsEgressTitle => 'خروج المتصفح إلى الشبكة (مساحة العمل هذه)';

  @override
  String get rigsEgressHint =>
      'مضيفون إضافيون يمكن للمتصفح المعزول الوصول إليهم — واحد في كل سطر: مضيف محدد (⁨api.example.com⁩) أو حرف بدل لنطاقاته الفرعية (⁨*.example.com⁩). يبقى موقع المنتج مسموحًا في الحالتين. تحصل الأجهزة الجديدة على القائمة؛ وتحتفظ الأجهزة قيد التشغيل بما أقلعت به.';

  @override
  String rigsEgressInvalid(String host) {
    return '\"⁨$host⁩\" ليس إدخال مضيف صالحًا.';
  }

  @override
  String get rigsEgressSaved =>
      'تم الحفظ. تسمح أجهزة المتصفح الجديدة بهؤلاء المضيفين؛ وتحتفظ الأجهزة قيد التشغيل بقائمتها.';

  @override
  String get rigImageInstalled => 'مثبّتة';

  @override
  String get rigImageNotDownloaded => 'لم تُنزَّل';

  @override
  String get rigImageNotPublished => 'غير منشورة';

  @override
  String get rigImageNotPublishedHint =>
      'لم تُنشر صورة لهذا بعد، لذا لا يوجد ما يُنزَّل. استورد صورة قرص متوافقة لتفعيله.';

  @override
  String get rigImageDownload => 'تنزيل';

  @override
  String get rigImageDownloading => 'جارٍ التنزيل…';

  @override
  String get rigImageImport => 'استيراد';

  @override
  String get rigImageImportMessage =>
      'مسار صورة قرص qcow2 على نظام ملفات الخادم. تُنسخ إلى مخزن الصور، لذا يمكن نقل الملف بعد ذلك.';

  @override
  String get rigConnectingStream => 'جارٍ الاتصال بالمنصة';

  @override
  String get rigStreamNotAllowed => 'ليس لديك صلاحية الوصول إلى هذه المنصة.';

  @override
  String get rigStreamNotRunning => 'هذه المنصة لم تعد قيد التشغيل.';

  @override
  String get rigStreamNeedsFfmpeg =>
      'يحتاج العرض المباشر إلى ⁨ffmpeg⁩ على هذا المضيف. ثبّت ⁨ffmpeg⁩ وأعد فتح علامة التبويب.';

  @override
  String get rigStreamEnded => 'انتهى العرض المباشر.';

  @override
  String get rigStreamFailed => 'تعذّر فتح العرض المباشر.';

  @override
  String get rigStreamDisconnected => 'غير متصل بخادم.';

  @override
  String rigDropSendingOne(String name) {
    return 'جارٍ نسخ \"⁨$name⁩\" إلى الجهاز…';
  }

  @override
  String rigDropSendingMany(int count) {
    return 'جارٍ نسخ $count من الملفات إلى الجهاز…';
  }

  @override
  String get rigTerminalDropSending => 'جارٍ النسخ إلى الجهاز…';

  @override
  String get rigTerminalPasteImage => 'حُفظت الصورة الملصقة في الجهاز';

  @override
  String get rigPortsTitle => 'المنافذ المعاد توجيهها';

  @override
  String get rigPortsTooltip => 'المنافذ المفتوحة داخل هذا الجهاز';

  @override
  String get rigPortsEmpty =>
      'لا شيء يستمع بعد. شغّل خادمًا في الطرفية — سيظهر هنا خادم تطوير على المنفذ 3000.';

  @override
  String get rigPortsAdd => 'إضافة منفذ';

  @override
  String get rigPortsAddHint =>
      'منفذ النظام الضيف المراد إعادة توجيهه (مثال: 3000)';

  @override
  String get rigPortsAutoForward => 'إعادة توجيه المنافذ تلقائيًا';

  @override
  String get rigPortsCopyUrl => 'نسخ عنوان URL المحلي';

  @override
  String rigPortsCopiedUrl(String url) {
    return 'تم نسخ ⁨$url⁩';
  }

  @override
  String get rigPortsStopForward => 'إيقاف إعادة التوجيه';

  @override
  String get rigPortsExposeLan => 'المشاركة على الشبكة المحلية';

  @override
  String get rigPortsLanPrivate => 'محلي فقط';

  @override
  String get rigPortsLanShared => 'على الشبكة';

  @override
  String get rigPortsSetDomain => 'تعيين نطاق للمتصفح (.test)';

  @override
  String get rigPortsDomainHint =>
      'نطاق للمتصفح (VM)، مثل ⁨myapp.test⁩ — يمكن الوصول إليه هناك، وليس على المضيف';

  @override
  String get rigPortsProcessUnknown => 'عملية غير معروفة';

  @override
  String get rigPortsInactive => 'لا يستمع';

  @override
  String get rigPortsTooltipHost => 'المنافذ المفتوحة في هذا الطرفية';

  @override
  String get rigPortsEmptyHost =>
      'لا يوجد شيء يستمع في هذا الطرفية بعد. ابدأ خادماً فيظهر هنا.';

  @override
  String get rigPortsAddHintHost => 'المنفذ للتعيين (مثل 5173)';

  @override
  String get rigPortsLocalPortHint => 'المنفذ المحلي (اختياري)';

  @override
  String rigPortsDestDesktop(int port) {
    return 'localhost:$port';
  }

  @override
  String rigPortsDestBrowser(int port) {
    return 'localhost:$port في المتصفح (آلة افتراضية)';
  }

  @override
  String get rigPortsDestBrowserUnreachable =>
      'المتصفح (آلة افتراضية) غير متصل';

  @override
  String rigPortsDestAndroid(int port) {
    return 'localhost:$port على أندرويد';
  }

  @override
  String get rigPortsDestAndroidUnreachable => 'أندرويد غير متصل';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صورة أساسية لا تزال بحاجة إلى التنزيل',
      many: '$count صورة أساسية لا تزال بحاجة إلى التنزيل',
      few: '$count صور أساسية لا تزال بحاجة إلى التنزيل',
      two: 'صورتان أساسيتان لا تزالان بحاجة إلى التنزيل',
      one: 'صورة أساسية واحدة لا تزال بحاجة إلى التنزيل',
      zero: 'لا صور أساسية بحاجة إلى التنزيل',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => 'السماح';

  @override
  String get guardrailDecisionPrompt => 'السؤال أولًا';

  @override
  String get guardrailDecisionDeny => 'الرفض';

  @override
  String get guardrailSourceThisScope => 'هذا النطاق';

  @override
  String get guardrailSourceDefault => 'الافتراضي المضمّن';

  @override
  String get guardrailSourcePreset => 'الإعداد المسبق للوضع';

  @override
  String get guardrailSourceInherited => 'موروث';

  @override
  String get guardrailClearToInherited => 'إعادة التعيين إلى الموروث';

  @override
  String get guardrailWhatIf => 'ماذا لو؟';

  @override
  String get guardrailWhatIfDescription =>
      'اطّلع على كيفية بتّ القواعد الحالية في إجراء ما، باستخدام المنطق نفسه الذي يخضع له الوكلاء.';

  @override
  String get guardrailProbeActionLabel => 'الإجراء';

  @override
  String get guardrailProbeCommandLabel => 'الأمر (اختياري)';

  @override
  String get guardrailProbeCommandHint => 'مثال: ⁨git push origin main⁩';

  @override
  String get guardrailProbeAgentLabel => 'الوكيل (اختياري)';

  @override
  String get guardrailProbeSpaceLabel => 'المساحة (اختياري)';

  @override
  String get guardrailProbeNone => 'بلا';

  @override
  String get guardrailProbeModeLabel => 'الوضع';

  @override
  String get guardrailProbeResult => 'النتيجة';

  @override
  String get guardrailProbeSource => 'المصدر:';

  @override
  String get guardrailAdapterMatrix => 'أين تُفرض القواعد';

  @override
  String get guardrailAdapterMatrixDescription =>
      'مرجع صريح: أين يُرصد كل تأثير فعليًا، لكل مشغّل وكلاء. هذا يوثّق الواقع وليس ضمانًا — فالتأثيرات التي ينفذها المشغّل خارج النطاق لا يمكن اعتراضها.';

  @override
  String get guardrailEffectColumn => 'التأثير';

  @override
  String get guardrailAdapterHarness => 'الإطار المضمّن';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => 'الحد الأدنى للبيئة المعزولة';

  @override
  String get guardrailEnforcementPolicyGate => 'بوابة السياسة';

  @override
  String get guardrailEnforcementSandbox => 'البيئة المعزولة فقط';

  @override
  String get guardrailEnforcementNone => 'غير قابل للفرض';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      'يُفحص قرار الإذن قبل تنفيذ التأثير ويمكنه منعه.';

  @override
  String get guardrailEnforcementSandboxHelp =>
      'البيئة المعزولة وحدها تقيّده؛ ولا يُرجَع إلى قاعدة الإذن.';

  @override
  String get guardrailEnforcementNoneHelp =>
      'القرار استشاري فقط — لا يمكن اعتراضه هنا.';

  @override
  String get obsStatCost => 'التكلفة';

  @override
  String obsStatDelegatedCost(String amount) {
    return '+$amount مفوَّضة';
  }

  @override
  String get obsStatDuration => 'المدة';

  @override
  String get obsStatTokens => 'الرموز';

  @override
  String get obsStatTools => 'الأدوات';

  @override
  String get openAgentActivity => 'فتح النشاط';

  @override
  String get orgChart => 'الهيكل التنظيمي';

  @override
  String get orgChartEmpty => 'لا يوجد وكلاء بعد';

  @override
  String get navCalendar => 'التقويم';

  @override
  String get serverConnection => 'اتصال الخادم';

  @override
  String get serverModeLocal => 'التشغيل داخل هذا التطبيق';

  @override
  String get serverModeLocalDescription =>
      'يشغّل Control Center خادمه الخاص على هذا الجهاز ويملك بياناتك محليًا.';

  @override
  String get serverModeRemote => 'الاتصال بمثيل بعيد';

  @override
  String get serverModeRemoteDescription =>
      'اتصل بخادم Control Center يعمل في مكان آخر. تبقى بياناتك على ذلك الخادم.';

  @override
  String get serverRemoteUrl => 'عنوان URL للخادم';

  @override
  String get serverRemoteDeviceId => 'معرّف الجهاز';

  @override
  String get serverRemotePairingKey => 'مفتاح الاقتران';

  @override
  String get serverRemotePairingKeyHint =>
      'الصق مفتاح الاقتران من الخادم البعيد';

  @override
  String get serverSetupInviteCode => 'رمز الدعوة';

  @override
  String get serverSetupInviteCodeHint =>
      'الصق رمز دعوة يُستخدم مرة واحدة (اتركه فارغًا لاستخدام مفتاح اقتران)';

  @override
  String get serverDiscoveryTooltip => 'البحث عن خوادم على شبكتك';

  @override
  String get serverDiscoveryTitle => 'الخوادم على شبكتك';

  @override
  String get serverDiscoverySearching => 'جارٍ البحث عن الخوادم…';

  @override
  String get serverDiscoveryEmpty =>
      'لم يُعثر على خوادم. تأكد من أن الخادم يعمل وأن هذا الجهاز يمكنه الوصول إليه، ثم ابحث مجددًا.';

  @override
  String get serverDiscoveryRefresh => 'البحث مجددًا';

  @override
  String get serverListActive => 'نشط';

  @override
  String get serverListSwitch => 'تبديل';

  @override
  String get serverListAddTitle => 'إضافة خادم';

  @override
  String get serverListRemoveActiveHint =>
      'بدّل إلى خادم آخر قبل إزالة هذا الخادم.';

  @override
  String get serverSwitchFailedTitle => 'تعذّر تبديل الخادم';

  @override
  String get serverListInsecureBadge => 'غير آمن';

  @override
  String get connectionPathLocal => 'محلي';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => 'جارٍ إيقاف التشغيل';

  @override
  String get shutdownSubtitle => 'جارٍ إغلاق الخادم المحلي';

  @override
  String get shutdownServiceApprovals => 'الموافقات';

  @override
  String get shutdownServiceBackgroundJobs => 'المهام في الخلفية';

  @override
  String get shutdownServiceScheduler => 'مجدول المهام';

  @override
  String get shutdownServiceCalendar => 'مزامنة التقويم';

  @override
  String get shutdownServiceWeather => 'الطقس';

  @override
  String get shutdownServiceSoundscape => 'المشهد الصوتي';

  @override
  String get shutdownServiceMeetings => 'الاجتماعات';

  @override
  String get shutdownServiceVoiceModels => 'النماذج الصوتية';

  @override
  String get shutdownServiceNetworking => 'الشبكات';

  @override
  String get shutdownServicePresence => 'الحضور';

  @override
  String get shutdownServiceDataSync => 'مزامنة البيانات';

  @override
  String get shutdownServiceDeviceRelay => 'مرحّل الأجهزة';

  @override
  String get shutdownServiceMcpConnections => 'اتصالات MCP';

  @override
  String get shutdownServiceCodeEditors => 'محررات التعليمات البرمجية';

  @override
  String get serverSharingTitle => 'مشاركة هذا الخادم';

  @override
  String get serverSharingDescription =>
      'اجعل هذا الخادم قابلًا للوصول من أجهزتك الأخرى. لا يُكشف أي شيء علنًا ما لم تفعّل نفقًا أدناه. تضمّن دعوات الاقتران عناوين الخادم الحالية تلقائيًا — أنشئها من إعدادات مساحة العمل.';

  @override
  String get serverSharingUnavailable =>
      'عناصر التحكم في المشاركة غير متاحة على هذا الخادم.';

  @override
  String get serverSharingMdnsLabel => 'اكتشاف الشبكة المحلية';

  @override
  String get serverSharingMdnsOn =>
      'يجري الإعلان عن هذا الخادم على شبكتك المحلية (mDNS)';

  @override
  String get serverSharingMdnsOff => 'لا يجري الإعلان على شبكتك المحلية (mDNS)';

  @override
  String get serverSharingTunnelLabel => 'النفق';

  @override
  String get serverSharingTunnelHelper =>
      'تفعيل النفق يجعل هذا الخادم قابلًا للوصول من الإنترنت. الكشف العلني اختياري ومعطّل افتراضيًا.';

  @override
  String get serverSharingProviderOff => 'إيقاف';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => 'عنوان URL العام';

  @override
  String get serverSharingTunnelStarting => 'جارٍ بدء النفق…';

  @override
  String serverSharingTunnelError(String error) {
    return 'خطأ في النفق: ⁨$error⁩';
  }

  @override
  String get serverSharingTunnelUpNoUrl =>
      'النفق يعمل. يمكن الوصول إليه عبر اسم مضيف DNS الذي هيّأته.';

  @override
  String get serverSharingRelayLabel => 'المرحّل';

  @override
  String serverSharingRelayUsage(String amount) {
    return 'المُرحَّل هذا الشهر: $amount';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return 'جلسات الترحيل النشطة: $count';
  }

  @override
  String get serverSharingUpdateFailedTitle => 'تعذّر تحديث المشاركة';

  @override
  String get pairNewClient => 'اقتران عميل جديد';

  @override
  String get pairClientNameHint =>
      'سمِّ هذا العميل (مثال: حاسوب العمل المحمول)';

  @override
  String get pairClientTypeWeb => 'متصفح ويب';

  @override
  String get pairClientTypeDesktop => 'تطبيق سطح المكتب';

  @override
  String get pairClientTypePhone => 'هاتف';

  @override
  String get pairAction => 'اقتران';

  @override
  String get revoke => 'إبطال';

  @override
  String get pairCredentialsIntro =>
      'اربط العميل الجديد بهذه التفاصيل، أو افتح الرابط فيه.';

  @override
  String get pairLinkLabel => 'الرابط';

  @override
  String get pairScanQr => 'امسح رمز QR هذا بكاميرا هاتفك لإقرانه.';

  @override
  String get pairServerUnreachableTitle => 'غير قابل للوصول';

  @override
  String get pairServerUnreachable =>
      'لا يمكن للأجهزة الأخرى الوصول إلى هذا الخادم مباشرة، لذا لا يمكن لعميل جديد الاتصال. عيّن عنوان URL العام للخادم لإقران مزيد من العملاء.';

  @override
  String get serverSetupTitle => 'كيف ينبغي أن يعمل Control Center؟';

  @override
  String get serverSetupSubtitle =>
      'يحتاج Control Center إلى خادم يملك بياناتك. شغّل واحدًا داخل هذا التطبيق، أو اتصل بمثيل يعمل في مكان آخر.';

  @override
  String get serverSetupRunLocal => 'التشغيل داخل هذا التطبيق';

  @override
  String get serverSetupConnect => 'اتصال';

  @override
  String get serverSetupInvalidUrl =>
      'أدخل عنوان URL صالحًا للخادم يبدأ بـ ⁨ws://⁩ أو ⁨wss://⁩.';

  @override
  String get serverSetupCouldNotConnect => 'تعذّر الاتصال';

  @override
  String get serverSetupErrorUnreachable =>
      'تعذّر الوصول إلى الخادم. تأكد من أنه يعمل وأن هذا الجهاز يمكنه الوصول إليه (الشبكة نفسها أو عبر مرحّل).';

  @override
  String get serverSetupErrorIdentityMismatch =>
      'هوية الخادم لا تطابق الهوية المحفوظة على هذا الجهاز. إذا أُعيد تثبيت الخادم أو إعادة تعيينه، فأزل الخادم المحفوظ وأعد الاقتران.';

  @override
  String get serverSetupErrorAuthRejected =>
      'رفض الخادم هذا الجهاز. تأكد من أن مفتاح الاقتران ومعرّف الجهاز يطابقان ما أصدره الخادم.';

  @override
  String get serverSetupErrorInviteRejected =>
      'رمز الدعوة غير صالح أو منتهي الصلاحية. اطلب رمزًا جديدًا.';

  @override
  String get serverSetupErrorGeneric =>
      'حدث خطأ أثناء الاتصال. وسّع التفاصيل التقنية أدناه لمزيد من المعلومات.';

  @override
  String get serverSetupErrorDetails => 'التفاصيل التقنية';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حدث آخر',
      many: '$count حدثًا آخر',
      few: '$count أحداث أخرى',
      two: 'حدثان آخران',
      one: 'حدث واحد آخر',
      zero: 'لا مزيد',
    );
    return '$_temp0';
  }

  @override
  String get calendarAllDayGutter => 'طوال اليوم';

  @override
  String calendarAllDayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حدث',
      many: '$count حدثًا',
      few: '$count أحداث',
      two: 'حدثان',
      one: 'حدث واحد',
      zero: 'لا أحداث',
    );
    return '$_temp0';
  }

  @override
  String get calendarCollapseAllDay => 'طي أحداث اليوم الكامل';

  @override
  String get calendarExpandAllDay => 'توسيع أحداث اليوم الكامل';

  @override
  String get calendarViewMonth => 'شهر';

  @override
  String get calendarViewWeek => 'أسبوع';

  @override
  String get calendarViewAgenda => 'جدول الأعمال';

  @override
  String get calendarConnectGoogle => 'ربط تقويم Google';

  @override
  String get calendarConnectDescription =>
      'زامن تقويم Google لديك لرؤية الأحداث هنا وتلقي تنبيهات قبل بدء الاجتماعات.';

  @override
  String get calendarDisconnect => 'قطع الاتصال';

  @override
  String get calendarReconnect => 'إعادة الاتصال';

  @override
  String get calendarEmptyNoEvents => 'لا أحداث في هذا النطاق';

  @override
  String get calendarStartRecording => 'بدء التسجيل';

  @override
  String get calendarStartRecordingAndLink => 'بدء التسجيل والربط';

  @override
  String get calendarJoinMeet => 'الانضمام إلى الاجتماع';

  @override
  String get calendarFromCalendar => 'من التقويم';

  @override
  String get calendarLinkedMeeting => 'اجتماع مرتبط';

  @override
  String get calendarToday => 'اليوم';

  @override
  String get calendarAllDay => 'طوال اليوم';

  @override
  String calendarWeekNumber(int number) {
    return 'الأسبوع $number';
  }

  @override
  String get calendarPreviousPeriod => 'السابق';

  @override
  String get calendarNextPeriod => 'التالي';

  @override
  String calendarLastSynced(String time) {
    return 'تمت المزامنة $time';
  }

  @override
  String get calendarNeverSynced => 'لم تتم المزامنة بعد';

  @override
  String get calendarSyncing => 'جارٍ المزامنة…';

  @override
  String get calendarViewDay => 'يوم';

  @override
  String get calendarShow => 'إظهار';

  @override
  String get calendarHide => 'إخفاء';

  @override
  String get calendarRsvpGoing => 'هل ستحضر؟';

  @override
  String get calendarRsvpYes => 'نعم';

  @override
  String get calendarRsvpNo => 'لا';

  @override
  String get calendarRsvpMaybe => 'ربما';

  @override
  String get calendarRsvpFailed => 'تعذّر تحديث ردّك';

  @override
  String get calendarAddAccount => 'إضافة حساب تقويم';

  @override
  String get calendarSettingsTitle => 'تقويم Google';

  @override
  String get calendarSettingsDescription =>
      'اربط حساب Google لمزامنة الأحداث في مساحة العمل هذه. هذه التقاويم لك هنا.';

  @override
  String get calendarConnecting => 'جارٍ الاتصال…';

  @override
  String get calendarSyncNow => 'المزامنة الآن';

  @override
  String get calendarNoWorkspace => 'اختر مساحة عمل لعرض تقويمها';

  @override
  String get calendarConnectError => 'تعذّر ربط تقويم Google';

  @override
  String get calendarClientIdLabel => 'معرّف العميل';

  @override
  String get calendarClientSecretLabel => 'سر العميل';

  @override
  String get calendarConnectCredsHint =>
      'أدخل معرّف عميل Google OAuth لتدفق رمز الجهاز وسرّه الخاصين بمشروعك. الخادم هو من يتولى الاتصال والمزامنة — متصفحك لا يحتفظ برموز الوصول أبدًا.';

  @override
  String get calendarConnectApproveInstruction =>
      'افتح صفحة التحقق على أي جهاز، وسجّل الدخول وأدخل هذا الرمز:';

  @override
  String get calendarConnectOpenPage => 'فتح صفحة التحقق';

  @override
  String get calendarConnectWaiting => 'في انتظار الموافقة…';

  @override
  String get calendarConnectDenied => 'رُفض التفويض. يرجى المحاولة مجددًا.';

  @override
  String get calendarConnectExpired =>
      'انتهت صلاحية الرمز. يرجى المحاولة مجددًا.';

  @override
  String get notificationMeetingStartsSoon => 'اجتماع يبدأ قريبًا';

  @override
  String get notifyMeetingStartsSoon =>
      'عندما يوشك اجتماع في التقويم على البدء';

  @override
  String get notificationCalendarAuthExpiredTitle => 'انقطع اتصال التقويم';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'أعد ربط ⁨$email⁩ لاستئناف المزامنة';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'أعد ربط تقويمك لاستئناف المزامنة';

  @override
  String get notifyCalendarAuthExpired =>
      'عندما يحتاج حساب تقويم إلى إعادة الربط';

  @override
  String get notificationRigStatusChanged => 'تحديثات الحاوية المعزولة';

  @override
  String get notifyRigStatusChanged =>
      'عند تولي التحكم بحاوية معزولة أو استردادها أو فشلها';

  @override
  String get notificationRigTakenOver => 'تم تولي التحكم بالحاوية المعزولة';

  @override
  String get notificationRigTakenOverBody =>
      'شخص يقود الجهاز الآن؛ يمكن للوكيل المشاهدة دون التصرف.';

  @override
  String get notificationRigReleased => 'تم تحرير التحكم بالحاوية المعزولة';

  @override
  String get notificationRigReleasedBody => 'عاد الجهاز إلى الوكيل.';

  @override
  String get notificationRigReclaimed => 'استُردَّت الحاوية المعزولة';

  @override
  String get notificationRigReclaimedBodyIdle =>
      'ظل الجهاز خاملًا، فأُغلق لتحرير الذاكرة.';

  @override
  String get notificationRigReclaimedBodyTtl => 'بلغ حده الزمني فأُغلق.';

  @override
  String get notificationRigFailed => 'فشلت الحاوية المعزولة';

  @override
  String get notificationRigFailedBody =>
      'توقف برنامج hypervisor الذي يشغّله. أعد فتح الجهاز للمتابعة.';

  @override
  String get calendarAlertLeadTime => 'مهلة التنبيه';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'قبل كم من الوقت من الاجتماع يتم تنبيهك';

  @override
  String calendarConnectedAs(String email) {
    return 'متصل باسم ⁨$email⁩';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count من الحضور';
  }

  @override
  String get calendarEventLabel => 'حدث';

  @override
  String get calendarRecurring => 'حدث متكرر';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'المنظّم';

  @override
  String get calendarYou => 'أنت';

  @override
  String get calendarShowFewer => 'إظهار أقل';

  @override
  String get calendarRsvpAwaiting => 'في الانتظار';

  @override
  String calendarParticipantsCount(int count) {
    return '$count من المشاركين';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'عرض جميع المشاركين ($count)';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count نعم';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count لا';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count ربما';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count في الانتظار';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count دقيقة';
  }

  @override
  String get openInEditorPrompt => 'فتح في أي محرر؟';

  @override
  String get ideNotInstalled => 'غير مثبّت';

  @override
  String openInIde(String editor) {
    return 'فتح في ⁨$editor⁩';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return 'تعذّر فتح ⁨$editor⁩: ⁨$error⁩';
  }

  @override
  String get profileSearchHint => 'البحث في طلبات السحب…';

  @override
  String get stopAgentRun => 'إيقاف التشغيل';

  @override
  String get stopAgentRunConfirm =>
      'هل تريد إيقاف هذا التشغيل؟ سيضيع العمل الجاري.';

  @override
  String get inProgress => 'قيد التنفيذ';

  @override
  String get drafts => 'المسودات';

  @override
  String get sortOldest => 'الأقدم';

  @override
  String get sortLargest => 'الأكبر';

  @override
  String get prFilterTooltip => 'تصفية';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عامل تصفية نشط',
      many: '$count عامل تصفية نشطًا',
      few: '$count عوامل تصفية نشطة',
      two: 'عاملا تصفية نشطان',
      one: 'عامل تصفية نشط واحد',
      zero: 'لا عوامل تصفية نشطة',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => 'إضافة عامل تصفية…';

  @override
  String get prFilterFieldHint => 'تصفية…';

  @override
  String get prFilterCategoryStatus => 'الحالة';

  @override
  String get prFilterCategoryAuthor => 'المؤلف';

  @override
  String get prFilterCategoryReviewer => 'المراجعون';

  @override
  String get prFilterCategoryContent => 'المحتوى';

  @override
  String get prFilterCategoryRepoOwner => 'مالك المستودع';

  @override
  String get prFilterCategoryRepoName => 'اسم المستودع';

  @override
  String get prFilterCategoryOpenedDate => 'تاريخ الفتح';

  @override
  String get prFilterCategoryUpdatedDate => 'تاريخ التحديث';

  @override
  String get prFilterQuickToReview => 'سريع المراجعة';

  @override
  String get prFilterClearAll => 'مسح عوامل التصفية';

  @override
  String prFilterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلب سحب',
      many: '$count طلب سحب',
      few: '$count طلبات سحب',
      two: 'طلبا سحب',
      one: 'طلب سحب واحد',
      zero: 'لا طلبات سحب',
    );
    return '$_temp0';
  }

  @override
  String prFilterHiddenOptions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count خيار لا يطابق أي طلب سحب',
      many: '$count خيارًا لا يطابق أي طلب سحب',
      few: '$count خيارات لا تطابق أي طلب سحب',
      two: 'خياران لا يطابقان أي طلب سحب',
      one: 'خيار واحد لا يطابق أي طلب سحب',
      zero: 'لا توجد خيارات غير مطابقة لأي طلب سحب',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => 'العنوان أو النص يحتوي على…';

  @override
  String get prFilterNoOptions => 'لا خيارات مطابقة';

  @override
  String get prFilterChipIs => 'هو';

  @override
  String get prFilterChipIsAnyOf => 'هو أي من';

  @override
  String get prFilterChipContains => 'يحتوي على';

  @override
  String get prFilterChipSince => 'منذ';

  @override
  String get prFilterAddFilterButton => 'إضافة عامل تصفية';

  @override
  String prFilterClearCategory(String category) {
    return 'مسح عامل تصفية $category';
  }

  @override
  String get prFilterCurrentUser => 'المستخدم الحالي';

  @override
  String get prStatusDraft => 'مسودة';

  @override
  String get prStatusOpen => 'مفتوح';

  @override
  String get prStatusInReview => 'قيد المراجعة';

  @override
  String get prStatusChangesRequested => 'طُلبت تغييرات';

  @override
  String get prStatusApproved => 'معتمد';

  @override
  String get prStatusMerged => 'مدموج';

  @override
  String get prStatusClosed => 'مغلق';

  @override
  String get prDateWindowDay => 'قبل يوم واحد';

  @override
  String get prDateWindowThreeDays => 'قبل 3 أيام';

  @override
  String get prDateWindowWeek => 'قبل أسبوع واحد';

  @override
  String get prDateWindowMonth => 'قبل شهر واحد';

  @override
  String get prDateWindowThreeMonths => 'قبل 3 أشهر';

  @override
  String get prDateWindowSixMonths => 'قبل 6 أشهر';

  @override
  String get prDateWindowYear => 'قبل سنة واحدة';

  @override
  String get prDisplayOptions => 'خيارات العرض';

  @override
  String get prDisplayGrouping => 'التجميع';

  @override
  String get prDisplayOrdering => 'الترتيب';

  @override
  String get prDisplayShowDrafts => 'إظهار المسودات';

  @override
  String get prDisplayMergedWindow => 'الفترة الزمنية للمدموجة';

  @override
  String get prDisplayMergedWindowDay => 'اليوم الماضي';

  @override
  String get prDisplayMergedWindowWeek => 'الأسبوع الماضي';

  @override
  String get prDisplayMergedWindowMonth => 'الشهر الماضي';

  @override
  String get prDisplayProperties => 'خصائص العرض';

  @override
  String get prGroupingRepository => 'المستودع';

  @override
  String get prGroupingAuthor => 'المؤلف';

  @override
  String get prGroupingStatus => 'الحالة';

  @override
  String get prGroupingNone => 'بلا تجميع';

  @override
  String get prPropertyRepository => 'المستودع';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => 'الفرع';

  @override
  String get prPropertyUpdated => 'آخر تحديث';

  @override
  String get prPropertyAuthor => 'المؤلف';

  @override
  String get prPropertyChecks => 'الفحوصات';

  @override
  String get prPropertyDiff => 'الفرق';

  @override
  String get prPropertyComments => 'التعليقات';

  @override
  String get keybindingOpenFilterMenu => 'فتح قائمة التصفية';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'فتح قائمة تصفية طلبات السحب';

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم تحديد $count عنصر',
      many: 'تم تحديد $count عنصرًا',
      few: 'تم تحديد $count عناصر',
      two: 'تم تحديد عنصرين',
      one: 'تم تحديد عنصر واحد',
      zero: 'لم يُحدَّد أي عنصر',
    );
    return '$_temp0';
  }

  @override
  String get summary => 'الملخص';

  @override
  String get kbMove => 'تنقّل';

  @override
  String get kbTabs => 'علامات التبويب';

  @override
  String get kbSearch => 'بحث';

  @override
  String get kbViewed => 'مشاهدة';

  @override
  String get kbCollapse => 'طي';

  @override
  String get appearance => 'المظهر';

  @override
  String get appearanceSettingsDescription => 'السمة واللغة وأسلوب الخط.';

  @override
  String get notificationsSettingsDescription =>
      'اختر أحداث الوكلاء ومساحة العمل التي تصلك إشعارات عنها.';

  @override
  String get advanced => 'متقدم';

  @override
  String get accounts => 'الحسابات';

  @override
  String get mcpServers => 'خوادم MCP';

  @override
  String get mcpServersSettingsDescription =>
      'خادم MCP المضمّن وخوادم MCP الخارجية.';

  @override
  String get remoteControlAndDevices => 'التحكم عن بُعد والأجهزة';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'اقرن الهواتف وهيّئ خادم التحكم عن بُعد.';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'نماذج الكلام وفصل المتحدثين التي يستضيفها هذا الخادم.';

  @override
  String get needsSetupLabel => 'يتطلب إعدادًا';

  @override
  String get collapseSidebar => 'طي الشريط الجانبي';

  @override
  String get expandSidebar => 'توسيع الشريط الجانبي';

  @override
  String get filterSpacesHint => 'تصفية المساحات';

  @override
  String noSpacesMatch(String query) {
    return 'لا مساحات تطابق \"$query\"';
  }

  @override
  String get privacy => 'الخصوصية';

  @override
  String get sendDiffContentTitle =>
      'إرسال محتوى الفروق إلى مهايئ الذكاء الاصطناعي';

  @override
  String get diffSharingOnSubtitle =>
      'تُضمَّن أسطر الفروق الخام في موجّهات الوكلاء لمراجعة أعمق.';

  @override
  String get diffSharingOffSubtitle =>
      'يستخدم الوكلاء البيانات الوصفية المهيكلة فقط (مسارات الملفات وأرقام الأسطر ووصف الـ PR)؛ ولا تغادر أي تعليمات برمجية خام التطبيق.';

  @override
  String get errorReportingTitle => 'مشاركة تقارير الأعطال';

  @override
  String get errorReportingOnSubtitle =>
      'تُرسل تشخيصات الأعطال والأخطاء والأداء للمساعدة في إصلاح المشكلات (إصدارات النشر فقط).';

  @override
  String get errorReportingOffSubtitle =>
      'التشخيصات معطّلة. لا تُرسل أي تقارير أعطال أو أخطاء.';

  @override
  String get onboardingDiagnosticsTitle => 'ساعد في تحسين Control Center';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'أرسل تشخيصات الأعطال والأخطاء والأداء لنتمكن من إصلاح المشكلات أسرع (إصدارات النشر فقط). يمكنك تغيير هذا في أي وقت من الإعدادات ← الخصوصية.';

  @override
  String get blocked => 'محظور';

  @override
  String get idle => 'خامل';

  @override
  String get noRunsYet => 'لا عمليات تشغيل بعد';

  @override
  String get copyPath => 'نسخ المسار';

  @override
  String get copyRelativePath => 'نسخ المسار النسبي';

  @override
  String get nameRequired => 'الاسم مطلوب';

  @override
  String get import => 'استيراد';

  @override
  String get noMatchingAgents => 'لا وكلاء يطابقون عامل التصفية';

  @override
  String watchVideoOn(String provider) {
    return 'مشاهدة الفيديو على ⁨$provider⁩';
  }

  @override
  String get branchTemplate => 'قالب اسم الفرع';

  @override
  String get branchTemplateDescription =>
      'نمط الفرع الذي يُنشأ عند بدء تذكرة في شجرة عمل معزولة.';

  @override
  String branchTemplatePreview(String example) {
    return 'مثال: ⁨$example⁩';
  }

  @override
  String get deletePipelineRun => 'حذف تشغيل خط الأنابيب';

  @override
  String deletePipelineRunConfirm(String template) {
    return 'هل تريد حذف هذا التشغيل من \"$template\"؟ لا يمكن التراجع عن هذا.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'خطأ أثناء حذف تشغيل خط الأنابيب: ⁨$error⁩';
  }

  @override
  String get deleteTicket => 'حذف التذكرة';

  @override
  String deleteTicketConfirm(String title) {
    return 'هل تريد حذف \"$title\"؟ لا يمكن التراجع عن هذا.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'خطأ أثناء حذف التذكرة: ⁨$error⁩';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return 'هل تريد حذف \"$name\"؟ لن تُمس المستودعات المرتبطة على القرص.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'خطأ أثناء حذف مساحة العمل: ⁨$error⁩';
  }

  @override
  String get indexCode => 'فهرسة التعليمات البرمجية';

  @override
  String get indexNoGrammars => 'قواعد تحليل التعليمات البرمجية غير مثبّتة';

  @override
  String get indexFailed => 'فشلت الفهرسة';

  @override
  String indexedSymbolsCount(int count) {
    return 'تمت فهرسة $count من الرموز';
  }

  @override
  String get nodeConfigAdvanced => 'متقدم';

  @override
  String get nodeConfigReducer => 'المخفِّض';

  @override
  String get nodeConfigReducerHelp =>
      'كيفية الدمج عندما يكون لمفتاح الإخراج هذا قيمة بالفعل';

  @override
  String get nodeConfigTimeoutMs => 'المهلة (مللي ثانية)';

  @override
  String get nodeConfigRetryAttempts => 'محاولات الإعادة';

  @override
  String get nodeConfigContinueOnFail => 'المتابعة إذا فشلت هذه الخطوة';

  @override
  String get nodeConfigTeamId => 'معرّف الفريق';

  @override
  String get nodeConfigDispatchMode => 'وضع الإرسال';

  @override
  String get nodeConfigOutputSchema => 'مخطط الإخراج (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'مخطط JSON الذي يجب أن يطابقه إخراج الخطوة';

  @override
  String get diffLineDisplay => 'الأسطر الطويلة في الفروق';

  @override
  String get diffLineDisplayDescription =>
      'التفاف الأسطر الطويلة أو تمريرها أفقيًا';

  @override
  String get diffLineWrap => 'التفاف';

  @override
  String get diffLineScroll => 'التمرير أفقيًا';

  @override
  String get actions => 'إجراءات';

  @override
  String get activate => 'تفعيل';

  @override
  String get activity => 'النشاط';

  @override
  String get activityLabel => 'النشاط';

  @override
  String get activitySearchHint => 'البحث في النشاط';

  @override
  String get activityNoMatches => 'لا يوجد نشاط يطابق عوامل التصفية';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$start–$end من $total';
  }

  @override
  String get activityPreviousPage => 'الصفحة السابقة';

  @override
  String get activityNextPage => 'الصفحة التالية';

  @override
  String get activityNetworkLocal => 'المضيف المحلي';

  @override
  String get activityClearFilter => 'مسح عامل التصفية';

  @override
  String activityFilterIp(String ip) {
    return 'IP ⁨$ip⁩';
  }

  @override
  String activityFilterCountry(String country) {
    return 'البلد $country';
  }

  @override
  String get activitySavedWorkspaceLogo => 'حفظ شعار مساحة العمل';

  @override
  String activityVerbCreated(String target) {
    return 'أنشأ $target';
  }

  @override
  String activityVerbUpdated(String target) {
    return 'حدّث $target';
  }

  @override
  String activityVerbDeleted(String target) {
    return 'حذف $target';
  }

  @override
  String activityVerbAdded(String target) {
    return 'أضاف $target';
  }

  @override
  String activityVerbRemoved(String target) {
    return 'أزال $target';
  }

  @override
  String activityVerbInvited(String target) {
    return 'دعا $target';
  }

  @override
  String activityVerbChanged(String target) {
    return 'غيّر $target';
  }

  @override
  String activityVerbStarted(String target) {
    return 'بدأ $target';
  }

  @override
  String activityVerbStopped(String target) {
    return 'أوقف $target';
  }

  @override
  String activityVerbWrote(String target) {
    return 'كتب $target';
  }

  @override
  String get activityTargetAgent => 'الوكيل';

  @override
  String get activityTargetTicket => 'التذكرة';

  @override
  String get activityTargetWorkspace => 'مساحة العمل';

  @override
  String get activityTargetRepository => 'المستودع';

  @override
  String get activityTargetMember => 'العضو';

  @override
  String get activityTargetInvite => 'الدعوة';

  @override
  String get activityTargetSpace => 'المساحة';

  @override
  String get activityTargetMessage => 'الرسالة';

  @override
  String get activityTargetCache => 'ذاكرة التخزين المؤقت';

  @override
  String get activityTargetFile => 'الملف';

  @override
  String get activityTargetPipeline => 'خط الأنابيب';

  @override
  String get activityTargetTemplate => 'القالب';

  @override
  String get activityTargetProvider => 'المزوّد';

  @override
  String get activityTargetModel => 'النموذج';

  @override
  String get activityTargetSkill => 'المهارة';

  @override
  String get activityTargetTodo => 'المهمة';

  @override
  String get activityTargetMeeting => 'الاجتماع';

  @override
  String get activityTargetProject => 'المشروع';

  @override
  String get activityTargetTeam => 'الفريق';

  @override
  String get activityTargetDevice => 'الجهاز';

  @override
  String get activityTargetPreference => 'التفضيل';

  @override
  String get activityTargetBudget => 'الميزانية';

  @override
  String activityVerbApproved(String target) {
    return 'وافق على $target';
  }

  @override
  String activityVerbArchived(String target) {
    return 'أرشف $target';
  }

  @override
  String activityVerbAssigned(String target) {
    return 'أسند $target';
  }

  @override
  String activityVerbBackedUp(String target) {
    return 'نسخ $target احتياطيًا';
  }

  @override
  String activityVerbCancelled(String target) {
    return 'ألغى $target';
  }

  @override
  String activityVerbCleared(String target) {
    return 'مسح $target';
  }

  @override
  String activityVerbClosed(String target) {
    return 'أغلق $target';
  }

  @override
  String activityVerbCommitted(String target) {
    return 'أودع $target';
  }

  @override
  String activityVerbCompacted(String target) {
    return 'ضغط $target';
  }

  @override
  String activityVerbCompleted(String target) {
    return 'أكمل $target';
  }

  @override
  String activityVerbConnected(String target) {
    return 'وصّل $target';
  }

  @override
  String activityVerbContinued(String target) {
    return 'تابع $target';
  }

  @override
  String activityVerbDisconnected(String target) {
    return 'فصل $target';
  }

  @override
  String activityVerbDispatched(String target) {
    return 'أوفد $target';
  }

  @override
  String activityVerbDrained(String target) {
    return 'أفرغ $target';
  }

  @override
  String activityVerbEnrolled(String target) {
    return 'قيّد $target';
  }

  @override
  String activityVerbEstimated(String target) {
    return 'قدّر $target';
  }

  @override
  String activityVerbImported(String target) {
    return 'استورد $target';
  }

  @override
  String activityVerbInstalled(String target) {
    return 'ثبّت $target';
  }

  @override
  String activityVerbKilled(String target) {
    return 'أنهى $target قسرًا';
  }

  @override
  String activityVerbMarked(String target) {
    return 'علّم $target';
  }

  @override
  String activityVerbMerged(String target) {
    return 'دمج $target';
  }

  @override
  String activityVerbOpened(String target) {
    return 'فتح $target';
  }

  @override
  String activityVerbPaused(String target) {
    return 'أوقف $target مؤقتًا';
  }

  @override
  String activityVerbPolled(String target) {
    return 'استطلع $target';
  }

  @override
  String activityVerbPrepared(String target) {
    return 'جهّز $target';
  }

  @override
  String activityVerbProcessed(String target) {
    return 'عالج $target';
  }

  @override
  String activityVerbPublished(String target) {
    return 'نشر $target';
  }

  @override
  String activityVerbRefined(String target) {
    return 'نقّح $target';
  }

  @override
  String activityVerbRefreshed(String target) {
    return 'أعاد تحميل $target';
  }

  @override
  String activityVerbRegistered(String target) {
    return 'سجّل $target';
  }

  @override
  String activityVerbRenamed(String target) {
    return 'أعاد تسمية $target';
  }

  @override
  String activityVerbReordered(String target) {
    return 'أعاد ترتيب $target';
  }

  @override
  String activityVerbResponded(String target) {
    return 'ردّ على $target';
  }

  @override
  String activityVerbRestored(String target) {
    return 'استعاد $target';
  }

  @override
  String activityVerbResumed(String target) {
    return 'استأنف $target';
  }

  @override
  String activityVerbRetried(String target) {
    return 'أعاد محاولة $target';
  }

  @override
  String activityVerbReverted(String target) {
    return 'تراجع عن $target';
  }

  @override
  String activityVerbReviewed(String target) {
    return 'راجع $target';
  }

  @override
  String activityVerbRan(String target) {
    return 'شغّل $target';
  }

  @override
  String activityVerbSelected(String target) {
    return 'حدد $target';
  }

  @override
  String activityVerbSent(String target) {
    return 'أرسل $target';
  }

  @override
  String activityVerbStaged(String target) {
    return 'أدرج $target مرحليًا';
  }

  @override
  String activityVerbSteered(String target) {
    return 'وجّه $target';
  }

  @override
  String activityVerbSubmitted(String target) {
    return 'قدّم $target';
  }

  @override
  String activityVerbSynced(String target) {
    return 'زامن $target';
  }

  @override
  String activityVerbToggled(String target) {
    return 'بدّل $target';
  }

  @override
  String activityVerbUninstalled(String target) {
    return 'ألغى تثبيت $target';
  }

  @override
  String activityVerbUnstaged(String target) {
    return 'أزال $target من الإدراج المرحلي';
  }

  @override
  String get activityTargetActionPolicy => 'سياسة الإجراءات';

  @override
  String get activityTargetGoalRun => 'تشغيل الهدف';

  @override
  String get activityTargetRunLog => 'سجل التشغيل';

  @override
  String get activityTargetWorkingMemory => 'الذاكرة العاملة';

  @override
  String get activityTargetRoutingPolicy => 'سياسة التوجيه';

  @override
  String get activityTargetAutonomy => 'الاستقلالية';

  @override
  String get activityTargetCalendar => 'التقويم';

  @override
  String get activityTargetChecker => 'المدقق';

  @override
  String get activityTargetEditor => 'المحرر';

  @override
  String get activityTargetConfirmation => 'التأكيد';

  @override
  String get activityTargetTunnel => 'النفق';

  @override
  String get activityTargetConversation => 'المحادثة';

  @override
  String get activityTargetCredentials => 'بيانات الاعتماد';

  @override
  String get activityTargetDictation => 'الإملاء';

  @override
  String get activityTargetAgentRun => 'تشغيل الوكيل';

  @override
  String get activityTargetEvalSuite => 'حزمة التقييم';

  @override
  String get activityTargetWorker => 'العامل';

  @override
  String get activityTargetWorktree => 'شجرة العمل';

  @override
  String get activityTargetMcpServer => 'خادم MCP';

  @override
  String get activityTargetMemoryAccessGrant => 'إذن الوصول إلى الذاكرة';

  @override
  String get activityTargetMemoryDomain => 'نطاق الذاكرة';

  @override
  String get activityTargetMemoryFact => 'حقيقة الذاكرة';

  @override
  String get activityTargetMemoryPolicy => 'سياسة الذاكرة';

  @override
  String get activityTargetFeed => 'الموجز';

  @override
  String get activityTargetNote => 'الملاحظة';

  @override
  String get activityTargetOrchestration => 'التنسيق';

  @override
  String get activityTargetPipelineRun => 'تشغيل خط الأنابيب';

  @override
  String get activityTargetPipelineTrigger => 'مشغّل خط الأنابيب';

  @override
  String get activityTargetPlan => 'الخطة';

  @override
  String get activityTargetPlaybook => 'دليل التشغيل';

  @override
  String get activityTargetPullRequest => 'طلب السحب';

  @override
  String get activityTargetReview => 'المراجعة';

  @override
  String get activityTargetProcess => 'العملية';

  @override
  String get activityTargetProviderPolicy => 'سياسة المزوّد';

  @override
  String get activityTargetReaction => 'التفاعل';

  @override
  String get activityTargetReviewSpace => 'مساحة المراجعة';

  @override
  String get activityTargetReviewStudio => 'استوديو المراجعة';

  @override
  String get activityTargetServerData => 'بيانات الخادم';

  @override
  String get activityTargetSoundscape => 'المشهد الصوتي';

  @override
  String get activityTargetSession => 'الجلسة';

  @override
  String get activityTargetTerminal => 'الطرفية';

  @override
  String get activityTargetTicketLink => 'رابط التذكرة';

  @override
  String get activityTargetTicketSync => 'مزامنة التذاكر';

  @override
  String get activityTargetProfile => 'الملف الشخصي';

  @override
  String get activityTargetVoiceProfile => 'الملف الصوتي';

  @override
  String get activityTargetWeather => 'توقعات الطقس';

  @override
  String get activityTargetWorkProduct => 'ناتج العمل';

  @override
  String get activityChangedMemberRole => 'غيّر دور أحد الأعضاء';

  @override
  String get activityChangedMemberRepoAccess =>
      'غيّر وصول أحد الأعضاء إلى المستودعات';

  @override
  String get activityUpdatedGitHubToken => 'حدّث رمز وصول GitHub';

  @override
  String get activityRefreshedWeather => 'حدّث توقعات الطقس';

  @override
  String get activitySetWeatherLocation => 'عيّن موقع الطقس';

  @override
  String get activityClearedWeatherLocation => 'مسح موقع الطقس';

  @override
  String get activityMarkedAllArticlesRead => 'علّم جميع المقالات كمقروءة';

  @override
  String get activityMarkedArticleRead => 'علّم مقالة كمقروءة';

  @override
  String get activityUpdatedSavedArticle => 'حدّث مقالة محفوظة';

  @override
  String get activityTookOverSession => 'تولّى الجلسة';

  @override
  String get activityHandedBackSession => 'أعاد تسليم الجلسة';

  @override
  String get activityCommittedAndPushed => 'أودع ودفع';

  @override
  String get activityBackedUpServer => 'نسخ بيانات الخادم احتياطيًا';

  @override
  String get activityMarkedSpaceRead => 'علّم المساحة كمقروءة';

  @override
  String get activityRespondedToInvitation => 'ردّ على دعوة الحدث';

  @override
  String get activityStartedCalendarConnect => 'بدأ ربط التقويم';

  @override
  String get activityDisconnectedCalendar => 'فصل التقويم';

  @override
  String get activityMarkedFileViewed => 'علّم ملفًا كمعروض';

  @override
  String get activityRespondedToApproval => 'ردّ على طلب موافقة';

  @override
  String get activityChangedTunnel => 'غيّر إعداد النفق';

  @override
  String get activitySentMessageToAgent => 'أرسل رسالة إلى الوكيل';

  @override
  String get activityOpenedReviewSpace => 'فتح مساحة المراجعة';

  @override
  String get activityOpenedStandingConversation => 'فتح المحادثة الدائمة';

  @override
  String get activityStartedRecording => 'بدأ التسجيل';

  @override
  String get activityStoppedRecording => 'أوقف التسجيل';

  @override
  String get activityToggledMcpServer => 'بدّل خادم MCP';

  @override
  String get activityUpdatedMcpToken => 'حدّث رمز وصول MCP';

  @override
  String get activitySavedApiKey => 'حفظ مفتاح API';

  @override
  String get activityRemovedProviderCredential => 'أزال بيانات اعتماد مزوّد';

  @override
  String get activityUpdatedLinkedRepos => 'حدّث المستودعات المرتبطة';

  @override
  String get activityUnlinkedRepo => 'ألغى ربط مستودع';

  @override
  String get activityUpdatedActionItem => 'حدّث بند إجراء';

  @override
  String adRulesCount(int count) {
    return '$count من قواعد الإعلانات';
  }

  @override
  String get adapter => 'المحوّل';

  @override
  String get adapterLabel => 'المحوّل';

  @override
  String get adapters => 'المحوّلات';

  @override
  String get adaptersAutoDetected =>
      'مشغّلات الوكلاء المكتشفة تلقائيًا والمتاحة على هذا الجهاز. ثبّت أي أدوات CLI مفقودة لتمكين مشغّلات إضافية.';

  @override
  String get add => 'إضافة';

  @override
  String get addAComment => 'إضافة تعليق';

  @override
  String get addAReaction => 'إضافة تفاعل';

  @override
  String get addASuggestion => 'إضافة اقتراح';

  @override
  String get addAgents => 'إضافة وكلاء';

  @override
  String get addEmoji => 'إضافة رمز تعبيري';

  @override
  String get addFeed => 'إضافة موجز';

  @override
  String get addressBarHint => 'أدخل عنوان URL';

  @override
  String get addFromFile => 'إضافة من ملف';

  @override
  String get addGif => 'إضافة GIF';

  @override
  String get addGithubRepoPrompt =>
      'أضف مستودع GitHub واحدًا على الأقل لعرض طلبات السحب';

  @override
  String get addLocalCheckoutDescription =>
      'أضف نسخة محلية لبدء استهدافها من مساحة العمل هذه.';

  @override
  String get addRepository => 'إضافة مستودع';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'إضافة $count مستودع',
      many: 'إضافة $count مستودعًا',
      few: 'إضافة $count مستودعات',
      two: 'إضافة مستودعين',
      one: 'إضافة مستودع',
      zero: 'إضافة مستودعات',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro =>
      'تصفّح المجلدات على الجهاز الذي يشغّل الخادم وحدد نسخ git المراد تسجيلها.';

  @override
  String get selectThisFolder => 'تحديد هذا المجلد';

  @override
  String get deselectThisFolder => 'إلغاء تحديد هذا المجلد';

  @override
  String get goUp => 'لأعلى';

  @override
  String get noSubfoldersHere => 'لا توجد مجلدات فرعية هنا';

  @override
  String get notAGitRepository => 'هذا المجلد ليس مستودع git.';

  @override
  String get addToken => 'إضافة رمز وصول';

  @override
  String get addWorkspace => 'إضافة مساحة عمل';

  @override
  String get addWorkspaceEllipsis => 'إضافة مساحة عمل…';

  @override
  String get added => 'تمت الإضافة';

  @override
  String get addingEllipsis => 'جارٍ الإضافة…';

  @override
  String get advancedLabel => 'متقدم';

  @override
  String get agent => 'الوكيل';

  @override
  String agentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count وكيل',
      many: '$count وكيلًا',
      few: '$count وكلاء',
      two: '$count وكيلان',
      one: '$count وكيل',
      zero: '$count وكلاء',
    );
    return '$_temp0';
  }

  @override
  String get agentMdPath => 'مسار ملف Markdown للوكيل';

  @override
  String get agentName => 'اسم الوكيل';

  @override
  String get agentTitle => 'لقب الوكيل';

  @override
  String get agentUpdated => 'تم تحديث الوكيل.';

  @override
  String get agents => 'الوكلاء';

  @override
  String get agentsMentionSection => 'الوكلاء';

  @override
  String get usersMentionSection => 'الأشخاص';

  @override
  String get ticketsMentionSection => 'التذاكر';

  @override
  String get pullRequestsMentionSection => 'طلبات السحب';

  @override
  String get meetingsMentionSection => 'الاجتماعات';

  @override
  String get entityRefTicketFallback => 'تذكرة';

  @override
  String get entityRefPrFallback => 'طلب سحب';

  @override
  String get entityRefMeetingFallback => 'اجتماع';

  @override
  String get aiReview => 'مراجعة الذكاء الاصطناعي';

  @override
  String get all => 'الكل';

  @override
  String get allAgentsAlreadyInSpace =>
      'جميع الوكلاء موجودون بالفعل في هذه المساحة.';

  @override
  String get allCommits => 'جميع الإيداعات';

  @override
  String get allSources => 'جميع المصادر';

  @override
  String get allow => 'السماح';

  @override
  String get allowGitPush => 'السماح بـ ⁨git push⁩';

  @override
  String get allowGithubApi => 'السماح باستدعاءات GitHub API';

  @override
  String get allowNetwork => 'السماح بالوصول العام إلى الشبكة';

  @override
  String get apiKeys => 'مفاتيح API';

  @override
  String get appFont => 'خط التطبيق';

  @override
  String get appLogLevelDebugDescription => 'يضيف تتبّعات مفصّلة - للتطوير.';

  @override
  String get appLogLevelDebugLabel => 'تصحيح';

  @override
  String get appLogLevelErrorDescription =>
      'الأخطاء والاستثناءات غير المتوقعة فقط.';

  @override
  String get appLogLevelErrorLabel => 'خطأ';

  @override
  String get appLogLevelInfoDescription => 'يضيف رسائل دورة الحياة والحالة.';

  @override
  String get appLogLevelInfoLabel => 'معلومات';

  @override
  String get appLogLevelNoneDescription => 'بدون أي إخراج إلى وحدة التحكم.';

  @override
  String get appLogLevelNoneLabel => 'بلا';

  @override
  String get appLogLevelVerboseDescription =>
      'كل شيء. صاخب للغاية - استخدمه للتصحيح فقط.';

  @override
  String get appLogLevelVerboseLabel => 'مفصّل';

  @override
  String get appLogLevelWarningDescription =>
      'يضيف التحذيرات والمشكلات القابلة للاسترداد.';

  @override
  String get appLogLevelWarningLabel => 'تحذير';

  @override
  String get appearanceLanguage => 'المظهر واللغة';

  @override
  String get apply => 'تطبيق';

  @override
  String get approve => 'موافقة';

  @override
  String get agentApprovalRequired => 'الموافقة مطلوبة';

  @override
  String agentApprovalsMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر آخر في الانتظار',
      many: '$count عنصرًا آخر في الانتظار',
      few: '$count عناصر أخرى في الانتظار',
      two: 'عنصران آخران في الانتظار',
      one: 'عنصر واحد آخر في الانتظار',
      zero: 'لا مزيد في الانتظار',
    );
    return '$_temp0';
  }

  @override
  String get approved => 'تمت الموافقة';

  @override
  String get articleNoun => 'مقالة';

  @override
  String get articlesSubscribed => 'مقالات من الموجزات التي اشتركت فيها.';

  @override
  String get askAi => 'اسأل الذكاء الاصطناعي';

  @override
  String get askAiReviewDescription =>
      'اطلب من الذكاء الاصطناعي مراجعة هذا الـ PR';

  @override
  String get assignees => 'المُسند إليهم';

  @override
  String get attachImage => 'إرفاق صورة';

  @override
  String get attachedAgents => 'الوكلاء المرفقون';

  @override
  String get audioInput => 'إدخال الصوت';

  @override
  String get audioOutput => 'إخراج الصوت';

  @override
  String get authenticationToken => 'رمز وصول المصادقة';

  @override
  String authoredByLabel(String role) {
    return 'بواسطة: $role';
  }

  @override
  String get autoRecommended => 'تلقائي (موصى به)';

  @override
  String get available => 'متاح';

  @override
  String get awaitingYourReview => 'بانتظار مراجعتك';

  @override
  String get back => 'رجوع';

  @override
  String get backLabel => 'رجوع';

  @override
  String get backend => 'الخلفية';

  @override
  String get blockAdsTrackers =>
      'حظر الإعلانات والمتتبعات ولافتات ملفات تعريف الارتباط';

  @override
  String get blocking => 'الحظر';

  @override
  String get bookmarkLabel => 'إشارة مرجعية';

  @override
  String get briefDescription => 'وصف موجز';

  @override
  String get bugLabel => 'خلل';

  @override
  String get bundledDefaultsNeverUpdated =>
      'الإعدادات الافتراضية المضمّنة — لا تُحدَّث أبدًا';

  @override
  String get cancel => 'إلغاء';

  @override
  String get cancelEdit => 'إلغاء التحرير';

  @override
  String get categoryCreation => 'الإنشاء';

  @override
  String get categoryEditing => 'التحرير';

  @override
  String get categoryNavigation => 'التنقل';

  @override
  String get categorySystem => 'النظام';

  @override
  String get categoryView => 'عرض حسب الفئة';

  @override
  String get change => 'تغيير';

  @override
  String get changesRequested => 'طُلبت تغييرات';

  @override
  String get spacesMentionSection => 'المساحات';

  @override
  String get checkForUpdates => 'التحقق من التحديثات';

  @override
  String get checking => 'جارٍ التحقق';

  @override
  String get checkingEllipsis => 'جارٍ التحقق…';

  @override
  String get chooseAppFont => 'اختيار خط التطبيق';

  @override
  String get chooseCodeFont => 'اختيار خط التعليمات البرمجية';

  @override
  String get chooseRunner => 'اختر مشغّل الوكيل.';

  @override
  String get clear => 'مسح';

  @override
  String get clickToRetry => 'انقر لإعادة المحاولة';

  @override
  String get close => 'إغلاق';

  @override
  String get closeEsc => 'إغلاق (Esc)';

  @override
  String get closeReader => 'إغلاق القارئ';

  @override
  String get closed => 'مغلق';

  @override
  String get codeFont => 'خط التعليمات البرمجية';

  @override
  String get codeFontLigatures => 'حروف الربط في خط التعليمات البرمجية';

  @override
  String get codeFontLigaturesDescription =>
      'عرض حروف الربط البرمجية (=>, !=, ->) كمحارف مدمجة في التعليمات البرمجية والفروق';

  @override
  String get collapse => 'طي';

  @override
  String get commandPalette => 'لوحة الأوامر';

  @override
  String get commandPaletteOrgMembers => 'أعضاء المؤسسة';

  @override
  String get commandPaletteBrowseTeam => 'تصفّح الفريق';

  @override
  String get commandPaletteBrowseTeamDesc => 'عرض جميع أعضاء المؤسسة';

  @override
  String get compactDone => 'تم ضغط المحادثة. طُوي السجل الأقدم في ملخص.';

  @override
  String get compactNothing =>
      'لا يوجد ما يمكن ضغطه بعد. المحادثة لا تزال قصيرة.';

  @override
  String get compactBusy =>
      'لا يزال أحد الوكلاء يعمل. نفّذ الضغط عند انتهاء الدور.';

  @override
  String get compactUnavailable => 'الضغط غير متاح على هذا الخادم.';

  @override
  String get commandsMentionSection => 'الأوامر';

  @override
  String get comment => 'تعليق';

  @override
  String get commentOnThisFile => 'التعليق على هذا الملف';

  @override
  String get commented => 'تم التعليق';

  @override
  String get commits => 'الإيداعات';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'عرض أحدث $loaded من أصل $total من الإيداعات';
  }

  @override
  String get prCloneProgressCloningTitle => 'جارٍ استنساخ المستودع';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'يغيّر هذا الـ PR $fileCount من الملفات، وهو ما يتجاوز حد GitHub API. جارٍ استنساخ المستودع محليًا…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'يتجاوز هذا الـ PR حد الملفات في GitHub API. جارٍ استنساخ المستودع محليًا…';

  @override
  String get prCloneProgressFetchingTitle => 'جارٍ جلب مراجع الـ PR';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'جارٍ جلب الفرع الأساسي ومرجع رأس الـ PR…';

  @override
  String get prCloneProgressComputingTitle => 'جارٍ حساب الفرق';

  @override
  String get prCloneProgressComputingSubtitle =>
      'جارٍ تشغيل ⁨git diff⁩ محليًا…';

  @override
  String get prCloneProgressErrorTitle => 'فشل تحميل الفرق';

  @override
  String get prCloneProgressErrorSubtitle =>
      'حدث خطأ أثناء استنساخ المستودع أو حساب الفرق. جرّب التحديث.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'لا يزال العمل جاريًا… مضى ⁨$elapsed⁩';
  }

  @override
  String confidenceLabel(int percent) {
    return 'الثقة: $percent%';
  }

  @override
  String get configureAgentIdentities =>
      'اضبط هويات الوكلاء والموجّهات والمهارات واعرض عمليات التشغيل.';

  @override
  String get configureDefaultRunners =>
      'اضبط المحوّل والنموذج المستخدمين للمساحات الجديدة وتوليد العناوين.';

  @override
  String get configuredLabel => 'تم الضبط.';

  @override
  String get confirmedBy => 'تم التأكيد بواسطة';

  @override
  String get consensus => 'الإجماع';

  @override
  String get contentHint => 'ما الذي يجب تذكّره';

  @override
  String get contentLabel => 'المحتوى';

  @override
  String get contentMarkdown => 'المحتوى (Markdown)';

  @override
  String get contextWindowSize => 'حجم نافذة السياق';

  @override
  String modelContextChip(String size) {
    return 'النموذج · $size';
  }

  @override
  String get continueLabel => 'متابعة';

  @override
  String get conversationMode => 'الوضع';

  @override
  String cookieRulesCount(int count) {
    return '$count من قواعد ملفات تعريف الارتباط';
  }

  @override
  String get copied => 'تم النسخ!';

  @override
  String get copy => 'نسخ';

  @override
  String get copyAddress => 'نسخ العنوان';

  @override
  String get copyBaseBranchTooltip => 'نسخ اسم الفرع الأساسي';

  @override
  String get copyHeadBranchTooltip => 'نسخ اسم فرع الرأس';

  @override
  String couldNotListDevices(String error) {
    return 'تعذّر سرد الأجهزة: ⁨$error⁩';
  }

  @override
  String get create => 'إنشاء';

  @override
  String get createOrSelectWorkspace =>
      'أنشئ مساحة عمل أو حدد واحدة قبل إضافة المستودعات.';

  @override
  String get createPullRequest => 'إنشاء طلب سحب';

  @override
  String get createdByMe => 'من إنشائي';

  @override
  String createdLabel(String date) {
    return 'تاريخ الإنشاء: $date';
  }

  @override
  String get currentParticipants => 'المشاركون الحاليون';

  @override
  String get customCapabilitiesDescription => 'وصف القدرات المخصصة';

  @override
  String get customSystemPrompt => 'موجّه نظام مخصص لهذا الوكيل...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count يوم',
      many: 'قبل $count يومًا',
      few: 'قبل $count أيام',
      two: 'قبل يومين',
      one: 'قبل يوم واحد',
      zero: 'قبل $count يوم',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'إلغاء التفعيل';

  @override
  String get defaultCapabilities => 'القدرات الافتراضية · المساحات الجديدة';

  @override
  String get defaultChat => 'الدردشة الافتراضية';

  @override
  String get defaultRunners => 'المشغّلات الافتراضية';

  @override
  String get delete => 'حذف';

  @override
  String get deleteAgent => 'حذف الوكيل';

  @override
  String deleteAgentConfirm(String name) {
    return 'هل تريد حذف \"$name\"؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get deleteSpace => 'حذف المساحة';

  @override
  String deleteConfirmName(String name) {
    return 'هل تريد حذف \"$name\"؟';
  }

  @override
  String get archiveConversation => 'أرشفة المحادثة';

  @override
  String get deleteFact => 'حذف الحقيقة';

  @override
  String get deleteFeedBody =>
      'يزيل هذا الموجز وجميع مقالاته المخزّنة مؤقتًا. ستُزال أيضًا المقالات المحفوظة بإشارة مرجعية من هذا الموجز.';

  @override
  String deleteFeedConfirm(String name) {
    return 'هل تريد حذف \"$name\"؟';
  }

  @override
  String get deletePolicy => 'حذف السياسة';

  @override
  String get deletePolicyConfirm =>
      'هل تريد حذف هذه السياسة؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String deleteTopicConfirm(String topic) {
    return 'هل تريد حذف \"$topic\"؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get deleteWorkspace => 'حذف مساحة العمل';

  @override
  String get deny => 'رفض';

  @override
  String get detailsLabel => 'التفاصيل';

  @override
  String get descriptionLabel => 'الوصف';

  @override
  String detectedBackend(String label) {
    return 'تم الاكتشاف: $label';
  }

  @override
  String get detectedRunners => 'المشغّلات المكتشفة';

  @override
  String get detectingAdapters => 'جارٍ اكتشاف المحوّلات…';

  @override
  String get detectingInputDevices => 'جارٍ اكتشاف أجهزة الإدخال…';

  @override
  String detectionFailed(String error) {
    return 'فشل الاكتشاف: ⁨$error⁩';
  }

  @override
  String get disabled => 'معطّل';

  @override
  String get discover => 'استكشاف';

  @override
  String get dismissed => 'تم التجاهل';

  @override
  String get domainHint => 'مثال: api-performance';

  @override
  String get domainLabel => 'النطاق';

  @override
  String get download => 'تنزيل';

  @override
  String get downloadingLabel => 'جارٍ التنزيل';

  @override
  String downloadingModel(int pct) {
    return 'جارٍ تنزيل النموذج… $pct%';
  }

  @override
  String get draft => 'مسودة';

  @override
  String get draftLabel => 'مسودة';

  @override
  String get edit => 'تحرير';

  @override
  String get edited => 'معدّل';

  @override
  String get editMessage => 'تحرير الرسالة';

  @override
  String get revertToThere => 'التراجع إلى هناك';

  @override
  String get sendAsNewMessage => 'إرسال كرسالة جديدة';

  @override
  String get editMessageChoiceBody =>
      'يؤدي التراجع إلى إخفاء الرسائل بعد هذه الرسالة وإعادة ملفات الوكيل. يمكنك التراجع عن ذلك. الإرسال كرسالة جديدة يُبقي المحادثة كما هي.';

  @override
  String get deleteMessage => 'حذف الرسالة';

  @override
  String get deleteMessageConfirm =>
      'هل تريد حذف هذه الرسالة؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get messageDeleted => 'تم حذف الرسالة';

  @override
  String get searchInConversation => 'البحث في المحادثة';

  @override
  String get searchMessagesHint => 'البحث في الرسائل…';

  @override
  String get noMessagesFound => 'لم يُعثر على رسائل';

  @override
  String get editFact => 'تحرير الحقيقة';

  @override
  String get editPolicy => 'تحرير السياسة';

  @override
  String get editSuggestedCodeHint => 'حرّر التعليمات البرمجية المقترحة…';

  @override
  String get editSuggestion => 'تحرير الاقتراح';

  @override
  String get egArchitect => 'مثال: architect';

  @override
  String get egControlCenter => 'مثال: control-center';

  @override
  String get egPlatform => 'مثال: Platform';

  @override
  String get egSamuelAlev => 'مثال: SamuelAlev';

  @override
  String get egSoftwareArchitect => 'مثال: مهندس برمجيات';

  @override
  String get egTheVerge => 'مثال: The Verge';

  @override
  String get egTokenLimit => 'مثال: 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'فشل التثبيت: ⁨$error⁩';
  }

  @override
  String get embeddingInstalled =>
      'تم تثبيت نموذج التضمين المحلي. البحث الهجين ممكّن.';

  @override
  String get embeddingModel => 'نموذج التضمين (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'غير مثبّت. يقتصر البحث على الكلمات المفتاحية حتى يتم التمكين.';

  @override
  String get embeddingRedownloadBody =>
      'ستُحذف ملفات النموذج الحالية ويُعاد تنزيلها. لن يتوفر البحث الدلالي حتى يكتمل التنزيل.';

  @override
  String get embeddingRemoveBody =>
      'سيُعطَّل البحث الدلالي حتى تعيد التثبيت. يمكنك إعادة التثبيت في أي وقت.';

  @override
  String get speakerDiarization => 'تمييز المتحدثين';

  @override
  String get diarizationModel => 'نموذج تمييز المتحدثين';

  @override
  String get diarizationInstalled =>
      'مثبّت — يسمّي كل متحدث في نصوص الاجتماعات';

  @override
  String get diarizationNotInstalled =>
      'غير مثبّت — لن يُفصل بين المتحدثين في الاجتماعات';

  @override
  String diarizationInstallFailed(String error) {
    return 'فشل التثبيت: ⁨$error⁩';
  }

  @override
  String get redownloadDiarizationModel => 'إعادة تنزيل نموذج تمييز المتحدثين';

  @override
  String get diarizationRedownloadBody =>
      'يزيل هذا نماذج تمييز المتحدثين الحالية ويعيد تنزيلها.';

  @override
  String get removeDiarizationModel => 'إزالة نموذج تمييز المتحدثين';

  @override
  String get diarizationRemoveBody =>
      'يحذف هذا نماذج تمييز المتحدثين الموجودة على الجهاز. لن تتأثر نصوص الاجتماعات المنتجة سابقًا.';

  @override
  String get enableNotifications => 'تمكين الإشعارات';

  @override
  String get enableSandboxing => 'تمكين البيئة المعزولة';

  @override
  String get enabled => 'ممكّن';

  @override
  String errorCreatingAgent(String error) {
    return 'خطأ في إنشاء الوكيل: ⁨$error⁩';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'خطأ في حذف الوكيل: ⁨$error⁩';
  }

  @override
  String errorWithDetail(String error) {
    return 'خطأ: ⁨$error⁩';
  }

  @override
  String get expand => 'توسيع';

  @override
  String extractingModel(int pct) {
    return 'جارٍ استخراج النموذج… $pct%';
  }

  @override
  String get fact => 'حقيقة';

  @override
  String factCount(int count) {
    return '$count حقيقة';
  }

  @override
  String factCountPlural(int count) {
    return '$count حقائق';
  }

  @override
  String get facts => 'الحقائق';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount من الحقائق · $policyCount من السياسات';
  }

  @override
  String get failed => 'فشل';

  @override
  String failedToDispatch(String error) {
    return 'فشل الإرسال: ⁨$error⁩';
  }

  @override
  String get failedToLoad => 'فشل التحميل';

  @override
  String failedToLoadAgents(String error) {
    return 'فشل تحميل الوكلاء: ⁨$error⁩';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'فشل تحميل الموجزات: ⁨$error⁩';
  }

  @override
  String get failedToLoadGifs => 'فشل تحميل صور GIF';

  @override
  String failedToLoadLogs(String error) {
    return 'فشل تحميل السجلات: ⁨$error⁩';
  }

  @override
  String get failedToLoadRepos => 'فشل تحميل المستودعات';

  @override
  String get failedToLoadWorkspaces => 'فشل تحميل مساحات العمل';

  @override
  String failedToStartAiReview(String error) {
    return 'فشل بدء مراجعة الذكاء الاصطناعي: ⁨$error⁩';
  }

  @override
  String get failedToStartMicTest => 'فشل بدء اختبار الميكروفون.';

  @override
  String failedToSubmitReview(String error) {
    return 'فشل إرسال المراجعة: ⁨$error⁩';
  }

  @override
  String failedToUpload(String name, String error) {
    return 'فشل رفع ⁨$name⁩: ⁨$error⁩';
  }

  @override
  String failedWithError(String error) {
    return 'فشل: ⁨$error⁩';
  }

  @override
  String get failure => 'فشل';

  @override
  String get feedAlreadyExists => 'يوجد موجز بعنوان URL هذا بالفعل.';

  @override
  String get feedUrlExample => 'مثال: https://example.com/feed.xml';

  @override
  String get feedUrlLabel => 'عنوان URL للموجز';

  @override
  String feedsCount(int count) {
    return 'الموجزات ($count)';
  }

  @override
  String get filesChanged => 'الملفات المتغيّرة';

  @override
  String filesCount(int count) {
    return '$count من الملفات';
  }

  @override
  String get filesMentionSection => 'الملفات';

  @override
  String get filterAgents => 'تصفية الوكلاء...';

  @override
  String get filterFilesHint => 'تصفية الملفات…';

  @override
  String get filterLists => 'قوائم التصفية';

  @override
  String get filterSkillsPlaceholder => 'تصفية المهارات…';

  @override
  String get finish => 'إنهاء';

  @override
  String get fix => 'إصلاح';

  @override
  String get forward => 'للأمام';

  @override
  String get gatesGithubPatPush =>
      'يتحكّم في حقن رمز GitHub PAT. مطلوب ليتمكن الوكيل من الدفع.';

  @override
  String get general => 'عام';

  @override
  String get githubLink => 'رابط GitHub';

  @override
  String get claudeStatusFetchFailed => 'تعذّر الوصول إلى status.claude.com';

  @override
  String get claudeStatusOpenInBrowser => 'فتح status.claude.com';

  @override
  String get githubStatusFetchFailed => 'تعذّر الوصول إلى githubstatus.com';

  @override
  String get githubDegradedTitle => 'يبلّغ GitHub عن مشكلات';

  @override
  String githubDegradedStatusLine(String status) {
    return 'حالة GitHub: $status.';
  }

  @override
  String githubDegradedBody(String status) {
    return 'حالة GitHub: $status. قد تكون بيانات طلبات السحب قديمة أو غير مكتملة حتى يتعافى.';
  }

  @override
  String get githubStatusOpenInBrowser => 'فتح githubstatus.com';

  @override
  String get githubStatusRefresh => 'تحديث';

  @override
  String githubStatusUpdated(String time) {
    return 'تم التحديث $time';
  }

  @override
  String get kimiStatusFetchFailed => 'تعذّر الوصول إلى status.moonshot.cn';

  @override
  String get kimiStatusOpenInBrowser => 'فتح status.moonshot.cn';

  @override
  String get openaiStatusFetchFailed => 'تعذّر الوصول إلى status.openai.com';

  @override
  String get openaiStatusOpenInBrowser => 'فتح status.openai.com';

  @override
  String get serviceStatusMaintenance => 'صيانة';

  @override
  String get serviceStatusMajorIssues => 'مشكلات كبيرة';

  @override
  String get serviceStatusMinorIssues => 'مشكلات طفيفة';

  @override
  String get serviceStatusOperational => 'يعمل بشكل طبيعي';

  @override
  String get serviceStatusOutage => 'انقطاع';

  @override
  String get serviceStatusTitle => 'حالة الخدمات';

  @override
  String get serviceStatusUnknown => 'غير معروفة';

  @override
  String lastChecked(String time) {
    return 'تم الفحص $time';
  }

  @override
  String get lastCheckedRecently => 'تم الفحص مؤخرًا';

  @override
  String get giveYourWorkAHome => 'امنح عملك موطنًا.';

  @override
  String get goBack => 'الرجوع';

  @override
  String get goForward => 'التقدّم';

  @override
  String get googleFonts => 'خطوط Google';

  @override
  String get high => 'مرتفع';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count ساعة',
      many: 'قبل $count ساعة',
      few: 'قبل $count ساعات',
      two: 'قبل ساعتين',
      one: 'قبل ساعة واحدة',
      zero: 'قبل $count ساعة',
    );
    return '$_temp0';
  }

  @override
  String get images => 'الصور';

  @override
  String get inactive => 'غير نشطة';

  @override
  String get install => 'تثبيت';

  @override
  String get installRequired => 'التثبيت مطلوب';

  @override
  String installedVersion(String version) {
    return 'الإصدار المثبّت ⁨$version⁩';
  }

  @override
  String get invite => 'دعوة';

  @override
  String get inviteAgent => 'دعوة وكيل';

  @override
  String get isolateAgentExecution => 'عزل تنفيذ الوكلاء.';

  @override
  String get justNow => 'الآن';

  @override
  String get keepSandboxing => 'الإبقاء على البيئة المعزولة';

  @override
  String get keybindingAddARepositoryDescription => 'إضافة مستودع';

  @override
  String get keybindingAddRepository => 'إضافة مستودع';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'إضافة المقال المحدد إلى الإشارات المرجعية أو إزالته منها';

  @override
  String get keybindingCommandPalette => 'لوحة الأوامر';

  @override
  String get keybindingCreateANewAgentDescription => 'إنشاء وكيل جديد';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'إنشاء مساحة عمل جديدة';

  @override
  String get keybindingFocusSearch => 'التركيز على البحث';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'التركيز على حقل البحث في طلبات السحب';

  @override
  String get keybindingNewAgent => 'وكيل جديد';

  @override
  String get keybindingNewWorkspace => 'مساحة عمل جديدة';

  @override
  String get keybindingNextArticle => 'المقال التالي';

  @override
  String get keybindingNextSpace => 'المساحة التالية';

  @override
  String get keybindingNextWorkspace => 'مساحة العمل التالية';

  @override
  String get keybindingOpenArticle => 'فتح المقال';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'فتح نافذة مبدّل مساحات العمل في الشريط الجانبي أو إغلاقها';

  @override
  String get keybindingOpenPr => 'فتح PR';

  @override
  String get keybindingOpenSettings => 'فتح الإعدادات';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'فتح إعدادات التطبيق';

  @override
  String get keybindingOpenTheCommandPaletteDescription => 'فتح لوحة الأوامر';

  @override
  String get keybindingOpenTheSelectedArticleDescription => 'فتح المقال المحدد';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'فتح طلب السحب المحدد';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'فتح مساحة العمل المحددة';

  @override
  String get keybindingOpenWorkspace => 'فتح مساحة العمل';

  @override
  String get keybindingPreviousArticle => 'المقال السابق';

  @override
  String get keybindingPreviousSpace => 'المساحة السابقة';

  @override
  String get keybindingPreviousWorkspace => 'مساحة العمل السابقة';

  @override
  String get keybindingRefresh => 'تحديث';

  @override
  String get keybindingRefreshAllFeedsDescription => 'تحديث جميع الموجزات';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'تحديث قائمة طلبات السحب';

  @override
  String get keybindingRescanForAdaptersDescription =>
      'إعادة الفحص بحثًا عن المحوّلات';

  @override
  String get keybindingSelectTheNextArticleDescription => 'تحديد المقال التالي';

  @override
  String get keybindingSelectTheNextSpaceDescription => 'تحديد المساحة التالية';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'تحديد المقال السابق';

  @override
  String get keybindingSelectThePreviousSpaceDescription =>
      'تحديد المساحة السابقة';

  @override
  String get keybindingSendMessage => 'إرسال رسالة';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'إرسال الرسالة الحالية';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'التبديل بين الوضعين الفاتح والداكن';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'التبديل إلى مساحة العمل الثامنة';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'التبديل إلى مساحة العمل الخامسة';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'التبديل إلى مساحة العمل الأولى';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'التبديل إلى مساحة العمل الرابعة';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'التبديل إلى مساحة العمل التالية';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'التبديل إلى مساحة العمل التاسعة';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'التبديل إلى مساحة العمل السابقة';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'التبديل إلى مساحة العمل الثانية';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'التبديل إلى مساحة العمل السابعة';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'التبديل إلى مساحة العمل السادسة';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'التبديل إلى مساحة العمل الثالثة';

  @override
  String get keybindingToggleBookmark => 'تبديل الإشارة المرجعية';

  @override
  String get keybindingToggleTheme => 'تبديل السمة';

  @override
  String get keybindingToggleWorkspaceSwitcher => 'تبديل مبدّل مساحات العمل';

  @override
  String get keybindingWorkspace1 => 'مساحة العمل 1';

  @override
  String get keybindingWorkspace2 => 'مساحة العمل 2';

  @override
  String get keybindingWorkspace3 => 'مساحة العمل 3';

  @override
  String get keybindingWorkspace4 => 'مساحة العمل 4';

  @override
  String get keybindingWorkspace5 => 'مساحة العمل 5';

  @override
  String get keybindingWorkspace6 => 'مساحة العمل 6';

  @override
  String get keybindingWorkspace7 => 'مساحة العمل 7';

  @override
  String get keybindingWorkspace8 => 'مساحة العمل 8';

  @override
  String get keybindingWorkspace9 => 'مساحة العمل 9';

  @override
  String get keybindings => 'اختصارات لوحة المفاتيح';

  @override
  String get keybindingsDescription =>
      'جميع اختصارات لوحة المفاتيح. الاختصارات ثابتة ولا يمكن إعادة تعيينها.';

  @override
  String get killRunning => 'إنهاء العمليات الجارية';

  @override
  String get languageSystem => 'النظام';

  @override
  String get leaveACommentEllipsis => 'اكتب تعليقًا…';

  @override
  String get legendLabel => 'وسيلة الإيضاح';

  @override
  String get lessLabel => 'أقل';

  @override
  String get letsPluginTools => 'لنوصّل أدواتك.';

  @override
  String get level => 'المستوى';

  @override
  String get loadingAgents => 'جارٍ تحميل الوكلاء…';

  @override
  String get loadingModels => 'جارٍ تحميل النماذج…';

  @override
  String get loadingProviders => 'جارٍ تحميل الموفّرين…';

  @override
  String get logLevel => 'مستوى السجل';

  @override
  String get logs => 'السجلات';

  @override
  String get low => 'منخفض';

  @override
  String get maintenance => 'الصيانة';

  @override
  String get manageParticipants => 'إدارة المشاركين';

  @override
  String get manageWorkspaces => 'إدارة مساحات العمل';

  @override
  String get reorderWorkspace => 'إعادة ترتيب مساحة العمل';

  @override
  String get matchOsAppearance =>
      'طابق مظهر نظام التشغيل لديك أو اختر وضعًا ثابتًا.';

  @override
  String get mcpAuthToken => 'رمز مصادقة MCP';

  @override
  String get mcpNotAvailableOnServer =>
      'التحكم في خادم MCP غير متوفر على الخادم المتصل.';

  @override
  String get modelManagedOnServer =>
      'يعمل هذا النموذج على مضيف الخادم وتتم إدارته هناك.';

  @override
  String get mcpServer => 'خادم MCP';

  @override
  String get medium => 'متوسط';

  @override
  String get memoryDataHint => 'ستظهر الحقائق والسياسات هنا أثناء عمل الوكلاء.';

  @override
  String get memoryLabel => 'الذاكرة';

  @override
  String get merge => 'دمج';

  @override
  String get merged => 'تم الدمج';

  @override
  String get messagePlaceholder => 'اكتب رسالة… (@ للإشارة، / للأوامر)';

  @override
  String get navConversations => 'المساحات';

  @override
  String get microphonePermissionDenied => 'تم رفض إذن الميكروفون.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count دقيقة',
      many: 'منذ $count دقيقة',
      few: 'منذ $count دقائق',
      two: 'منذ دقيقتين',
      one: 'منذ دقيقة واحدة',
      zero: 'منذ أقل من دقيقة',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'النموذج';

  @override
  String get modified => 'معدَّل';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count شهر',
      many: 'منذ $count شهرًا',
      few: 'منذ $count أشهر',
      two: 'منذ شهرين',
      one: 'منذ شهر واحد',
      zero: 'منذ أقل من شهر',
    );
    return '$_temp0';
  }

  @override
  String get moreLabel => 'المزيد';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'الاسم';

  @override
  String get nameAndTitleRequired => 'الاسم والعنوان مطلوبان.';

  @override
  String get nameAndUrlRequired => 'الاسم وعنوان URL مطلوبان';

  @override
  String get nameLabel => 'الاسم';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'البيئة المعزولة الأصلية متوفرة على ⁨$platform⁩.';
  }

  @override
  String get nativeSandboxNeedsInstall => 'يلزم تثبيت البيئة المعزولة الأصلية';

  @override
  String get navObservability => 'قابلية الملاحظة';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String networkBlockCount(int count) {
    return '$count من عمليات حظر الشبكة';
  }

  @override
  String get neutral => 'محايد';

  @override
  String get newCommitsPushed =>
      'تم دفع إيداعات جديدة — انقر لإعادة تحميل الفرق';

  @override
  String get newFact => 'حقيقة جديدة';

  @override
  String get newPolicy => 'سياسة جديدة';

  @override
  String get newsfeed => 'موجز الأخبار';

  @override
  String get newsfeedLabel => 'موجز الأخبار';

  @override
  String get newsfeedSettingsDescription =>
      'إدارة الموجزات المشترك فيها وتفضيلات القراءة.';

  @override
  String get newsfeedSettingsTitle => 'إعدادات موجز الأخبار';

  @override
  String get nextMatch => 'التطابق التالي (↵)';

  @override
  String get noActiveWorkspace => 'لا توجد مساحة عمل نشطة أو مستودع محدد.';

  @override
  String get noActiveWorkspaceCreate => 'لا توجد مساحة عمل نشطة';

  @override
  String get noActiveWorkspaceGithub =>
      'لا توجد مساحة عمل نشطة تحتوي على مستودع GitHub.';

  @override
  String get noAgents => 'لا يوجد وكلاء';

  @override
  String get noArticlesYet => 'لا توجد مقالات بعد';

  @override
  String get noArticlesYetBody => 'ستظهر مقالات موجزاتك هنا.';

  @override
  String get noExecutionLogsYet => 'لا توجد سجلات تنفيذ بعد';

  @override
  String get noFacts => 'لا توجد حقائق بعد';

  @override
  String get noFeedsYet => 'لا توجد موجزات بعد';

  @override
  String get noFileAnchor => 'لا توجد نقطة ربط بالملف — يتعذر نشر تعليق مضمّن.';

  @override
  String get noFileChangesInScope => 'لا توجد تغييرات ملفات في هذا النطاق';

  @override
  String get noGifsFound => 'لم يتم العثور على صور GIF';

  @override
  String get noInputDevicesDetected =>
      'لم يتم اكتشاف أجهزة إدخال — سيُستخدم الإعداد الافتراضي للنظام.';

  @override
  String get noMatchingFiles => 'لا توجد ملفات مطابقة';

  @override
  String get noMatchingGoogleFonts => 'لا توجد خطوط Google مطابقة.';

  @override
  String get noMemoryData => 'لا توجد بيانات ذاكرة بعد';

  @override
  String get noMessagesYet => 'لا توجد رسائل بعد';

  @override
  String get noModelsAdvertised => 'لا توجد نماذج معلنة من هذا المحوّل.';

  @override
  String get noOpenPullRequests => 'لا توجد طلبات سحب مفتوحة';

  @override
  String get noPolicies => 'لا توجد سياسات بعد';

  @override
  String get noReposInWorkspaceYet => 'لا توجد مستودعات في مساحة العمل هذه بعد';

  @override
  String get noRunnersDetected =>
      'لم يتم اكتشاف أي مشغّلات بعد. حدِّث لإجراء الفحص مرة أخرى.';

  @override
  String get noSavedArticles => 'لا توجد مقالات محفوظة';

  @override
  String get noSavedArticlesBody => 'ستظهر المقالات التي تحفظها هنا.';

  @override
  String noShortcutsMatch(String query) {
    return 'لا توجد اختصارات تطابق \"$query\"';
  }

  @override
  String get noSystemFonts => 'لم يتم اكتشاف خطوط نظام.';

  @override
  String get noTokenSet => 'لم يتم تعيين رمز وصول — الوصول غير مقيّد.';

  @override
  String get noWorkingMemory => 'لا توجد ملاحظات ذاكرة عمل بعد.';

  @override
  String get noneAllRoles => 'بلا (جميع الأدوار)';

  @override
  String get notAvailable => 'غير متوفر';

  @override
  String get notConfiguredLabel => 'غير مكوّن.';

  @override
  String get notFoundLabel => 'غير موجود';

  @override
  String get notes => 'ملاحظات';

  @override
  String get notificationAgentFinished => 'انتهى الوكيل';

  @override
  String get notificationPrMentioned => 'تمت الإشارة إليك في طلب سحب';

  @override
  String get notificationNewMessages => 'رسائل جديدة';

  @override
  String get notificationPrMerged => 'تم دمج PR';

  @override
  String get notificationPrPublished => 'تم نشر PR';

  @override
  String get notificationReviewRequested => 'تم طلب مراجعة';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get notifyAgentRunCompleted => 'الإشعار عندما يُكمل وكيل تشغيلًا.';

  @override
  String get notifyPrMentioned => 'الإشعار عند الإشارة إليك في طلب سحب.';

  @override
  String get notifyNewMessages =>
      'الإشعار عند ورود رسائل جديدة من الوكلاء في مساحات أخرى.';

  @override
  String get notifyPrMerged => 'الإشعار عند دمج طلب سحب.';

  @override
  String get notifyPrPublished => 'الإشعار عندما ينشر وكيل طلب سحب.';

  @override
  String get notifyReviewRequested => 'الإشعار عند طلب مراجعتك على طلب سحب.';

  @override
  String get notificationReviewStale => 'المراجعة لم تعد محدّثة';

  @override
  String get notifyReviewStale =>
      'عند وصول إيداعات جديدة إلى طلب سحب سبق أن راجعته';

  @override
  String get notificationPrMergeReadiness => 'جاهز للدمج';

  @override
  String get notifyPrMergeReadiness =>
      'الإشعار عندما يصبح طلب سحب أنشأته قابلًا للدمج أو يتوقف عن ذلك.';

  @override
  String get notificationPrReviewDecision => 'قرارات المراجعة';

  @override
  String get notifyPrReviewDecision =>
      'الإشعار عندما يوافق مراجع أو يطلب تغييرات أو تُلغى موافقته.';

  @override
  String get notificationPrChecksStatus => 'الفحوصات';

  @override
  String get notifyPrChecksStatus =>
      'الإشعار عند فشل CI على طلب سحب أنشأته، وعند تعافيه.';

  @override
  String get notificationPrThreadActivity => 'سلاسل المراجعة';

  @override
  String get notifyPrThreadActivity =>
      'الإشعار عندما يرد شخص ما في سلسلة تشارك فيها أو يقوم بحلها.';

  @override
  String get notificationPrReadyToMerge => 'جاهز للدمج';

  @override
  String notificationPrReadyToMergeBody(String prTitle) {
    return '$prTitle لديه كل ما يلزم.';
  }

  @override
  String get notificationPrMergeBlocked => 'لم يعد قابلًا للدمج';

  @override
  String notificationPrMergeBlockedBodyConflicts(String prTitle) {
    return '$prTitle يتعارض مع الفرع الأساسي.';
  }

  @override
  String notificationPrMergeBlockedBodyBehind(String prTitle) {
    return '$prTitle متأخر عن الفرع الأساسي.';
  }

  @override
  String notificationPrMergeBlockedBodyReviews(String prTitle) {
    return '$prTitle في انتظار مراجعة مطلوبة.';
  }

  @override
  String notificationPrMergeBlockedBodyChanges(String prTitle) {
    return 'طلب أحد المراجعين تغييرات على $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyChecks(String prTitle) {
    return 'الفحوصات تفشل على $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyOther(String prTitle) {
    return 'لم يعد بالإمكان دمج $prTitle.';
  }

  @override
  String get notificationPrApproved => 'تمت الموافقة على طلب السحب';

  @override
  String notificationPrApprovedBodyBy(String login, String prTitle) {
    return 'وافق ⁨$login⁩ على $prTitle';
  }

  @override
  String notificationPrApprovedBody(String prTitle) {
    return 'تمت الموافقة على $prTitle';
  }

  @override
  String notificationPrReviewersRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مراجع لم يردوا بعد',
      many: '$count مراجعًا لم يردوا بعد',
      few: '$count مراجعين لم يردوا بعد',
      two: 'مراجعان لم يردا بعد',
      one: 'مراجع واحد لم يرد بعد',
      zero: 'لم يتبق أي مراجع',
    );
    return '$_temp0';
  }

  @override
  String get notificationPrChangesRequested => 'طُلبت تغييرات';

  @override
  String notificationPrChangesRequestedBodyBy(String login, String prTitle) {
    return 'طلب ⁨$login⁩ تغييرات على $prTitle';
  }

  @override
  String notificationPrChangesRequestedBody(String prTitle) {
    return 'طُلبت تغييرات على $prTitle';
  }

  @override
  String get notificationPrReviewDismissed => 'تم إلغاء الموافقة';

  @override
  String notificationPrReviewDismissedBody(String prTitle) {
    return '$prTitle يحتاج إلى مراجعة مرة أخرى.';
  }

  @override
  String get notificationPrChecksFailed => 'فشلت الفحوصات';

  @override
  String notificationPrChecksFailedBody(String checkName, String prTitle) {
    return 'فشل ⁨$checkName⁩ على $prTitle';
  }

  @override
  String notificationPrChecksFailedBodyUnnamed(String prTitle) {
    return 'الفحوصات تفشل على $prTitle';
  }

  @override
  String get notificationPrChecksRecovered => 'الفحوصات تنجح';

  @override
  String notificationPrChecksRecoveredBody(String prTitle) {
    return 'اجتاز $prTitle الفحوصات من جديد.';
  }

  @override
  String notificationPrMentionedInCommentBody(String login, String location) {
    return 'أشار ⁨$login⁩ إليك في $location';
  }

  @override
  String get notificationPrThreadReplied => 'رد جديد';

  @override
  String notificationPrThreadRepliedBody(String login, String location) {
    return 'رد ⁨$login⁩ في $location';
  }

  @override
  String get notificationPrThreadResolved => 'تم حل السلسلة';

  @override
  String notificationPrThreadResolvedBody(String location) {
    return 'تم حل سلسلتك في $location.';
  }

  @override
  String get notificationGroupAgents => 'الوكلاء';

  @override
  String get notificationGroupPullRequests => 'طلبات السحب';

  @override
  String get notificationGroupMessages => 'الرسائل';

  @override
  String get notificationGroupTickets => 'التذاكر';

  @override
  String get notificationGroupCalendar => 'التقويم';

  @override
  String get notificationGroupMachines => 'الآلات';

  @override
  String get notificationsMutedRepos => 'المستودعات المكتومة';

  @override
  String notificationsMutedReposCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مستودع مكتوم',
      many: '$count مستودعًا مكتومًا',
      few: '$count مستودعات مكتومة',
      two: 'مستودعان مكتومان',
      one: 'مستودع واحد مكتوم',
      zero: 'لا توجد مستودعات مكتومة',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMuteRepo => 'كتم هذا المستودع';

  @override
  String get onboardingLinuxDescription =>
      'يمكن لـ Control Center استخدام حاويات Linux لعزل تنفيذ الوكلاء.';

  @override
  String get onboardingMacosDescription =>
      'يستخدم Control Center البيئة المعزولة الأصلية على macOS لعزل تنفيذ الوكلاء.';

  @override
  String get onboardingUnsupportedDescription =>
      'البيئة المعزولة غير متوفرة على هذا النظام الأساسي. سيعمل تنفيذ الوكلاء دون عزل.';

  @override
  String get openArticlesInApp => 'فتح المقالات داخل التطبيق';

  @override
  String get openInBrowser => 'فتح في المتصفح';

  @override
  String get openedInYourBrowser => 'فُتح في متصفحك.';

  @override
  String get openLabel => 'فتح';

  @override
  String get openOnGithub => 'فتح على GitHub';

  @override
  String get openStatus => 'مفتوح';

  @override
  String get optionalPersonaDescription => 'وصف اختياري للشخصية';

  @override
  String get otherLabel => 'أخرى';

  @override
  String get ownerOrganization => 'المالك / المؤسسة';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get passed => 'ناجح';

  @override
  String get pasteValueHere => 'الصق القيمة هنا';

  @override
  String get persona => 'الشخصية';

  @override
  String get policies => 'السياسات';

  @override
  String get policiesHint => 'ستظهر السياسات هنا عندما يرقّي الوكلاء الحقائق.';

  @override
  String get policy => 'سياسة';

  @override
  String get popular => 'شائع';

  @override
  String get port => 'المنفذ';

  @override
  String get postingEllipsis => 'جارٍ النشر…';

  @override
  String get prCommits => 'الإيداعات';

  @override
  String get prMergedBody => 'تم دمج طلب سحب';

  @override
  String get prMoreActions => 'مزيد من الإجراءات';

  @override
  String get prTitle => 'عنوان PR';

  @override
  String get reviewCommentHint =>
      'انقر على الموافقة ببساطة، أو أضف تعليقًا أو تفاعلًا إن كنت تشعر بالحماس…';

  @override
  String get nothingToPreview => 'لا شيء للمعاينة';

  @override
  String get previousMatch => 'التطابق السابق (⇧↵)';

  @override
  String get priorityReviewsDescription =>
      'المراجعات ذات الأولوية ونظرة عامة على المستودع.';

  @override
  String get prsCreated => 'PRs المُنشأة';

  @override
  String get prsMerged => 'PRs المدموجة';

  @override
  String get publishToGithub => 'النشر على GitHub';

  @override
  String get published => 'منشور';

  @override
  String get pullRequestApproved => 'تمت الموافقة على طلب السحب';

  @override
  String get pullRequests => 'طلبات السحب';

  @override
  String get questionLabel => 'سؤال';

  @override
  String get queued => 'في قائمة الانتظار';

  @override
  String get react => 'تفاعل';

  @override
  String get readPrsIssuesMetadata =>
      'يتيح للوكيل قراءة PRs والمشكلات والبيانات الوصفية للمستودع.';

  @override
  String get readerPreferences => 'تفضيلات القراءة';

  @override
  String get reasoningEffort => 'جهد الاستدلال';

  @override
  String get recommendLabel => 'توصية';

  @override
  String recordingFromDevice(String device) {
    return 'جارٍ التسجيل من $device.';
  }

  @override
  String get redownload => 'إعادة التنزيل';

  @override
  String get redownloadEmbeddingModel => 'هل تريد إعادة تنزيل نموذج التضمين؟';

  @override
  String get redownloadVoiceModel => 'هل تريد إعادة تنزيل نموذج الصوت؟';

  @override
  String get refinePlan => 'تحسين الخطة';

  @override
  String get refresh => 'تحديث';

  @override
  String get refreshAll => 'تحديث الكل';

  @override
  String get refreshAllFeeds => 'تحديث جميع الموجزات';

  @override
  String get reject => 'رفض';

  @override
  String get rejected => 'مرفوض';

  @override
  String get reload => 'إعادة التحميل';

  @override
  String get remove => 'إزالة';

  @override
  String get removeBookmark => 'إزالة الإشارة المرجعية';

  @override
  String get removeEmbeddingModel => 'هل تريد إزالة نموذج التضمين؟';

  @override
  String get removeLogo => 'إزالة الشعار';

  @override
  String get removeRepoFromWorkspace =>
      'هل تريد إزالة المستودع من مساحة العمل؟';

  @override
  String get removeVoiceModel => 'هل تريد إزالة نموذج الصوت؟';

  @override
  String get removed => 'مُزال';

  @override
  String get renamed => 'أُعيدت تسميته';

  @override
  String get reopen => 'إعادة الفتح';

  @override
  String get resolve => 'حل';

  @override
  String get replyEllipsis => 'رد…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return 'ستتم إزالة ⁨$name⁩ من مساحة العمل هذه. لن تُمسّ الملفات المحلية على القرص.';
  }

  @override
  String repoAccessNoticeBody(String repos) {
    return 'بيانات اعتماد GitHub الخاصة بالخادم لا يمكنها رؤية ⁨$repos⁩. إذا كان مستودع ما يتبع مؤسسة، فثبّت تطبيق GitHub هناك أو اربط رمز وصول لديه صلاحية الوصول.';
  }

  @override
  String repoAccessNoticeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يتعذر الوصول إلى $count مستودع',
      many: 'يتعذر الوصول إلى $count مستودعًا',
      few: 'يتعذر الوصول إلى $count مستودعات',
      two: 'يتعذر الوصول إلى مستودعين',
      one: 'يتعذر الوصول إلى مستودع واحد',
      zero: 'لا توجد مستودعات يتعذر الوصول إليها',
    );
    return '$_temp0';
  }

  @override
  String get repoAccessNoticeSuspendedTitle => 'تم تعليق تثبيت GitHub App';

  @override
  String repoAccessNoticeSuspendedBody(String repos) {
    return 'يتم عرض آخر بيانات معروفة لـ ⁨$repos⁩. استأنف التثبيت على GitHub، أو اربط رمز وصول لديه صلاحية الوصول.';
  }

  @override
  String get repoNoAccessBadge => 'بلا وصول';

  @override
  String get reportsTo => 'يتبع لـ';

  @override
  String reposCount(int count) {
    return 'المستودعات ($count)';
  }

  @override
  String get reposDescription => 'النسخ المحلية التي تستهدفها مساحة العمل هذه.';

  @override
  String get repositories => 'المستودعات';

  @override
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مستودع',
      many: '$count مستودعًا',
      few: '$count مستودعات',
      two: 'مستودعين',
      one: 'مستودع واحد',
      zero: 'أي مستودع',
    );
    return 'تعذّرت إضافة $_temp0: ⁨$error⁩';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تمت إضافة $count مستودع',
      many: 'تمت إضافة $count مستودعًا',
      few: 'تمت إضافة $count مستودعات',
      two: 'تمت إضافة مستودعين',
      one: 'تمت إضافة مستودع واحد',
      zero: 'لم تتم إضافة أي مستودع',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => 'إعدادات المستودعات';

  @override
  String get repositoryName => 'اسم المستودع';

  @override
  String get requestChanges => 'طلب تغييرات';

  @override
  String get requested => 'مطلوب';

  @override
  String get requestedChanges => 'طُلبت تغييرات';

  @override
  String requiredRoleLabel(String role) {
    return 'الدور المطلوب: $role';
  }

  @override
  String get requiredRoleOptional => 'الدور المطلوب (اختياري)';

  @override
  String get requirements => 'المتطلبات';

  @override
  String get reset => 'إعادة التعيين';

  @override
  String get resolved => 'تم الحل';

  @override
  String get enclosedTerminalTitle => 'طرفية داخل حاوية معزولة';

  @override
  String get enclosedTerminalStart => 'فتح الصدفة';

  @override
  String get enclosedTerminalStartHint =>
      'تعمل هذه الصدفة داخل جهاز VM المؤقت الخاص بهذه المحادثة. يبدأ تشغيله عند فتحها، لا عند بدء التطبيق.';

  @override
  String get terminalStreamReconnecting => 'انقطع البث — جارٍ إعادة الاتصال…';

  @override
  String get terminalStreamError => 'خطأ في البث:';

  @override
  String get terminalShellExited => 'انتهت الصدفة';

  @override
  String get restartShell => 'إعادة تشغيل الصدفة';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get review => 'مراجعة';

  @override
  String get reviewedByMe => 'تمت مراجعتها بواسطتي';

  @override
  String get reviewers => 'المراجعون';

  @override
  String get roleLabel => 'الدور';

  @override
  String get ruleHint => 'قاعدة السياسة (يدعم Markdown)';

  @override
  String get ruleLabel => 'القاعدة';

  @override
  String get runCompleted => 'اكتمل التشغيل';

  @override
  String get running => 'قيد التشغيل';

  @override
  String get runningLabel => 'قيد التشغيل';

  @override
  String get runs => 'عمليات التشغيل';

  @override
  String get runsLabel => 'عمليات التشغيل';

  @override
  String get sandboxBackendNativeLabel => 'بيئة معزولة أصلية';

  @override
  String get sandboxBackendMicrovmLabel => 'جهاز VM في حاوية معزولة';

  @override
  String get sandboxBackendNoneLabel => 'بلا عزل';

  @override
  String get sandboxLinuxInstall =>
      'تستخدم البيئة المعزولة الأصلية على Linux/WSL2 أداة bubblewrap. ثبّتها باستخدام:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'البيئة المعزولة الأصلية مضمّنة في macOS - تستخدم Apple Seatbelt (`sandbox-exec`). لا يلزم أي تثبيت.';

  @override
  String get sandboxPermissions => 'أذونات البيئة المعزولة';

  @override
  String get sandboxUnsupported =>
      'البيئة المعزولة الأصلية غير مدعومة على هذا النظام الأساسي بعد. يتم الرجوع إلى \"بلا عزل\".';

  @override
  String get sandboxingDisabledDescription =>
      'يعمل الوكلاء مباشرة على المضيف مع البيئة الكاملة - غير مستحسن.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'تمر جميع استدعاءات الوكلاء عبر $backend.';
  }

  @override
  String get save => 'حفظ';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get adapterArguments => 'وسائط إضافية';

  @override
  String get adapterArgumentsHint => 'علامات CLI إضافية (مثل ⁨--yolo⁩)';

  @override
  String get addVariable => 'إضافة متغير';

  @override
  String get environmentVariables => 'متغيرات البيئة';

  @override
  String get environmentVariablesDescription =>
      'متغيرات بيئة مخصصة تُمرَّر إلى هذا المحوّل (مثل مفاتيح API). تُخزَّن في سلسلة المفاتيح.';

  @override
  String get variableKey => 'المفتاح';

  @override
  String get variableValue => 'القيمة';

  @override
  String get savingEllipsis => 'جارٍ الحفظ…';

  @override
  String get scopeDiffToCommits =>
      'حصر الفرق في إيداعات محددة — انقر مع الضغط على Shift لتحديد نطاق';

  @override
  String get noPrsMatchSearch => 'لا توجد طلبات سحب مطابقة';

  @override
  String get searchFactsHint => 'البحث في الحقائق...';

  @override
  String get searchFonts => 'البحث في الخطوط…';

  @override
  String get searchGifs => 'البحث عن صور GIF';

  @override
  String get searchGifsHint => 'البحث عن صور GIF...';

  @override
  String get searchInDiffHint => 'البحث في الفرق…';

  @override
  String get searchOrTypeModel => 'ابحث أو اكتب اسم نموذج…';

  @override
  String get searchPlaceholder => 'بحث…';

  @override
  String get searchShortcuts => 'البحث في الاختصارات…';

  @override
  String get shortcutUnavailableInBrowser => 'غير متوفر في المتصفح';

  @override
  String get searching => 'جارٍ البحث…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count ثانية',
      many: 'منذ $count ثانية',
      few: 'منذ $count ثوانٍ',
      two: 'منذ ثانيتين',
      one: 'منذ ثانية واحدة',
      zero: 'منذ أقل من ثانية',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'تحديد المحوّل';

  @override
  String get selectAdapterFirst => 'حدد محوّلًا أولًا';

  @override
  String get selectAgentToReportTo => 'حدد الوكيل الذي يتبع له…';

  @override
  String get selectAnAgent => 'حدد وكيلًا';

  @override
  String get selectConversation => 'حدد محادثة';

  @override
  String get selectLabel => 'تحديد';

  @override
  String get selectRunner => 'حدد مشغّلًا';

  @override
  String get semanticSearch => 'البحث الدلالي';

  @override
  String get send => 'إرسال';

  @override
  String get sendFirstMessage => 'أرسل الرسالة الأولى';

  @override
  String get sendMessage => 'إرسال رسالة';

  @override
  String sentFindingsToAgent(int count) {
    return 'تم إرسال $count من النتائج إلى الوكيل.';
  }

  @override
  String setGithubLinkDescription(String name) {
    return 'عيّن مالك GitHub واسم المستودع لـ ⁨$name⁩. يُستخدم هذا لحل مراجع PR والمشكلات مثل #123 في محتوى Markdown.';
  }

  @override
  String get setLabel => 'تعيين';

  @override
  String get setToken => 'تعيين رمز الوصول';

  @override
  String get settingsLabel => 'الإعدادات';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsLanguageDescription => 'اختر لغة التطبيق.';

  @override
  String get shortTask => 'مهمة قصيرة';

  @override
  String get showNativeNotifications => 'عرض إشعارات النظام للأحداث.';

  @override
  String get showSuperseded => 'عرض المستبدَلة';

  @override
  String get signedIn => 'تم تسجيل الدخول.';

  @override
  String signedInAs(String username) {
    return 'تم تسجيل الدخول باسم ⁨$username⁩.';
  }

  @override
  String get skillNameRequired => 'اسم المهارة مطلوب.';

  @override
  String skillSaved(String name) {
    return 'تم حفظ المهارة \"⁨$name⁩\".';
  }

  @override
  String get skillsSourcesTab => 'المصادر';

  @override
  String get skillSourcesDisclaimer =>
      'تُثبَّت المهارات من مستودعات GitHub التي تضيفها. البيانات الوصفية للمستودع غير موثوقة — فحص مكافحة الفيروسات هو إشارة الأمان الحقيقية.';

  @override
  String get skillSourcesEmpty => 'لا توجد مستودعات مهارات';

  @override
  String get skillSourcesEmptyHint => 'أضف مستودع GitHub لتصفح مهاراته.';

  @override
  String get skillSourceAdd => 'إضافة مستودع';

  @override
  String get skillSourceAddTitle => 'إضافة مستودع مهارات';

  @override
  String get skillSourceAddHint => 'https://github.com/owner/repo';

  @override
  String get skillSourceInvalidUrl =>
      'أدخل عنوان URL لمستودع GitHub (⁨https://github.com/owner/repo⁩).';

  @override
  String skillSourceAdded(String repo) {
    return 'تمت إضافة المستودع ⁨$repo⁩.';
  }

  @override
  String skillSourceAlreadyAdded(String repo) {
    return 'المستودع ⁨$repo⁩ مضاف بالفعل.';
  }

  @override
  String skillSourceRemoved(String repo) {
    return 'تمت إزالة المستودع ⁨$repo⁩.';
  }

  @override
  String get skillSourceRemove => 'إزالة';

  @override
  String skillSourceRemoveConfirmTitle(String repo) {
    return 'هل تريد إزالة ⁨$repo⁩؟';
  }

  @override
  String get skillSourceRemoveConfirmBody =>
      'تبقى المهارات المثبتة مثبتة. تتم إزالة كتالوج المستودع فقط.';

  @override
  String get skillSourceNoSkills =>
      'لم يُعثر على مهارات في هذا المستودع (المهارة هي دليل يحتوي على SKILL.md).';

  @override
  String get skillSourceRefresh => 'تحديث';

  @override
  String get skillSourceInstalledBadge => 'مثبتة';

  @override
  String get skillSourceUpdateBadge => 'يتوفر تحديث';

  @override
  String get skillSourceSlugTaken => 'الاسم مستخدم';

  @override
  String skillSourceFilesCount(num count) {
    return '$count من الملفات';
  }

  @override
  String get skillSourceReadme => 'README';

  @override
  String get skillSourceNoReadme => 'لا يوجد README لهذه المهارة.';

  @override
  String get skillSourceNoMatches => 'لا توجد مهارات تطابق عامل التصفية.';

  @override
  String get skillUpdateAction => 'تحديث';

  @override
  String get skillUninstallAction => 'إلغاء التثبيت';

  @override
  String skillUninstallConfirmTitle(String slug) {
    return 'هل تريد إلغاء تثبيت \"⁨$slug⁩\"؟';
  }

  @override
  String skillUninstalled(String slug) {
    return 'تم إلغاء تثبيت المهارة \"⁨$slug⁩\".';
  }

  @override
  String get skillFindingLine => 'السطر';

  @override
  String get skillInstallAnywayOverride => 'أفهم المخاطرة — التثبيت على أي حال';

  @override
  String skillInstalled(String slug) {
    return 'تم تثبيت المهارة \"⁨$slug⁩\".';
  }

  @override
  String get skillPreviewCapabilities => 'القدرات';

  @override
  String get skillPreviewFindings => 'النتائج';

  @override
  String get skillPreviewGuardedActions => 'الإجراءات المحمية';

  @override
  String get skillPreviewLlmReviewed => 'تمت مراجعتها بواسطة LLM';

  @override
  String get skillPreviewNoCapabilities => 'لم يتم الإعلان عن أي قدرات.';

  @override
  String get skillPreviewNoFindings => 'لا توجد نتائج.';

  @override
  String get skillPreviewScanning => 'جارٍ فحص المهارة…';

  @override
  String get skillPreviewVerdictLabel => 'نتيجة الفحص';

  @override
  String get skillPreviewVerdictPass => 'ناجح';

  @override
  String get skillPreviewVerdictQuarantine => 'محجورة';

  @override
  String get skillPreviewVerdictWarn => 'تحذير';

  @override
  String get skillQuarantineWarning =>
      'حجر الماسح هذه المهارة. تثبيتها يشغّل تعليمات برمجية على جهازك. تابع فقط إذا كنت تثق بالمصدر وراجعت النتائج.';

  @override
  String skillDetachedFromAgents(String agents) {
    return 'تم الحجر والفصل عن الوكلاء: $agents';
  }

  @override
  String get skillNotScanned => 'لم تُفحص';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => 'يدوي';

  @override
  String get skillOriginRegistry => 'السجل';

  @override
  String get skillOriginRuntimeLocal => 'محلي في وقت التشغيل';

  @override
  String get skillRulesStale => 'الفحص قديم';

  @override
  String get skillSaveAnywayOverride => 'أفهم المخاطرة — الحفظ على أي حال';

  @override
  String get skillSaveBlockedBody => 'تم حظر المحتوى قبل كتابة أي شيء.';

  @override
  String get skillSaveBlockedTitle => 'تم حظر الحفظ بواسطة بوابة الفحص';

  @override
  String get skillScanAction => 'فحص';

  @override
  String get skillScanAll => 'فحص الكل';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass ناجحة · $warn تحذيرات · $quarantine محجورة';
  }

  @override
  String get skillStateDrifted => 'معدَّلة منذ التثبيت';

  @override
  String get skillStateUnmanaged => 'غير مُدارة';

  @override
  String get skillSeverityBlocked => 'محظور';

  @override
  String get skillSeverityWarn => 'تحذير';

  @override
  String get skillsInstalledTab => 'المثبتة';

  @override
  String get skills => 'المهارات';

  @override
  String get skipAcceptRisk => 'تخطي — أقبل المخاطرة';

  @override
  String get skipForNow => 'التخطي الآن';

  @override
  String get skipSandboxing => 'تخطي البيئة المعزولة';

  @override
  String get skipSandboxingDialogContent =>
      'هل أنت متأكد من رغبتك في تخطي البيئة المعزولة؟ سيتيح هذا للوكلاء تنفيذ تعليمات برمجية على نظامك دون عزل.';

  @override
  String get somethingWentWrong => 'حدث خطأ ما';

  @override
  String sourceCount(int count) {
    return '$count مصدر';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count مصادر';
  }

  @override
  String get sourceFacts => 'الحقائق المصدرية:';

  @override
  String get splitDiff => 'فرق مقسّم (جنبًا إلى جنب)';

  @override
  String get startLabel => 'بدء';

  @override
  String get startOnAppLaunch => 'البدء عند تشغيل التطبيق';

  @override
  String get statusLabel => 'الحالة';

  @override
  String get onboardingStepConnect => 'الاتصال';

  @override
  String get onboardingStepWorkspace => 'مساحة العمل';

  @override
  String get onboardingStepSandbox => 'البيئة المعزولة';

  @override
  String get onboardingStepAdapter => 'المحوّل';

  @override
  String get onboardingStepVoice => 'الصوت';

  @override
  String get stop => 'إيقاف';

  @override
  String get stopped => 'متوقف';

  @override
  String get strictIdentityCheck => 'التحقق الصارم من الهوية';

  @override
  String get success => 'نجاح';

  @override
  String get successLabel => 'نجاح';

  @override
  String get suggestAChange => 'اقتراح تغيير';

  @override
  String get suggestLabel => 'اقتراح';

  @override
  String get superseded => 'مستبدَل';

  @override
  String get synced => 'متزامن';

  @override
  String get systemDefault => 'الافتراضي للنظام';

  @override
  String get systemFonts => 'خطوط النظام';

  @override
  String get systemPrompt => 'موجّه النظام';

  @override
  String get systemPromptLabel => 'موجّه النظام';

  @override
  String get talkToControlCenter => 'تحدث إلى Control Center.';

  @override
  String get taskMentionSection => 'المهمة';

  @override
  String get testLabel => 'اختبار';

  @override
  String get theme => 'السمة';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeSystem => 'النظام';

  @override
  String get thisCannotBeUndone => 'لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get ticketLabel => 'تذكرة';

  @override
  String get titleLabel => 'العنوان';

  @override
  String get todayLabel => 'اليوم';

  @override
  String get toggleTheme => 'تبديل السمة';

  @override
  String get tokenConfigured =>
      'تم التكوين — يجب على العملاء تقديم رمز الوصول هذا.';

  @override
  String get topic => 'الموضوع';

  @override
  String get topicHint => 'مثل: حزمة التقنيات، نظام التصميم';

  @override
  String get totalRuns => 'إجمالي عمليات التشغيل';

  @override
  String trackingParamsCount(int count) {
    return '$count من معلمات التتبع';
  }

  @override
  String get typeCommandOrSearch => 'اكتب أمرًا أو ابحث…';

  @override
  String get typography => 'الطباعة';

  @override
  String get unavailable => 'غير متوفر';

  @override
  String get unifiedDiff => 'فرق موحّد';

  @override
  String get unknownAuthor => 'غير معروف';

  @override
  String get unnamedAgent => 'وكيل بلا اسم';

  @override
  String get updateKey => 'تحديث المفتاح';

  @override
  String get updateLabel => 'تحديث';

  @override
  String get updateToken => 'تحديث رمز الوصول';

  @override
  String updatedDaysAgo(int count) {
    return 'حُدّث قبل $count يوم';
  }

  @override
  String updatedHoursAgo(int count) {
    return 'حُدّث قبل $count ساعة';
  }

  @override
  String get updatedJustNow => 'حُدّث للتو';

  @override
  String updatedMinutesAgo(int count) {
    return 'حُدّث قبل $count دقيقة';
  }

  @override
  String get useSandbox => 'استخدام البيئة المعزولة';

  @override
  String get useWorkspaceDefault => 'استخدام إعداد مساحة العمل الافتراضي';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      'اتركه فارغًا لاستخدام User-Agent الافتراضي للتطبيق. بعض المواقع تحظر قيم User-Agent غير الصادرة عن متصفح.';

  @override
  String get usingSystemDefaultMicrophone =>
      'يُستخدم ميكروفون النظام الافتراضي.';

  @override
  String get viewLabel => 'عرض';

  @override
  String get viewLogs => 'عرض السجلات';

  @override
  String voiceInstallFailed(String error) {
    return 'فشل التثبيت: ⁨$error⁩';
  }

  @override
  String get voiceModelNotInstalled =>
      'غير مثبّت. يُنزّل نحو 200 ميغابايت مرة واحدة؛ ويعمل بالكامل على الجهاز.';

  @override
  String get voiceModelNotInstalledLabel => 'نموذج الصوت غير مثبّت.';

  @override
  String get voiceRedownloadBody =>
      'ستُحذف ملفات النموذج الحالية ويُنزَّل الأرشيف البالغ نحو 200 ميغابايت من جديد. لن يتوفر النسخ الصوتي حتى يكتمل التنزيل.';

  @override
  String get voiceRemoveBody =>
      'سيُعطَّل النسخ الصوتي حتى تعيد تثبيته. يمكنك تثبيته مجددًا في أي وقت.';

  @override
  String get voiceTranscription => 'النسخ الصوتي';

  @override
  String get weakIsolationDescription =>
      'عزل ضعيف — حدود مساحة الأسماء فقط، دون حدود على مستوى النواة.';

  @override
  String get whenOffNoDefaultRoute =>
      'عند إيقافه، تُقلع البيئة المعزولة دون مسار افتراضي.';

  @override
  String get whenOffServerStaysStopped =>
      'عند إيقافه، يبقى الخادم متوقفًا حتى تشغّله.';

  @override
  String get speechModel => 'نموذج الكلام';

  @override
  String get speechModelHint =>
      'يُستخدم لنسخ الاجتماعات وميكروفون حقل الكتابة.';

  @override
  String get voiceModelInstalled =>
      'مثبّت. يشغّل نسخ الاجتماعات وزر الميكروفون في حقل الكتابة.';

  @override
  String get meetingMicSilentWarning =>
      'قد يكون الميكروفون مكتومًا — الآخرون يتحدثون لكن لا شيء يصل إلى الميكروفون.';

  @override
  String get meetingSummaryPrivacyNotice =>
      'يبقى التسجيل والنسخ على هذا الجهاز. يكتب الملخصَ وكيل، فإذا استخدم نموذجًا سحابيًا أُرسل النص المفرّغ وملاحظاتك إلى ذلك المزوّد.';

  @override
  String get meetingTemplates => 'قوالب ملاحظات الاجتماع';

  @override
  String get meetingTemplatesHint =>
      'شكّل ملخص الذكاء الاصطناعي لنوع معيّن من الاجتماعات. يُطبَّق القالب النشط على الملخصات الجديدة والمعاد توليدها.';

  @override
  String get meetingTemplateActive => 'القالب النشط';

  @override
  String get meetingTemplateAdd => 'إضافة قالب';

  @override
  String get meetingTemplateNewTitle => 'قالب جديد';

  @override
  String get meetingTemplateEditTitle => 'تعديل القالب';

  @override
  String get meetingTemplateNameLabel => 'الاسم';

  @override
  String get meetingTemplateNameHint => 'مثال: مراجعة السبرنت';

  @override
  String get meetingTemplateInstructionsLabel => 'التعليمات';

  @override
  String get meetingTemplateInstructionsHint =>
      'كيف ينبغي للذكاء الاصطناعي هيكلة هذه الملاحظات وما الذي يبرزه فيها؟';

  @override
  String get workingMemory => 'الذاكرة العاملة';

  @override
  String get workspaceName => 'اسم مساحة العمل';

  @override
  String get workspaceScopedSkills =>
      'ملفات مهارات على نطاق مساحة العمل مرفقة بالوكلاء.';

  @override
  String get workspaces => 'مساحات العمل';

  @override
  String get writePrivateNotes => 'اكتب ملاحظات خاصة ومشاهدات وخططًا...';

  @override
  String get writeSkillContent => 'اكتب محتوى مهارتك هنا (Markdown)…';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count سنة',
      many: 'قبل $count سنة',
      few: 'قبل $count سنوات',
      two: 'قبل سنتين',
      one: 'قبل سنة واحدة',
      zero: 'قبل $count سنة',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'أمس';

  @override
  String get focusModeStart => 'بدء جلسة تركيز';

  @override
  String get focusModeConfigTitle => 'بدء جلسة تركيز';

  @override
  String get focusModeGoalLabel => 'الهدف';

  @override
  String get focusModeGoalHint => 'على ماذا تعمل؟';

  @override
  String get focusModeDurationLabel => 'المدة';

  @override
  String get focusModeBlockNotifications => 'حظر الإشعارات';

  @override
  String get focusModeStartButton => 'بدء';

  @override
  String get focusModeFloat => 'تصغير إلى الشريط';

  @override
  String get focusModeActiveTooltip => 'وضع التركيز نشط — انقر للإنهاء';

  @override
  String get dismiss => 'تجاهل';

  @override
  String get acceptAndResolve => 'قبول وحل';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'أنت تراجع منذ $minutes دقيقة — تشير الأبحاث إلى أن جودة المراجعة قد تتراجع بعد 60 دقيقة. فكّر في أخذ استراحة.';
  }

  @override
  String get notificationSound => 'صوت الإشعار';

  @override
  String get notificationSoundDescription =>
      'الصوت الذي يُشغَّل عند ظهور إشعار.';

  @override
  String get notificationSoundNone => 'بلا';

  @override
  String get notificationSoundPing => 'بينغ';

  @override
  String get notificationSoundChime => 'رنين';

  @override
  String get notificationSoundPop => 'بوب';

  @override
  String get notificationSoundDing => 'دينغ';

  @override
  String get notificationSoundWhoosh => 'ووش';

  @override
  String get notificationSoundMigrosSoft => 'Migros (ناعم)';

  @override
  String get notificationSoundMigrosHard => 'Migros (حاد)';

  @override
  String get notificationSoundSbb => 'SBB';

  @override
  String get notificationSoundCff => 'CFF';

  @override
  String get notificationSoundFfs => 'FFS';

  @override
  String get notificationSoundPost => 'Post';

  @override
  String get notificationSoundTest => 'تجربة';

  @override
  String get notificationVolume => 'مستوى الصوت';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'لا توجد طلبات سحب من ⁨@$login⁩ في مساحة العمل هذه';
  }

  @override
  String get usersLabel => 'المستخدمون';

  @override
  String get mergePullRequest => 'دمج طلب السحب';

  @override
  String get forceMergePullRequest => 'دمج طلب السحب قسرًا';

  @override
  String get closePullRequest => 'إغلاق طلب السحب';

  @override
  String get closePullRequestConfirm =>
      'هل أنت متأكد من رغبتك في إغلاق طلب السحب هذا؟';

  @override
  String get stackedPullRequests => 'طلبات سحب مكدّسة';

  @override
  String partOfStack(int position, int total) {
    return 'جزء من مكدس ($position من $total)';
  }

  @override
  String get createStack => 'إنشاء مكدس';

  @override
  String get createStackDialogTitle => 'إنشاء مكدس طلبات سحب';

  @override
  String createStackDialogBody(int count) {
    return 'سيتم تكديس $count من طلبات السحب هذه، من الأسفل إلى الأعلى:';
  }

  @override
  String get createStackInvalidSelection =>
      'حدد طلبَي سحب على الأقل من المستودع نفسه لإنشاء مكدس';

  @override
  String get createStackNotAChain =>
      'طلبات السحب المحددة لا تشكّل سلسلة: يجب أن يكون الفرع الأساسي لكل طلب سحب هو الفرع المصدر للطلب الذي قبله';

  @override
  String get createStackAlreadyStacked =>
      'واحد أو أكثر من طلبات السحب المحددة موجود في مكدس بالفعل';

  @override
  String get stackCreated => 'تم إنشاء المكدس';

  @override
  String get stackCreationFailed => 'تعذّر إنشاء المكدس';

  @override
  String get squashAndMerge => 'سحق ودمج';

  @override
  String get createMergeCommit => 'إنشاء إيداع دمج';

  @override
  String get rebaseAndMerge => 'إعادة تأسيس ودمج';

  @override
  String get commitTitle => 'عنوان الإيداع';

  @override
  String get commitDescription => 'وصف الإيداع';

  @override
  String get pullRequestMerged => 'تم دمج طلب السحب';

  @override
  String get pullRequestClosed => 'تم إغلاق طلب السحب';

  @override
  String failedToMergePr(String error) {
    return 'فشل الدمج: ⁨$error⁩';
  }

  @override
  String failedToClosePr(String error) {
    return 'فشل الإغلاق: ⁨$error⁩';
  }

  @override
  String get markReadyForReview => 'جاهز للمراجعة';

  @override
  String get markReadyForReviewConfirm =>
      'سيخرج طلب السحب هذا من وضع المسودة. سيُخطَر المراجعون، وتبدأ الفحوصات المطلوبة في حجب الدمج، وتعمل أي أتمتة تراقب طلبات السحب الجاهزة.';

  @override
  String get convertToDraft => 'تحويل إلى مسودة';

  @override
  String get convertToDraftConfirm =>
      'سيعود طلب السحب هذا إلى وضع المسودة. تُرفض طلبات المراجعة المعلّقة الخاصة به ولا يمكن دمجه حتى تحدده جاهزًا من جديد.';

  @override
  String get pullRequestMarkedReady => 'تم تحديد طلب السحب جاهزًا للمراجعة';

  @override
  String get pullRequestConvertedToDraft => 'تم تحويل طلب السحب إلى مسودة';

  @override
  String failedToMarkPrReady(String error) {
    return 'فشل التحديد كجاهز للمراجعة: ⁨$error⁩';
  }

  @override
  String failedToConvertPrToDraft(String error) {
    return 'فشل التحويل إلى مسودة: ⁨$error⁩';
  }

  @override
  String get checksFailing => 'فحوصات فاشلة';

  @override
  String get reviewsPending => 'بعض المراجعات معلّقة';

  @override
  String get mergeConflictsWithBase => 'يحتوي هذا الفرع على تعارضات يجب حلها';

  @override
  String get branchOutOfDateWithBase => 'هذا الفرع متأخر عن الفرع الأساسي';

  @override
  String get mergeBlockedByBranchProtection => 'حماية الفرع تحجب هذا الدمج';

  @override
  String get confirm => 'تأكيد';

  @override
  String get trustedSitesSectionTitle => 'المواقع الموثوقة';

  @override
  String get trustedSitesEmpty =>
      'لا مواقع موثوقة. أضف نطاقًا لتعطيل الحظر عليه.';

  @override
  String get addTrustedSite => 'إضافة موقع موثوق';

  @override
  String get removeTrustedSite => 'إزالة';

  @override
  String get disableBlockingForThisSite => 'تعطيل الحظر على هذا الموقع';

  @override
  String get enableBlockingForThisSite => 'تفعيل الحظر على هذا الموقع';

  @override
  String get enterDomainHint => 'مثال: example.com';

  @override
  String get invalidDomain => 'أدخل نطاقًا صالحًا (مثال: example.com)';

  @override
  String get pageLoadTimedOut =>
      'انتهت مهلة تحميل الصفحة. أعد التحميل أو افتحها في المتصفح.';

  @override
  String get pipelinesScreenTitle => 'خطوط الأنابيب';

  @override
  String get pipelinesScreenSubtitle =>
      'مسارات عمل وكلاء تصريحية متعددة الخطوات';

  @override
  String get pipelinesRunPipeline => 'تشغيل خط أنابيب';

  @override
  String get pipelineRunLauncherTitle => 'تشغيل خط أنابيب';

  @override
  String get pipelineRunSubtitle => 'اختر خط أنابيب واملأ مدخلاته لبدء تشغيل.';

  @override
  String get pipelineRunNoInputsBadge => 'بلا مدخلات';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مدخل',
      many: '$count مدخلًا',
      few: '$count مدخلات',
      two: 'مدخلان',
      one: 'مدخل واحد',
      zero: 'بلا مدخلات',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'لا يأخذ خط الأنابيب هذا أي مدخلات.';

  @override
  String get pipelineRunSubmit => 'تشغيل خط الأنابيب';

  @override
  String get pipelineRunCouldNotStart => 'تعذّر بدء التشغيل.';

  @override
  String pipelineRunStarted(String name) {
    return 'تم بدء $name';
  }

  @override
  String get pipelineRunEmptyTitle => 'لا خطوط أنابيب جاهزة للتشغيل';

  @override
  String get pipelineRunEmptyHint =>
      'فعّل خط أنابيب وشغّل التشغيل اليدوي في محرره ليمكن إطلاقه من هنا.';

  @override
  String get pipelineRunManageTemplates => 'إدارة خطوط الأنابيب';

  @override
  String get pipelineRunSettingsTitle => 'تشغيل يدوي';

  @override
  String get pipelineRunSettingsAllow => 'السماح بالتشغيل اليدوي';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'أظهر خط الأنابيب هذا في صفحة التشغيل ليمكن بدؤه يدويًا.';

  @override
  String get pipelineRunSettingsConcurrencyTitle => 'التزامن';

  @override
  String get pipelineRunSettingsMaxParallel =>
      'الحد الأقصى للتشغيلات المتوازية';

  @override
  String get pipelineRunSettingsMaxParallelHelp =>
      'اتركه فارغًا لعدد غير محدود. تنتظر التشغيلات الإضافية في قائمة انتظار وتبدأ عند توفر أماكن.';

  @override
  String get pipelineRunSettingsMaxParallelHint => 'غير محدود';

  @override
  String get pipelineRunSettingsMaxParallelInvalid =>
      'أدخل عددًا صحيحًا قيمته 1 أو أكثر، أو اتركه فارغًا لعدد غير محدود.';

  @override
  String get pipelineRunSettingsInputsTitle => 'المدخلات';

  @override
  String get pipelineRunSettingsAddInput => 'إضافة مدخل';

  @override
  String get pipelineRunSettingsNoInputs => 'لا مدخلات بعد.';

  @override
  String get pipelineInputEditTitle => 'حقل إدخال';

  @override
  String get pipelineInputKeyLabel => 'المفتاح';

  @override
  String get pipelineInputKeyHelp =>
      'مفتاح الحالة الذي تُخزَّن القيمة تحته (مثال: ⁨repo_full_name⁩).';

  @override
  String get pipelineInputLabelLabel => 'التسمية';

  @override
  String get pipelineInputTypeLabel => 'النوع';

  @override
  String get pipelineInputOptionsLabel => 'الخيارات (مفصولة بفواصل)';

  @override
  String get pipelineInputDefaultLabel => 'القيمة الافتراضية';

  @override
  String get pipelineInputPlaceholderLabel => 'النص النائب';

  @override
  String get pipelineInputHelpLabel => 'نص المساعدة';

  @override
  String get pipelineInputRequiredLabel => 'مطلوب';

  @override
  String get pipelineInputTypeText => 'نص';

  @override
  String get pipelineInputTypeMultiline => 'نص متعدد الأسطر';

  @override
  String get pipelineInputTypeNumber => 'رقم';

  @override
  String get pipelineInputTypeBoolean => 'مفتاح تبديل';

  @override
  String get pipelineInputTypeSelect => 'قائمة اختيار';

  @override
  String get pipelinesEmpty => 'لا تشغيلات لخطوط الأنابيب بعد';

  @override
  String get pipelinesEmptyHint => 'انقر على «تشغيل خط أنابيب» لبدء واحد.';

  @override
  String get pipelinesNoSteps => 'لا خطوات مسجلة بعد';

  @override
  String get pipelinesNoActiveWorkspace =>
      'حدد مساحة عمل لعرض خطوط الأنابيب الخاصة بها';

  @override
  String pipelinesLoadError(String error) {
    return 'فشل تحميل خطوط الأنابيب: ⁨$error⁩';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'فشل بدء خط الأنابيب: ⁨$error⁩';
  }

  @override
  String get pipelineStatusPending => 'قيد الانتظار';

  @override
  String get pipelineStatusQueued => 'في قائمة الانتظار';

  @override
  String get pipelineStatusRunning => 'قيد التشغيل';

  @override
  String get pipelineStatusSuspended => 'معلّق';

  @override
  String get pipelineStatusCompleted => 'مكتمل';

  @override
  String get pipelineStatusFailed => 'فشل';

  @override
  String get pipelineStatusCancelled => 'أُلغي';

  @override
  String get pipelineStatusSkipped => 'تم تخطيه';

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed من $total خطوات';
  }

  @override
  String get pipelineWaterfallTimeline => 'الخط الزمني';

  @override
  String pipelineWaterfallActive(String duration) {
    return 'نشط ⁨$duration⁩';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return 'خامل ⁨$duration⁩';
  }

  @override
  String get pipelineWaterfallIdleTooltip =>
      'وقت مستبعد من الإجمالي النشط: كان التشغيل متوقفًا أو منتظرًا بين الخطوات.';

  @override
  String get pipelineStepStarted => 'بدأت';

  @override
  String get pipelineStepFinished => 'انتهت';

  @override
  String get pipelineStepDurationLabel => 'المدة';

  @override
  String get pipelineStepBranch => 'الفرع';

  @override
  String get pipelineStepViewConversation => 'عرض المحادثة';

  @override
  String get pipelineStepError => 'الخطأ';

  @override
  String get pipelineStepInput => 'المدخل';

  @override
  String get pipelineStepOutput => 'المخرج';

  @override
  String get pipelineStepNotExecuted => 'لم تُنفَّذ بعد';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'فشل عند $step';
  }

  @override
  String get pipelineRunTriggerManual => 'يدوي';

  @override
  String get pipelineStepSkippedReason => 'تم تخطيها';

  @override
  String get pipelineStepPriorAttempts => 'المحاولات السابقة';

  @override
  String get pipelineStepAttemptLabel => 'المحاولة';

  @override
  String pipelineStepAttemptN(int number) {
    return 'المحاولة $number';
  }

  @override
  String get pipelineStepAttemptInterrupted => 'انقطعت';

  @override
  String get pipelineRunColumnPipeline => 'خط الأنابيب';

  @override
  String get pipelineRunColumnDuration => 'المدة';

  @override
  String get pipelineRunQueueNext => 'التالي';

  @override
  String pipelineRunQueuePosition(int position) {
    return '$position في قائمة الانتظار';
  }

  @override
  String get pipelineRunColumnStarted => 'البدء';

  @override
  String get pipelineRunHistory => 'سجلّ التشغيلات';

  @override
  String get pipelineRunHistoryEmpty => 'لا تشغيلات أخرى بعد';

  @override
  String pipelineRunRerunAgo(String time) {
    return 'أُعيد تشغيله $time';
  }

  @override
  String pipelineRunAttempt(int number) {
    return 'المحاولة $number';
  }

  @override
  String pipelineRunFirstStarted(String time) {
    return 'بدأ أول مرة $time';
  }

  @override
  String get pipelineRunFilterAll => 'الكل';

  @override
  String get pipelineRunFilterEmpty => 'لا تشغيلات تطابق هذا المرشح';

  @override
  String get relativeJustNow => 'للتو';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count دقيقة',
      many: 'قبل $count دقيقة',
      few: 'قبل $count دقائق',
      two: 'قبل دقيقتين',
      one: 'قبل دقيقة واحدة',
      zero: 'قبل $count دقيقة',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count ساعة',
      many: 'قبل $count ساعة',
      few: 'قبل $count ساعات',
      two: 'قبل ساعتين',
      one: 'قبل ساعة واحدة',
      zero: 'قبل $count ساعة',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count يوم',
      many: 'قبل $count يومًا',
      few: 'قبل $count أيام',
      two: 'قبل يومين',
      one: 'قبل يوم واحد',
      zero: 'قبل $count يوم',
    );
    return '$_temp0';
  }

  @override
  String get teamsTitle => 'الفرق';

  @override
  String get teamsAddTeam => 'إضافة فريق';

  @override
  String get teamsLoadError => 'تعذّر تحميل الفرق';

  @override
  String get teamsEmptyTitle => 'لا فرق بعد';

  @override
  String get teamsEmptyDescription =>
      'اجمع الوكلاء في فرق بحيث يمر العمل المُسنَد إلى فريق عبر قائد يفوّضه.';

  @override
  String get teamCreateTitle => 'فريق جديد';

  @override
  String get teamEditTitle => 'تعديل الفريق';

  @override
  String get teamNameLabel => 'اسم الفريق';

  @override
  String get teamNameHint => 'مثال: الواجهة الأمامية';

  @override
  String get teamDescriptionLabel => 'الوصف';

  @override
  String get teamDescriptionHint => 'ما الذي يتولاه هذا الفريق';

  @override
  String get teamLeaderLabel => 'القائد';

  @override
  String get teamLeaderHelp =>
      'المنسّق الذي يستلم العمل المُسنَد إلى الفريق ويفوّضه إلى العضو الأنسب.';

  @override
  String get teamNoLeader => 'بلا قائد';

  @override
  String get teamInstructionsLabel => 'تعليمات التشغيل';

  @override
  String get teamInstructionsHelp =>
      'تُلحق بإحاطة القائد — أعراف الفريق وقواعد التصعيد والنبرة.';

  @override
  String get teamInstructionsHint => 'اختياري';

  @override
  String get teamSaved => 'تم حفظ الفريق';

  @override
  String get teamMembersError => 'تعذّر تحميل الأعضاء';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عضو',
      many: '$count عضوًا',
      few: '$count أعضاء',
      two: 'عضوان',
      one: 'عضو واحد',
      zero: 'لا أعضاء',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => 'إضافة عضو';

  @override
  String get teamAddMemberTitle => 'إضافة أعضاء';

  @override
  String teamAddMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'إضافة $count',
      many: 'إضافة $count',
      few: 'إضافة $count',
      two: 'إضافة $count',
      one: 'إضافة 1',
      zero: 'إضافة',
    );
    return '$_temp0';
  }

  @override
  String get teamNoAgentsToAdd => 'كل الوكلاء في هذا الفريق بالفعل.';

  @override
  String get teamRemoveMember => 'إزالة من الفريق';

  @override
  String get teamLeaderBadge => 'القائد';

  @override
  String get teamUnknownAgent => 'وكيل غير معروف';

  @override
  String get teamMembersEmpty => 'لا أعضاء بعد';

  @override
  String get teamMembersEmptyDescription =>
      'أضف وكلاء ليكون لدى القائد من يفوّض إليهم.';

  @override
  String get teamSelectPrompt => 'حدد فريقًا';

  @override
  String get teamSelectPromptDescription =>
      'اختر فريقًا من القائمة، أو أنشئ فريقًا جديدًا.';

  @override
  String get teamDeleteTitle => 'حذف الفريق؟';

  @override
  String teamDeleteBody(String name) {
    return 'سيُحذف $name. لن يتأثر وكلاؤه.';
  }

  @override
  String get teamHasLeaderTooltip => 'له قائد';

  @override
  String get pipelineTemplatesNav => 'قوالب خطوط الأنابيب';

  @override
  String get pipelineTemplatesTitle => 'قوالب خطوط الأنابيب';

  @override
  String get pipelineTemplatesSubtitle =>
      'محرر سحب وإفلات لخطوط الأنابيب التي تنسّق وكلاءك.';

  @override
  String get pipelineTemplatesNew => 'قالب جديد';

  @override
  String get pipelineTemplatesEmpty =>
      'لا قوالب خطوط أنابيب بعد. أنشئ واحدًا للبدء.';

  @override
  String get pipelineTemplateBuiltInBadge => 'مدمج';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'حذف القالب؟';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'هل تريد حذف قالب خط الأنابيب ⁨$name⁩؟ لا يمكن التراجع عن هذا.';
  }

  @override
  String get pipelineTemplateEditorSubtitle =>
      'اسحب أنواع العقد من الشريط الجانبي إلى اللوحة، ثم اربطها معًا.';

  @override
  String get unsavedChanges => 'تغييرات غير محفوظة';

  @override
  String get nodeLibraryTitle => 'مكتبة العقد';

  @override
  String get nodeLibraryHint => 'اسحب أي عنصر إلى اللوحة لإضافة عقدة.';

  @override
  String get editorEmptyCanvas => 'اسحب عقدة من المكتبة للبدء.';

  @override
  String get pipelineWhenThisHappens => 'عندما يحدث هذا';

  @override
  String get pipelineDoThis => 'نفّذ هذا';

  @override
  String get pipelineAddStep => 'إضافة خطوة';

  @override
  String get pipelineTidyUp => 'ترتيب التخطيط';

  @override
  String get pipelineEditorHint => 'اسحب الخطوات للترتيب · اسحب مقبضًا للربط';

  @override
  String get pipelineRemoveConnection => 'إزالة الاتصال';

  @override
  String get pipelineDragToConnect => 'اسحب للربط';

  @override
  String get pipelineNewDefaultName => 'خط أنابيب جديد';

  @override
  String get nodeCategoryTriggers => 'المشغّلات';

  @override
  String get triggerEventWebhook => 'ويب هوك';

  @override
  String get pipelineAddTrigger => 'إضافة مشغّل';

  @override
  String get pipelineOnEvent => 'عند حدث';

  @override
  String get nodeConfigTitle => 'إعدادات العقدة';

  @override
  String get nodeConfigKind => 'النوع';

  @override
  String get nodeConfigLabel => 'التسمية';

  @override
  String get nodeConfigAgent => 'الوكيل';

  @override
  String get nodeConfigAgentHint => 'اختر وكيلًا…';

  @override
  String get nodeConfigInputKeys => 'مفاتيح الإدخال (مفصولة بفواصل)';

  @override
  String get nodeConfigInputKeysHelp =>
      'مفاتيح الحالة التي تستهلكها هذه العقدة. تُستخدم لاستبدال العناصر النائبة في الموجّه.';

  @override
  String get nodeConfigRepos => 'المستودعات المطلوب استنساخها';

  @override
  String get nodeConfigReposHelp =>
      'المستودعات التي تُستنسخ وتُفهرس شفرتها عند بدء هذه العقدة محادثتها. تحديد كل المستودعات يستنسخها جميعًا (الافتراضي).';

  @override
  String get nodeConfigRepoBranchHint => 'الفرع (الافتراضي)';

  @override
  String get nodeConfigRepoBranchHelp =>
      'الفرع الذي تُشتق منه كل نسخة عمل. اتركه فارغًا لاستخدام الفرع الافتراضي للمستودع — تحصل شجرة العمل على فرعها الخاص في كل الأحوال، فلا يصل ما يودعه الوكيل إلى هذا الفرع.';

  @override
  String nodeConfigReposDynamic(String entries) {
    return 'العناصر الديناميكية المحتفظ بها: ⁨$entries⁩';
  }

  @override
  String get nodeConfigCreateConversation => 'فتح محادثة فيها';

  @override
  String get nodeConfigCreateConversationHelp =>
      'أبقِ هذا الخيار مطفأً عندما تتبعها عدة عقد وكلاء — كل واحدة تفتح تدفقها المسمى الخاص. فعّله عندما تتبعها عقدة وكيل واحدة، كي لا تعرض المساحة محادثة بلا عنوان بجانبها.';

  @override
  String get nodeConfigConversationTitle => 'اسم المحادثة';

  @override
  String get nodeConfigConversationTitleHelp =>
      'أعطِ عقدة الوكيل التالية الاسم نفسه فيعملا في تدفق واحد. القيمة الافتراضية هي تسمية العقدة.';

  @override
  String get nodeConfigSpaceName => 'اسم المساحة';

  @override
  String get nodeConfigSpaceNameHelp =>
      'اسم المساحة التي تفتحها هذه العقدة. يدعم عناصر الحالة النائبة نفسها المتاحة في الموجّه. اتركه فارغًا لاستخدام تسمية العقدة.';

  @override
  String get nodeConfigSpaceNameHint => 'مراجعة ⁨pr_number⁩';

  @override
  String get nodeConfigStreamTitle => 'اسم المحادثة';

  @override
  String get nodeConfigStreamTitleHelp =>
      'التدفق المسمى الذي يعمل فيه وكيل هذه العقدة داخل المساحة. يدعم عناصر الحالة النائبة نفسها المتاحة في الموجّه. اتركه فارغًا فيهبط الدور في المحادثة الدائمة للمساحة، حيث يتداخل كل الوكلاء عند التوزيع المتوازي.';

  @override
  String get nodeConfigConversationTitleHint => 'تحليل البنية المعمارية';

  @override
  String get nodeConfigOutputKey => 'مفتاح الإخراج';

  @override
  String get nodeConfigPrompt => 'قالب الموجّه';

  @override
  String get nodeConfigPromptHelp =>
      'استخدم عناصر نائبة بأقواس مزدوجة لسحب القيم من الحالة وقت التشغيل.';

  @override
  String get nodeConfigScript => 'سكربت Bash';

  @override
  String get nodeConfigScriptHelp =>
      'يعمل عبر ⁨bash -c⁩. المتغير GITHUB_TOKEN مضبوط. تُستبدل العناصر النائبة قبل التنفيذ.';

  @override
  String get nodeConfigRouteKeys => 'مفاتيح التوجيه';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'مفتاح التوجيه من $source';
  }

  @override
  String get conditionSectionTitle => 'الشرط';

  @override
  String get conditionMode => 'الوضع';

  @override
  String get conditionModeFilesAny => 'وجود ملف/ملفات — أي منها';

  @override
  String get conditionModeFilesAll => 'وجود الملفات — كلها';

  @override
  String get conditionModeComparison => 'مقارنة';

  @override
  String get conditionModeSwitch => 'تفريع';

  @override
  String get conditionFilePaths => 'مسارات الملفات';

  @override
  String get conditionFilePathsAnyHelp =>
      'مسار واحد في كل سطر، نسبةً إلى الدليل الأساسي. يوجَّه إلى «صحيح» عند وجود أي منها.';

  @override
  String get conditionFilePathsAllHelp =>
      'مسار واحد في كل سطر، نسبةً إلى الدليل الأساسي. يوجَّه إلى «صحيح» فقط عند وجودها كلها.';

  @override
  String get conditionBaseKey => 'مفتاح الدليل الأساسي';

  @override
  String get conditionBaseKeyHelp =>
      'مفتاح الحالة الذي يحمل الدليل الذي تُحل المسارات نسبةً إليه (الافتراضي ⁨repo_local_path⁩).';

  @override
  String get conditionRecursive => 'البحث في الأدلة الفرعية';

  @override
  String get conditionNegate => 'عكس: التوجيه إلى «صحيح» عند الغياب';

  @override
  String get conditionLeft => 'القيمة اليسرى';

  @override
  String get conditionOperator => 'المعامل';

  @override
  String get conditionRight => 'القيمة اليمنى';

  @override
  String get conditionSwitchKey => 'التفريع حسب مفتاح الحالة';

  @override
  String get conditionCases => 'الحالات (مفصولة بفواصل)';

  @override
  String get conditionCasesHelp =>
      'مفاتيح التوجيه التي تُطابَق مع القيمة، بالترتيب.';

  @override
  String get conditionDefaultCase => 'الحالة الافتراضية';

  @override
  String get triggerManualHelp => 'الإظهار في صفحة التشغيل والبدء يدويًا.';

  @override
  String get triggerKindSchedule => 'وفق جدول';

  @override
  String get triggerScheduleExprLabel => 'الجدولة (cron أو ⁨every:seconds⁩)';

  @override
  String get triggerTimezoneLabel => 'المنطقة الزمنية (اختياري)';

  @override
  String get triggerCatchUpLabel => 'عند التشغيلات الفائتة';

  @override
  String get triggerCatchUpRunOnce => 'تشغيل مرة واحدة';

  @override
  String get triggerCatchUpSkip => 'تخطي';

  @override
  String get syncHealthTitle => 'سلامة المزامنة';

  @override
  String get syncHealthNoConfigs => 'لا اتصالات مزامنة بعد';

  @override
  String get syncHealthNeverSynced => 'لم تتم المزامنة قط';

  @override
  String get syncOutcomeOk => 'تمت المزامنة';

  @override
  String get syncOutcomeFailed => 'فشلت';

  @override
  String get syncOutcomeSkipped => 'تم تخطيها';

  @override
  String syncHealthFailedStreak(int count) {
    return '$count إخفاقات متتالية';
  }

  @override
  String get triggerWebhookHelp =>
      'يُنشأ عنوان URL موقّع للويب هوك. ترسل الأنظمة الخارجية طلب POST إليه لبدء خط الأنابيب هذا.';

  @override
  String get triggerWebhookPathLabel => 'مسار الويب هوك';

  @override
  String get triggerMatchStatusLabel => 'فقط عندما تكون الحالة';

  @override
  String get triggerSummaryNone => 'لا مشغّلات';

  @override
  String triggerEverySeconds(int seconds) {
    return 'كل $seconds ثانية';
  }

  @override
  String get triggerEventManual => 'تشغيل يدوي';

  @override
  String get triggerEventSchedule => 'جدولة';

  @override
  String get triggerEventPrStatusChanged => 'تغيّرت حالة PR';

  @override
  String get triggerEventExternalPr => 'فُتح PR خارجي';

  @override
  String get triggerEventPrPublished => 'نُشر PR';

  @override
  String get triggerEventPrMerged => 'دُمج PR';

  @override
  String get triggerEventRepoAdded => 'أُضيف مستودع';

  @override
  String get triggerEventCodeGraphWatch => 'تغيير ملف';

  @override
  String pipelineRunCauseChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملف متغيّر',
      many: '$count ملفًا متغيّرًا',
      few: '$count ملفات متغيّرة',
      two: 'ملفان متغيّران',
      one: 'ملف واحد متغيّر',
      zero: '$count ملف متغيّر',
    );
    return '$_temp0';
  }

  @override
  String pipelineRunCauseMorePaths(int count) {
    return '⁨+$count⁩ أخرى';
  }

  @override
  String get pipelineRunCauseRescan => 'تغيّر على القرص';

  @override
  String get pipelineRunCauseInitial => 'أول فهرسة لنسخة العمل هذه';

  @override
  String get triggerEventMessageReceived => 'استلام رسالة';

  @override
  String get triggerEventTicketCompleted => 'اكتملت تذكرة';

  @override
  String get triggerEventTicketFailed => 'فشلت تذكرة';

  @override
  String get triggerEventTicketCancelled => 'أُلغيت تذكرة';

  @override
  String get triggerEventBudgetCrossed => 'تم تجاوز عتبة الميزانية';

  @override
  String get nodeLibrarySearchHint => 'البحث في العقد';

  @override
  String get nodeLibraryNoMatches => 'لا عقد مطابقة';

  @override
  String get nodeCategoryFlow => 'التدفق والمنطق';

  @override
  String get nodeCategoryPr => 'مراجعة PR';

  @override
  String get nodeCategoryAgents => 'الوكلاء';

  @override
  String get nodeCategoryMessaging => 'المراسلة';

  @override
  String get nodeCategoryCode => 'الكود';

  @override
  String get triggerDisabledTag => 'مطفأ';

  @override
  String get pipelineInputTypeRepo => 'مستودع';

  @override
  String get pipelineRunNoRepos => 'لا مستودعات في مساحة العمل هذه بعد.';

  @override
  String get allowTicketingApi => 'السماح باستدعاءات API للتذاكر';

  @override
  String get ticketingApiKey => 'مفتاح API للتذاكر';

  @override
  String get ticketingApiKeySubtitle =>
      'يحقن مفتاح API لمزوّد التذاكر في البيئة المعزولة.';

  @override
  String get ticketingProvider => 'مزوّد التذاكر';

  @override
  String get connectGitHubAndTicketing =>
      'اربط مستضيف كود ليتمكن Control Center من قراءة طلبات السحب والمشكلات والمراجعات الخاصة بك. اربط مزوّد تذاكر إن شئت. بيانات الاعتماد يحتفظ بها خادمك، لا هذا الجهاز أبدًا.';

  @override
  String get triggerEventTicketAssigned => 'إسناد تذكرة';

  @override
  String get triggerEventTicketCreated => 'تم إنشاء تذكرة';

  @override
  String get triggerEventTicketStatusChanged => 'تغيرت حالة التذكرة';

  @override
  String get triggerEventMeetingRecordingStopped => 'توقف تسجيل الاجتماع';

  @override
  String get triggerEventSkillUpdated => 'تم تحديث المهارة';

  @override
  String get triggerEventSpaceDeleted => 'تم حذف المساحة';

  @override
  String get triggerExternalPrHelp =>
      'طلب سحب فُتح على مضيف الشفرة، وليس من Control Center.';

  @override
  String get triggerPrPublishedHelp =>
      'طلب سحب فُتح من Control Center أو بواسطة وكيل.';

  @override
  String get triggerPrStatusChangedHelp =>
      'دُمج أو أُغلق أو فُتح أو أُعيد فتحه أو وُوفق عليه. صفِّ حسب الحالة في اللوحة.';

  @override
  String get triggerPrMergedHelp =>
      'فقط عند دمج طلب السحب، وليس عند إغلاقه أو إعادة فتحه.';

  @override
  String get triggerRepoAddedHelp => 'يُربط مستودع بهذا مساحة العمل.';

  @override
  String get triggerCodeGraphWatchHelp =>
      'يتغيّر ملف في مستودع مرتبط على القرص.';

  @override
  String get triggerMessageReceivedHelp => 'تصل رسالة جديدة في مساحة.';

  @override
  String get triggerTicketCreatedHelp => 'يُنشأ تذكرة في مساحة العمل هذه.';

  @override
  String get triggerTicketStatusChangedHelp => 'تنتقل تذكرة بين الحالات.';

  @override
  String get triggerTicketCompletedHelp => 'تكتمل تذكرة بنجاح.';

  @override
  String get triggerTicketFailedHelp =>
      'فشل تشغيل وكيل وتُعلَّم التذكرة كفاشلة.';

  @override
  String get triggerTicketCancelledHelp => 'تُلغى تذكرة ولن تُتابع.';

  @override
  String get triggerBudgetCrossedHelp => 'يُتجاوز حد إنفاق لمساحة عمل أو وكيل.';

  @override
  String get triggerTicketAssignedHelp =>
      'تُسند تذكرة إلى شخص أو وكيل أو فريق.';

  @override
  String get triggerMeetingRecordingStoppedHelp => 'ينتهي تسجيل اجتماع.';

  @override
  String get triggerSkillUpdatedHelp => 'يُثبَّت مهارة أو تُحدَّث.';

  @override
  String get triggerSpaceDeletedHelp => 'تُحذف مساحة محادثة.';

  @override
  String get navTickets => 'التذاكر';

  @override
  String get ticketsTitle => 'التذاكر';

  @override
  String get newTicket => 'تذكرة جديدة';

  @override
  String get noTicketsYet => 'لا تذاكر بعد';

  @override
  String get addCollaborator => 'إضافة متعاون';

  @override
  String get noCollaborators => 'لا متعاونين بعد';

  @override
  String get linkedPullRequests => 'طلبات السحب المرتبطة';

  @override
  String get noLinkedPullRequests => 'لا طلبات سحب مرتبطة بعد';

  @override
  String get stopAgent => 'إيقاف الوكيل';

  @override
  String get ticketProperties => 'الخصائص';

  @override
  String get ticketTabIssue => 'المشكلة';

  @override
  String get ticketSelectPrompt => 'حدد تذكرة لعرض تفاصيلها';

  @override
  String get unassigned => 'غير مُسنَدة';

  @override
  String get ticketStatusBacklog => 'الأعمال المتراكمة';

  @override
  String get ticketStatusOpen => 'للتنفيذ';

  @override
  String get ticketStatusInProgress => 'قيد التنفيذ';

  @override
  String get ticketStatusInReview => 'قيد المراجعة';

  @override
  String get ticketStatusDone => 'منجزة';

  @override
  String get ticketStatusBlocked => 'متعثرة';

  @override
  String get ticketStatusFailed => 'فشلت';

  @override
  String get ticketStatusCancelled => 'أُلغيت';

  @override
  String get notificationTicketAssigned => 'تم إسناد تذكرة';

  @override
  String get notificationTicketStatusChanged => 'تغيّرت حالة التذكرة';

  @override
  String get priority => 'الأولوية';

  @override
  String get status => 'الحالة';

  @override
  String get assignee => 'المُسنَد إليه';

  @override
  String get labels => 'التسميات';

  @override
  String get noLabelsYet => 'لا تسميات بعد';

  @override
  String get clearLabels => 'مسح التسميات';

  @override
  String get pipelineStepAgentActivity => 'نشاط الوكيل';

  @override
  String get runStatusCompleted => 'مكتمل';

  @override
  String get runStatusQueued => 'في قائمة الانتظار';

  @override
  String get ticketDescription => 'الوصف';

  @override
  String get ticketPriorityNone => 'بلا';

  @override
  String get ticketPriorityUrgent => 'عاجلة';

  @override
  String get ticketPriorityHigh => 'مرتفعة';

  @override
  String get ticketPriorityMedium => 'متوسطة';

  @override
  String get ticketPriorityLow => 'منخفضة';

  @override
  String get ticketViewList => 'قائمة';

  @override
  String get ticketViewBoard => 'لوحة';

  @override
  String get ticketTitlePlaceholder => 'عنوان المشكلة';

  @override
  String get ticketDescriptionPlaceholder => 'أضف وصفًا…';

  @override
  String get createMore => 'إنشاء المزيد';

  @override
  String selectedCount(int count) {
    return '$count محددة';
  }

  @override
  String get clearSelection => 'مسح التحديد';

  @override
  String get bulkDeleteTitle => 'حذف التذاكر';

  @override
  String bulkDeleteMessage(int count) {
    return 'هل تريد حذف $count من التذاكر المحددة؟ لا يمكن التراجع عن هذا.';
  }

  @override
  String get assignTo => 'إسناد إلى…';

  @override
  String get sectionMembers => 'الأعضاء';

  @override
  String get sectionAgents => 'الوكلاء';

  @override
  String get sidebarGroupWorkspace => 'مساحة العمل';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsTooltip => 'الإشعارات';

  @override
  String get notificationsEmpty => 'اطلعت على كل شيء';

  @override
  String notificationsUnreadCount(int count) {
    return '$count غير مقروءة';
  }

  @override
  String get notificationsMarkRead => 'وضع علامة مقروء';

  @override
  String get notificationsMarkUnread => 'وضع علامة غير مقروء';

  @override
  String get notificationsEntryActions => 'إجراءات الإشعار';

  @override
  String get markAllRead => 'وضع علامة مقروء على الكل';

  @override
  String get teamsNav => 'الفرق';

  @override
  String get noWorkspace => 'لا مساحة عمل';

  @override
  String get selectWorkspace => 'حدد مساحة عمل';

  @override
  String get navMemory => 'الذاكرة';

  @override
  String get memoryTabFacts => 'الحقائق';

  @override
  String get memoryTabPolicies => 'السياسات';

  @override
  String get memoryGraphShowFacts => 'إظهار الحقائق';

  @override
  String get memoryGraphHideFacts => 'إخفاء الحقائق';

  @override
  String get memoryGraphExpandAll => 'توسيع كل الحقائق';

  @override
  String get memoryGraphCollapseAll => 'طي كل الحقائق';

  @override
  String get memoryTabGraph => 'شبكة المعرفة';

  @override
  String get memoryNoWorkspace => 'حدد مساحة عمل لعرض ذاكرتها.';

  @override
  String get searchArticles => 'البحث في المقالات';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterUnread => 'غير المقروءة';

  @override
  String get filterSaved => 'المحفوظة';

  @override
  String get saveArticle => 'حفظ المقال';

  @override
  String get removeFromSaved => 'إزالة من المحفوظات';

  @override
  String get filterBySource => 'تصفية حسب المصدر';

  @override
  String get viewAsList => 'عرض قائمة';

  @override
  String get viewAsGrid => 'عرض شبكة';

  @override
  String get noMatchingArticles => 'لا مقالات مطابقة';

  @override
  String get noMatchingArticlesBody => 'جرّب بحثًا مختلفًا أو مرشح مصدر آخر.';

  @override
  String get allCaughtUp => 'اطلعت على كل شيء';

  @override
  String get allCaughtUpBody => 'لا مقالات غير مقروءة — عُد لاحقًا.';

  @override
  String get openArticlesInAppDescription =>
      'افتح الروابط في القارئ المدمج بدلًا من متصفحك الافتراضي.';

  @override
  String get blockAdsTrackersDescription =>
      'أزل الإعلانات والمتتبعات ولافتات ملفات تعريف الارتباط من المقالات التي تفتحها في القارئ.';

  @override
  String get agentQuestionHeader => 'سؤال لك';

  @override
  String get agentQuestionAnsweredLabel => 'تمت الإجابة';

  @override
  String get agentQuestionFreeformHint => 'اكتب إجابتك…';

  @override
  String agentQuestionProgress(int index, int count) {
    return 'السؤال $index من $count';
  }

  @override
  String get agentQuestionSkip => 'تخطي';

  @override
  String get agentQuestionSkippedLabel => 'تم التخطي';

  @override
  String get agentQuestionFreeformOptionHint => 'صِف الأمر بكلماتك…';

  @override
  String get reviewRequested => 'طُلبت مراجعة';

  @override
  String get connectGitHubHint =>
      'سجّل الدخول إلى GitHub أو أضف رمز وصول في الإعدادات ← مساحة العمل ← الملف الشخصي والهوية ← استضافة الكود';

  @override
  String get connectGitHubToLoadPrs => 'اربط GitHub لتحميل طلبات السحب';

  @override
  String get noRepositoriesConfigured => 'لا مستودعات مُعدّة';

  @override
  String openedAgo(String age) {
    return 'فُتح $age';
  }

  @override
  String prTimelineOpened(String author) {
    return 'فتح ⁨$author⁩ طلب السحب هذا';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إيداع',
      many: '$count إيداعًا',
      few: '$count إيداعات',
      two: 'إيداعين',
      one: 'إيداع واحد',
      zero: '$count إيداع',
    );
    return 'فتح ⁨$author⁩ طلب السحب هذا مع $_temp0';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return 'طلب ⁨$actor⁩ مراجعة من ⁨$reviewers⁩';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return 'أزال ⁨$actor⁩ طلب المراجعة الموجّه إلى ⁨$reviewers⁩';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return 'طلب ⁨$actor⁩ مراجعة من ⁨$requested⁩ وأزال طلب المراجعة الموجّه إلى ⁨$removed⁩';
  }

  @override
  String prTimelineAddedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'التسميات',
      one: 'التسمية',
    );
    return 'أضاف ⁨$actor⁩ ⁨$labels⁩ $_temp0';
  }

  @override
  String prTimelineRemovedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'التسميات',
      one: 'التسمية',
    );
    return 'أزال ⁨$actor⁩ ⁨$labels⁩ $_temp0';
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
      other: 'التسميات',
      one: 'التسمية',
    );
    String _temp1 = intl.Intl.pluralLogic(
      removedCount,
      locale: localeName,
      other: 'التسميات',
      one: 'التسمية',
    );
    return 'أضاف ⁨$actor⁩ ⁨$added⁩ $_temp0 وأزال ⁨$removed⁩ $_temp1';
  }

  @override
  String prTimelineCommitted(String author) {
    return 'أودع ⁨$author⁩';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إيداع',
      many: '$count إيداعًا',
      few: '$count إيداعات',
      two: 'إيداعين',
      one: 'إيداعًا واحدًا',
      zero: '$count إيداع',
    );
    return 'دفع ⁨$author⁩ $_temp0';
  }

  @override
  String prTimelineApproved(String author) {
    return 'وافق ⁨$author⁩ على هذه التغييرات';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return 'طلب ⁨$author⁩ تغييرات';
  }

  @override
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تعليق على الكود',
      many: '$count تعليقًا على الكود',
      few: '$count تعليقات على الكود',
      two: 'تعليقان على الكود',
      one: 'تعليق واحد على الكود',
      zero: 'لا تعليقات على الكود',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return 'راجع ⁨$author⁩';
  }

  @override
  String get prTimelineSomeone => 'شخص ما';

  @override
  String get prTimelineBotBadge => 'بوت';

  @override
  String updatedAgo(String age) {
    return 'حُدّث $age';
  }

  @override
  String get checksPassing => 'الفحوصات ناجحة';

  @override
  String get checksRunning => 'الفحوصات قيد التشغيل';

  @override
  String get needsYourReview => 'بحاجة إلى مراجعتك';

  @override
  String get checks => 'الفحوصات';

  @override
  String get noReviewersAssigned => 'لا مراجعون معيّنون';

  @override
  String get noAssignees => 'لا مُسنَد إليهم';

  @override
  String get loadingEllipsis => 'جارٍ التحميل…';

  @override
  String get loadingChecks => 'جارٍ تحميل الفحوصات…';

  @override
  String get noChecksYet => 'لم تُشغَّل أي فحوصات بعد';

  @override
  String get noChangesToReview => 'لا توجد تغييرات للمراجعة';

  @override
  String checksFailingCount(int count) {
    return '$count فاشلة';
  }

  @override
  String get showMore => 'عرض المزيد';

  @override
  String get showLess => 'عرض أقل';

  @override
  String get backToPullRequests => 'العودة إلى طلبات السحب';

  @override
  String get pullRequestNotFound => 'لم يتم العثور على طلب السحب';

  @override
  String get pullRequestNotFoundBody => 'ربما تم دمجه أو إغلاقه أو نقله.';

  @override
  String get couldntLoadPullRequest => 'تعذر تحميل طلب السحب هذا';

  @override
  String get showDetails => 'عرض التفاصيل';

  @override
  String get noDescriptionProvided => 'لم يتم تقديم وصف.';

  @override
  String get factsHint => 'ستظهر الحقائق هنا مع تعلّم وكلائك.';

  @override
  String get noFactsMatch => 'لا توجد حقائق مطابقة لبحثك';

  @override
  String get memoryLoadError => 'تعذر تحميل الذاكرة';

  @override
  String get sortRecent => 'الأحدث';

  @override
  String get sortConfidence => 'الثقة';

  @override
  String get confidenceTooltip =>
      'مدى تأكد الوكلاء من صحة هذه الحقيقة، من 0 إلى 100%.';

  @override
  String get supersededTooltip => 'حلّت حقيقة أحدث محل هذه الحقيقة.';

  @override
  String get domain => 'المجال';

  @override
  String get fitToView => 'ملاءمة العرض';

  @override
  String get project => 'المشروع';

  @override
  String get newProject => 'مشروع جديد';

  @override
  String get editProject => 'تحرير المشروع';

  @override
  String get deleteProject => 'حذف المشروع';

  @override
  String get noProject => 'بدون مشروع';

  @override
  String get allTickets => 'كل التذاكر';

  @override
  String get projectNamePlaceholder => 'اسم المشروع';

  @override
  String get projectDescriptionPlaceholder => 'الوصف (اختياري)';

  @override
  String get projectColorLabel => 'اللون';

  @override
  String get noProjectsYet => 'لا توجد مشاريع بعد';

  @override
  String get projectTicketsEmpty => 'لا توجد تذاكر في هذا المشروع بعد';

  @override
  String get createProject => 'إنشاء مشروع';

  @override
  String projectProgress(int done, int total) {
    return 'اكتمل $done من $total';
  }

  @override
  String deleteProjectConfirm(String name) {
    return 'هل تريد حذف \"$name\"؟ يتم الاحتفاظ بتذاكره وإزالتها من المشروع.';
  }

  @override
  String get projectStatusActive => 'نشط';

  @override
  String get projectStatusCompleted => 'مكتمل';

  @override
  String get projectStatusArchived => 'مؤرشف';

  @override
  String get markProjectCompleted => 'تحديد كمكتمل';

  @override
  String get markProjectActive => 'تحديد كنشط';

  @override
  String get archiveProject => 'أرشفة';

  @override
  String get restoreProject => 'استعادة';

  @override
  String get relations => 'العلاقات';

  @override
  String get relateTo => 'ربط مع';

  @override
  String get relationSubIssueOf => 'مشكلة فرعية من…';

  @override
  String get relationParentOf => 'أصل لـ…';

  @override
  String get relationBlockedBy => 'محظورة بواسطة…';

  @override
  String get relationBlocking => 'تحظر…';

  @override
  String get relationRelatedTo => 'مرتبطة بـ…';

  @override
  String get relationDuplicateOf => 'تكرار لـ…';

  @override
  String get relationGroupParent => 'الأصل';

  @override
  String get relationGroupSubIssues => 'المشكلات الفرعية';

  @override
  String get relationGroupBlockedBy => 'محظورة بواسطة';

  @override
  String get relationGroupBlocking => 'تحظر';

  @override
  String get relationGroupRelated => 'مرتبطة';

  @override
  String get relationGroupDuplicateOf => 'تكرار لـ';

  @override
  String get relationGroupDuplicatedBy => 'مكرَّرة بواسطة';

  @override
  String get copyId => 'نسخ ID';

  @override
  String get ticketIdCopied => 'تم نسخ ID التذكرة';

  @override
  String get searchTicketsHint => 'البحث في التذاكر…';

  @override
  String get noMatchingTickets => 'لا توجد تذاكر مطابقة';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs PR',
      many: '$prs PR',
      few: '$prs PR',
      two: '$prs PR',
      one: 'PR واحد',
      zero: 'لا PR',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos مستودع',
      many: '$repos مستودعًا',
      few: '$repos مستودعات',
      two: 'مستودعين',
      one: 'مستودع واحد',
      zero: '0 مستودع',
    );
    return '$_temp0 بانتظار مراجعتك في $_temp1';
  }

  @override
  String get manageWorkspacesSubtitle =>
      'أعد تسمية مساحة العمل وغيّر شعارها — اختر واحدة من القائمة الجانبية لتحريرها.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مساحة عمل',
      many: '$count مساحة عمل',
      few: '$count مساحات عمل',
      two: 'مساحتا عمل',
      one: 'مساحة عمل واحدة',
      zero: 'لا توجد مساحات عمل',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos مستودع',
      many: '$repos مستودعًا',
      few: '$repos مستودعات',
      two: 'مستودعان',
      one: 'مستودع واحد',
      zero: 'لا مستودعات',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents وكيل',
      many: '$agents وكيلًا',
      few: '$agents وكلاء',
      two: 'وكيلان',
      one: 'وكيل واحد',
      zero: '0 وكلاء',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'الهوية';

  @override
  String get uploadImage => 'رفع صورة';

  @override
  String get failedToSaveLogo =>
      'تعذر حفظ صورة الشعار. تأكد من أن التطبيق يمكنه قراءة الملف المحدد.';

  @override
  String get workspaceLogoHint =>
      'PNG أو JPG أو GIF حتى 2 ميجابايت. وإلا فسنستخدم الحرف الأول من اسم مساحة العمل.';

  @override
  String get workspaceNameFieldHelp =>
      'يظهر في مبدّل المساحات وشريط التنقل وعلى كل شاشة.';

  @override
  String get dangerZone => 'منطقة الخطر';

  @override
  String get deleteThisWorkspace => 'حذف مساحة العمل هذه';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return 'يزيل $name نهائيًا مع اتصالات المستودعات والوكلاء والذاكرة الخاصة بها. لا يمكن التراجع عن هذا.';
  }

  @override
  String get discard => 'تجاهل';

  @override
  String discardChangesQuestion(String name) {
    return 'هل تريد تجاهل التغييرات غير المحفوظة في $name؟';
  }

  @override
  String get workspaceUpdated => 'تم تحديث مساحة العمل';

  @override
  String get editTitle => 'تحرير العنوان';

  @override
  String get editDescription => 'تحرير الوصف';

  @override
  String get addDescription => 'إضافة وصف';

  @override
  String get prTitlePlaceholder => 'العنوان';

  @override
  String get prBodyPlaceholder => 'اترك وصفًا';

  @override
  String get write => 'كتابة';

  @override
  String get overview => 'نظرة عامة';

  @override
  String get noFilesChanged => 'لم يتم تغيير أي ملفات';

  @override
  String get diff => 'الفروق';

  @override
  String get preview => 'معاينة';

  @override
  String get imageDiffBefore => 'قبل';

  @override
  String get imageDiffAfter => 'بعد';

  @override
  String get imageDiffModeTwoUp => 'جنباً إلى جنب';

  @override
  String get imageDiffModeSwipe => 'تمرير';

  @override
  String get imageDiffModeDifference => 'الفرق';

  @override
  String imageDiffChangedPercent(String percent) {
    return 'تغير $percent٪';
  }

  @override
  String get imageDiffPictures => 'صور';

  @override
  String get imageDiffSource => 'المصدر';

  @override
  String get imageDiffDeleted => 'محذوف';

  @override
  String get imageDiffAdded => 'مضاف';

  @override
  String imageDiffDimensions(int width, int height) {
    return 'ع: ${width}px | ص: ${height}px';
  }

  @override
  String get outdated => 'قديم';

  @override
  String get outdatedComments => 'تعليقات قديمة';

  @override
  String outdatedCountLabel(int count) {
    return '$count قديمة';
  }

  @override
  String get prTemplateLabel => 'القالب';

  @override
  String get prTemplateDefault => 'افتراضي';

  @override
  String get addReviewers => 'إضافة مراجعين';

  @override
  String get addAssignees => 'إضافة معيّنين';

  @override
  String get searchUsers => 'البحث عن أشخاص…';

  @override
  String get searchReviewers => 'البحث عن أشخاص وفرق…';

  @override
  String get usersSectionLabel => 'الأشخاص';

  @override
  String get userStatusBusy => 'مشغول';

  @override
  String get teamsSectionLabel => 'الفرق';

  @override
  String get suggestedReviewers => 'مراجعون مقترحون';

  @override
  String get noMatchingUsers => 'لا يوجد أشخاص مطابقون';

  @override
  String get noMatchingReviewers => 'لا توجد نتائج مطابقة';

  @override
  String get requiredByCodeOwners => 'مطلوب من مالكي الكود';

  @override
  String reviewedOnBehalfOf(String login) {
    return 'عبر ⁨$login⁩';
  }

  @override
  String get team => 'فريق';

  @override
  String get markdownBold => 'غامق';

  @override
  String get markdownItalic => 'مائل';

  @override
  String get markdownHeading => 'عنوان';

  @override
  String get markdownBulletList => 'قائمة نقطية';

  @override
  String get markdownChecklist => 'قائمة تحقق';

  @override
  String get markdownCode => 'كود';

  @override
  String get markdownLink => 'رابط';

  @override
  String get markdownQuote => 'اقتباس';

  @override
  String get markdownSupported => 'Markdown مدعوم';

  @override
  String get markdownAttachImages => 'انقر لإضافة صور';

  @override
  String failedToUpdateTitle(String error) {
    return 'تعذر تحديث العنوان: ⁨$error⁩';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'تعذر تحديث الوصف: ⁨$error⁩';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'تعذر تحديث المراجعين: ⁨$error⁩';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'تعذر تحديث المعيّنين: ⁨$error⁩';
  }

  @override
  String get discardChangesConfirm => 'هل تريد تجاهل تغييراتك؟';

  @override
  String get newPr => 'PR جديد';

  @override
  String get openPullRequest => 'فتح طلب سحب';

  @override
  String get composePrSubtitle => 'من فرع دفعته بنفسك — دون أي وكلاء أو تذاكر';

  @override
  String get createAsDraft => 'إنشاء كمسودة';

  @override
  String get composePrNoRepo => 'لم يتم تحديد مستودع GitHub';

  @override
  String get composePrNoRepoHint =>
      'حدد مساحة عمل تحتوي على مستودع مرتبط بـ GitHub لفتح طلب سحب.';

  @override
  String get composePrPickBranches =>
      'اختر فرع الأساس وفرع المقارنة لمعاينة التغييرات.';

  @override
  String get composePrNothingToCompare => 'لا توجد تغييرات بين هذين الفرعين.';

  @override
  String get repository => 'المستودع';

  @override
  String get baseBranchLabel => 'الأساس';

  @override
  String get compareBranchLabel => 'المقارنة';

  @override
  String get selectBranch => 'اختر فرعًا';

  @override
  String get navMeetings => 'الاجتماعات';

  @override
  String get meetingsNoWorkspace => 'اختر مساحة عمل لعرض الاجتماعات.';

  @override
  String get meetingsEmpty => 'لا توجد اجتماعات بعد';

  @override
  String get meetingsEmptyHint =>
      'سجّل اجتماعك الأول — يبقى الصوت على هذا الجهاز ويحوّله الوكيل إلى ملاحظات وقرارات وبنود عمل.';

  @override
  String get meetingNotesHint =>
      'دوّن ملاحظات سريعة — يوسّعها الوكيل بعد الاجتماع.';

  @override
  String get meetingSpeakerMe => 'أنت';

  @override
  String get meetingStatusRecording => 'جارٍ التسجيل';

  @override
  String get meetingStatusProcessing => 'قيد المعالجة';

  @override
  String get meetingStatusDone => 'تم';

  @override
  String get meetingStatusFailed => 'فشل';

  @override
  String get meetingsSubtitle =>
      'يُسجَّل ويُفرَّغ نصيًا على هذا الجهاز، ثم يلخّصه وكيل.';

  @override
  String get meetingsRecordMeeting => 'تسجيل اجتماع';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count قيد المعالجة الآن',
      many: '$count قيد المعالجة الآن',
      few: '$count قيد المعالجة الآن',
      two: 'اثنان قيد المعالجة الآن',
      one: 'واحد قيد المعالجة الآن',
      zero: 'لا شيء قيد المعالجة الآن',
    );
    return '$_temp0';
  }

  @override
  String meetingsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count اجتماع',
      many: '$count اجتماعًا',
      few: '$count اجتماعات',
      two: 'اجتماعان',
      one: 'اجتماع واحد',
      zero: 'لا اجتماعات',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLedgerOpenActions => 'بنود عمل مفتوحة';

  @override
  String get meetingsLedgerDecisions => 'القرارات';

  @override
  String get meetingsLiveOpen => 'فتح التسجيل';

  @override
  String get meetingTemplateShort => 'قالب';

  @override
  String get meetingsStatThisWeek => 'هذا الأسبوع';

  @override
  String get meetingsStatRecorded => 'مسجَّلة';

  @override
  String get meetingsFilterAll => 'الكل';

  @override
  String get meetingsFilterDone => 'تم';

  @override
  String get meetingsFilterProcessing => 'قيد المعالجة';

  @override
  String get meetingsSearchHint => 'تصفية حسب العنوان أو الشخص أو التطبيق…';

  @override
  String get meetingsBucketToday => 'اليوم';

  @override
  String get meetingsBucketYesterday => 'أمس';

  @override
  String get meetingsBucketEarlierThisWeek => 'في وقت سابق هذا الأسبوع';

  @override
  String get meetingsBucketLastWeek => 'الأسبوع الماضي';

  @override
  String get meetingsBucketOlder => 'أقدم';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count قرار',
      many: '$count قرارًا',
      few: '$count قرارات',
      two: 'قراران',
      one: 'قرار واحد',
      zero: 'لا قرارات',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total من بنود العمل';
  }

  @override
  String get meetingsEnhancedPill => 'محسَّنة';

  @override
  String get meetingsTranscribing => 'جارٍ التفريغ والتلخيص…';

  @override
  String get meetingsOpenAction => 'فتح';

  @override
  String get meetingsStopProcessing => 'إيقاف';

  @override
  String get meetingsStillTranscribing =>
      'لا يزال التفريغ جاريًا — يظهر الملخص عند اكتماله.';

  @override
  String get meetingsNoMatch => 'لا توجد اجتماعات مطابقة';

  @override
  String get meetingsNoMatchHint => 'جرّب عامل تصفية أو كلمة بحث مختلفة.';

  @override
  String get meetingBackAllMeetings => 'كل الاجتماعات';

  @override
  String get meetingReRunSummary => 'إعادة تشغيل التلخيص';

  @override
  String get meetingExport => 'تصدير';

  @override
  String get meetingAugmentingBanner =>
      'جارٍ إثراء ملاحظاتك من التفريغ النصي — استخراج القرارات وبنود العمل…';

  @override
  String get meetingTabNotes => 'الملاحظات';

  @override
  String get meetingTabTranscript => 'التفريغ النصي';

  @override
  String get meetingTabActionItems => 'بنود العمل';

  @override
  String get meetingTabDecisions => 'القرارات';

  @override
  String get meetingNotesEnhancedToggle => 'محسَّنة';

  @override
  String get meetingNotesYoursToggle => 'ملاحظاتك';

  @override
  String get meetingEnhancedByAgent => 'حسّنها الوكيل · من التفريغ النصي';

  @override
  String get meetingEnhancedPending => 'لا يزال الوكيل يعمل على هذا الملخص.';

  @override
  String get meetingNotesEmpty => 'لا توجد ملاحظات محسَّنة بعد.';

  @override
  String get meetingNotesSavedLocally => 'محفوظة محليًا';

  @override
  String get meetingNotesSaving => 'جارٍ الحفظ…';

  @override
  String get meetingViewFullTranscript => 'عرض التفريغ النصي الكامل';

  @override
  String get meetingTranscriptSearchHint => 'البحث في التفريغ النصي…';

  @override
  String get meetingSpeakerEveryone => 'الجميع';

  @override
  String get meetingSpeakerOthers => 'آخرون';

  @override
  String get meetingTranscriptEmpty => 'لا يوجد تفريغ نصي بعد.';

  @override
  String get meetingActionItemsEmpty => 'لم تُستخرج أي بنود عمل.';

  @override
  String get meetingActionItemFrom => 'من هذا الاجتماع';

  @override
  String get meetingCreateTicket => 'إنشاء تذكرة';

  @override
  String meetingTicketCreated(String key) {
    return 'تم إنشاء التذكرة ⁨$key⁩ وإرسالها.';
  }

  @override
  String get meetingTicketFailed => 'تعذر إنشاء التذكرة.';

  @override
  String get meetingDecisionsEmpty => 'لم تُسجَّل أي قرارات.';

  @override
  String get meetingEditTitle => 'تحرير العنوان';

  @override
  String get meetingTitleLabel => 'العنوان';

  @override
  String get meetingAddActionItem => 'إضافة بند عمل';

  @override
  String get meetingEditActionItem => 'تحرير بند العمل';

  @override
  String get meetingDeleteActionItem => 'حذف بند العمل';

  @override
  String get meetingActionItemContentLabel => 'بند العمل';

  @override
  String get meetingActionItemContentHint => 'ما الذي يجب أن يحدث؟';

  @override
  String get meetingActionItemOwnerLabel => 'المالك';

  @override
  String get meetingActionItemOwnerHint => 'من المسؤول؟ (اختياري)';

  @override
  String get meetingAddDecision => 'إضافة قرار';

  @override
  String get meetingEditDecision => 'تحرير القرار';

  @override
  String get meetingDeleteDecision => 'حذف القرار';

  @override
  String get meetingDecisionContentLabel => 'القرار';

  @override
  String get meetingDecisionContentHint => 'ما الذي تقرر؟';

  @override
  String get meetingReRunStarted =>
      'جارٍ إعادة تشغيل الملخِّص على التفريغ النصي…';

  @override
  String get meetingReRunNoTranscript => 'لا يوجد تفريغ نصي لتلخيصه بعد.';

  @override
  String get meetingExportCopied =>
      'تم نسخ الملاحظات إلى الحافظة بتنسيق Markdown.';

  @override
  String get meetingExportSaved => 'تم تصدير الاجتماع.';

  @override
  String meetingExportFailed(String error) {
    return 'فشل التصدير: ⁨$error⁩';
  }

  @override
  String get meetingExportNothing => 'لا يوجد شيء للتصدير بعد.';

  @override
  String get meetingPlaybackPlay => 'تشغيل';

  @override
  String get meetingPlaybackPause => 'إيقاف مؤقت';

  @override
  String get meetingPlaybackUnavailable =>
      'تشغيل الصوت غير متاح على هذا الجهاز.';

  @override
  String get meetingDetectedTitle => 'تم رصد اجتماع';

  @override
  String meetingDetectedSubtitle(String label) {
    return 'يبدو أن \"$label\" يجري الآن. هل تريد تسجيله؟';
  }

  @override
  String get meetingDetectedSubtitleGeneric =>
      'يبدو أن اجتماعًا يجري الآن. هل تريد تسجيله؟';

  @override
  String get meetingDetectedRecord => 'تسجيل';

  @override
  String get meetingDetectedDismiss => 'تجاهل';

  @override
  String get meetingAutoStopTitle =>
      'يبدو أن هذا الاجتماع انتهى. هل تريد إيقاف التسجيل؟';

  @override
  String get meetingAutoStopStop => 'إيقاف';

  @override
  String get meetingAutoStopKeep => 'متابعة التسجيل';

  @override
  String get meetingAutoDetect => 'رصد الاجتماعات تلقائيًا';

  @override
  String get meetingAutoDetectDescription =>
      'مراقبة التقويم وتطبيقات الاجتماعات وعرض التسجيل عند بدء اجتماع.';

  @override
  String get meetingsRecordingCrumb => 'جارٍ التسجيل…';

  @override
  String get meetingRecordTitleHint => 'عنوان الاجتماع';

  @override
  String get meetingRecordTappingLabel => 'الالتقاط:';

  @override
  String get meetingRecordMic => 'الميكروفون';

  @override
  String get meetingRecordSystemAudio => 'صوت النظام';

  @override
  String get meetingRecordPause => 'إيقاف مؤقت';

  @override
  String get meetingRecordResume => 'استئناف';

  @override
  String get meetingRecordStop => 'إيقاف وتلخيص';

  @override
  String get meetingRecordYourNotes => 'ملاحظاتك';

  @override
  String get meetingRecordNotesPlaceholder =>
      'اكتب أثناء الاستماع. تكفي بضع عبارات — بعد الإيقاف، يوسّعها الوكيل باستخدام التفريغ النصي.';

  @override
  String get meetingRecordLiveTranscript => 'التفريغ النصي المباشر';

  @override
  String get meetingRecordDecoding => 'فك الترميز على الجهاز';

  @override
  String get meetingRecordListening =>
      'جارٍ الاستماع… يظهر الكلام هنا خلال ثانية أو اثنتين، موسومًا أنت / آخرون.';

  @override
  String get meetingRecordPausedHint =>
      'متوقف مؤقتًا — يتم تجاهل الصوت حتى تستأنف.';

  @override
  String get meetingRecordNotActive => 'لا يوجد تسجيل نشط.';

  @override
  String get meetingHudRecording => 'تسجيل';

  @override
  String get meetingHudPaused => 'متوقف مؤقتًا';

  @override
  String get meetingHudOpen => 'فتح';

  @override
  String get meetingHudStop => 'إيقاف';

  @override
  String get meetingToolbarPopOut => 'فصل النافذة';

  @override
  String get meetingToolbarHoldToStop => 'اضغط مطولًا لإيقاف التسجيل';

  @override
  String get meetingToolbarSemanticLabel => 'شريط أدوات تسجيل الاجتماع';

  @override
  String get orchestrate => 'تنسيق';

  @override
  String get orchestrationUnavailable => 'التنسيق غير متاح';

  @override
  String get orchestrationApprove => 'الموافقة على الخطة';

  @override
  String get orchestrationReject => 'رفض';

  @override
  String get orchestrationCancel => 'إلغاء التنسيق';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count أدوار — $hires تعيينات جديدة';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count تذاكر فرعية';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'التكلفة التقديرية: \$$amount';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return 'اكتمل $done/$total من التذاكر الفرعية';
  }

  @override
  String get orchestrationStatusProposed => 'مقترح';

  @override
  String get orchestrationStatusApproved => 'موافق عليه';

  @override
  String get orchestrationStatusExecuting => 'قيد التنفيذ';

  @override
  String get orchestrationStatusSynthesizing => 'قيد التجميع';

  @override
  String get orchestrationStatusCompleted => 'مكتمل';

  @override
  String get orchestrationStatusFailed => 'فشل';

  @override
  String get orchestrationStatusCancelled => 'ملغى';

  @override
  String get messageFailed => 'فشل التشغيل';

  @override
  String get turnLimitReached => 'توقف عند حد الأدوار — رُدّ للمتابعة';

  @override
  String get retried => 'أعيدت المحاولة';

  @override
  String replyingTo(String name) {
    return 'ردًا على $name';
  }

  @override
  String get silenceTimeoutLabel => 'مهلة الصمت (بالدقائق)';

  @override
  String get silenceTimeoutHint =>
      'مثال: 15 — إنهاء التشغيل بعد هذه المدة دون أي مخرجات';

  @override
  String get capabilityJsonMode => 'وضع JSON';

  @override
  String get capabilityModelSelection => 'اختيار النموذج';

  @override
  String get transcriptThinking => 'جارٍ التفكير…';

  @override
  String transcriptThoughtFor(String duration) {
    return 'فكّر لمدة $duration';
  }

  @override
  String get transcriptStatusMakingEdits => 'جارٍ إجراء التعديلات…';

  @override
  String get transcriptStatusReadingFiles => 'جارٍ قراءة الملفات…';

  @override
  String get transcriptStatusSearching => 'جارٍ البحث في قاعدة الكود…';

  @override
  String get transcriptStatusRunningCommands => 'جارٍ تنفيذ الأوامر…';

  @override
  String get transcriptStatusResponding => 'جارٍ الرد…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return 'جارٍ تشغيل ⁨$tool⁩…';
  }

  @override
  String get transcriptInput => 'الإدخال';

  @override
  String get transcriptOutput => 'الإخراج';

  @override
  String get transcriptErrorLabel => 'خطأ';

  @override
  String get transcriptSandboxBlocked => 'حظرت البيئة المعزولة إجراءً';

  @override
  String transcriptShowFullOutput(int kb) {
    return 'عرض الإخراج الكامل (+$kb كيلوبايت)';
  }

  @override
  String transcriptShowAllLines(int count) {
    return 'عرض جميع الأسطر ($count)';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return 'عرض أول $count من الأسطر';
  }

  @override
  String get transcriptGrepNoMatches => 'لا توجد نتائج مطابقة';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '$matches نتيجة',
      many: '$matches نتيجة',
      few: '$matches نتائج',
      two: 'نتيجتان',
      one: 'نتيجة واحدة',
      zero: 'لا نتائج',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files ملف',
      many: '$files ملفًا',
      few: '$files ملفات',
      two: 'ملفان',
      one: 'ملف واحد',
      zero: 'لا ملفات',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return 'الشخص $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => 'إعادة تسمية المتحدث';

  @override
  String get meetingRenameSpeakerTitle => 'إعادة تسمية المتحدث';

  @override
  String get meetingSpeakerNameLabel => 'الاسم';

  @override
  String get meetingSpeakerSuggestFromCalendar => 'من المدعوين في هذا الاجتماع';

  @override
  String get meetingRenameSpeakerApplyAll => 'التطبيق على كل مقاطع هذا المتحدث';

  @override
  String get meetingRenameSpeakerScopeHint =>
      'عند الإيقاف، تُعاد تسمية السطر المحدد فقط.';

  @override
  String get meetingLinkEvent => 'ربط بحدث';

  @override
  String get meetingChangeEvent => 'تغيير الحدث';

  @override
  String get meetingLinkEventTitle => 'الربط بحدث في التقويم';

  @override
  String get meetingLinkEventSearchHint => 'البحث في الأحداث';

  @override
  String get meetingLinkEventEmpty => 'لا توجد أحداث تقويم قريبة';

  @override
  String get meetingUnlinkEvent => 'إزالة الربط';

  @override
  String get calendarLinkExistingMeeting => 'ربط باجتماع موجود';

  @override
  String get calendarLinkMeetingTitle => 'ربط اجتماع';

  @override
  String get calendarLinkMeetingSearchHint => 'البحث في الاجتماعات';

  @override
  String get calendarLinkMeetingEmpty => 'لا توجد اجتماعات للربط';

  @override
  String get meetingRenameSpeakerFailed => 'تعذر إعادة تسمية المتحدث';

  @override
  String get calendarLinkUpdateFailed => 'تعذر تحديث ربط التقويم';

  @override
  String get rename => 'إعادة تسمية';

  @override
  String get notNow => 'ليس الآن';

  @override
  String get meetingSaveVoiceProfileTitle => 'هل تريد حفظ ملف تعريف الصوت؟';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return 'التعرف على $name تلقائيًا في الاجتماعات القادمة عبر حفظ بصمة صوته.';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return 'تم حفظ ملف تعريف الصوت لـ $name';
  }

  @override
  String get meetingVoiceProfileSaveFailed => 'تعذر حفظ ملف تعريف الصوت';

  @override
  String get voiceProfilesSection => 'ملفات تعريف الصوت';

  @override
  String get voiceProfilesDescription =>
      'يتم التعرف تلقائيًا على الأصوات المحفوظة في الاجتماعات القادمة.';

  @override
  String get voiceProfilesEmpty =>
      'لا توجد أصوات محفوظة بعد. سمِّ متحدثًا في تفريغ اجتماع، ثم اختر \"حفظ ملف تعريف الصوت\".';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عينة',
      many: '$count عينة',
      few: '$count عينات',
      two: 'عينتان',
      one: 'عينة واحدة',
      zero: 'لا عينات',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => 'إعادة تسمية ملف تعريف الصوت';

  @override
  String get deleteVoiceProfileTitle => 'هل تريد حذف ملف تعريف الصوت؟';

  @override
  String deleteVoiceProfileBody(String name) {
    return 'هل تريد إيقاف التعرف على $name؟ ستُزال بصمة صوته المحفوظة. تبقى الأسماء المطبَّقة في الاجتماعات السابقة كما هي.';
  }

  @override
  String get connectedLabel => 'متصل';

  @override
  String get ideTabGeneral => 'عام';

  @override
  String get ideTabExplorer => 'المستكشف';

  @override
  String get ideTabSourceControl => 'التحكم بالمصدر';

  @override
  String get generalSectionTodos => 'المهام';

  @override
  String get generalSectionGoals => 'الأهداف';

  @override
  String get goalRunStatusActive => 'نشط';

  @override
  String get goalRunStatusPaused => 'متوقف مؤقتًا';

  @override
  String get goalRunStatusCompleted => 'مكتمل';

  @override
  String get goalRunStatusFailed => 'فشل';

  @override
  String get goalRunStatusCancelled => 'ملغى';

  @override
  String get goalRunStatusBudgetExhausted => 'استُنفدت الميزانية';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return 'التشغيل $run من $max · $cost من $cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return 'التشغيل $run · $cost من $cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return 'الموعد النهائي $deadline';
  }

  @override
  String get goalRunPause => 'إيقاف الهدف مؤقتًا';

  @override
  String get goalRunResume => 'استئناف الهدف';

  @override
  String goalRunResumeRaise(String cap) {
    return 'استئناف · رفع الحد الأقصى إلى $cap';
  }

  @override
  String get goalRunStop => 'إيقاف الهدف';

  @override
  String get generalSectionAgents => 'الوكلاء';

  @override
  String get generalSectionTerminals => 'الطرفيات';

  @override
  String get generalTodosEmpty => 'لا توجد مهام بعد';

  @override
  String get generalAgentsEmpty => 'لا يوجد وكلاء قيد التشغيل';

  @override
  String get generalTerminalsEmpty => 'لا توجد طرفيات مفتوحة';

  @override
  String get generalSectionBrowsers => 'المتصفحات';

  @override
  String get generalSectionComputers => 'أجهزة الكمبيوتر';

  @override
  String get generalBrowsersEmpty => 'لا توجد متصفحات مفتوحة';

  @override
  String get generalComputersEmpty => 'لا توجد أجهزة كمبيوتر مفتوحة';

  @override
  String get generalSectionPhones => 'الهواتف';

  @override
  String get generalPhonesEmpty => 'لا توجد هواتف مفتوحة';

  @override
  String get pauseAgent => 'إيقاف الوكيل مؤقتًا';

  @override
  String get resumeAgent => 'استئناف الوكيل';

  @override
  String get agentCannotPause =>
      'لا يمكن إيقاف هذا الوكيل مؤقتًا — أوقفه نهائيًا بدلًا من ذلك.';

  @override
  String get goalClear => 'مسح الهدف';

  @override
  String get undoLabelGoalClear => 'مسح الهدف';

  @override
  String get todoStatusPending => 'لم يبدأ';

  @override
  String get todoStatusInProgress => 'قيد التنفيذ';

  @override
  String get todoStatusCompleted => 'تم';

  @override
  String get reorderTodo => 'إعادة ترتيب المهمة';

  @override
  String get focusTerminal => 'التركيز على الطرفية';

  @override
  String get focusMachine => 'التركيز على الجهاز';

  @override
  String get focusBrowser => 'التركيز على المتصفح';

  @override
  String get todoEditorTitle => 'تحرير المهام';

  @override
  String get todoEditorHint =>
      'عنصر واحد في كل سطر. استخدم ⁨- [ ]⁩ لما لم يبدأ، و⁨- [~]⁩ لقيد التنفيذ، و⁨- [x]⁩ لما تم.';

  @override
  String get todoNeedsText => 'أضف نصًا بعد الأمر';

  @override
  String get todoNotFound => 'لا توجد مهمة مطابقة';

  @override
  String get todoCleared => 'تم مسح قائمة المهام';

  @override
  String get todoNothingToCopy => 'لا يوجد شيء للنسخ';

  @override
  String todoAdded(String content) {
    return 'تمت إضافة \"$content\"';
  }

  @override
  String todoStarted(String content) {
    return 'تم بدء \"$content\"';
  }

  @override
  String todoCompleted(String content) {
    return 'تم إكمال \"$content\"';
  }

  @override
  String todoRemoved(String content) {
    return 'تمت إزالة \"$content\"';
  }

  @override
  String todoCopied(int count) {
    return 'تم نسخ $count من العناصر';
  }

  @override
  String todoImported(int count) {
    return 'تم استيراد $count من العناصر';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return 'أمر مهام غير معروف \"⁨$name⁩\"';
  }

  @override
  String get terminal => 'الطرفية';

  @override
  String get ideCloseTab => 'إغلاق علامة التبويب';

  @override
  String get ideSplitEditor => 'تقسيم المحرر';

  @override
  String get ideSplitRight => 'تقسيم لليمين';

  @override
  String get ideSplitDown => 'تقسيم للأسفل';

  @override
  String get ideSplitLeft => 'تقسيم لليسار';

  @override
  String get ideSplitUp => 'تقسيم للأعلى';

  @override
  String get ideCloseGroup => 'إغلاق المجموعة';

  @override
  String get ideCloseOthers => 'إغلاق الأخرى';

  @override
  String get ideCloseToRight => 'إغلاق ما إلى اليمين';

  @override
  String get ideCloseSaved => 'إغلاق المحفوظة';

  @override
  String get ideCloseAll => 'إغلاق الكل';

  @override
  String get ideSplit => 'تقسيم';

  @override
  String get ideToggleSidebar => 'تبديل الشريط الجانبي';

  @override
  String get ideNewTab => 'فتح محرر';

  @override
  String get ideNewTabMenu => 'علامة تبويب جديدة';

  @override
  String get ideReviewCode => 'مراجعة الكود';

  @override
  String ideReviewCodeInRepo(String repo) {
    return 'مراجعة الكود (⁨$repo⁩)';
  }

  @override
  String get ideRevertConfirmTitle => 'إرجاع التغييرات';

  @override
  String get ideRevertUntracked => 'لا يمكن إرجاع الملفات غير المتتبعة';

  @override
  String get ideRevertFailed =>
      'تعذر إرجاع الملفات. قد تكون شجرة عمل المحادثة غير متاحة.';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملف',
      many: '$count ملفًا',
      few: '$count ملفات',
      two: 'ملفين',
      one: 'ملف واحد',
      zero: '0 ملفات',
    );
    return 'تعذر إرجاع $_temp0 (غير متتبعة).';
  }

  @override
  String get ideSearchMatchCase => 'مطابقة حالة الأحرف';

  @override
  String get ideSearchWholeWord => 'الكلمة كاملة';

  @override
  String get ideSearchRegex => 'تعبير نمطي';

  @override
  String get ideSearchFilters => 'عوامل تصفية البحث';

  @override
  String get ideSearchFilesToInclude => 'ملفات للتضمين';

  @override
  String get ideSearchFilesToExclude => 'ملفات للاستبعاد';

  @override
  String get ideNoOpenTabs => 'لا توجد علامات تبويب مفتوحة — استخدم + للفتح';

  @override
  String get ideBrowserAddressHint => 'أدخل عنوانًا أو ابحث';

  @override
  String get ideSimpleWebBrowser => 'متصفح ويب بسيط';

  @override
  String get ideWebBrowser => 'متصفح الويب';

  @override
  String get ideBrowserEnterUrl =>
      'أدخل عنوان URL في شريط العناوين لبدء التصفح';

  @override
  String get ideCodeServer => 'المحرر';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return 'هل تريد حفظ التغييرات في ⁨$fileName⁩؟';
  }

  @override
  String get ideUnsavedChangesBody => 'ستفقد تغييراتك إذا لم تحفظها.';

  @override
  String get ideDontSave => 'عدم الحفظ';

  @override
  String get editorAutoSave => 'الحفظ التلقائي';

  @override
  String get editorAutoSaveDescription =>
      'حفظ التغييرات تلقائيًا في المحرر المضمّن.';

  @override
  String get editorAutoSaveOff => 'إيقاف';

  @override
  String get editorAutoSaveAfterDelay => 'بعد مهلة';

  @override
  String get editorAutoSaveOnFocusChange => 'عند تغيّر التركيز';

  @override
  String get ideCodeServerUnavailable => 'code-server غير متاح على هذا الخادم';

  @override
  String get ideCodeServerUnavailableHint =>
      'ثبّت code-server ‏(coder/code-server) على مضيف الخادم، ثم أعد فتح المحرر.';

  @override
  String get ideCodeServerInstalling => 'جارٍ تجهيز المحرر…';

  @override
  String get ideCodeServerOpenInBrowser => 'فتح المحرر في المتصفح';

  @override
  String get ideCodeServerError => 'تعذر فتح المحرر';

  @override
  String get paneSuspendedCaption =>
      'معلّق لتوفير الموارد — يُعاد تحميله عند التركيز عليه';

  @override
  String get ideFolderLoadFailed => 'تعذر تحميل هذا المجلد';

  @override
  String get ideFileSearchFailed => 'تعذر البحث في الملفات';

  @override
  String get ideSearchInFiles => 'البحث في الملفات';

  @override
  String get ideNoContentMatches => 'لا توجد نتائج مطابقة';

  @override
  String get ideSourceControlCreatePr => 'إنشاء طلب سحب';

  @override
  String ideSourceControlViewPr(int number) {
    return 'عرض طلب السحب ⁨#$number⁩';
  }

  @override
  String get ideSourceControlNoChanges => 'لا توجد تغييرات';

  @override
  String get noReposInConversation => 'لا توجد مستودعات في هذه المحادثة';

  @override
  String get ideSourceControlNoSpace => 'افتح محادثة لعرض تغييراتها';

  @override
  String get ideFileLoading => 'جارٍ التحميل…';

  @override
  String get ideFileBinary => 'ملف ثنائي';

  @override
  String get mcpExternalServers => 'خوادم MCP خارجية';

  @override
  String get mcpExternalServersDescription =>
      'الاتصال بخوادم MCP خارجية (GitHub وSentry وPostgres وأتمتة المتصفح). تُكتشف تلقائيًا الخوادم التي كوّنتها لأدوات Claude وCursor وVS Code وغيرها.';

  @override
  String get mcpApprovalMode => 'الموافقة على الأدوات';

  @override
  String get mcpApprovalModeDescription =>
      'أي إجراءات الأدوات تعمل دون سؤال. القراءات مسموح بها دائمًا؛ والمستويات الأعلى تطلب الموافقة.';

  @override
  String get mcpApprovalAlwaysAsk => 'السؤال دائمًا';

  @override
  String get mcpApprovalWrite => 'الموافقة التلقائية على الكتابات';

  @override
  String get mcpApprovalYolo => 'الموافقة التلقائية على الكل';

  @override
  String get mcpNoExternalServers => 'لم تُكتشف أي خوادم MCP خارجية.';

  @override
  String get mcpAuthorize => 'تفويض';

  @override
  String get mcpReconnect => 'إعادة الاتصال';

  @override
  String get mcpExternalConnectionsNote =>
      'تعمل خوادم MCP الخارجية على خادم الوكلاء (مشترك بين سطح المكتب والويب). تفويض خوادم OAuth متاح على سطح المكتب فقط.';

  @override
  String get mcpStatusConnected => 'متصل';

  @override
  String get mcpStatusConnecting => 'جارٍ الاتصال…';

  @override
  String get mcpStatusNeedsAuth => 'يحتاج إلى تفويض';

  @override
  String get mcpStatusFailed => 'فشل';

  @override
  String get mcpStatusCircuitOpen => 'متوقف مؤقتًا';

  @override
  String get mcpStatusDisabled => 'معطّل';

  @override
  String get providersAndModels => 'الموفّرون والنماذج';

  @override
  String get providersAndModelsDescription =>
      'اسرد كل موفّر يمكن للوكيل المدمج استخدامه — عيّن مفتاح API أو سجّل الدخول عبر المتصفح، واطّلع على نماذج كل موفّر متصل وأسعاره، وتحكّم في الموفّرين المسموح باستخدامهم في مساحة العمل هذه.';

  @override
  String get syncNow => 'المزامنة الآن';

  @override
  String syncNowResult(int applied, int failed) {
    return 'اكتملت المزامنة — تم تطبيق $applied وفشل $failed';
  }

  @override
  String syncNowFailed(String error) {
    return 'فشلت المزامنة: ⁨$error⁩';
  }

  @override
  String get denied => 'مرفوض';

  @override
  String get allowed => 'مسموح';

  @override
  String allowProviderSemantic(String provider) {
    return 'السماح لـ $provider';
  }

  @override
  String enabledViaEnv(String key) {
    return 'مفعّل عبر ⁨$key⁩';
  }

  @override
  String costPerMillion(String input, String output) {
    return '⁨$input / $output⁩ لكل مليون';
  }

  @override
  String contextTokens(String tokens) {
    return 'سياق $tokens';
  }

  @override
  String get usageAndCost => 'الاستخدام والتكلفة';

  @override
  String get usageAndCostDescription =>
      'الإنفاق عبر وكلائك خلال الأيام السبعة الماضية، بناءً على تكاليف التشغيل المرصودة.';

  @override
  String get noUsageYet => 'لم يُسجَّل أي استخدام بعد.';

  @override
  String get spentThisWeek => 'أُنفق هذا الأسبوع';

  @override
  String get subscriptionUsage => 'استخدام الاشتراك';

  @override
  String get subscriptionUsageUnavailable => 'غير متاح';

  @override
  String get subscriptionUsageExhausted => 'استُنفدت الحصة';

  @override
  String get subscriptionUsageSignInRequired => 'سجّل الدخول مرة أخرى';

  @override
  String get subscriptionUsageSignInExpired =>
      'انتهت صلاحية تسجيل الدخول، يتجدد عند التشغيل التالي';

  @override
  String get subscriptionUsagePartiallyAvailable => 'متاح جزئيًا';

  @override
  String resetsIn(String duration) {
    return 'يُعاد التعيين خلال $duration';
  }

  @override
  String get feedbackHelpful => 'كان هذا مفيدًا';

  @override
  String get feedbackNotHelpful => 'لم يكن هذا مفيدًا';

  @override
  String get modeChat => 'دردشة';

  @override
  String get modePlan => 'تخطيط';

  @override
  String get modeReview => 'مراجعة';

  @override
  String get modeOrchestrate => 'تنسيق';

  @override
  String get editorTheme => 'سمة المحرر';

  @override
  String get editorThemeDescription =>
      'استورد سمة ألوان VS Code لكي يطابق المحرر وعارض الفروق المضمّنان بيئة التطوير لديك.';

  @override
  String get editorThemePasteHint => 'الصق محتويات ملف JSON لسمة ألوان VS Code';

  @override
  String get editorThemeImported => 'تم استيراد السمة';

  @override
  String get editorThemeInvalid => 'لا يبدو أن هذه سمة VS Code صالحة';

  @override
  String get importTheme => 'استيراد السمة';

  @override
  String get clearTheme => 'مسح السمة';

  @override
  String get openInDiffViewer => 'فتح في عارض الفروق';

  @override
  String get shellCommand => 'الأمر';

  @override
  String get shellOutput => 'الإخراج';

  @override
  String get revertToHere => 'التراجع إلى هنا';

  @override
  String get revertConfirmBody =>
      'هل تريد إخفاء الرسائل بعد هذه النقطة وإرجاع تغييرات ملفات الوكيل إلى هذا الدور؟ يمكنك التراجع عن ذلك.';

  @override
  String get revert => 'تراجع';

  @override
  String get revertedToHere => 'تم التراجع إلى هنا';

  @override
  String get nothingToRevert => 'لا شيء للتراجع عنه';

  @override
  String get undoRevert => 'إلغاء التراجع';

  @override
  String get revertUndone => 'أُلغي التراجع';

  @override
  String get systemBehavior => 'سلوك النظام';

  @override
  String get keepAwakeTitle => 'إبقاء الكمبيوتر مستيقظًا أثناء تشغيل الوكلاء';

  @override
  String get keepAwakeOnSubtitle =>
      'لن يدخل الكمبيوتر في وضع السكون أثناء عمل وكيل';

  @override
  String get keepAwakeOffSubtitle =>
      'قد يدخل الكمبيوتر في وضع السكون حتى أثناء عمل وكيل';

  @override
  String get syncEngineSectionTitle => 'محرك المزامنة';

  @override
  String get syncEngineDescription =>
      'تُحدَّث التذاكر والمراسلة والملاحظات مباشرةً عبر تغييرات تزايدية صغيرة بدلًا من اللقطات الكاملة. إيقاف أحد المفاتيح يعيد ذلك المخزن إلى وضع اللقطات الكاملة — أعد تحميل التطبيق ليسري التغيير.';

  @override
  String get syncEngineTicketsTitle => 'التذاكر';

  @override
  String get syncEngineMessagingTitle => 'المراسلة';

  @override
  String get syncEngineNotesTitle => 'الملاحظات';

  @override
  String get syncEngineOnSubtitle => 'مزامنة الفروق المباشرة نشطة';

  @override
  String get syncEngineOffSubtitle => 'تُستخدم مزامنة اللقطات الكاملة';

  @override
  String get spaces => 'المساحات';

  @override
  String get spacesHomeDescription =>
      'اختر مساحة من القائمة، أو ابدأ مساحة جديدة.';

  @override
  String get noSpacesYet => 'لا توجد مساحات بعد';

  @override
  String get newSpace => 'مساحة جديدة';

  @override
  String get spaceName => 'اسم المساحة';

  @override
  String get spaceReposHint => 'المستودعات المراد تضمينها';

  @override
  String get ideSourceControl => 'إدارة المصادر';

  @override
  String get stagedChanges => 'التغييرات المُدرجة';

  @override
  String get changes => 'التغييرات';

  @override
  String get stageFile => 'إدراج';

  @override
  String get unstageFile => 'إلغاء الإدراج';

  @override
  String get stageAll => 'إدراج كل التغييرات';

  @override
  String get unstageAll => 'إلغاء إدراج الكل';

  @override
  String get stageChangesToCommit => 'أدرج التغييرات لإيداعها';

  @override
  String get syncToPrHead => 'سحب أحدث إيداعات PR';

  @override
  String get syncedToPrHead => 'تمت المزامنة مع أحدث إيداعات PR';

  @override
  String get syncPrHeadDirty => 'أودع تغييراتك أو تجاهلها قبل المزامنة';

  @override
  String get syncPrHeadFailed => 'تعذّرت المزامنة مع رأس PR';

  @override
  String get spaceLabel => 'مساحة';

  @override
  String get keybindingNewSpace => 'مساحة جديدة';

  @override
  String get keybindingCreateANewSpaceDescription => 'إنشاء مساحة جديدة';

  @override
  String get jumpToLatest => 'الانتقال إلى الأحدث';

  @override
  String get streaming => 'يجري البث';

  @override
  String get newMessages => 'جديد';

  @override
  String get copyLink => 'نسخ الرابط';

  @override
  String get linkCopied => 'تم نسخ الرابط';

  @override
  String get agentResponding => 'الوكيل يرد';

  @override
  String get agentFinished => 'انتهى الوكيل';

  @override
  String get harnessConnectProviderForModels => 'اربط مزودًا لعرض النماذج.';

  @override
  String get providerSignOut => 'تسجيل الخروج';

  @override
  String get providerWaitingForDeviceCode =>
      'في انتظار تأكيدك للرمز في المتصفح…';

  @override
  String get providerDeviceCodeHint =>
      'تحقق من تطابق هذا الرمز مع الرمز المعروض في متصفحك، ثم وافق.';

  @override
  String get providerPlanUsageLoading => 'يجري التحقق من استخدام الخطة…';

  @override
  String get providerPlanUsageUnavailable => 'لم تُبلغ هذه الخطة عن الاستخدام.';

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return 'هل تريد إزالة مفتاح API الخاص بـ $provider؟';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return 'يُحذف المفتاح المخزّن ولا يمكن عرضه مجددًا. يتوقف الوكلاء الذين يستخدمون نماذج $provider عن العمل حتى تلصق مفتاحًا جديدًا.';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return 'هل تريد إزالة $provider؟';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return 'يُحذف المزود $provider ومفتاحه المخزّن. يتوقف الوكلاء المثبّتون على نماذجه عن العمل.';
  }

  @override
  String get providerApiKeyHint => 'الصق مفتاح API';

  @override
  String get providerApiKeyStoredHint => 'الصق مفتاح API آخر لإضافته';

  @override
  String get providerAddAnotherAccount => 'إضافة حساب آخر';

  @override
  String get providerActiveBadge => 'نشط';

  @override
  String get providerOauthAccountFallback => 'حساب OAuth';

  @override
  String get providerApiKeyFallback => 'مفتاح API';

  @override
  String get providerRemoveCredentialConfirmTitle =>
      'هل تريد إزالة بيانات الاعتماد هذه؟';

  @override
  String get providerSignOutAccountConfirmTitle =>
      'هل تريد تسجيل الخروج من هذا الحساب؟';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return 'يعود الوكلاء الذين يستخدمون $provider إلى مفاتيحه وحساباته الأخرى. وإن لم يتبقَّ أي منها، فسيتوقفون حتى تضيف واحدًا.';
  }

  @override
  String get providerBaseUrlHint => 'عنوان URL الأساسي (اختياري)';

  @override
  String get addProvider => 'إضافة مزود';

  @override
  String get noCustomProviders => 'لا يوجد مزودون مخصصون بعد.';

  @override
  String get providerNameLabel => 'الاسم';

  @override
  String get apiTypeLabel => 'نوع API';

  @override
  String get providerBaseUrlLabel => 'عنوان URL الأساسي';

  @override
  String get providerApiKeyOptionalHint => 'مفتاح API (اختياري)';

  @override
  String get dialectOpenAiCompatible => 'متوافق مع OpenAI';

  @override
  String get dialectAnthropicCompatible => 'متوافق مع Anthropic';

  @override
  String get removeProviderTooltip => 'إزالة المزود';

  @override
  String get providerLogInWithBrowser => 'تسجيل الدخول عبر المتصفح';

  @override
  String providerLoginDialogTitle(String provider) {
    return 'تسجيل الدخول إلى $provider';
  }

  @override
  String get providerLabel => 'المزود';

  @override
  String get selectProviderToLogin => 'اختر مزودًا لتسجيل الدخول';

  @override
  String providerLoginFailed(String error) {
    return 'فشل تسجيل الدخول: ⁨$error⁩';
  }

  @override
  String get providerWaitingForBrowser => 'في انتظار تفويضك في المتصفح…';

  @override
  String get providerPasteCodeHint => 'أو الصق الرمز من متصفحك';

  @override
  String get providerCompleteLogin => 'إكمال';

  @override
  String get providerConnectedApiKey => 'متصل عبر مفتاح API';

  @override
  String get providerConnectedOauth => 'متصل';

  @override
  String providerConnectedAccount(String account) {
    return 'متصل · ⁨$account⁩';
  }

  @override
  String get providerLocalReady => 'محلي · جاهز';

  @override
  String get providerNotConnected => 'غير متصل';

  @override
  String get preparingWorkspace => 'يجري تجهيز مساحة العمل…';

  @override
  String provisioningRunningSetupScript(String repo) {
    return 'يجري تشغيل سكربت الإعداد لـ ⁨$repo⁩…';
  }

  @override
  String get repoScriptsTitle => 'السكربتات';

  @override
  String get repoScriptsTooltip => 'تكوين سكربتات دورة الحياة';

  @override
  String get repoScriptsSetupLabel => 'سكربت الإعداد';

  @override
  String get repoScriptsSetupHelp =>
      'يعمل في شجرة عمل المساحة فور إنشائها — لتثبيت التبعيات وتوليد الملفات. الفشل يضع علامة فاشلة على المساحة؛ وإعادة المحاولة تشغّله من جديد.';

  @override
  String get repoScriptsArchiveLabel => 'سكربت الأرشفة';

  @override
  String get repoScriptsArchiveHelp =>
      'يعمل قبل حذف شجرة عمل المساحة مباشرةً — لتنظيف الموارد خارج شجرة العمل. الفشل لا يمنع الحذف أبدًا.';

  @override
  String get repoScriptsEnvHelp =>
      'يعمل عبر bash من شجرة العمل، مع تعيين CC_WORKSPACE_PATH (شجرة العمل) وCC_ROOT_PATH (جذر المستودع) وCC_SPACE_ID وCC_SPACE_NAME وCC_REPO_NAME.';

  @override
  String get repoScriptsSetupPlaceholder => 'مثال: pnpm install';

  @override
  String get repoScriptsArchivePlaceholder =>
      'مثال: docker compose -p \$CC_SPACE_ID down';

  @override
  String get repoScriptsRecentRuns => 'عمليات التشغيل الأخيرة';

  @override
  String get repoScriptsNoRuns => 'لا توجد عمليات تشغيل بعد';

  @override
  String get repoScriptsSaved => 'تم حفظ السكربتات';

  @override
  String get repoScriptsRunKindSetup => 'إعداد';

  @override
  String get repoScriptsRunKindArchive => 'أرشفة';

  @override
  String get repoScriptsRunStatusRunning => 'قيد التشغيل';

  @override
  String get repoScriptsRunStatusSucceeded => 'نجح';

  @override
  String get repoScriptsRunStatusFailed => 'فشل';

  @override
  String get repoScriptsRunStatusTimedOut => 'انتهت المهلة';

  @override
  String repoScriptsExitCode(int code) {
    return 'رمز الخروج $code';
  }

  @override
  String provisioningCloningRepo(String repo) {
    return 'يجري استنساخ ⁨$repo⁩…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return 'يجري تجهيز طلب السحب في ⁨$repo⁩…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return 'يجري إعداد الوكيل $agent…';
  }

  @override
  String get workspacePrepFailed => 'فشل إعداد مساحة العمل';

  @override
  String get workspacePrepStopped => 'توقف إعداد مساحة العمل';

  @override
  String get stopWorkspacePrep => 'إيقاف التجهيز';

  @override
  String get stopWorkspacePrepTooltip => 'إيقاف تجهيز مساحة العمل هذه';

  @override
  String get stopWorkspacePrepConfirm =>
      'هل تريد إيقاف تجهيز مساحة العمل هذه؟ يُتجاهل الاستنساخ الجاري — يمكنك بدؤه من جديد من هنا.';

  @override
  String messageWillSendWhenReady(int count) {
    return 'سيتم إرسال $count من الرسائل عند الجاهزية';
  }

  @override
  String get membersNav => 'الأعضاء';

  @override
  String get membersSettingsDescription =>
      'الأشخاص الذين يملكون وصولًا إلى مساحة العمل هذه: القائمة والدعوات وسجل التدقيق';

  @override
  String get memberRosterLabel => 'قائمة الأعضاء';

  @override
  String get memberRepoAccessAction => 'الوصول إلى المستودعات';

  @override
  String memberRepoAccessTitle(String name) {
    return 'وصول $name إلى المستودعات';
  }

  @override
  String get roleOwner => 'مالك';

  @override
  String get roleAdmin => 'مسؤول';

  @override
  String get roleMember => 'عضو';

  @override
  String get roleViewer => 'مشاهد';

  @override
  String get roleGuest => 'ضيف';

  @override
  String get removeMemberTitle => 'إزالة عضو';

  @override
  String removeMemberConfirm(String name) {
    return 'هل تريد إزالة $name من مساحة العمل هذه؟ سيفقد الوصول فورًا.';
  }

  @override
  String get transferOwnershipAction => 'نقل الملكية';

  @override
  String get transferOwnershipTitle => 'نقل الملكية';

  @override
  String transferOwnershipConfirm(String name) {
    return 'هل تريد جعل $name مالكًا لمساحة العمل هذه؟ ستصبح مسؤولًا. المالك وحده يمكنه حذف مساحة العمل أو تغيير دور مسؤول آخر.';
  }

  @override
  String get transferOwnershipCta => 'نقل';

  @override
  String get auditTrailLabel => 'سجل تدقيق التفويض';

  @override
  String get auditTrailDescription =>
      'كل سماح ورفض، مرتبط بسلسلة تجزئة بحيث يمكن اكتشاف أي إدخال معدّل أو محذوف.';

  @override
  String get auditVerifyChain => 'التحقق من السلسلة';

  @override
  String auditChainIntact(int count) {
    return 'السلسلة سليمة — تم التحقق من $count من الإدخالات';
  }

  @override
  String auditChainBroken(int seq, String reason) {
    return 'السلسلة مكسورة عند الإدخال $seq: ⁨$reason⁩';
  }

  @override
  String get auditEmpty => 'لم تُسجّل أي قرارات بعد.';

  @override
  String get auditDenied => 'مرفوض';

  @override
  String get auditAllowed => 'مسموح';

  @override
  String auditOnBehalfOf(String user) {
    return 'لصالح $user';
  }

  @override
  String get policyTemplatesLabel => 'قوالب السياسات';

  @override
  String get policyTemplatesDescription =>
      'طبّق وضعية بداية، أو انقل واحدة بين مساحات العمل.';

  @override
  String get policyTemplateStrict => 'صارم';

  @override
  String get policyTemplateBalanced => 'متوازن';

  @override
  String get policyTemplatePermissive => 'متساهل';

  @override
  String get policyTemplateApply => 'تطبيق';

  @override
  String policyTemplateApplied(int count) {
    return 'تم تطبيق $count من القواعد';
  }

  @override
  String get policyExport => 'نسخ السياسة';

  @override
  String get policyExported => 'تم نسخ السياسة إلى الحافظة';

  @override
  String get policyImport => 'لصق السياسة';

  @override
  String policyImported(int count) {
    return 'تم استيراد $count من القواعد';
  }

  @override
  String get approveAndRemember => 'الموافقة لمدة 8 ساعات';

  @override
  String get approveAndRememberTooltip =>
      'يوافق على هذا الإجراء ويتوقف عن السؤال عن إجراءات مماثلة في هذه المساحة لمدة 8 ساعات. تنتهي صلاحيته تلقائيًا.';

  @override
  String get unknownUserLabel => 'مستخدم غير معروف';

  @override
  String get inviteMember => 'دعوة عضو';

  @override
  String get inviteRepoAccessHeader => 'الوصول إلى المستودعات';

  @override
  String get inviteRepoAccessExplainer =>
      'لا يُشارك مع المدعو إلا المستودعات التي تحددها، وبالمستوى الذي تختاره. يبقى كل شيء آخر مخفيًا.';

  @override
  String get grantLevelRead => 'قراءة';

  @override
  String get grantLevelReview => 'مراجعة';

  @override
  String get grantLevelWrite => 'كتابة';

  @override
  String get inviteExpiryLabel => 'تنتهي الصلاحية خلال';

  @override
  String get expiryOneDay => 'يوم واحد';

  @override
  String get expirySevenDays => '7 أيام';

  @override
  String get expiryThirtyDays => '30 يومًا';

  @override
  String get createInviteAction => 'إنشاء دعوة';

  @override
  String get inviteOneTimeCodeLabel => 'رمز لمرة واحدة';

  @override
  String get inviteCodeShownOnce =>
      'يُعرض هذا الرمز مرة واحدة فقط — انسخه الآن.';

  @override
  String get inviteLinkLabel => 'رابط الدعوة';

  @override
  String get inviteRedeemHint =>
      'شارك الرمز مع المدعو؛ وسيستخدمه مع عنوان URL لخادمك.';

  @override
  String get inviteScanQr => 'أو امسح الرمز للاستخدام';

  @override
  String get inviteLoopbackWarningTitle => 'الدعوة تشير إلى عنوان محلي';

  @override
  String get inviteLoopbackWarningBody =>
      'لن يتمكن المتعاونون على أجهزة أخرى من الوصول إلى هذا الخادم. ابدأ نفقًا (الإعدادات ← عمليات التكامل ← مشاركة هذا الخادم) أو اربط الخادم بشبكتك ليتمكن المستخدمون خارج المضيف من الاتصال.';

  @override
  String get inviteStatusOpen => 'مفتوحة';

  @override
  String get inviteStatusUsed => 'مستخدمة';

  @override
  String get inviteStatusRevoked => 'ملغاة';

  @override
  String get inviteStatusExpired => 'منتهية الصلاحية';

  @override
  String inviteCreatedTime(String time) {
    return 'أُنشئت $time';
  }

  @override
  String inviteExpiresOn(String date) {
    return 'تنتهي الصلاحية $date';
  }

  @override
  String get noActivityYet => 'لا يوجد نشاط بعد';

  @override
  String get couldNotLoadMembers => 'تعذّر تحميل الأعضاء';

  @override
  String get couldNotLoadInvites => 'تعذّر تحميل الدعوات';

  @override
  String get couldNotLoadActivity => 'تعذّر تحميل النشاط';

  @override
  String get yourDevices => 'أجهزتك';

  @override
  String get yourDevicesDescription =>
      'العملاء المقترنون بحسابك على هذا الخادم.';

  @override
  String get noOwnDevices => 'لا توجد أجهزة مقترنة بحسابك بعد';

  @override
  String get renameDeviceTitle => 'إعادة تسمية الجهاز';

  @override
  String get revokeDeviceTitle => 'إلغاء الجهاز';

  @override
  String revokeDeviceConfirm(String label) {
    return 'هل تريد إلغاء $label؟ سيُفصل فورًا ولن يتمكن من الوصول إلى هذا الخادم بعد الآن.';
  }

  @override
  String devicePairedTime(String time) {
    return 'اقترن $time';
  }

  @override
  String deviceLastSeenTime(String time) {
    return 'آخر ظهور $time';
  }

  @override
  String get deviceNeverSeen => 'لم يتصل مطلقًا';

  @override
  String get profileSectionLabel => 'الملف الشخصي';

  @override
  String get profileSectionDescription =>
      'كيف تظهر للفريق وفي مؤلفية إيداعات git في مساحة العمل هذه. الحقول الفارغة ترث اسم حسابك وبريدك.';

  @override
  String get displayNameLabel => 'الاسم المعروض';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get gitAuthorNameLabel => 'اسم المؤلف في Git';

  @override
  String get gitAuthorEmailLabel => 'البريد الإلكتروني للمؤلف في Git';

  @override
  String get profileSaved => 'تم حفظ الملف الشخصي';

  @override
  String get presenceOnline => 'متصل';

  @override
  String get presenceIdle => 'خامل';

  @override
  String get presenceTyping => 'يكتب…';

  @override
  String get presenceAgentThinking => 'يفكر';

  @override
  String get presenceAgentRunning => 'قيد التشغيل';

  @override
  String get presenceAgentBlocked => 'معلّق';

  @override
  String get presenceAgentDone => 'تم';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String presenceNameStatusCost(String name, String status, String cost) {
    return '$name — $status ($cost)';
  }

  @override
  String get presenceRailLabel => 'المتصلون الآن';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => 'تشغيل وضع عدم الإزعاج';

  @override
  String get dndTooltipOff => 'إيقاف وضع عدم الإزعاج';

  @override
  String get startPresenting => 'بدء العرض';

  @override
  String get stopPresenting => 'إيقاف العرض';

  @override
  String spotlightPresentingBanner(String name) {
    return '$name يعرض الآن';
  }

  @override
  String get spotlightLeave => 'مغادرة';

  @override
  String typingIndicator(String name) {
    return '$name يكتب…';
  }

  @override
  String get ideTabNotes => 'الملاحظات';

  @override
  String get ideSidebarAllViews => 'كل طرق العرض';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return 'كل طرق العرض ($count مخفية)';
  }

  @override
  String get ideSidebarPinView => 'تثبيت في الشريط الجانبي';

  @override
  String get ideSidebarUnpinView => 'إلغاء التثبيت من الشريط الجانبي';

  @override
  String get notesEmptyHint => 'أضف ملاحظة لأي شخص يتابع هذه المحادثة…';

  @override
  String get notesEditTooltip => 'تحرير الملاحظة';

  @override
  String notesUpdatedBy(String name, String time) {
    return 'حدّثها $name · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '$name يحرر الآن';
  }

  @override
  String get notesSaveFailed => 'تعذّر حفظ الملاحظة';

  @override
  String get reactionAddTooltip => 'إضافة تفاعل';

  @override
  String reactionToggleTooltip(String emoji) {
    return 'التفاعل بـ $emoji';
  }

  @override
  String get autonomyDialLabel => 'الاستقلالية';

  @override
  String get autonomyProposeOnly => 'اقتراح فقط';

  @override
  String get autonomyActWithApproval => 'التصرف بموافقة';

  @override
  String get autonomyActFreely => 'التصرف بحرية';

  @override
  String get autonomyDefaultOption => 'افتراضي';

  @override
  String get checkerLabel => 'المدقق';

  @override
  String get checkerNone => 'بلا';

  @override
  String get checkerCaption =>
      'يراجع المدقق عمليات التشغيل المكتملة للوكلاء الآخرين.';

  @override
  String get takeoverTooltip => 'تولّي شجرة العمل';

  @override
  String get takeoverBannerSelf => 'لقد تولّيت شجرة عمل هذه المحادثة';

  @override
  String takeoverBannerOther(String name) {
    return '$name تولّى شجرة عمل هذه المحادثة';
  }

  @override
  String get handBackButton => 'إعادة التسليم';

  @override
  String get handBackDialogTitle => 'إعادة تسليم شجرة العمل';

  @override
  String get handBackDialogNoteHint => 'ملاحظة اختيارية للوكيل…';

  @override
  String takeoverFailed(String message) {
    return 'تعذّر التولّي: ⁨$message⁩';
  }

  @override
  String handBackFailed(String message) {
    return 'تعذّرت إعادة التسليم: ⁨$message⁩';
  }

  @override
  String get planStudioTitle => 'استوديو الخطط';

  @override
  String get plansTitle => 'الخطط';

  @override
  String get plansSubtitle => 'الخطط النشطة ومستندات الخطط وكتيبات التشغيل';

  @override
  String get plansActiveSection => 'الخطط النشطة';

  @override
  String get plansDocumentsSection => 'مستندات الخطط';

  @override
  String get plansPlaybooksSection => 'كتيبات التشغيل';

  @override
  String get plansNoActive => 'لا توجد خطط نشطة بعد.';

  @override
  String get plansNoDocuments => 'لا توجد مستندات خطط بعد.';

  @override
  String get plansNoPlaybooks => 'لا توجد كتيبات تشغيل بعد.';

  @override
  String get planNotFound => 'لم يُعثر على الخطة.';

  @override
  String get planOpenInStudio => 'فتح';

  @override
  String get planNodeTitle => 'العنوان';

  @override
  String get planNodeDescription => 'الوصف';

  @override
  String get planNodeDescriptionHint => 'ما الذي ينبغي أن تفعله هذه الخطوة…';

  @override
  String get planNodeApplyDescription => 'تطبيق';

  @override
  String get planNodeRole => 'الدور';

  @override
  String get planNodeDependencies => 'يعتمد على';

  @override
  String get planNodeDependenciesHint => 'إضافة تبعية';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تبعية',
      many: '$count تبعية',
      few: '$count تبعيات',
      two: 'تبعيتان',
      one: 'تبعية واحدة',
      zero: 'بلا تبعيات',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies =>
      'لا توجد تبعيات، لذا تعمل هذه الخطوة فور بدء الخطة';

  @override
  String get planNodeOutputSchema => 'مخطط المخرجات (JSON)';

  @override
  String get planNodeEstimate => 'تقدير';

  @override
  String get planNodeProvenance => 'المصدر';

  @override
  String get planNodeAlreadyExecuted =>
      'نُفّذت بالفعل — التحرير يفرّع الخطة من هنا.';

  @override
  String get planNewNodeTitle => 'خطوة جديدة';

  @override
  String get planEstimateNoHistory => 'لا يوجد سجل بعد';

  @override
  String get planEstimateBlastUnknown => 'نطاق التأثير: غير معروف';

  @override
  String get planEstimatePartial => 'جزئي';

  @override
  String get planEstimateAction => 'تقدير';

  @override
  String planEstimateDuration(String range) {
    return 'المدة $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return 'نطاق التأثير: $files من الملفات و$symbols من الرموز';
  }

  @override
  String get planApprove => 'الموافقة على الخطة';

  @override
  String get planApproveSelectedNodes => 'الموافقة على المحدد';

  @override
  String get planReject => 'رفض';

  @override
  String get planCancel => 'إلغاء التشغيل';

  @override
  String get planContinueNode => 'متابعة العقدة';

  @override
  String get planTotalNotEstimated => 'لم يُقدَّر بعد';

  @override
  String get planBudgetExceeded => 'تجاوز الميزانية';

  @override
  String planBudgetCeiling(String amount) {
    return 'الميزانية ≤ ⁨\$$amount⁩';
  }

  @override
  String get planVersionsTitle => 'الإصدارات';

  @override
  String get planNoRevisions => 'لا توجد إصدارات بعد.';

  @override
  String get planDiffIdentical => 'لا توجد تغييرات.';

  @override
  String get planDiffGoalChanged => 'تغيّر الهدف';

  @override
  String get planDiffBudgetChanged => 'تغيّرت الميزانية';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'التغييرات من ⁨v$fromRev⁩ إلى ⁨v$toRev⁩';
  }

  @override
  String planDiffAdded(String node) {
    return 'أُضيفت $node';
  }

  @override
  String planDiffRemoved(String node) {
    return 'أُزيلت $node';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return 'تغيّرت $node: ⁨$fields⁩';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return 'أُضيفت حافة: ⁨$edge⁩';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return 'أُزيلت حافة: ⁨$edge⁩';
  }

  @override
  String planDiffRoleAdded(String role) {
    return 'أُضيف دور: $role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return 'أُزيل دور: $role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return 'أُعيد إسناد دور: $role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return 'أُعيد تخطيط الخطة: لقد وافقت على ⁨v$approved⁩ وهي الآن ⁨v$current⁩. راجع الفروق قبل أن تتابع.';
  }

  @override
  String planLiveActualCost(String amount) {
    return 'التكلفة الفعلية: ⁨\$$amount⁩';
  }

  @override
  String get planPlaybookRun => 'تشغيل';

  @override
  String get planPlaybookDelete => 'حذف كتيب التشغيل';

  @override
  String get planPlaybookProposed =>
      'تم اقتراح الخطة — وافق عليها في استوديو الخطط.';

  @override
  String get planPlaybookAnchorTicket => 'التذكرة المرجعية';

  @override
  String get planPlaybookPickTicket => 'اختر تذكرة…';

  @override
  String get planPlaybookProposeRun => 'اقتراح خطة';

  @override
  String get planPlaybookRepoHint => 'معرّف مستودع';

  @override
  String get planPlaybookAgentHint => 'معرّف وكيل';

  @override
  String planPlaybookRunTitle(String name) {
    return 'تشغيل $name';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '$count من المعاملات';
  }

  @override
  String get recentLabel => 'الأخيرة';

  @override
  String get cheatSheetTitle => 'اختصارات لوحة المفاتيح';

  @override
  String get cheatSheetGlobal => 'عام';

  @override
  String get cheatSheetThisScreen => 'هذه الشاشة';

  @override
  String get cheatSheetReservedInBrowser => 'محجوز للمتصفح';

  @override
  String get keybindingCheatSheet => 'اختصارات لوحة المفاتيح';

  @override
  String get keybindingShowKeyboardShortcutsDescription =>
      'عرض ورقة اختصارات لوحة المفاتيح للشاشة الحالية';

  @override
  String get runPlaybookLabel => 'تشغيل كتيب التشغيل';

  @override
  String get playbooksLabel => 'كتيبات التشغيل';

  @override
  String get keybindingUndo => 'تراجع';

  @override
  String get keybindingRedo => 'إعادة';

  @override
  String get keybindingUndoLastActionDescription =>
      'التراجع عن آخر إجراء قابل للعكس';

  @override
  String get keybindingRedoLastActionDescription =>
      'إعادة آخر إجراء متراجَع عنه';

  @override
  String get undone => 'تم التراجع';

  @override
  String get redone => 'تمت الإعادة';

  @override
  String get undoFailed => 'تعذّر التراجع';

  @override
  String get undoLabelTicketEdit => 'تحرير التذكرة';

  @override
  String get undoLabelMessageEdit => 'تحرير الرسالة';

  @override
  String get undoLabelTodoStatus => 'حالة المهمة';

  @override
  String get inboxTitle => 'الوارد';

  @override
  String get inboxReview => 'مراجعة';

  @override
  String get inboxOpen => 'فتح';

  @override
  String get inboxAllCaughtUp => 'لقد اطلعت على كل شيء';

  @override
  String get inboxGitHubDownTitle => 'قد يكون GitHub متعطلًا';

  @override
  String inboxGitHubDownBody(String status) {
    return 'يُبلغ GitHub عن الحالة ⁨$status⁩، لذا قد تكون طلبات السحب مفقودة من هذه القائمة لا منجزة فعلًا.';
  }

  @override
  String get inboxGitHubIdentityTitle => 'تعذّر تأكيد حسابك على GitHub';

  @override
  String get inboxGitHubIdentityBody =>
      'يُرتّب الوارد بحسب هويتك على GitHub. وإلى أن يتم تحميلها يبقى فارغًا، حتى عندما تكون هناك طلبات سحب في انتظارك.';

  @override
  String get inboxSeverityBlocking => 'متوقف';

  @override
  String get inboxSeverityWaiting => 'في الانتظار';

  @override
  String get inboxSeverityInfo => 'معلومات';

  @override
  String get inboxSyncFailed => 'فشلت المزامنة';

  @override
  String get inboxNeedsYourAttention => 'يحتاج إلى انتباهك';

  @override
  String get inboxSectionNeedsYourReview => 'بحاجة إلى مراجعتك';

  @override
  String get inboxSectionReturnedToYou => 'أُعيدت إليك';

  @override
  String get inboxSectionApproved => 'موافق عليها';

  @override
  String get inboxSectionDrafts => 'المسودات';

  @override
  String get inboxSectionWaitingForReviewers => 'في انتظار المراجعين';

  @override
  String get inboxSectionMergingAndMerged => 'قيد الدمج ومدمجة حديثًا';

  @override
  String get inboxSectionWaitingForAuthor => 'في انتظار المؤلف';

  @override
  String get inboxColumnTitle => 'العنوان';

  @override
  String get inboxColumnChanges => 'التغييرات';

  @override
  String get inboxColumnUpdated => 'آخر تحديث';

  @override
  String get inboxReviewApproved => 'موافق عليه';

  @override
  String get inboxReviewChangesRequested => 'طُلبت تغييرات';

  @override
  String get inboxHeroSubtitle =>
      'كل طلب سحب يخصك، مرتبًا بحسب ما سيحدث تاليًا.';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلب سحب بحاجة إلى مراجعتك',
      many: '$count طلب سحب بحاجة إلى مراجعتك',
      few: '$count طلبات سحب بحاجة إلى مراجعتك',
      two: 'طلبا سحب بحاجة إلى مراجعتك',
      one: 'طلب سحب واحد بحاجة إلى مراجعتك',
      zero: 'لا توجد طلبات سحب بحاجة إلى مراجعتك',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أُعيد إليك $count',
      many: 'أُعيد إليك $count',
      few: 'أُعيدت إليك $count',
      two: 'أُعيد إليك اثنان',
      one: 'أُعيد إليك واحد',
      zero: 'لم يُعَد إليك شيء',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted => 'لم يُحفظ ذلك التغيير وتم التراجع عنه';

  @override
  String get offlinePendingLabel => 'قيد الانتظار';

  @override
  String get offlineSyncingLabel => 'قيد المزامنة';

  @override
  String get copyLinkLabel => 'نسخ رابط هذه الصفحة';

  @override
  String get agentsSectionLabel => 'الوكلاء';

  @override
  String get fleetWorkersTitle => 'العمّال';

  @override
  String get fleetWorkersSubtitle => 'الأجهزة المتاحة لتشغيل المهام';

  @override
  String get fleetJobsTitle => 'المهام';

  @override
  String get fleetJobsSubtitle => 'العمل الموزّع عبر الأسطول';

  @override
  String get fleetNoWorkers =>
      'لا يوجد عمّال بعد — أي جهاز آخر يشغّل ⁨`cc_worker --server <url>`⁩ ينضم إلى الأسطول.';

  @override
  String get fleetNoJobs => 'لا توجد مهام.';

  @override
  String get fleetError => 'تعذّر تحميل الأسطول';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نواة',
      many: '$count نواة',
      few: '$count أنوية',
      two: 'نواتان',
      one: 'نواة واحدة',
      zero: 'بلا أنوية',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return 'نبضة $time';
  }

  @override
  String get fleetNoHeartbeat => 'لا توجد نبضات بعد';

  @override
  String fleetLastErrorLabel(String error) {
    return 'آخر خطأ: ⁨$error⁩';
  }

  @override
  String get fleetDrain => 'تصريف';

  @override
  String get fleetResume => 'استئناف';

  @override
  String get fleetRevoke => 'إلغاء';

  @override
  String get fleetRemove => 'إزالة';

  @override
  String get fleetRevokeTitle => 'هل تريد إلغاء العامل؟';

  @override
  String fleetRevokeBody(String name) {
    return 'هل تريد إلغاء $name؟ تنتهي جلسته ويُعاد إسناد أي مهام نشطة.';
  }

  @override
  String get fleetRemoveTitle => 'هل تريد إزالة العامل؟';

  @override
  String fleetRemoveBody(String name) {
    return 'هل تريد إزالة $name من الأسطول؟ سيؤدي هذا إلى حذف سجله.';
  }

  @override
  String get fleetActionFailed => 'فشل الإجراء';

  @override
  String get fleetJobUnassigned => 'غير مسندة';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '⁨$attempts/$max⁩ من المحاولات';
  }

  @override
  String get fleetPlacementReasons => 'قرارات التوزيع';

  @override
  String get fleetNoPlacements => 'لا توجد قرارات توزيع بعد.';

  @override
  String get fleetStatusOnline => 'متصل';

  @override
  String get fleetStatusDraining => 'قيد التصريف';

  @override
  String get fleetStatusOffline => 'غير متصل';

  @override
  String get fleetStatusIncompatible => 'غير متوافق';

  @override
  String get fleetStatusRevoked => 'ملغى';

  @override
  String get fleetJobStatusQueued => 'في قائمة الانتظار';

  @override
  String get fleetJobStatusRunning => 'قيد التشغيل';

  @override
  String get fleetJobStatusSucceeded => 'نجحت';

  @override
  String get fleetJobStatusFailed => 'فشلت';

  @override
  String get fleetJobStatusCancelled => 'ملغاة';

  @override
  String get evalsNoSuites => 'لا توجد حزم تقييم بعد.';

  @override
  String get evalsError => 'تعذّر تحميل التقييمات';

  @override
  String get evalsStarterBadge => 'مبدئي';

  @override
  String evalsDefaultBatch(int count) {
    return 'الدفعة الافتراضية من $count';
  }

  @override
  String get evalsRecentRuns => 'عمليات التشغيل الأخيرة';

  @override
  String get evalsNoRuns => 'لا توجد عمليات تشغيل بعد.';

  @override
  String get evalsPassRate => 'معدل النجاح';

  @override
  String evalsBatchTimes(int count) {
    return '× $count';
  }

  @override
  String evalsTriggeredBy(String who) {
    return 'بواسطة $who';
  }

  @override
  String evalsRunFinished(String rate) {
    return 'انتهى التقييم — نجح $rate';
  }

  @override
  String get evalsRunFailed => 'تعذّر تشغيل الحزمة';

  @override
  String get evalsRun => 'تشغيل';

  @override
  String get evalsStatusQueued => 'في قائمة الانتظار';

  @override
  String get evalsStatusRunning => 'قيد التشغيل';

  @override
  String get evalsStatusPassed => 'ناجح';

  @override
  String get evalsStatusFailed => 'فاشل';

  @override
  String get bannerMeetingJoin => 'انضمام';

  @override
  String get bannerMeetingRecordAndLink => 'تسجيل وربط';

  @override
  String get bannerCalendarReconnect => 'إعادة الاتصال';

  @override
  String get bannerView => 'عرض';

  @override
  String get soundscapeTitle => 'المشاهد الصوتية';

  @override
  String get soundscapePlay => 'تشغيل';

  @override
  String get soundscapePause => 'إيقاف مؤقت';

  @override
  String get soundscapeMoodLabel => 'المزاج';

  @override
  String get soundscapeMoodFocus => 'تركيز';

  @override
  String get soundscapeMoodRelax => 'استرخاء';

  @override
  String get soundscapeMoodSleep => 'نوم';

  @override
  String get soundscapeMoodRise => 'صعود';

  @override
  String get soundscapeVolumeLabel => 'مستوى الصوت';

  @override
  String get soundscapeTuneLabel => 'ضبط';

  @override
  String get soundscapeTuneMellow => 'هادئ';

  @override
  String get soundscapeTuneBright => 'ساطع';

  @override
  String get soundscapeTuneEnergetic => 'نشيط';

  @override
  String get soundscapeTuneSpacy => 'حالم';

  @override
  String get soundscapeTuneResetHint => 'انقر نقرًا مزدوجًا لإعادة الضبط';

  @override
  String get soundscapeSceneLabel => 'قيد التشغيل الآن';

  @override
  String get soundscapeSceneLoading => 'يجري ضبط الأجواء…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees°C';
  }

  @override
  String get soundscapeLocationLabel => 'الموقع';

  @override
  String get soundscapeLocationDetecting => 'يجري تحديد الموقع…';

  @override
  String get soundscapeLocationAutoNote => 'يأتي الموقع من هذا الجهاز.';

  @override
  String get soundscapeRefreshWeather => 'تحديث الطقس';

  @override
  String get soundscapeAutoStartLabel => 'البدء مع وضع التركيز';

  @override
  String get soundscapeAutoStartDescription =>
      'تشغيل مشهد صوتي تلقائيًا عند بدء جلسة تركيز.';

  @override
  String get soundscapeReturnToApp => 'العودة إلى التطبيق';

  @override
  String get soundscapePopOut => 'فصل المشغّل';

  @override
  String get discussion => 'النقاش';

  @override
  String get chat => 'الدردشة';

  @override
  String get saving => 'يجري الحفظ…';

  @override
  String get saved => 'تم الحفظ';

  @override
  String get saveFailed => 'تعذّر الحفظ';

  @override
  String get commitAndPush => 'إيداع ودفع';

  @override
  String get commit => 'إيداع';

  @override
  String get commitAmend => 'إيداع (تعديل)';

  @override
  String get commitAndSync => 'إيداع ومزامنة';

  @override
  String get scmSyncChanges => 'مزامنة التغييرات';

  @override
  String get scmPublishBranch => 'نشر الفرع';

  @override
  String get scmSyncFailed => 'فشلت المزامنة';

  @override
  String get scmSyncDirty => 'أودِع التغييرات أو تخلَّ عنها قبل المزامنة';

  @override
  String get scmSynced => 'تمت المزامنة';

  @override
  String get scmSelectBranch => 'اختر فرعًا للانتقال إليه';

  @override
  String get scmCreateBranch => 'إنشاء فرع جديد…';

  @override
  String get scmCreateBranchFrom => 'إنشاء فرع جديد من…';

  @override
  String get scmCheckoutDetached => 'انتقال منفصل…';

  @override
  String get scmBranchName => 'اسم الفرع';

  @override
  String get scmCreateBranchTitle => 'إنشاء فرع';

  @override
  String scmFromRef(String ref) {
    return 'من ⁨$ref⁩';
  }

  @override
  String get scmCheckoutFailed => 'تعذّر تبديل الفرع';

  @override
  String get scmCheckoutDirty =>
      'أكمل الإيداع أو تجاهل التغييرات قبل تبديل الفرع';

  @override
  String scmSwitchedToBranch(String branch) {
    return 'تم التبديل إلى ⁨$branch⁩';
  }

  @override
  String scmDetachedAt(String ref) {
    return 'منفصل عند ⁨$ref⁩';
  }

  @override
  String get scmDetachedHead => 'HEAD منفصل';

  @override
  String get scmNoBranches => 'لا توجد فروع مطابقة';

  @override
  String get scmBranches => 'الفروع';

  @override
  String get scmRemoteBranches => 'الفروع البعيدة';

  @override
  String get scmTags => 'الوسوم';

  @override
  String get scmPickStartPoint => 'اختر نقطة البداية';

  @override
  String get scmSwitchBranch => 'تبديل الفرع';

  @override
  String commitMessageOnBranch(String shortcut, String branch) {
    return 'رسالة ($shortcut للإيداع على “$branch”)';
  }

  @override
  String get committed => 'تم الإيداع';

  @override
  String get commitAmended => 'تم تعديل الإيداع';

  @override
  String get commitFailed => 'فشل الإيداع';

  @override
  String get moreCommitActions => 'مزيد من إجراءات الإيداع';

  @override
  String get sourceControl => 'إدارة المصادر';

  @override
  String fixFindingTitle(String location) {
    return 'إصلاح: ⁨$location⁩';
  }

  @override
  String get openInEditor => 'فتح في المحرر';

  @override
  String get regexTesterTitle => 'اختبار التعبير النمطي';

  @override
  String get regexTesterHint => 'اكتب عيّنة';

  @override
  String get regexMatch => 'مطابقة';

  @override
  String get regexNoMatch => 'لا توجد مطابقة';

  @override
  String get regexInvalidPattern => 'نمط غير صالح';

  @override
  String get symbolLookupNone => 'لا يوجد تعريف في الفهرس أو في طلب السحب هذا';

  @override
  String get symbolLookupInDiff => 'موجود في طلب السحب هذا';

  @override
  String get symbolLookupFromBase =>
      'من نسخة الأساس — شجرة عمل هذا الطلب غير مفهرسة بعد';

  @override
  String get symbolImplementations => 'التنفيذات';

  @override
  String symbolCallersCount(int count) {
    return '$count مستدعٍ';
  }

  @override
  String get commitMessageHint => 'رسالة الإيداع';

  @override
  String get pushedToPr => 'تم الدفع إلى PR';

  @override
  String get pushFailed => 'فشل الدفع';

  @override
  String get reviewFindings => 'النتائج';

  @override
  String get treeLabel => 'الشجرة';

  @override
  String get toggleFileTree => 'إظهار شجرة الملفات أو إخفاؤها';

  @override
  String get diffViewSettings => 'إعدادات عرض الفروق';

  @override
  String get splitViewLabel => 'مقسّم';

  @override
  String get unifiedViewLabel => 'موحّد';

  @override
  String get wrapLines => 'التفاف الأسطر';

  @override
  String get shiftClickSelectRange => 'انقر مع الضغط على Shift لتحديد نطاق';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملف',
      many: '$count ملفًا',
      few: '$count ملفات',
      two: 'ملفان',
      one: 'ملف واحد',
      zero: '$count ملف',
    );
    return '$_temp0';
  }

  @override
  String prComplexityLoc(String loc) {
    return '$loc LOC';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return 'PR صغير — $files، نحو $minutes دقيقة للمراجعة';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return 'PR متوسط — $files، خصص نحو $minutes دقيقة للمراجعة';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return 'PR كبير — $files، فكّر في تقسيمه قبل المراجعة';
  }

  @override
  String get searchInFiles => 'البحث في الملفات';

  @override
  String get showFileList => 'عرض قائمة الملفات';

  @override
  String get searchInFilesHintField => 'البحث في الملفات…';

  @override
  String get searchInFilesHint => 'البحث عبر ملفات طلب السحب';

  @override
  String get searchInWholeRepo => 'البحث في المستودع بالكامل';

  @override
  String get searchInThisPullRequest => 'البحث في طلب السحب هذا';

  @override
  String get searchNoResults => 'لم يُعثر على نتائج';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نتيجة',
      many: '$count نتيجة',
      few: '$count نتائج',
      two: 'نتيجتان',
      one: 'نتيجة واحدة',
      zero: 'بلا نتائج',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files ملف',
      many: '$files ملفًا',
      few: '$files ملفات',
      two: 'ملفين',
      one: 'ملف واحد',
      zero: '$files ملف',
    );
    return '$_temp0 في $_temp1';
  }

  @override
  String get discardChangesTitle => 'هل تريد تجاهل التغييرات؟';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملف',
      many: '$count ملفًا',
      few: '$count ملفات',
      two: 'ملفين',
      one: 'ملف واحد',
      zero: '$count ملف',
    );
    return 'هل تريد تجاهل $_temp0 والعودة إلى HEAD؟ لا يمكن التراجع عن هذا.';
  }

  @override
  String get discardAll => 'تجاهل الكل';

  @override
  String get discardFailed => 'فشل تجاهل التغييرات';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملف',
      many: '$count ملفًا',
      few: '$count ملفات',
      two: 'ملفين',
      one: 'ملف واحد',
      zero: '$count ملف',
    );
    return 'تم تجاهل $_temp0';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '$reverted ملف',
      many: '$reverted ملفًا',
      few: '$reverted ملفات',
      two: 'ملفين',
      one: 'ملف واحد',
      zero: '$reverted ملف',
    );
    return 'تم تجاهل $_temp0؛ وتم تخطي $skipped (غير متتبَّعة)';
  }

  @override
  String get prWorktreeUnavailable => 'مساحة العمل غير جاهزة';

  @override
  String get prWorktreeUnavailableHint =>
      'فشل تجهيز ملفات طلب السحب. أعد فتح طلب السحب للمحاولة مجددًا.';

  @override
  String get timestampRelativeLabel => 'نسبي';

  @override
  String get timestampRawLabel => 'الطابع الزمني';

  @override
  String get copyTimestamp => 'نسخ الطابع الزمني';

  @override
  String get copiedTimestamp => 'تم نسخ الطابع الزمني';

  @override
  String get previewDeployment => 'معاينة النشر';

  @override
  String previewDeploymentTab(String site) {
    return 'معاينة: ⁨$site⁩';
  }

  @override
  String get askForReview => 'طلب مراجعة…';

  @override
  String get closePrsConfirmTitle => 'هل تريد إغلاق طلبات السحب؟';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'هل تريد إغلاق $count طلب سحب؟',
      many: 'هل تريد إغلاق $count طلب سحب؟',
      few: 'هل تريد إغلاق $count طلبات سحب؟',
      two: 'هل تريد إغلاق طلبَي سحب؟',
      one: 'هل تريد إغلاق طلب سحب واحد؟',
      zero: 'هل تريد إغلاق $count طلب سحب؟',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أُغلق $count طلب سحب',
      many: 'أُغلق $count طلب سحب',
      few: 'أُغلقت $count طلبات سحب',
      two: 'أُغلق طلبا سحب',
      one: 'أُغلق طلب سحب واحد',
      zero: 'أُغلق $count طلب سحب',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أُسند $count طلب سحب',
      many: 'أُسند $count طلب سحب',
      few: 'أُسندت $count طلبات سحب',
      two: 'أُسند طلبا سحب',
      one: 'أُسند طلب سحب واحد',
      zero: 'أُسند $count طلب سحب',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'طُلبت مراجعة $count طلب سحب',
      many: 'طُلبت مراجعة $count طلب سحب',
      few: 'طُلبت مراجعة $count طلبات سحب',
      two: 'طُلبت مراجعة طلبَي سحب',
      one: 'طُلبت مراجعة طلب سحب واحد',
      zero: 'طُلبت مراجعة $count طلب سحب',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'فشل $count إجراء',
      many: 'فشل $count إجراءً',
      few: 'فشلت $count إجراءات',
      two: 'فشل إجراءان',
      one: 'فشل إجراء واحد',
      zero: 'لم يفشل أي إجراء',
    );
    return '$_temp0';
  }

  @override
  String get diagram => 'مخطط';

  @override
  String get diagramViewSource => 'عرض المصدر';

  @override
  String get diagramHideSource => 'إخفاء المصدر';

  @override
  String diagramPreviewUnavailable(String reason) {
    return 'معاينة المخطط غير متاحة (⁨$reason⁩)';
  }

  @override
  String get planUnavailable => 'الخطة غير متاحة';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count خطوة',
      many: '$count خطوة',
      few: '$count خطوات',
      two: 'خطوتان',
      one: 'خطوة واحدة',
      zero: 'بلا خطوات',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => 'الموافقة والتشغيل';

  @override
  String get planStatusDraft => 'مسودة';

  @override
  String get planStatusProposed => 'خطة';

  @override
  String get planStatusApproved => 'تمت الموافقة على الخطة';

  @override
  String get planStatusRejected => 'رُفضت الخطة';

  @override
  String get planStatusSuperseded => 'استُبدلت الخطة';

  @override
  String planRevisionLabel(int revision) {
    return 'النسخة $revision';
  }

  @override
  String get adapterEnforcementTitle => 'ما يفرضه هذا المحوّل';

  @override
  String get enforcementFiltersToolSurface => 'يختار Control Center الأدوات';

  @override
  String get enforcementInterceptsToolCalls =>
      'يُتحقَّق من كل استدعاء قبل تنفيذه';

  @override
  String get enforcementObservesCompletionContract =>
      'يُلزَم التشغيل بتسليم ناتجه المطلوب';

  @override
  String get enforcementNativeToolsInterceptable => 'أدوات المشغِّل نفسه مرئية';

  @override
  String get enforcementInProcessToolsSandboxed =>
      'الأدوات داخل العملية تعمل في بيئة معزولة';

  @override
  String get enforcementYes => 'نعم';

  @override
  String get enforcementNo => 'لا';

  @override
  String get adapterEnforcementCaveats => 'تحفظات';

  @override
  String get enforcementSummaryModesEnforced => 'الأوضاع مفروضة';

  @override
  String get enforcementSummaryModesNotEnforced => 'الأوضاع غير مفروضة';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تحفظ',
      many: '$count تحفظًا',
      few: '$count تحفظات',
      two: 'تحفظان',
      one: 'تحفظ واحد',
      zero: 'بلا تحفظات',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      'أوضاع القراءة فقط ليست بنيوية: لا يستطيع Control Center إزالة أدوات هذا المشغِّل نفسه.';

  @override
  String get caveatToolCallsNotIntercepted =>
      'لا توجد بوابة قبل التنفيذ: استدعاءات أدوات MCP فقط هي التي تمر عبر Control Center.';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      'أدوات الملفات وسطر الأوامر الخاصة بالمشغِّل لا تصل إلى Control Center مطلقًا؛ والبيئة المعزولة لنظام التشغيل هي الحد الأدنى الوحيد تحتها.';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      'أدوات الملفات داخل العملية تعمل خارج البيئة المعزولة، لذا فإن سطح الأدوات هو الحد الوحيد لنظام الملفات.';

  @override
  String get caveatCompletionContractUnobservable =>
      'لا يستطيع Control Center تنبيه تشغيل ينتهي دون إنتاج ناتجه المطلوب أو إفشاله.';

  @override
  String get modeDegraded => 'منقوص';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return 'وضع $mode على ⁨$adapter⁩ يعتمد على البيئة المعزولة فقط؛ أدوات الملفات الخاصة بالوكيل لا تُعترَض.';
  }

  @override
  String get artifactUnavailable => 'المخرَج غير متاح';

  @override
  String artifactRevisionLabel(int count) {
    return 'النسخ: $count';
  }

  @override
  String get artifactShowMore => 'عرض المزيد';

  @override
  String get artifactShowLess => 'عرض أقل';

  @override
  String get artifactCopy => 'نسخ';

  @override
  String get artifactCopied => 'تم نسخ المخرَج';

  @override
  String get artifactsTabLabel => 'المخرَجات';

  @override
  String get artifactsEmptyTitle => 'لا مخرَجات بعد';

  @override
  String get artifactsEmptyBody =>
      'عندما ينشر وكيل جدولًا أو مخططًا أو رسمًا بيانيًا هنا، سيظهر في هذه القائمة.';

  @override
  String get artifactRevisionPickerLabel => 'النسخة';

  @override
  String get artifactRestoreRevision => 'استعادة هذه النسخة';

  @override
  String get artifactOpenInTab => 'فتح في علامة تبويب';

  @override
  String get artifactTitleFallback => 'مخرَج';

  @override
  String get providerGenerationLabel => 'الإعدادات الافتراضية للتوليد';

  @override
  String get providerGenerationHint =>
      'اترك الحقل فارغًا لاستخدام القيمة الافتراضية لنقطة النهاية نفسها. تنشر النماذج حدودها القصوى للمخرجات ووصفات أخذ العينات الخاصة بها؛ وتشغيل نموذج بقيم أخرى قد يضعف أداءه.';

  @override
  String get providerMaxTokensLabel => 'الحد الأقصى لرموز الإخراج';

  @override
  String get addModel => 'إضافة نموذج';

  @override
  String get modelListTitle => 'قائمة النماذج';

  @override
  String get railProvidersGroup => 'المزوّدون';

  @override
  String get railCustomProvidersGroup => 'مزوّدون مخصصون';

  @override
  String get editModelSettings => 'تعديل إعدادات النموذج';

  @override
  String get modelIdLabel => 'معرّف النموذج';

  @override
  String get modelIdImmutableHint =>
      'المعرّف الذي تقدمه نقطة النهاية؛ ثابت بعد الإدراج.';

  @override
  String get contextWindowLabel => 'نافذة السياق';

  @override
  String get inputTypesLabel => 'أنواع الإدخال';

  @override
  String get outputTypesLabel => 'أنواع الإخراج';

  @override
  String get modalityText => 'نص';

  @override
  String get modalityImage => 'صورة';

  @override
  String get modalityAudio => 'صوت';

  @override
  String get modalityVideo => 'فيديو';

  @override
  String get modalityPdf => 'PDF';

  @override
  String get modelOverrideReset => 'إعادة التعيين إلى تلقائي';

  @override
  String get modelOverrideEdited => 'معدَّل';

  @override
  String get manualModelBadge => 'أُضيف يدويًا';

  @override
  String get modelIdRequired => 'أدخل معرّف نموذج.';

  @override
  String get modelTokensInvalid => 'أدخل عددًا صحيحًا موجبًا من الرموز.';

  @override
  String get removeModelAction => 'إزالة النموذج';

  @override
  String removeModelConfirmTitle(String model) {
    return 'إزالة ⁨$model⁩؟';
  }

  @override
  String get removeModelConfirmBody =>
      'سيُحذف النموذج من القائمة وسيتوقف الوكلاء المثبَّتون عليه عن العمل. لن يتأثر المزوّد.';

  @override
  String get addModelProviderTitle => 'إضافة مزوّد نماذج';

  @override
  String get addModelProviderDescription =>
      'اضبط نقطة نهاية API مخصصة ونماذجها.';

  @override
  String get modelListEmptyHint =>
      'لا توجد نماذج مضبوطة. أضف نموذجًا لاستخدامه في الدردشة.';

  @override
  String get addProviderModelsHint =>
      'تُجلب النماذج مباشرة بمجرد استجابة نقطة النهاية. أضف نموذجًا يدويًا فقط إذا تعذّر عليها إدراج نماذجها بنفسها.';

  @override
  String get providerTemperatureLabel => 'درجة الحرارة';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved => 'تم حفظ الإعدادات الافتراضية للتوليد';

  @override
  String get providerGenerationInvalid =>
      'تحقق من القيم: يجب أن يكون الحد الأقصى لرموز الإخراج وTop-k موجبين، ودرجة الحرارة بين 0 و2، وTop-p بين 0 و1.';

  @override
  String get providerGenerationOverridden => 'مُتجاوَز';

  @override
  String get branchNotPushed => 'غير مدفوع';

  @override
  String branchNotOnRemote(String branch) {
    return '«⁨$branch⁩» موجود في هذه المحادثة فقط';
  }

  @override
  String get branchNotOnRemoteHint =>
      'لم يرَ GitHub هذا الفرع من قبل، لذا لا يمكن لطلب سحب استخدامه بعد. النشر يدفع الإيداعات الموجودة فعلًا في شجرة العمل — وتُترك التغييرات غير المودَعة كما هي.';

  @override
  String get publishBranch => 'نشر الفرع';

  @override
  String branchPublished(String branch) {
    return 'تم نشر «⁨$branch⁩» إلى origin';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return 'تم نشر الفرع. لم يُضمَّن $count من التغييرات غير المودَعة.';
  }

  @override
  String get composePrLoadingBranches => 'جارٍ تحميل الفروع من GitHub…';

  @override
  String get composePrBranchesFailed =>
      'تعذّر تحميل الفروع من GitHub. اكتب اسم فرع، أو تحقق من الاتصال بـGitHub.';

  @override
  String get composePrSubtitleFromSpace =>
      'من فرع هذه المحادثة — انشره أولًا إذا لم يره GitHub بعد';

  @override
  String get obsTabInsights => 'الرؤى';

  @override
  String get obsTabLive => 'مباشر';

  @override
  String get obsTabQuality => 'الجودة';

  @override
  String get obsTabUsage => 'الاستخدام';

  @override
  String get obsUsageTotalTokens => 'إجمالي الرموز';

  @override
  String get obsUsagePeakTokens => 'ذروة الرموز';

  @override
  String get obsUsageLongestSession => 'أطول جلسة';

  @override
  String get obsUsageCurrentStreak => 'السلسلة الحالية';

  @override
  String get obsUsageLongestStreak => 'أطول سلسلة';

  @override
  String obsUsageDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم',
      many: '$count يومًا',
      few: '$count أيام',
      two: 'يومان',
      one: 'يوم واحد',
      zero: 'لا أيام',
    );
    return '$_temp0';
  }

  @override
  String get obsUsageTokenActivity => 'نشاط الرموز';

  @override
  String get obsUsageActivityModeLabel => 'وضع نشاط الرموز';

  @override
  String get obsUsageModeDaily => 'يومي';

  @override
  String get obsUsageModeWeekly => 'أسبوعي';

  @override
  String get obsUsageModeCumulative => 'تراكمي';

  @override
  String get obsUsageTimeRange => 'النطاق الزمني';

  @override
  String get obsUsageTrendTitle => 'اتجاه الرموز اليومي';

  @override
  String get obsUsageModelUsage => 'استخدام النماذج';

  @override
  String get obsUsageTokensLabel => 'رمز';

  @override
  String get obsUsageNoActivity => 'لم يُسجَّل أي استخدام للرموز بعد';

  @override
  String get obsUsageOtherModels => 'أخرى';

  @override
  String obsUsageCellReadout(String date, String tokens) {
    return '$date · $tokens رمز';
  }

  @override
  String obsUsageActivitySummary(
    String start,
    String end,
    int activeDays,
    String peak,
  ) {
    return 'نشاط الرموز من $start إلى $end. $activeDays من الأيام النشطة. أكثر الأيام ازدحامًا: $peak رمز.';
  }

  @override
  String get obsScreenSubtitle =>
      'تحكم مباشر في الوكلاء، وإسناد التكاليف، والحصص، وإشارات الجودة';

  @override
  String get obsRangeLast24h => 'آخر 24 ساعة';

  @override
  String get obsRangeLast7d => 'آخر 7 أيام';

  @override
  String get obsRangeLast30d => 'آخر 30 يومًا';

  @override
  String get obsRangeAll => 'كل الوقت';

  @override
  String get obsAddFilter => 'إضافة عامل تصفية';

  @override
  String get obsFilterAgent => 'الوكيل';

  @override
  String get obsFilterModel => 'النموذج';

  @override
  String get obsFilterStatus => 'الحالة';

  @override
  String get obsFilterRole => 'الدور';

  @override
  String get obsKpiTotalRuns => 'إجمالي التشغيلات';

  @override
  String get obsKpiTotalCost => 'إجمالي التكلفة';

  @override
  String get obsKpiErrorRate => 'معدل الأخطاء';

  @override
  String get obsKpiCacheRate => 'معدل الذاكرة المؤقتة';

  @override
  String get obsKpiTokensPerSec => 'رمز / ثانية';

  @override
  String get obsKpiAvgLatency => 'متوسط زمن الاستجابة';

  @override
  String get obsKpiTtft => 'الوقت حتى أول رمز';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '$delta مقارنة بالفترة السابقة';
  }

  @override
  String get obsChartActivity => 'النشاط';

  @override
  String get obsChartCost => 'التكلفة عبر الزمن';

  @override
  String get obsLegendRuns => 'التشغيلات';

  @override
  String get obsLegendErrors => 'الأخطاء';

  @override
  String get obsAgentsTitle => 'الوكلاء';

  @override
  String obsShowAllAgents(int count) {
    return 'عرض جميع الوكلاء ($count)';
  }

  @override
  String get obsShowFewerAgents => 'عرض أقل';

  @override
  String get obsRunsTitle => 'التشغيلات';

  @override
  String get obsNoRunsInRange => 'لا تشغيلات في هذا النطاق';

  @override
  String get obsColTime => 'الوقت';

  @override
  String get obsColAgent => 'الوكيل';

  @override
  String get obsColStatus => 'الحالة';

  @override
  String get obsColModel => 'النموذج';

  @override
  String get obsColDuration => 'المدة';

  @override
  String get obsColTokens => 'الرموز';

  @override
  String get obsColCost => 'التكلفة';

  @override
  String get obsColErrors => 'الأخطاء';

  @override
  String get obsColRuns => 'التشغيلات';

  @override
  String get obsColAvgLatency => 'متوسط زمن الاستجابة';

  @override
  String get obsColLastActive => 'آخر نشاط';

  @override
  String get obsStatusPending => 'قيد الانتظار';

  @override
  String get obsStatusRunning => 'قيد التشغيل';

  @override
  String get obsStatusCompleted => 'مكتمل';

  @override
  String get obsStatusError => 'خطأ';

  @override
  String get obsRosterLoadError => 'تعذّر تحميل قائمة الوكلاء.';

  @override
  String get obsRosterEmpty => 'لا وكلاء بعد';

  @override
  String get obsRosterEmptyDescription =>
      'أرسل وكيلًا وسيظهر هنا مباشرة — الحالة والأداة الحالية والرموز والتكلفة.';

  @override
  String get obsKillAgent => 'إنهاء الوكيل';

  @override
  String get obsRosterTokensLabel => 'رمز';

  @override
  String get obsCostByRoleTitle => 'التكلفة حسب الدور';

  @override
  String get obsCostByRoleSubtitle =>
      'أين تُنفِق مساحة العمل هذه، حسب دور الوكيل';

  @override
  String get obsRoleMain => 'رئيسي';

  @override
  String get obsRoleSubagents => 'الوكلاء الفرعيون';

  @override
  String get obsRoleAdvisor => 'مستشار';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return 'الرئيسي: $main · الوكلاء الفرعيون: $sub · المستشار: $advisor';
  }

  @override
  String get obsTotal => 'الإجمالي';

  @override
  String get obsTokenModelTitle => 'نموذج الرموز (5 محاور)';

  @override
  String get obsTokenModelSubtitle =>
      'كل رمز أنفقته مساحة العمل هذه، حسب المحور';

  @override
  String get obsAxisInput => 'إدخال';

  @override
  String get obsAxisOutput => 'إخراج';

  @override
  String get obsAxisReasoning => 'استدلال';

  @override
  String get obsAxisCacheRead => 'قراءة من الذاكرة المؤقتة';

  @override
  String get obsAxisCacheWrite => 'كتابة في الذاكرة المؤقتة';

  @override
  String get obsTotalTokens => 'إجمالي الرموز';

  @override
  String get obsCacheDiscountNote =>
      'تُحتسب رموز القراءة من الذاكرة المؤقتة بسعر مخفَّض، لذا تكلف أقل بكثير من الحجم نفسه من الإدخال الجديد.';

  @override
  String get obsByModelTitle => 'حسب النموذج';

  @override
  String get obsByModelSubtitle => 'استخدام الرموز والتكلفة لكل نموذج';

  @override
  String get obsNoModelUsage => 'لم يُسجَّل أي استخدام للنماذج بعد.';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تشغيل',
      many: '$count تشغيلًا',
      few: '$count تشغيلات',
      two: 'تشغيلان',
      one: 'تشغيل واحد',
      zero: 'بلا تشغيلات',
    );
    return '$_temp0';
  }

  @override
  String get obsPerRunTitle => 'لكل تشغيل';

  @override
  String get obsPerRunSubtitle => 'التكلفة النموذجية بالرموز لتشغيل واحد';

  @override
  String get obsMedianRunTokens => 'وسيط رموز التشغيل';

  @override
  String get obsMedianRunTokensSub => 'نقطة المنتصف عبر كل التشغيلات';

  @override
  String get obsRunsInWorkspace => 'في مساحة العمل هذه';

  @override
  String get obsCostShare => 'حصة التكلفة';

  @override
  String get obsQuotaConfiguredLimits => 'الحدود المضبوطة';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      'الاستخدام مقابل السقوف التي حددتها، الأسوأ حالةً أولًا.';

  @override
  String get obsQuotaAddLimit => 'إضافة حد';

  @override
  String get obsQuotaNoLimits =>
      'لا حدود حصص مضبوطة بعد — أضف حدًا لتتبع الاستخدام مقابل سقف.';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return 'إزالة حد $title';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return 'يُعاد التعيين خلال $duration · $status';
  }

  @override
  String get obsQuotaUsageWindows => 'نوافذ الاستخدام';

  @override
  String get obsQuotaUsageWindowsSubtitle =>
      'الاستخدام المرصود عبر جميع المزوّدين، دون تطبيق أي سقف.';

  @override
  String get obsQuotaNoUsage => 'لم يُسجَّل أي استخدام بعد.';

  @override
  String get obsQuotaTokensUsed => 'الرموز المستخدمة';

  @override
  String get obsQuotaRequests => 'الطلبات';

  @override
  String get obsQuotaUnitTokens => 'رموز';

  @override
  String get obsQuotaUnitRequests => 'طلبات';

  @override
  String get obsQuotaUnitCost => 'تكلفة';

  @override
  String get obsQuotaAddLimitTitle => 'إضافة حد حصة';

  @override
  String get obsQuotaProviderLabel => 'المزوّد';

  @override
  String get obsQuotaWindowLabel => 'النافذة';

  @override
  String get obsQuotaUnitLabel => 'الوحدة';

  @override
  String obsQuotaLimitLabel(String unit) {
    return 'الحد ($unit)';
  }

  @override
  String get obsQuotaCentsHint => 'بالسنت الأمريكي (⁨500 = \$5.00⁩).';

  @override
  String get obsQuotaStatusOk => 'جيد';

  @override
  String get obsQuotaStatusWarning => 'تحذير';

  @override
  String get obsQuotaStatusExhausted => 'مستنفَد';

  @override
  String get obsQuotaStatusUnknown => 'غير معروف';

  @override
  String get obsGoalNoActiveTitle => 'لا هدف نشط';

  @override
  String get obsGoalNoActiveBody =>
      'حدد هدفًا لإعطاء الوكلاء غاية وميزانية رموز اختيارية. مع اكتمال التشغيلات، تمتلئ الميزانية ويُحَث الوكلاء على الاختتام عندما تقترب من النفاد.';

  @override
  String get obsGoalSetGoal => 'تحديد هدف';

  @override
  String get obsGoalTokenBudget => 'ميزانية الرموز';

  @override
  String obsGoalTokensLeft(String tokens) {
    return 'المتبقي $tokens';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens (لا ميزانية محددة)';
  }

  @override
  String get obsGoalTokensUsed => 'الرموز المستخدمة';

  @override
  String get obsGoalElapsed => 'الوقت المنقضي';

  @override
  String get obsGoalWrapUp => 'اختتام';

  @override
  String get obsGoalClear => 'مسح الهدف';

  @override
  String get obsGoalFallbackTitle => 'الهدف';

  @override
  String get obsGoalSubtitle => 'ميزانية وضع الهدف';

  @override
  String get obsGoalStatusActive => 'نشط';

  @override
  String get obsGoalStatusPaused => 'متوقف مؤقتًا';

  @override
  String get obsGoalStatusBudgetLimited => 'مقيّد بالميزانية';

  @override
  String get obsGoalStatusComplete => 'مكتمل';

  @override
  String get obsGoalStatusDropped => 'متروك';

  @override
  String get obsGoalObjectiveLabel => 'الغاية';

  @override
  String get obsGoalBudgetLabel => 'ميزانية الرموز (اختياري)';

  @override
  String get obsGoalSetAction => 'تحديد الهدف';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => 'النجاح %';

  @override
  String get obsBenchmarkPassed => 'ناجح';

  @override
  String get obsBenchmarkFailed => 'فاشل';

  @override
  String get obsBenchmarkErrors => 'الأخطاء';

  @override
  String get obsBenchmarkSpend => 'الإنفاق';

  @override
  String get obsBenchmarkCostPerTask => 'التكلفة / المهمة';

  @override
  String get obsBenchmarkTrials => 'المحاولات';

  @override
  String get obsBenchmarkNoTrials => 'لا تشغيلات لتقييمها بعد.';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'و$count أخرى',
      many: 'و$count أخرى',
      few: 'و$count أخرى',
      two: 'واثنان آخران',
      one: 'وواحد آخر',
      zero: 'ولا شيء آخر',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => 'نجاح';

  @override
  String get obsBenchmarkTrialFail => 'فشل';

  @override
  String get obsBenchmarkTrialError => 'خطأ';

  @override
  String get obsBenchmarkTrialRunning => 'قيد التشغيل';

  @override
  String get obsBenchmarkReward => 'المكافأة';

  @override
  String get obsBenchmarkReport => 'التقرير';

  @override
  String get obsBenchmarkCopyMarkdown => 'نسخ Markdown';

  @override
  String get obsBenchmarkCopied => 'تم نسخ التقرير إلى الحافظة';

  @override
  String get obsBehaviorCaption =>
      'هذه إشارات إحباط مستخلصة من رسائلك أنت — قراءة لصحة المحادثة، وليست تقييمًا للوكلاء. تُحسب محليًا؛ ولا يغادر أي شيء هذا الجهاز.';

  @override
  String get obsBehaviorMessagesAnalyzed => 'الرسائل المحلَّلة';

  @override
  String get obsBehaviorTotalSignals => 'إجمالي الإشارات';

  @override
  String get obsBehaviorYelling => 'صراخ';

  @override
  String get obsBehaviorProfanity => 'ألفاظ نابية';

  @override
  String get obsBehaviorAnguish => 'ضيق';

  @override
  String get obsBehaviorNegation => 'نفي';

  @override
  String get obsBehaviorRepetition => 'تكرار';

  @override
  String get obsBehaviorBlame => 'لوم';

  @override
  String get obsBehaviorConversationsTitle => 'المحادثات الأكثر إحباطًا';

  @override
  String get obsBehaviorConversationsSubtitle =>
      'مرتبة حسب كثافة الإشارات عبر رسائلك.';

  @override
  String get obsBehaviorNoSignals =>
      'لم تُرصد أي إشارات إحباط — كل شيء يسير بسلاسة.';

  @override
  String obsBehaviorMessagesCount(String count) {
    return 'تم تحليل $count من الرسائل';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '$count من الإشارات';
  }

  @override
  String get obsAgentStatusIdle => 'خامل';

  @override
  String get obsAgentStatusParked => 'مركون';

  @override
  String get obsAgentStatusAborted => 'أُجهِض';

  @override
  String get obsAgentKindSub => 'فرعي';

  @override
  String get noChecksOnCommit => 'لم تُشغَّل أي فحوصات على هذا الإيداع.';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قيد التشغيل — $count مهمة',
      many: 'قيد التشغيل — $count مهمة',
      few: 'قيد التشغيل — $count مهام',
      two: 'قيد التشغيل — مهمتان',
      one: 'قيد التشغيل — مهمة واحدة',
      zero: 'قيد التشغيل — بلا مهام',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'نجحت كل الفحوصات — $count مهمة',
      many: 'نجحت كل الفحوصات — $count مهمة',
      few: 'نجحت كل الفحوصات — $count مهام',
      two: 'نجحت كل الفحوصات — مهمتان',
      one: 'نجحت كل الفحوصات — مهمة واحدة',
      zero: 'نجحت كل الفحوصات — بلا مهام',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اكتمل — $count مهمة',
      many: 'اكتمل — $count مهمة',
      few: 'اكتمل — $count مهام',
      two: 'اكتمل — مهمتان',
      one: 'اكتمل — مهمة واحدة',
      zero: 'اكتمل — بلا مهام',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total مهمة',
      many: '$total مهمة',
      few: '$total مهام',
      two: 'مهمتين',
      one: 'مهمة واحدة',
      zero: '0 مهام',
    );
    return 'فشل $failed من $_temp0';
  }

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مهمة',
      many: '$count مهمة',
      few: '$count مهام',
      two: 'مهمتان',
      one: 'مهمة واحدة',
      zero: 'بلا مهام',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return 'مصفوفة: ⁨$jobId⁩';
  }

  @override
  String get jobLogsPending => 'ستظهر السجلات هنا عند انتهاء المهمة.';

  @override
  String get jobLogsUnavailable => 'السجلات غير متاحة لهذه المهمة.';

  @override
  String get noLogsForStep => 'لم تُلتقط سجلات لهذه الخطوة.';

  @override
  String get jobLogsTruncated => 'السجل مقتطع — يُعرض أحدث المخرجات.';

  @override
  String get fullLog => 'السجل الكامل';

  @override
  String get copyLogs => 'نسخ السجلات';

  @override
  String get resizeGraph => 'اسحب لتغيير حجم المخطط';

  @override
  String workflowRunStartedAgo(String time) {
    return 'بدأ $time';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return 'اكتمل $time';
  }

  @override
  String get chatBridgesTitle => 'جسور الدردشة';

  @override
  String chatProviderDescription(String provider, String command) {
    return 'اذكر البوت في $provider لتكليف وكيل بأمر ما، أو أنشئ تذاكر باستخدام ⁨$command⁩.';
  }

  @override
  String chatConnectProvider(String provider) {
    return 'الاتصال بـ$provider';
  }

  @override
  String get chatDisconnectProvider => 'قطع الاتصال';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$botName في $teamName';
  }

  @override
  String get chatStateLive => 'مباشر';

  @override
  String get chatStateConnecting => 'جارٍ الاتصال…';

  @override
  String get chatStateError => 'خطأ في الاتصال';

  @override
  String get chatNotConnected => 'غير متصل';

  @override
  String chatStreamingUnavailable(String provider) {
    return 'البث المباشر متوقف لتطبيق $provider هذا — تصل الردود كرسالة واحدة.';
  }

  @override
  String chatAdminOnly(String provider) {
    return 'لا يستطيع سوى مسؤول توصيل $provider لمساحة العمل هذه.';
  }

  @override
  String chatConnectHint(String provider) {
    return 'أنشئ تطبيق $provider، ثم الصق بيانات اعتماده هنا. يتصل Control Center خارجيًا بـ$provider، لذا لا يحتاج هذا الخادم إلى عنوان عام.';
  }

  @override
  String chatOpenConsole(String provider) {
    return 'فتح وحدة تحكم $provider';
  }

  @override
  String get chatOpenSetupGuide => 'دليل الإعداد';

  @override
  String get chatFieldBotToken => 'رمز وصول البوت';

  @override
  String get chatFieldAppToken => 'رمز وصول على مستوى التطبيق';

  @override
  String get chatFieldConfigRefreshToken => 'رمز وصول تكوين التطبيق';

  @override
  String chatFieldOptional(String label) {
    return '$label (اختياري)';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return 'ربط حسابي في $provider';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return 'اربط حسابك في $provider حتى تُنسب إليك الرسائل التي ترسلها هناك.';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return 'مرتبط بـ⁨$externalUserId⁩';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return 'ربط حسابك في $provider';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return 'أرسل هذا الأمر إلى البوت في $provider. يعمل مرة واحدة وتنتهي صلاحيته خلال 15 دقيقة.';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return 'أصبح حسابك في $provider مرتبطًا الآن — الرسائل التي ترسلها هناك تُنسب إليك.';
  }

  @override
  String get chatLinkedAccounts => 'الحسابات المرتبطة';

  @override
  String chatNoLinkedAccounts(String provider) {
    return 'لم يربط أحد حسابه في $provider بعد.';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حساب مرتبط',
      many: '$count حسابًا مرتبطًا',
      few: '$count حسابات مرتبطة',
      two: 'حسابان مرتبطان',
      one: 'حساب مرتبط واحد',
      zero: 'لا حسابات مرتبطة',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '⁨$externalUserId⁩ · مطابقة عبر البريد الإلكتروني';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '⁨$externalUserId⁩ · رُبط برمز';
  }

  @override
  String get chatUnlink => 'إلغاء الربط';

  @override
  String get chatCustomizeBot => 'تخصيص البوت';

  @override
  String get chatCustomizeBotDescription =>
      'أعد تسمية البوت، أو غيّر ما يقوله عن نفسه، أو أعد تسمية أمر الشرطة المائلة.';

  @override
  String get chatCustomizeBotUnavailable =>
      'يحتاج Control Center إلى رمز وصول تكوين التطبيق لتعديل البوت. أعد الاتصال وضمِّن واحدًا.';

  @override
  String chatCreateAppTitle(String provider) {
    return 'إنشاء تطبيق $provider';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'يستطيع Control Center إنشاء تطبيق $provider نيابةً عنك، مع ضبط الأذونات والأحداث الصحيحة مسبقًا. ستُكمل في $provider، ثم تلصق بيانات الاعتماد هنا.';
  }

  @override
  String get chatCreateApp => 'إنشاء التطبيق';

  @override
  String get chatCreateAppCta => 'أنشئ التطبيق نيابةً عني';

  @override
  String get chatAppNameLabel => 'اسم التطبيق';

  @override
  String get chatBotDisplayNameLabel => 'اسم البوت (ما يكتبه الأعضاء بعد @)';

  @override
  String get chatDescriptionLabel => 'وصف قصير';

  @override
  String get chatAgentDescriptionLabel => 'ما يقول البوت إنه يستطيع فعله';

  @override
  String get chatCommandLabel => 'أمر الشرطة المائلة';

  @override
  String get chatDirectMessages => 'الرسائل المباشرة';

  @override
  String chatDirectMessagesHint(String provider) {
    return 'يتيح للأعضاء الدردشة مع البوت في رسالة مباشرة. قد يتطلب خطة $provider مدفوعة.';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return 'أنشأ $provider التطبيق ⁨$appId⁩.';
  }

  @override
  String chatRemainingSteps(String provider) {
    return 'بقيت خطوات قليلة لا يمكن تنفيذها إلا في $provider:';
  }

  @override
  String get chatStepAppToken => 'أنشئ رمز وصول على مستوى التطبيق';

  @override
  String get chatStepInstall => 'ثبّت التطبيق';

  @override
  String get chatOpenAppSettings => 'فتح إعدادات التطبيق';

  @override
  String get chatContinueToCredentials => 'لصق بيانات الاعتماد';

  @override
  String chatBotUpdated(String provider) {
    return 'تم تحديث البوت في $provider.';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return 'غيّر $provider أذونات التطبيق. أعد تثبيت التطبيق لتسري التغييرات.';
  }

  @override
  String get chatReinstallApp => 'إعادة تثبيت التطبيق';

  @override
  String chatIconNotEditable(String provider) {
    return 'لا يمكن تغيير أيقونة البوت إلا من إعدادات التطبيق في $provider نفسه.';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return 'يمكنك أيضًا إنشاؤه في $provider بنفسك — دون الحاجة إلى رمز وصول. الإعدادات أعلاه تنتقل مع الرابط.';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return 'إنشاء في $provider';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return 'فُتح $provider في متصفحك مع هذا التكوين معبأً مسبقًا. أنشئ التطبيق هناك، ثم أكمل هذه الخطوات وعُد ومعك رموز الوصول.';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return 'لا يُبلغ $provider عن التطبيق الذي أنشأه، لذا سيحتاج تخصيص البوت من هنا لاحقًا إلى رمز وصول تكوين التطبيق.';
  }

  @override
  String get chatStepCreateApp => 'أنشئ التطبيق من التكوين المعبأ مسبقًا';

  @override
  String chatStepCreateAppHint(String provider) {
    return 'اختر مساحة عمل في $provider وأكِّد.';
  }

  @override
  String get chatStepAppTokenHint =>
      '⁨Basic information → App-level tokens⁩، مع نطاق ⁨connections:write⁩.';

  @override
  String get chatStepInstallHint =>
      'من ⁨Install app⁩ انسخ رمز وصول OAuth الخاص بمستخدم البوت.';

  @override
  String get calendarUseBuiltinApp =>
      'استخدام تطبيق Google التابع لـControl Center';

  @override
  String get calendarUseBuiltinAppHint =>
      'وافق باستخدام حساب Google الخاص بك. لا شيء يلزم إعداده في Google Cloud.';

  @override
  String get calendarUseOwnClient => 'استخدام عميل Google Cloud الخاص بي';

  @override
  String get calendarUseOwnClientHint =>
      'أدخل عميل OAuth من مشروع Google Cloud الخاص بك.';

  @override
  String get aboutTitle => 'حول';

  @override
  String get aboutAppVersion => 'إصدار التطبيق';

  @override
  String get aboutServerVersion => 'الخادم المتصل';

  @override
  String get aboutRpcCatalog => 'كتالوج RPC';

  @override
  String get aboutServerUnknown => 'غير مُبلَّغ عنه';

  @override
  String get serverStaleTitle => 'الخادم المضمَّن أقدم من هذا التطبيق';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return 'إصدار cc_server قيد التشغيل هو ⁨$serverVersion⁩ بينما هذا التطبيق ⁨$appVersion⁩. أعد تشغيل التطبيق ليلتقط أحدث نسخة مضمَّنة من الخادم؛ وفي أثناء التطوير، أعد بناءه بالأمر ⁨`dart build cli`⁩ في ⁨apps/cc_server⁩.';
  }

  @override
  String get updateCheckButton => 'التحقق من التحديثات';

  @override
  String get updateChecking => 'جارٍ التحقق من التحديثات…';

  @override
  String get updateUpToDate => 'أنت على أحدث إصدار';

  @override
  String get updateDeferredBusy =>
      'يوجد تحديث جاهز لكن هناك اجتماع قيد التسجيل — سيُطلب التحديث بعد انتهائه.';

  @override
  String get updateOpenedReleasesPage => 'فُتحت صفحة الإصدارات في متصفحك.';

  @override
  String get updateCheckFailed => 'فشل التحقق من التحديثات';

  @override
  String updateAvailableVersion(String version) {
    return 'الإصدار ⁨$version⁩ متاح.';
  }

  @override
  String get updateBannerTitle => 'يتوفر إصدار جديد من Control Center';

  @override
  String get updateBannerRefresh => 'تحديث';

  @override
  String get updateBlockedRecording =>
      'التحديث متوقف مؤقتًا أثناء تسجيل اجتماع — سيُعاد التحميل عند انتهائه.';

  @override
  String get settingsScopeYou => 'أنت';

  @override
  String get settingsScopeWorkspace => 'مساحة العمل';

  @override
  String get settingsScopeServer => 'الخادم';

  @override
  String get settingsProfile => 'الملف الشخصي والهوية';

  @override
  String get settingsYourDevices => 'أجهزتك';

  @override
  String get settingsWorkspaceGeneral => 'عام';

  @override
  String get settingsServerConnection => 'الاتصال والحالة';

  @override
  String get settingsModelProviders => 'مزوّدو النماذج';

  @override
  String get settingsVoiceModels => 'نماذج الصوت والاجتماعات';

  @override
  String get settingsDiagnostics => 'التشخيص والخصوصية';

  @override
  String get settingsAbout => 'حول';

  @override
  String get settingsScopeBadgeYou => 'أنت';

  @override
  String get settingsScopeBadgeDevice => 'هذا الجهاز';

  @override
  String get settingsScopeBadgeWorkspace => 'مساحة العمل';

  @override
  String get settingsScopeBadgeServer => 'الخادم';

  @override
  String get settingsProfileDescription =>
      'اسمك وبريدك وهوية git في مساحة العمل هذه. تبديل المساحة يبدّل هذه الطبقة؛ المعرّف وتسجيل الدخول والأجهزة تبقى على الحساب.';

  @override
  String get settingsServerConnectionDescription =>
      'الخادم الذي يتصل به هذا العميل، وكيفية مشاركة هذا الخادم (mDNS، الأنفاق، المرحّل).';

  @override
  String get settingsAboutDescription => 'هوية البناء والتحديثات.';

  @override
  String get settingsDiagnosticsDescription =>
      'العزل والفهرسة والمزامنة والتسجيل وتقارير الأعطال لهذا التثبيت.';

  @override
  String get settingsWorkspaceGeneralDescription =>
      'الهوية والسياسة والاصطلاحات المشتركة بين الجميع في مساحة العمل هذه.';

  @override
  String get settingsWorkspaceMeetingsDescription =>
      'قوالب الملاحظات والأصوات المحفوظة لاجتماعات مساحة العمل هذه.';

  @override
  String get settingsWorkspacePolicyLabel => 'سياسة مساحة العمل';

  @override
  String get settingsWorkspacePolicyDescription =>
      'تنطبق على كل عضو وكل وكيل في مساحة العمل هذه.';

  @override
  String get settingsSecretGlobsLabel => 'استثناءات مسارات الأسرار';

  @override
  String get settingsSecretGlobsHelp =>
      'نمط glob واحد في كل سطر. تُخفى هذه المسارات عن المشاهدين والضيوف على الأسطح التي تعرض الكود، إضافةً إلى الافتراضيات المدمجة.';

  @override
  String get settingsReviewConcurrencyLabel => 'توزيع المراجعة';

  @override
  String get settingsReviewConcurrencyHelp =>
      'عدد المراجعين الذين يُرسَلون بالتوازي عندما لا يُحدَّد عدد صريح.';

  @override
  String get settingsReviewLevelLabel => 'مستوى المراجعة';

  @override
  String get settingsReviewLevelHelp =>
      'مدى عمق مراجعة الذكاء الاصطناعي، ومقدار ما يُبلَّغ عنه مقدَّمًا مما تجده. لا يُتجاهل أي شيء — المستوى الأخف يجمع الملاحظات الطفيفة بدلًا من إسقاطها.';

  @override
  String get reviewLevelLight => 'خفيف';

  @override
  String get reviewLevelBalanced => 'متوازن';

  @override
  String get reviewLevelThorough => 'شامل';

  @override
  String get reviewLevelLightHint =>
      'مراجع واحد. لا يُبلَّغ مقدَّمًا إلا عما يهم فعليًا.';

  @override
  String get reviewLevelBalancedHint =>
      'ثلاثة مراجعين يغطون ضمان الجودة والبنية والتنفيذ.';

  @override
  String get reviewLevelThoroughHint =>
      'يضيف متخصصين في الأمان والأداء، ويبلّغ عن كل ما يُعثر عليه.';

  @override
  String get askAiReviewAtLevel => 'المراجعة بمستوى مختلف';

  @override
  String reviewNitpicksGroup(int count) {
    return 'ملاحظات شكلية ($count)';
  }

  @override
  String get reviewFindingResolve => 'تم الإصلاح';

  @override
  String get reviewFindingResolveHint =>
      'ضع علامة على هذه الملاحظة كمُصلَحة. لن تُحتسب بعد الآن ضد المراجعة.';

  @override
  String get reviewFindingDismiss => 'تجاهل';

  @override
  String get reviewFindingDismissHint =>
      'ليست مشكلة حقيقية. سيتوقف المراجعون عن الإشارة إلى هذا النمط في طلبات السحب المستقبلية.';

  @override
  String get reviewFindingReopen => 'إعادة فتح';

  @override
  String get reviewFindingStatusUndoLabel => 'حالة الملاحظة';

  @override
  String get reviewFindingDismissTitle => 'تجاهل هذه الملاحظة';

  @override
  String get reviewFindingDismissReasonHint =>
      'لماذا لا ينطبق هذا؟ سيقرؤه المراجعون.';

  @override
  String reviewFindingStatusFailed(String error) {
    return 'تعذّر تحديث الملاحظة: ⁨$error⁩';
  }

  @override
  String get reviewStaleTitle => 'هذه المراجعة قديمة';

  @override
  String get reviewStaleBody =>
      'تقدّم طلب السحب منذ إجراء هذه المراجعة. قد تشير الملاحظات إلى كود لم يعد موجودًا.';

  @override
  String reviewStaleReviewedAt(String sha) {
    return 'روجع عند ⁨$sha⁩';
  }

  @override
  String get reviewStaleRerun => 'مراجعة مرة أخرى';

  @override
  String reviewStaleNotificationTitle(int prNumber) {
    return 'المراجعة قديمة على ⁨#$prNumber⁩';
  }

  @override
  String reviewStaleNotificationBody(String title) {
    return '$title فيه إيداعات جديدة منذ آخر مراجعة له.';
  }

  @override
  String get reviewCategorySecurity => 'الأمان';

  @override
  String get reviewCategoryStability => 'الاستقرار';

  @override
  String get reviewCategoryDataIntegrity => 'سلامة البيانات';

  @override
  String get reviewCategoryCorrectness => 'الصحة';

  @override
  String get reviewCategoryPerformance => 'الأداء';

  @override
  String get reviewCategoryMaintainability => 'قابلية الصيانة';

  @override
  String get reviewEffortQuickWin => 'مكسب سريع';

  @override
  String get reviewEffortModerate => 'متوسط';

  @override
  String get reviewEffortHeavyLift => 'جهد كبير';

  @override
  String get reviewProposedFix => 'الإصلاح المقترح';

  @override
  String get reviewAiAgentPrompt => 'موجّه لوكلاء الذكاء الاصطناعي';

  @override
  String get reviewCopyAiPrompt => 'نسخ الموجّه';

  @override
  String get settingsWorkspaceAdminOnly =>
      'لا يمكن تغيير هذه الإعدادات إلا لمسؤولي مساحة العمل.';

  @override
  String get chatMyAccountsTitle => 'حسابات الدردشة المرتبطة';

  @override
  String get settingsServerSso => 'تسجيل الدخول الموحّد';

  @override
  String get settingsServerSsoDescription =>
      'تسجيل الدخول عبر SAML وOpenID Connect مع توفير المستخدمين';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabledDescription =>
      'يمكن للمستخدمين تسجيل الدخول عبر هذا الموفّر';

  @override
  String get ssoEnabledDescriptionOn => 'تسجيل الدخول فعّال لهذا الموفّر';

  @override
  String get ssoIdpMetadataLabel => 'XML لبيانات تعريف IdP';

  @override
  String get ssoIdpMetadataHint => 'الصق XML الخاص بـEntityDescriptor من IdP';

  @override
  String get ssoEmailAttributeLabel => 'سمة البريد الإلكتروني';

  @override
  String get ssoDisplayNameAttributeLabel => 'سمة اسم العرض';

  @override
  String get ssoGroupsAttributeLabel => 'سمة المجموعات';

  @override
  String get ssoIssuerLabel => 'عنوان URL للمُصدِر';

  @override
  String get ssoClientIdLabel => 'معرّف العميل';

  @override
  String get ssoGroupsClaimLabel => 'مطالبة المجموعات';

  @override
  String get ssoAutoMemberLabel =>
      'إضافة المستخدمين إلى كل مساحة عمل عند أول تسجيل دخول';

  @override
  String get ssoAutoMemberDescription => 'أوقفه لاشتراط دعوة لكل مساحة عمل';

  @override
  String get ssoAllowJitLabel =>
      'توفير المستخدمين غير المعروفين عند أول تسجيل دخول';

  @override
  String get ssoAllowJitDescription =>
      'أوقفه لرفض المستخدمين الذين ليس لديهم حساب موجود';

  @override
  String get ssoAllowIdpInitiatedLabel =>
      'قبول تسجيل الدخول غير المطلوب (المبدوء من IdP)';

  @override
  String get ssoAllowIdpInitiatedDescription =>
      'حصرًا لبوابات IdP التي تشغّل التطبيقات مباشرة';

  @override
  String get ssoWantResponseSignedLabel => 'اشتراط مغلّف استجابة موقّع';

  @override
  String get ssoWantResponseSignedDescription =>
      'تواقيع التأكيدات مطلوبة دائمًا';

  @override
  String get ssoTestConnectionButton => 'اختبار الاتصال';

  @override
  String get ssoTestConnectionOk => 'الاتصال يعمل:';

  @override
  String get ssoCopySpMetadata => 'نسخ بيانات تعريف SP';

  @override
  String get ssoCopySpMetadataDone => 'نُسخت بيانات تعريف SP إلى الحافظة';

  @override
  String get ssoSavedToast => 'حُفظت إعدادات تسجيل الدخول الموحّد';

  @override
  String get ssoUnavailable =>
      'لا يعرض هذا الخادم إعدادات تسجيل الدخول الموحّد. حدّث ملف الخادم الثنائي وحاول مجددًا.';

  @override
  String get ssoScimCardTitle => 'توفير المستخدمين (SCIM)';

  @override
  String get ssoScimDescription =>
      'وجّه موصل SCIM لدى موفّر الهوية إلى نقطة النهاية أدناه مع رمز وصول من نوع bearer. إلغاء التوفير يُبطل الجلسات والوصول إلى مساحات العمل خلال ثوانٍ. يجب أن يكون الخادم قابلاً للوصول من IdP (نفق أو عنوان URL عام).';

  @override
  String get ssoScimEndpoint => 'نقطة نهاية SCIM';

  @override
  String get ssoScimEndpointUnknownOrigin =>
      'حدد عنوان URL العام للخادم أو فعّل نفقًا أولًا';

  @override
  String get ssoScimRegenerate => 'إعادة إنشاء رمز الوصول';

  @override
  String get ssoScimRegenerateConfirm =>
      'إنشاء رمز وصول bearer جديد لـSCIM؟ يتوقف الرمز السابق عن العمل فورًا.';

  @override
  String get ssoScimTokenTitle => 'رمز وصول bearer';

  @override
  String get ssoScimTokenPresent => 'يوجد رمز وصول مضبوط';

  @override
  String get ssoScimTokenAbsent => 'لا رمز وصول بعد — أنشئ واحدًا لتفعيل SCIM';

  @override
  String get ssoScimTokenOnce => 'رمز وصول SCIM (يُعرض مرة واحدة)';

  @override
  String ssoSignInWith(String provider) {
    return 'تسجيل الدخول عبر $provider';
  }

  @override
  String get ssoProbeFailed =>
      'تعذّر الوصول إلى ذلك الخادم لتسجيل الدخول الموحّد';

  @override
  String get ssoOpensBrowser => 'يفتح متصفحك لإكمال تسجيل الدخول';

  @override
  String get ssoWaitingForBrowser => 'في انتظار متصفحك لإكمال تسجيل الدخول…';

  @override
  String get ssoBrowserOpenFailed => 'تعذّر فتح متصفحك لتسجيل الدخول الموحّد';

  @override
  String get ssoUseManualPairing =>
      'تسجيل الدخول بدعوة أو مفتاح اقتران بدلًا من ذلك';

  @override
  String get ssoHideManualPairing => 'إخفاء الاقتران اليدوي';

  @override
  String get ssoClientIdHint => 'عميل عام (PKCE) — لا حاجة إلى سر';

  @override
  String get ssoClientSecretLabel => 'سر العميل (اختياري)';

  @override
  String get ssoClientSecretHintUnset => 'مطلوب فقط لعملاء IdP السرّيين';

  @override
  String get ssoClientSecretHintSet =>
      'يوجد سر مخزَّن — اتركه فارغًا للإبقاء عليه';

  @override
  String get ssoPairingToggle =>
      'السماح بالاقتران اليدوي (رموز الدعوة ومفاتيح الاقتران)';

  @override
  String get ssoPairingToggleDescription =>
      'أوقفه لجعل الانضمام عبر تسجيل الدخول الموحّد فقط — تصل الأجهزة الجديدة عبر تسجيلات دخول SSO؛ وتستمر الأجهزة الحالية في العمل';

  @override
  String get ssoPairConfirmTitle => 'الاتصال بالخادم؟';

  @override
  String ssoPairConfirmBody(String server) {
    return 'وصلت بيانات اعتماد تسجيل دخول للخادم ⁨$server⁩، لكن لم يُبدأ أي تسجيل دخول من هذا التطبيق. هل تريد الاتصال بهذا الخادم؟';
  }

  @override
  String get ssoPairConfirmConnect => 'اتصال';

  @override
  String get ssoPairConfirmCancel => 'تجاهل';

  @override
  String get forgeConnections => 'استضافة الكود';

  @override
  String get connect => 'اتصال';

  @override
  String get disconnect => 'قطع الاتصال';

  @override
  String get notConnected => 'غير متصل';

  @override
  String get checkingConnection => 'جارٍ التحقق من الاتصال…';

  @override
  String get fromEnvironment => 'من البيئة';

  @override
  String forgeTokenTitle(String forge) {
    return 'رمز وصول $forge';
  }

  @override
  String get settingsAudio => 'الصوت';

  @override
  String get settingsAudioDescription =>
      'الميكروفون والإملاء واكتشاف الاجتماعات وإخراج المشهد الصوتي.';

  @override
  String get audioDevicesSection => 'أجهزة الصوت';

  @override
  String get voiceInputBehaviorSection => 'الإملاء والاجتماعات';

  @override
  String get audioOutputDeviceTitle => 'جهاز الإخراج';

  @override
  String get audioOutputDefaultHint =>
      'يُشغَّل كل صوت التطبيق عبر مخرج النظام الافتراضي.';

  @override
  String get audioOutputGone =>
      'جهاز الإخراج المحدد لم يعد متصلاً — يُستخدم الجهاز الافتراضي للنظام حتى تختار جهازًا آخر.';

  @override
  String get reviewHubIntroBody =>
      'يحلل الوكلاء الفروقات، ويحددون مناطق التغيير، ويتوصلون إلى حكم بالإجماع.';

  @override
  String get reviewHubAlreadyRunning =>
      'هناك مراجعة قيد التشغيل بالفعل لطلب السحب هذا';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return 'منذ المراجعة الأخيرة: $resolved تم حلها · $added جديدة · $open لا تزال مفتوحة';
  }

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return 'تمت المراجعة سابقًا عند ⁨$sha⁩';
  }

  @override
  String reviewArtifactFixAll(int count) {
    return 'إصلاح $count من النتائج';
  }

  @override
  String reviewArtifactFixSelected(int count) {
    return 'إصلاح $count من النتائج المحددة';
  }

  @override
  String reviewArtifactCommentSelected(int count) {
    return 'التعليق على $count من النتائج المحددة';
  }

  @override
  String get webConnectTitle => 'الاتصال بـ Control Center';

  @override
  String get webConnectSubtitle =>
      'اتصل بخادم cc-server قيد التشغيل عبر WebSocket. يبقى مفتاحك على هذا الجهاز.';

  @override
  String get webConnectServerLabel => 'الخادم';

  @override
  String get webConnectDeviceIdLabel => 'معرّف الجهاز';

  @override
  String get webConnectPairingKeyLabel => 'مفتاح الاقتران';

  @override
  String get webConnectPairingKeyHint => 'الصق مفتاح PSK';

  @override
  String get webConnectStayConnected => 'البقاء متصلاً على هذا الجهاز';

  @override
  String get webConnectStayConnectedDetail =>
      'البقاء متصلاً على هذا الجهاز (يخزّن مفتاحك في هذا المتصفح)';

  @override
  String failedToCreateWorkspace(String error) {
    return 'فشل إنشاء مساحة العمل: $error';
  }

  @override
  String committedRelative(String relative) {
    return 'تم الإيداع $relative';
  }

  @override
  String get selectAgents => 'اختر الوكلاء';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count وكيل',
      many: '$count وكيلًا',
      few: '$count وكلاء',
      two: 'وكيلان',
      one: 'وكيل واحد',
      zero: 'لا وكلاء',
    );
    return '$_temp0';
  }

  @override
  String get newConversation => 'محادثة جديدة';

  @override
  String get untitledConversation => 'محادثة بلا عنوان';

  @override
  String get conversationTitleOptionalHint =>
      'اختياري — اتركه فارغًا وسيسميه نموذج العناوين تلقائيًا';

  @override
  String get conversationTitlesSectionTitle => 'عناوين المحادثات';

  @override
  String get conversationTitlesSectionCaption =>
      'اختر المشغّل الذي يسمّي المحادثات الجديدة في مساحة العمل هذه تلقائيًا. تبقى العناوين معطّلة حتى يُختار محوّل، وتنطبق على كل عضو.';

  @override
  String get conversationTitlesModelLabel => 'نموذج العناوين';

  @override
  String get conversationTitlesAdapterLabel => 'المحوّل';

  @override
  String get conversationTitlesAdapterHint => 'معطّل';

  @override
  String get conversationTitlesAdapterOff => 'معطّل';

  @override
  String get startThread => 'بدء سلسلة';

  @override
  String get deleteSpaceConfirm =>
      'هل تريد حذف هذه المساحة؟ ستُفقد كل الرسائل.';

  @override
  String threadTabTitle(String title) {
    return 'سلسلة: $title';
  }

  @override
  String threadReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رد',
      many: '$count ردًا',
      few: '$count ردود',
      two: 'ردان',
      one: 'رد واحد',
      zero: 'لا ردود',
    );
    return '$_temp0';
  }

  @override
  String threadLastReply(String time) {
    return 'آخر رد $time';
  }

  @override
  String signInWithProvider(String provider) {
    return 'تسجيل الدخول عبر $provider';
  }

  @override
  String get signInAgain => 'تسجيل الدخول مجددًا';

  @override
  String get signInNotFinished =>
      'لم يكتمل تسجيل الدخول بعد. أكمله في متصفحك ثم تحقق مجددًا.';

  @override
  String get signedOutTitle => 'لقد سُجّل خروجك';

  @override
  String get signedOutSubtitle =>
      'اتصالك بمستضيف الشيفرة لم يعد صالحًا — انتهت صلاحية رمز وصول، أو أُلغي وصوله. لم يتغير أي شيء آخر: سجّل الدخول مجددًا وستجد كل شيء كما تركته.';

  @override
  String get viaServerApp => 'عبر تطبيق هذا الخادم';

  @override
  String get ticketing => 'التذاكر';

  @override
  String get ticketingProviderHelp =>
      'حيث تُخزَّن تذاكرك. الخيار «محلي» يبقيها داخل Control Center.';

  @override
  String providerComingSoon(String provider) {
    return '$provider (قريبًا)';
  }

  @override
  String get ticketProviderLocal => 'محلي';

  @override
  String get addKey => 'إضافة مفتاح';

  @override
  String get providerApps => 'تطبيقات الموفّرين';

  @override
  String get providerAppsDescription =>
      'ترث مساحات العمل تطبيق GitHub هذا ما لم تختر تطبيقًا آخر أو رمز وصول شخصي. العمل في الخلفية — webhooks والاستطلاع والمزامنة — يعمل على التطبيق، لا على رمز شخص.';

  @override
  String get providerAppId => 'معرّف التطبيق';

  @override
  String get providerPrivateKey => 'المفتاح الخاص';

  @override
  String get providerClientId => 'معرّف العميل';

  @override
  String get providerClientSecret => 'سر العميل';

  @override
  String get providerApiKey => 'مفتاح API';

  @override
  String get providerCallbackUrl => 'عنوان URL لرد الاتصال';

  @override
  String get providerAppFullyConfigured =>
      'يمكن للخادم التصرف باسم نفسه، ويمكن للأشخاص تسجيل الدخول.';

  @override
  String get providerAppServerOnly =>
      'يمكن للخادم التصرف باسم نفسه. أضف معرّف عميل وسرًا للسماح للأشخاص بتسجيل الدخول.';

  @override
  String get providerAppSignInOnly =>
      'يمكن للأشخاص تسجيل الدخول. تعود الأعمال الخلفية إلى بيانات اعتمادهم.';

  @override
  String providerAppInstalledOn(String accounts) {
    return 'بيانات الاعتماد تعمل. مثبّت على: ⁨$accounts⁩';
  }

  @override
  String deviceCodeInstructions(String provider) {
    return 'أدخل هذا الرمز في صفحة $provider التي فُتحت للتو. وقد نُسخ إلى الحافظة.';
  }

  @override
  String get deviceCodeWaiting => 'في انتظار إكمالك العملية في المتصفح…';

  @override
  String get copyCodeAndOpen => 'نسخ الرمز والفتح';

  @override
  String get couldNotOpenBrowser =>
      'تعذّر فتح أي متصفح. انسخ الرابط وأكمل تسجيل الدخول بنفسك.';

  @override
  String get contextUsage => 'استخدام السياق';

  @override
  String get contextUsageFull => 'ممتلئ';

  @override
  String get contextUsageTokens => 'رمز';

  @override
  String get contextSeeMore => 'عرض المزيد';

  @override
  String get contextSegmentSystemPrompt => 'موجّه النظام';

  @override
  String get contextSegmentRules => 'القواعد';

  @override
  String get contextSegmentSkills => 'المهارات';

  @override
  String get contextSegmentToolDefinitions => 'تعريفات الأدوات';

  @override
  String get contextSegmentMcpTools => 'أدوات MCP والأدوات الديناميكية';

  @override
  String get contextSegmentDeferredTools => 'أدوات تُحمَّل عند الطلب';

  @override
  String get contextSegmentSubagents => 'تعريفات الوكلاء الفرعيين';

  @override
  String get contextSegmentMemory => 'الذاكرة';

  @override
  String get contextSegmentConversation => 'المحادثة';

  @override
  String get contextExplorerTitle => 'السياق';

  @override
  String get contextExplorerEverything => 'كل شيء';

  @override
  String get contextExplorerSelectPart => 'اختر جزءًا لفحص محتواه';

  @override
  String get contextExplorerUnavailable => 'تفصيل السياق غير متاح';

  @override
  String get contextRetry => 'إعادة المحاولة';

  @override
  String get settingsFieldOptional => 'اختياري';

  @override
  String get settingsFilterHint => 'تصفية هذه القائمة';

  @override
  String get settingsValueNotAvailable => 'غير متاح بعد';

  @override
  String get settingsNoEntriesYet => 'لا شيء هنا بعد';

  @override
  String get settingsChangedBadge => 'معدَّل';

  @override
  String get ssoConnectionCardDescription =>
      'اختر كيفية تسجيل الأشخاص الدخول إلى هذا الخادم، ثم فعّل ذلك الاتصال.';

  @override
  String get ssoUseSamlForSignIn => 'استخدام SAML لتسجيل الدخول';

  @override
  String get ssoUseOidcForSignIn => 'استخدام OpenID Connect لتسجيل الدخول';

  @override
  String get ssoSaveConnection => 'حفظ الاتصال';

  @override
  String get ssoStateLive => 'يعمل';

  @override
  String get ssoStateConfiguredOff => 'مُهيّأ، متوقف';

  @override
  String get ssoStateOnIncomplete => 'مفعّل، غير مكتمل';

  @override
  String get ssoStateActive => 'نشط';

  @override
  String get ssoStateAllowed => 'مسموح';

  @override
  String get ssoStateNoToken => 'لا يوجد رمز وصول';

  @override
  String get ssoSummaryDirectorySync => 'مزامنة الدليل';

  @override
  String get ssoSummaryManualPairing => 'اقتران يدوي';

  @override
  String get ssoNoMethodLiveNote =>
      'لا توجد طريقة تسجيل دخول قيد التشغيل. تنضم الأجهزة الجديدة بدعوة أو مفتاح اقتران حتى تهيّئ اتصالاً وتفعّله.';

  @override
  String get ssoMethodSamlBlurb =>
      'لموفّري الهوية الذين يدعمون SAML 2.0، مثل Okta أو Entra ID أو Google Workspace.';

  @override
  String get ssoMethodOidcBlurb =>
      'لموفّري الهوية الذين يدعمون OpenID Connect. عادةً هو الأسهل إعدادًا بين الاثنين.';

  @override
  String get ssoGroupIdentityProvider => 'موفّر الهوية';

  @override
  String get ssoGroupIdentityProviderSamlDescription =>
      'من أين تأتي التأكيدات، وكيف يتحقق هذا الخادم منها.';

  @override
  String get ssoGroupIdentityProviderOidcDescription =>
      'المُصدِر الذي يثق به هذا الخادم، والعميل الذي يوثّق هويته به.';

  @override
  String get ssoSpEntityIdShortLabel => 'معرّف كيان SP';

  @override
  String get ssoSpEntityIdDescription =>
      'اتركه فارغًا لاشتقاقه من عنوان URL للخادم.';

  @override
  String get ssoIssuerDescription =>
      'عنوان URL الأساسي الذي يقدّم مستند الاكتشاف الخاص بالموفّر.';

  @override
  String get ssoSecretStored => 'مخزَّن';

  @override
  String get ssoGroupHandoff => 'ما يحتاجه موفّر الهوية لديك';

  @override
  String get ssoGroupHandoffDescription =>
      'الصق هذه القيم في التطبيق الذي أنشأته لدى موفّرك.';

  @override
  String get ssoOriginUnknownTitle =>
      'هذا الخادم لا يعرف عنوان URL العام الخاص به';

  @override
  String get ssoOriginUnknownBody =>
      'تُبنى عناوين تسجيل الدخول ورد الاتصال منه، لذا لا يستطيع موفّرك الوصول إلى هذا الخادم حتى يُحدَّد عنوان. أضف عنوان URL عامًا أو فعّل نفقًا من الخادم ← الاتصال.';

  @override
  String get ssoAcsUrlLabel => 'عنوان URL لخدمة مستهلك التأكيدات (ACS)';

  @override
  String get ssoAcsUrlDescription => 'حيث ينشر موفّرك التأكيد الموقَّع.';

  @override
  String get ssoSpEntityIdResolvedLabel => 'معرّف كيان موفّر الخدمة';

  @override
  String get ssoMetadataUrlLabel => 'عنوان URL لبيانات SP الوصفية';

  @override
  String get ssoMetadataUrlDescription =>
      'الموفّرون الذين يستوردون البيانات الوصفية يمكنهم جلبها من هنا بدلاً من ذلك.';

  @override
  String get ssoRedirectUriLabel => 'معرّف URI لإعادة التوجيه';

  @override
  String get ssoRedirectUriDescription =>
      'أضف هذا إلى معرّفات URI المسموح بها لإعادة التوجيه في تطبيق موفّرك.';

  @override
  String get ssoSignInUrlLabel => 'عنوان URL لتسجيل الدخول';

  @override
  String get ssoSignInUrlDescription =>
      'وجّه الأشخاص إلى هنا لبدء تسجيل دخول موحّد.';

  @override
  String get ssoGroupAttributeMapping => 'تعيين السمات';

  @override
  String get ssoGroupAttributeMappingDescription =>
      'أي مطالبة تحمل كل حقل. أبقِ الإعدادات الافتراضية ما لم يغيّر موفّرك أسماءها.';

  @override
  String get ssoGroupAccess => 'الوصول والأدوار';

  @override
  String get ssoGroupAccessDescription =>
      'ما يُسمح لمن ينجح في تسجيل الدخول بفعله.';

  @override
  String get ssoDefaultRoleShortLabel => 'الدور الافتراضي';

  @override
  String get ssoDefaultRoleDescription =>
      'يُمنح لكل من لا تطابق مجموعاتُه أي تعيين أدناه.';

  @override
  String get ssoRoleMapShortLabel => 'تعيين المجموعات إلى الأدوار';

  @override
  String get ssoRoleMapDescription =>
      'المجموعة الأولى المطابقة هي المعتمدة. لا يمكن منح دور المالك بهذه الطريقة.';

  @override
  String get ssoRoleMapGroupHint => 'اسم المجموعة من موفّرك';

  @override
  String get ssoRoleMapAdd => 'إضافة تعيين';

  @override
  String get ssoRoleMapEmpty =>
      'لا توجد تعيينات — يحصل الجميع على الدور الافتراضي.';

  @override
  String get ssoAdvancedSummary =>
      'انحراف الساعة، تسجيل الدخول المبدوء من IdP، سياسة التوقيع';

  @override
  String get ssoClockSkewShortLabel => 'انحراف الساعة';

  @override
  String get ssoClockSkewDescription =>
      'ثوانٍ من التسامح في الطوابع الزمنية للتأكيدات. القيمة 90 تناسب معظم الموفّرين.';

  @override
  String get ssoScimGenerate => 'إنشاء رمز وصول';

  @override
  String get ssoScimTokenOnceBody =>
      'نُسخ إلى الحافظة. يُعرض مرة واحدة ولا يمكن استعادته، فالصقه لدى موفّرك الآن.';

  @override
  String get ssoPairingCardTitle => 'الاقتران اليدوي';

  @override
  String get ssoPairingCardDescription =>
      'الطريقة الأخرى للدخول إلى هذا الخادم: رموز الدعوة ومفاتيح الاقتران، للأجهزة التي لا تمر عبر تسجيل الدخول الموحّد.';

  @override
  String settingsCountOfTotal(int count, int total) {
    return '$count من $total';
  }

  @override
  String get providersNoneConnectedNote =>
      'لا يوجد موفّر متصل، لذا لا يملك وقت تشغيل الوكلاء المدمج ما يعمل عليه. أضف مفتاح API أو سجّل الدخول إلى أحد الموفّرين أدناه.';

  @override
  String get providersFilterHint => 'تصفية الموفّرين';

  @override
  String get providersNoneMatch => 'لا شيء يطابق هذه التصفية';

  @override
  String get providerDeniedHereTitle => 'مرفوض في مساحة العمل هذه';

  @override
  String get providerDeniedHereBody =>
      'لا يستطيع الوكلاء هنا استخدام هذا الموفّر رغم أنه متصل. مساحات العمل الأخرى غير متأثرة.';

  @override
  String get providerNeedsSignIn => 'سجّل الدخول لاستخدام هذا الموفّر';

  @override
  String get providerNeedsApiKey => 'أضف مفتاح API لاستخدام هذا الموفّر';

  @override
  String get providerApiKeyLabel => 'مفتاح API';

  @override
  String get providerGenerationDefaults => 'الإعدادات الافتراضية للموفّر';

  @override
  String get providerNoModelsYet =>
      'لم يُبلَّغ عن أي نماذج بعد. صِل الموفّر ثم زامِن.';

  @override
  String get providerModelsFilterHint => 'تصفية النماذج';

  @override
  String get adaptersNoneReadyNote =>
      'لم يُعثر على أي من أدوات CLI للمشغّلات المفهرسة على هذا الجهاز. ثبّت أحدها ثم حدّث.';

  @override
  String get adaptersFilterHint => 'تصفية المشغّلات';

  @override
  String get adaptersLaunchGroup => 'الإطلاق';

  @override
  String get adaptersLaunchGroupDescription =>
      'ما يُعطى لهذا المشغّل عندما يبدؤه وكيل. يمكنك ضبط هذه القيم قبل تثبيت الـ CLI إذا شئت.';

  @override
  String get adaptersEnvNone => 'لا شيء مضبوط';

  @override
  String adaptersEnvCount(int count) {
    return 'تم ضبط $count';
  }

  @override
  String get adapterArgumentsDescription =>
      'تُلحق بسطر أوامر المشغّل عند كل إطلاق.';

  @override
  String get defaultChatDescription =>
      'يشغّل المحادثات الجديدة وأي وكيل ليس له مشغّل خاص به.';

  @override
  String get shortTaskDescription =>
      'يشغّل الأعمال الخلفية السريعة مثل العناوين والملخصات. النموذج الأصغر هو الأنسب هنا.';

  @override
  String get settingsStateFailed => 'فشل';

  @override
  String get providerAppsGroupServer => 'التصرف باسم الخادم';

  @override
  String get providerAppsGroupServerDescription =>
      'لمساحات العمل التي ترث GitHub App لهذا التثبيت. مساحة بعملها أو PAT تُضبط تحت مساحة العمل → عام.';

  @override
  String get providerAppsGroupPrConversations => 'محادثات طلبات السحب';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      'كيف يخاطب المطوّرون هذا الخادم على GitHub في المساحات الوارثة. مساحة بعملها لها بوتها تحت مساحة العمل → عام. يعمل بلا webhook أو عنوان عام — الخادم يستطلع.';

  @override
  String get providerAppBotLogin => 'اسم دخول البوت';

  @override
  String get providerAppBotLoginEmpty =>
      'اختبر الاتصال للحصول على اسم دخول البوت.';

  @override
  String get providerAppAskOnGitHub => 'السؤال على GitHub';

  @override
  String get providerAppAskOnGitHubHint =>
      'اذكر اسم دخول البوت أعلاه في تعليق على طلب سحب — اللاحقة ⁨[bot]⁩ اختيارية — لطلب مراجعة أو طرح سؤال، أو رُدَّ داخل سلاسل مراجعته، أو أضف التسمية ⁨`ai-review`⁩ لطلب مراجعة.';

  @override
  String get providerAppsGroupSignIn => 'تسجيل دخول الأشخاص';

  @override
  String get providerAppsGroupSignInDescription =>
      'يتيح لكل عضو ربط حسابه الخاص والحصول على بيانات اعتماد خاصة به.';

  @override
  String get providerAppCapActsAsServer => 'يتصرف باسم الخادم';

  @override
  String get providerAppCapSignsIn => 'يسجّل دخول الأشخاص';

  @override
  String get portLabel => 'المنفذ';

  @override
  String get mcpNoTokenWarning =>
      'بدون رمز وصول، يمكن لأي جهة تصل إلى هذا المنفذ استدعاء كل الأدوات.';

  @override
  String get mcpBridgedToolsLabel => 'الأدوات';

  @override
  String get guardrailFamilyFiles => 'الملفات';

  @override
  String get guardrailFamilyGit => 'Git وطلبات السحب';

  @override
  String get guardrailFamilyMachine => 'الجهاز والشبكة';

  @override
  String get guardrailFamilyControl => 'الأسرار ومساحة العمل';

  @override
  String get guardrailScopeFieldLabel => 'تحرير القواعد لـ';

  @override
  String get guardrailScopeFieldDescription =>
      'النطاق الأضيق يغلب الأوسع. القواعد المضبوطة هنا تُطبَّق فوق ما هو موروث.';

  @override
  String get guardrailSetHere => 'مضبوط هنا';

  @override
  String get guardrailClearAllHere => 'مسح الكل';

  @override
  String get sandboxingCardLabel => 'العزل';

  @override
  String get sandboxingCardDescription =>
      'ما إذا كان عمل الوكلاء يجري معزولاً عن هذا المضيف، وما الذي لا يزال بوسع الوكيل المعزول الوصول إليه.';

  @override
  String get sandboxBackendNoneActive => 'المضيف، دون عزل';

  @override
  String get sandboxSummaryHost => 'المضيف';

  @override
  String get sandboxGroupIsolation => 'العزل';

  @override
  String get sandboxGroupIsolationDescription =>
      'أين تجري فعليًا عمليات الوكيل وكتاباته للملفات.';

  @override
  String get sandboxBackendFieldDescription =>
      'الخيار التلقائي ينتقي أقوى ما يدعمه هذا المضيف. ثبّت واحدًا لمنع تغيّره دون علمك.';

  @override
  String get sandboxCapabilitiesDescription =>
      'الثغرات المفتوحة عبر الحدود. كل واحدة منها شيء لا يزال بوسع الوكيل المعزول فعله تجاه العالم الخارجي.';

  @override
  String get sandboxSummaryInForce => 'ساري المفعول';

  @override
  String get rigsInstallHintLabel => 'كيفية التثبيت';

  @override
  String get rigsStarting => 'قيد البدء';

  @override
  String get rigsResidentMemory => 'الذاكرة المقيمة';

  @override
  String get installedLabel => 'مثبّت';

  @override
  String get notInstalledLabel => 'غير مثبّت';

  @override
  String ssoOtherKindUnsaved(String method) {
    return 'لدى $method تغييرات غير محفوظة';
  }

  @override
  String get collapseComment => 'طي التعليق';

  @override
  String get expandComment => 'توسيع التعليق';

  @override
  String get suggestedChange => 'تغيير مقترح';

  @override
  String get emptyComment => 'تعليق فارغ';

  @override
  String repliesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رد',
      many: '$count ردًا',
      few: '$count ردود',
      two: 'ردان',
      one: 'رد واحد',
      zero: 'لا ردود',
    );
    return '$_temp0';
  }

  @override
  String get pendingReview => 'مراجعة معلّقة';

  @override
  String failedToResolveConversation(String error) {
    return 'تعذّر تحديث المحادثة: $error';
  }

  @override
  String get addSingleComment => 'إضافة تعليق واحد';

  @override
  String get addToReview => 'إضافة إلى المراجعة';

  @override
  String get startAReview => 'بدء مراجعة';

  @override
  String get reviewNeedsABody =>
      'اكتب ملخصًا أو أضف تعليقًا مضمّنًا إلى قائمة الانتظار أولاً';

  @override
  String get reviewSubmitted => 'تم إرسال المراجعة';

  @override
  String get finishYourReview => 'أنهِ مراجعتك';

  @override
  String get commentVerdict => 'تعليق';

  @override
  String pendingCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تعليق معلّق',
      many: '$count تعليقًا معلّقًا',
      few: '$count تعليقات معلّقة',
      two: 'تعليقان معلّقان',
      one: 'تعليق واحد معلّق',
      zero: 'لا تعليقات معلّقة',
    );
    return '$_temp0';
  }

  @override
  String andNMore(int count) {
    return 'و$count أخرى';
  }

  @override
  String get queuedCommentHint => 'يُرسل هذا التعليق عند إرسال مراجعتك.';

  @override
  String commentOnLinesRange(int start, int end) {
    return 'الأسطر من $start إلى $end';
  }

  @override
  String get claudeAccountsTitle => 'حسابات Claude Code';

  @override
  String get claudeAccountsDescription =>
      'كل حساب هو تسجيل دخول منفصل إلى Claude Code. تستخدم عمليات التشغيل الحسابات المرفقة أدناه بهذا الترتيب.';

  @override
  String get claudeAccountsEmpty => 'لا حسابات بعد';

  @override
  String get claudeAccountAdd => 'إضافة حساب';

  @override
  String get claudeAccountSignIn => 'تسجيل الدخول';

  @override
  String get claudeAccountSignInAgain => 'تسجيل الدخول مجددًا';

  @override
  String get claudeAccountSignInHint =>
      'شغّل هذا في طرفية على الخادم. سيفتح متصفحًا لإكمال تسجيل الدخول، ويكتب بيانات الاعتماد في دليل هذا الحساب.';

  @override
  String get claudeAccountSignedOut => 'مُسجَّل الخروج';

  @override
  String get claudeAccountExpired => 'انتهت صلاحية تسجيل الدخول';

  @override
  String claudeAccountExpiredDetail(String when) {
    return 'انتهت صلاحية تسجيل الدخول في $when. سجّل الدخول مجددًا لاستخدام هذا الحساب.';
  }

  @override
  String get claudeAccountMakeDefault => 'جعله الافتراضي';

  @override
  String get claudeAccountDefault => 'افتراضي';

  @override
  String claudeAccountRemoveConfirm(String label) {
    return 'هل تريد إزالة $label؟';
  }

  @override
  String get claudeAccountRemoveDetail =>
      'هذا يسجّل خروج الحساب ويحذف دليله على الخادم. تسجيل الدخول نفسه لا يتأثر.';

  @override
  String claudeAccountStatusUnknown(String error) {
    return 'تعذّر التحقق من هذا الحساب: $error';
  }

  @override
  String claudeAccountUsedPercent(String percent) {
    return 'استُخدم $percent%';
  }

  @override
  String get accountPoolStrategy => 'التناوب';

  @override
  String get accountPoolPinned => 'مثبّت';

  @override
  String get accountPoolRoundRobin => 'بالتناوب الدوري';

  @override
  String get accountPoolSerial => 'واحد تلو الآخر';

  @override
  String get accountPoolPinnedHint =>
      'ابدأ دائمًا بالحساب الأول. تبقى البقية كاحتياط إذا فشل.';

  @override
  String get accountPoolRoundRobinHint =>
      'وزّع عمليات التشغيل على الحسابات، بالانتقال إلى التالي مع كل إرسال.';

  @override
  String get accountPoolSerialHint =>
      'استنفد الحساب الأول قبل الانتقال إلى التالي.';

  @override
  String get accountPoolMoveUp => 'نقل لأعلى';

  @override
  String get accountPoolMoveDown => 'نقل لأسفل';

  @override
  String get accountPoolUsingAll =>
      'لا شيء مرفق بعد — تُستخدم كل الحسابات بهذا الترتيب.';

  @override
  String get accountPoolInheriting => 'يرث حسابات مساحة العمل.';

  @override
  String get accountPoolResetToWorkspace =>
      'إعادة التعيين إلى حسابات مساحة العمل';

  @override
  String accountPoolCoolingOff(String when) {
    return 'نفدت الحصة حتى $when';
  }

  @override
  String get accountPoolSignedOut => 'مُسجَّل الخروج';

  @override
  String get accountPoolExpired => 'انتهت صلاحية تسجيل الدخول';

  @override
  String accountPoolLoadFailed(String error) {
    return 'تعذّر تحميل التناوب: $error';
  }

  @override
  String get providerSignedInAccount => 'الحساب المسجّل دخوله';

  @override
  String get agentAccountsTab => 'الحسابات';

  @override
  String get agentClaudeAccountsNoticeTitle => 'حسابات Claude Code متعددة';

  @override
  String agentClaudeAccountsNoticeBody(int count) {
    return 'يسجّل هذا المشغّل الدخول بأحد حسابات Claude Code البالغ عددها $count على هذا المضيف. اختر أيها، أو ناوب بينها، من تبويب الحسابات.';
  }

  @override
  String get agentAccountsDescription =>
      'أي الحسابات تستخدمها عمليات تشغيل هذا الوكيل. كل كتلة تبدأ وارثةً اختيار مساحة العمل.';

  @override
  String get agentAccountsNothingToRotate =>
      'لا شيء للتناوب — صِل حسابًا ثانيًا أو مفتاحًا أولاً.';

  @override
  String failedToPostReply(String error) {
    return 'تعذّر نشر الرد: $error';
  }

  @override
  String commentOnLine(int line) {
    return 'السطر $line';
  }

  @override
  String get viewInDiff => 'عرض في الفروقات';

  @override
  String get subscriptionUsagePreviousAccount => 'الحساب السابق';

  @override
  String get subscriptionUsageNextAccount => 'الحساب التالي';

  @override
  String inReplyTo(String path) {
    return 'ردًا على ⁨$path⁩';
  }

  @override
  String get subscriptionUsageNoneReported =>
      'لم يُبلَّغ عن أي استخدام لهذا الحساب.';

  @override
  String get subscriptionUsageCredits => 'الأرصدة';

  @override
  String get reviewHubStaticRule => 'قاعدة ثابتة';

  @override
  String get reviewHubStarted => 'بدأت المراجعة';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return 'عُثر عليها بقاعدة حتمية (⁨$rule⁩) على سطر يضيفه طلب السحب هذا — وليس بوكيل مراجع.';
  }

  @override
  String get prReviewArtifactTab => 'مراجعة PR';

  @override
  String get prReviewRunning => 'تجري مراجعة طلب السحب هذا…';

  @override
  String get prReviewStarting => 'جارٍ بدء المراجعة…';

  @override
  String get prReviewStartingBody =>
      'يجري تجهيز شجرة العمل لطلب السحب هذا. يبدأ المراجعون فور جاهزيتها.';

  @override
  String get prReviewFailed => 'فشلت المراجعة.';

  @override
  String get prReviewRerunning => 'جارٍ إعادة المراجعة…';

  @override
  String get prReviewNoOpenFindings => 'لا نتائج مفتوحة';

  @override
  String prReviewOpenFindings(int count) {
    return '$count نتيجة مفتوحة';
  }

  @override
  String subscriptionUsageSpend(String used, String limit) {
    return '$used من $limit';
  }

  @override
  String reviewCommentsPosted(int posted, int skipped, int failed) {
    return 'نُشر $posted من التعليقات باسم البوت. تم تخطي $skipped (بلا مرساة ملف)، وفشل $failed.';
  }

  @override
  String reviewFindingsOutOfDiff(int count, String files) {
    return '$count من النتائج تستهدف شيفرة لا يغيّرها طلب السحب هذا (⁨$files⁩). لا يقبل GitHub التعليقات المضمّنة إلا على الفروقات.';
  }

  @override
  String get reviewRailReport => 'التقرير';

  @override
  String get reviewNoFindingsTitle => 'لا نتائج مراجعة بعد';

  @override
  String get reviewNoFindingsHint => 'تظهر النتائج هنا عندما ينشرها الوكلاء.';

  @override
  String reviewShowDismissed(int count) {
    return 'إظهار $count مستبعدة';
  }

  @override
  String reviewHideDismissed(int count) {
    return 'إخفاء $count مستبعدة';
  }

  @override
  String reviewDisagreementsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'رُصد $count خلاف بين المراجعين',
      many: 'رُصد $count خلافًا بين المراجعين',
      few: 'رُصدت $count خلافات بين المراجعين',
      two: 'رُصد خلافان بين المراجعين',
      one: 'رُصد خلاف واحد بين المراجعين',
      zero: 'لم يُرصد أي خلاف بين المراجعين',
    );
    return '$_temp0';
  }

  @override
  String get reviewFilterKind => 'النوع';

  @override
  String get reviewFilterStatus => 'الحالة';

  @override
  String get reviewKindBug => 'خلل';

  @override
  String get reviewKindSuggestion => 'اقتراح';

  @override
  String get reviewKindRecommendation => 'توصية';

  @override
  String get reviewKindQuestion => 'سؤال';

  @override
  String get reviewKindTicket => 'تذكرة';

  @override
  String get archiveSpace => 'أرشفة المساحة';

  @override
  String get archivedSpaces => 'المساحات المؤرشفة';

  @override
  String get archivedSpacesEmpty => 'لا مساحات مؤرشفة';

  @override
  String get restoreSpace => 'استعادة';

  @override
  String archivedWhen(String time) {
    return 'أُرشفت $time';
  }

  @override
  String get deleteSpacePermanently => 'حذف نهائيًا';

  @override
  String get renameSpace => 'إعادة تسمية المساحة';

  @override
  String get renameConversation => 'إعادة تسمية المحادثة';

  @override
  String get spaceActions => 'إجراءات المساحة';

  @override
  String get conversationActions => 'إجراءات المحادثة';

  @override
  String get editSpaceRepos => 'تحرير المستودعات';

  @override
  String get editSpaceReposTitle => 'مستودعات المساحة';

  @override
  String get editSpaceReposWarning =>
      'إضافة مستودع تنشئ نسخة منه داخل هذه المساحة؛ وإزالته تحذف مجلده.';

  @override
  String get agentSectionIdentity => 'الهوية';

  @override
  String get agentSectionRuntime => 'وقت التشغيل';

  @override
  String get agentSectionGuardrails => 'الضوابط';

  @override
  String orgChartReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مرؤوس',
      many: '$count مرؤوسًا',
      few: '$count مرؤوسين',
      two: 'مرؤوسان',
      one: 'مرؤوس واحد',
      zero: 'لا مرؤوسين',
    );
    return '$_temp0';
  }

  @override
  String get teamsFilterHint => 'تصفية الفرق…';

  @override
  String get teamsSummaryWithLeader => 'لديها قائد';

  @override
  String teamCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فريق',
      many: '$count فريقًا',
      few: '$count فرق',
      two: 'فريقان',
      one: 'فريق واحد',
      zero: 'لا فرق',
    );
    return '$_temp0';
  }

  @override
  String agentDeleteLongDescription(String name) {
    return 'حذف $name يزيل ملفه التعريفي وروابط مهاراته وسجل تشغيله. لا يمكن التراجع عن هذا.';
  }

  @override
  String get resetToDefault => 'إعادة التعيين إلى الافتراضي';

  @override
  String get newAgent => 'وكيل جديد';

  @override
  String get newSkill => 'مهارة جديدة';

  @override
  String get zoomIn => 'تكبير';

  @override
  String get zoomOut => 'تصغير';

  @override
  String get resetZoom => 'إعادة تعيين التكبير';

  @override
  String get imageHostedOnGitHub => 'صورة مستضافة على GitHub';

  @override
  String get imageOpenExternally => 'صورة · فتح خارجيًا';

  @override
  String get memoryScopeAll => 'كل النطاقات';

  @override
  String get memoryScopeWorkspace => 'على مستوى مساحة العمل';

  @override
  String get memoryScopeFilterLabel => 'تصفية حسب النطاق';

  @override
  String memoryScopeRepoTooltip(String repo) {
    return 'مقصور على مستودع ⁨$repo⁩';
  }

  @override
  String get toolScreenshot => 'لقطة شاشة من الوكيل';

  @override
  String get toolImageUnavailable => 'الصورة غير متاحة';

  @override
  String toolImagesUnavailable(int count) {
    return '$count من الصور غير متاحة';
  }

  @override
  String get shakeUnavailable => 'خاصية النفض غير متاحة على هذا الخادم';

  @override
  String get shakeNothing => 'لا شيء لنفضه — الأدوار الأخيرة محمية';

  @override
  String shakeDone(int tokens) {
    return 'حُرر نحو $tokens رمز';
  }

  @override
  String get compactionDivider => 'تم الضغط';

  @override
  String compactionDividerCount(int count) {
    return 'تم الضغط · طُويت $count رسالة';
  }

  @override
  String get composerDropToAttach => 'أفلت للإرفاق';

  @override
  String get attachmentUnavailable => 'المرفق غير متاح';

  @override
  String get attachmentUnavailableDetail =>
      'لم يعد هذا المرفق محفوظًا في الذاكرة. أرفقه مجددًا لمعاينته.';

  @override
  String get attachmentPreviewFailed => 'تعذّر فتح هذا الملف';

  @override
  String get attachmentPreviewUnsupported => 'لا معاينة لهذا النوع من الملفات';

  @override
  String get attachmentTooLargeToPreview => 'أكبر من أن يُعايَن';

  @override
  String get attachmentOpenExternally => 'فتح في التطبيق الافتراضي';

  @override
  String get asideUnavailable =>
      'عيّن نموذج المهام السريعة في إعدادات مساحة العمل لاستخدام هذا';

  @override
  String get asideEmpty => 'لا شيء للعمل عليه بعد';

  @override
  String get asideFailed => 'تعذّر الحصول على إجابة';

  @override
  String get handoffTitle => 'التسليم';

  @override
  String get asideTitle => 'سؤال جانبي';

  @override
  String get attachFilesOrDrop => 'أرفق ملفات — أو أفلتها هنا';

  @override
  String get guidedGoalTitle => 'صقل الهدف';

  @override
  String get guidedGoalIntro =>
      'الوكيل الذي يعمل دون إشراف يحتاج إلى معرفة متى ينتهي بالضبط. بضعة أسئلة أولاً.';

  @override
  String get guidedGoalAnswerHint => 'إجابتك';

  @override
  String get guidedGoalNext => 'التالي';

  @override
  String get guidedGoalStart => 'بدء الهدف';

  @override
  String get guidedGoalSkip => 'تخطٍّ وتشغيل كما هو مكتوب';

  @override
  String guidedGoalStillMissing(String items) {
    return 'لا يزال غير محدد: $items';
  }

  @override
  String get conversationTreeTitle => 'شجرة المحادثة';

  @override
  String conversationTreeBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فرع',
      many: '$count فرعًا',
      few: '$count فروع',
      two: 'فرعان',
      one: 'فرع واحد',
      zero: 'لا فروع',
    );
    return '$_temp0';
  }

  @override
  String get conversationTreeSwitch => 'المتابعة من هنا';

  @override
  String get conversationTreeFork => 'تفريع إلى محادثة جديدة';

  @override
  String get conversationTreeCurrent => 'على هذا الفرع';

  @override
  String get conversationTreeEmpty => 'لا شيء هنا بعد';

  @override
  String get conversationTreeForked => 'تم التفريع إلى محادثة جديدة';

  @override
  String get conversationTreeSwitched => 'تجري المتابعة الآن من تلك الرسالة';

  @override
  String exportSaved(String path) {
    return 'حُفظ في ⁨$path⁩';
  }

  @override
  String get exportFailed => 'تعذّرت كتابة التصدير';

  @override
  String get contextCommandNoAgent =>
      'لا يوجد وكيل في هذه المحادثة، فلا توجد نافذة سياق لفتحها';

  @override
  String contextCommandNoSuchAgent(String name, String names) {
    return 'لا يوجد وكيل باسم «$name» في هذه المحادثة. جرّب: $names';
  }

  @override
  String get dumpCopied => 'نُسخ نص المحادثة إلى الحافظة';

  @override
  String get messageQueueHint =>
      'واصل الكتابة لوضع تغييرات لاحقة في قائمة الانتظار';

  @override
  String get steerNow => 'توجيه';

  @override
  String get steeringQueueLabel => 'رسائل التوجيه في قائمة الانتظار';

  @override
  String get steeringDeliverUnavailable =>
      'لا يوجد وكيل قيد التشغيل يمكنه تلقي ذلك الآن — يبقى في قائمة الانتظار.';

  @override
  String get reorderSteeringCard => 'إعادة ترتيب الرسالة في قائمة الانتظار';

  @override
  String get editSteeringCard => 'تحرير الرسالة في قائمة الانتظار';

  @override
  String get deleteSteeringCard => 'حذف الرسالة من قائمة الانتظار';

  @override
  String get steeringBadge => 'موجَّه';

  @override
  String get settingsSandboxLabel => 'البيئة المعزولة';

  @override
  String get sandboxExecGrantsTitle => 'أذونات الملفات التنفيذية';

  @override
  String get sandboxExecGrantsSubtitle =>
      'البرامج التي يجوز للوكلاء تشغيلها من نسخة العمل الخاصة بهم من مستودعاتك. كل إدخال وافقتَ عليه عندما سألت البيئة المعزولة.';

  @override
  String get sandboxExecGrantsEmpty =>
      'لم تُسجَّل أي قرارات بعد. ستُسأل أول مرة يحتاج فيها وكيل إلى تشغيل برنامج من نسخة عمله.';

  @override
  String get sandboxExecGrantRevoke => 'إبطال';

  @override
  String get sandboxExecGrantAllowed => 'مسموح';

  @override
  String get sandboxExecGrantBlocked => 'محظور';

  @override
  String get sandboxExecGrantRevokeConfirmTitle => 'هل تريد إبطال هذا القرار؟';

  @override
  String get sandboxExecGrantRevokeConfirmBody =>
      'ستُسأل مجددًا في المرة القادمة التي يحتاج فيها وكيل إلى تشغيل برنامج من هذه النسخة.';

  @override
  String get repoScriptsTest => 'اختبار';

  @override
  String get repoScriptsTestTooltip =>
      'شغّل هذه المسودة في نسخة مؤقتة من المستودع';

  @override
  String get repoScriptsRunKindTest => 'اختبار';

  @override
  String get demoBadgeLabel => 'تجريبي';

  @override
  String get demoFilePickerTitle => 'ملفات تجريبية';

  @override
  String get demoFilePickerBody =>
      'النسخة التجريبية تحاكي الرفع: اختر أيًا من هذه الملفات وسيُرفق برسالتك دون لمس القرص.';

  @override
  String get demoFilePickerAttach => 'إرفاق';

  @override
  String get demoReadOnlySave => 'للقراءة فقط في النسخة التجريبية';

  @override
  String get demoBadgeTooltip =>
      'أنت تستكشف نسخة تجريبية. البيانات خيالية والوكلاء يعملون وفق نص معد.';

  @override
  String get demoFirstRunTitle => 'أنت في عرض تجريبي مباشر';

  @override
  String demoFirstRunBody(int minutes) {
    return 'هذا هو التطبيق الحقيقي يعمل على شيفرة حقيقية — البيانات وحدها مُختلقة. يبث الوكلاء عمليات تشغيل حقيقية من نص معد، فلا يصل شيء إلى نموذج ولا يعمل شيء على جهاز. مساحة عملك لك وحدك وتختفي بعد $minutes دقيقة.';
  }

  @override
  String get demoFirstRunDismiss => 'فهمت';

  @override
  String get demoTourTitle => 'أين تنظر أولاً';

  @override
  String get demoTourSubtitle => 'أربعة أماكن تُظهر ما يفعله التطبيق فعليًا.';

  @override
  String get demoTourSkip => 'تخطٍّ';

  @override
  String get demoTourStarRepo => 'ضع نجمة على GitHub';

  @override
  String get demoTourOpen => 'فتح';

  @override
  String get demoTourSpacesTitle => 'تحدث إلى وكيل';

  @override
  String get demoTourSpacesBody =>
      'أرسل رسالة في مساحة وشاهد تشغيلاً يتدفق — التفكير واستدعاءات الأدوات والتكلفة، تمامًا كما يُعرض التشغيل الحقيقي.';

  @override
  String get demoTourReviewTitle => 'راجع طلب سحب';

  @override
  String get demoTourReviewBody =>
      'افتح ⁨#412⁩. اترك تعليقًا مضمّنًا أو أرسل مراجعة؛ كلماتك تصل إلى السلسلة وتبقى هناك.';

  @override
  String get demoTourTicketsTitle => 'تابع العمل';

  @override
  String get demoTourTicketsBody =>
      'التذاكر والمهام والخطط مرتبطة بالمحادثات نفسها التي يجريها الوكلاء.';

  @override
  String get demoTourInboxTitle => 'شاهد العملية بأكملها';

  @override
  String get demoTourInboxBody =>
      'كل تنبيه من كل ركن يصل إلى وارد واحد — المراجعات والتذاكر وعمليات التشغيل والاجتماعات.';

  @override
  String get demoUnavailableTitle => 'غير متاح في النسخة التجريبية';

  @override
  String get demoUnavailableTerminal =>
      'تشغّل الطرفية صدفة أوامر حقيقية على مضيف الخادم. لا تملك النسخة التجريبية أي سطح تنفيذ على الإطلاق — وهذا ما يجعلها آمنة للفتح أمام العموم.';

  @override
  String get demoUnavailableRig =>
      'الحاوية المعزولة هي آلة افتراضية مؤقتة يقودها وكيل. لا تشغّل النسخة التجريبية أيًا منها: نقطة نهاية عامة يمكنها بدء VM ليست نسخة تجريبية.';

  @override
  String get demoUnavailableEditor =>
      'يشغّل المحرر داخل المتصفح عملية code-server على نسخة حقيقية من الشيفرة. لا تملك النسخة التجريبية أيًا من الاثنين.';

  @override
  String get demoUnavailableFeeds =>
      'تقرأ النسخة التجريبية موجزات حقيقية، لكن قائمة اشتراكاتها ثابتة. إضافة موجز أو إزالته معطّلة هنا.';

  @override
  String get demoUnavailableForge =>
      'لا تحمل النسخة التجريبية أي بيانات اعتماد ولا تتصل أبدًا بـ GitHub أو GitLab أو Linear. طلبات السحب فيها نماذج ثابتة، وتعليقاتك عليها تُخزَّن محليًا.';

  @override
  String get demoUnavailableModels =>
      'لا تستدعي النسخة التجريبية أي نموذج. عمليات تشغيل الوكلاء إعادة عرض وفق نص معد، ولهذا لا تكلف شيئًا ولا تصل إلى أي موفّر.';

  @override
  String get demoUnavailableMcp =>
      'سطح أدوات MCP غير مركّب في النسخة التجريبية، فلا يمكن لأي عميل خارجي الاتصال به.';

  @override
  String get demoUnavailableRepos =>
      'لا تسحب النسخة التجريبية أي شيفرة ولا تشغّل Git. المستودع الذي تراه نموذج ثابت خلف طلبات السحب.';

  @override
  String get demoUnavailableSkills =>
      'تثبيت مهارة يعني تنزيل شيفرة وفحصها. النسخة التجريبية لا تجلب شيئًا.';

  @override
  String get demoUnavailableSso =>
      'تسجيل الدخول الموحّد هو تهيئة للخادم. تسجّلك النسخة التجريبية كضيف مؤقت بدلاً من ذلك.';

  @override
  String get demoUnavailableAudio =>
      'يتطلب التسجيل والإملاء التقاط الصوت ونموذج كلام على المضيف. لا توفر النسخة التجريبية أيًا منهما، لذا اجتماعاتها نصوص دون تشغيل صوتي.';

  @override
  String get demoUnavailableServerAdmin =>
      'هذه إدارة للخادم. تمنح النسخة التجريبية كل زائر مساحة عمل مؤقتة خاصة به ولا شيء غيرها.';

  @override
  String get demoUnavailablePipelines =>
      'لا يمكن تشغيل المسارات هنا. الزائر الذي يستطيع كتابة خطوة bash وتشغيلها — يدوياً أو عبر محفّز حدث — ينفّذ رمزاً على هذا المضيف.';

  @override
  String get settingsBackupRestore => 'النسخ الاحتياطي والاستعادة';

  @override
  String get settingsBackupRestoreDescription =>
      'لقطات لكل قاعدة بيانات على هذا الخادم، مع تصدير مساحة عمل واحدة واستيرادها وحذفها.';

  @override
  String get backupSnapshotsLabel => 'لقطات التثبيت';

  @override
  String get backupSnapshotsExplainer =>
      'تنسخ اللقطة كل قاعدة بيانات إلى مجلد مؤرَّخ على مضيف الخادم. استعادة التثبيت بأكمله تعني نسخ ذلك المجلد مرة أخرى مع إيقاف الخادم؛ ويمكن استعادة مساحة عمل واحدة من هنا.';

  @override
  String get backupNowAction => 'نسخ احتياطي الآن';

  @override
  String backupSnapshotWritten(String path) {
    return 'كُتبت اللقطة في ⁨$path⁩';
  }

  @override
  String get backupNoSnapshots =>
      'لا لقطات بعد. لا تُلتقط إلا عندما تطلبها — لا شيء مجدول.';

  @override
  String get backupSnapshotComplete => 'مكتملة';

  @override
  String get backupSnapshotIncomplete => 'غير مكتملة';

  @override
  String get backupSnapshotIncompleteNote =>
      'ملف البيان مفقود أو يسمّي ملفات غير موجودة، لذا لا يمكن لهذه اللقطة استعادة التثبيت بأكمله. ملفات مساحات العمل الموجودة فيها لا يزال بالإمكان اعتمادها واحدًا تلو الآخر.';

  @override
  String backupSnapshotWorkspaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مساحة عمل',
      many: '$count مساحة عمل',
      few: '$count مساحات عمل',
      two: 'مساحتا عمل',
      one: 'مساحة عمل واحدة',
      zero: 'لا مساحات عمل',
    );
    return '$_temp0';
  }

  @override
  String backupSnapshotSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مساحة عمل لم تُلتقط',
      many: '$count مساحة عمل لم تُلتقط',
      few: '$count مساحات عمل لم تُلتقط',
      two: 'مساحتا عمل لم تُلتقطا',
      one: 'مساحة عمل واحدة لم تُلتقط',
      zero: 'لا مساحات عمل غير ملتقطة',
    );
    return '$_temp0';
  }

  @override
  String get backupServerPathLabel => 'المسار على الخادم';

  @override
  String get backupRestoreAction => 'استعادة';

  @override
  String get backupRestoreTitle => 'استعادة مساحة العمل';

  @override
  String backupRestoreBody(String name) {
    return 'هذا يستبدل كل ما في $name بالنسخة المحفوظة في هذه اللقطة. كل ما جرى في مساحة العمل تلك منذ التقاط اللقطة يُفقد، ولا يمكن التراجع عن ذلك.';
  }

  @override
  String backupRestoreDone(String name) {
    return 'استُعيدت $name من اللقطة.';
  }

  @override
  String get backupWorkspaceUnknown => 'لم تعد على هذا الخادم';

  @override
  String get backupWorkspaceDataLabel => 'بيانات مساحة العمل';

  @override
  String get backupWorkspaceDataExplainer =>
      'كل مساحة عمل هي ملف قاعدة بيانات واحد، لذا فإن تصديرها ينسخ ذلك الملف بدلاً من تفريغ الجداول جدولاً جدولاً. والاستيراد يستبدل كل ما في مساحة العمل الهدف بالملف الذي تسمّيه.';

  @override
  String get backupExportAction => 'تصدير';

  @override
  String backupExportDone(String path) {
    return 'صُدّر إلى ⁨$path⁩';
  }

  @override
  String get backupExportedFileLabel => 'الملف المصدَّر على الخادم';

  @override
  String get backupImportAction => 'استيراد';

  @override
  String backupImportTitle(String name) {
    return 'استيراد إلى $name';
  }

  @override
  String backupImportBody(String name) {
    return 'هذا يستبدل كل ما في $name بمحتويات الملف. كل ما تحويه مساحة العمل تلك الآن يُفقد، ولا يمكن التراجع عن ذلك.';
  }

  @override
  String get backupImportSourceLabel => 'ملف قاعدة بيانات مساحة العمل';

  @override
  String get backupImportSourceDescription =>
      'ملف ⁨.db⁩ يمكن للخادم قراءته. تُحل المسارات على مضيف الخادم، لا على هذا الجهاز.';

  @override
  String backupImportDone(String name) {
    return 'تم الاستيراد إلى $name.';
  }

  @override
  String backupDeleteBody(String name) {
    return 'تختفي $name من كل قائمة وبحث. يبقى ملف قاعدة بياناتها على القرص، وما تزال النسخ الاحتياطية تتضمنه، ولا شيء يسترد المساحة تلقائيًا.';
  }

  @override
  String get backupExportDescription =>
      'اكتب نسخة على الخادم، أو نزّل نسخة إلى هذا الجهاز.';

  @override
  String get backupExportOnServerAction => 'حفظ على الخادم';

  @override
  String get backupDownloadAction => 'تنزيل';

  @override
  String backupDownloadSaved(String path) {
    return 'حُفظ في ⁨$path⁩';
  }

  @override
  String get backupDownloadInBrowser => 'متصفحك يقوم بتنزيله.';

  @override
  String get backupRestoreFromDeviceLabel => 'الاستعادة من هذا الجهاز';

  @override
  String get backupRestoreFromDeviceDescription =>
      'اختر ملف قاعدة بيانات مساحة عمل هنا وسيرفعه Control Center إلى الخادم. هذا هو الخيار الذي يعمل عندما لا يكون الخادم هو هذا الجهاز.';

  @override
  String get backupUploadAction => 'اختيار ملف ورفعه';

  @override
  String get backupTransferUnavailable =>
      'يصل هذا الاتصال إلى الخادم عبر مرحّل لا ينقل الملفات. اتصل بالخادم مباشرة لتنزيل نسخة احتياطية أو رفعها.';

  @override
  String get backupTransferForbidden =>
      'رفض الخادم. تنزيل مساحة عمل يتطلب دور المشرف، واستعادتها تتطلب المالك، واللقطة الكاملة تتطلب مشغّل التثبيت.';

  @override
  String get backupTransferUnsupported =>
      'لا يملك هذا الخادم أي سطح نسخ احتياطي.';

  @override
  String get backupTransferTooLarge => 'الملف أكبر مما يقبله الخادم.';

  @override
  String get credentialGateWaitingTitle => 'في انتظار بيانات اعتماد';

  @override
  String credentialGateHarnessTitle(String provider) {
    return 'لا توجد بيانات اعتماد لـ $provider';
  }

  @override
  String get credentialGateSignedOutTitle => 'Claude Code مسجَّل الخروج';

  @override
  String get credentialGateExpiredTitle =>
      'انتهت صلاحية تسجيل دخولك إلى Claude Code';

  @override
  String get credentialGatePlanSpentTitle => 'تم بلوغ حد خطة Claude Code';

  @override
  String credentialGateWaitingAgent(String agent) {
    return '$agent في انتظار المتابعة.';
  }

  @override
  String get credentialGateWaitingRun => 'هناك تشغيل في انتظار المتابعة.';

  @override
  String get credentialGateWatching =>
      'تجري مراقبة الإصلاح — يتابع التشغيل من تلقاء نفسه.';

  @override
  String credentialGateFreesUpAt(String time) {
    return 'يتحرر في $time';
  }

  @override
  String credentialGateGivesUpAt(String time) {
    return 'يستسلم التشغيل في $time';
  }

  @override
  String get credentialGateCheckAgain => 'التحقق مجددًا';

  @override
  String get credentialGateCancelRun => 'إلغاء التشغيل';

  @override
  String get credentialGateAccountsTried => 'الحسابات المجرَّبة';

  @override
  String get credentialGateClaudeSignInHint =>
      'سجّل الدخول من الإعدادات ← المحوّلات ← Claude Code، أو شغّل أمر تسجيل الدخول في طرفية. يلتقطه التشغيل من تلقاء نفسه.';

  @override
  String get credentialGateOpenSettings => 'فتح الإعدادات';

  @override
  String get selectModel => 'اختيار النموذج';

  @override
  String get allModels => 'كل النماذج';

  @override
  String get noModelsMatchSearch => 'لا توجد نماذج مطابقة لبحثك';

  @override
  String useCustomModelId(String id) {
    return 'استخدام “$id”';
  }

  @override
  String get modelFree => 'مجاني';

  @override
  String modelOutputTokens(String tokens) {
    return '$tokens إخراج';
  }

  @override
  String modelPricePerMTokens(String input, String output) {
    return '$input إدخال / $output إخراج لكل مليون رمز';
  }

  @override
  String modelEffortLevels(String levels) {
    return 'جهد الاستدلال: $levels';
  }

  @override
  String get modelSupportsReasoning => 'يدعم جهد الاستدلال';

  @override
  String get profileDeliveryMetrics => 'مقاييس التسليم';

  @override
  String profileMetricsSample(int count) {
    return 'طلبات PR التي تم تحليلها: $count';
  }

  @override
  String get profileMergeRate => 'معدل الدمج';

  @override
  String get profileReviewCoverage => 'تغطية المراجعة';

  @override
  String get profilePrSize => 'حجم PR';

  @override
  String get profileTimeToMerge => 'الوقت حتى الدمج';

  @override
  String get profileMergeTimeTrend => 'اتجاه وقت الدمج';

  @override
  String get profileWeeklyMedian => 'الوسيط الأسبوعي، مقياس لوغاريتمي';

  @override
  String get profilePrOpeningPattern => 'يوم الأسبوع × الساعة، بالتوقيت المحلي';

  @override
  String get profileFirstReview => 'الوقت حتى المراجعة الأولى';

  @override
  String get profileMetricsTruncated =>
      'تستخدم القيم المئينية عينة محدودة من طلبات السحب المتاحة.';

  @override
  String profileLinesChanged(String count) {
    return '$count سطر';
  }

  @override
  String profileDurationMinutes(int count) {
    return '$count د';
  }

  @override
  String profileDurationHours(int count) {
    return '$count س';
  }

  @override
  String profileDurationDaysHours(int days, int hours) {
    return '$daysي $hoursس';
  }

  @override
  String profilePercentiles(String median, String p90) {
    return 'p50 $median · p90 $p90';
  }

  @override
  String profileTeamMembers(int count) {
    return 'الأعضاء: $count';
  }

  @override
  String noPrsByTeamInWorkspace(String team) {
    return 'لا توجد طلبات سحب من $team في مساحة العمل هذه';
  }

  @override
  String get profilePrStateFilterLabel => 'تصفية طلبات السحب حسب الحالة';

  @override
  String get noProfilePrsMatchSearchHint => 'جرّب عنوانًا أو رقم طلب سحب آخر';

  @override
  String get rigNetworkUnrestricted => 'الشبكة غير مقيّدة';

  @override
  String get rigNetworkAllowAllHosts => 'السماح بجميع المضيفين';

  @override
  String get rigBrowserPermissionsTitle => 'أذونات الموقع';

  @override
  String get rigBrowserPermissionsTooltip => 'أذونات الموقع والشبكة';

  @override
  String get rigBrowserPermissionEmpty => 'لم يطلب أي موقع إذناً بعد';

  @override
  String rigBrowserPermissionPrompt(String origin, String permission) {
    return '$origin يريد استخدام $permission';
  }

  @override
  String get rigBrowserPermissionBlock => 'حظر';

  @override
  String get rigBrowserPermissionCamera => 'الكاميرا';

  @override
  String get rigBrowserPermissionMicrophone => 'الميكروفون';

  @override
  String get rigBrowserPermissionNotifications => 'الإشعارات';

  @override
  String get rigBrowserPermissionGeolocation => 'الموقع';

  @override
  String get rigBrowserPermissionPersistentStorage => 'التخزين الدائم';

  @override
  String get rigBrowserPermissionClipboard => 'الحافظة';

  @override
  String get rigBrowserPermissionDisplayCapture => 'التقاط الشاشة';

  @override
  String get rigBrowserPermissionMidi => 'MIDI';

  @override
  String get rigNetworkBypassTitle => 'هل تريد السماح بكل مضيفي الشبكة؟';

  @override
  String get rigNetworkBypassBody =>
      'سيؤدي هذا إلى إعادة تشغيل البيئة المعزولة وحذف العمل غير المثبّت داخلها. سيتمكن الضيف بعدها من الوصول إلى أي مضيف على الشبكة حتى يتم إغلاقه.';

  @override
  String get rigNetworkRestartUnrestricted => 'إعادة التشغيل بلا قيود';

  @override
  String get rigNetworkUnrestrictedBody =>
      'يمكن لهذه البيئة المعزولة الوصول إلى كل مضيفي الشبكة. أغلقها وافتح بيئة جديدة لاستعادة القيود الافتراضية.';

  @override
  String get rigNetworkAlreadyUnrestrictedBody =>
      'يدير محاكي Android هذا شبكته بنفسه بالفعل، لذلك لا يمكن لـ Control Center فرض قائمة سماح لكل مضيف. لا حاجة إلى إعادة التشغيل.';

  @override
  String get rigClipboardPermissionHostToRigTitle =>
      'لصق الحافظة في هذه الحاوية؟';

  @override
  String get rigClipboardPermissionHostToRigBody =>
      'سيقرأ Control Center حافظة جهازك ويرسل محتواها إلى الحاوية. قد يحتوي محتوى الحافظة على كلمات مرور أو أسرار أخرى.';

  @override
  String get rigClipboardPermissionRigToHostTitle =>
      'نسخ الحافظة من هذه الحاوية؟';

  @override
  String get rigClipboardPermissionRigToHostBody =>
      'سيقرأ Control Center حافظة الحاوية ويستبدل حافظة جهازك بمحتواها. تعامل مع المحتوى القادم من الحاوية على أنه غير موثوق.';

  @override
  String get rigClipboardAllowTenMinutes => 'السماح لمدة 10 دقائق';

  @override
  String get rigClipboardAlwaysAllow => 'السماح دائمًا';

  @override
  String get rigClipboardSettingsTitle => 'الوصول إلى الحافظة';

  @override
  String get rigClipboardSettingsHint =>
      'اختر عمليات نقل الحافظة التي يمكن تشغيلها دون طلب إذن. تنتهي صلاحية الأذونات المؤقتة بعد 10 دقائق.';

  @override
  String get rigClipboardAlwaysPasteTitle => 'السماح دائمًا باللصق في الحاويات';

  @override
  String get rigClipboardAlwaysPasteDescription =>
      'إرسال حافظة هذا الجهاز إلى أي حاوية دون طلب إذن.';

  @override
  String get rigClipboardAlwaysCopyTitle => 'السماح دائمًا بالنسخ من الحاويات';

  @override
  String get rigClipboardAlwaysCopyDescription =>
      'وضع محتوى الحافظة من أي حاوية على هذا الجهاز دون طلب إذن.';

  @override
  String get workspaceGitHubIdentity => 'هوية GitHub';

  @override
  String get workspaceGitHubIdentityDescription =>
      'كيف تُصادق أعمال GitHub الخلفية في مساحة العمل هذه. ورّث تطبيق التثبيت، أو استخدم تطبيقًا آخر، أو رمز وصول شخصي فقط.';

  @override
  String get workspaceGitHubModeInherit => 'استخدام GitHub App لهذا التثبيت';

  @override
  String get workspaceGitHubModeApp => 'استخدام GitHub App مختلف';

  @override
  String get workspaceGitHubModePat => 'رمز وصول شخصي فقط';

  @override
  String get workspaceGitHubInheritHint =>
      'يستخدم GitHub App في الخادم → تطبيقات الموفر.';

  @override
  String get workspaceGitHubAppHint =>
      'هوية البوت والاستطلاع لمساحة العمل هذه. يسجّل الأعضاء الدخول من أنت عبر هذا التطبيق.';

  @override
  String get workspaceGitHubPatLabel => 'رمز الخلفية';

  @override
  String get workspaceGitHubPatDescription =>
      'للاستطلاع والوكلاء في مساحة العمل هذه. ليس رمز ملف عضو.';

  @override
  String get workspaceGitHubHasPat => 'رمز خلفية محفوظ.';

  @override
  String get workspaceGitHubNoPat => 'لا يوجد رمز خلفية.';

  @override
  String get profileOverlayHint =>
      'هذه الحقول أنت في مساحة العمل هذه. الحقول الفارغة ترث اسم حسابك وبريدك. تبديل المساحة يبدّل هذه الطبقة.';

  @override
  String get forgeConnectionsThisWorkspace =>
      'سجّل الدخول أو الصق رمزًا لمساحة العمل هذه.';
}
