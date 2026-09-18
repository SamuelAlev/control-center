// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => '戻る';

  @override
  String get cancel => 'キャンセル';

  @override
  String get retry => '再試行';

  @override
  String get tryAgain => 'もう一度試す';

  @override
  String get settings => '設定';

  @override
  String get refresh => '更新';

  @override
  String get approve => '承認';

  @override
  String get deny => '拒否';

  @override
  String get continueLabel => '続ける';

  @override
  String get agentQuestionHeader => '質問があります';

  @override
  String get agentQuestionAnsweredLabel => '回答済み';

  @override
  String get agentQuestionSkip => 'スキップ';

  @override
  String get agentQuestionSkippedLabel => 'スキップ済み';

  @override
  String get agentQuestionFreeformHint => '回答を入力…';

  @override
  String get agentApprovalRequired => '承認が必要です';

  @override
  String get approveAndRemember => '8時間承認する';

  @override
  String get decline => '拒否';

  @override
  String get confirm => '確認';

  @override
  String get send => '送信';

  @override
  String get close => '閉じる';

  @override
  String get expand => '展開';

  @override
  String get zoomIn => '拡大';

  @override
  String get zoomOut => '縮小';

  @override
  String get resetZoom => 'ズームをリセット';

  @override
  String get scanQrPrompt => 'このスマートフォンをペアリングするには、MacのQRコードをスキャンしてください。';

  @override
  String get scanQrHelp =>
      'カメラを開いて、MacのControl Centerに表示されたQRに向けてください。このスマートフォンは非公開のリンクでMacに直接接続します。';

  @override
  String get connectingToMac => 'Macに接続しています…';

  @override
  String get connectingDetail => '安全な直接リンクを確立しています。';

  @override
  String get identityChangedTitle => 'サーバーの識別情報が変わりました';

  @override
  String get identityChangedBody =>
      'このサーバーは、ペアリング時に保存された識別情報と一致しなくなりました。サーバーが再インストールされたか、接続が傍受されている可能性があります。安全のため、このデバイスは接続しません。ペアリングを削除してから、Macの新しいQRコードをスキャンして再度ペアリングしてください。';

  @override
  String get removePairing => 'ペアリングを削除';

  @override
  String get couldntConnect => '接続できませんでした';

  @override
  String get pendingPairingTitle => 'このサーバーに接続しますか？';

  @override
  String get pendingPairingBody =>
      'リンクがControl Centerにこのサーバーとのペアリングを要求しました。ご自身で開始した場合のみ続行してください。';

  @override
  String get connect => '接続';

  @override
  String get failureNotPaired => '未ペアリング — MacのQRコードをスキャンしてください';

  @override
  String get failureUnreachable =>
      'どの経路でもサーバーに到達できませんでした — 起動しているか確認するか、同じネットワークで試してください';

  @override
  String get failureIdentityChanged =>
      'サーバーの識別情報が変わりました — 再インストールした場合は、このデバイスを再ペアリングしてください';

  @override
  String get failureAuthRejected => 'サーバーがこのデバイスを拒否しました — Macから再ペアリングしてください';

  @override
  String get failureUnknown => '接続できませんでした — タップして再試行';

  @override
  String get statusConnected => '接続済み';

  @override
  String get statusConnecting => '接続中';

  @override
  String get statusOffline => 'オフライン';

  @override
  String get statusIdentityMismatch => '識別情報の不一致';

  @override
  String get statusNotPaired => '未ペアリング';

  @override
  String get statusConfirmPairing => 'ペアリングの確認';

  @override
  String get connectionFailed => '接続に失敗しました';

  @override
  String get identityMismatchBanner =>
      'サーバーの識別情報が変わりました — 接続を停止しました。続行するにはこのデバイスを再ペアリングしてください。';

  @override
  String get tabInbox => '受信トレイ';

  @override
  String get tabTickets => 'チケット';

  @override
  String get tabChat => 'チャット';

  @override
  String get tabPrs => 'PRs';

  @override
  String get tabCalendar => 'カレンダー';

  @override
  String get tabNews => 'ニュース';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label、$count件待機中';
  }

  @override
  String get updateAvailable => '新しいControl Centerが利用できます';

  @override
  String get appearance => '外観';

  @override
  String get language => '言語';

  @override
  String get device => 'デバイス';

  @override
  String get themeSystem => 'システム';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get languageSystem => 'システム';

  @override
  String get disconnectTapAgain => 'もう一度タップすると、このデバイスをMacから切断します';

  @override
  String get disconnectDevice => 'このデバイスを切断';

  @override
  String get disconnect => '切断';

  @override
  String get chooseWorkspace => 'ワークスペースを選択';

  @override
  String get workspaces => 'ワークスペース';

  @override
  String get workspacesLoadFailed => 'ワークスペースを読み込めませんでした';

  @override
  String get noWorkspacesYet => 'ワークスペースはまだありません';

  @override
  String selectWorkspace(String name) {
    return '$nameを選択';
  }

  @override
  String get inboxLoadFailed => '受信トレイを読み込めませんでした';

  @override
  String get allCaughtUp => 'すべて確認済みです';

  @override
  String get inboxNoForgeAccount =>
      'サーバーにforgeアカウントが接続されていないため、プルリクエストをまだあなたに紐づけられません。';

  @override
  String get inboxNothingWaiting => 'ブロックされているものはなく、あなた待ちのプルリクエストもありません。';

  @override
  String get blocked => 'ブロック中';

  @override
  String get sectionNeedsYourReview => 'レビューが必要';

  @override
  String get sectionReturnedToYou => 'あなたに差し戻し';

  @override
  String get sectionApprovedAndReady => '承認済みで準備完了';

  @override
  String get sectionYourDrafts => '自分の下書き';

  @override
  String get sectionWaitingForReviewers => 'レビュアー待ち';

  @override
  String get sectionMergingAndMerged => 'マージ中および最近マージ済み';

  @override
  String get sectionWaitingForAuthor => '作成者待ち';

  @override
  String waitingAgo(String ago) {
    return '$ago待機中';
  }

  @override
  String get openConversation => '会話を開く';

  @override
  String get calendarLoadFailed => 'カレンダーを読み込めませんでした';

  @override
  String get nothingScheduled => '予定はありません';

  @override
  String get calendarEmptyDescription => '接続したカレンダーの予定がここに表示されます。';

  @override
  String get agenda => '予定表';

  @override
  String get syncCalendarsNow => 'カレンダーを今すぐ同期';

  @override
  String get event => '予定';

  @override
  String get eventNotFound => '予定が見つかりません';

  @override
  String get eventNotFoundDescription => '予定表の期間外か、元のカレンダーで削除された可能性があります。';

  @override
  String get joinMeeting => '会議に参加';

  @override
  String get join => '参加';

  @override
  String attendeesCount(int count) {
    return '参加者（$count）';
  }

  @override
  String get details => '詳細';

  @override
  String get allDay => '終日';

  @override
  String get happeningNow => '開催中';

  @override
  String inDuration(String duration) {
    return '$duration後';
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
  String get attendeeAccepted => '参加';

  @override
  String get attendeeDeclined => '不参加';

  @override
  String get attendeeMaybe => '未定';

  @override
  String get attendeeNoReply => '未返信';

  @override
  String get organizer => '主催者';

  @override
  String get calendarNoAccounts =>
      'このワークスペースにカレンダーは接続されていません。デスクトップアプリから接続してください。サインインするとトークンがサーバーに保存されます。';

  @override
  String get calendarReauthNeeded =>
      'カレンダーアカウントの再接続が必要です — 以下の表示は最新でない可能性があります。デスクトップアプリから再接続してください。';

  @override
  String get spacesLoadFailed => 'スペースを読み込めませんでした';

  @override
  String get noSpaces => 'スペースはありません';

  @override
  String get spacesEmptyDescription => 'このワークスペースのスペースがここに表示されます。';

  @override
  String get thread => 'スレッド';

  @override
  String get agentWorking => 'エージェントが作業中です';

  @override
  String get messagesLoadFailed => 'メッセージを読み込めませんでした';

  @override
  String get noMessagesYet => 'メッセージはまだありません';

  @override
  String get noMessagesDescription => 'メッセージを送信して会話を始めてください。';

  @override
  String get agentResponding => 'エージェントが応答中';

  @override
  String get agentFinished => 'エージェントが完了しました';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$namesはここから送信するには大きすぎます。',
      one: '$namesはここから送信するには大きすぎます。',
    );
    return '$_temp0';
  }

  @override
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$namesはサイズが大きく、ここからリレー経由では送信できません。',
      one: '$namesはサイズが大きく、ここからリレー経由では送信できません。',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed => '添付ファイルをアップロードできませんでした。もう一度お試しください。';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の添付ファイルをアップロードできず、送信から除外しました。',
      one: '1件の添付ファイルをアップロードできず、送信から除外しました。',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'チームメイト';

  @override
  String get agent => 'エージェント';

  @override
  String get attachFile => 'ファイルを添付';

  @override
  String get messageHint => 'メッセージ';

  @override
  String removeAttachment(String name) {
    return '$nameを削除';
  }

  @override
  String get articlesLoadFailed => '記事を読み込めませんでした';

  @override
  String get noArticles => '記事はありません';

  @override
  String get articlesEmptyDescription => 'フィードが更新されると、新しい記事がここに表示されます。';

  @override
  String get unread => '未読';

  @override
  String get allFeeds => 'すべてのフィード';

  @override
  String get save => '保存';

  @override
  String get unsave => '保存を解除';

  @override
  String get readFullArticle => '全文を読む';

  @override
  String get ticketsLoadFailed => 'チケットを読み込めませんでした';

  @override
  String get noTickets => 'チケットはありません';

  @override
  String get ticketsEmptyDescription => 'このワークスペースのチケットがここに表示されます。';

  @override
  String get all => 'すべて';

  @override
  String get ticket => 'チケット';

  @override
  String get ticketLoadFailed => 'チケットを読み込めませんでした';

  @override
  String assignedTo(String name) {
    return '$nameが担当';
  }

  @override
  String get openInBrowser => 'ブラウザで開く';

  @override
  String get status => 'ステータス';

  @override
  String get assign => '割り当て';

  @override
  String get reassign => '再割り当て';

  @override
  String get noAgents => 'エージェントがありません';

  @override
  String get noAgentsDescription => 'このワークスペースのエージェントを割り当ててください。';

  @override
  String get statusOpen => 'オープン';

  @override
  String get statusInProgress => '進行中';

  @override
  String get statusBlocked => 'ブロック';

  @override
  String get statusInReview => 'レビュー中';

  @override
  String get statusDone => '完了';

  @override
  String get statusBacklog => 'バックログ';

  @override
  String get lensNeedsMe => '自分宛て';

  @override
  String get lensMine => '自分';

  @override
  String get prsLoadFailed => 'プルリクエストを読み込めませんでした';

  @override
  String get noOpenPullRequests => 'オープンなプルリクエストはありません';

  @override
  String get nothingWaitingOnReview => 'レビュー待ちはありません';

  @override
  String get noOwnOpenPullRequests => 'オープン中のプルリクエストはありません';

  @override
  String get nothingBlocked => 'ブロック中はありません';

  @override
  String get prsEmptyDescription => 'このワークスペースのリポジトリのプルリクエストがここに表示されます。';

  @override
  String get refreshPullRequests => 'プルリクエストを更新';

  @override
  String get noForgeConnected =>
      'サーバーにForgeが接続されていないため、プルリクエストを取得できません。デスクトップアプリから接続してください。';

  @override
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のリポジトリを読み取れませんでした。',
      one: '1件のリポジトリを読み取れませんでした。',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return '読み取れません: $names';
  }

  @override
  String get installationSuspendedTitle => 'GitHub Appのインストールが停止されています';

  @override
  String installationSuspendedBody(String names) {
    return '$names の最終既知データを表示しています。GitHubでインストールを再開するか、アクセス権のあるトークンを接続してください。';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'GitHub Appのインストールが停止されています。$names の最終既知データを表示しています。GitHubでインストールを再開するか、アクセス権のあるトークンを接続してください。';
  }

  @override
  String get draft => '下書き';

  @override
  String get merged => 'マージ済み';

  @override
  String get closed => 'クローズ';

  @override
  String get open => 'オープン';

  @override
  String get approved => '承認済み';

  @override
  String get changesRequested => '変更リクエスト';

  @override
  String get reviewRequired => 'レビューが必要';

  @override
  String get checksPassing => 'チェックは合格';

  @override
  String get checksFailing => 'チェックが失敗しています';

  @override
  String get checksRunning => 'チェック実行中';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title、$status';
  }

  @override
  String get pullRequest => 'プルリクエスト';

  @override
  String get prLoadFailed => 'このプルリクエストを読み込めませんでした';

  @override
  String get openOnForge => 'Forgeで開く';

  @override
  String get requestChangesNeedsComment => '変更が必要な点をコメントで説明してください。';

  @override
  String get conversation => '会話';

  @override
  String get files => 'ファイル';

  @override
  String get checks => 'チェック';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のファイル',
      one: '1件のファイル',
    );
    return '$_temp0';
  }

  @override
  String commitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のコミット',
      one: '1件のコミット',
    );
    return '$_temp0';
  }

  @override
  String get conflicts => 'コンフリクト';

  @override
  String get reviewers => 'レビュアー';

  @override
  String get noDescriptionNoComments => '説明もコメントもまだありません。';

  @override
  String get noChangedFiles => '変更されたファイルはありません。';

  @override
  String get noChecksReported => 'ヘッドコミットのチェックは報告されていません。';

  @override
  String get reviewCommentHint => 'レビューコメントを入力…';

  @override
  String get comment => 'コメント';

  @override
  String get commentPosted => 'コメントを投稿しました';

  @override
  String get request => 'リクエスト';

  @override
  String get squashAndMerge => 'スカッシュしてマージ';

  @override
  String noActionsAvailable(String status) {
    return '$status — 操作はありません。';
  }

  @override
  String get reviewApproved => '承認済み';

  @override
  String get reviewRequestedChanges => '変更をリクエスト';

  @override
  String get reviewCommented => 'レビュー済み';

  @override
  String get reviewPending => '保留中';

  @override
  String get unknownAuthor => '不明';

  @override
  String hideDiffFor(String file) {
    return '$fileの差分を非表示';
  }

  @override
  String showDiffFor(String file) {
    return '$fileの差分を表示';
  }

  @override
  String get checkRunning => '実行中';

  @override
  String get checkPassed => '成功';

  @override
  String get checkFailed => '失敗';

  @override
  String get checkCancelled => 'キャンセル';

  @override
  String get checkSkipped => 'スキップ';

  @override
  String labelWithDuration(String label, String duration) {
    return '$label · $duration';
  }

  @override
  String checkSemanticLabel(String name, String state) {
    return '$name、$state';
  }

  @override
  String get noTextDiff => 'このファイルのテキスト差分はありません。バイナリか、Forgeが返すには大きすぎます。';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '残りの$count行を表示',
      one: '残りの行を表示',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count行変更なし',
      one: '1行変更なし',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => '最新へジャンプ';

  @override
  String get streaming => 'ストリーミング';

  @override
  String get working => '処理中';

  @override
  String get input => '入力';

  @override
  String get output => '出力';

  @override
  String get now => '今';

  @override
  String agoMinutes(int count) {
    return '$count分';
  }

  @override
  String agoHours(int count) {
    return '$count時間';
  }

  @override
  String agoDays(int count) {
    return '$count日';
  }

  @override
  String get today => '今日';

  @override
  String get tomorrow => '明日';

  @override
  String get yesterday => '昨日';

  @override
  String durationMinutes(int count) {
    return '$count分';
  }

  @override
  String durationHours(int count) {
    return '$count時間';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours時間 $minutes分';
  }
}
