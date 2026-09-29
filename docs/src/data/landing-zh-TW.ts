import type { LandingCopy } from "./landing-en";

export const zhTw: LandingCopy = {
  meta: {
    title: "Control Center \\\\ 開發者一天的家",
    description:
      "把工單、程式碼審查、AI 代理、會議和流水線放在一起。給桌面、網頁和手機用的免費開源工作區。",
    imageAlt: "Control Center，把開發工作放進同一個工作區。",
  },
  nav: {
    product: "產品",
    workflows: "工作流程",
    features: "功能",
    docs: "文件",
    demo: "試用展示",
    download: "下載",
    menu: "選單",
    primary: "主要導覽",
    mobile: "行動導覽",
    home: "Control Center 首頁",
    skip: "跳到本文",
    language: "語言",
    appearance: "外觀",
    light: "淺色",
    dark: "深色",
    system: "系統",
  },
  hero: {
    line1: "有很多在動的部分。",
    line2: "只有一個 Control Center。",
    description:
      "程式碼、代理、審查，以及組成開發者一天的其他事情，都有一個家。",
    download: "取得 Control Center",
    demo: "看看即時展示",
    platforms: "macOS, Windows, Linux",
    web: "網頁和手機上也有",
  },
  media: {
    phone:
      "手機伴侶顯示同一個工作區、一項待處理的核准，以及一次代理執行的狀態。",
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
    note: "把開發者的一天再看近一些。",
    imageLanguage: "影像或影片佔位",
    stops: [
      {
        kind: "desk",
        label: "你的一天",
        title: "從需要你的事情開始。",
        description: "審查請求、核准和阻塞。下一步就在這裡，不用在分頁裡找。",
        alt: "Control Center 收件匣依審查狀態歸組 Pull request，並顯示一處同步阻塞。",
      },
      {
        kind: "agents",
        label: "代理",
        title: "給好工作留出發生的地方。",
        description:
          "在隔離的 Git worktree 裡執行代理。跟上它們的工具，引導工作，並保留脈絡。",
        alt: "Control Center 裡與代理的對話，能看到任務脈絡和活動。",
      },
      {
        kind: "review",
        label: "程式碼審查",
        title: "讀改動。知道來龍去脈。",
        description: "差異、討論和檢查留在一起。用你自己的帳號發布審查。",
        alt: "Control Center 的 Pull request 審查，包含程式碼改動和審查脈絡。",
      },
      {
        kind: "tickets",
        label: "工單",
        title: "讓下一步保持相連。",
        description:
          "追蹤優先順序和負責人，同步 Linear，並連上工作真正發生的對話。",
        alt: "Control Center 工單板依狀態歸組任務。",
      },
      {
        kind: "meetings",
        label: "會議",
        title: "通話結束後，決定還在。",
        description:
          "在你自己的伺服器上錄音和轉寫。會議結束時，你有筆記和行動項目。",
        alt: "Control Center 中的會議，包含轉寫和會議資訊。",
      },
      {
        kind: "pipelines",
        label: "流水線",
        title: "讓重複的工作可以重複。",
        description: "搭一條工作流程，選定觸發方式，並跟上執行的每一步。",
        alt: "Control Center 的流水線檢視，包含工作流程步驟和執行狀態。",
      },
    ],
  },
  integrations: {
    title: "帶上你已經在用的工具。",
    note: "透過你的伺服器連接，而不是再複製一份你的一天。",
  },
  grid: {
    title: "每天都會伸手去拿的工具。",
    description: "把工作做完，看清改了什麼，並把決定留下來。",
    more: "閱讀文件",
    items: [
      {
        title: "平行代理",
        description:
          "給每項任務一個隔離的 Git worktree。跟上執行，引導代理，或在不打擾其餘工作的情況下接手。",
        link: "平行執行代理",
        kind: "agents",
        href: "/manual/guides/parallel-agents/",
      },
      {
        title: "Pull request 審查",
        description:
          "差異旁邊就是討論和檢查。需要時加上 AI 審查，再用你自己的程式碼代管帳號發布。",
        link: "審查 Pull request",
        kind: "review",
        href: "/manual/guides/review-merge-pr/",
      },
      {
        title: "連在一起的工單",
        description:
          "同步 Linear，設定優先順序，並分派工作。把工單連到完成它的那次對話。",
        link: "管理工單",
        kind: "tickets",
        href: "/manual/guides/manage-tickets/",
      },
      {
        title: "會議筆記",
        description:
          "在你自己的伺服器上錄音和轉寫。通話結束後，決定和行動項目還在。",
        link: "錄製會議",
        kind: "meetings",
        href: "/manual/guides/record-meeting/",
      },
      {
        title: "可以重複的流水線",
        description: "工作流程搭一次。依排程、由事件或手動執行，並檢查每一步。",
        link: "搭建流水線",
        kind: "pipelines",
        href: "/manual/guides/create-pipeline/",
      },
      {
        title: "切換帳戶",
        description: "選好每個代理可用的帳戶，再依需求切換，執行時的脈絡也不會中斷。",
        link: "管理模型供應商",
        kind: "accounts",
        href: "/manual/guides/adapters/",
        alt: "Control Center 帳戶集區編輯器，顯示代理可使用的帳戶。",
      },
      {
        title: "使用配額",
        description: "開始下一次執行前，查看供應商的可用額度與重設時間。",
        link: "管理費用",
        kind: "quota",
        href: "/manual/guides/manage-costs/",
        alt: "Control Center 使用情況面板，顯示供應商配額與重設時間。",
      },
      {
        title: "環境音與專注",
        description: "開始計時專注時段、將通知靜音，並調整背景播放的環境音。",
        link: "使用專注模式",
        kind: "focus",
        href: "/manual/guides/focus-mode/",
        alt: "Control Center 專注計時器與環境音控制介面。",
      },
      {
        title: "執行監測",
        description: "即時追蹤代理，查看工作空間中每次執行的費用、Token 用量與延遲。",
        link: "查看代理執行紀錄",
        kind: "observability",
        href: "/manual/guides/manage-costs/",
        alt: "Control Center 執行監測檢視，顯示即時運作的代理與執行分析。",
      },
      {
        title: "技能與代理編輯器",
        description: "編輯工作空間技能，設定每個代理的模型、指令與權限。",
        link: "管理技能",
        kind: "editors",
        href: "/manual/guides/manage-skills/",
        alt: "Control Center 技能編輯器與代理設定介面。",
      },
    ],
    supporting: [
      {
        title: "一個收件匣",
        description:
          "審查、核准和阻塞排在同一條佇列裡。用命令面板跳到下一項任務。",
        href: "/manual/guides/triage-inbox/",
      },
      {
        title: "用手機看一眼",
        description: "不用回到書桌，也能跟上執行並處理核准。",
        href: "/manual/concepts/remote-control/",
      },
    ],
  },
  workflow: {
    title: "抓住這條線。\n一直到交付。",
    description: "工作會在工具之間移動。脈絡應該跟著走。",
    label: "連在一起的工作流程",
    steps: [
      {
        title: "從工單開始。",
        text: "設定優先順序，寫下負責人，並連上對話。記錄留在工單裡。",
        kind: "tickets",
        label: "意圖",
      },
      {
        title: "給工作一個自己的地方。",
        text: "討論計畫，準備隔離的 worktree，並執行代理。需要時引導，或接手。",
        kind: "agents",
        label: "工作",
      },
      {
        title: "把結果帶進審查。",
        text: "讀改動，跟上討論，並用你的程式碼代管帳號發布。故事仍然連著。",
        kind: "review",
        label: "結果",
      },
    ],
  },
  boundaries: {
    title: "先核准 push，再讓它執行。",
    description:
      "把 Git push、發布 Pull request 和其他受保護的操作放在核准後面。在任何東西改變之前，先看代理準備做什麼。",
    media:
      "一次代理執行停在 Git push 的核准請求上。展示建議的命令、工作目錄，以及核准或拒絕的控制項。",
    note: "沒有核准的人在線？操作會被拒絕。權限由你的伺服器執行，而不是由一段提示詞。",
    link: "設定操作核准",
  },
  surfaces: {
    title: "書桌是一個地方。\n工作不是。",
    description:
      "從桌面開始。在瀏覽器裡看一眼。用手機保持靠近。一台伺服器把事情攏在一起。",
    desktop: "原生桌面",
    web: "在瀏覽器裡",
    phone: "手機伴侶",
    note: "資料和執行屬於你的伺服器。你的裝置保持同步。",
    link: "找到你的平台",
  },
  faq: {
    title: "好問題。",
    description: "安頓下來之前，有幾件事值得知道。",
    items: [
      {
        question: "Control Center 只給 AI 代理用嗎？",
        answer:
          "不是。Control Center 把工單、Pull request、對話、會議、行事曆、流水線、代理和個人 RSS 閱讀器放在同一個工作區。代理是這張書桌的一部分，不是使用其他功能的前提。",
        links: [{ label: "了解功能", href: "/zh-TW/#features" }],
      },
      {
        question: "工單和對話有什麼不同？",
        answer:
          "工單記錄工作及其狀態；執行發生在對話裡。對話可以在代理執行前準備一棵隔離的寫入時複製 worktree。在 Windows 上，這次準備使用 Git worktree。",
        links: [{ label: "順著一條範例工作流程", href: "/zh-TW/#workflows" }],
      },
      {
        question: "代理在哪裡執行，伺服器做什麼？",
        answer:
          "伺服器擁有工作區資料庫、認證、API 和代理執行；桌面和瀏覽器用戶端展示並控制這些工作。可選的機群工作行程領取租約任務並串流傳回事件，但不保存資料庫、認證或預算。",
        links: [
          { label: "閱讀架構指南", href: "/manual/concepts/architecture/" },
        ],
      },
      {
        question: "我對一次代理執行有多少控制？",
        answer:
          "每個對話都可以使用僅提出建議、經核准後行動或自由行動。權限和沙箱仍然限制允許的操作；沒有核准人時，核准請求會被拒絕。軟預算上限會警告，硬上限會暫停，執行會留下記錄。",
        links: [{ label: "查看這些控制", href: "/zh-TW/#boundaries" }],
      },
      {
        question: "Orchestrate 計畫會自動聘用代理嗎？",
        answer:
          "不會。Orchestrate 可以調查並提議角色、子工單和一份計畫，但聘用要等核准。Plan Studio 從發起對話裡的計畫列打開；只指派工單並不會開始一次執行。",
        links: [{ label: "順著範例工作流程", href: "/zh-TW/#workflows" }],
      },
      {
        question: "我能從已配對的手機執行代理嗎？",
        answer:
          "已配對的手機是同一套伺服器工作區的精簡用戶端，不是第二台執行機器。桌面、瀏覽器和手機看到的是同一件事；代理在伺服器上執行，或在可選的租約機群工作行程上執行。",
        links: [{ label: "查看連在一起的介面", href: "/zh-TW/#surfaces" }],
      },
      {
        question: "我能用哪些整合？",
        answer:
          "Linear 工單同步已經實作；Jira 和 ClickUp 沒有配接器。已連接的 Google 日曆事件是唯讀的，只有日曆授予寫入權限時才能回覆邀請。Slack 討論串可以接到對話上，已連接的程式碼代管會提供 Pull request 和檢查。",
        links: [{ label: "閱讀手冊", href: "/manual/" }],
      },
      {
        question: "會議筆記和行動項目什麼時候出現？",
        answer:
          "即時轉寫可以在錄音時區分發言人。你停止之後，摘要代理會處理這次會議，並保存筆記、決定和行動項目；錄音和處理是兩種不同的狀態。",
        links: [{ label: "在脈絡裡看這一天", href: "/zh-TW/#day" }],
      },
      {
        question: "公開展示是真正的工作區嗎？",
        answer:
          "公開展示是單獨的、受限的版本，使用編造的資料和按腳本行動的代理。裡面的記錄和執行是例子，不是你自己的工作。",
        links: [{ label: "看看即時展示", href: "/demo" }],
      },
    ],
  },
  pilot: {
    controls:
      "三維滑翔傘。拖曳可環繞觀看並操控方向。左右方向鍵轉向；上下方向鍵讓飛行姿態向上或向下傾斜。R 重設；空白鍵暫停或恢復飛行與風。",
  },
  install: {
    title: "安頓\n下來。",
    description: "下一個開發日可以從這裡開始。免費，並且開源。",
    mac: "Apple Silicon · macOS 13+",
    windows: "x64 · Windows 10+",
    linux: "x86_64 · AppImage",
    release: "查看版本",
    web: "開啟網頁應用程式",
    phone: "開啟手機伴侶",
    webNote: "連線到你自己執行的伺服器。",
    phoneNote: "透過封閉的中繼把手機和伺服器配對。",
    selfHost: "想自己代管？",
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
    privacy: "隱私",
    terms: "條款",
    licenses: "授權",
    acknowledgements: "致謝",
    made: "在公開中建構。",
    top: "回到頂端",
  },
};
