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
  String get inboxNoForgeAccount =>
      'לא מחובר חשבון forge בשרת, ולכן עדיין לא ניתן לשייך אליכם בקשות משיכה.';

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
  String get join => 'הצטרפות';

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
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁨$names⁩ גדולים מדי לשליחה דרך הממסר מכאן.',
      many: '⁨$names⁩ גדולים מדי לשליחה דרך הממסר מכאן.',
      two: '⁨$names⁩ גדולים מדי לשליחה דרך הממסר מכאן.',
      one: '⁨$names⁩ גדול מדי לשליחה דרך הממסר מכאן.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed =>
      'לא ניתן להעלות את הקובץ המצורף. נסו שוב.';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count קבצים מצורפים לא הועלו ולא נכללו.',
      many: '$count קבצים מצורפים לא הועלו ולא נכללו.',
      two: 'שני קבצים מצורפים לא הועלו ולא נכללו.',
      one: 'קובץ מצורף אחד לא הועלה ולא נכלל.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'חבר צוות';

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
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'לא ניתן לקרוא $count מאגרים.',
      many: 'לא ניתן לקרוא $count מאגרים.',
      two: 'לא ניתן לקרוא שני מאגרים.',
      one: 'לא ניתן לקרוא מאגר אחד.',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return 'לא ניתנים לקריאה: ⁨$names⁩';
  }

  @override
  String get installationSuspendedTitle => 'התקנת GitHub App הושעתה';

  @override
  String installationSuspendedBody(String names) {
    return 'מוצגים הנתונים האחרונים הידועים עבור ⁨$names⁩. חדש את ההתקנה ב-GitHub, או חבר אסימון עם גישה.';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'התקנת GitHub App הושעתה. מוצגים הנתונים האחרונים הידועים עבור ⁨$names⁩. חדש את ההתקנה ב-GitHub, או חבר אסימון עם גישה.';
  }

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
}
