import type { LandingCopy } from "./landing-en";

export const zhHk: LandingCopy = {
  meta: {
    title: "Control Center \\\\ 開發者一天的家",
    description:
      "將工單、程式碼審查、AI 代理、會議同流水線放埋一齊。畀桌面、網頁同手機用嘅免費開源工作區。",
    imageAlt: "Control Center，將開發工作放進同一個工作區。",
  },
  nav: {
    product: "產品",
    workflows: "工作流程",
    features: "功能",
    docs: "文件",
    demo: "試用示範",
    download: "下載",
    menu: "選單",
    primary: "主要導覽",
    mobile: "流動導覽",
    home: "Control Center 主頁",
    skip: "跳到本文",
    language: "語言",
    appearance: "外觀",
    light: "淺色",
    dark: "深色",
    system: "系統",
  },
  hero: {
    line1: "有好多嘢同時郁緊。",
    line2: "得一個 Control Center。",
    description:
      "程式碼、代理、審查，同埋組成開發者一天嘅其他事，都有一個地方安放。",
    download: "取得 Control Center",
    demo: "睇下即場示範",
    platforms: "macOS, Windows, Linux",
    web: "網頁同手機都有",
  },
  media: {
    phone: "手機伴侶顯示同一個工作區、一項待處理嘅核准，同一次代理執行嘅狀態。",
  },
  tour: {
    label: "認識 Control Center",
    previous: "上一個產品畫面",
    next: "下一個產品畫面",
    play: "播放導覽",
    pause: "暫停導覽",
    videoPlay: "播放預覽",
    videoPause: "暫停預覽",
    expand: "展開預覽",
    preview: "產品預覽",
    close: "關閉預覽",
    note: "將開發者嘅一天睇近少少。",
    imageLanguage: "影像或影片佔位",
    stops: [
      {
        kind: "agents",
        label: "代理",
        title: "畀好嘅工作一個發生嘅地方。",
        description:
          "喺隔離嘅 Git worktree 入面執行代理。跟上佢哋嘅工具，引導工作，並保留脈絡。",
        alt: "Control Center 入面同代理嘅對話，睇到任務脈絡同活動。",
      },
      {
        kind: "desk",
        label: "收件箱",
        title: "由需要你嘅事先開始。",
        description: "審查請求、核准同阻塞。下一步就喺度，唔使喺分頁入面搵。",
        alt: "Control Center 收件箱按審查狀態歸組 Pull request，並顯示一處同步阻塞。",
      },
      {
        kind: "review",
        label: "程式碼審查",
        title: "讀改動。知道來龍去脈。",
        description: "差異、討論同檢查留喺一齊。用你自己嘅帳戶發佈審查。",
        alt: "Control Center 嘅 Pull request 審查，包含程式碼改動同審查脈絡。",
      },
      {
        kind: "tickets",
        label: "工單",
        title: "令下一步保持相連。",
        description:
          "追蹤優先次序同負責人，同步 Linear，並連上工作真正發生嘅對話。",
        alt: "Control Center 工單板按狀態歸組任務。",
      },
      {
        kind: "meetings",
        label: "會議",
        title: "通話完咗，決定仲喺。",
        description:
          "喺你自己嘅伺服器上面錄音同轉寫。會議結束時，你有筆記同行動項目。",
        alt: "Control Center 入面嘅會議，包含轉寫同會議資訊。",
      },
      {
        kind: "pipelines",
        label: "流水線",
        title: "令重複嘅工作可以重複。",
        description: "搭一條工作流程，揀定觸發方式，並跟上執行嘅每一步。",
        alt: "Control Center 嘅流水線檢視，包含工作流程步驟同執行狀態。",
      },
    ],
  },
  integrations: {
    title: "帶埋你已經用緊嘅工具。",
    note: "透過你嘅伺服器連接，而唔係再複製多一份你嘅一天。",
  },
  grid: {
    title: "每日都會伸手去攞嘅工具。",
    description: "將工作做完，睇清楚改咗啲咩，並將決定留低。",
    more: "閱讀文件",
    items: [
      {
        title: "並行代理",
        description:
          "畀每項任務一個隔離嘅 Git worktree。跟上執行，引導代理，或者喺唔打擾其餘工作嘅情況下接手。",
        link: "並行執行代理",
        kind: "agents",
        href: "/manual/guides/parallel-agents/",
      },
      {
        title: "Pull request 審查",
        description:
          "差異旁邊就係討論同檢查。需要時加上 AI 審查，再用你自己嘅程式碼託管帳戶發佈。",
        link: "審查 Pull request",
        kind: "review",
        href: "/manual/guides/review-merge-pr/",
      },
      {
        title: "連埋一齊嘅工單",
        description:
          "同步 Linear，設定優先次序，並分派工作。將工單連去完成佢嗰次對話。",
        link: "管理工單",
        kind: "tickets",
        href: "/manual/guides/manage-tickets/",
      },
      {
        title: "會議筆記",
        description:
          "喺你自己嘅伺服器上面錄音同轉寫。通話結束之後，決定同行動項目仲喺。",
        link: "錄製會議",
        kind: "meetings",
        href: "/manual/guides/record-meeting/",
      },
      {
        title: "可以重複嘅流水線",
        description:
          "工作流程搭一次。按日程、由事件或者手動執行，並檢查每一步。",
        link: "搭建流水線",
        kind: "pipelines",
        href: "/manual/guides/create-pipeline/",
      },
      {
        title: "切換帳戶",
        description: "揀好每個代理可以用嘅帳戶，再按需要切換，執行時嘅上下文都唔會丟失。",
        link: "管理模型供應商",
        kind: "accounts",
        href: "/manual/guides/adapters/",
        alt: "Control Center 帳戶池編輯器，顯示代理可以用嘅帳戶。",
      },
      {
        title: "使用配額",
        description: "開始下一次執行之前，查看供應商嘅可用額度同重設時間。",
        link: "管理費用",
        kind: "quota",
        href: "/manual/guides/manage-costs/",
        alt: "Control Center 使用情況面板，顯示供應商配額同重設時間。",
      },
      {
        title: "環境音與專注",
        description: "開始計時專注時段、將通知靜音，再調整背景播放緊嘅環境音。",
        link: "使用專注模式",
        kind: "focus",
        href: "/manual/guides/focus-mode/",
        alt: "Control Center 專注計時器同環境音控制介面。",
      },
      {
        title: "執行監察",
        description: "即時追蹤代理，查看工作空間入面每次執行嘅費用、Token 用量同延遲。",
        link: "查看代理執行紀錄",
        kind: "observability",
        href: "/manual/guides/manage-costs/",
        alt: "Control Center 執行監察檢視，顯示即時運作嘅代理同執行分析。",
      },
      {
        title: "技能與代理編輯器",
        description: "編輯工作空間技能，設定每個代理嘅模型、指令同權限。",
        link: "管理技能",
        kind: "editors",
        href: "/manual/guides/manage-skills/",
        alt: "Control Center 技能編輯器同代理設定介面。",
      },
    ],
    supporting: [
      {
        title: "一個收件箱",
        description:
          "審查、核准同阻塞排喺同一條隊列入面。用命令面板跳去下一項任務。",
        href: "/manual/guides/triage-inbox/",
      },
      {
        title: "用手機睇一眼",
        description: "唔使返到書枱，都可以跟上執行並處理核准。",
        href: "/manual/concepts/remote-control/",
      },
    ],
  },
  workflow: {
    title: "捉住條線。\n直至交付。",
    description: "工作會喺工具之間移動。脈絡應該跟住行。",
    label: "連埋一齊嘅工作流程",
    steps: [
      {
        title: "由工單開始。",
        text: "設定優先次序，寫低負責人，並連上對話。記錄留喺工單入面。",
        kind: "tickets",
        label: "意圖",
      },
      {
        title: "畀工作一個自己嘅地方。",
        text: "討論計劃，準備隔離嘅 worktree，並執行代理。需要時引導，或者接手。",
        kind: "agents",
        label: "工作",
      },
      {
        title: "將結果帶入審查。",
        text: "讀改動，跟上討論，並用你嘅程式碼託管帳戶發佈。故事仍然連住。",
        kind: "review",
        label: "結果",
      },
    ],
  },
  boundaries: {
    title: "先核准 push，先至畀佢執行。",
    description:
      "將 Git push、發佈 Pull request 同其他受保護嘅操作放喺核准後面。喺任何嘢改變之前，先睇代理準備做咩。",
    media:
      "一次代理執行停喺 Git push 嘅核准請求上。展示建議嘅命令、工作目錄，以及核准或者拒絕嘅控制項。",
    note: "冇核准嘅人在線？操作會被拒絕。權限由你嘅伺服器執行，而唔係由一段提示詞。",
    link: "設定操作核准",
  },
  surfaces: {
    title: "書枱係一個地方。\n工作唔係。",
    description:
      "由桌面開始。喺瀏覽器入面睇一眼。用手機保持靠近。一部伺服器將事情攏埋一齊。",
    desktop: "原生桌面",
    web: "喺瀏覽器入面",
    phone: "手機伴侶",
    note: "資料同執行屬於你嘅伺服器。你嘅裝置保持同步。",
    link: "搵到你嘅平台",
  },
  faq: {
    title: "好問題。",
    description: "安頓落嚟之前，有幾件事值得知道。",
    items: [
      {
        question: "Control Center 係咪只畀 AI 代理用？",
        answer:
          "唔係。Control Center 將工單、Pull request、對話、會議、日曆、流水線、代理同個人 RSS 閱讀器放喺同一個工作區。代理係呢張書枱嘅一部分，唔係使用其他功能嘅前提。",
        links: [{ label: "了解功能", href: "/zh-HK/#features" }],
      },
      {
        question: "工單同對話有咩唔同？",
        answer:
          "工單記錄工作同佢嘅狀態；執行發生喺對話入面。對話可以喺代理執行前準備一棵隔離嘅寫入時複製 worktree。喺 Windows 上，呢次準備使用 Git worktree。",
        links: [{ label: "跟住一條範例工作流程", href: "/zh-HK/#workflows" }],
      },
      {
        question: "代理喺邊度執行，伺服器做咩？",
        answer:
          "伺服器擁有工作區資料庫、憑證、API 同代理執行；桌面同瀏覽器用戶端展示並控制呢啲工作。可選嘅機羣工作行程領取租約任務並串流傳回事件，但唔保存資料庫、憑證或者預算。",
        links: [
          { label: "閱讀架構指南", href: "/manual/concepts/architecture/" },
        ],
      },
      {
        question: "我對一次代理執行有幾多控制？",
        answer:
          "每個對話都可以使用僅提出建議、經核准後行動或者自由行動。權限同沙箱仍然限制允許嘅操作；冇核准人時，核准請求會被拒絕。軟預算上限會警告，硬上限會暫停，執行會留低記錄。",
        links: [{ label: "查看呢啲控制", href: "/zh-HK/#boundaries" }],
      },
      {
        question: "Orchestrate 計劃會唔會自動聘用代理？",
        answer:
          "唔會。Orchestrate 可以調查並提議角色、子工單同一份計劃，但聘用要等核准。Plan Studio 由發起對話入面嘅計劃列打開；只指派工單並唔會開始一次執行。",
        links: [{ label: "跟住範例工作流程", href: "/zh-HK/#workflows" }],
      },
      {
        question: "我可唔可以喺已配對嘅手機執行代理？",
        answer:
          "已配對嘅手機係同一套伺服器工作區嘅精簡用戶端，唔係第二部執行機器。桌面、瀏覽器同手機見到嘅係同一件事；代理喺伺服器上執行，或者喺可選嘅租約機羣工作行程上執行。",
        links: [{ label: "查看連埋一齊嘅介面", href: "/zh-HK/#surfaces" }],
      },
      {
        question: "我可以用邊啲整合？",
        answer:
          "Linear 工單同步已經實作；Jira 同 ClickUp 冇配接器。已連接嘅 Google 日曆事件係唯讀嘅，只有日曆授予寫入權限時先可以回覆邀請。Slack 討論串可以接到對話上，已連接嘅程式碼託管會提供 Pull request 同檢查。",
        links: [{ label: "閱讀手冊", href: "/manual/" }],
      },
      {
        question: "會議筆記同行動項目幾時出現？",
        answer:
          "即時轉寫可以喺錄音時區分發言人。你停止之後，摘要代理會處理呢次會議，並保存筆記、決定同行動項目；錄音同處理係兩種唔同嘅狀態。",
        links: [{ label: "喺脈絡入面睇呢一日", href: "/zh-HK/#day" }],
      },
      {
        question: "公開示範係咪真正嘅工作區？",
        answer:
          "公開示範係單獨嘅、受限嘅版本，使用編造嘅資料同按腳本行動嘅代理。入面嘅記錄同執行係例子，唔係你自己嘅工作。",
        links: [{ label: "睇下即場示範", href: "/demo" }],
      },
    ],
  },
  pilot: {
    controls:
      "三維滑翔傘。拖曳可環繞觀看及操控方向。左右方向鍵轉向；上下方向鍵令飛行姿態向上或向下傾斜。R 重設；空白鍵暫停或者恢復飛行同風。",
  },
  install: {
    title: "安頓\n落嚟。",
    description: "下一個開發日可以由呢度開始。免費，而且開源。",
    mac: "Apple Silicon · macOS 13+",
    windows: "x64 · ARM64 · Windows 10+",
    linux: "x86_64 · AppImage",
    release: "查看版本",
    web: "開啟網頁應用程式",
    phone: "開啟手機伴侶",
    webNote: "連線到你自己執行嘅伺服器。",
    phoneNote: "透過封閉嘅中繼將手機同伺服器配對。",
    selfHost: "想自己託管？",
    server: "執行無介面伺服器",
    guide: "閱讀快速入門",
  },
  footer: {
    tagline: "開發者一天的家。",
    resources: "資源",
    source: "GitHub 上的原始碼",
    compare: "比較",
    changelog: "變更記錄",
    about: "關於",
    contact: "聯絡",
    privacy: "私隱",
    terms: "條款",
    licenses: "授權",
    acknowledgements: "致謝",
    made: "喺公開中構建。",
    top: "回到頂端",
  },
};
