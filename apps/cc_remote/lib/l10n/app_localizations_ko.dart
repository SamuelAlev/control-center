// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => '뒤로';

  @override
  String get cancel => '취소';

  @override
  String get retry => '재시도';

  @override
  String get tryAgain => '다시 시도';

  @override
  String get settings => '설정';

  @override
  String get refresh => '새로 고침';

  @override
  String get approve => '승인';

  @override
  String get deny => '거부';

  @override
  String get continueLabel => '계속';

  @override
  String get agentQuestionHeader => '질문이 있습니다';

  @override
  String get agentQuestionAnsweredLabel => '답변 완료';

  @override
  String get agentQuestionSkip => '건너뛰기';

  @override
  String get agentQuestionSkippedLabel => '건너뜀';

  @override
  String get agentQuestionFreeformHint => '답변을 입력하세요…';

  @override
  String get agentApprovalRequired => '승인이 필요합니다';

  @override
  String get approveAndRemember => '8시간 동안 승인';

  @override
  String get decline => '거절';

  @override
  String get confirm => '확인';

  @override
  String get send => '보내기';

  @override
  String get close => '닫기';

  @override
  String get expand => '펼치기';

  @override
  String get zoomIn => '확대';

  @override
  String get zoomOut => '축소';

  @override
  String get resetZoom => '줌 재설정';

  @override
  String get scanQrPrompt => 'Control Center의 QR 코드를 스캔해 이 폰을 페어링하세요.';

  @override
  String get scanQrHelp =>
      '카메라를 열어 Control Center에 표시된 QR을 비추세요. 이 폰은 비공개 링크로 직접 연결됩니다.';

  @override
  String get connectingToMac => 'Control Center에 연결하는 중…';

  @override
  String get connectingDetail => '보안 직접 연결을 설정하는 중입니다.';

  @override
  String get identityChangedTitle => '서버 ID가 변경됨';

  @override
  String get identityChangedBody =>
      '이 서버는 페어링 당시 저장된 ID와 더 이상 일치하지 않습니다. 서버가 재설치되었거나 연결이 가로채졌을 수 있습니다. 안전을 위해 이 기기는 연결하지 않습니다. 페어링을 삭제한 뒤 Control Center에서 새 QR 코드를 스캔해 다시 페어링하세요.';

  @override
  String get removePairing => '페어링 삭제';

  @override
  String get couldntConnect => '연결할 수 없음';

  @override
  String get pendingPairingTitle => '이 서버에 연결할까요?';

  @override
  String get pendingPairingBody =>
      '링크가 Control Center에 이 서버와의 페어링을 요청했습니다. 직접 시작한 경우에만 계속하세요.';

  @override
  String get connect => '연결';

  @override
  String get failureNotPaired => '페어링되지 않음 — Control Center의 QR 코드를 스캔하세요';

  @override
  String get failureUnreachable =>
      '어떤 경로로도 서버에 도달하지 못함 — 실행 중인지 확인하거나 같은 네트워크에서 시도하세요';

  @override
  String get failureIdentityChanged => '서버 ID가 변경됨 — 재설치했다면 이 기기를 다시 페어링하세요';

  @override
  String get failureAuthRejected =>
      '서버가 이 기기를 거부함 — Control Center에서 다시 페어링하세요';

  @override
  String get failureUnknown => '연결할 수 없음 — 눌러서 다시 시도';

  @override
  String get statusConnected => '연결됨';

  @override
  String get statusConnecting => '연결 중';

  @override
  String get statusOffline => '오프라인';

  @override
  String get statusIdentityMismatch => 'ID 불일치';

  @override
  String get statusNotPaired => '페어링되지 않음';

  @override
  String get statusConfirmPairing => '페어링 확인';

  @override
  String get connectionFailed => '연결 실패';

  @override
  String get identityMismatchBanner =>
      '서버 ID가 변경되어 연결이 중단되었습니다. 계속하려면 이 기기를 다시 페어링하세요.';

  @override
  String get tabInbox => '받은편지함';

  @override
  String get tabTickets => '티켓';

  @override
  String get tabChat => '채팅';

  @override
  String get tabPrs => 'PR';

  @override
  String get tabCalendar => '캘린더';

  @override
  String get tabNews => '뉴스';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label, $count건 대기';
  }

  @override
  String get updateAvailable => '새 Control Center를 사용할 수 있습니다';

  @override
  String get appearance => '화면';

  @override
  String get language => '언어';

  @override
  String get device => '기기';

  @override
  String get themeSystem => '시스템';

  @override
  String get themeLight => '라이트';

  @override
  String get themeDark => '다크';

  @override
  String get languageSystem => '시스템';

  @override
  String get disconnectTapAgain => '다시 눌러 이 기기를 Control Center에서 연결 해제';

  @override
  String get disconnectDevice => '이 기기 연결 해제';

  @override
  String get disconnect => '연결 해제';

  @override
  String get chooseWorkspace => '워크스페이스 선택';

  @override
  String get workspaces => '워크스페이스';

  @override
  String get workspacesLoadFailed => '워크스페이스를 불러올 수 없음';

  @override
  String get noWorkspacesYet => '워크스페이스가 아직 없음';

  @override
  String selectWorkspace(String name) {
    return '$name 선택';
  }

  @override
  String get inboxLoadFailed => '받은편지함을 불러올 수 없음';

  @override
  String get allCaughtUp => '모두 확인했습니다';

  @override
  String get inboxNoForgeAccount =>
      '서버에 연결된 forge 계정이 없어 아직 내 풀 리퀘스트로 표시할 수 없습니다.';

  @override
  String get inboxNothingWaiting => '막힌 항목이 없고 대기 중인 풀 리퀘스트도 없습니다.';

  @override
  String get blocked => '차단됨';

  @override
  String get sectionNeedsYourReview => '내 리뷰 필요';

  @override
  String get sectionReturnedToYou => '나에게 반환됨';

  @override
  String get sectionApprovedAndReady => '승인됨, 머지 가능';

  @override
  String get sectionYourDrafts => '내 초안';

  @override
  String get sectionWaitingForReviewers => '리뷰어 대기 중';

  @override
  String get sectionMergingAndMerged => '머지 중 및 최근 머지됨';

  @override
  String get sectionWaitingForAuthor => '작성자 대기 중';

  @override
  String waitingAgo(String ago) {
    return '$ago 대기';
  }

  @override
  String get openConversation => '대화 열기';

  @override
  String get calendarLoadFailed => '캘린더를 불러올 수 없음';

  @override
  String get nothingScheduled => '일정 없음';

  @override
  String get calendarEmptyDescription => '연결된 캘린더의 이벤트가 여기에 표시됩니다.';

  @override
  String get agenda => '일정';

  @override
  String get syncCalendarsNow => '지금 캘린더 동기화';

  @override
  String get event => '이벤트';

  @override
  String get eventNotFound => '이벤트를 찾을 수 없음';

  @override
  String get eventNotFoundDescription => '일정 범위를 벗어났거나 원본에서 삭제되었을 수 있습니다.';

  @override
  String get joinMeeting => '회의 참가';

  @override
  String get join => '참가';

  @override
  String attendeesCount(int count) {
    return '참석자 ($count)';
  }

  @override
  String get details => '세부정보';

  @override
  String get allDay => '종일';

  @override
  String get happeningNow => '진행 중';

  @override
  String inDuration(String duration) {
    return '$duration 후';
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
  String get attendeeAccepted => '수락';

  @override
  String get attendeeDeclined => '거절';

  @override
  String get attendeeMaybe => '미정';

  @override
  String get attendeeNoReply => '무응답';

  @override
  String get organizer => '주최자';

  @override
  String get calendarNoAccounts =>
      '이 워크스페이스에 연결된 캘린더가 없습니다. 데스크톱 앱에서 연결하세요. 로그인은 토큰을 서버에 저장합니다.';

  @override
  String get calendarReauthNeeded =>
      '캘린더 계정을 다시 연결해야 합니다. 아래 정보가 오래되었을 수 있습니다. 데스크톱 앱에서 다시 연결하세요.';

  @override
  String get spacesLoadFailed => '스페이스를 불러올 수 없음';

  @override
  String get noSpaces => '스페이스 없음';

  @override
  String get spacesEmptyDescription => '이 워크스페이스의 스페이스가 여기에 표시됩니다.';

  @override
  String get thread => '스레드';

  @override
  String get agentWorking => '에이전트 작업 중';

  @override
  String get messagesLoadFailed => '메시지를 불러올 수 없음';

  @override
  String get noMessagesYet => '아직 메시지가 없습니다';

  @override
  String get noMessagesDescription => '메시지를 보내 대화를 시작하세요.';

  @override
  String get agentResponding => '에이전트 응답 중';

  @override
  String get agentFinished => '에이전트 완료';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names은(는) 여기서 보내기에 너무 큽니다.',
      one: '$names은(는) 여기서 보내기에 너무 큽니다.',
    );
    return '$_temp0';
  }

  @override
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names은(는) 여기서 릴레이로 보내기에 너무 큽니다.',
      one: '$names은(는) 여기서 릴레이로 보내기에 너무 큽니다.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed => '첨부 파일을 업로드할 수 없습니다. 다시 시도하세요.';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '첨부 파일 $count개를 업로드하지 못해 제외했습니다.',
      one: '첨부 파일 1개를 업로드하지 못해 제외했습니다.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => '팀원';

  @override
  String get agent => '에이전트';

  @override
  String get attachFile => '파일 첨부';

  @override
  String get messageHint => '메시지';

  @override
  String removeAttachment(String name) {
    return '$name 삭제';
  }

  @override
  String get articlesLoadFailed => '글을 불러오지 못함';

  @override
  String get noArticles => '글 없음';

  @override
  String get articlesEmptyDescription => '피드가 업데이트되면 새 글이 여기에 표시됩니다.';

  @override
  String get unread => '읽지 않음';

  @override
  String get allFeeds => '모든 피드';

  @override
  String get save => '저장';

  @override
  String get unsave => '저장 취소';

  @override
  String get readFullArticle => '전체 글 보기';

  @override
  String get ticketsLoadFailed => '티켓을 불러오지 못함';

  @override
  String get noTickets => '티켓 없음';

  @override
  String get ticketsEmptyDescription => '이 워크스페이스의 티켓이 여기에 표시됩니다.';

  @override
  String get all => '전체';

  @override
  String get ticket => '티켓';

  @override
  String get ticketLoadFailed => '티켓을 불러오지 못함';

  @override
  String assignedTo(String name) {
    return '$name에게 할당됨';
  }

  @override
  String get openInBrowser => '브라우저에서 열기';

  @override
  String get status => '상태';

  @override
  String get assign => '할당';

  @override
  String get reassign => '재할당';

  @override
  String get noAgents => '에이전트 없음';

  @override
  String get noAgentsDescription => '이 워크스페이스에서 담당자를 할당하세요.';

  @override
  String get statusOpen => '열림';

  @override
  String get statusInProgress => '진행 중';

  @override
  String get statusBlocked => '차단됨';

  @override
  String get statusInReview => '검토 중';

  @override
  String get statusDone => '완료';

  @override
  String get statusBacklog => '백로그';

  @override
  String get lensNeedsMe => '내 검토 필요';

  @override
  String get lensMine => '내 PR';

  @override
  String get prsLoadFailed => '풀 리퀘스트를 불러오지 못함';

  @override
  String get noOpenPullRequests => '열린 풀 리퀘스트가 없습니다';

  @override
  String get nothingWaitingOnReview => '검토를 기다리는 항목이 없습니다';

  @override
  String get noOwnOpenPullRequests => '열린 풀 리퀘스트가 없습니다';

  @override
  String get nothingBlocked => '차단된 항목이 없습니다';

  @override
  String get prsEmptyDescription => '이 워크스페이스 저장소의 풀 리퀘스트가 여기에 표시됩니다.';

  @override
  String get refreshPullRequests => '풀 리퀘스트 새로고침';

  @override
  String get noForgeConnected =>
      '서버에 연결된 포지가 없어 풀 리퀘스트를 가져올 수 없습니다. 데스크톱 앱에서 연결하세요.';

  @override
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '저장소 $count개를 읽을 수 없습니다.',
      one: '저장소 1개를 읽을 수 없습니다.',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return '읽을 수 없음: $names';
  }

  @override
  String get installationSuspendedTitle => 'GitHub App 설치가 일시 중단됨';

  @override
  String installationSuspendedBody(String names) {
    return '$names의 마지막 알려진 데이터를 표시합니다. GitHub에서 설치를 재개하거나 접근 권한이 있는 토큰을 연결하세요.';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'GitHub App 설치가 일시 중단됨. $names의 마지막 알려진 데이터를 표시합니다. GitHub에서 설치를 재개하거나 접근 권한이 있는 토큰을 연결하세요.';
  }

  @override
  String get draft => '초안';

  @override
  String get merged => '병합됨';

  @override
  String get closed => '닫힘';

  @override
  String get open => '열림';

  @override
  String get approved => '승인됨';

  @override
  String get changesRequested => '변경 요청됨';

  @override
  String get reviewRequired => '검토 필요';

  @override
  String get checksPassing => '검사 통과';

  @override
  String get checksFailing => '검사 실패';

  @override
  String get checksRunning => '검사 실행 중';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => '풀 리퀘스트';

  @override
  String get prLoadFailed => '이 풀 리퀘스트를 불러오지 못함';

  @override
  String get openOnForge => '포지에서 열기';

  @override
  String get requestChangesNeedsComment => '변경이 필요한 이유를 댓글로 작성하세요.';

  @override
  String get conversation => '대화';

  @override
  String get files => '파일';

  @override
  String get checks => '검사';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '파일 $count개',
      one: '파일 1개',
    );
    return '$_temp0';
  }

  @override
  String commitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '커밋 $count개',
      one: '커밋 1개',
    );
    return '$_temp0';
  }

  @override
  String get conflicts => '충돌';

  @override
  String get reviewers => '리뷰어';

  @override
  String get noDescriptionNoComments => '설명과 댓글이 아직 없습니다.';

  @override
  String get noChangedFiles => '변경된 파일이 없습니다.';

  @override
  String get noChecksReported => '헤드 커밋에 보고된 검사가 없습니다.';

  @override
  String get reviewCommentHint => '검토 댓글 남기기…';

  @override
  String get comment => '댓글';

  @override
  String get commentPosted => '댓글을 게시했습니다';

  @override
  String get request => '요청';

  @override
  String get squashAndMerge => '스쿼시 후 병합';

  @override
  String noActionsAvailable(String status) {
    return '$status — 사용 가능한 작업이 없습니다.';
  }

  @override
  String get reviewApproved => '승인함';

  @override
  String get reviewRequestedChanges => '변경 요청함';

  @override
  String get reviewCommented => '검토함';

  @override
  String get reviewPending => '대기 중';

  @override
  String get unknownAuthor => '알 수 없음';

  @override
  String hideDiffFor(String file) {
    return '$file 차이 숨기기';
  }

  @override
  String showDiffFor(String file) {
    return '$file 차이 보기';
  }

  @override
  String get checkRunning => '실행 중';

  @override
  String get checkPassed => '통과';

  @override
  String get checkFailed => '실패';

  @override
  String get checkCancelled => '취소됨';

  @override
  String get checkSkipped => '건너뜀';

  @override
  String labelWithDuration(String label, String duration) {
    return '$label · $duration';
  }

  @override
  String checkSemanticLabel(String name, String state) {
    return '$name, $state';
  }

  @override
  String get noTextDiff => '이 파일의 텍스트 차이가 없습니다. 바이너리이거나 포지가 반환하기에 너무 큽니다.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '남은 $count줄 보기',
      one: '남은 줄 보기',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '변경되지 않은 줄 $count개',
      one: '변경되지 않은 줄 1개',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => '최신으로 이동';

  @override
  String get streaming => '스트리밍';

  @override
  String get working => '작업 중';

  @override
  String get input => '입력';

  @override
  String get output => '출력';

  @override
  String get now => '방금';

  @override
  String agoMinutes(int count) {
    return '$count분';
  }

  @override
  String agoHours(int count) {
    return '$count시간';
  }

  @override
  String agoDays(int count) {
    return '$count일';
  }

  @override
  String get today => '오늘';

  @override
  String get tomorrow => '내일';

  @override
  String get yesterday => '어제';

  @override
  String durationMinutes(int count) {
    return '$count분';
  }

  @override
  String durationHours(int count) {
    return '$count시간';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours시간 $minutes분';
  }
}
