// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'חזרה';

  @override
  String get cancel => 'ביטול';

  @override
  String get retry => 'ניסיון חוזר';

  @override
  String get tryAgain => 'נסו שוב';

  @override
  String get settings => 'הגדרות';

  @override
  String get refresh => 'רענון';

  @override
  String get approve => 'אישור';

  @override
  String get deny => 'דחייה';

  @override
  String get continueLabel => 'המשך';

  @override
  String get agentQuestionHeader => 'שאלה אליכם';

  @override
  String get agentQuestionAnsweredLabel => 'נענתה';

  @override
  String get agentQuestionSkip => 'דילוג';

  @override
  String get agentQuestionSkippedLabel => 'דולגה';

  @override
  String get agentQuestionFreeformHint => 'הקלידו את תשובתכם…';

  @override
  String get agentApprovalRequired => 'נדרש אישור';

  @override
  String get copyCommand => 'העתקת הפקודה';

  @override
  String get approveAndRemember => 'אישור ל־8 שעות';

  @override
  String get decline => 'סירוב';

  @override
  String get confirm => 'אישור';

  @override
  String get send => 'שליחה';

  @override
  String get close => 'סגירה';

  @override
  String get expand => 'הרחבה';

  @override
  String get zoomIn => 'הגדלה';

  @override
  String get zoomOut => 'הקטנה';

  @override
  String get resetZoom => 'איפוס זום';

  @override
  String get scanQrPrompt =>
      'סרקו את קוד ה-QR מ-Control Center כדי לצמד את הטלפון הזה.';

  @override
  String get scanQrHelp =>
      'פתחו את המצלמה וכוונו אותה אל קוד ה-QR שמוצג ב-Control Center. הטלפון הזה מתחבר ישירות בקישור פרטי.';

  @override
  String get connectingToMac => 'מתחבר ל-Control Center…';

  @override
  String get connectingDetail => 'יוצר חיבור ישיר ומאובטח.';

  @override
  String get identityChangedTitle => 'זהות השרת השתנתה';

  @override
  String get identityChangedBody =>
      'השרת הזה כבר לא תואם את הזהות שנשמרה בעת הצימוד. ייתכן שהשרת הותקן מחדש — או שמשהו מיירט את החיבור. ליתר ביטחון, המכשיר הזה לא יתחבר. הסירו את הצימוד, ואז סרקו קוד QR חדש מ-Control Center כדי לצמד מחדש.';

  @override
  String get removePairing => 'הסרת הצימוד';

  @override
  String get couldntConnect => 'לא ניתן להתחבר';

  @override
  String get pendingPairingTitle => 'להתחבר לשרת הזה?';

  @override
  String get pendingPairingBody =>
      'קישור ביקש מ-Control Center לבצע צימוד לשרת הזה. המשיכו רק אם יזמתם זאת בעצמכם.';

  @override
  String get connect => 'התחברות';

  @override
  String get failureNotPaired =>
      'אין צימוד — סרקו את קוד ה-QR מ-Control Center';

  @override
  String get failureUnreachable =>
      'לא ניתן להגיע לשרת בשום נתיב — ודאו שהוא פועל, או נסו מאותה רשת';

  @override
  String get failureIdentityChanged =>
      'זהות השרת השתנתה — אם הוא הותקן מחדש, צמדו את המכשיר מחדש';

  @override
  String get failureAuthRejected =>
      'השרת דחה את המכשיר הזה — צמדו אותו מחדש מ-Control Center';

  @override
  String get failureUnknown => 'לא ניתן להתחבר — הקישו כדי לנסות שוב';

  @override
  String get statusConnected => 'מחובר';

  @override
  String get statusConnecting => 'מתחבר';

  @override
  String get statusOffline => 'לא מקוון';

  @override
  String get statusIdentityMismatch => 'אי-התאמת זהות';

  @override
  String get statusNotPaired => 'אין צימוד';

  @override
  String get statusConfirmPairing => 'אישור צימוד';

  @override
  String get connectionFailed => 'החיבור נכשל';

  @override
  String get identityMismatchBanner =>
      'זהות השרת השתנתה — החיבור הופסק. צמדו את המכשיר מחדש כדי להמשיך.';

  @override
  String get tabInbox => 'דואר נכנס';

  @override
  String get tabTickets => 'כרטיסים';

  @override
  String get tabChat => 'צ\'אט';

  @override
  String get tabPrs => 'PRs';

  @override
  String get tabCalendar => 'יומן';

  @override
  String get tabNews => 'חדשות';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label, $count בהמתנה';
  }

  @override
  String get updateAvailable => 'גרסה חדשה של Control Center זמינה';

  @override
  String get appearance => 'מראה';

  @override
  String get language => 'שפה';

  @override
  String get device => 'מכשיר';

  @override
  String get themeSystem => 'מערכת';

  @override
  String get themeLight => 'בהיר';

  @override
  String get themeDark => 'כהה';

  @override
  String get languageSystem => 'מערכת';

  @override
  String get disconnectTapAgain =>
      'הקישו שוב כדי לנתק את המכשיר הזה מ-Control Center';

  @override
  String get disconnectDevice => 'ניתוק המכשיר הזה';

  @override
  String get disconnect => 'ניתוק';

  @override
  String get chooseWorkspace => 'בחירת סביבת עבודה';

  @override
  String get workspaces => 'סביבות עבודה';

  @override
  String get workspacesLoadFailed => 'לא ניתן לטעון את סביבות העבודה';

  @override
  String get noWorkspacesYet => 'עדיין אין סביבות עבודה';

  @override
  String selectWorkspace(String name) {
    return 'בחירת $name';
  }

  @override
  String get inboxLoadFailed => 'לא ניתן לטעון את הדואר הנכנס';

  @override
  String get allCaughtUp => 'התעדכנתם בהכול';

  @override
  String get inboxNothingWaiting =>
      'שום דבר לא חסום ואף בקשת משיכה לא ממתינה לכם.';

  @override
  String get blocked => 'חסומים';

  @override
  String get sectionNeedsYourReview => 'ממתינים לסקירה שלכם';

  @override
  String get sectionReturnedToYou => 'הוחזרו אליכם';

  @override
  String get sectionApprovedAndReady => 'מאושרים ומוכנים';

  @override
  String get sectionYourDrafts => 'הטיוטות שלכם';

  @override
  String get sectionWaitingForReviewers => 'ממתינים לסוקרים';

  @override
  String get sectionMergingAndMerged => 'במיזוג ומוזגו לאחרונה';

  @override
  String get sectionWaitingForAuthor => 'ממתינים למחבר';

  @override
  String waitingAgo(String ago) {
    return 'ממתין $ago';
  }

  @override
  String get openConversation => 'פתיחת השיחה';

  @override
  String get calendarLoadFailed => 'לא ניתן לטעון את היומן';

  @override
  String get nothingScheduled => 'אין אירועים מתוכננים';

  @override
  String get calendarEmptyDescription =>
      'אירועים מהיומנים המחוברים שלכם יופיעו כאן.';

  @override
  String get agenda => 'סדר יום';

  @override
  String get syncCalendarsNow => 'סנכרון היומנים עכשיו';

  @override
  String get event => 'אירוע';

  @override
  String get eventNotFound => 'האירוע לא נמצא';

  @override
  String get eventNotFoundDescription =>
      'ייתכן שהוא מחוץ לחלון סדר היום, או שהוסר במקור.';

  @override
  String get joinMeeting => 'הצטרפות לפגישה';

  @override
  String attendeesCount(int count) {
    return 'משתתפים ($count)';
  }

  @override
  String get details => 'פרטים';

  @override
  String get allDay => 'כל היום';

  @override
  String get happeningNow => 'מתרחש עכשיו';

  @override
  String inDuration(String duration) {
    return 'בעוד $duration';
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
  String get attendeeAccepted => 'אישרו';

  @override
  String get attendeeDeclined => 'סירבו';

  @override
  String get attendeeMaybe => 'אולי';

  @override
  String get attendeeNoReply => 'ללא מענה';

  @override
  String get organizer => 'מארגן';

  @override
  String get calendarNoAccounts =>
      'לא מחובר יומן לסביבת העבודה הזו. חברו יומן מאפליקציית שולחן העבודה — ההתחברות שומרת את הטוקן שלה בשרת.';

  @override
  String get calendarReauthNeeded =>
      'חשבון יומן דורש חיבור מחדש — מה שמוצג למטה עשוי להיות לא מעודכן. חברו אותו מחדש מאפליקציית שולחן העבודה.';

  @override
  String get spacesLoadFailed => 'לא ניתן לטעון את המרחבים';

  @override
  String get noSpaces => 'אין מרחבים';

  @override
  String get spacesEmptyDescription => 'מרחבים בסביבת העבודה הזו יופיעו כאן.';

  @override
  String get newSpaceFolder => 'תיקייה חדשה';

  @override
  String get folderName => 'שם התיקייה';

  @override
  String get renameSpaceFolder => 'שינוי שם התיקייה';

  @override
  String get deleteSpaceFolder => 'מחיקת התיקייה';

  @override
  String get moveSpaceToFolder => 'העברה לתיקייה';

  @override
  String get removeSpaceFromFolder => 'הסרה מהתיקייה';

  @override
  String get spaceFolderActions => 'פעולות התיקייה';

  @override
  String get deleteFolderWithSpacesWarning =>
      'מחיקה לצמיתות של מרחבים מסירה את ההודעות ועצי העבודה שלהם עבור כולם. אי אפשר לבטל פעולה זו.';

  @override
  String get deleteSpacesInFolder => 'מחיקת המרחבים שבתיקייה הזו לצמיתות';

  @override
  String get deleteFolderAndSpaces => 'מחיקת התיקייה והמרחבים';

  @override
  String get keepSpacesInFolder => 'אחרת, המרחבים יישארו מחוץ לתיקיות.';

  @override
  String get create => 'יצירה';

  @override
  String get otherSpaces => 'מרחבים אחרים';

  @override
  String get folderUpdateFailed => 'לא ניתן לעדכן את התיקיות';

  @override
  String get thread => 'שרשור';

  @override
  String get agentWorking => 'הסוכן עובד';

  @override
  String get messagesLoadFailed => 'לא ניתן לטעון את ההודעות';

  @override
  String get noMessagesYet => 'עדיין אין הודעות';

  @override
  String get noMessagesDescription => 'שלחו הודעה כדי להתחיל את השיחה.';

  @override
  String get agentResponding => 'הסוכן מגיב';

  @override
  String get agentFinished => 'הסוכן סיים';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁨$names⁩ גדולים מדי לשליחה מכאן.',
      many: '⁨$names⁩ גדולים מדי לשליחה מכאן.',
      two: '⁨$names⁩ גדולים מדי לשליחה מכאן.',
      one: '⁨$names⁩ גדול מדי לשליחה מכאן.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'חבר צוות';

  @override
  String get systemSender => 'מערכת';

  @override
  String get agent => 'סוכן';

  @override
  String get attachFile => 'צירוף קובץ';

  @override
  String get messageHint => 'הודעה';

  @override
  String removeAttachment(String name) {
    return 'הסרת ⁨$name⁩';
  }

  @override
  String get articlesLoadFailed => 'לא ניתן לטעון כתבות';

  @override
  String get noArticles => 'אין כתבות';

  @override
  String get articlesEmptyDescription =>
      'כתבות חדשות יופיעו כאן כשהפידים יתעדכנו.';

  @override
  String get unread => 'לא נקראו';

  @override
  String get allFeeds => 'כל הפידים';

  @override
  String get save => 'שמירה';

  @override
  String get unsave => 'ביטול שמירה';

  @override
  String get readFullArticle => 'קריאת הכתבה המלאה';

  @override
  String get ticketsLoadFailed => 'לא ניתן לטעון כרטיסים';

  @override
  String get noTickets => 'אין כרטיסים';

  @override
  String get ticketsEmptyDescription => 'כרטיסים בסביבת העבודה הזו יופיעו כאן.';

  @override
  String get all => 'הכול';

  @override
  String get ticket => 'כרטיס';

  @override
  String get ticketLoadFailed => 'לא ניתן לטעון את הכרטיס';

  @override
  String assignedTo(String name) {
    return 'הוקצה ל-$name';
  }

  @override
  String get openInBrowser => 'פתיחה בדפדפן';

  @override
  String get status => 'סטטוס';

  @override
  String get assign => 'הקצאה';

  @override
  String get reassign => 'הקצאה מחדש';

  @override
  String get noAgents => 'אין סוכנים';

  @override
  String get noAgentsDescription => 'הקצו סוכן מסביבת העבודה הזו.';

  @override
  String get statusOpen => 'פתוח';

  @override
  String get statusInProgress => 'בתהליך';

  @override
  String get statusBlocked => 'חסום';

  @override
  String get statusInReview => 'בסקירה';

  @override
  String get statusDone => 'הושלם';

  @override
  String get statusBacklog => 'בקלוג';

  @override
  String get lensNeedsMe => 'ממתינים לי';

  @override
  String get lensMine => 'שלי';

  @override
  String get prsLoadFailed => 'לא ניתן לטעון בקשות משיכה';

  @override
  String get noOpenPullRequests => 'אין בקשות משיכה פתוחות';

  @override
  String get nothingWaitingOnReview => 'שום דבר לא ממתין לסקירה שלכם';

  @override
  String get noOwnOpenPullRequests => 'אין לכם בקשות משיכה פתוחות';

  @override
  String get nothingBlocked => 'שום דבר לא חסום';

  @override
  String get prsEmptyDescription =>
      'בקשות משיכה מהמאגרים של סביבת העבודה הזו יופיעו כאן.';

  @override
  String get refreshPullRequests => 'רענון בקשות משיכה';

  @override
  String get noForgeConnected =>
      'לא מחובר forge בשרת, ולכן לא ניתן להביא בקשות משיכה. חברו אחד מאפליקציית שולחן העבודה.';

  @override
  String get draft => 'טיוטה';

  @override
  String get merged => 'מוזג';

  @override
  String get closed => 'נסגר';

  @override
  String get open => 'פתוח';

  @override
  String get approved => 'אושר';

  @override
  String get changesRequested => 'התבקשו שינויים';

  @override
  String get reviewRequired => 'נדרשת סקירה';

  @override
  String get checksPassing => 'הבדיקות עוברות';

  @override
  String get checksFailing => 'הבדיקות נכשלות';

  @override
  String get checksRunning => 'הבדיקות פועלות';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => 'בקשת משיכה';

  @override
  String get prLoadFailed => 'לא ניתן לטעון את בקשת המשיכה הזו';

  @override
  String get openOnForge => 'פתיחה ב-forge';

  @override
  String get requestChangesNeedsComment =>
      'הוסיפו תגובה שמסבירה מה צריך לשנות.';

  @override
  String get conversation => 'שיחה';

  @override
  String get files => 'קבצים';

  @override
  String get checks => 'בדיקות';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count קבצים',
      many: '$count קבצים',
      two: 'שני קבצים',
      one: 'קובץ אחד',
    );
    return '$_temp0';
  }

  @override
  String commitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count קומיטים',
      many: '$count קומיטים',
      two: 'שני קומיטים',
      one: 'קומיט אחד',
    );
    return '$_temp0';
  }

  @override
  String get conflicts => 'קונפליקטים';

  @override
  String get reviewers => 'סוקרים';

  @override
  String get noDescriptionNoComments => 'עדיין אין תיאור ואין תגובות.';

  @override
  String get noChangedFiles => 'אין קבצים ששונו.';

  @override
  String get noChecksReported => 'לא דווחו בדיקות לקומיט העדכני.';

  @override
  String get reviewCommentHint => 'כתבו תגובת סקירה…';

  @override
  String get comment => 'תגובה';

  @override
  String get commentPosted => 'התגובה פורסמה';

  @override
  String get request => 'בקשת שינויים';

  @override
  String get squashAndMerge => 'Squash ומיזוג';

  @override
  String noActionsAvailable(String status) {
    return '$status — אין פעולות זמינות.';
  }

  @override
  String get reviewApproved => 'אישר';

  @override
  String get reviewRequestedChanges => 'ביקש שינויים';

  @override
  String get reviewCommented => 'הגיב';

  @override
  String get reviewPending => 'בהמתנה';

  @override
  String get unknownAuthor => 'לא ידוע';

  @override
  String hideDiffFor(String file) {
    return 'הסתרת ה-diff של ⁨$file⁩';
  }

  @override
  String showDiffFor(String file) {
    return 'הצגת ה-diff של ⁨$file⁩';
  }

  @override
  String get checkRunning => 'פועלת';

  @override
  String get checkPassed => 'עברה';

  @override
  String get checkFailed => 'נכשלה';

  @override
  String get checkCancelled => 'בוטלה';

  @override
  String get checkSkipped => 'דולגה';

  @override
  String labelWithDuration(String label, String duration) {
    return '$label · $duration';
  }

  @override
  String checkSemanticLabel(String name, String state) {
    return '⁨$name⁩, $state';
  }

  @override
  String get noTextDiff =>
      'אין diff טקסטואלי לקובץ הזה — הוא בינארי, או גדול מכדי שה-forge יחזיר אותו.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'הצגת $count השורות הנותרות',
      many: 'הצגת $count השורות הנותרות',
      two: 'הצגת שתי השורות הנותרות',
      one: 'הצגת השורה הנותרת',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count שורות ללא שינוי',
      many: '$count שורות ללא שינוי',
      two: 'שתי שורות ללא שינוי',
      one: 'שורה אחת ללא שינוי',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'מעבר להודעה האחרונה';

  @override
  String get streaming => 'סטרימינג';

  @override
  String get working => 'עובד';

  @override
  String get input => 'קלט';

  @override
  String get output => 'פלט';

  @override
  String get now => 'עכשיו';

  @override
  String agoMinutes(int count) {
    return '$count דק׳';
  }

  @override
  String agoHours(int count) {
    return '$count שע׳';
  }

  @override
  String agoDays(int count) {
    return '$count ימ׳';
  }

  @override
  String get today => 'היום';

  @override
  String get tomorrow => 'מחר';

  @override
  String get yesterday => 'אתמול';

  @override
  String durationMinutes(int count) {
    return '$count דק׳';
  }

  @override
  String durationHours(int count) {
    return '$count שע׳';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours שע׳ $minutes דק׳';
  }

  @override
  String get mobileConversations => 'שיחות';

  @override
  String get mobileNewConversation => 'שיחה חדשה';

  @override
  String get mobileConversationName => 'שם השיחה';

  @override
  String get mobileRename => 'שינוי שם';

  @override
  String get mobileManageSpace => 'ניהול המרחב';

  @override
  String get mobileArchived => 'בארכיון';

  @override
  String get mobileSearchMessages => 'חיפוש בכל ההודעות במרחב הזה';

  @override
  String get mobileSearch => 'חיפוש';

  @override
  String get mobileNoResults => 'אין תוצאות';

  @override
  String get mobileReopen => 'פתח מחדש';

  @override
  String get mobileArchive => 'העברה לארכיון';

  @override
  String get mobileProgress => 'התקדמות והקשר';

  @override
  String get mobileReadFailed => 'לא ניתן לסמן את השיחה כנקראה';

  @override
  String get mobileSendFailed => 'ההודעה לא נשלחה. הטיוטה שלך נשמרה.';

  @override
  String get sentAttachmentUnavailable => 'הקובץ המצורף אינו זמין';

  @override
  String get sentAttachmentLoadFailed => 'לא ניתן לטעון את הקובץ המצורף';

  @override
  String get mobileActionFailed => 'הפעולה נכשלה';

  @override
  String get mobileRemove => 'הסר';

  @override
  String get mobileLinkedMessage => 'הודעה מקושרת';

  @override
  String get mobileOlderMessages => 'הודעות קודמות';

  @override
  String get mobileMessageActions => 'פעולות בהודעה';

  @override
  String get mobileOpenThread => 'פתיחת השרשור';

  @override
  String get mobileCopyLink => 'העתקת קישור';

  @override
  String get mobileStopRun => 'עצור הרצה';

  @override
  String get mobileStopRunConfirm =>
      'לעצור את הרצת הסוכן? העבודה שכבר הושלמה תישמר.';

  @override
  String get mobileControlUnsupported =>
      'ההרצה הסתיימה או אינה תומכת בפעולה הזאת.';

  @override
  String get mobilePauseRequested => 'התבקשה השהיה בסוף הסבב הבא';

  @override
  String get mobileResumed => 'ההרצה חודשה';

  @override
  String get mobileStopRequested => 'התבקשה עצירה';

  @override
  String get mobileQueuedMessages => 'הודעות בתור';

  @override
  String get mobilePauseRun => 'השהיה בסבב הבא';

  @override
  String get mobileResumeRun => 'המשך';

  @override
  String get mobileEditQueued => 'עריכת הודעה בתור';

  @override
  String get mobileSteerNow => 'הנחיה מיידית';

  @override
  String get mobileMoveUp => 'העברה למעלה';

  @override
  String get mobileMoveDown => 'העברה למטה';

  @override
  String get mobileQueueChanged =>
      'התור השתנה, או שההרצה אינה מקבלת הנחיות בזמן אמת. יש לרענן ולנסות שוב.';

  @override
  String get mobileActivity => 'פעילות';

  @override
  String get mobilePermissions => 'הרשאות וביקורת';

  @override
  String get mobilePlans => 'תוכניות';

  @override
  String get mobileGoals => 'יעדים מפוקחים';

  @override
  String get mobileCredentials => 'חיבורים ופרטי גישה';

  @override
  String get mobileWorkspaceUnavailable =>
      'סביבת העבודה אינה זמינה, או שכבר אין לך גישה אליה.';

  @override
  String get mobilePrReviewThreads => 'שרשורי סקירה';

  @override
  String get mobilePrThreadsLoadFailed => 'לא ניתן לטעון שרשורי סקירה';

  @override
  String get mobilePrNoReviewThreads => 'אין עדיין שרשורי סקירה בתוך הקוד';

  @override
  String get mobilePrCommentPermissionDenied => 'אין לך הרשאה להגיב במאגר הזה.';

  @override
  String get mobilePrPermissionChecking => 'בודק הרשאות לתגובות…';

  @override
  String get mobilePrPermissionLoadFailed =>
      'לא ניתן לבדוק הרשאות לתגובות. יש לנסות שוב כדי להגיב.';

  @override
  String mobilePrThreadLine(String side, String line) {
    return '$side, שורה $line';
  }

  @override
  String get mobilePrOriginalSide => 'מקורי';

  @override
  String get mobilePrSelectCommentLine => 'בחרו שורה להוספת תגובה';

  @override
  String get mobilePrUpdatedSide => 'עודכן';

  @override
  String get mobilePrThreadResolved => 'נפתר';

  @override
  String get mobilePrReplyHint => 'כתיבת תשובה…';

  @override
  String get mobilePrCommentRequired => 'יש לכתוב תגובה לפני הפרסום.';

  @override
  String get mobilePrReply => 'השבה';

  @override
  String get mobilePrReopenThread => 'פתיחת השרשור מחדש';

  @override
  String get mobilePrResolveThread => 'פתרון השרשור';

  @override
  String get mobilePrResolvePermissionDenied =>
      'רק מי שיצר את בקשת המשיכה או בעל הרשאת כתיבה יכולים לפתור את השרשור הזה.';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return 'תגובה על $side, שורה $line';
  }

  @override
  String get mobilePrInlineCommentHint => 'כתיבת תגובה בתוך הקוד…';

  @override
  String get mobilePrPostInlineComment => 'פרסום התגובה';

  @override
  String get mobilePrCommentUnavailable =>
      'תגובות בתוך הקוד אינן זמינות לבקשת המשיכה הזאת.';

  @override
  String get mobilePrPatchUnavailable =>
      'שירות המאגר לא סיפק תיקון טקסט לקובץ הזה.';

  @override
  String get mobilePrNoPatchForFile => 'התיקון לקובץ הזה אינו זמין.';

  @override
  String get mobileTicketNew => 'כרטיס חדש';

  @override
  String get mobileTicketCreate => 'יצירת כרטיס';

  @override
  String get mobileTicketEdit => 'עריכת כרטיס';

  @override
  String get mobileTicketTitle => 'כותרת';

  @override
  String get mobileTicketTitleRequired => 'יש להזין כותרת כדי לשמור את הכרטיס.';

  @override
  String get mobileTicketDescription => 'תיאור';

  @override
  String get mobileTicketMarkdownHint => 'הוספת פרטים ב-Markdown';

  @override
  String get mobileTicketPriority => 'עדיפות';

  @override
  String get mobileTicketPriorityNone => 'ללא עדיפות';

  @override
  String get mobileTicketPriorityUrgent => 'דחופה';

  @override
  String get mobileTicketPriorityHigh => 'גבוה';

  @override
  String get mobileTicketPriorityMedium => 'בינוני';

  @override
  String get mobileTicketPriorityLow => 'נמוך';

  @override
  String get mobileTicketLabels => 'תוויות';

  @override
  String get mobileTicketLabelsHint => 'תווית אחת בכל שורה';

  @override
  String get mobileTicketLabelsHelp => 'יש להזין כל תווית בשורה נפרדת.';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return 'נפתח ב-$provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => 'ללא אחראי';

  @override
  String get mobileTicketAssignedFilter => 'הוקצו';

  @override
  String get mobileTicketAgentsLoadFailed => 'לא ניתן לטעון סוכנים';

  @override
  String get mobileTicketSearch => 'חיפוש כרטיסים';

  @override
  String get mobileTicketSearchHint => 'כותרת, מזהה, תיאור, תווית או אחראי';

  @override
  String get mobileTicketClearSearch => 'ניקוי החיפוש בכרטיסים';

  @override
  String get mobileTicketNoMatches => 'אין כרטיסים תואמים';

  @override
  String get mobileTicketAdjustFilters =>
      'אפשר לנסות חיפוש אחר או לשנות את המסננים.';

  @override
  String get mobileTicketClearFilters => 'נקה מסננים';

  @override
  String get mobileTicketNotFound => 'הכרטיס לא נמצא';

  @override
  String get mobileTicketNotFoundDescription =>
      'ייתכן שהכרטיס נמחק או הועבר מסביבת העבודה הזאת.';

  @override
  String get mobileTicketWorkspaceChanged =>
      'סביבת העבודה השתנתה. יש לחזור לסביבת העבודה הנוכחית לפני השמירה.';

  @override
  String get mobileTicketOpenLinkedSpace => 'פתיחת המרחב המקושר';

  @override
  String get mobileTicketReadOnly =>
      'כדי לשנות כרטיסים נדרשת חברות בסביבת העבודה.';

  @override
  String get permissionTitle => 'הרשאות';

  @override
  String get permissionWorkspaceFailed => 'לא ניתן לטעון את סביבת העבודה';

  @override
  String get permissionNoWorkspace => 'יש לבחור סביבת עבודה כדי לבדוק הרשאות.';

  @override
  String get permissionLoading => 'טוען הרשאות…';

  @override
  String get permissionScopeDescription =>
      'כאן אפשר לראות כיצד מתקבלת החלטה לגבי כל פעולה בטווח הזה. סוכנים ומרחבים יכולים לרשת כללים מסביבת העבודה.';

  @override
  String get permissionScope => 'טווח המדיניות';

  @override
  String get permissionWorkspaceScope => 'סביבת עבודה';

  @override
  String get permissionAgentScope => 'סוכן';

  @override
  String get permissionSpaceScope => 'מרחב';

  @override
  String get permissionAgentContext => 'סוכן הפועל במרחב הזה';

  @override
  String get permissionNoAgentContext => 'לא נבחר סוכן';

  @override
  String get permissionTargetsFailed => 'לא ניתן לטעון יעדים בטווח הזה';

  @override
  String get permissionNoTargets => 'אין יעדים זמינים בטווח הזה.';

  @override
  String get permissionRoleFailed => 'לא ניתן לאמת את התפקיד שלך בסביבת העבודה';

  @override
  String get permissionMemberRequired =>
      'כדי להציג כללי מדיניות נדרשת חברות בסביבת העבודה.';

  @override
  String get permissionRulesFailed => 'לא ניתן לטעון כללי מדיניות';

  @override
  String get permissionAuditAdminOnly =>
      'היסטוריית ההרשאות זמינה למנהלי סביבת העבודה בלבד.';

  @override
  String get permissionAllow => 'אפשר';

  @override
  String get permissionAsk => 'שאל קודם';

  @override
  String get permissionDeny => 'חסום';

  @override
  String get permissionFileDelete => 'מחיקת קבצים';

  @override
  String get permissionFileWriteOutsideWorktree => 'כתיבה מחוץ לעץ העבודה';

  @override
  String get permissionGitCommit => 'ביצוע commit לשינויים';

  @override
  String get permissionGitPush => 'דחיפת commits';

  @override
  String get permissionPrCreate => 'יצירת בקשות משיכה';

  @override
  String get permissionPrPublish => 'עדכון בקשות משיכה או מיזוגן';

  @override
  String get permissionVendorSyncWrite => 'כתיבה בסנכרון עם ספק';

  @override
  String get permissionNetworkEgress => 'גישה לרשת';

  @override
  String get permissionSecretAccess => 'גישה לסודות';

  @override
  String get permissionPackageInstall => 'התקנת חבילות';

  @override
  String get permissionProcessSpawn => 'הפעלת תהליכים';

  @override
  String get permissionWorkspaceMutation => 'שינוי סביבת העבודה';

  @override
  String get permissionEnclosureControl => 'שליטה במתחם';

  @override
  String get permissionChangeFailed => 'לא ניתן לשנות את הכלל';

  @override
  String get permissionEffectiveDescription =>
      'ההחלטה החלה בטווח הזה ללא ארגומנטים של פעולה. ההרשאות המותנות שלהלן חלות רק על בקשות תואמות; השרת מקבל את ההחלטה הסופית.';

  @override
  String get permissionSpaceAgentNote =>
      'לא נבחר סוכן. כללים ייחודיים לסוכן יוצגו לאחר בחירת סוכן למעלה.';

  @override
  String get permissionScopedGrants => 'כללים בטווח הזה';

  @override
  String get permissionModePreset => 'ערכת מצב';

  @override
  String get permissionBuiltInDefault => 'ברירת מחדל מובנית';

  @override
  String get permissionRemembered => 'אישור מתמשך';

  @override
  String get permissionSource => 'מקור';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · הוגדר כאן';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · התקבל בירושה';
  }

  @override
  String permissionExpiresAt(String date) {
    return 'תוקף עד $date';
  }

  @override
  String get permissionSetHere => 'הגדרת כלל כאן';

  @override
  String get permissionConfirmRevoke => 'אישור ביטול';

  @override
  String get permissionRevokeRule => 'ביטול הכלל';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'קידומת פקודה: $prefix';
  }

  @override
  String get permissionNoExpiry => 'ללא תאריך תפוגה';

  @override
  String get permissionExpired => 'פג תוקפה';

  @override
  String get permissionExplicitRule => 'כלל מפורש';

  @override
  String get permissionEnforcementAdvisory =>
      'מצב מייעץ: כללי ״שאל קודם״ נרשמים ללא בקשת אישור';

  @override
  String get permissionEnforcementSoft => 'אכיפה גמישה: עקיפה דורשת הרשאה';

  @override
  String get permissionEnforcementHard => 'אכיפה קשיחה: אי אפשר לעקוף';

  @override
  String permissionPaths(String paths) {
    return 'נתיבים: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'הפניות Git: $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return 'מארחים: $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return 'פקודות: $commands';
  }

  @override
  String permissionTools(String tools) {
    return 'כלים: $tools';
  }

  @override
  String get permissionNotInEffect => 'לא בתוקף בזמן שפעולה זו חסומה';

  @override
  String permissionMaxCount(String count) {
    return 'מספר מרבי: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return 'מספר מרבי של סנטים: $cents';
  }

  @override
  String get permissionAuditHeading => 'היסטוריית הרשאות';

  @override
  String get permissionAuditDescription =>
      'החלטות אחרונות שנרשמו בשרת. רק מנהלים יכולים לעיין ביומן או לאמת את שרשרת הגיבובים שלו.';

  @override
  String permissionOnBehalfOf(String user) {
    return 'בשם $user';
  }

  @override
  String get permissionPrompted => 'התבקש אישור מאדם';

  @override
  String get permissionVerifyChain => 'אימות שרשרת הביקורת';

  @override
  String get permissionVerifyFailed => 'לא ניתן לאמת את שרשרת הביקורת';

  @override
  String permissionChainIntact(String count) {
    return 'השרשרת תקינה · נבדקו $count רשומות';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'השרשרת נקטעה ברשומה $sequence: $reason';
  }

  @override
  String get permissionAuditEmpty => 'טרם נרשמו החלטות הרשאה.';

  @override
  String get permissionAuditFailed => 'לא ניתן לטעון את היסטוריית ההרשאות';

  @override
  String get mobilePlansLoadFailed => 'לא ניתן לטעון תוכניות';

  @override
  String get mobilePlansEmpty => 'אין עדיין תוכניות';

  @override
  String get mobilePlansEmptyDescription =>
      'תוכניות שיגישו סוכנים יופיעו כאן לסקירה.';

  @override
  String get mobilePlanTitle => 'תכנון';

  @override
  String get mobilePlanMissing =>
      'התוכנית הזאת כבר אינה זמינה בסביבת העבודה הזאת.';

  @override
  String mobilePlanStepCount(int count) {
    return '$count שלבים';
  }

  @override
  String get mobilePlanDraft => 'טיוטה';

  @override
  String get mobilePlanProposed => 'ממתינה לסקירה';

  @override
  String get mobilePlanApproved => 'אושרה';

  @override
  String get mobilePlanRejected => 'נדחה';

  @override
  String get mobilePlanSuperseded => 'הוחלפה';

  @override
  String get mobilePlanExecuting => 'מבצע';

  @override
  String get mobilePlanSynthesizing => 'מסנתז';

  @override
  String get mobilePlanCompleted => 'הושלם';

  @override
  String get mobilePlanFailed => 'נכשלה';

  @override
  String get mobilePlanCancelled => 'בוטל';

  @override
  String mobilePlanRevision(String revision) {
    return 'גרסה $revision';
  }

  @override
  String get mobilePlanSteps => 'שלבים';

  @override
  String get mobilePlanNoSteps => 'לא הוגשו שלבים לתוכנית הזאת.';

  @override
  String get mobilePlanAssumptions => 'הבהרות';

  @override
  String mobilePlanDependsOn(String keys) {
    return 'תלוי ב-$keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return 'עלות מוערכת עד $cost';
  }

  @override
  String get mobilePlanSelect => 'בחר';

  @override
  String get mobilePlanSelected => 'נבחר';

  @override
  String get mobilePlanEstimate => 'הערכת עלות';

  @override
  String get mobilePlanEstimateRequired =>
      'יש להעריך את התוכנית לפני אישור הביצוע.';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return 'עלות מוערכת: $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => 'לא זמין';

  @override
  String get mobilePlanNoHardCap => 'ללא תקרה קשיחה';

  @override
  String get mobilePlanExceedsBudget =>
      'ההערכה חורגת מהתקציב שהוגדר. יש לבדוק אותה לפני האישור.';

  @override
  String get mobilePlanPartialEstimate =>
      'ההערכה הזאת כוללת את כל התוכנית; השלבים שנבחרו עשויים לעלות פחות.';

  @override
  String get mobilePlanConfirmAll => 'להתחיל את כל התוכנית?';

  @override
  String get mobilePlanConfirmSelected => 'להתחיל את השלבים שנבחרו?';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return 'האישור מתחיל את הביצוע ועלול לגרור חיובים. עלות מרבית מוערכת: $cost. תקרת תקציב: $cap.';
  }

  @override
  String get mobilePlanApproveAll => 'אישור הכול והפעלה';

  @override
  String get mobilePlanApproveSelected => 'אישור השלבים שנבחרו והפעלה';

  @override
  String get mobilePlanWiden => 'אישור שלבים נוספים';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return 'לאשר ביצוע של עוד $count שלבים? הם עשויים לגרור חיובים. תקרת העלות הקיימת לביצוע: $cap.';
  }

  @override
  String get mobilePlanChanged =>
      'התוכנית השתנתה במהלך הסקירה. יש לפתוח את הגרסה האחרונה ולהעריך אותה מחדש.';

  @override
  String get mobilePlanReject => 'דחיית התוכנית';

  @override
  String get mobilePlanRejectConfirm => 'לדחות את התוכנית? היא לא תבוצע.';

  @override
  String get mobilePlanStop => 'עצירת הביצוע';

  @override
  String get mobilePlanStopConfirm =>
      'לעצור את ביצוע התוכנית? העבודה שכבר הושלמה לא תבוטל.';

  @override
  String mobilePlanRunId(String runId) {
    return 'הרצת ביצוע: $runId';
  }

  @override
  String get mobilePlanExecutionPending =>
      'האישור התקבל. ממתינים לרישום הביצוע…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return 'הושלמו $completed מתוך $total שלבי ביצוע';
  }

  @override
  String get mobilePlanOpenConversation => 'פתיחת השיחה';

  @override
  String get mobileGoalsTitle => 'יעדים מפוקחים';

  @override
  String get mobileGoalsLoadFailed => 'לא ניתן לטעון יעדים מפוקחים';

  @override
  String get mobileGoalsEmpty => 'אין עדיין יעדים מפוקחים';

  @override
  String get mobileGoalsEmptyDescription =>
      'אפשר להתחיל יעד במרחב או לשלוח /goal בשיחה.';

  @override
  String get mobileGoalMissing => 'היעד הזה כבר אינו זמין בסביבת העבודה הזאת.';

  @override
  String get mobileGoalActive => 'פעיל';

  @override
  String get mobileGoalPaused => 'מושהה';

  @override
  String get mobileGoalCompleted => 'הושלם';

  @override
  String get mobileGoalFailed => 'נכשלה';

  @override
  String get mobileGoalCancelled => 'בוטל';

  @override
  String get mobileGoalBudgetExhausted => 'התקציב מוצה';

  @override
  String mobileGoalFailures(String count) {
    return 'הרצות רצופות שנכשלו: $count';
  }

  @override
  String get mobileGoalFailedDescription =>
      'המפקח עצר לאחר כישלונות חוזרים בהרצות. יש לעיין בשיחה לפרטים.';

  @override
  String get mobileGoalPause => 'השהיית היעד';

  @override
  String get mobileGoalResume => 'חידוש היעד';

  @override
  String get mobileGoalStop => 'ביטול היעד';

  @override
  String get mobileGoalStopConfirm =>
      'לבטל לצמיתות את היעד המפוקח? לא ניתן יהיה לחדש אותו.';

  @override
  String get mobileGoalRaiseBudget => 'הגדלת התקציב וחידוש';

  @override
  String mobileGoalRaiseTo(String amount) {
    return 'הגדלת התקציב ל-$amount וחידוש';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return 'להגדיל את תקרת העלות של היעד מ-$oldCap ל-$newCap ולחדש את ההוצאות?';
  }

  @override
  String get mobileGoalOpenConversation => 'פתיחת שיחת היעד';

  @override
  String get mobileGoalCreate => 'התחלת יעד מפוקח';

  @override
  String get mobileGoalChooseSpace => 'הרצה במרחב';

  @override
  String get mobileGoalNoSpaces => 'יש ליצור מרחב לפני שמתחילים יעד.';

  @override
  String get mobileGoalChooseAgent => 'הרצה עם סוכן';

  @override
  String get mobileGoalNoAgents => 'יש להוסיף סוכן פעיל לפני שמתחילים יעד.';

  @override
  String mobileGoalSelectedAgent(String name) {
    return 'נבחר $name';
  }

  @override
  String get mobileGoalObjectiveHint => 'איזו תוצאה הסוכן צריך להשיג?';

  @override
  String get mobileGoalBudgetUsd => 'תקרת עלות (USD)';

  @override
  String get mobileGoalCreateInvalid =>
      'יש לבחור מרחב וסוכן, להזין יעד ולהגדיר תקרת עלות חיובית בדולרים.';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return 'להתחיל יעד מפוקח בעלות מרבית של $cap? הסוכן עשוי להתחיל מיד.';
  }

  @override
  String get mobileGoalUnavailable =>
      'החיבור לשרת עדיין לא מוכן. יש לנסות שוב לאחר החיבור מחדש.';

  @override
  String get mobileGoalConversationMissing =>
      'השיחה שנבחרה כבר אינה זמינה בסביבת העבודה הזאת.';

  @override
  String get mobileGoalCreateSent =>
      'היעד התחיל. מצב הפיקוח יופיע ברשימה הזאת.';

  @override
  String get mobileGoalStartRefused =>
      'לא החלה הרצת יעד. אפשר לעיין בשיחה כדי להבין את סיבת הסירוב של המפקח.';

  @override
  String mobileGoalSelectedSpace(String name) {
    return 'נבחר $name';
  }

  @override
  String get requestUnavailable =>
      'הבקשה הזאת כבר אינה זמינה בסביבת העבודה הפעילה.';

  @override
  String get requestAlreadyResolved => 'הבקשה הזאת כבר טופלה.';

  @override
  String get inboxCredentialsBlocked => 'פרטי גישה חוסמים הרצות';

  @override
  String get inboxSyncFailures => 'סנכרונים שנכשלו מול ספקים';

  @override
  String get inboxConfigureCredentials => 'הגדרת פרטי גישה';

  @override
  String get openTicket => 'פתיחת הכרטיס';

  @override
  String get activityTitle => 'פעילות';

  @override
  String get activityClearAll => 'ניקוי הפעילות';

  @override
  String get activityClearConfirm =>
      'הפעולה תסתיר את כל הפעילות שנרשמה עבורך עד כה בכל המכשירים. פעילות חדשה עדיין תופיע.';

  @override
  String get activityMarkAllRead => 'סימון הכול כנקרא';

  @override
  String get activityMarkAllConfirm =>
      'לסמן את כל פריטי הפעילות בסביבת העבודה הזאת כנקראו בכל המכשירים שלך?';

  @override
  String get activityMarkRead => 'סימון כנקרא';

  @override
  String get activityMarkUnread => 'סימון כלא נקרא';

  @override
  String get activityDismiss => 'סגירה';

  @override
  String get activityResolved => 'נפתר';

  @override
  String get activityOpen => 'פתוחה';

  @override
  String get activityEmpty => 'אין פעילות עדיין';

  @override
  String get activityLoadFailed => 'לא ניתן לטעון את הפעילות';

  @override
  String get activityAgentWaiting => 'הסוכן ממתין לתגובה';

  @override
  String get activityAgentBlocked => 'פעולת הסוכן נחסמה';

  @override
  String get activityMessage => 'הודעה חדשה';

  @override
  String get activityPullRequest => 'עדכון בבקשת משיכה';

  @override
  String get activityRig => 'עדכון במתחם';

  @override
  String get activityEvent => 'עדכן';

  @override
  String get activityPrReady => 'בקשת המשיכה מוכנה למיזוג';

  @override
  String get activityPrBlocked => 'מיזוג בקשת המשיכה נחסם';

  @override
  String get activityPrApproved => 'בקשת המשיכה אושרה';

  @override
  String get activityPrChanges => 'התבקשו שינויים';

  @override
  String get activityPrChecksFailed => 'בדיקות בקשת המשיכה נכשלו';

  @override
  String get activityPrChecksRecovered => 'בדיקות בקשת המשיכה חזרו לפעול';

  @override
  String get activityPrComment => 'תגובה לבקשת משיכה';

  @override
  String get activityPrPublished => 'בקשת המשיכה פורסמה';

  @override
  String get activityPrMerged => 'בקשת המשיכה מוזגה';

  @override
  String get activityPrMentioned => 'אוזכרת בבקשת משיכה';

  @override
  String get activityPrReviewRequested => 'התבקשה סקירה';

  @override
  String get activityPrReviewStale => 'צריך לרענן את הסקירה';

  @override
  String get activityTicketAssigned => 'כרטיס הוקצה';

  @override
  String get activityTicketChanged => 'סטטוס הכרטיס השתנה';

  @override
  String get activityMeetingSoon => 'פגישה מתחילה בקרוב';

  @override
  String get activityCalendarExpired => 'פג תוקף החיבור ללוח השנה';

  @override
  String get activityRigControl => 'השליטה במתחם השתנתה';

  @override
  String get activityRigClosed => 'המתחם נעצר';

  @override
  String get mobileSpacesSearch => 'חיפוש מרחבים';

  @override
  String get mobileSpacesArchived => 'בארכיון';

  @override
  String get mobileSpacesActive => 'פעיל';

  @override
  String get mobileSpacesNew => 'מרחב חדש';

  @override
  String get mobileSpacesManage => 'ניהול המרחב';

  @override
  String get mobileSpacesName => 'שם המרחב';

  @override
  String get mobileSpacesAgents => 'סוכנים';

  @override
  String get mobileSpacesMembers => 'אנשים';

  @override
  String get mobileSpacesRepos => 'מאגרים';

  @override
  String get mobileSpacesAllRepos => 'כל המאגרים המקושרים';

  @override
  String get mobileSpacesNoRepos => 'אין מאגרים';

  @override
  String get mobileSpacesBaseBranch => 'ענף בסיס (אופציונלי)';

  @override
  String get mobileSpacesDefaultBranch => 'ענף ברירת מחדל';

  @override
  String get mobileSpacesMode => 'מצב';

  @override
  String get mobileSpacesModeChat => 'צ\'אט';

  @override
  String get mobileSpacesModeReview => 'סקירה (לקריאה בלבד)';

  @override
  String get mobileSpacesModePlan => 'תכנון (לקריאה בלבד)';

  @override
  String get mobileSpacesModeOrchestrate => 'תזמור';

  @override
  String get mobileSpacesAutonomy => 'דריסת רמת העצמאות';

  @override
  String get mobileSpacesAutonomyInherited => 'בירושה';

  @override
  String get mobileSpacesAutonomyPropose => 'הצעות בלבד';

  @override
  String get mobileSpacesAutonomyApproval => 'פעולה באישור';

  @override
  String get mobileSpacesAutonomyFreely => 'פעולה חופשית';

  @override
  String get mobileSpacesAutonomyNotice =>
      'דריסה אינה יכולה לעקוף בקשות אישור או סירובים של מדיניות הפעולות. רק מנהלי סביבת העבודה יכולים לשנות אותה.';

  @override
  String get mobileSpacesArchive => 'העברת המרחב לארכיון';

  @override
  String get mobileSpacesReopen => 'פתיחת המרחב מחדש';

  @override
  String get mobileSpacesSave => 'שמור שינויים';

  @override
  String get mobileSpacesCreate => 'יצירת מרחב';

  @override
  String get mobileSpacesOperationFailed => 'לא ניתן לעדכן את המרחב';

  @override
  String get mobileSpacesMissing => 'המרחב לא נמצא בסביבת העבודה הזאת';

  @override
  String get mobileSpacesEmptyName => 'יש להזין שם למרחב';

  @override
  String get mobileSpacesNoMatches => 'אין מרחבים תואמים';

  @override
  String get mobileSpacesUnread => 'תשובת סוכן שלא נקראה';

  @override
  String get mobileSpacesNeedsInput => 'נדרשת תגובתך';

  @override
  String get mobileSpacesRunning => 'סוכן פועל';

  @override
  String get mobileSpacesNoAgents => 'אין סוכנים בסביבת העבודה הזאת';

  @override
  String get mobileSpacesNoMembers => 'אין חברים נוספים בסביבת העבודה';

  @override
  String get mobileSpacesRepoError => 'לא ניתן לטעון מאגרים';

  @override
  String get mobileSpacesRetry => 'נסה שוב';

  @override
  String get mobileSpacesBranchUnavailable =>
      'יש לבחור או להזין ענף בסיס כשיוצרים מרחב; אי אפשר לשנות ענף בסיס של מרחב קיים.';

  @override
  String get mobileSpacesArchivedEmpty => 'אין מרחבים בארכיון';

  @override
  String get mobileSpacesAllRepoWarning =>
      'מאגרים שיקושרו לסביבת העבודה בעתיד ייכללו גם במרחב הזה.';

  @override
  String get mobileSpacesCreatedRetry =>
      'המרחב נוצר. אפשר לנסות שוב להוסיף אנשים או לפתוח את דף הניהול שלו.';

  @override
  String get progressTitle => 'התקדמות';

  @override
  String get progressConversation => 'שיחה';

  @override
  String get progressLoadFailed => 'לא ניתן לטעון את ההתקדמות';

  @override
  String get progressUnavailable => 'השיחה אינה זמינה';

  @override
  String get progressUnavailableDescription =>
      'השיחה הזאת אינה בסביבת העבודה ובמרחב הפעילים. יש לחזור למרחב שלה כדי להמשיך.';

  @override
  String get progressSaveFailed => 'לא ניתן לעדכן את ההתקדמות';

  @override
  String get progressGoal => 'מטרה';

  @override
  String get progressNoGoal => 'לא הוגדר יעד עבודה';

  @override
  String get progressSetGoal => 'הגדרת יעד';

  @override
  String get progressEditGoal => 'עריכת היעד';

  @override
  String get progressClearGoal => 'ניקוי היעד';

  @override
  String get progressGoalRequired => 'יש להזין יעד לפני השמירה.';

  @override
  String get progressTodos => 'משימות';

  @override
  String get transcriptToolTodos => 'משימות';

  @override
  String get transcriptToolSearchMemory => 'חיפוש בזיכרון';

  @override
  String get transcriptToolRenderMedia => 'הצגת מדיה';

  @override
  String get progressNoTodos => 'אין עדיין משימות';

  @override
  String get progressNewTodo => 'משימה חדשה';

  @override
  String get progressAddTodo => 'הוספת משימה';

  @override
  String get progressEditTodo => 'עריכת משימה';

  @override
  String get progressTodoRequired => 'יש להזין משימה לפני השמירה.';

  @override
  String get progressTodoNoLongerExists =>
      'המשימה הוסרה. יש לטעון מחדש את הרשימה ולנסות שוב.';

  @override
  String get progressWorkspaceChanged =>
      'סביבת העבודה הפעילה השתנתה. יש לחזור לשיחה הזאת ולנסות שוב.';

  @override
  String progressRemoveTodo(String name) {
    return 'הסרת המשימה $name';
  }

  @override
  String get progressPending => 'ממתין';

  @override
  String get progressInProgress => 'בתהליך';

  @override
  String get progressCompleted => 'הושלם';

  @override
  String get progressMoveUp => 'העברת המשימה למעלה';

  @override
  String get progressMoveDown => 'העברת המשימה למטה';

  @override
  String get progressRunTree => 'הרצות סוכנים';

  @override
  String get progressNoRuns => 'אין עדיין הרצות בשיחה הזאת';

  @override
  String get progressRunning => 'פועל';

  @override
  String get progressFailed => 'נכשלה';

  @override
  String get progressUnknown => 'לא ידוע';

  @override
  String get progressHealthy => 'פעיל';

  @override
  String get progressBlocked => 'חסום';

  @override
  String get progressLooping => 'בלולאה';

  @override
  String get progressStalled => 'תקוע';

  @override
  String get progressDead => 'נעצר באופן בלתי צפוי';

  @override
  String get progressQuiet => 'אין עדיין פלט';

  @override
  String get progressCostReported => 'חיוב שדיווח הספק';

  @override
  String get progressCostNotional => 'מחיר מחירון משוער למינוי; אינו חשבונית';

  @override
  String get progressCostMixed => 'מקורות עלות מעורבים';

  @override
  String get progressCostEstimated => 'עלות מוערכת';

  @override
  String progressDurationSeconds(String seconds) {
    return '$seconds שנ׳';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'מודל: $model · משך: $duration · עלות: $cost';
  }

  @override
  String progressStartedAt(String time) {
    return 'התחיל $time';
  }

  @override
  String progressLiveness(String state) {
    return 'מצב: $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return 'קלט: $input · פלט: $output טוקנים';
  }

  @override
  String get progressOutputPreviewLimited =>
      'מוצגים רק 6,000 התווים הראשונים של הפלט המובנה.';

  @override
  String progressRetryOf(String runId) {
    return 'ניסיון חוזר של הרצה $runId';
  }

  @override
  String get progressContext => 'הקשר ומגבלות';

  @override
  String get progressNoAgent => 'אין סוכן לבדיקה';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window טוקנים';
  }

  @override
  String get progressMeasured => 'הקשר שדווח בידי הספק בקריאה האחרונה';

  @override
  String get progressEstimated => 'הערכה מתוך השיחה השמורה וההקשר הקבוע';

  @override
  String get progressContextUnknown => 'עדיין לא דווח על שימוש בהקשר';

  @override
  String progressContextPercent(String percent) {
    return '$percent% מחלון ההקשר';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return 'מגבלה חודשית מוגדרת לסוכן: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return 'שיחה פעילה שמורה: כ-$tokens טוקנים';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return 'הקשר קבוע עבור $agent · $model';
  }

  @override
  String get progressContextSystem => 'הנחיית מערכת';

  @override
  String get progressContextRules => 'כללים';

  @override
  String get progressContextSkills => 'מיומנויות';

  @override
  String get progressContextTools => 'הגדרות כלים';

  @override
  String get progressContextMcp => 'כלי MCP';

  @override
  String get progressContextDeferred => 'כלים מושהים';

  @override
  String get progressContextSubagents => 'תתי-סוכנים';

  @override
  String get progressContextRunner => 'מריץ חיצוני';

  @override
  String get progressContextMemory => 'זיכרון';

  @override
  String get progressContextHistory => 'היסטוריית השיחה';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens טוקנים';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens טוקנים';
  }

  @override
  String get progressOutputs => 'פלטים אחרונים';

  @override
  String get progressNoOutputs => 'אין פלטים אחרונים של סוכנים';

  @override
  String get progressStructuredOutputsAbove =>
      'הפלטים המובנים של ההרצות מוצגים למעלה.';

  @override
  String get progressRecentOutputsOnly =>
      'מוצגות הודעות אחרונות בלבד. יש לפתוח את השיחה כדי לראות עבודה קודמת.';

  @override
  String get progressPlan => 'תכנון';

  @override
  String get progressArtifact => 'תוצר';

  @override
  String get progressResult => 'תוצאה';

  @override
  String get progressHideArtifact => 'הסתרת התוצר';

  @override
  String get progressReadArtifact => 'קריאת התוצר';

  @override
  String get progressArtifactUnavailable => 'התוצר כבר אינו זמין';

  @override
  String get progressArtifactPreviewLimited =>
      'מוצגת תצוגה מקדימה מוגבלת של התוצר.';

  @override
  String get progressDiagramSource => 'מקור התרשים';

  @override
  String progressOpenAttachment(String name) {
    return 'פתיחת $name';
  }

  @override
  String get progressOpenPlan => 'פתיחת התוכנית';

  @override
  String progressOpenDiff(String label) {
    return 'סקירת קבצים ששונו: $label';
  }

  @override
  String get progressViewMessage => 'הצגת ההודעה';

  @override
  String get pushTitle => 'התראות ברקע';

  @override
  String get pushIntro =>
      'אפשר לקבל התראה פרטית כשמשהו דורש את תשומת לבך, גם כשהאפליקציה סגורה. הפרטים נשארים בחיבור המוצפן שלך.';

  @override
  String get pushLoading => 'בודק הגדרות התראות…';

  @override
  String get pushError =>
      'לא ניתן לעדכן את ההתראות. יש לבדוק את החיבור ולנסות שוב.';

  @override
  String get pushEnable => 'הפעלת התראות';

  @override
  String get pushDisable => 'כיבוי ההתראות';

  @override
  String get pushQuiet => 'השהיית ההתראות במכשיר הזה';

  @override
  String get pushCategories => 'לקבל התראות על';

  @override
  String get pushCategoryAgents => 'סוכנים';

  @override
  String get pushCategoryMessages => 'הודעות';

  @override
  String get pushCategoryPullRequests => 'בקשות משיכה';

  @override
  String get pushCategoryTickets => 'כרטיסים';

  @override
  String get pushCategoryCalendar => 'לוח שנה';

  @override
  String get pushCategoryMachines => 'מכונות';

  @override
  String get pushSecureOrigin => 'התראות מחייבות HTTPS.';

  @override
  String get pushInstallIos =>
      'ב-iPhone או ב-iPad יש להוסיף את האפליקציה למסך הבית ולפתוח אותה משם כדי להפעיל התראות.';

  @override
  String get pushUnsupported => 'הדפדפן הזה אינו תומך בהתראות ברקע.';

  @override
  String get pushDenied =>
      'הדפדפן מדווח שההתראות חסומות. יש לבדוק את ההרשאה לאתר הזה ואת הגדרות ההתראות בדפדפן או במכשיר, ואז לרענן.';

  @override
  String get pushOsHint =>
      'הדפדפן צריך גם הרשאה להציג התראות בהגדרות המערכת של המכשיר.';

  @override
  String get pushServiceUnavailable =>
      'שירות ה-push של הדפדפן דחה את המינוי. דפדפנים מסוימים, כמו Brave, מכבים אותו כברירת מחדל: חפשו אפשרות להודעות push בהגדרות הפרטיות של הדפדפן ונסו שוב.';

  @override
  String get pushWorkerUnavailable =>
      'לא ניתן היה להפעיל את שירות ההתראות בדפדפן הזה. טענו מחדש את הדף ונסו שוב.';

  @override
  String get pushResubscribe => 'חיבור מחדש להתראות';

  @override
  String get pushStatusEnabled => 'ההתראות פועלות במכשיר הזה.';

  @override
  String get pushStatusDisabled => 'ההתראות כבויות במכשיר הזה.';

  @override
  String get credentialsTitle => 'חיבורים ופרטי גישה';

  @override
  String get credentialsIntro =>
      'יש לחבר את החשבונות שבהם משתמשים ההרצות והשילובים שלך. פרטי גישה סודיים נשמרים בשרת שלך, לא בטלפון הזה.';

  @override
  String get credentialsModelProviders => 'ספקי מודלים';

  @override
  String get credentialsOwnerOnly =>
      'רק הבעלים של השרת יכולים להוסיף, לחבר או להסיר פרטי גישה לספקי מודלים. המפתחות האלה משותפים לכל סביבות העבודה.';

  @override
  String get credentialsContactOwner =>
      'יש לבקש מהבעלים של השרת לחבר את הספק שנדרש להרצה החסומה שלך.';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'ההתחברות ל-Claude Code מתבצעת דרך ממשק שורת הפקודה במחשב המארח. יש לבקש מהבעלים של השרת להשלים או לחדש את ההתחברות לחשבון במסוף של המארח; אי אפשר לעשות זאת בטלפון הזה.';

  @override
  String get credentialsYourForgeAccounts => 'חשבונות שירותי המאגרים שלך';

  @override
  String get credentialsYourTicketingAccount => 'חשבון ניהול הכרטיסים שלך';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'כרטיסים מקומיים אינם דורשים התחברות. אם סביבת העבודה שלך משתמשת ב-Linear, אפשר לחבר אותו כאן.';

  @override
  String get credentialsMembershipRequired =>
      'יש להצטרף לסביבת עבודה כדי לנהל את פרטי הגישה שלך לשירותי מאגרים או לניהול כרטיסים. יש לבקש גישה ממנהל סביבת העבודה.';

  @override
  String get credentialsSwitchWorkspace =>
      'הקישור הזה מפנה לסביבת עבודה אחרת. יש לעבור אליה לפני שמשנים פרטי גישה.';

  @override
  String get credentialsReturnToInbox =>
      'אחרי חיבור פרטי הגישה, אפשר לחזור לתיבת הדואר הנכנס ולנסות שוב להריץ את הפעולה שנחסמה. המארח בודק גם הרצות מושהות באופן אוטומטי.';

  @override
  String get credentialsLoadFailed =>
      'לא ניתן לטעון חיבורים. יש לבדוק את החיבור לשרת ולנסות שוב.';

  @override
  String get credentialsOperationFailed =>
      'לא ניתן לשנות את החיבור הזה. יש לבדוק את החיבור לשרת, את הגישה שלך ואת פרטי הגישה, ולנסות שוב.';

  @override
  String get credentialsConnected => 'מחובר';

  @override
  String get credentialsNotConnected => 'לא מחובר';

  @override
  String credentialsSignedInAs(String username) {
    return 'מחובר בתור $username';
  }

  @override
  String get credentialsAccount => 'חשבון מחובר';

  @override
  String get credentialsStoredKey => 'מפתח שמור';

  @override
  String get credentialsActive => 'פעיל';

  @override
  String get credentialsRemove => 'הסר';

  @override
  String get credentialsRemoveConfirm =>
      'להסיר את פרטי הגישה השמורים שלך? ייתכן שיהיה צורך להתחבר שוב.';

  @override
  String get credentialsApiKey => 'מפתח API';

  @override
  String get credentialsApiKeyHint => 'יש להדביק מפתח API של הספק';

  @override
  String get credentialsBrowserLogin => 'התחברות דרך הדפדפן';

  @override
  String get credentialsSignInAgain => 'יש להתחבר שוב';

  @override
  String get credentialsWaitingForLogin => 'ממתינים לאישור בדפדפן שלך…';

  @override
  String get credentialsConnectCodePrompt => 'קוד אישור';

  @override
  String get credentialsConnectCodeMalformed =>
      'זה לא נראה כמו קוד כניסה. קודים כוללים 8 אותיות וספרות.';

  @override
  String get credentialsSignInInvalidCode =>
      'הקוד הזה לא תואם לכניסה הזו. בדקו אותו ונסו שוב.';

  @override
  String get credentialsSignInTooManyCodes =>
      'יותר מדי קודים שגויים. התחילו את ההתחברות מחדש.';

  @override
  String get credentialsSignInRetryLater =>
      'שירות ההתחברות לא מגיב כרגע. המתינו דקה ונסו שוב.';

  @override
  String get credentialsSignInRefused =>
      'ההתחברות נדחתה. התחילו אותה מחדש ואשרו את כל ההרשאות המבוקשות.';

  @override
  String get credentialsSignInNotSaved =>
      'ההתחברות הצליחה, אבל השרת לא הצליח לשמור אותה. נסו שוב.';

  @override
  String credentialsSignInUnavailable(String provider) {
    return 'הכניסה ל-$provider עדיין לא הוגדרה בשרת הזה.';
  }

  @override
  String get credentialsSignInPhoneUnreachable =>
      'כתובת החזרה של ההתחברות בשרת הזה אינה נגישה באופן מאובטח מטלפון. התחברו מאפליקציית המחשב, או בקשו מבעל השרת להגדיר כתובת HTTPS ציבורית.';

  @override
  String get credentialsLoginTimedOut =>
      'תוקף ההתחברות פג. יש להתחיל ניסיון התחברות חדש.';

  @override
  String get credentialsCopyCode => 'העתקת הקוד';

  @override
  String get credentialsDeviceCodeHint =>
      'יש לאשר את הקוד הזה בדף של הספק. חשוב להשאיר את המסך פתוח בזמן שהשרת משלים את ההתחברות.';

  @override
  String get credentialsPasteRedirect => 'קוד הרשאה או כתובת URL להפניה מחדש';

  @override
  String get credentialsPasteRedirectHint =>
      'יש להדביק את הקוד או את כתובת ה-URL המלאה להפניה מחדש מהספק';

  @override
  String get credentialsCompleteLogin => 'השלמת ההתחברות';

  @override
  String get credentialsUpdateToken => 'עדכון אסימון גישה';

  @override
  String get credentialsAddToken => 'הוספת אסימון גישה';

  @override
  String get credentialsPersonalToken => 'אסימון גישה אישי';

  @override
  String get credentialsPersonalTokenHint => 'יש להדביק אסימון גישה אישי';

  @override
  String get credentialsStopWatching => 'הפסקת המעקב';

  @override
  String get transcriptClaudeSignInExpiredTitle =>
      'תוקף הכניסה ל-Claude Code פג';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      'הריצה נעצרה כי החשבון שלה כבר לא עובר אימות. היכנסו שוב ואז נסו שוב את התור.';

  @override
  String get transcriptSignInExpiredTitle => 'תוקף הכניסה לספק פג';

  @override
  String get transcriptSignInExpiredBody =>
      'הריצה נעצרה כי פרטי ההתחברות של הספק כבר לא עובדים. חברו אותו מחדש בהגדרות ← ספקים ואז נסו שוב את התור.';

  @override
  String get permissionHostExecution => 'הרצת פקודות במארח';

  @override
  String credentialsSignInLapsed(String provider) {
    return 'תוקף הכניסה שלכם ל-$provider פג. היכנסו שוב.';
  }

  @override
  String get credentialsSignInPaused =>
      'מושהה: שירות הכניסה של סביבת העבודה הזו השתנה. הכניסה תעבוד שוב כשהשירות יחזור.';

  @override
  String credentialsProviderUnreachable(String provider) {
    return 'אין גישה ל-$provider כרגע. מנסים שוב.';
  }

  @override
  String get credentialsScopeWorkspace => 'רק סביבת העבודה הזו';

  @override
  String get credentialsScopeAllWorkspaces => 'כל סביבות העבודה';

  @override
  String get credentialsRemoveConfirmWorkspace =>
      'להסיר את פרטי ההתחברות השמורים מסביבת העבודה הזו? סביבות עבודה אחרות שומרות על שלהן.';

  @override
  String get credentialsRemoveConfirmAllWorkspaces =>
      'להסיר את פרטי ההתחברות השמורים מכל סביבות העבודה שמשתפות אותם?';

  @override
  String get credentialsSignInServerRestarted =>
      'השרת הופעל מחדש. התחילו את הכניסה מחדש.';

  @override
  String repoAccessInstallApp(String owner, String names) {
    return 'התקינו את GitHub App ב-$owner כדי שהאוטומציה תגיע אל $names. הקישו כדי לפתוח את GitHub.';
  }

  @override
  String repoAccessAskAdminInstall(String owner, String names) {
    return 'GitHub App לא מותקנת ב-$owner, ולכן האוטומציה לא מגיעה אל $names. בקשו ממנהל של סביבת העבודה להתקין אותה.';
  }

  @override
  String repoAccessAddToApp(String names) {
    return 'הוסיפו את $names למאגרים של GitHub App. הקישו כדי לפתוח את GitHub.';
  }

  @override
  String repoAccessAskAdminAdd(String names) {
    return 'GitHub App עדיין לא רואה את $names. בקשו ממנהל של סביבת העבודה להוסיף אותם למאגרים שלה.';
  }

  @override
  String repoAccessSuspended(String names) {
    return 'התקנת GitHub App הושעתה. האוטומציה עבור $names מושהית עד שאחד מבעלי החשבון יחדש את ההתקנה ב-GitHub.';
  }

  @override
  String repoAccessOwnerCannotSee(String names) {
    return 'האדם האחראי על האוטומציה של סביבת העבודה הזו כבר לא רואה את $names, ולכן שום דבר לא רץ שם בשמו.';
  }

  @override
  String repoAccessOwnerNotSignedIn(String names) {
    return 'האדם האחראי על האוטומציה של סביבת העבודה הזו לא מחובר לפלטפורמת הקוד, ולכן האוטומציה עבור $names ממתינה עד שיתחבר.';
  }

  @override
  String repoAccessRetrying(String names) {
    return 'לא ניתן היה לבדוק את הגישה אל $names. מנסים שוב.';
  }

  @override
  String hiddenReposSignIn(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'היכנסו ל-$forge כדי לראות בקשות משיכה מעוד $count מאגרים',
      one: 'היכנסו ל-$forge כדי לראות בקשות משיכה ממאגר נוסף אחד',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoForgeAccess(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count מאגרים מוסתרים כי החשבון שלכם ב-$forge לא רואה אותם',
      one: 'מאגר אחד מוסתר כי החשבון שלכם ב-$forge לא רואה אותו',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoGrant(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count מאגרים מוסתרים כי אין לכם גישה אליהם בסביבת העבודה הזו',
      one: 'מאגר אחד מוסתר כי אין לכם גישה אליו בסביבת העבודה הזו',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposChecking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'בודקים את הגישה שלכם לעוד $count מאגרים…',
      one: 'בודקים את הגישה שלכם למאגר נוסף אחד…',
    );
    return '$_temp0';
  }

  @override
  String get credentialsAtlassianEmail => 'האימייל של חשבון Atlassian';

  @override
  String get credentialsAtlassianEmailInvalid =>
      'הזינו את כתובת האימייל של חשבון Atlassian שלכם.';

  @override
  String get credentialsBitbucketApiToken => 'אסימון API';

  @override
  String repoAccessAutomationTokenMissing(String names) {
    return 'אף אסימון אוטומציה לא יכול לקרוא את $names, לכן עבודת הרקע שם מושהית. מנהל יכול להוסיף אסימון בהגדרות ← מאגרים.';
  }

  @override
  String get credentialsSignInConfirmInBrowser =>
      'אשרו בדפדפן, ואז הזינו את הקוד שהוא מציג בשדה שלמטה.';

  @override
  String get credentialsSignInAccountAlreadyBound =>
      'החשבון הזה כבר מחובר לאדם אחר בשרת הזה. היכנסו עם חשבון אחר.';

  @override
  String credentialsTokenUnreachable(String provider) {
    return 'לא ניתן להגיע ל־$provider כדי לבדוק את האסימון הזה. נסו שוב בעוד רגע.';
  }

  @override
  String credentialsTokenRejected(String provider) {
    return '$provider לא מקבל את האסימון הזה. בדקו שהעתקתם אותו במלואו ושהוא לא בוטל.';
  }

  @override
  String credentialsTokenWrongKind(String provider) {
    return 'זה לא אסימון אישי. הדביקו אסימון גישה אישי מהחשבון שלכם ב־$provider, ולא אסימון של פרויקט, קבוצה, סביבת עבודה או בוט.';
  }

  @override
  String credentialsTokenNarrowScope(String scope) {
    return 'לאסימון חסרה ההרשאה $scope, שנדרשת לסקירה ולהערות. צרו אסימון שכולל אותה.';
  }

  @override
  String get credentialsTokenExpired =>
      'האסימון הזה פג. צרו חדש והדביקו אותו כאן.';

  @override
  String get credentialsSignInRateLimited =>
      'יותר מדי בקשות כרגע. המתינו רגע ונסו שוב.';

  @override
  String get credentialsSignInCancelled =>
      'הכניסה בוטלה או נדחתה. התחילו אותה מחדש כשתהיו מוכנים.';

  @override
  String get credentialsSignInNoLongerOpen =>
      'הכניסה הזו כבר לא פתוחה: היא בוטלה, נוצלה או הוחלפה. התחילו אותה מחדש.';

  @override
  String get noWorkspacesYetHint =>
      'מנהל סביבת עבודה צריך להזמין אתכם, או שבעל השרת יכול ליצור עבורכם סביבת עבודה.';

  @override
  String repoAccessReplaced(String repos, String forge) {
    return '$repos מצביע כעת על מאגר אחר ב־$forge. קשרו אותו מחדש מאפליקציית שולחן העבודה או מהאתר כדי להמשיך להשתמש בו.';
  }

  @override
  String repoAccessAskAdminRelink(String repos, String forge) {
    return '$repos מצביע כעת על מאגר אחר ב־$forge. מנהל סביבת עבודה צריך לקשר אותו מחדש לפני שאפשר להשתמש בו שוב.';
  }

  @override
  String get runSandboxUnavailableTitle => 'סוכנים צריכים ארגז חול בשרת הזה';

  @override
  String get runSandboxUnavailable =>
      'לשרת הזה אין ארגז חול, ולכן רק בעליו יכולים להפעיל כאן סוכנים. הבעלים יכול להתקין את ארגז החול או לכבות את הבידוד לכולם.';

  @override
  String get scriptToolCalls => 'קריאות כלים';

  @override
  String scriptCallCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count קריאות',
      two: 'שתי קריאות',
      one: 'קריאה אחת',
    );
    return '$_temp0';
  }

  @override
  String scriptCallsRunning(int count) {
    return '$count פועלות';
  }

  @override
  String scriptCallsOk(int count) {
    return '$count תקינות';
  }

  @override
  String scriptCallsFailed(int count) {
    return '$count נכשלו';
  }

  @override
  String scriptCallsDenied(int count) {
    return '$count נדחו';
  }

  @override
  String scriptCallsCancelled(int count) {
    return '$count בוטלו';
  }

  @override
  String scriptCallsQueued(int count) {
    return '$count בתור';
  }

  @override
  String scriptCallsSkipped(int count) {
    return '$count דולגו';
  }

  @override
  String get scriptStepQueued => 'ממתין בתור';

  @override
  String get scriptStepSkipped => 'דולג';

  @override
  String get scriptGroupLoop => 'לולאה';

  @override
  String get scriptGroupEach => 'לכל אחד';

  @override
  String get scriptGroupParallel => 'במקביל';

  @override
  String get scriptGroupFunction => 'פונקציה';

  @override
  String scriptCallsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'הצג $count קריאות נוספות',
      one: 'הצג קריאה נוספת אחת',
    );
    return '$_temp0';
  }

  @override
  String get scriptCallsUnplaced => 'קריאות שלא שובצו בסקריפט';

  @override
  String get scriptToolComputed => 'כלי';

  @override
  String scriptStepSemantics(String subject, String state) {
    return '$subject, $state';
  }

  @override
  String get scriptSourceLabel => 'סקריפט';

  @override
  String scriptSourceLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count שורות',
      two: 'שתי שורות',
      one: 'שורה אחת',
    );
    return '$_temp0';
  }

  @override
  String get scriptStateRunning => 'פועל';

  @override
  String get scriptStateCompleted => 'הושלם';

  @override
  String get scriptStateFailed => 'נכשל';

  @override
  String get scriptStateTimedOut => 'הזמן תם';

  @override
  String get scriptStateCancelled => 'בוטל';

  @override
  String get scriptStateMemoryExceeded => 'חריגה מהזיכרון';

  @override
  String get scriptStateOutputExceeded => 'פלט גדול מדי';

  @override
  String get scriptStateSandboxError => 'שגיאת ארגז חול';

  @override
  String get scriptStateRefused => 'נדחה';

  @override
  String get scriptOriginLine => 'מסקריפט שהסוכן מריץ';

  @override
  String get codeModeTitle => 'מצב קוד';

  @override
  String get codeModeAvailable => 'זמין';

  @override
  String get codeModeUnavailable => 'לא זמין';

  @override
  String codeModeUnavailableNote(String reason) {
    return 'השרת הזה לא יכול להריץ סקריפטים, ולכן סוכנים כאן קוראים לכלים שלהם אחד אחד. השרת מציין: $reason';
  }

  @override
  String get codeModeNoReason => 'לא סופקה סיבה.';

  @override
  String get workKindUnknown => 'מסיבה שהגרסה הזו לא מזהה:';

  @override
  String get workRefusalUnknown => 'השרת דחה את זה:';

  @override
  String workActionFailed(String error) {
    return 'זה לא עבד: $error';
  }

  @override
  String get wakeKindStopped => 'הוחזקה כי אדם עצר את ההרצה.';

  @override
  String get wakeKindAttempts => 'המסירה נכשלה שלוש פעמים.';

  @override
  String get wakeKindAgentDeleted => 'הסוכן כבר לא קיים.';

  @override
  String get wakeKindAgentNotDispatchable => 'הסוכן פרש.';

  @override
  String get wakeKindAgentPaused => 'הסוכן מושהה.';

  @override
  String get wakeKindPersonRemoved =>
      'האדם שבשמו היא פועלת עזב את סביבת העבודה.';

  @override
  String get wakeKindBudgetBlocked => 'תקציב חוסם הרצה.';

  @override
  String get wakeKindTakeOver => 'אדם השתלט על עץ העבודה.';

  @override
  String get wakeKindRateCapConversation =>
      'השיחה הזו התחילה 30 הרצות מהשכמות בשעה האחרונה.';

  @override
  String get wakeKindRateCapWorkspace =>
      'סביבת העבודה הזו התחילה 300 הרצות מהשכמות בשעה האחרונה.';

  @override
  String get wakeKindLiveRunNoInput =>
      'ההרצה החיה של הסוכן כאן אינה מקבלת קלט.';

  @override
  String get wakeKindLiveRunOtherOptions =>
      'ההרצה החיה של הסוכן כאן פועלת אחרת, לכן היא תתחיל הרצה משלה אחריה.';

  @override
  String get wakeKindLiveRunOtherPerson =>
      'ההרצה החיה של הסוכן כאן פועלת בשם אדם אחר, לכן היא תתחיל הרצה משלה אחריה.';

  @override
  String get wakeKindDispatchRefused => 'לא ניתן היה להתחיל את ההרצה.';

  @override
  String get wakeKindSandboxUnavailable =>
      'אין ארגז חול זמין להרצה לקריאה בלבד.';

  @override
  String get wakeKindReadOnlyUnavailable =>
      'הבאקאנד של הסוכן הזה לא יכול להשאיר הרצה לקריאה בלבד.';

  @override
  String get wakeKindServerStopped => 'הפעלה מחדש של השרת עצרה את ההרצה.';

  @override
  String get wakeKindServerRestarted => 'השרת הופעל מחדש במהלך הרצה של אדם.';

  @override
  String get wakeKindGuardFailed => 'בדיקה לפני המסירה נכשלה.';

  @override
  String get wakeKindLimit => 'ממתינה לאיפוס מגבלת השימוש של הספק.';

  @override
  String get wakeKindLimitRunLive => 'ממתינה לסיום ההרצה שנמצאת במגבלת השימוש.';

  @override
  String get wakeKindWakeMissed => 'הוחמצה בזמן שהשרת היה כבוי.';

  @override
  String get wakeKindPipelineRunEnded => 'הרצת הפייפליין שלה הסתיימה.';

  @override
  String get wakeKindGoalEnded => 'המטרה שלה הסתיימה.';

  @override
  String get wakeKindGoalBudgetExhausted => 'המטרה שלה ניצלה את התקציב שלה.';

  @override
  String get wakeKindGoalReviewStale => 'המטרה השתנתה מאז שהתבקשה הסקירה הזו.';

  @override
  String get wakeKindGoalPaused => 'המטרה שלה מושהית.';

  @override
  String get wakeKindGoalHeld => 'המטרה שלה מוחזקת.';

  @override
  String get wakeKindGoalStopped => 'המטרה שלה נעצרה.';

  @override
  String get wakeKindAskSettled => 'השאלה שהיא עונה עליה כבר נסגרה.';

  @override
  String get wakeKindRuleEnded => 'לוח הזמנים שלו הסתיים.';

  @override
  String get wakeRefusalNotYours =>
      'ההשכמה הזו פועלת בשם אדם אחר. רק הוא יכול למסור, להמשיך או לבטל אותה.';

  @override
  String get wakeRefusalSettled => 'ההשכמה הזו כבר הסתיימה.';

  @override
  String get goalRefusalAlreadyActive => 'לסוכן הזה כבר יש מטרה פעילה.';

  @override
  String get goalRefusalNotInReview => 'המטרה הזו לא ממתינה לסקירה.';

  @override
  String get goalRefusalEvidenceIncomplete => 'הראיות למטרה אינן שלמות.';

  @override
  String get goalRefusalClaimPending => 'הטענה שהמטרה הושלמה עדיין נבדקת.';

  @override
  String get goalRefusalNotActiveSegment => 'למטרה הזו אין מקטע שרץ.';

  @override
  String get goalRefusalNotYours =>
      'רק האדם שהתחיל את המטרה הזו יכול לעשות את זה.';

  @override
  String get goalRefusalNotPaused => 'השהו קודם את המטרה.';

  @override
  String get goalRefusalContractInvalid => 'אי אפשר לקרוא את החוזה של המטרה.';

  @override
  String get goalRefusalCheckerUnknown => 'אין סוכן בשם הזה.';

  @override
  String get goalRefusalCheckerAmbiguous => 'יש יותר מסוכן אחד בשם הזה.';

  @override
  String get goalRefusalCheckerIsGoalAgent =>
      'הבודק חייב להיות סוכן אחר מזה שמבצע את העבודה.';

  @override
  String get goalRefusalCommandInvalid => 'אי אפשר לקרוא את המטרה הזו:';

  @override
  String get wakeRuleRefusalIntervalTooShort =>
      'המרווח קצר מדי. בחרו לפחות דקה.';

  @override
  String get wakeRuleRefusalTooSoon =>
      'הזמן הזה קרוב מדי. בחרו זמן מאוחר יותר.';

  @override
  String get wakeRuleRefusalLineageEnded =>
      'שרשרת ההשכמות הזו ניצלה את ההרצות או את הזמן שלה.';

  @override
  String get wakeRuleRefusalWatchTargetUnreadable =>
      'אי אפשר לקרוא את מה שהמעקב הזה היה עוקב אחריו.';

  @override
  String get wakeRuleRefusalExpiryRequired =>
      'תנו לזה תאריך סיום או מספר הרצות.';

  @override
  String get wakeRuleRefusalLimitReached =>
      'לשיחה או לסוכן הזה כבר יש כמות מקסימלית של לוחות זמנים.';

  @override
  String get wakeRuleRefusalInvalidWhen => 'אי אפשר לקרוא את הזמן.';

  @override
  String get wakeRuleRefusalNoteTooLong => 'ההערה ארוכה מדי.';

  @override
  String get wakeRuleRefusalExpiryTooLong => 'הסיום רחוק מדי.';

  @override
  String get wakeRuleRefusalLimitOutOfRange =>
      'מגבלת הרצות, ימים או תקציב מחוץ לטווח.';

  @override
  String get wakeRuleRefusalNextOutsideLoop =>
      'רק לולאה יכולה לבחור את הזמן הבא שלה.';

  @override
  String get wakeRuleRefusalWatchRefused => 'את זה אי אפשר לעקוב.';

  @override
  String get wakeRuleRefusalRuleEnded => 'לוח הזמנים הזה כבר הסתיים.';

  @override
  String get wakeRuleRefusalNotYours => 'לוח הזמנים הזה שייך למישהו אחר.';

  @override
  String get wakeRuleEndFired => 'הוא רץ פעם אחת.';

  @override
  String get wakeRuleEndExpired => 'הוא הגיע לתאריך הסיום שלו.';

  @override
  String get wakeRuleEndRunCap => 'הוא ניצל את ההרצות שלו.';

  @override
  String get wakeRuleEndCostCap => 'הוא הגיע למגבלת העלות שלו.';

  @override
  String get wakeRuleEndGoalEnded => 'המטרה שלו הסתיימה.';

  @override
  String get wakeRuleEndCancelled => 'הוא בוטל.';

  @override
  String get wakeRuleEndMemberRemoved => 'האדם שלו עזב את סביבת העבודה.';

  @override
  String get wakeRuleEndInvalidRow =>
      'לא ניתן היה לקרוא את ההגדרות השמורות שלו.';

  @override
  String goalHoldWorking(int segment) {
    final intl.NumberFormat segmentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String segmentString = segmentNumberFormat.format(segment);

    return 'עובדת על מקטע $segmentString. אין צורך שמישהו יפעל.';
  }

  @override
  String get goalHoldWaiting => 'ממתינה לעבודה שמגיעה לה. היא תמשיך מעצמה.';

  @override
  String goalHoldWaitingUntil(String time) {
    return 'ממתינה לעבודה שמגיעה לה. היא תמשיך מעצמה לכל המאוחר ב-$time.';
  }

  @override
  String get goalHoldVerifying =>
      'היא אומרת שהושלמה. השרת מריץ את הבדיקות שלה, ואז סוקר מחליט.';

  @override
  String get goalHoldLimit =>
      'הושהתה במגבלת השימוש של הספק. תמשיך מעצמה אחרי האיפוס.';

  @override
  String goalHoldLimitUntil(String time) {
    return 'הושהתה במגבלת השימוש של הספק. תמשיך מעצמה ב-$time.';
  }

  @override
  String get goalHoldPerson =>
      'ממתינה לתשובה של אדם בשיחה. תמשיך אחרי שמישהו יענה.';

  @override
  String get goalHoldByPerson =>
      'הושהתה על ידי אדם. היא תישאר מושהית עד שמישהו ימשיך אותה.';

  @override
  String get goalHoldNeedsReview =>
      'ממתינה לסקירה: היא לא יכולה להמשיך מעצמה. אשרו אותה כהושלמה, המשיכו אותה או בטלו אותה.';

  @override
  String get goalHoldBudget =>
      'היא ניצלה את התקציב שלה. העלו את התקציב כדי שתמשיך.';

  @override
  String goalHoldLimitParks(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'השהיות במגבלת השימוש: $countString מתוך $maxString';
  }

  @override
  String get goalHoldDetailStalled => 'אין התקדמות במקטעים האחרונים שלה.';

  @override
  String get goalHoldDetailStalledWaiting =>
      'היא המתינה 24 שעות על אותה עבודה בלי התקדמות.';

  @override
  String get goalHoldDetailVerificationFailed => 'הבדיקה האחרונה נכשלה.';

  @override
  String get goalHoldDetailCannotVerify =>
      'הבודק לא הצליח לקבוע אם היא הושלמה.';

  @override
  String get goalHoldDetailSandboxUnavailable =>
      'אין ארגז חול זמין להרצת הבדיקות שלה.';

  @override
  String get goalHoldDetailCheckerUnavailable =>
      'סוכן הבודק שלה אינו זמין. בחרו בודק אחר, ואז המשיכו.';

  @override
  String get goalHoldDetailCheckBroken => 'הבדיקה הזו לא יכולה לרוץ:';

  @override
  String get goalHoldDetailWakeSkipped => 'ההשכמה שלה לא נמסרה.';

  @override
  String get goalHoldDetailClaimPending => 'הטענה שהיא הושלמה ממתינה לבדיקה.';

  @override
  String get goalHoldDetailUnanswered =>
      'שאלה או בקשת אישור לאדם נותרו ללא מענה.';

  @override
  String get goalHoldDetailLimitParks =>
      'היא הושהתה במגבלות השימוש יותר מדי פעמים. בדקו אותה, ואז המשיכו.';

  @override
  String get goalHoldDetailInput => 'ממתינה לתשובה בשיחה.';

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

    return 'מקטע $runString מתוך $maxString';
  }

  @override
  String goalSegmentsNoCap(int run) {
    final intl.NumberFormat runNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String runString = runNumberFormat.format(run);

    return 'מקטע $runString, ללא מגבלה';
  }

  @override
  String goalMoney(String spent, String cap) {
    return 'הוצאו $spent מתוך $cap';
  }

  @override
  String goalDeadline(String time) {
    return 'מועד אחרון $time';
  }

  @override
  String get goalPipelineStep => 'שלב בפייפליין מקדם את המטרה הזו.';

  @override
  String get goalSummaryHeading => 'הסיכום האחרון';

  @override
  String get goalDoneMeans => 'מתי זה נחשב כהושלם';

  @override
  String get goalChecks => 'בדיקות';

  @override
  String get goalBoundaries => 'גבולות';

  @override
  String get goalStopWhen => 'לעצור ולשאול כש';

  @override
  String get goalNoMachineCheck =>
      'אין בדיקה אוטומטית. סוקר שופט לפי מה שהוא יכול לקרוא.';

  @override
  String get goalCheckEnvironment => 'משימה של הסביבה';

  @override
  String goalLastCheck(int round, String time) {
    final intl.NumberFormat roundNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String roundString = roundNumberFormat.format(round);

    return 'הבדיקה האחרונה, סבב $roundString, $time';
  }

  @override
  String get goalClaim => 'מה שהיא טענה';

  @override
  String get goalCheckPassed => 'עבר';

  @override
  String goalCheckFailed(int code) {
    return 'נכשל, קוד יציאה $code';
  }

  @override
  String get goalCheckTimedOut => 'הזמן תם';

  @override
  String get goalCheckNotRerun => 'לא הורצה מחדש: דבר לא השתנה';

  @override
  String get goalCheckBroken => 'לא ניתן להריץ';

  @override
  String get goalCriterionMet => 'התקיים';

  @override
  String get goalCriterionUnmet => 'לא התקיים';

  @override
  String get goalCriterionCannotTell => 'לא ניתן לדעת';

  @override
  String get goalVerdictPass => 'הכרעה: הושלמה';

  @override
  String get goalVerdictFail => 'הכרעה: לא הושלמה';

  @override
  String get goalVerdictCannotVerify => 'הכרעה: לא ניתן היה לקבוע';

  @override
  String get goalConcerns => 'הסתייגויות';

  @override
  String goalVerifiedBy(String agent) {
    return 'אומת על ידי $agent';
  }

  @override
  String get goalVerifiedBySelf => 'אומת על ידי הסוכן עצמו (ללא בודק נפרד)';

  @override
  String get goalClosedByPerson => 'נסגרה על ידי אדם ללא בדיקה שעברה';

  @override
  String get goalApprove => 'אישור השלמה';

  @override
  String get goalApproveTitle => 'לסגור את המטרה הזו כהושלמה?';

  @override
  String get goalApproveBody =>
      'אף בדיקה לא אישרה את זה. אתם סוגרים אותה על פי דבריכם בלבד, והמטרה תרשום שאדם סגר אותה ללא אימות.';

  @override
  String get goalApproveConfirm => 'סגירה כהושלמה';

  @override
  String get goalResumeNotYours =>
      'המשך המטרה או הגדלת התקציב שלה שייכים למי שהתחיל אותה.';

  @override
  String get goalChooseChecker => 'בחירת בודק אחר';

  @override
  String goalCheckerSet(String agent) {
    return '$agent בודק אותה עכשיו. המשיכו כדי לאמת שוב.';
  }

  @override
  String get goalSchedules => 'לוחות זמנים';

  @override
  String get goalRepeat => 'חזרה';

  @override
  String get goalCreateChecks => 'בדיקות (אופציונלי)';

  @override
  String get goalCreateCheckHint => 'פקודה שעוברת כשהעבודה הושלמה';

  @override
  String get goalCreateAddCheck => 'הוספת בדיקה';

  @override
  String get goalCreateRemoveCheck => 'הסרת בדיקה';

  @override
  String get goalCreateSegmentCap => 'מגבלת מקטעים (אופציונלי)';

  @override
  String get goalCreateSegmentInvalid =>
      'מגבלת המקטעים חייבת להיות מספר שלם, לפחות 1.';

  @override
  String get scheduleCreateTitle => 'חזרה על בקשה';

  @override
  String get scheduleCadence => 'באיזו תדירות';

  @override
  String get scheduleEveryMinutes => 'כל N דקות';

  @override
  String get scheduleEveryHours => 'כל N שעות';

  @override
  String get scheduleSelfPaced => 'בקצב של הסוכן';

  @override
  String get scheduleSelfPacedHint =>
      'הסוכן בוחר את ההמתנה אחרי כל הרצה, בין דקה לשעה.';

  @override
  String get scheduleInterval => 'מרווח';

  @override
  String get scheduleNote => 'מה כל הרצה צריכה לעשות?';

  @override
  String get scheduleCostCap => 'מגבלת עלות בדולרים (אופציונלי)';

  @override
  String get scheduleExpiryDays => 'מסתיים אחרי N ימים (אופציונלי)';

  @override
  String get scheduleCreateInvalid =>
      'בחרו מרחב וסוכן, כתבו מה כל הרצה צריכה לעשות, והזינו מספרים שלמים של 1 לפחות.';

  @override
  String get scheduleCreateButton => 'התחלת לוח הזמנים';

  @override
  String get scheduleCreateConfirmTitle => 'להתחיל את לוח הזמנים הזה?';

  @override
  String scheduleCreateConfirmEveryMinutes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'הוא רץ כל $countString דקות, החל מעכשיו.',
      two: 'הוא רץ כל שתי דקות, החל מעכשיו.',
      one: 'הוא רץ כל דקה, החל מעכשיו.',
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
      other: 'הוא רץ כל $countString שעות, החל מעכשיו.',
      two: 'הוא רץ כל שעתיים, החל מעכשיו.',
      one: 'הוא רץ כל שעה, החל מעכשיו.',
    );
    return '$_temp0';
  }

  @override
  String get scheduleCreateConfirmSelfPaced =>
      'הוא רץ עכשיו, ואז הסוכן בוחר מתי לרוץ שוב.';

  @override
  String get scheduleCreated => 'לוח הזמנים התחיל. הוא מופיע תחת לוחות זמנים.';

  @override
  String get schedulesTitle => 'לוחות זמנים';

  @override
  String get schedulesLoadFailed => 'לא ניתן לטעון את לוחות הזמנים';

  @override
  String get schedulesEmpty => 'אין לוחות זמנים או מעקבים';

  @override
  String get schedulesEmptyDescription =>
      'חזרו על בקשה ממסך המטרות, או שלחו /loop או /schedule בשיחה.';

  @override
  String get scheduleMissing => 'לוח הזמנים הזה כבר לא זמין בסביבת העבודה הזו.';

  @override
  String scheduleEvery(String interval) {
    return 'כל $interval';
  }

  @override
  String get scheduleSelfPacedLoop => 'לולאה בקצב של הסוכן';

  @override
  String get scheduleCron => 'לוח cron';

  @override
  String scheduleOnce(String time) {
    return 'פעם אחת ב-$time';
  }

  @override
  String scheduleWatch(String event) {
    return 'מעקב: $event';
  }

  @override
  String get scheduleWatchPrChecks => 'הבדיקות של בקשת המשיכה';

  @override
  String get scheduleWatchPrReview => 'הסקירות של בקשת המשיכה';

  @override
  String get scheduleWatchPrMerged => 'מיזוג בקשת המשיכה';

  @override
  String get scheduleWatchEnvironment => 'הסביבה';

  @override
  String get scheduleWatchTicket => 'הכרטיס';

  @override
  String get scheduleWatchPipelineRun => 'הרצת הפייפליין';

  @override
  String get scheduleStatusActive => 'פעיל';

  @override
  String get scheduleStatusPaused => 'מושהה';

  @override
  String get scheduleStatusEnded => 'הסתיים';

  @override
  String scheduleWakes(String agent) {
    return 'מעורר את $agent';
  }

  @override
  String scheduleNext(String time) {
    return 'ההרצה הבאה $time';
  }

  @override
  String scheduleLast(String time) {
    return 'ההרצה האחרונה $time';
  }

  @override
  String scheduleRuns(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString הרצות',
      two: 'שתי הרצות',
      one: 'הרצה אחת',
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

    return '$countString מתוך $maxString הרצות';
  }

  @override
  String scheduleSkipped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'דולג $countString פעמים',
      two: 'דולג פעמיים',
      one: 'דולג פעם אחת',
    );
    return '$_temp0';
  }

  @override
  String scheduleEnds(String time) {
    return 'מסתיים $time';
  }

  @override
  String scheduleChain(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'חלק משרשרת: נותרו $countString הרצות, מסתיימת ב-$time';
  }

  @override
  String get scheduleNoteAgent => 'ההערה של הסוכן, במילים שלו:';

  @override
  String get scheduleNotePerson => 'הערה של אדם:';

  @override
  String scheduleActsFor(String name) {
    return 'פועל בשם $name';
  }

  @override
  String get scheduleActsForBot => 'לא פועל בשם אף אדם';

  @override
  String get scheduleGoalBound => 'הוא מסתיים יחד עם המטרה שלו.';

  @override
  String get schedulePause => 'השהיה';

  @override
  String get scheduleResume => 'המשך';

  @override
  String get scheduleDelete => 'מחיקה';

  @override
  String get scheduleRemove => 'הסרה';

  @override
  String get scheduleDeleteTitle => 'למחוק את לוח הזמנים הזה?';

  @override
  String get scheduleDeleteBody =>
      'הוא יפסיק לתמיד. מה שכבר נעשה על ידיו לא מבוטל.';

  @override
  String get scheduleRemoveTitle => 'להסיר את לוח הזמנים הזה?';

  @override
  String get scheduleRemoveBody => 'הוא ייעלם מהרשימה.';

  @override
  String get scheduleResumeNotYours =>
      'רק האדם שבשמו לוח הזמנים הזה פועל יכול להמשיך אותו.';

  @override
  String get scheduleResumeAdminOnly =>
      'רק מנהל סביבת העבודה יכול להמשיך לוח זמנים שאף אדם אינו הבעלים שלו.';

  @override
  String get scheduleOpenConversation => 'פתיחת השיחה';

  @override
  String get progressWaiting => 'ממתינות';

  @override
  String get progressNothingWaiting => 'אין דבר שממתין.';

  @override
  String get wakeOriginGoal => 'מטרה';

  @override
  String get wakeOriginGoalCheck => 'בדיקת מטרה';

  @override
  String get wakeOriginGoalReview => 'סקירת מטרה';

  @override
  String get wakeOriginSchedule => 'לוח זמנים';

  @override
  String get wakeOriginWatch => 'מעקב';

  @override
  String get wakeOriginReply => 'תשובה';

  @override
  String get wakeOriginMessage => 'הודעה';

  @override
  String get wakeOriginWorkFinished => 'עבודה שהסתיימה';

  @override
  String get wakeOriginLimitReset => 'איפוס מגבלה';

  @override
  String get wakeOriginRecovery => 'שחזור';

  @override
  String get wakeOriginAssignment => 'הקצאה';

  @override
  String get wakeOriginPipelineStep => 'שלב בפייפליין';

  @override
  String get wakeOriginImprovementReview => 'סקירת שיפורים';

  @override
  String wakeOriginReplyFrom(String agent) {
    return 'תשובה מ-$agent';
  }

  @override
  String wakeOriginMessageFrom(String agent) {
    return 'הודעה מ-$agent';
  }

  @override
  String wakeOriginWorkFinishedBy(String agent) {
    return 'עבודה שהסתיימה אצל $agent';
  }

  @override
  String wakeFor(String agent) {
    return 'עבור $agent';
  }

  @override
  String wakeDue(String time) {
    return 'לביצוע ב-$time';
  }

  @override
  String get wakeDueNow => 'לביצוע עכשיו';

  @override
  String get wakeHeld => 'מוחזקת';

  @override
  String wakeExpires(String time) {
    return 'פוקעת ב-$time';
  }

  @override
  String wakeAttempt(int attempt) {
    final intl.NumberFormat attemptNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String attemptString = attemptNumberFormat.format(attempt);

    return 'ניסיון $attemptString';
  }

  @override
  String get wakeCancel => 'ביטול';

  @override
  String get wakeDeliverNow => 'מסירה עכשיו';

  @override
  String get wakeResume => 'המשך';

  @override
  String get wakeDismiss => 'דחייה';

  @override
  String get wakeResumeOnlyTheirs => 'רק האדם שההרצה שלו יכול להמשיך אותה.';

  @override
  String get wakeRecovery =>
      'השרת הופעל מחדש במהלך ההרצה הזו. המשיכו אותה, או דחו.';

  @override
  String limitParkTitle(String provider, String time) {
    return 'הושהה במגבלת השימוש של $provider, שמתאפסת ב-$time. ההרצה ממתינה להמשך, עד 7 ימים מאיפוס המגבלה.';
  }

  @override
  String limitParkTitleUnnamed(String time) {
    return 'הושהה במגבלת השימוש של הספק, שמתאפסת ב-$time. ההרצה ממתינה להמשך, עד 7 ימים מאיפוס המגבלה.';
  }

  @override
  String get limitParkResumeNow => 'המשך עכשיו';

  @override
  String get limitParkCancel => 'ביטול';

  @override
  String limitParkResumed(String provider) {
    return 'המשיכה אחרי מגבלת השימוש של $provider.';
  }

  @override
  String limitParkGone(String provider) {
    return 'כבר לא ממתינה למגבלת השימוש של $provider.';
  }

  @override
  String get limitParkProviderUnknown => 'הספק';

  @override
  String get mobileHeldMessages => 'הודעות מוחזקות';

  @override
  String get heldSteeringTitle =>
      'מוחזקות כי ההרצה הסתיימה לפני שהספיקה לקחת אותן. שלחו את שלכם עכשיו או הסירו אותן.';

  @override
  String get heldSteeringRelease => 'שליחת ההודעות המוחזקות';

  @override
  String get notifGoalCompleted => 'המטרה הושלמה';

  @override
  String get notifGoalFailed => 'המטרה נכשלה';

  @override
  String get notifGoalCancelled => 'המטרה בוטלה';

  @override
  String get notifGoalBudgetExhausted => 'המטרה ניצלה את התקציב שלה';

  @override
  String get notifGoalNeedsReview => 'מטרה ממתינה לסקירה שלכם';

  @override
  String get notifGoalNeedsPerson => 'מטרה זקוקה לכם';

  @override
  String get notifGoalOnHold => 'מטרה מוחזקת';

  @override
  String get notifWakeRuleEnded => 'לוח זמנים הסתיים';

  @override
  String notifWaitingDigest(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString דברים ממתינים לכם',
      two: 'שני דברים ממתינים לכם',
      one: 'דבר אחד ממתין לכם',
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
      other: 'הוצעו $countString שיפורים',
      two: 'הוצעו שני שיפורים',
      one: 'הוצע שיפור',
    );
    return '$_temp0';
  }

  @override
  String get notifPipelineRunHeld => 'הרצת פייפליין מוחזקת במגבלת התקציב שלה';

  @override
  String notifPipelineRunHeldBody(String spent, String cap) {
    return 'הוצאו $spent מתוך $cap';
  }

  @override
  String get notifNeedsYou => 'דורש את תשומת לבכם';

  @override
  String get notifDigestGoalReview => 'מטרה ממתינה לסקירה';

  @override
  String get notifDigestGoalPerson => 'מטרה זקוקה לאדם';

  @override
  String get notifDigestHeldWake => 'השכמה מוחזקת';

  @override
  String get notifDigestImprovement => 'שיפור שהוצע';

  @override
  String get wakeKindRulePaused => 'לוח הזמנים שלו הושהה.';

  @override
  String get wakeKindRuleBusy =>
      'הסוכן היה עסוק, ולוח הזמנים הזה מדלג על זמן כזה.';

  @override
  String get wakeKindRuleFolded =>
      'אירוע מאוחר יותר של אותו מעקב תפס את מקומו.';

  @override
  String get wakeKindRuleSuperseded =>
      'זמן מאוחר יותר של לוח הזמנים החליף אותה.';

  @override
  String get wakeKindRuleNotified =>
      'לוח הזמנים שלו שולח רק התראה, ולכן לא התחילה הרצה.';

  @override
  String get wakeKindRuleLimitParked =>
      'לוח הזמנים שלו ממתין לאיפוס מגבלת השימוש של הספק.';

  @override
  String get improvementRefusalCooldown =>
      'סקירת שיפורים רצה בשיחה הזו לפני זמן קצר. נסו שוב מאוחר יותר.';

  @override
  String get improvementRefusalQueued =>
      'סקירת שיפורים של השיחה הזו כבר ממתינה לרוץ.';

  @override
  String get improvementRefusalAgentNotFound =>
      'הסוכן הזה אינו סוכן של סביבת העבודה הזו.';

  @override
  String get steeringRefusalHeldByLimit =>
      'הודעות שמחזיקה מגבלת שימוש לא ניתן לשלוח ידנית. הן ממתינות להמשך ההרצה המושהית.';

  @override
  String limitParkCancelled(String provider) {
    return 'ההמתנה למגבלת השימוש של $provider בוטלה.';
  }

  @override
  String limitParkExpired(String provider) {
    return 'ההמתנה למגבלת השימוש של $provider פגה לפני שההרצה המשיכה.';
  }

  @override
  String limitParkSkipped(String provider) {
    return 'ההרצה לא המשיכה אחרי מגבלת השימוש של $provider.';
  }

  @override
  String get heldSteeringLimitTitle =>
      'מוחזקות בזמן שההרצה ממתינה לאיפוס מגבלת השימוש. הן יישלחו כשהאדם שעבורו היא פועלת ימשיך אותה.';

  @override
  String heldSteeringLimitAt(String time) {
    return 'מוחזקות עד שמגבלת השימוש מתאפסת ב-$time. הן יישלחו כשהאדם שעבורו היא פועלת ימשיך אותה.';
  }

  @override
  String get heldSteeringOtherTitle => 'מוחזקות על ידי השרת. אפשר להסיר אותן.';

  @override
  String workRowWoke(int count, String agent) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'הפעיל את $agent בגלל $countString פריטים ממתינים',
      two: 'הפעיל את $agent בגלל שני פריטים ממתינים',
      one: 'הפעיל את $agent',
    );
    return '$_temp0';
  }

  @override
  String workRowWakeMissed(String agent) {
    return 'השכמה עבור $agent הוחמצה בזמן שהשרת היה כבוי.';
  }

  @override
  String workRowWakeSkipped(String agent) {
    return 'השכמה עבור $agent לא נמסרה.';
  }

  @override
  String workRowScheduleCreated(String agent) {
    return 'נקבע לוח זמנים עבור $agent.';
  }

  @override
  String workRowScheduleEnded(String agent) {
    return 'לוח הזמנים של $agent הסתיים.';
  }

  @override
  String workRowNoteFromAgent(String agent) {
    return 'הערה מתוך לוח הזמנים מ-$agent:';
  }

  @override
  String get workRowNoteFromPerson => 'הערה מתוך לוח הזמנים מאדם:';

  @override
  String workRowCommandRefusedNamed(String command) {
    return 'הפקודה $command נדחתה.';
  }

  @override
  String get workRowCommandRefused => 'פקודה נדחתה.';

  @override
  String workRowCapRaised(String person, String from, String to) {
    return '$person העלה את מגבלת ההוצאה של הפייפליין מ-$from ל-$to.';
  }

  @override
  String workRowCapRaisedNoAmounts(String person) {
    return '$person העלה את מגבלת ההוצאה של הפייפליין.';
  }

  @override
  String get workRowApplyIncomplete =>
      'שינוי מאושר למיומנות הזו לא יכול היה להסתיים, כי המיומנות השתנתה בינתיים. ההצעה הוחזרה לאחור.';

  @override
  String get workRowOpenSchedule => 'פתיחת לוח הזמנים';

  @override
  String get heldSteeringOthersTitle =>
      'מוחזקות כי ההרצה הסתיימה לפני שהספיקה לקחת אותן. רק האדם שכתב הודעה יכול לשלוח אותה.';

  @override
  String get heldSteeringOnlyYours =>
      'שולחות רק את ההודעות שלכם. האחרות ממתינות לאנשים שכתבו אותן.';

  @override
  String heldSteeringWrittenBy(String name) {
    return 'נכתבה על ידי $name';
  }

  @override
  String get steeringRefusalNotYours =>
      'רק האדם שכתב הודעה מוחזקת יכול לשלוח אותה, ואף אחת מאלה אינה שלכם.';

  @override
  String get steeringRefusalNeedsWrite =>
      'נדרשת לך הרשאת כתיבה למאגרי המרחב הזה כדי לכוון הרצה שפועלת עבור מישהו אחר.';

  @override
  String workRowSchedulePaused(String name, String agent) {
    return '$name השהה את לוח הזמנים של $agent.';
  }

  @override
  String get goalVerdictObjective => 'היעד בשלמותו';

  @override
  String get notifDigestRequest => 'ממתין לתשובתך';
}
