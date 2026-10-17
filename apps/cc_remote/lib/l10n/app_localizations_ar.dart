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
  String get permissionPrPublish => 'نشر طلبات سحب';

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
  String get permissionRemembered => 'موافقة محفوظة';

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
  String get permissionRevokeBeforeEdit =>
      'ألغِ القاعدة الخاصة بالنطاق أو المحفوظة قبل تحديد قاعدة عامة لهذا الإجراء.';

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
  String get mobileGoalGoal => 'الهدف';

  @override
  String get mobileGoalLoop => 'دورة التكرار';

  @override
  String mobileGoalKind(String kind) {
    return 'النوع: $kind';
  }

  @override
  String mobileGoalRuns(String count) {
    return '$count عمليات تشغيل';
  }

  @override
  String get mobileGoalNoRunLimit => 'بلا حد';

  @override
  String mobileGoalProgress(
    String runs,
    String maxRuns,
    String spent,
    String cap,
  ) {
    return 'عمليات التشغيل: $runs / $maxRuns · المصروف: $spent / $cap';
  }

  @override
  String mobileGoalDeadline(String date) {
    return 'الموعد النهائي: $date';
  }

  @override
  String mobileGoalFailures(String count) {
    return 'عمليات التشغيل الفاشلة المتتالية: $count';
  }

  @override
  String get mobileGoalSummary => 'ملخص الإنجاز';

  @override
  String get mobileGoalFailedDescription =>
      'توقف المشرف بعد تكرار فشل التشغيل. راجع المحادثة للاطلاع على التفاصيل.';

  @override
  String get mobileGoalBudgetWall =>
      'بلغ الموعد النهائي أو حد التشغيل. لا يمكن استئناف هذا الهدف برفع سقف التكلفة.';

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
  String get activityTicket => 'تحديث التذكرة';

  @override
  String get activityMeeting => 'تحديث الاجتماع';

  @override
  String get activityCalendar => 'اتصال التقويم';

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
  String get credentialsRedirectUnavailable =>
      'لا يمكن الوصول بأمان إلى عنوان رجوع المتصفح لهذا الخادم من الهاتف. اطلب من مالك الخادم إعداد عنوان رجوع عام عبر HTTPS، أو أضف رمز وصول بدلًا من ذلك.';

  @override
  String get credentialsUpdateToken => 'تحديث رمز الوصول';

  @override
  String get credentialsAddToken => 'إضافة رمز وصول';

  @override
  String get credentialsPersonalToken => 'رمز وصول شخصي';

  @override
  String get credentialsPersonalTokenHint => 'الصق رمز وصول شخصيًا';

  @override
  String get credentialsHostManaged =>
      'يأتي هذا الاتصال من تطبيق الخادم أو بيئته. لا يستطيع تغييره هناك سوى مالك الخادم؛ لكن يمكنك إضافة رمز الوصول الخاص بك.';

  @override
  String get credentialsStopWatching => 'إيقاف المتابعة';
}
