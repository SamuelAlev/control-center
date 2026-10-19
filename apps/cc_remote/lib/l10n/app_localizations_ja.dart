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
  String get permissionPrPublish => 'プルリクエストを公開';

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
  String get permissionRemembered => '記憶された承認';

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
  String get permissionRevokeBeforeEdit =>
      'この操作に共通のルールを設定する前に、スコープ限定または記憶されたルールを取り消してください。';

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
  String get mobileGoalGoal => '目標';

  @override
  String get mobileGoalLoop => 'ループ';

  @override
  String mobileGoalKind(String kind) {
    return '種類: $kind';
  }

  @override
  String mobileGoalRuns(String count) {
    return '実行$count回';
  }

  @override
  String get mobileGoalNoRunLimit => '無制限';

  @override
  String mobileGoalProgress(
    String runs,
    String maxRuns,
    String spent,
    String cap,
  ) {
    return '実行: $runs / $maxRuns · 使用額: $spent / $cap';
  }

  @override
  String mobileGoalDeadline(String date) {
    return '期限: $date';
  }

  @override
  String mobileGoalFailures(String count) {
    return '連続失敗回数: $count';
  }

  @override
  String get mobileGoalSummary => '完了時の概要';

  @override
  String get mobileGoalFailedDescription =>
      '実行の失敗が続いたため監督機能が停止しました。詳細は会話を確認してください。';

  @override
  String get mobileGoalBudgetWall =>
      '期限または実行回数の上限に達しました。費用上限を引き上げても、このゴールは再開できません。';

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
  String get activityTicket => 'チケットの更新';

  @override
  String get activityMeeting => '会議の更新';

  @override
  String get activityCalendar => 'カレンダーの接続';

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
  String get credentialsRedirectUnavailable =>
      'このサーバーのブラウザーコールバックには、スマートフォンから安全にアクセスできません。公開HTTPSコールバックの設定をサーバーの所有者に依頼するか、代わりにトークンを追加してください。';

  @override
  String get credentialsUpdateToken => 'トークンを更新';

  @override
  String get credentialsAddToken => 'トークンを追加';

  @override
  String get credentialsPersonalToken => '個人用アクセストークン';

  @override
  String get credentialsPersonalTokenHint => '個人用アクセストークンを貼り付け';

  @override
  String get credentialsHostManaged =>
      'この接続はサーバーアプリまたは環境から提供されています。そこで変更できるのはサーバーの所有者だけですが、自分のトークンを追加することはできます。';

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
}
