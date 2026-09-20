// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'بازگشت';

  @override
  String get cancel => 'لغو';

  @override
  String get retry => 'تلاش مجدد';

  @override
  String get tryAgain => 'دوباره تلاش کنید';

  @override
  String get settings => 'تنظیمات';

  @override
  String get refresh => 'تازه‌سازی';

  @override
  String get approve => 'تأیید';

  @override
  String get deny => 'رد';

  @override
  String get continueLabel => 'ادامه';

  @override
  String get agentQuestionHeader => 'پرسش برای شما';

  @override
  String get agentQuestionAnsweredLabel => 'پاسخ‌داده‌شده';

  @override
  String get agentQuestionSkip => 'رد شدن';

  @override
  String get agentQuestionSkippedLabel => 'رد شد';

  @override
  String get agentQuestionFreeformHint => 'پاسختان را بنویسید…';

  @override
  String get agentApprovalRequired => 'تأیید لازم است';

  @override
  String get approveAndRemember => 'تأیید برای ۸ ساعت';

  @override
  String get decline => 'نپذیرفتن';

  @override
  String get confirm => 'تأیید';

  @override
  String get send => 'ارسال';

  @override
  String get close => 'بستن';

  @override
  String get expand => 'گستردن';

  @override
  String get zoomIn => 'بزرگ‌نمایی';

  @override
  String get zoomOut => 'کوچک‌نمایی';

  @override
  String get resetZoom => 'بازنشانی بزرگ‌نمایی';

  @override
  String get scanQrPrompt =>
      'کد ⁨QR⁩ را از ⁨Control Center⁩ اسکن کنید تا این تلفن جفت شود.';

  @override
  String get scanQrHelp =>
      'دوربین را باز کنید و به‌سمت کد ⁨QR⁩ نشان‌داده‌شده در ⁨Control Center⁩ بگیرید. این تلفن مستقیم از طریق یک پیوند خصوصی وصل می‌شود.';

  @override
  String get connectingToMac => 'در حال اتصال به ⁨Control Center⁩…';

  @override
  String get connectingDetail => 'در حال برقراری پیوند امن و مستقیم.';

  @override
  String get identityChangedTitle => 'هویت سرور تغییر کرد';

  @override
  String get identityChangedBody =>
      'این سرور دیگر با هویت ذخیره‌شده هنگام جفت‌سازی مطابقت ندارد. ممکن است سرور از نو نصب شده باشد — یا چیزی در حال رهگیری اتصال باشد. برای ایمنی، این دستگاه وصل نخواهد شد. جفت‌سازی را بردارید، سپس یک کد ⁨QR⁩ تازه از ⁨Control Center⁩ اسکن کنید تا دوباره جفت شود.';

  @override
  String get removePairing => 'برداشتن جفت‌سازی';

  @override
  String get couldntConnect => 'اتصال ممکن نشد';

  @override
  String get pendingPairingTitle => 'به این سرور وصل شوید؟';

  @override
  String get pendingPairingBody =>
      'یک پیوند از ⁨Control Center⁩ خواست با این سرور جفت شود. فقط اگر خودتان شروعش کرده‌اید ادامه دهید.';

  @override
  String get connect => 'اتصال';

  @override
  String get failureNotPaired =>
      'جفت نشده — کد ⁨QR⁩ را از ⁨Control Center⁩ اسکن کنید';

  @override
  String get failureUnreachable =>
      'از هیچ مسیری به سرور نرسیدیم — مطمئن شوید در حال اجراست، یا همان شبکه را امتحان کنید';

  @override
  String get failureIdentityChanged =>
      'هویت سرور تغییر کرد — اگر از نو نصب شده، این دستگاه را دوباره جفت کنید';

  @override
  String get failureAuthRejected =>
      'سرور این دستگاه را نپذیرفت — دوباره از ⁨Control Center⁩ جفتش کنید';

  @override
  String get failureUnknown => 'اتصال ممکن نشد — برای تلاش مجدد ضربه بزنید';

  @override
  String get statusConnected => 'متصل';

  @override
  String get statusConnecting => 'در حال اتصال';

  @override
  String get statusOffline => 'آفلاین';

  @override
  String get statusIdentityMismatch => 'عدم تطابق هویت';

  @override
  String get statusNotPaired => 'جفت‌نشده';

  @override
  String get statusConfirmPairing => 'تأیید جفت‌سازی';

  @override
  String get connectionFailed => 'اتصال ناموفق بود';

  @override
  String get identityMismatchBanner =>
      'هویت سرور تغییر کرد — اتصال متوقف شد. برای ادامه این دستگاه را دوباره جفت کنید.';

  @override
  String get tabInbox => 'صندوق ورودی';

  @override
  String get tabTickets => 'تیکت‌ها';

  @override
  String get tabChat => 'گفتگو';

  @override
  String get tabPrs => 'PRs';

  @override
  String get tabCalendar => 'تقویم';

  @override
  String get tabNews => 'اخبار';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label، $count در انتظار';
  }

  @override
  String get updateAvailable => 'Control Center جدید در دسترس است';

  @override
  String get appearance => 'ظاهر';

  @override
  String get language => 'زبان';

  @override
  String get device => 'دستگاه';

  @override
  String get themeSystem => 'سیستم';

  @override
  String get themeLight => 'روشن';

  @override
  String get themeDark => 'تاریک';

  @override
  String get languageSystem => 'سیستم';

  @override
  String get disconnectTapAgain =>
      'دوباره ضربه بزنید تا این دستگاه از ⁨Control Center⁩ قطع شود';

  @override
  String get disconnectDevice => 'قطع اتصال این دستگاه';

  @override
  String get disconnect => 'قطع اتصال';

  @override
  String get chooseWorkspace => 'انتخاب فضای کاری';

  @override
  String get workspaces => 'فضاهای کاری';

  @override
  String get workspacesLoadFailed => 'بارگذاری فضاهای کاری ممکن نشد';

  @override
  String get noWorkspacesYet => 'هنوز فضای کاری نیست';

  @override
  String selectWorkspace(String name) {
    return 'انتخاب $name';
  }

  @override
  String get inboxLoadFailed => 'بارگذاری صندوق ورودی ممکن نشد';

  @override
  String get allCaughtUp => 'همه را دیده‌اید';

  @override
  String get inboxNoForgeAccount =>
      'هیچ حساب میزبانی کدی روی سرور وصل نیست، بنابراین هنوز نمی‌توان pull requestها را به شما نسبت داد.';

  @override
  String get inboxNothingWaiting =>
      'چیزی مسدود نیست و هیچ pull requestی منتظر شما نیست.';

  @override
  String get blocked => 'مسدود';

  @override
  String get sectionNeedsYourReview => 'نیاز به بازبینی شما';

  @override
  String get sectionReturnedToYou => 'بازگشته به شما';

  @override
  String get sectionApprovedAndReady => 'تأییدشده و آماده';

  @override
  String get sectionYourDrafts => 'پیش‌نویس‌های شما';

  @override
  String get sectionWaitingForReviewers => 'در انتظار بازبین‌ها';

  @override
  String get sectionMergingAndMerged => 'در حال ادغام و اخیراً ادغام‌شده';

  @override
  String get sectionWaitingForAuthor => 'در انتظار نویسنده';

  @override
  String waitingAgo(String ago) {
    return 'در انتظار $ago';
  }

  @override
  String get openConversation => 'باز کردن گفتگو';

  @override
  String get calendarLoadFailed => 'بارگذاری تقویم ممکن نشد';

  @override
  String get nothingScheduled => 'چیزی زمان‌بندی نشده';

  @override
  String get calendarEmptyDescription =>
      'رویدادهای تقویم‌های وصل‌شده اینجا ظاهر می‌شوند.';

  @override
  String get agenda => 'برنامه';

  @override
  String get syncCalendarsNow => 'همگام‌سازی تقویم‌ها اکنون';

  @override
  String get event => 'رویداد';

  @override
  String get eventNotFound => 'رویداد پیدا نشد';

  @override
  String get eventNotFoundDescription =>
      'ممکن است بیرون از بازهٔ برنامه باشد، یا در مبدأ حذف شده باشد.';

  @override
  String get joinMeeting => 'پیوستن به جلسه';

  @override
  String get join => 'پیوستن';

  @override
  String attendeesCount(int count) {
    return 'شرکت‌کنندگان ($count)';
  }

  @override
  String get details => 'جزئیات';

  @override
  String get allDay => 'تمام روز';

  @override
  String get happeningNow => 'در حال برگزاری';

  @override
  String inDuration(String duration) {
    return 'تا $duration دیگر';
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
  String get attendeeAccepted => 'پذیرفته';

  @override
  String get attendeeDeclined => 'نپذیرفته';

  @override
  String get attendeeMaybe => 'شاید';

  @override
  String get attendeeNoReply => 'بدون پاسخ';

  @override
  String get organizer => 'برگزارکننده';

  @override
  String get calendarNoAccounts =>
      'هیچ تقویمی برای این فضای کاری وصل نیست. یکی را از برنامهٔ دسکتاپ وصل کنید — ورود، توکن را روی سرور ذخیره می‌کند.';

  @override
  String get calendarReauthNeeded =>
      'یک حساب تقویم باید دوباره وصل شود — آنچه پایین می‌بینید ممکن است قدیمی باشد. از برنامهٔ دسکتاپ دوباره وصلش کنید.';

  @override
  String get spacesLoadFailed => 'بارگذاری فضاها ممکن نشد';

  @override
  String get noSpaces => 'فضایی نیست';

  @override
  String get spacesEmptyDescription =>
      'فضاهای این فضای کاری اینجا ظاهر می‌شوند.';

  @override
  String get thread => 'رشته';

  @override
  String get agentWorking => 'عامل در حال کار است';

  @override
  String get messagesLoadFailed => 'بارگذاری پیام‌ها ممکن نشد';

  @override
  String get noMessagesYet => 'هنوز پیامی نیست';

  @override
  String get noMessagesDescription => 'پیامی بفرستید تا گفتگو شروع شود.';

  @override
  String get agentResponding => 'عامل در حال پاسخ';

  @override
  String get agentFinished => 'عامل تمام کرد';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁨$names⁩ برای ارسال از اینجا خیلی بزرگ هستند.',
      one: '⁨$names⁩ برای ارسال از اینجا خیلی بزرگ است.',
    );
    return '$_temp0';
  }

  @override
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁨$names⁩ برای ارسال از اینجا روی رله خیلی بزرگ هستند.',
      one: '⁨$names⁩ برای ارسال از اینجا روی رله خیلی بزرگ است.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed =>
      'بارگذاری پیوست ممکن نشد. دوباره تلاش کنید.';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count پیوست بارگذاری نشد و کنار گذاشته شد.',
      one: '1 پیوست بارگذاری نشد و کنار گذاشته شد.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'هم‌تیمی';

  @override
  String get agent => 'عامل';

  @override
  String get attachFile => 'پیوست کردن فایل';

  @override
  String get messageHint => 'پیام';

  @override
  String removeAttachment(String name) {
    return 'برداشتن ⁨$name⁩';
  }

  @override
  String get articlesLoadFailed => 'بارگذاری مقاله‌ها ممکن نشد';

  @override
  String get noArticles => 'مقاله‌ای نیست';

  @override
  String get articlesEmptyDescription =>
      'مقاله‌های تازه با به‌روزرسانی خوراک‌ها اینجا ظاهر می‌شوند.';

  @override
  String get unread => 'خوانده‌نشده';

  @override
  String get allFeeds => 'همهٔ خوراک‌ها';

  @override
  String get save => 'ذخیره';

  @override
  String get unsave => 'لغو ذخیره';

  @override
  String get readFullArticle => 'خواندن مقالهٔ کامل';

  @override
  String get ticketsLoadFailed => 'بارگذاری تیکت‌ها ممکن نشد';

  @override
  String get noTickets => 'تیکتی نیست';

  @override
  String get ticketsEmptyDescription =>
      'تیکت‌های این فضای کاری اینجا ظاهر می‌شوند.';

  @override
  String get all => 'همه';

  @override
  String get ticket => 'تیکت';

  @override
  String get ticketLoadFailed => 'بارگذاری تیکت ممکن نشد';

  @override
  String assignedTo(String name) {
    return 'تخصیص به $name';
  }

  @override
  String get openInBrowser => 'باز کردن در مرورگر';

  @override
  String get status => 'وضعیت';

  @override
  String get assign => 'تخصیص';

  @override
  String get reassign => 'تخصیص دوباره';

  @override
  String get noAgents => 'عاملی نیست';

  @override
  String get noAgentsDescription => 'عاملی از این فضای کاری تخصیص دهید.';

  @override
  String get statusOpen => 'برای انجام';

  @override
  String get statusInProgress => 'در جریان';

  @override
  String get statusBlocked => 'مسدود';

  @override
  String get statusInReview => 'در بازبینی';

  @override
  String get statusDone => 'انجام‌شده';

  @override
  String get statusBacklog => 'بک‌لاگ';

  @override
  String get lensNeedsMe => 'نیاز به من';

  @override
  String get lensMine => 'مال من';

  @override
  String get prsLoadFailed => 'بارگذاری pull requestها ممکن نشد';

  @override
  String get noOpenPullRequests => 'هیچ pull request بازی نیست';

  @override
  String get nothingWaitingOnReview => 'چیزی منتظر بازبینی شما نیست';

  @override
  String get noOwnOpenPullRequests => 'هیچ pull request بازی ندارید';

  @override
  String get nothingBlocked => 'چیزی مسدود نیست';

  @override
  String get prsEmptyDescription =>
      'pull requestهای مخزن‌های این فضای کاری اینجا ظاهر می‌شوند.';

  @override
  String get refreshPullRequests => 'تازه‌سازی pull requestها';

  @override
  String get noForgeConnected =>
      'هیچ میزبانی کدی روی سرور وصل نیست، بنابراین نمی‌توان pull requestها را گرفت. یکی را از برنامهٔ دسکتاپ وصل کنید.';

  @override
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'خواندن $count مخزن ممکن نشد.',
      one: 'خواندن 1 مخزن ممکن نشد.',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return 'خوانده نشد: ⁨$names⁩';
  }

  @override
  String get installationSuspendedTitle => 'نصب GitHub App معلق شده است';

  @override
  String installationSuspendedBody(String names) {
    return 'آخرین داده‌های شناخته‌شده برای ⁨$names⁩ نمایش داده می‌شود. نصب را در GitHub از سر بگیرید یا توکنی با دسترسی وصل کنید.';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'نصب GitHub App معلق شده است. آخرین داده‌های شناخته‌شده برای ⁨$names⁩ نمایش داده می‌شود. نصب را در GitHub از سر بگیرید یا توکنی با دسترسی وصل کنید.';
  }

  @override
  String get draft => 'پیش‌نویس';

  @override
  String get merged => 'ادغام‌شده';

  @override
  String get closed => 'بسته';

  @override
  String get open => 'باز';

  @override
  String get approved => 'تأییدشده';

  @override
  String get changesRequested => 'درخواست تغییرات';

  @override
  String get reviewRequired => 'نیاز به بازبینی';

  @override
  String get checksPassing => 'بررسی‌ها موفق';

  @override
  String get checksFailing => 'بررسی‌ها ناموفق';

  @override
  String get checksRunning => 'بررسی‌ها در حال اجرا';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title، $status';
  }

  @override
  String get pullRequest => 'Pull request';

  @override
  String get prLoadFailed => 'بارگذاری این pull request ممکن نشد';

  @override
  String get openOnForge => 'باز کردن در میزبانی کد';

  @override
  String get requestChangesNeedsComment =>
      'نظری بنویسید که توضیح دهد چه چیزی باید تغییر کند.';

  @override
  String get conversation => 'گفتگو';

  @override
  String get files => 'فایل‌ها';

  @override
  String get checks => 'بررسی‌ها';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فایل',
      one: '1 فایل',
    );
    return '$_temp0';
  }

  @override
  String commitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کامیت',
      one: '1 کامیت',
    );
    return '$_temp0';
  }

  @override
  String get conflicts => 'تعارض‌ها';

  @override
  String get reviewers => 'بازبین‌ها';

  @override
  String get noDescriptionNoComments => 'هنوز توضیح و نظری نیست.';

  @override
  String get noChangedFiles => 'فایل تغییریافته‌ای نیست.';

  @override
  String get noChecksReported => 'برای کامیت ⁨head⁩ هیچ بررسی‌ای گزارش نشده.';

  @override
  String get reviewCommentHint => 'نظر بازبینی بنویسید…';

  @override
  String get comment => 'نظر';

  @override
  String get commentPosted => 'نظر ثبت شد';

  @override
  String get request => 'درخواست';

  @override
  String get squashAndMerge => 'اسکواش و ادغام';

  @override
  String noActionsAvailable(String status) {
    return '$status — اقدامی در دسترس نیست.';
  }

  @override
  String get reviewApproved => 'تأیید کرد';

  @override
  String get reviewRequestedChanges => 'درخواست تغییرات کرد';

  @override
  String get reviewCommented => 'بازبینی کرد';

  @override
  String get reviewPending => 'در انتظار';

  @override
  String get unknownAuthor => 'ناشناخته';

  @override
  String hideDiffFor(String file) {
    return 'پنهان کردن دیف ⁨$file⁩';
  }

  @override
  String showDiffFor(String file) {
    return 'نمایش دیف ⁨$file⁩';
  }

  @override
  String get checkRunning => 'در حال اجرا';

  @override
  String get checkPassed => 'موفق';

  @override
  String get checkFailed => 'ناموفق';

  @override
  String get checkCancelled => 'لغوشده';

  @override
  String get checkSkipped => 'ردشده';

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
      'برای این فایل دیف متنی نیست — باینری است، یا برای میزبانی کد خیلی بزرگ است که برگرداند.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'نمایش $count خط باقی‌مانده',
      one: 'نمایش خط باقی‌مانده',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count خط بدون تغییر',
      one: '1 خط بدون تغییر',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'پرش به آخرین';

  @override
  String get streaming => 'در حال استریم';

  @override
  String get working => 'در حال کار';

  @override
  String get input => 'ورودی';

  @override
  String get output => 'خروجی';

  @override
  String get now => 'الان';

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
    return '$count ر';
  }

  @override
  String get today => 'امروز';

  @override
  String get tomorrow => 'فردا';

  @override
  String get yesterday => 'دیروز';

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
