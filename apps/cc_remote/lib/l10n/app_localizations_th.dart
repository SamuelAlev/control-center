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
  String get copyCommand => 'คัดลอกคำสั่ง';

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
  String get newSpaceFolder => 'โฟลเดอร์ใหม่';

  @override
  String get folderName => 'ชื่อโฟลเดอร์';

  @override
  String get renameSpaceFolder => 'เปลี่ยนชื่อโฟลเดอร์';

  @override
  String get deleteSpaceFolder => 'ลบโฟลเดอร์';

  @override
  String get moveSpaceToFolder => 'ย้ายไปยังโฟลเดอร์';

  @override
  String get removeSpaceFromFolder => 'นำออกจากโฟลเดอร์';

  @override
  String get spaceFolderActions => 'การดำเนินการของโฟลเดอร์';

  @override
  String get deleteFolderWithSpacesWarning =>
      'การลบพื้นที่อย่างถาวรจะนำข้อความและไดเรกทอรีงานของพื้นที่ออกสำหรับทุกคน ไม่สามารถยกเลิกการดำเนินการนี้ได้';

  @override
  String get deleteSpacesInFolder => 'ลบพื้นที่ในโฟลเดอร์นี้อย่างถาวร';

  @override
  String get deleteFolderAndSpaces => 'ลบโฟลเดอร์และพื้นที่';

  @override
  String get keepSpacesInFolder => 'มิฉะนั้น พื้นที่จะยังคงอยู่นอกโฟลเดอร์';

  @override
  String get create => 'สร้าง';

  @override
  String get otherSpaces => 'พื้นที่อื่น ๆ';

  @override
  String get folderUpdateFailed => 'อัปเดตโฟลเดอร์ไม่ได้';

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

  @override
  String get mobileConversations => 'การสนทนา';

  @override
  String get mobileNewConversation => 'การสนทนาใหม่';

  @override
  String get mobileConversationName => 'ชื่อการสนทนา';

  @override
  String get mobileRename => 'เปลี่ยนชื่อ';

  @override
  String get mobileManageSpace => 'จัดการสเปซ';

  @override
  String get mobileArchived => 'เก็บถาวรแล้ว';

  @override
  String get mobileSearchMessages => 'ค้นหาข้อความทั้งหมดในสเปซนี้';

  @override
  String get mobileSearch => 'ค้นหา';

  @override
  String get mobileNoResults => 'ไม่พบผลลัพธ์';

  @override
  String get mobileReopen => 'เปิดอีกครั้ง';

  @override
  String get mobileArchive => 'เก็บถาวร';

  @override
  String get mobileProgress => 'ความคืบหน้าและบริบท';

  @override
  String get mobileReadFailed => 'ทำเครื่องหมายการสนทนานี้ว่าอ่านแล้วไม่ได้';

  @override
  String get mobileSendFailed => 'ส่งข้อความไม่สำเร็จ ฉบับร่างของคุณยังอยู่';

  @override
  String get sentAttachmentUnavailable => 'ไฟล์แนบไม่พร้อมใช้งาน';

  @override
  String get sentAttachmentLoadFailed => 'โหลดไฟล์แนบไม่ได้';

  @override
  String get mobileActionFailed => 'การกระทำล้มเหลว';

  @override
  String get mobileRemove => 'ลบออก';

  @override
  String get mobileLinkedMessage => 'ข้อความที่ลิงก์ไว้';

  @override
  String get mobileOlderMessages => 'ข้อความก่อนหน้า';

  @override
  String get mobileMessageActions => 'การดำเนินการกับข้อความ';

  @override
  String get mobileOpenThread => 'เปิดเธรด';

  @override
  String get mobileCopyLink => 'คัดลอกลิงก์';

  @override
  String get mobileStopRun => 'หยุดรัน';

  @override
  String get mobileStopRunConfirm =>
      'หยุดการรันของเอเจนต์นี้ไหม? งานที่เสร็จแล้วจะยังคงอยู่';

  @override
  String get mobileControlUnsupported =>
      'การรันนี้สิ้นสุดแล้วหรือไม่รองรับการควบคุมนี้';

  @override
  String get mobilePauseRequested =>
      'ส่งคำขอให้หยุดชั่วคราวเมื่อจบรอบปัจจุบันแล้ว';

  @override
  String get mobileResumed => 'รันต่อแล้ว';

  @override
  String get mobileStopRequested => 'ส่งคำขอหยุดแล้ว';

  @override
  String get mobileQueuedMessages => 'ข้อความที่คิวไว้';

  @override
  String get mobilePauseRun => 'หยุดชั่วคราวก่อนรอบถัดไป';

  @override
  String get mobileResumeRun => 'ทำต่อ';

  @override
  String get mobileEditQueued => 'แก้ไขข้อความที่คิว';

  @override
  String get mobileSteerNow => 'ปรับทิศทางทันที';

  @override
  String get mobileMoveUp => 'ย้ายขึ้น';

  @override
  String get mobileMoveDown => 'ย้ายลง';

  @override
  String get mobileQueueChanged =>
      'คิวมีการเปลี่ยนแปลง หรือการรันนี้ไม่รองรับการปรับทิศทางขณะรัน รีเฟรชแล้วลองอีกครั้ง';

  @override
  String get mobileActivity => 'กิจกรรม';

  @override
  String get mobilePermissions => 'สิทธิ์และบันทึกการตรวจสอบ';

  @override
  String get mobilePlans => 'แผน';

  @override
  String get mobileGoals => 'เป้าหมายภายใต้การดูแล';

  @override
  String get mobileCredentials => 'การเชื่อมต่อและข้อมูลรับรอง';

  @override
  String get mobileWorkspaceUnavailable =>
      'เวิร์กสเปซนี้ไม่พร้อมใช้งาน หรือคุณไม่มีสิทธิ์เข้าถึงแล้ว';

  @override
  String get mobilePrReviewThreads => 'เธรดรีวิว';

  @override
  String get mobilePrThreadsLoadFailed => 'โหลดเธรดรีวิวไม่ได้';

  @override
  String get mobilePrNoReviewThreads => 'ยังไม่มีเธรดรีวิวแบบระบุบรรทัด';

  @override
  String get mobilePrCommentPermissionDenied =>
      'คุณไม่มีสิทธิ์แสดงความคิดเห็นในรีโพสิทอรีนี้';

  @override
  String get mobilePrPermissionChecking => 'กำลังตรวจสอบสิทธิ์แสดงความคิดเห็น…';

  @override
  String get mobilePrPermissionLoadFailed =>
      'ตรวจสอบสิทธิ์แสดงความคิดเห็นไม่ได้ ลองอีกครั้งเพื่อแสดงความคิดเห็น';

  @override
  String mobilePrThreadLine(String side, String line) {
    return '$side บรรทัด $line';
  }

  @override
  String get mobilePrOriginalSide => 'ต้นฉบับ';

  @override
  String get mobilePrSelectCommentLine =>
      'เลือกบรรทัดที่ต้องการแสดงความคิดเห็น';

  @override
  String get mobilePrUpdatedSide => 'อัปเดตแล้ว';

  @override
  String get mobilePrThreadResolved => 'ปิดแล้ว';

  @override
  String get mobilePrReplyHint => 'เขียนคำตอบ…';

  @override
  String get mobilePrCommentRequired => 'เขียนความคิดเห็นก่อนโพสต์';

  @override
  String get mobilePrReply => 'ตอบกลับ';

  @override
  String get mobilePrReopenThread => 'เปิดเธรดอีกครั้ง';

  @override
  String get mobilePrResolveThread => 'ปิดเธรด';

  @override
  String get mobilePrResolvePermissionDenied =>
      'เฉพาะผู้สร้าง pull request หรือผู้ที่มีสิทธิ์เขียนเท่านั้นที่ปิดเธรดนี้ได้';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return 'แสดงความคิดเห็นที่ $side บรรทัด $line';
  }

  @override
  String get mobilePrInlineCommentHint => 'เขียนความคิดเห็นในบรรทัด…';

  @override
  String get mobilePrPostInlineComment => 'โพสต์ความคิดเห็น';

  @override
  String get mobilePrCommentUnavailable =>
      'แสดงความคิดเห็นในบรรทัดสำหรับ pull request นี้ไม่ได้';

  @override
  String get mobilePrPatchUnavailable =>
      'แพลตฟอร์มโฮสต์โค้ดไม่ได้ให้แพตช์แบบข้อความสำหรับไฟล์นี้';

  @override
  String get mobilePrNoPatchForFile => 'ไม่มีแพตช์สำหรับไฟล์นี้';

  @override
  String get mobileTicketNew => 'ตั๋วงานใหม่';

  @override
  String get mobileTicketCreate => 'สร้างตั๋วงาน';

  @override
  String get mobileTicketEdit => 'แก้ไขตั๋วงาน';

  @override
  String get mobileTicketTitle => 'ชื่อ';

  @override
  String get mobileTicketTitleRequired => 'ป้อนชื่อเพื่อบันทึกตั๋วงานนี้';

  @override
  String get mobileTicketDescription => 'คำอธิบาย';

  @override
  String get mobileTicketMarkdownHint => 'เพิ่มรายละเอียดในรูปแบบ Markdown';

  @override
  String get mobileTicketPriority => 'ลำดับความสำคัญ';

  @override
  String get mobileTicketPriorityNone => 'ไม่ระบุลำดับความสำคัญ';

  @override
  String get mobileTicketPriorityUrgent => 'เร่งด่วน';

  @override
  String get mobileTicketPriorityHigh => 'สูง';

  @override
  String get mobileTicketPriorityMedium => 'ปานกลาง';

  @override
  String get mobileTicketPriorityLow => 'ต่ำ';

  @override
  String get mobileTicketLabels => 'ป้ายกำกับ';

  @override
  String get mobileTicketLabelsHint => 'หนึ่งป้ายกำกับต่อบรรทัด';

  @override
  String get mobileTicketLabelsHelp => 'ป้อนป้ายกำกับแต่ละรายการแยกบรรทัด';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return 'บันทึกไว้ใน $provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => 'ยังไม่มอบหมาย';

  @override
  String get mobileTicketAssignedFilter => 'มอบหมายแล้ว';

  @override
  String get mobileTicketAgentsLoadFailed => 'โหลดเอเจนต์ไม่ได้';

  @override
  String get mobileTicketSearch => 'ค้นหาตั๋วงาน';

  @override
  String get mobileTicketSearchHint =>
      'ชื่อ รหัส คำอธิบาย ป้ายกำกับ หรือผู้รับมอบหมาย';

  @override
  String get mobileTicketClearSearch => 'ล้างการค้นหาตั๋วงาน';

  @override
  String get mobileTicketNoMatches => 'ไม่พบตั๋วงานที่ตรงกัน';

  @override
  String get mobileTicketAdjustFilters =>
      'ลองค้นหาด้วยคำอื่นหรือเปลี่ยนตัวกรอง';

  @override
  String get mobileTicketClearFilters => 'ล้างตัวกรอง';

  @override
  String get mobileTicketNotFound => 'ไม่พบตั๋วงาน';

  @override
  String get mobileTicketNotFoundDescription =>
      'ตั๋วงานนี้อาจถูกลบหรือย้ายออกจากเวิร์กสเปซนี้แล้ว';

  @override
  String get mobileTicketWorkspaceChanged =>
      'เวิร์กสเปซเปลี่ยนไปแล้ว กลับไปที่เวิร์กสเปซปัจจุบันก่อนบันทึก';

  @override
  String get mobileTicketOpenLinkedSpace => 'เปิดสเปซที่ลิงก์ไว้';

  @override
  String get mobileTicketReadOnly =>
      'ต้องมีบทบาทสมาชิกเวิร์กสเปซจึงจะเปลี่ยนแปลงตั๋วงานได้';

  @override
  String get permissionTitle => 'สิทธิ์';

  @override
  String get permissionWorkspaceFailed => 'โหลดเวิร์กสเปซไม่ได้';

  @override
  String get permissionNoWorkspace => 'เลือกเวิร์กสเปซเพื่อตรวจสอบสิทธิ์';

  @override
  String get permissionLoading => 'กำลังโหลดสิทธิ์…';

  @override
  String get permissionScopeDescription =>
      'ตรวจสอบวิธีตัดสินแต่ละการกระทำในขอบเขตนี้ เอเจนต์และสเปซสามารถสืบทอดกฎของเวิร์กสเปซได้';

  @override
  String get permissionScope => 'ขอบเขตนโยบาย';

  @override
  String get permissionWorkspaceScope => 'เวิร์กสเปซ';

  @override
  String get permissionAgentScope => 'เอเจนต์';

  @override
  String get permissionSpaceScope => 'สเปซ';

  @override
  String get permissionAgentContext => 'เอเจนต์ที่ทำงานในสเปซนี้';

  @override
  String get permissionNoAgentContext => 'ยังไม่ได้เลือกเอเจนต์';

  @override
  String get permissionTargetsFailed => 'โหลดเป้าหมายของขอบเขตไม่ได้';

  @override
  String get permissionNoTargets => 'ไม่มีเป้าหมายในขอบเขตนี้';

  @override
  String get permissionRoleFailed => 'ยืนยันบทบาทของคุณในเวิร์กสเปซไม่ได้';

  @override
  String get permissionMemberRequired =>
      'ต้องมีบทบาทสมาชิกเวิร์กสเปซจึงจะดูกฎนโยบายได้';

  @override
  String get permissionRulesFailed => 'โหลดกฎนโยบายไม่ได้';

  @override
  String get permissionAuditAdminOnly =>
      'เฉพาะผู้ดูแลเวิร์กสเปซเท่านั้นที่ดูประวัติการอนุญาตได้';

  @override
  String get permissionAllow => 'อนุญาต';

  @override
  String get permissionAsk => 'ถามก่อน';

  @override
  String get permissionDeny => 'ปฏิเสธ';

  @override
  String get permissionFileDelete => 'ลบไฟล์';

  @override
  String get permissionFileWriteOutsideWorktree => 'เขียนนอกเวิร์กทรี';

  @override
  String get permissionGitCommit => 'คอมมิตการเปลี่ยนแปลง';

  @override
  String get permissionGitPush => 'พุชคอมมิต';

  @override
  String get permissionPrCreate => 'สร้าง pull request';

  @override
  String get permissionPrPublish => 'เผยแพร่ pull request';

  @override
  String get permissionVendorSyncWrite => 'เขียนไปยังตัวติดตามภายนอก';

  @override
  String get permissionNetworkEgress => 'เข้าถึงเครือข่าย';

  @override
  String get permissionSecretAccess => 'อ่านความลับ';

  @override
  String get permissionPackageInstall => 'ติดตั้งแพ็กเกจ';

  @override
  String get permissionProcessSpawn => 'สร้างโปรเซส';

  @override
  String get permissionWorkspaceMutation => 'เปลี่ยนแปลงเวิร์กสเปซ';

  @override
  String get permissionEnclosureControl => 'ควบคุมเอนโคลเจอร์ (ริก)';

  @override
  String get permissionChangeFailed => 'เปลี่ยนกฎไม่ได้';

  @override
  String get permissionEffectiveDescription =>
      'มีผลกับขอบเขตนี้เมื่อไม่มีอาร์กิวเมนต์ของการกระทำ การอนุญาตแบบมีเงื่อนไขด้านล่างใช้เฉพาะกับคำขอที่ตรงเงื่อนไข โดยเซิร์ฟเวอร์เป็นผู้ตัดสินขั้นสุดท้าย';

  @override
  String get permissionSpaceAgentNote =>
      'ยังไม่ได้เลือกเอเจนต์ กฎเฉพาะเอเจนต์จะไม่แสดงจนกว่าคุณจะเลือกเอเจนต์ด้านบน';

  @override
  String get permissionScopedGrants => 'กฎในขอบเขตนี้';

  @override
  String get permissionModePreset => 'พรีเซ็ตโหมด';

  @override
  String get permissionBuiltInDefault => 'ค่าเริ่มต้นในตัว';

  @override
  String get permissionRemembered => 'การอนุมัติที่จดจำไว้';

  @override
  String get permissionSource => 'ต้นฉบับ';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · ตั้งไว้ที่นี่';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · สืบทอด';
  }

  @override
  String permissionExpiresAt(String date) {
    return 'หมดอายุ $date';
  }

  @override
  String get permissionSetHere => 'ตั้งกฎที่นี่';

  @override
  String get permissionRevokeBeforeEdit =>
      'เพิกถอนกฎเฉพาะขอบเขตหรือกฎที่จดจำไว้ก่อนตั้งกฎทั่วไปสำหรับการกระทำนี้';

  @override
  String get permissionConfirmRevoke => 'ยืนยันการเพิกถอน';

  @override
  String get permissionRevokeRule => 'เพิกถอนกฎ';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'คำนำหน้าคำสั่ง: $prefix';
  }

  @override
  String get permissionNoExpiry => 'ไม่มีวันหมดอายุ';

  @override
  String get permissionExpired => 'หมดอายุแล้ว';

  @override
  String get permissionExplicitRule => 'กฎที่กำหนดไว้โดยตรง';

  @override
  String get permissionEnforcementAdvisory =>
      'โหมดแนะนำ: บันทึกกฎแบบถามก่อนโดยไม่แสดงคำถาม';

  @override
  String get permissionEnforcementSoft =>
      'บังคับใช้แบบยืดหยุ่น: ต้องได้รับอนุญาตจึงจะข้ามกฎได้';

  @override
  String get permissionEnforcementHard => 'บังคับใช้แบบเข้มงวด: ข้ามกฎไม่ได้';

  @override
  String permissionPaths(String paths) {
    return 'พาธ: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'การอ้างอิง Git: $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return 'โฮสต์: $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return 'คำสั่ง: $commands';
  }

  @override
  String permissionMaxCount(String count) {
    return 'จำนวนสูงสุด: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return 'จำนวนเซนต์สูงสุด: $cents';
  }

  @override
  String get permissionAuditHeading => 'ประวัติการอนุญาต';

  @override
  String get permissionAuditDescription =>
      'การตัดสินใจล่าสุดที่เซิร์ฟเวอร์บันทึกไว้ เฉพาะผู้ดูแลเวิร์กสเปซเท่านั้นที่ดูบันทึกหรือตรวจสอบสายโซ่แฮชได้';

  @override
  String permissionOnBehalfOf(String user) {
    return 'ในนามของ $user';
  }

  @override
  String get permissionPrompted => 'ขออนุมัติจากผู้ใช้แล้ว';

  @override
  String get permissionVerifyChain => 'ตรวจสอบสายโซ่บันทึก';

  @override
  String get permissionVerifyFailed => 'ตรวจสอบสายโซ่บันทึกไม่ได้';

  @override
  String permissionChainIntact(String count) {
    return 'สายโซ่สมบูรณ์ · ตรวจสอบแล้ว $count รายการ';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'สายโซ่ขาดที่รายการ $sequence: $reason';
  }

  @override
  String get permissionAuditEmpty => 'ยังไม่มีบันทึกการตัดสินใจอนุญาต';

  @override
  String get permissionAuditFailed => 'โหลดประวัติการอนุญาตไม่ได้';

  @override
  String get mobilePlansLoadFailed => 'โหลดแผนไม่ได้';

  @override
  String get mobilePlansEmpty => 'ยังไม่มีแผน';

  @override
  String get mobilePlansEmptyDescription =>
      'แผนที่เอเจนต์ส่งมาจะปรากฏที่นี่เพื่อให้รีวิว';

  @override
  String get mobilePlanTitle => 'แผน';

  @override
  String get mobilePlanMissing => 'แผนนี้ไม่อยู่ในเวิร์กสเปซนี้แล้ว';

  @override
  String mobilePlanStepCount(int count) {
    return '$count ขั้นตอน';
  }

  @override
  String get mobilePlanDraft => 'ฉบับร่าง';

  @override
  String get mobilePlanProposed => 'รอรีวิว';

  @override
  String get mobilePlanApproved => 'อนุมัติแล้ว';

  @override
  String get mobilePlanRejected => 'ถูกปฏิเสธ';

  @override
  String get mobilePlanSuperseded => 'ถูกแทนที่';

  @override
  String get mobilePlanExecuting => 'กำลังดำเนินการ';

  @override
  String get mobilePlanSynthesizing => 'กำลังสังเคราะห์';

  @override
  String get mobilePlanCompleted => 'เสร็จแล้ว';

  @override
  String get mobilePlanFailed => 'ล้มเหลว';

  @override
  String get mobilePlanCancelled => 'ยกเลิกแล้ว';

  @override
  String mobilePlanRevision(String revision) {
    return 'ฉบับแก้ไข $revision';
  }

  @override
  String get mobilePlanSteps => 'ขั้นตอน';

  @override
  String get mobilePlanNoSteps => 'ไม่มีขั้นตอนที่ส่งมาสำหรับแผนนี้';

  @override
  String get mobilePlanAssumptions => 'คำชี้แจง';

  @override
  String mobilePlanDependsOn(String keys) {
    return 'ขึ้นอยู่กับ $keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return 'ประมาณการไม่เกิน $cost';
  }

  @override
  String get mobilePlanSelect => 'เลือก';

  @override
  String get mobilePlanSelected => 'เลือกแล้ว';

  @override
  String get mobilePlanEstimate => 'ประมาณการค่าใช้จ่าย';

  @override
  String get mobilePlanEstimateRequired =>
      'ประมาณการค่าใช้จ่ายของแผนก่อนอนุมัติให้ดำเนินการ';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return 'ค่าใช้จ่ายโดยประมาณ: $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => 'ไม่มีข้อมูล';

  @override
  String get mobilePlanNoHardCap => 'ไม่มีเพดานตายตัว';

  @override
  String get mobilePlanExceedsBudget =>
      'ค่าใช้จ่ายโดยประมาณเกินงบที่ตั้งไว้ โปรดตรวจสอบก่อนอนุมัติ';

  @override
  String get mobilePlanPartialEstimate =>
      'ประมาณการนี้ครอบคลุมทั้งแผน ขั้นตอนที่เลือกอาจมีค่าใช้จ่ายน้อยกว่า';

  @override
  String get mobilePlanConfirmAll => 'เริ่มดำเนินการทั้งแผนหรือไม่?';

  @override
  String get mobilePlanConfirmSelected => 'เริ่มขั้นตอนที่เลือกหรือไม่?';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return 'การอนุมัติจะเริ่มดำเนินการและอาจมีค่าใช้จ่าย ค่าใช้จ่ายประมาณการสูงสุด: $cost เพดานงบประมาณ: $cap';
  }

  @override
  String get mobilePlanApproveAll => 'อนุมัติทั้งหมดและรัน';

  @override
  String get mobilePlanApproveSelected => 'อนุมัติที่เลือกและรัน';

  @override
  String get mobilePlanWiden => 'อนุมัติขั้นตอนเพิ่มเติม';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return 'อนุญาตให้ดำเนินการอีก $count ขั้นตอนหรือไม่? ขั้นตอนเหล่านี้อาจมีค่าใช้จ่าย เพดานค่าใช้จ่ายในการดำเนินการปัจจุบัน: $cap';
  }

  @override
  String get mobilePlanChanged =>
      'แผนเปลี่ยนไประหว่างรีวิว โปรดเปิดฉบับแก้ไขล่าสุดอีกครั้งและประมาณการค่าใช้จ่ายใหม่';

  @override
  String get mobilePlanReject => 'ปฏิเสธแผน';

  @override
  String get mobilePlanRejectConfirm =>
      'ปฏิเสธแผนนี้หรือไม่? แผนนี้จะไม่ถูกดำเนินการ';

  @override
  String get mobilePlanStop => 'หยุดดำเนินการ';

  @override
  String get mobilePlanStopConfirm =>
      'หยุดดำเนินการแผนนี้หรือไม่? งานที่เสร็จแล้วจะไม่ถูกย้อนกลับ';

  @override
  String mobilePlanRunId(String runId) {
    return 'รอบการดำเนินการ: $runId';
  }

  @override
  String get mobilePlanExecutionPending =>
      'รับการอนุมัติแล้ว กำลังรอบันทึกการดำเนินการ…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return 'ดำเนินการเสร็จแล้ว $completed จาก $total ขั้นตอน';
  }

  @override
  String get mobilePlanOpenConversation => 'เปิดการสนทนา';

  @override
  String get mobileGoalsTitle => 'เป้าหมายภายใต้การดูแล';

  @override
  String get mobileGoalsLoadFailed => 'โหลดเป้าหมายภายใต้การดูแลไม่ได้';

  @override
  String get mobileGoalsEmpty => 'ยังไม่มีเป้าหมายภายใต้การดูแล';

  @override
  String get mobileGoalsEmptyDescription =>
      'เริ่มเป้าหมายในสเปซ หรือส่ง /goal ในการสนทนา';

  @override
  String get mobileGoalMissing => 'เป้าหมายนี้ไม่อยู่ในเวิร์กสเปซนี้แล้ว';

  @override
  String get mobileGoalActive => 'ใช้งานอยู่';

  @override
  String get mobileGoalPaused => 'หยุดชั่วคราว';

  @override
  String get mobileGoalCompleted => 'เสร็จแล้ว';

  @override
  String get mobileGoalFailed => 'ล้มเหลว';

  @override
  String get mobileGoalCancelled => 'ยกเลิกแล้ว';

  @override
  String get mobileGoalBudgetExhausted => 'ใช้งบถึงขีดจำกัดแล้ว';

  @override
  String get mobileGoalGoal => 'เป้าหมาย';

  @override
  String get mobileGoalLoop => 'วนรอบ';

  @override
  String mobileGoalKind(String kind) {
    return 'ประเภท: $kind';
  }

  @override
  String mobileGoalRuns(String count) {
    return '$count รอบ';
  }

  @override
  String get mobileGoalNoRunLimit => 'ไม่จำกัด';

  @override
  String mobileGoalProgress(
    String runs,
    String maxRuns,
    String spent,
    String cap,
  ) {
    return 'รัน: $runs / $maxRuns รอบ · ใช้ไป: $spent / $cap';
  }

  @override
  String mobileGoalDeadline(String date) {
    return 'กำหนดเวลา: $date';
  }

  @override
  String mobileGoalFailures(String count) {
    return 'รันล้มเหลวติดต่อกัน: $count รอบ';
  }

  @override
  String get mobileGoalSummary => 'สรุปผลการดำเนินงาน';

  @override
  String get mobileGoalFailedDescription =>
      'ผู้ควบคุมหยุดทำงานหลังจากรันล้มเหลวหลายครั้ง ดูรายละเอียดได้ในการสนทนา';

  @override
  String get mobileGoalBudgetWall =>
      'ถึงกำหนดเวลาหรือจำนวนรันสูงสุดแล้ว การเพิ่มเพดานค่าใช้จ่ายจะไม่ทำให้เป้าหมายนี้ทำต่อได้';

  @override
  String get mobileGoalPause => 'หยุดเป้าหมายชั่วคราว';

  @override
  String get mobileGoalResume => 'ทำเป้าหมายต่อ';

  @override
  String get mobileGoalStop => 'ยกเลิกเป้าหมาย';

  @override
  String get mobileGoalStopConfirm =>
      'ยกเลิกเป้าหมายภายใต้การดูแลนี้อย่างถาวรหรือไม่? จะกลับมาทำต่อไม่ได้';

  @override
  String get mobileGoalRaiseBudget => 'เพิ่มงบและทำต่อ';

  @override
  String mobileGoalRaiseTo(String amount) {
    return 'เพิ่มงบเป็น $amount และทำต่อ';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return 'เพิ่มเพดานค่าใช้จ่ายของเป้าหมายนี้จาก $oldCap เป็น $newCap และกลับมาใช้จ่ายต่อหรือไม่?';
  }

  @override
  String get mobileGoalOpenConversation => 'เปิดการสนทนาของเป้าหมาย';

  @override
  String get mobileGoalCreate => 'เริ่มเป้าหมายภายใต้การดูแล';

  @override
  String get mobileGoalChooseSpace => 'รันในสเปซ';

  @override
  String get mobileGoalNoSpaces => 'สร้างสเปซก่อนเริ่มเป้าหมาย';

  @override
  String get mobileGoalChooseAgent => 'รันด้วยเอเจนต์';

  @override
  String get mobileGoalNoAgents => 'เพิ่มเอเจนต์ที่ใช้งานอยู่ก่อนเริ่มเป้าหมาย';

  @override
  String mobileGoalSelectedAgent(String name) {
    return 'เลือก $name แล้ว';
  }

  @override
  String get mobileGoalObjectiveHint =>
      'ต้องการให้เอเจนต์ทำให้เกิดผลลัพธ์อะไร?';

  @override
  String get mobileGoalBudgetUsd => 'เพดานค่าใช้จ่าย (USD)';

  @override
  String get mobileGoalCreateInvalid =>
      'เลือกสเปซและเอเจนต์ ระบุวัตถุประสงค์ และตั้งเพดานค่าใช้จ่ายเป็น USD ที่มากกว่าศูนย์';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return 'เริ่มเป้าหมายภายใต้การดูแลโดยมีค่าใช้จ่ายสูงสุด $cap หรือไม่? เอเจนต์อาจเริ่มทำงานทันที';
  }

  @override
  String get mobileGoalUnavailable =>
      'การเชื่อมต่อเซิร์ฟเวอร์ยังไม่พร้อม โปรดลองใหม่หลังเชื่อมต่ออีกครั้ง';

  @override
  String get mobileGoalConversationMissing =>
      'การสนทนาที่เลือกไม่อยู่ในเวิร์กสเปซนี้แล้ว';

  @override
  String get mobileGoalCreateSent =>
      'เริ่มเป้าหมายแล้ว สถานะของผู้ควบคุมจะปรากฏในรายการนี้';

  @override
  String get mobileGoalStartRefused =>
      'ยังไม่ได้เริ่มรันเป้าหมาย ดูเหตุผลจากผู้ควบคุมได้ในการสนทนา';

  @override
  String mobileGoalSelectedSpace(String name) {
    return 'เลือก $name แล้ว';
  }

  @override
  String get requestUnavailable =>
      'คำขอนี้ไม่อยู่ในเวิร์กสเปซที่ใช้งานอยู่แล้ว';

  @override
  String get requestAlreadyResolved => 'คำขอนี้ได้รับการจัดการแล้ว';

  @override
  String get inboxCredentialsBlocked => 'ข้อมูลรับรองทำให้รันไม่ได้';

  @override
  String get inboxSyncFailures => 'ซิงค์กับผู้ให้บริการล้มเหลว';

  @override
  String get inboxConfigureCredentials => 'ตั้งค่าข้อมูลรับรอง';

  @override
  String get openTicket => 'เปิดตั๋วงาน';

  @override
  String get activityTitle => 'กิจกรรม';

  @override
  String get activityClearAll => 'ล้างกิจกรรม';

  @override
  String get activityClearConfirm =>
      'การดำเนินการนี้จะซ่อนกิจกรรมทั้งหมดที่บันทึกไว้จนถึงตอนนี้จากทุกอุปกรณ์ของคุณ กิจกรรมใหม่จะยังคงปรากฏ';

  @override
  String get activityMarkAllRead => 'ทำเครื่องหมายทั้งหมดว่าอ่านแล้ว';

  @override
  String get activityMarkAllConfirm =>
      'ทำเครื่องหมายกิจกรรมทุกรายการในเวิร์กสเปซนี้ว่าอ่านแล้วบนทุกอุปกรณ์ของคุณหรือไม่?';

  @override
  String get activityMarkRead => 'ทำเครื่องหมายว่าอ่านแล้ว';

  @override
  String get activityMarkUnread => 'ทำเครื่องหมายว่ายังไม่อ่าน';

  @override
  String get activityDismiss => 'ปิด';

  @override
  String get activityResolved => 'ปิดแล้ว';

  @override
  String get activityOpen => 'เปิด';

  @override
  String get activityEmpty => 'ยังไม่มีกิจกรรม';

  @override
  String get activityLoadFailed => 'โหลดกิจกรรมไม่ได้';

  @override
  String get activityAgentWaiting => 'เอเจนต์ต้องการข้อมูลเพิ่มเติม';

  @override
  String get activityAgentBlocked => 'การกระทำของเอเจนต์ถูกบล็อก';

  @override
  String get activityMessage => 'ข้อความใหม่';

  @override
  String get activityPullRequest => 'อัปเดต pull request';

  @override
  String get activityTicket => 'อัปเดตตั๋วงาน';

  @override
  String get activityMeeting => 'อัปเดตการประชุม';

  @override
  String get activityCalendar => 'การเชื่อมต่อปฏิทิน';

  @override
  String get activityRig => 'อัปเดตริก';

  @override
  String get activityEvent => 'อัปเดต';

  @override
  String get activityPrReady => 'Pull request พร้อมรวมแล้ว';

  @override
  String get activityPrBlocked => 'การรวม pull request ถูกบล็อก';

  @override
  String get activityPrApproved => 'อนุมัติ pull request แล้ว';

  @override
  String get activityPrChanges => 'ขอให้แก้ไข';

  @override
  String get activityPrChecksFailed => 'การตรวจสอบ pull request ล้มเหลว';

  @override
  String get activityPrChecksRecovered =>
      'การตรวจสอบ pull request กลับมาผ่านแล้ว';

  @override
  String get activityPrComment => 'ความคิดเห็นใน pull request';

  @override
  String get activityPrPublished => 'เผยแพร่ pull request แล้ว';

  @override
  String get activityPrMerged => 'รวม pull request แล้ว';

  @override
  String get activityPrMentioned => 'ถูกกล่าวถึงใน pull request';

  @override
  String get activityPrReviewRequested => 'ขอรีวิว';

  @override
  String get activityPrReviewStale => 'ต้องรีวิวใหม่';

  @override
  String get activityTicketAssigned => 'มอบหมายตั๋วงาน';

  @override
  String get activityTicketChanged => 'สถานะตั๋วงานเปลี่ยน';

  @override
  String get activityMeetingSoon => 'การประชุมกำลังจะเริ่ม';

  @override
  String get activityCalendarExpired => 'การเชื่อมต่อปฏิทินหมดอายุแล้ว';

  @override
  String get activityRigControl => 'การควบคุมริกเปลี่ยนแปลง';

  @override
  String get activityRigClosed => 'ริกหยุดทำงานแล้ว';

  @override
  String get mobileSpacesSearch => 'ค้นหาสเปซ';

  @override
  String get mobileSpacesArchived => 'เก็บถาวรแล้ว';

  @override
  String get mobileSpacesActive => 'ใช้งานอยู่';

  @override
  String get mobileSpacesNew => 'สเปซใหม่';

  @override
  String get mobileSpacesManage => 'จัดการสเปซ';

  @override
  String get mobileSpacesName => 'ชื่อสเปซ';

  @override
  String get mobileSpacesAgents => 'เอเจนต์';

  @override
  String get mobileSpacesMembers => 'บุคคล';

  @override
  String get mobileSpacesRepos => 'รีโพสิทอรี';

  @override
  String get mobileSpacesAllRepos => 'รีโพสิทอรีที่เชื่อมโยงทั้งหมด';

  @override
  String get mobileSpacesNoRepos => 'ไม่มีรีโพสิทอรี';

  @override
  String get mobileSpacesBaseBranch => 'บรานช์ฐาน (ไม่บังคับ)';

  @override
  String get mobileSpacesDefaultBranch => 'บรานช์เริ่มต้น';

  @override
  String get mobileSpacesMode => 'โหมด';

  @override
  String get mobileSpacesModeChat => 'แชท';

  @override
  String get mobileSpacesModeReview => 'รีวิว (อ่านอย่างเดียว)';

  @override
  String get mobileSpacesModePlan => 'แผน (อ่านอย่างเดียว)';

  @override
  String get mobileSpacesModeOrchestrate => 'ประสานงาน';

  @override
  String get mobileSpacesAutonomy => 'กำหนดระดับอิสระเฉพาะสเปซ';

  @override
  String get mobileSpacesAutonomyInherited => 'สืบทอด';

  @override
  String get mobileSpacesAutonomyPropose => 'เสนออย่างเดียว';

  @override
  String get mobileSpacesAutonomyApproval => 'ทำเมื่อได้รับอนุมัติ';

  @override
  String get mobileSpacesAutonomyFreely => 'ทำได้อย่างอิสระ';

  @override
  String get mobileSpacesAutonomyNotice =>
      'การตั้งค่าเฉพาะนี้ไม่สามารถข้ามการถามยืนยันหรือการปฏิเสธตามนโยบายการกระทำได้ เฉพาะผู้ดูแลเวิร์กสเปซเท่านั้นที่เปลี่ยนได้';

  @override
  String get mobileSpacesArchive => 'เก็บถาวรสเปซ';

  @override
  String get mobileSpacesReopen => 'เปิดสเปซอีกครั้ง';

  @override
  String get mobileSpacesSave => 'บันทึกการเปลี่ยนแปลง';

  @override
  String get mobileSpacesCreate => 'สร้างสเปซ';

  @override
  String get mobileSpacesOperationFailed => 'อัปเดตสเปซไม่ได้';

  @override
  String get mobileSpacesMissing => 'ไม่พบสเปซในเวิร์กสเปซนี้';

  @override
  String get mobileSpacesEmptyName => 'ป้อนชื่อสเปซ';

  @override
  String get mobileSpacesNoMatches => 'ไม่มีสเปซที่ตรงกัน';

  @override
  String get mobileSpacesUnread => 'มีคำตอบจากเอเจนต์ที่ยังไม่ได้อ่าน';

  @override
  String get mobileSpacesNeedsInput => 'ต้องการข้อมูลจากคุณ';

  @override
  String get mobileSpacesRunning => 'เอเจนต์กำลังรัน';

  @override
  String get mobileSpacesNoAgents => 'ไม่มีเอเจนต์ในเวิร์กสเปซนี้';

  @override
  String get mobileSpacesNoMembers => 'ไม่มีสมาชิกคนอื่นในเวิร์กสเปซ';

  @override
  String get mobileSpacesRepoError => 'โหลดรีโพสิทอรีไม่ได้';

  @override
  String get mobileSpacesRetry => 'ลองใหม่';

  @override
  String get mobileSpacesBranchUnavailable =>
      'เลือกหรือพิมพ์บรานช์ฐานเมื่อสร้างสเปซ บรานช์ฐานของสเปซที่มีอยู่แล้วไม่สามารถเปลี่ยนได้';

  @override
  String get mobileSpacesArchivedEmpty => 'ไม่มีสเปซที่เก็บถาวร';

  @override
  String get mobileSpacesAllRepoWarning =>
      'รีโพสิทอรีที่เชื่อมโยงกับเวิร์กสเปซนี้ในภายหลังก็จะรวมอยู่ในสเปซนี้ด้วย';

  @override
  String get mobileSpacesCreatedRetry =>
      'สร้างสเปซแล้ว ลองเพิ่มบุคคลอีกครั้ง หรือเปิดหน้าจัดการสเปซ';

  @override
  String get progressTitle => 'ความคืบหน้า';

  @override
  String get progressConversation => 'การสนทนา';

  @override
  String get progressLoadFailed => 'โหลดความคืบหน้าไม่ได้';

  @override
  String get progressUnavailable => 'การสนทนาไม่พร้อมใช้งาน';

  @override
  String get progressUnavailableDescription =>
      'การสนทนานี้ไม่ได้อยู่ในเวิร์กสเปซและสเปซที่ใช้งานอยู่ กลับไปที่สเปซของการสนทนาเพื่อทำต่อ';

  @override
  String get progressSaveFailed => 'อัปเดตความคืบหน้าไม่ได้';

  @override
  String get progressGoal => 'เป้าหมาย';

  @override
  String get progressNoGoal => 'ยังไม่ได้ตั้งเป้าหมายการทำงาน';

  @override
  String get progressSetGoal => 'ตั้งเป้าหมาย';

  @override
  String get progressEditGoal => 'แก้ไขเป้าหมาย';

  @override
  String get progressClearGoal => 'ล้างเป้าหมาย';

  @override
  String get progressGoalRequired => 'ป้อนเป้าหมายก่อนบันทึก';

  @override
  String get progressTodos => 'งาน';

  @override
  String get transcriptToolTodos => 'งาน';

  @override
  String get transcriptToolSearchMemory => 'ค้นหาในความจำ';

  @override
  String get transcriptToolRenderMedia => 'แสดงสื่อ';

  @override
  String get progressNoTodos => 'ยังไม่มีงาน';

  @override
  String get progressNewTodo => 'งานใหม่';

  @override
  String get progressAddTodo => 'เพิ่มงาน';

  @override
  String get progressEditTodo => 'แก้ไขงาน';

  @override
  String get progressTodoRequired => 'ป้อนงานก่อนบันทึก';

  @override
  String get progressTodoNoLongerExists =>
      'งานนั้นถูกลบแล้ว โหลดรายการใหม่แล้วลองอีกครั้ง';

  @override
  String get progressWorkspaceChanged =>
      'เวิร์กสเปซที่ใช้งานอยู่เปลี่ยนไป กลับไปที่การสนทนานี้แล้วลองอีกครั้ง';

  @override
  String progressRemoveTodo(String name) {
    return 'ลบงาน $name';
  }

  @override
  String get progressPending => 'รอดำเนินการ';

  @override
  String get progressInProgress => 'กำลังดำเนินการ';

  @override
  String get progressCompleted => 'เสร็จแล้ว';

  @override
  String get progressMoveUp => 'ย้ายงานขึ้น';

  @override
  String get progressMoveDown => 'ย้ายงานลง';

  @override
  String get progressRunTree => 'การรันของเอเจนต์';

  @override
  String get progressNoRuns => 'ยังไม่มีการรันในการสนทนานี้';

  @override
  String get progressRunning => 'กำลังรัน';

  @override
  String get progressFailed => 'ล้มเหลว';

  @override
  String get progressUnknown => 'ไม่ทราบ';

  @override
  String get progressHealthy => 'ใช้งานอยู่';

  @override
  String get progressBlocked => 'ถูกบล็อก';

  @override
  String get progressLooping => 'กำลังวนซ้ำ';

  @override
  String get progressStalled => 'ค้าง';

  @override
  String get progressDead => 'หยุดโดยไม่คาดคิด';

  @override
  String get progressQuiet => 'ยังไม่มีผลลัพธ์';

  @override
  String get progressCostReported => 'ค่าใช้จ่ายที่ผู้ให้บริการรายงาน';

  @override
  String get progressCostNotional =>
      'ราคาตามรายการของการสมัครสมาชิกโดยประมาณ ไม่ใช่ยอดเรียกเก็บจริง';

  @override
  String get progressCostMixed => 'ค่าใช้จ่ายจากหลายแหล่ง';

  @override
  String get progressCostEstimated => 'ค่าใช้จ่ายโดยประมาณ';

  @override
  String progressDurationSeconds(String seconds) {
    return '$seconds วินาที';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'โมเดล: $model · เวลา: $duration · ค่าใช้จ่าย: $cost';
  }

  @override
  String progressStartedAt(String time) {
    return 'เริ่มเมื่อ $time';
  }

  @override
  String progressLiveness(String state) {
    return 'สถานะการทำงาน: $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return 'อินพุต: $input · เอาต์พุต: $output โทเคน';
  }

  @override
  String get progressOutputPreviewLimited =>
      'แสดงเฉพาะ 6,000 อักขระแรกของผลลัพธ์แบบมีโครงสร้าง';

  @override
  String progressRetryOf(String runId) {
    return 'รันซ้ำจากการรัน $runId';
  }

  @override
  String get progressContext => 'บริบทและขีดจำกัด';

  @override
  String get progressNoAgent => 'ไม่มีเอเจนต์ให้ตรวจสอบ';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window โทเคน';
  }

  @override
  String get progressMeasured =>
      'บริบทที่ผู้ให้บริการรายงานในการเรียกใช้ล่าสุด';

  @override
  String get progressEstimated => 'ประมาณจากการสนทนาที่จัดเก็บไว้และบริบทถาวร';

  @override
  String get progressContextUnknown => 'ยังไม่มีรายงานการใช้บริบท';

  @override
  String progressContextPercent(String percent) {
    return '$percent% ของความจุบริบท';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return 'ขีดจำกัดเอเจนต์รายเดือนที่ตั้งไว้: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return 'การสนทนาปัจจุบันที่จัดเก็บไว้: ประมาณ $tokens โทเคน';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return 'บริบทถาวรของ $agent · $model';
  }

  @override
  String get progressContextSystem => 'พรอมต์ระบบ';

  @override
  String get progressContextRules => 'กฎ';

  @override
  String get progressContextSkills => 'สกิล';

  @override
  String get progressContextTools => 'คำจำกัดความเครื่องมือ';

  @override
  String get progressContextMcp => 'เครื่องมือ MCP';

  @override
  String get progressContextDeferred => 'เครื่องมือที่เลื่อนการโหลดไว้';

  @override
  String get progressContextSubagents => 'ซับเอเจนต์';

  @override
  String get progressContextRunner => 'ตัวรันภายนอก';

  @override
  String get progressContextMemory => 'หน่วยความจำ';

  @override
  String get progressContextHistory => 'ประวัติการสนทนา';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens โทเคน';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens โทเคน';
  }

  @override
  String get progressOutputs => 'ผลลัพธ์ล่าสุด';

  @override
  String get progressNoOutputs => 'ไม่มีผลลัพธ์ล่าสุดจากเอเจนต์';

  @override
  String get progressStructuredOutputsAbove =>
      'ผลลัพธ์การรันแบบมีโครงสร้างแสดงอยู่ในการรันของเอเจนต์ด้านบน';

  @override
  String get progressRecentOutputsOnly =>
      'แสดงเฉพาะข้อความล่าสุด เปิดการสนทนาเพื่อดูงานก่อนหน้า';

  @override
  String get progressPlan => 'แผน';

  @override
  String get progressArtifact => 'อาร์ติแฟกต์';

  @override
  String get progressResult => 'ผลลัพธ์';

  @override
  String get progressHideArtifact => 'ซ่อนอาร์ติแฟกต์';

  @override
  String get progressReadArtifact => 'อ่านอาร์ติแฟกต์';

  @override
  String get progressArtifactUnavailable => 'อาร์ติแฟกต์ไม่พร้อมใช้งานแล้ว';

  @override
  String get progressArtifactPreviewLimited =>
      'แสดงตัวอย่างอาร์ติแฟกต์นี้เพียงบางส่วน';

  @override
  String get progressDiagramSource => 'ซอร์สของแผนภาพ';

  @override
  String progressOpenAttachment(String name) {
    return 'เปิด $name';
  }

  @override
  String get progressOpenPlan => 'เปิดแผน';

  @override
  String progressOpenDiff(String label) {
    return 'รีวิวไฟล์ที่เปลี่ยนแปลง: $label';
  }

  @override
  String get progressViewMessage => 'ดูข้อความ';

  @override
  String get pushTitle => 'การแจ้งเตือนเบื้องหลัง';

  @override
  String get pushIntro =>
      'รับการแจ้งเตือนส่วนตัวเมื่อมีเรื่องที่ต้องให้คุณจัดการ แม้ปิดแอปอยู่ รายละเอียดจะอยู่ภายในการเชื่อมต่อที่เข้ารหัสของคุณเท่านั้น';

  @override
  String get pushLoading => 'กำลังตรวจสอบการตั้งค่าการแจ้งเตือน…';

  @override
  String get pushError =>
      'อัปเดตการแจ้งเตือนไม่ได้ ตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง';

  @override
  String get pushEnable => 'เปิดการแจ้งเตือน';

  @override
  String get pushDisable => 'ปิดการแจ้งเตือน';

  @override
  String get pushQuiet => 'พักการแจ้งเตือนบนอุปกรณ์นี้';

  @override
  String get pushCategories => 'แจ้งเตือนฉันเกี่ยวกับ';

  @override
  String get pushCategoryAgents => 'เอเจนต์';

  @override
  String get pushCategoryMessages => 'ข้อความ';

  @override
  String get pushCategoryPullRequests => 'Pull request';

  @override
  String get pushCategoryTickets => 'ตั๋วงาน';

  @override
  String get pushCategoryCalendar => 'ปฏิทิน';

  @override
  String get pushCategoryMachines => 'เครื่อง';

  @override
  String get pushSecureOrigin => 'การแจ้งเตือนต้องใช้ HTTPS';

  @override
  String get pushInstallIos =>
      'บน iPhone หรือ iPad ให้เพิ่มแอปนี้ไปยังหน้าจอโฮม แล้วเปิดจากที่นั่นเพื่อเปิดการแจ้งเตือน';

  @override
  String get pushUnsupported => 'เบราว์เซอร์นี้ไม่รองรับการแจ้งเตือนเบื้องหลัง';

  @override
  String get pushDenied =>
      'เบราว์เซอร์แจ้งว่าการแจ้งเตือนถูกบล็อก ตรวจสอบสิทธิ์ของเว็บไซต์นี้และการตั้งค่าการแจ้งเตือนของเบราว์เซอร์หรืออุปกรณ์ แล้วรีเฟรชหน้า';

  @override
  String get pushOsHint =>
      'เบราว์เซอร์ของคุณต้องได้รับสิทธิ์แสดงการแจ้งเตือนในการตั้งค่าระบบของอุปกรณ์ด้วย';

  @override
  String get pushServiceUnavailable =>
      'บริการพุชของเบราว์เซอร์ปฏิเสธการสมัครรับ เบราว์เซอร์บางตัว เช่น Brave ปิดบริการนี้ไว้เป็นค่าเริ่มต้น: มองหาตัวเลือกข้อความพุชในการตั้งค่าความเป็นส่วนตัวของเบราว์เซอร์ แล้วลองอีกครั้ง';

  @override
  String get pushWorkerUnavailable =>
      'ไม่สามารถเริ่มบริการการแจ้งเตือนในเบราว์เซอร์นี้ได้ โหลดหน้าใหม่แล้วลองอีกครั้ง';

  @override
  String get pushResubscribe => 'เชื่อมต่อการแจ้งเตือนอีกครั้ง';

  @override
  String get pushStatusEnabled => 'เปิดการแจ้งเตือนสำหรับอุปกรณ์นี้แล้ว';

  @override
  String get pushStatusDisabled => 'ปิดการแจ้งเตือนสำหรับอุปกรณ์นี้แล้ว';

  @override
  String get credentialsTitle => 'การเชื่อมต่อและข้อมูลรับรอง';

  @override
  String get credentialsIntro =>
      'เชื่อมต่อบัญชีที่ใช้ในการรันและการผสานการทำงาน ข้อมูลลับเก็บไว้บนเซิร์ฟเวอร์ของคุณ ไม่ใช่ในโทรศัพท์นี้';

  @override
  String get credentialsModelProviders => 'ผู้ให้บริการโมเดล';

  @override
  String get credentialsOwnerOnly =>
      'เฉพาะเจ้าของเซิร์ฟเวอร์เท่านั้นที่เพิ่ม ลงชื่อเข้าใช้ หรือลบข้อมูลรับรองของผู้ให้บริการโมเดลได้ คีย์เหล่านี้ใช้ร่วมกันระหว่างเวิร์กสเปซ';

  @override
  String get credentialsContactOwner =>
      'ขอให้เจ้าของเซิร์ฟเวอร์เชื่อมต่อผู้ให้บริการที่การรันซึ่งถูกบล็อกต้องใช้';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'Claude Code ลงชื่อเข้าใช้ผ่าน CLI บนเครื่องโฮสต์ ขอให้เจ้าของเซิร์ฟเวอร์ลงชื่อเข้าใช้หรือต่ออายุการเข้าสู่ระบบผ่านเทอร์มินัลของเครื่องโฮสต์ โทรศัพท์นี้ทำไม่ได้';

  @override
  String get credentialsYourForgeAccounts => 'บัญชีแพลตฟอร์มโฮสต์โค้ดของคุณ';

  @override
  String get credentialsYourTicketingAccount => 'บัญชีระบบตั๋วงานของคุณ';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'ตั๋วงานในเครื่องไม่ต้องลงชื่อเข้าใช้ หากเวิร์กสเปซใช้ Linear ให้เชื่อมต่อ Linear ที่นี่';

  @override
  String get credentialsMembershipRequired =>
      'เข้าร่วมเวิร์กสเปซเพื่อจัดการข้อมูลรับรองของแพลตฟอร์มโฮสต์โค้ดหรือระบบตั๋วงาน ขอสิทธิ์จากผู้ดูแลเวิร์กสเปซ';

  @override
  String get credentialsSwitchWorkspace =>
      'ลิงก์นี้ชี้ไปยังเวิร์กสเปซอื่น สลับไปยังเวิร์กสเปซนั้นก่อนเปลี่ยนข้อมูลรับรอง';

  @override
  String get credentialsReturnToInbox =>
      'กลับไปที่กล่องขาเข้าเพื่อลองรันงานที่ถูกบล็อกอีกครั้งเมื่อเชื่อมต่อข้อมูลรับรองแล้ว เครื่องโฮสต์จะตรวจสอบการรันที่พักไว้โดยอัตโนมัติด้วย';

  @override
  String get credentialsLoadFailed =>
      'โหลดการเชื่อมต่อไม่ได้ ตรวจสอบการเชื่อมต่อเซิร์ฟเวอร์แล้วลองอีกครั้ง';

  @override
  String get credentialsOperationFailed =>
      'เปลี่ยนการเชื่อมต่อนี้ไม่ได้ ตรวจสอบการเชื่อมต่อเซิร์ฟเวอร์ สิทธิ์ของคุณ และข้อมูลรับรอง แล้วลองอีกครั้ง';

  @override
  String get credentialsConnected => 'เชื่อมต่อแล้ว';

  @override
  String get credentialsNotConnected => 'ยังไม่เชื่อมต่อ';

  @override
  String credentialsSignedInAs(String username) {
    return 'ลงชื่อเข้าใช้เป็น $username';
  }

  @override
  String get credentialsAccount => 'บัญชีที่เชื่อมต่อ';

  @override
  String get credentialsStoredKey => 'คีย์ที่จัดเก็บไว้';

  @override
  String get credentialsActive => 'ใช้งานอยู่';

  @override
  String get credentialsRemove => 'ลบออก';

  @override
  String get credentialsRemoveConfirm =>
      'ลบข้อมูลรับรองที่บันทึกไว้หรือไม่? คุณอาจต้องลงชื่อเข้าใช้อีกครั้ง';

  @override
  String get credentialsApiKey => 'คีย์ API';

  @override
  String get credentialsApiKeyHint => 'วางคีย์ API ของผู้ให้บริการ';

  @override
  String get credentialsBrowserLogin => 'ลงชื่อเข้าใช้ผ่านเบราว์เซอร์';

  @override
  String get credentialsSignInAgain => 'ลงชื่อเข้าใช้อีกครั้ง';

  @override
  String get credentialsWaitingForLogin =>
      'กำลังรอการอนุญาตในเบราว์เซอร์ของคุณ…';

  @override
  String get credentialsLoginTimedOut =>
      'การเข้าสู่ระบบหมดอายุแล้ว เริ่มลงชื่อเข้าใช้อีกครั้ง';

  @override
  String get credentialsCopyCode => 'คัดลอกรหัส';

  @override
  String get credentialsDeviceCodeHint =>
      'ยืนยันรหัสนี้บนหน้าของผู้ให้บริการ เปิดหน้าจอนี้ไว้ระหว่างที่เซิร์ฟเวอร์ลงชื่อเข้าใช้ให้เสร็จ';

  @override
  String get credentialsPasteRedirect => 'รหัสอนุญาตหรือ URL เปลี่ยนเส้นทาง';

  @override
  String get credentialsPasteRedirectHint =>
      'วางรหัสหรือ URL เปลี่ยนเส้นทางแบบเต็มจากผู้ให้บริการ';

  @override
  String get credentialsCompleteLogin => 'ลงชื่อเข้าใช้ให้เสร็จ';

  @override
  String get credentialsRedirectUnavailable =>
      'โทรศัพท์ไม่สามารถเข้าถึงจุดรับการตอบกลับจากเบราว์เซอร์ของเซิร์ฟเวอร์นี้อย่างปลอดภัยได้ ขอให้เจ้าของเซิร์ฟเวอร์ตั้งค่าจุดรับการตอบกลับ HTTPS สาธารณะ หรือเพิ่มโทเค็นแทน';

  @override
  String get credentialsUpdateToken => 'อัปเดตโทเค็น';

  @override
  String get credentialsAddToken => 'เพิ่มโทเค็น';

  @override
  String get credentialsPersonalToken => 'โทเค็นการเข้าถึงส่วนบุคคล';

  @override
  String get credentialsPersonalTokenHint => 'วางโทเค็นการเข้าถึงส่วนบุคคล';

  @override
  String get credentialsHostManaged =>
      'การเชื่อมต่อนี้มาจากแอปเซิร์ฟเวอร์หรือสภาพแวดล้อมของเซิร์ฟเวอร์ เฉพาะเจ้าของเซิร์ฟเวอร์เท่านั้นที่เปลี่ยนได้ที่นั่น แต่คุณยังเพิ่มโทเค็นของตนเองได้';

  @override
  String get credentialsStopWatching => 'หยุดติดตาม';

  @override
  String get transcriptClaudeSignInExpiredTitle =>
      'การลงชื่อเข้าใช้ Claude Code หมดอายุ';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      'การทำงานหยุดลงเพราะบัญชีของมันยืนยันตัวตนไม่ได้อีกต่อไป ลงชื่อเข้าใช้อีกครั้ง แล้วลองรอบนี้ใหม่';

  @override
  String get transcriptSignInExpiredTitle =>
      'การลงชื่อเข้าใช้ผู้ให้บริการหมดอายุ';

  @override
  String get transcriptSignInExpiredBody =>
      'การทำงานหยุดลงเพราะข้อมูลรับรองของผู้ให้บริการใช้ไม่ได้อีกต่อไป เชื่อมต่อใหม่ในการตั้งค่า → ผู้ให้บริการ แล้วลองรอบนี้ใหม่';
}
