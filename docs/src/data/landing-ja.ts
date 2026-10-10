import type { LandingCopy } from "./landing-en";

export const ja: LandingCopy = {
  meta: {
    title: "Control Center \\\\ 開発者の一日の居場所",
    description:
      "チケット、コードレビュー、AIエージェント、ミーティング、パイプラインをひとつに。デスクトップ、ウェブ、電話で使える無料のオープンソース作業空間です。",
    imageAlt: "Control Center。開発の仕事をひとつの作業空間に。",
  },
  nav: {
    product: "製品",
    workflows: "ワークフロー",
    features: "機能",
    docs: "ドキュメント",
    demo: "デモを試す",
    download: "ダウンロード",
    menu: "メニュー",
    primary: "メインナビゲーション",
    mobile: "モバイルナビゲーション",
    home: "Control Center のホーム",
    skip: "本文へスキップ",
    language: "言語",
    appearance: "外観",
    light: "ライト",
    dark: "ダーク",
    system: "システム",
  },
  hero: {
    line1: "動くものは、たくさん。",
    line2: "Control Center は、ひとつ。",
    description:
      "コード、エージェント、レビュー、そして開発者の一日を形づくるすべてのための居場所です。",
    download: "Control Center を入手",
    demo: "ライブデモを見る",
    platforms: "macOS, Windows, Linux",
    web: "ウェブと電話にも対応",
  },
  media: {
    phone:
      "電話のコンパニオンが、同じ作業空間、保留中の承認、エージェント実行の状態を表示しています。",
  },
  tour: {
    label: "Control Center を見る",
    previous: "前の製品画面",
    next: "次の製品画面",
    play: "ツアーを再生",
    pause: "ツアーを一時停止",
    videoPlay: "プレビューを再生",
    videoPause: "プレビューを一時停止",
    expand: "プレビューを拡大",
    preview: "製品プレビュー",
    close: "プレビューを閉じる",
    note: "開発者の一日を、もう少し近くから。",
    imageLanguage: "画像または動画のプレースホルダー",
    stops: [
      {
        kind: "agents",
        label: "エージェント",
        title: "よい仕事が起きる場所を残す。",
        description:
          "エージェントは隔離された Git worktree で動きます。ツールを追い、仕事を導き、文脈を保ちます。",
        alt: "Control Center のエージェントとの会話。タスクの文脈と活動が見えます。",
      },
      {
        kind: "desk",
        label: "受信トレイ",
        title: "自分を必要としていることから。",
        description:
          "レビュー依頼、承認、妨げ。次の行動が、タブを探さずに見えます。",
        alt: "Control Center の受信トレイ。プルリクエストをレビュー状態でまとめ、同期の妨げを表示しています。",
      },
      {
        kind: "review",
        label: "コードレビュー",
        title: "変更を読む。経緯を知る。",
        description:
          "差分、議論、チェックは離れません。レビューは自分のアカウントで公開します。",
        alt: "Control Center のプルリクエストレビュー。コードの変更とレビューの文脈があります。",
      },
      {
        kind: "tickets",
        label: "チケット",
        title: "次の一歩を、つなぎたままに。",
        description:
          "優先度と担当を追い、Linear を同期し、仕事が起きる会話へつなぎます。",
        alt: "Control Center のチケットボード。タスクが状態ごとにまとまっています。",
      },
      {
        kind: "meetings",
        label: "ミーティング",
        title: "通話のあとにも、決定を残す。",
        description:
          "録音と文字起こしは自分のサーバーで。ミーティングが終わると、メモとアクションがあります。",
        alt: "Control Center のミーティング。文字起こしとミーティング情報があります。",
      },
      {
        kind: "pipelines",
        label: "パイプライン",
        title: "繰り返す仕事を、繰り返せるように。",
        description:
          "ワークフローを組み、きっかけを選び、実行の一歩ずつを追います。",
        alt: "Control Center のパイプライン。ワークフローの段階と実行状態が見えます。",
      },
    ],
  },
  integrations: {
    title: "すでに使っているツールを、連れてくる。",
    note: "つながるのは自分のサーバーです。一日のコピーを、もうひとつ増やしません。",
  },
  grid: {
    title: "毎日、手を伸ばすツール。",
    description: "仕事を進め、変わったところを見て、決定を残します。",
    more: "ドキュメントを読む",
    items: [
      {
        title: "並列エージェント",
        description:
          "タスクごとに隔離された Git worktree を渡します。実行を追い、エージェントを導き、ほかを乱さずに引き継げます。",
        link: "エージェントを並列で動かす",
        kind: "agents",
        href: "/manual/guides/parallel-agents/",
      },
      {
        title: "プルリクエストのレビュー",
        description:
          "差分を、議論とチェックのそばで読みます。役立つときは AI レビューを足し、自分の forge アカウントで公開します。",
        link: "プルリクエストをレビューする",
        kind: "review",
        href: "/manual/guides/review-merge-pr/",
      },
      {
        title: "つながったチケット",
        description:
          "Linear を同期し、優先度を決め、仕事を割り当てます。チケットを、仕上げる会話へつなぎます。",
        link: "チケットを扱う",
        kind: "tickets",
        href: "/manual/guides/manage-tickets/",
      },
      {
        title: "ミーティングのメモ",
        description:
          "録音と文字起こしは自分のサーバーで。通話が終わったあとも、決定とアクションが残ります。",
        link: "ミーティングを録音する",
        kind: "meetings",
        href: "/manual/guides/record-meeting/",
      },
      {
        title: "繰り返せるパイプライン",
        description:
          "ワークフローは一度組みます。スケジュール、イベント、手動のどれかで実行し、段階ごとに確認します。",
        link: "パイプラインを組む",
        kind: "pipelines",
        href: "/manual/guides/create-pipeline/",
      },
      {
        title: "アカウントの切り替え",
        description:
          "各エージェントが使えるアカウントを選び、実行の文脈を保ったまま切り替えます。",
        link: "モデルプロバイダーを管理する",
        kind: "accounts",
        href: "/manual/guides/adapters/",
        alt: "Control Center のアカウントプールエディター。エージェントが使えるアカウントを表示しています。",
      },
      {
        title: "利用枠",
        description:
          "次の実行を始める前に、プロバイダーの利用枠とリセット時刻を確認します。",
        link: "コストを管理する",
        kind: "quota",
        href: "/manual/guides/manage-costs/",
        alt: "Control Center の利用状況パネル。プロバイダーごとの利用枠とリセット時刻を表示しています。",
      },
      {
        title: "サウンドスケープと集中",
        description:
          "時間を決めて集中セッションを始め、通知を静かにし、流れるサウンドスケープを調整します。",
        link: "集中モードを使う",
        kind: "focus",
        href: "/manual/guides/focus-mode/",
        alt: "Control Center の集中タイマーとサウンドスケープの操作画面。",
      },
      {
        title: "実行状況の把握",
        description:
          "稼働中のエージェントを追い、ワークスペースの実行コスト、トークン使用量、遅延を確認します。",
        link: "エージェントの実行を確認する",
        kind: "observability",
        href: "/manual/guides/manage-costs/",
        alt: "Control Center の実行状況画面。稼働中のエージェントと実行の分析を表示しています。",
      },
      {
        title: "スキルとエージェントのエディター",
        description:
          "ワークスペースのスキルを編集し、エージェントごとのモデル、指示、権限を設定します。",
        link: "スキルを管理する",
        kind: "editors",
        href: "/manual/guides/manage-skills/",
        alt: "Control Center のスキルエディターとエージェント設定。",
      },
    ],
    supporting: [
      {
        title: "受信トレイはひとつ",
        description:
          "レビュー、承認、妨げがひとつの列に並びます。コマンドパレットで次のタスクへ移ります。",
        href: "/manual/guides/triage-inbox/",
      },
      {
        title: "電話から様子を見る",
        description: "机に戻らなくても、実行を追い、承認を扱えます。",
        href: "/manual/concepts/remote-control/",
      },
    ],
  },
  workflow: {
    title: "糸を手放さない。\n出荷するまで。",
    description: "仕事はツールのあいだを移ります。文脈も一緒に来るべきです。",
    label: "つながったワークフロー",
    steps: [
      {
        title: "チケットから始める。",
        text: "優先度を決め、担当を名づけ、会話をつなぎます。記録を持つのはチケットです。",
        kind: "tickets",
        label: "意図",
      },
      {
        title: "仕事に、自分の場所を渡す。",
        text: "計画を話し、隔離された worktree を用意し、エージェントを動かします。必要なら導き、引き継ぎます。",
        kind: "agents",
        label: "仕事",
      },
      {
        title: "結果をレビューへ運ぶ。",
        text: "変更を読み、議論を追い、forge アカウントで公開します。経緯はつながったままです。",
        kind: "review",
        label: "結果",
      },
    ],
  },
  boundaries: {
    title: "push は、実行の前に承認する。",
    description:
      "Git の push、プルリクエストの公開、そのほか守られた操作は承認の後ろに置きます。何かが変わる前に、エージェントがしようとしていることを見ます。",
    media:
      "Git push の承認依頼で止まったエージェントの実行。提案されたコマンド、作業ディレクトリ、承認と拒否の操作を見せます。",
    note: "承認する人がつながっていないときは、操作は拒否されます。権限を守るのはサーバーであり、プロンプトではありません。",
    link: "操作の承認を設定する",
  },
  surfaces: {
    title: "机は場所です。\n仕事は、違います。",
    description:
      "デスクトップで始め、ブラウザーから覗き、電話から近くにいます。ひとつのサーバーが、仕事をまとめています。",
    desktop: "ネイティブのデスクトップ",
    web: "ブラウザーで",
    phone: "電話のコンパニオン",
    note: "データと実行を持つのはサーバーです。端末は同期したままです。",
    link: "自分のプラットフォームを見つける",
  },
  faq: {
    title: "よい質問です。",
    description: "腰を据える前に、知っておきたいことがいくつかあります。",
    items: [
      {
        question: "Control Center は AI エージェント専用ですか？",
        answer:
          "いいえ。Control Center はチケット、プルリクエスト、会話、ミーティング、カレンダー、パイプライン、エージェント、個人用の RSS リーダーをひとつの作業空間に置きます。エージェントは机の一部であり、ほかを使うための前提ではありません。",
        links: [{ label: "機能を見る", href: "/ja-JP/#features" }],
      },
      {
        question: "チケットと会話はどう違いますか？",
        answer:
          "チケットは仕事とその状態を記録し、実行は会話の中で起きます。会話はエージェントの実行前に、隔離された copy-on-write の worktree を用意できます。Windows では、その用意に Git worktree を使います。",
        links: [{ label: "サンプルの流れを追う", href: "/ja-JP/#workflows" }],
      },
      {
        question: "エージェントはどこで動き、サーバーは何をしますか？",
        answer:
          "サーバーは作業空間のデータベース、資格情報、API、エージェントの実行を持ちます。デスクトップとブラウザーのクライアントは、その仕事を表示し、操作します。任意のフリートワーカーはリースされたジョブを取り、イベントを流しますが、データベースも資格情報も予算も持ちません。",
        links: [
          {
            label: "アーキテクチャガイドを読む",
            href: "/manual/concepts/architecture/",
          },
        ],
      },
      {
        question: "エージェントの実行を、どこまで制御できますか？",
        answer:
          "会話ごとに、提案のみ、承認後に実行、自由に実行を選べます。権限とサンドボックスは、許される操作をなおも限られます。承認する人がいなければ、承認依頼は拒否されます。予算の軟らかい上限は警告し、硬い上限は一時停止し、実行は記録を残します。",
        links: [{ label: "制御を見る", href: "/ja-JP/#boundaries" }],
      },
      {
        question: "Orchestrate の計画は、エージェントを自動で雇いますか？",
        answer:
          "いいえ。Orchestrate は役割、子チケット、計画を調べて提案できますが、採用は承認を待ちます。Plan Studio は、元の会話にある計画の行から開きます。チケットを割り当てただけでは実行は始まりません。",
        links: [{ label: "サンプルの流れを追う", href: "/ja-JP/#workflows" }],
      },
      {
        question: "ペアリングした電話からエージェントを動かせますか？",
        answer:
          "ペアリングした電話は、同じサーバー上の作業空間を見る薄いクライアントであり、実行用のもう一台ではありません。デスクトップ、ブラウザー、電話は同じ仕事を表示します。エージェントはサーバー、または任意のリースされたフリートワーカーで動きます。",
        links: [{ label: "つながった画面を見る", href: "/ja-JP/#surfaces" }],
      },
      {
        question: "どの連携を使えますか？",
        answer:
          "Linear のチケット同期は実装済みです。Jira と ClickUp にはアダプターがありません。接続した Google カレンダーの予定は読み取り専用で、出欠の返答はカレンダーが書き込みを許したときだけです。Slack のスレッドは会話へ橋を渡せ、接続した forge はプルリクエストとチェックを渡します。",
        links: [{ label: "マニュアルを読む", href: "/manual/" }],
      },
      {
        question: "ミーティングのメモとアクションはいつ出ますか？",
        answer:
          "ライブの文字起こしは、録音中に話者を分けられます。止めたあと、要約エージェントがミーティングを処理し、メモ、決定、アクションを保存します。録音と処理は別の状態です。",
        links: [{ label: "一日を文脈の中で見る", href: "/ja-JP/#day" }],
      },
      {
        question: "公開デモは、本物の作業空間ですか？",
        answer:
          "公開デモは別の制限されたビルドで、作られたデータと台本どおりのエージェントを使います。その記録と実行は例であり、自分の仕事ではありません。",
        links: [{ label: "ライブデモを見る", href: "/demo" }],
      },
    ],
  },
  pilot: {
    controls:
      "3D のパラグライダーです。ドラッグで視点を回し、進行方向を変えます。左右の矢印キーで旋回し、上下の矢印キーで機首を上または下に傾けます。R でリセットし、スペースで飛行と風を一時停止または再開します。",
  },
  install: {
    title: "腰を\n落ち着けて。",
    description:
      "次の開発者の一日は、ここから始められます。無料で、オープンソースです。",
    mac: "Apple Silicon · macOS 13+",
    windows: "x64 · ARM64 · Windows 10+",
    linux: "x86_64 · AppImage",
    release: "リリースを見る",
    web: "ウェブアプリを開く",
    phone: "電話のコンパニオンを開く",
    webNote: "自分で動かすサーバーへ接続します。",
    phoneNote: "閉じたリレー越しに、電話をサーバーとペアリングします。",
    selfHost: "自分でホストしますか？",
    server: "画面のないサーバーを動かす",
    guide: "クイックスタートを読む",
  },
  footer: {
    tagline: "開発者の一日の居場所。",
    resources: "リソース",
    source: "GitHub のソース",
    compare: "比較",
    changelog: "変更履歴",
    about: "概要",
    contact: "連絡先",
    privacy: "プライバシー",
    terms: "条項",
    licenses: "ライセンス",
    acknowledgements: "謝辞",
    made: "開いた場所で作っています。",
    top: "先頭へ戻る",
  },
};
