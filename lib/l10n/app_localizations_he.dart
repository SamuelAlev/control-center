// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get succeeded => 'הצליחה';

  @override
  String agentRunRetryLabel(int number, String time) {
    return 'ניסיון חוזר ⁨#$number⁩ · $time';
  }

  @override
  String agentRunStarting(String time) {
    return 'מתחילה · $time';
  }

  @override
  String get agentActivityFollowingLive => 'מעקב אחר פעילות חיה';

  @override
  String get agentActivityJumpToLatest => 'עבור לאחרון';

  @override
  String get agentActivityLoadFailed => 'לא ניתן לטעון את הפעילות של הרצה זו';

  @override
  String get agentActivityNotRecorded => 'לא נרשמה פעילות עבור הרצה זו';

  @override
  String get agentActivityNotRecordedHint =>
      'להרצות שהסתיימו לפני שהופעל תיעוד הפעילות אין ציר זמן.';

  @override
  String get agentActivityRunUnavailable => 'הרצה זו אינה זמינה עוד';

  @override
  String agentActivitySubagentOf(String agent) {
    return 'תת-סוכן של $agent';
  }

  @override
  String get agentActivityUnsupported => 'תיעוד פעילות אינו זמין בשרת המחובר';

  @override
  String get agentActivityUnsupportedHint =>
      'הפעל מחדש את האפליקציה כדי שתטען את גרסת השרת העדכנית.';

  @override
  String get agentActivityWaiting => 'ממתין לפעילות…';

  @override
  String get created => 'נוצר';

  @override
  String get dictationStart => 'התחל הכתבה';

  @override
  String get dictationListening => 'מאזין…';

  @override
  String get dictationUnavailable =>
      'הכתבה דורשת מודל קול על מארח השרת. הגדר אחד בהגדרות הקול.';

  @override
  String get dictationFailedToStart => 'לא ניתן להתחיל הכתבה';

  @override
  String get dictationHoldToTalkTitle => 'החזק כדי לדבר';

  @override
  String get dictationHoldToTalkDescription =>
      'החזק את כפתור המיקרופון או את קיצור הדרך כדי להכתיב, ושחרר כדי לעצור. כשהאפשרות כבויה, לחץ פעם אחת כדי להתחיל ושוב כדי לעצור.';

  @override
  String get focusConversation => 'התמקד בשיחה';

  @override
  String get ideAgentActivity => 'פעילות סוכן';

  @override
  String get keybindingPushToTalk => 'לחץ ודבר';

  @override
  String get keybindingPushToTalkDescription =>
      'החזק או החלף מצב הכתבה קולית באזור כתיבת ההודעה';

  @override
  String get agentPermissions => 'הרשאות סוכנים';

  @override
  String get agentPermissionsSettingsDescription =>
      'קבע מה סוכנים רשאים לעשות בעצמם, על מה עליהם לשאול קודם ומה אסור להם לעולם — לפי סביבת עבודה, סוכן או מרחב.';

  @override
  String get agentPermissionsMatrixDescription =>
      'קבע החלטה לכל סוג השפעה. הכללים פועלים במדרג: מרחב גובר על סוכן, סוכן על סביבת עבודה, וסביבת עבודה על ערכת המצב. הכלל הספציפי ביותר מנצח.';

  @override
  String get guardrailLoading => 'טוען כללים…';

  @override
  String get guardrailRulesLoadFailed => 'לא ניתן לטעון את כללי ההרשאות.';

  @override
  String get guardrailScopeWorkspace => 'סביבת עבודה';

  @override
  String get guardrailScopeAgent => 'סוכן';

  @override
  String get guardrailScopeSpace => 'מרחב';

  @override
  String get guardrailSelectAgent => 'בחר סוכן';

  @override
  String get guardrailSelectSpace => 'בחר מרחב';

  @override
  String get guardrailNoAgents => 'אין עדיין סוכנים בסביבת עבודה זו.';

  @override
  String get guardrailNoSpaces => 'אין עדיין מרחבים בסביבת עבודה זו.';

  @override
  String get guardrailClassFileDelete => 'מחיקת קובץ';

  @override
  String get guardrailClassFileWriteOutsideWorktree => 'כתיבה מחוץ לעץ העבודה';

  @override
  String get guardrailClassGitCommit => 'יצירת קומיט';

  @override
  String get guardrailClassGitPush => 'דחיפה למאגר מרוחק';

  @override
  String get guardrailClassPrCreate => 'פתיחת בקשת משיכה';

  @override
  String get guardrailClassPrPublish => 'פרסום סקירה או מיזוג';

  @override
  String get guardrailClassVendorSyncWrite => 'כתיבה למערכת מעקב חיצונית';

  @override
  String get guardrailClassNetworkEgress => 'גישה לרשת';

  @override
  String get guardrailClassSecretAccess => 'קריאת סוד';

  @override
  String get guardrailClassPackageInstall => 'התקנת חבילה';

  @override
  String get guardrailClassProcessSpawn => 'הרצת תהליך';

  @override
  String get guardrailClassWorkspaceMutation => 'שינוי מבנה סביבת העבודה';

  @override
  String get guardrailClassEnclosureControl => 'שליטה במתחם מבודד (תחנה)';

  @override
  String get navRigs => 'תחנות';

  @override
  String get rigsUnsupportedServer =>
      'שרת זה אינו יכול לארח משטחי rig. יש לבדוק את דרישות המארח עבור המחשב שבו ברצונך להשתמש.';

  @override
  String get rigSurfaceComputer => 'מחשב';

  @override
  String get rigSurfaceBrowser => 'דפדפן';

  @override
  String get rigSurfaceAndroid => 'Android';

  @override
  String get rigSurfaceIosSimulator => 'סימולטור iOS';

  @override
  String rigSurfaceBrowserEngine(String engine) {
    return '$engine';
  }

  @override
  String rigBrowserEngineHint(String engine) {
    return '⁨$engine⁩ חד-פעמי, מבודד מהמחשב שלך. פתח מנוע נוסף כדי להשוות את אותו עמוד זה לצד זה.';
  }

  @override
  String get rigPhaseReady => 'מוכנה';

  @override
  String get rigPhaseStarting => 'בהפעלה';

  @override
  String get rigPhaseParked => 'מושהית';

  @override
  String get rigPhaseClosing => 'נסגרת';

  @override
  String get rigPhaseClosed => 'סגורה';

  @override
  String get rigPhaseFailed => 'נכשלה';

  @override
  String get rigPhaseUnknown => 'לא ידוע';

  @override
  String get rigNotAccelerated => 'באמולציה';

  @override
  String get rigAudioListen => 'האזן למכונה';

  @override
  String get rigAudioMute => 'השתק את המכונה';

  @override
  String get rigYouHaveControl => 'השליטה בידיך';

  @override
  String get rigBackendAvailable => 'זמין';

  @override
  String get rigBackendUnavailable => 'לא זמין';

  @override
  String get rigEgressNotEnforced =>
      'הרשת אינה מבודדת במנגנון הרצה זה — הוא מנהל את הקישוריות שלו בעצמו.';

  @override
  String get rigStartMachine => 'הפעל את המכונה';

  @override
  String get rigStartHint =>
      'מפעיל VM חד-פעמי שאתה והסוכנים שלך חולקים בשיחה זו. הוא מושמד עם סגירתו, ודבר בתוכו אינו נוגע במחשב שלך.';

  @override
  String get rigStartAndroidHint =>
      'מתחבר לאמולטור Android שכבר פועל בשרת. הגישה לרשת אינה מבודדת.';

  @override
  String get rigStartIosHint =>
      'יוצר סימולטור iOS זמני בשרת macOS. הוא נמחק כשסביבת הבדיקה נסגרת; הגישה לרשת אינה מבודדת.';

  @override
  String get rigTechnicalDetails => 'פרטים טכניים';

  @override
  String get rigStopMachine => 'עצור את המכונה';

  @override
  String get rigHomeButton => 'בית';

  @override
  String get rigRotateClockwise => 'סיבוב עם כיוון השעון';

  @override
  String get rigRotateCounterclockwise => 'סיבוב נגד כיוון השעון';

  @override
  String get rigTakeScreenshot => 'צילום מסך';

  @override
  String get rigScreenshotSaved => 'צילום המסך נשמר';

  @override
  String rigScreenshotSaveFailed(String error) {
    return 'לא ניתן לשמור את צילום המסך: ⁨$error⁩';
  }

  @override
  String get rigSurfaceUnavailable => 'שרת זה אינו יכול לארח מכונה מסוג זה.';

  @override
  String get rigTabNeedsConversation =>
      'פתח שיחה קודם — מכונה שייכת לשיחה אחת, כך שאתה והסוכנים שלך רואים את אותו מסך.';

  @override
  String get ideMenuSectionTools => 'כלים';

  @override
  String get ideMenuSectionMachines => 'מכונות';

  @override
  String get ideMenuSectionReopen => 'פתח מחדש';

  @override
  String get ideMenuSearchHint => 'חיפוש';

  @override
  String get ideMenuNoMatches => 'אין התאמות';

  @override
  String get rigMenuComputer => 'מחשב';

  @override
  String get rigMenuBrowser => 'דפדפן';

  @override
  String get rigMenuAndroid => 'Android';

  @override
  String get rigMenuIosSimulator => 'סימולטור iOS';

  @override
  String rigLabelNumbered(String label, String suffix) {
    return '$label $suffix';
  }

  @override
  String ideCloseKeepTitle(String name) {
    return 'לסגור את $name?';
  }

  @override
  String get ideCloseKeepBodyMachine =>
      'המכונה ממשיכה לרוץ ברקע — פתח אותה מחדש בכל עת מסרגל הצד. כבה אותה במקום זאת כדי לפנות את הזיכרון שלה עכשיו.';

  @override
  String get ideCloseKeepBodyShell =>
      'הפקודה ממשיכה לרוץ ברקע — פתח את המעטפת מחדש בכל עת מסרגל הצד. סיים אותה במקום זאת כדי לעצור את מה שהיא עושה עכשיו.';

  @override
  String get ideCloseKeepBodyAgent =>
      'הסוכן ממשיך לעבוד ברקע — פתח את השיחה מחדש בכל עת מסרגל הצד. עצור אותו במקום זאת כדי לסיים את ההרצה עכשיו.';

  @override
  String get ideCloseKeepRunning => 'השאר פועל';

  @override
  String get ideCloseShutDownMachine => 'כבה';

  @override
  String get ideCloseEndShell => 'סיים מעטפת';

  @override
  String get ideCloseStopAgent => 'עצור סוכן';

  @override
  String get rigsSettingsSubtitle =>
      'מה שרת זה מסוגל להפעיל, תמונות הבסיס שהוא צריך והמכונות שרצות כעת';

  @override
  String get rigsCapabilitiesTitle => 'שרת זה';

  @override
  String get rigInstallIosAutomation => 'התקנת גשר האוטומציה של iOS';

  @override
  String get rigInstallingIosAutomation => 'גשר האוטומציה של iOS מותקן…';

  @override
  String get rigIosAutomationInstalled => 'גשר האוטומציה של iOS הותקן';

  @override
  String get rigsImagesTitle => 'תמונות בסיס';

  @override
  String get rigsImagesHint =>
      'כל תחנה מופעלת מאחת מתמונות הבסיס הללו, לקריאה בלבד. כל הפעלה כותבת לשכבת-על זמנית, כך שתחנה אחת לעולם לא תשנה את נקודת ההתחלה של הבאה אחריה.';

  @override
  String get rigsRunningTitle => 'רצות כעת';

  @override
  String get rigsNoneRunning => 'אין מכונות רצות.';

  @override
  String get rigsCustomImagesTitle => 'תמונות מותאמות אישית (סביבת עבודה זו)';

  @override
  String get rigsCustomImagesHint =>
      'הפנה את הטרמינל (VM) או הדפדפן (VM) לתמונה משלך — הרחב את ברירות המחדל עם הכלים שהפרויקט שלך צריך, או השתמש בכל תמונה תואמת מ-registry. מכונות חדשות ישתמשו בה; מכונות רצות שומרות על שלהן. עיין במדריך התחנות כדי לדעת מה תמונה חייבת לספק.';

  @override
  String get rigsCustomTerminalImageLabel => 'תמונת טרמינל (VM)';

  @override
  String get rigsCustomBrowserImageLabel => 'תמונת דפדפן (VM)';

  @override
  String get rigsCustomImagePlaceholder =>
      'לדוגמה ⁨ghcr.io/acme/dev-shell:1.2⁩ — השאר ריק לברירת המחדל';

  @override
  String get rigsCustomImageInvalid =>
      'הזן הפניית registry כגון ⁨repo/name:tag⁩. נתיבים מקומיים וארכיונים אינם מותרים.';

  @override
  String get rigsCustomImageSaved =>
      'נשמר. מכונות חדשות יופעלו מתמונה זו; מכונות רצות שומרות על שלהן.';

  @override
  String get rigsEgressTitle => 'תעבורה יוצאת מהדפדפן (סביבת עבודה זו)';

  @override
  String get rigsEgressHint =>
      'מארחים נוספים שהדפדפן המבודד רשאי לגשת אליהם — אחד בכל שורה: מארח מדויק (⁨api.example.com⁩) או תו כללי לתת-הדומיינים שלו (⁨*.example.com⁩). אתר המוצר נשאר מותר בכל מקרה. מכונות חדשות מקבלות את הרשימה; מכונות רצות שומרות על מה שאיתו הופעלו.';

  @override
  String rigsEgressInvalid(String host) {
    return '\"⁨$host⁩\" אינו ערך מארח חוקי.';
  }

  @override
  String get rigsEgressSaved =>
      'נשמר. מכונות דפדפן חדשות יאפשרו את המארחים האלה; מכונות רצות שומרות על שלהן.';

  @override
  String get rigImageInstalled => 'מותקנת';

  @override
  String get rigImageNotDownloaded => 'לא הורדה';

  @override
  String get rigImageNotPublished => 'לא פורסמה';

  @override
  String get rigImageNotPublishedHint =>
      'טרם פורסמה תמונה עבור זה, כך שאין מה להוריד. ייבא תמונת דיסק תואמת כדי להפעיל זאת.';

  @override
  String get rigImageDownload => 'הורד';

  @override
  String get rigImageDownloading => 'מוריד…';

  @override
  String get rigImageImport => 'ייבא';

  @override
  String get rigImageImportMessage =>
      'נתיב לתמונת דיסק ⁨qcow2⁩ במערכת הקבצים של השרת. היא מועתקת אל מחסן התמונות, כך שהקובץ יכול לזוז לאחר מכן.';

  @override
  String get rigConnectingStream => 'מתחבר לתחנה';

  @override
  String get rigStreamNotAllowed => 'אין לך גישה לתחנה זו.';

  @override
  String get rigStreamNotRunning => 'תחנה זו כבר אינה רצה.';

  @override
  String get rigStreamNeedsFfmpeg =>
      'תצוגה חיה דורשת ⁨ffmpeg⁩ על מארח זה. התקן ⁨ffmpeg⁩ ופתח מחדש את הכרטיסייה.';

  @override
  String get rigStreamEnded => 'התצוגה החיה הסתיימה.';

  @override
  String get rigStreamFailed => 'לא ניתן לפתוח את התצוגה החיה.';

  @override
  String get rigStreamDisconnected => 'אין חיבור לשרת.';

  @override
  String rigDropSendingOne(String name) {
    return 'מעתיק את \"⁨$name⁩\" אל המכונה…';
  }

  @override
  String rigDropSendingMany(int count) {
    return 'מעתיק $count קבצים אל המכונה…';
  }

  @override
  String get rigTerminalDropSending => 'מעתיק אל המכונה…';

  @override
  String get rigTerminalPasteImage => 'התמונה שהודבקה נשמרה במכונה';

  @override
  String get rigPortsTitle => 'פורטים מועברים';

  @override
  String get rigPortsTooltip => 'פורטים פתוחים בתוך מכונה זו';

  @override
  String get rigPortsEmpty =>
      'שום דבר לא מאזין עדיין. הפעל שרת בטרמינל — שרת פיתוח בפורט 3000 יופיע כאן.';

  @override
  String get rigPortsAdd => 'הוסף פורט';

  @override
  String get rigPortsAddHint => 'פורט אורח להעברה (לדוגמה 3000)';

  @override
  String get rigPortsAutoForward => 'העברת פורטים אוטומטית';

  @override
  String get rigPortsCopyUrl => 'העתק URL מקומי';

  @override
  String rigPortsCopiedUrl(String url) {
    return 'הועתק ⁨$url⁩';
  }

  @override
  String get rigPortsStopForward => 'הפסק העברה';

  @override
  String get rigPortsExposeLan => 'שתף ברשת המקומית';

  @override
  String get rigPortsLanPrivate => 'מקומי בלבד';

  @override
  String get rigPortsLanShared => 'ברשת';

  @override
  String get rigPortsSetDomain => 'הגדר דומיין דפדפן (⁨.test⁩)';

  @override
  String get rigPortsDomainHint =>
      'דומיין עבור הדפדפן (VM), לדוגמה ⁨myapp.test⁩ — נגיש שם, לא על המארח';

  @override
  String get rigPortsProcessUnknown => 'תהליך לא ידוע';

  @override
  String get rigPortsInactive => 'לא מאזין';

  @override
  String get rigPortsTooltipHost => 'פורטים פתוחים במסוף הזה';

  @override
  String get rigPortsEmptyHost =>
      'עדיין אין האזנה במסוף הזה. הפעילו שרת והוא יופיע כאן.';

  @override
  String get rigPortsAddHintHost => 'פורט למיפוי (למשל 5173)';

  @override
  String get rigPortsLocalPortHint => 'פורט מקומי (אופציונלי)';

  @override
  String rigPortsDestDesktop(int port) {
    return 'localhost:$port';
  }

  @override
  String rigPortsDestBrowser(int port) {
    return 'localhost:$port בדפדפן (מכונה וירטואלית)';
  }

  @override
  String get rigPortsDestBrowserUnreachable =>
      'דפדפן (מכונה וירטואלית) לא מחובר';

  @override
  String rigPortsDestAndroid(int port) {
    return 'localhost:$port ב-Android';
  }

  @override
  String get rigPortsDestAndroidUnreachable => 'Android לא מחובר';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'נותרו $count תמונות בסיס להורדה',
      many: 'נותרו $count תמונות בסיס להורדה',
      two: 'נותרו שתי תמונות בסיס להורדה',
      one: 'נותרה תמונת בסיס אחת להורדה',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => 'אפשר';

  @override
  String get guardrailDecisionPrompt => 'שאל קודם';

  @override
  String get guardrailDecisionDeny => 'חסום';

  @override
  String get guardrailSourceThisScope => 'טווח זה';

  @override
  String get guardrailSourceDefault => 'ברירת מחדל מובנית';

  @override
  String get guardrailSourcePreset => 'ערכת מצב';

  @override
  String get guardrailSourceInherited => 'בירושה';

  @override
  String get guardrailClearToInherited => 'נקה לערך שבירושה';

  @override
  String get guardrailWhatIf => 'מה אם?';

  @override
  String get guardrailWhatIfDescription =>
      'בדוק כיצד הכללים הנוכחיים יכריעו פעולה, לפי אותו היגיון שהסוכנים כפופים לו.';

  @override
  String get guardrailProbeActionLabel => 'פעולה';

  @override
  String get guardrailProbeCommandLabel => 'פקודה (אופציונלי)';

  @override
  String get guardrailProbeCommandHint => 'לדוגמה ⁨git push origin main⁩';

  @override
  String get guardrailProbeAgentLabel => 'סוכן (אופציונלי)';

  @override
  String get guardrailProbeSpaceLabel => 'מרחב (אופציונלי)';

  @override
  String get guardrailProbeNone => 'ללא';

  @override
  String get guardrailProbeModeLabel => 'מצב';

  @override
  String get guardrailProbeResult => 'תוצאה';

  @override
  String get guardrailProbeSource => 'מקור:';

  @override
  String get guardrailAdapterMatrix => 'היכן הכללים נאכפים';

  @override
  String get guardrailAdapterMatrixDescription =>
      'מסמך כן: היכן כל השפעה נתפסת בפועל, לפי מריץ הסוכן. זה מתעד את המציאות, לא הבטחה — השפעות שמריץ מבצע מחוץ לערוץ אינן ניתנות ליירוט.';

  @override
  String get guardrailEffectColumn => 'השפעה';

  @override
  String get guardrailAdapterHarness => 'מנגנון הרצה מובנה';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => 'רצפת ארגז החול';

  @override
  String get guardrailEnforcementPolicyGate => 'שער מדיניות';

  @override
  String get guardrailEnforcementSandbox => 'ארגז חול בלבד';

  @override
  String get guardrailEnforcementNone => 'לא ניתן לאכיפה';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      'החלטת ההרשאה נבדקת לפני שההשפעה רצה ויכולה לחסום אותה.';

  @override
  String get guardrailEnforcementSandboxHelp =>
      'רק ארגז החול מגביל אותה; כלל ההרשאה אינו נבדק.';

  @override
  String get guardrailEnforcementNoneHelp =>
      'ההחלטה מייעצת בלבד — לא ניתן ליירט אותה כאן.';

  @override
  String get obsStatCost => 'עלות';

  @override
  String obsStatDelegatedCost(String amount) {
    return '⁨+$amount⁩ בהאצלה';
  }

  @override
  String get obsStatDuration => 'משך';

  @override
  String get obsStatTokens => 'אסימונים';

  @override
  String get obsStatTools => 'כלים';

  @override
  String get openAgentActivity => 'פתח פעילות';

  @override
  String get orgChart => 'תרשים ארגוני';

  @override
  String get orgChartEmpty => 'אין סוכנים עדיין';

  @override
  String get navCalendar => 'לוח שנה';

  @override
  String get serverConnection => 'חיבור לשרת';

  @override
  String get serverModeLocal => 'הרץ באפליקציה זו';

  @override
  String get serverModeLocalDescription =>
      'Control Center מריץ שרת משלו במחשב זה ומחזיק בנתונים שלך באופן מקומי.';

  @override
  String get serverModeRemote => 'התחבר למופע מרוחק';

  @override
  String get serverModeRemoteDescription =>
      'התחבר לשרת Control Center שרץ במקום אחר. הנתונים שלך נמצאים בשרת ההוא.';

  @override
  String get serverRemoteUrl => 'כתובת URL של השרת';

  @override
  String get serverRemoteDeviceId => 'מזהה מכשיר';

  @override
  String get serverRemotePairingKey => 'מפתח צימוד';

  @override
  String get serverRemotePairingKeyHint => 'הדבק את מפתח הצימוד מהשרת המרוחק';

  @override
  String get serverSetupInviteCode => 'קוד הזמנה';

  @override
  String get serverSetupInviteCodeHint =>
      'הדבק קוד הזמנה חד-פעמי (השאר ריק כדי להשתמש במפתח צימוד)';

  @override
  String get serverDiscoveryTooltip => 'מצא שרתים ברשת שלך';

  @override
  String get serverDiscoveryTitle => 'שרתים ברשת שלך';

  @override
  String get serverDiscoverySearching => 'מחפש שרתים…';

  @override
  String get serverDiscoveryEmpty =>
      'לא נמצאו שרתים. ודא שהשרת רץ ושמכשיר זה יכול להגיע אליו, ואז חפש שוב.';

  @override
  String get serverDiscoveryRefresh => 'חפש שוב';

  @override
  String get serverListActive => 'פעיל';

  @override
  String get serverListSwitch => 'החלף';

  @override
  String get serverListAddTitle => 'הוסף שרת';

  @override
  String get serverListRemoveActiveHint => 'עבור לשרת אחר לפני הסרת שרת זה.';

  @override
  String get serverSwitchFailedTitle => 'לא ניתן להחליף שרת';

  @override
  String get serverListInsecureBadge => 'לא מאובטח';

  @override
  String get connectionPathLocal => 'מקומי';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => 'מכבה';

  @override
  String get shutdownSubtitle => 'סוגר את השרת המקומי';

  @override
  String get shutdownServiceApprovals => 'אישורים';

  @override
  String get shutdownServiceBackgroundJobs => 'משימות רקע';

  @override
  String get shutdownServiceScheduler => 'מתזמן משימות';

  @override
  String get shutdownServiceCalendar => 'סנכרון לוח שנה';

  @override
  String get shutdownServiceWeather => 'מזג אוויר';

  @override
  String get shutdownServiceSoundscape => 'נוף צלילי';

  @override
  String get shutdownServiceMeetings => 'פגישות';

  @override
  String get shutdownServiceVoiceModels => 'מודלי קול';

  @override
  String get shutdownServiceNetworking => 'רשת';

  @override
  String get shutdownServicePresence => 'נוכחות';

  @override
  String get shutdownServiceDataSync => 'סנכרון נתונים';

  @override
  String get shutdownServiceDeviceRelay => 'ממסר מכשירים';

  @override
  String get shutdownServiceMcpConnections => 'חיבורי MCP';

  @override
  String get shutdownServiceCodeEditors => 'עורכי קוד';

  @override
  String get serverSharingTitle => 'שתף שרת זה';

  @override
  String get serverSharingDescription =>
      'הפוך שרת זה לנגיש מהמכשירים האחרים שלך. שום דבר אינו חשוף לציבור אלא אם תפעיל מנהרה למטה. הזמנות צימוד מטמיעות אוטומטית את הכתובות הנוכחיות של השרת — צור אותן תחת הגדרות סביבת העבודה.';

  @override
  String get serverSharingUnavailable => 'בקרות שיתוף אינן זמינות בשרת זה.';

  @override
  String get serverSharingMdnsLabel => 'גילוי ברשת מקומית';

  @override
  String get serverSharingMdnsOn => 'מפרסם שרת זה ברשת המקומית שלך (mDNS)';

  @override
  String get serverSharingMdnsOff => 'לא מפרסם ברשת המקומית שלך (mDNS)';

  @override
  String get serverSharingTunnelLabel => 'מנהרה';

  @override
  String get serverSharingTunnelHelper =>
      'הפעלת מנהרה הופכת שרת זה לנגיש מהאינטרנט. חשיפה ציבורית היא בהסכמה בלבד וכבויה כברירת מחדל.';

  @override
  String get serverSharingProviderOff => 'כבוי';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => 'כתובת URL ציבורית';

  @override
  String get serverSharingTunnelStarting => 'מפעיל את המנהרה…';

  @override
  String serverSharingTunnelError(String error) {
    return 'שגיאת מנהרה: ⁨$error⁩';
  }

  @override
  String get serverSharingTunnelUpNoUrl =>
      'המנהרה פעילה. גש אליה דרך שם המארח שהגדרת ב-DNS.';

  @override
  String get serverSharingRelayLabel => 'ממסר';

  @override
  String serverSharingRelayUsage(String amount) {
    return 'הועבר בממסר החודש: ⁨$amount⁩';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return 'חיבורי ממסר פעילים: $count';
  }

  @override
  String get serverSharingUpdateFailedTitle => 'לא ניתן לעדכן את השיתוף';

  @override
  String get pairNewClient => 'צמד לקוח חדש';

  @override
  String get pairClientNameHint => 'תן שם ללקוח זה (למשל מחשב נייד לעבודה)';

  @override
  String get pairClientTypeWeb => 'דפדפן אינטרנט';

  @override
  String get pairClientTypeDesktop => 'אפליקציית שולחן עבודה';

  @override
  String get pairClientTypePhone => 'טלפון';

  @override
  String get pairAction => 'צמד';

  @override
  String get revoke => 'בטל גישה';

  @override
  String get pairCredentialsIntro =>
      'חבר את הלקוח החדש באמצעות הפרטים האלה, או פתח בו את הקישור.';

  @override
  String get pairLinkLabel => 'קישור';

  @override
  String get pairScanQr => 'סרוק קוד QR זה במצלמת הטלפון שלך כדי לצמד אותו.';

  @override
  String get pairServerUnreachableTitle => 'לא נגיש';

  @override
  String get pairServerUnreachable =>
      'מכשירים אחרים אינם יכולים להגיע לשרת זה ישירות, ולכן לקוח חדש לא יכול להתחבר. הגדר את כתובת ה-URL הציבורית של השרת כדי לצמד לקוחות נוספים.';

  @override
  String get serverSetupTitle => 'כיצד להריץ את Control Center?';

  @override
  String get serverSetupSubtitle =>
      'Control Center זקוק לשרת שמחזיק בנתונים שלך. הרץ אחד בתוך האפליקציה הזו, או התחבר למופע שרץ במקום אחר.';

  @override
  String get serverSetupRunLocal => 'הרץ באפליקציה זו';

  @override
  String get serverSetupConnect => 'התחבר';

  @override
  String get serverSetupInvalidUrl =>
      'הזן כתובת שרת חוקית מסוג ⁨ws://⁩ או ⁨wss://⁩.';

  @override
  String get serverSetupCouldNotConnect => 'לא ניתן להתחבר';

  @override
  String get serverSetupErrorUnreachable =>
      'לא הצלחנו להגיע לשרת. ודא שהוא רץ ושמכשיר זה יכול להגיע אליו (אותה רשת או ממסר).';

  @override
  String get serverSetupErrorIdentityMismatch =>
      'זהות השרת אינה תואמת לזו השמורה במכשיר זה. אם השרת הותקן מחדש או אופס, הסר את השרת השמור וצמד שוב.';

  @override
  String get serverSetupErrorAuthRejected =>
      'השרת דחה מכשיר זה. ודא שמפתח הצימוד ומזהה המכשיר תואמים למה שהשרת הנפיק.';

  @override
  String get serverSetupErrorInviteRejected =>
      'קוד ההזמנה אינו חוקי או שפג תוקפו. בקש קוד חדש.';

  @override
  String get serverSetupErrorGeneric =>
      'משהו השתבש בעת ההתחברות. הרחב את הפרטים הטכניים למטה למידע נוסף.';

  @override
  String get serverSetupErrorDetails => 'פרטים טכניים';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'עוד $count',
      many: 'עוד $count',
      two: 'עוד שניים',
      one: 'עוד אחד',
    );
    return '$_temp0';
  }

  @override
  String get calendarAllDayGutter => 'כל היום';

  @override
  String calendarAllDayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count אירועים',
      many: '$count אירועים',
      two: 'שני אירועים',
      one: 'אירוע אחד',
    );
    return '$_temp0';
  }

  @override
  String get calendarCollapseAllDay => 'כווץ אירועי יום שלם';

  @override
  String get calendarExpandAllDay => 'הרחב אירועי יום שלם';

  @override
  String get calendarViewMonth => 'חודש';

  @override
  String get calendarViewWeek => 'שבוע';

  @override
  String get calendarViewAgenda => 'סדר יום';

  @override
  String get calendarConnectGoogle => 'חבר את Google Calendar';

  @override
  String get calendarConnectDescription =>
      'סנכרן את Google Calendar שלך כדי לראות אירועים כאן ולקבל התראות לפני שפגישות מתחילות.';

  @override
  String get calendarDisconnect => 'נתק';

  @override
  String get calendarReconnect => 'חבר מחדש';

  @override
  String get calendarEmptyNoEvents => 'אין אירועים בטווח זה';

  @override
  String get calendarStartRecording => 'התחל הקלטה';

  @override
  String get calendarStartRecordingAndLink => 'התחל הקלטה וקישור';

  @override
  String get calendarJoinMeet => 'הצטרף לפגישה';

  @override
  String get calendarFromCalendar => 'מלוח השנה';

  @override
  String get calendarLinkedMeeting => 'פגישה מקושרת';

  @override
  String get calendarToday => 'היום';

  @override
  String get calendarAllDay => 'כל היום';

  @override
  String calendarWeekNumber(int number) {
    return 'שבוע $number';
  }

  @override
  String get calendarPreviousPeriod => 'הקודם';

  @override
  String get calendarNextPeriod => 'הבא';

  @override
  String calendarLastSynced(String time) {
    return 'סונכרן $time';
  }

  @override
  String get calendarNeverSynced => 'טרם סונכרן';

  @override
  String get calendarSyncing => 'מסנכרן…';

  @override
  String get calendarViewDay => 'יום';

  @override
  String get calendarShow => 'הצג';

  @override
  String get calendarHide => 'הסתר';

  @override
  String get calendarRsvpGoing => 'מגיע?';

  @override
  String get calendarRsvpYes => 'כן';

  @override
  String get calendarRsvpNo => 'לא';

  @override
  String get calendarRsvpMaybe => 'אולי';

  @override
  String get calendarRsvpFailed => 'לא ניתן לעדכן את התשובה שלך';

  @override
  String get calendarAddAccount => 'הוסף חשבון לוח שנה';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'חברו חשבון Google כדי לסנכרן אירועים למרחב הזה. לוחות השנה האלה הם שלך כאן.';

  @override
  String get calendarConnecting => 'מתחבר…';

  @override
  String get calendarSyncNow => 'סנכרן עכשיו';

  @override
  String get calendarNoWorkspace => 'בחר סביבת עבודה כדי לצפות בלוח השנה שלה';

  @override
  String get calendarConnectError => 'לא ניתן לחבר את Google Calendar';

  @override
  String get calendarClientIdLabel => 'מזהה לקוח';

  @override
  String get calendarClientSecretLabel => 'סוד לקוח';

  @override
  String get calendarConnectCredsHint =>
      'הזן את ה-Client ID וה-Client secret של Google OAuth (קוד מכשיר) עבור הפרויקט שלך. השרת מבצע את החיבור והסנכרון — הדפדפן שלך לעולם אינו מחזיק באסימוני הגישה.';

  @override
  String get calendarConnectApproveInstruction =>
      'פתח את דף האימות בכל מכשיר, היכנס והזן את הקוד הזה:';

  @override
  String get calendarConnectOpenPage => 'פתח דף אימות';

  @override
  String get calendarConnectWaiting => 'ממתין לאישור…';

  @override
  String get calendarConnectDenied => 'ההרשאה נדחתה. נסה שוב.';

  @override
  String get calendarConnectExpired => 'תוקף הקוד פג. נסה שוב.';

  @override
  String get notificationMeetingStartsSoon => 'פגישה מתחילה בקרוב';

  @override
  String get notifyMeetingStartsSoon => 'כאשר פגישה מלוח השנה עומדת להתחיל';

  @override
  String get notificationCalendarAuthExpiredTitle => 'לוח השנה נותק';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'חבר מחדש את ⁨$email⁩ כדי לחדש את הסנכרון';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'חבר מחדש את לוח השנה כדי לחדש את הסנכרון';

  @override
  String get notifyCalendarAuthExpired => 'כאשר חשבון לוח שנה דורש חיבור מחדש';

  @override
  String get notificationRigStatusChanged => 'עדכוני מתחם מבודד';

  @override
  String get notifyRigStatusChanged =>
      'כאשר מתחם מבודד עובר השתלטות, נסגר אוטומטית או נכשל';

  @override
  String get notificationRigTakenOver => 'השתלטות על מתחם מבודד';

  @override
  String get notificationRigTakenOverBody =>
      'אדם שולט במכונה; הסוכן יכול לצפות אך לא לפעול.';

  @override
  String get notificationRigReleased => 'השליטה במתחם המבודד שוחררה';

  @override
  String get notificationRigReleasedBody => 'המכונה חזרה לידי הסוכן.';

  @override
  String get notificationRigReclaimed => 'מתחם מבודד נסגר אוטומטית';

  @override
  String get notificationRigReclaimedBodyIdle =>
      'הוא עמד ללא פעילות, ולכן המכונה נסגרה כדי לפנות זיכרון.';

  @override
  String get notificationRigReclaimedBodyTtl =>
      'הוא הגיע למגבלת הזמן שלו ונסגר.';

  @override
  String get notificationRigFailed => 'המתחם המבודד נכשל';

  @override
  String get notificationRigFailedBody =>
      'ההיפרוויזור קרס מתחתיו. פתח מחדש את המכונה כדי להמשיך.';

  @override
  String get calendarAlertLeadTime => 'זמן התראה מראש';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'כמה זמן לפני פגישה לשלוח לך התראה';

  @override
  String calendarConnectedAs(String email) {
    return 'מחובר בתור ⁨$email⁩';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count משתתפים';
  }

  @override
  String get calendarEventLabel => 'אירוע';

  @override
  String get calendarRecurring => 'אירוע חוזר';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'מארגן';

  @override
  String get calendarYou => 'אתה';

  @override
  String get calendarShowFewer => 'הצג פחות';

  @override
  String get calendarRsvpAwaiting => 'ממתין';

  @override
  String calendarParticipantsCount(int count) {
    return '$count משתתפים';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'הצג את כל $count המשתתפים';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count כן';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count לא';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count אולי';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count ממתינים';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count דקות';
  }

  @override
  String get openInEditorPrompt => 'באיזה עורך לפתוח?';

  @override
  String get ideNotInstalled => 'לא מותקן';

  @override
  String openInIde(String editor) {
    return 'פתח ב-⁨$editor⁩';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return 'לא ניתן לפתוח את ⁨$editor⁩: ⁨$error⁩';
  }

  @override
  String get profileSearchHint => 'חפש בקשות משיכה…';

  @override
  String get stopAgentRun => 'עצור הרצה';

  @override
  String get stopAgentRunConfirm => 'לעצור הרצה זו? עבודה שבתהליך תאבד.';

  @override
  String get inProgress => 'בתהליך';

  @override
  String get drafts => 'טיוטות';

  @override
  String get sortOldest => 'הישן ביותר';

  @override
  String get sortLargest => 'הגדול ביותר';

  @override
  String get prFilterTooltip => 'סינון';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count מסננים פעילים',
      many: '$count מסננים פעילים',
      two: 'שני מסננים פעילים',
      one: 'מסנן פעיל אחד',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => 'הוסף מסנן…';

  @override
  String get prFilterFieldHint => 'סינון…';

  @override
  String get prFilterCategoryStatus => 'סטטוס';

  @override
  String get prFilterCategoryAuthor => 'מחבר';

  @override
  String get prFilterCategoryReviewer => 'סוקרים';

  @override
  String get prFilterCategoryContent => 'תוכן';

  @override
  String get prFilterCategoryRepoOwner => 'בעלי המאגר';

  @override
  String get prFilterCategoryRepoName => 'שם המאגר';

  @override
  String get prFilterCategoryOpenedDate => 'תאריך פתיחה';

  @override
  String get prFilterCategoryUpdatedDate => 'תאריך עדכון';

  @override
  String get prFilterQuickToReview => 'מהיר לסקירה';

  @override
  String get prFilterClearAll => 'נקה מסננים';

  @override
  String prFilterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count בקשות משיכה',
      many: '$count בקשות משיכה',
      two: 'שתי בקשות משיכה',
      one: 'בקשת משיכה אחת',
    );
    return '$_temp0';
  }

  @override
  String prFilterHiddenOptions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count אפשרויות שאינן תואמות אף בקשת משיכה',
      many: '$count אפשרויות שאינן תואמות אף בקשת משיכה',
      two: 'שתי אפשרויות שאינן תואמות אף בקשת משיכה',
      one: 'אפשרות אחת שאינה תואמת אף בקשת משיכה',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => 'הכותרת או הגוף מכילים…';

  @override
  String get prFilterNoOptions => 'אין אפשרויות תואמות';

  @override
  String get prFilterChipIs => 'הוא';

  @override
  String get prFilterChipIsAnyOf => 'הוא אחד מתוך';

  @override
  String get prFilterChipContains => 'מכיל';

  @override
  String get prFilterChipSince => 'מאז';

  @override
  String get prFilterAddFilterButton => 'הוסף מסנן';

  @override
  String prFilterClearCategory(String category) {
    return 'נקה מסנן $category';
  }

  @override
  String get prFilterCurrentUser => 'המשתמש הנוכחי';

  @override
  String get prStatusDraft => 'טיוטה';

  @override
  String get prStatusOpen => 'פתוחה';

  @override
  String get prStatusInReview => 'בסקירה';

  @override
  String get prStatusChangesRequested => 'התבקשו שינויים';

  @override
  String get prStatusApproved => 'אושרה';

  @override
  String get prStatusMerged => 'מוזגה';

  @override
  String get prStatusClosed => 'נסגרה';

  @override
  String get prDateWindowDay => 'לפני יום';

  @override
  String get prDateWindowThreeDays => 'לפני 3 ימים';

  @override
  String get prDateWindowWeek => 'לפני שבוע';

  @override
  String get prDateWindowMonth => 'לפני חודש';

  @override
  String get prDateWindowThreeMonths => 'לפני 3 חודשים';

  @override
  String get prDateWindowSixMonths => 'לפני 6 חודשים';

  @override
  String get prDateWindowYear => 'לפני שנה';

  @override
  String get prDisplayOptions => 'אפשרויות תצוגה';

  @override
  String get prDisplayGrouping => 'קיבוץ';

  @override
  String get prDisplayOrdering => 'מיון';

  @override
  String get prDisplayShowDrafts => 'הצג טיוטות';

  @override
  String get prDisplayMergedWindow => 'חלון מיזוגים';

  @override
  String get prDisplayMergedWindowDay => 'היממה האחרונה';

  @override
  String get prDisplayMergedWindowWeek => 'השבוע האחרון';

  @override
  String get prDisplayMergedWindowMonth => 'החודש האחרון';

  @override
  String get prDisplayProperties => 'מאפייני תצוגה';

  @override
  String get prGroupingRepository => 'מאגר';

  @override
  String get prGroupingAuthor => 'מחבר';

  @override
  String get prGroupingStatus => 'סטטוס';

  @override
  String get prGroupingNone => 'ללא קיבוץ';

  @override
  String get prPropertyRepository => 'מאגר';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => 'ענף';

  @override
  String get prPropertyUpdated => 'עודכן';

  @override
  String get prPropertyAuthor => 'מחבר';

  @override
  String get prPropertyChecks => 'בדיקות';

  @override
  String get prPropertyDiff => 'הבדלים';

  @override
  String get prPropertyComments => 'תגובות';

  @override
  String get keybindingOpenFilterMenu => 'פתח את תפריט הסינון';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'פתח את תפריט הסינון של בקשות המשיכה';

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'נבחרו $count',
      many: 'נבחרו $count',
      two: 'נבחרו שניים',
      one: 'נבחר אחד',
    );
    return '$_temp0';
  }

  @override
  String get summary => 'סיכום';

  @override
  String get kbMove => 'מעבר';

  @override
  String get kbTabs => 'כרטיסיות';

  @override
  String get kbSearch => 'חיפוש';

  @override
  String get kbViewed => 'נצפה';

  @override
  String get kbCollapse => 'כיווץ';

  @override
  String get appearance => 'מראה';

  @override
  String get appearanceSettingsDescription => 'ערכת נושא, שפה וטיפוגרפיה.';

  @override
  String get notificationsSettingsDescription =>
      'בחר אילו אירועי סוכנים וסביבת עבודה יתריעו לך.';

  @override
  String get advanced => 'מתקדם';

  @override
  String get accounts => 'חשבונות';

  @override
  String get mcpServers => 'שרתי MCP';

  @override
  String get mcpServersSettingsDescription =>
      'שרת ה-MCP המובנה ושרתי MCP חיצוניים.';

  @override
  String get remoteControlAndDevices => 'שליטה מרחוק ומכשירים';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'צמד טלפונים והגדר את שרת השליטה מרחוק.';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'מודלי הדיבור וזיהוי הדוברים ששרת זה מארח.';

  @override
  String get needsSetupLabel => 'דורש הגדרה';

  @override
  String get collapseSidebar => 'כווץ סרגל צד';

  @override
  String get expandSidebar => 'הרחב סרגל צד';

  @override
  String get filterSpacesHint => 'סנן מרחבים';

  @override
  String noSpacesMatch(String query) {
    return 'אין מרחבים תואמים ל-\"$query\"';
  }

  @override
  String get privacy => 'פרטיות';

  @override
  String get sendDiffContentTitle => 'שלח תוכן diff למתאם ה-AI';

  @override
  String get diffSharingOnSubtitle =>
      'שורות diff גולמיות נכללות בהנחיות הסוכנים לסקירה מעמיקה יותר.';

  @override
  String get diffSharingOffSubtitle =>
      'סוכנים משתמשים רק במטא-נתונים מובנים (נתיבי קבצים, מספרי שורות, תיאור ה-PR); שום קוד גולמי אינו יוצא מהאפליקציה.';

  @override
  String get errorReportingTitle => 'שתף דוחות קריסה';

  @override
  String get errorReportingOnSubtitle =>
      'נתוני אבחון של קריסות, שגיאות וביצועים נשלחים כדי לעזור בתיקון באגים (גרסאות שחרור בלבד).';

  @override
  String get errorReportingOffSubtitle =>
      'האבחון כבוי. לא נשלחים דוחות קריסה או שגיאות.';

  @override
  String get onboardingDiagnosticsTitle => 'עזור לשפר את Control Center';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'שלח נתוני אבחון של קריסות, שגיאות וביצועים כדי שנוכל לתקן בעיות מהר יותר (גרסאות שחרור בלבד). ניתן לשנות זאת בכל עת בהגדרות ← פרטיות.';

  @override
  String get blocked => 'חסום';

  @override
  String get idle => 'לא פעיל';

  @override
  String get noRunsYet => 'אין הרצות עדיין';

  @override
  String get copyPath => 'העתק נתיב';

  @override
  String get copyRelativePath => 'העתק נתיב יחסי';

  @override
  String get nameRequired => 'נדרש שם';

  @override
  String get import => 'ייבא';

  @override
  String get noMatchingAgents => 'אין סוכנים התואמים למסנן שלך';

  @override
  String watchVideoOn(String provider) {
    return 'צפה בסרטון ב-⁨$provider⁩';
  }

  @override
  String get branchTemplate => 'תבנית שם ענף';

  @override
  String get branchTemplateDescription =>
      'תבנית לענף שנוצר כאשר כרטיס מופעל בעץ עבודה מבודד.';

  @override
  String branchTemplatePreview(String example) {
    return 'לדוגמה: ⁨$example⁩';
  }

  @override
  String get deletePipelineRun => 'מחק הרצת צינור עבודה';

  @override
  String deletePipelineRunConfirm(String template) {
    return 'למחוק הרצה זו של \"$template\"? לא ניתן לבטל פעולה זו.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'שגיאה במחיקת הרצת צינור עבודה: ⁨$error⁩';
  }

  @override
  String get deleteTicket => 'מחק כרטיס';

  @override
  String deleteTicketConfirm(String title) {
    return 'למחוק את \"$title\"? לא ניתן לבטל פעולה זו.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'שגיאה במחיקת כרטיס: ⁨$error⁩';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return 'למחוק את \"$name\"? מאגרים מקושרים בדיסק לא ייפגעו.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'שגיאה במחיקת סביבת עבודה: ⁨$error⁩';
  }

  @override
  String get indexCode => 'אינדוקס קוד';

  @override
  String get indexNoGrammars => 'דקדוקי הקוד אינם מותקנים';

  @override
  String get indexFailed => 'האינדוקס נכשל';

  @override
  String indexedSymbolsCount(int count) {
    return '$count סמלים נוספו לאינדקס';
  }

  @override
  String get nodeConfigAdvanced => 'מתקדם';

  @override
  String get nodeConfigReducer => 'Reducer';

  @override
  String get nodeConfigReducerHelp =>
      'כיצד למזג כאשר למפתח הפלט הזה כבר יש ערך';

  @override
  String get nodeConfigTimeoutMs => 'זמן קצוב (ms)';

  @override
  String get nodeConfigRetryAttempts => 'ניסיונות חוזרים';

  @override
  String get nodeConfigContinueOnFail => 'המשך אם שלב זה נכשל';

  @override
  String get nodeConfigTeamId => 'מזהה צוות';

  @override
  String get nodeConfigDispatchMode => 'מצב שיגור';

  @override
  String get nodeConfigOutputSchema => 'סכמת פלט (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp => 'סכמת JSON שפלט השלב חייב לעמוד בה';

  @override
  String get diffLineDisplay => 'שורות ארוכות ב-diff';

  @override
  String get diffLineDisplayDescription => 'גלישת שורות ארוכות או גלילה אופקית';

  @override
  String get diffLineWrap => 'גלישה';

  @override
  String get diffLineScroll => 'גלילה אופקית';

  @override
  String get actions => 'פעולות';

  @override
  String get activate => 'הפעלה';

  @override
  String get activity => 'פעילות';

  @override
  String get activityLabel => 'פעילות';

  @override
  String get activitySearchHint => 'חיפוש בפעילות';

  @override
  String get activityNoMatches => 'אין פעילות שתואמת את הסינון';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$start–$end מתוך $total';
  }

  @override
  String get activityPreviousPage => 'העמוד הקודם';

  @override
  String get activityNextPage => 'העמוד הבא';

  @override
  String get activityNetworkLocal => 'מארח מקומי';

  @override
  String get activityClearFilter => 'ניקוי סינון';

  @override
  String activityFilterIp(String ip) {
    return 'IP ⁨$ip⁩';
  }

  @override
  String activityFilterCountry(String country) {
    return 'מדינה $country';
  }

  @override
  String get activitySavedWorkspaceLogo => 'שמר את הלוגו של סביבת העבודה';

  @override
  String activityVerbCreated(String target) {
    return 'יצר $target';
  }

  @override
  String activityVerbUpdated(String target) {
    return 'עדכן $target';
  }

  @override
  String activityVerbDeleted(String target) {
    return 'מחק $target';
  }

  @override
  String activityVerbAdded(String target) {
    return 'הוסיף $target';
  }

  @override
  String activityVerbRemoved(String target) {
    return 'הסיר $target';
  }

  @override
  String activityVerbInvited(String target) {
    return 'הזמין $target';
  }

  @override
  String activityVerbChanged(String target) {
    return 'שינה $target';
  }

  @override
  String activityVerbStarted(String target) {
    return 'התחיל $target';
  }

  @override
  String activityVerbStopped(String target) {
    return 'עצר $target';
  }

  @override
  String activityVerbWrote(String target) {
    return 'כתב $target';
  }

  @override
  String get activityTargetAgent => 'סוכן';

  @override
  String get activityTargetTicket => 'כרטיס';

  @override
  String get activityTargetWorkspace => 'סביבת עבודה';

  @override
  String get activityTargetRepository => 'מאגר';

  @override
  String get activityTargetMember => 'חבר';

  @override
  String get activityTargetInvite => 'הזמנה';

  @override
  String get activityTargetSpace => 'מרחב';

  @override
  String get activityTargetMessage => 'הודעה';

  @override
  String get activityTargetCache => 'מטמון';

  @override
  String get activityTargetFile => 'קובץ';

  @override
  String get activityTargetPipeline => 'פייפליין';

  @override
  String get activityTargetTemplate => 'תבנית';

  @override
  String get activityTargetProvider => 'ספק';

  @override
  String get activityTargetModel => 'מודל';

  @override
  String get activityTargetSkill => 'מיומנות';

  @override
  String get activityTargetTodo => 'משימה';

  @override
  String get activityTargetMeeting => 'פגישה';

  @override
  String get activityTargetProject => 'פרויקט';

  @override
  String get activityTargetTeam => 'צוות';

  @override
  String get activityTargetDevice => 'מכשיר';

  @override
  String get activityTargetPreference => 'העדפה';

  @override
  String get activityTargetBudget => 'תקציב';

  @override
  String activityVerbApproved(String target) {
    return 'אישר $target';
  }

  @override
  String activityVerbArchived(String target) {
    return 'העביר $target לארכיון';
  }

  @override
  String activityVerbAssigned(String target) {
    return 'הקצה $target';
  }

  @override
  String activityVerbBackedUp(String target) {
    return 'גיבה $target';
  }

  @override
  String activityVerbCancelled(String target) {
    return 'ביטל $target';
  }

  @override
  String activityVerbCleared(String target) {
    return 'ניקה $target';
  }

  @override
  String activityVerbClosed(String target) {
    return 'סגר $target';
  }

  @override
  String activityVerbCommitted(String target) {
    return 'ביצע קומיט של $target';
  }

  @override
  String activityVerbCompacted(String target) {
    return 'דחס $target';
  }

  @override
  String activityVerbCompleted(String target) {
    return 'השלים $target';
  }

  @override
  String activityVerbConnected(String target) {
    return 'חיבר $target';
  }

  @override
  String activityVerbContinued(String target) {
    return 'המשיך $target';
  }

  @override
  String activityVerbDisconnected(String target) {
    return 'ניתק $target';
  }

  @override
  String activityVerbDispatched(String target) {
    return 'שיגר $target';
  }

  @override
  String activityVerbDrained(String target) {
    return 'ריקן $target';
  }

  @override
  String activityVerbEnrolled(String target) {
    return 'רשם $target';
  }

  @override
  String activityVerbEstimated(String target) {
    return 'העריך $target';
  }

  @override
  String activityVerbImported(String target) {
    return 'ייבא $target';
  }

  @override
  String activityVerbInstalled(String target) {
    return 'התקין $target';
  }

  @override
  String activityVerbKilled(String target) {
    return 'עצר בכוח $target';
  }

  @override
  String activityVerbMarked(String target) {
    return 'סימן $target';
  }

  @override
  String activityVerbMerged(String target) {
    return 'מיזג $target';
  }

  @override
  String activityVerbOpened(String target) {
    return 'פתח $target';
  }

  @override
  String activityVerbPaused(String target) {
    return 'השהה $target';
  }

  @override
  String activityVerbPolled(String target) {
    return 'תשאל $target';
  }

  @override
  String activityVerbPrepared(String target) {
    return 'הכין $target';
  }

  @override
  String activityVerbProcessed(String target) {
    return 'עיבד $target';
  }

  @override
  String activityVerbPublished(String target) {
    return 'פרסם $target';
  }

  @override
  String activityVerbRefined(String target) {
    return 'שכלל $target';
  }

  @override
  String activityVerbRefreshed(String target) {
    return 'רענן $target';
  }

  @override
  String activityVerbRegistered(String target) {
    return 'רשם $target';
  }

  @override
  String activityVerbRenamed(String target) {
    return 'שינה שם של $target';
  }

  @override
  String activityVerbReordered(String target) {
    return 'סידר מחדש $target';
  }

  @override
  String activityVerbResponded(String target) {
    return 'הגיב ל$target';
  }

  @override
  String activityVerbRestored(String target) {
    return 'שחזר $target';
  }

  @override
  String activityVerbResumed(String target) {
    return 'חידש $target';
  }

  @override
  String activityVerbRetried(String target) {
    return 'ניסה שוב $target';
  }

  @override
  String activityVerbReverted(String target) {
    return 'החזיר $target לקדמותו';
  }

  @override
  String activityVerbReviewed(String target) {
    return 'סקר $target';
  }

  @override
  String activityVerbRan(String target) {
    return 'הריץ $target';
  }

  @override
  String activityVerbSelected(String target) {
    return 'בחר $target';
  }

  @override
  String activityVerbSent(String target) {
    return 'שלח $target';
  }

  @override
  String activityVerbStaged(String target) {
    return 'העביר $target ל־staging';
  }

  @override
  String activityVerbSteered(String target) {
    return 'כיוון $target';
  }

  @override
  String activityVerbSubmitted(String target) {
    return 'הגיש $target';
  }

  @override
  String activityVerbSynced(String target) {
    return 'סנכרן $target';
  }

  @override
  String activityVerbToggled(String target) {
    return 'שינה את המצב של $target';
  }

  @override
  String activityVerbUninstalled(String target) {
    return 'הסיר את ההתקנה של $target';
  }

  @override
  String activityVerbUnstaged(String target) {
    return 'הוציא $target מ־staging';
  }

  @override
  String get activityTargetActionPolicy => 'מדיניות פעולות';

  @override
  String get activityTargetGoalRun => 'הרצת יעד';

  @override
  String get activityTargetRunLog => 'יומן הרצה';

  @override
  String get activityTargetWorkingMemory => 'זיכרון עבודה';

  @override
  String get activityTargetRoutingPolicy => 'מדיניות ניתוב';

  @override
  String get activityTargetAutonomy => 'אוטונומיה';

  @override
  String get activityTargetCalendar => 'לוח שנה';

  @override
  String get activityTargetChecker => 'בודק';

  @override
  String get activityTargetEditor => 'עורך';

  @override
  String get activityTargetConfirmation => 'אישור';

  @override
  String get activityTargetTunnel => 'מנהרה';

  @override
  String get activityTargetConversation => 'שיחה';

  @override
  String get activityTargetCredentials => 'פרטי גישה';

  @override
  String get activityTargetDictation => 'הכתבה';

  @override
  String get activityTargetAgentRun => 'הרצת סוכן';

  @override
  String get activityTargetEvalSuite => 'חבילת הערכה';

  @override
  String get activityTargetWorker => 'worker';

  @override
  String get activityTargetWorktree => 'עץ עבודה';

  @override
  String get activityTargetMcpServer => 'שרת MCP';

  @override
  String get activityTargetMemoryAccessGrant => 'הרשאת גישה לזיכרון';

  @override
  String get activityTargetMemoryDomain => 'תחום זיכרון';

  @override
  String get activityTargetMemoryFact => 'עובדת זיכרון';

  @override
  String get activityTargetMemoryPolicy => 'מדיניות זיכרון';

  @override
  String get activityTargetFeed => 'פיד';

  @override
  String get activityTargetNote => 'פתק';

  @override
  String get activityTargetOrchestration => 'אורקסטרציה';

  @override
  String get activityTargetPipelineRun => 'הרצת פייפליין';

  @override
  String get activityTargetPipelineTrigger => 'טריגר פייפליין';

  @override
  String get activityTargetPlan => 'תוכנית';

  @override
  String get activityTargetPlaybook => 'פלייבוק';

  @override
  String get activityTargetPullRequest => 'בקשת משיכה';

  @override
  String get activityTargetReview => 'סקירה';

  @override
  String get activityTargetProcess => 'תהליך';

  @override
  String get activityTargetProviderPolicy => 'מדיניות ספק';

  @override
  String get activityTargetReaction => 'ריאקציה';

  @override
  String get activityTargetReviewSpace => 'מרחב סקירה';

  @override
  String get activityTargetReviewStudio => 'סטודיו סקירה';

  @override
  String get activityTargetServerData => 'נתוני שרת';

  @override
  String get activityTargetSoundscape => 'נוף צלילי';

  @override
  String get activityTargetSession => 'סשן';

  @override
  String get activityTargetTerminal => 'טרמינל';

  @override
  String get activityTargetTicketLink => 'קישור כרטיס';

  @override
  String get activityTargetTicketSync => 'סנכרון כרטיסים';

  @override
  String get activityTargetProfile => 'פרופיל';

  @override
  String get activityTargetVoiceProfile => 'פרופיל קול';

  @override
  String get activityTargetWeather => 'תחזית מזג אוויר';

  @override
  String get activityTargetWorkProduct => 'תוצר עבודה';

  @override
  String get activityChangedMemberRole => 'שינה תפקיד של חבר';

  @override
  String get activityChangedMemberRepoAccess => 'שינה גישת מאגרים של חבר';

  @override
  String get activityUpdatedGitHubToken => 'עדכן את אסימון הגישה של GitHub';

  @override
  String get activityRefreshedWeather => 'רענן את תחזית מזג האוויר';

  @override
  String get activitySetWeatherLocation => 'הגדיר את מיקום מזג האוויר';

  @override
  String get activityClearedWeatherLocation => 'ניקה את מיקום מזג האוויר';

  @override
  String get activityMarkedAllArticlesRead => 'סימן את כל הכתבות כנקראו';

  @override
  String get activityMarkedArticleRead => 'סימן כתבה כנקראה';

  @override
  String get activityUpdatedSavedArticle => 'עדכן כתבה שמורה';

  @override
  String get activityTookOverSession => 'השתלט על הסשן';

  @override
  String get activityHandedBackSession => 'החזיר את השליטה בסשן';

  @override
  String get activityCommittedAndPushed => 'ביצע קומיט ודחף';

  @override
  String get activityBackedUpServer => 'גיבה את נתוני השרת';

  @override
  String get activityMarkedSpaceRead => 'סימן את המרחב כנקרא';

  @override
  String get activityRespondedToInvitation => 'הגיב להזמנה לאירוע';

  @override
  String get activityStartedCalendarConnect => 'התחיל את חיבור לוח השנה';

  @override
  String get activityDisconnectedCalendar => 'ניתק את לוח השנה';

  @override
  String get activityMarkedFileViewed => 'סימן קובץ כנצפה';

  @override
  String get activityRespondedToApproval => 'הגיב לבקשת אישור';

  @override
  String get activityChangedTunnel => 'שינה את הגדרת המנהרה';

  @override
  String get activitySentMessageToAgent => 'שלח הודעה לסוכן';

  @override
  String get activityOpenedReviewSpace => 'פתח את מרחב הסקירה';

  @override
  String get activityOpenedStandingConversation => 'פתח את השיחה הקבועה';

  @override
  String get activityStartedRecording => 'התחיל את ההקלטה';

  @override
  String get activityStoppedRecording => 'עצר את ההקלטה';

  @override
  String get activityToggledMcpServer => 'שינה את מצב שרת ה־MCP';

  @override
  String get activityUpdatedMcpToken => 'עדכן את אסימון הגישה של MCP';

  @override
  String get activitySavedApiKey => 'שמר מפתח API';

  @override
  String get activityRemovedProviderCredential => 'הסיר פרטי גישה של ספק';

  @override
  String get activityUpdatedLinkedRepos => 'עדכן את המאגרים המקושרים';

  @override
  String get activityUnlinkedRepo => 'ביטל קישור של מאגר';

  @override
  String get activityUpdatedActionItem => 'עדכן פריט פעולה';

  @override
  String adRulesCount(int count) {
    return '$count כללי פרסומות';
  }

  @override
  String get adapter => 'מתאם';

  @override
  String get adapterLabel => 'מתאם';

  @override
  String get adapters => 'מתאמים';

  @override
  String get adaptersAutoDetected =>
      'מריצי סוכנים שזוהו אוטומטית במחשב זה. התקינו כלי CLI חסרים כדי להפעיל מריצים נוספים.';

  @override
  String get add => 'הוספה';

  @override
  String get addAComment => 'הוספת תגובה';

  @override
  String get addAReaction => 'הוספת ריאקציה';

  @override
  String get addASuggestion => 'הוספת הצעה';

  @override
  String get addAgents => 'הוספת סוכנים';

  @override
  String get addEmoji => 'הוספת אימוג׳י';

  @override
  String get addFeed => 'הוספת פיד';

  @override
  String get addressBarHint => 'הזינו כתובת URL';

  @override
  String get addFromFile => 'הוספה מקובץ';

  @override
  String get addGif => 'הוספת GIF';

  @override
  String get addGithubRepoPrompt =>
      'הוסיפו לפחות מאגר GitHub אחד כדי לראות בקשות משיכה';

  @override
  String get addLocalCheckoutDescription =>
      'הוסיפו עותק מקומי כדי להתחיל לעבוד עליו מסביבת העבודה הזו.';

  @override
  String get addRepository => 'הוספת מאגר';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'הוספת $count מאגרים',
      many: 'הוספת $count מאגרים',
      two: 'הוספת $count מאגרים',
      one: 'הוספת מאגר',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro =>
      'עיינו בתיקיות במחשב שמריץ את השרת ובחרו את מאגרי ה־Git לרישום.';

  @override
  String get selectThisFolder => 'בחירת תיקייה זו';

  @override
  String get deselectThisFolder => 'ביטול בחירת תיקייה זו';

  @override
  String get goUp => 'למעלה';

  @override
  String get noSubfoldersHere => 'אין כאן תיקיות משנה';

  @override
  String get notAGitRepository => 'תיקייה זו אינה מאגר Git.';

  @override
  String get addToken => 'הוספת אסימון גישה';

  @override
  String get addWorkspace => 'הוספת סביבת עבודה';

  @override
  String get addWorkspaceEllipsis => 'הוספת סביבת עבודה…';

  @override
  String get added => 'נוסף';

  @override
  String get addingEllipsis => 'מוסיף…';

  @override
  String get advancedLabel => 'מתקדם';

  @override
  String get agent => 'סוכן';

  @override
  String agentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count סוכנים',
      many: '$count סוכנים',
      two: '$count סוכנים',
      one: '$count סוכן',
    );
    return '$_temp0';
  }

  @override
  String get agentMdPath => 'נתיב Agent MD';

  @override
  String get agentName => 'שם הסוכן';

  @override
  String get agentTitle => 'תפקיד הסוכן';

  @override
  String get agentUpdated => 'הסוכן עודכן.';

  @override
  String get agents => 'סוכנים';

  @override
  String get agentsMentionSection => 'סוכנים';

  @override
  String get usersMentionSection => 'אנשים';

  @override
  String get ticketsMentionSection => 'כרטיסים';

  @override
  String get pullRequestsMentionSection => 'בקשות משיכה';

  @override
  String get meetingsMentionSection => 'פגישות';

  @override
  String get entityRefTicketFallback => 'כרטיס';

  @override
  String get entityRefPrFallback => 'בקשת משיכה';

  @override
  String get entityRefMeetingFallback => 'פגישה';

  @override
  String get aiReview => 'סקירת AI';

  @override
  String get all => 'הכול';

  @override
  String get allAgentsAlreadyInSpace => 'כל הסוכנים כבר נמצאים במרחב הזה.';

  @override
  String get allCommits => 'כל הקומיטים';

  @override
  String get allSources => 'כל המקורות';

  @override
  String get allow => 'אפשר';

  @override
  String get allowGitPush => 'אפשר git push';

  @override
  String get allowGithubApi => 'אפשר קריאות ל־API של GitHub';

  @override
  String get allowNetwork => 'אפשר גישה כללית לרשת';

  @override
  String get apiKeys => 'מפתחות API';

  @override
  String get appFont => 'גופן האפליקציה';

  @override
  String get appLogLevelDebugDescription => 'מוסיף מעקבים מפורטים – לפיתוח.';

  @override
  String get appLogLevelDebugLabel => 'דיבאג';

  @override
  String get appLogLevelErrorDescription => 'רק שגיאות וחריגות לא צפויות.';

  @override
  String get appLogLevelErrorLabel => 'שגיאה';

  @override
  String get appLogLevelInfoDescription => 'מוסיף הודעות סטטוס ומחזור חיים.';

  @override
  String get appLogLevelInfoLabel => 'מידע';

  @override
  String get appLogLevelNoneDescription => 'ללא פלט קונסולה כלל.';

  @override
  String get appLogLevelNoneLabel => 'ללא';

  @override
  String get appLogLevelVerboseDescription =>
      'הכול. רועש מאוד – לשימוש בדיבאג בלבד.';

  @override
  String get appLogLevelVerboseLabel => 'מפורט';

  @override
  String get appLogLevelWarningDescription =>
      'מוסיף אזהרות ותקלות שניתן להתאושש מהן.';

  @override
  String get appLogLevelWarningLabel => 'אזהרה';

  @override
  String get appearanceLanguage => 'מראה ושפה';

  @override
  String get apply => 'החלה';

  @override
  String get approve => 'אישור';

  @override
  String get agentApprovalRequired => 'נדרש אישור';

  @override
  String agentApprovalsMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'עוד $count ממתינות',
      many: 'עוד $count ממתינות',
      two: 'עוד $count ממתינות',
      one: 'עוד פעולה אחת ממתינה',
    );
    return '$_temp0';
  }

  @override
  String get approved => 'אושר';

  @override
  String get articleNoun => 'מאמר';

  @override
  String get articlesSubscribed => 'כתבות מכל הפידים שאתם מנויים עליהם.';

  @override
  String get askAi => 'שאל את ה־AI';

  @override
  String get askAiReviewDescription => 'בקשו מה־AI לסקור את ה־PR הזה';

  @override
  String get assignees => 'אחראים';

  @override
  String get attachImage => 'צירוף תמונה';

  @override
  String get attachedAgents => 'סוכנים מצורפים';

  @override
  String get audioInput => 'כניסת שמע';

  @override
  String get audioOutput => 'יציאת שמע';

  @override
  String get authenticationToken => 'אסימון גישה';

  @override
  String authoredByLabel(String role) {
    return 'מאת: $role';
  }

  @override
  String get autoRecommended => 'אוטומטי (מומלץ)';

  @override
  String get available => 'זמין';

  @override
  String get awaitingYourReview => 'ממתין לסקירה שלך';

  @override
  String get back => 'חזרה';

  @override
  String get backLabel => 'חזרה';

  @override
  String get backend => 'בקאנד';

  @override
  String get blockAdsTrackers => 'חסימת פרסומות, רכיבי מעקב ובאנרים של עוגיות';

  @override
  String get blocking => 'חוסם';

  @override
  String get bookmarkLabel => 'סימנייה';

  @override
  String get briefDescription => 'תיאור קצר';

  @override
  String get bugLabel => 'באג';

  @override
  String get bundledDefaultsNeverUpdated =>
      'ברירות מחדל מובנות — לא עודכנו מעולם';

  @override
  String get cancel => 'ביטול';

  @override
  String get cancelEdit => 'ביטול עריכה';

  @override
  String get categoryCreation => 'יצירה';

  @override
  String get categoryEditing => 'עריכה';

  @override
  String get categoryNavigation => 'ניווט';

  @override
  String get categorySystem => 'מערכת';

  @override
  String get categoryView => 'תצוגת קטגוריות';

  @override
  String get change => 'שינוי';

  @override
  String get changesRequested => 'התבקשו שינויים';

  @override
  String get spacesMentionSection => 'מרחבים';

  @override
  String get checkForUpdates => 'בדיקת עדכונים';

  @override
  String get checking => 'בודק';

  @override
  String get checkingEllipsis => 'בודק…';

  @override
  String get chooseAppFont => 'בחירת גופן האפליקציה';

  @override
  String get chooseCodeFont => 'בחירת גופן הקוד';

  @override
  String get chooseRunner => 'בחרו את מריץ הסוכנים שלכם.';

  @override
  String get clear => 'ניקוי';

  @override
  String get clickToRetry => 'לחצו כדי לנסות שוב';

  @override
  String get close => 'סגירה';

  @override
  String get closeEsc => 'סגירה (Esc)';

  @override
  String get closeReader => 'סגירת תצוגת הקריאה';

  @override
  String get closed => 'סגור';

  @override
  String get codeFont => 'גופן קוד';

  @override
  String get codeFontLigatures => 'ליגטורות בגופן הקוד';

  @override
  String get codeFontLigaturesDescription =>
      'הצגת ליגטורות תכנות (=>, !=, ->) כסימנים משולבים בקוד ובדיפים';

  @override
  String get collapse => 'כיווץ';

  @override
  String get commandPalette => 'לוח פקודות';

  @override
  String get commandPaletteOrgMembers => 'חברי הארגון';

  @override
  String get commandPaletteBrowseTeam => 'עיון בצוות';

  @override
  String get commandPaletteBrowseTeamDesc => 'הצגת כל חברי הארגון';

  @override
  String get compactDone => 'השיחה נדחסה. היסטוריה מוקדמת קופלה לתוך סיכום.';

  @override
  String get compactNothing => 'אין עדיין מה לדחוס. השיחה עדיין קצרה.';

  @override
  String get compactBusy => 'סוכן עדיין עובד. דחסו כשהתור הנוכחי יסתיים.';

  @override
  String get compactUnavailable => 'דחיסה אינה זמינה בשרת זה.';

  @override
  String get commandsMentionSection => 'פקודות';

  @override
  String get comment => 'תגובה';

  @override
  String get commentOnThisFile => 'הוספת תגובה לקובץ זה';

  @override
  String get commented => 'הגיב';

  @override
  String get commits => 'קומיטים';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'מציג את $loaded הקומיטים האחרונים מתוך $total';
  }

  @override
  String get prCloneProgressCloningTitle => 'שיבוט המאגר';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'PR זה משנה $fileCount קבצים, מעבר למגבלת ה־API של GitHub. משבט את המאגר מקומית…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'PR זה חורג ממגבלת הקבצים של ה־API של GitHub. משבט את המאגר מקומית…';

  @override
  String get prCloneProgressFetchingTitle => 'אחזור refs של ה־PR';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'מאחזר את ענף הבסיס ואת ה־head ref של ה־PR…';

  @override
  String get prCloneProgressComputingTitle => 'חישוב הדיף';

  @override
  String get prCloneProgressComputingSubtitle => 'מריץ git diff מקומית…';

  @override
  String get prCloneProgressErrorTitle => 'טעינת הדיף נכשלה';

  @override
  String get prCloneProgressErrorSubtitle =>
      'אירעה שגיאה בזמן שיבוט המאגר או חישוב הדיף. נסו לרענן.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'עדיין עובד… חלפו ⁨$elapsed⁩';
  }

  @override
  String confidenceLabel(int percent) {
    return 'רמת ביטחון: $percent%';
  }

  @override
  String get configureAgentIdentities =>
      'הגדירו זהויות, הנחיות ומיומנויות של סוכנים וצפו בהרצות.';

  @override
  String get configureDefaultRunners =>
      'הגדירו איזה מתאם ומודל ישמשו למרחבים חדשים וליצירת כותרות.';

  @override
  String get configuredLabel => 'הוגדר.';

  @override
  String get confirmedBy => 'אושר על ידי';

  @override
  String get consensus => 'קונצנזוס';

  @override
  String get contentHint => 'מה צריך לזכור';

  @override
  String get contentLabel => 'תוכן';

  @override
  String get contentMarkdown => 'תוכן (Markdown)';

  @override
  String get contextWindowSize => 'גודל חלון ההקשר';

  @override
  String modelContextChip(String size) {
    return 'מודל · ⁨$size⁩';
  }

  @override
  String get continueLabel => 'המשך';

  @override
  String get conversationMode => 'מצב';

  @override
  String cookieRulesCount(int count) {
    return '$count כללי עוגיות';
  }

  @override
  String get copied => 'הועתק!';

  @override
  String get copy => 'העתקה';

  @override
  String get copyAddress => 'העתקת כתובת';

  @override
  String get copyBaseBranchTooltip => 'העתקת שם ענף הבסיס';

  @override
  String get copyHeadBranchTooltip => 'העתקת שם ענף ה־head';

  @override
  String couldNotListDevices(String error) {
    return 'לא ניתן להציג את רשימת המכשירים: ⁨$error⁩';
  }

  @override
  String get create => 'יצירה';

  @override
  String get createOrSelectWorkspace =>
      'צרו או בחרו סביבת עבודה לפני הוספת מאגרים.';

  @override
  String get createPullRequest => 'יצירת בקשת משיכה';

  @override
  String get createdByMe => 'נוצרו על ידיי';

  @override
  String createdLabel(String date) {
    return 'נוצר: $date';
  }

  @override
  String get currentParticipants => 'משתתפים נוכחיים';

  @override
  String get customCapabilitiesDescription => 'תיאור יכולות מותאמות אישית';

  @override
  String get customSystemPrompt => 'הנחיית מערכת מותאמת אישית לסוכן זה...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'לפני $count ימים',
      many: 'לפני $count ימים',
      two: 'לפני יומיים',
      one: 'לפני יום',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'השבתה';

  @override
  String get defaultCapabilities => 'יכולות ברירת מחדל · מרחבים חדשים';

  @override
  String get defaultChat => 'צ׳אט ברירת מחדל';

  @override
  String get defaultRunners => 'מריצי ברירת מחדל';

  @override
  String get delete => 'מחיקה';

  @override
  String get deleteAgent => 'מחיקת סוכן';

  @override
  String deleteAgentConfirm(String name) {
    return 'למחוק את \"$name\"? פעולה זו אינה ניתנת לביטול.';
  }

  @override
  String get deleteSpace => 'מחיקת מרחב';

  @override
  String deleteConfirmName(String name) {
    return 'למחוק את \"$name\"?';
  }

  @override
  String get archiveConversation => 'העברת השיחה לארכיון';

  @override
  String get deleteFact => 'מחיקת עובדה';

  @override
  String get deleteFeedBody =>
      'פעולה זו מסירה את הפיד ואת כל הכתבות השמורות שלו במטמון. גם כתבות שסומנו בסימנייה מהפיד הזה יוסרו.';

  @override
  String deleteFeedConfirm(String name) {
    return 'למחוק את \"$name\"?';
  }

  @override
  String get deletePolicy => 'מחיקת מדיניות';

  @override
  String get deletePolicyConfirm =>
      'למחוק מדיניות זו? פעולה זו אינה ניתנת לביטול.';

  @override
  String deleteTopicConfirm(String topic) {
    return 'למחוק את \"$topic\"? פעולה זו אינה ניתנת לביטול.';
  }

  @override
  String get deleteWorkspace => 'מחיקת סביבת עבודה';

  @override
  String get deny => 'דחייה';

  @override
  String get detailsLabel => 'פרטים';

  @override
  String get descriptionLabel => 'תיאור';

  @override
  String detectedBackend(String label) {
    return 'זוהה: ⁨$label⁩';
  }

  @override
  String get detectedRunners => 'מריצים שזוהו';

  @override
  String get detectingAdapters => 'מזהה מתאמים…';

  @override
  String get detectingInputDevices => 'מזהה התקני קלט…';

  @override
  String detectionFailed(String error) {
    return 'הזיהוי נכשל: ⁨$error⁩';
  }

  @override
  String get disabled => 'מושבת';

  @override
  String get discover => 'גילוי';

  @override
  String get dismissed => 'נדחה';

  @override
  String get domainHint => 'למשל api-performance';

  @override
  String get domainLabel => 'תחום';

  @override
  String get download => 'הורדה';

  @override
  String get downloadingLabel => 'מוריד';

  @override
  String downloadingModel(int pct) {
    return 'מוריד מודל… $pct%';
  }

  @override
  String get draft => 'טיוטה';

  @override
  String get draftLabel => 'טיוטה';

  @override
  String get edit => 'עריכה';

  @override
  String get edited => 'נערך';

  @override
  String get editMessage => 'עריכת הודעה';

  @override
  String get revertToThere => 'שחזור לנקודה ההיא';

  @override
  String get sendAsNewMessage => 'שליחה כהודעה חדשה';

  @override
  String get editMessageChoiceBody =>
      'השחזור מסתיר את ההודעות שאחרי זו ומחזיר את קבצי הסוכן. אפשר לבטל את זה. שליחה כהודעה חדשה משאירה את השיחה כפי שהיא.';

  @override
  String get deleteMessage => 'מחיקת הודעה';

  @override
  String get deleteMessageConfirm =>
      'למחוק הודעה זו? פעולה זו אינה ניתנת לביטול.';

  @override
  String get messageDeleted => 'ההודעה נמחקה';

  @override
  String get searchInConversation => 'חיפוש בשיחה';

  @override
  String get searchMessagesHint => 'חיפוש הודעות…';

  @override
  String get noMessagesFound => 'לא נמצאו הודעות';

  @override
  String get editFact => 'עריכת עובדה';

  @override
  String get editPolicy => 'עריכת מדיניות';

  @override
  String get editSuggestedCodeHint => 'עריכת הקוד המוצע…';

  @override
  String get editSuggestion => 'עריכת הצעה';

  @override
  String get egArchitect => 'למשל architect';

  @override
  String get egControlCenter => 'למשל control-center';

  @override
  String get egPlatform => 'למשל Platform';

  @override
  String get egSamuelAlev => 'למשל SamuelAlev';

  @override
  String get egSoftwareArchitect => 'למשל ארכיטקט תוכנה';

  @override
  String get egTheVerge => 'למשל The Verge';

  @override
  String get egTokenLimit => 'למשל 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'ההתקנה נכשלה: ⁨$error⁩';
  }

  @override
  String get embeddingInstalled =>
      'מודל ההטמעות המקומי הותקן. חיפוש היברידי הופעל.';

  @override
  String get embeddingModel => 'מודל הטמעות (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'לא מותקן. עד להפעלה, החיפוש מתבסס על מילות מפתח בלבד.';

  @override
  String get embeddingRedownloadBody =>
      'קובצי המודל הקיימים יימחקו ויורדו מחדש. חיפוש סמנטי לא יהיה זמין עד להשלמת ההורדה.';

  @override
  String get embeddingRemoveBody =>
      'חיפוש סמנטי יושבת עד להתקנה מחדש. ניתן להתקין אותו שוב בכל עת.';

  @override
  String get speakerDiarization => 'הפרדת דוברים';

  @override
  String get diarizationModel => 'מודל הפרדת דוברים';

  @override
  String get diarizationInstalled => 'מותקן — נותן שמות לדוברים בתמלולי פגישות';

  @override
  String get diarizationNotInstalled => 'לא מותקן — דוברים בפגישות לא יופרדו';

  @override
  String diarizationInstallFailed(String error) {
    return 'ההתקנה נכשלה: ⁨$error⁩';
  }

  @override
  String get redownloadDiarizationModel => 'הורדה מחדש של מודל הפרדת הדוברים';

  @override
  String get diarizationRedownloadBody =>
      'פעולה זו מסירה את מודלי הפרדת הדוברים הנוכחיים ומורידה אותם מחדש.';

  @override
  String get removeDiarizationModel => 'הסרת מודל הפרדת הדוברים';

  @override
  String get diarizationRemoveBody =>
      'פעולה זו מוחקת את מודלי הפרדת הדוברים שבמכשיר. תמלולי פגישות שכבר הופקו לא יושפעו.';

  @override
  String get enableNotifications => 'הפעלת התראות';

  @override
  String get enableSandboxing => 'הפעלת ארגז חול';

  @override
  String get enabled => 'מופעל';

  @override
  String errorCreatingAgent(String error) {
    return 'שגיאה ביצירת סוכן: ⁨$error⁩';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'שגיאה במחיקת סוכן: ⁨$error⁩';
  }

  @override
  String errorWithDetail(String error) {
    return 'שגיאה: ⁨$error⁩';
  }

  @override
  String get expand => 'הרחבה';

  @override
  String extractingModel(int pct) {
    return 'מחלץ מודל… $pct%';
  }

  @override
  String get fact => 'עובדה';

  @override
  String factCount(int count) {
    return '$count עובדה';
  }

  @override
  String factCountPlural(int count) {
    return '$count עובדות';
  }

  @override
  String get facts => 'עובדות';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount עובדות · $policyCount כללי מדיניות';
  }

  @override
  String get failed => 'נכשל';

  @override
  String failedToDispatch(String error) {
    return 'השיגור נכשל: ⁨$error⁩';
  }

  @override
  String get failedToLoad => 'הטעינה נכשלה';

  @override
  String failedToLoadAgents(String error) {
    return 'טעינת הסוכנים נכשלה: ⁨$error⁩';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'טעינת הפידים נכשלה: ⁨$error⁩';
  }

  @override
  String get failedToLoadGifs => 'טעינת קובצי GIF נכשלה';

  @override
  String failedToLoadLogs(String error) {
    return 'טעינת היומנים נכשלה: ⁨$error⁩';
  }

  @override
  String get failedToLoadRepos => 'טעינת המאגרים נכשלה';

  @override
  String get failedToLoadWorkspaces => 'טעינת סביבות העבודה נכשלה';

  @override
  String failedToStartAiReview(String error) {
    return 'הפעלת סקירת ה־AI נכשלה: ⁨$error⁩';
  }

  @override
  String get failedToStartMicTest => 'הפעלת בדיקת המיקרופון נכשלה.';

  @override
  String failedToSubmitReview(String error) {
    return 'שליחת הסקירה נכשלה: ⁨$error⁩';
  }

  @override
  String failedToUpload(String name, String error) {
    return 'העלאת ⁨$name⁩ נכשלה: ⁨$error⁩';
  }

  @override
  String failedWithError(String error) {
    return 'נכשל: ⁨$error⁩';
  }

  @override
  String get failure => 'כישלון';

  @override
  String get feedAlreadyExists => 'פיד עם כתובת URL זו כבר קיים.';

  @override
  String get feedUrlExample => 'למשל https://example.com/feed.xml';

  @override
  String get feedUrlLabel => 'כתובת URL של הפיד';

  @override
  String feedsCount(int count) {
    return 'פידים ($count)';
  }

  @override
  String get filesChanged => 'קבצים ששונו';

  @override
  String filesCount(int count) {
    return '$count קבצים';
  }

  @override
  String get filesMentionSection => 'קבצים';

  @override
  String get filterAgents => 'סינון סוכנים...';

  @override
  String get filterFilesHint => 'סינון קבצים…';

  @override
  String get filterLists => 'רשימות סינון';

  @override
  String get filterSkillsPlaceholder => 'סינון מיומנויות…';

  @override
  String get finish => 'סיום';

  @override
  String get fix => 'תיקון';

  @override
  String get forward => 'קדימה';

  @override
  String get gatesGithubPatPush =>
      'שולט בהזרקת ה־PAT של GitHub. נדרש כדי שהסוכן יוכל לבצע push.';

  @override
  String get general => 'כללי';

  @override
  String get githubLink => 'קישור GitHub';

  @override
  String get claudeStatusFetchFailed => 'לא ניתן להגיע אל status.claude.com';

  @override
  String get claudeStatusOpenInBrowser => 'פתיחת status.claude.com';

  @override
  String get githubStatusFetchFailed => 'לא ניתן להגיע אל githubstatus.com';

  @override
  String get githubDegradedTitle => 'GitHub מדווח על בעיות';

  @override
  String githubDegradedStatusLine(String status) {
    return 'סטטוס GitHub: $status.';
  }

  @override
  String githubDegradedBody(String status) {
    return 'סטטוס GitHub: $status. נתוני בקשות משיכה עשויים להיות לא מעודכנים או חלקיים עד להתאוששות.';
  }

  @override
  String get githubStatusOpenInBrowser => 'פתיחת githubstatus.com';

  @override
  String get githubStatusRefresh => 'רענון';

  @override
  String githubStatusUpdated(String time) {
    return 'עודכן $time';
  }

  @override
  String get kimiStatusFetchFailed => 'לא ניתן להגיע אל status.moonshot.cn';

  @override
  String get kimiStatusOpenInBrowser => 'פתיחת status.moonshot.cn';

  @override
  String get openaiStatusFetchFailed => 'לא ניתן להגיע אל status.openai.com';

  @override
  String get openaiStatusOpenInBrowser => 'פתיחת status.openai.com';

  @override
  String get serviceStatusMaintenance => 'תחזוקה';

  @override
  String get serviceStatusMajorIssues => 'בעיות חמורות';

  @override
  String get serviceStatusMinorIssues => 'בעיות קלות';

  @override
  String get serviceStatusOperational => 'תקין';

  @override
  String get serviceStatusOutage => 'הפסקת שירות';

  @override
  String get serviceStatusTitle => 'סטטוס שירותים';

  @override
  String get serviceStatusUnknown => 'לא ידוע';

  @override
  String lastChecked(String time) {
    return 'נבדק $time';
  }

  @override
  String get lastCheckedRecently => 'נבדק לאחרונה';

  @override
  String get giveYourWorkAHome => 'תנו לעבודה שלכם בית.';

  @override
  String get goBack => 'מעבר אחורה';

  @override
  String get goForward => 'מעבר קדימה';

  @override
  String get googleFonts => 'גופני Google';

  @override
  String get high => 'גבוה';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'לפני $count שעות',
      many: 'לפני $count שעות',
      two: 'לפני שעתיים',
      one: 'לפני שעה',
    );
    return '$_temp0';
  }

  @override
  String get images => 'תמונות';

  @override
  String get inactive => 'לא פעיל';

  @override
  String get install => 'התקנה';

  @override
  String get installRequired => 'נדרשת התקנה';

  @override
  String installedVersion(String version) {
    return 'מותקנת גרסה ⁨$version⁩';
  }

  @override
  String get invite => 'הזמן';

  @override
  String get inviteAgent => 'הזמן סוכן';

  @override
  String get isolateAgentExecution => 'בידוד הרצת סוכנים.';

  @override
  String get justNow => 'ממש עכשיו';

  @override
  String get keepSandboxing => 'השאר ארגז חול';

  @override
  String get keybindingAddARepositoryDescription => 'הוספת מאגר';

  @override
  String get keybindingAddRepository => 'הוסף מאגר';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'הוספת או הסרת סימנייה מהכתבה הנבחרת';

  @override
  String get keybindingCommandPalette => 'לוח פקודות';

  @override
  String get keybindingCreateANewAgentDescription => 'יצירת סוכן חדש';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'יצירת סביבת עבודה חדשה';

  @override
  String get keybindingFocusSearch => 'מיקוד בחיפוש';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'מיקוד בשדה חיפוש בקשות המשיכה';

  @override
  String get keybindingNewAgent => 'סוכן חדש';

  @override
  String get keybindingNewWorkspace => 'סביבת עבודה חדשה';

  @override
  String get keybindingNextArticle => 'הכתבה הבאה';

  @override
  String get keybindingNextSpace => 'המרחב הבא';

  @override
  String get keybindingNextWorkspace => 'סביבת העבודה הבאה';

  @override
  String get keybindingOpenArticle => 'פתח כתבה';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'פתיחה או סגירה של חלונית החלפת סביבות העבודה בסרגל הצד';

  @override
  String get keybindingOpenPr => 'פתח PR';

  @override
  String get keybindingOpenSettings => 'פתח הגדרות';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'פתיחת הגדרות היישום';

  @override
  String get keybindingOpenTheCommandPaletteDescription => 'פתיחת לוח הפקודות';

  @override
  String get keybindingOpenTheSelectedArticleDescription =>
      'פתיחת הכתבה הנבחרת';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'פתיחת בקשת המשיכה הנבחרת';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'פתיחת סביבת העבודה הנבחרת';

  @override
  String get keybindingOpenWorkspace => 'פתח סביבת עבודה';

  @override
  String get keybindingPreviousArticle => 'הכתבה הקודמת';

  @override
  String get keybindingPreviousSpace => 'המרחב הקודם';

  @override
  String get keybindingPreviousWorkspace => 'סביבת העבודה הקודמת';

  @override
  String get keybindingRefresh => 'רענן';

  @override
  String get keybindingRefreshAllFeedsDescription => 'רענון כל הפידים';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'רענון רשימת בקשות המשיכה';

  @override
  String get keybindingRescanForAdaptersDescription => 'סריקה מחדש אחר מתאמים';

  @override
  String get keybindingSelectTheNextArticleDescription => 'בחירת הכתבה הבאה';

  @override
  String get keybindingSelectTheNextSpaceDescription => 'בחירת המרחב הבא';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'בחירת הכתבה הקודמת';

  @override
  String get keybindingSelectThePreviousSpaceDescription => 'בחירת המרחב הקודם';

  @override
  String get keybindingSendMessage => 'שלח הודעה';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'שליחת ההודעה הנוכחית';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'מעבר בין מצב בהיר למצב כהה';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'מעבר לסביבת העבודה השמינית';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'מעבר לסביבת העבודה החמישית';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'מעבר לסביבת העבודה הראשונה';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'מעבר לסביבת העבודה הרביעית';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'מעבר לסביבת העבודה הבאה';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'מעבר לסביבת העבודה התשיעית';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'מעבר לסביבת העבודה הקודמת';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'מעבר לסביבת העבודה השנייה';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'מעבר לסביבת העבודה השביעית';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'מעבר לסביבת העבודה השישית';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'מעבר לסביבת העבודה השלישית';

  @override
  String get keybindingToggleBookmark => 'הוסף/הסר סימנייה';

  @override
  String get keybindingToggleTheme => 'החלף ערכת נושא';

  @override
  String get keybindingToggleWorkspaceSwitcher => 'פתח/סגור מחליף סביבות עבודה';

  @override
  String get keybindingWorkspace1 => 'סביבת עבודה 1';

  @override
  String get keybindingWorkspace2 => 'סביבת עבודה 2';

  @override
  String get keybindingWorkspace3 => 'סביבת עבודה 3';

  @override
  String get keybindingWorkspace4 => 'סביבת עבודה 4';

  @override
  String get keybindingWorkspace5 => 'סביבת עבודה 5';

  @override
  String get keybindingWorkspace6 => 'סביבת עבודה 6';

  @override
  String get keybindingWorkspace7 => 'סביבת עבודה 7';

  @override
  String get keybindingWorkspace8 => 'סביבת עבודה 8';

  @override
  String get keybindingWorkspace9 => 'סביבת עבודה 9';

  @override
  String get keybindings => 'קיצורי מקלדת';

  @override
  String get keybindingsDescription =>
      'כל קיצורי המקלדת. הקיצורים קבועים ולא ניתן לשנות את ההקצאה שלהם.';

  @override
  String get killRunning => 'עצור הרצות פעילות';

  @override
  String get languageSystem => 'מערכת';

  @override
  String get leaveACommentEllipsis => 'השאר תגובה…';

  @override
  String get legendLabel => 'מקרא';

  @override
  String get lessLabel => 'פחות';

  @override
  String get letsPluginTools => 'בואו נחבר את הכלים שלך.';

  @override
  String get level => 'רמה';

  @override
  String get loadingAgents => 'טוען סוכנים…';

  @override
  String get loadingModels => 'טוען מודלים…';

  @override
  String get loadingProviders => 'טוען ספקים…';

  @override
  String get logLevel => 'רמת יומן';

  @override
  String get logs => 'יומנים';

  @override
  String get low => 'נמוך';

  @override
  String get maintenance => 'תחזוקה';

  @override
  String get manageParticipants => 'ניהול משתתפים';

  @override
  String get manageWorkspaces => 'ניהול סביבות עבודה';

  @override
  String get reorderWorkspace => 'שינוי סדר סביבת העבודה';

  @override
  String get matchOsAppearance => 'התאם למראה מערכת ההפעלה או בחר מצב קבוע.';

  @override
  String get mcpAuthToken => 'אסימון גישה של MCP';

  @override
  String get mcpNotAvailableOnServer =>
      'שליטה בשרת MCP אינה זמינה בשרת המחובר.';

  @override
  String get modelManagedOnServer => 'מודל זה רץ על מארח השרת ומנוהל שם.';

  @override
  String get mcpServer => 'שרת MCP';

  @override
  String get medium => 'בינוני';

  @override
  String get memoryDataHint => 'עובדות ומדיניות יופיעו כאן ככל שהסוכנים יעבדו.';

  @override
  String get memoryLabel => 'זיכרון';

  @override
  String get merge => 'מזג';

  @override
  String get merged => 'מוזג';

  @override
  String get messagePlaceholder => 'הודעה… (@ לאזכור, / לפקודות)';

  @override
  String get navConversations => 'מרחבים';

  @override
  String get microphonePermissionDenied => 'הרשאת המיקרופון נדחתה.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'לפני $count דקות',
      many: 'לפני $count דקות',
      two: 'לפני שתי דקות',
      one: 'לפני דקה',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'מודל';

  @override
  String get modified => 'שונה';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'לפני $count חודשים',
      many: 'לפני $count חודשים',
      two: 'לפני חודשיים',
      one: 'לפני חודש',
    );
    return '$_temp0';
  }

  @override
  String get moreLabel => 'עוד';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'שם';

  @override
  String get nameAndTitleRequired => 'יש להזין שם וכותרת.';

  @override
  String get nameAndUrlRequired => 'יש להזין שם ו־URL';

  @override
  String get nameLabel => 'שם';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'ארגז חול מקורי זמין ב־⁨$platform⁩.';
  }

  @override
  String get nativeSandboxNeedsInstall => 'נדרשת התקנת ארגז חול מקורי';

  @override
  String get navObservability => 'ניטור';

  @override
  String get navSettings => 'הגדרות';

  @override
  String networkBlockCount(int count) {
    return '$count חסימות רשת';
  }

  @override
  String get neutral => 'ניטרלי';

  @override
  String get newCommitsPushed =>
      'נדחפו קומיטים חדשים — לחץ כדי לטעון מחדש את ה־diff';

  @override
  String get newFact => 'עובדה חדשה';

  @override
  String get newPolicy => 'מדיניות חדשה';

  @override
  String get newsfeed => 'עדכוני חדשות';

  @override
  String get newsfeedLabel => 'עדכוני חדשות';

  @override
  String get newsfeedSettingsDescription =>
      'נהל את הפידים שלך ואת העדפות הקריאה.';

  @override
  String get newsfeedSettingsTitle => 'הגדרות עדכוני חדשות';

  @override
  String get nextMatch => 'ההתאמה הבאה (↵)';

  @override
  String get noActiveWorkspace => 'לא נבחרו סביבת עבודה או מאגר פעילים.';

  @override
  String get noActiveWorkspaceCreate => 'אין סביבת עבודה פעילה';

  @override
  String get noActiveWorkspaceGithub => 'אין סביבת עבודה פעילה עם מאגר GitHub.';

  @override
  String get noAgents => 'אין סוכנים';

  @override
  String get noArticlesYet => 'אין כתבות עדיין';

  @override
  String get noArticlesYetBody => 'כתבות מהפידים שלך יופיעו כאן.';

  @override
  String get noExecutionLogsYet => 'אין עדיין יומני הרצה';

  @override
  String get noFacts => 'אין עובדות עדיין';

  @override
  String get noFeedsYet => 'אין פידים עדיין';

  @override
  String get noFileAnchor => 'אין עוגן קובץ — לא ניתן לפרסם תגובה בשורת הקוד.';

  @override
  String get noFileChangesInScope => 'אין שינויי קבצים בהיקף זה';

  @override
  String get noGifsFound => 'לא נמצאו קובצי GIF';

  @override
  String get noInputDevicesDetected =>
      'לא זוהו התקני קלט — נעשה שימוש בברירת המחדל של המערכת.';

  @override
  String get noMatchingFiles => 'אין קבצים תואמים';

  @override
  String get noMatchingGoogleFonts => 'לא נמצאו גופנים תואמים ב־Google Fonts.';

  @override
  String get noMemoryData => 'אין עדיין נתוני זיכרון';

  @override
  String get noMessagesYet => 'אין הודעות עדיין';

  @override
  String get noModelsAdvertised => 'מתאם זה לא פרסם מודלים.';

  @override
  String get noOpenPullRequests => 'אין בקשות משיכה פתוחות';

  @override
  String get noPolicies => 'אין מדיניות עדיין';

  @override
  String get noReposInWorkspaceYet => 'אין עדיין מאגרים בסביבת עבודה זו';

  @override
  String get noRunnersDetected => 'עדיין לא זוהו מריצים. רענן כדי לסרוק שוב.';

  @override
  String get noSavedArticles => 'אין כתבות שמורות';

  @override
  String get noSavedArticlesBody => 'כתבות שתשמור יופיעו כאן.';

  @override
  String noShortcutsMatch(String query) {
    return 'אין קיצורים שתואמים ל־\"$query\"';
  }

  @override
  String get noSystemFonts => 'לא זוהו גופני מערכת.';

  @override
  String get noTokenSet => 'לא הוגדר אסימון גישה — הגישה אינה מוגבלת.';

  @override
  String get noWorkingMemory => 'אין עדיין רשומות זיכרון עבודה.';

  @override
  String get noneAllRoles => 'ללא (כל התפקידים)';

  @override
  String get notAvailable => 'לא זמין';

  @override
  String get notConfiguredLabel => 'לא מוגדר.';

  @override
  String get notFoundLabel => 'לא נמצא';

  @override
  String get notes => 'הערות';

  @override
  String get notificationAgentFinished => 'הסוכן סיים';

  @override
  String get notificationPrMentioned => 'אוזכרת בבקשת משיכה';

  @override
  String get notificationNewMessages => 'הודעות חדשות';

  @override
  String get notificationPrMerged => 'PR מוזג';

  @override
  String get notificationPrPublished => 'PR פורסם';

  @override
  String get notificationReviewRequested => 'התבקשה סקירה';

  @override
  String get notifications => 'התראות';

  @override
  String get notifyAgentRunCompleted => 'קבל התראה כשסוכן משלים הרצה.';

  @override
  String get notifyPrMentioned => 'קבל התראה כשמאזכרים אותך בבקשת משיכה.';

  @override
  String get notifyNewMessages =>
      'קבל התראה על הודעות חדשות מסוכנים במרחבים אחרים.';

  @override
  String get notifyPrMerged => 'קבל התראה כשבקשת משיכה ממוזגת.';

  @override
  String get notifyPrPublished => 'קבל התראה כשסוכן מפרסם בקשת משיכה.';

  @override
  String get notifyReviewRequested =>
      'קבל התראה כשמתבקשת ממך סקירה על בקשת משיכה.';

  @override
  String get notificationReviewStale => 'הסקירה אינה עדכנית';

  @override
  String get notifyReviewStale =>
      'כשקומיטים חדשים מגיעים לבקשת משיכה שכבר סקרת';

  @override
  String get notificationPrMergeReadiness => 'מוכן למיזוג';

  @override
  String get notifyPrMergeReadiness =>
      'קבל התראה כשבקשת משיכה שיצרת הופכת לניתנת למיזוג, או מפסיקה להיות כזו.';

  @override
  String get notificationPrReviewDecision => 'החלטות סקירה';

  @override
  String get notifyPrReviewDecision =>
      'קבל התראה כשסוקר מאשר, מבקש שינויים, או כשאישור מבוטל.';

  @override
  String get notificationPrChecksStatus => 'בדיקות';

  @override
  String get notifyPrChecksStatus =>
      'קבל התראה כש־CI נכשל בבקשת משיכה שיצרת, וכשהוא מתאושש.';

  @override
  String get notificationPrThreadActivity => 'שרשורי סקירה';

  @override
  String get notifyPrThreadActivity =>
      'קבל התראה כשמישהו משיב או פותר שרשור שאתה משתתף בו.';

  @override
  String get notificationPrReadyToMerge => 'מוכן למיזוג';

  @override
  String notificationPrReadyToMergeBody(String prTitle) {
    return 'ל־⁨$prTitle⁩ יש את כל מה שנדרש.';
  }

  @override
  String get notificationPrMergeBlocked => 'כבר לא ניתן למיזוג';

  @override
  String notificationPrMergeBlockedBodyConflicts(String prTitle) {
    return '⁨$prTitle⁩ מתנגש עם ענף הבסיס.';
  }

  @override
  String notificationPrMergeBlockedBodyBehind(String prTitle) {
    return '⁨$prTitle⁩ נמצא מאחורי ענף הבסיס.';
  }

  @override
  String notificationPrMergeBlockedBodyReviews(String prTitle) {
    return '⁨$prTitle⁩ ממתין לסקירה נדרשת.';
  }

  @override
  String notificationPrMergeBlockedBodyChanges(String prTitle) {
    return 'סוקר ביקש שינויים ב־⁨$prTitle⁩.';
  }

  @override
  String notificationPrMergeBlockedBodyChecks(String prTitle) {
    return 'בדיקות נכשלות ב־⁨$prTitle⁩.';
  }

  @override
  String notificationPrMergeBlockedBodyOther(String prTitle) {
    return 'לא ניתן עוד למזג את ⁨$prTitle⁩.';
  }

  @override
  String get notificationPrApproved => 'בקשת המשיכה אושרה';

  @override
  String notificationPrApprovedBodyBy(String login, String prTitle) {
    return '⁨$login⁩ אישר את ⁨$prTitle⁩';
  }

  @override
  String notificationPrApprovedBody(String prTitle) {
    return '⁨$prTitle⁩ אושר';
  }

  @override
  String notificationPrReviewersRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count סוקרים טרם הגיבו',
      many: '$count סוקרים טרם הגיבו',
      two: 'שני סוקרים טרם הגיבו',
      one: 'סוקר אחד טרם הגיב',
      zero: 'לא נותרו סוקרים',
    );
    return '$_temp0';
  }

  @override
  String get notificationPrChangesRequested => 'התבקשו שינויים';

  @override
  String notificationPrChangesRequestedBodyBy(String login, String prTitle) {
    return '⁨$login⁩ ביקש שינויים ב־⁨$prTitle⁩';
  }

  @override
  String notificationPrChangesRequestedBody(String prTitle) {
    return 'התבקשו שינויים ב־⁨$prTitle⁩';
  }

  @override
  String get notificationPrReviewDismissed => 'האישור בוטל';

  @override
  String notificationPrReviewDismissedBody(String prTitle) {
    return '⁨$prTitle⁩ זקוק לסקירה מחדש.';
  }

  @override
  String get notificationPrChecksFailed => 'בדיקות נכשלו';

  @override
  String notificationPrChecksFailedBody(String checkName, String prTitle) {
    return '⁨$checkName⁩ נכשלה ב־⁨$prTitle⁩';
  }

  @override
  String notificationPrChecksFailedBodyUnnamed(String prTitle) {
    return 'בדיקות נכשלות ב־⁨$prTitle⁩';
  }

  @override
  String get notificationPrChecksRecovered => 'בדיקות עוברות';

  @override
  String notificationPrChecksRecoveredBody(String prTitle) {
    return '⁨$prTitle⁩ שוב ירוק.';
  }

  @override
  String notificationPrMentionedInCommentBody(String login, String location) {
    return '⁨$login⁩ אזכר אותך ב־⁨$location⁩';
  }

  @override
  String get notificationPrThreadReplied => 'תגובה חדשה';

  @override
  String notificationPrThreadRepliedBody(String login, String location) {
    return '⁨$login⁩ השיב ב־⁨$location⁩';
  }

  @override
  String get notificationPrThreadResolved => 'השרשור נפתר';

  @override
  String notificationPrThreadResolvedBody(String location) {
    return 'השרשור שלך ב־⁨$location⁩ נפתר.';
  }

  @override
  String get notificationGroupAgents => 'סוכנים';

  @override
  String get notificationGroupPullRequests => 'בקשות משיכה';

  @override
  String get notificationGroupMessages => 'הודעות';

  @override
  String get notificationGroupTickets => 'כרטיסים';

  @override
  String get notificationGroupCalendar => 'לוח שנה';

  @override
  String get notificationGroupMachines => 'מכונות';

  @override
  String get notificationsMutedRepos => 'מאגרים מושתקים';

  @override
  String notificationsMutedReposCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count מאגרים הושתקו',
      many: '$count מאגרים הושתקו',
      two: 'שני מאגרים הושתקו',
      one: 'מאגר אחד הושתק',
      zero: 'לא הושתקו מאגרים',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMuteRepo => 'השתק מאגר זה';

  @override
  String get onboardingLinuxDescription =>
      'Control Center יכול להשתמש בקונטיינרים של Linux כדי לבודד הרצת סוכנים.';

  @override
  String get onboardingMacosDescription =>
      'Control Center משתמש בארגז חול מקורי ב־macOS כדי לבודד הרצת סוכנים.';

  @override
  String get onboardingUnsupportedDescription =>
      'ארגז חול אינו זמין בפלטפורמה זו. הרצת סוכנים תתבצע ללא בידוד.';

  @override
  String get openArticlesInApp => 'פתח כתבות בתוך היישום';

  @override
  String get openInBrowser => 'פתח בדפדפן';

  @override
  String get openedInYourBrowser => 'נפתח בדפדפן שלך.';

  @override
  String get openLabel => 'פתח';

  @override
  String get openOnGithub => 'פתח ב־GitHub';

  @override
  String get openStatus => 'פתוח';

  @override
  String get optionalPersonaDescription => 'תיאור פרסונה אופציונלי';

  @override
  String get otherLabel => 'אחר';

  @override
  String get ownerOrganization => 'בעלים / ארגון';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get passed => 'עבר';

  @override
  String get pasteValueHere => 'הדבק ערך כאן';

  @override
  String get persona => 'פרסונה';

  @override
  String get policies => 'מדיניות';

  @override
  String get policiesHint => 'מדיניות תופיע כאן ברגע שסוכנים יקדמו עובדות.';

  @override
  String get policy => 'מדיניות';

  @override
  String get popular => 'פופולרי';

  @override
  String get port => 'פורט';

  @override
  String get postingEllipsis => 'מפרסם…';

  @override
  String get prCommits => 'קומיטים';

  @override
  String get prMergedBody => 'בקשת משיכה מוזגה';

  @override
  String get prMoreActions => 'פעולות נוספות';

  @override
  String get prTitle => 'כותרת ה־PR';

  @override
  String get reviewCommentHint =>
      'פשוט לחץ על אשר, ואם בא לך קצת חריפות — הוסף תגובה או ריאקציה…';

  @override
  String get nothingToPreview => 'אין מה להציג בתצוגה מקדימה';

  @override
  String get previousMatch => 'ההתאמה הקודמת (⇧↵)';

  @override
  String get priorityReviewsDescription =>
      'סקירות בעדיפות גבוהה ומבט כולל על המאגרים.';

  @override
  String get prsCreated => 'PRs שנוצרו';

  @override
  String get prsMerged => 'PRs שמוזגו';

  @override
  String get publishToGithub => 'פרסם ב־GitHub';

  @override
  String get published => 'פורסם';

  @override
  String get pullRequestApproved => 'בקשת המשיכה אושרה';

  @override
  String get pullRequests => 'בקשות משיכה';

  @override
  String get questionLabel => 'שאלה';

  @override
  String get queued => 'ממתין בתור';

  @override
  String get react => 'הוסף ריאקציה';

  @override
  String get readPrsIssuesMetadata =>
      'מאפשר לסוכן לקרוא PRs, issues ומטא־נתונים של המאגר.';

  @override
  String get readerPreferences => 'העדפות קריאה';

  @override
  String get reasoningEffort => 'מאמץ חשיבה';

  @override
  String get recommendLabel => 'המלצה';

  @override
  String recordingFromDevice(String device) {
    return 'מקליט מ־⁨$device⁩.';
  }

  @override
  String get redownload => 'הורד מחדש';

  @override
  String get redownloadEmbeddingModel => 'להוריד מחדש את מודל ההטמעה?';

  @override
  String get redownloadVoiceModel => 'להוריד מחדש את מודל הקול?';

  @override
  String get refinePlan => 'חדד את התוכנית';

  @override
  String get refresh => 'רענן';

  @override
  String get refreshAll => 'רענן הכול';

  @override
  String get refreshAllFeeds => 'רענן את כל הפידים';

  @override
  String get reject => 'דחה';

  @override
  String get rejected => 'נדחה';

  @override
  String get reload => 'טען מחדש';

  @override
  String get remove => 'הסר';

  @override
  String get removeBookmark => 'הסר סימנייה';

  @override
  String get removeEmbeddingModel => 'להסיר את מודל ההטמעה?';

  @override
  String get removeLogo => 'הסר לוגו';

  @override
  String get removeRepoFromWorkspace => 'להסיר את המאגר מסביבת העבודה?';

  @override
  String get removeVoiceModel => 'להסיר את מודל הקול?';

  @override
  String get removed => 'הוסר';

  @override
  String get renamed => 'שם שונה';

  @override
  String get reopen => 'פתח מחדש';

  @override
  String get resolve => 'פתור';

  @override
  String get replyEllipsis => 'השב…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '⁨$name⁩ יוסר מסביבת עבודה זו. הקבצים המקומיים בדיסק לא יושפעו.';
  }

  @override
  String repoAccessNoticeBody(String repos) {
    return 'פרטי הגישה של השרת ל־GitHub לא רואים את ⁨$repos⁩. אם מאגר שייך לארגון, התקן שם את ה־GitHub App או חבר אסימון גישה עם הרשאה מתאימה.';
  }

  @override
  String repoAccessNoticeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'לא ניתן לגשת ל־$count מאגרים',
      many: 'לא ניתן לגשת ל־$count מאגרים',
      two: 'לא ניתן לגשת לשני מאגרים',
      one: 'לא ניתן לגשת למאגר אחד',
    );
    return '$_temp0';
  }

  @override
  String get repoAccessNoticeSuspendedTitle => 'התקנת GitHub App הושעתה';

  @override
  String repoAccessNoticeSuspendedBody(String repos) {
    return 'מוצגים הנתונים האחרונים הידועים עבור ⁨$repos⁩. חדש את ההתקנה ב-GitHub, או חבר אסימון עם גישה.';
  }

  @override
  String get repoNoAccessBadge => 'אין גישה';

  @override
  String get reportsTo => 'מדווח אל';

  @override
  String reposCount(int count) {
    return 'מאגרים ($count)';
  }

  @override
  String get reposDescription =>
      'עותקי הקוד המקומיים שסביבת עבודה זו עובדת מולם.';

  @override
  String get repositories => 'מאגרים';

  @override
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count מאגרים',
      many: '$count מאגרים',
      two: 'שני מאגרים',
      one: 'מאגר אחד',
    );
    return 'לא ניתן היה להוסיף $_temp0: ⁨$error⁩';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count מאגרים נוספו',
      many: '$count מאגרים נוספו',
      two: 'שני מאגרים נוספו',
      one: 'המאגר נוסף',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => 'הגדרות מאגרים';

  @override
  String get repositoryName => 'שם המאגר';

  @override
  String get requestChanges => 'בקש שינויים';

  @override
  String get requested => 'התבקש';

  @override
  String get requestedChanges => 'ביקש שינויים';

  @override
  String requiredRoleLabel(String role) {
    return 'תפקיד נדרש: $role';
  }

  @override
  String get requiredRoleOptional => 'תפקיד נדרש (אופציונלי)';

  @override
  String get requirements => 'דרישות';

  @override
  String get reset => 'אפס';

  @override
  String get resolved => 'נפתר';

  @override
  String get enclosedTerminalTitle => 'טרמינל במתחם מבודד';

  @override
  String get enclosedTerminalStart => 'פתח את ה־shell';

  @override
  String get enclosedTerminalStartHint =>
      'ה־shell הזה רץ בתוך ה־VM החד־פעמי של השיחה. הוא עולה כשפותחים אותו, לא כשהיישום מופעל.';

  @override
  String get terminalStreamReconnecting => 'הזרם נקטע — מתחבר מחדש…';

  @override
  String get terminalStreamError => 'שגיאת זרם:';

  @override
  String get terminalShellExited => 'ה־shell הסתיים';

  @override
  String get restartShell => 'הפעל מחדש את ה־shell';

  @override
  String get retry => 'נסה שוב';

  @override
  String get review => 'סקירה';

  @override
  String get reviewedByMe => 'נסקרו על ידיי';

  @override
  String get reviewers => 'סוקרים';

  @override
  String get roleLabel => 'תפקיד';

  @override
  String get ruleHint => 'כלל המדיניות (תמיכה ב־Markdown)';

  @override
  String get ruleLabel => 'כלל';

  @override
  String get runCompleted => 'ההרצה הושלמה';

  @override
  String get running => 'פועל';

  @override
  String get runningLabel => 'פועל';

  @override
  String get runs => 'הרצות';

  @override
  String get runsLabel => 'הרצות';

  @override
  String get sandboxBackendNativeLabel => 'ארגז חול מקורי';

  @override
  String get sandboxBackendMicrovmLabel => 'VM במתחם מבודד';

  @override
  String get sandboxBackendNoneLabel => 'ללא בידוד';

  @override
  String get sandboxLinuxInstall =>
      'ארגז חול מקורי ב־Linux/WSL2 משתמש ב־bubblewrap. התקן באמצעות:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'ארגז חול מקורי מובנה ב־macOS — משתמש ב־Apple Seatbelt (`sandbox-exec`). לא נדרשת התקנה.';

  @override
  String get sandboxPermissions => 'הרשאות ארגז חול';

  @override
  String get sandboxUnsupported =>
      'ארגז חול מקורי עדיין אינו נתמך בפלטפורמה זו. המערכת חוזרת ל\"ללא בידוד\".';

  @override
  String get sandboxingDisabledDescription =>
      'סוכנים רצים ישירות על המארח עם סביבה מלאה — לא מומלץ.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'כל הפעלות הסוכנים עוברות דרך $backend.';
  }

  @override
  String get save => 'שמור';

  @override
  String get saveChanges => 'שמור שינויים';

  @override
  String get adapterArguments => 'ארגומנטים נוספים';

  @override
  String get adapterArgumentsHint => 'דגלי CLI נוספים (למשל --yolo)';

  @override
  String get addVariable => 'הוסף משתנה';

  @override
  String get environmentVariables => 'משתני סביבה';

  @override
  String get environmentVariablesDescription =>
      'משתני סביבה מותאמים אישית המועברים למתאם זה (למשל מפתחות API). נשמרים ב־keychain.';

  @override
  String get variableKey => 'מפתח';

  @override
  String get variableValue => 'ערך';

  @override
  String get savingEllipsis => 'שומר…';

  @override
  String get scopeDiffToCommits =>
      'הגבל את ה־diff לקומיטים — לחיצה עם Shift לבחירת טווח';

  @override
  String get noPrsMatchSearch => 'אין בקשות משיכה תואמות';

  @override
  String get searchFactsHint => 'חיפוש עובדות...';

  @override
  String get searchFonts => 'חיפוש גופנים…';

  @override
  String get searchGifs => 'חיפוש GIF';

  @override
  String get searchGifsHint => 'חיפוש GIF...';

  @override
  String get searchInDiffHint => 'חיפוש ב־diff…';

  @override
  String get searchOrTypeModel => 'חפש או הקלד שם מודל…';

  @override
  String get searchPlaceholder => 'חיפוש…';

  @override
  String get searchShortcuts => 'חיפוש קיצורים…';

  @override
  String get shortcutUnavailableInBrowser => 'לא זמין בדפדפן';

  @override
  String get searching => 'מחפש…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'לפני $count שניות',
      many: 'לפני $count שניות',
      two: 'לפני שתי שניות',
      one: 'לפני שנייה',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'בחר מתאם';

  @override
  String get selectAdapterFirst => 'בחר תחילה מתאם';

  @override
  String get selectAgentToReportTo => 'בחר סוכן לדווח אליו…';

  @override
  String get selectAnAgent => 'בחר סוכן';

  @override
  String get selectConversation => 'בחר שיחה';

  @override
  String get selectLabel => 'בחר';

  @override
  String get selectRunner => 'בחר מריץ';

  @override
  String get semanticSearch => 'חיפוש סמנטי';

  @override
  String get send => 'שלח';

  @override
  String get sendFirstMessage => 'שלח את ההודעה הראשונה';

  @override
  String get sendMessage => 'שלח הודעה';

  @override
  String sentFindingsToAgent(int count) {
    return 'נשלחו $count ממצאים לסוכן.';
  }

  @override
  String setGithubLinkDescription(String name) {
    return 'הגדר את הבעלים ואת שם המאגר ב־GitHub עבור ⁨$name⁩. משמש לפענוח הפניות ל־PR ול־issues כמו #123 בתוכן Markdown.';
  }

  @override
  String get setLabel => 'הגדר';

  @override
  String get setToken => 'הגדר אסימון גישה';

  @override
  String get settingsLabel => 'הגדרות';

  @override
  String get settingsLanguage => 'שפה';

  @override
  String get settingsLanguageDescription => 'בחר את שפת היישום.';

  @override
  String get shortTask => 'משימה קצרה';

  @override
  String get showNativeNotifications => 'הצג התראות מערכת על אירועים.';

  @override
  String get showSuperseded => 'הצג עובדות שהוחלפו';

  @override
  String get signedIn => 'מחובר.';

  @override
  String signedInAs(String username) {
    return 'מחובר בתור ⁨$username⁩.';
  }

  @override
  String get skillNameRequired => 'נדרש שם מיומנות.';

  @override
  String skillSaved(String name) {
    return 'המיומנות \"⁨$name⁩\" נשמרה.';
  }

  @override
  String get skillsSourcesTab => 'מקורות';

  @override
  String get skillSourcesDisclaimer =>
      'מיומנויות מותקנות ממאגרי GitHub שאתה מוסיף. המטא־נתונים של המאגר אינם מהימנים — סריקת האנטי־וירוס היא אות הבטיחות האמיתי.';

  @override
  String get skillSourcesEmpty => 'אין מאגרי מיומנויות';

  @override
  String get skillSourcesEmptyHint =>
      'הוסף מאגר GitHub כדי לעיין במיומנויות שבו.';

  @override
  String get skillSourceAdd => 'הוסף מאגר';

  @override
  String get skillSourceAddTitle => 'הוספת מאגר מיומנויות';

  @override
  String get skillSourceAddHint => 'https://github.com/owner/repo';

  @override
  String get skillSourceInvalidUrl =>
      'הזן URL של מאגר GitHub‏ (https://github.com/owner/repo).';

  @override
  String skillSourceAdded(String repo) {
    return 'המאגר ⁨$repo⁩ נוסף.';
  }

  @override
  String skillSourceAlreadyAdded(String repo) {
    return 'המאגר ⁨$repo⁩ כבר נוסף.';
  }

  @override
  String skillSourceRemoved(String repo) {
    return 'המאגר ⁨$repo⁩ הוסר.';
  }

  @override
  String get skillSourceRemove => 'הסר';

  @override
  String skillSourceRemoveConfirmTitle(String repo) {
    return 'להסיר את ⁨$repo⁩?';
  }

  @override
  String get skillSourceRemoveConfirmBody =>
      'מיומנויות מותקנות נשארות מותקנות. רק קטלוג המאגר מוסר.';

  @override
  String get skillSourceNoSkills =>
      'לא נמצאו מיומנויות במאגר זה (מיומנות היא ספרייה המכילה SKILL.md).';

  @override
  String get skillSourceRefresh => 'רענן';

  @override
  String get skillSourceInstalledBadge => 'מותקנת';

  @override
  String get skillSourceUpdateBadge => 'עדכון זמין';

  @override
  String get skillSourceSlugTaken => 'השם תפוס';

  @override
  String skillSourceFilesCount(num count) {
    return '$count קבצים';
  }

  @override
  String get skillSourceReadme => 'README';

  @override
  String get skillSourceNoReadme => 'למיומנות זו אין README.';

  @override
  String get skillSourceNoMatches => 'אין מיומנויות שתואמות לסינון.';

  @override
  String get skillUpdateAction => 'עדכן';

  @override
  String get skillUninstallAction => 'הסר התקנה';

  @override
  String skillUninstallConfirmTitle(String slug) {
    return 'להסיר את ההתקנה של \"⁨$slug⁩\"?';
  }

  @override
  String skillUninstalled(String slug) {
    return 'ההתקנה של המיומנות \"⁨$slug⁩\" הוסרה.';
  }

  @override
  String get skillFindingLine => 'שורה';

  @override
  String get skillInstallAnywayOverride => 'אני מבין את הסיכון — התקן בכל זאת';

  @override
  String skillInstalled(String slug) {
    return 'המיומנות \"⁨$slug⁩\" הותקנה.';
  }

  @override
  String get skillPreviewCapabilities => 'יכולות';

  @override
  String get skillPreviewFindings => 'ממצאים';

  @override
  String get skillPreviewGuardedActions => 'פעולות מוגנות';

  @override
  String get skillPreviewLlmReviewed => 'נסקר על ידי LLM';

  @override
  String get skillPreviewNoCapabilities => 'לא הוצהרו יכולות.';

  @override
  String get skillPreviewNoFindings => 'אין ממצאים.';

  @override
  String get skillPreviewScanning => 'סורק מיומנות…';

  @override
  String get skillPreviewVerdictLabel => 'תוצאת הסריקה';

  @override
  String get skillPreviewVerdictPass => 'עברה';

  @override
  String get skillPreviewVerdictQuarantine => 'בהסגר';

  @override
  String get skillPreviewVerdictWarn => 'אזהרה';

  @override
  String get skillQuarantineWarning =>
      'מיומנות זו הוכנסה להסגר על ידי הסורק. התקנתה מריצה קוד על המחשב שלך. המשך רק אם אתה סומך על המקור וסקרת את הממצאים.';

  @override
  String skillDetachedFromAgents(String agents) {
    return 'הוכנסה להסגר ונותקה מהסוכנים: $agents';
  }

  @override
  String get skillNotScanned => 'לא נסרקה';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => 'ידני';

  @override
  String get skillOriginRegistry => 'מרשם';

  @override
  String get skillOriginRuntimeLocal => 'מקומי (זמן ריצה)';

  @override
  String get skillRulesStale => 'הסריקה אינה עדכנית';

  @override
  String get skillSaveAnywayOverride => 'אני מבין את הסיכון — שמור בכל זאת';

  @override
  String get skillSaveBlockedBody => 'התוכן נחסם לפני שנכתב דבר.';

  @override
  String get skillSaveBlockedTitle => 'השמירה נחסמה על ידי שער הסריקה';

  @override
  String get skillScanAction => 'סרוק';

  @override
  String get skillScanAll => 'סרוק הכול';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass עברו · $warn אזהרות · $quarantine בהסגר';
  }

  @override
  String get skillStateDrifted => 'שונתה מאז ההתקנה';

  @override
  String get skillStateUnmanaged => 'לא מנוהלת';

  @override
  String get skillSeverityBlocked => 'חוסם';

  @override
  String get skillSeverityWarn => 'אזהרה';

  @override
  String get skillsInstalledTab => 'מותקנות';

  @override
  String get skills => 'מיומנויות';

  @override
  String get skipAcceptRisk => 'דלג — אני מקבל את הסיכון';

  @override
  String get skipForNow => 'דלג בינתיים';

  @override
  String get skipSandboxing => 'דלג על ארגז חול';

  @override
  String get skipSandboxingDialogContent =>
      'האם לדלג על ארגז החול? הדבר יאפשר לסוכנים להריץ קוד על המערכת שלך ללא בידוד.';

  @override
  String get somethingWentWrong => 'משהו השתבש';

  @override
  String sourceCount(int count) {
    return '$count מקור';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count מקורות';
  }

  @override
  String get sourceFacts => 'עובדות מקור:';

  @override
  String get splitDiff => 'diff מפוצל (זה לצד זה)';

  @override
  String get startLabel => 'התחל';

  @override
  String get startOnAppLaunch => 'הפעל בעת עליית היישום';

  @override
  String get statusLabel => 'סטטוס';

  @override
  String get onboardingStepConnect => 'חיבור';

  @override
  String get onboardingStepWorkspace => 'סביבת עבודה';

  @override
  String get onboardingStepSandbox => 'ארגז חול';

  @override
  String get onboardingStepAdapter => 'מתאם';

  @override
  String get onboardingStepVoice => 'קול';

  @override
  String get stop => 'עצור';

  @override
  String get stopped => 'נעצר';

  @override
  String get strictIdentityCheck => 'בדיקת זהות קפדנית';

  @override
  String get success => 'הצלחה';

  @override
  String get successLabel => 'הצלחה';

  @override
  String get suggestAChange => 'הצע שינוי';

  @override
  String get suggestLabel => 'הצעה';

  @override
  String get superseded => 'הוחלפה';

  @override
  String get synced => 'מסונכרן';

  @override
  String get systemDefault => 'ברירת המחדל של המערכת';

  @override
  String get systemFonts => 'גופני מערכת';

  @override
  String get systemPrompt => 'הנחיית מערכת';

  @override
  String get systemPromptLabel => 'הנחיית מערכת';

  @override
  String get talkToControlCenter => 'דבר עם Control Center.';

  @override
  String get taskMentionSection => 'משימה';

  @override
  String get testLabel => 'בדוק';

  @override
  String get theme => 'ערכת נושא';

  @override
  String get themeDark => 'כהה';

  @override
  String get themeLight => 'בהיר';

  @override
  String get themeSystem => 'מערכת';

  @override
  String get thisCannotBeUndone => 'פעולה זו אינה ניתנת לביטול.';

  @override
  String get ticketLabel => 'כרטיס';

  @override
  String get titleLabel => 'כותרת';

  @override
  String get todayLabel => 'היום';

  @override
  String get toggleTheme => 'החלף ערכת נושא';

  @override
  String get tokenConfigured => 'הוגדר — לקוחות חייבים להציג אסימון גישה זה.';

  @override
  String get topic => 'נושא';

  @override
  String get topicHint => 'למשל סטאק טכנולוגי, מערכת עיצוב';

  @override
  String get totalRuns => 'סך כל ההרצות';

  @override
  String trackingParamsCount(int count) {
    return '$count פרמטרי מעקב';
  }

  @override
  String get typeCommandOrSearch => 'הקלד פקודה או חפש…';

  @override
  String get typography => 'טיפוגרפיה';

  @override
  String get unavailable => 'לא זמין';

  @override
  String get unifiedDiff => 'diff מאוחד';

  @override
  String get unknownAuthor => 'לא ידוע';

  @override
  String get unnamedAgent => 'סוכן ללא שם';

  @override
  String get updateKey => 'עדכון מפתח';

  @override
  String get updateLabel => 'עדכון';

  @override
  String get updateToken => 'עדכון אסימון גישה';

  @override
  String updatedDaysAgo(int count) {
    return 'עודכן לפני $count ימים';
  }

  @override
  String updatedHoursAgo(int count) {
    return 'עודכן לפני $count שעות';
  }

  @override
  String get updatedJustNow => 'עודכן זה עתה';

  @override
  String updatedMinutesAgo(int count) {
    return 'עודכן לפני $count דק׳';
  }

  @override
  String get useSandbox => 'שימוש בארגז חול';

  @override
  String get useWorkspaceDefault => 'שימוש בברירת המחדל של סביבת העבודה';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      'אם משאירים ריק, ייעשה שימוש ב-User-Agent של האפליקציה כברירת מחדל. חלק מהאתרים חוסמים User-Agent שאינו של דפדפן.';

  @override
  String get usingSystemDefaultMicrophone =>
      'נעשה שימוש במיקרופון ברירת המחדל של המערכת.';

  @override
  String get viewLabel => 'הצגה';

  @override
  String get viewLogs => 'הצגת לוגים';

  @override
  String voiceInstallFailed(String error) {
    return 'ההתקנה נכשלה: ⁨$error⁩';
  }

  @override
  String get voiceModelNotInstalled =>
      'לא מותקן. הורדה חד-פעמית של כ-200 MB; פועל כולו על המכשיר.';

  @override
  String get voiceModelNotInstalledLabel => 'מודל הקול אינו מותקן.';

  @override
  String get voiceRedownloadBody =>
      'קובצי המודל הקיימים יימחקו והארכיון בנפח של כ-200 MB יורד מחדש. תמלול קולי לא יהיה זמין עד שההורדה תושלם.';

  @override
  String get voiceRemoveBody =>
      'תמלול קולי יושבת עד להתקנה מחדש. אפשר להתקין אותו שוב בכל עת.';

  @override
  String get voiceTranscription => 'תמלול קולי';

  @override
  String get weakIsolationDescription =>
      'בידוד חלש — גבול namespace בלבד, ללא גבול kernel.';

  @override
  String get whenOffNoDefaultRoute =>
      'כשהאפשרות כבויה, ארגז החול עולה ללא נתיב ברירת מחדל.';

  @override
  String get whenOffServerStaysStopped =>
      'כשהאפשרות כבויה, השרת נשאר כבוי עד שמפעילים אותו.';

  @override
  String get speechModel => 'מודל דיבור';

  @override
  String get speechModelHint => 'משמש לתמלול פגישות ולמיקרופון בתיבת הכתיבה.';

  @override
  String get voiceModelInstalled =>
      'מותקן. מפעיל את תמלול הפגישות ואת כפתור המיקרופון בתיבת הכתיבה.';

  @override
  String get meetingMicSilentWarning =>
      'ייתכן שהמיקרופון שלכם מושתק — האחרים מדברים אך שום דבר לא מגיע מהמיקרופון שלכם.';

  @override
  String get meetingSummaryPrivacyNotice =>
      'ההקלטה והתמלול נשארים במחשב הזה. הסיכום נכתב על ידי סוכן, כך שאם הוא משתמש במודל ענן, התמליל וההערות שלכם נשלחים לאותו ספק.';

  @override
  String get meetingTemplates => 'תבניות סיכום לפגישות';

  @override
  String get meetingTemplatesHint =>
      'מעצבות את סיכום ה-AI לפי סוג הפגישה. התבנית הפעילה חלה על סיכומים חדשים ועל סיכומים שמופקים מחדש.';

  @override
  String get meetingTemplateActive => 'תבנית פעילה';

  @override
  String get meetingTemplateAdd => 'הוספת תבנית';

  @override
  String get meetingTemplateNewTitle => 'תבנית חדשה';

  @override
  String get meetingTemplateEditTitle => 'עריכת תבנית';

  @override
  String get meetingTemplateNameLabel => 'שם';

  @override
  String get meetingTemplateNameHint => 'למשל: סקירת ספרינט';

  @override
  String get meetingTemplateInstructionsLabel => 'הוראות';

  @override
  String get meetingTemplateInstructionsHint =>
      'איך על ה-AI לבנות את הסיכום ומה להדגיש?';

  @override
  String get workingMemory => 'זיכרון עבודה';

  @override
  String get workspaceName => 'שם סביבת העבודה';

  @override
  String get workspaceScopedSkills =>
      'קובצי מיומנות ברמת סביבת העבודה המצורפים לסוכנים.';

  @override
  String get workspaces => 'סביבות עבודה';

  @override
  String get writePrivateNotes => 'כתבו הערות פרטיות, תצפיות, תוכניות...';

  @override
  String get writeSkillContent => 'כתבו כאן את תוכן המיומנות (Markdown)…';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'לפני $count שנים',
      many: 'לפני $count שנים',
      two: 'לפני שנתיים',
      one: 'לפני שנה',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'אתמול';

  @override
  String get focusModeStart => 'התחלת סשן ריכוז';

  @override
  String get focusModeConfigTitle => 'התחלת סשן ריכוז';

  @override
  String get focusModeGoalLabel => 'מטרה';

  @override
  String get focusModeGoalHint => 'על מה אתם עובדים?';

  @override
  String get focusModeDurationLabel => 'משך';

  @override
  String get focusModeBlockNotifications => 'חסימת התראות';

  @override
  String get focusModeStartButton => 'התחלה';

  @override
  String get focusModeFloat => 'מזעור לסרגל';

  @override
  String get focusModeActiveTooltip => 'מצב ריכוז פעיל — הקישו לסיום';

  @override
  String get dismiss => 'סגירה';

  @override
  String get acceptAndResolve => 'קבלה ופתרון';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'אתם בסקירה כבר $minutes דק׳ — מחקרים מצביעים על ירידה באיכות הסקירה אחרי 60 דק׳. שקלו הפסקה.';
  }

  @override
  String get notificationSound => 'צליל התראה';

  @override
  String get notificationSoundDescription => 'הצליל שמושמע כשמוצגת התראה.';

  @override
  String get notificationSoundNone => 'ללא';

  @override
  String get notificationSoundPing => 'פינג';

  @override
  String get notificationSoundChime => 'צ\'יים';

  @override
  String get notificationSoundPop => 'פופ';

  @override
  String get notificationSoundDing => 'דינג';

  @override
  String get notificationSoundWhoosh => 'ווש';

  @override
  String get notificationSoundMigrosSoft => 'מיגרוס (רך)';

  @override
  String get notificationSoundMigrosHard => 'מיגרוס (חזק)';

  @override
  String get notificationSoundSbb => 'SBB';

  @override
  String get notificationSoundCff => 'CFF';

  @override
  String get notificationSoundFfs => 'FFS';

  @override
  String get notificationSoundPost => 'פוסט';

  @override
  String get notificationSoundTest => 'בדיקה';

  @override
  String get notificationVolume => 'עוצמת קול';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'אין PR מאת ⁨@$login⁩ בסביבת העבודה הזו';
  }

  @override
  String get usersLabel => 'משתמשים';

  @override
  String get mergePullRequest => 'מיזוג בקשת המשיכה';

  @override
  String get forceMergePullRequest => 'מיזוג בכפייה של בקשת המשיכה';

  @override
  String get closePullRequest => 'סגירת בקשת המשיכה';

  @override
  String get closePullRequestConfirm => 'לסגור את בקשת המשיכה הזו?';

  @override
  String get stackedPullRequests => 'בקשות משיכה בערימה';

  @override
  String partOfStack(int position, int total) {
    return 'חלק מערימה ($position מתוך $total)';
  }

  @override
  String get createStack => 'יצירת ערימה';

  @override
  String get createStackDialogTitle => 'יצירת ערימת בקשות משיכה';

  @override
  String createStackDialogBody(int count) {
    return '$count בקשות המשיכה האלה ייערמו, מלמטה למעלה:';
  }

  @override
  String get createStackInvalidSelection =>
      'יש לבחור לפחות שתי בקשות משיכה מאותו מאגר כדי ליצור ערימה';

  @override
  String get createStackNotAChain =>
      'בקשות המשיכה שנבחרו אינן יוצרות שרשרת: ענף הבסיס של כל בקשת משיכה חייב להיות ענף ה-head של הבקשה הקודמת';

  @override
  String get createStackAlreadyStacked =>
      'אחת או יותר מבקשות המשיכה שנבחרו כבר נמצאת בערימה';

  @override
  String get stackCreated => 'הערימה נוצרה';

  @override
  String get stackCreationFailed => 'לא ניתן היה ליצור את הערימה';

  @override
  String get squashAndMerge => 'Squash ומיזוג';

  @override
  String get createMergeCommit => 'יצירת קומיט מיזוג';

  @override
  String get rebaseAndMerge => 'Rebase ומיזוג';

  @override
  String get commitTitle => 'כותרת הקומיט';

  @override
  String get commitDescription => 'תיאור הקומיט';

  @override
  String get pullRequestMerged => 'בקשת המשיכה מוזגה';

  @override
  String get pullRequestClosed => 'בקשת המשיכה נסגרה';

  @override
  String failedToMergePr(String error) {
    return 'המיזוג נכשל: ⁨$error⁩';
  }

  @override
  String failedToClosePr(String error) {
    return 'הסגירה נכשלה: ⁨$error⁩';
  }

  @override
  String get markReadyForReview => 'מוכנה לסקירה';

  @override
  String get markReadyForReviewConfirm =>
      'בקשת המשיכה הזו תצא ממצב טיוטה. סוקרים יקבלו התראה, בדיקות חובה יתחילו לחסום את המיזוג וכל אוטומציה שממתינה לבקשות משיכה מוכנות תופעל.';

  @override
  String get convertToDraft => 'המרה לטיוטה';

  @override
  String get convertToDraftConfirm =>
      'בקשת המשיכה הזו תחזור למצב טיוטה. בקשות הסקירה הממתינות שלה יבוטלו ולא ניתן יהיה למזג אותה עד שתסומן שוב כמוכנה.';

  @override
  String get pullRequestMarkedReady => 'בקשת המשיכה סומנה כמוכנה לסקירה';

  @override
  String get pullRequestConvertedToDraft => 'בקשת המשיכה הומרה לטיוטה';

  @override
  String failedToMarkPrReady(String error) {
    return 'הסימון כמוכנה לסקירה נכשל: ⁨$error⁩';
  }

  @override
  String failedToConvertPrToDraft(String error) {
    return 'ההמרה לטיוטה נכשלה: ⁨$error⁩';
  }

  @override
  String get checksFailing => 'בדיקות נכשלות';

  @override
  String get reviewsPending => 'חלק מהסקירות עדיין ממתינות';

  @override
  String get mergeConflictsWithBase => 'בענף הזה יש התנגשויות שיש לפתור';

  @override
  String get branchOutOfDateWithBase => 'הענף הזה אינו מעודכן ביחס לענף הבסיס';

  @override
  String get mergeBlockedByBranchProtection => 'הגנת ענף חוסמת את המיזוג הזה';

  @override
  String get confirm => 'אישור';

  @override
  String get trustedSitesSectionTitle => 'אתרים מהימנים';

  @override
  String get trustedSitesEmpty =>
      'אין אתרים מהימנים. הוסיפו דומיין כדי לבטל את החסימה עבורו.';

  @override
  String get addTrustedSite => 'הוספת אתר מהימן';

  @override
  String get removeTrustedSite => 'הסרה';

  @override
  String get disableBlockingForThisSite => 'ביטול חסימה באתר הזה';

  @override
  String get enableBlockingForThisSite => 'הפעלת חסימה באתר הזה';

  @override
  String get enterDomainHint => 'למשל: example.com';

  @override
  String get invalidDomain => 'יש להזין דומיין תקין (למשל: ⁨example.com⁩)';

  @override
  String get pageLoadTimedOut =>
      'טעינת הדף חרגה מזמן ההמתנה. טענו מחדש או פתחו בדפדפן.';

  @override
  String get pipelinesScreenTitle => 'פייפליינים';

  @override
  String get pipelinesScreenSubtitle =>
      'תהליכי עבודה דקלרטיביים רב-שלביים לסוכנים';

  @override
  String get pipelinesRunPipeline => 'הרצת פייפליין';

  @override
  String get pipelineRunLauncherTitle => 'הרצת פייפליין';

  @override
  String get pipelineRunSubtitle =>
      'בחרו פייפליין ומלאו את הקלטים שלו כדי להתחיל הרצה.';

  @override
  String get pipelineRunNoInputsBadge => 'ללא קלטים';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count קלטים',
      many: '$count קלטים',
      two: 'שני קלטים',
      one: 'קלט אחד',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'הפייפליין הזה אינו מקבל קלטים.';

  @override
  String get pipelineRunSubmit => 'הרצת פייפליין';

  @override
  String get pipelineRunCouldNotStart => 'לא ניתן היה להתחיל את ההרצה.';

  @override
  String pipelineRunStarted(String name) {
    return 'ההרצה של $name החלה';
  }

  @override
  String get pipelineRunEmptyTitle => 'אין פייפליינים מוכנים להרצה';

  @override
  String get pipelineRunEmptyHint =>
      'הפעילו פייפליין והדליקו הרצה ידנית בעורך שלו כדי להריץ אותו כאן.';

  @override
  String get pipelineRunManageTemplates => 'ניהול פייפליינים';

  @override
  String get pipelineRunSettingsTitle => 'הרצה ידנית';

  @override
  String get pipelineRunSettingsAllow => 'התרת הרצה ידנית';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'הצגת הפייפליין הזה בדף ההרצה כדי שאפשר יהיה להתחיל אותו ידנית.';

  @override
  String get pipelineRunSettingsConcurrencyTitle => 'מקביליות';

  @override
  String get pipelineRunSettingsMaxParallel => 'מקסימום הרצות במקביל';

  @override
  String get pipelineRunSettingsMaxParallelHelp =>
      'השאירו ריק כדי שלא תהיה הגבלה. הרצות נוספות ממתינות בתור ומתחילות כשמתפנים מקומות.';

  @override
  String get pipelineRunSettingsMaxParallelHint => 'ללא הגבלה';

  @override
  String get pipelineRunSettingsMaxParallelInvalid =>
      'יש להזין מספר שלם של 1 ומעלה, או להשאיר ריק כדי שלא תהיה הגבלה.';

  @override
  String get pipelineRunSettingsInputsTitle => 'קלטים';

  @override
  String get pipelineRunSettingsAddInput => 'הוספת קלט';

  @override
  String get pipelineRunSettingsNoInputs => 'אין קלטים עדיין.';

  @override
  String get pipelineInputEditTitle => 'שדה קלט';

  @override
  String get pipelineInputKeyLabel => 'מפתח';

  @override
  String get pipelineInputKeyHelp =>
      'מפתח המצב שתחתיו נשמר הערך (למשל: ⁨repo_full_name⁩).';

  @override
  String get pipelineInputLabelLabel => 'תווית';

  @override
  String get pipelineInputTypeLabel => 'סוג';

  @override
  String get pipelineInputOptionsLabel => 'אפשרויות (מופרדות בפסיקים)';

  @override
  String get pipelineInputDefaultLabel => 'ערך ברירת מחדל';

  @override
  String get pipelineInputPlaceholderLabel => 'מציין מקום';

  @override
  String get pipelineInputHelpLabel => 'טקסט עזרה';

  @override
  String get pipelineInputRequiredLabel => 'חובה';

  @override
  String get pipelineInputTypeText => 'טקסט';

  @override
  String get pipelineInputTypeMultiline => 'טקסט מרובה שורות';

  @override
  String get pipelineInputTypeNumber => 'מספר';

  @override
  String get pipelineInputTypeBoolean => 'מתג';

  @override
  String get pipelineInputTypeSelect => 'בחירה';

  @override
  String get pipelinesEmpty => 'אין עדיין הרצות פייפליין';

  @override
  String get pipelinesEmptyHint => 'לחצו על \'הרצת פייפליין\' כדי להתחיל.';

  @override
  String get pipelinesNoSteps => 'טרם נרשמו שלבים';

  @override
  String get pipelinesNoActiveWorkspace =>
      'בחרו סביבת עבודה כדי לצפות בפייפליינים שלה';

  @override
  String pipelinesLoadError(String error) {
    return 'טעינת הפייפליינים נכשלה: ⁨$error⁩';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'התחלת הפייפליין נכשלה: ⁨$error⁩';
  }

  @override
  String get pipelineStatusPending => 'ממתין';

  @override
  String get pipelineStatusQueued => 'בתור';

  @override
  String get pipelineStatusRunning => 'פועל';

  @override
  String get pipelineStatusSuspended => 'מושהה';

  @override
  String get pipelineStatusCompleted => 'הושלם';

  @override
  String get pipelineStatusFailed => 'נכשל';

  @override
  String get pipelineStatusCancelled => 'בוטל';

  @override
  String get pipelineStatusSkipped => 'דולג';

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed מתוך $total שלבים';
  }

  @override
  String get pipelineWaterfallTimeline => 'ציר זמן';

  @override
  String pipelineWaterfallActive(String duration) {
    return 'פעיל $duration';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return 'המתנה $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip =>
      'זמן שאינו נכלל בסך הפעיל: ההרצה הייתה עצורה או המתינה בין שלבים.';

  @override
  String get pipelineStepStarted => 'התחיל';

  @override
  String get pipelineStepFinished => 'הסתיים';

  @override
  String get pipelineStepDurationLabel => 'משך';

  @override
  String get pipelineStepBranch => 'ענף';

  @override
  String get pipelineStepViewConversation => 'הצגת השיחה';

  @override
  String get pipelineStepError => 'שגיאה';

  @override
  String get pipelineStepInput => 'קלט';

  @override
  String get pipelineStepOutput => 'פלט';

  @override
  String get pipelineStepNotExecuted => 'טרם בוצע';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'נכשל בשלב $step';
  }

  @override
  String get pipelineRunTriggerManual => 'ידני';

  @override
  String get pipelineStepSkippedReason => 'דולג';

  @override
  String get pipelineStepPriorAttempts => 'ניסיונות קודמים';

  @override
  String get pipelineStepAttemptLabel => 'ניסיון';

  @override
  String pipelineStepAttemptN(int number) {
    return 'ניסיון $number';
  }

  @override
  String get pipelineStepAttemptInterrupted => 'נקטע';

  @override
  String get pipelineRunColumnPipeline => 'פייפליין';

  @override
  String get pipelineRunColumnDuration => 'משך';

  @override
  String get pipelineRunQueueNext => 'הבא בתור';

  @override
  String pipelineRunQueuePosition(int position) {
    return '$position בתור';
  }

  @override
  String get pipelineRunColumnStarted => 'התחיל';

  @override
  String get pipelineRunHistory => 'היסטוריית הרצות';

  @override
  String get pipelineRunHistoryEmpty => 'אין עדיין הרצות נוספות';

  @override
  String pipelineRunRerunAgo(String time) {
    return 'הורץ מחדש $time';
  }

  @override
  String pipelineRunAttempt(int number) {
    return 'ניסיון $number';
  }

  @override
  String pipelineRunFirstStarted(String time) {
    return 'החל לראשונה $time';
  }

  @override
  String get pipelineRunFilterAll => 'הכול';

  @override
  String get pipelineRunFilterEmpty => 'אין הרצות שתואמות למסנן הזה';

  @override
  String get relativeJustNow => 'זה עתה';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'לפני $count דק׳',
      many: 'לפני $count דק׳',
      two: 'לפני שתי דקות',
      one: 'לפני דקה',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'לפני $count שעות',
      many: 'לפני $count שעות',
      two: 'לפני שעתיים',
      one: 'לפני שעה',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'לפני $count ימים',
      many: 'לפני $count ימים',
      two: 'לפני יומיים',
      one: 'לפני יום',
    );
    return '$_temp0';
  }

  @override
  String get teamsTitle => 'צוותים';

  @override
  String get teamsAddTeam => 'הוספת צוות';

  @override
  String get teamsLoadError => 'לא ניתן היה לטעון את הצוותים';

  @override
  String get teamsEmptyTitle => 'אין צוותים עדיין';

  @override
  String get teamsEmptyDescription =>
      'קבצו סוכנים לצוותים כך שעבודה שמוקצית לצוות תנותב דרך מוביל שמאציל אותה הלאה.';

  @override
  String get teamCreateTitle => 'צוות חדש';

  @override
  String get teamEditTitle => 'עריכת צוות';

  @override
  String get teamNameLabel => 'שם הצוות';

  @override
  String get teamNameHint => 'למשל: פרונטאנד';

  @override
  String get teamDescriptionLabel => 'תיאור';

  @override
  String get teamDescriptionHint => 'על מה הצוות הזה אחראי';

  @override
  String get teamLeaderLabel => 'מוביל';

  @override
  String get teamLeaderHelp =>
      'המתאם שמקבל עבודה שהוקצתה לצוות ומאציל אותה לחבר המתאים ביותר.';

  @override
  String get teamNoLeader => 'ללא מוביל';

  @override
  String get teamInstructionsLabel => 'הוראות הפעלה';

  @override
  String get teamInstructionsHelp =>
      'מצורפות לתדריך של המוביל — מוסכמות צוות, כללי הסלמה, טון.';

  @override
  String get teamInstructionsHint => 'אופציונלי';

  @override
  String get teamSaved => 'הצוות נשמר';

  @override
  String get teamMembersError => 'לא ניתן היה לטעון את החברים';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count חברים',
      many: '$count חברים',
      two: 'שני חברים',
      one: 'חבר אחד',
      zero: 'אין חברים',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => 'הוספת חבר';

  @override
  String get teamAddMemberTitle => 'הוספת חברים';

  @override
  String teamAddMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'הוספת $count',
      many: 'הוספת $count',
      two: 'הוספת 2',
      one: 'הוספת 1',
      zero: 'הוספה',
    );
    return '$_temp0';
  }

  @override
  String get teamNoAgentsToAdd => 'כל הסוכנים כבר בצוות הזה.';

  @override
  String get teamRemoveMember => 'הסרה מהצוות';

  @override
  String get teamLeaderBadge => 'מוביל';

  @override
  String get teamUnknownAgent => 'סוכן לא ידוע';

  @override
  String get teamMembersEmpty => 'אין חברים עדיין';

  @override
  String get teamMembersEmptyDescription =>
      'הוסיפו סוכנים כדי שלמוביל יהיה למי להאציל עבודה.';

  @override
  String get teamSelectPrompt => 'בחרו צוות';

  @override
  String get teamSelectPromptDescription =>
      'בחרו צוות מהרשימה, או צרו צוות חדש.';

  @override
  String get teamDeleteTitle => 'למחוק את הצוות?';

  @override
  String teamDeleteBody(String name) {
    return '$name יימחק. הסוכנים שבו לא יושפעו.';
  }

  @override
  String get teamHasLeaderTooltip => 'יש מוביל';

  @override
  String get pipelineTemplatesNav => 'תבניות פייפליין';

  @override
  String get pipelineTemplatesTitle => 'תבניות פייפליין';

  @override
  String get pipelineTemplatesSubtitle =>
      'עורך גרירה ושחרור לפייפליינים שמתזמרים את הסוכנים שלכם.';

  @override
  String get pipelineTemplatesNew => 'תבנית חדשה';

  @override
  String get pipelineTemplatesEmpty =>
      'אין עדיין תבניות פייפליין. צרו אחת כדי להתחיל.';

  @override
  String get pipelineTemplateBuiltInBadge => 'מובנה';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'למחוק את התבנית?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'למחוק את תבנית הפייפליין $name? לא ניתן לבטל פעולה זו.';
  }

  @override
  String get pipelineTemplateEditorSubtitle =>
      'גררו סוגי צמתים מסרגל הצד אל הקנבס, ואז חברו אותם זה לזה.';

  @override
  String get unsavedChanges => 'שינויים שלא נשמרו';

  @override
  String get nodeLibraryTitle => 'ספריית צמתים';

  @override
  String get nodeLibraryHint => 'גררו פריט אל הקנבס כדי להוסיף צומת.';

  @override
  String get editorEmptyCanvas => 'גררו צומת מהספרייה כדי להתחיל.';

  @override
  String get pipelineWhenThisHappens => 'כשזה קורה';

  @override
  String get pipelineDoThis => 'עשה זאת';

  @override
  String get pipelineAddStep => 'הוספת שלב';

  @override
  String get pipelineTidyUp => 'סידור הפריסה';

  @override
  String get pipelineEditorHint => 'גררו שלבים כדי לסדר · גררו ידית כדי לחבר';

  @override
  String get pipelineRemoveConnection => 'הסר חיבור';

  @override
  String get pipelineDragToConnect => 'גררו כדי לחבר';

  @override
  String get pipelineNewDefaultName => 'פייפליין חדש';

  @override
  String get nodeCategoryTriggers => 'טריגרים';

  @override
  String get triggerEventWebhook => 'Webhook';

  @override
  String get pipelineAddTrigger => 'הוספת טריגר';

  @override
  String get pipelineOnEvent => 'באירוע';

  @override
  String get nodeConfigTitle => 'הגדרות צומת';

  @override
  String get nodeConfigKind => 'סוג';

  @override
  String get nodeConfigLabel => 'תווית';

  @override
  String get nodeConfigAgent => 'סוכן';

  @override
  String get nodeConfigAgentHint => 'בחרו סוכן…';

  @override
  String get nodeConfigInputKeys => 'מפתחות קלט (מופרדים בפסיקים)';

  @override
  String get nodeConfigInputKeysHelp =>
      'מפתחות מצב שהצומת הזה צורך. משמשים להחלפת מצייני מקום בהנחיה.';

  @override
  String get nodeConfigRepos => 'מאגרים לשיבוט';

  @override
  String get nodeConfigReposHelp =>
      'מאגרים שמשובטים ומאונדקסים כשהצומת הזה מתחיל את השיחה שלו. בחירת כל המאגרים משבטת את כולם (ברירת המחדל).';

  @override
  String get nodeConfigRepoBranchHint => 'ענף (ברירת מחדל)';

  @override
  String get nodeConfigRepoBranchHelp =>
      'הענף שממנו נגזר כל checkout. השאירו ריק לענף ברירת המחדל של המאגר — עץ העבודה עדיין מקבל ענף משלו, כך ששום קומיט של סוכן לא נוחת על הענף הזה.';

  @override
  String nodeConfigReposDynamic(String entries) {
    return 'רשומות דינמיות שנשמרו: ⁨$entries⁩';
  }

  @override
  String get nodeConfigCreateConversation => 'פתיחת שיחה בתוכו';

  @override
  String get nodeConfigCreateConversationHelp =>
      'השאירו כבוי כשכמה צומתי סוכן באים אחריו — כל אחד פותח זרם משלו עם שם. הפעילו כשצומת סוכן יחיד בא אחריו, כדי שהחדר לא יציג שיחה ללא שם לצידו.';

  @override
  String get nodeConfigConversationTitle => 'שם השיחה';

  @override
  String get nodeConfigConversationTitleHelp =>
      'תנו לצומת הסוכן שבהמשך את אותו השם ושניהם יעבדו בזרם אחד. ברירת המחדל היא תווית הצומת.';

  @override
  String get nodeConfigSpaceName => 'שם המרחב';

  @override
  String get nodeConfigSpaceNameHelp =>
      'השם של החדר שהצומת הזה פותח. תומך באותם מצייני מקום של מצב כמו הנחיה. השאירו ריק כדי להשתמש בתווית הצומת.';

  @override
  String get nodeConfigSpaceNameHint => 'סקירה של ⁨pr_number⁩';

  @override
  String get nodeConfigStreamTitle => 'שם השיחה';

  @override
  String get nodeConfigStreamTitleHelp =>
      'הזרם בעל השם שסוכן הצומת הזה עובד בו בתוך החדר. תומך באותם מצייני מקום של מצב כמו הנחיה. אם משאירים ריק, התור נוחת בשיחה הקבועה של החדר, שבה פיצול מקבילי משלב את כל הסוכנים.';

  @override
  String get nodeConfigConversationTitleHint => 'ניתוח ארכיטקטורה';

  @override
  String get nodeConfigOutputKey => 'מפתח פלט';

  @override
  String get nodeConfigPrompt => 'תבנית הנחיה';

  @override
  String get nodeConfigPromptHelp =>
      'השתמשו במצייני מקום בסוגריים מסולסלים כפולים כדי למשוך ערכים מהמצב בזמן ריצה.';

  @override
  String get nodeConfigScript => 'סקריפט Bash';

  @override
  String get nodeConfigScriptHelp =>
      'רץ עם ⁨bash -c⁩. המשתנה ⁨GITHUB_TOKEN⁩ מוגדר. מצייני מקום מוחלפים לפני הביצוע.';

  @override
  String get nodeConfigRouteKeys => 'מפתחות ניתוב';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'מפתח ניתוב מ-$source';
  }

  @override
  String get conditionSectionTitle => 'תנאי';

  @override
  String get conditionMode => 'מצב';

  @override
  String get conditionModeFilesAny => 'קבצים קיימים — אחד לפחות';

  @override
  String get conditionModeFilesAll => 'קבצים קיימים — כולם';

  @override
  String get conditionModeComparison => 'השוואה';

  @override
  String get conditionModeSwitch => 'מיתוג';

  @override
  String get conditionFilePaths => 'נתיבי קבצים';

  @override
  String get conditionFilePathsAnyHelp =>
      'נתיב אחד בכל שורה, יחסית לתיקיית הבסיס. מנתב ל-true כשאחד מהם קיים.';

  @override
  String get conditionFilePathsAllHelp =>
      'נתיב אחד בכל שורה, יחסית לתיקיית הבסיס. מנתב ל-true רק כשכולם קיימים.';

  @override
  String get conditionBaseKey => 'מפתח תיקיית הבסיס';

  @override
  String get conditionBaseKeyHelp =>
      'מפתח מצב שמחזיק את התיקייה שנתיבים נפתרים ביחס אליה (ברירת מחדל: ⁨repo_local_path⁩).';

  @override
  String get conditionRecursive => 'חיפוש בתיקיות משנה';

  @override
  String get conditionNegate => 'היפוך: ניתוב ל-true כשחסר';

  @override
  String get conditionLeft => 'ערך שמאלי';

  @override
  String get conditionOperator => 'אופרטור';

  @override
  String get conditionRight => 'ערך ימני';

  @override
  String get conditionSwitchKey => 'מיתוג לפי מפתח מצב';

  @override
  String get conditionCases => 'מקרים (מופרדים בפסיקים)';

  @override
  String get conditionCasesHelp => 'מפתחות ניתוב להשוואה מול הערך, לפי הסדר.';

  @override
  String get conditionDefaultCase => 'מקרה ברירת מחדל';

  @override
  String get triggerManualHelp => 'הצגה בדף ההרצה והתחלה ידנית.';

  @override
  String get triggerKindSchedule => 'לפי לוח זמנים';

  @override
  String get triggerScheduleExprLabel => 'לוח זמנים (cron או ⁨every:seconds⁩)';

  @override
  String get triggerTimezoneLabel => 'אזור זמן (אופציונלי)';

  @override
  String get triggerCatchUpLabel => 'הרצות שהוחמצו';

  @override
  String get triggerCatchUpRunOnce => 'הרצה פעם אחת';

  @override
  String get triggerCatchUpSkip => 'דילוג';

  @override
  String get syncHealthTitle => 'תקינות הסנכרון';

  @override
  String get syncHealthNoConfigs => 'אין עדיין חיבורי סנכרון';

  @override
  String get syncHealthNeverSynced => 'לא סונכרן מעולם';

  @override
  String get syncOutcomeOk => 'סונכרן';

  @override
  String get syncOutcomeFailed => 'נכשל';

  @override
  String get syncOutcomeSkipped => 'דולג';

  @override
  String syncHealthFailedStreak(int count) {
    return '$count כישלונות רצופים';
  }

  @override
  String get triggerWebhookHelp =>
      'נוצר URL חתום של webhook. מערכות חיצוניות שולחות אליו POST כדי להתחיל את הפייפליין הזה.';

  @override
  String get triggerWebhookPathLabel => 'נתיב ה-webhook';

  @override
  String get triggerMatchStatusLabel => 'רק כשהסטטוס הוא';

  @override
  String get triggerSummaryNone => 'ללא טריגרים';

  @override
  String triggerEverySeconds(int seconds) {
    return 'כל $seconds שניות';
  }

  @override
  String get triggerEventManual => 'הרצה ידנית';

  @override
  String get triggerEventSchedule => 'לוח זמנים';

  @override
  String get triggerEventPrStatusChanged => 'סטטוס PR השתנה';

  @override
  String get triggerEventExternalPr => 'PR חיצוני נפתח';

  @override
  String get triggerEventPrPublished => 'PR פורסם';

  @override
  String get triggerEventPrMerged => 'PR מוזג';

  @override
  String get triggerEventRepoAdded => 'מאגר נוסף';

  @override
  String get triggerEventCodeGraphWatch => 'שינוי קובץ';

  @override
  String pipelineRunCauseChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count קבצים השתנו',
      many: '$count קבצים השתנו',
      two: 'שני קבצים השתנו',
      one: 'קובץ אחד השתנה',
    );
    return '$_temp0';
  }

  @override
  String pipelineRunCauseMorePaths(int count) {
    return 'ועוד $count';
  }

  @override
  String get pipelineRunCauseRescan => 'השתנה בדיסק';

  @override
  String get pipelineRunCauseInitial => 'אינדוקס ראשון של ה-checkout הזה';

  @override
  String get triggerEventMessageReceived => 'הודעה התקבלה';

  @override
  String get triggerEventTicketCompleted => 'כרטיס הושלם';

  @override
  String get triggerEventTicketFailed => 'כרטיס נכשל';

  @override
  String get triggerEventTicketCancelled => 'כרטיס בוטל';

  @override
  String get triggerEventBudgetCrossed => 'סף תקציב נחצה';

  @override
  String get nodeLibrarySearchHint => 'חיפוש צמתים';

  @override
  String get nodeLibraryNoMatches => 'אין צמתים תואמים';

  @override
  String get nodeCategoryFlow => 'זרימה ולוגיקה';

  @override
  String get nodeCategoryPr => 'סקירת PR';

  @override
  String get nodeCategoryAgents => 'סוכנים';

  @override
  String get nodeCategoryMessaging => 'הודעות';

  @override
  String get nodeCategoryCode => 'קוד';

  @override
  String get triggerDisabledTag => 'כבוי';

  @override
  String get pipelineInputTypeRepo => 'מאגר';

  @override
  String get pipelineRunNoRepos => 'אין עדיין מאגרים בסביבת העבודה הזו.';

  @override
  String get allowTicketingApi => 'התרת קריאות API של ניהול כרטיסים';

  @override
  String get ticketingApiKey => 'מפתח API לניהול כרטיסים';

  @override
  String get ticketingApiKeySubtitle =>
      'מזריק את מפתח ה-API של ספק ניהול הכרטיסים לתוך ארגז החול.';

  @override
  String get ticketingProvider => 'ספק ניהול כרטיסים';

  @override
  String get connectGitHubAndTicketing =>
      'חברו שירות אחסון קוד כדי ש-Control Center יוכל לקרוא את בקשות המשיכה, הסוגיות והסקירות שלכם. אפשר גם לחבר ספק ניהול כרטיסים. פרטי הגישה נשמרים בשרת שלכם, לעולם לא במחשב הזה.';

  @override
  String get triggerEventTicketAssigned => 'כרטיס הוקצה';

  @override
  String get triggerEventTicketCreated => 'כרטיס נוצר';

  @override
  String get triggerEventTicketStatusChanged => 'סטטוס הכרטיס השתנה';

  @override
  String get triggerEventMeetingRecordingStopped => 'הקלטת הפגישה הופסקה';

  @override
  String get triggerEventSkillUpdated => 'המיומנות עודכנה';

  @override
  String get triggerEventSpaceDeleted => 'המרחב נמחק';

  @override
  String get triggerExternalPrHelp =>
      'בקשת משיכה שנפתחה במארח הקוד, לא מ-Control Center.';

  @override
  String get triggerPrPublishedHelp =>
      'בקשת משיכה שנפתחה מ-Control Center או על ידי סוכן.';

  @override
  String get triggerPrStatusChangedHelp =>
      'מוזגה, נסגרה, נפתחה, נפתחה מחדש או אושרה. סננו לפי סטטוס בלוח.';

  @override
  String get triggerPrMergedHelp =>
      'רק כשבקשת המשיכה ממוזגת, לא כשהיא נסגרת או נפתחת מחדש.';

  @override
  String get triggerRepoAddedHelp => 'מאגר מקושר למרחב העבודה הזה.';

  @override
  String get triggerCodeGraphWatchHelp => 'קובץ במאגר מקושר משתנה בדיסק.';

  @override
  String get triggerMessageReceivedHelp => 'הודעה חדשה מגיעה למרחב.';

  @override
  String get triggerTicketCreatedHelp => 'כרטיס נוצר במרחב העבודה הזה.';

  @override
  String get triggerTicketStatusChangedHelp => 'כרטיס עובר בין סטטוסים.';

  @override
  String get triggerTicketCompletedHelp => 'כרטיס מסתיים בהצלחה.';

  @override
  String get triggerTicketFailedHelp => 'ריצת סוכן נכשלה והכרטיס מסומן כנכשל.';

  @override
  String get triggerTicketCancelledHelp => 'כרטיס מבוטל ולא ימשיך.';

  @override
  String get triggerBudgetCrossedHelp =>
      'חריגה ממגבלת הוצאה של מרחב עבודה או סוכן.';

  @override
  String get triggerTicketAssignedHelp => 'כרטיס מוקצה לאדם, לסוכן או לצוות.';

  @override
  String get triggerMeetingRecordingStoppedHelp => 'הקלטת פגישה מסתיימת.';

  @override
  String get triggerSkillUpdatedHelp => 'מיומנות מותקנת או מתעדכנת.';

  @override
  String get triggerSpaceDeletedHelp => 'מרחב שיחה נמחק.';

  @override
  String get navTickets => 'כרטיסים';

  @override
  String get ticketsTitle => 'כרטיסים';

  @override
  String get newTicket => 'כרטיס חדש';

  @override
  String get noTicketsYet => 'אין כרטיסים עדיין';

  @override
  String get addCollaborator => 'הוספת משתף פעולה';

  @override
  String get noCollaborators => 'אין עדיין משתפי פעולה';

  @override
  String get linkedPullRequests => 'בקשות משיכה מקושרות';

  @override
  String get noLinkedPullRequests => 'אין עדיין בקשות משיכה מקושרות';

  @override
  String get stopAgent => 'עצירת הסוכן';

  @override
  String get ticketProperties => 'מאפיינים';

  @override
  String get ticketTabIssue => 'סוגיה';

  @override
  String get ticketSelectPrompt => 'בחרו כרטיס כדי לצפות בפרטיו';

  @override
  String get unassigned => 'ללא אחראי';

  @override
  String get ticketStatusBacklog => 'בקלוג';

  @override
  String get ticketStatusOpen => 'לביצוע';

  @override
  String get ticketStatusInProgress => 'בתהליך';

  @override
  String get ticketStatusInReview => 'בסקירה';

  @override
  String get ticketStatusDone => 'הושלם';

  @override
  String get ticketStatusBlocked => 'חסום';

  @override
  String get ticketStatusFailed => 'נכשל';

  @override
  String get ticketStatusCancelled => 'בוטל';

  @override
  String get notificationTicketAssigned => 'כרטיס הוקצה';

  @override
  String get notificationTicketStatusChanged => 'סטטוס כרטיס השתנה';

  @override
  String get priority => 'עדיפות';

  @override
  String get status => 'סטטוס';

  @override
  String get assignee => 'אחראי';

  @override
  String get labels => 'תוויות';

  @override
  String get noLabelsYet => 'אין תוויות עדיין';

  @override
  String get clearLabels => 'ניקוי תוויות';

  @override
  String get pipelineStepAgentActivity => 'פעילות הסוכן';

  @override
  String get runStatusCompleted => 'הושלמה';

  @override
  String get runStatusQueued => 'בתור';

  @override
  String get ticketDescription => 'תיאור';

  @override
  String get ticketPriorityNone => 'ללא';

  @override
  String get ticketPriorityUrgent => 'דחופה';

  @override
  String get ticketPriorityHigh => 'גבוהה';

  @override
  String get ticketPriorityMedium => 'בינונית';

  @override
  String get ticketPriorityLow => 'נמוכה';

  @override
  String get ticketViewList => 'רשימה';

  @override
  String get ticketViewBoard => 'לוח';

  @override
  String get ticketTitlePlaceholder => 'כותרת הסוגיה';

  @override
  String get ticketDescriptionPlaceholder => 'הוספת תיאור…';

  @override
  String get createMore => 'יצירת עוד';

  @override
  String selectedCount(int count) {
    return '$count נבחרו';
  }

  @override
  String get clearSelection => 'ניקוי בחירה';

  @override
  String get bulkDeleteTitle => 'מחיקת כרטיסים';

  @override
  String bulkDeleteMessage(int count) {
    return 'למחוק $count כרטיסים שנבחרו? לא ניתן לבטל פעולה זו.';
  }

  @override
  String get assignTo => 'הקצאה ל…';

  @override
  String get sectionMembers => 'חברים';

  @override
  String get sectionAgents => 'סוכנים';

  @override
  String get sidebarGroupWorkspace => 'סביבת עבודה';

  @override
  String get notificationsTitle => 'התראות';

  @override
  String get notificationsTooltip => 'התראות';

  @override
  String get notificationsEmpty => 'אתם מעודכנים בהכול';

  @override
  String notificationsUnreadCount(int count) {
    return '$count שלא נקראו';
  }

  @override
  String get notificationsMarkRead => 'סימון כנקרא';

  @override
  String get notificationsMarkUnread => 'סימון כלא נקרא';

  @override
  String get notificationsEntryActions => 'פעולות התראה';

  @override
  String get markAllRead => 'סימון הכול כנקרא';

  @override
  String get teamsNav => 'צוותים';

  @override
  String get noWorkspace => 'אין סביבת עבודה';

  @override
  String get selectWorkspace => 'בחרו סביבת עבודה';

  @override
  String get navMemory => 'זיכרון';

  @override
  String get memoryTabFacts => 'עובדות';

  @override
  String get memoryTabPolicies => 'כללי מדיניות';

  @override
  String get memoryGraphShowFacts => 'הצגת עובדות';

  @override
  String get memoryGraphHideFacts => 'הסתרת עובדות';

  @override
  String get memoryGraphExpandAll => 'הרחבת כל העובדות';

  @override
  String get memoryGraphCollapseAll => 'כיווץ כל העובדות';

  @override
  String get memoryTabGraph => 'גרף ידע';

  @override
  String get memoryNoWorkspace => 'בחרו סביבת עבודה כדי לצפות בזיכרון שלה.';

  @override
  String get searchArticles => 'חיפוש כתבות';

  @override
  String get filterAll => 'הכול';

  @override
  String get filterUnread => 'שלא נקראו';

  @override
  String get filterSaved => 'שמורות';

  @override
  String get saveArticle => 'שמירת כתבה';

  @override
  String get removeFromSaved => 'הסרה מהשמורות';

  @override
  String get filterBySource => 'סינון לפי מקור';

  @override
  String get viewAsList => 'תצוגת רשימה';

  @override
  String get viewAsGrid => 'תצוגת רשת';

  @override
  String get noMatchingArticles => 'אין כתבות תואמות';

  @override
  String get noMatchingArticlesBody => 'נסו חיפוש אחר או מסנן מקור אחר.';

  @override
  String get allCaughtUp => 'הכול מעודכן';

  @override
  String get allCaughtUpBody => 'אין כתבות שלא נקראו — חזרו מאוחר יותר.';

  @override
  String get openArticlesInAppDescription =>
      'פתיחת קישורים בקורא המובנה במקום בדפדפן ברירת המחדל.';

  @override
  String get blockAdsTrackersDescription =>
      'הסרת פרסומות, רכיבי מעקב ובאנרים של עוגיות מכתבות שנפתחות בקורא.';

  @override
  String get agentQuestionHeader => 'שאלה אליכם';

  @override
  String get agentQuestionAnsweredLabel => 'נענתה';

  @override
  String get agentQuestionFreeformHint => 'הקלידו את תשובתכם…';

  @override
  String agentQuestionProgress(int index, int count) {
    return 'שאלה $index מתוך $count';
  }

  @override
  String get agentQuestionSkip => 'דילוג';

  @override
  String get agentQuestionSkippedLabel => 'דולגה';

  @override
  String get agentQuestionFreeformOptionHint => 'תארו במילים שלכם…';

  @override
  String get reviewRequested => 'התבקשה סקירה';

  @override
  String get connectGitHubHint =>
      'היכנסו ל-GitHub או הוסיפו אסימון גישה תחת הגדרות ← סביבת עבודה ← פרופיל וזהות ← אחסון קוד';

  @override
  String get connectGitHubToLoadPrs => 'חברו את GitHub כדי לטעון בקשות משיכה';

  @override
  String get noRepositoriesConfigured => 'לא הוגדרו מאגרים';

  @override
  String openedAgo(String age) {
    return 'נפתחה $age';
  }

  @override
  String prTimelineOpened(String author) {
    return '⁨$author⁩ פתח את בקשת המשיכה הזו';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count קומיטים',
      many: '$count קומיטים',
      two: 'שני קומיטים',
      one: 'קומיט אחד',
    );
    return '⁨$author⁩ פתח את בקשת המשיכה הזו עם $_temp0';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return '⁨$actor⁩ ביקש סקירה מאת ⁨$reviewers⁩';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '⁨$actor⁩ הסיר את בקשת הסקירה עבור ⁨$reviewers⁩';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '⁨$actor⁩ ביקש סקירה מאת ⁨$requested⁩ והסיר את בקשת הסקירה עבור ⁨$removed⁩';
  }

  @override
  String prTimelineAddedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'התוויות',
      one: 'התווית',
    );
    return '⁨$actor⁩ הוסיף את ⁨$labels⁩ $_temp0';
  }

  @override
  String prTimelineRemovedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'התוויות',
      one: 'התווית',
    );
    return '⁨$actor⁩ הסיר את ⁨$labels⁩ $_temp0';
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
      other: 'התוויות',
      one: 'התווית',
    );
    String _temp1 = intl.Intl.pluralLogic(
      removedCount,
      locale: localeName,
      other: 'התוויות',
      one: 'התווית',
    );
    return '⁨$actor⁩ הוסיף את ⁨$added⁩ $_temp0 והסיר את ⁨$removed⁩ $_temp1';
  }

  @override
  String prTimelineCommitted(String author) {
    return '⁨$author⁩ ביצע קומיט';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count קומיטים',
      many: '$count קומיטים',
      two: 'שני קומיטים',
      one: 'קומיט אחד',
    );
    return '⁨$author⁩ דחף $_temp0';
  }

  @override
  String prTimelineApproved(String author) {
    return '⁨$author⁩ אישר את השינויים האלה';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return '⁨$author⁩ ביקש שינויים';
  }

  @override
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count הערות קוד',
      many: '$count הערות קוד',
      two: 'שתי הערות קוד',
      one: 'הערת קוד אחת',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '⁨$author⁩ סקר';
  }

  @override
  String get prTimelineSomeone => 'מישהו';

  @override
  String get prTimelineBotBadge => 'בוט';

  @override
  String updatedAgo(String age) {
    return 'עודכנה $age';
  }

  @override
  String get checksPassing => 'הבדיקות עוברות';

  @override
  String get checksRunning => 'בדיקות פועלות';

  @override
  String get needsYourReview => 'נדרשת הסקירה שלכם';

  @override
  String get checks => 'בדיקות';

  @override
  String get noReviewersAssigned => 'לא הוקצו סוקרים';

  @override
  String get noAssignees => 'אין אחראים';

  @override
  String get loadingEllipsis => 'טוען…';

  @override
  String get loadingChecks => 'טוען בדיקות…';

  @override
  String get noChecksYet => 'עדיין לא רצו בדיקות';

  @override
  String get noChangesToReview => 'אין שינויים לבדיקה';

  @override
  String checksFailingCount(int count) {
    return '$count נכשלות';
  }

  @override
  String get showMore => 'הצגת עוד';

  @override
  String get showLess => 'הצגת פחות';

  @override
  String get backToPullRequests => 'חזרה לבקשות המשיכה';

  @override
  String get pullRequestNotFound => 'בקשת המשיכה לא נמצאה';

  @override
  String get pullRequestNotFoundBody => 'ייתכן שהיא מוזגה, נסגרה או הועברה.';

  @override
  String get couldntLoadPullRequest => 'לא ניתן לטעון את בקשת המשיכה הזו';

  @override
  String get showDetails => 'הצגת פרטים';

  @override
  String get noDescriptionProvided => 'לא סופק תיאור.';

  @override
  String get factsHint => 'עובדות יופיעו כאן ככל שהסוכנים שלכם לומדים.';

  @override
  String get noFactsMatch => 'אין עובדות התואמות את החיפוש';

  @override
  String get memoryLoadError => 'לא ניתן לטעון את הזיכרון';

  @override
  String get sortRecent => 'אחרונות';

  @override
  String get sortConfidence => 'רמת ביטחון';

  @override
  String get confidenceTooltip =>
      'עד כמה הסוכנים בטוחים שהעובדה נכונה, בין 0 ל-100%.';

  @override
  String get supersededTooltip => 'עובדה חדשה יותר החליפה את זו.';

  @override
  String get domain => 'תחום';

  @override
  String get fitToView => 'התאמה לתצוגה';

  @override
  String get project => 'פרויקט';

  @override
  String get newProject => 'פרויקט חדש';

  @override
  String get editProject => 'עריכת פרויקט';

  @override
  String get deleteProject => 'מחיקת פרויקט';

  @override
  String get noProject => 'ללא פרויקט';

  @override
  String get allTickets => 'כל הכרטיסים';

  @override
  String get projectNamePlaceholder => 'שם הפרויקט';

  @override
  String get projectDescriptionPlaceholder => 'תיאור (אופציונלי)';

  @override
  String get projectColorLabel => 'צבע';

  @override
  String get noProjectsYet => 'אין פרויקטים עדיין';

  @override
  String get projectTicketsEmpty => 'אין עדיין כרטיסים בפרויקט הזה';

  @override
  String get createProject => 'יצירת פרויקט';

  @override
  String projectProgress(int done, int total) {
    return '$done מתוך $total הושלמו';
  }

  @override
  String deleteProjectConfirm(String name) {
    return 'למחוק את \"$name\"? הכרטיסים שלו יישמרו ויוסרו מהפרויקט.';
  }

  @override
  String get projectStatusActive => 'פעיל';

  @override
  String get projectStatusCompleted => 'הושלם';

  @override
  String get projectStatusArchived => 'בארכיון';

  @override
  String get markProjectCompleted => 'סימון כהושלם';

  @override
  String get markProjectActive => 'סימון כפעיל';

  @override
  String get archiveProject => 'העברה לארכיון';

  @override
  String get restoreProject => 'שחזור';

  @override
  String get relations => 'קשרים';

  @override
  String get relateTo => 'קישור אל';

  @override
  String get relationSubIssueOf => 'תת-כרטיס של…';

  @override
  String get relationParentOf => 'הורה של…';

  @override
  String get relationBlockedBy => 'חסום על ידי…';

  @override
  String get relationBlocking => 'חוסם את…';

  @override
  String get relationRelatedTo => 'קשור אל…';

  @override
  String get relationDuplicateOf => 'כפילות של…';

  @override
  String get relationGroupParent => 'הורה';

  @override
  String get relationGroupSubIssues => 'תת-כרטיסים';

  @override
  String get relationGroupBlockedBy => 'חסום על ידי';

  @override
  String get relationGroupBlocking => 'חוסם';

  @override
  String get relationGroupRelated => 'קשורים';

  @override
  String get relationGroupDuplicateOf => 'כפילות של';

  @override
  String get relationGroupDuplicatedBy => 'משוכפל על ידי';

  @override
  String get copyId => 'העתקת ID';

  @override
  String get ticketIdCopied => 'ה-ID של הכרטיס הועתק';

  @override
  String get searchTicketsHint => 'חיפוש כרטיסים…';

  @override
  String get noMatchingTickets => 'אין כרטיסים תואמים';

  @override
  String get clearAll => 'ניקוי הכול';

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs PR ממתינים',
      many: '$prs PR ממתינים',
      two: 'שני PR ממתינים',
      one: 'PR אחד ממתין',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: 'ב-$repos מאגרים',
      many: 'ב-$repos מאגרים',
      two: 'בשני מאגרים',
      one: 'במאגר אחד',
    );
    return '$_temp0 לסקירה שלכם $_temp1';
  }

  @override
  String get manageWorkspacesSubtitle =>
      'שינוי שם של סביבת עבודה ועדכון הסמל שלה — בחרו אחת מהרשימה כדי לערוך.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count סביבות עבודה',
      many: '$count סביבות עבודה',
      two: 'שתי סביבות עבודה',
      one: 'סביבת עבודה אחת',
      zero: 'אין סביבות עבודה',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos מאגרים',
      many: '$repos מאגרים',
      two: 'שני מאגרים',
      one: 'מאגר אחד',
      zero: 'אין מאגרים',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents סוכנים',
      many: '$agents סוכנים',
      two: 'שני סוכנים',
      one: 'סוכן אחד',
      zero: '0 סוכנים',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'זהות';

  @override
  String get uploadImage => 'העלאת תמונה';

  @override
  String get failedToSaveLogo =>
      'שמירת תמונת הלוגו נכשלה. ודאו שהאפליקציה יכולה לקרוא את הקובץ שנבחר.';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG או GIF בגודל עד 2 MB. אחרת נשתמש באות הראשונה של סביבת העבודה.';

  @override
  String get workspaceNameFieldHelp =>
      'מוצג בבורר סביבות העבודה, בנתיב הניווט ובכל מסך.';

  @override
  String get dangerZone => 'אזור מסוכן';

  @override
  String get deleteThisWorkspace => 'מחיקת סביבת העבודה הזו';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return 'מוחק לצמיתות את $name, את חיבורי המאגרים שלה, את הסוכנים ואת הזיכרון. לא ניתן לבטל פעולה זו.';
  }

  @override
  String get discard => 'ביטול שינויים';

  @override
  String discardChangesQuestion(String name) {
    return 'לבטל שינויים שלא נשמרו ב-$name?';
  }

  @override
  String get workspaceUpdated => 'סביבת העבודה עודכנה';

  @override
  String get editTitle => 'עריכת כותרת';

  @override
  String get editDescription => 'עריכת תיאור';

  @override
  String get addDescription => 'הוספת תיאור';

  @override
  String get prTitlePlaceholder => 'כותרת';

  @override
  String get prBodyPlaceholder => 'כתבו תיאור';

  @override
  String get write => 'כתיבה';

  @override
  String get overview => 'סקירה כללית';

  @override
  String get noFilesChanged => 'לא שונו קבצים';

  @override
  String get diff => 'הבדלים';

  @override
  String get preview => 'תצוגה מקדימה';

  @override
  String get imageDiffBefore => 'לפני';

  @override
  String get imageDiffAfter => 'אחרי';

  @override
  String get imageDiffModeTwoUp => 'זה לצד זה';

  @override
  String get imageDiffModeSwipe => 'החלקה';

  @override
  String get imageDiffModeDifference => 'הפרש';

  @override
  String imageDiffChangedPercent(String percent) {
    return '$percent% השתנה';
  }

  @override
  String get imageDiffPictures => 'תמונות';

  @override
  String get imageDiffSource => 'מקור';

  @override
  String get imageDiffDeleted => 'נמחק';

  @override
  String get imageDiffAdded => 'נוסף';

  @override
  String imageDiffDimensions(int width, int height) {
    return 'ר: ${width}px | ג: ${height}px';
  }

  @override
  String get outdated => 'לא עדכנית';

  @override
  String get outdatedComments => 'תגובות לא עדכניות';

  @override
  String outdatedCountLabel(int count) {
    return '$count לא עדכניות';
  }

  @override
  String get prTemplateLabel => 'תבנית';

  @override
  String get prTemplateDefault => 'ברירת מחדל';

  @override
  String get addReviewers => 'הוספת סוקרים';

  @override
  String get addAssignees => 'הוספת אחראים';

  @override
  String get searchUsers => 'חיפוש אנשים…';

  @override
  String get searchReviewers => 'חיפוש אנשים וצוותים…';

  @override
  String get usersSectionLabel => 'אנשים';

  @override
  String get userStatusBusy => 'עסוק';

  @override
  String get teamsSectionLabel => 'צוותים';

  @override
  String get suggestedReviewers => 'סוקרים מוצעים';

  @override
  String get noMatchingUsers => 'אין אנשים תואמים';

  @override
  String get noMatchingReviewers => 'אין התאמות';

  @override
  String get requiredByCodeOwners => 'נדרש על ידי בעלי הקוד';

  @override
  String reviewedOnBehalfOf(String login) {
    return 'באמצעות ⁨$login⁩';
  }

  @override
  String get team => 'צוות';

  @override
  String get markdownBold => 'מודגש';

  @override
  String get markdownItalic => 'נטוי';

  @override
  String get markdownHeading => 'כותרת';

  @override
  String get markdownBulletList => 'רשימת תבליטים';

  @override
  String get markdownChecklist => 'רשימת משימות';

  @override
  String get markdownCode => 'קוד';

  @override
  String get markdownLink => 'קישור';

  @override
  String get markdownQuote => 'ציטוט';

  @override
  String get markdownSupported => 'יש תמיכה ב-Markdown';

  @override
  String get markdownAttachImages => 'לחצו להוספת תמונות';

  @override
  String failedToUpdateTitle(String error) {
    return 'לא ניתן לעדכן את הכותרת: ⁨$error⁩';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'לא ניתן לעדכן את התיאור: ⁨$error⁩';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'לא ניתן לעדכן את הסוקרים: ⁨$error⁩';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'לא ניתן לעדכן את האחראים: ⁨$error⁩';
  }

  @override
  String get discardChangesConfirm => 'לבטל את השינויים שלכם?';

  @override
  String get newPr => 'PR חדש';

  @override
  String get openPullRequest => 'פתיחת בקשת משיכה';

  @override
  String get composePrSubtitle => 'מענף שדחפתם — בלי סוכנים או כרטיסים';

  @override
  String get createAsDraft => 'יצירה כטיוטה';

  @override
  String get composePrNoRepo => 'לא נבחר מאגר GitHub';

  @override
  String get composePrNoRepoHint =>
      'בחרו סביבת עבודה עם מאגר המקושר ל-GitHub כדי לפתוח בקשת משיכה.';

  @override
  String get composePrPickBranches =>
      'בחרו ענף בסיס וענף השוואה כדי להציג את השינויים.';

  @override
  String get composePrNothingToCompare => 'אין שינויים בין הענפים האלה.';

  @override
  String get repository => 'מאגר';

  @override
  String get baseBranchLabel => 'בסיס';

  @override
  String get compareBranchLabel => 'השוואה';

  @override
  String get selectBranch => 'בחרו ענף';

  @override
  String get navMeetings => 'פגישות';

  @override
  String get meetingsNoWorkspace => 'בחרו סביבת עבודה כדי לראות פגישות.';

  @override
  String get meetingsEmpty => 'אין פגישות עדיין';

  @override
  String get meetingsEmptyHint =>
      'הקליטו את הפגישה הראשונה שלכם — השמע נשאר במכשיר הזה והסוכן הופך אותו להערות, החלטות ומשימות לביצוע.';

  @override
  String get meetingNotesHint =>
      'רשמו הערות מהירות — הסוכן ירחיב אותן אחרי הפגישה.';

  @override
  String get meetingSpeakerMe => 'אתם';

  @override
  String get meetingStatusRecording => 'מקליט';

  @override
  String get meetingStatusProcessing => 'בעיבוד';

  @override
  String get meetingStatusDone => 'הושלם';

  @override
  String get meetingStatusFailed => 'נכשל';

  @override
  String get meetingsSubtitle =>
      'מוקלט ומתומלל במכשיר הזה, ואז מסוכם על ידי סוכן.';

  @override
  String get meetingsRecordMeeting => 'הקלטת פגישה';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count בעיבוד כעת',
      many: '$count בעיבוד כעת',
      two: 'שתיים בעיבוד כעת',
      one: 'אחת בעיבוד כעת',
    );
    return '$_temp0';
  }

  @override
  String meetingsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count פגישות',
      many: '$count פגישות',
      two: 'שתי פגישות',
      one: 'פגישה אחת',
      zero: 'אין פגישות',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLedgerOpenActions => 'משימות פתוחות';

  @override
  String get meetingsLedgerDecisions => 'החלטות';

  @override
  String get meetingsLiveOpen => 'פתיחת ההקלטה';

  @override
  String get meetingTemplateShort => 'תבנית';

  @override
  String get meetingsStatThisWeek => 'השבוע';

  @override
  String get meetingsStatRecorded => 'הוקלטו';

  @override
  String get meetingsFilterAll => 'הכול';

  @override
  String get meetingsFilterDone => 'הושלמו';

  @override
  String get meetingsFilterProcessing => 'בעיבוד';

  @override
  String get meetingsSearchHint => 'סינון לפי כותרת, אדם, אפליקציה…';

  @override
  String get meetingsBucketToday => 'היום';

  @override
  String get meetingsBucketYesterday => 'אתמול';

  @override
  String get meetingsBucketEarlierThisWeek => 'מוקדם יותר השבוע';

  @override
  String get meetingsBucketLastWeek => 'שבוע שעבר';

  @override
  String get meetingsBucketOlder => 'ישן יותר';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count החלטות',
      many: '$count החלטות',
      two: 'שתי החלטות',
      one: 'החלטה אחת',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total משימות לביצוע';
  }

  @override
  String get meetingsEnhancedPill => 'משופר';

  @override
  String get meetingsTranscribing => 'מתמלל ומסכם…';

  @override
  String get meetingsOpenAction => 'פתיחה';

  @override
  String get meetingsStopProcessing => 'עצירה';

  @override
  String get meetingsStillTranscribing =>
      'התמלול עדיין מתבצע — הסיכום יופיע בסיומו.';

  @override
  String get meetingsNoMatch => 'אין פגישות תואמות';

  @override
  String get meetingsNoMatchHint => 'נסו מסנן או מונח חיפוש אחר.';

  @override
  String get meetingBackAllMeetings => 'כל הפגישות';

  @override
  String get meetingReRunSummary => 'הרצת הסיכום מחדש';

  @override
  String get meetingExport => 'ייצוא';

  @override
  String get meetingAugmentingBanner =>
      'מעשיר את ההערות שלכם מתוך התמלול — מחלץ החלטות ומשימות לביצוע…';

  @override
  String get meetingTabNotes => 'הערות';

  @override
  String get meetingTabTranscript => 'תמלול';

  @override
  String get meetingTabActionItems => 'משימות לביצוע';

  @override
  String get meetingTabDecisions => 'החלטות';

  @override
  String get meetingNotesEnhancedToggle => 'משופר';

  @override
  String get meetingNotesYoursToggle => 'ההערות שלכם';

  @override
  String get meetingEnhancedByAgent => 'שופר על ידי סוכן · מתוך התמלול';

  @override
  String get meetingEnhancedPending => 'הסוכן עדיין עובד על הסיכום הזה.';

  @override
  String get meetingNotesEmpty => 'אין עדיין הערות משופרות.';

  @override
  String get meetingNotesSavedLocally => 'נשמר מקומית';

  @override
  String get meetingNotesSaving => 'שומר…';

  @override
  String get meetingViewFullTranscript => 'הצגת התמלול המלא';

  @override
  String get meetingTranscriptSearchHint => 'חיפוש בתמלול…';

  @override
  String get meetingSpeakerEveryone => 'כולם';

  @override
  String get meetingSpeakerOthers => 'אחרים';

  @override
  String get meetingTranscriptEmpty => 'אין תמלול עדיין.';

  @override
  String get meetingActionItemsEmpty => 'לא חולצו משימות לביצוע.';

  @override
  String get meetingActionItemFrom => 'מהפגישה הזו';

  @override
  String get meetingCreateTicket => 'יצירת כרטיס';

  @override
  String meetingTicketCreated(String key) {
    return 'כרטיס ⁨$key⁩ נוצר ונשלח.';
  }

  @override
  String get meetingTicketFailed => 'לא ניתן ליצור את הכרטיס.';

  @override
  String get meetingDecisionsEmpty => 'לא נרשמו החלטות.';

  @override
  String get meetingEditTitle => 'עריכת כותרת';

  @override
  String get meetingTitleLabel => 'כותרת';

  @override
  String get meetingAddActionItem => 'הוספת משימה לביצוע';

  @override
  String get meetingEditActionItem => 'עריכת משימה לביצוע';

  @override
  String get meetingDeleteActionItem => 'מחיקת משימה לביצוע';

  @override
  String get meetingActionItemContentLabel => 'משימה לביצוע';

  @override
  String get meetingActionItemContentHint => 'מה צריך לקרות?';

  @override
  String get meetingActionItemOwnerLabel => 'בעלים';

  @override
  String get meetingActionItemOwnerHint => 'מי אחראי? (אופציונלי)';

  @override
  String get meetingAddDecision => 'הוספת החלטה';

  @override
  String get meetingEditDecision => 'עריכת החלטה';

  @override
  String get meetingDeleteDecision => 'מחיקת החלטה';

  @override
  String get meetingDecisionContentLabel => 'החלטה';

  @override
  String get meetingDecisionContentHint => 'מה הוחלט?';

  @override
  String get meetingReRunStarted => 'מריץ מחדש את המסכם על התמלול…';

  @override
  String get meetingReRunNoTranscript => 'אין עדיין תמלול לסיכום.';

  @override
  String get meetingExportCopied => 'ההערות הועתקו ללוח כ-Markdown.';

  @override
  String get meetingExportSaved => 'ייצוא הפגישה הושלם.';

  @override
  String meetingExportFailed(String error) {
    return 'הייצוא נכשל: ⁨$error⁩';
  }

  @override
  String get meetingExportNothing => 'אין עדיין מה לייצא.';

  @override
  String get meetingPlaybackPlay => 'ניגון';

  @override
  String get meetingPlaybackPause => 'השהיה';

  @override
  String get meetingPlaybackUnavailable => 'ניגון שמע אינו זמין במכשיר הזה.';

  @override
  String get meetingDetectedTitle => 'זוהתה פגישה';

  @override
  String meetingDetectedSubtitle(String label) {
    return 'נראה ש\"$label\" מתקיימת כעת. להקליט?';
  }

  @override
  String get meetingDetectedSubtitleGeneric =>
      'נראה שמתקיימת פגישה כעת. להקליט?';

  @override
  String get meetingDetectedRecord => 'הקלטה';

  @override
  String get meetingDetectedDismiss => 'התעלמות';

  @override
  String get meetingAutoStopTitle => 'נראה שהפגישה הסתיימה. לעצור את ההקלטה?';

  @override
  String get meetingAutoStopStop => 'עצירה';

  @override
  String get meetingAutoStopKeep => 'להמשיך להקליט';

  @override
  String get meetingAutoDetect => 'זיהוי אוטומטי של פגישות';

  @override
  String get meetingAutoDetectDescription =>
      'מעקב אחר לוח השנה ואפליקציות שיחות ועידה והצעה להקליט כשפגישה מתחילה.';

  @override
  String get meetingsRecordingCrumb => 'מקליט…';

  @override
  String get meetingRecordTitleHint => 'כותרת הפגישה';

  @override
  String get meetingRecordTappingLabel => 'לוכד:';

  @override
  String get meetingRecordMic => 'מיקרופון';

  @override
  String get meetingRecordSystemAudio => 'שמע מערכת';

  @override
  String get meetingRecordPause => 'השהיה';

  @override
  String get meetingRecordResume => 'המשך';

  @override
  String get meetingRecordStop => 'עצירה וסיכום';

  @override
  String get meetingRecordYourNotes => 'ההערות שלכם';

  @override
  String get meetingRecordNotesPlaceholder =>
      'הקלידו תוך כדי האזנה. כמה קטעים קצרים מספיקים — אחרי העצירה הסוכן ירחיב אותם בעזרת התמלול.';

  @override
  String get meetingRecordLiveTranscript => 'תמלול חי';

  @override
  String get meetingRecordDecoding => 'מפענח במכשיר';

  @override
  String get meetingRecordListening =>
      'מאזין… דיבור מופיע כאן תוך שנייה או שתיים, מתויג אתם / אחרים.';

  @override
  String get meetingRecordPausedHint => 'מושהה — השמע לא נקלט עד שתחדשו.';

  @override
  String get meetingRecordNotActive => 'אין הקלטה פעילה.';

  @override
  String get meetingHudRecording => 'מקליט';

  @override
  String get meetingHudPaused => 'מושהה';

  @override
  String get meetingHudOpen => 'פתיחה';

  @override
  String get meetingHudStop => 'עצירה';

  @override
  String get meetingToolbarPopOut => 'פתיחה בחלון נפרד';

  @override
  String get meetingToolbarHoldToStop => 'החזיקו לחוץ כדי לעצור את ההקלטה';

  @override
  String get meetingToolbarSemanticLabel => 'סרגל כלים של הקלטת פגישה';

  @override
  String get orchestrate => 'תזמור';

  @override
  String get orchestrationUnavailable => 'תזמור אינו זמין';

  @override
  String get orchestrationApprove => 'אישור התוכנית';

  @override
  String get orchestrationReject => 'דחייה';

  @override
  String get orchestrationCancel => 'ביטול התזמור';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count תפקידים — $hires מגויסים חדשים';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count תת-כרטיסים';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'עלות משוערת: \$$amount';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total תת-כרטיסים הושלמו';
  }

  @override
  String get orchestrationStatusProposed => 'הוצע';

  @override
  String get orchestrationStatusApproved => 'אושר';

  @override
  String get orchestrationStatusExecuting => 'מבצע';

  @override
  String get orchestrationStatusSynthesizing => 'מסנתז';

  @override
  String get orchestrationStatusCompleted => 'הושלם';

  @override
  String get orchestrationStatusFailed => 'נכשל';

  @override
  String get orchestrationStatusCancelled => 'בוטל';

  @override
  String get messageFailed => 'ההרצה נכשלה';

  @override
  String get turnLimitReached => 'נעצר במגבלת התורות — השיבו כדי להמשיך';

  @override
  String get retried => 'נוסה שוב';

  @override
  String replyingTo(String name) {
    return 'בתשובה ל-$name';
  }

  @override
  String get silenceTimeoutLabel => 'זמן קצוב לשקט (דקות)';

  @override
  String get silenceTimeoutHint =>
      'למשל 15 — הרצה תסתיים אחרי פרק זמן כזה ללא פלט';

  @override
  String get capabilityJsonMode => 'מצב JSON';

  @override
  String get capabilityModelSelection => 'בחירת מודל';

  @override
  String get transcriptThinking => 'חושב…';

  @override
  String transcriptThoughtFor(String duration) {
    return 'חשב במשך $duration';
  }

  @override
  String get transcriptStatusMakingEdits => 'מבצע עריכות…';

  @override
  String get transcriptStatusReadingFiles => 'קורא קבצים…';

  @override
  String get transcriptStatusSearching => 'מחפש בקוד…';

  @override
  String get transcriptStatusRunningCommands => 'מריץ פקודות…';

  @override
  String get transcriptStatusResponding => 'משיב…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return 'מריץ ⁨$tool⁩…';
  }

  @override
  String get transcriptInput => 'קלט';

  @override
  String get transcriptOutput => 'פלט';

  @override
  String get transcriptErrorLabel => 'שגיאה';

  @override
  String get transcriptSandboxBlocked => 'ארגז החול חסם פעולה';

  @override
  String transcriptShowFullOutput(int kb) {
    return 'הצגת הפלט המלא (⁨+$kb KB⁩)';
  }

  @override
  String transcriptShowAllLines(int count) {
    return 'הצגת כל $count השורות';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return 'מוצגות $count השורות הראשונות';
  }

  @override
  String get transcriptGrepNoMatches => 'אין התאמות';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '$matches התאמות',
      many: '$matches התאמות',
      two: 'שתי התאמות',
      one: 'התאמה אחת',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files קבצים',
      many: '$files קבצים',
      two: 'שני קבצים',
      one: 'קובץ אחד',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return 'אדם $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => 'שינוי שם הדובר';

  @override
  String get meetingRenameSpeakerTitle => 'שינוי שם הדובר';

  @override
  String get meetingSpeakerNameLabel => 'שם';

  @override
  String get meetingSpeakerSuggestFromCalendar => 'מתוך המוזמנים לפגישה הזו';

  @override
  String get meetingRenameSpeakerApplyAll => 'החלה על כל הקטעים של הדובר הזה';

  @override
  String get meetingRenameSpeakerScopeHint =>
      'כשהאפשרות כבויה, רק השורה שנבחרה משתנה.';

  @override
  String get meetingLinkEvent => 'קישור לאירוע';

  @override
  String get meetingChangeEvent => 'החלפת אירוע';

  @override
  String get meetingLinkEventTitle => 'קישור לאירוע בלוח השנה';

  @override
  String get meetingLinkEventSearchHint => 'חיפוש אירועים';

  @override
  String get meetingLinkEventEmpty => 'אין אירועי לוח שנה קרובים';

  @override
  String get meetingUnlinkEvent => 'הסרת הקישור';

  @override
  String get calendarLinkExistingMeeting => 'קישור לפגישה קיימת';

  @override
  String get calendarLinkMeetingTitle => 'קישור פגישה';

  @override
  String get calendarLinkMeetingSearchHint => 'חיפוש פגישות';

  @override
  String get calendarLinkMeetingEmpty => 'אין פגישות לקישור';

  @override
  String get meetingRenameSpeakerFailed => 'לא ניתן לשנות את שם הדובר';

  @override
  String get calendarLinkUpdateFailed => 'לא ניתן לעדכן את הקישור ללוח השנה';

  @override
  String get rename => 'שינוי שם';

  @override
  String get notNow => 'לא עכשיו';

  @override
  String get meetingSaveVoiceProfileTitle => 'לשמור פרופיל קול?';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return 'זיהוי אוטומטי של $name בפגישות עתידיות באמצעות שמירת טביעת הקול.';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return 'פרופיל הקול של $name נשמר';
  }

  @override
  String get meetingVoiceProfileSaveFailed => 'לא ניתן לשמור את פרופיל הקול';

  @override
  String get voiceProfilesSection => 'פרופילי קול';

  @override
  String get voiceProfilesDescription =>
      'קולות שמורים מזוהים אוטומטית בפגישות עתידיות.';

  @override
  String get voiceProfilesEmpty =>
      'אין עדיין קולות שמורים. תנו שם לדובר בתמלול פגישה, ואז בחרו \"שמירת פרופיל קול\".';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count דגימות',
      many: '$count דגימות',
      two: 'שתי דגימות',
      one: 'דגימה אחת',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => 'שינוי שם פרופיל קול';

  @override
  String get deleteVoiceProfileTitle => 'למחוק את פרופיל הקול?';

  @override
  String deleteVoiceProfileBody(String name) {
    return 'להפסיק לזהות את $name? טביעת הקול השמורה תוסר. שמות שכבר הוחלו בפגישות קודמות יישמרו.';
  }

  @override
  String get connectedLabel => 'מחובר';

  @override
  String get ideTabGeneral => 'כללי';

  @override
  String get ideTabExplorer => 'סייר';

  @override
  String get ideTabSourceControl => 'בקרת מקור';

  @override
  String get generalSectionTodos => 'מטלות';

  @override
  String get generalSectionGoals => 'יעדים';

  @override
  String get goalRunStatusActive => 'פעיל';

  @override
  String get goalRunStatusPaused => 'מושהה';

  @override
  String get goalRunStatusCompleted => 'הושלם';

  @override
  String get goalRunStatusFailed => 'נכשל';

  @override
  String get goalRunStatusCancelled => 'בוטל';

  @override
  String get goalRunStatusBudgetExhausted => 'התקציב מוצה';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return 'הרצה $run מתוך $max · $cost מתוך $cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return 'הרצה $run · $cost מתוך $cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return 'עד $deadline';
  }

  @override
  String get goalRunPause => 'השהיית היעד';

  @override
  String get goalRunResume => 'חידוש היעד';

  @override
  String goalRunResumeRaise(String cap) {
    return 'חידוש · העלאת התקרה ל-$cap';
  }

  @override
  String get goalRunStop => 'עצירת היעד';

  @override
  String get generalSectionAgents => 'סוכנים';

  @override
  String get generalSectionTerminals => 'טרמינלים';

  @override
  String get generalTodosEmpty => 'אין מטלות עדיין';

  @override
  String get generalAgentsEmpty => 'אין סוכנים פועלים';

  @override
  String get generalTerminalsEmpty => 'אין טרמינלים פתוחים';

  @override
  String get generalSectionBrowsers => 'דפדפנים';

  @override
  String get generalSectionComputers => 'מחשבים';

  @override
  String get generalBrowsersEmpty => 'אין דפדפנים פתוחים';

  @override
  String get generalComputersEmpty => 'אין מחשבים פתוחים';

  @override
  String get generalSectionPhones => 'טלפונים';

  @override
  String get generalPhonesEmpty => 'אין טלפונים פתוחים';

  @override
  String get pauseAgent => 'השהיית הסוכן';

  @override
  String get resumeAgent => 'חידוש הסוכן';

  @override
  String get agentCannotPause =>
      'לא ניתן להשהות את הסוכן הזה — עצרו אותו במקום.';

  @override
  String get goalClear => 'ניקוי היעד';

  @override
  String get undoLabelGoalClear => 'ניקוי היעד';

  @override
  String get todoStatusPending => 'טרם החלה';

  @override
  String get todoStatusInProgress => 'בתהליך';

  @override
  String get todoStatusCompleted => 'הושלמה';

  @override
  String get reorderTodo => 'שינוי סדר מטלה';

  @override
  String get focusTerminal => 'מיקוד בטרמינל';

  @override
  String get focusMachine => 'מיקוד במכונה';

  @override
  String get focusBrowser => 'מיקוד בדפדפן';

  @override
  String get todoEditorTitle => 'עריכת מטלות';

  @override
  String get todoEditorHint =>
      'פריט אחד בכל שורה. ⁨- [ ]⁩ = ממתינה, ⁨- [~]⁩ = בתהליך, ⁨- [x]⁩ = הושלמה.';

  @override
  String get todoNeedsText => 'הוסיפו טקסט אחרי הפקודה';

  @override
  String get todoNotFound => 'אין מטלה תואמת';

  @override
  String get todoCleared => 'רשימת המטלות נוקתה';

  @override
  String get todoNothingToCopy => 'אין מה להעתיק';

  @override
  String todoAdded(String content) {
    return 'נוספה: \"$content\"';
  }

  @override
  String todoStarted(String content) {
    return 'החלה: \"$content\"';
  }

  @override
  String todoCompleted(String content) {
    return 'הושלמה: \"$content\"';
  }

  @override
  String todoRemoved(String content) {
    return 'הוסרה: \"$content\"';
  }

  @override
  String todoCopied(int count) {
    return 'הועתקו $count פריטים';
  }

  @override
  String todoImported(int count) {
    return 'יובאו $count פריטים';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return 'פקודת מטלות לא מוכרת \"⁨$name⁩\"';
  }

  @override
  String get terminal => 'טרמינל';

  @override
  String get ideCloseTab => 'סגירת כרטיסייה';

  @override
  String get ideSplitEditor => 'פיצול העורך';

  @override
  String get ideSplitRight => 'פיצול ימינה';

  @override
  String get ideSplitDown => 'פיצול למטה';

  @override
  String get ideSplitLeft => 'פיצול שמאלה';

  @override
  String get ideSplitUp => 'פיצול למעלה';

  @override
  String get ideCloseGroup => 'סגירת הקבוצה';

  @override
  String get ideCloseOthers => 'סגירת האחרות';

  @override
  String get ideCloseToRight => 'סגירת הכרטיסיות שאחרי';

  @override
  String get ideCloseSaved => 'סגירת הכרטיסיות השמורות';

  @override
  String get ideCloseAll => 'סגירת הכול';

  @override
  String get ideSplit => 'פיצול';

  @override
  String get ideToggleSidebar => 'הצגה/הסתרה של סרגל הצד';

  @override
  String get ideNewTab => 'פתיחת עורך';

  @override
  String get ideNewTabMenu => 'כרטיסייה חדשה';

  @override
  String get ideReviewCode => 'סקירת קוד';

  @override
  String ideReviewCodeInRepo(String repo) {
    return 'סקירת קוד (⁨$repo⁩)';
  }

  @override
  String get ideRevertConfirmTitle => 'שחזור שינויים';

  @override
  String get ideRevertUntracked => 'לא ניתן לשחזר קבצים שאינם במעקב';

  @override
  String get ideRevertFailed =>
      'לא ניתן לשחזר את הקבצים. ייתכן שעץ העבודה של השיחה אינו זמין.';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count קבצים',
      many: '$count קבצים',
      two: 'שני קבצים',
      one: 'קובץ אחד',
    );
    return 'לא ניתן היה לשחזר $_temp0 (לא במעקב).';
  }

  @override
  String get ideSearchMatchCase => 'התאמת רישיות';

  @override
  String get ideSearchWholeWord => 'מילה שלמה';

  @override
  String get ideSearchRegex => 'ביטוי רגולרי';

  @override
  String get ideSearchFilters => 'מסנני חיפוש';

  @override
  String get ideSearchFilesToInclude => 'קבצים להכללה';

  @override
  String get ideSearchFilesToExclude => 'קבצים להחרגה';

  @override
  String get ideNoOpenTabs => 'אין כרטיסיות פתוחות — השתמשו ב-⁨+⁩ כדי לפתוח';

  @override
  String get ideBrowserAddressHint => 'הזינו כתובת או חיפוש';

  @override
  String get ideSimpleWebBrowser => 'דפדפן אינטרנט פשוט';

  @override
  String get ideWebBrowser => 'דפדפן אינטרנט';

  @override
  String get ideBrowserEnterUrl => 'הזינו URL בשורת הכתובת כדי להתחיל לגלוש';

  @override
  String get ideCodeServer => 'עורך';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return 'לשמור שינויים ב-⁨$fileName⁩?';
  }

  @override
  String get ideUnsavedChangesBody => 'השינויים שלכם יאבדו אם לא תשמרו אותם.';

  @override
  String get ideDontSave => 'לא לשמור';

  @override
  String get editorAutoSave => 'שמירה אוטומטית';

  @override
  String get editorAutoSaveDescription =>
      'שמירת שינויים אוטומטית בעורך המובנה.';

  @override
  String get editorAutoSaveOff => 'כבוי';

  @override
  String get editorAutoSaveAfterDelay => 'לאחר השהיה';

  @override
  String get editorAutoSaveOnFocusChange => 'בשינוי מיקוד';

  @override
  String get ideCodeServerUnavailable => '⁨code-server⁩ אינו זמין בשרת הזה';

  @override
  String get ideCodeServerUnavailableHint =>
      'התקינו ⁨code-server⁩ (⁨coder/code-server⁩) על מארח השרת, ואז פתחו את העורך מחדש.';

  @override
  String get ideCodeServerInstalling => 'מכין את העורך…';

  @override
  String get ideCodeServerOpenInBrowser => 'פתיחת העורך בדפדפן';

  @override
  String get ideCodeServerError => 'לא ניתן לפתוח את העורך';

  @override
  String get paneSuspendedCaption =>
      'הושעה כדי לחסוך במשאבים — נטען מחדש עם קבלת מיקוד';

  @override
  String get ideFolderLoadFailed => 'לא ניתן לטעון את התיקייה הזו';

  @override
  String get ideFileSearchFailed => 'לא ניתן לחפש קבצים';

  @override
  String get ideSearchInFiles => 'חיפוש בקבצים';

  @override
  String get ideNoContentMatches => 'אין התאמות';

  @override
  String get ideSourceControlCreatePr => 'יצירת בקשת משיכה';

  @override
  String ideSourceControlViewPr(int number) {
    return 'הצגת בקשת משיכה ⁨#$number⁩';
  }

  @override
  String get ideSourceControlNoChanges => 'אין שינויים';

  @override
  String get noReposInConversation => 'אין מאגרים בשיחה הזו';

  @override
  String get ideSourceControlNoSpace => 'פתחו שיחה כדי לראות את השינויים שלה';

  @override
  String get ideFileLoading => 'טוען…';

  @override
  String get ideFileBinary => 'קובץ בינארי';

  @override
  String get mcpExternalServers => 'שרתי MCP חיצוניים';

  @override
  String get mcpExternalServersDescription =>
      'התחברות לשרתי MCP חיצוניים (GitHub, Sentry, Postgres, אוטומציית דפדפן). שרתים שהגדרתם עבור Claude, Cursor, VS Code וכלים אחרים מתגלים אוטומטית.';

  @override
  String get mcpApprovalMode => 'אישור כלים';

  @override
  String get mcpApprovalModeDescription =>
      'אילו פעולות של כלים רצות בלי לשאול. קריאה תמיד מותרת; דרגות גבוהות יותר מבקשות אישור.';

  @override
  String get mcpApprovalAlwaysAsk => 'לשאול תמיד';

  @override
  String get mcpApprovalWrite => 'אישור אוטומטי לכתיבות';

  @override
  String get mcpApprovalYolo => 'אישור אוטומטי להכול';

  @override
  String get mcpNoExternalServers => 'לא התגלו שרתי MCP חיצוניים.';

  @override
  String get mcpAuthorize => 'מתן הרשאה';

  @override
  String get mcpReconnect => 'התחברות מחדש';

  @override
  String get mcpExternalConnectionsNote =>
      'שרתי MCP חיצוניים רצים על שרת הסוכנים (משותף לגרסת שולחן העבודה ולגרסת האינטרנט). מתן הרשאה לשרתי OAuth זמין רק בשולחן העבודה.';

  @override
  String get mcpStatusConnected => 'מחובר';

  @override
  String get mcpStatusConnecting => 'מתחבר…';

  @override
  String get mcpStatusNeedsAuth => 'נדרשת הרשאה';

  @override
  String get mcpStatusFailed => 'נכשל';

  @override
  String get mcpStatusCircuitOpen => 'מושהה';

  @override
  String get mcpStatusDisabled => 'מושבת';

  @override
  String get providersAndModels => 'ספקים ומודלים';

  @override
  String get providersAndModelsDescription =>
      'כל הספקים שהסוכן המובנה יכול להשתמש בהם — הגדירו מפתח API או התחברו דרך הדפדפן, צפו במודלים ובתמחור של כל ספק מחובר וקבעו באילו ספקים סביבת העבודה הזו רשאית להשתמש.';

  @override
  String get syncNow => 'סנכרון עכשיו';

  @override
  String syncNowResult(int applied, int failed) {
    return 'הסנכרון הושלם — $applied הוחלו, $failed נכשלו';
  }

  @override
  String syncNowFailed(String error) {
    return 'הסנכרון נכשל: ⁨$error⁩';
  }

  @override
  String get denied => 'נדחה';

  @override
  String get allowed => 'מותר';

  @override
  String allowProviderSemantic(String provider) {
    return 'לאפשר את ⁨$provider⁩';
  }

  @override
  String enabledViaEnv(String key) {
    return 'הופעל באמצעות ⁨$key⁩';
  }

  @override
  String costPerMillion(String input, String output) {
    return '⁨$input / $output⁩ למיליון';
  }

  @override
  String contextTokens(String tokens) {
    return 'הקשר של ⁨$tokens⁩';
  }

  @override
  String get usageAndCost => 'שימוש ועלות';

  @override
  String get usageAndCostDescription =>
      'ההוצאה על הסוכנים שלכם ב-7 הימים האחרונים, לפי עלויות הרצה שנצפו.';

  @override
  String get noUsageYet => 'עדיין לא נרשם שימוש.';

  @override
  String get spentThisWeek => 'הוצאו השבוע';

  @override
  String get subscriptionUsage => 'שימוש במינוי';

  @override
  String get subscriptionUsageUnavailable => 'לא זמין';

  @override
  String get subscriptionUsageExhausted => 'המכסה מוצתה';

  @override
  String get subscriptionUsageSignInRequired => 'יש להתחבר שוב';

  @override
  String get subscriptionUsageSignInExpired => 'ההתחברות פגה, תתחדש בהרצה הבאה';

  @override
  String get subscriptionUsagePartiallyAvailable => 'זמין חלקית';

  @override
  String resetsIn(String duration) {
    return 'מתאפס בעוד $duration';
  }

  @override
  String get feedbackHelpful => 'זה עזר';

  @override
  String get feedbackNotHelpful => 'זה לא עזר';

  @override
  String get modeChat => 'צ\'אט';

  @override
  String get modePlan => 'תכנון';

  @override
  String get modeReview => 'סקירה';

  @override
  String get modeOrchestrate => 'תזמור';

  @override
  String get editorTheme => 'ערכת נושא לעורך';

  @override
  String get editorThemeDescription =>
      'ייבוא ערכת צבעים של VS Code כדי שתצוגת ה-diff והעורך המובנים יתאימו ל-IDE שלכם.';

  @override
  String get editorThemePasteHint =>
      'הדביקו את התוכן של קובץ JSON של ערכת צבעים של VS Code';

  @override
  String get editorThemeImported => 'ערכת הנושא יובאה';

  @override
  String get editorThemeInvalid => 'זה לא נראה כמו ערכת נושא תקינה של VS Code';

  @override
  String get importTheme => 'ייבוא ערכת נושא';

  @override
  String get clearTheme => 'ניקוי ערכת נושא';

  @override
  String get openInDiffViewer => 'פתיחה במציג ה-diff';

  @override
  String get shellCommand => 'פקודה';

  @override
  String get shellOutput => 'פלט';

  @override
  String get revertToHere => 'שחזור לנקודה זו';

  @override
  String get revertConfirmBody =>
      'להסתיר את ההודעות שאחרי נקודה זו ולהחזיר את שינויי הקבצים של הסוכן לתור הזה? אפשר לבטל את הפעולה.';

  @override
  String get revert => 'שחזור';

  @override
  String get revertedToHere => 'שוחזר לנקודה זו';

  @override
  String get nothingToRevert => 'אין מה לשחזר';

  @override
  String get undoRevert => 'ביטול השחזור';

  @override
  String get revertUndone => 'השחזור בוטל';

  @override
  String get systemBehavior => 'התנהגות המערכת';

  @override
  String get keepAwakeTitle => 'השארת המחשב ער בזמן שסוכנים פועלים';

  @override
  String get keepAwakeOnSubtitle => 'המחשב לא יעבור למצב שינה בזמן שסוכן עובד';

  @override
  String get keepAwakeOffSubtitle =>
      'המחשב עשוי לעבור למצב שינה גם בזמן שסוכן עובד';

  @override
  String get syncEngineSectionTitle => 'מנוע סנכרון';

  @override
  String get syncEngineDescription =>
      'כרטיסים, הודעות והערות מתעדכנים בזמן אמת באמצעות שינויים מצטברים קטנים במקום תמונות מצב מלאות. כיבוי מתג מחזיר את אותו רכיב לסנכרון בתמונת מצב מלאה — יש לטעון מחדש את האפליקציה כדי שהשינוי ייכנס לתוקף.';

  @override
  String get syncEngineTicketsTitle => 'כרטיסים';

  @override
  String get syncEngineMessagingTitle => 'הודעות';

  @override
  String get syncEngineNotesTitle => 'הערות';

  @override
  String get syncEngineOnSubtitle => 'סנכרון דלתא בזמן אמת פעיל';

  @override
  String get syncEngineOffSubtitle => 'משתמש בסנכרון תמונת מצב מלאה';

  @override
  String get spaces => 'מרחבים';

  @override
  String get spacesHomeDescription => 'בחרו מרחב מהרשימה, או התחילו מרחב חדש.';

  @override
  String get noSpacesYet => 'אין מרחבים עדיין';

  @override
  String get newSpace => 'מרחב חדש';

  @override
  String get spaceName => 'שם המרחב';

  @override
  String get spaceReposHint => 'מאגרים לצירוף';

  @override
  String get ideSourceControl => 'בקרת מקור';

  @override
  String get stagedChanges => 'שינויים ב-staging';

  @override
  String get changes => 'שינויים';

  @override
  String get stageFile => 'הוספה ל-staging';

  @override
  String get unstageFile => 'הסרה מ-staging';

  @override
  String get stageAll => 'הוספת כל השינויים ל-staging';

  @override
  String get unstageAll => 'הסרת הכול מ-staging';

  @override
  String get stageChangesToCommit => 'הוסיפו שינויים ל-staging כדי לבצע קומיט';

  @override
  String get syncToPrHead => 'משיכת הקומיטים האחרונים של ה-PR';

  @override
  String get syncedToPrHead => 'סונכרן לקומיטים האחרונים של ה-PR';

  @override
  String get syncPrHeadDirty => 'בצעו קומיט או בטלו את השינויים לפני הסנכרון';

  @override
  String get syncPrHeadFailed => 'לא ניתן היה להסתנכרן ל-head של ה-PR';

  @override
  String get spaceLabel => 'מרחב';

  @override
  String get keybindingNewSpace => 'מרחב חדש';

  @override
  String get keybindingCreateANewSpaceDescription => 'יצירת מרחב חדש';

  @override
  String get jumpToLatest => 'קפיצה לסוף';

  @override
  String get streaming => 'בשידור חי';

  @override
  String get newMessages => 'חדש';

  @override
  String get copyLink => 'העתקת קישור';

  @override
  String get linkCopied => 'הקישור הועתק';

  @override
  String get agentResponding => 'הסוכן מגיב';

  @override
  String get agentFinished => 'הסוכן סיים';

  @override
  String get harnessConnectProviderForModels => 'חברו ספק כדי לראות מודלים.';

  @override
  String get providerSignOut => 'התנתקות';

  @override
  String get providerWaitingForDeviceCode => 'ממתין שתאשרו את הקוד בדפדפן…';

  @override
  String get providerDeviceCodeHint =>
      'ודאו שהקוד הזה תואם לקוד שמוצג בדפדפן, ואז אשרו.';

  @override
  String get providerPlanUsageLoading => 'בודק את השימוש במסלול…';

  @override
  String get providerPlanUsageUnavailable => 'המסלול הזה לא דיווח על שימוש.';

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return 'להסיר את מפתח ה-API של ⁨$provider⁩?';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return 'המפתח השמור יימחק ולא ניתן יהיה להציגו שוב. סוכנים שמשתמשים במודלים של ⁨$provider⁩ יפסיקו לעבוד עד שתדביקו מפתח חדש.';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return 'להסיר את ⁨$provider⁩?';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return 'הספק והמפתח השמור שלו יימחקו. סוכנים שמוצמדים למודלים של ⁨$provider⁩ יפסיקו לעבוד.';
  }

  @override
  String get providerApiKeyHint => 'הדביקו מפתח API';

  @override
  String get providerApiKeyStoredHint => 'הדביקו מפתח API נוסף כדי להוסיף אותו';

  @override
  String get providerAddAnotherAccount => 'הוספת חשבון נוסף';

  @override
  String get providerActiveBadge => 'פעיל';

  @override
  String get providerOauthAccountFallback => 'חשבון OAuth';

  @override
  String get providerApiKeyFallback => 'מפתח API';

  @override
  String get providerRemoveCredentialConfirmTitle =>
      'להסיר את פרטי הגישה האלה?';

  @override
  String get providerSignOutAccountConfirmTitle => 'להתנתק מהחשבון הזה?';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return 'סוכנים שמשתמשים ב-⁨$provider⁩ יעברו למפתחות ולחשבונות האחרים שלו. כשלא יישארו כאלה, הם ייעצרו עד שתוסיפו אחד.';
  }

  @override
  String get providerBaseUrlHint => 'כתובת בסיס (אופציונלי)';

  @override
  String get addProvider => 'הוספת ספק';

  @override
  String get noCustomProviders => 'אין ספקים מותאמים אישית עדיין.';

  @override
  String get providerNameLabel => 'שם';

  @override
  String get apiTypeLabel => 'סוג API';

  @override
  String get providerBaseUrlLabel => 'כתובת בסיס';

  @override
  String get providerApiKeyOptionalHint => 'מפתח API (אופציונלי)';

  @override
  String get dialectOpenAiCompatible => 'תואם OpenAI';

  @override
  String get dialectAnthropicCompatible => 'תואם Anthropic';

  @override
  String get removeProviderTooltip => 'הסרת ספק';

  @override
  String get providerLogInWithBrowser => 'התחברות דרך הדפדפן';

  @override
  String providerLoginDialogTitle(String provider) {
    return 'התחברות אל ⁨$provider⁩';
  }

  @override
  String get providerLabel => 'ספק';

  @override
  String get selectProviderToLogin => 'בחרו ספק להתחברות';

  @override
  String providerLoginFailed(String error) {
    return 'ההתחברות נכשלה: ⁨$error⁩';
  }

  @override
  String get providerWaitingForBrowser => 'ממתין שתאשרו בדפדפן…';

  @override
  String get providerPasteCodeHint => 'או הדביקו את הקוד מהדפדפן';

  @override
  String get providerCompleteLogin => 'סיום';

  @override
  String get providerConnectedApiKey => 'מחובר באמצעות מפתח API';

  @override
  String get providerConnectedOauth => 'מחובר';

  @override
  String providerConnectedAccount(String account) {
    return 'מחובר · ⁨$account⁩';
  }

  @override
  String get providerLocalReady => 'מקומי · מוכן';

  @override
  String get providerNotConnected => 'לא מחובר';

  @override
  String get preparingWorkspace => 'מכין את סביבת העבודה…';

  @override
  String provisioningRunningSetupScript(String repo) {
    return 'מריץ את סקריפט ההקמה של ⁨$repo⁩…';
  }

  @override
  String get repoScriptsTitle => 'סקריפטים';

  @override
  String get repoScriptsTooltip => 'הגדרת סקריפטים למחזור החיים';

  @override
  String get repoScriptsSetupLabel => 'סקריפט הקמה';

  @override
  String get repoScriptsSetupHelp =>
      'רץ בעץ העבודה של המרחב מיד לאחר יצירתו — התקנת תלויות, יצירת קבצים. כשל מסמן את המרחב ככושל; ניסיון חוזר מריץ אותו שוב.';

  @override
  String get repoScriptsArchiveLabel => 'סקריפט ארכוב';

  @override
  String get repoScriptsArchiveHelp =>
      'רץ רגע לפני שעץ העבודה של המרחב נמחק — ניקוי משאבים מחוץ לעץ העבודה. כשל לעולם אינו חוסם מחיקה.';

  @override
  String get repoScriptsEnvHelp =>
      'רץ דרך bash מתוך עץ העבודה, עם המשתנים ⁨CC_WORKSPACE_PATH⁩ (עץ העבודה), ⁨CC_ROOT_PATH⁩ (שורש המאגר), ⁨CC_SPACE_ID⁩, ⁨CC_SPACE_NAME⁩ ו-⁨CC_REPO_NAME⁩.';

  @override
  String get repoScriptsSetupPlaceholder => 'לדוגמה: ⁨pnpm install⁩';

  @override
  String get repoScriptsArchivePlaceholder =>
      'לדוגמה: ⁨docker compose -p \$CC_SPACE_ID down⁩';

  @override
  String get repoScriptsRecentRuns => 'הרצות אחרונות';

  @override
  String get repoScriptsNoRuns => 'אין הרצות עדיין';

  @override
  String get repoScriptsSaved => 'הסקריפטים נשמרו';

  @override
  String get repoScriptsRunKindSetup => 'הקמה';

  @override
  String get repoScriptsRunKindArchive => 'ארכוב';

  @override
  String get repoScriptsRunStatusRunning => 'בביצוע';

  @override
  String get repoScriptsRunStatusSucceeded => 'הצליח';

  @override
  String get repoScriptsRunStatusFailed => 'נכשל';

  @override
  String get repoScriptsRunStatusTimedOut => 'פג הזמן הקצוב';

  @override
  String repoScriptsExitCode(int code) {
    return 'קוד יציאה $code';
  }

  @override
  String provisioningCloningRepo(String repo) {
    return 'משכפל את ⁨$repo⁩…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return 'מבצע checkout של בקשת המשיכה ב-⁨$repo⁩…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return 'מגדיר את הסוכן $agent…';
  }

  @override
  String get workspacePrepFailed => 'הכנת סביבת העבודה נכשלה';

  @override
  String get workspacePrepStopped => 'הכנת סביבת העבודה נעצרה';

  @override
  String get stopWorkspacePrep => 'עצירת ההכנה';

  @override
  String get stopWorkspacePrepTooltip => 'עצירת הכנת סביבת העבודה הזו';

  @override
  String get stopWorkspacePrepConfirm =>
      'לעצור את הכנת סביבת העבודה הזו? השכפול שמתבצע כעת יימחק — אפשר להתחיל אותו שוב מכאן.';

  @override
  String messageWillSendWhenReady(int count) {
    return '$count הודעות יישלחו כשההכנה תסתיים';
  }

  @override
  String get membersNav => 'חברים';

  @override
  String get membersSettingsDescription =>
      'אנשים עם גישה לסביבת עבודה זו: רשימת חברים, הזמנות ויומן ביקורת';

  @override
  String get memberRosterLabel => 'רשימת חברים';

  @override
  String get memberRepoAccessAction => 'גישה למאגרים';

  @override
  String memberRepoAccessTitle(String name) {
    return 'גישה למאגרים עבור $name';
  }

  @override
  String get roleOwner => 'בעלים';

  @override
  String get roleAdmin => 'מנהל';

  @override
  String get roleMember => 'חבר';

  @override
  String get roleViewer => 'צופה';

  @override
  String get roleGuest => 'אורח';

  @override
  String get removeMemberTitle => 'הסרת חבר';

  @override
  String removeMemberConfirm(String name) {
    return 'להסיר את $name מסביבת העבודה הזו? הגישה נשללת מיידית.';
  }

  @override
  String get transferOwnershipAction => 'העברת בעלות';

  @override
  String get transferOwnershipTitle => 'העברת בעלות';

  @override
  String transferOwnershipConfirm(String name) {
    return 'להפוך את $name לבעלים של סביבת העבודה הזו? התפקיד שלכם ישתנה למנהל. רק בעלים יכול למחוק את סביבת העבודה או לשנות תפקיד של מנהל אחר.';
  }

  @override
  String get transferOwnershipCta => 'העברה';

  @override
  String get auditTrailLabel => 'יומן ביקורת הרשאות';

  @override
  String get auditTrailDescription =>
      'כל אישור וכל סירוב, משורשרים בשרשרת גיבוב כך שרשומה ששונתה או נמחקה ניתנת לזיהוי.';

  @override
  String get auditVerifyChain => 'אימות השרשרת';

  @override
  String auditChainIntact(int count) {
    return 'השרשרת תקינה — אומתו $count רשומות';
  }

  @override
  String auditChainBroken(int seq, String reason) {
    return 'השרשרת נשברה ברשומה $seq: $reason';
  }

  @override
  String get auditEmpty => 'עדיין לא נרשמו החלטות.';

  @override
  String get auditDenied => 'נדחה';

  @override
  String get auditAllowed => 'אושר';

  @override
  String auditOnBehalfOf(String user) {
    return 'עבור $user';
  }

  @override
  String get policyTemplatesLabel => 'תבניות מדיניות';

  @override
  String get policyTemplatesDescription =>
      'החילו עמדת פתיחה, או העבירו מדיניות בין סביבות עבודה.';

  @override
  String get policyTemplateStrict => 'מחמירה';

  @override
  String get policyTemplateBalanced => 'מאוזנת';

  @override
  String get policyTemplatePermissive => 'מתירנית';

  @override
  String get policyTemplateApply => 'החלה';

  @override
  String policyTemplateApplied(int count) {
    return 'הוחלו $count כללים';
  }

  @override
  String get policyExport => 'העתקת מדיניות';

  @override
  String get policyExported => 'המדיניות הועתקה ללוח';

  @override
  String get policyImport => 'הדבקת מדיניות';

  @override
  String policyImported(int count) {
    return 'יובאו $count כללים';
  }

  @override
  String get approveAndRemember => 'אישור ל-8 שעות';

  @override
  String get approveAndRememberTooltip =>
      'מאשר את הפעולה הזו ומפסיק לשאול על פעולות דומות במרחב הזה למשך 8 שעות. התוקף פג מעצמו.';

  @override
  String get unknownUserLabel => 'משתמש לא ידוע';

  @override
  String get inviteMember => 'הזמנת חבר';

  @override
  String get inviteRepoAccessHeader => 'גישה למאגרים';

  @override
  String get inviteRepoAccessExplainer =>
      'רק המאגרים שתסמנו ישותפו עם המוזמן, ברמה שתבחרו. כל השאר נשאר מוסתר.';

  @override
  String get grantLevelRead => 'קריאה';

  @override
  String get grantLevelReview => 'סקירה';

  @override
  String get grantLevelWrite => 'כתיבה';

  @override
  String get inviteExpiryLabel => 'פג תוקף בעוד';

  @override
  String get expiryOneDay => 'יום אחד';

  @override
  String get expirySevenDays => '7 ימים';

  @override
  String get expiryThirtyDays => '30 יום';

  @override
  String get createInviteAction => 'יצירת הזמנה';

  @override
  String get inviteOneTimeCodeLabel => 'קוד חד-פעמי';

  @override
  String get inviteCodeShownOnce =>
      'הקוד מוצג פעם אחת בלבד — העתיקו אותו עכשיו.';

  @override
  String get inviteLinkLabel => 'קישור הזמנה';

  @override
  String get inviteRedeemHint =>
      'שתפו את הקוד עם המוזמן; הוא ימומש מול כתובת ה-URL של השרת שלכם.';

  @override
  String get inviteScanQr => 'או סרקו כדי לממש';

  @override
  String get inviteLoopbackWarningTitle => 'ההזמנה מצביעה על כתובת מקומית';

  @override
  String get inviteLoopbackWarningBody =>
      'משתפי פעולה במחשבים אחרים לא יוכלו להגיע לשרת הזה. הפעילו מנהרה (הגדרות ← אינטגרציות ← שיתוף השרת הזה) או קשרו את השרת לרשת שלכם כדי שמשתמשים מחוץ למחשב יוכלו להתחבר.';

  @override
  String get inviteStatusOpen => 'פתוחה';

  @override
  String get inviteStatusUsed => 'נוצלה';

  @override
  String get inviteStatusRevoked => 'בוטלה';

  @override
  String get inviteStatusExpired => 'פג תוקפה';

  @override
  String inviteCreatedTime(String time) {
    return 'נוצרה $time';
  }

  @override
  String inviteExpiresOn(String date) {
    return 'פג תוקף $date';
  }

  @override
  String get noActivityYet => 'אין פעילות עדיין';

  @override
  String get couldNotLoadMembers => 'לא ניתן היה לטעון את החברים';

  @override
  String get couldNotLoadInvites => 'לא ניתן היה לטעון את ההזמנות';

  @override
  String get couldNotLoadActivity => 'לא ניתן היה לטעון את הפעילות';

  @override
  String get yourDevices => 'המכשירים שלכם';

  @override
  String get yourDevicesDescription => 'לקוחות המצומדים לחשבון שלכם בשרת הזה.';

  @override
  String get noOwnDevices => 'עדיין לא מצומדים מכשירים לחשבון שלכם';

  @override
  String get renameDeviceTitle => 'שינוי שם המכשיר';

  @override
  String get revokeDeviceTitle => 'שלילת מכשיר';

  @override
  String revokeDeviceConfirm(String label) {
    return 'לשלול את ⁨$label⁩? הוא ינותק מיידית ולא יוכל עוד לגשת לשרת הזה.';
  }

  @override
  String devicePairedTime(String time) {
    return 'צומד $time';
  }

  @override
  String deviceLastSeenTime(String time) {
    return 'נראה לאחרונה $time';
  }

  @override
  String get deviceNeverSeen => 'מעולם לא התחבר';

  @override
  String get profileSectionLabel => 'פרופיל';

  @override
  String get profileSectionDescription =>
      'איך אתה מופיע לצוות ובמחבר commit של git במרחב הזה. שדות ריקים יורשים שם ואימייל מהחשבון.';

  @override
  String get displayNameLabel => 'שם תצוגה';

  @override
  String get emailLabel => 'אימייל';

  @override
  String get gitAuthorNameLabel => 'שם המחבר ב-Git';

  @override
  String get gitAuthorEmailLabel => 'אימייל המחבר ב-Git';

  @override
  String get profileSaved => 'הפרופיל נשמר';

  @override
  String get presenceOnline => 'מחובר';

  @override
  String get presenceIdle => 'לא פעיל';

  @override
  String get presenceTyping => 'מקליד…';

  @override
  String get presenceAgentThinking => 'חושב';

  @override
  String get presenceAgentRunning => 'פועל';

  @override
  String get presenceAgentBlocked => 'חסום';

  @override
  String get presenceAgentDone => 'סיים';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String presenceNameStatusCost(String name, String status, String cost) {
    return '$name — $status (⁨$cost⁩)';
  }

  @override
  String get presenceRailLabel => 'מי מחובר';

  @override
  String presencePlusCount(int count) {
    return '⁨+$count⁩';
  }

  @override
  String get dndTooltipOn => 'הפעלת \'נא לא להפריע\'';

  @override
  String get dndTooltipOff => 'כיבוי \'נא לא להפריע\'';

  @override
  String get startPresenting => 'התחלת הצגה';

  @override
  String get stopPresenting => 'עצירת הצגה';

  @override
  String spotlightPresentingBanner(String name) {
    return '$name מציג';
  }

  @override
  String get spotlightLeave => 'יציאה';

  @override
  String typingIndicator(String name) {
    return '$name מקליד…';
  }

  @override
  String get ideTabNotes => 'הערות';

  @override
  String get ideSidebarAllViews => 'כל התצוגות';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return 'כל התצוגות ($count מוסתרות)';
  }

  @override
  String get ideSidebarPinView => 'הצמדה לסרגל הצד';

  @override
  String get ideSidebarUnpinView => 'ביטול הצמדה מסרגל הצד';

  @override
  String get notesEmptyHint => 'הוסיפו הערה למי שימשיך את השיחה הזו…';

  @override
  String get notesEditTooltip => 'עריכת הערה';

  @override
  String notesUpdatedBy(String name, String time) {
    return 'עודכן על ידי $name · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '$name עורך';
  }

  @override
  String get notesSaveFailed => 'לא ניתן היה לשמור את ההערה';

  @override
  String get reactionAddTooltip => 'הוספת תגובת אימוג\'י';

  @override
  String reactionToggleTooltip(String emoji) {
    return 'תגובה עם $emoji';
  }

  @override
  String get autonomyDialLabel => 'אוטונומיה';

  @override
  String get autonomyProposeOnly => 'הצעות בלבד';

  @override
  String get autonomyActWithApproval => 'פעולה באישור';

  @override
  String get autonomyActFreely => 'פעולה חופשית';

  @override
  String get autonomyDefaultOption => 'ברירת מחדל';

  @override
  String get checkerLabel => 'בודק';

  @override
  String get checkerNone => 'ללא';

  @override
  String get checkerCaption => 'הבודק סוקר הרצות שהושלמו של סוכנים אחרים.';

  @override
  String get takeoverTooltip => 'השתלטות על עץ העבודה';

  @override
  String get takeoverBannerSelf => 'השתלטתם על עץ העבודה של השיחה הזו';

  @override
  String takeoverBannerOther(String name) {
    return '$name השתלט על עץ העבודה של השיחה הזו';
  }

  @override
  String get handBackButton => 'החזרת שליטה';

  @override
  String get handBackDialogTitle => 'החזרת עץ העבודה';

  @override
  String get handBackDialogNoteHint => 'הערה אופציונלית לסוכן…';

  @override
  String takeoverFailed(String message) {
    return 'ההשתלטות נכשלה: ⁨$message⁩';
  }

  @override
  String handBackFailed(String message) {
    return 'החזרת השליטה נכשלה: ⁨$message⁩';
  }

  @override
  String get planStudioTitle => 'סטודיו תוכניות';

  @override
  String get plansTitle => 'תוכניות';

  @override
  String get plansSubtitle => 'תוכניות פעילות, מסמכי תוכנית ופלייבוקים';

  @override
  String get plansActiveSection => 'תוכניות פעילות';

  @override
  String get plansDocumentsSection => 'מסמכי תוכנית';

  @override
  String get plansPlaybooksSection => 'פלייבוקים';

  @override
  String get plansNoActive => 'אין תוכניות פעילות עדיין.';

  @override
  String get plansNoDocuments => 'אין מסמכי תוכנית עדיין.';

  @override
  String get plansNoPlaybooks => 'אין פלייבוקים עדיין.';

  @override
  String get planNotFound => 'התוכנית לא נמצאה.';

  @override
  String get planOpenInStudio => 'פתיחה';

  @override
  String get planNodeTitle => 'כותרת';

  @override
  String get planNodeDescription => 'תיאור';

  @override
  String get planNodeDescriptionHint => 'מה השלב הזה אמור לעשות…';

  @override
  String get planNodeApplyDescription => 'החלה';

  @override
  String get planNodeRole => 'תפקיד';

  @override
  String get planNodeDependencies => 'תלוי ב־';

  @override
  String get planNodeDependenciesHint => 'הוספת תלות';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count תלויות',
      many: '$count תלויות',
      two: 'שתי תלויות',
      one: 'תלות אחת',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies =>
      'אין תלויות, ולכן זה רץ מיד כשהתוכנית מתחילה';

  @override
  String get planNodeOutputSchema => 'סכמת פלט (JSON)';

  @override
  String get planNodeEstimate => 'אומדן';

  @override
  String get planNodeProvenance => 'מקור';

  @override
  String get planNodeAlreadyExecuted =>
      'כבר בוצע — עריכה מפצלת את התוכנית מנקודה זו.';

  @override
  String get planNewNodeTitle => 'שלב חדש';

  @override
  String get planEstimateNoHistory => 'אין היסטוריה עדיין';

  @override
  String get planEstimateBlastUnknown => 'רדיוס פגיעה: לא ידוע';

  @override
  String get planEstimatePartial => 'חלקי';

  @override
  String get planEstimateAction => 'חישוב אומדן';

  @override
  String planEstimateDuration(String range) {
    return 'משך ⁨$range⁩';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return 'רדיוס פגיעה: $files קבצים, $symbols סמלים';
  }

  @override
  String get planApprove => 'אישור התוכנית';

  @override
  String get planApproveSelectedNodes => 'אישור הצמתים שנבחרו';

  @override
  String get planReject => 'דחייה';

  @override
  String get planCancel => 'ביטול ההרצה';

  @override
  String get planContinueNode => 'המשך הצומת';

  @override
  String get planTotalNotEstimated => 'טרם נאמד';

  @override
  String get planBudgetExceeded => 'חריגה מהתקציב';

  @override
  String planBudgetCeiling(String amount) {
    return 'תקציב ≤ ⁨\$$amount⁩';
  }

  @override
  String get planVersionsTitle => 'גרסאות';

  @override
  String get planNoRevisions => 'אין גרסאות עדיין.';

  @override
  String get planDiffIdentical => 'אין שינויים.';

  @override
  String get planDiffGoalChanged => 'המטרה השתנתה';

  @override
  String get planDiffBudgetChanged => 'התקציב השתנה';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'שינויים מ-⁨v$fromRev⁩ ל-⁨v$toRev⁩';
  }

  @override
  String planDiffAdded(String node) {
    return 'נוסף $node';
  }

  @override
  String planDiffRemoved(String node) {
    return 'הוסר $node';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return 'השתנה $node: ⁨$fields⁩';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return 'נוספה קשת: ⁨$edge⁩';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return 'הוסרה קשת: ⁨$edge⁩';
  }

  @override
  String planDiffRoleAdded(String role) {
    return 'נוסף תפקיד: $role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return 'הוסר תפקיד: $role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return 'תפקיד הוקצה מחדש: $role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return 'התוכנית תוכננה מחדש: אישרתם את ⁨v$approved⁩ והיא כעת ⁨v$current⁩. סקרו את ההבדלים לפני שהיא ממשיכה.';
  }

  @override
  String planLiveActualCost(String amount) {
    return 'עלות בפועל: ⁨\$$amount⁩';
  }

  @override
  String get planPlaybookRun => 'הרצה';

  @override
  String get planPlaybookDelete => 'מחיקת הפלייבוק';

  @override
  String get planPlaybookProposed => 'הוצעה תוכנית — אשרו אותה ב-Plan Studio.';

  @override
  String get planPlaybookAnchorTicket => 'כרטיס עוגן';

  @override
  String get planPlaybookPickTicket => 'בחרו כרטיס…';

  @override
  String get planPlaybookProposeRun => 'הצעת תוכנית';

  @override
  String get planPlaybookRepoHint => 'מזהה מאגר';

  @override
  String get planPlaybookAgentHint => 'מזהה סוכן';

  @override
  String planPlaybookRunTitle(String name) {
    return 'הרצת $name';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '$count פרמטרים';
  }

  @override
  String get recentLabel => 'אחרונים';

  @override
  String get cheatSheetTitle => 'קיצורי מקלדת';

  @override
  String get cheatSheetGlobal => 'כללי';

  @override
  String get cheatSheetThisScreen => 'המסך הזה';

  @override
  String get cheatSheetReservedInBrowser => 'שמור לדפדפן';

  @override
  String get keybindingCheatSheet => 'קיצורי מקלדת';

  @override
  String get keybindingShowKeyboardShortcutsDescription =>
      'הצגת דף קיצורי המקלדת של המסך הנוכחי';

  @override
  String get runPlaybookLabel => 'הרצת פלייבוק';

  @override
  String get playbooksLabel => 'פלייבוקים';

  @override
  String get keybindingUndo => 'ביטול';

  @override
  String get keybindingRedo => 'ביצוע מחדש';

  @override
  String get keybindingUndoLastActionDescription =>
      'ביטול הפעולה האחרונה הניתנת לביטול';

  @override
  String get keybindingRedoLastActionDescription =>
      'ביצוע מחדש של הפעולה האחרונה שבוטלה';

  @override
  String get undone => 'בוטל';

  @override
  String get redone => 'בוצע מחדש';

  @override
  String get undoFailed => 'לא ניתן היה לבטל';

  @override
  String get undoLabelTicketEdit => 'עריכת כרטיס';

  @override
  String get undoLabelMessageEdit => 'עריכת הודעה';

  @override
  String get undoLabelTodoStatus => 'סטטוס משימה';

  @override
  String get inboxTitle => 'דואר נכנס';

  @override
  String get inboxReview => 'סקירה';

  @override
  String get inboxOpen => 'פתיחה';

  @override
  String get inboxAllCaughtUp => 'הכול טופל';

  @override
  String get inboxGitHubDownTitle => 'ייתכן שיש תקלה ב-GitHub';

  @override
  String inboxGitHubDownBody(String status) {
    return 'GitHub מדווח על ⁨$status⁩, ולכן ייתכן שבקשות משיכה חסרות מהרשימה הזו ולא באמת הסתיימו.';
  }

  @override
  String get inboxGitHubIdentityTitle =>
      'לא ניתן היה לאמת את חשבון ה-GitHub שלכם';

  @override
  String get inboxGitHubIdentityBody =>
      'הדואר הנכנס ממוין לפי הזהות שלכם ב-GitHub. עד שהיא נטענת הוא נשאר ריק, גם כשבקשות משיכה ממתינות לכם.';

  @override
  String get inboxSeverityBlocking => 'חסום';

  @override
  String get inboxSeverityWaiting => 'ממתין';

  @override
  String get inboxSeverityInfo => 'מידע';

  @override
  String get inboxSyncFailed => 'הסנכרון נכשל';

  @override
  String get inboxNeedsYourAttention => 'דורש את תשומת ליבכם';

  @override
  String get inboxSectionNeedsYourReview => 'ממתינות לסקירה שלכם';

  @override
  String get inboxSectionReturnedToYou => 'הוחזרו אליכם';

  @override
  String get inboxSectionApproved => 'אושרו';

  @override
  String get inboxSectionDrafts => 'טיוטות';

  @override
  String get inboxSectionWaitingForReviewers => 'ממתינות לסוקרים';

  @override
  String get inboxSectionMergingAndMerged => 'במיזוג ומוזגו לאחרונה';

  @override
  String get inboxSectionWaitingForAuthor => 'ממתינות למחבר';

  @override
  String get inboxColumnTitle => 'כותרת';

  @override
  String get inboxColumnChanges => 'שינויים';

  @override
  String get inboxColumnUpdated => 'עודכן';

  @override
  String get inboxReviewApproved => 'אושר';

  @override
  String get inboxReviewChangesRequested => 'התבקשו שינויים';

  @override
  String get inboxHeroSubtitle =>
      'כל בקשת משיכה שנוגעת אליכם, ממוינת לפי הצעד הבא.';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count בקשות משיכה ממתינות לסקירה שלכם',
      many: '$count בקשות משיכה ממתינות לסקירה שלכם',
      two: 'שתי בקשות משיכה ממתינות לסקירה שלכם',
      one: 'בקשת משיכה אחת ממתינה לסקירה שלכם',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count הוחזרו אליכם',
      many: '$count הוחזרו אליכם',
      two: 'שתיים הוחזרו אליכם',
      one: 'אחת הוחזרה אליכם',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted => 'השינוי לא נשמר ולכן בוטל';

  @override
  String get offlinePendingLabel => 'ממתין';

  @override
  String get offlineSyncingLabel => 'מסתנכרן';

  @override
  String get copyLinkLabel => 'העתקת קישור לעמוד הזה';

  @override
  String get agentsSectionLabel => 'סוכנים';

  @override
  String get fleetWorkersTitle => 'וורקרים';

  @override
  String get fleetWorkersSubtitle => 'מכונות זמינות להרצת עבודות';

  @override
  String get fleetJobsTitle => 'עבודות';

  @override
  String get fleetJobsSubtitle => 'עבודה שמפוזרת על פני הצי';

  @override
  String get fleetNoWorkers =>
      'אין וורקרים עדיין — מכונה נוספת שמריצה ⁨`cc_worker --server <url>`⁩ מצטרפת לצי.';

  @override
  String get fleetNoJobs => 'אין עבודות.';

  @override
  String get fleetError => 'לא ניתן היה לטעון את הצי';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ליבות',
      many: '$count ליבות',
      two: 'שתי ליבות',
      one: 'ליבה אחת',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return 'פעימה $time';
  }

  @override
  String get fleetNoHeartbeat => 'אין פעימה עדיין';

  @override
  String fleetLastErrorLabel(String error) {
    return 'שגיאה אחרונה: ⁨$error⁩';
  }

  @override
  String get fleetDrain => 'ריקון';

  @override
  String get fleetResume => 'חידוש';

  @override
  String get fleetRevoke => 'שלילה';

  @override
  String get fleetRemove => 'הסרה';

  @override
  String get fleetRevokeTitle => 'לשלול את הוורקר?';

  @override
  String fleetRevokeBody(String name) {
    return 'לשלול את ⁨$name⁩? ההפעלה שלו תסתיים וכל עבודה פעילה תוקצה מחדש.';
  }

  @override
  String get fleetRemoveTitle => 'להסיר את הוורקר?';

  @override
  String fleetRemoveBody(String name) {
    return 'להסיר את ⁨$name⁩ מהצי? הרשומה שלו תימחק.';
  }

  @override
  String get fleetActionFailed => 'הפעולה נכשלה';

  @override
  String get fleetJobUnassigned => 'לא משויכת';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '⁨$attempts/$max⁩ ניסיונות';
  }

  @override
  String get fleetPlacementReasons => 'החלטות שיבוץ';

  @override
  String get fleetNoPlacements => 'אין החלטות שיבוץ עדיין.';

  @override
  String get fleetStatusOnline => 'מחובר';

  @override
  String get fleetStatusDraining => 'מתרוקן';

  @override
  String get fleetStatusOffline => 'מנותק';

  @override
  String get fleetStatusIncompatible => 'לא תואם';

  @override
  String get fleetStatusRevoked => 'נשלל';

  @override
  String get fleetJobStatusQueued => 'בתור';

  @override
  String get fleetJobStatusRunning => 'בביצוע';

  @override
  String get fleetJobStatusSucceeded => 'הושלמה';

  @override
  String get fleetJobStatusFailed => 'נכשלה';

  @override
  String get fleetJobStatusCancelled => 'בוטלה';

  @override
  String get evalsNoSuites => 'אין חבילות הערכה עדיין.';

  @override
  String get evalsError => 'לא ניתן היה לטעון את ההערכות';

  @override
  String get evalsStarterBadge => 'התחלתית';

  @override
  String evalsDefaultBatch(int count) {
    return 'אצוות ברירת מחדל של $count';
  }

  @override
  String get evalsRecentRuns => 'הרצות אחרונות';

  @override
  String get evalsNoRuns => 'אין הרצות עדיין.';

  @override
  String get evalsPassRate => 'שיעור הצלחה';

  @override
  String evalsBatchTimes(int count) {
    return '⁨× $count⁩';
  }

  @override
  String evalsTriggeredBy(String who) {
    return 'על ידי $who';
  }

  @override
  String evalsRunFinished(String rate) {
    return 'ההערכה הסתיימה — $rate עברו';
  }

  @override
  String get evalsRunFailed => 'לא ניתן היה להריץ את החבילה';

  @override
  String get evalsRun => 'הרצה';

  @override
  String get evalsStatusQueued => 'בתור';

  @override
  String get evalsStatusRunning => 'בביצוע';

  @override
  String get evalsStatusPassed => 'עבר';

  @override
  String get evalsStatusFailed => 'נכשל';

  @override
  String get bannerMeetingJoin => 'הצטרפות';

  @override
  String get bannerMeetingRecordAndLink => 'הקלטה וקישור';

  @override
  String get bannerCalendarReconnect => 'התחברות מחדש';

  @override
  String get bannerView => 'צפייה';

  @override
  String get soundscapeTitle => 'נופי צליל';

  @override
  String get soundscapePlay => 'ניגון';

  @override
  String get soundscapePause => 'השהיה';

  @override
  String get soundscapeMoodLabel => 'אווירה';

  @override
  String get soundscapeMoodFocus => 'ריכוז';

  @override
  String get soundscapeMoodRelax => 'רגיעה';

  @override
  String get soundscapeMoodSleep => 'שינה';

  @override
  String get soundscapeMoodRise => 'עלייה';

  @override
  String get soundscapeVolumeLabel => 'עוצמת שמע';

  @override
  String get soundscapeTuneLabel => 'כוונון';

  @override
  String get soundscapeTuneMellow => 'רך';

  @override
  String get soundscapeTuneBright => 'בהיר';

  @override
  String get soundscapeTuneEnergetic => 'אנרגטי';

  @override
  String get soundscapeTuneSpacy => 'חללי';

  @override
  String get soundscapeTuneResetHint => 'הקשה כפולה לאיפוס';

  @override
  String get soundscapeSceneLabel => 'מתנגן עכשיו';

  @override
  String get soundscapeSceneLoading => 'מכוונן את האווירה…';

  @override
  String soundscapeTemperature(int degrees) {
    return '⁨$degrees°C⁩';
  }

  @override
  String get soundscapeLocationLabel => 'מיקום';

  @override
  String get soundscapeLocationDetecting => 'מזהה מיקום…';

  @override
  String get soundscapeLocationAutoNote => 'המיקום מגיע מהמכשיר הזה.';

  @override
  String get soundscapeRefreshWeather => 'רענון מזג האוויר';

  @override
  String get soundscapeAutoStartLabel => 'הפעלה עם מצב ריכוז';

  @override
  String get soundscapeAutoStartDescription =>
      'השמעת נוף צליל אוטומטית בתחילת סשן ריכוז.';

  @override
  String get soundscapeReturnToApp => 'חזרה לאפליקציה';

  @override
  String get soundscapePopOut => 'פתיחת הנגן בחלון צף';

  @override
  String get discussion => 'דיון';

  @override
  String get chat => 'צ\'אט';

  @override
  String get saving => 'שומר…';

  @override
  String get saved => 'נשמר';

  @override
  String get saveFailed => 'לא ניתן היה לשמור';

  @override
  String get commitAndPush => 'קומיט ודחיפה';

  @override
  String get commit => 'קומיט';

  @override
  String get commitAmend => 'קומיט (amend)';

  @override
  String get commitAndSync => 'קומיט וסנכרון';

  @override
  String get scmSyncChanges => 'סנכרון שינויים';

  @override
  String get scmPublishBranch => 'פרסום הענף';

  @override
  String get scmSyncFailed => 'הסנכרון נכשל';

  @override
  String get scmSyncDirty => 'בצע קומיט או בטל שינויים לפני הסנכרון';

  @override
  String get scmSynced => 'סונכרן';

  @override
  String get scmSelectBranch => 'בחירת ענף למעבר';

  @override
  String get scmCreateBranch => 'יצירת ענף חדש…';

  @override
  String get scmCreateBranchFrom => 'יצירת ענף חדש מתוך…';

  @override
  String get scmCheckoutDetached => 'מעבר ל-HEAD מנותק…';

  @override
  String get scmBranchName => 'שם הענף';

  @override
  String get scmCreateBranchTitle => 'יצירת ענף';

  @override
  String scmFromRef(String ref) {
    return 'מתוך ⁨$ref⁩';
  }

  @override
  String get scmCheckoutFailed => 'לא ניתן להחליף ענף';

  @override
  String get scmCheckoutDirty =>
      'יש לבצע commit או לבטל שינויים לפני החלפת ענף';

  @override
  String scmSwitchedToBranch(String branch) {
    return 'עברת אל ⁨$branch⁩';
  }

  @override
  String scmDetachedAt(String ref) {
    return 'מנותק ב-⁨$ref⁩';
  }

  @override
  String get scmDetachedHead => 'HEAD מנותק';

  @override
  String get scmNoBranches => 'אין ענפים תואמים';

  @override
  String get scmBranches => 'ענפים';

  @override
  String get scmRemoteBranches => 'ענפים מרוחקים';

  @override
  String get scmTags => 'תגיות';

  @override
  String get scmPickStartPoint => 'בחירת נקודת התחלה';

  @override
  String get scmSwitchBranch => 'החלפת ענף';

  @override
  String commitMessageOnBranch(String shortcut, String branch) {
    return 'הודעה ($shortcut לקומיט על “$branch”)';
  }

  @override
  String get committed => 'הקומיט בוצע';

  @override
  String get commitAmended => 'הקומיט תוקן';

  @override
  String get commitFailed => 'הקומיט נכשל';

  @override
  String get moreCommitActions => 'פעולות קומיט נוספות';

  @override
  String get sourceControl => 'בקרת מקור';

  @override
  String fixFindingTitle(String location) {
    return 'תיקון: ⁨$location⁩';
  }

  @override
  String get openInEditor => 'פתיחה בעורך';

  @override
  String get regexTesterTitle => 'בדיקת ביטוי רגולרי';

  @override
  String get regexTesterHint => 'הקלד דוגמה';

  @override
  String get regexMatch => 'התאמה';

  @override
  String get regexNoMatch => 'אין התאמה';

  @override
  String get regexInvalidPattern => 'תבנית לא תקינה';

  @override
  String get symbolLookupNone => 'אין הגדרה באינדקס או בבקשת המשיכה הזו';

  @override
  String get symbolLookupInDiff => 'נמצא בבקשת המשיכה הזו';

  @override
  String get symbolLookupFromBase =>
      'מתוך ה-checkout הבסיסי — עץ העבודה של ה-PR הזה עדיין לא באינדקס';

  @override
  String get symbolImplementations => 'מימושים';

  @override
  String symbolCallersCount(int count) {
    return '$count קוראים';
  }

  @override
  String get commitMessageHint => 'הודעת קומיט';

  @override
  String get pushedToPr => 'נדחף ל-PR';

  @override
  String get pushFailed => 'הדחיפה נכשלה';

  @override
  String get reviewFindings => 'ממצאים';

  @override
  String get treeLabel => 'עץ';

  @override
  String get toggleFileTree => 'הצגה או הסתרה של עץ הקבצים';

  @override
  String get diffViewSettings => 'הגדרות תצוגת ה-diff';

  @override
  String get splitViewLabel => 'מפוצלת';

  @override
  String get unifiedViewLabel => 'מאוחדת';

  @override
  String get wrapLines => 'גלישת שורות';

  @override
  String get shiftClickSelectRange => 'לחיצה עם Shift לבחירת טווח';

  @override
  String diffFilesCount(int count) {
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
  String prComplexityLoc(String loc) {
    return '$loc LOC';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return 'PR קטן — $files, כ-$minutes דק\' לסקירה';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return 'PR בינוני — $files, שריינו כ-$minutes דק\' לסקירה';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return 'PR גדול — $files, שקלו לפצל לפני הסקירה';
  }

  @override
  String get searchInFiles => 'חיפוש בקבצים';

  @override
  String get showFileList => 'הצגת רשימת הקבצים';

  @override
  String get searchInFilesHintField => 'חיפוש בקבצים…';

  @override
  String get searchInFilesHint => 'חיפוש בכל קובצי בקשת המשיכה';

  @override
  String get searchInWholeRepo => 'חיפוש בכל המאגר';

  @override
  String get searchInThisPullRequest => 'חיפוש בבקשת המשיכה הזו';

  @override
  String get searchNoResults => 'לא נמצאו תוצאות';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count תוצאות',
      many: '$count תוצאות',
      two: 'שתי תוצאות',
      one: 'תוצאה אחת',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files קבצים',
      many: '$files קבצים',
      two: 'שני קבצים',
      one: 'קובץ אחד',
    );
    return '$_temp0 בתוך $_temp1';
  }

  @override
  String get discardChangesTitle => 'לבטל את השינויים?';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'לבטל את השינויים ב-$count קבצים ולחזור ל-HEAD?',
      many: 'לבטל את השינויים ב-$count קבצים ולחזור ל-HEAD?',
      two: 'לבטל את השינויים בשני קבצים ולחזור ל-HEAD?',
      one: 'לבטל את השינויים בקובץ אחד ולחזור ל-HEAD?',
    );
    return '$_temp0 לא ניתן לבטל פעולה זו.';
  }

  @override
  String get discardAll => 'ביטול הכול';

  @override
  String get discardFailed => 'ביטול השינויים נכשל';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'השינויים ב-$count קבצים בוטלו',
      many: 'השינויים ב-$count קבצים בוטלו',
      two: 'השינויים בשני קבצים בוטלו',
      one: 'השינויים בקובץ אחד בוטלו',
    );
    return '$_temp0';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: 'השינויים ב-$reverted קבצים בוטלו',
      many: 'השינויים ב-$reverted קבצים בוטלו',
      two: 'השינויים בשני קבצים בוטלו',
      one: 'השינויים בקובץ אחד בוטלו',
    );
    return '$_temp0; $skipped דולגו (לא במעקב)';
  }

  @override
  String get prWorktreeUnavailable => 'סביבת העבודה אינה מוכנה';

  @override
  String get prWorktreeUnavailableHint =>
      'הכנת הקבצים של בקשת המשיכה נכשלה. פתחו מחדש את בקשת המשיכה כדי לנסות שוב.';

  @override
  String get timestampRelativeLabel => 'יחסי';

  @override
  String get timestampRawLabel => 'חותמת זמן';

  @override
  String get copyTimestamp => 'העתקת חותמת זמן';

  @override
  String get copiedTimestamp => 'חותמת הזמן הועתקה';

  @override
  String get previewDeployment => 'תצוגה מקדימה של פריסה';

  @override
  String previewDeploymentTab(String site) {
    return 'תצוגה מקדימה: ⁨$site⁩';
  }

  @override
  String get askForReview => 'בקשת סקירה…';

  @override
  String get closePrsConfirmTitle => 'לסגור בקשות משיכה?';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'לסגור $count בקשות משיכה?',
      many: 'לסגור $count בקשות משיכה?',
      two: 'לסגור שתי בקשות משיכה?',
      one: 'לסגור בקשת משיכה אחת?',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'נסגרו $count בקשות משיכה',
      many: 'נסגרו $count בקשות משיכה',
      two: 'נסגרו שתי בקשות משיכה',
      one: 'נסגרה בקשת משיכה אחת',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'הוקצו $count בקשות משיכה',
      many: 'הוקצו $count בקשות משיכה',
      two: 'הוקצו שתי בקשות משיכה',
      one: 'הוקצתה בקשת משיכה אחת',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'התבקשה סקירה על $count בקשות משיכה',
      many: 'התבקשה סקירה על $count בקשות משיכה',
      two: 'התבקשה סקירה על שתי בקשות משיכה',
      one: 'התבקשה סקירה על בקשת משיכה אחת',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count פעולות נכשלו',
      many: '$count פעולות נכשלו',
      two: 'שתי פעולות נכשלו',
      one: 'פעולה אחת נכשלה',
    );
    return '$_temp0';
  }

  @override
  String get diagram => 'תרשים';

  @override
  String get diagramViewSource => 'הצגת המקור';

  @override
  String get diagramHideSource => 'הסתרת המקור';

  @override
  String diagramPreviewUnavailable(String reason) {
    return 'תצוגה מקדימה של התרשים אינה זמינה (⁨$reason⁩)';
  }

  @override
  String get planUnavailable => 'התוכנית אינה זמינה';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count שלבים',
      many: '$count שלבים',
      two: 'שני שלבים',
      one: 'שלב אחד',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => 'אישור והרצה';

  @override
  String get planStatusDraft => 'טיוטה';

  @override
  String get planStatusProposed => 'תוכנית';

  @override
  String get planStatusApproved => 'התוכנית אושרה';

  @override
  String get planStatusRejected => 'התוכנית נדחתה';

  @override
  String get planStatusSuperseded => 'התוכנית הוחלפה';

  @override
  String planRevisionLabel(int revision) {
    return 'גרסה $revision';
  }

  @override
  String get adapterEnforcementTitle => 'מה המתאם הזה אוכף';

  @override
  String get enforcementFiltersToolSurface => 'Control Center בוחר את הכלים';

  @override
  String get enforcementInterceptsToolCalls =>
      'כל קריאה עוברת שער לפני שהיא רצה';

  @override
  String get enforcementObservesCompletionContract => 'ההרצה מחויבת לתוצר שלה';

  @override
  String get enforcementNativeToolsInterceptable =>
      'הכלים המובנים של מנוע ההרצה גלויים';

  @override
  String get enforcementInProcessToolsSandboxed =>
      'כלים בתוך התהליך רצים בארגז חול';

  @override
  String get enforcementYes => 'כן';

  @override
  String get enforcementNo => 'לא';

  @override
  String get adapterEnforcementCaveats => 'הסתייגויות';

  @override
  String get enforcementSummaryModesEnforced => 'מצבים נאכפים';

  @override
  String get enforcementSummaryModesNotEnforced => 'מצבים לא נאכפים';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count הסתייגויות',
      many: '$count הסתייגויות',
      two: 'שתי הסתייגויות',
      one: 'הסתייגות אחת',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      'מצבי קריאה בלבד אינם מובְנים: Control Center אינו יכול להסיר את הכלים המובנים של מנוע ההרצה הזה.';

  @override
  String get caveatToolCallsNotIntercepted =>
      'אין שער לפני ביצוע: רק קריאות לכלי MCP עוברות דרך Control Center.';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      'כלי הקבצים והמעטפת המובנים של מנוע ההרצה לעולם אינם מגיעים אל Control Center; ארגז החול של מערכת ההפעלה הוא הרצפה היחידה מתחתיהם.';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      'כלי קבצים בתוך התהליך רצים מחוץ לארגז החול, ולכן משטח הכלים הוא הגבול היחיד למערכת הקבצים.';

  @override
  String get caveatCompletionContractUnobservable =>
      'Control Center אינו יכול לדרבן או להכשיל הרצה שמסתיימת בלי להפיק את התוצר שלה.';

  @override
  String get modeDegraded => 'מופחת';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return 'מצב $mode על ⁨$adapter⁩ מסתמך על ארגז החול בלבד; כלי הקבצים של הסוכן עצמו אינם מיורטים.';
  }

  @override
  String get artifactUnavailable => 'התוצר אינו זמין';

  @override
  String artifactRevisionLabel(int count) {
    return '$count גרסאות';
  }

  @override
  String get artifactShowMore => 'הצגת עוד';

  @override
  String get artifactShowLess => 'הצגת פחות';

  @override
  String get artifactCopy => 'העתקה';

  @override
  String get artifactCopied => 'התוצר הועתק';

  @override
  String get artifactsTabLabel => 'תוצרים';

  @override
  String get artifactsEmptyTitle => 'אין תוצרים עדיין';

  @override
  String get artifactsEmptyBody =>
      'כשסוכן מפרסם כאן טבלה, תרשים או דיאגרמה, הם מופיעים ברשימה הזו.';

  @override
  String get artifactRevisionPickerLabel => 'גרסה';

  @override
  String get artifactRestoreRevision => 'שחזור הגרסה הזו';

  @override
  String get artifactOpenInTab => 'פתיחה בכרטיסייה';

  @override
  String get artifactTitleFallback => 'תוצר';

  @override
  String get providerGenerationLabel => 'ברירות מחדל ליצירה';

  @override
  String get providerGenerationHint =>
      'השאירו שדה ריק כדי להשתמש בברירת המחדל של נקודת הקצה עצמה. מודלים מפרסמים תקרות פלט ומתכוני דגימה משלהם; הגשת מודל בערכים אחרים עלולה לפגוע בו.';

  @override
  String get providerMaxTokensLabel => 'מקסימום אסימוני פלט';

  @override
  String get addModel => 'הוספת מודל';

  @override
  String get modelListTitle => 'רשימת מודלים';

  @override
  String get railProvidersGroup => 'ספקים';

  @override
  String get railCustomProvidersGroup => 'ספקים מותאמים אישית';

  @override
  String get editModelSettings => 'עריכת הגדרות המודל';

  @override
  String get modelIdLabel => 'מזהה מודל';

  @override
  String get modelIdImmutableHint =>
      'המזהה שנקודת הקצה משרתת; קבוע מרגע שנוסף לרשימה.';

  @override
  String get contextWindowLabel => 'חלון הקשר';

  @override
  String get inputTypesLabel => 'סוגי קלט';

  @override
  String get outputTypesLabel => 'סוגי פלט';

  @override
  String get modalityText => 'טקסט';

  @override
  String get modalityImage => 'תמונה';

  @override
  String get modalityAudio => 'שמע';

  @override
  String get modalityVideo => 'וידאו';

  @override
  String get modalityPdf => 'PDF';

  @override
  String get modelOverrideReset => 'איפוס לאוטומטי';

  @override
  String get modelOverrideEdited => 'נערך';

  @override
  String get manualModelBadge => 'נוסף ידנית';

  @override
  String get modelIdRequired => 'יש להזין מזהה מודל.';

  @override
  String get modelTokensInvalid => 'יש להזין מספר שלם וחיובי של אסימונים.';

  @override
  String get removeModelAction => 'הסרת המודל';

  @override
  String removeModelConfirmTitle(String model) {
    return 'להסיר את ⁨$model⁩?';
  }

  @override
  String get removeModelConfirmBody =>
      'המודל יוסר מהרשימה וסוכנים המוצמדים אליו יפסיקו לעבוד. הספק אינו מושפע.';

  @override
  String get addModelProviderTitle => 'הוספת ספק מודלים';

  @override
  String get addModelProviderDescription =>
      'הגדרת נקודת קצה API מותאמת אישית והמודלים שלה.';

  @override
  String get modelListEmptyHint =>
      'לא הוגדרו מודלים. הוסיפו מודל כדי להשתמש בו בצ\'אט.';

  @override
  String get addProviderModelsHint =>
      'המודלים נשלפים בזמן אמת ברגע שנקודת הקצה עונה. הוסיפו מודל ידנית רק אם היא אינה מסוגלת לפרסם רשימה משלה.';

  @override
  String get providerTemperatureLabel => 'טמפרטורה';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved => 'ברירות המחדל ליצירה נשמרו';

  @override
  String get providerGenerationInvalid =>
      'בדקו את הערכים: מקסימום אסימוני פלט ו-Top-k חייבים להיות חיוביים, טמפרטורה בין 0 ל-2 ו-Top-p בין 0 ל-1.';

  @override
  String get providerGenerationOverridden => 'נדרס';

  @override
  String get branchNotPushed => 'לא נדחף';

  @override
  String branchNotOnRemote(String branch) {
    return '\"⁨$branch⁩\" קיים רק בשיחה הזו';
  }

  @override
  String get branchNotOnRemoteHint =>
      'GitHub מעולם לא ראה את הענף הזה, ולכן בקשת משיכה עדיין לא יכולה להשתמש בו. פרסום דוחף את הקומיטים שכבר נמצאים בעץ העבודה — שינויים ללא קומיט נשארים במקומם.';

  @override
  String get publishBranch => 'פרסום הענף';

  @override
  String branchPublished(String branch) {
    return 'הענף \"⁨$branch⁩\" פורסם אל ⁨origin⁩';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return 'הענף פורסם. $count שינויים ללא קומיט לא נכללו.';
  }

  @override
  String get composePrLoadingBranches => 'טוען ענפים מ-GitHub…';

  @override
  String get composePrBranchesFailed =>
      'לא ניתן לטעון ענפים מ-GitHub. הקלידו שם ענף, או בדקו את החיבור ל-GitHub.';

  @override
  String get composePrSubtitleFromSpace =>
      'מהענף של השיחה הזו — פרסמו אותו קודם אם GitHub עדיין לא ראה אותו';

  @override
  String get obsTabInsights => 'תובנות';

  @override
  String get obsTabLive => 'בזמן אמת';

  @override
  String get obsTabQuality => 'איכות';

  @override
  String get obsTabUsage => 'שימוש';

  @override
  String get obsUsageTotalTokens => 'סך אסימונים';

  @override
  String get obsUsagePeakTokens => 'שיא אסימונים';

  @override
  String get obsUsageLongestSession => 'הסשן הארוך ביותר';

  @override
  String get obsUsageCurrentStreak => 'רצף נוכחי';

  @override
  String get obsUsageLongestStreak => 'הרצף הארוך ביותר';

  @override
  String obsUsageDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ימים',
      many: '$count ימים',
      two: 'יומיים',
      one: 'יום אחד',
      zero: '0 ימים',
    );
    return '$_temp0';
  }

  @override
  String get obsUsageTokenActivity => 'פעילות אסימונים';

  @override
  String get obsUsageActivityModeLabel => 'מצב פעילות האסימונים';

  @override
  String get obsUsageModeDaily => 'יומי';

  @override
  String get obsUsageModeWeekly => 'שבועי';

  @override
  String get obsUsageModeCumulative => 'מצטבר';

  @override
  String get obsUsageTimeRange => 'טווח זמן';

  @override
  String get obsUsageTrendTitle => 'מגמת אסימונים יומית';

  @override
  String get obsUsageModelUsage => 'שימוש במודלים';

  @override
  String get obsUsageTokensLabel => 'אסימונים';

  @override
  String get obsUsageNoActivity => 'עדיין לא נרשם שימוש באסימונים';

  @override
  String get obsUsageOtherModels => 'אחר';

  @override
  String obsUsageCellReadout(String date, String tokens) {
    return '$date · $tokens אסימונים';
  }

  @override
  String obsUsageActivitySummary(
    String start,
    String end,
    int activeDays,
    String peak,
  ) {
    return 'פעילות אסימונים מ-$start עד $end. $activeDays ימים פעילים. היום העמוס ביותר: $peak אסימונים.';
  }

  @override
  String get obsScreenSubtitle =>
      'שליטה חיה בסוכנים, שיוך עלויות, מכסות ואותות איכות';

  @override
  String get obsRangeLast24h => '24 השעות האחרונות';

  @override
  String get obsRangeLast7d => '7 הימים האחרונים';

  @override
  String get obsRangeLast30d => '30 הימים האחרונים';

  @override
  String get obsRangeAll => 'כל הזמן';

  @override
  String get obsAddFilter => 'הוספת מסנן';

  @override
  String get obsFilterAgent => 'סוכן';

  @override
  String get obsFilterModel => 'מודל';

  @override
  String get obsFilterStatus => 'סטטוס';

  @override
  String get obsFilterRole => 'תפקיד';

  @override
  String get obsKpiTotalRuns => 'סך הרצות';

  @override
  String get obsKpiTotalCost => 'עלות כוללת';

  @override
  String get obsKpiErrorRate => 'שיעור שגיאות';

  @override
  String get obsKpiCacheRate => 'שיעור מטמון';

  @override
  String get obsKpiTokensPerSec => 'אסימונים / שנייה';

  @override
  String get obsKpiAvgLatency => 'השהיה ממוצעת';

  @override
  String get obsKpiTtft => 'זמן עד האסימון הראשון';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '⁨$delta⁩ לעומת התקופה הקודמת';
  }

  @override
  String get obsChartActivity => 'פעילות';

  @override
  String get obsChartCost => 'עלות לאורך זמן';

  @override
  String get obsLegendRuns => 'הרצות';

  @override
  String get obsLegendErrors => 'שגיאות';

  @override
  String get obsAgentsTitle => 'סוכנים';

  @override
  String obsShowAllAgents(int count) {
    return 'הצגת כל $count הסוכנים';
  }

  @override
  String get obsShowFewerAgents => 'הצגת פחות';

  @override
  String get obsRunsTitle => 'הרצות';

  @override
  String get obsNoRunsInRange => 'אין הרצות בטווח הזה';

  @override
  String get obsColTime => 'זמן';

  @override
  String get obsColAgent => 'סוכן';

  @override
  String get obsColStatus => 'סטטוס';

  @override
  String get obsColModel => 'מודל';

  @override
  String get obsColDuration => 'משך';

  @override
  String get obsColTokens => 'אסימונים';

  @override
  String get obsColCost => 'עלות';

  @override
  String get obsColErrors => 'שגיאות';

  @override
  String get obsColRuns => 'הרצות';

  @override
  String get obsColAvgLatency => 'השהיה ממוצעת';

  @override
  String get obsColLastActive => 'פעילות אחרונה';

  @override
  String get obsStatusPending => 'ממתין';

  @override
  String get obsStatusRunning => 'רץ';

  @override
  String get obsStatusCompleted => 'הושלם';

  @override
  String get obsStatusError => 'שגיאה';

  @override
  String get obsRosterLoadError => 'לא ניתן לטעון את רשימת הסוכנים.';

  @override
  String get obsRosterEmpty => 'אין סוכנים עדיין';

  @override
  String get obsRosterEmptyDescription =>
      'שגרו סוכן והוא יופיע כאן בזמן אמת — סטטוס, הכלי הנוכחי, אסימונים, עלות.';

  @override
  String get obsKillAgent => 'עצירת הסוכן';

  @override
  String get obsRosterTokensLabel => 'אסימ\'';

  @override
  String get obsCostByRoleTitle => 'עלות לפי תפקיד';

  @override
  String get obsCostByRoleSubtitle =>
      'על מה סביבת העבודה הזו מוציאה, לפי תפקיד סוכן';

  @override
  String get obsRoleMain => 'ראשי';

  @override
  String get obsRoleSubagents => 'תתי-סוכנים';

  @override
  String get obsRoleAdvisor => 'יועץ';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return 'ראשי: $main · תתי-סוכנים: $sub · יועץ: $advisor';
  }

  @override
  String get obsTotal => 'סה״כ';

  @override
  String get obsTokenModelTitle => 'מודל האסימונים (5 צירים)';

  @override
  String get obsTokenModelSubtitle =>
      'כל אסימון שסביבת העבודה הזו צרכה, לפי ציר';

  @override
  String get obsAxisInput => 'קלט';

  @override
  String get obsAxisOutput => 'פלט';

  @override
  String get obsAxisReasoning => 'חשיבה';

  @override
  String get obsAxisCacheRead => 'קריאת מטמון';

  @override
  String get obsAxisCacheWrite => 'כתיבת מטמון';

  @override
  String get obsTotalTokens => 'סך אסימונים';

  @override
  String get obsCacheDiscountNote =>
      'אסימוני קריאה מהמטמון מחויבים בהנחה, ולכן עלותם נמוכה בהרבה מאותו נפח של קלט טרי.';

  @override
  String get obsByModelTitle => 'לפי מודל';

  @override
  String get obsByModelSubtitle => 'שימוש באסימונים ועלות לפי מודל';

  @override
  String get obsNoModelUsage => 'עדיין לא נרשם שימוש במודלים.';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count הרצות',
      many: '$count הרצות',
      two: 'שתי הרצות',
      one: 'הרצה אחת',
    );
    return '$_temp0';
  }

  @override
  String get obsPerRunTitle => 'לכל הרצה';

  @override
  String get obsPerRunSubtitle => 'עלות אסימונים טיפוסית של הרצה בודדת';

  @override
  String get obsMedianRunTokens => 'חציון אסימונים להרצה';

  @override
  String get obsMedianRunTokensSub => 'נקודת האמצע על פני כל ההרצות';

  @override
  String get obsRunsInWorkspace => 'בסביבת העבודה הזו';

  @override
  String get obsCostShare => 'נתח עלות';

  @override
  String get obsQuotaConfiguredLimits => 'מגבלות מוגדרות';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      'השימוש ביחס לתקרות שהגדרתם, הסטטוס החמור ביותר תחילה.';

  @override
  String get obsQuotaAddLimit => 'הוספת מגבלה';

  @override
  String get obsQuotaNoLimits =>
      'עדיין לא הוגדרו מגבלות מכסה — הוסיפו אחת כדי לעקוב אחרי השימוש ביחס לתקרה.';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return 'הסרת המגבלה $title';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return 'מתאפס בעוד $duration · $status';
  }

  @override
  String get obsQuotaUsageWindows => 'חלונות שימוש';

  @override
  String get obsQuotaUsageWindowsSubtitle =>
      'שימוש שנצפה בכל הספקים, ללא החלת תקרה.';

  @override
  String get obsQuotaNoUsage => 'עדיין לא נרשם שימוש.';

  @override
  String get obsQuotaTokensUsed => 'אסימונים בשימוש';

  @override
  String get obsQuotaRequests => 'בקשות';

  @override
  String get obsQuotaUnitTokens => 'אסימונים';

  @override
  String get obsQuotaUnitRequests => 'בקשות';

  @override
  String get obsQuotaUnitCost => 'עלות';

  @override
  String get obsQuotaAddLimitTitle => 'הוספת מגבלת מכסה';

  @override
  String get obsQuotaProviderLabel => 'ספק';

  @override
  String get obsQuotaWindowLabel => 'חלון';

  @override
  String get obsQuotaUnitLabel => 'יחידה';

  @override
  String obsQuotaLimitLabel(String unit) {
    return 'מגבלה ($unit)';
  }

  @override
  String get obsQuotaCentsHint => 'בסנטים אמריקאיים (500 = ⁨\$5.00⁩).';

  @override
  String get obsQuotaStatusOk => 'תקין';

  @override
  String get obsQuotaStatusWarning => 'אזהרה';

  @override
  String get obsQuotaStatusExhausted => 'מוצה';

  @override
  String get obsQuotaStatusUnknown => 'לא ידוע';

  @override
  String get obsGoalNoActiveTitle => 'אין יעד פעיל';

  @override
  String get obsGoalNoActiveBody =>
      'הגדירו יעד כדי לתת לסוכנים מטרה ותקציב אסימונים אופציונלי. ככל שהרצות מושלמות התקציב מתמלא, וכשהוא כמעט מוצה הסוכנים מקבלים דחיפה לסיים.';

  @override
  String get obsGoalSetGoal => 'הגדרת יעד';

  @override
  String get obsGoalTokenBudget => 'תקציב אסימונים';

  @override
  String obsGoalTokensLeft(String tokens) {
    return '$tokens נותרו';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens (לא הוגדר תקציב)';
  }

  @override
  String get obsGoalTokensUsed => 'אסימונים בשימוש';

  @override
  String get obsGoalElapsed => 'זמן שחלף';

  @override
  String get obsGoalWrapUp => 'סיום מסודר';

  @override
  String get obsGoalClear => 'ניקוי היעד';

  @override
  String get obsGoalFallbackTitle => 'יעד';

  @override
  String get obsGoalSubtitle => 'תקציב מצב היעד';

  @override
  String get obsGoalStatusActive => 'פעיל';

  @override
  String get obsGoalStatusPaused => 'מושהה';

  @override
  String get obsGoalStatusBudgetLimited => 'מוגבל בתקציב';

  @override
  String get obsGoalStatusComplete => 'הושלם';

  @override
  String get obsGoalStatusDropped => 'נזנח';

  @override
  String get obsGoalObjectiveLabel => 'מטרה';

  @override
  String get obsGoalBudgetLabel => 'תקציב אסימונים (אופציונלי)';

  @override
  String get obsGoalSetAction => 'הגדרת יעד';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => '% הצלחה';

  @override
  String get obsBenchmarkPassed => 'עברו';

  @override
  String get obsBenchmarkFailed => 'נכשלו';

  @override
  String get obsBenchmarkErrors => 'שגיאות';

  @override
  String get obsBenchmarkSpend => 'הוצאה';

  @override
  String get obsBenchmarkCostPerTask => 'עלות / משימה';

  @override
  String get obsBenchmarkTrials => 'ניסיונות';

  @override
  String get obsBenchmarkNoTrials => 'אין עדיין הרצות לניקוד.';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ועוד $count',
      many: 'ועוד $count',
      two: 'ועוד שניים',
      one: 'ועוד אחד',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => 'עבר';

  @override
  String get obsBenchmarkTrialFail => 'נכשל';

  @override
  String get obsBenchmarkTrialError => 'שגיאה';

  @override
  String get obsBenchmarkTrialRunning => 'רץ';

  @override
  String get obsBenchmarkReward => 'תגמול';

  @override
  String get obsBenchmarkReport => 'דוח';

  @override
  String get obsBenchmarkCopyMarkdown => 'העתקת Markdown';

  @override
  String get obsBenchmarkCopied => 'הדוח הועתק ללוח';

  @override
  String get obsBehaviorCaption =>
      'אלה אותות תסכול המזוהים מתוך ההודעות שלכם — קריאת מצב על בריאות השיחה, לא ציון לסוכנים. מחושב מקומית; שום דבר לא עוזב את המכשיר הזה.';

  @override
  String get obsBehaviorMessagesAnalyzed => 'הודעות שנותחו';

  @override
  String get obsBehaviorTotalSignals => 'סך אותות';

  @override
  String get obsBehaviorYelling => 'צעקות';

  @override
  String get obsBehaviorProfanity => 'קללות';

  @override
  String get obsBehaviorAnguish => 'ייאוש';

  @override
  String get obsBehaviorNegation => 'שלילה';

  @override
  String get obsBehaviorRepetition => 'חזרתיות';

  @override
  String get obsBehaviorBlame => 'האשמה';

  @override
  String get obsBehaviorConversationsTitle => 'השיחות המתסכלות ביותר';

  @override
  String get obsBehaviorConversationsSubtitle =>
      'מדורגות לפי צפיפות האותות בהודעות שלכם.';

  @override
  String get obsBehaviorNoSignals => 'לא זוהו אותות תסכול — הכול זורם.';

  @override
  String obsBehaviorMessagesCount(String count) {
    return '$count הודעות נותחו';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '$count אותות';
  }

  @override
  String get obsAgentStatusIdle => 'לא פעיל';

  @override
  String get obsAgentStatusParked => 'חונה';

  @override
  String get obsAgentStatusAborted => 'הופסק';

  @override
  String get obsAgentKindSub => 'תת';

  @override
  String get noChecksOnCommit => 'לא רצו בדיקות על הקומיט הזה.';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'בריצה — $count משימות',
      many: 'בריצה — $count משימות',
      two: 'בריצה — שתי משימות',
      one: 'בריצה — משימה אחת',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'כל הבדיקות עברו — $count משימות',
      many: 'כל הבדיקות עברו — $count משימות',
      two: 'כל הבדיקות עברו — שתי משימות',
      one: 'כל הבדיקות עברו — משימה אחת',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'הושלם — $count משימות',
      many: 'הושלם — $count משימות',
      two: 'הושלם — שתי משימות',
      one: 'הושלם — משימה אחת',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total משימות',
      many: '$total משימות',
      two: 'שתי משימות',
      one: 'משימה אחת',
    );
    return '$failed מתוך $_temp0 נכשלו';
  }

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count משימות',
      many: '$count משימות',
      two: 'שתי משימות',
      one: 'משימה אחת',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return 'מטריצה: ⁨$jobId⁩';
  }

  @override
  String get jobLogsPending => 'הלוגים יופיעו כאן כשהמשימה תסתיים.';

  @override
  String get jobLogsUnavailable => 'אין לוגים זמינים למשימה הזו.';

  @override
  String get noLogsForStep => 'לא נקלטו לוגים לשלב הזה.';

  @override
  String get jobLogsTruncated => 'הלוג קוצץ — מוצג הפלט העדכני ביותר.';

  @override
  String get fullLog => 'לוג מלא';

  @override
  String get copyLogs => 'העתקת לוגים';

  @override
  String get resizeGraph => 'גרירה לשינוי גודל הגרף';

  @override
  String workflowRunStartedAgo(String time) {
    return 'התחיל $time';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return 'הסתיים $time';
  }

  @override
  String get chatBridgesTitle => 'גשרי צ\'אט';

  @override
  String chatProviderDescription(String provider, String command) {
    return 'אזכרו את הבוט ב-$provider כדי להעמיד סוכן על משימה, או פתחו כרטיסים עם ⁨$command⁩.';
  }

  @override
  String chatConnectProvider(String provider) {
    return 'חיבור $provider';
  }

  @override
  String get chatDisconnectProvider => 'ניתוק';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$botName ב-$teamName';
  }

  @override
  String get chatStateLive => 'פעיל';

  @override
  String get chatStateConnecting => 'מתחבר…';

  @override
  String get chatStateError => 'שגיאת חיבור';

  @override
  String get chatNotConnected => 'לא מחובר';

  @override
  String chatStreamingUnavailable(String provider) {
    return 'הזרמה חיה כבויה לאפליקציית ה-$provider הזו — תשובות מגיעות כהודעה אחת.';
  }

  @override
  String chatAdminOnly(String provider) {
    return 'רק מנהל יכול לחבר את $provider לסביבת העבודה הזו.';
  }

  @override
  String chatConnectHint(String provider) {
    return 'צרו אפליקציית $provider, ואז הדביקו כאן את פרטי הגישה שלה. Control Center מתחבר החוצה אל $provider, כך שהשרת הזה אינו זקוק לכתובת ציבורית.';
  }

  @override
  String chatOpenConsole(String provider) {
    return 'פתיחת מסוף $provider';
  }

  @override
  String get chatOpenSetupGuide => 'מדריך הקמה';

  @override
  String get chatFieldBotToken => 'אסימון גישה של הבוט';

  @override
  String get chatFieldAppToken => 'אסימון גישה ברמת האפליקציה';

  @override
  String get chatFieldConfigRefreshToken => 'אסימון גישה לתצורת האפליקציה';

  @override
  String chatFieldOptional(String label) {
    return '$label (אופציונלי)';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return 'קישור חשבון ה-$provider שלי';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return 'קשרו את חשבון ה-$provider שלכם כדי שהודעות שתשלחו שם ישויכו אליכם.';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return 'מקושר אל ⁨$externalUserId⁩';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return 'קישור חשבון ה-$provider שלכם';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return 'שלחו את הפקודה הזו לבוט ב-$provider. היא עובדת פעם אחת ופגה בתוך 15 דקות.';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return 'חשבון ה-$provider שלכם מקושר עכשיו — הודעות שתשלחו שם ישויכו אליכם.';
  }

  @override
  String get chatLinkedAccounts => 'חשבונות מקושרים';

  @override
  String chatNoLinkedAccounts(String provider) {
    return 'אף אחד עדיין לא קישר את חשבון ה-$provider שלו.';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count חשבונות מקושרים',
      many: '$count חשבונות מקושרים',
      two: 'שני חשבונות מקושרים',
      one: 'חשבון מקושר אחד',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '⁨$externalUserId⁩ · הותאם לפי אימייל';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '⁨$externalUserId⁩ · קושר באמצעות קוד';
  }

  @override
  String get chatUnlink => 'ביטול קישור';

  @override
  String get chatCustomizeBot => 'התאמת הבוט';

  @override
  String get chatCustomizeBotDescription =>
      'שינוי שם הבוט, מה שהוא מספר על עצמו, או שם פקודת הסלאש.';

  @override
  String get chatCustomizeBotUnavailable =>
      'Control Center זקוק לאסימון גישה לתצורת האפליקציה כדי לערוך את הבוט. התחברו מחדש וצרפו אחד.';

  @override
  String chatCreateAppTitle(String provider) {
    return 'יצירת אפליקציית $provider';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'Control Center יכול ליצור עבורכם את אפליקציית ה-$provider, עם ההרשאות והאירועים הנכונים כבר מוגדרים. תסיימו בתוך $provider, ואז תדביקו כאן את פרטי הגישה.';
  }

  @override
  String get chatCreateApp => 'יצירת אפליקציה';

  @override
  String get chatCreateAppCta => 'יצירת האפליקציה עבורי';

  @override
  String get chatAppNameLabel => 'שם האפליקציה';

  @override
  String get chatBotDisplayNameLabel => 'שם הבוט (מה שחברים מקלידים אחרי @)';

  @override
  String get chatDescriptionLabel => 'תיאור קצר';

  @override
  String get chatAgentDescriptionLabel => 'מה הבוט אומר שהוא יודע לעשות';

  @override
  String get chatCommandLabel => 'פקודת סלאש';

  @override
  String get chatDirectMessages => 'הודעות ישירות';

  @override
  String chatDirectMessagesHint(String provider) {
    return 'מאפשר לחברים לשוחח עם הבוט בהודעה ישירה. עשוי לדרוש תוכנית $provider בתשלום.';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return '$provider יצר את האפליקציה ⁨$appId⁩.';
  }

  @override
  String chatRemainingSteps(String provider) {
    return 'נותרו כמה שלבים שרק $provider יכול לבצע:';
  }

  @override
  String get chatStepAppToken => 'יצירת אסימון גישה ברמת האפליקציה';

  @override
  String get chatStepInstall => 'התקנת האפליקציה';

  @override
  String get chatOpenAppSettings => 'פתיחת הגדרות האפליקציה';

  @override
  String get chatContinueToCredentials => 'הדבקת פרטי הגישה';

  @override
  String chatBotUpdated(String provider) {
    return 'הבוט עודכן ב-$provider.';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return '$provider שינה את הרשאות האפליקציה. התקינו אותה מחדש כדי שההרשאות ייכנסו לתוקף.';
  }

  @override
  String get chatReinstallApp => 'התקנת האפליקציה מחדש';

  @override
  String chatIconNotEditable(String provider) {
    return 'את סמל הבוט אפשר לשנות רק בהגדרות האפליקציה של $provider עצמו.';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return 'אפשר גם ליצור אותה בעצמכם ב-$provider — ללא צורך באסימון גישה. ההגדרות שלמעלה עוברות יחד עם הקישור.';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return 'יצירה ב-$provider';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return '$provider נפתח בדפדפן שלכם עם התצורה הזו ממולאת מראש. צרו שם את האפליקציה, אחר כך השלימו את השלבים האלה וחזרו עם אסימוני הגישה.';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return '$provider אינו מדווח איזו אפליקציה נוצרה, ולכן התאמת הבוט מכאן תדרוש בהמשך אסימון גישה לתצורת האפליקציה.';
  }

  @override
  String get chatStepCreateApp => 'יצירת האפליקציה מהתצורה הממולאת מראש';

  @override
  String chatStepCreateAppHint(String provider) {
    return 'בחרו סביבת עבודה ב-$provider ואשרו.';
  }

  @override
  String get chatStepAppTokenHint =>
      'בתוך ⁨Basic information⁩, תחת ⁨App-level tokens⁩, עם ההרשאה ⁨connections:write⁩.';

  @override
  String get chatStepInstallHint =>
      'בעמוד ⁨Install app⁩, העתיקו את אסימון ה-OAuth של משתמש הבוט.';

  @override
  String get calendarUseBuiltinApp =>
      'שימוש באפליקציית ה-Google של Control Center';

  @override
  String get calendarUseBuiltinAppHint =>
      'אשרו עם חשבון ה-Google שלכם. אין מה להגדיר ב-Google Cloud.';

  @override
  String get calendarUseOwnClient => 'שימוש בלקוח Google Cloud משלי';

  @override
  String get calendarUseOwnClientHint =>
      'הזינו לקוח OAuth מפרויקט Google Cloud משלכם.';

  @override
  String get aboutTitle => 'אודות';

  @override
  String get aboutAppVersion => 'גרסת האפליקציה';

  @override
  String get aboutServerVersion => 'השרת המחובר';

  @override
  String get aboutRpcCatalog => 'קטלוג RPC';

  @override
  String get aboutServerUnknown => 'לא דווח';

  @override
  String get serverStaleTitle => 'השרת המצורף ישן יותר מהאפליקציה הזו';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return 'ה-⁨cc_server⁩ שרץ הוא בגרסה ⁨$serverVersion⁩ בעוד שהאפליקציה בגרסה ⁨$appVersion⁩. הפעילו מחדש את האפליקציה כדי שתטען את גרסת השרת המצורפת העדכנית; בפיתוח, בנו אותו מחדש עם ⁨`dart build cli`⁩ בתוך ⁨apps/cc_server⁩.';
  }

  @override
  String get updateCheckButton => 'בדיקת עדכונים';

  @override
  String get updateChecking => 'בודק עדכונים…';

  @override
  String get updateUpToDate => 'אתם מעודכנים';

  @override
  String get updateDeferredBusy =>
      'עדכון מוכן, אבל פגישה מוקלטת כרגע — הוא יוצע אחרי שהיא תסתיים.';

  @override
  String get updateOpenedReleasesPage => 'דף הגרסאות נפתח בדפדפן שלכם.';

  @override
  String get updateCheckFailed => 'בדיקת העדכונים נכשלה';

  @override
  String updateAvailableVersion(String version) {
    return 'גרסה ⁨$version⁩ זמינה.';
  }

  @override
  String get updateBannerTitle => 'גרסה חדשה של Control Center זמינה';

  @override
  String get updateBannerRefresh => 'רענון';

  @override
  String get updateBlockedRecording =>
      'הרענון מושהה בזמן שפגישה מוקלטת — הוא יתבצע כשהיא תסתיים.';

  @override
  String get settingsScopeYou => 'אישי';

  @override
  String get settingsScopeWorkspace => 'סביבת עבודה';

  @override
  String get settingsScopeServer => 'שרת';

  @override
  String get settingsProfile => 'פרופיל וזהות';

  @override
  String get settingsYourDevices => 'המכשירים שלכם';

  @override
  String get settingsWorkspaceGeneral => 'כללי';

  @override
  String get settingsServerConnection => 'חיבור וסטטוס';

  @override
  String get settingsModelProviders => 'ספקי מודלים';

  @override
  String get settingsVoiceModels => 'מודלי קול ופגישות';

  @override
  String get settingsDiagnostics => 'אבחון ופרטיות';

  @override
  String get settingsAbout => 'אודות';

  @override
  String get settingsScopeBadgeYou => 'אישי';

  @override
  String get settingsScopeBadgeDevice => 'המכשיר הזה';

  @override
  String get settingsScopeBadgeWorkspace => 'סביבת עבודה';

  @override
  String get settingsScopeBadgeServer => 'שרת';

  @override
  String get settingsProfileDescription =>
      'השם, האימייל וזהות git שלך במרחב הזה. החלפת מרחב מחליפה את השכבה; הכינוי, הכניסה והמכשירים נשארים בחשבון.';

  @override
  String get settingsServerConnectionDescription =>
      'עם איזה שרת הלקוח הזה מדבר, ואיך השרת משותף (mDNS, מנהרות, ממסר).';

  @override
  String get settingsAboutDescription => 'זהות הגרסה ועדכונים.';

  @override
  String get settingsDiagnosticsDescription =>
      'בידוד, אינדוקס, סנכרון, רישום לוגים ודיווחי קריסות להתקנה הזו.';

  @override
  String get settingsWorkspaceGeneralDescription =>
      'זהות, מדיניות ומוסכמות המשותפות לכולם בסביבת העבודה הזו.';

  @override
  String get settingsWorkspaceMeetingsDescription =>
      'תבניות הערות וקולות שמורים לפגישות בסביבת העבודה הזו.';

  @override
  String get settingsWorkspacePolicyLabel => 'מדיניות סביבת העבודה';

  @override
  String get settingsWorkspacePolicyDescription =>
      'חלה על כל חבר וכל סוכן בסביבת העבודה הזו.';

  @override
  String get settingsSecretGlobsLabel => 'החרגת נתיבים סודיים';

  @override
  String get settingsSecretGlobsHelp =>
      'תבנית glob אחת בכל שורה. הנתיבים האלה מוסתרים מפני צופים ואורחים במשטחים שמציגים קוד, בנוסף לברירות המחדל המובנות.';

  @override
  String get settingsReviewConcurrencyLabel => 'מקביליות סקירה';

  @override
  String get settingsReviewConcurrencyHelp =>
      'כמה סוקרים משוגרים במקביל כשלא צוין מספר מפורש.';

  @override
  String get settingsReviewLevelLabel => 'רמת סקירה';

  @override
  String get settingsReviewLevelHelp =>
      'כמה עמוק סקירת ה-AI מגיעה, וכמה ממה שהיא מוצאת מדווח מראש. שום דבר לא נזרק — רמה קלה יותר מקבצת ממצאים מינוריים במקום להשמיט אותם.';

  @override
  String get reviewLevelLight => 'קלה';

  @override
  String get reviewLevelBalanced => 'מאוזנת';

  @override
  String get reviewLevelThorough => 'יסודית';

  @override
  String get reviewLevelLightHint => 'סוקר אחד. רק מה שחשוב מהותית מדווח מראש.';

  @override
  String get reviewLevelBalancedHint =>
      'שלושה סוקרים שמכסים QA, ארכיטקטורה ומימוש.';

  @override
  String get reviewLevelThoroughHint =>
      'מוסיפה מומחי אבטחה וביצועים, ומדווחת על כל מה שנמצא.';

  @override
  String get askAiReviewAtLevel => 'סקירה ברמה אחרת';

  @override
  String reviewNitpicksGroup(int count) {
    return 'הערות קטנות ($count)';
  }

  @override
  String get reviewFindingResolve => 'תוקן';

  @override
  String get reviewFindingResolveHint =>
      'סימון הממצא הזה כמתוקן. הוא מפסיק להיספר נגד הסקירה.';

  @override
  String get reviewFindingDismiss => 'דחייה';

  @override
  String get reviewFindingDismissHint =>
      'לא בעיה אמיתית. סוקרים יפסיקו לסמן את הדפוס הזה ב-PRs הבאים.';

  @override
  String get reviewFindingReopen => 'פתיחה מחדש';

  @override
  String get reviewFindingStatusUndoLabel => 'סטטוס ממצא';

  @override
  String get reviewFindingDismissTitle => 'דחיית הממצא הזה';

  @override
  String get reviewFindingDismissReasonHint =>
      'למה זה לא רלוונטי? הסוקרים יקראו את זה.';

  @override
  String reviewFindingStatusFailed(String error) {
    return 'לא ניתן לעדכן את הממצא: ⁨$error⁩';
  }

  @override
  String get reviewStaleTitle => 'הסקירה הזו אינה מעודכנת';

  @override
  String get reviewStaleBody =>
      'בקשת המשיכה התקדמה מאז שהסקירה הזו רצה. ממצאים עשויים להצביע על קוד שכבר לא קיים.';

  @override
  String reviewStaleReviewedAt(String sha) {
    return 'נסקר בקומיט ⁨$sha⁩';
  }

  @override
  String get reviewStaleRerun => 'סקירה מחדש';

  @override
  String reviewStaleNotificationTitle(int prNumber) {
    return 'סקירה לא מעודכנת ב-⁨#$prNumber⁩';
  }

  @override
  String reviewStaleNotificationBody(String title) {
    return 'ל-$title יש קומיטים חדשים מאז הסקירה האחרונה שלו.';
  }

  @override
  String get reviewCategorySecurity => 'אבטחה';

  @override
  String get reviewCategoryStability => 'יציבות';

  @override
  String get reviewCategoryDataIntegrity => 'שלמות נתונים';

  @override
  String get reviewCategoryCorrectness => 'נכונות';

  @override
  String get reviewCategoryPerformance => 'ביצועים';

  @override
  String get reviewCategoryMaintainability => 'תחזוקתיות';

  @override
  String get reviewEffortQuickWin => 'תיקון מהיר';

  @override
  String get reviewEffortModerate => 'בינוני';

  @override
  String get reviewEffortHeavyLift => 'מאמץ גדול';

  @override
  String get reviewProposedFix => 'תיקון מוצע';

  @override
  String get reviewAiAgentPrompt => 'הנחיה לסוכני AI';

  @override
  String get reviewCopyAiPrompt => 'העתקת ההנחיה';

  @override
  String get settingsWorkspaceAdminOnly =>
      'רק מנהלי סביבת העבודה יכולים לשנות את אלה.';

  @override
  String get chatMyAccountsTitle => 'חשבונות צ\'אט מקושרים';

  @override
  String get settingsServerSso => 'כניסה מאוחדת';

  @override
  String get settingsServerSsoDescription =>
      'כניסה עם SAML ו-OpenID Connect כולל הקצאת משתמשים';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabledDescription => 'משתמשים יכולים להתחבר עם הספק הזה';

  @override
  String get ssoEnabledDescriptionOn => 'ההתחברות פעילה לספק הזה';

  @override
  String get ssoIdpMetadataLabel => 'מטא-נתוני ה-IdP (XML)';

  @override
  String get ssoIdpMetadataHint =>
      'הדביקו את ה-XML של ה-⁨EntityDescriptor⁩ מה-IdP';

  @override
  String get ssoEmailAttributeLabel => 'מאפיין אימייל';

  @override
  String get ssoDisplayNameAttributeLabel => 'מאפיין שם תצוגה';

  @override
  String get ssoGroupsAttributeLabel => 'מאפיין קבוצות';

  @override
  String get ssoIssuerLabel => 'כתובת ה-Issuer';

  @override
  String get ssoClientIdLabel => 'מזהה לקוח';

  @override
  String get ssoGroupsClaimLabel => 'Claim של קבוצות';

  @override
  String get ssoAutoMemberLabel =>
      'הוספת משתמשים לכל סביבת עבודה בהתחברות הראשונה';

  @override
  String get ssoAutoMemberDescription => 'כבו כדי לדרוש הזמנה לכל סביבת עבודה';

  @override
  String get ssoAllowJitLabel => 'הקצאת משתמשים לא מוכרים בהתחברות הראשונה';

  @override
  String get ssoAllowJitDescription => 'כבו כדי לדחות משתמשים ללא חשבון קיים';

  @override
  String get ssoAllowIdpInitiatedLabel => 'קבלת כניסה לא יזומה (ביוזמת ה-IdP)';

  @override
  String get ssoAllowIdpInitiatedDescription =>
      'אך ורק לפורטלים של IdP שמפעילים אפליקציות ישירות';

  @override
  String get ssoWantResponseSignedLabel => 'דרישת מעטפת תגובה חתומה';

  @override
  String get ssoWantResponseSignedDescription =>
      'חתימות על ה-Assertion נדרשות תמיד';

  @override
  String get ssoTestConnectionButton => 'בדיקת חיבור';

  @override
  String get ssoTestConnectionOk => 'החיבור עובד:';

  @override
  String get ssoCopySpMetadata => 'העתקת מטא-נתוני SP';

  @override
  String get ssoCopySpMetadataDone => 'מטא-נתוני ה-SP הועתקו ללוח';

  @override
  String get ssoSavedToast => 'הגדרות הכניסה המאוחדת נשמרו';

  @override
  String get ssoUnavailable =>
      'השרת הזה אינו חושף הגדרות כניסה מאוחדת. עדכנו את הקובץ הבינארי של השרת ונסו שוב.';

  @override
  String get ssoScimCardTitle => 'הקצאת משתמשים (SCIM)';

  @override
  String get ssoScimDescription =>
      'כוונו את מחבר ה-SCIM של ספק הזהויות שלכם אל נקודת הקצה שלמטה עם אסימון גישה מסוג Bearer. ביטול הקצאה שולל סשנים וגישה לסביבות עבודה בתוך שניות. השרת חייב להיות נגיש ל-IdP (מנהרה או כתובת ציבורית).';

  @override
  String get ssoScimEndpoint => 'נקודת קצה של SCIM';

  @override
  String get ssoScimEndpointUnknownOrigin =>
      'הגדירו קודם את כתובת ה-URL הציבורית של השרת או הפעילו מנהרה';

  @override
  String get ssoScimRegenerate => 'יצירת אסימון מחדש';

  @override
  String get ssoScimRegenerateConfirm =>
      'ליצור אסימון גישה חדש מסוג Bearer ל-SCIM? האסימון הקודם יפסיק לעבוד מיידית.';

  @override
  String get ssoScimTokenTitle => 'אסימון Bearer';

  @override
  String get ssoScimTokenPresent => 'אסימון גישה מוגדר';

  @override
  String get ssoScimTokenAbsent =>
      'אין אסימון גישה עדיין — צרו אחד כדי להפעיל SCIM';

  @override
  String get ssoScimTokenOnce => 'אסימון SCIM (מוצג פעם אחת)';

  @override
  String ssoSignInWith(String provider) {
    return 'כניסה עם $provider';
  }

  @override
  String get ssoProbeFailed => 'לא ניתן להגיע לשרת הזה לצורך כניסה מאוחדת';

  @override
  String get ssoOpensBrowser => 'פותח את הדפדפן שלכם להשלמת הכניסה';

  @override
  String get ssoWaitingForBrowser => 'ממתין שהדפדפן ישלים את הכניסה…';

  @override
  String get ssoBrowserOpenFailed => 'לא ניתן לפתוח את הדפדפן לכניסה מאוחדת';

  @override
  String get ssoUseManualPairing => 'כניסה עם הזמנה או מפתח צימוד במקום זאת';

  @override
  String get ssoHideManualPairing => 'הסתרת צימוד ידני';

  @override
  String get ssoClientIdHint => 'לקוח ציבורי (PKCE) — אין צורך בסוד';

  @override
  String get ssoClientSecretLabel => 'סוד לקוח (אופציונלי)';

  @override
  String get ssoClientSecretHintUnset => 'נדרש רק ללקוחות IdP חסויים';

  @override
  String get ssoClientSecretHintSet =>
      'סוד כבר שמור — השאירו ריק כדי לשמור עליו';

  @override
  String get ssoPairingToggle => 'אפשור צימוד ידני (קודי הזמנה ומפתחות צימוד)';

  @override
  String get ssoPairingToggleDescription =>
      'כבו כדי שהצטרפות תהיה בכניסה מאוחדת בלבד — מכשירים חדשים מגיעים דרך התחברויות SSO; מכשירים קיימים ממשיכים לעבוד';

  @override
  String get ssoPairConfirmTitle => 'להתחבר לשרת?';

  @override
  String ssoPairConfirmBody(String server) {
    return 'התקבלו פרטי כניסה עבור ⁨$server⁩, אבל לא הותחלה כניסה מהאפליקציה הזו. להתחבר לשרת הזה?';
  }

  @override
  String get ssoPairConfirmConnect => 'התחברות';

  @override
  String get ssoPairConfirmCancel => 'התעלמות';

  @override
  String get forgeConnections => 'אחסון קוד';

  @override
  String get connect => 'התחברות';

  @override
  String get disconnect => 'ניתוק';

  @override
  String get notConnected => 'לא מחובר';

  @override
  String get checkingConnection => 'בודק חיבור…';

  @override
  String get fromEnvironment => 'ממשתני הסביבה';

  @override
  String forgeTokenTitle(String forge) {
    return 'אסימון גישה של $forge';
  }

  @override
  String get settingsAudio => 'שמע';

  @override
  String get settingsAudioDescription =>
      'מיקרופון, הכתבה, זיהוי פגישות ופלט הנוף הצלילי.';

  @override
  String get audioDevicesSection => 'התקני שמע';

  @override
  String get voiceInputBehaviorSection => 'הכתבה ופגישות';

  @override
  String get audioOutputDeviceTitle => 'התקן פלט';

  @override
  String get audioOutputDefaultHint =>
      'כל השמע של האפליקציה מושמע דרך פלט ברירת המחדל של המערכת.';

  @override
  String get audioOutputGone =>
      'התקן הפלט שנבחר כבר אינו מחובר — ברירת המחדל של המערכת תשמש עד שתבחרו אחר.';

  @override
  String get reviewHubIntroBody =>
      'סוכנים מנתחים את ה-diff, ממפים את אזורי השינוי ומגיעים להכרעה משותפת.';

  @override
  String get reviewHubAlreadyRunning => 'סקירה כבר רצה עבור בקשת המשיכה הזו';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return 'מאז הסקירה האחרונה: $resolved נפתרו · $added חדשים · $open עדיין פתוחים';
  }

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return 'נסקר בעבר ב-⁨$sha⁩';
  }

  @override
  String reviewArtifactFixAll(int count) {
    return 'תיקון $count ממצאים';
  }

  @override
  String reviewArtifactFixSelected(int count) {
    return 'תיקון $count שנבחרו';
  }

  @override
  String reviewArtifactCommentSelected(int count) {
    return 'תגובה על $count שנבחרו';
  }

  @override
  String get webConnectTitle => 'התחברות ל-Control Center';

  @override
  String get webConnectSubtitle =>
      'התחברו ל-cc-server פעיל דרך WebSocket. המפתח שלכם נשאר במכשיר הזה.';

  @override
  String get webConnectServerLabel => 'שרת';

  @override
  String get webConnectDeviceIdLabel => 'מזהה מכשיר';

  @override
  String get webConnectPairingKeyLabel => 'מפתח צימוד';

  @override
  String get webConnectPairingKeyHint => 'הדביקו את ה-PSK';

  @override
  String get webConnectStayConnected => 'להישאר מחוברים במכשיר הזה';

  @override
  String get webConnectStayConnectedDetail =>
      'להישאר מחוברים במכשיר הזה (המפתח נשמר בדפדפן זה)';

  @override
  String failedToCreateWorkspace(String error) {
    return 'יצירת סביבת העבודה נכשלה: $error';
  }

  @override
  String committedRelative(String relative) {
    return 'בוצע קומיט $relative';
  }

  @override
  String get selectAgents => 'בחירת סוכנים';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count סוכנים',
      many: '$count סוכנים',
      two: 'שני סוכנים',
      one: 'סוכן אחד',
    );
    return '$_temp0';
  }

  @override
  String get newConversation => 'שיחה חדשה';

  @override
  String get untitledConversation => 'שיחה ללא שם';

  @override
  String get conversationTitleOptionalHint =>
      'אופציונלי — השאירו ריק ומודל הכותרות ייתן שם אוטומטית';

  @override
  String get conversationTitlesSectionTitle => 'כותרות שיחה';

  @override
  String get conversationTitlesSectionCaption =>
      'בחרו את המריץ שנותן שמות לשיחות חדשות בסביבת עבודה זו אוטומטית. הכותרות כבויות עד שנבחר מתאם, וחלות על כל החברים.';

  @override
  String get conversationTitlesModelLabel => 'מודל כותרות';

  @override
  String get conversationTitlesAdapterLabel => 'מתאם';

  @override
  String get conversationTitlesAdapterHint => 'כבוי';

  @override
  String get conversationTitlesAdapterOff => 'כבוי';

  @override
  String get startThread => 'פתיחת שרשור';

  @override
  String get deleteSpaceConfirm => 'למחוק את המרחב הזה? כל ההודעות יאבדו.';

  @override
  String threadTabTitle(String title) {
    return 'שרשור: $title';
  }

  @override
  String threadReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count תשובות',
      many: '$count תשובות',
      two: 'שתי תשובות',
      one: 'תשובה אחת',
    );
    return '$_temp0';
  }

  @override
  String threadLastReply(String time) {
    return 'תשובה אחרונה $time';
  }

  @override
  String signInWithProvider(String provider) {
    return 'כניסה עם $provider';
  }

  @override
  String get signInAgain => 'כניסה מחדש';

  @override
  String get signInNotFinished =>
      'הכניסה טרם הושלמה. סיימו אותה בדפדפן ואז בדקו שוב.';

  @override
  String get signedOutTitle => 'נותקתם מהמערכת';

  @override
  String get signedOutSubtitle =>
      'החיבור לשירות אירוח הקוד שלכם כבר אינו תקף — אסימון גישה פג, או שהגישה שלו נשללה. שום דבר אחר לא השתנה: היכנסו מחדש והכול נשאר היכן שעזבתם.';

  @override
  String get viaServerApp => 'דרך האפליקציה של השרת הזה';

  @override
  String get ticketing => 'כרטוס';

  @override
  String get ticketingProviderHelp =>
      'היכן הכרטיסים שלכם נשמרים. מקומי שומר אותם ב-Control Center.';

  @override
  String providerComingSoon(String provider) {
    return '$provider (בקרוב)';
  }

  @override
  String get ticketProviderLocal => 'מקומי';

  @override
  String get addKey => 'הוספת מפתח';

  @override
  String get providerApps => 'אפליקציות ספק';

  @override
  String get providerAppsDescription =>
      'מרחבי עבודה יורשים את GitHub App הזה אלא אם בחרו App אחר או אסימון גישה אישי. עבודת רקע — webhooks, סריקה, סנכרון — רצה על האפליקציה, לא על אסימון של אדם.';

  @override
  String get providerAppId => 'מזהה אפליקציה';

  @override
  String get providerPrivateKey => 'מפתח פרטי';

  @override
  String get providerClientId => 'מזהה לקוח';

  @override
  String get providerClientSecret => 'סוד לקוח';

  @override
  String get providerApiKey => 'מפתח API';

  @override
  String get providerCallbackUrl => 'כתובת URL ל-callback';

  @override
  String get providerAppFullyConfigured =>
      'השרת יכול לפעול בשם עצמו, ואנשים יכולים להיכנס.';

  @override
  String get providerAppServerOnly =>
      'השרת יכול לפעול בשם עצמו. הוסיפו מזהה לקוח וסוד כדי לאפשר לאנשים להיכנס.';

  @override
  String get providerAppSignInOnly =>
      'אנשים יכולים להיכנס. עבודת רקע נסמכת על פרטי הגישה שלהם.';

  @override
  String providerAppInstalledOn(String accounts) {
    return 'פרטי הגישה תקינים. מותקן על: $accounts';
  }

  @override
  String deviceCodeInstructions(String provider) {
    return 'הזינו את הקוד הזה בעמוד של $provider שנפתח זה עתה. הקוד הועתק ללוח.';
  }

  @override
  String get deviceCodeWaiting => 'ממתין שתסיימו בדפדפן…';

  @override
  String get copyCodeAndOpen => 'העתקת הקוד ופתיחה';

  @override
  String get couldNotOpenBrowser =>
      'לא ניתן היה לפתוח דפדפן. העתיקו את הקישור וסיימו את הכניסה בעצמכם.';

  @override
  String get contextUsage => 'שימוש בהקשר';

  @override
  String get contextUsageFull => 'מלא';

  @override
  String get contextUsageTokens => 'אסימונים';

  @override
  String get contextSeeMore => 'הצגת עוד';

  @override
  String get contextSegmentSystemPrompt => 'הנחיית מערכת';

  @override
  String get contextSegmentRules => 'כללים';

  @override
  String get contextSegmentSkills => 'מיומנויות';

  @override
  String get contextSegmentToolDefinitions => 'הגדרות כלים';

  @override
  String get contextSegmentMcpTools => 'כלי MCP וכלים דינמיים';

  @override
  String get contextSegmentDeferredTools => 'כלים שנטענים לפי דרישה';

  @override
  String get contextSegmentSubagents => 'הגדרות תת-סוכנים';

  @override
  String get contextSegmentMemory => 'זיכרון';

  @override
  String get contextSegmentConversation => 'שיחה';

  @override
  String get contextExplorerTitle => 'הקשר';

  @override
  String get contextExplorerEverything => 'הכול';

  @override
  String get contextExplorerSelectPart => 'בחרו חלק כדי לבחון את תוכנו';

  @override
  String get contextExplorerUnavailable => 'פירוט ההקשר אינו זמין';

  @override
  String get contextRetry => 'ניסיון חוזר';

  @override
  String get settingsFieldOptional => 'אופציונלי';

  @override
  String get settingsFilterHint => 'סינון הרשימה';

  @override
  String get settingsValueNotAvailable => 'עדיין לא זמין';

  @override
  String get settingsNoEntriesYet => 'אין כאן כלום עדיין';

  @override
  String get settingsChangedBadge => 'שונה';

  @override
  String get ssoConnectionCardDescription =>
      'בחרו איך אנשים נכנסים לשרת הזה, ואז הפעילו את החיבור.';

  @override
  String get ssoUseSamlForSignIn => 'שימוש ב-SAML לכניסה';

  @override
  String get ssoUseOidcForSignIn => 'שימוש ב-OpenID Connect לכניסה';

  @override
  String get ssoSaveConnection => 'שמירת החיבור';

  @override
  String get ssoStateLive => 'פעיל';

  @override
  String get ssoStateConfiguredOff => 'מוגדר, כבוי';

  @override
  String get ssoStateOnIncomplete => 'מופעל, לא הושלם';

  @override
  String get ssoStateActive => 'פעיל';

  @override
  String get ssoStateAllowed => 'מורשה';

  @override
  String get ssoStateNoToken => 'אין אסימון גישה';

  @override
  String get ssoSummaryDirectorySync => 'סנכרון ספרייה';

  @override
  String get ssoSummaryManualPairing => 'צימוד ידני';

  @override
  String get ssoNoMethodLiveNote =>
      'אף שיטת כניסה אינה פעילה. מכשירים חדשים מצטרפים באמצעות הזמנה או מפתח צימוד עד שתגדירו חיבור ותפעילו אותו.';

  @override
  String get ssoMethodSamlBlurb =>
      'לספקי זהות שתומכים ב-SAML 2.0, כגון Okta, Entra ID או Google Workspace.';

  @override
  String get ssoMethodOidcBlurb =>
      'לספקי זהות שתומכים ב-OpenID Connect. בדרך כלל הפשוט יותר מבין השניים להגדרה.';

  @override
  String get ssoGroupIdentityProvider => 'ספק זהות';

  @override
  String get ssoGroupIdentityProviderSamlDescription =>
      'מאין מגיעות ההצהרות, ואיך השרת הזה מאמת אותן.';

  @override
  String get ssoGroupIdentityProviderOidcDescription =>
      'באיזה מנפיק (issuer) השרת הזה בוטח, והלקוח שבשמו הוא מזדהה.';

  @override
  String get ssoSpEntityIdShortLabel => 'מזהה ישות SP';

  @override
  String get ssoSpEntityIdDescription =>
      'השאירו ריק כדי לגזור אותו מכתובת השרת.';

  @override
  String get ssoIssuerDescription =>
      'כתובת הבסיס שמגישה את מסמך הגילוי (discovery) של הספק.';

  @override
  String get ssoSecretStored => 'שמור';

  @override
  String get ssoGroupHandoff => 'מה ספק הזהות שלכם צריך';

  @override
  String get ssoGroupHandoffDescription =>
      'הדביקו את אלה באפליקציה שיצרתם אצל הספק.';

  @override
  String get ssoOriginUnknownTitle =>
      'השרת הזה אינו יודע את הכתובת הציבורית שלו';

  @override
  String get ssoOriginUnknownBody =>
      'כתובות הכניסה וה-callback נבנות ממנה, ולכן הספק שלכם לא יוכל להגיע לשרת הזה עד שתוגדר אחת. הוסיפו כתובת ציבורית או הפעילו מנהרה תחת שרת ← חיבור.';

  @override
  String get ssoAcsUrlLabel => 'כתובת URL של שירות צריכת ההצהרות (ACS)';

  @override
  String get ssoAcsUrlDescription => 'לכאן הספק שולח את ההצהרה החתומה.';

  @override
  String get ssoSpEntityIdResolvedLabel => 'מזהה ישות של ספק השירות';

  @override
  String get ssoMetadataUrlLabel => 'כתובת URL של מטא-נתוני SP';

  @override
  String get ssoMetadataUrlDescription =>
      'ספקים שמייבאים מטא-נתונים יכולים לאחזר אותם מכאן במקום זאת.';

  @override
  String get ssoRedirectUriLabel => 'URI להפניה מחדש';

  @override
  String get ssoRedirectUriDescription =>
      'הוסיפו את זה לרשימת כתובות ההפניה המורשות באפליקציה אצל הספק.';

  @override
  String get ssoSignInUrlLabel => 'כתובת URL לכניסה';

  @override
  String get ssoSignInUrlDescription =>
      'שלחו אנשים לכאן כדי להתחיל כניסה מאוחדת (SSO).';

  @override
  String get ssoGroupAttributeMapping => 'מיפוי מאפיינים';

  @override
  String get ssoGroupAttributeMappingDescription =>
      'איזו תביעה (claim) נושאת כל שדה. השאירו את ברירות המחדל אלא אם הספק שלכם משנה את שמן.';

  @override
  String get ssoGroupAccess => 'גישה ותפקידים';

  @override
  String get ssoGroupAccessDescription => 'מה מותר לעשות למי שנכנס בהצלחה.';

  @override
  String get ssoDefaultRoleShortLabel => 'תפקיד ברירת מחדל';

  @override
  String get ssoDefaultRoleDescription =>
      'ניתן לכל מי שהקבוצות שלו אינן תואמות אף מיפוי למטה.';

  @override
  String get ssoRoleMapShortLabel => 'מיפוי קבוצה לתפקיד';

  @override
  String get ssoRoleMapDescription =>
      'הקבוצה התואמת הראשונה מנצחת. אי אפשר להעניק בעלים בדרך זו.';

  @override
  String get ssoRoleMapGroupHint => 'שם קבוצה מהספק שלכם';

  @override
  String get ssoRoleMapAdd => 'הוספת מיפוי';

  @override
  String get ssoRoleMapEmpty =>
      'אין מיפויים — כולם מקבלים את תפקיד ברירת המחדל.';

  @override
  String get ssoAdvancedSummary =>
      'סטיית שעון, כניסה ביוזמת ה-IdP, מדיניות חתימה';

  @override
  String get ssoClockSkewShortLabel => 'סטיית שעון';

  @override
  String get ssoClockSkewDescription =>
      'שניות של סובלנות על חותמות הזמן של ההצהרות. 90 מתאים לרוב הספקים.';

  @override
  String get ssoScimGenerate => 'יצירת אסימון גישה';

  @override
  String get ssoScimTokenOnceBody =>
      'הועתק ללוח. הוא מוצג פעם אחת בלבד ולא ניתן לשחזרו, אז הדביקו אותו אצל הספק עכשיו.';

  @override
  String get ssoPairingCardTitle => 'צימוד ידני';

  @override
  String get ssoPairingCardDescription =>
      'הדרך האחרת אל השרת הזה: קודי הזמנה ומפתחות צימוד, למכשירים שאינם עוברים דרך כניסה מאוחדת.';

  @override
  String settingsCountOfTotal(int count, int total) {
    return '$count מתוך $total';
  }

  @override
  String get providersNoneConnectedNote =>
      'אף ספק אינו מחובר, ולכן לסביבת הריצה המובנית של הסוכנים אין על מה לרוץ. הוסיפו מפתח API או היכנסו לאחד מהספקים למטה.';

  @override
  String get providersFilterHint => 'סינון ספקים';

  @override
  String get providersNoneMatch => 'אין התאמות למסנן הזה';

  @override
  String get providerDeniedHereTitle => 'נדחה בסביבת עבודה זו';

  @override
  String get providerDeniedHereBody =>
      'סוכנים כאן אינם יכולים להשתמש בספק הזה, אף שהוא מחובר. סביבות עבודה אחרות אינן מושפעות.';

  @override
  String get providerNeedsSignIn => 'היכנסו כדי להשתמש בספק הזה';

  @override
  String get providerNeedsApiKey => 'הוסיפו מפתח API כדי להשתמש בספק הזה';

  @override
  String get providerApiKeyLabel => 'מפתח API';

  @override
  String get providerGenerationDefaults => 'ברירות מחדל של הספק';

  @override
  String get providerNoModelsYet =>
      'טרם דווחו מודלים. חברו את הספק ואז סנכרנו.';

  @override
  String get providerModelsFilterHint => 'סינון מודלים';

  @override
  String get adaptersNoneReadyNote =>
      'אף אחד מכלי ה-CLI של המריצים שבקטלוג לא נמצא במחשב הזה. התקינו אחד ואז רעננו.';

  @override
  String get adaptersFilterHint => 'סינון מריצים';

  @override
  String get adaptersLaunchGroup => 'הפעלה';

  @override
  String get adaptersLaunchGroupDescription =>
      'מה המריץ הזה מקבל כשסוכן מפעיל אותו. אפשר להגדיר את אלה עוד לפני התקנת ה-CLI.';

  @override
  String get adaptersEnvNone => 'לא הוגדר דבר';

  @override
  String adaptersEnvCount(int count) {
    return '$count הוגדרו';
  }

  @override
  String get adapterArgumentsDescription =>
      'מצורף לשורת הפקודה של המריץ בכל הפעלה.';

  @override
  String get defaultChatDescription =>
      'מריץ שיחות חדשות וכל סוכן שאין לו מריץ משלו.';

  @override
  String get shortTaskDescription =>
      'מריץ עבודות רקע מהירות כמו כותרות ותקצירים. מודל קטן יותר מתאים לכאן.';

  @override
  String get settingsStateFailed => 'נכשל';

  @override
  String get providerAppsGroupServer => 'פעולה בשם השרת';

  @override
  String get providerAppsGroupServerDescription =>
      'למרחבים שיורשים את GitHub App של ההתקנה. מרחב עם App או PAT משלו מוגדר תחת מרחב עבודה → כללי.';

  @override
  String get providerAppsGroupPrConversations => 'שיחות בבקשות משיכה';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      'איך מפתחים מדברים עם השרת ב-GitHub במרחבים יורשים. למרחב עם App משלו יש בוט תחת מרחב עבודה → כללי. בלי webhook או כתובת ציבורית — השרת סורק.';

  @override
  String get providerAppBotLogin => 'שם המשתמש של הבוט';

  @override
  String get providerAppBotLoginEmpty =>
      'בדקו את החיבור כדי לברר את שם המשתמש של הבוט.';

  @override
  String get providerAppAskOnGitHub => 'פנייה ב-GitHub';

  @override
  String get providerAppAskOnGitHubHint =>
      'אזכרו את שם המשתמש של הבוט שלמעלה בתגובה בבקשת משיכה — הסיומת [bot] אופציונלית — כדי לבקש סקירה או לשאול שאלה, השיבו בתוך שרשורי הסקירה שלו, או הוסיפו את התווית `ai-review` כדי לבקש סקירה.';

  @override
  String get providerAppsGroupSignIn => 'כניסת אנשים';

  @override
  String get providerAppsGroupSignInDescription =>
      'מאפשר לכל חבר לחבר חשבון משלו ולקבל פרטי גישה משלו.';

  @override
  String get providerAppCapActsAsServer => 'פועל בשם השרת';

  @override
  String get providerAppCapSignsIn => 'מכניס אנשים';

  @override
  String get portLabel => 'פורט';

  @override
  String get mcpNoTokenWarning =>
      'ללא אסימון גישה, כל מה שמגיע לפורט הזה יכול לקרוא לכל כלי.';

  @override
  String get mcpBridgedToolsLabel => 'כלים';

  @override
  String get guardrailFamilyFiles => 'קבצים';

  @override
  String get guardrailFamilyGit => 'Git ובקשות משיכה';

  @override
  String get guardrailFamilyMachine => 'מכונה ורשת';

  @override
  String get guardrailFamilyControl => 'סודות וסביבת עבודה';

  @override
  String get guardrailScopeFieldLabel => 'עריכת כללים עבור';

  @override
  String get guardrailScopeFieldDescription =>
      'טווח צר גובר על טווח רחב. כללים שנקבעים כאן חלים בנוסף למה שמתקבל בירושה.';

  @override
  String get guardrailSetHere => 'הוגדר כאן';

  @override
  String get guardrailClearAllHere => 'ניקוי הכול';

  @override
  String get sandboxingCardLabel => 'ארגז חול';

  @override
  String get sandboxingCardDescription =>
      'האם עבודת סוכנים רצה מבודדת מהמארח הזה, ולמה סוכן מבודד עדיין יכול להגיע.';

  @override
  String get sandboxBackendNoneActive => 'מארח, ללא בידוד';

  @override
  String get sandboxSummaryHost => 'מארח';

  @override
  String get sandboxGroupIsolation => 'בידוד';

  @override
  String get sandboxGroupIsolationDescription =>
      'היכן התהליכים וכתיבות הקבצים של סוכן קורים בפועל.';

  @override
  String get sandboxBackendFieldDescription =>
      'אוטומטי בוחר את החזק ביותר שהמארח הזה תומך בו. הצמידו אחד כדי שלא יתחלף מתחת לידיכם.';

  @override
  String get sandboxCapabilitiesDescription =>
      'החורים שנוקבו בגבול. כל אחד מהם הוא משהו שסוכן מבודד עדיין יכול לעשות לעולם החיצון.';

  @override
  String get sandboxSummaryInForce => 'בתוקף';

  @override
  String get rigsInstallHintLabel => 'איך להתקין';

  @override
  String get rigsStarting => 'מופעלת';

  @override
  String get rigsResidentMemory => 'זיכרון תושב';

  @override
  String get installedLabel => 'מותקן';

  @override
  String get notInstalledLabel => 'לא מותקן';

  @override
  String ssoOtherKindUnsaved(String method) {
    return 'ל-$method יש שינויים שלא נשמרו';
  }

  @override
  String get collapseComment => 'כיווץ התגובה';

  @override
  String get expandComment => 'הרחבת התגובה';

  @override
  String get suggestedChange => 'שינוי מוצע';

  @override
  String get emptyComment => 'תגובה ריקה';

  @override
  String repliesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count תשובות',
      many: '$count תשובות',
      two: 'שתי תשובות',
      one: 'תשובה אחת',
    );
    return '$_temp0';
  }

  @override
  String get pendingReview => 'ממתין לסקירה';

  @override
  String failedToResolveConversation(String error) {
    return 'לא ניתן היה לעדכן את השיחה: $error';
  }

  @override
  String get addSingleComment => 'הוספת תגובה בודדת';

  @override
  String get addToReview => 'הוספה לסקירה';

  @override
  String get startAReview => 'התחלת סקירה';

  @override
  String get reviewNeedsABody => 'כתבו תקציר או הכניסו קודם תגובה לתור';

  @override
  String get reviewSubmitted => 'הסקירה נשלחה';

  @override
  String get finishYourReview => 'סיום הסקירה';

  @override
  String get commentVerdict => 'תגובה';

  @override
  String pendingCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count תגובות ממתינות',
      many: '$count תגובות ממתינות',
      two: 'שתי תגובות ממתינות',
      one: 'תגובה אחת ממתינה',
    );
    return '$_temp0';
  }

  @override
  String andNMore(int count) {
    return 'ועוד $count';
  }

  @override
  String get queuedCommentHint => 'התגובה הזו תישלח כשתגישו את הסקירה.';

  @override
  String commentOnLinesRange(int start, int end) {
    return 'שורות $start עד $end';
  }

  @override
  String get claudeAccountsTitle => 'חשבונות Claude Code';

  @override
  String get claudeAccountsDescription =>
      'כל חשבון הוא כניסת Claude Code נפרדת. הרצות משתמשות בחשבונות המצורפים למטה, לפי הסדר הזה.';

  @override
  String get claudeAccountsEmpty => 'אין חשבונות עדיין';

  @override
  String get claudeAccountAdd => 'הוספת חשבון';

  @override
  String get claudeAccountSignIn => 'כניסה';

  @override
  String get claudeAccountSignInAgain => 'כניסה מחדש';

  @override
  String get claudeAccountSignInHint =>
      'הריצו את זה בטרמינל על השרת. זה פותח דפדפן להשלמת הכניסה, וכותב את פרטי הגישה לתיקייה של החשבון הזה.';

  @override
  String get claudeAccountSignedOut => 'מנותק';

  @override
  String get claudeAccountExpired => 'פג תוקף הכניסה';

  @override
  String claudeAccountExpiredDetail(String when) {
    return 'תוקף הכניסה פג ב-$when. היכנסו מחדש כדי להשתמש בחשבון הזה.';
  }

  @override
  String get claudeAccountMakeDefault => 'קביעה כברירת מחדל';

  @override
  String get claudeAccountDefault => 'ברירת מחדל';

  @override
  String claudeAccountRemoveConfirm(String label) {
    return 'להסיר את $label?';
  }

  @override
  String get claudeAccountRemoveDetail =>
      'פעולה זו מנתקת את החשבון ומוחקת את התיקייה שלו על השרת. הכניסה עצמה אינה מושפעת.';

  @override
  String claudeAccountStatusUnknown(String error) {
    return 'לא ניתן היה לבדוק את החשבון הזה: $error';
  }

  @override
  String claudeAccountUsedPercent(String percent) {
    return '$percent% בשימוש';
  }

  @override
  String get accountPoolStrategy => 'רוטציה';

  @override
  String get accountPoolPinned => 'מוצמד';

  @override
  String get accountPoolRoundRobin => 'סבב מחזורי';

  @override
  String get accountPoolSerial => 'אחד בכל פעם';

  @override
  String get accountPoolPinnedHint =>
      'להתחיל תמיד בחשבון הראשון. האחרים נשארים כגיבוי אם הוא נכשל.';

  @override
  String get accountPoolRoundRobinHint =>
      'לפזר הרצות בין החשבונות, במעבר לחשבון הבא בכל שיגור.';

  @override
  String get accountPoolSerialHint =>
      'למצות את החשבון הראשון לפני שנוגעים בבא אחריו.';

  @override
  String get accountPoolMoveUp => 'העברה למעלה';

  @override
  String get accountPoolMoveDown => 'העברה למטה';

  @override
  String get accountPoolUsingAll =>
      'עוד לא צורף דבר — כל החשבונות בשימוש, לפי הסדר הזה.';

  @override
  String get accountPoolInheriting => 'יורש את החשבונות של סביבת העבודה.';

  @override
  String get accountPoolResetToWorkspace => 'איפוס לחשבונות של סביבת העבודה';

  @override
  String accountPoolCoolingOff(String when) {
    return 'מחוץ למכסה עד $when';
  }

  @override
  String get accountPoolSignedOut => 'מנותק';

  @override
  String get accountPoolExpired => 'פג תוקף הכניסה';

  @override
  String accountPoolLoadFailed(String error) {
    return 'לא ניתן היה לטעון את הרוטציה: $error';
  }

  @override
  String get providerSignedInAccount => 'חשבון מחובר';

  @override
  String get agentAccountsTab => 'חשבונות';

  @override
  String get agentClaudeAccountsNoticeTitle => 'מספר חשבונות Claude Code';

  @override
  String agentClaudeAccountsNoticeBody(int count) {
    return 'המריץ הזה נכנס כאחד מ-$count חשבונות Claude Code שבמארח הזה. בחרו איזה מהם, או סובבו ביניהם, בלשונית החשבונות.';
  }

  @override
  String get agentAccountsDescription =>
      'באילו חשבונות משתמשות ההרצות של הסוכן הזה. כל בלוק מתחיל בירושה מהבחירה של סביבת העבודה.';

  @override
  String get agentAccountsNothingToRotate =>
      'אין מה לסובב — חברו קודם חשבון שני או מפתח.';

  @override
  String failedToPostReply(String error) {
    return 'לא ניתן היה לפרסם את התשובה: $error';
  }

  @override
  String commentOnLine(int line) {
    return 'שורה $line';
  }

  @override
  String get viewInDiff => 'הצגה ב-diff';

  @override
  String get subscriptionUsagePreviousAccount => 'החשבון הקודם';

  @override
  String get subscriptionUsageNextAccount => 'החשבון הבא';

  @override
  String inReplyTo(String path) {
    return 'בתשובה ל-⁨$path⁩';
  }

  @override
  String get subscriptionUsageNoneReported => 'לא דווח שימוש עבור החשבון הזה.';

  @override
  String get subscriptionUsageCredits => 'קרדיטים';

  @override
  String get reviewHubStaticRule => 'כלל סטטי';

  @override
  String get reviewHubStarted => 'הסקירה החלה';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return 'נמצא על ידי כלל דטרמיניסטי (⁨$rule⁩) על שורה שבקשת המשיכה הזו מוסיפה — לא על ידי סוכן סוקר.';
  }

  @override
  String get prReviewArtifactTab => 'סקירת PR';

  @override
  String get prReviewRunning => 'סוקר את בקשת המשיכה הזו…';

  @override
  String get prReviewStarting => 'מתחיל סקירה…';

  @override
  String get prReviewStartingBody =>
      'מכין את עץ העבודה של בקשת המשיכה הזו. הסוקרים יתחילו ברגע שהוא מוכן.';

  @override
  String get prReviewFailed => 'הסקירה נכשלה.';

  @override
  String get prReviewRerunning => 'סוקר מחדש…';

  @override
  String get prReviewNoOpenFindings => 'אין ממצאים פתוחים';

  @override
  String prReviewOpenFindings(int count) {
    return '$count ממצאים פתוחים';
  }

  @override
  String subscriptionUsageSpend(String used, String limit) {
    return '$used מתוך $limit';
  }

  @override
  String reviewCommentsPosted(int posted, int skipped, int failed) {
    return 'פורסמו $posted תגובות בשם הבוט. $skipped דולגו (אין עוגן קובץ), $failed נכשלו.';
  }

  @override
  String reviewFindingsOutOfDiff(int count, String files) {
    return '$count ממצאים מכוונים לקוד שבקשת המשיכה הזו אינה משנה (⁨$files⁩). GitHub מקבל תגובות בתוך השורה רק על ה-diff.';
  }

  @override
  String get reviewRailReport => 'דוח';

  @override
  String get reviewNoFindingsTitle => 'אין עדיין ממצאי סקירה';

  @override
  String get reviewNoFindingsHint => 'ממצאים יופיעו כאן כשסוכנים יפרסמו אותם.';

  @override
  String reviewShowDismissed(int count) {
    return 'הצגת $count שנדחו';
  }

  @override
  String reviewHideDismissed(int count) {
    return 'הסתרת $count שנדחו';
  }

  @override
  String reviewDisagreementsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'זוהו $count מחלוקות סוקרים',
      many: 'זוהו $count מחלוקות סוקרים',
      two: 'זוהו שתי מחלוקות סוקרים',
      one: 'זוהתה מחלוקת סוקרים אחת',
    );
    return '$_temp0';
  }

  @override
  String get reviewFilterKind => 'סוג';

  @override
  String get reviewFilterStatus => 'סטטוס';

  @override
  String get reviewKindBug => 'באג';

  @override
  String get reviewKindSuggestion => 'הצעה';

  @override
  String get reviewKindRecommendation => 'המלצה';

  @override
  String get reviewKindQuestion => 'שאלה';

  @override
  String get reviewKindTicket => 'כרטיס';

  @override
  String get archiveSpace => 'העברת המרחב לארכיון';

  @override
  String get archivedSpaces => 'מרחבים בארכיון';

  @override
  String get archivedSpacesEmpty => 'אין מרחבים בארכיון';

  @override
  String get restoreSpace => 'שחזור';

  @override
  String archivedWhen(String time) {
    return 'הועבר לארכיון $time';
  }

  @override
  String get deleteSpacePermanently => 'מחיקה לצמיתות';

  @override
  String get renameSpace => 'שינוי שם המרחב';

  @override
  String get renameConversation => 'שינוי שם השיחה';

  @override
  String get spaceActions => 'פעולות המרחב';

  @override
  String get conversationActions => 'פעולות השיחה';

  @override
  String get editSpaceRepos => 'עריכת מאגרים';

  @override
  String get editSpaceReposTitle => 'מאגרי המרחב';

  @override
  String get editSpaceReposWarning =>
      'הוספת מאגר משכפלת אותו לתוך המרחב הזה; הסרת מאגר מוחקת את התיקייה שלו.';

  @override
  String get agentSectionIdentity => 'זהות';

  @override
  String get agentSectionRuntime => 'סביבת ריצה';

  @override
  String get agentSectionGuardrails => 'מעקות בטיחות';

  @override
  String orgChartReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count כפיפים',
      many: '$count כפיפים',
      two: 'שני כפיפים',
      one: 'כפיף אחד',
    );
    return '$_temp0';
  }

  @override
  String get teamsFilterHint => 'סינון צוותים…';

  @override
  String get teamsSummaryWithLeader => 'עם מוביל';

  @override
  String teamCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count צוותים',
      many: '$count צוותים',
      two: 'שני צוותים',
      one: 'צוות אחד',
      zero: 'אין צוותים',
    );
    return '$_temp0';
  }

  @override
  String agentDeleteLongDescription(String name) {
    return 'מחיקת $name מסירה את הפרופיל שלו, את קישורי המיומנויות שלו ואת היסטוריית ההרצות שלו. אי אפשר לבטל זאת.';
  }

  @override
  String get resetToDefault => 'איפוס לברירת המחדל';

  @override
  String get newAgent => 'סוכן חדש';

  @override
  String get newSkill => 'מיומנות חדשה';

  @override
  String get zoomIn => 'התקרבות';

  @override
  String get zoomOut => 'התרחקות';

  @override
  String get resetZoom => 'איפוס התקריב';

  @override
  String get imageHostedOnGitHub => 'תמונה מאוחסנת ב-GitHub';

  @override
  String get imageOpenExternally => 'תמונה · פתיחה חיצונית';

  @override
  String get memoryScopeAll => 'כל הטווחים';

  @override
  String get memoryScopeWorkspace => 'כלל סביבת העבודה';

  @override
  String get memoryScopeFilterLabel => 'סינון לפי טווח';

  @override
  String memoryScopeRepoTooltip(String repo) {
    return 'מוגבל למאגר ⁨$repo⁩';
  }

  @override
  String get toolScreenshot => 'צילום מסך מהסוכן';

  @override
  String get toolImageUnavailable => 'התמונה אינה זמינה';

  @override
  String toolImagesUnavailable(int count) {
    return '$count תמונות אינן זמינות';
  }

  @override
  String get shakeUnavailable => 'ניעור אינו זמין בשרת הזה';

  @override
  String get shakeNothing => 'אין מה לנער החוצה — התורים האחרונים מוגנים';

  @override
  String shakeDone(int tokens) {
    return 'שוחררו כ-$tokens אסימונים';
  }

  @override
  String get compactionDivider => 'נדחס';

  @override
  String compactionDividerCount(int count) {
    return 'נדחס · $count הודעות קופלו';
  }

  @override
  String get composerDropToAttach => 'שחררו כדי לצרף';

  @override
  String get attachmentUnavailable => 'הקובץ המצורף אינו זמין';

  @override
  String get attachmentUnavailableDetail =>
      'הקובץ המצורף הזה כבר אינו מוחזק בזיכרון. צרפו אותו שוב כדי לראות תצוגה מקדימה.';

  @override
  String get attachmentPreviewFailed => 'לא ניתן היה לפתוח את הקובץ הזה';

  @override
  String get attachmentPreviewUnsupported => 'אין תצוגה מקדימה לסוג הקובץ הזה';

  @override
  String get attachmentTooLargeToPreview => 'גדול מדי לתצוגה מקדימה';

  @override
  String get attachmentOpenExternally => 'פתיחה באפליקציית ברירת המחדל';

  @override
  String get asideUnavailable =>
      'כדי להשתמש בזה, הגדירו מודל חד-פעמי בהגדרות סביבת העבודה';

  @override
  String get asideEmpty => 'אין עדיין ממה לעבוד';

  @override
  String get asideFailed => 'לא התקבלה תשובה';

  @override
  String get handoffTitle => 'מסירה';

  @override
  String get asideTitle => 'שאלת צד';

  @override
  String get attachFilesOrDrop => 'צירוף קבצים — או גררו אותם לכאן';

  @override
  String get guidedGoalTitle => 'חידוד המטרה';

  @override
  String get guidedGoalIntro =>
      'סוכן שעובד ללא השגחה צריך לדעת בדיוק מתי סיים. כמה שאלות קודם.';

  @override
  String get guidedGoalAnswerHint => 'התשובה שלכם';

  @override
  String get guidedGoalNext => 'הבא';

  @override
  String get guidedGoalStart => 'התחלת המטרה';

  @override
  String get guidedGoalSkip => 'דילוג והרצה כפי שנכתב';

  @override
  String guidedGoalStillMissing(String items) {
    return 'עדיין לא הוגדר: $items';
  }

  @override
  String get conversationTreeTitle => 'עץ השיחה';

  @override
  String conversationTreeBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ענפים',
      many: '$count ענפים',
      two: 'שני ענפים',
      one: 'ענף אחד',
    );
    return '$_temp0';
  }

  @override
  String get conversationTreeSwitch => 'המשך מכאן';

  @override
  String get conversationTreeFork => 'פיצול לשיחה חדשה';

  @override
  String get conversationTreeCurrent => 'בענף הזה';

  @override
  String get conversationTreeEmpty => 'אין כאן כלום עדיין';

  @override
  String get conversationTreeForked => 'פוצל לשיחה חדשה';

  @override
  String get conversationTreeSwitched => 'ממשיכים כעת מההודעה ההיא';

  @override
  String exportSaved(String path) {
    return 'נשמר אל ⁨$path⁩';
  }

  @override
  String get exportFailed => 'לא ניתן היה לכתוב את הייצוא';

  @override
  String get contextCommandNoAgent =>
      'אין סוכן בשיחה הזו, ולכן אין חלון הקשר לפתוח';

  @override
  String contextCommandNoSuchAgent(String name, String names) {
    return 'אין סוכן בשם ״$name״ בשיחה הזו. נסו: $names';
  }

  @override
  String get dumpCopied => 'התמליל הועתק ללוח';

  @override
  String get messageQueueHint => 'המשיכו להקליד כדי להכניס לתור שינויים נוספים';

  @override
  String get steerNow => 'היגוי';

  @override
  String get steeringQueueLabel => 'הודעות היגוי בתור';

  @override
  String get steeringDeliverUnavailable =>
      'אף סוכן פעיל לא יכול לקבל את זה כרגע — זה נשאר בתור.';

  @override
  String get reorderSteeringCard => 'סידור מחדש של הודעה בתור';

  @override
  String get editSteeringCard => 'עריכת הודעה בתור';

  @override
  String get deleteSteeringCard => 'מחיקת הודעה בתור';

  @override
  String get steeringBadge => 'עבר היגוי';

  @override
  String get settingsSandboxLabel => 'ארגז חול';

  @override
  String get sandboxExecGrantsTitle => 'הרשאות הפעלה';

  @override
  String get sandboxExecGrantsSubtitle =>
      'תוכניות שסוכנים רשאים להריץ מעותק העבודה של המאגרים שלכם. כל רשומה אושרה על ידכם כשארגז החול ביקש.';

  @override
  String get sandboxExecGrantsEmpty =>
      'טרם נרשמו החלטות. תישאלו בפעם הראשונה שסוכן יצטרך להריץ תוכנית מעותק העבודה שלו.';

  @override
  String get sandboxExecGrantRevoke => 'שלילה';

  @override
  String get sandboxExecGrantAllowed => 'מותר';

  @override
  String get sandboxExecGrantBlocked => 'חסום';

  @override
  String get sandboxExecGrantRevokeConfirmTitle => 'לשלול את ההחלטה הזו?';

  @override
  String get sandboxExecGrantRevokeConfirmBody =>
      'תישאלו שוב בפעם הבאה שסוכן יצטרך להריץ תוכנית מהעותק הזה.';

  @override
  String get repoScriptsTest => 'בדיקה';

  @override
  String get repoScriptsTestTooltip => 'הרצת הטיוטה הזו בשכפול זמני של המאגר';

  @override
  String get repoScriptsRunKindTest => 'בדיקה';

  @override
  String get demoBadgeLabel => 'דמו';

  @override
  String get demoFilePickerTitle => 'קובצי דמו';

  @override
  String get demoFilePickerBody =>
      'הדמו מדמה העלאות: בחרו כל אחד מאלה והוא יצורף להודעה שלכם בלי לגעת בדיסק.';

  @override
  String get demoFilePickerAttach => 'צירוף';

  @override
  String get demoReadOnlySave => 'לקריאה בלבד בדמו';

  @override
  String get demoBadgeTooltip =>
      'אתם חוקרים דמו. הנתונים בדיוניים והסוכנים מתוסרטים.';

  @override
  String get demoFirstRunTitle => 'אתם בדמו חי';

  @override
  String demoFirstRunBody(int minutes) {
    return 'זו האפליקציה האמיתית שרצה על קוד אמיתי — רק הנתונים מומצאים. הסוכנים מזרימים הרצות אמיתיות מתוך תסריט, כך ששום דבר לא מגיע למודל ושום דבר לא רץ על מכונה. סביבת העבודה שלכם היא שלכם בלבד ונעלמת אחרי $minutes דקות.';
  }

  @override
  String get demoFirstRunDismiss => 'הבנתי';

  @override
  String get demoTourTitle => 'לאן להסתכל קודם';

  @override
  String get demoTourSubtitle => 'ארבעה מקומות שמראים מה האפליקציה באמת עושה.';

  @override
  String get demoTourSkip => 'דילוג';

  @override
  String get demoTourStarRepo => 'כוכב ב-GitHub';

  @override
  String get demoTourOpen => 'פתיחה';

  @override
  String get demoTourSpacesTitle => 'דברו עם סוכן';

  @override
  String get demoTourSpacesBody =>
      'שלחו הודעה במרחב וצפו בהרצה זורמת פנימה — חשיבה, קריאות כלים ועלות, בדיוק כפי שהרצה אמיתית נראית.';

  @override
  String get demoTourReviewTitle => 'סקרו בקשת משיכה';

  @override
  String get demoTourReviewBody =>
      'פתחו את ⁨#412⁩. השאירו תגובה בתוך השורה או הגישו סקירה; המילים שלכם נוחתות בשרשור ונשארות שם.';

  @override
  String get demoTourTicketsTitle => 'עקבו אחרי העבודה';

  @override
  String get demoTourTicketsBody =>
      'כרטיסים, מטלות ותוכניות מקושרים לאותן שיחות שהסוכנים מנהלים.';

  @override
  String get demoTourInboxTitle => 'ראו את התמונה המלאה';

  @override
  String get demoTourInboxBody =>
      'כל התראה מכל תחום נוחתת בדואר נכנס אחד — סקירות, כרטיסים, הרצות ופגישות.';

  @override
  String get demoUnavailableTitle => 'לא זמין בדמו';

  @override
  String get demoUnavailableTerminal =>
      'טרמינל מריץ מעטפת אמיתית על מארח השרת. לדמו אין שום משטח הרצה — זה מה שהופך אותו לבטוח לפתיחה לציבור.';

  @override
  String get demoUnavailableRig =>
      'מתחם מבודד הוא מכונה וירטואלית חד-פעמית שסוכן מפעיל. הדמו לא מאתחל אף אחת: נקודת קצה ציבורית שיכולה להפעיל VM אינה דמו.';

  @override
  String get demoUnavailableEditor =>
      'העורך שבדפדפן מריץ תהליך code-server מול checkout אמיתי. לדמו אין לא את זה ולא את זה.';

  @override
  String get demoUnavailableFeeds =>
      'הדמו קורא הזנות אמיתיות, אבל רשימת המינויים שלו קבועה. הוספה או הסרה מושבתות כאן.';

  @override
  String get demoUnavailableForge =>
      'הדמו לא מחזיק פרטי גישה ולעולם לא פונה אל GitHub, GitLab או Linear. בקשות המשיכה שלו הן נתוני דמה, והתגובות שלכם עליהן נשמרות מקומית.';

  @override
  String get demoUnavailableModels =>
      'הדמו לא קורא לאף מודל. הרצות סוכנים הן השמעה מתוסרטת, ולכן הן לא עולות דבר ולא מגיעות לאף ספק.';

  @override
  String get demoUnavailableMcp =>
      'משטח כלי ה-MCP לא מותקן בדמו, ולכן אף לקוח חיצוני לא יכול להתחבר אליו.';

  @override
  String get demoUnavailableRepos =>
      'הדמו לא משכפל קוד ולא מריץ git. המאגר שאתם רואים הוא נתון דמה שמאחורי בקשות המשיכה.';

  @override
  String get demoUnavailableSkills =>
      'התקנת מיומנות מורידה וסורקת קוד. הדמו לא מוריד דבר.';

  @override
  String get demoUnavailableSso =>
      'כניסה מאוחדת היא תצורת שרת. הדמו מכניס אתכם במקום זאת כאורחים זמניים.';

  @override
  String get demoUnavailableAudio =>
      'הקלטה והכתבה דורשות לכידת שמע ומודל דיבור על המארח. הדמו לא כולל אף אחד מהם, ולכן הפגישות שלו הן תמלילים ללא השמעה.';

  @override
  String get demoUnavailableServerAdmin =>
      'זהו ניהול שרת. הדמו נותן לכל מבקר סביבת עבודה חד-פעמית משלו ותו לא.';

  @override
  String get demoUnavailablePipelines =>
      'לא ניתן להריץ צינורות כאן. מבקר שיכול לכתוב שלב bash ולהפעיל אותו — ידנית או דרך מפעיל אירוע — מריץ קוד על המארח הזה.';

  @override
  String get settingsBackupRestore => 'גיבוי ושחזור';

  @override
  String get settingsBackupRestoreDescription =>
      'תמונות מצב של כל מסד נתונים בשרת הזה, וגם ייצוא, ייבוא ומחיקה של סביבת עבודה בודדת.';

  @override
  String get backupSnapshotsLabel => 'תמונות מצב של ההתקנה';

  @override
  String get backupSnapshotsExplainer =>
      'תמונת מצב מעתיקה כל מסד נתונים לתיקייה עם חותמת זמן על מארח השרת. שחזור התקנה שלמה פירושו העתקת התיקייה בחזרה כשהשרת כבוי; סביבת עבודה בודדת אפשר לשחזר מכאן.';

  @override
  String get backupNowAction => 'גיבוי עכשיו';

  @override
  String backupSnapshotWritten(String path) {
    return 'תמונת המצב נכתבה אל ⁨$path⁩';
  }

  @override
  String get backupNoSnapshots =>
      'אין תמונות מצב עדיין. תמונה נוצרת רק כשתבקשו — שום דבר לא מתוזמן.';

  @override
  String get backupSnapshotComplete => 'שלמה';

  @override
  String get backupSnapshotIncomplete => 'חלקית';

  @override
  String get backupSnapshotIncompleteNote =>
      'המניפסט חסר או מפנה לקבצים שאינם שם, ולכן תמונת המצב הזו לא יכולה לשחזר את ההתקנה כולה. את קובצי סביבות העבודה שכן יש בה עדיין אפשר לאמץ אחד-אחד.';

  @override
  String backupSnapshotWorkspaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count סביבות עבודה',
      many: '$count סביבות עבודה',
      two: 'שתי סביבות עבודה',
      one: 'סביבת עבודה אחת',
      zero: 'אין סביבות עבודה',
    );
    return '$_temp0';
  }

  @override
  String backupSnapshotSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count סביבות עבודה לא נלכדו',
      many: '$count סביבות עבודה לא נלכדו',
      two: 'שתי סביבות עבודה לא נלכדו',
      one: 'סביבת עבודה אחת לא נלכדה',
    );
    return '$_temp0';
  }

  @override
  String get backupServerPathLabel => 'נתיב על השרת';

  @override
  String get backupRestoreAction => 'שחזור';

  @override
  String get backupRestoreTitle => 'שחזור סביבת עבודה';

  @override
  String backupRestoreBody(String name) {
    return 'פעולה זו מחליפה את כל התוכן של $name בעותק שבתמונת המצב הזו. כל מה שסביבת העבודה עשתה מאז שנוצרה תמונת המצב יאבד, ואי אפשר לבטל זאת.';
  }

  @override
  String backupRestoreDone(String name) {
    return '$name שוחזרה מתמונת המצב.';
  }

  @override
  String get backupWorkspaceUnknown => 'כבר לא נמצאת בשרת הזה';

  @override
  String get backupWorkspaceDataLabel => 'נתוני סביבת עבודה';

  @override
  String get backupWorkspaceDataExplainer =>
      'סביבת עבודה אחת היא קובץ מסד נתונים אחד, ולכן ייצוא שלה מעתיק את הקובץ במקום לשפוך טבלה אחר טבלה. ייבוא מחליף את כל התוכן של סביבת העבודה היעד בקובץ שתציינו.';

  @override
  String get backupExportAction => 'ייצוא';

  @override
  String backupExportDone(String path) {
    return 'יוצא אל ⁨$path⁩';
  }

  @override
  String get backupExportedFileLabel => 'הקובץ שיוצא על השרת';

  @override
  String get backupImportAction => 'ייבוא';

  @override
  String backupImportTitle(String name) {
    return 'ייבוא אל $name';
  }

  @override
  String backupImportBody(String name) {
    return 'פעולה זו מחליפה את כל התוכן של $name בתוכן הקובץ. כל מה שסביבת העבודה מכילה כעת יאבד, ואי אפשר לבטל זאת.';
  }

  @override
  String get backupImportSourceLabel => 'קובץ מסד הנתונים של סביבת העבודה';

  @override
  String get backupImportSourceDescription =>
      'קובץ ⁨.db⁩ שהשרת יכול לקרוא. נתיבים נפתרים על מארח השרת, לא במכשיר הזה.';

  @override
  String backupImportDone(String name) {
    return 'יובא אל $name.';
  }

  @override
  String backupDeleteBody(String name) {
    return '$name נעלמת מכל רשימה וחיפוש. קובץ מסד הנתונים שלה נשאר בדיסק, גיבויים עדיין כוללים אותו, ושום דבר לא מפנה את המקום אוטומטית.';
  }

  @override
  String get backupExportDescription =>
      'כתיבת עותק על השרת, או הורדת עותק למכשיר הזה.';

  @override
  String get backupExportOnServerAction => 'שמירה על השרת';

  @override
  String get backupDownloadAction => 'הורדה';

  @override
  String backupDownloadSaved(String path) {
    return 'נשמר אל ⁨$path⁩';
  }

  @override
  String get backupDownloadInBrowser => 'הדפדפן שלכם מוריד אותו כעת.';

  @override
  String get backupRestoreFromDeviceLabel => 'שחזור מהמכשיר הזה';

  @override
  String get backupRestoreFromDeviceDescription =>
      'בחרו כאן קובץ מסד נתונים של סביבת עבודה ו-Control Center יעלה אותו לשרת. זו הדרך שעובדת כשהשרת אינו המחשב הזה.';

  @override
  String get backupUploadAction => 'בחירת קובץ והעלאה';

  @override
  String get backupTransferUnavailable =>
      'החיבור הזה מגיע לשרת דרך ממסר, שאינו מעביר קבצים. התחברו לשרת ישירות כדי להוריד או להעלות גיבוי.';

  @override
  String get backupTransferForbidden =>
      'השרת סירב. הורדת סביבת עבודה דורשת תפקיד מנהל, שחזור דורש בעלים, ותמונת מצב שלמה דורשת את מפעיל ההתקנה.';

  @override
  String get backupTransferUnsupported => 'לשרת הזה אין משטח גיבוי.';

  @override
  String get backupTransferTooLarge => 'הקובץ גדול ממה שהשרת מקבל.';

  @override
  String get credentialGateWaitingTitle => 'ממתין לפרטי גישה';

  @override
  String credentialGateHarnessTitle(String provider) {
    return 'ל-$provider אין פרטי גישה';
  }

  @override
  String get credentialGateSignedOutTitle => 'Claude Code מנותק';

  @override
  String get credentialGateExpiredTitle => 'תוקף הכניסה שלכם ל-Claude Code פג';

  @override
  String get credentialGatePlanSpentTitle =>
      'הגעתם למגבלת התוכנית של Claude Code';

  @override
  String credentialGateWaitingAgent(String agent) {
    return '$agent ממתין להמשיך.';
  }

  @override
  String get credentialGateWaitingRun => 'הרצה ממתינה להמשיך.';

  @override
  String get credentialGateWatching => 'עוקב אחר התיקון — ההרצה תמשיך מעצמה.';

  @override
  String credentialGateFreesUpAt(String time) {
    return 'מתפנה ב-$time';
  }

  @override
  String credentialGateGivesUpAt(String time) {
    return 'ההרצה תוותר ב-$time';
  }

  @override
  String get credentialGateCheckAgain => 'בדיקה חוזרת';

  @override
  String get credentialGateCancelRun => 'ביטול ההרצה';

  @override
  String get credentialGateAccountsTried => 'חשבונות שנוסו';

  @override
  String get credentialGateClaudeSignInHint =>
      'היכנסו מהגדרות ← מתאמים ← Claude Code, או הריצו את פקודת הכניסה בטרמינל. ההרצה תקלוט זאת מעצמה.';

  @override
  String get credentialGateOpenSettings => 'פתיחת ההגדרות';

  @override
  String get selectModel => 'בחירת מודל';

  @override
  String get allModels => 'כל המודלים';

  @override
  String get noModelsMatchSearch => 'אין מודלים התואמים לחיפוש שלך';

  @override
  String useCustomModelId(String id) {
    return 'להשתמש ב-“$id”';
  }

  @override
  String get modelFree => 'חינם';

  @override
  String modelOutputTokens(String tokens) {
    return '$tokens פלט';
  }

  @override
  String modelPricePerMTokens(String input, String output) {
    return '$input קלט / $output פלט למיליון טוקנים';
  }

  @override
  String modelEffortLevels(String levels) {
    return 'מאמץ חשיבה: $levels';
  }

  @override
  String get modelSupportsReasoning => 'תומך במאמץ חשיבה';

  @override
  String get profileDeliveryMetrics => 'מדדי מסירה';

  @override
  String profileMetricsSample(int count) {
    return 'בקשות PR שנותחו: $count';
  }

  @override
  String get profileMergeRate => 'שיעור מיזוג';

  @override
  String get profileReviewCoverage => 'כיסוי סקירה';

  @override
  String get profilePrSize => 'גודל PR';

  @override
  String get profileTimeToMerge => 'זמן עד למיזוג';

  @override
  String get profileMergeTimeTrend => 'מגמת זמן המיזוג';

  @override
  String get profileWeeklyMedian => 'חציון שבועי, סולם לוגריתמי';

  @override
  String get profilePrOpeningPattern => 'יום בשבוע × שעה, זמן מקומי';

  @override
  String get profileFirstReview => 'זמן עד לסקירה הראשונה';

  @override
  String get profileMetricsTruncated =>
      'האחוזונים משתמשים במדגם מוגבל מבקשות המשיכה הזמינות.';

  @override
  String profileLinesChanged(String count) {
    return '$count שורות';
  }

  @override
  String profileDurationMinutes(int count) {
    return '$count דק׳';
  }

  @override
  String profileDurationHours(int count) {
    return '$count שע׳';
  }

  @override
  String profileDurationDaysHours(int days, int hours) {
    return '$daysי׳ $hoursש׳';
  }

  @override
  String profilePercentiles(String median, String p90) {
    return 'p50 $median · p90 $p90';
  }

  @override
  String profileTeamMembers(int count) {
    return 'חברים: $count';
  }

  @override
  String noPrsByTeamInWorkspace(String team) {
    return 'אין בקשות משיכה של $team במרחב העבודה הזה';
  }

  @override
  String get profilePrStateFilterLabel => 'סינון בקשות משיכה לפי מצב';

  @override
  String get noProfilePrsMatchSearchHint =>
      'נסו כותרת או מספר בקשת משיכה אחרים';

  @override
  String get rigNetworkUnrestricted => 'רשת ללא הגבלות';

  @override
  String get rigNetworkAllowAllHosts => 'מתן גישה לכל המארחים';

  @override
  String get rigBrowserPermissionsTitle => 'הרשאות אתר';

  @override
  String get rigBrowserPermissionsTooltip => 'הרשאות אתר ורשת';

  @override
  String get rigBrowserPermissionEmpty => 'אף אתר עדיין לא ביקש הרשאה';

  @override
  String rigBrowserPermissionPrompt(String origin, String permission) {
    return '$origin רוצה להשתמש ב$permission';
  }

  @override
  String get rigBrowserPermissionBlock => 'חסום';

  @override
  String get rigBrowserPermissionCamera => 'מצלמה';

  @override
  String get rigBrowserPermissionMicrophone => 'מיקרופון';

  @override
  String get rigBrowserPermissionNotifications => 'התראות';

  @override
  String get rigBrowserPermissionGeolocation => 'מיקום';

  @override
  String get rigBrowserPermissionPersistentStorage => 'אחסון קבוע';

  @override
  String get rigBrowserPermissionClipboard => 'לוח';

  @override
  String get rigBrowserPermissionDisplayCapture => 'צילום מסך';

  @override
  String get rigBrowserPermissionMidi => 'MIDI';

  @override
  String get rigNetworkBypassTitle => 'לאפשר כל מארח ברשת?';

  @override
  String get rigNetworkBypassBody =>
      'פעולה זו מפעילה מחדש את הסביבה המבודדת ומוחקת עבודה שלא נשמרה בתוכה. לאחר מכן המערכת האורחת תוכל לגשת לכל מארח ברשת עד לסגירתה.';

  @override
  String get rigNetworkRestartUnrestricted => 'הפעלה מחדש ללא הגבלות';

  @override
  String get rigNetworkUnrestrictedBody =>
      'סביבה מבודדת זו יכולה לגשת לכל מארח ברשת. יש לסגור אותה ולפתוח חדשה כדי לשחזר את הגבלות ברירת המחדל.';

  @override
  String get rigNetworkAlreadyUnrestrictedBody =>
      'אמולטור Android זה כבר מנהל את הרשת שלו בעצמו, ולכן Control Center אינו יכול לאכוף רשימת מארחים מורשים. אין צורך בהפעלה מחדש.';

  @override
  String get rigClipboardPermissionHostToRigTitle =>
      'להדביק את הלוח בסביבה הזו?';

  @override
  String get rigClipboardPermissionHostToRigBody =>
      'Control Center יקרא את הלוח של המכשיר שלך וישלח את התוכן שלו לסביבה. תוכן הלוח עשוי להכיל סיסמאות או סודות אחרים.';

  @override
  String get rigClipboardPermissionRigToHostTitle =>
      'להעתיק את הלוח מתוך הסביבה הזו?';

  @override
  String get rigClipboardPermissionRigToHostBody =>
      'Control Center יקרא את הלוח של הסביבה ויחליף את הלוח של המכשיר שלך בתוכן שלו. יש להתייחס לתוכן מהסביבה כלא מהימן.';

  @override
  String get rigClipboardAllowTenMinutes => 'לאפשר למשך 10 דקות';

  @override
  String get rigClipboardAlwaysAllow => 'לאפשר תמיד';

  @override
  String get rigClipboardSettingsTitle => 'גישה ללוח';

  @override
  String get rigClipboardSettingsHint =>
      'בחרו אילו העברות לוח יכולות לפעול ללא בקשה. הרשאות זמניות יפוגו לאחר 10 דקות.';

  @override
  String get rigClipboardAlwaysPasteTitle => 'לאפשר תמיד הדבקה לסביבות';

  @override
  String get rigClipboardAlwaysPasteDescription =>
      'שליחת הלוח של המכשיר הזה לכל סביבה ללא בקשה.';

  @override
  String get rigClipboardAlwaysCopyTitle => 'לאפשר תמיד העתקה מסביבות';

  @override
  String get rigClipboardAlwaysCopyDescription =>
      'הצבת תוכן לוח מכל סביבה במכשיר הזה ללא בקשה.';

  @override
  String get workspaceGitHubIdentity => 'זהות GitHub';

  @override
  String get workspaceGitHubIdentityDescription =>
      'איך עבודת GitHub ברקע מאומתת במרחב הזה. ירושת ה-App של ההתקנה, App אחר, או אסימון גישה אישי בלבד.';

  @override
  String get workspaceGitHubModeInherit => 'להשתמש ב-GitHub App של ההתקנה הזו';

  @override
  String get workspaceGitHubModeApp => 'להשתמש ב-GitHub App אחר';

  @override
  String get workspaceGitHubModePat => 'אסימון גישה אישי בלבד';

  @override
  String get workspaceGitHubInheritHint =>
      'משתמש ב-GitHub App בשרת → אפליקציות ספק.';

  @override
  String get workspaceGitHubAppHint =>
      'זהות הבוט והסריקה של המרחב. חברים נכנסים ב\"אתה\" דרך ה-App הזה.';

  @override
  String get workspaceGitHubPatLabel => 'אסימון רקע';

  @override
  String get workspaceGitHubPatDescription =>
      'לסריקה ולסוכנים במרחב הזה. לא אסימון הפרופיל של חבר.';

  @override
  String get workspaceGitHubHasPat => 'אסימון רקע שמור.';

  @override
  String get workspaceGitHubNoPat => 'אין אסימון רקע שמור.';

  @override
  String get profileOverlayHint =>
      'השדות האלה הם אתה במרחב הזה. שדות ריקים יורשים שם ואימייל מהחשבון. החלפת מרחב מחליפה את השכבה.';

  @override
  String get forgeConnectionsThisWorkspace =>
      'היכנסו או הדביקו אסימון למרחב העבודה הזה.';
}
