// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get succeeded => 'สำเร็จ';

  @override
  String agentRunRetryLabel(int number, String time) {
    return 'ลองใหม่ #$number · $time';
  }

  @override
  String agentRunStarting(String time) {
    return 'กำลังเริ่ม · $time';
  }

  @override
  String get agentActivityFollowingLive => 'กำลังติดตามกิจกรรมแบบสด';

  @override
  String get agentActivityJumpToLatest => 'ไปยังล่าสุด';

  @override
  String get agentActivityLoadFailed => 'โหลดกิจกรรมของรันนี้ไม่ได้';

  @override
  String get agentActivityNotRecorded => 'รันนี้ไม่ได้บันทึกกิจกรรม';

  @override
  String get agentActivityNotRecordedHint =>
      'รันที่จบก่อนเปิดการบันทึกกิจกรรมจะไม่มีไทม์ไลน์';

  @override
  String get agentActivityRunUnavailable => 'รันนี้ไม่มีแล้ว';

  @override
  String agentActivitySubagentOf(String agent) {
    return 'ซับเอเจนต์ของ $agent';
  }

  @override
  String get agentActivityUnsupported =>
      'เซิร์ฟเวอร์ที่เชื่อมต่อไม่รองรับการบันทึกกิจกรรม';

  @override
  String get agentActivityUnsupportedHint =>
      'รีสตาร์ทแอปเพื่อใช้บิลด์เซิร์ฟเวอร์ล่าสุด';

  @override
  String get agentActivityWaiting => 'กำลังรอกิจกรรม…';

  @override
  String get created => 'สร้างแล้ว';

  @override
  String get dictationStart => 'เริ่มป้อนด้วยเสียง';

  @override
  String get dictationListening => 'กำลังฟัง…';

  @override
  String get dictationUnavailable =>
      'การป้อนด้วยเสียงต้องมีโมเดลเสียงบนโฮสต์เซิร์ฟเวอร์ ตั้งค่าได้ที่การตั้งค่าเสียง';

  @override
  String get dictationFailedToStart => 'เริ่มป้อนด้วยเสียงไม่ได้';

  @override
  String get dictationHoldToTalkTitle => 'กดค้างเพื่อพูด';

  @override
  String get dictationHoldToTalkDescription =>
      'กดปุ่มไมค์หรือทางลัดค้างไว้เพื่อป้อนด้วยเสียง แล้วปล่อยเพื่อหยุด หากปิดอยู่ ให้กดครั้งหนึ่งเพื่อเริ่ม และกดอีกครั้งเพื่อหยุด';

  @override
  String get focusConversation => 'โฟกัสการสนทนา';

  @override
  String get ideAgentActivity => 'กิจกรรมของเอเจนต์';

  @override
  String get keybindingPushToTalk => 'กดเพื่อพูด';

  @override
  String get keybindingPushToTalkDescription =>
      'กดค้างหรือสลับการป้อนด้วยเสียงในช่องเขียนข้อความ';

  @override
  String get agentPermissions => 'สิทธิ์ของเอเจนต์';

  @override
  String get agentPermissionsSettingsDescription =>
      'กำหนดว่าเอเจนต์ทำอะไรได้เอง ต้องถามก่อน หรือห้ามทำ — ตามเวิร์กสเปซ เอเจนต์ หรือสเปซ';

  @override
  String get agentPermissionsMatrixDescription =>
      'ตั้งค่าการตัดสินใจสำหรับแต่ละประเภทผลกระทบ กฎซ้อนกัน: สเปซทับเอเจนต์ ทับเวิร์กสเปซ ทับพรีเซ็ตโหมด กฎที่เจาะจงที่สุดมีผล';

  @override
  String get guardrailLoading => 'กำลังโหลดกฎ…';

  @override
  String get guardrailRulesLoadFailed => 'โหลดกฎสิทธิ์ไม่ได้';

  @override
  String get guardrailScopeWorkspace => 'เวิร์กสเปซ';

  @override
  String get guardrailScopeAgent => 'เอเจนต์';

  @override
  String get guardrailScopeSpace => 'สเปซ';

  @override
  String get guardrailSelectAgent => 'เลือกเอเจนต์';

  @override
  String get guardrailSelectSpace => 'เลือกสเปซ';

  @override
  String get guardrailNoAgents => 'ยังไม่มีเอเจนต์ในเวิร์กสเปซนี้';

  @override
  String get guardrailNoSpaces => 'ยังไม่มีสเปซในเวิร์กสเปซนี้';

  @override
  String get guardrailClassFileDelete => 'ลบไฟล์';

  @override
  String get guardrailClassFileWriteOutsideWorktree => 'เขียนนอก worktree';

  @override
  String get guardrailClassGitCommit => 'สร้างคอมมิต';

  @override
  String get guardrailClassGitPush => 'พุชไปยังรีโมต';

  @override
  String get guardrailClassPrCreate => 'เปิด pull request';

  @override
  String get guardrailClassPrPublish => 'เผยแพร่รีวิวหรือรวม';

  @override
  String get guardrailClassVendorSyncWrite => 'เขียนไปยังตัวติดตามภายนอก';

  @override
  String get guardrailClassNetworkEgress => 'เข้าถึงเครือข่าย';

  @override
  String get guardrailClassSecretAccess => 'อ่านความลับ';

  @override
  String get guardrailClassPackageInstall => 'ติดตั้งแพ็กเกจ';

  @override
  String get guardrailClassProcessSpawn => 'รันโพรเซส';

  @override
  String get guardrailClassWorkspaceMutation => 'เปลี่ยนโครงสร้างเวิร์กสเปซ';

  @override
  String get guardrailClassEnclosureControl => 'ควบคุมเอนโคลเจอร์ (ริก)';

  @override
  String get navRigs => 'ริก';

  @override
  String get rigsUnsupportedServer =>
      'เซิร์ฟเวอร์นี้ไม่สามารถโฮสต์พื้นผิว rig ได้ โปรดตรวจสอบข้อกำหนดของโฮสต์สำหรับเครื่องที่คุณต้องการใช้';

  @override
  String get rigSurfaceComputer => 'คอมพิวเตอร์';

  @override
  String get rigSurfaceBrowser => 'เบราว์เซอร์';

  @override
  String get rigSurfaceAndroid => 'Android';

  @override
  String get rigSurfaceIosSimulator => 'เครื่องจำลอง iOS';

  @override
  String rigSurfaceBrowserEngine(String engine) {
    return '$engine';
  }

  @override
  String rigBrowserEngineHint(String engine) {
    return '$engine แบบใช้แล้วทิ้ง แยกจากเครื่องของคุณ เปิดเอ็นจินอื่นเพื่อเทียบหน้าเดียวกันเคียงข้างกัน';
  }

  @override
  String get rigPhaseReady => 'พร้อม';

  @override
  String get rigPhaseStarting => 'กำลังเริ่ม';

  @override
  String get rigPhaseParked => 'จอดไว้';

  @override
  String get rigPhaseClosing => 'กำลังปิด';

  @override
  String get rigPhaseClosed => 'ปิดแล้ว';

  @override
  String get rigPhaseFailed => 'ล้มเหลว';

  @override
  String get rigPhaseUnknown => 'ไม่ทราบ';

  @override
  String get rigNotAccelerated => 'จำลอง';

  @override
  String get rigAudioListen => 'ฟังเครื่อง';

  @override
  String get rigAudioMute => 'ปิดเสียงเครื่อง';

  @override
  String get rigYouHaveControl => 'คุณกำลังควบคุม';

  @override
  String get rigBackendAvailable => 'พร้อมใช้';

  @override
  String get rigBackendUnavailable => 'ไม่พร้อมใช้';

  @override
  String get rigEgressNotEnforced =>
      'แบ็กเอนด์นี้ไม่หุ้มเครือข่าย — จัดการการเชื่อมต่อเอง';

  @override
  String get rigStartMachine => 'เริ่มเครื่อง';

  @override
  String get rigStartHint =>
      'เริ่ม VM แบบใช้แล้วทิ้งที่คุณกับเอเจนต์ใช้ร่วมกันในการสนทนานี้ ปิดแล้วจะถูกทำลาย และไม่มีอะไรในนั้นแตะคอมพิวเตอร์ของคุณ';

  @override
  String get rigStartAndroidHint =>
      'เชื่อมต่อกับโปรแกรมจำลอง Android ที่ทำงานอยู่บนเซิร์ฟเวอร์แล้ว การเข้าถึงเครือข่ายไม่ได้แยกออกจากกัน';

  @override
  String get rigStartIosHint =>
      'สร้าง iOS Simulator ชั่วคราวบนเซิร์ฟเวอร์ macOS โดยจะถูกลบเมื่อปิดสภาพแวดล้อมการทดสอบ และการเข้าถึงเครือข่ายไม่ได้แยกออกจากกัน';

  @override
  String get rigTechnicalDetails => 'รายละเอียดทางเทคนิค';

  @override
  String get rigStopMachine => 'หยุดเครื่อง';

  @override
  String get rigHomeButton => 'หน้าหลัก';

  @override
  String get rigRotateClockwise => 'หมุนตามเข็มนาฬิกา';

  @override
  String get rigRotateCounterclockwise => 'หมุนทวนเข็มนาฬิกา';

  @override
  String get rigTakeScreenshot => 'ถ่ายภาพหน้าจอ';

  @override
  String get rigScreenshotSaved => 'บันทึกภาพหน้าจอแล้ว';

  @override
  String rigScreenshotSaveFailed(String error) {
    return 'บันทึกภาพหน้าจอไม่ได้: $error';
  }

  @override
  String get rigSurfaceUnavailable => 'เซิร์ฟเวอร์นี้โฮสต์เครื่องชนิดนี้ไม่ได้';

  @override
  String get rigTabNeedsConversation =>
      'เปิดการสนทนาก่อน — เครื่องสังกัดการสนทนาหนึ่งรายการ เพื่อให้คุณกับเอเจนต์ดูหน้าจอเดียวกัน';

  @override
  String get ideMenuSectionTools => 'เครื่องมือ';

  @override
  String get ideMenuSectionMachines => 'เครื่อง';

  @override
  String get ideMenuSectionReopen => 'เปิดอีกครั้ง';

  @override
  String get ideMenuSearchHint => 'ค้นหา';

  @override
  String get ideMenuNoMatches => 'ไม่พบรายการ';

  @override
  String get rigMenuComputer => 'คอมพิวเตอร์';

  @override
  String get rigMenuBrowser => 'เบราว์เซอร์';

  @override
  String get rigMenuAndroid => 'Android';

  @override
  String get rigMenuIosSimulator => 'เครื่องจำลอง iOS';

  @override
  String rigLabelNumbered(String label, String suffix) {
    return '$label $suffix';
  }

  @override
  String ideCloseKeepTitle(String name) {
    return 'ปิด $name หรือไม่?';
  }

  @override
  String get ideCloseKeepBodyMachine =>
      'เครื่องยังรันอยู่เบื้องหลัง — เปิดใหม่ได้ทุกเมื่อจากแถบข้าง หากต้องการคืนหน่วยความจำตอนนี้ ให้ปิดเครื่องแทน';

  @override
  String get ideCloseKeepBodyShell =>
      'คำสั่งยังรันอยู่เบื้องหลัง — เปิดเชลล์ใหม่ได้ทุกเมื่อจากแถบข้าง หากต้องการหยุดงานตอนนี้ ให้จบเชลล์แทน';

  @override
  String get ideCloseKeepBodyAgent =>
      'เอเจนต์ยังทำงานอยู่เบื้องหลัง — เปิดการสนทนาใหม่ได้ทุกเมื่อจากแถบข้าง หากต้องการจบรันตอนนี้ ให้หยุดเอเจนต์แทน';

  @override
  String get ideCloseKeepRunning => 'ให้รันต่อไป';

  @override
  String get ideCloseShutDownMachine => 'ปิดเครื่อง';

  @override
  String get ideCloseEndShell => 'จบเชลล์';

  @override
  String get ideCloseStopAgent => 'หยุดเอเจนต์';

  @override
  String get rigsSettingsSubtitle =>
      'สิ่งที่เซิร์ฟเวอร์นี้บูตได้ อิมเมจฐานที่ต้องใช้ และเครื่องที่กำลังรันอยู่';

  @override
  String get rigsCapabilitiesTitle => 'เซิร์ฟเวอร์นี้';

  @override
  String get rigInstallIosAutomation => 'ติดตั้งบริดจ์ระบบอัตโนมัติของ iOS';

  @override
  String get rigInstallingIosAutomation =>
      'กำลังติดตั้งบริดจ์ระบบอัตโนมัติของ iOS…';

  @override
  String get rigIosAutomationInstalled =>
      'ติดตั้งบริดจ์ระบบอัตโนมัติของ iOS แล้ว';

  @override
  String get rigsImagesTitle => 'อิมเมจฐาน';

  @override
  String get rigsImagesHint =>
      'ทุกริกบูตจากอิมเมจแบบอ่านอย่างเดียวเหล่านี้ แต่ละเซสชันเขียนลงโอเวอร์เลย์ทิ้งได้ ดังนั้นริกหนึ่งเปลี่ยนจุดเริ่มของริกถัดไปไม่ได้';

  @override
  String get rigsRunningTitle => 'กำลังรันอยู่';

  @override
  String get rigsNoneRunning => 'ไม่มีเครื่องที่กำลังรัน';

  @override
  String get rigsCustomImagesTitle => 'อิมเมจที่กำหนดเอง (เวิร์กสเปซนี้)';

  @override
  String get rigsCustomImagesHint =>
      'ชี้ Terminal (VM) หรือ Browser (VM) ไปยังอิมเมจของคุณ — ขยายค่าเริ่มต้นด้วยเครื่องมือที่โปรเจกต์ต้องการ หรือใช้อิมเมจที่เข้ากันได้จากรีจิสทรี เครื่องใหม่ใช้อิมเมจนี้ เครื่องที่รันอยู่ยังใช้อันเดิม ดูคู่มิกริกเรื่องสิ่งที่อิมเมจต้องมี';

  @override
  String get rigsCustomTerminalImageLabel => 'อิมเมจ Terminal (VM)';

  @override
  String get rigsCustomBrowserImageLabel => 'อิมเมจ Browser (VM)';

  @override
  String get rigsCustomImagePlaceholder =>
      'เช่น ghcr.io/acme/dev-shell:1.2 — เว้นว่างเพื่อใช้ค่าเริ่มต้น';

  @override
  String get rigsCustomImageInvalid =>
      'ใส่การอ้างอิงรีจิสทรี เช่น repo/name:tag ห้ามใช้พาธในเครื่องหรือไฟล์เก็บถาวร';

  @override
  String get rigsCustomImageSaved =>
      'บันทึกแล้ว เครื่องใหม่จะบูตอิมเมจนี้ เครื่องที่รันอยู่ยังใช้อันเดิม';

  @override
  String get rigsEgressTitle => 'เอเกรสของเบราว์เซอร์ (เวิร์กสเปซนี้)';

  @override
  String get rigsEgressHint =>
      'โฮสต์เพิ่มที่เบราว์เซอร์หุ้มเข้าถึงได้ — บรรทัดละหนึ่งรายการ: โฮสต์ตรงๆ (api.example.com) หรือไวลด์การ์ดซับโดเมน (*.example.com) ไซต์ของผลิตภัณฑ์ยังได้รับอนุญาตอยู่เสมอ เครื่องใหม่ได้รายการนี้ เครื่องที่รันอยู่ใช้ค่าตอนบูต';

  @override
  String rigsEgressInvalid(String host) {
    return '\"$host\" ไม่ใช่รายการโฮสต์ที่ถูกต้อง';
  }

  @override
  String get rigsEgressSaved =>
      'บันทึกแล้ว เครื่องเบราว์เซอร์ใหม่จะอนุญาตโฮสต์เหล่านี้ เครื่องที่รันอยู่ยังใช้อันเดิม';

  @override
  String get rigImageInstalled => 'ติดตั้งแล้ว';

  @override
  String get rigImageNotDownloaded => 'ยังไม่ได้ดาวน์โหลด';

  @override
  String get rigImageNotPublished => 'ยังไม่ได้เผยแพร่';

  @override
  String get rigImageNotPublishedHint =>
      'ยังไม่มีอิมเมจเผยแพร่สำหรับรายการนี้ จึงไม่มีอะไรให้ดาวน์โหลด นำเข้าอิมเมจดิสก์ที่เข้ากันได้เพื่อเปิดใช้';

  @override
  String get rigImageDownload => 'ดาวน์โหลด';

  @override
  String get rigImageDownloading => 'กำลังดาวน์โหลด…';

  @override
  String get rigImageImport => 'นำเข้า';

  @override
  String get rigImageImportMessage =>
      'พาธไปยังอิมเมจดิสก์ qcow2 บนระบบไฟล์ของเซิร์ฟเวอร์ จะถูกคัดลอกเข้าคลังอิมเมจ จึงย้ายไฟล์ต้นทางได้ภายหลัง';

  @override
  String get rigConnectingStream => 'กำลังเชื่อมต่อริก';

  @override
  String get rigStreamNotAllowed => 'คุณไม่มีสิทธิ์เข้าถึงริกนี้';

  @override
  String get rigStreamNotRunning => 'ริกนี้ไม่ได้รันอยู่แล้ว';

  @override
  String get rigStreamNeedsFfmpeg =>
      'มุมมองสดต้องมี ffmpeg บนโฮสต์นี้ ติดตั้ง ffmpeg แล้วเปิดแท็บใหม่';

  @override
  String get rigStreamEnded => 'มุมมองสดสิ้นสุดแล้ว';

  @override
  String get rigStreamFailed => 'เปิดมุมมองสดไม่ได้';

  @override
  String get rigStreamDisconnected => 'ไม่ได้เชื่อมต่อเซิร์ฟเวอร์';

  @override
  String rigDropSendingOne(String name) {
    return 'กำลังคัดลอก \"$name\" เข้าเครื่อง…';
  }

  @override
  String rigDropSendingMany(int count) {
    return 'กำลังคัดลอก $count ไฟล์เข้าเครื่อง…';
  }

  @override
  String get rigTerminalDropSending => 'กำลังคัดลอกเข้าเครื่อง…';

  @override
  String get rigTerminalPasteImage => 'บันทึกภาพที่วางลงในเครื่องแล้ว';

  @override
  String get rigPortsTitle => 'พอร์ตที่ส่งต่อ';

  @override
  String get rigPortsTooltip => 'พอร์ตที่เปิดอยู่ภายในเครื่องนี้';

  @override
  String get rigPortsEmpty =>
      'ยังไม่มีอะไรกำลังฟัง เริ่มเซิร์ฟเวอร์ในเทอร์มินัล — เซิร์ฟเวอร์พัฒนาที่พอร์ต 3000 จะปรากฏที่นี่';

  @override
  String get rigPortsAdd => 'เพิ่มพอร์ต';

  @override
  String get rigPortsAddHint => 'พอร์ตของเกสต์ที่จะส่งต่อ (เช่น 3000)';

  @override
  String get rigPortsAutoForward => 'ส่งต่อพอร์ตอัตโนมัติ';

  @override
  String get rigPortsCopyUrl => 'คัดลอก URL ในเครื่อง';

  @override
  String rigPortsCopiedUrl(String url) {
    return 'คัดลอก $url แล้ว';
  }

  @override
  String get rigPortsStopForward => 'หยุดส่งต่อ';

  @override
  String get rigPortsExposeLan => 'แชร์บนเครือข่ายภายใน';

  @override
  String get rigPortsLanPrivate => 'เฉพาะเครื่องนี้';

  @override
  String get rigPortsLanShared => 'บนเครือข่าย';

  @override
  String get rigPortsSetDomain => 'ตั้งโดเมนเบราว์เซอร์ (.test)';

  @override
  String get rigPortsDomainHint =>
      'โดเมนสำหรับ Browser (VM) เช่น myapp.test — เข้าถึงได้ที่นั่น ไม่ใช่บนโฮสต์';

  @override
  String get rigPortsProcessUnknown => 'โพรเซสที่ไม่ทราบ';

  @override
  String get rigPortsInactive => 'ไม่ได้ฟัง';

  @override
  String get rigPortsTooltipHost => 'พอร์ตที่เปิดในเทอร์มินัลนี้';

  @override
  String get rigPortsEmptyHost =>
      'ยังไม่มีอะไรกำลังฟังในเทอร์มินัลนี้ เริ่มเซิร์ฟเวอร์แล้วจะปรากฏที่นี่';

  @override
  String get rigPortsAddHintHost => 'พอร์ตที่จะแมป (เช่น 5173)';

  @override
  String get rigPortsLocalPortHint => 'พอร์ตภายในเครื่อง (ไม่บังคับ)';

  @override
  String rigPortsDestDesktop(int port) {
    return 'localhost:$port';
  }

  @override
  String rigPortsDestBrowser(int port) {
    return 'localhost:$port ในเบราว์เซอร์ (VM)';
  }

  @override
  String get rigPortsDestBrowserUnreachable =>
      'เบราว์เซอร์ (VM) ยังไม่เชื่อมต่อ';

  @override
  String rigPortsDestAndroid(int port) {
    return 'localhost:$port บน Android';
  }

  @override
  String get rigPortsDestAndroidUnreachable => 'Android ยังไม่เชื่อมต่อ';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ยังต้องดาวน์โหลดอิมเมจฐาน $count รายการ',
      one: 'ยังต้องดาวน์โหลดอิมเมจฐาน 1 รายการ',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => 'อนุญาต';

  @override
  String get guardrailDecisionPrompt => 'ถามก่อน';

  @override
  String get guardrailDecisionDeny => 'ปฏิเสธ';

  @override
  String get guardrailSourceThisScope => 'ขอบเขตนี้';

  @override
  String get guardrailSourceDefault => 'ค่าเริ่มต้นในตัว';

  @override
  String get guardrailSourcePreset => 'พรีเซ็ตโหมด';

  @override
  String get guardrailSourceInherited => 'สืบทอด';

  @override
  String get guardrailClearToInherited => 'ล้างเป็นสืบทอด';

  @override
  String get guardrailWhatIf => 'ถ้าหาก?';

  @override
  String get guardrailWhatIfDescription =>
      'ดูว่ากฎปัจจุบันจะตัดสินการกระทำอย่างไร ด้วยตรรกะเดียวกับที่เอเจนต์ใช้';

  @override
  String get guardrailProbeActionLabel => 'การกระทำ';

  @override
  String get guardrailProbeCommandLabel => 'คำสั่ง (ไม่บังคับ)';

  @override
  String get guardrailProbeCommandHint => 'เช่น git push origin main';

  @override
  String get guardrailProbeAgentLabel => 'เอเจนต์ (ไม่บังคับ)';

  @override
  String get guardrailProbeSpaceLabel => 'สเปซ (ไม่บังคับ)';

  @override
  String get guardrailProbeNone => 'ไม่มี';

  @override
  String get guardrailProbeModeLabel => 'โหมด';

  @override
  String get guardrailProbeResult => 'ผลลัพธ์';

  @override
  String get guardrailProbeSource => 'แหล่งที่มา:';

  @override
  String get guardrailAdapterMatrix => 'จุดที่บังคับใช้กฎ';

  @override
  String get guardrailAdapterMatrixDescription =>
      'ข้อมูลอ้างอิงตามจริง: แต่ละผลกระทบถูกจับที่ใด ต่อตัวรันเอเจนต์ นี่คือสภาพจริง ไม่ใช่การรับประกัน — ผลกระทบที่ตัวรันทำนอกแถบจะสกัดไม่ได้';

  @override
  String get guardrailEffectColumn => 'ผลกระทบ';

  @override
  String get guardrailAdapterHarness => 'ฮาร์เนสในตัว';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => 'พื้นแซนด์บ็อกซ์';

  @override
  String get guardrailEnforcementPolicyGate => 'ประตูนโยบาย';

  @override
  String get guardrailEnforcementSandbox => 'เฉพาะแซนด์บ็อกซ์';

  @override
  String get guardrailEnforcementNone => 'บังคับใช้ไม่ได้';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      'ตรวจการตัดสินสิทธิ์ก่อนให้ผลกระทบทำงาน และสามารถบล็อกได้';

  @override
  String get guardrailEnforcementSandboxHelp =>
      'มีแค่แซนด์บ็อกซ์ที่จำกัด ไม่ได้ปรึกษากฎสิทธิ์';

  @override
  String get guardrailEnforcementNoneHelp =>
      'การตัดสินเป็นเพียงคำแนะนำ — สกัดที่นี่ไม่ได้';

  @override
  String get obsStatCost => 'ค่าใช้จ่าย';

  @override
  String obsStatDelegatedCost(String amount) {
    return '+$amount ที่มอบหมาย';
  }

  @override
  String get obsStatDuration => 'ระยะเวลา';

  @override
  String get obsStatTokens => 'โทเค็น';

  @override
  String get obsStatTools => 'เครื่องมือ';

  @override
  String get openAgentActivity => 'เปิดกิจกรรม';

  @override
  String get orgChart => 'ผังองค์กร';

  @override
  String get orgChartEmpty => 'ยังไม่มีเอเจนต์';

  @override
  String get navCalendar => 'ปฏิทิน';

  @override
  String get serverConnection => 'การเชื่อมต่อเซิร์ฟเวอร์';

  @override
  String get serverModeLocal => 'รันในแอปนี้';

  @override
  String get serverModeLocalDescription =>
      'Control Center รันเซิร์ฟเวอร์ของตัวเองบนเครื่องนี้ และเก็บข้อมูลในเครื่อง';

  @override
  String get serverModeRemote => 'เชื่อมต่ออินสแตนซ์ระยะไกล';

  @override
  String get serverModeRemoteDescription =>
      'เชื่อมต่อเซิร์ฟเวอร์ Control Center ที่รันที่อื่น ข้อมูลของคุณอยู่บนเซิร์ฟเวอร์นั้น';

  @override
  String get serverRemoteUrl => 'URL ของเซิร์ฟเวอร์';

  @override
  String get serverRemoteDeviceId => 'ID อุปกรณ์';

  @override
  String get serverRemotePairingKey => 'คีย์จับคู่';

  @override
  String get serverRemotePairingKeyHint => 'วางคีย์จับคู่จากเซิร์ฟเวอร์ระยะไกล';

  @override
  String get serverSetupInviteCode => 'รหัสเชิญ';

  @override
  String get serverSetupInviteCodeHint =>
      'วางรหัสเชิญครั้งเดียว (เว้นว่างเพื่อใช้คีย์จับคู่)';

  @override
  String get serverDiscoveryTooltip => 'ค้นหาเซิร์ฟเวอร์ในเครือข่ายของคุณ';

  @override
  String get serverDiscoveryTitle => 'เซิร์ฟเวอร์ในเครือข่ายของคุณ';

  @override
  String get serverDiscoverySearching => 'กำลังค้นหาเซิร์ฟเวอร์…';

  @override
  String get serverDiscoveryEmpty =>
      'ไม่พบเซิร์ฟเวอร์ ตรวจว่าเซิร์ฟเวอร์กำลังรันและอุปกรณ์นี้เข้าถึงได้ แล้วค้นหาอีกครั้ง';

  @override
  String get serverDiscoveryRefresh => 'ค้นหาอีกครั้ง';

  @override
  String get serverListActive => 'ใช้งานอยู่';

  @override
  String get serverListSwitch => 'สลับ';

  @override
  String get serverListAddTitle => 'เพิ่มเซิร์ฟเวอร์';

  @override
  String get serverListRemoveActiveHint =>
      'สลับไปเซิร์ฟเวอร์อื่นก่อนลบรายการนี้';

  @override
  String get serverSwitchFailedTitle => 'สลับเซิร์ฟเวอร์ไม่ได้';

  @override
  String get serverListInsecureBadge => 'ไม่ปลอดภัย';

  @override
  String get connectionPathLocal => 'ในเครื่อง';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => 'กำลังปิดระบบ';

  @override
  String get shutdownSubtitle => 'กำลังปิดเซิร์ฟเวอร์ในเครื่อง';

  @override
  String get shutdownServiceApprovals => 'การอนุมัติ';

  @override
  String get shutdownServiceBackgroundJobs => 'งานเบื้องหลัง';

  @override
  String get shutdownServiceScheduler => 'ตัวจัดตารางงาน';

  @override
  String get shutdownServiceCalendar => 'ซิงค์ปฏิทิน';

  @override
  String get shutdownServiceWeather => 'สภาพอากาศ';

  @override
  String get shutdownServiceSoundscape => 'ซาวด์สเคป';

  @override
  String get shutdownServiceMeetings => 'การประชุม';

  @override
  String get shutdownServiceVoiceModels => 'โมเดลเสียง';

  @override
  String get shutdownServiceNetworking => 'เครือข่าย';

  @override
  String get shutdownServicePresence => 'สถานะออนไลน์';

  @override
  String get shutdownServiceDataSync => 'ซิงค์ข้อมูล';

  @override
  String get shutdownServiceDeviceRelay => 'รีเลย์อุปกรณ์';

  @override
  String get shutdownServiceMcpConnections => 'การเชื่อมต่อ MCP';

  @override
  String get shutdownServiceCodeEditors => 'ตัวแก้ไขโค้ด';

  @override
  String get serverSharingTitle => 'แชร์เซิร์ฟเวอร์นี้';

  @override
  String get serverSharingDescription =>
      'ให้เซิร์ฟเวอร์นี้เข้าถึงได้จากอุปกรณ์อื่นของคุณ จะไม่เปิดสู่สาธารณะจนกว่าคุณจะเปิดทันเนลด้านล่าง คำเชิญจับคู่ฝังที่อยู่ปัจจุบันของเซิร์ฟเวอร์โดยอัตโนมัติ — สร้างได้ที่การตั้งค่าเวิร์กสเปซ';

  @override
  String get serverSharingUnavailable =>
      'ตัวควบคุมการแชร์ใช้ไม่ได้บนเซิร์ฟเวอร์นี้';

  @override
  String get serverSharingMdnsLabel => 'การค้นหาใน LAN';

  @override
  String get serverSharingMdnsOn =>
      'กำลังประกาศเซิร์ฟเวอร์นี้บนเครือข่ายภายใน (mDNS)';

  @override
  String get serverSharingMdnsOff => 'ไม่ได้ประกาศบนเครือข่ายภายใน (mDNS)';

  @override
  String get serverSharingTunnelLabel => 'ทันเนล';

  @override
  String get serverSharingTunnelHelper =>
      'เปิดทันเนลจะทำให้เซิร์ฟเวอร์นี้เข้าถึงได้จากอินเทอร์เน็ต การเปิดสู่สาธารณะต้องเลือกเอง และปิดเป็นค่าเริ่มต้น';

  @override
  String get serverSharingProviderOff => 'ปิด';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => 'URL สาธารณะ';

  @override
  String get serverSharingTunnelStarting => 'กำลังเริ่มทันเนล…';

  @override
  String serverSharingTunnelError(String error) {
    return 'ข้อผิดพลาดทันเนล: $error';
  }

  @override
  String get serverSharingTunnelUpNoUrl =>
      'ทันเนลพร้อมแล้ว เข้าถึงได้ที่ชื่อโฮสต์ DNS ที่ตั้งไว้';

  @override
  String get serverSharingRelayLabel => 'รีเลย์';

  @override
  String serverSharingRelayUsage(String amount) {
    return 'รีเลย์เดือนนี้: $amount';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return 'เซสชันรีเลย์ที่ใช้งาน: $count';
  }

  @override
  String get serverSharingUpdateFailedTitle => 'อัปเดตการแชร์ไม่ได้';

  @override
  String get pairNewClient => 'จับคู่ไคลเอนต์ใหม่';

  @override
  String get pairClientNameHint =>
      'ตั้งชื่อไคลเอนต์นี้ (เช่น แล็ปท็อปที่ทำงาน)';

  @override
  String get pairClientTypeWeb => 'เว็บเบราว์เซอร์';

  @override
  String get pairClientTypeDesktop => 'แอปเดสก์ท็อป';

  @override
  String get pairClientTypePhone => 'โทรศัพท์';

  @override
  String get pairAction => 'จับคู่';

  @override
  String get revoke => 'เพิกถอน';

  @override
  String get pairCredentialsIntro =>
      'เชื่อมต่อไคลเอนต์ใหม่ด้วยรายละเอียดเหล่านี้ หรือเปิดลิงก์ในไคลเอนต์นั้น';

  @override
  String get pairLinkLabel => 'ลิงก์';

  @override
  String get pairScanQr => 'สแกน QR โค้ดนี้ด้วยกล้องโทรศัพท์เพื่อจับคู่';

  @override
  String get pairServerUnreachableTitle => 'เข้าถึงไม่ได้';

  @override
  String get pairServerUnreachable =>
      'อุปกรณ์อื่นเข้าถึงเซิร์ฟเวอร์นี้โดยตรงไม่ได้ จึงเชื่อมต่อไคลเอนต์ใหม่ไม่ได้ ตั้ง URL สาธารณะของเซิร์ฟเวอร์เพื่อจับคู่ไคลเอนต์เพิ่ม';

  @override
  String get serverSetupTitle => 'Control Center ควรรันอย่างไร?';

  @override
  String get serverSetupSubtitle =>
      'Control Center ต้องมีเซิร์ฟเวอร์ที่เป็นเจ้าของข้อมูลของคุณ รันในแอปนี้ หรือเชื่อมต่ออินสแตนซ์ที่รันที่อื่น';

  @override
  String get serverSetupRunLocal => 'รันในแอปนี้';

  @override
  String get serverSetupConnect => 'เชื่อมต่อ';

  @override
  String get serverSetupInvalidUrl =>
      'ใส่ URL เซิร์ฟเวอร์ ws:// หรือ wss:// ที่ถูกต้อง';

  @override
  String get serverSetupCouldNotConnect => 'เชื่อมต่อไม่ได้';

  @override
  String get serverSetupErrorUnreachable =>
      'เข้าถึงเซิร์ฟเวอร์ไม่ได้ ตรวจว่ากำลังรันและอุปกรณ์นี้เข้าถึงได้ (เครือข่ายเดียวกันหรือรีเลย์)';

  @override
  String get serverSetupErrorIdentityMismatch =>
      'ตัวตนของเซิร์ฟเวอร์ไม่ตรงกับที่บันทึกในอุปกรณ์นี้ หากเซิร์ฟเวอร์ถูกติดตั้งใหม่หรือรีเซ็ต ให้ลบเซิร์ฟเวอร์ที่บันทึกแล้วจับคู่ใหม่';

  @override
  String get serverSetupErrorAuthRejected =>
      'เซิร์ฟเวอร์ปฏิเสธอุปกรณ์นี้ ตรวจว่าคีย์จับคู่และ ID อุปกรณ์ตรงกับที่เซิร์ฟเวอร์ออกให้';

  @override
  String get serverSetupErrorInviteRejected =>
      'รหัสเชิญไม่ถูกต้องหรือหมดอายุแล้ว ขอรหัสใหม่';

  @override
  String get serverSetupErrorGeneric =>
      'เกิดข้อผิดพลาดขณะเชื่อมต่อ ขยายรายละเอียดทางเทคนิคด้านล่างเพื่อดูข้อมูลเพิ่ม';

  @override
  String get serverSetupErrorDetails => 'รายละเอียดทางเทคนิค';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'อีก $count รายการ',
      one: 'อีก 1 รายการ',
    );
    return '$_temp0';
  }

  @override
  String get calendarAllDayGutter => 'ทั้งวัน';

  @override
  String calendarAllDayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count เหตุการณ์',
      one: '1 เหตุการณ์',
    );
    return '$_temp0';
  }

  @override
  String get calendarCollapseAllDay => 'ยุบเหตุการณ์ทั้งวัน';

  @override
  String get calendarExpandAllDay => 'ขยายเหตุการณ์ทั้งวัน';

  @override
  String get calendarViewMonth => 'เดือน';

  @override
  String get calendarViewWeek => 'สัปดาห์';

  @override
  String get calendarViewAgenda => 'วาระ';

  @override
  String get calendarConnectGoogle => 'เชื่อมต่อ Google Calendar';

  @override
  String get calendarConnectDescription =>
      'ซิงค์ Google Calendar เพื่อดูเหตุการณ์ที่นี่ และรับการแจ้งเตือนก่อนการประชุมเริ่ม';

  @override
  String get calendarDisconnect => 'ยกเลิกการเชื่อมต่อ';

  @override
  String get calendarReconnect => 'เชื่อมต่ออีกครั้ง';

  @override
  String get calendarEmptyNoEvents => 'ไม่มีเหตุการณ์ในช่วงนี้';

  @override
  String get calendarStartRecording => 'เริ่มบันทึก';

  @override
  String get calendarStartRecordingAndLink => 'เริ่มบันทึกและลิงก์';

  @override
  String get calendarJoinMeet => 'เข้าร่วมการประชุม';

  @override
  String get calendarFromCalendar => 'จากปฏิทิน';

  @override
  String get calendarLinkedMeeting => 'การประชุมที่ลิงก์แล้ว';

  @override
  String get calendarToday => 'วันนี้';

  @override
  String get calendarAllDay => 'ทั้งวัน';

  @override
  String calendarWeekNumber(int number) {
    return 'สัปดาห์ $number';
  }

  @override
  String get calendarPreviousPeriod => 'ก่อนหน้า';

  @override
  String get calendarNextPeriod => 'ถัดไป';

  @override
  String calendarLastSynced(String time) {
    return 'ซิงค์แล้ว $time';
  }

  @override
  String get calendarNeverSynced => 'ยังไม่ได้ซิงค์';

  @override
  String get calendarSyncing => 'กำลังซิงค์…';

  @override
  String get calendarViewDay => 'วัน';

  @override
  String get calendarShow => 'แสดง';

  @override
  String get calendarHide => 'ซ่อน';

  @override
  String get calendarRsvpGoing => 'ไปหรือไม่?';

  @override
  String get calendarRsvpYes => 'ไป';

  @override
  String get calendarRsvpNo => 'ไม่ไป';

  @override
  String get calendarRsvpMaybe => 'อาจไป';

  @override
  String get calendarRsvpFailed => 'อัปเดตคำตอบไม่ได้';

  @override
  String get calendarAddAccount => 'เพิ่มบัญชีปฏิทิน';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'เชื่อมบัญชี Google เพื่อซิงค์เหตุการณ์เข้าพื้นที่นี้ ปฏิทินเหล่านี้เป็นของคุณที่นี่';

  @override
  String get calendarConnecting => 'กำลังเชื่อมต่อ…';

  @override
  String get calendarSyncNow => 'ซิงค์ตอนนี้';

  @override
  String get calendarNoWorkspace => 'เลือกเวิร์กสเปซเพื่อดูปฏิทิน';

  @override
  String get calendarConnectError => 'เชื่อมต่อ Google Calendar ไม่ได้';

  @override
  String get calendarClientIdLabel => 'Client ID';

  @override
  String get calendarClientSecretLabel => 'Client secret';

  @override
  String get calendarConnectCredsHint =>
      'ใส่ Client ID และ secret ของ Google OAuth แบบ device-code สำหรับโปรเจกต์ของคุณ เซิร์ฟเวอร์เป็นผู้เชื่อมต่อและซิงค์ — เบราว์เซอร์ไม่เก็บโทเค็น';

  @override
  String get calendarConnectApproveInstruction =>
      'เปิดหน้ายืนยันบนอุปกรณ์ใดก็ได้ ลงชื่อเข้าใช้ แล้วใส่รหัสนี้:';

  @override
  String get calendarConnectOpenPage => 'เปิดหน้ายืนยัน';

  @override
  String get calendarConnectWaiting => 'กำลังรอการอนุมัติ…';

  @override
  String get calendarConnectDenied => 'การอนุญาตถูกปฏิเสธ โปรดลองอีกครั้ง';

  @override
  String get calendarConnectExpired => 'รหัสหมดอายุแล้ว โปรดลองอีกครั้ง';

  @override
  String get notificationMeetingStartsSoon => 'การประชุมกำลังจะเริ่ม';

  @override
  String get notifyMeetingStartsSoon => 'เมื่อการประชุมในปฏิทินใกล้เริ่ม';

  @override
  String get notificationCalendarAuthExpiredTitle => 'ปฏิทินถูกตัดการเชื่อมต่อ';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'เชื่อมต่อ $email อีกครั้งเพื่อซิงค์ต่อ';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'เชื่อมต่อปฏิทินอีกครั้งเพื่อซิงค์ต่อ';

  @override
  String get notifyCalendarAuthExpired => 'เมื่อบัญชีปฏิทินต้องเชื่อมต่อใหม่';

  @override
  String get notificationRigStatusChanged => 'อัปเดตเอนโคลเจอร์';

  @override
  String get notifyRigStatusChanged =>
      'เมื่อเอนโคลเจอร์ถูกเข้าควบคุม ถูกยึดคืน หรือล้มเหลว';

  @override
  String get notificationRigTakenOver => 'เอนโคลเจอร์ถูกเข้าควบคุม';

  @override
  String get notificationRigTakenOverBody =>
      'มีคนกำลังขับเครื่องอยู่ เอเจนต์ดูได้แต่ทำอะไรไม่ได้';

  @override
  String get notificationRigReleased => 'ปล่อยการควบคุมเอนโคลเจอร์แล้ว';

  @override
  String get notificationRigReleasedBody => 'เอเจนต์ได้เครื่องคืนแล้ว';

  @override
  String get notificationRigReclaimed => 'ยึดคืนเอนโคลเจอร์แล้ว';

  @override
  String get notificationRigReclaimedBodyIdle =>
      'เครื่องว่างนาน จึงปิดเพื่อคืนหน่วยความจำ';

  @override
  String get notificationRigReclaimedBodyTtl => 'ถึงขีดจำกัดเวลาแล้วจึงถูกปิด';

  @override
  String get notificationRigFailed => 'เอนโคลเจอร์ล้มเหลว';

  @override
  String get notificationRigFailedBody =>
      'ไฮเปอร์ไวเซอร์ด้านล่างตายแล้ว เปิดเครื่องอีกครั้งเพื่อทำงานต่อ';

  @override
  String get calendarAlertLeadTime => 'เวลาก่อนแจ้งเตือน';

  @override
  String get calendarAlertLeadTimeSubtitle => 'แจ้งเตือนก่อนการประชุมนานเท่าใด';

  @override
  String calendarConnectedAs(String email) {
    return 'เชื่อมต่อเป็น $email';
  }

  @override
  String calendarAttendeesCount(int count) {
    return 'ผู้เข้าร่วม $count คน';
  }

  @override
  String get calendarEventLabel => 'เหตุการณ์';

  @override
  String get calendarRecurring => 'เหตุการณ์ที่เกิดซ้ำ';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'ผู้จัด';

  @override
  String get calendarYou => 'คุณ';

  @override
  String get calendarShowFewer => 'แสดงน้อยลง';

  @override
  String get calendarRsvpAwaiting => 'รอตอบ';

  @override
  String calendarParticipantsCount(int count) {
    return 'ผู้เข้าร่วม $count คน';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'ดูผู้เข้าร่วมทั้งหมด $count คน';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return 'ไป $count';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return 'ไม่ไป $count';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return 'อาจไป $count';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return 'รอตอบ $count';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count นาที';
  }

  @override
  String get openInEditorPrompt => 'เปิดในตัวแก้ไขใด?';

  @override
  String get ideNotInstalled => 'ไม่ได้ติดตั้ง';

  @override
  String openInIde(String editor) {
    return 'เปิดใน $editor';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return 'เปิด $editor ไม่ได้: $error';
  }

  @override
  String get profileSearchHint => 'ค้นหา pull request…';

  @override
  String get stopAgentRun => 'หยุดรัน';

  @override
  String get stopAgentRunConfirm => 'หยุดรันนี้หรือไม่? งานที่ค้างอยู่จะหายไป';

  @override
  String get inProgress => 'กำลังดำเนินการ';

  @override
  String get drafts => 'ฉบับร่าง';

  @override
  String get sortOldest => 'เก่าสุด';

  @override
  String get sortLargest => 'ใหญ่สุด';

  @override
  String get prFilterTooltip => 'ตัวกรอง';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ตัวกรองที่ใช้งาน',
      one: '1 ตัวกรองที่ใช้งาน',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => 'เพิ่มตัวกรอง…';

  @override
  String get prFilterFieldHint => 'กรอง…';

  @override
  String get prFilterCategoryStatus => 'สถานะ';

  @override
  String get prFilterCategoryAuthor => 'ผู้เขียน';

  @override
  String get prFilterCategoryReviewer => 'ผู้รีวิว';

  @override
  String get prFilterCategoryContent => 'เนื้อหา';

  @override
  String get prFilterCategoryRepoOwner => 'เจ้าของรีโพสิทอรี';

  @override
  String get prFilterCategoryRepoName => 'ชื่อรีโพสิทอรี';

  @override
  String get prFilterCategoryOpenedDate => 'วันที่เปิด';

  @override
  String get prFilterCategoryUpdatedDate => 'วันที่อัปเดต';

  @override
  String get prFilterQuickToReview => 'รีวิวได้เร็ว';

  @override
  String get prFilterClearAll => 'ล้างตัวกรอง';

  @override
  String prFilterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull request',
      one: '1 pull request',
    );
    return '$_temp0';
  }

  @override
  String prFilterHiddenOptions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ตัวเลือกที่ไม่ตรงกับ pull request ใด',
      one: '1 ตัวเลือกที่ไม่ตรงกับ pull request ใด',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => 'ชื่อหรือเนื้อหาประกอบด้วย…';

  @override
  String get prFilterNoOptions => 'ไม่มีตัวเลือกที่ตรง';

  @override
  String get prFilterChipIs => 'คือ';

  @override
  String get prFilterChipIsAnyOf => 'เป็นหนึ่งใน';

  @override
  String get prFilterChipContains => 'ประกอบด้วย';

  @override
  String get prFilterChipSince => 'ตั้งแต่';

  @override
  String get prFilterAddFilterButton => 'เพิ่มตัวกรอง';

  @override
  String prFilterClearCategory(String category) {
    return 'ล้างตัวกรอง $category';
  }

  @override
  String get prFilterCurrentUser => 'ผู้ใช้ปัจจุบัน';

  @override
  String get prStatusDraft => 'ฉบับร่าง';

  @override
  String get prStatusOpen => 'เปิด';

  @override
  String get prStatusInReview => 'กำลังรีวิว';

  @override
  String get prStatusChangesRequested => 'ขอให้แก้ไข';

  @override
  String get prStatusApproved => 'อนุมัติแล้ว';

  @override
  String get prStatusMerged => 'รวมแล้ว';

  @override
  String get prStatusClosed => 'ปิดแล้ว';

  @override
  String get prDateWindowDay => '1 วันที่แล้ว';

  @override
  String get prDateWindowThreeDays => '3 วันที่แล้ว';

  @override
  String get prDateWindowWeek => '1 สัปดาห์ที่แล้ว';

  @override
  String get prDateWindowMonth => '1 เดือนที่แล้ว';

  @override
  String get prDateWindowThreeMonths => '3 เดือนที่แล้ว';

  @override
  String get prDateWindowSixMonths => '6 เดือนที่แล้ว';

  @override
  String get prDateWindowYear => '1 ปีที่แล้ว';

  @override
  String get prDisplayOptions => 'ตัวเลือกการแสดง';

  @override
  String get prDisplayGrouping => 'การจัดกลุ่ม';

  @override
  String get prDisplayOrdering => 'การเรียงลำดับ';

  @override
  String get prDisplayShowDrafts => 'แสดงฉบับร่าง';

  @override
  String get prDisplayMergedWindow => 'ช่วงที่รวมแล้ว';

  @override
  String get prDisplayMergedWindowDay => 'วันที่ผ่านมา';

  @override
  String get prDisplayMergedWindowWeek => 'สัปดาห์ที่ผ่านมา';

  @override
  String get prDisplayMergedWindowMonth => 'เดือนที่ผ่านมา';

  @override
  String get prDisplayProperties => 'คุณสมบัติที่แสดง';

  @override
  String get prGroupingRepository => 'รีโพสิทอรี';

  @override
  String get prGroupingAuthor => 'ผู้เขียน';

  @override
  String get prGroupingStatus => 'สถานะ';

  @override
  String get prGroupingNone => 'ไม่จัดกลุ่ม';

  @override
  String get prPropertyRepository => 'รีโพสิทอรี';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => 'สาขา';

  @override
  String get prPropertyUpdated => 'อัปเดตแล้ว';

  @override
  String get prPropertyAuthor => 'ผู้เขียน';

  @override
  String get prPropertyChecks => 'การตรวจ';

  @override
  String get prPropertyDiff => 'Diff';

  @override
  String get prPropertyComments => 'ความคิดเห็น';

  @override
  String get keybindingOpenFilterMenu => 'เปิดเมนูตัวกรอง';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'เปิดเมนูตัวกรอง pull request';

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เลือกแล้ว $count รายการ',
      one: 'เลือกแล้ว 1 รายการ',
    );
    return '$_temp0';
  }

  @override
  String get summary => 'สรุป';

  @override
  String get kbMove => 'ย้าย';

  @override
  String get kbTabs => 'แท็บ';

  @override
  String get kbSearch => 'ค้นหา';

  @override
  String get kbViewed => 'ดูแล้ว';

  @override
  String get kbCollapse => 'ยุบ';

  @override
  String get appearance => 'ลักษณะ';

  @override
  String get appearanceSettingsDescription => 'ธีม ภาษา และตัวอักษร';

  @override
  String get notificationsSettingsDescription =>
      'เลือกเหตุการณ์ของเอเจนต์และเวิร์กสเปซที่จะแจ้งเตือนคุณ';

  @override
  String get advanced => 'ขั้นสูง';

  @override
  String get accounts => 'บัญชี';

  @override
  String get mcpServers => 'เซิร์ฟเวอร์ MCP';

  @override
  String get mcpServersSettingsDescription =>
      'เซิร์ฟเวอร์ MCP ในตัวและเซิร์ฟเวอร์ MCP ภายนอก';

  @override
  String get remoteControlAndDevices => 'รีโมตคอนโทรลและอุปกรณ์';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'จับคู่โทรศัพท์และกำหนดค่าเซิร์ฟเวอร์รีโมตคอนโทรล';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'โมเดลการพูดและการแยกผู้พูดที่เซิร์ฟเวอร์นี้โฮสต์';

  @override
  String get needsSetupLabel => 'ต้องตั้งค่า';

  @override
  String get collapseSidebar => 'ยุบแถบข้าง';

  @override
  String get expandSidebar => 'ขยายแถบข้าง';

  @override
  String get filterSpacesHint => 'กรองสเปซ';

  @override
  String noSpacesMatch(String query) {
    return 'ไม่มีสเปซที่ตรงกับ \"$query\"';
  }

  @override
  String get privacy => 'ความเป็นส่วนตัว';

  @override
  String get sendDiffContentTitle => 'ส่งเนื้อหา diff ไปยังอะแดปเตอร์ AI';

  @override
  String get diffSharingOnSubtitle =>
      'บรรทัด diff ดิบถูกรวมในพรอมต์ของเอเจนต์เพื่อรีวิวลึกขึ้น';

  @override
  String get diffSharingOffSubtitle =>
      'เอเจนต์ใช้เฉพาะเมตาดาต้าที่มีโครงสร้าง (พาธไฟล์ หมายเลขบรรทัด คำอธิบาย PR) ไม่มีโค้ดดิบออกจากแอป';

  @override
  String get errorReportingTitle => 'แชร์รายงานข้อขัดข้อง';

  @override
  String get errorReportingOnSubtitle =>
      'ส่งการวินิจฉัยข้อขัดข้อง ข้อผิดพลาด และประสิทธิภาพเพื่อช่วยแก้บั๊ก (เฉพาะบิลด์เผยแพร่)';

  @override
  String get errorReportingOffSubtitle =>
      'ปิดการวินิจฉัยแล้ว จะไม่ส่งรายงานข้อขัดข้องหรือข้อผิดพลาด';

  @override
  String get onboardingDiagnosticsTitle => 'ช่วยปรับปรุง Control Center';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'ส่งการวินิจฉัยข้อขัดข้อง ข้อผิดพลาด และประสิทธิภาพ เพื่อแก้ปัญหาได้เร็วขึ้น (เฉพาะบิลด์เผยแพร่) เปลี่ยนได้ทุกเมื่อที่ การตั้งค่า → ความเป็นส่วนตัว';

  @override
  String get blocked => 'ถูกบล็อก';

  @override
  String get idle => 'ว่าง';

  @override
  String get noRunsYet => 'ยังไม่มีรัน';

  @override
  String get copyPath => 'คัดลอกพาธ';

  @override
  String get copyRelativePath => 'คัดลอกพาธสัมพัทธ์';

  @override
  String get nameRequired => 'ต้องระบุชื่อ';

  @override
  String get import => 'นำเข้า';

  @override
  String get noMatchingAgents => 'ไม่มีเอเจนต์ที่ตรงกับตัวกรอง';

  @override
  String watchVideoOn(String provider) {
    return 'ดูวิดีโอบน $provider';
  }

  @override
  String get branchTemplate => 'เทมเพลตชื่อสาขา';

  @override
  String get branchTemplateDescription =>
      'รูปแบบชื่อสาขาที่สร้างเมื่อเริ่มตั๋วงานใน worktree ที่แยก';

  @override
  String branchTemplatePreview(String example) {
    return 'ตัวอย่าง: $example';
  }

  @override
  String get deletePipelineRun => 'ลบรันไปป์ไลน์';

  @override
  String deletePipelineRunConfirm(String template) {
    return 'ลบรันนี้ของ \"$template\" หรือไม่? เลิกทำไม่ได้';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'เกิดข้อผิดพลาดขณะลบรันไปป์ไลน์: $error';
  }

  @override
  String get deleteTicket => 'ลบตั๋วงาน';

  @override
  String deleteTicketConfirm(String title) {
    return 'ลบ \"$title\" หรือไม่? เลิกทำไม่ได้';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'เกิดข้อผิดพลาดขณะลบตั๋วงาน: $error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return 'ลบ \"$name\" หรือไม่? รีโพสิทอรีที่ลิงก์บนดิสก์จะไม่ถูกแตะต้อง';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'เกิดข้อผิดพลาดขณะลบเวิร์กสเปซ: $error';
  }

  @override
  String get indexCode => 'จัดทำดัชนีโค้ด';

  @override
  String get indexNoGrammars => 'ยังไม่ได้ติดตั้งไวยากรณ์โค้ด';

  @override
  String get indexFailed => 'จัดทำดัชนีไม่สำเร็จ';

  @override
  String indexedSymbolsCount(int count) {
    return 'จัดทำดัชนีสัญลักษณ์แล้ว $count รายการ';
  }

  @override
  String get nodeConfigAdvanced => 'ขั้นสูง';

  @override
  String get nodeConfigReducer => 'ตัวลดทอน';

  @override
  String get nodeConfigReducerHelp =>
      'วิธีรวมเมื่อคีย์เอาต์พุตนี้มีค่าอยู่แล้ว';

  @override
  String get nodeConfigTimeoutMs => 'หมดเวลา (ms)';

  @override
  String get nodeConfigRetryAttempts => 'ครั้งที่ลองใหม่';

  @override
  String get nodeConfigContinueOnFail => 'ทำต่อหากขั้นตอนนี้ล้มเหลว';

  @override
  String get nodeConfigTeamId => 'ID ทีม';

  @override
  String get nodeConfigDispatchMode => 'โหมดจัดส่ง';

  @override
  String get nodeConfigOutputSchema => 'สคีมาเอาต์พุต (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'JSON Schema ที่เอาต์พุตของขั้นตอนต้องผ่าน';

  @override
  String get diffLineDisplay => 'บรรทัดยาวใน diff';

  @override
  String get diffLineDisplayDescription => 'ตัดบรรทัดยาวหรือเลื่อนในแนวนอน';

  @override
  String get diffLineWrap => 'ตัดบรรทัด';

  @override
  String get diffLineScroll => 'เลื่อนในแนวนอน';

  @override
  String get actions => 'การกระทำ';

  @override
  String get activate => 'เปิดใช้';

  @override
  String get activity => 'กิจกรรม';

  @override
  String get activityLabel => 'กิจกรรม';

  @override
  String get activitySearchHint => 'ค้นหากิจกรรม';

  @override
  String get activityNoMatches => 'ไม่มีกิจกรรมที่ตรงกับตัวกรอง';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$start–$end จาก $total';
  }

  @override
  String get activityPreviousPage => 'หน้าก่อนหน้า';

  @override
  String get activityNextPage => 'หน้าถัดไป';

  @override
  String get activityNetworkLocal => 'Localhost';

  @override
  String get activityClearFilter => 'ล้างตัวกรอง';

  @override
  String activityFilterIp(String ip) {
    return 'IP $ip';
  }

  @override
  String activityFilterCountry(String country) {
    return 'ประเทศ $country';
  }

  @override
  String get activitySavedWorkspaceLogo => 'บันทึกโลโก้เวิร์กสเปซแล้ว';

  @override
  String activityVerbCreated(String target) {
    return 'สร้าง $target';
  }

  @override
  String activityVerbUpdated(String target) {
    return 'อัปเดต $target';
  }

  @override
  String activityVerbDeleted(String target) {
    return 'ลบ $target';
  }

  @override
  String activityVerbAdded(String target) {
    return 'เพิ่ม $target';
  }

  @override
  String activityVerbRemoved(String target) {
    return 'ลบ $target ออก';
  }

  @override
  String activityVerbInvited(String target) {
    return 'เชิญ $target';
  }

  @override
  String activityVerbChanged(String target) {
    return 'เปลี่ยน $target';
  }

  @override
  String activityVerbStarted(String target) {
    return 'เริ่ม $target';
  }

  @override
  String activityVerbStopped(String target) {
    return 'หยุด $target';
  }

  @override
  String activityVerbWrote(String target) {
    return 'เขียน $target';
  }

  @override
  String get activityTargetAgent => 'เอเจนต์';

  @override
  String get activityTargetTicket => 'ตั๋วงาน';

  @override
  String get activityTargetWorkspace => 'เวิร์กสเปซ';

  @override
  String get activityTargetRepository => 'รีโพสิทอรี';

  @override
  String get activityTargetMember => 'สมาชิก';

  @override
  String get activityTargetInvite => 'คำเชิญ';

  @override
  String get activityTargetSpace => 'สเปซ';

  @override
  String get activityTargetMessage => 'ข้อความ';

  @override
  String get activityTargetCache => 'แคช';

  @override
  String get activityTargetFile => 'ไฟล์';

  @override
  String get activityTargetPipeline => 'ไปป์ไลน์';

  @override
  String get activityTargetTemplate => 'เทมเพลต';

  @override
  String get activityTargetProvider => 'ผู้ให้บริการ';

  @override
  String get activityTargetModel => 'โมเดล';

  @override
  String get activityTargetSkill => 'สกิล';

  @override
  String get activityTargetTodo => 'สิ่งที่ต้องทำ';

  @override
  String get activityTargetMeeting => 'การประชุม';

  @override
  String get activityTargetProject => 'โปรเจกต์';

  @override
  String get activityTargetTeam => 'ทีม';

  @override
  String get activityTargetDevice => 'อุปกรณ์';

  @override
  String get activityTargetPreference => 'ค่ากำหนด';

  @override
  String get activityTargetBudget => 'งบประมาณ';

  @override
  String activityVerbApproved(String target) {
    return 'อนุมัติ $target';
  }

  @override
  String activityVerbArchived(String target) {
    return 'เก็บถาวร $target';
  }

  @override
  String activityVerbAssigned(String target) {
    return 'มอบหมาย $target';
  }

  @override
  String activityVerbBackedUp(String target) {
    return 'สำรอง $target';
  }

  @override
  String activityVerbCancelled(String target) {
    return 'ยกเลิก $target';
  }

  @override
  String activityVerbCleared(String target) {
    return 'ล้าง $target';
  }

  @override
  String activityVerbClosed(String target) {
    return 'ปิด $target';
  }

  @override
  String activityVerbCommitted(String target) {
    return 'คอมมิต $target';
  }

  @override
  String activityVerbCompacted(String target) {
    return 'ย่อ $target';
  }

  @override
  String activityVerbCompleted(String target) {
    return 'ทำ $target เสร็จ';
  }

  @override
  String activityVerbConnected(String target) {
    return 'เชื่อมต่อ $target';
  }

  @override
  String activityVerbContinued(String target) {
    return 'ทำ $target ต่อ';
  }

  @override
  String activityVerbDisconnected(String target) {
    return 'ตัดการเชื่อมต่อ $target';
  }

  @override
  String activityVerbDispatched(String target) {
    return 'จัดส่ง $target';
  }

  @override
  String activityVerbDrained(String target) {
    return 'ระบาย $target';
  }

  @override
  String activityVerbEnrolled(String target) {
    return 'ลงทะเบียน $target';
  }

  @override
  String activityVerbEstimated(String target) {
    return 'ประมาณ $target';
  }

  @override
  String activityVerbImported(String target) {
    return 'นำเข้า $target';
  }

  @override
  String activityVerbInstalled(String target) {
    return 'ติดตั้ง $target';
  }

  @override
  String activityVerbKilled(String target) {
    return 'ฆ่า $target';
  }

  @override
  String activityVerbMarked(String target) {
    return 'ทำเครื่องหมาย $target';
  }

  @override
  String activityVerbMerged(String target) {
    return 'รวม $target';
  }

  @override
  String activityVerbOpened(String target) {
    return 'เปิด $target';
  }

  @override
  String activityVerbPaused(String target) {
    return 'หยุดชั่วคราว $target';
  }

  @override
  String activityVerbPolled(String target) {
    return 'โพล $target';
  }

  @override
  String activityVerbPrepared(String target) {
    return 'เตรียม $target';
  }

  @override
  String activityVerbProcessed(String target) {
    return 'ประมวลผล $target';
  }

  @override
  String activityVerbPublished(String target) {
    return 'เผยแพร่ $target';
  }

  @override
  String activityVerbRefined(String target) {
    return 'ปรับ $target';
  }

  @override
  String activityVerbRefreshed(String target) {
    return 'รีเฟรช $target';
  }

  @override
  String activityVerbRegistered(String target) {
    return 'ลงทะเบียน $target';
  }

  @override
  String activityVerbRenamed(String target) {
    return 'เปลี่ยนชื่อ $target';
  }

  @override
  String activityVerbReordered(String target) {
    return 'จัดลำดับ $target ใหม่';
  }

  @override
  String activityVerbResponded(String target) {
    return 'ตอบ $target';
  }

  @override
  String activityVerbRestored(String target) {
    return 'กู้คืน $target';
  }

  @override
  String activityVerbResumed(String target) {
    return 'ทำ $target ต่อ';
  }

  @override
  String activityVerbRetried(String target) {
    return 'ลอง $target ใหม่';
  }

  @override
  String activityVerbReverted(String target) {
    return 'ย้อน $target';
  }

  @override
  String activityVerbReviewed(String target) {
    return 'รีวิว $target';
  }

  @override
  String activityVerbRan(String target) {
    return 'รัน $target';
  }

  @override
  String activityVerbSelected(String target) {
    return 'เลือก $target';
  }

  @override
  String activityVerbSent(String target) {
    return 'ส่ง $target';
  }

  @override
  String activityVerbStaged(String target) {
    return 'สเตจ $target';
  }

  @override
  String activityVerbSteered(String target) {
    return 'ชี้นำ $target';
  }

  @override
  String activityVerbSubmitted(String target) {
    return 'ส่ง $target';
  }

  @override
  String activityVerbSynced(String target) {
    return 'ซิงค์ $target';
  }

  @override
  String activityVerbToggled(String target) {
    return 'สลับ $target';
  }

  @override
  String activityVerbUninstalled(String target) {
    return 'ถอนการติดตั้ง $target';
  }

  @override
  String activityVerbUnstaged(String target) {
    return 'เลิกสเตจ $target';
  }

  @override
  String get activityTargetActionPolicy => 'นโยบายการกระทำ';

  @override
  String get activityTargetGoalRun => 'รันเป้าหมาย';

  @override
  String get activityTargetRunLog => 'บันทึกรัน';

  @override
  String get activityTargetWorkingMemory => 'หน่วยความจำทำงาน';

  @override
  String get activityTargetRoutingPolicy => 'นโยบายการกำหนดเส้นทาง';

  @override
  String get activityTargetAutonomy => 'ความเป็นอิสระ';

  @override
  String get activityTargetCalendar => 'ปฏิทิน';

  @override
  String get activityTargetChecker => 'ตัวตรวจ';

  @override
  String get activityTargetEditor => 'ตัวแก้ไข';

  @override
  String get activityTargetConfirmation => 'การยืนยัน';

  @override
  String get activityTargetTunnel => 'ทันเนล';

  @override
  String get activityTargetConversation => 'การสนทนา';

  @override
  String get activityTargetCredentials => 'ข้อมูลรับรอง';

  @override
  String get activityTargetDictation => 'การป้อนด้วยเสียง';

  @override
  String get activityTargetAgentRun => 'รันของเอเจนต์';

  @override
  String get activityTargetEvalSuite => 'ชุด eval';

  @override
  String get activityTargetWorker => 'เวิร์กเกอร์';

  @override
  String get activityTargetWorktree => 'worktree';

  @override
  String get activityTargetMcpServer => 'เซิร์ฟเวอร์ MCP';

  @override
  String get activityTargetMemoryAccessGrant => 'สิทธิ์เข้าถึงหน่วยความจำ';

  @override
  String get activityTargetMemoryDomain => 'โดเมนหน่วยความจำ';

  @override
  String get activityTargetMemoryFact => 'ข้อเท็จจริงในหน่วยความจำ';

  @override
  String get activityTargetMemoryPolicy => 'นโยบายหน่วยความจำ';

  @override
  String get activityTargetFeed => 'ฟีด';

  @override
  String get activityTargetNote => 'บันทึก';

  @override
  String get activityTargetOrchestration => 'การประสานงาน';

  @override
  String get activityTargetPipelineRun => 'รันไปป์ไลน์';

  @override
  String get activityTargetPipelineTrigger => 'ทริกเกอร์ไปป์ไลน์';

  @override
  String get activityTargetPlan => 'แผน';

  @override
  String get activityTargetPlaybook => 'เพลย์บุ๊ก';

  @override
  String get activityTargetPullRequest => 'pull request';

  @override
  String get activityTargetReview => 'รีวิว';

  @override
  String get activityTargetProcess => 'โพรเซส';

  @override
  String get activityTargetProviderPolicy => 'นโยบายผู้ให้บริการ';

  @override
  String get activityTargetReaction => 'ปฏิกิริยา';

  @override
  String get activityTargetReviewSpace => 'สเปซรีวิว';

  @override
  String get activityTargetReviewStudio => 'สตูดิโอรีวิว';

  @override
  String get activityTargetServerData => 'ข้อมูลเซิร์ฟเวอร์';

  @override
  String get activityTargetSoundscape => 'ซาวด์สเคป';

  @override
  String get activityTargetSession => 'เซสชัน';

  @override
  String get activityTargetTerminal => 'เทอร์มินัล';

  @override
  String get activityTargetTicketLink => 'ลิงก์ตั๋วงาน';

  @override
  String get activityTargetTicketSync => 'ซิงค์ตั๋วงาน';

  @override
  String get activityTargetProfile => 'โปรไฟล์';

  @override
  String get activityTargetVoiceProfile => 'โปรไฟล์เสียง';

  @override
  String get activityTargetWeather => 'พยากรณ์อากาศ';

  @override
  String get activityTargetWorkProduct => 'ผลงาน';

  @override
  String get activityChangedMemberRole => 'เปลี่ยนบทบาทของสมาชิก';

  @override
  String get activityChangedMemberRepoAccess =>
      'เปลี่ยนสิทธิ์รีโพสิทอรีของสมาชิก';

  @override
  String get activityUpdatedGitHubToken => 'อัปเดตโทเค็น GitHub';

  @override
  String get activityRefreshedWeather => 'รีเฟรชพยากรณ์อากาศ';

  @override
  String get activitySetWeatherLocation => 'ตั้งตำแหน่งสภาพอากาศ';

  @override
  String get activityClearedWeatherLocation => 'ล้างตำแหน่งสภาพอากาศ';

  @override
  String get activityMarkedAllArticlesRead =>
      'ทำเครื่องหมายบทความทั้งหมดว่าอ่านแล้ว';

  @override
  String get activityMarkedArticleRead => 'ทำเครื่องหมายบทความว่าอ่านแล้ว';

  @override
  String get activityUpdatedSavedArticle => 'อัปเดตบทความที่บันทึกไว้';

  @override
  String get activityTookOverSession => 'เข้าควบคุมเซสชัน';

  @override
  String get activityHandedBackSession => 'คืนเซสชัน';

  @override
  String get activityCommittedAndPushed => 'คอมมิตและพุชแล้ว';

  @override
  String get activityBackedUpServer => 'สำรองข้อมูลเซิร์ฟเวอร์';

  @override
  String get activityMarkedSpaceRead => 'ทำเครื่องหมายสเปซว่าอ่านแล้ว';

  @override
  String get activityRespondedToInvitation => 'ตอบคำเชิญเหตุการณ์';

  @override
  String get activityStartedCalendarConnect => 'เริ่มเชื่อมต่อปฏิทิน';

  @override
  String get activityDisconnectedCalendar => 'ตัดการเชื่อมต่อปฏิทิน';

  @override
  String get activityMarkedFileViewed => 'ทำเครื่องหมายไฟล์ว่าดูแล้ว';

  @override
  String get activityRespondedToApproval => 'ตอบคำขออนุมัติ';

  @override
  String get activityChangedTunnel => 'เปลี่ยนการตั้งค่าทันเนล';

  @override
  String get activitySentMessageToAgent => 'ส่งข้อความถึงเอเจนต์';

  @override
  String get activityOpenedReviewSpace => 'เปิดสเปซรีวิว';

  @override
  String get activityOpenedStandingConversation => 'เปิดการสนทนาประจำ';

  @override
  String get activityStartedRecording => 'เริ่มการบันทึก';

  @override
  String get activityStoppedRecording => 'หยุดการบันทึก';

  @override
  String get activityToggledMcpServer => 'สลับเซิร์ฟเวอร์ MCP';

  @override
  String get activityUpdatedMcpToken => 'อัปเดตโทเค็น MCP';

  @override
  String get activitySavedApiKey => 'บันทึกคีย์ API';

  @override
  String get activityRemovedProviderCredential => 'ลบข้อมูลรับรองผู้ให้บริการ';

  @override
  String get activityUpdatedLinkedRepos => 'อัปเดตรีโพสิทอรีที่ลิงก์';

  @override
  String get activityUnlinkedRepo => 'เลิกลิงก์รีโพสิทอรี';

  @override
  String get activityUpdatedActionItem => 'อัปเดตรายการที่ต้องทำ';

  @override
  String adRulesCount(int count) {
    return 'กฎโฆษณา $count ข้อ';
  }

  @override
  String get adapter => 'อะแดปเตอร์';

  @override
  String get adapterLabel => 'อะแดปเตอร์';

  @override
  String get adapters => 'อะแดปเตอร์';

  @override
  String get adaptersAutoDetected =>
      'ตรวจพบตัวรันเอเจนต์ที่ใช้ได้บนเครื่องนี้ ติดตั้ง CLI ที่ขาดเพื่อเปิดใช้ตัวรันเพิ่ม';

  @override
  String get add => 'เพิ่ม';

  @override
  String get addAComment => 'เพิ่มความคิดเห็น';

  @override
  String get addAReaction => 'เพิ่มปฏิกิริยา';

  @override
  String get addASuggestion => 'เพิ่มข้อเสนอแนะ';

  @override
  String get addAgents => 'เพิ่มเอเจนต์';

  @override
  String get addEmoji => 'เพิ่มอิโมจิ';

  @override
  String get addFeed => 'เพิ่มฟีด';

  @override
  String get addressBarHint => 'ใส่ URL';

  @override
  String get addFromFile => 'เพิ่มจากไฟล์';

  @override
  String get addGif => 'เพิ่ม GIF';

  @override
  String get addGithubRepoPrompt =>
      'เพิ่มรีโพสิทอรี GitHub อย่างน้อยหนึ่งรายการเพื่อดู pull request';

  @override
  String get addLocalCheckoutDescription =>
      'เพิ่มเช็กเอาต์ในเครื่องเพื่อเริ่มกำหนดเป้าหมายจากเวิร์กสเปซนี้';

  @override
  String get addRepository => 'เพิ่มรีโพสิทอรี';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เพิ่ม $count รีโพสิทอรี',
      one: 'เพิ่มรีโพสิทอรี',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro =>
      'เรียกดูโฟลเดอร์บนเครื่องที่รันเซิร์ฟเวอร์ แล้วเลือกเช็กเอาต์ git ที่จะลงทะเบียน';

  @override
  String get selectThisFolder => 'เลือกโฟลเดอร์นี้';

  @override
  String get deselectThisFolder => 'ยกเลิกการเลือกโฟลเดอร์นี้';

  @override
  String get goUp => 'ขึ้น';

  @override
  String get noSubfoldersHere => 'ไม่มีโฟลเดอร์ย่อยที่นี่';

  @override
  String get notAGitRepository => 'โฟลเดอร์นี้ไม่ใช่รีโพสิทอรี git';

  @override
  String get addToken => 'เพิ่มโทเค็น';

  @override
  String get addWorkspace => 'เพิ่มเวิร์กสเปซ';

  @override
  String get addWorkspaceEllipsis => 'เพิ่มเวิร์กสเปซ…';

  @override
  String get added => 'เพิ่มแล้ว';

  @override
  String get addingEllipsis => 'กำลังเพิ่ม…';

  @override
  String get advancedLabel => 'ขั้นสูง';

  @override
  String get agent => 'เอเจนต์';

  @override
  String conversationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count การสนทนา',
      one: '1 การสนทนา',
    );
    return '$_temp0';
  }

  @override
  String agentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count เอเจนต์',
      one: '1 เอเจนต์',
    );
    return '$_temp0';
  }

  @override
  String get agentMdPath => 'พาธ Agent MD';

  @override
  String get agentName => 'ชื่อเอเจนต์';

  @override
  String get agentTitle => 'ตำแหน่งเอเจนต์';

  @override
  String get agentUpdated => 'อัปเดตเอเจนต์แล้ว';

  @override
  String get agents => 'เอเจนต์';

  @override
  String get agentsMentionSection => 'เอเจนต์';

  @override
  String get usersMentionSection => 'บุคคล';

  @override
  String get ticketsMentionSection => 'ตั๋วงาน';

  @override
  String get pullRequestsMentionSection => 'Pull request';

  @override
  String get meetingsMentionSection => 'การประชุม';

  @override
  String get entityRefTicketFallback => 'ตั๋วงาน';

  @override
  String get entityRefPrFallback => 'Pull request';

  @override
  String get entityRefMeetingFallback => 'การประชุม';

  @override
  String get aiReview => 'รีวิว AI';

  @override
  String get all => 'ทั้งหมด';

  @override
  String get allAgentsAlreadyInSpace => 'เอเจนต์ทั้งหมดอยู่ในสเปซนี้แล้ว';

  @override
  String get allCommits => 'คอมมิตทั้งหมด';

  @override
  String get allSources => 'แหล่งทั้งหมด';

  @override
  String get allow => 'อนุญาต';

  @override
  String get allowGitPush => 'อนุญาต git push';

  @override
  String get allowGithubApi => 'อนุญาตการเรียก GitHub API';

  @override
  String get allowNetwork => 'อนุญาตการเข้าถึงเครือข่ายทั่วไป';

  @override
  String get apiKeys => 'คีย์ API';

  @override
  String get appFont => 'แบบอักษรแอป';

  @override
  String get appLogLevelDebugDescription =>
      'เพิ่มร่องรอยโดยละเอียด — สำหรับการพัฒนา';

  @override
  String get appLogLevelDebugLabel => 'ดีบัก';

  @override
  String get appLogLevelErrorDescription =>
      'เฉพาะข้อผิดพลาดและข้อยกเว้นที่ไม่คาดคิด';

  @override
  String get appLogLevelErrorLabel => 'ข้อผิดพลาด';

  @override
  String get appLogLevelInfoDescription => 'เพิ่มข้อความวงจรชีวิตและสถานะ';

  @override
  String get appLogLevelInfoLabel => 'ข้อมูล';

  @override
  String get appLogLevelNoneDescription => 'ไม่แสดงเอาต์พุตคอนโซลเลย';

  @override
  String get appLogLevelNoneLabel => 'ไม่มี';

  @override
  String get appLogLevelVerboseDescription =>
      'ทุกอย่าง เสียงดังมาก — ใช้เพื่อดีบักเท่านั้น';

  @override
  String get appLogLevelVerboseLabel => 'ละเอียด';

  @override
  String get appLogLevelWarningDescription =>
      'เพิ่มคำเตือนและปัญหาที่กู้คืนได้';

  @override
  String get appLogLevelWarningLabel => 'คำเตือน';

  @override
  String get appearanceLanguage => 'ลักษณะและภาษา';

  @override
  String get apply => 'ใช้';

  @override
  String get approve => 'อนุมัติ';

  @override
  String get agentApprovalRequired => 'ต้องอนุมัติ';

  @override
  String agentApprovalsMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'รออีก $count รายการ',
      one: 'รออีก 1 รายการ',
    );
    return '$_temp0';
  }

  @override
  String get approved => 'อนุมัติแล้ว';

  @override
  String get articleNoun => 'บทความ';

  @override
  String get articlesSubscribed => 'บทความจากฟีดที่คุณติดตาม';

  @override
  String get askAi => 'ถาม AI';

  @override
  String get askAiReviewDescription => 'ให้ AI รีวิว PR นี้';

  @override
  String get assignees => 'ผู้รับมอบหมาย';

  @override
  String get attachImage => 'แนบภาพ';

  @override
  String get attachedAgents => 'เอเจนต์ที่แนบ';

  @override
  String get audioInput => 'อินพุตเสียง';

  @override
  String get audioOutput => 'เอาต์พุตเสียง';

  @override
  String get authenticationToken => 'โทเค็นยืนยันตัวตน';

  @override
  String authoredByLabel(String role) {
    return 'โดย: $role';
  }

  @override
  String get autoRecommended => 'อัตโนมัติ (แนะนำ)';

  @override
  String get available => 'พร้อมใช้';

  @override
  String get awaitingYourReview => 'รอรีวิวจากคุณ';

  @override
  String get back => 'กลับ';

  @override
  String get backLabel => 'กลับ';

  @override
  String get backend => 'แบ็กเอนด์';

  @override
  String get blockAdsTrackers => 'บล็อกโฆษณา ตัวติดตาม และแบนเนอร์คุกกี้';

  @override
  String get blocking => 'กำลังบล็อก';

  @override
  String get bookmarkLabel => 'บุ๊กมาร์ก';

  @override
  String get briefDescription => 'คำอธิบายสั้น ๆ';

  @override
  String get bugLabel => 'บั๊ก';

  @override
  String get bundledDefaultsNeverUpdated =>
      'ค่าเริ่มต้นที่มาพร้อมชุด — ไม่เคยอัปเดต';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get cancelEdit => 'ยกเลิกการแก้ไข';

  @override
  String get categoryCreation => 'การสร้าง';

  @override
  String get categoryEditing => 'การแก้ไข';

  @override
  String get categoryNavigation => 'การนำทาง';

  @override
  String get categorySystem => 'ระบบ';

  @override
  String get categoryView => 'มุมมองหมวดหมู่';

  @override
  String get change => 'เปลี่ยน';

  @override
  String get changesRequested => 'ขอให้แก้ไข';

  @override
  String get spacesMentionSection => 'สเปซ';

  @override
  String get checkForUpdates => 'ตรวจหาอัปเดต';

  @override
  String get checking => 'กำลังตรวจ';

  @override
  String get checkingEllipsis => 'กำลังตรวจ…';

  @override
  String get chooseAppFont => 'เลือกแบบอักษรแอป';

  @override
  String get chooseCodeFont => 'เลือกแบบอักษรโค้ด';

  @override
  String get chooseRunner => 'เลือกตัวรันเอเจนต์';

  @override
  String get clear => 'ล้าง';

  @override
  String get clickToRetry => 'คลิกเพื่อลองใหม่';

  @override
  String get close => 'ปิด';

  @override
  String get closeEsc => 'ปิด (Esc)';

  @override
  String get closeReader => 'ปิดตัวอ่าน';

  @override
  String get closed => 'ปิดแล้ว';

  @override
  String get codeFont => 'แบบอักษรโค้ด';

  @override
  String get codeFontLigatures => 'ลิเกเจอร์แบบอักษรโค้ด';

  @override
  String get codeFontLigaturesDescription =>
      'แสดงลิเกเจอร์การเขียนโปรแกรม (=>, !=, ->) เป็นไกลฟ์รวมในโค้ดและ diff';

  @override
  String get collapse => 'ยุบ';

  @override
  String get commandPalette => 'จานคำสั่ง';

  @override
  String get commandPaletteOrgMembers => 'สมาชิกองค์กร';

  @override
  String get commandPaletteBrowseTeam => 'เรียกดูทีม';

  @override
  String get commandPaletteBrowseTeamDesc => 'ดูสมาชิกองค์กรทั้งหมด';

  @override
  String get compactDone => 'ย่อการสนทนาแล้ว ประวัติก่อนหน้าถูกพับเป็นสรุป';

  @override
  String get compactNothing => 'ยังไม่มีอะไรให้ย่อ การสนทนายังสั้นอยู่';

  @override
  String get compactBusy => 'เอเจนต์ยังทำงานอยู่ ย่อเมื่อเทิร์นนี้จบ';

  @override
  String get compactUnavailable => 'การย่อใช้ไม่ได้บนเซิร์ฟเวอร์นี้';

  @override
  String get commandsMentionSection => 'คำสั่ง';

  @override
  String get comment => 'ความคิดเห็น';

  @override
  String get commentOnThisFile => 'แสดงความคิดเห็นในไฟล์นี้';

  @override
  String get commented => 'แสดงความคิดเห็นแล้ว';

  @override
  String get commits => 'คอมมิต';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'แสดงล่าสุด $loaded จาก $total คอมมิต';
  }

  @override
  String get prCloneProgressCloningTitle => 'กำลังโคลนรีโพสิทอรี';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'PR นี้เปลี่ยน $fileCount ไฟล์ ซึ่งเกินขีดจำกัด API ของ GitHub กำลังโคลนรีโพสิทอรีในเครื่อง…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'PR นี้เกินขีดจำกัดไฟล์ของ GitHub API กำลังโคลนรีโพสิทอรีในเครื่อง…';

  @override
  String get prCloneProgressFetchingTitle => 'กำลังดึง refs ของ PR';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'กำลังดึงสาขาฐานและ ref หัวของ PR…';

  @override
  String get prCloneProgressComputingTitle => 'กำลังคำนวณ diff';

  @override
  String get prCloneProgressComputingSubtitle => 'กำลังรัน git diff ในเครื่อง…';

  @override
  String get prCloneProgressErrorTitle => 'โหลด diff ไม่ได้';

  @override
  String get prCloneProgressErrorSubtitle =>
      'เกิดข้อผิดพลาดขณะโคลนหรือคำนวณ diff โปรดลองรีเฟรช';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'ยังทำงานอยู่… ผ่านไป $elapsed';
  }

  @override
  String confidenceLabel(int percent) {
    return 'ความมั่นใจ: $percent%';
  }

  @override
  String get configureAgentIdentities =>
      'กำหนดตัวตน พรอมต์ สกิลของเอเจนต์ และดูรัน';

  @override
  String get configureDefaultRunners =>
      'กำหนดอะแดปเตอร์และโมเดลที่ใช้กับสเปซใหม่และการสร้างชื่อ';

  @override
  String get configuredLabel => 'ตั้งค่าแล้ว';

  @override
  String get confirmedBy => 'ยืนยันโดย';

  @override
  String get consensus => 'ฉันทามติ';

  @override
  String get contentHint => 'สิ่งที่ควรจำไว้';

  @override
  String get contentLabel => 'เนื้อหา';

  @override
  String get contentMarkdown => 'เนื้อหา (Markdown)';

  @override
  String get contextWindowSize => 'ขนาดหน้าต่างบริบท';

  @override
  String modelContextChip(String size) {
    return 'โมเดล · $size';
  }

  @override
  String get continueLabel => 'ดำเนินการต่อ';

  @override
  String get conversationMode => 'โหมด';

  @override
  String cookieRulesCount(int count) {
    return 'กฎคุกกี้ $count ข้อ';
  }

  @override
  String get copied => 'คัดลอกแล้ว!';

  @override
  String get copy => 'คัดลอก';

  @override
  String get copyAddress => 'คัดลอกที่อยู่';

  @override
  String get copyBaseBranchTooltip => 'คัดลอกชื่อสาขาฐาน';

  @override
  String get copyHeadBranchTooltip => 'คัดลอกชื่อสาขาหัว';

  @override
  String couldNotListDevices(String error) {
    return 'แสดงรายการอุปกรณ์ไม่ได้: $error';
  }

  @override
  String get create => 'สร้าง';

  @override
  String get createOrSelectWorkspace =>
      'สร้างหรือเลือกเวิร์กสเปซก่อนเพิ่มรีโพสิทอรี';

  @override
  String get createPullRequest => 'สร้าง pull request';

  @override
  String get createdByMe => 'สร้างโดยฉัน';

  @override
  String createdLabel(String date) {
    return 'สร้างเมื่อ: $date';
  }

  @override
  String get currentParticipants => 'ผู้เข้าร่วมปัจจุบัน';

  @override
  String get customCapabilitiesDescription => 'คำอธิบายความสามารถที่กำหนดเอง';

  @override
  String get customSystemPrompt => 'พรอมต์ระบบที่กำหนดเองสำหรับเอเจนต์นี้...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count วันที่แล้ว',
      one: '1 วันที่แล้ว',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'ปิดใช้';

  @override
  String get defaultCapabilities => 'ความสามารถเริ่มต้น · สเปซใหม่';

  @override
  String get defaultChat => 'แชทเริ่มต้น';

  @override
  String get defaultRunners => 'ตัวรันเริ่มต้น';

  @override
  String get delete => 'ลบ';

  @override
  String get deleteAgent => 'ลบเอเจนต์';

  @override
  String deleteAgentConfirm(String name) {
    return 'ลบ \"$name\" หรือไม่? เลิกทำไม่ได้';
  }

  @override
  String get deleteSpace => 'ลบสเปซ';

  @override
  String deleteConfirmName(String name) {
    return 'ลบ \"$name\" หรือไม่?';
  }

  @override
  String get archiveConversation => 'เก็บถาวรการสนทนา';

  @override
  String get deleteFact => 'ลบข้อเท็จจริง';

  @override
  String get deleteFeedBody =>
      'การดำเนินการนี้จะลบฟีดและบทความที่แคชไว้ทั้งหมด บทความที่บุ๊กมาร์กจากฟีดนี้จะถูกลบด้วย';

  @override
  String deleteFeedConfirm(String name) {
    return 'ลบ \"$name\" หรือไม่?';
  }

  @override
  String get deletePolicy => 'ลบนโยบาย';

  @override
  String get deletePolicyConfirm => 'ลบนโยบายนี้หรือไม่? เลิกทำไม่ได้';

  @override
  String deleteTopicConfirm(String topic) {
    return 'ลบ \"$topic\" หรือไม่? เลิกทำไม่ได้';
  }

  @override
  String get deleteWorkspace => 'ลบเวิร์กสเปซ';

  @override
  String get deny => 'ปฏิเสธ';

  @override
  String get detailsLabel => 'รายละเอียด';

  @override
  String get descriptionLabel => 'คำอธิบาย';

  @override
  String detectedBackend(String label) {
    return 'ตรวจพบ: $label';
  }

  @override
  String get detectedRunners => 'ตัวรันที่ตรวจพบ';

  @override
  String get detectingAdapters => 'กำลังตรวจจับอะแดปเตอร์…';

  @override
  String get detectingInputDevices => 'กำลังตรวจจับอุปกรณ์อินพุต…';

  @override
  String detectionFailed(String error) {
    return 'ตรวจจับไม่สำเร็จ: $error';
  }

  @override
  String get disabled => 'ปิดใช้';

  @override
  String get discover => 'ค้นพบ';

  @override
  String get dismissed => 'ปิดแล้ว';

  @override
  String get domainHint => 'เช่น api-performance';

  @override
  String get domainLabel => 'โดเมน';

  @override
  String get download => 'ดาวน์โหลด';

  @override
  String get downloadingLabel => 'กำลังดาวน์โหลด';

  @override
  String downloadingModel(int pct) {
    return 'กำลังดาวน์โหลดโมเดล… $pct%';
  }

  @override
  String get draft => 'ฉบับร่าง';

  @override
  String get draftLabel => 'ฉบับร่าง';

  @override
  String get edit => 'แก้ไข';

  @override
  String get edited => 'แก้ไขแล้ว';

  @override
  String get editMessage => 'แก้ไขข้อความ';

  @override
  String get revertToThere => 'ย้อนกลับไปที่นั่น';

  @override
  String get sendAsNewMessage => 'ส่งเป็นข้อความใหม่';

  @override
  String get editMessageChoiceBody =>
      'การย้อนกลับจะซ่อนข้อความหลังจากข้อความนี้และย้อนไฟล์ของเอเจนต์ คุณเลิกทำได้ การส่งเป็นข้อความใหม่จะคงการสนทนาไว้เหมือนเดิม';

  @override
  String get deleteMessage => 'ลบข้อความ';

  @override
  String get deleteMessageConfirm => 'ลบข้อความนี้หรือไม่? เลิกทำไม่ได้';

  @override
  String get messageDeleted => 'ลบข้อความแล้ว';

  @override
  String get searchInConversation => 'ค้นหาในการสนทนา';

  @override
  String get searchMessagesHint => 'ค้นหาข้อความ…';

  @override
  String get noMessagesFound => 'ไม่พบข้อความ';

  @override
  String get editFact => 'แก้ไขข้อเท็จจริง';

  @override
  String get editPolicy => 'แก้ไขนโยบาย';

  @override
  String get editSuggestedCodeHint => 'แก้ไขโค้ดที่เสนอ…';

  @override
  String get editSuggestion => 'แก้ไขข้อเสนอแนะ';

  @override
  String get egArchitect => 'เช่น architect';

  @override
  String get egControlCenter => 'เช่น control-center';

  @override
  String get egPlatform => 'เช่น Platform';

  @override
  String get egSamuelAlev => 'เช่น SamuelAlev';

  @override
  String get egSoftwareArchitect => 'เช่น Software Architect';

  @override
  String get egTheVerge => 'เช่น The Verge';

  @override
  String get egTokenLimit => 'เช่น 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'ติดตั้งไม่สำเร็จ: $error';
  }

  @override
  String get embeddingInstalled =>
      'ติดตั้งโมเดลฝังตัวในเครื่องแล้ว เปิดใช้การค้นหาแบบไฮบริดแล้ว';

  @override
  String get embeddingModel => 'โมเดลฝังตัว (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'ยังไม่ได้ติดตั้ง การค้นหาจะใช้เฉพาะคำสำคัญจนกว่าจะเปิดใช้';

  @override
  String get embeddingRedownloadBody =>
      'ไฟล์โมเดลที่มีอยู่จะถูกลบและดาวน์โหลดใหม่ การค้นหาเชิงความหมายจะใช้ไม่ได้จนกว่าจะดาวน์โหลดเสร็จ';

  @override
  String get embeddingRemoveBody =>
      'การค้นหาเชิงความหมายจะถูกปิดจนกว่าจะติดตั้งอีกครั้ง ติดตั้งใหม่ได้ทุกเมื่อ';

  @override
  String get speakerDiarization => 'การแยกผู้พูด';

  @override
  String get diarizationModel => 'โมเดลแยกผู้พูด';

  @override
  String get diarizationInstalled =>
      'ติดตั้งแล้ว — ระบุชื่อผู้พูดแต่ละคนในถอดเสียงการประชุม';

  @override
  String get diarizationNotInstalled =>
      'ยังไม่ได้ติดตั้ง — จะไม่แยกผู้พูดในการประชุม';

  @override
  String diarizationInstallFailed(String error) {
    return 'ติดตั้งไม่สำเร็จ: $error';
  }

  @override
  String get redownloadDiarizationModel => 'ดาวน์โหลดโมเดลแยกผู้พูดอีกครั้ง';

  @override
  String get diarizationRedownloadBody =>
      'การดำเนินการนี้จะลบโมเดลแยกผู้พูดปัจจุบันแล้วดาวน์โหลดใหม่';

  @override
  String get removeDiarizationModel => 'ลบโมเดลแยกผู้พูด';

  @override
  String get diarizationRemoveBody =>
      'การดำเนินการนี้จะลบโมเดลแยกผู้พูดบนอุปกรณ์ ถอดเสียงการประชุมที่มีอยู่แล้วจะไม่ได้รับผลกระทบ';

  @override
  String get enableNotifications => 'เปิดการแจ้งเตือน';

  @override
  String get enableSandboxing => 'เปิดใช้แซนด์บ็อกซ์';

  @override
  String get enabled => 'เปิดใช้';

  @override
  String errorCreatingAgent(String error) {
    return 'เกิดข้อผิดพลาดขณะสร้างเอเจนต์: $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'เกิดข้อผิดพลาดขณะลบเอเจนต์: $error';
  }

  @override
  String errorWithDetail(String error) {
    return 'ข้อผิดพลาด: $error';
  }

  @override
  String get expand => 'ขยาย';

  @override
  String extractingModel(int pct) {
    return 'กำลังแตกโมเดล… $pct%';
  }

  @override
  String get fact => 'ข้อเท็จจริง';

  @override
  String factCount(int count) {
    return 'ข้อเท็จจริง $count รายการ';
  }

  @override
  String factCountPlural(int count) {
    return 'ข้อเท็จจริง $count รายการ';
  }

  @override
  String get facts => 'ข้อเท็จจริง';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return 'ข้อเท็จจริง $factCount รายการ · นโยบาย $policyCount รายการ';
  }

  @override
  String get failed => 'ล้มเหลว';

  @override
  String failedToDispatch(String error) {
    return 'จัดส่งไม่ได้: $error';
  }

  @override
  String get failedToLoad => 'โหลดไม่ได้';

  @override
  String failedToLoadAgents(String error) {
    return 'โหลดเอเจนต์ไม่ได้: $error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'โหลดฟีดไม่ได้: $error';
  }

  @override
  String get failedToLoadGifs => 'โหลด GIF ไม่ได้';

  @override
  String failedToLoadLogs(String error) {
    return 'โหลดบันทึกไม่ได้: $error';
  }

  @override
  String get failedToLoadRepos => 'โหลดรีโพสิทอรีไม่ได้';

  @override
  String get failedToLoadWorkspaces => 'โหลดเวิร์กสเปซไม่ได้';

  @override
  String failedToStartAiReview(String error) {
    return 'เริ่มรีวิว AI ไม่ได้: $error';
  }

  @override
  String get failedToStartMicTest => 'เริ่มทดสอบไมค์ไม่ได้';

  @override
  String failedToSubmitReview(String error) {
    return 'ส่งรีวิวไม่ได้: $error';
  }

  @override
  String failedToUpload(String name, String error) {
    return 'อัปโหลด $name ไม่ได้: $error';
  }

  @override
  String failedWithError(String error) {
    return 'ล้มเหลว: $error';
  }

  @override
  String get failure => 'ความล้มเหลว';

  @override
  String get feedAlreadyExists => 'มีฟีดที่ใช้ URL นี้อยู่แล้ว';

  @override
  String get feedUrlExample => 'เช่น https://example.com/feed.xml';

  @override
  String get feedUrlLabel => 'URL ของฟีด';

  @override
  String feedsCount(int count) {
    return 'ฟีด ($count)';
  }

  @override
  String get filesChanged => 'ไฟล์ที่เปลี่ยน';

  @override
  String filesCount(int count) {
    return '$count ไฟล์';
  }

  @override
  String get filesMentionSection => 'ไฟล์';

  @override
  String get filterAgents => 'กรองเอเจนต์...';

  @override
  String get filterFilesHint => 'กรองไฟล์…';

  @override
  String get filterLists => 'รายการตัวกรอง';

  @override
  String get filterSkillsPlaceholder => 'กรองสกิล…';

  @override
  String get finish => 'เสร็จสิ้น';

  @override
  String get fix => 'แก้';

  @override
  String get forward => 'ไปข้างหน้า';

  @override
  String get gatesGithubPatPush =>
      'ควบคุมการฉีด GitHub PAT จำเป็นเพื่อให้เอเจนต์พุชได้';

  @override
  String get general => 'ทั่วไป';

  @override
  String get githubLink => 'ลิงก์ GitHub';

  @override
  String get claudeStatusFetchFailed => 'เข้าถึง status.claude.com ไม่ได้';

  @override
  String get claudeStatusOpenInBrowser => 'เปิด status.claude.com';

  @override
  String get githubStatusFetchFailed => 'เข้าถึง githubstatus.com ไม่ได้';

  @override
  String get githubDegradedTitle => 'GitHub รายงานปัญหา';

  @override
  String githubDegradedStatusLine(String status) {
    return 'สถานะ GitHub: $status';
  }

  @override
  String githubDegradedBody(String status) {
    return 'สถานะ GitHub: $status ข้อมูล pull request อาจเก่าหรือไม่ครบจนกว่าจะกลับมาปกติ';
  }

  @override
  String get githubStatusOpenInBrowser => 'เปิด githubstatus.com';

  @override
  String get githubStatusRefresh => 'รีเฟรช';

  @override
  String githubStatusUpdated(String time) {
    return 'อัปเดต $time';
  }

  @override
  String get kimiStatusFetchFailed => 'เข้าถึง status.moonshot.cn ไม่ได้';

  @override
  String get kimiStatusOpenInBrowser => 'เปิด status.moonshot.cn';

  @override
  String get openaiStatusFetchFailed => 'เข้าถึง status.openai.com ไม่ได้';

  @override
  String get openaiStatusOpenInBrowser => 'เปิด status.openai.com';

  @override
  String get serviceStatusMaintenance => 'บำรุงรักษา';

  @override
  String get serviceStatusMajorIssues => 'ปัญหาใหญ่';

  @override
  String get serviceStatusMinorIssues => 'ปัญหาเล็กน้อย';

  @override
  String get serviceStatusOperational => 'ทำงานปกติ';

  @override
  String get serviceStatusOutage => 'ขัดข้อง';

  @override
  String get serviceStatusTitle => 'สถานะบริการ';

  @override
  String get serviceStatusUnknown => 'ไม่ทราบ';

  @override
  String lastChecked(String time) {
    return 'ตรวจเมื่อ $time';
  }

  @override
  String get lastCheckedRecently => 'ตรวจเมื่อไม่นานมานี้';

  @override
  String get giveYourWorkAHome => 'ให้งานของคุณมีที่อยู่';

  @override
  String get goBack => 'ย้อนกลับ';

  @override
  String get goForward => 'ไปข้างหน้า';

  @override
  String get googleFonts => 'Google fonts';

  @override
  String get high => 'สูง';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ชั่วโมงที่แล้ว',
      one: '1 ชั่วโมงที่แล้ว',
    );
    return '$_temp0';
  }

  @override
  String get sidebarAgeNow => 'เมื่อกี้';

  @override
  String sidebarAgeMinutes(int count) {
    return '$count น.';
  }

  @override
  String sidebarAgeHours(int count) {
    return '$count ชม.';
  }

  @override
  String sidebarAgeDays(int count) {
    return '$count ว.';
  }

  @override
  String sidebarAgeMonths(int count) {
    return '$count ด.';
  }

  @override
  String sidebarAgeYears(int count) {
    return '$count ปี';
  }

  @override
  String get images => 'ภาพ';

  @override
  String get inactive => 'ไม่ได้ใช้งาน';

  @override
  String get install => 'ติดตั้ง';

  @override
  String get installRequired => 'ต้องติดตั้ง';

  @override
  String installedVersion(String version) {
    return 'ติดตั้ง $version แล้ว';
  }

  @override
  String get invite => 'เชิญ';

  @override
  String get inviteAgent => 'เชิญเอเจนต์';

  @override
  String get isolateAgentExecution => 'แยกการรันของเอเจนต์';

  @override
  String get justNow => 'เมื่อสักครู่';

  @override
  String get keepSandboxing => 'ใช้แซนด์บ็อกซ์ต่อไป';

  @override
  String get keybindingAddARepositoryDescription => 'เพิ่มรีโพสิทอรี';

  @override
  String get keybindingAddRepository => 'เพิ่มรีโพสิทอรี';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'บุ๊กมาร์กหรือเลิกบุ๊กมาร์กบทความที่เลือก';

  @override
  String get keybindingCommandPalette => 'จานคำสั่ง';

  @override
  String get keybindingCreateANewAgentDescription => 'สร้างเอเจนต์ใหม่';

  @override
  String get keybindingCreateANewWorkspaceDescription => 'สร้างเวิร์กสเปซใหม่';

  @override
  String get keybindingFocusSearch => 'โฟกัสการค้นหา';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'โฟกัสช่องค้นหา pull request';

  @override
  String get keybindingNewAgent => 'เอเจนต์ใหม่';

  @override
  String get keybindingNewWorkspace => 'เวิร์กสเปซใหม่';

  @override
  String get keybindingNextArticle => 'บทความถัดไป';

  @override
  String get keybindingNextSpace => 'สเปซถัดไป';

  @override
  String get keybindingNextWorkspace => 'เวิร์กสเปซถัดไป';

  @override
  String get keybindingOpenArticle => 'เปิดบทความ';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'เปิดหรือปิดป๊อปอัปสลับเวิร์กสเปซในแถบข้าง';

  @override
  String get keybindingOpenPr => 'เปิด PR';

  @override
  String get keybindingOpenSettings => 'เปิดการตั้งค่า';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'เปิดการตั้งค่าแอป';

  @override
  String get keybindingOpenTheCommandPaletteDescription => 'เปิดจานคำสั่ง';

  @override
  String get keybindingOpenTheSelectedArticleDescription =>
      'เปิดบทความที่เลือก';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'เปิด pull request ที่เลือก';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'เปิดเวิร์กสเปซที่เลือก';

  @override
  String get keybindingOpenWorkspace => 'เปิดเวิร์กสเปซ';

  @override
  String get keybindingPreviousArticle => 'บทความก่อนหน้า';

  @override
  String get keybindingPreviousSpace => 'สเปซก่อนหน้า';

  @override
  String get keybindingPreviousWorkspace => 'เวิร์กสเปซก่อนหน้า';

  @override
  String get keybindingRefresh => 'รีเฟรช';

  @override
  String get keybindingRefreshAllFeedsDescription => 'รีเฟรชฟีดทั้งหมด';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'รีเฟรชรายการ pull request';

  @override
  String get keybindingRescanForAdaptersDescription => 'สแกนอะแดปเตอร์อีกครั้ง';

  @override
  String get keybindingSelectTheNextArticleDescription => 'เลือกบทความถัดไป';

  @override
  String get keybindingSelectTheNextSpaceDescription => 'เลือกสเปซถัดไป';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'เลือกบทความก่อนหน้า';

  @override
  String get keybindingSelectThePreviousSpaceDescription => 'เลือกสเปซก่อนหน้า';

  @override
  String get keybindingSendMessage => 'ส่งข้อความ';

  @override
  String get keybindingSendTheCurrentMessageDescription => 'ส่งข้อความปัจจุบัน';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'สลับระหว่างโหมดสว่างและมืด';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'สลับไปเวิร์กสเปซที่แปด';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'สลับไปเวิร์กสเปซที่ห้า';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'สลับไปเวิร์กสเปซแรก';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'สลับไปเวิร์กสเปซที่สี่';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'สลับไปเวิร์กสเปซถัดไป';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'สลับไปเวิร์กสเปซที่เก้า';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'สลับไปเวิร์กสเปซก่อนหน้า';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'สลับไปเวิร์กสเปซที่สอง';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'สลับไปเวิร์กสเปซที่เจ็ด';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'สลับไปเวิร์กสเปซที่หก';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'สลับไปเวิร์กสเปซที่สาม';

  @override
  String get keybindingToggleBookmark => 'สลับบุ๊กมาร์ก';

  @override
  String get keybindingToggleTheme => 'สลับธีม';

  @override
  String get keybindingToggleWorkspaceSwitcher => 'สลับตัวสลับเวิร์กสเปซ';

  @override
  String get keybindingWorkspace1 => 'เวิร์กสเปซ 1';

  @override
  String get keybindingWorkspace2 => 'เวิร์กสเปซ 2';

  @override
  String get keybindingWorkspace3 => 'เวิร์กสเปซ 3';

  @override
  String get keybindingWorkspace4 => 'เวิร์กสเปซ 4';

  @override
  String get keybindingWorkspace5 => 'เวิร์กสเปซ 5';

  @override
  String get keybindingWorkspace6 => 'เวิร์กสเปซ 6';

  @override
  String get keybindingWorkspace7 => 'เวิร์กสเปซ 7';

  @override
  String get keybindingWorkspace8 => 'เวิร์กสเปซ 8';

  @override
  String get keybindingWorkspace9 => 'เวิร์กสเปซ 9';

  @override
  String get keybindings => 'ทางลัดคีย์บอร์ด';

  @override
  String get keybindingsDescription =>
      'ทางลัดคีย์บอร์ดทั้งหมด ทางลัดถูกกำหนดตายตัวและกำหนดใหม่ไม่ได้';

  @override
  String get killRunning => 'ฆ่าที่กำลังรัน';

  @override
  String get languageSystem => 'ระบบ';

  @override
  String get leaveACommentEllipsis => 'เขียนความคิดเห็น…';

  @override
  String get legendLabel => 'คำอธิบายสัญลักษณ์';

  @override
  String get lessLabel => 'น้อยลง';

  @override
  String get letsPluginTools => 'มาเสียบเครื่องมือของคุณกัน';

  @override
  String get level => 'ระดับ';

  @override
  String get loadingAgents => 'กำลังโหลดเอเจนต์…';

  @override
  String get loadingModels => 'กำลังโหลดโมเดล…';

  @override
  String get loadingProviders => 'กำลังโหลดผู้ให้บริการ…';

  @override
  String get logLevel => 'ระดับบันทึก';

  @override
  String get logs => 'บันทึก';

  @override
  String get low => 'ต่ำ';

  @override
  String get maintenance => 'บำรุงรักษา';

  @override
  String get manageParticipants => 'จัดการผู้เข้าร่วม';

  @override
  String get manageWorkspaces => 'จัดการเวิร์กสเปซ';

  @override
  String get reorderWorkspace => 'จัดลำดับเวิร์กสเปซ';

  @override
  String get matchOsAppearance =>
      'ตามลักษณะของระบบปฏิบัติการ หรือเลือกโหมดคงที่';

  @override
  String get mcpAuthToken => 'โทเค็นยืนยันตัวตน MCP';

  @override
  String get mcpNotAvailableOnServer =>
      'ควบคุมเซิร์ฟเวอร์ MCP ไม่ได้บนเซิร์ฟเวอร์ที่เชื่อมต่อ';

  @override
  String get modelManagedOnServer =>
      'โมเดลนี้รันบนโฮสต์เซิร์ฟเวอร์และจัดการที่นั่น';

  @override
  String get mcpServer => 'เซิร์ฟเวอร์ MCP';

  @override
  String get medium => 'ปานกลาง';

  @override
  String get memoryDataHint =>
      'ข้อเท็จจริงและนโยบายจะปรากฏที่นี่เมื่อเอเจนต์ทำงาน';

  @override
  String get memoryLabel => 'หน่วยความจำ';

  @override
  String get merge => 'รวม';

  @override
  String get merged => 'รวมแล้ว';

  @override
  String get messagePlaceholder => 'ข้อความ… (@ เพื่อกล่าวถึง, / สำหรับคำสั่ง)';

  @override
  String get navConversations => 'สเปซ';

  @override
  String get microphonePermissionDenied => 'ถูกปฏิเสธสิทธิ์ไมโครโฟน';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count นาทีที่แล้ว',
      one: '1 นาทีที่แล้ว',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'โมเดล';

  @override
  String get modified => 'แก้ไขแล้ว';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count เดือนที่แล้ว',
      one: '1 เดือนที่แล้ว',
    );
    return '$_temp0';
  }

  @override
  String get moreLabel => 'เพิ่มเติม';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'ชื่อ';

  @override
  String get nameAndTitleRequired => 'ต้องระบุชื่อและตำแหน่ง';

  @override
  String get nameAndUrlRequired => 'ต้องระบุชื่อและ URL';

  @override
  String get nameLabel => 'ชื่อ';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'แซนด์บ็อกซ์เนทีฟพร้อมใช้บน $platform';
  }

  @override
  String get nativeSandboxNeedsInstall => 'ต้องติดตั้งแซนด์บ็อกซ์เนทีฟ';

  @override
  String get navObservability => 'การสังเกตการณ์';

  @override
  String get navSettings => 'การตั้งค่า';

  @override
  String networkBlockCount(int count) {
    return 'บล็อกเครือข่าย $count รายการ';
  }

  @override
  String get neutral => 'เป็นกลาง';

  @override
  String get newCommitsPushed => 'มีคอมมิตใหม่ถูกพุช — คลิกเพื่อโหลด diff ใหม่';

  @override
  String get newFact => 'ข้อเท็จจริงใหม่';

  @override
  String get newPolicy => 'นโยบายใหม่';

  @override
  String get newsfeed => 'ฟีดข่าว';

  @override
  String get newsfeedLabel => 'ฟีดข่าว';

  @override
  String get newsfeedSettingsDescription =>
      'จัดการฟีดที่ติดตามและค่ากำหนดตัวอ่าน';

  @override
  String get newsfeedSettingsTitle => 'การตั้งค่าฟีดข่าว';

  @override
  String get nextMatch => 'รายการที่ตรงถัดไป (↵)';

  @override
  String get noActiveWorkspace =>
      'ไม่ได้เลือกเวิร์กสเปซหรือรีโพสิทอรีที่ใช้งาน';

  @override
  String get noActiveWorkspaceCreate => 'ไม่มีเวิร์กสเปซที่ใช้งาน';

  @override
  String get noActiveWorkspaceGithub =>
      'ไม่มีเวิร์กสเปซที่ใช้งานที่มีรีโพสิทอรี GitHub';

  @override
  String get noAgents => 'ไม่มีเอเจนต์';

  @override
  String get noArticlesYet => 'ยังไม่มีบทความ';

  @override
  String get noArticlesYetBody => 'บทความจากฟีดของคุณจะปรากฏที่นี่';

  @override
  String get noExecutionLogsYet => 'ยังไม่มีบันทึกการรัน';

  @override
  String get noFacts => 'ยังไม่มีข้อเท็จจริง';

  @override
  String get noFeedsYet => 'ยังไม่มีฟีด';

  @override
  String get noFileAnchor => 'ไม่มีจุดยึดไฟล์ — โพสต์ความคิดเห็นในบรรทัดไม่ได้';

  @override
  String get noFileChangesInScope => 'ไม่มีไฟล์ที่เปลี่ยนในขอบเขตนี้';

  @override
  String get noGifsFound => 'ไม่พบ GIF';

  @override
  String get noInputDevicesDetected =>
      'ไม่พบอุปกรณ์อินพุต — ใช้ค่าเริ่มต้นของระบบ';

  @override
  String get noMatchingFiles => 'ไม่มีไฟล์ที่ตรง';

  @override
  String get noMatchingGoogleFonts => 'ไม่มี Google Fonts ที่ตรง';

  @override
  String get noMemoryData => 'ยังไม่มีข้อมูลหน่วยความจำ';

  @override
  String get noMessagesYet => 'ยังไม่มีข้อความ';

  @override
  String get noModelsAdvertised => 'อะแดปเตอร์นี้ไม่ได้ประกาศโมเดล';

  @override
  String get noOpenPullRequests => 'ไม่มี pull request ที่เปิดอยู่';

  @override
  String get noPolicies => 'ยังไม่มีนโยบาย';

  @override
  String get noReposInWorkspaceYet => 'ยังไม่มีรีโพสิทอรีในเวิร์กสเปซนี้';

  @override
  String get noRunnersDetected => 'ยังไม่พบตัวรัน รีเฟรชเพื่อสแกนอีกครั้ง';

  @override
  String get noSavedArticles => 'ไม่มีบทความที่บันทึก';

  @override
  String get noSavedArticlesBody => 'บทความที่คุณบันทึกจะปรากฏที่นี่';

  @override
  String noShortcutsMatch(String query) {
    return 'ไม่มีทางลัดที่ตรงกับ \"$query\"';
  }

  @override
  String get noSystemFonts => 'ไม่พบแบบอักษรของระบบ';

  @override
  String get noTokenSet => 'ยังไม่ได้ตั้งโทเค็น — การเข้าถึงไม่ถูกจำกัด';

  @override
  String get noWorkingMemory => 'ยังไม่มีบันทึกหน่วยความจำทำงาน';

  @override
  String get noneAllRoles => 'ไม่มี (ทุกบทบาท)';

  @override
  String get notAvailable => 'ไม่พร้อมใช้';

  @override
  String get notConfiguredLabel => 'ยังไม่ได้ตั้งค่า';

  @override
  String get notFoundLabel => 'ไม่พบ';

  @override
  String get notes => 'บันทึก';

  @override
  String get notificationAgentFinished => 'เอเจนต์เสร็จแล้ว';

  @override
  String get notificationPrMentioned => 'ถูกกล่าวถึงใน pull request';

  @override
  String get notificationNewMessages => 'ข้อความใหม่';

  @override
  String get notificationPrMerged => 'PR ถูกรวมแล้ว';

  @override
  String get notificationPrPublished => 'PR ถูกเผยแพร่แล้ว';

  @override
  String get notificationReviewRequested => 'ขอรีวิว';

  @override
  String get notifications => 'การแจ้งเตือน';

  @override
  String get notifyAgentRunCompleted => 'แจ้งเตือนเมื่อเอเจนต์ทำรันเสร็จ';

  @override
  String get notifyPrMentioned => 'แจ้งเตือนเมื่อคุณถูกกล่าวถึงใน pull request';

  @override
  String get notifyNewMessages =>
      'แจ้งเตือนเมื่อมีข้อความเอเจนต์ใหม่ในสเปซอื่น';

  @override
  String get notifyPrMerged => 'แจ้งเตือนเมื่อ pull request ถูกรวม';

  @override
  String get notifyPrPublished => 'แจ้งเตือนเมื่อเอเจนต์เผยแพร่ pull request';

  @override
  String get notifyReviewRequested =>
      'แจ้งเตือนเมื่อมีการขอรีวิวจากคุณใน pull request';

  @override
  String get notificationReviewStale => 'รีวิวล้าสมัย';

  @override
  String get notifyReviewStale =>
      'เมื่อมีคอมมิตใหม่บน pull request ที่คุณรีวิวแล้ว';

  @override
  String get notificationPrMergeReadiness => 'พร้อมรวม';

  @override
  String get notifyPrMergeReadiness =>
      'แจ้งเตือนเมื่อ pull request ที่คุณเขียนพร้อมรวม หรือเลิกพร้อมรวม';

  @override
  String get notificationPrReviewDecision => 'ผลการรีวิว';

  @override
  String get notifyPrReviewDecision =>
      'แจ้งเตือนเมื่อผู้รีวิวอนุมัติ ขอให้แก้ไข หรือการอนุมัติถูกยกเลิก';

  @override
  String get notificationPrChecksStatus => 'การตรวจ';

  @override
  String get notifyPrChecksStatus =>
      'แจ้งเตือนเมื่อ CI ล้มเหลวบน pull request ที่คุณเขียน และเมื่อกลับมาผ่าน';

  @override
  String get notificationPrThreadActivity => 'เธรดรีวิว';

  @override
  String get notifyPrThreadActivity =>
      'แจ้งเตือนเมื่อมีคนตอบหรือปิดเธรดที่คุณอยู่';

  @override
  String get notificationPrReadyToMerge => 'พร้อมรวม';

  @override
  String notificationPrReadyToMergeBody(String prTitle) {
    return '$prTitle มีครบทุกอย่างแล้ว';
  }

  @override
  String get notificationPrMergeBlocked => 'รวมไม่ได้อีกต่อไป';

  @override
  String notificationPrMergeBlockedBodyConflicts(String prTitle) {
    return '$prTitle ขัดแย้งกับสาขาฐาน';
  }

  @override
  String notificationPrMergeBlockedBodyBehind(String prTitle) {
    return '$prTitle ตามหลังสาขาฐาน';
  }

  @override
  String notificationPrMergeBlockedBodyReviews(String prTitle) {
    return '$prTitle รอรีวิวที่จำเป็น';
  }

  @override
  String notificationPrMergeBlockedBodyChanges(String prTitle) {
    return 'ผู้รีวิวขอให้แก้ไข $prTitle';
  }

  @override
  String notificationPrMergeBlockedBodyChecks(String prTitle) {
    return 'การตรวจล้มเหลวบน $prTitle';
  }

  @override
  String notificationPrMergeBlockedBodyOther(String prTitle) {
    return '$prTitle รวมไม่ได้อีกต่อไป';
  }

  @override
  String get notificationPrApproved => 'อนุมัติ pull request แล้ว';

  @override
  String notificationPrApprovedBodyBy(String login, String prTitle) {
    return '$login อนุมัติ $prTitle';
  }

  @override
  String notificationPrApprovedBody(String prTitle) {
    return '$prTitle ได้รับการอนุมัติ';
  }

  @override
  String notificationPrReviewersRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'รอผู้รีวิวอีก $count คน',
      one: 'รอผู้รีวิวอีก 1 คน',
      zero: 'ไม่มีผู้รีวิวเหลือ',
    );
    return '$_temp0';
  }

  @override
  String get notificationPrChangesRequested => 'ขอให้แก้ไข';

  @override
  String notificationPrChangesRequestedBodyBy(String login, String prTitle) {
    return '$login ขอให้แก้ไข $prTitle';
  }

  @override
  String notificationPrChangesRequestedBody(String prTitle) {
    return 'มีการขอให้แก้ไข $prTitle';
  }

  @override
  String get notificationPrReviewDismissed => 'ยกเลิกการอนุมัติแล้ว';

  @override
  String notificationPrReviewDismissedBody(String prTitle) {
    return '$prTitle ต้องรีวิวอีกครั้ง';
  }

  @override
  String get notificationPrChecksFailed => 'การตรวจล้มเหลว';

  @override
  String notificationPrChecksFailedBody(String checkName, String prTitle) {
    return '$checkName ล้มเหลวบน $prTitle';
  }

  @override
  String notificationPrChecksFailedBodyUnnamed(String prTitle) {
    return 'การตรวจล้มเหลวบน $prTitle';
  }

  @override
  String get notificationPrChecksRecovered => 'การตรวจผ่านแล้ว';

  @override
  String notificationPrChecksRecoveredBody(String prTitle) {
    return '$prTitle กลับมาผ่านแล้ว';
  }

  @override
  String notificationPrMentionedInCommentBody(String login, String location) {
    return '$login กล่าวถึงคุณใน $location';
  }

  @override
  String get notificationPrThreadReplied => 'การตอบกลับใหม่';

  @override
  String notificationPrThreadRepliedBody(String login, String location) {
    return '$login ตอบใน $location';
  }

  @override
  String get notificationPrThreadResolved => 'ปิดเธรดแล้ว';

  @override
  String notificationPrThreadResolvedBody(String location) {
    return 'เธรดของคุณใน $location ถูกปิดแล้ว';
  }

  @override
  String get notificationGroupAgents => 'เอเจนต์';

  @override
  String get notificationGroupPullRequests => 'Pull request';

  @override
  String get notificationGroupMessages => 'ข้อความ';

  @override
  String get notificationGroupTickets => 'ตั๋วงาน';

  @override
  String get notificationGroupCalendar => 'ปฏิทิน';

  @override
  String get notificationGroupMachines => 'เครื่อง';

  @override
  String get notificationsMutedRepos => 'รีโพสิทอรีที่ปิดเสียง';

  @override
  String notificationsMutedReposCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ปิดเสียง $count รีโพสิทอรี',
      one: 'ปิดเสียง 1 รีโพสิทอรี',
      zero: 'ไม่มีรีโพสิทอรีที่ปิดเสียง',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMuteRepo => 'ปิดเสียงรีโพสิทอรีนี้';

  @override
  String get onboardingLinuxDescription =>
      'Control Center สามารถใช้คอนเทนเนอร์ Linux เพื่อแยกการรันของเอเจนต์';

  @override
  String get onboardingMacosDescription =>
      'Control Center ใช้แซนด์บ็อกซ์เนทีฟบน macOS เพื่อแยกการรันของเอเจนต์';

  @override
  String get onboardingUnsupportedDescription =>
      'แซนด์บ็อกซ์ใช้ไม่ได้บนแพลตฟอร์มนี้ การรันของเอเจนต์จะไม่ถูกแยก';

  @override
  String get openArticlesInApp => 'เปิดบทความในแอป';

  @override
  String get openInBrowser => 'เปิดในเบราว์เซอร์';

  @override
  String get openedInYourBrowser => 'เปิดในเบราว์เซอร์แล้ว';

  @override
  String get openLabel => 'เปิด';

  @override
  String get openOnGithub => 'เปิดบน GitHub';

  @override
  String get openStatus => 'เปิด';

  @override
  String get optionalPersonaDescription => 'คำอธิบายเพอร์โซนา (ไม่บังคับ)';

  @override
  String get otherLabel => 'อื่น ๆ';

  @override
  String get ownerOrganization => 'เจ้าของ / องค์กร';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get passed => 'ผ่าน';

  @override
  String get pasteValueHere => 'วางค่าที่นี่';

  @override
  String get persona => 'เพอร์โซนา';

  @override
  String get policies => 'นโยบาย';

  @override
  String get policiesHint =>
      'นโยบายจะปรากฏที่นี่เมื่อเอเจนต์เลื่อนขั้นข้อเท็จจริง';

  @override
  String get policy => 'นโยบาย';

  @override
  String get popular => 'ยอดนิยม';

  @override
  String get port => 'พอร์ต';

  @override
  String get postingEllipsis => 'กำลังโพสต์…';

  @override
  String get prCommits => 'คอมมิต';

  @override
  String get prMergedBody => 'มี pull request ถูกรวมแล้ว';

  @override
  String get prMoreActions => 'การกระทำเพิ่มเติม';

  @override
  String get prTitle => 'ชื่อ PR';

  @override
  String get reviewCommentHint =>
      'กดอนุมัติได้เลย หรือถ้าอยากเพิ่มเติม ให้เขียนความคิดเห็นหรือปฏิกิริยา…';

  @override
  String get nothingToPreview => 'ไม่มีอะไรให้ดูตัวอย่าง';

  @override
  String get previousMatch => 'รายการที่ตรงก่อนหน้า (⇧↵)';

  @override
  String get priorityReviewsDescription => 'รีวิวสำคัญและภาพรวมรีโพสิทอรี';

  @override
  String get prsCreated => 'PR ที่สร้าง';

  @override
  String get prsMerged => 'PR ที่รวม';

  @override
  String get publishToGithub => 'เผยแพร่ไปยัง GitHub';

  @override
  String get published => 'เผยแพร่แล้ว';

  @override
  String get pullRequestApproved => 'อนุมัติ pull request แล้ว';

  @override
  String get pullRequests => 'Pull request';

  @override
  String get questionLabel => 'คำถาม';

  @override
  String get queued => 'อยู่ในคิว';

  @override
  String get react => 'แสดงปฏิกิริยา';

  @override
  String get readPrsIssuesMetadata =>
      'ให้เอเจนต์อ่าน PR, issue และเมตาดาต้าของรีโพสิทอรี';

  @override
  String get readerPreferences => 'ค่ากำหนดตัวอ่าน';

  @override
  String get reasoningEffort => 'ความพยายามในการคิด';

  @override
  String get recommendLabel => 'แนะนำ';

  @override
  String recordingFromDevice(String device) {
    return 'กำลังบันทึกจาก $device';
  }

  @override
  String get redownload => 'ดาวน์โหลดอีกครั้ง';

  @override
  String get redownloadEmbeddingModel => 'ดาวน์โหลดโมเดลฝังตัวอีกครั้งหรือไม่?';

  @override
  String get redownloadVoiceModel => 'ดาวน์โหลดโมเดลเสียงอีกครั้งหรือไม่?';

  @override
  String get refinePlan => 'ปรับแผน';

  @override
  String get refresh => 'รีเฟรช';

  @override
  String get refreshAll => 'รีเฟรชทั้งหมด';

  @override
  String get refreshAllFeeds => 'รีเฟรชฟีดทั้งหมด';

  @override
  String get reject => 'ปฏิเสธ';

  @override
  String get rejected => 'ถูกปฏิเสธ';

  @override
  String get reload => 'โหลดใหม่';

  @override
  String get remove => 'ลบออก';

  @override
  String get removeBookmark => 'ลบบุ๊กมาร์ก';

  @override
  String get removeEmbeddingModel => 'ลบโมเดลฝังตัวหรือไม่?';

  @override
  String get removeLogo => 'ลบโลโก้';

  @override
  String get removeRepoFromWorkspace => 'ลบรีโพสิทอรีออกจากเวิร์กสเปซหรือไม่?';

  @override
  String get removeVoiceModel => 'ลบโมเดลเสียงหรือไม่?';

  @override
  String get removed => 'ลบออกแล้ว';

  @override
  String get renamed => 'เปลี่ยนชื่อแล้ว';

  @override
  String get reopen => 'เปิดอีกครั้ง';

  @override
  String get resolve => 'ปิดแล้ว';

  @override
  String get replyEllipsis => 'ตอบกลับ…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$name จะถูกลบออกจากเวิร์กสเปซนี้ ไฟล์ในเครื่องบนดิสก์จะไม่ถูกแตะต้อง';
  }

  @override
  String repoAccessNoticeBody(String repos) {
    return 'ข้อมูลรับรอง GitHub ของเซิร์ฟเวอร์มองไม่เห็น $repos หากรีโพสิทอรีเป็นขององค์กร ให้ติดตั้ง GitHub App ที่นั่น หรือเชื่อมต่อโทเค็นที่มีสิทธิ์เข้าถึง';
  }

  @override
  String repoAccessNoticeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เข้าถึง $count รีโพสิทอรีไม่ได้',
      one: 'เข้าถึงรีโพสิทอรีไม่ได้',
    );
    return '$_temp0';
  }

  @override
  String get repoAccessNoticeSuspendedTitle => 'การติดตั้ง GitHub App ถูกระงับ';

  @override
  String repoAccessNoticeSuspendedBody(String repos) {
    return 'กำลังแสดงข้อมูลล่าสุดที่ทราบของ $repos โปรดดำเนินการติดตั้งต่อบน GitHub หรือเชื่อมต่อโทเค็นที่มีสิทธิ์เข้าถึง';
  }

  @override
  String get repoNoAccessBadge => 'ไม่มีสิทธิ์เข้าถึง';

  @override
  String get reportsTo => 'รายงานต่อ';

  @override
  String reposCount(int count) {
    return 'รีโพสิทอรี ($count)';
  }

  @override
  String get reposDescription =>
      'เช็กเอาต์ในเครื่องที่เวิร์กสเปซนี้กำหนดเป้าหมาย';

  @override
  String get repositories => 'รีโพสิทอรี';

  @override
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' $count รีโพสิทอรี',
      one: 'รีโพสิทอรี 1 รายการ',
    );
    return 'เพิ่ม$_temp0ไม่ได้: $error';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เพิ่ม $count รีโพสิทอรีแล้ว',
      one: 'เพิ่มรีโพสิทอรีแล้ว',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => 'การตั้งค่ารีโพสิทอรี';

  @override
  String get repositoryName => 'ชื่อรีโพสิทอรี';

  @override
  String get requestChanges => 'ขอให้แก้ไข';

  @override
  String get requested => 'ขอแล้ว';

  @override
  String get requestedChanges => 'ขอให้แก้ไขแล้ว';

  @override
  String requiredRoleLabel(String role) {
    return 'บทบาทที่จำเป็น: $role';
  }

  @override
  String get requiredRoleOptional => 'บทบาทที่จำเป็น (ไม่บังคับ)';

  @override
  String get requirements => 'ข้อกำหนด';

  @override
  String get reset => 'รีเซ็ต';

  @override
  String get resolved => 'ปิดแล้ว';

  @override
  String get enclosedTerminalTitle => 'เทอร์มินัลที่หุ้ม';

  @override
  String get enclosedTerminalStart => 'เปิดเชลล์';

  @override
  String get enclosedTerminalStartHint =>
      'เชลล์นี้รันใน VM แบบใช้แล้วทิ้งของการสนทนานี้ จะบูตเมื่อคุณเปิด ไม่ใช่เมื่อแอปเริ่ม';

  @override
  String get terminalStreamReconnecting => 'สตรีมขาด — กำลังเชื่อมต่อใหม่…';

  @override
  String get terminalStreamError => 'ข้อผิดพลาดสตรีม:';

  @override
  String get terminalShellExited => 'เชลล์จบแล้ว';

  @override
  String get restartShell => 'รีสตาร์ทเชลล์';

  @override
  String get retry => 'ลองใหม่';

  @override
  String get review => 'รีวิว';

  @override
  String get reviewedByMe => 'รีวิวโดยฉัน';

  @override
  String get reviewers => 'ผู้รีวิว';

  @override
  String get roleLabel => 'บทบาท';

  @override
  String get ruleHint => 'กฎนโยบาย (รองรับ markdown)';

  @override
  String get ruleLabel => 'กฎ';

  @override
  String get runCompleted => 'รันเสร็จแล้ว';

  @override
  String get running => 'กำลังรัน';

  @override
  String get runningLabel => 'กำลังรัน';

  @override
  String get runs => 'รัน';

  @override
  String get runsLabel => 'รัน';

  @override
  String get sandboxBackendNativeLabel => 'แซนด์บ็อกซ์เนทีฟ';

  @override
  String get sandboxBackendMicrovmLabel => 'VM ที่หุ้ม';

  @override
  String get sandboxBackendNoneLabel => 'ไม่แยก';

  @override
  String get sandboxLinuxInstall =>
      'แซนด์บ็อกซ์เนทีฟบน Linux/WSL2 ใช้ bubblewrap ติดตั้งด้วย:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'แซนด์บ็อกซ์เนทีฟมีในตัวบน macOS — ใช้ Apple Seatbelt (`sandbox-exec`) ไม่ต้องติดตั้ง';

  @override
  String get sandboxPermissions => 'สิทธิ์แซนด์บ็อกซ์';

  @override
  String get sandboxUnsupported =>
      'แซนด์บ็อกซ์เนทีฟยังไม่รองรับบนแพลตฟอร์มนี้ จะถอยไปใช้ \"ไม่แยก\"';

  @override
  String get sandboxingDisabledDescription =>
      'เอเจนต์รันบนโฮสต์โดยตรงพร้อม env เต็ม — ไม่แนะนำ';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'การเรียกเอเจนต์ทั้งหมดผ่าน $backend';
  }

  @override
  String get save => 'บันทึก';

  @override
  String get saveChanges => 'บันทึกการเปลี่ยนแปลง';

  @override
  String get adapterArguments => 'อาร์กิวเมนต์เพิ่มเติม';

  @override
  String get adapterArgumentsHint => 'แฟล็ก CLI เพิ่มเติม (เช่น --yolo)';

  @override
  String get addVariable => 'เพิ่มตัวแปร';

  @override
  String get environmentVariables => 'ตัวแปรสภาพแวดล้อม';

  @override
  String get environmentVariablesDescription =>
      'ตัวแปรสภาพแวดล้อมที่กำหนดเองที่ส่งให้อะแดปเตอร์นี้ (เช่น คีย์ API) เก็บในพวงกุญแจ';

  @override
  String get variableKey => 'คีย์';

  @override
  String get variableValue => 'ค่า';

  @override
  String get savingEllipsis => 'กำลังบันทึก…';

  @override
  String get scopeDiffToCommits =>
      'จำกัด diff ตามคอมมิต — Shift-คลิกสำหรับช่วง';

  @override
  String get noPrsMatchSearch => 'ไม่มี pull request ที่ตรง';

  @override
  String get searchFactsHint => 'ค้นหาข้อเท็จจริง...';

  @override
  String get searchFonts => 'ค้นหาแบบอักษร…';

  @override
  String get searchGifs => 'ค้นหา GIF';

  @override
  String get searchGifsHint => 'ค้นหา GIF...';

  @override
  String get searchInDiffHint => 'ค้นหาใน diff…';

  @override
  String get searchOrTypeModel => 'ค้นหาหรือพิมพ์ชื่อโมเดล…';

  @override
  String get searchPlaceholder => 'ค้นหา…';

  @override
  String get searchShortcuts => 'ค้นหาทางลัด…';

  @override
  String get shortcutUnavailableInBrowser => 'ใช้ไม่ได้ในเบราว์เซอร์';

  @override
  String get searching => 'กำลังค้นหา…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count วินาทีที่แล้ว',
      one: '1 วินาทีที่แล้ว',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'เลือกอะแดปเตอร์';

  @override
  String get selectAdapterFirst => 'เลือกอะแดปเตอร์ก่อน';

  @override
  String get selectAgentToReportTo => 'เลือกเอเจนต์ที่จะรายงานต่อ…';

  @override
  String get selectAnAgent => 'เลือกเอเจนต์';

  @override
  String get selectConversation => 'เลือกการสนทนา';

  @override
  String get selectLabel => 'เลือก';

  @override
  String get selectRunner => 'เลือกตัวรัน';

  @override
  String get semanticSearch => 'ค้นหาเชิงความหมาย';

  @override
  String get send => 'ส่ง';

  @override
  String get sendFirstMessage => 'ส่งข้อความแรก';

  @override
  String get sendMessage => 'ส่งข้อความ';

  @override
  String sentFindingsToAgent(int count) {
    return 'ส่ง $count ข้อค้นพบไปยังเอเจนต์แล้ว';
  }

  @override
  String setGithubLinkDescription(String name) {
    return 'ตั้งเจ้าของ GitHub และชื่อรีโพสิทอรีสำหรับ $name ใช้เพื่อแก้การอ้างอิง PR และ issue เช่น #123 ในเนื้อหา markdown';
  }

  @override
  String get setLabel => 'ตั้งค่า';

  @override
  String get setToken => 'ตั้งโทเค็น';

  @override
  String get settingsLabel => 'การตั้งค่า';

  @override
  String get settingsLanguage => 'ภาษา';

  @override
  String get settingsLanguageDescription => 'เลือกภาษาของแอป';

  @override
  String get shortTask => 'งานสั้น';

  @override
  String get showNativeNotifications =>
      'แสดงการแจ้งเตือนของระบบสำหรับเหตุการณ์';

  @override
  String get showSuperseded => 'แสดงที่ถูกแทนที่';

  @override
  String get signedIn => 'ลงชื่อเข้าใช้แล้ว';

  @override
  String signedInAs(String username) {
    return 'ลงชื่อเข้าใช้เป็น $username';
  }

  @override
  String get skillNameRequired => 'ต้องระบุชื่อสกิล';

  @override
  String skillSaved(String name) {
    return 'บันทึกสกิล \"$name\" แล้ว';
  }

  @override
  String get skillsSourcesTab => 'แหล่ง';

  @override
  String get skillSourcesDisclaimer =>
      'สกิลติดตั้งจากรีโพสิทอรี GitHub ที่คุณเพิ่ม เมตาดาต้าของรีโพสิทอรีไม่น่าเชื่อถือ — การสแกนแอนติไวรัสคือสัญญาณความปลอดภัยที่แท้จริง';

  @override
  String get skillSourcesEmpty => 'ไม่มีรีโพสิทอรีสกิล';

  @override
  String get skillSourcesEmptyHint => 'เพิ่มรีโพสิทอรี GitHub เพื่อเรียกดูสกิล';

  @override
  String get skillSourceAdd => 'เพิ่มรีโพสิทอรี';

  @override
  String get skillSourceAddTitle => 'เพิ่มรีโพสิทอรีสกิล';

  @override
  String get skillSourceAddHint => 'https://github.com/owner/repo';

  @override
  String get skillSourceInvalidUrl =>
      'ใส่ URL รีโพสิทอรี GitHub (https://github.com/owner/repo)';

  @override
  String skillSourceAdded(String repo) {
    return 'เพิ่มรีโพสิทอรี $repo แล้ว';
  }

  @override
  String skillSourceAlreadyAdded(String repo) {
    return 'เพิ่มรีโพสิทอรี $repo ไว้แล้ว';
  }

  @override
  String skillSourceRemoved(String repo) {
    return 'ลบรีโพสิทอรี $repo แล้ว';
  }

  @override
  String get skillSourceRemove => 'ลบออก';

  @override
  String skillSourceRemoveConfirmTitle(String repo) {
    return 'ลบ $repo หรือไม่?';
  }

  @override
  String get skillSourceRemoveConfirmBody =>
      'สกิลที่ติดตั้งแล้วยังอยู่ ลบเฉพาะแค็ตตาล็อกของรีโพสิทอรี';

  @override
  String get skillSourceNoSkills =>
      'ไม่พบสกิลในรีโพสิทอรีนี้ (สกิลคือไดเรกทอรีที่มี SKILL.md)';

  @override
  String get skillSourceRefresh => 'รีเฟรช';

  @override
  String get skillSourceInstalledBadge => 'ติดตั้งแล้ว';

  @override
  String get skillSourceUpdateBadge => 'มีอัปเดต';

  @override
  String get skillSourceSlugTaken => 'ชื่อนี้ถูกใช้แล้ว';

  @override
  String skillSourceFilesCount(num count) {
    return '$count ไฟล์';
  }

  @override
  String get skillSourceReadme => 'README';

  @override
  String get skillSourceNoReadme => 'สกิลนี้ไม่มี README';

  @override
  String get skillSourceNoMatches => 'ไม่มีสกิลที่ตรงกับตัวกรอง';

  @override
  String get skillUpdateAction => 'อัปเดต';

  @override
  String get skillUninstallAction => 'ถอนการติดตั้ง';

  @override
  String skillUninstallConfirmTitle(String slug) {
    return 'ถอนการติดตั้ง \"$slug\" หรือไม่?';
  }

  @override
  String skillUninstalled(String slug) {
    return 'ถอนการติดตั้งสกิล \"$slug\" แล้ว';
  }

  @override
  String get skillFindingLine => 'บรรทัด';

  @override
  String get skillInstallAnywayOverride => 'เข้าใจความเสี่ยง — ติดตั้งต่อไป';

  @override
  String skillInstalled(String slug) {
    return 'ติดตั้งสกิล \"$slug\" แล้ว';
  }

  @override
  String get skillPreviewCapabilities => 'ความสามารถ';

  @override
  String get skillPreviewFindings => 'ข้อค้นพบ';

  @override
  String get skillPreviewGuardedActions => 'การกระทำที่ถูกคุม';

  @override
  String get skillPreviewLlmReviewed => 'รีวิวโดย LLM';

  @override
  String get skillPreviewNoCapabilities => 'ไม่ได้ประกาศความสามารถ';

  @override
  String get skillPreviewNoFindings => 'ไม่มีข้อค้นพบ';

  @override
  String get skillPreviewScanning => 'กำลังสแกนสกิล…';

  @override
  String get skillPreviewVerdictLabel => 'คำตัดสินการสแกน';

  @override
  String get skillPreviewVerdictPass => 'ผ่าน';

  @override
  String get skillPreviewVerdictQuarantine => 'กักกัน';

  @override
  String get skillPreviewVerdictWarn => 'คำเตือน';

  @override
  String get skillQuarantineWarning =>
      'สกิลนี้ถูกกักกันโดยตัวสแกน การติดตั้งจะรันโค้ดบนเครื่องคุณ ดำเนินการต่อเฉพาะเมื่อเชื่อแหล่งที่มาและตรวจข้อค้นพบแล้ว';

  @override
  String skillDetachedFromAgents(String agents) {
    return 'ถูกกักกันและถอดออกจากเอเจนต์: $agents';
  }

  @override
  String get skillNotScanned => 'ยังไม่ได้สแกน';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => 'ด้วยตนเอง';

  @override
  String get skillOriginRegistry => 'รีจิสทรี';

  @override
  String get skillOriginRuntimeLocal => 'รันไทม์ในเครื่อง';

  @override
  String get skillRulesStale => 'การสแกนล้าสมัย';

  @override
  String get skillSaveAnywayOverride => 'เข้าใจความเสี่ยง — บันทึกต่อไป';

  @override
  String get skillSaveBlockedBody => 'เนื้อหาถูกบล็อกก่อนที่จะมีการเขียนใด ๆ';

  @override
  String get skillSaveBlockedTitle => 'การบันทึกถูกบล็อกโดยประตูสแกน';

  @override
  String get skillScanAction => 'สแกน';

  @override
  String get skillScanAll => 'สแกนทั้งหมด';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return 'ผ่าน $pass · คำเตือน $warn · กักกัน $quarantine';
  }

  @override
  String get skillStateDrifted => 'ถูกแก้ไขตั้งแต่ติดตั้ง';

  @override
  String get skillStateUnmanaged => 'ไม่ได้จัดการ';

  @override
  String get skillSeverityBlocked => 'ถูกบล็อก';

  @override
  String get skillSeverityWarn => 'คำเตือน';

  @override
  String get skillsInstalledTab => 'ติดตั้งแล้ว';

  @override
  String get skills => 'สกิล';

  @override
  String get skipAcceptRisk => 'ข้าม — ยอมรับความเสี่ยง';

  @override
  String get skipForNow => 'ข้ามตอนนี้';

  @override
  String get skipSandboxing => 'ข้ามแซนด์บ็อกซ์';

  @override
  String get skipSandboxingDialogContent =>
      'แน่ใจหรือไม่ว่าจะข้ามแซนด์บ็อกซ์? การดำเนินการนี้ให้เอเจนต์รันโค้ดบนระบบของคุณโดยไม่แยก';

  @override
  String get somethingWentWrong => 'เกิดข้อผิดพลาด';

  @override
  String sourceCount(int count) {
    return 'แหล่ง $count รายการ';
  }

  @override
  String sourceCountPlural(int count) {
    return 'แหล่ง $count รายการ';
  }

  @override
  String get sourceFacts => 'ข้อเท็จจริงต้นทาง:';

  @override
  String get splitDiff => 'Diff แยก (คู่ขนาน)';

  @override
  String get startLabel => 'เริ่ม';

  @override
  String get startOnAppLaunch => 'เริ่มเมื่อเปิดแอป';

  @override
  String get statusLabel => 'สถานะ';

  @override
  String get onboardingStepConnect => 'เชื่อมต่อ';

  @override
  String get onboardingStepWorkspace => 'เวิร์กสเปซ';

  @override
  String get onboardingStepSandbox => 'แซนด์บ็อกซ์';

  @override
  String get onboardingStepAdapter => 'อะแดปเตอร์';

  @override
  String get onboardingStepVoice => 'เสียง';

  @override
  String get stop => 'หยุด';

  @override
  String get stopped => 'หยุดแล้ว';

  @override
  String get strictIdentityCheck => 'ตรวจตัวตนแบบเข้มงวด';

  @override
  String get success => 'สำเร็จ';

  @override
  String get successLabel => 'สำเร็จ';

  @override
  String get suggestAChange => 'เสนอการเปลี่ยนแปลง';

  @override
  String get suggestion => 'ข้อเสนอแนะ';

  @override
  String get suggestLabel => 'เสนอ';

  @override
  String get superseded => 'ถูกแทนที่';

  @override
  String get synced => 'ซิงค์แล้ว';

  @override
  String get systemDefault => 'ค่าเริ่มต้นของระบบ';

  @override
  String get systemFonts => 'แบบอักษรระบบ';

  @override
  String get systemPrompt => 'พรอมต์ระบบ';

  @override
  String get systemPromptLabel => 'พรอมต์ระบบ';

  @override
  String get talkToControlCenter => 'คุยกับ Control Center';

  @override
  String get taskMentionSection => 'งาน';

  @override
  String get testLabel => 'ทดสอบ';

  @override
  String get theme => 'ธีม';

  @override
  String get themeDark => 'มืด';

  @override
  String get themeLight => 'สว่าง';

  @override
  String get themeSystem => 'ระบบ';

  @override
  String get thisCannotBeUndone => 'เลิกทำไม่ได้';

  @override
  String get ticketLabel => 'ตั๋วงาน';

  @override
  String get titleLabel => 'ชื่อ';

  @override
  String get todayLabel => 'วันนี้';

  @override
  String get toggleTheme => 'สลับธีม';

  @override
  String get tokenConfigured => 'ตั้งค่าแล้ว — ไคลเอนต์ต้องแสดงโทเค็นนี้';

  @override
  String get topic => 'หัวข้อ';

  @override
  String get topicHint => 'เช่น Tech Stack, Design System';

  @override
  String get totalRuns => 'รันทั้งหมด';

  @override
  String trackingParamsCount(int count) {
    return 'พารามิเตอร์ติดตาม $count รายการ';
  }

  @override
  String get typeCommandOrSearch => 'พิมพ์คำสั่งหรือค้นหา…';

  @override
  String get typography => 'ตัวอักษร';

  @override
  String get unavailable => 'ไม่พร้อมใช้';

  @override
  String get unifiedDiff => 'Diff รวม';

  @override
  String get unknownAuthor => 'ไม่ทราบผู้เขียน';

  @override
  String get unnamedAgent => 'เอเจนต์ไม่มีชื่อ';

  @override
  String get updateKey => 'อัปเดตคีย์';

  @override
  String get updateLabel => 'อัปเดต';

  @override
  String get updateToken => 'อัปเดตโทเค็น';

  @override
  String updatedDaysAgo(int count) {
    return 'อัปเดตเมื่อ $count วันที่แล้ว';
  }

  @override
  String updatedHoursAgo(int count) {
    return 'อัปเดตเมื่อ $count ชม. ที่แล้ว';
  }

  @override
  String get updatedJustNow => 'เพิ่งอัปเดต';

  @override
  String updatedMinutesAgo(int count) {
    return 'อัปเดตเมื่อ $count นาทีที่แล้ว';
  }

  @override
  String get useSandbox => 'ใช้แซนด์บ็อกซ์';

  @override
  String get useWorkspaceDefault => 'ใช้ค่าเริ่มต้นของเวิร์กสเปซ';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      'เว้นว่างเพื่อใช้ User-Agent เริ่มต้นของแอป บางไซต์บล็อก User-Agent ที่ไม่ใช่เบราว์เซอร์';

  @override
  String get usingSystemDefaultMicrophone => 'ใช้ไมโครโฟนเริ่มต้นของระบบ';

  @override
  String get viewLabel => 'ดู';

  @override
  String get viewLogs => 'ดูบันทึก';

  @override
  String voiceInstallFailed(String error) {
    return 'ติดตั้งไม่สำเร็จ: $error';
  }

  @override
  String get voiceModelNotInstalled =>
      'ยังไม่ได้ติดตั้ง ดาวน์โหลดประมาณ 200 MB ครั้งเดียว รันบนอุปกรณ์ทั้งหมด';

  @override
  String get voiceModelNotInstalledLabel => 'ยังไม่ได้ติดตั้งโมเดลเสียง';

  @override
  String get voiceRedownloadBody =>
      'ไฟล์โมเดลที่มีอยู่จะถูกลบ และดาวน์โหลดไฟล์เก็บถาวรประมาณ 200 MB อีกครั้ง การถอดเสียงจะใช้ไม่ได้จนกว่าจะดาวน์โหลดเสร็จ';

  @override
  String get voiceRemoveBody =>
      'การถอดเสียงจะถูกปิดจนกว่าจะติดตั้งอีกครั้ง ติดตั้งใหม่ได้ทุกเมื่อ';

  @override
  String get voiceTranscription => 'การถอดเสียง';

  @override
  String get weakIsolationDescription =>
      'การแยกแบบอ่อน — ขอบเขตเนมสเปซเท่านั้น ไม่มีขอบเขตเคอร์เนล';

  @override
  String get whenOffNoDefaultRoute =>
      'เมื่อปิด แซนด์บ็อกซ์จะบูตโดยไม่มีเส้นทางเริ่มต้น';

  @override
  String get whenOffServerStaysStopped =>
      'เมื่อปิด เซิร์ฟเวอร์จะหยุดอยู่จนกว่าคุณจะเริ่ม';

  @override
  String get speechModel => 'โมเดลการพูด';

  @override
  String get speechModelHint => 'ใช้สำหรับถอดเสียงการประชุมและไมค์ในช่องเขียน';

  @override
  String get voiceModelInstalled =>
      'ติดตั้งแล้ว ใช้ถอดเสียงการประชุมและปุ่มไมค์ในช่องเขียน';

  @override
  String get meetingMicSilentWarning =>
      'ไมค์ของคุณอาจปิดเสียง — คนอื่นกำลังพูดแต่ไม่มีอะไรเข้าไมโครโฟน';

  @override
  String get meetingSummaryPrivacyNotice =>
      'การบันทึกและถอดเสียงอยู่บนเครื่องนี้ สรุปเขียนโดยเอเจนต์ ดังนั้นหากใช้โมเดลคลาวด์ ถอดเสียงและบันทึกของคุณจะถูกส่งไปยังผู้ให้บริการนั้น';

  @override
  String get meetingTemplates => 'เทมเพลตบันทึกการประชุม';

  @override
  String get meetingTemplatesHint =>
      'กำหนดรูปแบบสรุป AI สำหรับการประชุมแต่ละประเภท เทมเพลตที่ใช้งานมีผลกับสรุปใหม่และที่รันใหม่';

  @override
  String get meetingTemplateActive => 'เทมเพลตที่ใช้งาน';

  @override
  String get meetingTemplateAdd => 'เพิ่มเทมเพลต';

  @override
  String get meetingTemplateNewTitle => 'เทมเพลตใหม่';

  @override
  String get meetingTemplateEditTitle => 'แก้ไขเทมเพลต';

  @override
  String get meetingTemplateNameLabel => 'ชื่อ';

  @override
  String get meetingTemplateNameHint => 'เช่น Sprint review';

  @override
  String get meetingTemplateInstructionsLabel => 'คำสั่ง';

  @override
  String get meetingTemplateInstructionsHint =>
      'AI ควรจัดโครงสร้างและเน้นบันทึกเหล่านี้อย่างไร?';

  @override
  String get workingMemory => 'หน่วยความจำทำงาน';

  @override
  String get workspaceName => 'ชื่อเวิร์กสเปซ';

  @override
  String get workspaceScopedSkills => 'ไฟล์สกิลระดับเวิร์กสเปซที่แนบกับเอเจนต์';

  @override
  String get workspaces => 'เวิร์กสเปซ';

  @override
  String get writePrivateNotes => 'เขียนบันทึกส่วนตัว ข้อสังเกต แผน...';

  @override
  String get writeSkillContent => 'เขียนเนื้อหาสกิลที่นี่ (Markdown)…';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ปีที่แล้ว',
      one: '1 ปีที่แล้ว',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'เมื่อวาน';

  @override
  String get focusModeStart => 'เริ่มเซสชันโฟกัส';

  @override
  String get focusModeConfigTitle => 'เริ่มเซสชันโฟกัส';

  @override
  String get focusModeGoalLabel => 'เป้าหมาย';

  @override
  String get focusModeGoalHint => 'คุณกำลังทำงานอะไร?';

  @override
  String get focusModeDurationLabel => 'ระยะเวลา';

  @override
  String get focusModeBlockNotifications => 'บล็อกการแจ้งเตือน';

  @override
  String get focusModeStartButton => 'เริ่ม';

  @override
  String get focusModeFloat => 'ย่อเป็นแถบ';

  @override
  String get focusModeActiveTooltip => 'โหมดโฟกัสกำลังทำงาน — แตะเพื่อจบ';

  @override
  String get dismiss => 'ปิด';

  @override
  String get acceptAndResolve => 'ยอมรับและปิด';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'คุณรีวิวมาแล้ว $minutes นาที — งานวิจัยชี้ว่าคุณภาพรีวิวอาจลดลงหลัง 60 นาที ลองพักสักครู่';
  }

  @override
  String get notificationSound => 'เสียงแจ้งเตือน';

  @override
  String get notificationSoundDescription =>
      'เสียงที่เล่นเมื่อแสดงการแจ้งเตือน';

  @override
  String get notificationSoundNone => 'ไม่มี';

  @override
  String get notificationSoundPing => 'Ping';

  @override
  String get notificationSoundChime => 'Chime';

  @override
  String get notificationSoundPop => 'Pop';

  @override
  String get notificationSoundDing => 'Ding';

  @override
  String get notificationSoundWhoosh => 'Whoosh';

  @override
  String get notificationSoundMigrosSoft => 'Migros (เบา)';

  @override
  String get notificationSoundMigrosHard => 'Migros (หนัก)';

  @override
  String get notificationSoundSbb => 'SBB';

  @override
  String get notificationSoundCff => 'CFF';

  @override
  String get notificationSoundFfs => 'FFS';

  @override
  String get notificationSoundPost => 'Post';

  @override
  String get notificationSoundTest => 'ทดสอบ';

  @override
  String get notificationVolume => 'ระดับเสียง';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'ไม่มี PR โดย @$login ในเวิร์กสเปซนี้';
  }

  @override
  String get usersLabel => 'ผู้ใช้';

  @override
  String get mergePullRequest => 'รวม pull request';

  @override
  String get forceMergePullRequest => 'บังคับรวม pull request';

  @override
  String get closePullRequest => 'ปิด pull request';

  @override
  String get closePullRequestConfirm =>
      'แน่ใจหรือไม่ว่าต้องการปิด pull request นี้?';

  @override
  String get stackedPullRequests => 'Pull request ที่ซ้อนกัน';

  @override
  String partOfStack(int position, int total) {
    return 'เป็นส่วนของสแต็ก ($position จาก $total)';
  }

  @override
  String get createStack => 'สร้างสแต็ก';

  @override
  String get createStackDialogTitle => 'สร้างสแต็ก pull request';

  @override
  String createStackDialogBody(int count) {
    return 'pull request ทั้ง $count รายการจะถูกซ้อนจากล่างขึ้นบน:';
  }

  @override
  String get createStackInvalidSelection =>
      'เลือกอย่างน้อยสอง pull request จากรีโพสิทอรีเดียวกันเพื่อสร้างสแต็ก';

  @override
  String get createStackNotAChain =>
      'pull request ที่เลือกไม่ได้เป็นสายโซ่: สาขาฐานของแต่ละรายการต้องเป็นสาขาหัวของรายการก่อนหน้า';

  @override
  String get createStackAlreadyStacked =>
      'มี pull request ที่เลือกอย่างน้อยหนึ่งรายการอยู่ในสแต็กแล้ว';

  @override
  String get stackCreated => 'สร้างสแต็กแล้ว';

  @override
  String get stackCreationFailed => 'สร้างสแต็กไม่ได้';

  @override
  String get squashAndMerge => 'สควอชแล้วรวม';

  @override
  String get createMergeCommit => 'สร้างคอมมิตการรวม';

  @override
  String get rebaseAndMerge => 'รีเบสแล้วรวม';

  @override
  String get mergeMethod => 'วิธีการรวม';

  @override
  String get commitTitle => 'ชื่อคอมมิต';

  @override
  String get commitDescription => 'คำอธิบายคอมมิต';

  @override
  String get pullRequestMerged => 'รวม pull request แล้ว';

  @override
  String get pullRequestClosed => 'ปิด pull request แล้ว';

  @override
  String failedToMergePr(String error) {
    return 'รวมไม่ได้: $error';
  }

  @override
  String failedToClosePr(String error) {
    return 'ปิดไม่ได้: $error';
  }

  @override
  String get markReadyForReview => 'พร้อมรีวิว';

  @override
  String get markReadyForReviewConfirm =>
      'pull request นี้จะออกจากฉบับร่าง ผู้รีวิวจะได้รับแจ้ง การตรวจที่จำเป็นเริ่มกั้นการรวม และระบบอัตโนมัติที่เฝ้า PR ที่พร้อมจะทำงาน';

  @override
  String get convertToDraft => 'แปลงเป็นฉบับร่าง';

  @override
  String get convertToDraftConfirm =>
      'pull request นี้จะกลับเป็นฉบับร่าง คำขอรีวิวที่ค้างจะถูกยกเลิก และรวมไม่ได้จนกว่าจะทำเครื่องหมายว่าพร้อมอีกครั้ง';

  @override
  String get pullRequestMarkedReady =>
      'ทำเครื่องหมาย pull request ว่าพร้อมรีวิวแล้ว';

  @override
  String get pullRequestConvertedToDraft =>
      'แปลง pull request เป็นฉบับร่างแล้ว';

  @override
  String failedToMarkPrReady(String error) {
    return 'ทำเครื่องหมายว่าพร้อมรีวิวไม่ได้: $error';
  }

  @override
  String failedToConvertPrToDraft(String error) {
    return 'แปลงเป็นฉบับร่างไม่ได้: $error';
  }

  @override
  String get checksFailing => 'การตรวจล้มเหลว';

  @override
  String get reviewsPending => 'มีรีวิวที่รออยู่';

  @override
  String get mergeConflictsWithBase => 'สาขานี้มีความขัดแย้งที่ต้องแก้';

  @override
  String get branchOutOfDateWithBase => 'สาขานี้ไม่ตรงกับสาขาฐาน';

  @override
  String get mergeBlockedByBranchProtection => 'การป้องกันสาขากั้นการรวมนี้';

  @override
  String get confirm => 'ยืนยัน';

  @override
  String get trustedSitesSectionTitle => 'ไซต์ที่เชื่อถือ';

  @override
  String get trustedSitesEmpty =>
      'ไม่มีไซต์ที่เชื่อถือ เพิ่มโดเมนเพื่อปิดการบล็อกบนโดเมนนั้น';

  @override
  String get addTrustedSite => 'เพิ่มไซต์ที่เชื่อถือ';

  @override
  String get removeTrustedSite => 'ลบออก';

  @override
  String get disableBlockingForThisSite => 'ปิดการบล็อกบนไซต์นี้';

  @override
  String get enableBlockingForThisSite => 'เปิดการบล็อกบนไซต์นี้';

  @override
  String get enterDomainHint => 'เช่น example.com';

  @override
  String get invalidDomain => 'ใส่โดเมนที่ถูกต้อง (เช่น example.com)';

  @override
  String get pageLoadTimedOut =>
      'โหลดหน้าหมดเวลา โหลดใหม่หรือเปิดในเบราว์เซอร์';

  @override
  String get pipelinesScreenTitle => 'ไปป์ไลน์';

  @override
  String get pipelinesScreenSubtitle =>
      'เวิร์กโฟลว์เอเจนต์หลายขั้นตอนแบบประกาศ';

  @override
  String get pipelinesRunPipeline => 'รันไปป์ไลน์';

  @override
  String get pipelineRunLauncherTitle => 'รันไปป์ไลน์';

  @override
  String get pipelineRunSubtitle => 'เลือกไปป์ไลน์แล้วกรอกอินพุตเพื่อเริ่มรัน';

  @override
  String get pipelineRunNoInputsBadge => 'ไม่มีอินพุต';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count อินพุต',
      one: '1 อินพุต',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'ไปป์ไลน์นี้ไม่รับอินพุต';

  @override
  String get pipelineRunSubmit => 'รันไปป์ไลน์';

  @override
  String get pipelineRunCouldNotStart => 'เริ่มรันไม่ได้';

  @override
  String pipelineRunStarted(String name) {
    return 'เริ่ม $name แล้ว';
  }

  @override
  String get pipelineRunEmptyTitle => 'ไม่มีไปป์ไลน์ที่พร้อมรัน';

  @override
  String get pipelineRunEmptyHint =>
      'เปิดใช้ไปป์ไลน์และเปิดการรันด้วยตนเองในตัวแก้ไขเพื่อเริ่มที่นี่';

  @override
  String get pipelineRunManageTemplates => 'จัดการไปป์ไลน์';

  @override
  String get pipelineRunSettingsTitle => 'รันด้วยตนเอง';

  @override
  String get pipelineRunSettingsAllow => 'อนุญาตการรันด้วยตนเอง';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'แสดงไปป์ไลน์นี้ในหน้ารันเพื่อเริ่มด้วยตนเองได้';

  @override
  String get pipelineRunSettingsConcurrencyTitle => 'การทำงานพร้อมกัน';

  @override
  String get pipelineRunSettingsMaxParallel => 'รันขนานสูงสุด';

  @override
  String get pipelineRunSettingsMaxParallelHelp =>
      'เว้นว่างเพื่อไม่จำกัด รันส่วนเกินจะรอในคิวและเริ่มเมื่อมีช่องว่าง';

  @override
  String get pipelineRunSettingsMaxParallelHint => 'ไม่จำกัด';

  @override
  String get pipelineRunSettingsMaxParallelInvalid =>
      'ใส่จำนวนเต็ม 1 ขึ้นไป หรือเว้นว่างเพื่อไม่จำกัด';

  @override
  String get pipelineRunSettingsInputsTitle => 'อินพุต';

  @override
  String get pipelineRunSettingsAddInput => 'เพิ่มอินพุต';

  @override
  String get pipelineRunSettingsNoInputs => 'ยังไม่มีอินพุต';

  @override
  String get pipelineInputEditTitle => 'ฟิลด์อินพุต';

  @override
  String get pipelineInputKeyLabel => 'คีย์';

  @override
  String get pipelineInputKeyHelp =>
      'คีย์สถานะที่เก็บค่า (เช่น repo_full_name)';

  @override
  String get pipelineInputLabelLabel => 'ป้าย';

  @override
  String get pipelineInputTypeLabel => 'ชนิด';

  @override
  String get pipelineInputOptionsLabel => 'ตัวเลือก (คั่นด้วยจุลภาค)';

  @override
  String get pipelineInputDefaultLabel => 'ค่าเริ่มต้น';

  @override
  String get pipelineInputPlaceholderLabel => 'ข้อความตัวอย่าง';

  @override
  String get pipelineInputHelpLabel => 'ข้อความช่วยเหลือ';

  @override
  String get pipelineInputRequiredLabel => 'จำเป็น';

  @override
  String get pipelineInputTypeText => 'ข้อความ';

  @override
  String get pipelineInputTypeMultiline => 'ข้อความหลายบรรทัด';

  @override
  String get pipelineInputTypeNumber => 'ตัวเลข';

  @override
  String get pipelineInputTypeBoolean => 'สวิตช์';

  @override
  String get pipelineInputTypeSelect => 'เลือก';

  @override
  String get pipelinesEmpty => 'ยังไม่มีรันไปป์ไลน์';

  @override
  String get pipelinesEmptyHint => 'คลิก \'รันไปป์ไลน์\' เพื่อเริ่ม';

  @override
  String get pipelinesNoSteps => 'ยังไม่มีขั้นตอนที่บันทึก';

  @override
  String get pipelinesNoActiveWorkspace => 'เลือกเวิร์กสเปซเพื่อดูไปป์ไลน์';

  @override
  String pipelinesLoadError(String error) {
    return 'โหลดไปป์ไลน์ไม่ได้: $error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'เริ่มไปป์ไลน์ไม่ได้: $error';
  }

  @override
  String get pipelineStatusPending => 'รอดำเนินการ';

  @override
  String get pipelineStatusQueued => 'อยู่ในคิว';

  @override
  String get pipelineStatusRunning => 'กำลังรัน';

  @override
  String get pipelineStatusSuspended => 'ระงับ';

  @override
  String get pipelineStatusCompleted => 'เสร็จแล้ว';

  @override
  String get pipelineStatusFailed => 'ล้มเหลว';

  @override
  String get pipelineStatusCancelled => 'ยกเลิกแล้ว';

  @override
  String get pipelineStatusSkipped => 'ข้ามแล้ว';

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed จาก $total ขั้นตอน';
  }

  @override
  String get pipelineWaterfallTimeline => 'ไทม์ไลน์';

  @override
  String pipelineWaterfallActive(String duration) {
    return 'ใช้งาน $duration';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return 'ว่าง $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip =>
      'เวลาที่ไม่นับในยอดใช้งาน: รันถูกหยุดหรือรอระหว่างขั้นตอน';

  @override
  String get pipelineStepStarted => 'เริ่มแล้ว';

  @override
  String get pipelineStepFinished => 'จบแล้ว';

  @override
  String get pipelineStepDurationLabel => 'ระยะเวลา';

  @override
  String get pipelineStepBranch => 'สาขา';

  @override
  String get pipelineStepViewConversation => 'ดูการสนทนา';

  @override
  String get pipelineStepError => 'ข้อผิดพลาด';

  @override
  String get pipelineStepInput => 'อินพุต';

  @override
  String get pipelineStepOutput => 'เอาต์พุต';

  @override
  String get pipelineStepNotExecuted => 'ยังไม่ได้รัน';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'ล้มเหลวที่ $step';
  }

  @override
  String get pipelineRunTriggerManual => 'ด้วยตนเอง';

  @override
  String get pipelineStepSkippedReason => 'ข้ามแล้ว';

  @override
  String get pipelineStepPriorAttempts => 'ครั้งก่อนหน้า';

  @override
  String get pipelineStepAttemptLabel => 'ครั้งที่ลอง';

  @override
  String pipelineStepAttemptN(int number) {
    return 'ครั้งที่ $number';
  }

  @override
  String get pipelineStepAttemptInterrupted => 'ถูกขัดจังหวะ';

  @override
  String get pipelineRunColumnPipeline => 'ไปป์ไลน์';

  @override
  String get pipelineRunColumnDuration => 'ระยะเวลา';

  @override
  String get pipelineRunQueueNext => 'ถัดไป';

  @override
  String pipelineRunQueuePosition(int position) {
    return 'คิวที่ $position';
  }

  @override
  String get pipelineRunColumnStarted => 'เริ่มแล้ว';

  @override
  String get pipelineRunHistory => 'ประวัติรัน';

  @override
  String get pipelineRunHistoryEmpty => 'ยังไม่มีรันอื่น';

  @override
  String pipelineRunRerunAgo(String time) {
    return 'รันใหม่ $time';
  }

  @override
  String pipelineRunAttempt(int number) {
    return 'ครั้งที่ $number';
  }

  @override
  String pipelineRunFirstStarted(String time) {
    return 'เริ่มครั้งแรก $time';
  }

  @override
  String get pipelineRunFilterAll => 'ทั้งหมด';

  @override
  String get pipelineRunFilterEmpty => 'ไม่มีรันที่ตรงกับตัวกรองนี้';

  @override
  String get relativeJustNow => 'เมื่อสักครู่';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count นาทีที่แล้ว',
      one: '1 นาทีที่แล้ว',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ชั่วโมงที่แล้ว',
      one: '1 ชั่วโมงที่แล้ว',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count วันที่แล้ว',
      one: '1 วันที่แล้ว',
    );
    return '$_temp0';
  }

  @override
  String get teamsTitle => 'ทีม';

  @override
  String get teamsAddTeam => 'เพิ่มทีม';

  @override
  String get teamsLoadError => 'โหลดทีมไม่ได้';

  @override
  String get teamsEmptyTitle => 'ยังไม่มีทีม';

  @override
  String get teamsEmptyDescription =>
      'จัดกลุ่มเอเจนต์เป็นทีม เพื่อให้งานที่มอบหมายให้ทีมผ่านหัวหน้าซึ่งมอบหมายต่อ';

  @override
  String get teamCreateTitle => 'ทีมใหม่';

  @override
  String get teamEditTitle => 'แก้ไขทีม';

  @override
  String get teamNameLabel => 'ชื่อทีม';

  @override
  String get teamNameHint => 'เช่น Frontend';

  @override
  String get teamDescriptionLabel => 'คำอธิบาย';

  @override
  String get teamDescriptionHint => 'ทีมนี้รับผิดชอบอะไร';

  @override
  String get teamLeaderLabel => 'หัวหน้า';

  @override
  String get teamLeaderHelp =>
      'ผู้ประสานที่รับงานของทีมและมอบหมายให้สมาชิกที่เหมาะสมที่สุด';

  @override
  String get teamNoLeader => 'ไม่มีหัวหน้า';

  @override
  String get teamInstructionsLabel => 'คำสั่งการทำงาน';

  @override
  String get teamInstructionsHelp =>
      'ต่อท้ายบรีฟของหัวหน้า — ข้อตกลงของทีม กฎการยกระดับ น้ำเสียง';

  @override
  String get teamInstructionsHint => 'ไม่บังคับ';

  @override
  String get teamSaved => 'บันทึกทีมแล้ว';

  @override
  String get teamMembersError => 'โหลดสมาชิกไม่ได้';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count สมาชิก',
      one: '1 สมาชิก',
      zero: 'ไม่มีสมาชิก',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => 'เพิ่มสมาชิก';

  @override
  String get teamAddMemberTitle => 'เพิ่มสมาชิก';

  @override
  String teamAddMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เพิ่ม $count',
      one: 'เพิ่ม 1',
      zero: 'เพิ่ม',
    );
    return '$_temp0';
  }

  @override
  String get teamNoAgentsToAdd => 'เอเจนต์ทุกคนอยู่ในทีมนี้แล้ว';

  @override
  String get teamRemoveMember => 'ลบออกจากทีม';

  @override
  String get teamLeaderBadge => 'หัวหน้า';

  @override
  String get teamUnknownAgent => 'เอเจนต์ที่ไม่ทราบ';

  @override
  String get teamMembersEmpty => 'ยังไม่มีสมาชิก';

  @override
  String get teamMembersEmptyDescription =>
      'เพิ่มเอเจนต์เพื่อให้หัวหน้ามีคนมอบหมายงาน';

  @override
  String get teamSelectPrompt => 'เลือกทีม';

  @override
  String get teamSelectPromptDescription => 'เลือกทีมจากรายการ หรือสร้างใหม่';

  @override
  String get teamDeleteTitle => 'ลบทีมหรือไม่?';

  @override
  String teamDeleteBody(String name) {
    return '$name จะถูกลบ เอเจนต์จะไม่ได้รับผลกระทบ';
  }

  @override
  String get teamHasLeaderTooltip => 'มีหัวหน้า';

  @override
  String get pipelineTemplatesNav => 'เทมเพลตไปป์ไลน์';

  @override
  String get pipelineTemplatesTitle => 'เทมเพลตไปป์ไลน์';

  @override
  String get pipelineTemplatesSubtitle =>
      'ตัวแก้ไขลากแล้ววางสำหรับไปป์ไลน์ที่ประสานเอเจนต์ของคุณ';

  @override
  String get pipelineTemplatesNew => 'เทมเพลตใหม่';

  @override
  String get pipelineTemplatesEmpty =>
      'ยังไม่มีเทมเพลตไปป์ไลน์ สร้างหนึ่งรายการเพื่อเริ่มต้น';

  @override
  String get pipelineTemplateBuiltInBadge => 'ในตัว';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'ลบเทมเพลตหรือไม่?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'ลบเทมเพลตไปป์ไลน์ $name หรือไม่? เลิกทำไม่ได้';
  }

  @override
  String get pipelineTemplateEditorSubtitle =>
      'ลากชนิดโหนดจากแถบข้างลงบนแคนวาส แล้วต่อเข้าด้วยกัน';

  @override
  String get unsavedChanges => 'มีการเปลี่ยนแปลงที่ยังไม่บันทึก';

  @override
  String get nodeLibraryTitle => 'คลังโหนด';

  @override
  String get nodeLibraryHint => 'ลากรายการใดก็ได้ลงบนแคนวาสเพื่อเพิ่มโหนด';

  @override
  String get editorEmptyCanvas => 'ลากโหนดจากคลังเพื่อเริ่ม';

  @override
  String get pipelineWhenThisHappens => 'เมื่อสิ่งนี้เกิดขึ้น';

  @override
  String get pipelineDoThis => 'ทำสิ่งนี้';

  @override
  String get pipelineAddStep => 'เพิ่มขั้นตอน';

  @override
  String get pipelineTidyUp => 'จัดเลย์เอาต์ให้เป็นระเบียบ';

  @override
  String get pipelineEditorHint =>
      'ลากขั้นตอนเพื่อจัดวาง · ลากจุดจับเพื่อเชื่อมต่อ';

  @override
  String get pipelineRemoveConnection => 'ลบการเชื่อมต่อ';

  @override
  String get pipelineDragToConnect => 'ลากเพื่อเชื่อมต่อ';

  @override
  String get pipelineNewDefaultName => 'ไปป์ไลน์ใหม่';

  @override
  String get nodeCategoryTriggers => 'ทริกเกอร์';

  @override
  String get triggerEventWebhook => 'Webhook';

  @override
  String get pipelineAddTrigger => 'เพิ่มทริกเกอร์';

  @override
  String get pipelineOnEvent => 'เมื่อเกิดเหตุการณ์';

  @override
  String get nodeConfigTitle => 'การตั้งค่าโหนด';

  @override
  String get nodeConfigKind => 'ชนิด';

  @override
  String get nodeConfigLabel => 'ป้าย';

  @override
  String get nodeConfigAgent => 'เอเจนต์';

  @override
  String get nodeConfigAgentHint => 'เลือกเอเจนต์…';

  @override
  String get nodeConfigInputKeys => 'คีย์อินพุต (คั่นด้วยจุลภาค)';

  @override
  String get nodeConfigInputKeysHelp =>
      'คีย์สถานะที่โหนดนี้ใช้ สำหรับแทนที่ตัวยึดในพรอมต์';

  @override
  String get nodeConfigRepos => 'รีโพสิทอรีที่จะโคลน';

  @override
  String get nodeConfigReposHelp =>
      'รีโพสิทอรีที่ถูกโคลนและจัดทำดัชนีโค้ดเมื่อโหนดนี้เริ่มการสนทนา การเลือกทุกรีโพสิทอรีจะโคลนทั้งหมด (ค่าเริ่มต้น)';

  @override
  String get nodeConfigRepoBranchHint => 'สาขา (ค่าเริ่มต้น)';

  @override
  String get nodeConfigRepoBranchHelp =>
      'สาขาที่แต่ละเช็กเอาต์ถูกตัดออก เว้นว่างเพื่อใช้สาขาเริ่มต้นของรีโพสิทอรี — worktree ยังได้สาขาของตัวเอง ดังนั้นคอมมิตของเอเจนต์จะไม่ลงสาขานี้';

  @override
  String nodeConfigReposDynamic(String entries) {
    return 'คงรายการไดนามิกไว้: $entries';
  }

  @override
  String get nodeConfigCreateConversation => 'เปิดการสนทนาในนั้น';

  @override
  String get nodeConfigCreateConversationHelp =>
      'ปิดไว้เมื่อมีโหนดเอเจนต์ตามมาหลายตัว — แต่ละตัวเปิดสตรีมชื่อของตัวเอง เปิดเมื่อมีโหนดเอเจนต์ตามมาตัวเดียว เพื่อไม่ให้ห้องแสดงการสนทนาไม่มีชื่อข้าง ๆ';

  @override
  String get nodeConfigConversationTitle => 'ชื่อการสนทนา';

  @override
  String get nodeConfigConversationTitleHelp =>
      'ตั้งชื่อโหนดเอเจนต์ด้านล่างให้เหมือนกัน แล้วทั้งคู่ทำงานในสตรีมเดียว ค่าเริ่มต้นคือป้ายของโหนด';

  @override
  String get nodeConfigSpaceName => 'ชื่อสเปซ';

  @override
  String get nodeConfigSpaceNameHelp =>
      'ชื่อห้องที่โหนดนี้เปิด รองรับตัวยึดสถานะแบบเดียวกับพรอมต์ เว้นว่างเพื่อใช้ป้ายของโหนด';

  @override
  String get nodeConfigSpaceNameHint => 'Review of pr_number';

  @override
  String get nodeConfigStreamTitle => 'ชื่อการสนทนา';

  @override
  String get nodeConfigStreamTitleHelp =>
      'สตรีมที่มีชื่อที่เอเจนต์ของโหนดนี้ทำงานในห้อง รองรับตัวยึดสถานะแบบเดียวกับพรอมต์ เว้นว่างแล้วเทิร์นจะไปที่การสนทนาประจำของห้อง ที่ซึ่งการกระจายจะสลับเอเจนต์ทุกตัว';

  @override
  String get nodeConfigConversationTitleHint => 'Architecture analysis';

  @override
  String get nodeConfigOutputKey => 'คีย์เอาต์พุต';

  @override
  String get nodeConfigPrompt => 'เทมเพลตพรอมต์';

  @override
  String get nodeConfigPromptHelp =>
      'ใช้ตัวยึดวงเล็บปีกกาคู่เพื่อดึงค่าจากสถานะตอนรัน';

  @override
  String get nodeConfigScript => 'สคริปต์ Bash';

  @override
  String get nodeConfigScriptHelp =>
      'รันด้วย bash -c มีการตั้ง GITHUB_TOKEN ตัวยึดถูกแทนที่ก่อนรัน';

  @override
  String get nodeConfigRouteKeys => 'คีย์เส้นทาง';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'คีย์เส้นทางจาก $source';
  }

  @override
  String get conditionSectionTitle => 'เงื่อนไข';

  @override
  String get conditionMode => 'โหมด';

  @override
  String get conditionModeFilesAny => 'มีไฟล์อยู่ — อย่างใดอย่างหนึ่ง';

  @override
  String get conditionModeFilesAll => 'มีไฟล์อยู่ — ทั้งหมด';

  @override
  String get conditionModeComparison => 'การเปรียบเทียบ';

  @override
  String get conditionModeSwitch => 'สวิตช์';

  @override
  String get conditionFilePaths => 'พาธไฟล์';

  @override
  String get conditionFilePathsAnyHelp =>
      'พาธละบรรทัด สัมพันธ์กับไดเรกทอรีฐาน ส่ง true เมื่อมีอย่างน้อยหนึ่งรายการ';

  @override
  String get conditionFilePathsAllHelp =>
      'พาธละบรรทัด สัมพันธ์กับไดเรกทอรีฐาน ส่ง true เมื่อมีครบทั้งหมด';

  @override
  String get conditionBaseKey => 'คีย์ไดเรกทอรีฐาน';

  @override
  String get conditionBaseKeyHelp =>
      'คีย์สถานะที่เก็บไดเรกทอรีที่พาธอ้างอิง (ค่าเริ่มต้น repo_local_path)';

  @override
  String get conditionRecursive => 'ค้นหาในไดเรกทอรีย่อย';

  @override
  String get conditionNegate => 'กลับค่า: ส่ง true เมื่อไม่มี';

  @override
  String get conditionLeft => 'ค่าซ้าย';

  @override
  String get conditionOperator => 'ตัวดำเนินการ';

  @override
  String get conditionRight => 'ค่าขวา';

  @override
  String get conditionSwitchKey => 'สวิตช์ตามคีย์สถานะ';

  @override
  String get conditionCases => 'กรณี (คั่นด้วยจุลภาค)';

  @override
  String get conditionCasesHelp => 'คีย์เส้นทางที่จับคู่กับค่า ตามลำดับ';

  @override
  String get conditionDefaultCase => 'กรณีเริ่มต้น';

  @override
  String get triggerManualHelp => 'แสดงในหน้ารันและเริ่มด้วยตนเอง';

  @override
  String get triggerKindSchedule => 'ตามตารางเวลา';

  @override
  String get triggerScheduleExprLabel => 'ตารางเวลา (cron หรือ every:seconds)';

  @override
  String get triggerTimezoneLabel => 'เขตเวลา (ไม่บังคับ)';

  @override
  String get triggerCatchUpLabel => 'เมื่อพลาดรัน';

  @override
  String get triggerCatchUpRunOnce => 'รันครั้งเดียว';

  @override
  String get triggerCatchUpSkip => 'ข้าม';

  @override
  String get syncHealthTitle => 'สุขภาพการซิงค์';

  @override
  String get syncHealthNoConfigs => 'ยังไม่มีการเชื่อมต่อซิงค์';

  @override
  String get syncHealthNeverSynced => 'ยังไม่ได้ซิงค์';

  @override
  String get syncOutcomeOk => 'ซิงค์แล้ว';

  @override
  String get syncOutcomeFailed => 'ล้มเหลว';

  @override
  String get syncOutcomeSkipped => 'ข้ามแล้ว';

  @override
  String syncHealthFailedStreak(int count) {
    return 'ล้มเหลวติดต่อกัน $count ครั้ง';
  }

  @override
  String get triggerWebhookHelp =>
      'สร้าง URL webhook ที่ลงนาม ระบบภายนอก POST ไปที่นั่นเพื่อเริ่มไปป์ไลน์นี้';

  @override
  String get triggerWebhookPathLabel => 'เส้นทางเว็บฮุค';

  @override
  String get triggerMatchStatusLabel => 'เฉพาะเมื่อสถานะคือ';

  @override
  String get triggerSummaryNone => 'ไม่มีทริกเกอร์';

  @override
  String triggerEverySeconds(int seconds) {
    return 'ทุก $seconds วินาที';
  }

  @override
  String get triggerEventManual => 'รันด้วยตนเอง';

  @override
  String get triggerEventSchedule => 'ตารางเวลา';

  @override
  String get triggerEventPrStatusChanged => 'สถานะ PR เปลี่ยน';

  @override
  String get triggerEventExternalPr => 'เปิด PR ภายนอก';

  @override
  String get triggerEventPrPublished => 'เผยแพร่ PR';

  @override
  String get triggerEventPrMerged => 'รวม PR แล้ว';

  @override
  String get triggerEventRepoAdded => 'เพิ่มรีโพสิทอรี';

  @override
  String get triggerEventCodeGraphWatch => 'ไฟล์เปลี่ยน';

  @override
  String pipelineRunCauseChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ไฟล์ที่เปลี่ยน',
      one: '1 ไฟล์ที่เปลี่ยน',
    );
    return '$_temp0';
  }

  @override
  String pipelineRunCauseMorePaths(int count) {
    return 'อีก $count รายการ';
  }

  @override
  String get pipelineRunCauseRescan => 'เปลี่ยนบนดิสก์';

  @override
  String get pipelineRunCauseInitial => 'ดัชนีแรกของเช็กเอาต์นี้';

  @override
  String get triggerEventMessageReceived => 'ได้รับข้อความ';

  @override
  String get triggerEventTicketCompleted => 'ตั๋วงานเสร็จ';

  @override
  String get triggerEventTicketFailed => 'ตั๋วงานล้มเหลว';

  @override
  String get triggerEventTicketCancelled => 'ตั๋วงานถูกยกเลิก';

  @override
  String get triggerEventBudgetCrossed => 'ข้ามเกณฑ์งบประมาณ';

  @override
  String get nodeLibrarySearchHint => 'ค้นหาโหนด';

  @override
  String get nodeLibraryNoMatches => 'ไม่มีโหนดที่ตรง';

  @override
  String get nodeCategoryFlow => 'โฟลว์และตรรกะ';

  @override
  String get nodeCategoryPr => 'รีวิว PR';

  @override
  String get nodeCategoryAgents => 'เอเจนต์';

  @override
  String get nodeCategoryMessaging => 'ข้อความ';

  @override
  String get nodeCategoryCode => 'โค้ด';

  @override
  String get triggerDisabledTag => 'ปิด';

  @override
  String get pipelineInputTypeRepo => 'รีโพสิทอรี';

  @override
  String get pipelineRunNoRepos => 'ยังไม่มีรีโพสิทอรีในเวิร์กสเปซนี้';

  @override
  String get allowTicketingApi => 'อนุญาตการเรียก ticketing API';

  @override
  String get ticketingApiKey => 'คีย์ API ของตั๋วงาน';

  @override
  String get ticketingApiKeySubtitle =>
      'ฉีดคีย์ API ของผู้ให้บริการตั๋วงานเข้าแซนด์บ็อกซ์';

  @override
  String get ticketingProvider => 'ผู้ให้บริการตั๋วงาน';

  @override
  String get connectGitHubAndTicketing =>
      'เชื่อมต่อโฮสต์โค้ดเพื่อให้ Control Center อ่าน pull request, issue และรีวิวของคุณ ได้เชื่อมต่อผู้ให้บริการตั๋วงานด้วยก็ได้ ข้อมูลรับรองอยู่ที่เซิร์ฟเวอร์ ไม่ใช่เครื่องนี้';

  @override
  String get triggerEventTicketAssigned => 'มอบหมายตั๋วงาน';

  @override
  String get triggerEventTicketCreated => 'สร้างตั๋วงานแล้ว';

  @override
  String get triggerEventTicketStatusChanged => 'สถานะตั๋วงานเปลี่ยน';

  @override
  String get triggerEventMeetingRecordingStopped => 'หยุดการบันทึกประชุม';

  @override
  String get triggerEventSkillUpdated => 'อัปเดตสกิลแล้ว';

  @override
  String get triggerEventSpaceDeleted => 'สเปซถูกลบ';

  @override
  String get triggerExternalPrHelp =>
      'คำขอพุลที่เปิดบนโฮสต์โค้ด ไม่ใช่จาก Control Center';

  @override
  String get triggerPrPublishedHelp =>
      'คำขอพุลที่เปิดจาก Control Center หรือโดยเอเจนต์';

  @override
  String get triggerPrStatusChangedHelp =>
      'ถูกรวม ปิด เปิด เปิดใหม่ หรืออนุมัติ กรองตามสถานะในตัวตรวจสอบ';

  @override
  String get triggerPrMergedHelp =>
      'เฉพาะเมื่อคำขอพุลถูกรวม ไม่ใช่เมื่อปิดหรือเปิดใหม่';

  @override
  String get triggerRepoAddedHelp => 'ที่เก็บถูกเชื่อมกับพื้นที่ทำงานนี้';

  @override
  String get triggerCodeGraphWatchHelp =>
      'ไฟล์ในที่เก็บที่เชื่อมอยู่เปลี่ยนบนดิสก์';

  @override
  String get triggerMessageReceivedHelp => 'ข้อความใหม่มาถึงในสเปซ';

  @override
  String get triggerTicketCreatedHelp => 'ตั๋วถูกสร้างในพื้นที่ทำงานนี้';

  @override
  String get triggerTicketStatusChangedHelp => 'ตั๋วย้ายระหว่างสถานะ';

  @override
  String get triggerTicketCompletedHelp => 'ตั๋วเสร็จสมบูรณ์';

  @override
  String get triggerTicketFailedHelp =>
      'การรันเอเจนต์ล้มเหลว และตั๋วถูกทำเครื่องหมายว่าล้มเหลว';

  @override
  String get triggerTicketCancelledHelp => 'ตั๋วถูกยกเลิกและจะไม่ต่อ';

  @override
  String get triggerBudgetCrossedHelp =>
      'เกินขีดจำกัดการใช้จ่ายของพื้นที่ทำงานหรือเอเจนต์';

  @override
  String get triggerTicketAssignedHelp =>
      'ตั๋วถูกมอบหมายให้บุคคล เอเจนต์ หรือทีม';

  @override
  String get triggerMeetingRecordingStoppedHelp => 'การบันทึกการประชุมสิ้นสุด';

  @override
  String get triggerSkillUpdatedHelp => 'สกิลถูกติดตั้งหรืออัปเดต';

  @override
  String get triggerSpaceDeletedHelp => 'สเปซสนทนาถูกลบ';

  @override
  String get navTickets => 'ตั๋วงาน';

  @override
  String get ticketsTitle => 'ตั๋วงาน';

  @override
  String get newTicket => 'ตั๋วงานใหม่';

  @override
  String get noTicketsYet => 'ยังไม่มีตั๋วงาน';

  @override
  String get addCollaborator => 'เพิ่มผู้ร่วมงาน';

  @override
  String get noCollaborators => 'ยังไม่มีผู้ร่วมงาน';

  @override
  String get linkedPullRequests => 'Pull request ที่ลิงก์';

  @override
  String get noLinkedPullRequests => 'ยังไม่มี pull request ที่ลิงก์';

  @override
  String get stopAgent => 'หยุดเอเจนต์';

  @override
  String get ticketProperties => 'คุณสมบัติ';

  @override
  String get ticketTabIssue => 'Issue';

  @override
  String get ticketSelectPrompt => 'เลือกตั๋วงานเพื่อดูรายละเอียด';

  @override
  String get unassigned => 'ยังไม่มอบหมาย';

  @override
  String get ticketStatusBacklog => 'งานค้าง';

  @override
  String get ticketStatusOpen => 'สิ่งที่ต้องทำ';

  @override
  String get ticketStatusInProgress => 'กำลังดำเนินการ';

  @override
  String get ticketStatusInReview => 'กำลังรีวิว';

  @override
  String get ticketStatusDone => 'เสร็จแล้ว';

  @override
  String get ticketStatusBlocked => 'ถูกบล็อก';

  @override
  String get ticketStatusFailed => 'ล้มเหลว';

  @override
  String get ticketStatusCancelled => 'ยกเลิกแล้ว';

  @override
  String get notificationTicketAssigned => 'มอบหมายตั๋วงานแล้ว';

  @override
  String get notificationTicketStatusChanged => 'สถานะตั๋วงานเปลี่ยน';

  @override
  String get priority => 'ลำดับความสำคัญ';

  @override
  String get status => 'สถานะ';

  @override
  String get assignee => 'ผู้รับมอบหมาย';

  @override
  String get labels => 'ป้ายกำกับ';

  @override
  String get noLabelsYet => 'ยังไม่มีป้ายกำกับ';

  @override
  String get clearLabels => 'ล้างป้ายกำกับ';

  @override
  String get pipelineStepAgentActivity => 'กิจกรรมของเอเจนต์';

  @override
  String get runStatusCompleted => 'เสร็จแล้ว';

  @override
  String get runStatusQueued => 'อยู่ในคิว';

  @override
  String get ticketDescription => 'คำอธิบาย';

  @override
  String get ticketPriorityNone => 'ไม่มี';

  @override
  String get ticketPriorityUrgent => 'เร่งด่วน';

  @override
  String get ticketPriorityHigh => 'สูง';

  @override
  String get ticketPriorityMedium => 'ปานกลาง';

  @override
  String get ticketPriorityLow => 'ต่ำ';

  @override
  String get ticketViewList => 'รายการ';

  @override
  String get ticketViewBoard => 'บอร์ด';

  @override
  String get ticketTitlePlaceholder => 'ชื่อ issue';

  @override
  String get ticketDescriptionPlaceholder => 'เพิ่มคำอธิบาย…';

  @override
  String get createMore => 'สร้างเพิ่ม';

  @override
  String selectedCount(int count) {
    return 'เลือกแล้ว $count รายการ';
  }

  @override
  String get clearSelection => 'ล้างการเลือก';

  @override
  String get bulkDeleteTitle => 'ลบตั๋วงาน';

  @override
  String bulkDeleteMessage(int count) {
    return 'ลบตั๋วงานที่เลือก $count รายการหรือไม่? เลิกทำไม่ได้';
  }

  @override
  String get assignTo => 'มอบหมายให้…';

  @override
  String get sectionMembers => 'สมาชิก';

  @override
  String get sectionAgents => 'เอเจนต์';

  @override
  String get sidebarGroupWorkspace => 'เวิร์กสเปซ';

  @override
  String get notificationsTitle => 'การแจ้งเตือน';

  @override
  String get notificationsTooltip => 'การแจ้งเตือน';

  @override
  String get notificationsEmpty => 'คุณตามทันหมดแล้ว';

  @override
  String notificationsUnreadCount(int count) {
    return 'ยังไม่อ่าน $count รายการ';
  }

  @override
  String get notificationsMarkRead => 'ทำเครื่องหมายว่าอ่านแล้ว';

  @override
  String get notificationsMarkUnread => 'ทำเครื่องหมายว่ายังไม่อ่าน';

  @override
  String get notificationsEntryActions => 'การกระทำของการแจ้งเตือน';

  @override
  String get markAllRead => 'ทำเครื่องหมายทั้งหมดว่าอ่านแล้ว';

  @override
  String get teamsNav => 'ทีม';

  @override
  String get noWorkspace => 'ไม่มีเวิร์กสเปซ';

  @override
  String get selectWorkspace => 'เลือกเวิร์กสเปซ';

  @override
  String get navMemory => 'หน่วยความจำ';

  @override
  String get memoryTabFacts => 'ข้อเท็จจริง';

  @override
  String get memoryTabPolicies => 'นโยบาย';

  @override
  String get memoryGraphShowFacts => 'แสดงข้อเท็จจริง';

  @override
  String get memoryGraphHideFacts => 'ซ่อนข้อเท็จจริง';

  @override
  String get memoryGraphExpandAll => 'ขยายข้อเท็จจริงทั้งหมด';

  @override
  String get memoryGraphCollapseAll => 'ยุบข้อเท็จจริงทั้งหมด';

  @override
  String get memoryTabGraph => 'กราฟความรู้';

  @override
  String get memoryNoWorkspace => 'เลือกเวิร์กสเปซเพื่อดูหน่วยความจำ';

  @override
  String get searchArticles => 'ค้นหาบทความ';

  @override
  String get filterAll => 'ทั้งหมด';

  @override
  String get filterUnread => 'ยังไม่อ่าน';

  @override
  String get filterSaved => 'ที่บันทึก';

  @override
  String get saveArticle => 'บันทึกบทความ';

  @override
  String get removeFromSaved => 'ลบออกจากที่บันทึก';

  @override
  String get filterBySource => 'กรองตามแหล่ง';

  @override
  String get viewAsList => 'มุมมองรายการ';

  @override
  String get viewAsGrid => 'มุมมองตาราง';

  @override
  String get noMatchingArticles => 'ไม่มีบทความที่ตรง';

  @override
  String get noMatchingArticlesBody => 'ลองค้นหาหรือตัวกรองแหล่งอื่น';

  @override
  String get allCaughtUp => 'ตามทันหมดแล้ว';

  @override
  String get allCaughtUpBody => 'ไม่มีบทความที่ยังไม่อ่าน — กลับมาดูภายหลัง';

  @override
  String get openArticlesInAppDescription =>
      'เปิดลิงก์ในตัวอ่านในตัวแทนเบราว์เซอร์เริ่มต้น';

  @override
  String get blockAdsTrackersDescription =>
      'ตัดโฆษณา ตัวติดตาม และแบนเนอร์คุกกี้ออกจากบทความที่เปิดในตัวอ่าน';

  @override
  String get agentQuestionHeader => 'คำถามสำหรับคุณ';

  @override
  String get agentQuestionAnsweredLabel => 'ตอบแล้ว';

  @override
  String get agentQuestionFreeformHint => 'พิมพ์คำตอบของคุณ…';

  @override
  String agentQuestionProgress(int index, int count) {
    return 'คำถาม $index จาก $count';
  }

  @override
  String get agentQuestionSkip => 'ข้าม';

  @override
  String get agentQuestionSkippedLabel => 'ข้ามแล้ว';

  @override
  String get agentQuestionFreeformOptionHint => 'อธิบายด้วยคำของคุณเอง…';

  @override
  String get reviewRequested => 'ขอรีวิวแล้ว';

  @override
  String get connectGitHubHint =>
      'ลงชื่อเข้าใช้ GitHub หรือเพิ่มโทเค็นที่ การตั้งค่า → เวิร์กสเปซ → โปรไฟล์และตัวตน → โฮสต์โค้ด';

  @override
  String get connectGitHubToLoadPrs =>
      'เชื่อมต่อ GitHub เพื่อโหลด pull request';

  @override
  String get noRepositoriesConfigured => 'ยังไม่ได้ตั้งค่ารีโพสิทอรี';

  @override
  String openedAgo(String age) {
    return 'เปิดเมื่อ $age';
  }

  @override
  String prTimelineOpened(String author) {
    return '$author เปิด pull request นี้';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count คอมมิต',
      one: '1 คอมมิต',
    );
    return '$author เปิด pull request นี้พร้อม $_temp0';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return '$actor ขอรีวิวจาก $reviewers';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '$actor ลบคำขอรีวิวสำหรับ $reviewers';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '$actor ขอรีวิวจาก $requested และลบคำขอรีวิวสำหรับ $removed';
  }

  @override
  String prTimelineAddedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ป้าย',
      one: 'ป้าย',
    );
    return '$actor เพิ่ม$_temp0 $labels';
  }

  @override
  String prTimelineRemovedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ป้าย',
      one: 'ป้าย',
    );
    return '$actor ลบ$_temp0 $labels';
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
      other: 'ป้าย',
      one: 'ป้าย',
    );
    String _temp1 = intl.Intl.pluralLogic(
      removedCount,
      locale: localeName,
      other: 'ป้าย',
      one: 'ป้าย',
    );
    return '$actor เพิ่ม$_temp0 $added และลบ$_temp1 $removed';
  }

  @override
  String prTimelineCommitted(String author) {
    return '$author คอมมิตแล้ว';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count คอมมิต',
      one: '1 คอมมิต',
    );
    return '$author พุช $_temp0';
  }

  @override
  String prTimelineApproved(String author) {
    return '$author อนุมัติการเปลี่ยนแปลงเหล่านี้';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return '$author ขอให้แก้ไข';
  }

  @override
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ความคิดเห็นในโค้ด',
      one: '1 ความคิดเห็นในโค้ด',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '$author รีวิวแล้ว';
  }

  @override
  String get prTimelineSomeone => 'ใครบางคน';

  @override
  String get prTimelineBotBadge => 'บอต';

  @override
  String updatedAgo(String age) {
    return 'อัปเดตเมื่อ $age';
  }

  @override
  String get checksPassing => 'การตรวจผ่าน';

  @override
  String get checksRunning => 'กำลังตรวจ';

  @override
  String get needsYourReview => 'ต้องรีวิวจากคุณ';

  @override
  String get checks => 'การตรวจ';

  @override
  String get noReviewersAssigned => 'ยังไม่ได้มอบหมายผู้รีวิว';

  @override
  String get noAssignees => 'ไม่มีผู้รับมอบหมาย';

  @override
  String get loadingEllipsis => 'กำลังโหลด…';

  @override
  String get loadingChecks => 'กำลังโหลดการตรวจ…';

  @override
  String get noChecksYet => 'ยังไม่มีการตรวจที่รัน';

  @override
  String get noChangesToReview => 'ไม่มีการเปลี่ยนแปลงให้ตรวจ';

  @override
  String checksFailingCount(int count) {
    return 'ล้มเหลว $count รายการ';
  }

  @override
  String get showMore => 'แสดงเพิ่ม';

  @override
  String get showLess => 'แสดงน้อยลง';

  @override
  String get backToPullRequests => 'กลับไปที่ pull request';

  @override
  String get pullRequestNotFound => 'ไม่พบ pull request';

  @override
  String get pullRequestNotFoundBody => 'อาจถูกรวม ปิด หรือย้ายแล้ว';

  @override
  String get couldntLoadPullRequest => 'โหลด pull request นี้ไม่ได้';

  @override
  String get showDetails => 'แสดงรายละเอียด';

  @override
  String get noDescriptionProvided => 'ไม่มีคำอธิบาย';

  @override
  String get factsHint => 'ข้อเท็จจริงจะปรากฏที่นี่เมื่อเอเจนต์เรียนรู้';

  @override
  String get noFactsMatch => 'ไม่มีข้อเท็จจริงที่ตรงกับการค้นหา';

  @override
  String get memoryLoadError => 'โหลดหน่วยความจำไม่ได้';

  @override
  String get sortRecent => 'ล่าสุด';

  @override
  String get sortConfidence => 'ความมั่นใจ';

  @override
  String get confidenceTooltip =>
      'เอเจนต์มั่นใจแค่ไหนว่าข้อเท็จจริงนี้จริง จาก 0 ถึง 100%';

  @override
  String get supersededTooltip => 'ข้อเท็จจริงใหม่กว่าได้แทนที่รายการนี้แล้ว';

  @override
  String get domain => 'โดเมน';

  @override
  String get fitToView => 'พอดีกับมุมมอง';

  @override
  String get project => 'โปรเจกต์';

  @override
  String get newProject => 'โปรเจกต์ใหม่';

  @override
  String get editProject => 'แก้ไขโปรเจกต์';

  @override
  String get deleteProject => 'ลบโปรเจกต์';

  @override
  String get noProject => 'ไม่มีโปรเจกต์';

  @override
  String get allTickets => 'ตั๋วงานทั้งหมด';

  @override
  String get projectNamePlaceholder => 'ชื่อโปรเจกต์';

  @override
  String get projectDescriptionPlaceholder => 'คำอธิบาย (ไม่บังคับ)';

  @override
  String get projectColorLabel => 'สี';

  @override
  String get noProjectsYet => 'ยังไม่มีโปรเจกต์';

  @override
  String get projectTicketsEmpty => 'ยังไม่มีตั๋วงานในโปรเจกต์นี้';

  @override
  String get createProject => 'สร้างโปรเจกต์';

  @override
  String projectProgress(int done, int total) {
    return 'เสร็จ $done จาก $total';
  }

  @override
  String deleteProjectConfirm(String name) {
    return 'ลบ \"$name\" หรือไม่? ตั๋วงานจะถูกเก็บไว้และนำออกจากโปรเจกต์';
  }

  @override
  String get projectStatusActive => 'ใช้งานอยู่';

  @override
  String get projectStatusCompleted => 'เสร็จแล้ว';

  @override
  String get projectStatusArchived => 'เก็บถาวรแล้ว';

  @override
  String get markProjectCompleted => 'ทำเครื่องหมายว่าเสร็จ';

  @override
  String get markProjectActive => 'ทำเครื่องหมายว่าใช้งาน';

  @override
  String get archiveProject => 'เก็บถาวร';

  @override
  String get restoreProject => 'กู้คืน';

  @override
  String get relations => 'ความสัมพันธ์';

  @override
  String get relateTo => 'เชื่อมโยงกับ';

  @override
  String get relationSubIssueOf => 'ประเด็นย่อยของ…';

  @override
  String get relationParentOf => 'แม่ของ…';

  @override
  String get relationBlockedBy => 'ถูกบล็อกโดย…';

  @override
  String get relationBlocking => 'กำลังบล็อก…';

  @override
  String get relationRelatedTo => 'เกี่ยวข้องกับ…';

  @override
  String get relationDuplicateOf => 'ซ้ำกับ…';

  @override
  String get relationGroupParent => 'แม่';

  @override
  String get relationGroupSubIssues => 'ประเด็นย่อย';

  @override
  String get relationGroupBlockedBy => 'ถูกบล็อกโดย';

  @override
  String get relationGroupBlocking => 'กำลังบล็อก';

  @override
  String get relationGroupRelated => 'เกี่ยวข้อง';

  @override
  String get relationGroupDuplicateOf => 'ซ้ำกับ';

  @override
  String get relationGroupDuplicatedBy => 'ถูกทำซ้ำโดย';

  @override
  String get copyId => 'คัดลอก ID';

  @override
  String get ticketIdCopied => 'คัดลอก ID ตั๋วงานแล้ว';

  @override
  String get searchTicketsHint => 'ค้นหาตั๋วงาน…';

  @override
  String get noMatchingTickets => 'ไม่มีตั๋วงานที่ตรง';

  @override
  String get clearAll => 'ล้างทั้งหมด';

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs PR',
      one: '1 PR',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos รีโพสิทอรี',
      one: '1 รีโพสิทอรี',
    );
    return '$_temp0 รอการรีวิวของคุณใน $_temp1';
  }

  @override
  String get manageWorkspacesSubtitle =>
      'เปลี่ยนชื่อเวิร์กสเปซและเปลี่ยนเครื่องหมาย — เลือกด้านซ้ายเพื่อแก้ไข';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count เวิร์กสเปซ',
      one: '1 เวิร์กสเปซ',
      zero: 'ไม่มีเวิร์กสเปซ',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos รีโพสิทอรี',
      one: '1 รีโพสิทอรี',
      zero: 'ไม่มีรีโพสิทอรี',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents เอเจนต์',
      one: '1 เอเจนต์',
      zero: '0 เอเจนต์',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'ตัวตน';

  @override
  String get uploadImage => 'อัปโหลดรูป';

  @override
  String get failedToSaveLogo =>
      'บันทึกรูปโลโก้ไม่สำเร็จ ตรวจว่าแอปอ่านไฟล์ที่เลือกได้';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG หรือ GIF สูงสุด 2 MB ไม่เช่นนั้นจะใช้ตัวอักษรแรกของเวิร์กสเปซ';

  @override
  String get workspaceNameFieldHelp => 'แสดงในตัวสลับ เบรดครัมบ์ และทุกหน้าจอ';

  @override
  String get dangerZone => 'โซนอันตราย';

  @override
  String get deleteThisWorkspace => 'ลบเวิร์กสเปซนี้';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return 'ลบ $name การเชื่อมต่อรีโพสิทอรี เอเจนต์ และหน่วยความจำอย่างถาวร เลิกทำไม่ได้';
  }

  @override
  String get discard => 'ทิ้ง';

  @override
  String discardChangesQuestion(String name) {
    return 'ทิ้งการเปลี่ยนแปลงที่ยังไม่บันทึกของ $name หรือไม่?';
  }

  @override
  String get workspaceUpdated => 'อัปเดตเวิร์กสเปซแล้ว';

  @override
  String get editTitle => 'แก้ไขชื่อ';

  @override
  String get editDescription => 'แก้ไขคำอธิบาย';

  @override
  String get addDescription => 'เพิ่มคำอธิบาย';

  @override
  String get prTitlePlaceholder => 'ชื่อเรื่อง';

  @override
  String get prBodyPlaceholder => 'ใส่คำอธิบาย';

  @override
  String get write => 'เขียน';

  @override
  String get overview => 'ภาพรวม';

  @override
  String get noFilesChanged => 'ไม่มีไฟล์ที่เปลี่ยน';

  @override
  String get diff => 'Diff';

  @override
  String get preview => 'ตัวอย่าง';

  @override
  String get imageDiffBefore => 'ก่อน';

  @override
  String get imageDiffAfter => 'หลัง';

  @override
  String get imageDiffModeTwoUp => 'เทียบคู่';

  @override
  String get imageDiffModeSwipe => 'ปัด';

  @override
  String get imageDiffModeDifference => 'ส่วนต่าง';

  @override
  String imageDiffChangedPercent(String percent) {
    return 'เปลี่ยน $percent%';
  }

  @override
  String get imageDiffPictures => 'รูปภาพ';

  @override
  String get imageDiffSource => 'ต้นฉบับ';

  @override
  String get imageDiffDeleted => 'ลบแล้ว';

  @override
  String get imageDiffAdded => 'เพิ่มแล้ว';

  @override
  String imageDiffDimensions(int width, int height) {
    return 'ก: ${width}px | ส: ${height}px';
  }

  @override
  String get outdated => 'ล้าสมัย';

  @override
  String get outdatedComments => 'ความคิดเห็นที่ล้าสมัย';

  @override
  String outdatedCountLabel(int count) {
    return 'ล้าสมัย $count';
  }

  @override
  String get prTemplateLabel => 'เทมเพลต';

  @override
  String get prTemplateDefault => 'ค่าเริ่มต้น';

  @override
  String get addReviewers => 'เพิ่มผู้รีวิว';

  @override
  String get addAssignees => 'เพิ่มผู้รับมอบหมาย';

  @override
  String get addLabels => 'เพิ่มป้ายกำกับ';

  @override
  String get searchLabels => 'ค้นหาป้ายกำกับ…';

  @override
  String get noMatchingLabels => 'ไม่มีป้ายกำกับที่ตรงกัน';

  @override
  String removeLabel(String label) {
    return 'นำ $label ออก';
  }

  @override
  String get searchUsers => 'ค้นหาคน…';

  @override
  String get searchReviewers => 'ค้นหาคนและทีม…';

  @override
  String get usersSectionLabel => 'คน';

  @override
  String get userStatusBusy => 'ไม่ว่าง';

  @override
  String get teamsSectionLabel => 'ทีม';

  @override
  String get suggestedReviewers => 'ผู้รีวิวที่แนะนำ';

  @override
  String get noMatchingUsers => 'ไม่มีคนที่ตรง';

  @override
  String get noMatchingReviewers => 'ไม่พบรายการ';

  @override
  String get requiredByCodeOwners => 'จำเป็นตาม code owners';

  @override
  String reviewedOnBehalfOf(String login) {
    return 'ผ่าน $login';
  }

  @override
  String get team => 'ทีม';

  @override
  String get markdownBold => 'ตัวหนา';

  @override
  String get markdownItalic => 'ตัวเอียง';

  @override
  String get markdownHeading => 'หัวเรื่อง';

  @override
  String get markdownBulletList => 'รายการหัวข้อย่อย';

  @override
  String get markdownChecklist => 'รายการตรวจ';

  @override
  String get markdownCode => 'โค้ด';

  @override
  String get markdownLink => 'ลิงก์';

  @override
  String get markdownQuote => 'คำพูด';

  @override
  String get markdownSupported => 'รองรับ Markdown';

  @override
  String get markdownAttachImages => 'คลิกเพื่อเพิ่มรูป';

  @override
  String failedToUpdateTitle(String error) {
    return 'อัปเดตชื่อไม่ได้: $error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'อัปเดตคำอธิบายไม่ได้: $error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'อัปเดตผู้รีวิวไม่ได้: $error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'อัปเดตผู้รับมอบหมายไม่ได้: $error';
  }

  @override
  String failedToUpdateLabels(String error) {
    return 'อัปเดตป้ายกำกับไม่สำเร็จ: $error';
  }

  @override
  String get discardChangesConfirm => 'ทิ้งการเปลี่ยนแปลงหรือไม่?';

  @override
  String get newPr => 'PR ใหม่';

  @override
  String get openPullRequest => 'เปิด pull request';

  @override
  String get composePrSubtitle =>
      'จากสาขาที่คุณพุชแล้ว — ไม่มีเอเจนต์หรือตั๋วงานเกี่ยวข้อง';

  @override
  String get createAsDraft => 'สร้างเป็นฉบับร่าง';

  @override
  String get composePrNoRepo => 'ยังไม่ได้เลือกรีโพสิทอรี GitHub';

  @override
  String get composePrNoRepoHint =>
      'เลือกเวิร์กสเปซที่มีรีโพสิทอรีลิงก์ GitHub เพื่อเปิด pull request';

  @override
  String get composePrPickBranches =>
      'เลือกสาขาฐานและสาขาเปรียบเทียบเพื่อดูตัวอย่างการเปลี่ยนแปลง';

  @override
  String get composePrNothingToCompare =>
      'ไม่มีการเปลี่ยนแปลงระหว่างสาขาเหล่านี้';

  @override
  String get repository => 'รีโพสิทอรี';

  @override
  String get baseBranchLabel => 'ฐาน';

  @override
  String get compareBranchLabel => 'เปรียบเทียบ';

  @override
  String get selectBranch => 'เลือกสาขา';

  @override
  String get navMeetings => 'การประชุม';

  @override
  String get meetingsNoWorkspace => 'เลือกเวิร์กสเปซเพื่อดูการประชุม';

  @override
  String get meetingsEmpty => 'ยังไม่มีการประชุม';

  @override
  String get meetingsEmptyHint =>
      'บันทึกการประชุมครั้งแรก — เสียงอยู่บนอุปกรณ์นี้ และเอเจนต์จะแปลงเป็นโน้ต การตัดสินใจ และรายการดำเนินการ';

  @override
  String get meetingNotesHint => 'จดโน้ตสั้นๆ — เอเจนต์จะขยายหลังการประชุม';

  @override
  String get meetingSpeakerMe => 'คุณ';

  @override
  String get meetingStatusRecording => 'กำลังบันทึก';

  @override
  String get meetingStatusProcessing => 'กำลังประมวลผล';

  @override
  String get meetingStatusDone => 'เสร็จแล้ว';

  @override
  String get meetingStatusFailed => 'ล้มเหลว';

  @override
  String get meetingsSubtitle =>
      'บันทึกและถอดเสียงบนอุปกรณ์นี้ แล้วสรุปโดยเอเจนต์';

  @override
  String get meetingsRecordMeeting => 'บันทึกการประชุม';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'กำลังประมวลผล $count รายการ',
      one: 'กำลังประมวลผล 1 รายการ',
    );
    return '$_temp0';
  }

  @override
  String meetingsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count การประชุม',
      one: '1 การประชุม',
      zero: 'ไม่มีการประชุม',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLedgerOpenActions => 'การดำเนินการที่เปิด';

  @override
  String get meetingsLedgerDecisions => 'การตัดสินใจ';

  @override
  String get meetingsLiveOpen => 'เปิดการบันทึก';

  @override
  String get meetingTemplateShort => 'เทมเพลต';

  @override
  String get meetingsStatThisWeek => 'สัปดาห์นี้';

  @override
  String get meetingsStatRecorded => 'บันทึกแล้ว';

  @override
  String get meetingsFilterAll => 'ทั้งหมด';

  @override
  String get meetingsFilterDone => 'เสร็จแล้ว';

  @override
  String get meetingsFilterProcessing => 'กำลังประมวลผล';

  @override
  String get meetingsSearchHint => 'กรองตามชื่อ คน แอป…';

  @override
  String get meetingsBucketToday => 'วันนี้';

  @override
  String get meetingsBucketYesterday => 'เมื่อวาน';

  @override
  String get meetingsBucketEarlierThisWeek => 'ต้นสัปดาห์นี้';

  @override
  String get meetingsBucketLastWeek => 'สัปดาห์ที่แล้ว';

  @override
  String get meetingsBucketOlder => 'เก่ากว่านั้น';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count การตัดสินใจ',
      one: '1 การตัดสินใจ',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return 'รายการดำเนินการ $done / $total';
  }

  @override
  String get meetingsEnhancedPill => 'เสริมแล้ว';

  @override
  String get meetingsTranscribing => 'กำลังถอดเสียงและสรุป…';

  @override
  String get meetingsOpenAction => 'เปิด';

  @override
  String get meetingsStopProcessing => 'หยุด';

  @override
  String get meetingsStillTranscribing =>
      'ยังถอดเสียงอยู่ — สรุปจะปรากฏเมื่อเสร็จ';

  @override
  String get meetingsNoMatch => 'ไม่มีการประชุมที่ตรง';

  @override
  String get meetingsNoMatchHint => 'ลองตัวกรองหรือคำค้นอื่น';

  @override
  String get meetingBackAllMeetings => 'การประชุมทั้งหมด';

  @override
  String get meetingReRunSummary => 'รันสรุปใหม่';

  @override
  String get meetingExport => 'ส่งออก';

  @override
  String get meetingAugmentingBanner =>
      'กำลังเสริมโน้ตจากทรานสคริปต์ — ดึงการตัดสินใจและรายการดำเนินการ…';

  @override
  String get meetingTabNotes => 'โน้ต';

  @override
  String get meetingTabTranscript => 'ทรานสคริปต์';

  @override
  String get meetingTabActionItems => 'รายการดำเนินการ';

  @override
  String get meetingTabDecisions => 'การตัดสินใจ';

  @override
  String get meetingNotesEnhancedToggle => 'เสริมแล้ว';

  @override
  String get meetingNotesYoursToggle => 'โน้ตของคุณ';

  @override
  String get meetingEnhancedByAgent => 'เสริมโดยเอเจนต์ · จากทรานสคริปต์';

  @override
  String get meetingEnhancedPending => 'เอเจนต์ยังทำงานกับสรุปนี้อยู่';

  @override
  String get meetingNotesEmpty => 'ยังไม่มีโน้ตที่เสริม';

  @override
  String get meetingNotesSavedLocally => 'บันทึกในเครื่องแล้ว';

  @override
  String get meetingNotesSaving => 'กำลังบันทึก…';

  @override
  String get meetingViewFullTranscript => 'ดูทรานสคริปต์เต็ม';

  @override
  String get meetingTranscriptSearchHint => 'ค้นหาทรานสคริปต์…';

  @override
  String get meetingSpeakerEveryone => 'ทุกคน';

  @override
  String get meetingSpeakerOthers => 'คนอื่น';

  @override
  String get meetingTranscriptEmpty => 'ยังไม่มีทรานสคริปต์';

  @override
  String get meetingActionItemsEmpty => 'ไม่ได้ดึงรายการดำเนินการ';

  @override
  String get meetingActionItemFrom => 'จากการประชุมนี้';

  @override
  String get meetingCreateTicket => 'สร้างตั๋วงาน';

  @override
  String meetingTicketCreated(String key) {
    return 'สร้างตั๋วงาน $key และจัดส่งแล้ว';
  }

  @override
  String get meetingTicketFailed => 'สร้างตั๋วงานไม่ได้';

  @override
  String get meetingDecisionsEmpty => 'ไม่มีการตัดสินใจที่บันทึก';

  @override
  String get meetingEditTitle => 'แก้ไขชื่อ';

  @override
  String get meetingTitleLabel => 'ชื่อเรื่อง';

  @override
  String get meetingAddActionItem => 'เพิ่มรายการดำเนินการ';

  @override
  String get meetingEditActionItem => 'แก้ไขรายการดำเนินการ';

  @override
  String get meetingDeleteActionItem => 'ลบรายการดำเนินการ';

  @override
  String get meetingActionItemContentLabel => 'รายการดำเนินการ';

  @override
  String get meetingActionItemContentHint => 'ต้องเกิดอะไรขึ้น?';

  @override
  String get meetingActionItemOwnerLabel => 'เจ้าของ';

  @override
  String get meetingActionItemOwnerHint => 'ใครรับผิดชอบ? (ไม่บังคับ)';

  @override
  String get meetingAddDecision => 'เพิ่มการตัดสินใจ';

  @override
  String get meetingEditDecision => 'แก้ไขการตัดสินใจ';

  @override
  String get meetingDeleteDecision => 'ลบการตัดสินใจ';

  @override
  String get meetingDecisionContentLabel => 'การตัดสินใจ';

  @override
  String get meetingDecisionContentHint => 'ตัดสินใจอะไร?';

  @override
  String get meetingReRunStarted => 'กำลังรันตัวสรุปบนทรานสคริปต์อีกครั้ง…';

  @override
  String get meetingReRunNoTranscript => 'ยังไม่มีทรานสคริปต์ให้สรุป';

  @override
  String get meetingExportCopied => 'คัดลอกโน้ตไปคลิปบอร์ดเป็น Markdown แล้ว';

  @override
  String get meetingExportSaved => 'ส่งออกการประชุมแล้ว';

  @override
  String meetingExportFailed(String error) {
    return 'ส่งออกไม่สำเร็จ: $error';
  }

  @override
  String get meetingExportNothing => 'ยังไม่มีอะไรให้ส่งออก';

  @override
  String get meetingPlaybackPlay => 'เล่น';

  @override
  String get meetingPlaybackPause => 'หยุดชั่วคราว';

  @override
  String get meetingPlaybackUnavailable => 'เล่นเสียงไม่ได้บนอุปกรณ์นี้';

  @override
  String get meetingDetectedTitle => 'ตรวจพบการประชุม';

  @override
  String meetingDetectedSubtitle(String label) {
    return 'ดูเหมือน \"$label\" กำลังเกิดขึ้น บันทึกหรือไม่?';
  }

  @override
  String get meetingDetectedSubtitleGeneric =>
      'ดูเหมือนมีการประชุมเกิดขึ้น บันทึกหรือไม่?';

  @override
  String get meetingDetectedRecord => 'บันทึก';

  @override
  String get meetingDetectedDismiss => 'ปิดทิ้ง';

  @override
  String get meetingAutoStopTitle =>
      'ดูเหมือนการประชุมจบแล้ว หยุดบันทึกหรือไม่?';

  @override
  String get meetingAutoStopStop => 'หยุด';

  @override
  String get meetingAutoStopKeep => 'บันทึกต่อไป';

  @override
  String get meetingAutoDetect => 'ตรวจจับการประชุมอัตโนมัติ';

  @override
  String get meetingAutoDetectDescription =>
      'ดูปฏิทินและแอปประชุม แล้วเสนอให้บันทึกเมื่อการประชุมเริ่ม';

  @override
  String get meetingsRecordingCrumb => 'กำลังบันทึก…';

  @override
  String get meetingRecordTitleHint => 'ชื่อการประชุม';

  @override
  String get meetingRecordTappingLabel => 'กำลังแตะ:';

  @override
  String get meetingRecordMic => 'ไมค์';

  @override
  String get meetingRecordSystemAudio => 'เสียงระบบ';

  @override
  String get meetingRecordPause => 'หยุดชั่วคราว';

  @override
  String get meetingRecordResume => 'ทำต่อ';

  @override
  String get meetingRecordStop => 'หยุดและสรุป';

  @override
  String get meetingRecordYourNotes => 'โน้ตของคุณ';

  @override
  String get meetingRecordNotesPlaceholder =>
      'พิมพ์ขณะฟัง เศษข้อความไม่กี่อย่างก็พอ — หลังหยุด เอเจนต์จะขยายโดยใช้ทรานสคริปต์';

  @override
  String get meetingRecordLiveTranscript => 'ทรานสคริปต์สด';

  @override
  String get meetingRecordDecoding => 'ถอดรหัสบนอุปกรณ์';

  @override
  String get meetingRecordListening =>
      'กำลังฟัง… คำพูดจะปรากฏที่นี่ในหนึ่งหรือสองวินาที ติดแท็ก คุณ / คนอื่น';

  @override
  String get meetingRecordPausedHint =>
      'หยุดชั่วคราว — ไม่สนใจเสียงจนกว่าคุณจะทำต่อ';

  @override
  String get meetingRecordNotActive => 'ไม่มีการบันทึกที่ใช้งาน';

  @override
  String get meetingHudRecording => 'กำลังบันทึก';

  @override
  String get meetingHudPaused => 'หยุดชั่วคราว';

  @override
  String get meetingHudOpen => 'เปิด';

  @override
  String get meetingHudStop => 'หยุด';

  @override
  String get meetingToolbarPopOut => 'แยกหน้าต่าง';

  @override
  String get meetingToolbarHoldToStop => 'กดค้างเพื่อหยุดบันทึก';

  @override
  String get meetingToolbarSemanticLabel => 'แถบเครื่องมือบันทึกการประชุม';

  @override
  String get orchestrate => 'ประสานงาน';

  @override
  String get orchestrationUnavailable => 'การประสานงานใช้ไม่ได้';

  @override
  String get orchestrationApprove => 'อนุมัติแผน';

  @override
  String get orchestrationReject => 'ปฏิเสธ';

  @override
  String get orchestrationCancel => 'ยกเลิกการประสานงาน';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count บทบาท — พนักงานใหม่ $hires';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return 'ตั๋วงานย่อย $count';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'ค่าใช้จ่ายโดยประมาณ: \$$amount';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return 'ตั๋วงานย่อยเสร็จ $done/$total';
  }

  @override
  String get orchestrationStatusProposed => 'เสนอแล้ว';

  @override
  String get orchestrationStatusApproved => 'อนุมัติแล้ว';

  @override
  String get orchestrationStatusExecuting => 'กำลังดำเนินการ';

  @override
  String get orchestrationStatusSynthesizing => 'กำลังสังเคราะห์';

  @override
  String get orchestrationStatusCompleted => 'เสร็จแล้ว';

  @override
  String get orchestrationStatusFailed => 'ล้มเหลว';

  @override
  String get orchestrationStatusCancelled => 'ยกเลิกแล้ว';

  @override
  String get messageFailed => 'รันล้มเหลว';

  @override
  String get turnLimitReached => 'หยุดที่ขีดจำกัดเทิร์น — ตอบกลับเพื่อทำต่อ';

  @override
  String get retried => 'ลองใหม่แล้ว';

  @override
  String replyingTo(String name) {
    return 'กำลังตอบ $name';
  }

  @override
  String get silenceTimeoutLabel => 'หมดเวลาเงียบ (นาที)';

  @override
  String get silenceTimeoutHint =>
      'เช่น 15 — จบรันหลังจากไม่มีเอาต์พุตนานเท่านี้';

  @override
  String get capabilityJsonMode => 'โหมด JSON';

  @override
  String get capabilityModelSelection => 'การเลือกโมเดล';

  @override
  String get transcriptThinking => 'กำลังคิด…';

  @override
  String transcriptThoughtFor(String duration) {
    return 'คิดไป $duration';
  }

  @override
  String get transcriptStatusMakingEdits => 'กำลังแก้ไข…';

  @override
  String get transcriptStatusReadingFiles => 'กำลังอ่านไฟล์…';

  @override
  String get transcriptStatusSearching => 'กำลังค้นหาโค้ดเบส…';

  @override
  String get transcriptStatusRunningCommands => 'กำลังรันคำสั่ง…';

  @override
  String get transcriptStatusResponding => 'กำลังตอบ…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return 'กำลังรัน $tool…';
  }

  @override
  String get transcriptInput => 'อินพุต';

  @override
  String get transcriptOutput => 'เอาต์พุต';

  @override
  String get transcriptErrorLabel => 'ข้อผิดพลาด';

  @override
  String get transcriptSandboxBlocked => 'แซนด์บ็อกซ์บล็อกการกระทำ';

  @override
  String transcriptShowFullOutput(int kb) {
    return 'แสดงเอาต์พุตเต็ม (+$kb KB)';
  }

  @override
  String transcriptShowAllLines(int count) {
    return 'แสดงทั้ง $count บรรทัด';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return 'แสดง $count บรรทัดแรก';
  }

  @override
  String get transcriptGrepNoMatches => 'ไม่พบรายการ';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '$matches รายการ',
      one: '1 รายการ',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files ไฟล์',
      one: '1 ไฟล์',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return 'บุคคล $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => 'เปลี่ยนชื่อผู้พูด';

  @override
  String get meetingRenameSpeakerTitle => 'เปลี่ยนชื่อผู้พูด';

  @override
  String get meetingSpeakerNameLabel => 'ชื่อ';

  @override
  String get meetingSpeakerSuggestFromCalendar =>
      'จากผู้ถูกเชิญของการประชุมนี้';

  @override
  String get meetingRenameSpeakerApplyAll => 'ใช้กับทุกบล็อกจากผู้พูดนี้';

  @override
  String get meetingRenameSpeakerScopeHint =>
      'เมื่อปิด จะเปลี่ยนชื่อเฉพาะบรรทัดที่เลือก';

  @override
  String get meetingLinkEvent => 'ลิงก์กับเหตุการณ์';

  @override
  String get meetingChangeEvent => 'เปลี่ยนเหตุการณ์';

  @override
  String get meetingLinkEventTitle => 'ลิงก์กับเหตุการณ์ปฏิทิน';

  @override
  String get meetingLinkEventSearchHint => 'ค้นหาเหตุการณ์';

  @override
  String get meetingLinkEventEmpty => 'ไม่มีเหตุการณ์ปฏิทินใกล้เคียง';

  @override
  String get meetingUnlinkEvent => 'ลบลิงก์';

  @override
  String get calendarLinkExistingMeeting => 'ลิงก์กับการประชุมที่มีอยู่';

  @override
  String get calendarLinkMeetingTitle => 'ลิงก์การประชุม';

  @override
  String get calendarLinkMeetingSearchHint => 'ค้นหาการประชุม';

  @override
  String get calendarLinkMeetingEmpty => 'ไม่มีการประชุมให้ลิงก์';

  @override
  String get meetingRenameSpeakerFailed => 'เปลี่ยนชื่อผู้พูดไม่ได้';

  @override
  String get calendarLinkUpdateFailed => 'อัปเดตลิงก์ปฏิทินไม่ได้';

  @override
  String get rename => 'เปลี่ยนชื่อ';

  @override
  String get notNow => 'ไม่ใช่ตอนนี้';

  @override
  String get meetingSaveVoiceProfileTitle => 'บันทึกโปรไฟล์เสียงหรือไม่?';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return 'จดจำ $name อัตโนมัติในการประชุมครั้งหน้าโดยบันทึกลายเสียง';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return 'บันทึกโปรไฟล์เสียงของ $name แล้ว';
  }

  @override
  String get meetingVoiceProfileSaveFailed => 'บันทึกโปรไฟล์เสียงไม่ได้';

  @override
  String get voiceProfilesSection => 'โปรไฟล์เสียง';

  @override
  String get voiceProfilesDescription =>
      'เสียงที่บันทึกจะถูกจดจำอัตโนมัติในการประชุมครั้งหน้า';

  @override
  String get voiceProfilesEmpty =>
      'ยังไม่มีเสียงที่บันทึก ตั้งชื่อผู้พูดในทรานสคริปต์การประชุม แล้วเลือก \"บันทึกโปรไฟล์เสียง\"';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ตัวอย่าง',
      one: '1 ตัวอย่าง',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => 'เปลี่ยนชื่อโปรไฟล์เสียง';

  @override
  String get deleteVoiceProfileTitle => 'ลบโปรไฟล์เสียงหรือไม่?';

  @override
  String deleteVoiceProfileBody(String name) {
    return 'หยุดจดจำ $name หรือไม่? ลายเสียงที่บันทึกจะถูกลบ ชื่อที่ใช้แล้วในการประชุมที่ผ่านมาจะถูกเก็บไว้';
  }

  @override
  String get connectedLabel => 'เชื่อมต่อแล้ว';

  @override
  String get ideTabGeneral => 'ทั่วไป';

  @override
  String get ideTabExplorer => 'ตัวสำรวจ';

  @override
  String get ideTabSourceControl => 'การควบคุมซอร์ส';

  @override
  String get generalSectionTodos => 'สิ่งที่ต้องทำ';

  @override
  String get generalSectionGoals => 'เป้าหมาย';

  @override
  String get goalRunStatusActive => 'ใช้งานอยู่';

  @override
  String get goalRunStatusPaused => 'หยุดชั่วคราว';

  @override
  String get goalRunStatusCompleted => 'เสร็จแล้ว';

  @override
  String get goalRunStatusFailed => 'ล้มเหลว';

  @override
  String get goalRunStatusCancelled => 'ยกเลิกแล้ว';

  @override
  String get goalRunStatusBudgetExhausted => 'งบประมาณหมด';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return 'รัน $run จาก $max · $cost จาก $cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return 'รัน $run · $cost จาก $cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return 'ครบกำหนด $deadline';
  }

  @override
  String get goalRunPause => 'หยุดเป้าหมายชั่วคราว';

  @override
  String get goalRunResume => 'ทำเป้าหมายต่อ';

  @override
  String goalRunResumeRaise(String cap) {
    return 'ทำต่อ · เพิ่มเพดานเป็น $cap';
  }

  @override
  String get goalRunStop => 'หยุดเป้าหมาย';

  @override
  String get generalSectionAgents => 'เอเจนต์';

  @override
  String get generalSectionTerminals => 'เทอร์มินัล';

  @override
  String get generalTodosEmpty => 'ยังไม่มีสิ่งที่ต้องทำ';

  @override
  String get generalAgentsEmpty => 'ไม่มีเอเจนต์ที่กำลังรัน';

  @override
  String get generalTerminalsEmpty => 'ไม่มีเทอร์มินัลที่เปิด';

  @override
  String get generalSectionBrowsers => 'เบราว์เซอร์';

  @override
  String get generalSectionComputers => 'คอมพิวเตอร์';

  @override
  String get generalBrowsersEmpty => 'ไม่มีเบราว์เซอร์ที่เปิด';

  @override
  String get generalComputersEmpty => 'ไม่มีคอมพิวเตอร์ที่เปิด';

  @override
  String get generalSectionPhones => 'โทรศัพท์';

  @override
  String get generalPhonesEmpty => 'ไม่มีโทรศัพท์ที่เปิด';

  @override
  String get pauseAgent => 'หยุดเอเจนต์ชั่วคราว';

  @override
  String get resumeAgent => 'ทำเอเจนต์ต่อ';

  @override
  String get agentCannotPause => 'เอเจนต์นี้หยุดชั่วคราวไม่ได้ — หยุดแทน';

  @override
  String get goalClear => 'ล้างเป้าหมาย';

  @override
  String get undoLabelGoalClear => 'ล้างเป้าหมาย';

  @override
  String get todoStatusPending => 'ยังไม่เริ่ม';

  @override
  String get todoStatusInProgress => 'กำลังดำเนินการ';

  @override
  String get todoStatusCompleted => 'เสร็จแล้ว';

  @override
  String get reorderTodo => 'จัดลำดับสิ่งที่ต้องทำ';

  @override
  String get focusTerminal => 'โฟกัสเทอร์มินัล';

  @override
  String get focusMachine => 'โฟกัสเครื่อง';

  @override
  String get focusBrowser => 'โฟกัสเบราว์เซอร์';

  @override
  String get todoEditorTitle => 'แก้ไขสิ่งที่ต้องทำ';

  @override
  String get todoEditorHint =>
      'รายการละหนึ่งบรรทัด ใช้ - [ ] สำหรับยังไม่เริ่ม, - [~] สำหรับกำลังทำ, - [x] สำหรับเสร็จ';

  @override
  String get todoNeedsText => 'เพิ่มข้อความหลังคำสั่ง';

  @override
  String get todoNotFound => 'ไม่มีสิ่งที่ต้องทำที่ตรง';

  @override
  String get todoCleared => 'ล้างรายการสิ่งที่ต้องทำแล้ว';

  @override
  String get todoNothingToCopy => 'ไม่มีอะไรให้คัดลอก';

  @override
  String todoAdded(String content) {
    return 'เพิ่ม \"$content\" แล้ว';
  }

  @override
  String todoStarted(String content) {
    return 'เริ่ม \"$content\" แล้ว';
  }

  @override
  String todoCompleted(String content) {
    return 'ทำ \"$content\" เสร็จแล้ว';
  }

  @override
  String todoRemoved(String content) {
    return 'นำ \"$content\" ออกแล้ว';
  }

  @override
  String todoCopied(int count) {
    return 'คัดลอก $count รายการ';
  }

  @override
  String todoImported(int count) {
    return 'นำเข้า $count รายการ';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return 'ไม่รู้จักคำสั่ง todo \"$name\"';
  }

  @override
  String get terminal => 'เทอร์มินัล';

  @override
  String get ideCloseTab => 'ปิดแท็บ';

  @override
  String get ideSplitEditor => 'แยกตัวแก้ไข';

  @override
  String get ideSplitRight => 'แยกไปทางขวา';

  @override
  String get ideSplitDown => 'แยกลงล่าง';

  @override
  String get ideSplitLeft => 'แยกไปทางซ้าย';

  @override
  String get ideSplitUp => 'แยกขึ้นบน';

  @override
  String get ideCloseGroup => 'ปิดกลุ่ม';

  @override
  String get ideCloseOthers => 'ปิดอันอื่น';

  @override
  String get ideCloseToRight => 'ปิดทางขวา';

  @override
  String get ideCloseSaved => 'ปิดที่บันทึกแล้ว';

  @override
  String get ideCloseAll => 'ปิดทั้งหมด';

  @override
  String get ideSplit => 'แยก';

  @override
  String get ideToggleSidebar => 'สลับแถบข้าง';

  @override
  String get ideNewTab => 'เปิดตัวแก้ไข';

  @override
  String get ideNewTabMenu => 'แท็บใหม่';

  @override
  String get ideReviewCode => 'รีวิวโค้ด';

  @override
  String ideReviewCodeInRepo(String repo) {
    return 'รีวิวโค้ด ($repo)';
  }

  @override
  String get ideRevertConfirmTitle => 'ย้อนการเปลี่ยนแปลง';

  @override
  String get ideRevertUntracked => 'ไฟล์ที่ยังไม่ติดตามย้อนกลับไม่ได้';

  @override
  String get ideRevertFailed =>
      'ย้อนไฟล์ไม่ได้ worktree ของการสนทนาอาจใช้ไม่ได้';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ไฟล์',
      one: '1 ไฟล์',
    );
    return '$_temp0 ย้อนกลับไม่ได้ (ยังไม่ติดตาม)';
  }

  @override
  String get ideSearchMatchCase => 'ตรงตัวพิมพ์';

  @override
  String get ideSearchWholeWord => 'ทั้งคำ';

  @override
  String get ideSearchRegex => 'Regex';

  @override
  String get ideSearchFilters => 'ตัวกรองการค้นหา';

  @override
  String get ideSearchFilesToInclude => 'ไฟล์ที่จะรวม';

  @override
  String get ideSearchFilesToExclude => 'ไฟล์ที่จะไม่รวม';

  @override
  String get ideNoOpenTabs => 'ไม่มีแท็บที่เปิด — ใช้ + เพื่อเปิด';

  @override
  String get ideBrowserAddressHint => 'ใส่ที่อยู่หรือค้นหา';

  @override
  String get ideSimpleWebBrowser => 'เว็บเบราว์เซอร์อย่างง่าย';

  @override
  String get ideWebBrowser => 'เว็บเบราว์เซอร์';

  @override
  String get ideBrowserEnterUrl => 'ใส่ URL ในแถบที่อยู่เพื่อเริ่มเรียกดู';

  @override
  String get ideCodeServer => 'ตัวแก้ไข';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return 'บันทึกการเปลี่ยนแปลงของ $fileName หรือไม่?';
  }

  @override
  String get ideUnsavedChangesBody => 'การเปลี่ยนแปลงจะหายไปหากไม่บันทึก';

  @override
  String get ideDontSave => 'ไม่บันทึก';

  @override
  String get editorAutoSave => 'บันทึกอัตโนมัติ';

  @override
  String get editorAutoSaveDescription =>
      'บันทึกการเปลี่ยนแปลงในตัวแก้ไขฝังอัตโนมัติ';

  @override
  String get editorAutoSaveOff => 'ปิด';

  @override
  String get editorAutoSaveAfterDelay => 'หลังหน่วงเวลา';

  @override
  String get editorAutoSaveOnFocusChange => 'เมื่อโฟกัสเปลี่ยน';

  @override
  String get ideCodeServerUnavailable =>
      'code-server ใช้ไม่ได้บนเซิร์ฟเวอร์นี้';

  @override
  String get ideCodeServerUnavailableHint =>
      'ติดตั้ง code-server (coder/code-server) บนโฮสต์เซิร์ฟเวอร์ แล้วเปิดตัวแก้ไขใหม่';

  @override
  String get ideCodeServerInstalling => 'กำลังเตรียมตัวแก้ไข…';

  @override
  String get ideCodeServerOpenInBrowser => 'เปิดตัวแก้ไขในเบราว์เซอร์';

  @override
  String get ideCodeServerError => 'เปิดตัวแก้ไขไม่ได้';

  @override
  String get paneSuspendedCaption =>
      'ถูกระงับเพื่อประหยัดทรัพยากร — จะโหลดใหม่เมื่อโฟกัส';

  @override
  String get ideFolderLoadFailed => 'โหลดโฟลเดอร์นี้ไม่ได้';

  @override
  String get ideFileSearchFailed => 'ค้นหาไฟล์ไม่ได้';

  @override
  String get ideSearchInFiles => 'ค้นหาในไฟล์';

  @override
  String get ideNoContentMatches => 'ไม่พบรายการ';

  @override
  String get ideSourceControlCreatePr => 'สร้าง pull request';

  @override
  String ideSourceControlViewPr(int number) {
    return 'ดู pull request #$number';
  }

  @override
  String get ideSourceControlNoChanges => 'ไม่มีการเปลี่ยนแปลง';

  @override
  String get noReposInConversation => 'ไม่มีรีโพสิทอรีในการสนทนานี้';

  @override
  String get ideSourceControlNoSpace => 'เปิดการสนทนาเพื่อดูการเปลี่ยนแปลง';

  @override
  String get ideFileLoading => 'กำลังโหลด…';

  @override
  String get ideFileBinary => 'ไฟล์ไบนารี';

  @override
  String get mcpExternalServers => 'เซิร์ฟเวอร์ MCP ภายนอก';

  @override
  String get mcpExternalServersDescription =>
      'เชื่อมต่อเซิร์ฟเวอร์ MCP ภายนอก (GitHub, Sentry, Postgres, อัตโนมัติเบราว์เซอร์) เซิร์ฟเวอร์ที่คุณตั้งค่าสำหรับ Claude, Cursor, VS Code และเครื่องมืออื่นจะถูกค้นพบอัตโนมัติ';

  @override
  String get mcpApprovalMode => 'การอนุมัติเครื่องมือ';

  @override
  String get mcpApprovalModeDescription =>
      'การกระทำของเครื่องมือใดรันโดยไม่ถาม การอ่านได้รับอนุญาตเสมอ ระดับสูงกว่าจะถาม';

  @override
  String get mcpApprovalAlwaysAsk => 'ถามเสมอ';

  @override
  String get mcpApprovalWrite => 'อนุมัติการเขียนอัตโนมัติ';

  @override
  String get mcpApprovalYolo => 'อนุมัติทั้งหมดอัตโนมัติ';

  @override
  String get mcpNoExternalServers => 'ไม่พบเซิร์ฟเวอร์ MCP ภายนอก';

  @override
  String get mcpAuthorize => 'อนุญาต';

  @override
  String get mcpReconnect => 'เชื่อมต่ออีกครั้ง';

  @override
  String get mcpExternalConnectionsNote =>
      'เซิร์ฟเวอร์ MCP ภายนอกรันบนเซิร์ฟเวอร์เอเจนต์ (แชร์โดยเดสก์ท็อปและเว็บ) การอนุญาตเซิร์ฟเวอร์ OAuth มีเฉพาะบนเดสก์ท็อป';

  @override
  String get mcpStatusConnected => 'เชื่อมต่อแล้ว';

  @override
  String get mcpStatusConnecting => 'กำลังเชื่อมต่อ…';

  @override
  String get mcpStatusNeedsAuth => 'ต้องอนุญาต';

  @override
  String get mcpStatusFailed => 'ล้มเหลว';

  @override
  String get mcpStatusCircuitOpen => 'หยุดชั่วคราว';

  @override
  String get mcpStatusDisabled => 'ปิดใช้';

  @override
  String get providersAndModels => 'ผู้ให้บริการและโมเดล';

  @override
  String get providersAndModelsDescription =>
      'แสดงผู้ให้บริการทุกตัวที่เอเจนต์ในตัวใช้ได้ — ตั้งคีย์ API หรือลงชื่อเข้าใช้ด้วยเบราว์เซอร์ ดูโมเดลและราคาของแต่ละผู้ให้บริการที่เชื่อมต่อ และกำกับว่าเวิร์กสเปซนี้อาจใช้ผู้ให้บริการใด';

  @override
  String get syncNow => 'ซิงค์ตอนนี้';

  @override
  String syncNowResult(int applied, int failed) {
    return 'ซิงค์เสร็จ — ใช้แล้ว $applied ล้มเหลว $failed';
  }

  @override
  String syncNowFailed(String error) {
    return 'ซิงค์ไม่สำเร็จ: $error';
  }

  @override
  String get denied => 'ปฏิเสธแล้ว';

  @override
  String get allowed => 'อนุญาตแล้ว';

  @override
  String allowProviderSemantic(String provider) {
    return 'อนุญาต $provider';
  }

  @override
  String enabledViaEnv(String key) {
    return 'เปิดใช้ผ่าน $key';
  }

  @override
  String costPerMillion(String input, String output) {
    return '$input / $output ต่อ 1M';
  }

  @override
  String contextTokens(String tokens) {
    return 'บริบท $tokens';
  }

  @override
  String get usageAndCost => 'การใช้งานและค่าใช้จ่าย';

  @override
  String get usageAndCostDescription =>
      'การใช้จ่ายของเอเจนต์ในช่วง 7 วันที่ผ่านมา จากค่าใช้จ่ายรันที่สังเกตได้';

  @override
  String get noUsageYet => 'ยังไม่มีการใช้งานที่บันทึก';

  @override
  String get spentThisWeek => 'ใช้จ่ายสัปดาห์นี้';

  @override
  String get subscriptionUsage => 'การใช้งานการสมัคร';

  @override
  String get subscriptionUsageUnavailable => 'ไม่พร้อมใช้';

  @override
  String get subscriptionUsageExhausted => 'โควตาหมด';

  @override
  String get subscriptionUsageSignInRequired => 'ลงชื่อเข้าใช้อีกครั้ง';

  @override
  String get subscriptionUsageSignInExpired =>
      'การลงชื่อเข้าใช้หมดอายุ จะต่อเมื่อรันครั้งหน้า';

  @override
  String get subscriptionUsagePartiallyAvailable => 'พร้อมใช้บางส่วน';

  @override
  String resetsIn(String duration) {
    return 'รีเซ็ตใน $duration';
  }

  @override
  String get feedbackHelpful => 'มีประโยชน์';

  @override
  String get feedbackNotHelpful => 'ไม่มีประโยชน์';

  @override
  String get modeChat => 'แชท';

  @override
  String get modePlan => 'แผน';

  @override
  String get modeReview => 'รีวิว';

  @override
  String get modeOrchestrate => 'ประสานงาน';

  @override
  String get editorTheme => 'ธีมตัวแก้ไข';

  @override
  String get editorThemeDescription =>
      'นำเข้าธีมสี VS Code เพื่อให้ diff และตัวแก้ไขฝังตรงกับ IDE ของคุณ';

  @override
  String get editorThemePasteHint => 'วางเนื้อหาไฟล์ JSON ธีมสี VS Code';

  @override
  String get editorThemeImported => 'นำเข้าธีมแล้ว';

  @override
  String get editorThemeInvalid => 'นี่ไม่เหมือนธีม VS Code ที่ถูกต้อง';

  @override
  String get importTheme => 'นำเข้าธีม';

  @override
  String get clearTheme => 'ล้างธีม';

  @override
  String get openInDiffViewer => 'เปิดในตัวดู diff';

  @override
  String get shellCommand => 'คำสั่ง';

  @override
  String get shellOutput => 'เอาต์พุต';

  @override
  String get revertToHere => 'ย้อนกลับมาที่นี่';

  @override
  String get revertConfirmBody =>
      'ซ่อนข้อความหลังจุดนี้และย้อนการเปลี่ยนแปลงไฟล์ของเอเจนต์กลับเทิร์นนี้หรือไม่? คุณเลิกทำได้';

  @override
  String get revert => 'ย้อนกลับ';

  @override
  String get revertedToHere => 'ย้อนกลับมาที่นี่แล้ว';

  @override
  String get nothingToRevert => 'ไม่มีอะไรให้ย้อน';

  @override
  String get undoRevert => 'เลิกย้อน';

  @override
  String get revertUndone => 'เลิกย้อนแล้ว';

  @override
  String get systemBehavior => 'พฤติกรรมระบบ';

  @override
  String get keepAwakeTitle => 'ไม่ให้คอมพิวเตอร์หลับขณะเอเจนต์รัน';

  @override
  String get keepAwakeOnSubtitle => 'คอมพิวเตอร์จะไม่หลับขณะเอเจนต์ทำงาน';

  @override
  String get keepAwakeOffSubtitle =>
      'คอมพิวเตอร์อาจหลับได้แม้เอเจนต์กำลังทำงาน';

  @override
  String get syncEngineSectionTitle => 'เอนจินซิงค์';

  @override
  String get syncEngineDescription =>
      'ตั๋วงาน ข้อความ และโน้ตอัปเดตแบบสดผ่านการเปลี่ยนแปลงเล็กๆ แทนสแนปช็อตเต็ม ปิดสวิตช์จะให้คลังนั้นถอยไปโหมดสแนปช็อตเต็ม — โหลดแอปใหม่เพื่อให้การเปลี่ยนแปลงมีผล';

  @override
  String get syncEngineTicketsTitle => 'ตั๋วงาน';

  @override
  String get syncEngineMessagingTitle => 'ข้อความ';

  @override
  String get syncEngineNotesTitle => 'โน้ต';

  @override
  String get syncEngineOnSubtitle => 'ซิงค์เดลต้าแบบสดทำงานอยู่';

  @override
  String get syncEngineOffSubtitle => 'ใช้ซิงค์แบบสแนปช็อตเต็ม';

  @override
  String get spaces => 'สเปซ';

  @override
  String get spacesHomeDescription => 'เลือกสเปซจากรายการ หรือเริ่มสเปซใหม่';

  @override
  String get noSpacesYet => 'ยังไม่มีสเปซ';

  @override
  String get newSpace => 'สเปซใหม่';

  @override
  String get spaceName => 'ชื่อสเปซ';

  @override
  String get spaceReposHint => 'รีโพที่จะรวม';

  @override
  String get ideSourceControl => 'การควบคุมซอร์ส';

  @override
  String get stagedChanges => 'การเปลี่ยนแปลงที่สเตจแล้ว';

  @override
  String get changes => 'การเปลี่ยนแปลง';

  @override
  String get stageFile => 'สเตจ';

  @override
  String get unstageFile => 'ยกเลิกสเตจ';

  @override
  String get stageAll => 'สเตจการเปลี่ยนแปลงทั้งหมด';

  @override
  String get unstageAll => 'ยกเลิกสเตจทั้งหมด';

  @override
  String get stageChangesToCommit => 'สเตจการเปลี่ยนแปลงเพื่อคอมมิต';

  @override
  String get syncToPrHead => 'ดึงคอมมิต PR ล่าสุด';

  @override
  String get syncedToPrHead => 'ซิงค์กับคอมมิต PR ล่าสุดแล้ว';

  @override
  String get syncPrHeadDirty => 'คอมมิตหรือทิ้งการเปลี่ยนแปลงก่อนซิงค์';

  @override
  String get syncPrHeadFailed => 'ซิงค์กับหัว PR ไม่ได้';

  @override
  String get spaceLabel => 'สเปซ';

  @override
  String get keybindingNewSpace => 'สเปซใหม่';

  @override
  String get keybindingCreateANewSpaceDescription => 'สร้างสเปซใหม่';

  @override
  String get jumpToLatest => 'ไปยังล่าสุด';

  @override
  String get streaming => 'กำลังสตรีม';

  @override
  String get newMessages => 'ใหม่';

  @override
  String get copyLink => 'คัดลอกลิงก์';

  @override
  String get linkCopied => 'คัดลอกลิงก์แล้ว';

  @override
  String get agentResponding => 'เอเจนต์กำลังตอบ';

  @override
  String get agentFinished => 'เอเจนต์ทำงานเสร็จ';

  @override
  String get harnessConnectProviderForModels =>
      'เชื่อมต่อผู้ให้บริการเพื่อดูโมเดล';

  @override
  String get providerSignOut => 'ลงชื่อออก';

  @override
  String get providerWaitingForDeviceCode =>
      'กำลังรอให้คุณยืนยันรหัสในเบราว์เซอร์…';

  @override
  String get providerDeviceCodeHint =>
      'ตรวจว่ารหัสนี้ตรงกับที่แสดงในเบราว์เซอร์ แล้วอนุมัติ';

  @override
  String get providerPlanUsageLoading => 'กำลังตรวจการใช้งานแผน…';

  @override
  String get providerPlanUsageUnavailable => 'แผนนี้ไม่ได้รายงานการใช้งาน';

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return 'ลบคีย์ API ของ $provider หรือไม่?';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return 'คีย์ที่เก็บไว้จะถูกลบและแสดงอีกไม่ได้ เอเจนต์ที่ใช้โมเดล $provider จะหยุดจนกว่าคุณจะวางคีย์ใหม่';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return 'นำ $provider ออกหรือไม่?';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return 'ผู้ให้บริการ $provider และคีย์ที่เก็บไว้จะถูกลบ เอเจนต์ที่ตรึงกับโมเดลของมันจะหยุดทำงาน';
  }

  @override
  String get providerApiKeyHint => 'วางคีย์ API';

  @override
  String get providerApiKeyStoredHint => 'วางคีย์ API อีกอันเพื่อเพิ่ม';

  @override
  String get providerAddAnotherAccount => 'เพิ่มบัญชีอื่น';

  @override
  String get providerActiveBadge => 'ใช้งานอยู่';

  @override
  String get providerOauthAccountFallback => 'บัญชี OAuth';

  @override
  String get providerApiKeyFallback => 'คีย์ API';

  @override
  String get providerRemoveCredentialConfirmTitle =>
      'ลบข้อมูลรับรองนี้หรือไม่?';

  @override
  String get providerSignOutAccountConfirmTitle =>
      'ลงชื่อออกจากบัญชีนี้หรือไม่?';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return 'เอเจนต์ที่ใช้ $provider จะถอยไปใช้คีย์และบัญชีอื่น หากไม่เหลือ จะหยุดจนกว่าคุณจะเพิ่ม';
  }

  @override
  String get providerBaseUrlHint => 'Base URL (ไม่บังคับ)';

  @override
  String get addProvider => 'เพิ่มผู้ให้บริการ';

  @override
  String get noCustomProviders => 'ยังไม่มีผู้ให้บริการที่กำหนดเอง';

  @override
  String get providerNameLabel => 'ชื่อ';

  @override
  String get apiTypeLabel => 'ชนิด API';

  @override
  String get providerBaseUrlLabel => 'Base URL';

  @override
  String get providerApiKeyOptionalHint => 'คีย์ API (ไม่บังคับ)';

  @override
  String get dialectOpenAiCompatible => 'เข้ากันได้กับ OpenAI';

  @override
  String get dialectAnthropicCompatible => 'เข้ากันได้กับ Anthropic';

  @override
  String get removeProviderTooltip => 'นำผู้ให้บริการออก';

  @override
  String get providerLogInWithBrowser => 'ลงชื่อเข้าใช้ด้วยเบราว์เซอร์';

  @override
  String providerLoginDialogTitle(String provider) {
    return 'ลงชื่อเข้าใช้ $provider';
  }

  @override
  String get providerLabel => 'ผู้ให้บริการ';

  @override
  String get selectProviderToLogin => 'เลือกผู้ให้บริการเพื่อลงชื่อเข้าใช้';

  @override
  String providerLoginFailed(String error) {
    return 'ลงชื่อเข้าใช้ไม่สำเร็จ: $error';
  }

  @override
  String get providerWaitingForBrowser => 'กำลังรอให้คุณอนุญาตในเบราว์เซอร์…';

  @override
  String get providerPasteCodeHint => 'หรือวางรหัสจากเบราว์เซอร์';

  @override
  String get providerCompleteLogin => 'เสร็จสิ้น';

  @override
  String get providerConnectedApiKey => 'เชื่อมต่อผ่านคีย์ API';

  @override
  String get providerConnectedOauth => 'เชื่อมต่อแล้ว';

  @override
  String providerConnectedAccount(String account) {
    return 'เชื่อมต่อแล้ว · $account';
  }

  @override
  String get providerLocalReady => 'ในเครื่อง · พร้อม';

  @override
  String get providerNotConnected => 'ยังไม่เชื่อมต่อ';

  @override
  String get preparingWorkspace => 'กำลังเตรียมเวิร์กสเปซ…';

  @override
  String provisioningRunningSetupScript(String repo) {
    return 'กำลังรันสคริปต์ตั้งค่าสำหรับ $repo…';
  }

  @override
  String get repoScriptsTitle => 'สคริปต์';

  @override
  String get repoScriptsTooltip => 'กำหนดสคริปต์วงจรชีวิต';

  @override
  String get repoScriptsSetupLabel => 'สคริปต์ตั้งค่า';

  @override
  String get repoScriptsSetupHelp =>
      'รันใน worktree ของสเปซทันทีหลังสร้าง — ติดตั้งดีเพนเดนซี สร้างไฟล์ หากล้มเหลว สเปซจะถูกทำเครื่องหมายล้มเหลว การลองใหม่จะรันอีกครั้ง';

  @override
  String get repoScriptsArchiveLabel => 'สคริปต์เก็บถาวร';

  @override
  String get repoScriptsArchiveHelp =>
      'รันก่อนลบ worktree ของสเปซ — ทำความสะอาดทรัพยากรนอก worktree ความล้มเหลวไม่กั้นการลบ';

  @override
  String get repoScriptsEnvHelp =>
      'รันผ่าน bash จาก worktree โดยตั้ง CC_WORKSPACE_PATH (worktree), CC_ROOT_PATH (รากรีโพ), CC_SPACE_ID, CC_SPACE_NAME และ CC_REPO_NAME';

  @override
  String get repoScriptsSetupPlaceholder => 'เช่น pnpm install';

  @override
  String get repoScriptsArchivePlaceholder =>
      'เช่น docker compose -p \$CC_SPACE_ID down';

  @override
  String get repoScriptsRecentRuns => 'รันล่าสุด';

  @override
  String get repoScriptsNoRuns => 'ยังไม่มีรัน';

  @override
  String get repoScriptsSaved => 'บันทึกสคริปต์แล้ว';

  @override
  String get repoScriptsRunKindSetup => 'ตั้งค่า';

  @override
  String get repoScriptsRunKindArchive => 'เก็บถาวร';

  @override
  String get repoScriptsRunStatusRunning => 'กำลังรัน';

  @override
  String get repoScriptsRunStatusSucceeded => 'สำเร็จ';

  @override
  String get repoScriptsRunStatusFailed => 'ล้มเหลว';

  @override
  String get repoScriptsRunStatusTimedOut => 'หมดเวลา';

  @override
  String repoScriptsExitCode(int code) {
    return 'รหัสออก $code';
  }

  @override
  String provisioningCloningRepo(String repo) {
    return 'กำลังโคลน $repo…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return 'กำลังเช็กเอาต์ pull request ใน $repo…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return 'กำลังตั้งค่าเอเจนต์ $agent…';
  }

  @override
  String get workspacePrepFailed => 'การตั้งค่าเวิร์กสเปซล้มเหลว';

  @override
  String get workspacePrepStopped => 'หยุดการตั้งค่าเวิร์กสเปซแล้ว';

  @override
  String get stopWorkspacePrep => 'หยุดการเตรียม';

  @override
  String get stopWorkspacePrepTooltip => 'หยุดเตรียมเวิร์กสเปซนี้';

  @override
  String get stopWorkspacePrepConfirm =>
      'หยุดเตรียมเวิร์กสเปซนี้หรือไม่? การโคลนที่กำลังทำจะถูกทิ้ง — คุณเริ่มใหม่จากที่นี่ได้';

  @override
  String messageWillSendWhenReady(int count) {
    return 'ข้อความ $count รายการจะส่งเมื่อพร้อม';
  }

  @override
  String get membersNav => 'สมาชิก';

  @override
  String get membersSettingsDescription =>
      'คนที่มีสิทธิ์เข้าถึงเวิร์กสเปซนี้: รายชื่อ คำเชิญ และร่องรอยการตรวจสอบ';

  @override
  String get memberRosterLabel => 'รายชื่อสมาชิก';

  @override
  String get memberRepoAccessAction => 'สิทธิ์รีโพ';

  @override
  String memberRepoAccessTitle(String name) {
    return 'สิทธิ์รีโพของ $name';
  }

  @override
  String get roleOwner => 'เจ้าของ';

  @override
  String get roleAdmin => 'แอดมิน';

  @override
  String get roleMember => 'สมาชิก';

  @override
  String get roleViewer => 'ผู้ดู';

  @override
  String get roleGuest => 'แขก';

  @override
  String get removeMemberTitle => 'นำสมาชิกออก';

  @override
  String removeMemberConfirm(String name) {
    return 'นำ $name ออกจากเวิร์กสเปซนี้หรือไม่? พวกเขาจะเสียสิทธิ์ทันที';
  }

  @override
  String get transferOwnershipAction => 'โอนความเป็นเจ้าของ';

  @override
  String get transferOwnershipTitle => 'โอนความเป็นเจ้าของ';

  @override
  String transferOwnershipConfirm(String name) {
    return 'ให้ $name เป็นเจ้าของเวิร์กสเปซนี้หรือไม่? คุณจะเป็นแอดมิน เฉพาะเจ้าของลบเวิร์กสเปซหรือเปลี่ยนบทบาทแอดมินอื่นได้';
  }

  @override
  String get transferOwnershipCta => 'โอน';

  @override
  String get auditTrailLabel => 'ร่องรอยการตรวจสอบการอนุญาต';

  @override
  String get auditTrailDescription =>
      'ทุกการอนุญาตและการปฏิเสธ ผูกด้วยแฮชเพื่อให้ตรวจพบรายการที่ถูกแก้หรือลบได้';

  @override
  String get auditVerifyChain => 'ตรวจสอบโซ่';

  @override
  String auditChainIntact(int count) {
    return 'โซ่สมบูรณ์ — ตรวจแล้ว $count รายการ';
  }

  @override
  String auditChainBroken(int seq, String reason) {
    return 'โซ่ขาดที่รายการ $seq: $reason';
  }

  @override
  String get auditEmpty => 'ยังไม่มีการตัดสินที่บันทึก';

  @override
  String get auditDenied => 'ปฏิเสธแล้ว';

  @override
  String get auditAllowed => 'อนุญาตแล้ว';

  @override
  String auditOnBehalfOf(String user) {
    return 'สำหรับ $user';
  }

  @override
  String get policyTemplatesLabel => 'เทมเพลตนโยบาย';

  @override
  String get policyTemplatesDescription =>
      'ใช้ท่าเริ่มต้น หรือย้ายระหว่างเวิร์กสเปซ';

  @override
  String get policyTemplateStrict => 'เข้มงวด';

  @override
  String get policyTemplateBalanced => 'สมดุล';

  @override
  String get policyTemplatePermissive => 'ผ่อนปรน';

  @override
  String get policyTemplateApply => 'ใช้';

  @override
  String policyTemplateApplied(int count) {
    return 'ใช้กฎแล้ว $count ข้อ';
  }

  @override
  String get policyExport => 'คัดลอกนโยบาย';

  @override
  String get policyExported => 'คัดลอกนโยบายไปคลิปบอร์ดแล้ว';

  @override
  String get policyImport => 'วางนโยบาย';

  @override
  String policyImported(int count) {
    return 'นำเข้ากฎแล้ว $count ข้อ';
  }

  @override
  String get approveAndRemember => 'อนุมัติ 8 ชั่วโมง';

  @override
  String get approveAndRememberTooltip =>
      'อนุมัติการกระทำนี้และหยุดถามที่คล้ายกันในสเปซนี้เป็น 8 ชั่วโมง จะหมดอายุเอง';

  @override
  String get unknownUserLabel => 'ผู้ใช้ไม่ทราบ';

  @override
  String get inviteMember => 'เชิญสมาชิก';

  @override
  String get inviteRepoAccessHeader => 'สิทธิ์รีโพสิทอรี';

  @override
  String get inviteRepoAccessExplainer =>
      'เฉพาะรีโพที่คุณเลือกถูกแชร์กับผู้ถูกเชิญ ในระดับที่คุณเลือก ส่วนอื่นยังถูกซ่อน';

  @override
  String get grantLevelRead => 'อ่าน';

  @override
  String get grantLevelReview => 'รีวิว';

  @override
  String get grantLevelWrite => 'เขียน';

  @override
  String get inviteExpiryLabel => 'หมดอายุใน';

  @override
  String get expiryOneDay => '1 วัน';

  @override
  String get expirySevenDays => '7 วัน';

  @override
  String get expiryThirtyDays => '30 วัน';

  @override
  String get createInviteAction => 'สร้างคำเชิญ';

  @override
  String get inviteOneTimeCodeLabel => 'รหัสครั้งเดียว';

  @override
  String get inviteCodeShownOnce => 'รหัสนี้แสดงครั้งเดียว — คัดลอกตอนนี้';

  @override
  String get inviteLinkLabel => 'ลิงก์เชิญ';

  @override
  String get inviteRedeemHint =>
      'แชร์รหัสกับผู้ถูกเชิญ พวกเขาใช้กับ URL เซิร์ฟเวอร์ของคุณ';

  @override
  String get inviteScanQr => 'หรือสแกนเพื่อใช้สิทธิ์';

  @override
  String get inviteLoopbackWarningTitle => 'คำเชิญชี้ไปที่อยู่ภายในเครื่อง';

  @override
  String get inviteLoopbackWarningBody =>
      'ผู้ร่วมงานบนเครื่องอื่นเข้าถึงเซิร์ฟเวอร์นี้ไม่ได้ เริ่มทันเนล (การตั้งค่า → การผสานรวม → แชร์เซิร์ฟเวอร์นี้) หรือผูกกับเครือข่ายเพื่อให้ผู้ใช้ภายนอกเครื่องเชื่อมต่อได้';

  @override
  String get inviteStatusOpen => 'เปิด';

  @override
  String get inviteStatusUsed => 'ใช้แล้ว';

  @override
  String get inviteStatusRevoked => 'เพิกถอนแล้ว';

  @override
  String get inviteStatusExpired => 'หมดอายุแล้ว';

  @override
  String inviteCreatedTime(String time) {
    return 'สร้างเมื่อ $time';
  }

  @override
  String inviteExpiresOn(String date) {
    return 'หมดอายุ $date';
  }

  @override
  String get noActivityYet => 'ยังไม่มีกิจกรรม';

  @override
  String get couldNotLoadMembers => 'โหลดสมาชิกไม่ได้';

  @override
  String get couldNotLoadInvites => 'โหลดคำเชิญไม่ได้';

  @override
  String get couldNotLoadActivity => 'โหลดกิจกรรมไม่ได้';

  @override
  String get yourDevices => 'อุปกรณ์ของคุณ';

  @override
  String get yourDevicesDescription =>
      'ไคลเอนต์ที่จับคู่กับบัญชีของคุณบนเซิร์ฟเวอร์นี้';

  @override
  String get noOwnDevices => 'ยังไม่มีอุปกรณ์ที่จับคู่กับบัญชีของคุณ';

  @override
  String get renameDeviceTitle => 'เปลี่ยนชื่ออุปกรณ์';

  @override
  String get revokeDeviceTitle => 'เพิกถอนอุปกรณ์';

  @override
  String revokeDeviceConfirm(String label) {
    return 'เพิกถอน $label หรือไม่? จะถูกตัดการเชื่อมต่อทันทีและเข้าถึงเซิร์ฟเวอร์นี้ไม่ได้อีก';
  }

  @override
  String devicePairedTime(String time) {
    return 'จับคู่เมื่อ $time';
  }

  @override
  String deviceLastSeenTime(String time) {
    return 'เห็นล่าสุด $time';
  }

  @override
  String get deviceNeverSeen => 'ไม่เคยเชื่อมต่อ';

  @override
  String get profileSectionLabel => 'โปรไฟล์';

  @override
  String get profileSectionDescription =>
      'คุณปรากฏต่อทีมและในผู้แต่งคอมมิต git ในพื้นที่นี้อย่างไร ช่องว่างสืบทอดชื่อและอีเมลของบัญชี';

  @override
  String get displayNameLabel => 'ชื่อที่แสดง';

  @override
  String get emailLabel => 'อีเมล';

  @override
  String get gitAuthorNameLabel => 'ชื่อผู้เขียน Git';

  @override
  String get gitAuthorEmailLabel => 'อีเมลผู้เขียน Git';

  @override
  String get profileSaved => 'บันทึกโปรไฟล์แล้ว';

  @override
  String get presenceOnline => 'ออนไลน์';

  @override
  String get presenceIdle => 'ว่าง';

  @override
  String get presenceTyping => 'กำลังพิมพ์…';

  @override
  String get presenceAgentThinking => 'กำลังคิด';

  @override
  String get presenceAgentRunning => 'กำลังรัน';

  @override
  String get presenceAgentBlocked => 'ถูกบล็อก';

  @override
  String get presenceAgentDone => 'เสร็จแล้ว';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String presenceNameStatusCost(String name, String status, String cost) {
    return '$name — $status ($cost)';
  }

  @override
  String get presenceRailLabel => 'ใครออนไลน์';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => 'เปิดห้ามรบกวน';

  @override
  String get dndTooltipOff => 'ปิดห้ามรบกวน';

  @override
  String get startPresenting => 'เริ่มนำเสนอ';

  @override
  String get stopPresenting => 'หยุดนำเสนอ';

  @override
  String spotlightPresentingBanner(String name) {
    return '$name กำลังนำเสนอ';
  }

  @override
  String get spotlightLeave => 'ออก';

  @override
  String typingIndicator(String name) {
    return '$name กำลังพิมพ์…';
  }

  @override
  String get ideTabNotes => 'โน้ต';

  @override
  String get ideSidebarAllViews => 'มุมมองทั้งหมด';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return 'มุมมองทั้งหมด (ซ่อน $count)';
  }

  @override
  String get ideSidebarPinView => 'ปักหมุดที่แถบข้าง';

  @override
  String get ideSidebarUnpinView => 'เลิกปักหมุดจากแถบข้าง';

  @override
  String get notesEmptyHint => 'เพิ่มโน้ตสำหรับใครก็ตามที่รับการสนทนานี้ต่อ…';

  @override
  String get notesEditTooltip => 'แก้ไขโน้ต';

  @override
  String notesUpdatedBy(String name, String time) {
    return 'อัปเดตโดย $name · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '$name กำลังแก้ไข';
  }

  @override
  String get notesSaveFailed => 'บันทึกโน้ตไม่ได้';

  @override
  String get reactionAddTooltip => 'เพิ่มปฏิกิริยา';

  @override
  String reactionToggleTooltip(String emoji) {
    return 'แสดงปฏิกิริยาด้วย $emoji';
  }

  @override
  String get reactionThumbsUp => 'ยกนิ้วโป้ง';

  @override
  String get reactionThumbsDown => 'คว่ำนิ้วโป้ง';

  @override
  String get reactionLaugh => 'หัวเราะ';

  @override
  String get reactionHooray => 'เยี่ยม';

  @override
  String get reactionConfused => 'สับสน';

  @override
  String get reactionHeart => 'หัวใจ';

  @override
  String get reactionRocket => 'จรวด';

  @override
  String get reactionEyes => 'ตา';

  @override
  String get commentReact => 'แสดงความรู้สึก';

  @override
  String get commentResolveThread => 'ปิดเธรด';

  @override
  String get commentReopenThread => 'เปิดเธรดอีกครั้ง';

  @override
  String get commentCopyLink => 'คัดลอกลิงก์ไปยังความคิดเห็น';

  @override
  String get commentCopyMarkdown => 'คัดลอกเป็น Markdown';

  @override
  String get commentCopyThreadMarkdown => 'คัดลอกเธรดเป็น Markdown';

  @override
  String get commentCopyPrompt => 'คัดลอกเป็นพรอมป์ต์';

  @override
  String get commentCopyThreadPrompt => 'คัดลอกเธรดเป็นพรอมป์ต์';

  @override
  String get commentSendToAgent => 'ส่งถึงเอเจนต์';

  @override
  String get commentDelete => 'ลบความคิดเห็น';

  @override
  String get commentEdit => 'แก้ไขความคิดเห็น';

  @override
  String get commentActions => 'การทำงานของความคิดเห็น';

  @override
  String get commentDeleteTitle => 'ลบความคิดเห็นนี้หรือไม่';

  @override
  String get commentDeleteBody => 'ระบบจะนำออกจาก pull request';

  @override
  String get commentSentToAgent => 'ส่งถึงเอเจนต์แล้ว';

  @override
  String get commentSendFailed => 'ส่งความคิดเห็นนี้ถึงเอเจนต์ไม่ได้';

  @override
  String get commentDeleteFailed => 'ลบความคิดเห็นนี้ไม่ได้';

  @override
  String get autonomyDialLabel => 'ความเป็นอิสระ';

  @override
  String get autonomyProposeOnly => 'เสนออย่างเดียว';

  @override
  String get autonomyActWithApproval => 'ทำเมื่อได้รับอนุมัติ';

  @override
  String get autonomyActFreely => 'ทำได้อย่างอิสระ';

  @override
  String get autonomyDefaultOption => 'ค่าเริ่มต้น';

  @override
  String get checkerLabel => 'ตัวตรวจ';

  @override
  String get checkerNone => 'ไม่มี';

  @override
  String get checkerCaption => 'ตัวตรวจรีวิวรันที่เสร็จแล้วของเอเจนต์อื่น';

  @override
  String get takeoverTooltip => 'เข้าควบคุม worktree';

  @override
  String get takeoverBannerSelf => 'คุณเข้าควบคุม worktree ของการสนทนานี้แล้ว';

  @override
  String takeoverBannerOther(String name) {
    return '$name เข้าควบคุม worktree ของการสนทนานี้แล้ว';
  }

  @override
  String get handBackButton => 'คืนงาน';

  @override
  String get handBackDialogTitle => 'คืน worktree';

  @override
  String get handBackDialogNoteHint => 'โน้ตไม่บังคับถึงเอเจนต์…';

  @override
  String takeoverFailed(String message) {
    return 'เข้าควบคุมไม่ได้: $message';
  }

  @override
  String handBackFailed(String message) {
    return 'คืนงานไม่ได้: $message';
  }

  @override
  String get planStudioTitle => 'Plan Studio';

  @override
  String get plansTitle => 'แผน';

  @override
  String get plansSubtitle => 'แผนที่ใช้งาน เอกสารแผน และเพลย์บุ๊ก';

  @override
  String get plansActiveSection => 'แผนที่ใช้งาน';

  @override
  String get plansDocumentsSection => 'เอกสารแผน';

  @override
  String get plansPlaybooksSection => 'เพลย์บุ๊ก';

  @override
  String get plansNoActive => 'ยังไม่มีแผนที่ใช้งาน';

  @override
  String get plansNoDocuments => 'ยังไม่มีเอกสารแผน';

  @override
  String get plansNoPlaybooks => 'ยังไม่มีเพลย์บุ๊ก';

  @override
  String get planNotFound => 'ไม่พบแผน';

  @override
  String get planOpenInStudio => 'เปิด';

  @override
  String get planNodeTitle => 'ชื่อเรื่อง';

  @override
  String get planNodeDescription => 'คำอธิบาย';

  @override
  String get planNodeDescriptionHint => 'ขั้นตอนนี้ควรทำอะไร…';

  @override
  String get planNodeApplyDescription => 'ใช้';

  @override
  String get planNodeRole => 'บทบาท';

  @override
  String get planNodeDependencies => 'ขึ้นกับ';

  @override
  String get planNodeDependenciesHint => 'เพิ่มการพึ่งพา';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count การพึ่งพา',
      one: '1 การพึ่งพา',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies => 'ไม่มีการพึ่งพา จึงรันทันทีที่แผนเริ่ม';

  @override
  String get planNodeOutputSchema => 'สคีมาเอาต์พุต (JSON)';

  @override
  String get planNodeEstimate => 'ประมาณการ';

  @override
  String get planNodeProvenance => 'แหล่งที่มา';

  @override
  String get planNodeAlreadyExecuted => 'รันแล้ว — การแก้ไขจะแยกแผนจากที่นี่';

  @override
  String get planNewNodeTitle => 'ขั้นตอนใหม่';

  @override
  String get planEstimateNoHistory => 'ยังไม่มีประวัติ';

  @override
  String get planEstimateBlastUnknown => 'รัศมีผลกระทบ: ไม่ทราบ';

  @override
  String get planEstimatePartial => 'บางส่วน';

  @override
  String get planEstimateAction => 'ประมาณการ';

  @override
  String planEstimateDuration(String range) {
    return 'ระยะเวลา $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return 'รัศมีผลกระทบ: $files ไฟล์, $symbols สัญลักษณ์';
  }

  @override
  String get planApprove => 'อนุมัติแผน';

  @override
  String get planApproveSelectedNodes => 'อนุมัติที่เลือก';

  @override
  String get planReject => 'ปฏิเสธ';

  @override
  String get planCancel => 'ยกเลิกรัน';

  @override
  String get planContinueNode => 'ทำโหนดต่อ';

  @override
  String get planTotalNotEstimated => 'ยังไม่ประมาณการ';

  @override
  String get planBudgetExceeded => 'เกินงบ';

  @override
  String planBudgetCeiling(String amount) {
    return 'งบ ≤ \$$amount';
  }

  @override
  String get planVersionsTitle => 'เวอร์ชัน';

  @override
  String get planNoRevisions => 'ยังไม่มีการแก้ไข';

  @override
  String get planDiffIdentical => 'ไม่มีการเปลี่ยนแปลง';

  @override
  String get planDiffGoalChanged => 'เป้าหมายเปลี่ยน';

  @override
  String get planDiffBudgetChanged => 'งบประมาณเปลี่ยน';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'การเปลี่ยนแปลงจาก v$fromRev ถึง v$toRev';
  }

  @override
  String planDiffAdded(String node) {
    return 'เพิ่ม $node';
  }

  @override
  String planDiffRemoved(String node) {
    return 'ลบ $node';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return 'เปลี่ยน $node: $fields';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return 'เพิ่มเส้น: $edge';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return 'ลบเส้น: $edge';
  }

  @override
  String planDiffRoleAdded(String role) {
    return 'เพิ่มบทบาท: $role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return 'ลบบทบาท: $role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return 'มอบหมายบทบาทใหม่: $role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return 'วางแผนใหม่: คุณอนุมัติ v$approved ตอนนี้เป็น v$current ตรวจ diff ก่อนดำเนินการต่อ';
  }

  @override
  String planLiveActualCost(String amount) {
    return 'ค่าใช้จ่ายจริง: \$$amount';
  }

  @override
  String get planPlaybookRun => 'รัน';

  @override
  String get planPlaybookDelete => 'ลบเพลย์บุ๊ก';

  @override
  String get planPlaybookProposed => 'เสนอแผนแล้ว — อนุมัติใน Plan Studio';

  @override
  String get planPlaybookAnchorTicket => 'ตั๋วงานหลัก';

  @override
  String get planPlaybookPickTicket => 'เลือกตั๋วงาน…';

  @override
  String get planPlaybookProposeRun => 'เสนอแผน';

  @override
  String get planPlaybookRepoHint => 'ID รีโพสิทอรี';

  @override
  String get planPlaybookAgentHint => 'ID เอเจนต์';

  @override
  String planPlaybookRunTitle(String name) {
    return 'รัน $name';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '$count พารามิเตอร์';
  }

  @override
  String get recentLabel => 'ล่าสุด';

  @override
  String get cheatSheetTitle => 'ทางลัดแป้นพิมพ์';

  @override
  String get cheatSheetGlobal => 'ทั่วไป';

  @override
  String get cheatSheetThisScreen => 'หน้าจอนี้';

  @override
  String get cheatSheetReservedInBrowser => 'สงวนในเบราว์เซอร์';

  @override
  String get keybindingCheatSheet => 'ทางลัดแป้นพิมพ์';

  @override
  String get keybindingShowKeyboardShortcutsDescription =>
      'แสดงแผ่นทางลัดแป้นพิมพ์ของหน้าจอปัจจุบัน';

  @override
  String get runPlaybookLabel => 'รันเพลย์บุ๊ก';

  @override
  String get playbooksLabel => 'เพลย์บุ๊ก';

  @override
  String get keybindingUndo => 'เลิกทำ';

  @override
  String get keybindingRedo => 'ทำซ้ำ';

  @override
  String get keybindingUndoLastActionDescription =>
      'เลิกทำการกระทำล่าสุดที่ย้อนได้';

  @override
  String get keybindingRedoLastActionDescription =>
      'ทำซ้ำการกระทำที่เลิกทำล่าสุด';

  @override
  String get undone => 'เลิกทำแล้ว';

  @override
  String get redone => 'ทำซ้ำแล้ว';

  @override
  String get undoFailed => 'เลิกทำไม่ได้';

  @override
  String get undoLabelTicketEdit => 'แก้ไขตั๋วงาน';

  @override
  String get undoLabelMessageEdit => 'แก้ไขข้อความ';

  @override
  String get undoLabelTodoStatus => 'สถานะสิ่งที่ต้องทำ';

  @override
  String get inboxTitle => 'กล่องขาเข้า';

  @override
  String get inboxReview => 'รีวิว';

  @override
  String get inboxOpen => 'เปิด';

  @override
  String get inboxAllCaughtUp => 'คุณตามทันหมดแล้ว';

  @override
  String get inboxGitHubDownTitle => 'GitHub อาจล่ม';

  @override
  String inboxGitHubDownBody(String status) {
    return 'GitHub รายงาน $status ดังนั้น pull request อาจหายจากรายการนี้ มิใช่ว่าเสร็จจริง';
  }

  @override
  String get inboxGitHubIdentityTitle => 'ยืนยันบัญชี GitHub ของคุณไม่ได้';

  @override
  String get inboxGitHubIdentityBody =>
      'กล่องขาเข้าเรียงตามว่าคุณเป็นใครบน GitHub จนกว่าจะโหลดได้จะว่าง แม้มี pull request รอคุณอยู่';

  @override
  String get inboxSeverityBlocking => 'ถูกบล็อก';

  @override
  String get inboxSeverityWaiting => 'กำลังรอ';

  @override
  String get inboxSeverityInfo => 'ข้อมูล';

  @override
  String get inboxSyncFailed => 'ซิงค์ไม่สำเร็จ';

  @override
  String get inboxNeedsYourAttention => 'ต้องการความสนใจของคุณ';

  @override
  String get inboxSectionNeedsYourReview => 'ต้องการการรีวิวของคุณ';

  @override
  String get inboxSectionReturnedToYou => 'คืนมาให้คุณ';

  @override
  String get inboxSectionApproved => 'อนุมัติแล้ว';

  @override
  String get inboxSectionDrafts => 'ฉบับร่าง';

  @override
  String get inboxSectionWaitingForReviewers => 'รอผู้รีวิว';

  @override
  String get inboxSectionMergingAndMerged => 'กำลังรวมและรวมล่าสุด';

  @override
  String get inboxSectionWaitingForAuthor => 'รอผู้เขียน';

  @override
  String get inboxColumnTitle => 'ชื่อเรื่อง';

  @override
  String get inboxColumnChanges => 'การเปลี่ยนแปลง';

  @override
  String get inboxColumnUpdated => 'อัปเดตแล้ว';

  @override
  String get inboxReviewApproved => 'อนุมัติแล้ว';

  @override
  String get inboxReviewChangesRequested => 'ขอให้แก้ไข';

  @override
  String get inboxHeroSubtitle =>
      'ทุก pull request ที่เกี่ยวข้องกับคุณ เรียงตามสิ่งที่เกิดต่อไป';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull request ต้องการการรีวิวของคุณ',
      one: '1 pull request ต้องการการรีวิวของคุณ',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'คืนมาให้คุณ $count รายการ',
      one: 'คืนมาให้คุณ 1 รายการ',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted =>
      'การเปลี่ยนแปลงนั้นไม่ถูกบันทึกและถูกย้อนแล้ว';

  @override
  String get offlinePendingLabel => 'รอดำเนินการ';

  @override
  String get offlineSyncingLabel => 'กำลังซิงค์';

  @override
  String get copyLinkLabel => 'คัดลอกลิงก์ไปหน้านี้';

  @override
  String get agentsSectionLabel => 'เอเจนต์';

  @override
  String get fleetWorkersTitle => 'เวิร์กเกอร์';

  @override
  String get fleetWorkersSubtitle => 'เครื่องที่พร้อมรันงาน';

  @override
  String get fleetJobsTitle => 'งาน';

  @override
  String get fleetJobsSubtitle => 'งานที่กระจายทั่วกองเรือ';

  @override
  String get fleetNoWorkers =>
      'ยังไม่มีเวิร์กเกอร์ — เครื่องที่สองที่รัน `cc_worker --server <url>` จะเข้าร่วมกองเรือ';

  @override
  String get fleetNoJobs => 'ไม่มีงาน';

  @override
  String get fleetError => 'โหลดกองเรือไม่ได้';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count คอร์',
      one: '1 คอร์',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return 'Heartbeat $time';
  }

  @override
  String get fleetNoHeartbeat => 'ยังไม่มี heartbeat';

  @override
  String fleetLastErrorLabel(String error) {
    return 'ข้อผิดพลาดล่าสุด: $error';
  }

  @override
  String get fleetDrain => 'ระบาย';

  @override
  String get fleetResume => 'ทำต่อ';

  @override
  String get fleetRevoke => 'เพิกถอน';

  @override
  String get fleetRemove => 'นำออก';

  @override
  String get fleetRevokeTitle => 'เพิกถอนเวิร์กเกอร์หรือไม่?';

  @override
  String fleetRevokeBody(String name) {
    return 'เพิกถอน $name หรือไม่? เซสชันจะจบและงานที่กำลังทำจะถูกมอบใหม่';
  }

  @override
  String get fleetRemoveTitle => 'นำเวิร์กเกอร์ออกหรือไม่?';

  @override
  String fleetRemoveBody(String name) {
    return 'นำ $name ออกจากกองเรือหรือไม่? การดำเนินการนี้ลบบันทึก';
  }

  @override
  String get fleetActionFailed => 'การกระทำล้มเหลว';

  @override
  String get fleetJobUnassigned => 'ยังไม่มอบหมาย';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '$attempts/$max ครั้ง';
  }

  @override
  String get fleetPlacementReasons => 'การตัดสินใจจัดวาง';

  @override
  String get fleetNoPlacements => 'ยังไม่มีการตัดสินใจจัดวาง';

  @override
  String get fleetStatusOnline => 'ออนไลน์';

  @override
  String get fleetStatusDraining => 'กำลังระบาย';

  @override
  String get fleetStatusOffline => 'ออฟไลน์';

  @override
  String get fleetStatusIncompatible => 'เข้ากันไม่ได้';

  @override
  String get fleetStatusRevoked => 'เพิกถอนแล้ว';

  @override
  String get fleetJobStatusQueued => 'อยู่ในคิว';

  @override
  String get fleetJobStatusRunning => 'กำลังรัน';

  @override
  String get fleetJobStatusSucceeded => 'สำเร็จ';

  @override
  String get fleetJobStatusFailed => 'ล้มเหลว';

  @override
  String get fleetJobStatusCancelled => 'ยกเลิกแล้ว';

  @override
  String get evalsNoSuites => 'ยังไม่มีชุด eval';

  @override
  String get evalsError => 'โหลด eval ไม่ได้';

  @override
  String get evalsStarterBadge => 'เริ่มต้น';

  @override
  String evalsDefaultBatch(int count) {
    return 'ชุดเริ่มต้น $count รายการ';
  }

  @override
  String get evalsRecentRuns => 'รันล่าสุด';

  @override
  String get evalsNoRuns => 'ยังไม่มีรัน';

  @override
  String get evalsPassRate => 'อัตราผ่าน';

  @override
  String evalsBatchTimes(int count) {
    return '× $count';
  }

  @override
  String evalsTriggeredBy(String who) {
    return 'โดย $who';
  }

  @override
  String evalsRunFinished(String rate) {
    return 'Eval เสร็จ — ผ่าน $rate';
  }

  @override
  String get evalsRunFailed => 'รันชุดไม่ได้';

  @override
  String get evalsRun => 'รัน';

  @override
  String get evalsStatusQueued => 'อยู่ในคิว';

  @override
  String get evalsStatusRunning => 'กำลังรัน';

  @override
  String get evalsStatusPassed => 'ผ่าน';

  @override
  String get evalsStatusFailed => 'ล้มเหลว';

  @override
  String get bannerMeetingJoin => 'เข้าร่วม';

  @override
  String get bannerMeetingRecordAndLink => 'บันทึกและลิงก์';

  @override
  String get bannerCalendarReconnect => 'เชื่อมต่ออีกครั้ง';

  @override
  String get bannerView => 'ดู';

  @override
  String get soundscapeTitle => 'ซาวด์สเคป';

  @override
  String get soundscapePlay => 'เล่น';

  @override
  String get soundscapePause => 'หยุดชั่วคราว';

  @override
  String get soundscapeMoodLabel => 'อารมณ์';

  @override
  String get soundscapeMoodFocus => 'โฟกัส';

  @override
  String get soundscapeMoodRelax => 'ผ่อนคลาย';

  @override
  String get soundscapeMoodSleep => 'นอน';

  @override
  String get soundscapeMoodRise => 'รุ่ง';

  @override
  String get soundscapeVolumeLabel => 'ระดับเสียง';

  @override
  String get soundscapeTuneLabel => 'ปรับ';

  @override
  String get soundscapeTuneMellow => 'นุ่ม';

  @override
  String get soundscapeTuneBright => 'สว่าง';

  @override
  String get soundscapeTuneEnergetic => 'มีพลัง';

  @override
  String get soundscapeTuneSpacy => 'โปร่ง';

  @override
  String get soundscapeTuneResetHint => 'แตะสองครั้งเพื่อรีเซ็ต';

  @override
  String get soundscapeSceneLabel => 'กำลังเล่น';

  @override
  String get soundscapeSceneLoading => 'กำลังจูนบรรยากาศ…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees°C';
  }

  @override
  String get soundscapeLocationLabel => 'ตำแหน่ง';

  @override
  String get soundscapeLocationDetecting => 'กำลังตรวจจับตำแหน่ง…';

  @override
  String get soundscapeLocationAutoNote => 'ตำแหน่งมาจากอุปกรณ์นี้';

  @override
  String get soundscapeRefreshWeather => 'รีเฟรชสภาพอากาศ';

  @override
  String get soundscapeAutoStartLabel => 'เริ่มกับโหมดโฟกัส';

  @override
  String get soundscapeAutoStartDescription =>
      'เล่นซาวด์สเคปอัตโนมัติเมื่อเริ่มเซสชันโฟกัส';

  @override
  String get soundscapeReturnToApp => 'กลับไปแอป';

  @override
  String get soundscapePopOut => 'แยกเครื่องเล่น';

  @override
  String get discussion => 'การอภิปราย';

  @override
  String get chat => 'แชท';

  @override
  String get saving => 'กำลังบันทึก…';

  @override
  String get saved => 'บันทึกแล้ว';

  @override
  String get saveFailed => 'บันทึกไม่ได้';

  @override
  String get commitAndPush => 'คอมมิตและพุช';

  @override
  String get commit => 'คอมมิต';

  @override
  String get commitAmend => 'คอมมิต (แก้)';

  @override
  String get commitAndSync => 'คอมมิตและซิงค์';

  @override
  String get scmSyncChanges => 'ซิงค์การเปลี่ยนแปลง';

  @override
  String get scmPublishBranch => 'เผยแพร่สาขา';

  @override
  String get scmSyncFailed => 'ซิงค์ไม่สำเร็จ';

  @override
  String get scmSyncDirty => 'คอมมิตหรือยกเลิกการเปลี่ยนแปลงก่อนซิงค์';

  @override
  String get scmSynced => 'ซิงค์แล้ว';

  @override
  String get scmPushRefused => 'การพุชถูกปฏิเสธ';

  @override
  String get scmPulledPushRefused => 'ดึงมาแล้ว แต่การพุชถูกปฏิเสธ';

  @override
  String get scmPushRefusedHint => 'รีโมตหรือฮุกปฏิเสธการอัปเดต';

  @override
  String get scmSelectBranch => 'เลือกสาขาที่จะเช็คเอาต์';

  @override
  String get scmCreateBranch => 'สร้างสาขาใหม่…';

  @override
  String get scmCreateBranchFrom => 'สร้างสาขาใหม่จาก…';

  @override
  String get scmCheckoutDetached => 'เช็คเอาต์แบบแยก…';

  @override
  String get scmBranchName => 'ชื่อสาขา';

  @override
  String get scmCreateBranchTitle => 'สร้างสาขา';

  @override
  String scmFromRef(String ref) {
    return 'จาก ⁨$ref⁩';
  }

  @override
  String get scmCheckoutFailed => 'สลับสาขาไม่ได้';

  @override
  String get scmCheckoutDirty => 'คอมมิตหรือยกเลิกการเปลี่ยนแปลงก่อนสลับสาขา';

  @override
  String scmSwitchedToBranch(String branch) {
    return 'สลับไปที่ ⁨$branch⁩';
  }

  @override
  String scmDetachedAt(String ref) {
    return 'แยกที่ ⁨$ref⁩';
  }

  @override
  String get scmDetachedHead => 'HEAD ที่แยกออก';

  @override
  String get scmNoBranches => 'ไม่มีสาขาที่ตรงกัน';

  @override
  String get scmBranches => 'สาขา';

  @override
  String get scmRemoteBranches => 'สาขาระยะไกล';

  @override
  String get scmTags => 'แท็ก';

  @override
  String get scmPickStartPoint => 'เลือกจุดเริ่มต้น';

  @override
  String get scmSwitchBranch => 'สลับสาขา';

  @override
  String get scmPullConflictTitle => 'การดึงจะทำให้เกิดความขัดแย้ง';

  @override
  String scmPullConflictBody(int count, String branch) {
    return 'การดึง $count คอมมิตไปที่ ⁨$branch⁩ จะขัดแย้งกับงานในสำเนานี้';
  }

  @override
  String get scmAskAi => 'ถาม AI';

  @override
  String scmResolveConflictPrompt(String branch, String repo, int count) {
    return 'ดึง ⁨$branch⁩ ใน ⁨$repo⁩ สาขานี้ตามหลังอัปสตรีม $count คอมมิต และการดึงขัดแย้งกับงานในเครื่อง แก้ความขัดแย้งแล้วดึงให้เสร็จ';
  }

  @override
  String commitMessageOnBranch(String shortcut, String branch) {
    return 'ข้อความ ($shortcut เพื่อคอมมิตบน “$branch”)';
  }

  @override
  String get committed => 'คอมมิตแล้ว';

  @override
  String get commitAmended => 'แก้คอมมิตแล้ว';

  @override
  String get commitFailed => 'คอมมิตไม่สำเร็จ';

  @override
  String get moreCommitActions => 'การกระทำคอมมิตเพิ่มเติม';

  @override
  String get sourceControl => 'การควบคุมซอร์ส';

  @override
  String fixFindingTitle(String location) {
    return 'แก้: $location';
  }

  @override
  String get openInEditor => 'เปิดในตัวแก้ไข';

  @override
  String get regexTesterTitle => 'ทดสอบนิพจน์ปรกติ';

  @override
  String get regexTesterHint => 'พิมพ์ตัวอย่าง';

  @override
  String get regexMatch => 'ตรงกัน';

  @override
  String get regexNoMatch => 'ไม่ตรงกัน';

  @override
  String get regexInvalidPattern => 'รูปแบบไม่ถูกต้อง';

  @override
  String get symbolLookupNone => 'ไม่มีนิยามในดัชนีหรือในคำขอดึงนี้';

  @override
  String get symbolLookupInDiff => 'พบในคำขอดึงนี้';

  @override
  String get symbolLookupFromBase =>
      'จากเช็กเอาต์ฐาน — เวิร์กทรีของ PR นี้ยังไม่ได้จัดทำดัชนี';

  @override
  String get symbolImplementations => 'การใช้งาน';

  @override
  String symbolCallersCount(int count) {
    return '$count ผู้เรียก';
  }

  @override
  String get commitMessageHint => 'ข้อความคอมมิต';

  @override
  String get pushedToPr => 'พุชไป PR แล้ว';

  @override
  String get pushFailed => 'พุชไม่สำเร็จ';

  @override
  String get reviewFindings => 'ข้อค้นพบ';

  @override
  String get treeLabel => 'ต้นไม้';

  @override
  String get toggleFileTree => 'แสดงหรือซ่อนต้นไม้ไฟล์';

  @override
  String get diffViewSettings => 'การตั้งค่ามุมมอง diff';

  @override
  String get splitViewLabel => 'แยก';

  @override
  String get unifiedViewLabel => 'รวม';

  @override
  String get wrapLines => 'ตัดบรรทัด';

  @override
  String get shiftClickSelectRange => 'Shift-คลิกเพื่อเลือกช่วง';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ไฟล์',
      one: '1 ไฟล์',
    );
    return '$_temp0';
  }

  @override
  String prComplexityLoc(String loc) {
    return '$loc LOC';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return 'PR เล็ก — $files ประมาณ $minutes นาทีในการรีวิว';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return 'PR กลาง — $files กันเวลาประมาณ $minutes นาทีในการรีวิว';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return 'PR ใหญ่ — $files ลองแยกก่อนรีวิว';
  }

  @override
  String get searchInFiles => 'ค้นหาในไฟล์';

  @override
  String get showFileList => 'แสดงรายการไฟล์';

  @override
  String get searchInFilesHintField => 'ค้นหาในไฟล์…';

  @override
  String get searchInFilesHint => 'ค้นหาข้ามไฟล์ของ pull request';

  @override
  String get searchInWholeRepo => 'ค้นหาทั้งรีโพสิทอรี';

  @override
  String get searchInThisPullRequest => 'ค้นหาใน pull request นี้';

  @override
  String get searchNoResults => 'ไม่พบผลลัพธ์';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ผลลัพธ์',
      one: '1 ผลลัพธ์',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files ไฟล์',
      one: '1 ไฟล์',
    );
    return '$_temp0 ใน $_temp1';
  }

  @override
  String get discardChangesTitle => 'ทิ้งการเปลี่ยนแปลงหรือไม่?';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ไฟล์',
      one: '1 ไฟล์',
    );
    return 'ทิ้ง $_temp0 ไปที่ HEAD หรือไม่? เลิกทำไม่ได้';
  }

  @override
  String get discardAll => 'ทิ้งทั้งหมด';

  @override
  String get discardFailed => 'ทิ้งการเปลี่ยนแปลงไม่สำเร็จ';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ไฟล์',
      one: '1 ไฟล์',
    );
    return 'ทิ้ง $_temp0 แล้ว';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '$reverted ไฟล์',
      one: '1 ไฟล์',
    );
    return 'ทิ้ง $_temp0; ข้าม $skipped (ยังไม่ติดตาม)';
  }

  @override
  String get prWorktreeUnavailable => 'เวิร์กสเปซยังไม่พร้อม';

  @override
  String get prWorktreeUnavailableHint =>
      'เตรียมไฟล์ของ pull request ไม่สำเร็จ เปิด pull request ใหม่เพื่อลองอีกครั้ง';

  @override
  String get timestampRelativeLabel => 'สัมพัทธ์';

  @override
  String get timestampRawLabel => 'เวลา';

  @override
  String get copyTimestamp => 'คัดลอกเวลา';

  @override
  String get copiedTimestamp => 'คัดลอกเวลาแล้ว';

  @override
  String get previewDeployment => 'การปรับใช้ตัวอย่าง';

  @override
  String previewDeploymentTab(String site) {
    return 'ตัวอย่าง: $site';
  }

  @override
  String get askForReview => 'ขอให้รีวิว…';

  @override
  String get closePrsConfirmTitle => 'ปิด pull request หรือไม่?';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ปิด $count pull request หรือไม่?',
      one: 'ปิด 1 pull request หรือไม่?',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ปิด $count pull request แล้ว',
      one: 'ปิด 1 pull request แล้ว',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'มอบหมาย $count pull request แล้ว',
      one: 'มอบหมาย 1 pull request แล้ว',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ขอรีวิว $count pull request แล้ว',
      one: 'ขอรีวิว 1 pull request แล้ว',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count การกระทำล้มเหลว',
      one: '1 การกระทำล้มเหลว',
    );
    return '$_temp0';
  }

  @override
  String get diagram => 'ไดอะแกรม';

  @override
  String get diagramViewSource => 'ดูซอร์ส';

  @override
  String get diagramHideSource => 'ซ่อนซอร์ส';

  @override
  String diagramPreviewUnavailable(String reason) {
    return 'ดูตัวอย่างไดอะแกรมไม่ได้ ($reason)';
  }

  @override
  String get planUnavailable => 'แผนใช้ไม่ได้';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ขั้นตอน',
      one: '1 ขั้นตอน',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => 'อนุมัติและรัน';

  @override
  String get planStatusDraft => 'ฉบับร่าง';

  @override
  String get planStatusProposed => 'แผน';

  @override
  String get planStatusApproved => 'อนุมัติแผนแล้ว';

  @override
  String get planStatusRejected => 'ปฏิเสธแผนแล้ว';

  @override
  String get planStatusSuperseded => 'แผนถูกแทนที่';

  @override
  String planRevisionLabel(int revision) {
    return 'ฉบับแก้ไข $revision';
  }

  @override
  String get adapterEnforcementTitle => 'สิ่งที่อะแดปเตอร์นี้บังคับใช้';

  @override
  String get enforcementFiltersToolSurface => 'Control Center เลือกเครื่องมือ';

  @override
  String get enforcementInterceptsToolCalls => 'ทุกการเรียกถูกกั้นก่อนรัน';

  @override
  String get enforcementObservesCompletionContract =>
      'รันถูกยึดตามสิ่งที่ต้องส่งมอบ';

  @override
  String get enforcementNativeToolsInterceptable =>
      'เครื่องมือของตัวรันเองมองเห็นได้';

  @override
  String get enforcementInProcessToolsSandboxed =>
      'เครื่องมือในโพรเซสถูกแซนด์บ็อกซ์';

  @override
  String get enforcementYes => 'ใช่';

  @override
  String get enforcementNo => 'ไม่';

  @override
  String get adapterEnforcementCaveats => 'ข้อควรทราบ';

  @override
  String get enforcementSummaryModesEnforced => 'บังคับใช้โหมดแล้ว';

  @override
  String get enforcementSummaryModesNotEnforced => 'ยังไม่บังคับใช้โหมด';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ข้อควรทราบ',
      one: '1 ข้อควรทราบ',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      'โหมดอ่านอย่างเดียวไม่ใช่เชิงโครงสร้าง: Control Center เอาเครื่องมือของตัวรันนี้ออกไม่ได้';

  @override
  String get caveatToolCallsNotIntercepted =>
      'ไม่มีประตูก่อนรัน: เฉพาะการเรียกเครื่องมือ MCP ที่ผ่าน Control Center';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      'เครื่องมือไฟล์และเชลล์ของตัวรันเองไม่ถึง Control Center แซนด์บ็อกซ์ของ OS คือพื้นเดียวภายใต้พวกมัน';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      'เครื่องมือไฟล์ในโพรเซสรันนอกแซนด์บ็อกซ์ ดังนั้นพื้นผิวเครื่องมือคือขอบระบบไฟล์เดียว';

  @override
  String get caveatCompletionContractUnobservable =>
      'Control Center กระตุ้นหรือทำให้รันล้มเหลวไม่ได้หากจบโดยไม่ส่งมอบสิ่งที่ต้องมี';

  @override
  String get modeDegraded => 'ลดระดับ';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return 'โหมด $mode บน $adapter พึ่งแซนด์บ็อกซ์อย่างเดียว เครื่องมือไฟล์ของเอเจนต์เองไม่ถูกสกัด';
  }

  @override
  String get artifactUnavailable => 'อาร์ติแฟกต์ใช้ไม่ได้';

  @override
  String artifactRevisionLabel(int count) {
    return '$count ฉบับแก้ไข';
  }

  @override
  String get artifactShowMore => 'แสดงเพิ่ม';

  @override
  String get artifactShowLess => 'แสดงน้อยลง';

  @override
  String get artifactCopy => 'คัดลอก';

  @override
  String get artifactCopied => 'คัดลอกอาร์ติแฟกต์แล้ว';

  @override
  String get artifactsTabLabel => 'อาร์ติแฟกต์';

  @override
  String get artifactsEmptyTitle => 'ยังไม่มีอาร์ติแฟกต์';

  @override
  String get artifactsEmptyBody =>
      'เมื่อเอเจนต์เผยแพร่ตาราง กราฟ หรือไดอะแกรมที่นี่ จะปรากฏในรายการนี้';

  @override
  String get artifactRevisionPickerLabel => 'ฉบับแก้ไข';

  @override
  String get artifactRestoreRevision => 'กู้คืนฉบับนี้';

  @override
  String get artifactOpenInTab => 'เปิดในแท็บ';

  @override
  String get artifactTitleFallback => 'อาร์ติแฟกต์';

  @override
  String get providerGenerationLabel => 'ค่าเริ่มต้นการสร้าง';

  @override
  String get providerGenerationHint =>
      'เว้นช่องว่างเพื่อใช้ค่าเริ่มต้นของเอนด์พอยต์ โมเดลประกาศเพดานเอาต์พุตและสูตรสุ่มของตัวเอง การเสิร์ฟค่าอื่นอาจทำให้คุณภาพลด';

  @override
  String get providerMaxTokensLabel => 'โทเค็นเอาต์พุตสูงสุด';

  @override
  String get addModel => 'เพิ่มโมเดล';

  @override
  String get modelListTitle => 'รายการโมเดล';

  @override
  String get railProvidersGroup => 'ผู้ให้บริการ';

  @override
  String get railCustomProvidersGroup => 'ผู้ให้บริการที่กำหนดเอง';

  @override
  String get editModelSettings => 'แก้ไขการตั้งค่าโมเดล';

  @override
  String get modelIdLabel => 'ID โมเดล';

  @override
  String get modelIdImmutableHint =>
      'ID ที่เอนด์พอยต์เสิร์ฟ ตรึงเมื่ออยู่ในรายการแล้ว';

  @override
  String get contextWindowLabel => 'หน้าต่างบริบท';

  @override
  String get inputTypesLabel => 'ชนิดอินพุต';

  @override
  String get outputTypesLabel => 'ชนิดเอาต์พุต';

  @override
  String get modalityText => 'ข้อความ';

  @override
  String get modalityImage => 'รูปภาพ';

  @override
  String get modalityAudio => 'เสียง';

  @override
  String get modalityVideo => 'วิดีโอ';

  @override
  String get modalityPdf => 'PDF';

  @override
  String get modelOverrideReset => 'รีเซ็ตเป็นอัตโนมัติ';

  @override
  String get modelOverrideEdited => 'แก้ไขแล้ว';

  @override
  String get manualModelBadge => 'เพิ่มด้วยมือ';

  @override
  String get modelIdRequired => 'ใส่ ID โมเดล';

  @override
  String get modelTokensInvalid => 'ใส่จำนวนโทเค็นเป็นจำนวนเต็มบวก';

  @override
  String get removeModelAction => 'นำโมเดลออก';

  @override
  String removeModelConfirmTitle(String model) {
    return 'นำ $model ออกหรือไม่?';
  }

  @override
  String get removeModelConfirmBody =>
      'โมเดลจะออกจากรายการ และเอเจนต์ที่ตรึงกับมันจะหยุดทำงาน ผู้ให้บริการไม่ได้รับผลกระทบ';

  @override
  String get addModelProviderTitle => 'เพิ่มผู้ให้บริการโมเดล';

  @override
  String get addModelProviderDescription =>
      'กำหนดเอนด์พอยต์ API ที่กำหนดเองและโมเดลของมัน';

  @override
  String get modelListEmptyHint =>
      'ยังไม่ได้กำหนดโมเดล เพิ่มโมเดลเพื่อใช้ในแชท';

  @override
  String get addProviderModelsHint =>
      'โมเดลถูกดึงแบบสดเมื่อเอนด์พอยต์ตอบ เพิ่มด้วยมือเฉพาะเมื่อมันแสดงรายการเองไม่ได้';

  @override
  String get providerTemperatureLabel => 'Temperature';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved => 'บันทึกค่าเริ่มต้นการสร้างแล้ว';

  @override
  String get providerGenerationInvalid =>
      'ตรวจค่า: โทเค็นเอาต์พุตสูงสุดและ top-k ต้องเป็นบวก temperature 0–2 top-p 0–1';

  @override
  String get providerGenerationOverridden => 'ถูกแทนที่';

  @override
  String get branchNotPushed => 'ยังไม่ได้พุช';

  @override
  String branchNotOnRemote(String branch) {
    return '“$branch” มีอยู่ในการสนทนานี้เท่านั้น';
  }

  @override
  String get branchNotOnRemoteHint =>
      'GitHub ยังไม่เคยเห็นสาขานี้ จึงยังใช้กับ pull request ไม่ได้ การเผยแพร่จะพุชคอมมิตที่มีใน worktree แล้ว — การเปลี่ยนแปลงที่ยังไม่คอมมิตถูกปล่อยไว้';

  @override
  String get publishBranch => 'เผยแพร่สาขา';

  @override
  String branchPublished(String branch) {
    return 'เผยแพร่ “$branch” ไป origin แล้ว';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return 'เผยแพร่สาขาแล้ว การเปลี่ยนแปลงที่ยังไม่คอมมิต $count รายการไม่ถูกรวม';
  }

  @override
  String get composePrLoadingBranches => 'กำลังโหลดสาขาจาก GitHub…';

  @override
  String get composePrBranchesFailed =>
      'โหลดสาขาจาก GitHub ไม่ได้ พิมพ์ชื่อสาขา หรือตรวจการเชื่อมต่อ GitHub';

  @override
  String get composePrSubtitleFromSpace =>
      'จากสาขาของการสนทนานี้ — เผยแพร่ก่อนหาก GitHub ยังไม่เห็น';

  @override
  String get obsTabInsights => 'ข้อมูลเชิงลึก';

  @override
  String get obsTabLive => 'สด';

  @override
  String get obsTabQuality => 'คุณภาพ';

  @override
  String get obsTabUsage => 'การใช้งาน';

  @override
  String get obsUsageTotalTokens => 'โทเค็นทั้งหมด';

  @override
  String get obsUsagePeakTokens => 'โทเค็นสูงสุด';

  @override
  String get obsUsageLongestSession => 'เซสชันยาวสุด';

  @override
  String get obsUsageCurrentStreak => 'สตรีคปัจจุบัน';

  @override
  String get obsUsageLongestStreak => 'สตรีคยาวสุด';

  @override
  String obsUsageDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count วัน',
      one: '1 วัน',
      zero: '0 วัน',
    );
    return '$_temp0';
  }

  @override
  String get obsUsageTokenActivity => 'กิจกรรมโทเค็น';

  @override
  String get obsUsageActivityModeLabel => 'โหมดกิจกรรมโทเค็น';

  @override
  String get obsUsageModeDaily => 'รายวัน';

  @override
  String get obsUsageModeWeekly => 'รายสัปดาห์';

  @override
  String get obsUsageModeCumulative => 'สะสม';

  @override
  String get obsUsageTimeRange => 'ช่วงเวลา';

  @override
  String get obsUsageTrendTitle => 'แนวโน้มโทเค็นรายวัน';

  @override
  String get obsUsageModelUsage => 'การใช้งานโมเดล';

  @override
  String get obsUsageTokensLabel => 'โทเค็น';

  @override
  String get obsUsageNoActivity => 'ยังไม่มีการใช้งานโทเค็นที่บันทึก';

  @override
  String get obsUsageOtherModels => 'อื่นๆ';

  @override
  String obsUsageCellReadout(String date, String tokens) {
    return '$date · $tokens โทเค็น';
  }

  @override
  String obsUsageActivitySummary(
    String start,
    String end,
    int activeDays,
    String peak,
  ) {
    return 'กิจกรรมโทเค็นจาก $start ถึง $end $activeDays วันที่ใช้งาน วันที่ยุ่งสุด $peak โทเค็น';
  }

  @override
  String get obsScreenSubtitle =>
      'การควบคุมเอเจนต์แบบสด การระบุค่าใช้จ่าย โควตา และสัญญาณคุณภาพ';

  @override
  String get obsRangeLast24h => '24 ชั่วโมงที่แล้ว';

  @override
  String get obsRangeLast7d => '7 วันที่แล้ว';

  @override
  String get obsRangeLast30d => '30 วันที่แล้ว';

  @override
  String get obsRangeAll => 'ทั้งหมด';

  @override
  String get obsAddFilter => 'เพิ่มตัวกรอง';

  @override
  String get obsFilterAgent => 'เอเจนต์';

  @override
  String get obsFilterModel => 'โมเดล';

  @override
  String get obsFilterStatus => 'สถานะ';

  @override
  String get obsFilterRole => 'บทบาท';

  @override
  String get obsKpiTotalRuns => 'รันทั้งหมด';

  @override
  String get obsKpiTotalCost => 'ค่าใช้จ่ายทั้งหมด';

  @override
  String get obsKpiErrorRate => 'อัตราข้อผิดพลาด';

  @override
  String get obsKpiCacheRate => 'อัตราแคช';

  @override
  String get obsKpiTokensPerSec => 'โทเค็น / วินาที';

  @override
  String get obsKpiAvgLatency => 'ความหน่วงเฉลี่ย';

  @override
  String get obsKpiTtft => 'เวลาถึงโทเค็นแรก';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '$delta เทียบช่วงก่อน';
  }

  @override
  String get obsChartActivity => 'กิจกรรม';

  @override
  String get obsChartCost => 'ค่าใช้จ่ายตามเวลา';

  @override
  String get obsLegendRuns => 'รัน';

  @override
  String get obsLegendErrors => 'ข้อผิดพลาด';

  @override
  String get obsAgentsTitle => 'เอเจนต์';

  @override
  String obsShowAllAgents(int count) {
    return 'แสดงเอเจนต์ทั้งหมด $count ตัว';
  }

  @override
  String get obsShowFewerAgents => 'แสดงน้อยลง';

  @override
  String get obsRunsTitle => 'รัน';

  @override
  String get obsNoRunsInRange => 'ไม่มีรันในช่วงนี้';

  @override
  String get obsColTime => 'เวลา';

  @override
  String get obsColAgent => 'เอเจนต์';

  @override
  String get obsColStatus => 'สถานะ';

  @override
  String get obsColModel => 'โมเดล';

  @override
  String get obsColDuration => 'ระยะเวลา';

  @override
  String get obsColTokens => 'โทเค็น';

  @override
  String get obsColCost => 'ค่าใช้จ่าย';

  @override
  String get obsColErrors => 'ข้อผิดพลาด';

  @override
  String get obsColRuns => 'รัน';

  @override
  String get obsColAvgLatency => 'ความหน่วงเฉลี่ย';

  @override
  String get obsColLastActive => 'ใช้งานล่าสุด';

  @override
  String get obsStatusPending => 'รอดำเนินการ';

  @override
  String get obsStatusRunning => 'กำลังรัน';

  @override
  String get obsStatusCompleted => 'เสร็จแล้ว';

  @override
  String get obsStatusError => 'ข้อผิดพลาด';

  @override
  String get obsRosterLoadError => 'โหลดรายชื่อเอเจนต์ไม่ได้';

  @override
  String get obsRosterEmpty => 'ยังไม่มีเอเจนต์';

  @override
  String get obsRosterEmptyDescription =>
      'จัดส่งเอเจนต์แล้วจะปรากฏที่นี่แบบสด — สถานะ เครื่องมือปัจจุบัน โทเค็น ค่าใช้จ่าย';

  @override
  String get obsKillAgent => 'ฆ่าเอเจนต์';

  @override
  String get obsRosterTokensLabel => 'tok';

  @override
  String get obsCostByRoleTitle => 'ค่าใช้จ่ายตามบทบาท';

  @override
  String get obsCostByRoleSubtitle =>
      'เวิร์กสเปซนี้ใช้จ่ายที่ไหน ตามบทบาทเอเจนต์';

  @override
  String get obsRoleMain => 'หลัก';

  @override
  String get obsRoleSubagents => 'ซับเอเจนต์';

  @override
  String get obsRoleAdvisor => 'ที่ปรึกษา';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return 'หลัก: $main · ซับเอเจนต์: $sub · ที่ปรึกษา: $advisor';
  }

  @override
  String get obsTotal => 'ทั้งหมด';

  @override
  String get obsTokenModelTitle => 'โมเดลโทเค็น (5 แกน)';

  @override
  String get obsTokenModelSubtitle => 'ทุกโทเค็นที่เวิร์กสเปซนี้ใช้ ตามแกน';

  @override
  String get obsAxisInput => 'อินพุต';

  @override
  String get obsAxisOutput => 'เอาต์พุต';

  @override
  String get obsAxisReasoning => 'การให้เหตุผล';

  @override
  String get obsAxisCacheRead => 'อ่านแคช';

  @override
  String get obsAxisCacheWrite => 'เขียนแคช';

  @override
  String get obsTotalTokens => 'โทเค็นทั้งหมด';

  @override
  String get obsCacheDiscountNote =>
      'โทเค็นอ่านแคชถูกคิดเงินในอัตราส่วนลด จึงถูกกว่าอินพุตใหม่ในปริมาณเดียวกันมาก';

  @override
  String get obsByModelTitle => 'ตามโมเดล';

  @override
  String get obsByModelSubtitle => 'การใช้โทเค็นและค่าใช้จ่ายต่อโมเดล';

  @override
  String get obsNoModelUsage => 'ยังไม่มีการใช้งานโมเดลที่บันทึก';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count รัน',
      one: '1 รัน',
    );
    return '$_temp0';
  }

  @override
  String get obsPerRunTitle => 'ต่อรัน';

  @override
  String get obsPerRunSubtitle => 'ค่าโทเค็นโดยทั่วไปของรันเดียว';

  @override
  String get obsMedianRunTokens => 'โทเค็นรันมัธยฐาน';

  @override
  String get obsMedianRunTokensSub => 'จุดกลางของทุกรัน';

  @override
  String get obsRunsInWorkspace => 'ในเวิร์กสเปซนี้';

  @override
  String get obsCostShare => 'ส่วนแบ่งค่าใช้จ่าย';

  @override
  String get obsQuotaConfiguredLimits => 'ขีดจำกัดที่ตั้งไว้';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      'การใช้งานเทียบเพดานที่คุณตั้ง สถานะแย่สุดก่อน';

  @override
  String get obsQuotaAddLimit => 'เพิ่มขีดจำกัด';

  @override
  String get obsQuotaNoLimits =>
      'ยังไม่ได้ตั้งขีดจำกัดโควตา — เพิ่มหนึ่งรายการเพื่อติดตามการใช้งานเทียบเพดาน';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return 'ลบขีดจำกัด $title';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return 'รีเซ็ตใน $duration · $status';
  }

  @override
  String get obsQuotaUsageWindows => 'หน้าต่างการใช้งาน';

  @override
  String get obsQuotaUsageWindowsSubtitle =>
      'การใช้งานที่สังเกตได้จากผู้ให้บริการทั้งหมด ไม่ใช้เพดาน';

  @override
  String get obsQuotaNoUsage => 'ยังไม่มีการใช้งานที่บันทึก';

  @override
  String get obsQuotaTokensUsed => 'โทเค็นที่ใช้';

  @override
  String get obsQuotaRequests => 'คำขอ';

  @override
  String get obsQuotaUnitTokens => 'โทเค็น';

  @override
  String get obsQuotaUnitRequests => 'คำขอ';

  @override
  String get obsQuotaUnitCost => 'ค่าใช้จ่าย';

  @override
  String get obsQuotaAddLimitTitle => 'เพิ่มขีดจำกัดโควตา';

  @override
  String get obsQuotaProviderLabel => 'ผู้ให้บริการ';

  @override
  String get obsQuotaWindowLabel => 'หน้าต่าง';

  @override
  String get obsQuotaUnitLabel => 'หน่วย';

  @override
  String obsQuotaLimitLabel(String unit) {
    return 'ขีดจำกัด ($unit)';
  }

  @override
  String get obsQuotaCentsHint => 'เป็นเซนต์สหรัฐ (500 = \$5.00)';

  @override
  String get obsQuotaStatusOk => 'ปกติ';

  @override
  String get obsQuotaStatusWarning => 'คำเตือน';

  @override
  String get obsQuotaStatusExhausted => 'หมดแล้ว';

  @override
  String get obsQuotaStatusUnknown => 'ไม่ทราบ';

  @override
  String get obsGoalNoActiveTitle => 'ไม่มีเป้าหมายที่ใช้งาน';

  @override
  String get obsGoalNoActiveBody =>
      'ตั้งเป้าหมายเพื่อให้อีเจนต์มีวัตถุประสงค์และงบโทเค็นไม่บังคับ เมื่อรันเสร็จ งบจะเต็มและเอเจนต์ถูกกระตุ้นให้ปิดงานเมื่อใกล้หมด';

  @override
  String get obsGoalSetGoal => 'ตั้งเป้าหมาย';

  @override
  String get obsGoalTokenBudget => 'งบโทเค็น';

  @override
  String obsGoalTokensLeft(String tokens) {
    return 'เหลือ $tokens';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens (ไม่ได้ตั้งงบ)';
  }

  @override
  String get obsGoalTokensUsed => 'โทเค็นที่ใช้';

  @override
  String get obsGoalElapsed => 'ผ่านไปแล้ว';

  @override
  String get obsGoalWrapUp => 'ปิดงาน';

  @override
  String get obsGoalClear => 'ล้างเป้าหมาย';

  @override
  String get obsGoalFallbackTitle => 'เป้าหมาย';

  @override
  String get obsGoalSubtitle => 'งบโหมดเป้าหมาย';

  @override
  String get obsGoalStatusActive => 'ใช้งานอยู่';

  @override
  String get obsGoalStatusPaused => 'หยุดชั่วคราว';

  @override
  String get obsGoalStatusBudgetLimited => 'จำกัดงบ';

  @override
  String get obsGoalStatusComplete => 'เสร็จแล้ว';

  @override
  String get obsGoalStatusDropped => 'ยกเลิกแล้ว';

  @override
  String get obsGoalObjectiveLabel => 'วัตถุประสงค์';

  @override
  String get obsGoalBudgetLabel => 'งบโทเค็น (ไม่บังคับ)';

  @override
  String get obsGoalSetAction => 'ตั้งเป้าหมาย';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => '% สำเร็จ';

  @override
  String get obsBenchmarkPassed => 'ผ่าน';

  @override
  String get obsBenchmarkFailed => 'ล้มเหลว';

  @override
  String get obsBenchmarkErrors => 'ข้อผิดพลาด';

  @override
  String get obsBenchmarkSpend => 'ใช้จ่าย';

  @override
  String get obsBenchmarkCostPerTask => 'ค่าใช้จ่าย / งาน';

  @override
  String get obsBenchmarkTrials => 'การทดลอง';

  @override
  String get obsBenchmarkNoTrials => 'ยังไม่มีรันให้ให้คะแนน';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'และอีก $count',
      one: 'และอีก 1',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => 'ผ่าน';

  @override
  String get obsBenchmarkTrialFail => 'ไม่ผ่าน';

  @override
  String get obsBenchmarkTrialError => 'ข้อผิดพลาด';

  @override
  String get obsBenchmarkTrialRunning => 'กำลังรัน';

  @override
  String get obsBenchmarkReward => 'รางวัล';

  @override
  String get obsBenchmarkReport => 'รายงาน';

  @override
  String get obsBenchmarkCopyMarkdown => 'คัดลอก markdown';

  @override
  String get obsBenchmarkCopied => 'คัดลอกรายงานไปคลิปบอร์ดแล้ว';

  @override
  String get obsBehaviorCaption =>
      'สัญญาณความหงุดหงิดที่แยกจากข้อความของคุณเอง — เป็นการอ่านสุขภาพการสนทนา ไม่ใช่คะแนนของเอเจนต์ คำนวณในเครื่อง ไม่มีอะไรออกจากอุปกรณ์นี้';

  @override
  String get obsBehaviorMessagesAnalyzed => 'ข้อความที่วิเคราะห์';

  @override
  String get obsBehaviorTotalSignals => 'สัญญาณทั้งหมด';

  @override
  String get obsBehaviorYelling => 'ตะโกน';

  @override
  String get obsBehaviorProfanity => 'คำหยาบ';

  @override
  String get obsBehaviorAnguish => 'ความทุกข์';

  @override
  String get obsBehaviorNegation => 'การปฏิเสธ';

  @override
  String get obsBehaviorRepetition => 'การซ้ำ';

  @override
  String get obsBehaviorBlame => 'การตำหนิ';

  @override
  String get obsBehaviorConversationsTitle => 'การสนทนาที่หงุดหงิดที่สุด';

  @override
  String get obsBehaviorConversationsSubtitle =>
      'เรียงตามความหนาแน่นของสัญญาณในข้อความของคุณ';

  @override
  String get obsBehaviorNoSignals => 'ไม่พบสัญญาณความหงุดหงิด — ราบรื่นดี';

  @override
  String obsBehaviorMessagesCount(String count) {
    return 'วิเคราะห์ข้อความแล้ว $count รายการ';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '$count สัญญาณ';
  }

  @override
  String get obsAgentStatusIdle => 'ว่าง';

  @override
  String get obsAgentStatusParked => 'จอดไว้';

  @override
  String get obsAgentStatusAborted => 'ยกเลิกแล้ว';

  @override
  String get obsAgentKindSub => 'ซับ';

  @override
  String get noChecksOnCommit => 'ยังไม่มีการตรวจที่รันบนคอมมิตนี้';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'กำลังรัน — $count งาน',
      one: 'กำลังรัน — 1 งาน',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'การตรวจผ่านทั้งหมด — $count งาน',
      one: 'การตรวจผ่านทั้งหมด — 1 งาน',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เสร็จแล้ว — $count งาน',
      one: 'เสร็จแล้ว — 1 งาน',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total งาน',
      one: '1 งาน',
    );
    return '$failed จาก $_temp0 ไม่ผ่าน';
  }

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count งาน',
      one: '1 งาน',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return 'Matrix: $jobId';
  }

  @override
  String get jobLogsPending => 'บันทึกจะปรากฏที่นี่เมื่องานเสร็จ';

  @override
  String get jobLogsUnavailable => 'บันทึกใช้ไม่ได้สำหรับงานนี้';

  @override
  String get noLogsForStep => 'ไม่มีบันทึกที่จับได้สำหรับขั้นตอนนี้';

  @override
  String get jobLogsTruncated => 'บันทึกถูกตัด — แสดงเอาต์พุตล่าสุด';

  @override
  String get fullLog => 'บันทึกเต็ม';

  @override
  String get copyLogs => 'คัดลอกบันทึก';

  @override
  String get resizeGraph => 'ลากเพื่อปรับขนาดกราฟ';

  @override
  String workflowRunStartedAgo(String time) {
    return 'เริ่มเมื่อ $time';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return 'เสร็จเมื่อ $time';
  }

  @override
  String get chatBridgesTitle => 'สะพานแชท';

  @override
  String chatProviderDescription(String provider, String command) {
    return 'กล่าวถึงบอทใน $provider เพื่อให้อีเจนต์ทำอะไร หรือเปิดตั๋วงานด้วย $command';
  }

  @override
  String chatConnectProvider(String provider) {
    return 'เชื่อมต่อ $provider';
  }

  @override
  String get chatDisconnectProvider => 'ยกเลิกการเชื่อมต่อ';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$botName ใน $teamName';
  }

  @override
  String get chatStateLive => 'สด';

  @override
  String get chatStateConnecting => 'กำลังเชื่อมต่อ…';

  @override
  String get chatStateError => 'ข้อผิดพลาดการเชื่อมต่อ';

  @override
  String get chatNotConnected => 'ยังไม่เชื่อมต่อ';

  @override
  String chatStreamingUnavailable(String provider) {
    return 'สตรีมสดปิดสำหรับแอป $provider นี้ — คำตอบมาเป็นข้อความเดียว';
  }

  @override
  String chatAdminOnly(String provider) {
    return 'เฉพาะแอดมินเชื่อมต่อ $provider สำหรับเวิร์กสเปซนี้ได้';
  }

  @override
  String chatConnectHint(String provider) {
    return 'สร้างแอป $provider แล้ววางข้อมูลรับรองที่นี่ Control Center เชื่อมออกไปยัง $provider ดังนั้นเซิร์ฟเวอร์นี้ไม่ต้องมีที่อยู่สาธารณะ';
  }

  @override
  String chatOpenConsole(String provider) {
    return 'เปิดคอนโซล $provider';
  }

  @override
  String get chatOpenSetupGuide => 'คู่มือตั้งค่า';

  @override
  String get chatFieldBotToken => 'โทเค็นบอท';

  @override
  String get chatFieldAppToken => 'โทเค็นระดับแอป';

  @override
  String get chatFieldConfigRefreshToken => 'โทเค็นการตั้งค่าแอป';

  @override
  String chatFieldOptional(String label) {
    return '$label (ไม่บังคับ)';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return 'ลิงก์บัญชี $provider ของฉัน';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return 'ลิงก์บัญชี $provider ของคุณเพื่อให้ข้อความที่คุณส่งที่นั่นถูกระบุว่าเป็นของคุณ';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return 'ลิงก์กับ $externalUserId';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return 'ลิงก์บัญชี $provider ของคุณ';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return 'ส่งคำสั่งนี้ถึงบอทใน $provider ใช้ได้ครั้งเดียวและหมดอายุใน 15 นาที';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return 'บัญชี $provider ของคุณลิงก์แล้ว — ข้อความที่คุณส่งที่นั่นถูกระบุว่าเป็นของคุณ';
  }

  @override
  String get chatLinkedAccounts => 'บัญชีที่ลิงก์';

  @override
  String chatNoLinkedAccounts(String provider) {
    return 'ยังไม่มีใครลิงก์บัญชี $provider ของตน';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count บัญชีที่ลิงก์',
      one: '1 บัญชีที่ลิงก์',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '$externalUserId · จับคู่ด้วยอีเมล';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '$externalUserId · ลิงก์ด้วยรหัส';
  }

  @override
  String get chatUnlink => 'เลิกลิงก์';

  @override
  String get chatCustomizeBot => 'ปรับแต่งบอท';

  @override
  String get chatCustomizeBotDescription =>
      'เปลี่ยนชื่อบอท เปลี่ยนสิ่งที่มันพูดเกี่ยวกับตัวเอง หรือเปลี่ยนชื่อคำสั่งสแลช';

  @override
  String get chatCustomizeBotUnavailable =>
      'Control Center ต้องมีโทเค็นการตั้งค่าแอปเพื่อแก้ไขบอท เชื่อมต่อใหม่และใส่หนึ่งอัน';

  @override
  String chatCreateAppTitle(String provider) {
    return 'สร้างแอป $provider';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'Control Center สร้างแอป $provider ให้คุณได้ พร้อมสิทธิ์และเหตุการณ์ที่ถูกต้อง คุณจะทำต่อใน $provider แล้ววางข้อมูลรับรองที่นี่';
  }

  @override
  String get chatCreateApp => 'สร้างแอป';

  @override
  String get chatCreateAppCta => 'สร้างแอปให้ฉัน';

  @override
  String get chatAppNameLabel => 'ชื่อแอป';

  @override
  String get chatBotDisplayNameLabel => 'ชื่อบอท (สิ่งที่สมาชิกพิมพ์หลัง @)';

  @override
  String get chatDescriptionLabel => 'คำอธิบายสั้น';

  @override
  String get chatAgentDescriptionLabel => 'สิ่งที่บอทบอกว่าทำได้';

  @override
  String get chatCommandLabel => 'คำสั่งสแลช';

  @override
  String get chatDirectMessages => 'ข้อความตรง';

  @override
  String chatDirectMessagesHint(String provider) {
    return 'ให้สมาชิกแชทกับบอทใน DM อาจต้องใช้แผน $provider แบบชำระเงิน';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return '$provider สร้างแอป $appId แล้ว';
  }

  @override
  String chatRemainingSteps(String provider) {
    return 'เหลืออีกไม่กี่ขั้นตอนและมีเพียง $provider ที่ทำได้:';
  }

  @override
  String get chatStepAppToken => 'สร้างโทเค็นระดับแอป';

  @override
  String get chatStepInstall => 'ติดตั้งแอป';

  @override
  String get chatOpenAppSettings => 'เปิดการตั้งค่าแอป';

  @override
  String get chatContinueToCredentials => 'วางข้อมูลรับรอง';

  @override
  String chatBotUpdated(String provider) {
    return 'อัปเดตบอทใน $provider แล้ว';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return '$provider เปลี่ยนสิทธิ์ของแอป ติดตั้งแอปใหม่เพื่อให้มีผล';
  }

  @override
  String get chatReinstallApp => 'ติดตั้งแอปใหม่';

  @override
  String chatIconNotEditable(String provider) {
    return 'ไอคอนของบอทเปลี่ยนได้เฉพาะในการตั้งค่าแอปของ $provider เอง';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return 'คุณสร้างใน $provider เองก็ได้ — ไม่ต้องใช้โทเค็น การตั้งค่าด้านบนเดินทางไปกับลิงก์';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return 'สร้างใน $provider';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return '$provider เปิดในเบราว์เซอร์พร้อมการตั้งค่านี้กรอกไว้แล้ว สร้างแอปที่นั่น แล้วทำขั้นตอนเหล่านี้ให้เสร็จและกลับมาพร้อมโทเค็น';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return '$provider ไม่รายงานว่าสร้างแอปใด ดังนั้นการปรับแต่งบอทจากที่นี่ต้องมีโทเค็นการตั้งค่าแอปภายหลัง';
  }

  @override
  String get chatStepCreateApp => 'สร้างแอปจากการตั้งค่าที่กรอกไว้';

  @override
  String chatStepCreateAppHint(String provider) {
    return 'เลือกเวิร์กสเปซใน $provider แล้วยืนยัน';
  }

  @override
  String get chatStepAppTokenHint =>
      'Basic information → app-level tokens พร้อมขอบเขต connections:write';

  @override
  String get chatStepInstallHint => 'Install app → คัดลอก bot user OAuth token';

  @override
  String get calendarUseBuiltinApp => 'ใช้แอป Google ของ Control Center';

  @override
  String get calendarUseBuiltinAppHint =>
      'อนุมัติด้วยบัญชี Google ของคุณ ไม่ต้องตั้งอะไรใน Google Cloud';

  @override
  String get calendarUseOwnClient => 'ใช้ไคลเอนต์ Google Cloud ของฉันเอง';

  @override
  String get calendarUseOwnClientHint =>
      'ใส่ไคลเอนต์ OAuth จากโปรเจกต์ Google Cloud ของคุณเอง';

  @override
  String get aboutTitle => 'เกี่ยวกับ';

  @override
  String get aboutAppVersion => 'เวอร์ชันแอป';

  @override
  String get aboutServerVersion => 'เซิร์ฟเวอร์ที่เชื่อมต่อ';

  @override
  String get aboutRpcCatalog => 'แคตตาล็อก RPC';

  @override
  String get aboutServerUnknown => 'ไม่ได้รายงาน';

  @override
  String get serverStaleTitle => 'เซิร์ฟเวอร์ที่มาพร้อมกันเก่ากว่าแอปนี้';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return 'cc_server ที่รันอยู่คือ $serverVersion ในขณะที่แอปนี้คือ $appVersion รีสตาร์ทแอปเพื่อใช้บิลด์เซิร์ฟเวอร์ล่าสุดที่มาพร้อมกัน ในการพัฒนา ให้สร้างใหม่ด้วย `dart build cli` ใน apps/cc_server';
  }

  @override
  String get updateCheckButton => 'ตรวจหาอัปเดต';

  @override
  String get updateChecking => 'กำลังตรวจหาอัปเดต…';

  @override
  String get updateUpToDate => 'คุณใช้เวอร์ชันล่าสุดแล้ว';

  @override
  String get updateDeferredBusy =>
      'มีอัปเดตพร้อมแต่กำลังบันทึกการประชุม — จะถามหลังจบ';

  @override
  String get updateOpenedReleasesPage => 'เปิดหน้าเผยแพร่ในเบราว์เซอร์แล้ว';

  @override
  String get updateCheckFailed => 'ตรวจหาอัปเดตไม่สำเร็จ';

  @override
  String updateAvailableVersion(String version) {
    return 'มีเวอร์ชัน $version ให้ใช้';
  }

  @override
  String get updateBannerTitle => 'มี Control Center เวอร์ชันใหม่';

  @override
  String get updateBannerRefresh => 'รีเฟรช';

  @override
  String get updateBlockedRecording =>
      'การรีเฟรชถูกพักขณะบันทึกการประชุม — จะโหลดใหม่เมื่อจบ';

  @override
  String get settingsScopeYou => 'คุณ';

  @override
  String get settingsScopeWorkspace => 'เวิร์กสเปซ';

  @override
  String get settingsScopeServer => 'เซิร์ฟเวอร์';

  @override
  String get settingsProfile => 'โปรไฟล์และตัวตน';

  @override
  String get settingsYourDevices => 'อุปกรณ์ของคุณ';

  @override
  String get settingsWorkspaceGeneral => 'ทั่วไป';

  @override
  String get settingsServerConnection => 'การเชื่อมต่อและสถานะ';

  @override
  String get settingsModelProviders => 'ผู้ให้บริการโมเดล';

  @override
  String get settingsVoiceModels => 'โมเดลเสียงและการประชุม';

  @override
  String get settingsDiagnostics => 'การวินิจฉัยและความเป็นส่วนตัว';

  @override
  String get settingsAbout => 'เกี่ยวกับ';

  @override
  String get settingsScopeBadgeYou => 'คุณ';

  @override
  String get settingsScopeBadgeDevice => 'อุปกรณ์นี้';

  @override
  String get settingsScopeBadgeWorkspace => 'เวิร์กสเปซ';

  @override
  String get settingsScopeBadgeServer => 'เซิร์ฟเวอร์';

  @override
  String get settingsProfileDescription =>
      'ชื่อ อีเมล และตัวตน git ของคุณในพื้นที่นี้ การเปลี่ยนพื้นที่เปลี่ยนเลเยอร์นี้ แฮนเดิล การเข้าสู่ระบบ และอุปกรณ์ยังอยู่ที่บัญชี';

  @override
  String get settingsServerConnectionDescription =>
      'เซิร์ฟเวอร์ที่ไคลเอนต์นี้คุยด้วย และวิธีที่เซิร์ฟเวอร์นี้ถูกแชร์ (mDNS, ทันเนล, รีเลย์)';

  @override
  String get settingsAboutDescription => 'ตัวตนของบิลด์และอัปเดต';

  @override
  String get settingsDiagnosticsDescription =>
      'การแยก การจัดทำดัชนี การซิงค์ การบันทึก และรายงานข้อขัดข้องของการติดตั้งนี้';

  @override
  String get settingsWorkspaceGeneralDescription =>
      'ตัวตน นโยบาย และธรรมเนียมที่ทุกคนในเวิร์กสเปซนี้ใช้ร่วมกัน';

  @override
  String get settingsWorkspaceMeetingsDescription =>
      'แม่แบบบันทึกและเสียงที่บันทึกไว้สำหรับการประชุมในเวิร์กสเปซนี้';

  @override
  String get settingsWorkspacePolicyLabel => 'นโยบายเวิร์กสเปซ';

  @override
  String get settingsWorkspacePolicyDescription =>
      'มีผลกับทุกสมาชิกและทุกเอเจนต์ในเวิร์กสเปซนี้';

  @override
  String get settingsSecretGlobsLabel => 'การยกเว้นพาธความลับ';

  @override
  String get settingsSecretGlobsHelp =>
      'glob บรรทัดละหนึ่ง พาธเหล่านี้ถูกซ่อนจากผู้ดูและแขกบนพื้นผิวที่มีโค้ด นอกเหนือจากค่าเริ่มต้นในตัว';

  @override
  String get settingsReviewConcurrencyLabel => 'การกระจายรีวิว';

  @override
  String get settingsReviewConcurrencyHelp =>
      'ผู้รีวิวกี่คนถูกจัดส่งขนานเมื่อไม่ได้ระบุจำนวน';

  @override
  String get settingsReviewLevelLabel => 'ระดับรีวิว';

  @override
  String get settingsReviewLevelHelp =>
      'รีวิว AI ลึกแค่ไหน และรายงานสิ่งที่พบล่วงหน้ามากแค่ไหน ไม่มีอะไรถูกทิ้ง — ระดับเบากว่าจะจัดกลุ่มข้อค้นพบเล็กแทนการตัดทิ้ง';

  @override
  String get reviewLevelLight => 'เบา';

  @override
  String get reviewLevelBalanced => 'สมดุล';

  @override
  String get reviewLevelThorough => 'ละเอียด';

  @override
  String get reviewLevelLightHint =>
      'ผู้รีวิวหนึ่งคน รายงานล่วงหน้าเฉพาะสิ่งที่สำคัญจริง';

  @override
  String get reviewLevelBalancedHint =>
      'ผู้รีวิวสามคนครอบคลุม QA สถาปัตยกรรม และการใช้งาน';

  @override
  String get reviewLevelThoroughHint =>
      'เพิ่มผู้เชี่ยวชาญด้านความปลอดภัยและประสิทธิภาพ และรายงานทุกอย่างที่พบ';

  @override
  String get askAiReviewAtLevel => 'รีวิวที่ระดับอื่น';

  @override
  String reviewNitpicksGroup(int count) {
    return 'ข้อจิ๊บจ๊อย ($count)';
  }

  @override
  String get reviewFindingResolve => 'แก้แล้ว';

  @override
  String get reviewFindingResolveHint =>
      'ทำเครื่องหมายข้อค้นพบนี้ว่าแก้แล้ว จะไม่นับกับรีวิว';

  @override
  String get reviewFindingDismiss => 'ปิดทิ้ง';

  @override
  String get reviewFindingDismissHint =>
      'ไม่ใช่ปัญหาจริง ผู้รีวิวจะหยุดชี้รูปแบบนี้บน PR ครั้งหน้า';

  @override
  String get reviewFindingReopen => 'เปิดอีกครั้ง';

  @override
  String get reviewFindingStatusUndoLabel => 'สถานะข้อค้นพบ';

  @override
  String get reviewFindingDismissTitle => 'ปิดทิ้งข้อค้นพบนี้';

  @override
  String get reviewFindingDismissReasonHint => 'ทำไมจึงไม่ใช้? ผู้รีวิวจะอ่าน';

  @override
  String reviewFindingStatusFailed(String error) {
    return 'อัปเดตข้อค้นพบไม่ได้: $error';
  }

  @override
  String get reviewStaleTitle => 'รีวิวนี้ล้าสมัย';

  @override
  String get reviewStaleBody =>
      'pull request เดินหน้าไปตั้งแต่รีวิวนี้รัน ข้อค้นพบอาจชี้โค้ดที่ไม่มีแล้ว';

  @override
  String reviewStaleReviewedAt(String sha) {
    return 'รีวิวที่ $sha';
  }

  @override
  String get reviewStaleRerun => 'รีวิวอีกครั้ง';

  @override
  String reviewStaleNotificationTitle(int prNumber) {
    return 'รีวิวล้าสมัยบน #$prNumber';
  }

  @override
  String reviewStaleNotificationBody(String title) {
    return '$title มีคอมมิตใหม่ตั้งแต่รีวิวล่าสุด';
  }

  @override
  String get reviewCategorySecurity => 'ความปลอดภัย';

  @override
  String get reviewCategoryStability => 'ความเสถียร';

  @override
  String get reviewCategoryDataIntegrity => 'ความสมบูรณ์ของข้อมูล';

  @override
  String get reviewCategoryCorrectness => 'ความถูกต้อง';

  @override
  String get reviewCategoryPerformance => 'ประสิทธิภาพ';

  @override
  String get reviewCategoryMaintainability => 'การดูแลรักษา';

  @override
  String get reviewEffortQuickWin => 'ได้เร็ว';

  @override
  String get reviewEffortModerate => 'ปานกลาง';

  @override
  String get reviewEffortHeavyLift => 'งานหนัก';

  @override
  String get reviewProposedFix => 'การแก้ไขที่เสนอ';

  @override
  String get reviewAiAgentPrompt => 'พรอมต์สำหรับเอเจนต์ AI';

  @override
  String get reviewCopyAiPrompt => 'คัดลอกพรอมต์';

  @override
  String get settingsWorkspaceAdminOnly =>
      'เฉพาะแอดมินเวิร์กสเปซเปลี่ยนสิ่งเหล่านี้ได้';

  @override
  String get chatMyAccountsTitle => 'บัญชีแชทที่ลิงก์';

  @override
  String get settingsServerSso => 'ลงชื่อเข้าใช้ครั้งเดียว';

  @override
  String get settingsServerSsoDescription =>
      'การลงชื่อเข้าใช้ SAML และ OpenID Connect พร้อมการจัดหาผู้ใช้';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabledDescription =>
      'ผู้ใช้ลงชื่อเข้าใช้ด้วยผู้ให้บริการนี้ได้';

  @override
  String get ssoEnabledDescriptionOn =>
      'การลงชื่อเข้าใช้ทำงานสำหรับผู้ให้บริการนี้';

  @override
  String get ssoIdpMetadataLabel => 'IdP metadata XML';

  @override
  String get ssoIdpMetadataHint => 'วาง EntityDescriptor XML ของ IdP';

  @override
  String get ssoEmailAttributeLabel => 'แอตทริบิวต์อีเมล';

  @override
  String get ssoDisplayNameAttributeLabel => 'แอตทริบิวต์ชื่อที่แสดง';

  @override
  String get ssoGroupsAttributeLabel => 'แอตทริบิวต์กลุ่ม';

  @override
  String get ssoIssuerLabel => 'URL ผู้ออก';

  @override
  String get ssoClientIdLabel => 'Client ID';

  @override
  String get ssoGroupsClaimLabel => 'เคลมกลุ่ม';

  @override
  String get ssoAutoMemberLabel =>
      'เพิ่มผู้ใช้เข้าทุกเวิร์กสเปซเมื่อลงชื่อเข้าใช้ครั้งแรก';

  @override
  String get ssoAutoMemberDescription => 'ปิดเพื่อต้องมีคำเชิญต่อเวิร์กสเปซ';

  @override
  String get ssoAllowJitLabel =>
      'จัดหาผู้ใช้ที่ไม่รู้จักเมื่อลงชื่อเข้าใช้ครั้งแรก';

  @override
  String get ssoAllowJitDescription =>
      'ปิดเพื่อปฏิเสธผู้ใช้ที่ไม่มีบัญชีอยู่แล้ว';

  @override
  String get ssoAllowIdpInitiatedLabel =>
      'รับการลงชื่อเข้าใช้ที่ไม่ถูกขอ (IdP เป็นผู้เริ่ม)';

  @override
  String get ssoAllowIdpInitiatedDescription =>
      'เข้มงวดสำหรับพอร์ทัล IdP ที่เปิดแอปโดยตรง';

  @override
  String get ssoWantResponseSignedLabel => 'ต้องมีซองคำตอบที่ลงนาม';

  @override
  String get ssoWantResponseSignedDescription => 'ต้องมีลายเซ็น assertion เสมอ';

  @override
  String get ssoTestConnectionButton => 'ทดสอบการเชื่อมต่อ';

  @override
  String get ssoTestConnectionOk => 'การเชื่อมต่อใช้งานได้:';

  @override
  String get ssoCopySpMetadata => 'คัดลอก SP metadata';

  @override
  String get ssoCopySpMetadataDone => 'คัดลอก SP metadata ไปคลิปบอร์ดแล้ว';

  @override
  String get ssoSavedToast => 'บันทึกการตั้งค่าลงชื่อเข้าใช้ครั้งเดียวแล้ว';

  @override
  String get ssoUnavailable =>
      'เซิร์ฟเวอร์นี้ไม่เปิดเผยการตั้งค่าลงชื่อเข้าใช้ครั้งเดียว อัปเดตไบนารีเซิร์ฟเวอร์แล้วลองอีกครั้ง';

  @override
  String get ssoScimCardTitle => 'การจัดหาผู้ใช้ (SCIM)';

  @override
  String get ssoScimDescription =>
      'ชี้ตัวเชื่อม SCIM ของผู้ให้บริการตัวตนไปยังเอนด์พอยต์ด้านล่างด้วย bearer token การเพิกถอนจะยกเลิกเซสชันและสิทธิ์เวิร์กสเปซภายในไม่กี่วินาที เซิร์ฟเวอร์ต้องเข้าถึงได้โดย IdP (ทันเนลหรือ URL สาธารณะ)';

  @override
  String get ssoScimEndpoint => 'เอนด์พอยต์ SCIM';

  @override
  String get ssoScimEndpointUnknownOrigin =>
      'ตั้ง URL สาธารณะของเซิร์ฟเวอร์หรือเปิดทันเนลก่อน';

  @override
  String get ssoScimRegenerate => 'สร้างโทเค็นใหม่';

  @override
  String get ssoScimRegenerateConfirm =>
      'สร้าง SCIM bearer token ใหม่หรือไม่? โทเค็นก่อนหน้าจะใช้ไม่ไดทันที';

  @override
  String get ssoScimTokenTitle => 'Bearer token';

  @override
  String get ssoScimTokenPresent => 'มีโทเค็นที่กำหนดค่าแล้ว';

  @override
  String get ssoScimTokenAbsent =>
      'ยังไม่มีโทเค็น — สร้างหนึ่งอันเพื่อเปิดใช้ SCIM';

  @override
  String get ssoScimTokenOnce => 'โทเค็น SCIM (แสดงครั้งเดียว)';

  @override
  String ssoSignInWith(String provider) {
    return 'ลงชื่อเข้าใช้ด้วย $provider';
  }

  @override
  String get ssoProbeFailed =>
      'เข้าถึงเซิร์ฟเวอร์นั้นสำหรับการลงชื่อเข้าใช้ครั้งเดียวไม่ได้';

  @override
  String get ssoOpensBrowser => 'เปิดเบราว์เซอร์เพื่อลงชื่อเข้าใช้ให้เสร็จ';

  @override
  String get ssoWaitingForBrowser => 'กำลังรอเบราว์เซอร์ลงชื่อเข้าใช้ให้เสร็จ…';

  @override
  String get ssoBrowserOpenFailed =>
      'เปิดเบราว์เซอร์สำหรับการลงชื่อเข้าใช้ครั้งเดียวไม่ได้';

  @override
  String get ssoUseManualPairing => 'ลงชื่อเข้าใช้ด้วยคำเชิญหรือคีย์จับคู่แทน';

  @override
  String get ssoHideManualPairing => 'ซ่อนการจับคู่ด้วยมือ';

  @override
  String get ssoClientIdHint => 'ไคลเอนต์สาธารณะ (PKCE) — ไม่ต้องใช้ secret';

  @override
  String get ssoClientSecretLabel => 'Client secret (ไม่บังคับ)';

  @override
  String get ssoClientSecretHintUnset =>
      'จำเป็นเฉพาะไคลเอนต์ IdP แบบ confidential';

  @override
  String get ssoClientSecretHintSet => 'มี secret เก็บไว้ — เว้นว่างเพื่อคงไว้';

  @override
  String get ssoPairingToggle =>
      'อนุญาตการจับคู่ด้วยมือ (รหัสเชิญและคีย์จับคู่)';

  @override
  String get ssoPairingToggleDescription =>
      'ปิดเพื่อให้การเข้าร่วมเป็นการลงชื่อเข้าใช้ครั้งเดียวเท่านั้น — อุปกรณ์ใหม่มาผ่าน SSO อุปกรณ์ที่มีอยู่ยังใช้ได้';

  @override
  String get ssoPairConfirmTitle => 'เชื่อมต่อเซิร์ฟเวอร์หรือไม่?';

  @override
  String ssoPairConfirmBody(String server) {
    return 'ข้อมูลรับรองการลงชื่อเข้าใช้สำหรับ $server มาถึง แต่ไม่ได้เริ่มการลงชื่อเข้าใช้จากแอปนี้ เชื่อมต่อเซิร์ฟเวอร์นี้หรือไม่?';
  }

  @override
  String get ssoPairConfirmConnect => 'เชื่อมต่อ';

  @override
  String get ssoPairConfirmCancel => 'ละเว้น';

  @override
  String get forgeConnections => 'โฮสต์โค้ด';

  @override
  String get connect => 'เชื่อมต่อ';

  @override
  String get disconnect => 'ยกเลิกการเชื่อมต่อ';

  @override
  String get notConnected => 'ยังไม่เชื่อมต่อ';

  @override
  String get checkingConnection => 'กำลังตรวจการเชื่อมต่อ…';

  @override
  String get fromEnvironment => 'จากสภาพแวดล้อม';

  @override
  String forgeTokenTitle(String forge) {
    return 'โทเค็น $forge';
  }

  @override
  String get settingsAudio => 'เสียง';

  @override
  String get settingsAudioDescription =>
      'ไมโครโฟน การป้อนด้วยเสียง การตรวจจับการประชุม และเอาต์พุตซาวด์สเคป';

  @override
  String get audioDevicesSection => 'อุปกรณ์เสียง';

  @override
  String get voiceInputBehaviorSection => 'การป้อนด้วยเสียงและการประชุม';

  @override
  String get audioOutputDeviceTitle => 'อุปกรณ์เอาต์พุต';

  @override
  String get audioOutputDefaultHint =>
      'เสียงแอปทั้งหมดเล่นผ่านเอาต์พุตเริ่มต้นของระบบ';

  @override
  String get audioOutputGone =>
      'อุปกรณ์เอาต์พุตที่เลือกไม่ได้เชื่อมต่อแล้ว — ใช้ค่าเริ่มต้นของระบบจนกว่าคุณจะเลือกอันอื่น';

  @override
  String get reviewHubIntroBody =>
      'เอเจนต์วิเคราะห์ diff แผนที่พื้นที่ที่เปลี่ยน และสรุปคำตัดสินร่วม';

  @override
  String get reviewHubAlreadyRunning =>
      'มีรีวิวกำลังรันสำหรับ pull request นี้อยู่แล้ว';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return 'ตั้งแต่รีวิวล่าสุด: ปิดแล้ว $resolved · ใหม่ $added · ยังเปิด $open';
  }

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return 'รีวิวก่อนหน้าที่ $sha';
  }

  @override
  String reviewArtifactFixAll(int count) {
    return 'แก้ข้อค้นพบ $count รายการ';
  }

  @override
  String reviewArtifactFixSelected(int count) {
    return 'แก้ที่เลือก $count รายการ';
  }

  @override
  String reviewArtifactCommentSelected(int count) {
    return 'แสดงความคิดเห็นที่เลือก $count รายการ';
  }

  @override
  String get webConnectTitle => 'เชื่อมต่อ Control Center';

  @override
  String get webConnectSubtitle =>
      'โทรหา cc-server ที่กำลังรันผ่าน WebSocket คีย์ของคุณอยู่บนอุปกรณ์นี้';

  @override
  String get webConnectServerLabel => 'เซิร์ฟเวอร์';

  @override
  String get webConnectDeviceIdLabel => 'ID อุปกรณ์';

  @override
  String get webConnectPairingKeyLabel => 'คีย์จับคู่';

  @override
  String get webConnectPairingKeyHint => 'วาง PSK';

  @override
  String get webConnectStayConnected => 'เชื่อมต่อต่อไปบนอุปกรณ์นี้';

  @override
  String get webConnectStayConnectedDetail =>
      'เชื่อมต่อต่อไปบนอุปกรณ์นี้ (เก็บคีย์ในเบราว์เซอร์นี้)';

  @override
  String failedToCreateWorkspace(String error) {
    return 'สร้างเวิร์กสเปซไม่สำเร็จ: $error';
  }

  @override
  String committedRelative(String relative) {
    return 'คอมมิตเมื่อ $relative';
  }

  @override
  String get selectAgents => 'เลือกเอเจนต์';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count เอเจนต์',
      one: '1 เอเจนต์',
    );
    return '$_temp0';
  }

  @override
  String get newConversation => 'การสนทนาใหม่';

  @override
  String get untitledConversation => 'การสนทนาไม่มีชื่อ';

  @override
  String get conversationTitleOptionalHint =>
      'ไม่บังคับ — เว้นว่างแล้วโมเดลชื่อจะตั้งให้อัตโนมัติ';

  @override
  String get conversationTitlesSectionTitle => 'ชื่อการสนทนา';

  @override
  String get conversationTitlesSectionCaption =>
      'เลือกตัวรันที่ตั้งชื่อการสนทนาใหม่ในเวิร์กสเปซนี้อัตโนมัติ ชื่อจะปิดจนกว่าจะเลือกอะแดปเตอร์ และมีผลกับทุกสมาชิก';

  @override
  String get conversationTitlesModelLabel => 'โมเดลชื่อ';

  @override
  String get conversationTitlesAdapterLabel => 'อะแดปเตอร์';

  @override
  String get conversationTitlesAdapterHint => 'ปิด';

  @override
  String get conversationTitlesAdapterOff => 'ปิด';

  @override
  String get startThread => 'เริ่มเธรด';

  @override
  String get deleteSpaceConfirm => 'ลบสเปซนี้หรือไม่? ข้อความทั้งหมดจะหายไป';

  @override
  String threadTabTitle(String title) {
    return 'เธรด: $title';
  }

  @override
  String threadReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count คำตอบ',
      one: '1 คำตอบ',
    );
    return '$_temp0';
  }

  @override
  String threadLastReply(String time) {
    return 'คำตอบล่าสุด $time';
  }

  @override
  String signInWithProvider(String provider) {
    return 'ลงชื่อเข้าใช้ด้วย $provider';
  }

  @override
  String get signInAgain => 'ลงชื่อเข้าใช้อีกครั้ง';

  @override
  String get signInNotFinished =>
      'การลงชื่อเข้าใช้ยังไม่กลับมา ทำในเบราว์เซอร์ให้เสร็จ แล้วตรวจอีกครั้ง';

  @override
  String get signedOutTitle => 'คุณลงชื่อออกแล้ว';

  @override
  String get signedOutSubtitle =>
      'การเชื่อมต่อโฮสต์โค้ดไม่ถูกต้องแล้ว — โทเค็นหมดอายุ หรือสิทธิ์ถูกเพิกถอน สิ่งอื่นไม่เปลี่ยน: ลงชื่อเข้าใช้อีกครั้งแล้วทุกอย่างอยู่ที่เดิม';

  @override
  String get viaServerApp => 'ผ่านแอปของเซิร์ฟเวอร์นี้';

  @override
  String get ticketing => 'ตั๋วงาน';

  @override
  String get ticketingProviderHelp =>
      'ที่อยู่ของตั๋วงาน Local เก็บไว้ใน Control Center';

  @override
  String providerComingSoon(String provider) {
    return '$provider (เร็วๆ นี้)';
  }

  @override
  String get ticketProviderLocal => 'ในเครื่อง';

  @override
  String get addKey => 'เพิ่มคีย์';

  @override
  String get providerApps => 'แอปผู้ให้บริการ';

  @override
  String get providerAppsDescription =>
      'พื้นที่ทำงานสืบทอด GitHub App นี้ เว้นแต่เลือก App อื่นหรือโทเค็นเข้าถึงส่วนบุคคล งานเบื้องหลัง — เว็บฮุค การสำรวจ การซิงค์ — ทำงานบนแอป ไม่ใช่โทเค็นของบุคคล';

  @override
  String get providerAppId => 'App id';

  @override
  String get providerPrivateKey => 'Private key';

  @override
  String get providerClientId => 'Client id';

  @override
  String get providerClientSecret => 'Client secret';

  @override
  String get providerApiKey => 'คีย์ API';

  @override
  String get providerCallbackUrl => 'Callback URL';

  @override
  String get providerAppFullyConfigured =>
      'เซิร์ฟเวอร์ทำหน้าที่เป็นตัวเองได้ และคนลงชื่อเข้าใช้ได้';

  @override
  String get providerAppServerOnly =>
      'เซิร์ฟเวอร์ทำหน้าที่เป็นตัวเองได้ เพิ่ม client id และ secret เพื่อให้คนลงชื่อเข้าใช้ได้';

  @override
  String get providerAppSignInOnly =>
      'คนลงชื่อเข้าใช้ได้ งานเบื้องหลังถอยไปใช้ข้อมูลรับรองของพวกเขา';

  @override
  String providerAppInstalledOn(String accounts) {
    return 'ข้อมูลรับรองใช้งานได้ ติดตั้งบน: $accounts';
  }

  @override
  String deviceCodeInstructions(String provider) {
    return 'ใส่รหัสนี้บนหน้า $provider ที่เพิ่งเปิด คัดลอกไปคลิปบอร์ดแล้ว';
  }

  @override
  String get deviceCodeWaiting => 'กำลังรอให้คุณทำในเบราว์เซอร์ให้เสร็จ…';

  @override
  String get copyCodeAndOpen => 'คัดลอกรหัสแล้วเปิด';

  @override
  String get couldNotOpenBrowser =>
      'เปิดเบราว์เซอร์ไม่ได้ คัดลอกลิงก์แล้วลงชื่อเข้าใช้เอง';

  @override
  String get contextUsage => 'การใช้บริบท';

  @override
  String get contextUsageFull => 'เต็ม';

  @override
  String get contextUsageTokens => 'โทเค็น';

  @override
  String get contextSeeMore => 'ดูเพิ่ม';

  @override
  String get contextSegmentSystemPrompt => 'พรอมต์ระบบ';

  @override
  String get contextSegmentRules => 'กฎ';

  @override
  String get contextSegmentSkills => 'สกิล';

  @override
  String get contextSegmentToolDefinitions => 'คำจำกัดความเครื่องมือ';

  @override
  String get contextSegmentMcpTools => 'เครื่องมือ MCP และไดนามิก';

  @override
  String get contextSegmentDeferredTools => 'เครื่องมือที่โหลดตามต้องการ';

  @override
  String get contextSegmentSubagents => 'คำจำกัดความซับเอเจนต์';

  @override
  String get contextSegmentMemory => 'หน่วยความจำ';

  @override
  String get contextSegmentConversation => 'การสนทนา';

  @override
  String get contextExplorerTitle => 'บริบท';

  @override
  String get contextExplorerEverything => 'ทุกอย่าง';

  @override
  String get contextExplorerSelectPart => 'เลือกส่วนเพื่อตรวจเนื้อหา';

  @override
  String get contextExplorerUnavailable => 'รายละเอียดบริบทใช้ไม่ได้';

  @override
  String get contextRetry => 'ลองใหม่';

  @override
  String get settingsFieldOptional => 'ไม่บังคับ';

  @override
  String get settingsFilterHint => 'กรองรายการนี้';

  @override
  String get settingsValueNotAvailable => 'ยังไม่พร้อมใช้';

  @override
  String get settingsNoEntriesYet => 'ยังไม่มีอะไรที่นี่';

  @override
  String get settingsChangedBadge => 'เปลี่ยนแล้ว';

  @override
  String get ssoConnectionCardDescription =>
      'เลือกวิธีที่คนลงชื่อเข้าใช้เซิร์ฟเวอร์นี้ แล้วเปิดการเชื่อมต่อนั้น';

  @override
  String get ssoUseSamlForSignIn => 'ใช้ SAML สำหรับลงชื่อเข้าใช้';

  @override
  String get ssoUseOidcForSignIn => 'ใช้ OpenID Connect สำหรับลงชื่อเข้าใช้';

  @override
  String get ssoSaveConnection => 'บันทึกการเชื่อมต่อ';

  @override
  String get ssoStateLive => 'สด';

  @override
  String get ssoStateConfiguredOff => 'กำหนดค่าแล้ว ปิด';

  @override
  String get ssoStateOnIncomplete => 'เปิด ไม่ครบ';

  @override
  String get ssoStateActive => 'ใช้งานอยู่';

  @override
  String get ssoStateAllowed => 'อนุญาตแล้ว';

  @override
  String get ssoStateNoToken => 'ไม่มีโทเค็น';

  @override
  String get ssoSummaryDirectorySync => 'ซิงค์ไดเรกทอรี';

  @override
  String get ssoSummaryManualPairing => 'การจับคู่ด้วยมือ';

  @override
  String get ssoNoMethodLiveNote =>
      'ยังไม่มีวิธีลงชื่อเข้าใช้ที่ทำงาน อุปกรณ์ใหม่เข้าร่วมด้วยคำเชิญหรือคีย์จับคู่จนกว่าคุณจะตั้งการเชื่อมต่อแล้วเปิดใช้';

  @override
  String get ssoMethodSamlBlurb =>
      'สำหรับผู้ให้บริการตัวตนที่พูด SAML 2.0 เช่น Okta, Entra ID หรือ Google Workspace';

  @override
  String get ssoMethodOidcBlurb =>
      'สำหรับผู้ให้บริการตัวตนที่พูด OpenID Connect มักตั้งค่าง่ายกว่าในสองแบบ';

  @override
  String get ssoGroupIdentityProvider => 'ผู้ให้บริการตัวตน';

  @override
  String get ssoGroupIdentityProviderSamlDescription =>
      'assertion มาจากไหน และเซิร์ฟเวอร์นี้ตรวจสอบอย่างไร';

  @override
  String get ssoGroupIdentityProviderOidcDescription =>
      'issuer ใดที่เซิร์ฟเวอร์นี้เชื่อถือ และไคลเอนต์ที่ยืนยันตัวตนเป็น';

  @override
  String get ssoSpEntityIdShortLabel => 'SP entity ID';

  @override
  String get ssoSpEntityIdDescription =>
      'เว้นว่างเพื่อ derive จาก URL ของเซิร์ฟเวอร์';

  @override
  String get ssoIssuerDescription =>
      'URL ฐานที่เสิร์ฟเอกสาร discovery ของผู้ให้บริการ';

  @override
  String get ssoSecretStored => 'เก็บแล้ว';

  @override
  String get ssoGroupHandoff => 'สิ่งที่ผู้ให้บริการตัวตนของคุณต้องการ';

  @override
  String get ssoGroupHandoffDescription =>
      'วางสิ่งเหล่านี้ในแอปพลิเคชันที่คุณสร้างที่ผู้ให้บริการ';

  @override
  String get ssoOriginUnknownTitle => 'เซิร์ฟเวอร์นี้ไม่ทราบ URL สาธารณะ';

  @override
  String get ssoOriginUnknownBody =>
      'URL ลงชื่อเข้าใช้และ callback สร้างจากมัน ดังนั้นผู้ให้บริการเข้าถึงเซิร์ฟเวอร์นี้ไม่ได้จนกว่าจะตั้งค่า เพิ่ม URL สาธารณะหรือเปิดทันเนลที่ เซิร์ฟเวอร์ → การเชื่อมต่อ';

  @override
  String get ssoAcsUrlLabel => 'Assertion consumer service (ACS) URL';

  @override
  String get ssoAcsUrlDescription =>
      'ที่ที่ผู้ให้บริการโพสต์ assertion ที่ลงนาม';

  @override
  String get ssoSpEntityIdResolvedLabel => 'Service provider entity ID';

  @override
  String get ssoMetadataUrlLabel => 'SP metadata URL';

  @override
  String get ssoMetadataUrlDescription =>
      'ผู้ให้บริการที่นำเข้า metadata สามารถดึงจากที่นี่แทน';

  @override
  String get ssoRedirectUriLabel => 'Redirect URI';

  @override
  String get ssoRedirectUriDescription =>
      'เพิ่มสิ่งนี้ใน redirect URI ที่อนุญาตของแอปพลิเคชันผู้ให้บริการ';

  @override
  String get ssoSignInUrlLabel => 'URL ลงชื่อเข้าใช้';

  @override
  String get ssoSignInUrlDescription =>
      'ส่งคนมาที่นี่เพื่อเริ่มลงชื่อเข้าใช้ครั้งเดียว';

  @override
  String get ssoGroupAttributeMapping => 'การจับคู่แอตทริบิวต์';

  @override
  String get ssoGroupAttributeMappingDescription =>
      'เคลมใดถือแต่ละฟิลด์ คงค่าเริ่มต้นไว้เว้นแต่ผู้ให้บริการเปลี่ยนชื่อ';

  @override
  String get ssoGroupAccess => 'การเข้าถึงและบทบาท';

  @override
  String get ssoGroupAccessDescription =>
      'คนที่ลงชื่อเข้าใช้สำเร็จได้รับอนุญาตให้ทำอะไร';

  @override
  String get ssoDefaultRoleShortLabel => 'บทบาทเริ่มต้น';

  @override
  String get ssoDefaultRoleDescription =>
      'ให้กับใครก็ตามที่กลุ่มไม่ตรงกับการจับคู่ด้านล่าง';

  @override
  String get ssoRoleMapShortLabel => 'การจับคู่กลุ่มกับบทบาท';

  @override
  String get ssoRoleMapDescription =>
      'กลุ่มที่ตรงแรกมีผล ไม่สามารถให้บทบาทเจ้าของด้วยวิธีนี้';

  @override
  String get ssoRoleMapGroupHint => 'ชื่อกลุ่มจากผู้ให้บริการของคุณ';

  @override
  String get ssoRoleMapAdd => 'เพิ่มการจับคู่';

  @override
  String get ssoRoleMapEmpty => 'ไม่มีการจับคู่ — ทุกคนได้บทบาทเริ่มต้น';

  @override
  String get ssoAdvancedSummary =>
      'ความคลาดเคลื่อนนาฬิกา การลงชื่อเข้าใช้ที่ IdP เป็นผู้เริ่ม นโยบายลายเซ็น';

  @override
  String get ssoClockSkewShortLabel => 'ความคลาดเคลื่อนนาฬิกา';

  @override
  String get ssoClockSkewDescription =>
      'วินาทีที่ยอมรับได้บนเวลาของ assertion 90 เหมาะกับผู้ให้บริการส่วนใหญ่';

  @override
  String get ssoScimGenerate => 'สร้างโทเค็น';

  @override
  String get ssoScimTokenOnceBody =>
      'คัดลอกไปคลิปบอร์ดแล้ว แสดงครั้งเดียวและกู้คืนไม่ได้ ดังนั้นวางในผู้ให้บริการตอนนี้';

  @override
  String get ssoPairingCardTitle => 'การจับคู่ด้วยมือ';

  @override
  String get ssoPairingCardDescription =>
      'ทางอื่นเข้าเซิร์ฟเวอร์นี้: รหัสเชิญและคีย์จับคู่ สำหรับอุปกรณ์ที่ไม่ผ่านการลงชื่อเข้าใช้ครั้งเดียว';

  @override
  String settingsCountOfTotal(int count, int total) {
    return '$count จาก $total';
  }

  @override
  String get providersNoneConnectedNote =>
      'ยังไม่เชื่อมต่อผู้ให้บริการ ดังนั้นรันไทม์เอเจนต์ในตัวไม่มีอะไรให้รัน เพิ่มคีย์ API หรือลงชื่อเข้าใช้ด้านล่าง';

  @override
  String get providersFilterHint => 'กรองผู้ให้บริการ';

  @override
  String get providersNoneMatch => 'ไม่มีอะไรตรงกับตัวกรองนี้';

  @override
  String get providerDeniedHereTitle => 'ปฏิเสธในเวิร์กสเปซนี้';

  @override
  String get providerDeniedHereBody =>
      'เอเจนต์ที่นี่ใช้ผู้ให้บริการนี้ไม่ได้ แม้เชื่อมต่อแล้ว เวิร์กสเปซอื่นไม่ได้รับผลกระทบ';

  @override
  String get providerNeedsSignIn => 'ลงชื่อเข้าใช้เพื่อใช้ผู้ให้บริการนี้';

  @override
  String get providerNeedsApiKey => 'เพิ่มคีย์ API เพื่อใช้ผู้ให้บริการนี้';

  @override
  String get providerApiKeyLabel => 'คีย์ API';

  @override
  String get providerGenerationDefaults => 'ค่าเริ่มต้นผู้ให้บริการ';

  @override
  String get providerNoModelsYet =>
      'ยังไม่มีโมเดลที่รายงาน เชื่อมต่อผู้ให้บริการ แล้วซิงค์';

  @override
  String get providerModelsFilterHint => 'กรองโมเดล';

  @override
  String get adaptersNoneReadyNote =>
      'ไม่พบ CLI ของตัวรันในแคตตาล็อกบนเครื่องนี้ ติดตั้งหนึ่งตัว แล้วรีเฟรช';

  @override
  String get adaptersFilterHint => 'กรองตัวรัน';

  @override
  String get adaptersLaunchGroup => 'เปิดใช้';

  @override
  String get adaptersLaunchGroupDescription =>
      'สิ่งที่ตัวรันนี้ได้รับเมื่อเอเจนต์เริ่ม ตั้งค่าเหล่านี้ก่อนติดตั้ง CLI ได้ถ้าต้องการ';

  @override
  String get adaptersEnvNone => 'ยังไม่ได้ตั้ง';

  @override
  String adaptersEnvCount(int count) {
    return 'ตั้งแล้ว $count';
  }

  @override
  String get adapterArgumentsDescription =>
      'ต่อท้ายบรรทัดคำสั่งของตัวรันทุกครั้งที่เปิดใช้';

  @override
  String get defaultChatDescription =>
      'รันการสนทนาใหม่และเอเจนต์ที่ไม่มีตัวรันของตัวเอง';

  @override
  String get shortTaskDescription =>
      'รันงานเบื้องหลังเร็ว เช่น ชื่อและสรุป โมเดลเล็กกว่าเหมาะที่นี่';

  @override
  String get settingsStateFailed => 'ล้มเหลว';

  @override
  String get providerAppsGroupServer => 'ทำหน้าที่เป็นเซิร์ฟเวอร์';

  @override
  String get providerAppsGroupServerDescription =>
      'สำหรับพื้นที่ที่สืบทอด GitHub App ของการติดตั้งนี้ พื้นที่ที่มี App หรือ PAT ของตนเองตั้งค่าที่ พื้นที่ทำงาน → ทั่วไป';

  @override
  String get providerAppsGroupPrConversations => 'การสนทนา pull request';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      'วิธีที่นักพัฒนาคุยกับเซิร์ฟเวอร์นี้บน GitHub ในพื้นที่ที่สืบทอด พื้นที่ที่มี App ของตนเองมีบอทที่ พื้นที่ทำงาน → ทั่วไป ไม่ต้องมีเว็บฮุคหรือ URL สาธารณะ — เซิร์ฟเวอร์สำรวจ';

  @override
  String get providerAppBotLogin => 'ล็อกอินบอท';

  @override
  String get providerAppBotLoginEmpty => 'ทดสอบการเชื่อมต่อเพื่อแก้ล็อกอินบอท';

  @override
  String get providerAppAskOnGitHub => 'ถามบน GitHub';

  @override
  String get providerAppAskOnGitHubHint =>
      'กล่าวถึงล็อกอินบอทด้านบนในความคิดเห็น pull request — ส่วนต่อท้าย [bot] ไม่บังคับ — เพื่อขอรีวิวหรือถามคำถาม ตอบในเธรดรีวิวของมัน หรือเพิ่มป้าย `ai-review` เพื่อขอรีวิว';

  @override
  String get providerAppsGroupSignIn => 'ลงชื่อเข้าใช้คน';

  @override
  String get providerAppsGroupSignInDescription =>
      'ให้แต่ละสมาชิกเชื่อมต่อบัญชีของตัวเองและได้ข้อมูลรับรองของตัวเอง';

  @override
  String get providerAppCapActsAsServer => 'ทำหน้าที่เป็นเซิร์ฟเวอร์';

  @override
  String get providerAppCapSignsIn => 'ลงชื่อเข้าใช้คน';

  @override
  String get portLabel => 'พอร์ต';

  @override
  String get mcpNoTokenWarning =>
      'หากไม่มีโทเค็น สิ่งใดที่ถึงพอร์ตนี้เรียกทุกเครื่องมือได้';

  @override
  String get mcpBridgedToolsLabel => 'เครื่องมือ';

  @override
  String get guardrailFamilyFiles => 'ไฟล์';

  @override
  String get guardrailFamilyGit => 'Git และ pull request';

  @override
  String get guardrailFamilyMachine => 'เครื่องและเครือข่าย';

  @override
  String get guardrailFamilyControl => 'ความลับและเวิร์กสเปซ';

  @override
  String get guardrailScopeFieldLabel => 'กำลังแก้ไขกฎสำหรับ';

  @override
  String get guardrailScopeFieldDescription =>
      'ขอบเขตที่แคบกว่ามีผลเหนือที่กว้างกว่า กฎที่ตั้งที่นี่ใช้ทับสิ่งที่สืบทอด';

  @override
  String get guardrailSetHere => 'ตั้งที่นี่';

  @override
  String get guardrailClearAllHere => 'ล้างทั้งหมด';

  @override
  String get sandboxingCardLabel => 'แซนด์บ็อกซ์';

  @override
  String get sandboxingCardDescription =>
      'ว่างานเอเจนต์รันแยกจากโฮสต์นี้หรือไม่ และเอเจนต์ที่แยกยังเข้าถึงอะไรได้';

  @override
  String get sandboxBackendNoneActive => 'โฮสต์ ไม่แยก';

  @override
  String get sandboxSummaryHost => 'โฮสต์';

  @override
  String get sandboxGroupIsolation => 'การแยก';

  @override
  String get sandboxGroupIsolationDescription =>
      'โพรเซสและการเขียนไฟล์ของเอเจนต์เกิดที่ไหนจริง';

  @override
  String get sandboxBackendFieldDescription =>
      'อัตโนมัติเลือกอันที่แข็งสุดที่โฮสต์นี้รองรับ ตรึงอันหนึ่งเพื่อไม่ให้เปลี่ยนเอง';

  @override
  String get sandboxCapabilitiesDescription =>
      'รูที่เจาะผ่านขอบ แต่ละอันคือสิ่งที่เอเจนต์ที่แยกยังทำกับโลกภายนอกได้';

  @override
  String get sandboxSummaryInForce => 'มีผล';

  @override
  String get rigsInstallHintLabel => 'วิธีติดตั้ง';

  @override
  String get rigsStarting => 'กำลังเริ่ม';

  @override
  String get rigsResidentMemory => 'หน่วยความจำที่ใช้อยู่';

  @override
  String get installedLabel => 'ติดตั้งแล้ว';

  @override
  String get notInstalledLabel => 'ยังไม่ได้ติดตั้ง';

  @override
  String ssoOtherKindUnsaved(String method) {
    return '$method มีการเปลี่ยนแปลงที่ยังไม่บันทึก';
  }

  @override
  String get collapseComment => 'ยุบความคิดเห็น';

  @override
  String get expandComment => 'ขยายความคิดเห็น';

  @override
  String get suggestedChange => 'การเปลี่ยนแปลงที่เสนอ';

  @override
  String get emptyComment => 'ความคิดเห็นว่าง';

  @override
  String repliesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count คำตอบ',
      one: '1 คำตอบ',
    );
    return '$_temp0';
  }

  @override
  String get pendingReview => 'รีวิวที่ค้าง';

  @override
  String failedToResolveConversation(String error) {
    return 'อัปเดตการสนทนาไม่ได้: $error';
  }

  @override
  String get addSingleComment => 'เพิ่มความคิดเห็นเดี่ยว';

  @override
  String get addToReview => 'เพิ่มในรีวิว';

  @override
  String get startAReview => 'เริ่มรีวิว';

  @override
  String get reviewNeedsABody => 'เขียนสรุปหรือคิวความคิดเห็นในบรรทัดก่อน';

  @override
  String get reviewSubmitted => 'ส่งรีวิวแล้ว';

  @override
  String get finishYourReview => 'จบรีวิวของคุณ';

  @override
  String get commentVerdict => 'ความคิดเห็น';

  @override
  String pendingCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ความคิดเห็นที่ค้าง',
      one: '1 ความคิดเห็นที่ค้าง',
    );
    return '$_temp0';
  }

  @override
  String andNMore(int count) {
    return 'และอีก $count';
  }

  @override
  String get queuedCommentHint => 'ความคิดเห็นนี้จะส่งเมื่อคุณส่งรีวิว';

  @override
  String commentOnLinesRange(int start, int end) {
    return 'บรรทัด $start ถึง $end';
  }

  @override
  String get claudeAccountsTitle => 'บัญชี Claude Code';

  @override
  String get claudeAccountsDescription =>
      'แต่ละบัญชีเป็นการลงชื่อเข้าใช้ Claude Code แยก รันใช้บัญชีที่แนบด้านล่าง ตามลำดับนี้';

  @override
  String get claudeAccountsEmpty => 'ยังไม่มีบัญชี';

  @override
  String get claudeAccountAdd => 'เพิ่มบัญชี';

  @override
  String get claudeAccountSignIn => 'ลงชื่อเข้าใช้';

  @override
  String get claudeAccountSignInAgain => 'ลงชื่อเข้าใช้อีกครั้ง';

  @override
  String get claudeAccountSignInHint =>
      'รันสิ่งนี้ในเทอร์มินัลบนเซิร์ฟเวอร์ จะเปิดเบราว์เซอร์เพื่อลงชื่อเข้าใช้ให้เสร็จ และเขียนข้อมูลรับรองลงไดเรกทอรีของบัญชีนี้';

  @override
  String get claudeAccountSignedOut => 'ลงชื่อออกแล้ว';

  @override
  String get claudeAccountExpired => 'การลงชื่อเข้าใช้หมดอายุ';

  @override
  String claudeAccountExpiredDetail(String when) {
    return 'การลงชื่อเข้าใช้หมดอายุเมื่อ $when ลงชื่อเข้าใช้อีกครั้งเพื่อใช้บัญชีนี้';
  }

  @override
  String get claudeAccountMakeDefault => 'ตั้งเป็นค่าเริ่มต้น';

  @override
  String get claudeAccountDefault => 'ค่าเริ่มต้น';

  @override
  String claudeAccountRemoveConfirm(String label) {
    return 'นำ $label ออกหรือไม่?';
  }

  @override
  String get claudeAccountRemoveDetail =>
      'การดำเนินการนี้ลงชื่อออกบัญชีและลบไดเรกทอรีบนเซิร์ฟเวอร์ การล็อกอินเองไม่ได้รับผลกระทบ';

  @override
  String claudeAccountStatusUnknown(String error) {
    return 'ตรวจบัญชีนี้ไม่ได้: $error';
  }

  @override
  String claudeAccountUsedPercent(String percent) {
    return 'ใช้แล้ว $percent%';
  }

  @override
  String get accountPoolStrategy => 'การหมุนเวียน';

  @override
  String get accountPoolPinned => 'ตรึง';

  @override
  String get accountPoolRoundRobin => 'รอบเวียน';

  @override
  String get accountPoolSerial => 'ทีละบัญชี';

  @override
  String get accountPoolPinnedHint =>
      'เริ่มที่บัญชีแรกเสมอ อันอื่นเป็นทางสำรองหากล้มเหลว';

  @override
  String get accountPoolRoundRobinHint =>
      'กระจายรันข้ามบัญชี ย้ายไปอันถัดไปทุกครั้งที่จัดส่ง';

  @override
  String get accountPoolSerialHint => 'ใช้บัญชีแรกให้หมดก่อนแตะอันถัดไป';

  @override
  String get accountPoolMoveUp => 'ย้ายขึ้น';

  @override
  String get accountPoolMoveDown => 'ย้ายลง';

  @override
  String get accountPoolUsingAll =>
      'ยังไม่ได้แนบอะไร — ใช้ทุกบัญชี ตามลำดับนี้';

  @override
  String get accountPoolInheriting => 'สืบทอดบัญชีของเวิร์กสเปซ';

  @override
  String get accountPoolResetToWorkspace => 'รีเซ็ตเป็นบัญชีของเวิร์กสเปซ';

  @override
  String accountPoolCoolingOff(String when) {
    return 'โควตาหมดจนถึง $when';
  }

  @override
  String get accountPoolSignedOut => 'ลงชื่อออกแล้ว';

  @override
  String get accountPoolExpired => 'การลงชื่อเข้าใช้หมดอายุ';

  @override
  String accountPoolLoadFailed(String error) {
    return 'โหลดการหมุนเวียนไม่ได้: $error';
  }

  @override
  String get providerSignedInAccount => 'บัญชีที่ลงชื่อเข้าใช้';

  @override
  String get agentAccountsTab => 'บัญชี';

  @override
  String get agentClaudeAccountsNoticeTitle => 'หลายบัญชี Claude Code';

  @override
  String agentClaudeAccountsNoticeBody(int count) {
    return 'ตัวรันนี้ลงชื่อเข้าใช้เป็นหนึ่งใน $count บัญชี Claude Code บนโฮสต์นี้ เลือกอันใด หรือหมุนเวียนระหว่างกัน ในแท็บบัญชี';
  }

  @override
  String get agentAccountsDescription =>
      'บัญชีใดที่รันของเอเจนต์นี้ใช้ แต่ละบล็อกเริ่มต้นสืบทอดตัวเลือกของเวิร์กสเปซ';

  @override
  String get agentAccountsNothingToRotate =>
      'ไม่มีอะไรให้หมุนเวียน — เชื่อมต่อบัญชีหรือคีย์ที่สองก่อน';

  @override
  String failedToPostReply(String error) {
    return 'โพสต์คำตอบไม่ได้: $error';
  }

  @override
  String commentOnLine(int line) {
    return 'บรรทัด $line';
  }

  @override
  String get viewInDiff => 'ดูใน diff';

  @override
  String get subscriptionUsagePreviousAccount => 'บัญชีก่อน';

  @override
  String get subscriptionUsageNextAccount => 'บัญชีถัดไป';

  @override
  String inReplyTo(String path) {
    return 'ตอบไปที่ $path';
  }

  @override
  String get subscriptionUsageNoneReported =>
      'ไม่มีการใช้งานที่รายงานสำหรับบัญชีนี้';

  @override
  String get subscriptionUsageCredits => 'เครดิต';

  @override
  String get reviewHubStaticRule => 'กฎคงที่';

  @override
  String get reviewHubStarted => 'เริ่มรีวิวแล้ว';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return 'พบโดยกฎเชิงกำหนด ($rule) บนบรรทัดที่ pull request นี้เพิ่ม — ไม่ใช่โดยเอเจนต์ผู้รีวิว';
  }

  @override
  String get prReviewArtifactTab => 'รีวิว PR';

  @override
  String get prReviewRunning => 'กำลังรีวิว pull request นี้…';

  @override
  String get prReviewStarting => 'กำลังเริ่มรีวิว…';

  @override
  String get prReviewStartingBody =>
      'กำลังเตรียม worktree ของ pull request นี้ ผู้รีวิวจะเริ่มทันทีที่พร้อม';

  @override
  String get prReviewFailed => 'รีวิวล้มเหลว';

  @override
  String get prReviewRerunning => 'กำลังรีวิวอีกครั้ง…';

  @override
  String get prReviewNoOpenFindings => 'ไม่มีข้อค้นพบที่เปิด';

  @override
  String prReviewOpenFindings(int count) {
    return '$count ข้อค้นพบที่เปิด';
  }

  @override
  String subscriptionUsageSpend(String used, String limit) {
    return '$used จาก $limit';
  }

  @override
  String reviewCommentsPosted(int posted, int skipped, int failed) {
    return 'โพสต์ความคิดเห็น $posted รายการในฐานะบอท ข้าม $skipped (ไม่มีจุดยึดไฟล์) ล้มเหลว $failed';
  }

  @override
  String reviewFindingsOutOfDiff(int count, String files) {
    return 'ข้อค้นพบ $count รายการชี้โค้ดที่ pull request นี้ไม่ได้เปลี่ยน ($files) GitHub รับความคิดเห็นในบรรทัดบน diff เท่านั้น';
  }

  @override
  String get reviewRailReport => 'รายงาน';

  @override
  String get reviewNoFindingsTitle => 'ยังไม่มีข้อค้นพบรีวิว';

  @override
  String get reviewNoFindingsHint => 'ข้อค้นพบจะปรากฏที่นี่เมื่อเอเจนต์โพสต์';

  @override
  String reviewShowDismissed(int count) {
    return 'แสดงที่ปิดทิ้ง $count';
  }

  @override
  String reviewHideDismissed(int count) {
    return 'ซ่อนที่ปิดทิ้ง $count';
  }

  @override
  String reviewDisagreementsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ตรวจพบความไม่เห็นด้วยของผู้รีวิว $count รายการ',
      one: 'ตรวจพบความไม่เห็นด้วยของผู้รีวิว 1 รายการ',
    );
    return '$_temp0';
  }

  @override
  String get reviewFilterKind => 'ชนิด';

  @override
  String get reviewFilterStatus => 'สถานะ';

  @override
  String get reviewKindBug => 'บั๊ก';

  @override
  String get reviewKindSuggestion => 'ข้อเสนอ';

  @override
  String get reviewKindRecommendation => 'คำแนะนำ';

  @override
  String get reviewKindQuestion => 'คำถาม';

  @override
  String get reviewKindTicket => 'ตั๋วงาน';

  @override
  String get archiveSpace => 'เก็บถาวรสเปซ';

  @override
  String get archivedSpaces => 'สเปซที่เก็บถาวร';

  @override
  String get archivedSpacesEmpty => 'ไม่มีสเปซที่เก็บถาวร';

  @override
  String get restoreSpace => 'กู้คืน';

  @override
  String archivedWhen(String time) {
    return 'เก็บถาวรเมื่อ $time';
  }

  @override
  String get deleteSpacePermanently => 'ลบถาวร';

  @override
  String get renameSpace => 'เปลี่ยนชื่อสเปซ';

  @override
  String get renameConversation => 'เปลี่ยนชื่อการสนทนา';

  @override
  String get spaceActions => 'การดำเนินการของสเปซ';

  @override
  String get conversationActions => 'การดำเนินการของการสนทนา';

  @override
  String get editSpaceRepos => 'แก้ไขรีโพสิทอรี';

  @override
  String get editSpaceReposTitle => 'รีโพสิทอรีของสเปซ';

  @override
  String get editSpaceReposWarning =>
      'การเพิ่มรีโพสิทอรีจะเช็กเอาต์เข้าสเปซนี้ การนำออกจะลบโฟลเดอร์';

  @override
  String get agentSectionIdentity => 'ตัวตน';

  @override
  String get agentSectionRuntime => 'รันไทม์';

  @override
  String get agentSectionGuardrails => 'การ์ดเรล';

  @override
  String orgChartReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count รายงาน',
      one: '1 รายงาน',
    );
    return '$_temp0';
  }

  @override
  String get teamsFilterHint => 'กรองทีม…';

  @override
  String get teamsSummaryWithLeader => 'มีหัวหน้า';

  @override
  String teamCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ทีม',
      one: '1 ทีม',
      zero: 'ไม่มีทีม',
    );
    return '$_temp0';
  }

  @override
  String agentDeleteLongDescription(String name) {
    return 'การลบ $name จะลบโปรไฟล์ ลิงก์สกิล และประวัติรัน เลิกทำไม่ได้';
  }

  @override
  String get resetToDefault => 'รีเซ็ตเป็นค่าเริ่มต้น';

  @override
  String get newAgent => 'เอเจนต์ใหม่';

  @override
  String get newSkill => 'สกิลใหม่';

  @override
  String get zoomIn => 'ซูมเข้า';

  @override
  String get zoomOut => 'ซูมออก';

  @override
  String get resetZoom => 'รีเซ็ตซูม';

  @override
  String get imageHostedOnGitHub => 'รูปโฮสต์บน GitHub';

  @override
  String get imageOpenExternally => 'รูป · เปิดภายนอก';

  @override
  String get memoryScopeAll => 'ทุกขอบเขต';

  @override
  String get memoryScopeWorkspace => 'ทั้งเวิร์กสเปซ';

  @override
  String get memoryScopeFilterLabel => 'กรองตามขอบเขต';

  @override
  String memoryScopeRepoTooltip(String repo) {
    return 'จำกัดขอบเขตที่รีโพสิทอรี $repo';
  }

  @override
  String get toolScreenshot => 'ภาพหน้าจอจากเอเจนต์';

  @override
  String get toolImageUnavailable => 'รูปใช้ไม่ได้';

  @override
  String toolImagesUnavailable(int count) {
    return '$count รูปใช้ไม่ได้';
  }

  @override
  String get shakeUnavailable => 'การเขย่าใช้ไม่ได้บนเซิร์ฟเวอร์นี้';

  @override
  String get shakeNothing => 'ไม่มีอะไรให้เขย่าออก — เทิร์นล่าสุดถูกป้องกัน';

  @override
  String shakeDone(int tokens) {
    return 'ปลดโทเค็นประมาณ $tokens';
  }

  @override
  String get compactionDivider => 'ย่อแล้ว';

  @override
  String compactionDividerCount(int count) {
    return 'ย่อแล้ว · พับ $count ข้อความ';
  }

  @override
  String get composerDropToAttach => 'วางเพื่อแนบ';

  @override
  String get attachmentUnavailable => 'ไฟล์แนบใช้ไม่ได้';

  @override
  String get attachmentUnavailableDetail =>
      'ไฟล์แนบนี้ไม่ได้อยู่ในหน่วยความจำแล้ว แนบอีกครั้งเพื่อดูตัวอย่าง';

  @override
  String get attachmentPreviewFailed => 'เปิดไฟล์นี้ไม่ได้';

  @override
  String get attachmentPreviewUnsupported => 'ไม่มีตัวอย่างสำหรับชนิดไฟล์นี้';

  @override
  String get attachmentTooLargeToPreview => 'ใหญ่เกินกว่าจะดูตัวอย่าง';

  @override
  String get attachmentOpenExternally => 'เปิดในแอปเริ่มต้น';

  @override
  String get asideUnavailable =>
      'ตั้งโมเดลครั้งเดียวในการตั้งค่าเวิร์กสเปซเพื่อใช้สิ่งนี้';

  @override
  String get asideEmpty => 'ยังไม่มีอะไรให้ทำงานต่อ';

  @override
  String get asideFailed => 'ได้คำตอบไม่ได้';

  @override
  String get handoffTitle => 'ส่งต่อ';

  @override
  String get asideTitle => 'คำถามข้าง';

  @override
  String get attachFilesOrDrop => 'แนบไฟล์ — หรือวางที่นี่';

  @override
  String get guidedGoalTitle => 'ทำให้วัตถุประสงค์คมขึ้น';

  @override
  String get guidedGoalIntro =>
      'เอเจนต์ที่ทำงานโดยไม่มีผู้ดูแลต้องรู้แน่ชัดว่าเมื่อไหร่เสร็จ มีคำถามไม่กี่ข้อก่อน';

  @override
  String get guidedGoalAnswerHint => 'คำตอบของคุณ';

  @override
  String get guidedGoalNext => 'ถัดไป';

  @override
  String get guidedGoalStart => 'เริ่มเป้าหมาย';

  @override
  String get guidedGoalSkip => 'ข้ามและรันตามที่เขียน';

  @override
  String guidedGoalStillMissing(String items) {
    return 'ยังไม่ระบุ: $items';
  }

  @override
  String get conversationTreeTitle => 'ต้นไม้การสนทนา';

  @override
  String conversationTreeBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count สาขา',
      one: '1 สาขา',
    );
    return '$_temp0';
  }

  @override
  String get conversationTreeSwitch => 'ทำต่อจากที่นี่';

  @override
  String get conversationTreeFork => 'แยกเป็นการสนทนาใหม่';

  @override
  String get conversationTreeCurrent => 'อยู่บนสาขานี้';

  @override
  String get conversationTreeEmpty => 'ยังไม่มีอะไรที่นี่';

  @override
  String get conversationTreeForked => 'แยกเป็นการสนทนาใหม่แล้ว';

  @override
  String get conversationTreeSwitched => 'กำลังทำต่อจากข้อความนั้นแล้ว';

  @override
  String exportSaved(String path) {
    return 'บันทึกไปที่ $path แล้ว';
  }

  @override
  String get exportFailed => 'เขียนการส่งออกไม่ได้';

  @override
  String get contextCommandNoAgent =>
      'ไม่มีเอเจนต์ในการสนทนานี้ จึงไม่มีหน้าต่างบริบทให้เปิด';

  @override
  String contextCommandNoSuchAgent(String name, String names) {
    return 'ไม่มีเอเจนต์ชื่อ “$name” ในการสนทนานี้ ลอง: $names';
  }

  @override
  String get dumpCopied => 'คัดลอกทรานสคริปต์ไปคลิปบอร์ดแล้ว';

  @override
  String get messageQueueHint => 'พิมพ์ต่อเพื่อคิวการเปลี่ยนแปลงตามมา';

  @override
  String get steerNow => 'ชี้นำ';

  @override
  String get steeringQueueLabel => 'ข้อความชี้นำที่คิวไว้';

  @override
  String get steeringDeliverUnavailable =>
      'ไม่มีเอเจนต์ที่กำลังรันรับสิ่งนั้นได้ตอนนี้ — จะอยู่ในคิว';

  @override
  String get reorderSteeringCard => 'จัดลำดับข้อความที่คิว';

  @override
  String get editSteeringCard => 'แก้ไขข้อความที่คิว';

  @override
  String get deleteSteeringCard => 'ลบข้อความที่คิว';

  @override
  String get steeringBadge => 'ชี้นำแล้ว';

  @override
  String get settingsSandboxLabel => 'แซนด์บ็อกซ์';

  @override
  String get sandboxExecGrantsTitle => 'สิทธิ์ปฏิบัติการ';

  @override
  String get sandboxExecGrantsSubtitle =>
      'โปรแกรมที่เอเจนต์อาจรันจากสำเนาทำงานของรีโพสิทอรีของคุณ แต่ละรายการคุณอนุมัติเมื่อแซนด์บ็อกซ์ถาม';

  @override
  String get sandboxExecGrantsEmpty =>
      'ยังไม่มีการตัดสินที่บันทึก คุณจะถูกถามครั้งแรกที่เอเจนต์ต้องรันโปรแกรมจากสำเนาทำงาน';

  @override
  String get sandboxExecGrantRevoke => 'เพิกถอน';

  @override
  String get sandboxExecGrantAllowed => 'อนุญาตแล้ว';

  @override
  String get sandboxExecGrantBlocked => 'ถูกบล็อก';

  @override
  String get sandboxExecGrantRevokeConfirmTitle =>
      'เพิกถอนการตัดสินนี้หรือไม่?';

  @override
  String get sandboxExecGrantRevokeConfirmBody =>
      'คุณจะถูกถามอีกครั้งครั้งหน้าที่เอเจนต์ต้องรันโปรแกรมจากสำเนานี้';

  @override
  String get repoScriptsTest => 'ทดสอบ';

  @override
  String get repoScriptsTestTooltip => 'รันฉบับร่างนี้ในโคลนทิ้งได้ของรีโพ';

  @override
  String get repoScriptsRunKindTest => 'ทดสอบ';

  @override
  String get demoBadgeLabel => 'เดโม';

  @override
  String get demoFilePickerTitle => 'ไฟล์เดโม';

  @override
  String get demoFilePickerBody =>
      'เดโมจำลองการอัปโหลด: เลือกอันใดก็ได้แล้วจะแนบกับข้อความโดยไม่แตะดิสก์';

  @override
  String get demoFilePickerAttach => 'แนบ';

  @override
  String get demoReadOnlySave => 'อ่านอย่างเดียวในเดโม';

  @override
  String get demoBadgeTooltip =>
      'คุณกำลังสำรวจเดโม ข้อมูลเป็นเรื่องสมมติและเอเจนต์เป็นสคริปต์';

  @override
  String get demoFirstRunTitle => 'คุณอยู่ในเดโมสด';

  @override
  String demoFirstRunBody(int minutes) {
    return 'นี่คือแอปจริงที่รันบนโค้ดจริง — เฉพาะข้อมูลที่ถูกแต่ง เอเจนต์สตรีมรันจริงจากสคริปต์ จึงไม่มีอะไรถึงโมเดลและไม่มีอะไรรันบนเครื่อง เวิร์กสเปซเป็นของคุณคนเดียวและหายไปหลัง $minutes นาที';
  }

  @override
  String get demoFirstRunDismiss => 'เข้าใจแล้ว';

  @override
  String get demoTourTitle => 'ดูที่ไหนก่อน';

  @override
  String get demoTourSubtitle => 'สี่ที่ที่แสดงสิ่งที่แอปทำจริง';

  @override
  String get demoTourSkip => 'ข้าม';

  @override
  String get demoTourStarRepo => 'Star บน GitHub';

  @override
  String get demoTourOpen => 'เปิด';

  @override
  String get demoTourSpacesTitle => 'คุยกับเอเจนต์';

  @override
  String get demoTourSpacesBody =>
      'ส่งข้อความในสเปซแล้วดูรันสตรีมเข้ามา — การคิด การเรียกเครื่องมือ และค่าใช้จ่าย เหมือนรันจริง';

  @override
  String get demoTourReviewTitle => 'รีวิว pull request';

  @override
  String get demoTourReviewBody =>
      'เปิด #412 แสดงความคิดเห็นในบรรทัดหรือส่งรีวิว คำของคุณลงในเธรดและอยู่ที่นั่น';

  @override
  String get demoTourTicketsTitle => 'ติดตามงาน';

  @override
  String get demoTourTicketsBody =>
      'ตั๋วงาน สิ่งที่ต้องทำ และแผนลิงก์กับการสนทนาเดียวกันที่เอเจนต์กำลังมี';

  @override
  String get demoTourInboxTitle => 'ดูการทำงานทั้งหมด';

  @override
  String get demoTourInboxBody =>
      'ทุกการแจ้งจากทุกเสาลงในกล่องขาเข้าเดียว — รีวิว ตั๋วงาน รัน และการประชุม';

  @override
  String get demoUnavailableTitle => 'ใช้ไม่ได้ในเดโม';

  @override
  String get demoUnavailableTerminal =>
      'เทอร์มินัลรันเชลล์จริงบนโฮสต์เซิร์ฟเวอร์ เดโมไม่มีพื้นผิวการรันเลย — นั่นคือสิ่งที่ทำให้เปิดสู่สาธารณะได้อย่างปลอดภัย';

  @override
  String get demoUnavailableRig =>
      'เอนโคลเจอร์คือเครื่องเสมือนใช้แล้วทิ้งที่เอเจนต์ขับ เดโมไม่บูตเลย: เอนด์พอยต์สาธารณะที่เริ่ม VM ได้ไม่ใช่เดโม';

  @override
  String get demoUnavailableEditor =>
      'ตัวแก้ไขในเบราว์เซอร์รันโพรเซส code-server กับเช็กเอาต์จริง เดโมไม่มีทั้งสองอย่าง';

  @override
  String get demoUnavailableFeeds =>
      'เดโมอ่านฟีดจริง แต่รายการติดตามคงที่ การเพิ่มหรือนำออกถูกปิดที่นี่';

  @override
  String get demoUnavailableForge =>
      'เดโมไม่ถือข้อมูลรับรองและไม่ติดต่อ GitHub, GitLab หรือ Linear pull request เป็นไฟล์ตัวอย่าง และความคิดเห็นของคุณถูกเก็บในเครื่อง';

  @override
  String get demoUnavailableModels =>
      'เดโมไม่เรียกโมเดล รันเอเจนต์เป็นการเล่นสคริปต์ จึงไม่มีค่าใช้จ่ายและไม่ถึงผู้ให้บริการ';

  @override
  String get demoUnavailableMcp =>
      'พื้นผิวเครื่องมือ MCP ไม่ถูกติดตั้งบนเดโม จึงไม่มีไคลเอนต์ภายนอกแนบได้';

  @override
  String get demoUnavailableRepos =>
      'เดโมไม่เช็กเอาต์โค้ดและไม่รัน git รีโพสิทอรีที่คุณเห็นเป็นไฟล์ตัวอย่างหลัง pull request';

  @override
  String get demoUnavailableSkills =>
      'การติดตั้งสกิลดาวน์โหลดและสแกนโค้ด เดโมไม่ดึงอะไร';

  @override
  String get demoUnavailableSso =>
      'การลงชื่อเข้าใช้ครั้งเดียวเป็นการตั้งค่าเซิร์ฟเวอร์ เดโมลงชื่อเข้าใช้คุณเป็นแขกชั่วคราวแทน';

  @override
  String get demoUnavailableAudio =>
      'การบันทึกและการป้อนด้วยเสียงต้องจับเสียงและโมเดลพูดบนโฮสต์ เดโมไม่มีทั้งสองอย่าง ดังนั้นการประชุมเป็นทรานสคริปต์โดยไม่มีการเล่น';

  @override
  String get demoUnavailableServerAdmin =>
      'นี่คือการดูแลเซิร์ฟเวอร์ เดโมให้ผู้เข้าชมทุกคนมีเวิร์กสเปซทิ้งได้ของตัวเองและไม่มีอะไรเกินนั้น';

  @override
  String get demoUnavailablePipelines =>
      'ไม่สามารถรันไปป์ไลน์ที่นี่ได้ ผู้เยี่ยมชมที่เขียนสเต็ป bash แล้วเริ่มได้ — ด้วยมือหรือผ่านทริกเกอร์เหตุการณ์ — คือการรันโค้ดบนโฮสต์นี้';

  @override
  String get settingsBackupRestore => 'สำรองและกู้คืน';

  @override
  String get settingsBackupRestoreDescription =>
      'สแนปช็อตของทุกฐานข้อมูลบนเซิร์ฟเวอร์นี้ พร้อมส่งออก นำเข้า และลบเวิร์กสเปซเดียว';

  @override
  String get backupSnapshotsLabel => 'สแนปช็อตการติดตั้ง';

  @override
  String get backupSnapshotsExplainer =>
      'สแนปช็อตคัดลอกทุกฐานข้อมูลเข้าโฟลเดอร์ประทับเวลาบนโฮสต์เซิร์ฟเวอร์ การกู้คืนทั้งการติดตั้งหมายถึงคัดลอกโฟลเดอร์นั้นกลับโดยหยุดเซิร์ฟเวอร์ เวิร์กสเปซเดียวกู้คืนจากที่นี่ได้';

  @override
  String get backupNowAction => 'สำรองตอนนี้';

  @override
  String backupSnapshotWritten(String path) {
    return 'เขียนสแนปช็อตไปที่ $path แล้ว';
  }

  @override
  String get backupNoSnapshots =>
      'ยังไม่มีสแนปช็อต จะถ่ายเมื่อคุณขอเท่านั้น — ไม่มีตารางเวลา';

  @override
  String get backupSnapshotComplete => 'ครบ';

  @override
  String get backupSnapshotIncomplete => 'ไม่ครบ';

  @override
  String get backupSnapshotIncompleteNote =>
      'แมนิเฟสต์หายไปหรือระบุไฟล์ที่ไม่มี ดังนั้นสแนปช็อตนี้กู้คืนทั้งการติดตั้งไม่ได้ ไฟล์เวิร์กสเปซที่มียังนำมาใช้ทีละรายการได้';

  @override
  String backupSnapshotWorkspaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count เวิร์กสเปซ',
      one: '1 เวิร์กสเปซ',
      zero: 'ไม่มีเวิร์กสเปซ',
    );
    return '$_temp0';
  }

  @override
  String backupSnapshotSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count เวิร์กสเปซไม่ได้จับ',
      one: '1 เวิร์กสเปซไม่ได้จับ',
    );
    return '$_temp0';
  }

  @override
  String get backupServerPathLabel => 'พาธบนเซิร์ฟเวอร์';

  @override
  String get backupRestoreAction => 'กู้คืน';

  @override
  String get backupRestoreTitle => 'กู้คืนเวิร์กสเปซ';

  @override
  String backupRestoreBody(String name) {
    return 'การดำเนินการนี้แทนที่ทุกอย่างใน $name ด้วยสำเนาในสแนปช็อตนี้ สิ่งที่เวิร์กสเปซทำตั้งแต่ถ่ายสแนปช็อตจะหายไป และเลิกทำไม่ได้';
  }

  @override
  String backupRestoreDone(String name) {
    return 'กู้คืน $name จากสแนปช็อตแล้ว';
  }

  @override
  String get backupWorkspaceUnknown => 'ไม่อยู่บนเซิร์ฟเวอร์นี้อีกแล้ว';

  @override
  String get backupWorkspaceDataLabel => 'ข้อมูลเวิร์กสเปซ';

  @override
  String get backupWorkspaceDataExplainer =>
      'เวิร์กสเปซหนึ่งคือไฟล์ฐานข้อมูลหนึ่งไฟล์ ดังนั้นการส่งออกคือคัดลอกไฟล์นั้น ไม่ใช่ดัมพ์ทีละตาราง การนำเข้าแทนที่ทุกอย่างในเวิร์กสเปซเป้าหมายด้วยไฟล์ที่คุณระบุ';

  @override
  String get backupExportAction => 'ส่งออก';

  @override
  String backupExportDone(String path) {
    return 'ส่งออกไปที่ $path แล้ว';
  }

  @override
  String get backupExportedFileLabel => 'ไฟล์ที่ส่งออกบนเซิร์ฟเวอร์';

  @override
  String get backupImportAction => 'นำเข้า';

  @override
  String backupImportTitle(String name) {
    return 'นำเข้าใน $name';
  }

  @override
  String backupImportBody(String name) {
    return 'การดำเนินการนี้แทนที่ทุกอย่างใน $name ด้วยเนื้อหาของไฟล์ สิ่งที่เวิร์กสเปซถืออยู่ตอนนี้จะหายไป และเลิกทำไม่ได้';
  }

  @override
  String get backupImportSourceLabel => 'ไฟล์ฐานข้อมูลเวิร์กสเปซ';

  @override
  String get backupImportSourceDescription =>
      'ไฟล์ .db ที่เซิร์ฟเวอร์อ่านได้ พาธแก้บนโฮสต์เซิร์ฟเวอร์ ไม่ใช่บนอุปกรณ์นี้';

  @override
  String backupImportDone(String name) {
    return 'นำเข้าใน $name แล้ว';
  }

  @override
  String backupDeleteBody(String name) {
    return '$name หายจากทุกรายการและการค้นหา ไฟล์ฐานข้อมูลยังอยู่บนดิสก์ การสำรองยังรวมมัน และไม่มีอะไรรีเคลมพื้นที่อัตโนมัติ';
  }

  @override
  String get backupExportDescription =>
      'เขียนสำเนาบนเซิร์ฟเวอร์ หรือดาวน์โหลดมาที่อุปกรณ์นี้';

  @override
  String get backupExportOnServerAction => 'บันทึกบนเซิร์ฟเวอร์';

  @override
  String get backupDownloadAction => 'ดาวน์โหลด';

  @override
  String backupDownloadSaved(String path) {
    return 'บันทึกไปที่ $path แล้ว';
  }

  @override
  String get backupDownloadInBrowser => 'เบราว์เซอร์กำลังดาวน์โหลด';

  @override
  String get backupRestoreFromDeviceLabel => 'กู้คืนจากอุปกรณ์นี้';

  @override
  String get backupRestoreFromDeviceDescription =>
      'เลือกไฟล์ฐานข้อมูลเวิร์กสเปซที่นี่แล้ว Control Center จะอัปโหลดไปเซิร์ฟเวอร์ นี่คืออันที่ใช้เมื่อเซิร์ฟเวอร์ไม่ใช่เครื่องนี้';

  @override
  String get backupUploadAction => 'เลือกไฟล์แล้วอัปโหลด';

  @override
  String get backupTransferUnavailable =>
      'การเชื่อมต่อนี้ถึงเซิร์ฟเวอร์ผ่านรีเลย์ ซึ่งไม่รับส่งไฟล์ เชื่อมต่อเซิร์ฟเวอร์โดยตรงเพื่อดาวน์โหลดหรืออัปโหลดการสำรอง';

  @override
  String get backupTransferForbidden =>
      'เซิร์ฟเวอร์ปฏิเสธ การดาวน์โหลดเวิร์กสเปซต้องมีบทบาทแอดมิน การกู้คืนต้องเป็นเจ้าของ และสแนปช็อตทั้งก้อนต้องเป็นผู้ดำเนินการติดตั้ง';

  @override
  String get backupTransferUnsupported => 'เซิร์ฟเวอร์นี้ไม่มีพื้นผิวการสำรอง';

  @override
  String get backupTransferTooLarge => 'ไฟล์ใหญ่เกินกว่าที่เซิร์ฟเวอร์รับ';

  @override
  String get credentialGateWaitingTitle => 'กำลังรอข้อมูลรับรอง';

  @override
  String credentialGateHarnessTitle(String provider) {
    return '$provider ไม่มีข้อมูลรับรอง';
  }

  @override
  String get credentialGateSignedOutTitle => 'Claude Code ลงชื่อออกแล้ว';

  @override
  String get credentialGateExpiredTitle =>
      'การลงชื่อเข้าใช้ Claude Code ของคุณหมดอายุ';

  @override
  String get credentialGatePlanSpentTitle => 'ถึงขีดจำกัดแผน Claude Code';

  @override
  String credentialGateWaitingAgent(String agent) {
    return '$agent กำลังรอทำต่อ';
  }

  @override
  String get credentialGateWaitingRun => 'รันกำลังรอทำต่อ';

  @override
  String get credentialGateWatching => 'กำลังดูการแก้ไข — รันจะทำต่อเอง';

  @override
  String credentialGateFreesUpAt(String time) {
    return 'ว่างเมื่อ $time';
  }

  @override
  String credentialGateGivesUpAt(String time) {
    return 'รันยอมแพ้เมื่อ $time';
  }

  @override
  String get credentialGateCheckAgain => 'ตรวจอีกครั้ง';

  @override
  String get credentialGateCancelRun => 'ยกเลิกรัน';

  @override
  String get credentialGateAccountsTried => 'บัญชีที่ลองแล้ว';

  @override
  String get credentialGateClaudeSignInHint =>
      'ลงชื่อเข้าใช้จาก การตั้งค่า → อะแดปเตอร์ → Claude Code หรือรันคำสั่งล็อกอินในเทอร์มินัล รันจะรับเอง';

  @override
  String get credentialGateOpenSettings => 'เปิดการตั้งค่า';

  @override
  String get selectModel => 'เลือกโมเดล';

  @override
  String get allModels => 'โมเดลทั้งหมด';

  @override
  String get noModelsMatchSearch => 'ไม่มีโมเดลที่ตรงกับการค้นหาของคุณ';

  @override
  String useCustomModelId(String id) {
    return 'ใช้ “$id”';
  }

  @override
  String get modelFree => 'ฟรี';

  @override
  String modelOutputTokens(String tokens) {
    return 'เอาต์พุต $tokens';
  }

  @override
  String modelPricePerMTokens(String input, String output) {
    return 'อินพุต $input / เอาต์พุต $output ต่อ 1M โทเค็น';
  }

  @override
  String modelEffortLevels(String levels) {
    return 'ความพยายามในการคิด: $levels';
  }

  @override
  String get modelSupportsReasoning => 'รองรับความพยายามในการคิด';

  @override
  String get profileDeliveryMetrics => 'เมตริกการส่งมอบ';

  @override
  String profileMetricsSample(int count) {
    return 'PR ที่วิเคราะห์: $count';
  }

  @override
  String get profileMergeRate => 'อัตราการผสาน';

  @override
  String get profileReviewCoverage => 'ความครอบคลุมของการตรวจสอบ';

  @override
  String get profilePrSize => 'ขนาด PR';

  @override
  String get profileTimeToMerge => 'เวลาจนถึงการผสาน';

  @override
  String get profileMergeTimeTrend => 'แนวโน้มเวลาในการผสาน';

  @override
  String get profileWeeklyMedian => 'ค่ามัธยฐานรายสัปดาห์, สเกลลอการิทึม';

  @override
  String get profilePrOpeningPattern => 'วันในสัปดาห์ × ชั่วโมง, เวลาท้องถิ่น';

  @override
  String get profileFirstReview => 'เวลาจนถึงการตรวจสอบครั้งแรก';

  @override
  String get profileMetricsTruncated =>
      'ค่าเปอร์เซ็นไทล์คำนวณจากตัวอย่างคำขอพูลที่มีอยู่ในจำนวนจำกัด';

  @override
  String profileLinesChanged(String count) {
    return '$count บรรทัด';
  }

  @override
  String profileDurationMinutes(int count) {
    return '$count นาที';
  }

  @override
  String profileDurationHours(int count) {
    return '$count ชม.';
  }

  @override
  String profileDurationDaysHours(int days, int hours) {
    return '$days วัน $hours ชม.';
  }

  @override
  String profilePercentiles(String median, String p90) {
    return 'p50 $median · p90 $p90';
  }

  @override
  String profileTeamMembers(int count) {
    return 'สมาชิก: $count';
  }

  @override
  String noPrsByTeamInWorkspace(String team) {
    return 'ไม่มี Pull Request จาก $team ในพื้นที่ทำงานนี้';
  }

  @override
  String get profilePrStateFilterLabel => 'กรอง Pull Request ตามสถานะ';

  @override
  String get noProfilePrsMatchSearchHint =>
      'ลองใช้ชื่อหรือหมายเลข Pull Request อื่น';

  @override
  String get rigNetworkUnrestricted => 'เครือข่ายไม่มีข้อจำกัด';

  @override
  String get rigNetworkAllowAllHosts => 'อนุญาตโฮสต์ทั้งหมด';

  @override
  String get rigBrowserPermissionsTitle => 'สิทธิ์ของไซต์';

  @override
  String get rigBrowserPermissionsTooltip => 'สิทธิ์ของไซต์และเครือข่าย';

  @override
  String get rigBrowserPermissionEmpty => 'ยังไม่มีไซต์ใดขอสิทธิ์';

  @override
  String rigBrowserPermissionPrompt(String origin, String permission) {
    return '$origin ต้องการใช้ $permission';
  }

  @override
  String get rigBrowserPermissionBlock => 'บล็อก';

  @override
  String get rigBrowserPermissionCamera => 'กล้อง';

  @override
  String get rigBrowserPermissionMicrophone => 'ไมโครโฟน';

  @override
  String get rigBrowserPermissionNotifications => 'การแจ้งเตือน';

  @override
  String get rigBrowserPermissionGeolocation => 'ตำแหน่ง';

  @override
  String get rigBrowserPermissionPersistentStorage => 'ที่เก็บข้อมูลถาวร';

  @override
  String get rigBrowserPermissionClipboard => 'คลิปบอร์ด';

  @override
  String get rigBrowserPermissionDisplayCapture => 'การจับภาพหน้าจอ';

  @override
  String get rigBrowserPermissionMidi => 'MIDI';

  @override
  String get rigNetworkBypassTitle => 'อนุญาตโฮสต์เครือข่ายทั้งหมดหรือไม่';

  @override
  String get rigNetworkBypassBody =>
      'การดำเนินการนี้จะรีสตาร์ทสภาพแวดล้อมแบบแยกและละทิ้งงานภายในที่ยังไม่ได้คอมมิต จากนั้นระบบเกสต์จะเข้าถึงโฮสต์เครือข่ายใดก็ได้จนกว่าจะปิด';

  @override
  String get rigNetworkRestartUnrestricted => 'รีสตาร์ทโดยไม่มีข้อจำกัด';

  @override
  String get rigNetworkUnrestrictedBody =>
      'สภาพแวดล้อมแบบแยกนี้เข้าถึงโฮสต์เครือข่ายทั้งหมดได้ ปิดแล้วเปิดสภาพแวดล้อมใหม่เพื่อคืนค่าข้อจำกัดเริ่มต้น';

  @override
  String get rigNetworkAlreadyUnrestrictedBody =>
      'โปรแกรมจำลอง Android นี้จัดการเครือข่ายของตนเองอยู่แล้ว ดังนั้น Control Center จึงบังคับใช้รายการโฮสต์ที่อนุญาตไม่ได้ ไม่จำเป็นต้องรีสตาร์ท';

  @override
  String get rigClipboardPermissionHostToRigTitle =>
      'วางคลิปบอร์ดลงในสภาพแวดล้อมนี้หรือไม่';

  @override
  String get rigClipboardPermissionHostToRigBody =>
      'Control Center จะอ่านคลิปบอร์ดของอุปกรณ์คุณและส่งเนื้อหาไปยังสภาพแวดล้อม เนื้อหาในคลิปบอร์ดอาจมีรหัสผ่านหรือความลับอื่น ๆ';

  @override
  String get rigClipboardPermissionRigToHostTitle =>
      'คัดลอกคลิปบอร์ดออกจากสภาพแวดล้อมนี้หรือไม่';

  @override
  String get rigClipboardPermissionRigToHostBody =>
      'Control Center จะอ่านคลิปบอร์ดของสภาพแวดล้อมและแทนที่คลิปบอร์ดของอุปกรณ์คุณด้วยเนื้อหานั้น โปรดถือว่าเนื้อหาจากสภาพแวดล้อมไม่น่าเชื่อถือ';

  @override
  String get rigClipboardAllowTenMinutes => 'อนุญาตเป็นเวลา 10 นาที';

  @override
  String get rigClipboardAlwaysAllow => 'อนุญาตเสมอ';

  @override
  String get rigClipboardSettingsTitle => 'การเข้าถึงคลิปบอร์ด';

  @override
  String get rigClipboardSettingsHint =>
      'เลือกการถ่ายโอนคลิปบอร์ดที่สามารถทำงานได้โดยไม่ต้องถาม สิทธิ์ชั่วคราวจะหมดอายุหลังจาก 10 นาที';

  @override
  String get rigClipboardAlwaysPasteTitle => 'อนุญาตให้วางลงในสภาพแวดล้อมเสมอ';

  @override
  String get rigClipboardAlwaysPasteDescription =>
      'ส่งคลิปบอร์ดของอุปกรณ์นี้ไปยังสภาพแวดล้อมใดก็ได้โดยไม่ต้องถาม';

  @override
  String get rigClipboardAlwaysCopyTitle => 'อนุญาตให้คัดลอกจากสภาพแวดล้อมเสมอ';

  @override
  String get rigClipboardAlwaysCopyDescription =>
      'วางเนื้อหาคลิปบอร์ดจากสภาพแวดล้อมใดก็ได้บนอุปกรณ์นี้โดยไม่ต้องถาม';

  @override
  String get workspaceGitHubIdentity => 'ตัวตน GitHub';

  @override
  String get workspaceGitHubIdentityDescription =>
      'วิธีที่งาน GitHub เบื้องหลังยืนยันตัวตนในพื้นที่ทำงานนี้ สืบทอด App ของการติดตั้ง ใช้ App อื่น หรือโทเค็นเข้าถึงส่วนบุคคลเท่านั้น';

  @override
  String get workspaceGitHubModeInherit => 'ใช้ GitHub App ของการติดตั้งนี้';

  @override
  String get workspaceGitHubModeApp => 'ใช้ GitHub App อื่น';

  @override
  String get workspaceGitHubModePat => 'โทเค็นเข้าถึงส่วนบุคคลเท่านั้น';

  @override
  String get workspaceGitHubInheritHint =>
      'ใช้ GitHub App ที่ เซิร์ฟเวอร์ → แอปผู้ให้บริการ';

  @override
  String get workspaceGitHubAppHint =>
      'ตัวตนบอทและการสำรวจของพื้นที่นี้ สมาชิกเข้าสู่ระบบที่ คุณ ผ่าน App นี้';

  @override
  String get workspaceGitHubPatLabel => 'โทเค็นเบื้องหลัง';

  @override
  String get workspaceGitHubPatDescription =>
      'สำหรับการสำรวจและเอเจนต์ในพื้นที่นี้ ไม่ใช่โทเค็นโปรไฟล์ของสมาชิก';

  @override
  String get workspaceGitHubHasPat => 'มีโทเค็นเบื้องหลังถูกเก็บไว้';

  @override
  String get workspaceGitHubNoPat => 'ไม่มีโทเค็นเบื้องหลัง';

  @override
  String get profileOverlayHint =>
      'ช่องเหล่านี้คือคุณในพื้นที่ทำงานนี้ ช่องว่างสืบทอดชื่อและอีเมลของบัญชี การเปลี่ยนพื้นที่เปลี่ยนเลเยอร์นี้';

  @override
  String get forgeConnectionsThisWorkspace =>
      'เข้าสู่ระบบหรือวางโทเค็นสำหรับพื้นที่ทำงานนี้';

  @override
  String get stackStartNextPart => 'เริ่มส่วนถัดไป';

  @override
  String get stackPartNameTitle => 'ชื่อส่วน';

  @override
  String get stackPartNameHint => 'เช่น migration';

  @override
  String get stackPublish => 'เผยแพร่สแตก';

  @override
  String get stackCurrentPart => 'ปัจจุบัน';

  @override
  String get stackSwitchDirty => 'คอมมิตหรือทิ้งการเปลี่ยนแปลงก่อนสลับส่วน';

  @override
  String get stackCutFailed => 'เริ่มส่วนถัดไปไม่ได้';

  @override
  String get stackPublishFailed => 'เผยแพร่สแตกไม่ได้';

  @override
  String get stackPublished => 'เผยแพร่สแตกเป็นฉบับร่างแล้ว';

  @override
  String get stackOpenPullRequest => 'เปิดพูลรีเควสต์';

  @override
  String get stackSection => 'สแตก';

  @override
  String get mergeConflictsButton => 'ข้อขัดแย้ง';

  @override
  String mergeConflictsFileCount(int count, String base) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ไฟล์ขัดแย้งกับ $base',
    );
    return '$_temp0';
  }

  @override
  String get mergeConflictsLoading => 'กำลังค้นหาไฟล์ที่ขัดแย้ง…';

  @override
  String get mergeConflictsLoadFailed => 'ไม่สามารถแสดงรายการไฟล์ที่ขัดแย้งได้';

  @override
  String get mergeConflictsNoneFound =>
      'ไม่พบไฟล์ที่ขัดแย้ง GitHub อาจยังอัปเดต pull request นี้อยู่';

  @override
  String get askAiToFixConflicts => 'ให้ AI แก้ไขข้อขัดแย้ง';

  @override
  String get fixConflictsStarted =>
      'เอเจนต์กำลังแก้ไขข้อขัดแย้งในแชทของ pull request นี้';

  @override
  String failedToStartConflictFix(String error) {
    return 'ไม่สามารถเริ่มการแก้ไขข้อขัดแย้งได้: $error';
  }
}
