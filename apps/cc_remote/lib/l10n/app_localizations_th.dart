// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'กลับ';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get retry => 'ลองใหม่';

  @override
  String get tryAgain => 'ลองอีกครั้ง';

  @override
  String get settings => 'การตั้งค่า';

  @override
  String get refresh => 'รีเฟรช';

  @override
  String get approve => 'อนุมัติ';

  @override
  String get deny => 'ปฏิเสธ';

  @override
  String get continueLabel => 'ดำเนินการต่อ';

  @override
  String get agentQuestionHeader => 'คำถามสำหรับคุณ';

  @override
  String get agentQuestionAnsweredLabel => 'ตอบแล้ว';

  @override
  String get agentQuestionSkip => 'ข้าม';

  @override
  String get agentQuestionSkippedLabel => 'ข้ามแล้ว';

  @override
  String get agentQuestionFreeformHint => 'พิมพ์คำตอบของคุณ…';

  @override
  String get agentApprovalRequired => 'ต้องอนุมัติ';

  @override
  String get approveAndRemember => 'อนุมัติ 8 ชั่วโมง';

  @override
  String get decline => 'ปฏิเสธ';

  @override
  String get confirm => 'ยืนยัน';

  @override
  String get send => 'ส่ง';

  @override
  String get close => 'ปิด';

  @override
  String get expand => 'ขยาย';

  @override
  String get zoomIn => 'ซูมเข้า';

  @override
  String get zoomOut => 'ซูมออก';

  @override
  String get resetZoom => 'รีเซ็ตซูม';

  @override
  String get scanQrPrompt =>
      'สแกนรหัส QR จาก Control Center เพื่อจับคู่โทรศัพท์นี้';

  @override
  String get scanQrHelp =>
      'เปิดกล้องแล้วเล็งไปที่ QR ที่แสดงใน Control Center โทรศัพท์นี้เชื่อมต่อโดยตรงผ่านลิงก์ส่วนตัว';

  @override
  String get connectingToMac => 'กำลังเชื่อมต่อกับ Control Center…';

  @override
  String get connectingDetail => 'กำลังสร้างลิงก์โดยตรงที่ปลอดภัย';

  @override
  String get identityChangedTitle => 'ตัวตนของเซิร์ฟเวอร์เปลี่ยนแล้ว';

  @override
  String get identityChangedBody =>
      'เซิร์ฟเวอร์นี้ไม่ตรงกับตัวตนที่บันทึกตอนจับคู่ อาจหมายความว่าเซิร์ฟเวอร์ถูกติดตั้งใหม่ — หรือมีสิ่งใดกำลังดักการเชื่อมต่อ เพื่อความปลอดภัย อุปกรณ์นี้จะไม่เชื่อมต่อ ลบการจับคู่ แล้วสแกนรหัส QR ใหม่จาก Control Center เพื่อจับคู่อีกครั้ง';

  @override
  String get removePairing => 'ลบการจับคู่';

  @override
  String get couldntConnect => 'เชื่อมต่อไม่ได้';

  @override
  String get pendingPairingTitle => 'เชื่อมต่อเซิร์ฟเวอร์นี้หรือไม่?';

  @override
  String get pendingPairingBody =>
      'มีลิงก์ขอให้ Control Center จับคู่กับเซิร์ฟเวอร์นี้ ดำเนินการต่อเฉพาะเมื่อคุณเป็นผู้เริ่มเอง';

  @override
  String get connect => 'เชื่อมต่อ';

  @override
  String get failureNotPaired =>
      'ยังไม่ได้จับคู่ — สแกนรหัส QR จาก Control Center';

  @override
  String get failureUnreachable =>
      'เข้าถึงเซิร์ฟเวอร์ไม่ได้ทุกเส้นทาง — ตรวจว่าเซิร์ฟเวอร์กำลังทำงาน หรือลองเครือข่ายเดียวกัน';

  @override
  String get failureIdentityChanged =>
      'ตัวตนของเซิร์ฟเวอร์เปลี่ยนแล้ว — หากติดตั้งใหม่ ให้จับคู่อุปกรณ์นี้อีกครั้ง';

  @override
  String get failureAuthRejected =>
      'เซิร์ฟเวอร์ปฏิเสธอุปกรณ์นี้ — จับคู่ใหม่จาก Control Center';

  @override
  String get failureUnknown => 'เชื่อมต่อไม่ได้ — แตะเพื่อลองใหม่';

  @override
  String get statusConnected => 'เชื่อมต่อแล้ว';

  @override
  String get statusConnecting => 'กำลังเชื่อมต่อ';

  @override
  String get statusOffline => 'ออฟไลน์';

  @override
  String get statusIdentityMismatch => 'ตัวตนไม่ตรง';

  @override
  String get statusNotPaired => 'ยังไม่ได้จับคู่';

  @override
  String get statusConfirmPairing => 'ยืนยันการจับคู่';

  @override
  String get connectionFailed => 'การเชื่อมต่อล้มเหลว';

  @override
  String get identityMismatchBanner =>
      'ตัวตนของเซิร์ฟเวอร์เปลี่ยนแล้ว — หยุดการเชื่อมต่อแล้ว จับคู่อุปกรณ์นี้อีกครั้งเพื่อดำเนินการต่อ';

  @override
  String get tabInbox => 'อินบ็อกซ์';

  @override
  String get tabTickets => 'ทิกเก็ต';

  @override
  String get tabChat => 'แชท';

  @override
  String get tabPrs => 'PRs';

  @override
  String get tabCalendar => 'ปฏิทิน';

  @override
  String get tabNews => 'ข่าว';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label รอ $count รายการ';
  }

  @override
  String get updateAvailable => 'มี Control Center เวอร์ชันใหม่แล้ว';

  @override
  String get appearance => 'ลักษณะ';

  @override
  String get language => 'ภาษา';

  @override
  String get device => 'อุปกรณ์';

  @override
  String get themeSystem => 'ระบบ';

  @override
  String get themeLight => 'สว่าง';

  @override
  String get themeDark => 'มืด';

  @override
  String get languageSystem => 'ระบบ';

  @override
  String get disconnectTapAgain =>
      'แตะอีกครั้งเพื่อยกเลิกการเชื่อมต่ออุปกรณ์นี้จาก Control Center';

  @override
  String get disconnectDevice => 'ยกเลิกการเชื่อมต่ออุปกรณ์นี้';

  @override
  String get disconnect => 'ยกเลิกการเชื่อมต่อ';

  @override
  String get chooseWorkspace => 'เลือกเวิร์กสเปซ';

  @override
  String get workspaces => 'เวิร์กสเปซ';

  @override
  String get workspacesLoadFailed => 'โหลดเวิร์กสเปซไม่ได้';

  @override
  String get noWorkspacesYet => 'ยังไม่มีเวิร์กสเปซ';

  @override
  String selectWorkspace(String name) {
    return 'เลือก $name';
  }

  @override
  String get inboxLoadFailed => 'โหลดอินบ็อกซ์ไม่ได้';

  @override
  String get allCaughtUp => 'ตามทันหมดแล้ว';

  @override
  String get inboxNoForgeAccount =>
      'เซิร์ฟเวอร์ยังไม่ได้เชื่อมต่อบัญชี forge จึงยังระบุพูลรีเควสต์ให้คุณไม่ได้';

  @override
  String get inboxNothingWaiting =>
      'ไม่มีรายการถูกบล็อก และไม่มีพูลรีเควสต์รอคุณ';

  @override
  String get blocked => 'ถูกบล็อก';

  @override
  String get sectionNeedsYourReview => 'รอรีวิวจากคุณ';

  @override
  String get sectionReturnedToYou => 'ส่งกลับมาให้คุณ';

  @override
  String get sectionApprovedAndReady => 'อนุมัติแล้ว พร้อมรวม';

  @override
  String get sectionYourDrafts => 'ฉบับร่างของคุณ';

  @override
  String get sectionWaitingForReviewers => 'รอผู้รีวิว';

  @override
  String get sectionMergingAndMerged => 'กำลังรวมและเพิ่งรวมแล้ว';

  @override
  String get sectionWaitingForAuthor => 'รอผู้เขียน';

  @override
  String waitingAgo(String ago) {
    return 'รอมา $ago';
  }

  @override
  String get openConversation => 'เปิดการสนทนา';

  @override
  String get calendarLoadFailed => 'โหลดปฏิทินไม่ได้';

  @override
  String get nothingScheduled => 'ไม่มีตาราง';

  @override
  String get calendarEmptyDescription =>
      'เหตุการณ์จากปฏิทินที่เชื่อมต่อจะปรากฏที่นี่';

  @override
  String get agenda => 'วาระ';

  @override
  String get syncCalendarsNow => 'ซิงค์ปฏิทินตอนนี้';

  @override
  String get event => 'เหตุการณ์';

  @override
  String get eventNotFound => 'ไม่พบเหตุการณ์';

  @override
  String get eventNotFoundDescription =>
      'อาจอยู่นอกช่วงวาระ หรือถูกลบที่ต้นทาง';

  @override
  String get joinMeeting => 'เข้าร่วมการประชุม';

  @override
  String get join => 'เข้าร่วม';

  @override
  String attendeesCount(int count) {
    return 'ผู้เข้าร่วม ($count)';
  }

  @override
  String get details => 'รายละเอียด';

  @override
  String get allDay => 'ทั้งวัน';

  @override
  String get happeningNow => 'กำลังดำเนินอยู่';

  @override
  String inDuration(String duration) {
    return 'อีก $duration';
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
  String get attendeeAccepted => 'ตอบรับ';

  @override
  String get attendeeDeclined => 'ปฏิเสธ';

  @override
  String get attendeeMaybe => 'อาจไป';

  @override
  String get attendeeNoReply => 'ยังไม่ตอบ';

  @override
  String get organizer => 'ผู้จัด';

  @override
  String get calendarNoAccounts =>
      'เวิร์กสเปซนี้ยังไม่ได้เชื่อมต่อปฏิทิน เชื่อมต่อจากแอปเดสก์ท็อป — การลงชื่อเข้าใช้จะเก็บโทเค็นไว้บนเซิร์ฟเวอร์';

  @override
  String get calendarReauthNeeded =>
      'ต้องเชื่อมต่อบัญชีปฏิทินอีกครั้ง — ข้อมูลด้านล่างอาจไม่เป็นปัจจุบัน เชื่อมต่อใหม่จากแอปเดสก์ท็อป';

  @override
  String get spacesLoadFailed => 'โหลดสเปซไม่ได้';

  @override
  String get noSpaces => 'ไม่มีสเปซ';

  @override
  String get spacesEmptyDescription => 'สเปซในเวิร์กสเปซนี้จะปรากฏที่นี่';

  @override
  String get thread => 'เธรด';

  @override
  String get agentWorking => 'เอเจนต์กำลังทำงาน';

  @override
  String get messagesLoadFailed => 'โหลดข้อความไม่ได้';

  @override
  String get noMessagesYet => 'ยังไม่มีข้อความ';

  @override
  String get noMessagesDescription => 'ส่งข้อความเพื่อเริ่มการสนทนา';

  @override
  String get agentResponding => 'เอเจนต์กำลังตอบ';

  @override
  String get agentFinished => 'เอเจนต์ทำงานเสร็จแล้ว';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names มีขนาดใหญ่เกินไปที่จะส่งจากที่นี่',
      one: '$names มีขนาดใหญ่เกินไปที่จะส่งจากที่นี่',
    );
    return '$_temp0';
  }

  @override
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names มีขนาดใหญ่เกินไปที่จะส่งผ่านรีเลย์จากที่นี่',
      one: '$names มีขนาดใหญ่เกินไปที่จะส่งผ่านรีเลย์จากที่นี่',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed => 'อัปโหลดไฟล์แนบไม่ได้ ลองอีกครั้ง';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'อัปโหลดไฟล์แนบ $count รายการไม่ได้จึงถูกตัดออก',
      one: 'อัปโหลดไฟล์แนบ 1 รายการไม่ได้จึงถูกตัดออก',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'เพื่อนร่วมทีม';

  @override
  String get agent => 'เอเจนต์';

  @override
  String get attachFile => 'แนบไฟล์';

  @override
  String get messageHint => 'ข้อความ';

  @override
  String removeAttachment(String name) {
    return 'นำ $name ออก';
  }

  @override
  String get articlesLoadFailed => 'โหลดบทความไม่ได้';

  @override
  String get noArticles => 'ไม่มีบทความ';

  @override
  String get articlesEmptyDescription =>
      'บทความใหม่จะปรากฏที่นี่เมื่อฟีดอัปเดต';

  @override
  String get unread => 'ยังไม่ได้อ่าน';

  @override
  String get allFeeds => 'ทุกฟีด';

  @override
  String get save => 'บันทึก';

  @override
  String get unsave => 'เลิกบันทึก';

  @override
  String get readFullArticle => 'อ่านบทความเต็ม';

  @override
  String get ticketsLoadFailed => 'โหลดทิกเก็ตไม่ได้';

  @override
  String get noTickets => 'ไม่มีทิกเก็ต';

  @override
  String get ticketsEmptyDescription => 'ทิกเก็ตในเวิร์กสเปซนี้จะปรากฏที่นี่';

  @override
  String get all => 'ทั้งหมด';

  @override
  String get ticket => 'ทิกเก็ต';

  @override
  String get ticketLoadFailed => 'โหลดทิกเก็ตไม่ได้';

  @override
  String assignedTo(String name) {
    return 'มอบหมายให้ $name';
  }

  @override
  String get openInBrowser => 'เปิดในเบราว์เซอร์';

  @override
  String get status => 'สถานะ';

  @override
  String get assign => 'มอบหมาย';

  @override
  String get reassign => 'มอบหมายใหม่';

  @override
  String get noAgents => 'ไม่มีเอเจนต์';

  @override
  String get noAgentsDescription => 'มอบหมายเอเจนต์จากเวิร์กสเปซนี้';

  @override
  String get statusOpen => 'เปิด';

  @override
  String get statusInProgress => 'กำลังดำเนินการ';

  @override
  String get statusBlocked => 'ถูกบล็อก';

  @override
  String get statusInReview => 'กำลังรีวิว';

  @override
  String get statusDone => 'เสร็จแล้ว';

  @override
  String get statusBacklog => 'แบ็กล็อก';

  @override
  String get lensNeedsMe => 'รอฉัน';

  @override
  String get lensMine => 'ของฉัน';

  @override
  String get prsLoadFailed => 'โหลดพูลรีเควสต์ไม่ได้';

  @override
  String get noOpenPullRequests => 'ไม่มีพูลรีเควสต์ที่เปิดอยู่';

  @override
  String get nothingWaitingOnReview => 'ไม่มีรายการรอรีวิวจากคุณ';

  @override
  String get noOwnOpenPullRequests => 'คุณไม่มีพูลรีเควสต์ที่เปิดอยู่';

  @override
  String get nothingBlocked => 'ไม่มีรายการถูกบล็อก';

  @override
  String get prsEmptyDescription =>
      'พูลรีเควสต์จากรีโปในเวิร์กสเปซนี้จะปรากฏที่นี่';

  @override
  String get refreshPullRequests => 'รีเฟรชพูลรีเควสต์';

  @override
  String get noForgeConnected =>
      'เซิร์ฟเวอร์ยังไม่ได้เชื่อมต่อ forge จึงดึงพูลรีเควสต์ไม่ได้ เชื่อมต่อจากแอปเดสก์ท็อป';

  @override
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'อ่านรีโป $count รายการไม่ได้',
      one: 'อ่านรีโป 1 รายการไม่ได้',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return 'อ่านไม่ได้: $names';
  }

  @override
  String get installationSuspendedTitle => 'การติดตั้ง GitHub App ถูกระงับ';

  @override
  String installationSuspendedBody(String names) {
    return 'กำลังแสดงข้อมูลล่าสุดที่ทราบของ $names โปรดดำเนินการติดตั้งต่อบน GitHub หรือเชื่อมต่อโทเค็นที่มีสิทธิ์เข้าถึง';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'การติดตั้ง GitHub App ถูกระงับ. กำลังแสดงข้อมูลล่าสุดที่ทราบของ $names โปรดดำเนินการติดตั้งต่อบน GitHub หรือเชื่อมต่อโทเค็นที่มีสิทธิ์เข้าถึง';
  }

  @override
  String get draft => 'ฉบับร่าง';

  @override
  String get merged => 'รวมแล้ว';

  @override
  String get closed => 'ปิดแล้ว';

  @override
  String get open => 'เปิด';

  @override
  String get approved => 'อนุมัติแล้ว';

  @override
  String get changesRequested => 'ขอให้แก้ไข';

  @override
  String get reviewRequired => 'ต้องรีวิว';

  @override
  String get checksPassing => 'การตรวจผ่าน';

  @override
  String get checksFailing => 'การตรวจไม่ผ่าน';

  @override
  String get checksRunning => 'กำลังตรวจ';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => 'พูลรีเควสต์';

  @override
  String get prLoadFailed => 'โหลดพูลรีเควสต์นี้ไม่ได้';

  @override
  String get openOnForge => 'เปิดบน forge';

  @override
  String get requestChangesNeedsComment =>
      'เพิ่มความคิดเห็นอธิบายว่าต้องเปลี่ยนอะไร';

  @override
  String get conversation => 'การสนทนา';

  @override
  String get files => 'ไฟล์';

  @override
  String get checks => 'การตรวจ';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ไฟล์',
      one: '1 ไฟล์',
    );
    return '$_temp0';
  }

  @override
  String commitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count คอมมิต',
      one: '1 คอมมิต',
    );
    return '$_temp0';
  }

  @override
  String get conflicts => 'คอนฟลิกต์';

  @override
  String get reviewers => 'ผู้รีวิว';

  @override
  String get noDescriptionNoComments => 'ยังไม่มีคำอธิบายและความคิดเห็น';

  @override
  String get noChangedFiles => 'ไม่มีไฟล์ที่เปลี่ยน';

  @override
  String get noChecksReported => 'ไม่มีการตรวจสำหรับคอมมิตหัว';

  @override
  String get reviewCommentHint => 'เขียนความคิดเห็นรีวิว…';

  @override
  String get comment => 'ความคิดเห็น';

  @override
  String get commentPosted => 'โพสต์ความคิดเห็นแล้ว';

  @override
  String get request => 'ขอแก้ไข';

  @override
  String get squashAndMerge => 'สควอชแล้วรวม';

  @override
  String noActionsAvailable(String status) {
    return '$status — ไม่มีคำสั่งที่ใช้ได้';
  }

  @override
  String get reviewApproved => 'อนุมัติแล้ว';

  @override
  String get reviewRequestedChanges => 'ขอให้แก้ไข';

  @override
  String get reviewCommented => 'รีวิวแล้ว';

  @override
  String get reviewPending => 'รอดำเนินการ';

  @override
  String get unknownAuthor => 'ไม่ทราบ';

  @override
  String hideDiffFor(String file) {
    return 'ซ่อน diff ของ $file';
  }

  @override
  String showDiffFor(String file) {
    return 'แสดง diff ของ $file';
  }

  @override
  String get checkRunning => 'กำลังรัน';

  @override
  String get checkPassed => 'ผ่าน';

  @override
  String get checkFailed => 'ไม่ผ่าน';

  @override
  String get checkCancelled => 'ยกเลิกแล้ว';

  @override
  String get checkSkipped => 'ข้าม';

  @override
  String labelWithDuration(String label, String duration) {
    return '$label · $duration';
  }

  @override
  String checkSemanticLabel(String name, String state) {
    return '$name, $state';
  }

  @override
  String get noTextDiff =>
      'ไม่มี diff ข้อความสำหรับไฟล์นี้ — เป็นไบนารี หรือใหญ่เกินกว่าที่ forge จะส่งกลับ';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'แสดงอีก $count บรรทัด',
      one: 'แสดงบรรทัดที่เหลือ',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count บรรทัดที่ไม่เปลี่ยน',
      one: '1 บรรทัดที่ไม่เปลี่ยน',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'ไปยังล่าสุด';

  @override
  String get streaming => 'กำลังสตรีม';

  @override
  String get working => 'กำลังทำงาน';

  @override
  String get input => 'อินพุต';

  @override
  String get output => 'เอาต์พุต';

  @override
  String get now => 'ตอนนี้';

  @override
  String agoMinutes(int count) {
    return '$count นาที';
  }

  @override
  String agoHours(int count) {
    return '$count ชม.';
  }

  @override
  String agoDays(int count) {
    return '$count วัน';
  }

  @override
  String get today => 'วันนี้';

  @override
  String get tomorrow => 'พรุ่งนี้';

  @override
  String get yesterday => 'เมื่อวาน';

  @override
  String durationMinutes(int count) {
    return '$count นาที';
  }

  @override
  String durationHours(int count) {
    return '$count ชม.';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours ชม. $minutes นาที';
  }
}
