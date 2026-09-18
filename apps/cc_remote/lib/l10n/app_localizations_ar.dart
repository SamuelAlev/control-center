// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'رجوع';

  @override
  String get cancel => 'إلغاء';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get settings => 'الإعدادات';

  @override
  String get refresh => 'تحديث';

  @override
  String get approve => 'موافقة';

  @override
  String get deny => 'رفض';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get agentQuestionHeader => 'سؤال لك';

  @override
  String get agentQuestionAnsweredLabel => 'تمت الإجابة';

  @override
  String get agentQuestionSkip => 'تخطي';

  @override
  String get agentQuestionSkippedLabel => 'تم التخطي';

  @override
  String get agentQuestionFreeformHint => 'اكتب إجابتك…';

  @override
  String get agentApprovalRequired => 'يلزم الموافقة';

  @override
  String get approveAndRemember => 'الموافقة لمدة 8 ساعات';

  @override
  String get decline => 'رفض';

  @override
  String get confirm => 'تأكيد';

  @override
  String get send => 'إرسال';

  @override
  String get close => 'إغلاق';

  @override
  String get expand => 'توسيع';

  @override
  String get zoomIn => 'تكبير';

  @override
  String get zoomOut => 'تصغير';

  @override
  String get resetZoom => 'إعادة تعيين التكبير';

  @override
  String get scanQrPrompt => 'امسح رمز QR من جهاز Mac لإقران هذا الهاتف.';

  @override
  String get scanQrHelp =>
      'افتح الكاميرا ووجّهها نحو رمز QR المعروض في Control Center على جهاز Mac. يتصل هذا الهاتف مباشرة بجهاز Mac عبر رابط خاص.';

  @override
  String get connectingToMac => 'جارٍ الاتصال بجهاز Mac…';

  @override
  String get connectingDetail => 'جارٍ إنشاء رابط آمن ومباشر.';

  @override
  String get identityChangedTitle => 'تغيّرت هوية الخادم';

  @override
  String get identityChangedBody =>
      'لم يعد هذا الخادم يطابق الهوية المحفوظة عند الإقران. قد يعني ذلك أن الخادم أُعيد تثبيته — أو أن شيئًا ما يعترض الاتصال. حفاظًا على أمانك، لن يتصل هذا الجهاز. أزل الإقران، ثم امسح رمز QR جديدًا من جهاز Mac لإعادة الإقران.';

  @override
  String get removePairing => 'إزالة الإقران';

  @override
  String get couldntConnect => 'تعذّر الاتصال';

  @override
  String get pendingPairingTitle => 'هل تريد الاتصال بهذا الخادم؟';

  @override
  String get pendingPairingBody =>
      'طلب رابطٌ من Control Center الإقران بهذا الخادم. لا تتابع إلا إذا كنت أنت من بدأ ذلك.';

  @override
  String get connect => 'اتصال';

  @override
  String get failureNotPaired => 'غير مقترن — امسح رمز QR من جهاز Mac';

  @override
  String get failureUnreachable =>
      'تعذّر الوصول إلى الخادم عبر أي مسار — تأكد من أنه يعمل، أو جرّب الشبكة نفسها';

  @override
  String get failureIdentityChanged =>
      'تغيّرت هوية الخادم — إذا أُعيد تثبيته، فأعد إقران هذا الجهاز';

  @override
  String get failureAuthRejected =>
      'رفض الخادم هذا الجهاز — أعد إقرانه من جهاز Mac';

  @override
  String get failureUnknown => 'تعذّر الاتصال — انقر لإعادة المحاولة';

  @override
  String get statusConnected => 'متصل';

  @override
  String get statusConnecting => 'جارٍ الاتصال';

  @override
  String get statusOffline => 'غير متصل';

  @override
  String get statusIdentityMismatch => 'عدم تطابق الهوية';

  @override
  String get statusNotPaired => 'غير مقترن';

  @override
  String get statusConfirmPairing => 'تأكيد الإقران';

  @override
  String get connectionFailed => 'فشل الاتصال';

  @override
  String get identityMismatchBanner =>
      'تغيّرت هوية الخادم — توقّف الاتصال. أعد إقران هذا الجهاز للمتابعة.';

  @override
  String get tabInbox => 'الوارد';

  @override
  String get tabTickets => 'التذاكر';

  @override
  String get tabChat => 'الدردشة';

  @override
  String get tabPrs => 'PRs';

  @override
  String get tabCalendar => 'التقويم';

  @override
  String get tabNews => 'الأخبار';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label، $count في الانتظار';
  }

  @override
  String get updateAvailable => 'يتوفر إصدار جديد من Control Center';

  @override
  String get appearance => 'المظهر';

  @override
  String get language => 'اللغة';

  @override
  String get device => 'الجهاز';

  @override
  String get themeSystem => 'النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get languageSystem => 'النظام';

  @override
  String get disconnectTapAgain => 'انقر مرة أخرى لفصل هذا الجهاز عن جهاز Mac';

  @override
  String get disconnectDevice => 'فصل هذا الجهاز';

  @override
  String get disconnect => 'فصل';

  @override
  String get chooseWorkspace => 'اختر مساحة العمل';

  @override
  String get workspaces => 'مساحات العمل';

  @override
  String get workspacesLoadFailed => 'تعذّر تحميل مساحات العمل';

  @override
  String get noWorkspacesYet => 'لا توجد مساحات عمل بعد';

  @override
  String selectWorkspace(String name) {
    return 'تحديد $name';
  }

  @override
  String get inboxLoadFailed => 'تعذّر تحميل الوارد';

  @override
  String get allCaughtUp => 'اطّلعت على كل شيء';

  @override
  String get inboxNoForgeAccount =>
      'لا يوجد حساب منصة Git متصل بالخادم، لذا لا يمكن نسب طلبات السحب إليك بعد.';

  @override
  String get inboxNothingWaiting => 'لا شيء معطّل ولا يوجد طلب سحب في انتظارك.';

  @override
  String get blocked => 'معطّل';

  @override
  String get sectionNeedsYourReview => 'بحاجة إلى مراجعتك';

  @override
  String get sectionReturnedToYou => 'أُعيدت إليك';

  @override
  String get sectionApprovedAndReady => 'معتمدة وجاهزة';

  @override
  String get sectionYourDrafts => 'مسوداتك';

  @override
  String get sectionWaitingForReviewers => 'في انتظار المراجعين';

  @override
  String get sectionMergingAndMerged => 'قيد الدمج ومدموجة حديثًا';

  @override
  String get sectionWaitingForAuthor => 'في انتظار المؤلف';

  @override
  String waitingAgo(String ago) {
    return 'في الانتظار منذ $ago';
  }

  @override
  String get openConversation => 'فتح المحادثة';

  @override
  String get calendarLoadFailed => 'تعذّر تحميل التقويم';

  @override
  String get nothingScheduled => 'لا شيء مجدول';

  @override
  String get calendarEmptyDescription => 'تظهر هنا الأحداث من تقاويمك المتصلة.';

  @override
  String get agenda => 'جدول الأعمال';

  @override
  String get syncCalendarsNow => 'مزامنة التقاويم الآن';

  @override
  String get event => 'حدث';

  @override
  String get eventNotFound => 'لم يُعثر على الحدث';

  @override
  String get eventNotFoundDescription =>
      'قد يكون خارج نطاق جدول الأعمال، أو أُزيل من المصدر.';

  @override
  String get joinMeeting => 'الانضمام إلى الاجتماع';

  @override
  String get join => 'انضمام';

  @override
  String attendeesCount(int count) {
    return 'الحاضرون ($count)';
  }

  @override
  String get details => 'التفاصيل';

  @override
  String get allDay => 'طوال اليوم';

  @override
  String get happeningNow => 'يحدث الآن';

  @override
  String inDuration(String duration) {
    return 'بعد $duration';
  }

  @override
  String eventTimeRange(String start, String end, String duration) {
    return '$start – $end · $duration';
  }

  @override
  String upNextSemantic(String lead, String title) {
    return '$lead: $title';
  }

  @override
  String get attendeeAccepted => 'وافق';

  @override
  String get attendeeDeclined => 'اعتذر';

  @override
  String get attendeeMaybe => 'ربما';

  @override
  String get attendeeNoReply => 'لم يرد';

  @override
  String get organizer => 'المنظّم';

  @override
  String get calendarNoAccounts =>
      'لا يوجد تقويم متصل بمساحة العمل هذه. اربط تقويمًا من تطبيق سطح المكتب — يخزّن تسجيل الدخول رمزه على الخادم.';

  @override
  String get calendarReauthNeeded =>
      'يحتاج أحد حسابات التقويم إلى إعادة الربط — وقد يكون ما تراه أدناه قديمًا. أعد ربطه من تطبيق سطح المكتب.';

  @override
  String get spacesLoadFailed => 'تعذّر تحميل المساحات';

  @override
  String get noSpaces => 'لا توجد مساحات';

  @override
  String get spacesEmptyDescription =>
      'تظهر هنا المساحات الموجودة في مساحة العمل هذه.';

  @override
  String get thread => 'سلسلة الرسائل';

  @override
  String get agentWorking => 'الوكيل يعمل';

  @override
  String get messagesLoadFailed => 'تعذّر تحميل الرسائل';

  @override
  String get noMessagesYet => 'لا توجد رسائل بعد';

  @override
  String get noMessagesDescription => 'أرسل رسالة لبدء المحادثة.';

  @override
  String get agentResponding => 'الوكيل يرد';

  @override
  String get agentFinished => 'انتهى الوكيل';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁨$names⁩ أكبر من أن تُرسل من هنا.',
      many: '⁨$names⁩ أكبر من أن تُرسل من هنا.',
      few: '⁨$names⁩ أكبر من أن تُرسل من هنا.',
      two: '⁨$names⁩ أكبر من أن يُرسلا من هنا.',
      one: '⁨$names⁩ أكبر من أن يُرسل من هنا.',
      zero: '⁨$names⁩ أكبر من أن تُرسل من هنا.',
    );
    return '$_temp0';
  }

  @override
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁨$names⁩ أكبر من أن تُرسل عبر المرحّل من هنا.',
      many: '⁨$names⁩ أكبر من أن تُرسل عبر المرحّل من هنا.',
      few: '⁨$names⁩ أكبر من أن تُرسل عبر المرحّل من هنا.',
      two: '⁨$names⁩ أكبر من أن يُرسلا عبر المرحّل من هنا.',
      one: '⁨$names⁩ أكبر من أن يُرسل عبر المرحّل من هنا.',
      zero: '⁨$names⁩ أكبر من أن تُرسل عبر المرحّل من هنا.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed => 'تعذّر رفع المرفق. حاول مرة أخرى.';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تعذّر رفع $count مرفق فاستُبعدت.',
      many: 'تعذّر رفع $count مرفقًا فاستُبعدت.',
      few: 'تعذّر رفع $count مرفقات فاستُبعدت.',
      two: 'تعذّر رفع مرفقين فاستُبعدا.',
      one: 'تعذّر رفع مرفق واحد فاستُبعد.',
      zero: 'لم يتعذّر رفع أي مرفق.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'زميل';

  @override
  String get agent => 'وكيل';

  @override
  String get attachFile => 'إرفاق ملف';

  @override
  String get messageHint => 'رسالة';

  @override
  String removeAttachment(String name) {
    return 'إزالة ⁨$name⁩';
  }

  @override
  String get articlesLoadFailed => 'تعذّر تحميل المقالات';

  @override
  String get noArticles => 'لا توجد مقالات';

  @override
  String get articlesEmptyDescription =>
      'تظهر المقالات الجديدة هنا مع تحديث الخلاصات.';

  @override
  String get unread => 'غير مقروءة';

  @override
  String get allFeeds => 'كل الخلاصات';

  @override
  String get save => 'حفظ';

  @override
  String get unsave => 'إلغاء الحفظ';

  @override
  String get readFullArticle => 'قراءة المقال كاملًا';

  @override
  String get ticketsLoadFailed => 'تعذّر تحميل التذاكر';

  @override
  String get noTickets => 'لا توجد تذاكر';

  @override
  String get ticketsEmptyDescription =>
      'تظهر هنا التذاكر الموجودة في مساحة العمل هذه.';

  @override
  String get all => 'الكل';

  @override
  String get ticket => 'تذكرة';

  @override
  String get ticketLoadFailed => 'تعذّر تحميل التذكرة';

  @override
  String assignedTo(String name) {
    return 'مُسندة إلى $name';
  }

  @override
  String get openInBrowser => 'فتح في المتصفح';

  @override
  String get status => 'الحالة';

  @override
  String get assign => 'إسناد';

  @override
  String get reassign => 'إعادة إسناد';

  @override
  String get noAgents => 'لا يوجد وكلاء';

  @override
  String get noAgentsDescription => 'أسنِد وكيلًا من مساحة العمل هذه.';

  @override
  String get statusOpen => 'مفتوحة';

  @override
  String get statusInProgress => 'قيد التنفيذ';

  @override
  String get statusBlocked => 'معطّلة';

  @override
  String get statusInReview => 'قيد المراجعة';

  @override
  String get statusDone => 'منجزة';

  @override
  String get statusBacklog => 'قائمة الانتظار';

  @override
  String get lensNeedsMe => 'بحاجة إليّ';

  @override
  String get lensMine => 'طلباتي';

  @override
  String get prsLoadFailed => 'تعذّر تحميل طلبات السحب';

  @override
  String get noOpenPullRequests => 'لا توجد طلبات سحب مفتوحة';

  @override
  String get nothingWaitingOnReview => 'لا شيء في انتظار مراجعتك';

  @override
  String get noOwnOpenPullRequests => 'ليس لديك طلبات سحب مفتوحة';

  @override
  String get nothingBlocked => 'لا شيء معطّل';

  @override
  String get prsEmptyDescription =>
      'تظهر هنا طلبات السحب عبر مستودعات مساحة العمل هذه.';

  @override
  String get refreshPullRequests => 'تحديث طلبات السحب';

  @override
  String get noForgeConnected =>
      'لا توجد منصة Git متصلة بالخادم، لذا يتعذّر جلب طلبات السحب. اربط منصة من تطبيق سطح المكتب.';

  @override
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تعذّرت قراءة $count مستودع.',
      many: 'تعذّرت قراءة $count مستودعًا.',
      few: 'تعذّرت قراءة $count مستودعات.',
      two: 'تعذّرت قراءة مستودعين.',
      one: 'تعذّرت قراءة مستودع واحد.',
      zero: 'لم تتعذّر قراءة أي مستودع.',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return 'تعذّرت قراءة: ⁨$names⁩';
  }

  @override
  String get installationSuspendedTitle => 'تم تعليق تثبيت GitHub App';

  @override
  String installationSuspendedBody(String names) {
    return 'يتم عرض آخر بيانات معروفة لـ ⁨$names⁩. استأنف التثبيت على GitHub، أو اربط رمز وصول لديه صلاحية الوصول.';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'تم تعليق تثبيت GitHub App. يتم عرض آخر بيانات معروفة لـ ⁨$names⁩. استأنف التثبيت على GitHub، أو اربط رمز وصول لديه صلاحية الوصول.';
  }

  @override
  String get draft => 'مسودة';

  @override
  String get merged => 'تم الدمج';

  @override
  String get closed => 'مغلق';

  @override
  String get open => 'مفتوح';

  @override
  String get approved => 'تمت الموافقة';

  @override
  String get changesRequested => 'طُلبت تغييرات';

  @override
  String get reviewRequired => 'المراجعة مطلوبة';

  @override
  String get checksPassing => 'الفحوصات ناجحة';

  @override
  String get checksFailing => 'الفحوصات فاشلة';

  @override
  String get checksRunning => 'الفحوصات قيد التشغيل';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title، $status';
  }

  @override
  String get pullRequest => 'طلب سحب';

  @override
  String get prLoadFailed => 'تعذّر تحميل طلب السحب هذا';

  @override
  String get openOnForge => 'فتح على منصة Git';

  @override
  String get requestChangesNeedsComment => 'أضف تعليقًا يوضح ما يلزم تغييره.';

  @override
  String get conversation => 'المحادثة';

  @override
  String get files => 'الملفات';

  @override
  String get checks => 'الفحوصات';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملف',
      many: '$count ملفًا',
      few: '$count ملفات',
      two: 'ملفان',
      one: 'ملف واحد',
      zero: 'لا ملفات',
    );
    return '$_temp0';
  }

  @override
  String commitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إيداع',
      many: '$count إيداعًا',
      few: '$count إيداعات',
      two: 'إيداعان',
      one: 'إيداع واحد',
      zero: 'لا إيداعات',
    );
    return '$_temp0';
  }

  @override
  String get conflicts => 'تعارضات';

  @override
  String get reviewers => 'المراجعون';

  @override
  String get noDescriptionNoComments => 'لا يوجد وصف ولا تعليقات بعد.';

  @override
  String get noChangedFiles => 'لا توجد ملفات متغيّرة.';

  @override
  String get noChecksReported => 'لم يُبلَّغ عن أي فحوصات للإيداع الأخير.';

  @override
  String get reviewCommentHint => 'اكتب تعليق مراجعة…';

  @override
  String get comment => 'تعليق';

  @override
  String get commentPosted => 'نُشر التعليق';

  @override
  String get request => 'طلب';

  @override
  String get squashAndMerge => 'ضغط ودمج';

  @override
  String noActionsAvailable(String status) {
    return '$status — لا توجد إجراءات متاحة.';
  }

  @override
  String get reviewApproved => 'وافق';

  @override
  String get reviewRequestedChanges => 'طلب تغييرات';

  @override
  String get reviewCommented => 'راجع';

  @override
  String get reviewPending => 'قيد الانتظار';

  @override
  String get unknownAuthor => 'غير معروف';

  @override
  String hideDiffFor(String file) {
    return 'إخفاء فروقات ⁨$file⁩';
  }

  @override
  String showDiffFor(String file) {
    return 'عرض فروقات ⁨$file⁩';
  }

  @override
  String get checkRunning => 'قيد التشغيل';

  @override
  String get checkPassed => 'نجح';

  @override
  String get checkFailed => 'فشل';

  @override
  String get checkCancelled => 'أُلغي';

  @override
  String get checkSkipped => 'تم تخطيه';

  @override
  String labelWithDuration(String label, String duration) {
    return '$label · $duration';
  }

  @override
  String checkSemanticLabel(String name, String state) {
    return '⁨$name⁩، $state';
  }

  @override
  String get noTextDiff =>
      'لا يوجد فرق نصي لهذا الملف — فهو إما ثنائي أو أكبر من أن تعيده منصة Git.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'عرض $count سطر متبقٍ',
      many: 'عرض $count سطرًا متبقيًا',
      few: 'عرض $count أسطر متبقية',
      two: 'عرض السطرين المتبقيين',
      one: 'عرض السطر المتبقي',
      zero: 'عرض الأسطر المتبقية',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سطر غير متغيّر',
      many: '$count سطرًا غير متغيّر',
      few: '$count أسطر غير متغيّرة',
      two: 'سطران غير متغيّرين',
      one: 'سطر واحد غير متغيّر',
      zero: 'لا أسطر غير متغيّرة',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'الانتقال إلى الأحدث';

  @override
  String get streaming => 'جارٍ البث';

  @override
  String get working => 'جارٍ العمل';

  @override
  String get input => 'الإدخال';

  @override
  String get output => 'الإخراج';

  @override
  String get now => 'الآن';

  @override
  String agoMinutes(int count) {
    return '$count د';
  }

  @override
  String agoHours(int count) {
    return '$count س';
  }

  @override
  String agoDays(int count) {
    return '$count ي';
  }

  @override
  String get today => 'اليوم';

  @override
  String get tomorrow => 'غدًا';

  @override
  String get yesterday => 'أمس';

  @override
  String durationMinutes(int count) {
    return '$count د';
  }

  @override
  String durationHours(int count) {
    return '$count س';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours س $minutes د';
  }
}
