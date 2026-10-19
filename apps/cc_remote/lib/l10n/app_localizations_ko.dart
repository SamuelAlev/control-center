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
  String get copyCommand => '명령 복사';

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
  String get newSpaceFolder => '새 폴더';

  @override
  String get folderName => '폴더 이름';

  @override
  String get renameSpaceFolder => '폴더 이름 변경';

  @override
  String get deleteSpaceFolder => '폴더 삭제';

  @override
  String get moveSpaceToFolder => '폴더로 이동';

  @override
  String get removeSpaceFromFolder => '폴더에서 제거';

  @override
  String get spaceFolderActions => '폴더 작업';

  @override
  String get deleteFolderWithSpacesWarning =>
      '스페이스를 영구 삭제하면 모든 사용자에게 해당 메시지와 작업 트리가 제거됩니다. 이 작업은 되돌릴 수 없습니다.';

  @override
  String get deleteSpacesInFolder => '이 폴더의 스페이스 영구 삭제';

  @override
  String get deleteFolderAndSpaces => '폴더와 스페이스 삭제';

  @override
  String get keepSpacesInFolder => '그렇지 않으면 스페이스가 폴더에 속하지 않은 상태로 남습니다.';

  @override
  String get create => '만들기';

  @override
  String get otherSpaces => '다른 스페이스';

  @override
  String get folderUpdateFailed => '폴더를 업데이트할 수 없습니다';

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

  @override
  String get mobileConversations => '대화';

  @override
  String get mobileNewConversation => '새 대화';

  @override
  String get mobileConversationName => '대화 이름';

  @override
  String get mobileRename => '이름 바꾸기';

  @override
  String get mobileManageSpace => '스페이스 관리';

  @override
  String get mobileArchived => '보관됨';

  @override
  String get mobileSearchMessages => '이 스페이스의 모든 메시지 검색';

  @override
  String get mobileSearch => '검색';

  @override
  String get mobileNoResults => '결과 없음';

  @override
  String get mobileReopen => '다시 열기';

  @override
  String get mobileArchive => '보관';

  @override
  String get mobileProgress => '진행 상황 및 컨텍스트';

  @override
  String get mobileReadFailed => '이 대화를 읽음으로 표시하지 못했습니다';

  @override
  String get mobileSendFailed => '메시지를 보내지 못했습니다. 작성 중인 내용은 그대로 있습니다.';

  @override
  String get sentAttachmentUnavailable => '첨부 파일을 사용할 수 없음';

  @override
  String get sentAttachmentLoadFailed => '첨부 파일을 불러올 수 없습니다';

  @override
  String get mobileActionFailed => '실행에 실패했습니다';

  @override
  String get mobileRemove => '제거';

  @override
  String get mobileLinkedMessage => '연결된 메시지';

  @override
  String get mobileOlderMessages => '이전 메시지';

  @override
  String get mobileMessageActions => '메시지 작업';

  @override
  String get mobileOpenThread => '스레드 열기';

  @override
  String get mobileCopyLink => '링크 복사';

  @override
  String get mobileStopRun => '실행 중지';

  @override
  String get mobileStopRunConfirm => '이 에이전트의 실행을 중지하시겠습니까? 이미 완료된 작업은 유지됩니다.';

  @override
  String get mobileControlUnsupported => '이 실행은 종료되었거나 이 기능을 지원하지 않습니다.';

  @override
  String get mobilePauseRequested => '다음 턴이 끝나면 일시 중지하도록 요청했습니다';

  @override
  String get mobileResumed => '실행 재개됨';

  @override
  String get mobileStopRequested => '중지 요청됨';

  @override
  String get mobileQueuedMessages => '대기 중인 메시지';

  @override
  String get mobilePauseRun => '다음 턴에 일시 중지';

  @override
  String get mobileResumeRun => '다시 시작';

  @override
  String get mobileEditQueued => '대기 메시지 편집';

  @override
  String get mobileSteerNow => '지금 방향 변경';

  @override
  String get mobileMoveUp => '위로 이동';

  @override
  String get mobileMoveDown => '아래로 이동';

  @override
  String get mobileQueueChanged =>
      '대기열이 변경되었거나 이 실행에서 실시간 지시를 받을 수 없습니다. 새로고침한 후 다시 시도하세요.';

  @override
  String get mobileActivity => '활동';

  @override
  String get mobilePermissions => '권한 및 감사';

  @override
  String get mobilePlans => '플랜';

  @override
  String get mobileGoals => '관리형 목표';

  @override
  String get mobileCredentials => '연결 및 자격 증명';

  @override
  String get mobileWorkspaceUnavailable =>
      '이 워크스페이스를 사용할 수 없거나 더 이상 접근 권한이 없습니다.';

  @override
  String get mobilePrReviewThreads => '리뷰 스레드';

  @override
  String get mobilePrThreadsLoadFailed => '리뷰 스레드를 불러오지 못했습니다';

  @override
  String get mobilePrNoReviewThreads => '아직 인라인 리뷰 스레드가 없습니다';

  @override
  String get mobilePrCommentPermissionDenied => '이 리포지토리에 댓글을 작성할 권한이 없습니다.';

  @override
  String get mobilePrPermissionChecking => '댓글 권한 확인 중…';

  @override
  String get mobilePrPermissionLoadFailed =>
      '댓글 권한을 확인하지 못했습니다. 댓글을 작성하려면 다시 시도하세요.';

  @override
  String mobilePrThreadLine(String side, String line) {
    return '$side $line행';
  }

  @override
  String get mobilePrOriginalSide => '원본';

  @override
  String get mobilePrSelectCommentLine => '댓글을 달 줄 선택';

  @override
  String get mobilePrUpdatedSide => '업데이트';

  @override
  String get mobilePrThreadResolved => '해결됨';

  @override
  String get mobilePrReplyHint => '답글 작성…';

  @override
  String get mobilePrCommentRequired => '게시하기 전에 댓글을 작성하세요.';

  @override
  String get mobilePrReply => '답글';

  @override
  String get mobilePrReopenThread => '스레드 다시 열기';

  @override
  String get mobilePrResolveThread => '스레드 해결';

  @override
  String get mobilePrResolvePermissionDenied =>
      '풀 리퀘스트 작성자 또는 쓰기 권한이 있는 사용자만 이 스레드를 해결할 수 있습니다.';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return '$side $line행에 댓글 작성';
  }

  @override
  String get mobilePrInlineCommentHint => '인라인 댓글 작성…';

  @override
  String get mobilePrPostInlineComment => '댓글 게시';

  @override
  String get mobilePrCommentUnavailable => '이 풀 리퀘스트에서는 인라인 댓글을 사용할 수 없습니다.';

  @override
  String get mobilePrPatchUnavailable =>
      '코드 호스팅 서비스에서 이 파일의 텍스트 패치를 제공하지 않았습니다.';

  @override
  String get mobilePrNoPatchForFile => '이 파일의 패치를 사용할 수 없습니다.';

  @override
  String get mobileTicketNew => '새 티켓';

  @override
  String get mobileTicketCreate => '티켓 만들기';

  @override
  String get mobileTicketEdit => '티켓 편집';

  @override
  String get mobileTicketTitle => '제목';

  @override
  String get mobileTicketTitleRequired => '티켓을 저장하려면 제목을 입력하세요.';

  @override
  String get mobileTicketDescription => '설명';

  @override
  String get mobileTicketMarkdownHint => 'Markdown으로 상세 정보 추가';

  @override
  String get mobileTicketPriority => '우선순위';

  @override
  String get mobileTicketPriorityNone => '우선순위 없음';

  @override
  String get mobileTicketPriorityUrgent => '긴급';

  @override
  String get mobileTicketPriorityHigh => '높음';

  @override
  String get mobileTicketPriorityMedium => '중간';

  @override
  String get mobileTicketPriorityLow => '낮음';

  @override
  String get mobileTicketLabels => '레이블';

  @override
  String get mobileTicketLabelsHint => '한 줄에 레이블 하나';

  @override
  String get mobileTicketLabelsHelp => '각 레이블을 별도의 줄에 입력하세요.';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return '$provider에 등록됨';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => '미할당';

  @override
  String get mobileTicketAssignedFilter => '할당됨';

  @override
  String get mobileTicketAgentsLoadFailed => '에이전트를 불러오지 못했습니다';

  @override
  String get mobileTicketSearch => '티켓 검색';

  @override
  String get mobileTicketSearchHint => '제목, 키, 설명, 레이블 또는 담당자';

  @override
  String get mobileTicketClearSearch => '티켓 검색어 지우기';

  @override
  String get mobileTicketNoMatches => '일치하는 티켓 없음';

  @override
  String get mobileTicketAdjustFilters => '다른 검색어를 사용하거나 필터를 변경하세요.';

  @override
  String get mobileTicketClearFilters => '필터 지우기';

  @override
  String get mobileTicketNotFound => '티켓을 찾을 수 없음';

  @override
  String get mobileTicketNotFoundDescription =>
      '이 티켓이 삭제되었거나 이 워크스페이스에서 이동되었을 수 있습니다.';

  @override
  String get mobileTicketWorkspaceChanged =>
      '워크스페이스가 변경되었습니다. 저장하기 전에 현재 워크스페이스로 돌아가세요.';

  @override
  String get mobileTicketOpenLinkedSpace => '연결된 스페이스 열기';

  @override
  String get mobileTicketReadOnly => '티켓을 변경하려면 워크스페이스 멤버 권한이 필요합니다.';

  @override
  String get permissionTitle => '권한';

  @override
  String get permissionWorkspaceFailed => '워크스페이스를 불러오지 못했습니다';

  @override
  String get permissionNoWorkspace => '권한을 확인할 워크스페이스를 선택하세요.';

  @override
  String get permissionLoading => '권한 불러오는 중…';

  @override
  String get permissionScopeDescription =>
      '이 범위에서 각 작업의 허용 여부가 어떻게 결정되는지 확인하세요. 워크스페이스 규칙은 에이전트와 스페이스에 상속될 수 있습니다.';

  @override
  String get permissionScope => '정책 적용 범위';

  @override
  String get permissionWorkspaceScope => '워크스페이스';

  @override
  String get permissionAgentScope => '에이전트';

  @override
  String get permissionSpaceScope => '스페이스';

  @override
  String get permissionAgentContext => '이 스페이스에서 활동하는 에이전트';

  @override
  String get permissionNoAgentContext => '선택한 에이전트 없음';

  @override
  String get permissionTargetsFailed => '적용 대상 목록을 불러오지 못했습니다';

  @override
  String get permissionNoTargets => '이 범위에서 사용할 수 있는 대상이 없습니다.';

  @override
  String get permissionRoleFailed => '워크스페이스 내 역할을 확인하지 못했습니다';

  @override
  String get permissionMemberRequired => '정책 규칙을 보려면 워크스페이스 멤버 권한이 필요합니다.';

  @override
  String get permissionRulesFailed => '정책 규칙을 불러오지 못했습니다';

  @override
  String get permissionAuditAdminOnly => '권한 승인 기록은 워크스페이스 관리자만 볼 수 있습니다.';

  @override
  String get permissionAllow => '허용';

  @override
  String get permissionAsk => '먼저 묻기';

  @override
  String get permissionDeny => '거부';

  @override
  String get permissionFileDelete => '파일 삭제';

  @override
  String get permissionFileWriteOutsideWorktree => '작업 트리 외부에 쓰기';

  @override
  String get permissionGitCommit => '변경 사항 커밋';

  @override
  String get permissionGitPush => '커밋 푸시';

  @override
  String get permissionPrCreate => '풀 리퀘스트 만들기';

  @override
  String get permissionPrPublish => '풀 리퀘스트 게시';

  @override
  String get permissionVendorSyncWrite => '외부 서비스 동기화 쓰기';

  @override
  String get permissionNetworkEgress => '네트워크 접근';

  @override
  String get permissionSecretAccess => '비밀 정보 접근';

  @override
  String get permissionPackageInstall => '패키지 설치';

  @override
  String get permissionProcessSpawn => '프로세스 시작';

  @override
  String get permissionWorkspaceMutation => '워크스페이스 변경';

  @override
  String get permissionEnclosureControl => '인클로저 제어';

  @override
  String get permissionChangeFailed => '규칙을 변경하지 못했습니다';

  @override
  String get permissionEffectiveDescription =>
      '작업 인수 없이 이 범위에 적용되는 규칙입니다. 아래의 조건부 허용은 조건에 맞는 요청에만 적용되며, 최종 결정은 서버에서 내립니다.';

  @override
  String get permissionSpaceAgentNote =>
      '선택한 에이전트가 없습니다. 위에서 에이전트를 선택할 때까지 에이전트별 규칙은 표시되지 않습니다.';

  @override
  String get permissionScopedGrants => '이 범위의 규칙';

  @override
  String get permissionModePreset => '모드 프리셋';

  @override
  String get permissionBuiltInDefault => '내장 기본값';

  @override
  String get permissionRemembered => '기억된 승인';

  @override
  String get permissionSource => '소스';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · 여기에서 설정';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · 상속됨';
  }

  @override
  String permissionExpiresAt(String date) {
    return '$date에 만료';
  }

  @override
  String get permissionSetHere => '여기에 규칙 설정';

  @override
  String get permissionRevokeBeforeEdit =>
      '이 작업의 일반 규칙을 설정하기 전에 범위 지정 규칙이나 기억된 규칙을 취소하세요.';

  @override
  String get permissionConfirmRevoke => '취소 확인';

  @override
  String get permissionRevokeRule => '규칙 취소';

  @override
  String permissionCommandPrefix(String prefix) {
    return '명령어 접두사: $prefix';
  }

  @override
  String get permissionNoExpiry => '만료일 없음';

  @override
  String get permissionExpired => '만료됨';

  @override
  String get permissionExplicitRule => '명시적 규칙';

  @override
  String get permissionEnforcementAdvisory => '권고: 먼저 묻기 규칙은 사용자에게 묻지 않고 기록됩니다';

  @override
  String get permissionEnforcementSoft => '완화 적용: 재정의하려면 승인이 필요합니다';

  @override
  String get permissionEnforcementHard => '엄격 적용: 재정의할 수 없습니다';

  @override
  String permissionPaths(String paths) {
    return '경로: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'Git 참조: $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return '호스트: $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return '명령어: $commands';
  }

  @override
  String permissionMaxCount(String count) {
    return '최대 개수: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return '최대 센트: $cents';
  }

  @override
  String get permissionAuditHeading => '권한 승인 기록';

  @override
  String get permissionAuditDescription =>
      '서버에 기록된 최근 결정입니다. 관리자만 로그를 보거나 해시 체인을 검증할 수 있습니다.';

  @override
  String permissionOnBehalfOf(String user) {
    return '$user을(를) 대신하여';
  }

  @override
  String get permissionPrompted => '사용자 승인 요청됨';

  @override
  String get permissionVerifyChain => '감사 체인 검증';

  @override
  String get permissionVerifyFailed => '감사 체인을 검증하지 못했습니다';

  @override
  String permissionChainIntact(String count) {
    return '체인 정상 · 항목 $count개 확인';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return '체인 손상 · 항목 $sequence: $reason';
  }

  @override
  String get permissionAuditEmpty => '아직 기록된 권한 승인 결정이 없습니다.';

  @override
  String get permissionAuditFailed => '권한 승인 기록을 불러오지 못했습니다';

  @override
  String get mobilePlansLoadFailed => '플랜을 불러오지 못했습니다';

  @override
  String get mobilePlansEmpty => '아직 플랜이 없습니다';

  @override
  String get mobilePlansEmptyDescription => '에이전트가 제출한 플랜을 여기에서 검토할 수 있습니다.';

  @override
  String get mobilePlanTitle => '계획';

  @override
  String get mobilePlanMissing => '이 워크스페이스에서 더 이상 이 플랜을 사용할 수 없습니다.';

  @override
  String mobilePlanStepCount(int count) {
    return '단계 $count개';
  }

  @override
  String get mobilePlanDraft => '초안';

  @override
  String get mobilePlanProposed => '검토 대기 중';

  @override
  String get mobilePlanApproved => '승인됨';

  @override
  String get mobilePlanRejected => '거절됨';

  @override
  String get mobilePlanSuperseded => '대체됨';

  @override
  String get mobilePlanExecuting => '실행 중';

  @override
  String get mobilePlanSynthesizing => '종합 중';

  @override
  String get mobilePlanCompleted => '완료됨';

  @override
  String get mobilePlanFailed => '실패';

  @override
  String get mobilePlanCancelled => '취소됨';

  @override
  String mobilePlanRevision(String revision) {
    return '리비전 $revision';
  }

  @override
  String get mobilePlanSteps => '단계';

  @override
  String get mobilePlanNoSteps => '이 플랜에 제출된 단계가 없습니다.';

  @override
  String get mobilePlanAssumptions => '확인할 사항';

  @override
  String mobilePlanDependsOn(String keys) {
    return '$keys에 종속';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return '최대 $cost 예상';
  }

  @override
  String get mobilePlanSelect => '선택';

  @override
  String get mobilePlanSelected => '선택됨';

  @override
  String get mobilePlanEstimate => '비용 추정';

  @override
  String get mobilePlanEstimateRequired => '실행을 승인하기 전에 플랜 비용을 추정하세요.';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return '예상 비용: $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => '확인할 수 없음';

  @override
  String get mobilePlanNoHardCap => '최대 한도 없음';

  @override
  String get mobilePlanExceedsBudget => '예상 비용이 설정된 예산을 초과합니다. 승인하기 전에 검토하세요.';

  @override
  String get mobilePlanPartialEstimate =>
      '이 추정치는 플랜 전체에 대한 것입니다. 선택한 단계의 비용은 더 낮을 수 있습니다.';

  @override
  String get mobilePlanConfirmAll => '전체 플랜을 시작하시겠습니까?';

  @override
  String get mobilePlanConfirmSelected => '선택한 단계를 시작하시겠습니까?';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return '승인하면 실행이 시작되고 비용이 발생할 수 있습니다. 예상 최대 비용: $cost. 예산 상한: $cap.';
  }

  @override
  String get mobilePlanApproveAll => '모두 승인하고 실행';

  @override
  String get mobilePlanApproveSelected => '선택한 단계 승인하고 실행';

  @override
  String get mobilePlanWiden => '추가 단계 승인';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return '단계 $count개를 추가로 실행하시겠습니까? 비용이 발생할 수 있습니다. 기존 실행 비용 상한: $cap.';
  }

  @override
  String get mobilePlanChanged =>
      '검토 중 플랜이 변경되었습니다. 최신 리비전을 다시 열어 비용을 다시 추정하세요.';

  @override
  String get mobilePlanReject => '플랜 거절';

  @override
  String get mobilePlanRejectConfirm => '이 플랜을 거절하시겠습니까? 실행되지 않습니다.';

  @override
  String get mobilePlanStop => '실행 중지';

  @override
  String get mobilePlanStopConfirm =>
      '이 플랜의 실행을 중지하시겠습니까? 이미 완료된 작업은 취소되지 않습니다.';

  @override
  String mobilePlanRunId(String runId) {
    return '실행 ID: $runId';
  }

  @override
  String get mobilePlanExecutionPending => '승인되었습니다. 실행 기록을 기다리는 중…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return '실행 단계 $total개 중 $completed개 완료';
  }

  @override
  String get mobilePlanOpenConversation => '대화 열기';

  @override
  String get mobileGoalsTitle => '관리형 목표';

  @override
  String get mobileGoalsLoadFailed => '관리형 목표를 불러오지 못했습니다';

  @override
  String get mobileGoalsEmpty => '아직 관리형 목표가 없습니다';

  @override
  String get mobileGoalsEmptyDescription =>
      '스페이스에서 목표를 시작하거나 대화에서 /goal을 보내세요.';

  @override
  String get mobileGoalMissing => '이 워크스페이스에서 더 이상 이 목표를 사용할 수 없습니다.';

  @override
  String get mobileGoalActive => '활성';

  @override
  String get mobileGoalPaused => '일시 중지됨';

  @override
  String get mobileGoalCompleted => '완료됨';

  @override
  String get mobileGoalFailed => '실패';

  @override
  String get mobileGoalCancelled => '취소됨';

  @override
  String get mobileGoalBudgetExhausted => '예산 한도 도달';

  @override
  String get mobileGoalGoal => '목표';

  @override
  String get mobileGoalLoop => '반복';

  @override
  String mobileGoalKind(String kind) {
    return '유형: $kind';
  }

  @override
  String mobileGoalRuns(String count) {
    return '실행 $count회';
  }

  @override
  String get mobileGoalNoRunLimit => '제한 없음';

  @override
  String mobileGoalProgress(
    String runs,
    String maxRuns,
    String spent,
    String cap,
  ) {
    return '실행: $runs / $maxRuns · 지출: $spent / $cap';
  }

  @override
  String mobileGoalDeadline(String date) {
    return '마감일: $date';
  }

  @override
  String mobileGoalFailures(String count) {
    return '연속 실행 실패: $count회';
  }

  @override
  String get mobileGoalSummary => '완료 요약';

  @override
  String get mobileGoalFailedDescription =>
      '반복된 실행 실패로 관리자가 목표를 중지했습니다. 자세한 내용은 대화를 확인하세요.';

  @override
  String get mobileGoalBudgetWall =>
      '마감일이나 실행 횟수 한도에 도달했습니다. 비용 상한을 높여도 이 목표를 재개할 수 없습니다.';

  @override
  String get mobileGoalPause => '목표 일시 중지';

  @override
  String get mobileGoalResume => '목표 재개';

  @override
  String get mobileGoalStop => '목표 취소';

  @override
  String get mobileGoalStopConfirm =>
      '이 관리형 목표를 영구적으로 취소하시겠습니까? 다시 시작할 수 없습니다.';

  @override
  String get mobileGoalRaiseBudget => '예산 늘리고 재개';

  @override
  String mobileGoalRaiseTo(String amount) {
    return '예산을 $amount로 늘리고 재개';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return '이 목표의 비용 상한을 $oldCap에서 $newCap(으)로 늘리고 지출을 재개하시겠습니까?';
  }

  @override
  String get mobileGoalOpenConversation => '목표 대화 열기';

  @override
  String get mobileGoalCreate => '관리형 목표 시작';

  @override
  String get mobileGoalChooseSpace => '실행할 스페이스';

  @override
  String get mobileGoalNoSpaces => '목표를 시작하기 전에 스페이스를 만드세요.';

  @override
  String get mobileGoalChooseAgent => '실행할 에이전트';

  @override
  String get mobileGoalNoAgents => '목표를 시작하기 전에 활성 에이전트를 추가하세요.';

  @override
  String mobileGoalSelectedAgent(String name) {
    return '$name 선택됨';
  }

  @override
  String get mobileGoalObjectiveHint => '에이전트가 달성할 결과를 입력하세요';

  @override
  String get mobileGoalBudgetUsd => '비용 상한(USD)';

  @override
  String get mobileGoalCreateInvalid =>
      '스페이스와 에이전트를 선택하고 목표를 입력한 다음 USD 기준 양수의 비용 상한을 설정하세요.';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return '최대 비용 $cap으로 관리형 목표를 시작하시겠습니까? 에이전트가 즉시 실행될 수 있습니다.';
  }

  @override
  String get mobileGoalUnavailable => '서버 연결이 준비되지 않았습니다. 다시 연결한 후 재시도하세요.';

  @override
  String get mobileGoalConversationMissing =>
      '선택한 대화를 이 워크스페이스에서 더 이상 사용할 수 없습니다.';

  @override
  String get mobileGoalCreateSent => '목표가 시작되었습니다. 이 목록에 관리 상태가 표시됩니다.';

  @override
  String get mobileGoalStartRefused => '목표 실행이 시작되지 않았습니다. 이유는 대화에서 확인하세요.';

  @override
  String mobileGoalSelectedSpace(String name) {
    return '$name 선택됨';
  }

  @override
  String get requestUnavailable => '이 요청을 현재 워크스페이스에서 더 이상 사용할 수 없습니다.';

  @override
  String get requestAlreadyResolved => '이 요청은 이미 처리되었습니다.';

  @override
  String get inboxCredentialsBlocked => '실행을 차단하는 자격 증명';

  @override
  String get inboxSyncFailures => '실패한 외부 서비스 동기화';

  @override
  String get inboxConfigureCredentials => '자격 증명 설정';

  @override
  String get openTicket => '티켓 열기';

  @override
  String get activityTitle => '활동';

  @override
  String get activityClearAll => '활동 모두 지우기';

  @override
  String get activityClearConfirm =>
      '모든 기기에서 지금까지 기록된 활동이 숨겨집니다. 새 활동은 계속 표시됩니다.';

  @override
  String get activityMarkAllRead => '모두 읽음으로 표시';

  @override
  String get activityMarkAllConfirm =>
      '이 워크스페이스의 모든 활동을 모든 기기에서 읽음으로 표시하시겠습니까?';

  @override
  String get activityMarkRead => '읽음으로 표시';

  @override
  String get activityMarkUnread => '읽지 않음으로 표시';

  @override
  String get activityDismiss => '닫기';

  @override
  String get activityResolved => '해결됨';

  @override
  String get activityOpen => '열림';

  @override
  String get activityEmpty => '아직 활동이 없습니다';

  @override
  String get activityLoadFailed => '활동을 불러오지 못했습니다';

  @override
  String get activityAgentWaiting => '에이전트가 입력을 기다림';

  @override
  String get activityAgentBlocked => '에이전트 작업 차단됨';

  @override
  String get activityMessage => '새 메시지';

  @override
  String get activityPullRequest => '풀 리퀘스트 업데이트';

  @override
  String get activityTicket => '티켓 업데이트';

  @override
  String get activityMeeting => '회의 업데이트';

  @override
  String get activityCalendar => '캘린더 연결';

  @override
  String get activityRig => '인클로저 업데이트';

  @override
  String get activityEvent => '업데이트';

  @override
  String get activityPrReady => '풀 리퀘스트 병합 준비됨';

  @override
  String get activityPrBlocked => '풀 리퀘스트 병합 차단됨';

  @override
  String get activityPrApproved => '풀 리퀘스트 승인됨';

  @override
  String get activityPrChanges => '변경 요청됨';

  @override
  String get activityPrChecksFailed => '풀 리퀘스트 검사 실패';

  @override
  String get activityPrChecksRecovered => '풀 리퀘스트 검사 정상화';

  @override
  String get activityPrComment => '풀 리퀘스트 댓글';

  @override
  String get activityPrPublished => '풀 리퀘스트 게시됨';

  @override
  String get activityPrMerged => '풀 리퀘스트가 병합되었습니다';

  @override
  String get activityPrMentioned => '풀 리퀘스트에서 나를 언급함';

  @override
  String get activityPrReviewRequested => '리뷰 요청됨';

  @override
  String get activityPrReviewStale => '리뷰를 새로 확인해야 함';

  @override
  String get activityTicketAssigned => '티켓 할당됨';

  @override
  String get activityTicketChanged => '티켓 상태 변경';

  @override
  String get activityMeetingSoon => '회의가 곧 시작됩니다';

  @override
  String get activityCalendarExpired => '캘린더 연결 만료됨';

  @override
  String get activityRigControl => '인클로저 제어 변경됨';

  @override
  String get activityRigClosed => '인클로저 중지됨';

  @override
  String get mobileSpacesSearch => '스페이스 검색';

  @override
  String get mobileSpacesArchived => '보관됨';

  @override
  String get mobileSpacesActive => '활성';

  @override
  String get mobileSpacesNew => '새 스페이스';

  @override
  String get mobileSpacesManage => '스페이스 관리';

  @override
  String get mobileSpacesName => '스페이스 이름';

  @override
  String get mobileSpacesAgents => '에이전트';

  @override
  String get mobileSpacesMembers => '사람';

  @override
  String get mobileSpacesRepos => '리포지토리';

  @override
  String get mobileSpacesAllRepos => '연결된 모든 리포지토리';

  @override
  String get mobileSpacesNoRepos => '리포지토리 없음';

  @override
  String get mobileSpacesBaseBranch => '기준 브랜치(선택 사항)';

  @override
  String get mobileSpacesDefaultBranch => '기본 브랜치';

  @override
  String get mobileSpacesMode => '모드';

  @override
  String get mobileSpacesModeChat => '채팅';

  @override
  String get mobileSpacesModeReview => '리뷰(읽기 전용)';

  @override
  String get mobileSpacesModePlan => '계획(읽기 전용)';

  @override
  String get mobileSpacesModeOrchestrate => '오케스트레이션';

  @override
  String get mobileSpacesAutonomy => '자율성 설정 재정의';

  @override
  String get mobileSpacesAutonomyInherited => '상속됨';

  @override
  String get mobileSpacesAutonomyPropose => '제안만';

  @override
  String get mobileSpacesAutonomyApproval => '승인 후 실행';

  @override
  String get mobileSpacesAutonomyFreely => '자유롭게 실행';

  @override
  String get mobileSpacesAutonomyNotice =>
      '재정의 설정으로 작업 정책의 승인 요청이나 거부를 우회할 수 없습니다. 워크스페이스 관리자만 변경할 수 있습니다.';

  @override
  String get mobileSpacesArchive => '스페이스 보관';

  @override
  String get mobileSpacesReopen => '스페이스 다시 열기';

  @override
  String get mobileSpacesSave => '변경 사항 저장';

  @override
  String get mobileSpacesCreate => '스페이스 만들기';

  @override
  String get mobileSpacesOperationFailed => '스페이스를 업데이트하지 못했습니다';

  @override
  String get mobileSpacesMissing => '이 워크스페이스에서 스페이스를 찾을 수 없음';

  @override
  String get mobileSpacesEmptyName => '스페이스 이름을 입력하세요';

  @override
  String get mobileSpacesNoMatches => '일치하는 스페이스 없음';

  @override
  String get mobileSpacesUnread => '읽지 않은 에이전트 답변';

  @override
  String get mobileSpacesNeedsInput => '입력 필요';

  @override
  String get mobileSpacesRunning => '에이전트 실행 중';

  @override
  String get mobileSpacesNoAgents => '이 워크스페이스에 에이전트가 없습니다';

  @override
  String get mobileSpacesNoMembers => '다른 워크스페이스 멤버가 없습니다';

  @override
  String get mobileSpacesRepoError => '리포지토리를 불러오지 못했습니다';

  @override
  String get mobileSpacesRetry => '재시도';

  @override
  String get mobileSpacesBranchUnavailable =>
      '스페이스를 만들 때 기준 브랜치를 선택하거나 입력하세요. 기존 스페이스의 기준 브랜치는 변경할 수 없습니다.';

  @override
  String get mobileSpacesArchivedEmpty => '보관된 스페이스가 없습니다';

  @override
  String get mobileSpacesAllRepoWarning =>
      '워크스페이스에 새로 연결된 리포지토리도 이 스페이스에 포함됩니다.';

  @override
  String get mobileSpacesCreatedRetry =>
      '스페이스를 만들었습니다. 사람 추가를 다시 시도하거나 관리 페이지를 여세요.';

  @override
  String get progressTitle => '진행 상황';

  @override
  String get progressConversation => '대화';

  @override
  String get progressLoadFailed => '진행 상황을 불러오지 못했습니다';

  @override
  String get progressUnavailable => '대화를 사용할 수 없음';

  @override
  String get progressUnavailableDescription =>
      '이 대화는 현재 워크스페이스와 스페이스에 속하지 않습니다. 계속하려면 해당 스페이스로 돌아가세요.';

  @override
  String get progressSaveFailed => '진행 상황을 업데이트하지 못했습니다';

  @override
  String get progressGoal => '목표';

  @override
  String get progressNoGoal => '진행 목표가 설정되지 않음';

  @override
  String get progressSetGoal => '목표 설정';

  @override
  String get progressEditGoal => '목표 편집';

  @override
  String get progressClearGoal => '목표 지우기';

  @override
  String get progressGoalRequired => '저장하기 전에 목표를 입력하세요.';

  @override
  String get progressTodos => '작업';

  @override
  String get transcriptToolTodos => '작업';

  @override
  String get transcriptToolSearchMemory => '메모리 검색';

  @override
  String get transcriptToolRenderMedia => '미디어 표시';

  @override
  String get progressNoTodos => '아직 작업이 없습니다';

  @override
  String get progressNewTodo => '새 작업';

  @override
  String get progressAddTodo => '작업 추가';

  @override
  String get progressEditTodo => '작업 편집';

  @override
  String get progressTodoRequired => '저장하기 전에 작업을 입력하세요.';

  @override
  String get progressTodoNoLongerExists =>
      '해당 작업이 삭제되었습니다. 목록을 다시 불러온 후 재시도하세요.';

  @override
  String get progressWorkspaceChanged =>
      '현재 워크스페이스가 변경되었습니다. 이 대화로 돌아와 다시 시도하세요.';

  @override
  String progressRemoveTodo(String name) {
    return '작업 $name 제거';
  }

  @override
  String get progressPending => '대기 중';

  @override
  String get progressInProgress => '진행 중';

  @override
  String get progressCompleted => '완료됨';

  @override
  String get progressMoveUp => '작업 위로 이동';

  @override
  String get progressMoveDown => '작업 아래로 이동';

  @override
  String get progressRunTree => '에이전트 실행';

  @override
  String get progressNoRuns => '이 대화에는 아직 실행 기록이 없습니다';

  @override
  String get progressRunning => '실행 중';

  @override
  String get progressFailed => '실패';

  @override
  String get progressUnknown => '알 수 없음';

  @override
  String get progressHealthy => '활성';

  @override
  String get progressBlocked => '차단됨';

  @override
  String get progressLooping => '반복 중';

  @override
  String get progressStalled => '진행 멈춤';

  @override
  String get progressDead => '예기치 않게 중지됨';

  @override
  String get progressQuiet => '아직 출력 없음';

  @override
  String get progressCostReported => '서비스 제공자가 보고한 요금';

  @override
  String get progressCostNotional => '구독 정가를 기준으로 계산한 참고 가격이며 청구 금액이 아닙니다';

  @override
  String get progressCostMixed => '여러 비용 출처';

  @override
  String get progressCostEstimated => '예상 비용';

  @override
  String progressDurationSeconds(String seconds) {
    return '$seconds초';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return '모델: $model · 시간: $duration · 비용: $cost';
  }

  @override
  String progressStartedAt(String time) {
    return '$time에 시작됨';
  }

  @override
  String progressLiveness(String state) {
    return '상태: $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return '입력: $input · 출력: $output토큰';
  }

  @override
  String get progressOutputPreviewLimited => '구조화된 출력의 처음 6,000자만 표시됩니다.';

  @override
  String progressRetryOf(String runId) {
    return '실행 $runId의 재시도';
  }

  @override
  String get progressContext => '컨텍스트 및 한도';

  @override
  String get progressNoAgent => '확인할 에이전트가 없습니다';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window토큰';
  }

  @override
  String get progressMeasured => '최근 호출에서 서비스 제공자가 보고한 컨텍스트';

  @override
  String get progressEstimated => '저장된 대화와 지속 컨텍스트를 바탕으로 추정';

  @override
  String get progressContextUnknown => '아직 컨텍스트 사용량이 보고되지 않았습니다';

  @override
  String progressContextPercent(String percent) {
    return '컨텍스트 창의 $percent%';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return '설정된 월간 에이전트 한도: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return '저장된 현재 대화: 예상 $tokens토큰';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return '$agent의 지속 컨텍스트 · $model';
  }

  @override
  String get progressContextSystem => '시스템 프롬프트';

  @override
  String get progressContextRules => '규칙';

  @override
  String get progressContextSkills => '스킬';

  @override
  String get progressContextTools => '도구 정의';

  @override
  String get progressContextMcp => 'MCP 도구';

  @override
  String get progressContextDeferred => '지연 로드 도구';

  @override
  String get progressContextSubagents => '서브에이전트';

  @override
  String get progressContextRunner => '외부 실행기';

  @override
  String get progressContextMemory => '메모리';

  @override
  String get progressContextHistory => '대화 기록';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens토큰';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens토큰';
  }

  @override
  String get progressOutputs => '최근 출력';

  @override
  String get progressNoOutputs => '최근 에이전트 출력이 없습니다';

  @override
  String get progressStructuredOutputsAbove => '구조화된 실행 출력은 위의 에이전트 실행에 표시됩니다.';

  @override
  String get progressRecentOutputsOnly => '최근 메시지만 표시됩니다. 이전 작업은 대화에서 확인하세요.';

  @override
  String get progressPlan => '계획';

  @override
  String get progressArtifact => '아티팩트';

  @override
  String get progressResult => '결과';

  @override
  String get progressHideArtifact => '아티팩트 숨기기';

  @override
  String get progressReadArtifact => '아티팩트 읽기';

  @override
  String get progressArtifactUnavailable => '아티팩트를 더 이상 사용할 수 없습니다';

  @override
  String get progressArtifactPreviewLimited => '이 아티팩트의 일부 미리보기만 표시됩니다.';

  @override
  String get progressDiagramSource => '다이어그램 소스';

  @override
  String progressOpenAttachment(String name) {
    return '$name 열기';
  }

  @override
  String get progressOpenPlan => '플랜 열기';

  @override
  String progressOpenDiff(String label) {
    return '변경된 파일 검토: $label';
  }

  @override
  String get progressViewMessage => '메시지 보기';

  @override
  String get pushTitle => '백그라운드 알림';

  @override
  String get pushIntro =>
      '앱이 닫혀 있어도 확인이 필요한 일이 생기면 개인 알림을 받습니다. 자세한 내용은 암호화된 연결 안에만 유지됩니다.';

  @override
  String get pushLoading => '알림 설정 확인 중…';

  @override
  String get pushError => '알림을 업데이트하지 못했습니다. 연결을 확인하고 다시 시도하세요.';

  @override
  String get pushEnable => '알림 활성화';

  @override
  String get pushDisable => '알림 끄기';

  @override
  String get pushQuiet => '이 기기의 알림 일시 중지';

  @override
  String get pushCategories => '알림 받을 항목';

  @override
  String get pushCategoryAgents => '에이전트';

  @override
  String get pushCategoryMessages => '메시지';

  @override
  String get pushCategoryPullRequests => '풀 리퀘스트';

  @override
  String get pushCategoryTickets => '티켓';

  @override
  String get pushCategoryCalendar => '캘린더';

  @override
  String get pushCategoryMachines => '머신';

  @override
  String get pushSecureOrigin => '알림을 사용하려면 HTTPS가 필요합니다.';

  @override
  String get pushInstallIos =>
      'iPhone 또는 iPad에서 알림을 사용하려면 이 앱을 홈 화면에 추가하고 홈 화면에서 여세요.';

  @override
  String get pushUnsupported => '이 브라우저는 백그라운드 알림을 지원하지 않습니다.';

  @override
  String get pushDenied =>
      '브라우저에서 알림이 차단된 것으로 보고합니다. 이 사이트의 권한과 브라우저 또는 기기의 알림 설정을 확인한 뒤 새로고침하세요.';

  @override
  String get pushOsHint => '브라우저도 기기의 시스템 설정에서 알림 표시 권한이 있어야 합니다.';

  @override
  String get pushServiceUnavailable =>
      '브라우저의 푸시 서비스가 구독을 거부했습니다. Brave 등 일부 브라우저는 기본적으로 이 서비스를 꺼 둡니다. 브라우저의 개인정보 설정에서 푸시 메시지 옵션을 찾은 후 다시 시도하세요.';

  @override
  String get pushWorkerUnavailable =>
      '이 브라우저에서 알림 서비스를 시작할 수 없습니다. 페이지를 새로고침한 후 다시 시도하세요.';

  @override
  String get pushResubscribe => '알림 다시 연결';

  @override
  String get pushStatusEnabled => '이 기기의 알림이 켜져 있습니다.';

  @override
  String get pushStatusDisabled => '이 기기의 알림이 꺼져 있습니다.';

  @override
  String get credentialsTitle => '연결 및 자격 증명';

  @override
  String get credentialsIntro =>
      '실행과 연동에 사용하는 계정을 연결하세요. 비밀 정보는 이 휴대전화가 아닌 서버에 저장됩니다.';

  @override
  String get credentialsModelProviders => '모델 제공업체';

  @override
  String get credentialsOwnerOnly =>
      '모델 제공업체의 자격 증명은 서버 소유자만 추가하거나 로그인하거나 제거할 수 있습니다. 이 키는 워크스페이스 간에 공유됩니다.';

  @override
  String get credentialsContactOwner =>
      '차단된 실행에 필요한 제공업체를 연결해 달라고 서버 소유자에게 요청하세요.';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'Claude Code는 호스트의 CLI에서 로그인합니다. 서버 소유자에게 호스트 터미널에서 계정 로그인을 완료하거나 갱신해 달라고 요청하세요. 이 휴대전화에서는 실행할 수 없습니다.';

  @override
  String get credentialsYourForgeAccounts => '내 코드 호스팅 계정';

  @override
  String get credentialsYourTicketingAccount => '내 티켓 서비스 계정';

  @override
  String get credentialsLocalTicketsNoLogin =>
      '로컬 티켓에는 로그인이 필요하지 않습니다. 워크스페이스에서 Linear를 사용한다면 여기에서 연결하세요.';

  @override
  String get credentialsMembershipRequired =>
      '코드 호스팅 또는 티켓 서비스 자격 증명을 관리하려면 워크스페이스에 가입하세요. 워크스페이스 관리자에게 접근 권한을 요청하세요.';

  @override
  String get credentialsSwitchWorkspace =>
      '이 링크는 다른 워크스페이스를 가리킵니다. 자격 증명을 변경하기 전에 해당 워크스페이스로 전환하세요.';

  @override
  String get credentialsReturnToInbox =>
      '자격 증명이 연결되면 받은 편지함으로 돌아가 차단된 실행을 다시 시도하세요. 호스트에서도 대기 중인 실행을 자동으로 확인합니다.';

  @override
  String get credentialsLoadFailed => '연결을 불러오지 못했습니다. 서버 연결을 확인하고 다시 시도하세요.';

  @override
  String get credentialsOperationFailed =>
      '이 연결을 변경하지 못했습니다. 서버 연결, 접근 권한, 자격 증명을 확인하고 다시 시도하세요.';

  @override
  String get credentialsConnected => '연결됨';

  @override
  String get credentialsNotConnected => '연결되지 않음';

  @override
  String credentialsSignedInAs(String username) {
    return '$username(으)로 로그인됨';
  }

  @override
  String get credentialsAccount => '연결된 계정';

  @override
  String get credentialsStoredKey => '저장된 키';

  @override
  String get credentialsActive => '활성';

  @override
  String get credentialsRemove => '제거';

  @override
  String get credentialsRemoveConfirm =>
      '저장된 자격 증명을 제거하시겠습니까? 다시 로그인해야 할 수 있습니다.';

  @override
  String get credentialsApiKey => 'API 키';

  @override
  String get credentialsApiKeyHint => '제공업체 API 키 붙여넣기';

  @override
  String get credentialsBrowserLogin => '브라우저에서 로그인';

  @override
  String get credentialsSignInAgain => '다시 로그인하세요';

  @override
  String get credentialsWaitingForLogin => '브라우저에서 승인 대기 중…';

  @override
  String get credentialsLoginTimedOut => '로그인 시간이 만료되었습니다. 다시 로그인해 보세요.';

  @override
  String get credentialsCopyCode => '코드 복사';

  @override
  String get credentialsDeviceCodeHint =>
      '제공업체 페이지에서 이 코드를 확인하세요. 서버에서 로그인을 완료할 때까지 이 화면을 열어 두세요.';

  @override
  String get credentialsPasteRedirect => '승인 코드 또는 리디렉션 URL';

  @override
  String get credentialsPasteRedirectHint => '제공업체의 코드 또는 전체 리디렉션 URL 붙여넣기';

  @override
  String get credentialsCompleteLogin => '로그인 완료';

  @override
  String get credentialsRedirectUnavailable =>
      '휴대전화에서 이 서버의 브라우저 콜백에 안전하게 접근할 수 없습니다. 서버 소유자에게 공개 HTTPS 콜백을 설정해 달라고 요청하거나 대신 토큰을 추가하세요.';

  @override
  String get credentialsUpdateToken => '토큰 업데이트';

  @override
  String get credentialsAddToken => '토큰 추가';

  @override
  String get credentialsPersonalToken => '개인용 액세스 토큰';

  @override
  String get credentialsPersonalTokenHint => '개인용 액세스 토큰 붙여넣기';

  @override
  String get credentialsHostManaged =>
      '이 연결은 서버 앱 또는 환경에서 제공됩니다. 서버 소유자만 해당 위치에서 변경할 수 있지만, 자신의 토큰은 추가할 수 있습니다.';

  @override
  String get credentialsStopWatching => '상태 확인 중지';

  @override
  String get transcriptClaudeSignInExpiredTitle => 'Claude Code 로그인이 만료되었습니다';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      '계정이 더 이상 인증되지 않아 실행이 중지되었습니다. 다시 로그인한 뒤 이 턴을 재시도하세요.';

  @override
  String get transcriptSignInExpiredTitle => '제공자 로그인이 만료되었습니다';

  @override
  String get transcriptSignInExpiredBody =>
      '제공자 자격 증명이 더 이상 작동하지 않아 실행이 중지되었습니다. 설정 → 제공자에서 다시 연결한 뒤 이 턴을 재시도하세요.';
}
