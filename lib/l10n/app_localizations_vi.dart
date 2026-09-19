// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

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
  String get keybindingPushToTalkDescription =>
      'Giữ hoặc bật/tắt đọc chính tả trong trình soạn tin nhắn';

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
  String get guardrailClassPrPublish => 'Xuất bản review hoặc merge';

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
      'Tạo một Trình mô phỏng iOS tạm thời trên máy Mac của máy chủ. Trình mô phỏng sẽ bị xóa khi môi trường kiểm thử đóng; quyền truy cập mạng không được cô lập.';

  @override
  String get rigStopMachine => 'Dừng máy';

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
  String get serverModeRemote => 'Kết nối tới một phiên bản từ xa';

  @override
  String get serverModeRemoteDescription =>
      'Kết nối tới máy chủ Control Center đang chạy ở nơi khác. Dữ liệu của bạn nằm trên máy chủ đó.';

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
  String get serverSetupTitle => 'Control Center nên chạy như thế nào?';

  @override
  String get serverSetupSubtitle =>
      'Control Center cần một máy chủ nắm giữ dữ liệu của bạn. Chạy một máy chủ trong ứng dụng này, hoặc kết nối tới instance đang chạy ở nơi khác.';

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
  String get calendarAllDayGutter => 'Cả ngày';

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
  String get calendarStartRecording => 'Bắt đầu ghi';

  @override
  String get calendarStartRecordingAndLink => 'Bắt đầu ghi & liên kết';

  @override
  String get calendarJoinMeet => 'Tham gia cuộc họp';

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
  String get calendarAddAccount => 'Thêm tài khoản lịch';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Kết nối tài khoản Google để đồng bộ sự kiện vào không gian làm việc này.';

  @override
  String get calendarConnecting => 'Đang kết nối…';

  @override
  String get calendarSyncNow => 'Đồng bộ ngay';

  @override
  String get calendarNoWorkspace => 'Chọn không gian làm việc để xem lịch';

  @override
  String get calendarConnectError => 'Không thể kết nối Google Calendar';

  @override
  String get calendarClientIdLabel => 'Client ID';

  @override
  String get calendarClientSecretLabel => 'Client secret';

  @override
  String get calendarConnectCredsHint =>
      'Nhập client ID và secret OAuth device-code của Google cho dự án của bạn. Máy chủ thực hiện kết nối và đồng bộ — trình duyệt không bao giờ giữ token.';

  @override
  String get calendarConnectApproveInstruction =>
      'Mở trang xác minh trên bất kỳ thiết bị nào, đăng nhập và nhập mã này:';

  @override
  String get calendarConnectOpenPage => 'Mở trang xác minh';

  @override
  String get calendarConnectWaiting => 'Đang chờ phê duyệt…';

  @override
  String get calendarConnectDenied => 'Ủy quyền bị từ chối. Vui lòng thử lại.';

  @override
  String get calendarConnectExpired => 'Mã đã hết hạn. Vui lòng thử lại.';

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
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'Mở menu bộ lọc pull request';

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
  String get mcpServersSettingsDescription =>
      'Máy chủ MCP tích hợp và máy chủ MCP bên ngoài.';

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
  String get sortByStatus => 'Trạng thái';

  @override
  String get sortByName => 'Tên';

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
  String get activityLabel => 'HOẠT ĐỘNG';

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
  String get activityUpdatedGitHubToken => 'Đã cập nhật token GitHub';

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
  String get activityMarkedSpaceRead => 'Đã đánh dấu không gian là đã đọc';

  @override
  String get activityRespondedToInvitation => 'Đã phản hồi lời mời sự kiện';

  @override
  String get activityStartedCalendarConnect => 'Đã bắt đầu kết nối lịch';

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
  String get activityUpdatedMcpToken => 'Đã cập nhật token MCP';

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
  String get addGithubRepoPrompt =>
      'Thêm ít nhất một kho lưu trữ GitHub để xem pull request';

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
  String get allowGitPush => 'Cho phép git push';

  @override
  String get allowGithubApi => 'Cho phép gọi GitHub API';

  @override
  String get allowNetwork => 'Cho phép truy cập mạng chung';

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
  String get attachFiles => 'Đính kèm tệp';

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
  String get bugLabel => 'BUG';

  @override
  String get bundledDefaultsNeverUpdated =>
      'Mặc định đi kèm — không bao giờ cập nhật';

  @override
  String get cancel => 'Hủy';

  @override
  String get cancelEdit => 'Hủy chỉnh sửa';

  @override
  String get categoryCreation => 'Tạo';

  @override
  String get categoryEditing => 'Chỉnh sửa';

  @override
  String get categoryNavigation => 'Điều hướng';

  @override
  String get categorySystem => 'Hệ thống';

  @override
  String get categoryView => 'Xem theo danh mục';

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
  String get closeKeyboardHint => 'Đóng';

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
  String get configureDefaultRunners =>
      'Cấu hình adapter và mô hình dùng cho không gian mới và tạo tiêu đề.';

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
  String get customCapabilitiesDescription => 'Mô tả khả năng tùy chỉnh';

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
  String get defaultCapabilities => 'Khả năng mặc định · không gian mới';

  @override
  String get defaultChat => 'Chat mặc định';

  @override
  String get defaultRunners => 'Runner mặc định';

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
  String get archiveConversation => 'Lưu trữ cuộc trò chuyện';

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
  String get egPlatform => 'vd. macOS';

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
  String get gatesGithubPatPush =>
      'Kiểm soát tiêm GitHub PAT. Cần để agent đẩy mã.';

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
  String get images => 'Hình ảnh';

  @override
  String get inactive => 'Không hoạt động';

  @override
  String get install => 'Cài đặt';

  @override
  String get installRequired => 'Cần cài đặt';

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
  String get keybindingAddARepositoryDescription => 'Thêm kho lưu trữ';

  @override
  String get keybindingAddRepository => 'Thêm kho lưu trữ';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'Gắn hoặc bỏ đánh dấu bài đã chọn';

  @override
  String get keybindingCommandPalette => 'Bảng lệnh';

  @override
  String get keybindingCreateANewAgentDescription => 'Tạo agent mới';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'Tạo không gian làm việc mới';

  @override
  String get keybindingFocusSearch => 'Tập trung ô tìm kiếm';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'Tập trung ô tìm kiếm pull request';

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
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'Mở hoặc đóng cửa sổ bật lên chuyển không gian làm việc trên thanh bên';

  @override
  String get keybindingOpenPr => 'Mở PR';

  @override
  String get keybindingOpenSettings => 'Mở cài đặt';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'Mở cài đặt ứng dụng';

  @override
  String get keybindingOpenTheCommandPaletteDescription => 'Mở bảng lệnh';

  @override
  String get keybindingOpenTheSelectedArticleDescription =>
      'Mở bài viết đã chọn';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'Mở pull request đã chọn';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'Mở không gian làm việc đã chọn';

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
  String get keybindingRefreshAllFeedsDescription => 'Làm mới tất cả nguồn cấp';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'Làm mới danh sách pull request';

  @override
  String get keybindingRescanForAdaptersDescription => 'Quét lại adapter';

  @override
  String get keybindingSelectTheNextArticleDescription =>
      'Chọn bài viết tiếp theo';

  @override
  String get keybindingSelectTheNextSpaceDescription =>
      'Chọn không gian tiếp theo';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'Chọn bài viết trước';

  @override
  String get keybindingSelectThePreviousSpaceDescription =>
      'Chọn không gian trước';

  @override
  String get keybindingSendMessage => 'Gửi tin nhắn';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'Gửi tin nhắn hiện tại';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Chuyển giữa chế độ sáng và tối';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Chuyển sang không gian làm việc thứ tám';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Chuyển sang không gian làm việc thứ năm';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'Chuyển sang không gian làm việc đầu tiên';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'Chuyển sang không gian làm việc thứ tư';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'Chuyển sang không gian làm việc tiếp theo';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'Chuyển sang không gian làm việc thứ chín';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'Chuyển sang không gian làm việc trước';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'Chuyển sang không gian làm việc thứ hai';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'Chuyển sang không gian làm việc thứ bảy';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'Chuyển sang không gian làm việc thứ sáu';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'Chuyển sang không gian làm việc thứ ba';

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
  String get keybindings => 'Phím tắt';

  @override
  String get keybindingsDescription =>
      'Tất cả phím tắt. Phím tắt cố định và không thể gán lại.';

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
  String get mcpAuthToken => 'Token xác thực MCP';

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
  String get navigateLabel => 'Điều hướng';

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
  String get newLabel => 'Mới';

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
  String noShortcutsMatch(String query) {
    return 'Không có phím tắt khớp \"$query\"';
  }

  @override
  String get noSystemFonts => 'Không phát hiện font hệ thống.';

  @override
  String get noTokenSet => 'Chưa đặt token — truy cập không bị hạn chế.';

  @override
  String get noWorkingMemory => 'Chưa có ghi chú bộ nhớ làm việc.';

  @override
  String get noneAllRoles => 'Không (tất cả vai trò)';

  @override
  String get notAvailable => 'Không khả dụng';

  @override
  String get notConfiguredLabel => 'Chưa cấu hình.';

  @override
  String get notDetected => 'Không phát hiện';

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
      'Thông báo tin nhắn agent mới ở các không gian khác.';

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
  String get notificationsUnmuteRepo => 'Bật lại thông báo kho lưu trữ này';

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
  String get openApplicationSettings => 'Mở cài đặt ứng dụng';

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
  String get readPrsIssuesMetadata =>
      'Cho phép agent đọc PR, issue và metadata repo.';

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
  String repoAccessNoticeBody(String repos) {
    return 'Thông tin xác thực GitHub của máy chủ không thể thấy $repos. Nếu kho lưu trữ thuộc một tổ chức, hãy cài GitHub App ở đó hoặc kết nối token có quyền truy cập.';
  }

  @override
  String repoAccessNoticeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Không thể truy cập $count kho lưu trữ',
      one: 'Không thể truy cập một kho lưu trữ',
    );
    return '$_temp0';
  }

  @override
  String get repoAccessNoticeSuspendedTitle =>
      'Cài đặt GitHub App đã bị tạm ngưng';

  @override
  String repoAccessNoticeSuspendedBody(String repos) {
    return 'Đang hiển thị dữ liệu đã biết gần nhất cho $repos. Tiếp tục cài đặt trên GitHub, hoặc kết nối token có quyền truy cập.';
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
  String get runCompleted => 'Chạy xong';

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
  String get sandboxPermissions => 'Quyền sandbox';

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
  String get savingChanges => 'Đang lưu thay đổi…';

  @override
  String get savingEllipsis => 'Đang lưu…';

  @override
  String get scopeDiffToCommits =>
      'Giới hạn diff theo commit — Shift-click để chọn khoảng';

  @override
  String get noPrsMatchSearch => 'Không có pull request khớp';

  @override
  String get noPrsMatchSearchHint =>
      'Không có PR đang mở khớp tìm kiếm. Thử từ khác hoặc xóa tìm kiếm.';

  @override
  String get searchFactsHint => 'Tìm fact...';

  @override
  String get searchFonts => 'Tìm font…';

  @override
  String get searchGifs => 'Tìm GIF';

  @override
  String get searchGifsHint => 'Tìm GIF...';

  @override
  String get searchInDiffHint => 'Tìm trong diff…';

  @override
  String get searchOrTypeModel => 'Tìm hoặc nhập tên model…';

  @override
  String get searchPlaceholder => 'Tìm kiếm…';

  @override
  String get searchShortcuts => 'Tìm phím tắt…';

  @override
  String get shortcutUnavailableInBrowser => 'Không dùng được trên trình duyệt';

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
  String get selectEffortLevel => 'Chọn mức effort';

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
  String get setToken => 'Đặt token';

  @override
  String get settingsLabel => 'Cài đặt';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get settingsLanguageDescription => 'Chọn ngôn ngữ ứng dụng.';

  @override
  String get shortTask => 'Tác vụ ngắn';

  @override
  String get showNativeNotifications => 'Hiện thông báo gốc macOS cho sự kiện.';

  @override
  String get showSuperseded => 'Hiện bản bị thay thế';

  @override
  String get signedIn => 'Đã đăng nhập.';

  @override
  String signedInAs(String username) {
    return 'Đã đăng nhập với tên $username.';
  }

  @override
  String get skillEditor => 'Trình chỉnh sửa skill';

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
  String get skillOriginRegistry => 'Registry';

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
  String get suggestAChange => 'Đề xuất thay đổi';

  @override
  String get suggestLabel => 'ĐỀ XUẤT';

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
  String get ticketLabel => 'PHIẾU';

  @override
  String get titleLabel => 'Tiêu đề';

  @override
  String get todayLabel => 'Hôm nay';

  @override
  String get toggleTheme => 'Chuyển chủ đề';

  @override
  String get tokenConfigured => 'Đã cấu hình — client phải cung cấp token này.';

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
  String get updateKey => 'Cập nhật khóa';

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
  String get useWorkspaceDefault => 'Dùng mặc định không gian làm việc';

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
  String get whenOffNoDefaultRoute =>
      'Khi tắt, sandbox khởi động không có tuyến mặc định.';

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
  String get focusModeActiveTooltip =>
      'Chế độ tập trung đang bật — chạm để kết thúc';

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
  String get pipelineStepBranch => 'Nhánh';

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
  String get pipelineTemplateIdLabel => 'ID mẫu';

  @override
  String get pipelineTemplateBuiltInBadge => 'Có sẵn';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'Xóa mẫu?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'Xóa mẫu quy trình $name? Không thể hoàn tác.';
  }

  @override
  String get pipelineTemplateEditorTitle => 'Sửa quy trình';

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
  String get editorDragHint => 'Kéo từ thư viện, nhấp nút để chỉnh sửa';

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
      'Chạy bằng bash -c. GITHUB_TOKEN được thiết lập. Placeholder được thay thế trước khi thực thi.';

  @override
  String get nodeConfigTriggers => 'Kích hoạt từ';

  @override
  String get nodeConfigNoUpstream => 'Không có nút nào khác để nối từ.';

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
  String get triggerPanelTitle => 'Bộ kích hoạt';

  @override
  String get triggerPanelHelp => 'Điều khởi chạy quy trình này.';

  @override
  String get triggerManualHelp => 'Hiện trên trang chạy và khởi chạy thủ công.';

  @override
  String get triggerSectionAutomatic => 'Bộ kích hoạt tự động';

  @override
  String get triggerAddButton => 'Thêm bộ kích hoạt';

  @override
  String get triggerNoneYet => 'Chưa có bộ kích hoạt tự động.';

  @override
  String get triggerAddDialogTitle => 'Thêm bộ kích hoạt';

  @override
  String get triggerKindLabel => 'Loại bộ kích hoạt';

  @override
  String get triggerKindEvent => 'Khi có sự kiện';

  @override
  String get triggerKindSchedule => 'Theo lịch';

  @override
  String get triggerKindWebhook => 'Qua webhook';

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
  String get triggerEventFieldLabel => 'Sự kiện';

  @override
  String get triggerNoMoreEvents => 'Tất cả sự kiện có sẵn đã được gắn.';

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
  String get allowTicketingApi => 'Cho phép gọi API phiếu';

  @override
  String get ticketingApiKey => 'Khóa API phiếu';

  @override
  String get ticketingApiKeySubtitle =>
      'Chèn khóa API nhà cung cấp phiếu vào sandbox.';

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
  String get agentQuestionSubmit => 'Gửi câu trả lời';

  @override
  String get agentQuestionFreeformHint => 'Nhập câu trả lời…';

  @override
  String get agentQuestionAnswerLabel => 'Câu trả lời của bạn';

  @override
  String agentQuestionProgress(int index, int count) {
    return 'Câu hỏi $index / $count';
  }

  @override
  String get agentQuestionSkip => 'Bỏ qua';

  @override
  String get agentQuestionSkippedLabel => 'Đã bỏ qua';

  @override
  String get agentQuestionFreeformOptionHint => 'Mô tả bằng lời của bạn…';

  @override
  String get reviewRequested => 'Đã yêu cầu review';

  @override
  String get connectGitHubHint =>
      'Đăng nhập GitHub hoặc thêm token trong Cài đặt → Bạn → Hồ sơ & danh tính → Code hosting';

  @override
  String get connectGitHubToLoadPrs => 'Kết nối GitHub để tải pull requests';

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
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nhận xét mã',
      one: '1 nhận xét mã',
    );
    return '$_temp0';
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
  String get addAssignees => 'Thêm người được gán';

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
  String get composePrNoRepo => 'Chưa chọn kho GitHub';

  @override
  String get composePrNoRepoHint =>
      'Chọn không gian làm việc có kho liên kết GitHub để mở pull request.';

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
  String meetingsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cuộc họp',
      one: '1 cuộc họp',
      zero: 'Không có cuộc họp',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLedgerOpenActions => 'Hành động còn mở';

  @override
  String get meetingsLedgerDecisions => 'Quyết định';

  @override
  String get meetingsLiveOpen => 'Mở bản ghi';

  @override
  String get meetingTemplateShort => 'Mẫu';

  @override
  String get meetingsStatThisWeek => 'Tuần này';

  @override
  String get meetingsStatRecorded => 'Đã ghi';

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
  String get meetingsEnhancedPill => 'nâng cao';

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
  String get meetingDetectedRecord => 'Ghi';

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
  String get ideRevert => 'Hoàn nguyên';

  @override
  String get ideRevertConfirmTitle => 'Hoàn nguyên thay đổi';

  @override
  String ideRevertConfirmMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tệp',
      one: '1 tệp',
    );
    return 'Hoàn nguyên $_temp0 về HEAD? Thao tác này sẽ hủy thay đổi trên cây làm việc.';
  }

  @override
  String get ideRevertConfirmAction => 'Hoàn nguyên';

  @override
  String get ideRevertConfirmCancel => 'Hủy';

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
  String get ideViewSource => 'Xem nguồn';

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
  String ideSourceControlViewPr(int number) {
    return 'Xem pull request #$number';
  }

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
  String get mcpExternalServers => 'Máy chủ MCP bên ngoài';

  @override
  String get mcpExternalServersDescription =>
      'Kết nối máy chủ MCP bên ngoài (GitHub, Sentry, Postgres, tự động hóa trình duyệt). Máy chủ bạn đã cấu hình cho Claude, Cursor, VS Code và các công cụ khác được tự động phát hiện.';

  @override
  String get mcpApprovalMode => 'Phê duyệt công cụ';

  @override
  String get mcpApprovalModeDescription =>
      'Hành động công cụ nào chạy mà không hỏi. Đọc luôn được phép; cấp cao hơn sẽ hỏi.';

  @override
  String get mcpApprovalAlwaysAsk => 'Luôn hỏi';

  @override
  String get mcpApprovalWrite => 'Tự phê duyệt ghi';

  @override
  String get mcpApprovalYolo => 'Tự phê duyệt tất cả';

  @override
  String get mcpNoExternalServers => 'Không phát hiện máy chủ MCP bên ngoài.';

  @override
  String get mcpAuthorize => 'Ủy quyền';

  @override
  String get mcpReconnect => 'Kết nối lại';

  @override
  String get mcpExternalConnectionsNote =>
      'Máy chủ MCP bên ngoài chạy trên máy chủ agent (dùng chung cho desktop và web). Ủy quyền máy chủ OAuth chỉ khả dụng trên desktop.';

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
  String get usageAndCost => 'Sử dụng và chi phí';

  @override
  String get usageAndCostDescription =>
      'Chi phí các agent trong 7 ngày qua, từ chi phí chạy ghi nhận được.';

  @override
  String get noUsageYet => 'Chưa ghi nhận mức sử dụng.';

  @override
  String get spentThisWeek => 'đã chi tuần này';

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
  String get subscriptionUsagePartiallyAvailable => 'Khả dụng một phần';

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
  String get syncEngineSectionTitle => 'Công cụ đồng bộ';

  @override
  String get syncEngineDescription =>
      'Phiếu, tin nhắn và ghi chú cập nhật trực tiếp qua các thay đổi nhỏ tăng dần thay vì ảnh chụp toàn bộ. Tắt công tắc sẽ đưa kho đó về chế độ ảnh chụp toàn bộ — tải lại ứng dụng để thay đổi có hiệu lực.';

  @override
  String get syncEngineTicketsTitle => 'Phiếu';

  @override
  String get syncEngineMessagingTitle => 'Tin nhắn';

  @override
  String get syncEngineNotesTitle => 'Ghi chú';

  @override
  String get syncEngineOnSubtitle => 'Đồng bộ delta trực tiếp đang bật';

  @override
  String get syncEngineOffSubtitle => 'Đang dùng đồng bộ ảnh chụp toàn bộ';

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
  String get keybindingCreateANewSpaceDescription => 'Tạo không gian mới';

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
  String get customProvidersDescription =>
      'Mọi endpoint tương thích OpenAI hoặc Anthropic — Ollama, LM Studio, vLLM, hoặc triển khai riêng — kèm khóa API tùy chọn.';

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
  String provisioningRunningSetupScript(String repo) {
    return 'Đang chạy script thiết lập cho $repo…';
  }

  @override
  String get repoScriptsTitle => 'Script';

  @override
  String get repoScriptsTooltip => 'Cấu hình script vòng đời';

  @override
  String get repoScriptsSetupLabel => 'Script thiết lập';

  @override
  String get repoScriptsSetupHelp =>
      'Chạy trong cây làm việc của không gian ngay sau khi được tạo — cài dependency, sinh file. Thất bại đánh dấu không gian là thất bại; thử lại sẽ chạy lại.';

  @override
  String get repoScriptsArchiveLabel => 'Script lưu trữ';

  @override
  String get repoScriptsArchiveHelp =>
      'Chạy ngay trước khi cây làm việc của không gian bị xóa — dọn tài nguyên ngoài cây làm việc. Thất bại không bao giờ chặn việc xóa.';

  @override
  String get repoScriptsEnvHelp =>
      'Chạy qua bash từ cây làm việc, với CC_WORKSPACE_PATH (cây làm việc), CC_ROOT_PATH (thư mục gốc của repo), CC_SPACE_ID, CC_SPACE_NAME và CC_REPO_NAME được đặt.';

  @override
  String get repoScriptsSetupPlaceholder => 'vd. pnpm install';

  @override
  String get repoScriptsArchivePlaceholder =>
      'vd. docker compose -p \$CC_SPACE_ID down';

  @override
  String get repoScriptsRecentRuns => 'Lần chạy gần đây';

  @override
  String get repoScriptsNoRuns => 'Chưa có lần chạy nào';

  @override
  String get repoScriptsOutput => 'Kết quả';

  @override
  String get repoScriptsSaved => 'Đã lưu script';

  @override
  String get repoScriptsRunKindSetup => 'Thiết lập';

  @override
  String get repoScriptsRunKindArchive => 'Lưu trữ';

  @override
  String get repoScriptsRunStatusRunning => 'Đang chạy';

  @override
  String get repoScriptsRunStatusSucceeded => 'Thành công';

  @override
  String get repoScriptsRunStatusFailed => 'Thất bại';

  @override
  String get repoScriptsRunStatusTimedOut => 'Hết thời gian';

  @override
  String repoScriptsExitCode(int code) {
    return 'Mã thoát $code';
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
  String get profileSectionLabel => 'Hồ sơ';

  @override
  String get profileSectionDescription =>
      'Cách bạn hiện với đồng đội và trong thông tin tác giả commit git.';

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
  String get presenceAgentThinking => 'Đang nghĩ';

  @override
  String get presenceAgentRunning => 'Đang chạy';

  @override
  String get presenceAgentBlocked => 'Bị chặn';

  @override
  String get presenceAgentDone => 'Xong';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String presenceNameStatusCost(String name, String status, String cost) {
    return '$name — $status ($cost)';
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
  String get keybindingShowKeyboardShortcutsDescription =>
      'Hiện bảng phím tắt cho màn hình hiện tại';

  @override
  String get runPlaybookLabel => 'Chạy playbook';

  @override
  String get playbooksLabel => 'Playbook';

  @override
  String get keybindingUndo => 'Hoàn tác';

  @override
  String get keybindingRedo => 'Làm lại';

  @override
  String get keybindingUndoLastActionDescription =>
      'Hoàn tác thao tác có thể đảo ngược gần nhất';

  @override
  String get keybindingRedoLastActionDescription =>
      'Làm lại thao tác vừa hoàn tác';

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
  String get bannerMeetingJoin => 'Tham gia';

  @override
  String get bannerMeetingRecordAndLink => 'Ghi và liên kết';

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
  String get soundscapeLocationAutoNote =>
      'Vị trí được phát hiện tự động từ không gian làm việc này.';

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
  String get copyTimestamp => 'Sao chép dấu thời gian';

  @override
  String get copiedTimestamp => 'Đã sao chép dấu thời gian';

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
    return 'Nhắc bot trong $provider để giao việc cho agent, hoặc tạo phiếu bằng $command.';
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
    return 'Gửi lệnh này cho bot trong $provider. Chỉ dùng được một lần và hết hạn sau 15 phút.';
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
  String get calendarUseBuiltinApp => 'Dùng app Google của Control Center';

  @override
  String get calendarUseBuiltinAppHint =>
      'Phê duyệt bằng tài khoản Google. Không cần thiết lập gì trên Google Cloud.';

  @override
  String get calendarUseOwnClient => 'Dùng client Google Cloud của tôi';

  @override
  String get calendarUseOwnClientHint =>
      'Nhập OAuth client từ dự án Google Cloud của bạn.';

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
  String get settingsScopeBadgeYou => 'BẠN';

  @override
  String get settingsScopeBadgeDevice => 'THIẾT BỊ NÀY';

  @override
  String get settingsScopeBadgeWorkspace => 'KHÔNG GIAN LÀM VIỆC';

  @override
  String get settingsScopeBadgeServer => 'MÁY CHỦ';

  @override
  String get settingsProfileDescription =>
      'Tên, email và danh tính git gắn trên các commit thực hiện thay bạn.';

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
      'Danh tính, chính sách và quy ước dùng chung cho mọi người trong không gian làm việc này.';

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
  String get fromEnvironment => 'từ môi trường';

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
  String get webConnectTitle => 'Kết nối với Control Center';

  @override
  String get webConnectSubtitle =>
      'Kết nối tới cc-server đang chạy qua WebSocket. Khóa của bạn được giữ trên thiết bị này.';

  @override
  String get webConnectServerLabel => 'Máy chủ';

  @override
  String get webConnectDeviceIdLabel => 'Id thiết bị';

  @override
  String get webConnectPairingKeyLabel => 'Khóa ghép nối';

  @override
  String get webConnectPairingKeyHint => 'dán PSK';

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
  String get conversationTitlesSectionTitle => 'Tiêu đề cuộc trò chuyện';

  @override
  String get conversationTitlesSectionCaption =>
      'Chọn runner tự động đặt tên cuộc trò chuyện mới trong không gian làm việc này. Tiêu đề tắt cho đến khi chọn adapter, và áp dụng cho mọi thành viên.';

  @override
  String get conversationTitlesModelLabel => 'Mô hình tiêu đề';

  @override
  String get conversationTitlesAdapterLabel => 'Adapter';

  @override
  String get conversationTitlesAdapterHint => 'Tắt';

  @override
  String get conversationTitlesAdapterOff => 'Tắt';

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
  String get signInNotFinished =>
      'Đăng nhập chưa hoàn tất. Hoàn tất trên trình duyệt, rồi kiểm tra lại.';

  @override
  String get signedOutTitle => 'Bạn đã đăng xuất';

  @override
  String get signedOutSubtitle =>
      'Kết nối lưu trữ mã không còn hợp lệ — token đã hết hạn hoặc quyền truy cập bị thu hồi. Không có gì khác thay đổi: đăng nhập lại và mọi thứ vẫn như bạn để lại.';

  @override
  String get viaServerApp => 'qua ứng dụng của máy chủ này';

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
  String get addKey => 'Thêm khóa';

  @override
  String get providerApps => 'Ứng dụng nhà cung cấp';

  @override
  String get providerAppsDescription =>
      'Cách máy chủ này xác thực với tư cách của chính nó, và kênh người dùng đăng nhập. Công việc nền — webhook, polling, đồng bộ — chạy trên ứng dụng, không bao giờ trên token của người dùng.';

  @override
  String get providerAppId => 'Id ứng dụng';

  @override
  String get providerPrivateKey => 'Khóa riêng';

  @override
  String get providerClientId => 'Id client';

  @override
  String get providerClientSecret => 'Bí mật client';

  @override
  String get providerApiKey => 'Khóa API';

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
  String deviceCodeInstructions(String provider) {
    return 'Nhập mã này trên trang $provider vừa mở. Mã đã được sao chép vào clipboard.';
  }

  @override
  String get deviceCodeWaiting => 'Đang chờ bạn hoàn tất trong trình duyệt…';

  @override
  String get copyCodeAndOpen => 'Sao chép mã và mở';

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
  String get providersFacetNeedsSetup => 'Cần thiết lập';

  @override
  String get providersFacetCustom => 'Tùy chỉnh';

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
  String get adaptersFacetReady => 'Sẵn sàng';

  @override
  String get adaptersFacetMissing => 'Thiếu';

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
  String get defaultChatDescription =>
      'Chạy các cuộc hội thoại mới và mọi agent không có runner riêng.';

  @override
  String get shortTaskDescription =>
      'Chạy việc nền nhanh như tiêu đề và tóm tắt. Nên dùng mô hình nhỏ hơn ở đây.';

  @override
  String get settingsStateFailed => 'Thất bại';

  @override
  String get providerAppsGroupServer => 'Đóng vai trò máy chủ';

  @override
  String get providerAppsGroupServerDescription =>
      'Cho phép việc nền truy cập kho lưu trữ khi không có người đứng sau yêu cầu: webhook, polling pull request, đồng bộ phiếu.';

  @override
  String get providerAppsGroupPrConversations => 'Hội thoại pull request';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      'Cách nhà phát triển trò chuyện với máy chủ này trực tiếp trên GitHub. Hoạt động không cần webhook hay URL công khai — máy chủ tự polling.';

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
  String get mcpNoTokenWarning =>
      'Không có token, bất kỳ thứ gì truy cập được cổng này đều có thể gọi mọi công cụ.';

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
  String get sandboxBackendFieldDescription =>
      'Tự chọn loại mạnh nhất mà máy này hỗ trợ. Ghim một loại để tránh bị đổi khi bạn không để ý.';

  @override
  String get sandboxCapabilitiesDescription =>
      'Các cửa mở xuyên ranh giới. Mỗi mục là việc agent đã cách ly vẫn có thể làm với thế giới bên ngoài.';

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
  String get archiveSpace => 'Lưu trữ không gian';

  @override
  String get archivedSpaces => 'Không gian đã lưu trữ';

  @override
  String get archivedSpacesEmpty => 'Không có không gian đã lưu trữ';

  @override
  String get restoreSpace => 'Khôi phục';

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
  String get asideUnavailable =>
      'Đặt mô hình one-shot trong cài đặt không gian làm việc để dùng tính năng này';

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
  String get repoScriptsTest => 'Kiểm thử';

  @override
  String get repoScriptsTestTooltip =>
      'Chạy bản nháp này trên bản sao tạm của repo';

  @override
  String get repoScriptsRunKindTest => 'Kiểm thử';

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
  String get demoTourDone => 'Xong';

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
  String demoSessionEndingSoon(int minutes) {
    return 'Phiên demo này kết thúc sau $minutes phút.';
  }

  @override
  String get demoSessionEnded =>
      'Phiên demo này đã kết thúc. Tải lại trang để bắt đầu phiên mới.';

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
      'Chưa có ảnh chụp. Chỉ chụp khi bạn yêu cầu — không có lịch tự động.';

  @override
  String get backupSnapshotComplete => 'Hoàn tất';

  @override
  String get backupSnapshotIncomplete => 'Chưa hoàn tất';

  @override
  String get backupSnapshotIncompleteNote =>
      'Manifest thiếu hoặc liệt kê tệp không tồn tại, nên ảnh chụp này không thể khôi phục cả cài đặt. Các tệp không gian làm việc có sẵn vẫn có thể được nhận từng cái.';

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
  String get backupImportChooseFile => 'Chọn tệp';

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
      'Kết nối này tới máy chủ qua relay, không truyền được tệp. Kết nối trực tiếp tới máy chủ để tải xuống hoặc tải lên bản sao lưu.';

  @override
  String get backupTransferForbidden =>
      'Máy chủ từ chối. Tải xuống không gian làm việc cần vai trò admin, khôi phục cần owner, và toàn bộ snapshot cần operator của bản cài đặt.';

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
}
