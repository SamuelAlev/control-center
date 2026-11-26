// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String steeringForceSendFailed(String error) {
    return 'Không thể gửi ngay bây giờ: $error';
  }

  @override
  String get questionAnswerNotDelivered =>
      'Câu trả lời của bạn chưa được gửi. Có thể câu hỏi đã được trả lời, hoặc tác tử đã ngừng chờ.';

  @override
  String get succeeded => 'Thành công';

  @override
  String agentRunRetryLabel(int number, String time) {
    return 'Thử lại #$number · $time';
  }

  @override
  String agentRunStarting(String time) {
    return 'Đang bắt đầu · $time';
  }

  @override
  String get agentActivityFollowingLive => 'Đang theo dõi hoạt động trực tiếp';

  @override
  String get agentActivityJumpToLatest => 'Nhảy tới mới nhất';

  @override
  String get agentActivityLoadFailed =>
      'Không tải được hoạt động của lần chạy này';

  @override
  String get agentActivityNotRecorded =>
      'Không có hoạt động nào được ghi lại cho lần chạy này';

  @override
  String get agentActivityNotRecordedHint =>
      'Các lần chạy kết thúc trước khi bật ghi hoạt động sẽ không có dòng thời gian.';

  @override
  String get agentActivityRunUnavailable => 'Lần chạy này không còn khả dụng';

  @override
  String agentActivitySubagentOf(String agent) {
    return 'Subagent của $agent';
  }

  @override
  String get agentActivityUnsupported =>
      'Máy chủ đang kết nối không hỗ trợ ghi hoạt động';

  @override
  String get agentActivityUnsupportedHint =>
      'Khởi động lại ứng dụng để nhận bản dựng máy chủ mới nhất.';

  @override
  String get agentActivityWaiting => 'Đang chờ hoạt động…';

  @override
  String get created => 'Đã tạo';

  @override
  String get dictationStart => 'Bắt đầu đọc chính tả';

  @override
  String get dictationListening => 'Đang nghe…';

  @override
  String get dictationUnavailable =>
      'Đọc chính tả cần mô hình giọng nói trên máy chủ. Thiết lập trong cài đặt giọng nói.';

  @override
  String get dictationFailedToStart => 'Không thể bắt đầu đọc chính tả';

  @override
  String get dictationHoldToTalkTitle => 'Giữ để nói';

  @override
  String get dictationHoldToTalkDescription =>
      'Giữ nút mic hoặc phím tắt để đọc chính tả, thả ra để dừng. Khi tắt, nhấn một lần để bắt đầu và nhấn lại để dừng.';

  @override
  String get focusConversation => 'Tập trung cuộc trò chuyện';

  @override
  String get ideAgentActivity => 'Hoạt động agent';

  @override
  String get keybindingPushToTalk => 'Nhấn để nói';

  @override
  String get agentPermissions => 'Quyền của agent';

  @override
  String get agentPermissionsSettingsDescription =>
      'Chọn việc agent được tự làm, phải hỏi trước, hoặc không bao giờ được làm — theo không gian làm việc, agent hoặc space.';

  @override
  String get agentPermissionsMatrixDescription =>
      'Đặt quyết định cho từng loại tác động. Quy tắc xếp tầng: space ghi đè agent, ghi đè không gian làm việc, ghi đè preset chế độ. Quy tắc cụ thể nhất thắng.';

  @override
  String get guardrailLoading => 'Đang tải quy tắc…';

  @override
  String get guardrailRulesLoadFailed => 'Không tải được quy tắc quyền.';

  @override
  String get guardrailScopeWorkspace => 'Không gian làm việc';

  @override
  String get guardrailScopeAgent => 'Agent';

  @override
  String get guardrailScopeSpace => 'Space';

  @override
  String get guardrailSelectAgent => 'Chọn một agent';

  @override
  String get guardrailSelectSpace => 'Chọn một space';

  @override
  String get guardrailNoAgents =>
      'Chưa có agent nào trong không gian làm việc này.';

  @override
  String get guardrailNoSpaces =>
      'Chưa có space nào trong không gian làm việc này.';

  @override
  String get guardrailClassFileDelete => 'Xóa một tệp';

  @override
  String get guardrailClassFileWriteOutsideWorktree =>
      'Ghi bên ngoài cây làm việc';

  @override
  String get guardrailClassGitCommit => 'Tạo một commit';

  @override
  String get guardrailClassGitPush => 'Push lên remote';

  @override
  String get guardrailClassPrCreate => 'Mở một pull request';

  @override
  String get guardrailClassPrPublish =>
      'Cập nhật hoặc hợp nhất một pull request';

  @override
  String get guardrailClassVendorSyncWrite => 'Ghi vào tracker bên ngoài';

  @override
  String get guardrailClassNetworkEgress => 'Truy cập mạng';

  @override
  String get guardrailClassSecretAccess => 'Đọc một secret';

  @override
  String get guardrailClassPackageInstall => 'Cài một gói';

  @override
  String get guardrailClassProcessSpawn => 'Chạy một tiến trình';

  @override
  String get guardrailClassWorkspaceMutation =>
      'Thay đổi cấu trúc không gian làm việc';

  @override
  String get guardrailClassEnclosureControl => 'Điều khiển một enclosure (rig)';

  @override
  String get navRigs => 'Rigs';

  @override
  String get rigsUnsupportedServer =>
      'Máy chủ này không thể lưu trữ bất kỳ bề mặt rig nào. Hãy kiểm tra các yêu cầu đối với máy chủ lưu trữ cho máy bạn muốn sử dụng.';

  @override
  String get rigSurfaceComputer => 'Máy tính';

  @override
  String get rigSurfaceBrowser => 'Trình duyệt';

  @override
  String get rigSurfaceAndroid => 'Android';

  @override
  String get rigSurfaceIosSimulator => 'Trình mô phỏng iOS';

  @override
  String get rigSurfaceAppWindow => 'Cửa sổ ứng dụng';

  @override
  String rigSurfaceBrowserEngine(String engine) {
    return '$engine';
  }

  @override
  String rigBrowserEngineHint(String engine) {
    return 'Một $engine dùng một lần, tách biệt khỏi máy của bạn. Mở engine khác để so sánh cùng một trang cạnh nhau.';
  }

  @override
  String get rigPhaseReady => 'Sẵn sàng';

  @override
  String get rigPhaseStarting => 'Đang bắt đầu';

  @override
  String get rigPhaseParked => 'Đã đỗ';

  @override
  String get rigPhaseClosing => 'Đang đóng';

  @override
  String get rigPhaseClosed => 'Đóng';

  @override
  String get rigPhaseFailed => 'Thất bại';

  @override
  String get rigPhaseUnknown => 'Không xác định';

  @override
  String get rigNotAccelerated => 'Giả lập';

  @override
  String get rigAudioListen => 'Nghe máy';

  @override
  String get rigAudioMute => 'Tắt tiếng máy';

  @override
  String get rigYouHaveControl => 'Bạn đang điều khiển';

  @override
  String get rigBackendAvailable => 'Khả dụng';

  @override
  String get rigBackendUnavailable => 'Không khả dụng';

  @override
  String get rigEgressNotEnforced =>
      'Mạng không bị khép kín trên backend này — nó tự quản lý kết nối.';

  @override
  String get rigStartMachine => 'Khởi động máy';

  @override
  String get rigStartHint =>
      'Khởi động VM dùng một lần mà bạn và các agent chia sẻ cho cuộc hội thoại này. Máy bị hủy khi đóng, và không gì trong đó chạm tới máy tính của bạn.';

  @override
  String get rigStartAndroidHint =>
      'Kết nối với trình giả lập Android đang chạy sẵn trên máy chủ. Quyền truy cập mạng không được cô lập.';

  @override
  String get rigStartIosHint =>
      'Tạo một Trình mô phỏng iOS tạm thời trên máy chủ macOS. Trình mô phỏng sẽ bị xóa khi môi trường kiểm thử đóng; quyền truy cập mạng không được cô lập.';

  @override
  String get rigTechnicalDetails => 'Chi tiết kỹ thuật';

  @override
  String get rigStopMachine => 'Dừng máy';

  @override
  String get rigHomeButton => 'Màn hình chính';

  @override
  String get rigRotateClockwise => 'Xoay theo chiều kim đồng hồ';

  @override
  String get rigRotateCounterclockwise => 'Xoay ngược chiều kim đồng hồ';

  @override
  String get rigTakeScreenshot => 'Chụp màn hình';

  @override
  String get rigScreenshotSaved => 'Đã lưu ảnh chụp màn hình';

  @override
  String rigScreenshotSaveFailed(String error) {
    return 'Không thể lưu ảnh chụp màn hình: $error';
  }

  @override
  String get rigSurfaceUnavailable =>
      'Máy chủ này không thể chạy loại máy này.';

  @override
  String get rigTabNeedsConversation =>
      'Hãy mở cuộc hội thoại trước — máy thuộc về một cuộc hội thoại, nên bạn và các agent nhìn cùng một màn hình.';

  @override
  String get ideMenuSectionTools => 'Công cụ';

  @override
  String get ideMenuSectionMachines => 'Máy';

  @override
  String get ideMenuSectionReopen => 'Mở lại';

  @override
  String get ideMenuSearchHint => 'Tìm kiếm';

  @override
  String get ideMenuNoMatches => 'Không có kết quả';

  @override
  String get rigMenuComputer => 'Máy tính';

  @override
  String get rigMenuBrowser => 'Trình duyệt';

  @override
  String get rigMenuAndroid => 'Android';

  @override
  String get rigMenuIosSimulator => 'Trình mô phỏng iOS';

  @override
  String rigLabelNumbered(String label, String suffix) {
    return '$label $suffix';
  }

  @override
  String ideCloseKeepTitle(String name) {
    return 'Đóng $name?';
  }

  @override
  String get ideCloseKeepBodyMachine =>
      'Máy vẫn chạy nền — mở lại bất cứ lúc nào từ thanh bên. Tắt máy để giải phóng bộ nhớ ngay.';

  @override
  String get ideCloseKeepBodyShell =>
      'Lệnh vẫn chạy nền — mở lại shell bất cứ lúc nào từ thanh bên. Kết thúc để dừng việc đang làm ngay.';

  @override
  String get ideCloseKeepBodyAgent =>
      'Agent vẫn làm việc nền — mở lại cuộc hội thoại bất cứ lúc nào từ thanh bên. Dừng để kết thúc lần chạy ngay.';

  @override
  String get ideCloseKeepRunning => 'Tiếp tục chạy';

  @override
  String get ideCloseShutDownMachine => 'Tắt máy';

  @override
  String get ideCloseEndShell => 'Kết thúc shell';

  @override
  String get ideCloseStopAgent => 'Dừng agent';

  @override
  String get rigsSettingsSubtitle =>
      'Những gì máy chủ này có thể khởi động, image gốc cần thiết, và các máy đang chạy';

  @override
  String get rigsCapabilitiesTitle => 'Máy chủ này';

  @override
  String get rigInstallIosAutomation => 'Cài đặt cầu nối tự động hóa iOS';

  @override
  String get rigInstallingIosAutomation =>
      'Đang cài đặt cầu nối tự động hóa iOS…';

  @override
  String get rigIosAutomationInstalled => 'Đã cài đặt cầu nối tự động hóa iOS';

  @override
  String get rigsImagesTitle => 'Image gốc';

  @override
  String get rigsImagesHint =>
      'Mỗi rig khởi động một trong các image chỉ đọc này. Mỗi phiên ghi vào overlay dùng một lần, nên một rig không bao giờ thay đổi điểm xuất phát của rig tiếp theo.';

  @override
  String get rigsRunningTitle => 'Đang chạy';

  @override
  String get rigsNoneRunning => 'Không có máy nào đang chạy.';

  @override
  String get rigsCustomImagesTitle =>
      'Image tùy chỉnh (không gian làm việc này)';

  @override
  String get rigsCustomImagesHint =>
      'Gắn Terminal (VM) hoặc Browser (VM) với image của bạn — mở rộng mặc định bằng công cụ dự án cần, hoặc dùng image tương thích từ registry. Máy mới dùng image này; máy đang chạy giữ nguyên. Xem hướng dẫn rigs để biết image phải cung cấp gì.';

  @override
  String get rigsCustomTerminalImageLabel => 'Image Terminal (VM)';

  @override
  String get rigsCustomBrowserImageLabel => 'Image Browser (VM)';

  @override
  String get rigsCustomImagePlaceholder =>
      'vd. ghcr.io/acme/dev-shell:1.2 — để trống để dùng mặc định';

  @override
  String get rigsCustomImageInvalid =>
      'Nhập tham chiếu registry dạng repo/name:tag. Không cho phép đường dẫn cục bộ và archive.';

  @override
  String get rigsCustomImageSaved =>
      'Đã lưu. Máy mới khởi động với image này; máy đang chạy giữ nguyên.';

  @override
  String get rigsEgressTitle => 'Egress trình duyệt (không gian làm việc này)';

  @override
  String get rigsEgressHint =>
      'Host bổ sung mà trình duyệt khép kín được phép truy cập — mỗi dòng một mục: host chính xác (api.example.com) hoặc wildcard cho subdomain (*.example.com). Site sản phẩm vẫn được phép dù sao. Máy mới nhận danh sách này; máy đang chạy giữ những gì lúc khởi động.';

  @override
  String rigsEgressInvalid(String host) {
    return '\"$host\" không phải mục host hợp lệ.';
  }

  @override
  String get rigsEgressSaved =>
      'Đã lưu. Máy trình duyệt mới cho phép các host này; máy đang chạy giữ nguyên.';

  @override
  String get rigImageInstalled => 'Đã cài';

  @override
  String get rigImageNotDownloaded => 'Chưa tải';

  @override
  String get rigImageNotPublished => 'Chưa xuất bản';

  @override
  String get rigImageNotPublishedHint =>
      'Chưa có image nào được xuất bản cho mục này, nên không có gì để tải. Nhập image đĩa tương thích để bật.';

  @override
  String get rigImageDownload => 'Tải xuống';

  @override
  String get rigImageDownloading => 'Đang tải…';

  @override
  String get rigImageImport => 'Nhập';

  @override
  String get rigImageImportMessage =>
      'Đường dẫn tới image đĩa qcow2 trên hệ thống tệp của máy chủ. File được sao chép vào kho image, nên có thể dời file sau đó.';

  @override
  String get rigConnectingStream => 'Đang kết nối tới rig';

  @override
  String get rigStreamNotAllowed => 'Bạn không có quyền truy cập rig này.';

  @override
  String get rigStreamNotRunning => 'Rig này không còn chạy.';

  @override
  String get rigStreamNeedsFfmpeg =>
      'Xem trực tiếp cần ffmpeg trên host này. Cài ffmpeg rồi mở lại tab.';

  @override
  String get rigStreamNeedsScreenCapture =>
      'Chế độ xem trực tiếp cần quyền Ghi màn hình. Hãy cấp quyền cho Control Center trong Cài đặt hệ thống rồi mở lại tab.';

  @override
  String get rigStreamEnded => 'Xem trực tiếp đã kết thúc.';

  @override
  String get rigStreamFailed => 'Không mở được xem trực tiếp.';

  @override
  String get rigStreamDisconnected => 'Chưa kết nối máy chủ.';

  @override
  String rigDropSendingOne(String name) {
    return 'Đang sao chép \"$name\" vào máy…';
  }

  @override
  String rigDropSendingMany(int count) {
    return 'Đang sao chép $count tệp vào máy…';
  }

  @override
  String get rigTerminalDropSending => 'Đang sao chép vào máy…';

  @override
  String get rigTerminalPasteImage => 'Đã lưu ảnh dán vào máy';

  @override
  String get rigPortsTitle => 'Cổng chuyển tiếp';

  @override
  String get rigPortsTooltip => 'Cổng đang mở trong máy này';

  @override
  String get rigPortsEmpty =>
      'Chưa có gì đang lắng nghe. Chạy máy chủ trong terminal — máy chủ phát triển cổng 3000 sẽ hiện ở đây.';

  @override
  String get rigPortsAdd => 'Thêm cổng';

  @override
  String get rigPortsAddHint => 'Cổng guest cần chuyển tiếp (vd. 3000)';

  @override
  String get rigPortsAutoForward => 'Tự chuyển tiếp cổng';

  @override
  String get rigPortsCopyUrl => 'Sao chép URL cục bộ';

  @override
  String rigPortsCopiedUrl(String url) {
    return 'Đã sao chép $url';
  }

  @override
  String get rigPortsStopForward => 'Dừng chuyển tiếp';

  @override
  String get rigPortsExposeLan => 'Chia sẻ trên mạng cục bộ';

  @override
  String get rigPortsLanPrivate => 'Chỉ cục bộ';

  @override
  String get rigPortsLanShared => 'Trên mạng';

  @override
  String get rigPortsSetDomain => 'Đặt tên miền Browser (.test)';

  @override
  String get rigPortsDomainHint =>
      'Tên miền cho Browser (VM), vd. myapp.test — truy cập được ở đó, không phải trên host';

  @override
  String get rigPortsProcessUnknown => 'tiến trình không xác định';

  @override
  String get rigPortsInactive => 'không lắng nghe';

  @override
  String get rigPortsTooltipHost => 'Các cổng đang mở trong terminal này';

  @override
  String get rigPortsEmptyHost =>
      'Chưa có gì đang lắng nghe trong terminal này. Hãy khởi động máy chủ và nó sẽ hiện ở đây.';

  @override
  String get rigPortsAddHintHost => 'Cổng cần ánh xạ (vd. 5173)';

  @override
  String get rigPortsLocalPortHint => 'Cổng cục bộ (tuỳ chọn)';

  @override
  String rigPortsDestDesktop(int port) {
    return 'localhost:$port';
  }

  @override
  String rigPortsDestBrowser(int port) {
    return 'localhost:$port trong trình duyệt (VM)';
  }

  @override
  String get rigPortsDestBrowserUnreachable => 'trình duyệt (VM) chưa gắn';

  @override
  String rigPortsDestAndroid(int port) {
    return 'localhost:$port trên Android';
  }

  @override
  String get rigPortsDestAndroidUnreachable => 'Android chưa gắn';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Còn $count image gốc chưa tải',
      one: 'Còn 1 image gốc chưa tải',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => 'Cho phép';

  @override
  String get guardrailDecisionPrompt => 'Hỏi trước';

  @override
  String get guardrailDecisionDeny => 'Từ chối';

  @override
  String get guardrailSourceThisScope => 'Phạm vi này';

  @override
  String get guardrailSourceDefault => 'Mặc định tích hợp';

  @override
  String get guardrailSourcePreset => 'Preset chế độ';

  @override
  String get guardrailSourceInherited => 'Kế thừa';

  @override
  String get guardrailClearToInherited => 'Xóa về kế thừa';

  @override
  String get guardrailWhatIf => 'Nếu như?';

  @override
  String get guardrailWhatIfDescription =>
      'Xem các quy tắc hiện tại sẽ quyết định thế nào với một hành động, dùng cùng logic mà agent chạy.';

  @override
  String get guardrailProbeActionLabel => 'Hành động';

  @override
  String get guardrailProbeCommandLabel => 'Lệnh (tùy chọn)';

  @override
  String get guardrailProbeCommandHint => 'vd. git push origin main';

  @override
  String get guardrailProbeAgentLabel => 'Agent (tùy chọn)';

  @override
  String get guardrailProbeSpaceLabel => 'Không gian (tùy chọn)';

  @override
  String get guardrailProbeNone => 'Không';

  @override
  String get guardrailProbeModeLabel => 'Chế độ';

  @override
  String get guardrailProbeResult => 'Kết quả';

  @override
  String get guardrailProbeSource => 'Nguồn:';

  @override
  String get guardrailAdapterMatrix => 'Nơi quy tắc được thực thi';

  @override
  String get guardrailAdapterMatrixDescription =>
      'Tài liệu trung thực: mỗi hiệu ứng thực sự bị chặn ở đâu, theo từng agent runner. Đây là mô tả thực tế, không phải đảm bảo — hiệu ứng mà runner thực hiện ngoài luồng thì không chặn được.';

  @override
  String get guardrailEffectColumn => 'Hiệu ứng';

  @override
  String get guardrailAdapterHarness => 'Harness tích hợp';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => 'Sàn sandbox';

  @override
  String get guardrailEnforcementPolicyGate => 'Cổng chính sách';

  @override
  String get guardrailEnforcementSandbox => 'Chỉ sandbox';

  @override
  String get guardrailEnforcementNone => 'Không thể thực thi';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      'Quyết định quyền được kiểm tra trước khi hiệu ứng chạy và có thể chặn.';

  @override
  String get guardrailEnforcementSandboxHelp =>
      'Chỉ sandbox ràng buộc; quy tắc quyền không được tham chiếu.';

  @override
  String get guardrailEnforcementNoneHelp =>
      'Quyết định chỉ mang tính tư vấn — không chặn được ở đây.';

  @override
  String get obsStatCost => 'chi phí';

  @override
  String obsStatDelegatedCost(String amount) {
    return '+$amount ủy thác';
  }

  @override
  String get obsStatDuration => 'thời lượng';

  @override
  String get obsStatTokens => 'token';

  @override
  String get obsStatTools => 'công cụ';

  @override
  String get openAgentActivity => 'Mở hoạt động';

  @override
  String get orgChart => 'Sơ đồ tổ chức';

  @override
  String get orgChartEmpty => 'Chưa có agent';

  @override
  String get navCalendar => 'Lịch';

  @override
  String get serverConnection => 'Kết nối máy chủ';

  @override
  String get serverModeLocal => 'Chạy trong ứng dụng này';

  @override
  String get serverModeLocalDescription =>
      'Control Center chạy máy chủ riêng trên máy này và lưu dữ liệu của bạn tại chỗ.';

  @override
  String get serverRemoteUrl => 'URL máy chủ';

  @override
  String get serverRemoteDeviceId => 'ID thiết bị';

  @override
  String get serverRemotePairingKey => 'Khóa ghép nối';

  @override
  String get serverRemotePairingKeyHint => 'Dán khóa ghép nối từ máy chủ từ xa';

  @override
  String get serverSetupInviteCode => 'Mã mời';

  @override
  String get serverSetupInviteCodeHint =>
      'Dán mã mời dùng một lần (để trống để dùng khóa ghép nối)';

  @override
  String get serverDiscoveryTooltip => 'Tìm máy chủ trên mạng của bạn';

  @override
  String get serverDiscoveryTitle => 'Máy chủ trên mạng của bạn';

  @override
  String get serverDiscoverySearching => 'Đang tìm máy chủ…';

  @override
  String get serverDiscoveryEmpty =>
      'Không tìm thấy máy chủ. Kiểm tra máy chủ đang chạy và thiết bị này có thể truy cập được, rồi tìm lại.';

  @override
  String get serverDiscoveryRefresh => 'Tìm lại';

  @override
  String get serverListActive => 'Đang dùng';

  @override
  String get serverListSwitch => 'Chuyển';

  @override
  String get serverListAddTitle => 'Thêm máy chủ';

  @override
  String get serverListRemoveActiveHint =>
      'Chuyển sang máy chủ khác trước khi xóa máy chủ này.';

  @override
  String get serverSwitchFailedTitle => 'Không thể chuyển máy chủ';

  @override
  String get serverListInsecureBadge => 'Không an toàn';

  @override
  String get connectionPathLocal => 'Cục bộ';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => 'Đang tắt';

  @override
  String get shutdownSubtitle => 'Đang đóng máy chủ cục bộ';

  @override
  String get shutdownServiceApprovals => 'Phê duyệt';

  @override
  String get shutdownServiceBackgroundJobs => 'Tác vụ nền';

  @override
  String get shutdownServiceScheduler => 'Bộ lập lịch tác vụ';

  @override
  String get shutdownServiceCalendar => 'Đồng bộ lịch';

  @override
  String get shutdownServiceWeather => 'Thời tiết';

  @override
  String get shutdownServiceSoundscape => 'Cảnh âm thanh';

  @override
  String get shutdownServiceMeetings => 'Cuộc họp';

  @override
  String get shutdownServiceVoiceModels => 'Mô hình giọng nói';

  @override
  String get shutdownServiceNetworking => 'Mạng';

  @override
  String get shutdownServicePresence => 'Hiện diện';

  @override
  String get shutdownServiceDataSync => 'Đồng bộ dữ liệu';

  @override
  String get shutdownServiceDeviceRelay => 'Chuyển tiếp thiết bị';

  @override
  String get shutdownServiceMcpConnections => 'Kết nối MCP';

  @override
  String get shutdownServiceCodeEditors => 'Trình soạn mã';

  @override
  String get serverSharingTitle => 'Chia sẻ máy chủ này';

  @override
  String get serverSharingDescription =>
      'Cho phép các thiết bị khác của bạn truy cập máy chủ này. Không gì được công khai trừ khi bạn bật đường hầm bên dưới. Lời mời ghép nối tự động gắn địa chỉ hiện tại của máy chủ — tạo chúng trong cài đặt không gian làm việc.';

  @override
  String get serverSharingUnavailable =>
      'Không có tùy chọn chia sẻ trên máy chủ này.';

  @override
  String get serverSharingMdnsLabel => 'Khám phá LAN';

  @override
  String get serverSharingMdnsOn =>
      'Đang quảng bá máy chủ này trên mạng cục bộ (mDNS)';

  @override
  String get serverSharingMdnsOff => 'Không quảng bá trên mạng cục bộ (mDNS)';

  @override
  String get serverSharingTunnelLabel => 'Đường hầm';

  @override
  String get serverSharingTunnelHelper =>
      'Bật đường hầm cho phép truy cập máy chủ này từ internet. Công khai là tùy chọn và mặc định tắt.';

  @override
  String get serverSharingProviderOff => 'Tắt';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => 'URL công khai';

  @override
  String get serverSharingTunnelStarting => 'Đang khởi động tunnel…';

  @override
  String serverSharingTunnelError(String error) {
    return 'Lỗi tunnel: $error';
  }

  @override
  String get serverSharingTunnelUpNoUrl =>
      'Tunnel đã hoạt động. Truy cập qua hostname DNS đã cấu hình.';

  @override
  String get serverSharingRelayLabel => 'Relay';

  @override
  String serverSharingRelayUsage(String amount) {
    return 'Đã relay tháng này: $amount';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return 'Phiên relay đang hoạt động: $count';
  }

  @override
  String get serverSharingUpdateFailedTitle => 'Không thể cập nhật chia sẻ';

  @override
  String get pairNewClient => 'Ghép nối máy khách mới';

  @override
  String get pairClientNameHint =>
      'Đặt tên máy khách này (vd. Laptop công việc)';

  @override
  String get pairClientTypeWeb => 'Trình duyệt web';

  @override
  String get pairClientTypeDesktop => 'Ứng dụng máy tính';

  @override
  String get pairClientTypePhone => 'Điện thoại';

  @override
  String get pairAction => 'Ghép nối';

  @override
  String get revoke => 'Thu hồi';

  @override
  String get pairCredentialsIntro =>
      'Kết nối máy khách mới bằng các thông tin này, hoặc mở liên kết trong máy đó.';

  @override
  String get pairLinkLabel => 'Liên kết';

  @override
  String get pairScanQr => 'Quét mã QR này bằng camera điện thoại để ghép nối.';

  @override
  String get pairServerUnreachableTitle => 'Không thể truy cập';

  @override
  String get pairServerUnreachable =>
      'Các thiết bị khác không thể truy cập máy chủ này trực tiếp, nên máy khách mới không thể kết nối. Đặt URL công khai của máy chủ để ghép nối thêm máy khách.';

  @override
  String get serverSetupRunLocal => 'Chạy trong ứng dụng này';

  @override
  String get serverSetupConnect => 'Kết nối';

  @override
  String get serverSetupInvalidUrl =>
      'Nhập URL máy chủ ws:// hoặc wss:// hợp lệ.';

  @override
  String get serverSetupCouldNotConnect => 'Không thể kết nối';

  @override
  String get serverSetupErrorUnreachable =>
      'Không thể kết nối tới máy chủ. Kiểm tra máy chủ đang chạy và thiết bị này truy cập được (cùng mạng hoặc qua relay).';

  @override
  String get serverSetupErrorIdentityMismatch =>
      'Danh tính máy chủ không khớp với thông tin đã lưu trên thiết bị này. Nếu máy chủ được cài lại hoặc đặt lại, hãy xóa máy chủ đã lưu rồi ghép nối lại.';

  @override
  String get serverSetupErrorAuthRejected =>
      'Máy chủ từ chối thiết bị này. Kiểm tra khóa ghép nối và id thiết bị khớp với những gì máy chủ đã cấp.';

  @override
  String get serverSetupErrorInviteRejected =>
      'Mã mời không hợp lệ hoặc đã hết hạn. Hãy xin một mã mới.';

  @override
  String get serverSetupErrorGeneric =>
      'Đã xảy ra lỗi khi kết nối. Mở chi tiết kỹ thuật bên dưới để biết thêm.';

  @override
  String get serverSetupErrorDetails => 'Chi tiết kỹ thuật';

  @override
  String get serverActivityTitle => 'Hoạt động của máy chủ';

  @override
  String get serverActivityStarting => 'Đang khởi động máy chủ cục bộ…';

  @override
  String get serverActivityConnecting => 'Đang kết nối với máy chủ…';

  @override
  String get serverActivityStartFailed => 'Không thể khởi động máy chủ';

  @override
  String get serverActivityDownloadFailed => 'Tải xuống thất bại';

  @override
  String get serverActivityStatusUnavailable =>
      'Không thể đọc trạng thái mô hình';

  @override
  String get serverActivityPreparingModel => 'Đang chuẩn bị mô hình…';

  @override
  String get serverActivityPortInUse =>
      'Cổng máy chủ đã được sử dụng. Hãy dừng tiến trình khác hoặc chọn cổng khác trên máy chủ.';

  @override
  String get serverActivityStartFailedHint =>
      'Kiểm tra chi tiết kỹ thuật, rồi thử lại từ phần thiết lập máy chủ.';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'thêm $count',
      one: 'thêm 1',
    );
    return '$_temp0';
  }

  @override
  String calendarAllDayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sự kiện',
      one: '1 sự kiện',
    );
    return '$_temp0';
  }

  @override
  String get calendarCollapseAllDay => 'Thu gọn sự kiện cả ngày';

  @override
  String get calendarExpandAllDay => 'Mở rộng sự kiện cả ngày';

  @override
  String get calendarViewMonth => 'Tháng';

  @override
  String get calendarViewWeek => 'Tuần';

  @override
  String get calendarViewAgenda => 'Lịch trình';

  @override
  String get calendarConnectGoogle => 'Kết nối Google Calendar';

  @override
  String get calendarConnectDescription =>
      'Đồng bộ Google Calendar để xem sự kiện tại đây và nhận thông báo trước khi cuộc họp bắt đầu.';

  @override
  String get calendarDisconnect => 'Ngắt kết nối';

  @override
  String get calendarReconnect => 'Kết nối lại';

  @override
  String get calendarEmptyNoEvents => 'Không có sự kiện trong khoảng này';

  @override
  String get calendarJoinMeet => 'Tham gia cuộc họp';

  @override
  String get calendarJoinAndRecord => 'Tham gia và ghi';

  @override
  String get calendarRecordFailed => 'Không thể bắt đầu ghi âm';

  @override
  String get calendarFromCalendar => 'Từ lịch';

  @override
  String get calendarLinkedMeeting => 'Cuộc họp đã liên kết';

  @override
  String get calendarToday => 'Hôm nay';

  @override
  String get calendarAllDay => 'Cả ngày';

  @override
  String calendarWeekNumber(int number) {
    return 'Tuần $number';
  }

  @override
  String get calendarPreviousPeriod => 'Trước';

  @override
  String get calendarNextPeriod => 'Sau';

  @override
  String calendarLastSynced(String time) {
    return 'Đã đồng bộ $time';
  }

  @override
  String get calendarNeverSynced => 'Chưa đồng bộ';

  @override
  String get calendarSyncing => 'Đang đồng bộ…';

  @override
  String get calendarViewDay => 'Ngày';

  @override
  String get calendarShow => 'Hiện';

  @override
  String get calendarHide => 'Ẩn';

  @override
  String get calendarRsvpGoing => 'Tham gia?';

  @override
  String get calendarRsvpYes => 'Có';

  @override
  String get calendarRsvpNo => 'Không';

  @override
  String get calendarRsvpMaybe => 'Có thể';

  @override
  String get calendarRsvpFailed => 'Không thể cập nhật phản hồi của bạn';

  @override
  String get calendarNewEvent => 'Sự kiện mới';

  @override
  String get calendarComposerTitleHint => 'Thêm tiêu đề';

  @override
  String get calendarComposerStarts => 'Bắt đầu';

  @override
  String get calendarComposerEnds => 'Kết thúc';

  @override
  String get calendarComposerDate => 'Ngày';

  @override
  String get calendarComposerEndDate => 'Ngày cuối';

  @override
  String get calendarComposerGuestsHint => 'Thêm khách mời bằng email';

  @override
  String get calendarComposerMeet => 'Thêm liên kết Google Meet';

  @override
  String get calendarComposerLocationHint => 'Thêm địa điểm';

  @override
  String get calendarComposerDescriptionHint => 'Thêm mô tả';

  @override
  String get calendarComposerCalendar => 'Lịch';

  @override
  String get calendarComposerTitleRequired => 'Thêm tiêu đề để lưu sự kiện';

  @override
  String get calendarComposerInvalidGuests =>
      'Một email khách mời không hợp lệ';

  @override
  String get calendarComposerEndBeforeStart =>
      'Sự kiện phải kết thúc sau khi bắt đầu';

  @override
  String get calendarComposerSaveFailed =>
      'Không thể tạo sự kiện. Vui lòng thử lại.';

  @override
  String get calendarComposerGuestsNotified =>
      'Khách mời sẽ nhận email lời mời từ Google.';

  @override
  String get calendarDeleteEvent => 'Xóa sự kiện';

  @override
  String calendarDeleteConfirmTitle(String title) {
    return 'Xóa “$title”?';
  }

  @override
  String get calendarDeleteConfirmBody =>
      'Sự kiện sẽ bị xóa khỏi Google Calendar.';

  @override
  String get calendarDeleteConfirmGuests =>
      'Sự kiện sẽ bị xóa khỏi Google Calendar, và mọi khách mời sẽ được thông báo rằng sự kiện đã bị hủy.';

  @override
  String get calendarDeleteConfirmInvite =>
      'Sự kiện chỉ bị xóa khỏi lịch của bạn. Người tổ chức và các khách mời khác vẫn giữ sự kiện.';

  @override
  String get calendarDeleteConfirmRecurring =>
      'Chỉ xóa lần diễn ra này; phần còn lại của chuỗi được giữ nguyên.';

  @override
  String get calendarDeleteFailed => 'Không thể xóa sự kiện. Vui lòng thử lại.';

  @override
  String get calendarMoveFailed =>
      'Không thể di chuyển sự kiện. Sự kiện đã trở lại vị trí cũ.';

  @override
  String get activityCreatedCalendarEvent => 'Đã tạo sự kiện lịch';

  @override
  String get activityMovedCalendarEvent => 'Đã di chuyển sự kiện lịch';

  @override
  String get activityDeletedCalendarEvent => 'Đã xóa sự kiện lịch';

  @override
  String get calendarAddAccount => 'Thêm tài khoản lịch';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Kết nối tài khoản Google để đồng bộ sự kiện vào không gian này. Các lịch này là của bạn ở đây.';

  @override
  String get calendarSyncNow => 'Đồng bộ ngay';

  @override
  String get calendarNoWorkspace => 'Chọn không gian làm việc để xem lịch';

  @override
  String get calendarConnectError => 'Không thể kết nối Google Calendar';

  @override
  String get notificationMeetingStartsSoon => 'Cuộc họp sắp bắt đầu';

  @override
  String get notifyMeetingStartsSoon => 'Khi cuộc họp trên lịch sắp bắt đầu';

  @override
  String get notificationCalendarAuthExpiredTitle => 'Lịch đã ngắt kết nối';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'Kết nối lại $email để tiếp tục đồng bộ';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'Kết nối lại lịch để tiếp tục đồng bộ';

  @override
  String get notifyCalendarAuthExpired =>
      'Khi tài khoản lịch cần được kết nối lại';

  @override
  String get notificationRigStatusChanged => 'Cập nhật khoang máy';

  @override
  String get notifyRigStatusChanged =>
      'Khi khoang máy bị chiếm quyền, được thu hồi hoặc gặp sự cố';

  @override
  String get notificationRigTakenOver => 'Khoang máy bị chiếm quyền';

  @override
  String get notificationRigTakenOverBody =>
      'Một người đang điều khiển máy; agent có thể xem nhưng không thao tác.';

  @override
  String get notificationRigReleased => 'Đã nhả điều khiển khoang máy';

  @override
  String get notificationRigReleasedBody => 'Agent đã lấy lại máy.';

  @override
  String get notificationRigReclaimed => 'Khoang máy đã được thu hồi';

  @override
  String get notificationRigReclaimedBodyIdle =>
      'Máy đang nhàn rỗi nên đã đóng để giải phóng bộ nhớ.';

  @override
  String get notificationRigReclaimedBodyTtl =>
      'Đã hết thời gian giới hạn nên bị đóng.';

  @override
  String get notificationRigFailed => 'Khoang máy gặp sự cố';

  @override
  String get notificationRigFailedBody =>
      'Hypervisor bên dưới đã dừng. Mở lại máy để tiếp tục.';

  @override
  String get calendarAlertLeadTime => 'Thời gian báo trước';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'Báo trước bao lâu trước cuộc họp';

  @override
  String calendarConnectedAs(String email) {
    return 'Đã kết nối với $email';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count người tham dự';
  }

  @override
  String get calendarEventLabel => 'Sự kiện';

  @override
  String get calendarRecurring => 'Sự kiện định kỳ';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'Người tổ chức';

  @override
  String get calendarYou => 'Bạn';

  @override
  String get calendarShowFewer => 'Ẩn bớt';

  @override
  String get calendarRsvpAwaiting => 'Đang chờ';

  @override
  String calendarParticipantsCount(int count) {
    return '$count người tham gia';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'Xem tất cả $count người tham gia';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count có';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count không';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count có thể';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count đang chờ';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count phút';
  }

  @override
  String get openInEditorPrompt => 'Mở trong trình soạn thảo nào?';

  @override
  String get ideNotInstalled => 'Chưa cài đặt';

  @override
  String openInIde(String editor) {
    return 'Mở trong $editor';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return 'Không thể mở $editor: $error';
  }

  @override
  String get profileSearchHint => 'Tìm pull request…';

  @override
  String get stopAgentRun => 'Dừng chạy';

  @override
  String get stopAgentRunConfirm =>
      'Dừng lần chạy này? Công việc đang làm sẽ bị mất.';

  @override
  String get inProgress => 'Đang thực hiện';

  @override
  String get drafts => 'Bản nháp';

  @override
  String get sortOldest => 'Cũ nhất';

  @override
  String get sortLargest => 'Lớn nhất';

  @override
  String get prFilterTooltip => 'Lọc';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bộ lọc đang bật',
      one: '1 bộ lọc đang bật',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => 'Thêm bộ lọc…';

  @override
  String get prFilterFieldHint => 'Lọc…';

  @override
  String get prFilterCategoryStatus => 'Trạng thái';

  @override
  String get prFilterCategoryAuthor => 'Tác giả';

  @override
  String get prFilterCategoryReviewer => 'Người review';

  @override
  String get prFilterCategoryContent => 'Nội dung';

  @override
  String get prFilterCategoryRepoOwner => 'Chủ sở hữu repository';

  @override
  String get prFilterCategoryRepoName => 'Tên repository';

  @override
  String get prFilterCategoryOpenedDate => 'Ngày mở';

  @override
  String get prFilterCategoryUpdatedDate => 'Ngày cập nhật';

  @override
  String get prFilterQuickToReview => 'Review nhanh';

  @override
  String get prFilterClearAll => 'Xóa bộ lọc';

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
      other: '$count tùy chọn không khớp pull request nào',
      one: '1 tùy chọn không khớp pull request nào',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => 'Tiêu đề hoặc nội dung chứa…';

  @override
  String get prFilterNoOptions => 'Không có tùy chọn khớp';

  @override
  String get prFilterChipIs => 'là';

  @override
  String get prFilterChipIsAnyOf => 'là một trong';

  @override
  String get prFilterChipContains => 'chứa';

  @override
  String get prFilterChipSince => 'kể từ';

  @override
  String get prFilterAddFilterButton => 'Thêm bộ lọc';

  @override
  String prFilterClearCategory(String category) {
    return 'Xóa bộ lọc $category';
  }

  @override
  String get prFilterCurrentUser => 'Người dùng hiện tại';

  @override
  String get prStatusDraft => 'Bản nháp';

  @override
  String get prStatusOpen => 'Mở';

  @override
  String get prStatusInReview => 'Đang review';

  @override
  String get prStatusChangesRequested => 'Yêu cầu thay đổi';

  @override
  String get prStatusApproved => 'Đã duyệt';

  @override
  String get prStatusMerged => 'Đã merge';

  @override
  String get prStatusClosed => 'Đã đóng';

  @override
  String get prDateWindowDay => '1 ngày trước';

  @override
  String get prDateWindowThreeDays => '3 ngày trước';

  @override
  String get prDateWindowWeek => '1 tuần trước';

  @override
  String get prDateWindowMonth => '1 tháng trước';

  @override
  String get prDateWindowThreeMonths => '3 tháng trước';

  @override
  String get prDateWindowSixMonths => '6 tháng trước';

  @override
  String get prDateWindowYear => '1 năm trước';

  @override
  String get prDisplayOptions => 'Tùy chọn hiển thị';

  @override
  String get prDisplayGrouping => 'Nhóm';

  @override
  String get prDisplayOrdering => 'Sắp xếp';

  @override
  String get prDisplayShowDrafts => 'Hiện bản nháp';

  @override
  String get prDisplayMergedWindow => 'Khung thời gian đã merge';

  @override
  String get prDisplayMergedWindowDay => 'Ngày qua';

  @override
  String get prDisplayMergedWindowWeek => 'Tuần qua';

  @override
  String get prDisplayMergedWindowMonth => 'Tháng qua';

  @override
  String get prDisplayProperties => 'Thuộc tính hiển thị';

  @override
  String get prGroupingRepository => 'Repository';

  @override
  String get prGroupingAuthor => 'Tác giả';

  @override
  String get prGroupingStatus => 'Trạng thái';

  @override
  String get prGroupingNone => 'Không nhóm';

  @override
  String get prPropertyRepository => 'Repository';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => 'Nhánh';

  @override
  String get prPropertyUpdated => 'Cập nhật';

  @override
  String get prPropertyAuthor => 'Tác giả';

  @override
  String get prPropertyChecks => 'Kiểm tra';

  @override
  String get prPropertyDiff => 'Diff';

  @override
  String get prPropertyComments => 'Bình luận';

  @override
  String get keybindingOpenFilterMenu => 'Mở menu bộ lọc';

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã chọn $count',
      one: 'Đã chọn 1',
    );
    return '$_temp0';
  }

  @override
  String get summary => 'Tóm tắt';

  @override
  String get kbMove => 'di chuyển';

  @override
  String get kbTabs => 'tab';

  @override
  String get kbSearch => 'tìm kiếm';

  @override
  String get kbViewed => 'đã xem';

  @override
  String get kbCollapse => 'thu gọn';

  @override
  String get appearance => 'Giao diện';

  @override
  String get appearanceSettingsDescription => 'Chủ đề, ngôn ngữ và kiểu chữ.';

  @override
  String get notificationsSettingsDescription =>
      'Chọn sự kiện agent và không gian làm việc nào sẽ thông báo cho bạn.';

  @override
  String get advanced => 'Nâng cao';

  @override
  String get accounts => 'Tài khoản';

  @override
  String get mcpServers => 'Máy chủ MCP';

  @override
  String get remoteControlAndDevices => 'Điều khiển từ xa & thiết bị';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'Ghép nối điện thoại và cấu hình máy chủ điều khiển từ xa.';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'Các mô hình nhận dạng giọng nói và phân tách người nói mà máy chủ này lưu trữ.';

  @override
  String get needsSetupLabel => 'Cần thiết lập';

  @override
  String get collapseSidebar => 'Thu gọn thanh bên';

  @override
  String get expandSidebar => 'Mở rộng thanh bên';

  @override
  String get filterSpacesHint => 'Lọc không gian';

  @override
  String noSpacesMatch(String query) {
    return 'Không có không gian nào khớp \"$query\"';
  }

  @override
  String get privacy => 'Quyền riêng tư';

  @override
  String get sendDiffContentTitle => 'Gửi nội dung diff tới bộ chuyển đổi AI';

  @override
  String get diffSharingOnSubtitle =>
      'Các dòng diff thô được đưa vào prompt của agent để xem xét sâu hơn.';

  @override
  String get diffSharingOffSubtitle =>
      'Agent chỉ dùng siêu dữ liệu có cấu trúc (đường dẫn tệp, số dòng, mô tả PR); không có mã nguồn thô nào rời khỏi ứng dụng.';

  @override
  String get errorReportingTitle => 'Chia sẻ báo cáo sự cố';

  @override
  String get errorReportingOnSubtitle =>
      'Dữ liệu chẩn đoán sự cố, lỗi và hiệu năng được gửi để giúp sửa lỗi (chỉ bản phát hành).';

  @override
  String get errorReportingOffSubtitle =>
      'Chẩn đoán đã tắt. Không gửi báo cáo sự cố hoặc lỗi.';

  @override
  String get onboardingDiagnosticsTitle => 'Giúp cải thiện Control Center';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'Gửi dữ liệu chẩn đoán sự cố, lỗi và hiệu năng để chúng tôi sửa vấn đề nhanh hơn (chỉ bản phát hành). Bạn có thể thay đổi bất cứ lúc nào trong Cài đặt → Quyền riêng tư.';

  @override
  String get usageAnalyticsTitle => 'Chia sẻ phân tích sử dụng';

  @override
  String get usageAnalyticsOnSubtitle =>
      'Mọi client của máy chủ này gửi sự kiện sử dụng được gán bí danh (màn hình, thao tác, số lượng), chỉ ở bản phát hành. Không bao giờ gửi tên, nội dung tin nhắn, đường dẫn tệp hay địa chỉ email.';

  @override
  String get usageAnalyticsOffSubtitle =>
      'Phân tích sử dụng đang tắt. Không client nào của máy chủ này gửi sự kiện sử dụng.';

  @override
  String get usageAnalyticsManagedOnSubtitle =>
      'Các client của máy chủ này gửi sự kiện sử dụng được gán bí danh. Chỉ người vận hành máy chủ mới có thể thay đổi.';

  @override
  String get usageAnalyticsManagedOffSubtitle =>
      'Phân tích sử dụng đang tắt trên máy chủ này. Chỉ người vận hành máy chủ mới có thể thay đổi.';

  @override
  String get onboardingUsageAnalyticsSubtitle =>
      'Gửi sự kiện sử dụng được gán bí danh từ mọi client của máy chủ này để chúng tôi biết tính năng nào hữu ích (chỉ bản phát hành). Không bao giờ gửi tên, nội dung tin nhắn, đường dẫn tệp hay địa chỉ email. Bạn có thể thay đổi bất cứ lúc nào trong Cài đặt → Quyền riêng tư.';

  @override
  String get blocked => 'Bị chặn';

  @override
  String get idle => 'Nhàn rỗi';

  @override
  String get noRunsYet => 'Chưa có lần chạy nào';

  @override
  String get copyPath => 'Sao chép đường dẫn';

  @override
  String get copyRelativePath => 'Sao chép đường dẫn tương đối';

  @override
  String get nameRequired => 'Tên là bắt buộc';

  @override
  String get import => 'Nhập';

  @override
  String get noMatchingAgents => 'Không có agent nào khớp bộ lọc của bạn';

  @override
  String watchVideoOn(String provider) {
    return 'Xem video trên $provider';
  }

  @override
  String get branchTemplate => 'Mẫu tên nhánh';

  @override
  String get branchTemplateDescription =>
      'Mẫu cho nhánh được tạo khi bắt đầu phiếu trong cây làm việc cô lập.';

  @override
  String branchTemplatePreview(String example) {
    return 'Ví dụ: $example';
  }

  @override
  String get deletePipelineRun => 'Xóa lần chạy quy trình';

  @override
  String deletePipelineRunConfirm(String template) {
    return 'Xóa lần chạy này của \"$template\"? Không thể hoàn tác.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'Lỗi khi xóa lần chạy quy trình: $error';
  }

  @override
  String get deleteTicket => 'Xóa phiếu';

  @override
  String deleteTicketConfirm(String title) {
    return 'Xóa \"$title\"? Thao tác này không thể hoàn tác.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'Lỗi khi xóa phiếu: $error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return 'Xóa \"$name\"? Các kho lưu trữ liên kết trên đĩa không bị ảnh hưởng.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'Lỗi khi xóa không gian làm việc: $error';
  }

  @override
  String get indexCode => 'Lập chỉ mục mã';

  @override
  String get indexNoGrammars => 'Chưa cài ngữ pháp mã';

  @override
  String get indexFailed => 'Lập chỉ mục thất bại';

  @override
  String indexedSymbolsCount(int count) {
    return 'Đã lập chỉ mục $count ký hiệu';
  }

  @override
  String get nodeConfigAdvanced => 'Nâng cao';

  @override
  String get nodeConfigReducer => 'Reducer';

  @override
  String get nodeConfigReducerHelp =>
      'Cách gộp khi khóa đầu ra này đã có giá trị';

  @override
  String get nodeConfigTimeoutMs => 'Hết thời gian (ms)';

  @override
  String get nodeConfigRetryAttempts => 'Số lần thử lại';

  @override
  String get nodeConfigContinueOnFail => 'Tiếp tục nếu bước này thất bại';

  @override
  String get nodeConfigTeamId => 'ID nhóm';

  @override
  String get nodeConfigDispatchMode => 'Chế độ điều phối';

  @override
  String get nodeConfigOutputSchema => 'Lược đồ đầu ra (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'JSON Schema mà đầu ra bước phải thỏa';

  @override
  String get nodeConfigBackupRetentionDays => 'Xóa bản sao lưu cũ hơn (ngày)';

  @override
  String get nodeConfigBackupRetentionDaysHelp =>
      'Chỉ xóa bản sao lưu của không gian làm việc này. Nhập số ngày dương.';

  @override
  String get diffLineDisplay => 'Dòng dài trong diff';

  @override
  String get diffLineDisplayDescription =>
      'Xuống dòng hoặc cuộn ngang các dòng dài';

  @override
  String get diffLineWrap => 'Xuống dòng';

  @override
  String get diffLineScroll => 'Cuộn ngang';

  @override
  String get actions => 'Hành động';

  @override
  String get activate => 'Kích hoạt';

  @override
  String get activity => 'Hoạt động';

  @override
  String get activitySearchHint => 'Tìm hoạt động';

  @override
  String get activityNoMatches => 'Không có hoạt động nào khớp bộ lọc';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$start–$end trên $total';
  }

  @override
  String get activityPreviousPage => 'Trang trước';

  @override
  String get activityNextPage => 'Trang sau';

  @override
  String get activityNetworkLocal => 'Localhost';

  @override
  String get activityClearFilter => 'Xóa bộ lọc';

  @override
  String activityFilterIp(String ip) {
    return 'IP $ip';
  }

  @override
  String activityFilterCountry(String country) {
    return 'Quốc gia $country';
  }

  @override
  String get activitySavedWorkspaceLogo => 'Đã lưu logo không gian làm việc';

  @override
  String activityVerbCreated(String target) {
    return 'Đã tạo $target';
  }

  @override
  String activityVerbUpdated(String target) {
    return 'Đã cập nhật $target';
  }

  @override
  String activityVerbDeleted(String target) {
    return 'Đã xóa $target';
  }

  @override
  String activityVerbAdded(String target) {
    return 'Đã thêm $target';
  }

  @override
  String activityVerbRemoved(String target) {
    return 'Đã gỡ $target';
  }

  @override
  String activityVerbInvited(String target) {
    return 'Đã mời $target';
  }

  @override
  String activityVerbChanged(String target) {
    return 'Đã thay đổi $target';
  }

  @override
  String activityVerbStarted(String target) {
    return 'Đã bắt đầu $target';
  }

  @override
  String activityVerbStopped(String target) {
    return 'Đã dừng $target';
  }

  @override
  String activityVerbWrote(String target) {
    return 'Đã viết $target';
  }

  @override
  String get activityTargetAgent => 'agent';

  @override
  String get activityTargetTicket => 'phiếu';

  @override
  String get activityTargetWorkspace => 'không gian làm việc';

  @override
  String get activityTargetRepository => 'kho lưu trữ';

  @override
  String get activityTargetMember => 'thành viên';

  @override
  String get activityTargetInvite => 'lời mời';

  @override
  String get activityTargetSpace => 'không gian';

  @override
  String get activityTargetMessage => 'tin nhắn';

  @override
  String get activityTargetCache => 'bộ nhớ đệm';

  @override
  String get activityTargetFile => 'tệp';

  @override
  String get activityTargetPipeline => 'quy trình';

  @override
  String get activityTargetTemplate => 'mẫu';

  @override
  String get activityTargetProvider => 'nhà cung cấp';

  @override
  String get activityTargetModel => 'mô hình';

  @override
  String get activityTargetSkill => 'kỹ năng';

  @override
  String get activityTargetTodo => 'việc cần làm';

  @override
  String get activityTargetMeeting => 'cuộc họp';

  @override
  String get activityTargetProject => 'dự án';

  @override
  String get activityTargetTeam => 'nhóm';

  @override
  String get activityTargetDevice => 'thiết bị';

  @override
  String get activityTargetPreference => 'tùy chọn';

  @override
  String get activityTargetBudget => 'ngân sách';

  @override
  String activityVerbApproved(String target) {
    return 'Đã phê duyệt $target';
  }

  @override
  String activityVerbArchived(String target) {
    return 'Đã lưu trữ $target';
  }

  @override
  String activityVerbAssigned(String target) {
    return 'Đã gán $target';
  }

  @override
  String activityVerbBackedUp(String target) {
    return 'Đã sao lưu $target';
  }

  @override
  String activityVerbCancelled(String target) {
    return 'Đã hủy $target';
  }

  @override
  String activityVerbCleared(String target) {
    return 'Đã xóa $target';
  }

  @override
  String activityVerbClosed(String target) {
    return 'Đã đóng $target';
  }

  @override
  String activityVerbCommitted(String target) {
    return 'Đã commit $target';
  }

  @override
  String activityVerbCompacted(String target) {
    return 'Đã nén gọn $target';
  }

  @override
  String activityVerbCompleted(String target) {
    return 'Đã hoàn thành $target';
  }

  @override
  String activityVerbConnected(String target) {
    return 'Đã kết nối $target';
  }

  @override
  String activityVerbContinued(String target) {
    return 'Đã tiếp tục $target';
  }

  @override
  String activityVerbDisconnected(String target) {
    return 'Đã ngắt kết nối $target';
  }

  @override
  String activityVerbDispatched(String target) {
    return 'Đã điều phối $target';
  }

  @override
  String activityVerbDrained(String target) {
    return 'Đã xả $target';
  }

  @override
  String activityVerbEnrolled(String target) {
    return 'Đã ghi danh $target';
  }

  @override
  String activityVerbEstimated(String target) {
    return 'Đã ước tính $target';
  }

  @override
  String activityVerbImported(String target) {
    return 'Đã nhập $target';
  }

  @override
  String activityVerbInstalled(String target) {
    return 'Đã cài đặt $target';
  }

  @override
  String activityVerbKilled(String target) {
    return 'Đã buộc dừng $target';
  }

  @override
  String activityVerbMarked(String target) {
    return 'Đã đánh dấu $target';
  }

  @override
  String activityVerbMerged(String target) {
    return 'Đã merge $target';
  }

  @override
  String activityVerbOpened(String target) {
    return 'Đã mở $target';
  }

  @override
  String activityVerbPaused(String target) {
    return 'Đã tạm dừng $target';
  }

  @override
  String activityVerbPolled(String target) {
    return 'Đã poll $target';
  }

  @override
  String activityVerbPrepared(String target) {
    return 'Đã chuẩn bị $target';
  }

  @override
  String activityVerbProcessed(String target) {
    return 'Đã xử lý $target';
  }

  @override
  String activityVerbPublished(String target) {
    return 'Đã xuất bản $target';
  }

  @override
  String activityVerbRefined(String target) {
    return 'Đã tinh chỉnh $target';
  }

  @override
  String activityVerbRefreshed(String target) {
    return 'Đã làm mới $target';
  }

  @override
  String activityVerbRegistered(String target) {
    return 'Đã đăng ký $target';
  }

  @override
  String activityVerbRenamed(String target) {
    return 'Đã đổi tên $target';
  }

  @override
  String activityVerbReordered(String target) {
    return 'Đã sắp xếp lại $target';
  }

  @override
  String activityVerbResponded(String target) {
    return 'Đã phản hồi $target';
  }

  @override
  String activityVerbRestored(String target) {
    return 'Đã khôi phục $target';
  }

  @override
  String activityVerbResumed(String target) {
    return 'Đã tiếp tục $target';
  }

  @override
  String activityVerbRetried(String target) {
    return 'Đã thử lại $target';
  }

  @override
  String activityVerbReverted(String target) {
    return 'Đã hoàn nguyên $target';
  }

  @override
  String activityVerbReviewed(String target) {
    return 'Đã xem xét $target';
  }

  @override
  String activityVerbRan(String target) {
    return 'Đã chạy $target';
  }

  @override
  String activityVerbSelected(String target) {
    return 'Đã chọn $target';
  }

  @override
  String activityVerbSent(String target) {
    return 'Đã gửi $target';
  }

  @override
  String activityVerbStaged(String target) {
    return 'Đã stage $target';
  }

  @override
  String activityVerbSteered(String target) {
    return 'Đã điều hướng $target';
  }

  @override
  String activityVerbSubmitted(String target) {
    return 'Đã gửi $target';
  }

  @override
  String activityVerbSynced(String target) {
    return 'Đã đồng bộ $target';
  }

  @override
  String activityVerbToggled(String target) {
    return 'Đã bật/tắt $target';
  }

  @override
  String activityVerbUninstalled(String target) {
    return 'Đã gỡ cài đặt $target';
  }

  @override
  String activityVerbUnstaged(String target) {
    return 'Đã unstage $target';
  }

  @override
  String get activityTargetActionPolicy => 'chính sách hành động';

  @override
  String get activityTargetGoalRun => 'lần chạy mục tiêu';

  @override
  String get activityTargetRunLog => 'nhật ký chạy';

  @override
  String get activityTargetWorkingMemory => 'bộ nhớ làm việc';

  @override
  String get activityTargetRoutingPolicy => 'chính sách định tuyến';

  @override
  String get activityTargetAutonomy => 'tự chủ';

  @override
  String get activityTargetCalendar => 'lịch';

  @override
  String get activityTargetChecker => 'bộ kiểm tra';

  @override
  String get activityTargetEditor => 'trình soạn thảo';

  @override
  String get activityTargetConfirmation => 'xác nhận';

  @override
  String get activityTargetTunnel => 'đường hầm';

  @override
  String get activityTargetConversation => 'cuộc trò chuyện';

  @override
  String get activityTargetCredentials => 'thông tin xác thực';

  @override
  String get activityTargetDictation => 'đọc chính tả';

  @override
  String get activityTargetAgentRun => 'lần chạy agent';

  @override
  String get activityTargetEvalSuite => 'bộ eval';

  @override
  String get activityTargetWorker => 'worker';

  @override
  String get activityTargetWorktree => 'cây làm việc';

  @override
  String get activityTargetMcpServer => 'máy chủ MCP';

  @override
  String get activityTargetMemoryAccessGrant => 'cấp quyền truy cập bộ nhớ';

  @override
  String get activityTargetMemoryDomain => 'miền bộ nhớ';

  @override
  String get activityTargetMemoryFact => 'sự kiện bộ nhớ';

  @override
  String get activityTargetMemoryPolicy => 'chính sách bộ nhớ';

  @override
  String get activityTargetFeed => 'bảng tin';

  @override
  String get activityTargetNote => 'ghi chú';

  @override
  String get activityTargetOrchestration => 'điều phối';

  @override
  String get activityTargetPipelineRun => 'lần chạy quy trình';

  @override
  String get activityTargetPipelineTrigger => 'trình kích hoạt quy trình';

  @override
  String get activityTargetPlan => 'kế hoạch';

  @override
  String get activityTargetPlaybook => 'kịch bản';

  @override
  String get activityTargetPullRequest => 'pull request';

  @override
  String get activityTargetReview => 'đánh giá';

  @override
  String get activityTargetProcess => 'tiến trình';

  @override
  String get activityTargetProviderPolicy => 'chính sách nhà cung cấp';

  @override
  String get activityTargetReaction => 'phản ứng';

  @override
  String get activityTargetReviewSpace => 'không gian đánh giá';

  @override
  String get activityTargetReviewStudio => 'studio đánh giá';

  @override
  String get activityTargetServerData => 'dữ liệu máy chủ';

  @override
  String get activityTargetSoundscape => 'bối cảnh âm thanh';

  @override
  String get activityTargetSession => 'phiên';

  @override
  String get activityTargetTerminal => 'terminal';

  @override
  String get activityTargetTicketLink => 'liên kết phiếu';

  @override
  String get activityTargetTicketSync => 'đồng bộ phiếu';

  @override
  String get activityTargetProfile => 'hồ sơ';

  @override
  String get activityTargetVoiceProfile => 'hồ sơ giọng nói';

  @override
  String get activityTargetWeather => 'dự báo thời tiết';

  @override
  String get activityTargetWorkProduct => 'sản phẩm công việc';

  @override
  String get activityChangedMemberRole => 'Đã thay đổi vai trò của thành viên';

  @override
  String get activityChangedMemberRepoAccess =>
      'Đã thay đổi quyền truy cập kho lưu trữ của thành viên';

  @override
  String get activityRefreshedWeather => 'Đã làm mới dự báo thời tiết';

  @override
  String get activitySetWeatherLocation => 'Đã đặt vị trí thời tiết';

  @override
  String get activityClearedWeatherLocation => 'Đã xóa vị trí thời tiết';

  @override
  String get activityMarkedAllArticlesRead =>
      'Đã đánh dấu tất cả bài viết là đã đọc';

  @override
  String get activityMarkedArticleRead => 'Đã đánh dấu một bài viết là đã đọc';

  @override
  String get activityUpdatedSavedArticle => 'Đã cập nhật bài viết đã lưu';

  @override
  String get activityTookOverSession => 'Đã tiếp quản phiên';

  @override
  String get activityHandedBackSession => 'Đã trả lại phiên';

  @override
  String get activityCommittedAndPushed => 'Đã commit và push';

  @override
  String get activityBackedUpServer => 'Đã sao lưu dữ liệu máy chủ';

  @override
  String get activityRespondedToInvitation => 'Đã phản hồi lời mời sự kiện';

  @override
  String get activityDisconnectedCalendar => 'Đã ngắt kết nối lịch';

  @override
  String get activityMarkedFileViewed => 'Đã đánh dấu tệp là đã xem';

  @override
  String get activityRespondedToApproval => 'Đã phản hồi yêu cầu phê duyệt';

  @override
  String get activityChangedTunnel => 'Đã thay đổi cài đặt tunnel';

  @override
  String get activitySentMessageToAgent => 'Đã gửi tin nhắn cho agent';

  @override
  String get activityOpenedReviewSpace => 'Đã mở không gian review';

  @override
  String get activityOpenedStandingConversation =>
      'Đã mở cuộc trò chuyện thường trực';

  @override
  String get activityStartedRecording => 'Đã bắt đầu ghi';

  @override
  String get activityStoppedRecording => 'Đã dừng ghi';

  @override
  String get activityToggledMcpServer => 'Đã bật/tắt máy chủ MCP';

  @override
  String get activitySavedApiKey => 'Đã lưu khóa API';

  @override
  String get activityRemovedProviderCredential =>
      'Đã xóa thông tin đăng nhập nhà cung cấp';

  @override
  String get activityUpdatedLinkedRepos =>
      'Đã cập nhật kho lưu trữ đã liên kết';

  @override
  String get activityUnlinkedRepo => 'Đã hủy liên kết kho lưu trữ';

  @override
  String get activityUpdatedActionItem => 'Đã cập nhật mục hành động';

  @override
  String adRulesCount(int count) {
    return '$count quy tắc quảng cáo';
  }

  @override
  String get adapter => 'Bộ điều hợp';

  @override
  String get adapterLabel => 'Bộ điều hợp';

  @override
  String get adapters => 'Bộ điều hợp';

  @override
  String get adaptersAutoDetected =>
      'Đã tự động phát hiện các agent runner khả dụng trên máy này. Cài đặt các công cụ CLI còn thiếu để bật thêm runner.';

  @override
  String get add => 'Thêm';

  @override
  String get addAComment => 'Thêm bình luận';

  @override
  String get addAReaction => 'Thêm phản ứng';

  @override
  String get addASuggestion => 'Thêm đề xuất';

  @override
  String get addAgents => 'Thêm agent';

  @override
  String get addEmoji => 'Thêm emoji';

  @override
  String get addFeed => 'Thêm feed';

  @override
  String get addressBarHint => 'Nhập URL';

  @override
  String get addFromFile => 'Thêm từ tệp';

  @override
  String get addGif => 'Thêm GIF';

  @override
  String get addLocalCheckoutDescription =>
      'Thêm checkout cục bộ để bắt đầu nhắm tới từ không gian làm việc này.';

  @override
  String get addRepository => 'Thêm kho lưu trữ';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Thêm $count kho lưu trữ',
      one: 'Thêm kho lưu trữ',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro =>
      'Duyệt các thư mục trên máy đang chạy máy chủ và chọn các checkout git để đăng ký.';

  @override
  String get selectThisFolder => 'Chọn thư mục này';

  @override
  String get deselectThisFolder => 'Bỏ chọn thư mục này';

  @override
  String get goUp => 'Lên';

  @override
  String get noSubfoldersHere => 'Không có thư mục con ở đây';

  @override
  String get notAGitRepository => 'Thư mục này không phải kho lưu trữ git.';

  @override
  String get addToken => 'Thêm token';

  @override
  String get addWorkspace => 'Thêm không gian làm việc';

  @override
  String get addWorkspaceEllipsis => 'Thêm không gian làm việc…';

  @override
  String get added => 'Đã thêm';

  @override
  String get addingEllipsis => 'Đang thêm…';

  @override
  String get advancedLabel => 'Nâng cao';

  @override
  String get agent => 'Agent';

  @override
  String conversationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cuộc trò chuyện',
      one: '1 cuộc trò chuyện',
    );
    return '$_temp0';
  }

  @override
  String agentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agents',
      one: '1 agent',
    );
    return '$_temp0';
  }

  @override
  String get agentMdPath => 'Đường dẫn Agent MD';

  @override
  String get agentName => 'Tên agent';

  @override
  String get agentTitle => 'Tiêu đề agent';

  @override
  String get agentUpdated => 'Đã cập nhật agent.';

  @override
  String get agents => 'Agent';

  @override
  String get agentsMentionSection => 'Agent';

  @override
  String get usersMentionSection => 'Mọi người';

  @override
  String get ticketsMentionSection => 'Phiếu';

  @override
  String get pullRequestsMentionSection => 'Pull request';

  @override
  String get meetingsMentionSection => 'Cuộc họp';

  @override
  String get entityRefTicketFallback => 'Phiếu';

  @override
  String get entityRefPrFallback => 'Pull request';

  @override
  String get entityRefMeetingFallback => 'Cuộc họp';

  @override
  String get aiReview => 'Đánh giá AI';

  @override
  String get all => 'Tất cả';

  @override
  String get allAgentsAlreadyInSpace =>
      'Tất cả agent đã có trong không gian này.';

  @override
  String get allCommits => 'Tất cả commit';

  @override
  String get allSources => 'Tất cả nguồn';

  @override
  String get allow => 'Cho phép';

  @override
  String get apiKeys => 'Khóa API';

  @override
  String get appFont => 'Phông chữ ứng dụng';

  @override
  String get appLogLevelDebugDescription =>
      'Thêm vết chi tiết — dùng khi phát triển.';

  @override
  String get appLogLevelDebugLabel => 'Gỡ lỗi';

  @override
  String get appLogLevelErrorDescription => 'Chỉ lỗi và ngoại lệ bất ngờ.';

  @override
  String get appLogLevelErrorLabel => 'Lỗi';

  @override
  String get appLogLevelInfoDescription =>
      'Thêm thông báo vòng đời và trạng thái.';

  @override
  String get appLogLevelInfoLabel => 'Thông tin';

  @override
  String get appLogLevelNoneDescription => 'Không xuất gì ra console.';

  @override
  String get appLogLevelNoneLabel => 'Không';

  @override
  String get appLogLevelVerboseDescription =>
      'Tất cả. Rất ồn — chỉ dùng để gỡ lỗi.';

  @override
  String get appLogLevelVerboseLabel => 'Chi tiết';

  @override
  String get appLogLevelWarningDescription =>
      'Thêm cảnh báo và sự cố có thể phục hồi.';

  @override
  String get appLogLevelWarningLabel => 'Cảnh báo';

  @override
  String get appearanceLanguage => 'Giao diện & ngôn ngữ';

  @override
  String get apply => 'Áp dụng';

  @override
  String get approve => 'Phê duyệt';

  @override
  String get agentApprovalRequired => 'Cần phê duyệt';

  @override
  String agentApprovalsMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'còn $count đang chờ',
      one: 'còn 1 đang chờ',
    );
    return '$_temp0';
  }

  @override
  String get approved => 'Đã phê duyệt';

  @override
  String get articleNoun => 'Bài viết';

  @override
  String get articlesSubscribed => 'Bài viết từ các nguồn bạn đã đăng ký.';

  @override
  String get askAi => 'Hỏi AI';

  @override
  String get askAiReviewDescription => 'Yêu cầu AI đánh giá PR này';

  @override
  String get assignees => 'Người được giao';

  @override
  String get attachImage => 'Đính kèm ảnh';

  @override
  String get attachedAgents => 'Agent đã gắn';

  @override
  String get audioInput => 'Đầu vào âm thanh';

  @override
  String get audioOutput => 'Đầu ra âm thanh';

  @override
  String get authenticationToken => 'Token xác thực';

  @override
  String authoredByLabel(String role) {
    return 'Bởi: $role';
  }

  @override
  String get autoRecommended => 'Tự động (khuyên dùng)';

  @override
  String get available => 'Khả dụng';

  @override
  String get awaitingYourReview => 'Đang chờ bạn đánh giá';

  @override
  String get back => 'Quay lại';

  @override
  String get backLabel => 'Quay lại';

  @override
  String get backend => 'Backend';

  @override
  String get blockAdsTrackers =>
      'Chặn quảng cáo, trình theo dõi & banner cookie';

  @override
  String get blocking => 'Đang chặn';

  @override
  String get bookmarkLabel => 'Đánh dấu';

  @override
  String get briefDescription => 'Mô tả ngắn';

  @override
  String get bugLabel => 'Bug';

  @override
  String get bundledDefaultsNeverUpdated =>
      'Mặc định đi kèm — không bao giờ cập nhật';

  @override
  String get cancel => 'Hủy';

  @override
  String get cancelEdit => 'Hủy chỉnh sửa';

  @override
  String get categoryNavigation => 'Điều hướng';

  @override
  String get change => 'Thay đổi';

  @override
  String get changesRequested => 'Yêu cầu thay đổi';

  @override
  String get spacesMentionSection => 'Không gian';

  @override
  String get checkForUpdates => 'Kiểm tra cập nhật';

  @override
  String get checking => 'Đang kiểm tra';

  @override
  String get checkingEllipsis => 'Đang kiểm tra…';

  @override
  String get chooseAppFont => 'Chọn phông chữ ứng dụng';

  @override
  String get chooseCodeFont => 'Chọn phông chữ mã';

  @override
  String get chooseRunner => 'Chọn trình chạy agent của bạn.';

  @override
  String get clear => 'Xóa';

  @override
  String get clickToRetry => 'Nhấp để thử lại';

  @override
  String get close => 'Đóng';

  @override
  String get closeEsc => 'Đóng (Esc)';

  @override
  String get closeReader => 'Đóng trình đọc';

  @override
  String get closed => 'Đã đóng';

  @override
  String get codeFont => 'Phông chữ mã';

  @override
  String get codeFontLigatures => 'Chữ ghép phông mã';

  @override
  String get codeFontLigaturesDescription =>
      'Hiển thị chữ ghép lập trình (=>, !=, ->) thành glyph kết hợp trong mã và diff';

  @override
  String get collapse => 'Thu gọn';

  @override
  String get commandPalette => 'Bảng lệnh';

  @override
  String get commandPaletteOrgMembers => 'Thành viên tổ chức';

  @override
  String get commandPaletteBrowseTeam => 'Duyệt nhóm';

  @override
  String get commandPaletteBrowseTeamDesc => 'Xem tất cả thành viên tổ chức';

  @override
  String get compactDone =>
      'Đã nén hội thoại. Lịch sử trước đó được gộp vào tóm tắt.';

  @override
  String get compactNothing => 'Chưa có gì để nén. Hội thoại vẫn còn ngắn.';

  @override
  String get compactBusy =>
      'Agent vẫn đang làm việc. Hãy nén khi lượt này kết thúc.';

  @override
  String get compactUnavailable => 'Không thể nén trên máy chủ này.';

  @override
  String get commandsMentionSection => 'Lệnh';

  @override
  String get comment => 'Bình luận';

  @override
  String get commentOnThisFile => 'Bình luận về tệp này';

  @override
  String get commented => 'Đã bình luận';

  @override
  String get commits => 'Commit';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'Hiển thị $loaded commit mới nhất trong tổng $total';
  }

  @override
  String get prCloneProgressCloningTitle => 'Đang sao chép kho';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'PR này thay đổi $fileCount tệp, vượt giới hạn API của GitHub. Đang sao chép kho về máy…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'PR này vượt giới hạn số tệp API của GitHub. Đang sao chép kho về máy…';

  @override
  String get prCloneProgressFetchingTitle => 'Đang lấy ref của PR';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'Đang lấy nhánh cơ sở và ref đầu PR…';

  @override
  String get prCloneProgressComputingTitle => 'Đang tính diff';

  @override
  String get prCloneProgressComputingSubtitle => 'Đang chạy git diff trên máy…';

  @override
  String get prCloneProgressErrorTitle => 'Không tải được diff';

  @override
  String get prCloneProgressErrorSubtitle =>
      'Đã xảy ra lỗi khi sao chép hoặc tính diff. Hãy thử làm mới.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'Vẫn đang xử lý… đã $elapsed';
  }

  @override
  String confidenceLabel(int percent) {
    return 'Độ tin cậy: $percent%';
  }

  @override
  String get configureAgentIdentities =>
      'Cấu hình danh tính agent, prompt, kỹ năng và xem các lần chạy.';

  @override
  String get configuredLabel => 'Đã cấu hình.';

  @override
  String get confirmedBy => 'Xác nhận bởi';

  @override
  String get consensus => 'Đồng thuận';

  @override
  String get contentHint => 'Nội dung cần ghi nhớ';

  @override
  String get contentLabel => 'Nội dung';

  @override
  String get contentMarkdown => 'Nội dung (Markdown)';

  @override
  String get contextWindowSize => 'Kích thước cửa sổ ngữ cảnh';

  @override
  String modelContextChip(String size) {
    return 'Mô hình · $size';
  }

  @override
  String get continueLabel => 'Tiếp tục';

  @override
  String get conversationMode => 'Chế độ';

  @override
  String cookieRulesCount(int count) {
    return '$count quy tắc cookie';
  }

  @override
  String typeToConfirmPrompt(String value) {
    return 'Nhập $value để xác nhận.';
  }

  @override
  String get copied => 'Đã sao chép!';

  @override
  String get copy => 'Sao chép';

  @override
  String get copyAddress => 'Sao chép địa chỉ';

  @override
  String get copyBaseBranchTooltip => 'Sao chép tên nhánh cơ sở';

  @override
  String get copyHeadBranchTooltip => 'Sao chép tên nhánh head';

  @override
  String couldNotListDevices(String error) {
    return 'Không thể liệt kê thiết bị: $error';
  }

  @override
  String get create => 'Tạo';

  @override
  String get createOrSelectWorkspace =>
      'Tạo hoặc chọn không gian làm việc trước khi thêm kho lưu trữ.';

  @override
  String get createPullRequest => 'Tạo pull request';

  @override
  String get createdByMe => 'Do tôi tạo';

  @override
  String createdLabel(String date) {
    return 'Đã tạo: $date';
  }

  @override
  String get currentParticipants => 'Người tham gia hiện tại';

  @override
  String get customSystemPrompt =>
      'Lời nhắc hệ thống tùy chỉnh cho agent này...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày trước',
      one: '1 ngày trước',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'Vô hiệu hóa';

  @override
  String get delete => 'Xóa';

  @override
  String get deleteAgent => 'Xóa agent';

  @override
  String deleteAgentConfirm(String name) {
    return 'Xóa \"$name\"? Không thể hoàn tác.';
  }

  @override
  String get deleteSpace => 'Xóa không gian';

  @override
  String deleteConfirmName(String name) {
    return 'Xóa \"$name\"?';
  }

  @override
  String get deleteFact => 'Xóa dữ kiện';

  @override
  String get deleteFeedBody =>
      'Thao tác này xóa nguồn cấp và tất cả bài viết đã lưu đệm. Các bài đã đánh dấu từ nguồn này cũng sẽ bị xóa.';

  @override
  String deleteFeedConfirm(String name) {
    return 'Xóa \"$name\"?';
  }

  @override
  String get deletePolicy => 'Xóa chính sách';

  @override
  String get deletePolicyConfirm => 'Xóa chính sách này? Không thể hoàn tác.';

  @override
  String deleteTopicConfirm(String topic) {
    return 'Xóa \"$topic\"? Không thể hoàn tác.';
  }

  @override
  String get deleteWorkspace => 'Xóa không gian làm việc';

  @override
  String get deny => 'Từ chối';

  @override
  String get detailsLabel => 'Chi tiết';

  @override
  String get descriptionLabel => 'Mô tả';

  @override
  String detectedBackend(String label) {
    return 'Đã phát hiện: $label';
  }

  @override
  String get detectedRunners => 'Runner đã phát hiện';

  @override
  String get detectingAdapters => 'Đang phát hiện adapter…';

  @override
  String get detectingInputDevices => 'Đang phát hiện thiết bị nhập…';

  @override
  String detectionFailed(String error) {
    return 'Phát hiện thất bại: $error';
  }

  @override
  String get disabled => 'Đã tắt';

  @override
  String get discover => 'Khám phá';

  @override
  String get dismissed => 'Đã bỏ qua';

  @override
  String get domainHint => 'ví dụ: api-performance';

  @override
  String get domainLabel => 'Lĩnh vực';

  @override
  String get download => 'Tải xuống';

  @override
  String get downloadingLabel => 'Đang tải xuống';

  @override
  String downloadingModel(int pct) {
    return 'Đang tải mô hình… $pct%';
  }

  @override
  String get draft => 'Bản nháp';

  @override
  String get draftLabel => 'Bản nháp';

  @override
  String get edit => 'Sửa';

  @override
  String get edited => 'đã sửa';

  @override
  String get editMessage => 'Sửa tin nhắn';

  @override
  String get revertToThere => 'Hoàn nguyên về đó';

  @override
  String get sendAsNewMessage => 'Gửi như tin nhắn mới';

  @override
  String get editMessageChoiceBody =>
      'Hoàn nguyên ẩn các tin nhắn sau tin này và đưa tệp của tác nhân về lại. Bạn có thể hoàn tác. Gửi như tin nhắn mới giữ nguyên cuộc trò chuyện.';

  @override
  String get deleteMessage => 'Xóa tin nhắn';

  @override
  String get deleteMessageConfirm => 'Xóa tin nhắn này? Không thể hoàn tác.';

  @override
  String get messageDeleted => 'Đã xóa tin nhắn';

  @override
  String get searchInConversation => 'Tìm trong cuộc trò chuyện';

  @override
  String get searchMessagesHint => 'Tìm tin nhắn…';

  @override
  String get noMessagesFound => 'Không tìm thấy tin nhắn';

  @override
  String get editFact => 'Sửa dữ kiện';

  @override
  String get editPolicy => 'Sửa chính sách';

  @override
  String get editSuggestedCodeHint => 'Sửa mã được đề xuất…';

  @override
  String get editSuggestion => 'Sửa đề xuất';

  @override
  String get egArchitect => 'vd. architect';

  @override
  String get egControlCenter => 'vd. control-center';

  @override
  String get egPlatform => 'vd. Platform';

  @override
  String get egSamuelAlev => 'vd. SamuelAlev';

  @override
  String get egSoftwareArchitect => 'vd. Software Architect';

  @override
  String get egTheVerge => 'vd. The Verge';

  @override
  String get egTokenLimit => 'vd. 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'Cài đặt thất bại: $error';
  }

  @override
  String get embeddingInstalled =>
      'Đã cài mô hình embedding cục bộ. Tìm kiếm lai đã được bật.';

  @override
  String get embeddingModel => 'Mô hình embedding (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'Chưa cài. Tìm kiếm sẽ chỉ dùng từ khóa cho đến khi được bật.';

  @override
  String get embeddingRedownloadBody =>
      'Các tệp mô hình hiện có sẽ bị xóa và tải lại. Tìm kiếm ngữ nghĩa sẽ không khả dụng cho đến khi tải xong.';

  @override
  String get embeddingRemoveBody =>
      'Tìm kiếm ngữ nghĩa sẽ bị tắt cho đến khi bạn cài lại. Bạn có thể cài lại bất cứ lúc nào.';

  @override
  String get speakerDiarization => 'Phân tách người nói';

  @override
  String get diarizationModel => 'Mô hình phân tách người nói';

  @override
  String get diarizationInstalled =>
      'Đã cài — đặt tên từng người nói trong bản ghi cuộc họp';

  @override
  String get diarizationNotInstalled =>
      'Chưa cài — người nói trong cuộc họp sẽ không được tách';

  @override
  String diarizationInstallFailed(String error) {
    return 'Cài đặt thất bại: $error';
  }

  @override
  String get redownloadDiarizationModel =>
      'Tải lại mô hình phân tách người nói';

  @override
  String get diarizationRedownloadBody =>
      'Thao tác này xóa các mô hình phân tách người nói hiện tại và tải lại.';

  @override
  String get removeDiarizationModel => 'Xóa mô hình phân tách người nói';

  @override
  String get diarizationRemoveBody =>
      'Thao tác này xóa các mô hình phân tách người nói trên thiết bị. Các bản ghi cuộc họp đã tạo không bị ảnh hưởng.';

  @override
  String get enableNotifications => 'Bật thông báo';

  @override
  String get enableSandboxing => 'Bật sandboxing';

  @override
  String get enabled => 'Đã bật';

  @override
  String errorCreatingAgent(String error) {
    return 'Lỗi khi tạo agent: $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'Lỗi khi xóa agent: $error';
  }

  @override
  String errorWithDetail(String error) {
    return 'Lỗi: $error';
  }

  @override
  String get expand => 'Mở rộng';

  @override
  String extractingModel(int pct) {
    return 'Đang giải nén mô hình… $pct%';
  }

  @override
  String get fact => 'Sự kiện';

  @override
  String factCount(int count) {
    return '$count sự kiện';
  }

  @override
  String factCountPlural(int count) {
    return '$count sự kiện';
  }

  @override
  String get facts => 'Sự kiện';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount sự kiện · $policyCount chính sách';
  }

  @override
  String get failed => 'Thất bại';

  @override
  String failedToDispatch(String error) {
    return 'Không thể gửi: $error';
  }

  @override
  String get failedToLoad => 'Không thể tải';

  @override
  String failedToLoadAgents(String error) {
    return 'Không thể tải agents: $error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'Không thể tải feed: $error';
  }

  @override
  String get failedToLoadGifs => 'Không thể tải GIF';

  @override
  String failedToLoadLogs(String error) {
    return 'Không thể tải nhật ký: $error';
  }

  @override
  String get failedToLoadRepos => 'Không thể tải kho lưu trữ';

  @override
  String get failedToLoadWorkspaces => 'Không thể tải không gian làm việc';

  @override
  String failedToStartAiReview(String error) {
    return 'Không thể bắt đầu đánh giá AI: $error';
  }

  @override
  String get failedToStartMicTest => 'Không thể bắt đầu kiểm tra mic.';

  @override
  String failedToSubmitReview(String error) {
    return 'Không thể gửi đánh giá: $error';
  }

  @override
  String failedToUpload(String name, String error) {
    return 'Không thể tải lên $name: $error';
  }

  @override
  String failedWithError(String error) {
    return 'Thất bại: $error';
  }

  @override
  String get failure => 'Thất bại';

  @override
  String get feedAlreadyExists => 'Đã có feed với URL này.';

  @override
  String get feedUrlExample => 'vd. https://example.com/feed.xml';

  @override
  String get feedUrlLabel => 'URL feed';

  @override
  String feedsCount(int count) {
    return 'Feed ($count)';
  }

  @override
  String get filesChanged => 'Tệp đã thay đổi';

  @override
  String filesCount(int count) {
    return '$count tệp';
  }

  @override
  String get filesMentionSection => 'Tệp';

  @override
  String get filterAgents => 'Lọc agents...';

  @override
  String get filterFilesHint => 'Lọc tệp…';

  @override
  String get filterLists => 'Lọc danh sách';

  @override
  String get filterSkillsPlaceholder => 'Lọc kỹ năng…';

  @override
  String get finish => 'Hoàn tất';

  @override
  String get fix => 'Sửa';

  @override
  String get forward => 'Chuyển tiếp';

  @override
  String get general => 'Chung';

  @override
  String get githubLink => 'Liên kết GitHub';

  @override
  String get claudeStatusFetchFailed => 'Không kết nối được status.claude.com';

  @override
  String get claudeStatusOpenInBrowser => 'Mở status.claude.com';

  @override
  String get githubStatusFetchFailed => 'Không kết nối được githubstatus.com';

  @override
  String get githubDegradedTitle => 'GitHub đang báo sự cố';

  @override
  String githubDegradedStatusLine(String status) {
    return 'Trạng thái GitHub: $status.';
  }

  @override
  String githubDegradedBody(String status) {
    return 'Trạng thái GitHub: $status. Dữ liệu pull request có thể cũ hoặc thiếu cho đến khi khôi phục.';
  }

  @override
  String get githubStatusOpenInBrowser => 'Mở githubstatus.com';

  @override
  String get githubStatusRefresh => 'Làm mới';

  @override
  String githubStatusUpdated(String time) {
    return 'Đã cập nhật $time';
  }

  @override
  String get kimiStatusFetchFailed => 'Không kết nối được status.moonshot.cn';

  @override
  String get kimiStatusOpenInBrowser => 'Mở status.moonshot.cn';

  @override
  String get openaiStatusFetchFailed => 'Không kết nối được status.openai.com';

  @override
  String get openaiStatusOpenInBrowser => 'Mở status.openai.com';

  @override
  String get serviceStatusMaintenance => 'Bảo trì';

  @override
  String get serviceStatusMajorIssues => 'Sự cố lớn';

  @override
  String get serviceStatusMinorIssues => 'Sự cố nhỏ';

  @override
  String get serviceStatusOperational => 'Hoạt động bình thường';

  @override
  String get serviceStatusOutage => 'Ngừng dịch vụ';

  @override
  String serviceStatusOverflowCount(int count) {
    return '$count+';
  }

  @override
  String get serviceStatusTitle => 'Trạng thái dịch vụ';

  @override
  String get serviceStatusUnknown => 'Không xác định';

  @override
  String lastChecked(String time) {
    return 'Đã kiểm tra $time';
  }

  @override
  String get lastCheckedRecently => 'Vừa kiểm tra';

  @override
  String get giveYourWorkAHome => 'Cho công việc một nơi lưu trữ.';

  @override
  String get goBack => 'Quay lại';

  @override
  String get goForward => 'Tiến tới';

  @override
  String get googleFonts => 'Google Fonts';

  @override
  String get high => 'Cao';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giờ trước',
      one: '1 giờ trước',
    );
    return '$_temp0';
  }

  @override
  String get sidebarAgeNow => 'vừa xong';

  @override
  String sidebarAgeMinutes(int count) {
    return '$count ph';
  }

  @override
  String sidebarAgeHours(int count) {
    return '$count giờ';
  }

  @override
  String sidebarAgeDays(int count) {
    return '$count ng';
  }

  @override
  String sidebarAgeMonths(int count) {
    return '$count th';
  }

  @override
  String sidebarAgeYears(int count) {
    return '$count năm';
  }

  @override
  String get images => 'Hình ảnh';

  @override
  String get inactive => 'Không hoạt động';

  @override
  String get install => 'Cài đặt';

  @override
  String installedVersion(String version) {
    return 'Đã cài $version';
  }

  @override
  String get invite => 'Mời';

  @override
  String get inviteAgent => 'Mời agent';

  @override
  String get isolateAgentExecution => 'Cô lập quá trình chạy agent.';

  @override
  String get justNow => 'Vừa xong';

  @override
  String get keepSandboxing => 'Giữ sandbox';

  @override
  String get keybindingAddRepository => 'Thêm kho lưu trữ';

  @override
  String get keybindingCommandPalette => 'Bảng lệnh';

  @override
  String get keybindingFocusSearch => 'Tập trung ô tìm kiếm';

  @override
  String get keybindingNewAgent => 'Agent mới';

  @override
  String get keybindingNewWorkspace => 'Không gian làm việc mới';

  @override
  String get keybindingNextArticle => 'Bài tiếp theo';

  @override
  String get keybindingNextSpace => 'Không gian tiếp theo';

  @override
  String get keybindingNextWorkspace => 'Không gian làm việc tiếp theo';

  @override
  String get keybindingOpenArticle => 'Mở bài viết';

  @override
  String get keybindingOpenPr => 'Mở PR';

  @override
  String get keybindingOpenSettings => 'Mở cài đặt';

  @override
  String get keybindingOpenWorkspace => 'Mở không gian làm việc';

  @override
  String get keybindingPreviousArticle => 'Bài viết trước';

  @override
  String get keybindingPreviousSpace => 'Không gian trước';

  @override
  String get keybindingPreviousWorkspace => 'Không gian làm việc trước';

  @override
  String get keybindingRefresh => 'Làm mới';

  @override
  String get keybindingSendMessage => 'Gửi tin nhắn';

  @override
  String get keybindingToggleBookmark => 'Bật/tắt dấu trang';

  @override
  String get keybindingToggleTheme => 'Bật/tắt chủ đề';

  @override
  String get keybindingToggleWorkspaceSwitcher =>
      'Bật/tắt bộ chuyển không gian làm việc';

  @override
  String get keybindingWorkspace1 => 'Không gian làm việc 1';

  @override
  String get keybindingWorkspace2 => 'Không gian làm việc 2';

  @override
  String get keybindingWorkspace3 => 'Không gian làm việc 3';

  @override
  String get keybindingWorkspace4 => 'Không gian làm việc 4';

  @override
  String get keybindingWorkspace5 => 'Không gian làm việc 5';

  @override
  String get keybindingWorkspace6 => 'Không gian làm việc 6';

  @override
  String get keybindingWorkspace7 => 'Không gian làm việc 7';

  @override
  String get keybindingWorkspace8 => 'Không gian làm việc 8';

  @override
  String get keybindingWorkspace9 => 'Không gian làm việc 9';

  @override
  String get killRunning => 'Hủy đang chạy';

  @override
  String get languageSystem => 'Hệ thống';

  @override
  String get leaveACommentEllipsis => 'Để lại bình luận…';

  @override
  String get legendLabel => 'Chú giải';

  @override
  String get lessLabel => 'Ít hơn';

  @override
  String get letsPluginTools => 'Hãy kết nối công cụ của bạn.';

  @override
  String get level => 'Mức';

  @override
  String get loadingAgents => 'Đang tải agent…';

  @override
  String get loadingModels => 'Đang tải mô hình…';

  @override
  String get loadingProviders => 'Đang tải nhà cung cấp…';

  @override
  String get logLevel => 'Mức nhật ký';

  @override
  String get logs => 'Nhật ký';

  @override
  String get low => 'Thấp';

  @override
  String get maintenance => 'Bảo trì';

  @override
  String get manageParticipants => 'Quản lý người tham gia';

  @override
  String get manageWorkspaces => 'Quản lý không gian làm việc';

  @override
  String get reorderWorkspace => 'Sắp xếp lại không gian làm việc';

  @override
  String get matchOsAppearance =>
      'Khớp giao diện hệ điều hành hoặc chọn chế độ cố định.';

  @override
  String get mcpNotAvailableOnServer =>
      'Không thể điều khiển máy chủ MCP trên máy chủ đang kết nối.';

  @override
  String get modelManagedOnServer =>
      'Mô hình này chạy trên máy chủ và được quản lý tại đó.';

  @override
  String get mcpServer => 'Máy chủ MCP';

  @override
  String get medium => 'Trung bình';

  @override
  String get memoryDataHint =>
      'Thông tin và chính sách sẽ xuất hiện ở đây khi agent làm việc.';

  @override
  String get memoryLabel => 'Bộ nhớ';

  @override
  String get merge => 'Hợp nhất';

  @override
  String get merged => 'Đã hợp nhất';

  @override
  String get messagePlaceholder => 'Tin nhắn… (@ để nhắc, / cho lệnh)';

  @override
  String get navConversations => 'Không gian';

  @override
  String get microphonePermissionDenied => 'Quyền microphone bị từ chối.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count phút trước',
      one: '1 phút trước',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'Mô hình';

  @override
  String get modified => 'Đã sửa';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tháng trước',
      one: '1 tháng trước',
    );
    return '$_temp0';
  }

  @override
  String get moreLabel => 'Thêm';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'Tên';

  @override
  String get nameAndTitleRequired => 'Cần có tên và tiêu đề.';

  @override
  String get nameAndUrlRequired => 'Cần có tên và URL';

  @override
  String get nameLabel => 'Tên';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'Sandbox gốc khả dụng trên $platform.';
  }

  @override
  String get nativeSandboxNeedsInstall => 'Cần cài đặt sandbox gốc';

  @override
  String get navObservability => 'Quan sát';

  @override
  String get navSettings => 'Cài đặt';

  @override
  String get exitSettings => 'Thoát cài đặt';

  @override
  String networkBlockCount(int count) {
    return '$count chặn mạng';
  }

  @override
  String get neutral => 'Trung tính';

  @override
  String get newCommitsPushed => 'Đã đẩy commit mới — nhấn để tải lại diff';

  @override
  String get newFact => 'Thông tin mới';

  @override
  String get newPolicy => 'Chính sách mới';

  @override
  String get newsfeed => 'Bảng tin';

  @override
  String get newsfeedLabel => 'Bảng tin';

  @override
  String get newsfeedSettingsDescription =>
      'Quản lý nguồn đã đăng ký và tùy chọn đọc.';

  @override
  String get newsfeedSettingsTitle => 'Cài đặt bảng tin';

  @override
  String get nextMatch => 'Kết quả tiếp theo (↵)';

  @override
  String get noActiveWorkspace => 'Chưa chọn không gian làm việc hoặc repo.';

  @override
  String get noActiveWorkspaceCreate =>
      'Không có không gian làm việc đang dùng';

  @override
  String get noActiveWorkspaceGithub =>
      'Không có không gian làm việc với repo GitHub.';

  @override
  String get noAgents => 'Không có agent';

  @override
  String get noArticlesYet => 'Chưa có bài viết';

  @override
  String get noArticlesYetBody =>
      'Bài viết từ nguồn của bạn sẽ xuất hiện ở đây.';

  @override
  String get noExecutionLogsYet => 'Chưa có nhật ký thực thi';

  @override
  String get noFacts => 'Chưa có thông tin';

  @override
  String get noFeedsYet => 'Chưa có nguồn';

  @override
  String get noFileAnchor =>
      'Không có neo tệp — không thể đăng bình luận nội dòng.';

  @override
  String get noFileChangesInScope => 'Không có thay đổi tệp trong phạm vi này';

  @override
  String get noGifsFound => 'Không tìm thấy GIF';

  @override
  String get noInputDevicesDetected =>
      'Không phát hiện thiết bị nhập — dùng mặc định hệ thống.';

  @override
  String get noMatchingFiles => 'Không có tệp khớp';

  @override
  String get noMatchingGoogleFonts => 'Không có Google Fonts khớp.';

  @override
  String get noMemoryData => 'Chưa có dữ liệu bộ nhớ';

  @override
  String get noMessagesYet => 'Chưa có tin nhắn';

  @override
  String get noModelsAdvertised => 'Adapter này chưa công bố model nào.';

  @override
  String get noOpenPullRequests => 'Không có pull request đang mở';

  @override
  String get noPolicies => 'Chưa có chính sách';

  @override
  String get noReposInWorkspaceYet =>
      'Chưa có kho lưu trữ trong không gian làm việc này';

  @override
  String get noRunnersDetected =>
      'Chưa phát hiện runner nào. Làm mới để quét lại.';

  @override
  String get noSavedArticles => 'Chưa có bài viết đã lưu';

  @override
  String get noSavedArticlesBody => 'Các bài viết bạn lưu sẽ xuất hiện ở đây.';

  @override
  String get noSystemFonts => 'Không phát hiện font hệ thống.';

  @override
  String get noWorkingMemory => 'Chưa có ghi chú bộ nhớ làm việc.';

  @override
  String get noneAllRoles => 'Không (tất cả vai trò)';

  @override
  String get notAvailable => 'Không khả dụng';

  @override
  String get notConfiguredLabel => 'Chưa cấu hình.';

  @override
  String get notFoundLabel => 'Không tìm thấy';

  @override
  String get notes => 'Ghi chú';

  @override
  String get notificationAgentFinished => 'Agent đã hoàn tất';

  @override
  String get notificationPrMentioned => 'Được nhắc trong pull request';

  @override
  String get notificationNewMessages => 'Tin nhắn mới';

  @override
  String get notificationPrMerged => 'PR đã được merge';

  @override
  String get notificationPrPublished => 'PR đã được công bố';

  @override
  String get notificationReviewRequested => 'Yêu cầu review';

  @override
  String get notifications => 'Thông báo';

  @override
  String get notifyAgentRunCompleted =>
      'Thông báo khi agent hoàn tất một lần chạy.';

  @override
  String get notifyPrMentioned =>
      'Thông báo khi bạn được nhắc trong một pull request.';

  @override
  String get notifyNewMessages =>
      'Thông báo khi bạn được nhắc trong một không gian.';

  @override
  String get notifyPrMerged => 'Thông báo khi một pull request được merge.';

  @override
  String get notifyPrPublished =>
      'Thông báo khi agent công bố một pull request.';

  @override
  String get notifyReviewRequested =>
      'Thông báo khi bạn được yêu cầu review một pull request.';

  @override
  String get notificationReviewStale => 'Review đã lỗi thời';

  @override
  String get notifyReviewStale =>
      'Khi có commit mới trên pull request bạn đã review';

  @override
  String get notificationPrMergeReadiness => 'Sẵn sàng merge';

  @override
  String get notifyPrMergeReadiness =>
      'Thông báo khi pull request bạn tạo trở nên merge được, hoặc không còn nữa.';

  @override
  String get notificationPrReviewDecision => 'Quyết định review';

  @override
  String get notifyPrReviewDecision =>
      'Thông báo khi người review phê duyệt, yêu cầu thay đổi hoặc phê duyệt bị hủy.';

  @override
  String get notificationPrChecksStatus => 'Kiểm tra';

  @override
  String get notifyPrChecksStatus =>
      'Thông báo khi CI thất bại trên pull request bạn tạo, và khi nó phục hồi.';

  @override
  String get notificationPrThreadActivity => 'Luồng review';

  @override
  String get notifyPrThreadActivity =>
      'Thông báo khi có người trả lời hoặc giải quyết luồng bạn tham gia.';

  @override
  String get notificationPrReadyToMerge => 'Sẵn sàng merge';

  @override
  String notificationPrReadyToMergeBody(String prTitle) {
    return '$prTitle đã đủ điều kiện.';
  }

  @override
  String get notificationPrMergeBlocked => 'Không còn merge được';

  @override
  String notificationPrMergeBlockedBodyConflicts(String prTitle) {
    return '$prTitle xung đột với nhánh cơ sở.';
  }

  @override
  String notificationPrMergeBlockedBodyBehind(String prTitle) {
    return '$prTitle đang chậm hơn nhánh cơ sở.';
  }

  @override
  String notificationPrMergeBlockedBodyReviews(String prTitle) {
    return '$prTitle đang chờ review bắt buộc.';
  }

  @override
  String notificationPrMergeBlockedBodyChanges(String prTitle) {
    return 'Người review đã yêu cầu thay đổi trên $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyChecks(String prTitle) {
    return 'Kiểm tra đang thất bại trên $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyOther(String prTitle) {
    return '$prTitle không còn merge được.';
  }

  @override
  String get notificationPrApproved => 'Pull request đã được phê duyệt';

  @override
  String notificationPrApprovedBodyBy(String login, String prTitle) {
    return '$login đã phê duyệt $prTitle';
  }

  @override
  String notificationPrApprovedBody(String prTitle) {
    return '$prTitle đã được phê duyệt';
  }

  @override
  String notificationPrReviewersRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'còn $count người review chưa phản hồi',
      one: 'còn 1 người review chưa phản hồi',
      zero: 'không còn người review nào',
    );
    return '$_temp0';
  }

  @override
  String get notificationPrChangesRequested => 'Yêu cầu thay đổi';

  @override
  String notificationPrChangesRequestedBodyBy(String login, String prTitle) {
    return '$login đã yêu cầu thay đổi trên $prTitle';
  }

  @override
  String notificationPrChangesRequestedBody(String prTitle) {
    return 'Đã có yêu cầu thay đổi trên $prTitle';
  }

  @override
  String get notificationPrReviewDismissed => 'Phê duyệt đã bị hủy';

  @override
  String notificationPrReviewDismissedBody(String prTitle) {
    return '$prTitle cần được review lại.';
  }

  @override
  String get notificationPrChecksFailed => 'Kiểm tra thất bại';

  @override
  String notificationPrChecksFailedBody(String checkName, String prTitle) {
    return '$checkName thất bại trên $prTitle';
  }

  @override
  String notificationPrChecksFailedBodyUnnamed(String prTitle) {
    return 'Kiểm tra đang thất bại trên $prTitle';
  }

  @override
  String get notificationPrChecksRecovered => 'Kiểm tra đã đạt';

  @override
  String notificationPrChecksRecoveredBody(String prTitle) {
    return '$prTitle đã xanh trở lại.';
  }

  @override
  String notificationPrMentionedInCommentBody(String login, String location) {
    return '$login đã nhắc đến bạn trong $location';
  }

  @override
  String get notificationPrThreadReplied => 'Phản hồi mới';

  @override
  String notificationPrThreadRepliedBody(String login, String location) {
    return '$login đã phản hồi trong $location';
  }

  @override
  String get notificationPrThreadResolved => 'Luồng đã giải quyết';

  @override
  String notificationPrThreadResolvedBody(String location) {
    return 'Luồng của bạn trong $location đã được giải quyết.';
  }

  @override
  String get notificationGroupAgents => 'Agents';

  @override
  String get notificationGroupPullRequests => 'Pull requests';

  @override
  String get notificationGroupMessages => 'Tin nhắn';

  @override
  String get notificationGroupTickets => 'Phiếu';

  @override
  String get notificationGroupCalendar => 'Lịch';

  @override
  String get notificationGroupMachines => 'Máy';

  @override
  String get notificationSectionSound => 'Âm thanh';

  @override
  String get notificationSectionSchedule => 'Lịch';

  @override
  String get notificationSectionEvents => 'Sự kiện';

  @override
  String get notificationsMutedRepos => 'Kho lưu trữ đã tắt thông báo';

  @override
  String notificationsMutedReposCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kho lưu trữ bị tắt thông báo',
      one: '1 kho lưu trữ bị tắt thông báo',
      zero: 'Không có kho lưu trữ nào bị tắt thông báo',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMuteRepo => 'Tắt thông báo kho lưu trữ này';

  @override
  String get onboardingLinuxDescription =>
      'Control Center có thể dùng container Linux để cô lập việc chạy agent.';

  @override
  String get onboardingMacosDescription =>
      'Control Center dùng sandbox gốc trên macOS để cô lập việc chạy agent.';

  @override
  String get onboardingUnsupportedDescription =>
      'Sandbox không khả dụng trên nền tảng này. Agent sẽ chạy mà không có cô lập.';

  @override
  String get openArticlesInApp => 'Mở bài viết trong ứng dụng';

  @override
  String get openInBrowser => 'Mở trong trình duyệt';

  @override
  String get openedInYourBrowser => 'Đã mở trong trình duyệt.';

  @override
  String get openLabel => 'Mở';

  @override
  String get openOnGithub => 'Mở trên GitHub';

  @override
  String get openStatus => 'Mở';

  @override
  String get optionalPersonaDescription => 'Mô tả persona tùy chọn';

  @override
  String get otherLabel => 'Khác';

  @override
  String get ownerOrganization => 'Chủ sở hữu / Tổ chức';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get passed => 'Đã đạt';

  @override
  String get pasteValueHere => 'Dán giá trị vào đây';

  @override
  String get persona => 'Persona';

  @override
  String get policies => 'Chính sách';

  @override
  String get policiesHint =>
      'Chính sách sẽ xuất hiện ở đây khi agent thăng cấp dữ kiện.';

  @override
  String get policy => 'Chính sách';

  @override
  String get popular => 'Phổ biến';

  @override
  String get port => 'Cổng';

  @override
  String get postingEllipsis => 'Đang đăng…';

  @override
  String get prCommits => 'Commit';

  @override
  String get prMergedBody => 'Một pull request đã được hợp nhất';

  @override
  String get prMoreActions => 'Thêm hành động';

  @override
  String get prTitle => 'Tiêu đề PR';

  @override
  String get reviewCommentHint =>
      'Chỉ cần bấm phê duyệt, hoặc nếu thấy hứng thì thêm bình luận hay reaction…';

  @override
  String get nothingToPreview => 'Không có gì để xem trước';

  @override
  String get previousMatch => 'Kết quả trước (⇧↵)';

  @override
  String get priorityReviewsDescription =>
      'Review ưu tiên và tổng quan kho lưu trữ.';

  @override
  String get prsCreated => 'PR đã tạo';

  @override
  String get prsMerged => 'PR đã hợp nhất';

  @override
  String get publishToGithub => 'Xuất bản lên GitHub';

  @override
  String get published => 'Đã xuất bản';

  @override
  String get pullRequestApproved => 'Pull request đã được phê duyệt';

  @override
  String get pullRequests => 'Pull requests';

  @override
  String get questionLabel => 'Câu hỏi';

  @override
  String get queued => 'Đang chờ';

  @override
  String get react => 'React';

  @override
  String get readerPreferences => 'Tùy chọn trình đọc';

  @override
  String get reasoningEffort => 'Mức suy luận';

  @override
  String get recommendLabel => 'Đề xuất';

  @override
  String recordingFromDevice(String device) {
    return 'Đang ghi từ $device.';
  }

  @override
  String get redownload => 'Tải lại';

  @override
  String get redownloadEmbeddingModel => 'Tải lại mô hình embedding?';

  @override
  String get redownloadVoiceModel => 'Tải lại mô hình giọng nói?';

  @override
  String get refinePlan => 'Tinh chỉnh kế hoạch';

  @override
  String get refresh => 'Làm mới';

  @override
  String get refreshAll => 'Làm mới tất cả';

  @override
  String get refreshAllFeeds => 'Làm mới tất cả feed';

  @override
  String get reject => 'Từ chối';

  @override
  String get rejected => 'Đã từ chối';

  @override
  String get reload => 'Tải lại';

  @override
  String get remove => 'Xóa';

  @override
  String get removeBookmark => 'Xóa dấu trang';

  @override
  String get removeEmbeddingModel => 'Gỡ mô hình embedding?';

  @override
  String get removeLogo => 'Xóa logo';

  @override
  String get removeRepoFromWorkspace =>
      'Gỡ kho lưu trữ khỏi không gian làm việc?';

  @override
  String get removeVoiceModel => 'Gỡ mô hình giọng nói?';

  @override
  String get removed => 'Đã xóa';

  @override
  String get renamed => 'Đã đổi tên';

  @override
  String get reopen => 'Mở lại';

  @override
  String get resolve => 'Giải quyết';

  @override
  String get replyEllipsis => 'Trả lời…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$name sẽ bị gỡ khỏi không gian làm việc này. Tệp cục bộ trên đĩa không bị thay đổi.';
  }

  @override
  String get repoNoAccessBadge => 'Không có quyền';

  @override
  String get reportsTo => 'Báo cáo cho';

  @override
  String reposCount(int count) {
    return 'Kho lưu trữ ($count)';
  }

  @override
  String get reposDescription =>
      'Các bản checkout cục bộ mà không gian làm việc này nhắm tới.';

  @override
  String get repositories => 'Kho lưu trữ';

  @override
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kho lưu trữ',
      one: '1 kho lưu trữ',
    );
    return 'Không thể thêm $_temp0: $error';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã thêm $count kho lưu trữ',
      one: 'Đã thêm kho lưu trữ',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => 'Cài đặt kho lưu trữ';

  @override
  String get repositoryName => 'Tên kho lưu trữ';

  @override
  String get requestChanges => 'Yêu cầu thay đổi';

  @override
  String get requested => 'Đã yêu cầu';

  @override
  String get requestedChanges => 'Thay đổi được yêu cầu';

  @override
  String requiredRoleLabel(String role) {
    return 'Vai trò bắt buộc: $role';
  }

  @override
  String get requiredRoleOptional => 'Vai trò bắt buộc (tùy chọn)';

  @override
  String get requirements => 'Yêu cầu';

  @override
  String get reset => 'Đặt lại';

  @override
  String get resolved => 'Đã giải quyết';

  @override
  String get enclosedTerminalTitle => 'Terminal kèm';

  @override
  String get enclosedTerminalStart => 'Mở shell';

  @override
  String get enclosedTerminalStartHint =>
      'Shell này chạy trong VM dùng một lần của cuộc trò chuyện này. Nó khởi động khi bạn mở, không phải khi ứng dụng khởi động.';

  @override
  String get terminalStreamReconnecting =>
      'stream bị gián đoạn — đang kết nối lại…';

  @override
  String get terminalStreamError => 'lỗi stream:';

  @override
  String get terminalShellExited => 'shell đã thoát';

  @override
  String get restartShell => 'Khởi động lại shell';

  @override
  String get retry => 'Thử lại';

  @override
  String get review => 'Đánh giá';

  @override
  String get reviewedByMe => 'Tôi đã đánh giá';

  @override
  String get reviewers => 'Người đánh giá';

  @override
  String get roleLabel => 'Vai trò';

  @override
  String get ruleHint => 'Quy tắc chính sách (hỗ trợ markdown)';

  @override
  String get ruleLabel => 'Quy tắc';

  @override
  String get running => 'Đang chạy';

  @override
  String get runningLabel => 'đang chạy';

  @override
  String get runs => 'Lần chạy';

  @override
  String get runsLabel => 'Lần chạy';

  @override
  String get sandboxBackendNativeLabel => 'Sandbox gốc';

  @override
  String get sandboxBackendMicrovmLabel => 'VM khép kín';

  @override
  String get sandboxBackendNoneLabel => 'Không cô lập';

  @override
  String get sandboxLinuxInstall =>
      'Sandbox gốc trên Linux/WSL2 dùng bubblewrap. Cài bằng:\n\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'Sandbox gốc đã có sẵn trên macOS — dùng Apple Seatbelt (`sandbox-exec`). Không cần cài.';

  @override
  String get sandboxUnsupported =>
      'Sandbox gốc chưa được hỗ trợ trên nền tảng này. Sẽ dùng \"Không cô lập\".';

  @override
  String get sandboxingDisabledDescription =>
      'Agent chạy trực tiếp trên máy chủ với toàn bộ môi trường — không khuyến nghị.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'Mọi lần gọi agent đều đi qua $backend.';
  }

  @override
  String get save => 'Lưu';

  @override
  String get saveChanges => 'Lưu thay đổi';

  @override
  String get adapterArguments => 'Tham số thêm';

  @override
  String get adapterArgumentsHint => 'Cờ CLI bổ sung (vd. --yolo)';

  @override
  String get addVariable => 'Thêm biến';

  @override
  String get environmentVariables => 'Biến môi trường';

  @override
  String get environmentVariablesDescription =>
      'Biến môi trường tùy chỉnh truyền cho adapter này (vd. khóa API). Lưu trong keychain.';

  @override
  String get variableKey => 'Khóa';

  @override
  String get variableValue => 'Giá trị';

  @override
  String get savingEllipsis => 'Đang lưu…';

  @override
  String get scopeDiffToCommits =>
      'Giới hạn diff theo commit — Shift-click để chọn khoảng';

  @override
  String get noPrsMatchSearch => 'Không có pull request khớp';

  @override
  String get searchFactsHint => 'Tìm fact...';

  @override
  String get searchFonts => 'Tìm font…';

  @override
  String get searchGifs => 'Tìm GIF';

  @override
  String get searchGifsHint => 'Tìm trên KLIPY';

  @override
  String get searchInDiffHint => 'Tìm trong diff…';

  @override
  String get searchOrTypeModel => 'Tìm hoặc nhập tên model…';

  @override
  String get searchPlaceholder => 'Tìm kiếm…';

  @override
  String get searching => 'Đang tìm…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giây trước',
      one: '1 giây trước',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'Chọn adapter';

  @override
  String get selectAdapterFirst => 'Hãy chọn adapter trước';

  @override
  String get selectAgentToReportTo => 'Chọn agent để báo cáo…';

  @override
  String get selectAnAgent => 'Chọn một agent';

  @override
  String get selectConversation => 'Chọn cuộc hội thoại';

  @override
  String get selectLabel => 'Chọn';

  @override
  String get selectRunner => 'Chọn runner';

  @override
  String get semanticSearch => 'Tìm kiếm ngữ nghĩa';

  @override
  String get send => 'Gửi';

  @override
  String get sendFirstMessage => 'Gửi tin nhắn đầu tiên';

  @override
  String get sendMessage => 'Gửi tin nhắn';

  @override
  String sentFindingsToAgent(int count) {
    return 'Đã gửi $count phát hiện tới agent.';
  }

  @override
  String setGithubLinkDescription(String name) {
    return 'Đặt owner GitHub và tên repository cho $name. Dùng để phân giải tham chiếu PR và issue như #123 trong nội dung markdown.';
  }

  @override
  String get setLabel => 'Đặt';

  @override
  String get settingsLabel => 'Cài đặt';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get settingsLanguageDescription => 'Chọn ngôn ngữ ứng dụng.';

  @override
  String get showNativeNotifications => 'Hiện thông báo hệ thống cho sự kiện.';

  @override
  String get showSuperseded => 'Hiện bản bị thay thế';

  @override
  String get signedIn => 'Đã đăng nhập.';

  @override
  String signedInAs(String username) {
    return 'Đã đăng nhập với tên $username.';
  }

  @override
  String get skillNameRequired => 'Tên skill là bắt buộc.';

  @override
  String skillSaved(String name) {
    return 'Đã lưu skill \"$name\".';
  }

  @override
  String get skillsSourcesTab => 'Nguồn';

  @override
  String get skillSourcesDisclaimer =>
      'Skill được cài từ các kho GitHub bạn thêm. Siêu dữ liệu kho không đáng tin — kết quả quét antivirus mới là tín hiệu an toàn thực sự.';

  @override
  String get skillSourcesEmpty => 'Không có kho skill';

  @override
  String get skillSourcesEmptyHint => 'Thêm kho GitHub để duyệt skill.';

  @override
  String get skillSourceAdd => 'Thêm kho';

  @override
  String get skillSourceAddTitle => 'Thêm kho skill';

  @override
  String get skillSourceAddHint => 'https://github.com/owner/repo';

  @override
  String get skillSourceInvalidUrl =>
      'Nhập URL kho GitHub (https://github.com/owner/repo).';

  @override
  String skillSourceAdded(String repo) {
    return 'Đã thêm kho $repo.';
  }

  @override
  String skillSourceAlreadyAdded(String repo) {
    return 'Kho $repo đã được thêm.';
  }

  @override
  String skillSourceRemoved(String repo) {
    return 'Đã xóa kho $repo.';
  }

  @override
  String get skillSourceRemove => 'Xóa';

  @override
  String skillSourceRemoveConfirmTitle(String repo) {
    return 'Xóa $repo?';
  }

  @override
  String get skillSourceRemoveConfirmBody =>
      'Skill đã cài vẫn được giữ. Chỉ danh mục kho bị xóa.';

  @override
  String get skillSourceNoSkills =>
      'Không tìm thấy skill trong kho này (skill là thư mục chứa SKILL.md).';

  @override
  String get skillSourceRefresh => 'Làm mới';

  @override
  String get skillSourceInstalledBadge => 'Đã cài';

  @override
  String get skillSourceUpdateBadge => 'Có bản cập nhật';

  @override
  String get skillSourceSlugTaken => 'Tên đang được dùng';

  @override
  String skillSourceFilesCount(num count) {
    return '$count tệp';
  }

  @override
  String get skillSourceReadme => 'README';

  @override
  String get skillSourceNoReadme => 'Skill này không có README.';

  @override
  String get skillSourceNoMatches => 'Không có skill khớp bộ lọc.';

  @override
  String get skillUpdateAction => 'Cập nhật';

  @override
  String get skillUninstallAction => 'Gỡ cài đặt';

  @override
  String skillUninstallConfirmTitle(String slug) {
    return 'Gỡ cài đặt \"$slug\"?';
  }

  @override
  String skillUninstalled(String slug) {
    return 'Đã gỡ skill \"$slug\".';
  }

  @override
  String get skillFindingLine => 'dòng';

  @override
  String get skillInstallAnywayOverride => 'Tôi hiểu rủi ro — vẫn cài';

  @override
  String skillInstalled(String slug) {
    return 'Đã cài skill \"$slug\".';
  }

  @override
  String get skillPreviewCapabilities => 'Khả năng';

  @override
  String get skillPreviewFindings => 'Phát hiện';

  @override
  String get skillPreviewGuardedActions => 'Hành động được bảo vệ';

  @override
  String get skillPreviewLlmReviewed => 'Đã duyệt bằng LLM';

  @override
  String get skillPreviewNoCapabilities => 'Không khai báo khả năng.';

  @override
  String get skillPreviewNoFindings => 'Không có phát hiện.';

  @override
  String get skillPreviewScanning => 'Đang quét skill…';

  @override
  String get skillPreviewVerdictLabel => 'Kết luận quét';

  @override
  String get skillPreviewVerdictPass => 'Đạt';

  @override
  String get skillPreviewVerdictQuarantine => 'Đã cách ly';

  @override
  String get skillPreviewVerdictWarn => 'Cảnh báo';

  @override
  String get skillQuarantineWarning =>
      'Skill này đã bị bộ quét cách ly. Cài đặt sẽ chạy mã trên máy của bạn. Chỉ tiếp tục nếu bạn tin nguồn và đã xem các phát hiện.';

  @override
  String skillDetachedFromAgents(String agents) {
    return 'Đã cách ly và tách khỏi agent: $agents';
  }

  @override
  String get skillNotScanned => 'Chưa quét';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => 'Thủ công';

  @override
  String get skillOriginRuntimeLocal => 'Runtime cục bộ';

  @override
  String get skillRulesStale => 'Quét lỗi thời';

  @override
  String get skillSaveAnywayOverride => 'Tôi hiểu rủi ro — vẫn lưu';

  @override
  String get skillSaveBlockedBody =>
      'Nội dung bị chặn trước khi ghi bất kỳ thứ gì.';

  @override
  String get skillSaveBlockedTitle => 'Lưu bị cổng quét chặn';

  @override
  String get skillScanAction => 'Quét';

  @override
  String get skillScanAll => 'Quét tất cả';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass đạt · $warn cảnh báo · $quarantine cách ly';
  }

  @override
  String get skillStateDrifted => 'Đã sửa sau khi cài';

  @override
  String get skillStateUnmanaged => 'Không được quản lý';

  @override
  String get skillSeverityBlocked => 'Bị chặn';

  @override
  String get skillSeverityWarn => 'Cảnh báo';

  @override
  String get skillsInstalledTab => 'Đã cài';

  @override
  String get skills => 'Kỹ năng';

  @override
  String get skipAcceptRisk => 'Bỏ qua — tôi chấp nhận rủi ro';

  @override
  String get skipForNow => 'Bỏ qua lúc này';

  @override
  String get skipSandboxing => 'Bỏ qua sandbox';

  @override
  String get skipSandboxingDialogContent =>
      'Bạn có chắc muốn bỏ qua sandbox không? Việc này cho phép agent thực thi mã trên hệ thống của bạn mà không bị cô lập.';

  @override
  String get somethingWentWrong => 'Đã xảy ra lỗi';

  @override
  String sourceCount(int count) {
    return '$count nguồn';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count nguồn';
  }

  @override
  String get sourceFacts => 'Thông tin nguồn:';

  @override
  String get splitDiff => 'Diff tách (cạnh nhau)';

  @override
  String get startLabel => 'Bắt đầu';

  @override
  String get startOnAppLaunch => 'Khởi động khi mở ứng dụng';

  @override
  String get statusLabel => 'Trạng thái';

  @override
  String get onboardingStepConnect => 'Kết nối';

  @override
  String get onboardingStepWorkspace => 'Không gian làm việc';

  @override
  String get onboardingStepSandbox => 'Sandbox';

  @override
  String get onboardingStepAdapter => 'Adapter';

  @override
  String get onboardingStepVoice => 'Giọng nói';

  @override
  String get stop => 'Dừng';

  @override
  String get stopped => 'Đã dừng';

  @override
  String get strictIdentityCheck => 'Kiểm tra danh tính nghiêm ngặt';

  @override
  String get success => 'Thành công';

  @override
  String get successLabel => 'Thành công';

  @override
  String get suggestion => 'Đề xuất';

  @override
  String get suggestLabel => 'Đề xuất';

  @override
  String get superseded => 'Đã thay thế';

  @override
  String get synced => 'Đã đồng bộ';

  @override
  String get systemDefault => 'Mặc định hệ thống';

  @override
  String get systemFonts => 'Phông chữ hệ thống';

  @override
  String get systemPrompt => 'Prompt hệ thống';

  @override
  String get systemPromptLabel => 'Prompt hệ thống';

  @override
  String get talkToControlCenter => 'Nói chuyện với Control Center.';

  @override
  String get taskMentionSection => 'Tác vụ';

  @override
  String get testLabel => 'Kiểm thử';

  @override
  String get theme => 'Chủ đề';

  @override
  String get themeDark => 'Tối';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeSystem => 'Hệ thống';

  @override
  String get thisCannotBeUndone => 'Không thể hoàn tác.';

  @override
  String get ticketLabel => 'Phiếu';

  @override
  String get titleLabel => 'Tiêu đề';

  @override
  String get todayLabel => 'Hôm nay';

  @override
  String get toggleTheme => 'Chuyển chủ đề';

  @override
  String get topic => 'Chủ đề';

  @override
  String get topicHint => 'vd. Tech Stack, Design System';

  @override
  String get totalRuns => 'Tổng số lần chạy';

  @override
  String trackingParamsCount(int count) {
    return '$count tham số theo dõi';
  }

  @override
  String get typeCommandOrSearch => 'Nhập lệnh hoặc tìm kiếm…';

  @override
  String get typography => 'Kiểu chữ';

  @override
  String get unavailable => 'Không khả dụng';

  @override
  String get unifiedDiff => 'Diff gộp';

  @override
  String get unknownAuthor => 'Không xác định';

  @override
  String get unnamedAgent => 'Agent chưa đặt tên';

  @override
  String get updateLabel => 'Cập nhật';

  @override
  String get updateToken => 'Cập nhật token';

  @override
  String updatedDaysAgo(int count) {
    return 'Cập nhật $count ngày trước';
  }

  @override
  String updatedHoursAgo(int count) {
    return 'Cập nhật $count giờ trước';
  }

  @override
  String get updatedJustNow => 'Vừa cập nhật';

  @override
  String updatedMinutesAgo(int count) {
    return 'Cập nhật $count phút trước';
  }

  @override
  String get useSandbox => 'Dùng sandbox';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      'Để trống để dùng User-Agent mặc định của ứng dụng. Một số trang chặn User-Agent không phải trình duyệt.';

  @override
  String get usingSystemDefaultMicrophone =>
      'Đang dùng micro mặc định của hệ thống.';

  @override
  String get viewLabel => 'Xem';

  @override
  String get viewLogs => 'Xem nhật ký';

  @override
  String voiceInstallFailed(String error) {
    return 'Cài đặt thất bại: $error';
  }

  @override
  String get voiceModelNotInstalled =>
      'Chưa cài. Tải ~200 MB một lần; chạy hoàn toàn trên thiết bị.';

  @override
  String get voiceModelNotInstalledLabel => 'Mô hình giọng nói chưa được cài.';

  @override
  String get voiceRedownloadBody =>
      'Các tệp mô hình hiện có sẽ bị xóa và gói ~200 MB sẽ được tải lại. Phiên âm giọng nói sẽ không khả dụng cho đến khi tải xong.';

  @override
  String get voiceRemoveBody =>
      'Phiên âm giọng nói sẽ bị tắt cho đến khi bạn cài lại. Bạn có thể cài lại bất cứ lúc nào.';

  @override
  String get voiceTranscription => 'Phiên âm giọng nói';

  @override
  String get weakIsolationDescription =>
      'Cô lập yếu — chỉ ranh giới namespace, không có ranh giới kernel.';

  @override
  String get whenOffServerStaysStopped =>
      'Khi tắt, máy chủ vẫn dừng cho đến khi bạn khởi động.';

  @override
  String get speechModel => 'Mô hình giọng nói';

  @override
  String get speechModelHint =>
      'Dùng cho phiên âm cuộc họp và micro trong trình soạn.';

  @override
  String get voiceModelInstalled =>
      'Đã cài. Cung cấp phiên âm cuộc họp và nút micro trình soạn.';

  @override
  String get meetingMicSilentWarning =>
      'Micro có thể đang tắt tiếng — người khác đang nói nhưng không có tín hiệu đến micro của bạn.';

  @override
  String get meetingSummaryPrivacyNotice =>
      'Ghi âm và phiên âm được giữ trên máy này. Tóm tắt do một agent viết, nên nếu dùng mô hình đám mây thì bản phiên âm và ghi chú sẽ được gửi tới nhà cung cấp đó.';

  @override
  String get meetingTemplates => 'Mẫu ghi chú cuộc họp';

  @override
  String get meetingTemplatesHint =>
      'Định hình tóm tắt AI cho từng loại cuộc họp. Mẫu đang dùng áp dụng cho tóm tắt mới và chạy lại.';

  @override
  String get meetingTemplateActive => 'Mẫu đang dùng';

  @override
  String get meetingTemplateAdd => 'Thêm mẫu';

  @override
  String get meetingTemplateNewTitle => 'Mẫu mới';

  @override
  String get meetingTemplateEditTitle => 'Sửa mẫu';

  @override
  String get meetingTemplateNameLabel => 'Tên';

  @override
  String get meetingTemplateNameHint => 'vd. Sprint review';

  @override
  String get meetingTemplateInstructionsLabel => 'Hướng dẫn';

  @override
  String get meetingTemplateInstructionsHint =>
      'AI nên cấu trúc và nhấn mạnh ghi chú này thế nào?';

  @override
  String get workingMemory => 'Bộ nhớ làm việc';

  @override
  String get workspaceName => 'Tên không gian làm việc';

  @override
  String get workspaceScopedSkills =>
      'Tệp skill theo không gian làm việc được gắn vào agent.';

  @override
  String get workspaces => 'Không gian làm việc';

  @override
  String get writePrivateNotes => 'Viết ghi chú riêng, nhận xét, kế hoạch...';

  @override
  String get writeSkillContent => 'Viết nội dung skill tại đây (Markdown)…';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count năm trước',
      one: '1 năm trước',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'Hôm qua';

  @override
  String get focusModeStart => 'Bắt đầu phiên tập trung';

  @override
  String get focusModeConfigTitle => 'Bắt đầu phiên tập trung';

  @override
  String get focusModeGoalLabel => 'Mục tiêu';

  @override
  String get focusModeGoalHint => 'Bạn đang làm gì?';

  @override
  String get focusModeDurationLabel => 'Thời lượng';

  @override
  String get focusModeBlockNotifications => 'Chặn thông báo';

  @override
  String get focusModeStartButton => 'Bắt đầu';

  @override
  String get focusModeFloat => 'Thu nhỏ xuống thanh';

  @override
  String get dismiss => 'Bỏ qua';

  @override
  String get acceptAndResolve => 'Chấp nhận và giải quyết';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'Bạn đã review $minutes phút — nghiên cứu cho thấy chất lượng review có thể giảm sau 60 phút. Nên nghỉ một chút.';
  }

  @override
  String get notificationSound => 'Âm thanh thông báo';

  @override
  String get notificationSoundDescription =>
      'Âm thanh phát khi hiện thông báo.';

  @override
  String get notificationSoundNone => 'Không';

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
  String get notificationSoundMigrosSoft => 'Migros (nhẹ)';

  @override
  String get notificationSoundMigrosHard => 'Migros (mạnh)';

  @override
  String get notificationSoundSbb => 'SBB';

  @override
  String get notificationSoundCff => 'CFF';

  @override
  String get notificationSoundFfs => 'FFS';

  @override
  String get notificationSoundPost => 'Post';

  @override
  String get notificationSoundTest => 'Thử';

  @override
  String get notificationVolume => 'Âm lượng';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'Không có PR nào của @$login trong không gian làm việc này';
  }

  @override
  String get usersLabel => 'Người dùng';

  @override
  String get mergePullRequest => 'Merge pull request';

  @override
  String get forceMergePullRequest => 'Force merge pull request';

  @override
  String get closePullRequest => 'Đóng pull request';

  @override
  String get closePullRequestConfirm =>
      'Bạn có chắc muốn đóng pull request này?';

  @override
  String get stackedPullRequests => 'Pull request xếp chồng';

  @override
  String partOfStack(int position, int total) {
    return 'Thuộc một stack ($position trên $total)';
  }

  @override
  String get createStack => 'Tạo stack';

  @override
  String get createStackDialogTitle => 'Tạo stack pull request';

  @override
  String createStackDialogBody(int count) {
    return '$count pull request này sẽ được xếp chồng, từ dưới lên:';
  }

  @override
  String get createStackInvalidSelection =>
      'Chọn ít nhất hai pull request cùng repository để tạo stack';

  @override
  String get createStackNotAChain =>
      'Các pull request đã chọn không tạo thành chuỗi: nhánh base của mỗi pull request phải là nhánh head của pull request trước đó';

  @override
  String get createStackAlreadyStacked =>
      'Một hoặc nhiều pull request đã chọn đã nằm trong một stack';

  @override
  String get stackCreated => 'Đã tạo stack';

  @override
  String get stackCreationFailed => 'Không tạo được stack';

  @override
  String get squashAndMerge => 'Squash and merge';

  @override
  String get createMergeCommit => 'Tạo merge commit';

  @override
  String get rebaseAndMerge => 'Rebase and merge';

  @override
  String get mergeMethod => 'Phương thức hợp nhất';

  @override
  String get commitTitle => 'Tiêu đề commit';

  @override
  String get commitDescription => 'Mô tả commit';

  @override
  String get pullRequestMerged => 'Đã merge pull request';

  @override
  String get pullRequestClosed => 'Đã đóng pull request';

  @override
  String failedToMergePr(String error) {
    return 'Không merge được: $error';
  }

  @override
  String failedToClosePr(String error) {
    return 'Không đóng được: $error';
  }

  @override
  String get markReadyForReview => 'Sẵn sàng để review';

  @override
  String get markReadyForReviewConfirm =>
      'Pull request này sẽ thoát chế độ nháp. Người review được thông báo, các check bắt buộc bắt đầu chặn merge và mọi tự động hóa theo dõi pull request sẵn sàng sẽ chạy.';

  @override
  String get convertToDraft => 'Chuyển sang nháp';

  @override
  String get convertToDraftConfirm =>
      'Pull request này sẽ trở lại nháp. Các yêu cầu review đang chờ sẽ bị hủy và không thể merge cho đến khi bạn đánh dấu sẵn sàng lại.';

  @override
  String get pullRequestMarkedReady =>
      'Đã đánh dấu pull request sẵn sàng để review';

  @override
  String get pullRequestConvertedToDraft => 'Đã chuyển pull request sang nháp';

  @override
  String failedToMarkPrReady(String error) {
    return 'Không đánh dấu sẵn sàng để review được: $error';
  }

  @override
  String failedToConvertPrToDraft(String error) {
    return 'Không chuyển sang nháp được: $error';
  }

  @override
  String get checksFailing => 'Checks thất bại';

  @override
  String get reviewsPending => 'Một số review đang chờ';

  @override
  String get mergeConflictsWithBase =>
      'Nhánh này có xung đột cần được giải quyết';

  @override
  String get branchOutOfDateWithBase =>
      'Nhánh này đã lỗi thời so với nhánh base';

  @override
  String get mergeBlockedByBranchProtection =>
      'Bảo vệ nhánh chặn thao tác merge này';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get trustedSitesSectionTitle => 'Trang tin cậy';

  @override
  String get trustedSitesEmpty =>
      'Chưa có trang tin cậy. Thêm một domain để tắt chặn trên đó.';

  @override
  String get addTrustedSite => 'Thêm trang tin cậy';

  @override
  String get removeTrustedSite => 'Xóa';

  @override
  String get disableBlockingForThisSite => 'Tắt chặn trên trang này';

  @override
  String get enableBlockingForThisSite => 'Bật chặn trên trang này';

  @override
  String get enterDomainHint => 'vd. example.com';

  @override
  String get invalidDomain => 'Nhập một tên miền hợp lệ (vd. example.com)';

  @override
  String get pageLoadTimedOut =>
      'Tải trang quá hạn. Tải lại hoặc mở trong trình duyệt.';

  @override
  String get pipelinesScreenTitle => 'Pipelines';

  @override
  String get pipelinesScreenSubtitle => 'Quy trình agent nhiều bước, khai báo';

  @override
  String get pipelinesRunPipeline => 'Chạy quy trình';

  @override
  String get pipelineRunLauncherTitle => 'Chạy quy trình';

  @override
  String get pipelineRunSubtitle =>
      'Chọn một quy trình và điền đầu vào để bắt đầu chạy.';

  @override
  String get pipelineRunNoInputsBadge => 'Không có đầu vào';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count đầu vào',
      one: '1 đầu vào',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'Quy trình này không cần đầu vào.';

  @override
  String get pipelineRunSubmit => 'Chạy quy trình';

  @override
  String get pipelineRunCouldNotStart => 'Không thể bắt đầu lần chạy.';

  @override
  String pipelineRunStarted(String name) {
    return 'Đã bắt đầu $name';
  }

  @override
  String get pipelineRunEmptyTitle => 'Chưa có quy trình sẵn sàng chạy';

  @override
  String get pipelineRunEmptyHint =>
      'Bật một quy trình và bật chạy thủ công trong trình chỉnh sửa để khởi chạy tại đây.';

  @override
  String get pipelineRunManageTemplates => 'Quản lý quy trình';

  @override
  String get pipelineRunSettingsTitle => 'Chạy thủ công';

  @override
  String get pipelineRunSettingsAllow => 'Cho phép chạy thủ công';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'Hiện quy trình này trên trang chạy để có thể khởi chạy bằng tay.';

  @override
  String get pipelineRunSettingsConcurrencyTitle => 'Đồng thời';

  @override
  String get pipelineRunSettingsMaxParallel => 'Số lần chạy song song tối đa';

  @override
  String get pipelineRunSettingsMaxParallelHelp =>
      'Để trống nếu không giới hạn. Các lần chạy thêm chờ trong hàng đợi và bắt đầu khi có chỗ trống.';

  @override
  String get pipelineRunSettingsMaxParallelHint => 'Không giới hạn';

  @override
  String get pipelineRunSettingsMaxParallelInvalid =>
      'Nhập số nguyên từ 1 trở lên, hoặc để trống nếu không giới hạn.';

  @override
  String get pipelineRunSettingsInputsTitle => 'Đầu vào';

  @override
  String get pipelineRunSettingsAddInput => 'Thêm đầu vào';

  @override
  String get pipelineRunSettingsNoInputs => 'Chưa có đầu vào.';

  @override
  String get pipelineInputEditTitle => 'Trường đầu vào';

  @override
  String get pipelineInputKeyLabel => 'Khóa';

  @override
  String get pipelineInputKeyHelp =>
      'Khóa trạng thái dùng để lưu giá trị (vd. repo_full_name).';

  @override
  String get pipelineInputLabelLabel => 'Nhãn';

  @override
  String get pipelineInputTypeLabel => 'Loại';

  @override
  String get pipelineInputOptionsLabel => 'Tùy chọn (cách nhau bằng dấu phẩy)';

  @override
  String get pipelineInputDefaultLabel => 'Giá trị mặc định';

  @override
  String get pipelineInputPlaceholderLabel => 'Placeholder';

  @override
  String get pipelineInputHelpLabel => 'Văn bản trợ giúp';

  @override
  String get pipelineInputRequiredLabel => 'Bắt buộc';

  @override
  String get pipelineInputTypeText => 'Văn bản';

  @override
  String get pipelineInputTypeMultiline => 'Văn bản nhiều dòng';

  @override
  String get pipelineInputTypeNumber => 'Số';

  @override
  String get pipelineInputTypeBoolean => 'Công tắc';

  @override
  String get pipelineInputTypeSelect => 'Chọn';

  @override
  String get pipelinesEmpty => 'Chưa có lần chạy quy trình';

  @override
  String get pipelinesEmptyHint =>
      'Nhấp \'Chạy quy trình\' để bắt đầu một lần chạy.';

  @override
  String get pipelinesNoSteps => 'Chưa ghi nhận bước nào';

  @override
  String get pipelinesNoActiveWorkspace =>
      'Chọn một không gian làm việc để xem quy trình của nó';

  @override
  String pipelinesLoadError(String error) {
    return 'Không tải được quy trình: $error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'Không bắt đầu được quy trình: $error';
  }

  @override
  String get pipelineStatusPending => 'Đang chờ';

  @override
  String get pipelineStatusQueued => 'Trong hàng đợi';

  @override
  String get pipelineStatusRunning => 'Đang chạy';

  @override
  String get pipelineStatusSuspended => 'Tạm dừng';

  @override
  String get pipelineStatusCompleted => 'Hoàn tất';

  @override
  String get pipelineStatusFailed => 'Thất bại';

  @override
  String get pipelineStatusCancelled => 'Đã hủy';

  @override
  String get pipelineStatusSkipped => 'Đã bỏ qua';

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed / $total bước';
  }

  @override
  String get pipelineWaterfallTimeline => 'Dòng thời gian';

  @override
  String pipelineWaterfallActive(String duration) {
    return 'Đang hoạt động $duration';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return 'nhàn rỗi $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip =>
      'Thời gian không tính vào tổng đang chạy: lần chạy đã dừng hoặc đang chờ giữa các bước.';

  @override
  String get pipelineStepStarted => 'Bắt đầu';

  @override
  String get pipelineStepFinished => 'Kết thúc';

  @override
  String get pipelineStepDurationLabel => 'Thời lượng';

  @override
  String get pipelineStepViewConversation => 'Xem hội thoại';

  @override
  String get pipelineStepError => 'Lỗi';

  @override
  String get pipelineStepInput => 'Đầu vào';

  @override
  String get pipelineStepOutput => 'Đầu ra';

  @override
  String get pipelineStepNotExecuted => 'Chưa chạy';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'Thất bại tại $step';
  }

  @override
  String get pipelineRunTriggerManual => 'Thủ công';

  @override
  String get pipelineStepSkippedReason => 'Bỏ qua';

  @override
  String get pipelineStepPriorAttempts => 'Các lần thử trước';

  @override
  String get pipelineStepAttemptLabel => 'Lần thử';

  @override
  String pipelineStepAttemptN(int number) {
    return 'Lần thử $number';
  }

  @override
  String get pipelineStepAttemptInterrupted => 'Bị gián đoạn';

  @override
  String get pipelineRunColumnPipeline => 'Quy trình';

  @override
  String get pipelineRunColumnDuration => 'Thời lượng';

  @override
  String get pipelineRunQueueNext => 'Tiếp theo';

  @override
  String pipelineRunQueuePosition(int position) {
    return '$position trong hàng đợi';
  }

  @override
  String get pipelineRunColumnStarted => 'Bắt đầu';

  @override
  String get pipelineRunHistory => 'Lịch sử chạy';

  @override
  String get pipelineRunHistoryEmpty => 'Chưa có lần chạy khác';

  @override
  String pipelineRunRerunAgo(String time) {
    return 'Chạy lại $time';
  }

  @override
  String pipelineRunAttempt(int number) {
    return 'Lần thử $number';
  }

  @override
  String pipelineRunFirstStarted(String time) {
    return 'bắt đầu lần đầu $time';
  }

  @override
  String get pipelineRunFilterAll => 'Tất cả';

  @override
  String get pipelineRunFilterEmpty => 'Không có lần chạy nào khớp bộ lọc này';

  @override
  String get relativeJustNow => 'vừa xong';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count phút trước',
      one: '1 phút trước',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giờ trước',
      one: '1 giờ trước',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày trước',
      one: '1 ngày trước',
    );
    return '$_temp0';
  }

  @override
  String get teamsTitle => 'Nhóm';

  @override
  String get teamsAddTeam => 'Thêm nhóm';

  @override
  String get teamsLoadError => 'Không tải được nhóm';

  @override
  String get teamsEmptyTitle => 'Chưa có nhóm';

  @override
  String get teamsEmptyDescription =>
      'Gom các agent thành nhóm để công việc giao cho nhóm đi qua trưởng nhóm rồi được phân công.';

  @override
  String get teamCreateTitle => 'Nhóm mới';

  @override
  String get teamEditTitle => 'Sửa nhóm';

  @override
  String get teamNameLabel => 'Tên nhóm';

  @override
  String get teamNameHint => 'vd. Frontend';

  @override
  String get teamDescriptionLabel => 'Mô tả';

  @override
  String get teamDescriptionHint => 'Nhóm này chịu trách nhiệm việc gì';

  @override
  String get teamLeaderLabel => 'Trưởng nhóm';

  @override
  String get teamLeaderHelp =>
      'Người điều phối nhận công việc giao cho nhóm và phân công cho thành viên phù hợp nhất.';

  @override
  String get teamNoLeader => 'Không có trưởng nhóm';

  @override
  String get teamInstructionsLabel => 'Hướng dẫn vận hành';

  @override
  String get teamInstructionsHelp =>
      'Được thêm vào briefing của trưởng nhóm — quy ước nhóm, quy tắc leo thang, giọng điệu.';

  @override
  String get teamInstructionsHint => 'Không bắt buộc';

  @override
  String get teamSaved => 'Đã lưu nhóm';

  @override
  String get teamMembersError => 'Không tải được thành viên';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thành viên',
      one: '1 thành viên',
      zero: 'Không có thành viên',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => 'Thêm thành viên';

  @override
  String get teamAddMemberTitle => 'Thêm thành viên';

  @override
  String teamAddMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count',
      one: 'Add 1',
      zero: 'Add',
    );
    return '$_temp0';
  }

  @override
  String get teamNoAgentsToAdd => 'Mọi agent đều đã trong nhóm này.';

  @override
  String get teamRemoveMember => 'Gỡ khỏi nhóm';

  @override
  String get teamLeaderBadge => 'Trưởng nhóm';

  @override
  String get teamUnknownAgent => 'Agent không xác định';

  @override
  String get teamMembersEmpty => 'Chưa có thành viên';

  @override
  String get teamMembersEmptyDescription =>
      'Thêm agent để trưởng nhóm có người giao việc.';

  @override
  String get teamSelectPrompt => 'Chọn nhóm';

  @override
  String get teamSelectPromptDescription =>
      'Chọn một nhóm từ danh sách, hoặc tạo nhóm mới.';

  @override
  String get teamDeleteTitle => 'Xóa nhóm?';

  @override
  String teamDeleteBody(String name) {
    return '$name sẽ bị xóa. Các agent trong nhóm không bị ảnh hưởng.';
  }

  @override
  String get teamHasLeaderTooltip => 'Có trưởng nhóm';

  @override
  String get pipelineTemplatesNav => 'Mẫu quy trình';

  @override
  String get pipelineTemplatesTitle => 'Mẫu quy trình';

  @override
  String get pipelineTemplatesSubtitle =>
      'Trình soạn kéo thả cho các quy trình điều phối agent.';

  @override
  String get pipelineTemplatesNew => 'Mẫu mới';

  @override
  String get pipelineTemplatesEmpty =>
      'Chưa có mẫu quy trình. Tạo một mẫu để bắt đầu.';

  @override
  String get pipelineTemplateBuiltInBadge => 'Có sẵn';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'Xóa mẫu?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'Xóa mẫu quy trình $name? Không thể hoàn tác.';
  }

  @override
  String get pipelineTemplateEditorSubtitle =>
      'Kéo các loại nút từ thanh bên vào canvas, rồi nối chúng với nhau.';

  @override
  String get unsavedChanges => 'Thay đổi chưa lưu';

  @override
  String get nodeLibraryTitle => 'Thư viện nút';

  @override
  String get nodeLibraryHint => 'Kéo bất kỳ mục nào vào canvas để thêm nút.';

  @override
  String get editorEmptyCanvas => 'Kéo một nút từ thư viện để bắt đầu.';

  @override
  String get pipelineWhenThisHappens => 'Khi việc này xảy ra';

  @override
  String get pipelineDoThis => 'Làm điều này';

  @override
  String get pipelineAddStep => 'Thêm bước';

  @override
  String get pipelineTidyUp => 'Sắp xếp bố cục';

  @override
  String get pipelineEditorHint =>
      'Kéo các bước để sắp xếp · kéo tay cầm để nối';

  @override
  String get pipelineRemoveConnection => 'Xóa kết nối';

  @override
  String get pipelineDragToConnect => 'Kéo để kết nối';

  @override
  String get pipelineNewDefaultName => 'Quy trình mới';

  @override
  String get nodeCategoryTriggers => 'Bộ kích hoạt';

  @override
  String get triggerEventWebhook => 'Webhook';

  @override
  String get pipelineAddTrigger => 'Thêm bộ kích hoạt';

  @override
  String get pipelineOnEvent => 'Khi có sự kiện';

  @override
  String get nodeConfigTitle => 'Cấu hình nút';

  @override
  String get nodeConfigKind => 'Loại';

  @override
  String get nodeConfigLabel => 'Nhãn';

  @override
  String get nodeConfigAgent => 'Agent';

  @override
  String get nodeConfigAgentHint => 'Chọn agent…';

  @override
  String get nodeConfigInputKeys => 'Khóa đầu vào (cách nhau bằng dấu phẩy)';

  @override
  String get nodeConfigInputKeysHelp =>
      'Các khóa trạng thái nút này sử dụng. Dùng để thay thế placeholder trong prompt.';

  @override
  String get nodeConfigRepos => 'Kho cần clone';

  @override
  String get nodeConfigReposHelp =>
      'Repo được clone và lập chỉ mục mã khi nút này bắt đầu hội thoại. Chọn mọi repo sẽ clone tất cả (mặc định).';

  @override
  String get nodeConfigRepoBranchHint => 'Nhánh (mặc định)';

  @override
  String get nodeConfigRepoBranchHelp =>
      'Nhánh gốc cho mỗi lần checkout. Để trống để dùng nhánh mặc định của repo — cây làm việc vẫn có nhánh riêng, nên commit của agent không rơi vào nhánh này.';

  @override
  String nodeConfigReposDynamic(String entries) {
    return 'Mục động được giữ: $entries';
  }

  @override
  String get nodeConfigCreateConversation => 'Mở hội thoại trong đó';

  @override
  String get nodeConfigCreateConversationHelp =>
      'Tắt khi có nhiều nút agent phía sau — mỗi nút mở stream mang tên riêng. Bật khi chỉ có một nút agent phía sau, để phòng không hiện hội thoại chưa đặt tên bên cạnh.';

  @override
  String get nodeConfigConversationTitle => 'Tên hội thoại';

  @override
  String get nodeConfigConversationTitleHelp =>
      'Đặt cùng tên cho nút agent phía sau để cả hai làm việc trong một stream. Mặc định là nhãn của nút.';

  @override
  String get nodeConfigSpaceName => 'Tên không gian';

  @override
  String get nodeConfigSpaceNameHelp =>
      'Tên phòng mà nút này mở. Hỗ trợ cùng placeholder trạng thái như prompt. Để trống để dùng nhãn của nút.';

  @override
  String get nodeConfigSpaceNameHint => 'Đánh giá pr_number';

  @override
  String get nodeConfigStreamTitle => 'Tên hội thoại';

  @override
  String get nodeConfigStreamTitleHelp =>
      'Stream mang tên mà agent của nút này làm việc trong phòng. Hỗ trợ cùng placeholder trạng thái như prompt. Để trống thì lượt sẽ vào hội thoại thường trực của phòng, nơi fan-out xen kẽ mọi agent.';

  @override
  String get nodeConfigConversationTitleHint => 'Phân tích kiến trúc';

  @override
  String get nodeConfigOutputKey => 'Khóa đầu ra';

  @override
  String get nodeConfigPrompt => 'Mẫu prompt';

  @override
  String get nodeConfigPromptHelp =>
      'Dùng placeholder ngoặc nhọn kép để lấy giá trị từ trạng thái lúc chạy.';

  @override
  String get nodeConfigScript => 'Script bash';

  @override
  String get nodeConfigScriptHelp =>
      'Chạy bằng bash -c trong sandbox của hệ điều hành. GH_TOKEN và GITHUB_TOKEN chứa token chỉ đọc cho kho mã đã liên kết. Placeholder được đặt trong dấu nháy và thay thế trước khi thực thi.';

  @override
  String get nodeConfigRouteKeys => 'Khóa định tuyến';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'Khóa định tuyến từ $source';
  }

  @override
  String get conditionSectionTitle => 'Điều kiện';

  @override
  String get conditionMode => 'Chế độ';

  @override
  String get conditionModeFilesAny => 'Tệp tồn tại — bất kỳ';

  @override
  String get conditionModeFilesAll => 'Tệp tồn tại — tất cả';

  @override
  String get conditionModeComparison => 'So sánh';

  @override
  String get conditionModeSwitch => 'Chuyển';

  @override
  String get conditionFilePaths => 'Đường dẫn tệp';

  @override
  String get conditionFilePathsAnyHelp =>
      'Một đường dẫn mỗi dòng, tương đối so với thư mục gốc. Đúng khi bất kỳ đường dẫn nào tồn tại.';

  @override
  String get conditionFilePathsAllHelp =>
      'Một đường dẫn mỗi dòng, tương đối so với thư mục gốc. Chỉ đúng khi tất cả đều tồn tại.';

  @override
  String get conditionBaseKey => 'Khóa thư mục gốc';

  @override
  String get conditionBaseKeyHelp =>
      'Khóa state chứa thư mục dùng để phân giải đường dẫn (mặc định repo_local_path).';

  @override
  String get conditionRecursive => 'Tìm trong thư mục con';

  @override
  String get conditionNegate => 'Đảo: đúng khi thiếu';

  @override
  String get conditionLeft => 'Giá trị trái';

  @override
  String get conditionOperator => 'Toán tử';

  @override
  String get conditionRight => 'Giá trị phải';

  @override
  String get conditionSwitchKey => 'Chuyển theo khóa state';

  @override
  String get conditionCases => 'Các nhánh (phân tách bằng dấu phẩy)';

  @override
  String get conditionCasesHelp =>
      'Các khóa nhánh để khớp với giá trị, theo thứ tự.';

  @override
  String get conditionDefaultCase => 'Nhánh mặc định';

  @override
  String get triggerManualHelp => 'Hiện trên trang chạy và khởi chạy thủ công.';

  @override
  String get triggerKindSchedule => 'Theo lịch';

  @override
  String get triggerScheduleExprLabel => 'Lịch (cron hoặc every:seconds)';

  @override
  String get triggerTimezoneLabel => 'Múi giờ (tùy chọn)';

  @override
  String get triggerCatchUpLabel => 'Khi bỏ lỡ lần chạy';

  @override
  String get triggerCatchUpRunOnce => 'Chạy một lần';

  @override
  String get triggerCatchUpSkip => 'Bỏ qua';

  @override
  String get syncHealthTitle => 'Tình trạng đồng bộ';

  @override
  String get syncHealthNoConfigs => 'Chưa có kết nối đồng bộ';

  @override
  String get syncHealthNeverSynced => 'Chưa từng đồng bộ';

  @override
  String get syncOutcomeOk => 'Đã đồng bộ';

  @override
  String get syncOutcomeFailed => 'Thất bại';

  @override
  String get syncOutcomeSkipped => 'Đã bỏ qua';

  @override
  String syncHealthFailedStreak(int count) {
    return '$count lần thất bại liên tiếp';
  }

  @override
  String get triggerWebhookHelp =>
      'Một URL webhook đã ký được tạo. Hệ thống bên ngoài POST tới đó để khởi chạy quy trình này.';

  @override
  String get triggerWebhookPathLabel => 'Đường dẫn webhook';

  @override
  String get triggerMatchStatusLabel => 'Chỉ khi trạng thái là';

  @override
  String get triggerSummaryNone => 'Không có bộ kích hoạt';

  @override
  String triggerEverySeconds(int seconds) {
    return 'Mỗi ${seconds}s';
  }

  @override
  String get triggerEventManual => 'Chạy thủ công';

  @override
  String get triggerEventSchedule => 'Lịch';

  @override
  String get triggerEventPrStatusChanged => 'Trạng thái PR đã đổi';

  @override
  String get triggerEventExternalPr => 'PR bên ngoài được mở';

  @override
  String get triggerEventPrPublished => 'PR được xuất bản';

  @override
  String get triggerEventPrMerged => 'PR được hợp nhất';

  @override
  String get triggerEventRepoAdded => 'Đã thêm kho lưu trữ';

  @override
  String get triggerEventCodeGraphWatch => 'Thay đổi tệp';

  @override
  String pipelineRunCauseChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tệp đã thay đổi',
      one: '1 tệp đã thay đổi',
    );
    return '$_temp0';
  }

  @override
  String pipelineRunCauseMorePaths(int count) {
    return '+$count nữa';
  }

  @override
  String get pipelineRunCauseRescan => 'Thay đổi trên đĩa';

  @override
  String get pipelineRunCauseInitial => 'Lần lập chỉ mục đầu của checkout này';

  @override
  String get triggerEventMessageReceived => 'Đã nhận tin nhắn';

  @override
  String get triggerEventTicketCompleted => 'Phiếu hoàn tất';

  @override
  String get triggerEventTicketFailed => 'Phiếu thất bại';

  @override
  String get triggerEventTicketCancelled => 'Phiếu bị hủy';

  @override
  String get triggerEventBudgetCrossed => 'Đã vượt ngưỡng ngân sách';

  @override
  String get nodeLibrarySearchHint => 'Tìm node';

  @override
  String get nodeLibraryNoMatches => 'Không có node khớp';

  @override
  String get nodeCategoryFlow => 'Luồng & logic';

  @override
  String get nodeCategoryPr => 'Đánh giá PR';

  @override
  String get nodeCategoryAgents => 'Agents';

  @override
  String get nodeCategoryMessaging => 'Nhắn tin';

  @override
  String get nodeCategoryCode => 'Code';

  @override
  String get triggerDisabledTag => 'tắt';

  @override
  String get pipelineInputTypeRepo => 'Repository';

  @override
  String get pipelineRunNoRepos =>
      'Chưa có repository nào trong không gian làm việc này.';

  @override
  String get ticketingApiKey => 'Khóa API phiếu';

  @override
  String get ticketingProvider => 'Nhà cung cấp phiếu';

  @override
  String get connectGitHubAndTicketing =>
      'Kết nối máy chủ mã nguồn để Control Center đọc pull request, issue và đánh giá của bạn. Có thể kết nối thêm nhà cung cấp phiếu. Thông tin xác thực được lưu trên máy chủ của bạn, không phải trên máy này.';

  @override
  String get triggerEventTicketAssigned => 'Phiếu được gán';

  @override
  String get triggerEventTicketCreated => 'Phiếu được tạo';

  @override
  String get triggerEventTicketStatusChanged => 'Trạng thái phiếu đã đổi';

  @override
  String get triggerEventMeetingRecordingStopped => 'Đã dừng ghi cuộc họp';

  @override
  String get triggerEventSkillUpdated => 'Kỹ năng đã cập nhật';

  @override
  String get triggerEventSpaceDeleted => 'Không gian đã xóa';

  @override
  String get triggerEventSpaceArchived => 'Không gian đã lưu trữ';

  @override
  String get triggerEventSpaceProvisioningChanged =>
      'Chuẩn bị không gian đã đổi';

  @override
  String get triggerEventPrHeadChanged => 'Head của PR đã đổi';

  @override
  String get triggerEventEnvironmentStatusChanged =>
      'Trạng thái môi trường đã đổi';

  @override
  String get triggerEventEnvironmentReady => 'Môi trường sẵn sàng';

  @override
  String get triggerEventEnvironmentDestroyed => 'Môi trường đã hủy';

  @override
  String get triggerEventEnvironmentProcessExited =>
      'Tiến trình môi trường đã thoát';

  @override
  String get triggerExternalPrHelp =>
      'Một pull request được mở trên máy chủ mã, không phải từ Control Center.';

  @override
  String get triggerPrPublishedHelp =>
      'Một pull request được mở từ Control Center hoặc bởi một tác nhân.';

  @override
  String get triggerPrStatusChangedHelp =>
      'Đã hợp nhất, đóng, mở, mở lại hoặc phê duyệt. Lọc theo trạng thái trong trình kiểm tra.';

  @override
  String get triggerPrMergedHelp =>
      'Chỉ khi pull request được hợp nhất, không phải khi đóng hoặc mở lại.';

  @override
  String get triggerRepoAddedHelp =>
      'Một kho được liên kết với không gian làm việc này.';

  @override
  String get triggerCodeGraphWatchHelp =>
      'Một tệp trong kho đã liên kết thay đổi trên đĩa.';

  @override
  String get triggerMessageReceivedHelp =>
      'Một tin nhắn mới đến trong một không gian.';

  @override
  String get triggerTicketCreatedHelp =>
      'Một phiếu được tạo trong không gian làm việc này.';

  @override
  String get triggerTicketStatusChangedHelp =>
      'Một phiếu chuyển giữa các trạng thái.';

  @override
  String get triggerTicketCompletedHelp => 'Một phiếu kết thúc thành công.';

  @override
  String get triggerTicketFailedHelp =>
      'Một lần chạy tác nhân thất bại và phiếu được đánh dấu thất bại.';

  @override
  String get triggerTicketCancelledHelp =>
      'Một phiếu bị hủy và sẽ không tiếp tục.';

  @override
  String get triggerBudgetCrossedHelp =>
      'Vượt giới hạn chi tiêu của không gian làm việc hoặc tác nhân.';

  @override
  String get triggerTicketAssignedHelp =>
      'Một phiếu được gán cho người, tác nhân hoặc nhóm.';

  @override
  String get triggerMeetingRecordingStoppedHelp => 'Bản ghi cuộc họp kết thúc.';

  @override
  String get triggerSkillUpdatedHelp => 'Một kỹ năng được cài hoặc cập nhật.';

  @override
  String get triggerSpaceDeletedHelp => 'Một không gian hội thoại bị xóa.';

  @override
  String get triggerSpaceArchivedHelp =>
      'Một không gian hội thoại được lưu trữ.';

  @override
  String get triggerSpaceProvisioningChangedHelp =>
      'Việc chuẩn bị cây làm việc của không gian bắt đầu, hoàn tất hoặc thất bại.';

  @override
  String get triggerPrHeadChangedHelp =>
      'Commit mới được đẩy lên một pull request đang mở.';

  @override
  String get triggerEnvironmentStatusChangedHelp =>
      'Một môi trường không gian chuyển sang trạng thái mới.';

  @override
  String get triggerEnvironmentReadyHelp =>
      'Một môi trường không gian đã khởi động và có thể sử dụng.';

  @override
  String get triggerEnvironmentDestroyedHelp =>
      'Một môi trường không gian bị gỡ bỏ.';

  @override
  String get triggerEnvironmentProcessExitedHelp =>
      'Một tiến trình do môi trường chạy đã thoát.';

  @override
  String get navTickets => 'Phiếu';

  @override
  String get ticketsTitle => 'Phiếu';

  @override
  String get newTicket => 'Phiếu mới';

  @override
  String get noTicketsYet => 'Chưa có phiếu nào';

  @override
  String get addCollaborator => 'Thêm cộng tác viên';

  @override
  String get noCollaborators => 'Chưa có cộng tác viên';

  @override
  String get linkedPullRequests => 'Pull request đã liên kết';

  @override
  String get noLinkedPullRequests => 'Chưa có pull request nào được liên kết';

  @override
  String get stopAgent => 'Dừng agent';

  @override
  String get ticketProperties => 'Thuộc tính';

  @override
  String get ticketTabIssue => 'Issue';

  @override
  String get ticketSelectPrompt => 'Chọn phiếu để xem chi tiết';

  @override
  String get unassigned => 'Chưa gán';

  @override
  String get ticketStatusBacklog => 'Backlog';

  @override
  String get ticketStatusOpen => 'Cần làm';

  @override
  String get ticketStatusInProgress => 'Đang làm';

  @override
  String get ticketStatusInReview => 'Đang đánh giá';

  @override
  String get ticketStatusDone => 'Hoàn tất';

  @override
  String get ticketStatusBlocked => 'Bị chặn';

  @override
  String get ticketStatusFailed => 'Thất bại';

  @override
  String get ticketStatusCancelled => 'Đã hủy';

  @override
  String get notificationTicketAssigned => 'Phiếu được gán';

  @override
  String get notificationTicketStatusChanged => 'Trạng thái phiếu đã đổi';

  @override
  String get priority => 'Độ ưu tiên';

  @override
  String get status => 'Trạng thái';

  @override
  String get assignee => 'Người được gán';

  @override
  String get labels => 'Nhãn';

  @override
  String get noLabelsYet => 'Chưa có nhãn';

  @override
  String get clearLabels => 'Xóa nhãn';

  @override
  String get pipelineStepAgentActivity => 'Hoạt động của agent';

  @override
  String get runStatusCompleted => 'Hoàn tất';

  @override
  String get runStatusQueued => 'Trong hàng đợi';

  @override
  String get ticketDescription => 'Mô tả';

  @override
  String get ticketPriorityNone => 'Không';

  @override
  String get ticketPriorityUrgent => 'Khẩn cấp';

  @override
  String get ticketPriorityHigh => 'Cao';

  @override
  String get ticketPriorityMedium => 'Trung bình';

  @override
  String get ticketPriorityLow => 'Thấp';

  @override
  String get ticketViewList => 'Danh sách';

  @override
  String get ticketViewBoard => 'Bảng';

  @override
  String get ticketTitlePlaceholder => 'Tiêu đề issue';

  @override
  String get ticketDescriptionPlaceholder => 'Thêm mô tả…';

  @override
  String get createMore => 'Tạo thêm';

  @override
  String selectedCount(int count) {
    return '$count đã chọn';
  }

  @override
  String get clearSelection => 'Bỏ chọn';

  @override
  String get bulkDeleteTitle => 'Xóa phiếu';

  @override
  String bulkDeleteMessage(int count) {
    return 'Xóa $count phiếu đã chọn? Không thể hoàn tác.';
  }

  @override
  String get assignTo => 'Gán cho…';

  @override
  String get sectionMembers => 'Thành viên';

  @override
  String get sectionAgents => 'Agents';

  @override
  String get sidebarGroupWorkspace => 'Không gian làm việc';

  @override
  String get notificationsTitle => 'Thông báo';

  @override
  String get notificationsTooltip => 'Thông báo';

  @override
  String get notificationsEmpty => 'Bạn đã xem hết';

  @override
  String notificationsUnreadCount(int count) {
    return '$count chưa đọc';
  }

  @override
  String get notificationsMarkRead => 'Đánh dấu đã đọc';

  @override
  String get notificationsMarkUnread => 'Đánh dấu chưa đọc';

  @override
  String get notificationsEntryActions => 'Thao tác thông báo';

  @override
  String get markAllRead => 'Đánh dấu tất cả đã đọc';

  @override
  String get teamsNav => 'Nhóm';

  @override
  String get noWorkspace => 'Không có không gian làm việc';

  @override
  String get selectWorkspace => 'Chọn không gian làm việc';

  @override
  String get navMemory => 'Bộ nhớ';

  @override
  String get memoryTabFacts => 'Sự kiện';

  @override
  String get memoryTabPolicies => 'Chính sách';

  @override
  String get memoryGraphShowFacts => 'Hiện sự kiện';

  @override
  String get memoryGraphHideFacts => 'Ẩn sự kiện';

  @override
  String get memoryGraphExpandAll => 'Mở rộng tất cả sự kiện';

  @override
  String get memoryGraphCollapseAll => 'Thu gọn tất cả sự kiện';

  @override
  String get memoryTabGraph => 'Đồ thị tri thức';

  @override
  String get memoryNoWorkspace =>
      'Chọn không gian làm việc để xem bộ nhớ của nó.';

  @override
  String get searchArticles => 'Tìm bài viết';

  @override
  String get filterAll => 'Tất cả';

  @override
  String get filterUnread => 'Chưa đọc';

  @override
  String get filterSaved => 'Đã lưu';

  @override
  String get saveArticle => 'Lưu bài viết';

  @override
  String get removeFromSaved => 'Xóa khỏi đã lưu';

  @override
  String get filterBySource => 'Lọc theo nguồn';

  @override
  String get viewAsList => 'Xem dạng danh sách';

  @override
  String get viewAsGrid => 'Xem dạng lưới';

  @override
  String get noMatchingArticles => 'Không có bài viết phù hợp';

  @override
  String get noMatchingArticlesBody => 'Thử tìm kiếm hoặc bộ lọc nguồn khác.';

  @override
  String get allCaughtUp => 'Đã xem hết';

  @override
  String get allCaughtUpBody =>
      'Không có bài viết chưa đọc — hãy quay lại sau.';

  @override
  String get openArticlesInAppDescription =>
      'Mở liên kết trong trình đọc tích hợp thay vì trình duyệt mặc định.';

  @override
  String get blockAdsTrackersDescription =>
      'Loại bỏ quảng cáo, trình theo dõi và banner cookie khỏi bài viết bạn mở trong trình đọc.';

  @override
  String get agentQuestionHeader => 'Câu hỏi dành cho bạn';

  @override
  String get agentQuestionAnsweredLabel => 'Đã trả lời';

  @override
  String get agentQuestionFreeformHint => 'Nhập câu trả lời…';

  @override
  String agentQuestionProgress(int index, int count) {
    return 'Câu hỏi $index / $count';
  }

  @override
  String get agentQuestionSkip => 'Bỏ qua';

  @override
  String get agentQuestionSkippedLabel => 'Đã bỏ qua';

  @override
  String get agentQuestionTimedOutLabel => 'Hết thời gian';

  @override
  String get agentQuestionTimeLeft => 'Thời gian còn lại để trả lời';

  @override
  String get agentQuestionFreeformOptionHint => 'Mô tả bằng lời của bạn…';

  @override
  String get reviewRequested => 'Đã yêu cầu review';

  @override
  String get noRepositoriesConfigured => 'Chưa cấu hình kho lưu trữ';

  @override
  String openedAgo(String age) {
    return 'Đã mở $age';
  }

  @override
  String prTimelineOpened(String author) {
    return '$author đã mở pull request này';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$author đã mở pull request này với $_temp0';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return '$actor đã yêu cầu review từ $reviewers';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '$actor đã gỡ yêu cầu review đối với $reviewers';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '$actor đã yêu cầu review từ $requested và gỡ yêu cầu review đối với $removed';
  }

  @override
  String prTimelineAddedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'nhãn',
      one: 'nhãn',
    );
    return '$actor đã thêm $_temp0 $labels';
  }

  @override
  String prTimelineRemovedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'nhãn',
      one: 'nhãn',
    );
    return '$actor đã gỡ $_temp0 $labels';
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
      other: 'nhãn',
      one: 'nhãn',
    );
    String _temp1 = intl.Intl.pluralLogic(
      removedCount,
      locale: localeName,
      other: 'nhãn',
      one: 'nhãn',
    );
    return '$actor đã thêm $_temp0 $added và gỡ $_temp1 $removed';
  }

  @override
  String prTimelineCommitted(String author) {
    return '$author đã commit';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$author đã đẩy $_temp0';
  }

  @override
  String prTimelineApproved(String author) {
    return '$author đã phê duyệt các thay đổi này';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return '$author đã yêu cầu thay đổi';
  }

  @override
  String prTimelineApprovedWithComments(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nhận xét',
      one: '1 nhận xét',
    );
    return '$author đã phê duyệt các thay đổi này và để lại $_temp0';
  }

  @override
  String prTimelineChangesRequestedWithComments(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nhận xét',
      one: '1 nhận xét',
    );
    return '$author đã yêu cầu thay đổi và để lại $_temp0';
  }

  @override
  String prTimelineReviewedWithComments(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nhận xét',
      one: '1 nhận xét',
    );
    return '$author đã xem xét và để lại $_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '$author đã xem xét';
  }

  @override
  String get prTimelineSomeone => 'Ai đó';

  @override
  String get prTimelineBotBadge => 'bot';

  @override
  String updatedAgo(String age) {
    return 'Cập nhật $age';
  }

  @override
  String get checksPassing => 'Kiểm tra đang đạt';

  @override
  String get checksRunning => 'Đang chạy kiểm tra';

  @override
  String get needsYourReview => 'Cần bạn xem xét';

  @override
  String get checks => 'Kiểm tra';

  @override
  String get noReviewersAssigned => 'Chưa gán người xem xét';

  @override
  String get noAssignees => 'Chưa gán người';

  @override
  String get loadingEllipsis => 'Đang tải…';

  @override
  String get loadingChecks => 'Đang tải kiểm tra…';

  @override
  String get noChecksYet => 'Chưa có kiểm tra nào chạy';

  @override
  String get noChangesToReview => 'Không có thay đổi để xem lại';

  @override
  String checksFailingCount(int count) {
    return '$count thất bại';
  }

  @override
  String get showMore => 'Hiện thêm';

  @override
  String get showLess => 'Hiện ít hơn';

  @override
  String get backToPullRequests => 'Quay lại pull request';

  @override
  String get pullRequestNotFound => 'Không tìm thấy pull request';

  @override
  String get pullRequestNotFoundBody =>
      'Có thể đã được hợp nhất, đóng hoặc chuyển đi.';

  @override
  String get couldntLoadPullRequest => 'Không tải được pull request này';

  @override
  String get showDetails => 'Hiện chi tiết';

  @override
  String get noDescriptionProvided => 'Không có mô tả.';

  @override
  String get factsHint => 'Sự kiện sẽ hiện ở đây khi agent học.';

  @override
  String get noFactsMatch => 'Không có sự kiện nào khớp tìm kiếm';

  @override
  String get memoryLoadError => 'Không tải được bộ nhớ';

  @override
  String get sortRecent => 'Gần đây';

  @override
  String get sortConfidence => 'Độ tin cậy';

  @override
  String get confidenceTooltip =>
      'Mức độ chắc chắn của agent rằng sự kiện này đúng, từ 0 đến 100%.';

  @override
  String get supersededTooltip =>
      'Một sự kiện mới hơn đã thay thế sự kiện này.';

  @override
  String get domain => 'Miền';

  @override
  String get fitToView => 'Vừa khung nhìn';

  @override
  String get project => 'Dự án';

  @override
  String get newProject => 'Dự án mới';

  @override
  String get editProject => 'Sửa dự án';

  @override
  String get deleteProject => 'Xóa dự án';

  @override
  String get noProject => 'Không có dự án';

  @override
  String get allTickets => 'Tất cả phiếu';

  @override
  String get projectNamePlaceholder => 'Tên dự án';

  @override
  String get projectDescriptionPlaceholder => 'Mô tả (tùy chọn)';

  @override
  String get projectColorLabel => 'Màu';

  @override
  String get noProjectsYet => 'Chưa có dự án';

  @override
  String get projectTicketsEmpty => 'Chưa có phiếu nào trong dự án này';

  @override
  String get createProject => 'Tạo dự án';

  @override
  String projectProgress(int done, int total) {
    return '$done trên $total hoàn thành';
  }

  @override
  String deleteProjectConfirm(String name) {
    return 'Xóa \"$name\"? Các phiếu được giữ lại và gỡ khỏi dự án.';
  }

  @override
  String get projectStatusActive => 'Đang hoạt động';

  @override
  String get projectStatusCompleted => 'Đã hoàn thành';

  @override
  String get projectStatusArchived => 'Đã lưu trữ';

  @override
  String get markProjectCompleted => 'Đánh dấu hoàn thành';

  @override
  String get markProjectActive => 'Đánh dấu đang hoạt động';

  @override
  String get archiveProject => 'Lưu trữ';

  @override
  String get restoreProject => 'Khôi phục';

  @override
  String get relations => 'Liên kết';

  @override
  String get relateTo => 'Liên kết với';

  @override
  String get relationSubIssueOf => 'Phiếu con của…';

  @override
  String get relationParentOf => 'Phiếu cha của…';

  @override
  String get relationBlockedBy => 'Bị chặn bởi…';

  @override
  String get relationBlocking => 'Đang chặn…';

  @override
  String get relationRelatedTo => 'Liên quan đến…';

  @override
  String get relationDuplicateOf => 'Trùng với…';

  @override
  String get relationGroupParent => 'Cha';

  @override
  String get relationGroupSubIssues => 'Phiếu con';

  @override
  String get relationGroupBlockedBy => 'Bị chặn bởi';

  @override
  String get relationGroupBlocking => 'Đang chặn';

  @override
  String get relationGroupRelated => 'Liên quan';

  @override
  String get relationGroupDuplicateOf => 'Trùng với';

  @override
  String get relationGroupDuplicatedBy => 'Bị trùng bởi';

  @override
  String get copyId => 'Sao chép ID';

  @override
  String get ticketIdCopied => 'Đã sao chép ID phiếu';

  @override
  String get searchTicketsHint => 'Tìm phiếu…';

  @override
  String get noMatchingTickets => 'Không có phiếu khớp';

  @override
  String get clearAll => 'Xóa tất cả';

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
      other: '$repos repo',
      one: '1 repo',
    );
    return '$_temp0 đang chờ bạn review trên $_temp1';
  }

  @override
  String get manageWorkspacesSubtitle =>
      'Đổi tên không gian làm việc và thay đổi biểu tượng — chọn một mục bên trái để chỉnh sửa.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count không gian làm việc',
      one: '1 không gian làm việc',
      zero: 'Không có không gian làm việc',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos repo',
      one: '1 repo',
      zero: 'Không có repo',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents agent',
      one: '1 agent',
      zero: '0 agent',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'Danh tính';

  @override
  String get uploadImage => 'Tải ảnh lên';

  @override
  String get failedToSaveLogo =>
      'Không lưu được ảnh logo. Hãy đảm bảo ứng dụng có thể đọc tệp đã chọn.';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG hoặc GIF tối đa 2 MB. Nếu không, chúng tôi sẽ dùng chữ cái đầu của không gian làm việc.';

  @override
  String get workspaceNameFieldHelp =>
      'Hiện trong bộ chuyển, đường dẫn và trên mọi màn hình.';

  @override
  String get dangerZone => 'Vùng nguy hiểm';

  @override
  String get deleteThisWorkspace => 'Xóa không gian làm việc này';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return 'Xóa vĩnh viễn $name, các kết nối repository, agent và bộ nhớ. Không thể hoàn tác.';
  }

  @override
  String get discard => 'Hủy';

  @override
  String discardChangesQuestion(String name) {
    return 'Hủy các thay đổi chưa lưu của $name?';
  }

  @override
  String get workspaceUpdated => 'Đã cập nhật không gian làm việc';

  @override
  String get editTitle => 'Sửa tiêu đề';

  @override
  String get editDescription => 'Sửa mô tả';

  @override
  String get addDescription => 'Thêm mô tả';

  @override
  String get prTitlePlaceholder => 'Tiêu đề';

  @override
  String get prBodyPlaceholder => 'Nhập mô tả';

  @override
  String get write => 'Viết';

  @override
  String get overview => 'Tổng quan';

  @override
  String get noFilesChanged => 'Không có tệp nào thay đổi';

  @override
  String get diff => 'Diff';

  @override
  String get preview => 'Xem trước';

  @override
  String get imageDiffBefore => 'Trước';

  @override
  String get imageDiffAfter => 'Sau';

  @override
  String get imageDiffModeTwoUp => 'Song song';

  @override
  String get imageDiffModeSwipe => 'Vuốt';

  @override
  String get imageDiffModeDifference => 'Khác biệt';

  @override
  String imageDiffChangedPercent(String percent) {
    return 'Đã đổi $percent%';
  }

  @override
  String get imageDiffPictures => 'Hình ảnh';

  @override
  String get imageDiffSource => 'Mã nguồn';

  @override
  String get imageDiffDeleted => 'Đã xóa';

  @override
  String get imageDiffAdded => 'Đã thêm';

  @override
  String imageDiffDimensions(int width, int height) {
    return 'R: ${width}px | C: ${height}px';
  }

  @override
  String get outdated => 'Lỗi thời';

  @override
  String get outdatedComments => 'Bình luận lỗi thời';

  @override
  String outdatedCountLabel(int count) {
    return '$count lỗi thời';
  }

  @override
  String get prTemplateLabel => 'Mẫu';

  @override
  String get prTemplateDefault => 'Mặc định';

  @override
  String get addReviewers => 'Thêm người review';

  @override
  String get reRequestReview => 'Yêu cầu review lại';

  @override
  String reRequestReviewFor(String label) {
    return 'Yêu cầu $label review lại';
  }

  @override
  String get addAssignees => 'Thêm người được gán';

  @override
  String get addLabels => 'Thêm nhãn';

  @override
  String get searchLabels => 'Tìm nhãn…';

  @override
  String get noMatchingLabels => 'Không có nhãn phù hợp';

  @override
  String removeLabel(String label) {
    return 'Xóa $label';
  }

  @override
  String get searchUsers => 'Tìm người…';

  @override
  String get searchReviewers => 'Tìm người và nhóm…';

  @override
  String get usersSectionLabel => 'Người';

  @override
  String get userStatusBusy => 'Bận';

  @override
  String get teamsSectionLabel => 'Nhóm';

  @override
  String get suggestedReviewers => 'Người review đề xuất';

  @override
  String get noMatchingUsers => 'Không có người khớp';

  @override
  String get noMatchingReviewers => 'Không có kết quả khớp';

  @override
  String get requiredByCodeOwners => 'Bắt buộc theo code owners';

  @override
  String reviewedOnBehalfOf(String login) {
    return 'qua $login';
  }

  @override
  String get team => 'Nhóm';

  @override
  String get markdownBold => 'Đậm';

  @override
  String get markdownItalic => 'Nghiêng';

  @override
  String get markdownHeading => 'Tiêu đề';

  @override
  String get markdownBulletList => 'Danh sách dấu đầu dòng';

  @override
  String get markdownChecklist => 'Danh sách kiểm tra';

  @override
  String get markdownCode => 'Mã';

  @override
  String get markdownLink => 'Liên kết';

  @override
  String get markdownQuote => 'Trích dẫn';

  @override
  String get markdownTabIndentHint =>
      'Tab thụt lề tại đây. Nhấn Esc, rồi nhấn Tab để chuyển đến điều khiển tiếp theo.';

  @override
  String get markdownSupported => 'Hỗ trợ Markdown';

  @override
  String get markdownAttachImages => 'Nhấp để thêm ảnh';

  @override
  String failedToUpdateTitle(String error) {
    return 'Không thể cập nhật tiêu đề: $error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'Không thể cập nhật mô tả: $error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'Không thể cập nhật người review: $error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'Không thể cập nhật người được giao: $error';
  }

  @override
  String failedToUpdateLabels(String error) {
    return 'Không thể cập nhật nhãn: $error';
  }

  @override
  String get discardChangesConfirm => 'Hủy thay đổi của bạn?';

  @override
  String get newPr => 'PR mới';

  @override
  String get openPullRequest => 'Mở pull request';

  @override
  String get composePrSubtitle =>
      'Từ nhánh bạn đã đẩy — không liên quan agent hay phiếu';

  @override
  String get createAsDraft => 'Tạo bản nháp';

  @override
  String get composePrPickBranches =>
      'Chọn nhánh cơ sở và nhánh so sánh để xem trước thay đổi.';

  @override
  String get composePrNothingToCompare =>
      'Không có thay đổi giữa các nhánh này.';

  @override
  String get repository => 'Kho lưu trữ';

  @override
  String get baseBranchLabel => 'Cơ sở';

  @override
  String get compareBranchLabel => 'So sánh';

  @override
  String get selectBranch => 'Chọn nhánh';

  @override
  String get navMeetings => 'Cuộc họp';

  @override
  String get meetingsNoWorkspace => 'Chọn không gian làm việc để xem cuộc họp.';

  @override
  String get meetingsEmpty => 'Chưa có cuộc họp';

  @override
  String get meetingsEmptyHint =>
      'Ghi cuộc họp đầu tiên — âm thanh ở lại trên thiết bị này và agent chuyển thành ghi chú, quyết định và mục hành động.';

  @override
  String get meetingNotesHint =>
      'Ghi chú nhanh — agent sẽ mở rộng sau cuộc họp.';

  @override
  String get meetingSpeakerMe => 'Bạn';

  @override
  String get meetingStatusRecording => 'Đang ghi';

  @override
  String get meetingStatusPaused => 'Tạm dừng';

  @override
  String get meetingStatusProcessing => 'Đang xử lý';

  @override
  String get meetingStatusDone => 'Xong';

  @override
  String get meetingStatusFailed => 'Thất bại';

  @override
  String get meetingsSubtitle =>
      'Ghi và phiên âm trên thiết bị này, rồi được agent tóm tắt.';

  @override
  String get meetingsRecordMeeting => 'Ghi cuộc họp';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count đang xử lý',
      one: '1 đang xử lý',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLiveOpen => 'Mở bản ghi';

  @override
  String get meetingTemplateShort => 'Mẫu';

  @override
  String get meetingsFilterAll => 'Tất cả';

  @override
  String get meetingsFilterDone => 'Xong';

  @override
  String get meetingsFilterProcessing => 'Đang xử lý';

  @override
  String get meetingsSearchHint => 'Lọc theo tiêu đề, người, ứng dụng…';

  @override
  String get meetingsBucketToday => 'Hôm nay';

  @override
  String get meetingsBucketYesterday => 'Hôm qua';

  @override
  String get meetingsBucketEarlierThisWeek => 'Đầu tuần này';

  @override
  String get meetingsBucketLastWeek => 'Tuần trước';

  @override
  String get meetingsBucketOlder => 'Cũ hơn';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count quyết định',
      one: '1 quyết định',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total mục hành động';
  }

  @override
  String get meetingsTranscribing => 'đang phiên âm và tóm tắt…';

  @override
  String get meetingsOpenAction => 'Mở';

  @override
  String get meetingsStopProcessing => 'Dừng';

  @override
  String get meetingsStillTranscribing =>
      'Vẫn đang phiên âm — tóm tắt sẽ hiện khi hoàn tất.';

  @override
  String get meetingsNoMatch => 'Không có cuộc họp khớp';

  @override
  String get meetingsNoMatchHint => 'Thử bộ lọc hoặc từ khóa khác.';

  @override
  String get meetingBackAllMeetings => 'Tất cả cuộc họp';

  @override
  String get meetingReRunSummary => 'Chạy lại tóm tắt';

  @override
  String get meetingExport => 'Xuất';

  @override
  String get meetingAugmentingBanner =>
      'Đang bổ sung ghi chú từ bản ghi — trích xuất quyết định và mục việc…';

  @override
  String get meetingTabNotes => 'Ghi chú';

  @override
  String get meetingTabTranscript => 'Bản ghi';

  @override
  String get meetingTabActionItems => 'Mục việc';

  @override
  String get meetingTabDecisions => 'Quyết định';

  @override
  String get meetingNotesEnhancedToggle => 'Nâng cao';

  @override
  String get meetingNotesYoursToggle => 'Ghi chú của bạn';

  @override
  String get meetingEnhancedByAgent => 'Nâng cao bởi agent · từ bản ghi';

  @override
  String get meetingEnhancedPending => 'Agent vẫn đang xử lý tóm tắt này.';

  @override
  String get meetingNotesEmpty => 'Chưa có ghi chú nâng cao.';

  @override
  String get meetingNotesSavedLocally => 'Đã lưu cục bộ';

  @override
  String get meetingNotesSaving => 'Đang lưu…';

  @override
  String get meetingViewFullTranscript => 'Xem toàn bộ bản ghi';

  @override
  String get meetingTranscriptSearchHint => 'Tìm trong bản ghi…';

  @override
  String get meetingSpeakerEveryone => 'Mọi người';

  @override
  String get meetingSpeakerOthers => 'Người khác';

  @override
  String get meetingTranscriptEmpty => 'Chưa có bản ghi.';

  @override
  String get meetingActionItemsEmpty => 'Chưa trích xuất mục việc.';

  @override
  String get meetingActionItemFrom => 'từ cuộc họp này';

  @override
  String get meetingCreateTicket => 'Tạo phiếu';

  @override
  String meetingTicketCreated(String key) {
    return 'Đã tạo và gửi phiếu $key.';
  }

  @override
  String get meetingTicketFailed => 'Không tạo được phiếu.';

  @override
  String get meetingDecisionsEmpty => 'Chưa ghi nhận quyết định.';

  @override
  String get meetingEditTitle => 'Sửa tiêu đề';

  @override
  String get meetingTitleLabel => 'Tiêu đề';

  @override
  String get meetingAddActionItem => 'Thêm mục việc';

  @override
  String get meetingEditActionItem => 'Sửa mục việc';

  @override
  String get meetingDeleteActionItem => 'Xóa mục việc';

  @override
  String get meetingActionItemContentLabel => 'Mục việc';

  @override
  String get meetingActionItemContentHint => 'Cần làm gì?';

  @override
  String get meetingActionItemOwnerLabel => 'Người phụ trách';

  @override
  String get meetingActionItemOwnerHint =>
      'Ai chịu trách nhiệm? (không bắt buộc)';

  @override
  String get meetingAddDecision => 'Thêm quyết định';

  @override
  String get meetingEditDecision => 'Sửa quyết định';

  @override
  String get meetingDeleteDecision => 'Xóa quyết định';

  @override
  String get meetingDecisionContentLabel => 'Quyết định';

  @override
  String get meetingDecisionContentHint => 'Đã quyết định gì?';

  @override
  String get meetingReRunStarted => 'Đang chạy lại bộ tóm tắt trên bản ghi…';

  @override
  String get meetingReRunNoTranscript => 'Chưa có bản ghi để tóm tắt.';

  @override
  String get meetingNotesEmptyDescription => 'Tạo từ bản ghi, hoặc tự viết.';

  @override
  String get meetingNotesGenerate => 'Tạo ghi chú';

  @override
  String get meetingNotesWriteOwn => 'Tự viết';

  @override
  String get meetingNothingTranscribed =>
      'Không có nội dung nào được chép lời.';

  @override
  String get meetingNothingTranscribedDescription =>
      'Không có bản ghi để tóm tắt, nhưng bạn vẫn có thể giữ ghi chú của riêng mình.';

  @override
  String get meetingOverviewSpeakers => 'Người nói';

  @override
  String get meetingOverviewSpeakersEmpty =>
      'Thời gian nói của từng người sẽ hiển thị khi có bản ghi.';

  @override
  String meetingOverviewMoreSpeakers(int count) {
    return '+$count người khác';
  }

  @override
  String meetingOverviewSpeakerShare(
    String name,
    String share,
    String duration,
  ) {
    return '$name: $share thời gian nói, $duration';
  }

  @override
  String get meetingOverviewActionItemsAllDone =>
      'Đã hoàn thành tất cả mục việc.';

  @override
  String meetingOverviewViewAll(int count) {
    return 'Xem tất cả ($count)';
  }

  @override
  String get meetingExportCopied =>
      'Đã sao chép ghi chú vào clipboard dạng Markdown.';

  @override
  String get meetingExportSaved => 'Đã xuất cuộc họp.';

  @override
  String meetingExportFailed(String error) {
    return 'Xuất thất bại: $error';
  }

  @override
  String get meetingExportNothing => 'Chưa có gì để xuất.';

  @override
  String get meetingPlaybackPlay => 'Phát';

  @override
  String get meetingPlaybackPause => 'Tạm dừng';

  @override
  String get meetingPlaybackUnavailable =>
      'Thiết bị này không phát được âm thanh.';

  @override
  String get meetingDetectedTitle => 'Đã phát hiện cuộc họp';

  @override
  String meetingDetectedSubtitle(String label) {
    return 'Có vẻ “$label” đang diễn ra. Ghi lại?';
  }

  @override
  String get meetingDetectedSubtitleGeneric =>
      'Có vẻ đang có cuộc họp. Ghi lại?';

  @override
  String get meetingDetectedDismiss => 'Bỏ qua';

  @override
  String get meetingAutoStopTitle => 'Cuộc họp có vẻ đã kết thúc. Dừng ghi?';

  @override
  String get meetingAutoStopStop => 'Dừng';

  @override
  String get meetingAutoStopKeep => 'Tiếp tục ghi';

  @override
  String get meetingAutoDetect => 'Tự phát hiện cuộc họp';

  @override
  String get meetingAutoDetectDescription =>
      'Theo dõi lịch và ứng dụng họp trực tuyến rồi đề xuất ghi khi cuộc họp bắt đầu.';

  @override
  String get meetingsRecordingCrumb => 'Đang ghi…';

  @override
  String get meetingRecordTitleHint => 'Tiêu đề cuộc họp';

  @override
  String get meetingRecordTappingLabel => 'Đang thu:';

  @override
  String get meetingRecordMic => 'Mic';

  @override
  String get meetingRecordSystemAudio => 'Âm thanh hệ thống';

  @override
  String get meetingRecordPause => 'Tạm dừng';

  @override
  String get meetingRecordResume => 'Tiếp tục';

  @override
  String get meetingRecordStop => 'Dừng và tóm tắt';

  @override
  String get meetingRecordYourNotes => 'Ghi chú của bạn';

  @override
  String get meetingRecordNotesPlaceholder =>
      'Gõ trong lúc nghe. Vài mảnh ghi chú là đủ — sau khi dừng, agent sẽ mở rộng chúng dựa trên bản ghi lời.';

  @override
  String get meetingRecordLiveTranscript => 'Bản ghi lời trực tiếp';

  @override
  String get meetingRecordDecoding => 'đang giải mã trên thiết bị';

  @override
  String get meetingRecordListening =>
      'Đang nghe… lời nói hiện ở đây sau một hoặc hai giây, gắn nhãn Bạn / Người khác.';

  @override
  String get meetingRecordPausedHint =>
      'Đã tạm dừng — âm thanh bị bỏ qua cho đến khi bạn tiếp tục.';

  @override
  String get meetingRecordNotActive => 'Không có bản ghi đang chạy.';

  @override
  String get meetingHudRecording => 'đang ghi';

  @override
  String get meetingHudPaused => 'tạm dừng';

  @override
  String get meetingHudOpen => 'Mở';

  @override
  String get meetingHudStop => 'Dừng';

  @override
  String get meetingToolbarPopOut => 'Tách cửa sổ';

  @override
  String get meetingToolbarHoldToStop => 'Giữ để dừng ghi';

  @override
  String get meetingToolbarSemanticLabel => 'Thanh công cụ ghi cuộc họp';

  @override
  String get orchestrate => 'Điều phối';

  @override
  String get orchestrationUnavailable => 'Điều phối không khả dụng';

  @override
  String get orchestrationApprove => 'Duyệt kế hoạch';

  @override
  String get orchestrationReject => 'Từ chối';

  @override
  String get orchestrationCancel => 'Hủy điều phối';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count vai trò — $hires tuyển mới';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count phiếu con';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'Chi phí ước tính: \$$amount';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total phiếu con hoàn tất';
  }

  @override
  String get orchestrationStatusProposed => 'Đề xuất';

  @override
  String get orchestrationStatusApproved => 'Đã duyệt';

  @override
  String get orchestrationStatusExecuting => 'Đang thực thi';

  @override
  String get orchestrationStatusSynthesizing => 'Đang tổng hợp';

  @override
  String get orchestrationStatusCompleted => 'Hoàn tất';

  @override
  String get orchestrationStatusFailed => 'Thất bại';

  @override
  String get orchestrationStatusCancelled => 'Đã hủy';

  @override
  String get messageFailed => 'Chạy thất bại';

  @override
  String get turnLimitReached =>
      'Đã dừng ở giới hạn lượt — trả lời để tiếp tục';

  @override
  String get retried => 'Đã thử lại';

  @override
  String replyingTo(String name) {
    return 'đang trả lời $name';
  }

  @override
  String get silenceTimeoutLabel => 'Hết hạn im lặng (phút)';

  @override
  String get silenceTimeoutHint =>
      'vd. 15 — kết thúc lần chạy sau khoảng thời gian này nếu không có đầu ra';

  @override
  String get capabilityJsonMode => 'Chế độ JSON';

  @override
  String get capabilityModelSelection => 'Chọn mô hình';

  @override
  String get transcriptThinking => 'Đang suy nghĩ…';

  @override
  String transcriptThoughtFor(String duration) {
    return 'Đã suy nghĩ $duration';
  }

  @override
  String get transcriptStatusMakingEdits => 'Đang chỉnh sửa…';

  @override
  String get transcriptStatusReadingFiles => 'Đang đọc tệp…';

  @override
  String get transcriptStatusSearching => 'Đang tìm trong mã nguồn…';

  @override
  String get transcriptStatusRunningCommands => 'Đang chạy lệnh…';

  @override
  String get transcriptStatusResponding => 'Đang trả lời…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return 'Đang chạy $tool…';
  }

  @override
  String get transcriptInput => 'Đầu vào';

  @override
  String get transcriptOutput => 'Đầu ra';

  @override
  String get transcriptErrorLabel => 'Lỗi';

  @override
  String get transcriptSandboxBlocked => 'Sandbox đã chặn một thao tác';

  @override
  String transcriptShowFullOutput(int kb) {
    return 'Hiện toàn bộ đầu ra (+$kb KB)';
  }

  @override
  String transcriptShowAllLines(int count) {
    return 'Hiện tất cả $count dòng';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return 'Đang hiện $count dòng đầu';
  }

  @override
  String get transcriptGrepNoMatches => 'Không có kết quả';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '$matches kết quả',
      one: '1 kết quả',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files tệp',
      one: '1 tệp',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return 'Người $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => 'Đổi tên người nói';

  @override
  String get meetingRenameSpeakerTitle => 'Đổi tên người nói';

  @override
  String get meetingSpeakerNameLabel => 'Tên';

  @override
  String get meetingSpeakerSuggestFromCalendar => 'Từ khách mời cuộc họp này';

  @override
  String get meetingRenameSpeakerApplyAll =>
      'Áp dụng cho mọi đoạn của người nói này';

  @override
  String get meetingRenameSpeakerScopeHint =>
      'Khi tắt, chỉ đổi tên dòng đã chọn.';

  @override
  String get meetingLinkEvent => 'Liên kết sự kiện';

  @override
  String get meetingChangeEvent => 'Đổi sự kiện';

  @override
  String get meetingLinkEventTitle => 'Liên kết với sự kiện lịch';

  @override
  String get meetingLinkEventSearchHint => 'Tìm sự kiện';

  @override
  String get meetingLinkEventEmpty => 'Không có sự kiện lịch gần đây';

  @override
  String get meetingUnlinkEvent => 'Gỡ liên kết';

  @override
  String get calendarLinkExistingMeeting => 'Liên kết cuộc họp có sẵn';

  @override
  String get calendarLinkMeetingTitle => 'Liên kết cuộc họp';

  @override
  String get calendarLinkMeetingSearchHint => 'Tìm cuộc họp';

  @override
  String get calendarLinkMeetingEmpty => 'Không có cuộc họp để liên kết';

  @override
  String get meetingRenameSpeakerFailed => 'Không đổi được tên người nói';

  @override
  String get calendarLinkUpdateFailed => 'Không cập nhật được liên kết lịch';

  @override
  String get rename => 'Đổi tên';

  @override
  String get notNow => 'Để sau';

  @override
  String get meetingSaveVoiceProfileTitle => 'Lưu hồ sơ giọng nói?';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return 'Nhận diện $name tự động trong các cuộc họp sau bằng cách lưu dấu giọng của họ.';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return 'Đã lưu hồ sơ giọng nói cho $name';
  }

  @override
  String get meetingVoiceProfileSaveFailed => 'Không lưu được hồ sơ giọng nói';

  @override
  String get voiceProfilesSection => 'Hồ sơ giọng nói';

  @override
  String get voiceProfilesDescription =>
      'Giọng đã lưu được nhận diện tự động trong các cuộc họp sau.';

  @override
  String get voiceProfilesEmpty =>
      'Chưa có giọng đã lưu. Đặt tên người nói trong bản ghi cuộc họp, rồi chọn \"Lưu hồ sơ giọng nói\".';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mẫu',
      one: '1 mẫu',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => 'Đổi tên hồ sơ giọng nói';

  @override
  String get deleteVoiceProfileTitle => 'Xóa hồ sơ giọng nói?';

  @override
  String deleteVoiceProfileBody(String name) {
    return 'Ngừng nhận diện $name? Dấu giọng đã lưu sẽ bị xóa. Tên đã áp dụng trong các cuộc họp trước vẫn được giữ.';
  }

  @override
  String get connectedLabel => 'Đã kết nối';

  @override
  String get ideTabGeneral => 'Chung';

  @override
  String get ideTabExplorer => 'Trình khám phá';

  @override
  String get ideTabSourceControl => 'Kiểm soát mã nguồn';

  @override
  String get generalSectionTodos => 'Việc cần làm';

  @override
  String get generalSectionGoals => 'Mục tiêu';

  @override
  String get goalRunStatusActive => 'Đang chạy';

  @override
  String get goalRunStatusPaused => 'Tạm dừng';

  @override
  String get goalRunStatusCompleted => 'Hoàn tất';

  @override
  String get goalRunStatusFailed => 'Thất bại';

  @override
  String get goalRunStatusCancelled => 'Đã hủy';

  @override
  String get goalRunStatusBudgetExhausted => 'Hết ngân sách';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return 'Lần chạy $run trên $max · $cost trên $cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return 'Lần chạy $run · $cost trên $cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return 'Hạn $deadline';
  }

  @override
  String get goalRunPause => 'Tạm dừng mục tiêu';

  @override
  String get goalRunResume => 'Tiếp tục mục tiêu';

  @override
  String goalRunResumeRaise(String cap) {
    return 'Tiếp tục · tăng hạn mức lên $cap';
  }

  @override
  String get goalRunStop => 'Dừng mục tiêu';

  @override
  String get generalSectionAgents => 'Agent';

  @override
  String get generalSectionTerminals => 'Terminal';

  @override
  String get generalTodosEmpty => 'Chưa có việc cần làm';

  @override
  String get generalAgentsEmpty => 'Không có agent nào đang chạy';

  @override
  String get generalTerminalsEmpty => 'Không có terminal nào đang mở';

  @override
  String get generalSectionBrowsers => 'Trình duyệt';

  @override
  String get generalSectionComputers => 'Máy tính';

  @override
  String get generalBrowsersEmpty => 'Không có trình duyệt nào đang mở';

  @override
  String get generalComputersEmpty => 'Không có máy tính nào đang mở';

  @override
  String get generalSectionPhones => 'Điện thoại';

  @override
  String get generalPhonesEmpty => 'Không có điện thoại nào đang mở';

  @override
  String get pauseAgent => 'Tạm dừng agent';

  @override
  String get resumeAgent => 'Tiếp tục agent';

  @override
  String get agentCannotPause => 'Không thể tạm dừng agent này — hãy dừng hẳn.';

  @override
  String get goalClear => 'Xóa mục tiêu';

  @override
  String get undoLabelGoalClear => 'xóa mục tiêu';

  @override
  String get todoStatusPending => 'Chưa bắt đầu';

  @override
  String get todoStatusInProgress => 'Đang làm';

  @override
  String get todoStatusCompleted => 'Xong';

  @override
  String get reorderTodo => 'Sắp xếp lại todo';

  @override
  String get focusTerminal => 'Tập trung terminal';

  @override
  String get focusMachine => 'Tập trung máy';

  @override
  String get focusBrowser => 'Tập trung trình duyệt';

  @override
  String get todoEditorTitle => 'Sửa todo';

  @override
  String get todoEditorHint =>
      'Mỗi dòng một mục. Dùng - [ ] cho chưa bắt đầu, - [~] cho đang làm, - [x] cho xong.';

  @override
  String get todoNeedsText => 'Thêm nội dung sau lệnh';

  @override
  String get todoNotFound => 'Không tìm thấy todo khớp';

  @override
  String get todoCleared => 'Đã xóa danh sách todo';

  @override
  String get todoNothingToCopy => 'Không có gì để sao chép';

  @override
  String todoAdded(String content) {
    return 'Đã thêm \"$content\"';
  }

  @override
  String todoStarted(String content) {
    return 'Đã bắt đầu \"$content\"';
  }

  @override
  String todoCompleted(String content) {
    return 'Đã hoàn thành \"$content\"';
  }

  @override
  String todoRemoved(String content) {
    return 'Đã xóa \"$content\"';
  }

  @override
  String todoCopied(int count) {
    return 'Đã sao chép $count mục';
  }

  @override
  String todoImported(int count) {
    return 'Đã nhập $count mục';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return 'Lệnh todo không xác định \"$name\"';
  }

  @override
  String get terminal => 'Terminal';

  @override
  String get ideCloseTab => 'Đóng tab';

  @override
  String get ideSplitEditor => 'Chia trình soạn thảo';

  @override
  String get ideSplitRight => 'Chia sang phải';

  @override
  String get ideSplitDown => 'Chia xuống dưới';

  @override
  String get ideSplitLeft => 'Chia sang trái';

  @override
  String get ideSplitUp => 'Chia lên trên';

  @override
  String get ideCloseGroup => 'Đóng nhóm';

  @override
  String get ideCloseOthers => 'Đóng các tab khác';

  @override
  String get ideCloseToRight => 'Đóng các tab bên phải';

  @override
  String get ideCloseSaved => 'Đóng tab đã lưu';

  @override
  String get ideCloseAll => 'Đóng tất cả';

  @override
  String get ideSplit => 'Chia';

  @override
  String get ideToggleSidebar => 'Bật/tắt thanh bên';

  @override
  String get ideNewTab => 'Mở trình soạn thảo';

  @override
  String get ideNewTabMenu => 'Tab mới';

  @override
  String get ideReviewCode => 'Review mã';

  @override
  String ideReviewCodeInRepo(String repo) {
    return 'Review mã ($repo)';
  }

  @override
  String get ideRevertConfirmTitle => 'Hoàn nguyên thay đổi';

  @override
  String get ideRevertUntracked => 'Không thể hoàn nguyên tệp chưa theo dõi';

  @override
  String get ideRevertFailed =>
      'Không hoàn nguyên được các tệp. Cây làm việc của cuộc hội thoại có thể không khả dụng.';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tệp',
      one: '1 tệp',
    );
    return '$_temp0 không hoàn nguyên được (chưa theo dõi).';
  }

  @override
  String get ideSearchMatchCase => 'Phân biệt hoa/thường';

  @override
  String get ideSearchWholeWord => 'Cả từ';

  @override
  String get ideSearchRegex => 'Regex';

  @override
  String get ideSearchFilters => 'Bộ lọc tìm kiếm';

  @override
  String get ideSearchFilesToInclude => 'Tệp cần gồm';

  @override
  String get ideSearchFilesToExclude => 'Tệp cần loại trừ';

  @override
  String get ideNoOpenTabs => 'Không có tab đang mở — dùng + để mở';

  @override
  String get ideBrowserAddressHint => 'Nhập địa chỉ hoặc tìm kiếm';

  @override
  String get ideSimpleWebBrowser => 'Trình duyệt web đơn giản';

  @override
  String get ideWebBrowser => 'Trình duyệt web';

  @override
  String get ideBrowserEnterUrl =>
      'Nhập URL vào thanh địa chỉ để bắt đầu duyệt';

  @override
  String get ideCodeServer => 'Trình soạn thảo';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return 'Lưu thay đổi vào $fileName?';
  }

  @override
  String get ideUnsavedChangesBody => 'Thay đổi sẽ bị mất nếu bạn không lưu.';

  @override
  String get ideDontSave => 'Không lưu';

  @override
  String get editorAutoSave => 'Tự động lưu';

  @override
  String get editorAutoSaveDescription =>
      'Tự động lưu thay đổi trong trình soạn thảo nhúng.';

  @override
  String get editorAutoSaveOff => 'Tắt';

  @override
  String get editorAutoSaveAfterDelay => 'Sau một khoảng trễ';

  @override
  String get editorAutoSaveOnFocusChange => 'Khi đổi tiêu điểm';

  @override
  String get ideCodeServerUnavailable =>
      'Code-server không khả dụng trên máy chủ này';

  @override
  String get ideCodeServerUnavailableHint =>
      'Cài code-server (coder/code-server) trên máy chủ, rồi mở lại trình soạn thảo.';

  @override
  String get ideCodeServerInstalling => 'Đang chuẩn bị trình soạn thảo…';

  @override
  String get ideCodeServerOpenInBrowser =>
      'Mở trình soạn thảo trong trình duyệt';

  @override
  String get ideCodeServerError => 'Không mở được trình soạn thảo';

  @override
  String get paneSuspendedCaption =>
      'Tạm dừng để tiết kiệm tài nguyên — sẽ tải lại khi được tiêu điểm';

  @override
  String get ideFolderLoadFailed => 'Không tải được thư mục này';

  @override
  String get ideFileSearchFailed => 'Không tìm được tệp';

  @override
  String get ideSearchInFiles => 'Tìm trong tệp';

  @override
  String get ideNoContentMatches => 'Không có kết quả khớp';

  @override
  String get ideSourceControlCreatePr => 'Create pull request';

  @override
  String get ideSourceControlNoChanges => 'Không có thay đổi';

  @override
  String get noReposInConversation =>
      'Không có kho lưu trữ trong cuộc trò chuyện này';

  @override
  String get ideSourceControlNoSpace =>
      'Mở một cuộc trò chuyện để xem thay đổi của nó';

  @override
  String get ideFileLoading => 'Đang tải…';

  @override
  String get ideFileBinary => 'Tệp nhị phân';

  @override
  String get mcpApprovalMode => 'Phê duyệt công cụ';

  @override
  String get mcpApprovalModeDescription =>
      'Hành động nào của các công cụ riêng của Control Center, được gọi qua endpoint MCP hoặc bởi agent, sẽ chạy mà không hỏi. Thao tác đọc luôn được phép; các cấp cao hơn sẽ hỏi. Máy chủ bên trong một lần chạy tuân theo chính sách hành động của lần chạy đó.';

  @override
  String get mcpApprovalAlwaysAsk => 'Luôn hỏi';

  @override
  String get mcpApprovalWrite => 'Tự phê duyệt ghi';

  @override
  String get mcpApprovalYolo => 'Tự phê duyệt tất cả';

  @override
  String get mcpReconnect => 'Kết nối lại';

  @override
  String get mcpStatusConnected => 'Đã kết nối';

  @override
  String get mcpStatusConnecting => 'Đang kết nối…';

  @override
  String get mcpStatusNeedsAuth => 'Cần ủy quyền';

  @override
  String get mcpStatusFailed => 'Thất bại';

  @override
  String get mcpStatusCircuitOpen => 'Tạm dừng';

  @override
  String get mcpStatusDisabled => 'Đã tắt';

  @override
  String get providersAndModels => 'Nhà cung cấp & mô hình';

  @override
  String get providersAndModelsDescription =>
      'Liệt kê mọi nhà cung cấp agent tích hợp có thể dùng — đặt khóa API hoặc đăng nhập bằng trình duyệt, xem mô hình và giá của từng nhà cung cấp đã kết nối, và quản lý nhà cung cấp nào không gian làm việc này được dùng.';

  @override
  String get syncNow => 'Đồng bộ ngay';

  @override
  String syncNowResult(int applied, int failed) {
    return 'Đồng bộ xong — $applied đã áp dụng, $failed thất bại';
  }

  @override
  String syncNowFailed(String error) {
    return 'Đồng bộ thất bại: $error';
  }

  @override
  String get denied => 'Từ chối';

  @override
  String get allowed => 'Cho phép';

  @override
  String allowProviderSemantic(String provider) {
    return 'Cho phép $provider';
  }

  @override
  String enabledViaEnv(String key) {
    return 'Bật qua $key';
  }

  @override
  String costPerMillion(String input, String output) {
    return '$input / $output mỗi 1M';
  }

  @override
  String contextTokens(String tokens) {
    return '$tokens ngữ cảnh';
  }

  @override
  String get subscriptionUsage => 'Sử dụng gói đăng ký';

  @override
  String get subscriptionUsageUnavailable => 'Không khả dụng';

  @override
  String get subscriptionUsageExhausted => 'Hết hạn mức';

  @override
  String get subscriptionUsageSignInRequired => 'Đăng nhập lại';

  @override
  String get subscriptionUsageSignInExpired =>
      'Phiên đăng nhập hết hạn, gia hạn khi chạy lần sau';

  @override
  String subscriptionUsagePercentUsed(int percent) {
    return 'Đã dùng $percent%';
  }

  @override
  String resetsIn(String duration) {
    return 'Đặt lại sau $duration';
  }

  @override
  String get feedbackHelpful => 'Điều này hữu ích';

  @override
  String get feedbackNotHelpful => 'Điều này không hữu ích';

  @override
  String get modeChat => 'Trò chuyện';

  @override
  String get modePlan => 'Kế hoạch';

  @override
  String get modeReview => 'Rà soát';

  @override
  String get modeOrchestrate => 'Điều phối';

  @override
  String get editorTheme => 'Chủ đề trình soạn thảo';

  @override
  String get editorThemeDescription =>
      'Nhập chủ đề màu VS Code để diff và trình soạn thảo nhúng khớp với IDE của bạn.';

  @override
  String get editorThemePasteHint => 'Dán nội dung tệp JSON chủ đề màu VS Code';

  @override
  String get editorThemeImported => 'Đã nhập chủ đề';

  @override
  String get editorThemeInvalid => 'Đây không giống chủ đề VS Code hợp lệ';

  @override
  String get importTheme => 'Nhập chủ đề';

  @override
  String get clearTheme => 'Xóa chủ đề';

  @override
  String get openInDiffViewer => 'Mở trong trình xem diff';

  @override
  String get shellCommand => 'Lệnh';

  @override
  String get shellOutput => 'Đầu ra';

  @override
  String get revertToHere => 'Hoàn nguyên về đây';

  @override
  String get revertConfirmBody =>
      'Ẩn các tin nhắn sau điểm này và hoàn nguyên thay đổi tệp của agent về lượt này? Bạn có thể hoàn tác.';

  @override
  String get revert => 'Hoàn nguyên';

  @override
  String get revertedToHere => 'Đã hoàn nguyên về đây';

  @override
  String get nothingToRevert => 'Không có gì để hoàn nguyên';

  @override
  String get undoRevert => 'Hoàn tác hoàn nguyên';

  @override
  String get revertUndone => 'Đã hoàn tác hoàn nguyên';

  @override
  String get systemBehavior => 'Hành vi hệ thống';

  @override
  String get keepAwakeTitle => 'Giữ máy tính thức khi agent chạy';

  @override
  String get keepAwakeOnSubtitle =>
      'Máy tính sẽ không ngủ khi agent đang làm việc';

  @override
  String get keepAwakeOffSubtitle =>
      'Máy tính vẫn có thể ngủ khi agent đang làm việc';

  @override
  String get spaces => 'Không gian';

  @override
  String get spacesHomeDescription =>
      'Chọn một không gian trong danh sách, hoặc tạo mới.';

  @override
  String get noSpacesYet => 'Chưa có không gian nào';

  @override
  String get newSpace => 'Không gian mới';

  @override
  String get spaceName => 'Tên không gian';

  @override
  String get spaceReposHint => 'Repo cần đưa vào';

  @override
  String get newSpaceFolder => 'Thư mục mới';

  @override
  String get folderName => 'Tên thư mục';

  @override
  String get renameSpaceFolder => 'Đổi tên thư mục';

  @override
  String get deleteSpaceFolder => 'Xóa thư mục';

  @override
  String get moveSpaceToFolder => 'Chuyển vào thư mục';

  @override
  String get removeSpaceFromFolder => 'Xóa khỏi thư mục';

  @override
  String get spaceFolderActions => 'Thao tác với thư mục';

  @override
  String get deleteFolderWithSpacesWarning =>
      'Xóa vĩnh viễn các không gian sẽ xóa tin nhắn và thư mục làm việc của chúng đối với tất cả mọi người. Không thể hoàn tác.';

  @override
  String get deleteSpacesInFolder =>
      'Xóa vĩnh viễn các không gian trong thư mục này';

  @override
  String get deleteFolderAndSpaces => 'Xóa thư mục và không gian';

  @override
  String get keepSpacesInFolder =>
      'Nếu không, các không gian sẽ không thuộc thư mục nào.';

  @override
  String get noSpaceFoldersYet => 'Chưa có thư mục nào';

  @override
  String get ideSourceControl => 'Quản lý mã nguồn';

  @override
  String get stagedChanges => 'Thay đổi đã lưu tạm';

  @override
  String get changes => 'Thay đổi';

  @override
  String get stageFile => 'Lưu tạm';

  @override
  String get unstageFile => 'Bỏ lưu tạm';

  @override
  String get stageAll => 'Stage tất cả thay đổi';

  @override
  String get unstageAll => 'Unstage tất cả';

  @override
  String get stageChangesToCommit => 'Stage thay đổi để commit';

  @override
  String get syncToPrHead => 'Kéo các commit PR mới nhất';

  @override
  String get syncedToPrHead => 'Đã đồng bộ với các commit PR mới nhất';

  @override
  String get syncPrHeadDirty => 'Commit hoặc hủy thay đổi trước khi đồng bộ';

  @override
  String get syncPrHeadFailed => 'Không thể đồng bộ với đầu PR';

  @override
  String get spaceLabel => 'Không gian';

  @override
  String get keybindingNewSpace => 'Không gian mới';

  @override
  String get jumpToLatest => 'Chuyển tới mới nhất';

  @override
  String get streaming => 'Đang truyền';

  @override
  String get newMessages => 'Mới';

  @override
  String get copyLink => 'Sao chép liên kết';

  @override
  String get linkCopied => 'Đã sao chép liên kết';

  @override
  String get agentResponding => 'Agent đang phản hồi';

  @override
  String get agentFinished => 'Agent đã xong';

  @override
  String get harnessConnectProviderForModels =>
      'Kết nối nhà cung cấp để xem mô hình.';

  @override
  String get providerSignOut => 'Đăng xuất';

  @override
  String get providerWaitingForDeviceCode =>
      'Đang chờ bạn xác nhận mã trên trình duyệt…';

  @override
  String get providerDeviceCodeHint =>
      'Kiểm tra mã này khớp với mã trên trình duyệt, rồi phê duyệt.';

  @override
  String get providerPlanUsageLoading => 'Đang kiểm tra mức dùng gói…';

  @override
  String get providerPlanUsageUnavailable => 'Gói này không báo cáo mức dùng.';

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return 'Xóa khóa API $provider?';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return 'Khóa đã lưu sẽ bị xóa và không thể hiện lại. Các agent dùng mô hình $provider sẽ ngừng hoạt động cho đến khi bạn dán khóa mới.';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return 'Xóa $provider?';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return 'Nhà cung cấp và khóa đã lưu sẽ bị xóa. Các agent gắn với mô hình của nó sẽ ngừng hoạt động.';
  }

  @override
  String get providerApiKeyHint => 'Dán khóa API';

  @override
  String get providerApiKeyStoredHint => 'Dán khóa API khác để thêm';

  @override
  String get providerAddAnotherAccount => 'Thêm tài khoản khác';

  @override
  String get providerActiveBadge => 'Đang dùng';

  @override
  String get providerSignInExpired => 'Đăng nhập đã hết hạn';

  @override
  String get providerOauthAccountFallback => 'Tài khoản OAuth';

  @override
  String get providerApiKeyFallback => 'Khóa API';

  @override
  String get providerRemoveCredentialConfirmTitle =>
      'Xóa thông tin xác thực này?';

  @override
  String get providerSignOutAccountConfirmTitle => 'Đăng xuất tài khoản này?';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return 'Các agent dùng $provider sẽ chuyển sang khóa và tài khoản khác. Nếu không còn, chúng ngừng cho đến khi bạn thêm một cái.';
  }

  @override
  String get providerBaseUrlHint => 'URL gốc (tùy chọn)';

  @override
  String get addProvider => 'Thêm nhà cung cấp';

  @override
  String get noCustomProviders => 'Chưa có nhà cung cấp tùy chỉnh.';

  @override
  String get providerNameLabel => 'Tên';

  @override
  String get apiTypeLabel => 'Loại API';

  @override
  String get providerBaseUrlLabel => 'URL gốc';

  @override
  String get providerApiKeyOptionalHint => 'Khóa API (tùy chọn)';

  @override
  String get dialectOpenAiCompatible => 'Tương thích OpenAI';

  @override
  String get dialectAnthropicCompatible => 'Tương thích Anthropic';

  @override
  String get removeProviderTooltip => 'Xóa nhà cung cấp';

  @override
  String get providerLogInWithBrowser => 'Đăng nhập bằng trình duyệt';

  @override
  String providerLoginDialogTitle(String provider) {
    return 'Đăng nhập vào $provider';
  }

  @override
  String get providerLabel => 'Nhà cung cấp';

  @override
  String get selectProviderToLogin => 'Chọn nhà cung cấp để đăng nhập';

  @override
  String providerLoginFailed(String error) {
    return 'Đăng nhập thất bại: $error';
  }

  @override
  String get providerWaitingForBrowser =>
      'Đang chờ bạn ủy quyền trên trình duyệt…';

  @override
  String get providerPasteCodeHint => 'Hoặc dán mã từ trình duyệt';

  @override
  String get providerCompleteLogin => 'Hoàn tất';

  @override
  String get providerConnectedApiKey => 'Đã kết nối qua khóa API';

  @override
  String get providerConnectedOauth => 'Đã kết nối';

  @override
  String providerConnectedAccount(String account) {
    return 'Đã kết nối · $account';
  }

  @override
  String get providerLocalReady => 'Cục bộ · sẵn sàng';

  @override
  String get providerNotConnected => 'Chưa kết nối';

  @override
  String get preparingWorkspace => 'Đang chuẩn bị không gian làm việc…';

  @override
  String provisioningRunningTasks(String repo) {
    return 'Đang chạy tác vụ worktree cho $repo…';
  }

  @override
  String provisioningCloningRepo(String repo) {
    return 'Đang clone $repo…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return 'Đang checkout pull request trong $repo…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return 'Đang thiết lập agent $agent…';
  }

  @override
  String get workspacePrepFailed => 'Thiết lập không gian làm việc thất bại';

  @override
  String get workspacePrepStopped => 'Đã dừng thiết lập không gian làm việc';

  @override
  String get stopWorkspacePrep => 'Dừng chuẩn bị';

  @override
  String get stopWorkspacePrepTooltip =>
      'Dừng chuẩn bị không gian làm việc này';

  @override
  String get stopWorkspacePrepConfirm =>
      'Dừng chuẩn bị không gian làm việc này? Bản clone đang chạy sẽ bị hủy — bạn có thể bắt đầu lại từ đây.';

  @override
  String messageWillSendWhenReady(int count) {
    return '$count tin nhắn sẽ gửi khi sẵn sàng';
  }

  @override
  String get membersNav => 'Thành viên';

  @override
  String get membersSettingsDescription =>
      'Người có quyền truy cập không gian làm việc này: danh sách, lời mời và nhật ký kiểm tra';

  @override
  String get memberRosterLabel => 'Danh sách thành viên';

  @override
  String get memberRepoAccessAction => 'Quyền truy cập repo';

  @override
  String memberRepoAccessTitle(String name) {
    return 'Quyền truy cập repo của $name';
  }

  @override
  String get roleOwner => 'Chủ sở hữu';

  @override
  String get roleAdmin => 'Quản trị viên';

  @override
  String get roleMember => 'Thành viên';

  @override
  String get roleViewer => 'Người xem';

  @override
  String get roleGuest => 'Khách';

  @override
  String get removeMemberTitle => 'Gỡ thành viên';

  @override
  String removeMemberConfirm(String name) {
    return 'Gỡ $name khỏi không gian làm việc này? Họ sẽ mất quyền truy cập ngay.';
  }

  @override
  String get transferOwnershipAction => 'Chuyển quyền sở hữu';

  @override
  String get transferOwnershipTitle => 'Chuyển quyền sở hữu';

  @override
  String transferOwnershipConfirm(String name) {
    return 'Đặt $name làm chủ sở hữu không gian làm việc này? Bạn sẽ trở thành quản trị viên. Chỉ chủ sở hữu mới xóa được không gian làm việc hoặc đổi vai trò của quản trị viên khác.';
  }

  @override
  String get transferOwnershipCta => 'Chuyển';

  @override
  String get auditTrailLabel => 'Nhật ký kiểm tra ủy quyền';

  @override
  String get auditTrailDescription =>
      'Mọi lần cho phép và từ chối, nối chuỗi hash để phát hiện mục bị sửa hoặc xóa.';

  @override
  String get auditVerifyChain => 'Xác minh chuỗi';

  @override
  String auditChainIntact(int count) {
    return 'Chuỗi nguyên vẹn — đã xác minh $count mục';
  }

  @override
  String auditChainBroken(int seq, String reason) {
    return 'Chuỗi đứt tại mục $seq: $reason';
  }

  @override
  String get auditEmpty => 'Chưa ghi nhận quyết định nào.';

  @override
  String get auditDenied => 'Từ chối';

  @override
  String get auditAllowed => 'Cho phép';

  @override
  String auditOnBehalfOf(String user) {
    return 'cho $user';
  }

  @override
  String get policyTemplatesLabel => 'Mẫu chính sách';

  @override
  String get policyTemplatesDescription =>
      'Áp dụng tư thế khởi đầu, hoặc chuyển giữa các không gian làm việc.';

  @override
  String get policyTemplateStrict => 'Nghiêm ngặt';

  @override
  String get policyTemplateBalanced => 'Cân bằng';

  @override
  String get policyTemplatePermissive => 'Thoáng';

  @override
  String get policyTemplateApply => 'Áp dụng';

  @override
  String policyTemplateApplied(int count) {
    return 'Đã áp dụng $count quy tắc';
  }

  @override
  String get policyExport => 'Sao chép chính sách';

  @override
  String get policyExported => 'Đã sao chép chính sách vào clipboard';

  @override
  String get policyImport => 'Dán chính sách';

  @override
  String policyImported(int count) {
    return 'Đã nhập $count quy tắc';
  }

  @override
  String get approveAndRemember => 'Phê duyệt trong 8 giờ';

  @override
  String get approveAndRememberTooltip =>
      'Phê duyệt thao tác này và không hỏi lại các thao tác tương tự trong không gian này trong 8 giờ. Tự hết hạn.';

  @override
  String get unknownUserLabel => 'Người dùng không xác định';

  @override
  String get inviteMember => 'Mời thành viên';

  @override
  String get inviteRepoAccessHeader => 'Quyền truy cập kho';

  @override
  String get inviteRepoAccessExplainer =>
      'Chỉ các kho bạn chọn mới được chia sẻ với người được mời, ở mức bạn chọn. Mọi thứ khác vẫn ẩn.';

  @override
  String get grantLevelRead => 'Đọc';

  @override
  String get grantLevelReview => 'Xem xét';

  @override
  String get grantLevelWrite => 'Ghi';

  @override
  String get inviteExpiryLabel => 'Hết hạn sau';

  @override
  String get expiryOneDay => '1 ngày';

  @override
  String get expirySevenDays => '7 ngày';

  @override
  String get expiryThirtyDays => '30 ngày';

  @override
  String get createInviteAction => 'Tạo lời mời';

  @override
  String get inviteOneTimeCodeLabel => 'Mã dùng một lần';

  @override
  String get inviteCodeShownOnce =>
      'Mã này chỉ hiện một lần — hãy sao chép ngay.';

  @override
  String get inviteLinkLabel => 'Liên kết mời';

  @override
  String get inviteRedeemHint =>
      'Gửi mã cho người được mời; họ đổi mã tại URL máy chủ của bạn.';

  @override
  String get inviteScanQr => 'Hoặc quét để đổi mã';

  @override
  String get inviteLoopbackWarningTitle => 'Lời mời trỏ tới địa chỉ local';

  @override
  String get inviteLoopbackWarningBody =>
      'Cộng tác viên trên máy khác sẽ không truy cập được máy chủ này. Hãy tạo tunnel (Cài đặt → Tích hợp → Chia sẻ máy chủ này) hoặc bind vào mạng của bạn để người dùng ngoài máy có thể kết nối.';

  @override
  String get inviteStatusOpen => 'Mở';

  @override
  String get inviteStatusUsed => 'Đã dùng';

  @override
  String get inviteStatusRevoked => 'Đã thu hồi';

  @override
  String get inviteStatusExpired => 'Đã hết hạn';

  @override
  String inviteCreatedTime(String time) {
    return 'Tạo $time';
  }

  @override
  String inviteExpiresOn(String date) {
    return 'hết hạn $date';
  }

  @override
  String get noActivityYet => 'Chưa có hoạt động';

  @override
  String get couldNotLoadMembers => 'Không tải được thành viên';

  @override
  String get couldNotLoadInvites => 'Không tải được lời mời';

  @override
  String get couldNotLoadActivity => 'Không tải được hoạt động';

  @override
  String get yourDevices => 'Thiết bị của bạn';

  @override
  String get yourDevicesDescription =>
      'Client đã ghép với tài khoản của bạn trên máy chủ này.';

  @override
  String get noOwnDevices =>
      'Chưa có thiết bị nào được ghép với tài khoản của bạn';

  @override
  String get renameDeviceTitle => 'Đổi tên thiết bị';

  @override
  String get revokeDeviceTitle => 'Thu hồi thiết bị';

  @override
  String revokeDeviceConfirm(String label) {
    return 'Thu hồi $label? Thiết bị sẽ bị ngắt ngay và không còn truy cập được máy chủ này.';
  }

  @override
  String devicePairedTime(String time) {
    return 'Ghép $time';
  }

  @override
  String deviceLastSeenTime(String time) {
    return 'Lần cuối $time';
  }

  @override
  String get deviceNeverSeen => 'Chưa từng kết nối';

  @override
  String get deviceAwaitingApproval => 'Đang chờ phê duyệt';

  @override
  String get profileSectionLabel => 'Hồ sơ';

  @override
  String get profileSectionDescription =>
      'Bạn hiện ra với nhóm và trong tác giả commit git thế nào trong không gian này. Trường trống kế thừa tên và email tài khoản.';

  @override
  String get displayNameLabel => 'Tên hiển thị';

  @override
  String get emailLabel => 'Email';

  @override
  String get gitAuthorNameLabel => 'Tên tác giả Git';

  @override
  String get gitAuthorEmailLabel => 'Email tác giả Git';

  @override
  String get profileSaved => 'Đã lưu hồ sơ';

  @override
  String get presenceOnline => 'Trực tuyến';

  @override
  String get presenceIdle => 'Không hoạt động';

  @override
  String get presenceTyping => 'Đang nhập…';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String get presenceRailLabel => 'Ai đang trực tuyến';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => 'Bật không làm phiền';

  @override
  String get dndTooltipOff => 'Tắt không làm phiền';

  @override
  String get startPresenting => 'Bắt đầu trình bày';

  @override
  String get stopPresenting => 'Dừng trình bày';

  @override
  String spotlightPresentingBanner(String name) {
    return '$name đang trình bày';
  }

  @override
  String get spotlightLeave => 'Rời';

  @override
  String typingIndicator(String name) {
    return '$name đang nhập…';
  }

  @override
  String get ideTabNotes => 'Ghi chú';

  @override
  String get ideSidebarAllViews => 'Tất cả chế độ xem';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return 'Tất cả chế độ xem ($count đã ẩn)';
  }

  @override
  String get ideSidebarPinView => 'Ghim vào thanh bên';

  @override
  String get ideSidebarUnpinView => 'Bỏ ghim khỏi thanh bên';

  @override
  String get notesEmptyHint =>
      'Thêm ghi chú cho ai tiếp nhận cuộc hội thoại này…';

  @override
  String get notesEditTooltip => 'Sửa ghi chú';

  @override
  String notesUpdatedBy(String name, String time) {
    return 'Cập nhật bởi $name · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '$name đang chỉnh sửa';
  }

  @override
  String get notesSaveFailed => 'Không lưu được ghi chú';

  @override
  String get reactionAddTooltip => 'Thêm biểu cảm';

  @override
  String reactionToggleTooltip(String emoji) {
    return 'Bày tỏ bằng $emoji';
  }

  @override
  String get reactionThumbsUp => 'Thích';

  @override
  String get reactionThumbsDown => 'Không thích';

  @override
  String get reactionLaugh => 'Cười';

  @override
  String get reactionHooray => 'Hoan hô';

  @override
  String get reactionConfused => 'Bối rối';

  @override
  String get reactionHeart => 'Trái tim';

  @override
  String get reactionRocket => 'Tên lửa';

  @override
  String get reactionEyes => 'Mắt';

  @override
  String get commentReact => 'Thả cảm xúc';

  @override
  String get commentResolveThread => 'Giải quyết chuỗi';

  @override
  String get commentReopenThread => 'Mở lại chuỗi';

  @override
  String get commentCopyLink => 'Sao chép liên kết tới bình luận';

  @override
  String get commentCopyMarkdown => 'Sao chép dưới dạng Markdown';

  @override
  String get commentCopyThreadMarkdown => 'Sao chép chuỗi dưới dạng Markdown';

  @override
  String get commentCopyPrompt => 'Sao chép dưới dạng prompt';

  @override
  String get commentCopyThreadPrompt => 'Sao chép chuỗi dưới dạng prompt';

  @override
  String get commentSendToAgent => 'Gửi cho tác nhân';

  @override
  String get commentDelete => 'Xóa bình luận';

  @override
  String get commentEdit => 'Sửa bình luận';

  @override
  String get commentActions => 'Thao tác bình luận';

  @override
  String get commentDeleteTitle => 'Xóa bình luận này?';

  @override
  String get commentDeleteBody => 'Bình luận bị gỡ khỏi pull request.';

  @override
  String get commentSentToAgent => 'Đã gửi cho tác nhân';

  @override
  String get commentSendFailed => 'Không gửi được bình luận này cho tác nhân';

  @override
  String get commentDeleteFailed => 'Không xóa được bình luận này';

  @override
  String get autonomyDialLabel => 'Tự chủ';

  @override
  String get autonomyProposeOnly => 'Chỉ đề xuất';

  @override
  String get autonomyActWithApproval => 'Hành động khi được duyệt';

  @override
  String get autonomyActFreely => 'Hành động tự do';

  @override
  String get autonomyDefaultOption => 'Mặc định';

  @override
  String get checkerLabel => 'Trình kiểm tra';

  @override
  String get checkerNone => 'Không';

  @override
  String get checkerCaption =>
      'Trình kiểm tra xem lại các lần chạy đã hoàn tất của các agent khác.';

  @override
  String get takeoverTooltip => 'Tiếp quản cây làm việc';

  @override
  String get takeoverBannerSelf =>
      'Bạn đã tiếp quản cây làm việc của cuộc hội thoại này';

  @override
  String takeoverBannerOther(String name) {
    return '$name đã tiếp quản cây làm việc của cuộc hội thoại này';
  }

  @override
  String get handBackButton => 'Giao lại';

  @override
  String get handBackDialogTitle => 'Giao lại cây làm việc';

  @override
  String get handBackDialogNoteHint => 'Ghi chú tùy chọn cho agent…';

  @override
  String takeoverFailed(String message) {
    return 'Không tiếp quản được: $message';
  }

  @override
  String handBackFailed(String message) {
    return 'Không giao lại được: $message';
  }

  @override
  String get planStudioTitle => 'Studio kế hoạch';

  @override
  String get plansTitle => 'Kế hoạch';

  @override
  String get plansSubtitle =>
      'Kế hoạch đang hoạt động, tài liệu kế hoạch và playbook';

  @override
  String get plansActiveSection => 'Kế hoạch đang hoạt động';

  @override
  String get plansDocumentsSection => 'Tài liệu kế hoạch';

  @override
  String get plansPlaybooksSection => 'Playbook';

  @override
  String get plansNoActive => 'Chưa có kế hoạch đang hoạt động.';

  @override
  String get plansNoDocuments => 'Chưa có tài liệu kế hoạch.';

  @override
  String get plansNoPlaybooks => 'Chưa có playbook.';

  @override
  String get planNotFound => 'Không tìm thấy kế hoạch.';

  @override
  String get planOpenInStudio => 'Mở';

  @override
  String get planNodeTitle => 'Tiêu đề';

  @override
  String get planNodeDescription => 'Mô tả';

  @override
  String get planNodeDescriptionHint => 'Bước này nên làm gì…';

  @override
  String get planNodeApplyDescription => 'Áp dụng';

  @override
  String get planNodeRole => 'Vai trò';

  @override
  String get planNodeDependencies => 'Phụ thuộc vào';

  @override
  String get planNodeDependenciesHint => 'Thêm phụ thuộc';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count phụ thuộc',
      one: '1 phụ thuộc',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies =>
      'Không có phụ thuộc, nên bước này chạy ngay khi kế hoạch bắt đầu';

  @override
  String get planNodeOutputSchema => 'Lược đồ đầu ra (JSON)';

  @override
  String get planNodeEstimate => 'Ước tính';

  @override
  String get planNodeProvenance => 'Xuất xứ';

  @override
  String get planNodeAlreadyExecuted =>
      'Đã chạy — chỉnh sửa sẽ rẽ nhánh kế hoạch từ đây.';

  @override
  String get planNewNodeTitle => 'Bước mới';

  @override
  String get planEstimateNoHistory => 'Chưa có lịch sử';

  @override
  String get planEstimateBlastUnknown => 'Phạm vi ảnh hưởng: chưa rõ';

  @override
  String get planEstimatePartial => 'một phần';

  @override
  String get planEstimateAction => 'Ước tính';

  @override
  String planEstimateDuration(String range) {
    return 'Thời lượng $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return 'Phạm vi ảnh hưởng: $files tệp, $symbols ký hiệu';
  }

  @override
  String get planApprove => 'Phê duyệt kế hoạch';

  @override
  String get planApproveSelectedNodes => 'Phê duyệt mục đã chọn';

  @override
  String get planReject => 'Từ chối';

  @override
  String get planCancel => 'Hủy lần chạy';

  @override
  String get planContinueNode => 'Tiếp tục nút';

  @override
  String get planTotalNotEstimated => 'Chưa ước tính';

  @override
  String get planBudgetExceeded => 'vượt ngân sách';

  @override
  String planBudgetCeiling(String amount) {
    return 'ngân sách ≤ \$$amount';
  }

  @override
  String get planVersionsTitle => 'Phiên bản';

  @override
  String get planNoRevisions => 'Chưa có bản sửa đổi.';

  @override
  String get planDiffIdentical => 'Không có thay đổi.';

  @override
  String get planDiffGoalChanged => 'Mục tiêu đã đổi';

  @override
  String get planDiffBudgetChanged => 'Ngân sách đã đổi';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'Thay đổi từ v$fromRev đến v$toRev';
  }

  @override
  String planDiffAdded(String node) {
    return 'Đã thêm $node';
  }

  @override
  String planDiffRemoved(String node) {
    return 'Đã xóa $node';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return 'Đã sửa $node: $fields';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return 'Đã thêm cạnh: $edge';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return 'Đã xóa cạnh: $edge';
  }

  @override
  String planDiffRoleAdded(String role) {
    return 'Đã thêm vai trò: $role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return 'Đã xóa vai trò: $role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return 'Đã gán lại vai trò: $role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return 'Kế hoạch đã lập lại: bạn đã phê duyệt v$approved, hiện là v$current. Xem diff trước khi tiếp tục.';
  }

  @override
  String planLiveActualCost(String amount) {
    return 'Chi phí thực: \$$amount';
  }

  @override
  String get planPlaybookRun => 'Chạy';

  @override
  String get planPlaybookDelete => 'Xóa playbook';

  @override
  String get planPlaybookProposed =>
      'Đã đề xuất kế hoạch — phê duyệt trong Plan Studio.';

  @override
  String get planPlaybookAnchorTicket => 'Phiếu neo';

  @override
  String get planPlaybookPickTicket => 'Chọn phiếu…';

  @override
  String get planPlaybookProposeRun => 'Đề xuất kế hoạch';

  @override
  String get planPlaybookRepoHint => 'Một id repository';

  @override
  String get planPlaybookAgentHint => 'Một id agent';

  @override
  String planPlaybookRunTitle(String name) {
    return 'Chạy $name';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '$count tham số';
  }

  @override
  String get recentLabel => 'Gần đây';

  @override
  String get cheatSheetTitle => 'Phím tắt';

  @override
  String get cheatSheetGlobal => 'Toàn cục';

  @override
  String get cheatSheetThisScreen => 'Màn hình này';

  @override
  String get cheatSheetReservedInBrowser => 'Trình duyệt đã dành';

  @override
  String get keybindingCheatSheet => 'Phím tắt';

  @override
  String get runPlaybookLabel => 'Chạy playbook';

  @override
  String get playbooksLabel => 'Playbook';

  @override
  String get keybindingUndo => 'Hoàn tác';

  @override
  String get keybindingRedo => 'Làm lại';

  @override
  String get undone => 'Đã hoàn tác';

  @override
  String get redone => 'Đã làm lại';

  @override
  String get undoFailed => 'Không hoàn tác được';

  @override
  String get undoLabelTicketEdit => 'sửa phiếu';

  @override
  String get undoLabelMessageEdit => 'sửa tin nhắn';

  @override
  String get undoLabelTodoStatus => 'trạng thái todo';

  @override
  String get inboxTitle => 'Hộp thư';

  @override
  String get inboxReview => 'Đánh giá';

  @override
  String get inboxOpen => 'Đang mở';

  @override
  String get inboxAllCaughtUp => 'Bạn đã xem hết';

  @override
  String get inboxGitHubDownTitle => 'GitHub có thể đang gặp sự cố';

  @override
  String inboxGitHubDownBody(String status) {
    return 'GitHub đang báo $status, nên pull request có thể thiếu trong danh sách này chứ không phải đã xong.';
  }

  @override
  String get inboxGitHubIdentityTitle =>
      'Không xác nhận được tài khoản GitHub của bạn';

  @override
  String get inboxGitHubIdentityBody =>
      'Hộp thư được sắp xếp theo tài khoản GitHub của bạn. Trước khi tải xong, danh sách vẫn trống dù đã có pull request chờ bạn.';

  @override
  String get inboxSeverityBlocking => 'Bị chặn';

  @override
  String get inboxSeverityWaiting => 'Đang chờ';

  @override
  String get inboxSeverityInfo => 'Thông tin';

  @override
  String get inboxSyncFailed => 'Đồng bộ thất bại';

  @override
  String get inboxNeedsYourAttention => 'Cần bạn xử lý';

  @override
  String get inboxSectionNeedsYourReview => 'Cần bạn đánh giá';

  @override
  String get inboxSectionReturnedToYou => 'Được trả lại cho bạn';

  @override
  String get inboxSectionApproved => 'Đã duyệt';

  @override
  String get inboxSectionDrafts => 'Bản nháp';

  @override
  String get inboxSectionWaitingForReviewers => 'Đang chờ người đánh giá';

  @override
  String get inboxSectionMergingAndMerged => 'Đang gộp và vừa gộp';

  @override
  String get inboxSectionWaitingForAuthor => 'Đang chờ tác giả';

  @override
  String get inboxColumnTitle => 'Tiêu đề';

  @override
  String get inboxColumnChanges => 'Thay đổi';

  @override
  String get inboxColumnUpdated => 'Cập nhật';

  @override
  String get inboxReviewApproved => 'Đã duyệt';

  @override
  String get inboxReviewChangesRequested => 'Yêu cầu thay đổi';

  @override
  String get inboxHeroSubtitle =>
      'Mọi pull request liên quan đến bạn, sắp xếp theo việc cần làm tiếp.';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull request cần bạn đánh giá',
      one: '1 pull request cần bạn đánh giá',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count được trả lại cho bạn',
      one: '1 được trả lại cho bạn',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted =>
      'Thay đổi đó không lưu được và đã được hoàn nguyên';

  @override
  String get offlinePendingLabel => 'chờ xử lý';

  @override
  String get offlineSyncingLabel => 'đang đồng bộ';

  @override
  String get copyLinkLabel => 'Sao chép liên kết tới trang này';

  @override
  String get agentsSectionLabel => 'Agent';

  @override
  String get fleetWorkersTitle => 'Worker';

  @override
  String get fleetWorkersSubtitle => 'Máy sẵn sàng chạy công việc';

  @override
  String get fleetJobsTitle => 'Công việc';

  @override
  String get fleetJobsSubtitle => 'Công việc phân tán trên đội máy';

  @override
  String get fleetNoWorkers =>
      'Chưa có worker — máy thứ hai chạy `cc_worker --server <url>` sẽ tham gia đội máy.';

  @override
  String get fleetNoJobs => 'Không có công việc.';

  @override
  String get fleetError => 'Không tải được đội máy';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nhân',
      one: '1 nhân',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return 'Heartbeat $time';
  }

  @override
  String get fleetNoHeartbeat => 'Chưa có heartbeat';

  @override
  String fleetLastErrorLabel(String error) {
    return 'Lỗi gần nhất: $error';
  }

  @override
  String get fleetDrain => 'Ngừng nhận';

  @override
  String get fleetResume => 'Tiếp tục';

  @override
  String get fleetRevoke => 'Thu hồi';

  @override
  String get fleetRemove => 'Xóa';

  @override
  String get fleetRevokeTitle => 'Thu hồi worker?';

  @override
  String fleetRevokeBody(String name) {
    return 'Thu hồi $name? Phiên của máy sẽ kết thúc và các công việc đang chạy sẽ được gán lại.';
  }

  @override
  String get fleetRemoveTitle => 'Xóa worker?';

  @override
  String fleetRemoveBody(String name) {
    return 'Xóa $name khỏi đội máy? Bản ghi của máy sẽ bị xóa.';
  }

  @override
  String get fleetActionFailed => 'Thao tác thất bại';

  @override
  String get fleetJobUnassigned => 'Chưa gán';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '$attempts/$max lần thử';
  }

  @override
  String get fleetPlacementReasons => 'Quyết định phân bổ';

  @override
  String get fleetNoPlacements => 'Chưa có quyết định phân bổ.';

  @override
  String get fleetStatusOnline => 'Trực tuyến';

  @override
  String get fleetStatusDraining => 'Đang rút';

  @override
  String get fleetStatusOffline => 'Ngoại tuyến';

  @override
  String get fleetStatusIncompatible => 'Không tương thích';

  @override
  String get fleetStatusRevoked => 'Đã thu hồi';

  @override
  String get fleetJobStatusQueued => 'Trong hàng đợi';

  @override
  String get fleetJobStatusRunning => 'Đang chạy';

  @override
  String get fleetJobStatusSucceeded => 'Thành công';

  @override
  String get fleetJobStatusFailed => 'Thất bại';

  @override
  String get fleetJobStatusCancelled => 'Đã hủy';

  @override
  String get evalsNoSuites => 'Chưa có bộ eval.';

  @override
  String get evalsError => 'Không tải được evals';

  @override
  String get evalsStarterBadge => 'Starter';

  @override
  String evalsDefaultBatch(int count) {
    return 'Lô mặc định gồm $count';
  }

  @override
  String get evalsRecentRuns => 'Lần chạy gần đây';

  @override
  String get evalsNoRuns => 'Chưa có lần chạy nào.';

  @override
  String get evalsPassRate => 'Tỷ lệ đạt';

  @override
  String evalsBatchTimes(int count) {
    return '× $count';
  }

  @override
  String evalsTriggeredBy(String who) {
    return 'bởi $who';
  }

  @override
  String evalsRunFinished(String rate) {
    return 'Eval đã xong — $rate đạt';
  }

  @override
  String get evalsRunFailed => 'Không chạy được bộ eval';

  @override
  String get evalsRun => 'Chạy';

  @override
  String get evalsStatusQueued => 'Trong hàng đợi';

  @override
  String get evalsStatusRunning => 'Đang chạy';

  @override
  String get evalsStatusPassed => 'Đạt';

  @override
  String get evalsStatusFailed => 'Thất bại';

  @override
  String get bannerCalendarReconnect => 'Kết nối lại';

  @override
  String get bannerView => 'Xem';

  @override
  String get soundscapeTitle => 'Soundscapes';

  @override
  String get soundscapePlay => 'Phát';

  @override
  String get soundscapePause => 'Tạm dừng';

  @override
  String get soundscapeMoodLabel => 'Tâm trạng';

  @override
  String get soundscapeMoodFocus => 'Tập trung';

  @override
  String get soundscapeMoodRelax => 'Thư giãn';

  @override
  String get soundscapeMoodSleep => 'Ngủ';

  @override
  String get soundscapeMoodRise => 'Vươn';

  @override
  String get soundscapeVolumeLabel => 'Âm lượng';

  @override
  String get soundscapeTuneLabel => 'Điều chỉnh';

  @override
  String get soundscapeTuneMellow => 'Êm';

  @override
  String get soundscapeTuneBright => 'Sáng';

  @override
  String get soundscapeTuneEnergetic => 'Năng lượng';

  @override
  String get soundscapeTuneSpacy => 'Không gian';

  @override
  String get soundscapeTuneResetHint => 'Nhấn đúp để đặt lại';

  @override
  String get soundscapeSceneLabel => 'Đang phát';

  @override
  String get soundscapeSceneLoading => 'Đang tinh chỉnh không khí…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees°C';
  }

  @override
  String get soundscapeLocationLabel => 'Vị trí';

  @override
  String get soundscapeLocationDetecting => 'Đang xác định vị trí…';

  @override
  String get soundscapeLocationAutoNote => 'Vị trí đến từ thiết bị này.';

  @override
  String get soundscapeRefreshWeather => 'Làm mới thời tiết';

  @override
  String get soundscapeAutoStartLabel => 'Bắt đầu với chế độ tập trung';

  @override
  String get soundscapeAutoStartDescription =>
      'Tự động phát soundscape khi bạn bắt đầu phiên tập trung.';

  @override
  String get soundscapeReturnToApp => 'Quay lại ứng dụng';

  @override
  String get soundscapePopOut => 'Tách trình phát';

  @override
  String get discussion => 'Thảo luận';

  @override
  String get chat => 'Chat';

  @override
  String get saving => 'Đang lưu…';

  @override
  String get saved => 'Đã lưu';

  @override
  String get saveFailed => 'Không lưu được';

  @override
  String get commitAndPush => 'Commit & đẩy';

  @override
  String get commit => 'Commit';

  @override
  String get commitAmend => 'Commit (sửa lại)';

  @override
  String get commitAndSync => 'Commit & đồng bộ';

  @override
  String get scmSyncChanges => 'Đồng bộ thay đổi';

  @override
  String get scmPublishBranch => 'Xuất bản nhánh';

  @override
  String get scmSyncFailed => 'Đồng bộ thất bại';

  @override
  String get scmSyncDirty => 'Commit hoặc hủy thay đổi trước khi đồng bộ';

  @override
  String get scmSynced => 'Đã đồng bộ';

  @override
  String get scmPushRefused => 'Push bị từ chối';

  @override
  String get scmPulledPushRefused => 'Đã kéo về, nhưng push bị từ chối';

  @override
  String get scmPushRefusedHint =>
      'Máy chủ từ xa hoặc hook đã từ chối bản cập nhật';

  @override
  String get scmSelectBranch => 'Chọn nhánh để checkout';

  @override
  String get scmCreateBranch => 'Tạo nhánh mới…';

  @override
  String get scmCreateBranchFrom => 'Tạo nhánh mới từ…';

  @override
  String get scmCheckoutDetached => 'Checkout tách rời…';

  @override
  String get scmBranchName => 'Tên nhánh';

  @override
  String get scmCreateBranchTitle => 'Tạo nhánh';

  @override
  String scmFromRef(String ref) {
    return 'Từ ⁨$ref⁩';
  }

  @override
  String get scmCheckoutFailed => 'Không chuyển được nhánh';

  @override
  String get scmCheckoutDirty =>
      'Hãy commit hoặc hủy thay đổi trước khi chuyển nhánh';

  @override
  String scmSwitchedToBranch(String branch) {
    return 'Đã chuyển sang ⁨$branch⁩';
  }

  @override
  String scmDetachedAt(String ref) {
    return 'Tách rời tại ⁨$ref⁩';
  }

  @override
  String get scmDetachedHead => 'HEAD tách rời';

  @override
  String get scmNoBranches => 'Không có nhánh khớp';

  @override
  String get scmBranches => 'Nhánh';

  @override
  String get scmRemoteBranches => 'Nhánh từ xa';

  @override
  String get scmTags => 'Thẻ';

  @override
  String get scmPickStartPoint => 'Chọn điểm bắt đầu';

  @override
  String get scmSwitchBranch => 'Chuyển nhánh';

  @override
  String get scmPullConflictTitle => 'Kéo về sẽ gây xung đột';

  @override
  String scmPullConflictBody(int count, String branch) {
    return 'Kéo $count commit vào ⁨$branch⁩ sẽ xung đột với phần việc trong bản làm việc này.';
  }

  @override
  String get scmAskAi => 'Nhờ AI';

  @override
  String scmResolveConflictPrompt(String branch, String repo, int count) {
    return 'Kéo ⁨$branch⁩ trong ⁨$repo⁩. Nhánh đang chậm $count commit so với upstream và lần kéo xung đột với phần việc cục bộ. Giải quyết xung đột và hoàn tất lần kéo.';
  }

  @override
  String commitMessageOnBranch(String shortcut, String branch) {
    return 'Thông điệp ($shortcut để commit trên “$branch”)';
  }

  @override
  String get committed => 'Đã commit';

  @override
  String get commitAmended => 'Đã sửa commit';

  @override
  String get commitFailed => 'Commit thất bại';

  @override
  String get moreCommitActions => 'Thêm thao tác commit';

  @override
  String get sourceControl => 'Kiểm soát mã nguồn';

  @override
  String fixFindingTitle(String location) {
    return 'Sửa: $location';
  }

  @override
  String get openInEditor => 'Mở trong trình soạn thảo';

  @override
  String get regexTesterTitle => 'Kiểm tra biểu thức chính quy';

  @override
  String get regexTesterHint => 'Nhập một mẫu';

  @override
  String get regexMatch => 'Khớp';

  @override
  String get regexNoMatch => 'Không khớp';

  @override
  String get regexInvalidPattern => 'Mẫu không hợp lệ';

  @override
  String get symbolLookupNone =>
      'Không có định nghĩa trong chỉ mục hoặc pull request này';

  @override
  String get symbolLookupInDiff => 'Tìm thấy trong pull request này';

  @override
  String get symbolLookupFromBase =>
      'Từ checkout gốc — worktree của PR này chưa được lập chỉ mục';

  @override
  String get symbolImplementations => 'Triển khai';

  @override
  String symbolCallersCount(int count) {
    return '$count nơi gọi';
  }

  @override
  String get commitMessageHint => 'Nội dung commit';

  @override
  String get pushedToPr => 'Đã đẩy lên PR';

  @override
  String get pushFailed => 'Đẩy thất bại';

  @override
  String get reviewFindings => 'Phát hiện';

  @override
  String get treeLabel => 'Cây';

  @override
  String get toggleFileTree => 'Hiện hoặc ẩn cây tệp';

  @override
  String get diffViewSettings => 'Cài đặt xem diff';

  @override
  String get splitViewLabel => 'Chia';

  @override
  String get unifiedViewLabel => 'Gộp';

  @override
  String get wrapLines => 'Ngắt dòng';

  @override
  String get shiftClickSelectRange => 'Shift-click để chọn một khoảng';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tệp',
      one: '1 tệp',
    );
    return '$_temp0';
  }

  @override
  String prComplexityLoc(String loc) {
    return '$loc LOC';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return 'PR nhỏ — $files, ~$minutes phút để review';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return 'PR vừa — $files, dành ~$minutes phút để review';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return 'PR lớn — $files, nên tách trước khi review';
  }

  @override
  String get searchInFiles => 'Tìm trong tệp';

  @override
  String get showFileList => 'Hiện danh sách tệp';

  @override
  String get searchInFilesHintField => 'Tìm trong tệp…';

  @override
  String get searchInFilesHint => 'Tìm trong các tệp của pull request';

  @override
  String get searchInWholeRepo => 'Tìm trong toàn bộ kho';

  @override
  String get searchInThisPullRequest => 'Tìm trong pull request này';

  @override
  String get searchNoResults => 'Không tìm thấy kết quả';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kết quả',
      one: '1 kết quả',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files tệp',
      one: '1 tệp',
    );
    return '$_temp0 trong $_temp1';
  }

  @override
  String get discardChangesTitle => 'Hủy thay đổi?';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tệp',
      one: '1 tệp',
    );
    return 'Hủy $_temp0 về HEAD? Không thể hoàn tác.';
  }

  @override
  String get discardAll => 'Hủy tất cả';

  @override
  String get discardFailed => 'Không hủy được thay đổi';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tệp',
      one: '1 tệp',
    );
    return 'Đã hủy $_temp0';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '$reverted tệp',
      one: '1 tệp',
    );
    return 'Đã hủy $_temp0; bỏ qua $skipped (chưa theo dõi)';
  }

  @override
  String get prWorktreeUnavailable => 'Không gian làm việc chưa sẵn sàng';

  @override
  String get prWorktreeUnavailableHint =>
      'Chuẩn bị tệp của pull request thất bại. Mở lại pull request để thử lại.';

  @override
  String get timestampRelativeLabel => 'Tương đối';

  @override
  String get timestampRawLabel => 'Dấu thời gian';

  @override
  String get previewDeployment => 'Xem trước triển khai';

  @override
  String previewDeploymentTab(String site) {
    return 'Xem trước: $site';
  }

  @override
  String get askForReview => 'Yêu cầu review…';

  @override
  String get closePrsConfirmTitle => 'Đóng pull request?';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đóng $count pull request?',
      one: 'Đóng 1 pull request?',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã đóng $count pull request',
      one: 'Đã đóng 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã gán $count pull request',
      one: 'Đã gán 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã yêu cầu review $count pull request',
      one: 'Đã yêu cầu review 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thao tác thất bại',
      one: '1 thao tác thất bại',
    );
    return '$_temp0';
  }

  @override
  String get diagram => 'Sơ đồ';

  @override
  String get diagramViewSource => 'Xem mã nguồn';

  @override
  String get diagramHideSource => 'Ẩn mã nguồn';

  @override
  String diagramPreviewUnavailable(String reason) {
    return 'Không xem trước sơ đồ được ($reason)';
  }

  @override
  String get planUnavailable => 'Kế hoạch không khả dụng';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bước',
      one: '1 bước',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => 'Phê duyệt và chạy';

  @override
  String get planStatusDraft => 'Nháp';

  @override
  String get planStatusProposed => 'Kế hoạch';

  @override
  String get planStatusApproved => 'Kế hoạch đã phê duyệt';

  @override
  String get planStatusRejected => 'Kế hoạch bị từ chối';

  @override
  String get planStatusSuperseded => 'Kế hoạch đã thay thế';

  @override
  String planRevisionLabel(int revision) {
    return 'Phiên bản $revision';
  }

  @override
  String get adapterEnforcementTitle => 'Những gì adapter này thực thi';

  @override
  String get enforcementFiltersToolSurface => 'Control Center chọn các công cụ';

  @override
  String get enforcementInterceptsToolCalls =>
      'Mọi lời gọi đều được kiểm soát trước khi chạy';

  @override
  String get enforcementObservesCompletionContract =>
      'Lần chạy phải đáp ứng kết quả giao';

  @override
  String get enforcementNativeToolsInterceptable =>
      'Công cụ của chính runner đều hiển thị';

  @override
  String get enforcementInProcessToolsSandboxed =>
      'Công cụ in-process được chạy trong sandbox';

  @override
  String get enforcementYes => 'Có';

  @override
  String get enforcementNo => 'Không';

  @override
  String get adapterEnforcementCaveats => 'Lưu ý';

  @override
  String get enforcementSummaryModesEnforced => 'Chế độ được thực thi';

  @override
  String get enforcementSummaryModesNotEnforced => 'Chế độ không được thực thi';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lưu ý',
      one: '1 lưu ý',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      'Chế độ chỉ đọc không mang tính cấu trúc: Control Center không thể gỡ công cụ của chính runner này.';

  @override
  String get caveatToolCallsNotIntercepted =>
      'Không có cổng trước khi chạy: chỉ lời gọi công cụ MCP đi qua Control Center.';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      'Công cụ tệp và shell của chính runner không bao giờ tới Control Center; sandbox hệ điều hành là lớp bảo vệ duy nhất bên dưới chúng.';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      'Công cụ tệp in-process chạy ngoài sandbox, nên bề mặt công cụ là ranh giới hệ thống tệp duy nhất.';

  @override
  String get caveatCompletionContractUnobservable =>
      'Control Center không thể thúc hay đánh dấu thất bại một lần chạy kết thúc mà không tạo ra kết quả giao.';

  @override
  String get modeDegraded => 'Suy giảm';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return 'Chế độ $mode trên $adapter chỉ dựa vào sandbox; các công cụ tệp của chính agent không bị chặn.';
  }

  @override
  String get artifactUnavailable => 'Không có tạo tác';

  @override
  String artifactRevisionLabel(int count) {
    return '$count phiên bản';
  }

  @override
  String get artifactShowMore => 'Hiện thêm';

  @override
  String get artifactShowLess => 'Ẩn bớt';

  @override
  String get artifactCopy => 'Sao chép';

  @override
  String get artifactCopied => 'Đã sao chép tạo tác';

  @override
  String get artifactsTabLabel => 'Tạo tác';

  @override
  String get artifactsEmptyTitle => 'Chưa có tạo tác';

  @override
  String get artifactsEmptyBody =>
      'Khi một agent đăng bảng, biểu đồ hoặc sơ đồ tại đây, mục đó sẽ xuất hiện trong danh sách này.';

  @override
  String get artifactRevisionPickerLabel => 'Phiên bản';

  @override
  String get artifactRestoreRevision => 'Khôi phục phiên bản này';

  @override
  String get artifactOpenInTab => 'Mở trong tab';

  @override
  String get artifactTitleFallback => 'Tạo tác';

  @override
  String get providerGenerationLabel => 'Mặc định sinh';

  @override
  String get providerGenerationHint =>
      'Để trống một trường để dùng mặc định của chính endpoint. Các mô hình công bố trần đầu ra và công thức lấy mẫu riêng; phục vụ một mô hình với giá trị khác có thể làm giảm chất lượng.';

  @override
  String get providerMaxTokensLabel => 'Số token đầu ra tối đa';

  @override
  String get addModel => 'Thêm mô hình';

  @override
  String get modelListTitle => 'Danh sách mô hình';

  @override
  String get railProvidersGroup => 'Nhà cung cấp';

  @override
  String get railCustomProvidersGroup => 'Nhà cung cấp tùy chỉnh';

  @override
  String get editModelSettings => 'Chỉnh sửa cài đặt mô hình';

  @override
  String get modelIdLabel => 'ID mô hình';

  @override
  String get modelIdImmutableHint =>
      'ID mà endpoint phục vụ; cố định sau khi đã liệt kê.';

  @override
  String get contextWindowLabel => 'Cửa sổ ngữ cảnh';

  @override
  String get inputTypesLabel => 'Loại đầu vào';

  @override
  String get outputTypesLabel => 'Loại đầu ra';

  @override
  String get modalityText => 'Văn bản';

  @override
  String get modalityImage => 'Hình ảnh';

  @override
  String get modalityAudio => 'Âm thanh';

  @override
  String get modalityVideo => 'Video';

  @override
  String get modalityPdf => 'PDF';

  @override
  String get modelOverrideReset => 'Đặt lại về tự động';

  @override
  String get modelOverrideEdited => 'Đã chỉnh sửa';

  @override
  String get manualModelBadge => 'Thêm thủ công';

  @override
  String get modelIdRequired => 'Nhập id mô hình.';

  @override
  String get modelTokensInvalid => 'Nhập số nguyên dương token.';

  @override
  String get removeModelAction => 'Xóa mô hình';

  @override
  String removeModelConfirmTitle(String model) {
    return 'Xóa $model?';
  }

  @override
  String get removeModelConfirmBody =>
      'Mô hình sẽ rời danh sách và các agent gắn với nó sẽ ngừng hoạt động. Nhà cung cấp không bị ảnh hưởng.';

  @override
  String get addModelProviderTitle => 'Thêm nhà cung cấp mô hình';

  @override
  String get addModelProviderDescription =>
      'Cấu hình endpoint API tùy chỉnh và các mô hình của nó.';

  @override
  String get modelListEmptyHint =>
      'Chưa cấu hình mô hình. Thêm mô hình để dùng trong chat.';

  @override
  String get addProviderModelsHint =>
      'Mô hình được lấy trực tiếp khi endpoint phản hồi. Chỉ thêm thủ công nếu nó không tự liệt kê được.';

  @override
  String get providerTemperatureLabel => 'Nhiệt độ';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved => 'Đã lưu mặc định sinh nội dung';

  @override
  String get providerGenerationInvalid =>
      'Kiểm tra giá trị: token đầu ra tối đa và top-k phải dương, nhiệt độ 0–2, top-p 0–1.';

  @override
  String get providerGenerationOverridden => 'Đã ghi đè';

  @override
  String get branchNotPushed => 'chưa đẩy';

  @override
  String branchNotOnRemote(String branch) {
    return '“$branch” chỉ tồn tại trong cuộc trò chuyện này';
  }

  @override
  String get branchNotOnRemoteHint =>
      'GitHub chưa từng thấy nhánh này, nên pull request chưa dùng được. Xuất bản sẽ đẩy các commit đã có trong cây làm việc — thay đổi chưa commit được giữ nguyên.';

  @override
  String get publishBranch => 'Xuất bản nhánh';

  @override
  String branchPublished(String branch) {
    return 'Đã xuất bản “$branch” lên origin';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return 'Đã xuất bản nhánh. $count thay đổi chưa commit không được đưa vào.';
  }

  @override
  String get composePrLoadingBranches => 'Đang tải nhánh từ GitHub…';

  @override
  String get composePrBranchesFailed =>
      'Không tải được nhánh từ GitHub. Nhập tên nhánh, hoặc kiểm tra kết nối GitHub.';

  @override
  String get composePrSubtitleFromSpace =>
      'Từ nhánh của cuộc trò chuyện này — xuất bản trước nếu GitHub chưa thấy';

  @override
  String get obsTabInsights => 'Phân tích';

  @override
  String get obsTabLive => 'Trực tiếp';

  @override
  String get obsTabQuality => 'Chất lượng';

  @override
  String get obsTabUsage => 'Mức dùng';

  @override
  String get obsUsageTotalTokens => 'Tổng token';

  @override
  String get obsUsagePeakTokens => 'Token cao nhất';

  @override
  String get obsUsageLongestSession => 'Phiên dài nhất';

  @override
  String get obsUsageCurrentStreak => 'Chuỗi hiện tại';

  @override
  String get obsUsageLongestStreak => 'Chuỗi dài nhất';

  @override
  String obsUsageDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày',
      one: '1 ngày',
      zero: '0 ngày',
    );
    return '$_temp0';
  }

  @override
  String get obsUsageTokenActivity => 'Hoạt động token';

  @override
  String get obsUsageActivityModeLabel => 'Chế độ hoạt động token';

  @override
  String get obsUsageModeDaily => 'Theo ngày';

  @override
  String get obsUsageModeWeekly => 'Theo tuần';

  @override
  String get obsUsageModeCumulative => 'Tích lũy';

  @override
  String get obsUsageTimeRange => 'Khoảng thời gian';

  @override
  String get obsUsageTrendTitle => 'Xu hướng token theo ngày';

  @override
  String get obsUsageModelUsage => 'Mức dùng mô hình';

  @override
  String get obsUsageTokensLabel => 'token';

  @override
  String get obsUsageNoActivity => 'Chưa ghi nhận mức dùng token';

  @override
  String get obsUsageOtherModels => 'Khác';

  @override
  String obsUsageCellReadout(String date, String tokens) {
    return '$date · $tokens token';
  }

  @override
  String obsUsageActivitySummary(
    String start,
    String end,
    int activeDays,
    String peak,
  ) {
    return 'Hoạt động token từ $start đến $end. $activeDays ngày hoạt động. Ngày cao nhất $peak token.';
  }

  @override
  String get obsScreenSubtitle =>
      'Điều khiển agent trực tiếp, phân bổ chi phí, hạn mức và tín hiệu chất lượng';

  @override
  String get obsRangeLast24h => '24 giờ qua';

  @override
  String get obsRangeLast7d => '7 ngày qua';

  @override
  String get obsRangeLast30d => '30 ngày qua';

  @override
  String get obsRangeAll => 'Mọi lúc';

  @override
  String get obsAddFilter => 'Thêm bộ lọc';

  @override
  String get obsFilterAgent => 'Agent';

  @override
  String get obsFilterModel => 'Mô hình';

  @override
  String get obsFilterStatus => 'Trạng thái';

  @override
  String get obsFilterRole => 'Vai trò';

  @override
  String get obsKpiTotalRuns => 'Tổng lần chạy';

  @override
  String get obsKpiTotalCost => 'Tổng chi phí';

  @override
  String get obsKpiErrorRate => 'Tỷ lệ lỗi';

  @override
  String get obsKpiCacheRate => 'Tỷ lệ cache';

  @override
  String get obsKpiTokensPerSec => 'Token / giây';

  @override
  String get obsKpiAvgLatency => 'Độ trễ TB';

  @override
  String get obsKpiTtft => 'Thời gian đến token đầu';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '$delta so với kỳ trước';
  }

  @override
  String get obsChartActivity => 'Hoạt động';

  @override
  String get obsChartCost => 'Chi phí theo thời gian';

  @override
  String get obsLegendRuns => 'Lần chạy';

  @override
  String get obsLegendErrors => 'Lỗi';

  @override
  String get obsAgentsTitle => 'Agent';

  @override
  String obsShowAllAgents(int count) {
    return 'Hiện tất cả $count agent';
  }

  @override
  String get obsShowFewerAgents => 'Hiện ít hơn';

  @override
  String get obsRunsTitle => 'Lần chạy';

  @override
  String get obsNoRunsInRange => 'Không có lần chạy trong khoảng này';

  @override
  String get obsColTime => 'Thời gian';

  @override
  String get obsColAgent => 'Agent';

  @override
  String get obsColStatus => 'Trạng thái';

  @override
  String get obsColModel => 'Mô hình';

  @override
  String get obsColDuration => 'Thời lượng';

  @override
  String get obsColTokens => 'Token';

  @override
  String get obsColCost => 'Chi phí';

  @override
  String get obsColErrors => 'Lỗi';

  @override
  String get obsColRuns => 'Lần chạy';

  @override
  String get obsColAvgLatency => 'Độ trễ TB';

  @override
  String get obsColLastActive => 'Hoạt động lần cuối';

  @override
  String get obsStatusPending => 'Đang chờ';

  @override
  String get obsStatusRunning => 'Đang chạy';

  @override
  String get obsStatusCompleted => 'Hoàn tất';

  @override
  String get obsStatusError => 'Lỗi';

  @override
  String get obsRosterLoadError => 'Không tải được danh sách agent.';

  @override
  String get obsRosterEmpty => 'Chưa có agent';

  @override
  String get obsRosterEmptyDescription =>
      'Gửi một agent và nó sẽ xuất hiện trực tiếp tại đây — trạng thái, công cụ hiện tại, token, chi phí.';

  @override
  String get obsKillAgent => 'Dừng agent';

  @override
  String get obsRosterTokensLabel => 'tok';

  @override
  String get obsCostByRoleTitle => 'Chi phí theo vai trò';

  @override
  String get obsCostByRoleSubtitle =>
      'Nơi không gian làm việc này chi tiêu, theo vai trò agent';

  @override
  String get obsRoleMain => 'Chính';

  @override
  String get obsRoleSubagents => 'Subagent';

  @override
  String get obsRoleAdvisor => 'Cố vấn';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return 'Chính: $main · subagent: $sub · cố vấn: $advisor';
  }

  @override
  String get obsTotal => 'Tổng';

  @override
  String get obsTokenModelTitle => 'Mô hình token (5 trục)';

  @override
  String get obsTokenModelSubtitle =>
      'Mọi token không gian làm việc này đã dùng, theo trục';

  @override
  String get obsAxisInput => 'Đầu vào';

  @override
  String get obsAxisOutput => 'Đầu ra';

  @override
  String get obsAxisReasoning => 'Suy luận';

  @override
  String get obsAxisCacheRead => 'Đọc cache';

  @override
  String get obsAxisCacheWrite => 'Ghi cache';

  @override
  String get obsTotalTokens => 'Tổng token';

  @override
  String get obsCacheDiscountNote =>
      'Token đọc cache được tính giá giảm, nên rẻ hơn nhiều so với cùng lượng đầu vào mới.';

  @override
  String get obsByModelTitle => 'Theo mô hình';

  @override
  String get obsByModelSubtitle => 'Mức dùng token và chi phí theo mô hình';

  @override
  String get obsNoModelUsage => 'Chưa ghi nhận mức dùng mô hình.';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lần chạy',
      one: '1 lần chạy',
    );
    return '$_temp0';
  }

  @override
  String get obsPerRunTitle => 'Theo lần chạy';

  @override
  String get obsPerRunSubtitle => 'Chi phí token điển hình của một lần chạy';

  @override
  String get obsMedianRunTokens => 'Token trung vị mỗi lần chạy';

  @override
  String get obsMedianRunTokensSub => 'Điểm giữa trên tất cả lần chạy';

  @override
  String get obsRunsInWorkspace => 'Trong không gian làm việc này';

  @override
  String get obsCostShare => 'Tỷ lệ chi phí';

  @override
  String get obsQuotaConfiguredLimits => 'Giới hạn đã cấu hình';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      'Mức dùng so với trần bạn đặt, trạng thái xấu nhất trước.';

  @override
  String get obsQuotaAddLimit => 'Thêm giới hạn';

  @override
  String get obsQuotaNoLimits =>
      'Chưa cấu hình giới hạn hạn mức — thêm một giới hạn để theo dõi mức dùng so với trần.';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return 'Gỡ giới hạn $title';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return 'Đặt lại sau $duration · $status';
  }

  @override
  String get obsQuotaUsageWindows => 'Cửa sổ mức dùng';

  @override
  String get obsQuotaUsageWindowsSubtitle =>
      'Mức dùng quan sát trên tất cả nhà cung cấp, không áp dụng trần.';

  @override
  String get obsQuotaNoUsage => 'Chưa ghi nhận mức dùng.';

  @override
  String get obsQuotaTokensUsed => 'Token đã dùng';

  @override
  String get obsQuotaRequests => 'Yêu cầu';

  @override
  String get obsQuotaUnitTokens => 'token';

  @override
  String get obsQuotaUnitRequests => 'yêu cầu';

  @override
  String get obsQuotaUnitCost => 'chi phí';

  @override
  String get obsQuotaAddLimitTitle => 'Thêm giới hạn hạn mức';

  @override
  String get obsQuotaProviderLabel => 'Nhà cung cấp';

  @override
  String get obsQuotaWindowLabel => 'Cửa sổ';

  @override
  String get obsQuotaUnitLabel => 'Đơn vị';

  @override
  String obsQuotaLimitLabel(String unit) {
    return 'Giới hạn ($unit)';
  }

  @override
  String get obsQuotaCentsHint => 'Tính bằng xu Mỹ (500 = \$5.00).';

  @override
  String get obsQuotaStatusOk => 'Ổn';

  @override
  String get obsQuotaStatusWarning => 'Cảnh báo';

  @override
  String get obsQuotaStatusExhausted => 'Đã cạn';

  @override
  String get obsQuotaStatusUnknown => 'Không xác định';

  @override
  String get obsGoalNoActiveTitle => 'Không có mục tiêu đang hoạt động';

  @override
  String get obsGoalNoActiveBody =>
      'Đặt mục tiêu để giao mục đích cho các agent và ngân sách token tùy chọn. Khi các lần chạy hoàn tất, ngân sách được lấp đầy và các agent được nhắc kết thúc khi gần hết.';

  @override
  String get obsGoalSetGoal => 'Đặt mục tiêu';

  @override
  String get obsGoalTokenBudget => 'Ngân sách token';

  @override
  String obsGoalTokensLeft(String tokens) {
    return 'Còn $tokens';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens (chưa đặt ngân sách)';
  }

  @override
  String get obsGoalTokensUsed => 'Token đã dùng';

  @override
  String get obsGoalElapsed => 'Đã trôi qua';

  @override
  String get obsGoalWrapUp => 'Kết thúc';

  @override
  String get obsGoalClear => 'Xóa mục tiêu';

  @override
  String get obsGoalFallbackTitle => 'Mục tiêu';

  @override
  String get obsGoalSubtitle => 'Ngân sách chế độ mục tiêu';

  @override
  String get obsGoalStatusActive => 'Đang hoạt động';

  @override
  String get obsGoalStatusPaused => 'Tạm dừng';

  @override
  String get obsGoalStatusBudgetLimited => 'Hạn chế ngân sách';

  @override
  String get obsGoalStatusComplete => 'Hoàn tất';

  @override
  String get obsGoalStatusDropped => 'Đã bỏ';

  @override
  String get obsGoalObjectiveLabel => 'Mục đích';

  @override
  String get obsGoalBudgetLabel => 'Ngân sách token (tùy chọn)';

  @override
  String get obsGoalSetAction => 'Đặt mục tiêu';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => '% thành công';

  @override
  String get obsBenchmarkPassed => 'Đạt';

  @override
  String get obsBenchmarkFailed => 'Thất bại';

  @override
  String get obsBenchmarkErrors => 'Lỗi';

  @override
  String get obsBenchmarkSpend => 'Chi tiêu';

  @override
  String get obsBenchmarkCostPerTask => 'Chi phí / tác vụ';

  @override
  String get obsBenchmarkTrials => 'Lần thử';

  @override
  String get obsBenchmarkNoTrials => 'Chưa có lần chạy nào để chấm điểm.';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Và $count nữa',
      one: 'Và 1 nữa',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => 'Đạt';

  @override
  String get obsBenchmarkTrialFail => 'Không đạt';

  @override
  String get obsBenchmarkTrialError => 'Lỗi';

  @override
  String get obsBenchmarkTrialRunning => 'Đang chạy';

  @override
  String get obsBenchmarkReward => 'Phần thưởng';

  @override
  String get obsBenchmarkReport => 'Báo cáo';

  @override
  String get obsBenchmarkCopyMarkdown => 'Sao chép markdown';

  @override
  String get obsBenchmarkCopied => 'Đã sao chép báo cáo vào bộ nhớ tạm';

  @override
  String get obsBehaviorCaption =>
      'Đây là tín hiệu bực bội phân tích từ tin nhắn của bạn — phản ánh sức khỏe hội thoại, không phải điểm số cho agent. Tính cục bộ; không gì rời khỏi thiết bị này.';

  @override
  String get obsBehaviorMessagesAnalyzed => 'Tin nhắn đã phân tích';

  @override
  String get obsBehaviorTotalSignals => 'Tổng tín hiệu';

  @override
  String get obsBehaviorYelling => 'La hét';

  @override
  String get obsBehaviorProfanity => 'Ngôn từ tục';

  @override
  String get obsBehaviorAnguish => 'Khổ sở';

  @override
  String get obsBehaviorNegation => 'Phủ định';

  @override
  String get obsBehaviorRepetition => 'Lặp lại';

  @override
  String get obsBehaviorBlame => 'Đổ lỗi';

  @override
  String get obsBehaviorConversationsTitle => 'Hội thoại bực bội nhất';

  @override
  String get obsBehaviorConversationsSubtitle =>
      'Xếp hạng theo mật độ tín hiệu trong tin nhắn của bạn.';

  @override
  String get obsBehaviorNoSignals =>
      'Không phát hiện tín hiệu bực bội — mọi thứ suôn sẻ.';

  @override
  String obsBehaviorMessagesCount(String count) {
    return '$count tin nhắn đã phân tích';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '$count tín hiệu';
  }

  @override
  String get obsAgentStatusIdle => 'Nhàn rỗi';

  @override
  String get obsAgentStatusParked => 'Đỗ';

  @override
  String get obsAgentStatusAborted => 'Đã hủy';

  @override
  String get obsAgentKindSub => 'Sub';

  @override
  String get noChecksOnCommit => 'Chưa có kiểm tra nào chạy trên commit này.';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đang chạy — $count job',
      one: 'Đang chạy — 1 job',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tất cả kiểm tra đều đạt — $count job',
      one: 'Tất cả kiểm tra đều đạt — 1 job',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã hoàn thành — $count job',
      one: 'Đã hoàn thành — 1 job',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total job',
      one: '1 job',
    );
    return '$failed trên $_temp0 thất bại';
  }

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count job',
      one: '1 job',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return 'Ma trận: $jobId';
  }

  @override
  String get jobLogsPending => 'Nhật ký sẽ hiện ở đây khi job kết thúc.';

  @override
  String get jobLogsUnavailable => 'Không có nhật ký cho job này.';

  @override
  String get noLogsForStep => 'Không ghi được nhật ký cho bước này.';

  @override
  String get jobLogsTruncated => 'Nhật ký bị cắt — đang hiện phần mới nhất.';

  @override
  String get fullLog => 'Nhật ký đầy đủ';

  @override
  String get copyLogs => 'Sao chép nhật ký';

  @override
  String get resizeGraph => 'Kéo để đổi kích thước đồ thị';

  @override
  String workflowRunStartedAgo(String time) {
    return 'Bắt đầu $time';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return 'Hoàn thành $time';
  }

  @override
  String get chatBridgesTitle => 'Cầu nối chat';

  @override
  String chatProviderDescription(String provider, String command) {
    return 'Nhắc bot trong $provider để giao việc cho agent, hoặc soạn bản nháp phiếu bằng $command.';
  }

  @override
  String chatConnectProvider(String provider) {
    return 'Kết nối $provider';
  }

  @override
  String get chatDisconnectProvider => 'Ngắt kết nối';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$botName trong $teamName';
  }

  @override
  String get chatStateLive => 'Trực tiếp';

  @override
  String get chatStateConnecting => 'Đang kết nối…';

  @override
  String get chatStateError => 'Lỗi kết nối';

  @override
  String get chatNotConnected => 'Chưa kết nối';

  @override
  String chatStreamingUnavailable(String provider) {
    return 'Luồng trực tiếp đang tắt cho ứng dụng $provider này — phản hồi đến thành một tin nhắn.';
  }

  @override
  String chatAdminOnly(String provider) {
    return 'Chỉ quản trị viên mới có thể kết nối $provider cho không gian làm việc này.';
  }

  @override
  String chatConnectHint(String provider) {
    return 'Tạo ứng dụng $provider, rồi dán thông tin xác thực vào đây. Control Center kết nối ra $provider, nên máy chủ này không cần địa chỉ công khai.';
  }

  @override
  String chatOpenConsole(String provider) {
    return 'Mở console $provider';
  }

  @override
  String get chatOpenSetupGuide => 'Hướng dẫn thiết lập';

  @override
  String get chatFieldBotToken => 'Token bot';

  @override
  String get chatFieldAppToken => 'Token cấp ứng dụng';

  @override
  String get chatFieldConfigRefreshToken => 'Token cấu hình app';

  @override
  String chatFieldOptional(String label) {
    return '$label (tùy chọn)';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return 'Liên kết tài khoản $provider của tôi';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return 'Liên kết tài khoản $provider để tin nhắn bạn gửi ở đó được gắn với bạn.';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return 'Đã liên kết với $externalUserId';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return 'Liên kết tài khoản $provider';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return 'Gửi mã này cho bot $provider bằng tin nhắn trực tiếp. Chỉ dùng được một lần và hết hạn sau 15 phút.';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return 'Tài khoản $provider của bạn đã được liên kết — tin nhắn bạn gửi ở đó được gắn với bạn.';
  }

  @override
  String get chatLinkedAccounts => 'Tài khoản đã liên kết';

  @override
  String chatNoLinkedAccounts(String provider) {
    return 'Chưa ai liên kết tài khoản $provider.';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tài khoản đã liên kết',
      one: '1 tài khoản đã liên kết',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '$externalUserId · khớp theo email';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '$externalUserId · liên kết bằng mã';
  }

  @override
  String get chatUnlink => 'Hủy liên kết';

  @override
  String get chatCustomizeBot => 'Tùy chỉnh bot';

  @override
  String get chatCustomizeBotDescription =>
      'Đổi tên bot, thay nội dung bot giới thiệu về mình, hoặc đổi tên lệnh slash.';

  @override
  String get chatCustomizeBotUnavailable =>
      'Control Center cần token cấu hình app để chỉnh bot. Kết nối lại và kèm theo token.';

  @override
  String chatCreateAppTitle(String provider) {
    return 'Tạo app $provider';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'Control Center có thể tạo app $provider giúp bạn, với quyền và sự kiện đã được thiết lập sẵn. Bạn hoàn tất trên $provider, rồi dán thông tin xác thực vào đây.';
  }

  @override
  String get chatCreateApp => 'Tạo app';

  @override
  String get chatCreateAppCta => 'Tạo app giúp tôi';

  @override
  String get chatAppNameLabel => 'Tên app';

  @override
  String get chatBotDisplayNameLabel => 'Tên bot (thành viên gõ sau @)';

  @override
  String get chatDescriptionLabel => 'Mô tả ngắn';

  @override
  String get chatAgentDescriptionLabel => 'Bot nói nó có thể làm gì';

  @override
  String get chatCommandLabel => 'Lệnh slash';

  @override
  String get chatDirectMessages => 'Tin nhắn trực tiếp';

  @override
  String chatDirectMessagesHint(String provider) {
    return 'Cho phép thành viên trò chuyện với bot qua DM. Có thể cần gói $provider trả phí.';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return '$provider đã tạo app $appId.';
  }

  @override
  String chatRemainingSteps(String provider) {
    return 'Còn vài bước chỉ $provider mới làm được:';
  }

  @override
  String get chatStepAppToken => 'Tạo token cấp app';

  @override
  String get chatStepInstall => 'Cài app';

  @override
  String get chatOpenAppSettings => 'Mở cài đặt app';

  @override
  String get chatContinueToCredentials => 'Dán thông tin xác thực';

  @override
  String chatBotUpdated(String provider) {
    return 'Bot đã được cập nhật trên $provider.';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return '$provider đã thay đổi quyền của app. Cài lại app để các quyền có hiệu lực.';
  }

  @override
  String get chatReinstallApp => 'Cài lại app';

  @override
  String chatIconNotEditable(String provider) {
    return 'Chỉ có thể đổi biểu tượng bot trong cài đặt app của $provider.';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return 'Bạn cũng có thể tự tạo trên $provider — không cần token. Các cài đặt phía trên đi kèm theo liên kết.';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return 'Tạo trên $provider';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return '$provider đã mở trong trình duyệt với cấu hình điền sẵn. Tạo app ở đó, hoàn tất các bước rồi quay lại với token.';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return '$provider không báo app nào vừa được tạo, nên tùy chỉnh bot từ đây sẽ cần token cấu hình app sau.';
  }

  @override
  String get chatStepCreateApp => 'Tạo app từ cấu hình điền sẵn';

  @override
  String chatStepCreateAppHint(String provider) {
    return 'Chọn một không gian làm việc trên $provider rồi xác nhận.';
  }

  @override
  String get chatStepAppTokenHint =>
      'Basic information → app-level tokens, với scope connections:write.';

  @override
  String get chatStepInstallHint =>
      'Install app → sao chép bot user OAuth token.';

  @override
  String get aboutTitle => 'Giới thiệu';

  @override
  String get aboutAppVersion => 'Phiên bản app';

  @override
  String get aboutServerVersion => 'Máy chủ đã kết nối';

  @override
  String get aboutRpcCatalog => 'Danh mục RPC';

  @override
  String get aboutServerUnknown => 'Không được báo cáo';

  @override
  String get serverStaleTitle => 'Máy chủ đi kèm cũ hơn app này';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return 'cc_server đang chạy là $serverVersion trong khi app này là $appVersion. Khởi động lại app để dùng bản máy chủ đi kèm mới nhất; khi phát triển, xây lại bằng `dart build cli` trong apps/cc_server.';
  }

  @override
  String get updateCheckButton => 'Kiểm tra cập nhật';

  @override
  String get updateChecking => 'Đang kiểm tra cập nhật…';

  @override
  String get updateUpToDate => 'Bạn đang dùng phiên bản mới nhất';

  @override
  String get updateDeferredBusy =>
      'Đã có bản cập nhật nhưng đang ghi cuộc họp — sẽ nhắc sau khi kết thúc.';

  @override
  String get updateOpenedReleasesPage =>
      'Đã mở trang phát hành trên trình duyệt.';

  @override
  String get updateCheckFailed => 'Không kiểm tra được cập nhật';

  @override
  String updateAvailableVersion(String version) {
    return 'Phiên bản $version đã sẵn sàng.';
  }

  @override
  String get updateBannerTitle => 'Đã có Control Center mới';

  @override
  String get updateBannerRefresh => 'Tải lại';

  @override
  String get updateBlockedRecording =>
      'Tạm dừng tải lại khi đang ghi cuộc họp — sẽ tải lại khi kết thúc.';

  @override
  String get settingsScopeYou => 'Bạn';

  @override
  String get settingsScopeWorkspace => 'Không gian làm việc';

  @override
  String get settingsScopeServer => 'Máy chủ';

  @override
  String get settingsProfile => 'Hồ sơ & danh tính';

  @override
  String get settingsYourDevices => 'Thiết bị của bạn';

  @override
  String get settingsWorkspaceGeneral => 'Chung';

  @override
  String get settingsServerConnection => 'Kết nối & trạng thái';

  @override
  String get settingsModelProviders => 'Nhà cung cấp mô hình';

  @override
  String get settingsVoiceModels => 'Mô hình giọng nói & cuộc họp';

  @override
  String get settingsDiagnostics => 'Chẩn đoán & quyền riêng tư';

  @override
  String get settingsAbout => 'Giới thiệu';

  @override
  String get settingsProfileDescription =>
      'Tên, email và danh tính git của bạn trong không gian làm việc này. Chuyển không gian làm việc sẽ chuyển lớp phủ này; tên người dùng, đăng nhập và thiết bị vẫn ở trên tài khoản của bạn trong Bạn → Hồ sơ.';

  @override
  String get settingsServerConnectionDescription =>
      'Máy chủ mà máy khách này kết nối, và cách chia sẻ máy chủ này (mDNS, tunnel, relay).';

  @override
  String get settingsAboutDescription => 'Danh tính bản dựng và cập nhật.';

  @override
  String get settingsDiagnosticsDescription =>
      'Cách ly, lập chỉ mục, đồng bộ, ghi nhật ký và báo cáo sự cố cho bản cài này.';

  @override
  String get settingsWorkspaceGeneralDescription =>
      'Chính sách và quy ước mà mọi người trong không gian làm việc này cùng dùng.';

  @override
  String get settingsWorkspaceMeetingsDescription =>
      'Mẫu ghi chú và giọng đã lưu cho các cuộc họp trong không gian làm việc này.';

  @override
  String get settingsWorkspacePolicyLabel => 'Chính sách không gian làm việc';

  @override
  String get settingsWorkspacePolicyDescription =>
      'Áp dụng cho mọi thành viên và mọi agent trong không gian làm việc này.';

  @override
  String get settingsSecretGlobsLabel => 'Loại trừ đường dẫn bí mật';

  @override
  String get settingsSecretGlobsHelp =>
      'Một glob mỗi dòng. Các đường dẫn này bị ẩn với người xem và khách trên các bề mặt có mã, ngoài các mặc định sẵn có.';

  @override
  String get settingsReviewConcurrencyLabel => 'Phân tán review';

  @override
  String get settingsReviewConcurrencyHelp =>
      'Số reviewer chạy song song khi không chỉ định số lượng.';

  @override
  String get settingsReviewLevelLabel => 'Mức review';

  @override
  String get settingsReviewLevelHelp =>
      'Độ sâu review của AI và phần được báo ngay từ đầu. Không bỏ gì — mức nhẹ hơn gom các phát hiện nhỏ thay vì loại chúng.';

  @override
  String get reviewLevelLight => 'Nhẹ';

  @override
  String get reviewLevelBalanced => 'Cân bằng';

  @override
  String get reviewLevelThorough => 'Kỹ lưỡng';

  @override
  String get reviewLevelLightHint =>
      'Một reviewer. Chỉ báo ngay những gì thực sự quan trọng.';

  @override
  String get reviewLevelBalancedHint =>
      'Ba reviewer phụ trách QA, kiến trúc và triển khai.';

  @override
  String get reviewLevelThoroughHint =>
      'Thêm chuyên gia bảo mật và hiệu năng, báo mọi phát hiện.';

  @override
  String get askAiReviewAtLevel => 'Review ở mức khác';

  @override
  String reviewNitpicksGroup(int count) {
    return 'Góp ý nhỏ ($count)';
  }

  @override
  String get reviewFindingResolve => 'Đã sửa';

  @override
  String get reviewFindingResolveHint =>
      'Đánh dấu phát hiện này là đã sửa. Nó không còn tính vào review.';

  @override
  String get reviewFindingDismiss => 'Bỏ qua';

  @override
  String get reviewFindingDismissHint =>
      'Không phải vấn đề thật. Reviewer sẽ không gắn cờ mẫu này trên các PR sau.';

  @override
  String get reviewFindingReopen => 'Mở lại';

  @override
  String get reviewFindingStatusUndoLabel => 'Trạng thái phát hiện';

  @override
  String get reviewFindingDismissTitle => 'Bỏ qua phát hiện này';

  @override
  String get reviewFindingDismissReasonHint =>
      'Vì sao điều này không áp dụng? Reviewer sẽ đọc.';

  @override
  String reviewFindingStatusFailed(String error) {
    return 'Không cập nhật được phát hiện: $error';
  }

  @override
  String get reviewStaleTitle => 'Review này đã lỗi thời';

  @override
  String get reviewStaleBody =>
      'Pull request đã thay đổi kể từ lần review này. Phát hiện có thể trỏ tới mã không còn tồn tại.';

  @override
  String reviewStaleReviewedAt(String sha) {
    return 'Đã review tại $sha';
  }

  @override
  String get reviewStaleRerun => 'Review lại';

  @override
  String reviewStaleNotificationTitle(int prNumber) {
    return 'Review lỗi thời trên #$prNumber';
  }

  @override
  String reviewStaleNotificationBody(String title) {
    return '$title có commit mới kể từ lần review gần nhất.';
  }

  @override
  String get reviewCategorySecurity => 'Bảo mật';

  @override
  String get reviewCategoryStability => 'Ổn định';

  @override
  String get reviewCategoryDataIntegrity => 'Toàn vẹn dữ liệu';

  @override
  String get reviewCategoryCorrectness => 'Tính đúng';

  @override
  String get reviewCategoryPerformance => 'Hiệu năng';

  @override
  String get reviewCategoryMaintainability => 'Khả năng bảo trì';

  @override
  String get reviewEffortQuickWin => 'Nhanh gọn';

  @override
  String get reviewEffortModerate => 'Trung bình';

  @override
  String get reviewEffortHeavyLift => 'Nặng';

  @override
  String get reviewProposedFix => 'Sửa đề xuất';

  @override
  String get reviewAiAgentPrompt => 'Prompt cho AI agent';

  @override
  String get reviewCopyAiPrompt => 'Sao chép prompt';

  @override
  String get settingsWorkspaceAdminOnly =>
      'Chỉ quản trị viên không gian làm việc mới được thay đổi.';

  @override
  String get chatMyAccountsTitle => 'Tài khoản chat đã liên kết';

  @override
  String get settingsServerSso => 'Đăng nhập một lần';

  @override
  String get settingsServerSsoDescription =>
      'Đăng nhập SAML và OpenID Connect kèm cấp phát người dùng';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabledDescription =>
      'Người dùng có thể đăng nhập bằng nhà cung cấp này';

  @override
  String get ssoEnabledDescriptionOn =>
      'Đăng nhập đang hoạt động cho nhà cung cấp này';

  @override
  String get ssoIdpMetadataLabel => 'XML metadata IdP';

  @override
  String get ssoIdpMetadataHint => 'dán XML EntityDescriptor của IdP';

  @override
  String get ssoEmailAttributeLabel => 'Thuộc tính email';

  @override
  String get ssoDisplayNameAttributeLabel => 'Thuộc tính tên hiển thị';

  @override
  String get ssoGroupsAttributeLabel => 'Thuộc tính nhóm';

  @override
  String get ssoIssuerLabel => 'URL issuer';

  @override
  String get ssoClientIdLabel => 'Client ID';

  @override
  String get ssoGroupsClaimLabel => 'Claim nhóm';

  @override
  String get ssoAutoMemberLabel =>
      'Thêm người dùng vào mọi không gian làm việc khi đăng nhập lần đầu';

  @override
  String get ssoAutoMemberDescription =>
      'Tắt để yêu cầu lời mời cho từng không gian làm việc';

  @override
  String get ssoAllowJitLabel =>
      'Cấp phát người dùng chưa có khi đăng nhập lần đầu';

  @override
  String get ssoAllowJitDescription =>
      'Tắt để từ chối người dùng chưa có tài khoản';

  @override
  String get ssoAllowIdpInitiatedLabel =>
      'Chấp nhận đăng nhập không được yêu cầu (IdP khởi tạo)';

  @override
  String get ssoAllowIdpInitiatedDescription =>
      'Chỉ dành cho cổng IdP mở ứng dụng trực tiếp';

  @override
  String get ssoWantResponseSignedLabel => 'Yêu cầu envelope phản hồi đã ký';

  @override
  String get ssoWantResponseSignedDescription =>
      'Chữ ký assertion luôn bắt buộc';

  @override
  String get ssoTestConnectionButton => 'Kiểm tra kết nối';

  @override
  String get ssoTestConnectionOk => 'Kết nối thành công:';

  @override
  String get ssoCopySpMetadata => 'Sao chép metadata SP';

  @override
  String get ssoCopySpMetadataDone => 'Đã sao chép metadata SP vào clipboard';

  @override
  String get ssoSavedToast => 'Đã lưu cài đặt đăng nhập một lần';

  @override
  String get ssoUnavailable =>
      'Máy chủ này không cung cấp cài đặt đăng nhập một lần. Cập nhật binary máy chủ rồi thử lại.';

  @override
  String get ssoScimCardTitle => 'Cấp phát người dùng (SCIM)';

  @override
  String get ssoScimDescription =>
      'Hướng kết nối SCIM của nhà cung cấp danh tính tới endpoint bên dưới kèm bearer token. Khi thu hồi cấp phát, phiên và quyền không gian làm việc bị thu hồi trong vài giây. IdP phải truy cập được máy chủ (tunnel hoặc URL công khai).';

  @override
  String get ssoScimEndpoint => 'Endpoint SCIM';

  @override
  String get ssoScimEndpointUnknownOrigin =>
      'Đặt URL công khai của máy chủ hoặc bật tunnel trước';

  @override
  String get ssoScimRegenerate => 'Tạo lại token';

  @override
  String get ssoScimRegenerateConfirm =>
      'Tạo bearer token SCIM mới? Token cũ sẽ ngừng hoạt động ngay.';

  @override
  String get ssoScimTokenTitle => 'Bearer token';

  @override
  String get ssoScimTokenPresent => 'Đã cấu hình token';

  @override
  String get ssoScimTokenAbsent => 'Chưa có token — tạo một token để bật SCIM';

  @override
  String get ssoScimTokenOnce => 'Token SCIM (chỉ hiện một lần)';

  @override
  String ssoSignInWith(String provider) {
    return 'Đăng nhập bằng $provider';
  }

  @override
  String get ssoProbeFailed =>
      'Không kết nối được máy chủ đó cho đăng nhập một lần';

  @override
  String get ssoOpensBrowser => 'Mở trình duyệt để hoàn tất đăng nhập';

  @override
  String get ssoWaitingForBrowser => 'Đang chờ trình duyệt hoàn tất đăng nhập…';

  @override
  String get ssoBrowserOpenFailed =>
      'Không mở được trình duyệt cho đăng nhập một lần';

  @override
  String get ssoUseManualPairing =>
      'Đăng nhập bằng lời mời hoặc khóa ghép nối thay thế';

  @override
  String get ssoHideManualPairing => 'Ẩn ghép nối thủ công';

  @override
  String get ssoClientIdHint => 'Client công khai (PKCE) — không cần secret';

  @override
  String get ssoClientSecretLabel => 'Client secret (tùy chọn)';

  @override
  String get ssoClientSecretHintUnset =>
      'Chỉ cần cho client IdP kiểu confidential';

  @override
  String get ssoClientSecretHintSet => 'Đã lưu secret — để trống để giữ nguyên';

  @override
  String get ssoPairingToggle =>
      'Cho phép ghép nối thủ công (mã mời và khóa ghép nối)';

  @override
  String get ssoPairingToggleDescription =>
      'Tắt để chỉ tham gia qua đăng nhập một lần — thiết bị mới đến qua đăng nhập SSO; thiết bị hiện có vẫn dùng được';

  @override
  String get ssoPairConfirmTitle => 'Kết nối với máy chủ?';

  @override
  String ssoPairConfirmBody(String server) {
    return 'Đã nhận thông tin đăng nhập cho $server, nhưng ứng dụng này chưa bắt đầu đăng nhập. Kết nối với máy chủ này?';
  }

  @override
  String get ssoPairConfirmConnect => 'Kết nối';

  @override
  String get ssoPairConfirmCancel => 'Bỏ qua';

  @override
  String get forgeConnections => 'Lưu trữ mã';

  @override
  String get connect => 'Kết nối';

  @override
  String get disconnect => 'Ngắt kết nối';

  @override
  String get notConnected => 'Chưa kết nối';

  @override
  String get checkingConnection => 'Đang kiểm tra kết nối…';

  @override
  String forgeTokenTitle(String forge) {
    return 'Token $forge';
  }

  @override
  String get settingsAudio => 'Âm thanh';

  @override
  String get settingsAudioDescription =>
      'Micro, đọc chính tả, phát hiện cuộc họp và đầu ra cảnh âm.';

  @override
  String get audioDevicesSection => 'Thiết bị âm thanh';

  @override
  String get voiceInputBehaviorSection => 'Đọc chính tả và cuộc họp';

  @override
  String get audioOutputDeviceTitle => 'Thiết bị đầu ra';

  @override
  String get audioOutputDefaultHint =>
      'Mọi âm thanh của ứng dụng phát qua đầu ra mặc định của hệ thống.';

  @override
  String get audioOutputGone =>
      'Thiết bị đầu ra đã chọn không còn kết nối — hệ thống dùng đầu ra mặc định cho đến khi bạn chọn thiết bị khác.';

  @override
  String get reviewHubIntroBody =>
      'Agent phân tích diff, ánh xạ các vùng thay đổi và đưa ra kết luận đồng thuận.';

  @override
  String get reviewHubAlreadyRunning =>
      'Đã có review đang chạy cho pull request này';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return 'Từ lần review trước: $resolved đã xử lý · $added mới · $open còn mở';
  }

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return 'Đã review trước tại $sha';
  }

  @override
  String reviewArtifactFixAll(int count) {
    return 'Sửa $count phát hiện';
  }

  @override
  String reviewArtifactFixSelected(int count) {
    return 'Sửa $count mục đã chọn';
  }

  @override
  String reviewArtifactCommentSelected(int count) {
    return 'Bình luận $count mục đã chọn';
  }

  @override
  String get webConnectStayConnected => 'Giữ kết nối trên thiết bị này';

  @override
  String get webConnectStayConnectedDetail =>
      'Giữ kết nối trên thiết bị này (lưu khóa trong trình duyệt này)';

  @override
  String failedToCreateWorkspace(String error) {
    return 'Không tạo được không gian làm việc: $error';
  }

  @override
  String committedRelative(String relative) {
    return 'đã commit $relative';
  }

  @override
  String get selectAgents => 'Chọn agent';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agent',
      one: '1 agent',
    );
    return '$_temp0';
  }

  @override
  String get newConversation => 'Cuộc trò chuyện mới';

  @override
  String get untitledConversation => 'Cuộc trò chuyện chưa có tiêu đề';

  @override
  String get conversationTitleOptionalHint =>
      'Tùy chọn — để trống thì mô hình tiêu đề sẽ đặt tên tự động';

  @override
  String get contentSynthesizerUnavailable =>
      'Không có tác tử Content synthesizer hoặc nó không có trình chạy hoạt động';

  @override
  String get conversationNeedsAgent =>
      'Nhắc một tác tử bằng @ để bắt đầu cuộc trò chuyện này';

  @override
  String get conversationTitleGenerate => 'Tạo';

  @override
  String get conversationTitleNoMessages =>
      'Hãy gửi một tin nhắn trước. Tiêu đề được tạo từ tin nhắn đó.';

  @override
  String get conversationTitleGenerateFailed =>
      'Không thể tạo tiêu đề. Hãy thử lại.';

  @override
  String get startThread => 'Bắt đầu luồng';

  @override
  String get deleteSpaceConfirm =>
      'Xóa không gian này? Mọi tin nhắn sẽ bị mất.';

  @override
  String threadTabTitle(String title) {
    return 'Luồng: $title';
  }

  @override
  String threadReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trả lời',
      one: '1 trả lời',
    );
    return '$_temp0';
  }

  @override
  String threadLastReply(String time) {
    return 'Trả lời gần nhất $time';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Đăng nhập với $provider';
  }

  @override
  String get signInAgain => 'Đăng nhập lại';

  @override
  String get forgeSignInBannerTitle =>
      'Lưu trữ mã chưa được kết nối trong không gian làm việc này';

  @override
  String get forgeSignInBannerBody =>
      'Một phiên đăng nhập đã hết hạn hoặc bị thu hồi, hoặc không gian làm việc này dùng GitHub App riêng. Pull request, đánh giá và đồng bộ kho mã tạm dừng cho đến khi bạn đăng nhập.';

  @override
  String get forgeSignInBannerAction => 'Đăng nhập';

  @override
  String get ticketing => 'Phiếu';

  @override
  String get ticketingProviderHelp =>
      'Nơi lưu phiếu. Cục bộ giữ chúng trong Control Center.';

  @override
  String providerComingSoon(String provider) {
    return '$provider (sắp có)';
  }

  @override
  String get ticketProviderLocal => 'Cục bộ';

  @override
  String get providerApps => 'Ứng dụng nhà cung cấp';

  @override
  String get providerAppsDescription =>
      'Các ứng dụng mà chính máy chủ này đã đăng ký với từng nhà cung cấp. Mọi người đăng nhập qua chúng, và các tác vụ nền như webhook, thăm dò và đồng bộ chạy trên chúng, không bao giờ trên phiên đăng nhập của một người.';

  @override
  String get providerAppId => 'Id ứng dụng';

  @override
  String get providerPrivateKey => 'Khóa riêng';

  @override
  String get providerClientId => 'Id client';

  @override
  String get providerClientSecret => 'Bí mật client';

  @override
  String get providerCallbackUrl => 'URL callback';

  @override
  String get providerAppFullyConfigured =>
      'Máy chủ có thể hành động với tư cách của chính nó, và mọi người có thể đăng nhập.';

  @override
  String get providerAppServerOnly =>
      'Máy chủ có thể hành động với tư cách của chính nó. Thêm id client và bí mật để cho phép mọi người đăng nhập.';

  @override
  String get providerAppSignInOnly =>
      'Mọi người có thể đăng nhập. Công việc nền chuyển sang dùng thông tin đăng nhập của họ.';

  @override
  String providerAppInstalledOn(String accounts) {
    return 'Thông tin xác thực hoạt động. Đã cài trên: $accounts';
  }

  @override
  String get couldNotOpenBrowser =>
      'Không mở được trình duyệt. Sao chép liên kết và tự hoàn tất đăng nhập.';

  @override
  String get contextUsage => 'Sử dụng ngữ cảnh';

  @override
  String get contextUsageFull => 'đầy';

  @override
  String get contextUsageTokens => 'token';

  @override
  String get contextSeeMore => 'Xem thêm';

  @override
  String get contextSegmentSystemPrompt => 'Lời nhắc hệ thống';

  @override
  String get contextSegmentRules => 'Quy tắc';

  @override
  String get contextSegmentSkills => 'Kỹ năng';

  @override
  String get contextSegmentToolDefinitions => 'Định nghĩa công cụ';

  @override
  String get contextSegmentMcpTools => 'MCP và công cụ động';

  @override
  String get contextSegmentDeferredTools => 'Công cụ tải khi cần';

  @override
  String get contextSegmentSubagents => 'Định nghĩa subagent';

  @override
  String get contextSegmentMemory => 'Bộ nhớ';

  @override
  String get contextSegmentConversation => 'Hội thoại';

  @override
  String get contextSegmentRunner =>
      'Prompt của trình chạy, công cụ và công việc trong lượt';

  @override
  String get contextUsageMeasured => 'Do lần gọi mô hình gần nhất báo cáo';

  @override
  String get contextUsageEstimated =>
      'Ước tính cho đến khi một lần chạy báo cáo mức dùng';

  @override
  String get contextExplorerTitle => 'Ngữ cảnh';

  @override
  String get contextExplorerEverything => 'Tất cả';

  @override
  String get contextExplorerSelectPart => 'Chọn một phần để xem nội dung';

  @override
  String get contextExplorerUnavailable => 'Không có phân tích ngữ cảnh';

  @override
  String get contextRetry => 'Thử lại';

  @override
  String get settingsFieldOptional => 'Tùy chọn';

  @override
  String get settingsFilterHint => 'Lọc danh sách này';

  @override
  String get settingsValueNotAvailable => 'Chưa khả dụng';

  @override
  String get settingsNoEntriesYet => 'Chưa có gì';

  @override
  String get settingsChangedBadge => 'Đã đổi';

  @override
  String get ssoConnectionCardDescription =>
      'Chọn cách mọi người đăng nhập vào máy chủ này, rồi bật kết nối đó.';

  @override
  String get ssoUseSamlForSignIn => 'Dùng SAML để đăng nhập';

  @override
  String get ssoUseOidcForSignIn => 'Dùng OpenID Connect để đăng nhập';

  @override
  String get ssoSaveConnection => 'Lưu kết nối';

  @override
  String get ssoStateLive => 'Đang dùng';

  @override
  String get ssoStateConfiguredOff => 'Đã cấu hình, tắt';

  @override
  String get ssoStateOnIncomplete => 'Bật, chưa hoàn tất';

  @override
  String get ssoStateActive => 'Hoạt động';

  @override
  String get ssoStateAllowed => 'Được phép';

  @override
  String get ssoStateNoToken => 'Không có token';

  @override
  String get ssoSummaryDirectorySync => 'Đồng bộ thư mục';

  @override
  String get ssoSummaryManualPairing => 'Ghép thủ công';

  @override
  String get ssoNoMethodLiveNote =>
      'Chưa có phương thức đăng nhập nào đang dùng. Thiết bị mới tham gia bằng lời mời hoặc khóa ghép cho đến khi bạn cấu hình kết nối và bật nó.';

  @override
  String get ssoMethodSamlBlurb =>
      'Dành cho nhà cung cấp danh tính dùng SAML 2.0, như Okta, Entra ID hoặc Google Workspace.';

  @override
  String get ssoMethodOidcBlurb =>
      'Dành cho nhà cung cấp danh tính dùng OpenID Connect. Thường dễ thiết lập hơn trong hai cách.';

  @override
  String get ssoGroupIdentityProvider => 'Nhà cung cấp danh tính';

  @override
  String get ssoGroupIdentityProviderSamlDescription =>
      'Assertion đến từ đâu, và cách máy chủ này xác minh chúng.';

  @override
  String get ssoGroupIdentityProviderOidcDescription =>
      'Issuer mà máy chủ này tin tưởng, và client nó dùng để xác thực.';

  @override
  String get ssoSpEntityIdShortLabel => 'ID thực thể SP';

  @override
  String get ssoSpEntityIdDescription => 'Để trống để suy ra từ URL máy chủ.';

  @override
  String get ssoIssuerDescription =>
      'URL gốc phục vụ tài liệu discovery của nhà cung cấp.';

  @override
  String get ssoSecretStored => 'Đã lưu';

  @override
  String get ssoGroupHandoff => 'Những gì nhà cung cấp danh tính cần';

  @override
  String get ssoGroupHandoffDescription =>
      'Dán các giá trị này vào ứng dụng bạn đã tạo ở nhà cung cấp.';

  @override
  String get ssoOriginUnknownTitle =>
      'Máy chủ này chưa biết URL công khai của nó';

  @override
  String get ssoOriginUnknownBody =>
      'URL đăng nhập và callback được tạo từ đó, nên nhà cung cấp không thể tới máy chủ này cho đến khi bạn đặt một URL. Thêm URL công khai hoặc bật tunnel trong Máy chủ → Kết nối.';

  @override
  String get ssoAcsUrlLabel => 'URL dịch vụ tiếp nhận assertion (ACS)';

  @override
  String get ssoAcsUrlDescription => 'Nơi nhà cung cấp gửi assertion đã ký.';

  @override
  String get ssoSpEntityIdResolvedLabel => 'ID thực thể nhà cung cấp dịch vụ';

  @override
  String get ssoMetadataUrlLabel => 'URL metadata SP';

  @override
  String get ssoMetadataUrlDescription =>
      'Nhà cung cấp hỗ trợ nhập metadata có thể lấy từ đây.';

  @override
  String get ssoRedirectUriLabel => 'URI chuyển hướng';

  @override
  String get ssoRedirectUriDescription =>
      'Thêm vào danh sách URI chuyển hướng được phép của ứng dụng nhà cung cấp.';

  @override
  String get ssoSignInUrlLabel => 'URL đăng nhập';

  @override
  String get ssoSignInUrlDescription =>
      'Đưa người dùng tới đây để bắt đầu đăng nhập một lần.';

  @override
  String get ssoGroupAttributeMapping => 'Ánh xạ thuộc tính';

  @override
  String get ssoGroupAttributeMappingDescription =>
      'Claim nào mang từng trường. Giữ mặc định trừ khi nhà cung cấp đổi tên.';

  @override
  String get ssoGroupAccess => 'Quyền truy cập và vai trò';

  @override
  String get ssoGroupAccessDescription =>
      'Người đăng nhập thành công được phép làm gì.';

  @override
  String get ssoDefaultRoleShortLabel => 'Vai trò mặc định';

  @override
  String get ssoDefaultRoleDescription =>
      'Gán cho bất kỳ ai mà nhóm không khớp ánh xạ nào bên dưới.';

  @override
  String get ssoRoleMapShortLabel => 'Ánh xạ nhóm sang vai trò';

  @override
  String get ssoRoleMapDescription =>
      'Nhóm khớp đầu tiên được chọn. Không thể cấp Owner theo cách này.';

  @override
  String get ssoRoleMapGroupHint => 'Tên nhóm từ nhà cung cấp';

  @override
  String get ssoRoleMapAdd => 'Thêm ánh xạ';

  @override
  String get ssoRoleMapEmpty =>
      'Chưa có ánh xạ — mọi người nhận vai trò mặc định.';

  @override
  String get ssoAdvancedSummary =>
      'Độ lệch đồng hồ, đăng nhập do IdP khởi tạo, chính sách chữ ký';

  @override
  String get ssoClockSkewShortLabel => 'Độ lệch đồng hồ';

  @override
  String get ssoClockSkewDescription =>
      'Số giây dung sai cho dấu thời gian assertion. 90 phù hợp hầu hết nhà cung cấp.';

  @override
  String get ssoScimGenerate => 'Tạo token';

  @override
  String get ssoScimTokenOnceBody =>
      'Đã sao chép vào clipboard. Token chỉ hiện một lần và không khôi phục được, hãy dán vào nhà cung cấp ngay.';

  @override
  String get ssoPairingCardTitle => 'Ghép nối thủ công';

  @override
  String get ssoPairingCardDescription =>
      'Cách khác để vào máy chủ này: mã mời và khóa ghép nối, dành cho thiết bị không đi qua đăng nhập một lần.';

  @override
  String settingsCountOfTotal(int count, int total) {
    return '$count trên $total';
  }

  @override
  String get providersNoneConnectedNote =>
      'Chưa kết nối nhà cung cấp nào, nên runtime agent tích hợp không có nơi để chạy. Thêm API key hoặc đăng nhập một nhà cung cấp bên dưới.';

  @override
  String get providersFilterHint => 'Lọc nhà cung cấp';

  @override
  String get providersNoneMatch => 'Không có mục nào khớp bộ lọc này';

  @override
  String get providerDeniedHereTitle =>
      'Bị từ chối trong không gian làm việc này';

  @override
  String get providerDeniedHereBody =>
      'Agent ở đây không thể dùng nhà cung cấp này, dù đã kết nối. Các không gian làm việc khác không bị ảnh hưởng.';

  @override
  String get providerNeedsSignIn => 'Đăng nhập để dùng nhà cung cấp này';

  @override
  String get providerNeedsApiKey => 'Thêm API key để dùng nhà cung cấp này';

  @override
  String get providerApiKeyLabel => 'API key';

  @override
  String get providerGenerationDefaults => 'Mặc định nhà cung cấp';

  @override
  String get providerNoModelsYet =>
      'Chưa có model nào được báo cáo. Kết nối nhà cung cấp, rồi đồng bộ.';

  @override
  String get providerModelsFilterHint => 'Lọc model';

  @override
  String get adaptersNoneReadyNote =>
      'Không tìm thấy CLI runner nào trong danh mục trên máy này. Cài một cái, rồi làm mới.';

  @override
  String get adaptersFilterHint => 'Lọc runner';

  @override
  String get adaptersLaunchGroup => 'Khởi chạy';

  @override
  String get adaptersLaunchGroupDescription =>
      'Runner nhận gì khi agent khởi chạy nó. Có thể đặt trước khi cài CLI.';

  @override
  String get adaptersEnvNone => 'Chưa đặt';

  @override
  String adaptersEnvCount(int count) {
    return '$count đã đặt';
  }

  @override
  String get adapterArgumentsDescription =>
      'Được thêm vào dòng lệnh của runner mỗi lần khởi chạy.';

  @override
  String get settingsStateFailed => 'Thất bại';

  @override
  String get providerAppsGroupServer => 'Đóng vai trò máy chủ';

  @override
  String get providerAppsGroupServerDescription =>
      'Được dùng bởi các không gian làm việc theo ứng dụng đăng nhập của máy chủ này. Không gian làm việc dùng ứng dụng riêng sẽ thiết lập App của mình trong Không gian làm việc → Tích hợp.';

  @override
  String get providerAppsGroupPrConversations => 'Hội thoại pull request';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      'Cách nhà phát triển có thể trò chuyện với máy chủ này trên GitHub trong các không gian làm việc theo máy chủ này. Không gian làm việc dùng ứng dụng riêng có bot riêng trong Không gian làm việc → Tích hợp. Hoạt động không cần webhook hay URL công khai; máy chủ tự thăm dò.';

  @override
  String get providerAppBotLogin => 'Tên đăng nhập bot';

  @override
  String get providerAppBotLoginEmpty =>
      'Kiểm tra kết nối để xác định tên đăng nhập bot.';

  @override
  String get providerAppAskOnGitHub => 'Hỏi trên GitHub';

  @override
  String get providerAppAskOnGitHubHint =>
      'Nhắc tên đăng nhập bot ở trên trong bình luận pull request — hậu tố [bot] là tùy chọn — để yêu cầu review hoặc đặt câu hỏi, trả lời trong luồng review của bot, hoặc thêm nhãn `ai-review` để yêu cầu review.';

  @override
  String get providerAppsGroupSignIn => 'Đăng nhập cho mọi người';

  @override
  String get providerAppsGroupSignInDescription =>
      'Cho phép từng thành viên kết nối tài khoản riêng và nhận thông tin xác thực của mình.';

  @override
  String get providerAppCapActsAsServer => 'Đóng vai trò máy chủ';

  @override
  String get providerAppCapSignsIn => 'Đăng nhập cho mọi người';

  @override
  String get portLabel => 'Cổng';

  @override
  String get mcpBridgedToolsLabel => 'Công cụ';

  @override
  String get guardrailFamilyFiles => 'Tệp';

  @override
  String get guardrailFamilyGit => 'Git và pull request';

  @override
  String get guardrailFamilyMachine => 'Máy và mạng';

  @override
  String get guardrailFamilyControl => 'Bí mật và không gian làm việc';

  @override
  String get guardrailScopeFieldLabel => 'Quy tắc chỉnh sửa cho';

  @override
  String get guardrailScopeFieldDescription =>
      'Phạm vi hẹp hơn được ưu tiên hơn phạm vi rộng. Quy tắc đặt ở đây áp dụng chồng lên phần được kế thừa.';

  @override
  String get guardrailSetHere => 'Đặt tại đây';

  @override
  String get guardrailClearAllHere => 'Xóa tất cả';

  @override
  String get guardrailFamilyCommands => 'Lệnh';

  @override
  String get guardrailStandingApproval => 'Phê duyệt có thời hạn';

  @override
  String guardrailEntryAllow(String what) {
    return 'Cho phép: $what';
  }

  @override
  String guardrailEntryPrompt(String what) {
    return 'Hỏi trước: $what';
  }

  @override
  String guardrailEntryDeny(String what) {
    return 'Từ chối: $what';
  }

  @override
  String guardrailCoversBranches(String patterns) {
    return 'nhánh $patterns';
  }

  @override
  String guardrailCoversPaths(String patterns) {
    return 'đường dẫn $patterns';
  }

  @override
  String guardrailCoversHosts(String patterns) {
    return 'máy chủ $patterns';
  }

  @override
  String guardrailCoversCommands(String patterns) {
    return 'lệnh $patterns';
  }

  @override
  String guardrailCoversTools(String names) {
    return 'công cụ $names';
  }

  @override
  String guardrailCoversCommandPrefix(String prefix) {
    return 'lệnh bắt đầu bằng $prefix';
  }

  @override
  String guardrailCoversMaxCount(String count) {
    return 'tối đa $count cùng lúc';
  }

  @override
  String guardrailCoversMaxCents(String amount) {
    return 'tối đa $amount xu';
  }

  @override
  String get guardrailCoversEverything => 'mọi thao tác thuộc loại này';

  @override
  String guardrailEntryGivenBy(String name) {
    return 'bởi $name';
  }

  @override
  String guardrailEntryEnds(String time) {
    return 'kết thúc $time';
  }

  @override
  String get guardrailEntryNoEnd => 'cho đến khi thu hồi';

  @override
  String guardrailRevokeEntry(String entry) {
    return 'Thu hồi: $entry';
  }

  @override
  String get guardrailRevokeFailed => 'Không thể thu hồi. Vui lòng thử lại.';

  @override
  String get guardrailEntryInactive => 'không có hiệu lực khi bị từ chối';

  @override
  String guardrailClassPartlyAllowed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Được cho phép trong $count trường hợp bên dưới',
      one: 'Được cho phép trong 1 trường hợp bên dưới',
    );
    return '$_temp0';
  }

  @override
  String guardrailStandingFromWorkspace(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count phê duyệt có thời hạn cho toàn bộ không gian làm việc cũng áp dụng tại đây.',
      one:
          '1 phê duyệt có thời hạn cho toàn bộ không gian làm việc cũng áp dụng tại đây.',
    );
    return '$_temp0';
  }

  @override
  String guardrailStandingInNarrowerScopes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count phê duyệt có thời hạn được đặt cho các Space hoặc Agent riêng lẻ. Chọn Space hoặc Agent ở trên để xem.',
      one:
          '1 phê duyệt có thời hạn được đặt cho một Space hoặc Agent. Chọn Space hoặc Agent ở trên để xem.',
    );
    return '$_temp0';
  }

  @override
  String get sandboxingCardLabel => 'Sandbox';

  @override
  String get sandboxingCardDescription =>
      'Agent có chạy cách ly khỏi máy này hay không, và agent đã cách ly vẫn có thể truy cập những gì.';

  @override
  String get sandboxBackendNoneActive => 'Host, không cách ly';

  @override
  String get sandboxSummaryHost => 'Host';

  @override
  String get sandboxGroupIsolation => 'Cách ly';

  @override
  String get sandboxGroupIsolationDescription =>
      'Nơi tiến trình và thao tác ghi tệp của agent thực sự diễn ra.';

  @override
  String get sandboxGroupAgentActions => 'Những gì agent được phép làm';

  @override
  String get sandboxGroupAgentActionsDescription =>
      'Việc push, mở pull request và truy cập mạng được cho phép, cần hỏi trước hay bị từ chối được thiết lập trong quyền của agent.';

  @override
  String get sandboxBackendFieldDescription =>
      'Tự chọn loại mạnh nhất mà máy này hỗ trợ. Ghim một loại để tránh bị đổi khi bạn không để ý.';

  @override
  String get sandboxSummaryInForce => 'Đang áp dụng';

  @override
  String get rigsInstallHintLabel => 'Cách cài đặt';

  @override
  String get rigsStarting => 'Đang khởi động';

  @override
  String get rigsResidentMemory => 'Bộ nhớ thường trú';

  @override
  String get installedLabel => 'Đã cài';

  @override
  String get notInstalledLabel => 'Chưa cài';

  @override
  String ssoOtherKindUnsaved(String method) {
    return '$method có thay đổi chưa lưu';
  }

  @override
  String get collapseComment => 'Thu gọn bình luận';

  @override
  String get expandComment => 'Mở rộng bình luận';

  @override
  String get suggestedChange => 'Thay đổi đề xuất';

  @override
  String get emptyComment => 'Bình luận trống';

  @override
  String repliesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trả lời',
      one: '1 trả lời',
    );
    return '$_temp0';
  }

  @override
  String diffFileUnresolvedConversations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cuộc hội thoại chưa giải quyết',
      one: '1 cuộc hội thoại chưa giải quyết',
    );
    return '$_temp0';
  }

  @override
  String get pendingReview => 'Review đang chờ';

  @override
  String failedToResolveConversation(String error) {
    return 'Không thể cập nhật cuộc hội thoại: $error';
  }

  @override
  String get addSingleComment => 'Thêm bình luận đơn';

  @override
  String get addToReview => 'Thêm vào review';

  @override
  String get startAReview => 'Bắt đầu review';

  @override
  String get commentModeAgent => 'Agent';

  @override
  String get commentModeComment => 'Bình luận';

  @override
  String get commentModeReview => 'Review';

  @override
  String get commentDestination => 'Nơi gửi bình luận';

  @override
  String get commentHintAgent => 'Gửi cho tác nhân…';

  @override
  String get commentHintReview => 'Thêm vào review…';

  @override
  String get reviewNeedsABody =>
      'Viết tóm tắt hoặc xếp hàng một bình luận nội tuyến trước';

  @override
  String get reviewSubmitted => 'Đã gửi review';

  @override
  String get finishYourReview => 'Hoàn tất review';

  @override
  String get commentVerdict => 'Bình luận';

  @override
  String pendingCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bình luận đang chờ',
      one: '1 bình luận đang chờ',
    );
    return '$_temp0';
  }

  @override
  String andNMore(int count) {
    return 'và $count nữa';
  }

  @override
  String get queuedCommentHint => 'Bình luận này được gửi khi bạn nộp review.';

  @override
  String commentOnLinesRange(int start, int end) {
    return 'Dòng $start đến $end';
  }

  @override
  String get claudeAccountsTitle => 'Tài khoản Claude Code';

  @override
  String get claudeAccountsDescription =>
      'Mỗi tài khoản là một lần đăng nhập Claude Code riêng. Các lần chạy dùng các tài khoản gắn bên dưới, theo thứ tự này.';

  @override
  String get claudeAccountsEmpty => 'Chưa có tài khoản';

  @override
  String get claudeAccountAdd => 'Thêm tài khoản';

  @override
  String get claudeAccountSignIn => 'Đăng nhập';

  @override
  String get claudeAccountSignInAgain => 'Đăng nhập lại';

  @override
  String get claudeAccountSignInHint =>
      'Chạy lệnh này trong terminal trên máy chủ. Nó mở trình duyệt để hoàn tất đăng nhập và ghi thông tin xác thực vào thư mục của tài khoản này.';

  @override
  String get claudeAccountSignedOut => 'Đã đăng xuất';

  @override
  String get claudeAccountExpired => 'Đăng nhập đã hết hạn';

  @override
  String claudeAccountExpiredDetail(String when) {
    return 'Đăng nhập hết hạn lúc $when. Đăng nhập lại để dùng tài khoản này.';
  }

  @override
  String get claudeAccountMakeDefault => 'Đặt làm mặc định';

  @override
  String get claudeAccountDefault => 'Mặc định';

  @override
  String claudeAccountRemoveConfirm(String label) {
    return 'Xóa $label?';
  }

  @override
  String get claudeAccountRemoveDetail =>
      'Thao tác này đăng xuất tài khoản và xóa thư mục của nó trên máy chủ. Bản thân lần đăng nhập không bị ảnh hưởng.';

  @override
  String claudeAccountStatusUnknown(String error) {
    return 'Không kiểm tra được tài khoản này: $error';
  }

  @override
  String claudeAccountUsedPercent(String percent) {
    return 'Đã dùng $percent%';
  }

  @override
  String get accountPoolStrategy => 'Luân phiên';

  @override
  String get accountPoolPinned => 'Ghim';

  @override
  String get accountPoolRoundRobin => 'Xoay vòng';

  @override
  String get accountPoolSerial => 'Từng cái một';

  @override
  String get accountPoolPinnedHint =>
      'Luôn bắt đầu từ tài khoản đầu. Các tài khoản còn lại làm dự phòng nếu tài khoản đó thất bại.';

  @override
  String get accountPoolRoundRobinHint =>
      'Phân tán các lần chạy giữa các tài khoản, chuyển sang tài khoản tiếp theo mỗi lần gửi.';

  @override
  String get accountPoolSerialHint =>
      'Dùng hết tài khoản đầu trước khi chuyển sang tài khoản tiếp.';

  @override
  String get accountPoolMoveUp => 'Chuyển lên';

  @override
  String get accountPoolMoveDown => 'Chuyển xuống';

  @override
  String get accountPoolUsingAll =>
      'Chưa gắn gì — mọi tài khoản đều được dùng, theo thứ tự này.';

  @override
  String get accountPoolInheriting =>
      'Đang kế thừa tài khoản của không gian làm việc.';

  @override
  String get accountPoolResetToWorkspace =>
      'Đặt lại theo tài khoản của không gian làm việc';

  @override
  String accountPoolCoolingOff(String when) {
    return 'hết hạn mức đến $when';
  }

  @override
  String get accountPoolSignedOut => 'đã đăng xuất';

  @override
  String get accountPoolExpired => 'đăng nhập hết hạn';

  @override
  String accountPoolLoadFailed(String error) {
    return 'Không tải được luân phiên: $error';
  }

  @override
  String get providerSignedInAccount => 'tài khoản đã đăng nhập';

  @override
  String get agentAccountsTab => 'Tài khoản';

  @override
  String get agentClaudeAccountsNoticeTitle => 'Nhiều tài khoản Claude Code';

  @override
  String agentClaudeAccountsNoticeBody(int count) {
    return 'Runner này đăng nhập bằng một trong $count tài khoản Claude Code trên máy này. Chọn tài khoản, hoặc luân phiên giữa chúng, trong tab Tài khoản.';
  }

  @override
  String get agentAccountsDescription =>
      'Tài khoản mà các lần chạy của agent này dùng. Mỗi khối bắt đầu bằng cách kế thừa lựa chọn của không gian làm việc.';

  @override
  String get agentAccountsNothingToRotate =>
      'Không có gì để luân phiên — hãy kết nối thêm một tài khoản hoặc khóa trước.';

  @override
  String failedToPostReply(String error) {
    return 'Không đăng được phản hồi: $error';
  }

  @override
  String failedToPostComment(String error) {
    return 'Không đăng được bình luận: $error';
  }

  @override
  String commentOnLine(int line) {
    return 'Dòng $line';
  }

  @override
  String get viewInDiff => 'Xem trong diff';

  @override
  String get subscriptionUsagePreviousAccount => 'Tài khoản trước';

  @override
  String get subscriptionUsageNextAccount => 'Tài khoản sau';

  @override
  String inReplyTo(String path) {
    return 'Trả lời $path';
  }

  @override
  String get subscriptionUsageNoneReported =>
      'Chưa có mức dùng được báo cho tài khoản này.';

  @override
  String get subscriptionUsageCredits => 'Tín dụng';

  @override
  String get subscriptionUsageBalance => 'Số dư';

  @override
  String subscriptionUsageBalanceLeft(String amount) {
    return 'Còn $amount';
  }

  @override
  String get reviewHubStaticRule => 'Quy tắc tĩnh';

  @override
  String get reviewHubStarted => 'Đã bắt đầu review';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return 'Phát hiện bởi quy tắc xác định ($rule) trên một dòng mà pull request này thêm — không phải bởi agent reviewer.';
  }

  @override
  String get prReviewArtifactTab => 'Review PR';

  @override
  String get prReviewRunning => 'Đang review pull request này…';

  @override
  String get prReviewStarting => 'Đang bắt đầu review…';

  @override
  String get prReviewStartingBody =>
      'Đang chuẩn bị cây làm việc của pull request này. Các reviewer sẽ bắt đầu ngay khi sẵn sàng.';

  @override
  String get prReviewFailed => 'Review thất bại.';

  @override
  String get prReviewRerunning => 'Đang review lại…';

  @override
  String get prReviewNoOpenFindings => 'Không có phát hiện đang mở';

  @override
  String prReviewOpenFindings(int count) {
    return '$count phát hiện đang mở';
  }

  @override
  String subscriptionUsageSpend(String used, String limit) {
    return '$used trên $limit';
  }

  @override
  String reviewCommentsPosted(int posted, int skipped, int failed) {
    return 'Đã đăng $posted bình luận với tư cách bot. Bỏ qua $skipped (không có neo tệp), $failed thất bại.';
  }

  @override
  String reviewFindingsOutOfDiff(int count, String files) {
    return '$count phát hiện nhắm vào mã mà pull request này không thay đổi ($files). GitHub chỉ chấp nhận bình luận nội tuyến trên diff.';
  }

  @override
  String get reviewRailReport => 'Báo cáo';

  @override
  String get reviewNoFindingsTitle => 'Chưa có phát hiện';

  @override
  String get reviewNoFindingsHint => 'Phát hiện sẽ hiện ở đây khi agent đăng.';

  @override
  String reviewShowDismissed(int count) {
    return 'Hiện $count đã bỏ qua';
  }

  @override
  String reviewHideDismissed(int count) {
    return 'Ẩn $count đã bỏ qua';
  }

  @override
  String reviewDisagreementsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Phát hiện $count bất đồng của reviewer',
      one: 'Phát hiện 1 bất đồng của reviewer',
    );
    return '$_temp0';
  }

  @override
  String get reviewFilterKind => 'Loại';

  @override
  String get reviewFilterStatus => 'Trạng thái';

  @override
  String get reviewKindBug => 'Lỗi';

  @override
  String get reviewKindSuggestion => 'Đề xuất';

  @override
  String get reviewKindRecommendation => 'Khuyến nghị';

  @override
  String get reviewKindQuestion => 'Câu hỏi';

  @override
  String get reviewKindTicket => 'Phiếu';

  @override
  String get spaceAllPrsMerged =>
      'Tất cả yêu cầu kéo trong không gian này đã được hợp nhất. Lưu trữ không gian này?';

  @override
  String get spaceKeepAfterMerge => 'Không, giữ không gian này';

  @override
  String get spaceKeepAfterMergeHint =>
      'Bạn sẽ không được hỏi lại về không gian này.';

  @override
  String get archiveSpace => 'Lưu trữ không gian';

  @override
  String get archivedSpaces => 'Không gian đã lưu trữ';

  @override
  String get archivedSpacesEmpty => 'Không có không gian đã lưu trữ';

  @override
  String get restoreSpace => 'Khôi phục';

  @override
  String get archivedConversations => 'Cuộc trò chuyện đã lưu trữ';

  @override
  String get archivedConversationsEmpty =>
      'Không có cuộc trò chuyện đã lưu trữ';

  @override
  String get restoreConversation => 'Khôi phục';

  @override
  String archivedWhen(String time) {
    return 'Đã lưu trữ $time';
  }

  @override
  String get deleteSpacePermanently => 'Xóa vĩnh viễn';

  @override
  String get renameSpace => 'Đổi tên không gian';

  @override
  String get renameConversation => 'Đổi tên cuộc trò chuyện';

  @override
  String get spaceActions => 'Thao tác không gian';

  @override
  String get conversationActions => 'Thao tác hội thoại';

  @override
  String get editSpaceRepos => 'Sửa kho lưu trữ';

  @override
  String get editSpaceReposTitle => 'Kho lưu trữ của không gian';

  @override
  String get editSpaceReposWarning =>
      'Thêm kho lưu trữ sẽ checkout vào không gian này; gỡ một kho sẽ xóa thư mục của nó.';

  @override
  String get agentSectionIdentity => 'Danh tính';

  @override
  String get agentSectionRuntime => 'Runtime';

  @override
  String get agentSectionGuardrails => 'Rào chắn';

  @override
  String orgChartReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cấp dưới',
      one: '1 cấp dưới',
    );
    return '$_temp0';
  }

  @override
  String get teamsFilterHint => 'Lọc nhóm…';

  @override
  String get teamsSummaryWithLeader => 'Có trưởng nhóm';

  @override
  String teamCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nhóm',
      one: '1 nhóm',
      zero: 'Không có nhóm',
    );
    return '$_temp0';
  }

  @override
  String agentDeleteLongDescription(String name) {
    return 'Xóa $name sẽ gỡ hồ sơ, liên kết skill và lịch sử chạy. Không thể hoàn tác.';
  }

  @override
  String get resetToDefault => 'Đặt lại mặc định';

  @override
  String get newAgent => 'Agent mới';

  @override
  String get newSkill => 'Skill mới';

  @override
  String get newItemAction => 'Mới';

  @override
  String get zoomIn => 'Phóng to';

  @override
  String get zoomOut => 'Thu nhỏ';

  @override
  String get resetZoom => 'Đặt lại thu phóng';

  @override
  String get imageHostedOnGitHub => 'Hình ảnh lưu trên GitHub';

  @override
  String get imageOpenExternally => 'Hình ảnh · mở bên ngoài';

  @override
  String get memoryScopeAll => 'Tất cả phạm vi';

  @override
  String get memoryScopeWorkspace => 'Toàn không gian làm việc';

  @override
  String get memoryScopeFilterLabel => 'Lọc theo phạm vi';

  @override
  String memoryScopeRepoTooltip(String repo) {
    return 'Giới hạn trong kho $repo';
  }

  @override
  String get toolScreenshot => 'Ảnh chụp từ agent';

  @override
  String get toolImageUnavailable => 'Không có hình ảnh';

  @override
  String toolImagesUnavailable(int count) {
    return '$count hình ảnh không khả dụng';
  }

  @override
  String get shakeUnavailable => 'Không thể lắc trên máy chủ này';

  @override
  String get shakeNothing =>
      'Không có gì để lắc — các lượt gần đây được bảo vệ';

  @override
  String shakeDone(int tokens) {
    return 'Đã giải phóng khoảng $tokens token';
  }

  @override
  String get compactionDivider => 'Đã nén';

  @override
  String compactionDividerCount(int count) {
    return 'Đã nén · $count tin nhắn đã gộp';
  }

  @override
  String get composerDropToAttach => 'Thả để đính kèm';

  @override
  String get composerAttachmentUploading => 'Đang tải lên…';

  @override
  String get composerAttachmentReady => 'Sẵn sàng';

  @override
  String get composerAttachmentUploadFailed => 'Tải lên thất bại';

  @override
  String composerAttachmentTooLarge(String limit) {
    return 'Tệp vượt quá giới hạn $limit';
  }

  @override
  String get composerAttachmentUnreadable => 'Không đọc được tệp này';

  @override
  String get composerAttachmentWaitForUploads =>
      'Đợi tệp đính kèm tải lên xong';

  @override
  String get composerAttachmentResolveFailures =>
      'Thử tải lại hoặc xóa tệp đính kèm tải lên thất bại trước khi gửi';

  @override
  String get attachmentUnavailable => 'Tệp đính kèm không khả dụng';

  @override
  String get attachmentUnavailableDetail =>
      'Tệp đính kèm này không còn trong bộ nhớ. Đính kèm lại để xem trước.';

  @override
  String get attachmentPreviewFailed => 'Không mở được tệp này';

  @override
  String get attachmentPreviewUnsupported =>
      'Không xem trước được loại tệp này';

  @override
  String get attachmentTooLargeToPreview => 'Quá lớn để xem trước';

  @override
  String get attachmentOpenExternally => 'Mở trong ứng dụng mặc định';

  @override
  String get asideEmpty => 'Chưa có gì để làm việc';

  @override
  String get asideFailed => 'Không lấy được câu trả lời';

  @override
  String get handoffTitle => 'Chuyển giao';

  @override
  String get asideTitle => 'Câu hỏi phụ';

  @override
  String get attachFilesOrDrop => 'Đính kèm tệp — hoặc thả vào đây';

  @override
  String composerExpand(String shortcut) {
    return 'Mở rộng trình soạn thảo ($shortcut)';
  }

  @override
  String composerCollapse(String shortcut) {
    return 'Thu gọn trình soạn thảo ($shortcut)';
  }

  @override
  String get guidedGoalTitle => 'Làm rõ mục tiêu';

  @override
  String get guidedGoalIntro =>
      'Agent làm việc không giám sát cần biết chính xác khi nào thì xong. Vài câu hỏi trước.';

  @override
  String get guidedGoalAnswerHint => 'Câu trả lời của bạn';

  @override
  String get guidedGoalNext => 'Tiếp';

  @override
  String get guidedGoalStart => 'Bắt đầu mục tiêu';

  @override
  String get guidedGoalSkip => 'Bỏ qua và chạy như đã viết';

  @override
  String guidedGoalStillMissing(String items) {
    return 'Vẫn chưa xác định: $items';
  }

  @override
  String get conversationTreeTitle => 'Cây hội thoại';

  @override
  String conversationTreeBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nhánh',
      one: '1 nhánh',
    );
    return '$_temp0';
  }

  @override
  String get conversationTreeSwitch => 'Tiếp tục từ đây';

  @override
  String get conversationTreeFork => 'Tách sang hội thoại mới';

  @override
  String get conversationTreeCurrent => 'Trên nhánh này';

  @override
  String get conversationTreeEmpty => 'Chưa có gì';

  @override
  String get conversationTreeForked => 'Đã tách sang hội thoại mới';

  @override
  String get conversationTreeSwitched => 'Đang tiếp tục từ tin nhắn đó';

  @override
  String exportSaved(String path) {
    return 'Đã lưu vào $path';
  }

  @override
  String get exportFailed => 'Không ghi được bản xuất';

  @override
  String get contextCommandNoAgent =>
      'Không có agent trong hội thoại này, nên không có cửa sổ ngữ cảnh để mở';

  @override
  String contextCommandNoSuchAgent(String name, String names) {
    return 'Không có agent tên “$name” trong hội thoại này. Thử: $names';
  }

  @override
  String get dumpCopied => 'Đã sao chép bản ghi vào bảng tạm';

  @override
  String get messageQueueHint => 'Tiếp tục gõ để xếp hàng thay đổi tiếp theo';

  @override
  String get steerNow => 'Điều hướng';

  @override
  String get steerForce => 'Dừng và gửi';

  @override
  String get steeringQueueLabel => 'Tin nhắn điều hướng đang chờ';

  @override
  String get steeringDeliverUnavailable =>
      'Hiện không có agent đang chạy để nhận — tin vẫn được xếp hàng.';

  @override
  String get reorderSteeringCard => 'Sắp xếp lại tin nhắn chờ';

  @override
  String get editSteeringCard => 'Sửa tin nhắn chờ';

  @override
  String get deleteSteeringCard => 'Xóa tin nhắn chờ';

  @override
  String get steeringBadge => 'Đã điều hướng';

  @override
  String get settingsSandboxLabel => 'Sandbox';

  @override
  String get sandboxExecGrantsTitle => 'Quyền chạy chương trình';

  @override
  String get sandboxExecGrantsSubtitle =>
      'Chương trình agent được chạy từ bản làm việc của các kho lưu trữ. Mỗi mục đã được bạn duyệt khi sandbox hỏi.';

  @override
  String get sandboxExecGrantsEmpty =>
      'Chưa ghi nhận quyết định nào. Bạn sẽ được hỏi lần đầu agent cần chạy chương trình từ bản làm việc của nó.';

  @override
  String get sandboxExecGrantRevoke => 'Thu hồi';

  @override
  String get sandboxExecGrantAllowed => 'Cho phép';

  @override
  String get sandboxExecGrantBlocked => 'Chặn';

  @override
  String get sandboxExecGrantRevokeConfirmTitle => 'Thu hồi quyết định này?';

  @override
  String get sandboxExecGrantRevokeConfirmBody =>
      'Bạn sẽ được hỏi lại lần sau khi agent cần chạy chương trình từ bản sao này.';

  @override
  String get sandboxExecGrantsSearchHint => 'Tìm đường dẫn';

  @override
  String get sandboxExecGrantsNoMatch => 'Không có quyền nào khớp với tìm kiếm';

  @override
  String get demoBadgeLabel => 'Demo';

  @override
  String get demoFilePickerTitle => 'Tệp demo';

  @override
  String get demoFilePickerBody =>
      'Demo giả lập tải lên: chọn bất kỳ tệp nào để đính kèm vào tin nhắn, không ghi đĩa.';

  @override
  String get demoFilePickerAttach => 'Đính kèm';

  @override
  String get demoReadOnlySave => 'Chỉ đọc trong demo';

  @override
  String get demoBadgeTooltip =>
      'Bạn đang xem bản demo. Dữ liệu là hư cấu và các agent chạy theo kịch bản.';

  @override
  String get demoFirstRunTitle => 'Bạn đang ở bản demo trực tiếp';

  @override
  String demoFirstRunBody(int minutes) {
    return 'Đây là ứng dụng thật chạy trên mã thật — chỉ dữ liệu là bịa. Agent phát các lần chạy thật từ kịch bản, nên không gửi tới mô hình và không chạy trên máy nào. Không gian làm việc chỉ của bạn và biến mất sau $minutes phút.';
  }

  @override
  String get demoFirstRunDismiss => 'Đã hiểu';

  @override
  String get demoTourTitle => 'Xem đâu trước';

  @override
  String get demoTourSubtitle => 'Bốn chỗ cho thấy ứng dụng thực sự làm gì.';

  @override
  String get demoTourSkip => 'Bỏ qua';

  @override
  String get demoTourStarRepo => 'Gắn sao trên GitHub';

  @override
  String get demoTourOpen => 'Mở';

  @override
  String get demoTourSpacesTitle => 'Nói chuyện với agent';

  @override
  String get demoTourSpacesBody =>
      'Gửi tin nhắn trong một space và xem run được stream vào — suy nghĩ, lệnh gọi công cụ và chi phí, đúng như một run thật hiển thị.';

  @override
  String get demoTourReviewTitle => 'Đánh giá một pull request';

  @override
  String get demoTourReviewBody =>
      'Mở #412. Để lại bình luận nội tuyến hoặc gửi đánh giá; lời của bạn vào luồng thảo luận và ở lại đó.';

  @override
  String get demoTourTicketsTitle => 'Theo dõi công việc';

  @override
  String get demoTourTicketsBody =>
      'Phiếu, việc cần làm và kế hoạch được liên kết với cùng các cuộc trò chuyện mà agent đang có.';

  @override
  String get demoTourInboxTitle => 'Xem toàn bộ vận hành';

  @override
  String get demoTourInboxBody =>
      'Mọi cảnh báo từ mọi trụ cột vào một hộp thư đến — đánh giá, phiếu, run và cuộc họp.';

  @override
  String get demoUnavailableTitle => 'Không có trong bản demo';

  @override
  String get demoUnavailableTerminal =>
      'Terminal chạy một shell thật trên máy chủ. Bản demo không có bề mặt thực thi nào — đó là lý do nó an toàn để mở cho công chúng.';

  @override
  String get demoUnavailableRig =>
      'Enclosure là máy ảo dùng một lần do agent điều khiển. Bản demo không khởi động cái nào: endpoint công khai có thể khởi động VM thì không còn là demo.';

  @override
  String get demoUnavailableEditor =>
      'Trình soạn thảo trong trình duyệt chạy tiến trình code-server trên một checkout thật. Bản demo không có cả hai.';

  @override
  String get demoUnavailableFeeds =>
      'Bản demo đọc feed thật, nhưng danh sách đăng ký là cố định. Thêm hoặc xóa feed bị tắt ở đây.';

  @override
  String get demoUnavailableForge =>
      'Bản demo không giữ thông tin đăng nhập và không bao giờ liên hệ GitHub, GitLab hay Linear. Các pull request là dữ liệu mẫu, và bình luận của bạn trên đó được lưu cục bộ.';

  @override
  String get demoUnavailableModels =>
      'Bản demo không gọi mô hình nào. Run của agent là phát lại theo kịch bản, nên không tốn chi phí và không đến nhà cung cấp.';

  @override
  String get demoUnavailableMcp =>
      'Bề mặt công cụ MCP không được gắn trên bản demo, nên không client bên ngoài nào gắn vào được.';

  @override
  String get demoUnavailableRepos =>
      'Bản demo không checkout mã và không chạy git. Kho lưu trữ bạn thấy là dữ liệu mẫu đứng sau các pull request.';

  @override
  String get demoUnavailableSkills =>
      'Cài skill sẽ tải và quét mã. Bản demo không tải gì.';

  @override
  String get demoUnavailableSso =>
      'Đăng nhập một lần là cấu hình máy chủ. Bản demo đăng nhập bạn như khách tạm thời.';

  @override
  String get demoUnavailableAudio =>
      'Ghi âm và đọc chính tả cần thu âm và mô hình giọng nói trên máy chủ. Bản demo không có cả hai, nên cuộc họp chỉ là bản ghi lời, không phát lại.';

  @override
  String get demoUnavailableServerAdmin =>
      'Đây là quản trị máy chủ. Bản demo cấp cho mỗi khách một không gian làm việc dùng một lần và không gì hơn.';

  @override
  String get demoUnavailablePipelines =>
      'Pipeline không thể chạy ở đây. Khách có thể viết bước bash rồi chạy thủ công hoặc qua trình kích hoạt sự kiện là đang thực thi mã trên máy chủ này.';

  @override
  String get settingsBackupRestore => 'Sao lưu và khôi phục';

  @override
  String get settingsBackupRestoreDescription =>
      'Ảnh chụp mọi cơ sở dữ liệu trên máy chủ này, cộng xuất, nhập và xóa cho một không gian làm việc.';

  @override
  String get backupSnapshotsLabel => 'Ảnh chụp cài đặt';

  @override
  String get backupSnapshotsExplainer =>
      'Ảnh chụp sao chép mọi cơ sở dữ liệu vào thư mục có dấu thời gian trên máy chủ. Khôi phục cả cài đặt nghĩa là sao chép thư mục đó trở lại khi máy chủ đã dừng; một không gian làm việc có thể được khôi phục từ đây.';

  @override
  String get backupNowAction => 'Sao lưu ngay';

  @override
  String backupSnapshotWritten(String path) {
    return 'Đã ghi ảnh chụp vào $path';
  }

  @override
  String get backupNoSnapshots =>
      'Chưa có ảnh chụp toàn bộ máy chủ. Tạo ngay hoặc dùng pipeline theo lịch để sao lưu không gian làm việc.';

  @override
  String get backupSnapshotComplete => 'Hoàn tất';

  @override
  String get backupDeleteSnapshotLabel => 'Xóa ảnh chụp';

  @override
  String get backupDeleteSnapshotDescription =>
      'Xóa vĩnh viễn ảnh chụp này khỏi máy chủ. Hãy tải xuống trước nếu muốn giữ lại.';

  @override
  String get backupDeleteSnapshotAction => 'Xóa ảnh chụp';

  @override
  String get backupDeleteSnapshotTitle => 'Xóa ảnh chụp này?';

  @override
  String backupDeleteSnapshotBody(String name) {
    return 'Xóa $name khỏi máy chủ? Tất cả cơ sở dữ liệu trong ảnh chụp sẽ mất. Không thể hoàn tác.';
  }

  @override
  String backupDeleteSnapshotDone(String name) {
    return 'Đã xóa ảnh chụp $name.';
  }

  @override
  String backupSnapshotWorkspaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count không gian làm việc',
      one: '1 không gian làm việc',
      zero: 'Không có không gian làm việc',
    );
    return '$_temp0';
  }

  @override
  String backupSnapshotSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count không gian làm việc không được chụp',
      one: '1 không gian làm việc không được chụp',
    );
    return '$_temp0';
  }

  @override
  String get backupServerPathLabel => 'Đường dẫn trên máy chủ';

  @override
  String get backupScheduledLabel => 'Sao lưu theo lịch';

  @override
  String get backupScheduledExplainer =>
      'Các bản sao do pipeline sao lưu của mỗi không gian làm việc lưu lại. Đặt lịch và thời gian lưu giữ trong mẫu pipeline.';

  @override
  String get backupScheduledNone => 'Chưa có bản sao lưu';

  @override
  String backupScheduledCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bản sao lưu',
    );
    return '$_temp0';
  }

  @override
  String backupScheduledLast(String time) {
    return 'Sao lưu gần nhất: $time';
  }

  @override
  String get backupListForbidden =>
      'Bạn cần vai trò quản trị viên trong không gian làm việc này để xem các bản sao lưu.';

  @override
  String get backupScheduledDeleteTitle => 'Xóa bản sao lưu này?';

  @override
  String backupScheduledDeleteBody(String date, String name) {
    return 'Xóa bản sao lưu ngày $date của $name khỏi máy chủ? Không thể hoàn tác thao tác này.';
  }

  @override
  String get backupScheduledDeleteDone => 'Đã xóa bản sao lưu.';

  @override
  String get backupScheduledWorkspaceDeleted => 'Không gian làm việc đã xóa';

  @override
  String get backupRestoreAction => 'Khôi phục';

  @override
  String get backupRestoreTitle => 'Khôi phục không gian làm việc';

  @override
  String backupRestoreBody(String name) {
    return 'Thao tác này thay thế mọi thứ trong $name bằng bản sao trong ảnh chụp này. Mọi việc không gian làm việc đó đã làm sau khi chụp sẽ mất, và không hoàn tác được.';
  }

  @override
  String backupRestoreDone(String name) {
    return 'Đã khôi phục $name từ ảnh chụp.';
  }

  @override
  String get backupWorkspaceUnknown => 'Không còn trên máy chủ này';

  @override
  String get backupWorkspaceDataLabel => 'Dữ liệu không gian làm việc';

  @override
  String get backupWorkspaceDataExplainer =>
      'Một không gian làm việc là một tệp cơ sở dữ liệu, nên xuất là sao chép tệp đó chứ không xuất từng bảng. Nhập thay thế mọi thứ trong không gian làm việc đích bằng tệp bạn chỉ định.';

  @override
  String get backupExportAction => 'Xuất';

  @override
  String backupExportDone(String path) {
    return 'Đã xuất tới $path';
  }

  @override
  String get backupExportedFileLabel => 'Tệp đã xuất trên máy chủ';

  @override
  String get backupImportAction => 'Nhập';

  @override
  String backupImportTitle(String name) {
    return 'Nhập vào $name';
  }

  @override
  String backupImportBody(String name) {
    return 'Thao tác này thay thế mọi thứ trong $name bằng nội dung tệp. Những gì không gian làm việc đang giữ sẽ mất, và không hoàn tác được.';
  }

  @override
  String get backupImportSourceLabel => 'Tệp cơ sở dữ liệu không gian làm việc';

  @override
  String get backupImportSourceDescription =>
      'Tệp .db mà máy chủ đọc được. Đường dẫn được phân giải trên máy chủ, không trên thiết bị này.';

  @override
  String backupImportDone(String name) {
    return 'Đã nhập vào $name.';
  }

  @override
  String backupDeleteBody(String name) {
    return '$name biến mất khỏi mọi danh sách và tra cứu. Tệp cơ sở dữ liệu vẫn trên đĩa, bản sao lưu vẫn gồm nó, và không gì tự thu hồi dung lượng.';
  }

  @override
  String get backupExportDescription =>
      'Ghi một bản sao trên máy chủ, hoặc tải một bản về thiết bị này.';

  @override
  String get backupExportOnServerAction => 'Lưu trên máy chủ';

  @override
  String get backupDownloadAction => 'Tải xuống';

  @override
  String backupDownloadSaved(String path) {
    return 'Đã lưu vào $path';
  }

  @override
  String get backupDownloadInBrowser => 'Trình duyệt đang tải xuống.';

  @override
  String get backupRestoreFromDeviceLabel => 'Khôi phục từ thiết bị này';

  @override
  String get backupRestoreFromDeviceDescription =>
      'Chọn tệp cơ sở dữ liệu không gian làm việc ở đây và Control Center tải lên máy chủ. Đây là cách dùng khi máy chủ không phải máy này.';

  @override
  String get backupUploadAction => 'Chọn tệp và tải lên';

  @override
  String get backupTransferUnavailable =>
      'Chưa thiết lập truyền tệp cho kết nối này. Kết nối lại với máy chủ để tải xuống hoặc tải lên bản sao lưu.';

  @override
  String get backupTransferForbidden =>
      'Máy chủ từ chối. Tải xuống không gian làm việc cần vai trò admin của không gian làm việc. Khôi phục một không gian làm việc cần chủ sở hữu máy chủ, đồng thời người đó cũng phải sở hữu không gian làm việc đó. Toàn bộ snapshot cần chủ sở hữu máy chủ.';

  @override
  String get backupTransferUnsupported =>
      'Máy chủ này không có bề mặt sao lưu.';

  @override
  String get backupTransferTooLarge => 'Tệp lớn hơn mức máy chủ chấp nhận.';

  @override
  String get credentialGateWaitingTitle => 'Đang chờ thông tin xác thực';

  @override
  String credentialGateHarnessTitle(String provider) {
    return '$provider không có thông tin xác thực';
  }

  @override
  String get credentialGateSignedOutTitle => 'Claude Code đã đăng xuất';

  @override
  String get credentialGateExpiredTitle =>
      'Phiên đăng nhập Claude Code đã hết hạn';

  @override
  String get credentialGatePlanSpentTitle => 'Đã đạt giới hạn gói Claude Code';

  @override
  String credentialGateWaitingAgent(String agent) {
    return '$agent đang chờ để tiếp tục.';
  }

  @override
  String get credentialGateWaitingRun => 'Một lần chạy đang chờ để tiếp tục.';

  @override
  String get credentialGateWatching =>
      'Đang theo dõi bản sửa — lần chạy tự tiếp tục.';

  @override
  String credentialGateFreesUpAt(String time) {
    return 'Mở lại lúc $time';
  }

  @override
  String credentialGateGivesUpAt(String time) {
    return 'Lần chạy sẽ bỏ cuộc lúc $time';
  }

  @override
  String get credentialGateCheckAgain => 'Kiểm tra lại';

  @override
  String get credentialGateCancelRun => 'Hủy lần chạy';

  @override
  String get credentialGateAccountsTried => 'Tài khoản đã thử';

  @override
  String get credentialGateClaudeSignInHint =>
      'Đăng nhập từ Cài đặt → Adapters → Claude Code, hoặc chạy lệnh login trong terminal. Lần chạy sẽ nhận tự động.';

  @override
  String get credentialGateOpenSettings => 'Mở cài đặt';

  @override
  String get credentialGateAccountsRemovedTitle =>
      'Các tài khoản Claude Code đã gắn đã bị xóa';

  @override
  String get credentialGateAccountsRemovedHint =>
      'Gắn tài khoản khác trong cài đặt tài khoản của tác tử này hoặc của không gian làm việc, hoặc xóa danh sách để dùng tài khoản mặc định. Lượt chạy sẽ tự tiếp tục.';

  @override
  String get accountPoolAllRemoved =>
      'Mọi tài khoản trong danh sách này đã bị xóa khỏi máy chủ. Hãy gắn tài khoản khác hoặc xóa danh sách.';

  @override
  String get accountPoolClear => 'Xóa danh sách';

  @override
  String get selectModel => 'Chọn mô hình';

  @override
  String get allModels => 'Tất cả mô hình';

  @override
  String get noModelsMatchSearch =>
      'Không có mô hình nào khớp với tìm kiếm của bạn';

  @override
  String useCustomModelId(String id) {
    return 'Dùng “$id”';
  }

  @override
  String get modelFree => 'Miễn phí';

  @override
  String modelOutputTokens(String tokens) {
    return '$tokens đầu ra';
  }

  @override
  String modelPricePerMTokens(String input, String output) {
    return '$input đầu vào / $output đầu ra trên 1M token';
  }

  @override
  String modelEffortLevels(String levels) {
    return 'Mức suy luận: $levels';
  }

  @override
  String get modelSupportsReasoning => 'Hỗ trợ mức suy luận';

  @override
  String get profileDeliveryMetrics => 'Chỉ số phân phối';

  @override
  String profileMetricsSample(int count) {
    return 'PR đã phân tích: $count';
  }

  @override
  String get profileMergeRate => 'Tỷ lệ hợp nhất';

  @override
  String get profileReviewCoverage => 'Mức độ bao phủ đánh giá';

  @override
  String get profilePrSize => 'Kích thước PR';

  @override
  String get profileTimeToMerge => 'Thời gian đến khi hợp nhất';

  @override
  String get profileMergeTimeTrend => 'Xu hướng thời gian hợp nhất';

  @override
  String get profileWeeklyMedian => 'Trung vị hằng tuần, thang logarit';

  @override
  String get profilePrOpeningPattern => 'Thứ trong tuần × giờ, giờ địa phương';

  @override
  String get profileFirstReview => 'Thời gian đến lần đánh giá đầu tiên';

  @override
  String get profileMetricsTruncated =>
      'Các phân vị sử dụng một mẫu giới hạn trong số các yêu cầu kéo hiện có.';

  @override
  String profileLinesChanged(String count) {
    return '$count dòng';
  }

  @override
  String profileDurationMinutes(int count) {
    return '$count phút';
  }

  @override
  String profileDurationHours(int count) {
    return '$count giờ';
  }

  @override
  String profileDurationDaysHours(int days, int hours) {
    return '$days ngày $hours giờ';
  }

  @override
  String profilePercentiles(String median, String p90) {
    return 'p50 $median · p90 $p90';
  }

  @override
  String profileTeamMembers(int count) {
    return 'Thành viên: $count';
  }

  @override
  String noPrsByTeamInWorkspace(String team) {
    return 'Không có pull request nào của $team trong không gian làm việc này';
  }

  @override
  String get profilePrStateFilterLabel => 'Lọc pull request theo trạng thái';

  @override
  String get noProfilePrsMatchSearchHint =>
      'Thử tiêu đề hoặc số pull request khác';

  @override
  String get rigNetworkUnrestricted => 'Mạng không bị hạn chế';

  @override
  String get rigNetworkAllowAllHosts => 'Cho phép mọi máy chủ';

  @override
  String get rigBrowserPermissionsTitle => 'Quyền của trang';

  @override
  String get rigBrowserPermissionsTooltip => 'Quyền của trang và mạng';

  @override
  String get rigBrowserPermissionEmpty => 'Chưa có trang nào xin quyền';

  @override
  String rigBrowserPermissionPrompt(String origin, String permission) {
    return '$origin muốn dùng $permission';
  }

  @override
  String get rigBrowserPermissionBlock => 'Chặn';

  @override
  String get rigBrowserPermissionCamera => 'Máy ảnh';

  @override
  String get rigBrowserPermissionMicrophone => 'Micro';

  @override
  String get rigBrowserPermissionNotifications => 'Thông báo';

  @override
  String get rigBrowserPermissionGeolocation => 'Vị trí';

  @override
  String get rigBrowserPermissionPersistentStorage => 'Bộ nhớ bền vững';

  @override
  String get rigBrowserPermissionClipboard => 'Bảng tạm';

  @override
  String get rigBrowserPermissionDisplayCapture => 'Quay màn hình';

  @override
  String get rigBrowserPermissionMidi => 'MIDI';

  @override
  String get rigNetworkBypassTitle => 'Cho phép mọi máy chủ mạng?';

  @override
  String get rigNetworkBypassBody =>
      'Thao tác này sẽ khởi động lại môi trường cách ly và hủy phần việc chưa commit bên trong. Sau đó, hệ thống khách có thể truy cập mọi máy chủ mạng cho đến khi bị đóng.';

  @override
  String get rigNetworkRestartUnrestricted => 'Khởi động lại không hạn chế';

  @override
  String get rigNetworkUnrestrictedBody =>
      'Môi trường cách ly này có thể truy cập mọi máy chủ mạng. Hãy đóng và mở môi trường mới để khôi phục các hạn chế mặc định.';

  @override
  String get rigNetworkAlreadyUnrestrictedBody =>
      'Trình giả lập Android này đã tự quản lý mạng, vì vậy Control Center không thể thực thi danh sách máy chủ được phép. Không cần khởi động lại.';

  @override
  String get rigClipboardPermissionHostToRigTitle =>
      'Dán bảng nhớ tạm vào môi trường này?';

  @override
  String get rigClipboardPermissionHostToRigBody =>
      'Control Center sẽ đọc bảng nhớ tạm của thiết bị và gửi nội dung của nó đến môi trường. Nội dung bảng nhớ tạm có thể chứa mật khẩu hoặc bí mật khác.';

  @override
  String get rigClipboardPermissionRigToHostTitle =>
      'Sao chép bảng nhớ tạm từ môi trường này?';

  @override
  String get rigClipboardPermissionRigToHostBody =>
      'Control Center sẽ đọc bảng nhớ tạm của môi trường và thay thế bảng nhớ tạm của thiết bị bằng nội dung đó. Hãy coi nội dung từ môi trường là không đáng tin cậy.';

  @override
  String get rigClipboardAllowTenMinutes => 'Cho phép trong 10 phút';

  @override
  String get rigClipboardAlwaysAllow => 'Luôn cho phép';

  @override
  String get rigClipboardSettingsTitle => 'Quyền truy cập bảng nhớ tạm';

  @override
  String get rigClipboardSettingsHint =>
      'Chọn các lần truyền bảng nhớ tạm có thể chạy mà không cần hỏi. Quyền tạm thời hết hạn sau 10 phút.';

  @override
  String get rigClipboardAlwaysPasteTitle => 'Luôn cho phép dán vào môi trường';

  @override
  String get rigClipboardAlwaysPasteDescription =>
      'Gửi bảng nhớ tạm của thiết bị này đến bất kỳ môi trường nào mà không cần hỏi.';

  @override
  String get rigClipboardAlwaysCopyTitle =>
      'Luôn cho phép sao chép từ môi trường';

  @override
  String get rigClipboardAlwaysCopyDescription =>
      'Đặt nội dung bảng nhớ tạm từ bất kỳ môi trường nào trên thiết bị này mà không cần hỏi.';

  @override
  String get profileOverlayHint =>
      'Các trường này là bạn trong không gian này. Trường trống kế thừa tên và email tài khoản. Đổi không gian sẽ đổi lớp phủ này.';

  @override
  String get stackStartNextPart => 'Bắt đầu phần tiếp theo';

  @override
  String get stackPartNameTitle => 'Tên phần';

  @override
  String get stackPartNameHint => 'vd. migration';

  @override
  String get stackPublish => 'Xuất bản ngăn xếp';

  @override
  String get stackCurrentPart => 'Hiện tại';

  @override
  String get stackSwitchDirty =>
      'Hãy commit hoặc hủy thay đổi trước khi chuyển phần';

  @override
  String get stackCutFailed => 'Không bắt đầu được phần tiếp theo';

  @override
  String get stackPublishFailed => 'Không xuất bản được ngăn xếp';

  @override
  String get stackPublished => 'Đã xuất bản ngăn xếp dưới dạng bản nháp';

  @override
  String get stackOpenPullRequest => 'Mở pull request';

  @override
  String get stackSection => 'Ngăn xếp';

  @override
  String get mergeConflictsButton => 'Xung đột';

  @override
  String mergeConflictsFileCount(int count, String base) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tệp xung đột với $base',
    );
    return '$_temp0';
  }

  @override
  String get mergeConflictsLoading => 'Đang tìm các tệp xung đột…';

  @override
  String get mergeConflictsLoadFailed => 'Không thể liệt kê các tệp xung đột';

  @override
  String get mergeConflictsNoneFound =>
      'Không tìm thấy tệp xung đột. GitHub có thể vẫn đang cập nhật pull request này.';

  @override
  String get askAiToFixConflicts => 'Nhờ AI sửa xung đột';

  @override
  String get fixConflictsStarted =>
      'Một tác tử đang giải quyết xung đột trong cuộc trò chuyện của pull request này';

  @override
  String failedToStartConflictFix(String error) {
    return 'Không thể bắt đầu sửa xung đột: $error';
  }

  @override
  String get settingsLinks => 'Liên kết';

  @override
  String get linksSettingsDescription =>
      'Chọn nơi mở các liên kết từ bên ngoài Control Center, chẳng hạn một pull request được mở từ GitHub.';

  @override
  String get repoLinkRememberedTitle => 'Không gian làm việc đã ghi nhớ';

  @override
  String get repoLinkRememberedHint =>
      'Khi một kho lưu trữ được liên kết với nhiều không gian làm việc, việc mở liên kết tới kho đó sẽ hỏi bạn dùng không gian làm việc nào. Các lựa chọn bạn đã yêu cầu ghi nhớ được liệt kê ở đây.';

  @override
  String get repoLinkRememberedEmpty => 'Chưa có lựa chọn nào được ghi nhớ.';

  @override
  String get repoLinkForget => 'Quên';

  @override
  String get repoLinkWorkspaceUnavailable =>
      'Không gian làm việc không còn khả dụng';

  @override
  String get repoLinkWorkspaceDialogTitle => 'Chọn không gian làm việc';

  @override
  String repoLinkWorkspaceDialogBody(String repo) {
    return '$repo được liên kết với nhiều không gian làm việc. Mở liên kết này trong không gian làm việc nào?';
  }

  @override
  String get repoLinkWorkspaceRemember =>
      'Ghi nhớ lựa chọn của tôi cho kho lưu trữ này';

  @override
  String get repoLinkWorkspaceOpen => 'Mở';

  @override
  String get repoLinkUnlinkedTitle =>
      'Thêm kho lưu trữ vào không gian làm việc';

  @override
  String repoLinkUnlinkedBody(String repo) {
    return 'Chưa có không gian làm việc nào liên kết $repo. Hãy thêm vào một không gian để mở liên kết này.';
  }

  @override
  String repoLinkUnlinkedAddTo(String workspace) {
    return 'Thêm vào $workspace';
  }

  @override
  String get repoLinkUnlinkedAddToHint => 'Chọn checkout của kho trên máy chủ.';

  @override
  String get repoLinkUnlinkedCreate => 'Không gian làm việc mới';

  @override
  String get repoLinkUnlinkedCreateHint => 'Đặt tên, rồi chọn checkout.';

  @override
  String repoLinkChooseCheckout(String repo) {
    return 'Chọn checkout của $repo trên máy đang chạy máy chủ.';
  }

  @override
  String repoLinkCheckoutMismatch(String repo) {
    return 'Không kho lưu trữ nào vừa thêm là $repo, nên liên kết đã mở mà không có nó.';
  }

  @override
  String get windowMinimize => 'Thu nhỏ';

  @override
  String get windowMaximize => 'Phóng to';

  @override
  String get windowRestore => 'Khôi phục';

  @override
  String nativeSandboxUnsupported(String platform) {
    return 'Sandbox gốc chưa được hỗ trợ trên $platform.';
  }

  @override
  String get continueWithoutSandbox => 'Tiếp tục không dùng sandbox';

  @override
  String get sandboxCheckAgain => 'Kiểm tra lại';

  @override
  String get ideQuickOpen => 'Đi tới tệp';

  @override
  String get ideQuickOpenHint => 'Tìm tệp theo tên';

  @override
  String get ideQuickOpenRecentlyOpened => 'Đã mở gần đây';

  @override
  String get ideQuickOpenOpenToSide => 'Mở bên cạnh';

  @override
  String get ideQuickOpenRemoveRecent => 'Xóa khỏi danh sách đã mở gần đây';

  @override
  String get ideQuickOpenNoRecent => 'Không có tệp nào được mở gần đây';

  @override
  String get diffMarkFileViewed => 'Đánh dấu đã xem';

  @override
  String get diffMarkFileNotViewed => 'Đánh dấu chưa xem';

  @override
  String diffAdditionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dòng thêm',
      one: '1 dòng thêm',
    );
    return '$_temp0';
  }

  @override
  String diffDeletionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dòng xóa',
      one: '1 dòng xóa',
    );
    return '$_temp0';
  }

  @override
  String diffFileSemantics(
    String path,
    String status,
    String additions,
    String deletions,
  ) {
    return '$path, $status, $additions, $deletions';
  }

  @override
  String diffFileSemanticsViewed(
    String path,
    String status,
    String additions,
    String deletions,
  ) {
    return '$path, $status, $additions, $deletions, đã xem';
  }

  @override
  String diffFileRenamedFrom(String previous) {
    return 'đổi tên từ $previous';
  }

  @override
  String diffTreeFolderSemantics(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tệp',
      one: '1 tệp',
    );
    return '$name, thư mục, $_temp0';
  }

  @override
  String diffTreeFileSemantics(String name, String status) {
    return '$name, $status';
  }

  @override
  String diffTreeFileSemanticsViewed(String name, String status) {
    return '$name, $status, đã xem';
  }

  @override
  String diffLineAdded(int line, String code) {
    return 'Dòng đã thêm $line: $code';
  }

  @override
  String diffLineRemoved(int line, String code) {
    return 'Dòng đã xóa $line: $code';
  }

  @override
  String diffLineContext(int line, String code) {
    return 'Dòng $line: $code';
  }

  @override
  String diffLineHunk(String header) {
    return 'Khối $header';
  }

  @override
  String get diffLineBlank => 'trống';

  @override
  String get diffCommentOnLineAction => 'Bình luận dòng này';

  @override
  String diffFileMarkedViewedAnnouncement(String path) {
    return 'Đã đánh dấu $path là đã xem';
  }

  @override
  String diffFileMarkedNotViewedAnnouncement(String path) {
    return 'Đã đánh dấu $path là chưa xem';
  }

  @override
  String prLineChangesSemantics(int additions, int deletions) {
    return 'Dòng đã thêm: $additions, dòng đã xóa: $deletions';
  }

  @override
  String closeTabNamed(String tab) {
    return 'Đóng $tab';
  }

  @override
  String get notificationAgentAwaitingInput => 'Agent cần được chú ý';

  @override
  String get notifyAgentAwaitingInput =>
      'Khi agent cần phê duyệt, câu trả lời hoặc thông tin xác thực hợp lệ, hoặc chính sách chặn một hành động';

  @override
  String notificationAgentNeedsApproval(String agent) {
    return '$agent cần bạn phê duyệt';
  }

  @override
  String get notificationAgentNeedsApprovalUnnamed =>
      'Một agent cần bạn phê duyệt';

  @override
  String notificationAgentAskedQuestion(String agent) {
    return '$agent có câu hỏi';
  }

  @override
  String get notificationAgentAskedQuestionUnnamed => 'Một agent có câu hỏi';

  @override
  String notificationAgentBlockedOnCredential(String agent) {
    return '$agent bị chặn do thông tin xác thực';
  }

  @override
  String get notificationAgentBlockedOnCredentialUnnamed =>
      'Một agent bị chặn do thông tin xác thực';

  @override
  String notificationWaitReminder(String title) {
    return 'Vẫn đang chờ: $title';
  }

  @override
  String get killTerminal => 'Đóng terminal';

  @override
  String get stopAgentCommand => 'Dừng lệnh';

  @override
  String get agentCommandStopping => 'Đang dừng…';

  @override
  String sidebarAgeSeconds(int count) {
    return '$count giây';
  }

  @override
  String agentCommandSemantics(String command, String elapsed) {
    return 'Lệnh của tác tử $command, đã chạy $elapsed';
  }

  @override
  String get serverLostTitle => 'Mất kết nối với máy chủ';

  @override
  String get serverLostBody =>
      'Control Center vẫn đang thử kết nối lại trong nền. Hãy thử lại ngay hoặc chuyển đến màn hình đăng nhập để chọn máy chủ.';

  @override
  String get serverLostRetrying => 'Đang kết nối lại…';

  @override
  String serverLostNextAttempt(int seconds) {
    return 'Lần thử tiếp theo sau $seconds giây';
  }

  @override
  String get serverLostReconnect => 'Thử kết nối lại';

  @override
  String get serverLostSignIn => 'Đến màn hình đăng nhập';

  @override
  String get serverEndedTitle => 'Không thể kết nối lại với máy chủ';

  @override
  String get shutdownSubtitleServer => 'Máy chủ đang dừng';

  @override
  String get skillEvalAbsent => 'Không có so với có sẵn';

  @override
  String get skillEvalAmbient => 'Kỹ năng sẵn có';

  @override
  String skillEvalArtifactRef(String reference) {
    return 'Tham chiếu hiện vật: $reference';
  }

  @override
  String skillEvalAttempt(String task, String arm, int repeat) {
    final intl.NumberFormat repeatNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String repeatString = repeatNumberFormat.format(repeat);

    return '$task · $arm · lặp lại $repeatString';
  }

  @override
  String get skillEvalAttempts => 'Lần thử';

  @override
  String get skillEvalAvailableEvent => 'Có sẵn';

  @override
  String get skillEvalBaseline => 'Hash của bản sửa đổi trước';

  @override
  String get skillEvalBodyLoad => 'Đã tải nội dung';

  @override
  String get skillEvalBudgetCents => 'Ngân sách (US cents)';

  @override
  String get skillEvalBudgetNote =>
      'Đánh giá trả phí dùng nhà cung cấp và ngân sách đã chọn. Kết quả quét bảo mật được tính riêng.';

  @override
  String get skillEvalUsageBudgetNote =>
      'Ngân sách đăng ký theo dõi mức sử dụng quy đổi theo giá API, không phải hóa đơn. Lệnh gọi đang chạy có thể vượt ngân sách; khi đạt giới hạn, hệ thống không bắt đầu lệnh gọi mới. Quét bảo mật được thực hiện riêng.';

  @override
  String get skillEvalCancel => 'Hủy lượt chạy';

  @override
  String get skillEvalCancelled => 'Đã hủy';

  @override
  String get skillEvalCancelling => 'Đang hủy';

  @override
  String get skillEvalComparison => 'So sánh';

  @override
  String get skillEvalCompleted => 'Đã hoàn tất';

  @override
  String get skillEvalComposition => 'Thành phần';

  @override
  String get skillEvalCorpus => 'Tập tác vụ';

  @override
  String skillEvalCoverage(String corpus, int repeats) {
    final intl.NumberFormat repeatsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String repeatsString = repeatsNumberFormat.format(repeats);

    return '$corpus · lặp lại $repeatsString lần';
  }

  @override
  String get skillEvalCoverageComplete =>
      'Đã ghi nhận mọi lượt thử theo kế hoạch';

  @override
  String skillEvalCurrentHash(String hash) {
    return 'Hash gói hiện tại: $hash';
  }

  @override
  String get skillEvalDisableUpdates => 'Tắt đánh giá khi cập nhật';

  @override
  String get skillEvalEnableUpdates => 'Bật đánh giá khi cập nhật';

  @override
  String get skillEvalExport => 'Sao chép JSON đã ẩn dữ liệu nhạy cảm';

  @override
  String get skillEvalFailed => 'Thất bại';

  @override
  String get skillEvalForced => 'Buộc tải so với không có';

  @override
  String get skillEvalForcedEvent => 'Buộc tải';

  @override
  String get skillEvalHashLabel => 'Hash gói';

  @override
  String get skillEvalProgressLabel => 'Tiến độ';

  @override
  String get skillEvalUpdatesToggle => 'Đánh giá khi cập nhật';

  @override
  String get skillEvalHashUnavailable =>
      'Hash gói không có trên máy chủ này. Tính năng đánh giá đã bị vô hiệu hóa.';

  @override
  String get skillEvalHistory => 'Lịch sử bản sửa đổi';

  @override
  String get skillEvalImproved => 'Đã cải thiện';

  @override
  String get skillEvalIncomplete => 'Chưa hoàn chỉnh';

  @override
  String get skillEvalInconclusive =>
      'Chưa có quyết định (không đủ bằng chứng)';

  @override
  String get skillEvalInferred => 'Suy ra';

  @override
  String get skillEvalInterrupted => 'Bị gián đoạn';

  @override
  String get skillEvalLoadUnobserved =>
      'Không thể quan sát việc tải kỹ năng; không có sự kiện không có nghĩa là kỹ năng đã bị bỏ qua.';

  @override
  String get skillEvalModel => 'Mô hình đã chọn';

  @override
  String get skillEvalNoAttempts => 'Chưa có lần thử nào.';

  @override
  String get skillEvalNoModels =>
      'Không có mô hình nào đã kết nối. Trước tiên, hãy kết nối với một nhà cung cấp trong Cài đặt.';

  @override
  String get skillEvalNoPrevious =>
      'Không có hash trước đó trong lịch sử chiến dịch. Hãy đánh giá bản sửa đổi trước khi thay thế.';

  @override
  String get skillEvalNoReport =>
      'Chưa có báo cáo; các lần thử một phần vẫn có sẵn.';

  @override
  String get skillEvalNoWorkspace => 'Chưa chọn không gian làm việc.';

  @override
  String get skillEvalNoTasks => 'Chưa có tác vụ nào được báo cáo.';

  @override
  String get skillEvalNoVerifiers => 'Chưa ghi nhận bằng chứng xác minh.';

  @override
  String get skillEvalNotEvaluated =>
      'Chưa đánh giá đúng các byte này. Quét không phải là bằng chứng về hành vi.';

  @override
  String get skillEvalNotVerified => 'Chưa xác minh';

  @override
  String get skillEvalObserved => 'Đã quan sát';

  @override
  String get skillEvalOpenQuality => 'Mở Chất lượng';

  @override
  String get skillEvalPolicyNote =>
      'Theo mặc định, lưu kỹ năng không bắt đầu đánh giá trả phí. Nếu bạn chủ động bật đánh giá lại tự động khi cập nhật, thao tác lưu sẽ bắt đầu một lượt đánh giá lại trả phí trong phạm vi ngân sách đã đặt.';

  @override
  String get skillEvalPolicyNeedsCampaign =>
      'Hãy đánh giá một bản sửa đổi trước khi cấu hình chính sách cập nhật.';

  @override
  String get skillEvalPolicyTemplate => 'Cấu hình chính sách cập nhật';

  @override
  String get skillEvalPartial =>
      'Bằng chứng chưa đầy đủ; chưa thể kết luận có nên áp dụng';

  @override
  String skillEvalProgress(int completed, int planned) {
    final intl.NumberFormat completedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String completedString = completedNumberFormat.format(completed);
    final intl.NumberFormat plannedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String plannedString = plannedNumberFormat.format(planned);

    return '$completedString / $plannedString lần thử';
  }

  @override
  String skillEvalProvider(String provider) {
    return 'Nhà cung cấp: $provider';
  }

  @override
  String get skillEvalQualityIntro =>
      'Các chiến dịch kỹ năng trong không gian làm việc và bằng chứng theo từng bản sửa đổi.';

  @override
  String get skillEvalQueued => 'Đang chờ';

  @override
  String get skillEvalReconnecting =>
      'Đang kết nối lại với các bản ghi trạng thái chiến dịch…';

  @override
  String get skillEvalRefresh => 'Làm mới';

  @override
  String get skillEvalReferenceLoad => 'Đã tải tài liệu tham chiếu';

  @override
  String get skillEvalRepetitions => 'Số lần lặp lại mỗi tác vụ';

  @override
  String get skillEvalReport => 'Báo cáo bằng chứng';

  @override
  String get skillEvalRunning => 'Đang chạy';

  @override
  String get skillEvalScriptExecution => 'Đã chạy tập lệnh';

  @override
  String skillEvalSpend(String spent, String budget) {
    return 'Đã chi: $spent / ngân sách $budget';
  }

  @override
  String get skillEvalStart => 'Bắt đầu đánh giá';

  @override
  String get skillEvalStartTitle => 'So sánh các bản sửa đổi kỹ năng';

  @override
  String get skillEvalStale => 'Đã lỗi thời';

  @override
  String skillEvalStaleReason(String reason) {
    return 'Đã lỗi thời: $reason';
  }

  @override
  String skillEvalTaskClusters(String count) {
    return 'Nhóm tác vụ riêng biệt: $count';
  }

  @override
  String skillEvalTaskEvidence(String rate, String passes, String cost) {
    return '$rate ($passes đã xác minh) · $cost';
  }

  @override
  String get skillEvalTasks => 'Tác vụ theo nhánh';

  @override
  String get skillEvalToolError => 'Lỗi công cụ';

  @override
  String get skillEvalTools => 'Sự kiện công cụ';

  @override
  String get skillEvalTitle => 'Đánh giá kỹ năng';

  @override
  String skillEvalUnavailable(String reason) {
    return 'Không khả dụng: $reason';
  }

  @override
  String get skillEvalUnknown => 'Không rõ';

  @override
  String get skillEvalUnsaved =>
      'Các thay đổi chưa lưu không được đưa vào. Hãy lưu trước khi đánh giá.';

  @override
  String get skillEvalUncertainty => 'Khoảng bất định';

  @override
  String get skillEvalVerified => 'Đã xác minh';

  @override
  String get skillEvalVerifiers => 'Xác minh';

  @override
  String get skillEvalVerdict => 'Kết luận';

  @override
  String skillEvalExportCopied(String filename) {
    return 'Đã sao chép: $filename';
  }

  @override
  String get skillEvalPlanViolation => 'Vi phạm kế hoạch';

  @override
  String get skillEvalPreserved => 'Chất lượng được duy trì';

  @override
  String get skillEvalPrevious => 'Bản trước so với bản hiện tại';

  @override
  String get skillEvalRegressed => 'Đã chứng minh có suy giảm';

  @override
  String get skillEvalCostRegression => 'Chi phí tăng trở lại';

  @override
  String get skillEvalHarnessError => 'Lỗi bộ kiểm thử';

  @override
  String get skillBehaviorRouting => 'Định tuyến kỹ năng';

  @override
  String skillBehaviorRoutingCounts(
    String truePositive,
    String falsePositive,
    String falseNegative,
    String trueNegative,
  ) {
    return '$truePositive lượt dùng đúng kỳ vọng · $falsePositive lượt dùng ngoài kỳ vọng · $falseNegative lượt bỏ lỡ · $trueNegative lượt bỏ qua đúng';
  }

  @override
  String skillBehaviorUnknownCounts(
    String positive,
    String negative,
    String notOffered,
  ) {
    return '$positive lượt dùng chưa rõ · $negative lượt bỏ qua chưa rõ · $notOffered lượt không được cung cấp';
  }

  @override
  String skillBehaviorRoutingRates(
    String precision,
    String recall,
    String falsePositiveRate,
  ) {
    return 'Độ chính xác quan sát được $precision · độ bao phủ $recall · tỷ lệ dương tính giả $falsePositiveRate';
  }

  @override
  String get skillBehaviorForced => 'Nhánh cưỡng bức · chỉ để chẩn đoán';

  @override
  String get skillBehaviorRoutingNote =>
      'Tỷ lệ chỉ tính những lần truy cập quan sát được. Truy cập qua shell hoặc tìm kiếm có thể chưa rõ; tải kỹ năng không chứng tỏ đã áp dụng kỹ năng.';

  @override
  String get skillBehaviorSafety => 'An toàn mô phỏng';

  @override
  String skillBehaviorSafetyCounts(
    String passes,
    String attempts,
    String denials,
    String violations,
  ) {
    return '$passes/$attempts lượt kiểm tra hiện vật đạt · $denials lượt bị chính sách từ chối · $violations lượt vi phạm tệp được bảo vệ';
  }

  @override
  String get skillBehaviorSafetyNote =>
      'Các lượt kiểm tra hiện vật chỉ là mô phỏng, không phản ánh tỷ lệ tấn công trong thực tế; các tác động phụ thực tế không được theo dõi.';

  @override
  String get skillBehaviorUtility => 'Mức hữu ích theo nhóm';

  @override
  String skillBehaviorUtilityCounts(String verified, String attempts) {
    return '$verified/$attempts lượt thành công đã xác minh';
  }

  @override
  String get skillBehaviorUtilityNote =>
      'Mọi lượt thử đều nằm trong mẫu số mức hữu ích, kể cả lượt thất bại và chưa hoàn tất.';

  @override
  String get claudeAccountSignInFailed => 'Đăng nhập thất bại';

  @override
  String get claudeSignInDialogTitle => 'Đăng nhập vào Claude Code';

  @override
  String get claudeSignInDialogHint =>
      'Chạy từng lệnh trong một terminal trên máy chủ. Lệnh sẽ mở trình duyệt để hoàn tất đăng nhập và ghi thông tin xác thực vào thư mục của tài khoản đó.';

  @override
  String get claudeSignInNoAccounts =>
      'Không có tài khoản được quản lý nào bị đăng xuất. Nếu tác tử này dùng đăng nhập riêng của Claude Code, hãy chạy:';

  @override
  String get claudeSignInCommandUnavailable =>
      'Máy chủ không thể cung cấp lệnh đăng nhập cho tài khoản này.';

  @override
  String get claudeAccountSignedIn => 'Đã đăng nhập';

  @override
  String get claudeSignInClosesItself =>
      'Hộp thoại này sẽ tự đóng khi quá trình đăng nhập hoàn tất.';

  @override
  String get claudeSignInClosesItselfAll =>
      'Hộp thoại này sẽ tự đóng khi tất cả tài khoản đã đăng nhập.';

  @override
  String get transcriptClaudeSignInExpiredTitle =>
      'Phiên đăng nhập Claude Code đã hết hạn';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      'Lần chạy đã dừng vì tài khoản của nó không còn xác thực được. Hãy đăng nhập lại rồi thử lại lượt này.';

  @override
  String get transcriptSignInExpiredTitle =>
      'Phiên đăng nhập nhà cung cấp đã hết hạn';

  @override
  String get transcriptSignInExpiredBody =>
      'Lần chạy đã dừng vì thông tin xác thực của nhà cung cấp không còn hoạt động. Hãy kết nối lại trong Cài đặt → Nhà cung cấp rồi thử lại lượt này.';

  @override
  String get helpMenuLabel => 'Trợ giúp';

  @override
  String get helpWhatsNew => 'Có gì mới';

  @override
  String get helpReportProblem => 'Báo cáo sự cố';

  @override
  String get helpCreateGitHubIssue => 'Tạo issue trên GitHub';

  @override
  String get changelogInstalled => 'Đã cài đặt';

  @override
  String get changelogGroupNew => 'Mới';

  @override
  String get changelogGroupImproved => 'Cải thiện';

  @override
  String get changelogGroupFixed => 'Đã sửa';

  @override
  String get changelogLoadFailed => 'Không thể tải ghi chú phát hành.';

  @override
  String get changelogOpenWebsite => 'Mở trên trang web';

  @override
  String get connectWelcomeTitle => 'Chào mừng đến với Control Center';

  @override
  String get connectWelcomeSubtitle =>
      'Chạy tại đây hoặc kết nối tới máy chủ bạn đã có.';

  @override
  String get connectWelcomeSubtitleWeb =>
      'Kết nối tới máy chủ của bạn để bắt đầu.';

  @override
  String get connectToServer => 'Kết nối tới máy chủ';

  @override
  String get connectToServerIntro =>
      'Nhập địa chỉ của một máy chủ Control Center.';

  @override
  String get connectUsePairingKey => 'Dùng khóa ghép nối';

  @override
  String get connectPasteLink => 'Dán liên kết ghép nối';

  @override
  String get connectPasteLinkIntro =>
      'Dán liên kết mời hoặc liên kết ghép nối bạn nhận được.';

  @override
  String get connectPasteLinkLabel => 'Liên kết mời hoặc ghép nối';

  @override
  String get connectPasteLinkInvalid =>
      'Đó không phải là liên kết mời hoặc ghép nối của Control Center. Hãy sao chép toàn bộ liên kết và thử lại.';

  @override
  String get connectPasteLinkTarget => 'Kết nối tới';

  @override
  String get focusModeEnd => 'Kết thúc phiên tập trung';

  @override
  String focusModeRemaining(int minutes) {
    return 'Còn $minutes phút';
  }

  @override
  String get demoUnavailableEnvironments =>
      'Môi trường chạy các tiến trình thật trên máy chủ, nên bản demo không có môi trường nào.';

  @override
  String get environmentChecksFailing =>
      'Một số kiểm tra đang thất bại trên máy chủ';

  @override
  String environmentCliEndpoints(String names) {
    return 'Điểm cuối: $names';
  }

  @override
  String environmentCliServices(String names) {
    return 'Dịch vụ: $names';
  }

  @override
  String get environmentCopied => 'Đã sao chép';

  @override
  String get environmentCopyCommand => 'Sao chép lệnh';

  @override
  String get environmentCopyUrl => 'Sao chép URL';

  @override
  String get environmentDefinition => 'Định nghĩa';

  @override
  String environmentDefinitionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count định nghĩa',
    );
    return '$_temp0';
  }

  @override
  String get environmentDestroy => 'Hủy bỏ';

  @override
  String environmentDestroyBody(String name) {
    return '$name và dữ liệu của nó sẽ bị xóa. Bắt đầu sẽ tạo cái mới.';
  }

  @override
  String get environmentDestroyTitle => 'Hủy bỏ môi trường này?';

  @override
  String get environmentExec => 'Exec';

  @override
  String get environmentExecTitle => 'Chạy trong một dịch vụ';

  @override
  String environmentExitCode(int code) {
    return 'Mã thoát $code';
  }

  @override
  String get environmentInputNeeded => 'Cần thiết lập việc này trên máy chủ';

  @override
  String get environmentKindApp => 'Ứng dụng';

  @override
  String get environmentKindCli => 'CLI';

  @override
  String get environmentKindCompose => 'Compose';

  @override
  String get environmentKindProcess => 'Tiến trình';

  @override
  String get environmentKindTask => 'Tác vụ';

  @override
  String get environmentLaunch => 'Khởi chạy';

  @override
  String get environmentLogsGone => 'Các nhật ký này không còn khả dụng.';

  @override
  String environmentLogsTab(String name) {
    return 'Nhật ký: $name';
  }

  @override
  String get environmentLogsWaiting => 'Đang chờ đầu ra';

  @override
  String get environmentMoreActions => 'Thêm thao tác môi trường';

  @override
  String get environmentNeedsRecreate =>
      'Một thay đổi yêu cầu tạo lại môi trường này.';

  @override
  String get environmentNoStack =>
      'Chỉ chạy tác vụ worktree, nên không có gì để bắt đầu.';

  @override
  String get environmentOnTheServer => 'Trên máy chủ';

  @override
  String get environmentOpenInBrowserVm => 'Mở trong Browser (VM)';

  @override
  String get environmentOpenViewer => 'Mở trình xem';

  @override
  String get environmentPlacementRig => 'Trong VM';

  @override
  String get environmentPreviewTab => 'Môi trường';

  @override
  String get environmentRebuildRelaunch => 'Dựng lại và khởi chạy lại';

  @override
  String get environmentRecreate => 'Tạo lại';

  @override
  String environmentRecreateBody(String name) {
    return '$name sẽ bị hủy và khởi động lại với cùng tùy chọn. Dữ liệu sẽ mất.';
  }

  @override
  String get environmentRecreateTitle => 'Tạo lại môi trường này?';

  @override
  String environmentResetBody(String name) {
    return '$name trở về trạng thái gốc. Dữ liệu tạo từ đó sẽ mất.';
  }

  @override
  String get environmentResetData => 'Đặt lại dữ liệu';

  @override
  String get environmentResetTitle => 'Đặt lại dữ liệu?';

  @override
  String get environmentRestart => 'Khởi động lại';

  @override
  String environmentRestarts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lần khởi động lại',
    );
    return '$_temp0';
  }

  @override
  String get environmentRun => 'Chạy';

  @override
  String get environmentRunInTerminal => 'Chạy trong terminal';

  @override
  String get environmentSectionTitle => 'Môi trường';

  @override
  String get environmentService => 'Dịch vụ';

  @override
  String environmentServiceActions(String name) {
    return 'Thao tác cho $name';
  }

  @override
  String get environmentStartTitle => 'Bắt đầu môi trường';

  @override
  String get environmentStateCrashed => 'Đã sập';

  @override
  String get environmentStatusDegraded => 'Suy giảm';

  @override
  String get environmentStatusDestroying => 'Đang hủy';

  @override
  String get environmentStatusGone => 'Đã mất';

  @override
  String get environmentStatusStopping => 'Đang dừng';

  @override
  String environmentStopDataLoss(String name) {
    return 'Dừng $name sẽ mất dữ liệu, và Bắt đầu không khôi phục được.';
  }

  @override
  String get environmentStopLoseData => 'Dừng và mất dữ liệu';

  @override
  String get environmentStopTitle => 'Dừng môi trường này?';

  @override
  String get environmentTaskNeverRun => 'Chưa chạy';

  @override
  String get environmentsAddCheck => 'Thêm kiểm tra';

  @override
  String get environmentsAddOption => 'Thêm tùy chọn';

  @override
  String get environmentsAddRole => 'Thêm vai trò';

  @override
  String get environmentsAdminOnly =>
      'Chỉ quản trị viên không gian làm việc mới có thể thay đổi định nghĩa.';

  @override
  String get environmentsAfter => 'Chờ các thành phần này';

  @override
  String get environmentsAnchor => 'Neo';

  @override
  String get environmentsAutoCreate => 'Tự động bắt đầu';

  @override
  String get environmentsAutoCreateAll => 'Trong mọi không gian đủ điều kiện';

  @override
  String get environmentsAutoCreateOff => 'Không bao giờ';

  @override
  String get environmentsAutoCreatePrs => 'Trong không gian pull request';

  @override
  String get environmentsBlank => 'Định nghĩa trống';

  @override
  String get environmentsCheckFix => 'Lệnh sửa lỗi';

  @override
  String get environmentsCheckHint => 'Gợi ý';

  @override
  String get environmentsCommandHelp =>
      'Các đối số cách nhau bằng dấu cách. Đặt đối số chứa dấu cách trong dấu ngoặc kép.';

  @override
  String environmentsComponentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thành phần',
    );
    return '$_temp0';
  }

  @override
  String get environmentsComponentId => 'ID';

  @override
  String get environmentsComposeBuild => 'Dựng image khi bắt đầu';

  @override
  String get environmentsComposeFile => 'Tệp compose';

  @override
  String get environmentsComposeHttp => 'HTTP';

  @override
  String get environmentsComposeNoFile =>
      'Không đọc được tệp compose. Vẫn có thể nhập tên dịch vụ trong chế độ xem JSON.';

  @override
  String get environmentsComposeServices => 'Dịch vụ';

  @override
  String get environmentsComposeServicesHint =>
      'Bỏ chọn mọi dịch vụ để chạy tất cả.';

  @override
  String get environmentsConditionalArgs =>
      'Lệnh này có đối số điều kiện. Hãy sửa trong chế độ xem JSON.';

  @override
  String get environmentsCwdPath => 'Đường dẫn làm việc';

  @override
  String get environmentsCwdRole => 'Vai trò làm việc';

  @override
  String get environmentsDeleteBody =>
      'Các không gian sẽ không thể bắt đầu nó nữa. Môi trường đang chạy tiếp tục cho đến khi bị dừng.';

  @override
  String environmentsDeleteTitle(String name) {
    return 'Xóa $name?';
  }

  @override
  String get environmentsDescription =>
      'Những gì mỗi không gian có thể bắt đầu và tác vụ worktree của nó chạy.';

  @override
  String get environmentsDraftFromRepo => 'Tạo bản nháp từ repo';

  @override
  String get environmentsEmpty => 'Chưa có định nghĩa';

  @override
  String get environmentsEnabledWhen => 'Bật khi';

  @override
  String get environmentsEndpointRole => 'Vai trò điểm cuối';

  @override
  String get environmentsFollowPrHead => 'Theo head của pull request';

  @override
  String get environmentsForkApproval =>
      'Mỗi lần bắt đầu cần một quản trị viên';

  @override
  String get environmentsForkDeny => 'Bị từ chối';

  @override
  String get environmentsForkPrs => 'Pull request từ fork';

  @override
  String get environmentsForkRig => 'Chạy trong VM';

  @override
  String get environmentsIdleStop => 'Dừng sau số phút rảnh';

  @override
  String get environmentsIsolateHome => 'Cấp cho ứng dụng thư mục home riêng';

  @override
  String get environmentsIssues => 'Sửa các mục này trước khi lưu';

  @override
  String environmentsJsonInvalid(String error) {
    return 'JSON không hợp lệ: $error';
  }

  @override
  String get environmentsKeepsData => 'Giữ dữ liệu khi dừng';

  @override
  String get environmentsLinkConfirm => 'Liên kết và phê duyệt';

  @override
  String get environmentsLinkFile => 'Liên kết tệp repo';

  @override
  String get environmentsLinkHelp =>
      'Chỉ đọc từ nhánh mặc định và chỉ chạy sau khi được phê duyệt.';

  @override
  String get environmentsLinkPath => 'Đường dẫn';

  @override
  String get environmentsMaxRunning => 'Chạy cùng lúc';

  @override
  String get environmentsNamingProject => 'Dự án';

  @override
  String get environmentsNamingTemplate => 'Mẫu tên';

  @override
  String get environmentsNew => 'Định nghĩa mới';

  @override
  String get environmentsNewDefinitionName => 'Môi trường mới';

  @override
  String get environmentsNoChecks => 'Định nghĩa này không có kiểm tra.';

  @override
  String get environmentsNoRuns => 'Chưa có lần chạy thử';

  @override
  String get environmentsOnChange => 'Đường dẫn cần theo dõi';

  @override
  String get environmentsOptionBool => 'Có hoặc không';

  @override
  String get environmentsOptionEnum => 'Một trong';

  @override
  String get environmentsOptionMulti => 'Một vài trong';

  @override
  String get environmentsOptionValues => 'Giá trị';

  @override
  String get environmentsPlacement => 'Vị trí đặt';

  @override
  String get environmentsPlacementHost => 'Trên máy chủ';

  @override
  String get environmentsPlacementRig => 'Trong VM';

  @override
  String get environmentsPrepareTask => 'Tác vụ chuẩn bị';

  @override
  String get environmentsPrimaryEndpoint => 'Điểm cuối chính';

  @override
  String get environmentsReadyHttp => 'Sẵn sàng khi URL này phản hồi';

  @override
  String get environmentsRestartAlways => 'Luôn luôn';

  @override
  String get environmentsRestartNever => 'Không bao giờ';

  @override
  String get environmentsRestartOn =>
      'Khởi động lại khi các đường dẫn này thay đổi';

  @override
  String get environmentsRestartOnFailure => 'Khi thất bại';

  @override
  String get environmentsRestartPolicy => 'Khởi động lại';

  @override
  String get environmentsRigTtl => 'Thời gian tồn tại của VM tính bằng giờ';

  @override
  String get environmentsRunChecks => 'Chạy lại';

  @override
  String get environmentsRunTest => 'Chạy kiểm thử';

  @override
  String get environmentsSaved => 'Đã lưu định nghĩa';

  @override
  String get environmentsSectionComponents => 'Thành phần';

  @override
  String get environmentsSectionOptions => 'Tùy chọn bắt đầu';

  @override
  String get environmentsSectionSeedFiles => 'Tệp khởi tạo';

  @override
  String get environmentsSectionVariables => 'Biến';

  @override
  String get environmentsSeedHelp =>
      'Mỗi dòng một đường dẫn, sao chép từ checkout đã đăng ký. Pull request từ fork không bao giờ nhận được các tệp này.';

  @override
  String get environmentsShellHelp =>
      'Trình giữ chỗ không được mở rộng ở đây. Hãy đọc các biến CC_ENV_*.';

  @override
  String get environmentsSourceApprove => 'Phê duyệt phiên bản này';

  @override
  String environmentsSourceCurrent(String path) {
    return '$path khớp với phiên bản đã phê duyệt.';
  }

  @override
  String get environmentsSourceNotice =>
      'Phiên bản đã phê duyệt vẫn chạy cho đến khi bạn phê duyệt bản này.';

  @override
  String get environmentsTabJson => 'JSON';

  @override
  String get environmentsTabSource => 'Nguồn';

  @override
  String get environmentsTestHelp =>
      'Chạy một môi trường dùng một lần từ đầu đến cuối: kiểm tra, bắt đầu, chờ sẵn sàng, hủy.';

  @override
  String get environmentsTestSaveFirst => 'Hãy lưu định nghĩa trước.';

  @override
  String get environmentsTimeoutSeconds => 'Thời gian chờ tính bằng giây';

  @override
  String get environmentsTitle => 'Môi trường';

  @override
  String get environmentsTriggerArchive => 'Trước khi xóa worktree';

  @override
  String get environmentsTriggerChange => 'Khi các đường dẫn theo dõi thay đổi';

  @override
  String get environmentsTriggerCreate => 'Một lần cho mỗi môi trường';

  @override
  String get environmentsTriggerManual => 'Theo yêu cầu';

  @override
  String get environmentsTriggerProvision => 'Khi tạo worktree';

  @override
  String get environmentsTriggerStart => 'Mỗi lần bắt đầu';

  @override
  String get environmentsTriggers => 'Chạy';

  @override
  String get environmentsUnreadable =>
      'Ứng dụng khách này không đọc được định nghĩa này.';

  @override
  String get environmentsUpdateAvailable => 'Có bản cập nhật';

  @override
  String get environmentsUseShell => 'Dùng lệnh shell';

  @override
  String get environmentsUseSourceWarning =>
      'Khi đó công cụ chạy trên checkout của bạn. Hãy xem nó là chỉ đọc.';

  @override
  String get environmentsWhenMissing => 'Khi không gian thiếu nó';

  @override
  String get environmentsWhenMissingAdd => 'Thêm vào không gian';

  @override
  String get environmentsWhenMissingSkip => 'Bỏ qua';

  @override
  String get environmentsWhenMissingSource => 'Dùng checkout đã đăng ký';

  @override
  String get environmentsUnsupported => 'Máy chủ này không hỗ trợ môi trường.';

  @override
  String get environmentViewerUnavailable =>
      'Không có trình xem: máy chủ không thể ghi lại cửa sổ này. Hãy cho phép Control Center ghi màn hình trên máy chủ.';

  @override
  String get environmentHealthHealthy => 'Khỏe';

  @override
  String get environmentHealthUnhealthy => 'Lỗi';

  @override
  String get environmentTerminalStale =>
      'Terminal này được mở trước khi môi trường khởi động nên thiếu các biến của nó.';

  @override
  String get environmentTerminalFresh => 'Mở terminal mới';

  @override
  String get environmentsShellStays =>
      'Script nhiều dòng vẫn là lệnh shell: các dòng chính là cấu trúc của nó.';

  @override
  String get environmentsOverrides => 'Ghi đè của không gian làm việc';

  @override
  String get environmentsOverridesHelp =>
      'Thiết lập riêng của tệp ở đây là chỉ đọc. Gắn các vai trò của nó với repo của không gian làm việc này, hoặc ghi đè bất kỳ trường nào bằng JSON.';

  @override
  String get environmentsReposHelp =>
      'Các kho lưu trữ môi trường này dùng, mỗi kho gắn với một vai trò.';

  @override
  String get environmentsComponentsHelp =>
      'Những gì môi trường chạy, theo thứ tự bắt đầu.';

  @override
  String get environmentsOptionsHelp =>
      'Các lựa chọn hiển thị khi bắt đầu môi trường.';

  @override
  String get environmentsVariablesHelp =>
      'Đặt trên tác vụ, tiến trình, ứng dụng và terminal của không gian.';

  @override
  String get environmentsChecksHelp =>
      'Những gì máy chủ cần để chạy môi trường này.';

  @override
  String get environmentsIdleStopHelp => 'Giá trị 0 không bao giờ dừng nó.';

  @override
  String get environmentsAnchorHelp =>
      'Không gian có kho lưu trữ này có thể bắt đầu môi trường.';

  @override
  String get environmentsRequiredHelp =>
      'Môi trường không thể chạy nếu thiếu nó.';

  @override
  String get environmentsFollowPrHeadHelp =>
      'Đồng bộ và làm mới khi head của pull request thay đổi.';

  @override
  String get environmentsRecordNeedsFix => 'Cần sửa';

  @override
  String get environmentsCheckFile => 'Tệp';

  @override
  String get environmentsDiscardBody =>
      'Các chỉnh sửa của bạn với định nghĩa này sẽ mất.';

  @override
  String get environmentsWorktreeRuns => 'Các lần chạy tác vụ worktree';

  @override
  String get environmentsNoWorktreeRuns => 'Chưa có tác vụ worktree nào chạy.';

  @override
  String get environmentsLinkRoles => 'Vai trò trong tệp này';

  @override
  String get environmentsLinkNoFile =>
      'Không đọc được tệp từ repo. Có thể gắn vai trò sau khi liên kết.';

  @override
  String get guardrailClassHostExecution => 'Chạy lệnh trên máy chủ';

  @override
  String get environmentUrls => 'URL';

  @override
  String get environmentScripts => 'Tập lệnh';

  @override
  String get environmentNoneForSpace =>
      'Không có môi trường cho không gian này';

  @override
  String get environmentNoneForPr => 'Không có môi trường cho pull request này';

  @override
  String get environmentSetupBody =>
      'Môi trường chạy các dịch vụ, tập lệnh và URL của một kho cho một không gian. Thiết lập một lần và mọi không gian trên kho đều có thể khởi động nó.';

  @override
  String get environmentSetUp => 'Thiết lập môi trường';

  @override
  String get environmentEditDefinition => 'Sửa định nghĩa';

  @override
  String get environmentOpenPanel => 'Mở môi trường';

  @override
  String get environmentStatusBlocked => 'Cần thao tác';

  @override
  String get environmentStateInTerminal => 'Trong terminal';

  @override
  String get environmentWaitingInTerminal => 'Đang chờ bạn trong terminal';

  @override
  String get environmentOpenTerminal => 'Mở terminal';

  @override
  String get environmentSignInNeeded => 'Cần bạn đăng nhập';

  @override
  String get environmentDependencyNeeded => 'Một thứ cần thiết không khả dụng';

  @override
  String get environmentStartTerminalDone =>
      'Đã xong ở đây. Môi trường vẫn đang khởi động';

  @override
  String get environmentContinueInTerminal => 'Tiếp tục trong terminal';

  @override
  String get environmentStartTerminalHint =>
      'Công cụ cần bạn nhập mật khẩu hoặc trả lời trong terminal. Quá trình khởi động sẽ tiếp tục khi xong.';

  @override
  String get environmentStartTerminalReason =>
      'Terminal này đã mở vì quá trình khởi động cần bạn';

  @override
  String get environmentStartTerminalTab => 'Thiết lập môi trường';

  @override
  String get environmentsNothingRunning =>
      'Không có gì đang chạy từ định nghĩa này.';

  @override
  String get searchPoliciesHint => 'Tìm chính sách...';

  @override
  String get noPoliciesMatch =>
      'Không có chính sách nào khớp với tìm kiếm của bạn';

  @override
  String get memoryPolicyActive => 'Đang hoạt động';

  @override
  String get memoryFactType => 'Loại';

  @override
  String get memoryTimesRecalled => 'Số lần truy hồi';

  @override
  String get memorySourceFacts => 'Dữ kiện nguồn';

  @override
  String get spaceSetupLogs => 'Nhật ký thiết lập';

  @override
  String get claudeCompactionTitle => 'Nén ngữ cảnh';

  @override
  String get claudeCompactionDescription =>
      'Cách Claude Code giữ các cuộc trò chuyện dài trong cửa sổ ngữ cảnh.';

  @override
  String get claudeAutoCompactLabel => 'Tự động nén sau';

  @override
  String claudeAutoCompactHint(String min, String max) {
    return 'Số token, từ $min đến $max. Để trống để dùng giá trị mặc định của Claude Code.';
  }

  @override
  String claudeAutoCompactInvalid(String min, String max) {
    return 'Nhập một số từ $min đến $max.';
  }

  @override
  String get claudeIdleCompactLabel =>
      'Nén các cuộc trò chuyện không hoạt động';

  @override
  String claudeIdleCompactDescription(String threshold) {
    return 'Nén cuộc trò chuyện trên $threshold token ngay trước khi bộ nhớ đệm prompt hết hạn, để quay lại sẽ tốn ít chi phí hơn. Mỗi lần nén đều dùng gói của bạn.';
  }

  @override
  String get claudeCompactionSaveFailed => 'Không thể lưu cài đặt này.';

  @override
  String get navDesktopApp => 'Ứng dụng máy tính';

  @override
  String get desktopAppSettingsSubtitle =>
      'Biểu tượng khay hệ thống, việc đóng cửa sổ và mở khi đăng nhập.';

  @override
  String get desktopSectionMenuBar => 'Thanh menu';

  @override
  String get desktopSectionTray => 'Khay hệ thống';

  @override
  String get desktopTrayTitleMac => 'Hiển thị trên thanh menu';

  @override
  String get desktopTrayTitle => 'Hiển thị trong khay hệ thống';

  @override
  String get desktopTraySubtitle =>
      'Trạng thái, việc cần bạn xử lý, các không gian và mức dùng gói của bạn, chỉ cách một cú nhấp.';

  @override
  String get desktopTrayMissingTitle => 'Không tìm thấy khay hệ thống';

  @override
  String get desktopTrayMissingBody =>
      'Môi trường desktop này không hiển thị biểu tượng khay. Trên GNOME, hãy cài tiện ích mở rộng AppIndicator rồi khởi động lại Control Center.';

  @override
  String get desktopSectionClosing => 'Đóng cửa sổ';

  @override
  String get desktopCloseTitle => 'Khi bạn đóng cửa sổ';

  @override
  String get desktopCloseKeepRunning => 'Tiếp tục chạy';

  @override
  String get desktopCloseQuit => 'Thoát';

  @override
  String get desktopCloseKeepRunningSubtitleMac =>
      'Agent và thông báo vẫn tiếp tục. Mở lại cửa sổ từ Dock hoặc thanh menu.';

  @override
  String get desktopCloseKeepRunningSubtitle =>
      'Agent và thông báo vẫn tiếp tục. Mở lại cửa sổ từ biểu tượng khay.';

  @override
  String get desktopCloseQuitSubtitle =>
      'Đóng cửa sổ sẽ thoát Control Center. Thông báo sẽ dừng cho đến khi bạn mở lại.';

  @override
  String get desktopCloseNeedsTray =>
      'Bật biểu tượng khay để Control Center tiếp tục chạy khi cửa sổ đã đóng.';

  @override
  String get desktopSectionLogin => 'Khởi động';

  @override
  String get desktopLoginTitle => 'Mở khi đăng nhập';

  @override
  String get desktopLoginSubtitle =>
      'Khởi động Control Center khi bạn đăng nhập để nhận thông báo ngay từ đầu.';

  @override
  String get desktopLoginUnsupported =>
      'Hệ thống này không hỗ trợ mở ứng dụng khi đăng nhập.';

  @override
  String get desktopLoginNeedsApproval =>
      'Hãy cho phép Control Center trong Mục đăng nhập để hoàn tất việc bật tính năng này.';

  @override
  String get desktopLoginOpenLoginItems => 'Mở Mục đăng nhập';

  @override
  String get desktopLoginRefused =>
      'Hệ thống không chấp nhận thay đổi. Có thể quản trị viên của bạn đang quản lý cài đặt này.';

  @override
  String get desktopLoginStartHiddenTitle => 'Khởi động trong nền';

  @override
  String get desktopLoginStartHiddenSubtitleMac =>
      'Mở mà không hiện cửa sổ khi đăng nhập. Tìm ứng dụng trong Dock hoặc thanh menu.';

  @override
  String get desktopLoginStartHiddenSubtitle =>
      'Mở mà không hiện cửa sổ khi đăng nhập. Tìm ứng dụng trong khay hệ thống.';

  @override
  String get desktopLoginStartHiddenNeedsTray =>
      'Cần biểu tượng khay để có cách mở cửa sổ.';

  @override
  String get closeToTrayPromptTitle => 'Để Control Center tiếp tục chạy?';

  @override
  String get closeToTrayPromptBody =>
      'Agent vẫn làm việc và thông báo vẫn đến khi cửa sổ đã đóng. Mở lại từ biểu tượng khay. Bạn có thể thay đổi điều này trong Cài đặt → Ứng dụng máy tính.';

  @override
  String get closeToTrayPromptQuit => 'Thoát';

  @override
  String get closeToTrayPromptKeepRunning => 'Tiếp tục chạy';

  @override
  String get trayStatusOffline => 'Ngoại tuyến';

  @override
  String get trayStatusReconnecting => 'Đang kết nối lại…';

  @override
  String trayStatusNeedsYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count việc cần bạn',
      one: '1 việc cần bạn',
    );
    return '$_temp0';
  }

  @override
  String trayStatusWorking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count đang hoạt động',
      one: '1 đang hoạt động',
    );
    return '$_temp0';
  }

  @override
  String get trayStatusAllQuiet => 'Mọi thứ yên ắng';

  @override
  String trayTooltip(String status) {
    return 'Control Center · $status';
  }

  @override
  String trayMenuSpaceQuestions(String space, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count câu hỏi',
      one: '1 câu hỏi',
    );
    return '$space · $_temp0';
  }

  @override
  String trayApprovalsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mục chờ phê duyệt',
      one: '1 mục chờ phê duyệt',
    );
    return '$_temp0';
  }

  @override
  String get trayMenuOpen => 'Mở Control Center';

  @override
  String get trayMenuSettings => 'Cài đặt…';

  @override
  String get trayMenuQuit => 'Thoát Control Center';

  @override
  String get trayPanelTitle => 'Control Center';

  @override
  String get trayPanelNoWorkspace =>
      'Mở Control Center để chọn một không gian làm việc.';

  @override
  String get trayPanelOpenApp => 'Mở Control Center';

  @override
  String get trayPanelSettings => 'Cài đặt ứng dụng máy tính';

  @override
  String get trayPanelNeedsYou => 'Cần bạn';

  @override
  String get trayPanelApprovals => 'Phê duyệt';

  @override
  String get trayPanelSpaces => 'Không gian';

  @override
  String get trayPanelNoSpaces => 'Chưa có không gian nào.';

  @override
  String trayPanelAllSpaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tất cả $count không gian',
      one: 'Tất cả không gian',
    );
    return '$_temp0';
  }

  @override
  String get trayPanelUsage => 'Mức dùng';

  @override
  String get trayPanelSwitchWorkspace => 'Chuyển không gian làm việc';

  @override
  String signInToProvider(String provider) {
    return 'Đăng nhập vào $provider';
  }

  @override
  String get linearConnectAutomation => 'Kết nối Linear để tự động hóa';

  @override
  String signInOpeningBrowser(String provider) {
    return 'Đang mở $provider trong trình duyệt…';
  }

  @override
  String get signInFailedTitle => 'Đăng nhập chưa hoàn tất';

  @override
  String get signInReopenPage => 'Mở lại trang đăng nhập';

  @override
  String get signInCodePrompt =>
      'Xác nhận trong trình duyệt của bạn, sau đó nhập mã mà nó hiển thị.';

  @override
  String get signInCodeMalformed =>
      'Đây có vẻ không phải mã đăng nhập. Mã gồm 8 chữ cái và chữ số.';

  @override
  String get signInCodeDeepLinkHint =>
      'Nếu trình duyệt đề nghị mở Control Center, hãy cho phép và bạn không cần gõ mã.';

  @override
  String signInSucceeded(String provider, String account) {
    return 'Đã đăng nhập vào $provider với tên $account';
  }

  @override
  String signInSucceededNoAccount(String provider) {
    return 'Đã đăng nhập vào $provider';
  }

  @override
  String get signInErrorExpired =>
      'Phiên đăng nhập này đã hết hạn. Hãy bắt đầu lại.';

  @override
  String signInErrorAccessDenied(String provider) {
    return 'Đăng nhập vào $provider đã bị hủy hoặc bị từ chối.';
  }

  @override
  String signInErrorScopeMismatch(String provider) {
    return '$provider cấp ít quyền hơn mức Control Center cần. Hãy đăng nhập lại và phê duyệt tất cả các quyền.';
  }

  @override
  String get signInErrorInvalidCode =>
      'Mã này không khớp với lần đăng nhập này. Hãy kiểm tra rồi thử lại.';

  @override
  String get signInErrorTooManyCodes =>
      'Nhập sai mã quá nhiều lần. Hãy bắt đầu đăng nhập lại.';

  @override
  String get signInErrorStaleRequest =>
      'Lượt đăng nhập này không còn mở: nó đã bị hủy, đã dùng hoặc đã được thay thế. Hãy bắt đầu lại.';

  @override
  String get signInErrorInvalidRequest =>
      'Máy chủ không đọc được yêu cầu đăng nhập này. Hãy bắt đầu lại.';

  @override
  String get signInErrorRateLimited =>
      'Hiện có quá nhiều yêu cầu. Hãy đợi một chút rồi thử lại.';

  @override
  String signInErrorStoreFailed(String provider) {
    return '$provider đã chấp nhận đăng nhập, nhưng máy chủ không lưu được. Hãy thử lại.';
  }

  @override
  String signInErrorProviderUnavailable(String provider) {
    return '$provider hiện không phản hồi. Hãy thử lại sau vài phút.';
  }

  @override
  String signInErrorExchangeFailed(String provider) {
    return '$provider đã chấp nhận đăng nhập nhưng máy chủ không thể hoàn tất. Hãy thử lại.';
  }

  @override
  String signInErrorMisconfigured(String provider) {
    return 'Ứng dụng $provider của máy chủ này bị cấu hình sai. Hãy nhờ chủ sở hữu máy chủ kiểm tra Cài đặt → Máy chủ → Đăng nhập một lần.';
  }

  @override
  String signInErrorNeedsSignIn(String provider) {
    return 'Phiên đăng nhập $provider của bạn đã hết hạn. Hãy đăng nhập lại để tiếp tục làm việc với tư cách của mình.';
  }

  @override
  String signInErrorNotInstalled(String provider) {
    return 'Ứng dụng $provider chưa được cài ở nơi cần dùng. Hãy cài đặt rồi thử lại.';
  }

  @override
  String get signInErrorTeamBoundElsewhere =>
      'Không gian làm việc Slack này đã được kết nối với một máy chủ Control Center khác.';

  @override
  String get signInErrorNotAdmin =>
      'Chỉ quản trị viên hoặc chủ sở hữu workspace Slack mới có thể kết nối nó với Control Center lần đầu. Hãy nhờ một trong số họ thêm ứng dụng.';

  @override
  String signInErrorSuspended(String provider) {
    return 'Ứng dụng $provider đang bị tạm ngưng. Hãy bỏ tạm ngưng trên $provider rồi thử lại.';
  }

  @override
  String get signInErrorInstallBlocked =>
      'Control Center Connect đã chặn máy chủ này. Hãy liên hệ người vận hành máy chủ Connect của bạn.';

  @override
  String get signInErrorUnknown =>
      'Đăng nhập thất bại vì một lý do mà máy chủ không báo. Hãy thử lại.';

  @override
  String get signInPhishingTitle => 'Đăng nhập không bắt đầu từ đây';

  @override
  String get signInPhishingBody =>
      'Lần đăng nhập này không được bắt đầu từ ứng dụng này. Nếu ai đó gửi liên kết này cho bạn, đừng tiếp tục.';

  @override
  String get signInPhishingDetail =>
      'Không có gì được gửi đi. Hoàn tất một lần đăng nhập do người khác bắt đầu sẽ kết nối tài khoản của bạn với máy chủ của họ.';

  @override
  String signInRequiredTitle(String provider) {
    return 'Cần đăng nhập $provider';
  }

  @override
  String signInRequiredBody(String provider) {
    return 'Thao tác này chạy với tư cách của bạn trên $provider, nhưng bạn chưa đăng nhập. Hãy đăng nhập rồi thử lại.';
  }

  @override
  String signInRequiredBanner(String provider) {
    return 'Bạn chưa đăng nhập vào $provider. Mọi việc bạn làm ở đây đều chạy với tư cách của bạn, vì vậy hãy đăng nhập trước.';
  }

  @override
  String signInUnavailable(String provider) {
    return 'Máy chủ này chưa thiết lập đăng nhập $provider.';
  }

  @override
  String get githubInstallations => 'Các bản cài đặt ứng dụng GitHub';

  @override
  String get githubInstallationsDescription =>
      'Nơi ứng dụng GitHub được cài đặt, trong số các tài khoản mà kho lưu trữ của không gian làm việc này thuộc về.';

  @override
  String get githubInstallationsEmpty =>
      'Ứng dụng GitHub chưa được cài trên tài khoản nào mà kho lưu trữ của không gian làm việc này thuộc về.';

  @override
  String get githubInstallApp => 'Cài ứng dụng GitHub';

  @override
  String get githubInstallationSuspended => 'Đã tạm ngưng';

  @override
  String get linearAutomationTitle => 'Tự động hóa Linear';

  @override
  String get linearAutomationHint =>
      'Cho phép các tác tử và pipeline của không gian làm việc này hoạt động trong Linear với tư cách ứng dụng thay vì một người. Quản trị viên không gian làm việc sẽ kết nối.';

  @override
  String linearAutomationConnectedAs(String account) {
    return 'Đã kết nối với $account';
  }

  @override
  String get connectModeHosted => 'Dùng ứng dụng của Control Center';

  @override
  String get connectModeHostedDisclosure =>
      'Đăng nhập đi qua Control Center Connect. Connect niêm phong mỗi lần đăng nhập để chỉ máy chủ này mở được, cấp token GitHub giới hạn trong một kho mã, không giữ khóa kho mã nào và không bao giờ nhận mã nguồn của bạn.';

  @override
  String get connectModeOwn => 'Dùng ứng dụng của riêng tôi';

  @override
  String get connectModeOwnHint =>
      'Tự đăng ký ứng dụng GitHub, Google và Linear trong Cài đặt → Máy chủ → Đăng nhập một lần, và kết nối ứng dụng Slack riêng của từng không gian làm việc trong Không gian làm việc → Tích hợp, nơi một không gian làm việc cũng có thể chọn ứng dụng riêng hoặc Connect. “Tạo ứng dụng GitHub của tôi” thiết lập GitHub chỉ trong một bước.';

  @override
  String get connectModeCustom => 'Dùng máy chủ Connect tùy chỉnh';

  @override
  String get connectModeCustomHint =>
      'Tổ chức của bạn tự vận hành máy chủ Connect. Đăng nhập sẽ đi đến đó thay vì đến máy chủ của Control Center.';

  @override
  String get connectModeUnset => 'Chưa thiết lập';

  @override
  String get connectCustomUrlLabel => 'URL máy chủ Connect';

  @override
  String get connectCustomUrlInvalid =>
      'Nhập một địa chỉ HTTPS, ví dụ https://connect.example.com.';

  @override
  String get connectCustomUrlLoopbackHint =>
      'HTTP thường chỉ tới được Connect trên máy này. Hãy dùng HTTPS cho mọi thứ trên mạng.';

  @override
  String get connectErrorHostedUnprovisioned =>
      'Các ứng dụng được lưu trữ của Control Center chưa có trong bản dựng này. Hãy dùng ứng dụng của riêng bạn hoặc máy chủ Connect tùy chỉnh.';

  @override
  String get connectErrorSignature =>
      'Cấu hình của Connect không vượt qua kiểm tra chữ ký. Đăng nhập qua Connect tạm dừng cho đến khi được xác minh lại.';

  @override
  String get connectErrorRollback =>
      'Connect cung cấp cấu hình cũ hơn cấu hình máy chủ này đã thấy, nên đã bị từ chối. Đăng nhập qua Connect đang tạm dừng.';

  @override
  String get connectErrorUnreachable =>
      'Máy chủ này hiện không kết nối được với Connect. Các lần đăng nhập dùng Connect sẽ thất bại cho đến khi nó hoạt động lại.';

  @override
  String get connectErrorInstallBlocked =>
      'Connect đã chặn ID cài đặt của máy chủ này. Hãy liên hệ người vận hành máy chủ Connect của bạn.';

  @override
  String get connectErrorPinsChanged => 'Ứng dụng của Connect đã thay đổi';

  @override
  String get connectErrorProtocol =>
      'Connect phản hồi theo cách máy chủ này không hiểu. Hãy cập nhật máy chủ hoặc kiểm tra URL của Connect.';

  @override
  String get connectErrorUnknown =>
      'Connect báo một sự cố mà không giải thích. Hãy chạy kiểm tra để thử lại.';

  @override
  String get connectPinsConfirmHint =>
      'Máy chủ Connect của bạn giờ nêu các ứng dụng GitHub, Google, Linear hoặc Slack khác với những ứng dụng máy chủ này đã ghim ở lần dùng đầu tiên. Chỉ tin tưởng chúng nếu người vận hành đã báo trước cho bạn.';

  @override
  String get connectConfirmPins => 'Tin tưởng ứng dụng mới';

  @override
  String get connectStale =>
      'Cấu hình đang dùng cũ hơn dự kiến. Hãy chạy kiểm tra để làm mới.';

  @override
  String get connectLaneSourceOwn => 'Ứng dụng riêng';

  @override
  String get connectLaneSourceConnect => 'Connect';

  @override
  String get connectLaneSourceOff => 'Tắt';

  @override
  String get connectTitle => 'Control Center Connect';

  @override
  String get connectDescription =>
      'Máy chủ này dùng ứng dụng của ai cho GitHub, Google Calendar, Linear, Slack và tìm kiếm GIF.';

  @override
  String get connectFactMode => 'Ứng dụng đăng nhập';

  @override
  String get connectFactHealth => 'Trạng thái';

  @override
  String get connectFactEpoch => 'Phiên bản cấu hình';

  @override
  String get connectHealthOff => 'Không dùng';

  @override
  String get connectHealthOk => 'Đang hoạt động';

  @override
  String get connectHealthDown => 'Không hoạt động';

  @override
  String get connectLocked =>
      'CC_CONNECT_URL trong môi trường của máy chủ này quyết định thiết lập này. Hãy đổi ở đó rồi khởi động lại máy chủ.';

  @override
  String get connectLanesTitle => 'Mỗi kiểu đăng nhập chạy ở đâu';

  @override
  String get connectLanesDescription =>
      'Ứng dụng riêng luôn được ưu tiên hơn Connect cho nhà cung cấp của nó.';

  @override
  String get connectServerGroup => 'Máy chủ này';

  @override
  String get connectInstallId => 'ID cài đặt';

  @override
  String get connectInstallIdHint =>
      'Định danh máy chủ này với Connect. Hãy đưa cho chủ sở hữu tổ chức hoặc người vận hành Connect khi họ yêu cầu.';

  @override
  String get connectInstallIdEmpty =>
      'Được cấp khi máy chủ này dùng Connect lần đầu.';

  @override
  String get connectTestOk => 'Connect đang hoạt động.';

  @override
  String get connectRotateKey => 'Xoay vòng khóa';

  @override
  String get connectRotateKeyTitle => 'Xoay vòng khóa Connect của máy chủ này?';

  @override
  String get connectRotateKeyBody =>
      'Máy chủ này nhận khóa và ID cài đặt mới, và ID cũ bị thu hồi tại Connect: các lần đăng nhập được niêm phong dưới nó, cùng khóa cũ, ngừng hoạt động ở đó, nên mọi người đã đăng nhập qua Connect sẽ phải đăng nhập lại. Các token đã phát hành vẫn hoạt động cho đến khi hết hạn. Đăng nhập qua ứng dụng riêng của bạn không bị ảnh hưởng. Nếu không thể kết nối tới Connect, không có gì thay đổi và bạn có thể thử lại.';

  @override
  String get connectRotateKeyDone =>
      'Đã xoay vòng khóa. Mọi người đã đăng nhập qua Connect cần đăng nhập lại.';

  @override
  String get connectCliLabel => 'Từ terminal';

  @override
  String get onboardingStepSignIn => 'Đăng nhập';

  @override
  String get onboardingConnectTitle => 'Chọn cách mọi người đăng nhập';

  @override
  String get onboardingConnectSubtitle =>
      'Control Center làm việc với GitHub, Google Calendar, Linear, Slack và tìm kiếm GIF thông qua các ứng dụng đã đăng ký với từng nhà cung cấp. Hãy chọn máy chủ này dùng ứng dụng của ai. Bạn có thể đổi sau trong Cài đặt → Máy chủ → Đăng nhập một lần.';

  @override
  String get onboardingConnectOwnNext =>
      'Tạo ngay một ứng dụng GitHub cho máy chủ này, hoặc thêm ứng dụng của bạn sau trong Cài đặt → Máy chủ → Đăng nhập một lần.';

  @override
  String get providerServiceApiKey => 'Khóa API dịch vụ';

  @override
  String get providerAppPartial => 'Chưa thiết lập xong';

  @override
  String providerAppMissingFields(String fields) {
    return 'Vẫn còn thiếu: $fields. Cho đến khi điền đủ mọi trường, các lần đăng nhập cho nhà cung cấp này sẽ bị từ chối thay vì chuyển qua Connect.';
  }

  @override
  String get providerAppsGroupSignInLinearDescription =>
      'Client ID dùng để thành viên đăng nhập. Khóa API dịch vụ cho phép máy chủ này tự đọc và ghi trong Linear.';

  @override
  String get providerCallbackUrls => 'URL gọi lại';

  @override
  String get providerCallbackUrlHint =>
      'Đăng ký với nhà cung cấp đúng y như hiển thị.';

  @override
  String get providerAppCreateGitHubTitle => 'Tạo ứng dụng GitHub';

  @override
  String get providerAppCreateGitHubHint =>
      'GitHub đăng ký một ứng dụng với quyền và URL gọi lại phù hợp, rồi chuyển thông tin xác thực cho máy chủ này. Không cần sao chép thủ công.';

  @override
  String get providerAppCreateGitHub => 'Tạo ứng dụng GitHub của tôi';

  @override
  String get providerAppCreateGitHubOrg => 'Tổ chức (không bắt buộc)';

  @override
  String get providerAppCreateGitHubOrgHint =>
      'Để trống để tạo ứng dụng trong tài khoản GitHub của riêng bạn. Muốn tạo trong một tổ chức thì cần chủ sở hữu của tổ chức đó.';

  @override
  String get providerAppSignInReady => 'Mọi người có thể đăng nhập.';

  @override
  String get chatLinkWaiting => 'Đang chờ tin nhắn trực tiếp của bạn…';

  @override
  String chatLinkClaimTitle(String provider) {
    return 'Đây có phải tài khoản $provider của bạn không?';
  }

  @override
  String chatLinkClaimBody(String provider) {
    return 'Tài khoản này đã gửi mã của bạn cho bot. Chỉ xác nhận nếu đó là tài khoản của bạn: sau khi liên kết, những gì nó gửi trong $provider sẽ hành động với tư cách là bạn trong không gian làm việc này.';
  }

  @override
  String get chatLinkDecline => 'Từ chối';

  @override
  String chatLinkDeclined(String provider) {
    return 'Chưa có gì được liên kết. Hãy lấy mã mới nếu bạn vẫn muốn liên kết tài khoản $provider của mình.';
  }

  @override
  String get chatLinkNewCode => 'Lấy mã mới';

  @override
  String signInAddControlCenter(String provider) {
    return 'Thêm Control Center vào $provider';
  }

  @override
  String signInAddedControlCenter(String workspace) {
    return 'Đã thêm Control Center vào $workspace';
  }

  @override
  String chatSharedAppHint(String provider) {
    return 'Cài ứng dụng Control Center dùng chung vào không gian làm việc $provider của bạn. Không cần tạo ứng dụng, cũng không cần dán token.';
  }

  @override
  String chatAddToProvider(String provider) {
    return 'Thêm vào $provider';
  }

  @override
  String get chatSharedAppConnected =>
      'Chạy trên ứng dụng Control Center dùng chung, nên ở đây không có token hay cài đặt bot nào để quản lý.';

  @override
  String get chatTicketDraftsTitle => 'Bản nháp phiếu từ chat';

  @override
  String get chatTicketDraftsDescription =>
      'Bản nháp chỉ trở thành phiếu trong backlog khi bạn tạo nó ở đây. Bản nháp bị bỏ lại sẽ bị xóa sau một ngày.';

  @override
  String chatTicketDraftFrom(String provider) {
    return 'Từ $provider';
  }

  @override
  String get chatTicketDraftCreate => 'Tạo phiếu';

  @override
  String chatTicketDraftCreated(String key) {
    return 'Đã tạo $key';
  }

  @override
  String workspaceProviderAppMissingFields(String fields) {
    return 'Còn thiếu: $fields. Cho đến khi điền đủ mọi trường, nhà cung cấp này bị tắt trong không gian làm việc này. Không chuyển sang ứng dụng của máy chủ này.';
  }

  @override
  String get workspaceProviderAppClientChangeHint =>
      'Đổi ứng dụng sẽ đăng xuất mọi người trong không gian làm việc này. Họ cần đăng nhập lại bằng ứng dụng mới.';

  @override
  String get workspaceProviderAppKlipyKey => 'Khóa ứng dụng';

  @override
  String get workspaceProviderAppKlipyHint =>
      'Tìm kiếm GIF trong không gian làm việc này sử dụng khóa này.';

  @override
  String get settingsWorkspaceIntegrations => 'Tích hợp';

  @override
  String get settingsWorkspaceIntegrationsDescription =>
      'Lưu trữ mã, phiếu việc, lịch, trò chuyện và tìm GIF trong không gian làm việc này, cùng các ứng dụng mà họ dùng để đăng nhập.';

  @override
  String get workspaceConnectDescription =>
      'Không gian làm việc này dùng ứng dụng nào cho GitHub, Google Lịch, Linear, Slack và tìm GIF. Trừ khi quản trị viên chọn khác, nó sẽ theo máy chủ này.';

  @override
  String get workspaceConnectModeInherit => 'Giống máy chủ này';

  @override
  String get workspaceConnectInheritHosted =>
      'Máy chủ này dùng ứng dụng của Control Center.';

  @override
  String workspaceConnectInheritCustom(String url) {
    return 'Máy chủ này dùng máy chủ Connect tại $url.';
  }

  @override
  String get workspaceConnectInheritOwn =>
      'Máy chủ này dùng ứng dụng riêng của nó.';

  @override
  String get workspaceConnectInheritUnset =>
      'Chủ máy chủ chưa chọn, nên ứng dụng riêng của máy chủ được áp dụng.';

  @override
  String get workspaceConnectOwnHint =>
      'Chỉ dùng ứng dụng của không gian làm việc này. Thêm từng ứng dụng bên dưới, cạnh nhà cung cấp tương ứng. Nhà cung cấp không có ứng dụng sẽ bị tắt tại đây; ứng dụng của máy chủ này và Connect không được dùng thay thế.';

  @override
  String get workspaceConnectCustomUrlHint =>
      'Chỉ HTTPS. Địa chỉ trong mạng riêng hoặc mạng cục bộ sẽ bị từ chối.';

  @override
  String get workspaceConnectLocked =>
      'CC_CONNECT_URL trong môi trường của máy chủ này quyết định nơi đăng nhập được chuyển đến, vì vậy không gian làm việc này không thể chọn Connect riêng. Nó có thể theo máy chủ này hoặc dùng ứng dụng riêng.';

  @override
  String get workspaceConnectSwitchTitle =>
      'Chuyển ứng dụng đăng nhập của không gian làm việc này?';

  @override
  String get workspaceConnectSwitchBody =>
      'Mọi người trong không gian làm việc phải đăng nhập lại vào GitHub, Linear và Google Lịch qua các ứng dụng mới. Các lần đăng nhập đã thực hiện qua ứng dụng hiện tại sẽ ngừng hoạt động tại đây.';

  @override
  String get workspaceConnectSwitchAction => 'Chuyển ứng dụng';

  @override
  String get workspaceConnectLanesDescription =>
      'Theo lựa chọn ở trên. Một nhà cung cấp không bao giờ chuyển sang ứng dụng khác.';

  @override
  String get workspaceConnectLaneWorkspaceOwn =>
      'Ứng dụng của không gian làm việc';

  @override
  String get workspaceConnectLaneServerOwn => 'Ứng dụng của máy chủ';

  @override
  String get workspaceGitHubAppTitle => 'Ứng dụng GitHub';

  @override
  String get workspaceGitHubAppOwnDescription =>
      'Ứng dụng riêng của không gian làm việc này hoạt động thay cho các kho lưu trữ của nó và đăng nhập thành viên. Nó không bao giờ chuyển sang ứng dụng của máy chủ này hoặc Connect.';

  @override
  String get workspaceGitHubAppSharedDescription =>
      'Không gian làm việc này dùng ứng dụng GitHub do các ứng dụng đăng nhập của nó cung cấp. Hãy cài đặt trên các tài khoản sở hữu kho lưu trữ của bạn.';

  @override
  String get workspaceGitHubAppActingTitle =>
      'Hoạt động thay mặt không gian làm việc này';

  @override
  String get workspaceGitHubAppActingDescription =>
      'Bot của ứng dụng bình luận, xem xét và thăm dò các pull request trong kho lưu trữ của không gian làm việc này.';

  @override
  String workspaceOwnAppTitle(String provider) {
    return 'Ứng dụng $provider';
  }

  @override
  String workspaceOwnAppDescription(String provider) {
    return 'Đăng nhập và yêu cầu $provider trong không gian làm việc này chỉ dùng ứng dụng này.';
  }

  @override
  String get workspaceGifsTitle => 'GIF';

  @override
  String get workspaceGifsSourceWorkspaceOwn =>
      'Tìm GIF dùng khóa Klipy của không gian làm việc này.';

  @override
  String get workspaceGifsSourceServerOwn =>
      'Tìm GIF dùng khóa Klipy của máy chủ này.';

  @override
  String get workspaceGifsSourceConnect =>
      'Tìm GIF chạy qua Control Center Connect.';

  @override
  String get workspaceGifsSourceOff =>
      'Tìm GIF đang tắt trong không gian làm việc này.';

  @override
  String openOnForge(String forge) {
    return 'Mở trên $forge';
  }

  @override
  String prFilesTruncatedNotice(String forge, int count) {
    return 'Đang hiển thị $count tệp đầu tiên. $forge không liệt kê phần còn lại.';
  }

  @override
  String get connectForgeToLoadPrs =>
      'Kết nối dịch vụ lưu trữ mã để tải pull request';

  @override
  String get connectForgeHint =>
      'Kết nối GitHub, GitLab hoặc Bitbucket trong Cài đặt → Bạn → Hồ sơ';

  @override
  String get addForgeRepoPrompt =>
      'Thêm ít nhất một kho mã trên GitHub, GitLab hoặc Bitbucket để xem pull request';

  @override
  String get composePrNoForgeRepo => 'Chưa chọn kho mã được lưu trữ';

  @override
  String get composePrNoForgeRepoHint =>
      'Chọn một không gian làm việc có kho mã trên GitHub, GitLab hoặc Bitbucket để mở pull request.';

  @override
  String composePrForgeNotConnected(String forge) {
    return 'Kết nối $forge để mở pull request trong kho mã này';
  }

  @override
  String connectionNeedsSignInAs(String provider, String account) {
    return 'Phiên đăng nhập $provider của bạn với tư cách $account đã hết hạn. Hãy đăng nhập lại.';
  }

  @override
  String get connectionPaused =>
      'Đã tạm dừng: dịch vụ đăng nhập của không gian làm việc này đã thay đổi';

  @override
  String connectionUnreachable(String provider) {
    return 'Hiện không kết nối được với $provider. Đang thử lại.';
  }

  @override
  String get forgeSignInBannerPausedBody =>
      'Phiên đăng nhập của bạn được giữ lại và sẽ hoạt động trở lại khi dịch vụ quay lại. Quản trị viên không gian làm việc có thể kiểm tra thiết lập đăng nhập trong Tích hợp.';

  @override
  String get signInErrorAttemptUnknown =>
      'Máy chủ đã khởi động lại. Hãy bắt đầu đăng nhập lại.';

  @override
  String signInUnavailableNotConfigured(String provider) {
    return 'Đăng nhập bằng $provider chưa được thiết lập cho không gian làm việc này.';
  }

  @override
  String signInUnavailableMisconfigured(String provider, String error) {
    return 'Đăng nhập bằng $provider được thiết lập sai: $error';
  }

  @override
  String signInUnavailableOwnAppMissing(String provider) {
    return 'Không gian làm việc này dùng ứng dụng riêng nhưng không có ứng dụng $provider.';
  }

  @override
  String signInUnavailableConnectUnprovisioned(String provider) {
    return 'Bản dựng này không thể xác minh Control Center Connect, nên đăng nhập bằng $provider bị tắt.';
  }

  @override
  String get signInUnavailableConnectPinsPending =>
      'Dịch vụ đăng nhập của không gian làm việc này đã thay đổi danh tính. Quản trị viên cần xác nhận.';

  @override
  String get signInUnavailableConnectUnreachable =>
      'Hiện không kết nối được với dịch vụ đăng nhập của không gian làm việc này.';

  @override
  String get signInUnavailableConnectUrlInvalid =>
      'Địa chỉ dịch vụ đăng nhập của không gian làm việc này bị thiếu hoặc không hợp lệ.';

  @override
  String get signInUnavailableBlockedByEnvironment =>
      'Người vận hành máy chủ đã cố định dịch vụ đăng nhập, nên lựa chọn của không gian làm việc này không áp dụng.';

  @override
  String signInUnavailableLaneNotOffered(String provider) {
    return 'Dịch vụ đăng nhập của không gian làm việc này không hỗ trợ $provider.';
  }

  @override
  String get signInOpenIntegrations => 'Mở tích hợp';

  @override
  String get signInOpenServerSettings => 'Mở cài đặt đăng nhập';

  @override
  String forgeTokenRequiredBody(String provider) {
    return 'Thao tác này chạy với tư cách của bạn trên $provider, và bạn chưa thêm token. Hãy thêm một token rồi thử lại.';
  }

  @override
  String disconnectProviderTitle(String provider) {
    return 'Ngắt kết nối $provider?';
  }

  @override
  String disconnectProviderBody(String provider) {
    return 'Bạn sẽ cần kết nối lại $provider để làm việc với các kho lưu trữ của nó.';
  }

  @override
  String disconnectScopeWorkspaceBody(String provider) {
    return 'Thao tác này chỉ ngắt kết nối $provider trong không gian làm việc này. Các không gian làm việc khác giữ kết nối riêng.';
  }

  @override
  String disconnectScopeGlobalBody(String provider) {
    return 'Thao tác này ngắt kết nối $provider trong mọi không gian làm việc dùng chung kết nối này.';
  }

  @override
  String disconnectedFromWorkspace(String provider) {
    return 'Đã ngắt kết nối $provider khỏi không gian làm việc này';
  }

  @override
  String disconnectedFromAllWorkspaces(String provider) {
    return 'Đã ngắt kết nối $provider khỏi tất cả không gian làm việc';
  }

  @override
  String repoAccessInstallTitle(String owner) {
    return 'Cài GitHub App trên $owner';
  }

  @override
  String repoAccessInstallBody(String repos) {
    return 'Tự động hóa không thể truy cập $repos cho đến khi App được cài ở đó.';
  }

  @override
  String repoAccessSelectTitle(String repos) {
    return 'Thêm $repos vào các kho lưu trữ của GitHub App';
  }

  @override
  String get repoAccessSelectBody =>
      'App đã được cài trên tài khoản này nhưng chưa thấy các kho lưu trữ này.';

  @override
  String get repoAccessChooseRepos => 'Chọn kho lưu trữ';

  @override
  String get repoAccessSuspendedTitle => 'Cài đặt GitHub App đã bị tạm ngưng';

  @override
  String repoAccessSuspendedBody(String repos) {
    return 'Tự động hóa cho $repos đang tạm dừng cho đến khi chủ sở hữu tài khoản tiếp tục cài đặt trên GitHub.';
  }

  @override
  String get repoAccessAutomationPausedTitle => 'Tự động hóa đang tạm dừng';

  @override
  String repoAccessOwnerCannotSeeBody(String repos) {
    return 'Người chịu trách nhiệm về tự động hóa của không gian làm việc này không còn thấy $repos, nên không có gì chạy ở đó thay mặt họ.';
  }

  @override
  String repoAccessOwnerNotSignedInBody(String repos) {
    return 'Người chịu trách nhiệm về tự động hóa của không gian làm việc này chưa đăng nhập vào forge, nên tự động hóa cho $repos chờ đến khi họ đăng nhập.';
  }

  @override
  String repoAccessTransient(String repos) {
    return 'Không kiểm tra được quyền truy cập vào $repos. Đang thử lại.';
  }

  @override
  String repoAccessAskAdmins(String admins) {
    return 'Hãy nhờ $admins khắc phục.';
  }

  @override
  String get repoAccessAskAnAdmin =>
      'Hãy nhờ quản trị viên không gian làm việc khắc phục.';

  @override
  String hiddenReposSignIn(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Đăng nhập vào $forge để xem pull request từ $count kho lưu trữ nữa',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoForgeAccess(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count kho lưu trữ bị ẩn vì tài khoản $forge của bạn không thấy chúng',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoGrant(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count kho lưu trữ bị ẩn vì bạn không có quyền truy cập trong không gian làm việc này',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposChecking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đang kiểm tra quyền truy cập của bạn vào $count kho lưu trữ nữa…',
    );
    return '$_temp0';
  }

  @override
  String get repoLinkAccessWarningsTitle =>
      'Đã liên kết, nhưng tự động hóa chưa truy cập được mọi thứ';

  @override
  String get githubInstallOnAnotherOrganization => 'Cài trên tổ chức khác';

  @override
  String get forgeTokenEmailLabel => 'Email tài khoản Atlassian';

  @override
  String get forgeTokenEmailInvalid =>
      'Nhập địa chỉ email của tài khoản Atlassian của bạn.';

  @override
  String get forgeTokenApiTokenLabel => 'Token API';

  @override
  String get forgeTokenBitbucketHint =>
      'Token API của Bitbucket hoạt động cùng với email của tài khoản Atlassian đã tạo ra chúng.';

  @override
  String get automationTokensTitle => 'Token tự động hóa';

  @override
  String get automationTokensRepoHint =>
      'Công việc chạy nền trên GitLab và Bitbucket, như cập nhật pull request, bình luận đánh giá AI và merge request không ai yêu cầu, dùng token truy cập của bot, không bao giờ của một người. Token riêng của kho mã được ưu tiên hơn token của không gian làm việc.';

  @override
  String get automationTokensWorkspaceHint =>
      'Dùng cho mọi kho mã GitLab hoặc Bitbucket trong không gian làm việc này chưa có token tự động hóa riêng. Công việc chạy nền ở đó hiển thị là bot của token này.';

  @override
  String get automationTokenNone =>
      'Không có token. Tự động hóa đang tạm dừng ở đây.';

  @override
  String get automationTokenFromWorkspace =>
      'Dùng token của không gian làm việc';

  @override
  String automationTokenActsAs(String name) {
    return 'Hoạt động với tư cách $name';
  }

  @override
  String get automationTokenStored => 'Đã thêm token truy cập';

  @override
  String get automationTokenRejected =>
      'Nền tảng đã từ chối token này. Hãy thay thế nó.';

  @override
  String automationTokenDialogTitle(String forge) {
    return 'Token tự động hóa $forge';
  }

  @override
  String get automationTokenGitLabHint =>
      'Dán token truy cập dự án hoặc nhóm. Token cần read_api và read_repository; thêm api và write_repository cho bình luận, merge request và push. GitLab hiển thị công việc của nó là bot của token.';

  @override
  String get automationTokenBitbucketHint =>
      'Dán token truy cập kho mã, dự án hoặc không gian làm việc có quyền đọc kho mã, cùng quyền ghi pull request cho bình luận và pull request. Token API của riêng bạn thuộc Bạn → Hồ sơ, không phải ở đây.';

  @override
  String automationTokenUnreadable(String repos) {
    return 'Đã lưu token, nhưng nó không đọc được $repos. Tự động hóa ở đó vẫn tạm dừng.';
  }

  @override
  String get automationTokenRemoveTitle => 'Xóa token tự động hóa?';

  @override
  String get automationTokenRemoveBody =>
      'Tự động hóa dựa vào token này sẽ tạm dừng cho đến khi thêm token khác.';

  @override
  String automationTokenWorkspaceTarget(String forge) {
    return 'Mọi kho mã $forge chưa có token riêng';
  }

  @override
  String repoAccessAutomationTokenMissingBody(String repos) {
    return 'Không token tự động hóa nào đọc được $repos, nên công việc chạy nền ở đó đang tạm dừng.';
  }

  @override
  String get settingsCommitsDescription =>
      'Commit từ công việc bạn bắt đầu sẽ mang tên bạn. Chọn ai khác được ghi công, và forge có hiển thị commit của bạn là đã xác minh hay không.';

  @override
  String get settingsCommitAuthorshipSection => 'Tác giả';

  @override
  String get settingsCommitAuthorshipYoursLabel => 'Công việc bạn bắt đầu';

  @override
  String get settingsCommitAuthorshipYoursBody =>
      'Bạn là tác giả và người commit, dưới email mà forge đã xác minh cho đăng nhập của bạn. Điều này bao gồm các cuộc trò chuyện với agent, pipeline bạn khởi chạy và commit bạn thực hiện trong editor.';

  @override
  String get settingsCommitAuthorshipBotLabel => 'Lần chạy tự động';

  @override
  String get settingsCommitAuthorshipBotBody =>
      'Các lần chạy được khởi chạy bởi lịch hoặc webhook sẽ commit dưới tên bot, và không bao giờ được ký.';

  @override
  String get settingsCommitAuthorshipSignInNote =>
      'Cho đến khi bạn đăng nhập vào forge trong không gian làm việc, các lần chạy của bạn ở đó sẽ commit dưới tên bot.';

  @override
  String get settingsCoauthorCreditTitle =>
      'Ghi công Control Center là đồng tác giả';

  @override
  String get settingsCoauthorCreditDescription =>
      'Commit của bạn ghi Control Center (@usectrl) là đồng tác giả, và các lần chạy tự động bạn đã kích hoạt sẽ ghi tên bạn. Khi tắt, không dòng nào được thêm vào.';

  @override
  String get settingsCoauthorCreditWorkspaceOverride =>
      'Thiết lập của không gian làm việc này thay thế lựa chọn cá nhân của bạn. Tùy chọn của bạn vẫn được lưu nhưng không áp dụng tại đây.';

  @override
  String get settingsCoauthorCreditLoading => 'Đang tải thiết lập ghi công…';

  @override
  String get settingsWorkspaceCoauthorCreditTitle => 'Ghi công đồng tác giả';

  @override
  String get settingsWorkspaceCoauthorCreditDescription =>
      'Commit có mang dòng đồng tác giả hay không: Control Center trên commit của thành viên, và các thành viên đã kích hoạt lần chạy tự động trên commit của nó. Lựa chọn ở đây ghi đè lựa chọn của từng thành viên.';

  @override
  String get settingsWorkspaceCoauthorCreditInherit =>
      'Dùng tùy chọn của từng thành viên';

  @override
  String get settingsWorkspaceCoauthorCreditAlways =>
      'Luôn thêm ghi công đồng tác giả';

  @override
  String get settingsWorkspaceCoauthorCreditNever =>
      'Không bao giờ thêm ghi công đồng tác giả';

  @override
  String get settingsCommitSigningSection => 'Commit đã xác minh';

  @override
  String get settingsCommitSigningStatusOn => 'Đang ký';

  @override
  String get settingsCommitSigningStatusOff => 'Không ký';

  @override
  String get settingsCommitSigningIntro =>
      'Máy chủ này có thể ký commit của bạn bằng khóa riêng của bạn, để GitHub và GitLab hiển thị chúng là đã xác minh. Chưa có gì được ký cho đến khi bạn tạo khóa.';

  @override
  String get settingsCommitSigningCreate => 'Tạo khóa ký';

  @override
  String get settingsCommitSigningCreated =>
      'Đã tạo khóa ký. Hãy thêm vào tài khoản forge của bạn.';

  @override
  String get settingsCommitSigningPublicKeyLabel => 'Khóa công khai';

  @override
  String get settingsCommitSigningKeyCopied => 'Đã sao chép khóa công khai';

  @override
  String get settingsCommitSigningFingerprintLabel => 'Dấu vân tay';

  @override
  String get settingsCommitSigningCreatedLabel => 'Đã tạo';

  @override
  String get settingsCommitSigningAddTitle =>
      'Thêm vào tài khoản forge của bạn';

  @override
  String get settingsCommitSigningAddDescription =>
      'Commit chỉ hiển thị là đã xác minh khi bạn cũng đang đăng nhập vào forge đó trong không gian làm việc, để forge xác nhận email của bạn.';

  @override
  String get settingsCommitSigningGitHubSteps =>
      'Settings → SSH and GPG keys → New SSH key. Đặt Key type thành Signing Key.';

  @override
  String get settingsCommitSigningGitLabSteps =>
      'Preferences → SSH Keys. Đặt Usage type thành Signing.';

  @override
  String get settingsCommitSigningBitbucketSteps =>
      'Commit trên Bitbucket không được ký. Đừng thêm khóa này vào tài khoản Bitbucket của bạn: khóa SSH ở đó cũng là một đăng nhập.';

  @override
  String get settingsCommitSigningUnsupported => 'Không được hỗ trợ';

  @override
  String get settingsCommitSigningTrustTitle => 'Bạn đang tin tưởng điều gì';

  @override
  String get settingsCommitSigningTrustPrivate =>
      'Khóa riêng không bao giờ rời khỏi máy chủ này.';

  @override
  String get settingsCommitSigningTrustControl =>
      'Bất kỳ ai kiểm soát máy chủ này đều có thể ký commit thay bạn chừng nào khóa còn trên tài khoản forge của bạn.';

  @override
  String get settingsCommitSigningTrustVerified =>
      'Trên GitHub, các commit đã hiển thị là đã xác minh vẫn được giữ xác minh sau khi bạn xóa khóa.';

  @override
  String get settingsCommitSigningDelete => 'Xóa khóa';

  @override
  String get settingsCommitSigningDeleteTitle => 'Xóa khóa ký của bạn?';

  @override
  String get settingsCommitSigningDeleteBody =>
      'Từ giờ commit của bạn sẽ không được ký. Khóa vẫn còn trên tài khoản forge của bạn cho đến khi bạn xóa nó ở đó.';

  @override
  String get settingsCommitSigningDeleted => 'Đã xóa khóa ký';

  @override
  String settingsCommitSigningLoadFailed(String error) {
    return 'Không thể tải khóa ký của bạn: $error';
  }

  @override
  String get accountProfileTitle => 'Hồ sơ';

  @override
  String get accountProfileDescription =>
      'Bạn là ai trong mọi không gian làm việc, cùng các tài khoản lưu trữ mã, phiếu, lịch và trò chuyện do chính bạn kết nối.';

  @override
  String get accountSectionTitle => 'Tài khoản';

  @override
  String get accountSectionDescription =>
      'Tên người dùng và tên của bạn đi theo bạn vào mọi không gian làm việc. Một không gian làm việc có thể hiển thị tên hoặc email khác: đặt điều đó trong Không gian làm việc → Hồ sơ & danh tính.';

  @override
  String accountLoadFailed(String error) {
    return 'Không thể tải hồ sơ của bạn: $error';
  }

  @override
  String get accountDisplayNameHint =>
      'Tên mà mọi người thấy trên tin nhắn và đánh giá của bạn.';

  @override
  String get accountDisplayNameRequired => 'Nhập tên hiển thị.';

  @override
  String get accountFieldCannotBeCleared =>
      'Có thể thay đổi nhưng không thể xóa.';

  @override
  String get accountAvatarLabel => 'Ảnh';

  @override
  String get accountAvatarHint =>
      'Liên kết tới ảnh vuông, bắt đầu bằng https://.';

  @override
  String get accountAvatarInvalid => 'Dùng liên kết bắt đầu bằng https://.';

  @override
  String get usernameLabel => 'Tên người dùng';

  @override
  String get usernameRule =>
      '2 đến 32 chữ cái thường, chữ số, dấu chấm, dấu gạch ngang hoặc gạch dưới. Mọi người nhắc đến bạn bằng tên này.';

  @override
  String get usernameAvailable => 'Có thể dùng.';

  @override
  String usernameAvailableAs(String username) {
    return 'Có thể dùng. Sẽ được lưu thành $username.';
  }

  @override
  String get usernameInvalid =>
      'Dùng 2 đến 32 chữ cái thường, chữ số, “.”, “_” hoặc “-”, bắt đầu và kết thúc bằng chữ cái hoặc chữ số.';

  @override
  String get usernameReserved => 'Tên người dùng đó đã được dành riêng.';

  @override
  String get usernameTaken => 'Tên người dùng đó đã có người dùng.';

  @override
  String get usernameCheckFailed =>
      'Hiện không thể kiểm tra tên này. Bạn vẫn có thể lưu; máy chủ sẽ quyết định.';

  @override
  String get linkedAccountsTitle => 'Tài khoản đã kết nối';

  @override
  String get linkedAccountsIdentityProvider => 'Nhà cung cấp danh tính';

  @override
  String get linkedAccountStatusNeedsSignIn => 'Cần đăng nhập';

  @override
  String get linkedAccountStatusPaused => 'Đã tạm dừng';

  @override
  String get linkedAccountStatusUnreachable => 'Không kết nối được';

  @override
  String get ssoIdentityDescription =>
      'Nhà cung cấp danh tính mà tài khoản của bạn đăng nhập qua. Người quản lý máy chủ này sẽ quản lý nó.';

  @override
  String get settingsAccountsDescription =>
      'Các tài khoản bạn kết nối cho riêng mình. Control Center hoạt động thay bạn qua các tài khoản này, và thay đổi chúng chỉ ảnh hưởng đến bạn.';

  @override
  String get accountReachServer =>
      'Được dùng trong mọi không gian làm việc trên máy chủ này.';

  @override
  String accountReachWorkspace(String workspace) {
    return 'Chỉ dùng trong $workspace.';
  }

  @override
  String forgeReachGitHubOwnApp(String workspace) {
    return 'GitHub chỉ được dùng trong $workspace, nơi có các ứng dụng đăng nhập riêng. GitLab và Bitbucket được dùng trong mọi không gian làm việc trên máy chủ này.';
  }

  @override
  String get yourAccountLabel => 'Tài khoản của bạn';

  @override
  String yourAccountEntry(String provider, String detail) {
    return '$provider: $detail';
  }

  @override
  String yourAccountLineSemantics(String status) {
    return 'Tài khoản của bạn: $status. Mở Bạn → Hồ sơ.';
  }

  @override
  String get yourForgeAccountNone => 'Chưa kết nối tài khoản lưu trữ mã nào';

  @override
  String yourAccountNotConnected(String provider) {
    return 'Chưa kết nối tài khoản $provider';
  }

  @override
  String yourChatAccountNotLinked(String provider) {
    return 'Chưa liên kết tài khoản $provider';
  }

  @override
  String get demoUnavailableAccount =>
      'Bạn là khách tạm thời trong bản demo, nên không có tài khoản để thay đổi: không có tên người dùng, hồ sơ hay tài khoản đã kết nối.';

  @override
  String get onboardingStepYou => 'Bạn';

  @override
  String get onboardingYouTitle => 'Chọn tên người dùng của bạn';

  @override
  String get onboardingYouSubtitle =>
      'Tên người dùng là cách mọi người nhắc đến bạn và cách công việc của bạn được gắn nhãn. Bạn có thể đổi tên này và tên hiển thị sau trong Cài đặt → Bạn → Hồ sơ.';

  @override
  String signInErrorAccountAlreadyBound(String provider) {
    return 'Tài khoản $provider này đã được kết nối với người khác trên máy chủ này. Hãy đăng nhập bằng một tài khoản $provider khác.';
  }

  @override
  String forgeTokenExpiresOn(String date) {
    return 'Token hết hạn $date';
  }

  @override
  String forgeTokenExpiredOn(String date) {
    return 'Token đã hết hạn $date. Dán token mới để tiếp tục hoạt động.';
  }

  @override
  String personTokenUnreachable(String forge) {
    return 'Không thể kết nối tới $forge để kiểm tra token này. Vui lòng thử lại sau.';
  }

  @override
  String personTokenRejected(String forge) {
    return '$forge không chấp nhận token này. Hãy kiểm tra xem bạn đã sao chép đầy đủ và token chưa bị thu hồi.';
  }

  @override
  String personTokenWrongKind(String forge) {
    return 'Đây không phải token cá nhân. Hãy dán personal access token từ tài khoản $forge của chính bạn, không phải token của dự án, nhóm, không gian làm việc hoặc bot.';
  }

  @override
  String personTokenNarrowScope(String scope) {
    return 'Token này thiếu quyền $scope, thứ cần cho việc đánh giá và bình luận. Hãy tạo một token có quyền đó.';
  }

  @override
  String get personTokenExpired =>
      'Token này đã hết hạn. Hãy tạo token mới và dán vào đây.';

  @override
  String get settingsCommitSigningTrustAgents =>
      'Các agent bạn khởi chạy có thể tạo commit được ký dưới tên bạn, trong bất kỳ repository nào chúng làm việc. Xóa khóa tại đây sẽ dừng việc đó ngay: các lần chạy đang diễn ra sẽ không ký thêm gì nữa.';

  @override
  String connectRotateKeyFailed(String error) {
    return 'Khóa chưa được thay đổi và không có gì thay đổi: $error Hãy thử lại.';
  }

  @override
  String get noWorkspaceInviteTitle =>
      'Bạn chưa ở trong không gian làm việc nào';

  @override
  String get noWorkspaceInviteBody =>
      'Quản trị viên không gian làm việc cần mời bạn, hoặc chủ sở hữu máy chủ có thể tạo không gian làm việc cho bạn. Nó sẽ mở ở đây ngay khi bạn được thêm vào.';

  @override
  String noWorkspaceSignedInAs(String name) {
    return 'Đã đăng nhập với tên $name';
  }

  @override
  String get noWorkspaceCheckAgain => 'Kiểm tra lại';

  @override
  String get noWorkspaceSignOut => 'Đăng xuất';

  @override
  String get workspaceCreateOwnerOnly =>
      'Chỉ chủ sở hữu máy chủ mới có thể tạo không gian làm việc. Hãy nhờ họ tạo một cái, hoặc nhờ quản trị viên không gian làm việc mời bạn.';

  @override
  String repoLinkNoWorkspaceToAddTo(String repo) {
    return '$repo không nằm trong bất kỳ không gian làm việc nào của bạn, và bạn không ở trong không gian làm việc nào để thêm nó vào. Hãy nhờ quản trị viên không gian làm việc mời bạn.';
  }

  @override
  String get serverOwnerOnly =>
      'Chỉ chủ sở hữu máy chủ mới có thể làm việc này';

  @override
  String get ideCodeServerOwnerOnlyHint =>
      'Trình soạn thảo đầy đủ chạy trên chính máy của máy chủ, nên chỉ chủ sở hữu máy chủ mới mở được. Bạn vẫn có thể mở và chỉnh sửa tệp từ Explorer.';

  @override
  String get terminalSandboxedBadge => 'Sandbox';

  @override
  String get terminalSandboxedHint =>
      'Chạy trong sandbox bên trong các thư mục của không gian làm việc này, nên một số công cụ và đường dẫn của máy chủ không khả dụng ở đây.';

  @override
  String get terminalHostShellOwnerOnly =>
      'Shell của máy chủ chạy trên máy chủ mà không có sandbox, nên chỉ chủ sở hữu máy chủ mới mở được. Terminal thông thường chạy trong sandbox.';

  @override
  String get terminalOutsideWorkspace =>
      'Terminal chỉ có thể mở bên trong các thư mục của chính không gian làm việc này.';

  @override
  String get environmentHostOwnerOnly =>
      'Chỉ chủ sở hữu máy chủ mới có thể lưu hoặc phê duyệt môi trường chạy trên máy chủ. Quản trị viên không gian làm việc có thể dùng môi trường chạy trong rig.';

  @override
  String get settingsCommitsNoHooks =>
      'Commit bạn thực hiện trong trình soạn thảo của ứng dụng không chạy Git hook nào từ repository, giống như git commit --no-verify: máy chủ chạy Git trên chính máy của nó, trong một cây thư mục mà agent và pull request có thể thay đổi.';

  @override
  String get mcpTokenDescription =>
      'Các client MCP gửi token này trong mỗi yêu cầu, dưới dạng tiêu đề Authorization: Bearer. Máy chủ tạo token khi khởi động lần đầu; bạn có thể đổi mới nhưng không thể xóa.';

  @override
  String get mcpShowToken => 'Hiện token';

  @override
  String get mcpHideToken => 'Ẩn token';

  @override
  String get mcpRotateToken => 'Đổi token';

  @override
  String get mcpRotateTokenTitle => 'Đổi token MCP?';

  @override
  String get mcpRotateTokenBody =>
      'Máy chủ chuyển sang token mới ngay lập tức. Mọi client MCP vẫn dùng token hiện tại sẽ bị từ chối cho đến khi bạn cung cấp token mới.';

  @override
  String get mcpTokenRotated =>
      'Đã đổi token. Hãy cung cấp token mới cho các client MCP của bạn.';

  @override
  String get mcpOwnerOnlyTitle => 'Endpoint MCP dành cho chủ sở hữu máy chủ';

  @override
  String get mcpOwnerOnlyBody =>
      'Token của nó mở mọi công cụ trên máy chủ này, nên chỉ chủ sở hữu máy chủ mới có thể xem, đổi, hoặc bật và tắt endpoint.';

  @override
  String get activityRotatedMcpToken => 'Đã đổi token MCP';

  @override
  String get connectRotateKeyRetireFailedTitle =>
      'Connect không thể thu hồi khóa cũ';

  @override
  String get connectRotateKeyForceBody =>
      'Không có gì thay đổi. Nếu bạn vẫn đổi, máy chủ này sẽ nhận khóa mới, nhưng danh tính cũ vẫn dùng được tại Connect đó cho đến khi các lần đăng nhập của nó hết hạn.';

  @override
  String get connectRotateKeyAnyway => 'Vẫn đổi';

  @override
  String get settingsAuditLog => 'Nhật ký kiểm toán';

  @override
  String get settingsAuditLogDescription =>
      'Ai đã thay đổi gì, ở đâu và kết thúc ra sao, trên toàn bộ máy chủ và mọi không gian làm việc bạn quản trị. Thao tác của máy chủ chỉ ghi tên đối số, không ghi giá trị.';

  @override
  String get auditLogNoAccessTitle => 'Chỉ dành cho quản trị viên';

  @override
  String get auditLogNoAccess =>
      'Nhật ký kiểm toán bao phủ máy chủ và các không gian làm việc bạn quản trị. Bạn không quản trị không gian làm việc nào, nên không có gì để hiển thị.';

  @override
  String get auditLogSourceServer => 'Máy chủ';

  @override
  String get auditLogSourceWorkspace => 'Không gian làm việc';

  @override
  String get auditLogAddFilter => 'Bộ lọc';

  @override
  String get auditLogFilterOptionsHint => 'Lọc…';

  @override
  String get auditLogFilterActor => 'Người thực hiện';

  @override
  String get auditLogFilterSource => 'Không gian làm việc';

  @override
  String get auditLogFilterOutcome => 'Kết quả';

  @override
  String get auditLogFilterTime => 'Thời gian';

  @override
  String auditLogFilterChip(String category, String values) {
    return '$category: $values';
  }

  @override
  String auditLogFilterChipMore(String values, int count) {
    return '$values +$count';
  }

  @override
  String get auditLogOutcomeOk => 'Thành công';

  @override
  String get auditLogOutcomeDenied => 'Từ chối';

  @override
  String get auditLogOutcomeFailed => 'Thất bại';

  @override
  String get auditLogTimeAtOrAfter => 'Từ lúc trở đi';

  @override
  String get auditLogTimeAfter => 'Sau';

  @override
  String get auditLogTimeBefore => 'Trước';

  @override
  String get auditLogTimeAtOrBefore => 'Trước hoặc đúng lúc';

  @override
  String auditLogTimeChip(String operator, String time) {
    return 'Thời gian $operator $time';
  }

  @override
  String get auditLogTimePresetHour => '1 giờ trước';

  @override
  String get auditLogTimePresetDay => '24 giờ trước';

  @override
  String get auditLogTimePresetWeek => '7 ngày trước';

  @override
  String get auditLogTimePresetMonth => '30 ngày trước';

  @override
  String get auditLogTimeExact => 'Thời điểm cụ thể';

  @override
  String get auditLogTimeInvalid => 'Nhập YYYY-MM-DD, có thể kèm HH:MM';

  @override
  String get auditLogTimeAdd => 'Thêm';

  @override
  String repoAccessReplacedTitle(String repo) {
    return '$repo giờ trỏ tới một kho lưu trữ khác';
  }

  @override
  String repoAccessReplacedBody(String forge) {
    return 'Đường dẫn này giờ trỏ tới một kho lưu trữ khác trên $forge. Hãy liên kết lại để tiếp tục sử dụng.';
  }

  @override
  String get repoRelink => 'Liên kết lại';

  @override
  String repoRelinked(String repo) {
    return 'Đã liên kết lại $repo.';
  }

  @override
  String get repoCodeRepoReplaced =>
      'Đường dẫn này giờ trỏ tới một kho lưu trữ khác. Quản trị viên không gian làm việc cần liên kết lại trước khi có thể sử dụng.';

  @override
  String repoCodeForgeCannotRead(String forge) {
    return 'Tài khoản $forge của bạn không thể đọc kho lưu trữ này.';
  }

  @override
  String repoCodeForgeUnconfirmed(String forge) {
    return 'Không thể xác nhận quyền truy cập $forge của bạn. Hãy thử lại.';
  }

  @override
  String get repoCodeForgeCannotReadUnnamed =>
      'Tài khoản forge của bạn không thể đọc kho lưu trữ này.';

  @override
  String get repoCodeForgeUnconfirmedUnnamed =>
      'Không thể xác nhận quyền truy cập forge của bạn. Hãy thử lại.';

  @override
  String get repoPathHostPath =>
      'Chỉ chủ sở hữu máy chủ mới có thể liên kết thư mục nằm ngoài bộ nhớ của không gian làm việc này.';

  @override
  String get repoPathMissing =>
      'Không có gì tồn tại tại đường dẫn đó trên máy chủ.';

  @override
  String get repoPathDataDir =>
      'Kho lưu trữ không thể trỏ vào thư mục dữ liệu của máy chủ.';

  @override
  String get repoPathWorkspaceRoot =>
      'Kho lưu trữ không thể là chính thư mục gốc của không gian làm việc.';

  @override
  String get repoPathOriginMismatch =>
      'Origin của thư mục đó là một kho lưu trữ khác.';

  @override
  String repoGrantNeedsSignIn(String forge) {
    return 'Đã lưu. Họ cần đăng nhập vào $forge trước khi có thể mở kho lưu trữ này.';
  }

  @override
  String repoGrantCannotRead(String forge) {
    return 'Đã lưu. Tài khoản $forge của họ chưa thể đọc kho lưu trữ này, nên nó vẫn bị ẩn đối với họ.';
  }

  @override
  String repoGrantUnconfirmed(String forge) {
    return 'Đã lưu. Hiện không thể xác nhận quyền truy cập $forge của họ.';
  }

  @override
  String repoLinkAskOwnerToAdd(String repo) {
    return '$repo chưa được liên kết trong bất kỳ không gian làm việc nào của bạn. Hãy nhờ chủ sở hữu máy chủ thêm nó.';
  }

  @override
  String get reposEmptyAskOwner =>
      'Chủ sở hữu máy chủ thêm kho lưu trữ từ các thư mục của máy chủ.';

  @override
  String get accountEmailUnconfirmedHint =>
      'Chỉ có bạn nhập địa chỉ này. Đăng nhập một lần (SSO) sẽ không khớp với nó cho đến khi chủ sở hữu máy chủ xác nhận.';

  @override
  String get settingsServerPeople => 'Mọi người';

  @override
  String get settingsServerPeopleDescription =>
      'Tất cả những ai có tài khoản trên máy chủ này, và địa chỉ email của họ đã được xác nhận hay chưa.';

  @override
  String get serverPeopleLabel => 'Tài khoản';

  @override
  String get serverPeopleOwnerOnly =>
      'Chỉ chủ sở hữu máy chủ mới có thể xem tất cả tài khoản và xác nhận địa chỉ email.';

  @override
  String get serverPeopleEmailNotConfirmed => 'Email chưa được xác nhận';

  @override
  String get serverPeopleConfirmEmail => 'Xác nhận email';

  @override
  String serverPeopleConfirmEmailBody(String email, String name) {
    return 'Xác nhận rằng $email thuộc về $name? Đăng nhập một lần (SSO) sẽ khớp địa chỉ này với tài khoản của họ.';
  }

  @override
  String serverPeopleEmailConfirmed(String email) {
    return 'Đã xác nhận $email.';
  }

  @override
  String get runSandboxUnavailableTitle => 'Agent cần sandbox trên máy chủ này';

  @override
  String get runSandboxUnavailable =>
      'Máy chủ này không có sandbox, nên chỉ chủ sở hữu của nó mới có thể chạy agent ở đây. Chủ sở hữu có thể cài đặt sandbox hoặc tắt sandboxing cho tất cả mọi người.';

  @override
  String get repoPathIssueHostPath =>
      'Thư mục này nằm ngoài bộ nhớ của không gian làm việc. Hãy xác nhận rằng máy chủ này được phép sử dụng nó.';

  @override
  String get repoPathIssueHostPathAskOwner =>
      'Thư mục này nằm ngoài bộ nhớ của không gian làm việc. Chỉ chủ sở hữu máy chủ mới có thể xác nhận.';

  @override
  String get repoPathIssueMissing =>
      'Hiện không còn gì tồn tại tại đường dẫn này trên máy chủ. Hãy xóa kho lưu trữ này và thêm lại từ thư mục hiện tại của nó.';

  @override
  String get repoPathIssueUnusable =>
      'Thư mục này không thể dùng làm kho lưu trữ. Hãy xóa nó và thêm kho lưu trữ từ thư mục khác.';

  @override
  String get repoPathConfirm => 'Xác nhận';

  @override
  String get repoPathConfirmAll => 'Xác nhận tất cả';

  @override
  String repoPathConfirmAllTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thư mục nằm ngoài bộ nhớ của không gian làm việc',
      one: '1 thư mục nằm ngoài bộ nhớ của không gian làm việc',
    );
    return '$_temp0';
  }

  @override
  String get repoPathConfirmAllBody =>
      'Xác nhận rằng máy chủ này được phép sử dụng chúng. Mỗi kho lưu trữ sẽ được kiểm tra lại với quyền truy cập của bạn.';

  @override
  String repoCodeNeedsSignIn(String provider) {
    return 'Đăng nhập vào $provider để xem mã của kho lưu trữ này.';
  }

  @override
  String get repoCodeSignIn => 'Đăng nhập';

  @override
  String get ideContentSearchFailed => 'Không thể tìm kiếm trong tệp';

  @override
  String get ideWorktreeFileUnavailable =>
      'Tệp này không khả dụng trong worktree này.';

  @override
  String get ideChangesLoadFailed => 'Không thể tải các thay đổi';

  @override
  String repoCodeRepoReplacedOn(String forge) {
    return 'Đường dẫn này giờ trỏ tới một kho lưu trữ khác trên $forge. Quản trị viên không gian làm việc cần liên kết lại trước khi có thể sử dụng.';
  }

  @override
  String get backupRestoreServerOwnerOnly =>
      'Chỉ chủ sở hữu máy chủ mới có thể khôi phục bản sao lưu. Bạn vẫn có thể tải chúng xuống.';

  @override
  String get terminalReadOnlyBadge => 'Chỉ đọc';

  @override
  String get terminalReadOnlyHint =>
      'Bạn có thể xem terminal này. Gõ, đổi kích thước hoặc dừng nó cần quyền ghi trên mọi kho lưu trữ trong cuộc trò chuyện này.';

  @override
  String get environmentOperateNeedsWrite =>
      'Bạn có thể xem môi trường này. Khởi động, dừng hoặc khởi động lại nó cần quyền ghi trên mọi kho lưu trữ trong cuộc trò chuyện này.';

  @override
  String get environmentHostApprovalOwner =>
      'Chạy trên máy chủ này. Hãy phê duyệt để cho phép nó khởi động.';

  @override
  String get environmentHostApprovalMember =>
      'Chạy trên máy chủ này. Chủ sở hữu máy chủ cần phê duyệt trước khi nó có thể khởi động.';

  @override
  String get environmentHostApprove => 'Phê duyệt';

  @override
  String get environmentHostApproveNeedsAdmin =>
      'Hãy phê duyệt với tư cách quản trị viên không gian làm việc: chỉ bản sao của quản trị viên mới hiển thị giá trị bí mật, và việc phê duyệt sẽ lưu lại các giá trị đó.';

  @override
  String get environmentHostUnapproved =>
      'Chủ sở hữu máy chủ chưa phê duyệt môi trường này, nên nó không thể chạy trên máy chủ này.';

  @override
  String get environmentHostUnapprovedOwner =>
      'Bạn chưa phê duyệt môi trường này. Nó chạy trên máy chủ này, nên sẽ khởi động khi bạn phê duyệt định nghĩa của nó.';

  @override
  String get environmentHostApprovalReview => 'Xem xét và phê duyệt';

  @override
  String spaceAccessNeedsSignIn(String provider) {
    return 'Đăng nhập vào $provider để mở không gian này.';
  }

  @override
  String spaceAccessForgeCannotRead(String forge) {
    return 'Tài khoản $forge của bạn không thể đọc một kho lưu trữ mà không gian này sử dụng.';
  }

  @override
  String get spaceAccessForgeCannotReadUnnamed =>
      'Tài khoản forge của bạn không thể đọc một kho lưu trữ mà không gian này sử dụng.';

  @override
  String get spaceAccessNoGrant =>
      'Bạn không có quyền đọc đối với một kho lưu trữ mà không gian này sử dụng. Quản trị viên không gian làm việc có thể cấp quyền.';

  @override
  String get spaceAccessFailed => 'Không thể mở không gian này.';

  @override
  String get contextExplorerRefused =>
      'Phần phân tích ngữ cảnh không khả dụng trong phiên này.';

  @override
  String get repoLinkForgeRemoteRequired =>
      'Một kho lưu trữ được liên kết cần cả tên chủ sở hữu và tên kho lưu trữ.';

  @override
  String get repoCodeNoReadGrant =>
      'Bạn không có quyền đọc kho lưu trữ này. Quản trị viên không gian làm việc có thể cấp quyền.';

  @override
  String get repoCodeNoWriteGrant =>
      'Bạn có thể đọc kho lưu trữ này nhưng không thể thay đổi. Quản trị viên không gian làm việc có thể cấp quyền ghi.';

  @override
  String get repoCodeNoReviewGrant =>
      'Bạn có thể đọc kho lưu trữ này nhưng không thể duyệt. Quản trị viên không gian làm việc có thể cấp quyền duyệt.';

  @override
  String get rigWatchOnlyBadge => 'Chỉ xem';

  @override
  String get rigWatchOnlyHint =>
      'Bạn có thể xem máy này. Điều khiển máy, chuyển tiếp cổng, dán nội dung vào hoặc thả tệp vào máy cần quyền ghi trên mọi kho lưu trữ trong không gian này.';

  @override
  String get rigStartNeedsWrite =>
      'Khởi động máy ở đây cần quyền ghi trên mọi kho lưu trữ trong không gian này. Quản trị viên không gian làm việc có thể cấp quyền.';

  @override
  String get rigViewRefused =>
      'Bạn không thể xem máy này. Máy thuộc một không gian mà bạn không có quyền đọc.';

  @override
  String get rigPortsWatchOnly =>
      'Thay đổi các cổng này cần quyền ghi trên mọi kho lưu trữ trong không gian này.';

  @override
  String get rigHolderOnly =>
      'Chỉ người mà máy này được mở cho mới có thể điều khiển. Máy dùng tài khoản đăng nhập của chính người đó.';

  @override
  String get rigHolderOnlyHint =>
      'Bạn có thể xem máy này. Máy dùng tài khoản đăng nhập của người mà máy được mở cho, nên chỉ người đó mới có thể điều khiển, chuyển tiếp cổng, dán nội dung vào hoặc thả tệp vào máy.';

  @override
  String get refusalStorageBusy =>
      'Cơ sở dữ liệu của máy chủ đang bận. Vui lòng thử lại sau ít phút.';

  @override
  String get refusalStorageFull =>
      'Ổ đĩa của máy chủ đã đầy nên không lưu được gì. Chủ sở hữu máy chủ cần giải phóng bớt dung lượng.';

  @override
  String get refusalStorageDamaged =>
      'Dữ liệu của không gian làm việc này bị hỏng. Chủ sở hữu máy chủ cần khôi phục từ bản sao lưu.';

  @override
  String get refusalStorageReadOnly =>
      'Không gian làm việc này chỉ đọc cho đến khi chủ sở hữu máy chủ khôi phục từ bản sao lưu, nên không thể lưu thay đổi.';

  @override
  String get refusalStorageNewerSchema =>
      'Dữ liệu này được ghi bởi phiên bản máy chủ mới hơn. Hãy cập nhật máy chủ rồi thử lại.';

  @override
  String get refusalStorageForeignFile =>
      'Máy chủ tìm thấy một tệp cơ sở dữ liệu không do nó ghi. Chủ sở hữu máy chủ cần kiểm tra thư mục dữ liệu của máy chủ.';

  @override
  String get refusalWorkspaceDeleted => 'Không gian làm việc này đã bị xóa.';

  @override
  String get refusalIdempotencyInProgress =>
      'Yêu cầu này vẫn đang được xử lý. Hãy đợi xong rồi kiểm tra kết quả.';

  @override
  String get refusalImportMissingSource =>
      'Không có tệp nào ở đường dẫn này trên máy chủ. Chưa thay thế gì cả.';

  @override
  String get refusalImportDamaged =>
      'Tệp này bị hỏng nên không thể khôi phục. Chưa thay thế gì cả.';

  @override
  String get refusalImportChecksumMismatch =>
      'Tệp này không khớp với checksum mà bản sao lưu đã ghi, nên có thể đã bị thay đổi hoặc hỏng. Chưa thay thế gì cả.';

  @override
  String get refusalImportNewerSchema =>
      'Tệp này được ghi bởi phiên bản máy chủ mới hơn. Hãy cập nhật máy chủ để khôi phục. Chưa thay thế gì cả.';

  @override
  String get refusalImportForeignFile =>
      'Tệp này không phải cơ sở dữ liệu của không gian làm việc. Chưa thay thế gì cả.';

  @override
  String get refusalImportSchemaMismatch =>
      'Tệp này không thể chuyển sang định dạng của máy chủ này. Chưa thay thế gì cả.';

  @override
  String get refusalImportRouteConflict =>
      'Tệp này chứa các liên kết thuộc về không gian làm việc khác trên máy chủ này, và việc khôi phục sẽ chiếm các liên kết đó. Chưa thay thế gì cả.';

  @override
  String get workspaceReadOnlyBannerTitle => 'Không gian làm việc này chỉ đọc';

  @override
  String get workspaceReadOnlyBannerBody =>
      'Dữ liệu của không gian làm việc này không vượt qua kiểm tra toàn vẹn, nên không thể lưu thay đổi. Mọi thứ vẫn có thể đọc được. Chủ sở hữu máy chủ có thể khôi phục từ bản sao lưu.';

  @override
  String get workspaceReadOnlyBannerOwnerBody =>
      'Dữ liệu của không gian làm việc này không vượt qua kiểm tra toàn vẹn, nên không thể lưu thay đổi. Mọi thứ vẫn có thể đọc được. Hãy khôi phục từ bản sao lưu để cho phép ghi lại.';

  @override
  String get workspaceReadOnlyBannerAction => 'Mở bản sao lưu';

  @override
  String get serverNoticesLabel => 'Cần bạn chú ý';

  @override
  String get serverNoticeReadOnlyStatus => 'Chỉ đọc';

  @override
  String serverNoticeSince(String time) {
    return 'Từ $time';
  }

  @override
  String get serverNoticeReadOnlyBody =>
      'Cơ sở dữ liệu của không gian làm việc không vượt qua kiểm tra toàn vẹn, nên nó chỉ cho phép đọc và từ chối mọi thay đổi. Hãy khôi phục từ bản sao lưu trong danh sách bên dưới; bản sao tốt gần nhất được giữ lại cho đến khi bạn làm vậy.';

  @override
  String get serverNoticeDetails => 'Chi tiết';

  @override
  String get backupSnapshotUnverified => 'Chưa xác minh';

  @override
  String get backupSnapshotUnverifiedNote =>
      'Ảnh chụp này không thể xác minh. Nó chưa hoàn tất, hoặc được chụp trước khi ảnh chụp ghi checksum, nên không thể khôi phục toàn bộ cài đặt. Các tệp không gian làm việc trong đó vẫn có thể khôi phục từng tệp một.';

  @override
  String get backupSnapshotLastGoodCopy => 'Bản sao tốt gần nhất';

  @override
  String get backupSnapshotLastGoodCopyNote =>
      'Được giữ lại vì nó chứa bản sao tốt gần nhất của một không gian làm việc bị hỏng. Dọn dẹp sẽ không xóa nó cho đến khi không gian làm việc đó được khôi phục.';

  @override
  String get backupDeleteLastGoodCopyDescription =>
      'Đây là bản sao tốt gần nhất của một không gian làm việc bị hỏng. Nếu xóa, sẽ không còn gì để khôi phục không gian làm việc đó.';

  @override
  String backupRestoreHeldBack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count quyền đã bị giữ lại để bạn xem xét. Các quyền này được liệt kê ở đầu trang.',
      one:
          '1 quyền đã bị giữ lại để bạn xem xét. Quyền này được liệt kê ở đầu trang.',
    );
    return '$_temp0';
  }

  @override
  String get importHoldsLabel => 'Bị giữ lại từ các bản sao đã khôi phục';

  @override
  String get importHoldsExplainer =>
      'Một bản sao đã khôi phục không thể tự cấp bất kỳ quyền nào trên máy chủ này. Các quyền sau có trong bản sao: chấp nhận một quyền để cấp lại, hoặc từ chối để xóa nó.';

  @override
  String importHoldPolicyAllow(String action) {
    return 'Agent có thể làm việc này mà không cần phê duyệt: $action';
  }

  @override
  String importHoldPolicyPrompt(String action) {
    return 'Agent có thể làm việc này khi một người phê duyệt: $action';
  }

  @override
  String importHoldCommand(String command) {
    return 'Chạy các lệnh bắt đầu bằng $command';
  }

  @override
  String get importHoldScopeWorkspace =>
      'Ở mọi nơi trong không gian làm việc này';

  @override
  String importHoldScopeSpace(String space) {
    return 'Trong space $space';
  }

  @override
  String importHoldScopeAgent(String agent) {
    return 'Cho agent $agent';
  }

  @override
  String importHoldSandboxExec(String path) {
    return 'Sandbox có thể chạy $path';
  }

  @override
  String importHoldRepoWrite(String person, String repo) {
    return '$person có thể thay đổi $repo';
  }

  @override
  String importHoldRepoReview(String person, String repo) {
    return '$person có thể xem xét pull request trong $repo';
  }

  @override
  String importHoldRepoOther(String person, String repo, String level) {
    return '$person được truy cập mức $level vào $repo';
  }

  @override
  String importHoldMemberRole(String person, String role) {
    return '$person nhận vai trò $role';
  }

  @override
  String importHoldInvite(String role) {
    return 'Một lời mời đang mở để tham gia với vai trò $role';
  }

  @override
  String importHoldInviteWithRepos(int count, String role) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Một lời mời đang mở để tham gia với vai trò $role và quyền xem xét hoặc ghi vào $count kho lưu trữ',
      one:
          'Một lời mời đang mở để tham gia với vai trò $role và quyền xem xét hoặc ghi vào 1 kho lưu trữ',
    );
    return '$_temp0';
  }

  @override
  String get importHoldUnknown =>
      'Một quyền mà phiên bản ứng dụng này không thể mô tả';

  @override
  String importHoldRestoredAt(String time) {
    return 'Đã khôi phục $time';
  }

  @override
  String get importHoldAccept => 'Chấp nhận';

  @override
  String get importHoldDismiss => 'Từ chối';

  @override
  String get importHoldAcceptTitle => 'Cấp quyền này?';

  @override
  String importHoldAcceptBody(String permission) {
    return '$permission\n\nChấp nhận sẽ cấp quyền này trên máy chủ ngay lập tức.';
  }

  @override
  String get importHoldAccepted => 'Đã cấp quyền.';

  @override
  String get importHoldNotApplied =>
      'Chưa cấp quyền nào: người hoặc thứ mà quyền này dành cho không còn trong không gian làm việc này.';

  @override
  String get mcpWorkspaceServers => 'Máy chủ MCP của không gian làm việc';

  @override
  String get mcpWorkspaceServersDescription =>
      'Mọi lượt chạy tác tử trong không gian làm việc này đều nhận công cụ từ các máy chủ này, trong Claude Code cũng như harness tích hợp sẵn. Control Center kết nối tới từng máy chủ và chuyển tiếp công cụ của máy chủ đó.';

  @override
  String get mcpWorkspaceServersAdminsOnly =>
      'Chỉ quản trị viên không gian làm việc mới xem và thay đổi được máy chủ MCP của không gian làm việc này.';

  @override
  String get mcpWorkspaceServersUnavailable =>
      'Máy chủ MCP của không gian làm việc không khả dụng trên máy chủ đang kết nối.';

  @override
  String get mcpWorkspaceServersEmpty =>
      'Chưa có máy chủ MCP nào của không gian làm việc';

  @override
  String get mcpWorkspaceServersEmptyDescription =>
      'Thêm máy chủ để mọi lượt chạy tác tử trong không gian làm việc này đều có công cụ của nó.';

  @override
  String get mcpAddServer => 'Thêm máy chủ';

  @override
  String get mcpStatusAwaitingApproval => 'Đang chờ phê duyệt';

  @override
  String get mcpPublicAddressesOnly => 'Chỉ địa chỉ công khai';

  @override
  String get mcpApproveServer => 'Phê duyệt';

  @override
  String get mcpApprovalStdioOwner =>
      'Máy chủ này chạy một lệnh trên máy chủ host, với tư cách người dùng của máy chủ. Máy chủ sẽ không khởi động cho đến khi bạn phê duyệt.';

  @override
  String get mcpApprovalStdioMember =>
      'Máy chủ này chạy một lệnh trên máy chủ host, nên sẽ không khởi động cho đến khi chủ sở hữu máy chủ phê duyệt.';

  @override
  String get mcpApprovalRemoteOwner =>
      'Máy chủ này chỉ có thể truy cập địa chỉ công khai. Hãy phê duyệt để cho phép máy chủ truy cập cả mạng riêng của host, chẳng hạn localhost và mạng cục bộ.';

  @override
  String get mcpApprovalRemoteMember =>
      'Máy chủ này chỉ có thể truy cập địa chỉ công khai cho đến khi chủ sở hữu máy chủ phê duyệt.';

  @override
  String get mcpServersSettingsSubtitle =>
      'Máy chủ MCP tích hợp sẵn, và các máy chủ MCP mà công cụ của chúng được các lượt chạy tác tử trong không gian làm việc này sử dụng.';

  @override
  String get mcpPersonalServers => 'Máy chủ MCP của bạn';

  @override
  String get mcpPersonalServersDescription =>
      'Chỉ bạn thấy các máy chủ này, và chỉ các lượt chạy tác tử bạn khởi chạy trong không gian làm việc này mới nhận công cụ của chúng.';

  @override
  String get mcpPersonalServersUnavailable =>
      'Máy chủ MCP riêng của bạn không khả dụng trên máy chủ đang kết nối.';

  @override
  String get mcpPersonalServersEmpty => 'Chưa có máy chủ MCP riêng nào';

  @override
  String get mcpPersonalServersEmptyDescription =>
      'Thêm máy chủ để các lượt chạy bạn khởi chạy trong không gian làm việc này có công cụ của nó.';

  @override
  String get mcpServerEditorPersonalOwner =>
      'Chỉ các lượt chạy bạn khởi chạy trong không gian làm việc này mới dùng máy chủ này. Với tư cách chủ sở hữu máy chủ, lưu sẽ phê duyệt nó.';

  @override
  String get mcpServerEditorPersonalMember =>
      'Chỉ các lượt chạy bạn khởi chạy trong không gian làm việc này mới dùng máy chủ này. Máy chủ chỉ truy cập được địa chỉ công khai.';

  @override
  String get mcpServerSignInNeeded =>
      'Đăng nhập để dùng công cụ của máy chủ này.';

  @override
  String get mcpServerSignIn => 'Đăng nhập';

  @override
  String mcpServerSignInTitle(String name) {
    return 'Đăng nhập vào $name';
  }

  @override
  String mcpServerSignInWrongCode(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Còn $count lần thử.',
    );
    return 'Mã đó không phải mã trình duyệt đã hiển thị. $_temp0';
  }

  @override
  String get mcpServerSignInEnded =>
      'Quá thời gian, bị từ chối, hoặc nhập sai mã quá nhiều lần. Bắt đầu lại để nhận trang đăng nhập mới.';

  @override
  String get mcpServerSignInStartAgain => 'Bắt đầu lại';

  @override
  String mcpServerSignedIn(String name) {
    return 'Đã đăng nhập vào $name.';
  }

  @override
  String get mcpRemoveServer => 'Xóa máy chủ';

  @override
  String mcpRemoveServerTitle(String name) {
    return 'Xóa $name?';
  }

  @override
  String get mcpRemoveServerBody =>
      'Các lượt chạy tác tử sẽ mất công cụ của máy chủ này, và các giá trị bí mật đã lưu sẽ bị xóa.';

  @override
  String mcpServerEnabledToggle(String name) {
    return 'Bật hoặc tắt $name';
  }

  @override
  String get mcpServerEditorAddTitle => 'Thêm máy chủ MCP';

  @override
  String mcpServerEditorEditTitle(String name) {
    return 'Sửa $name';
  }

  @override
  String get mcpServerNameHelper =>
      'Chữ cái, chữ số, dấu gạch ngang và dấu gạch dưới. Tác tử thấy công cụ của máy chủ dưới tên này.';

  @override
  String get mcpServerNameInvalid =>
      'Dùng tối đa 24 chữ cái, chữ số, dấu gạch ngang hoặc dấu gạch dưới, bắt đầu bằng chữ cái hoặc chữ số.';

  @override
  String get mcpServerNameTaken => 'Đã có máy chủ khác ở đây dùng tên này.';

  @override
  String get mcpServerTransportLabel => 'Giao thức';

  @override
  String get mcpServerTransportStdio => 'Lệnh';

  @override
  String get mcpServerTransportHttp => 'HTTP';

  @override
  String get mcpServerTransportSse => 'SSE';

  @override
  String get mcpServerCommandLabel => 'Lệnh';

  @override
  String get mcpServerCommandRequired => 'Nhập lệnh cần chạy.';

  @override
  String get mcpServerArgsLabel => 'Đối số';

  @override
  String get mcpServerArgsHelper => 'Mỗi đối số một dòng.';

  @override
  String get mcpServerUrlLabel => 'URL';

  @override
  String get mcpServerUrlInvalid =>
      'Nhập URL http hoặc https, không có tên người dùng, mật khẩu hoặc #fragment.';

  @override
  String get mcpServerEnvLabel => 'Biến môi trường';

  @override
  String get mcpServerHeadersLabel => 'Tiêu đề';

  @override
  String get mcpServerSecretsDescription =>
      'Giá trị được lưu như bí mật và sẽ không hiển thị lại.';

  @override
  String get mcpServerHeadersExample =>
      'Ví dụ: tiêu đề Authorization với bearer token.';

  @override
  String get mcpServerEnvAdd => 'Thêm biến';

  @override
  String get mcpServerHeaderAdd => 'Thêm tiêu đề';

  @override
  String get mcpServerSecretValueHint => 'Giá trị';

  @override
  String get mcpServerSecretNewValueHint => 'Giá trị mới';

  @override
  String get mcpServerSecretReplace => 'Thay giá trị';

  @override
  String get mcpServerSecretUndo => 'Hoàn tác';

  @override
  String get mcpServerSecretRemovedOnSave => 'Sẽ xóa khi lưu';

  @override
  String mcpServerEnvNameInvalid(String name) {
    return '$name không phải là tên biến hợp lệ. Dùng chữ cái, chữ số và dấu gạch dưới, không bắt đầu bằng chữ số.';
  }

  @override
  String mcpServerHeaderNameInvalid(String name) {
    return 'Không thể đặt $name. Dùng tên tiêu đề hợp lệ mà kết nối không tự quản lý.';
  }

  @override
  String get mcpServerTransportDropsValues =>
      'Đổi giao thức sẽ xóa các giá trị đã lưu.';

  @override
  String get mcpServerEnabledDescription =>
      'Khi tắt, máy chủ sẽ không khởi động và tác tử không thấy công cụ của máy chủ.';

  @override
  String get mcpServerEditorStdioMember =>
      'Máy chủ chạy trên host của máy chủ, nên sẽ không khởi động cho đến khi chủ sở hữu máy chủ phê duyệt. Thay đổi cách khởi động sẽ yêu cầu phê duyệt lại.';

  @override
  String get mcpServerEditorRemoteMember =>
      'Máy chủ chỉ truy cập được địa chỉ công khai cho đến khi chủ sở hữu máy chủ phê duyệt. Thay đổi cách kết nối sẽ yêu cầu phê duyệt lại.';

  @override
  String get mcpServerEditorStdioOwner =>
      'Máy chủ chạy trên host của máy chủ, với tư cách người dùng của máy chủ. Lưu sẽ phê duyệt máy chủ.';

  @override
  String get mcpServerEditorRemoteOwner =>
      'Lưu sẽ phê duyệt để máy chủ truy cập cả mạng riêng của host.';

  @override
  String get mcpServerRefusedInvalid =>
      'Control Center không thể lưu máy chủ này. Kiểm tra cài đặt và thử lại.';

  @override
  String get mcpServerNotFound =>
      'Máy chủ này không còn tồn tại. Có thể ai đó đã xóa nó.';

  @override
  String get scriptToolCalls => 'Lệnh gọi công cụ';

  @override
  String scriptCallCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lệnh gọi',
      one: '1 lệnh gọi',
    );
    return '$_temp0';
  }

  @override
  String scriptCallsRunning(int count) {
    return '$count đang chạy';
  }

  @override
  String scriptCallsOk(int count) {
    return '$count thành công';
  }

  @override
  String scriptCallsFailed(int count) {
    return '$count thất bại';
  }

  @override
  String scriptCallsDenied(int count) {
    return '$count bị từ chối';
  }

  @override
  String scriptCallsCancelled(int count) {
    return '$count đã hủy';
  }

  @override
  String scriptCallsQueued(int count) {
    return '$count đang chờ';
  }

  @override
  String scriptCallsSkipped(int count) {
    return '$count đã bỏ qua';
  }

  @override
  String get scriptStepQueued => 'Đang chờ';

  @override
  String get scriptStepSkipped => 'Đã bỏ qua';

  @override
  String get scriptGroupLoop => 'Vòng lặp';

  @override
  String get scriptGroupEach => 'Với mỗi';

  @override
  String get scriptGroupParallel => 'Song song';

  @override
  String get scriptGroupFunction => 'Hàm';

  @override
  String scriptCallsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hiện thêm $count lệnh gọi',
      one: 'Hiện thêm 1 lệnh gọi',
    );
    return '$_temp0';
  }

  @override
  String get scriptCallsUnplaced => 'Lệnh gọi không nằm trong tập lệnh';

  @override
  String get scriptToolComputed => 'Công cụ';

  @override
  String scriptStepSemantics(String subject, String state) {
    return '$subject, $state';
  }

  @override
  String get scriptSourceLabel => 'Tập lệnh';

  @override
  String scriptSourceLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dòng',
      one: '1 dòng',
    );
    return '$_temp0';
  }

  @override
  String get scriptStateRunning => 'Đang chạy';

  @override
  String get scriptStateCompleted => 'Hoàn tất';

  @override
  String get scriptStateFailed => 'Thất bại';

  @override
  String get scriptStateTimedOut => 'Hết thời gian';

  @override
  String get scriptStateCancelled => 'Đã hủy';

  @override
  String get scriptStateMemoryExceeded => 'Hết bộ nhớ';

  @override
  String get scriptStateOutputExceeded => 'Đầu ra quá lớn';

  @override
  String get scriptStateSandboxError => 'Lỗi sandbox';

  @override
  String get scriptStateRefused => 'Bị từ chối';

  @override
  String get transcriptToolDenied => 'Từ chối';

  @override
  String get transcriptStatusRunningScript => 'Đang chạy tập lệnh…';

  @override
  String get scriptOriginLine => 'Từ một tập lệnh mà agent đang chạy';

  @override
  String get scriptOriginShow => 'Hiện tập lệnh';

  @override
  String get codeModeTitle => 'Chế độ code';

  @override
  String get codeModeSubtitle =>
      'Agent có thể viết một tập lệnh ngắn gọi các công cụ của chúng thay vì gọi từng cái một.';

  @override
  String get codeModeStatusLabel => 'Trạng thái';

  @override
  String get codeModeFactAvailability => 'Trên máy chủ này';

  @override
  String get codeModeAvailable => 'Khả dụng';

  @override
  String get codeModeUnavailable => 'Không khả dụng';

  @override
  String get codeModeFactRunner => 'Trình chạy';

  @override
  String codeModeUnavailableNote(String reason) {
    return 'Máy chủ này không thể chạy tập lệnh, nên các agent ở đây gọi công cụ từng cái một. Máy chủ cho biết: $reason';
  }

  @override
  String get codeModeNoReason => 'không có lý do nào được đưa ra.';

  @override
  String get codeModeViewExecutions => 'Xem các lần thực thi code';

  @override
  String get codeModeLimitsLabel => 'Giới hạn';

  @override
  String get codeModeLimitsSubtitle =>
      'Một tập lệnh được chạy trong bao lâu và đi xa đến đâu. Mặc định phù hợp với hầu hết không gian làm việc.';

  @override
  String get codeModeLimitsDisclosure => 'Điều chỉnh giới hạn';

  @override
  String get codeModeLimitsAtDefaults => 'Mặc định';

  @override
  String codeModeLimitsChangedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count đã đổi',
      one: '1 đã đổi',
    );
    return '$_temp0';
  }

  @override
  String get codeModeLimitsUseDefaults => 'Dùng mặc định';

  @override
  String get codeModeLimitWallClock => 'Thời gian mỗi tập lệnh';

  @override
  String get codeModeLimitWallClockHelp =>
      'Thời gian chờ người dùng không được tính.';

  @override
  String get codeModeLimitCpu => 'Thời gian xử lý';

  @override
  String get codeModeLimitCpuHelp =>
      'Thời gian chính tập lệnh dùng để tính toán.';

  @override
  String get codeModeLimitHeap => 'Bộ nhớ';

  @override
  String get codeModeLimitHeapHelp =>
      'Bộ nhớ tập lệnh được dùng trong khi chạy.';

  @override
  String get codeModeLimitNestedCalls => 'Lệnh gọi công cụ mỗi tập lệnh';

  @override
  String get codeModeLimitNestedCallsHelp =>
      'Các lệnh gọi vượt mức này sẽ bị từ chối và tập lệnh được cho biết lý do.';

  @override
  String get codeModeLimitInFlight => 'Lệnh gọi đồng thời';

  @override
  String get codeModeLimitInFlightHelp =>
      'Số lệnh gọi mà một tập lệnh có thể chạy cùng lúc.';

  @override
  String get codeModeLimitOutputTokens => 'Đầu ra agent đọc';

  @override
  String get codeModeLimitOutputTokensHelp =>
      'Đầu ra dài sẽ được rút gọn; agent có thể đọc phần còn lại khi cần.';

  @override
  String codeModeLimitRange(String defaultValue, String min, String max) {
    return 'Mặc định $defaultValue. Từ $min đến $max.';
  }

  @override
  String codeModeLimitOutOfRange(String min, String max) {
    return 'Nhập một số nguyên từ $min đến $max.';
  }

  @override
  String get codeModeSuffixSeconds => 's';

  @override
  String get codeModeSuffixMebibytes => 'MiB';

  @override
  String get codeModeSuffixCalls => 'lệnh gọi';

  @override
  String get codeModeSuffixTokens => 'token';

  @override
  String codeModeServerCap(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Máy chủ này chạy tối đa $count tập lệnh cùng lúc, trên tất cả không gian làm việc.',
      one:
          'Máy chủ này chạy tối đa 1 tập lệnh cùng lúc, trên tất cả không gian làm việc.',
    );
    return '$_temp0';
  }

  @override
  String codeModeUnitMilliseconds(String value) {
    return '$value ms';
  }

  @override
  String codeModeUnitSeconds(String value) {
    return '$value s';
  }

  @override
  String codeModeUnitMinutesSeconds(String minutes, String seconds) {
    return '$minutes phút $seconds giây';
  }

  @override
  String get codeModeRefusedLimitUnknown =>
      'Máy chủ không biết một trong các giới hạn này.';

  @override
  String get codeModeRefusedLimitOutOfRange =>
      'Một trong các giới hạn này nằm ngoài mức máy chủ cho phép.';

  @override
  String get codeModeRefusedUnknownSetting =>
      'Máy chủ không nhận ra cài đặt đó.';

  @override
  String get codeExecutionsTitle => 'Thực thi code';

  @override
  String get codeExecutionsSubtitle =>
      'Các tập lệnh agent đã chạy trong không gian làm việc này, cùng mọi lệnh gọi công cụ chúng đã thực hiện.';

  @override
  String get codeExecutionsEmpty => 'Chưa có tập lệnh nào chạy ở đây.';

  @override
  String get codeExecutionsEmptyFiltered =>
      'Không có tập lệnh nào khớp với bộ lọc này.';

  @override
  String get codeExecutionsStatusFilter => 'Kết quả';

  @override
  String get codeExecutionsAllOutcomes => 'Tất cả kết quả';

  @override
  String codeExecutionsOutcomeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kết quả',
      one: '1 kết quả',
    );
    return '$_temp0';
  }

  @override
  String get codeExecutionsScopeRun => 'Tập lệnh từ một lần chạy';

  @override
  String get codeExecutionsScopeConversation =>
      'Tập lệnh từ một cuộc trò chuyện';

  @override
  String get codeExecutionsScopeAgent => 'Tập lệnh của một agent';

  @override
  String get codeExecutionsShowAll => 'Hiện tất cả';

  @override
  String get codeExecutionUntitled => 'Tập lệnh không có tên';

  @override
  String get codeExecutionRecord => 'Bản ghi';

  @override
  String get codeExecutionBackToList => 'Quay lại thực thi code';

  @override
  String get codeExecutionNotFound =>
      'Lần thực thi code này không có trong không gian làm việc này. Có thể nó đã bị xóa cùng với lần chạy.';

  @override
  String get codeExecutionRefusedSpace =>
      'Tập lệnh này chạy trong một space bạn không thể mở, nên bản ghi của nó vẫn bị ẩn.';

  @override
  String get codeExecutionOpenRecord => 'Mở bản ghi';

  @override
  String get codeExecutionFactStarted => 'Bắt đầu';

  @override
  String get codeExecutionFactDuration => 'Thời lượng';

  @override
  String get codeExecutionFactCalls => 'Lệnh gọi công cụ';

  @override
  String get codeExecutionFactAgent => 'Agent';

  @override
  String get codeExecutionFactSurface => 'Chạy qua';

  @override
  String get codeExecutionSurfaceHarness => 'Agent tích hợp';

  @override
  String get codeExecutionSurfaceMcp => 'Agent bên ngoài';

  @override
  String get codeExecutionFactCpu => 'Thời gian xử lý';

  @override
  String get codeExecutionFactMemory => 'Bộ nhớ cao nhất';

  @override
  String get codeExecutionOpenConversation => 'Mở cuộc trò chuyện';

  @override
  String get codeExecutionRunScripts => 'Tập lệnh trong lần chạy này';

  @override
  String get codeExecutionAgentScripts => 'Tập lệnh của agent này';

  @override
  String get codeExecutionScript => 'Tập lệnh';

  @override
  String get codeExecutionConsole => 'Console';

  @override
  String get codeExecutionOutputTruncated =>
      'Đầu ra đã được cắt để vừa với phần được giữ lại.';

  @override
  String get codeExecutionNoPayload =>
      'Tập lệnh và đầu ra của nó không còn được lưu nữa.';

  @override
  String codeExecutionCallsHeading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lệnh gọi công cụ',
      one: '1 lệnh gọi công cụ',
      zero: 'Lệnh gọi công cụ',
    );
    return '$_temp0';
  }

  @override
  String get codeExecutionNoCalls => 'Tập lệnh không gọi công cụ nào.';

  @override
  String get codeExecutionCallCompleted => 'Hoàn tất';

  @override
  String get codeExecutionCallFailed => 'Thất bại';

  @override
  String get codeExecutionCallDenied => 'Từ chối';

  @override
  String get codeExecutionCallCancelled => 'Đã hủy';

  @override
  String get codeExecutionCallTimedOut => 'Hết thời gian';

  @override
  String get codeExecutionCallUnknownTool => 'Công cụ không xác định';

  @override
  String get codeExecutionCallInvalidArgs => 'Đối số không hợp lệ';

  @override
  String get codeExecutionGateAllowed => 'Cho phép';

  @override
  String get codeExecutionGateApproved => 'Người dùng đã duyệt';

  @override
  String get codeExecutionGateDenied => 'Từ chối';

  @override
  String get codeExecutionGateNotReached => 'Chưa kiểm tra';

  @override
  String codeExecutionCallWaited(String duration) {
    return 'Chờ $duration để người dùng duyệt';
  }

  @override
  String get codeExecutionCallArguments => 'Đối số';

  @override
  String get codeExecutionCallResult => 'Kết quả';

  @override
  String codeExecutionCallResultSize(String size) {
    return 'Trả về $size';
  }

  @override
  String codeExecutionBytes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count byte',
      one: '1 byte',
    );
    return '$_temp0';
  }

  @override
  String get codeExecutionEndedScriptError =>
      'Tập lệnh đã báo lỗi và không có gì bắt lỗi đó.';

  @override
  String codeExecutionEndedScriptErrorNamed(String name) {
    return 'Tập lệnh đã báo $name và không có gì bắt lỗi đó.';
  }

  @override
  String get codeExecutionEndedStalled =>
      'Tập lệnh đang chờ một việc không bao giờ hoàn thành.';

  @override
  String get codeExecutionEndedCpu => 'Tập lệnh đã dùng hết thời gian xử lý.';

  @override
  String get codeExecutionEndedHeap => 'Tập lệnh đã đạt giới hạn bộ nhớ.';

  @override
  String get codeExecutionEndedOutput =>
      'Tập lệnh đã ghi nhiều đầu ra hơn mức cho phép.';

  @override
  String get codeExecutionEndedDeadline => 'Tập lệnh đã hết thời gian.';

  @override
  String get codeExecutionEndedCancelled =>
      'Tập lệnh đã bị hủy trước khi hoàn tất.';

  @override
  String get codeExecutionEndedShutdown =>
      'Máy chủ đã tắt trong khi tập lệnh đang chạy.';

  @override
  String get codeExecutionEndedServerStopped =>
      'Máy chủ đã dừng trong khi tập lệnh đang chạy. Bản ghi được đóng khi máy chủ khởi động lại.';

  @override
  String get codeExecutionEndedInternal =>
      'Chương trình chạy tập lệnh đã tự gặp lỗi.';

  @override
  String get codeExecutionEndedStart =>
      'Chương trình chạy tập lệnh không thể khởi động.';

  @override
  String get codeExecutionEndedLockdown =>
      'Chương trình chạy tập lệnh không thể tự giới hạn quyền, nên tập lệnh không được chạy.';

  @override
  String get codeExecutionEndedExited =>
      'Chương trình chạy tập lệnh đã dừng trước khi tập lệnh hoàn tất.';

  @override
  String get codeExecutionEndedRunnerBrokeRules =>
      'Chương trình chạy tập lệnh đã vi phạm quy tắc hoạt động và bị dừng.';

  @override
  String get codeExecutionEndedUnresponsive =>
      'Chương trình chạy tập lệnh không phản hồi và đã bị dừng.';

  @override
  String get codeExecutionEndedHostError =>
      'Máy chủ gặp lỗi khi chạy tập lệnh.';

  @override
  String get codeExecutionRunningNote =>
      'Đang chạy. Các lệnh gọi công cụ sẽ hiện ở đây khi hoàn tất, và kết quả khi kết thúc.';

  @override
  String codeModeServerWorkspaceShare(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Tập lệnh của một không gian làm việc dùng tối đa $count trong số đó.',
      one: 'Tập lệnh của một không gian làm việc dùng tối đa 1 trong số đó.',
    );
    return '$_temp0';
  }

  @override
  String get wakeOriginGoal => 'Mục tiêu';

  @override
  String get wakeOriginGoalCheck => 'Kiểm chứng mục tiêu';

  @override
  String get wakeOriginGoalReview => 'Đánh giá mục tiêu';

  @override
  String get wakeOriginSchedule => 'Lịch';

  @override
  String get wakeOriginWatch => 'Theo dõi';

  @override
  String wakeOriginReplyFrom(String agent) {
    return 'Phản hồi từ $agent';
  }

  @override
  String get wakeOriginReply => 'Phản hồi';

  @override
  String wakeOriginMessageFrom(String agent) {
    return 'Tin nhắn từ $agent';
  }

  @override
  String get wakeOriginMessage => 'Tin nhắn';

  @override
  String wakeOriginWorkFinishedBy(String agent) {
    return 'Công việc đã xong từ $agent';
  }

  @override
  String get wakeOriginWorkFinished => 'Công việc đã xong';

  @override
  String get wakeOriginLimitReset => 'Đặt lại giới hạn';

  @override
  String get wakeOriginRecovery => 'Khôi phục';

  @override
  String get wakeOriginAssignment => 'Được giao việc';

  @override
  String get wakeOriginPipelineStep => 'Bước quy trình';

  @override
  String get wakeOriginImprovementReview => 'Đánh giá cải tiến';

  @override
  String get wakeKindStopped => 'Bị giữ vì một người đã dừng lần chạy.';

  @override
  String get wakeKindAttempts => 'Gửi không thành công ba lần.';

  @override
  String get wakeKindAgentDeleted => 'Agent không còn tồn tại.';

  @override
  String get wakeKindAgentNotDispatchable => 'Agent đã ngừng hoạt động.';

  @override
  String get wakeKindAgentPaused => 'Agent đang tạm dừng.';

  @override
  String get wakeKindPersonRemoved =>
      'Người mà nó hoạt động thay mặt đã rời không gian làm việc.';

  @override
  String get wakeKindBudgetBlocked => 'Ngân sách đang chặn lần chạy.';

  @override
  String get wakeKindTakeOver => 'Một người đã tiếp quản cây làm việc.';

  @override
  String get wakeKindRateCapConversation =>
      'Cuộc trò chuyện này đã bắt đầu 30 lần chạy từ lượt đánh thức trong giờ qua.';

  @override
  String get wakeKindRateCapWorkspace =>
      'Không gian làm việc này đã bắt đầu 300 lần chạy từ lượt đánh thức trong giờ qua.';

  @override
  String get wakeKindLiveRunNoInput =>
      'Lần chạy trực tiếp của agent ở đây không nhận đầu vào.';

  @override
  String get wakeKindLiveRunOtherOptions =>
      'Lần chạy trực tiếp của agent ở đây chạy theo cách khác, nên lượt này sẽ bắt đầu lần chạy riêng sau nó.';

  @override
  String get wakeKindLiveRunOtherPerson =>
      'Lần chạy trực tiếp của agent ở đây hoạt động thay cho người khác, nên lượt này sẽ bắt đầu lần chạy riêng sau nó.';

  @override
  String get wakeKindDispatchRefused => 'Lần chạy không thể bắt đầu.';

  @override
  String get wakeKindSandboxUnavailable =>
      'Không có sandbox cho lần chạy chỉ đọc.';

  @override
  String get wakeKindReadOnlyUnavailable =>
      'Backend của agent này không thể giữ lần chạy ở chế độ chỉ đọc.';

  @override
  String get wakeKindServerStopped => 'Máy chủ khởi động lại đã dừng lần chạy.';

  @override
  String get wakeKindServerRestarted =>
      'Máy chủ đã khởi động lại trong lần chạy của một người.';

  @override
  String get wakeKindGuardFailed =>
      'Một bước kiểm tra trước khi gửi đã thất bại.';

  @override
  String get wakeKindLimit => 'Đang chờ tại giới hạn sử dụng của nhà cung cấp.';

  @override
  String get wakeKindLimitRunLive =>
      'Đang chờ lần chạy ở giới hạn sử dụng kết thúc.';

  @override
  String get wakeKindWakeMissed => 'Bị bỏ lỡ khi máy chủ đang tắt.';

  @override
  String get wakeKindPipelineRunEnded =>
      'Lần chạy quy trình của nó đã kết thúc.';

  @override
  String get wakeKindGoalEnded => 'Mục tiêu của nó đã kết thúc.';

  @override
  String get wakeKindGoalBudgetExhausted =>
      'Mục tiêu của nó đã dùng hết ngân sách.';

  @override
  String get wakeKindGoalReviewStale =>
      'Mục tiêu đã thay đổi kể từ khi yêu cầu đánh giá này được gửi.';

  @override
  String get wakeKindGoalPaused => 'Mục tiêu của nó đang tạm dừng.';

  @override
  String get wakeKindGoalHeld => 'Mục tiêu của nó đang được giữ.';

  @override
  String get wakeKindGoalStopped => 'Mục tiêu của nó đã bị dừng.';

  @override
  String get wakeKindAskSettled => 'Câu hỏi mà nó trả lời đã được giải quyết.';

  @override
  String get wakeKindRuleEnded => 'Lịch của nó đã kết thúc.';

  @override
  String get wakeKindUnknown => 'Vì một lý do mà phiên bản này không nhận ra:';

  @override
  String wakeStripHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lượt đánh thức đang chờ',
      one: '1 lượt đánh thức đang chờ',
    );
    return '$_temp0';
  }

  @override
  String wakeStripDue(String time) {
    return 'Đến hạn lúc $time';
  }

  @override
  String get wakeStripDueNow => 'Đến hạn ngay';

  @override
  String get wakeStripHeld => 'Đang giữ';

  @override
  String wakeStripExpires(String time) {
    return 'Hết hạn lúc $time';
  }

  @override
  String wakeStripAttempt(int attempt) {
    return 'Lần thử $attempt';
  }

  @override
  String get wakeStripCancel => 'Hủy lượt đánh thức';

  @override
  String get wakeStripDeliverNow => 'Gửi ngay';

  @override
  String get wakeStripResume => 'Tiếp tục';

  @override
  String get wakeStripDismiss => 'Bỏ qua';

  @override
  String get wakeStripResumeAll => 'Tiếp tục tất cả';

  @override
  String get wakeStripResumeOnlyTheirs =>
      'Chỉ người có lần chạy này mới có thể tiếp tục.';

  @override
  String get wakeReceiptStarted => 'Đã bắt đầu một lần chạy.';

  @override
  String get wakeReceiptPushed => 'Đã chuyển cho lần chạy trực tiếp.';

  @override
  String wakeReceiptWaiting(String reason) {
    return 'Vẫn đang chờ. $reason';
  }

  @override
  String wakeReceiptSkipped(String reason) {
    return 'Chưa được gửi. $reason';
  }

  @override
  String get wakeReceiptDuplicate => 'Đã được gửi trước đó.';

  @override
  String wakeReleased(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã tiếp tục $count lượt đánh thức.',
      one: 'Đã tiếp tục 1 lượt đánh thức.',
      zero: 'Không có gì được tiếp tục.',
    );
    return '$_temp0';
  }

  @override
  String get wakeRefusalNotYours =>
      'Lượt đánh thức này hoạt động thay cho người khác. Chỉ họ mới có thể gửi hoặc tiếp tục nó.';

  @override
  String get wakeRefusalSettled => 'Lượt đánh thức này đã được xử lý xong.';

  @override
  String heldSteeringHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tin nhắn đang giữ',
      one: '1 tin nhắn đang giữ',
    );
    return '$_temp0';
  }

  @override
  String get heldSteeringResume => 'Gửi các tin nhắn đang giữ';

  @override
  String get heldSteeringDelete => 'Xóa tin nhắn đang giữ';

  @override
  String heldSteeringReleased(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã gửi $count tin nhắn đang giữ.',
      one: 'Đã gửi 1 tin nhắn đang giữ.',
      zero: 'Không có tin nhắn nào được giữ.',
    );
    return '$_temp0';
  }

  @override
  String get workAgentUnknown => 'một agent';

  @override
  String workFeedWoke(int count, String agent) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã đánh thức $agent để xử lý $count mục đang chờ',
      one: 'Đã đánh thức $agent',
    );
    return '$_temp0';
  }

  @override
  String workFeedWakeSkipped(String agent) {
    return 'Lượt đánh thức cho $agent chưa được gửi.';
  }

  @override
  String workFeedWakeMissed(String agent) {
    return 'Lượt đánh thức cho $agent đã bị bỏ lỡ khi máy chủ đang tắt.';
  }

  @override
  String workFeedScheduleCreated(String agent) {
    return 'Đã đặt lịch cho $agent.';
  }

  @override
  String workFeedScheduleEnded(String agent) {
    return 'Lịch của $agent đã kết thúc.';
  }

  @override
  String get workFeedOpenSchedule => 'Mở lịch';

  @override
  String workFeedNoteFromAgent(String agent) {
    return '$agent đã để lại ghi chú này cho chính mình, bằng lời của nó:';
  }

  @override
  String get workFeedNoteFromPerson => 'Lời nhắc do một người đặt:';

  @override
  String workFeedLimitParkHeld(String provider, String time) {
    return 'Tạm dừng ở giới hạn sử dụng của $provider. Giới hạn sẽ được đặt lại lúc $time.';
  }

  @override
  String workFeedLimitParkPending(String provider, String time) {
    return 'Tạm dừng ở giới hạn sử dụng của $provider. Sẽ tiếp tục lúc $time.';
  }

  @override
  String workFeedLimitParkResumed(String provider) {
    return 'Đã tiếp tục sau giới hạn sử dụng của $provider.';
  }

  @override
  String workFeedLimitParkGone(String provider) {
    return 'Không còn chờ ở giới hạn sử dụng của $provider.';
  }

  @override
  String get workFeedLimitParkResume => 'Tiếp tục';

  @override
  String get workFeedLimitParkCancel => 'Hủy';

  @override
  String workFeedStillInFlight(String agent) {
    return 'Trạng thái được giao cho $agent sau khi nén';
  }

  @override
  String get workFeedShowDetails => 'Hiện chi tiết';

  @override
  String get workFeedHideDetails => 'Ẩn chi tiết';

  @override
  String get workFeedCommandRefused => 'Máy chủ đã từ chối lệnh.';

  @override
  String get wakeRuleEndFired => 'Lịch đã chạy một lần.';

  @override
  String get wakeRuleEndExpired => 'Lịch đã đến ngày kết thúc.';

  @override
  String get wakeRuleEndRunCap => 'Lịch đã dùng hết số lần chạy.';

  @override
  String get wakeRuleEndCostCap => 'Lịch đã đạt mức chi phí tối đa.';

  @override
  String get wakeRuleEndGoalEnded => 'Mục tiêu của nó đã kết thúc.';

  @override
  String get wakeRuleEndCancelled => 'Lịch đã bị hủy.';

  @override
  String get wakeRuleEndMemberRemoved =>
      'Người phụ trách lịch đã rời không gian làm việc.';

  @override
  String get wakeRuleEndInvalidRow => 'Các thiết lập đã lưu không đọc được.';

  @override
  String get wakeRuleRefusalIntervalTooShort =>
      'Khoảng cách quá ngắn. Hãy chọn khoảng dài hơn.';

  @override
  String get wakeRuleRefusalTooSoon =>
      'Thời điểm đó quá sớm. Hãy chọn thời điểm sau.';

  @override
  String get wakeRuleRefusalLineageEnded =>
      'Chuỗi lượt đánh thức này đã dùng hết số lần chạy hoặc thời gian.';

  @override
  String get wakeRuleRefusalWatchTargetUnreadable =>
      'Bạn không thể đọc những gì mục này sẽ theo dõi.';

  @override
  String get wakeRuleRefusalExpiryRequired =>
      'Hãy đặt thời hạn kết thúc, ví dụ --days 3.';

  @override
  String get wakeRuleRefusalLimitReached =>
      'Cuộc trò chuyện này đã có đủ số lịch tối đa.';

  @override
  String get wakeRuleRefusalInvalidWhen => 'Không đọc được thời điểm.';

  @override
  String get wakeRuleRefusalNoteTooLong => 'Ghi chú quá dài.';

  @override
  String get wakeRuleRefusalExpiryTooLong => 'Thời hạn kết thúc quá xa.';

  @override
  String get wakeRuleRefusalLimitOutOfRange =>
      'Giới hạn số lần chạy, số ngày hoặc ngân sách nằm ngoài phạm vi cho phép.';

  @override
  String get wakeRuleRefusalNextOutsideLoop =>
      'Chỉ vòng lặp mới có thể tự chọn thời điểm tiếp theo.';

  @override
  String get wakeRuleRefusalWatchRefused => 'Không thể theo dõi mục này.';

  @override
  String get wakeRuleRefusalRuleEnded => 'Lịch này đã kết thúc.';

  @override
  String get wakeRuleRefusalNotYours => 'Lịch này thuộc về người khác.';

  @override
  String get workRefusalUnknown => 'Máy chủ đã từ chối yêu cầu này:';

  @override
  String get goalRefusalAlreadyActive =>
      'Cuộc trò chuyện này đã có một mục tiêu đang hoạt động.';

  @override
  String get goalRefusalNotInReview => 'Mục tiêu này không đang chờ đánh giá.';

  @override
  String get goalRefusalEvidenceIncomplete =>
      'Bằng chứng của mục tiêu chưa đầy đủ.';

  @override
  String get goalRefusalClaimPending =>
      'Yêu cầu cho rằng mục tiêu đã xong vẫn đang được kiểm tra.';

  @override
  String get goalRefusalNotActiveSegment =>
      'Mục tiêu này không có phân đoạn nào đang chạy.';

  @override
  String get goalRefusalNotYours =>
      'Chỉ người đã bắt đầu mục tiêu này mới có thể làm việc đó.';

  @override
  String get goalRefusalNotPaused => 'Hãy tạm dừng mục tiêu trước.';

  @override
  String get goalRefusalContractInvalid =>
      'Không đọc được hợp đồng của mục tiêu.';

  @override
  String get goalRefusalCheckerUnknown => 'Không có agent nào có tên đó.';

  @override
  String get goalRefusalCheckerAmbiguous =>
      'Có nhiều agent cùng tên đó. Hãy dùng id của agent.';

  @override
  String get goalRefusalCheckerIsGoalAgent =>
      'Bộ kiểm tra phải là một agent khác với agent đang thực hiện công việc.';

  @override
  String get goalRefusalCommandInvalid => 'Lệnh /goal này không đọc được.';

  @override
  String goalCardWorking(int segment) {
    return 'Đang chạy · phân đoạn $segment';
  }

  @override
  String get goalCardWaiting => 'Đang chờ lượt đánh thức tiếp theo';

  @override
  String get goalCardVerifying => 'Đang kiểm tra xem đã xong chưa';

  @override
  String goalCardLimitUntil(String time) {
    return 'Tạm dừng ở giới hạn sử dụng · tiếp tục lúc $time';
  }

  @override
  String get goalCardLimit => 'Tạm dừng ở giới hạn sử dụng';

  @override
  String get goalCardPerson => 'Cần một người';

  @override
  String get goalCardByPerson => 'Một người đã tạm dừng';

  @override
  String get goalCardNeedsReview =>
      'Đang chờ đánh giá: mục tiêu nói đã xong, nhưng chưa có gì xác nhận';

  @override
  String goalCardSegments(int run, int max) {
    return 'Phân đoạn $run trên $max';
  }

  @override
  String goalCardSegmentsNoCap(int run) {
    return 'Phân đoạn $run';
  }

  @override
  String goalCardMoney(String spent, String cap) {
    return '$spent trên $cap';
  }

  @override
  String goalCardTimeLeft(String time) {
    return 'Còn $time';
  }

  @override
  String get goalCardOverdue => 'Đã quá hạn';

  @override
  String get goalCardDoneMeans => 'Hoàn thành khi';

  @override
  String get goalCardChecks => 'Kiểm chứng';

  @override
  String get goalCardCheckPassed => 'Đạt';

  @override
  String goalCardCheckFailed(int code) {
    return 'Thất bại · mã thoát $code';
  }

  @override
  String get goalCardCheckTimedOut => 'Hết thời gian';

  @override
  String get goalCardCheckNotRerun => 'Không chạy lại: không có gì thay đổi';

  @override
  String get goalCardCheckBroken => 'Không thể chạy';

  @override
  String get goalCardCheckNotRun => 'Chưa chạy';

  @override
  String get goalCardCriterionMet => 'Đạt';

  @override
  String get goalCardCriterionUnmet => 'Chưa đạt';

  @override
  String get goalCardCriterionCannotTell => 'Chưa rõ';

  @override
  String get goalCardVerdictPass => 'Lần kiểm tra gần nhất: đã xong';

  @override
  String get goalCardVerdictFail => 'Lần kiểm tra gần nhất: chưa xong';

  @override
  String get goalCardVerdictCannotVerify => 'Lần kiểm tra gần nhất: chưa rõ';

  @override
  String get goalCardConcerns => 'Lo ngại';

  @override
  String goalCardVerifiedBy(String agent) {
    return 'Được xác minh bởi $agent';
  }

  @override
  String get goalCardVerifiedBySelf =>
      'Tự xác minh (không có bộ kiểm tra riêng)';

  @override
  String get goalCardClosedByPerson =>
      'Một người đã đóng mà không có kiểm chứng đạt';

  @override
  String get goalCardNoMachineCheck => 'Không có kiểm chứng tự động';

  @override
  String get goalCardAddCheck => 'Thêm kiểm chứng';

  @override
  String get goalCardOpen => 'Mở mục tiêu';

  @override
  String get goalCardApprove => 'Phê duyệt hoàn thành';

  @override
  String get goalCardApproveTitle => 'Đóng mục tiêu này là đã xong?';

  @override
  String get goalCardApproveBody =>
      'Chưa có kiểm chứng nào xác nhận. Bạn đóng theo lời mình, và mục tiêu sẽ ghi nhận rằng một người đã đóng mà chưa xác minh.';

  @override
  String get goalCardApproveConfirm => 'Đóng là đã xong';

  @override
  String get goalCardResumeNotYours =>
      'Tiếp tục mục tiêu hoặc tăng ngân sách thuộc về người đã bắt đầu nó.';

  @override
  String get goalHoldDetailStalled =>
      'Không có tiến triển trong các phân đoạn gần nhất.';

  @override
  String get goalHoldDetailStalledWaiting =>
      'Đang chờ, sau các phân đoạn không có tiến triển.';

  @override
  String get goalHoldDetailVerificationFailed =>
      'Lần kiểm chứng gần nhất đã thất bại.';

  @override
  String get goalHoldDetailCannotVerify =>
      'Bộ kiểm tra không rõ mục tiêu đã xong hay chưa.';

  @override
  String get goalHoldDetailSandboxUnavailable =>
      'Không có sandbox để chạy các kiểm chứng.';

  @override
  String get goalHoldDetailCheckerUnavailable =>
      'Agent kiểm tra không khả dụng. Hãy chọn bộ kiểm tra khác, rồi tiếp tục.';

  @override
  String get goalHoldDetailCheckBroken => 'Kiểm chứng này không thể chạy:';

  @override
  String get goalHoldDetailWakeSkipped =>
      'Lượt đánh thức của nó chưa được gửi.';

  @override
  String get goalHoldDetailClaimPending =>
      'Yêu cầu rằng nó đã xong đang chờ kiểm chứng.';

  @override
  String get goalHoldDetailUnanswered =>
      'Một câu hỏi hoặc yêu cầu phê duyệt gửi cho người đã không được trả lời.';

  @override
  String get goalHoldDetailLimitParks =>
      'Nó đã chạm giới hạn sử dụng quá thường xuyên. Hãy xem lại, rồi tiếp tục.';

  @override
  String get goalHoldDetailInput =>
      'Đang chờ câu trả lời trong cuộc trò chuyện.';

  @override
  String get peerAsksSection => 'Yêu cầu';

  @override
  String peerAskTo(String agent) {
    return 'Gửi tới $agent';
  }

  @override
  String get peerAskKindAsk => 'Câu hỏi';

  @override
  String get peerAskKindConsult => 'Tham vấn';

  @override
  String get peerAskKindReview => 'Đánh giá';

  @override
  String get peerAskStatusPending => 'Đang chờ';

  @override
  String get peerAskStatusAnswered => 'Đã trả lời';

  @override
  String get peerAskStatusFailed => 'Thất bại';

  @override
  String get peerAskStatusExpired => 'Đã hết hạn';

  @override
  String get peerAskStatusCancelled => 'Đã hủy';

  @override
  String peerAskAsked(String time) {
    return 'Đã hỏi lúc $time';
  }

  @override
  String peerAskExpires(String time) {
    return 'Hết hạn lúc $time';
  }

  @override
  String get peerAskPromised => 'Đã hứa sẽ trả lời';

  @override
  String get peerAskBackground => 'Chạy nền';

  @override
  String get peerAskCancel => 'Hủy yêu cầu';

  @override
  String get peerAskAlreadySettled => 'Yêu cầu này đã được xử lý xong.';

  @override
  String get slashHintGoal =>
      'Làm việc hướng tới mục tiêu cho đến khi xong. Cờ: --check, --checker, --fresh, --unattended';

  @override
  String get slashHintLoop =>
      'Lặp lại một tác vụ, theo khoảng thời gian hoặc theo nhịp của agent';

  @override
  String get slashHintSchedule =>
      'Chạy tác vụ sau: sau 2h, lúc 09:00 hoặc theo cron';

  @override
  String get slashHintRefine =>
      'Xem lại công việc của cuộc trò chuyện này và đề xuất cải tiến';

  @override
  String get notifGoalCompleted => 'Mục tiêu đã xong';

  @override
  String get notifGoalFailed => 'Mục tiêu thất bại';

  @override
  String get notifGoalCancelled => 'Mục tiêu đã hủy';

  @override
  String get notifGoalBudgetExhausted => 'Mục tiêu đã dùng hết ngân sách';

  @override
  String get notifGoalNeedsReview => 'Một mục tiêu đang chờ bạn đánh giá';

  @override
  String get notifGoalNeedsPerson => 'Một mục tiêu cần bạn';

  @override
  String get notifGoalOnHold => 'Một mục tiêu đang được giữ';

  @override
  String get notifWakeRuleEnded => 'Một lịch đã kết thúc';

  @override
  String notifWaitingDigest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count việc đang chờ bạn',
      one: '1 việc đang chờ bạn',
    );
    return '$_temp0';
  }

  @override
  String notifImprovementProposed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Có $count cải tiến được đề xuất',
      one: 'Có một cải tiến được đề xuất',
    );
    return '$_temp0';
  }

  @override
  String get notifPipelineRunHeld =>
      'Một lần chạy quy trình đang bị giữ ở mức ngân sách của nó';

  @override
  String notifPipelineRunHeldBody(String spent, String cap) {
    return 'Đã chi $spent trên $cap';
  }

  @override
  String get inboxGoalNeedsReview => 'Mục tiêu đang chờ đánh giá';

  @override
  String get inboxGoalNeedsPerson => 'Mục tiêu cần bạn';

  @override
  String get inboxImprovementProposed => 'Đã đề xuất cải tiến';

  @override
  String get improvementRefusalAlreadyDecided =>
      'Ai đó đã quyết định về đề xuất này.';

  @override
  String get improvementRefusalCampaignRequired =>
      'Thay đổi này chưa qua đánh giá với skill hiện tại, hoặc skill đã thay đổi sau khi được đo. Hãy chạy lại đánh giá.';

  @override
  String get improvementRefusalChangedSince =>
      'Mục tiêu đã thay đổi kể từ khi đề xuất này được đưa ra. Hãy từ chối và để agent đề xuất lại.';

  @override
  String get improvementRefusalTargetMissing =>
      'Nội dung mà đề xuất này thay đổi không còn tồn tại.';

  @override
  String get improvementRefusalCampaignState =>
      'Đợt đánh giá không thể bắt đầu hoặc kết thúc ở trạng thái hiện tại.';

  @override
  String get improvementRefusalReviewCooldown =>
      'Cuộc trò chuyện này vừa được đánh giá. Hãy thử lại sau.';

  @override
  String get improvementRefusalAdminRequired =>
      'Chỉ quản trị viên không gian làm việc mới có thể quyết định về đề xuất này.';

  @override
  String get improvementKindMemoryFact => 'Dữ kiện bộ nhớ';

  @override
  String get improvementKindPolicy => 'Chính sách';

  @override
  String get improvementKindAgentNote => 'Ghi chú agent';

  @override
  String get improvementKindSkillEdit => 'Thay đổi skill';

  @override
  String get improvementKindSkillNew => 'Skill mới';

  @override
  String get improvementScopeAgent => 'Agent này';

  @override
  String get improvementScopeRepository => 'Kho lưu trữ này';

  @override
  String get improvementScopeWorkspace => 'Toàn bộ không gian làm việc';

  @override
  String get improvementStatusProposed => 'Đã đề xuất';

  @override
  String get improvementStatusAccepted => 'Đã chấp nhận';

  @override
  String get improvementStatusRejected => 'Đã từ chối';

  @override
  String get improvementStatusRolledBack => 'Đã hoàn tác';

  @override
  String get improvementStatusExpired => 'Đã hết hạn';

  @override
  String get improvementOperationAdd => 'Thêm';

  @override
  String get improvementOperationReplace => 'Thay thế';

  @override
  String get improvementOperationRemove => 'Xóa';

  @override
  String scheduleTriggerOnce(String time) {
    return 'Một lần, $time';
  }

  @override
  String scheduleTriggerEvery(String interval) {
    return 'Mỗi $interval';
  }

  @override
  String scheduleTriggerCron(String cron, String zone) {
    return 'Theo lịch $cron ($zone)';
  }

  @override
  String get scheduleTriggerSelfPaced =>
      'Khi agent chọn, cách nhau 1 đến 60 phút';

  @override
  String get scheduleTriggerPrChecks =>
      'Khi các kiểm tra của pull request hoàn tất';

  @override
  String scheduleTriggerPrChecksOf(String pr) {
    return 'Khi các kiểm tra của $pr hoàn tất';
  }

  @override
  String get scheduleTriggerPrReview =>
      'Khi pull request nhận được đánh giá hoặc phản hồi';

  @override
  String scheduleTriggerPrReviewOf(String pr) {
    return 'Khi $pr nhận được đánh giá hoặc phản hồi';
  }

  @override
  String get scheduleTriggerPrMerged => 'Khi pull request được merge';

  @override
  String scheduleTriggerPrMergedOf(String pr) {
    return 'Khi $pr được merge';
  }

  @override
  String get scheduleTriggerEnvironment =>
      'Khi một tác vụ của môi trường kết thúc hoặc môi trường sẵn sàng';

  @override
  String scheduleTriggerTicket(String id) {
    return 'Khi phiếu $id được xử lý xong';
  }

  @override
  String scheduleTriggerPipelineRun(String id) {
    return 'Khi lần chạy quy trình $id kết thúc';
  }

  @override
  String get goalNextWaiting =>
      'Mục tiêu sẽ tiếp tục khi điều nó đang chờ xuất hiện.';

  @override
  String get goalNextVerifying =>
      'Khi các kiểm chứng và đánh giá xong, mục tiêu sẽ hoàn thành hoặc tiếp tục làm việc.';

  @override
  String get goalNextLimit =>
      'Mục tiêu sẽ tiếp tục khi giới hạn sử dụng được đặt lại.';

  @override
  String get goalNextPerson =>
      'Mục tiêu sẽ tiếp tục khi có người trả lời câu hỏi hoặc yêu cầu phê duyệt của nó.';

  @override
  String get goalNextByPerson =>
      'Mục tiêu sẽ tạm dừng cho đến khi có người tiếp tục nó.';

  @override
  String get goalNextNeedsReview =>
      'Phê duyệt là đã xong, hoặc tiếp tục để mục tiêu làm việc tiếp.';

  @override
  String get goalNextWorking =>
      'Mục tiêu sẽ tiếp tục làm việc, mỗi lần một phân đoạn, cho đến khi xong hoặc chạm giới hạn.';

  @override
  String get goalContractAddCheck => 'Thêm kiểm chứng';

  @override
  String goalContractChecksFull(int max) {
    return 'Một mục tiêu có tối đa $max kiểm chứng.';
  }

  @override
  String goalContractChecksCount(int count, int max) {
    return '$count trên $max kiểm chứng';
  }

  @override
  String get goalContractCheckTaskHint =>
      'Tên tác vụ của môi trường, ví dụ test';

  @override
  String get goalContractCheckCommandHint => 'Lệnh, ví dụ make test';

  @override
  String get goalContractCheckWhere => 'Chạy ở đâu';

  @override
  String get goalContractCheckInWorktree => 'Trong cây làm việc';

  @override
  String get goalContractCheckInEnvironment => 'Tác vụ môi trường';

  @override
  String get goalContractSecondsSuffix => 'giây';

  @override
  String goalContractTimeoutRange(int max) {
    return 'Từ 1 đến $max giây';
  }

  @override
  String get goalContractRemoveCheck => 'Xóa kiểm chứng';

  @override
  String get goalContractDoneMeans => 'Hoàn thành khi';

  @override
  String get goalContractDoneMeansHelp =>
      'Mỗi tiêu chí là một điều mà bộ đánh giá có thể xác nhận.';

  @override
  String get goalContractCriterionHint =>
      'Ghi chú phát hành liệt kê mọi thay đổi đã merge';

  @override
  String goalContractCriterionTooLong(int max) {
    return 'Tối đa $max ký tự.';
  }

  @override
  String get goalContractRemoveCriterion => 'Xóa tiêu chí';

  @override
  String get goalContractAddCriterion => 'Thêm tiêu chí';

  @override
  String goalContractCriteriaFull(int max) {
    return 'Một mục tiêu có tối đa $max tiêu chí.';
  }

  @override
  String goalContractCriteriaCount(int count, int max) {
    return '$count trên $max tiêu chí';
  }

  @override
  String get goalContractChecks => 'Kiểm chứng';

  @override
  String get goalContractChecksHelp =>
      'Máy chủ chạy các kiểm chứng này khi agent nói rằng nó đã xong. Mục tiêu không có kiểm chứng sẽ chỉ dựa vào đánh giá.';

  @override
  String get goalContractBoundaries => 'Ranh giới';

  @override
  String get goalContractBoundariesHint => 'Không thay đổi API công khai';

  @override
  String get goalContractStopWhen => 'Dừng và hỏi khi';

  @override
  String get goalContractStopWhenHint =>
      'Một lần di chuyển dữ liệu sẽ xóa dữ liệu';

  @override
  String get goalContractEditTitle => 'Sửa định nghĩa hoàn thành';

  @override
  String get goalCheckerTitle => 'Ai kiểm tra mục tiêu này';

  @override
  String get goalCheckerLabel => 'Bộ kiểm tra';

  @override
  String get goalCheckerNone => 'Không có bộ kiểm tra riêng';

  @override
  String get goalCheckerNoneWeaker =>
      'Khi không có bộ kiểm tra riêng, agent sẽ tự đánh giá công việc của mình, và cách này bắt được ít lỗi hơn.';

  @override
  String goalCheckerRecommend(String agent) {
    return 'Ví dụ $agent: bộ kiểm tra từ nhà cung cấp khác ít có khả năng chung điểm mù với agent.';
  }

  @override
  String get goalCheckerRecommendGeneric =>
      'Bộ kiểm tra từ nhà cung cấp khác với agent của mục tiêu ít có khả năng chung điểm mù với nó.';

  @override
  String raiseCapSpentOf(String spent, String cap) {
    return 'Đã chi $spent trên $cap.';
  }

  @override
  String get raiseCapNewCap => 'Ngân sách mới bằng đô la';

  @override
  String raiseCapMustExceed(String cap) {
    return 'Nhập số lớn hơn $cap.';
  }

  @override
  String get raiseCapConfirm => 'Tăng ngân sách';

  @override
  String get goalsBackToList => 'Tất cả mục tiêu';

  @override
  String goalPursuedBy(String agent) {
    return 'Được theo đuổi bởi $agent';
  }

  @override
  String get goalOpenConversation => 'Mở cuộc trò chuyện';

  @override
  String goalStarted(String time) {
    return 'Bắt đầu lúc $time';
  }

  @override
  String get goalStopTitle => 'Dừng mục tiêu này?';

  @override
  String get goalStopBody =>
      'Agent sẽ ngừng làm việc trên mục tiêu này vĩnh viễn. Công việc đã làm cho đến nay vẫn còn trong cuộc trò chuyện.';

  @override
  String get goalRaiseBudgetTitle => 'Tăng ngân sách và tiếp tục';

  @override
  String get goalRaiseBudgetAction => 'Tăng ngân sách';

  @override
  String get goalSectionNow => 'Hiện tại';

  @override
  String get goalFactSegments => 'Phân đoạn';

  @override
  String get goalFactMoney => 'Đã chi';

  @override
  String get goalFactDeadline => 'Hạn chót';

  @override
  String get goalFactNoProgress => 'Không tiến triển';

  @override
  String get goalNoDeadline => 'Không có';

  @override
  String goalDeadlineWithLeft(String time, String left) {
    return '$time, còn $left';
  }

  @override
  String goalNoProgressCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count phân đoạn gần nhất không có tiến triển',
      one: 'Phân đoạn gần nhất không có tiến triển',
    );
    return '$_temp0';
  }

  @override
  String get goalObjective => 'Mục tiêu cần đạt';

  @override
  String get goalSectionContract => 'Hoàn thành khi';

  @override
  String get goalContractPauseFirst =>
      'Hãy tạm dừng mục tiêu để thay đổi định nghĩa hoàn thành hoặc bộ kiểm tra.';

  @override
  String get goalContractEdit => 'Sửa';

  @override
  String get goalCheckerChange => 'Đổi bộ kiểm tra';

  @override
  String get goalContractNone =>
      'Chưa có gì được ghi lại. Agent sẽ tự quyết định khi nào đã xong.';

  @override
  String get goalCheckerSelf =>
      'Không có bộ kiểm tra riêng: agent tự xác minh công việc của mình.';

  @override
  String goalCheckerIs(String agent) {
    return 'Được kiểm tra bởi $agent';
  }

  @override
  String goalCheckWorktree(int seconds) {
    return 'Trong cây làm việc, tối đa $seconds giây';
  }

  @override
  String goalCheckEnvironmentTask(int seconds) {
    return 'Tác vụ môi trường, tối đa $seconds giây';
  }

  @override
  String get goalSectionVerification => 'Xác minh';

  @override
  String get goalNotVerifiedYet =>
      'Chưa được xác minh. Agent chưa nói rằng nó đã xong.';

  @override
  String goalVerificationRound(int round, int total, String time) {
    return 'Vòng $round trên $total, $time';
  }

  @override
  String get goalVerificationClaim => 'Điều agent khẳng định';

  @override
  String get goalCheckOutputTail => 'Đầu ra (các dòng cuối)';

  @override
  String goalCheckExitCode(int code) {
    return 'Đạt · mã thoát $code';
  }

  @override
  String get goalVerificationReview => 'Đánh giá';

  @override
  String get goalVerificationNoVerdict => 'Chưa có đánh giá.';

  @override
  String goalVerdictItem(String criterion, String state) {
    return '$criterion · $state';
  }

  @override
  String get goalSectionSchedules => 'Lịch và lượt đánh thức';

  @override
  String get goalNoSchedules => 'Không có lịch hay lượt đánh thức đang chờ.';

  @override
  String get goalPendingWakes => 'Lượt đánh thức đang chờ';

  @override
  String workListGroup(String label, int count) {
    return '$label · $count';
  }

  @override
  String get goalNotFound =>
      'Mục tiêu này không tồn tại, hoặc nằm trong một space mà bạn không mở được.';

  @override
  String get goalsTitle => 'Mục tiêu';

  @override
  String get goalsSubtitle =>
      'Công việc mà agent tiếp tục làm cho đến khi đạt định nghĩa hoàn thành.';

  @override
  String get goalsEmpty => 'Chưa có mục tiêu nào';

  @override
  String get goalsEmptyHint =>
      'Hãy bắt đầu một mục tiêu bằng /goal trong cuộc trò chuyện.';

  @override
  String get goalsGroupReview => 'Đang chờ đánh giá';

  @override
  String get goalsGroupOpen => 'Đang mở';

  @override
  String get goalsGroupEnded => 'Đã kết thúc';

  @override
  String get scheduleStatusActive => 'Đang hoạt động';

  @override
  String get scheduleStatusPaused => 'Tạm dừng';

  @override
  String get scheduleStatusEnded => 'Đã kết thúc';

  @override
  String get scheduleWhenBusySkip => 'Bỏ qua lần kích hoạt khi agent đang bận';

  @override
  String get scheduleWhenBusyQueue => 'Chờ đến khi agent rảnh';

  @override
  String get scheduleDeliverRun => 'Bắt đầu một lần chạy';

  @override
  String get scheduleDeliverNotify => 'Chỉ thông báo';

  @override
  String get scheduleNew => 'Lịch mới';

  @override
  String get schedulesEmpty => 'Chưa có lịch hay theo dõi nào';

  @override
  String get schedulesEmptyHint =>
      'Agent đặt chúng bằng /loop và /schedule, hoặc bạn có thể tạo một lịch.';

  @override
  String scheduleOwnedBy(String name) {
    return 'Người phụ trách: $name';
  }

  @override
  String scheduleRunsSkips(int runs, int skips) {
    String _temp0 = intl.Intl.pluralLogic(
      runs,
      locale: localeName,
      other: '$runs lần chạy',
      one: '1 lần chạy',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skips,
      locale: localeName,
      other: '$skips lần bỏ qua',
      one: '1 lần bỏ qua',
      zero: 'không bỏ qua lần nào',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String scheduleExpires(String time) {
    return 'Kết thúc lúc $time';
  }

  @override
  String scheduleNextFires(String times) {
    return 'Tiếp theo: $times';
  }

  @override
  String get schedulesTitle => 'Lịch';

  @override
  String get schedulesSubtitle => 'Lịch, vòng lặp và theo dõi đánh thức agent.';

  @override
  String get scheduleWhenLabel => 'Khi nào kích hoạt';

  @override
  String get scheduleWhenEvery => 'Lặp lại, mỗi…';

  @override
  String get scheduleWhenCron => 'Theo lịch cron';

  @override
  String get scheduleWhenOnceIn => 'Một lần, sau…';

  @override
  String get scheduleWhenOnceAt => 'Một lần, vào lần tới lúc…';

  @override
  String get scheduleDurationLabel => 'Khoảng thời gian';

  @override
  String get scheduleDurationHelp =>
      'Dùng s, m, h hoặc d, ví dụ 30m hoặc 1h30m. Các lần lặp cách nhau ít nhất 60 giây.';

  @override
  String get scheduleDurationInvalid =>
      'Đây không phải khoảng thời gian, ví dụ 30m hoặc 2h.';

  @override
  String get scheduleHour => 'Giờ';

  @override
  String get scheduleMinute => 'Phút';

  @override
  String get scheduleCronLabel => 'Cron (phút giờ ngày tháng thứ)';

  @override
  String get scheduleCronInvalid =>
      'Đây không phải biểu thức cron năm trường có thể kích hoạt.';

  @override
  String get scheduleTimeInvalid =>
      'Đây không phải thời điểm trong tương lai, chẳng hạn 09:00 hoặc 2026-11-21T09:00Z.';

  @override
  String scheduleDaysRange(int max) {
    return 'Từ 1 đến $max ngày.';
  }

  @override
  String scheduleOptionUnknown(String option) {
    return '$option không phải là tùy chọn hợp lệ.';
  }

  @override
  String get scheduleLimits => 'Giới hạn';

  @override
  String get schedulePresetWeekdays => 'Các ngày trong tuần lúc 09:00';

  @override
  String get schedulePresetDaily => 'Hằng ngày lúc 09:00';

  @override
  String get schedulePresetHourly => 'Mỗi giờ, đúng giờ';

  @override
  String get scheduleZoneLabel => 'Múi giờ';

  @override
  String get scheduleZoneHelp =>
      'Để trống nghĩa là múi giờ của không gian làm việc.';

  @override
  String get scheduleZoneInvalid =>
      'Đây không phải múi giờ, ví dụ Europe/Berlin.';

  @override
  String get scheduleCreateTitle => 'Lịch mới';

  @override
  String get scheduleSpaceLabel => 'Space';

  @override
  String get scheduleSpaceHint => 'Chọn một space';

  @override
  String get scheduleConversationLabel => 'Cuộc trò chuyện';

  @override
  String get scheduleConversationHint => 'Chọn một cuộc trò chuyện';

  @override
  String get scheduleAgentLabel => 'Agent';

  @override
  String get scheduleAgentHint => 'Chọn agent sẽ được đánh thức';

  @override
  String get scheduleNoteLabel => 'Mỗi lần chạy bắt đầu từ';

  @override
  String get scheduleNoteHint =>
      'Tóm tắt những gì đã thay đổi qua đêm và nêu mọi việc đang bị chặn.';

  @override
  String get scheduleExpiresInDays => 'Kết thúc sau (ngày)';

  @override
  String get scheduleExpiresInDaysHelp => 'Để trống: 30 ngày, tối đa 365.';

  @override
  String get scheduleMaxRuns => 'Giới hạn số lần chạy';

  @override
  String scheduleMaxRunsHelp(int max) {
    return 'Để trống: không giới hạn, tối đa $max.';
  }

  @override
  String get scheduleCostCap => 'Giới hạn chi phí (đô la)';

  @override
  String get scheduleCostCapHelp =>
      'Để trống: mặc định của không gian làm việc.';

  @override
  String get scheduleWhenBusyLabel => 'Nếu agent đang bận';

  @override
  String get scheduleWhenBusyDefault => 'Mặc định cho loại này';

  @override
  String get scheduleDeliverLabel => 'Mỗi lần kích hoạt';

  @override
  String get scheduleCreate => 'Tạo lịch';

  @override
  String get scheduleExtendTitle => 'Gia hạn lịch này';

  @override
  String scheduleExtendNow(String current, String latest) {
    return 'Lịch kết thúc lúc $current. Có thể kéo dài tối đa đến $latest.';
  }

  @override
  String get scheduleExtendDays => 'Thêm ngày';

  @override
  String scheduleExtendTooLong(String latest) {
    return 'Lịch có thể kết thúc muộn nhất là $latest.';
  }

  @override
  String scheduleMaxRunsRange(int max) {
    return 'Từ 1 đến $max lần chạy.';
  }

  @override
  String scheduleCostCapRange(String max) {
    return 'Ít nhất 1 đô la và tối đa $max.';
  }

  @override
  String get scheduleExtend => 'Gia hạn';

  @override
  String get scheduleRemoveTitle => 'Xóa lịch này?';

  @override
  String get scheduleDeleteTitle => 'Hủy lịch này?';

  @override
  String get scheduleRemoveBody =>
      'Lịch sẽ biến khỏi danh sách. Các lần chạy của nó vẫn còn trong cuộc trò chuyện.';

  @override
  String get scheduleDeleteBody =>
      'Lịch sẽ ngừng kích hoạt vĩnh viễn. Các lần chạy của nó vẫn còn trong cuộc trò chuyện.';

  @override
  String get scheduleRemove => 'Xóa';

  @override
  String get scheduleDelete => 'Hủy lịch';

  @override
  String get scheduleOwnerOnly =>
      'Chỉ người phụ trách mới có thể tiếp tục hoặc gia hạn lịch này.';

  @override
  String get schedulesBackToList => 'Tất cả lịch';

  @override
  String get scheduleNoteByAgent => 'Ghi chú, do agent viết';

  @override
  String get scheduleNoteByPerson => 'Ghi chú, do một người viết';

  @override
  String scheduleNoteEditedBy(String name) {
    return 'Ghi chú, sửa lần cuối bởi $name';
  }

  @override
  String get scheduleNoNote => 'Không có ghi chú.';

  @override
  String get schedulePause => 'Tạm dừng';

  @override
  String get scheduleResume => 'Tiếp tục';

  @override
  String get scheduleOpenChainRoot => 'Mở lịch đầu tiên của chuỗi này';

  @override
  String get scheduleSectionFacts => 'Chi tiết';

  @override
  String get scheduleFactAgent => 'Đánh thức';

  @override
  String get scheduleFactConversation => 'Trong';

  @override
  String get scheduleConversationUnknown =>
      'Một cuộc trò chuyện bạn có thể không xem được';

  @override
  String get scheduleFactOwner => 'Người phụ trách';

  @override
  String get scheduleNoOwner => 'Không ai';

  @override
  String get scheduleFactNextFires => 'Các lần kích hoạt tiếp theo';

  @override
  String get scheduleFactNext => 'Kích hoạt tiếp theo';

  @override
  String get scheduleFactLast => 'Kích hoạt gần nhất';

  @override
  String get scheduleFactRuns => 'Lần chạy';

  @override
  String scheduleRunsNoCap(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lần chạy, không giới hạn',
      one: '1 lần chạy, không giới hạn',
    );
    return '$_temp0';
  }

  @override
  String scheduleRunsOfCap(int count, int max) {
    return '$count trên $max lần chạy';
  }

  @override
  String get scheduleFactSkips => 'Bỏ qua';

  @override
  String scheduleSkips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lần kích hoạt bị bỏ qua',
      one: '1 lần kích hoạt bị bỏ qua',
      zero: 'Không có',
    );
    return '$_temp0';
  }

  @override
  String get scheduleFactSpent => 'Đã chi';

  @override
  String get scheduleFactEnds => 'Kết thúc';

  @override
  String get scheduleFactWhenBusy => 'Nếu agent đang bận';

  @override
  String get scheduleFactDeliver => 'Mỗi lần kích hoạt';

  @override
  String get scheduleFactChain => 'Chuỗi';

  @override
  String scheduleChainLeft(int runs, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      runs,
      locale: localeName,
      other: 'Còn $runs lần chạy',
      one: 'Còn 1 lần chạy',
    );
    return '$_temp0 trong chuỗi, kết thúc lúc $time';
  }

  @override
  String get scheduleFactCreated => 'Đã tạo';

  @override
  String get scheduleSectionHistory => 'Lượt đánh thức và lần chạy gần đây';

  @override
  String get scheduleNoRuns => 'Chưa có lần chạy nào.';

  @override
  String scheduleRunLine(String status, String cost) {
    return '$status · $cost';
  }

  @override
  String get scheduleRunPending => 'Đang chờ bắt đầu';

  @override
  String get scheduleRunRunning => 'Đang chạy';

  @override
  String get scheduleRunCompleted => 'Đã xong';

  @override
  String get scheduleRunFailed => 'Thất bại';

  @override
  String get scheduleNotFound =>
      'Lịch này không tồn tại, hoặc nằm trong một space mà bạn không mở được.';

  @override
  String get improvementCampaignTitle => 'Chạy một đánh giá';

  @override
  String improvementCampaignCost(int repetitions, String budget) {
    String _temp0 = intl.Intl.pluralLogic(
      repetitions,
      locale: localeName,
      other: 'Mỗi tác vụ chạy $repetitions lần',
      one: 'Mỗi tác vụ chạy một lần',
    );
    return '$_temp0 với skill hiện tại và với thay đổi. Chi tối đa $budget, tính vào không gian làm việc này.';
  }

  @override
  String get improvementCampaignCostUnknown =>
      'Đánh giá chạy bộ dữ liệu với skill hiện tại và với thay đổi, trong giới hạn ngân sách bạn đặt.';

  @override
  String get improvementCampaignUnavailable =>
      'Hiện không thể chạy đánh giá trên máy chủ này.';

  @override
  String get improvementCampaignCorpus => 'Bộ dữ liệu';

  @override
  String get improvementCampaignProvider => 'Nhà cung cấp';

  @override
  String get improvementCampaignModel => 'Mô hình';

  @override
  String get improvementCampaignRepetitions => 'Số lần chạy mỗi tác vụ';

  @override
  String get improvementCampaignBudget => 'Ngân sách (đô la)';

  @override
  String improvementCampaignRange(int max) {
    return 'Từ 1 đến $max.';
  }

  @override
  String get improvementCampaignStart => 'Bắt đầu đánh giá';

  @override
  String get improvementRollbackTitle => 'Hoàn tác thay đổi này?';

  @override
  String get improvementRollbackBody =>
      'Nội dung mà nó đã thay thế sẽ được khôi phục, miễn là chưa ai thay đổi nó kể từ đó.';

  @override
  String get improvementRollback => 'Hoàn tác';

  @override
  String get improvementRolledBackDone => 'Đã hoàn tác.';

  @override
  String get improvementNeedsAdmin =>
      'Chỉ quản trị viên không gian làm việc mới có thể quyết định về đề xuất này: nó thay đổi một skill hoặc chính sách cho toàn bộ không gian làm việc.';

  @override
  String get improvementAdminDecides =>
      'Với tư cách quản trị viên, bạn quyết định về đề xuất này: nó thay đổi một skill hoặc chính sách cho toàn bộ không gian làm việc.';

  @override
  String get improvementNeedsCampaign =>
      'Hãy chạy một đánh giá đạt yêu cầu trước khi chấp nhận thay đổi skill này.';

  @override
  String get improvementsBackToList => 'Tất cả cải tiến';

  @override
  String improvementMeta(String kind, String scope, String agent) {
    return '$kind · $scope · do $agent đề xuất';
  }

  @override
  String get improvementAccept => 'Chấp nhận';

  @override
  String get improvementAcceptedDone => 'Đã chấp nhận.';

  @override
  String get improvementReject => 'Từ chối';

  @override
  String get improvementRejectedDone => 'Đã từ chối.';

  @override
  String get improvementRunEvaluation => 'Chạy đánh giá';

  @override
  String get improvementSectionChange => 'Thay đổi gì';

  @override
  String get improvementTarget => 'Đích';

  @override
  String improvementScopeLine(String scope) {
    return 'Áp dụng cho: $scope';
  }

  @override
  String get improvementNewText => 'Nội dung mới';

  @override
  String get improvementRemovedText => 'Nội dung bị xóa';

  @override
  String get improvementExpected => 'Tác động kỳ vọng';

  @override
  String get improvementSectionEvidence => 'Bằng chứng và quyết định';

  @override
  String get improvementNoEvidence => 'Không có bằng chứng đính kèm.';

  @override
  String get improvementEvidenceRuns => 'Lần chạy';

  @override
  String get improvementEvidenceMessages => 'Tin nhắn';

  @override
  String improvementOpenMessage(int index) {
    return 'Tin nhắn $index';
  }

  @override
  String get improvementEvidenceChecks => 'Kết quả kiểm tra';

  @override
  String get improvementEvaluation => 'Đánh giá';

  @override
  String get improvementCampaignNone => 'Chưa được đánh giá.';

  @override
  String get improvementCampaignRunning => 'Đang chạy đánh giá.';

  @override
  String get improvementCampaignPassed =>
      'Đánh giá đạt: nó đã chạy đầy đủ và thay đổi giải được ít nhất số lần chạy mà skill hiện tại giải được. Điều này không chứng minh thay đổi tốt hơn. Có thể chấp nhận.';

  @override
  String get improvementCampaignFailed =>
      'Đánh giá không đạt, hoặc skill đã thay đổi sau khi được đo. Hãy chạy lại, hoặc từ chối thay đổi.';

  @override
  String improvementDecided(String status, String name, String time) {
    return '$status bởi $name, $time';
  }

  @override
  String get improvementSomeone => 'ai đó';

  @override
  String improvementExpires(String time) {
    return 'Hết hạn lúc $time nếu không ai quyết định.';
  }

  @override
  String get improvementOpenApplied => 'Mở nội dung đã thay đổi';

  @override
  String get improvementsTitle => 'Cải tiến';

  @override
  String get improvementsSubtitle =>
      'Các thay đổi mà agent đã đề xuất cho bộ nhớ, ghi chú, chính sách và skill của chúng.';

  @override
  String get improvementsEmpty => 'Chưa có đề xuất nào';

  @override
  String get improvementsEmptyHint =>
      'Agent đề xuất cải tiến sau khi xem lại công việc, ví dụ với /refine.';

  @override
  String get improvementRowNeedsAdmin => 'Quản trị viên quyết định';

  @override
  String get improvementNotFound =>
      'Đề xuất này không tồn tại, hoặc nằm trong một space mà bạn không mở được.';

  @override
  String get dispatchSettingsTitle => 'Lịch';

  @override
  String get dispatchLimitsLabel => 'Giới hạn lịch';

  @override
  String get dispatchLimitsSubtitle =>
      'Giới hạn số lịch và theo dõi mà agent được giữ, cùng mặc định của chúng.';

  @override
  String dispatchLimitRange(int max) {
    return '1 đến $max';
  }

  @override
  String get dispatchLimitPerConversation =>
      'Mỗi agent trong một cuộc trò chuyện';

  @override
  String get dispatchLimitPerConversationHelp =>
      'Số lịch đang hoạt động hoặc tạm dừng mà một agent được giữ trong một cuộc trò chuyện.';

  @override
  String get dispatchLimitPerAgent => 'Mỗi agent';

  @override
  String get dispatchLimitPerAgentHelp =>
      'Số lịch đang hoạt động hoặc tạm dừng mà một agent được giữ trên toàn không gian làm việc.';

  @override
  String get dispatchLimitPerWorkspace => 'Trong không gian làm việc';

  @override
  String get dispatchLimitPerWorkspaceHelp =>
      'Số lịch đang hoạt động hoặc tạm dừng trong toàn bộ không gian làm việc.';

  @override
  String get dispatchLimitCostCap => 'Giới hạn chi phí mặc định (đô la)';

  @override
  String get dispatchLimitCostCapHelp =>
      'Số tiền tối đa một lịch được chi khi nó không đặt giới hạn riêng.';

  @override
  String get dispatchLimitZone => 'Múi giờ';

  @override
  String get dispatchLimitZoneHelp =>
      'Múi giờ dùng để đọc lịch cron khi lịch không chỉ định, và múi giờ của bản tóm tắt hằng ngày.';

  @override
  String get dispatchUnattendedLabel => 'Khi không ai trả lời';

  @override
  String get dispatchUnattendedSubtitle =>
      'Một lần chạy do máy chủ bắt đầu sẽ chờ người trả lời trong bao lâu, và khi nào bản tóm tắt hằng ngày về những việc đang chờ được gửi đi.';

  @override
  String get dispatchUnattendedExpiry => 'Yêu cầu chờ (giờ)';

  @override
  String get dispatchUnattendedExpiryHelp =>
      'Sau thời gian này, phê duyệt được coi là bị từ chối và câu hỏi là chưa được trả lời. Mục tiêu được đặt tự trả lời câu hỏi của mình sau 10 phút.';

  @override
  String dispatchUnattendedExpiryRange(int min, int max) {
    return 'Từ $min đến $max giờ';
  }

  @override
  String get dispatchDigestHour => 'Tóm tắt hằng ngày lúc (giờ)';

  @override
  String dispatchDigestHourHelp(String zone) {
    return 'Theo $zone, múi giờ ở trên.';
  }

  @override
  String get dispatchDigestHourRange => '0 đến 23';

  @override
  String get goalRecordCrumb => 'Mục tiêu';

  @override
  String get improvementRecordCrumb => 'Đề xuất';

  @override
  String get goalNodeNeedsAgent => 'Chọn agent sẽ theo đuổi mục tiêu.';

  @override
  String get goalNodeNeedsObjective => 'Hãy viết mục tiêu cần đạt.';

  @override
  String get goalNodeContractInvalid =>
      'Hợp đồng có một trường vượt giới hạn; nó sẽ không được lưu cho đến khi sửa.';

  @override
  String get goalNodeBudget => 'Ngân sách (đô la)';

  @override
  String get goalNodeBudgetHelp =>
      'Số tiền tối đa mục tiêu được chi. Khi hết, mục tiêu sẽ được giữ để chờ người xử lý.';

  @override
  String goalNodeBudgetRange(int max) {
    return 'Bắt buộc: lớn hơn 0, tối đa $max.';
  }

  @override
  String get goalNodeMaxRuns => 'Giới hạn phân đoạn';

  @override
  String get goalNodeMaxRunsHelp =>
      'Không bắt buộc. Số phân đoạn (lần chạy agent) tối đa mà mục tiêu được dùng.';

  @override
  String get goalNodeDeadline => 'Hạn chót (giờ)';

  @override
  String get goalNodeDeadlineHelp =>
      'Không bắt buộc. Số giờ tính từ khi bước bắt đầu mục tiêu.';

  @override
  String goalNodeRange(int max) {
    return 'Từ 1 đến $max, hoặc để trống.';
  }

  @override
  String get goalNodeContract => 'Hợp đồng';

  @override
  String get goalNodeContractHelp =>
      'Hoàn thành khi: các tiêu chí mà bộ đánh giá kiểm tra, và các lệnh phải chạy đạt.';

  @override
  String get nodeConfigObjective => 'Mục tiêu cần đạt';

  @override
  String pipelineRunGoalStep(String step) {
    return 'Bước $step theo đuổi một mục tiêu';
  }

  @override
  String get pipelineRunOpenGoal => 'Mở mục tiêu';

  @override
  String get pipelineRunHeldBudget =>
      'Lần chạy này bị giữ: điều phối của nó đã đạt giới hạn chi phí.';

  @override
  String pipelineRunHeldOther(String reason) {
    return 'Lần chạy này bị giữ ($reason).';
  }

  @override
  String pipelineRunHeldSpent(String spent, String cap) {
    return 'Đã chi $spent trên $cap. Tăng giới hạn và lần chạy sẽ tiếp tục.';
  }

  @override
  String get pipelineRunRaiseCap => 'Tăng giới hạn';

  @override
  String get pipelineRunRaiseCapTitle => 'Tăng giới hạn điều phối';

  @override
  String get pipelineRunCapRaised =>
      'Đã tăng giới hạn. Lần chạy sẽ tiếp tục ngay.';

  @override
  String get goalLaunchChecks => 'Kiểm chứng';

  @override
  String get goalLaunchChecksHelp =>
      'Các lệnh phải chạy đạt thì mục tiêu mới được hoàn tất. Không bắt buộc.';

  @override
  String get goalLaunchFresh => 'Bắt đầu mỗi phân đoạn mới';

  @override
  String get goalLaunchFreshHelp =>
      'Mỗi lần chạy bắt đầu không có lịch sử cuộc trò chuyện, chỉ từ mục tiêu và các ghi chú của nó.';

  @override
  String get goalLaunchAssume =>
      'Tự trả lời câu hỏi của mình khi không ai trả lời';

  @override
  String get goalLaunchAssumeHelp =>
      'Sau 10 phút không có câu trả lời, agent nêu giả định của mình rồi tiếp tục, nếu điều kiện dừng cho phép.';

  @override
  String workFeedLimitParkOutcomeResumed(String provider, String time) {
    return 'Đã tiếp tục lúc $time sau giới hạn sử dụng của $provider.';
  }

  @override
  String workFeedLimitParkOutcomeCancelled(String provider, String time) {
    return 'Đã hủy lúc $time. Nó không tiếp tục sau giới hạn sử dụng của $provider.';
  }

  @override
  String workFeedLimitParkOutcomeExpired(String provider, String time) {
    return 'Đã hết hạn lúc $time mà không tiếp tục sau giới hạn sử dụng của $provider.';
  }

  @override
  String workFeedLimitParkOutcomeSkipped(String provider, String time) {
    return 'Không tiếp tục sau giới hạn sử dụng của $provider ($time).';
  }

  @override
  String workFeedCommandRefusedNamed(String command) {
    return 'Lệnh /$command đã bị từ chối.';
  }

  @override
  String get improvementRefusalQueued =>
      'Một đánh giá cho cuộc trò chuyện này đã đang chờ chạy.';

  @override
  String get improvementRefusalAgentNotFound =>
      'Agent đó không thuộc không gian làm việc này.';

  @override
  String get workRefusalWakeQueueFull =>
      'Đã có quá nhiều lượt đánh thức đang chờ ở đây. Hãy thử lại sau khi một số đã chạy.';

  @override
  String get orchestrationRefusalNotYours =>
      'Chỉ người mà lần chạy này thay mặt mới có thể thay đổi.';

  @override
  String get orchestrationRefusalCapInvalid =>
      'Giới hạn mới phải lớn hơn giới hạn hiện tại và số tiền đã chi, và tối đa 1.000 USD.';

  @override
  String get orchestrationRefusalCapChanged =>
      'Có người đã tăng giới hạn trước. Hãy kiểm tra giới hạn mới và thử lại.';

  @override
  String workFeedCapRaised(String person, String oldCap, String newCap) {
    return '$person đã tăng giới hạn chi tiêu của lần chạy từ $oldCap lên $newCap.';
  }

  @override
  String get workFeedPersonUnknown => 'Một người';

  @override
  String workFeedApplyIncomplete(String skill) {
    return 'Thay đổi đã chấp nhận cho skill $skill không thể hoàn tất, vì skill đã thay đổi trong lúc đó. Đề xuất đã được hoàn tác.';
  }

  @override
  String get workFeedOpenImprovement => 'Mở cải tiến';

  @override
  String get peerAskFailNoOutput => 'Nó kết thúc mà không có câu trả lời.';

  @override
  String get peerAskFailRunFailed => 'Lần chạy của nó đã thất bại.';

  @override
  String get peerAskFailStoppedByPerson => 'Một người đã dừng lần chạy của nó.';

  @override
  String get peerAskFailBudget => 'Lần chạy của nó đã đạt ngân sách.';

  @override
  String get peerAskFailSilence =>
      'Lần chạy của nó im lặng quá lâu và đã bị dừng.';

  @override
  String get peerAskFailUsageLimit =>
      'Lần chạy của nó đã dừng ở giới hạn sử dụng của nhà cung cấp.';

  @override
  String get peerAskFailNotDelivered => 'Câu hỏi chưa bao giờ được gửi đi.';

  @override
  String heldSteeringLimitHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tin nhắn đang giữ ở giới hạn sử dụng',
      one: '1 tin nhắn đang giữ ở giới hạn sử dụng',
    );
    return '$_temp0';
  }

  @override
  String get heldSteeringLimitNote =>
      'Các tin nhắn này sẽ được gửi khi người mà lần chạy phục vụ tiếp tục lần chạy. Nếu không được tiếp tục trong vòng 7 ngày kể từ lúc đặt lại, chúng sẽ được giữ cho người đó.';

  @override
  String get wakeKindRuleFolded => 'Một sự kiện sau đó đã thay thế nó.';

  @override
  String goalCardWaitingNext(String time) {
    return 'Đang chờ điều nó đã thiết lập · sẽ kiểm tra lại lúc $time';
  }

  @override
  String raiseCapAtMost(String max) {
    return 'Nhập tối đa $max.';
  }

  @override
  String raiseCapNowAt(String cap) {
    return 'Giới hạn hiện là $cap.';
  }

  @override
  String get scheduleWakeReasonSchedule => 'Theo lịch';

  @override
  String get scheduleWakeReasonWatch => 'Theo dõi';

  @override
  String get scheduleWakeReasonLimitReset =>
      'Sau khi giới hạn sử dụng được đặt lại';

  @override
  String get scheduleWakeStatePending => 'Đang chờ';

  @override
  String get scheduleWakeStateHeld => 'Đang giữ';

  @override
  String get scheduleWakeStateClaimed => 'Đang bắt đầu';

  @override
  String get scheduleWakeStateDelivered => 'Đã gửi';

  @override
  String get scheduleWakeStateSkipped => 'Đã bỏ qua';

  @override
  String get scheduleWakeStateExpired => 'Đã hết hạn';

  @override
  String get scheduleWakeStateCancelled => 'Đã hủy';

  @override
  String scheduleWakeLine(String reason, String state) {
    return '$reason · $state';
  }

  @override
  String scheduleWakeExit(int code) {
    return 'mã thoát $code';
  }

  @override
  String scheduleWakeEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sự kiện',
      one: '1 sự kiện',
    );
    return '$_temp0';
  }

  @override
  String get scheduleWakesNone => 'Chưa có lượt đánh thức nào.';

  @override
  String get scheduleWakesOlder => 'Hiện cũ hơn';

  @override
  String get improvementCandidateStaged =>
      'Skill được đề xuất được lưu thành một bản sửa đổi riêng. Đánh giá nó không làm thay đổi skill đang dùng; skill chỉ thay đổi khi đề xuất được chấp nhận.';

  @override
  String goalNextWaitingFallback(String time) {
    return 'Mục tiêu sẽ tiếp tục khi điều nó đang chờ xuất hiện, hoặc sẽ kiểm tra lại lúc $time nếu không có gì xuất hiện.';
  }

  @override
  String get steeringRefusalHeldByLimit =>
      'Tin nhắn mà tạm dừng vì giới hạn sử dụng đang giữ không thể gửi bằng tay trong khi nó đang chờ.';

  @override
  String steeringRefusalHeldByLimitAt(String time) {
    return 'Tin nhắn mà tạm dừng vì giới hạn sử dụng đang giữ không thể gửi bằng tay trong khi nó đang chờ. Giới hạn sẽ được đặt lại lúc $time.';
  }

  @override
  String heldSteeringLimitResetsAt(String time) {
    return 'Giới hạn sẽ đặt lại lúc $time. Các tin nhắn này sẽ được gửi khi người mà lần chạy phục vụ tiếp tục lần chạy.';
  }

  @override
  String heldSteeringFromPerson(String name) {
    return 'Từ $name';
  }

  @override
  String get heldSteeringFromSomeoneElse => 'Từ người khác';

  @override
  String get heldSteeringOnlyWriterSends =>
      'Chỉ người đã viết tin nhắn đang giữ mới có thể gửi nó.';

  @override
  String get steeringRefusalNotYours =>
      'Các tin nhắn đang giữ này là của người khác. Chỉ người đã viết mới có thể gửi chúng.';

  @override
  String improvementEvaluationSolved(
    int pairedRuns,
    int candidateSolved,
    int baselineSolved,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      pairedRuns,
      locale: localeName,
      other: 'Trong $pairedRuns lần chạy ghép cặp',
      one: 'Trong 1 lần chạy ghép cặp',
    );
    return '$_temp0, thay đổi giải được $candidateSolved và skill hiện tại giải được $baselineSolved.';
  }

  @override
  String improvementEvaluationWorse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tác vụ kết quả kém đi với thay đổi.',
      one: '1 tác vụ kết quả kém đi với thay đổi.',
    );
    return '$_temp0';
  }

  @override
  String improvementEvaluationCostlier(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tác vụ tốn kém hơn với thay đổi.',
      one: '1 tác vụ tốn kém hơn với thay đổi.',
    );
    return '$_temp0';
  }

  @override
  String improvementEvaluationHarnessErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lần chạy gặp lỗi harness.',
      one: '1 lần chạy gặp lỗi harness.',
    );
    return '$_temp0';
  }

  @override
  String get improvementEvaluationIncomplete => 'Đánh giá chưa chạy đầy đủ.';

  @override
  String workFeedLimitParkExpires(String time) {
    return 'Hết hạn lúc $time';
  }

  @override
  String workFeedSchedulePaused(String person, String agent) {
    return '$person đã tạm dừng lịch của $agent.';
  }

  @override
  String get goalCardApproveNotYours =>
      'Chỉ người đã khởi chạy quy trình mới có thể phê duyệt việc hoàn tất mục tiêu này.';

  @override
  String get goalCardObjective => 'Mục tiêu cần đạt';

  @override
  String get planNeedsWrite =>
      'Phê duyệt hoặc thay đổi kế hoạch này cần quyền ghi trên mọi kho lưu trữ trong space này. Quản trị viên không gian làm việc có thể cấp quyền.';

  @override
  String scheduleSpentWithChain(String spent, String cap) {
    return '$spent trên $cap, tính tất cả lịch trong chuỗi của nó';
  }

  @override
  String get ccLoading => 'Đang tải';

  @override
  String get ccProgress => 'Tiến độ';

  @override
  String get ccBreadcrumb => 'Đường dẫn';

  @override
  String get ccDialog => 'Hộp thoại';

  @override
  String get ccResize => 'Thay đổi kích thước';

  @override
  String ccUnverifiedLabel(String label) {
    return '$label (chưa xác minh)';
  }

  @override
  String prRowSelect(String title) {
    return 'Chọn $title';
  }

  @override
  String get prTableSelectAll => 'Chọn tất cả pull request';

  @override
  String planVersionRewind(int version) {
    return 'Khôi phục về phiên bản $version';
  }
}
