// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'Quay lại';

  @override
  String get cancel => 'Hủy';

  @override
  String get retry => 'Thử lại';

  @override
  String get tryAgain => 'Thử lại';

  @override
  String get settings => 'Cài đặt';

  @override
  String get refresh => 'Làm mới';

  @override
  String get approve => 'Phê duyệt';

  @override
  String get deny => 'Từ chối';

  @override
  String get continueLabel => 'Tiếp tục';

  @override
  String get agentQuestionHeader => 'Câu hỏi dành cho bạn';

  @override
  String get agentQuestionAnsweredLabel => 'Đã trả lời';

  @override
  String get agentQuestionSkip => 'Bỏ qua';

  @override
  String get agentQuestionSkippedLabel => 'Đã bỏ qua';

  @override
  String get agentQuestionFreeformHint => 'Nhập câu trả lời của bạn…';

  @override
  String get agentApprovalRequired => 'Cần phê duyệt';

  @override
  String get approveAndRemember => 'Phê duyệt trong 8 giờ';

  @override
  String get decline => 'Từ chối';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get send => 'Gửi';

  @override
  String get close => 'Đóng';

  @override
  String get expand => 'Mở rộng';

  @override
  String get zoomIn => 'Phóng to';

  @override
  String get zoomOut => 'Thu nhỏ';

  @override
  String get resetZoom => 'Đặt lại thu phóng';

  @override
  String get scanQrPrompt =>
      'Quét mã QR trên Control Center để ghép nối điện thoại này.';

  @override
  String get scanQrHelp =>
      'Mở camera và hướng vào mã QR trong Control Center. Điện thoại này kết nối trực tiếp qua liên kết riêng.';

  @override
  String get connectingToMac => 'Đang kết nối với Control Center…';

  @override
  String get connectingDetail => 'Đang thiết lập liên kết trực tiếp, bảo mật.';

  @override
  String get identityChangedTitle => 'Danh tính máy chủ đã đổi';

  @override
  String get identityChangedBody =>
      'Máy chủ này không còn khớp danh tính đã lưu khi ghép nối. Có thể máy chủ đã được cài lại — hoặc có thứ đang xen giữa kết nối. Để an toàn, thiết bị này sẽ không kết nối. Gỡ ghép nối, rồi quét mã QR mới từ Control Center để ghép nối lại.';

  @override
  String get removePairing => 'Gỡ ghép nối';

  @override
  String get couldntConnect => 'Không thể kết nối';

  @override
  String get pendingPairingTitle => 'Kết nối máy chủ này?';

  @override
  String get pendingPairingBody =>
      'Một liên kết đã yêu cầu Control Center ghép nối với máy chủ này. Chỉ tiếp tục nếu bạn tự bắt đầu.';

  @override
  String get connect => 'Kết nối';

  @override
  String get failureNotPaired => 'Chưa ghép nối — quét mã QR từ Control Center';

  @override
  String get failureUnreachable =>
      'Không tới được máy chủ trên đường nào — kiểm tra máy chủ đang chạy, hoặc thử cùng mạng';

  @override
  String get failureIdentityChanged =>
      'Danh tính máy chủ đã đổi — nếu đã cài lại, hãy ghép nối lại thiết bị này';

  @override
  String get failureAuthRejected =>
      'Máy chủ từ chối thiết bị này — ghép nối lại từ Control Center';

  @override
  String get failureUnknown => 'Không thể kết nối — chạm để thử lại';

  @override
  String get statusConnected => 'Đã kết nối';

  @override
  String get statusConnecting => 'Đang kết nối';

  @override
  String get statusOffline => 'Ngoại tuyến';

  @override
  String get statusIdentityMismatch => 'Danh tính không khớp';

  @override
  String get statusNotPaired => 'Chưa ghép nối';

  @override
  String get statusConfirmPairing => 'Xác nhận ghép nối';

  @override
  String get connectionFailed => 'Kết nối thất bại';

  @override
  String get identityMismatchBanner =>
      'Danh tính máy chủ đã đổi — đã dừng kết nối. Ghép nối lại thiết bị này để tiếp tục.';

  @override
  String get tabInbox => 'Hộp thư';

  @override
  String get tabTickets => 'Ticket';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabPrs => 'PRs';

  @override
  String get tabCalendar => 'Lịch';

  @override
  String get tabNews => 'Tin';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label, $count đang chờ';
  }

  @override
  String get updateAvailable => 'Có Control Center mới';

  @override
  String get appearance => 'Giao diện';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get device => 'Thiết bị';

  @override
  String get themeSystem => 'Hệ thống';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeDark => 'Tối';

  @override
  String get languageSystem => 'Hệ thống';

  @override
  String get disconnectTapAgain =>
      'Chạm lần nữa để ngắt kết nối thiết bị này khỏi Control Center';

  @override
  String get disconnectDevice => 'Ngắt kết nối thiết bị này';

  @override
  String get disconnect => 'Ngắt kết nối';

  @override
  String get chooseWorkspace => 'Chọn không gian làm việc';

  @override
  String get workspaces => 'Không gian làm việc';

  @override
  String get workspacesLoadFailed => 'Không thể tải không gian làm việc';

  @override
  String get noWorkspacesYet => 'Chưa có không gian làm việc';

  @override
  String selectWorkspace(String name) {
    return 'Chọn $name';
  }

  @override
  String get inboxLoadFailed => 'Không thể tải hộp thư';

  @override
  String get allCaughtUp => 'Bạn đã xem hết';

  @override
  String get inboxNoForgeAccount =>
      'Máy chủ chưa kết nối tài khoản forge, nên chưa gắn được pull request cho bạn.';

  @override
  String get inboxNothingWaiting =>
      'Không có gì bị chặn và không có pull request nào đang chờ bạn.';

  @override
  String get blocked => 'Bị chặn';

  @override
  String get sectionNeedsYourReview => 'Cần bạn duyệt';

  @override
  String get sectionReturnedToYou => 'Đã trả lại cho bạn';

  @override
  String get sectionApprovedAndReady => 'Đã duyệt và sẵn sàng';

  @override
  String get sectionYourDrafts => 'Bản nháp của bạn';

  @override
  String get sectionWaitingForReviewers => 'Đang chờ người duyệt';

  @override
  String get sectionMergingAndMerged => 'Đang gộp và mới gộp';

  @override
  String get sectionWaitingForAuthor => 'Đang chờ tác giả';

  @override
  String waitingAgo(String ago) {
    return 'chờ $ago';
  }

  @override
  String get openConversation => 'Mở cuộc trò chuyện';

  @override
  String get calendarLoadFailed => 'Không thể tải lịch';

  @override
  String get nothingScheduled => 'Không có lịch';

  @override
  String get calendarEmptyDescription =>
      'Sự kiện từ lịch đã kết nối sẽ hiện ở đây.';

  @override
  String get agenda => 'Lịch trình';

  @override
  String get syncCalendarsNow => 'Đồng bộ lịch ngay';

  @override
  String get event => 'Sự kiện';

  @override
  String get eventNotFound => 'Không tìm thấy sự kiện';

  @override
  String get eventNotFoundDescription =>
      'Có thể nằm ngoài cửa sổ lịch trình, hoặc đã bị xóa phía nguồn.';

  @override
  String get joinMeeting => 'Tham gia họp';

  @override
  String get join => 'Tham gia';

  @override
  String attendeesCount(int count) {
    return 'Người tham dự ($count)';
  }

  @override
  String get details => 'Chi tiết';

  @override
  String get allDay => 'Cả ngày';

  @override
  String get happeningNow => 'Đang diễn ra';

  @override
  String inDuration(String duration) {
    return 'Sau $duration';
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
  String get attendeeAccepted => 'đã chấp nhận';

  @override
  String get attendeeDeclined => 'đã từ chối';

  @override
  String get attendeeMaybe => 'có thể';

  @override
  String get attendeeNoReply => 'chưa trả lời';

  @override
  String get organizer => 'người tổ chức';

  @override
  String get calendarNoAccounts =>
      'Workspace này chưa kết nối lịch. Kết nối từ ứng dụng máy tính — đăng nhập sẽ lưu token trên máy chủ.';

  @override
  String get calendarReauthNeeded =>
      'Một tài khoản lịch cần kết nối lại — nội dung bên dưới có thể đã cũ. Kết nối lại từ ứng dụng máy tính.';

  @override
  String get spacesLoadFailed => 'Không thể tải không gian';

  @override
  String get noSpaces => 'Không có không gian';

  @override
  String get spacesEmptyDescription =>
      'Không gian trong workspace này sẽ hiện ở đây.';

  @override
  String get thread => 'Luồng';

  @override
  String get agentWorking => 'Agent đang làm việc';

  @override
  String get messagesLoadFailed => 'Không thể tải tin nhắn';

  @override
  String get noMessagesYet => 'Chưa có tin nhắn';

  @override
  String get noMessagesDescription =>
      'Gửi tin nhắn để bắt đầu cuộc trò chuyện.';

  @override
  String get agentResponding => 'Agent đang phản hồi';

  @override
  String get agentFinished => 'Agent đã xong';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names quá lớn để gửi từ đây.',
      one: '$names quá lớn để gửi từ đây.',
    );
    return '$_temp0';
  }

  @override
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names quá lớn để gửi qua relay từ đây.',
      one: '$names quá lớn để gửi qua relay từ đây.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed =>
      'Không thể tải lên tệp đính kèm. Thử lại.';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Không tải lên được $count tệp đính kèm nên đã bỏ qua.',
      one: 'Không tải lên được 1 tệp đính kèm nên đã bỏ qua.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Đồng nghiệp';

  @override
  String get agent => 'Agent';

  @override
  String get attachFile => 'Đính kèm tệp';

  @override
  String get messageHint => 'Tin nhắn';

  @override
  String removeAttachment(String name) {
    return 'Gỡ $name';
  }

  @override
  String get articlesLoadFailed => 'Không tải được bài viết';

  @override
  String get noArticles => 'Không có bài viết';

  @override
  String get articlesEmptyDescription =>
      'Bài viết mới sẽ xuất hiện khi nguồn cấp nhật.';

  @override
  String get unread => 'Chưa đọc';

  @override
  String get allFeeds => 'Tất cả nguồn';

  @override
  String get save => 'Lưu';

  @override
  String get unsave => 'Bỏ lưu';

  @override
  String get readFullArticle => 'Đọc bài đầy đủ';

  @override
  String get ticketsLoadFailed => 'Không tải được ticket';

  @override
  String get noTickets => 'Không có ticket';

  @override
  String get ticketsEmptyDescription =>
      'Ticket trong không gian làm việc này sẽ xuất hiện tại đây.';

  @override
  String get all => 'Tất cả';

  @override
  String get ticket => 'Ticket';

  @override
  String get ticketLoadFailed => 'Không tải được ticket';

  @override
  String assignedTo(String name) {
    return 'Giao cho $name';
  }

  @override
  String get openInBrowser => 'Mở trong trình duyệt';

  @override
  String get status => 'Trạng thái';

  @override
  String get assign => 'Giao việc';

  @override
  String get reassign => 'Giao lại';

  @override
  String get noAgents => 'Không có agent';

  @override
  String get noAgentsDescription =>
      'Chọn một agent từ không gian làm việc này.';

  @override
  String get statusOpen => 'Mở';

  @override
  String get statusInProgress => 'Đang làm';

  @override
  String get statusBlocked => 'Bị chặn';

  @override
  String get statusInReview => 'Đang xem xét';

  @override
  String get statusDone => 'Xong';

  @override
  String get statusBacklog => 'Tồn đọng';

  @override
  String get lensNeedsMe => 'Cần tôi';

  @override
  String get lensMine => 'Của tôi';

  @override
  String get prsLoadFailed => 'Không tải được pull request';

  @override
  String get noOpenPullRequests => 'Không có pull request đang mở';

  @override
  String get nothingWaitingOnReview => 'Không có gì chờ bạn review';

  @override
  String get noOwnOpenPullRequests => 'Bạn không có pull request đang mở';

  @override
  String get nothingBlocked => 'Không có gì bị chặn';

  @override
  String get prsEmptyDescription =>
      'Pull request trên các repo của không gian làm việc này sẽ xuất hiện tại đây.';

  @override
  String get refreshPullRequests => 'Làm mới pull request';

  @override
  String get noForgeConnected =>
      'Máy chủ chưa kết nối forge nên không lấy được pull request. Hãy kết nối từ ứng dụng desktop.';

  @override
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Không đọc được $count repo.',
      one: 'Không đọc được 1 repo.',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return 'Không đọc được: $names';
  }

  @override
  String get installationSuspendedTitle => 'Cài đặt GitHub App đã bị tạm ngưng';

  @override
  String installationSuspendedBody(String names) {
    return 'Đang hiển thị dữ liệu đã biết gần nhất cho $names. Tiếp tục cài đặt trên GitHub, hoặc kết nối token có quyền truy cập.';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'Cài đặt GitHub App đã bị tạm ngưng. Đang hiển thị dữ liệu đã biết gần nhất cho $names. Tiếp tục cài đặt trên GitHub, hoặc kết nối token có quyền truy cập.';
  }

  @override
  String get draft => 'Bản nháp';

  @override
  String get merged => 'Đã hợp nhất';

  @override
  String get closed => 'Đã đóng';

  @override
  String get open => 'Mở';

  @override
  String get approved => 'Đã phê duyệt';

  @override
  String get changesRequested => 'Yêu cầu thay đổi';

  @override
  String get reviewRequired => 'Cần review';

  @override
  String get checksPassing => 'Kiểm tra đang đạt';

  @override
  String get checksFailing => 'Checks thất bại';

  @override
  String get checksRunning => 'Đang chạy kiểm tra';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => 'Pull request';

  @override
  String get prLoadFailed => 'Không tải được pull request này';

  @override
  String get openOnForge => 'Mở trên forge';

  @override
  String get requestChangesNeedsComment =>
      'Thêm bình luận giải thích những gì cần sửa.';

  @override
  String get conversation => 'Thảo luận';

  @override
  String get files => 'Tệp';

  @override
  String get checks => 'Kiểm tra';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tệp',
      one: '1 tệp',
    );
    return '$_temp0';
  }

  @override
  String commitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commit',
      one: '1 commit',
    );
    return '$_temp0';
  }

  @override
  String get conflicts => 'Xung đột';

  @override
  String get reviewers => 'Người đánh giá';

  @override
  String get noDescriptionNoComments => 'Chưa có mô tả và bình luận.';

  @override
  String get noChangedFiles => 'Không có tệp thay đổi.';

  @override
  String get noChecksReported => 'Không có check nào cho commit đầu.';

  @override
  String get reviewCommentHint => 'Để lại bình luận review…';

  @override
  String get comment => 'Bình luận';

  @override
  String get commentPosted => 'Đã gửi bình luận';

  @override
  String get request => 'Yêu cầu';

  @override
  String get squashAndMerge => 'Squash and merge';

  @override
  String noActionsAvailable(String status) {
    return '$status — không có thao tác.';
  }

  @override
  String get reviewApproved => 'đã duyệt';

  @override
  String get reviewRequestedChanges => 'yêu cầu sửa';

  @override
  String get reviewCommented => 'đã review';

  @override
  String get reviewPending => 'đang chờ';

  @override
  String get unknownAuthor => 'không xác định';

  @override
  String hideDiffFor(String file) {
    return 'Ẩn diff của $file';
  }

  @override
  String showDiffFor(String file) {
    return 'Hiện diff của $file';
  }

  @override
  String get checkRunning => 'đang chạy';

  @override
  String get checkPassed => 'đạt';

  @override
  String get checkFailed => 'thất bại';

  @override
  String get checkCancelled => 'đã hủy';

  @override
  String get checkSkipped => 'bỏ qua';

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
      'Không có diff văn bản cho tệp này — tệp nhị phân hoặc quá lớn để forge trả về.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hiện $count dòng còn lại',
      one: 'Hiện dòng còn lại',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dòng không đổi',
      one: '1 dòng không đổi',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'Chuyển tới mới nhất';

  @override
  String get streaming => 'Đang truyền';

  @override
  String get working => 'Đang xử lý';

  @override
  String get input => 'Đầu vào';

  @override
  String get output => 'Đầu ra';

  @override
  String get now => 'vừa xong';

  @override
  String agoMinutes(int count) {
    return '${count}m';
  }

  @override
  String agoHours(int count) {
    return '${count}h';
  }

  @override
  String agoDays(int count) {
    return '${count}d';
  }

  @override
  String get today => 'Hôm nay';

  @override
  String get tomorrow => 'Ngày mai';

  @override
  String get yesterday => 'Hôm qua';

  @override
  String durationMinutes(int count) {
    return '${count}m';
  }

  @override
  String durationHours(int count) {
    return '${count}h';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }
}
