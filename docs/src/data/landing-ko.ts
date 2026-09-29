import type { LandingCopy } from "./landing-en";

export const ko: LandingCopy = {
  meta: {
    title: "Control Center \\\\ 개발하는 하루의 자리",
    description:
      "티켓, 코드 리뷰, AI 에이전트, 회의, 파이프라인을 한곳에 모읍니다. 데스크톱, 웹, 휴대폰을 위한 무료 오픈 소스 작업 공간입니다.",
    imageAlt: "Control Center, 개발 일을 하나의 작업 공간에.",
  },
  nav: {
    product: "제품",
    workflows: "워크플로",
    features: "기능",
    docs: "문서",
    demo: "데모 사용해 보기",
    download: "다운로드",
    menu: "메뉴",
    primary: "기본 탐색",
    mobile: "모바일 탐색",
    home: "Control Center 홈",
    skip: "본문으로 건너뛰기",
    language: "언어",
    appearance: "모양",
    light: "밝게",
    dark: "어둡게",
    system: "시스템",
  },
  hero: {
    line1: "움직이는 것이 많습니다.",
    line2: "Control Center는 하나입니다.",
    description:
      "코드, 에이전트, 리뷰, 그리고 개발하는 하루를 채우는 모든 것의 자리입니다.",
    download: "Control Center 받기",
    demo: "라이브 데모 살펴보기",
    platforms: "macOS, Windows, Linux",
    web: "웹과 휴대폰에서도",
  },
  media: {
    phone:
      "휴대폰 동반 앱이 같은 작업 공간, 대기 중인 승인, 에이전트 실행 상태를 보여 줍니다.",
  },
  tour: {
    label: "Control Center 살펴보기",
    previous: "이전 제품 화면",
    next: "다음 제품 화면",
    play: "둘러보기 재생",
    pause: "둘러보기 일시정지",
    videoPlay: "미리보기 재생",
    videoPause: "미리보기 일시정지",
    expand: "미리보기 확대",
    preview: "제품 미리보기",
    close: "미리보기 닫기",
    note: "개발하는 하루를 조금 더 가까이.",
    imageLanguage: "이미지 또는 동영상 자리",
    stops: [
      {
        kind: "desk",
        label: "하루",
        title: "당신을 필요로 하는 일부터.",
        description:
          "리뷰 요청, 승인, 막힌 일. 다음 행동은 탭을 뒤지지 않아도 보입니다.",
        alt: "Control Center 받은편지함이 풀 리퀘스트를 리뷰 상태별로 모으고 동기화 장애를 보여 줍니다.",
      },
      {
        kind: "agents",
        label: "에이전트",
        title: "좋은 일이 일어날 자리를 둡니다.",
        description:
          "에이전트는 격리된 Git worktree에서 돕니다. 도구를 따라가고, 일을 이끌고, 맥락을 남깁니다.",
        alt: "Control Center의 에이전트 대화. 작업 맥락과 활동이 보입니다.",
      },
      {
        kind: "review",
        label: "코드 리뷰",
        title: "변경을 읽습니다. 이야기를 압니다.",
        description:
          "diff, 토론, 검사는 함께 있습니다. 리뷰는 자신의 계정으로 게시합니다.",
        alt: "Control Center의 풀 리퀘스트 리뷰. 코드 변경과 리뷰 맥락이 있습니다.",
      },
      {
        kind: "tickets",
        label: "티켓",
        title: "다음 단계를 이어 둡니다.",
        description:
          "우선순위와 담당을 보고, Linear를 동기화하고, 일이 일어나는 대화에 연결합니다.",
        alt: "Control Center 티켓 보드. 작업이 상태별로 모여 있습니다.",
      },
      {
        kind: "meetings",
        label: "회의",
        title: "통화가 끝나도 결정은 남습니다.",
        description:
          "녹음과 전사는 자신의 서버에서 합니다. 회의가 끝나면 메모와 할 일이 있습니다.",
        alt: "Control Center의 회의. 전사와 회의 정보가 있습니다.",
      },
      {
        kind: "pipelines",
        label: "파이프라인",
        title: "반복되는 일을 반복할 수 있게.",
        description:
          "워크플로를 만들고, 트리거를 고르고, 실행의 단계마다 따라갑니다.",
        alt: "Control Center 파이프라인. 워크플로 단계와 실행 상태가 보입니다.",
      },
    ],
  },
  integrations: {
    title: "이미 쓰는 도구를 데려옵니다.",
    note: "연결은 자신의 서버를 통합니다. 하루를 하나 더 복사하지 않습니다.",
  },
  grid: {
    title: "매일 손을 뻗는 도구.",
    description: "일을 하고, 바뀐 것을 보고, 결정을 남깁니다.",
    more: "문서 읽기",
    items: [
      {
        title: "병렬 에이전트",
        description:
          "작업마다 격리된 Git worktree를 줍니다. 실행을 따라가고, 에이전트를 이끌거나, 나머지를 건드리지 않고 넘겨받습니다.",
        link: "에이전트를 병렬로 실행",
        kind: "agents",
        href: "/manual/guides/parallel-agents/",
      },
      {
        title: "풀 리퀘스트 리뷰",
        description:
          "diff를 토론과 검사 옆에서 읽습니다. 도움이 될 때 AI 리뷰를 더하고, 자신의 forge 계정으로 게시합니다.",
        link: "풀 리퀘스트 리뷰하기",
        kind: "review",
        href: "/manual/guides/review-merge-pr/",
      },
      {
        title: "이어진 티켓",
        description:
          "Linear를 동기화하고, 우선순위를 정하고, 일을 맡깁니다. 티켓을 그 일이 끝나는 대화에 연결합니다.",
        link: "티켓 관리",
        kind: "tickets",
        href: "/manual/guides/manage-tickets/",
      },
      {
        title: "회의 메모",
        description:
          "녹음과 전사는 자신의 서버에서 합니다. 통화가 끝난 뒤에도 결정과 할 일이 남습니다.",
        link: "회의 녹음",
        kind: "meetings",
        href: "/manual/guides/record-meeting/",
      },
      {
        title: "반복할 수 있는 파이프라인",
        description:
          "워크플로는 한 번 만듭니다. 일정, 이벤트, 또는 손으로 실행하고 단계마다 살펴봅니다.",
        link: "파이프라인 만들기",
        kind: "pipelines",
        href: "/manual/guides/create-pipeline/",
      },
      {
        title: "계정 전환",
        description:
          "에이전트마다 사용할 수 있는 계정을 고르고, 실행 맥락을 잃지 않은 채 계정을 전환합니다.",
        link: "모델 제공업체 관리",
        kind: "accounts",
        href: "/manual/guides/adapters/",
        alt: "에이전트가 사용할 수 있는 계정을 보여 주는 Control Center의 계정 풀 편집기.",
      },
      {
        title: "사용량 한도",
        description:
          "다음 실행을 시작하기 전에 제공업체별 허용량과 초기화 시점을 확인합니다.",
        link: "비용 관리",
        kind: "quota",
        href: "/manual/guides/manage-costs/",
        alt: "제공업체별 사용 한도와 초기화 시점을 보여 주는 Control Center 사용량 패널.",
      },
      {
        title: "사운드스케이프와 집중",
        description:
          "시간을 정해 집중 세션을 실행하고, 알림을 끄고, 배경에서 재생되는 사운드스케이프를 조절합니다.",
        link: "집중 모드 사용",
        kind: "focus",
        href: "/manual/guides/focus-mode/",
        alt: "Control Center의 집중 타이머와 사운드스케이프 조작 화면.",
      },
      {
        title: "실행 관측",
        description:
          "활성 에이전트를 추적하고 작업 공간에서 실행 비용, 토큰 사용량, 지연 시간을 살펴봅니다.",
        link: "에이전트 실행 살펴보기",
        kind: "observability",
        href: "/manual/guides/manage-costs/",
        alt: "활성 에이전트와 실행 분석을 보여 주는 Control Center의 실행 관측 화면.",
      },
      {
        title: "스킬과 에이전트 편집기",
        description:
          "작업 공간 스킬을 편집하고 에이전트별 모델, 지침, 권한을 설정합니다.",
        link: "스킬 관리",
        kind: "editors",
        href: "/manual/guides/manage-skills/",
        alt: "Control Center의 스킬 편집기와 에이전트 설정.",
      },
    ],
    supporting: [
      {
        title: "받은편지함은 하나",
        description:
          "리뷰, 승인, 막힌 일이 한 줄에 있습니다. 명령 팔레트로 다음 작업에 갑니다.",
        href: "/manual/guides/triage-inbox/",
      },
      {
        title: "휴대폰에서 확인",
        description:
          "책상으로 돌아가지 않아도 실행을 따라가고 승인을 처리합니다.",
        href: "/manual/concepts/remote-control/",
      },
    ],
  },
  workflow: {
    title: "실을 놓치지 않습니다.\n나갈 때까지.",
    description: "일은 도구 사이를 이동합니다. 맥락도 함께 와야 합니다.",
    label: "이어진 워크플로",
    steps: [
      {
        title: "티켓에서 시작합니다.",
        text: "우선순위를 정하고, 담당을 적고, 대화를 연결합니다. 기록을 갖는 것은 티켓입니다.",
        kind: "tickets",
        label: "의도",
      },
      {
        title: "일에 자리를 줍니다.",
        text: "계획을 이야기하고, 격리된 worktree를 준비하고, 에이전트를 실행합니다. 필요할 때 이끌거나 넘겨받습니다.",
        kind: "agents",
        label: "일",
      },
      {
        title: "결과를 리뷰로 가져옵니다.",
        text: "변경을 읽고, 토론을 따라가고, forge 계정으로 게시합니다. 이야기는 이어져 있습니다.",
        kind: "review",
        label: "결과",
      },
    ],
  },
  boundaries: {
    title: "push는 실행 전에 승인합니다.",
    description:
      "Git push, 풀 리퀘스트 게시, 그 밖의 보호된 동작은 승인 뒤에 둡니다. 무엇이 바뀌기 전에 에이전트가 하려는 일을 봅니다.",
    media:
      "Git push 승인 요청에서 멈춘 에이전트 실행. 제안된 명령, 작업 디렉터리, 승인하거나 거절하는 조작을 보여 줍니다.",
    note: "승인할 사람이 연결되어 있지 않으면 동작은 거절됩니다. 권한을 지키는 것은 서버이고, 프롬프트가 아닙니다.",
    link: "동작 승인 설정",
  },
  surfaces: {
    title: "책상은 장소입니다.\n일은 아닙니다.",
    description:
      "데스크톱에서 시작하고, 브라우저에서 들여다보고, 휴대폰에서 가까이 있습니다. 서버 하나가 일을 모아 둡니다.",
    desktop: "네이티브 데스크톱",
    web: "브라우저에서",
    phone: "휴대폰 동반 앱",
    note: "데이터와 실행은 서버가 갖습니다. 기기는 동기화된 채로 있습니다.",
    link: "내 플랫폼 찾기",
  },
  faq: {
    title: "좋은 질문입니다.",
    description: "자리를 잡기 전에 알아 두면 좋은 것들이 있습니다.",
    items: [
      {
        question: "Control Center는 AI 에이전트만 위한 제품인가요?",
        answer:
          "아닙니다. Control Center는 티켓, 풀 리퀘스트, 대화, 회의, 캘린더, 파이프라인, 에이전트, 개인 RSS 리더를 하나의 작업 공간에 둡니다. 에이전트는 책상의 일부이지, 나머지를 쓰기 위한 조건이 아닙니다.",
        links: [{ label: "기능 살펴보기", href: "/ko-KR/#features" }],
      },
      {
        question: "티켓과 대화는 어떻게 다른가요?",
        answer:
          "티켓은 일과 그 상태를 기록하고, 실행은 대화 안에서 일어납니다. 대화는 에이전트 실행 전에 격리된 copy-on-write worktree를 준비할 수 있습니다. Windows에서는 그 준비에 Git worktree를 씁니다.",
        links: [{ label: "예시 흐름 따라가기", href: "/ko-KR/#workflows" }],
      },
      {
        question: "에이전트는 어디에서 돌고, 서버는 무엇을 하나요?",
        answer:
          "서버는 작업 공간의 데이터베이스, 자격 증명, API, 에이전트 실행을 갖습니다. 데스크톱과 브라우저 클라이언트는 그 일을 보여 주고 다룹니다. 선택적 플릿 워커는 임대된 작업을 가져오고 이벤트를 흘리지만, 데이터베이스나 자격 증명, 예산은 갖지 않습니다.",
        links: [
          {
            label: "아키텍처 가이드 읽기",
            href: "/manual/concepts/architecture/",
          },
        ],
      },
      {
        question: "에이전트 실행을 얼마나 제어할 수 있나요?",
        answer:
          "대화마다 제안만, 승인 후 실행, 자유롭게 실행을 고를 수 있습니다. 권한과 샌드박스는 허용된 동작을 여전히 가둡니다. 승인할 사람이 없으면 승인 요청은 거절됩니다. 부드러운 예산 한도는 알리고, 단단한 한도는 멈추며, 실행은 기록을 남깁니다.",
        links: [{ label: "제어 보기", href: "/ko-KR/#boundaries" }],
      },
      {
        question: "Orchestrate 계획이 에이전트를 자동으로 고용하나요?",
        answer:
          "아닙니다. Orchestrate는 역할, 하위 티켓, 계획을 살펴보고 제안할 수 있지만, 고용은 승인을 기다립니다. Plan Studio는 원래 대화의 계획 줄에서 열립니다. 티켓을 배정하는 것만으로 실행이 시작되지는 않습니다.",
        links: [{ label: "예시 흐름 따라가기", href: "/ko-KR/#workflows" }],
      },
      {
        question: "페어링한 휴대폰에서 에이전트를 실행할 수 있나요?",
        answer:
          "페어링한 휴대폰은 같은 서버 작업 공간을 보는 얇은 클라이언트이지, 실행을 맡는 두 번째 기기가 아닙니다. 데스크톱, 브라우저, 휴대폰은 같은 일을 보여 줍니다. 에이전트는 서버 또는 선택적으로 임대된 플릿 워커에서 돕니다.",
        links: [{ label: "연결된 화면 보기", href: "/ko-KR/#surfaces" }],
      },
      {
        question: "어떤 연동을 쓸 수 있나요?",
        answer:
          "Linear 티켓 동기화는 구현되어 있습니다. Jira와 ClickUp에는 어댑터가 없습니다. 연결된 Google Calendar 일정은 읽기 전용이고, 참석 응답은 캘린더가 쓰기 권한을 줄 때만 있습니다. Slack 스레드는 대화로 이을 수 있고, 연결된 forge는 풀 리퀘스트와 검사를 제공합니다.",
        links: [{ label: "매뉴얼 읽기", href: "/manual/" }],
      },
      {
        question: "회의 메모와 할 일은 언제 나타나나요?",
        answer:
          "실시간 전사는 녹음 중에 말하는 사람을 가를 수 있습니다. 멈추면 요약 에이전트가 회의를 처리하고 메모, 결정, 할 일을 저장합니다. 녹음과 처리는 서로 다른 상태입니다.",
        links: [{ label: "하루를 맥락 속에서 보기", href: "/ko-KR/#day" }],
      },
      {
        question: "공개 데모는 실제 작업 공간인가요?",
        answer:
          "공개 데모는 따로 잠긴 빌드이며, 지어낸 데이터와 대본을 따르는 에이전트를 씁니다. 그 기록과 실행은 예시이지 자신의 일이 아닙니다.",
        links: [{ label: "라이브 데모 살펴보기", href: "/demo" }],
      },
    ],
  },
  pilot: {
    controls:
      "3D 패러글라이더입니다. 드래그하여 시점을 돌리고 방향을 조종하세요. 왼쪽·오른쪽 화살표로 선회하고 위쪽·아래쪽 화살표로 기수를 위아래로 기울입니다. R은 초기화하고 Space는 비행과 바람을 일시 정지하거나 재개합니다.",
  },
  install: {
    title: "자리를\n잡으세요.",
    description:
      "다음 개발하는 하루는 여기서 시작할 수 있습니다. 무료이고 오픈 소스입니다.",
    mac: "Apple Silicon · macOS 13+",
    windows: "x64 · Windows 10+",
    linux: "x86_64 · AppImage",
    release: "릴리스 보기",
    web: "웹 앱 열기",
    phone: "휴대폰 동반 앱 열기",
    webNote: "직접 실행하는 서버에 연결합니다.",
    phoneNote: "닫힌 릴레이로 휴대폰을 서버와 페어링합니다.",
    selfHost: "직접 호스트할까요?",
    server: "화면 없는 서버 실행",
    guide: "빠른 시작 가이드 읽기",
  },
  footer: {
    tagline: "개발하는 하루의 자리.",
    resources: "자료",
    source: "GitHub의 소스",
    compare: "비교",
    changelog: "변경 기록",
    about: "소개",
    contact: "연락처",
    privacy: "개인정보",
    terms: "약관",
    licenses: "라이선스",
    acknowledgements: "감사의 말",
    made: "열린 곳에서 만듭니다.",
    top: "맨 위로",
  },
};
