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
  String get copyCommand => 'コマンドをコピー';

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
  String get scanQrPrompt =>
      'このスマートフォンをペアリングするには、Control CenterのQRコードをスキャンしてください。';

  @override
  String get scanQrHelp =>
      'カメラを開いて、Control Centerに表示されたQRに向けてください。このスマートフォンは非公開のリンクで直接接続します。';

  @override
  String get connectingToMac => 'Control Centerに接続しています…';

  @override
  String get connectingDetail => '安全な直接リンクを確立しています。';

  @override
  String get identityChangedTitle => 'サーバーの識別情報が変わりました';

  @override
  String get identityChangedBody =>
      'このサーバーは、ペアリング時に保存された識別情報と一致しなくなりました。サーバーが再インストールされたか、接続が傍受されている可能性があります。安全のため、このデバイスは接続しません。ペアリングを削除してから、Control Centerの新しいQRコードをスキャンして再度ペアリングしてください。';

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
  String get failureNotPaired => '未ペアリング — Control CenterのQRコードをスキャンしてください';

  @override
  String get failureUnreachable =>
      'どの経路でもサーバーに到達できませんでした — 起動しているか確認するか、同じネットワークで試してください';

  @override
  String get failureIdentityChanged =>
      'サーバーの識別情報が変わりました — 再インストールした場合は、このデバイスを再ペアリングしてください';

  @override
  String get failureAuthRejected =>
      'サーバーがこのデバイスを拒否しました — Control Centerから再ペアリングしてください';

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
  String get disconnectTapAgain => 'もう一度タップすると、このデバイスをControl Centerから切断します';

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
  String get newSpaceFolder => '新しいフォルダー';

  @override
  String get folderName => 'フォルダー名';

  @override
  String get renameSpaceFolder => 'フォルダー名を変更';

  @override
  String get deleteSpaceFolder => 'フォルダーを削除';

  @override
  String get moveSpaceToFolder => 'フォルダーに移動';

  @override
  String get removeSpaceFromFolder => 'フォルダーから取り除く';

  @override
  String get spaceFolderActions => 'フォルダーの操作';

  @override
  String get deleteFolderWithSpacesWarning =>
      'スペースを完全に削除すると、そのメッセージと作業ツリーが全員から削除されます。この操作は元に戻せません。';

  @override
  String get deleteSpacesInFolder => 'このフォルダー内のスペースを完全に削除する';

  @override
  String get deleteFolderAndSpaces => 'フォルダーとスペースを削除';

  @override
  String get keepSpacesInFolder => 'それ以外の場合、スペースはどのフォルダーにも属さない状態になります。';

  @override
  String get create => '作成';

  @override
  String get otherSpaces => 'その他のスペース';

  @override
  String get folderUpdateFailed => 'フォルダーを更新できませんでした';

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
  String get teammate => 'チームメイト';

  @override
  String get systemSender => 'システム';

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

  @override
  String get mobileConversations => '会話';

  @override
  String get mobileNewConversation => '新しい会話';

  @override
  String get mobileConversationName => '会話名';

  @override
  String get mobileRename => '名前を変更';

  @override
  String get mobileManageSpace => 'スペースを管理';

  @override
  String get mobileArchived => 'アーカイブ済み';

  @override
  String get mobileSearchMessages => 'このスペースの全メッセージを検索';

  @override
  String get mobileSearch => '検索';

  @override
  String get mobileNoResults => '結果がありません';

  @override
  String get mobileReopen => '再度開く';

  @override
  String get mobileArchive => 'アーカイブ';

  @override
  String get mobileProgress => '進捗とコンテキスト';

  @override
  String get mobileReadFailed => '会話を既読にできませんでした';

  @override
  String get mobileSendFailed => 'メッセージを送信できませんでした。下書きは保持されています。';

  @override
  String get sentAttachmentUnavailable => '添付ファイルは利用できません';

  @override
  String get sentAttachmentLoadFailed => '添付ファイルを読み込めませんでした';

  @override
  String get mobileActionFailed => '操作に失敗しました';

  @override
  String get mobileRemove => '削除';

  @override
  String get mobileLinkedMessage => 'リンク先のメッセージ';

  @override
  String get mobileOlderMessages => '以前のメッセージ';

  @override
  String get mobileMessageActions => 'メッセージの操作';

  @override
  String get mobileOpenThread => 'スレッドを開く';

  @override
  String get mobileCopyLink => 'リンクをコピー';

  @override
  String get mobileStopRun => '実行を停止';

  @override
  String get mobileStopRunConfirm => 'エージェントの実行を停止しますか？完了済みの作業は保持されます。';

  @override
  String get mobileControlUnsupported => 'この実行は終了しているか、この操作に対応していません。';

  @override
  String get mobilePauseRequested => '次のターンの区切りで一時停止するよう要求しました';

  @override
  String get mobileResumed => '実行を再開しました';

  @override
  String get mobileStopRequested => '停止を要求しました';

  @override
  String get mobileQueuedMessages => 'キュー内のメッセージ';

  @override
  String get mobilePauseRun => '次のターンで一時停止';

  @override
  String get mobileResumeRun => '再開';

  @override
  String get mobileEditQueued => 'キュー済みメッセージを編集';

  @override
  String get mobileSteerNow => '今すぐ指示を出す';

  @override
  String get mobileMoveUp => '上へ';

  @override
  String get mobileMoveDown => '下へ';

  @override
  String get mobileQueueChanged =>
      'キューが変更されたか、この実行では進行中の指示を受け付けられません。更新して再試行してください。';

  @override
  String get mobileActivity => 'アクティビティ';

  @override
  String get mobilePermissions => '権限と監査';

  @override
  String get mobilePlans => 'プラン';

  @override
  String get mobileGoals => '監督付きゴール';

  @override
  String get mobileCredentials => '接続と認証情報';

  @override
  String get mobileWorkspaceUnavailable => 'このワークスペースは利用できないか、アクセス権がなくなりました。';

  @override
  String get mobilePrReviewThreads => 'レビュースレッド';

  @override
  String get mobilePrThreadsLoadFailed => 'レビュースレッドを読み込めませんでした';

  @override
  String get mobilePrNoReviewThreads => '行単位のレビュースレッドはまだありません';

  @override
  String get mobilePrCommentPermissionDenied => 'このリポジトリにコメントする権限がありません。';

  @override
  String get mobilePrPermissionChecking => 'コメント権限を確認中…';

  @override
  String get mobilePrPermissionLoadFailed =>
      'コメント権限を確認できませんでした。再試行してからコメントしてください。';

  @override
  String mobilePrThreadLine(String side, String line) {
    return '$sideの$line行目';
  }

  @override
  String get mobilePrOriginalSide => '元の版';

  @override
  String get mobilePrSelectCommentLine => 'コメントする行を選択';

  @override
  String get mobilePrUpdatedSide => '更新日時';

  @override
  String get mobilePrThreadResolved => '解決済み';

  @override
  String get mobilePrReplyHint => '返信を入力…';

  @override
  String get mobilePrCommentRequired => '投稿する前にコメントを入力してください。';

  @override
  String get mobilePrReply => '返信';

  @override
  String get mobilePrReopenThread => 'スレッドを再開';

  @override
  String get mobilePrResolveThread => 'スレッドを解決';

  @override
  String get mobilePrResolvePermissionDenied =>
      'このスレッドを解決できるのは、プルリクエストの作成者か書き込み権限を持つユーザーだけです。';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return '$sideの$line行目にコメント';
  }

  @override
  String get mobilePrInlineCommentHint => '行へのコメントを入力…';

  @override
  String get mobilePrPostInlineComment => 'コメントを投稿';

  @override
  String get mobilePrCommentUnavailable => 'このプルリクエストでは行単位のコメントを利用できません。';

  @override
  String get mobilePrPatchUnavailable =>
      'Gitホスティングサービスからこのファイルのテキストパッチが提供されませんでした。';

  @override
  String get mobilePrNoPatchForFile => 'このファイルのパッチは利用できません。';

  @override
  String get mobileTicketNew => '新規チケット';

  @override
  String get mobileTicketCreate => 'チケットを作成';

  @override
  String get mobileTicketEdit => 'チケットを編集';

  @override
  String get mobileTicketTitle => 'タイトル';

  @override
  String get mobileTicketTitleRequired => 'チケットを保存するにはタイトルを入力してください。';

  @override
  String get mobileTicketDescription => '説明';

  @override
  String get mobileTicketMarkdownHint => 'Markdownで詳細を追加';

  @override
  String get mobileTicketPriority => '優先度';

  @override
  String get mobileTicketPriorityNone => '優先度なし';

  @override
  String get mobileTicketPriorityUrgent => '緊急';

  @override
  String get mobileTicketPriorityHigh => '高';

  @override
  String get mobileTicketPriorityMedium => '中';

  @override
  String get mobileTicketPriorityLow => '低';

  @override
  String get mobileTicketLabels => 'ラベル';

  @override
  String get mobileTicketLabelsHint => '1行に1つのラベル';

  @override
  String get mobileTicketLabelsHelp => 'ラベルごとに改行して入力してください。';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return '登録先: $provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => '未割り当て';

  @override
  String get mobileTicketAssignedFilter => '割り当て済み';

  @override
  String get mobileTicketAgentsLoadFailed => 'エージェントを読み込めませんでした';

  @override
  String get mobileTicketSearch => 'チケットを検索';

  @override
  String get mobileTicketSearchHint => 'タイトル、キー、説明、ラベル、担当者';

  @override
  String get mobileTicketClearSearch => 'チケット検索をクリア';

  @override
  String get mobileTicketNoMatches => '該当するチケットがありません';

  @override
  String get mobileTicketAdjustFilters => '別の語句で検索するか、フィルターを変更してください。';

  @override
  String get mobileTicketClearFilters => 'フィルターをクリア';

  @override
  String get mobileTicketNotFound => 'チケットが見つかりません';

  @override
  String get mobileTicketNotFoundDescription =>
      'このチケットは削除されたか、別のワークスペースに移動された可能性があります。';

  @override
  String get mobileTicketWorkspaceChanged =>
      'ワークスペースが変更されました。保存する前に現在のワークスペースに戻ってください。';

  @override
  String get mobileTicketOpenLinkedSpace => 'リンクされたスペースを開く';

  @override
  String get mobileTicketReadOnly => 'チケットを変更するにはワークスペースのメンバー権限が必要です。';

  @override
  String get permissionTitle => '権限';

  @override
  String get permissionWorkspaceFailed => 'ワークスペースを読み込めませんでした';

  @override
  String get permissionNoWorkspace => '権限を確認するワークスペースを選択してください。';

  @override
  String get permissionLoading => '権限を読み込み中…';

  @override
  String get permissionScopeDescription =>
      'このスコープで各操作がどう判定されるか確認します。ワークスペースのルールはエージェントやスペースに継承されることがあります。';

  @override
  String get permissionScope => 'ポリシーのスコープ';

  @override
  String get permissionWorkspaceScope => 'ワークスペース';

  @override
  String get permissionAgentScope => 'エージェント';

  @override
  String get permissionSpaceScope => 'スペース';

  @override
  String get permissionAgentContext => 'このスペースで操作するエージェント';

  @override
  String get permissionNoAgentContext => 'エージェントが未選択です';

  @override
  String get permissionTargetsFailed => 'スコープの対象を読み込めませんでした';

  @override
  String get permissionNoTargets => 'このスコープに利用可能な対象はありません。';

  @override
  String get permissionRoleFailed => 'ワークスペースでの役割を確認できませんでした';

  @override
  String get permissionMemberRequired => 'ポリシールールを見るにはワークスペースのメンバー権限が必要です。';

  @override
  String get permissionRulesFailed => 'ポリシールールを読み込めませんでした';

  @override
  String get permissionAuditAdminOnly => '認可履歴を見られるのはワークスペースの管理者だけです。';

  @override
  String get permissionAllow => '許可';

  @override
  String get permissionAsk => '先に確認';

  @override
  String get permissionDeny => '拒否';

  @override
  String get permissionFileDelete => 'ファイルを削除';

  @override
  String get permissionFileWriteOutsideWorktree => '作業ツリーの外に書き込む';

  @override
  String get permissionGitCommit => '変更をコミット';

  @override
  String get permissionGitPush => 'コミットをプッシュ';

  @override
  String get permissionPrCreate => 'プルリクエストを作成';

  @override
  String get permissionPrPublish => 'プルリクエストの更新またはマージ';

  @override
  String get permissionVendorSyncWrite => '外部サービスとの同期を書き込む';

  @override
  String get permissionNetworkEgress => 'ネットワークにアクセス';

  @override
  String get permissionSecretAccess => 'シークレットにアクセス';

  @override
  String get permissionPackageInstall => 'パッケージをインストール';

  @override
  String get permissionProcessSpawn => 'プロセスを起動';

  @override
  String get permissionWorkspaceMutation => 'ワークスペースを変更';

  @override
  String get permissionEnclosureControl => '装置を操作';

  @override
  String get permissionChangeFailed => 'ルールを変更できませんでした';

  @override
  String get permissionEffectiveDescription =>
      '操作の引数を指定しない場合、このスコープで適用される設定です。以下の条件付き許可は一致するリクエストにのみ適用されます。最終的な判定はサーバーが行います。';

  @override
  String get permissionSpaceAgentNote =>
      'エージェントが未選択です。上で選択するまで、エージェント固有のルールは表示されません。';

  @override
  String get permissionScopedGrants => 'このスコープのルール';

  @override
  String get permissionModePreset => 'モードプリセット';

  @override
  String get permissionBuiltInDefault => '組み込みのデフォルト';

  @override
  String get permissionRemembered => '期間付き承認';

  @override
  String get permissionSource => 'ソース';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · ここで設定';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · 継承';
  }

  @override
  String permissionExpiresAt(String date) {
    return '有効期限: $date';
  }

  @override
  String get permissionSetHere => 'ここにルールを設定';

  @override
  String get permissionConfirmRevoke => '取り消しを確認';

  @override
  String get permissionRevokeRule => 'ルールを取り消す';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'コマンドの接頭辞: $prefix';
  }

  @override
  String get permissionNoExpiry => '有効期限なし';

  @override
  String get permissionExpired => '期限切れ';

  @override
  String get permissionExplicitRule => '明示的なルール';

  @override
  String get permissionEnforcementAdvisory => '参考扱い: 事前確認ルールは確認を求めずに記録します';

  @override
  String get permissionEnforcementSoft => '柔軟な適用: 上書きには認可が必要です';

  @override
  String get permissionEnforcementHard => '厳格な適用: 上書きできません';

  @override
  String permissionPaths(String paths) {
    return 'パス: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'Gitの参照: $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return 'ホスト: $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return 'コマンド: $commands';
  }

  @override
  String permissionTools(String tools) {
    return 'ツール: $tools';
  }

  @override
  String get permissionNotInEffect => '拒否に設定されている間は無効';

  @override
  String permissionMaxCount(String count) {
    return '最大件数: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return '上限額（セント）: $cents';
  }

  @override
  String get permissionAuditHeading => '認可履歴';

  @override
  String get permissionAuditDescription =>
      'サーバーに記録された最近の判定です。ログの閲覧やハッシュチェーンの検証は管理者のみ可能です。';

  @override
  String permissionOnBehalfOf(String user) {
    return '$userの代理で';
  }

  @override
  String get permissionPrompted => '人による承認を要求';

  @override
  String get permissionVerifyChain => '監査チェーンを検証';

  @override
  String get permissionVerifyFailed => '監査チェーンを検証できませんでした';

  @override
  String permissionChainIntact(String count) {
    return 'チェーンは正常 · $count件を確認';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'チェーンが$sequence番目の記録で破損: $reason';
  }

  @override
  String get permissionAuditEmpty => '認可の判定はまだ記録されていません。';

  @override
  String get permissionAuditFailed => '認可履歴を読み込めませんでした';

  @override
  String get mobilePlansLoadFailed => 'プランを読み込めませんでした';

  @override
  String get mobilePlansEmpty => 'プランはまだありません';

  @override
  String get mobilePlansEmptyDescription =>
      'エージェントから提出されたプランがここに表示され、レビューできます。';

  @override
  String get mobilePlanTitle => 'プラン';

  @override
  String get mobilePlanMissing => 'このプランは現在のワークスペースでは利用できなくなりました。';

  @override
  String mobilePlanStepCount(int count) {
    return '$countステップ';
  }

  @override
  String get mobilePlanDraft => '下書き';

  @override
  String get mobilePlanProposed => 'レビュー待ち';

  @override
  String get mobilePlanApproved => '承認済み';

  @override
  String get mobilePlanRejected => '却下済み';

  @override
  String get mobilePlanSuperseded => '置き換え済み';

  @override
  String get mobilePlanExecuting => '実行中';

  @override
  String get mobilePlanSynthesizing => '統合中';

  @override
  String get mobilePlanCompleted => '完了';

  @override
  String get mobilePlanFailed => '失敗';

  @override
  String get mobilePlanCancelled => 'キャンセル済み';

  @override
  String mobilePlanRevision(String revision) {
    return 'リビジョン $revision';
  }

  @override
  String get mobilePlanSteps => 'ステップ';

  @override
  String get mobilePlanNoSteps => 'このプランにはステップが提出されていません。';

  @override
  String get mobilePlanAssumptions => '確認事項';

  @override
  String mobilePlanDependsOn(String keys) {
    return '依存先: $keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return '最大見積額: $cost';
  }

  @override
  String get mobilePlanSelect => '選択';

  @override
  String get mobilePlanSelected => '選択済み';

  @override
  String get mobilePlanEstimate => '費用を見積もる';

  @override
  String get mobilePlanEstimateRequired => '実行を承認する前にプランを見積もってください。';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return '推定費用: $low～$high';
  }

  @override
  String get mobilePlanCostUnknown => '利用できません';

  @override
  String get mobilePlanNoHardCap => '厳密な上限なし';

  @override
  String get mobilePlanExceedsBudget => '見積額が設定済みの予算を超えています。承認前に確認してください。';

  @override
  String get mobilePlanPartialEstimate =>
      'この見積もりはプラン全体のものです。選択したステップだけなら費用が下がる場合があります。';

  @override
  String get mobilePlanConfirmAll => 'プラン全体を開始しますか？';

  @override
  String get mobilePlanConfirmSelected => '選択したステップを開始しますか？';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return '承認すると実行が始まり、料金が発生する場合があります。推定費用の上限: $cost。予算上限: $cap。';
  }

  @override
  String get mobilePlanApproveAll => 'すべて承認して実行';

  @override
  String get mobilePlanApproveSelected => '選択分を承認して実行';

  @override
  String get mobilePlanWiden => '追加のステップを承認';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return 'さらに$countステップの実行を許可しますか？料金が発生する場合があります。現在の実行費用の上限: $cap。';
  }

  @override
  String get mobilePlanChanged => 'レビュー中にプランが変更されました。最新のリビジョンを開いて再度見積もってください。';

  @override
  String get mobilePlanReject => 'プランを却下';

  @override
  String get mobilePlanRejectConfirm => 'このプランを却下しますか？実行されなくなります。';

  @override
  String get mobilePlanStop => '実行を停止';

  @override
  String get mobilePlanStopConfirm => 'プランの実行を停止しますか？完了済みの作業は元に戻りません。';

  @override
  String mobilePlanRunId(String runId) {
    return '実行ID: $runId';
  }

  @override
  String get mobilePlanExecutionPending => '承認されました。実行記録を待っています…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return '実行ステップ$total件中$completed件が完了';
  }

  @override
  String get mobilePlanOpenConversation => '会話を開く';

  @override
  String get mobileGoalsTitle => '監督付きゴール';

  @override
  String get mobileGoalsLoadFailed => '監督付きゴールを読み込めませんでした';

  @override
  String get mobileGoalsEmpty => '監督付きゴールはまだありません';

  @override
  String get mobileGoalsEmptyDescription => 'スペースで開始するか、会話で/goalを送信してください。';

  @override
  String get mobileGoalMissing => 'このゴールは現在のワークスペースでは利用できなくなりました。';

  @override
  String get mobileGoalActive => '使用中';

  @override
  String get mobileGoalPaused => '一時停止中';

  @override
  String get mobileGoalCompleted => '完了';

  @override
  String get mobileGoalFailed => '失敗';

  @override
  String get mobileGoalCancelled => 'キャンセル済み';

  @override
  String get mobileGoalBudgetExhausted => '予算上限に到達';

  @override
  String mobileGoalFailures(String count) {
    return '連続失敗回数: $count';
  }

  @override
  String get mobileGoalFailedDescription =>
      '実行の失敗が続いたため監督機能が停止しました。詳細は会話を確認してください。';

  @override
  String get mobileGoalPause => 'ゴールを一時停止';

  @override
  String get mobileGoalResume => 'ゴールを再開';

  @override
  String get mobileGoalStop => 'ゴールをキャンセル';

  @override
  String get mobileGoalStopConfirm => 'この監督付きゴールを完全にキャンセルしますか？再開できなくなります。';

  @override
  String get mobileGoalRaiseBudget => '予算を引き上げて再開';

  @override
  String mobileGoalRaiseTo(String amount) {
    return '予算を$amountに引き上げて再開';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return 'このゴールの費用上限を$oldCapから$newCapに引き上げ、費用が発生する実行を再開しますか？';
  }

  @override
  String get mobileGoalOpenConversation => 'ゴールの会話を開く';

  @override
  String get mobileGoalCreate => '監督付きゴールを開始';

  @override
  String get mobileGoalChooseSpace => '実行するスペース';

  @override
  String get mobileGoalNoSpaces => 'ゴールを開始する前にスペースを作成してください。';

  @override
  String get mobileGoalChooseAgent => '実行するエージェント';

  @override
  String get mobileGoalNoAgents => 'ゴールを開始する前に有効なエージェントを追加してください。';

  @override
  String mobileGoalSelectedAgent(String name) {
    return '$nameを選択中';
  }

  @override
  String get mobileGoalObjectiveHint => 'エージェントに達成してほしいことは？';

  @override
  String get mobileGoalBudgetUsd => '費用上限（USD）';

  @override
  String get mobileGoalCreateInvalid =>
      'スペースとエージェントを選び、目標を入力して、USDで正の費用上限を設定してください。';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return '最大費用$capの監督付きゴールを開始しますか？エージェントはすぐに実行を始める場合があります。';
  }

  @override
  String get mobileGoalUnavailable => 'サーバーに接続する準備ができていません。再接続後に試してください。';

  @override
  String get mobileGoalConversationMissing => '選択した会話は現在のワークスペースでは利用できなくなりました。';

  @override
  String get mobileGoalCreateSent => 'ゴールを開始しました。監督機能の状態がこの一覧に表示されます。';

  @override
  String get mobileGoalStartRefused => 'ゴールの実行は始まりませんでした。理由は会話で確認してください。';

  @override
  String mobileGoalSelectedSpace(String name) {
    return '$nameを選択中';
  }

  @override
  String get requestUnavailable => 'このリクエストは現在のワークスペースでは利用できなくなりました。';

  @override
  String get requestAlreadyResolved => 'このリクエストはすでに解決済みです。';

  @override
  String get inboxCredentialsBlocked => '認証情報が原因で実行がブロック中';

  @override
  String get inboxSyncFailures => '外部サービスとの同期に失敗';

  @override
  String get inboxConfigureCredentials => '認証情報を設定';

  @override
  String get openTicket => 'チケットを開く';

  @override
  String get activityTitle => 'アクティビティ';

  @override
  String get activityClearAll => 'アクティビティをすべて消去';

  @override
  String get activityClearConfirm =>
      'これまでに記録されたアクティビティを、すべてのデバイスで非表示にします。新しいアクティビティは引き続き表示されます。';

  @override
  String get activityMarkAllRead => 'すべて既読にする';

  @override
  String get activityMarkAllConfirm => 'このワークスペースのすべてのアクティビティを、全デバイスで既読にしますか？';

  @override
  String get activityMarkRead => '既読にする';

  @override
  String get activityMarkUnread => '未読にする';

  @override
  String get activityDismiss => '閉じる';

  @override
  String get activityResolved => '解決済み';

  @override
  String get activityOpen => 'オープン';

  @override
  String get activityEmpty => 'アクティビティはまだありません';

  @override
  String get activityLoadFailed => 'アクティビティを読み込めませんでした';

  @override
  String get activityAgentWaiting => 'エージェントが入力待ちです';

  @override
  String get activityAgentBlocked => 'エージェントの操作がブロック中';

  @override
  String get activityMessage => '新着メッセージ';

  @override
  String get activityPullRequest => 'プルリクエストの更新';

  @override
  String get activityRig => '装置の更新';

  @override
  String get activityEvent => '更新';

  @override
  String get activityPrReady => 'プルリクエストをマージできます';

  @override
  String get activityPrBlocked => 'プルリクエストのマージがブロック中';

  @override
  String get activityPrApproved => 'プルリクエスト承認';

  @override
  String get activityPrChanges => '変更リクエスト';

  @override
  String get activityPrChecksFailed => 'プルリクエストのチェックに失敗';

  @override
  String get activityPrChecksRecovered => 'プルリクエストのチェックが復旧';

  @override
  String get activityPrComment => 'プルリクエストへのコメント';

  @override
  String get activityPrPublished => 'プルリクエストが公開されました';

  @override
  String get activityPrMerged => 'プルリクエストをマージしました';

  @override
  String get activityPrMentioned => 'プルリクエストであなたがメンションされました';

  @override
  String get activityPrReviewRequested => 'レビュー依頼';

  @override
  String get activityPrReviewStale => 'レビューの更新が必要です';

  @override
  String get activityTicketAssigned => 'チケット割り当て';

  @override
  String get activityTicketChanged => 'チケットの状態が変更';

  @override
  String get activityMeetingSoon => 'まもなく会議開始';

  @override
  String get activityCalendarExpired => 'カレンダー接続の有効期限切れ';

  @override
  String get activityRigControl => '装置の制御設定が変更されました';

  @override
  String get activityRigClosed => '装置が停止しました';

  @override
  String get mobileSpacesSearch => 'スペースを検索';

  @override
  String get mobileSpacesArchived => 'アーカイブ済み';

  @override
  String get mobileSpacesActive => '使用中';

  @override
  String get mobileSpacesNew => '新しいスペース';

  @override
  String get mobileSpacesManage => 'スペースを管理';

  @override
  String get mobileSpacesName => 'スペース名';

  @override
  String get mobileSpacesAgents => 'エージェント';

  @override
  String get mobileSpacesMembers => 'ユーザー';

  @override
  String get mobileSpacesRepos => 'リポジトリ';

  @override
  String get mobileSpacesAllRepos => 'リンクされたすべてのリポジトリ';

  @override
  String get mobileSpacesNoRepos => 'リポジトリがありません';

  @override
  String get mobileSpacesBaseBranch => 'ベースブランチ（任意）';

  @override
  String get mobileSpacesDefaultBranch => 'デフォルトブランチ';

  @override
  String get mobileSpacesMode => 'モード';

  @override
  String get mobileSpacesModeChat => 'チャット';

  @override
  String get mobileSpacesModeReview => 'レビュー（読み取り専用）';

  @override
  String get mobileSpacesModePlan => 'プラン（読み取り専用）';

  @override
  String get mobileSpacesModeOrchestrate => 'オーケストレーション';

  @override
  String get mobileSpacesAutonomy => '自律性の上書き設定';

  @override
  String get mobileSpacesAutonomyInherited => '継承';

  @override
  String get mobileSpacesAutonomyPropose => '提案のみ';

  @override
  String get mobileSpacesAutonomyApproval => '承認後に実行';

  @override
  String get mobileSpacesAutonomyFreely => '自由に実行';

  @override
  String get mobileSpacesAutonomyNotice =>
      '上書き設定でも、操作ポリシーの確認や拒否を回避することはできません。変更できるのはワークスペースの管理者だけです。';

  @override
  String get mobileSpacesArchive => 'スペースをアーカイブ';

  @override
  String get mobileSpacesReopen => 'スペースを再開';

  @override
  String get mobileSpacesSave => '変更を保存';

  @override
  String get mobileSpacesCreate => 'スペースを作成';

  @override
  String get mobileSpacesOperationFailed => 'スペースを更新できませんでした';

  @override
  String get mobileSpacesMissing => 'このワークスペースにスペースが見つかりません';

  @override
  String get mobileSpacesEmptyName => 'スペース名を入力してください';

  @override
  String get mobileSpacesNoMatches => '該当するスペースがありません';

  @override
  String get mobileSpacesUnread => 'エージェントからの未読の返信';

  @override
  String get mobileSpacesNeedsInput => 'あなたの入力が必要です';

  @override
  String get mobileSpacesRunning => 'エージェントが実行中';

  @override
  String get mobileSpacesNoAgents => 'このワークスペースにエージェントはいません';

  @override
  String get mobileSpacesNoMembers => 'ほかのワークスペースメンバーはいません';

  @override
  String get mobileSpacesRepoError => 'リポジトリを読み込めませんでした';

  @override
  String get mobileSpacesRetry => '再試行';

  @override
  String get mobileSpacesBranchUnavailable =>
      'スペースを作成するときにベースブランチを選択または入力してください。既存のスペースのベースブランチは変更できません。';

  @override
  String get mobileSpacesArchivedEmpty => 'アーカイブ済みのスペースはありません';

  @override
  String get mobileSpacesAllRepoWarning =>
      '今後ワークスペースにリンクされるリポジトリも、このスペースに含まれます。';

  @override
  String get mobileSpacesCreatedRetry =>
      'スペースを作成しました。メンバーの追加を再試行するか、管理ページを開いてください。';

  @override
  String get progressTitle => '進捗';

  @override
  String get progressConversation => '会話';

  @override
  String get progressLoadFailed => '進捗を読み込めませんでした';

  @override
  String get progressUnavailable => '会話を利用できません';

  @override
  String get progressUnavailableDescription =>
      'この会話は現在のワークスペースとスペースにありません。続けるには会話のスペースに戻ってください。';

  @override
  String get progressSaveFailed => '進捗を更新できませんでした';

  @override
  String get progressGoal => '目標';

  @override
  String get progressNoGoal => '作業目標が設定されていません';

  @override
  String get progressSetGoal => '目標を設定';

  @override
  String get progressEditGoal => '目標を編集';

  @override
  String get progressClearGoal => 'ゴールをクリア';

  @override
  String get progressGoalRequired => '保存する前に目標を入力してください。';

  @override
  String get progressTodos => 'タスク';

  @override
  String get transcriptToolTodos => 'タスク';

  @override
  String get transcriptToolSearchMemory => 'メモリを検索';

  @override
  String get transcriptToolRenderMedia => 'メディアを表示';

  @override
  String get progressNoTodos => 'タスクはまだありません';

  @override
  String get progressNewTodo => '新しいタスク';

  @override
  String get progressAddTodo => 'タスクを追加';

  @override
  String get progressEditTodo => 'タスクを編集';

  @override
  String get progressTodoRequired => '保存する前にタスクを入力してください。';

  @override
  String get progressTodoNoLongerExists => 'そのタスクは削除されました。一覧を再読み込みしてからお試しください。';

  @override
  String get progressWorkspaceChanged =>
      '現在のワークスペースが変更されました。この会話に戻って再試行してください。';

  @override
  String progressRemoveTodo(String name) {
    return 'タスク$nameを削除';
  }

  @override
  String get progressPending => '保留中';

  @override
  String get progressInProgress => '進行中';

  @override
  String get progressCompleted => '完了';

  @override
  String get progressMoveUp => 'タスクを上へ移動';

  @override
  String get progressMoveDown => 'タスクを下へ移動';

  @override
  String get progressRunTree => 'エージェントの実行';

  @override
  String get progressNoRuns => 'この会話にはまだ実行がありません';

  @override
  String get progressRunning => '実行中';

  @override
  String get progressFailed => '失敗';

  @override
  String get progressUnknown => '不明';

  @override
  String get progressHealthy => '使用中';

  @override
  String get progressBlocked => 'ブロック中';

  @override
  String get progressLooping => 'ループ中';

  @override
  String get progressStalled => '停滞中';

  @override
  String get progressDead => '予期せず停止';

  @override
  String get progressQuiet => '出力はまだありません';

  @override
  String get progressCostReported => 'プロバイダーが報告した請求額';

  @override
  String get progressCostNotional => 'サブスクリプションの参考定価。請求額ではありません';

  @override
  String get progressCostMixed => '複数の費用データ源';

  @override
  String get progressCostEstimated => '推定費用';

  @override
  String progressDurationSeconds(String seconds) {
    return '$seconds秒';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'モデル: $model · 時間: $duration · 費用: $cost';
  }

  @override
  String progressStartedAt(String time) {
    return '$timeに開始';
  }

  @override
  String progressLiveness(String state) {
    return '状態: $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return '入力: $input · 出力: $outputトークン';
  }

  @override
  String get progressOutputPreviewLimited => '構造化された出力は先頭6,000文字のみ表示しています。';

  @override
  String progressRetryOf(String runId) {
    return '実行$runIdの再試行';
  }

  @override
  String get progressContext => 'コンテキストと上限';

  @override
  String get progressNoAgent => '確認できるエージェントがいません';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $windowトークン';
  }

  @override
  String get progressMeasured => '直近の呼び出しでプロバイダーが報告したコンテキスト';

  @override
  String get progressEstimated => '保存済みの会話と永続コンテキストから推定';

  @override
  String get progressContextUnknown => 'コンテキストの使用量はまだ報告されていません';

  @override
  String progressContextPercent(String percent) {
    return 'コンテキストウィンドウの$percent%';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return '設定済みのエージェント月間上限: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return '保存済みの進行中の会話: 推定$tokensトークン';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return '$agentの永続コンテキスト · $model';
  }

  @override
  String get progressContextSystem => 'システムプロンプト';

  @override
  String get progressContextRules => 'ルール';

  @override
  String get progressContextSkills => 'スキル';

  @override
  String get progressContextTools => 'ツール定義';

  @override
  String get progressContextMcp => 'MCPツール';

  @override
  String get progressContextDeferred => '遅延読み込みツール';

  @override
  String get progressContextSubagents => 'サブエージェント';

  @override
  String get progressContextRunner => '外部ランナー';

  @override
  String get progressContextMemory => 'メモリ';

  @override
  String get progressContextHistory => '会話履歴';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokensトークン';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokensトークン';
  }

  @override
  String get progressOutputs => '最近の出力';

  @override
  String get progressNoOutputs => 'エージェントの最近の出力はありません';

  @override
  String get progressStructuredOutputsAbove =>
      '構造化された実行結果は、上のエージェント実行欄に表示されています。';

  @override
  String get progressRecentOutputsOnly =>
      '最近のメッセージのみ表示しています。以前の作業は会話を開いて確認してください。';

  @override
  String get progressPlan => 'プラン';

  @override
  String get progressArtifact => 'アーティファクト';

  @override
  String get progressResult => '結果';

  @override
  String get progressHideArtifact => 'アーティファクトを隠す';

  @override
  String get progressReadArtifact => 'アーティファクトを読む';

  @override
  String get progressArtifactUnavailable => 'アーティファクトは利用できなくなりました';

  @override
  String get progressArtifactPreviewLimited => 'このアーティファクトの一部のみプレビューしています。';

  @override
  String get progressDiagramSource => '図のソース';

  @override
  String progressOpenAttachment(String name) {
    return '$nameを開く';
  }

  @override
  String get progressOpenPlan => 'プランを開く';

  @override
  String progressOpenDiff(String label) {
    return '変更されたファイルを確認: $label';
  }

  @override
  String get progressViewMessage => 'メッセージを表示';

  @override
  String get pushTitle => 'バックグラウンド通知';

  @override
  String get pushIntro =>
      'アプリを閉じていても、対応が必要なときに非公開の通知を受け取れます。詳細は暗号化された接続内に留まります。';

  @override
  String get pushLoading => '通知設定を確認中…';

  @override
  String get pushError => '通知を更新できませんでした。接続を確認して再試行してください。';

  @override
  String get pushEnable => '通知を有効にする';

  @override
  String get pushDisable => '通知をオフにする';

  @override
  String get pushQuiet => 'このデバイスの通知を一時停止';

  @override
  String get pushCategories => '通知する項目';

  @override
  String get pushCategoryAgents => 'エージェント';

  @override
  String get pushCategoryMessages => 'メッセージ';

  @override
  String get pushCategoryPullRequests => 'プルリクエスト';

  @override
  String get pushCategoryTickets => 'チケット';

  @override
  String get pushCategoryCalendar => 'カレンダー';

  @override
  String get pushCategoryMachines => 'マシン';

  @override
  String get pushSecureOrigin => '通知にはHTTPSが必要です。';

  @override
  String get pushInstallIos =>
      'iPhoneまたはiPadでは、このアプリをホーム画面に追加し、そこから開くと通知を有効にできます。';

  @override
  String get pushUnsupported => 'このブラウザーはバックグラウンド通知に対応していません。';

  @override
  String get pushDenied =>
      'ブラウザーは通知がブロックされていると報告しています。このサイトの許可設定とブラウザーまたは端末の通知設定を確認し、更新してください。';

  @override
  String get pushOsHint => 'ブラウザー自体にも、端末のシステム設定で通知を表示する許可が必要です。';

  @override
  String get pushServiceUnavailable =>
      'ブラウザーのプッシュサービスが登録を拒否しました。Brave など一部のブラウザーは既定でこのサービスをオフにしています。ブラウザーのプライバシー設定でプッシュメッセージのオプションを確認してから、もう一度お試しください。';

  @override
  String get pushWorkerUnavailable =>
      'このブラウザーで通知サービスを開始できませんでした。ページを再読み込みして、もう一度お試しください。';

  @override
  String get pushResubscribe => '通知を再接続';

  @override
  String get pushStatusEnabled => 'このデバイスの通知はオンです。';

  @override
  String get pushStatusDisabled => 'このデバイスの通知はオフです。';

  @override
  String get credentialsTitle => '接続と認証情報';

  @override
  String get credentialsIntro =>
      '実行や連携で使うアカウントを接続します。シークレットはこのスマートフォンではなく、サーバーに保存されます。';

  @override
  String get credentialsModelProviders => 'モデルプロバイダー';

  @override
  String get credentialsOwnerOnly =>
      'モデルプロバイダーの認証情報を追加、サインイン、削除できるのはサーバーの所有者だけです。このキーはワークスペース間で共有されます。';

  @override
  String get credentialsContactOwner =>
      'ブロックされた実行に必要なプロバイダーの接続を、サーバーの所有者に依頼してください。';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'Claude CodeにはホストのCLIからサインインします。ホストのターミナルでアカウントへのサインインまたは更新を完了するよう、サーバーの所有者に依頼してください。このスマートフォンでは実行できません。';

  @override
  String get credentialsYourForgeAccounts => 'あなたのGitホスティングアカウント';

  @override
  String get credentialsYourTicketingAccount => 'あなたのチケット管理アカウント';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'ローカルのチケットにはサインインが不要です。ワークスペースでLinearを使う場合は、ここで接続してください。';

  @override
  String get credentialsMembershipRequired =>
      'Gitホスティングやチケット管理の認証情報を管理するには、ワークスペースに参加してください。管理者にアクセスを依頼してください。';

  @override
  String get credentialsSwitchWorkspace =>
      'このリンクは別のワークスペースを指しています。認証情報を変更する前に、そのワークスペースに切り替えてください。';

  @override
  String get credentialsReturnToInbox =>
      '認証情報を接続したら、受信トレイに戻ってブロックされた実行を再試行してください。ホストも待機中の実行を自動的に確認します。';

  @override
  String get credentialsLoadFailed => '接続を読み込めませんでした。サーバーへの接続を確認して再試行してください。';

  @override
  String get credentialsOperationFailed =>
      'この接続を変更できませんでした。サーバーへの接続、アクセス権、認証情報を確認して再試行してください。';

  @override
  String get credentialsConnected => '接続済み';

  @override
  String get credentialsNotConnected => '未接続';

  @override
  String credentialsSignedInAs(String username) {
    return '$usernameとしてサインイン中';
  }

  @override
  String get credentialsAccount => '接続済みアカウント';

  @override
  String get credentialsStoredKey => '保存済みのキー';

  @override
  String get credentialsActive => '使用中';

  @override
  String get credentialsRemove => '削除';

  @override
  String get credentialsRemoveConfirm =>
      '保存済みの認証情報を削除しますか？再度サインインが必要になる場合があります。';

  @override
  String get credentialsApiKey => 'APIキー';

  @override
  String get credentialsApiKeyHint => 'プロバイダーのAPIキーを貼り付け';

  @override
  String get credentialsBrowserLogin => 'ブラウザーでサインイン';

  @override
  String get credentialsSignInAgain => '再サインイン';

  @override
  String get credentialsWaitingForLogin => 'ブラウザーでの認可を待っています…';

  @override
  String get credentialsConnectCodePrompt => '確認コード';

  @override
  String get credentialsConnectCodeMalformed =>
      'サインインコードではないようです。コードは英数字8文字です。';

  @override
  String get credentialsSignInInvalidCode =>
      'このコードはこのサインインと一致しません。確認してもう一度お試しください。';

  @override
  String get credentialsSignInTooManyCodes => '誤ったコードが多すぎます。サインインをやり直してください。';

  @override
  String get credentialsSignInRetryLater =>
      'サインインサービスが現在応答していません。1分待ってからもう一度お試しください。';

  @override
  String get credentialsSignInRefused =>
      'サインインが拒否されました。もう一度開始し、要求されたすべての権限を承認してください。';

  @override
  String get credentialsSignInNotSaved =>
      'サインインは成功しましたが、サーバーが保存できませんでした。もう一度お試しください。';

  @override
  String credentialsSignInUnavailable(String provider) {
    return 'このサーバーでは$providerへのサインインがまだ設定されていません。';
  }

  @override
  String get credentialsSignInPhoneUnreachable =>
      'このサーバーのサインイン用コールバックには、スマートフォンから安全にアクセスできません。デスクトップアプリからサインインするか、サーバーの所有者に公開 HTTPS アドレスの設定を依頼してください。';

  @override
  String get credentialsLoginTimedOut => 'サインインの期限が切れました。もう一度やり直してください。';

  @override
  String get credentialsCopyCode => 'コードをコピー';

  @override
  String get credentialsDeviceCodeHint =>
      'プロバイダーのページでこのコードを確認してください。サーバーがサインインを完了するまで、この画面を開いたままにしてください。';

  @override
  String get credentialsPasteRedirect => '認可コードまたはリダイレクトURL';

  @override
  String get credentialsPasteRedirectHint =>
      'プロバイダーから取得したコードまたはリダイレクトURL全体を貼り付け';

  @override
  String get credentialsCompleteLogin => 'サインインを完了';

  @override
  String get credentialsUpdateToken => 'トークンを更新';

  @override
  String get credentialsAddToken => 'トークンを追加';

  @override
  String get credentialsPersonalToken => '個人用アクセストークン';

  @override
  String get credentialsPersonalTokenHint => '個人用アクセストークンを貼り付け';

  @override
  String get credentialsStopWatching => '待機をやめる';

  @override
  String get transcriptClaudeSignInExpiredTitle =>
      'Claude Code のサインインの有効期限が切れました';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      'アカウントが認証できなくなったため、実行が停止しました。再度サインインしてから、このターンを再試行してください。';

  @override
  String get transcriptSignInExpiredTitle => 'プロバイダーのサインインの有効期限が切れました';

  @override
  String get transcriptSignInExpiredBody =>
      'プロバイダーの認証情報が使えなくなったため、実行が停止しました。設定 → プロバイダーで再接続してから、このターンを再試行してください。';

  @override
  String get permissionHostExecution => 'ホストでコマンドを実行';

  @override
  String credentialsSignInLapsed(String provider) {
    return '$provider のサインインが切れています。もう一度サインインしてください。';
  }

  @override
  String get credentialsSignInPaused =>
      '一時停止中: このワークスペースのサインインサービスが変更されました。サービスが戻れば再び使えます。';

  @override
  String credentialsProviderUnreachable(String provider) {
    return '現在 $provider に接続できません。再試行しています。';
  }

  @override
  String get credentialsScopeWorkspace => 'このワークスペースのみ';

  @override
  String get credentialsScopeAllWorkspaces => 'すべてのワークスペース';

  @override
  String get credentialsRemoveConfirmWorkspace =>
      '保存した認証情報をこのワークスペースから削除しますか？ほかのワークスペースはそれぞれの認証情報を保ちます。';

  @override
  String get credentialsRemoveConfirmAllWorkspaces =>
      '保存した認証情報を、共有しているすべてのワークスペースから削除しますか？';

  @override
  String get credentialsSignInServerRestarted =>
      'サーバーが再起動しました。サインインをやり直してください。';

  @override
  String repoAccessInstallApp(String owner, String names) {
    return '自動化が $names にアクセスできるよう、$owner に GitHub App をインストールしてください。タップすると GitHub が開きます。';
  }

  @override
  String repoAccessAskAdminInstall(String owner, String names) {
    return '$owner に GitHub App がインストールされていないため、自動化は $names にアクセスできません。ワークスペースの管理者にインストールを依頼してください。';
  }

  @override
  String repoAccessAddToApp(String names) {
    return '$names を GitHub App のリポジトリに追加してください。タップすると GitHub が開きます。';
  }

  @override
  String repoAccessAskAdminAdd(String names) {
    return 'GitHub App からまだ $names が見えません。ワークスペースの管理者に、App のリポジトリへの追加を依頼してください。';
  }

  @override
  String repoAccessSuspended(String names) {
    return 'GitHub App のインストールが停止されています。アカウントのオーナーが GitHub でインストールを再開するまで、$names の自動化は一時停止しています。';
  }

  @override
  String repoAccessOwnerCannotSee(String names) {
    return 'このワークスペースの自動化の責任者が $names を見られなくなったため、そこではその人の代わりに何も実行されません。';
  }

  @override
  String repoAccessOwnerNotSignedIn(String names) {
    return 'このワークスペースの自動化の責任者がフォージにサインインしていないため、$names の自動化はその人がサインインするまで待機しています。';
  }

  @override
  String repoAccessRetrying(String names) {
    return '$names へのアクセスを確認できませんでした。再試行しています。';
  }

  @override
  String hiddenReposSignIn(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$forge にサインインすると、さらに $count 件のリポジトリのプルリクエストが表示されます',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoForgeAccess(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$forge アカウントから見えないため、$count 件のリポジトリが非表示です',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoGrant(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'このワークスペースでアクセス権がないため、$count 件のリポジトリが非表示です',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposChecking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'さらに $count 件のリポジトリへのアクセスを確認しています…',
    );
    return '$_temp0';
  }

  @override
  String get credentialsAtlassianEmail => 'Atlassian アカウントのメールアドレス';

  @override
  String get credentialsAtlassianEmailInvalid =>
      'Atlassian アカウントのメールアドレスを入力してください。';

  @override
  String get credentialsBitbucketApiToken => 'API トークン';

  @override
  String repoAccessAutomationTokenMissing(String names) {
    return '$names を読み取れる自動化トークンがないため、そこでのバックグラウンド処理は一時停止しています。管理者が「設定 → リポジトリ」で追加できます。';
  }

  @override
  String get credentialsSignInConfirmInBrowser =>
      'ブラウザで確認してから、表示されたコードを下の欄に入力してください。';

  @override
  String get credentialsSignInAccountAlreadyBound =>
      'このアカウントは、このサーバー上の別のユーザーにすでに連携されています。別のアカウントでサインインしてください。';

  @override
  String credentialsTokenUnreachable(String provider) {
    return '$provider に接続してこのトークンを確認できませんでした。しばらくしてからもう一度お試しください。';
  }

  @override
  String credentialsTokenRejected(String provider) {
    return '$provider がこのトークンを受け付けません。すべてコピーできているか、取り消されていないかを確認してください。';
  }

  @override
  String credentialsTokenWrongKind(String provider) {
    return 'これは個人用トークンではありません。プロジェクト、グループ、ワークスペース、ボットのトークンではなく、ご自身の $provider アカウントの個人用アクセストークンを貼り付けてください。';
  }

  @override
  String credentialsTokenNarrowScope(String scope) {
    return 'このトークンには $scope スコープがありません。レビューとコメントに必要です。これを含むトークンを作成してください。';
  }

  @override
  String get credentialsTokenExpired =>
      'このトークンは期限切れです。新しいトークンを作成して、ここに貼り付けてください。';

  @override
  String get credentialsSignInRateLimited =>
      '現在リクエストが多すぎます。少し待ってから、もう一度お試しください。';

  @override
  String get credentialsSignInCancelled =>
      'サインインはキャンセルされたか、拒否されました。準備ができたら、もう一度開始してください。';

  @override
  String get credentialsSignInNoLongerOpen =>
      'このサインインは、取り消された、使用された、または置き換えられたため、もう開いていません。もう一度開始してください。';

  @override
  String get noWorkspacesYetHint =>
      'ワークスペース管理者に招待してもらうか、サーバーオーナーにワークスペースを作成してもらってください。';

  @override
  String repoAccessReplaced(String repos, String forge) {
    return '$repos は、$forge 上の別のリポジトリを指すようになりました。引き続き使うには、デスクトップまたは Web アプリから再リンクしてください。';
  }

  @override
  String repoAccessAskAdminRelink(String repos, String forge) {
    return '$repos は、$forge 上の別のリポジトリを指すようになりました。再び使うには、ワークスペース管理者が再リンクする必要があります。';
  }

  @override
  String get runSandboxUnavailableTitle => 'エージェントにはこのサーバーのサンドボックスが必要です';

  @override
  String get runSandboxUnavailable =>
      'このサーバーにはサンドボックスがないため、ここでエージェントを実行できるのはそのオーナーだけです。オーナーはサンドボックスをインストールするか、全員のサンドボックスをオフにできます。';

  @override
  String get scriptToolCalls => 'ツール呼び出し';

  @override
  String scriptCallCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 回の呼び出し',
      one: '1 回の呼び出し',
    );
    return '$_temp0';
  }

  @override
  String scriptCallsRunning(int count) {
    return '$count 件実行中';
  }

  @override
  String scriptCallsOk(int count) {
    return '$count 件成功';
  }

  @override
  String scriptCallsFailed(int count) {
    return '$count 件失敗';
  }

  @override
  String scriptCallsDenied(int count) {
    return '$count 件拒否';
  }

  @override
  String scriptCallsCancelled(int count) {
    return '$count 件キャンセル';
  }

  @override
  String scriptCallsQueued(int count) {
    return '$count 件キュー待ち';
  }

  @override
  String scriptCallsSkipped(int count) {
    return '$count 件スキップ';
  }

  @override
  String get scriptStepQueued => 'キュー待ち';

  @override
  String get scriptStepSkipped => 'スキップ済み';

  @override
  String get scriptGroupLoop => 'ループ';

  @override
  String get scriptGroupEach => '各要素ごと';

  @override
  String get scriptGroupParallel => '並列';

  @override
  String get scriptGroupFunction => '関数';

  @override
  String scriptCallsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'さらに $count 件の呼び出しを表示',
      one: 'さらに 1 件の呼び出しを表示',
    );
    return '$_temp0';
  }

  @override
  String get scriptCallsUnplaced => 'スクリプト内に配置されていない呼び出し';

  @override
  String get scriptToolComputed => 'ツール';

  @override
  String scriptStepSemantics(String subject, String state) {
    return '$subject、$state';
  }

  @override
  String get scriptSourceLabel => 'スクリプト';

  @override
  String scriptSourceLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 行',
      one: '1 行',
    );
    return '$_temp0';
  }

  @override
  String get scriptStateRunning => '実行中';

  @override
  String get scriptStateCompleted => '完了';

  @override
  String get scriptStateFailed => '失敗';

  @override
  String get scriptStateTimedOut => '時間切れ';

  @override
  String get scriptStateCancelled => 'キャンセル済み';

  @override
  String get scriptStateMemoryExceeded => 'メモリ上限超過';

  @override
  String get scriptStateOutputExceeded => '出力量超過';

  @override
  String get scriptStateSandboxError => 'サンドボックスエラー';

  @override
  String get scriptStateRefused => '拒否';

  @override
  String get scriptOriginLine => 'エージェントが実行中のスクリプトからのリクエスト';

  @override
  String get codeModeTitle => 'コードモード';

  @override
  String get codeModeAvailable => '利用可能';

  @override
  String get codeModeUnavailable => '利用不可';

  @override
  String codeModeUnavailableNote(String reason) {
    return 'このサーバーではスクリプトを実行できないため、ここのエージェントはツールを1つずつ呼び出します。サーバーの説明: $reason';
  }

  @override
  String get codeModeNoReason => '理由は示されませんでした。';

  @override
  String get workKindUnknown => 'このバージョンでは次の理由を認識できません:';

  @override
  String get workRefusalUnknown => 'サーバーがこれを拒否しました:';

  @override
  String workActionFailed(String error) {
    return 'うまくいきませんでした: $error';
  }

  @override
  String get wakeKindStopped => '担当者が実行を停止したため、保留中です。';

  @override
  String get wakeKindAttempts => '配信が3回失敗しました。';

  @override
  String get wakeKindAgentDeleted => 'エージェントはもう存在しません。';

  @override
  String get wakeKindAgentNotDispatchable => 'エージェントは退役済みです。';

  @override
  String get wakeKindAgentPaused => 'エージェントは一時停止中です。';

  @override
  String get wakeKindPersonRemoved => '代わりに動く担当者がワークスペースを離れました。';

  @override
  String get wakeKindBudgetBlocked => '予算により実行がブロックされています。';

  @override
  String get wakeKindTakeOver => '担当者がワークツリーを引き継ぎました。';

  @override
  String get wakeKindRateCapConversation => 'この会話は、起動予約から直近1時間に30回の実行を開始しました。';

  @override
  String get wakeKindRateCapWorkspace =>
      'このワークスペースは、起動予約から直近1時間に300回の実行を開始しました。';

  @override
  String get wakeKindLiveRunNoInput => 'エージェントの実行中の処理は入力を受け付けません。';

  @override
  String get wakeKindLiveRunOtherOptions =>
      'エージェントの実行中の処理は別の設定で動いているため、この起動予約はその後に独自の実行を開始します。';

  @override
  String get wakeKindLiveRunOtherPerson =>
      'エージェントの実行中の処理は別の担当者として動いているため、この起動予約はその後に独自の実行を開始します。';

  @override
  String get wakeKindDispatchRefused => '実行を開始できませんでした。';

  @override
  String get wakeKindSandboxUnavailable => '読み取り専用の実行に使えるサンドボックスがありません。';

  @override
  String get wakeKindReadOnlyUnavailable => 'このエージェントのバックエンドは、実行を読み取り専用に保てません。';

  @override
  String get wakeKindServerStopped => 'サーバーの再起動により実行が停止しました。';

  @override
  String get wakeKindServerRestarted => '担当者の実行中にサーバーが再起動しました。';

  @override
  String get wakeKindGuardFailed => '配信前のチェックに失敗しました。';

  @override
  String get wakeKindLimit => 'プロバイダーの利用上限がリセットされるまで待っています。';

  @override
  String get wakeKindLimitRunLive => '利用上限に達した実行が終わるまで待っています。';

  @override
  String get wakeKindWakeMissed => 'サーバーの停止中に逃しました。';

  @override
  String get wakeKindPipelineRunEnded => 'パイプラインの実行が終了しました。';

  @override
  String get wakeKindGoalEnded => 'ゴールが終了しました。';

  @override
  String get wakeKindGoalBudgetExhausted => 'ゴールが予算を使い切りました。';

  @override
  String get wakeKindGoalReviewStale => 'このレビューを依頼した後にゴールが変更されました。';

  @override
  String get wakeKindGoalPaused => 'ゴールは一時停止中です。';

  @override
  String get wakeKindGoalHeld => 'ゴールは保留中です。';

  @override
  String get wakeKindGoalStopped => 'ゴールは停止されました。';

  @override
  String get wakeKindAskSettled => 'この起動予約が回答する質問は、すでに決着しています。';

  @override
  String get wakeKindRuleEnded => 'スケジュールが終了しました。';

  @override
  String get wakeRefusalNotYours =>
      'この起動予約は別の担当者のために動きます。配信や再開ができるのはその担当者だけです。';

  @override
  String get wakeRefusalSettled => 'この起動予約はすでに決着しています。';

  @override
  String get goalRefusalAlreadyActive => 'このエージェントにはすでに進行中のゴールがあります。';

  @override
  String get goalRefusalNotInReview => 'このゴールはレビュー待ちではありません。';

  @override
  String get goalRefusalEvidenceIncomplete => 'ゴールの根拠が不完全です。';

  @override
  String get goalRefusalClaimPending => '完了したという主張は、まだ確認中です。';

  @override
  String get goalRefusalNotActiveSegment => 'このゴールには実行中のセグメントがありません。';

  @override
  String get goalRefusalNotYours => 'このゴールを開始した担当者だけが実行できます。';

  @override
  String get goalRefusalNotPaused => '先にゴールを一時停止してください。';

  @override
  String get goalRefusalContractInvalid => 'ゴールの契約を読み取れません。';

  @override
  String get goalRefusalCheckerUnknown => 'その名前のエージェントはありません。';

  @override
  String get goalRefusalCheckerAmbiguous => 'その名前のエージェントが複数あります。';

  @override
  String get goalRefusalCheckerIsGoalAgent =>
      'チェッカーは、作業を行うエージェントとは別のエージェントである必要があります。';

  @override
  String get goalRefusalCommandInvalid => 'このゴールを読み取れません:';

  @override
  String get wakeRuleRefusalIntervalTooShort => '間隔が短すぎます。少なくとも1分を選んでください。';

  @override
  String get wakeRuleRefusalTooSoon => 'その時刻は近すぎます。より後の時刻を選んでください。';

  @override
  String get wakeRuleRefusalLineageEnded => 'この起動予約の連鎖は、実行回数または時間を使い切りました。';

  @override
  String get wakeRuleRefusalWatchTargetUnreadable => 'この監視対象は読み取れません。';

  @override
  String get wakeRuleRefusalExpiryRequired => '終了日、または実行回数を指定してください。';

  @override
  String get wakeRuleRefusalLimitReached =>
      'この会話またはエージェントにはすでに上限までのスケジュールがあります。';

  @override
  String get wakeRuleRefusalInvalidWhen => '時刻を読み取れません。';

  @override
  String get wakeRuleRefusalNoteTooLong => 'ノートが長すぎます。';

  @override
  String get wakeRuleRefusalExpiryTooLong => '終了日が先すぎます。';

  @override
  String get wakeRuleRefusalLimitOutOfRange => '実行回数、日数、または予算の上限が範囲外です。';

  @override
  String get wakeRuleRefusalNextOutsideLoop => '次の時刻を自分で決められるのはループだけです。';

  @override
  String get wakeRuleRefusalWatchRefused => 'これは監視できません。';

  @override
  String get wakeRuleRefusalRuleEnded => 'そのスケジュールはすでに終了しています。';

  @override
  String get wakeRuleRefusalNotYours => 'そのスケジュールは別の担当者のものです。';

  @override
  String get wakeRuleEndFired => '1回の実行を完了しました。';

  @override
  String get wakeRuleEndExpired => '終了日に達しました。';

  @override
  String get wakeRuleEndRunCap => '実行回数の上限に達しました。';

  @override
  String get wakeRuleEndCostCap => 'コスト上限に達しました。';

  @override
  String get wakeRuleEndGoalEnded => 'ゴールが終了しました。';

  @override
  String get wakeRuleEndCancelled => 'キャンセルされました。';

  @override
  String get wakeRuleEndMemberRemoved => '担当者がワークスペースを離れました。';

  @override
  String get wakeRuleEndInvalidRow => '保存された設定を読み取れませんでした。';

  @override
  String goalHoldWorking(int segment) {
    final intl.NumberFormat segmentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String segmentString = segmentNumberFormat.format(segment);

    return 'セグメント $segmentString で作業中です。誰も対応する必要はありません。';
  }

  @override
  String get goalHoldWaiting => '受け取るべき作業を待っています。自動で続行します。';

  @override
  String goalHoldWaitingUntil(String time) {
    return '受け取るべき作業を待っています。遅くとも $time には自動で続行します。';
  }

  @override
  String get goalHoldVerifying => '完了を宣言しています。サーバーがチェックを実行し、その後レビュー担当者が判断します。';

  @override
  String get goalHoldLimit => 'プロバイダーの利用上限で一時停止中です。リセット後に自動で再開します。';

  @override
  String goalHoldLimitUntil(String time) {
    return 'プロバイダーの利用上限で一時停止中です。$timeに自動で再開します。';
  }

  @override
  String get goalHoldPerson => '会話で担当者の回答を待っています。誰かが回答すると続行します。';

  @override
  String get goalHoldByPerson => '担当者が一時停止しました。誰かが再開するまで一時停止のままです。';

  @override
  String get goalHoldNeedsReview =>
      'レビュー待ち: 自動では進めません。完了として承認するか、再開するか、キャンセルしてください。';

  @override
  String get goalHoldBudget => '予算を使い切りました。続行するには予算を引き上げてください。';

  @override
  String goalHoldLimitParks(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return '利用上限による一時停止: $countString / $maxString';
  }

  @override
  String get goalHoldDetailStalled => '直近のセグメントで進捗がありません。';

  @override
  String get goalHoldDetailStalledWaiting => '同じ作業で24時間、進捗なく待機しました。';

  @override
  String get goalHoldDetailVerificationFailed => '前回のチェックが失敗しました。';

  @override
  String get goalHoldDetailCannotVerify => 'チェッカーは、完了したかどうかを判断できませんでした。';

  @override
  String get goalHoldDetailSandboxUnavailable => 'チェックを実行するサンドボックスがありません。';

  @override
  String get goalHoldDetailCheckerUnavailable =>
      'チェッカーのエージェントが利用できません。別のチェッカーを選んでから再開してください。';

  @override
  String get goalHoldDetailCheckBroken => 'このチェックは実行できません:';

  @override
  String get goalHoldDetailWakeSkipped => 'その起動予約は配信されませんでした。';

  @override
  String get goalHoldDetailClaimPending => '完了したという主張は、チェックの結果を待っています。';

  @override
  String get goalHoldDetailUnanswered => '担当者への質問または承認リクエストに回答がありません。';

  @override
  String get goalHoldDetailLimitParks => '利用上限での一時停止が多すぎました。内容を確認してから再開してください。';

  @override
  String get goalHoldDetailInput => '会話内の回答を待っています。';

  @override
  String goalSegments(int run, int max) {
    final intl.NumberFormat runNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String runString = runNumberFormat.format(run);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'セグメント $runString / $maxString';
  }

  @override
  String goalSegmentsNoCap(int run) {
    final intl.NumberFormat runNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String runString = runNumberFormat.format(run);

    return 'セグメント $runString、上限なし';
  }

  @override
  String goalMoney(String spent, String cap) {
    return '$spent / $cap 使用';
  }

  @override
  String goalDeadline(String time) {
    return '期限 $time';
  }

  @override
  String get goalPipelineStep => 'パイプラインのステップがこのゴールを進めています。';

  @override
  String get goalSummaryHeading => '最後の要約';

  @override
  String get goalDoneMeans => '完了の条件';

  @override
  String get goalChecks => 'チェック';

  @override
  String get goalBoundaries => '境界';

  @override
  String get goalStopWhen => '停止して確認する条件';

  @override
  String get goalNoMachineCheck => '機械的なチェックはありません。レビュー担当者は読み取れる内容から判断します。';

  @override
  String get goalCheckEnvironment => '環境のタスク';

  @override
  String goalLastCheck(int round, String time) {
    final intl.NumberFormat roundNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String roundString = roundNumberFormat.format(round);

    return '前回のチェック、ラウンド $roundString、$time';
  }

  @override
  String get goalClaim => 'エージェントの主張';

  @override
  String get goalCheckPassed => '合格';

  @override
  String goalCheckFailed(int code) {
    return '失敗、終了コード $code';
  }

  @override
  String get goalCheckTimedOut => '時間切れ';

  @override
  String get goalCheckNotRerun => '再実行なし: 変更がありません';

  @override
  String get goalCheckBroken => '実行できません';

  @override
  String get goalCriterionMet => '達成';

  @override
  String get goalCriterionUnmet => '未達成';

  @override
  String get goalCriterionCannotTell => '判断できません';

  @override
  String get goalVerdictPass => '判定: 完了';

  @override
  String get goalVerdictFail => '判定: 未完了';

  @override
  String get goalVerdictCannotVerify => '判定: 判断できませんでした';

  @override
  String get goalConcerns => '懸念点';

  @override
  String goalVerifiedBy(String agent) {
    return '$agentが検証';
  }

  @override
  String get goalVerifiedBySelf => '自身で検証（別のチェッカーなし）';

  @override
  String get goalClosedByPerson => '合格したチェックなしに、担当者が閉じました';

  @override
  String get goalApprove => '完了を承認';

  @override
  String get goalApproveTitle => 'このゴールを完了として閉じますか？';

  @override
  String get goalApproveBody =>
      'どのチェックもこれを確認していません。あなた自身の判断で閉じ、ゴールには担当者が未検証のまま閉じたことが記録されます。';

  @override
  String get goalApproveConfirm => '完了として閉じる';

  @override
  String get goalResumeNotYours => '再開や予算の引き上げは、開始した担当者だけができます。';

  @override
  String get goalChooseChecker => '別のチェッカーを選ぶ';

  @override
  String goalCheckerSet(String agent) {
    return '$agentが今チェックします。再開すると、もう一度検証します。';
  }

  @override
  String get goalSchedules => 'スケジュール';

  @override
  String get goalRepeat => '繰り返す';

  @override
  String get goalCreateChecks => 'チェック（任意）';

  @override
  String get goalCreateCheckHint => '作業が完了したときに合格するコマンド';

  @override
  String get goalCreateAddCheck => 'チェックを追加';

  @override
  String get goalCreateRemoveCheck => 'チェックを削除';

  @override
  String get goalCreateSegmentCap => 'セグメントの上限（任意）';

  @override
  String get goalCreateSegmentInvalid => 'セグメントの上限は、1以上の整数で入力してください。';

  @override
  String get scheduleCreateTitle => 'プロンプトを繰り返す';

  @override
  String get scheduleCadence => '頻度';

  @override
  String get scheduleEveryMinutes => 'N分ごと';

  @override
  String get scheduleEveryHours => 'N時間ごと';

  @override
  String get scheduleSelfPaced => '自動調整';

  @override
  String get scheduleSelfPacedHint => 'エージェントは各実行の後に、次までの間隔を1分から1時間の間で選びます。';

  @override
  String get scheduleInterval => '間隔';

  @override
  String get scheduleNote => '各実行では何をしますか？';

  @override
  String get scheduleCostCap => 'コスト上限（USD、任意）';

  @override
  String get scheduleExpiryDays => 'N日後に終了（任意）';

  @override
  String get scheduleCreateInvalid =>
      'スペースとエージェントを選び、各実行の内容を入力し、1以上の整数を入力してください。';

  @override
  String get scheduleCreateButton => 'スケジュールを開始';

  @override
  String get scheduleCreateConfirmTitle => 'このスケジュールを開始しますか？';

  @override
  String scheduleCreateConfirmEveryMinutes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString分ごとに、今から実行されます。',
      one: '1分ごとに、今から実行されます。',
    );
    return '$_temp0';
  }

  @override
  String scheduleCreateConfirmEveryHours(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString時間ごとに、今から実行されます。',
      one: '1時間ごとに、今から実行されます。',
    );
    return '$_temp0';
  }

  @override
  String get scheduleCreateConfirmSelfPaced =>
      '今すぐ実行され、その後はエージェントが次の実行時刻を選びます。';

  @override
  String get scheduleCreated => 'スケジュールを開始しました。スケジュールの下に表示されます。';

  @override
  String get schedulesTitle => 'スケジュール';

  @override
  String get schedulesLoadFailed => 'スケジュールを読み込めませんでした';

  @override
  String get schedulesEmpty => 'スケジュールも監視もありません';

  @override
  String get schedulesEmptyDescription =>
      'ゴールの画面からプロンプトを繰り返すか、会話で /loop または /schedule を送ってください。';

  @override
  String get scheduleMissing => 'このスケジュールは、このワークスペースではもう利用できません。';

  @override
  String scheduleEvery(String interval) {
    return '$intervalごと';
  }

  @override
  String get scheduleSelfPacedLoop => '自動調整ループ';

  @override
  String get scheduleCron => 'cron スケジュール';

  @override
  String scheduleOnce(String time) {
    return '$timeに1回';
  }

  @override
  String scheduleWatch(String event) {
    return '監視: $event';
  }

  @override
  String get scheduleWatchPrChecks => 'プルリクエストのチェック';

  @override
  String get scheduleWatchPrReview => 'プルリクエストのレビュー';

  @override
  String get scheduleWatchPrMerged => 'プルリクエストのマージ';

  @override
  String get scheduleWatchEnvironment => '環境';

  @override
  String get scheduleWatchTicket => 'チケット';

  @override
  String get scheduleWatchPipelineRun => 'パイプラインの実行';

  @override
  String get scheduleStatusActive => 'アクティブ';

  @override
  String get scheduleStatusPaused => '一時停止中';

  @override
  String get scheduleStatusEnded => '終了';

  @override
  String scheduleWakes(String agent) {
    return '起動するエージェント: $agent';
  }

  @override
  String scheduleNext(String time) {
    return '次回の実行 $time';
  }

  @override
  String scheduleLast(String time) {
    return '前回の実行 $time';
  }

  @override
  String scheduleRuns(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '実行 $countString回',
      one: '実行 1回',
    );
    return '$_temp0';
  }

  @override
  String scheduleRunsOf(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return '$countString / $maxString 回';
  }

  @override
  String scheduleSkipped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'スキップ $countString回',
      one: 'スキップ 1回',
    );
    return '$_temp0';
  }

  @override
  String scheduleEnds(String time) {
    return '$timeに終了';
  }

  @override
  String scheduleChain(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'チェーンの一部: 残り $countString 回、$timeに終了';
  }

  @override
  String get scheduleNoteAgent => 'エージェント自身のノート（本人の言葉）:';

  @override
  String get scheduleNotePerson => '担当者のノート:';

  @override
  String scheduleActsFor(String name) {
    return '担当: $name';
  }

  @override
  String get scheduleActsForBot => '担当者なし';

  @override
  String get scheduleGoalBound => 'ゴールとともに終了します。';

  @override
  String get schedulePause => '一時停止';

  @override
  String get scheduleResume => '再開';

  @override
  String get scheduleDelete => '終了';

  @override
  String get scheduleRemove => '削除';

  @override
  String get scheduleDeleteTitle => 'このスケジュールを終了しますか？';

  @override
  String get scheduleDeleteBody => '完全に停止します。すでに行われた内容は取り消されません。';

  @override
  String get scheduleRemoveTitle => 'このスケジュールを削除しますか？';

  @override
  String get scheduleRemoveBody => '一覧から消えます。';

  @override
  String get scheduleResumeNotYours => 'このスケジュールの担当者だけが再開できます。';

  @override
  String get scheduleResumeAdminOnly => '担当者のいないスケジュールは、ワークスペースの管理者だけが再開できます。';

  @override
  String get scheduleOpenConversation => '会話を開く';

  @override
  String get progressWaiting => '待機中';

  @override
  String get progressNothingWaiting => '待機中のものはありません。';

  @override
  String get wakeOriginGoal => 'ゴール';

  @override
  String get wakeOriginGoalCheck => 'ゴールのチェック';

  @override
  String get wakeOriginGoalReview => 'ゴールのレビュー';

  @override
  String get wakeOriginSchedule => 'スケジュール';

  @override
  String get wakeOriginWatch => '監視';

  @override
  String get wakeOriginReply => '返信';

  @override
  String get wakeOriginMessage => 'メッセージ';

  @override
  String get wakeOriginWorkFinished => '完了した作業';

  @override
  String get wakeOriginLimitReset => '上限のリセット';

  @override
  String get wakeOriginRecovery => '復旧';

  @override
  String get wakeOriginAssignment => '割り当て';

  @override
  String get wakeOriginPipelineStep => 'パイプラインのステップ';

  @override
  String get wakeOriginImprovementReview => '改善のレビュー';

  @override
  String wakeOriginReplyFrom(String agent) {
    return '$agentからの返信';
  }

  @override
  String wakeOriginMessageFrom(String agent) {
    return '$agentからのメッセージ';
  }

  @override
  String wakeOriginWorkFinishedBy(String agent) {
    return '$agentが完了した作業';
  }

  @override
  String wakeFor(String agent) {
    return '$agent向け';
  }

  @override
  String wakeDue(String time) {
    return '$timeに実行予定';
  }

  @override
  String get wakeDueNow => 'まもなく実行';

  @override
  String get wakeHeld => '保留中';

  @override
  String wakeExpires(String time) {
    return '$timeに期限切れ';
  }

  @override
  String wakeAttempt(int attempt) {
    final intl.NumberFormat attemptNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String attemptString = attemptNumberFormat.format(attempt);

    return '試行 $attemptString';
  }

  @override
  String get wakeCancel => 'キャンセル';

  @override
  String get wakeDeliverNow => '今すぐ配信';

  @override
  String get wakeResume => '再開';

  @override
  String get wakeDismiss => '破棄';

  @override
  String get wakeResumeOnlyTheirs => 'この実行の担当者だけが再開できます。';

  @override
  String get wakeRecovery => 'サーバーがこの実行中に再起動しました。再開して続行するか、破棄してください。';

  @override
  String limitParkTitle(String provider, String time) {
    return '$providerの使用上限に達したため一時停止中です。上限は$timeにリセットされます。実行はリセット後最大7日間、再開を待ちます。';
  }

  @override
  String limitParkTitleUnnamed(String time) {
    return 'プロバイダーの使用上限に達したため一時停止中です。上限は$timeにリセットされます。実行はリセット後最大7日間、再開を待ちます。';
  }

  @override
  String get limitParkResumeNow => '今すぐ再開';

  @override
  String get limitParkCancel => 'キャンセル';

  @override
  String limitParkResumed(String provider) {
    return '$providerの利用上限の後に再開しました。';
  }

  @override
  String limitParkGone(String provider) {
    return '$providerの利用上限での待機は終了しました。';
  }

  @override
  String get limitParkProviderUnknown => 'プロバイダー';

  @override
  String get mobileHeldMessages => '保留中のメッセージ';

  @override
  String get heldSteeringTitle =>
      '実行が保留中のメッセージを受け取る前に終了したため、保留されています。今すぐ自分のメッセージを送るか、削除してください。';

  @override
  String get heldSteeringRelease => '保留中のメッセージを送信';

  @override
  String get notifGoalCompleted => 'ゴールが完了';

  @override
  String get notifGoalFailed => 'ゴールが失敗';

  @override
  String get notifGoalCancelled => 'ゴールがキャンセル';

  @override
  String get notifGoalBudgetExhausted => 'ゴールが予算を使い切りました';

  @override
  String get notifGoalNeedsReview => 'ゴールがレビューを待っています';

  @override
  String get notifGoalNeedsPerson => 'ゴールに担当者の対応が必要です';

  @override
  String get notifGoalOnHold => 'ゴールが保留中です';

  @override
  String get notifWakeRuleEnded => 'スケジュールが終了しました';

  @override
  String notifWaitingDigest(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '待機中の項目が $countString件あります',
      one: '待機中の項目が 1件あります',
    );
    return '$_temp0';
  }

  @override
  String notifImprovementProposed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '改善案 $countString件が提案されました',
      one: '改善案が提案されました',
    );
    return '$_temp0';
  }

  @override
  String get notifPipelineRunHeld => 'パイプラインの実行が予算で保留されました';

  @override
  String notifPipelineRunHeldBody(String spent, String cap) {
    return '$spent / $cap 使用';
  }

  @override
  String get notifNeedsYou => '要対応';

  @override
  String get notifDigestGoalReview => 'ゴールがレビューを待っています';

  @override
  String get notifDigestGoalPerson => 'ゴールに担当者の対応が必要です';

  @override
  String get notifDigestHeldWake => '保留中の起動予約';

  @override
  String get notifDigestImprovement => '提案された改善';

  @override
  String get wakeKindRulePaused => 'スケジュールが一時停止中でした。';

  @override
  String get wakeKindRuleBusy => 'エージェントは取り込み中で、このスケジュールは取り込み中の時刻をスキップする設定です。';

  @override
  String get wakeKindRuleFolded => '同じ監視の後のイベントに置き換わりました。';

  @override
  String get wakeKindRuleSuperseded => 'スケジュールの後の時刻に置き換えられました。';

  @override
  String get wakeKindRuleNotified => 'このスケジュールは通知のみを送る設定のため、実行は開始されませんでした。';

  @override
  String get wakeKindRuleLimitParked => 'スケジュールは、プロバイダーの利用上限がリセットされるのを待っています。';

  @override
  String get improvementRefusalCooldown =>
      'この会話の改善のレビューは少し前に実行されました。後でもう一度お試しください。';

  @override
  String get improvementRefusalQueued => 'この会話の改善のレビューは、すでに実行待ちです。';

  @override
  String get improvementRefusalAgentNotFound => 'そのエージェントは、このワークスペースにありません。';

  @override
  String get steeringRefusalHeldByLimit =>
      '利用上限で保留されたメッセージは、手動で送信できません。一時停止中の実行が再開するのを待ちます。';

  @override
  String limitParkCancelled(String provider) {
    return '$providerの利用上限での待機はキャンセルされました。';
  }

  @override
  String limitParkExpired(String provider) {
    return '実行が再開する前に、$providerの利用上限での待機が期限切れになりました。';
  }

  @override
  String limitParkSkipped(String provider) {
    return '実行は$providerの利用上限の後に再開しませんでした。';
  }

  @override
  String get heldSteeringLimitTitle =>
      '実行が使用上限のリセットを待っている間、保留中です。実行の担当者が再開すると送信されます。';

  @override
  String heldSteeringLimitAt(String time) {
    return '使用上限が$timeにリセットされるまで保留中です。実行の担当者が再開すると送信されます。';
  }

  @override
  String get heldSteeringOtherTitle => 'サーバーが保留中です。削除できます。';

  @override
  String workRowWoke(int count, String agent) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '待機中の $countString件のため$agentを起動しました',
      one: '$agentを起動しました',
    );
    return '$_temp0';
  }

  @override
  String workRowWakeMissed(String agent) {
    return '$agentへの起動予約は、サーバーの停止中に逃されました。';
  }

  @override
  String workRowWakeSkipped(String agent) {
    return '$agentへの起動予約は配信されませんでした。';
  }

  @override
  String workRowScheduleCreated(String agent) {
    return '$agentのスケジュールを設定しました。';
  }

  @override
  String workRowScheduleEnded(String agent) {
    return '$agentのスケジュールが終了しました。';
  }

  @override
  String workRowNoteFromAgent(String agent) {
    return '$agentからのスケジュールのノート:';
  }

  @override
  String get workRowNoteFromPerson => '担当者からのスケジュールのノート:';

  @override
  String workRowCommandRefusedNamed(String command) {
    return '$commandコマンドは拒否されました。';
  }

  @override
  String get workRowCommandRefused => 'コマンドは拒否されました。';

  @override
  String workRowCapRaised(String person, String from, String to) {
    return '$personがパイプラインの支出上限を $from から $to に引き上げました。';
  }

  @override
  String workRowCapRaisedNoAmounts(String person) {
    return '$personがパイプラインの支出上限を引き上げました。';
  }

  @override
  String get workRowApplyIncomplete =>
      'このスキルへの承認済みの変更は、その間にスキルが変わったため完了できませんでした。提案はロールバックされました。';

  @override
  String get workRowOpenSchedule => 'スケジュールを開く';

  @override
  String get heldSteeringOthersTitle =>
      '実行が受け取る前に終了したため、保留されています。保留中のメッセージを送信できるのは、書いた人だけです。';

  @override
  String get heldSteeringOnlyYours =>
      'あなたのメッセージだけを送信します。他の人のメッセージは、書いた人のために待機します。';

  @override
  String heldSteeringWrittenBy(String name) {
    return '$nameが書いたメッセージ';
  }

  @override
  String get steeringRefusalNotYours =>
      '保留中のメッセージを送信できるのは、書いた人だけです。これらはいずれもあなたのものではありません。';

  @override
  String get steeringRefusalNeedsWrite =>
      'ほかの人の代わりに動いている実行に指示を送るには、このスペースのリポジトリへの書き込み権限が必要です。';

  @override
  String workRowSchedulePaused(String name, String agent) {
    return '$nameが$agentのスケジュールを一時停止しました。';
  }

  @override
  String get goalVerdictObjective => '目的全体';

  @override
  String get notifDigestRequest => 'あなたの回答を待っています';
}
