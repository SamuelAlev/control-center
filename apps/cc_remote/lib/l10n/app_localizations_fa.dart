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
  String get copyCommand => 'رونوشت فرمان';

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
  String get newSpaceFolder => 'پوشهٔ جدید';

  @override
  String get folderName => 'نام پوشه';

  @override
  String get renameSpaceFolder => 'تغییر نام پوشه';

  @override
  String get deleteSpaceFolder => 'حذف پوشه';

  @override
  String get moveSpaceToFolder => 'انتقال فضا به پوشه';

  @override
  String get removeSpaceFromFolder => 'برداشتن فضا از پوشه';

  @override
  String get spaceFolderActions => 'کنش‌های پوشه';

  @override
  String get deleteFolderWithSpacesWarning =>
      'حذف دائمی فضاها، پیام‌ها و پوشه‌های کاری آن‌ها را برای همه پاک می‌کند. این کار بازگشت‌پذیر نیست.';

  @override
  String get deleteSpacesInFolder => 'حذف دائمی فضاهای این پوشه';

  @override
  String get deleteFolderAndSpaces => 'حذف پوشه و فضاها';

  @override
  String get keepSpacesInFolder =>
      'در غیر این صورت، فضاها خارج از پوشه باقی می‌مانند.';

  @override
  String get create => 'ایجاد';

  @override
  String get otherSpaces => 'فضاهای دیگر';

  @override
  String get folderUpdateFailed => 'به‌روزرسانی پوشه‌ها ممکن نشد';

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

  @override
  String get mobileConversations => 'گفتگوها';

  @override
  String get mobileNewConversation => 'گفتگوی جدید';

  @override
  String get mobileConversationName => 'نام گفتگو';

  @override
  String get mobileRename => 'تغییر نام';

  @override
  String get mobileManageSpace => 'مدیریت فضا';

  @override
  String get mobileArchived => 'بایگانی‌شده';

  @override
  String get mobileSearchMessages => 'جستجو در همهٔ پیام‌های این فضا';

  @override
  String get mobileSearch => 'جستجو';

  @override
  String get mobileNoResults => 'نتیجه‌ای یافت نشد';

  @override
  String get mobileReopen => 'بازگشایی';

  @override
  String get mobileArchive => 'بایگانی';

  @override
  String get mobileProgress => 'پیشرفت و زمینه';

  @override
  String get mobileReadFailed =>
      'نشان‌گذاری این گفتگو به‌عنوان خوانده‌شده ممکن نبود';

  @override
  String get mobileSendFailed => 'پیام ارسال نشد. پیش‌نویس شما همچنان اینجاست.';

  @override
  String get sentAttachmentUnavailable => 'پیوست در دسترس نیست';

  @override
  String get sentAttachmentLoadFailed => 'بارگذاری پیوست ممکن نشد';

  @override
  String get mobileActionFailed => 'کنش ناموفق بود';

  @override
  String get mobileRemove => 'برداشتن';

  @override
  String get mobileLinkedMessage => 'پیام پیوندشده';

  @override
  String get mobileOlderMessages => 'پیام‌های قدیمی‌تر';

  @override
  String get mobileMessageActions => 'کنش‌های پیام';

  @override
  String get mobileOpenThread => 'باز کردن رشته';

  @override
  String get mobileCopyLink => 'کپی پیوند';

  @override
  String get mobileStopRun => 'توقف اجرا';

  @override
  String get mobileStopRunConfirm =>
      'اجرای این عامل متوقف شود؟ کارهای انجام‌شده حفظ می‌شوند.';

  @override
  String get mobileControlUnsupported =>
      'این اجرا پایان یافته یا از این کنترل پشتیبانی نمی‌کند.';

  @override
  String get mobilePauseRequested => 'درخواست مکث در مرز نوبت بعدی ثبت شد';

  @override
  String get mobileResumed => 'اجرا از سر گرفته شد';

  @override
  String get mobileStopRequested => 'درخواست توقف ثبت شد';

  @override
  String get mobileQueuedMessages => 'پیام‌های در صف';

  @override
  String get mobilePauseRun => 'مکث در نوبت بعدی';

  @override
  String get mobileResumeRun => 'ازسرگیری';

  @override
  String get mobileEditQueued => 'ویرایش پیام در صف';

  @override
  String get mobileSteerNow => 'هدایت همین حالا';

  @override
  String get mobileMoveUp => 'حرکت به بالا';

  @override
  String get mobileMoveDown => 'حرکت به پایین';

  @override
  String get mobileQueueChanged =>
      'صف تغییر کرده یا این اجرا هدایت هم‌زمان را نمی‌پذیرد. صفحه را تازه‌سازی کنید و دوباره تلاش کنید.';

  @override
  String get mobileActivity => 'فعالیت';

  @override
  String get mobilePermissions => 'مجوزها و حسابرسی';

  @override
  String get mobilePlans => 'برنامه‌ها';

  @override
  String get mobileGoals => 'هدف‌های تحت نظارت';

  @override
  String get mobileCredentials => 'اتصال‌ها و اعتبارنامه‌ها';

  @override
  String get mobileWorkspaceUnavailable =>
      'این فضای کاری در دسترس نیست یا دیگر به آن دسترسی ندارید.';

  @override
  String get mobilePrReviewThreads => 'رشته‌های بازبینی';

  @override
  String get mobilePrThreadsLoadFailed => 'بارگیری رشته‌های بازبینی ممکن نبود';

  @override
  String get mobilePrNoReviewThreads =>
      'هنوز رشتهٔ بازبینی درون‌خطی وجود ندارد';

  @override
  String get mobilePrCommentPermissionDenied =>
      'اجازهٔ ثبت نظر در این مخزن را ندارید.';

  @override
  String get mobilePrPermissionChecking => 'در حال بررسی مجوزهای ثبت نظر…';

  @override
  String get mobilePrPermissionLoadFailed =>
      'بررسی مجوزهای ثبت نظر ممکن نبود. برای ثبت نظر دوباره تلاش کنید.';

  @override
  String mobilePrThreadLine(String side, String line) {
    return 'خط $line در $side';
  }

  @override
  String get mobilePrOriginalSide => 'اصلی';

  @override
  String get mobilePrSelectCommentLine => 'خطی را برای نظر دادن انتخاب کنید';

  @override
  String get mobilePrUpdatedSide => 'به‌روزرسانی‌شده';

  @override
  String get mobilePrThreadResolved => 'حل‌شده';

  @override
  String get mobilePrReplyHint => 'پاسخی بنویسید…';

  @override
  String get mobilePrCommentRequired => 'پیش از انتشار، نظری بنویسید.';

  @override
  String get mobilePrReply => 'پاسخ دادن';

  @override
  String get mobilePrReopenThread => 'بازگشایی رشته';

  @override
  String get mobilePrResolveThread => 'حل رشته';

  @override
  String get mobilePrResolvePermissionDenied =>
      'فقط نویسندهٔ Pull request یا فردی با دسترسی نوشتن می‌تواند این رشته را حل کند.';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return 'ثبت نظر روی خط $line در $side';
  }

  @override
  String get mobilePrInlineCommentHint => 'نظر درون‌خطی بنویسید…';

  @override
  String get mobilePrPostInlineComment => 'انتشار نظر';

  @override
  String get mobilePrCommentUnavailable =>
      'نظرهای درون‌خطی برای این Pull request در دسترس نیستند.';

  @override
  String get mobilePrPatchUnavailable =>
      'سرویس میزبانی کد وصلهٔ متنی این فایل را ارائه نکرد.';

  @override
  String get mobilePrNoPatchForFile => 'وصلهٔ این فایل در دسترس نیست.';

  @override
  String get mobileTicketNew => 'تیکت جدید';

  @override
  String get mobileTicketCreate => 'ایجاد تیکت';

  @override
  String get mobileTicketEdit => 'ویرایش تیکت';

  @override
  String get mobileTicketTitle => 'عنوان';

  @override
  String get mobileTicketTitleRequired =>
      'برای ذخیرهٔ این تیکت، عنوانی وارد کنید.';

  @override
  String get mobileTicketDescription => 'شرح';

  @override
  String get mobileTicketMarkdownHint => 'جزئیات را با Markdown بنویسید';

  @override
  String get mobileTicketPriority => 'اولویت';

  @override
  String get mobileTicketPriorityNone => 'بدون اولویت';

  @override
  String get mobileTicketPriorityUrgent => 'فوری';

  @override
  String get mobileTicketPriorityHigh => 'بالا';

  @override
  String get mobileTicketPriorityMedium => 'متوسط';

  @override
  String get mobileTicketPriorityLow => 'پایین';

  @override
  String get mobileTicketLabels => 'برچسب‌ها';

  @override
  String get mobileTicketLabelsHint => 'هر برچسب در یک خط';

  @override
  String get mobileTicketLabelsHelp => 'هر برچسب را در خطی جداگانه وارد کنید.';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return 'ثبت‌شده در $provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => 'بدون تخصیص';

  @override
  String get mobileTicketAssignedFilter => 'تخصیص‌یافته';

  @override
  String get mobileTicketAgentsLoadFailed => 'بارگیری عامل‌ها ممکن نبود';

  @override
  String get mobileTicketSearch => 'جستجوی تیکت‌ها';

  @override
  String get mobileTicketSearchHint => 'عنوان، کلید، شرح، برچسب یا فرد مسئول';

  @override
  String get mobileTicketClearSearch => 'پاک کردن جستجوی تیکت‌ها';

  @override
  String get mobileTicketNoMatches => 'تیکت مطابقی یافت نشد';

  @override
  String get mobileTicketAdjustFilters =>
      'جستجوی دیگری انجام دهید یا فیلترها را تغییر دهید.';

  @override
  String get mobileTicketClearFilters => 'پاک کردن فیلترها';

  @override
  String get mobileTicketNotFound => 'تیکت یافت نشد';

  @override
  String get mobileTicketNotFoundDescription =>
      'این تیکت شاید حذف شده یا از این فضای کاری منتقل شده باشد.';

  @override
  String get mobileTicketWorkspaceChanged =>
      'فضای کاری تغییر کرده است. پیش از ذخیره، به فضای کاری فعلی برگردید.';

  @override
  String get mobileTicketOpenLinkedSpace => 'باز کردن فضای پیوندشده';

  @override
  String get mobileTicketReadOnly =>
      'برای تغییر تیکت‌ها باید عضو فضای کاری باشید.';

  @override
  String get permissionTitle => 'مجوزها';

  @override
  String get permissionWorkspaceFailed => 'بارگیری فضای کاری ممکن نبود';

  @override
  String get permissionNoWorkspace =>
      'برای بررسی مجوزها یک فضای کاری انتخاب کنید.';

  @override
  String get permissionLoading => 'در حال بارگیری مجوزها…';

  @override
  String get permissionScopeDescription =>
      'نحوهٔ تصمیم‌گیری برای هر کنش را در این محدوده ببینید. عامل‌ها و فضاها می‌توانند قواعد فضای کاری را به ارث ببرند.';

  @override
  String get permissionScope => 'محدودهٔ سیاست';

  @override
  String get permissionWorkspaceScope => 'فضای کاری';

  @override
  String get permissionAgentScope => 'عامل';

  @override
  String get permissionSpaceScope => 'فضا';

  @override
  String get permissionAgentContext => 'عامل فعال در این فضا';

  @override
  String get permissionNoAgentContext => 'عاملی انتخاب نشده است';

  @override
  String get permissionTargetsFailed => 'بارگیری هدف‌های محدوده ممکن نبود';

  @override
  String get permissionNoTargets => 'در این محدوده هدفی در دسترس نیست.';

  @override
  String get permissionRoleFailed => 'تأیید نقش شما در فضای کاری ممکن نبود';

  @override
  String get permissionMemberRequired =>
      'برای دیدن قواعد سیاست باید عضو فضای کاری باشید.';

  @override
  String get permissionRulesFailed => 'بارگیری قواعد سیاست ممکن نبود';

  @override
  String get permissionAuditAdminOnly =>
      'تاریخچهٔ مجوزدهی فقط برای مدیران فضای کاری در دسترس است.';

  @override
  String get permissionAllow => 'اجازه';

  @override
  String get permissionAsk => 'ابتدا بپرس';

  @override
  String get permissionDeny => 'رد';

  @override
  String get permissionFileDelete => 'حذف فایل‌ها';

  @override
  String get permissionFileWriteOutsideWorktree => 'نوشتن خارج از درخت کاری';

  @override
  String get permissionGitCommit => 'ثبت تغییرات';

  @override
  String get permissionGitPush => 'ارسال commitها';

  @override
  String get permissionPrCreate => 'ایجاد Pull request';

  @override
  String get permissionPrPublish => 'انتشار Pull request';

  @override
  String get permissionVendorSyncWrite => 'نوشتن در همگام‌سازی ارائه‌دهنده';

  @override
  String get permissionNetworkEgress => 'دسترسی به شبکه';

  @override
  String get permissionSecretAccess => 'دسترسی به اطلاعات محرمانه';

  @override
  String get permissionPackageInstall => 'نصب بسته‌ها';

  @override
  String get permissionProcessSpawn => 'ایجاد فرایندها';

  @override
  String get permissionWorkspaceMutation => 'تغییر فضای کاری';

  @override
  String get permissionEnclosureControl => 'کنترل محیط محصور';

  @override
  String get permissionChangeFailed => 'تغییر قاعده ممکن نبود';

  @override
  String get permissionEffectiveDescription =>
      'قاعدهٔ مؤثر در این محدوده بدون آرگومان کنش. مجوزهای مشروط زیر فقط برای درخواست‌های مطابق اعمال می‌شوند؛ تصمیم نهایی را سرور می‌گیرد.';

  @override
  String get permissionSpaceAgentNote =>
      'عاملی انتخاب نشده است. تا زمانی که یکی را در بالا انتخاب نکنید، قواعد مختص عامل نمایش داده نمی‌شوند.';

  @override
  String get permissionScopedGrants => 'قواعد این محدوده';

  @override
  String get permissionModePreset => 'پیش‌تنظیم حالت';

  @override
  String get permissionBuiltInDefault => 'پیش‌فرض داخلی';

  @override
  String get permissionRemembered => 'تأیید ذخیره‌شده';

  @override
  String get permissionSource => 'منبع';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · تنظیم‌شده در اینجا';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · به‌ارث‌رسیده';
  }

  @override
  String permissionExpiresAt(String date) {
    return 'انقضا: $date';
  }

  @override
  String get permissionSetHere => 'تنظیم قاعده در اینجا';

  @override
  String get permissionRevokeBeforeEdit =>
      'پیش از تعیین قاعدهٔ عمومی برای این کنش، قاعدهٔ محدود یا ذخیره‌شده را لغو کنید.';

  @override
  String get permissionConfirmRevoke => 'تأیید لغو';

  @override
  String get permissionRevokeRule => 'لغو قاعده';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'پیشوند فرمان: $prefix';
  }

  @override
  String get permissionNoExpiry => 'بدون انقضا';

  @override
  String get permissionExpired => 'منقضی';

  @override
  String get permissionExplicitRule => 'قاعدهٔ صریح';

  @override
  String get permissionEnforcementAdvisory =>
      'راهنمایی: قواعد «ابتدا بپرس» بدون درخواست تأیید ثبت می‌شوند';

  @override
  String get permissionEnforcementSoft =>
      'اجرای نرم: عبور از قاعده به مجوز نیاز دارد';

  @override
  String get permissionEnforcementHard => 'اجرای سخت: قابل عبور نیست';

  @override
  String permissionPaths(String paths) {
    return 'مسیرها: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'ارجاع‌های Git: $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return 'میزبان‌ها: $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return 'فرمان‌ها: $commands';
  }

  @override
  String permissionMaxCount(String count) {
    return 'حداکثر تعداد: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return 'حداکثر سنت: $cents';
  }

  @override
  String get permissionAuditHeading => 'تاریخچهٔ مجوزدهی';

  @override
  String get permissionAuditDescription =>
      'تصمیم‌های اخیر ثبت‌شده در سرور. فقط مدیران می‌توانند گزارش را بررسی یا زنجیرهٔ هش آن را تأیید کنند.';

  @override
  String permissionOnBehalfOf(String user) {
    return 'از طرف $user';
  }

  @override
  String get permissionPrompted => 'تأیید انسانی درخواست شد';

  @override
  String get permissionVerifyChain => 'تأیید زنجیرهٔ حسابرسی';

  @override
  String get permissionVerifyFailed => 'تأیید زنجیرهٔ حسابرسی ممکن نبود';

  @override
  String permissionChainIntact(String count) {
    return 'زنجیره سالم است · $count ورودی بررسی شد';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'زنجیره در ورودی $sequence گسسته است: $reason';
  }

  @override
  String get permissionAuditEmpty =>
      'هنوز تصمیمی دربارهٔ مجوزدهی ثبت نشده است.';

  @override
  String get permissionAuditFailed => 'بارگیری تاریخچهٔ مجوزدهی ممکن نبود';

  @override
  String get mobilePlansLoadFailed => 'بارگیری برنامه‌ها ممکن نبود';

  @override
  String get mobilePlansEmpty => 'هنوز برنامه‌ای نیست';

  @override
  String get mobilePlansEmptyDescription =>
      'برنامه‌های ارسال‌شده توسط عامل‌ها برای بازبینی اینجا نمایش داده می‌شوند.';

  @override
  String get mobilePlanTitle => 'برنامه';

  @override
  String get mobilePlanMissing =>
      'این برنامه دیگر در این فضای کاری در دسترس نیست.';

  @override
  String mobilePlanStepCount(int count) {
    return '$count گام';
  }

  @override
  String get mobilePlanDraft => 'پیش‌نویس';

  @override
  String get mobilePlanProposed => 'در انتظار بازبینی';

  @override
  String get mobilePlanApproved => 'تأییدشده';

  @override
  String get mobilePlanRejected => 'ردشده';

  @override
  String get mobilePlanSuperseded => 'منسوخ';

  @override
  String get mobilePlanExecuting => 'در حال اجرا';

  @override
  String get mobilePlanSynthesizing => 'در حال ترکیب';

  @override
  String get mobilePlanCompleted => 'کامل‌شده';

  @override
  String get mobilePlanFailed => 'ناموفق';

  @override
  String get mobilePlanCancelled => 'لغوشده';

  @override
  String mobilePlanRevision(String revision) {
    return 'بازبینی $revision';
  }

  @override
  String get mobilePlanSteps => 'گام‌ها';

  @override
  String get mobilePlanNoSteps => 'برای این برنامه گامی ارسال نشده است.';

  @override
  String get mobilePlanAssumptions => 'شفاف‌سازی‌ها';

  @override
  String mobilePlanDependsOn(String keys) {
    return 'وابسته به $keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return 'هزینهٔ تخمینی تا $cost';
  }

  @override
  String get mobilePlanSelect => 'انتخاب';

  @override
  String get mobilePlanSelected => 'انتخاب‌شده';

  @override
  String get mobilePlanEstimate => 'برآورد هزینه';

  @override
  String get mobilePlanEstimateRequired =>
      'پیش از تأیید اجرا، هزینهٔ برنامه را برآورد کنید.';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return 'هزینهٔ تخمینی: $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => 'در دسترس نیست';

  @override
  String get mobilePlanNoHardCap => 'بدون سقف قطعی';

  @override
  String get mobilePlanExceedsBudget =>
      'برآورد از بودجهٔ تعیین‌شده فراتر است. پیش از تأیید آن را بررسی کنید.';

  @override
  String get mobilePlanPartialEstimate =>
      'این برآورد برای کل برنامه است؛ گام‌های انتخاب‌شده ممکن است هزینهٔ کمتری داشته باشند.';

  @override
  String get mobilePlanConfirmAll => 'کل برنامه شروع شود؟';

  @override
  String get mobilePlanConfirmSelected => 'گام‌های انتخاب‌شده شروع شوند؟';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return 'تأیید، اجرا را آغاز می‌کند و ممکن است هزینه داشته باشد. سقف برآورد هزینه: $cost. سقف بودجه: $cap.';
  }

  @override
  String get mobilePlanApproveAll => 'تأیید همه و اجرا';

  @override
  String get mobilePlanApproveSelected => 'تأیید انتخاب‌شده‌ها و اجرا';

  @override
  String get mobilePlanWiden => 'تأیید گام‌های بیشتر';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return '$count گام دیگر برای اجرا آزاد شوند؟ ممکن است هزینه داشته باشند. سقف هزینهٔ اجرای فعلی: $cap.';
  }

  @override
  String get mobilePlanChanged =>
      'برنامه هنگام بازبینی تغییر کرد. آخرین بازبینی را باز کنید و دوباره هزینه‌اش را برآورد کنید.';

  @override
  String get mobilePlanReject => 'رد برنامه';

  @override
  String get mobilePlanRejectConfirm => 'این برنامه رد شود؟ اجرا نخواهد شد.';

  @override
  String get mobilePlanStop => 'توقف اجرا';

  @override
  String get mobilePlanStopConfirm =>
      'اجرای این برنامه متوقف شود؟ کارهای انجام‌شده به حالت قبل برنمی‌گردند.';

  @override
  String mobilePlanRunId(String runId) {
    return 'اجرای برنامه: $runId';
  }

  @override
  String get mobilePlanExecutionPending =>
      'تأیید پذیرفته شد. در انتظار ثبت اجرا…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return '$completed از $total گام اجرا تکمیل شد';
  }

  @override
  String get mobilePlanOpenConversation => 'باز کردن گفتگو';

  @override
  String get mobileGoalsTitle => 'هدف‌های تحت نظارت';

  @override
  String get mobileGoalsLoadFailed => 'بارگیری هدف‌های تحت نظارت ممکن نبود';

  @override
  String get mobileGoalsEmpty => 'هنوز هدفی تحت نظارت نیست';

  @override
  String get mobileGoalsEmptyDescription =>
      'در یک فضا هدفی آغاز کنید یا در گفتگو /goal بفرستید.';

  @override
  String get mobileGoalMissing =>
      'این هدف دیگر در این فضای کاری در دسترس نیست.';

  @override
  String get mobileGoalActive => 'فعال';

  @override
  String get mobileGoalPaused => 'مکث‌شده';

  @override
  String get mobileGoalCompleted => 'کامل‌شده';

  @override
  String get mobileGoalFailed => 'ناموفق';

  @override
  String get mobileGoalCancelled => 'لغوشده';

  @override
  String get mobileGoalBudgetExhausted => 'بودجه به پایان رسید';

  @override
  String get mobileGoalGoal => 'هدف';

  @override
  String get mobileGoalLoop => 'چرخه';

  @override
  String mobileGoalKind(String kind) {
    return 'نوع: $kind';
  }

  @override
  String mobileGoalRuns(String count) {
    return '$count اجرا';
  }

  @override
  String get mobileGoalNoRunLimit => 'نامحدود';

  @override
  String mobileGoalProgress(
    String runs,
    String maxRuns,
    String spent,
    String cap,
  ) {
    return 'اجراها: $runs / $maxRuns · هزینه‌شده: $spent / $cap';
  }

  @override
  String mobileGoalDeadline(String date) {
    return 'مهلت: $date';
  }

  @override
  String mobileGoalFailures(String count) {
    return 'اجراهای ناموفق پیاپی: $count';
  }

  @override
  String get mobileGoalSummary => 'خلاصهٔ تکمیل';

  @override
  String get mobileGoalFailedDescription =>
      'ناظر پس از چند اجرای ناموفق متوقف شد. جزئیات را در گفتگو ببینید.';

  @override
  String get mobileGoalBudgetWall =>
      'مهلت یا محدودیت تعداد اجرا فرا رسیده است. این هدف با افزایش سقف هزینه از سر گرفته نمی‌شود.';

  @override
  String get mobileGoalPause => 'مکث هدف';

  @override
  String get mobileGoalResume => 'ازسرگیری هدف';

  @override
  String get mobileGoalStop => 'لغو هدف';

  @override
  String get mobileGoalStopConfirm =>
      'این هدف تحت نظارت برای همیشه لغو شود؟ از سر گرفته نخواهد شد.';

  @override
  String get mobileGoalRaiseBudget => 'افزایش بودجه و ازسرگیری';

  @override
  String mobileGoalRaiseTo(String amount) {
    return 'افزایش بودجه به $amount و ازسرگیری';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return 'سقف هزینهٔ این هدف از $oldCap به $newCap افزایش یابد و هزینه‌کرد از سر گرفته شود؟';
  }

  @override
  String get mobileGoalOpenConversation => 'باز کردن گفتگوی هدف';

  @override
  String get mobileGoalCreate => 'شروع هدف تحت نظارت';

  @override
  String get mobileGoalChooseSpace => 'اجرا در فضا';

  @override
  String get mobileGoalNoSpaces => 'پیش از شروع هدف، فضایی ایجاد کنید.';

  @override
  String get mobileGoalChooseAgent => 'اجرا با عامل';

  @override
  String get mobileGoalNoAgents => 'پیش از شروع هدف، عاملی فعال اضافه کنید.';

  @override
  String mobileGoalSelectedAgent(String name) {
    return '$name انتخاب شد';
  }

  @override
  String get mobileGoalObjectiveHint => 'عامل باید به چه نتیجه‌ای برسد؟';

  @override
  String get mobileGoalBudgetUsd => 'سقف هزینه (USD)';

  @override
  String get mobileGoalCreateInvalid =>
      'فضا و عامل را انتخاب کنید، هدفی بنویسید و سقف هزینهٔ مثبت به دلار آمریکا تعیین کنید.';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return 'هدف تحت نظارت با حداکثر هزینهٔ $cap آغاز شود؟ عامل ممکن است بلافاصله شروع کند.';
  }

  @override
  String get mobileGoalUnavailable =>
      'اتصال به سرور آماده نیست. پس از اتصال دوباره تلاش کنید.';

  @override
  String get mobileGoalConversationMissing =>
      'گفتگوی انتخاب‌شده دیگر در این فضای کاری در دسترس نیست.';

  @override
  String get mobileGoalCreateSent =>
      'هدف آغاز شد. وضعیت ناظر در این فهرست نمایش داده می‌شود.';

  @override
  String get mobileGoalStartRefused =>
      'هیچ اجرایی برای هدف آغاز نشد. دلیل ناظر را در گفتگو ببینید.';

  @override
  String mobileGoalSelectedSpace(String name) {
    return '$name انتخاب شد';
  }

  @override
  String get requestUnavailable =>
      'این درخواست دیگر در فضای کاری فعال در دسترس نیست.';

  @override
  String get requestAlreadyResolved => 'این درخواست قبلاً رسیدگی شده است.';

  @override
  String get inboxCredentialsBlocked => 'اعتبارنامه‌های مانع اجرا';

  @override
  String get inboxSyncFailures => 'همگام‌سازی‌های ناموفق ارائه‌دهندگان';

  @override
  String get inboxConfigureCredentials => 'پیکربندی اعتبارنامه‌ها';

  @override
  String get openTicket => 'باز کردن تیکت';

  @override
  String get activityTitle => 'فعالیت';

  @override
  String get activityClearAll => 'پاک کردن فعالیت‌ها';

  @override
  String get activityClearConfirm =>
      'این کار همهٔ فعالیت‌هایی را که تاکنون برای شما ثبت شده‌اند در تمام دستگاه‌ها پنهان می‌کند. فعالیت‌های جدید همچنان نمایش داده می‌شوند.';

  @override
  String get activityMarkAllRead => 'نشان‌گذاری همه به‌عنوان خوانده‌شده';

  @override
  String get activityMarkAllConfirm =>
      'همهٔ موارد فعالیت این فضای کاری در تمام دستگاه‌هایتان به‌عنوان خوانده‌شده نشان‌گذاری شوند؟';

  @override
  String get activityMarkRead => 'نشان‌گذاری به‌عنوان خوانده‌شده';

  @override
  String get activityMarkUnread => 'نشان‌گذاری به‌عنوان خوانده‌نشده';

  @override
  String get activityDismiss => 'نادیده گرفتن';

  @override
  String get activityResolved => 'حل‌شده';

  @override
  String get activityOpen => 'باز';

  @override
  String get activityEmpty => 'هنوز فعالیتی نیست';

  @override
  String get activityLoadFailed => 'بارگیری فعالیت‌ها ممکن نبود';

  @override
  String get activityAgentWaiting => 'عامل به اطلاعات نیاز دارد';

  @override
  String get activityAgentBlocked => 'کنش عامل مسدود شد';

  @override
  String get activityMessage => 'پیام جدید';

  @override
  String get activityPullRequest => 'به‌روزرسانی Pull request';

  @override
  String get activityTicket => 'به‌روزرسانی تیکت';

  @override
  String get activityMeeting => 'به‌روزرسانی جلسه';

  @override
  String get activityCalendar => 'اتصال تقویم';

  @override
  String get activityRig => 'به‌روزرسانی محیط محصور';

  @override
  String get activityEvent => 'به‌روزرسانی';

  @override
  String get activityPrReady => 'Pull request آمادهٔ ادغام است';

  @override
  String get activityPrBlocked => 'ادغام Pull request مسدود شد';

  @override
  String get activityPrApproved => 'Pull request تأیید شد';

  @override
  String get activityPrChanges => 'درخواست تغییرات';

  @override
  String get activityPrChecksFailed => 'بررسی‌های Pull request ناموفق بودند';

  @override
  String get activityPrChecksRecovered =>
      'بررسی‌های Pull request دوباره موفق شدند';

  @override
  String get activityPrComment => 'نظر در Pull request';

  @override
  String get activityPrPublished => 'Pull request منتشر شد';

  @override
  String get activityPrMerged => 'Pull request ادغام شد';

  @override
  String get activityPrMentioned => 'در یک Pull request به شما اشاره شد';

  @override
  String get activityPrReviewRequested => 'درخواست بازبینی';

  @override
  String get activityPrReviewStale => 'بازبینی نیاز به تازه‌سازی دارد';

  @override
  String get activityTicketAssigned => 'تیکت تخصیص یافت';

  @override
  String get activityTicketChanged => 'وضعیت تیکت تغییر کرد';

  @override
  String get activityMeetingSoon => 'جلسه به‌زودی شروع می‌شود';

  @override
  String get activityCalendarExpired => 'اتصال تقویم منقضی شد';

  @override
  String get activityRigControl => 'کنترل محیط محصور تغییر کرد';

  @override
  String get activityRigClosed => 'محیط محصور متوقف شد';

  @override
  String get mobileSpacesSearch => 'جستجوی فضاها';

  @override
  String get mobileSpacesArchived => 'بایگانی‌شده';

  @override
  String get mobileSpacesActive => 'فعال';

  @override
  String get mobileSpacesNew => 'فضای جدید';

  @override
  String get mobileSpacesManage => 'مدیریت فضا';

  @override
  String get mobileSpacesName => 'نام فضا';

  @override
  String get mobileSpacesAgents => 'عامل‌ها';

  @override
  String get mobileSpacesMembers => 'افراد';

  @override
  String get mobileSpacesRepos => 'مخزن‌ها';

  @override
  String get mobileSpacesAllRepos => 'همهٔ مخزن‌های پیوندشده';

  @override
  String get mobileSpacesNoRepos => 'مخزنی نیست';

  @override
  String get mobileSpacesBaseBranch => 'شاخهٔ پایه (اختیاری)';

  @override
  String get mobileSpacesDefaultBranch => 'شاخهٔ پیش‌فرض';

  @override
  String get mobileSpacesMode => 'حالت';

  @override
  String get mobileSpacesModeChat => 'گفتگو';

  @override
  String get mobileSpacesModeReview => 'بازبینی (فقط‌خواندنی)';

  @override
  String get mobileSpacesModePlan => 'برنامه‌ریزی (فقط‌خواندنی)';

  @override
  String get mobileSpacesModeOrchestrate => 'ارکستر کردن';

  @override
  String get mobileSpacesAutonomy => 'جایگزینی سطح خودمختاری';

  @override
  String get mobileSpacesAutonomyInherited => 'به ارث رسیده';

  @override
  String get mobileSpacesAutonomyPropose => 'فقط پیشنهاد';

  @override
  String get mobileSpacesAutonomyApproval => 'عمل با تأیید';

  @override
  String get mobileSpacesAutonomyFreely => 'عمل آزاد';

  @override
  String get mobileSpacesAutonomyNotice =>
      'این جایگزینی نمی‌تواند درخواست‌های تأیید یا ردهای سیاست کنش را دور بزند. فقط مدیران فضای کاری می‌توانند آن را تغییر دهند.';

  @override
  String get mobileSpacesArchive => 'بایگانی فضا';

  @override
  String get mobileSpacesReopen => 'بازگشایی فضا';

  @override
  String get mobileSpacesSave => 'ذخیرهٔ تغییرات';

  @override
  String get mobileSpacesCreate => 'ایجاد فضا';

  @override
  String get mobileSpacesOperationFailed => 'به‌روزرسانی فضا ممکن نبود';

  @override
  String get mobileSpacesMissing => 'فضا در این فضای کاری یافت نشد';

  @override
  String get mobileSpacesEmptyName => 'نامی برای فضا وارد کنید';

  @override
  String get mobileSpacesNoMatches => 'فضای مطابقی یافت نشد';

  @override
  String get mobileSpacesUnread => 'پاسخ خوانده‌نشدهٔ عامل';

  @override
  String get mobileSpacesNeedsInput => 'به پاسخ شما نیاز دارد';

  @override
  String get mobileSpacesRunning => 'عامل در حال اجراست';

  @override
  String get mobileSpacesNoAgents => 'در این فضای کاری عاملی نیست';

  @override
  String get mobileSpacesNoMembers => 'عضو دیگری در فضای کاری نیست';

  @override
  String get mobileSpacesRepoError => 'بارگیری مخزن‌ها ممکن نبود';

  @override
  String get mobileSpacesRetry => 'تلاش مجدد';

  @override
  String get mobileSpacesBranchUnavailable =>
      'هنگام ایجاد فضا، شاخهٔ پایه را انتخاب یا وارد کنید؛ شاخهٔ پایهٔ فضای موجود قابل تغییر نیست.';

  @override
  String get mobileSpacesArchivedEmpty => 'فضای بایگانی‌شده‌ای نیست';

  @override
  String get mobileSpacesAllRepoWarning =>
      'مخزن‌هایی که بعداً به فضای کاری پیوند می‌خورند نیز در این فضا قرار می‌گیرند.';

  @override
  String get mobileSpacesCreatedRetry =>
      'فضا ایجاد شد. افزودن افراد را دوباره امتحان کنید یا صفحهٔ مدیریت فضا را باز کنید.';

  @override
  String get progressTitle => 'پیشرفت';

  @override
  String get progressConversation => 'گفتگو';

  @override
  String get progressLoadFailed => 'بارگیری پیشرفت ممکن نبود';

  @override
  String get progressUnavailable => 'گفتگو در دسترس نیست';

  @override
  String get progressUnavailableDescription =>
      'این گفتگو در فضای کاری و فضای فعال نیست. برای ادامه به فضای آن برگردید.';

  @override
  String get progressSaveFailed => 'به‌روزرسانی پیشرفت ممکن نبود';

  @override
  String get progressGoal => 'هدف';

  @override
  String get progressNoGoal => 'هدف کاری تعیین نشده است';

  @override
  String get progressSetGoal => 'تعیین هدف';

  @override
  String get progressEditGoal => 'ویرایش هدف';

  @override
  String get progressClearGoal => 'پاک کردن هدف';

  @override
  String get progressGoalRequired => 'پیش از ذخیره، هدفی وارد کنید.';

  @override
  String get progressTodos => 'کارها';

  @override
  String get transcriptToolTodos => 'کارها';

  @override
  String get transcriptToolSearchMemory => 'جست‌وجو در حافظه';

  @override
  String get transcriptToolRenderMedia => 'نمایش رسانه';

  @override
  String get progressNoTodos => 'هنوز کاری نیست';

  @override
  String get progressNewTodo => 'کار جدید';

  @override
  String get progressAddTodo => 'افزودن کار';

  @override
  String get progressEditTodo => 'ویرایش کار';

  @override
  String get progressTodoRequired => 'پیش از ذخیره، کاری وارد کنید.';

  @override
  String get progressTodoNoLongerExists =>
      'آن کار حذف شده است. فهرست را دوباره بارگیری و تلاش کنید.';

  @override
  String get progressWorkspaceChanged =>
      'فضای کاری فعال تغییر کرد. به این گفتگو برگردید و دوباره تلاش کنید.';

  @override
  String progressRemoveTodo(String name) {
    return 'حذف کار $name';
  }

  @override
  String get progressPending => 'در انتظار';

  @override
  String get progressInProgress => 'در جریان';

  @override
  String get progressCompleted => 'کامل‌شده';

  @override
  String get progressMoveUp => 'انتقال کار به بالا';

  @override
  String get progressMoveDown => 'انتقال کار به پایین';

  @override
  String get progressRunTree => 'اجراهای عامل';

  @override
  String get progressNoRuns => 'هنوز اجرایی در این گفتگو نیست';

  @override
  String get progressRunning => 'در حال اجرا';

  @override
  String get progressFailed => 'ناموفق';

  @override
  String get progressUnknown => 'ناشناخته';

  @override
  String get progressHealthy => 'فعال';

  @override
  String get progressBlocked => 'مسدود';

  @override
  String get progressLooping => 'در چرخه';

  @override
  String get progressStalled => 'متوقف‌شده در میانهٔ کار';

  @override
  String get progressDead => 'توقف غیرمنتظره';

  @override
  String get progressQuiet => 'هنوز خروجی‌ای نیست';

  @override
  String get progressCostReported => 'هزینهٔ اعلام‌شده توسط ارائه‌دهنده';

  @override
  String get progressCostNotional => 'قیمت اسمی اشتراک؛ صورتحساب نیست';

  @override
  String get progressCostMixed => 'منابع هزینهٔ ترکیبی';

  @override
  String get progressCostEstimated => 'هزینهٔ تخمینی';

  @override
  String progressDurationSeconds(String seconds) {
    return '$seconds ثانیه';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'مدل: $model · زمان: $duration · هزینه: $cost';
  }

  @override
  String progressStartedAt(String time) {
    return 'شروع $time';
  }

  @override
  String progressLiveness(String state) {
    return 'سلامت: $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return 'ورودی: $input · خروجی: $output توکن';
  }

  @override
  String get progressOutputPreviewLimited =>
      'فقط ۶۰۰۰ نویسهٔ نخست خروجی ساختاریافته نمایش داده می‌شود.';

  @override
  String progressRetryOf(String runId) {
    return 'تلاش دوباره برای اجرای $runId';
  }

  @override
  String get progressContext => 'زمینه و محدودیت‌ها';

  @override
  String get progressNoAgent => 'عاملی برای بررسی نیست';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window توکن';
  }

  @override
  String get progressMeasured =>
      'زمینهٔ اعلام‌شده توسط ارائه‌دهنده در آخرین فراخوانی';

  @override
  String get progressEstimated =>
      'برآوردشده از گفتگوی ذخیره‌شده و زمینهٔ پایدار';

  @override
  String get progressContextUnknown =>
      'میزان استفاده از زمینه هنوز اعلام نشده است';

  @override
  String progressContextPercent(String percent) {
    return '$percent٪ از پنجرهٔ زمینه';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return 'محدودیت ماهانهٔ تعیین‌شده برای عامل: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return 'گفتگوی زندهٔ ذخیره‌شده: حدود $tokens توکن';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return 'زمینهٔ پایدار $agent · $model';
  }

  @override
  String get progressContextSystem => 'پرامپت سیستم';

  @override
  String get progressContextRules => 'قواعد';

  @override
  String get progressContextSkills => 'مهارت‌ها';

  @override
  String get progressContextTools => 'تعریف ابزارها';

  @override
  String get progressContextMcp => 'ابزارهای MCP';

  @override
  String get progressContextDeferred => 'ابزارهای تعویق‌افتاده';

  @override
  String get progressContextSubagents => 'زیرعامل‌ها';

  @override
  String get progressContextRunner => 'اجراکنندهٔ خارجی';

  @override
  String get progressContextMemory => 'حافظه';

  @override
  String get progressContextHistory => 'تاریخچهٔ گفتگو';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens توکن';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens توکن';
  }

  @override
  String get progressOutputs => 'خروجی‌های اخیر';

  @override
  String get progressNoOutputs => 'خروجی تازه‌ای از عامل نیست';

  @override
  String get progressStructuredOutputsAbove =>
      'خروجی‌های ساختاریافته در اجراهای عامل در بالا نمایش داده می‌شوند.';

  @override
  String get progressRecentOutputsOnly =>
      'فقط پیام‌های اخیر نمایش داده می‌شوند. برای کارهای قدیمی‌تر گفتگو را باز کنید.';

  @override
  String get progressPlan => 'برنامه';

  @override
  String get progressArtifact => 'آرتیفکت';

  @override
  String get progressResult => 'نتیجه';

  @override
  String get progressHideArtifact => 'پنهان کردن آرتیفکت';

  @override
  String get progressReadArtifact => 'خواندن آرتیفکت';

  @override
  String get progressArtifactUnavailable => 'آرتیفکت دیگر در دسترس نیست';

  @override
  String get progressArtifactPreviewLimited =>
      'پیش‌نمایش محدودی از این آرتیفکت نمایش داده می‌شود.';

  @override
  String get progressDiagramSource => 'کد منبع نمودار';

  @override
  String progressOpenAttachment(String name) {
    return 'باز کردن $name';
  }

  @override
  String get progressOpenPlan => 'باز کردن برنامه';

  @override
  String progressOpenDiff(String label) {
    return 'بازبینی فایل‌های تغییرکرده: $label';
  }

  @override
  String get progressViewMessage => 'دیدن پیام';

  @override
  String get pushTitle => 'اعلان‌های پس‌زمینه';

  @override
  String get pushIntro =>
      'وقتی موضوعی به توجه شما نیاز دارد، حتی با برنامهٔ بسته، هشداری خصوصی دریافت کنید. جزئیات در اتصال رمزگذاری‌شدهٔ شما باقی می‌مانند.';

  @override
  String get pushLoading => 'در حال بررسی تنظیمات اعلان‌ها…';

  @override
  String get pushError =>
      'به‌روزرسانی اعلان‌ها ممکن نبود. اتصال خود را بررسی و دوباره تلاش کنید.';

  @override
  String get pushEnable => 'فعال‌سازی اعلان‌ها';

  @override
  String get pushDisable => 'خاموش کردن اعلان‌ها';

  @override
  String get pushQuiet => 'مکث هشدارها در این دستگاه';

  @override
  String get pushCategories => 'دربارهٔ این موارد خبرم کن';

  @override
  String get pushCategoryAgents => 'عامل‌ها';

  @override
  String get pushCategoryMessages => 'پیام‌ها';

  @override
  String get pushCategoryPullRequests => 'Pull requestها';

  @override
  String get pushCategoryTickets => 'تیکت‌ها';

  @override
  String get pushCategoryCalendar => 'تقویم';

  @override
  String get pushCategoryMachines => 'دستگاه‌ها';

  @override
  String get pushSecureOrigin => 'اعلان‌ها به HTTPS نیاز دارند.';

  @override
  String get pushInstallIos =>
      'در iPhone یا iPad، این برنامه را به صفحهٔ اصلی اضافه کنید و برای فعال‌سازی اعلان‌ها آن را از همان‌جا باز کنید.';

  @override
  String get pushUnsupported =>
      'این مرورگر از اعلان‌های پس‌زمینه پشتیبانی نمی‌کند.';

  @override
  String get pushDenied =>
      'مرورگر گزارش می‌دهد که اعلان‌ها مسدود هستند. مجوز این سایت و تنظیمات اعلان مرورگر یا دستگاه را بررسی کنید، سپس صفحه را تازه‌سازی کنید.';

  @override
  String get pushOsHint =>
      'مرورگر شما همچنین باید در تنظیمات سیستم دستگاه اجازهٔ نمایش اعلان را داشته باشد.';

  @override
  String get pushServiceUnavailable =>
      'سرویس پوش مرورگر اشتراک را رد کرد. برخی مرورگرها مانند Brave آن را به‌طور پیش‌فرض خاموش می‌کنند: در تنظیمات حریم خصوصی مرورگر گزینهٔ پیام‌های پوش را پیدا کنید و دوباره تلاش کنید.';

  @override
  String get pushWorkerUnavailable =>
      'سرویس اعلان در این مرورگر راه‌اندازی نشد. صفحه را دوباره بارگذاری کنید و دوباره تلاش کنید.';

  @override
  String get pushResubscribe => 'اتصال دوبارهٔ اعلان‌ها';

  @override
  String get pushStatusEnabled => 'اعلان‌ها برای این دستگاه روشن هستند.';

  @override
  String get pushStatusDisabled => 'اعلان‌ها برای این دستگاه خاموش هستند.';

  @override
  String get credentialsTitle => 'اتصال‌ها و اعتبارنامه‌ها';

  @override
  String get credentialsIntro =>
      'حساب‌هایی را که اجراها و یکپارچه‌سازی‌هایتان استفاده می‌کنند متصل کنید. اطلاعات محرمانه در سرور شما ذخیره می‌شوند، نه در این تلفن.';

  @override
  String get credentialsModelProviders => 'ارائه‌دهندگان مدل';

  @override
  String get credentialsOwnerOnly =>
      'فقط مالک سرور می‌تواند اعتبارنامه‌های ارائه‌دهندگان مدل را اضافه کند، به آن‌ها وارد شود یا حذفشان کند. این کلیدها میان فضاهای کاری مشترک‌اند.';

  @override
  String get credentialsContactOwner =>
      'از مالک سرور بخواهید ارائه‌دهندهٔ موردنیاز اجرای مسدودشدهٔ شما را متصل کند.';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'Claude Code از طریق رابط خط فرمان در میزبان وارد حساب می‌شود. از مالک سرور بخواهید ورود به حساب را در پایانهٔ میزبان تکمیل یا تمدید کند؛ این کار از تلفن ممکن نیست.';

  @override
  String get credentialsYourForgeAccounts => 'حساب‌های میزبانی کد شما';

  @override
  String get credentialsYourTicketingAccount => 'حساب تیکت‌های شما';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'تیکت‌های محلی نیازی به ورود ندارند. اگر فضای کاری‌تان از Linear استفاده می‌کند، آن را اینجا متصل کنید.';

  @override
  String get credentialsMembershipRequired =>
      'برای مدیریت اعتبارنامه‌های میزبانی کد یا تیکت‌ها باید عضو فضای کاری شوید. از مدیر فضای کاری دسترسی بخواهید.';

  @override
  String get credentialsSwitchWorkspace =>
      'این پیوند به فضای کاری دیگری اشاره می‌کند. پیش از تغییر اعتبارنامه‌ها به آن فضا بروید.';

  @override
  String get credentialsReturnToInbox =>
      'پس از اتصال اعتبارنامه، برای تلاش دوبارهٔ اجرای مسدودشده به صندوق ورودی برگردید. میزبان اجراهای در انتظار را هم خودکار بررسی می‌کند.';

  @override
  String get credentialsLoadFailed =>
      'بارگیری اتصال‌ها ممکن نبود. پیوند سرور را بررسی و دوباره تلاش کنید.';

  @override
  String get credentialsOperationFailed =>
      'تغییر این اتصال ممکن نبود. پیوند سرور، دسترسی خود و اعتبارنامه را بررسی و دوباره تلاش کنید.';

  @override
  String get credentialsConnected => 'متصل';

  @override
  String get credentialsNotConnected => 'متصل نیست';

  @override
  String credentialsSignedInAs(String username) {
    return 'واردشده با نام $username';
  }

  @override
  String get credentialsAccount => 'حساب متصل';

  @override
  String get credentialsStoredKey => 'کلید ذخیره‌شده';

  @override
  String get credentialsActive => 'فعال';

  @override
  String get credentialsRemove => 'برداشتن';

  @override
  String get credentialsRemoveConfirm =>
      'اعتبارنامهٔ ذخیره‌شده‌تان حذف شود؟ ممکن است لازم باشد دوباره وارد شوید.';

  @override
  String get credentialsApiKey => 'کلید API';

  @override
  String get credentialsApiKeyHint => 'کلید API ارائه‌دهنده را جای‌گذاری کنید';

  @override
  String get credentialsBrowserLogin => 'ورود با مرورگر';

  @override
  String get credentialsSignInAgain => 'دوباره وارد شوید';

  @override
  String get credentialsWaitingForLogin => 'در انتظار مجوزدهی در مرورگر شما…';

  @override
  String get credentialsLoginTimedOut =>
      'مهلت ورود به پایان رسید. دوباره برای ورود تلاش کنید.';

  @override
  String get credentialsCopyCode => 'کپی کد';

  @override
  String get credentialsDeviceCodeHint =>
      'این کد را در صفحهٔ ارائه‌دهنده تأیید کنید. تا زمانی که سرور ورود را کامل می‌کند، این صفحه را باز نگه دارید.';

  @override
  String get credentialsPasteRedirect => 'کد مجوزدهی یا نشانی بازگشت';

  @override
  String get credentialsPasteRedirectHint =>
      'کد یا نشانی بازگشت کامل ارائه‌دهنده را جای‌گذاری کنید';

  @override
  String get credentialsCompleteLogin => 'تکمیل ورود';

  @override
  String get credentialsRedirectUnavailable =>
      'دسترسی امن از تلفن به نشانی بازگشت مرورگر این سرور ممکن نیست. از مالک سرور بخواهید نشانی بازگشت عمومی HTTPS تنظیم کند یا به‌جای آن توکنی اضافه کنید.';

  @override
  String get credentialsUpdateToken => 'به‌روزرسانی توکن';

  @override
  String get credentialsAddToken => 'افزودن توکن';

  @override
  String get credentialsPersonalToken => 'توکن دسترسی شخصی';

  @override
  String get credentialsPersonalTokenHint =>
      'توکن دسترسی شخصی را جای‌گذاری کنید';

  @override
  String get credentialsHostManaged =>
      'این اتصال از برنامه یا محیط سرور می‌آید. فقط مالک سرور می‌تواند آن را در همان‌جا تغییر دهد؛ شما همچنان می‌توانید توکن خودتان را اضافه کنید.';

  @override
  String get credentialsStopWatching => 'توقف انتظار';
}
