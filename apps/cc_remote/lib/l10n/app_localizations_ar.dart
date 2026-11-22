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
  String get copyCommand => 'نسخ الأمر';

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
  String get scanQrPrompt => 'امسح رمز QR من Control Center لإقران هذا الهاتف.';

  @override
  String get scanQrHelp =>
      'افتح الكاميرا ووجّهها نحو رمز QR المعروض في Control Center. يتصل هذا الهاتف مباشرة عبر رابط خاص.';

  @override
  String get connectingToMac => 'جارٍ الاتصال بـ Control Center…';

  @override
  String get connectingDetail => 'جارٍ إنشاء رابط آمن ومباشر.';

  @override
  String get identityChangedTitle => 'تغيّرت هوية الخادم';

  @override
  String get identityChangedBody =>
      'لم يعد هذا الخادم يطابق الهوية المحفوظة عند الإقران. قد يعني ذلك أن الخادم أُعيد تثبيته — أو أن شيئًا ما يعترض الاتصال. حفاظًا على أمانك، لن يتصل هذا الجهاز. أزل الإقران، ثم امسح رمز QR جديدًا من Control Center لإعادة الإقران.';

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
  String get failureNotPaired => 'غير مقترن — امسح رمز QR من Control Center';

  @override
  String get failureUnreachable =>
      'تعذّر الوصول إلى الخادم عبر أي مسار — تأكد من أنه يعمل، أو جرّب الشبكة نفسها';

  @override
  String get failureIdentityChanged =>
      'تغيّرت هوية الخادم — إذا أُعيد تثبيته، فأعد إقران هذا الجهاز';

  @override
  String get failureAuthRejected =>
      'رفض الخادم هذا الجهاز — أعد إقرانه من Control Center';

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
  String get disconnectTapAgain =>
      'انقر مرة أخرى لفصل هذا الجهاز عن Control Center';

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
  String get newSpaceFolder => 'مجلد جديد';

  @override
  String get folderName => 'اسم المجلد';

  @override
  String get renameSpaceFolder => 'إعادة تسمية المجلد';

  @override
  String get deleteSpaceFolder => 'حذف المجلد';

  @override
  String get moveSpaceToFolder => 'نقل المساحة إلى مجلد';

  @override
  String get removeSpaceFromFolder => 'إزالة المساحة من المجلد';

  @override
  String get spaceFolderActions => 'إجراءات المجلد';

  @override
  String get deleteFolderWithSpacesWarning =>
      'يؤدي حذف المساحات نهائيًا إلى إزالة رسائلها ومجلدات العمل الخاصة بها للجميع. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get deleteSpacesInFolder =>
      'حذف المساحات الموجودة في هذا المجلد نهائيًا';

  @override
  String get deleteFolderAndSpaces => 'حذف المجلد والمساحات';

  @override
  String get keepSpacesInFolder => 'وإلا فستبقى المساحات خارج أي مجلد.';

  @override
  String get create => 'إنشاء';

  @override
  String get otherSpaces => 'مساحات أخرى';

  @override
  String get folderUpdateFailed => 'تعذّر تحديث المجلدات';

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
  String get teammate => 'زميل';

  @override
  String get systemSender => 'النظام';

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

  @override
  String get mobileConversations => 'المحادثات';

  @override
  String get mobileNewConversation => 'محادثة جديدة';

  @override
  String get mobileConversationName => 'اسم المحادثة';

  @override
  String get mobileRename => 'إعادة تسمية';

  @override
  String get mobileManageSpace => 'إدارة المساحة';

  @override
  String get mobileArchived => 'مؤرشف';

  @override
  String get mobileSearchMessages => 'البحث في جميع الرسائل في هذه المساحة';

  @override
  String get mobileSearch => 'بحث';

  @override
  String get mobileNoResults => 'لا توجد نتائج';

  @override
  String get mobileReopen => 'إعادة فتح';

  @override
  String get mobileArchive => 'أرشفة';

  @override
  String get mobileProgress => 'التقدم والسياق';

  @override
  String get mobileReadFailed => 'تعذر وضع علامة «مقروءة» على هذه المحادثة';

  @override
  String get mobileSendFailed => 'لم تُرسل الرسالة. مسودتك لا تزال محفوظة هنا.';

  @override
  String get sentAttachmentUnavailable => 'المرفق غير متاح';

  @override
  String get sentAttachmentLoadFailed => 'تعذّر تحميل المرفق';

  @override
  String get mobileActionFailed => 'فشل الإجراء';

  @override
  String get mobileRemove => 'إزالة';

  @override
  String get mobileLinkedMessage => 'الرسالة المرتبطة';

  @override
  String get mobileOlderMessages => 'رسائل أقدم';

  @override
  String get mobileMessageActions => 'إجراءات الرسالة';

  @override
  String get mobileOpenThread => 'فتح سلسلة النقاش';

  @override
  String get mobileCopyLink => 'نسخ الرابط';

  @override
  String get mobileStopRun => 'إيقاف التشغيل';

  @override
  String get mobileStopRunConfirm =>
      'هل تريد إيقاف تشغيل هذا الوكيل؟ سيُحتفظ بالعمل المنجز.';

  @override
  String get mobileControlUnsupported =>
      'انتهى هذا التشغيل أو لا يدعم هذا التحكم.';

  @override
  String get mobilePauseRequested =>
      'طُلب الإيقاف المؤقت عند انتهاء الجولة التالية';

  @override
  String get mobileResumed => 'استؤنف التشغيل';

  @override
  String get mobileStopRequested => 'طُلب الإيقاف';

  @override
  String get mobileQueuedMessages => 'الرسائل في قائمة الانتظار';

  @override
  String get mobilePauseRun => 'الإيقاف مؤقتًا عند الجولة التالية';

  @override
  String get mobileResumeRun => 'استئناف';

  @override
  String get mobileEditQueued => 'تحرير الرسالة في قائمة الانتظار';

  @override
  String get mobileSteerNow => 'توجيه فوري';

  @override
  String get mobileMoveUp => 'نقل لأعلى';

  @override
  String get mobileMoveDown => 'نقل لأسفل';

  @override
  String get mobileQueueChanged =>
      'تغيرت قائمة الانتظار، أو لا يقبل هذا التشغيل التوجيه المباشر. حدّث الصفحة وحاول مجددًا.';

  @override
  String get mobileActivity => 'النشاط';

  @override
  String get mobilePermissions => 'الأذونات وسجل التدقيق';

  @override
  String get mobilePlans => 'الخطط';

  @override
  String get mobileGoals => 'الأهداف الخاضعة للإشراف';

  @override
  String get mobileCredentials => 'الاتصالات وبيانات الاعتماد';

  @override
  String get mobileWorkspaceUnavailable =>
      'هذه المساحة غير متاحة أو لم يعد لديك حق الوصول إليها.';

  @override
  String get mobilePrReviewThreads => 'سلاسل المراجعة';

  @override
  String get mobilePrThreadsLoadFailed => 'تعذر تحميل سلاسل المراجعة';

  @override
  String get mobilePrNoReviewThreads => 'لا توجد سلاسل مراجعة ضمنية بعد';

  @override
  String get mobilePrCommentPermissionDenied =>
      'ليس لديك إذن بالتعليق على هذا المستودع.';

  @override
  String get mobilePrPermissionChecking => 'جارٍ التحقق من أذونات التعليق…';

  @override
  String get mobilePrPermissionLoadFailed =>
      'تعذر التحقق من أذونات التعليق. أعد المحاولة للتعليق.';

  @override
  String mobilePrThreadLine(String side, String line) {
    return '$side، السطر $line';
  }

  @override
  String get mobilePrOriginalSide => 'الأصلي';

  @override
  String get mobilePrSelectCommentLine => 'اختر سطرًا للتعليق عليه';

  @override
  String get mobilePrUpdatedSide => 'آخر تحديث';

  @override
  String get mobilePrThreadResolved => 'تم الحل';

  @override
  String get mobilePrReplyHint => 'اكتب ردًا…';

  @override
  String get mobilePrCommentRequired => 'اكتب تعليقًا قبل النشر.';

  @override
  String get mobilePrReply => 'رد';

  @override
  String get mobilePrReopenThread => 'إعادة فتح النقاش';

  @override
  String get mobilePrResolveThread => 'حل النقاش';

  @override
  String get mobilePrResolvePermissionDenied =>
      'لا يستطيع حل هذه السلسلة إلا منشئ طلب السحب أو من يملك إذن الكتابة.';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return 'التعليق على $side، السطر $line';
  }

  @override
  String get mobilePrInlineCommentHint => 'اكتب تعليقًا ضمنيًا…';

  @override
  String get mobilePrPostInlineComment => 'نشر التعليق';

  @override
  String get mobilePrCommentUnavailable =>
      'التعليقات الضمنية غير متاحة لطلب السحب هذا.';

  @override
  String get mobilePrPatchUnavailable =>
      'لم توفر خدمة الاستضافة رقعة نصية لهذا الملف.';

  @override
  String get mobilePrNoPatchForFile => 'رقعة هذا الملف غير متاحة.';

  @override
  String get mobileTicketNew => 'تذكرة جديدة';

  @override
  String get mobileTicketCreate => 'إنشاء تذكرة';

  @override
  String get mobileTicketEdit => 'تحرير التذكرة';

  @override
  String get mobileTicketTitle => 'العنوان';

  @override
  String get mobileTicketTitleRequired => 'أدخل عنوانًا لحفظ هذه التذكرة.';

  @override
  String get mobileTicketDescription => 'الوصف';

  @override
  String get mobileTicketMarkdownHint => 'أضف التفاصيل بتنسيق Markdown';

  @override
  String get mobileTicketPriority => 'الأولوية';

  @override
  String get mobileTicketPriorityNone => 'بلا أولوية';

  @override
  String get mobileTicketPriorityUrgent => 'عاجلة';

  @override
  String get mobileTicketPriorityHigh => 'مرتفع';

  @override
  String get mobileTicketPriorityMedium => 'متوسط';

  @override
  String get mobileTicketPriorityLow => 'منخفض';

  @override
  String get mobileTicketLabels => 'التسميات';

  @override
  String get mobileTicketLabelsHint => 'تسمية واحدة لكل سطر';

  @override
  String get mobileTicketLabelsHelp => 'أدخل كل تسمية في سطر منفصل.';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return 'مُسجّلة في $provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => 'غير مُسنَدة';

  @override
  String get mobileTicketAssignedFilter => 'المُسنَدة';

  @override
  String get mobileTicketAgentsLoadFailed => 'تعذر تحميل الوكلاء';

  @override
  String get mobileTicketSearch => 'البحث في التذاكر';

  @override
  String get mobileTicketSearchHint =>
      'العنوان أو المعرّف أو الوصف أو التسمية أو المسؤول';

  @override
  String get mobileTicketClearSearch => 'مسح البحث في التذاكر';

  @override
  String get mobileTicketNoMatches => 'لا توجد تذاكر مطابقة';

  @override
  String get mobileTicketAdjustFilters =>
      'جرّب بحثًا آخر أو غيّر عوامل التصفية.';

  @override
  String get mobileTicketClearFilters => 'مسح عوامل التصفية';

  @override
  String get mobileTicketNotFound => 'التذكرة غير موجودة';

  @override
  String get mobileTicketNotFoundDescription =>
      'ربما حُذفت هذه التذكرة أو نُقلت خارج مساحة العمل هذه.';

  @override
  String get mobileTicketWorkspaceChanged =>
      'تغيرت مساحة العمل. عُد إلى مساحة العمل الحالية قبل الحفظ.';

  @override
  String get mobileTicketOpenLinkedSpace => 'فتح المساحة المرتبطة';

  @override
  String get mobileTicketReadOnly =>
      'يلزم دور عضو في مساحة العمل لتعديل التذاكر.';

  @override
  String get permissionTitle => 'الأذونات';

  @override
  String get permissionWorkspaceFailed => 'تعذر تحميل مساحة العمل';

  @override
  String get permissionNoWorkspace => 'اختر مساحة عمل لفحص الأذونات.';

  @override
  String get permissionLoading => 'جارٍ تحميل الأذونات…';

  @override
  String get permissionScopeDescription =>
      'افحص كيفية اتخاذ القرار لكل إجراء ضمن هذا النطاق. يمكن للوكلاء والمساحات وراثة قواعد مساحة العمل.';

  @override
  String get permissionScope => 'نطاق السياسة';

  @override
  String get permissionWorkspaceScope => 'مساحة العمل';

  @override
  String get permissionAgentScope => 'الوكيل';

  @override
  String get permissionSpaceScope => 'المساحة';

  @override
  String get permissionAgentContext => 'الوكيل الذي يعمل في هذه المساحة';

  @override
  String get permissionNoAgentContext => 'لم يُختر وكيل';

  @override
  String get permissionTargetsFailed => 'تعذر تحميل عناصر النطاق';

  @override
  String get permissionNoTargets => 'لا توجد عناصر متاحة في هذا النطاق.';

  @override
  String get permissionRoleFailed => 'تعذر تأكيد دورك في مساحة العمل';

  @override
  String get permissionMemberRequired =>
      'يلزم دور عضو في مساحة العمل لعرض قواعد السياسة.';

  @override
  String get permissionRulesFailed => 'تعذر تحميل قواعد السياسة';

  @override
  String get permissionAuditAdminOnly =>
      'سجل التفويض متاح لمسؤولي مساحة العمل فقط.';

  @override
  String get permissionAllow => 'السماح';

  @override
  String get permissionAsk => 'السؤال أولًا';

  @override
  String get permissionDeny => 'الرفض';

  @override
  String get permissionFileDelete => 'حذف الملفات';

  @override
  String get permissionFileWriteOutsideWorktree => 'الكتابة خارج شجرة العمل';

  @override
  String get permissionGitCommit => 'تثبيت التغييرات';

  @override
  String get permissionGitPush => 'دفع التغييرات المثبتة';

  @override
  String get permissionPrCreate => 'إنشاء طلبات سحب';

  @override
  String get permissionPrPublish => 'تحديث طلبات سحب أو دمجها';

  @override
  String get permissionVendorSyncWrite => 'الكتابة أثناء مزامنة المورّد';

  @override
  String get permissionNetworkEgress => 'الوصول إلى الشبكة';

  @override
  String get permissionSecretAccess => 'الوصول إلى الأسرار';

  @override
  String get permissionPackageInstall => 'تثبيت الحزم';

  @override
  String get permissionProcessSpawn => 'تشغيل العمليات';

  @override
  String get permissionWorkspaceMutation => 'تغيير مساحة العمل';

  @override
  String get permissionEnclosureControl => 'التحكم في الحاوية';

  @override
  String get permissionChangeFailed => 'تعذر تغيير القاعدة';

  @override
  String get permissionEffectiveDescription =>
      'سارية في هذا النطاق دون وسائط للإجراء. تنطبق الأذونات المشروطة أدناه على الطلبات المطابقة فقط؛ ويعود القرار النهائي إلى الخادم.';

  @override
  String get permissionSpaceAgentNote =>
      'لم يُختر وكيل. لن تظهر القواعد الخاصة بالوكيل حتى تختار واحدًا أعلاه.';

  @override
  String get permissionScopedGrants => 'القواعد في هذا النطاق';

  @override
  String get permissionModePreset => 'الإعداد المسبق للوضع';

  @override
  String get permissionBuiltInDefault => 'الافتراضي المضمّن';

  @override
  String get permissionRemembered => 'موافقة سارية';

  @override
  String get permissionSource => 'المصدر';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · محددة هنا';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · موروثة';
  }

  @override
  String permissionExpiresAt(String date) {
    return 'تنتهي الصلاحية في $date';
  }

  @override
  String get permissionSetHere => 'تحديد قاعدة هنا';

  @override
  String get permissionConfirmRevoke => 'تأكيد الإلغاء';

  @override
  String get permissionRevokeRule => 'إلغاء القاعدة';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'بادئة الأمر: $prefix';
  }

  @override
  String get permissionNoExpiry => 'بلا تاريخ انتهاء';

  @override
  String get permissionExpired => 'منتهية الصلاحية';

  @override
  String get permissionExplicitRule => 'قاعدة صريحة';

  @override
  String get permissionEnforcementAdvisory =>
      'استشاري: تُسجّل قواعد طلب الموافقة دون عرض مطالبة';

  @override
  String get permissionEnforcementSoft => 'تطبيق مرن: يتطلب التجاوز تفويضًا';

  @override
  String get permissionEnforcementHard => 'تطبيق صارم: لا يمكن التجاوز';

  @override
  String permissionPaths(String paths) {
    return 'المسارات: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'مراجع Git: $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return 'المضيفون: $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return 'الأوامر: $commands';
  }

  @override
  String permissionTools(String tools) {
    return 'الأدوات: $tools';
  }

  @override
  String get permissionNotInEffect => 'غير سارية أثناء رفض هذا الإجراء';

  @override
  String permissionMaxCount(String count) {
    return 'العدد الأقصى: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return 'الحد الأقصى بالسنتات: $cents';
  }

  @override
  String get permissionAuditHeading => 'سجل التفويض';

  @override
  String get permissionAuditDescription =>
      'القرارات الأخيرة المسجلة على الخادم. يمكن للمسؤولين فقط الاطلاع على السجل أو التحقق من سلسلة التجزئة.';

  @override
  String permissionOnBehalfOf(String user) {
    return 'نيابةً عن $user';
  }

  @override
  String get permissionPrompted => 'طُلبت موافقة بشرية';

  @override
  String get permissionVerifyChain => 'التحقق من سلسلة التدقيق';

  @override
  String get permissionVerifyFailed => 'تعذر التحقق من سلسلة التدقيق';

  @override
  String permissionChainIntact(String count) {
    return 'السلسلة سليمة · تم فحص $count إدخالات';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'انقطعت السلسلة عند الإدخال $sequence: $reason';
  }

  @override
  String get permissionAuditEmpty => 'لم تُسجّل قرارات تفويض بعد.';

  @override
  String get permissionAuditFailed => 'تعذر تحميل سجل التفويض';

  @override
  String get mobilePlansLoadFailed => 'تعذر تحميل الخطط';

  @override
  String get mobilePlansEmpty => 'لا توجد خطط بعد';

  @override
  String get mobilePlansEmptyDescription =>
      'ستظهر هنا الخطط التي يقدمها الوكلاء لمراجعتها.';

  @override
  String get mobilePlanTitle => 'تخطيط';

  @override
  String get mobilePlanMissing => 'لم تعد هذه الخطة متاحة في مساحة العمل هذه.';

  @override
  String mobilePlanStepCount(int count) {
    return '$count خطوات';
  }

  @override
  String get mobilePlanDraft => 'مسودة';

  @override
  String get mobilePlanProposed => 'بانتظار المراجعة';

  @override
  String get mobilePlanApproved => 'معتمد';

  @override
  String get mobilePlanRejected => 'مرفوض';

  @override
  String get mobilePlanSuperseded => 'مستبدَل';

  @override
  String get mobilePlanExecuting => 'قيد التنفيذ';

  @override
  String get mobilePlanSynthesizing => 'قيد التجميع';

  @override
  String get mobilePlanCompleted => 'مكتمل';

  @override
  String get mobilePlanFailed => 'فشل';

  @override
  String get mobilePlanCancelled => 'أُلغي';

  @override
  String mobilePlanRevision(String revision) {
    return 'النسخة $revision';
  }

  @override
  String get mobilePlanSteps => 'الخطوات';

  @override
  String get mobilePlanNoSteps => 'لم تُقدّم خطوات لهذه الخطة.';

  @override
  String get mobilePlanAssumptions => 'إيضاحات';

  @override
  String mobilePlanDependsOn(String keys) {
    return 'يعتمد على $keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return 'التكلفة المقدّرة حتى $cost';
  }

  @override
  String get mobilePlanSelect => 'تحديد';

  @override
  String get mobilePlanSelected => 'محددة';

  @override
  String get mobilePlanEstimate => 'تقدير التكلفة';

  @override
  String get mobilePlanEstimateRequired =>
      'قدّر تكلفة الخطة قبل الموافقة على تنفيذها.';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return 'التكلفة المقدّرة: $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => 'غير متاح';

  @override
  String get mobilePlanNoHardCap => 'بلا سقف ثابت';

  @override
  String get mobilePlanExceedsBudget =>
      'يتجاوز التقدير الميزانية المحددة. راجعه قبل الموافقة.';

  @override
  String get mobilePlanPartialEstimate =>
      'يغطي هذا التقدير الخطة كاملة؛ وقد تكون تكلفة الخطوات المحددة أقل.';

  @override
  String get mobilePlanConfirmAll => 'هل تريد بدء الخطة كاملة؟';

  @override
  String get mobilePlanConfirmSelected => 'هل تريد بدء الخطوات المحددة؟';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return 'تبدأ الموافقة التنفيذ وقد تترتب عليها رسوم. الحد الأعلى للتكلفة المقدّرة: $cost. سقف الميزانية: $cap.';
  }

  @override
  String get mobilePlanApproveAll => 'الموافقة على الكل والتشغيل';

  @override
  String get mobilePlanApproveSelected => 'الموافقة على المحدد والتشغيل';

  @override
  String get mobilePlanWiden => 'الموافقة على خطوات إضافية';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return 'هل تريد إتاحة $count خطوات إضافية للتنفيذ؟ قد تترتب عليها رسوم. سقف تكلفة التنفيذ الحالي: $cap.';
  }

  @override
  String get mobilePlanChanged =>
      'تغيرت الخطة أثناء المراجعة. افتح أحدث نسخة وقدّر تكلفتها مجددًا.';

  @override
  String get mobilePlanReject => 'رفض الخطة';

  @override
  String get mobilePlanRejectConfirm => 'هل تريد رفض هذه الخطة؟ لن تُنفّذ.';

  @override
  String get mobilePlanStop => 'إيقاف التنفيذ';

  @override
  String get mobilePlanStopConfirm =>
      'هل تريد إيقاف تنفيذ هذه الخطة؟ لن يُلغى العمل المنجز.';

  @override
  String mobilePlanRunId(String runId) {
    return 'تشغيل التنفيذ: $runId';
  }

  @override
  String get mobilePlanExecutionPending =>
      'قُبلت الموافقة. بانتظار سجل التنفيذ…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return 'اكتملت $completed من أصل $total خطوات تنفيذ';
  }

  @override
  String get mobilePlanOpenConversation => 'فتح المحادثة';

  @override
  String get mobileGoalsTitle => 'الأهداف الخاضعة للإشراف';

  @override
  String get mobileGoalsLoadFailed => 'تعذر تحميل الأهداف الخاضعة للإشراف';

  @override
  String get mobileGoalsEmpty => 'لا توجد أهداف خاضعة للإشراف بعد';

  @override
  String get mobileGoalsEmptyDescription =>
      'ابدأ هدفًا في مساحة، أو أرسل /goal في محادثة.';

  @override
  String get mobileGoalMissing => 'لم يعد هذا الهدف متاحًا في مساحة العمل هذه.';

  @override
  String get mobileGoalActive => 'نشط';

  @override
  String get mobileGoalPaused => 'متوقف مؤقتًا';

  @override
  String get mobileGoalCompleted => 'مكتمل';

  @override
  String get mobileGoalFailed => 'فشل';

  @override
  String get mobileGoalCancelled => 'أُلغي';

  @override
  String get mobileGoalBudgetExhausted => 'بلغت الميزانية حدها';

  @override
  String mobileGoalFailures(String count) {
    return 'عمليات التشغيل الفاشلة المتتالية: $count';
  }

  @override
  String get mobileGoalFailedDescription =>
      'توقف المشرف بعد تكرار فشل التشغيل. راجع المحادثة للاطلاع على التفاصيل.';

  @override
  String get mobileGoalPause => 'إيقاف الهدف مؤقتًا';

  @override
  String get mobileGoalResume => 'استئناف الهدف';

  @override
  String get mobileGoalStop => 'إلغاء الهدف';

  @override
  String get mobileGoalStopConfirm =>
      'هل تريد إلغاء هذا الهدف الخاضع للإشراف نهائيًا؟ لا يمكن استئنافه.';

  @override
  String get mobileGoalRaiseBudget => 'رفع الميزانية والاستئناف';

  @override
  String mobileGoalRaiseTo(String amount) {
    return 'رفع الميزانية إلى $amount والاستئناف';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return 'هل تريد رفع سقف تكلفة هذا الهدف من $oldCap إلى $newCap واستئناف الإنفاق؟';
  }

  @override
  String get mobileGoalOpenConversation => 'فتح محادثة الهدف';

  @override
  String get mobileGoalCreate => 'بدء هدف خاضع للإشراف';

  @override
  String get mobileGoalChooseSpace => 'التشغيل في المساحة';

  @override
  String get mobileGoalNoSpaces => 'أنشئ مساحة قبل بدء هدف.';

  @override
  String get mobileGoalChooseAgent => 'التشغيل بواسطة الوكيل';

  @override
  String get mobileGoalNoAgents => 'أضف وكيلًا نشطًا قبل بدء هدف.';

  @override
  String mobileGoalSelectedAgent(String name) {
    return 'تم اختيار $name';
  }

  @override
  String get mobileGoalObjectiveHint =>
      'ما النتيجة التي تريد أن يسعى إليها الوكيل؟';

  @override
  String get mobileGoalBudgetUsd => 'سقف التكلفة (بالدولار الأمريكي)';

  @override
  String get mobileGoalCreateInvalid =>
      'اختر مساحة ووكيلًا، وأدخل هدفًا، وحدد سقف تكلفة موجبًا بالدولار الأمريكي.';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return 'هل تريد بدء هدف خاضع للإشراف بسقف تكلفة $cap؟ قد يبدأ الوكيل فورًا.';
  }

  @override
  String get mobileGoalUnavailable =>
      'الاتصال بالخادم غير جاهز. أعد المحاولة بعد استعادة الاتصال.';

  @override
  String get mobileGoalConversationMissing =>
      'لم تعد المحادثة المحددة متاحة في مساحة العمل هذه.';

  @override
  String get mobileGoalCreateSent =>
      'بدأ الهدف. ستظهر حالة المشرف في هذه القائمة.';

  @override
  String get mobileGoalStartRefused =>
      'لم يبدأ تشغيل الهدف. راجع المحادثة لمعرفة سبب المشرف.';

  @override
  String mobileGoalSelectedSpace(String name) {
    return 'تم اختيار $name';
  }

  @override
  String get requestUnavailable =>
      'لم يعد هذا الطلب متاحًا في مساحة العمل النشطة.';

  @override
  String get requestAlreadyResolved => 'عولج هذا الطلب بالفعل.';

  @override
  String get inboxCredentialsBlocked => 'بيانات اعتماد تعيق التشغيل';

  @override
  String get inboxSyncFailures => 'عمليات مزامنة المورّد الفاشلة';

  @override
  String get inboxConfigureCredentials => 'إعداد بيانات الاعتماد';

  @override
  String get openTicket => 'فتح التذكرة';

  @override
  String get activityTitle => 'النشاط';

  @override
  String get activityClearAll => 'مسح النشاط';

  @override
  String get activityClearConfirm =>
      'يخفي هذا كل النشاط المسجل لك حتى الآن على جميع الأجهزة. سيظل النشاط الجديد ظاهرًا.';

  @override
  String get activityMarkAllRead => 'وضع علامة «مقروءة» على الكل';

  @override
  String get activityMarkAllConfirm =>
      'هل تريد وضع علامة «مقروءة» على جميع عناصر النشاط في مساحة العمل هذه على كل أجهزتك؟';

  @override
  String get activityMarkRead => 'وضع علامة «مقروءة»';

  @override
  String get activityMarkUnread => 'وضع علامة «غير مقروءة»';

  @override
  String get activityDismiss => 'تجاهل';

  @override
  String get activityResolved => 'تم الحل';

  @override
  String get activityOpen => 'مفتوح';

  @override
  String get activityEmpty => 'لا يوجد نشاط بعد';

  @override
  String get activityLoadFailed => 'تعذر تحميل النشاط';

  @override
  String get activityAgentWaiting => 'الوكيل بحاجة إلى توجيه';

  @override
  String get activityAgentBlocked => 'إجراء الوكيل محظور';

  @override
  String get activityMessage => 'رسالة جديدة';

  @override
  String get activityPullRequest => 'تحديث طلب السحب';

  @override
  String get activityRig => 'تحديث الحاوية';

  @override
  String get activityEvent => 'تحديث';

  @override
  String get activityPrReady => 'طلب السحب جاهز للدمج';

  @override
  String get activityPrBlocked => 'دمج طلب السحب محظور';

  @override
  String get activityPrApproved => 'تمت الموافقة على طلب السحب';

  @override
  String get activityPrChanges => 'طُلبت تغييرات';

  @override
  String get activityPrChecksFailed => 'فشلت فحوص طلب السحب';

  @override
  String get activityPrChecksRecovered => 'عادت فحوص طلب السحب للعمل';

  @override
  String get activityPrComment => 'تعليق على طلب السحب';

  @override
  String get activityPrPublished => 'نُشر طلب السحب';

  @override
  String get activityPrMerged => 'تم دمج طلب السحب';

  @override
  String get activityPrMentioned => 'ذُكرت في طلب سحب';

  @override
  String get activityPrReviewRequested => 'تم طلب مراجعة';

  @override
  String get activityPrReviewStale => 'تحتاج المراجعة إلى تحديث';

  @override
  String get activityTicketAssigned => 'إسناد تذكرة';

  @override
  String get activityTicketChanged => 'تغيرت حالة التذكرة';

  @override
  String get activityMeetingSoon => 'اجتماع يبدأ قريبًا';

  @override
  String get activityCalendarExpired => 'انتهت صلاحية اتصال التقويم';

  @override
  String get activityRigControl => 'تغير التحكم في الحاوية';

  @override
  String get activityRigClosed => 'توقفت الحاوية';

  @override
  String get mobileSpacesSearch => 'البحث في المساحات';

  @override
  String get mobileSpacesArchived => 'مؤرشف';

  @override
  String get mobileSpacesActive => 'نشط';

  @override
  String get mobileSpacesNew => 'مساحة جديدة';

  @override
  String get mobileSpacesManage => 'إدارة المساحة';

  @override
  String get mobileSpacesName => 'اسم المساحة';

  @override
  String get mobileSpacesAgents => 'الوكلاء';

  @override
  String get mobileSpacesMembers => 'الأشخاص';

  @override
  String get mobileSpacesRepos => 'المستودعات';

  @override
  String get mobileSpacesAllRepos => 'جميع المستودعات المرتبطة';

  @override
  String get mobileSpacesNoRepos => 'لا توجد مستودعات';

  @override
  String get mobileSpacesBaseBranch => 'الفرع الأساسي (اختياري)';

  @override
  String get mobileSpacesDefaultBranch => 'الفرع الافتراضي';

  @override
  String get mobileSpacesMode => 'الوضع';

  @override
  String get mobileSpacesModeChat => 'دردشة';

  @override
  String get mobileSpacesModeReview => 'مراجعة (للقراءة فقط)';

  @override
  String get mobileSpacesModePlan => 'خطة (للقراءة فقط)';

  @override
  String get mobileSpacesModeOrchestrate => 'تنسيق';

  @override
  String get mobileSpacesAutonomy => 'تجاوز الاستقلالية';

  @override
  String get mobileSpacesAutonomyInherited => 'موروث';

  @override
  String get mobileSpacesAutonomyPropose => 'اقتراح فقط';

  @override
  String get mobileSpacesAutonomyApproval => 'التصرف بموافقة';

  @override
  String get mobileSpacesAutonomyFreely => 'التصرف بحرية';

  @override
  String get mobileSpacesAutonomyNotice =>
      'لا يمكن للتجاوز تخطي مطالبات سياسة الإجراءات أو حالات الرفض. لا يستطيع تغييره سوى مسؤولي مساحة العمل.';

  @override
  String get mobileSpacesArchive => 'أرشفة المساحة';

  @override
  String get mobileSpacesReopen => 'إعادة فتح المساحة';

  @override
  String get mobileSpacesSave => 'حفظ التغييرات';

  @override
  String get mobileSpacesCreate => 'إنشاء مساحة';

  @override
  String get mobileSpacesOperationFailed => 'تعذر تحديث المساحة';

  @override
  String get mobileSpacesMissing => 'المساحة غير موجودة في مساحة العمل هذه';

  @override
  String get mobileSpacesEmptyName => 'أدخل اسم المساحة';

  @override
  String get mobileSpacesNoMatches => 'لا توجد مساحات مطابقة';

  @override
  String get mobileSpacesUnread => 'رد غير مقروء من الوكيل';

  @override
  String get mobileSpacesNeedsInput => 'يلزم تدخلك';

  @override
  String get mobileSpacesRunning => 'الوكيل قيد التشغيل';

  @override
  String get mobileSpacesNoAgents => 'لا يوجد وكلاء في مساحة العمل هذه';

  @override
  String get mobileSpacesNoMembers => 'لا يوجد أعضاء آخرون في مساحة العمل';

  @override
  String get mobileSpacesRepoError => 'تعذر تحميل المستودعات';

  @override
  String get mobileSpacesRetry => 'إعادة المحاولة';

  @override
  String get mobileSpacesBranchUnavailable =>
      'اختر فرعًا أساسيًا أو اكتبه عند إنشاء المساحة؛ لا يمكن تغيير الفروع الأساسية للمساحات الحالية.';

  @override
  String get mobileSpacesArchivedEmpty => 'لا مساحات مؤرشفة';

  @override
  String get mobileSpacesAllRepoWarning =>
      'ستُضم إلى هذه المساحة أيضًا المستودعات التي ستُربط بمساحة العمل لاحقًا.';

  @override
  String get mobileSpacesCreatedRetry =>
      'أُنشئت المساحة. حاول إضافة الأشخاص مجددًا، أو افتح صفحة إدارتها.';

  @override
  String get progressTitle => 'التقدم';

  @override
  String get progressConversation => 'المحادثة';

  @override
  String get progressLoadFailed => 'تعذر تحميل التقدم';

  @override
  String get progressUnavailable => 'المحادثة غير متاحة';

  @override
  String get progressUnavailableDescription =>
      'هذه المحادثة ليست في مساحة العمل والمساحة النشطتين. عُد إلى مساحتها للمتابعة.';

  @override
  String get progressSaveFailed => 'تعذر تحديث التقدم';

  @override
  String get progressGoal => 'الهدف';

  @override
  String get progressNoGoal => 'لم يُحدد هدف للعمل';

  @override
  String get progressSetGoal => 'تحديد الهدف';

  @override
  String get progressEditGoal => 'تحرير الهدف';

  @override
  String get progressClearGoal => 'مسح الهدف';

  @override
  String get progressGoalRequired => 'أدخل هدفًا قبل الحفظ.';

  @override
  String get progressTodos => 'المهام';

  @override
  String get transcriptToolTodos => 'المهام';

  @override
  String get transcriptToolSearchMemory => 'البحث في الذاكرة';

  @override
  String get transcriptToolRenderMedia => 'عرض الوسائط';

  @override
  String get progressNoTodos => 'لا توجد مهام بعد';

  @override
  String get progressNewTodo => 'مهمة جديدة';

  @override
  String get progressAddTodo => 'إضافة مهمة';

  @override
  String get progressEditTodo => 'تحرير المهمة';

  @override
  String get progressTodoRequired => 'أدخل مهمة قبل الحفظ.';

  @override
  String get progressTodoNoLongerExists =>
      'أُزيلت هذه المهمة. أعد تحميل القائمة وحاول مجددًا.';

  @override
  String get progressWorkspaceChanged =>
      'تغيرت مساحة العمل النشطة. عُد إلى هذه المحادثة وحاول مجددًا.';

  @override
  String progressRemoveTodo(String name) {
    return 'إزالة المهمة $name';
  }

  @override
  String get progressPending => 'قيد الانتظار';

  @override
  String get progressInProgress => 'قيد التنفيذ';

  @override
  String get progressCompleted => 'مكتمل';

  @override
  String get progressMoveUp => 'نقل المهمة لأعلى';

  @override
  String get progressMoveDown => 'نقل المهمة لأسفل';

  @override
  String get progressRunTree => 'عمليات تشغيل الوكلاء';

  @override
  String get progressNoRuns => 'لا توجد عمليات تشغيل في هذه المحادثة بعد';

  @override
  String get progressRunning => 'قيد التشغيل';

  @override
  String get progressFailed => 'فشل';

  @override
  String get progressUnknown => 'غير معروف';

  @override
  String get progressHealthy => 'نشط';

  @override
  String get progressBlocked => 'محظور';

  @override
  String get progressLooping => 'في حلقة تكرار';

  @override
  String get progressStalled => 'متعثر';

  @override
  String get progressDead => 'توقف على نحو غير متوقع';

  @override
  String get progressQuiet => 'لا توجد مخرجات بعد';

  @override
  String get progressCostReported => 'رسوم أبلغ عنها المزوّد';

  @override
  String get progressCostNotional => 'سعر اشتراك افتراضي معلن؛ ليس فاتورة';

  @override
  String get progressCostMixed => 'مصادر تكلفة مختلطة';

  @override
  String get progressCostEstimated => 'التكلفة المقدّرة';

  @override
  String progressDurationSeconds(String seconds) {
    return '$seconds ث';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'النموذج: $model · المدة: $duration · التكلفة: $cost';
  }

  @override
  String progressStartedAt(String time) {
    return 'بدأ $time';
  }

  @override
  String progressLiveness(String state) {
    return 'الحالة: $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return 'المدخلات: $input · المخرجات: $output رمزًا';
  }

  @override
  String get progressOutputPreviewLimited =>
      'تظهر أول 6,000 حرف فقط من المخرجات المهيكلة.';

  @override
  String progressRetryOf(String runId) {
    return 'إعادة محاولة للتشغيل $runId';
  }

  @override
  String get progressContext => 'السياق والحدود';

  @override
  String get progressNoAgent => 'لا يوجد وكيل لفحصه';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window رمزًا';
  }

  @override
  String get progressMeasured => 'السياق الذي أبلغ عنه المزوّد في آخر استدعاء';

  @override
  String get progressEstimated => 'مقدّر من المحادثة المحفوظة والسياق الدائم';

  @override
  String get progressContextUnknown => 'لم يُبلّغ عن استخدام السياق بعد';

  @override
  String progressContextPercent(String percent) {
    return '$percent% من نافذة السياق';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return 'الحد الشهري المحدد للوكيل: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return 'المحادثة النشطة المحفوظة: $tokens رمزًا مقدّرًا';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return 'السياق الدائم لـ $agent · $model';
  }

  @override
  String get progressContextSystem => 'موجّه النظام';

  @override
  String get progressContextRules => 'القواعد';

  @override
  String get progressContextSkills => 'المهارات';

  @override
  String get progressContextTools => 'تعريفات الأدوات';

  @override
  String get progressContextMcp => 'أدوات MCP';

  @override
  String get progressContextDeferred => 'الأدوات المؤجلة';

  @override
  String get progressContextSubagents => 'الوكلاء الفرعيون';

  @override
  String get progressContextRunner => 'مشغّل خارجي';

  @override
  String get progressContextMemory => 'الذاكرة';

  @override
  String get progressContextHistory => 'سجل المحادثة';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens رمزًا';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens رمزًا';
  }

  @override
  String get progressOutputs => 'المخرجات الأخيرة';

  @override
  String get progressNoOutputs => 'لا توجد مخرجات حديثة للوكلاء';

  @override
  String get progressStructuredOutputsAbove =>
      'تظهر مخرجات التشغيل المهيكلة ضمن عمليات تشغيل الوكلاء أعلاه.';

  @override
  String get progressRecentOutputsOnly =>
      'تظهر الرسائل الحديثة فقط. افتح المحادثة للاطلاع على العمل الأقدم.';

  @override
  String get progressPlan => 'تخطيط';

  @override
  String get progressArtifact => 'مخرَج';

  @override
  String get progressResult => 'النتيجة';

  @override
  String get progressHideArtifact => 'إخفاء المخرَج';

  @override
  String get progressReadArtifact => 'قراءة المخرَج';

  @override
  String get progressArtifactUnavailable => 'المخرَج لم يعد متاحًا';

  @override
  String get progressArtifactPreviewLimited =>
      'تظهر معاينة محدودة لهذا المخرَج.';

  @override
  String get progressDiagramSource => 'مصدر المخطط';

  @override
  String progressOpenAttachment(String name) {
    return 'فتح $name';
  }

  @override
  String get progressOpenPlan => 'فتح الخطة';

  @override
  String progressOpenDiff(String label) {
    return 'مراجعة الملفات المعدلة: $label';
  }

  @override
  String get progressViewMessage => 'عرض الرسالة';

  @override
  String get pushTitle => 'إشعارات الخلفية';

  @override
  String get pushIntro =>
      'تلقَّ تنبيهًا خاصًا عند وجود ما يستدعي انتباهك، حتى عندما يكون التطبيق مغلقًا. تبقى التفاصيل داخل اتصالك المشفر.';

  @override
  String get pushLoading => 'جارٍ التحقق من إعدادات الإشعارات…';

  @override
  String get pushError => 'تعذر تحديث الإشعارات. تحقق من اتصالك وحاول مجددًا.';

  @override
  String get pushEnable => 'تمكين الإشعارات';

  @override
  String get pushDisable => 'إيقاف الإشعارات';

  @override
  String get pushQuiet => 'إيقاف التنبيهات مؤقتًا على هذا الجهاز';

  @override
  String get pushCategories => 'أرسل لي إشعارات بشأن';

  @override
  String get pushCategoryAgents => 'الوكلاء';

  @override
  String get pushCategoryMessages => 'الرسائل';

  @override
  String get pushCategoryPullRequests => 'طلبات السحب';

  @override
  String get pushCategoryTickets => 'التذاكر';

  @override
  String get pushCategoryCalendar => 'التقويم';

  @override
  String get pushCategoryMachines => 'الأجهزة';

  @override
  String get pushSecureOrigin => 'تتطلب الإشعارات HTTPS.';

  @override
  String get pushInstallIos =>
      'على iPhone أو iPad، أضف هذا التطبيق إلى الشاشة الرئيسية وافتحه منها لتمكين الإشعارات.';

  @override
  String get pushUnsupported => 'هذا المتصفح لا يدعم إشعارات الخلفية.';

  @override
  String get pushDenied =>
      'يفيد المتصفح بأن الإشعارات محظورة. تحقّق من إذن هذا الموقع وإعدادات إشعارات المتصفح أو الجهاز، ثم حدّث الصفحة.';

  @override
  String get pushOsHint =>
      'يحتاج المتصفح أيضًا إلى إذن عرض الإشعارات من إعدادات نظام جهازك.';

  @override
  String get pushServiceUnavailable =>
      'رفضت خدمة الدفع في المتصفح الاشتراك. بعض المتصفحات، مثل Brave، تعطّلها افتراضيًا: ابحث عن خيار رسائل الدفع في إعدادات الخصوصية بالمتصفح، ثم أعد المحاولة.';

  @override
  String get pushWorkerUnavailable =>
      'تعذّر تشغيل خدمة الإشعارات في هذا المتصفح. أعد تحميل الصفحة وحاول مرة أخرى.';

  @override
  String get pushResubscribe => 'إعادة اتصال الإشعارات';

  @override
  String get pushStatusEnabled => 'الإشعارات مفعّلة على هذا الجهاز.';

  @override
  String get pushStatusDisabled => 'الإشعارات معطّلة على هذا الجهاز.';

  @override
  String get credentialsTitle => 'الاتصالات وبيانات الاعتماد';

  @override
  String get credentialsIntro =>
      'اربط الحسابات التي تستخدمها عمليات التشغيل وعمليات التكامل. تُحفظ المعلومات السرية على خادمك، وليس على هذا الهاتف.';

  @override
  String get credentialsModelProviders => 'مزوّدو النماذج';

  @override
  String get credentialsOwnerOnly =>
      'لا يستطيع إضافة بيانات اعتماد مزوّدي النماذج أو تسجيل الدخول إليها أو إزالتها سوى مالك الخادم. تُشارك هذه المفاتيح بين مساحات العمل.';

  @override
  String get credentialsContactOwner =>
      'اطلب من مالك الخادم ربط المزوّد الذي يحتاجه التشغيل المتوقف.';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'يسجّل Claude Code الدخول عبر واجهة سطر الأوامر على الجهاز المضيف. اطلب من مالك الخادم إكمال تسجيل الدخول إلى الحساب أو تجديده في طرفية الجهاز المضيف؛ لا يمكن فعل ذلك من هذا الهاتف.';

  @override
  String get credentialsYourForgeAccounts => 'حسابات استضافة الشيفرة الخاصة بك';

  @override
  String get credentialsYourTicketingAccount => 'حساب خدمة التذاكر الخاص بك';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'التذاكر المحلية لا تحتاج إلى تسجيل دخول. اربط Linear هنا إذا كانت مساحة عملك تستخدمه.';

  @override
  String get credentialsMembershipRequired =>
      'انضم إلى مساحة عمل لإدارة بيانات اعتماد استضافة الشيفرة أو التذاكر. اطلب الوصول من مسؤول مساحة العمل.';

  @override
  String get credentialsSwitchWorkspace =>
      'يشير هذا الرابط إلى مساحة عمل أخرى. انتقل إليها قبل تغيير بيانات الاعتماد.';

  @override
  String get credentialsReturnToInbox =>
      'عُد إلى البريد الوارد لإعادة محاولة تشغيل متوقف بعد ربط بيانات اعتماده. يفحص الجهاز المضيف عمليات التشغيل المعلّقة تلقائيًا أيضًا.';

  @override
  String get credentialsLoadFailed =>
      'تعذر تحميل الاتصالات. تحقق من الاتصال بالخادم وأعد المحاولة.';

  @override
  String get credentialsOperationFailed =>
      'تعذر تغيير هذا الاتصال. تحقق من اتصال الخادم وإمكانية وصولك وبيانات الاعتماد، ثم حاول مجددًا.';

  @override
  String get credentialsConnected => 'متصل';

  @override
  String get credentialsNotConnected => 'غير متصل';

  @override
  String credentialsSignedInAs(String username) {
    return 'تم تسجيل الدخول باسم $username';
  }

  @override
  String get credentialsAccount => 'الحساب المتصل';

  @override
  String get credentialsStoredKey => 'المفتاح المحفوظ';

  @override
  String get credentialsActive => 'نشط';

  @override
  String get credentialsRemove => 'إزالة';

  @override
  String get credentialsRemoveConfirm =>
      'هل تريد إزالة بيانات الاعتماد المحفوظة؟ قد تحتاج إلى تسجيل الدخول مرة أخرى.';

  @override
  String get credentialsApiKey => 'مفتاح API';

  @override
  String get credentialsApiKeyHint => 'الصق مفتاح API للمزوّد';

  @override
  String get credentialsBrowserLogin => 'تسجيل الدخول عبر المتصفح';

  @override
  String get credentialsSignInAgain => 'سجّل الدخول مرة أخرى';

  @override
  String get credentialsWaitingForLogin => 'بانتظار التفويض في متصفحك…';

  @override
  String get credentialsConnectCodePrompt => 'رمز التأكيد';

  @override
  String get credentialsConnectCodeMalformed =>
      'لا يبدو هذا رمز تسجيل دخول. تتكون الرموز من 8 أحرف وأرقام.';

  @override
  String get credentialsSignInInvalidCode =>
      'هذا الرمز لا يطابق تسجيل الدخول هذا. تحقّق منه وحاول مرة أخرى.';

  @override
  String get credentialsSignInTooManyCodes =>
      'رموز خاطئة كثيرة جدًا. ابدأ تسجيل الدخول من جديد.';

  @override
  String get credentialsSignInRetryLater =>
      'خدمة تسجيل الدخول لا تستجيب الآن. انتظر دقيقة ثم حاول مرة أخرى.';

  @override
  String get credentialsSignInRefused =>
      'رُفض تسجيل الدخول. ابدأه من جديد ووافق على كل الأذونات المطلوبة.';

  @override
  String get credentialsSignInNotSaved =>
      'نجح تسجيل الدخول، لكن تعذّر على الخادم حفظه. حاول مرة أخرى.';

  @override
  String credentialsSignInUnavailable(String provider) {
    return 'لم يُعدّ تسجيل الدخول إلى $provider على هذا الخادم بعد.';
  }

  @override
  String get credentialsSignInPhoneUnreachable =>
      'لا يمكن الوصول إلى عنوان رد تسجيل الدخول لهذا الخادم بشكل آمن من الهاتف. سجّل الدخول من تطبيق سطح المكتب، أو اطلب من مالك الخادم إعداد عنوان HTTPS عام.';

  @override
  String get credentialsLoginTimedOut =>
      'انتهت صلاحية تسجيل الدخول. ابدأ محاولة جديدة.';

  @override
  String get credentialsCopyCode => 'نسخ الرمز';

  @override
  String get credentialsDeviceCodeHint =>
      'أكّد هذا الرمز على صفحة المزوّد. أبقِ هذه الشاشة مفتوحة حتى يكمل الخادم تسجيل الدخول.';

  @override
  String get credentialsPasteRedirect =>
      'رمز التفويض أو عنوان URL لإعادة التوجيه';

  @override
  String get credentialsPasteRedirectHint =>
      'الصق الرمز أو عنوان URL الكامل لإعادة التوجيه من المزوّد';

  @override
  String get credentialsCompleteLogin => 'إكمال تسجيل الدخول';

  @override
  String get credentialsUpdateToken => 'تحديث رمز الوصول';

  @override
  String get credentialsAddToken => 'إضافة رمز وصول';

  @override
  String get credentialsPersonalToken => 'رمز وصول شخصي';

  @override
  String get credentialsPersonalTokenHint => 'الصق رمز وصول شخصيًا';

  @override
  String get credentialsStopWatching => 'إيقاف المتابعة';

  @override
  String get transcriptClaudeSignInExpiredTitle =>
      'انتهت صلاحية تسجيل الدخول إلى Claude Code';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      'توقف التشغيل لأن حسابه لم يعد يجتاز المصادقة. سجّل الدخول مرة أخرى، ثم أعد محاولة الدور.';

  @override
  String get transcriptSignInExpiredTitle =>
      'انتهت صلاحية تسجيل الدخول إلى المزوّد';

  @override
  String get transcriptSignInExpiredBody =>
      'توقف التشغيل لأن بيانات اعتماد المزوّد لم تعد تعمل. أعد ربطه من الإعدادات ← المزوّدون، ثم أعد محاولة الدور.';

  @override
  String get permissionHostExecution => 'تشغيل الأوامر على المضيف';

  @override
  String credentialsSignInLapsed(String provider) {
    return 'انتهت صلاحية تسجيل دخولك إلى $provider. سجّل الدخول مجددًا.';
  }

  @override
  String get credentialsSignInPaused =>
      'متوقف مؤقتًا: تغيّرت خدمة تسجيل الدخول في مساحة العمل هذه. سيعمل مجددًا عند عودة الخدمة.';

  @override
  String credentialsProviderUnreachable(String provider) {
    return 'يتعذر الوصول إلى $provider الآن. جارٍ إعادة المحاولة.';
  }

  @override
  String get credentialsScopeWorkspace => 'مساحة العمل هذه فقط';

  @override
  String get credentialsScopeAllWorkspaces => 'كل مساحات العمل';

  @override
  String get credentialsRemoveConfirmWorkspace =>
      'إزالة بيانات الاعتماد المحفوظة من مساحة العمل هذه؟ تحتفظ مساحات العمل الأخرى ببياناتها.';

  @override
  String get credentialsRemoveConfirmAllWorkspaces =>
      'إزالة بيانات الاعتماد المحفوظة من كل مساحات العمل التي تشاركها؟';

  @override
  String get credentialsSignInServerRestarted =>
      'أُعيد تشغيل الخادم. ابدأ تسجيل الدخول من جديد.';

  @override
  String repoAccessInstallApp(String owner, String names) {
    return 'ثبّت GitHub App على $owner لتصل الأتمتة إلى $names. اضغط لفتح GitHub.';
  }

  @override
  String repoAccessAskAdminInstall(String owner, String names) {
    return 'GitHub App غير مثبّت على $owner، لذا لا تصل الأتمتة إلى $names. اطلب من مسؤول مساحة العمل تثبيته.';
  }

  @override
  String repoAccessAddToApp(String names) {
    return 'أضف $names إلى مستودعات GitHub App. اضغط لفتح GitHub.';
  }

  @override
  String repoAccessAskAdminAdd(String names) {
    return 'لا يرى GitHub App $names بعد. اطلب من مسؤول مساحة العمل إضافتها إلى مستودعاته.';
  }

  @override
  String repoAccessSuspended(String names) {
    return 'تم تعليق تثبيت GitHub App. الأتمتة لـ $names متوقفة مؤقتًا حتى يستأنف أحد مالكي الحساب التثبيت على GitHub.';
  }

  @override
  String repoAccessOwnerCannotSee(String names) {
    return 'لم يعد الشخص المسؤول عن أتمتة مساحة العمل هذه يرى $names، لذا لا يعمل شيء هناك باسمه.';
  }

  @override
  String repoAccessOwnerNotSignedIn(String names) {
    return 'الشخص المسؤول عن أتمتة مساحة العمل هذه لم يسجّل الدخول إلى منصة الاستضافة، لذا تنتظر الأتمتة لـ $names حتى يسجّل الدخول.';
  }

  @override
  String repoAccessRetrying(String names) {
    return 'تعذر التحقق من الوصول إلى $names. جارٍ إعادة المحاولة.';
  }

  @override
  String hiddenReposSignIn(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'سجّل الدخول إلى $forge لرؤية طلبات السحب من مستودعات إضافية: $count',
      one: 'سجّل الدخول إلى $forge لرؤية طلبات السحب من مستودع إضافي واحد',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoForgeAccess(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'مستودعات مخفية لأن حسابك على $forge لا يراها: $count',
      one: 'مستودع واحد مخفي لأن حسابك على $forge لا يراه',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoGrant(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'مستودعات مخفية ليس لديك وصول إليها في مساحة العمل هذه: $count',
      one: 'مستودع واحد مخفي لأنه ليس لديك وصول إليه في مساحة العمل هذه',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposChecking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'جارٍ التحقق من وصولك إلى مستودعات إضافية: $count…',
      one: 'جارٍ التحقق من وصولك إلى مستودع إضافي واحد…',
    );
    return '$_temp0';
  }

  @override
  String get credentialsAtlassianEmail => 'البريد الإلكتروني لحساب Atlassian';

  @override
  String get credentialsAtlassianEmailInvalid =>
      'أدخل عنوان البريد الإلكتروني لحسابك على Atlassian.';

  @override
  String get credentialsBitbucketApiToken => 'رمز API';

  @override
  String repoAccessAutomationTokenMissing(String names) {
    return 'لا يوجد رمز أتمتة يستطيع قراءة $names، لذا فالعمل في الخلفية هناك متوقف مؤقتًا. يمكن للمسؤول إضافة رمز من الإعدادات ← المستودعات.';
  }

  @override
  String get credentialsSignInConfirmInBrowser =>
      'أكِّد في متصفحك، ثم أدخل الرمز الذي يظهر فيه.';

  @override
  String get credentialsSignInAccountAlreadyBound =>
      'هذا الحساب مرتبط بالفعل بشخص آخر على هذا الخادم. سجّل الدخول بحساب مختلف.';

  @override
  String credentialsTokenUnreachable(String provider) {
    return 'تعذّر الوصول إلى $provider للتحقق من هذا الرمز. حاول مرة أخرى بعد قليل.';
  }

  @override
  String credentialsTokenRejected(String provider) {
    return '$provider لا يقبل هذا الرمز. تحقّق من أنك نسخته كاملًا وأنه لم يُلغَ.';
  }

  @override
  String credentialsTokenWrongKind(String provider) {
    return 'هذا ليس رمز وصول شخصيًا. الصق رمز وصول شخصيًا من حسابك الخاص على $provider، لا رمز مشروع أو مجموعة أو مساحة عمل أو روبوت.';
  }

  @override
  String credentialsTokenNarrowScope(String scope) {
    return 'ينقص هذا الرمز نطاق $scope. أنشئ رمزًا يتضمنه.';
  }

  @override
  String get credentialsTokenExpired =>
      'انتهت صلاحية هذا الرمز. أنشئ رمزًا جديدًا والصقه هنا.';

  @override
  String get credentialsSignInRateLimited =>
      'طلبات كثيرة جدًا الآن. انتظر قليلًا ثم حاول مرة أخرى.';

  @override
  String get credentialsSignInCancelled =>
      'أُلغي تسجيل الدخول أو رُفض. ابدأه من جديد عندما تكون مستعدًا.';

  @override
  String get credentialsSignInNoLongerOpen =>
      'تسجيل الدخول هذا لم يعد مفتوحًا: أُلغي أو استُخدم أو استُبدل. ابدأه من جديد.';

  @override
  String get noWorkspacesYetHint =>
      'يجب أن يدعوك مسؤول مساحة عمل، أو يمكن لمالك الخادم إنشاء مساحة عمل لك.';

  @override
  String repoAccessReplaced(String repos, String forge) {
    return '$repos يشير الآن إلى مستودع مختلف على $forge. أعِد ربطه من تطبيق سطح المكتب أو الويب لمواصلة استخدامه.';
  }

  @override
  String repoAccessAskAdminRelink(String repos, String forge) {
    return '$repos يشير الآن إلى مستودع مختلف على $forge. يجب أن يعيد مسؤول مساحة العمل ربطه قبل أن يُستخدم مجددًا.';
  }

  @override
  String get runSandboxUnavailableTitle =>
      'يحتاج الوكلاء إلى حاوية معزولة على هذا الخادم';

  @override
  String get runSandboxUnavailable =>
      'لا توجد حاوية معزولة على هذا الخادم، لذا لا يمكن إلا لمالكه تشغيل الوكلاء هنا. يمكن للمالك تثبيت الحاوية المعزولة، أو إيقاف العزل للجميع.';

  @override
  String get scriptToolCalls => 'استدعاءات الأدوات';

  @override
  String scriptCallCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count استدعاء',
      many: '$count استدعاءً',
      few: '$count استدعاءات',
      two: 'استدعاءان',
      one: 'استدعاء واحد',
    );
    return '$_temp0';
  }

  @override
  String scriptCallsRunning(int count) {
    return '$count قيد التشغيل';
  }

  @override
  String scriptCallsOk(int count) {
    return '$count ناجح';
  }

  @override
  String scriptCallsFailed(int count) {
    return '$count فشل';
  }

  @override
  String scriptCallsDenied(int count) {
    return '$count مرفوض';
  }

  @override
  String scriptCallsCancelled(int count) {
    return '$count أُلغي';
  }

  @override
  String scriptCallsQueued(int count) {
    return '$count في قائمة الانتظار';
  }

  @override
  String scriptCallsSkipped(int count) {
    return '$count تم تخطيه';
  }

  @override
  String get scriptStepQueued => 'في قائمة الانتظار';

  @override
  String get scriptStepSkipped => 'تم تخطيه';

  @override
  String get scriptGroupLoop => 'حلقة';

  @override
  String get scriptGroupEach => 'لكل عنصر';

  @override
  String get scriptGroupParallel => 'بالتوازي';

  @override
  String get scriptGroupFunction => 'دالة';

  @override
  String scriptCallsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'إظهار $count استدعاء إضافي',
      many: 'إظهار $count استدعاءً إضافيًا',
      few: 'إظهار $count استدعاءات إضافية',
      two: 'إظهار استدعاءين إضافيين',
      one: 'إظهار استدعاء واحد إضافي',
    );
    return '$_temp0';
  }

  @override
  String get scriptCallsUnplaced => 'استدعاءات لم تُوضع في السكربت';

  @override
  String get scriptToolComputed => 'الأداة';

  @override
  String scriptStepSemantics(String subject, String state) {
    return '$subject، $state';
  }

  @override
  String get scriptSourceLabel => 'السكربت';

  @override
  String scriptSourceLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سطر',
      many: '$count سطرًا',
      few: '$count أسطر',
      two: 'سطران',
      one: 'سطر واحد',
    );
    return '$_temp0';
  }

  @override
  String get scriptStateRunning => 'قيد التشغيل';

  @override
  String get scriptStateCompleted => 'مكتمل';

  @override
  String get scriptStateFailed => 'فشل';

  @override
  String get scriptStateTimedOut => 'انتهت المهلة';

  @override
  String get scriptStateCancelled => 'أُلغي';

  @override
  String get scriptStateMemoryExceeded => 'نفدت الذاكرة';

  @override
  String get scriptStateOutputExceeded => 'مخرج كبير جدًا';

  @override
  String get scriptStateSandboxError => 'خطأ في البيئة المعزولة';

  @override
  String get scriptStateRefused => 'مرفوض';

  @override
  String get scriptOriginLine => 'من سكربت يشغّله الوكيل';

  @override
  String get codeModeTitle => 'وضع الكود';

  @override
  String get codeModeAvailable => 'متاح';

  @override
  String get codeModeUnavailable => 'غير متاح';

  @override
  String codeModeUnavailableNote(String reason) {
    return 'لا يستطيع هذا الخادم تشغيل السكربتات، لذا يستدعي الوكلاء هنا أدواتهم واحدةً تلو الأخرى. ما يقوله الخادم: $reason';
  }

  @override
  String get codeModeNoReason => 'لم يُذكر سبب.';

  @override
  String get workKindUnknown => 'لسبب لا تذكره هذه النسخة:';

  @override
  String get workRefusalUnknown => 'رفض الخادم هذا:';

  @override
  String workActionFailed(String error) {
    return 'لم ينجح ذلك: $error';
  }

  @override
  String get wakeKindStopped => 'محتجز لأن شخصًا أوقف التشغيل.';

  @override
  String get wakeKindAttempts => 'فشل التسليم ثلاث مرات.';

  @override
  String get wakeKindAgentDeleted => 'الوكيل لم يعد موجودًا.';

  @override
  String get wakeKindAgentNotDispatchable => 'الوكيل مُتقاعد.';

  @override
  String get wakeKindAgentPaused => 'الوكيل متوقف مؤقتًا.';

  @override
  String get wakeKindPersonRemoved =>
      'الشخص الذي يعمل الإيقاظ باسمه غادر مساحة العمل.';

  @override
  String get wakeKindBudgetBlocked => 'الميزانية تمنع التشغيل.';

  @override
  String get wakeKindTakeOver => 'تولّى شخص شجرة العمل.';

  @override
  String get wakeKindRateCapConversation =>
      'بدأت هذه المحادثة 30 تشغيلًا من عمليات الإيقاظ في الساعة الأخيرة.';

  @override
  String get wakeKindRateCapWorkspace =>
      'بدأت مساحة العمل هذه 300 تشغيل من عمليات الإيقاظ في الساعة الأخيرة.';

  @override
  String get wakeKindLiveRunNoInput =>
      'التشغيل المباشر للوكيل هنا لا يقبل مدخلات.';

  @override
  String get wakeKindLiveRunOtherOptions =>
      'التشغيل المباشر للوكيل هنا يعمل بشكل مختلف، لذلك سيبدأ هذا تشغيلًا خاصًا به بعده.';

  @override
  String get wakeKindLiveRunOtherPerson =>
      'التشغيل المباشر للوكيل هنا يعمل باسم شخص آخر، لذلك سيبدأ هذا تشغيلًا خاصًا به بعده.';

  @override
  String get wakeKindDispatchRefused => 'تعذّر بدء التشغيل.';

  @override
  String get wakeKindSandboxUnavailable =>
      'لا تتوفر بيئة معزولة لتشغيل للقراءة فقط.';

  @override
  String get wakeKindReadOnlyUnavailable =>
      'لا تستطيع خلفية هذا الوكيل إبقاء التشغيل للقراءة فقط.';

  @override
  String get wakeKindServerStopped => 'أوقفت إعادة تشغيل الخادم التشغيل.';

  @override
  String get wakeKindServerRestarted => 'أُعيد تشغيل الخادم أثناء تشغيل لشخص.';

  @override
  String get wakeKindGuardFailed => 'فشل فحص قبل التسليم.';

  @override
  String get wakeKindLimit => 'في انتظار إعادة ضبط حد استخدام المزوّد.';

  @override
  String get wakeKindLimitRunLive =>
      'في انتظار انتهاء التشغيل عند حد الاستخدام.';

  @override
  String get wakeKindWakeMissed => 'فات أثناء توقف الخادم.';

  @override
  String get wakeKindPipelineRunEnded => 'انتهى تشغيل خط الأنابيب الخاص به.';

  @override
  String get wakeKindGoalEnded => 'انتهى هدفه.';

  @override
  String get wakeKindGoalBudgetExhausted => 'استنفد هدفه ميزانيته.';

  @override
  String get wakeKindGoalReviewStale => 'تغيّر الهدف منذ طُلبت هذه المراجعة.';

  @override
  String get wakeKindGoalPaused => 'هدفه متوقف مؤقتًا.';

  @override
  String get wakeKindGoalHeld => 'هدفه محتجز.';

  @override
  String get wakeKindGoalStopped => 'أُوقف هدفه.';

  @override
  String get wakeKindAskSettled => 'السؤال الذي يجيب عنه حُسم من قبل.';

  @override
  String get wakeKindRuleEnded => 'انتهت جدولته.';

  @override
  String get wakeRefusalNotYours =>
      'هذا الإيقاظ يعمل باسم شخص آخر. هو وحده يستطيع تسليمه أو استئنافه.';

  @override
  String get wakeRefusalSettled => 'حُسم هذا الإيقاظ من قبل.';

  @override
  String get goalRefusalAlreadyActive => 'لهذا الوكيل هدف نشط بالفعل.';

  @override
  String get goalRefusalNotInReview => 'هذا الهدف ليس في انتظار المراجعة.';

  @override
  String get goalRefusalEvidenceIncomplete => 'أدلة الهدف غير مكتملة.';

  @override
  String get goalRefusalClaimPending => 'ما زال يجري فحص ادعاء بأنه تم.';

  @override
  String get goalRefusalNotActiveSegment => 'لا يعمل أي مقطع لهذا الهدف.';

  @override
  String get goalRefusalNotYours =>
      'الشخص الذي بدأ هذا الهدف وحده يستطيع فعل ذلك.';

  @override
  String get goalRefusalNotPaused => 'أوقف الهدف مؤقتًا أولًا.';

  @override
  String get goalRefusalContractInvalid => 'تعذّرت قراءة عقد الهدف.';

  @override
  String get goalRefusalCheckerUnknown => 'لا يوجد وكيل بهذا الاسم.';

  @override
  String get goalRefusalCheckerAmbiguous => 'أكثر من وكيل يحمل هذا الاسم.';

  @override
  String get goalRefusalCheckerIsGoalAgent =>
      'يجب أن يكون المدقق وكيلًا غير الوكيل الذي ينفذ العمل.';

  @override
  String get goalRefusalCommandInvalid => 'تعذّرت قراءة هذا الهدف:';

  @override
  String get wakeRuleRefusalIntervalTooShort =>
      'الفاصل قصير جدًا. اختر دقيقة واحدة على الأقل.';

  @override
  String get wakeRuleRefusalTooSoon =>
      'هذا الوقت قريب جدًا. اختر وقتًا لاحقًا.';

  @override
  String get wakeRuleRefusalLineageEnded =>
      'استنفدت سلسلة الإيقاظ هذه تشغيلاتها أو وقتها.';

  @override
  String get wakeRuleRefusalWatchTargetUnreadable =>
      'لا يمكنك قراءة ما ستراقبه هذه المراقبة.';

  @override
  String get wakeRuleRefusalExpiryRequired =>
      'حدّد لها تاريخ انتهاء أو عدد تشغيلات.';

  @override
  String get wakeRuleRefusalLimitReached =>
      'لهذه المحادثة أو هذا الوكيل بالفعل أقصى عدد من الجدولات المسموح به.';

  @override
  String get wakeRuleRefusalInvalidWhen => 'تعذّرت قراءة الوقت.';

  @override
  String get wakeRuleRefusalNoteTooLong => 'الملاحظة طويلة جدًا.';

  @override
  String get wakeRuleRefusalExpiryTooLong => 'النهاية بعيدة جدًا.';

  @override
  String get wakeRuleRefusalLimitOutOfRange =>
      'حد التشغيلات أو الأيام أو الميزانية خارج النطاق.';

  @override
  String get wakeRuleRefusalNextOutsideLoop =>
      'الحلقة وحدها تستطيع اختيار وقتها التالي.';

  @override
  String get wakeRuleRefusalWatchRefused => 'لا يمكن مراقبة ذلك.';

  @override
  String get wakeRuleRefusalRuleEnded => 'انتهت هذه الجدولة بالفعل.';

  @override
  String get wakeRuleRefusalNotYours => 'هذه الجدولة تخص شخصًا آخر.';

  @override
  String get wakeRuleEndFired => 'شغّل مرته الواحدة.';

  @override
  String get wakeRuleEndExpired => 'بلغ تاريخ انتهائه.';

  @override
  String get wakeRuleEndRunCap => 'استنفد تشغيلاته.';

  @override
  String get wakeRuleEndCostCap => 'بلغ حد التكلفة.';

  @override
  String get wakeRuleEndGoalEnded => 'انتهى هدفه.';

  @override
  String get wakeRuleEndCancelled => 'أُلغيت.';

  @override
  String get wakeRuleEndMemberRemoved => 'غادر الشخص المعني مساحة العمل.';

  @override
  String get wakeRuleEndInvalidRow => 'تعذّرت قراءة إعداداته المخزّنة.';

  @override
  String goalHoldWorking(int segment) {
    final intl.NumberFormat segmentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String segmentString = segmentNumberFormat.format(segment);

    return 'يعمل على المقطع $segmentString. لا يحتاج أحد إلى التدخل.';
  }

  @override
  String get goalHoldWaiting => 'في انتظار عمل مستحق له. سيستمر من تلقاء نفسه.';

  @override
  String goalHoldWaitingUntil(String time) {
    return 'في انتظار عمل مستحق له. سيستمر من تلقاء نفسه في $time في أبعد حد.';
  }

  @override
  String get goalHoldVerifying =>
      'يقول إنه تم. يشغّل الخادم فحوصه، ثم يقرر المراجع.';

  @override
  String get goalHoldLimit =>
      'متوقف عند حد استخدام المزوّد. يُستأنف من تلقاء نفسه بعد إعادة الضبط.';

  @override
  String goalHoldLimitUntil(String time) {
    return 'متوقف عند حد استخدام المزوّد. يُستأنف من تلقاء نفسه في $time.';
  }

  @override
  String get goalHoldPerson =>
      'في انتظار رد شخص في المحادثة. سيستمر بعد أن يجيب أحد.';

  @override
  String get goalHoldByPerson =>
      'أوقفه شخص مؤقتًا. يبقى متوقفًا حتى يستأنفه أحد.';

  @override
  String get goalHoldNeedsReview =>
      'في انتظار المراجعة: لا يستطيع المضي وحده. وافق عليه كمنجز، أو استأنفه، أو ألغِه.';

  @override
  String get goalHoldBudget => 'استنفد ميزانيته. ارفع الميزانية ليستمر.';

  @override
  String goalHoldLimitParks(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'مرات الإيقاف عند حد الاستخدام: $countString من $maxString';
  }

  @override
  String get goalHoldDetailStalled => 'لا تقدّم في مقاطعه الأخيرة.';

  @override
  String get goalHoldDetailStalledWaiting =>
      'انتظر 24 ساعة على العمل نفسه دون تقدّم.';

  @override
  String get goalHoldDetailVerificationFailed => 'فشل آخر فحص.';

  @override
  String get goalHoldDetailCannotVerify => 'تعذّر على المدقق الجزم بأنه تم.';

  @override
  String get goalHoldDetailSandboxUnavailable =>
      'لا تتوفر بيئة معزولة لتشغيل فحوصه.';

  @override
  String get goalHoldDetailCheckerUnavailable =>
      'وكيل المدقق غير متاح. اختر مدققًا آخر، ثم استأنف.';

  @override
  String get goalHoldDetailCheckBroken => 'هذا الفحص لا يمكن تشغيله:';

  @override
  String get goalHoldDetailWakeSkipped => 'لم يُسلَّم إيقاظه.';

  @override
  String get goalHoldDetailClaimPending => 'ادعاؤه بأنه تم ينتظر فحصًا.';

  @override
  String get goalHoldDetailUnanswered =>
      'بقي سؤال أو طلب موافقة موجَّه إلى شخص بلا رد.';

  @override
  String get goalHoldDetailLimitParks =>
      'تجاوز حدود الاستخدام مرات كثيرة. راجعه، ثم استأنف.';

  @override
  String get goalHoldDetailInput => 'في انتظار رد في المحادثة.';

  @override
  String goalSegments(int run, int max) {
    final intl.NumberFormat runNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String runString = runNumberFormat.format(run);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'المقطع $runString من $maxString';
  }

  @override
  String goalSegmentsNoCap(int run) {
    final intl.NumberFormat runNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String runString = runNumberFormat.format(run);

    return 'المقطع $runString، بلا حد';
  }

  @override
  String goalMoney(String spent, String cap) {
    return 'أُنفق $spent من $cap';
  }

  @override
  String goalDeadline(String time) {
    return 'الموعد النهائي $time';
  }

  @override
  String get goalPipelineStep => 'خطوة في خط أنابيب تعمل على هذا الهدف.';

  @override
  String get goalSummaryHeading => 'آخر ملخص';

  @override
  String get goalDoneMeans => 'المطلوب للإنجاز';

  @override
  String get goalChecks => 'الفحوصات';

  @override
  String get goalBoundaries => 'الحدود';

  @override
  String get goalStopWhen => 'توقف واسأل عندما';

  @override
  String get goalNoMachineCheck =>
      'لا يوجد فحص آلي. يحكم المراجع بناءً على ما يستطيع قراءته.';

  @override
  String get goalCheckEnvironment => 'مهمة البيئة';

  @override
  String goalLastCheck(int round, String time) {
    final intl.NumberFormat roundNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String roundString = roundNumberFormat.format(round);

    return 'آخر فحص، الجولة $roundString، $time';
  }

  @override
  String get goalClaim => 'ما ادّعاه';

  @override
  String get goalCheckPassed => 'ناجح';

  @override
  String goalCheckFailed(int code) {
    return 'فشل، رمز الخروج $code';
  }

  @override
  String get goalCheckTimedOut => 'انتهت المهلة';

  @override
  String get goalCheckNotRerun => 'لم يُعَد تشغيله: لم يتغير شيء';

  @override
  String get goalCheckBroken => 'تعذّر التشغيل';

  @override
  String get goalCriterionMet => 'مُستوفى';

  @override
  String get goalCriterionUnmet => 'غير مُستوفى';

  @override
  String get goalCriterionCannotTell => 'لا يمكن الجزم';

  @override
  String get goalVerdictPass => 'الحكم: تم';

  @override
  String get goalVerdictFail => 'الحكم: لم يتم';

  @override
  String get goalVerdictCannotVerify => 'الحكم: تعذّر الجزم';

  @override
  String get goalConcerns => 'المخاوف';

  @override
  String goalVerifiedBy(String agent) {
    return 'تحقق منه $agent';
  }

  @override
  String get goalVerifiedBySelf => 'تحقق منه بنفسه (دون مدقق منفصل)';

  @override
  String get goalClosedByPerson => 'أغلقه شخص دون فحص ناجح';

  @override
  String get goalApprove => 'الموافقة على الإكمال';

  @override
  String get goalApproveTitle => 'إغلاق هذا الهدف كمنجز؟';

  @override
  String get goalApproveBody =>
      'لم يؤكده أي فحص. تُغلقه بكلمتك، ويسجّل الهدف أن شخصًا أغلقه دون تحقق.';

  @override
  String get goalApproveConfirm => 'إغلاق كمنجز';

  @override
  String get goalResumeNotYours => 'استئنافه أو رفع ميزانيته من حق من بدأه.';

  @override
  String get goalChooseChecker => 'اختر مدققًا آخر';

  @override
  String goalCheckerSet(String agent) {
    return 'يدقّقه $agent الآن. استأنف ليُتحقق منه مجددًا.';
  }

  @override
  String get goalSchedules => 'الجدولات';

  @override
  String get goalRepeat => 'تكرار';

  @override
  String get goalCreateChecks => 'الفحوصات (اختياري)';

  @override
  String get goalCreateCheckHint => 'أمر ينجح عندما يكتمل العمل';

  @override
  String get goalCreateAddCheck => 'إضافة فحص';

  @override
  String get goalCreateRemoveCheck => 'إزالة الفحص';

  @override
  String get goalCreateSegmentCap => 'حد المقاطع (اختياري)';

  @override
  String get goalCreateSegmentInvalid => 'حد المقاطع عدد صحيح، 1 على الأقل.';

  @override
  String get scheduleCreateTitle => 'تكرار مطالبة';

  @override
  String get scheduleCadence => 'كم مرة';

  @override
  String get scheduleEveryMinutes => 'كل N دقيقة';

  @override
  String get scheduleEveryHours => 'كل N ساعة';

  @override
  String get scheduleSelfPaced => 'بتوقيت ذاتي';

  @override
  String get scheduleSelfPacedHint =>
      'يختار الوكيل التأخير بعد كل تشغيل، بين دقيقة وساعة.';

  @override
  String get scheduleInterval => 'الفاصل';

  @override
  String get scheduleNote => 'ماذا يفعل كل تشغيل؟';

  @override
  String get scheduleCostCap => 'حد التكلفة بالدولار (اختياري)';

  @override
  String get scheduleExpiryDays => 'ينتهي بعد N يومًا (اختياري)';

  @override
  String get scheduleCreateInvalid =>
      'اختر مساحة ووكيلًا، واكتب ما يجب أن يفعله كل تشغيل، واكتب أعدادًا صحيحة لا تقل عن 1.';

  @override
  String get scheduleCreateButton => 'بدء الجدولة';

  @override
  String get scheduleCreateConfirmTitle => 'بدء هذه الجدولة؟';

  @override
  String scheduleCreateConfirmEveryMinutes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تعمل كل $countString دقيقة، ابتداءً من الآن.',
      many: 'تعمل كل $countString دقيقةً، ابتداءً من الآن.',
      few: 'تعمل كل $countString دقائق، ابتداءً من الآن.',
      two: 'تعمل كل دقيقتين، ابتداءً من الآن.',
      one: 'تعمل كل دقيقة، ابتداءً من الآن.',
    );
    return '$_temp0';
  }

  @override
  String scheduleCreateConfirmEveryHours(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تعمل كل $countString ساعة، ابتداءً من الآن.',
      many: 'تعمل كل $countString ساعةً، ابتداءً من الآن.',
      few: 'تعمل كل $countString ساعات، ابتداءً من الآن.',
      two: 'تعمل كل ساعتين، ابتداءً من الآن.',
      one: 'تعمل كل ساعة، ابتداءً من الآن.',
    );
    return '$_temp0';
  }

  @override
  String get scheduleCreateConfirmSelfPaced =>
      'تعمل الآن، ثم يختار الوكيل موعد التشغيل التالي.';

  @override
  String get scheduleCreated => 'بدأت الجدولة. وهي مدرجة ضمن الجدولات.';

  @override
  String get schedulesTitle => 'الجدولات';

  @override
  String get schedulesLoadFailed => 'تعذّر تحميل الجدولات';

  @override
  String get schedulesEmpty => 'لا توجد جدولات ولا مراقبات';

  @override
  String get schedulesEmptyDescription =>
      'كرّر مطالبة من شاشة الأهداف، أو أرسل /loop أو /schedule في محادثة.';

  @override
  String get scheduleMissing => 'لم تعد هذه الجدولة متاحة في مساحة العمل هذه.';

  @override
  String scheduleEvery(String interval) {
    return 'كل $interval';
  }

  @override
  String get scheduleSelfPacedLoop => 'حلقة بتوقيت ذاتي';

  @override
  String get scheduleCron => 'جدولة cron';

  @override
  String scheduleOnce(String time) {
    return 'مرة واحدة في $time';
  }

  @override
  String scheduleWatch(String event) {
    return 'مراقبة: $event';
  }

  @override
  String get scheduleWatchPrChecks => 'فحوصات طلب السحب';

  @override
  String get scheduleWatchPrReview => 'مراجعات طلب السحب';

  @override
  String get scheduleWatchPrMerged => 'دمج طلب السحب';

  @override
  String get scheduleWatchEnvironment => 'البيئة';

  @override
  String get scheduleWatchTicket => 'التذكرة';

  @override
  String get scheduleWatchPipelineRun => 'تشغيل خط الأنابيب';

  @override
  String get scheduleStatusActive => 'نشطة';

  @override
  String get scheduleStatusPaused => 'متوقفة مؤقتًا';

  @override
  String get scheduleStatusEnded => 'منتهية';

  @override
  String scheduleWakes(String agent) {
    return 'يوقظ $agent';
  }

  @override
  String scheduleNext(String time) {
    return 'التشغيل التالي $time';
  }

  @override
  String scheduleLast(String time) {
    return 'آخر تشغيل $time';
  }

  @override
  String scheduleRuns(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString تشغيل',
      many: '$countString تشغيلًا',
      few: '$countString تشغيلات',
      two: 'تشغيلان',
      one: 'تشغيل واحد',
    );
    return '$_temp0';
  }

  @override
  String scheduleRunsOf(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return '$countString من $maxString تشغيلات';
  }

  @override
  String scheduleSkipped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString تخطٍّ',
      many: '$countString تخطيًا',
      few: '$countString تخطيات',
      two: 'تخطيان',
      one: 'تخطٍّ واحد',
    );
    return '$_temp0';
  }

  @override
  String scheduleEnds(String time) {
    return 'تنتهي $time';
  }

  @override
  String scheduleChain(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'جزء من سلسلة: $countString تشغيلات متبقية، وتنتهي $time';
  }

  @override
  String get scheduleNoteAgent => 'ملاحظة الوكيل الخاصة، بكلماته:';

  @override
  String get scheduleNotePerson => 'ملاحظة شخص:';

  @override
  String scheduleActsFor(String name) {
    return 'يعمل باسم $name';
  }

  @override
  String get scheduleActsForBot => 'لا يعمل باسم أي شخص';

  @override
  String get scheduleGoalBound => 'ينتهي مع هدفه.';

  @override
  String get schedulePause => 'إيقاف مؤقت';

  @override
  String get scheduleResume => 'استئناف';

  @override
  String get scheduleDelete => 'حذف';

  @override
  String get scheduleRemove => 'إزالة';

  @override
  String get scheduleDeleteTitle => 'حذف هذه الجدولة؟';

  @override
  String get scheduleDeleteBody => 'تتوقف نهائيًا. ولا يُلغى ما فعلته من قبل.';

  @override
  String get scheduleRemoveTitle => 'إزالة هذه الجدولة؟';

  @override
  String get scheduleRemoveBody => 'تختفي من القائمة.';

  @override
  String get scheduleResumeNotYours =>
      'لا يستطيع استئنافها إلا الشخص الذي تعمل الجدولة باسمه.';

  @override
  String get scheduleResumeAdminOnly =>
      'لا يستطيع استئناف جدولة لا يملكها شخص إلا مسؤول مساحة العمل.';

  @override
  String get scheduleOpenConversation => 'فتح المحادثة';

  @override
  String get progressWaiting => 'في الانتظار';

  @override
  String get progressNothingWaiting => 'لا شيء ينتظر.';

  @override
  String get wakeOriginGoal => 'الهدف';

  @override
  String get wakeOriginGoalCheck => 'فحص الهدف';

  @override
  String get wakeOriginGoalReview => 'مراجعة الهدف';

  @override
  String get wakeOriginSchedule => 'الجدولة';

  @override
  String get wakeOriginWatch => 'المراقبة';

  @override
  String get wakeOriginReply => 'ردّ';

  @override
  String get wakeOriginMessage => 'رسالة';

  @override
  String get wakeOriginWorkFinished => 'عمل منجز';

  @override
  String get wakeOriginLimitReset => 'إعادة ضبط الحد';

  @override
  String get wakeOriginRecovery => 'الاستعادة';

  @override
  String get wakeOriginAssignment => 'التكليف';

  @override
  String get wakeOriginPipelineStep => 'خطوة خط الأنابيب';

  @override
  String get wakeOriginImprovementReview => 'مراجعة التحسينات';

  @override
  String wakeOriginReplyFrom(String agent) {
    return 'ردّ من $agent';
  }

  @override
  String wakeOriginMessageFrom(String agent) {
    return 'رسالة من $agent';
  }

  @override
  String wakeOriginWorkFinishedBy(String agent) {
    return 'عمل منجز من $agent';
  }

  @override
  String wakeFor(String agent) {
    return 'لـ $agent';
  }

  @override
  String wakeDue(String time) {
    return 'موعده $time';
  }

  @override
  String get wakeDueNow => 'موعده الآن';

  @override
  String get wakeHeld => 'محتجز';

  @override
  String wakeExpires(String time) {
    return 'ينتهي $time';
  }

  @override
  String wakeAttempt(int attempt) {
    final intl.NumberFormat attemptNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String attemptString = attemptNumberFormat.format(attempt);

    return 'المحاولة $attemptString';
  }

  @override
  String get wakeCancel => 'إلغاء';

  @override
  String get wakeDeliverNow => 'تسليم الآن';

  @override
  String get wakeResume => 'استئناف';

  @override
  String get wakeDismiss => 'تجاهل';

  @override
  String get wakeResumeOnlyTheirs =>
      'الشخص الذي يخص هذا التشغيل وحده يستطيع استئنافه.';

  @override
  String get wakeRecovery =>
      'أعاد الخادم تشغيل أثناء هذا التشغيل. استأنفه لمواصلته، أو تجاهله.';

  @override
  String limitParkTitle(String provider, String time) {
    return 'متوقف مؤقتًا عند حد الاستخدام لدى $provider، ويُعاد تعيينه في $time. ينتظر التشغيل الاستئناف لمدة تصل إلى 7 أيام بعد إعادة التعيين.';
  }

  @override
  String limitParkTitleUnnamed(String time) {
    return 'متوقف مؤقتًا عند حد الاستخدام لدى المزوّد، ويُعاد تعيينه في $time. ينتظر التشغيل الاستئناف لمدة تصل إلى 7 أيام بعد إعادة التعيين.';
  }

  @override
  String get limitParkResumeNow => 'الاستئناف الآن';

  @override
  String get limitParkCancel => 'إلغاء';

  @override
  String limitParkResumed(String provider) {
    return 'استُؤنف بعد حد استخدام $provider.';
  }

  @override
  String limitParkGone(String provider) {
    return 'لم يعد في انتظار حد استخدام $provider.';
  }

  @override
  String get limitParkProviderUnknown => 'المزوّد';

  @override
  String get mobileHeldMessages => 'رسائل محتجزة';

  @override
  String get heldSteeringTitle =>
      'محتجزة لأن التشغيل انتهى قبل أن يأخذها. أرسل رسائلك الآن أو أزلها.';

  @override
  String get heldSteeringRelease => 'إرسال الرسائل المحتجزة';

  @override
  String get notifGoalCompleted => 'تم الهدف';

  @override
  String get notifGoalFailed => 'فشل الهدف';

  @override
  String get notifGoalCancelled => 'أُلغي الهدف';

  @override
  String get notifGoalBudgetExhausted => 'استنفد الهدف ميزانيته';

  @override
  String get notifGoalNeedsReview => 'هدف ينتظر مراجعتك';

  @override
  String get notifGoalNeedsPerson => 'هدف يحتاج إليك';

  @override
  String get notifGoalOnHold => 'الهدف محتجز';

  @override
  String get notifWakeRuleEnded => 'انتهت جدولة';

  @override
  String notifWaitingDigest(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString شيء ينتظرك',
      many: '$countString شيئًا ينتظرك',
      few: '$countString أشياء تنتظرك',
      two: 'شيئان ينتظرانك',
      one: 'شيء واحد ينتظرك',
    );
    return '$_temp0';
  }

  @override
  String notifImprovementProposed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اقتُرح $countString تحسين',
      many: 'اقتُرح $countString تحسينًا',
      few: 'اقتُرحت $countString تحسينات',
      two: 'اقتُرح تحسينان',
      one: 'اقتُرح تحسين',
    );
    return '$_temp0';
  }

  @override
  String get notifPipelineRunHeld => 'تشغيل خط الأنابيب محتجز عند ميزانيته';

  @override
  String notifPipelineRunHeldBody(String spent, String cap) {
    return 'أُنفق $spent من $cap';
  }

  @override
  String get notifNeedsYou => 'يحتاج إليك';

  @override
  String get notifDigestGoalReview => 'هدف ينتظر المراجعة';

  @override
  String get notifDigestGoalPerson => 'هدف يحتاج إلى شخص';

  @override
  String get notifDigestHeldWake => 'إيقاظ محتجز';

  @override
  String get notifDigestImprovement => 'تحسين مقترح';

  @override
  String get wakeKindRulePaused => 'توقفت جدولته مؤقتًا.';

  @override
  String get wakeKindRuleBusy =>
      'كان الوكيل مشغولًا، والجدولة تتخطّى وقتًا كهذا.';

  @override
  String get wakeKindRuleFolded => 'حلّ مكانه حدث لاحق من المراقبة نفسها.';

  @override
  String get wakeKindRuleSuperseded => 'حلّ محلّه موعد لاحق من جدولته.';

  @override
  String get wakeKindRuleNotified =>
      'جدولته ترسل إشعارًا فقط، لذلك لم يبدأ أي تشغيل.';

  @override
  String get wakeKindRuleLimitParked =>
      'جدولته في انتظار إعادة ضبط حد استخدام المزوّد.';

  @override
  String get improvementRefusalCooldown =>
      'جرت مراجعة للتحسينات في هذه المحادثة قبل وقت قصير. حاول لاحقًا.';

  @override
  String get improvementRefusalQueued =>
      'مراجعة التحسينات لهذه المحادثة تنتظر التشغيل بالفعل.';

  @override
  String get improvementRefusalAgentNotFound =>
      'هذا الوكيل ليس وكيلًا في مساحة العمل هذه.';

  @override
  String get steeringRefusalHeldByLimit =>
      'لا يمكن إرسال الرسائل المحتجزة عند حد الاستخدام يدويًا. تنتظر أن يُستأنف التشغيل المتوقف.';

  @override
  String limitParkCancelled(String provider) {
    return 'أُلغي الانتظار عند حد استخدام $provider.';
  }

  @override
  String limitParkExpired(String provider) {
    return 'انتهت مهلة الانتظار عند حد استخدام $provider قبل أن يُستأنف التشغيل.';
  }

  @override
  String limitParkSkipped(String provider) {
    return 'لم يُستأنف التشغيل بعد حد استخدام $provider.';
  }

  @override
  String get heldSteeringLimitTitle =>
      'محتجز بينما ينتظر التشغيل إعادة تعيين حد الاستخدام. تُرسل عندما يستأنفه الشخص الذي يعمل التشغيل لصالحه.';

  @override
  String heldSteeringLimitAt(String time) {
    return 'محتجز حتى يُعاد تعيين حد الاستخدام في $time. تُرسل عندما يستأنفه الشخص الذي يعمل التشغيل لصالحه.';
  }

  @override
  String get heldSteeringOtherTitle => 'محتجزة لدى الخادم. يمكنك إزالتها.';

  @override
  String workRowWoke(int count, String agent) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أيقظ $agent لأجل $countString عنصر في الانتظار',
      many: 'أيقظ $agent لأجل $countString عنصرًا في الانتظار',
      few: 'أيقظ $agent لأجل $countString عناصر في الانتظار',
      two: 'أيقظ $agent لأجل عنصرين في الانتظار',
      one: 'أيقظ $agent',
    );
    return '$_temp0';
  }

  @override
  String workRowWakeMissed(String agent) {
    return 'فات إيقاظ لـ$agent أثناء توقف الخادم.';
  }

  @override
  String workRowWakeSkipped(String agent) {
    return 'لم يُسلَّم إيقاظ لـ$agent.';
  }

  @override
  String workRowScheduleCreated(String agent) {
    return 'تم ضبط جدولة لـ$agent.';
  }

  @override
  String workRowScheduleEnded(String agent) {
    return 'انتهت جدولة $agent.';
  }

  @override
  String workRowNoteFromAgent(String agent) {
    return 'ملاحظة الجدولة من $agent:';
  }

  @override
  String get workRowNoteFromPerson => 'ملاحظة جدولة من شخص:';

  @override
  String workRowCommandRefusedNamed(String command) {
    return 'رُفض الأمر $command.';
  }

  @override
  String get workRowCommandRefused => 'رُفض أمر.';

  @override
  String workRowCapRaised(String person, String from, String to) {
    return 'رفع $person حد الإنفاق لخط الأنابيب من $from إلى $to.';
  }

  @override
  String workRowCapRaisedNoAmounts(String person) {
    return 'رفع $person حد الإنفاق لخط الأنابيب.';
  }

  @override
  String get workRowApplyIncomplete =>
      'تعذّر إكمال تغيير مقبول على هذه المهارة، لأن المهارة تغيّرت في الأثناء. أُرجع الاقتراح.';

  @override
  String get workRowOpenSchedule => 'فتح الجدولة';

  @override
  String get heldSteeringOthersTitle =>
      'محتجزة لأن التشغيل انتهى قبل أن يأخذها. لا يستطيع إرسال رسالة إلا الشخص الذي كتبها.';

  @override
  String get heldSteeringOnlyYours =>
      'يُرسل رسائلك فقط. تبقى الرسائل الأخرى بانتظار من كتبها.';

  @override
  String heldSteeringWrittenBy(String name) {
    return 'كتبها $name';
  }

  @override
  String get steeringRefusalNotYours =>
      'لا يستطيع إرسال رسالة محتجزة إلا الشخص الذي كتبها، ولا شيء من هذه الرسائل يخصّك.';

  @override
  String get steeringRefusalNeedsWrite =>
      'تحتاج إلى صلاحية الكتابة في مستودعات هذه المساحة لتوجيه تشغيل يعمل لصالح شخص آخر.';

  @override
  String workRowSchedulePaused(String name, String agent) {
    return 'أوقف $name الجدولة الخاصة بـ$agent.';
  }

  @override
  String get goalVerdictObjective => 'الغاية ككل';

  @override
  String get notifDigestRequest => 'في انتظار ردك';
}
