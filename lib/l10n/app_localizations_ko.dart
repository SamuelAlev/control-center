// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get succeeded => '성공';

  @override
  String agentRunRetryLabel(int number, String time) {
    return '재시도 #$number · $time';
  }

  @override
  String agentRunStarting(String time) {
    return '시작 중 · $time';
  }

  @override
  String get agentActivityFollowingLive => '실시간 활동 따라가는 중';

  @override
  String get agentActivityJumpToLatest => '최신으로 이동';

  @override
  String get agentActivityLoadFailed => '이 실행의 활동을 불러올 수 없습니다';

  @override
  String get agentActivityNotRecorded => '이 실행에 대해 기록된 활동이 없습니다';

  @override
  String get agentActivityNotRecordedHint =>
      '활동 캡처가 활성화되기 전에 완료된 실행에는 타임라인이 없습니다.';

  @override
  String get agentActivityRunUnavailable => '이 실행은 더 이상 사용할 수 없습니다';

  @override
  String agentActivitySubagentOf(String agent) {
    return '$agent의 하위 에이전트';
  }

  @override
  String get agentActivityUnsupported => '연결된 서버에서는 활동 캡처를 사용할 수 없습니다';

  @override
  String get agentActivityUnsupportedHint => '앱을 다시 시작해 최신 서버 빌드를 반영하세요.';

  @override
  String get agentActivityWaiting => '활동 대기 중…';

  @override
  String get created => '생성됨';

  @override
  String get dictationStart => '받아쓰기 시작';

  @override
  String get dictationListening => '듣고 있습니다…';

  @override
  String get dictationUnavailable =>
      '받아쓰기에는 서버 호스트에 음성 모델이 필요합니다. 음성 설정에서 설정하세요.';

  @override
  String get dictationFailedToStart => '받아쓰기를 시작할 수 없습니다';

  @override
  String get dictationHoldToTalkTitle => '눌러서 말하기';

  @override
  String get dictationHoldToTalkDescription =>
      '마이크 버튼이나 단축키를 누른 채로 말하고 놓으면 중지됩니다. 꺼 두면 한 번 눌러 시작하고 다시 눌러 중지합니다.';

  @override
  String get focusConversation => '대화 포커스';

  @override
  String get ideAgentActivity => '에이전트 활동';

  @override
  String get keybindingPushToTalk => '눌러서 말하기';

  @override
  String get keybindingPushToTalkDescription => '메시지 작성창에서 음성 받아쓰기 누르기 또는 토글';

  @override
  String get agentPermissions => '에이전트 권한';

  @override
  String get agentPermissionsSettingsDescription =>
      '에이전트가 스스로 할 수 있는 일, 먼저 물어야 하는 일, 절대 할 수 없는 일을 워크스페이스, 에이전트 또는 스페이스별로 정합니다.';

  @override
  String get agentPermissionsMatrixDescription =>
      '효과 유형별로 결정을 설정합니다. 규칙은 계단식으로 적용됩니다: 스페이스 > 에이전트 > 워크스페이스 > 모드 프리셋 순으로 재정의되며, 가장 구체적인 규칙이 우선합니다.';

  @override
  String get guardrailLoading => '규칙 불러오는 중…';

  @override
  String get guardrailRulesLoadFailed => '권한 규칙을 불러올 수 없습니다.';

  @override
  String get guardrailScopeWorkspace => '워크스페이스';

  @override
  String get guardrailScopeAgent => '에이전트';

  @override
  String get guardrailScopeSpace => '스페이스';

  @override
  String get guardrailSelectAgent => '에이전트 선택';

  @override
  String get guardrailSelectSpace => '스페이스 선택';

  @override
  String get guardrailNoAgents => '이 워크스페이스에는 아직 에이전트가 없습니다.';

  @override
  String get guardrailNoSpaces => '이 워크스페이스에는 아직 스페이스가 없습니다.';

  @override
  String get guardrailClassFileDelete => '파일 삭제';

  @override
  String get guardrailClassFileWriteOutsideWorktree => '워크트리 밖에 쓰기';

  @override
  String get guardrailClassGitCommit => '커밋 생성';

  @override
  String get guardrailClassGitPush => '리모트에 푸시';

  @override
  String get guardrailClassPrCreate => '풀 리퀘스트 열기';

  @override
  String get guardrailClassPrPublish => '리뷰 게시 또는 병합';

  @override
  String get guardrailClassVendorSyncWrite => '외부 트래커에 쓰기';

  @override
  String get guardrailClassNetworkEgress => '네트워크 접근';

  @override
  String get guardrailClassSecretAccess => '시크릿 읽기';

  @override
  String get guardrailClassPackageInstall => '패키지 설치';

  @override
  String get guardrailClassProcessSpawn => '프로세스 실행';

  @override
  String get guardrailClassWorkspaceMutation => '워크스페이스 구조 변경';

  @override
  String get guardrailClassEnclosureControl => '인클로저(rig) 조작';

  @override
  String get navRigs => '리그';

  @override
  String get rigsUnsupportedServer =>
      '이 서버는 rig 표면을 호스팅할 수 없습니다. 사용하려는 머신의 호스트 요구 사항을 확인하세요.';

  @override
  String get rigSurfaceComputer => '컴퓨터';

  @override
  String get rigSurfaceBrowser => '브라우저';

  @override
  String get rigSurfaceAndroid => 'Android';

  @override
  String get rigSurfaceIosSimulator => 'iOS 시뮬레이터';

  @override
  String rigSurfaceBrowserEngine(String engine) {
    return '$engine';
  }

  @override
  String rigBrowserEngineHint(String engine) {
    return '내 머신과 격리된 일회용 $engine입니다. 다른 엔진을 열어 같은 페이지를 나란히 비교할 수 있습니다.';
  }

  @override
  String get rigPhaseReady => '준비됨';

  @override
  String get rigPhaseStarting => '시작 중';

  @override
  String get rigPhaseParked => '대기 중';

  @override
  String get rigPhaseClosing => '종료 중';

  @override
  String get rigPhaseClosed => '종료됨';

  @override
  String get rigPhaseFailed => '실패';

  @override
  String get rigPhaseUnknown => '알 수 없음';

  @override
  String get rigNotAccelerated => '에뮬레이션됨';

  @override
  String get rigAudioListen => '머신 소리 듣기';

  @override
  String get rigAudioMute => '머신 음소거';

  @override
  String get rigYouHaveControl => '제어 권한이 있습니다';

  @override
  String get rigBackendAvailable => '사용 가능';

  @override
  String get rigBackendUnavailable => '사용 불가';

  @override
  String get rigEgressNotEnforced =>
      '이 백엔드에서는 네트워크가 격리되지 않습니다 — 자체적으로 연결을 관리합니다.';

  @override
  String get rigStartMachine => '머신 시작';

  @override
  String get rigStartHint =>
      '이 대화에서 사용자와 에이전트가 공유하는 일회용 VM을 시작합니다. 닫으면 삭제되며, 그 안의 어떤 것도 컴퓨터에 영향을 주지 않습니다.';

  @override
  String get rigStartAndroidHint =>
      '서버에서 이미 실행 중인 Android 에뮬레이터에 연결합니다. 네트워크 액세스는 격리되지 않습니다.';

  @override
  String get rigStartIosHint =>
      '서버의 Mac에 일회용 iOS Simulator를 생성합니다. 테스트 환경을 닫으면 삭제되며 네트워크 액세스는 격리되지 않습니다.';

  @override
  String get rigStopMachine => '머신 중지';

  @override
  String get rigSurfaceUnavailable => '이 서버는 이 종류의 머신을 호스팅할 수 없습니다.';

  @override
  String get rigTabNeedsConversation =>
      '먼저 대화를 여세요 — 머신은 하나의 대화에 속하므로 사용자와 에이전트가 같은 화면을 보게 됩니다.';

  @override
  String get ideMenuSectionTools => '도구';

  @override
  String get ideMenuSectionMachines => '머신';

  @override
  String get ideMenuSectionReopen => '다시 열기';

  @override
  String get ideMenuSearchHint => '검색';

  @override
  String get ideMenuNoMatches => '일치 항목 없음';

  @override
  String get rigMenuComputer => '컴퓨터';

  @override
  String get rigMenuBrowser => '브라우저';

  @override
  String get rigMenuAndroid => 'Android';

  @override
  String get rigMenuIosSimulator => 'iOS 시뮬레이터';

  @override
  String rigLabelNumbered(String label, String suffix) {
    return '$label $suffix';
  }

  @override
  String ideCloseKeepTitle(String name) {
    return '$name을(를) 닫을까요?';
  }

  @override
  String get ideCloseKeepBodyMachine =>
      '머신은 백그라운드에서 계속 실행됩니다 — 사이드바에서 언제든 다시 열 수 있습니다. 지금 메모리를 비우려면 종료하세요.';

  @override
  String get ideCloseKeepBodyShell =>
      '명령은 백그라운드에서 계속 실행됩니다 — 사이드바에서 언제든 셸을 다시 열 수 있습니다. 지금 하던 작업을 멈추려면 종료하세요.';

  @override
  String get ideCloseKeepBodyAgent =>
      '에이전트는 백그라운드에서 계속 작업합니다 — 사이드바에서 언제든 대화를 다시 열 수 있습니다. 지금 실행을 끝내려면 중지하세요.';

  @override
  String get ideCloseKeepRunning => '계속 실행';

  @override
  String get ideCloseShutDownMachine => '종료';

  @override
  String get ideCloseEndShell => '셸 종료';

  @override
  String get ideCloseStopAgent => '에이전트 중지';

  @override
  String get rigsSettingsSubtitle =>
      '이 서버가 부팅할 수 있는 것, 필요한 베이스 이미지, 현재 실행 중인 머신';

  @override
  String get rigsCapabilitiesTitle => '이 서버';

  @override
  String get rigInstallIosAutomation => 'iOS 자동화 브리지 설치';

  @override
  String get rigInstallingIosAutomation => 'iOS 자동화 브리지 설치 중…';

  @override
  String get rigIosAutomationInstalled => 'iOS 자동화 브리지 설치됨';

  @override
  String get rigsImagesTitle => '베이스 이미지';

  @override
  String get rigsImagesHint =>
      '모든 리그는 이 읽기 전용 이미지 중 하나로 부팅됩니다. 각 세션은 폐기 가능한 오버레이에 기록하므로 한 리그가 다음 리그의 시작점을 절대 바꿀 수 없습니다.';

  @override
  String get rigsRunningTitle => '지금 실행 중';

  @override
  String get rigsNoneRunning => '실행 중인 머신이 없습니다.';

  @override
  String get rigsCustomImagesTitle => '커스텀 이미지 (이 워크스페이스)';

  @override
  String get rigsCustomImagesHint =>
      '터미널(VM) 또는 브라우저(VM)에 자체 이미지를 지정하세요 — 필요한 도구로 기본 이미지를 확장하거나 레지스트리의 호환 이미지를 사용할 수 있습니다. 새 머신은 이 이미지를 사용하고 실행 중인 머신은 기존 이미지를 유지합니다. 이미지가 갖춰야 할 사항은 리그 가이드를 참고하세요.';

  @override
  String get rigsCustomTerminalImageLabel => '터미널 (VM) 이미지';

  @override
  String get rigsCustomBrowserImageLabel => '브라우저 (VM) 이미지';

  @override
  String get rigsCustomImagePlaceholder =>
      '예: ghcr.io/acme/dev-shell:1.2 — 비워 두면 기본값 사용';

  @override
  String get rigsCustomImageInvalid =>
      'repo/name:tag 형식의 레지스트리 참조를 입력하세요. 로컬 경로와 아카이브는 사용할 수 없습니다.';

  @override
  String get rigsCustomImageSaved =>
      '저장되었습니다. 새 머신은 이 이미지로 부팅되고 실행 중인 머신은 기존 이미지를 유지합니다.';

  @override
  String get rigsEgressTitle => '브라우저 이그레스 (이 워크스페이스)';

  @override
  String get rigsEgressHint =>
      '격리된 브라우저가 접근할 수 있는 추가 호스트 — 한 줄에 하나씩: 정확한 호스트(api.example.com) 또는 하위 도메인 와일드카드(*.example.com). 어떤 경우든 제품 사이트는 허용됩니다. 새 머신에는 이 목록이 적용되고 실행 중인 머신은 부팅 시의 목록을 유지합니다.';

  @override
  String rigsEgressInvalid(String host) {
    return '\"$host\"은(는) 유효한 호스트 항목이 아닙니다.';
  }

  @override
  String get rigsEgressSaved =>
      '저장되었습니다. 새 브라우저 머신은 이 호스트를 허용하고 실행 중인 머신은 기존 설정을 유지합니다.';

  @override
  String get rigImageInstalled => '설치됨';

  @override
  String get rigImageNotDownloaded => '다운로드 안 됨';

  @override
  String get rigImageNotPublished => '게시되지 않음';

  @override
  String get rigImageNotPublishedHint =>
      '아직 이에 대한 이미지가 게시되지 않아 다운로드할 것이 없습니다. 호환되는 디스크 이미지를 가져와 활성화하세요.';

  @override
  String get rigImageDownload => '다운로드';

  @override
  String get rigImageDownloading => '다운로드 중…';

  @override
  String get rigImageImport => '가져오기';

  @override
  String get rigImageImportMessage =>
      '서버 파일 시스템에 있는 qcow2 디스크 이미지의 경로입니다. 이미지 저장소로 복사되므로 이후에 파일을 옮겨도 됩니다.';

  @override
  String get rigConnectingStream => '리그에 연결하는 중';

  @override
  String get rigStreamNotAllowed => '이 리그에 접근할 권한이 없습니다.';

  @override
  String get rigStreamNotRunning => '이 리그는 더 이상 실행되지 않습니다.';

  @override
  String get rigStreamNeedsFfmpeg =>
      '라이브 뷰에는 이 호스트에 ffmpeg가 필요합니다. ffmpeg를 설치하고 탭을 다시 여세요.';

  @override
  String get rigStreamEnded => '라이브 뷰가 종료되었습니다.';

  @override
  String get rigStreamFailed => '라이브 뷰를 열 수 없습니다.';

  @override
  String get rigStreamDisconnected => '서버에 연결되어 있지 않습니다.';

  @override
  String rigDropSendingOne(String name) {
    return '\"$name\"을(를) 머신에 복사하는 중…';
  }

  @override
  String rigDropSendingMany(int count) {
    return '파일 $count개를 머신에 복사하는 중…';
  }

  @override
  String get rigTerminalDropSending => '머신에 복사하는 중…';

  @override
  String get rigTerminalPasteImage => '붙여넣은 이미지가 머신에 저장되었습니다';

  @override
  String get rigPortsTitle => '전달된 포트';

  @override
  String get rigPortsTooltip => '이 머신 내부에서 열린 포트';

  @override
  String get rigPortsEmpty =>
      '아직 수신 중인 것이 없습니다. 터미널에서 서버를 시작해 보세요 — 3000번 포트의 개발 서버가 여기에 나타납니다.';

  @override
  String get rigPortsAdd => '포트 추가';

  @override
  String get rigPortsAddHint => '전달할 게스트 포트 (예: 3000)';

  @override
  String get rigPortsAutoForward => '포트 자동 전달';

  @override
  String get rigPortsCopyUrl => '로컬 URL 복사';

  @override
  String rigPortsCopiedUrl(String url) {
    return '$url 복사됨';
  }

  @override
  String get rigPortsStopForward => '전달 중지';

  @override
  String get rigPortsExposeLan => '로컬 네트워크에서 공유';

  @override
  String get rigPortsLanPrivate => '로컬 전용';

  @override
  String get rigPortsLanShared => '네트워크에서';

  @override
  String get rigPortsSetDomain => '브라우저 도메인 설정 (.test)';

  @override
  String get rigPortsDomainHint =>
      '브라우저(VM)용 도메인, 예: myapp.test — 거기서는 접근 가능하고 호스트에서는 불가';

  @override
  String get rigPortsProcessUnknown => '알 수 없는 프로세스';

  @override
  String get rigPortsInactive => '수신 중 아님';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '베이스 이미지 $count개 다운로드 필요',
      one: '베이스 이미지 1개 다운로드 필요',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => '허용';

  @override
  String get guardrailDecisionPrompt => '먼저 묻기';

  @override
  String get guardrailDecisionDeny => '거부';

  @override
  String get guardrailSourceThisScope => '이 범위';

  @override
  String get guardrailSourceDefault => '내장 기본값';

  @override
  String get guardrailSourcePreset => '모드 프리셋';

  @override
  String get guardrailSourceInherited => '상속됨';

  @override
  String get guardrailClearToInherited => '상속값으로 초기화';

  @override
  String get guardrailWhatIf => '어떻게 될까요?';

  @override
  String get guardrailWhatIfDescription =>
      '에이전트에 적용되는 것과 동일한 로직으로 현재 규칙이 작업을 어떻게 판정하는지 확인하세요.';

  @override
  String get guardrailProbeActionLabel => '작업';

  @override
  String get guardrailProbeCommandLabel => '명령 (선택)';

  @override
  String get guardrailProbeCommandHint => '예: git push origin main';

  @override
  String get guardrailProbeAgentLabel => '에이전트 (선택)';

  @override
  String get guardrailProbeSpaceLabel => '스페이스 (선택)';

  @override
  String get guardrailProbeNone => '없음';

  @override
  String get guardrailProbeModeLabel => '모드';

  @override
  String get guardrailProbeResult => '결과';

  @override
  String get guardrailProbeSource => '출처:';

  @override
  String get guardrailAdapterMatrix => '규칙이 적용되는 위치';

  @override
  String get guardrailAdapterMatrixDescription =>
      '정직한 참고 자료: 에이전트 러너별로 각 효과가 실제로 어디서 잡히는지 보여줍니다. 실제 동작을 문서화한 것이지 보장이 아닙니다 — 러너가 대역 밖에서 수행하는 효과는 가로챌 수 없습니다.';

  @override
  String get guardrailEffectColumn => '효과';

  @override
  String get guardrailAdapterHarness => '기본 제공 하네스';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => '샌드박스 하한';

  @override
  String get guardrailEnforcementPolicyGate => '정책 게이트';

  @override
  String get guardrailEnforcementSandbox => '샌드박스만';

  @override
  String get guardrailEnforcementNone => '적용 불가';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      '권한 결정은 효과가 실행되기 전에 확인되며 차단할 수 있습니다.';

  @override
  String get guardrailEnforcementSandboxHelp => '샌드박스만 제한하며, 권한 규칙은 참조되지 않습니다.';

  @override
  String get guardrailEnforcementNoneHelp => '결정은 참고용일 뿐입니다 — 여기서는 가로챌 수 없습니다.';

  @override
  String get obsStatCost => '비용';

  @override
  String obsStatDelegatedCost(String amount) {
    return '+$amount 위임됨';
  }

  @override
  String get obsStatDuration => '소요 시간';

  @override
  String get obsStatTokens => '토큰';

  @override
  String get obsStatTools => '도구';

  @override
  String get openAgentActivity => '활동 열기';

  @override
  String get orgChart => '조직도';

  @override
  String get orgChartEmpty => '아직 에이전트가 없습니다';

  @override
  String get navCalendar => '캘린더';

  @override
  String get serverConnection => '서버 연결';

  @override
  String get serverModeLocal => '이 앱에서 실행';

  @override
  String get serverModeLocalDescription =>
      'Control Center가 이 머신에서 자체 서버를 실행하며 데이터를 로컬에서 소유합니다.';

  @override
  String get serverModeRemote => '원격 인스턴스에 연결';

  @override
  String get serverModeRemoteDescription =>
      '다른 곳에서 실행 중인 Control Center 서버에 연결합니다. 데이터는 해당 서버에 보관됩니다.';

  @override
  String get serverRemoteUrl => '서버 URL';

  @override
  String get serverRemoteDeviceId => '기기 ID';

  @override
  String get serverRemotePairingKey => '페어링 키';

  @override
  String get serverRemotePairingKeyHint => '원격 서버의 페어링 키를 붙여넣으세요';

  @override
  String get serverSetupInviteCode => '초대 코드';

  @override
  String get serverSetupInviteCodeHint => '일회용 초대 코드를 붙여넣으세요 (비워 두면 페어링 키 사용)';

  @override
  String get serverDiscoveryTooltip => '네트워크에서 서버 찾기';

  @override
  String get serverDiscoveryTitle => '네트워크의 서버';

  @override
  String get serverDiscoverySearching => '서버 검색 중…';

  @override
  String get serverDiscoveryEmpty =>
      '서버를 찾을 수 없습니다. 서버가 실행 중이고 이 기기가 접근할 수 있는지 확인한 다음 다시 검색하세요.';

  @override
  String get serverDiscoveryRefresh => '다시 검색';

  @override
  String get serverListActive => '활성';

  @override
  String get serverListSwitch => '전환';

  @override
  String get serverListAddTitle => '서버 추가';

  @override
  String get serverListRemoveActiveHint => '이 서버를 제거하기 전에 다른 서버로 전환하세요.';

  @override
  String get serverSwitchFailedTitle => '서버를 전환할 수 없습니다';

  @override
  String get serverListInsecureBadge => '안전하지 않음';

  @override
  String get connectionPathLocal => '로컬';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => '종료 중';

  @override
  String get shutdownSubtitle => '로컬 서버를 닫는 중';

  @override
  String get shutdownServiceApprovals => '승인';

  @override
  String get shutdownServiceBackgroundJobs => '백그라운드 작업';

  @override
  String get shutdownServiceScheduler => '작업 스케줄러';

  @override
  String get shutdownServiceCalendar => '캘린더 동기화';

  @override
  String get shutdownServiceWeather => '날씨';

  @override
  String get shutdownServiceSoundscape => '사운드스케이프';

  @override
  String get shutdownServiceMeetings => '회의';

  @override
  String get shutdownServiceVoiceModels => '음성 모델';

  @override
  String get shutdownServiceNetworking => '네트워킹';

  @override
  String get shutdownServicePresence => '프레즌스';

  @override
  String get shutdownServiceDataSync => '데이터 동기화';

  @override
  String get shutdownServiceDeviceRelay => '기기 릴레이';

  @override
  String get shutdownServiceMcpConnections => 'MCP 연결';

  @override
  String get shutdownServiceCodeEditors => '코드 에디터';

  @override
  String get serverSharingTitle => '이 서버 공유';

  @override
  String get serverSharingDescription =>
      '이 서버를 다른 기기에서 접근할 수 있게 만듭니다. 아래에서 터널을 켜지 않는 한 아무것도 공개되지 않습니다. 페어링 초대에는 서버의 현재 주소가 자동으로 포함됩니다 — 워크스페이스 설정에서 만드세요.';

  @override
  String get serverSharingUnavailable => '이 서버에서는 공유 컨트롤을 사용할 수 없습니다.';

  @override
  String get serverSharingMdnsLabel => 'LAN 검색';

  @override
  String get serverSharingMdnsOn => '로컬 네트워크에 이 서버를 알리는 중 (mDNS)';

  @override
  String get serverSharingMdnsOff => '로컬 네트워크에 알리지 않는 중 (mDNS)';

  @override
  String get serverSharingTunnelLabel => '터널';

  @override
  String get serverSharingTunnelHelper =>
      '터널을 켜면 인터넷에서 이 서버에 접근할 수 있습니다. 공개는 선택 사항이며 기본적으로 꺼져 있습니다.';

  @override
  String get serverSharingProviderOff => '꺼짐';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => '공개 URL';

  @override
  String get serverSharingTunnelStarting => '터널 시작하는 중…';

  @override
  String serverSharingTunnelError(String error) {
    return '터널 오류: $error';
  }

  @override
  String get serverSharingTunnelUpNoUrl =>
      '터널이 작동 중입니다. 구성한 DNS 호스트 이름으로 접근하세요.';

  @override
  String get serverSharingRelayLabel => '릴레이';

  @override
  String serverSharingRelayUsage(String amount) {
    return '이번 달 릴레이 사용량: $amount';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return '활성 릴레이 세션: $count';
  }

  @override
  String get serverSharingUpdateFailedTitle => '공유 설정을 업데이트할 수 없습니다';

  @override
  String get pairNewClient => '새 클라이언트 페어링';

  @override
  String get pairClientNameHint => '이 클라이언트의 이름 (예: 회사 노트북)';

  @override
  String get pairClientTypeWeb => '웹 브라우저';

  @override
  String get pairClientTypeDesktop => '데스크톱 앱';

  @override
  String get pairClientTypePhone => '휴대폰';

  @override
  String get pairAction => '페어링';

  @override
  String get revoke => '해지';

  @override
  String get pairCredentialsIntro => '새 클라이언트를 이 정보로 연결하거나, 클라이언트에서 링크를 여세요.';

  @override
  String get pairLinkLabel => '링크';

  @override
  String get pairScanQr => '휴대폰 카메라로 이 QR 코드를 스캔해 페어링하세요.';

  @override
  String get pairServerUnreachableTitle => '접근 불가';

  @override
  String get pairServerUnreachable =>
      '다른 기기가 이 서버에 직접 접근할 수 없어 새 클라이언트를 연결할 수 없습니다. 클라이언트를 더 페어링하려면 서버의 공개 URL을 설정하세요.';

  @override
  String get serverSetupTitle => 'Control Center를 어떻게 실행할까요?';

  @override
  String get serverSetupSubtitle =>
      'Control Center에는 데이터를 소유하는 서버가 필요합니다. 앱 내에서 실행하거나 다른 곳에서 실행 중인 인스턴스에 연결하세요.';

  @override
  String get serverSetupRunLocal => '이 앱에서 실행';

  @override
  String get serverSetupConnect => '연결';

  @override
  String get serverSetupInvalidUrl => '유효한 ws:// 또는 wss:// 서버 URL을 입력하세요.';

  @override
  String get serverSetupCouldNotConnect => '연결할 수 없습니다';

  @override
  String get serverSetupErrorUnreachable =>
      '서버에 연결할 수 없습니다. 서버가 실행 중이고 이 기기가 접근 가능한지 확인하세요 (같은 네트워크 또는 릴레이).';

  @override
  String get serverSetupErrorIdentityMismatch =>
      '서버의 신원이 이 기기에 저장된 것과 일치하지 않습니다. 서버를 재설치했거나 초기화한 경우 저장된 서버를 제거하고 다시 페어링하세요.';

  @override
  String get serverSetupErrorAuthRejected =>
      '서버가 이 기기를 거부했습니다. 페어링 키와 기기 ID가 서버가 발급한 것과 일치하는지 확인하세요.';

  @override
  String get serverSetupErrorInviteRejected =>
      '초대 코드가 유효하지 않거나 만료되었습니다. 새 코드를 요청하세요.';

  @override
  String get serverSetupErrorGeneric =>
      '연결 중 문제가 발생했습니다. 자세한 내용은 아래 기술 세부 정보를 펼쳐 확인하세요.';

  @override
  String get serverSetupErrorDetails => '기술 세부 정보';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 더',
      one: '1개 더',
    );
    return '$_temp0';
  }

  @override
  String get calendarAllDayGutter => '종일';

  @override
  String calendarAllDayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '일정 $count개',
      one: '일정 1개',
    );
    return '$_temp0';
  }

  @override
  String get calendarCollapseAllDay => '종일 일정 접기';

  @override
  String get calendarExpandAllDay => '종일 일정 펼치기';

  @override
  String get calendarViewMonth => '월';

  @override
  String get calendarViewWeek => '주';

  @override
  String get calendarViewAgenda => '아젠다';

  @override
  String get calendarConnectGoogle => 'Google Calendar 연결';

  @override
  String get calendarConnectDescription =>
      'Google Calendar를 동기화해 여기서 일정을 보고 회의 시작 전 알림을 받으세요.';

  @override
  String get calendarDisconnect => '연결 해제';

  @override
  String get calendarReconnect => '다시 연결';

  @override
  String get calendarEmptyNoEvents => '이 범위에 일정이 없습니다';

  @override
  String get calendarStartRecording => '녹음 시작';

  @override
  String get calendarStartRecordingAndLink => '녹음 시작 및 연결';

  @override
  String get calendarJoinMeet => '회의 참가';

  @override
  String get calendarFromCalendar => '캘린더에서';

  @override
  String get calendarLinkedMeeting => '연결된 회의';

  @override
  String get calendarToday => '오늘';

  @override
  String get calendarAllDay => '종일';

  @override
  String calendarWeekNumber(int number) {
    return '$number주차';
  }

  @override
  String get calendarPreviousPeriod => '이전';

  @override
  String get calendarNextPeriod => '다음';

  @override
  String calendarLastSynced(String time) {
    return '$time에 동기화됨';
  }

  @override
  String get calendarNeverSynced => '아직 동기화되지 않음';

  @override
  String get calendarSyncing => '동기화 중…';

  @override
  String get calendarViewDay => '일';

  @override
  String get calendarShow => '표시';

  @override
  String get calendarHide => '숨기기';

  @override
  String get calendarRsvpGoing => '참석하시나요?';

  @override
  String get calendarRsvpYes => '예';

  @override
  String get calendarRsvpNo => '아니요';

  @override
  String get calendarRsvpMaybe => '미정';

  @override
  String get calendarRsvpFailed => '응답을 업데이트할 수 없습니다';

  @override
  String get calendarAddAccount => '캘린더 계정 추가';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Google 계정을 연결해 이 워크스페이스로 일정을 동기화하세요.';

  @override
  String get calendarConnecting => '연결 중…';

  @override
  String get calendarSyncNow => '지금 동기화';

  @override
  String get calendarNoWorkspace => '캘린더를 보려면 워크스페이스를 선택하세요';

  @override
  String get calendarConnectError => 'Google Calendar에 연결할 수 없습니다';

  @override
  String get calendarClientIdLabel => '클라이언트 ID';

  @override
  String get calendarClientSecretLabel => '클라이언트 시크릿';

  @override
  String get calendarConnectCredsHint =>
      '프로젝트의 Google OAuth 기기 코드 클라이언트 ID와 시크릿을 입력하세요. 서버가 연결과 동기화를 실행합니다 — 브라우저는 토큰을 절대 보관하지 않습니다.';

  @override
  String get calendarConnectApproveInstruction =>
      '아무 기기에서나 확인 페이지를 열고 로그인한 후 이 코드를 입력하세요:';

  @override
  String get calendarConnectOpenPage => '확인 페이지 열기';

  @override
  String get calendarConnectWaiting => '승인 대기 중…';

  @override
  String get calendarConnectDenied => '인증이 거부되었습니다. 다시 시도해 주세요.';

  @override
  String get calendarConnectExpired => '코드가 만료되었습니다. 다시 시도해 주세요.';

  @override
  String get notificationMeetingStartsSoon => '회의가 곧 시작됩니다';

  @override
  String get notifyMeetingStartsSoon => '캘린더 회의가 곧 시작될 때';

  @override
  String get notificationCalendarAuthExpiredTitle => '캘린더 연결 해제됨';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return '동기화를 재개하려면 $email 계정을 다시 연결하세요';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      '동기화를 재개하려면 캘린더를 다시 연결하세요';

  @override
  String get notifyCalendarAuthExpired => '캘린더 계정을 다시 연결해야 할 때';

  @override
  String get notificationRigStatusChanged => '인클로저 업데이트';

  @override
  String get notifyRigStatusChanged => '인클로저가 점유되거나 회수되거나 실패할 때';

  @override
  String get notificationRigTakenOver => '인클로저 점유됨';

  @override
  String get notificationRigTakenOverBody =>
      '사람이 머신을 조작하고 있습니다. 에이전트는 지켜보기만 할 수 있고 조작할 수 없습니다.';

  @override
  String get notificationRigReleased => '인클로저 제어 해제됨';

  @override
  String get notificationRigReleasedBody => '에이전트가 머신을 다시 받았습니다.';

  @override
  String get notificationRigReclaimed => '인클로저 회수됨';

  @override
  String get notificationRigReclaimedBodyIdle =>
      '유휴 상태로 있어 메모리를 확보하려고 머신이 종료되었습니다.';

  @override
  String get notificationRigReclaimedBodyTtl => '시간 제한에 도달해 종료되었습니다.';

  @override
  String get notificationRigFailed => '인클로저 실패';

  @override
  String get notificationRigFailedBody => '하이퍼바이저가 중단되었습니다. 계속하려면 머신을 다시 여세요.';

  @override
  String get calendarAlertLeadTime => '사전 알림 시간';

  @override
  String get calendarAlertLeadTimeSubtitle => '회의 시작 얼마 전에 알릴지';

  @override
  String calendarConnectedAs(String email) {
    return '$email(으)로 연결됨';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '참석자 $count명';
  }

  @override
  String get calendarEventLabel => '일정';

  @override
  String get calendarRecurring => '반복 일정';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => '주최자';

  @override
  String get calendarYou => '나';

  @override
  String get calendarShowFewer => '간략히 보기';

  @override
  String get calendarRsvpAwaiting => '대기 중';

  @override
  String calendarParticipantsCount(int count) {
    return '참가자 $count명';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return '참가자 $count명 모두 보기';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count명 참석';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count명 불참';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count명 미정';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count명 대기 중';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count분';
  }

  @override
  String get openInEditorPrompt => '어떤 에디터에서 열까요?';

  @override
  String get ideNotInstalled => '설치되지 않음';

  @override
  String openInIde(String editor) {
    return '$editor에서 열기';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return '$editor을(를) 열 수 없습니다: $error';
  }

  @override
  String get profileSearchHint => '풀 리퀘스트 검색…';

  @override
  String get stopAgentRun => '실행 중지';

  @override
  String get stopAgentRunConfirm => '이 실행을 중지할까요? 진행 중인 작업은 사라집니다.';

  @override
  String get inProgress => '진행 중';

  @override
  String get drafts => '초안';

  @override
  String get sortOldest => '오래된순';

  @override
  String get sortLargest => '큰순';

  @override
  String get prFilterTooltip => '필터';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '활성 필터 $count개',
      one: '활성 필터 1개',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => '필터 추가…';

  @override
  String get prFilterFieldHint => '필터…';

  @override
  String get prFilterCategoryStatus => '상태';

  @override
  String get prFilterCategoryAuthor => '작성자';

  @override
  String get prFilterCategoryReviewer => '리뷰어';

  @override
  String get prFilterCategoryContent => '내용';

  @override
  String get prFilterCategoryRepoOwner => '리포지토리 소유자';

  @override
  String get prFilterCategoryRepoName => '리포지토리 이름';

  @override
  String get prFilterCategoryOpenedDate => '열린 날짜';

  @override
  String get prFilterCategoryUpdatedDate => '업데이트 날짜';

  @override
  String get prFilterQuickToReview => '빠르게 리뷰 가능';

  @override
  String get prFilterClearAll => '필터 지우기';

  @override
  String prFilterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '풀 리퀘스트 $count개',
      one: '풀 리퀘스트 1개',
    );
    return '$_temp0';
  }

  @override
  String prFilterHiddenOptions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '풀 리퀘스트와 일치하지 않는 옵션 $count개',
      one: '풀 리퀘스트와 일치하지 않는 옵션 1개',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => '제목 또는 본문에 포함…';

  @override
  String get prFilterNoOptions => '일치하는 옵션 없음';

  @override
  String get prFilterChipIs => '일치';

  @override
  String get prFilterChipIsAnyOf => '다음 중 하나';

  @override
  String get prFilterChipContains => '포함';

  @override
  String get prFilterChipSince => '이후';

  @override
  String get prFilterAddFilterButton => '필터 추가';

  @override
  String prFilterClearCategory(String category) {
    return '$category 필터 지우기';
  }

  @override
  String get prFilterCurrentUser => '현재 사용자';

  @override
  String get prStatusDraft => '초안';

  @override
  String get prStatusOpen => '열림';

  @override
  String get prStatusInReview => '리뷰 중';

  @override
  String get prStatusChangesRequested => '변경 요청됨';

  @override
  String get prStatusApproved => '승인됨';

  @override
  String get prStatusMerged => '병합됨';

  @override
  String get prStatusClosed => '닫힘';

  @override
  String get prDateWindowDay => '1일 전';

  @override
  String get prDateWindowThreeDays => '3일 전';

  @override
  String get prDateWindowWeek => '1주 전';

  @override
  String get prDateWindowMonth => '1개월 전';

  @override
  String get prDateWindowThreeMonths => '3개월 전';

  @override
  String get prDateWindowSixMonths => '6개월 전';

  @override
  String get prDateWindowYear => '1년 전';

  @override
  String get prDisplayOptions => '표시 옵션';

  @override
  String get prDisplayGrouping => '그룹화';

  @override
  String get prDisplayOrdering => '정렬';

  @override
  String get prDisplayShowDrafts => '초안 표시';

  @override
  String get prDisplayMergedWindow => '병합 기간';

  @override
  String get prDisplayMergedWindowDay => '지난 1일';

  @override
  String get prDisplayMergedWindowWeek => '지난 1주';

  @override
  String get prDisplayMergedWindowMonth => '지난 1개월';

  @override
  String get prDisplayProperties => '표시 속성';

  @override
  String get prGroupingRepository => '리포지토리';

  @override
  String get prGroupingAuthor => '작성자';

  @override
  String get prGroupingStatus => '상태';

  @override
  String get prGroupingNone => '그룹화 없음';

  @override
  String get prPropertyRepository => '리포지토리';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => '브랜치';

  @override
  String get prPropertyUpdated => '업데이트';

  @override
  String get prPropertyAuthor => '작성자';

  @override
  String get prPropertyChecks => '검사';

  @override
  String get prPropertyDiff => 'Diff';

  @override
  String get prPropertyComments => '댓글';

  @override
  String get keybindingOpenFilterMenu => '필터 메뉴 열기';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      '풀 리퀘스트 필터 메뉴 열기';

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 선택됨',
      one: '1개 선택됨',
    );
    return '$_temp0';
  }

  @override
  String get summary => '요약';

  @override
  String get kbMove => '이동';

  @override
  String get kbTabs => '탭';

  @override
  String get kbSearch => '검색';

  @override
  String get kbViewed => '확인';

  @override
  String get kbCollapse => '접기';

  @override
  String get appearance => '화면';

  @override
  String get appearanceSettingsDescription => '테마, 언어, 타이포그래피.';

  @override
  String get notificationsSettingsDescription =>
      '어떤 에이전트 및 워크스페이스 이벤트의 알림을 받을지 선택하세요.';

  @override
  String get advanced => '고급';

  @override
  String get accounts => '계정';

  @override
  String get mcpServers => 'MCP 서버';

  @override
  String get mcpServersSettingsDescription => '기본 제공 MCP 서버와 외부 MCP 서버.';

  @override
  String get remoteControlAndDevices => '원격 제어 및 기기';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      '휴대폰을 페어링하고 원격 제어 서버를 구성합니다.';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      '이 서버가 호스팅하는 음성 및 화자 분리 모델입니다.';

  @override
  String get needsSetupLabel => '설정 필요';

  @override
  String get collapseSidebar => '사이드바 접기';

  @override
  String get expandSidebar => '사이드바 펼치기';

  @override
  String get filterSpacesHint => '스페이스 필터';

  @override
  String noSpacesMatch(String query) {
    return '\"$query\"와 일치하는 스페이스가 없습니다';
  }

  @override
  String get privacy => '개인정보';

  @override
  String get sendDiffContentTitle => 'AI 어댑터에 diff 내용 전송';

  @override
  String get diffSharingOnSubtitle =>
      '더 깊은 리뷰를 위해 원시 diff 줄이 에이전트 프롬프트에 포함됩니다.';

  @override
  String get diffSharingOffSubtitle =>
      '에이전트는 구조화된 메타데이터(파일 경로, 줄 번호, PR 설명)만 사용합니다. 원시 코드는 앱을 벗어나지 않습니다.';

  @override
  String get errorReportingTitle => '크래시 리포트 공유';

  @override
  String get errorReportingOnSubtitle =>
      '버그 수정을 돕기 위해 크래시, 오류, 성능 진단이 전송됩니다 (릴리스 빌드만).';

  @override
  String get errorReportingOffSubtitle =>
      '진단이 꺼져 있습니다. 크래시나 오류 리포트가 전송되지 않습니다.';

  @override
  String get onboardingDiagnosticsTitle => 'Control Center 개선 돕기';

  @override
  String get onboardingDiagnosticsSubtitle =>
      '더 빠른 문제 해결을 위해 크래시, 오류, 성능 진단을 보내주세요 (릴리스 빌드만). 설정 → 개인정보에서 언제든 변경할 수 있습니다.';

  @override
  String get blocked => '차단됨';

  @override
  String get idle => '유휴';

  @override
  String get noRunsYet => '아직 실행 없음';

  @override
  String get copyPath => '경로 복사';

  @override
  String get copyRelativePath => '상대 경로 복사';

  @override
  String get nameRequired => '이름은 필수입니다';

  @override
  String get import => '가져오기';

  @override
  String get sortByStatus => '상태';

  @override
  String get sortByName => '이름';

  @override
  String get noMatchingAgents => '필터와 일치하는 에이전트가 없습니다';

  @override
  String watchVideoOn(String provider) {
    return '$provider에서 영상 보기';
  }

  @override
  String get branchTemplate => '브랜치 이름 템플릿';

  @override
  String get branchTemplateDescription =>
      '티켓이 격리된 워크트리에서 시작될 때 만들어지는 브랜치의 패턴입니다.';

  @override
  String branchTemplatePreview(String example) {
    return '예: $example';
  }

  @override
  String get deletePipelineRun => '파이프라인 실행 삭제';

  @override
  String deletePipelineRunConfirm(String template) {
    return '\"$template\"의 이 실행을 삭제할까요? 되돌릴 수 없습니다.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return '파이프라인 실행 삭제 오류: $error';
  }

  @override
  String get deleteTicket => '티켓 삭제';

  @override
  String deleteTicketConfirm(String title) {
    return '\"$title\"을(를) 삭제할까요? 되돌릴 수 없습니다.';
  }

  @override
  String errorDeletingTicket(String error) {
    return '티켓 삭제 오류: $error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return '\"$name\"을(를) 삭제할까요? 디스크의 연결된 리포지토리는 변경되지 않습니다.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return '워크스페이스 삭제 오류: $error';
  }

  @override
  String get indexCode => '코드 인덱싱';

  @override
  String get indexNoGrammars => '코드 문법이 설치되지 않았습니다';

  @override
  String get indexFailed => '인덱싱 실패';

  @override
  String indexedSymbolsCount(int count) {
    return '기호 $count개 인덱싱됨';
  }

  @override
  String get nodeConfigAdvanced => '고급';

  @override
  String get nodeConfigReducer => '리듀서';

  @override
  String get nodeConfigReducerHelp => '이 출력 키에 이미 값이 있을 때 병합하는 방법';

  @override
  String get nodeConfigTimeoutMs => '시간 제한 (ms)';

  @override
  String get nodeConfigRetryAttempts => '재시도 횟수';

  @override
  String get nodeConfigContinueOnFail => '이 단계가 실패해도 계속';

  @override
  String get nodeConfigTeamId => '팀 ID';

  @override
  String get nodeConfigDispatchMode => '디스패치 모드';

  @override
  String get nodeConfigOutputSchema => '출력 스키마 (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp => '단계 출력이 충족해야 하는 JSON 스키마';

  @override
  String get diffLineDisplay => 'diff의 긴 줄 처리';

  @override
  String get diffLineDisplayDescription => '긴 줄을 줄바꿈하거나 가로로 스크롤';

  @override
  String get diffLineWrap => '줄바꿈';

  @override
  String get diffLineScroll => '가로 스크롤';

  @override
  String get actions => '작업';

  @override
  String get activate => '활성화';

  @override
  String get activity => '활동';

  @override
  String get activityLabel => '활동';

  @override
  String get activitySearchHint => '활동 검색';

  @override
  String get activityNoMatches => '필터와 일치하는 활동이 없습니다';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$total개 중 $start–$end';
  }

  @override
  String get activityPreviousPage => '이전 페이지';

  @override
  String get activityNextPage => '다음 페이지';

  @override
  String get activityNetworkLocal => '로컬호스트';

  @override
  String get activityClearFilter => '필터 지우기';

  @override
  String activityFilterIp(String ip) {
    return 'IP $ip';
  }

  @override
  String activityFilterCountry(String country) {
    return '국가 $country';
  }

  @override
  String get activitySavedWorkspaceLogo => '워크스페이스 로고 저장됨';

  @override
  String activityVerbCreated(String target) {
    return '$target 생성됨';
  }

  @override
  String activityVerbUpdated(String target) {
    return '$target 업데이트됨';
  }

  @override
  String activityVerbDeleted(String target) {
    return '$target 삭제됨';
  }

  @override
  String activityVerbAdded(String target) {
    return '$target 추가됨';
  }

  @override
  String activityVerbRemoved(String target) {
    return '$target 제거됨';
  }

  @override
  String activityVerbInvited(String target) {
    return '$target 초대됨';
  }

  @override
  String activityVerbChanged(String target) {
    return '$target 변경됨';
  }

  @override
  String activityVerbStarted(String target) {
    return '$target 시작됨';
  }

  @override
  String activityVerbStopped(String target) {
    return '$target 중지됨';
  }

  @override
  String activityVerbWrote(String target) {
    return '$target 작성됨';
  }

  @override
  String get activityTargetAgent => '에이전트';

  @override
  String get activityTargetTicket => '티켓';

  @override
  String get activityTargetWorkspace => '워크스페이스';

  @override
  String get activityTargetRepository => '리포지토리';

  @override
  String get activityTargetMember => '멤버';

  @override
  String get activityTargetInvite => '초대';

  @override
  String get activityTargetSpace => '스페이스';

  @override
  String get activityTargetMessage => '메시지';

  @override
  String get activityTargetCache => '캐시';

  @override
  String get activityTargetFile => '파일';

  @override
  String get activityTargetPipeline => '파이프라인';

  @override
  String get activityTargetTemplate => '템플릿';

  @override
  String get activityTargetProvider => '공급자';

  @override
  String get activityTargetModel => '모델';

  @override
  String get activityTargetSkill => '스킬';

  @override
  String get activityTargetTodo => '할 일';

  @override
  String get activityTargetMeeting => '회의';

  @override
  String get activityTargetProject => '프로젝트';

  @override
  String get activityTargetTeam => '팀';

  @override
  String get activityTargetDevice => '기기';

  @override
  String get activityTargetPreference => '환경설정';

  @override
  String get activityTargetBudget => '예산';

  @override
  String activityVerbApproved(String target) {
    return '$target 승인됨';
  }

  @override
  String activityVerbArchived(String target) {
    return '$target 보관됨';
  }

  @override
  String activityVerbAssigned(String target) {
    return '$target 할당됨';
  }

  @override
  String activityVerbBackedUp(String target) {
    return '$target 백업됨';
  }

  @override
  String activityVerbCancelled(String target) {
    return '$target 취소됨';
  }

  @override
  String activityVerbCleared(String target) {
    return '$target 초기화됨';
  }

  @override
  String activityVerbClosed(String target) {
    return '$target 닫힘';
  }

  @override
  String activityVerbCommitted(String target) {
    return '$target 커밋됨';
  }

  @override
  String activityVerbCompacted(String target) {
    return '$target 압축됨';
  }

  @override
  String activityVerbCompleted(String target) {
    return '$target 완료됨';
  }

  @override
  String activityVerbConnected(String target) {
    return '$target 연결됨';
  }

  @override
  String activityVerbContinued(String target) {
    return '$target 계속됨';
  }

  @override
  String activityVerbDisconnected(String target) {
    return '$target 연결 해제됨';
  }

  @override
  String activityVerbDispatched(String target) {
    return '$target 디스패치됨';
  }

  @override
  String activityVerbDrained(String target) {
    return '$target 비워짐';
  }

  @override
  String activityVerbEnrolled(String target) {
    return '$target 등록됨';
  }

  @override
  String activityVerbEstimated(String target) {
    return '$target 추정됨';
  }

  @override
  String activityVerbImported(String target) {
    return '$target 가져옴';
  }

  @override
  String activityVerbInstalled(String target) {
    return '$target 설치됨';
  }

  @override
  String activityVerbKilled(String target) {
    return '$target 강제 종료됨';
  }

  @override
  String activityVerbMarked(String target) {
    return '$target 표시됨';
  }

  @override
  String activityVerbMerged(String target) {
    return '$target 병합됨';
  }

  @override
  String activityVerbOpened(String target) {
    return '$target 열림';
  }

  @override
  String activityVerbPaused(String target) {
    return '$target 일시중지됨';
  }

  @override
  String activityVerbPolled(String target) {
    return '$target 폴링됨';
  }

  @override
  String activityVerbPrepared(String target) {
    return '$target 준비됨';
  }

  @override
  String activityVerbProcessed(String target) {
    return '$target 처리됨';
  }

  @override
  String activityVerbPublished(String target) {
    return '$target 게시됨';
  }

  @override
  String activityVerbRefined(String target) {
    return '$target 정제됨';
  }

  @override
  String activityVerbRefreshed(String target) {
    return '$target 새로 고침됨';
  }

  @override
  String activityVerbRegistered(String target) {
    return '$target 등록됨';
  }

  @override
  String activityVerbRenamed(String target) {
    return '$target 이름 변경됨';
  }

  @override
  String activityVerbReordered(String target) {
    return '$target 순서 변경됨';
  }

  @override
  String activityVerbResponded(String target) {
    return '$target에 응답됨';
  }

  @override
  String activityVerbRestored(String target) {
    return '$target 복원됨';
  }

  @override
  String activityVerbResumed(String target) {
    return '$target 재개됨';
  }

  @override
  String activityVerbRetried(String target) {
    return '$target 재시도됨';
  }

  @override
  String activityVerbReverted(String target) {
    return '$target 되돌림';
  }

  @override
  String activityVerbReviewed(String target) {
    return '$target 리뷰됨';
  }

  @override
  String activityVerbRan(String target) {
    return '$target 실행됨';
  }

  @override
  String activityVerbSelected(String target) {
    return '$target 선택됨';
  }

  @override
  String activityVerbSent(String target) {
    return '$target 전송됨';
  }

  @override
  String activityVerbStaged(String target) {
    return '$target 스테이징됨';
  }

  @override
  String activityVerbSteered(String target) {
    return '$target 조정됨';
  }

  @override
  String activityVerbSubmitted(String target) {
    return '$target 제출됨';
  }

  @override
  String activityVerbSynced(String target) {
    return '$target 동기화됨';
  }

  @override
  String activityVerbToggled(String target) {
    return '$target 토글됨';
  }

  @override
  String activityVerbUninstalled(String target) {
    return '$target 설치 제거됨';
  }

  @override
  String activityVerbUnstaged(String target) {
    return '$target 스테이징 해제됨';
  }

  @override
  String get activityTargetActionPolicy => '작업 정책';

  @override
  String get activityTargetGoalRun => '목표 실행';

  @override
  String get activityTargetRunLog => '실행 로그';

  @override
  String get activityTargetWorkingMemory => '작업 메모리';

  @override
  String get activityTargetRoutingPolicy => '라우팅 정책';

  @override
  String get activityTargetAutonomy => '자율성';

  @override
  String get activityTargetCalendar => '캘린더';

  @override
  String get activityTargetChecker => '검사기';

  @override
  String get activityTargetEditor => '에디터';

  @override
  String get activityTargetConfirmation => '확인';

  @override
  String get activityTargetTunnel => '터널';

  @override
  String get activityTargetConversation => '대화';

  @override
  String get activityTargetCredentials => '자격 증명';

  @override
  String get activityTargetDictation => '받아쓰기';

  @override
  String get activityTargetAgentRun => '에이전트 실행';

  @override
  String get activityTargetEvalSuite => '평가 스위트';

  @override
  String get activityTargetWorker => '워커';

  @override
  String get activityTargetWorktree => '워크트리';

  @override
  String get activityTargetMcpServer => 'MCP 서버';

  @override
  String get activityTargetMemoryAccessGrant => '메모리 접근 권한';

  @override
  String get activityTargetMemoryDomain => '메모리 도메인';

  @override
  String get activityTargetMemoryFact => '메모리 팩트';

  @override
  String get activityTargetMemoryPolicy => '메모리 정책';

  @override
  String get activityTargetFeed => '피드';

  @override
  String get activityTargetNote => '노트';

  @override
  String get activityTargetOrchestration => '오케스트레이션';

  @override
  String get activityTargetPipelineRun => '파이프라인 실행';

  @override
  String get activityTargetPipelineTrigger => '파이프라인 트리거';

  @override
  String get activityTargetPlan => '계획';

  @override
  String get activityTargetPlaybook => '플레이북';

  @override
  String get activityTargetPullRequest => '풀 리퀘스트';

  @override
  String get activityTargetReview => '리뷰';

  @override
  String get activityTargetProcess => '프로세스';

  @override
  String get activityTargetProviderPolicy => '공급자 정책';

  @override
  String get activityTargetReaction => '리액션';

  @override
  String get activityTargetReviewSpace => '리뷰 스페이스';

  @override
  String get activityTargetReviewStudio => '리뷰 스튜디오';

  @override
  String get activityTargetServerData => '서버 데이터';

  @override
  String get activityTargetSoundscape => '사운드스케이프';

  @override
  String get activityTargetSession => '세션';

  @override
  String get activityTargetTerminal => '터미널';

  @override
  String get activityTargetTicketLink => '티켓 링크';

  @override
  String get activityTargetTicketSync => '티켓 동기화';

  @override
  String get activityTargetProfile => '프로필';

  @override
  String get activityTargetVoiceProfile => '음성 프로필';

  @override
  String get activityTargetWeather => '일기예보';

  @override
  String get activityTargetWorkProduct => '작업 산출물';

  @override
  String get activityChangedMemberRole => '멤버 역할 변경됨';

  @override
  String get activityChangedMemberRepoAccess => '멤버의 리포지토리 접근 권한 변경됨';

  @override
  String get activityUpdatedGitHubToken => 'GitHub 토큰 업데이트됨';

  @override
  String get activityRefreshedWeather => '일기예보 새로 고침됨';

  @override
  String get activitySetWeatherLocation => '날씨 위치 설정됨';

  @override
  String get activityClearedWeatherLocation => '날씨 위치 초기화됨';

  @override
  String get activityMarkedAllArticlesRead => '모든 아티클 읽음으로 표시됨';

  @override
  String get activityMarkedArticleRead => '아티클 읽음으로 표시됨';

  @override
  String get activityUpdatedSavedArticle => '저장된 아티클 업데이트됨';

  @override
  String get activityTookOverSession => '세션 인수됨';

  @override
  String get activityHandedBackSession => '세션 반납됨';

  @override
  String get activityCommittedAndPushed => '커밋 및 푸시됨';

  @override
  String get activityBackedUpServer => '서버 데이터 백업됨';

  @override
  String get activityMarkedSpaceRead => '스페이스 읽음으로 표시됨';

  @override
  String get activityRespondedToInvitation => '일정 초대 응답됨';

  @override
  String get activityStartedCalendarConnect => '캘린더 연결 시작됨';

  @override
  String get activityDisconnectedCalendar => '캘린더 연결 해제됨';

  @override
  String get activityMarkedFileViewed => '파일 확인 표시됨';

  @override
  String get activityRespondedToApproval => '승인 요청 응답됨';

  @override
  String get activityChangedTunnel => '터널 설정 변경됨';

  @override
  String get activitySentMessageToAgent => '에이전트에 메시지 전송됨';

  @override
  String get activityOpenedReviewSpace => '리뷰 스페이스 열림';

  @override
  String get activityOpenedStandingConversation => '상시 대화 열림';

  @override
  String get activityStartedRecording => '녹음 시작됨';

  @override
  String get activityStoppedRecording => '녹음 중지됨';

  @override
  String get activityToggledMcpServer => 'MCP 서버 토글됨';

  @override
  String get activityUpdatedMcpToken => 'MCP 토큰 업데이트됨';

  @override
  String get activitySavedApiKey => 'API 키 저장됨';

  @override
  String get activityRemovedProviderCredential => '공급자 자격 증명 제거됨';

  @override
  String get activityUpdatedLinkedRepos => '연결된 리포지토리 업데이트됨';

  @override
  String get activityUnlinkedRepo => '리포지토리 연결 해제됨';

  @override
  String get activityUpdatedActionItem => '액션 아이템 업데이트됨';

  @override
  String adRulesCount(int count) {
    return '광고 규칙 $count개';
  }

  @override
  String get adapter => '어댑터';

  @override
  String get adapterLabel => '어댑터';

  @override
  String get adapters => '어댑터';

  @override
  String get adaptersAutoDetected =>
      '이 머신에서 사용 가능한 에이전트 러너가 자동 감지되었습니다. 추가 러너를 사용하려면 누락된 CLI 도구를 설치하세요.';

  @override
  String get add => '추가';

  @override
  String get addAComment => '댓글 추가';

  @override
  String get addAReaction => '리액션 추가';

  @override
  String get addASuggestion => '제안 추가';

  @override
  String get addAgents => '에이전트 추가';

  @override
  String get addEmoji => '이모지 추가';

  @override
  String get addFeed => '피드 추가';

  @override
  String get addressBarHint => 'URL 입력';

  @override
  String get addFromFile => '파일에서 추가';

  @override
  String get addGif => 'GIF 추가';

  @override
  String get addGithubRepoPrompt => '풀 리퀘스트를 보려면 GitHub 리포지토리를 하나 이상 추가하세요';

  @override
  String get addLocalCheckoutDescription =>
      '로컬 체크아웃을 추가해 이 워크스페이스에서 대상으로 지정할 수 있습니다.';

  @override
  String get addRepository => '리포지토리 추가';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '리포지토리 $count개 추가',
      one: '리포지토리 추가',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro =>
      '서버가 실행 중인 머신의 폴더를 탐색하고 등록할 git 체크아웃을 선택하세요.';

  @override
  String get selectThisFolder => '이 폴더 선택';

  @override
  String get deselectThisFolder => '이 폴더 선택 해제';

  @override
  String get goUp => '위로';

  @override
  String get noSubfoldersHere => '여기에는 하위 폴더가 없습니다';

  @override
  String get notAGitRepository => '이 폴더는 git 리포지토리가 아닙니다.';

  @override
  String get addToken => '토큰 추가';

  @override
  String get addWorkspace => '워크스페이스 추가';

  @override
  String get addWorkspaceEllipsis => '워크스페이스 추가…';

  @override
  String get added => '추가됨';

  @override
  String get addingEllipsis => '추가하는 중…';

  @override
  String get advancedLabel => '고급';

  @override
  String get agent => '에이전트';

  @override
  String agentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개의 에이전트',
      one: '$count개의 에이전트',
    );
    return '$_temp0';
  }

  @override
  String get agentMdPath => '에이전트 MD 경로';

  @override
  String get agentName => '에이전트 이름';

  @override
  String get agentTitle => '에이전트 제목';

  @override
  String get agentUpdated => '에이전트가 업데이트되었습니다.';

  @override
  String get agents => '에이전트';

  @override
  String get agentsMentionSection => '에이전트';

  @override
  String get usersMentionSection => '사람';

  @override
  String get ticketsMentionSection => '티켓';

  @override
  String get pullRequestsMentionSection => '풀 리퀘스트';

  @override
  String get meetingsMentionSection => '회의';

  @override
  String get entityRefTicketFallback => '티켓';

  @override
  String get entityRefPrFallback => '풀 리퀘스트';

  @override
  String get entityRefMeetingFallback => '회의';

  @override
  String get aiReview => 'AI 리뷰';

  @override
  String get all => '전체';

  @override
  String get allAgentsAlreadyInSpace => '모든 에이전트가 이미 이 스페이스에 있습니다.';

  @override
  String get allCommits => '모든 커밋';

  @override
  String get allSources => '모든 소스';

  @override
  String get allow => '허용';

  @override
  String get allowGitPush => 'git push 허용';

  @override
  String get allowGithubApi => 'GitHub API 호출 허용';

  @override
  String get allowNetwork => '일반 네트워크 접근 허용';

  @override
  String get apiKeys => 'API 키';

  @override
  String get appFont => '앱 글꼴';

  @override
  String get appLogLevelDebugDescription => '상세 트레이스를 추가합니다 - 개발용.';

  @override
  String get appLogLevelDebugLabel => '디버그';

  @override
  String get appLogLevelErrorDescription => '예기치 않은 오류와 예외만 기록합니다.';

  @override
  String get appLogLevelErrorLabel => '오류';

  @override
  String get appLogLevelInfoDescription => '라이프사이클 및 상태 메시지를 추가합니다.';

  @override
  String get appLogLevelInfoLabel => '정보';

  @override
  String get appLogLevelNoneDescription => '콘솔 출력이 전혀 없습니다.';

  @override
  String get appLogLevelNoneLabel => '없음';

  @override
  String get appLogLevelVerboseDescription =>
      '모든 것을 기록합니다. 매우 시끄럽습니다 - 디버깅용으로만 사용하세요.';

  @override
  String get appLogLevelVerboseLabel => '상세';

  @override
  String get appLogLevelWarningDescription => '경고와 복구 가능한 문제를 추가합니다.';

  @override
  String get appLogLevelWarningLabel => '경고';

  @override
  String get appearanceLanguage => '화면 및 언어';

  @override
  String get apply => '적용';

  @override
  String get approve => '승인';

  @override
  String get agentApprovalRequired => '승인 필요';

  @override
  String agentApprovalsMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 더 대기 중',
      one: '1개 더 대기 중',
    );
    return '$_temp0';
  }

  @override
  String get approved => '승인됨';

  @override
  String get articleNoun => '기사';

  @override
  String get articlesSubscribed => '구독 중인 피드의 아티클입니다.';

  @override
  String get askAi => 'AI에게 물어보기';

  @override
  String get askAiReviewDescription => 'AI에게 이 PR 리뷰를 요청';

  @override
  String get assignees => '담당자';

  @override
  String get attachFiles => '파일 첨부';

  @override
  String get attachImage => '이미지 첨부';

  @override
  String get attachedAgents => '첨부된 에이전트';

  @override
  String get audioInput => '오디오 입력';

  @override
  String get audioOutput => '오디오 출력';

  @override
  String get authenticationToken => '인증 토큰';

  @override
  String authoredByLabel(String role) {
    return '작성자: $role';
  }

  @override
  String get autoRecommended => '자동 (권장)';

  @override
  String get available => '사용 가능';

  @override
  String get awaitingYourReview => '리뷰 대기 중';

  @override
  String get back => '뒤로';

  @override
  String get backLabel => '뒤로';

  @override
  String get backend => '백엔드';

  @override
  String get blockAdsTrackers => '광고, 트래커 및 쿠키 배너 차단';

  @override
  String get blocking => '차단 중';

  @override
  String get bookmarkLabel => '북마크';

  @override
  String get briefDescription => '간단한 설명';

  @override
  String get bugLabel => '버그';

  @override
  String get bundledDefaultsNeverUpdated => '번들 기본값 — 업데이트되지 않음';

  @override
  String get cancel => '취소';

  @override
  String get cancelEdit => '편집 취소';

  @override
  String get categoryCreation => '생성';

  @override
  String get categoryEditing => '편집';

  @override
  String get categoryNavigation => '탐색';

  @override
  String get categorySystem => '시스템';

  @override
  String get categoryView => '카테고리 보기';

  @override
  String get change => '변경';

  @override
  String get changesRequested => '변경 요청됨';

  @override
  String get spacesMentionSection => '스페이스';

  @override
  String get checkForUpdates => '업데이트 확인';

  @override
  String get checking => '확인 중';

  @override
  String get checkingEllipsis => '확인 중…';

  @override
  String get chooseAppFont => '앱 글꼴 선택';

  @override
  String get chooseCodeFont => '코드 글꼴 선택';

  @override
  String get chooseRunner => '에이전트 러너를 선택하세요.';

  @override
  String get clear => '지우기';

  @override
  String get clickToRetry => '클릭해서 재시도';

  @override
  String get close => '닫기';

  @override
  String get closeEsc => '닫기 (Esc)';

  @override
  String get closeKeyboardHint => '닫기';

  @override
  String get closeReader => '리더 닫기';

  @override
  String get closed => '닫힘';

  @override
  String get codeFont => '코드 글꼴';

  @override
  String get codeFontLigatures => '코드 글꼴 합자';

  @override
  String get codeFontLigaturesDescription =>
      '코드와 diff에서 프로그래밍 합자(=>, !=, ->)를 결합 글자로 렌더링';

  @override
  String get collapse => '접기';

  @override
  String get commandPalette => '커맨드 팔레트';

  @override
  String get commandPaletteOrgMembers => '조직 멤버';

  @override
  String get commandPaletteBrowseTeam => '팀 탐색';

  @override
  String get commandPaletteBrowseTeamDesc => '모든 조직 멤버 보기';

  @override
  String get compactDone => '대화가 압축되었습니다. 이전 기록이 요약으로 합쳐졌습니다.';

  @override
  String get compactNothing => '아직 압축할 것이 없습니다. 대화가 아직 짧습니다.';

  @override
  String get compactBusy => '에이전트가 아직 작업 중입니다. 턴이 끝나면 압축하세요.';

  @override
  String get compactUnavailable => '이 서버에서는 압축을 사용할 수 없습니다.';

  @override
  String get commandsMentionSection => '명령';

  @override
  String get comment => '댓글';

  @override
  String get commentOnThisFile => '이 파일에 댓글 달기';

  @override
  String get commented => '댓글 달림';

  @override
  String get commits => '커밋';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return '전체 $total개 커밋 중 최신 $loaded개 표시 중';
  }

  @override
  String get prCloneProgressCloningTitle => '리포지토리 클론하는 중';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return '이 PR은 $fileCount개 파일을 변경해 GitHub API 한도를 초과합니다. 리포지토리를 로컬로 클론하는 중…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      '이 PR은 GitHub API 파일 한도를 초과합니다. 리포지토리를 로컬로 클론하는 중…';

  @override
  String get prCloneProgressFetchingTitle => 'PR ref 가져오는 중';

  @override
  String get prCloneProgressFetchingSubtitle => '베이스 브랜치와 PR head ref를 가져오는 중…';

  @override
  String get prCloneProgressComputingTitle => 'diff 계산하는 중';

  @override
  String get prCloneProgressComputingSubtitle => '로컬에서 git diff 실행 중…';

  @override
  String get prCloneProgressErrorTitle => 'diff를 불러오지 못했습니다';

  @override
  String get prCloneProgressErrorSubtitle =>
      '클론 또는 diff 계산 중 오류가 발생했습니다. 새로 고침해 보세요.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return '계속 작업 중… $elapsed 경과';
  }

  @override
  String confidenceLabel(int percent) {
    return '신뢰도: $percent%';
  }

  @override
  String get configureAgentIdentities => '에이전트 신원, 프롬프트, 스킬을 구성하고 실행을 확인하세요.';

  @override
  String get configureDefaultRunners =>
      '새 스페이스와 제목 생성에 어떤 어댑터와 모델을 사용할지 구성합니다.';

  @override
  String get configuredLabel => '구성되었습니다.';

  @override
  String get confirmedBy => '확인한 사람';

  @override
  String get consensus => '합의';

  @override
  String get contentHint => '기억해야 할 내용';

  @override
  String get contentLabel => '내용';

  @override
  String get contentMarkdown => '내용 (Markdown)';

  @override
  String get contextWindowSize => '컨텍스트 윈도우 크기';

  @override
  String modelContextChip(String size) {
    return '모델 · $size';
  }

  @override
  String get continueLabel => '계속';

  @override
  String get conversationMode => '모드';

  @override
  String cookieRulesCount(int count) {
    return '쿠키 규칙 $count개';
  }

  @override
  String get copied => '복사했습니다!';

  @override
  String get copy => '복사';

  @override
  String get copyAddress => '주소 복사';

  @override
  String get copyBaseBranchTooltip => '베이스 브랜치 이름 복사';

  @override
  String get copyHeadBranchTooltip => '헤드 브랜치 이름 복사';

  @override
  String couldNotListDevices(String error) {
    return '기기를 나열할 수 없습니다: $error';
  }

  @override
  String get create => '만들기';

  @override
  String get createOrSelectWorkspace => '리포지토리를 추가하기 전에 워크스페이스를 만들거나 선택하세요.';

  @override
  String get createPullRequest => '풀 리퀘스트 만들기';

  @override
  String get createdByMe => '내가 만듦';

  @override
  String createdLabel(String date) {
    return '생성: $date';
  }

  @override
  String get currentParticipants => '현재 참가자';

  @override
  String get customCapabilitiesDescription => '커스텀 기능 설명';

  @override
  String get customSystemPrompt => '이 에이전트의 커스텀 시스템 프롬프트...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일 전',
      one: '1일 전',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => '비활성화';

  @override
  String get defaultCapabilities => '기본 기능 · 새 스페이스';

  @override
  String get defaultChat => '기본 채팅';

  @override
  String get defaultRunners => '기본 러너';

  @override
  String get delete => '삭제';

  @override
  String get deleteAgent => '에이전트 삭제';

  @override
  String deleteAgentConfirm(String name) {
    return '\"$name\"을(를) 삭제할까요? 되돌릴 수 없습니다.';
  }

  @override
  String get deleteSpace => '스페이스 삭제';

  @override
  String deleteConfirmName(String name) {
    return '\"$name\"을(를) 삭제할까요?';
  }

  @override
  String get archiveConversation => '대화 보관';

  @override
  String get deleteFact => '팩트 삭제';

  @override
  String get deleteFeedBody =>
      '피드와 캐시된 모든 아티클이 제거됩니다. 이 피드에서 북마크한 아티클도 함께 제거됩니다.';

  @override
  String deleteFeedConfirm(String name) {
    return '\"$name\"을(를) 삭제할까요?';
  }

  @override
  String get deletePolicy => '정책 삭제';

  @override
  String get deletePolicyConfirm => '이 정책을 삭제할까요? 되돌릴 수 없습니다.';

  @override
  String deleteTopicConfirm(String topic) {
    return '\"$topic\"을(를) 삭제할까요? 되돌릴 수 없습니다.';
  }

  @override
  String get deleteWorkspace => '워크스페이스 삭제';

  @override
  String get deny => '거부';

  @override
  String get detailsLabel => '세부정보';

  @override
  String get descriptionLabel => '설명';

  @override
  String detectedBackend(String label) {
    return '감지됨: $label';
  }

  @override
  String get detectedRunners => '감지된 러너';

  @override
  String get detectingAdapters => '어댑터 감지하는 중…';

  @override
  String get detectingInputDevices => '입력 기기 감지하는 중…';

  @override
  String detectionFailed(String error) {
    return '감지 실패: $error';
  }

  @override
  String get disabled => '비활성화됨';

  @override
  String get discover => '탐색';

  @override
  String get dismissed => '해제됨';

  @override
  String get domainHint => '예: api-performance';

  @override
  String get domainLabel => '도메인';

  @override
  String get download => '다운로드';

  @override
  String get downloadingLabel => '다운로드 중';

  @override
  String downloadingModel(int pct) {
    return '모델 다운로드 중… $pct%';
  }

  @override
  String get draft => '초안';

  @override
  String get draftLabel => '초안';

  @override
  String get edit => '편집';

  @override
  String get edited => '편집됨';

  @override
  String get editMessage => '메시지 편집';

  @override
  String get deleteMessage => '메시지 삭제';

  @override
  String get deleteMessageConfirm => '이 메시지를 삭제할까요? 되돌릴 수 없습니다.';

  @override
  String get messageDeleted => '메시지가 삭제되었습니다';

  @override
  String get searchInConversation => '대화에서 검색';

  @override
  String get searchMessagesHint => '메시지 검색…';

  @override
  String get noMessagesFound => '메시지를 찾을 수 없습니다';

  @override
  String get editFact => '팩트 편집';

  @override
  String get editPolicy => '정책 편집';

  @override
  String get editSuggestedCodeHint => '제안된 코드 편집…';

  @override
  String get editSuggestion => '제안 편집';

  @override
  String get egArchitect => '예: architect';

  @override
  String get egControlCenter => '예: control-center';

  @override
  String get egPlatform => '예: macOS';

  @override
  String get egSamuelAlev => '예: SamuelAlev';

  @override
  String get egSoftwareArchitect => '예: Software Architect';

  @override
  String get egTheVerge => '예: The Verge';

  @override
  String get egTokenLimit => '예: 128000';

  @override
  String embeddingInstallFailed(String error) {
    return '설치 실패: $error';
  }

  @override
  String get embeddingInstalled => '로컬 임베딩 모델이 설치되었습니다. 하이브리드 검색이 활성화되었습니다.';

  @override
  String get embeddingModel => '임베딩 모델 (ONNX)';

  @override
  String get embeddingNotInstalled =>
      '설치되지 않았습니다. 활성화할 때까지 검색은 키워드 전용으로 작동합니다.';

  @override
  String get embeddingRedownloadBody =>
      '기존 모델 파일이 삭제되고 다시 다운로드됩니다. 다운로드가 완료될 때까지 시맨틱 검색을 사용할 수 없습니다.';

  @override
  String get embeddingRemoveBody =>
      '다시 설치할 때까지 시맨틱 검색이 비활성화됩니다. 언제든 다시 설치할 수 있습니다.';

  @override
  String get speakerDiarization => '화자 분리';

  @override
  String get diarizationModel => '화자 분리 모델';

  @override
  String get diarizationInstalled => '설치됨 — 회의 녹취록에서 개별 화자를 구분합니다';

  @override
  String get diarizationNotInstalled => '설치되지 않음 — 회의 화자가 구분되지 않습니다';

  @override
  String diarizationInstallFailed(String error) {
    return '설치 실패: $error';
  }

  @override
  String get redownloadDiarizationModel => '화자 분리 모델 다시 다운로드';

  @override
  String get diarizationRedownloadBody => '현재 화자 분리 모델을 제거하고 다시 다운로드합니다.';

  @override
  String get removeDiarizationModel => '화자 분리 모델 제거';

  @override
  String get diarizationRemoveBody =>
      '기기 내 화자 분리 모델을 삭제합니다. 이미 만들어진 회의 녹취록은 영향을 받지 않습니다.';

  @override
  String get enableNotifications => '알림 활성화';

  @override
  String get enableSandboxing => '샌드박싱 활성화';

  @override
  String get enabled => '활성화됨';

  @override
  String errorCreatingAgent(String error) {
    return '에이전트 생성 오류: $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return '에이전트 삭제 오류: $error';
  }

  @override
  String errorWithDetail(String error) {
    return '오류: $error';
  }

  @override
  String get expand => '펼치기';

  @override
  String extractingModel(int pct) {
    return '모델 추출 중… $pct%';
  }

  @override
  String get fact => '팩트';

  @override
  String factCount(int count) {
    return '팩트 $count개';
  }

  @override
  String factCountPlural(int count) {
    return '팩트 $count개';
  }

  @override
  String get facts => '팩트';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '팩트 $factCount개 · 정책 $policyCount개';
  }

  @override
  String get failed => '실패';

  @override
  String failedToDispatch(String error) {
    return '디스패치 실패: $error';
  }

  @override
  String get failedToLoad => '불러오기 실패';

  @override
  String failedToLoadAgents(String error) {
    return '에이전트 불러오기 실패: $error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return '피드 불러오기 실패: $error';
  }

  @override
  String get failedToLoadGifs => 'GIF 불러오기 실패';

  @override
  String failedToLoadLogs(String error) {
    return '로그 불러오기 실패: $error';
  }

  @override
  String get failedToLoadRepos => '리포지토리 불러오기 실패';

  @override
  String get failedToLoadWorkspaces => '워크스페이스 불러오기 실패';

  @override
  String failedToStartAiReview(String error) {
    return 'AI 리뷰 시작 실패: $error';
  }

  @override
  String get failedToStartMicTest => '마이크 테스트를 시작하지 못했습니다.';

  @override
  String failedToSubmitReview(String error) {
    return '리뷰 제출 실패: $error';
  }

  @override
  String failedToUpload(String name, String error) {
    return '$name 업로드 실패: $error';
  }

  @override
  String failedWithError(String error) {
    return '실패: $error';
  }

  @override
  String get failure => '실패';

  @override
  String get feedAlreadyExists => '이 URL의 피드가 이미 있습니다.';

  @override
  String get feedUrlExample => '예: https://example.com/feed.xml';

  @override
  String get feedUrlLabel => '피드 URL';

  @override
  String feedsCount(int count) {
    return '피드 ($count)';
  }

  @override
  String get filesChanged => '변경된 파일';

  @override
  String filesCount(int count) {
    return '파일 $count개';
  }

  @override
  String get filesMentionSection => '파일';

  @override
  String get filterAgents => '에이전트 필터...';

  @override
  String get filterFilesHint => '파일 필터…';

  @override
  String get filterLists => '목록 필터';

  @override
  String get filterSkillsPlaceholder => '스킬 필터…';

  @override
  String get finish => '완료';

  @override
  String get fix => '수정';

  @override
  String get forward => '앞으로';

  @override
  String get gatesGithubPatPush => 'GitHub PAT 주입을 제어합니다. 에이전트가 푸시하려면 필요합니다.';

  @override
  String get general => '일반';

  @override
  String get githubLink => 'GitHub 링크';

  @override
  String get claudeStatusFetchFailed => 'status.claude.com에 연결할 수 없습니다';

  @override
  String get claudeStatusOpenInBrowser => 'status.claude.com 열기';

  @override
  String get githubStatusFetchFailed => 'githubstatus.com에 연결할 수 없습니다';

  @override
  String get githubDegradedTitle => 'GitHub에 문제가 발생했습니다';

  @override
  String githubDegradedStatusLine(String status) {
    return 'GitHub 상태: $status.';
  }

  @override
  String githubDegradedBody(String status) {
    return 'GitHub 상태: $status. 복구될 때까지 풀 리퀘스트 데이터가 오래되었거나 불완전할 수 있습니다.';
  }

  @override
  String get githubStatusOpenInBrowser => 'githubstatus.com 열기';

  @override
  String get githubStatusRefresh => '새로 고침';

  @override
  String githubStatusUpdated(String time) {
    return '$time에 업데이트됨';
  }

  @override
  String get kimiStatusFetchFailed => 'status.moonshot.cn에 연결할 수 없습니다';

  @override
  String get kimiStatusOpenInBrowser => 'status.moonshot.cn 열기';

  @override
  String get openaiStatusFetchFailed => 'status.openai.com에 연결할 수 없습니다';

  @override
  String get openaiStatusOpenInBrowser => 'status.openai.com 열기';

  @override
  String get serviceStatusMaintenance => '유지 보수';

  @override
  String get serviceStatusMajorIssues => '주요 문제';

  @override
  String get serviceStatusMinorIssues => '경미한 문제';

  @override
  String get serviceStatusOperational => '정상';

  @override
  String get serviceStatusOutage => '중단';

  @override
  String get serviceStatusTitle => '서비스 상태';

  @override
  String get serviceStatusUnknown => '알 수 없음';

  @override
  String lastChecked(String time) {
    return '$time에 확인됨';
  }

  @override
  String get lastCheckedRecently => '최근에 확인됨';

  @override
  String get giveYourWorkAHome => '작업에 집을 마련하세요.';

  @override
  String get goBack => '뒤로 가기';

  @override
  String get goForward => '앞으로 가기';

  @override
  String get googleFonts => 'Google 글꼴';

  @override
  String get high => '높음';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count시간 전',
      one: '1시간 전',
    );
    return '$_temp0';
  }

  @override
  String get images => '이미지';

  @override
  String get inactive => '비활성';

  @override
  String get install => '설치';

  @override
  String get installRequired => '설치 필요';

  @override
  String installedVersion(String version) {
    return '$version 설치됨';
  }

  @override
  String get invite => '초대';

  @override
  String get inviteAgent => '에이전트 초대';

  @override
  String get isolateAgentExecution => '에이전트 실행을 격리합니다.';

  @override
  String get justNow => '방금';

  @override
  String get keepSandboxing => '샌드박싱 유지';

  @override
  String get keybindingAddARepositoryDescription => '리포지토리 추가';

  @override
  String get keybindingAddRepository => '리포지토리 추가';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      '선택한 아티클 북마크 또는 해제';

  @override
  String get keybindingCommandPalette => '커맨드 팔레트';

  @override
  String get keybindingCreateANewAgentDescription => '새 에이전트 만들기';

  @override
  String get keybindingCreateANewWorkspaceDescription => '새 워크스페이스 만들기';

  @override
  String get keybindingFocusSearch => '검색 포커스';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      '풀 리퀘스트 검색 창에 포커스';

  @override
  String get keybindingNewAgent => '새 에이전트';

  @override
  String get keybindingNewWorkspace => '새 워크스페이스';

  @override
  String get keybindingNextArticle => '다음 아티클';

  @override
  String get keybindingNextSpace => '다음 스페이스';

  @override
  String get keybindingNextWorkspace => '다음 워크스페이스';

  @override
  String get keybindingOpenArticle => '아티클 열기';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      '사이드바의 워크스페이스 전환 팝업 열기 또는 닫기';

  @override
  String get keybindingOpenPr => 'PR 열기';

  @override
  String get keybindingOpenSettings => '설정 열기';

  @override
  String get keybindingOpenTheApplicationSettingsDescription => '애플리케이션 설정 열기';

  @override
  String get keybindingOpenTheCommandPaletteDescription => '커맨드 팔레트 열기';

  @override
  String get keybindingOpenTheSelectedArticleDescription => '선택한 아티클 열기';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription => '선택한 풀 리퀘스트 열기';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription => '선택한 워크스페이스 열기';

  @override
  String get keybindingOpenWorkspace => '워크스페이스 열기';

  @override
  String get keybindingPreviousArticle => '이전 아티클';

  @override
  String get keybindingPreviousSpace => '이전 스페이스';

  @override
  String get keybindingPreviousWorkspace => '이전 워크스페이스';

  @override
  String get keybindingRefresh => '새로 고침';

  @override
  String get keybindingRefreshAllFeedsDescription => '모든 피드 새로 고침';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      '풀 리퀘스트 목록 새로 고침';

  @override
  String get keybindingRescanForAdaptersDescription => '어댑터 다시 스캔';

  @override
  String get keybindingSelectTheNextArticleDescription => '다음 아티클 선택';

  @override
  String get keybindingSelectTheNextSpaceDescription => '다음 스페이스 선택';

  @override
  String get keybindingSelectThePreviousArticleDescription => '이전 아티클 선택';

  @override
  String get keybindingSelectThePreviousSpaceDescription => '이전 스페이스 선택';

  @override
  String get keybindingSendMessage => '메시지 보내기';

  @override
  String get keybindingSendTheCurrentMessageDescription => '현재 메시지 보내기';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      '라이트 모드와 다크 모드 전환';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      '여덟 번째 워크스페이스로 전환';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      '다섯 번째 워크스페이스로 전환';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      '첫 번째 워크스페이스로 전환';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      '네 번째 워크스페이스로 전환';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription => '다음 워크스페이스로 전환';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      '아홉 번째 워크스페이스로 전환';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      '이전 워크스페이스로 전환';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      '두 번째 워크스페이스로 전환';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      '일곱 번째 워크스페이스로 전환';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      '여섯 번째 워크스페이스로 전환';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      '세 번째 워크스페이스로 전환';

  @override
  String get keybindingToggleBookmark => '북마크 토글';

  @override
  String get keybindingToggleTheme => '테마 토글';

  @override
  String get keybindingToggleWorkspaceSwitcher => '워크스페이스 전환 토글';

  @override
  String get keybindingWorkspace1 => '워크스페이스 1';

  @override
  String get keybindingWorkspace2 => '워크스페이스 2';

  @override
  String get keybindingWorkspace3 => '워크스페이스 3';

  @override
  String get keybindingWorkspace4 => '워크스페이스 4';

  @override
  String get keybindingWorkspace5 => '워크스페이스 5';

  @override
  String get keybindingWorkspace6 => '워크스페이스 6';

  @override
  String get keybindingWorkspace7 => '워크스페이스 7';

  @override
  String get keybindingWorkspace8 => '워크스페이스 8';

  @override
  String get keybindingWorkspace9 => '워크스페이스 9';

  @override
  String get keybindings => '키 바인딩';

  @override
  String get keybindingsDescription =>
      '모든 키보드 단축키입니다. 단축키는 고정되어 있으며 다시 지정할 수 없습니다.';

  @override
  String get killRunning => '실행 중 강제 종료';

  @override
  String get languageSystem => '시스템';

  @override
  String get leaveACommentEllipsis => '댓글 남기기…';

  @override
  String get legendLabel => '범례';

  @override
  String get lessLabel => '간략히';

  @override
  String get letsPluginTools => '도구를 연결해 보세요.';

  @override
  String get level => '수준';

  @override
  String get loadingAgents => '에이전트 불러오는 중…';

  @override
  String get loadingModels => '모델 불러오는 중…';

  @override
  String get loadingProviders => '공급자 불러오는 중…';

  @override
  String get logLevel => '로그 수준';

  @override
  String get logs => '로그';

  @override
  String get low => '낮음';

  @override
  String get maintenance => '유지 보수';

  @override
  String get manageParticipants => '참가자 관리';

  @override
  String get manageWorkspaces => '워크스페이스 관리';

  @override
  String get reorderWorkspace => '워크스페이스 순서 변경';

  @override
  String get matchOsAppearance => 'OS 화면 설정을 따르거나 고정 모드를 선택하세요.';

  @override
  String get mcpAuthToken => 'MCP 인증 토큰';

  @override
  String get mcpNotAvailableOnServer => '연결된 서버에서는 MCP 서버 제어를 사용할 수 없습니다.';

  @override
  String get modelManagedOnServer => '이 모델은 서버 호스트에서 실행되며 거기서 관리됩니다.';

  @override
  String get mcpServer => 'MCP 서버';

  @override
  String get medium => '중간';

  @override
  String get memoryDataHint => '에이전트가 작업하면서 팩트와 정책이 여기에 나타납니다.';

  @override
  String get memoryLabel => '메모리';

  @override
  String get merge => '병합';

  @override
  String get merged => '병합됨';

  @override
  String get messagePlaceholder => '메시지… (멘션은 @, 명령은 /)';

  @override
  String get navConversations => '스페이스';

  @override
  String get microphonePermissionDenied => '마이크 권한이 거부되었습니다.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count분 전',
      one: '1분 전',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => '모델';

  @override
  String get modified => '수정됨';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개월 전',
      one: '1개월 전',
    );
    return '$_temp0';
  }

  @override
  String get moreLabel => '더 보기';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => '이름';

  @override
  String get nameAndTitleRequired => '이름과 제목은 필수입니다.';

  @override
  String get nameAndUrlRequired => '이름과 URL이 필요합니다';

  @override
  String get nameLabel => '이름';

  @override
  String nativeSandboxAvailable(String platform) {
    return '$platform에서 네이티브 샌드박스를 사용할 수 있습니다.';
  }

  @override
  String get nativeSandboxNeedsInstall => '네이티브 샌드박스 설치 필요';

  @override
  String get navObservability => '옵저버빌리티';

  @override
  String get navSettings => '설정';

  @override
  String get navigateLabel => '탐색';

  @override
  String networkBlockCount(int count) {
    return '네트워크 차단 $count개';
  }

  @override
  String get neutral => '중립';

  @override
  String get newCommitsPushed => '새 커밋이 푸시되었습니다 — 클릭해 diff를 다시 불러오세요';

  @override
  String get newFact => '새 팩트';

  @override
  String get newLabel => '신규';

  @override
  String get newPolicy => '새 정책';

  @override
  String get newsfeed => '뉴스피드';

  @override
  String get newsfeedLabel => '뉴스피드';

  @override
  String get newsfeedSettingsDescription => '구독 중인 피드와 리더 환경설정을 관리합니다.';

  @override
  String get newsfeedSettingsTitle => '뉴스피드 설정';

  @override
  String get nextMatch => '다음 일치 (↵)';

  @override
  String get noActiveWorkspace => '활성 워크스페이스나 리포지토리가 선택되지 않았습니다.';

  @override
  String get noActiveWorkspaceCreate => '활성 워크스페이스 없음';

  @override
  String get noActiveWorkspaceGithub => 'GitHub 리포지토리가 있는 활성 워크스페이스가 없습니다.';

  @override
  String get noAgents => '에이전트 없음';

  @override
  String get noArticlesYet => '아직 아티클이 없습니다';

  @override
  String get noArticlesYetBody => '피드의 아티클이 여기에 나타납니다.';

  @override
  String get noExecutionLogsYet => '아직 실행 로그가 없습니다';

  @override
  String get noFacts => '아직 팩트가 없습니다';

  @override
  String get noFeedsYet => '아직 피드가 없습니다';

  @override
  String get noFileAnchor => '파일 앵커가 없어 인라인 댓글을 달 수 없습니다.';

  @override
  String get noFileChangesInScope => '이 범위에 변경된 파일이 없습니다';

  @override
  String get noGifsFound => 'GIF를 찾을 수 없습니다';

  @override
  String get noInputDevicesDetected => '입력 기기가 감지되지 않았습니다 — 시스템 기본값을 사용합니다.';

  @override
  String get noMatchingFiles => '일치하는 파일 없음';

  @override
  String get noMatchingGoogleFonts => '일치하는 Google 글꼴이 없습니다.';

  @override
  String get noMemoryData => '아직 메모리 데이터가 없습니다';

  @override
  String get noMessagesYet => '아직 메시지가 없습니다';

  @override
  String get noModelsAdvertised => '이 어댑터에서 사용할 수 있는 모델이 없습니다.';

  @override
  String get noOpenPullRequests => '열린 풀 리퀘스트가 없습니다';

  @override
  String get noPolicies => '아직 정책이 없습니다';

  @override
  String get noReposInWorkspaceYet => '이 워크스페이스에는 아직 리포지토리가 없습니다';

  @override
  String get noRunnersDetected => '아직 감지된 러너가 없습니다. 새로 고침해 다시 스캔하세요.';

  @override
  String get noSavedArticles => '저장된 아티클 없음';

  @override
  String get noSavedArticlesBody => '저장한 아티클이 여기에 나타납니다.';

  @override
  String noShortcutsMatch(String query) {
    return '\"$query\"와 일치하는 단축키가 없습니다';
  }

  @override
  String get noSystemFonts => '감지된 시스템 글꼴이 없습니다.';

  @override
  String get noTokenSet => '토큰이 설정되지 않았습니다 — 접근이 제한되지 않습니다.';

  @override
  String get noWorkingMemory => '아직 작업 메모리 노트가 없습니다.';

  @override
  String get noneAllRoles => '없음 (모든 역할)';

  @override
  String get notAvailable => '사용할 수 없음';

  @override
  String get notConfiguredLabel => '구성되지 않았습니다.';

  @override
  String get notDetected => '감지되지 않음';

  @override
  String get notFoundLabel => '찾을 수 없음';

  @override
  String get notes => '노트';

  @override
  String get notificationAgentFinished => '에이전트 완료';

  @override
  String get notificationPrMentioned => '풀 리퀘스트에서 멘션됨';

  @override
  String get notificationNewMessages => '새 메시지';

  @override
  String get notificationPrMerged => 'PR 병합됨';

  @override
  String get notificationPrPublished => 'PR 게시됨';

  @override
  String get notificationReviewRequested => '리뷰 요청됨';

  @override
  String get notifications => '알림';

  @override
  String get notifyAgentRunCompleted => '에이전트가 실행을 완료하면 알립니다.';

  @override
  String get notifyPrMentioned => '풀 리퀘스트에서 멘션되면 알립니다.';

  @override
  String get notifyNewMessages => '다른 스페이스의 새 에이전트 메시지를 알립니다.';

  @override
  String get notifyPrMerged => '풀 리퀘스트가 병합되면 알립니다.';

  @override
  String get notifyPrPublished => '에이전트가 풀 리퀘스트를 게시하면 알립니다.';

  @override
  String get notifyReviewRequested => '풀 리퀘스트에 내 리뷰가 요청되면 알립니다.';

  @override
  String get notificationReviewStale => '리뷰 오래됨';

  @override
  String get notifyReviewStale => '이미 리뷰한 풀 리퀘스트에 새 커밋이 반영될 때';

  @override
  String get notificationPrMergeReadiness => '병합 가능';

  @override
  String get notifyPrMergeReadiness => '내가 만든 풀 리퀘스트가 병합 가능해지거나 불가능해지면 알립니다.';

  @override
  String get notificationPrReviewDecision => '리뷰 결정';

  @override
  String get notifyPrReviewDecision => '리뷰어가 승인하거나 변경을 요청하거나 승인이 해제되면 알립니다.';

  @override
  String get notificationPrChecksStatus => '검사';

  @override
  String get notifyPrChecksStatus => '내가 만든 풀 리퀘스트에서 CI가 실패하거나 복구되면 알립니다.';

  @override
  String get notificationPrThreadActivity => '리뷰 스레드';

  @override
  String get notifyPrThreadActivity => '내가 참여한 스레드에 답글이 달리거나 해결되면 알립니다.';

  @override
  String get notificationPrReadyToMerge => '병합 가능';

  @override
  String notificationPrReadyToMergeBody(String prTitle) {
    return '$prTitle이(가) 병합 준비를 마쳤습니다.';
  }

  @override
  String get notificationPrMergeBlocked => '더 이상 병합 불가';

  @override
  String notificationPrMergeBlockedBodyConflicts(String prTitle) {
    return '$prTitle이(가) 베이스 브랜치와 충돌합니다.';
  }

  @override
  String notificationPrMergeBlockedBodyBehind(String prTitle) {
    return '$prTitle이(가) 베이스 브랜치보다 뒤처져 있습니다.';
  }

  @override
  String notificationPrMergeBlockedBodyReviews(String prTitle) {
    return '$prTitle이(가) 필수 리뷰를 기다리고 있습니다.';
  }

  @override
  String notificationPrMergeBlockedBodyChanges(String prTitle) {
    return '리뷰어가 $prTitle에 변경을 요청했습니다.';
  }

  @override
  String notificationPrMergeBlockedBodyChecks(String prTitle) {
    return '$prTitle의 검사가 실패했습니다.';
  }

  @override
  String notificationPrMergeBlockedBodyOther(String prTitle) {
    return '$prTitle을(를) 더 이상 병합할 수 없습니다.';
  }

  @override
  String get notificationPrApproved => '풀 리퀘스트 승인됨';

  @override
  String notificationPrApprovedBodyBy(String login, String prTitle) {
    return '$login이(가) $prTitle을(를) 승인했습니다';
  }

  @override
  String notificationPrApprovedBody(String prTitle) {
    return '$prTitle이(가) 승인되었습니다';
  }

  @override
  String notificationPrReviewersRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '리뷰어 $count명이 아직 응답하지 않았습니다',
      one: '리뷰어 1명이 아직 응답하지 않았습니다',
      zero: '응답할 리뷰어가 없습니다',
    );
    return '$_temp0';
  }

  @override
  String get notificationPrChangesRequested => '변경 요청됨';

  @override
  String notificationPrChangesRequestedBodyBy(String login, String prTitle) {
    return '$login이(가) $prTitle에 변경을 요청했습니다';
  }

  @override
  String notificationPrChangesRequestedBody(String prTitle) {
    return '$prTitle에 변경이 요청되었습니다';
  }

  @override
  String get notificationPrReviewDismissed => '승인 해제됨';

  @override
  String notificationPrReviewDismissedBody(String prTitle) {
    return '$prTitle에 다시 리뷰가 필요합니다.';
  }

  @override
  String get notificationPrChecksFailed => '검사 실패';

  @override
  String notificationPrChecksFailedBody(String checkName, String prTitle) {
    return '$prTitle에서 $checkName이(가) 실패했습니다';
  }

  @override
  String notificationPrChecksFailedBodyUnnamed(String prTitle) {
    return '$prTitle의 검사가 실패하고 있습니다';
  }

  @override
  String get notificationPrChecksRecovered => '검사 통과';

  @override
  String notificationPrChecksRecoveredBody(String prTitle) {
    return '$prTitle이(가) 다시 통과했습니다.';
  }

  @override
  String notificationPrMentionedInCommentBody(String login, String location) {
    return '$login이(가) $location에서 나를 멘션했습니다';
  }

  @override
  String get notificationPrThreadReplied => '새 답글';

  @override
  String notificationPrThreadRepliedBody(String login, String location) {
    return '$login이(가) $location에 답글을 달았습니다';
  }

  @override
  String get notificationPrThreadResolved => '스레드 해결됨';

  @override
  String notificationPrThreadResolvedBody(String location) {
    return '$location의 내 스레드가 해결되었습니다.';
  }

  @override
  String get notificationGroupAgents => '에이전트';

  @override
  String get notificationGroupPullRequests => '풀 리퀘스트';

  @override
  String get notificationGroupMessages => '메시지';

  @override
  String get notificationGroupTickets => '티켓';

  @override
  String get notificationGroupCalendar => '캘린더';

  @override
  String get notificationGroupMachines => '머신';

  @override
  String get notificationsMutedRepos => '음소거된 리포지토리';

  @override
  String notificationsMutedReposCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '리포지토리 $count개 음소거됨',
      one: '리포지토리 1개 음소거됨',
      zero: '음소거된 리포지토리 없음',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMuteRepo => '이 리포지토리 음소거';

  @override
  String get notificationsUnmuteRepo => '이 리포지토리 음소거 해제';

  @override
  String get onboardingLinuxDescription =>
      'Control Center는 Linux 컨테이너를 사용해 에이전트 실행을 격리할 수 있습니다.';

  @override
  String get onboardingMacosDescription =>
      'Control Center는 macOS에서 네이티브 샌드박스를 사용해 에이전트 실행을 격리합니다.';

  @override
  String get onboardingUnsupportedDescription =>
      '이 플랫폼에서는 샌드박스를 사용할 수 없습니다. 에이전트 실행은 격리 없이 이루어집니다.';

  @override
  String get openApplicationSettings => '애플리케이션 설정 열기';

  @override
  String get openArticlesInApp => '앱에서 아티클 열기';

  @override
  String get openInBrowser => '브라우저에서 열기';

  @override
  String get openedInYourBrowser => '브라우저에서 열었습니다.';

  @override
  String get openLabel => '열기';

  @override
  String get openOnGithub => 'GitHub에서 열기';

  @override
  String get openStatus => '열림';

  @override
  String get optionalPersonaDescription => '선택적 페르소나 설명';

  @override
  String get otherLabel => '기타';

  @override
  String get ownerOrganization => '소유자 / 조직';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get passed => '통과';

  @override
  String get pasteValueHere => '여기에 값을 붙여넣으세요';

  @override
  String get persona => '페르소나';

  @override
  String get policies => '정책';

  @override
  String get policiesHint => '에이전트가 팩트를 승격하면 정책이 여기에 나타납니다.';

  @override
  String get policy => '정책';

  @override
  String get popular => '인기';

  @override
  String get port => '포트';

  @override
  String get postingEllipsis => '게시하는 중…';

  @override
  String get prCommits => '커밋';

  @override
  String get prMergedBody => '풀 리퀘스트가 병합되었습니다';

  @override
  String get prMoreActions => '추가 작업';

  @override
  String get prTitle => 'PR 제목';

  @override
  String get reviewCommentHint => '그냥 승인을 클릭하거나, 마음이 내키면 댓글이나 리액션을 남겨 보세요…';

  @override
  String get nothingToPreview => '미리 볼 항목이 없습니다';

  @override
  String get previousMatch => '이전 일치 (⇧↵)';

  @override
  String get priorityReviewsDescription => '우선 리뷰와 리포지토리 개요입니다.';

  @override
  String get prsCreated => '생성된 PR';

  @override
  String get prsMerged => '병합된 PR';

  @override
  String get publishToGithub => 'GitHub에 게시';

  @override
  String get published => '게시됨';

  @override
  String get pullRequestApproved => '풀 리퀘스트 승인됨';

  @override
  String get pullRequests => '풀 리퀘스트';

  @override
  String get questionLabel => '질문';

  @override
  String get queued => '대기 중';

  @override
  String get react => '리액션';

  @override
  String get readPrsIssuesMetadata => '에이전트가 PR, 이슈, 리포지토리 메타데이터를 읽을 수 있습니다.';

  @override
  String get readerPreferences => '리더 환경설정';

  @override
  String get reasoningEffort => '추론 강도';

  @override
  String get recommendLabel => '추천';

  @override
  String recordingFromDevice(String device) {
    return '$device에서 녹음 중입니다.';
  }

  @override
  String get redownload => '다시 다운로드';

  @override
  String get redownloadEmbeddingModel => '임베딩 모델을 다시 다운로드할까요?';

  @override
  String get redownloadVoiceModel => '음성 모델을 다시 다운로드할까요?';

  @override
  String get refinePlan => '계획 다듬기';

  @override
  String get refresh => '새로 고침';

  @override
  String get refreshAll => '모두 새로 고침';

  @override
  String get refreshAllFeeds => '모든 피드 새로 고침';

  @override
  String get reject => '거절';

  @override
  String get rejected => '거절됨';

  @override
  String get reload => '다시 불러오기';

  @override
  String get remove => '제거';

  @override
  String get removeBookmark => '북마크 제거';

  @override
  String get removeEmbeddingModel => '임베딩 모델을 제거할까요?';

  @override
  String get removeLogo => '로고 제거';

  @override
  String get removeRepoFromWorkspace => '워크스페이스에서 리포지토리를 제거할까요?';

  @override
  String get removeVoiceModel => '음성 모델을 제거할까요?';

  @override
  String get removed => '제거됨';

  @override
  String get renamed => '이름 변경됨';

  @override
  String get reopen => '다시 열기';

  @override
  String get resolve => '해결';

  @override
  String get replyEllipsis => '답글…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$name이(가) 이 워크스페이스에서 제거됩니다. 디스크의 로컬 파일은 변경되지 않습니다.';
  }

  @override
  String repoAccessNoticeBody(String repos) {
    return '서버의 GitHub 자격 증명이 $repos을(를) 볼 수 없습니다. 리포지토리가 조직에 속해 있다면 거기에 GitHub App을 설치하거나 접근 권한이 있는 토큰을 연결하세요.';
  }

  @override
  String repoAccessNoticeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '리포지토리 $count개에 접근할 수 없음',
      one: '리포지토리 1개에 접근할 수 없음',
    );
    return '$_temp0';
  }

  @override
  String get repoAccessNoticeSuspendedTitle => 'GitHub App 설치가 일시 중단됨';

  @override
  String repoAccessNoticeSuspendedBody(String repos) {
    return '$repos의 마지막 알려진 데이터를 표시합니다. GitHub에서 설치를 재개하거나 접근 권한이 있는 토큰을 연결하세요.';
  }

  @override
  String get repoNoAccessBadge => '접근 불가';

  @override
  String get reportsTo => '보고 대상';

  @override
  String reposCount(int count) {
    return '리포지토리 ($count)';
  }

  @override
  String get reposDescription => '이 워크스페이스가 대상으로 하는 로컬 체크아웃입니다.';

  @override
  String get repositories => '리포지토리';

  @override
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '리포지토리 $count개',
      one: '리포지토리 1개',
    );
    return '$_temp0를 추가할 수 없습니다: $error';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '리포지토리 $count개가 추가되었습니다',
      one: '리포지토리가 추가되었습니다',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => '리포지토리 설정';

  @override
  String get repositoryName => '리포지토리 이름';

  @override
  String get requestChanges => '변경 요청';

  @override
  String get requested => '요청됨';

  @override
  String get requestedChanges => '변경 요청함';

  @override
  String requiredRoleLabel(String role) {
    return '필요한 역할: $role';
  }

  @override
  String get requiredRoleOptional => '필요한 역할 (선택)';

  @override
  String get requirements => '요구 사항';

  @override
  String get reset => '초기화';

  @override
  String get resolved => '해결됨';

  @override
  String get enclosedTerminalTitle => '격리된 터미널';

  @override
  String get enclosedTerminalStart => '셸 열기';

  @override
  String get enclosedTerminalStartHint =>
      '이 셸은 이 대화의 일회용 VM 안에서 실행됩니다. 앱이 시작될 때가 아니라 열 때 부팅됩니다.';

  @override
  String get terminalStreamReconnecting => '스트림 중단됨 — 다시 연결하는 중…';

  @override
  String get terminalStreamError => '스트림 오류:';

  @override
  String get terminalShellExited => '셸 종료됨';

  @override
  String get restartShell => '셸 다시 시작';

  @override
  String get retry => '재시도';

  @override
  String get review => '리뷰';

  @override
  String get reviewedByMe => '내가 리뷰함';

  @override
  String get reviewers => '리뷰어';

  @override
  String get roleLabel => '역할';

  @override
  String get ruleHint => '정책 규칙 (마크다운 지원)';

  @override
  String get ruleLabel => '규칙';

  @override
  String get runCompleted => '실행 완료됨';

  @override
  String get running => '실행 중';

  @override
  String get runningLabel => '실행 중';

  @override
  String get runs => '실행';

  @override
  String get runsLabel => '실행';

  @override
  String get sandboxBackendNativeLabel => '네이티브 샌드박스';

  @override
  String get sandboxBackendMicrovmLabel => '격리 VM';

  @override
  String get sandboxBackendNoneLabel => '격리 없음';

  @override
  String get sandboxLinuxInstall =>
      'Linux/WSL2의 네이티브 샌드박스는 bubblewrap을 사용합니다. 다음 명령으로 설치하세요:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'macOS의 네이티브 샌드박스는 기본 제공되며 Apple Seatbelt(`sandbox-exec`)를 사용합니다. 설치가 필요하지 않습니다.';

  @override
  String get sandboxPermissions => '샌드박스 권한';

  @override
  String get sandboxUnsupported =>
      '이 플랫폼에서는 아직 네이티브 샌드박스를 지원하지 않습니다. \"격리 없음\"으로 대체됩니다.';

  @override
  String get sandboxingDisabledDescription =>
      '에이전트가 호스트에서 전체 환경으로 바로 실행됩니다. 권장하지 않습니다.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return '모든 에이전트 호출이 $backend을(를) 통해 전달됩니다.';
  }

  @override
  String get save => '저장';

  @override
  String get saveChanges => '변경 사항 저장';

  @override
  String get adapterArguments => '추가 인수';

  @override
  String get adapterArgumentsHint => '추가 CLI 플래그(예: --yolo)';

  @override
  String get addVariable => '변수 추가';

  @override
  String get environmentVariables => '환경 변수';

  @override
  String get environmentVariablesDescription =>
      '이 어댑터에 전달되는 사용자 지정 환경 변수입니다(예: API 키). 키체인에 저장됩니다.';

  @override
  String get variableKey => '키';

  @override
  String get variableValue => '값';

  @override
  String get savingChanges => '변경 사항 저장 중…';

  @override
  String get savingEllipsis => '저장 중…';

  @override
  String get scopeDiffToCommits => 'diff를 커밋 범위로 제한 — Shift-클릭으로 범위 지정';

  @override
  String get noPrsMatchSearch => '일치하는 풀 리퀘스트가 없습니다';

  @override
  String get noPrsMatchSearchHint =>
      '열려 있는 PR 중 검색과 일치하는 항목이 없습니다. 다른 검색어를 사용하거나 검색을 지우세요.';

  @override
  String get searchFactsHint => '팩트 검색...';

  @override
  String get searchFonts => '글꼴 검색…';

  @override
  String get searchGifs => 'GIF 검색';

  @override
  String get searchGifsHint => 'GIF 검색...';

  @override
  String get searchInDiffHint => 'diff에서 검색…';

  @override
  String get searchOrTypeModel => '모델을 검색하거나 이름을 입력하세요…';

  @override
  String get searchPlaceholder => '검색…';

  @override
  String get searchShortcuts => '단축키 검색…';

  @override
  String get shortcutUnavailableInBrowser => '브라우저에서는 사용할 수 없습니다';

  @override
  String get searching => '검색 중…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count초 전',
      one: '1초 전',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => '어댑터 선택';

  @override
  String get selectAdapterFirst => '먼저 어댑터를 선택하세요';

  @override
  String get selectAgentToReportTo => '보고할 에이전트 선택…';

  @override
  String get selectAnAgent => '에이전트 선택';

  @override
  String get selectConversation => '대화 선택';

  @override
  String get selectEffortLevel => '노력 수준 선택';

  @override
  String get selectLabel => '선택';

  @override
  String get selectRunner => '러너 선택';

  @override
  String get semanticSearch => '시맨틱 검색';

  @override
  String get send => '보내기';

  @override
  String get sendFirstMessage => '첫 메시지 보내기';

  @override
  String get sendMessage => '메시지 보내기';

  @override
  String sentFindingsToAgent(int count) {
    return '에이전트에 발견 항목 $count개를 보냈습니다.';
  }

  @override
  String setGithubLinkDescription(String name) {
    return '$name의 GitHub 소유자와 저장소 이름을 설정하세요. 마크다운에서 #123과 같은 PR 및 이슈 참조를 해석하는 데 사용됩니다.';
  }

  @override
  String get setLabel => '지정';

  @override
  String get setToken => '토큰 설정';

  @override
  String get settingsLabel => '설정';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsLanguageDescription => '앱 언어를 선택하세요.';

  @override
  String get shortTask => '짧은 작업';

  @override
  String get showNativeNotifications => '이벤트에 대해 네이티브 macOS 알림을 표시합니다.';

  @override
  String get showSuperseded => '대체된 항목 표시';

  @override
  String get signedIn => '로그인했습니다.';

  @override
  String signedInAs(String username) {
    return '$username(으)로 로그인했습니다.';
  }

  @override
  String get skillEditor => '스킬 편집기';

  @override
  String get skillNameRequired => '스킬 이름은 필수입니다.';

  @override
  String skillSaved(String name) {
    return '스킬 \"$name\"을(를) 저장했습니다.';
  }

  @override
  String get skillsSourcesTab => '소스';

  @override
  String get skillSourcesDisclaimer =>
      '추가한 GitHub 저장소에서 스킬을 설치합니다. 저장소 메타데이터는 신뢰할 수 없습니다. 실제 안전 신호는 안티바이러스 검사입니다.';

  @override
  String get skillSourcesEmpty => '스킬 저장소가 없습니다';

  @override
  String get skillSourcesEmptyHint => 'GitHub 저장소를 추가하면 스킬을 둘러볼 수 있습니다.';

  @override
  String get skillSourceAdd => '저장소 추가';

  @override
  String get skillSourceAddTitle => '스킬 저장소 추가';

  @override
  String get skillSourceAddHint => 'https://github.com/owner/repo';

  @override
  String get skillSourceInvalidUrl =>
      'GitHub 저장소 URL을 입력하세요 (https://github.com/owner/repo).';

  @override
  String skillSourceAdded(String repo) {
    return '$repo 저장소를 추가했습니다.';
  }

  @override
  String skillSourceAlreadyAdded(String repo) {
    return '$repo 저장소는 이미 추가되어 있습니다.';
  }

  @override
  String skillSourceRemoved(String repo) {
    return '$repo 저장소를 제거했습니다.';
  }

  @override
  String get skillSourceRemove => '제거';

  @override
  String skillSourceRemoveConfirmTitle(String repo) {
    return '$repo을(를) 제거할까요?';
  }

  @override
  String get skillSourceRemoveConfirmBody =>
      '설치된 스킬은 그대로 유지됩니다. 저장소 목록만 제거됩니다.';

  @override
  String get skillSourceNoSkills =>
      '이 저장소에서 스킬을 찾지 못했습니다 (스킬은 SKILL.md가 있는 디렉터리입니다).';

  @override
  String get skillSourceRefresh => '새로고침';

  @override
  String get skillSourceInstalledBadge => '설치됨';

  @override
  String get skillSourceUpdateBadge => '업데이트 있음';

  @override
  String get skillSourceSlugTaken => '이미 사용 중인 이름';

  @override
  String skillSourceFilesCount(num count) {
    return '$count개 파일';
  }

  @override
  String get skillSourceReadme => 'README';

  @override
  String get skillSourceNoReadme => '이 스킬에는 README가 없습니다.';

  @override
  String get skillSourceNoMatches => '필터와 일치하는 스킬이 없습니다.';

  @override
  String get skillUpdateAction => '업데이트';

  @override
  String get skillUninstallAction => '설치 해제';

  @override
  String skillUninstallConfirmTitle(String slug) {
    return '\"$slug\"을(를) 설치 해제할까요?';
  }

  @override
  String skillUninstalled(String slug) {
    return '\"$slug\" 스킬을 설치 해제했습니다.';
  }

  @override
  String get skillFindingLine => '줄';

  @override
  String get skillInstallAnywayOverride => '위험을 이해했습니다. 그래도 설치';

  @override
  String skillInstalled(String slug) {
    return '\"$slug\" 스킬을 설치했습니다.';
  }

  @override
  String get skillPreviewCapabilities => '기능';

  @override
  String get skillPreviewFindings => '발견 항목';

  @override
  String get skillPreviewGuardedActions => '보호된 작업';

  @override
  String get skillPreviewLlmReviewed => 'LLM 검토됨';

  @override
  String get skillPreviewNoCapabilities => '선언된 기능이 없습니다.';

  @override
  String get skillPreviewNoFindings => '발견 항목이 없습니다.';

  @override
  String get skillPreviewScanning => '스킬을 검사하는 중…';

  @override
  String get skillPreviewVerdictLabel => '검사 판정';

  @override
  String get skillPreviewVerdictPass => '통과';

  @override
  String get skillPreviewVerdictQuarantine => '격리됨';

  @override
  String get skillPreviewVerdictWarn => '경고';

  @override
  String get skillQuarantineWarning =>
      '검사기가 이 스킬을 격리했습니다. 설치하면 이 컴퓨터에서 코드가 실행됩니다. 출처를 신뢰하고 발견 항목을 검토한 경우에만 계속하세요.';

  @override
  String skillDetachedFromAgents(String agents) {
    return '격리되어 에이전트에서 분리됨: $agents';
  }

  @override
  String get skillNotScanned => '미검사';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => '수동';

  @override
  String get skillOriginRegistry => '레지스트리';

  @override
  String get skillOriginRuntimeLocal => '런타임 로컬';

  @override
  String get skillRulesStale => '검사 오래됨';

  @override
  String get skillSaveAnywayOverride => '위험을 이해했습니다. 그래도 저장';

  @override
  String get skillSaveBlockedBody => '아무것도 기록되기 전에 콘텐츠가 차단되었습니다.';

  @override
  String get skillSaveBlockedTitle => '검사 게이트가 저장을 차단함';

  @override
  String get skillScanAction => '검사';

  @override
  String get skillScanAll => '모두 검사';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass 통과 · $warn 경고 · $quarantine 격리';
  }

  @override
  String get skillStateDrifted => '설치 이후 수정됨';

  @override
  String get skillStateUnmanaged => '관리되지 않음';

  @override
  String get skillSeverityBlocked => '차단됨';

  @override
  String get skillSeverityWarn => '경고';

  @override
  String get skillsInstalledTab => '설치됨';

  @override
  String get skills => '스킬';

  @override
  String get skipAcceptRisk => '건너뛰기 — 위험을 감수합니다';

  @override
  String get skipForNow => '지금은 건너뛰기';

  @override
  String get skipSandboxing => '샌드박싱 건너뛰기';

  @override
  String get skipSandboxingDialogContent =>
      '샌드박싱을 건너뛰시겠어요? 에이전트가 격리 없이 시스템에서 코드를 실행할 수 있습니다.';

  @override
  String get somethingWentWrong => '문제가 발생했습니다';

  @override
  String sourceCount(int count) {
    return '소스 $count개';
  }

  @override
  String sourceCountPlural(int count) {
    return '소스 $count개';
  }

  @override
  String get sourceFacts => '소스 팩트:';

  @override
  String get splitDiff => '분할(나란히) diff';

  @override
  String get startLabel => '시작';

  @override
  String get startOnAppLaunch => '앱 실행 시 시작';

  @override
  String get statusLabel => '상태';

  @override
  String get onboardingStepConnect => '연결';

  @override
  String get onboardingStepWorkspace => '워크스페이스';

  @override
  String get onboardingStepSandbox => '샌드박스';

  @override
  String get onboardingStepAdapter => '어댑터';

  @override
  String get onboardingStepVoice => '음성';

  @override
  String get stop => '중지';

  @override
  String get stopped => '중지됨';

  @override
  String get strictIdentityCheck => '엄격한 신원 확인';

  @override
  String get success => '성공';

  @override
  String get successLabel => '성공';

  @override
  String get suggestAChange => '변경 제안';

  @override
  String get suggestLabel => '제안';

  @override
  String get superseded => '대체됨';

  @override
  String get synced => '동기화됨';

  @override
  String get systemDefault => '시스템 기본값';

  @override
  String get systemFonts => '시스템 글꼴';

  @override
  String get systemPrompt => '시스템 프롬프트';

  @override
  String get systemPromptLabel => '시스템 프롬프트';

  @override
  String get talkToControlCenter => 'Control Center에 말해 보세요.';

  @override
  String get taskMentionSection => '작업';

  @override
  String get testLabel => '테스트';

  @override
  String get theme => '테마';

  @override
  String get themeDark => '다크';

  @override
  String get themeLight => '라이트';

  @override
  String get themeSystem => '시스템';

  @override
  String get thisCannotBeUndone => '이 작업은 되돌릴 수 없습니다.';

  @override
  String get ticketLabel => '티켓';

  @override
  String get titleLabel => '제목';

  @override
  String get todayLabel => '오늘';

  @override
  String get toggleTheme => '테마 전환';

  @override
  String get tokenConfigured => '구성됨 — 클라이언트는 이 토큰을 제시해야 합니다.';

  @override
  String get topic => '주제';

  @override
  String get topicHint => '예: Tech Stack, Design System';

  @override
  String get totalRuns => '총 실행 횟수';

  @override
  String trackingParamsCount(int count) {
    return '추적 파라미터 $count개';
  }

  @override
  String get typeCommandOrSearch => '명령어를 입력하거나 검색하세요…';

  @override
  String get typography => '타이포그래피';

  @override
  String get unavailable => '사용할 수 없음';

  @override
  String get unifiedDiff => '통합 diff';

  @override
  String get unknownAuthor => '알 수 없음';

  @override
  String get unnamedAgent => '이름 없는 에이전트';

  @override
  String get updateKey => '키 업데이트';

  @override
  String get updateLabel => '업데이트';

  @override
  String get updateToken => '토큰 업데이트';

  @override
  String updatedDaysAgo(int count) {
    return '$count일 전에 업데이트됨';
  }

  @override
  String updatedHoursAgo(int count) {
    return '$count시간 전에 업데이트됨';
  }

  @override
  String get updatedJustNow => '방금 업데이트됨';

  @override
  String updatedMinutesAgo(int count) {
    return '$count분 전에 업데이트됨';
  }

  @override
  String get useSandbox => '샌드박스 사용';

  @override
  String get useWorkspaceDefault => '워크스페이스 기본값 사용';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      '비워 두면 앱 기본 User-Agent를 사용합니다. 일부 사이트는 브라우저가 아닌 User-Agent를 차단합니다.';

  @override
  String get usingSystemDefaultMicrophone => '시스템 기본 마이크를 사용합니다.';

  @override
  String get viewLabel => '보기';

  @override
  String get viewLogs => '로그 보기';

  @override
  String voiceInstallFailed(String error) {
    return '설치 실패: $error';
  }

  @override
  String get voiceModelNotInstalled =>
      '설치되지 않았습니다. 약 200MB를 한 번 다운로드하며, 이후에는 기기에서만 실행됩니다.';

  @override
  String get voiceModelNotInstalledLabel => '음성 모델이 설치되지 않았습니다.';

  @override
  String get voiceRedownloadBody =>
      '기존 모델 파일을 삭제한 뒤 약 200MB 아카이브를 다시 다운로드합니다. 다운로드가 끝날 때까지 음성 받아쓰기를 사용할 수 없습니다.';

  @override
  String get voiceRemoveBody => '다시 설치할 때까지 음성 받아쓰기가 꺼집니다. 언제든지 다시 설치할 수 있습니다.';

  @override
  String get voiceTranscription => '음성 받아쓰기';

  @override
  String get weakIsolationDescription => '약한 격리 - 네임스페이스 경계만 적용되며 커널 경계는 없습니다.';

  @override
  String get whenOffNoDefaultRoute => '끄면 샌드박스가 기본 라우트 없이 부팅됩니다.';

  @override
  String get whenOffServerStaysStopped => '끄면 직접 시작할 때까지 서버가 중지된 상태로 유지됩니다.';

  @override
  String get speechModel => '음성 모델';

  @override
  String get speechModelHint => '회의 받아쓰기와 작성기 마이크에 사용됩니다.';

  @override
  String get voiceModelInstalled => '설치됨. 회의 받아쓰기와 작성기 마이크 버튼을 구동합니다.';

  @override
  String get meetingMicSilentWarning =>
      '마이크가 음소거된 것 같습니다. 다른 사람은 말하고 있지만 마이크에 아무 소리도 들어오지 않습니다.';

  @override
  String get meetingSummaryPrivacyNotice =>
      '녹음과 받아쓰기는 이 기기에 남습니다. 요약은 에이전트가 작성하므로, 클라우드 모델을 쓰면 받아쓰기와 노트가 해당 제공업체로 전송됩니다.';

  @override
  String get meetingTemplates => '회의 노트 템플릿';

  @override
  String get meetingTemplatesHint =>
      '회의 유형에 맞게 AI 요약 형태를 지정합니다. 활성 템플릿은 새 요약과 다시 실행한 요약에 적용됩니다.';

  @override
  String get meetingTemplateActive => '활성 템플릿';

  @override
  String get meetingTemplateAdd => '템플릿 추가';

  @override
  String get meetingTemplateNewTitle => '새 템플릿';

  @override
  String get meetingTemplateEditTitle => '템플릿 편집';

  @override
  String get meetingTemplateNameLabel => '이름';

  @override
  String get meetingTemplateNameHint => '예: 스프린트 리뷰';

  @override
  String get meetingTemplateInstructionsLabel => '지시';

  @override
  String get meetingTemplateInstructionsHint => 'AI가 이 노트를 어떻게 구성하고 강조할까요?';

  @override
  String get workingMemory => '워킹 메모리';

  @override
  String get workspaceName => '워크스페이스 이름';

  @override
  String get workspaceScopedSkills => '에이전트에 첨부되는 워크스페이스 범위 스킬 파일입니다.';

  @override
  String get workspaces => '워크스페이스';

  @override
  String get writePrivateNotes => '비공개 노트, 관찰, 계획을 작성하세요...';

  @override
  String get writeSkillContent => '여기에 스킬 내용을 작성하세요 (Markdown)…';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count년 전',
      one: '1년 전',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => '어제';

  @override
  String get focusModeStart => '집중 세션 시작';

  @override
  String get focusModeConfigTitle => '집중 세션 시작';

  @override
  String get focusModeGoalLabel => '목표';

  @override
  String get focusModeGoalHint => '지금 무엇을 하고 있나요?';

  @override
  String get focusModeDurationLabel => '시간';

  @override
  String get focusModeBlockNotifications => '알림 차단';

  @override
  String get focusModeStartButton => '시작';

  @override
  String get focusModeFloat => '막대로 최소화';

  @override
  String get focusModeActiveTooltip => '집중 모드 사용 중 — 탭하여 종료';

  @override
  String get dismiss => '닫기';

  @override
  String get acceptAndResolve => '수락 및 해결';

  @override
  String reviewFatigueWarning(int minutes) {
    return '$minutes분째 리뷰 중입니다. 연구에 따르면 60분이 넘으면 리뷰 품질이 떨어질 수 있습니다. 휴식을 고려해 보세요.';
  }

  @override
  String get notificationSound => '알림 소리';

  @override
  String get notificationSoundDescription => '알림이 표시될 때 재생되는 소리입니다.';

  @override
  String get notificationSoundNone => '없음';

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
  String get notificationSoundMigrosSoft => 'Migros (소프트)';

  @override
  String get notificationSoundMigrosHard => 'Migros (하드)';

  @override
  String get notificationSoundSbb => 'SBB';

  @override
  String get notificationSoundCff => 'CFF';

  @override
  String get notificationSoundFfs => 'FFS';

  @override
  String get notificationSoundPost => 'Post';

  @override
  String get notificationSoundTest => '테스트';

  @override
  String get notificationVolume => '음량';

  @override
  String noPrsByUserInWorkspace(String login) {
    return '이 워크스페이스에 @$login의 PR이 없습니다';
  }

  @override
  String get usersLabel => '사용자';

  @override
  String get mergePullRequest => '풀 리퀘스트 병합';

  @override
  String get forceMergePullRequest => '풀 리퀘스트 강제 병합';

  @override
  String get closePullRequest => '풀 리퀘스트 닫기';

  @override
  String get closePullRequestConfirm => '이 풀 리퀘스트를 닫으시겠어요?';

  @override
  String get stackedPullRequests => '스택된 풀 리퀘스트';

  @override
  String partOfStack(int position, int total) {
    return '스택의 일부 ($total개 중 $position)';
  }

  @override
  String get createStack => '스택 만들기';

  @override
  String get createStackDialogTitle => '풀 리퀘스트 스택 만들기';

  @override
  String createStackDialogBody(int count) {
    return '이 $count개의 풀 리퀘스트가 아래에서 위로 스택됩니다:';
  }

  @override
  String get createStackInvalidSelection =>
      '스택을 만들려면 같은 저장소의 풀 리퀘스트를 두 개 이상 선택하세요';

  @override
  String get createStackNotAChain =>
      '선택한 풀 리퀘스트가 체인을 이루지 않습니다. 각 풀 리퀘스트의 베이스 브랜치는 바로 이전 풀 리퀘스트의 헤드 브랜치여야 합니다';

  @override
  String get createStackAlreadyStacked => '선택한 풀 리퀘스트 중 하나 이상이 이미 스택에 있습니다';

  @override
  String get stackCreated => '스택을 만들었습니다';

  @override
  String get stackCreationFailed => '스택을 만들지 못했습니다';

  @override
  String get squashAndMerge => '스쿼시 후 병합';

  @override
  String get createMergeCommit => '병합 커밋 만들기';

  @override
  String get rebaseAndMerge => '리베이스 후 병합';

  @override
  String get commitTitle => '커밋 제목';

  @override
  String get commitDescription => '커밋 설명';

  @override
  String get pullRequestMerged => '풀 리퀘스트가 병합되었습니다';

  @override
  String get pullRequestClosed => '풀 리퀘스트가 닫혔습니다';

  @override
  String failedToMergePr(String error) {
    return '병합하지 못했습니다: $error';
  }

  @override
  String failedToClosePr(String error) {
    return '닫지 못했습니다: $error';
  }

  @override
  String get markReadyForReview => '리뷰 준비 완료';

  @override
  String get markReadyForReviewConfirm =>
      '이 풀 리퀘스트가 초안에서 해제됩니다. 리뷰어에게 알림이 가고, 필수 검사가 병합을 제한하기 시작하며, 준비된 풀 리퀘스트를 감시하는 자동화가 실행됩니다.';

  @override
  String get convertToDraft => '초안으로 전환';

  @override
  String get convertToDraftConfirm =>
      '이 풀 리퀘스트가 다시 초안이 됩니다. 대기 중인 리뷰 요청은 취소되며, 다시 준비 완료로 표시할 때까지 병합할 수 없습니다.';

  @override
  String get pullRequestMarkedReady => '풀 리퀘스트를 리뷰 준비 완료로 표시했습니다';

  @override
  String get pullRequestConvertedToDraft => '풀 리퀘스트를 초안으로 전환했습니다';

  @override
  String failedToMarkPrReady(String error) {
    return '리뷰 준비 완료로 표시하지 못했습니다: $error';
  }

  @override
  String failedToConvertPrToDraft(String error) {
    return '초안으로 전환하지 못했습니다: $error';
  }

  @override
  String get checksFailing => '검사 실패';

  @override
  String get reviewsPending => '일부 리뷰가 대기 중입니다';

  @override
  String get mergeConflictsWithBase => '이 브랜치에 해결해야 할 충돌이 있습니다';

  @override
  String get branchOutOfDateWithBase => '이 브랜치가 베이스 브랜치보다 오래되었습니다';

  @override
  String get mergeBlockedByBranchProtection => '브랜치 보호가 이 병합을 차단합니다';

  @override
  String get confirm => '확인';

  @override
  String get trustedSitesSectionTitle => '신뢰할 수 있는 사이트';

  @override
  String get trustedSitesEmpty =>
      '신뢰할 수 있는 사이트가 없습니다. 도메인을 추가하면 해당 사이트의 차단이 해제됩니다.';

  @override
  String get addTrustedSite => '신뢰할 수 있는 사이트 추가';

  @override
  String get removeTrustedSite => '제거';

  @override
  String get disableBlockingForThisSite => '이 사이트의 차단 해제';

  @override
  String get enableBlockingForThisSite => '이 사이트의 차단 사용';

  @override
  String get enterDomainHint => '예: example.com';

  @override
  String get invalidDomain => '올바른 도메인을 입력하세요 (예: example.com)';

  @override
  String get pageLoadTimedOut => '페이지 로드 시간이 초과되었습니다. 다시 로드하거나 브라우저에서 여세요.';

  @override
  String get pipelinesScreenTitle => '파이프라인';

  @override
  String get pipelinesScreenSubtitle => '선언적 다단계 에이전트 워크플로';

  @override
  String get pipelinesRunPipeline => '파이프라인 실행';

  @override
  String get pipelineRunLauncherTitle => '파이프라인 실행';

  @override
  String get pipelineRunSubtitle => '파이프라인을 선택한 뒤 입력을 채우고 실행을 시작하세요.';

  @override
  String get pipelineRunNoInputsBadge => '입력 없음';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '입력 $count개',
      one: '입력 1개',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => '이 파이프라인에는 입력이 없습니다.';

  @override
  String get pipelineRunSubmit => '파이프라인 실행';

  @override
  String get pipelineRunCouldNotStart => '실행을 시작하지 못했습니다.';

  @override
  String pipelineRunStarted(String name) {
    return '$name을 시작했습니다';
  }

  @override
  String get pipelineRunEmptyTitle => '실행할 수 있는 파이프라인이 없습니다';

  @override
  String get pipelineRunEmptyHint =>
      '파이프라인을 활성화하고 편집기에서 수동 실행을 켜면 여기에서 시작할 수 있습니다.';

  @override
  String get pipelineRunManageTemplates => '파이프라인 관리';

  @override
  String get pipelineRunSettingsTitle => '수동 실행';

  @override
  String get pipelineRunSettingsAllow => '수동 실행 허용';

  @override
  String get pipelineRunSettingsAllowHelp =>
      '실행 페이지에 이 파이프라인을 표시하여 직접 시작할 수 있게 합니다.';

  @override
  String get pipelineRunSettingsConcurrencyTitle => '동시 실행';

  @override
  String get pipelineRunSettingsMaxParallel => '최대 병렬 실행 수';

  @override
  String get pipelineRunSettingsMaxParallelHelp =>
      '비워 두면 제한이 없습니다. 추가 실행은 대기열에서 기다리다가 자리가 나면 시작됩니다.';

  @override
  String get pipelineRunSettingsMaxParallelHint => '제한 없음';

  @override
  String get pipelineRunSettingsMaxParallelInvalid =>
      '1 이상의 정수를 입력하거나, 제한 없음으로 비워 두세요.';

  @override
  String get pipelineRunSettingsInputsTitle => '입력';

  @override
  String get pipelineRunSettingsAddInput => '입력 추가';

  @override
  String get pipelineRunSettingsNoInputs => '아직 입력이 없습니다.';

  @override
  String get pipelineInputEditTitle => '입력 필드';

  @override
  String get pipelineInputKeyLabel => '키';

  @override
  String get pipelineInputKeyHelp => '값을 저장할 상태 키입니다(예: repo_full_name).';

  @override
  String get pipelineInputLabelLabel => '레이블';

  @override
  String get pipelineInputTypeLabel => '유형';

  @override
  String get pipelineInputOptionsLabel => '옵션(쉼표로 구분)';

  @override
  String get pipelineInputDefaultLabel => '기본값';

  @override
  String get pipelineInputPlaceholderLabel => '플레이스홀더';

  @override
  String get pipelineInputHelpLabel => '도움말';

  @override
  String get pipelineInputRequiredLabel => '필수';

  @override
  String get pipelineInputTypeText => '텍스트';

  @override
  String get pipelineInputTypeMultiline => '여러 줄 텍스트';

  @override
  String get pipelineInputTypeNumber => '숫자';

  @override
  String get pipelineInputTypeBoolean => '토글';

  @override
  String get pipelineInputTypeSelect => '선택';

  @override
  String get pipelinesEmpty => '아직 파이프라인 실행이 없습니다';

  @override
  String get pipelinesEmptyHint => '\'파이프라인 실행\'을 눌러 시작하세요.';

  @override
  String get pipelinesNoSteps => '아직 기록된 단계가 없습니다';

  @override
  String get pipelinesNoActiveWorkspace => '파이프라인을 보려면 워크스페이스를 선택하세요';

  @override
  String pipelinesLoadError(String error) {
    return '파이프라인을 불러오지 못했습니다: $error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return '파이프라인을 시작하지 못했습니다: $error';
  }

  @override
  String get pipelineStatusPending => '대기 중';

  @override
  String get pipelineStatusQueued => '대기열';

  @override
  String get pipelineStatusRunning => '실행 중';

  @override
  String get pipelineStatusSuspended => '일시 중지됨';

  @override
  String get pipelineStatusCompleted => '완료됨';

  @override
  String get pipelineStatusFailed => '실패';

  @override
  String get pipelineStatusCancelled => '취소됨';

  @override
  String get pipelineStatusSkipped => '건너뜀';

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$total개 단계 중 $completed개';
  }

  @override
  String get pipelineWaterfallTimeline => '타임라인';

  @override
  String pipelineWaterfallActive(String duration) {
    return '활성 $duration';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return '유휴 $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip =>
      '활성 합계에서 제외된 시간입니다. 실행이 중지되었거나 단계 사이에서 대기 중이었습니다.';

  @override
  String get pipelineStepStarted => '시작';

  @override
  String get pipelineStepFinished => '종료';

  @override
  String get pipelineStepDurationLabel => '소요 시간';

  @override
  String get pipelineStepBranch => '브랜치';

  @override
  String get pipelineStepViewConversation => '대화 보기';

  @override
  String get pipelineStepError => '오류';

  @override
  String get pipelineStepInput => '입력';

  @override
  String get pipelineStepOutput => '출력';

  @override
  String get pipelineStepNotExecuted => '아직 실행되지 않음';

  @override
  String pipelineRunFailedAtStep(String step) {
    return '$step에서 실패';
  }

  @override
  String get pipelineRunTriggerManual => '수동';

  @override
  String get pipelineStepSkippedReason => '건너뜀';

  @override
  String get pipelineStepPriorAttempts => '이전 시도';

  @override
  String get pipelineStepAttemptLabel => '시도';

  @override
  String pipelineStepAttemptN(int number) {
    return '시도 $number';
  }

  @override
  String get pipelineStepAttemptInterrupted => '중단됨';

  @override
  String get pipelineRunColumnPipeline => '파이프라인';

  @override
  String get pipelineRunColumnDuration => '소요 시간';

  @override
  String get pipelineRunQueueNext => '다음';

  @override
  String pipelineRunQueuePosition(int position) {
    return '대기열 $position번째';
  }

  @override
  String get pipelineRunColumnStarted => '시작';

  @override
  String get pipelineRunHistory => '실행 기록';

  @override
  String get pipelineRunHistoryEmpty => '다른 실행이 없습니다';

  @override
  String pipelineRunRerunAgo(String time) {
    return '재실행 $time';
  }

  @override
  String pipelineRunAttempt(int number) {
    return '시도 $number';
  }

  @override
  String pipelineRunFirstStarted(String time) {
    return '최초 시작 $time';
  }

  @override
  String get pipelineRunFilterAll => '전체';

  @override
  String get pipelineRunFilterEmpty => '이 필터에 맞는 실행이 없습니다';

  @override
  String get relativeJustNow => '방금';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count분 전',
      one: '1분 전',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count시간 전',
      one: '1시간 전',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일 전',
      one: '1일 전',
    );
    return '$_temp0';
  }

  @override
  String get teamsTitle => '팀';

  @override
  String get teamsAddTeam => '팀 추가';

  @override
  String get teamsLoadError => '팀을 불러오지 못했습니다';

  @override
  String get teamsEmptyTitle => '아직 팀이 없습니다';

  @override
  String get teamsEmptyDescription =>
      '에이전트를 팀으로 묶어, 팀에 할당된 작업이 리더를 통해 위임되도록 합니다.';

  @override
  String get teamCreateTitle => '새 팀';

  @override
  String get teamEditTitle => '팀 수정';

  @override
  String get teamNameLabel => '팀 이름';

  @override
  String get teamNameHint => '예: Frontend';

  @override
  String get teamDescriptionLabel => '설명';

  @override
  String get teamDescriptionHint => '이 팀이 담당하는 일';

  @override
  String get teamLeaderLabel => '리더';

  @override
  String get teamLeaderHelp => '팀에 할당된 작업을 받아 가장 적합한 멤버에게 위임하는 조정자입니다.';

  @override
  String get teamNoLeader => '리더 없음';

  @override
  String get teamInstructionsLabel => '운영 지침';

  @override
  String get teamInstructionsHelp => '리더 브리핑에 추가됩니다. 팀 규칙, 에스컬레이션 규칙, 어조 등.';

  @override
  String get teamInstructionsHint => '선택 사항';

  @override
  String get teamSaved => '팀을 저장했습니다';

  @override
  String get teamMembersError => '멤버를 불러오지 못했습니다';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '멤버 $count명',
      one: '멤버 1명',
      zero: '멤버 없음',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => '멤버 추가';

  @override
  String get teamAddMemberTitle => '멤버 추가';

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
  String get teamNoAgentsToAdd => '모든 에이전트가 이미 이 팀에 있습니다.';

  @override
  String get teamRemoveMember => '팀에서 제거';

  @override
  String get teamLeaderBadge => '리더';

  @override
  String get teamUnknownAgent => '알 수 없는 에이전트';

  @override
  String get teamMembersEmpty => '아직 멤버가 없습니다';

  @override
  String get teamMembersEmptyDescription => '리더가 위임할 에이전트를 추가하세요.';

  @override
  String get teamSelectPrompt => '팀을 선택하세요';

  @override
  String get teamSelectPromptDescription => '목록에서 팀을 선택하거나 새로 만드세요.';

  @override
  String get teamDeleteTitle => '팀을 삭제할까요?';

  @override
  String teamDeleteBody(String name) {
    return '$name이(가) 삭제됩니다. 소속 에이전트는 영향을 받지 않습니다.';
  }

  @override
  String get teamHasLeaderTooltip => '리더가 있습니다';

  @override
  String get pipelineTemplatesNav => '파이프라인 템플릿';

  @override
  String get pipelineTemplatesTitle => '파이프라인 템플릿';

  @override
  String get pipelineTemplatesSubtitle => '에이전트를 조율하는 파이프라인을 드래그 앤 드롭으로 편집합니다.';

  @override
  String get pipelineTemplatesNew => '새 템플릿';

  @override
  String get pipelineTemplatesEmpty => '파이프라인 템플릿이 없습니다. 새로 만들어 시작하세요.';

  @override
  String get pipelineTemplateIdLabel => '템플릿 ID';

  @override
  String get pipelineTemplateBuiltInBadge => '기본 제공';

  @override
  String get pipelineTemplateDeleteConfirmTitle => '템플릿을 삭제할까요?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return '파이프라인 템플릿 $name을 삭제할까요? 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get pipelineTemplateEditorTitle => '파이프라인 편집';

  @override
  String get pipelineTemplateEditorSubtitle =>
      '사이드바에서 노드 유형을 캔버스로 끌어다 놓은 뒤 서로 연결하세요.';

  @override
  String get unsavedChanges => '저장되지 않은 변경 사항';

  @override
  String get nodeLibraryTitle => '노드 라이브러리';

  @override
  String get nodeLibraryHint => '항목을 캔버스로 끌어다 놓으면 노드가 추가됩니다.';

  @override
  String get editorDragHint => '라이브러리에서 끌어다 놓고, 노드를 클릭해 편집하세요';

  @override
  String get editorEmptyCanvas => '라이브러리에서 노드를 끌어다 놓아 시작하세요.';

  @override
  String get pipelineWhenThisHappens => '이 일이 발생하면';

  @override
  String get pipelineDoThis => '이 작업을 실행';

  @override
  String get pipelineAddStep => '단계 추가';

  @override
  String get pipelineTidyUp => '레이아웃 정리';

  @override
  String get pipelineEditorHint => '단계를 끌어 배치하세요 · 핸들을 끌어 연결하세요';

  @override
  String get pipelineRemoveConnection => '연결 제거';

  @override
  String get pipelineDragToConnect => '드래그하여 연결';

  @override
  String get pipelineNewDefaultName => '새 파이프라인';

  @override
  String get nodeCategoryTriggers => '트리거';

  @override
  String get triggerEventWebhook => '웹훅';

  @override
  String get pipelineAddTrigger => '트리거 추가';

  @override
  String get pipelineOnEvent => '이벤트 시';

  @override
  String get nodeConfigTitle => '노드 설정';

  @override
  String get nodeConfigKind => '종류';

  @override
  String get nodeConfigLabel => '레이블';

  @override
  String get nodeConfigAgent => '에이전트';

  @override
  String get nodeConfigAgentHint => '에이전트를 선택하세요…';

  @override
  String get nodeConfigInputKeys => '입력 키 (쉼표로 구분)';

  @override
  String get nodeConfigInputKeysHelp =>
      '이 노드가 사용하는 상태 키입니다. 프롬프트의 플레이스홀더 치환에 쓰입니다.';

  @override
  String get nodeConfigRepos => '클론할 저장소';

  @override
  String get nodeConfigReposHelp =>
      '이 노드가 대화를 시작할 때 클론하고 코드 인덱싱하는 저장소입니다. 모든 저장소를 선택하면 전체를 클론합니다(기본값).';

  @override
  String get nodeConfigRepoBranchHint => '브랜치 (기본값)';

  @override
  String get nodeConfigRepoBranchHelp =>
      '각 체크아웃이 만들어지는 기준 브랜치입니다. 비우면 저장소의 기본 브랜치를 사용합니다. 워크트리에는 별도 브랜치가 생기므로 에이전트가 커밋해도 이 브랜치에는 반영되지 않습니다.';

  @override
  String nodeConfigReposDynamic(String entries) {
    return '유지된 동적 항목: $entries';
  }

  @override
  String get nodeConfigCreateConversation => '여기서 대화 열기';

  @override
  String get nodeConfigCreateConversationHelp =>
      '에이전트 노드가 여러 개 이어질 때는 끄세요. 각 노드가 이름이 있는 스트림을 엽니다. 에이전트 노드가 하나일 때는 켜서 방에 제목 없는 대화가 옆에 보이지 않게 하세요.';

  @override
  String get nodeConfigConversationTitle => '대화 이름';

  @override
  String get nodeConfigConversationTitleHelp =>
      '하류 에이전트 노드에 같은 이름을 지정하면 하나의 스트림에서 함께 작업합니다. 기본값은 노드 레이블입니다.';

  @override
  String get nodeConfigSpaceName => '스페이스 이름';

  @override
  String get nodeConfigSpaceNameHelp =>
      '이 노드가 여는 방의 이름입니다. 프롬프트와 같은 상태 플레이스홀더를 지원합니다. 비우면 노드 레이블을 사용합니다.';

  @override
  String get nodeConfigSpaceNameHint => 'pr_number 리뷰';

  @override
  String get nodeConfigStreamTitle => '대화 이름';

  @override
  String get nodeConfigStreamTitleHelp =>
      '이 노드의 에이전트가 방 안에서 작업하는 이름 있는 스트림입니다. 프롬프트와 같은 상태 플레이스홀더를 지원합니다. 비우면 방의 기본 대화로 들어가며, 팬아웃 시 모든 에이전트가 한 대화에 섞입니다.';

  @override
  String get nodeConfigConversationTitleHint => '아키텍처 분석';

  @override
  String get nodeConfigOutputKey => '출력 키';

  @override
  String get nodeConfigPrompt => '프롬프트 템플릿';

  @override
  String get nodeConfigPromptHelp => '이중 중괄호 플레이스홀더로 런타임에 상태에서 값을 가져옵니다.';

  @override
  String get nodeConfigScript => 'Bash 스크립트';

  @override
  String get nodeConfigScriptHelp =>
      'bash -c로 실행됩니다. GITHUB_TOKEN이 설정됩니다. 플레이스홀더는 실행 전에 치환됩니다.';

  @override
  String get nodeConfigTriggers => '트리거 출처';

  @override
  String get nodeConfigNoUpstream => '연결할 다른 노드가 없습니다.';

  @override
  String get nodeConfigRouteKeys => '라우트 키';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return '$source의 라우트 키';
  }

  @override
  String get conditionSectionTitle => '조건';

  @override
  String get conditionMode => '모드';

  @override
  String get conditionModeFilesAny => '파일 존재 — 하나라도';

  @override
  String get conditionModeFilesAll => '파일 존재 — 모두';

  @override
  String get conditionModeComparison => '비교';

  @override
  String get conditionModeSwitch => '스위치';

  @override
  String get conditionFilePaths => '파일 경로';

  @override
  String get conditionFilePathsAnyHelp =>
      '한 줄에 경로 하나, 기준 디렉터리 기준 상대 경로입니다. 하나라도 있으면 true로 라우팅합니다.';

  @override
  String get conditionFilePathsAllHelp =>
      '한 줄에 경로 하나, 기준 디렉터리 기준 상대 경로입니다. 모두 있을 때만 true로 라우팅합니다.';

  @override
  String get conditionBaseKey => '기준 디렉터리 키';

  @override
  String get conditionBaseKeyHelp =>
      '경로가 해석되는 디렉터리를 담은 상태 키입니다(기본값 repo_local_path).';

  @override
  String get conditionRecursive => '하위 디렉터리 검색';

  @override
  String get conditionNegate => '반전: 값이 없을 때 true로 라우팅';

  @override
  String get conditionLeft => '왼쪽 값';

  @override
  String get conditionOperator => '연산자';

  @override
  String get conditionRight => '오른쪽 값';

  @override
  String get conditionSwitchKey => '상태 키로 분기';

  @override
  String get conditionCases => '케이스 (쉼표로 구분)';

  @override
  String get conditionCasesHelp => '값과 순서대로 비교할 라우트 키입니다.';

  @override
  String get conditionDefaultCase => '기본 케이스';

  @override
  String get triggerPanelTitle => '트리거';

  @override
  String get triggerPanelHelp => '이 파이프라인을 시작하는 조건입니다.';

  @override
  String get triggerManualHelp => '실행 페이지에 표시하고 직접 시작합니다.';

  @override
  String get triggerSectionAutomatic => '자동 트리거';

  @override
  String get triggerAddButton => '트리거 추가';

  @override
  String get triggerNoneYet => '자동 트리거가 아직 없습니다.';

  @override
  String get triggerAddDialogTitle => '트리거 추가';

  @override
  String get triggerKindLabel => '트리거 유형';

  @override
  String get triggerKindEvent => '이벤트 발생 시';

  @override
  String get triggerKindSchedule => '일정에 따라';

  @override
  String get triggerKindWebhook => '웹훅으로';

  @override
  String get triggerScheduleExprLabel => '일정 (cron 또는 every:seconds)';

  @override
  String get triggerTimezoneLabel => '시간대 (선택)';

  @override
  String get triggerCatchUpLabel => '놓친 실행 처리';

  @override
  String get triggerCatchUpRunOnce => '한 번만 실행';

  @override
  String get triggerCatchUpSkip => '건너뛰기';

  @override
  String get syncHealthTitle => '동기화 상태';

  @override
  String get syncHealthNoConfigs => '동기화 연결이 아직 없습니다';

  @override
  String get syncHealthNeverSynced => '동기화한 적 없음';

  @override
  String get syncOutcomeOk => '동기화됨';

  @override
  String get syncOutcomeFailed => '실패';

  @override
  String get syncOutcomeSkipped => '건너뜀';

  @override
  String syncHealthFailedStreak(int count) {
    return '연속 $count회 실패';
  }

  @override
  String get triggerWebhookHelp =>
      '서명된 웹훅 URL이 생성됩니다. 외부 시스템이 이 URL로 POST하여 이 파이프라인을 시작합니다.';

  @override
  String get triggerWebhookPathLabel => '웹훅 경로';

  @override
  String get triggerEventFieldLabel => '이벤트';

  @override
  String get triggerNoMoreEvents => '사용 가능한 이벤트가 모두 연결되어 있습니다.';

  @override
  String get triggerMatchStatusLabel => '상태가 다음일 때만';

  @override
  String get triggerSummaryNone => '트리거 없음';

  @override
  String triggerEverySeconds(int seconds) {
    return '$seconds초마다';
  }

  @override
  String get triggerEventManual => '수동 실행';

  @override
  String get triggerEventSchedule => '일정';

  @override
  String get triggerEventPrStatusChanged => 'PR 상태 변경';

  @override
  String get triggerEventExternalPr => '외부 PR 열림';

  @override
  String get triggerEventPrPublished => 'PR 게시됨';

  @override
  String get triggerEventPrMerged => 'PR 병합됨';

  @override
  String get triggerEventRepoAdded => '저장소 추가됨';

  @override
  String get triggerEventCodeGraphWatch => '파일 변경';

  @override
  String pipelineRunCauseChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '변경된 파일 $count개',
      one: '변경된 파일 1개',
    );
    return '$_temp0';
  }

  @override
  String pipelineRunCauseMorePaths(int count) {
    return '+$count개 더';
  }

  @override
  String get pipelineRunCauseRescan => '디스크에서 변경됨';

  @override
  String get pipelineRunCauseInitial => '이 체크아웃의 최초 인덱싱';

  @override
  String get triggerEventMessageReceived => '메시지 수신';

  @override
  String get triggerEventTicketCompleted => '티켓 완료';

  @override
  String get triggerEventTicketFailed => '티켓 실패';

  @override
  String get triggerEventTicketCancelled => '티켓 취소';

  @override
  String get triggerEventBudgetCrossed => '예산 한도 초과';

  @override
  String get nodeLibrarySearchHint => '노드 검색';

  @override
  String get nodeLibraryNoMatches => '일치하는 노드 없음';

  @override
  String get nodeCategoryFlow => '흐름 및 로직';

  @override
  String get nodeCategoryPr => 'PR 리뷰';

  @override
  String get nodeCategoryAgents => '에이전트';

  @override
  String get nodeCategoryMessaging => '메시징';

  @override
  String get nodeCategoryCode => '코드';

  @override
  String get triggerDisabledTag => '꺼짐';

  @override
  String get pipelineInputTypeRepo => '저장소';

  @override
  String get pipelineRunNoRepos => '이 워크스페이스에 아직 저장소가 없습니다.';

  @override
  String get allowTicketingApi => '티켓팅 API 호출 허용';

  @override
  String get ticketingApiKey => '티켓팅 API 키';

  @override
  String get ticketingApiKeySubtitle => '티켓팅 제공자의 API 키를 샌드박스에 주입합니다.';

  @override
  String get ticketingProvider => '티켓팅 제공자';

  @override
  String get connectGitHubAndTicketing =>
      '코드 호스트를 연결하면 Control Center가 풀 리퀘스트, 이슈, 리뷰를 읽을 수 있습니다. 티켓팅 제공자도 선택적으로 연결할 수 있습니다. 자격 증명은 이 기기가 아니라 서버에 보관됩니다.';

  @override
  String get triggerEventTicketAssigned => '티켓 할당됨';

  @override
  String get triggerEventTicketCreated => '티켓 생성됨';

  @override
  String get triggerEventTicketStatusChanged => '티켓 상태 변경';

  @override
  String get triggerEventMeetingRecordingStopped => '회의 녹음 중지';

  @override
  String get triggerEventSkillUpdated => '스킬 업데이트됨';

  @override
  String get triggerEventSpaceDeleted => '스페이스 삭제됨';

  @override
  String get triggerExternalPrHelp =>
      'Control Center가 아니라 코드 호스트에서 열린 풀 리퀘스트입니다.';

  @override
  String get triggerPrPublishedHelp => 'Control Center 또는 에이전트가 연 풀 리퀘스트입니다.';

  @override
  String get triggerPrStatusChangedHelp =>
      '병합, 닫힘, 열림, 다시 열림 또는 승인. 검사기에서 상태로 필터링하세요.';

  @override
  String get triggerPrMergedHelp => '풀 리퀘스트가 병합될 때만입니다. 닫히거나 다시 열릴 때는 아닙니다.';

  @override
  String get triggerRepoAddedHelp => '이 워크스페이스에 저장소가 연결됩니다.';

  @override
  String get triggerCodeGraphWatchHelp => '연결된 저장소의 파일이 디스크에서 바뀝니다.';

  @override
  String get triggerMessageReceivedHelp => '스페이스에 새 메시지가 도착합니다.';

  @override
  String get triggerTicketCreatedHelp => '이 워크스페이스에 티켓이 만들어집니다.';

  @override
  String get triggerTicketStatusChangedHelp => '티켓이 상태 사이를 이동합니다.';

  @override
  String get triggerTicketCompletedHelp => '티켓이 성공적으로 끝납니다.';

  @override
  String get triggerTicketFailedHelp => '에이전트 실행이 실패했고 티켓이 실패로 표시됩니다.';

  @override
  String get triggerTicketCancelledHelp => '티켓이 취소되며 계속되지 않습니다.';

  @override
  String get triggerBudgetCrossedHelp => '워크스페이스 또는 에이전트 지출 한도를 넘습니다.';

  @override
  String get triggerTicketAssignedHelp => '티켓이 사람, 에이전트 또는 팀에 할당됩니다.';

  @override
  String get triggerMeetingRecordingStoppedHelp => '회의 녹음이 끝납니다.';

  @override
  String get triggerSkillUpdatedHelp => '스킬이 설치되거나 업데이트됩니다.';

  @override
  String get triggerSpaceDeletedHelp => '대화 스페이스가 삭제됩니다.';

  @override
  String get navTickets => '티켓';

  @override
  String get ticketsTitle => '티켓';

  @override
  String get newTicket => '새 티켓';

  @override
  String get noTicketsYet => '아직 티켓이 없습니다';

  @override
  String get addCollaborator => '협업자 추가';

  @override
  String get noCollaborators => '아직 협업자가 없습니다';

  @override
  String get linkedPullRequests => '연결된 풀 리퀘스트';

  @override
  String get noLinkedPullRequests => '아직 연결된 풀 리퀘스트가 없습니다';

  @override
  String get stopAgent => '에이전트 중지';

  @override
  String get ticketProperties => '속성';

  @override
  String get ticketTabIssue => '이슈';

  @override
  String get ticketSelectPrompt => '티켓을 선택하면 세부 정보를 볼 수 있습니다';

  @override
  String get unassigned => '미할당';

  @override
  String get ticketStatusBacklog => '백로그';

  @override
  String get ticketStatusOpen => '할 일';

  @override
  String get ticketStatusInProgress => '진행 중';

  @override
  String get ticketStatusInReview => '리뷰 중';

  @override
  String get ticketStatusDone => '완료';

  @override
  String get ticketStatusBlocked => '차단됨';

  @override
  String get ticketStatusFailed => '실패';

  @override
  String get ticketStatusCancelled => '취소됨';

  @override
  String get notificationTicketAssigned => '티켓 할당됨';

  @override
  String get notificationTicketStatusChanged => '티켓 상태 변경됨';

  @override
  String get priority => '우선순위';

  @override
  String get status => '상태';

  @override
  String get assignee => '담당자';

  @override
  String get labels => '레이블';

  @override
  String get noLabelsYet => '아직 레이블이 없습니다';

  @override
  String get clearLabels => '레이블 지우기';

  @override
  String get pipelineStepAgentActivity => '에이전트 활동';

  @override
  String get runStatusCompleted => '완료됨';

  @override
  String get runStatusQueued => '대기 중';

  @override
  String get ticketDescription => '설명';

  @override
  String get ticketPriorityNone => '없음';

  @override
  String get ticketPriorityUrgent => '긴급';

  @override
  String get ticketPriorityHigh => '높음';

  @override
  String get ticketPriorityMedium => '보통';

  @override
  String get ticketPriorityLow => '낮음';

  @override
  String get ticketViewList => '목록';

  @override
  String get ticketViewBoard => '보드';

  @override
  String get ticketTitlePlaceholder => '이슈 제목';

  @override
  String get ticketDescriptionPlaceholder => '설명을 추가하세요…';

  @override
  String get createMore => '더 만들기';

  @override
  String selectedCount(int count) {
    return '$count개 선택됨';
  }

  @override
  String get clearSelection => '선택 해제';

  @override
  String get bulkDeleteTitle => '티켓 삭제';

  @override
  String bulkDeleteMessage(int count) {
    return '선택한 티켓 $count개를 삭제할까요? 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get assignTo => '할당할 대상…';

  @override
  String get sectionMembers => '멤버';

  @override
  String get sectionAgents => '에이전트';

  @override
  String get sidebarGroupWorkspace => '워크스페이스';

  @override
  String get notificationsTitle => '알림';

  @override
  String get notificationsTooltip => '알림';

  @override
  String get notificationsEmpty => '새 알림이 없습니다';

  @override
  String notificationsUnreadCount(int count) {
    return '$count개 읽지 않음';
  }

  @override
  String get notificationsMarkRead => '읽음으로 표시';

  @override
  String get notificationsMarkUnread => '읽지 않음으로 표시';

  @override
  String get notificationsEntryActions => '알림 작업';

  @override
  String get markAllRead => '모두 읽음으로 표시';

  @override
  String get teamsNav => '팀';

  @override
  String get noWorkspace => '워크스페이스 없음';

  @override
  String get selectWorkspace => '워크스페이스 선택';

  @override
  String get navMemory => '메모리';

  @override
  String get memoryTabFacts => '사실';

  @override
  String get memoryTabPolicies => '정책';

  @override
  String get memoryGraphShowFacts => '사실 표시';

  @override
  String get memoryGraphHideFacts => '사실 숨기기';

  @override
  String get memoryGraphExpandAll => '모든 사실 펼치기';

  @override
  String get memoryGraphCollapseAll => '모든 사실 접기';

  @override
  String get memoryTabGraph => '지식 그래프';

  @override
  String get memoryNoWorkspace => '워크스페이스를 선택하면 메모리를 볼 수 있습니다.';

  @override
  String get searchArticles => '아티클 검색';

  @override
  String get filterAll => '전체';

  @override
  String get filterUnread => '읽지 않음';

  @override
  String get filterSaved => '저장됨';

  @override
  String get saveArticle => '아티클 저장';

  @override
  String get removeFromSaved => '저장 목록에서 제거';

  @override
  String get filterBySource => '출처별 필터';

  @override
  String get viewAsList => '목록 보기';

  @override
  String get viewAsGrid => '그리드 보기';

  @override
  String get noMatchingArticles => '일치하는 아티클이 없습니다';

  @override
  String get noMatchingArticlesBody => '다른 검색어나 출처 필터를 사용해 보세요.';

  @override
  String get allCaughtUp => '모두 확인했습니다';

  @override
  String get allCaughtUpBody => '읽지 않은 아티클이 없습니다. 나중에 다시 확인해 주세요.';

  @override
  String get openArticlesInAppDescription => '기본 브라우저 대신 내장 리더에서 링크를 엽니다.';

  @override
  String get blockAdsTrackersDescription =>
      '리더에서 연 아티클에서 광고, 트래커, 쿠키 배너를 제거합니다.';

  @override
  String get agentQuestionHeader => '질문이 있습니다';

  @override
  String get agentQuestionAnsweredLabel => '답변 완료';

  @override
  String get agentQuestionSubmit => '답변 제출';

  @override
  String get agentQuestionFreeformHint => '답변을 입력하세요…';

  @override
  String get agentQuestionAnswerLabel => '내 답변';

  @override
  String agentQuestionProgress(int index, int count) {
    return '질문 $index / $count';
  }

  @override
  String get agentQuestionSkip => '건너뛰기';

  @override
  String get agentQuestionSkippedLabel => '건너뜀';

  @override
  String get agentQuestionFreeformOptionHint => '직접 설명해 주세요…';

  @override
  String get reviewRequested => '리뷰 요청됨';

  @override
  String get connectGitHubHint =>
      'GitHub에 로그인하거나 설정 → 나 → 프로필 및 신원 → 코드 호스팅에서 토큰을 추가하세요';

  @override
  String get connectGitHubToLoadPrs => '풀 리퀘스트를 불러오려면 GitHub를 연결하세요';

  @override
  String get noRepositoriesConfigured => '구성된 리포지토리가 없습니다';

  @override
  String openedAgo(String age) {
    return '$age에 열림';
  }

  @override
  String prTimelineOpened(String author) {
    return '$author 님이 이 풀 리퀘스트를 열었습니다';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '커밋 $count개',
      one: '커밋 1개',
    );
    return '$author 님이 $_temp0와 함께 이 풀 리퀘스트를 열었습니다';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return '$actor 님이 $reviewers에게 리뷰를 요청했습니다';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '$actor 님이 $reviewers에 대한 리뷰 요청을 제거했습니다';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '$actor 님이 $requested에게 리뷰를 요청하고 $removed에 대한 리뷰 요청을 제거했습니다';
  }

  @override
  String prTimelineAddedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '레이블',
      one: '레이블',
    );
    return '$actor 님이 $labels $_temp0을 추가했습니다';
  }

  @override
  String prTimelineRemovedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '레이블',
      one: '레이블',
    );
    return '$actor 님이 $labels $_temp0을 제거했습니다';
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
      other: '레이블',
      one: '레이블',
    );
    String _temp1 = intl.Intl.pluralLogic(
      removedCount,
      locale: localeName,
      other: '레이블',
      one: '레이블',
    );
    return '$actor 님이 $added $_temp0을 추가하고 $removed $_temp1을 제거했습니다';
  }

  @override
  String prTimelineCommitted(String author) {
    return '$author 님이 커밋했습니다';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '커밋 $count개',
      one: '커밋 1개',
    );
    return '$author 님이 $_temp0를 푸시했습니다';
  }

  @override
  String prTimelineApproved(String author) {
    return '$author 님이 이 변경을 승인했습니다';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return '$author 님이 변경을 요청했습니다';
  }

  @override
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '코드 댓글 $count개',
      one: '코드 댓글 1개',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '$author 님이 리뷰했습니다';
  }

  @override
  String get prTimelineSomeone => '누군가';

  @override
  String get prTimelineBotBadge => '봇';

  @override
  String updatedAgo(String age) {
    return '$age에 업데이트됨';
  }

  @override
  String get checksPassing => '검사 통과';

  @override
  String get checksRunning => '검사 실행 중';

  @override
  String get needsYourReview => '검토가 필요합니다';

  @override
  String get checks => '검사';

  @override
  String get noReviewersAssigned => '지정된 리뷰어가 없습니다';

  @override
  String get noAssignees => '지정된 담당자가 없습니다';

  @override
  String get loadingEllipsis => '로드 중…';

  @override
  String get loadingChecks => '검사를 로드하는 중…';

  @override
  String get noChecksYet => '아직 실행된 검사가 없습니다';

  @override
  String get noChangesToReview => '검토할 변경 사항이 없습니다';

  @override
  String checksFailingCount(int count) {
    return '$count개 실패';
  }

  @override
  String get showMore => '더 보기';

  @override
  String get showLess => '간략히';

  @override
  String get backToPullRequests => '풀 리퀘스트로 돌아가기';

  @override
  String get pullRequestNotFound => '풀 리퀘스트를 찾을 수 없습니다';

  @override
  String get pullRequestNotFoundBody => '병합되었거나, 닫혔거나, 이동되었을 수 있습니다.';

  @override
  String get couldntLoadPullRequest => '이 풀 리퀘스트를 로드할 수 없습니다';

  @override
  String get showDetails => '세부 정보 보기';

  @override
  String get noDescriptionProvided => '설명이 없습니다.';

  @override
  String get factsHint => '에이전트가 학습하면 사실이 여기에 표시됩니다.';

  @override
  String get noFactsMatch => '검색과 일치하는 사실이 없습니다';

  @override
  String get memoryLoadError => '메모리를 로드할 수 없습니다';

  @override
  String get sortRecent => '최근';

  @override
  String get sortConfidence => '신뢰도';

  @override
  String get confidenceTooltip =>
      '에이전트가 이 사실이 참이라고 확신하는 정도입니다. 0%에서 100%까지입니다.';

  @override
  String get supersededTooltip => '더 새로운 사실이 이 사실을 대체했습니다.';

  @override
  String get domain => '도메인';

  @override
  String get fitToView => '화면에 맞추기';

  @override
  String get project => '프로젝트';

  @override
  String get newProject => '새 프로젝트';

  @override
  String get editProject => '프로젝트 편집';

  @override
  String get deleteProject => '프로젝트 삭제';

  @override
  String get noProject => '프로젝트 없음';

  @override
  String get allTickets => '모든 티켓';

  @override
  String get projectNamePlaceholder => '프로젝트 이름';

  @override
  String get projectDescriptionPlaceholder => '설명 (선택 사항)';

  @override
  String get projectColorLabel => '색상';

  @override
  String get noProjectsYet => '아직 프로젝트가 없습니다';

  @override
  String get projectTicketsEmpty => '이 프로젝트에 아직 티켓이 없습니다';

  @override
  String get createProject => '프로젝트 만들기';

  @override
  String projectProgress(int done, int total) {
    return '$total개 중 $done개 완료';
  }

  @override
  String deleteProjectConfirm(String name) {
    return '\"$name\"을(를) 삭제할까요? 티켓은 유지되며 프로젝트에서만 제거됩니다.';
  }

  @override
  String get projectStatusActive => '진행 중';

  @override
  String get projectStatusCompleted => '완료됨';

  @override
  String get projectStatusArchived => '보관됨';

  @override
  String get markProjectCompleted => '완료로 표시';

  @override
  String get markProjectActive => '진행 중으로 표시';

  @override
  String get archiveProject => '보관';

  @override
  String get restoreProject => '복원';

  @override
  String get relations => '관계';

  @override
  String get relateTo => '관계 지정';

  @override
  String get relationSubIssueOf => '다음의 하위 이슈…';

  @override
  String get relationParentOf => '다음의 상위 이슈…';

  @override
  String get relationBlockedBy => '다음으로 인해 차단됨…';

  @override
  String get relationBlocking => '다음을 차단 중…';

  @override
  String get relationRelatedTo => '다음과 관련됨…';

  @override
  String get relationDuplicateOf => '다음의 복제…';

  @override
  String get relationGroupParent => '상위';

  @override
  String get relationGroupSubIssues => '하위 이슈';

  @override
  String get relationGroupBlockedBy => '차단됨';

  @override
  String get relationGroupBlocking => '차단 중';

  @override
  String get relationGroupRelated => '관련';

  @override
  String get relationGroupDuplicateOf => '원본';

  @override
  String get relationGroupDuplicatedBy => '복제됨';

  @override
  String get copyId => 'ID 복사';

  @override
  String get ticketIdCopied => '티켓 ID를 복사했습니다';

  @override
  String get searchTicketsHint => '티켓 검색…';

  @override
  String get noMatchingTickets => '일치하는 티켓이 없습니다';

  @override
  String get clearAll => '모두 지우기';

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '리포 $repos개',
      one: '리포 1개',
    );
    String _temp1 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs개',
      one: '1개',
    );
    return '$_temp0에서 검토 대기 중인 PR $_temp1';
  }

  @override
  String get manageWorkspacesSubtitle =>
      '워크스페이스 이름을 바꾸고 마크를 변경할 수 있습니다. 왼쪽에서 편집할 항목을 선택하세요.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '워크스페이스 $count개',
      one: '워크스페이스 1개',
      zero: '워크스페이스 없음',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '리포 $repos개',
      one: '리포 1개',
      zero: '리포 없음',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '에이전트 $agents개',
      one: '에이전트 1개',
      zero: '에이전트 0개',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => '아이덴티티';

  @override
  String get uploadImage => '이미지 업로드';

  @override
  String get failedToSaveLogo =>
      '로고 이미지를 저장하지 못했습니다. 앱이 선택한 파일을 읽을 수 있는지 확인하세요.';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG 또는 GIF, 최대 2MB. 그렇지 않으면 워크스페이스 이니셜을 사용합니다.';

  @override
  String get workspaceNameFieldHelp => '스위처, 브레드크럼, 모든 화면에 표시됩니다.';

  @override
  String get dangerZone => '위험 영역';

  @override
  String get deleteThisWorkspace => '이 워크스페이스 삭제';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return '$name과 리포지토리 연결, 에이전트, 메모리가 영구적으로 삭제됩니다. 되돌릴 수 없습니다.';
  }

  @override
  String get discard => '버리기';

  @override
  String discardChangesQuestion(String name) {
    return '$name의 저장하지 않은 변경 사항을 버리시겠어요?';
  }

  @override
  String get workspaceUpdated => '워크스페이스가 업데이트되었습니다';

  @override
  String get editTitle => '제목 편집';

  @override
  String get editDescription => '설명 편집';

  @override
  String get addDescription => '설명 추가';

  @override
  String get prTitlePlaceholder => '제목';

  @override
  String get prBodyPlaceholder => '설명을 남겨 주세요';

  @override
  String get write => '작성';

  @override
  String get overview => '개요';

  @override
  String get noFilesChanged => '변경된 파일이 없습니다';

  @override
  String get diff => 'Diff';

  @override
  String get preview => '미리보기';

  @override
  String get outdated => '오래됨';

  @override
  String get outdatedComments => '오래된 댓글';

  @override
  String outdatedCountLabel(int count) {
    return '오래된 $count개';
  }

  @override
  String get prTemplateLabel => '템플릿';

  @override
  String get prTemplateDefault => '기본';

  @override
  String get addReviewers => '리뷰어 추가';

  @override
  String get addAssignees => '담당자 추가';

  @override
  String get searchUsers => '사람 검색…';

  @override
  String get searchReviewers => '사람과 팀 검색…';

  @override
  String get usersSectionLabel => '사람';

  @override
  String get userStatusBusy => '바쁨';

  @override
  String get teamsSectionLabel => '팀';

  @override
  String get suggestedReviewers => '추천 리뷰어';

  @override
  String get noMatchingUsers => '일치하는 사람이 없습니다';

  @override
  String get noMatchingReviewers => '일치하는 항목이 없습니다';

  @override
  String get requiredByCodeOwners => '코드 오너 필수';

  @override
  String reviewedOnBehalfOf(String login) {
    return '$login 대신';
  }

  @override
  String get team => '팀';

  @override
  String get markdownBold => '굵게';

  @override
  String get markdownItalic => '기울임';

  @override
  String get markdownHeading => '제목';

  @override
  String get markdownBulletList => '글머리 기호 목록';

  @override
  String get markdownChecklist => '체크리스트';

  @override
  String get markdownCode => '코드';

  @override
  String get markdownLink => '링크';

  @override
  String get markdownQuote => '인용';

  @override
  String get markdownSupported => 'Markdown을 지원합니다';

  @override
  String get markdownAttachImages => '클릭하여 이미지를 추가하세요';

  @override
  String failedToUpdateTitle(String error) {
    return '제목을 업데이트하지 못했습니다: $error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return '설명을 업데이트하지 못했습니다: $error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return '리뷰어를 업데이트하지 못했습니다: $error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return '담당자를 업데이트하지 못했습니다: $error';
  }

  @override
  String get discardChangesConfirm => '변경 사항을 취소할까요?';

  @override
  String get newPr => '새 PR';

  @override
  String get openPullRequest => '풀 리퀘스트 열기';

  @override
  String get composePrSubtitle => '푸시한 브랜치에서 엽니다. 에이전트나 티켓은 관여하지 않습니다';

  @override
  String get createAsDraft => '초안으로 만들기';

  @override
  String get composePrNoRepo => 'GitHub 리포지토리가 선택되지 않았습니다';

  @override
  String get composePrNoRepoHint =>
      '풀 리퀘스트를 열려면 GitHub에 연결된 리포지토리가 있는 워크스페이스를 선택하세요.';

  @override
  String get composePrPickBranches => '변경 사항을 미리 보려면 베이스와 비교 브랜치를 선택하세요.';

  @override
  String get composePrNothingToCompare => '이 브랜치 사이에 변경 사항이 없습니다.';

  @override
  String get repository => '리포지토리';

  @override
  String get baseBranchLabel => '베이스';

  @override
  String get compareBranchLabel => '비교';

  @override
  String get selectBranch => '브랜치 선택';

  @override
  String get navMeetings => '회의';

  @override
  String get meetingsNoWorkspace => '회의를 보려면 워크스페이스를 선택하세요.';

  @override
  String get meetingsEmpty => '아직 회의가 없습니다';

  @override
  String get meetingsEmptyHint =>
      '첫 회의를 녹음하세요. 오디오는 이 기기에 남고, 에이전트가 노트, 결정 사항, 할 일로 정리합니다.';

  @override
  String get meetingNotesHint => '간단히 메모해 두세요. 회의가 끝나면 에이전트가 내용을 확장합니다.';

  @override
  String get meetingSpeakerMe => '나';

  @override
  String get meetingStatusRecording => '녹음 중';

  @override
  String get meetingStatusProcessing => '처리 중';

  @override
  String get meetingStatusDone => '완료';

  @override
  String get meetingStatusFailed => '실패';

  @override
  String get meetingsSubtitle => '이 기기에서 녹음·전사한 뒤 에이전트가 요약합니다.';

  @override
  String get meetingsRecordMeeting => '회의 녹음';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '지금 $count건 처리 중',
      one: '지금 1건 처리 중',
    );
    return '$_temp0';
  }

  @override
  String meetingsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '회의 $count건',
      one: '회의 1건',
      zero: '회의 없음',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLedgerOpenActions => '미완료 할 일';

  @override
  String get meetingsLedgerDecisions => '결정 사항';

  @override
  String get meetingsLiveOpen => '녹음 열기';

  @override
  String get meetingTemplateShort => '템플릿';

  @override
  String get meetingsStatThisWeek => '이번 주';

  @override
  String get meetingsStatRecorded => '녹음됨';

  @override
  String get meetingsFilterAll => '전체';

  @override
  String get meetingsFilterDone => '완료';

  @override
  String get meetingsFilterProcessing => '처리 중';

  @override
  String get meetingsSearchHint => '제목, 사람, 앱으로 필터…';

  @override
  String get meetingsBucketToday => '오늘';

  @override
  String get meetingsBucketYesterday => '어제';

  @override
  String get meetingsBucketEarlierThisWeek => '이번 주 초';

  @override
  String get meetingsBucketLastWeek => '지난주';

  @override
  String get meetingsBucketOlder => '이전';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '결정 사항 $count건',
      one: '결정 사항 1건',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total개 할 일';
  }

  @override
  String get meetingsEnhancedPill => '향상됨';

  @override
  String get meetingsTranscribing => '전사 및 요약 중…';

  @override
  String get meetingsOpenAction => '열기';

  @override
  String get meetingsStopProcessing => '중지';

  @override
  String get meetingsStillTranscribing => '아직 전사 중입니다. 완료되면 요약이 표시됩니다.';

  @override
  String get meetingsNoMatch => '일치하는 회의가 없습니다';

  @override
  String get meetingsNoMatchHint => '다른 필터나 검색어를 사용해 보세요.';

  @override
  String get meetingBackAllMeetings => '모든 회의';

  @override
  String get meetingReRunSummary => '요약 다시 실행';

  @override
  String get meetingExport => '내보내기';

  @override
  String get meetingAugmentingBanner =>
      '트랜스크립트에서 노트를 보강하는 중 — 결정 사항과 액션 아이템을 추출하고 있습니다…';

  @override
  String get meetingTabNotes => '노트';

  @override
  String get meetingTabTranscript => '트랜스크립트';

  @override
  String get meetingTabActionItems => '액션 아이템';

  @override
  String get meetingTabDecisions => '결정 사항';

  @override
  String get meetingNotesEnhancedToggle => '보강됨';

  @override
  String get meetingNotesYoursToggle => '내 노트';

  @override
  String get meetingEnhancedByAgent => '에이전트가 보강함 · 트랜스크립트 기반';

  @override
  String get meetingEnhancedPending => '에이전트가 아직 이 요약을 작성하고 있습니다.';

  @override
  String get meetingNotesEmpty => '보강된 노트가 아직 없습니다.';

  @override
  String get meetingNotesSavedLocally => '로컬에 저장됨';

  @override
  String get meetingNotesSaving => '저장 중…';

  @override
  String get meetingViewFullTranscript => '전체 트랜스크립트 보기';

  @override
  String get meetingTranscriptSearchHint => '트랜스크립트 검색…';

  @override
  String get meetingSpeakerEveryone => '모두';

  @override
  String get meetingSpeakerOthers => '기타';

  @override
  String get meetingTranscriptEmpty => '트랜스크립트가 아직 없습니다.';

  @override
  String get meetingActionItemsEmpty => '추출된 액션 아이템이 없습니다.';

  @override
  String get meetingActionItemFrom => '이 미팅에서';

  @override
  String get meetingCreateTicket => '티켓 만들기';

  @override
  String meetingTicketCreated(String key) {
    return '티켓 $key을 만들고 전달했습니다.';
  }

  @override
  String get meetingTicketFailed => '티켓을 만들지 못했습니다.';

  @override
  String get meetingDecisionsEmpty => '기록된 결정 사항이 없습니다.';

  @override
  String get meetingEditTitle => '제목 편집';

  @override
  String get meetingTitleLabel => '제목';

  @override
  String get meetingAddActionItem => '액션 아이템 추가';

  @override
  String get meetingEditActionItem => '액션 아이템 편집';

  @override
  String get meetingDeleteActionItem => '액션 아이템 삭제';

  @override
  String get meetingActionItemContentLabel => '액션 아이템';

  @override
  String get meetingActionItemContentHint => '무엇을 해야 하나요?';

  @override
  String get meetingActionItemOwnerLabel => '담당자';

  @override
  String get meetingActionItemOwnerHint => '담당자는 누구인가요? (선택)';

  @override
  String get meetingAddDecision => '결정 사항 추가';

  @override
  String get meetingEditDecision => '결정 사항 편집';

  @override
  String get meetingDeleteDecision => '결정 사항 삭제';

  @override
  String get meetingDecisionContentLabel => '결정 사항';

  @override
  String get meetingDecisionContentHint => '무엇을 결정했나요?';

  @override
  String get meetingReRunStarted => '트랜스크립트로 요약을 다시 실행하는 중…';

  @override
  String get meetingReRunNoTranscript => '요약할 트랜스크립트가 아직 없습니다.';

  @override
  String get meetingExportCopied => '노트를 Markdown으로 클립보드에 복사했습니다.';

  @override
  String get meetingExportSaved => '미팅을 내보냈습니다.';

  @override
  String meetingExportFailed(String error) {
    return '내보내기에 실패했습니다: $error';
  }

  @override
  String get meetingExportNothing => '내보낼 내용이 아직 없습니다.';

  @override
  String get meetingPlaybackPlay => '재생';

  @override
  String get meetingPlaybackPause => '일시정지';

  @override
  String get meetingPlaybackUnavailable => '이 기기에서는 오디오를 재생할 수 없습니다.';

  @override
  String get meetingDetectedTitle => '미팅이 감지됨';

  @override
  String meetingDetectedSubtitle(String label) {
    return '\"$label\"이 진행 중인 것 같습니다. 녹음할까요?';
  }

  @override
  String get meetingDetectedSubtitleGeneric => '미팅이 진행 중인 것 같습니다. 녹음할까요?';

  @override
  String get meetingDetectedRecord => '녹음';

  @override
  String get meetingDetectedDismiss => '닫기';

  @override
  String get meetingAutoStopTitle => '미팅이 끝난 것 같습니다. 녹음을 중지할까요?';

  @override
  String get meetingAutoStopStop => '중지';

  @override
  String get meetingAutoStopKeep => '계속 녹음';

  @override
  String get meetingAutoDetect => '미팅 자동 감지';

  @override
  String get meetingAutoDetectDescription =>
      '캘린더와 화상 회의 앱을 확인하고, 미팅이 시작되면 녹음을 제안합니다.';

  @override
  String get meetingsRecordingCrumb => '녹음 중…';

  @override
  String get meetingRecordTitleHint => '미팅 제목';

  @override
  String get meetingRecordTappingLabel => '탭핑:';

  @override
  String get meetingRecordMic => '마이크';

  @override
  String get meetingRecordSystemAudio => '시스템 오디오';

  @override
  String get meetingRecordPause => '일시 정지';

  @override
  String get meetingRecordResume => '다시 시작';

  @override
  String get meetingRecordStop => '중지하고 요약';

  @override
  String get meetingRecordYourNotes => '내 메모';

  @override
  String get meetingRecordNotesPlaceholder =>
      '들으면서 입력하세요. 짧은 메모만으로도 충분합니다. 중지하면 에이전트가 트랜스크립트를 바탕으로 내용을 확장합니다.';

  @override
  String get meetingRecordLiveTranscript => '실시간 트랜스크립트';

  @override
  String get meetingRecordDecoding => '기기에서 디코딩 중';

  @override
  String get meetingRecordListening =>
      '듣는 중… 1~2초 안에 음성이 여기에 표시되며, 나 / 다른 사람으로 태그가 붙습니다.';

  @override
  String get meetingRecordPausedHint => '일시 정지됨 — 다시 시작할 때까지 오디오는 무시됩니다.';

  @override
  String get meetingRecordNotActive => '진행 중인 녹음이 없습니다.';

  @override
  String get meetingHudRecording => '녹음 중';

  @override
  String get meetingHudPaused => '일시 정지됨';

  @override
  String get meetingHudOpen => '열기';

  @override
  String get meetingHudStop => '중지';

  @override
  String get meetingToolbarPopOut => '팝아웃';

  @override
  String get meetingToolbarHoldToStop => '길게 눌러 녹음 중지';

  @override
  String get meetingToolbarSemanticLabel => '회의 녹음 도구 모음';

  @override
  String get orchestrate => '오케스트레이션';

  @override
  String get orchestrationUnavailable => '오케스트레이션을 사용할 수 없습니다';

  @override
  String get orchestrationApprove => '계획 승인';

  @override
  String get orchestrationReject => '거절';

  @override
  String get orchestrationCancel => '오케스트레이션 취소';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count개 역할 — 신규 채용 $hires명';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '하위 티켓 $count개';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return '예상 비용: \$$amount';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '하위 티켓 $done/$total개 완료';
  }

  @override
  String get orchestrationStatusProposed => '제안됨';

  @override
  String get orchestrationStatusApproved => '승인됨';

  @override
  String get orchestrationStatusExecuting => '실행 중';

  @override
  String get orchestrationStatusSynthesizing => '종합 중';

  @override
  String get orchestrationStatusCompleted => '완료됨';

  @override
  String get orchestrationStatusFailed => '실패';

  @override
  String get orchestrationStatusCancelled => '취소됨';

  @override
  String get messageFailed => '실행 실패';

  @override
  String get turnLimitReached => '턴 한도에 도달해 중지되었습니다. 계속하려면 답장하세요';

  @override
  String get retried => '재시도함';

  @override
  String replyingTo(String name) {
    return '$name에게 답장 중';
  }

  @override
  String get silenceTimeoutLabel => '무응답 제한 시간(분)';

  @override
  String get silenceTimeoutHint => '예: 15 — 이 시간 동안 출력이 없으면 실행을 종료합니다';

  @override
  String get capabilityJsonMode => 'JSON 모드';

  @override
  String get capabilityModelSelection => '모델 선택';

  @override
  String get transcriptThinking => '생각 중…';

  @override
  String transcriptThoughtFor(String duration) {
    return '$duration 동안 생각함';
  }

  @override
  String get transcriptStatusMakingEdits => '수정 중…';

  @override
  String get transcriptStatusReadingFiles => '파일 읽는 중…';

  @override
  String get transcriptStatusSearching => '코드베이스 검색 중…';

  @override
  String get transcriptStatusRunningCommands => '명령 실행 중…';

  @override
  String get transcriptStatusResponding => '응답 중…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return '$tool 실행 중…';
  }

  @override
  String get transcriptInput => '입력';

  @override
  String get transcriptOutput => '출력';

  @override
  String get transcriptErrorLabel => '오류';

  @override
  String get transcriptSandboxBlocked => '샌드박스가 작업을 차단했습니다';

  @override
  String transcriptShowFullOutput(int kb) {
    return '전체 출력 보기 (+$kb KB)';
  }

  @override
  String transcriptShowAllLines(int count) {
    return '전체 $count줄 보기';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return '처음 $count줄 표시 중';
  }

  @override
  String get transcriptGrepNoMatches => '일치 항목 없음';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '일치 $matches개',
      one: '일치 1개',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '파일 $files개',
      one: '파일 1개',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return '사람 $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => '화자 이름 바꾸기';

  @override
  String get meetingRenameSpeakerTitle => '화자 이름 바꾸기';

  @override
  String get meetingSpeakerNameLabel => '이름';

  @override
  String get meetingSpeakerSuggestFromCalendar => '이 미팅의 초대 대상에서';

  @override
  String get meetingRenameSpeakerApplyAll => '이 화자의 모든 블록에 적용';

  @override
  String get meetingRenameSpeakerScopeHint => '끄면 선택한 줄만 이름이 바뀝니다.';

  @override
  String get meetingLinkEvent => '이벤트에 연결';

  @override
  String get meetingChangeEvent => '이벤트 변경';

  @override
  String get meetingLinkEventTitle => '캘린더 이벤트에 연결';

  @override
  String get meetingLinkEventSearchHint => '이벤트 검색';

  @override
  String get meetingLinkEventEmpty => '근처 캘린더 이벤트가 없습니다';

  @override
  String get meetingUnlinkEvent => '연결 해제';

  @override
  String get calendarLinkExistingMeeting => '기존 미팅에 연결';

  @override
  String get calendarLinkMeetingTitle => '미팅 연결';

  @override
  String get calendarLinkMeetingSearchHint => '미팅 검색';

  @override
  String get calendarLinkMeetingEmpty => '연결할 미팅이 없습니다';

  @override
  String get meetingRenameSpeakerFailed => '화자 이름을 바꾸지 못했습니다';

  @override
  String get calendarLinkUpdateFailed => '캘린더 연결을 업데이트하지 못했습니다';

  @override
  String get rename => '이름 바꾸기';

  @override
  String get notNow => '나중에';

  @override
  String get meetingSaveVoiceProfileTitle => '음성 프로필을 저장할까요?';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return '$name의 음성지문을 저장하면 이후 미팅에서 자동으로 인식합니다.';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return '$name의 음성 프로필을 저장했습니다';
  }

  @override
  String get meetingVoiceProfileSaveFailed => '음성 프로필을 저장하지 못했습니다';

  @override
  String get voiceProfilesSection => '음성 프로필';

  @override
  String get voiceProfilesDescription => '저장한 목소리는 이후 미팅에서 자동으로 인식됩니다.';

  @override
  String get voiceProfilesEmpty =>
      '아직 저장된 목소리가 없습니다. 미팅 기록에서 화자 이름을 지정한 다음 \"음성 프로필 저장\"을 선택하세요.';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '샘플 $count개',
      one: '샘플 1개',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => '음성 프로필 이름 바꾸기';

  @override
  String get deleteVoiceProfileTitle => '음성 프로필을 삭제할까요?';

  @override
  String deleteVoiceProfileBody(String name) {
    return '$name 인식을 중지할까요? 저장된 음성지문은 삭제됩니다. 지난 미팅에 이미 적용된 이름은 유지됩니다.';
  }

  @override
  String get connectedLabel => '연결됨';

  @override
  String get ideTabGeneral => '일반';

  @override
  String get ideTabExplorer => '탐색기';

  @override
  String get ideTabSourceControl => '소스 제어';

  @override
  String get generalSectionTodos => '할 일';

  @override
  String get generalSectionGoals => '목표';

  @override
  String get goalRunStatusActive => '진행 중';

  @override
  String get goalRunStatusPaused => '일시 중지됨';

  @override
  String get goalRunStatusCompleted => '완료됨';

  @override
  String get goalRunStatusFailed => '실패';

  @override
  String get goalRunStatusCancelled => '취소됨';

  @override
  String get goalRunStatusBudgetExhausted => '예산 소진됨';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return '실행 $run/$max · $cap 중 $cost';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return '실행 $run · $cap 중 $cost';
  }

  @override
  String goalRunDeadline(String deadline) {
    return '기한 $deadline';
  }

  @override
  String get goalRunPause => '목표 일시 중지';

  @override
  String get goalRunResume => '목표 재개';

  @override
  String goalRunResumeRaise(String cap) {
    return '재개 · 한도를 $cap으로 올리기';
  }

  @override
  String get goalRunStop => '목표 중지';

  @override
  String get generalSectionAgents => '에이전트';

  @override
  String get generalSectionTerminals => '터미널';

  @override
  String get generalTodosEmpty => '할 일이 없습니다';

  @override
  String get generalAgentsEmpty => '실행 중인 에이전트가 없습니다';

  @override
  String get generalTerminalsEmpty => '열린 터미널이 없습니다';

  @override
  String get generalSectionBrowsers => '브라우저';

  @override
  String get generalSectionComputers => '컴퓨터';

  @override
  String get generalBrowsersEmpty => '열린 브라우저가 없습니다';

  @override
  String get generalComputersEmpty => '열린 컴퓨터가 없습니다';

  @override
  String get generalSectionPhones => '휴대폰';

  @override
  String get generalPhonesEmpty => '열린 폰이 없습니다';

  @override
  String get pauseAgent => '에이전트 일시 중지';

  @override
  String get resumeAgent => '에이전트 재개';

  @override
  String get agentCannotPause => '이 에이전트는 일시 중지할 수 없습니다. 대신 중지하세요.';

  @override
  String get goalClear => '목표 지우기';

  @override
  String get undoLabelGoalClear => '목표 지우기';

  @override
  String get todoStatusPending => '시작 전';

  @override
  String get todoStatusInProgress => '진행 중';

  @override
  String get todoStatusCompleted => '완료';

  @override
  String get reorderTodo => '할 일 순서 변경';

  @override
  String get focusTerminal => '터미널에 포커스';

  @override
  String get focusMachine => '머신에 포커스';

  @override
  String get focusBrowser => '브라우저에 포커스';

  @override
  String get todoEditorTitle => '할 일 편집';

  @override
  String get todoEditorHint =>
      '한 줄에 항목 하나. 시작 전은 - [ ], 진행 중은 - [~], 완료는 - [x]를 사용하세요.';

  @override
  String get todoNeedsText => '명령 뒤에 텍스트를 추가하세요';

  @override
  String get todoNotFound => '일치하는 할 일이 없습니다';

  @override
  String get todoCleared => '할 일 목록을 지웠습니다';

  @override
  String get todoNothingToCopy => '복사할 항목이 없습니다';

  @override
  String todoAdded(String content) {
    return '\"$content\"을(를) 추가했습니다';
  }

  @override
  String todoStarted(String content) {
    return '\"$content\"을(를) 시작했습니다';
  }

  @override
  String todoCompleted(String content) {
    return '\"$content\"을(를) 완료했습니다';
  }

  @override
  String todoRemoved(String content) {
    return '\"$content\"을(를) 삭제했습니다';
  }

  @override
  String todoCopied(int count) {
    return '$count개 항목을 복사했습니다';
  }

  @override
  String todoImported(int count) {
    return '$count개 항목을 가져왔습니다';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return '알 수 없는 할 일 명령 \"$name\"';
  }

  @override
  String get terminal => '터미널';

  @override
  String get ideCloseTab => '탭 닫기';

  @override
  String get ideSplitEditor => '편집기 분할';

  @override
  String get ideSplitRight => '오른쪽으로 분할';

  @override
  String get ideSplitDown => '아래로 분할';

  @override
  String get ideSplitLeft => '왼쪽으로 분할';

  @override
  String get ideSplitUp => '위로 분할';

  @override
  String get ideCloseGroup => '그룹 닫기';

  @override
  String get ideCloseOthers => '다른 탭 닫기';

  @override
  String get ideCloseToRight => '오른쪽 탭 닫기';

  @override
  String get ideCloseSaved => '저장된 탭 닫기';

  @override
  String get ideCloseAll => '모두 닫기';

  @override
  String get ideSplit => '분할';

  @override
  String get ideToggleSidebar => '사이드바 전환';

  @override
  String get ideNewTab => '편집기 열기';

  @override
  String get ideNewTabMenu => '새 탭';

  @override
  String get ideReviewCode => '코드 검토';

  @override
  String get ideRevert => '되돌리기';

  @override
  String get ideRevertConfirmTitle => '변경 사항 되돌리기';

  @override
  String ideRevertConfirmMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '파일 $count개',
      one: '파일 1개',
    );
    return '$_temp0를 HEAD로 되돌릴까요? 워크트리 변경 사항은 버려집니다.';
  }

  @override
  String get ideRevertConfirmAction => '되돌리기';

  @override
  String get ideRevertConfirmCancel => '취소';

  @override
  String get ideRevertUntracked => '추적되지 않은 파일은 되돌릴 수 없습니다';

  @override
  String get ideRevertFailed => '파일을 되돌리지 못했습니다. 대화 워크트리를 사용할 수 없을 수 있습니다.';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '파일 $count개',
      one: '파일 1개',
    );
    return '$_temp0를 되돌리지 못했습니다(추적되지 않음).';
  }

  @override
  String get ideViewSource => '소스 보기';

  @override
  String get ideSearchMatchCase => '대/소문자 구분';

  @override
  String get ideSearchWholeWord => '단어 단위';

  @override
  String get ideSearchRegex => '정규식';

  @override
  String get ideSearchFilters => '검색 필터';

  @override
  String get ideSearchFilesToInclude => '포함할 파일';

  @override
  String get ideSearchFilesToExclude => '제외할 파일';

  @override
  String get ideNoOpenTabs => '열린 탭이 없습니다. +로 여세요.';

  @override
  String get ideBrowserAddressHint => '주소 입력 또는 검색';

  @override
  String get ideSimpleWebBrowser => '간단한 웹 브라우저';

  @override
  String get ideWebBrowser => '웹 브라우저';

  @override
  String get ideBrowserEnterUrl => '주소 표시줄에 URL을 입력하여 탐색을 시작하세요';

  @override
  String get ideCodeServer => '편집기';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return '$fileName의 변경 사항을 저장할까요?';
  }

  @override
  String get ideUnsavedChangesBody => '저장하지 않으면 변경 사항이 사라집니다.';

  @override
  String get ideDontSave => '저장 안 함';

  @override
  String get editorAutoSave => '자동 저장';

  @override
  String get editorAutoSaveDescription => '임베디드 편집기의 변경 사항을 자동으로 저장합니다.';

  @override
  String get editorAutoSaveOff => '끄기';

  @override
  String get editorAutoSaveAfterDelay => '지연 후';

  @override
  String get editorAutoSaveOnFocusChange => '포커스 변경 시';

  @override
  String get ideCodeServerUnavailable => '이 서버에서 code-server를 사용할 수 없습니다';

  @override
  String get ideCodeServerUnavailableHint =>
      '서버 호스트에 code-server(coder/code-server)를 설치한 다음 편집기를 다시 여세요.';

  @override
  String get ideCodeServerInstalling => '편집기를 준비하는 중…';

  @override
  String get ideCodeServerOpenInBrowser => '브라우저에서 편집기 열기';

  @override
  String get ideCodeServerError => '편집기를 열 수 없습니다';

  @override
  String get paneSuspendedCaption => '리소스 절약을 위해 일시 중단됨 — 포커스하면 다시 로드됩니다';

  @override
  String get ideFolderLoadFailed => '이 폴더를 불러올 수 없습니다';

  @override
  String get ideFileSearchFailed => '파일을 검색할 수 없습니다';

  @override
  String get ideSearchInFiles => '파일에서 검색';

  @override
  String get ideNoContentMatches => '일치 항목 없음';

  @override
  String get ideSourceControlCreatePr => '풀 리퀘스트 만들기';

  @override
  String ideSourceControlViewPr(int number) {
    return '풀 리퀘스트 #$number 보기';
  }

  @override
  String get ideSourceControlNoChanges => '변경 사항 없음';

  @override
  String get noReposInConversation => '이 대화에 리포지토리가 없습니다';

  @override
  String get ideSourceControlNoSpace => '대화를 열어 변경 사항을 확인하세요';

  @override
  String get ideFileLoading => '불러오는 중…';

  @override
  String get ideFileBinary => '바이너리 파일';

  @override
  String get mcpExternalServers => '외부 MCP 서버';

  @override
  String get mcpExternalServersDescription =>
      '외부 MCP 서버(GitHub, Sentry, Postgres, 브라우저 자동화)에 연결합니다. Claude, Cursor, VS Code 및 기타 도구에 구성한 서버는 자동으로 검색됩니다.';

  @override
  String get mcpApprovalMode => '도구 승인';

  @override
  String get mcpApprovalModeDescription =>
      '묻지 않고 실행할 도구 작업입니다. 읽기는 항상 허용되며, 상위 단계는 확인을 요청합니다.';

  @override
  String get mcpApprovalAlwaysAsk => '항상 묻기';

  @override
  String get mcpApprovalWrite => '쓰기 자동 승인';

  @override
  String get mcpApprovalYolo => '모두 자동 승인';

  @override
  String get mcpNoExternalServers => '검색된 외부 MCP 서버가 없습니다.';

  @override
  String get mcpAuthorize => '승인';

  @override
  String get mcpReconnect => '다시 연결';

  @override
  String get mcpExternalConnectionsNote =>
      '외부 MCP 서버는 에이전트 서버에서 실행되며 데스크톱과 웹에서 공유됩니다. OAuth 서버 승인은 데스크톱에서만 사용할 수 있습니다.';

  @override
  String get mcpStatusConnected => '연결됨';

  @override
  String get mcpStatusConnecting => '연결 중…';

  @override
  String get mcpStatusNeedsAuth => '승인 필요';

  @override
  String get mcpStatusFailed => '실패';

  @override
  String get mcpStatusCircuitOpen => '일시 중지됨';

  @override
  String get mcpStatusDisabled => '사용 안 함';

  @override
  String get providersAndModels => '프로바이더 및 모델';

  @override
  String get providersAndModelsDescription =>
      '내장 에이전트가 사용할 수 있는 모든 프로바이더를 나열합니다. API 키를 설정하거나 브라우저로 로그인한 뒤, 연결된 각 프로바이더의 모델과 요금을 확인하고 이 워크스페이스에서 사용할 프로바이더를 관리하세요.';

  @override
  String get syncNow => '지금 동기화';

  @override
  String syncNowResult(int applied, int failed) {
    return '동기화 완료 — $applied개 적용, $failed개 실패';
  }

  @override
  String syncNowFailed(String error) {
    return '동기화 실패: $error';
  }

  @override
  String get denied => '거부됨';

  @override
  String get allowed => '허용됨';

  @override
  String allowProviderSemantic(String provider) {
    return '$provider 허용';
  }

  @override
  String enabledViaEnv(String key) {
    return '$key(으)로 사용 설정됨';
  }

  @override
  String costPerMillion(String input, String output) {
    return '1M당 $input / $output';
  }

  @override
  String contextTokens(String tokens) {
    return '컨텍스트 $tokens';
  }

  @override
  String get usageAndCost => '사용량 및 비용';

  @override
  String get usageAndCostDescription => '지난 7일 동안 에이전트의 관측된 실행 비용입니다.';

  @override
  String get noUsageYet => '아직 기록된 사용량이 없습니다.';

  @override
  String get spentThisWeek => '이번 주 사용량';

  @override
  String get subscriptionUsage => '구독 사용량';

  @override
  String get subscriptionUsageUnavailable => '사용할 수 없음';

  @override
  String get subscriptionUsageExhausted => '할당량 소진';

  @override
  String get subscriptionUsageSignInRequired => '다시 로그인하세요';

  @override
  String get subscriptionUsageSignInExpired => '로그인이 만료되었습니다. 다음 실행 시 갱신됩니다';

  @override
  String get subscriptionUsagePartiallyAvailable => '일부만 사용 가능';

  @override
  String resetsIn(String duration) {
    return '재설정까지 $duration';
  }

  @override
  String get feedbackHelpful => '도움이 되었습니다';

  @override
  String get feedbackNotHelpful => '도움이 되지 않았습니다';

  @override
  String get modeChat => '채팅';

  @override
  String get modePlan => '계획';

  @override
  String get modeReview => '리뷰';

  @override
  String get modeOrchestrate => '오케스트레이트';

  @override
  String get editorTheme => '에디터 테마';

  @override
  String get editorThemeDescription =>
      'VS Code 색 테마를 가져와 내장 diff와 에디터가 IDE와 맞춰지도록 합니다.';

  @override
  String get editorThemePasteHint => 'VS Code 색 테마 JSON 파일 내용을 붙여넣으세요';

  @override
  String get editorThemeImported => '테마를 가져왔습니다';

  @override
  String get editorThemeInvalid => '올바른 VS Code 테마가 아닌 것 같습니다';

  @override
  String get importTheme => '테마 가져오기';

  @override
  String get clearTheme => '테마 지우기';

  @override
  String get openInDiffViewer => 'diff 뷰어에서 열기';

  @override
  String get shellCommand => '명령';

  @override
  String get shellOutput => '출력';

  @override
  String get revertToHere => '여기까지 되돌리기';

  @override
  String get revertConfirmBody =>
      '이 지점 이후의 메시지를 숨기고 에이전트의 파일 변경을 이 턴까지 되돌릴까요? 실행 취소할 수 있습니다.';

  @override
  String get revert => '되돌리기';

  @override
  String get revertedToHere => '여기까지 되돌렸습니다';

  @override
  String get nothingToRevert => '되돌릴 내용이 없습니다';

  @override
  String get undoRevert => '되돌리기 취소';

  @override
  String get revertUndone => '되돌리기를 취소했습니다';

  @override
  String get systemBehavior => '시스템 동작';

  @override
  String get keepAwakeTitle => '에이전트 실행 중 컴퓨터 절전 방지';

  @override
  String get keepAwakeOnSubtitle => '에이전트가 작업하는 동안 컴퓨터가 절전 모드로 전환되지 않습니다';

  @override
  String get keepAwakeOffSubtitle => '에이전트가 작업 중이어도 컴퓨터가 절전 모드로 전환될 수 있습니다';

  @override
  String get syncEngineSectionTitle => '동기화 엔진';

  @override
  String get syncEngineDescription =>
      '티켓, 메시징, 노트가 전체 스냅샷이 아닌 작은 증분 변경으로 실시간 업데이트됩니다. 토글을 끄면 해당 저장소가 전체 스냅샷 모드로 돌아갑니다. 변경 사항을 적용하려면 앱을 다시 로드하세요.';

  @override
  String get syncEngineTicketsTitle => '티켓';

  @override
  String get syncEngineMessagingTitle => '메시징';

  @override
  String get syncEngineNotesTitle => '노트';

  @override
  String get syncEngineOnSubtitle => '실시간 델타 동기화가 활성 상태입니다';

  @override
  String get syncEngineOffSubtitle => '전체 스냅샷 동기화를 사용합니다';

  @override
  String get spaces => '스페이스';

  @override
  String get spacesHomeDescription => '목록에서 스페이스를 선택하거나 새로 만드세요.';

  @override
  String get noSpacesYet => '아직 스페이스가 없습니다';

  @override
  String get newSpace => '새 스페이스';

  @override
  String get spaceName => '스페이스 이름';

  @override
  String get spaceReposHint => '포함할 리포';

  @override
  String get ideSourceControl => '소스 제어';

  @override
  String get stagedChanges => '스테이징된 변경';

  @override
  String get changes => '변경 사항';

  @override
  String get stageFile => '스테이징';

  @override
  String get unstageFile => '언스테이징';

  @override
  String get stageAll => '모든 변경 스테이징';

  @override
  String get unstageAll => '모두 언스테이징';

  @override
  String get stageChangesToCommit => '커밋할 변경 스테이징';

  @override
  String get syncToPrHead => '최신 PR 커밋 가져오기';

  @override
  String get syncedToPrHead => '최신 PR 커밋과 동기화되었습니다';

  @override
  String get syncPrHeadDirty => '동기화하기 전에 변경을 커밋하거나 버리세요';

  @override
  String get syncPrHeadFailed => 'PR 헤드와 동기화하지 못했습니다';

  @override
  String get spaceLabel => '스페이스';

  @override
  String get keybindingNewSpace => '새 스페이스';

  @override
  String get keybindingCreateANewSpaceDescription => '새 스페이스 만들기';

  @override
  String get jumpToLatest => '최신으로 이동';

  @override
  String get streaming => '스트리밍';

  @override
  String get newMessages => '새 메시지';

  @override
  String get copyLink => '링크 복사';

  @override
  String get linkCopied => '링크를 복사했습니다';

  @override
  String get agentResponding => '에이전트 응답 중';

  @override
  String get agentFinished => '에이전트 완료';

  @override
  String get harnessConnectProviderForModels => '모델을 보려면 프로바이더를 연결하세요.';

  @override
  String get providerSignOut => '로그아웃';

  @override
  String get providerWaitingForDeviceCode => '브라우저에서 코드를 확인하는 중…';

  @override
  String get providerDeviceCodeHint => '브라우저에 표시된 코드와 일치하는지 확인한 다음 승인하세요.';

  @override
  String get providerPlanUsageLoading => '플랜 사용량을 확인하는 중…';

  @override
  String get providerPlanUsageUnavailable => '이 플랜은 사용량을 보고하지 않았습니다.';

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return '$provider API 키를 삭제할까요?';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return '저장된 키가 삭제되며 다시 표시할 수 없습니다. $provider 모델을 사용하는 에이전트는 새 키를 붙여넣을 때까지 동작하지 않습니다.';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return '$provider를 삭제할까요?';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return '프로바이더와 저장된 키가 삭제됩니다. 해당 모델에 고정된 에이전트는 동작하지 않습니다.';
  }

  @override
  String get providerApiKeyHint => 'API 키 붙여넣기';

  @override
  String get providerApiKeyStoredHint => '다른 API 키를 붙여넣어 추가하세요';

  @override
  String get providerAddAnotherAccount => '다른 계정 추가';

  @override
  String get providerActiveBadge => '사용 중';

  @override
  String get providerOauthAccountFallback => 'OAuth 계정';

  @override
  String get providerApiKeyFallback => 'API 키';

  @override
  String get providerRemoveCredentialConfirmTitle => '이 자격 증명을 삭제할까요?';

  @override
  String get providerSignOutAccountConfirmTitle => '이 계정에서 로그아웃할까요?';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return '$provider를 사용하는 에이전트는 다른 키와 계정으로 전환됩니다. 남은 것이 없으면 새로 추가할 때까지 동작하지 않습니다.';
  }

  @override
  String get providerBaseUrlHint => 'Base URL (선택)';

  @override
  String get customProvidersDescription =>
      'OpenAI 또는 Anthropic 호환 엔드포인트 — Ollama, LM Studio, vLLM, 프라이빗 배포 — 에 선택적으로 API 키를 사용할 수 있습니다.';

  @override
  String get addProvider => '프로바이더 추가';

  @override
  String get noCustomProviders => '아직 커스텀 프로바이더가 없습니다.';

  @override
  String get providerNameLabel => '이름';

  @override
  String get apiTypeLabel => 'API 유형';

  @override
  String get providerBaseUrlLabel => 'Base URL';

  @override
  String get providerApiKeyOptionalHint => 'API 키 (선택)';

  @override
  String get dialectOpenAiCompatible => 'OpenAI 호환';

  @override
  String get dialectAnthropicCompatible => 'Anthropic 호환';

  @override
  String get removeProviderTooltip => '프로바이더 삭제';

  @override
  String get providerLogInWithBrowser => '브라우저로 로그인';

  @override
  String providerLoginDialogTitle(String provider) {
    return '$provider에 로그인';
  }

  @override
  String get providerLabel => '프로바이더';

  @override
  String get selectProviderToLogin => '로그인할 프로바이더를 선택하세요';

  @override
  String providerLoginFailed(String error) {
    return '로그인 실패: $error';
  }

  @override
  String get providerWaitingForBrowser => '브라우저에서 권한을 승인하는 중…';

  @override
  String get providerPasteCodeHint => '또는 브라우저의 코드를 붙여넣으세요';

  @override
  String get providerCompleteLogin => '완료';

  @override
  String get providerConnectedApiKey => 'API 키로 연결됨';

  @override
  String get providerConnectedOauth => '연결됨';

  @override
  String providerConnectedAccount(String account) {
    return '연결됨 · $account';
  }

  @override
  String get providerLocalReady => '로컬 · 준비됨';

  @override
  String get providerNotConnected => '연결되지 않음';

  @override
  String get preparingWorkspace => '워크스페이스를 준비하는 중…';

  @override
  String provisioningRunningSetupScript(String repo) {
    return '$repo 설정 스크립트를 실행하는 중…';
  }

  @override
  String get repoScriptsTitle => '스크립트';

  @override
  String get repoScriptsTooltip => '라이프사이클 스크립트 설정';

  @override
  String get repoScriptsSetupLabel => '설정 스크립트';

  @override
  String get repoScriptsSetupHelp =>
      '스페이스가 생성된 직후 해당 워크트리에서 실행됩니다. 의존성 설치, 파일 생성 등에 사용하세요. 실패하면 스페이스가 실패로 표시되며, 재시도하면 다시 실행됩니다.';

  @override
  String get repoScriptsArchiveLabel => '아카이브 스크립트';

  @override
  String get repoScriptsArchiveHelp =>
      '스페이스의 워크트리가 삭제되기 직전에 실행됩니다. 워크트리 바깥의 리소스를 정리하세요. 실패해도 삭제는 막히지 않습니다.';

  @override
  String get repoScriptsEnvHelp =>
      '워크트리에서 bash로 실행되며 CC_WORKSPACE_PATH(워크트리), CC_ROOT_PATH(저장소 루트), CC_SPACE_ID, CC_SPACE_NAME, CC_REPO_NAME이 설정됩니다.';

  @override
  String get repoScriptsSetupPlaceholder => '예: pnpm install';

  @override
  String get repoScriptsArchivePlaceholder =>
      '예: docker compose -p \$CC_SPACE_ID down';

  @override
  String get repoScriptsRecentRuns => '최근 실행';

  @override
  String get repoScriptsNoRuns => '아직 실행 기록이 없습니다';

  @override
  String get repoScriptsOutput => '출력';

  @override
  String get repoScriptsSaved => '스크립트를 저장했습니다';

  @override
  String get repoScriptsRunKindSetup => '셋업';

  @override
  String get repoScriptsRunKindArchive => '아카이브';

  @override
  String get repoScriptsRunStatusRunning => '실행 중';

  @override
  String get repoScriptsRunStatusSucceeded => '성공';

  @override
  String get repoScriptsRunStatusFailed => '실패';

  @override
  String get repoScriptsRunStatusTimedOut => '시간 초과';

  @override
  String repoScriptsExitCode(int code) {
    return '종료 코드 $code';
  }

  @override
  String provisioningCloningRepo(String repo) {
    return '$repo 클론 중…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return '$repo에서 풀 리퀘스트 체크아웃 중…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return '에이전트 $agent 설정 중…';
  }

  @override
  String get workspacePrepFailed => '워크스페이스 준비에 실패했습니다';

  @override
  String get workspacePrepStopped => '워크스페이스 준비를 중단했습니다';

  @override
  String get stopWorkspacePrep => '준비 중단';

  @override
  String get stopWorkspacePrepTooltip => '이 워크스페이스 준비를 중단합니다';

  @override
  String get stopWorkspacePrepConfirm =>
      '이 워크스페이스 준비를 중단할까요? 진행 중인 클론은 버려지며, 여기서 다시 시작할 수 있습니다.';

  @override
  String messageWillSendWhenReady(int count) {
    return '준비가 되면 메시지 $count개가 전송됩니다';
  }

  @override
  String get membersNav => '멤버';

  @override
  String get membersSettingsDescription =>
      '이 워크스페이스에 접근할 수 있는 사람: 명단, 초대, 감사 기록';

  @override
  String get memberRosterLabel => '멤버 명단';

  @override
  String get memberRepoAccessAction => '저장소 접근';

  @override
  String memberRepoAccessTitle(String name) {
    return '$name의 저장소 접근';
  }

  @override
  String get roleOwner => '소유자';

  @override
  String get roleAdmin => '관리자';

  @override
  String get roleMember => '멤버';

  @override
  String get roleViewer => '뷰어';

  @override
  String get roleGuest => '게스트';

  @override
  String get removeMemberTitle => '멤버 제거';

  @override
  String removeMemberConfirm(String name) {
    return '$name님을 이 워크스페이스에서 제거할까요? 즉시 접근 권한이 사라집니다.';
  }

  @override
  String get transferOwnershipAction => '소유권 이전';

  @override
  String get transferOwnershipTitle => '소유권 이전';

  @override
  String transferOwnershipConfirm(String name) {
    return '$name님을 이 워크스페이스의 소유자로 지정할까요? 본인은 관리자가 됩니다. 워크스페이스 삭제나 다른 관리자의 역할 변경은 소유자만 할 수 있습니다.';
  }

  @override
  String get transferOwnershipCta => '이전';

  @override
  String get auditTrailLabel => '권한 감사 기록';

  @override
  String get auditTrailDescription =>
      '허용과 거절이 모두 기록되며, 해시 체인으로 연결되어 수정이나 삭제를 감지할 수 있습니다.';

  @override
  String get auditVerifyChain => '체인 검증';

  @override
  String auditChainIntact(int count) {
    return '체인이 온전합니다 — $count개 항목을 검증했습니다';
  }

  @override
  String auditChainBroken(int seq, String reason) {
    return '$seq번 항목에서 체인이 끊겼습니다: $reason';
  }

  @override
  String get auditEmpty => '아직 기록된 결정이 없습니다.';

  @override
  String get auditDenied => '거절됨';

  @override
  String get auditAllowed => '허용됨';

  @override
  String auditOnBehalfOf(String user) {
    return '$user 대신';
  }

  @override
  String get policyTemplatesLabel => '정책 템플릿';

  @override
  String get policyTemplatesDescription =>
      '시작용 정책을 적용하거나, 워크스페이스 간에 옮길 수 있습니다.';

  @override
  String get policyTemplateStrict => '엄격';

  @override
  String get policyTemplateBalanced => '균형';

  @override
  String get policyTemplatePermissive => '허용적';

  @override
  String get policyTemplateApply => '적용';

  @override
  String policyTemplateApplied(int count) {
    return '규칙 $count개를 적용했습니다';
  }

  @override
  String get policyExport => '정책 복사';

  @override
  String get policyExported => '정책을 클립보드에 복사했습니다';

  @override
  String get policyImport => '정책 붙여넣기';

  @override
  String policyImported(int count) {
    return '규칙 $count개를 가져왔습니다';
  }

  @override
  String get approveAndRemember => '8시간 동안 승인';

  @override
  String get approveAndRememberTooltip =>
      '이 작업을 승인하고 8시간 동안 이 공간에서 비슷한 작업을 다시 묻지 않습니다. 시간이 지나면 자동으로 만료됩니다.';

  @override
  String get unknownUserLabel => '알 수 없는 사용자';

  @override
  String get inviteMember => '멤버 초대';

  @override
  String get inviteRepoAccessHeader => '저장소 액세스';

  @override
  String get inviteRepoAccessExplainer =>
      '선택한 저장소만 지정한 권한으로 초대받은 사람과 공유됩니다. 나머지는 보이지 않습니다.';

  @override
  String get grantLevelRead => '읽기';

  @override
  String get grantLevelReview => '리뷰';

  @override
  String get grantLevelWrite => '쓰기';

  @override
  String get inviteExpiryLabel => '만료 기간';

  @override
  String get expiryOneDay => '1일';

  @override
  String get expirySevenDays => '7일';

  @override
  String get expiryThirtyDays => '30일';

  @override
  String get createInviteAction => '초대 만들기';

  @override
  String get inviteOneTimeCodeLabel => '일회용 코드';

  @override
  String get inviteCodeShownOnce => '이 코드는 한 번만 표시됩니다. 지금 복사하세요.';

  @override
  String get inviteLinkLabel => '초대 링크';

  @override
  String get inviteRedeemHint => '초대받은 사람에게 코드를 공유하세요. 서버 URL에서 코드를 사용하면 됩니다.';

  @override
  String get inviteScanQr => '또는 스캔하여 사용';

  @override
  String get inviteLoopbackWarningTitle => '초대가 로컬 주소를 가리킵니다';

  @override
  String get inviteLoopbackWarningBody =>
      '다른 기기의 협업자는 이 서버에 연결할 수 없습니다. 터널을 시작하거나(설정 → 연동 → 이 서버 공유) 네트워크에 바인딩하여 외부 사용자가 연결할 수 있게 하세요.';

  @override
  String get inviteStatusOpen => '유효';

  @override
  String get inviteStatusUsed => '사용됨';

  @override
  String get inviteStatusRevoked => '취소됨';

  @override
  String get inviteStatusExpired => '만료됨';

  @override
  String inviteCreatedTime(String time) {
    return '$time에 생성됨';
  }

  @override
  String inviteExpiresOn(String date) {
    return '$date에 만료';
  }

  @override
  String get noActivityYet => '아직 활동이 없습니다';

  @override
  String get couldNotLoadMembers => '멤버를 불러오지 못했습니다';

  @override
  String get couldNotLoadInvites => '초대를 불러오지 못했습니다';

  @override
  String get couldNotLoadActivity => '활동을 불러오지 못했습니다';

  @override
  String get yourDevices => '내 기기';

  @override
  String get yourDevicesDescription => '이 서버에서 계정에 연결된 클라이언트입니다.';

  @override
  String get noOwnDevices => '아직 계정에 연결된 기기가 없습니다';

  @override
  String get renameDeviceTitle => '기기 이름 변경';

  @override
  String get revokeDeviceTitle => '기기 연결 해제';

  @override
  String revokeDeviceConfirm(String label) {
    return '$label의 연결을 해제할까요? 즉시 연결이 끊기며 더 이상 이 서버에 접근할 수 없습니다.';
  }

  @override
  String devicePairedTime(String time) {
    return '$time에 연결됨';
  }

  @override
  String deviceLastSeenTime(String time) {
    return '마지막 접속 $time';
  }

  @override
  String get deviceNeverSeen => '한 번도 연결되지 않음';

  @override
  String get profileSectionLabel => '프로필';

  @override
  String get profileSectionDescription => '팀원에게 보이는 이름과 Git 커밋 작성자 정보입니다.';

  @override
  String get displayNameLabel => '표시 이름';

  @override
  String get emailLabel => '이메일';

  @override
  String get gitAuthorNameLabel => 'Git 작성자 이름';

  @override
  String get gitAuthorEmailLabel => 'Git 작성자 이메일';

  @override
  String get profileSaved => '프로필이 저장되었습니다';

  @override
  String get presenceOnline => '온라인';

  @override
  String get presenceIdle => '자리 비움';

  @override
  String get presenceTyping => '입력 중…';

  @override
  String get presenceAgentThinking => '생각 중';

  @override
  String get presenceAgentRunning => '실행 중';

  @override
  String get presenceAgentBlocked => '차단됨';

  @override
  String get presenceAgentDone => '완료';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String presenceNameStatusCost(String name, String status, String cost) {
    return '$name — $status ($cost)';
  }

  @override
  String get presenceRailLabel => '온라인 사용자';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => '방해 금지 모드 켜기';

  @override
  String get dndTooltipOff => '방해 금지 모드 끄기';

  @override
  String get startPresenting => '발표 시작';

  @override
  String get stopPresenting => '발표 종료';

  @override
  String spotlightPresentingBanner(String name) {
    return '$name 님이 발표 중입니다';
  }

  @override
  String get spotlightLeave => '나가기';

  @override
  String typingIndicator(String name) {
    return '$name 님이 입력 중…';
  }

  @override
  String get ideTabNotes => '노트';

  @override
  String get ideSidebarAllViews => '모든 보기';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return '모든 보기 ($count개 숨김)';
  }

  @override
  String get ideSidebarPinView => '사이드바에 고정';

  @override
  String get ideSidebarUnpinView => '사이드바에서 고정 해제';

  @override
  String get notesEmptyHint => '이 대화를 이어받을 사람을 위한 노트를 추가하세요…';

  @override
  String get notesEditTooltip => '노트 편집';

  @override
  String notesUpdatedBy(String name, String time) {
    return '$name 님이 업데이트함 · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '$name 님이 편집 중';
  }

  @override
  String get notesSaveFailed => '노트를 저장하지 못했습니다';

  @override
  String get reactionAddTooltip => '반응 추가';

  @override
  String reactionToggleTooltip(String emoji) {
    return '$emoji로 반응하기';
  }

  @override
  String get autonomyDialLabel => '자율성';

  @override
  String get autonomyProposeOnly => '제안만';

  @override
  String get autonomyActWithApproval => '승인 후 실행';

  @override
  String get autonomyActFreely => '자유롭게 실행';

  @override
  String get autonomyDefaultOption => '기본값';

  @override
  String get checkerLabel => '체커';

  @override
  String get checkerNone => '없음';

  @override
  String get checkerCaption => '체커는 다른 에이전트의 완료된 실행을 검토합니다.';

  @override
  String get takeoverTooltip => '워크트리 인수';

  @override
  String get takeoverBannerSelf => '이 대화의 워크트리를 인수했습니다';

  @override
  String takeoverBannerOther(String name) {
    return '$name 님이 이 대화의 워크트리를 인수했습니다';
  }

  @override
  String get handBackButton => '반환';

  @override
  String get handBackDialogTitle => '워크트리 반환';

  @override
  String get handBackDialogNoteHint => '에이전트를 위한 노트(선택)…';

  @override
  String takeoverFailed(String message) {
    return '인수하지 못했습니다: $message';
  }

  @override
  String handBackFailed(String message) {
    return '반환하지 못했습니다: $message';
  }

  @override
  String get planStudioTitle => '플랜 스튜디오';

  @override
  String get plansTitle => '플랜';

  @override
  String get plansSubtitle => '활성 플랜, 플랜 문서, 플레이북';

  @override
  String get plansActiveSection => '활성 플랜';

  @override
  String get plansDocumentsSection => '플랜 문서';

  @override
  String get plansPlaybooksSection => '플레이북';

  @override
  String get plansNoActive => '아직 활성 플랜이 없습니다.';

  @override
  String get plansNoDocuments => '아직 플랜 문서가 없습니다.';

  @override
  String get plansNoPlaybooks => '아직 플레이북이 없습니다.';

  @override
  String get planNotFound => '플랜을 찾을 수 없습니다.';

  @override
  String get planOpenInStudio => '열기';

  @override
  String get planNodeTitle => '제목';

  @override
  String get planNodeDescription => '설명';

  @override
  String get planNodeDescriptionHint => '이 단계에서 할 일…';

  @override
  String get planNodeApplyDescription => '적용';

  @override
  String get planNodeRole => '역할';

  @override
  String get planNodeDependencies => '의존 대상';

  @override
  String get planNodeDependenciesHint => '의존 항목 추가';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '의존 항목 $count개',
      one: '의존 항목 1개',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies => '의존 항목이 없어 플랜이 시작되면 바로 실행됩니다';

  @override
  String get planNodeOutputSchema => '출력 스키마 (JSON)';

  @override
  String get planNodeEstimate => '예상';

  @override
  String get planNodeProvenance => '출처';

  @override
  String get planNodeAlreadyExecuted => '이미 실행됨 — 편집하면 여기서부터 플랜이 분기됩니다.';

  @override
  String get planNewNodeTitle => '새 단계';

  @override
  String get planEstimateNoHistory => '아직 기록이 없습니다';

  @override
  String get planEstimateBlastUnknown => '영향 범위: 알 수 없음';

  @override
  String get planEstimatePartial => '부분';

  @override
  String get planEstimateAction => '추정';

  @override
  String planEstimateDuration(String range) {
    return '소요 시간 $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return '영향 범위: 파일 $files개, 심볼 $symbols개';
  }

  @override
  String get planApprove => '플랜 승인';

  @override
  String get planApproveSelectedNodes => '선택 항목 승인';

  @override
  String get planReject => '거부';

  @override
  String get planCancel => '실행 중단';

  @override
  String get planContinueNode => '노드 계속';

  @override
  String get planTotalNotEstimated => '아직 추정되지 않음';

  @override
  String get planBudgetExceeded => '예산 초과';

  @override
  String planBudgetCeiling(String amount) {
    return '예산 ≤ \$$amount';
  }

  @override
  String get planVersionsTitle => '버전';

  @override
  String get planNoRevisions => '아직 개정 내역이 없습니다.';

  @override
  String get planDiffIdentical => '변경 사항이 없습니다.';

  @override
  String get planDiffGoalChanged => '목표가 변경됨';

  @override
  String get planDiffBudgetChanged => '예산이 변경됨';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'v$fromRev에서 v$toRev(으)로의 변경 사항';
  }

  @override
  String planDiffAdded(String node) {
    return '$node 추가됨';
  }

  @override
  String planDiffRemoved(String node) {
    return '$node 제거됨';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return '$node 변경됨: $fields';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return '엣지 추가됨: $edge';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return '엣지 제거됨: $edge';
  }

  @override
  String planDiffRoleAdded(String role) {
    return '역할 추가됨: $role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return '역할 제거됨: $role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return '역할 재할당됨: $role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return '플랜이 다시 계획되었습니다. 승인하신 버전은 v$approved이며 현재는 v$current입니다. 계속하기 전에 변경 사항을 검토하세요.';
  }

  @override
  String planLiveActualCost(String amount) {
    return '실제 비용: \$$amount';
  }

  @override
  String get planPlaybookRun => '실행';

  @override
  String get planPlaybookDelete => '플레이북 삭제';

  @override
  String get planPlaybookProposed => '플랜이 제안되었습니다. 플랜 스튜디오에서 승인하세요.';

  @override
  String get planPlaybookAnchorTicket => '앵커 티켓';

  @override
  String get planPlaybookPickTicket => '티켓 선택…';

  @override
  String get planPlaybookProposeRun => '플랜 제안';

  @override
  String get planPlaybookRepoHint => '리포지토리 ID';

  @override
  String get planPlaybookAgentHint => '에이전트 ID';

  @override
  String planPlaybookRunTitle(String name) {
    return '$name 실행';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '파라미터 $count개';
  }

  @override
  String get recentLabel => '최근';

  @override
  String get cheatSheetTitle => '키보드 단축키';

  @override
  String get cheatSheetGlobal => '전역';

  @override
  String get cheatSheetThisScreen => '이 화면';

  @override
  String get cheatSheetReservedInBrowser => '브라우저 예약';

  @override
  String get keybindingCheatSheet => '키보드 단축키';

  @override
  String get keybindingShowKeyboardShortcutsDescription =>
      '현재 화면의 키보드 단축키 치트시트를 표시합니다';

  @override
  String get runPlaybookLabel => '플레이북 실행';

  @override
  String get playbooksLabel => '플레이북';

  @override
  String get keybindingUndo => '실행 취소';

  @override
  String get keybindingRedo => '다시 실행';

  @override
  String get keybindingUndoLastActionDescription => '마지막 되돌릴 수 있는 작업을 취소합니다';

  @override
  String get keybindingRedoLastActionDescription => '마지막으로 취소한 작업을 다시 실행합니다';

  @override
  String get undone => '실행 취소됨';

  @override
  String get redone => '다시 실행됨';

  @override
  String get undoFailed => '실행 취소할 수 없습니다';

  @override
  String get undoLabelTicketEdit => '티켓 편집';

  @override
  String get undoLabelMessageEdit => '메시지 편집';

  @override
  String get undoLabelTodoStatus => '할 일 상태';

  @override
  String get inboxTitle => '받은편지함';

  @override
  String get inboxReview => '검토';

  @override
  String get inboxOpen => '열기';

  @override
  String get inboxAllCaughtUp => '모두 확인했습니다';

  @override
  String get inboxGitHubDownTitle => 'GitHub에 장애가 있을 수 있습니다';

  @override
  String inboxGitHubDownBody(String status) {
    return 'GitHub에서 $status을 보고하고 있어, 끝난 것이 아니라 이 목록에서 풀 리퀘스트가 빠졌을 수 있습니다.';
  }

  @override
  String get inboxGitHubIdentityTitle => 'GitHub 계정을 확인할 수 없습니다';

  @override
  String get inboxGitHubIdentityBody =>
      '인박스는 GitHub 계정을 기준으로 정렬됩니다. 로드되기 전에는 대기 중인 풀 리퀘스트가 있어도 비어 있습니다.';

  @override
  String get inboxSeverityBlocking => '차단됨';

  @override
  String get inboxSeverityWaiting => '대기 중';

  @override
  String get inboxSeverityInfo => '정보';

  @override
  String get inboxSyncFailed => '동기화 실패';

  @override
  String get inboxNeedsYourAttention => '확인이 필요합니다';

  @override
  String get inboxSectionNeedsYourReview => '리뷰가 필요합니다';

  @override
  String get inboxSectionReturnedToYou => '나에게 돌아옴';

  @override
  String get inboxSectionApproved => '승인됨';

  @override
  String get inboxSectionDrafts => '초안';

  @override
  String get inboxSectionWaitingForReviewers => '리뷰어 대기 중';

  @override
  String get inboxSectionMergingAndMerged => '병합 중 및 최근 병합됨';

  @override
  String get inboxSectionWaitingForAuthor => '작성자 대기 중';

  @override
  String get inboxColumnTitle => '제목';

  @override
  String get inboxColumnChanges => '변경 사항';

  @override
  String get inboxColumnUpdated => '업데이트됨';

  @override
  String get inboxReviewApproved => '승인됨';

  @override
  String get inboxReviewChangesRequested => '변경 요청됨';

  @override
  String get inboxHeroSubtitle => '나와 관련된 모든 풀 리퀘스트를 다음 작업 기준으로 정렬합니다.';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '리뷰가 필요한 풀 리퀘스트가 $count개 있습니다',
      one: '리뷰가 필요한 풀 리퀘스트가 1개 있습니다',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개가 나에게 돌아왔습니다',
      one: '1개가 나에게 돌아왔습니다',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted => '변경 사항이 저장되지 않아 되돌렸습니다';

  @override
  String get offlinePendingLabel => '대기 중';

  @override
  String get offlineSyncingLabel => '동기화 중';

  @override
  String get copyLinkLabel => '이 페이지 링크 복사';

  @override
  String get agentsSectionLabel => '에이전트';

  @override
  String get fleetWorkersTitle => '워커';

  @override
  String get fleetWorkersSubtitle => '작업을 실행할 수 있는 머신';

  @override
  String get fleetJobsTitle => '작업';

  @override
  String get fleetJobsSubtitle => '플릿에 분산된 작업';

  @override
  String get fleetNoWorkers =>
      '아직 워커가 없습니다. 다른 머신에서 `cc_worker --server <url>`을 실행하면 플릿에 참여합니다.';

  @override
  String get fleetNoJobs => '작업이 없습니다.';

  @override
  String get fleetError => '플릿을 불러올 수 없습니다';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '코어 $count개',
      one: '코어 1개',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return '하트비트 $time';
  }

  @override
  String get fleetNoHeartbeat => '아직 하트비트가 없습니다';

  @override
  String fleetLastErrorLabel(String error) {
    return '마지막 오류: $error';
  }

  @override
  String get fleetDrain => '드레인';

  @override
  String get fleetResume => '재개';

  @override
  String get fleetRevoke => '철회';

  @override
  String get fleetRemove => '제거';

  @override
  String get fleetRevokeTitle => '워커를 철회할까요?';

  @override
  String fleetRevokeBody(String name) {
    return '$name을 철회할까요? 세션이 종료되고 진행 중인 작업은 재할당됩니다.';
  }

  @override
  String get fleetRemoveTitle => '워커를 제거할까요?';

  @override
  String fleetRemoveBody(String name) {
    return '플릿에서 $name을 제거할까요? 기록이 삭제됩니다.';
  }

  @override
  String get fleetActionFailed => '실행에 실패했습니다';

  @override
  String get fleetJobUnassigned => '미할당';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '$attempts/$max회 시도';
  }

  @override
  String get fleetPlacementReasons => '배치 결정';

  @override
  String get fleetNoPlacements => '아직 배치 결정이 없습니다.';

  @override
  String get fleetStatusOnline => '온라인';

  @override
  String get fleetStatusDraining => '드레인 중';

  @override
  String get fleetStatusOffline => '오프라인';

  @override
  String get fleetStatusIncompatible => '호환되지 않음';

  @override
  String get fleetStatusRevoked => '철회됨';

  @override
  String get fleetJobStatusQueued => '대기열에 있음';

  @override
  String get fleetJobStatusRunning => '실행 중';

  @override
  String get fleetJobStatusSucceeded => '성공';

  @override
  String get fleetJobStatusFailed => '실패';

  @override
  String get fleetJobStatusCancelled => '취소됨';

  @override
  String get evalsNoSuites => '아직 평가 스위트가 없습니다.';

  @override
  String get evalsError => '평가를 불러오지 못했습니다';

  @override
  String get evalsStarterBadge => '스타터';

  @override
  String evalsDefaultBatch(int count) {
    return '기본 배치 $count개';
  }

  @override
  String get evalsRecentRuns => '최근 실행';

  @override
  String get evalsNoRuns => '아직 실행이 없습니다.';

  @override
  String get evalsPassRate => '통과율';

  @override
  String evalsBatchTimes(int count) {
    return '× $count';
  }

  @override
  String evalsTriggeredBy(String who) {
    return '$who님이';
  }

  @override
  String evalsRunFinished(String rate) {
    return '평가가 끝났습니다 — $rate 통과';
  }

  @override
  String get evalsRunFailed => '스위트를 실행하지 못했습니다';

  @override
  String get evalsRun => '실행';

  @override
  String get evalsStatusQueued => '대기 중';

  @override
  String get evalsStatusRunning => '실행 중';

  @override
  String get evalsStatusPassed => '통과';

  @override
  String get evalsStatusFailed => '실패';

  @override
  String get bannerMeetingJoin => '참여';

  @override
  String get bannerMeetingRecordAndLink => '녹화 및 연결';

  @override
  String get bannerCalendarReconnect => '다시 연결';

  @override
  String get bannerView => '보기';

  @override
  String get soundscapeTitle => '사운드스케이프';

  @override
  String get soundscapePlay => '재생';

  @override
  String get soundscapePause => '일시정지';

  @override
  String get soundscapeMoodLabel => '분위기';

  @override
  String get soundscapeMoodFocus => '집중';

  @override
  String get soundscapeMoodRelax => '휴식';

  @override
  String get soundscapeMoodSleep => '수면';

  @override
  String get soundscapeVolumeLabel => '볼륨';

  @override
  String get soundscapeTuneLabel => '톤';

  @override
  String get soundscapeTuneMellow => '부드러운';

  @override
  String get soundscapeTuneBright => '밝은';

  @override
  String get soundscapeTuneEnergetic => '활기찬';

  @override
  String get soundscapeTuneSpacy => '몽환적인';

  @override
  String get soundscapeTuneResetHint => '두 번 탭하면 초기화됩니다';

  @override
  String get soundscapeSceneLabel => '지금 재생 중';

  @override
  String get soundscapeSceneLoading => '분위기를 맞추는 중…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees°C';
  }

  @override
  String get soundscapeLocationLabel => '위치';

  @override
  String get soundscapeLocationDetecting => '위치를 확인하는 중…';

  @override
  String get soundscapeLocationAutoNote => '이 워크스페이스에서 위치가 자동으로 감지됩니다.';

  @override
  String get soundscapeRefreshWeather => '날씨 새로고침';

  @override
  String get soundscapeAutoStartLabel => '집중 모드와 함께 시작';

  @override
  String get soundscapeAutoStartDescription =>
      '집중 세션을 시작하면 사운드스케이프가 자동으로 재생됩니다.';

  @override
  String get soundscapeReturnToApp => '앱으로 돌아가기';

  @override
  String get soundscapePopOut => '플레이어 분리';

  @override
  String get discussion => '토론';

  @override
  String get chat => '채팅';

  @override
  String get saving => '저장 중…';

  @override
  String get saved => '저장됨';

  @override
  String get saveFailed => '저장하지 못했습니다';

  @override
  String get commitAndPush => '커밋 및 푸시';

  @override
  String get commit => '커밋';

  @override
  String get commitAmend => '커밋 (amend)';

  @override
  String get commitAndSync => '커밋 및 동기화';

  @override
  String get committed => '커밋됨';

  @override
  String get commitAmended => '커밋이 수정되었습니다';

  @override
  String get commitFailed => '커밋 실패';

  @override
  String get moreCommitActions => '추가 커밋 작업';

  @override
  String get sourceControl => '소스 제어';

  @override
  String fixFindingTitle(String location) {
    return '수정: $location';
  }

  @override
  String get openInEditor => '편집기에서 열기';

  @override
  String get regexTesterTitle => '정규식 테스트';

  @override
  String get regexTesterHint => '샘플을 입력하세요';

  @override
  String get regexMatch => '일치';

  @override
  String get regexNoMatch => '일치 없음';

  @override
  String get regexInvalidPattern => '잘못된 패턴';

  @override
  String get symbolLookupNone => '인덱스나 이 끌어오기 요청에 정의가 없습니다';

  @override
  String get symbolLookupInDiff => '이 끌어오기 요청에서 찾음';

  @override
  String get symbolLookupFromBase => '기본 체크아웃에서 — 이 PR의 워크트리가 아직 인덱싱되지 않았습니다';

  @override
  String get symbolImplementations => '구현';

  @override
  String symbolCallersCount(int count) {
    return '호출자 $count개';
  }

  @override
  String get commitMessageHint => '커밋 메시지';

  @override
  String get pushedToPr => 'PR에 푸시됨';

  @override
  String get pushFailed => '푸시 실패';

  @override
  String get reviewFindings => '발견 항목';

  @override
  String get treeLabel => '트리';

  @override
  String get toggleFileTree => '파일 트리 표시 또는 숨기기';

  @override
  String get diffViewSettings => 'Diff 보기 설정';

  @override
  String get splitViewLabel => '분할';

  @override
  String get unifiedViewLabel => '통합';

  @override
  String get wrapLines => '줄 바꿈';

  @override
  String get shiftClickSelectRange => 'Shift-클릭으로 범위 선택';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '파일 $count개',
      one: '파일 1개',
    );
    return '$_temp0';
  }

  @override
  String prComplexityLoc(String loc) {
    return '$loc LOC';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return '작은 PR — $files, 검토 약 $minutes분';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return '중간 PR — $files, 검토에 약 $minutes분 필요';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return '큰 PR — $files, 검토 전에 분할을 고려하세요';
  }

  @override
  String get searchInFiles => '파일에서 검색';

  @override
  String get showFileList => '파일 목록 표시';

  @override
  String get searchInFilesHintField => '파일에서 검색…';

  @override
  String get searchInFilesHint => '풀 리퀘스트의 파일에서 검색';

  @override
  String get searchInWholeRepo => '전체 저장소에서 검색';

  @override
  String get searchInThisPullRequest => '이 풀 리퀘스트에서 검색';

  @override
  String get searchNoResults => '결과를 찾을 수 없음';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '결과 $count개',
      one: '결과 1개',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '파일 $files개',
      one: '파일 1개',
    );
    return '$_temp0($_temp1)';
  }

  @override
  String get discardChangesTitle => '변경 사항을 취소할까요?';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '파일 $count개',
      one: '파일 1개',
    );
    return '$_temp0를 HEAD로 되돌릴까요? 이 작업은 취소할 수 없습니다.';
  }

  @override
  String get discardAll => '모두 취소';

  @override
  String get discardFailed => '변경 사항 취소에 실패했습니다';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '파일 $count개',
      one: '파일 1개',
    );
    return '$_temp0를 취소했습니다';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '파일 $reverted개',
      one: '파일 1개',
    );
    return '$_temp0를 취소했습니다. $skipped개는 건너뛰었습니다(추적되지 않음)';
  }

  @override
  String get prWorktreeUnavailable => '워크스페이스가 준비되지 않음';

  @override
  String get prWorktreeUnavailableHint =>
      '풀 리퀘스트 파일 준비에 실패했습니다. 풀 리퀘스트를 다시 열어 재시도하세요.';

  @override
  String get timestampRelativeLabel => '상대';

  @override
  String get timestampRawLabel => '타임스탬프';

  @override
  String get copyTimestamp => '타임스탬프 복사';

  @override
  String get copiedTimestamp => '타임스탬프를 복사했습니다';

  @override
  String get previewDeployment => '미리보기 배포';

  @override
  String previewDeploymentTab(String site) {
    return '미리보기: $site';
  }

  @override
  String get askForReview => '리뷰 요청…';

  @override
  String get closePrsConfirmTitle => '풀 리퀘스트를 닫을까요?';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '풀 리퀘스트 $count개를 닫을까요?',
      one: '풀 리퀘스트 1개를 닫을까요?',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '풀 리퀘스트 $count개를 닫았습니다',
      one: '풀 리퀘스트 1개를 닫았습니다',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '풀 리퀘스트 $count개를 할당했습니다',
      one: '풀 리퀘스트 1개를 할당했습니다',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '풀 리퀘스트 $count개에 리뷰를 요청했습니다',
      one: '풀 리퀘스트 1개에 리뷰를 요청했습니다',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '작업 $count개가 실패했습니다',
      one: '작업 1개가 실패했습니다',
    );
    return '$_temp0';
  }

  @override
  String get diagram => '다이어그램';

  @override
  String get diagramViewSource => '소스 보기';

  @override
  String get diagramHideSource => '소스 숨기기';

  @override
  String diagramPreviewUnavailable(String reason) {
    return '다이어그램 미리보기를 사용할 수 없습니다($reason)';
  }

  @override
  String get planUnavailable => '계획을 사용할 수 없음';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '단계 $count개',
      one: '단계 1개',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => '승인 후 실행';

  @override
  String get planStatusDraft => '초안';

  @override
  String get planStatusProposed => '계획';

  @override
  String get planStatusApproved => '계획 승인됨';

  @override
  String get planStatusRejected => '계획 거절됨';

  @override
  String get planStatusSuperseded => '계획이 대체됨';

  @override
  String planRevisionLabel(int revision) {
    return '리비전 $revision';
  }

  @override
  String get adapterEnforcementTitle => '이 어댑터가 적용하는 항목';

  @override
  String get enforcementFiltersToolSurface => 'Control Center가 도구를 고릅니다';

  @override
  String get enforcementInterceptsToolCalls => '모든 호출이 실행 전에 검사됩니다';

  @override
  String get enforcementObservesCompletionContract => '실행은 산출물 조건을 따릅니다';

  @override
  String get enforcementNativeToolsInterceptable => '러너의 자체 도구가 보입니다';

  @override
  String get enforcementInProcessToolsSandboxed => '프로세스 내 도구는 샌드박스에서 실행됩니다';

  @override
  String get enforcementYes => '예';

  @override
  String get enforcementNo => '아니요';

  @override
  String get adapterEnforcementCaveats => '주의사항';

  @override
  String get enforcementSummaryModesEnforced => '적용되는 모드';

  @override
  String get enforcementSummaryModesNotEnforced => '적용되지 않는 모드';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '주의사항 $count개',
      one: '주의사항 1개',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      '읽기 전용 모드는 구조적 제약이 아닙니다. Control Center는 이 러너의 자체 도구를 제거할 수 없습니다.';

  @override
  String get caveatToolCallsNotIntercepted =>
      '실행 전 검사가 없습니다. MCP 도구 호출만 Control Center를 거칩니다.';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      '러너의 자체 파일·셸 도구는 Control Center에 도달하지 않습니다. OS 샌드박스만이 유일한 보호 장치입니다.';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      '프로세스 내 파일 도구는 샌드박스 밖에서 실행되므로, 사용 가능한 도구가 유일한 파일시스템 경계입니다.';

  @override
  String get caveatCompletionContractUnobservable =>
      'Control Center는 산출물 없이 끝난 실행을 유도하거나 실패 처리할 수 없습니다.';

  @override
  String get modeDegraded => '저하됨';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return '$adapter의 $mode 모드는 샌드박스에만 의존합니다. 에이전트의 자체 파일 도구는 가로채지 않습니다.';
  }

  @override
  String get artifactUnavailable => '아티팩트를 사용할 수 없음';

  @override
  String artifactRevisionLabel(int count) {
    return '리비전 $count개';
  }

  @override
  String get artifactShowMore => '더 보기';

  @override
  String get artifactShowLess => '접기';

  @override
  String get artifactCopy => '복사';

  @override
  String get artifactCopied => '아티팩트를 복사했습니다';

  @override
  String get artifactsTabLabel => '아티팩트';

  @override
  String get artifactsEmptyTitle => '아직 아티팩트가 없습니다';

  @override
  String get artifactsEmptyBody => '에이전트가 여기에 표, 차트, 다이어그램을 게시하면 이 목록에 표시됩니다.';

  @override
  String get artifactRevisionPickerLabel => '리비전';

  @override
  String get artifactRestoreRevision => '이 리비전 복원';

  @override
  String get artifactOpenInTab => '탭에서 열기';

  @override
  String get artifactTitleFallback => '아티팩트';

  @override
  String get providerGenerationLabel => '생성 기본값';

  @override
  String get providerGenerationHint =>
      '필드를 비워 두면 엔드포인트 기본값을 사용합니다. 모델마다 출력 상한과 샘플링 방식이 있으며, 다른 값으로 제공하면 품질이 떨어질 수 있습니다.';

  @override
  String get providerMaxTokensLabel => '최대 출력 토큰';

  @override
  String get addModel => '모델 추가';

  @override
  String get modelListTitle => '모델 목록';

  @override
  String get railProvidersGroup => '프로바이더';

  @override
  String get railCustomProvidersGroup => '사용자 지정 프로바이더';

  @override
  String get editModelSettings => '모델 설정 편집';

  @override
  String get modelIdLabel => '모델 ID';

  @override
  String get modelIdImmutableHint => '엔드포인트가 제공하는 ID이며, 등록 후에는 변경할 수 없습니다.';

  @override
  String get contextWindowLabel => '컨텍스트 윈도우';

  @override
  String get inputTypesLabel => '입력 유형';

  @override
  String get outputTypesLabel => '출력 유형';

  @override
  String get modalityText => '텍스트';

  @override
  String get modalityImage => '이미지';

  @override
  String get modalityAudio => '오디오';

  @override
  String get modalityVideo => '비디오';

  @override
  String get modalityPdf => 'PDF';

  @override
  String get modelOverrideReset => '자동으로 재설정';

  @override
  String get modelOverrideEdited => '수정됨';

  @override
  String get manualModelBadge => '직접 추가됨';

  @override
  String get modelIdRequired => '모델 ID를 입력하세요.';

  @override
  String get modelTokensInvalid => '양수인 정수 토큰 수를 입력하세요.';

  @override
  String get removeModelAction => '모델 제거';

  @override
  String removeModelConfirmTitle(String model) {
    return '$model을(를) 제거할까요?';
  }

  @override
  String get removeModelConfirmBody =>
      '모델이 목록에서 제거되며, 이 모델에 고정된 에이전트는 동작하지 않습니다. 프로바이더는 영향을 받지 않습니다.';

  @override
  String get addModelProviderTitle => '모델 프로바이더 추가';

  @override
  String get addModelProviderDescription => '사용자 지정 API 엔드포인트와 해당 모델을 구성합니다.';

  @override
  String get modelListEmptyHint => '구성된 모델이 없습니다. 채팅에서 사용하려면 모델을 추가하세요.';

  @override
  String get addProviderModelsHint =>
      '엔드포인트가 응답하면 모델이 실시간으로 가져와집니다. 자체 목록을 제공할 수 없는 경우에만 직접 추가하세요.';

  @override
  String get providerTemperatureLabel => '온도';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved => '생성 기본값이 저장되었습니다';

  @override
  String get providerGenerationInvalid =>
      '값을 확인하세요. 최대 출력 토큰과 top-k는 양수여야 하고, 온도는 0–2, top-p는 0–1이어야 합니다.';

  @override
  String get providerGenerationOverridden => '재정의됨';

  @override
  String get branchNotPushed => '푸시되지 않음';

  @override
  String branchNotOnRemote(String branch) {
    return '“$branch”는 이 대화에만 있습니다';
  }

  @override
  String get branchNotOnRemoteHint =>
      'GitHub에 이 브랜치가 없어 아직 풀 리퀘스트에 사용할 수 없습니다. 게시하면 워크트리에 있는 커밋이 푸시되며, 커밋되지 않은 변경은 그대로 둡니다.';

  @override
  String get publishBranch => '브랜치 게시';

  @override
  String branchPublished(String branch) {
    return '“$branch”을 origin에 게시했습니다';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return '브랜치를 게시했습니다. 커밋되지 않은 변경 $count개는 포함되지 않았습니다.';
  }

  @override
  String get composePrLoadingBranches => 'GitHub에서 브랜치를 불러오는 중…';

  @override
  String get composePrBranchesFailed =>
      'GitHub에서 브랜치를 불러오지 못했습니다. 브랜치 이름을 입력하거나 GitHub 연결을 확인하세요.';

  @override
  String get composePrSubtitleFromSpace => '이 대화의 브랜치에서 — GitHub에 없다면 먼저 게시하세요';

  @override
  String get obsTabInsights => '인사이트';

  @override
  String get obsTabLive => '실시간';

  @override
  String get obsTabQuality => '품질';

  @override
  String get obsTabUsage => '사용량';

  @override
  String get obsUsageTotalTokens => '총 토큰';

  @override
  String get obsUsagePeakTokens => '최대 토큰';

  @override
  String get obsUsageLongestSession => '최장 세션';

  @override
  String get obsUsageCurrentStreak => '현재 연속';

  @override
  String get obsUsageLongestStreak => '최장 연속';

  @override
  String obsUsageDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일',
      one: '1일',
      zero: '0일',
    );
    return '$_temp0';
  }

  @override
  String get obsUsageTokenActivity => '토큰 활동';

  @override
  String get obsUsageActivityModeLabel => '토큰 활동 모드';

  @override
  String get obsUsageModeDaily => '일별';

  @override
  String get obsUsageModeWeekly => '주별';

  @override
  String get obsUsageModeCumulative => '누적';

  @override
  String get obsUsageTimeRange => '기간';

  @override
  String get obsUsageTrendTitle => '일별 토큰 추이';

  @override
  String get obsUsageModelUsage => '모델 사용량';

  @override
  String get obsUsageTokensLabel => '토큰';

  @override
  String get obsUsageNoActivity => '아직 기록된 토큰 사용량이 없습니다';

  @override
  String get obsUsageOtherModels => '기타';

  @override
  String obsUsageCellReadout(String date, String tokens) {
    return '$date · $tokens 토큰';
  }

  @override
  String obsUsageActivitySummary(
    String start,
    String end,
    int activeDays,
    String peak,
  ) {
    return '$start부터 $end까지 토큰 활동. 활동일 $activeDays일. 최대일 $peak 토큰.';
  }

  @override
  String get obsScreenSubtitle => '실시간 에이전트 제어, 비용 귀속, 할당량 및 품질 신호';

  @override
  String get obsRangeLast24h => '최근 24시간';

  @override
  String get obsRangeLast7d => '최근 7일';

  @override
  String get obsRangeLast30d => '최근 30일';

  @override
  String get obsRangeAll => '전체 기간';

  @override
  String get obsAddFilter => '필터 추가';

  @override
  String get obsFilterAgent => '에이전트';

  @override
  String get obsFilterModel => '모델';

  @override
  String get obsFilterStatus => '상태';

  @override
  String get obsFilterRole => '역할';

  @override
  String get obsKpiTotalRuns => '총 실행';

  @override
  String get obsKpiTotalCost => '총 비용';

  @override
  String get obsKpiErrorRate => '오류율';

  @override
  String get obsKpiCacheRate => '캐시율';

  @override
  String get obsKpiTokensPerSec => '토큰/초';

  @override
  String get obsKpiAvgLatency => '평균 지연 시간';

  @override
  String get obsKpiTtft => '첫 토큰까지 시간';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '이전 기간 대비 $delta';
  }

  @override
  String get obsChartActivity => '활동';

  @override
  String get obsChartCost => '비용 추이';

  @override
  String get obsLegendRuns => '실행';

  @override
  String get obsLegendErrors => '오류';

  @override
  String get obsAgentsTitle => '에이전트';

  @override
  String obsShowAllAgents(int count) {
    return '에이전트 $count개 모두 보기';
  }

  @override
  String get obsShowFewerAgents => '간략히 보기';

  @override
  String get obsRunsTitle => '실행';

  @override
  String get obsNoRunsInRange => '이 범위에 실행이 없습니다';

  @override
  String get obsColTime => '시간';

  @override
  String get obsColAgent => '에이전트';

  @override
  String get obsColStatus => '상태';

  @override
  String get obsColModel => '모델';

  @override
  String get obsColDuration => '소요 시간';

  @override
  String get obsColTokens => '토큰';

  @override
  String get obsColCost => '비용';

  @override
  String get obsColErrors => '오류';

  @override
  String get obsColRuns => '실행';

  @override
  String get obsColAvgLatency => '평균 지연 시간';

  @override
  String get obsColLastActive => '최근 활동';

  @override
  String get obsStatusPending => '대기 중';

  @override
  String get obsStatusRunning => '실행 중';

  @override
  String get obsStatusCompleted => '완료';

  @override
  String get obsStatusError => '오류';

  @override
  String get obsRosterLoadError => '에이전트 목록을 불러오지 못했습니다.';

  @override
  String get obsRosterEmpty => '아직 에이전트가 없습니다';

  @override
  String get obsRosterEmptyDescription =>
      '에이전트를 보내면 상태, 현재 도구, 토큰, 비용이 여기에 실시간으로 표시됩니다.';

  @override
  String get obsKillAgent => '에이전트 종료';

  @override
  String get obsRosterTokensLabel => '토큰';

  @override
  String get obsCostByRoleTitle => '역할별 비용';

  @override
  String get obsCostByRoleSubtitle => '이 워크스페이스의 에이전트 역할별 지출';

  @override
  String get obsRoleMain => '메인';

  @override
  String get obsRoleSubagents => '서브에이전트';

  @override
  String get obsRoleAdvisor => '어드바이저';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return '메인: $main · 서브에이전트: $sub · 어드바이저: $advisor';
  }

  @override
  String get obsTotal => '합계';

  @override
  String get obsTokenModelTitle => '토큰 모델(5축)';

  @override
  String get obsTokenModelSubtitle => '이 워크스페이스에서 사용한 모든 토큰을 축별로 표시합니다';

  @override
  String get obsAxisInput => '입력';

  @override
  String get obsAxisOutput => '출력';

  @override
  String get obsAxisReasoning => '추론';

  @override
  String get obsAxisCacheRead => '캐시 읽기';

  @override
  String get obsAxisCacheWrite => '캐시 쓰기';

  @override
  String get obsTotalTokens => '총 토큰';

  @override
  String get obsCacheDiscountNote =>
      '캐시 읽기 토큰은 할인 요금이 적용되어, 같은 양의 신규 입력보다 비용이 훨씬 적습니다.';

  @override
  String get obsByModelTitle => '모델별';

  @override
  String get obsByModelSubtitle => '모델별 토큰 및 비용 사용량';

  @override
  String get obsNoModelUsage => '아직 기록된 모델 사용량이 없습니다.';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '실행 $count회',
      one: '실행 1회',
    );
    return '$_temp0';
  }

  @override
  String get obsPerRunTitle => '실행당';

  @override
  String get obsPerRunSubtitle => '실행 1회의 일반적인 토큰 비용';

  @override
  String get obsMedianRunTokens => '실행 토큰 중앙값';

  @override
  String get obsMedianRunTokensSub => '전체 실행의 중간값';

  @override
  String get obsRunsInWorkspace => '이 워크스페이스';

  @override
  String get obsCostShare => '비용 비중';

  @override
  String get obsQuotaConfiguredLimits => '설정된 한도';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      '직접 설정한 한도 대비 사용량입니다. 상태가 가장 나쁜 항목부터 표시됩니다.';

  @override
  String get obsQuotaAddLimit => '한도 추가';

  @override
  String get obsQuotaNoLimits =>
      '아직 할당량 한도가 없습니다. 한도를 추가하면 한도 대비 사용량을 추적할 수 있습니다.';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return '$title 한도 삭제';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return '$duration 후 재설정 · $status';
  }

  @override
  String get obsQuotaUsageWindows => '사용량 구간';

  @override
  String get obsQuotaUsageWindowsSubtitle =>
      '모든 프로바이더의 관측 사용량입니다. 한도는 적용되지 않습니다.';

  @override
  String get obsQuotaNoUsage => '아직 기록된 사용량이 없습니다.';

  @override
  String get obsQuotaTokensUsed => '사용한 토큰';

  @override
  String get obsQuotaRequests => '요청';

  @override
  String get obsQuotaUnitTokens => '토큰';

  @override
  String get obsQuotaUnitRequests => '요청';

  @override
  String get obsQuotaUnitCost => '비용';

  @override
  String get obsQuotaAddLimitTitle => '할당량 한도 추가';

  @override
  String get obsQuotaProviderLabel => '프로바이더';

  @override
  String get obsQuotaWindowLabel => '구간';

  @override
  String get obsQuotaUnitLabel => '단위';

  @override
  String obsQuotaLimitLabel(String unit) {
    return '한도 ($unit)';
  }

  @override
  String get obsQuotaCentsHint => '미국 센트 단위입니다(500 = \$5.00).';

  @override
  String get obsQuotaStatusOk => '정상';

  @override
  String get obsQuotaStatusWarning => '경고';

  @override
  String get obsQuotaStatusExhausted => '소진됨';

  @override
  String get obsQuotaStatusUnknown => '알 수 없음';

  @override
  String get obsGoalNoActiveTitle => '활성 목표가 없습니다';

  @override
  String get obsGoalNoActiveBody =>
      '목표를 설정하면 에이전트에 목적과 선택적 토큰 예산을 부여합니다. 실행이 완료될수록 예산이 채워지고, 거의 소진되면 에이전트에게 마무리를 유도합니다.';

  @override
  String get obsGoalSetGoal => '목표 설정';

  @override
  String get obsGoalTokenBudget => '토큰 예산';

  @override
  String obsGoalTokensLeft(String tokens) {
    return '$tokens 남음';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens (예산 미설정)';
  }

  @override
  String get obsGoalTokensUsed => '사용한 토큰';

  @override
  String get obsGoalElapsed => '경과 시간';

  @override
  String get obsGoalWrapUp => '마무리';

  @override
  String get obsGoalClear => '목표 지우기';

  @override
  String get obsGoalFallbackTitle => '목표';

  @override
  String get obsGoalSubtitle => '목표 모드 예산';

  @override
  String get obsGoalStatusActive => '활성';

  @override
  String get obsGoalStatusPaused => '일시 중지';

  @override
  String get obsGoalStatusBudgetLimited => '예산 제한';

  @override
  String get obsGoalStatusComplete => '완료';

  @override
  String get obsGoalStatusDropped => '중단됨';

  @override
  String get obsGoalObjectiveLabel => '목적';

  @override
  String get obsGoalBudgetLabel => '토큰 예산 (선택)';

  @override
  String get obsGoalSetAction => '목표 설정';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => '성공 %';

  @override
  String get obsBenchmarkPassed => '통과';

  @override
  String get obsBenchmarkFailed => '실패';

  @override
  String get obsBenchmarkErrors => '오류';

  @override
  String get obsBenchmarkSpend => '지출';

  @override
  String get obsBenchmarkCostPerTask => '작업당 비용';

  @override
  String get obsBenchmarkTrials => '시도';

  @override
  String get obsBenchmarkNoTrials => '아직 채점할 실행이 없습니다.';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '외 $count건',
      one: '외 1건',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => '통과';

  @override
  String get obsBenchmarkTrialFail => '실패';

  @override
  String get obsBenchmarkTrialError => '오류';

  @override
  String get obsBenchmarkTrialRunning => '실행 중';

  @override
  String get obsBenchmarkReward => '보상';

  @override
  String get obsBenchmarkReport => '리포트';

  @override
  String get obsBenchmarkCopyMarkdown => '마크다운 복사';

  @override
  String get obsBenchmarkCopied => '리포트를 클립보드에 복사했습니다';

  @override
  String get obsBehaviorCaption =>
      '내 메시지에서 파싱한 좌절 신호입니다. 에이전트 점수가 아니라 대화 상태를 보는 지표입니다. 이 기기에서 로컬로 계산되며 외부로 전송되지 않습니다.';

  @override
  String get obsBehaviorMessagesAnalyzed => '분석한 메시지';

  @override
  String get obsBehaviorTotalSignals => '전체 신호';

  @override
  String get obsBehaviorYelling => '고함';

  @override
  String get obsBehaviorProfanity => '욕설';

  @override
  String get obsBehaviorAnguish => '괴로움';

  @override
  String get obsBehaviorNegation => '부정';

  @override
  String get obsBehaviorRepetition => '반복';

  @override
  String get obsBehaviorBlame => '비난';

  @override
  String get obsBehaviorConversationsTitle => '좌절 신호가 가장 많은 대화';

  @override
  String get obsBehaviorConversationsSubtitle => '메시지 대비 신호 밀도로 정렬했습니다.';

  @override
  String get obsBehaviorNoSignals => '좌절 신호가 없습니다. 순조롭게 진행 중입니다.';

  @override
  String obsBehaviorMessagesCount(String count) {
    return '메시지 $count개 분석';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '신호 $count개';
  }

  @override
  String get obsAgentStatusIdle => '유휴';

  @override
  String get obsAgentStatusParked => '주차됨';

  @override
  String get obsAgentStatusAborted => '중단됨';

  @override
  String get obsAgentKindSub => '서브';

  @override
  String get noChecksOnCommit => '이 커밋에서 실행된 검사가 없습니다.';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '실행 중 — 작업 $count개',
      one: '실행 중 — 작업 1개',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '모든 검사 통과 — 작업 $count개',
      one: '모든 검사 통과 — 작업 1개',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '완료 — 작업 $count개',
      one: '완료 — 작업 1개',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '작업 $total개',
      one: '작업 1개',
    );
    return '$_temp0 중 $failed개 실패';
  }

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '작업 $count개',
      one: '작업 1개',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return '매트릭스: $jobId';
  }

  @override
  String get jobLogsPending => '작업이 끝나면 여기에 로그가 표시됩니다.';

  @override
  String get jobLogsUnavailable => '이 작업의 로그를 사용할 수 없습니다.';

  @override
  String get noLogsForStep => '이 단계의 로그가 없습니다.';

  @override
  String get jobLogsTruncated => '로그가 잘렸습니다. 가장 최근 출력을 표시합니다.';

  @override
  String get fullLog => '전체 로그';

  @override
  String get copyLogs => '로그 복사';

  @override
  String get resizeGraph => '드래그하여 그래프 크기 조절';

  @override
  String workflowRunStartedAgo(String time) {
    return '$time에 시작됨';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return '$time에 완료됨';
  }

  @override
  String get chatBridgesTitle => '채팅 브리지';

  @override
  String chatProviderDescription(String provider, String command) {
    return '$provider에서 봇을 멘션해 에이전트에게 작업을 맡기거나, $command로 티켓을 만드세요.';
  }

  @override
  String chatConnectProvider(String provider) {
    return '$provider 연결';
  }

  @override
  String get chatDisconnectProvider => '연결 해제';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$teamName의 $botName';
  }

  @override
  String get chatStateLive => '실시간';

  @override
  String get chatStateConnecting => '연결 중…';

  @override
  String get chatStateError => '연결 오류';

  @override
  String get chatNotConnected => '연결되지 않음';

  @override
  String chatStreamingUnavailable(String provider) {
    return '이 $provider 앱은 실시간 스트리밍이 꺼져 있어 답변이 한 메시지로 도착합니다.';
  }

  @override
  String chatAdminOnly(String provider) {
    return '이 워크스페이스의 $provider 연결은 관리자만 할 수 있습니다.';
  }

  @override
  String chatConnectHint(String provider) {
    return '$provider 앱을 만든 뒤 자격 증명을 여기에 붙여넣으세요. Control Center가 $provider로 연결하므로 이 서버에 공인 주소가 필요하지 않습니다.';
  }

  @override
  String chatOpenConsole(String provider) {
    return '$provider 콘솔 열기';
  }

  @override
  String get chatOpenSetupGuide => '설정 가이드';

  @override
  String get chatFieldBotToken => '봇 토큰';

  @override
  String get chatFieldAppToken => '앱 수준 토큰';

  @override
  String get chatFieldConfigRefreshToken => '앱 구성 토큰';

  @override
  String chatFieldOptional(String label) {
    return '$label (선택)';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return '내 $provider 계정 연결';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return '$provider 계정을 연결하면 거기서 보낸 메시지가 내 이름으로 표시됩니다.';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return '$externalUserId에 연결됨';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return '$provider 계정 연결';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return '$provider에서 봇에게 이 명령을 보내세요. 한 번만 사용할 수 있으며 15분 후 만료됩니다.';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return '$provider 계정이 연결되었습니다. 해당 채널에서 보내는 메시지는 본인 이름으로 표시됩니다.';
  }

  @override
  String get chatLinkedAccounts => '연결된 계정';

  @override
  String chatNoLinkedAccounts(String provider) {
    return '아직 $provider 계정을 연결한 사람이 없습니다.';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '연결된 계정 $count개',
      one: '연결된 계정 1개',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '$externalUserId · 이메일로 매칭됨';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '$externalUserId · 코드로 연결됨';
  }

  @override
  String get chatUnlink => '연결 해제';

  @override
  String get chatCustomizeBot => '봇 맞춤 설정';

  @override
  String get chatCustomizeBotDescription => '봇 이름, 자기소개, 슬래시 명령 이름을 바꿀 수 있습니다.';

  @override
  String get chatCustomizeBotUnavailable =>
      '봇을 수정하려면 Control Center에 앱 구성 토큰이 필요합니다. 다시 연결하고 토큰을 포함하세요.';

  @override
  String chatCreateAppTitle(String provider) {
    return '$provider 앱 만들기';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'Control Center가 필요한 권한과 이벤트가 이미 설정된 $provider 앱을 만들어 드립니다. $provider에서 마친 뒤 자격 증명을 여기에 붙여넣으세요.';
  }

  @override
  String get chatCreateApp => '앱 만들기';

  @override
  String get chatCreateAppCta => '대신 앱 만들기';

  @override
  String get chatAppNameLabel => '앱 이름';

  @override
  String get chatBotDisplayNameLabel => '봇 이름 (@ 뒤에 입력하는 이름)';

  @override
  String get chatDescriptionLabel => '짧은 설명';

  @override
  String get chatAgentDescriptionLabel => '봇이 할 수 있다고 말하는 내용';

  @override
  String get chatCommandLabel => '슬래시 명령';

  @override
  String get chatDirectMessages => '다이렉트 메시지';

  @override
  String chatDirectMessagesHint(String provider) {
    return '멤버가 DM에서 봇과 대화할 수 있습니다. 유료 $provider 요금제가 필요할 수 있습니다.';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return '$provider가 앱 $appId을(를) 만들었습니다.';
  }

  @override
  String chatRemainingSteps(String provider) {
    return '남은 몇 단계는 $provider에서만 할 수 있습니다:';
  }

  @override
  String get chatStepAppToken => '앱 수준 토큰 생성';

  @override
  String get chatStepInstall => '앱 설치';

  @override
  String get chatOpenAppSettings => '앱 설정 열기';

  @override
  String get chatContinueToCredentials => '자격 증명 붙여넣기';

  @override
  String chatBotUpdated(String provider) {
    return '$provider에서 봇이 업데이트되었습니다.';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return '$provider에서 앱 권한이 변경되었습니다. 적용하려면 앱을 다시 설치하세요.';
  }

  @override
  String get chatReinstallApp => '앱 다시 설치';

  @override
  String chatIconNotEditable(String provider) {
    return '봇 아이콘은 $provider의 앱 설정에서만 바꿀 수 있습니다.';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return '$provider에서 직접 만들 수도 있으며 토큰은 필요 없습니다. 위 설정은 링크에 함께 포함됩니다.';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return '$provider에서 만들기';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return '이 구성이 미리 채워진 상태로 $provider가 브라우저에서 열렸습니다. 거기서 앱을 만든 뒤 이 단계를 마치고 토큰을 가져와 주세요.';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return '$provider는 만든 앱을 알려주지 않으므로, 여기서 봇을 맞춤 설정하려면 나중에 앱 구성 토큰이 필요합니다.';
  }

  @override
  String get chatStepCreateApp => '미리 채워진 구성으로 앱 만들기';

  @override
  String chatStepCreateAppHint(String provider) {
    return '$provider에서 워크스페이스를 선택한 뒤 확인하세요.';
  }

  @override
  String get chatStepAppTokenHint =>
      'Basic information → app-level tokens, connections:write 스코프 포함.';

  @override
  String get chatStepInstallHint => 'Install app → bot user OAuth 토큰을 복사하세요.';

  @override
  String get calendarUseBuiltinApp => 'Control Center의 Google 앱 사용';

  @override
  String get calendarUseBuiltinAppHint =>
      'Google 계정으로 승인하세요. Google Cloud에서 설정할 것은 없습니다.';

  @override
  String get calendarUseOwnClient => '내 Google Cloud 클라이언트 사용';

  @override
  String get calendarUseOwnClientHint =>
      '내 Google Cloud 프로젝트의 OAuth 클라이언트를 입력하세요.';

  @override
  String get aboutTitle => '정보';

  @override
  String get aboutAppVersion => '앱 버전';

  @override
  String get aboutServerVersion => '연결된 서버';

  @override
  String get aboutRpcCatalog => 'RPC 카탈로그';

  @override
  String get aboutServerUnknown => '보고되지 않음';

  @override
  String get serverStaleTitle => '번들 서버가 이 앱보다 오래되었습니다';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return '실행 중인 cc_server는 $serverVersion이고 이 앱은 $appVersion입니다. 최신 번들 서버 빌드를 쓰려면 앱을 다시 시작하세요. 개발 중이라면 apps/cc_server에서 `dart build cli`로 다시 빌드하세요.';
  }

  @override
  String get updateCheckButton => '업데이트 확인';

  @override
  String get updateChecking => '업데이트를 확인하는 중…';

  @override
  String get updateUpToDate => '최신 버전입니다';

  @override
  String get updateDeferredBusy => '업데이트가 준비되었지만 회의가 녹화 중입니다. 녹화가 끝나면 안내합니다.';

  @override
  String get updateOpenedReleasesPage => '브라우저에서 릴리스 페이지를 열었습니다.';

  @override
  String get updateCheckFailed => '업데이트 확인에 실패했습니다';

  @override
  String updateAvailableVersion(String version) {
    return '$version 버전을 사용할 수 있습니다.';
  }

  @override
  String get updateBannerTitle => '새 Control Center를 사용할 수 있습니다';

  @override
  String get updateBannerRefresh => '새로고침';

  @override
  String get updateBlockedRecording =>
      '회의가 녹화 중이라 새로고침이 일시 중지되었습니다. 녹화가 끝나면 다시 로드됩니다.';

  @override
  String get settingsScopeYou => '나';

  @override
  String get settingsScopeWorkspace => '워크스페이스';

  @override
  String get settingsScopeServer => '서버';

  @override
  String get settingsProfile => '프로필 및 신원';

  @override
  String get settingsYourDevices => '내 기기';

  @override
  String get settingsWorkspaceGeneral => '일반';

  @override
  String get settingsServerConnection => '연결 및 상태';

  @override
  String get settingsModelProviders => '모델 제공업체';

  @override
  String get settingsVoiceModels => '음성 및 미팅 모델';

  @override
  String get settingsDiagnostics => '진단 및 개인정보 보호';

  @override
  String get settingsAbout => '정보';

  @override
  String get settingsScopeBadgeYou => '나';

  @override
  String get settingsScopeBadgeDevice => '이 기기';

  @override
  String get settingsScopeBadgeWorkspace => '워크스페이스';

  @override
  String get settingsScopeBadgeServer => '서버';

  @override
  String get settingsProfileDescription =>
      '이름, 이메일, 그리고 대신 만든 커밋에 찍히는 git 신원입니다.';

  @override
  String get settingsServerConnectionDescription =>
      '이 클라이언트가 연결하는 서버와, 이 서버가 공유되는 방식(mDNS, 터널, 릴레이)입니다.';

  @override
  String get settingsAboutDescription => '빌드 신원과 업데이트입니다.';

  @override
  String get settingsDiagnosticsDescription =>
      '이 설치의 격리, 인덱싱, 동기화, 로깅, 크래시 리포팅입니다.';

  @override
  String get settingsWorkspaceGeneralDescription =>
      '이 워크스페이스의 모든 구성원이 공유하는 신원, 정책, 규칙입니다.';

  @override
  String get settingsWorkspacePolicyLabel => '워크스페이스 정책';

  @override
  String get settingsWorkspacePolicyDescription =>
      '이 워크스페이스의 모든 구성원과 모든 에이전트에 적용됩니다.';

  @override
  String get settingsSecretGlobsLabel => '시크릿 경로 제외';

  @override
  String get settingsSecretGlobsHelp =>
      '한 줄에 glob 하나. 기본 제외 항목에 더해, 코드가 표시되는 화면에서 뷰어와 게스트에게 이 경로가 숨겨집니다.';

  @override
  String get settingsReviewConcurrencyLabel => '리뷰 팬아웃';

  @override
  String get settingsReviewConcurrencyHelp =>
      '개수를 지정하지 않았을 때 병렬로 보내는 리뷰어 수입니다.';

  @override
  String get settingsReviewLevelLabel => '리뷰 수준';

  @override
  String get settingsReviewLevelHelp =>
      'AI 리뷰의 깊이와, 발견한 내용을 처음에 얼마나 보고할지 정합니다. 아무것도 버리지 않습니다. 가벼운 수준은 사소한 항목을 빼지 않고 묶어 보여줍니다.';

  @override
  String get reviewLevelLight => '가벼움';

  @override
  String get reviewLevelBalanced => '균형';

  @override
  String get reviewLevelThorough => '철저함';

  @override
  String get reviewLevelLightHint => '리뷰어 1명. 실질적으로 중요한 내용만 먼저 보고합니다.';

  @override
  String get reviewLevelBalancedHint => 'QA, 아키텍처, 구현을 담당하는 리뷰어 3명입니다.';

  @override
  String get reviewLevelThoroughHint => '보안과 성능 전문가를 더하고, 발견한 내용을 모두 보고합니다.';

  @override
  String get askAiReviewAtLevel => '다른 수준으로 리뷰';

  @override
  String reviewNitpicksGroup(int count) {
    return '사소한 지적 ($count)';
  }

  @override
  String get reviewFindingResolve => '수정됨';

  @override
  String get reviewFindingResolveHint => '이 항목을 수정됨으로 표시합니다. 리뷰 집계에서 빠집니다.';

  @override
  String get reviewFindingDismiss => '무시';

  @override
  String get reviewFindingDismissHint =>
      '실제 문제가 아닙니다. 이후 PR에서 리뷰어가 이 패턴을 표시하지 않습니다.';

  @override
  String get reviewFindingReopen => '다시 열기';

  @override
  String get reviewFindingStatusUndoLabel => '항목 상태';

  @override
  String get reviewFindingDismissTitle => '이 항목 무시하기';

  @override
  String get reviewFindingDismissReasonHint => '해당되지 않는 이유를 적어 주세요. 리뷰어가 읽습니다.';

  @override
  String reviewFindingStatusFailed(String error) {
    return '항목을 업데이트하지 못했습니다: $error';
  }

  @override
  String get reviewStaleTitle => '이 리뷰는 오래되었습니다';

  @override
  String get reviewStaleBody =>
      '이 리뷰가 실행된 이후 풀 리퀘스트가 변경되었습니다. 더 이상 없는 코드를 가리키는 항목이 있을 수 있습니다.';

  @override
  String reviewStaleReviewedAt(String sha) {
    return '$sha에서 리뷰됨';
  }

  @override
  String get reviewStaleRerun => '다시 리뷰';

  @override
  String reviewStaleNotificationTitle(int prNumber) {
    return '#$prNumber 리뷰가 오래됨';
  }

  @override
  String reviewStaleNotificationBody(String title) {
    return '마지막 리뷰 이후 $title에 새 커밋이 있습니다.';
  }

  @override
  String get reviewCategorySecurity => '보안';

  @override
  String get reviewCategoryStability => '안정성';

  @override
  String get reviewCategoryDataIntegrity => '데이터 무결성';

  @override
  String get reviewCategoryCorrectness => '정확성';

  @override
  String get reviewCategoryPerformance => '성능';

  @override
  String get reviewCategoryMaintainability => '유지보수성';

  @override
  String get reviewEffortQuickWin => '손쉬운 개선';

  @override
  String get reviewEffortModerate => '보통';

  @override
  String get reviewEffortHeavyLift => '큰 작업';

  @override
  String get reviewProposedFix => '제안된 수정';

  @override
  String get reviewAiAgentPrompt => 'AI 에이전트용 프롬프트';

  @override
  String get reviewCopyAiPrompt => '프롬프트 복사';

  @override
  String get settingsWorkspaceAdminOnly => '워크스페이스 관리자만 변경할 수 있습니다.';

  @override
  String get chatMyAccountsTitle => '연결된 채팅 계정';

  @override
  String get settingsServerSso => '싱글 사인온';

  @override
  String get settingsServerSsoDescription =>
      'SAML 및 OpenID Connect 로그인과 사용자 프로비저닝';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabledDescription => '사용자가 이 제공자로 로그인할 수 있습니다';

  @override
  String get ssoEnabledDescriptionOn => '이 제공자로 로그인이 활성화되어 있습니다';

  @override
  String get ssoIdpMetadataLabel => 'IdP 메타데이터 XML';

  @override
  String get ssoIdpMetadataHint => 'IdP의 EntityDescriptor XML을 붙여넣으세요';

  @override
  String get ssoEmailAttributeLabel => '이메일 특성';

  @override
  String get ssoDisplayNameAttributeLabel => '표시 이름 특성';

  @override
  String get ssoGroupsAttributeLabel => '그룹 특성';

  @override
  String get ssoIssuerLabel => 'Issuer URL';

  @override
  String get ssoClientIdLabel => 'Client ID';

  @override
  String get ssoGroupsClaimLabel => '그룹 클레임';

  @override
  String get ssoAutoMemberLabel => '첫 로그인 시 모든 워크스페이스에 사용자 추가';

  @override
  String get ssoAutoMemberDescription => '끄면 워크스페이스마다 초대가 필요합니다';

  @override
  String get ssoAllowJitLabel => '첫 로그인 시 알 수 없는 사용자 프로비저닝';

  @override
  String get ssoAllowJitDescription => '끄면 기존 계정이 없는 사용자를 거부합니다';

  @override
  String get ssoAllowIdpInitiatedLabel => '요청하지 않은(IdP 시작) 로그인 허용';

  @override
  String get ssoAllowIdpInitiatedDescription => '앱을 바로 실행하는 IdP 포털 전용입니다';

  @override
  String get ssoWantResponseSignedLabel => '서명된 응답 엔벨로프 필수';

  @override
  String get ssoWantResponseSignedDescription => 'Assertion 서명은 항상 필요합니다';

  @override
  String get ssoTestConnectionButton => '연결 테스트';

  @override
  String get ssoTestConnectionOk => '연결됨:';

  @override
  String get ssoCopySpMetadata => 'SP 메타데이터 복사';

  @override
  String get ssoCopySpMetadataDone => 'SP 메타데이터를 클립보드에 복사했습니다';

  @override
  String get ssoSavedToast => '싱글 사인온 설정을 저장했습니다';

  @override
  String get ssoUnavailable =>
      '이 서버는 싱글 사인온 설정을 제공하지 않습니다. 서버 바이너리를 업데이트한 뒤 다시 시도하세요.';

  @override
  String get ssoScimCardTitle => '사용자 프로비저닝(SCIM)';

  @override
  String get ssoScimDescription =>
      'IdP의 SCIM 커넥터를 아래 엔드포인트에 bearer 토큰과 함께 지정하세요. 디프로비저닝하면 몇 초 안에 세션과 워크스페이스 접근이 취소됩니다. 서버는 터널 또는 공개 URL로 IdP에서 접근할 수 있어야 합니다.';

  @override
  String get ssoScimEndpoint => 'SCIM 엔드포인트';

  @override
  String get ssoScimEndpointUnknownOrigin => '먼저 서버의 공개 URL을 설정하거나 터널을 켜세요';

  @override
  String get ssoScimRegenerate => '토큰 재생성';

  @override
  String get ssoScimRegenerateConfirm =>
      '새 SCIM bearer 토큰을 생성할까요? 이전 토큰은 즉시 사용할 수 없게 됩니다.';

  @override
  String get ssoScimTokenTitle => 'Bearer 토큰';

  @override
  String get ssoScimTokenPresent => '토큰이 구성되어 있습니다';

  @override
  String get ssoScimTokenAbsent => '아직 토큰이 없습니다 — SCIM을 쓰려면 생성하세요';

  @override
  String get ssoScimTokenOnce => 'SCIM 토큰(한 번만 표시)';

  @override
  String ssoSignInWith(String provider) {
    return '$provider(으)로 로그인';
  }

  @override
  String get ssoProbeFailed => '싱글 사인온을 위해 해당 서버에 연결할 수 없습니다';

  @override
  String get ssoOpensBrowser => '브라우저를 열어 로그인을 완료합니다';

  @override
  String get ssoWaitingForBrowser => '브라우저에서 로그인을 마칠 때까지 기다리는 중…';

  @override
  String get ssoBrowserOpenFailed => '싱글 사인온을 위해 브라우저를 열 수 없습니다';

  @override
  String get ssoUseManualPairing => '대신 초대 또는 페어링 키로 로그인';

  @override
  String get ssoHideManualPairing => '수동 페어링 숨기기';

  @override
  String get ssoClientIdHint => '공개(PKCE) 클라이언트 — 시크릿이 필요하지 않습니다';

  @override
  String get ssoClientSecretLabel => 'Client secret(선택)';

  @override
  String get ssoClientSecretHintUnset => '기밀 IdP 클라이언트에만 필요합니다';

  @override
  String get ssoClientSecretHintSet => '시크릿이 저장되어 있습니다 — 유지하려면 비워 두세요';

  @override
  String get ssoPairingToggle => '수동 페어링 허용(초대 코드 및 페어링 키)';

  @override
  String get ssoPairingToggleDescription =>
      '끄면 가입은 싱글 사인온만 가능합니다. 새 기기는 SSO 로그인으로 들어오고, 기존 기기는 계속 사용할 수 있습니다';

  @override
  String get ssoPairConfirmTitle => '서버에 연결할까요?';

  @override
  String ssoPairConfirmBody(String server) {
    return '$server의 로그인 자격 증명이 도착했지만, 이 앱에서 로그인을 시작하지 않았습니다. 이 서버에 연결할까요?';
  }

  @override
  String get ssoPairConfirmConnect => '연결';

  @override
  String get ssoPairConfirmCancel => '무시';

  @override
  String get forgeConnections => '코드 호스팅';

  @override
  String get connect => '연결';

  @override
  String get disconnect => '연결 해제';

  @override
  String get notConnected => '연결되지 않음';

  @override
  String get checkingConnection => '연결 확인 중…';

  @override
  String get fromEnvironment => '환경에서';

  @override
  String forgeTokenTitle(String forge) {
    return '$forge 토큰';
  }

  @override
  String get settingsAudio => '오디오';

  @override
  String get settingsAudioDescription => '마이크, 받아쓰기, 회의 감지 및 사운드스케이프 출력.';

  @override
  String get audioDevicesSection => '오디오 장치';

  @override
  String get voiceInputBehaviorSection => '받아쓰기 및 회의';

  @override
  String get audioOutputDeviceTitle => '출력 장치';

  @override
  String get audioOutputDefaultHint => '앱의 모든 소리는 시스템 기본 출력으로 재생됩니다.';

  @override
  String get audioOutputGone =>
      '선택한 출력 장치가 더 이상 연결되어 있지 않습니다. 다른 장치를 고를 때까지 시스템 기본값이 사용됩니다.';

  @override
  String get reviewHubIntroBody =>
      '에이전트가 diff를 분석하고 변경 영역을 파악한 뒤 합의된 판정을 내립니다.';

  @override
  String get reviewHubAlreadyRunning => '이 풀 리퀘스트에 대한 리뷰가 이미 진행 중입니다';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return '마지막 리뷰 이후: $resolved 해결됨 · $added 새로 추가됨 · $open 아직 미해결';
  }

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return '이전 리뷰 시점: $sha';
  }

  @override
  String reviewArtifactFixAll(int count) {
    return '발견 항목 $count개 수정';
  }

  @override
  String reviewArtifactFixSelected(int count) {
    return '선택한 $count개 수정';
  }

  @override
  String reviewArtifactCommentSelected(int count) {
    return '선택한 $count개에 댓글';
  }

  @override
  String get webConnectTitle => 'Control Center에 연결';

  @override
  String get webConnectSubtitle =>
      '실행 중인 cc-server에 WebSocket으로 연결합니다. 키는 이 장치에 남습니다.';

  @override
  String get webConnectServerLabel => '서버';

  @override
  String get webConnectDeviceIdLabel => '장치 ID';

  @override
  String get webConnectPairingKeyLabel => '페어링 키';

  @override
  String get webConnectPairingKeyHint => 'PSK 붙여넣기';

  @override
  String get webConnectStayConnected => '이 장치에서 연결 유지';

  @override
  String get webConnectStayConnectedDetail => '이 장치에서 연결 유지 (키가 이 브라우저에 저장됩니다)';

  @override
  String failedToCreateWorkspace(String error) {
    return '워크스페이스를 만들지 못했습니다: $error';
  }

  @override
  String committedRelative(String relative) {
    return '$relative에 커밋됨';
  }

  @override
  String get selectAgents => '에이전트 선택';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '에이전트 $count개',
      one: '에이전트 1개',
    );
    return '$_temp0';
  }

  @override
  String get newConversation => '새 대화';

  @override
  String get untitledConversation => '제목 없는 대화';

  @override
  String get conversationTitleOptionalHint =>
      '선택 사항 — 비워 두면 제목 모델이 자동으로 이름을 붙입니다';

  @override
  String get conversationTitlesSectionTitle => '대화 제목';

  @override
  String get conversationTitlesSectionCaption =>
      '이 워크스페이스의 새 대화에 자동으로 제목을 붙일 러너를 선택하세요. 어댑터를 고르기 전까지 제목은 꺼져 있으며, 모든 멤버에게 적용됩니다.';

  @override
  String get conversationTitlesModelLabel => '제목 모델';

  @override
  String get conversationTitlesAdapterLabel => '어댑터';

  @override
  String get conversationTitlesAdapterHint => '꺼짐';

  @override
  String get conversationTitlesAdapterOff => '꺼짐';

  @override
  String get startThread => '스레드 시작';

  @override
  String get deleteSpaceConfirm => '이 스페이스를 삭제할까요? 모든 메시지가 사라집니다.';

  @override
  String threadTabTitle(String title) {
    return '스레드: $title';
  }

  @override
  String threadReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '답글 $count개',
      one: '답글 1개',
    );
    return '$_temp0';
  }

  @override
  String threadLastReply(String time) {
    return '마지막 답글 $time';
  }

  @override
  String signInWithProvider(String provider) {
    return '$provider로 로그인';
  }

  @override
  String get signInAgain => '다시 로그인';

  @override
  String get signInNotFinished => '로그인이 아직 완료되지 않았습니다. 브라우저에서 마친 뒤 다시 확인해 주세요.';

  @override
  String get signedOutTitle => '로그아웃되었습니다';

  @override
  String get signedOutSubtitle =>
      '코드 호스팅 연결이 더 이상 유효하지 않습니다. 토큰이 만료되었거나 액세스가 취소되었습니다. 다른 것은 바뀌지 않았습니다. 다시 로그인하면 그대로입니다.';

  @override
  String get viaServerApp => '이 서버의 앱을 통해';

  @override
  String get ticketing => '티켓팅';

  @override
  String get ticketingProviderHelp =>
      '티켓이 있는 위치입니다. 로컬은 Control Center에 보관합니다.';

  @override
  String providerComingSoon(String provider) {
    return '$provider (곧)';
  }

  @override
  String get ticketProviderLocal => '로컬';

  @override
  String get addKey => '키 추가';

  @override
  String get providerApps => '프로바이더 앱';

  @override
  String get providerAppsDescription =>
      '이 서버가 자체적으로 인증하는 방식과, 사용자가 로그인하는 경로입니다. 웹훅, 폴링, 동기화 같은 백그라운드 작업은 앱에서 실행되며, 개인 토큰으로는 실행되지 않습니다.';

  @override
  String get providerAppId => '앱 ID';

  @override
  String get providerPrivateKey => '비공개 키';

  @override
  String get providerClientId => '클라이언트 ID';

  @override
  String get providerClientSecret => '클라이언트 시크릿';

  @override
  String get providerApiKey => 'API 키';

  @override
  String get providerCallbackUrl => '콜백 URL';

  @override
  String get providerAppFullyConfigured =>
      '서버가 자체 자격 증명으로 동작하며, 사용자가 로그인할 수 있습니다.';

  @override
  String get providerAppServerOnly =>
      '서버가 자체 자격 증명으로 동작합니다. 사용자가 로그인하려면 클라이언트 ID와 시크릿을 추가하세요.';

  @override
  String get providerAppSignInOnly =>
      '사용자가 로그인할 수 있습니다. 백그라운드 작업은 해당 사용자 자격 증명으로 대체됩니다.';

  @override
  String providerAppInstalledOn(String accounts) {
    return '자격 증명이 정상입니다. 설치된 계정: $accounts';
  }

  @override
  String deviceCodeInstructions(String provider) {
    return '방금 열린 $provider 페이지에 이 코드를 입력하세요. 클립보드에 복사되어 있습니다.';
  }

  @override
  String get deviceCodeWaiting => '브라우저에서 완료할 때까지 기다리는 중…';

  @override
  String get copyCodeAndOpen => '코드 복사 후 열기';

  @override
  String get couldNotOpenBrowser => '브라우저를 열 수 없습니다. 링크를 복사해 직접 로그인을 완료하세요.';

  @override
  String get contextUsage => '컨텍스트 사용량';

  @override
  String get contextUsageFull => '가득 참';

  @override
  String get contextUsageTokens => '토큰';

  @override
  String get contextSeeMore => '더 보기';

  @override
  String get contextSegmentSystemPrompt => '시스템 프롬프트';

  @override
  String get contextSegmentRules => '규칙';

  @override
  String get contextSegmentSkills => '스킬';

  @override
  String get contextSegmentToolDefinitions => '도구 정의';

  @override
  String get contextSegmentMcpTools => 'MCP 및 동적 도구';

  @override
  String get contextSegmentDeferredTools => '필요 시 로드되는 도구';

  @override
  String get contextSegmentSubagents => '서브에이전트 정의';

  @override
  String get contextSegmentMemory => '메모리';

  @override
  String get contextSegmentConversation => '대화';

  @override
  String get contextExplorerTitle => '컨텍스트';

  @override
  String get contextExplorerEverything => '전체';

  @override
  String get contextExplorerSelectPart => '내용을 확인하려면 항목을 선택하세요';

  @override
  String get contextExplorerUnavailable => '컨텍스트 분석을 사용할 수 없습니다';

  @override
  String get contextRetry => '다시 시도';

  @override
  String get settingsFieldOptional => '선택 사항';

  @override
  String get settingsFilterHint => '이 목록 필터';

  @override
  String get settingsValueNotAvailable => '아직 사용할 수 없음';

  @override
  String get settingsNoEntriesYet => '아직 항목이 없습니다';

  @override
  String get settingsChangedBadge => '변경됨';

  @override
  String get ssoConnectionCardDescription =>
      '이 서버에 로그인하는 방식을 선택한 뒤 해당 연결을 켜세요.';

  @override
  String get ssoUseSamlForSignIn => 'SAML로 로그인';

  @override
  String get ssoUseOidcForSignIn => 'OpenID Connect로 로그인';

  @override
  String get ssoSaveConnection => '연결 저장';

  @override
  String get ssoStateLive => '라이브';

  @override
  String get ssoStateConfiguredOff => '구성됨, 꺼짐';

  @override
  String get ssoStateOnIncomplete => '켜짐, 미완료';

  @override
  String get ssoStateActive => '활성';

  @override
  String get ssoStateAllowed => '허용됨';

  @override
  String get ssoStateNoToken => '토큰 없음';

  @override
  String get ssoSummaryDirectorySync => '디렉터리 동기화';

  @override
  String get ssoSummaryManualPairing => '수동 페어링';

  @override
  String get ssoNoMethodLiveNote =>
      '사용 중인 로그인 방식이 없습니다. 연결을 구성하고 켜기 전까지 새 기기는 초대 또는 페어링 키로 참여합니다.';

  @override
  String get ssoMethodSamlBlurb =>
      'Okta, Entra ID, Google Workspace처럼 SAML 2.0을 지원하는 ID 공급자용입니다.';

  @override
  String get ssoMethodOidcBlurb =>
      'OpenID Connect를 지원하는 ID 공급자용입니다. 보통 두 방식 중 설정이 더 간단합니다.';

  @override
  String get ssoGroupIdentityProvider => 'ID 공급자';

  @override
  String get ssoGroupIdentityProviderSamlDescription =>
      '어설션의 출처와 이 서버가 이를 검증하는 방식입니다.';

  @override
  String get ssoGroupIdentityProviderOidcDescription =>
      '이 서버가 신뢰하는 발급자와 인증에 사용하는 클라이언트입니다.';

  @override
  String get ssoSpEntityIdShortLabel => 'SP 엔터티 ID';

  @override
  String get ssoSpEntityIdDescription => '비워 두면 서버 URL에서 도출합니다.';

  @override
  String get ssoIssuerDescription => '공급자의 디스커버리 문서를 제공하는 기본 URL입니다.';

  @override
  String get ssoSecretStored => '저장됨';

  @override
  String get ssoGroupHandoff => 'ID 공급자에 필요한 정보';

  @override
  String get ssoGroupHandoffDescription => '제공자에서 만든 애플리케이션에 붙여넣으세요.';

  @override
  String get ssoOriginUnknownTitle => '이 서버의 공개 URL을 알 수 없습니다';

  @override
  String get ssoOriginUnknownBody =>
      '로그인 URL과 콜백 URL이 이를 기준으로 만들어지므로, 설정하기 전까지 제공자가 이 서버에 도달할 수 없습니다. 공개 URL을 추가하거나 서버 → 연결에서 터널을 켜세요.';

  @override
  String get ssoAcsUrlLabel => '어설션 소비자 서비스(ACS) URL';

  @override
  String get ssoAcsUrlDescription => '제공자가 서명된 어설션을 보내는 주소입니다.';

  @override
  String get ssoSpEntityIdResolvedLabel => '서비스 제공자 엔터티 ID';

  @override
  String get ssoMetadataUrlLabel => 'SP 메타데이터 URL';

  @override
  String get ssoMetadataUrlDescription => '메타데이터를 가져오는 제공자는 대신 여기서 가져올 수 있습니다.';

  @override
  String get ssoRedirectUriLabel => '리디렉션 URI';

  @override
  String get ssoRedirectUriDescription => '제공자 애플리케이션의 허용된 리디렉션 URI에 추가하세요.';

  @override
  String get ssoSignInUrlLabel => '로그인 URL';

  @override
  String get ssoSignInUrlDescription => '싱글 사인온 로그인을 시작하려면 사용자를 이곳으로 보내세요.';

  @override
  String get ssoGroupAttributeMapping => '속성 매핑';

  @override
  String get ssoGroupAttributeMappingDescription =>
      '각 필드를 담는 클레임입니다. 제공자가 이름을 바꾸지 않았다면 기본값을 유지하세요.';

  @override
  String get ssoGroupAccess => '액세스 및 역할';

  @override
  String get ssoGroupAccessDescription => '로그인에 성공한 사용자가 할 수 있는 작업입니다.';

  @override
  String get ssoDefaultRoleShortLabel => '기본 역할';

  @override
  String get ssoDefaultRoleDescription => '아래 매핑과 일치하는 그룹이 없는 사용자에게 부여됩니다.';

  @override
  String get ssoRoleMapShortLabel => '그룹-역할 매핑';

  @override
  String get ssoRoleMapDescription =>
      '먼저 일치하는 그룹이 적용됩니다. 소유자는 이 방식으로 부여할 수 없습니다.';

  @override
  String get ssoRoleMapGroupHint => '제공자의 그룹 이름';

  @override
  String get ssoRoleMapAdd => '매핑 추가';

  @override
  String get ssoRoleMapEmpty => '매핑이 없습니다. 모든 사용자에게 기본 역할이 부여됩니다.';

  @override
  String get ssoAdvancedSummary => '시간 오차, IdP 시작 로그인, 서명 정책';

  @override
  String get ssoClockSkewShortLabel => '시간 오차';

  @override
  String get ssoClockSkewDescription =>
      '어설션 타임스탬프에 허용하는 초 단위 오차입니다. 대부분의 제공자는 90이면 충분합니다.';

  @override
  String get ssoScimGenerate => '토큰 생성';

  @override
  String get ssoScimTokenOnceBody =>
      '클립보드에 복사되었습니다. 한 번만 표시되며 복구할 수 없으니 지금 제공자에 붙여넣으세요.';

  @override
  String get ssoPairingCardTitle => '수동 페어링';

  @override
  String get ssoPairingCardDescription =>
      '이 서버에 들어가는 다른 방법입니다. 싱글 사인온을 거치지 않는 장치를 위한 초대 코드와 페어링 키입니다.';

  @override
  String settingsCountOfTotal(int count, int total) {
    return '$total개 중 $count개';
  }

  @override
  String get providersNoneConnectedNote =>
      '연결된 제공자가 없어 내장 에이전트 런타임이 실행할 대상이 없습니다. 아래에서 API 키를 추가하거나 로그인하세요.';

  @override
  String get providersFilterHint => '제공자 필터';

  @override
  String get providersFacetNeedsSetup => '설정 필요';

  @override
  String get providersFacetCustom => '사용자 지정';

  @override
  String get providersNoneMatch => '이 필터와 일치하는 항목이 없습니다';

  @override
  String get providerDeniedHereTitle => '이 워크스페이스에서 거부됨';

  @override
  String get providerDeniedHereBody =>
      '연결되어 있어도 여기 에이전트는 이 제공자를 사용할 수 없습니다. 다른 워크스페이스에는 영향이 없습니다.';

  @override
  String get providerNeedsSignIn => '이 제공자를 사용하려면 로그인하세요';

  @override
  String get providerNeedsApiKey => '이 제공자를 사용하려면 API 키를 추가하세요';

  @override
  String get providerApiKeyLabel => 'API 키';

  @override
  String get providerGenerationDefaults => '제공자 기본값';

  @override
  String get providerNoModelsYet => '아직 보고된 모델이 없습니다. 제공자를 연결한 다음 동기화하세요.';

  @override
  String get providerModelsFilterHint => '모델 필터';

  @override
  String get adaptersNoneReadyNote =>
      '카탈로그에 있는 러너 CLI가 이 컴퓨터에서 하나도 발견되지 않았습니다. 설치한 다음 새로고침하세요.';

  @override
  String get adaptersFilterHint => '러너 필터';

  @override
  String get adaptersFacetReady => '준비됨';

  @override
  String get adaptersFacetMissing => '없음';

  @override
  String get adaptersLaunchGroup => '실행';

  @override
  String get adaptersLaunchGroupDescription =>
      '에이전트가 이 러너를 시작할 때 전달되는 값입니다. CLI를 설치하기 전에 설정해 두어도 됩니다.';

  @override
  String get adaptersEnvNone => '설정 없음';

  @override
  String adaptersEnvCount(int count) {
    return '$count개 설정됨';
  }

  @override
  String get adapterArgumentsDescription => '실행할 때마다 러너 명령줄에 추가됩니다.';

  @override
  String get defaultChatDescription => '새 대화와 자체 러너가 없는 에이전트를 실행합니다.';

  @override
  String get shortTaskDescription =>
      '제목과 요약 같은 빠른 백그라운드 작업을 실행합니다. 더 작은 모델을 여기에 두세요.';

  @override
  String get settingsStateFailed => '실패';

  @override
  String get providerAppsGroupServer => '서버로 동작';

  @override
  String get providerAppsGroupServerDescription =>
      '요청 뒤에 사람이 없어도 백그라운드 작업이 저장소에 도달할 수 있습니다. 웹훅, 풀 리퀘스트 폴링, 티켓 동기화.';

  @override
  String get providerAppsGroupPrConversations => '풀 리퀘스트 대화';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      '개발자가 GitHub에서 이 서버와 직접 대화하는 방식입니다. 웹훅이나 공개 URL 없이 동작하며, 서버가 폴링합니다.';

  @override
  String get providerAppBotLogin => '봇 로그인';

  @override
  String get providerAppBotLoginEmpty => '연결을 테스트하면 봇 로그인을 확인할 수 있습니다.';

  @override
  String get providerAppAskOnGitHub => 'GitHub에서 요청';

  @override
  String get providerAppAskOnGitHubHint =>
      '풀 리퀘스트 댓글에 위의 봇 로그인을 멘션하세요. [bot] 접미사는 생략해도 됩니다. 리뷰를 요청하거나 질문하고, 해당 리뷰 스레드에 답글을 달거나, `ai-review` 레이블을 추가해 리뷰를 요청할 수 있습니다.';

  @override
  String get providerAppsGroupSignIn => '사용자 로그인';

  @override
  String get providerAppsGroupSignInDescription =>
      '각 멤버가 자신의 계정을 연결하고 고유한 자격 증명을 받을 수 있습니다.';

  @override
  String get providerAppCapActsAsServer => '서버로 동작';

  @override
  String get providerAppCapSignsIn => '사용자를 로그인시킴';

  @override
  String get portLabel => '포트';

  @override
  String get mcpNoTokenWarning =>
      '토큰이 없으면 이 포트에 접근할 수 있는 누구나 모든 도구를 호출할 수 있습니다.';

  @override
  String get mcpBridgedToolsLabel => '도구';

  @override
  String get guardrailFamilyFiles => '파일';

  @override
  String get guardrailFamilyGit => 'Git과 풀 리퀘스트';

  @override
  String get guardrailFamilyMachine => '머신과 네트워크';

  @override
  String get guardrailFamilyControl => '시크릿과 워크스페이스';

  @override
  String get guardrailScopeFieldLabel => '규칙 편집 대상';

  @override
  String get guardrailScopeFieldDescription =>
      '좁은 범위가 넓은 범위보다 우선합니다. 여기서 설정한 규칙은 상속된 규칙 위에 적용됩니다.';

  @override
  String get guardrailSetHere => '여기서 설정';

  @override
  String get guardrailClearAllHere => '모두 지우기';

  @override
  String get sandboxingCardLabel => '샌드박싱';

  @override
  String get sandboxingCardDescription =>
      '에이전트 작업이 이 호스트와 격리되어 실행되는지, 격리된 에이전트가 여전히 접근할 수 있는 범위입니다.';

  @override
  String get sandboxBackendNoneActive => '호스트, 격리 없음';

  @override
  String get sandboxSummaryHost => '호스트';

  @override
  String get sandboxGroupIsolation => '격리';

  @override
  String get sandboxGroupIsolationDescription =>
      '에이전트의 프로세스와 파일 쓰기가 실제로 일어나는 위치입니다.';

  @override
  String get sandboxBackendFieldDescription =>
      '이 호스트가 지원하는 가장 강력한 방식을 자동으로 선택합니다. 하나를 고정하면 임의로 바뀌지 않습니다.';

  @override
  String get sandboxCapabilitiesDescription =>
      '경계를 통과하도록 연 예외입니다. 각각은 격리된 에이전트가 외부에서 여전히 할 수 있는 작업입니다.';

  @override
  String get sandboxSummaryInForce => '적용 중';

  @override
  String get rigsInstallHintLabel => '설치 방법';

  @override
  String get rigsStarting => '시작 중';

  @override
  String get rigsResidentMemory => '상주 메모리';

  @override
  String get installedLabel => '설치됨';

  @override
  String get notInstalledLabel => '설치되지 않음';

  @override
  String ssoOtherKindUnsaved(String method) {
    return '$method에 저장하지 않은 변경 사항이 있습니다';
  }

  @override
  String get collapseComment => '댓글 접기';

  @override
  String get expandComment => '댓글 펼치기';

  @override
  String get suggestedChange => '제안된 변경';

  @override
  String get emptyComment => '빈 댓글';

  @override
  String repliesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '답글 $count개',
      one: '답글 1개',
    );
    return '$_temp0';
  }

  @override
  String get pendingReview => '대기 중인 리뷰';

  @override
  String failedToResolveConversation(String error) {
    return '대화를 업데이트하지 못했습니다: $error';
  }

  @override
  String get addSingleComment => '댓글만 추가';

  @override
  String get addToReview => '리뷰에 추가';

  @override
  String get startAReview => '리뷰 시작';

  @override
  String get reviewNeedsABody => '먼저 요약을 작성하거나 인라인 댓글을 대기열에 넣으세요';

  @override
  String get reviewSubmitted => '리뷰가 제출되었습니다';

  @override
  String get finishYourReview => '리뷰 완료';

  @override
  String get commentVerdict => '댓글';

  @override
  String pendingCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '대기 중인 댓글 $count개',
      one: '대기 중인 댓글 1개',
    );
    return '$_temp0';
  }

  @override
  String andNMore(int count) {
    return '외 $count개';
  }

  @override
  String get queuedCommentHint => '이 댓글은 리뷰를 제출할 때 함께 전송됩니다.';

  @override
  String commentOnLinesRange(int start, int end) {
    return '$start행부터 $end행까지';
  }

  @override
  String get claudeAccountsTitle => 'Claude Code 계정';

  @override
  String get claudeAccountsDescription =>
      '각 계정은 별도의 Claude Code 로그인입니다. 실행은 아래에 연결된 계정을 이 순서대로 사용합니다.';

  @override
  String get claudeAccountsEmpty => '아직 계정이 없습니다';

  @override
  String get claudeAccountAdd => '계정 추가';

  @override
  String get claudeAccountSignIn => '로그인';

  @override
  String get claudeAccountSignInAgain => '다시 로그인';

  @override
  String get claudeAccountSignInHint =>
      '서버의 터미널에서 실행하세요. 브라우저가 열려 로그인을 완료하고, 자격 증명을 이 계정의 디렉터리에 저장합니다.';

  @override
  String get claudeAccountSignedOut => '로그아웃됨';

  @override
  String get claudeAccountExpired => '로그인이 만료됨';

  @override
  String claudeAccountExpiredDetail(String when) {
    return '$when에 로그인이 만료되었습니다. 이 계정을 사용하려면 다시 로그인해 주세요.';
  }

  @override
  String get claudeAccountMakeDefault => '기본으로 설정';

  @override
  String get claudeAccountDefault => '기본';

  @override
  String claudeAccountRemoveConfirm(String label) {
    return '$label을(를) 제거할까요?';
  }

  @override
  String get claudeAccountRemoveDetail =>
      '해당 계정에서 로그아웃하고 서버의 디렉터리를 삭제합니다. 로그인 자체는 영향을 받지 않습니다.';

  @override
  String claudeAccountStatusUnknown(String error) {
    return '이 계정을 확인하지 못했습니다: $error';
  }

  @override
  String claudeAccountUsedPercent(String percent) {
    return '$percent% 사용됨';
  }

  @override
  String get accountPoolStrategy => '로테이션';

  @override
  String get accountPoolPinned => '고정';

  @override
  String get accountPoolRoundRobin => '라운드 로빈';

  @override
  String get accountPoolSerial => '하나씩';

  @override
  String get accountPoolPinnedHint =>
      '항상 첫 번째 계정부터 시작합니다. 실패하면 나머지 계정을 대체로 사용합니다.';

  @override
  String get accountPoolRoundRobinHint => '실행을 계정에 분산하고, 디스패치마다 다음 계정으로 이동합니다.';

  @override
  String get accountPoolSerialHint => '첫 번째 계정을 모두 사용한 뒤에 다음 계정을 사용합니다.';

  @override
  String get accountPoolMoveUp => '위로 이동';

  @override
  String get accountPoolMoveDown => '아래로 이동';

  @override
  String get accountPoolUsingAll => '아직 연결된 항목이 없습니다. 모든 계정을 이 순서대로 사용합니다.';

  @override
  String get accountPoolInheriting => '워크스페이스의 계정을 상속합니다.';

  @override
  String get accountPoolResetToWorkspace => '워크스페이스 계정으로 되돌리기';

  @override
  String accountPoolCoolingOff(String when) {
    return '$when까지 쿼터 소진';
  }

  @override
  String get accountPoolSignedOut => '로그아웃됨';

  @override
  String get accountPoolExpired => '로그인 만료됨';

  @override
  String accountPoolLoadFailed(String error) {
    return '로테이션을 불러오지 못했습니다: $error';
  }

  @override
  String get providerSignedInAccount => '로그인한 계정';

  @override
  String get agentAccountsTab => '계정';

  @override
  String get agentClaudeAccountsNoticeTitle => '여러 Claude Code 계정';

  @override
  String agentClaudeAccountsNoticeBody(int count) {
    return '이 러너는 이 호스트의 Claude Code 계정 $count개 중 하나로 로그인합니다. 계정 탭에서 사용할 계정을 고르거나 로테이션하세요.';
  }

  @override
  String get agentAccountsDescription =>
      '이 에이전트의 실행에 사용할 계정입니다. 각 블록은 처음에 워크스페이스 선택을 상속합니다.';

  @override
  String get agentAccountsNothingToRotate =>
      '로테이션할 항목이 없습니다. 먼저 두 번째 계정 또는 키를 연결하세요.';

  @override
  String failedToPostReply(String error) {
    return '답글을 게시하지 못했습니다: $error';
  }

  @override
  String commentOnLine(int line) {
    return '$line번 줄';
  }

  @override
  String get viewInDiff => 'diff에서 보기';

  @override
  String get subscriptionUsagePreviousAccount => '이전 계정';

  @override
  String get subscriptionUsageNextAccount => '다음 계정';

  @override
  String inReplyTo(String path) {
    return '$path에 대한 답글';
  }

  @override
  String get subscriptionUsageNoneReported => '이 계정의 사용량이 보고되지 않았습니다.';

  @override
  String get subscriptionUsageCredits => '크레딧';

  @override
  String get reviewHubStaticRule => '정적 규칙';

  @override
  String get reviewHubStarted => '리뷰가 시작됨';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return '리뷰어 에이전트가 아니라, 이 풀 리퀘스트가 추가하는 줄에서 결정론적 규칙($rule)이 찾은 항목입니다.';
  }

  @override
  String get prReviewArtifactTab => 'PR 리뷰';

  @override
  String get prReviewRunning => '이 풀 리퀘스트를 리뷰하는 중…';

  @override
  String get prReviewStarting => '리뷰를 시작하는 중…';

  @override
  String get prReviewStartingBody =>
      '이 풀 리퀘스트의 워크트리를 준비하는 중입니다. 준비가 끝나면 리뷰어가 바로 시작합니다.';

  @override
  String get prReviewFailed => '리뷰에 실패했습니다.';

  @override
  String get prReviewRerunning => '다시 리뷰하는 중…';

  @override
  String get prReviewNoOpenFindings => '열린 발견 사항 없음';

  @override
  String prReviewOpenFindings(int count) {
    return '열린 발견 사항 $count개';
  }

  @override
  String subscriptionUsageSpend(String used, String limit) {
    return '$limit 중 $used';
  }

  @override
  String reviewCommentsPosted(int posted, int skipped, int failed) {
    return '봇으로 댓글 $posted개를 게시했습니다. $skipped개는 건너뛰었고(파일 앵커 없음), $failed개는 실패했습니다.';
  }

  @override
  String reviewFindingsOutOfDiff(int count, String files) {
    return '발견 사항 $count개가 이 풀 리퀘스트에서 변경하지 않은 코드를 가리킵니다($files). GitHub는 diff의 인라인 댓글만 허용합니다.';
  }

  @override
  String get reviewRailReport => '보고서';

  @override
  String get reviewNoFindingsTitle => '아직 리뷰 발견 사항이 없습니다';

  @override
  String get reviewNoFindingsHint => '에이전트가 게시하면 발견 사항이 여기에 표시됩니다.';

  @override
  String reviewShowDismissed(int count) {
    return '기각된 항목 $count개 표시';
  }

  @override
  String reviewHideDismissed(int count) {
    return '기각된 항목 $count개 숨기기';
  }

  @override
  String reviewDisagreementsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '리뷰어 불일치 $count건이 감지됨',
      one: '리뷰어 불일치 1건이 감지됨',
    );
    return '$_temp0';
  }

  @override
  String get reviewFilterKind => '종류';

  @override
  String get reviewFilterStatus => '상태';

  @override
  String get reviewKindBug => '버그';

  @override
  String get reviewKindSuggestion => '제안';

  @override
  String get reviewKindRecommendation => '권장';

  @override
  String get reviewKindQuestion => '질문';

  @override
  String get reviewKindTicket => '티켓';

  @override
  String get archiveSpace => '스페이스 보관';

  @override
  String get archivedSpaces => '보관된 스페이스';

  @override
  String get archivedSpacesEmpty => '보관된 스페이스가 없습니다';

  @override
  String get restoreSpace => '복원';

  @override
  String archivedWhen(String time) {
    return '$time에 보관됨';
  }

  @override
  String get deleteSpacePermanently => '영구 삭제';

  @override
  String get renameSpace => '스페이스 이름 변경';

  @override
  String get renameConversation => '대화 이름 변경';

  @override
  String get spaceActions => '스페이스 작업';

  @override
  String get conversationActions => '대화 작업';

  @override
  String get editSpaceRepos => '저장소 편집';

  @override
  String get editSpaceReposTitle => '스페이스 저장소';

  @override
  String get editSpaceReposWarning =>
      '저장소를 추가하면 이 스페이스에 체크아웃되고, 제거하면 해당 폴더가 삭제됩니다.';

  @override
  String get agentSectionIdentity => '아이덴티티';

  @override
  String get agentSectionRuntime => '런타임';

  @override
  String get agentSectionGuardrails => '가드레일';

  @override
  String orgChartReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '보고서 $count개',
      one: '보고서 1개',
    );
    return '$_temp0';
  }

  @override
  String get teamsFilterHint => '팀 필터…';

  @override
  String get teamsSummaryWithLeader => '리더 있음';

  @override
  String teamCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '팀 $count개',
      one: '팀 1개',
      zero: '팀 없음',
    );
    return '$_temp0';
  }

  @override
  String agentDeleteLongDescription(String name) {
    return '$name을(를) 삭제하면 프로필, 스킬 연결, 실행 기록이 삭제됩니다. 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get resetToDefault => '기본값으로 재설정';

  @override
  String get newAgent => '새 에이전트';

  @override
  String get newSkill => '새 스킬';

  @override
  String get zoomIn => '확대';

  @override
  String get zoomOut => '축소';

  @override
  String get resetZoom => '줌 재설정';

  @override
  String get imageHostedOnGitHub => 'GitHub에 호스팅된 이미지';

  @override
  String get imageOpenExternally => '이미지 · 외부에서 열기';

  @override
  String get memoryScopeAll => '모든 범위';

  @override
  String get memoryScopeWorkspace => '워크스페이스 전체';

  @override
  String get memoryScopeFilterLabel => '범위별 필터';

  @override
  String memoryScopeRepoTooltip(String repo) {
    return '$repo 저장소 범위';
  }

  @override
  String get toolScreenshot => '에이전트 스크린샷';

  @override
  String get toolImageUnavailable => '이미지를 사용할 수 없음';

  @override
  String toolImagesUnavailable(int count) {
    return '이미지 $count개를 사용할 수 없음';
  }

  @override
  String get shakeUnavailable => '이 서버에서는 흔들기를 사용할 수 없습니다';

  @override
  String get shakeNothing => '흔들어 비울 내용이 없습니다 — 최근 턴은 보호됩니다';

  @override
  String shakeDone(int tokens) {
    return '약 $tokens 토큰을 확보했습니다';
  }

  @override
  String get compactionDivider => '압축됨';

  @override
  String compactionDividerCount(int count) {
    return '압축됨 · 메시지 $count개 접힘';
  }

  @override
  String get composerDropToAttach => '놓아서 첨부';

  @override
  String get attachmentUnavailable => '첨부 파일을 사용할 수 없음';

  @override
  String get attachmentUnavailableDetail =>
      '이 첨부 파일은 더 이상 메모리에 없습니다. 미리 보려면 다시 첨부하세요.';

  @override
  String get attachmentPreviewFailed => '이 파일을 열 수 없습니다';

  @override
  String get attachmentPreviewUnsupported => '이 파일 형식은 미리 볼 수 없습니다';

  @override
  String get attachmentTooLargeToPreview => '파일이 너무 커서 미리 볼 수 없습니다';

  @override
  String get attachmentOpenExternally => '기본 앱으로 열기';

  @override
  String get asideUnavailable => '이 기능을 사용하려면 워크스페이스 설정에서 원샷 모델을 지정하세요';

  @override
  String get asideEmpty => '아직 작업할 내용이 없습니다';

  @override
  String get asideFailed => '답변을 가져오지 못했습니다';

  @override
  String get handoffTitle => '핸드오프';

  @override
  String get asideTitle => '사이드 질문';

  @override
  String get attachFilesOrDrop => '파일을 첨부하거나 여기에 놓으세요';

  @override
  String get guidedGoalTitle => '목표를 구체화하세요';

  @override
  String get guidedGoalIntro =>
      '감독 없이 작업하는 에이전트는 완료 시점을 정확히 알아야 합니다. 먼저 몇 가지 질문을 드리겠습니다.';

  @override
  String get guidedGoalAnswerHint => '답변';

  @override
  String get guidedGoalNext => '다음';

  @override
  String get guidedGoalStart => '목표 시작';

  @override
  String get guidedGoalSkip => '건너뛰고 작성된 대로 실행';

  @override
  String guidedGoalStillMissing(String items) {
    return '아직 지정되지 않음: $items';
  }

  @override
  String get conversationTreeTitle => '대화 트리';

  @override
  String conversationTreeBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '분기 $count개',
      one: '분기 1개',
    );
    return '$_temp0';
  }

  @override
  String get conversationTreeSwitch => '여기서 이어서 진행';

  @override
  String get conversationTreeFork => '새 대화로 포크';

  @override
  String get conversationTreeCurrent => '이 분기';

  @override
  String get conversationTreeEmpty => '아직 내용이 없습니다';

  @override
  String get conversationTreeForked => '새 대화로 포크했습니다';

  @override
  String get conversationTreeSwitched => '해당 메시지부터 이어서 진행합니다';

  @override
  String exportSaved(String path) {
    return '$path에 저장했습니다';
  }

  @override
  String get exportFailed => '내보내기를 저장하지 못했습니다';

  @override
  String get contextCommandNoAgent => '이 대화에 에이전트가 없어 열 컨텍스트 창이 없습니다';

  @override
  String contextCommandNoSuchAgent(String name, String names) {
    return '이 대화에 “$name” 에이전트가 없습니다. 다음을 시도해 보세요: $names';
  }

  @override
  String get dumpCopied => '대화 기록을 클립보드에 복사했습니다';

  @override
  String get messageQueueHint => '계속 입력하면 후속 변경이 대기열에 추가됩니다';

  @override
  String get steerNow => '스티어';

  @override
  String get steeringQueueLabel => '대기 중인 스티어링 메시지';

  @override
  String get steeringDeliverUnavailable =>
      '지금 받을 수 있는 실행 중인 에이전트가 없습니다. 대기열에 유지됩니다.';

  @override
  String get reorderSteeringCard => '대기 메시지 순서 변경';

  @override
  String get editSteeringCard => '대기 메시지 편집';

  @override
  String get deleteSteeringCard => '대기 메시지 삭제';

  @override
  String get steeringBadge => '스티어됨';

  @override
  String get settingsSandboxLabel => '샌드박스';

  @override
  String get sandboxExecGrantsTitle => '실행 권한';

  @override
  String get sandboxExecGrantsSubtitle =>
      '에이전트가 저장소 작업 복사본에서 실행할 수 있는 프로그램입니다. 각 항목은 샌드박스가 물었을 때 직접 승인한 것입니다.';

  @override
  String get sandboxExecGrantsEmpty =>
      '아직 기록된 결정이 없습니다. 에이전트가 작업 복사본에서 프로그램을 처음 실행해야 할 때 묻습니다.';

  @override
  String get sandboxExecGrantRevoke => '철회';

  @override
  String get sandboxExecGrantAllowed => '허용됨';

  @override
  String get sandboxExecGrantBlocked => '차단됨';

  @override
  String get sandboxExecGrantRevokeConfirmTitle => '이 결정을 철회할까요?';

  @override
  String get sandboxExecGrantRevokeConfirmBody =>
      '에이전트가 이 복사본에서 프로그램을 다시 실행해야 할 때 다시 묻습니다.';

  @override
  String get repoScriptsTest => '테스트';

  @override
  String get repoScriptsTestTooltip => '저장소의 임시 클론에서 이 초안을 실행합니다';

  @override
  String get repoScriptsRunKindTest => '테스트';

  @override
  String get demoBadgeLabel => '데모';

  @override
  String get demoFilePickerTitle => '데모 파일';

  @override
  String get demoFilePickerBody =>
      '데모에서는 업로드가 가상입니다. 아무거나 고르면 디스크에 쓰지 않고 메시지에 첨부됩니다.';

  @override
  String get demoFilePickerAttach => '첨부';

  @override
  String get demoReadOnlySave => '데모에서는 읽기 전용입니다';

  @override
  String get demoBadgeTooltip => '데모를 둘러보고 있습니다. 데이터는 가상이며 에이전트는 스크립트로 동작합니다.';

  @override
  String get demoFirstRunTitle => '라이브 데모입니다';

  @override
  String demoFirstRunBody(int minutes) {
    return '실제 코드로 동작하는 진짜 앱입니다. 데이터만 가상입니다. 에이전트는 스크립트에서 실제 실행처럼 스트리밍하므로 모델로 요청이 가지 않고 실제 머신에서도 실행되지 않습니다. 워크스페이스는 사용자 전용이며 $minutes분 후 사라집니다.';
  }

  @override
  String get demoFirstRunDismiss => '확인';

  @override
  String get demoTourTitle => '먼저 볼 곳';

  @override
  String get demoTourSubtitle => '앱이 실제로 하는 일을 보여주는 네 곳입니다.';

  @override
  String get demoTourSkip => '건너뛰기';

  @override
  String get demoTourStarRepo => 'GitHub에서 스타';

  @override
  String get demoTourDone => '완료';

  @override
  String get demoTourOpen => '열기';

  @override
  String get demoTourSpacesTitle => '에이전트와 대화';

  @override
  String get demoTourSpacesBody =>
      '스페이스에 메시지를 보내고 실행이 스트리밍되는 모습을 보세요. 사고, 도구 호출, 비용이 실제 실행과 똑같이 표시됩니다.';

  @override
  String get demoTourReviewTitle => '풀 리퀘스트 리뷰';

  @override
  String get demoTourReviewBody =>
      '#412를 여세요. 인라인 댓글을 남기거나 리뷰를 제출하면 내용이 스레드에 남아 있습니다.';

  @override
  String get demoTourTicketsTitle => '작업 따라가기';

  @override
  String get demoTourTicketsBody => '티켓, 할 일, 계획이 에이전트가 나누는 같은 대화에 연결되어 있습니다.';

  @override
  String get demoTourInboxTitle => '전체 운영 보기';

  @override
  String get demoTourInboxBody =>
      '모든 영역의 알림이 하나의 받은편지함에 모입니다. 리뷰, 티켓, 실행, 미팅입니다.';

  @override
  String demoSessionEndingSoon(int minutes) {
    return '이 데모 세션은 $minutes분 후에 종료됩니다.';
  }

  @override
  String get demoSessionEnded => '이 데모 세션이 종료되었습니다. 페이지를 새로고침하면 새 세션이 시작됩니다.';

  @override
  String get demoUnavailableTitle => '데모에서 사용할 수 없음';

  @override
  String get demoUnavailableTerminal =>
      '터미널은 서버 호스트에서 실제 셸을 실행합니다. 데모에는 실행 환경이 전혀 없습니다. 그래서 공개해도 안전합니다.';

  @override
  String get demoUnavailableRig =>
      '인클로저는 에이전트가 다루는 일회용 가상 머신입니다. 데모는 하나도 부팅하지 않습니다. VM을 띄울 수 있는 공개 엔드포인트는 데모가 아닙니다.';

  @override
  String get demoUnavailableEditor =>
      '브라우저 편집기는 실제 체크아웃에서 code-server 프로세스를 실행합니다. 데모에는 둘 다 없습니다.';

  @override
  String get demoUnavailableFeeds =>
      '데모는 실제 피드를 읽지만 구독 목록은 고정입니다. 여기서는 추가하거나 제거할 수 없습니다.';

  @override
  String get demoUnavailableForge =>
      '데모는 자격 증명을 보관하지 않으며 GitHub, GitLab, Linear에 연결하지 않습니다. 풀 리퀘스트는 미리 넣어 둔 데이터이고, 댓글은 이 기기에 저장됩니다.';

  @override
  String get demoUnavailableModels =>
      '데모는 모델을 호출하지 않습니다. 에이전트 실행은 스크립트 재생이라 비용이 들지 않고 어떤 제공자에도 연결되지 않습니다.';

  @override
  String get demoUnavailableMcp =>
      '데모에는 MCP 도구 표면이 마운트되지 않아 외부 클라이언트가 연결할 수 없습니다.';

  @override
  String get demoUnavailableRepos =>
      '데모는 코드를 체크아웃하지 않고 git도 실행하지 않습니다. 보이는 저장소는 풀 리퀘스트용으로 미리 넣어 둔 데이터입니다.';

  @override
  String get demoUnavailableSkills =>
      '스킬을 설치하면 코드를 내려받고 검사합니다. 데모는 아무것도 가져오지 않습니다.';

  @override
  String get demoUnavailableSso => '싱글 사인온은 서버 설정입니다. 데모에서는 임시 게스트로 로그인합니다.';

  @override
  String get demoUnavailableAudio =>
      '녹음과 받아쓰기는 호스트의 오디오 캡처와 음성 모델이 필요합니다. 데모에는 둘 다 없어 회의는 재생 없이 기록만 있습니다.';

  @override
  String get demoUnavailableServerAdmin =>
      '서버 관리 기능입니다. 데모는 방문객마다 일회용 워크스페이스만 제공하며 그 이상은 없습니다.';

  @override
  String get settingsBackupRestore => '백업 및 복원';

  @override
  String get settingsBackupRestoreDescription =>
      '이 서버의 모든 데이터베이스 스냅샷과, 워크스페이스 하나의 내보내기·가져오기·삭제입니다.';

  @override
  String get backupSnapshotsLabel => '설치 스냅샷';

  @override
  String get backupSnapshotsExplainer =>
      '스냅샷은 모든 데이터베이스를 서버 호스트의 타임스탬프 폴더에 복사합니다. 설치 전체를 복원하려면 서버를 중지한 뒤 그 폴더를 다시 복사하면 됩니다. 워크스페이스 하나는 여기서 복원할 수 있습니다.';

  @override
  String get backupNowAction => '지금 백업';

  @override
  String backupSnapshotWritten(String path) {
    return '스냅샷을 $path에 저장했습니다';
  }

  @override
  String get backupNoSnapshots => '아직 스냅샷이 없습니다. 요청할 때만 생성되며 예약 실행은 없습니다.';

  @override
  String get backupSnapshotComplete => '완료';

  @override
  String get backupSnapshotIncomplete => '미완료';

  @override
  String get backupSnapshotIncompleteNote =>
      '매니페스트가 없거나 없는 파일을 가리켜 이 스냅샷으로는 설치 전체를 복원할 수 없습니다. 있는 워크스페이스 파일은 하나씩 가져올 수 있습니다.';

  @override
  String backupSnapshotWorkspaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '워크스페이스 $count개',
      one: '워크스페이스 1개',
      zero: '워크스페이스 없음',
    );
    return '$_temp0';
  }

  @override
  String backupSnapshotSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '캡처되지 않은 워크스페이스 $count개',
      one: '캡처되지 않은 워크스페이스 1개',
    );
    return '$_temp0';
  }

  @override
  String get backupServerPathLabel => '서버 경로';

  @override
  String get backupRestoreAction => '복원';

  @override
  String get backupRestoreTitle => '워크스페이스 복원';

  @override
  String backupRestoreBody(String name) {
    return '이 스냅샷의 복사본으로 $name의 모든 내용을 바꿉니다. 스냅샷 이후의 작업은 모두 사라지며 되돌릴 수 없습니다.';
  }

  @override
  String backupRestoreDone(String name) {
    return '스냅샷에서 $name을(를) 복원했습니다.';
  }

  @override
  String get backupWorkspaceUnknown => '이 서버에 더 이상 없습니다';

  @override
  String get backupWorkspaceDataLabel => '워크스페이스 데이터';

  @override
  String get backupWorkspaceDataExplainer =>
      '워크스페이스 하나는 데이터베이스 파일 하나이므로, 내보내기는 테이블을 덤프하지 않고 그 파일을 복사합니다. 가져오기는 지정한 파일로 대상 워크스페이스의 모든 내용을 바꿉니다.';

  @override
  String get backupExportAction => '내보내기';

  @override
  String backupExportDone(String path) {
    return '$path(으)로 내보냈습니다';
  }

  @override
  String get backupExportedFileLabel => '서버의 내보낸 파일';

  @override
  String get backupImportAction => '가져오기';

  @override
  String backupImportTitle(String name) {
    return '$name(으)로 가져오기';
  }

  @override
  String backupImportBody(String name) {
    return '파일 내용으로 $name의 모든 내용을 바꿉니다. 현재 워크스페이스 내용은 모두 사라지며 되돌릴 수 없습니다.';
  }

  @override
  String get backupImportSourceLabel => '워크스페이스 데이터베이스 파일';

  @override
  String get backupImportSourceDescription =>
      '서버가 읽을 수 있는 .db 파일입니다. 경로는 이 기기가 아니라 서버 호스트에서 해석됩니다.';

  @override
  String get backupImportChooseFile => '파일 선택';

  @override
  String backupImportDone(String name) {
    return '$name(으)로 가져왔습니다.';
  }

  @override
  String backupDeleteBody(String name) {
    return '$name이(가) 모든 목록과 조회에서 사라집니다. 데이터베이스 파일은 디스크에 남고 백업에도 포함되며, 공간은 자동으로 회수되지 않습니다.';
  }

  @override
  String get backupExportDescription => '서버에 복사본을 저장하거나 이 기기로 내려받으세요.';

  @override
  String get backupExportOnServerAction => '서버에 저장';

  @override
  String get backupDownloadAction => '다운로드';

  @override
  String backupDownloadSaved(String path) {
    return '$path에 저장했습니다';
  }

  @override
  String get backupDownloadInBrowser => '브라우저에서 다운로드 중입니다.';

  @override
  String get backupRestoreFromDeviceLabel => '이 기기에서 복원';

  @override
  String get backupRestoreFromDeviceDescription =>
      '여기서 워크스페이스 데이터베이스 파일을 고르면 Control Center가 서버로 업로드합니다. 서버가 이 기기가 아닐 때 쓰는 방법입니다.';

  @override
  String get backupUploadAction => '파일 선택 후 업로드';

  @override
  String get backupTransferUnavailable =>
      '이 연결은 릴레이를 통해 서버에 도달하며, 릴레이는 파일 전송을 지원하지 않습니다. 백업을 다운로드하거나 업로드하려면 서버에 직접 연결하세요.';

  @override
  String get backupTransferForbidden =>
      '서버가 거부했습니다. 워크스페이스를 다운로드하려면 관리자 역할이, 복원하려면 소유자가, 설치 전체 스냅샷에는 설치 운영자가 필요합니다.';

  @override
  String get backupTransferUnsupported => '이 서버에는 백업 기능이 없습니다.';

  @override
  String get backupTransferTooLarge => '파일이 서버가 허용하는 크기보다 큽니다.';

  @override
  String get credentialGateWaitingTitle => '자격 증명을 기다리는 중';

  @override
  String credentialGateHarnessTitle(String provider) {
    return '$provider에 자격 증명이 없습니다';
  }

  @override
  String get credentialGateSignedOutTitle => 'Claude Code에서 로그아웃되어 있습니다';

  @override
  String get credentialGateExpiredTitle => 'Claude Code 로그인이 만료되었습니다';

  @override
  String get credentialGatePlanSpentTitle => 'Claude Code 플랜 한도에 도달했습니다';

  @override
  String credentialGateWaitingAgent(String agent) {
    return '$agent이(가) 계속하기를 기다리고 있습니다.';
  }

  @override
  String get credentialGateWaitingRun => '실행이 계속하기를 기다리고 있습니다.';

  @override
  String get credentialGateWatching => '수정이 반영되기를 확인하는 중입니다. 실행은 자동으로 계속됩니다.';

  @override
  String credentialGateFreesUpAt(String time) {
    return '$time에 해제됩니다';
  }

  @override
  String credentialGateGivesUpAt(String time) {
    return '실행이 $time에 포기합니다';
  }

  @override
  String get credentialGateCheckAgain => '다시 확인';

  @override
  String get credentialGateCancelRun => '실행 취소';

  @override
  String get credentialGateAccountsTried => '시도한 계정';

  @override
  String get credentialGateClaudeSignInHint =>
      '설정 → 어댑터 → Claude Code에서 로그인하거나, 터미널에서 로그인 명령을 실행하세요. 실행이 자동으로 반영됩니다.';

  @override
  String get credentialGateOpenSettings => '설정 열기';

  @override
  String get selectModel => '모델 선택';

  @override
  String get allModels => '모든 모델';

  @override
  String get noModelsMatchSearch => '검색과 일치하는 모델이 없습니다';

  @override
  String useCustomModelId(String id) {
    return '“$id” 사용';
  }

  @override
  String get modelFree => '무료';

  @override
  String modelOutputTokens(String tokens) {
    return '출력 $tokens';
  }

  @override
  String modelPricePerMTokens(String input, String output) {
    return '100만 토큰당 입력 $input / 출력 $output';
  }

  @override
  String modelEffortLevels(String levels) {
    return '추론 강도: $levels';
  }

  @override
  String get modelSupportsReasoning => '추론 강도 지원';

  @override
  String get profileDeliveryMetrics => '배포 지표';

  @override
  String profileMetricsSample(int count) {
    return '분석한 PR: $count';
  }

  @override
  String get profileMergeRate => '병합률';

  @override
  String get profileReviewCoverage => '리뷰 적용률';

  @override
  String get profilePrSize => 'PR 크기';

  @override
  String get profileTimeToMerge => '병합 소요 시간';

  @override
  String get profileMergeTimeTrend => '병합 시간 추이';

  @override
  String get profileWeeklyMedian => '주간 중앙값, 로그 스케일';

  @override
  String get profilePrOpeningPattern => '요일 × 시간, 현지 시간';

  @override
  String get profileFirstReview => '첫 리뷰 소요 시간';

  @override
  String get profileMetricsTruncated =>
      '백분위수는 사용 가능한 풀 리퀘스트의 제한된 표본을 기준으로 합니다.';

  @override
  String profileLinesChanged(String count) {
    return '$count줄';
  }

  @override
  String profileDurationMinutes(int count) {
    return '$count분';
  }

  @override
  String profileDurationHours(int count) {
    return '$count시간';
  }

  @override
  String profileDurationDaysHours(int days, int hours) {
    return '$days일 $hours시간';
  }

  @override
  String profilePercentiles(String median, String p90) {
    return 'p50 $median · p90 $p90';
  }

  @override
  String profileTeamMembers(int count) {
    return '멤버: $count';
  }

  @override
  String noPrsByTeamInWorkspace(String team) {
    return '이 워크스페이스에 $team의 풀 리퀘스트가 없습니다';
  }

  @override
  String get profilePrStateFilterLabel => '상태별로 풀 리퀘스트 필터링';

  @override
  String get noProfilePrsMatchSearchHint => '다른 제목이나 풀 리퀘스트 번호를 입력해 보세요';

  @override
  String get rigNetworkUnrestricted => '제한 없는 네트워크';

  @override
  String get rigNetworkAllowAllHosts => '모든 호스트 허용';

  @override
  String get rigNetworkBypassTitle => '모든 네트워크 호스트를 허용할까요?';

  @override
  String get rigNetworkBypassBody =>
      '격리 환경을 다시 시작하고 내부의 커밋되지 않은 작업을 삭제합니다. 이후 게스트는 닫힐 때까지 모든 네트워크 호스트에 접근할 수 있습니다.';

  @override
  String get rigNetworkRestartUnrestricted => '제한 없이 다시 시작';

  @override
  String get rigNetworkUnrestrictedBody =>
      '이 격리 환경은 모든 네트워크 호스트에 접근할 수 있습니다. 기본 제한을 복원하려면 닫고 새 환경을 여세요.';

  @override
  String get rigNetworkAlreadyUnrestrictedBody =>
      '이 Android 에뮬레이터는 이미 자체 네트워크를 관리하므로 Control Center에서 호스트별 허용 목록을 적용할 수 없습니다. 다시 시작할 필요가 없습니다.';

  @override
  String get rigClipboardPermissionHostToRigTitle => '클립보드를 이 환경에 붙여넣을까요?';

  @override
  String get rigClipboardPermissionHostToRigBody =>
      'Control Center가 기기의 클립보드를 읽고 그 내용을 환경으로 보냅니다. 클립보드 내용에는 비밀번호나 기타 비밀 정보가 포함될 수 있습니다.';

  @override
  String get rigClipboardPermissionRigToHostTitle => '이 환경에서 클립보드를 복사할까요?';

  @override
  String get rigClipboardPermissionRigToHostBody =>
      'Control Center가 환경의 클립보드를 읽고 그 내용으로 기기의 클립보드를 대체합니다. 환경에서 온 콘텐츠는 신뢰할 수 없는 것으로 취급하세요.';

  @override
  String get rigClipboardAllowTenMinutes => '10분 동안 허용';

  @override
  String get rigClipboardAlwaysAllow => '항상 허용';

  @override
  String get rigClipboardSettingsTitle => '클립보드 접근';

  @override
  String get rigClipboardSettingsHint =>
      '확인 없이 실행할 수 있는 클립보드 전송을 선택하세요. 임시 권한은 10분 후 만료됩니다.';

  @override
  String get rigClipboardAlwaysPasteTitle => '환경에 붙여넣기 항상 허용';

  @override
  String get rigClipboardAlwaysPasteDescription =>
      '확인 없이 이 기기의 클립보드를 모든 환경으로 보냅니다.';

  @override
  String get rigClipboardAlwaysCopyTitle => '환경에서 복사 항상 허용';

  @override
  String get rigClipboardAlwaysCopyDescription =>
      '확인 없이 모든 환경의 클립보드 내용을 이 기기에 넣습니다.';
}
