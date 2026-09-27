import type { LandingCopy } from "./landing-en";

export const zh: LandingCopy = {
  meta: {
    title: "Control Center \\\\ 开发者一天的家",
    description:
      "把工单、代码评审、AI 智能体、会议和流水线放在一起。面向桌面、网页和手机的免费开源工作区。",
    imageAlt: "Control Center，把开发工作放进同一个工作区。",
  },
  nav: {
    product: "产品",
    workflows: "工作流",
    features: "功能",
    docs: "文档",
    demo: "试用演示",
    download: "下载",
    menu: "菜单",
    primary: "主导航",
    mobile: "移动导航",
    home: "Control Center 首页",
    skip: "跳到正文",
    language: "语言",
    appearance: "外观",
    light: "浅色",
    dark: "深色",
    system: "系统",
  },
  hero: {
    line1: "有很多在动的部分。",
    line2: "只有一个 Control Center。",
    description:
      "代码、智能体、评审，以及组成开发者一天的其他事情，都有一个家。",
    download: "获取 Control Center",
    demo: "看看实况演示",
    platforms: "macOS, Windows, Linux",
    web: "网页和手机上也有",
  },
  media: {
    phone:
      "手机伴侣显示同一个工作区、一条待处理的批准，以及一次智能体运行的状态。",
  },
  tour: {
    label: "了解 Control Center",
    previous: "上一个产品视图",
    next: "下一个产品视图",
    play: "播放导览",
    pause: "暂停导览",
    expand: "放大预览",
    close: "关闭预览",
    preview: "产品预览",
    note: "把开发者的一天再看近一些。",
    imageLanguage: "图像或视频占位",
    stops: [
      {
        kind: "desk",
        label: "你的一天",
        title: "从需要你的事情开始。",
        description: "评审请求、批准和阻塞。下一步就在这里，不用在标签页里找。",
        alt: "Control Center 收件箱按评审状态归组 Pull request，并显示一处同步阻塞。",
      },
      {
        kind: "agents",
        label: "智能体",
        title: "给好工作留出发生的地方。",
        description:
          "在隔离的 Git worktree 里运行智能体。跟上它们的工具，引导工作，并保留上下文。",
        alt: "Control Center 里与智能体的对话，能看到任务上下文和活动。",
      },
      {
        kind: "review",
        label: "代码评审",
        title: "读改动。知道来龙去脉。",
        description: "差异、讨论和检查留在一起。用你自己的账号发布评审。",
        alt: "Control Center 的 Pull request 评审，包含代码改动和评审上下文。",
      },
      {
        kind: "tickets",
        label: "工单",
        title: "让下一步保持相连。",
        description:
          "跟踪优先级和负责人，同步 Linear，并连上工作真正发生的对话。",
        alt: "Control Center 工单板按状态归组任务。",
      },
      {
        kind: "meetings",
        label: "会议",
        title: "通话结束后，决定还在。",
        description:
          "在你自己的服务器上录音和转写。会议结束时，你有笔记和行动项。",
        alt: "Control Center 中的会议，包含转写和会议信息。",
      },
      {
        kind: "pipelines",
        label: "流水线",
        title: "让重复的工作可以重复。",
        description: "搭一条工作流，选定触发方式，并跟上运行的每一步。",
        alt: "Control Center 的流水线视图，包含工作流步骤和运行状态。",
      },
    ],
  },
  integrations: {
    title: "带上你已经在用的工具。",
    note: "通过你的服务器连接，而不是再复制一份你的一天。",
  },
  grid: {
    title: "每天都会伸手去拿的工具。",
    description: "把工作做完，看清改了什么，并把决定留下来。",
    more: "阅读文档",
    items: [
      {
        title: "并行智能体",
        description:
          "给每项任务一个隔离的 Git worktree。跟上运行，引导智能体，或在不打扰其余工作的情况下接手。",
        link: "并行运行智能体",
        kind: "agents",
        href: "/manual/guides/parallel-agents/",
      },
      {
        title: "Pull request 评审",
        description:
          "差异旁边就是讨论和检查。需要时加上 AI 评审，再用你自己的代码托管账号发布。",
        link: "评审 Pull request",
        kind: "review",
        href: "/manual/guides/review-merge-pr/",
      },
      {
        title: "连在一起的工单",
        description:
          "同步 Linear，设定优先级，并分派工作。把工单连到完成它的那次对话。",
        link: "管理工单",
        kind: "tickets",
        href: "/manual/guides/manage-tickets/",
      },
      {
        title: "会议笔记",
        description:
          "在你自己的服务器上录音和转写。通话结束后，决定和行动项还在。",
        link: "录制会议",
        kind: "meetings",
        href: "/manual/guides/record-meeting/",
      },
      {
        title: "可以重复的流水线",
        description: "工作流搭一次。按日程、由事件或手动运行，并检查每一步。",
        link: "搭建流水线",
        kind: "pipelines",
        href: "/manual/guides/create-pipeline/",
      },
      {
        title: "切换账户",
        description: "选好每个智能体可用的账户，再按需切换，运行上下文始终保留。",
        link: "管理模型服务商",
        kind: "accounts",
        href: "/manual/guides/adapters/",
        alt: "Control Center 账户池编辑器，显示智能体可用的账户。",
      },
      {
        title: "使用配额",
        description: "开始下一次运行前，查看服务商的可用额度和重置时间。",
        link: "管理费用",
        kind: "quota",
        href: "/manual/guides/manage-costs/",
        alt: "Control Center 使用情况面板，显示服务商配额及重置时间。",
      },
      {
        title: "氛围音与专注",
        description: "开启定时专注，静音通知，并调整背景中播放的氛围音。",
        link: "使用专注模式",
        kind: "focus",
        href: "/manual/guides/focus-mode/",
        alt: "Control Center 专注计时器和氛围音控制界面。",
      },
      {
        title: "运行监测",
        description: "实时跟踪智能体，查看工作区中每次运行的费用、令牌用量和延迟。",
        link: "查看智能体运行",
        kind: "observability",
        href: "/manual/guides/manage-costs/",
        alt: "Control Center 运行监测视图，显示实时运行的智能体和运行分析。",
      },
      {
        title: "技能与智能体编辑器",
        description: "编辑工作区技能，配置每个智能体的模型、指令和权限。",
        link: "管理技能",
        kind: "editors",
        href: "/manual/guides/manage-skills/",
        alt: "Control Center 技能编辑器和智能体设置界面。",
      },
    ],
    supporting: [
      {
        title: "一个收件箱",
        description:
          "评审、批准和阻塞排在同一条队列里。用命令面板跳到下一项任务。",
        href: "/manual/guides/triage-inbox/",
      },
      {
        title: "用手机看一眼",
        description: "不用回到书桌，也能跟上运行并处理批准。",
        href: "/manual/concepts/remote-control/",
      },
    ],
  },
  workflow: {
    title: "抓住这条线。\n一直到交付。",
    description: "工作会在工具之间移动。上下文应该跟着走。",
    label: "连在一起的工作流",
    steps: [
      {
        title: "从工单开始。",
        text: "设定优先级，写下负责人，并连上对话。记录留在工单里。",
        kind: "tickets",
        label: "意图",
      },
      {
        title: "给工作一个自己的地方。",
        text: "讨论计划，准备隔离的 worktree，并运行智能体。需要时引导，或接手。",
        kind: "agents",
        label: "工作",
      },
      {
        title: "把结果带进评审。",
        text: "读改动，跟上讨论，并用你的代码托管账号发布。故事仍然连着。",
        kind: "review",
        label: "结果",
      },
    ],
  },
  boundaries: {
    title: "先批准 push，再让它执行。",
    description:
      "把 Git push、发布 Pull request 和其他受保护的操作放在批准后面。在任何东西改变之前，先看智能体准备做什么。",
    media:
      "一次智能体运行停在 Git push 的批准请求上。展示建议的命令、工作目录，以及批准或拒绝的控件。",
    note: "没有批准的人在线？操作会被拒绝。权限由你的服务器执行，而不是由一段提示词。",
    link: "配置操作批准",
  },
  surfaces: {
    title: "书桌是一个地方。\n工作不是。",
    description:
      "从桌面开始。在浏览器里看一眼。用手机保持靠近。一台服务器把事情拢在一起。",
    desktop: "原生桌面",
    web: "在浏览器里",
    phone: "手机伴侣",
    note: "数据和执行属于你的服务器。你的设备保持同步。",
    link: "找到你的平台",
  },
  faq: {
    title: "好问题。",
    description: "安顿下来之前，有几件事值得知道。",
    items: [
      {
        question: "Control Center 只给 AI 智能体用吗？",
        answer:
          "不是。Control Center 把工单、Pull request、对话、会议、日历、流水线、智能体和个人 RSS 阅读器放在同一个工作区。智能体是这张书桌的一部分，不是使用其他功能的前提。",
        links: [{ label: "了解功能", href: "/zh-CN/#features" }],
      },
      {
        question: "工单和对话有什么不同？",
        answer:
          "工单记录工作及其状态；执行发生在对话里。对话可以在智能体运行前准备一棵隔离的写时复制 worktree。在 Windows 上，这次准备使用 Git worktree。",
        links: [{ label: "顺着一条示例工作流", href: "/zh-CN/#workflows" }],
      },
      {
        question: "智能体在哪里运行，服务器做什么？",
        answer:
          "服务器拥有工作区数据库、凭据、API 和智能体执行；桌面和浏览器客户端展示并控制这些工作。可选的舰队工作进程领取租约任务并流式传回事件，但不保存数据库、凭据或预算。",
        links: [
          { label: "阅读架构指南", href: "/manual/concepts/architecture/" },
        ],
      },
      {
        question: "我对一次智能体运行有多少控制？",
        answer:
          "每个对话都可以使用仅提议、批准后行动或自由行动。权限和沙箱仍然限制允许的操作；没有批准人时，批准请求会被拒绝。软预算上限会警告，硬上限会暂停，运行会留下记录。",
        links: [{ label: "查看这些控制", href: "/zh-CN/#boundaries" }],
      },
      {
        question: "Orchestrate 计划会自动聘用智能体吗？",
        answer:
          "不会。Orchestrate 可以调研并提议角色、子工单和一份计划，但聘用要等批准。Plan Studio 从发起对话里的计划行打开；只分配工单并不会开始一次运行。",
        links: [{ label: "顺着示例工作流", href: "/zh-CN/#workflows" }],
      },
      {
        question: "我能从已配对的手机运行智能体吗？",
        answer:
          "已配对的手机是同一套服务器工作区的瘦客户端，不是第二台执行机器。桌面、浏览器和手机看到的是同一件事；智能体在服务器上执行，或在可选的租约舰队工作进程上执行。",
        links: [{ label: "查看连在一起的界面", href: "/zh-CN/#surfaces" }],
      },
      {
        question: "我能用哪些集成？",
        answer:
          "Linear 工单同步已经实现；Jira 和 ClickUp 没有适配器。已连接的 Google 日历事件是只读的，只有日历授予写入权限时才能回复邀请。Slack 话题可以接到对话上，已连接的代码托管会提供 Pull request 和检查。",
        links: [{ label: "阅读手册", href: "/manual/" }],
      },
      {
        question: "会议笔记和行动项什么时候出现？",
        answer:
          "实时转写可以在录音时区分发言人。你停止之后，摘要智能体会处理这次会议，并保存笔记、决定和行动项；录音和处理是两种不同的状态。",
        links: [{ label: "在上下文里看这一天", href: "/zh-CN/#day" }],
      },
      {
        question: "公开演示是真正的工作区吗？",
        answer:
          "公开演示是单独的、受限的版本，使用编造的数据和按脚本行动的智能体。里面的记录和运行是例子，不是你自己的工作。",
        links: [{ label: "看看实况演示", href: "/demo" }],
      },
    ],
  },
  pilot: {
    controls:
      "三维滑翔伞。拖动可环绕查看并控制方向。左右方向键转向；上下方向键使飞行姿态向上或向下倾斜。R 重置；空格暂停或恢复飞行与风。",
  },
  install: {
    title: "安顿\n下来。",
    description: "下一个开发日可以从这里开始。免费，并且开源。",
    mac: "Apple Silicon · macOS 13+",
    windows: "x64 · Windows 10+",
    linux: "x86_64 · AppImage",
    release: "查看版本",
    web: "打开网页应用",
    phone: "打开手机伴侣",
    webNote: "连接到你自己运行的服务器。",
    phoneNote: "通过封闭的中继把手机和服务器配对。",
    selfHost: "想自己托管？",
    server: "运行无界面服务器",
    guide: "阅读快速入门",
  },
  footer: {
    tagline: "开发者一天的家。",
    resources: "资源",
    source: "GitHub 上的源码",
    compare: "比较",
    changelog: "变更记录",
    about: "关于",
    contact: "联系",
    privacy: "隐私",
    terms: "条款",
    licenses: "许可",
    acknowledgements: "致谢",
    made: "在公开中构建。",
    top: "回到顶部",
  },
};
