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
  String get copyCommand => 'Sao chép lệnh';

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
  String get create => 'Tạo';

  @override
  String get otherSpaces => 'Không gian khác';

  @override
  String get folderUpdateFailed => 'Không thể cập nhật thư mục';

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

  @override
  String get mobileConversations => 'Cuộc trò chuyện';

  @override
  String get mobileNewConversation => 'Cuộc trò chuyện mới';

  @override
  String get mobileConversationName => 'Tên hội thoại';

  @override
  String get mobileRename => 'Đổi tên';

  @override
  String get mobileManageSpace => 'Quản lý không gian';

  @override
  String get mobileArchived => 'Đã lưu trữ';

  @override
  String get mobileSearchMessages =>
      'Tìm trong mọi tin nhắn của không gian này';

  @override
  String get mobileSearch => 'Tìm kiếm';

  @override
  String get mobileNoResults => 'Không có kết quả';

  @override
  String get mobileReopen => 'Mở lại';

  @override
  String get mobileArchive => 'Lưu trữ';

  @override
  String get mobileProgress => 'Tiến độ và ngữ cảnh';

  @override
  String get mobileReadFailed =>
      'Không thể đánh dấu cuộc trò chuyện này là đã đọc';

  @override
  String get mobileSendFailed =>
      'Chưa gửi được tin nhắn. Bản nháp của bạn vẫn còn đây.';

  @override
  String get sentAttachmentUnavailable => 'Tệp đính kèm không khả dụng';

  @override
  String get sentAttachmentLoadFailed => 'Không thể tải tệp đính kèm';

  @override
  String get mobileActionFailed => 'Thao tác thất bại';

  @override
  String get mobileRemove => 'Xóa';

  @override
  String get mobileLinkedMessage => 'Tin nhắn được liên kết';

  @override
  String get mobileOlderMessages => 'Tin nhắn cũ hơn';

  @override
  String get mobileMessageActions => 'Thao tác với tin nhắn';

  @override
  String get mobileOpenThread => 'Mở chuỗi';

  @override
  String get mobileCopyLink => 'Sao chép liên kết';

  @override
  String get mobileStopRun => 'Dừng chạy';

  @override
  String get mobileStopRunConfirm =>
      'Dừng lượt chạy của agent này? Công việc đã hoàn thành sẽ được giữ lại.';

  @override
  String get mobileControlUnsupported =>
      'Lượt chạy này đã kết thúc hoặc không hỗ trợ thao tác này.';

  @override
  String get mobilePauseRequested => 'Đã yêu cầu tạm dừng sau lượt tiếp theo';

  @override
  String get mobileResumed => 'Đã tiếp tục chạy';

  @override
  String get mobileStopRequested => 'Đã yêu cầu dừng';

  @override
  String get mobileQueuedMessages => 'Tin nhắn đang chờ';

  @override
  String get mobilePauseRun => 'Tạm dừng sau lượt tiếp theo';

  @override
  String get mobileResumeRun => 'Tiếp tục';

  @override
  String get mobileEditQueued => 'Sửa tin nhắn chờ';

  @override
  String get mobileSteerNow => 'Điều hướng ngay';

  @override
  String get mobileMoveUp => 'Chuyển lên';

  @override
  String get mobileMoveDown => 'Chuyển xuống';

  @override
  String get mobileQueueChanged =>
      'Hàng chờ đã thay đổi hoặc lượt chạy này không nhận điều hướng trực tiếp. Tải lại rồi thử lần nữa.';

  @override
  String get mobileActivity => 'Hoạt động';

  @override
  String get mobilePermissions => 'Quyền và nhật ký kiểm tra';

  @override
  String get mobilePlans => 'Kế hoạch';

  @override
  String get mobileGoals => 'Mục tiêu được giám sát';

  @override
  String get mobileCredentials => 'Kết nối và thông tin xác thực';

  @override
  String get mobileWorkspaceUnavailable =>
      'Không gian làm việc này không khả dụng hoặc bạn không còn quyền truy cập.';

  @override
  String get mobilePrReviewThreads => 'Luồng review';

  @override
  String get mobilePrThreadsLoadFailed => 'Không thể tải các chuỗi review';

  @override
  String get mobilePrNoReviewThreads => 'Chưa có chuỗi review theo dòng nào';

  @override
  String get mobilePrCommentPermissionDenied =>
      'Bạn không có quyền bình luận trong kho lưu trữ này.';

  @override
  String get mobilePrPermissionChecking => 'Đang kiểm tra quyền bình luận…';

  @override
  String get mobilePrPermissionLoadFailed =>
      'Không thể kiểm tra quyền bình luận. Thử lại để bình luận.';

  @override
  String mobilePrThreadLine(String side, String line) {
    return '$side dòng $line';
  }

  @override
  String get mobilePrOriginalSide => 'Bản gốc';

  @override
  String get mobilePrSelectCommentLine => 'Chọn một dòng để bình luận';

  @override
  String get mobilePrUpdatedSide => 'Cập nhật';

  @override
  String get mobilePrThreadResolved => 'Đã giải quyết';

  @override
  String get mobilePrReplyHint => 'Viết phản hồi…';

  @override
  String get mobilePrCommentRequired => 'Viết bình luận trước khi đăng.';

  @override
  String get mobilePrReply => 'Phản hồi';

  @override
  String get mobilePrReopenThread => 'Mở lại chuỗi';

  @override
  String get mobilePrResolveThread => 'Giải quyết chuỗi';

  @override
  String get mobilePrResolvePermissionDenied =>
      'Chỉ tác giả pull request hoặc người có quyền ghi mới có thể giải quyết chuỗi này.';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return 'Bình luận tại $side dòng $line';
  }

  @override
  String get mobilePrInlineCommentHint => 'Viết bình luận theo dòng…';

  @override
  String get mobilePrPostInlineComment => 'Đăng bình luận';

  @override
  String get mobilePrCommentUnavailable =>
      'Không thể bình luận theo dòng trong pull request này.';

  @override
  String get mobilePrPatchUnavailable =>
      'Forge không cung cấp bản vá văn bản cho tệp này.';

  @override
  String get mobilePrNoPatchForFile => 'Không có bản vá cho tệp này.';

  @override
  String get mobileTicketNew => 'Phiếu mới';

  @override
  String get mobileTicketCreate => 'Tạo phiếu';

  @override
  String get mobileTicketEdit => 'Sửa phiếu';

  @override
  String get mobileTicketTitle => 'Tiêu đề';

  @override
  String get mobileTicketTitleRequired => 'Nhập tiêu đề trước khi lưu phiếu.';

  @override
  String get mobileTicketDescription => 'Mô tả';

  @override
  String get mobileTicketMarkdownHint => 'Thêm chi tiết bằng Markdown';

  @override
  String get mobileTicketPriority => 'Độ ưu tiên';

  @override
  String get mobileTicketPriorityNone => 'Không ưu tiên';

  @override
  String get mobileTicketPriorityUrgent => 'Khẩn cấp';

  @override
  String get mobileTicketPriorityHigh => 'Cao';

  @override
  String get mobileTicketPriorityMedium => 'Trung bình';

  @override
  String get mobileTicketPriorityLow => 'Thấp';

  @override
  String get mobileTicketLabels => 'Nhãn';

  @override
  String get mobileTicketLabelsHint => 'Mỗi dòng một nhãn';

  @override
  String get mobileTicketLabelsHelp => 'Nhập mỗi nhãn trên một dòng riêng.';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return 'Được tạo trong $provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => 'Chưa gán';

  @override
  String get mobileTicketAssignedFilter => 'Đã gán';

  @override
  String get mobileTicketAgentsLoadFailed => 'Không thể tải agent';

  @override
  String get mobileTicketSearch => 'Tìm phiếu';

  @override
  String get mobileTicketSearchHint =>
      'Tiêu đề, mã, mô tả, nhãn hoặc người được gán';

  @override
  String get mobileTicketClearSearch => 'Xóa tìm kiếm phiếu';

  @override
  String get mobileTicketNoMatches => 'Không có phiếu phù hợp';

  @override
  String get mobileTicketAdjustFilters => 'Thử tìm kiếm khác hoặc đổi bộ lọc.';

  @override
  String get mobileTicketClearFilters => 'Xóa bộ lọc';

  @override
  String get mobileTicketNotFound => 'Không tìm thấy phiếu';

  @override
  String get mobileTicketNotFoundDescription =>
      'Phiếu này có thể đã bị xóa hoặc chuyển khỏi không gian làm việc này.';

  @override
  String get mobileTicketWorkspaceChanged =>
      'Không gian làm việc đã thay đổi. Quay lại không gian hiện tại trước khi lưu.';

  @override
  String get mobileTicketOpenLinkedSpace => 'Mở không gian được liên kết';

  @override
  String get mobileTicketReadOnly =>
      'Bạn cần có vai trò thành viên không gian làm việc để thay đổi phiếu.';

  @override
  String get permissionTitle => 'Quyền';

  @override
  String get permissionWorkspaceFailed => 'Không thể tải không gian làm việc';

  @override
  String get permissionNoWorkspace => 'Chọn không gian làm việc để xem quyền.';

  @override
  String get permissionLoading => 'Đang tải quyền…';

  @override
  String get permissionScopeDescription =>
      'Xem cách từng hành động được quyết định ở phạm vi này. Quy tắc của không gian làm việc có thể được kế thừa bởi agent và không gian.';

  @override
  String get permissionScope => 'Phạm vi chính sách';

  @override
  String get permissionWorkspaceScope => 'Không gian làm việc';

  @override
  String get permissionAgentScope => 'Agent';

  @override
  String get permissionSpaceScope => 'Space';

  @override
  String get permissionAgentContext =>
      'Agent đang hoạt động trong không gian này';

  @override
  String get permissionNoAgentContext => 'Chưa chọn agent';

  @override
  String get permissionTargetsFailed => 'Không thể tải đối tượng của phạm vi';

  @override
  String get permissionNoTargets => 'Không có đối tượng nào ở phạm vi này.';

  @override
  String get permissionRoleFailed =>
      'Không thể xác nhận vai trò của bạn trong không gian làm việc';

  @override
  String get permissionMemberRequired =>
      'Bạn cần có vai trò thành viên không gian làm việc để xem quy tắc chính sách.';

  @override
  String get permissionRulesFailed => 'Không thể tải quy tắc chính sách';

  @override
  String get permissionAuditAdminOnly =>
      'Chỉ quản trị viên không gian làm việc mới xem được lịch sử cấp quyền.';

  @override
  String get permissionAllow => 'Cho phép';

  @override
  String get permissionAsk => 'Hỏi trước';

  @override
  String get permissionDeny => 'Từ chối';

  @override
  String get permissionFileDelete => 'Xóa tệp';

  @override
  String get permissionFileWriteOutsideWorktree => 'Ghi ngoài cây làm việc';

  @override
  String get permissionGitCommit => 'Commit thay đổi';

  @override
  String get permissionGitPush => 'Push commit';

  @override
  String get permissionPrCreate => 'Tạo pull request';

  @override
  String get permissionPrPublish => 'Xuất bản pull request';

  @override
  String get permissionVendorSyncWrite => 'Ghi khi đồng bộ nhà cung cấp';

  @override
  String get permissionNetworkEgress => 'Truy cập mạng';

  @override
  String get permissionSecretAccess => 'Truy cập bí mật';

  @override
  String get permissionPackageInstall => 'Cài đặt gói';

  @override
  String get permissionProcessSpawn => 'Khởi chạy tiến trình';

  @override
  String get permissionWorkspaceMutation => 'Thay đổi không gian làm việc';

  @override
  String get permissionEnclosureControl => 'Điều khiển enclosure';

  @override
  String get permissionChangeFailed => 'Không thể thay đổi quy tắc';

  @override
  String get permissionEffectiveDescription =>
      'Có hiệu lực ở phạm vi này khi không có tham số hành động. Các quyền có điều kiện bên dưới chỉ áp dụng cho yêu cầu phù hợp; máy chủ đưa ra quyết định cuối cùng.';

  @override
  String get permissionSpaceAgentNote =>
      'Chưa chọn agent. Quy tắc riêng cho agent sẽ không hiển thị cho đến khi bạn chọn một agent ở trên.';

  @override
  String get permissionScopedGrants => 'Quy tắc tại phạm vi này';

  @override
  String get permissionModePreset => 'Preset chế độ';

  @override
  String get permissionBuiltInDefault => 'Mặc định tích hợp';

  @override
  String get permissionRemembered => 'Phê duyệt đã ghi nhớ';

  @override
  String get permissionSource => 'Mã nguồn';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · đặt tại đây';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · được kế thừa';
  }

  @override
  String permissionExpiresAt(String date) {
    return 'Hết hạn $date';
  }

  @override
  String get permissionSetHere => 'Đặt quy tắc tại đây';

  @override
  String get permissionRevokeBeforeEdit =>
      'Thu hồi quy tắc theo phạm vi hoặc quy tắc đã ghi nhớ trước khi đặt quy tắc chung cho hành động này.';

  @override
  String get permissionConfirmRevoke => 'Xác nhận thu hồi';

  @override
  String get permissionRevokeRule => 'Thu hồi quy tắc';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'Tiền tố lệnh: $prefix';
  }

  @override
  String get permissionNoExpiry => 'Không hết hạn';

  @override
  String get permissionExpired => 'Đã hết hạn';

  @override
  String get permissionExplicitRule => 'Quy tắc tường minh';

  @override
  String get permissionEnforcementAdvisory =>
      'Chế độ tư vấn: quy tắc hỏi trước được ghi lại mà không hỏi';

  @override
  String get permissionEnforcementSoft =>
      'Thực thi mềm: cần được cấp quyền để ghi đè';

  @override
  String get permissionEnforcementHard =>
      'Thực thi nghiêm ngặt: không thể ghi đè';

  @override
  String permissionPaths(String paths) {
    return 'Đường dẫn: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'Git refs: $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return 'Máy chủ: $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return 'Lệnh: $commands';
  }

  @override
  String permissionMaxCount(String count) {
    return 'Số lượng tối đa: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return 'Số cent tối đa: $cents';
  }

  @override
  String get permissionAuditHeading => 'Lịch sử cấp quyền';

  @override
  String get permissionAuditDescription =>
      'Các quyết định gần đây do máy chủ ghi lại. Chỉ quản trị viên mới có thể xem nhật ký hoặc xác minh chuỗi băm.';

  @override
  String permissionOnBehalfOf(String user) {
    return 'Thay mặt $user';
  }

  @override
  String get permissionPrompted => 'Đã yêu cầu phê duyệt thủ công';

  @override
  String get permissionVerifyChain => 'Xác minh chuỗi kiểm tra';

  @override
  String get permissionVerifyFailed => 'Không thể xác minh chuỗi kiểm tra';

  @override
  String permissionChainIntact(String count) {
    return 'Chuỗi nguyên vẹn · đã kiểm tra $count mục';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'Chuỗi bị đứt tại mục $sequence: $reason';
  }

  @override
  String get permissionAuditEmpty => 'Chưa ghi nhận quyết định cấp quyền nào.';

  @override
  String get permissionAuditFailed => 'Không thể tải lịch sử cấp quyền';

  @override
  String get mobilePlansLoadFailed => 'Không thể tải kế hoạch';

  @override
  String get mobilePlansEmpty => 'Chưa có kế hoạch';

  @override
  String get mobilePlansEmptyDescription =>
      'Kế hoạch do agent gửi sẽ xuất hiện ở đây để bạn xem xét.';

  @override
  String get mobilePlanTitle => 'Kế hoạch';

  @override
  String get mobilePlanMissing =>
      'Kế hoạch này không còn trong không gian làm việc này.';

  @override
  String mobilePlanStepCount(int count) {
    return '$count bước';
  }

  @override
  String get mobilePlanDraft => 'Bản nháp';

  @override
  String get mobilePlanProposed => 'Đang chờ xem xét';

  @override
  String get mobilePlanApproved => 'Đã duyệt';

  @override
  String get mobilePlanRejected => 'Đã từ chối';

  @override
  String get mobilePlanSuperseded => 'Đã thay thế';

  @override
  String get mobilePlanExecuting => 'Đang thực thi';

  @override
  String get mobilePlanSynthesizing => 'Đang tổng hợp';

  @override
  String get mobilePlanCompleted => 'Hoàn tất';

  @override
  String get mobilePlanFailed => 'Thất bại';

  @override
  String get mobilePlanCancelled => 'Đã hủy';

  @override
  String mobilePlanRevision(String revision) {
    return 'Phiên bản $revision';
  }

  @override
  String get mobilePlanSteps => 'Các bước';

  @override
  String get mobilePlanNoSteps => 'Chưa có bước nào được gửi cho kế hoạch này.';

  @override
  String get mobilePlanAssumptions => 'Thông tin cần làm rõ';

  @override
  String mobilePlanDependsOn(String keys) {
    return 'Phụ thuộc vào $keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return 'Ước tính tối đa $cost';
  }

  @override
  String get mobilePlanSelect => 'Chọn';

  @override
  String get mobilePlanSelected => 'Đã chọn';

  @override
  String get mobilePlanEstimate => 'Ước tính chi phí';

  @override
  String get mobilePlanEstimateRequired =>
      'Ước tính chi phí kế hoạch trước khi duyệt thực thi.';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return 'Chi phí ước tính: $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => 'Không có thông tin';

  @override
  String get mobilePlanNoHardCap => 'Không giới hạn cứng';

  @override
  String get mobilePlanExceedsBudget =>
      'Chi phí ước tính vượt ngân sách đã đặt. Xem lại trước khi duyệt.';

  @override
  String get mobilePlanPartialEstimate =>
      'Ước tính này áp dụng cho toàn bộ kế hoạch; các bước được chọn có thể tốn ít hơn.';

  @override
  String get mobilePlanConfirmAll => 'Bắt đầu toàn bộ kế hoạch?';

  @override
  String get mobilePlanConfirmSelected => 'Bắt đầu các bước đã chọn?';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return 'Phê duyệt sẽ bắt đầu thực thi và có thể phát sinh phí. Chi phí ước tính cao nhất: $cost. Giới hạn ngân sách: $cap.';
  }

  @override
  String get mobilePlanApproveAll => 'Duyệt tất cả và chạy';

  @override
  String get mobilePlanApproveSelected => 'Duyệt các bước đã chọn và chạy';

  @override
  String get mobilePlanWiden => 'Duyệt thêm bước';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return 'Cho phép thực thi thêm $count bước? Việc này có thể phát sinh phí. Giới hạn chi phí hiện tại: $cap.';
  }

  @override
  String get mobilePlanChanged =>
      'Kế hoạch đã thay đổi trong lúc xem xét. Mở phiên bản mới nhất và ước tính lại.';

  @override
  String get mobilePlanReject => 'Từ chối kế hoạch';

  @override
  String get mobilePlanRejectConfirm =>
      'Từ chối kế hoạch này? Kế hoạch sẽ không được thực thi.';

  @override
  String get mobilePlanStop => 'Dừng thực thi';

  @override
  String get mobilePlanStopConfirm =>
      'Dừng thực thi kế hoạch này? Công việc đã hoàn thành sẽ không bị hoàn tác.';

  @override
  String mobilePlanRunId(String runId) {
    return 'Lượt chạy thực thi: $runId';
  }

  @override
  String get mobilePlanExecutionPending =>
      'Đã chấp nhận phê duyệt. Đang chờ bản ghi thực thi…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return 'Đã hoàn thành $completed / $total bước thực thi';
  }

  @override
  String get mobilePlanOpenConversation => 'Mở cuộc trò chuyện';

  @override
  String get mobileGoalsTitle => 'Mục tiêu được giám sát';

  @override
  String get mobileGoalsLoadFailed => 'Không thể tải mục tiêu được giám sát';

  @override
  String get mobileGoalsEmpty => 'Chưa có mục tiêu được giám sát';

  @override
  String get mobileGoalsEmptyDescription =>
      'Bắt đầu một mục tiêu trong không gian hoặc gửi /goal trong cuộc trò chuyện.';

  @override
  String get mobileGoalMissing =>
      'Mục tiêu này không còn trong không gian làm việc này.';

  @override
  String get mobileGoalActive => 'Đang dùng';

  @override
  String get mobileGoalPaused => 'Tạm dừng';

  @override
  String get mobileGoalCompleted => 'Hoàn tất';

  @override
  String get mobileGoalFailed => 'Thất bại';

  @override
  String get mobileGoalCancelled => 'Đã hủy';

  @override
  String get mobileGoalBudgetExhausted => 'Đã chạm giới hạn ngân sách';

  @override
  String get mobileGoalGoal => 'Mục tiêu';

  @override
  String get mobileGoalLoop => 'Vòng lặp';

  @override
  String mobileGoalKind(String kind) {
    return 'Loại: $kind';
  }

  @override
  String mobileGoalRuns(String count) {
    return '$count lượt chạy';
  }

  @override
  String get mobileGoalNoRunLimit => 'Không giới hạn';

  @override
  String mobileGoalProgress(
    String runs,
    String maxRuns,
    String spent,
    String cap,
  ) {
    return 'Lượt chạy: $runs / $maxRuns · Đã chi: $spent / $cap';
  }

  @override
  String mobileGoalDeadline(String date) {
    return 'Hạn chót: $date';
  }

  @override
  String mobileGoalFailures(String count) {
    return 'Số lượt chạy thất bại liên tiếp: $count';
  }

  @override
  String get mobileGoalSummary => 'Tóm tắt kết quả';

  @override
  String get mobileGoalFailedDescription =>
      'Bộ giám sát đã dừng sau nhiều lượt chạy thất bại. Xem cuộc trò chuyện để biết chi tiết.';

  @override
  String get mobileGoalBudgetWall =>
      'Đã đến hạn chót hoặc chạm giới hạn lượt chạy. Không thể tiếp tục mục tiêu này bằng cách tăng giới hạn chi phí.';

  @override
  String get mobileGoalPause => 'Tạm dừng mục tiêu';

  @override
  String get mobileGoalResume => 'Tiếp tục mục tiêu';

  @override
  String get mobileGoalStop => 'Hủy mục tiêu';

  @override
  String get mobileGoalStopConfirm =>
      'Hủy vĩnh viễn mục tiêu được giám sát này? Không thể tiếp tục sau khi hủy.';

  @override
  String get mobileGoalRaiseBudget => 'Tăng ngân sách và tiếp tục';

  @override
  String mobileGoalRaiseTo(String amount) {
    return 'Tăng ngân sách lên $amount và tiếp tục';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return 'Tăng giới hạn chi phí của mục tiêu này từ $oldCap lên $newCap và tiếp tục chi tiêu?';
  }

  @override
  String get mobileGoalOpenConversation => 'Mở cuộc trò chuyện của mục tiêu';

  @override
  String get mobileGoalCreate => 'Bắt đầu mục tiêu được giám sát';

  @override
  String get mobileGoalChooseSpace => 'Chạy trong không gian';

  @override
  String get mobileGoalNoSpaces =>
      'Tạo một không gian trước khi bắt đầu mục tiêu.';

  @override
  String get mobileGoalChooseAgent => 'Chạy với agent';

  @override
  String get mobileGoalNoAgents =>
      'Thêm agent đang hoạt động trước khi bắt đầu mục tiêu.';

  @override
  String mobileGoalSelectedAgent(String name) {
    return 'Đã chọn $name';
  }

  @override
  String get mobileGoalObjectiveHint => 'Bạn muốn agent đạt được kết quả gì?';

  @override
  String get mobileGoalBudgetUsd => 'Giới hạn chi phí (USD)';

  @override
  String get mobileGoalCreateInvalid =>
      'Chọn không gian và agent, nhập mục tiêu rồi đặt giới hạn chi phí dương bằng USD.';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return 'Bắt đầu mục tiêu được giám sát với chi phí tối đa $cap? Agent có thể bắt đầu ngay.';
  }

  @override
  String get mobileGoalUnavailable =>
      'Chưa sẵn sàng kết nối với máy chủ. Thử lại sau khi kết nối lại.';

  @override
  String get mobileGoalConversationMissing =>
      'Cuộc trò chuyện đã chọn không còn trong không gian làm việc này.';

  @override
  String get mobileGoalCreateSent =>
      'Đã bắt đầu mục tiêu. Trạng thái giám sát sẽ xuất hiện trong danh sách này.';

  @override
  String get mobileGoalStartRefused =>
      'Chưa có lượt chạy mục tiêu nào bắt đầu. Xem cuộc trò chuyện để biết lý do của bộ giám sát.';

  @override
  String mobileGoalSelectedSpace(String name) {
    return 'Đã chọn $name';
  }

  @override
  String get requestUnavailable =>
      'Yêu cầu này không còn trong không gian làm việc hiện tại.';

  @override
  String get requestAlreadyResolved => 'Yêu cầu này đã được giải quyết.';

  @override
  String get inboxCredentialsBlocked =>
      'Thông tin xác thực đang chặn lượt chạy';

  @override
  String get inboxSyncFailures => 'Các lần đồng bộ nhà cung cấp thất bại';

  @override
  String get inboxConfigureCredentials => 'Thiết lập thông tin xác thực';

  @override
  String get openTicket => 'Mở phiếu';

  @override
  String get activityTitle => 'Hoạt động';

  @override
  String get activityClearAll => 'Xóa hoạt động';

  @override
  String get activityClearConfirm =>
      'Thao tác này ẩn mọi hoạt động đã ghi cho bạn đến nay trên tất cả thiết bị. Hoạt động mới vẫn sẽ xuất hiện.';

  @override
  String get activityMarkAllRead => 'Đánh dấu tất cả đã đọc';

  @override
  String get activityMarkAllConfirm =>
      'Đánh dấu mọi mục hoạt động trong không gian làm việc này là đã đọc trên tất cả thiết bị của bạn?';

  @override
  String get activityMarkRead => 'Đánh dấu đã đọc';

  @override
  String get activityMarkUnread => 'Đánh dấu chưa đọc';

  @override
  String get activityDismiss => 'Bỏ qua';

  @override
  String get activityResolved => 'Đã giải quyết';

  @override
  String get activityOpen => 'Mở';

  @override
  String get activityEmpty => 'Chưa có hoạt động';

  @override
  String get activityLoadFailed => 'Không thể tải hoạt động';

  @override
  String get activityAgentWaiting => 'Agent cần bạn phản hồi';

  @override
  String get activityAgentBlocked => 'Hành động của agent bị chặn';

  @override
  String get activityMessage => 'Tin nhắn mới';

  @override
  String get activityPullRequest => 'Cập nhật pull request';

  @override
  String get activityTicket => 'Cập nhật phiếu';

  @override
  String get activityMeeting => 'Cập nhật cuộc họp';

  @override
  String get activityCalendar => 'Kết nối lịch';

  @override
  String get activityRig => 'Cập nhật enclosure';

  @override
  String get activityEvent => 'Cập nhật';

  @override
  String get activityPrReady => 'Pull request sẵn sàng merge';

  @override
  String get activityPrBlocked => 'Pull request bị chặn merge';

  @override
  String get activityPrApproved => 'Pull request đã được phê duyệt';

  @override
  String get activityPrChanges => 'Yêu cầu thay đổi';

  @override
  String get activityPrChecksFailed => 'Kiểm tra pull request thất bại';

  @override
  String get activityPrChecksRecovered =>
      'Kiểm tra pull request đã hoạt động lại';

  @override
  String get activityPrComment => 'Bình luận trong pull request';

  @override
  String get activityPrPublished => 'Pull request đã xuất bản';

  @override
  String get activityPrMerged => 'Đã merge pull request';

  @override
  String get activityPrMentioned => 'Được nhắc đến trong pull request';

  @override
  String get activityPrReviewRequested => 'Yêu cầu review';

  @override
  String get activityPrReviewStale => 'Cần cập nhật review';

  @override
  String get activityTicketAssigned => 'Phiếu được gán';

  @override
  String get activityTicketChanged => 'Trạng thái phiếu đã đổi';

  @override
  String get activityMeetingSoon => 'Cuộc họp sắp bắt đầu';

  @override
  String get activityCalendarExpired => 'Kết nối lịch đã hết hạn';

  @override
  String get activityRigControl => 'Quyền điều khiển enclosure đã thay đổi';

  @override
  String get activityRigClosed => 'Enclosure đã dừng';

  @override
  String get mobileSpacesSearch => 'Tìm không gian';

  @override
  String get mobileSpacesArchived => 'Đã lưu trữ';

  @override
  String get mobileSpacesActive => 'Đang dùng';

  @override
  String get mobileSpacesNew => 'Không gian mới';

  @override
  String get mobileSpacesManage => 'Quản lý không gian';

  @override
  String get mobileSpacesName => 'Tên không gian';

  @override
  String get mobileSpacesAgents => 'Agent';

  @override
  String get mobileSpacesMembers => 'Mọi người';

  @override
  String get mobileSpacesRepos => 'Kho lưu trữ';

  @override
  String get mobileSpacesAllRepos => 'Tất cả kho lưu trữ được liên kết';

  @override
  String get mobileSpacesNoRepos => 'Không có kho lưu trữ';

  @override
  String get mobileSpacesBaseBranch => 'Nhánh gốc (không bắt buộc)';

  @override
  String get mobileSpacesDefaultBranch => 'Nhánh mặc định';

  @override
  String get mobileSpacesMode => 'Chế độ';

  @override
  String get mobileSpacesModeChat => 'Trò chuyện';

  @override
  String get mobileSpacesModeReview => 'Review (chỉ đọc)';

  @override
  String get mobileSpacesModePlan => 'Lập kế hoạch (chỉ đọc)';

  @override
  String get mobileSpacesModeOrchestrate => 'Điều phối';

  @override
  String get mobileSpacesAutonomy => 'Ghi đè quyền tự chủ';

  @override
  String get mobileSpacesAutonomyInherited => 'Kế thừa';

  @override
  String get mobileSpacesAutonomyPropose => 'Chỉ đề xuất';

  @override
  String get mobileSpacesAutonomyApproval => 'Hành động khi được duyệt';

  @override
  String get mobileSpacesAutonomyFreely => 'Hành động tự do';

  @override
  String get mobileSpacesAutonomyNotice =>
      'Quyền ghi đè không thể bỏ qua yêu cầu phê duyệt hoặc từ chối của chính sách hành động. Chỉ quản trị viên không gian làm việc mới có thể thay đổi.';

  @override
  String get mobileSpacesArchive => 'Lưu trữ không gian';

  @override
  String get mobileSpacesReopen => 'Mở lại không gian';

  @override
  String get mobileSpacesSave => 'Lưu thay đổi';

  @override
  String get mobileSpacesCreate => 'Tạo không gian';

  @override
  String get mobileSpacesOperationFailed => 'Không thể cập nhật không gian';

  @override
  String get mobileSpacesMissing =>
      'Không tìm thấy không gian trong không gian làm việc này';

  @override
  String get mobileSpacesEmptyName => 'Nhập tên không gian';

  @override
  String get mobileSpacesNoMatches => 'Không có không gian phù hợp';

  @override
  String get mobileSpacesUnread => 'Phản hồi chưa đọc của agent';

  @override
  String get mobileSpacesNeedsInput => 'Cần bạn phản hồi';

  @override
  String get mobileSpacesRunning => 'Agent đang chạy';

  @override
  String get mobileSpacesNoAgents =>
      'Không có agent trong không gian làm việc này';

  @override
  String get mobileSpacesNoMembers =>
      'Không có thành viên nào khác trong không gian làm việc';

  @override
  String get mobileSpacesRepoError => 'Không thể tải kho lưu trữ';

  @override
  String get mobileSpacesRetry => 'Thử lại';

  @override
  String get mobileSpacesBranchUnavailable =>
      'Chọn hoặc nhập nhánh gốc khi tạo không gian; không thể đổi nhánh gốc của không gian đã có.';

  @override
  String get mobileSpacesArchivedEmpty => 'Không có không gian đã lưu trữ';

  @override
  String get mobileSpacesAllRepoWarning =>
      'Các kho lưu trữ mới liên kết với không gian làm việc cũng sẽ được thêm vào không gian này.';

  @override
  String get mobileSpacesCreatedRetry =>
      'Đã tạo không gian. Thử thêm người lần nữa hoặc mở trang quản lý của không gian.';

  @override
  String get progressTitle => 'Tiến độ';

  @override
  String get progressConversation => 'Hội thoại';

  @override
  String get progressLoadFailed => 'Không thể tải tiến độ';

  @override
  String get progressUnavailable => 'Cuộc trò chuyện không khả dụng';

  @override
  String get progressUnavailableDescription =>
      'Cuộc trò chuyện này không nằm trong không gian làm việc và không gian hiện tại. Quay lại không gian của cuộc trò chuyện để tiếp tục.';

  @override
  String get progressSaveFailed => 'Không thể cập nhật tiến độ';

  @override
  String get progressGoal => 'Mục tiêu';

  @override
  String get progressNoGoal => 'Chưa đặt mục tiêu công việc';

  @override
  String get progressSetGoal => 'Đặt mục tiêu';

  @override
  String get progressEditGoal => 'Sửa mục tiêu';

  @override
  String get progressClearGoal => 'Xóa mục tiêu';

  @override
  String get progressGoalRequired => 'Nhập mục tiêu trước khi lưu.';

  @override
  String get progressTodos => 'Công việc';

  @override
  String get transcriptToolTodos => 'Công việc';

  @override
  String get transcriptToolSearchMemory => 'Tìm trong bộ nhớ';

  @override
  String get transcriptToolRenderMedia => 'Hiển thị nội dung đa phương tiện';

  @override
  String get progressNoTodos => 'Chưa có công việc';

  @override
  String get progressNewTodo => 'Công việc mới';

  @override
  String get progressAddTodo => 'Thêm công việc';

  @override
  String get progressEditTodo => 'Sửa công việc';

  @override
  String get progressTodoRequired => 'Nhập công việc trước khi lưu.';

  @override
  String get progressTodoNoLongerExists =>
      'Công việc đó đã bị xóa. Tải lại danh sách rồi thử lần nữa.';

  @override
  String get progressWorkspaceChanged =>
      'Không gian làm việc hiện tại đã thay đổi. Quay lại cuộc trò chuyện này rồi thử lần nữa.';

  @override
  String progressRemoveTodo(String name) {
    return 'Xóa công việc $name';
  }

  @override
  String get progressPending => 'Đang chờ';

  @override
  String get progressInProgress => 'Đang thực hiện';

  @override
  String get progressCompleted => 'Hoàn tất';

  @override
  String get progressMoveUp => 'Chuyển công việc lên';

  @override
  String get progressMoveDown => 'Chuyển công việc xuống';

  @override
  String get progressRunTree => 'Các lượt chạy của agent';

  @override
  String get progressNoRuns =>
      'Chưa có lượt chạy nào trong cuộc trò chuyện này';

  @override
  String get progressRunning => 'Đang chạy';

  @override
  String get progressFailed => 'Thất bại';

  @override
  String get progressUnknown => 'Không xác định';

  @override
  String get progressHealthy => 'Đang dùng';

  @override
  String get progressBlocked => 'Bị chặn';

  @override
  String get progressLooping => 'Đang lặp';

  @override
  String get progressStalled => 'Bị đình trệ';

  @override
  String get progressDead => 'Dừng đột ngột';

  @override
  String get progressQuiet => 'Chưa có đầu ra';

  @override
  String get progressCostReported => 'Phí do nhà cung cấp báo cáo';

  @override
  String get progressCostNotional =>
      'Giá niêm yết giả định của gói đăng ký; không phải hóa đơn';

  @override
  String get progressCostMixed => 'Chi phí từ nhiều nguồn';

  @override
  String get progressCostEstimated => 'Chi phí ước tính';

  @override
  String progressDurationSeconds(String seconds) {
    return '${seconds}s';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'Mô hình: $model · Thời gian: $duration · Chi phí: $cost';
  }

  @override
  String progressStartedAt(String time) {
    return 'Bắt đầu $time';
  }

  @override
  String progressLiveness(String state) {
    return 'Trạng thái: $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return 'Đầu vào: $input · Đầu ra: $output token';
  }

  @override
  String get progressOutputPreviewLimited =>
      'Chỉ hiển thị 6.000 ký tự đầu của đầu ra có cấu trúc.';

  @override
  String progressRetryOf(String runId) {
    return 'Thử lại lượt chạy $runId';
  }

  @override
  String get progressContext => 'Ngữ cảnh và giới hạn';

  @override
  String get progressNoAgent => 'Không có agent để xem';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window token';
  }

  @override
  String get progressMeasured =>
      'Ngữ cảnh do nhà cung cấp báo cáo ở lần gọi gần nhất';

  @override
  String get progressEstimated =>
      'Ước tính từ cuộc trò chuyện đã lưu và ngữ cảnh liên tục';

  @override
  String get progressContextUnknown =>
      'Chưa có báo cáo về mức sử dụng ngữ cảnh';

  @override
  String progressContextPercent(String percent) {
    return '$percent% cửa sổ ngữ cảnh';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return 'Giới hạn agent hằng tháng đã đặt: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return 'Cuộc trò chuyện hiện hành đã lưu: khoảng $tokens token';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return 'Ngữ cảnh liên tục cho $agent · $model';
  }

  @override
  String get progressContextSystem => 'Prompt hệ thống';

  @override
  String get progressContextRules => 'Quy tắc';

  @override
  String get progressContextSkills => 'Kỹ năng';

  @override
  String get progressContextTools => 'Định nghĩa công cụ';

  @override
  String get progressContextMcp => 'Công cụ MCP';

  @override
  String get progressContextDeferred => 'Công cụ tải sau';

  @override
  String get progressContextSubagents => 'Subagent';

  @override
  String get progressContextRunner => 'Trình chạy bên ngoài';

  @override
  String get progressContextMemory => 'Bộ nhớ';

  @override
  String get progressContextHistory => 'Lịch sử trò chuyện';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens token';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens token';
  }

  @override
  String get progressOutputs => 'Đầu ra gần đây';

  @override
  String get progressNoOutputs => 'Không có đầu ra gần đây của agent';

  @override
  String get progressStructuredOutputsAbove =>
      'Đầu ra có cấu trúc của lượt chạy được hiển thị trong phần lượt chạy agent ở trên.';

  @override
  String get progressRecentOutputsOnly =>
      'Chỉ hiển thị tin nhắn gần đây. Mở cuộc trò chuyện để xem công việc cũ hơn.';

  @override
  String get progressPlan => 'Kế hoạch';

  @override
  String get progressArtifact => 'Tạo tác';

  @override
  String get progressResult => 'Kết quả';

  @override
  String get progressHideArtifact => 'Ẩn tạo tác';

  @override
  String get progressReadArtifact => 'Đọc tạo tác';

  @override
  String get progressArtifactUnavailable => 'Tạo tác không còn khả dụng';

  @override
  String get progressArtifactPreviewLimited =>
      'Đang hiển thị bản xem trước rút gọn của tạo tác này.';

  @override
  String get progressDiagramSource => 'Nguồn sơ đồ';

  @override
  String progressOpenAttachment(String name) {
    return 'Mở $name';
  }

  @override
  String get progressOpenPlan => 'Mở kế hoạch';

  @override
  String progressOpenDiff(String label) {
    return 'Xem các tệp đã thay đổi: $label';
  }

  @override
  String get progressViewMessage => 'Xem tin nhắn';

  @override
  String get pushTitle => 'Thông báo nền';

  @override
  String get pushIntro =>
      'Nhận cảnh báo riêng khi có điều cần chú ý, kể cả khi ứng dụng đã đóng. Chi tiết chỉ nằm trong kết nối được mã hóa của bạn.';

  @override
  String get pushLoading => 'Đang kiểm tra cài đặt thông báo…';

  @override
  String get pushError =>
      'Không thể cập nhật thông báo. Kiểm tra kết nối rồi thử lại.';

  @override
  String get pushEnable => 'Bật thông báo';

  @override
  String get pushDisable => 'Tắt thông báo';

  @override
  String get pushQuiet => 'Tạm dừng cảnh báo trên thiết bị này';

  @override
  String get pushCategories => 'Thông báo cho tôi về';

  @override
  String get pushCategoryAgents => 'Agent';

  @override
  String get pushCategoryMessages => 'Tin nhắn';

  @override
  String get pushCategoryPullRequests => 'Pull request';

  @override
  String get pushCategoryTickets => 'Phiếu';

  @override
  String get pushCategoryCalendar => 'Lịch';

  @override
  String get pushCategoryMachines => 'Máy';

  @override
  String get pushSecureOrigin => 'Thông báo yêu cầu HTTPS.';

  @override
  String get pushInstallIos =>
      'Trên iPhone hoặc iPad, hãy thêm ứng dụng này vào Màn hình chính và mở từ đó để bật thông báo.';

  @override
  String get pushUnsupported => 'Trình duyệt này không hỗ trợ thông báo nền.';

  @override
  String get pushDenied =>
      'Trình duyệt báo thông báo đang bị chặn. Kiểm tra quyền của trang này và cài đặt thông báo của trình duyệt hoặc thiết bị, rồi làm mới trang.';

  @override
  String get pushOsHint =>
      'Trình duyệt của bạn cũng cần được cấp quyền hiển thị thông báo trong cài đặt hệ thống của thiết bị.';

  @override
  String get pushServiceUnavailable =>
      'Dịch vụ đẩy của trình duyệt đã từ chối đăng ký. Một số trình duyệt, như Brave, tắt dịch vụ này theo mặc định: hãy tìm tùy chọn tin nhắn đẩy trong cài đặt quyền riêng tư của trình duyệt rồi thử lại.';

  @override
  String get pushWorkerUnavailable =>
      'Không thể khởi động dịch vụ thông báo trong trình duyệt này. Hãy tải lại trang và thử lại.';

  @override
  String get pushResubscribe => 'Kết nối lại thông báo';

  @override
  String get pushStatusEnabled => 'Thông báo đang bật trên thiết bị này.';

  @override
  String get pushStatusDisabled => 'Thông báo đang tắt trên thiết bị này.';

  @override
  String get credentialsTitle => 'Kết nối và thông tin xác thực';

  @override
  String get credentialsIntro =>
      'Kết nối các tài khoản mà lượt chạy và phần tích hợp của bạn sử dụng. Thông tin bí mật được lưu trên máy chủ, không phải trên điện thoại này.';

  @override
  String get credentialsModelProviders => 'Nhà cung cấp mô hình';

  @override
  String get credentialsOwnerOnly =>
      'Chỉ chủ máy chủ mới có thể thêm, đăng nhập hoặc xóa thông tin xác thực của nhà cung cấp mô hình. Các khóa này được dùng chung giữa các không gian làm việc.';

  @override
  String get credentialsContactOwner =>
      'Hãy nhờ chủ máy chủ kết nối nhà cung cấp mà lượt chạy đang bị chặn của bạn cần.';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'Claude Code đăng nhập qua CLI trên máy chủ. Hãy nhờ chủ máy chủ hoàn tất hoặc gia hạn đăng nhập tài khoản trong terminal của máy chủ; điện thoại này không thể làm việc đó.';

  @override
  String get credentialsYourForgeAccounts => 'Tài khoản forge của bạn';

  @override
  String get credentialsYourTicketingAccount =>
      'Tài khoản quản lý phiếu của bạn';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'Phiếu nội bộ không cần đăng nhập. Kết nối Linear tại đây nếu không gian làm việc của bạn dùng Linear.';

  @override
  String get credentialsMembershipRequired =>
      'Tham gia một không gian làm việc để quản lý thông tin xác thực forge hoặc quản lý phiếu. Hãy hỏi quản trị viên không gian làm việc để được cấp quyền.';

  @override
  String get credentialsSwitchWorkspace =>
      'Liên kết này trỏ đến không gian làm việc khác. Chuyển sang đó trước khi thay đổi thông tin xác thực.';

  @override
  String get credentialsReturnToInbox =>
      'Quay lại Hộp thư đến để thử lại lượt chạy bị chặn sau khi kết nối thông tin xác thực. Máy chủ cũng tự động kiểm tra các lượt chạy đang tạm chờ.';

  @override
  String get credentialsLoadFailed =>
      'Không thể tải các kết nối. Kiểm tra liên kết với máy chủ rồi thử lại.';

  @override
  String get credentialsOperationFailed =>
      'Không thể thay đổi kết nối này. Kiểm tra liên kết với máy chủ, quyền truy cập và thông tin xác thực, rồi thử lại.';

  @override
  String get credentialsConnected => 'Đã kết nối';

  @override
  String get credentialsNotConnected => 'Chưa kết nối';

  @override
  String credentialsSignedInAs(String username) {
    return 'Đã đăng nhập với tên $username';
  }

  @override
  String get credentialsAccount => 'Tài khoản đã kết nối';

  @override
  String get credentialsStoredKey => 'Khóa đã lưu';

  @override
  String get credentialsActive => 'Đang dùng';

  @override
  String get credentialsRemove => 'Xóa';

  @override
  String get credentialsRemoveConfirm =>
      'Xóa thông tin xác thực đã lưu? Bạn có thể cần đăng nhập lại.';

  @override
  String get credentialsApiKey => 'Khóa API';

  @override
  String get credentialsApiKeyHint => 'Dán khóa API của nhà cung cấp';

  @override
  String get credentialsBrowserLogin => 'Đăng nhập bằng trình duyệt';

  @override
  String get credentialsSignInAgain => 'Đăng nhập lại';

  @override
  String get credentialsWaitingForLogin =>
      'Đang chờ bạn cấp quyền trong trình duyệt…';

  @override
  String get credentialsLoginTimedOut =>
      'Phiên đăng nhập đã hết hạn. Bắt đầu đăng nhập lại.';

  @override
  String get credentialsCopyCode => 'Sao chép mã';

  @override
  String get credentialsDeviceCodeHint =>
      'Xác nhận mã này trên trang của nhà cung cấp. Giữ màn hình này mở trong khi máy chủ hoàn tất đăng nhập.';

  @override
  String get credentialsPasteRedirect => 'Mã ủy quyền hoặc URL chuyển hướng';

  @override
  String get credentialsPasteRedirectHint =>
      'Dán mã hoặc URL chuyển hướng đầy đủ từ nhà cung cấp';

  @override
  String get credentialsCompleteLogin => 'Hoàn tất đăng nhập';

  @override
  String get credentialsRedirectUnavailable =>
      'Điện thoại không thể kết nối an toàn đến địa chỉ callback trình duyệt của máy chủ này. Hãy nhờ chủ máy chủ thiết lập callback HTTPS công khai hoặc thêm token thay thế.';

  @override
  String get credentialsUpdateToken => 'Cập nhật token';

  @override
  String get credentialsAddToken => 'Thêm token';

  @override
  String get credentialsPersonalToken => 'Token truy cập cá nhân';

  @override
  String get credentialsPersonalTokenHint => 'Dán token truy cập cá nhân';

  @override
  String get credentialsHostManaged =>
      'Kết nối này đến từ ứng dụng máy chủ hoặc môi trường. Chỉ chủ máy chủ mới có thể thay đổi ở đó; bạn vẫn có thể thêm token của riêng mình.';

  @override
  String get credentialsStopWatching => 'Ngừng theo dõi';

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
}
