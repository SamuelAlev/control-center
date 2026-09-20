// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get succeeded => '成功';

  @override
  String agentRunRetryLabel(int number, String time) {
    return '再試行 #$number · $time';
  }

  @override
  String agentRunStarting(String time) {
    return '開始中 · $time';
  }

  @override
  String get agentActivityFollowingLive => 'ライブのアクティビティを追跡中';

  @override
  String get agentActivityJumpToLatest => '最新へジャンプ';

  @override
  String get agentActivityLoadFailed => 'この実行のアクティビティを読み込めませんでした';

  @override
  String get agentActivityNotRecorded => 'この実行のアクティビティは記録されていません';

  @override
  String get agentActivityNotRecordedHint =>
      'アクティビティの記録が有効になる前に終了した実行には、タイムラインがありません。';

  @override
  String get agentActivityRunUnavailable => 'この実行は利用できなくなりました';

  @override
  String agentActivitySubagentOf(String agent) {
    return '$agent のサブエージェント';
  }

  @override
  String get agentActivityUnsupported => '接続中のサーバーではアクティビティの記録を利用できません';

  @override
  String get agentActivityUnsupportedHint => '最新のサーバービルドを反映するため、アプリを再起動してください。';

  @override
  String get agentActivityWaiting => 'アクティビティを待機中…';

  @override
  String get created => '作成';

  @override
  String get dictationStart => '音声入力を開始';

  @override
  String get dictationListening => '聞き取り中…';

  @override
  String get dictationUnavailable =>
      '音声入力には、サーバーホスト上の音声モデルが必要です。音声設定でセットアップしてください。';

  @override
  String get dictationFailedToStart => '音声入力を開始できませんでした';

  @override
  String get dictationHoldToTalkTitle => '長押しで話す';

  @override
  String get dictationHoldToTalkDescription =>
      'マイクボタンまたはショートカットを押し続けて音声入力し、離すと停止します。オフのときは、一度押して開始し、もう一度押して停止します。';

  @override
  String get focusConversation => '会話にフォーカス';

  @override
  String get ideAgentActivity => 'エージェントのアクティビティ';

  @override
  String get keybindingPushToTalk => 'プッシュトゥトーク';

  @override
  String get keybindingPushToTalkDescription => 'メッセージ入力欄で音声入力を長押しまたは切り替えます';

  @override
  String get agentPermissions => 'エージェントの権限';

  @override
  String get agentPermissionsSettingsDescription =>
      'エージェントが単独で実行できること、事前に確認が必要なこと、実行できないことを、ワークスペース、エージェント、またはスペースごとに決めます。';

  @override
  String get agentPermissionsMatrixDescription =>
      '効果の種類ごとに判定を設定します。ルールはカスケードします。スペースがエージェントより優先し、エージェントがワークスペースより優先し、ワークスペースがモードのプリセットより優先します。最も具体的なルールが適用されます。';

  @override
  String get guardrailLoading => 'ルールを読み込み中…';

  @override
  String get guardrailRulesLoadFailed => '権限ルールを読み込めませんでした。';

  @override
  String get guardrailScopeWorkspace => 'ワークスペース';

  @override
  String get guardrailScopeAgent => 'エージェント';

  @override
  String get guardrailScopeSpace => 'スペース';

  @override
  String get guardrailSelectAgent => 'エージェントを選択';

  @override
  String get guardrailSelectSpace => 'スペースを選択';

  @override
  String get guardrailNoAgents => 'このワークスペースにはまだエージェントがありません。';

  @override
  String get guardrailNoSpaces => 'このワークスペースにはまだスペースがありません。';

  @override
  String get guardrailClassFileDelete => 'ファイルを削除';

  @override
  String get guardrailClassFileWriteOutsideWorktree => 'ワークツリー外への書き込み';

  @override
  String get guardrailClassGitCommit => 'コミットを作成';

  @override
  String get guardrailClassGitPush => 'リモートへプッシュ';

  @override
  String get guardrailClassPrCreate => 'プルリクエストを作成';

  @override
  String get guardrailClassPrPublish => 'レビューの公開またはマージ';

  @override
  String get guardrailClassVendorSyncWrite => '外部トラッカーへの書き込み';

  @override
  String get guardrailClassNetworkEgress => 'ネットワークにアクセス';

  @override
  String get guardrailClassSecretAccess => 'シークレットを読み取る';

  @override
  String get guardrailClassPackageInstall => 'パッケージをインストール';

  @override
  String get guardrailClassProcessSpawn => 'プロセスを実行';

  @override
  String get guardrailClassWorkspaceMutation => 'ワークスペース構造の変更';

  @override
  String get guardrailClassEnclosureControl => 'エンクロージャー（リグ）を操作';

  @override
  String get navRigs => 'リグ';

  @override
  String get rigsUnsupportedServer =>
      'このサーバーでは rig サーフェスをホストできません。使用するマシンのホスト要件を確認してください。';

  @override
  String get rigSurfaceComputer => 'コンピュータ';

  @override
  String get rigSurfaceBrowser => 'ブラウザ';

  @override
  String get rigSurfaceAndroid => 'Android';

  @override
  String get rigSurfaceIosSimulator => 'iOSシミュレータ';

  @override
  String rigSurfaceBrowserEngine(String engine) {
    return '$engine';
  }

  @override
  String rigBrowserEngineHint(String engine) {
    return '使い捨ての $engine で、マシンから隔離されています。別のエンジンを開くと、同じページを並べて比較できます。';
  }

  @override
  String get rigPhaseReady => '準備完了';

  @override
  String get rigPhaseStarting => '起動中';

  @override
  String get rigPhaseParked => 'パーク中';

  @override
  String get rigPhaseClosing => '終了中';

  @override
  String get rigPhaseClosed => '終了';

  @override
  String get rigPhaseFailed => '失敗';

  @override
  String get rigPhaseUnknown => '不明';

  @override
  String get rigNotAccelerated => 'エミュレーション';

  @override
  String get rigAudioListen => 'マシンの音声を聞く';

  @override
  String get rigAudioMute => 'マシンをミュート';

  @override
  String get rigYouHaveControl => '操作できます';

  @override
  String get rigBackendAvailable => '利用可能';

  @override
  String get rigBackendUnavailable => '利用不可';

  @override
  String get rigEgressNotEnforced =>
      'このバックエンドではネットワークは隔離されていません。接続はバックエンド側で管理されます。';

  @override
  String get rigStartMachine => 'マシンを起動';

  @override
  String get rigStartHint =>
      'この会話でエージェントと共有する使い捨ての VM を起動します。終了すると破棄され、中身はコンピュータに影響しません。';

  @override
  String get rigStartAndroidHint =>
      'サーバーですでに実行中の Android エミュレーターに接続します。ネットワークアクセスは隔離されません。';

  @override
  String get rigStartIosHint =>
      'サーバーの Mac 上に使い捨ての iOS Simulator を作成します。テスト環境を閉じると削除されます。ネットワークアクセスは隔離されません。';

  @override
  String get rigTechnicalDetails => '技術的な詳細';

  @override
  String get rigStopMachine => 'マシンを停止';

  @override
  String get rigSurfaceUnavailable => 'このサーバーではこの種類のマシンをホストできません。';

  @override
  String get rigTabNeedsConversation =>
      '先に会話を開いてください。マシンは会話に紐づくため、エージェントと同じ画面を見られます。';

  @override
  String get ideMenuSectionTools => 'ツール';

  @override
  String get ideMenuSectionMachines => 'マシン';

  @override
  String get ideMenuSectionReopen => '再度開く';

  @override
  String get ideMenuSearchHint => '検索';

  @override
  String get ideMenuNoMatches => '一致なし';

  @override
  String get rigMenuComputer => 'コンピュータ';

  @override
  String get rigMenuBrowser => 'ブラウザ';

  @override
  String get rigMenuAndroid => 'Android';

  @override
  String get rigMenuIosSimulator => 'iOSシミュレータ';

  @override
  String rigLabelNumbered(String label, String suffix) {
    return '$label $suffix';
  }

  @override
  String ideCloseKeepTitle(String name) {
    return '$name を閉じますか？';
  }

  @override
  String get ideCloseKeepBodyMachine =>
      'マシンはバックグラウンドで実行を続けます。サイドバーからいつでも再度開けます。今すぐメモリを解放するには、シャットダウンしてください。';

  @override
  String get ideCloseKeepBodyShell =>
      'コマンドはバックグラウンドで実行を続けます。サイドバーからいつでもシェルを再度開けます。今すぐ処理を止めるには、シェルを終了してください。';

  @override
  String get ideCloseKeepBodyAgent =>
      'エージェントはバックグラウンドで作業を続けます。サイドバーからいつでも会話を再度開けます。今すぐ実行を終えるには、停止してください。';

  @override
  String get ideCloseKeepRunning => '実行を続ける';

  @override
  String get ideCloseShutDownMachine => 'シャットダウン';

  @override
  String get ideCloseEndShell => 'シェルを終了';

  @override
  String get ideCloseStopAgent => 'エージェントを停止';

  @override
  String get rigsSettingsSubtitle => 'このサーバーが起動できるもの、必要なベースイメージ、現在実行中のマシン';

  @override
  String get rigsCapabilitiesTitle => 'このサーバー';

  @override
  String get rigInstallIosAutomation => 'iOS 自動化ブリッジをインストール';

  @override
  String get rigInstallingIosAutomation => 'iOS 自動化ブリッジをインストールしています…';

  @override
  String get rigIosAutomationInstalled => 'iOS 自動化ブリッジがインストールされました';

  @override
  String get rigsImagesTitle => 'ベースイメージ';

  @override
  String get rigsImagesHint =>
      '各リグはこれらの読み取り専用イメージのいずれかから起動します。セッションの書き込みは使い捨てのオーバーレイに行われるため、あるリグが次のリグの起動元を変えることはありません。';

  @override
  String get rigsRunningTitle => '実行中';

  @override
  String get rigsNoneRunning => '実行中のマシンはありません。';

  @override
  String get rigsCustomImagesTitle => 'カスタムイメージ（このワークスペース）';

  @override
  String get rigsCustomImagesHint =>
      'Terminal (VM) または Browser (VM) に独自のイメージを指定できます。プロジェクトに必要なツールでデフォルトを拡張するか、レジストリの互換イメージを使います。新しいマシンはそれを使い、実行中のマシンは現在のイメージのままです。イメージに必要なものはリグのガイドをご覧ください。';

  @override
  String get rigsCustomTerminalImageLabel => 'ターミナル（VM）イメージ';

  @override
  String get rigsCustomBrowserImageLabel => 'ブラウザ（VM）イメージ';

  @override
  String get rigsCustomImagePlaceholder =>
      '例: ghcr.io/acme/dev-shell:1.2 — 空欄でデフォルト';

  @override
  String get rigsCustomImageInvalid =>
      'repo/name:tag のようなレジストリ参照を入力してください。ローカルパスやアーカイブは使えません。';

  @override
  String get rigsCustomImageSaved =>
      '保存しました。新しいマシンはこのイメージで起動します。実行中のマシンは現在のイメージのままです。';

  @override
  String get rigsEgressTitle => 'ブラウザのエグレス（このワークスペース）';

  @override
  String get rigsEgressHint =>
      '隔離されたブラウザが追加で到達できるホストです。1行に1つ、完全一致のホスト（api.example.com）またはそのサブドメイン用のワイルドカード（*.example.com）を指定します。プロダクトのサイトはいずれの場合も許可されたままです。新しいマシンにこの一覧が適用されます。実行中のマシンは起動時の設定のままです。';

  @override
  String rigsEgressInvalid(String host) {
    return '「$host」は有効なホストの指定ではありません。';
  }

  @override
  String get rigsEgressSaved =>
      '保存しました。新しいブラウザマシンはこれらのホストを許可します。実行中のマシンは現在の設定のままです。';

  @override
  String get rigImageInstalled => 'インストール済み';

  @override
  String get rigImageNotDownloaded => '未ダウンロード';

  @override
  String get rigImageNotPublished => '未公開';

  @override
  String get rigImageNotPublishedHint =>
      'まだイメージが公開されていないため、ダウンロードするものがありません。対応するディスクイメージをインポートすると有効になります。';

  @override
  String get rigImageDownload => 'ダウンロード';

  @override
  String get rigImageDownloading => 'ダウンロード中…';

  @override
  String get rigImageImport => 'インポート';

  @override
  String get rigImageImportMessage =>
      'サーバーのファイルシステム上にある qcow2 ディスクイメージのパスです。イメージストアにコピーされるため、元のファイルはその後移動できます。';

  @override
  String get rigConnectingStream => 'リグに接続しています';

  @override
  String get rigStreamNotAllowed => 'このリグにアクセスする権限がありません。';

  @override
  String get rigStreamNotRunning => 'このリグはすでに実行されていません。';

  @override
  String get rigStreamNeedsFfmpeg =>
      'ライブビューにはこのホストに ffmpeg が必要です。ffmpeg をインストールしてタブを開き直してください。';

  @override
  String get rigStreamEnded => 'ライブビューが終了しました。';

  @override
  String get rigStreamFailed => 'ライブビューを開けませんでした。';

  @override
  String get rigStreamDisconnected => 'サーバーに接続していません。';

  @override
  String rigDropSendingOne(String name) {
    return '「$name」をマシンにコピーしています…';
  }

  @override
  String rigDropSendingMany(int count) {
    return '$count 件のファイルをマシンにコピーしています…';
  }

  @override
  String get rigTerminalDropSending => 'マシンにコピーしています…';

  @override
  String get rigTerminalPasteImage => '貼り付けた画像をマシンに保存しました';

  @override
  String get rigPortsTitle => '転送ポート';

  @override
  String get rigPortsTooltip => 'このマシン内で開いているポート';

  @override
  String get rigPortsEmpty =>
      'まだリッスンしているものはありません。ターミナルでサーバーを起動してください。ポート 3000 の開発サーバーなどはここに表示されます。';

  @override
  String get rigPortsAdd => 'ポートを追加';

  @override
  String get rigPortsAddHint => '転送するゲストのポート（例: 3000）';

  @override
  String get rigPortsAutoForward => 'ポートを自動転送';

  @override
  String get rigPortsCopyUrl => 'ローカル URL をコピー';

  @override
  String rigPortsCopiedUrl(String url) {
    return '$url をコピーしました';
  }

  @override
  String get rigPortsStopForward => '転送を停止';

  @override
  String get rigPortsExposeLan => 'ローカルネットワークで共有';

  @override
  String get rigPortsLanPrivate => 'ローカルのみ';

  @override
  String get rigPortsLanShared => 'ネットワーク上';

  @override
  String get rigPortsSetDomain => 'ブラウザのドメインを設定（.test）';

  @override
  String get rigPortsDomainHint =>
      'ブラウザ（VM）用のドメインです。例: myapp.test — そちらからアクセスでき、ホスト側では使えません';

  @override
  String get rigPortsProcessUnknown => '不明なプロセス';

  @override
  String get rigPortsInactive => '未リッスン';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ダウンロード待ちのベースイメージが $count 件あります',
      one: 'ダウンロード待ちのベースイメージが 1 件あります',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => '許可';

  @override
  String get guardrailDecisionPrompt => '先に確認';

  @override
  String get guardrailDecisionDeny => '拒否';

  @override
  String get guardrailSourceThisScope => 'このスコープ';

  @override
  String get guardrailSourceDefault => '組み込みのデフォルト';

  @override
  String get guardrailSourcePreset => 'モードプリセット';

  @override
  String get guardrailSourceInherited => '継承';

  @override
  String get guardrailClearToInherited => '継承に戻す';

  @override
  String get guardrailWhatIf => 'もしも？';

  @override
  String get guardrailWhatIfDescription =>
      '現在のルールがアクションをどのように判定するかを、エージェントと同じロジックで確認できます。';

  @override
  String get guardrailProbeActionLabel => 'アクション';

  @override
  String get guardrailProbeCommandLabel => 'コマンド（任意）';

  @override
  String get guardrailProbeCommandHint => '例: git push origin main';

  @override
  String get guardrailProbeAgentLabel => 'エージェント（任意）';

  @override
  String get guardrailProbeSpaceLabel => 'スペース（任意）';

  @override
  String get guardrailProbeNone => 'なし';

  @override
  String get guardrailProbeModeLabel => 'モード';

  @override
  String get guardrailProbeResult => '結果';

  @override
  String get guardrailProbeSource => 'ソース:';

  @override
  String get guardrailAdapterMatrix => 'ルールの適用箇所';

  @override
  String get guardrailAdapterMatrixDescription =>
      '各エージェントランナーで、どの効果が実際に捕捉されるかを示す参考情報です。保証ではなく実態の記録です。ランナーが帯域外で行う効果はインターセプトできません。';

  @override
  String get guardrailEffectColumn => '効果';

  @override
  String get guardrailAdapterHarness => '内蔵ハーネス';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => 'サンドボックス下限';

  @override
  String get guardrailEnforcementPolicyGate => 'ポリシーゲート';

  @override
  String get guardrailEnforcementSandbox => 'サンドボックスのみ';

  @override
  String get guardrailEnforcementNone => '強制不可';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      '効果が実行される前に権限判定が行われ、ブロックできます。';

  @override
  String get guardrailEnforcementSandboxHelp =>
      'サンドボックスのみが制約します。権限ルールは参照されません。';

  @override
  String get guardrailEnforcementNoneHelp => '判定は参考情報のみです。ここではインターセプトできません。';

  @override
  String get obsStatCost => 'コスト';

  @override
  String obsStatDelegatedCost(String amount) {
    return '+$amount 委任分';
  }

  @override
  String get obsStatDuration => '所要時間';

  @override
  String get obsStatTokens => 'トークン';

  @override
  String get obsStatTools => 'ツール';

  @override
  String get openAgentActivity => 'アクティビティを開く';

  @override
  String get orgChart => '組織図';

  @override
  String get orgChartEmpty => 'エージェントはまだありません';

  @override
  String get navCalendar => 'カレンダー';

  @override
  String get serverConnection => 'サーバー接続';

  @override
  String get serverModeLocal => 'このアプリで実行';

  @override
  String get serverModeLocalDescription =>
      'Control Center がこのマシン上でサーバーを起動し、データはローカルで管理します。';

  @override
  String get serverModeRemote => 'リモートインスタンスに接続';

  @override
  String get serverModeRemoteDescription =>
      '別の場所で稼働している Control Center サーバーに接続します。データはそのサーバー上にあります。';

  @override
  String get serverRemoteUrl => 'サーバー URL';

  @override
  String get serverRemoteDeviceId => 'デバイス ID';

  @override
  String get serverRemotePairingKey => 'ペアリングキー';

  @override
  String get serverRemotePairingKeyHint => 'リモートサーバーのペアリングキーを貼り付けてください';

  @override
  String get serverSetupInviteCode => '招待コード';

  @override
  String get serverSetupInviteCodeHint =>
      'ワンタイムの招待コードを貼り付けてください（空欄の場合はペアリングキーを使用します）';

  @override
  String get serverDiscoveryTooltip => 'ネットワーク上のサーバーを探す';

  @override
  String get serverDiscoveryTitle => 'ネットワーク上のサーバー';

  @override
  String get serverDiscoverySearching => 'サーバーを検索しています…';

  @override
  String get serverDiscoveryEmpty =>
      'サーバーが見つかりませんでした。サーバーが起動していて、このデバイスから接続できることを確認してから、もう一度検索してください。';

  @override
  String get serverDiscoveryRefresh => '再検索';

  @override
  String get serverListActive => '使用中';

  @override
  String get serverListSwitch => '切り替え';

  @override
  String get serverListAddTitle => 'サーバーを追加';

  @override
  String get serverListRemoveActiveHint => 'このサーバーを削除する前に、別のサーバーに切り替えてください。';

  @override
  String get serverSwitchFailedTitle => 'サーバーを切り替えられませんでした';

  @override
  String get serverListInsecureBadge => '安全でない';

  @override
  String get connectionPathLocal => 'ローカル';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => 'シャットダウン中';

  @override
  String get shutdownSubtitle => 'ローカルサーバーを閉じています';

  @override
  String get shutdownServiceApprovals => '承認';

  @override
  String get shutdownServiceBackgroundJobs => 'バックグラウンドジョブ';

  @override
  String get shutdownServiceScheduler => 'ジョブスケジューラー';

  @override
  String get shutdownServiceCalendar => 'カレンダー同期';

  @override
  String get shutdownServiceWeather => '天気';

  @override
  String get shutdownServiceSoundscape => 'サウンドスケープ';

  @override
  String get shutdownServiceMeetings => 'ミーティング';

  @override
  String get shutdownServiceVoiceModels => '音声モデル';

  @override
  String get shutdownServiceNetworking => 'ネットワーキング';

  @override
  String get shutdownServicePresence => 'プレゼンス';

  @override
  String get shutdownServiceDataSync => 'データ同期';

  @override
  String get shutdownServiceDeviceRelay => 'デバイスリレー';

  @override
  String get shutdownServiceMcpConnections => 'MCP接続';

  @override
  String get shutdownServiceCodeEditors => 'コードエディター';

  @override
  String get serverSharingTitle => 'このサーバーを共有';

  @override
  String get serverSharingDescription =>
      'ほかのデバイスからこのサーバーにアクセスできるようにします。下記のトンネルをオンにしない限り、外部には公開されません。ペアリング招待にはサーバーの現在のアドレスが自動で埋め込まれます。ワークスペースの設定で作成してください。';

  @override
  String get serverSharingUnavailable => 'このサーバーでは共有の設定を利用できません。';

  @override
  String get serverSharingMdnsLabel => 'LAN検出';

  @override
  String get serverSharingMdnsOn => 'ローカルネットワークでこのサーバーをアドバタイズしています（mDNS）';

  @override
  String get serverSharingMdnsOff => 'ローカルネットワークではアドバタイズしていません（mDNS）';

  @override
  String get serverSharingTunnelLabel => 'トンネル';

  @override
  String get serverSharingTunnelHelper =>
      'トンネルをオンにすると、インターネットからこのサーバーにアクセスできるようになります。公開は任意で、既定ではオフです。';

  @override
  String get serverSharingProviderOff => 'オフ';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => '公開URL';

  @override
  String get serverSharingTunnelStarting => 'トンネルを開始しています…';

  @override
  String serverSharingTunnelError(String error) {
    return 'トンネルエラー: $error';
  }

  @override
  String get serverSharingTunnelUpNoUrl => 'トンネルは稼働しています。設定したDNSホスト名でアクセスできます。';

  @override
  String get serverSharingRelayLabel => 'リレー';

  @override
  String serverSharingRelayUsage(String amount) {
    return '今月のリレー使用量: $amount';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return 'アクティブなリレーセッション: $count';
  }

  @override
  String get serverSharingUpdateFailedTitle => '共有を更新できませんでした';

  @override
  String get pairNewClient => '新しいクライアントをペアリング';

  @override
  String get pairClientNameHint => 'このクライアントの名前（例: 仕事用ノートPC）';

  @override
  String get pairClientTypeWeb => 'Webブラウザー';

  @override
  String get pairClientTypeDesktop => 'デスクトップアプリ';

  @override
  String get pairClientTypePhone => 'スマホ';

  @override
  String get pairAction => 'ペアリング';

  @override
  String get revoke => '取り消し';

  @override
  String get pairCredentialsIntro => 'これらの情報で新しいクライアントを接続するか、その中でリンクを開いてください。';

  @override
  String get pairLinkLabel => 'リンク';

  @override
  String get pairScanQr => 'スマホのカメラでこのQRコードを読み取るとペアリングできます。';

  @override
  String get pairServerUnreachableTitle => '到達できません';

  @override
  String get pairServerUnreachable =>
      '他のデバイスからこのサーバーに直接到達できないため、新しいクライアントは接続できません。さらにクライアントをペアリングするには、サーバーの公開URLを設定してください。';

  @override
  String get serverSetupTitle => 'Control Centerをどのように実行しますか？';

  @override
  String get serverSetupSubtitle =>
      'Control Centerには、データを管理するサーバーが必要です。このアプリ内で起動するか、別の場所で動いているインスタンスに接続してください。';

  @override
  String get serverSetupRunLocal => 'このアプリ内で実行';

  @override
  String get serverSetupConnect => '接続';

  @override
  String get serverSetupInvalidUrl => '有効な ws:// または wss:// のサーバーURLを入力してください。';

  @override
  String get serverSetupCouldNotConnect => '接続できませんでした';

  @override
  String get serverSetupErrorUnreachable =>
      'サーバーに到達できませんでした。起動していることと、このデバイスから到達できること（同一ネットワークまたはリレー）を確認してください。';

  @override
  String get serverSetupErrorIdentityMismatch =>
      'サーバーの識別情報が、このデバイスに保存されているものと一致しません。サーバーを再インストールまたはリセットした場合は、保存済みのサーバーを削除して、再度ペアリングしてください。';

  @override
  String get serverSetupErrorAuthRejected =>
      'サーバーがこのデバイスを拒否しました。ペアリングキーとデバイスIDが、サーバーが発行したものと一致するか確認してください。';

  @override
  String get serverSetupErrorInviteRejected =>
      'その招待コードは無効か、有効期限が切れています。新しいコードを発行してもらってください。';

  @override
  String get serverSetupErrorGeneric => '接続中に問題が発生しました。詳細は下の技術情報を展開してください。';

  @override
  String get serverSetupErrorDetails => '技術情報';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '他$count件',
      one: '他1件',
    );
    return '$_temp0';
  }

  @override
  String get calendarAllDayGutter => '終日';

  @override
  String calendarAllDayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の予定',
      one: '1件の予定',
    );
    return '$_temp0';
  }

  @override
  String get calendarCollapseAllDay => '終日の予定を折りたたむ';

  @override
  String get calendarExpandAllDay => '終日の予定を展開';

  @override
  String get calendarViewMonth => '月';

  @override
  String get calendarViewWeek => '週';

  @override
  String get calendarViewAgenda => '予定一覧';

  @override
  String get calendarConnectGoogle => 'Googleカレンダーを接続';

  @override
  String get calendarConnectDescription =>
      'Googleカレンダーを同期すると、予定がここに表示され、会議開始前に通知を受け取れます。';

  @override
  String get calendarDisconnect => '切断';

  @override
  String get calendarReconnect => '再接続';

  @override
  String get calendarEmptyNoEvents => 'この範囲に予定はありません';

  @override
  String get calendarStartRecording => '録音を開始';

  @override
  String get calendarStartRecordingAndLink => '録音を開始してリンク';

  @override
  String get calendarJoinMeet => '会議に参加';

  @override
  String get calendarFromCalendar => 'カレンダーから';

  @override
  String get calendarLinkedMeeting => 'リンク済みの会議';

  @override
  String get calendarToday => '今日';

  @override
  String get calendarAllDay => '終日';

  @override
  String calendarWeekNumber(int number) {
    return '第$number週';
  }

  @override
  String get calendarPreviousPeriod => '前へ';

  @override
  String get calendarNextPeriod => '次へ';

  @override
  String calendarLastSynced(String time) {
    return '$timeに同期済み';
  }

  @override
  String get calendarNeverSynced => 'まだ同期していません';

  @override
  String get calendarSyncing => '同期中…';

  @override
  String get calendarViewDay => '日';

  @override
  String get calendarShow => '表示';

  @override
  String get calendarHide => '非表示';

  @override
  String get calendarRsvpGoing => '参加しますか？';

  @override
  String get calendarRsvpYes => 'はい';

  @override
  String get calendarRsvpNo => 'いいえ';

  @override
  String get calendarRsvpMaybe => '未定';

  @override
  String get calendarRsvpFailed => '回答を更新できませんでした';

  @override
  String get calendarAddAccount => 'カレンダーアカウントを追加';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Googleアカウントを接続して、このワークスペースに予定を同期します。';

  @override
  String get calendarConnecting => '接続中…';

  @override
  String get calendarSyncNow => '今すぐ同期';

  @override
  String get calendarNoWorkspace => 'カレンダーを表示するワークスペースを選択してください';

  @override
  String get calendarConnectError => 'Google Calendarに接続できませんでした';

  @override
  String get calendarClientIdLabel => 'クライアント ID';

  @override
  String get calendarClientSecretLabel => 'クライアントシークレット';

  @override
  String get calendarConnectCredsHint =>
      'プロジェクトの Google OAuth デバイスコード用クライアント ID とシークレットを入力してください。接続と同期はサーバー側で行われ、ブラウザにトークンは保持されません。';

  @override
  String get calendarConnectApproveInstruction =>
      '任意のデバイスで確認ページを開き、サインインして次のコードを入力してください:';

  @override
  String get calendarConnectOpenPage => '確認ページを開く';

  @override
  String get calendarConnectWaiting => '承認待ち…';

  @override
  String get calendarConnectDenied => '承認が拒否されました。もう一度お試しください。';

  @override
  String get calendarConnectExpired => 'コードの有効期限が切れました。もう一度お試しください。';

  @override
  String get notificationMeetingStartsSoon => 'まもなく会議開始';

  @override
  String get notifyMeetingStartsSoon => 'カレンダーの会議がまもなく始まるとき';

  @override
  String get notificationCalendarAuthExpiredTitle => 'カレンダー切断';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return '$email を再接続して同期を再開してください';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'カレンダーを再接続して同期を再開してください';

  @override
  String get notifyCalendarAuthExpired => 'カレンダーアカウントの再接続が必要なとき';

  @override
  String get notificationRigStatusChanged => 'エンクロージャーの更新';

  @override
  String get notifyRigStatusChanged => 'エンクロージャーがテイクオーバー、回収、または失敗したとき';

  @override
  String get notificationRigTakenOver => 'エンクロージャーのテイクオーバー';

  @override
  String get notificationRigTakenOverBody =>
      '人がマシンを操作しています。エージェントは閲覧できますが、操作はできません。';

  @override
  String get notificationRigReleased => 'エンクロージャーの操作を解放';

  @override
  String get notificationRigReleasedBody => 'エージェントがマシンを再び操作できます。';

  @override
  String get notificationRigReclaimed => 'エンクロージャーを回収';

  @override
  String get notificationRigReclaimedBodyIdle =>
      'アイドル状態だったため、メモリを解放するためにマシンを閉じました。';

  @override
  String get notificationRigReclaimedBodyTtl => '制限時間に達したため、閉じました。';

  @override
  String get notificationRigFailed => 'エンクロージャーの失敗';

  @override
  String get notificationRigFailedBody =>
      'ハイパーバイザーが停止しました。続行するにはマシンを再度開いてください。';

  @override
  String get calendarAlertLeadTime => '事前通知時間';

  @override
  String get calendarAlertLeadTimeSubtitle => '会議の何分前に通知するか';

  @override
  String calendarConnectedAs(String email) {
    return '$email として接続済み';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count 人の出席者';
  }

  @override
  String get calendarEventLabel => '予定';

  @override
  String get calendarRecurring => '繰り返しの予定';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => '主催者';

  @override
  String get calendarYou => '自分';

  @override
  String get calendarShowFewer => '表示を減らす';

  @override
  String get calendarRsvpAwaiting => '未回答';

  @override
  String calendarParticipantsCount(int count) {
    return '$count 人の参加者';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'すべての $count 人の参加者を表示';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count はい';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count いいえ';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count 未定';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count 未回答';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count 分';
  }

  @override
  String get openInEditorPrompt => 'どのエディターで開きますか？';

  @override
  String get ideNotInstalled => '未インストール';

  @override
  String openInIde(String editor) {
    return '$editor で開く';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return '$editor を開けませんでした: $error';
  }

  @override
  String get profileSearchHint => 'プルリクエストを検索…';

  @override
  String get stopAgentRun => '実行を停止';

  @override
  String get stopAgentRunConfirm => 'この実行を停止しますか？進行中の作業は失われます。';

  @override
  String get inProgress => '進行中';

  @override
  String get drafts => '下書き';

  @override
  String get sortOldest => '古い順';

  @override
  String get sortLargest => '大きい順';

  @override
  String get prFilterTooltip => 'フィルター';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件の有効なフィルター',
      one: '1 件の有効なフィルター',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => 'フィルターを追加…';

  @override
  String get prFilterFieldHint => 'フィルター…';

  @override
  String get prFilterCategoryStatus => 'ステータス';

  @override
  String get prFilterCategoryAuthor => '作成者';

  @override
  String get prFilterCategoryReviewer => 'レビュアー';

  @override
  String get prFilterCategoryContent => '内容';

  @override
  String get prFilterCategoryRepoOwner => 'リポジトリのオーナー';

  @override
  String get prFilterCategoryRepoName => 'リポジトリ名';

  @override
  String get prFilterCategoryOpenedDate => 'オープン日';

  @override
  String get prFilterCategoryUpdatedDate => '更新日';

  @override
  String get prFilterQuickToReview => 'レビューしやすい';

  @override
  String get prFilterClearAll => 'フィルターをクリア';

  @override
  String prFilterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のプルリクエスト',
      one: '1 件のプルリクエスト',
    );
    return '$_temp0';
  }

  @override
  String prFilterHiddenOptions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'どのプルリクエストにも一致しないオプションが $count 件',
      one: 'どのプルリクエストにも一致しないオプションが 1 件',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => 'タイトルまたは本文に含む…';

  @override
  String get prFilterNoOptions => '一致するオプションはありません';

  @override
  String get prFilterChipIs => 'が';

  @override
  String get prFilterChipIsAnyOf => 'が次のいずれか';

  @override
  String get prFilterChipContains => 'を含む';

  @override
  String get prFilterChipSince => '以降';

  @override
  String get prFilterAddFilterButton => 'フィルターを追加';

  @override
  String prFilterClearCategory(String category) {
    return '$category のフィルターをクリア';
  }

  @override
  String get prFilterCurrentUser => '現在のユーザー';

  @override
  String get prStatusDraft => '下書き';

  @override
  String get prStatusOpen => 'オープン';

  @override
  String get prStatusInReview => 'レビュー中';

  @override
  String get prStatusChangesRequested => '変更リクエスト';

  @override
  String get prStatusApproved => '承認済み';

  @override
  String get prStatusMerged => 'マージ済み';

  @override
  String get prStatusClosed => 'クローズ';

  @override
  String get prDateWindowDay => '1 日前';

  @override
  String get prDateWindowThreeDays => '3 日前';

  @override
  String get prDateWindowWeek => '1週間前';

  @override
  String get prDateWindowMonth => '1か月前';

  @override
  String get prDateWindowThreeMonths => '3か月前';

  @override
  String get prDateWindowSixMonths => '6か月前';

  @override
  String get prDateWindowYear => '1年前';

  @override
  String get prDisplayOptions => '表示オプション';

  @override
  String get prDisplayGrouping => 'グループ化';

  @override
  String get prDisplayOrdering => '並び順';

  @override
  String get prDisplayShowDrafts => '下書きを表示';

  @override
  String get prDisplayMergedWindow => 'マージ期間';

  @override
  String get prDisplayMergedWindowDay => '過去1日';

  @override
  String get prDisplayMergedWindowWeek => '過去1週間';

  @override
  String get prDisplayMergedWindowMonth => '過去1か月';

  @override
  String get prDisplayProperties => '表示項目';

  @override
  String get prGroupingRepository => 'リポジトリ';

  @override
  String get prGroupingAuthor => '作成者';

  @override
  String get prGroupingStatus => 'ステータス';

  @override
  String get prGroupingNone => 'グループ化なし';

  @override
  String get prPropertyRepository => 'リポジトリ';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => 'ブランチ';

  @override
  String get prPropertyUpdated => '更新日時';

  @override
  String get prPropertyAuthor => '作成者';

  @override
  String get prPropertyChecks => 'チェック';

  @override
  String get prPropertyDiff => '差分';

  @override
  String get prPropertyComments => 'コメント';

  @override
  String get keybindingOpenFilterMenu => 'フィルターメニューを開く';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'プルリクエストのフィルターメニューを開きます';

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件選択中',
      one: '1件選択中',
    );
    return '$_temp0';
  }

  @override
  String get summary => '概要';

  @override
  String get kbMove => '移動';

  @override
  String get kbTabs => 'タブ';

  @override
  String get kbSearch => '検索';

  @override
  String get kbViewed => '既読';

  @override
  String get kbCollapse => '折りたたむ';

  @override
  String get appearance => '外観';

  @override
  String get appearanceSettingsDescription => 'テーマ、言語、タイポグラフィを設定します。';

  @override
  String get notificationsSettingsDescription =>
      '通知するエージェントとワークスペースのイベントを選択します。';

  @override
  String get advanced => '詳細';

  @override
  String get accounts => 'アカウント';

  @override
  String get mcpServers => 'MCPサーバー';

  @override
  String get mcpServersSettingsDescription => '内蔵MCPサーバーと外部MCPサーバーです。';

  @override
  String get remoteControlAndDevices => 'リモート操作とデバイス';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'スマートフォンをペアリングし、リモート操作サーバーを設定します。';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'このサーバーがホストする音声認識と話者分離のモデルです。';

  @override
  String get needsSetupLabel => 'セットアップが必要';

  @override
  String get collapseSidebar => 'サイドバーを折りたたむ';

  @override
  String get expandSidebar => 'サイドバーを展開';

  @override
  String get filterSpacesHint => 'スペースを絞り込み';

  @override
  String noSpacesMatch(String query) {
    return '「$query」に一致するスペースはありません';
  }

  @override
  String get privacy => 'プライバシー';

  @override
  String get sendDiffContentTitle => 'AIアダプターにdiffの内容を送信';

  @override
  String get diffSharingOnSubtitle => 'より深いレビューのため、生のdiff行がエージェントのプロンプトに含まれます。';

  @override
  String get diffSharingOffSubtitle =>
      'エージェントは構造化メタデータ（ファイルパス、行番号、PRの説明）のみを使用します。生のコードはアプリ外に出ません。';

  @override
  String get errorReportingTitle => 'クラッシュレポートを共有';

  @override
  String get errorReportingOnSubtitle =>
      'バグ修正のため、クラッシュ、エラー、パフォーマンスの診断情報が送信されます（リリースビルドのみ）。';

  @override
  String get errorReportingOffSubtitle => '診断はオフです。クラッシュやエラーのレポートは送信されません。';

  @override
  String get onboardingDiagnosticsTitle => 'Control Centerの改善にご協力ください';

  @override
  String get onboardingDiagnosticsSubtitle =>
      '問題をより早く修正できるよう、クラッシュ、エラー、パフォーマンスの診断情報を送信します（リリースビルドのみ）。設定 → プライバシーでいつでも変更できます。';

  @override
  String get blocked => 'ブロック中';

  @override
  String get idle => 'アイドル';

  @override
  String get noRunsYet => 'まだ実行がありません';

  @override
  String get copyPath => 'パスをコピー';

  @override
  String get copyRelativePath => '相対パスをコピー';

  @override
  String get nameRequired => '名前は必須です';

  @override
  String get import => 'インポート';

  @override
  String get noMatchingAgents => 'フィルターに一致するエージェントはありません';

  @override
  String watchVideoOn(String provider) {
    return '$providerで動画を見る';
  }

  @override
  String get branchTemplate => 'ブランチ名テンプレート';

  @override
  String get branchTemplateDescription =>
      '隔離されたワークツリーでチケットを開始したときに作成されるブランチのパターンです。';

  @override
  String branchTemplatePreview(String example) {
    return '例: $example';
  }

  @override
  String get deletePipelineRun => 'パイプライン実行を削除';

  @override
  String deletePipelineRunConfirm(String template) {
    return '「$template」のこの実行を削除しますか？この操作は取り消せません。';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'パイプライン実行の削除エラー: $error';
  }

  @override
  String get deleteTicket => 'チケットを削除';

  @override
  String deleteTicketConfirm(String title) {
    return '「$title」を削除しますか？この操作は取り消せません。';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'チケットの削除エラー: $error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return '「$name」を削除しますか？ディスク上のリンクされたリポジトリは変更されません。';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'ワークスペースの削除エラー: $error';
  }

  @override
  String get indexCode => 'コードをインデックス';

  @override
  String get indexNoGrammars => 'コードグラマーがインストールされていません';

  @override
  String get indexFailed => 'インデックスに失敗しました';

  @override
  String indexedSymbolsCount(int count) {
    return '$count個のシンボルをインデックスしました';
  }

  @override
  String get nodeConfigAdvanced => '詳細';

  @override
  String get nodeConfigReducer => 'リデューサー';

  @override
  String get nodeConfigReducerHelp => 'この出力キーに既に値がある場合のマージ方法です';

  @override
  String get nodeConfigTimeoutMs => 'タイムアウト (ms)';

  @override
  String get nodeConfigRetryAttempts => '再試行回数';

  @override
  String get nodeConfigContinueOnFail => 'このステップが失敗しても続行';

  @override
  String get nodeConfigTeamId => 'チームID';

  @override
  String get nodeConfigDispatchMode => 'ディスパッチモード';

  @override
  String get nodeConfigOutputSchema => '出力スキーマ (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp => 'ステップ出力が満たす必要があるJSON Schemaです';

  @override
  String get diffLineDisplay => 'diffの長い行';

  @override
  String get diffLineDisplayDescription => '長い行を折り返すか、横にスクロールします';

  @override
  String get diffLineWrap => '折り返し';

  @override
  String get diffLineScroll => '横スクロール';

  @override
  String get actions => '操作';

  @override
  String get activate => '有効化';

  @override
  String get activity => 'アクティビティ';

  @override
  String get activityLabel => 'アクティビティ';

  @override
  String get activitySearchHint => 'アクティビティを検索';

  @override
  String get activityNoMatches => 'フィルターに一致するアクティビティはありません';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$total件中 $start–$end';
  }

  @override
  String get activityPreviousPage => '前のページ';

  @override
  String get activityNextPage => '次のページ';

  @override
  String get activityNetworkLocal => 'ローカルホスト';

  @override
  String get activityClearFilter => 'フィルターをクリア';

  @override
  String activityFilterIp(String ip) {
    return 'IP $ip';
  }

  @override
  String activityFilterCountry(String country) {
    return '国 $country';
  }

  @override
  String get activitySavedWorkspaceLogo => 'ワークスペースのロゴを保存しました';

  @override
  String activityVerbCreated(String target) {
    return '$targetを作成しました';
  }

  @override
  String activityVerbUpdated(String target) {
    return '$targetを更新しました';
  }

  @override
  String activityVerbDeleted(String target) {
    return '$targetを削除しました';
  }

  @override
  String activityVerbAdded(String target) {
    return '$targetを追加しました';
  }

  @override
  String activityVerbRemoved(String target) {
    return '$targetを除外しました';
  }

  @override
  String activityVerbInvited(String target) {
    return '$targetを招待しました';
  }

  @override
  String activityVerbChanged(String target) {
    return '$targetを変更しました';
  }

  @override
  String activityVerbStarted(String target) {
    return '$targetを開始しました';
  }

  @override
  String activityVerbStopped(String target) {
    return '$targetを停止しました';
  }

  @override
  String activityVerbWrote(String target) {
    return '$targetを書きました';
  }

  @override
  String get activityTargetAgent => 'エージェント';

  @override
  String get activityTargetTicket => 'チケット';

  @override
  String get activityTargetWorkspace => 'ワークスペース';

  @override
  String get activityTargetRepository => 'リポジトリ';

  @override
  String get activityTargetMember => 'メンバー';

  @override
  String get activityTargetInvite => '招待';

  @override
  String get activityTargetSpace => 'スペース';

  @override
  String get activityTargetMessage => 'メッセージ';

  @override
  String get activityTargetCache => 'キャッシュ';

  @override
  String get activityTargetFile => 'ファイル';

  @override
  String get activityTargetPipeline => 'パイプライン';

  @override
  String get activityTargetTemplate => 'テンプレート';

  @override
  String get activityTargetProvider => 'プロバイダー';

  @override
  String get activityTargetModel => 'モデル';

  @override
  String get activityTargetSkill => 'スキル';

  @override
  String get activityTargetTodo => 'To-Do';

  @override
  String get activityTargetMeeting => 'ミーティング';

  @override
  String get activityTargetProject => 'プロジェクト';

  @override
  String get activityTargetTeam => 'チーム';

  @override
  String get activityTargetDevice => 'デバイス';

  @override
  String get activityTargetPreference => '設定';

  @override
  String get activityTargetBudget => '予算';

  @override
  String activityVerbApproved(String target) {
    return '$targetを承認しました';
  }

  @override
  String activityVerbArchived(String target) {
    return '$targetをアーカイブしました';
  }

  @override
  String activityVerbAssigned(String target) {
    return '$targetを割り当てました';
  }

  @override
  String activityVerbBackedUp(String target) {
    return '$targetをバックアップしました';
  }

  @override
  String activityVerbCancelled(String target) {
    return '$targetをキャンセルしました';
  }

  @override
  String activityVerbCleared(String target) {
    return '$targetをクリアしました';
  }

  @override
  String activityVerbClosed(String target) {
    return '$targetを閉じました';
  }

  @override
  String activityVerbCommitted(String target) {
    return '$targetをコミットしました';
  }

  @override
  String activityVerbCompacted(String target) {
    return '$targetをコンパクト化しました';
  }

  @override
  String activityVerbCompleted(String target) {
    return '$targetを完了しました';
  }

  @override
  String activityVerbConnected(String target) {
    return '$targetを接続しました';
  }

  @override
  String activityVerbContinued(String target) {
    return '$targetを続行しました';
  }

  @override
  String activityVerbDisconnected(String target) {
    return '$targetを切断しました';
  }

  @override
  String activityVerbDispatched(String target) {
    return '$targetをディスパッチしました';
  }

  @override
  String activityVerbDrained(String target) {
    return '$targetをドレインしました';
  }

  @override
  String activityVerbEnrolled(String target) {
    return '$targetをエンロールしました';
  }

  @override
  String activityVerbEstimated(String target) {
    return '$targetを見積もりました';
  }

  @override
  String activityVerbImported(String target) {
    return '$targetをインポートしました';
  }

  @override
  String activityVerbInstalled(String target) {
    return '$targetをインストールしました';
  }

  @override
  String activityVerbKilled(String target) {
    return '$targetを強制終了しました';
  }

  @override
  String activityVerbMarked(String target) {
    return '$targetをマークしました';
  }

  @override
  String activityVerbMerged(String target) {
    return '$targetをマージしました';
  }

  @override
  String activityVerbOpened(String target) {
    return '$targetを開きました';
  }

  @override
  String activityVerbPaused(String target) {
    return '$targetを一時停止しました';
  }

  @override
  String activityVerbPolled(String target) {
    return '$targetをポーリングしました';
  }

  @override
  String activityVerbPrepared(String target) {
    return '$targetを準備しました';
  }

  @override
  String activityVerbProcessed(String target) {
    return '$targetを処理しました';
  }

  @override
  String activityVerbPublished(String target) {
    return '$targetを公開しました';
  }

  @override
  String activityVerbRefined(String target) {
    return '$targetをリファインしました';
  }

  @override
  String activityVerbRefreshed(String target) {
    return '$targetを更新しました';
  }

  @override
  String activityVerbRegistered(String target) {
    return '$targetを登録しました';
  }

  @override
  String activityVerbRenamed(String target) {
    return '$targetの名前を変更しました';
  }

  @override
  String activityVerbReordered(String target) {
    return '$targetの順序を変更しました';
  }

  @override
  String activityVerbResponded(String target) {
    return '$targetに応答しました';
  }

  @override
  String activityVerbRestored(String target) {
    return '$targetを復元しました';
  }

  @override
  String activityVerbResumed(String target) {
    return '$targetを再開しました';
  }

  @override
  String activityVerbRetried(String target) {
    return '$targetを再試行しました';
  }

  @override
  String activityVerbReverted(String target) {
    return '$targetをリバートしました';
  }

  @override
  String activityVerbReviewed(String target) {
    return '$targetをレビューしました';
  }

  @override
  String activityVerbRan(String target) {
    return '$targetを実行しました';
  }

  @override
  String activityVerbSelected(String target) {
    return '$targetを選択しました';
  }

  @override
  String activityVerbSent(String target) {
    return '$targetを送信しました';
  }

  @override
  String activityVerbStaged(String target) {
    return '$targetをステージしました';
  }

  @override
  String activityVerbSteered(String target) {
    return '$targetをステアしました';
  }

  @override
  String activityVerbSubmitted(String target) {
    return '$targetを提出しました';
  }

  @override
  String activityVerbSynced(String target) {
    return '$targetを同期しました';
  }

  @override
  String activityVerbToggled(String target) {
    return '$targetを切り替えました';
  }

  @override
  String activityVerbUninstalled(String target) {
    return '$targetをアンインストールしました';
  }

  @override
  String activityVerbUnstaged(String target) {
    return '$targetのステージを解除しました';
  }

  @override
  String get activityTargetActionPolicy => 'アクションポリシー';

  @override
  String get activityTargetGoalRun => 'ゴール実行';

  @override
  String get activityTargetRunLog => '実行ログ';

  @override
  String get activityTargetWorkingMemory => 'ワーキングメモリ';

  @override
  String get activityTargetRoutingPolicy => 'ルーティングポリシー';

  @override
  String get activityTargetAutonomy => '自律';

  @override
  String get activityTargetCalendar => 'カレンダー';

  @override
  String get activityTargetChecker => 'チェッカー';

  @override
  String get activityTargetEditor => 'エディター';

  @override
  String get activityTargetConfirmation => '確認';

  @override
  String get activityTargetTunnel => 'トンネル';

  @override
  String get activityTargetConversation => '会話';

  @override
  String get activityTargetCredentials => '認証情報';

  @override
  String get activityTargetDictation => 'ディクテーション';

  @override
  String get activityTargetAgentRun => 'エージェント実行';

  @override
  String get activityTargetEvalSuite => '評価スイート';

  @override
  String get activityTargetWorker => 'ワーカー';

  @override
  String get activityTargetWorktree => 'ワークツリー';

  @override
  String get activityTargetMcpServer => 'MCPサーバー';

  @override
  String get activityTargetMemoryAccessGrant => 'メモリアクセス許可';

  @override
  String get activityTargetMemoryDomain => 'メモリドメイン';

  @override
  String get activityTargetMemoryFact => 'メモリファクト';

  @override
  String get activityTargetMemoryPolicy => 'メモリポリシー';

  @override
  String get activityTargetFeed => 'フィード';

  @override
  String get activityTargetNote => 'ノート';

  @override
  String get activityTargetOrchestration => 'オーケストレーション';

  @override
  String get activityTargetPipelineRun => 'パイプライン実行';

  @override
  String get activityTargetPipelineTrigger => 'パイプライントリガー';

  @override
  String get activityTargetPlan => 'プラン';

  @override
  String get activityTargetPlaybook => 'プレイブック';

  @override
  String get activityTargetPullRequest => 'プルリクエスト';

  @override
  String get activityTargetReview => 'レビュー';

  @override
  String get activityTargetProcess => 'プロセス';

  @override
  String get activityTargetProviderPolicy => 'プロバイダーポリシー';

  @override
  String get activityTargetReaction => 'リアクション';

  @override
  String get activityTargetReviewSpace => 'レビュースペース';

  @override
  String get activityTargetReviewStudio => 'レビュースタジオ';

  @override
  String get activityTargetServerData => 'サーバーデータ';

  @override
  String get activityTargetSoundscape => 'サウンドスケープ';

  @override
  String get activityTargetSession => 'セッション';

  @override
  String get activityTargetTerminal => 'ターミナル';

  @override
  String get activityTargetTicketLink => 'チケットリンク';

  @override
  String get activityTargetTicketSync => 'チケット同期';

  @override
  String get activityTargetProfile => 'プロフィール';

  @override
  String get activityTargetVoiceProfile => '音声プロフィール';

  @override
  String get activityTargetWeather => '天気予報';

  @override
  String get activityTargetWorkProduct => '成果物';

  @override
  String get activityChangedMemberRole => 'メンバーのロールを変更しました';

  @override
  String get activityChangedMemberRepoAccess => 'メンバーのリポジトリアクセスを変更しました';

  @override
  String get activityUpdatedGitHubToken => 'GitHubトークンを更新しました';

  @override
  String get activityRefreshedWeather => '天気予報を再読み込みしました';

  @override
  String get activitySetWeatherLocation => '天気の場所を設定しました';

  @override
  String get activityClearedWeatherLocation => '天気の場所をクリアしました';

  @override
  String get activityMarkedAllArticlesRead => 'すべての記事を既読にしました';

  @override
  String get activityMarkedArticleRead => '記事を既読にしました';

  @override
  String get activityUpdatedSavedArticle => '保存済み記事を更新しました';

  @override
  String get activityTookOverSession => 'セッションを引き継ぎました';

  @override
  String get activityHandedBackSession => 'セッションを返しました';

  @override
  String get activityCommittedAndPushed => 'コミットしてプッシュしました';

  @override
  String get activityBackedUpServer => 'サーバーデータをバックアップしました';

  @override
  String get activityMarkedSpaceRead => 'スペースを既読にしました';

  @override
  String get activityRespondedToInvitation => 'イベント招待に応答しました';

  @override
  String get activityStartedCalendarConnect => 'カレンダー連携を開始しました';

  @override
  String get activityDisconnectedCalendar => 'カレンダーの連携を解除しました';

  @override
  String get activityMarkedFileViewed => 'ファイルを閲覧済みにしました';

  @override
  String get activityRespondedToApproval => '承認リクエストに応答しました';

  @override
  String get activityChangedTunnel => 'トンネル設定を変更しました';

  @override
  String get activitySentMessageToAgent => 'エージェントにメッセージを送信しました';

  @override
  String get activityOpenedReviewSpace => 'レビュースペースを開きました';

  @override
  String get activityOpenedStandingConversation => '常設の会話を開きました';

  @override
  String get activityStartedRecording => '録画を開始しました';

  @override
  String get activityStoppedRecording => '録画を停止しました';

  @override
  String get activityToggledMcpServer => 'MCPサーバーを切り替えました';

  @override
  String get activityUpdatedMcpToken => 'MCPトークンを更新しました';

  @override
  String get activitySavedApiKey => 'APIキーを保存しました';

  @override
  String get activityRemovedProviderCredential => 'プロバイダーの認証情報を削除しました';

  @override
  String get activityUpdatedLinkedRepos => 'リンク済みリポジトリを更新しました';

  @override
  String get activityUnlinkedRepo => 'リポジトリのリンクを解除しました';

  @override
  String get activityUpdatedActionItem => 'アクションアイテムを更新しました';

  @override
  String adRulesCount(int count) {
    return '$count件の広告ルール';
  }

  @override
  String get adapter => 'アダプター';

  @override
  String get adapterLabel => 'アダプター';

  @override
  String get adapters => 'アダプター';

  @override
  String get adaptersAutoDetected =>
      'このマシンで利用可能なエージェントランナーを自動検出しています。足りないCLIツールをインストールすると、追加のランナーを有効にできます。';

  @override
  String get add => '追加';

  @override
  String get addAComment => 'コメントを追加';

  @override
  String get addAReaction => 'リアクションを追加';

  @override
  String get addASuggestion => '提案を追加';

  @override
  String get addAgents => 'エージェントを追加';

  @override
  String get addEmoji => '絵文字を追加';

  @override
  String get addFeed => 'フィードを追加';

  @override
  String get addressBarHint => 'URLを入力';

  @override
  String get addFromFile => 'ファイルから追加';

  @override
  String get addGif => 'GIFを追加';

  @override
  String get addGithubRepoPrompt => 'プルリクエストを表示するには、GitHubリポジトリを1つ以上追加してください';

  @override
  String get addLocalCheckoutDescription =>
      'このワークスペースから対象にするには、ローカルのチェックアウトを追加してください。';

  @override
  String get addRepository => 'リポジトリを追加';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のリポジトリを追加',
      one: 'リポジトリを追加',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro =>
      'サーバーが稼働しているマシン上のフォルダーを参照し、登録するgitチェックアウトを選択してください。';

  @override
  String get selectThisFolder => 'このフォルダーを選択';

  @override
  String get deselectThisFolder => 'このフォルダーの選択を解除';

  @override
  String get goUp => '上へ';

  @override
  String get noSubfoldersHere => 'サブフォルダーはありません';

  @override
  String get notAGitRepository => 'このフォルダーは git リポジトリではありません。';

  @override
  String get addToken => 'トークンを追加';

  @override
  String get addWorkspace => 'ワークスペースを追加';

  @override
  String get addWorkspaceEllipsis => 'ワークスペースを追加…';

  @override
  String get added => '追加済み';

  @override
  String get addingEllipsis => '追加中…';

  @override
  String get advancedLabel => '詳細';

  @override
  String get agent => 'エージェント';

  @override
  String agentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agents',
      one: '1 agent',
    );
    return '$_temp0';
  }

  @override
  String get agentMdPath => 'エージェント MD のパス';

  @override
  String get agentName => 'エージェント名';

  @override
  String get agentTitle => 'エージェントのタイトル';

  @override
  String get agentUpdated => 'エージェントを更新しました。';

  @override
  String get agents => 'エージェント';

  @override
  String get agentsMentionSection => 'エージェント';

  @override
  String get usersMentionSection => 'ユーザー';

  @override
  String get ticketsMentionSection => 'チケット';

  @override
  String get pullRequestsMentionSection => 'プルリクエスト';

  @override
  String get meetingsMentionSection => 'ミーティング';

  @override
  String get entityRefTicketFallback => 'チケット';

  @override
  String get entityRefPrFallback => 'プルリクエスト';

  @override
  String get entityRefMeetingFallback => 'ミーティング';

  @override
  String get aiReview => 'AI レビュー';

  @override
  String get all => 'すべて';

  @override
  String get allAgentsAlreadyInSpace => 'すべてのエージェントはすでにこのスペースに含まれています。';

  @override
  String get allCommits => 'すべてのコミット';

  @override
  String get allSources => 'すべてのソース';

  @override
  String get allow => '許可';

  @override
  String get allowGitPush => 'git push を許可';

  @override
  String get allowGithubApi => 'GitHub API の呼び出しを許可';

  @override
  String get allowNetwork => '一般的なネットワークアクセスを許可';

  @override
  String get apiKeys => 'API キー';

  @override
  String get appFont => 'アプリのフォント';

  @override
  String get appLogLevelDebugDescription => '詳細なトレースを追加します（開発用）。';

  @override
  String get appLogLevelDebugLabel => 'デバッグ';

  @override
  String get appLogLevelErrorDescription => '予期しないエラーと例外のみです。';

  @override
  String get appLogLevelErrorLabel => 'エラー';

  @override
  String get appLogLevelInfoDescription => 'ライフサイクルとステータスのメッセージを追加します。';

  @override
  String get appLogLevelInfoLabel => '情報';

  @override
  String get appLogLevelNoneDescription => 'コンソール出力は一切ありません。';

  @override
  String get appLogLevelNoneLabel => 'なし';

  @override
  String get appLogLevelVerboseDescription =>
      'すべてを出力します。非常に多いため、デバッグ時のみ使用してください。';

  @override
  String get appLogLevelVerboseLabel => '詳細';

  @override
  String get appLogLevelWarningDescription => '警告と回復可能な問題を追加します。';

  @override
  String get appLogLevelWarningLabel => '警告';

  @override
  String get appearanceLanguage => '外観と言語';

  @override
  String get apply => '適用';

  @override
  String get approve => '承認';

  @override
  String get agentApprovalRequired => '承認が必要';

  @override
  String agentApprovalsMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'あと $count 件待機中',
      one: 'あと 1 件待機中',
    );
    return '$_temp0';
  }

  @override
  String get approved => '承認済み';

  @override
  String get articleNoun => '記事';

  @override
  String get articlesSubscribed => '購読中のフィードの記事です。';

  @override
  String get askAi => 'AIに質問';

  @override
  String get askAiReviewDescription => 'このPRのレビューをAIに依頼';

  @override
  String get assignees => '担当者';

  @override
  String get attachImage => '画像を添付';

  @override
  String get attachedAgents => '添付エージェント';

  @override
  String get audioInput => '音声入力';

  @override
  String get audioOutput => '音声出力';

  @override
  String get authenticationToken => '認証トークン';

  @override
  String authoredByLabel(String role) {
    return '作成者: $role';
  }

  @override
  String get autoRecommended => '自動（推奨）';

  @override
  String get available => '利用可能';

  @override
  String get awaitingYourReview => 'レビュー待ち';

  @override
  String get back => '戻る';

  @override
  String get backLabel => '戻る';

  @override
  String get backend => 'バックエンド';

  @override
  String get blockAdsTrackers => '広告、トラッカー、Cookieバナーをブロック';

  @override
  String get blocking => 'ブロック中';

  @override
  String get bookmarkLabel => 'ブックマーク';

  @override
  String get briefDescription => '簡単な説明';

  @override
  String get bugLabel => 'バグ';

  @override
  String get bundledDefaultsNeverUpdated => '同梱のデフォルト — 更新されません';

  @override
  String get cancel => 'キャンセル';

  @override
  String get cancelEdit => '編集をキャンセル';

  @override
  String get categoryCreation => '作成';

  @override
  String get categoryEditing => '編集';

  @override
  String get categoryNavigation => 'ナビゲーション';

  @override
  String get categorySystem => 'システム';

  @override
  String get categoryView => 'カテゴリ表示';

  @override
  String get change => '変更';

  @override
  String get changesRequested => '変更リクエスト';

  @override
  String get spacesMentionSection => 'スペース';

  @override
  String get checkForUpdates => '更新を確認';

  @override
  String get checking => '確認中';

  @override
  String get checkingEllipsis => '確認中…';

  @override
  String get chooseAppFont => 'アプリのフォントを選択';

  @override
  String get chooseCodeFont => 'コードフォントを選択';

  @override
  String get chooseRunner => 'エージェントのランナーを選択してください。';

  @override
  String get clear => 'クリア';

  @override
  String get clickToRetry => 'クリックして再試行';

  @override
  String get close => '閉じる';

  @override
  String get closeEsc => '閉じる（Esc）';

  @override
  String get closeReader => 'リーダーを閉じる';

  @override
  String get closed => 'クローズ';

  @override
  String get codeFont => 'コードフォント';

  @override
  String get codeFontLigatures => 'コードフォントの合字';

  @override
  String get codeFontLigaturesDescription =>
      'コードと差分でプログラミング合字（=>、!=、->）を結合グリフとして表示します';

  @override
  String get collapse => '折りたたむ';

  @override
  String get commandPalette => 'コマンドパレット';

  @override
  String get commandPaletteOrgMembers => '組織メンバー';

  @override
  String get commandPaletteBrowseTeam => 'チームを閲覧';

  @override
  String get commandPaletteBrowseTeamDesc => 'すべての組織メンバーを表示します';

  @override
  String get compactDone => '会話を圧縮しました。それ以前の履歴は要約にまとめられています。';

  @override
  String get compactNothing => 'まだ圧縮するものはありません。会話はまだ短いです。';

  @override
  String get compactBusy => 'エージェントがまだ作業中です。ターンが終わってから圧縮してください。';

  @override
  String get compactUnavailable => 'このサーバーでは圧縮を利用できません。';

  @override
  String get commandsMentionSection => 'コマンド';

  @override
  String get comment => 'コメント';

  @override
  String get commentOnThisFile => 'このファイルにコメント';

  @override
  String get commented => 'コメント済み';

  @override
  String get commits => 'コミット';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return '最新 $loaded / $total 件のコミットを表示';
  }

  @override
  String get prCloneProgressCloningTitle => 'リポジトリをクローン中';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'このPRは $fileCount ファイルを変更しており、GitHubのAPI上限を超えています。リポジトリをローカルにクローンしています…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'このPRはGitHubのAPIファイル上限を超えています。リポジトリをローカルにクローンしています…';

  @override
  String get prCloneProgressFetchingTitle => 'PRのrefを取得中';

  @override
  String get prCloneProgressFetchingSubtitle => 'ベースブランチとPRのhead refを取得しています…';

  @override
  String get prCloneProgressComputingTitle => 'diffを計算中';

  @override
  String get prCloneProgressComputingSubtitle => 'ローカルでgit diffを実行しています…';

  @override
  String get prCloneProgressErrorTitle => 'diffの読み込みに失敗しました';

  @override
  String get prCloneProgressErrorSubtitle =>
      'クローンまたはdiffの計算中にエラーが発生しました。再読み込みしてください。';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return '作業中です… $elapsed 経過';
  }

  @override
  String confidenceLabel(int percent) {
    return '信頼度: $percent%';
  }

  @override
  String get configureAgentIdentities =>
      'エージェントのアイデンティティ、プロンプト、スキルを設定し、実行を表示します。';

  @override
  String get configureDefaultRunners => '新しいスペースとタイトル生成に使うアダプターとモデルを設定します。';

  @override
  String get configuredLabel => '設定済みです。';

  @override
  String get confirmedBy => '確認者';

  @override
  String get consensus => 'コンセンサス';

  @override
  String get contentHint => '記憶する内容';

  @override
  String get contentLabel => 'コンテンツ';

  @override
  String get contentMarkdown => 'コンテンツ（Markdown）';

  @override
  String get contextWindowSize => 'コンテキストウィンドウサイズ';

  @override
  String modelContextChip(String size) {
    return 'モデル · $size';
  }

  @override
  String get continueLabel => '続行';

  @override
  String get conversationMode => 'モード';

  @override
  String cookieRulesCount(int count) {
    return '$count 件のCookieルール';
  }

  @override
  String get copied => 'コピーしました！';

  @override
  String get copy => 'コピー';

  @override
  String get copyAddress => 'アドレスをコピー';

  @override
  String get copyBaseBranchTooltip => 'ベースブランチ名をコピー';

  @override
  String get copyHeadBranchTooltip => 'ヘッドブランチ名をコピー';

  @override
  String couldNotListDevices(String error) {
    return 'デバイスを一覧できませんでした: $error';
  }

  @override
  String get create => '作成';

  @override
  String get createOrSelectWorkspace => 'リポジトリを追加する前に、ワークスペースを作成または選択してください。';

  @override
  String get createPullRequest => 'プルリクエストを作成';

  @override
  String get createdByMe => '自分が作成';

  @override
  String createdLabel(String date) {
    return '作成日: $date';
  }

  @override
  String get currentParticipants => '現在の参加者';

  @override
  String get customCapabilitiesDescription => 'カスタム機能の説明';

  @override
  String get customSystemPrompt => 'このエージェントのカスタムシステムプロンプト...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日前',
      one: '1日前',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => '無効化';

  @override
  String get defaultCapabilities => 'デフォルトの機能 · 新しいスペース';

  @override
  String get defaultChat => 'デフォルトチャット';

  @override
  String get defaultRunners => 'デフォルトランナー';

  @override
  String get delete => '削除';

  @override
  String get deleteAgent => 'エージェントを削除';

  @override
  String deleteAgentConfirm(String name) {
    return '「$name」を削除しますか？この操作は元に戻せません。';
  }

  @override
  String get deleteSpace => 'スペースを削除';

  @override
  String deleteConfirmName(String name) {
    return '「$name」を削除しますか？';
  }

  @override
  String get archiveConversation => '会話をアーカイブ';

  @override
  String get deleteFact => 'ファクトを削除';

  @override
  String get deleteFeedBody =>
      'フィードとそのキャッシュ済み記事がすべて削除されます。このフィードからブックマークした記事も削除されます。';

  @override
  String deleteFeedConfirm(String name) {
    return '「$name」を削除しますか？';
  }

  @override
  String get deletePolicy => 'ポリシーを削除';

  @override
  String get deletePolicyConfirm => 'このポリシーを削除しますか？この操作は元に戻せません。';

  @override
  String deleteTopicConfirm(String topic) {
    return '「$topic」を削除しますか？この操作は元に戻せません。';
  }

  @override
  String get deleteWorkspace => 'ワークスペースを削除';

  @override
  String get deny => '拒否';

  @override
  String get detailsLabel => '詳細';

  @override
  String get descriptionLabel => '説明';

  @override
  String detectedBackend(String label) {
    return '検出: $label';
  }

  @override
  String get detectedRunners => '検出されたランナー';

  @override
  String get detectingAdapters => 'アダプターを検出しています…';

  @override
  String get detectingInputDevices => '入力デバイスを検出しています…';

  @override
  String detectionFailed(String error) {
    return '検出に失敗しました: $error';
  }

  @override
  String get disabled => '無効';

  @override
  String get discover => '探索';

  @override
  String get dismissed => '却下済み';

  @override
  String get domainHint => '例: api-performance';

  @override
  String get domainLabel => 'ドメイン';

  @override
  String get download => 'ダウンロード';

  @override
  String get downloadingLabel => 'ダウンロード中';

  @override
  String downloadingModel(int pct) {
    return 'モデルをダウンロードしています… $pct%';
  }

  @override
  String get draft => '下書き';

  @override
  String get draftLabel => '下書き';

  @override
  String get edit => '編集';

  @override
  String get edited => '編集済み';

  @override
  String get editMessage => 'メッセージを編集';

  @override
  String get deleteMessage => 'メッセージを削除';

  @override
  String get deleteMessageConfirm => 'このメッセージを削除しますか？この操作は元に戻せません。';

  @override
  String get messageDeleted => 'メッセージを削除しました';

  @override
  String get searchInConversation => '会話内を検索';

  @override
  String get searchMessagesHint => 'メッセージを検索…';

  @override
  String get noMessagesFound => 'メッセージが見つかりません';

  @override
  String get editFact => 'ファクトを編集';

  @override
  String get editPolicy => 'ポリシーを編集';

  @override
  String get editSuggestedCodeHint => '提案されたコードを編集…';

  @override
  String get editSuggestion => '編集の提案';

  @override
  String get egArchitect => '例: architect';

  @override
  String get egControlCenter => '例: control-center';

  @override
  String get egPlatform => '例: macOS';

  @override
  String get egSamuelAlev => '例: SamuelAlev';

  @override
  String get egSoftwareArchitect => '例: Software Architect';

  @override
  String get egTheVerge => '例: The Verge';

  @override
  String get egTokenLimit => '例: 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'インストールに失敗しました: $error';
  }

  @override
  String get embeddingInstalled => 'ローカルの埋め込みモデルをインストールしました。ハイブリッド検索が有効です。';

  @override
  String get embeddingModel => '埋め込みモデル（ONNX）';

  @override
  String get embeddingNotInstalled => '未インストールです。有効にするまで検索はキーワードのみになります。';

  @override
  String get embeddingRedownloadBody =>
      '既存のモデルファイルを削除して再ダウンロードします。ダウンロードが完了するまでセマンティック検索は利用できません。';

  @override
  String get embeddingRemoveBody =>
      '再インストールするまでセマンティック検索は無効になります。いつでも再インストールできます。';

  @override
  String get speakerDiarization => '話者分離';

  @override
  String get diarizationModel => '話者分離モデル';

  @override
  String get diarizationInstalled => 'インストール済み — 会議の文字起こしで話者を識別します';

  @override
  String get diarizationNotInstalled => '未インストール — 会議の話者は分離されません';

  @override
  String diarizationInstallFailed(String error) {
    return 'インストールに失敗しました: $error';
  }

  @override
  String get redownloadDiarizationModel => '話者分離モデルを再ダウンロード';

  @override
  String get diarizationRedownloadBody => '現在の話者分離モデルを削除して再ダウンロードします。';

  @override
  String get removeDiarizationModel => '話者分離モデルを削除';

  @override
  String get diarizationRemoveBody =>
      '端末上の話者分離モデルを削除します。すでに作成された会議の文字起こしには影響しません。';

  @override
  String get enableNotifications => '通知を有効にする';

  @override
  String get enableSandboxing => 'サンドボックスを有効にする';

  @override
  String get enabled => '有効';

  @override
  String errorCreatingAgent(String error) {
    return 'エージェントの作成エラー: $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'エージェントの削除エラー: $error';
  }

  @override
  String errorWithDetail(String error) {
    return 'エラー: $error';
  }

  @override
  String get expand => '展開';

  @override
  String extractingModel(int pct) {
    return 'モデルを展開中… $pct%';
  }

  @override
  String get fact => '事実';

  @override
  String factCount(int count) {
    return '$count 件の事実';
  }

  @override
  String factCountPlural(int count) {
    return '$count 件の事実';
  }

  @override
  String get facts => '事実';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount 件の事実 · $policyCount 件のポリシー';
  }

  @override
  String get failed => '失敗';

  @override
  String failedToDispatch(String error) {
    return 'ディスパッチに失敗しました: $error';
  }

  @override
  String get failedToLoad => '読み込みに失敗しました';

  @override
  String failedToLoadAgents(String error) {
    return 'エージェントの読み込みに失敗しました: $error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'フィードの読み込みに失敗しました: $error';
  }

  @override
  String get failedToLoadGifs => 'GIFの読み込みに失敗しました';

  @override
  String failedToLoadLogs(String error) {
    return 'ログの読み込みに失敗しました: $error';
  }

  @override
  String get failedToLoadRepos => 'リポジトリの読み込みに失敗しました';

  @override
  String get failedToLoadWorkspaces => 'ワークスペースの読み込みに失敗しました';

  @override
  String failedToStartAiReview(String error) {
    return 'AIレビューの開始に失敗しました: $error';
  }

  @override
  String get failedToStartMicTest => 'マイクテストを開始できませんでした。';

  @override
  String failedToSubmitReview(String error) {
    return 'レビューの送信に失敗しました: $error';
  }

  @override
  String failedToUpload(String name, String error) {
    return '$name のアップロードに失敗しました: $error';
  }

  @override
  String failedWithError(String error) {
    return '失敗: $error';
  }

  @override
  String get failure => '失敗';

  @override
  String get feedAlreadyExists => 'このURLのフィードはすでに存在します。';

  @override
  String get feedUrlExample => '例: https://example.com/feed.xml';

  @override
  String get feedUrlLabel => 'フィードURL';

  @override
  String feedsCount(int count) {
    return 'フィード ($count)';
  }

  @override
  String get filesChanged => '変更されたファイル';

  @override
  String filesCount(int count) {
    return '$count 件のファイル';
  }

  @override
  String get filesMentionSection => 'ファイル';

  @override
  String get filterAgents => 'エージェントを絞り込む...';

  @override
  String get filterFilesHint => 'ファイルを絞り込む…';

  @override
  String get filterLists => 'リストを絞り込む';

  @override
  String get filterSkillsPlaceholder => 'スキルを絞り込む…';

  @override
  String get finish => '完了';

  @override
  String get fix => '修正';

  @override
  String get forward => '進む';

  @override
  String get gatesGithubPatPush => 'GitHub PATの注入をゲートします。エージェントがプッシュするために必要です。';

  @override
  String get general => '一般';

  @override
  String get githubLink => 'GitHubリンク';

  @override
  String get claudeStatusFetchFailed => 'status.claude.com に接続できませんでした';

  @override
  String get claudeStatusOpenInBrowser => 'status.claude.com を開く';

  @override
  String get githubStatusFetchFailed => 'githubstatus.com に接続できませんでした';

  @override
  String get githubDegradedTitle => 'GitHubで問題が報告されています';

  @override
  String githubDegradedStatusLine(String status) {
    return 'GitHubのステータス: $status。';
  }

  @override
  String githubDegradedBody(String status) {
    return 'GitHubのステータス: $status。復旧するまで、プルリクエストのデータが古いか不完全な場合があります。';
  }

  @override
  String get githubStatusOpenInBrowser => 'githubstatus.com を開く';

  @override
  String get githubStatusRefresh => '更新';

  @override
  String githubStatusUpdated(String time) {
    return '$timeに更新';
  }

  @override
  String get kimiStatusFetchFailed => 'status.moonshot.cn に接続できませんでした';

  @override
  String get kimiStatusOpenInBrowser => 'status.moonshot.cn を開く';

  @override
  String get openaiStatusFetchFailed => 'status.openai.com に接続できませんでした';

  @override
  String get openaiStatusOpenInBrowser => 'status.openai.com を開く';

  @override
  String get serviceStatusMaintenance => 'メンテナンス';

  @override
  String get serviceStatusMajorIssues => '重大な問題';

  @override
  String get serviceStatusMinorIssues => '軽微な問題';

  @override
  String get serviceStatusOperational => '正常';

  @override
  String get serviceStatusOutage => '停止';

  @override
  String get serviceStatusTitle => 'サービスのステータス';

  @override
  String get serviceStatusUnknown => '不明';

  @override
  String lastChecked(String time) {
    return '$timeに確認';
  }

  @override
  String get lastCheckedRecently => '最近確認済み';

  @override
  String get giveYourWorkAHome => '作業のホームを決めましょう。';

  @override
  String get goBack => '戻る';

  @override
  String get goForward => '進む';

  @override
  String get googleFonts => 'Googleフォント';

  @override
  String get high => '高';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count時間前',
      one: '1時間前',
    );
    return '$_temp0';
  }

  @override
  String get images => '画像';

  @override
  String get inactive => '非アクティブ';

  @override
  String get install => 'インストール';

  @override
  String get installRequired => 'インストールが必要です';

  @override
  String installedVersion(String version) {
    return 'インストール済み $version';
  }

  @override
  String get invite => '招待';

  @override
  String get inviteAgent => 'エージェントを招待';

  @override
  String get isolateAgentExecution => 'エージェントの実行を分離します。';

  @override
  String get justNow => 'たった今';

  @override
  String get keepSandboxing => 'サンドボックスを維持';

  @override
  String get keybindingAddARepositoryDescription => 'リポジトリを追加';

  @override
  String get keybindingAddRepository => 'リポジトリを追加';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      '選択中の記事のブックマークを切り替え';

  @override
  String get keybindingCommandPalette => 'コマンドパレット';

  @override
  String get keybindingCreateANewAgentDescription => '新しいエージェントを作成';

  @override
  String get keybindingCreateANewWorkspaceDescription => '新しいワークスペースを作成';

  @override
  String get keybindingFocusSearch => '検索にフォーカス';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'プルリクエストの検索フィールドにフォーカス';

  @override
  String get keybindingNewAgent => '新しいエージェント';

  @override
  String get keybindingNewWorkspace => '新しいワークスペース';

  @override
  String get keybindingNextArticle => '次の記事';

  @override
  String get keybindingNextSpace => '次のスペース';

  @override
  String get keybindingNextWorkspace => '次のワークスペース';

  @override
  String get keybindingOpenArticle => '記事を開く';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'サイドバーのワークスペース切り替えポップアップを開閉';

  @override
  String get keybindingOpenPr => 'PR を開く';

  @override
  String get keybindingOpenSettings => '設定を開く';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'アプリケーションの設定を開く';

  @override
  String get keybindingOpenTheCommandPaletteDescription => 'コマンドパレットを開く';

  @override
  String get keybindingOpenTheSelectedArticleDescription => '選択中の記事を開く';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      '選択中のプルリクエストを開く';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription => '選択中のワークスペースを開く';

  @override
  String get keybindingOpenWorkspace => 'ワークスペースを開く';

  @override
  String get keybindingPreviousArticle => '前の記事';

  @override
  String get keybindingPreviousSpace => '前のスペース';

  @override
  String get keybindingPreviousWorkspace => '前のワークスペース';

  @override
  String get keybindingRefresh => '更新';

  @override
  String get keybindingRefreshAllFeedsDescription => 'すべてのフィードを更新';

  @override
  String get keybindingRefreshThePullRequestListDescription => 'プルリクエストの一覧を更新';

  @override
  String get keybindingRescanForAdaptersDescription => 'アダプターを再スキャン';

  @override
  String get keybindingSelectTheNextArticleDescription => '次の記事を選択';

  @override
  String get keybindingSelectTheNextSpaceDescription => '次のスペースを選択';

  @override
  String get keybindingSelectThePreviousArticleDescription => '前の記事を選択';

  @override
  String get keybindingSelectThePreviousSpaceDescription => '前のスペースを選択';

  @override
  String get keybindingSendMessage => 'メッセージを送信';

  @override
  String get keybindingSendTheCurrentMessageDescription => '現在のメッセージを送信';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'ライトモードとダークモードを切り替え';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      '8番目のワークスペースに切り替え';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      '5番目のワークスペースに切り替え';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      '1番目のワークスペースに切り替え';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      '4番目のワークスペースに切り替え';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription => '次のワークスペースに切り替え';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      '9番目のワークスペースに切り替え';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      '前のワークスペースに切り替え';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      '2番目のワークスペースに切り替えます';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      '7番目のワークスペースに切り替えます';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      '6番目のワークスペースに切り替えます';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      '3番目のワークスペースに切り替えます';

  @override
  String get keybindingToggleBookmark => 'ブックマークを切り替え';

  @override
  String get keybindingToggleTheme => 'テーマを切り替え';

  @override
  String get keybindingToggleWorkspaceSwitcher => 'ワークスペーススイッチャーを切り替え';

  @override
  String get keybindingWorkspace1 => 'ワークスペース 1';

  @override
  String get keybindingWorkspace2 => 'ワークスペース 2';

  @override
  String get keybindingWorkspace3 => 'ワークスペース 3';

  @override
  String get keybindingWorkspace4 => 'ワークスペース 4';

  @override
  String get keybindingWorkspace5 => 'ワークスペース 5';

  @override
  String get keybindingWorkspace6 => 'ワークスペース 6';

  @override
  String get keybindingWorkspace7 => 'ワークスペース 7';

  @override
  String get keybindingWorkspace8 => 'ワークスペース 8';

  @override
  String get keybindingWorkspace9 => 'ワークスペース 9';

  @override
  String get keybindings => 'キーバインド';

  @override
  String get keybindingsDescription =>
      'すべてのキーボードショートカットです。ショートカットは固定されており、再割り当てできません。';

  @override
  String get killRunning => '実行中を強制終了';

  @override
  String get languageSystem => 'システム';

  @override
  String get leaveACommentEllipsis => 'コメントを残す…';

  @override
  String get legendLabel => '凡例';

  @override
  String get lessLabel => '少なく';

  @override
  String get letsPluginTools => 'ツールを接続しましょう。';

  @override
  String get level => 'レベル';

  @override
  String get loadingAgents => 'エージェントを読み込み中…';

  @override
  String get loadingModels => 'モデルを読み込み中…';

  @override
  String get loadingProviders => 'プロバイダーを読み込み中…';

  @override
  String get logLevel => 'ログレベル';

  @override
  String get logs => 'ログ';

  @override
  String get low => '低';

  @override
  String get maintenance => 'メンテナンス';

  @override
  String get manageParticipants => '参加者を管理';

  @override
  String get manageWorkspaces => 'ワークスペースを管理';

  @override
  String get reorderWorkspace => 'ワークスペースの並び替え';

  @override
  String get matchOsAppearance => 'OSの外観に合わせるか、固定モードを選択してください。';

  @override
  String get mcpAuthToken => 'MCP認証トークン';

  @override
  String get mcpNotAvailableOnServer => '接続中のサーバーではMCPサーバーの操作は利用できません。';

  @override
  String get modelManagedOnServer => 'このモデルはサーバーホスト上で実行され、そこで管理されます。';

  @override
  String get mcpServer => 'MCPサーバー';

  @override
  String get medium => '中';

  @override
  String get memoryDataHint => 'エージェントの作業に応じて、事実とポリシーがここに表示されます。';

  @override
  String get memoryLabel => 'メモリ';

  @override
  String get merge => 'マージ';

  @override
  String get merged => 'マージ済み';

  @override
  String get messagePlaceholder => 'メッセージ…（@でメンション、/でコマンド）';

  @override
  String get navConversations => 'スペース';

  @override
  String get microphonePermissionDenied => 'マイクの使用が許可されていません。';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count分前',
      one: '1分前',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'モデル';

  @override
  String get modified => '変更済み';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countか月前',
      one: '1か月前',
    );
    return '$_temp0';
  }

  @override
  String get moreLabel => 'その他';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => '名前';

  @override
  String get nameAndTitleRequired => '名前とタイトルは必須です。';

  @override
  String get nameAndUrlRequired => '名前とURLは必須です';

  @override
  String get nameLabel => '名前';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'ネイティブサンドボックスは$platformで利用できます。';
  }

  @override
  String get nativeSandboxNeedsInstall => 'ネイティブサンドボックスのインストールが必要です';

  @override
  String get navObservability => 'オブザーバビリティ';

  @override
  String get navSettings => '設定';

  @override
  String networkBlockCount(int count) {
    return '$count件のネットワークブロック';
  }

  @override
  String get neutral => '中立';

  @override
  String get newCommitsPushed => '新しいコミットがプッシュされました — クリックして差分を再読み込み';

  @override
  String get newFact => '新しいファクト';

  @override
  String get newPolicy => '新しいポリシー';

  @override
  String get newsfeed => 'ニュースフィード';

  @override
  String get newsfeedLabel => 'ニュースフィード';

  @override
  String get newsfeedSettingsDescription => '購読中のフィードとリーダーの設定を管理します。';

  @override
  String get newsfeedSettingsTitle => 'ニュースフィードの設定';

  @override
  String get nextMatch => '次の一致 (↵)';

  @override
  String get noActiveWorkspace => 'アクティブなワークスペースまたはリポジトリが選択されていません。';

  @override
  String get noActiveWorkspaceCreate => 'アクティブなワークスペースがありません';

  @override
  String get noActiveWorkspaceGithub => 'GitHubリポジトリのあるアクティブなワークスペースがありません。';

  @override
  String get noAgents => 'エージェントがありません';

  @override
  String get noArticlesYet => '記事はまだありません';

  @override
  String get noArticlesYetBody => 'フィードの記事がここに表示されます。';

  @override
  String get noExecutionLogsYet => '実行ログはまだありません';

  @override
  String get noFacts => 'ファクトはまだありません';

  @override
  String get noFeedsYet => 'フィードはまだありません';

  @override
  String get noFileAnchor => 'ファイルアンカーがないため、インラインコメントを投稿できません。';

  @override
  String get noFileChangesInScope => 'このスコープにファイルの変更はありません';

  @override
  String get noGifsFound => 'GIFが見つかりません';

  @override
  String get noInputDevicesDetected => '入力デバイスが検出されませんでした — システムのデフォルトを使用します。';

  @override
  String get noMatchingFiles => '一致するファイルはありません';

  @override
  String get noMatchingGoogleFonts => '一致するGoogle Fontsはありません。';

  @override
  String get noMemoryData => 'メモリデータはまだありません';

  @override
  String get noMessagesYet => 'メッセージはまだありません';

  @override
  String get noModelsAdvertised => 'このアダプターが公開しているモデルはありません。';

  @override
  String get noOpenPullRequests => 'オープンなプルリクエストはありません';

  @override
  String get noPolicies => 'ポリシーはまだありません';

  @override
  String get noReposInWorkspaceYet => 'このワークスペースにはまだリポジトリがありません';

  @override
  String get noRunnersDetected => 'ランナーはまだ検出されていません。再読み込みして再度スキャンしてください。';

  @override
  String get noSavedArticles => '保存した記事はありません';

  @override
  String get noSavedArticlesBody => '保存した記事がここに表示されます。';

  @override
  String noShortcutsMatch(String query) {
    return '「$query」に一致するショートカットはありません';
  }

  @override
  String get noSystemFonts => 'システムフォントは検出されませんでした。';

  @override
  String get noTokenSet => 'トークンが設定されていません。アクセスは無制限です。';

  @override
  String get noWorkingMemory => '作業メモリのメモはまだありません。';

  @override
  String get noneAllRoles => 'なし（すべてのロール）';

  @override
  String get notAvailable => '利用不可';

  @override
  String get notConfiguredLabel => '未設定です。';

  @override
  String get notFoundLabel => '見つかりません';

  @override
  String get notes => 'メモ';

  @override
  String get notificationAgentFinished => 'エージェント完了';

  @override
  String get notificationPrMentioned => 'プルリクエストでメンション';

  @override
  String get notificationNewMessages => '新しいメッセージ';

  @override
  String get notificationPrMerged => 'PRマージ';

  @override
  String get notificationPrPublished => 'PR公開';

  @override
  String get notificationReviewRequested => 'レビュー依頼';

  @override
  String get notifications => '通知';

  @override
  String get notifyAgentRunCompleted => 'エージェントの実行が完了したときに通知します。';

  @override
  String get notifyPrMentioned => 'プルリクエストでメンションされたときに通知します。';

  @override
  String get notifyNewMessages => '他のスペースの新しいエージェントメッセージを通知します。';

  @override
  String get notifyPrMerged => 'プルリクエストがマージされたときに通知します。';

  @override
  String get notifyPrPublished => 'エージェントがプルリクエストを公開したときに通知します。';

  @override
  String get notifyReviewRequested => 'プルリクエストでレビューを依頼されたときに通知します。';

  @override
  String get notificationReviewStale => 'レビューが古くなっています';

  @override
  String get notifyReviewStale => 'すでにレビューしたプルリクエストに新しいコミットが追加されたとき';

  @override
  String get notificationPrMergeReadiness => 'マージ可能';

  @override
  String get notifyPrMergeReadiness =>
      '自分が作成したプルリクエストがマージ可能になったとき、またはマージできなくなったときに通知します。';

  @override
  String get notificationPrReviewDecision => 'レビュー判定';

  @override
  String get notifyPrReviewDecision => 'レビュー担当者が承認、変更依頼、または承認の取り下げをしたときに通知します。';

  @override
  String get notificationPrChecksStatus => 'チェック';

  @override
  String get notifyPrChecksStatus =>
      '自分が作成したプルリクエストでCIが失敗したとき、および回復したときに通知します。';

  @override
  String get notificationPrThreadActivity => 'レビュースレッド';

  @override
  String get notifyPrThreadActivity => '参加中のスレッドに返信または解決があったときに通知します。';

  @override
  String get notificationPrReadyToMerge => 'マージ可能';

  @override
  String notificationPrReadyToMergeBody(String prTitle) {
    return '$prTitle に必要なものがすべて揃っています。';
  }

  @override
  String get notificationPrMergeBlocked => 'マージ不可';

  @override
  String notificationPrMergeBlockedBodyConflicts(String prTitle) {
    return '$prTitle はベースブランチと競合しています。';
  }

  @override
  String notificationPrMergeBlockedBodyBehind(String prTitle) {
    return '$prTitle はベースブランチより遅れています。';
  }

  @override
  String notificationPrMergeBlockedBodyReviews(String prTitle) {
    return '$prTitle は必須のレビューを待っています。';
  }

  @override
  String notificationPrMergeBlockedBodyChanges(String prTitle) {
    return 'レビュー担当者が $prTitle に変更を依頼しました。';
  }

  @override
  String notificationPrMergeBlockedBodyChecks(String prTitle) {
    return '$prTitle のチェックが失敗しています。';
  }

  @override
  String notificationPrMergeBlockedBodyOther(String prTitle) {
    return '$prTitle はマージできなくなりました。';
  }

  @override
  String get notificationPrApproved => 'プルリクエスト承認';

  @override
  String notificationPrApprovedBodyBy(String login, String prTitle) {
    return '$login が $prTitle を承認しました';
  }

  @override
  String notificationPrApprovedBody(String prTitle) {
    return '$prTitle が承認されました';
  }

  @override
  String notificationPrReviewersRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '未応答のレビュー担当者が$count人います',
      one: '未応答のレビュー担当者が1人います',
      zero: '残りのレビュー担当者はいません',
    );
    return '$_temp0';
  }

  @override
  String get notificationPrChangesRequested => '変更依頼';

  @override
  String notificationPrChangesRequestedBodyBy(String login, String prTitle) {
    return '$login が $prTitle に変更を依頼しました';
  }

  @override
  String notificationPrChangesRequestedBody(String prTitle) {
    return '$prTitle に変更が依頼されました';
  }

  @override
  String get notificationPrReviewDismissed => '承認取り下げ';

  @override
  String notificationPrReviewDismissedBody(String prTitle) {
    return '$prTitle は再度レビューが必要です。';
  }

  @override
  String get notificationPrChecksFailed => 'チェック失敗';

  @override
  String notificationPrChecksFailedBody(String checkName, String prTitle) {
    return '$prTitle で $checkName が失敗しました';
  }

  @override
  String notificationPrChecksFailedBodyUnnamed(String prTitle) {
    return '$prTitle のチェックが失敗しています';
  }

  @override
  String get notificationPrChecksRecovered => 'チェック成功';

  @override
  String notificationPrChecksRecoveredBody(String prTitle) {
    return '$prTitle が再び成功しています。';
  }

  @override
  String notificationPrMentionedInCommentBody(String login, String location) {
    return '$login が $location であなたにメンションしました';
  }

  @override
  String get notificationPrThreadReplied => '新しい返信';

  @override
  String notificationPrThreadRepliedBody(String login, String location) {
    return '$login が $location に返信しました';
  }

  @override
  String get notificationPrThreadResolved => 'スレッド解決済み';

  @override
  String notificationPrThreadResolvedBody(String location) {
    return '$location のスレッドが解決されました。';
  }

  @override
  String get notificationGroupAgents => 'エージェント';

  @override
  String get notificationGroupPullRequests => 'プルリクエスト';

  @override
  String get notificationGroupMessages => 'メッセージ';

  @override
  String get notificationGroupTickets => 'チケット';

  @override
  String get notificationGroupCalendar => 'カレンダー';

  @override
  String get notificationGroupMachines => 'マシン';

  @override
  String get notificationsMutedRepos => 'ミュート中のリポジトリ';

  @override
  String notificationsMutedReposCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のリポジトリをミュート中',
      one: '1件のリポジトリをミュート中',
      zero: 'ミュート中のリポジトリはありません',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMuteRepo => 'このリポジトリをミュート';

  @override
  String get onboardingLinuxDescription =>
      'Control Center は Linux コンテナでエージェントの実行を分離できます。';

  @override
  String get onboardingMacosDescription =>
      'Control Center は macOS のネイティブサンドボックスでエージェントの実行を分離します。';

  @override
  String get onboardingUnsupportedDescription =>
      'このプラットフォームではサンドボックスを利用できません。エージェントは分離なしで実行されます。';

  @override
  String get openArticlesInApp => 'アプリで記事を開く';

  @override
  String get openInBrowser => 'ブラウザで開く';

  @override
  String get openedInYourBrowser => 'ブラウザで開きました。';

  @override
  String get openLabel => '開く';

  @override
  String get openOnGithub => 'GitHub で開く';

  @override
  String get openStatus => 'オープン';

  @override
  String get optionalPersonaDescription => '任意のペルソナの説明';

  @override
  String get otherLabel => 'その他';

  @override
  String get ownerOrganization => 'オーナー / 組織';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get passed => '成功';

  @override
  String get pasteValueHere => 'ここに値を貼り付け';

  @override
  String get persona => 'ペルソナ';

  @override
  String get policies => 'ポリシー';

  @override
  String get policiesHint => 'エージェントがファクトを昇格すると、ここにポリシーが表示されます。';

  @override
  String get policy => 'ポリシー';

  @override
  String get popular => '人気';

  @override
  String get port => 'ポート';

  @override
  String get postingEllipsis => '投稿中…';

  @override
  String get prCommits => 'コミット';

  @override
  String get prMergedBody => 'プルリクエストがマージされました';

  @override
  String get prMoreActions => 'その他の操作';

  @override
  String get prTitle => 'PR タイトル';

  @override
  String get reviewCommentHint => '承認をクリックするか、コメントやリアクションを追加してください…';

  @override
  String get nothingToPreview => 'プレビューするものはありません';

  @override
  String get previousMatch => '前の一致 (⇧↵)';

  @override
  String get priorityReviewsDescription => '優先レビューとリポジトリの概要です。';

  @override
  String get prsCreated => '作成したPR';

  @override
  String get prsMerged => 'マージしたPR';

  @override
  String get publishToGithub => 'GitHubに公開';

  @override
  String get published => '公開済み';

  @override
  String get pullRequestApproved => 'プルリクエスト承認済み';

  @override
  String get pullRequests => 'プルリクエスト';

  @override
  String get questionLabel => '質問';

  @override
  String get queued => 'キュー待ち';

  @override
  String get react => 'リアクション';

  @override
  String get readPrsIssuesMetadata => 'エージェントがPR、Issue、リポジトリのメタデータを読めるようにします。';

  @override
  String get readerPreferences => 'リーダー設定';

  @override
  String get reasoningEffort => '推論の程度';

  @override
  String get recommendLabel => '推奨';

  @override
  String recordingFromDevice(String device) {
    return '$deviceから録音しています。';
  }

  @override
  String get redownload => '再ダウンロード';

  @override
  String get redownloadEmbeddingModel => '埋め込みモデルを再ダウンロードしますか？';

  @override
  String get redownloadVoiceModel => '音声モデルを再ダウンロードしますか？';

  @override
  String get refinePlan => 'プランを改善';

  @override
  String get refresh => '更新';

  @override
  String get refreshAll => 'すべて更新';

  @override
  String get refreshAllFeeds => 'すべてのフィードを更新';

  @override
  String get reject => '却下';

  @override
  String get rejected => '却下済み';

  @override
  String get reload => '再読み込み';

  @override
  String get remove => '削除';

  @override
  String get removeBookmark => 'ブックマークを削除';

  @override
  String get removeEmbeddingModel => '埋め込みモデルを削除しますか？';

  @override
  String get removeLogo => 'ロゴを削除';

  @override
  String get removeRepoFromWorkspace => 'ワークスペースからリポジトリを削除しますか？';

  @override
  String get removeVoiceModel => '音声モデルを削除しますか？';

  @override
  String get removed => '削除済み';

  @override
  String get renamed => '名前を変更済み';

  @override
  String get reopen => '再オープン';

  @override
  String get resolve => '解決';

  @override
  String get replyEllipsis => '返信…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$nameはこのワークスペースから削除されます。ディスク上のローカルファイルは変更しません。';
  }

  @override
  String repoAccessNoticeBody(String repos) {
    return 'サーバーのGitHub認証情報では$reposを参照できません。リポジトリが組織に属している場合は、そこにGitHub Appをインストールするか、アクセス権のあるトークンを接続してください。';
  }

  @override
  String repoAccessNoticeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のリポジトリにアクセスできません',
      one: 'リポジトリにアクセスできません',
    );
    return '$_temp0';
  }

  @override
  String get repoAccessNoticeSuspendedTitle => 'GitHub Appのインストールが停止されています';

  @override
  String repoAccessNoticeSuspendedBody(String repos) {
    return '$repos の最終既知データを表示しています。GitHubでインストールを再開するか、アクセス権のあるトークンを接続してください。';
  }

  @override
  String get repoNoAccessBadge => 'アクセスなし';

  @override
  String get reportsTo => '報告先';

  @override
  String reposCount(int count) {
    return 'リポジトリ ($count)';
  }

  @override
  String get reposDescription => 'このワークスペースが対象とするローカルのチェックアウトです。';

  @override
  String get repositories => 'リポジトリ';

  @override
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のリポジトリ',
      one: '1件のリポジトリ',
    );
    return '$_temp0を追加できませんでした: $error';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のリポジトリを追加しました',
      one: 'リポジトリを追加しました',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => 'リポジトリ設定';

  @override
  String get repositoryName => 'リポジトリ名';

  @override
  String get requestChanges => '変更をリクエスト';

  @override
  String get requested => 'リクエスト済み';

  @override
  String get requestedChanges => '変更リクエスト';

  @override
  String requiredRoleLabel(String role) {
    return '必須ロール: $role';
  }

  @override
  String get requiredRoleOptional => '必須ロール（任意）';

  @override
  String get requirements => '要件';

  @override
  String get reset => 'リセット';

  @override
  String get resolved => '解決済み';

  @override
  String get enclosedTerminalTitle => '囲い込みターミナル';

  @override
  String get enclosedTerminalStart => 'シェルを開く';

  @override
  String get enclosedTerminalStartHint =>
      'このシェルは、この会話用の使い捨てVM内で実行されます。アプリ起動時ではなく、開いたときに起動します。';

  @override
  String get terminalStreamReconnecting => 'ストリームが中断されました — 再接続中…';

  @override
  String get terminalStreamError => 'ストリームエラー:';

  @override
  String get terminalShellExited => 'シェルが終了しました';

  @override
  String get restartShell => 'シェルを再起動';

  @override
  String get retry => '再試行';

  @override
  String get review => 'レビュー';

  @override
  String get reviewedByMe => '自分がレビュー済み';

  @override
  String get reviewers => 'レビュアー';

  @override
  String get roleLabel => 'ロール';

  @override
  String get ruleHint => 'ポリシールール（Markdown対応）';

  @override
  String get ruleLabel => 'ルール';

  @override
  String get runCompleted => '実行完了';

  @override
  String get running => '実行中';

  @override
  String get runningLabel => '実行中';

  @override
  String get runs => '実行';

  @override
  String get runsLabel => '実行';

  @override
  String get sandboxBackendNativeLabel => 'ネイティブサンドボックス';

  @override
  String get sandboxBackendMicrovmLabel => '囲い込みVM';

  @override
  String get sandboxBackendNoneLabel => '分離なし';

  @override
  String get sandboxLinuxInstall =>
      'Linux/WSL2のネイティブサンドボックスはbubblewrapを使用します。次のコマンドでインストールしてください:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'macOSではネイティブサンドボックスが組み込まれています。Apple Seatbelt（`sandbox-exec`）を使用します。インストールは不要です。';

  @override
  String get sandboxPermissions => 'サンドボックスの権限';

  @override
  String get sandboxUnsupported =>
      'このプラットフォームでは、ネイティブサンドボックスはまだサポートされていません。「分離なし」にフォールバックします。';

  @override
  String get sandboxingDisabledDescription =>
      'エージェントはホスト上でフル環境のまま直接実行されます。推奨しません。';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'すべてのエージェント呼び出しは $backend 経由で実行されます。';
  }

  @override
  String get save => '保存';

  @override
  String get saveChanges => '変更を保存';

  @override
  String get adapterArguments => '追加引数';

  @override
  String get adapterArgumentsHint => '追加のCLIフラグ（例: --yolo）';

  @override
  String get addVariable => '変数を追加';

  @override
  String get environmentVariables => '環境変数';

  @override
  String get environmentVariablesDescription =>
      'このアダプターに渡すカスタム環境変数です（例: APIキー）。キーチェーンに保存されます。';

  @override
  String get variableKey => 'キー';

  @override
  String get variableValue => '値';

  @override
  String get savingEllipsis => '保存中…';

  @override
  String get scopeDiffToCommits => 'コミットでdiffの範囲を指定 — Shiftクリックで範囲選択';

  @override
  String get noPrsMatchSearch => '一致するプルリクエストはありません';

  @override
  String get searchFactsHint => 'ファクトを検索...';

  @override
  String get searchFonts => 'フォントを検索…';

  @override
  String get searchGifs => 'GIFを検索';

  @override
  String get searchGifsHint => 'GIFを検索...';

  @override
  String get searchInDiffHint => 'diffを検索…';

  @override
  String get searchOrTypeModel => 'モデル名を検索または入力…';

  @override
  String get searchPlaceholder => '検索…';

  @override
  String get searchShortcuts => 'ショートカットを検索…';

  @override
  String get shortcutUnavailableInBrowser => 'ブラウザでは利用できません';

  @override
  String get searching => '検索中…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count秒前',
      one: '1秒前',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'アダプターを選択';

  @override
  String get selectAdapterFirst => '先にアダプターを選択してください';

  @override
  String get selectAgentToReportTo => '報告先のエージェントを選択…';

  @override
  String get selectAnAgent => 'エージェントを選択';

  @override
  String get selectConversation => '会話を選択';

  @override
  String get selectLabel => '選択';

  @override
  String get selectRunner => 'ランナーを選択';

  @override
  String get semanticSearch => 'セマンティック検索';

  @override
  String get send => '送信';

  @override
  String get sendFirstMessage => '最初のメッセージを送信';

  @override
  String get sendMessage => 'メッセージを送信';

  @override
  String sentFindingsToAgent(int count) {
    return 'エージェントに$count件の検出結果を送信しました。';
  }

  @override
  String setGithubLinkDescription(String name) {
    return '$nameのGitHubオーナーとリポジトリ名を設定します。Markdown内の #123 のようなPRやIssueの参照を解決するために使います。';
  }

  @override
  String get setLabel => '設定';

  @override
  String get setToken => 'トークンを設定';

  @override
  String get settingsLabel => '設定';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsLanguageDescription => 'アプリの言語を選択します。';

  @override
  String get shortTask => '短いタスク';

  @override
  String get showNativeNotifications => 'イベントのネイティブmacOS通知を表示します。';

  @override
  String get showSuperseded => '置き換え済みを表示';

  @override
  String get signedIn => 'サインインしました。';

  @override
  String signedInAs(String username) {
    return '$usernameとしてサインインしています。';
  }

  @override
  String get skillNameRequired => 'スキル名は必須です。';

  @override
  String skillSaved(String name) {
    return 'スキル「$name」を保存しました。';
  }

  @override
  String get skillsSourcesTab => 'ソース';

  @override
  String get skillSourcesDisclaimer =>
      'スキルは追加したGitHubリポジトリからインストールされます。リポジトリのメタデータは信頼できません。実際の安全性の判断はウイルス対策スキャンに基づきます。';

  @override
  String get skillSourcesEmpty => 'スキルリポジトリはありません';

  @override
  String get skillSourcesEmptyHint => 'GitHubリポジトリを追加してスキルを閲覧します。';

  @override
  String get skillSourceAdd => 'リポジトリを追加';

  @override
  String get skillSourceAddTitle => 'スキルリポジトリを追加';

  @override
  String get skillSourceAddHint => 'https://github.com/owner/repo';

  @override
  String get skillSourceInvalidUrl =>
      'GitHubリポジトリのURL（https://github.com/owner/repo）を入力してください。';

  @override
  String skillSourceAdded(String repo) {
    return 'リポジトリ$repoを追加しました。';
  }

  @override
  String skillSourceAlreadyAdded(String repo) {
    return 'リポジトリ$repoはすでに追加されています。';
  }

  @override
  String skillSourceRemoved(String repo) {
    return 'リポジトリ$repoを削除しました。';
  }

  @override
  String get skillSourceRemove => '削除';

  @override
  String skillSourceRemoveConfirmTitle(String repo) {
    return '$repoを削除しますか？';
  }

  @override
  String get skillSourceRemoveConfirmBody =>
      'インストール済みのスキルはそのまま残ります。削除されるのはリポジトリカタログのみです。';

  @override
  String get skillSourceNoSkills =>
      'このリポジトリにスキルが見つかりませんでした（スキルはSKILL.mdを含むディレクトリです）。';

  @override
  String get skillSourceRefresh => '更新';

  @override
  String get skillSourceInstalledBadge => 'インストール済み';

  @override
  String get skillSourceUpdateBadge => '更新あり';

  @override
  String get skillSourceSlugTaken => '使用中の名前';

  @override
  String skillSourceFilesCount(num count) {
    return '$count個のファイル';
  }

  @override
  String get skillSourceReadme => 'README';

  @override
  String get skillSourceNoReadme => 'このスキルにはREADMEがありません。';

  @override
  String get skillSourceNoMatches => 'フィルターに一致するスキルはありません。';

  @override
  String get skillUpdateAction => '更新';

  @override
  String get skillUninstallAction => 'アンインストール';

  @override
  String skillUninstallConfirmTitle(String slug) {
    return '「$slug」をアンインストールしますか？';
  }

  @override
  String skillUninstalled(String slug) {
    return 'スキル「$slug」をアンインストールしました。';
  }

  @override
  String get skillFindingLine => '行';

  @override
  String get skillInstallAnywayOverride => 'リスクを理解したうえでインストールする';

  @override
  String skillInstalled(String slug) {
    return 'スキル「$slug」をインストールしました。';
  }

  @override
  String get skillPreviewCapabilities => '機能';

  @override
  String get skillPreviewFindings => '検出結果';

  @override
  String get skillPreviewGuardedActions => 'ガード対象の操作';

  @override
  String get skillPreviewLlmReviewed => 'LLMレビュー済み';

  @override
  String get skillPreviewNoCapabilities => '機能は宣言されていません。';

  @override
  String get skillPreviewNoFindings => '検出結果はありません。';

  @override
  String get skillPreviewScanning => 'スキルをスキャンしています…';

  @override
  String get skillPreviewVerdictLabel => 'スキャン判定';

  @override
  String get skillPreviewVerdictPass => '合格';

  @override
  String get skillPreviewVerdictQuarantine => '隔離';

  @override
  String get skillPreviewVerdictWarn => '警告';

  @override
  String get skillQuarantineWarning =>
      'このスキルはスキャナーによって隔離されました。インストールすると、お使いのマシンでコードが実行されます。ソースを信頼し、検出結果を確認した場合のみ続行してください。';

  @override
  String skillDetachedFromAgents(String agents) {
    return '隔離され、エージェントから切り離されました: $agents';
  }

  @override
  String get skillNotScanned => '未スキャン';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => '手動';

  @override
  String get skillOriginRegistry => 'レジストリ';

  @override
  String get skillOriginRuntimeLocal => 'ランタイムローカル';

  @override
  String get skillRulesStale => 'スキャンが古い';

  @override
  String get skillSaveAnywayOverride => 'リスクを理解したうえで保存する';

  @override
  String get skillSaveBlockedBody => '何も書き込まれる前にコンテンツがブロックされました。';

  @override
  String get skillSaveBlockedTitle => 'スキャンゲートにより保存がブロックされました';

  @override
  String get skillScanAction => 'スキャン';

  @override
  String get skillScanAll => 'すべてスキャン';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass件合格 · $warn件警告 · $quarantine件隔離';
  }

  @override
  String get skillStateDrifted => 'インストール後に変更';

  @override
  String get skillStateUnmanaged => '未管理';

  @override
  String get skillSeverityBlocked => 'ブロック';

  @override
  String get skillSeverityWarn => '警告';

  @override
  String get skillsInstalledTab => 'インストール済み';

  @override
  String get skills => 'スキル';

  @override
  String get skipAcceptRisk => 'スキップ（リスクを承諾）';

  @override
  String get skipForNow => '今はスキップ';

  @override
  String get skipSandboxing => 'サンドボックスをスキップ';

  @override
  String get skipSandboxingDialogContent =>
      'サンドボックスをスキップしますか？エージェントが隔離なしでシステム上のコードを実行できるようになります。';

  @override
  String get somethingWentWrong => '問題が発生しました';

  @override
  String sourceCount(int count) {
    return '$count件のソース';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count件のソース';
  }

  @override
  String get sourceFacts => 'ソース情報:';

  @override
  String get splitDiff => '左右分割diff';

  @override
  String get startLabel => '開始';

  @override
  String get startOnAppLaunch => 'アプリ起動時に開始';

  @override
  String get statusLabel => 'ステータス';

  @override
  String get onboardingStepConnect => '接続';

  @override
  String get onboardingStepWorkspace => 'ワークスペース';

  @override
  String get onboardingStepSandbox => 'サンドボックス';

  @override
  String get onboardingStepAdapter => 'アダプター';

  @override
  String get onboardingStepVoice => '音声';

  @override
  String get stop => '停止';

  @override
  String get stopped => '停止済み';

  @override
  String get strictIdentityCheck => '厳格なアイデンティティチェック';

  @override
  String get success => '成功';

  @override
  String get successLabel => '成功';

  @override
  String get suggestAChange => '変更を提案';

  @override
  String get suggestLabel => '提案';

  @override
  String get superseded => '置き換え済み';

  @override
  String get synced => '同期済み';

  @override
  String get systemDefault => 'システムのデフォルト';

  @override
  String get systemFonts => 'システムフォント';

  @override
  String get systemPrompt => 'システムプロンプト';

  @override
  String get systemPromptLabel => 'システムプロンプト';

  @override
  String get talkToControlCenter => 'Control Centerに話しかけます。';

  @override
  String get taskMentionSection => 'タスク';

  @override
  String get testLabel => 'テスト';

  @override
  String get theme => 'テーマ';

  @override
  String get themeDark => 'ダーク';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeSystem => 'システム';

  @override
  String get thisCannotBeUndone => 'この操作は取り消せません。';

  @override
  String get ticketLabel => 'チケット';

  @override
  String get titleLabel => 'タイトル';

  @override
  String get todayLabel => '今日';

  @override
  String get toggleTheme => 'テーマを切り替え';

  @override
  String get tokenConfigured => '設定済み — クライアントはこのトークンを提示する必要があります。';

  @override
  String get topic => 'トピック';

  @override
  String get topicHint => '例: Tech Stack、Design System';

  @override
  String get totalRuns => '合計実行回数';

  @override
  String trackingParamsCount(int count) {
    return 'トラッキングパラメータ $count 件';
  }

  @override
  String get typeCommandOrSearch => 'コマンドを入力するか検索…';

  @override
  String get typography => 'タイポグラフィ';

  @override
  String get unavailable => '利用不可';

  @override
  String get unifiedDiff => 'ユニファイドdiff';

  @override
  String get unknownAuthor => '不明';

  @override
  String get unnamedAgent => '名前なしエージェント';

  @override
  String get updateKey => 'キーを更新';

  @override
  String get updateLabel => '更新';

  @override
  String get updateToken => 'トークンを更新';

  @override
  String updatedDaysAgo(int count) {
    return '$count日前に更新';
  }

  @override
  String updatedHoursAgo(int count) {
    return '$count時間前に更新';
  }

  @override
  String get updatedJustNow => 'たった今更新';

  @override
  String updatedMinutesAgo(int count) {
    return '$count分前に更新';
  }

  @override
  String get useSandbox => 'サンドボックスを使用';

  @override
  String get useWorkspaceDefault => 'ワークスペースのデフォルトを使用';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      '空のままにすると、アプリのデフォルトUser-Agentを使用します。一部のサイトはブラウザ以外のUser-Agentをブロックします。';

  @override
  String get usingSystemDefaultMicrophone => 'システムのデフォルトマイクを使用しています。';

  @override
  String get viewLabel => '表示';

  @override
  String get viewLogs => 'ログを表示';

  @override
  String voiceInstallFailed(String error) {
    return 'インストールに失敗しました: $error';
  }

  @override
  String get voiceModelNotInstalled =>
      '未インストールです。初回のみ約200 MBをダウンロードし、以降はすべて端末上で動作します。';

  @override
  String get voiceModelNotInstalledLabel => '音声モデルがインストールされていません。';

  @override
  String get voiceRedownloadBody =>
      '既存のモデルファイルを削除し、約200 MBのアーカイブを再ダウンロードします。ダウンロードが完了するまで音声文字起こしは利用できません。';

  @override
  String get voiceRemoveBody => '再インストールするまで音声文字起こしは無効になります。いつでも再インストールできます。';

  @override
  String get voiceTranscription => '音声文字起こし';

  @override
  String get weakIsolationDescription => '弱い分離 — 名前空間の境界のみで、カーネル境界はありません。';

  @override
  String get whenOffNoDefaultRoute => 'オフの場合、サンドボックスはデフォルトルートなしで起動します。';

  @override
  String get whenOffServerStaysStopped => 'オフの場合、サーバーは起動するまで停止したままです。';

  @override
  String get speechModel => '音声モデル';

  @override
  String get speechModelHint => '会議の文字起こしとコンポーザーのマイクで使用します。';

  @override
  String get voiceModelInstalled => 'インストール済みです。会議の文字起こしとコンポーザーのマイクボタンに使用します。';

  @override
  String get meetingMicSilentWarning =>
      'マイクがミュートになっている可能性があります — 他の人が話していますが、マイクに音声が届いていません。';

  @override
  String get meetingSummaryPrivacyNotice =>
      '録音と文字起こしはこのマシン上に留まります。要約はエージェントが作成するため、クラウドモデルを使う場合は文字起こしとメモがそのプロバイダーに送信されます。';

  @override
  String get meetingTemplates => '会議メモのテンプレート';

  @override
  String get meetingTemplatesHint =>
      'ミーティングの種類に合わせてAIの要約を整えます。有効なテンプレートは、新規と再実行の要約に適用されます。';

  @override
  String get meetingTemplateActive => '有効なテンプレート';

  @override
  String get meetingTemplateAdd => 'テンプレートを追加';

  @override
  String get meetingTemplateNewTitle => '新しいテンプレート';

  @override
  String get meetingTemplateEditTitle => 'テンプレートを編集';

  @override
  String get meetingTemplateNameLabel => '名前';

  @override
  String get meetingTemplateNameHint => '例: スプリントレビュー';

  @override
  String get meetingTemplateInstructionsLabel => '指示';

  @override
  String get meetingTemplateInstructionsHint =>
      'AIはこれらのメモをどのように構成し、何を強調すべきですか？';

  @override
  String get workingMemory => 'ワーキングメモリ';

  @override
  String get workspaceName => 'ワークスペース名';

  @override
  String get workspaceScopedSkills => 'エージェントに添付される、ワークスペーススコープのスキルファイルです。';

  @override
  String get workspaces => 'ワークスペース';

  @override
  String get writePrivateNotes => '非公開のメモ、所感、計画などを書く...';

  @override
  String get writeSkillContent => 'スキルの内容をここに書く（Markdown）…';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count年前',
      one: '1年前',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => '昨日';

  @override
  String get focusModeStart => 'フォーカスセッションを開始';

  @override
  String get focusModeConfigTitle => 'フォーカスセッションを開始';

  @override
  String get focusModeGoalLabel => '目標';

  @override
  String get focusModeGoalHint => '何に取り組んでいますか？';

  @override
  String get focusModeDurationLabel => '時間';

  @override
  String get focusModeBlockNotifications => '通知をブロック';

  @override
  String get focusModeStartButton => '開始';

  @override
  String get focusModeFloat => 'バーに最小化';

  @override
  String get focusModeActiveTooltip => 'フォーカスモードが有効です — タップして終了';

  @override
  String get dismiss => '閉じる';

  @override
  String get acceptAndResolve => '承認して解決';

  @override
  String reviewFatigueWarning(int minutes) {
    return '$minutes分レビューしています。研究によると、60分を超えるとレビュー品質が低下することがあります。休憩を検討してください。';
  }

  @override
  String get notificationSound => '通知音';

  @override
  String get notificationSoundDescription => '通知の表示時に再生される音です。';

  @override
  String get notificationSoundNone => 'なし';

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
  String get notificationSoundMigrosSoft => 'Migros（ソフト）';

  @override
  String get notificationSoundMigrosHard => 'Migros（ハード）';

  @override
  String get notificationSoundSbb => 'SBB';

  @override
  String get notificationSoundCff => 'CFF';

  @override
  String get notificationSoundFfs => 'FFS';

  @override
  String get notificationSoundPost => 'Post';

  @override
  String get notificationSoundTest => 'テスト';

  @override
  String get notificationVolume => '音量';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'このワークスペースに @$login のPRはありません';
  }

  @override
  String get usersLabel => 'ユーザー';

  @override
  String get mergePullRequest => 'プルリクエストをマージ';

  @override
  String get forceMergePullRequest => 'プルリクエストを強制マージ';

  @override
  String get closePullRequest => 'プルリクエストをクローズ';

  @override
  String get closePullRequestConfirm => 'このプルリクエストをクローズしてもよろしいですか？';

  @override
  String get stackedPullRequests => 'スタックされたプルリクエスト';

  @override
  String partOfStack(int position, int total) {
    return 'スタックの一部（$position / $total）';
  }

  @override
  String get createStack => 'スタックを作成';

  @override
  String get createStackDialogTitle => 'プルリクエストスタックを作成';

  @override
  String createStackDialogBody(int count) {
    return 'これらの$count件のプルリクエストを下から順にスタックします:';
  }

  @override
  String get createStackInvalidSelection =>
      'スタックを作成するには、同じリポジトリからプルリクエストを2件以上選択してください';

  @override
  String get createStackNotAChain =>
      '選択したプルリクエストはチェーンになっていません。各プルリクエストのベースブランチは、直前のヘッドブランチである必要があります';

  @override
  String get createStackAlreadyStacked => '選択したプルリクエストの一部はすでにスタックに含まれています';

  @override
  String get stackCreated => 'スタックを作成しました';

  @override
  String get stackCreationFailed => 'スタックを作成できませんでした';

  @override
  String get squashAndMerge => 'スカッシュしてマージ';

  @override
  String get createMergeCommit => 'マージコミットを作成';

  @override
  String get rebaseAndMerge => 'リベースしてマージ';

  @override
  String get commitTitle => 'コミットタイトル';

  @override
  String get commitDescription => 'コミットの説明';

  @override
  String get pullRequestMerged => 'プルリクエストをマージしました';

  @override
  String get pullRequestClosed => 'プルリクエストをクローズしました';

  @override
  String failedToMergePr(String error) {
    return 'マージできませんでした: $error';
  }

  @override
  String failedToClosePr(String error) {
    return 'クローズできませんでした: $error';
  }

  @override
  String get markReadyForReview => 'レビュー待ちにする';

  @override
  String get markReadyForReviewConfirm =>
      'このプルリクエストは下書きを解除します。レビュアーに通知され、必須チェックがマージをゲートし、準備完了のプルリクエストを監視する自動化が実行されます。';

  @override
  String get convertToDraft => '下書きに変換';

  @override
  String get convertToDraftConfirm =>
      'このプルリクエストは下書きに戻ります。保留中のレビュー依頼は取り下げられ、再度レビュー待ちにするまでマージできません。';

  @override
  String get pullRequestMarkedReady => 'プルリクエストをレビュー待ちにしました';

  @override
  String get pullRequestConvertedToDraft => 'プルリクエストを下書きに変換しました';

  @override
  String failedToMarkPrReady(String error) {
    return 'レビュー待ちにできませんでした: $error';
  }

  @override
  String failedToConvertPrToDraft(String error) {
    return '下書きに変換できませんでした: $error';
  }

  @override
  String get checksFailing => 'チェックが失敗しています';

  @override
  String get reviewsPending => '一部のレビューが保留中です';

  @override
  String get mergeConflictsWithBase => 'このブランチには解決が必要なコンフリクトがあります';

  @override
  String get branchOutOfDateWithBase => 'このブランチはベースブランチより古くなっています';

  @override
  String get mergeBlockedByBranchProtection => 'ブランチ保護によりこのマージはブロックされています';

  @override
  String get confirm => '確認';

  @override
  String get trustedSitesSectionTitle => '信頼済みサイト';

  @override
  String get trustedSitesEmpty =>
      '信頼済みサイトはありません。ドメインを追加すると、そのサイトのブロックを無効にできます。';

  @override
  String get addTrustedSite => '信頼済みサイトを追加';

  @override
  String get removeTrustedSite => '削除';

  @override
  String get disableBlockingForThisSite => 'このサイトのブロックを無効にする';

  @override
  String get enableBlockingForThisSite => 'このサイトのブロックを有効にする';

  @override
  String get enterDomainHint => '例: example.com';

  @override
  String get invalidDomain => '有効なドメインを入力してください（例: example.com）';

  @override
  String get pageLoadTimedOut => 'ページの読み込みがタイムアウトしました。再読み込みするか、ブラウザで開いてください。';

  @override
  String get pipelinesScreenTitle => 'パイプライン';

  @override
  String get pipelinesScreenSubtitle => '宣言的な複数ステップのエージェントワークフロー';

  @override
  String get pipelinesRunPipeline => 'パイプラインを実行';

  @override
  String get pipelineRunLauncherTitle => 'パイプラインを実行';

  @override
  String get pipelineRunSubtitle => 'パイプラインを選び、入力を埋めて実行を開始します。';

  @override
  String get pipelineRunNoInputsBadge => '入力なし';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件の入力',
      one: '1 件の入力',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'このパイプラインに入力はありません。';

  @override
  String get pipelineRunSubmit => 'パイプラインを実行';

  @override
  String get pipelineRunCouldNotStart => '実行を開始できませんでした。';

  @override
  String pipelineRunStarted(String name) {
    return '$name を開始しました';
  }

  @override
  String get pipelineRunEmptyTitle => '実行できるパイプラインがありません';

  @override
  String get pipelineRunEmptyHint =>
      'パイプラインを有効にし、エディターで手動実行をオンにすると、ここから起動できます。';

  @override
  String get pipelineRunManageTemplates => 'パイプラインを管理';

  @override
  String get pipelineRunSettingsTitle => '手動実行';

  @override
  String get pipelineRunSettingsAllow => '手動実行を許可';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'このパイプラインを実行ページに表示し、手動で開始できるようにします。';

  @override
  String get pipelineRunSettingsConcurrencyTitle => '同時実行';

  @override
  String get pipelineRunSettingsMaxParallel => '最大並列実行数';

  @override
  String get pipelineRunSettingsMaxParallelHelp =>
      '空欄にすると無制限です。枠が空くまで、追加の実行はキューで待機します。';

  @override
  String get pipelineRunSettingsMaxParallelHint => '無制限';

  @override
  String get pipelineRunSettingsMaxParallelInvalid =>
      '1以上の整数を入力するか、無制限にする場合は空欄にしてください。';

  @override
  String get pipelineRunSettingsInputsTitle => '入力';

  @override
  String get pipelineRunSettingsAddInput => '入力を追加';

  @override
  String get pipelineRunSettingsNoInputs => '入力はまだありません。';

  @override
  String get pipelineInputEditTitle => '入力フィールド';

  @override
  String get pipelineInputKeyLabel => 'キー';

  @override
  String get pipelineInputKeyHelp => '値が保存されるステートキーです（例: repo_full_name）。';

  @override
  String get pipelineInputLabelLabel => 'ラベル';

  @override
  String get pipelineInputTypeLabel => 'タイプ';

  @override
  String get pipelineInputOptionsLabel => 'オプション（カンマ区切り）';

  @override
  String get pipelineInputDefaultLabel => 'デフォルト値';

  @override
  String get pipelineInputPlaceholderLabel => 'プレースホルダー';

  @override
  String get pipelineInputHelpLabel => 'ヘルプテキスト';

  @override
  String get pipelineInputRequiredLabel => '必須';

  @override
  String get pipelineInputTypeText => 'テキスト';

  @override
  String get pipelineInputTypeMultiline => '複数行テキスト';

  @override
  String get pipelineInputTypeNumber => '数値';

  @override
  String get pipelineInputTypeBoolean => 'トグル';

  @override
  String get pipelineInputTypeSelect => '選択';

  @override
  String get pipelinesEmpty => 'パイプラインの実行はまだありません';

  @override
  String get pipelinesEmptyHint => '「パイプラインを実行」をクリックして開始します。';

  @override
  String get pipelinesNoSteps => 'ステップはまだ記録されていません';

  @override
  String get pipelinesNoActiveWorkspace => 'パイプラインを表示するにはワークスペースを選択してください';

  @override
  String pipelinesLoadError(String error) {
    return 'パイプラインの読み込みに失敗しました: $error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'パイプラインの開始に失敗しました: $error';
  }

  @override
  String get pipelineStatusPending => '保留中';

  @override
  String get pipelineStatusQueued => 'キュー済み';

  @override
  String get pipelineStatusRunning => '実行中';

  @override
  String get pipelineStatusSuspended => '一時停止';

  @override
  String get pipelineStatusCompleted => '完了';

  @override
  String get pipelineStatusFailed => '失敗';

  @override
  String get pipelineStatusCancelled => 'キャンセル済み';

  @override
  String get pipelineStatusSkipped => 'スキップ済み';

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed / $total ステップ';
  }

  @override
  String get pipelineWaterfallTimeline => 'タイムライン';

  @override
  String pipelineWaterfallActive(String duration) {
    return 'アクティブ $duration';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return 'アイドル $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip =>
      'アクティブ合計から除外された時間です。実行が停止していたか、ステップ間で待機していました。';

  @override
  String get pipelineStepStarted => '開始';

  @override
  String get pipelineStepFinished => '終了';

  @override
  String get pipelineStepDurationLabel => '所要時間';

  @override
  String get pipelineStepBranch => 'ブランチ';

  @override
  String get pipelineStepViewConversation => '会話を表示';

  @override
  String get pipelineStepError => 'エラー';

  @override
  String get pipelineStepInput => '入力';

  @override
  String get pipelineStepOutput => '出力';

  @override
  String get pipelineStepNotExecuted => '未実行';

  @override
  String pipelineRunFailedAtStep(String step) {
    return '$step で失敗';
  }

  @override
  String get pipelineRunTriggerManual => '手動';

  @override
  String get pipelineStepSkippedReason => 'スキップ済み';

  @override
  String get pipelineStepPriorAttempts => '以前の試行';

  @override
  String get pipelineStepAttemptLabel => '試行';

  @override
  String pipelineStepAttemptN(int number) {
    return '試行 $number';
  }

  @override
  String get pipelineStepAttemptInterrupted => '中断';

  @override
  String get pipelineRunColumnPipeline => 'パイプライン';

  @override
  String get pipelineRunColumnDuration => '所要時間';

  @override
  String get pipelineRunQueueNext => '次';

  @override
  String pipelineRunQueuePosition(int position) {
    return 'キュー $position 番目';
  }

  @override
  String get pipelineRunColumnStarted => '開始';

  @override
  String get pipelineRunHistory => '実行履歴';

  @override
  String get pipelineRunHistoryEmpty => '他の実行はまだありません';

  @override
  String pipelineRunRerunAgo(String time) {
    return '再実行 $time';
  }

  @override
  String pipelineRunAttempt(int number) {
    return '試行 $number';
  }

  @override
  String pipelineRunFirstStarted(String time) {
    return '初回開始 $time';
  }

  @override
  String get pipelineRunFilterAll => 'すべて';

  @override
  String get pipelineRunFilterEmpty => 'このフィルターに一致する実行はありません';

  @override
  String get relativeJustNow => 'たった今';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count分前',
      one: '1分前',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count時間前',
      one: '1時間前',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日前',
      one: '1日前',
    );
    return '$_temp0';
  }

  @override
  String get teamsTitle => 'チーム';

  @override
  String get teamsAddTeam => 'チームを追加';

  @override
  String get teamsLoadError => 'チームを読み込めませんでした';

  @override
  String get teamsEmptyTitle => 'チームはまだありません';

  @override
  String get teamsEmptyDescription =>
      'エージェントをチームにまとめます。チームに割り当てられた作業は、委任するリーダー経由で流れます。';

  @override
  String get teamCreateTitle => '新しいチーム';

  @override
  String get teamEditTitle => 'チームを編集';

  @override
  String get teamNameLabel => 'チーム名';

  @override
  String get teamNameHint => '例: Frontend';

  @override
  String get teamDescriptionLabel => '説明';

  @override
  String get teamDescriptionHint => 'このチームの担当範囲';

  @override
  String get teamLeaderLabel => 'リーダー';

  @override
  String get teamLeaderHelp => 'チームに割り当てられた作業を受け取り、最適なメンバーに委任するコーディネーターです。';

  @override
  String get teamNoLeader => 'リーダーなし';

  @override
  String get teamInstructionsLabel => '運用指示';

  @override
  String get teamInstructionsHelp =>
      'リーダーのブリーフィングに追記されます。チームの慣例、エスカレーションルール、トーンなどです。';

  @override
  String get teamInstructionsHint => '任意';

  @override
  String get teamSaved => 'チームを保存しました';

  @override
  String get teamMembersError => 'メンバーを読み込めませんでした';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count人',
      one: '1人',
      zero: 'メンバーなし',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => 'メンバーを追加';

  @override
  String get teamAddMemberTitle => 'メンバーを追加';

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
  String get teamNoAgentsToAdd => 'すべてのエージェントがすでにこのチームに入っています。';

  @override
  String get teamRemoveMember => 'チームから削除';

  @override
  String get teamLeaderBadge => 'リーダー';

  @override
  String get teamUnknownAgent => '不明なエージェント';

  @override
  String get teamMembersEmpty => 'メンバーはまだいません';

  @override
  String get teamMembersEmptyDescription => 'リーダーが委任できるよう、エージェントを追加してください。';

  @override
  String get teamSelectPrompt => 'チームを選択';

  @override
  String get teamSelectPromptDescription => 'リストからチームを選ぶか、新しく作成してください。';

  @override
  String get teamDeleteTitle => 'チームを削除しますか？';

  @override
  String teamDeleteBody(String name) {
    return '$name を削除します。所属エージェントには影響しません。';
  }

  @override
  String get teamHasLeaderTooltip => 'リーダーあり';

  @override
  String get pipelineTemplatesNav => 'パイプラインテンプレート';

  @override
  String get pipelineTemplatesTitle => 'パイプラインテンプレート';

  @override
  String get pipelineTemplatesSubtitle =>
      'エージェントを編成するパイプライン用のドラッグ＆ドロップエディターです。';

  @override
  String get pipelineTemplatesNew => '新しいテンプレート';

  @override
  String get pipelineTemplatesEmpty => 'パイプラインテンプレートはまだありません。作成して始めましょう。';

  @override
  String get pipelineTemplateBuiltInBadge => '組み込み';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'テンプレートを削除しますか？';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'パイプラインテンプレート $name を削除しますか？この操作は取り消せません。';
  }

  @override
  String get pipelineTemplateEditorSubtitle =>
      'サイドバーからノード種別をキャンバスにドラッグし、接続してください。';

  @override
  String get unsavedChanges => '未保存の変更';

  @override
  String get nodeLibraryTitle => 'ノードライブラリ';

  @override
  String get nodeLibraryHint => '項目をキャンバスにドラッグするとノードが追加されます。';

  @override
  String get editorEmptyCanvas => 'ライブラリからノードをドラッグして開始してください。';

  @override
  String get pipelineWhenThisHappens => 'これが起きたとき';

  @override
  String get pipelineDoThis => 'これを実行';

  @override
  String get pipelineAddStep => 'ステップを追加';

  @override
  String get pipelineTidyUp => 'レイアウトを整える';

  @override
  String get pipelineEditorHint => 'ステップをドラッグして配置 · ハンドルをドラッグして接続';

  @override
  String get pipelineRemoveConnection => '接続を削除';

  @override
  String get pipelineDragToConnect => 'ドラッグして接続';

  @override
  String get pipelineNewDefaultName => '新しいパイプライン';

  @override
  String get nodeCategoryTriggers => 'トリガー';

  @override
  String get triggerEventWebhook => 'Webhook';

  @override
  String get pipelineAddTrigger => 'トリガーを追加';

  @override
  String get pipelineOnEvent => 'イベント時';

  @override
  String get nodeConfigTitle => 'ノード設定';

  @override
  String get nodeConfigKind => '種別';

  @override
  String get nodeConfigLabel => 'ラベル';

  @override
  String get nodeConfigAgent => 'エージェント';

  @override
  String get nodeConfigAgentHint => 'エージェントを選択…';

  @override
  String get nodeConfigInputKeys => '入力キー（カンマ区切り）';

  @override
  String get nodeConfigInputKeysHelp =>
      'このノードが参照する状態キーです。プロンプトのプレースホルダー置換に使います。';

  @override
  String get nodeConfigRepos => 'クローンするリポジトリ';

  @override
  String get nodeConfigReposHelp =>
      'このノードが会話を開始するときにクローンし、コードインデックスするリポジトリです。すべてのリポジトリを選ぶとすべてをクローンします（デフォルト）。';

  @override
  String get nodeConfigRepoBranchHint => 'ブランチ（デフォルト）';

  @override
  String get nodeConfigRepoBranchHelp =>
      '各チェックアウトの元になるブランチです。空欄にするとリポジトリ自身のデフォルトブランチを使います。ワークツリーには独自のブランチが切られるため、エージェントのコミットはこのブランチには入りません。';

  @override
  String nodeConfigReposDynamic(String entries) {
    return '保持する動的エントリ: $entries';
  }

  @override
  String get nodeConfigCreateConversation => '会話を開く';

  @override
  String get nodeConfigCreateConversationHelp =>
      '後続に複数のエージェントノードがある場合はオフにしてください。それぞれが名前付きストリームを開きます。後続が1つのエージェントノードだけのときはオンにすると、無題の会話が部屋に並んで表示されません。';

  @override
  String get nodeConfigConversationTitle => '会話名';

  @override
  String get nodeConfigConversationTitleHelp =>
      '後続のエージェントノードに同じ名前を付けると、同じストリームで動作します。デフォルトはノードのラベルです。';

  @override
  String get nodeConfigSpaceName => 'スペース名';

  @override
  String get nodeConfigSpaceNameHelp =>
      'このノードが開く部屋の名前です。プロンプトと同じ状態プレースホルダーを使えます。空欄にするとノードのラベルを使います。';

  @override
  String get nodeConfigSpaceNameHint => 'pr_number のレビュー';

  @override
  String get nodeConfigStreamTitle => '会話名';

  @override
  String get nodeConfigStreamTitleHelp =>
      'このノードのエージェントが部屋内で作業する名前付きストリームです。プロンプトと同じ状態プレースホルダーを使えます。空欄にすると、部屋の常設会話にターンが入り、ファンアウトですべてのエージェントが交互に並びます。';

  @override
  String get nodeConfigConversationTitleHint => 'アーキテクチャ分析';

  @override
  String get nodeConfigOutputKey => '出力キー';

  @override
  String get nodeConfigPrompt => 'プロンプトテンプレート';

  @override
  String get nodeConfigPromptHelp => '二重波括弧のプレースホルダーで、実行時に状態から値を取り込めます。';

  @override
  String get nodeConfigScript => 'Bash スクリプト';

  @override
  String get nodeConfigScriptHelp =>
      'bash -c で実行します。GITHUB_TOKEN が設定されます。プレースホルダーは実行前に置換されます。';

  @override
  String get nodeConfigRouteKeys => 'ルートキー';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return '$source からのルートキー';
  }

  @override
  String get conditionSectionTitle => '条件';

  @override
  String get conditionMode => 'モード';

  @override
  String get conditionModeFilesAny => 'ファイルが存在する（いずれか）';

  @override
  String get conditionModeFilesAll => 'ファイルが存在する（すべて）';

  @override
  String get conditionModeComparison => '比較';

  @override
  String get conditionModeSwitch => 'スイッチ';

  @override
  String get conditionFilePaths => 'ファイルパス';

  @override
  String get conditionFilePathsAnyHelp =>
      '1行に1パス、ベースディレクトリからの相対パスです。いずれかが存在すれば true にルーティングします。';

  @override
  String get conditionFilePathsAllHelp =>
      '1行に1パス、ベースディレクトリからの相対パスです。すべてが存在するときだけ true にルーティングします。';

  @override
  String get conditionBaseKey => 'ベースディレクトリキー';

  @override
  String get conditionBaseKeyHelp =>
      'パス解決の基準ディレクトリを持つ状態キーです（デフォルトは repo_local_path）。';

  @override
  String get conditionRecursive => 'サブディレクトリも検索';

  @override
  String get conditionNegate => '反転: 存在しないとき true にルーティング';

  @override
  String get conditionLeft => '左の値';

  @override
  String get conditionOperator => '演算子';

  @override
  String get conditionRight => '右の値';

  @override
  String get conditionSwitchKey => '切り替え対象の状態キー';

  @override
  String get conditionCases => 'ケース（カンマ区切り）';

  @override
  String get conditionCasesHelp => '値と照合するルートキーです。順に評価します。';

  @override
  String get conditionDefaultCase => 'デフォルトケース';

  @override
  String get triggerManualHelp => '実行ページに表示し、手動で開始します。';

  @override
  String get triggerKindSchedule => 'スケジュール時';

  @override
  String get triggerScheduleExprLabel => 'スケジュール（cron または every:seconds）';

  @override
  String get triggerTimezoneLabel => 'タイムゾーン（任意）';

  @override
  String get triggerCatchUpLabel => '取りこぼした実行';

  @override
  String get triggerCatchUpRunOnce => '1回実行';

  @override
  String get triggerCatchUpSkip => 'スキップ';

  @override
  String get syncHealthTitle => '同期の健全性';

  @override
  String get syncHealthNoConfigs => '同期接続はまだありません';

  @override
  String get syncHealthNeverSynced => '未同期';

  @override
  String get syncOutcomeOk => '同期済み';

  @override
  String get syncOutcomeFailed => '失敗';

  @override
  String get syncOutcomeSkipped => 'スキップ';

  @override
  String syncHealthFailedStreak(int count) {
    return '$count 回連続で失敗';
  }

  @override
  String get triggerWebhookHelp =>
      '署名付きの Webhook URL が生成されます。外部システムが POST すると、このパイプラインが開始されます。';

  @override
  String get triggerWebhookPathLabel => 'Webhook のパス';

  @override
  String get triggerMatchStatusLabel => 'ステータスが次のときのみ';

  @override
  String get triggerSummaryNone => 'トリガーなし';

  @override
  String triggerEverySeconds(int seconds) {
    return '$seconds 秒ごと';
  }

  @override
  String get triggerEventManual => '手動実行';

  @override
  String get triggerEventSchedule => 'スケジュール';

  @override
  String get triggerEventPrStatusChanged => 'PR のステータス変更';

  @override
  String get triggerEventExternalPr => '外部 PR がオープン';

  @override
  String get triggerEventPrPublished => 'PR が公開';

  @override
  String get triggerEventPrMerged => 'PR がマージ';

  @override
  String get triggerEventRepoAdded => 'リポジトリが追加';

  @override
  String get triggerEventCodeGraphWatch => 'ファイル変更';

  @override
  String pipelineRunCauseChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '変更ファイル $count 件',
      one: '変更ファイル 1 件',
    );
    return '$_temp0';
  }

  @override
  String pipelineRunCauseMorePaths(int count) {
    return '+$count 件';
  }

  @override
  String get pipelineRunCauseRescan => 'ディスク上で変更';

  @override
  String get pipelineRunCauseInitial => 'このチェックアウトの初回インデックス';

  @override
  String get triggerEventMessageReceived => 'メッセージ受信';

  @override
  String get triggerEventTicketCompleted => 'チケット完了';

  @override
  String get triggerEventTicketFailed => 'チケット失敗';

  @override
  String get triggerEventTicketCancelled => 'チケットキャンセル';

  @override
  String get triggerEventBudgetCrossed => '予算のしきい値を超過';

  @override
  String get nodeLibrarySearchHint => 'ノードを検索';

  @override
  String get nodeLibraryNoMatches => '一致するノードはありません';

  @override
  String get nodeCategoryFlow => 'フローとロジック';

  @override
  String get nodeCategoryPr => 'PR レビュー';

  @override
  String get nodeCategoryAgents => 'エージェント';

  @override
  String get nodeCategoryMessaging => 'メッセージング';

  @override
  String get nodeCategoryCode => 'コード';

  @override
  String get triggerDisabledTag => 'オフ';

  @override
  String get pipelineInputTypeRepo => 'リポジトリ';

  @override
  String get pipelineRunNoRepos => 'このワークスペースにはまだリポジトリがありません。';

  @override
  String get allowTicketingApi => 'チケット API の呼び出しを許可';

  @override
  String get ticketingApiKey => 'チケット API キー';

  @override
  String get ticketingApiKeySubtitle => 'チケットプロバイダーの API キーをサンドボックスに注入します。';

  @override
  String get ticketingProvider => 'チケットプロバイダー';

  @override
  String get connectGitHubAndTicketing =>
      'コードホストを接続すると、Control Center がプルリクエスト、Issue、レビューを読み取れます。チケットプロバイダーの接続は任意です。認証情報はこのマシンではなく、サーバー側で保持されます。';

  @override
  String get triggerEventTicketAssigned => 'チケット割り当て';

  @override
  String get triggerEventTicketCreated => 'チケットが作成';

  @override
  String get triggerEventTicketStatusChanged => 'チケットの状態が変更';

  @override
  String get triggerEventMeetingRecordingStopped => '会議の録音が停止';

  @override
  String get triggerEventSkillUpdated => 'スキルが更新';

  @override
  String get triggerEventSpaceDeleted => 'スペースが削除';

  @override
  String get triggerExternalPrHelp =>
      'コードホスト上で開かれたプルリクエスト。Control Center からではありません。';

  @override
  String get triggerPrPublishedHelp => 'Control Center またはエージェントが開いたプルリクエスト。';

  @override
  String get triggerPrStatusChangedHelp =>
      'マージ、クローズ、オープン、再オープン、または承認。インスペクターで状態を絞り込みます。';

  @override
  String get triggerPrMergedHelp => 'プルリクエストがマージされたときのみ。クローズや再オープンでは動きません。';

  @override
  String get triggerRepoAddedHelp => 'このワークスペースにリポジトリがリンクされます。';

  @override
  String get triggerCodeGraphWatchHelp => 'リンクされたリポジトリのファイルがディスク上で変わります。';

  @override
  String get triggerMessageReceivedHelp => 'スペースに新しいメッセージが届きます。';

  @override
  String get triggerTicketCreatedHelp => 'このワークスペースでチケットが作成されます。';

  @override
  String get triggerTicketStatusChangedHelp => 'チケットの状態が変わります。';

  @override
  String get triggerTicketCompletedHelp => 'チケットが正常に完了します。';

  @override
  String get triggerTicketFailedHelp => 'エージェントの実行が失敗し、チケットが失敗として記録されます。';

  @override
  String get triggerTicketCancelledHelp => 'チケットがキャンセルされ、続きません。';

  @override
  String get triggerBudgetCrossedHelp => 'ワークスペースまたはエージェントの支出上限を超えます。';

  @override
  String get triggerTicketAssignedHelp => 'チケットが人、エージェント、またはチームに割り当てられます。';

  @override
  String get triggerMeetingRecordingStoppedHelp => '会議の録音が終わります。';

  @override
  String get triggerSkillUpdatedHelp => 'スキルがインストールまたは更新されます。';

  @override
  String get triggerSpaceDeletedHelp => '会話スペースが削除されます。';

  @override
  String get navTickets => 'チケット';

  @override
  String get ticketsTitle => 'チケット';

  @override
  String get newTicket => '新規チケット';

  @override
  String get noTicketsYet => 'チケットはまだありません';

  @override
  String get addCollaborator => 'コラボレーターを追加';

  @override
  String get noCollaborators => 'コラボレーターはまだいません';

  @override
  String get linkedPullRequests => 'リンク済みプルリクエスト';

  @override
  String get noLinkedPullRequests => 'リンク済みプルリクエストはまだありません';

  @override
  String get stopAgent => 'エージェントを停止';

  @override
  String get ticketProperties => 'プロパティ';

  @override
  String get ticketTabIssue => 'Issue';

  @override
  String get ticketSelectPrompt => 'チケットを選択すると詳細を表示できます';

  @override
  String get unassigned => '未割り当て';

  @override
  String get ticketStatusBacklog => 'バックログ';

  @override
  String get ticketStatusOpen => '未着手';

  @override
  String get ticketStatusInProgress => '進行中';

  @override
  String get ticketStatusInReview => 'レビュー中';

  @override
  String get ticketStatusDone => '完了';

  @override
  String get ticketStatusBlocked => 'ブロック中';

  @override
  String get ticketStatusFailed => '失敗';

  @override
  String get ticketStatusCancelled => 'キャンセル';

  @override
  String get notificationTicketAssigned => 'チケット割り当て';

  @override
  String get notificationTicketStatusChanged => 'チケットのステータス変更';

  @override
  String get priority => '優先度';

  @override
  String get status => 'ステータス';

  @override
  String get assignee => '担当者';

  @override
  String get labels => 'ラベル';

  @override
  String get noLabelsYet => 'ラベルはまだありません';

  @override
  String get clearLabels => 'ラベルをクリア';

  @override
  String get pipelineStepAgentActivity => 'エージェントのアクティビティ';

  @override
  String get runStatusCompleted => '完了';

  @override
  String get runStatusQueued => 'キュー中';

  @override
  String get ticketDescription => '説明';

  @override
  String get ticketPriorityNone => 'なし';

  @override
  String get ticketPriorityUrgent => '緊急';

  @override
  String get ticketPriorityHigh => '高';

  @override
  String get ticketPriorityMedium => '中';

  @override
  String get ticketPriorityLow => '低';

  @override
  String get ticketViewList => 'リスト';

  @override
  String get ticketViewBoard => 'ボード';

  @override
  String get ticketTitlePlaceholder => '課題のタイトル';

  @override
  String get ticketDescriptionPlaceholder => '説明を追加…';

  @override
  String get createMore => '続けて作成';

  @override
  String selectedCount(int count) {
    return '$count件選択中';
  }

  @override
  String get clearSelection => '選択を解除';

  @override
  String get bulkDeleteTitle => 'チケットを削除';

  @override
  String bulkDeleteMessage(int count) {
    return '選択した$count件のチケットを削除しますか？この操作は元に戻せません。';
  }

  @override
  String get assignTo => '割り当て先…';

  @override
  String get sectionMembers => 'メンバー';

  @override
  String get sectionAgents => 'エージェント';

  @override
  String get sidebarGroupWorkspace => 'ワークスペース';

  @override
  String get notificationsTitle => '通知';

  @override
  String get notificationsTooltip => '通知';

  @override
  String get notificationsEmpty => 'すべて確認済みです';

  @override
  String notificationsUnreadCount(int count) {
    return '未読$count件';
  }

  @override
  String get notificationsMarkRead => '既読にする';

  @override
  String get notificationsMarkUnread => '未読にする';

  @override
  String get notificationsEntryActions => '通知の操作';

  @override
  String get markAllRead => 'すべて既読にする';

  @override
  String get teamsNav => 'チーム';

  @override
  String get noWorkspace => 'ワークスペースなし';

  @override
  String get selectWorkspace => 'ワークスペースを選択';

  @override
  String get navMemory => 'メモリ';

  @override
  String get memoryTabFacts => '事実';

  @override
  String get memoryTabPolicies => 'ポリシー';

  @override
  String get memoryGraphShowFacts => '事実を表示';

  @override
  String get memoryGraphHideFacts => '事実を非表示';

  @override
  String get memoryGraphExpandAll => 'すべての事実を展開';

  @override
  String get memoryGraphCollapseAll => 'すべての事実を折りたたむ';

  @override
  String get memoryTabGraph => 'ナレッジグラフ';

  @override
  String get memoryNoWorkspace => 'メモリを表示するには、ワークスペースを選択してください。';

  @override
  String get searchArticles => '記事を検索';

  @override
  String get filterAll => 'すべて';

  @override
  String get filterUnread => '未読';

  @override
  String get filterSaved => '保存済み';

  @override
  String get saveArticle => '記事を保存';

  @override
  String get removeFromSaved => '保存から削除';

  @override
  String get filterBySource => 'ソースで絞り込み';

  @override
  String get viewAsList => 'リスト表示';

  @override
  String get viewAsGrid => 'グリッド表示';

  @override
  String get noMatchingArticles => '一致する記事はありません';

  @override
  String get noMatchingArticlesBody => '別の検索またはソースフィルターをお試しください。';

  @override
  String get allCaughtUp => 'すべて確認済み';

  @override
  String get allCaughtUpBody => '未読の記事はありません。後でもう一度ご確認ください。';

  @override
  String get openArticlesInAppDescription => 'デフォルトのブラウザではなく、内蔵リーダーでリンクを開きます。';

  @override
  String get blockAdsTrackersDescription =>
      'リーダーで開く記事から広告、トラッカー、Cookie バナーを除去します。';

  @override
  String get agentQuestionHeader => '質問があります';

  @override
  String get agentQuestionAnsweredLabel => '回答済み';

  @override
  String get agentQuestionFreeformHint => '回答を入力…';

  @override
  String agentQuestionProgress(int index, int count) {
    return '質問 $index / $count';
  }

  @override
  String get agentQuestionSkip => 'スキップ';

  @override
  String get agentQuestionSkippedLabel => 'スキップ済み';

  @override
  String get agentQuestionFreeformOptionHint => '自分の言葉で書いてください…';

  @override
  String get reviewRequested => 'レビュー依頼済み';

  @override
  String get connectGitHubHint =>
      'GitHub にサインインするか、設定 → あなた → プロフィールと ID → コードホスティング でトークンを追加してください';

  @override
  String get connectGitHubToLoadPrs => 'プルリクエストを読み込むには GitHub を接続してください';

  @override
  String get noRepositoriesConfigured => 'リポジトリが設定されていません';

  @override
  String openedAgo(String age) {
    return '$ageにオープン';
  }

  @override
  String prTimelineOpened(String author) {
    return '$author がこのプルリクエストをオープンしました';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のコミット',
      one: '1 件のコミット',
    );
    return '$author がこのプルリクエストを $_temp0 とともにオープンしました';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return '$actor が $reviewers にレビューを依頼しました';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '$actor が $reviewers へのレビュー依頼を取り消しました';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '$actor が $requested にレビューを依頼し、$removed へのレビュー依頼を取り消しました';
  }

  @override
  String prTimelineAddedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ラベル',
      one: 'ラベル',
    );
    return '$actor が $labels $_temp0 を追加しました';
  }

  @override
  String prTimelineRemovedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ラベル',
      one: 'ラベル',
    );
    return '$actor が $labels $_temp0 を削除しました';
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
      other: 'ラベル',
      one: 'ラベル',
    );
    String _temp1 = intl.Intl.pluralLogic(
      removedCount,
      locale: localeName,
      other: 'ラベル',
      one: 'ラベル',
    );
    return '$actor が $added $_temp0 を追加し、$removed $_temp1 を削除しました';
  }

  @override
  String prTimelineCommitted(String author) {
    return '$author がコミットしました';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のコミット',
      one: '1 件のコミット',
    );
    return '$author が $_temp0 をプッシュしました';
  }

  @override
  String prTimelineApproved(String author) {
    return '$author が変更を承認しました';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return '$author が変更を要求しました';
  }

  @override
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'コードコメント $count 件',
      one: 'コードコメント 1 件',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '$author がレビューしました';
  }

  @override
  String get prTimelineSomeone => '誰か';

  @override
  String get prTimelineBotBadge => 'bot';

  @override
  String updatedAgo(String age) {
    return '$ageに更新';
  }

  @override
  String get checksPassing => 'チェックは合格';

  @override
  String get checksRunning => 'チェック実行中';

  @override
  String get needsYourReview => 'あなたのレビューが必要';

  @override
  String get checks => 'チェック';

  @override
  String get noReviewersAssigned => 'レビュアー未割り当て';

  @override
  String get noAssignees => '担当者なし';

  @override
  String get loadingEllipsis => '読み込み中…';

  @override
  String get loadingChecks => 'チェックを読み込み中…';

  @override
  String get noChecksYet => 'まだチェックは実行されていません';

  @override
  String get noChangesToReview => 'レビューする変更はありません';

  @override
  String checksFailingCount(int count) {
    return '$count 件失敗';
  }

  @override
  String get showMore => 'さらに表示';

  @override
  String get showLess => '表示を減らす';

  @override
  String get backToPullRequests => 'プルリクエストに戻る';

  @override
  String get pullRequestNotFound => 'プルリクエストが見つかりません';

  @override
  String get pullRequestNotFoundBody => 'マージ、クローズ、または移動された可能性があります。';

  @override
  String get couldntLoadPullRequest => 'このプルリクエストを読み込めませんでした';

  @override
  String get showDetails => '詳細を表示';

  @override
  String get noDescriptionProvided => '説明はありません。';

  @override
  String get factsHint => 'エージェントが学習するにつれて、ファクトがここに表示されます。';

  @override
  String get noFactsMatch => '検索に一致するファクトはありません';

  @override
  String get memoryLoadError => 'メモリを読み込めませんでした';

  @override
  String get sortRecent => '最近';

  @override
  String get sortConfidence => '確信度';

  @override
  String get confidenceTooltip => 'エージェントがこの事実をどの程度確実と見ているかを、0〜100%で示します。';

  @override
  String get supersededTooltip => 'より新しい事実に置き換えられています。';

  @override
  String get domain => 'ドメイン';

  @override
  String get fitToView => '画面に合わせる';

  @override
  String get project => 'プロジェクト';

  @override
  String get newProject => '新規プロジェクト';

  @override
  String get editProject => 'プロジェクトを編集';

  @override
  String get deleteProject => 'プロジェクトを削除';

  @override
  String get noProject => 'プロジェクトなし';

  @override
  String get allTickets => 'すべてのチケット';

  @override
  String get projectNamePlaceholder => 'プロジェクト名';

  @override
  String get projectDescriptionPlaceholder => '説明（任意）';

  @override
  String get projectColorLabel => '色';

  @override
  String get noProjectsYet => 'まだプロジェクトがありません';

  @override
  String get projectTicketsEmpty => 'このプロジェクトにはまだチケットがありません';

  @override
  String get createProject => 'プロジェクトを作成';

  @override
  String projectProgress(int done, int total) {
    return '$total件中$done件完了';
  }

  @override
  String deleteProjectConfirm(String name) {
    return '「$name」を削除しますか？チケットは残りますが、プロジェクトから外れます。';
  }

  @override
  String get projectStatusActive => 'アクティブ';

  @override
  String get projectStatusCompleted => '完了';

  @override
  String get projectStatusArchived => 'アーカイブ済み';

  @override
  String get markProjectCompleted => '完了にする';

  @override
  String get markProjectActive => 'アクティブにする';

  @override
  String get archiveProject => 'アーカイブ';

  @override
  String get restoreProject => '復元';

  @override
  String get relations => '関連';

  @override
  String get relateTo => '関連付ける';

  @override
  String get relationSubIssueOf => '…のサブイシュー';

  @override
  String get relationParentOf => '…の親';

  @override
  String get relationBlockedBy => '…にブロックされている';

  @override
  String get relationBlocking => '…をブロック中';

  @override
  String get relationRelatedTo => '…に関連';

  @override
  String get relationDuplicateOf => '…の重複';

  @override
  String get relationGroupParent => '親';

  @override
  String get relationGroupSubIssues => 'サブイシュー';

  @override
  String get relationGroupBlockedBy => 'ブロック元';

  @override
  String get relationGroupBlocking => 'ブロック中';

  @override
  String get relationGroupRelated => '関連';

  @override
  String get relationGroupDuplicateOf => '重複元';

  @override
  String get relationGroupDuplicatedBy => '重複先';

  @override
  String get copyId => 'IDをコピー';

  @override
  String get ticketIdCopied => 'チケットIDをコピーしました';

  @override
  String get searchTicketsHint => 'チケットを検索…';

  @override
  String get noMatchingTickets => '一致するチケットはありません';

  @override
  String get clearAll => 'すべてクリア';

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs件のPR',
      one: '1件のPR',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos件のリポジトリ',
      one: '1件のリポジトリ',
    );
    return '$_temp0が、$_temp1でレビュー待ちです';
  }

  @override
  String get manageWorkspacesSubtitle =>
      'ワークスペースの名前とマークを変更できます。左の一覧から編集するワークスペースを選んでください。';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のワークスペース',
      one: '1件のワークスペース',
      zero: 'ワークスペースなし',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos件のリポジトリ',
      one: '1件のリポジトリ',
      zero: 'リポジトリなし',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents件のエージェント',
      one: '1件のエージェント',
      zero: '0件のエージェント',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'アイデンティティ';

  @override
  String get uploadImage => '画像をアップロード';

  @override
  String get failedToSaveLogo =>
      'ロゴ画像の保存に失敗しました。アプリが選択したファイルを読み取れることを確認してください。';

  @override
  String get workspaceLogoHint =>
      'PNG、JPG、GIF（最大2 MB）。指定しない場合はワークスペース名の頭文字を使用します。';

  @override
  String get workspaceNameFieldHelp => 'スイッチャー、パンくずリスト、各画面に表示されます。';

  @override
  String get dangerZone => '危険ゾーン';

  @override
  String get deleteThisWorkspace => 'このワークスペースを削除';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return '$nameと、そのリポジトリ接続、エージェント、メモリを完全に削除します。この操作は元に戻せません。';
  }

  @override
  String get discard => '破棄';

  @override
  String discardChangesQuestion(String name) {
    return '$nameへの未保存の変更を破棄しますか？';
  }

  @override
  String get workspaceUpdated => 'ワークスペースを更新しました';

  @override
  String get editTitle => 'タイトルを編集';

  @override
  String get editDescription => '説明を編集';

  @override
  String get addDescription => '説明を追加';

  @override
  String get prTitlePlaceholder => 'タイトル';

  @override
  String get prBodyPlaceholder => '説明を入力';

  @override
  String get write => '書く';

  @override
  String get overview => '概要';

  @override
  String get noFilesChanged => '変更されたファイルはありません';

  @override
  String get diff => '差分';

  @override
  String get preview => 'プレビュー';

  @override
  String get outdated => '古い';

  @override
  String get outdatedComments => '古いコメント';

  @override
  String outdatedCountLabel(int count) {
    return '$count 件が古い';
  }

  @override
  String get prTemplateLabel => 'テンプレート';

  @override
  String get prTemplateDefault => 'デフォルト';

  @override
  String get addReviewers => 'レビュアーを追加';

  @override
  String get addAssignees => '担当者を追加';

  @override
  String get searchUsers => 'ユーザーを検索…';

  @override
  String get searchReviewers => 'ユーザーとチームを検索…';

  @override
  String get usersSectionLabel => 'ユーザー';

  @override
  String get userStatusBusy => '取り込み中';

  @override
  String get teamsSectionLabel => 'チーム';

  @override
  String get suggestedReviewers => 'おすすめのレビュアー';

  @override
  String get noMatchingUsers => '一致するユーザーはいません';

  @override
  String get noMatchingReviewers => '一致するものはありません';

  @override
  String get requiredByCodeOwners => 'コードオーナーにより必須';

  @override
  String reviewedOnBehalfOf(String login) {
    return '$login 経由';
  }

  @override
  String get team => 'チーム';

  @override
  String get markdownBold => '太字';

  @override
  String get markdownItalic => '斜体';

  @override
  String get markdownHeading => '見出し';

  @override
  String get markdownBulletList => '箇条書き';

  @override
  String get markdownChecklist => 'チェックリスト';

  @override
  String get markdownCode => 'コード';

  @override
  String get markdownLink => 'リンク';

  @override
  String get markdownQuote => '引用';

  @override
  String get markdownSupported => 'Markdown に対応しています';

  @override
  String get markdownAttachImages => 'クリックして画像を追加';

  @override
  String failedToUpdateTitle(String error) {
    return 'タイトルを更新できませんでした: $error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return '説明を更新できませんでした: $error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'レビュアーを更新できませんでした: $error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return '担当者を更新できませんでした: $error';
  }

  @override
  String get discardChangesConfirm => '変更を破棄しますか？';

  @override
  String get newPr => '新しい PR';

  @override
  String get openPullRequest => 'プルリクエストを作成';

  @override
  String get composePrSubtitle => 'プッシュ済みのブランチから作成します。エージェントやチケットは使いません';

  @override
  String get createAsDraft => 'ドラフトとして作成';

  @override
  String get composePrNoRepo => 'GitHub リポジトリが選択されていません';

  @override
  String get composePrNoRepoHint =>
      'プルリクエストを作成するには、GitHub と連携したリポジトリがあるワークスペースを選択してください。';

  @override
  String get composePrPickBranches => 'ベースブランチと比較ブランチを選ぶと、変更内容をプレビューできます。';

  @override
  String get composePrNothingToCompare => 'これらのブランチ間に変更はありません。';

  @override
  String get repository => 'リポジトリ';

  @override
  String get baseBranchLabel => 'ベース';

  @override
  String get compareBranchLabel => '比較';

  @override
  String get selectBranch => 'ブランチを選択';

  @override
  String get navMeetings => 'ミーティング';

  @override
  String get meetingsNoWorkspace => 'ミーティングを表示するには、ワークスペースを選択してください。';

  @override
  String get meetingsEmpty => 'まだミーティングはありません';

  @override
  String get meetingsEmptyHint =>
      '最初のミーティングを録音してください。音声はこのデバイスに残り、エージェントがノート、決定事項、アクションアイテムにまとめます。';

  @override
  String get meetingNotesHint => '簡単なメモを残してください。会議後にエージェントが展開します。';

  @override
  String get meetingSpeakerMe => '自分';

  @override
  String get meetingStatusRecording => '録音中';

  @override
  String get meetingStatusProcessing => '処理中';

  @override
  String get meetingStatusDone => '完了';

  @override
  String get meetingStatusFailed => '失敗';

  @override
  String get meetingsSubtitle => 'このデバイスで録音・文字起こしし、エージェントが要約します。';

  @override
  String get meetingsRecordMeeting => '会議を録音';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件を処理中',
      one: '1件を処理中',
    );
    return '$_temp0';
  }

  @override
  String meetingsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の会議',
      one: '1件の会議',
      zero: '会議なし',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLedgerOpenActions => '未完了アクション';

  @override
  String get meetingsLedgerDecisions => '決定事項';

  @override
  String get meetingsLiveOpen => '録音を開く';

  @override
  String get meetingTemplateShort => 'テンプレート';

  @override
  String get meetingsStatThisWeek => '今週';

  @override
  String get meetingsStatRecorded => '録音済み';

  @override
  String get meetingsFilterAll => 'すべて';

  @override
  String get meetingsFilterDone => '完了';

  @override
  String get meetingsFilterProcessing => '処理中';

  @override
  String get meetingsSearchHint => 'タイトル、人名、アプリで絞り込み…';

  @override
  String get meetingsBucketToday => '今日';

  @override
  String get meetingsBucketYesterday => '昨日';

  @override
  String get meetingsBucketEarlierThisWeek => '今週のそれ以前';

  @override
  String get meetingsBucketLastWeek => '先週';

  @override
  String get meetingsBucketOlder => 'それ以前';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の決定',
      one: '1件の決定',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total 件のアクションアイテム';
  }

  @override
  String get meetingsEnhancedPill => '拡張済み';

  @override
  String get meetingsTranscribing => '文字起こしと要約中…';

  @override
  String get meetingsOpenAction => '開く';

  @override
  String get meetingsStopProcessing => '停止';

  @override
  String get meetingsStillTranscribing => 'まだ文字起こし中です。完了すると要約が表示されます。';

  @override
  String get meetingsNoMatch => '一致する会議はありません';

  @override
  String get meetingsNoMatchHint => '別のフィルターや検索語をお試しください。';

  @override
  String get meetingBackAllMeetings => 'すべての会議';

  @override
  String get meetingReRunSummary => '要約を再実行';

  @override
  String get meetingExport => 'エクスポート';

  @override
  String get meetingAugmentingBanner => '文字起こしからメモを補強しています。決定事項とアクションアイテムを抽出中…';

  @override
  String get meetingTabNotes => 'メモ';

  @override
  String get meetingTabTranscript => '文字起こし';

  @override
  String get meetingTabActionItems => 'アクションアイテム';

  @override
  String get meetingTabDecisions => '決定事項';

  @override
  String get meetingNotesEnhancedToggle => '拡張';

  @override
  String get meetingNotesYoursToggle => '自分のメモ';

  @override
  String get meetingEnhancedByAgent => 'エージェントが拡張 · 文字起こしから';

  @override
  String get meetingEnhancedPending => 'エージェントはまだこの要約を作成中です。';

  @override
  String get meetingNotesEmpty => '拡張メモはまだありません。';

  @override
  String get meetingNotesSavedLocally => 'ローカルに保存済み';

  @override
  String get meetingNotesSaving => '保存中…';

  @override
  String get meetingViewFullTranscript => '文字起こし全文を表示';

  @override
  String get meetingTranscriptSearchHint => '文字起こしを検索…';

  @override
  String get meetingSpeakerEveryone => '全員';

  @override
  String get meetingSpeakerOthers => 'その他';

  @override
  String get meetingTranscriptEmpty => '文字起こしはまだありません。';

  @override
  String get meetingActionItemsEmpty => '抽出されたアクションアイテムはありません。';

  @override
  String get meetingActionItemFrom => 'この会議から';

  @override
  String get meetingCreateTicket => 'チケットを作成';

  @override
  String meetingTicketCreated(String key) {
    return 'チケット $key を作成し、送信しました。';
  }

  @override
  String get meetingTicketFailed => 'チケットを作成できませんでした。';

  @override
  String get meetingDecisionsEmpty => '記録された決定事項はありません。';

  @override
  String get meetingEditTitle => 'タイトルを編集';

  @override
  String get meetingTitleLabel => 'タイトル';

  @override
  String get meetingAddActionItem => 'アクションアイテムを追加';

  @override
  String get meetingEditActionItem => 'アクションアイテムを編集';

  @override
  String get meetingDeleteActionItem => 'アクションアイテムを削除';

  @override
  String get meetingActionItemContentLabel => 'アクションアイテム';

  @override
  String get meetingActionItemContentHint => '何をする必要がありますか？';

  @override
  String get meetingActionItemOwnerLabel => '担当者';

  @override
  String get meetingActionItemOwnerHint => '担当者は誰ですか？（任意）';

  @override
  String get meetingAddDecision => '決定事項を追加';

  @override
  String get meetingEditDecision => '決定事項を編集';

  @override
  String get meetingDeleteDecision => '決定事項を削除';

  @override
  String get meetingDecisionContentLabel => '決定事項';

  @override
  String get meetingDecisionContentHint => '何が決まりましたか？';

  @override
  String get meetingReRunStarted => '文字起こしの要約を再実行しています…';

  @override
  String get meetingReRunNoTranscript => '要約できる文字起こしがまだありません。';

  @override
  String get meetingExportCopied => 'メモをMarkdownとしてクリップボードにコピーしました。';

  @override
  String get meetingExportSaved => 'ミーティングをエクスポートしました。';

  @override
  String meetingExportFailed(String error) {
    return 'エクスポートに失敗しました: $error';
  }

  @override
  String get meetingExportNothing => 'エクスポートできるものがまだありません。';

  @override
  String get meetingPlaybackPlay => '再生';

  @override
  String get meetingPlaybackPause => '一時停止';

  @override
  String get meetingPlaybackUnavailable => 'このデバイスでは音声の再生は利用できません。';

  @override
  String get meetingDetectedTitle => 'ミーティングを検出しました';

  @override
  String meetingDetectedSubtitle(String label) {
    return '「$label」が始まっているようです。録音しますか？';
  }

  @override
  String get meetingDetectedSubtitleGeneric => 'ミーティングが始まっているようです。録音しますか？';

  @override
  String get meetingDetectedRecord => '録音';

  @override
  String get meetingDetectedDismiss => '閉じる';

  @override
  String get meetingAutoStopTitle => 'ミーティングが終了したようです。録音を停止しますか？';

  @override
  String get meetingAutoStopStop => '停止';

  @override
  String get meetingAutoStopKeep => '録音を続ける';

  @override
  String get meetingAutoDetect => 'ミーティングの自動検出';

  @override
  String get meetingAutoDetectDescription =>
      'カレンダーと会議アプリを監視し、ミーティング開始時に録音を提案します。';

  @override
  String get meetingsRecordingCrumb => '録音中…';

  @override
  String get meetingRecordTitleHint => 'ミーティングのタイトル';

  @override
  String get meetingRecordTappingLabel => '取り込み:';

  @override
  String get meetingRecordMic => 'マイク';

  @override
  String get meetingRecordSystemAudio => 'システム音声';

  @override
  String get meetingRecordPause => '一時停止';

  @override
  String get meetingRecordResume => '再開';

  @override
  String get meetingRecordStop => '停止して要約';

  @override
  String get meetingRecordYourNotes => '自分のメモ';

  @override
  String get meetingRecordNotesPlaceholder =>
      '聞きながら入力してください。断片で十分です。停止後、エージェントが文字起こしを使って展開します。';

  @override
  String get meetingRecordLiveTranscript => 'リアルタイム文字起こし';

  @override
  String get meetingRecordDecoding => 'デバイス上でデコード中';

  @override
  String get meetingRecordListening =>
      '聞き取り中… 1〜2秒以内にここに発言が表示され、自分 / その他のタグが付きます。';

  @override
  String get meetingRecordPausedHint => '一時停止中 — 再開するまで音声は無視されます。';

  @override
  String get meetingRecordNotActive => '進行中の録音はありません。';

  @override
  String get meetingHudRecording => '録音中';

  @override
  String get meetingHudPaused => '一時停止中';

  @override
  String get meetingHudOpen => '開く';

  @override
  String get meetingHudStop => '停止';

  @override
  String get meetingToolbarPopOut => 'ポップアウト';

  @override
  String get meetingToolbarHoldToStop => '長押しで録音を停止';

  @override
  String get meetingToolbarSemanticLabel => 'ミーティング録音ツールバー';

  @override
  String get orchestrate => 'オーケストレーション';

  @override
  String get orchestrationUnavailable => 'オーケストレーションは利用できません';

  @override
  String get orchestrationApprove => 'プランを承認';

  @override
  String get orchestrationReject => '却下';

  @override
  String get orchestrationCancel => 'オーケストレーションをキャンセル';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count 件のロール — 新規採用 $hires 名';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count 件のサブチケット';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return '推定コスト: \$$amount';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return 'サブチケット $done/$total 完了';
  }

  @override
  String get orchestrationStatusProposed => '提案中';

  @override
  String get orchestrationStatusApproved => '承認済み';

  @override
  String get orchestrationStatusExecuting => '実行中';

  @override
  String get orchestrationStatusSynthesizing => '統合中';

  @override
  String get orchestrationStatusCompleted => '完了';

  @override
  String get orchestrationStatusFailed => '失敗';

  @override
  String get orchestrationStatusCancelled => 'キャンセル済み';

  @override
  String get messageFailed => '実行に失敗しました';

  @override
  String get turnLimitReached => 'ターン上限で停止しました。返信すると続行します';

  @override
  String get retried => '再試行済み';

  @override
  String replyingTo(String name) {
    return '$name に返信中';
  }

  @override
  String get silenceTimeoutLabel => '無応答タイムアウト（分）';

  @override
  String get silenceTimeoutHint => '例: 15 — この時間出力がないと実行を終了します';

  @override
  String get capabilityJsonMode => 'JSON モード';

  @override
  String get capabilityModelSelection => 'モデル選択';

  @override
  String get transcriptThinking => '考え中…';

  @override
  String transcriptThoughtFor(String duration) {
    return '$duration 考えました';
  }

  @override
  String get transcriptStatusMakingEdits => '編集中…';

  @override
  String get transcriptStatusReadingFiles => 'ファイルを読み取り中…';

  @override
  String get transcriptStatusSearching => 'コードベースを検索中…';

  @override
  String get transcriptStatusRunningCommands => 'コマンドを実行中…';

  @override
  String get transcriptStatusResponding => '応答中…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return '$tool を実行中…';
  }

  @override
  String get transcriptInput => '入力';

  @override
  String get transcriptOutput => '出力';

  @override
  String get transcriptErrorLabel => 'エラー';

  @override
  String get transcriptSandboxBlocked => 'サンドボックスが操作をブロックしました';

  @override
  String transcriptShowFullOutput(int kb) {
    return '出力をすべて表示（+$kb KB）';
  }

  @override
  String transcriptShowAllLines(int count) {
    return '全 $count 行を表示';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return '先頭 $count 行を表示中';
  }

  @override
  String get transcriptGrepNoMatches => '一致なし';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '$matches 件一致',
      one: '1 件一致',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files ファイル',
      one: '1 ファイル',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return '人物 $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => '話者名を変更';

  @override
  String get meetingRenameSpeakerTitle => '話者名を変更';

  @override
  String get meetingSpeakerNameLabel => '名前';

  @override
  String get meetingSpeakerSuggestFromCalendar => 'この会議の招待者から';

  @override
  String get meetingRenameSpeakerApplyAll => 'この話者のブロックすべてに適用';

  @override
  String get meetingRenameSpeakerScopeHint => 'オフの場合、選択中の行のみ名前を変更します。';

  @override
  String get meetingLinkEvent => 'イベントにリンク';

  @override
  String get meetingChangeEvent => 'イベントを変更';

  @override
  String get meetingLinkEventTitle => 'カレンダーのイベントにリンク';

  @override
  String get meetingLinkEventSearchHint => 'イベントを検索';

  @override
  String get meetingLinkEventEmpty => '近くのカレンダーイベントはありません';

  @override
  String get meetingUnlinkEvent => 'リンクを解除';

  @override
  String get calendarLinkExistingMeeting => '既存の会議にリンク';

  @override
  String get calendarLinkMeetingTitle => '会議をリンク';

  @override
  String get calendarLinkMeetingSearchHint => '会議を検索';

  @override
  String get calendarLinkMeetingEmpty => 'リンクできる会議はありません';

  @override
  String get meetingRenameSpeakerFailed => '話者名を変更できませんでした';

  @override
  String get calendarLinkUpdateFailed => 'カレンダーリンクを更新できませんでした';

  @override
  String get rename => '名前を変更';

  @override
  String get notNow => '今はしない';

  @override
  String get meetingSaveVoiceProfileTitle => '音声プロファイルを保存しますか？';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return '声紋を保存すると、今後の会議で $name を自動認識します。';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return '$name の音声プロファイルを保存しました';
  }

  @override
  String get meetingVoiceProfileSaveFailed => '音声プロファイルを保存できませんでした';

  @override
  String get voiceProfilesSection => '音声プロファイル';

  @override
  String get voiceProfilesDescription => '保存した音声は、今後のミーティングで自動的に認識されます。';

  @override
  String get voiceProfilesEmpty =>
      '保存済みの音声はまだありません。ミーティングの文字起こしで話者に名前を付け、「音声プロファイルを保存」を選択してください。';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のサンプル',
      one: '1 件のサンプル',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => '音声プロファイルの名前変更';

  @override
  String get deleteVoiceProfileTitle => '音声プロファイルを削除しますか？';

  @override
  String deleteVoiceProfileBody(String name) {
    return '$name の認識を停止しますか？保存済みの声紋は削除されます。過去のミーティングに適用済みの名前はそのまま残ります。';
  }

  @override
  String get connectedLabel => '接続済み';

  @override
  String get ideTabGeneral => '一般';

  @override
  String get ideTabExplorer => 'エクスプローラー';

  @override
  String get ideTabSourceControl => 'ソース管理';

  @override
  String get generalSectionTodos => 'やること';

  @override
  String get generalSectionGoals => 'ゴール';

  @override
  String get goalRunStatusActive => '実行中';

  @override
  String get goalRunStatusPaused => '一時停止中';

  @override
  String get goalRunStatusCompleted => '完了';

  @override
  String get goalRunStatusFailed => '失敗';

  @override
  String get goalRunStatusCancelled => 'キャンセル済み';

  @override
  String get goalRunStatusBudgetExhausted => '予算切れ';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return '$max 回中 $run 回目 · $cap 中 $cost';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return '実行 $run · $cap 中 $cost';
  }

  @override
  String goalRunDeadline(String deadline) {
    return '期限 $deadline';
  }

  @override
  String get goalRunPause => 'ゴールを一時停止';

  @override
  String get goalRunResume => 'ゴールを再開';

  @override
  String goalRunResumeRaise(String cap) {
    return '再開 · 上限を $cap に引き上げ';
  }

  @override
  String get goalRunStop => 'ゴールを停止';

  @override
  String get generalSectionAgents => 'エージェント';

  @override
  String get generalSectionTerminals => 'ターミナル';

  @override
  String get generalTodosEmpty => 'やることはまだありません';

  @override
  String get generalAgentsEmpty => '実行中のエージェントはありません';

  @override
  String get generalTerminalsEmpty => '開いているターミナルはありません';

  @override
  String get generalSectionBrowsers => 'ブラウザ';

  @override
  String get generalSectionComputers => 'コンピューター';

  @override
  String get generalBrowsersEmpty => '開いているブラウザはありません';

  @override
  String get generalComputersEmpty => '開いているコンピューターはありません';

  @override
  String get generalSectionPhones => 'スマートフォン';

  @override
  String get generalPhonesEmpty => '開いているスマートフォンはありません';

  @override
  String get pauseAgent => 'エージェントを一時停止';

  @override
  String get resumeAgent => 'エージェントを再開';

  @override
  String get agentCannotPause => 'このエージェントは一時停止できません。停止してください。';

  @override
  String get goalClear => 'ゴールをクリア';

  @override
  String get undoLabelGoalClear => 'ゴールをクリア';

  @override
  String get todoStatusPending => '未着手';

  @override
  String get todoStatusInProgress => '進行中';

  @override
  String get todoStatusCompleted => '完了';

  @override
  String get reorderTodo => 'やることを並べ替え';

  @override
  String get focusTerminal => 'ターミナルにフォーカス';

  @override
  String get focusMachine => 'マシンにフォーカス';

  @override
  String get focusBrowser => 'ブラウザにフォーカス';

  @override
  String get todoEditorTitle => 'やることを編集';

  @override
  String get todoEditorHint =>
      '1行に1項目です。未着手は - [ ]、進行中は - [~]、完了は - [x] を使います。';

  @override
  String get todoNeedsText => 'コマンドの後にテキストを追加してください';

  @override
  String get todoNotFound => '一致するやることはありません';

  @override
  String get todoCleared => 'やることリストをクリアしました';

  @override
  String get todoNothingToCopy => 'コピーするものがありません';

  @override
  String todoAdded(String content) {
    return '「$content」を追加しました';
  }

  @override
  String todoStarted(String content) {
    return '「$content」を開始しました';
  }

  @override
  String todoCompleted(String content) {
    return '「$content」を完了しました';
  }

  @override
  String todoRemoved(String content) {
    return '「$content」を削除しました';
  }

  @override
  String todoCopied(int count) {
    return '$count件をコピーしました';
  }

  @override
  String todoImported(int count) {
    return '$count件をインポートしました';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return '不明なtodoコマンド「$name」です';
  }

  @override
  String get terminal => 'ターミナル';

  @override
  String get ideCloseTab => 'タブを閉じる';

  @override
  String get ideSplitEditor => 'エディターを分割';

  @override
  String get ideSplitRight => '右に分割';

  @override
  String get ideSplitDown => '下に分割';

  @override
  String get ideSplitLeft => '左に分割';

  @override
  String get ideSplitUp => '上に分割';

  @override
  String get ideCloseGroup => 'グループを閉じる';

  @override
  String get ideCloseOthers => '他を閉じる';

  @override
  String get ideCloseToRight => '右側を閉じる';

  @override
  String get ideCloseSaved => '保存済みを閉じる';

  @override
  String get ideCloseAll => 'すべて閉じる';

  @override
  String get ideSplit => '分割';

  @override
  String get ideToggleSidebar => 'サイドバーの表示切替';

  @override
  String get ideNewTab => 'エディターを開く';

  @override
  String get ideNewTabMenu => '新しいタブ';

  @override
  String get ideReviewCode => 'コードをレビュー';

  @override
  String get ideRevertConfirmTitle => '変更を元に戻す';

  @override
  String get ideRevertUntracked => '未追跡ファイルは元に戻せません';

  @override
  String get ideRevertFailed => 'ファイルを元に戻せませんでした。会話のワークツリーが利用できない可能性があります。';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のファイル',
      one: '1件のファイル',
    );
    return '$_temp0を元に戻せませんでした（未追跡）。';
  }

  @override
  String get ideSearchMatchCase => '大文字と小文字を区別';

  @override
  String get ideSearchWholeWord => '単語単位';

  @override
  String get ideSearchRegex => '正規表現';

  @override
  String get ideSearchFilters => '検索フィルター';

  @override
  String get ideSearchFilesToInclude => '含めるファイル';

  @override
  String get ideSearchFilesToExclude => '除外するファイル';

  @override
  String get ideNoOpenTabs => '開いているタブはありません。+で開いてください';

  @override
  String get ideBrowserAddressHint => 'アドレスを入力するか検索';

  @override
  String get ideSimpleWebBrowser => '簡易ウェブブラウザー';

  @override
  String get ideWebBrowser => 'ウェブブラウザー';

  @override
  String get ideBrowserEnterUrl => 'アドレスバーにURLを入力して閲覧を開始します';

  @override
  String get ideCodeServer => 'エディター';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return '$fileNameへの変更を保存しますか？';
  }

  @override
  String get ideUnsavedChangesBody => '保存しないと変更は失われます。';

  @override
  String get ideDontSave => '保存しない';

  @override
  String get editorAutoSave => '自動保存';

  @override
  String get editorAutoSaveDescription => '埋め込みエディターの変更を自動的に保存します。';

  @override
  String get editorAutoSaveOff => 'オフ';

  @override
  String get editorAutoSaveAfterDelay => '遅延後';

  @override
  String get editorAutoSaveOnFocusChange => 'フォーカス変更時';

  @override
  String get ideCodeServerUnavailable => 'このサーバーではcode-serverを利用できません';

  @override
  String get ideCodeServerUnavailableHint =>
      'サーバーホストにcode-server（coder/code-server）をインストールしてから、エディターを開き直してください。';

  @override
  String get ideCodeServerInstalling => 'エディターを準備しています…';

  @override
  String get ideCodeServerOpenInBrowser => 'ブラウザーでエディターを開く';

  @override
  String get ideCodeServerError => 'エディターを開けませんでした';

  @override
  String get paneSuspendedCaption => 'リソース節約のため一時停止しています。フォーカスすると再読み込みされます';

  @override
  String get ideFolderLoadFailed => 'このフォルダーを読み込めませんでした';

  @override
  String get ideFileSearchFailed => 'ファイルを検索できませんでした';

  @override
  String get ideSearchInFiles => 'ファイル内検索';

  @override
  String get ideNoContentMatches => '一致なし';

  @override
  String get ideSourceControlCreatePr => 'プルリクエストを作成';

  @override
  String ideSourceControlViewPr(int number) {
    return 'プルリクエスト #$number を表示';
  }

  @override
  String get ideSourceControlNoChanges => '変更なし';

  @override
  String get noReposInConversation => 'この会話にリポジトリはありません';

  @override
  String get ideSourceControlNoSpace => '会話を開くと変更を確認できます';

  @override
  String get ideFileLoading => '読み込み中…';

  @override
  String get ideFileBinary => 'バイナリファイル';

  @override
  String get mcpExternalServers => '外部 MCP サーバー';

  @override
  String get mcpExternalServersDescription =>
      '外部 MCP サーバー（GitHub、Sentry、Postgres、ブラウザ自動化）に接続します。Claude、Cursor、VS Code などのツール向けに設定したサーバーは自動検出されます。';

  @override
  String get mcpApprovalMode => 'ツールの承認';

  @override
  String get mcpApprovalModeDescription =>
      '確認なしで実行するツール操作を選びます。読み取りは常に許可され、上位の段階では確認が表示されます。';

  @override
  String get mcpApprovalAlwaysAsk => '常に確認';

  @override
  String get mcpApprovalWrite => '書き込みを自動承認';

  @override
  String get mcpApprovalYolo => 'すべて自動承認';

  @override
  String get mcpNoExternalServers => '外部 MCP サーバーは検出されませんでした。';

  @override
  String get mcpAuthorize => '認可';

  @override
  String get mcpReconnect => '再接続';

  @override
  String get mcpExternalConnectionsNote =>
      '外部 MCP サーバーはエージェントサーバー（デスクトップと Web で共有）上で動作します。OAuth サーバーの認可はデスクトップでのみ利用できます。';

  @override
  String get mcpStatusConnected => '接続済み';

  @override
  String get mcpStatusConnecting => '接続中…';

  @override
  String get mcpStatusNeedsAuth => '認可が必要';

  @override
  String get mcpStatusFailed => '失敗';

  @override
  String get mcpStatusCircuitOpen => '一時停止';

  @override
  String get mcpStatusDisabled => '無効';

  @override
  String get providersAndModels => 'プロバイダーとモデル';

  @override
  String get providersAndModelsDescription =>
      '組み込みエージェントが使えるすべてのプロバイダーを一覧表示します。API キーの設定またはブラウザでのログイン、接続済みプロバイダーのモデルと料金の確認、このワークスペースで使えるプロバイダーの管理ができます。';

  @override
  String get syncNow => '今すぐ同期';

  @override
  String syncNowResult(int applied, int failed) {
    return '同期完了 — $applied 件適用、$failed 件失敗';
  }

  @override
  String syncNowFailed(String error) {
    return '同期に失敗しました: $error';
  }

  @override
  String get denied => '拒否';

  @override
  String get allowed => '許可';

  @override
  String allowProviderSemantic(String provider) {
    return '$provider を許可';
  }

  @override
  String enabledViaEnv(String key) {
    return '$key で有効';
  }

  @override
  String costPerMillion(String input, String output) {
    return '$input / $output / 100万';
  }

  @override
  String contextTokens(String tokens) {
    return 'コンテキスト $tokens';
  }

  @override
  String get usageAndCost => '使用量とコスト';

  @override
  String get usageAndCostDescription =>
      '過去 7 日間のエージェント全体の支出です。実行時に観測されたコストに基づきます。';

  @override
  String get noUsageYet => 'まだ使用量は記録されていません。';

  @override
  String get spentThisWeek => '今週の支出';

  @override
  String get subscriptionUsage => 'サブスクリプション使用量';

  @override
  String get subscriptionUsageUnavailable => '利用不可';

  @override
  String get subscriptionUsageExhausted => 'クォータ切れ';

  @override
  String get subscriptionUsageSignInRequired => '再サインイン';

  @override
  String get subscriptionUsageSignInExpired =>
      'サインインの有効期限が切れています。次回の実行時に更新されます';

  @override
  String get subscriptionUsagePartiallyAvailable => '一部利用可能';

  @override
  String resetsIn(String duration) {
    return '$duration 後にリセット';
  }

  @override
  String get feedbackHelpful => '役に立ちました';

  @override
  String get feedbackNotHelpful => '役に立ちませんでした';

  @override
  String get modeChat => 'チャット';

  @override
  String get modePlan => 'プラン';

  @override
  String get modeReview => 'レビュー';

  @override
  String get modeOrchestrate => 'オーケストレート';

  @override
  String get editorTheme => 'エディターのテーマ';

  @override
  String get editorThemeDescription =>
      'VS Code のカラーテーマをインポートして、埋め込みの差分表示とエディターを IDE に合わせます。';

  @override
  String get editorThemePasteHint => 'VS Code のカラーテーマ JSON ファイルの内容を貼り付けてください';

  @override
  String get editorThemeImported => 'テーマをインポートしました';

  @override
  String get editorThemeInvalid => '有効な VS Code テーマではないようです';

  @override
  String get importTheme => 'テーマをインポート';

  @override
  String get clearTheme => 'テーマをクリア';

  @override
  String get openInDiffViewer => '差分ビューアーで開く';

  @override
  String get shellCommand => 'コマンド';

  @override
  String get shellOutput => '出力';

  @override
  String get revertToHere => 'ここまで戻す';

  @override
  String get revertConfirmBody =>
      'この時点以降のメッセージを非表示にし、エージェントのファイル変更をこのターンまでロールバックしますか？後から取り消せます。';

  @override
  String get revert => '戻す';

  @override
  String get revertedToHere => 'ここまで戻しました';

  @override
  String get nothingToRevert => '戻すものはありません';

  @override
  String get undoRevert => '戻すを取り消す';

  @override
  String get revertUndone => '戻すを取り消しました';

  @override
  String get systemBehavior => 'システムの動作';

  @override
  String get keepAwakeTitle => 'エージェント実行中はコンピューターをスリープさせない';

  @override
  String get keepAwakeOnSubtitle => 'エージェントの作業中はコンピューターがスリープしません';

  @override
  String get keepAwakeOffSubtitle => 'エージェントの作業中でもコンピューターがスリープすることがあります';

  @override
  String get syncEngineSectionTitle => '同期エンジン';

  @override
  String get syncEngineDescription =>
      'チケット、メッセージ、ノートは、フルスナップショットではなく小さな増分変更でライブ更新されます。トグルをオフにすると、そのストアはフルスナップショットモードに戻ります。変更を反映するにはアプリを再読み込みしてください。';

  @override
  String get syncEngineTicketsTitle => 'チケット';

  @override
  String get syncEngineMessagingTitle => 'メッセージ';

  @override
  String get syncEngineNotesTitle => 'ノート';

  @override
  String get syncEngineOnSubtitle => 'ライブ差分同期が有効です';

  @override
  String get syncEngineOffSubtitle => 'フルスナップショット同期を使用しています';

  @override
  String get spaces => 'スペース';

  @override
  String get spacesHomeDescription => 'リストからスペースを選ぶか、新しく作成してください。';

  @override
  String get noSpacesYet => 'スペースはまだありません';

  @override
  String get newSpace => '新しいスペース';

  @override
  String get spaceName => 'スペース名';

  @override
  String get spaceReposHint => '含めるリポジトリ';

  @override
  String get ideSourceControl => 'ソース管理';

  @override
  String get stagedChanges => 'ステージ済みの変更';

  @override
  String get changes => '変更';

  @override
  String get stageFile => 'ステージ';

  @override
  String get unstageFile => 'アンステージ';

  @override
  String get stageAll => 'すべての変更をステージ';

  @override
  String get unstageAll => 'すべてアンステージ';

  @override
  String get stageChangesToCommit => 'コミットする変更をステージ';

  @override
  String get syncToPrHead => '最新のPRコミットを取得';

  @override
  String get syncedToPrHead => '最新のPRコミットに同期しました';

  @override
  String get syncPrHeadDirty => '同期する前に変更をコミットするか破棄してください';

  @override
  String get syncPrHeadFailed => 'PRのヘッドに同期できませんでした';

  @override
  String get spaceLabel => 'スペース';

  @override
  String get keybindingNewSpace => '新しいスペース';

  @override
  String get keybindingCreateANewSpaceDescription => '新しいスペースを作成';

  @override
  String get jumpToLatest => '最新へジャンプ';

  @override
  String get streaming => 'ストリーミング';

  @override
  String get newMessages => '新着';

  @override
  String get copyLink => 'リンクをコピー';

  @override
  String get linkCopied => 'リンクをコピーしました';

  @override
  String get agentResponding => 'エージェントが応答中';

  @override
  String get agentFinished => 'エージェントが完了しました';

  @override
  String get harnessConnectProviderForModels => 'モデルを表示するにはプロバイダーを接続してください。';

  @override
  String get providerSignOut => 'サインアウト';

  @override
  String get providerWaitingForDeviceCode => 'ブラウザーでコードを確認するのを待っています…';

  @override
  String get providerDeviceCodeHint =>
      'このコードがブラウザーに表示されているものと一致することを確認してから承認してください。';

  @override
  String get providerPlanUsageLoading => 'プランの使用状況を確認しています…';

  @override
  String get providerPlanUsageUnavailable => 'このプランは使用状況を報告しませんでした。';

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return '$provider の API キーを削除しますか？';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return '保存されたキーは削除され、再度表示できません。$provider のモデルを使うエージェントは、新しいキーを貼り付けるまで動作しません。';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return '$provider を削除しますか？';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return 'プロバイダーと保存されたキーが削除されます。そのモデルにピン留めされたエージェントは動作しなくなります。';
  }

  @override
  String get providerApiKeyHint => 'API キーを貼り付け';

  @override
  String get providerApiKeyStoredHint => '別の API キーを貼り付けて追加';

  @override
  String get providerAddAnotherAccount => '別のアカウントを追加';

  @override
  String get providerActiveBadge => '有効';

  @override
  String get providerOauthAccountFallback => 'OAuthアカウント';

  @override
  String get providerApiKeyFallback => 'APIキー';

  @override
  String get providerRemoveCredentialConfirmTitle => 'この認証情報を削除しますか？';

  @override
  String get providerSignOutAccountConfirmTitle => 'このアカウントからログアウトしますか？';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return '$provider を使うエージェントは、ほかのキーやアカウントにフォールバックします。どれも残っていない場合は、追加するまで停止します。';
  }

  @override
  String get providerBaseUrlHint => 'ベースURL（任意）';

  @override
  String get addProvider => 'プロバイダーを追加';

  @override
  String get noCustomProviders => 'カスタムプロバイダーはまだありません。';

  @override
  String get providerNameLabel => '名前';

  @override
  String get apiTypeLabel => 'APIの種類';

  @override
  String get providerBaseUrlLabel => 'ベースURL';

  @override
  String get providerApiKeyOptionalHint => 'APIキー（任意）';

  @override
  String get dialectOpenAiCompatible => 'OpenAI互換';

  @override
  String get dialectAnthropicCompatible => 'Anthropic互換';

  @override
  String get removeProviderTooltip => 'プロバイダーを削除';

  @override
  String get providerLogInWithBrowser => 'ブラウザでログイン';

  @override
  String providerLoginDialogTitle(String provider) {
    return '$provider にログイン';
  }

  @override
  String get providerLabel => 'プロバイダー';

  @override
  String get selectProviderToLogin => 'ログインするプロバイダーを選択';

  @override
  String providerLoginFailed(String error) {
    return 'ログインに失敗しました: $error';
  }

  @override
  String get providerWaitingForBrowser => 'ブラウザでの認可を待っています…';

  @override
  String get providerPasteCodeHint => 'またはブラウザのコードを貼り付け';

  @override
  String get providerCompleteLogin => '完了';

  @override
  String get providerConnectedApiKey => 'APIキーで接続済み';

  @override
  String get providerConnectedOauth => '接続済み';

  @override
  String providerConnectedAccount(String account) {
    return '接続済み · $account';
  }

  @override
  String get providerLocalReady => 'ローカル · 準備完了';

  @override
  String get providerNotConnected => '未接続';

  @override
  String get preparingWorkspace => 'ワークスペースを準備しています…';

  @override
  String provisioningRunningSetupScript(String repo) {
    return '$repo のセットアップスクリプトを実行しています…';
  }

  @override
  String get repoScriptsTitle => 'スクリプト';

  @override
  String get repoScriptsTooltip => 'ライフサイクルスクリプトを設定';

  @override
  String get repoScriptsSetupLabel => 'セットアップスクリプト';

  @override
  String get repoScriptsSetupHelp =>
      'スペースのワークツリー作成直後に実行されます。依存関係のインストールやファイル生成などに使います。失敗するとスペースは失敗扱いになり、再試行で再度実行されます。';

  @override
  String get repoScriptsArchiveLabel => 'アーカイブスクリプト';

  @override
  String get repoScriptsArchiveHelp =>
      'スペースのワークツリー削除直前に実行されます。ワークツリー外のリソースのクリーンアップに使います。失敗しても削除はブロックされません。';

  @override
  String get repoScriptsEnvHelp =>
      'ワークツリーから bash で実行され、CC_WORKSPACE_PATH（ワークツリー）、CC_ROOT_PATH（リポジトリのルート）、CC_SPACE_ID、CC_SPACE_NAME、CC_REPO_NAME が設定されます。';

  @override
  String get repoScriptsSetupPlaceholder => '例: pnpm install';

  @override
  String get repoScriptsArchivePlaceholder =>
      '例: docker compose -p \$CC_SPACE_ID down';

  @override
  String get repoScriptsRecentRuns => '最近の実行';

  @override
  String get repoScriptsNoRuns => 'まだ実行はありません';

  @override
  String get repoScriptsSaved => 'スクリプトを保存しました';

  @override
  String get repoScriptsRunKindSetup => 'セットアップ';

  @override
  String get repoScriptsRunKindArchive => 'アーカイブ';

  @override
  String get repoScriptsRunStatusRunning => '実行中';

  @override
  String get repoScriptsRunStatusSucceeded => '成功';

  @override
  String get repoScriptsRunStatusFailed => '失敗';

  @override
  String get repoScriptsRunStatusTimedOut => 'タイムアウト';

  @override
  String repoScriptsExitCode(int code) {
    return '終了コード $code';
  }

  @override
  String provisioningCloningRepo(String repo) {
    return '$repo をクローンしています…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return '$repo のプルリクエストをチェックアウトしています…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return 'エージェント $agent をセットアップしています…';
  }

  @override
  String get workspacePrepFailed => 'ワークスペースのセットアップに失敗しました';

  @override
  String get workspacePrepStopped => 'ワークスペースのセットアップを停止しました';

  @override
  String get stopWorkspacePrep => '準備を停止';

  @override
  String get stopWorkspacePrepTooltip => 'このワークスペースの準備を停止';

  @override
  String get stopWorkspacePrepConfirm =>
      'このワークスペースの準備を停止しますか？進行中のクローンは破棄されます。ここからやり直すことができます。';

  @override
  String messageWillSendWhenReady(int count) {
    return '準備ができたら$count件のメッセージを送信します';
  }

  @override
  String get membersNav => 'メンバー';

  @override
  String get membersSettingsDescription =>
      'このワークスペースにアクセスできる人です。名簿、招待、監査証跡を管理できます';

  @override
  String get memberRosterLabel => 'メンバー名簿';

  @override
  String get memberRepoAccessAction => 'リポジトリアクセス';

  @override
  String memberRepoAccessTitle(String name) {
    return '$nameのリポジトリアクセス';
  }

  @override
  String get roleOwner => 'オーナー';

  @override
  String get roleAdmin => '管理者';

  @override
  String get roleMember => 'メンバー';

  @override
  String get roleViewer => '閲覧者';

  @override
  String get roleGuest => 'ゲスト';

  @override
  String get removeMemberTitle => 'メンバーを削除';

  @override
  String removeMemberConfirm(String name) {
    return '$nameをこのワークスペースから削除しますか？すぐにアクセスできなくなります。';
  }

  @override
  String get transferOwnershipAction => '所有権を譲渡';

  @override
  String get transferOwnershipTitle => '所有権を譲渡';

  @override
  String transferOwnershipConfirm(String name) {
    return '$nameをこのワークスペースのオーナーにしますか？あなたは管理者になります。ワークスペースの削除や他の管理者のロール変更は、オーナーのみが行えます。';
  }

  @override
  String get transferOwnershipCta => '譲渡';

  @override
  String get auditTrailLabel => '認可監査証跡';

  @override
  String get auditTrailDescription => '許可と拒否のすべてをハッシュチェーンで記録し、改ざんや削除を検出できます。';

  @override
  String get auditVerifyChain => 'チェーンを検証';

  @override
  String auditChainIntact(int count) {
    return 'チェーンは正常です — $count件を検証済み';
  }

  @override
  String auditChainBroken(int seq, String reason) {
    return 'エントリ$seqでチェーンが切れています: $reason';
  }

  @override
  String get auditEmpty => 'まだ記録された決定はありません。';

  @override
  String get auditDenied => '拒否';

  @override
  String get auditAllowed => '許可';

  @override
  String auditOnBehalfOf(String user) {
    return '$userの代理';
  }

  @override
  String get policyTemplatesLabel => 'ポリシーテンプレート';

  @override
  String get policyTemplatesDescription => '初期方針を適用するか、ワークスペース間で移動できます。';

  @override
  String get policyTemplateStrict => '厳格';

  @override
  String get policyTemplateBalanced => 'バランス';

  @override
  String get policyTemplatePermissive => '寛容';

  @override
  String get policyTemplateApply => '適用';

  @override
  String policyTemplateApplied(int count) {
    return '$count件のルールを適用しました';
  }

  @override
  String get policyExport => 'ポリシーをコピー';

  @override
  String get policyExported => 'ポリシーをクリップボードにコピーしました';

  @override
  String get policyImport => 'ポリシーを貼り付け';

  @override
  String policyImported(int count) {
    return '$count件のルールをインポートしました';
  }

  @override
  String get approveAndRemember => '8時間承認';

  @override
  String get approveAndRememberTooltip =>
      'この操作を承認し、このワークスペースでは同様の確認を8時間求めません。期限が来ると自動で無効になります。';

  @override
  String get unknownUserLabel => '不明なユーザー';

  @override
  String get inviteMember => 'メンバーを招待';

  @override
  String get inviteRepoAccessHeader => 'リポジトリアクセス';

  @override
  String get inviteRepoAccessExplainer =>
      'チェックしたリポジトリだけが、選択した権限で招待先に共有されます。それ以外は表示されません。';

  @override
  String get grantLevelRead => '読み取り';

  @override
  String get grantLevelReview => 'レビュー';

  @override
  String get grantLevelWrite => '書き込み';

  @override
  String get inviteExpiryLabel => '有効期限';

  @override
  String get expiryOneDay => '1日';

  @override
  String get expirySevenDays => '7日';

  @override
  String get expiryThirtyDays => '30日';

  @override
  String get createInviteAction => '招待を作成';

  @override
  String get inviteOneTimeCodeLabel => 'ワンタイムコード';

  @override
  String get inviteCodeShownOnce => 'このコードは一度しか表示されません。今すぐコピーしてください。';

  @override
  String get inviteLinkLabel => '招待リンク';

  @override
  String get inviteRedeemHint => 'コードを招待相手に共有してください。相手はあなたのサーバーURLで引き換えます。';

  @override
  String get inviteScanQr => 'またはQRコードをスキャンして引き換え';

  @override
  String get inviteLoopbackWarningTitle => '招待がローカルアドレスを指しています';

  @override
  String get inviteLoopbackWarningBody =>
      '他のマシンのコラボレーターはこのサーバーに到達できません。トンネルを開始する（設定 → 連携 → このサーバーを共有）か、ネットワークにバインドして、ホスト外のユーザーが接続できるようにしてください。';

  @override
  String get inviteStatusOpen => '未使用';

  @override
  String get inviteStatusUsed => '使用済み';

  @override
  String get inviteStatusRevoked => '失効';

  @override
  String get inviteStatusExpired => '期限切れ';

  @override
  String inviteCreatedTime(String time) {
    return '$timeに作成';
  }

  @override
  String inviteExpiresOn(String date) {
    return '$dateに期限切れ';
  }

  @override
  String get noActivityYet => 'アクティビティはまだありません';

  @override
  String get couldNotLoadMembers => 'メンバーを読み込めませんでした';

  @override
  String get couldNotLoadInvites => '招待を読み込めませんでした';

  @override
  String get couldNotLoadActivity => 'アクティビティを読み込めませんでした';

  @override
  String get yourDevices => '自分のデバイス';

  @override
  String get yourDevicesDescription => 'このサーバーでアカウントにペアリング済みのクライアント。';

  @override
  String get noOwnDevices => 'アカウントにペアリングされたデバイスはまだありません';

  @override
  String get renameDeviceTitle => 'デバイスの名前を変更';

  @override
  String get revokeDeviceTitle => 'デバイスを失効';

  @override
  String revokeDeviceConfirm(String label) {
    return '$labelを失効しますか？即座に切断され、このサーバーには到達できなくなります。';
  }

  @override
  String devicePairedTime(String time) {
    return '$timeにペアリング';
  }

  @override
  String deviceLastSeenTime(String time) {
    return '最終接続 $time';
  }

  @override
  String get deviceNeverSeen => '未接続';

  @override
  String get profileSectionLabel => 'プロフィール';

  @override
  String get profileSectionDescription => 'チームメイトへの見え方と、gitコミットの作成者情報。';

  @override
  String get displayNameLabel => '表示名';

  @override
  String get emailLabel => 'メールアドレス';

  @override
  String get gitAuthorNameLabel => 'Git作成者名';

  @override
  String get gitAuthorEmailLabel => 'Git作成者のメールアドレス';

  @override
  String get profileSaved => 'プロフィールを保存しました';

  @override
  String get presenceOnline => 'オンライン';

  @override
  String get presenceIdle => 'アイドル';

  @override
  String get presenceTyping => '入力中…';

  @override
  String get presenceAgentThinking => '思考中';

  @override
  String get presenceAgentRunning => '実行中';

  @override
  String get presenceAgentBlocked => 'ブロック中';

  @override
  String get presenceAgentDone => '完了';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String presenceNameStatusCost(String name, String status, String cost) {
    return '$name — $status ($cost)';
  }

  @override
  String get presenceRailLabel => 'オンラインのメンバー';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => '取り込み中モードをオンにする';

  @override
  String get dndTooltipOff => '取り込み中モードをオフにする';

  @override
  String get startPresenting => '発表を開始';

  @override
  String get stopPresenting => '発表を終了';

  @override
  String spotlightPresentingBanner(String name) {
    return '$nameが発表中です';
  }

  @override
  String get spotlightLeave => '退出';

  @override
  String typingIndicator(String name) {
    return '$nameが入力中…';
  }

  @override
  String get ideTabNotes => 'ノート';

  @override
  String get ideSidebarAllViews => 'すべてのビュー';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return 'すべてのビュー（$count件非表示）';
  }

  @override
  String get ideSidebarPinView => 'サイドバーにピン留め';

  @override
  String get ideSidebarUnpinView => 'サイドバーのピン留めを解除';

  @override
  String get notesEmptyHint => 'この会話を引き継ぐ人のためにノートを追加…';

  @override
  String get notesEditTooltip => 'ノートを編集';

  @override
  String notesUpdatedBy(String name, String time) {
    return '$nameが$timeに更新';
  }

  @override
  String notesEditingHint(String name) {
    return '$nameが編集中';
  }

  @override
  String get notesSaveFailed => 'ノートを保存できませんでした';

  @override
  String get reactionAddTooltip => 'リアクションを追加';

  @override
  String reactionToggleTooltip(String emoji) {
    return '$emojiでリアクション';
  }

  @override
  String get autonomyDialLabel => '自律度';

  @override
  String get autonomyProposeOnly => '提案のみ';

  @override
  String get autonomyActWithApproval => '承認後に実行';

  @override
  String get autonomyActFreely => '自由に実行';

  @override
  String get autonomyDefaultOption => 'デフォルト';

  @override
  String get checkerLabel => 'チェッカー';

  @override
  String get checkerNone => 'なし';

  @override
  String get checkerCaption => 'チェッカーは他のエージェントの完了した実行をレビューします。';

  @override
  String get takeoverTooltip => 'ワークツリーを引き継ぐ';

  @override
  String get takeoverBannerSelf => 'この会話のワークツリーを引き継ぎました';

  @override
  String takeoverBannerOther(String name) {
    return '$nameがこの会話のワークツリーを引き継ぎました';
  }

  @override
  String get handBackButton => '返却';

  @override
  String get handBackDialogTitle => 'ワークツリーを返却';

  @override
  String get handBackDialogNoteHint => 'エージェントへの任意のメモ…';

  @override
  String takeoverFailed(String message) {
    return '引き継げませんでした: $message';
  }

  @override
  String handBackFailed(String message) {
    return '返却できませんでした: $message';
  }

  @override
  String get planStudioTitle => 'Plan Studio';

  @override
  String get plansTitle => 'プラン';

  @override
  String get plansSubtitle => 'アクティブなプラン、プランドキュメント、プレイブック';

  @override
  String get plansActiveSection => 'アクティブなプラン';

  @override
  String get plansDocumentsSection => 'プランドキュメント';

  @override
  String get plansPlaybooksSection => 'プレイブック';

  @override
  String get plansNoActive => 'アクティブなプランはまだありません。';

  @override
  String get plansNoDocuments => 'プランドキュメントはまだありません。';

  @override
  String get plansNoPlaybooks => 'プレイブックはまだありません。';

  @override
  String get planNotFound => 'プランが見つかりません。';

  @override
  String get planOpenInStudio => '開く';

  @override
  String get planNodeTitle => 'タイトル';

  @override
  String get planNodeDescription => '説明';

  @override
  String get planNodeDescriptionHint => 'このステップの内容…';

  @override
  String get planNodeApplyDescription => '適用';

  @override
  String get planNodeRole => 'ロール';

  @override
  String get planNodeDependencies => '依存先';

  @override
  String get planNodeDependenciesHint => '依存関係を追加';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の依存関係',
      one: '1件の依存関係',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies => '依存関係がないため、プランの開始と同時に実行されます';

  @override
  String get planNodeOutputSchema => '出力スキーマ（JSON）';

  @override
  String get planNodeEstimate => '見積もり';

  @override
  String get planNodeProvenance => '由来';

  @override
  String get planNodeAlreadyExecuted => '実行済み — ここを編集するとプランがここからフォークされます。';

  @override
  String get planNewNodeTitle => '新しいステップ';

  @override
  String get planEstimateNoHistory => '履歴はまだありません';

  @override
  String get planEstimateBlastUnknown => '影響範囲: 不明';

  @override
  String get planEstimatePartial => '部分的';

  @override
  String get planEstimateAction => '見積もり';

  @override
  String planEstimateDuration(String range) {
    return '所要時間 $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return '影響範囲: $filesファイル、$symbolsシンボル';
  }

  @override
  String get planApprove => 'プランを承認';

  @override
  String get planApproveSelectedNodes => '選択を承認';

  @override
  String get planReject => '却下';

  @override
  String get planCancel => '実行をキャンセル';

  @override
  String get planContinueNode => 'ノードを継続';

  @override
  String get planTotalNotEstimated => '未見積もり';

  @override
  String get planBudgetExceeded => '予算超過';

  @override
  String planBudgetCeiling(String amount) {
    return '予算 ≤ \$$amount';
  }

  @override
  String get planVersionsTitle => 'バージョン';

  @override
  String get planNoRevisions => 'リビジョンはまだありません。';

  @override
  String get planDiffIdentical => '変更はありません。';

  @override
  String get planDiffGoalChanged => '目標が変更されました';

  @override
  String get planDiffBudgetChanged => '予算が変更されました';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'v$fromRevからv$toRevへの変更';
  }

  @override
  String planDiffAdded(String node) {
    return '$nodeを追加';
  }

  @override
  String planDiffRemoved(String node) {
    return '$nodeを削除';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return '$nodeを変更: $fields';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return 'エッジ追加: $edge';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return 'エッジ削除: $edge';
  }

  @override
  String planDiffRoleAdded(String role) {
    return 'ロール追加: $role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return 'ロール削除: $role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return 'ロール再割り当て: $role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return 'プランが再計画されました: 承認したのはv$approved、現在はv$currentです。続行する前に差分を確認してください。';
  }

  @override
  String planLiveActualCost(String amount) {
    return '実際のコスト: \$$amount';
  }

  @override
  String get planPlaybookRun => '実行';

  @override
  String get planPlaybookDelete => 'プレイブックを削除';

  @override
  String get planPlaybookProposed => 'プランが提案されました — Plan Studioで承認してください。';

  @override
  String get planPlaybookAnchorTicket => 'アンカーチケット';

  @override
  String get planPlaybookPickTicket => 'チケットを選択…';

  @override
  String get planPlaybookProposeRun => 'プランを提案';

  @override
  String get planPlaybookRepoHint => 'リポジトリID';

  @override
  String get planPlaybookAgentHint => 'エージェントID';

  @override
  String planPlaybookRunTitle(String name) {
    return '$nameを実行';
  }

  @override
  String planPlaybookParamCount(int count) {
    return 'パラメータ$count件';
  }

  @override
  String get recentLabel => '最近';

  @override
  String get cheatSheetTitle => 'キーボードショートカット';

  @override
  String get cheatSheetGlobal => 'グローバル';

  @override
  String get cheatSheetThisScreen => 'この画面';

  @override
  String get cheatSheetReservedInBrowser => 'ブラウザ予約済み';

  @override
  String get keybindingCheatSheet => 'キーボードショートカット';

  @override
  String get keybindingShowKeyboardShortcutsDescription =>
      '現在の画面のキーボードショートカットチートシートを表示';

  @override
  String get runPlaybookLabel => 'プレイブックを実行';

  @override
  String get playbooksLabel => 'プレイブック';

  @override
  String get keybindingUndo => '元に戻す';

  @override
  String get keybindingRedo => 'やり直す';

  @override
  String get keybindingUndoLastActionDescription => '最後の取り消し可能な操作を元に戻す';

  @override
  String get keybindingRedoLastActionDescription => '元に戻した最後の操作をやり直す';

  @override
  String get undone => '元に戻しました';

  @override
  String get redone => 'やり直しました';

  @override
  String get undoFailed => '元に戻せませんでした';

  @override
  String get undoLabelTicketEdit => 'チケット編集';

  @override
  String get undoLabelMessageEdit => 'メッセージ編集';

  @override
  String get undoLabelTodoStatus => 'todoステータス';

  @override
  String get inboxTitle => '受信トレイ';

  @override
  String get inboxReview => 'レビュー';

  @override
  String get inboxOpen => '開く';

  @override
  String get inboxAllCaughtUp => 'すべて対応済みです';

  @override
  String get inboxGitHubDownTitle => 'GitHubがダウンしている可能性があります';

  @override
  String inboxGitHubDownBody(String status) {
    return 'GitHubが$statusを報告しているため、このリストにないプルリクエストは、実際に完了したのではなく表示漏れの可能性があります。';
  }

  @override
  String get inboxGitHubIdentityTitle => 'GitHubアカウントを確認できませんでした';

  @override
  String get inboxGitHubIdentityBody =>
      '受信トレイはGitHub上のあなたのアカウントで並べ替えられます。読み込まれるまでは、プルリクエストの待ちがあっても空のまま表示されます。';

  @override
  String get inboxSeverityBlocking => 'ブロック中';

  @override
  String get inboxSeverityWaiting => '待機中';

  @override
  String get inboxSeverityInfo => '情報';

  @override
  String get inboxSyncFailed => '同期に失敗しました';

  @override
  String get inboxNeedsYourAttention => '要対応';

  @override
  String get inboxSectionNeedsYourReview => 'レビュー待ち';

  @override
  String get inboxSectionReturnedToYou => '差し戻し';

  @override
  String get inboxSectionApproved => '承認済み';

  @override
  String get inboxSectionDrafts => 'ドラフト';

  @override
  String get inboxSectionWaitingForReviewers => 'レビュアー待ち';

  @override
  String get inboxSectionMergingAndMerged => 'マージ中・マージ済み';

  @override
  String get inboxSectionWaitingForAuthor => '作成者待ち';

  @override
  String get inboxColumnTitle => 'タイトル';

  @override
  String get inboxColumnChanges => '変更';

  @override
  String get inboxColumnUpdated => '更新';

  @override
  String get inboxReviewApproved => '承認済み';

  @override
  String get inboxReviewChangesRequested => '変更リクエスト';

  @override
  String get inboxHeroSubtitle => 'あなたに関わるすべてのプルリクエストを、次のアクション別に整理します。';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のプルリクエストがレビュー待ちです',
      one: '1件のプルリクエストがレビュー待ちです',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件があなたに差し戻されています',
      one: '1件があなたに差し戻されています',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted => '変更は保存されず、元に戻されました';

  @override
  String get offlinePendingLabel => '保留中';

  @override
  String get offlineSyncingLabel => '同期中';

  @override
  String get copyLinkLabel => 'このページへのリンクをコピー';

  @override
  String get agentsSectionLabel => 'エージェント';

  @override
  String get fleetWorkersTitle => 'ワーカー';

  @override
  String get fleetWorkersSubtitle => 'ジョブを実行できるマシン';

  @override
  String get fleetJobsTitle => 'ジョブ';

  @override
  String get fleetJobsSubtitle => 'フリート全体に分散された作業';

  @override
  String get fleetNoWorkers =>
      'ワーカーはまだありません — `cc_worker --server <url>` を実行している2台目のマシンがフリートに参加します。';

  @override
  String get fleetNoJobs => 'ジョブはありません。';

  @override
  String get fleetError => 'フリートを読み込めませんでした';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countコア',
      one: '1コア',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return 'ハートビート $time';
  }

  @override
  String get fleetNoHeartbeat => 'ハートビートはまだありません';

  @override
  String fleetLastErrorLabel(String error) {
    return '最後のエラー: $error';
  }

  @override
  String get fleetDrain => 'ドレイン';

  @override
  String get fleetResume => '再開';

  @override
  String get fleetRevoke => '失効';

  @override
  String get fleetRemove => '削除';

  @override
  String get fleetRevokeTitle => 'ワーカーを失効しますか？';

  @override
  String fleetRevokeBody(String name) {
    return '$nameを失効しますか？セッションが終了し、実行中のジョブは再割り当てされます。';
  }

  @override
  String get fleetRemoveTitle => 'ワーカーを削除しますか？';

  @override
  String fleetRemoveBody(String name) {
    return '$nameをフリートから削除しますか？そのレコードは削除されます。';
  }

  @override
  String get fleetActionFailed => '操作に失敗しました';

  @override
  String get fleetJobUnassigned => '未割り当て';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '試行 $attempts/$max';
  }

  @override
  String get fleetPlacementReasons => '配置の決定';

  @override
  String get fleetNoPlacements => '配置の決定はまだありません。';

  @override
  String get fleetStatusOnline => 'オンライン';

  @override
  String get fleetStatusDraining => 'ドレイン中';

  @override
  String get fleetStatusOffline => 'オフライン';

  @override
  String get fleetStatusIncompatible => '非互換';

  @override
  String get fleetStatusRevoked => '失効済み';

  @override
  String get fleetJobStatusQueued => 'キュー待ち';

  @override
  String get fleetJobStatusRunning => '実行中';

  @override
  String get fleetJobStatusSucceeded => '成功';

  @override
  String get fleetJobStatusFailed => '失敗';

  @override
  String get fleetJobStatusCancelled => 'キャンセル済み';

  @override
  String get evalsNoSuites => '評価スイートはまだありません。';

  @override
  String get evalsError => '評価を読み込めませんでした';

  @override
  String get evalsStarterBadge => 'スターター';

  @override
  String evalsDefaultBatch(int count) {
    return 'デフォルトのバッチ数: $count';
  }

  @override
  String get evalsRecentRuns => '最近の実行';

  @override
  String get evalsNoRuns => '実行はまだありません。';

  @override
  String get evalsPassRate => '合格率';

  @override
  String evalsBatchTimes(int count) {
    return '× $count';
  }

  @override
  String evalsTriggeredBy(String who) {
    return '$whoによる';
  }

  @override
  String evalsRunFinished(String rate) {
    return '評価が完了 — $rate合格';
  }

  @override
  String get evalsRunFailed => 'スイートを実行できませんでした';

  @override
  String get evalsRun => '実行';

  @override
  String get evalsStatusQueued => 'キュー待ち';

  @override
  String get evalsStatusRunning => '実行中';

  @override
  String get evalsStatusPassed => '合格';

  @override
  String get evalsStatusFailed => '失敗';

  @override
  String get bannerMeetingJoin => '参加';

  @override
  String get bannerMeetingRecordAndLink => '録画してリンク';

  @override
  String get bannerCalendarReconnect => '再接続';

  @override
  String get bannerView => '表示';

  @override
  String get soundscapeTitle => 'サウンドスケープ';

  @override
  String get soundscapePlay => '再生';

  @override
  String get soundscapePause => '一時停止';

  @override
  String get soundscapeMoodLabel => 'ムード';

  @override
  String get soundscapeMoodFocus => '集中';

  @override
  String get soundscapeMoodRelax => 'リラックス';

  @override
  String get soundscapeMoodSleep => '睡眠';

  @override
  String get soundscapeVolumeLabel => '音量';

  @override
  String get soundscapeTuneLabel => '音色';

  @override
  String get soundscapeTuneMellow => 'まろやか';

  @override
  String get soundscapeTuneBright => '明るい';

  @override
  String get soundscapeTuneEnergetic => 'エネルギッシュ';

  @override
  String get soundscapeTuneSpacy => 'スペーシー';

  @override
  String get soundscapeTuneResetHint => 'ダブルタップでリセット';

  @override
  String get soundscapeSceneLabel => '再生中';

  @override
  String get soundscapeSceneLoading => '環境音を調整中…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees°C';
  }

  @override
  String get soundscapeLocationLabel => '場所';

  @override
  String get soundscapeLocationDetecting => '場所を検出中…';

  @override
  String get soundscapeLocationAutoNote => '場所はこのワークスペースから自動的に検出されます。';

  @override
  String get soundscapeRefreshWeather => '天気を更新';

  @override
  String get soundscapeAutoStartLabel => '集中モードと一緒に開始';

  @override
  String get soundscapeAutoStartDescription =>
      '集中セッションを開始すると、サウンドスケープを自動再生します。';

  @override
  String get soundscapeReturnToApp => 'アプリに戻る';

  @override
  String get soundscapePopOut => 'プレーヤーをポップアウト';

  @override
  String get discussion => 'ディスカッション';

  @override
  String get chat => 'チャット';

  @override
  String get saving => '保存中…';

  @override
  String get saved => '保存しました';

  @override
  String get saveFailed => '保存できませんでした';

  @override
  String get commitAndPush => 'コミットしてプッシュ';

  @override
  String get commit => 'コミット';

  @override
  String get commitAmend => 'コミット（amend）';

  @override
  String get commitAndSync => 'コミットして同期';

  @override
  String get committed => 'コミットしました';

  @override
  String get commitAmended => 'コミットをamendしました';

  @override
  String get commitFailed => 'コミットに失敗しました';

  @override
  String get moreCommitActions => 'その他のコミット操作';

  @override
  String get sourceControl => 'ソース管理';

  @override
  String fixFindingTitle(String location) {
    return '修正: $location';
  }

  @override
  String get openInEditor => 'エディタで開く';

  @override
  String get regexTesterTitle => '正規表現をテスト';

  @override
  String get regexTesterHint => 'サンプルを入力';

  @override
  String get regexMatch => '一致';

  @override
  String get regexNoMatch => '一致なし';

  @override
  String get regexInvalidPattern => '無効なパターン';

  @override
  String get symbolLookupNone => 'インデックスにもこのプルリクエストにも定義がありません';

  @override
  String get symbolLookupInDiff => 'このプルリクエスト内で見つかりました';

  @override
  String get symbolLookupFromBase =>
      'ベースのチェックアウトから — この PR の worktree はまだインデックスされていません';

  @override
  String get symbolImplementations => '実装';

  @override
  String symbolCallersCount(int count) {
    return '$count 件の呼び出し元';
  }

  @override
  String get commitMessageHint => 'コミットメッセージ';

  @override
  String get pushedToPr => 'PRにプッシュしました';

  @override
  String get pushFailed => 'プッシュに失敗しました';

  @override
  String get reviewFindings => '指摘事項';

  @override
  String get treeLabel => 'ツリー';

  @override
  String get toggleFileTree => 'ファイルツリーの表示を切り替え';

  @override
  String get diffViewSettings => '差分ビューの設定';

  @override
  String get splitViewLabel => '分割';

  @override
  String get unifiedViewLabel => '統合';

  @override
  String get wrapLines => '行の折り返し';

  @override
  String get shiftClickSelectRange => 'Shift+クリックで範囲選択';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countファイル',
      one: '1ファイル',
    );
    return '$_temp0';
  }

  @override
  String prComplexityLoc(String loc) {
    return '$loc LOC';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return '小さいPR — $files、レビュー約$minutes分';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return '中規模のPR — $files、約$minutes分のレビュー時間を確保してください';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return '大きなPR — $files、レビュー前に分割を検討してください';
  }

  @override
  String get searchInFiles => 'ファイル内を検索';

  @override
  String get showFileList => 'ファイルリストを表示';

  @override
  String get searchInFilesHintField => 'ファイル内を検索…';

  @override
  String get searchInFilesHint => 'プルリクエストの全ファイルを検索';

  @override
  String get searchInWholeRepo => 'リポジトリ全体を検索';

  @override
  String get searchInThisPullRequest => 'このプルリクエスト内を検索';

  @override
  String get searchNoResults => '結果が見つかりませんでした';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の結果',
      one: '1件の結果',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$filesファイル',
      one: '1ファイル',
    );
    return '$_temp0（$_temp1）';
  }

  @override
  String get discardChangesTitle => '変更を破棄しますか？';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countファイル',
      one: '1ファイル',
    );
    return '$_temp0をHEADまで破棄しますか？この操作は取り消せません。';
  }

  @override
  String get discardAll => 'すべて破棄';

  @override
  String get discardFailed => '変更を破棄できませんでした';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countファイル',
      one: '1ファイル',
    );
    return '$_temp0を破棄しました';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '$revertedファイル',
      one: '1ファイル',
    );
    return '$_temp0を破棄しました。$skipped件はスキップ（未追跡）';
  }

  @override
  String get prWorktreeUnavailable => 'ワークスペースの準備ができていません';

  @override
  String get prWorktreeUnavailableHint =>
      'プルリクエストのファイルの準備に失敗しました。プルリクエストを開き直して再試行してください。';

  @override
  String get timestampRelativeLabel => '相対表示';

  @override
  String get timestampRawLabel => 'タイムスタンプ';

  @override
  String get copyTimestamp => 'タイムスタンプをコピー';

  @override
  String get copiedTimestamp => 'タイムスタンプをコピーしました';

  @override
  String get previewDeployment => 'プレビューデプロイ';

  @override
  String previewDeploymentTab(String site) {
    return 'プレビュー: $site';
  }

  @override
  String get askForReview => 'レビューを依頼…';

  @override
  String get closePrsConfirmTitle => 'プルリクエストをクローズしますか？';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のプルリクエストをクローズしますか？',
      one: '1件のプルリクエストをクローズしますか？',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のプルリクエストをクローズしました',
      one: '1件のプルリクエストをクローズしました',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のプルリクエストをアサインしました',
      one: '1件のプルリクエストをアサインしました',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のプルリクエストにレビューを依頼しました',
      one: '1件のプルリクエストにレビューを依頼しました',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の操作に失敗',
      one: '1件の操作に失敗',
    );
    return '$_temp0';
  }

  @override
  String get diagram => 'ダイアグラム';

  @override
  String get diagramViewSource => 'ソースを表示';

  @override
  String get diagramHideSource => 'ソースを隠す';

  @override
  String diagramPreviewUnavailable(String reason) {
    return 'ダイアグラムのプレビューは利用できません（$reason）';
  }

  @override
  String get planUnavailable => 'プランは利用できません';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countステップ',
      one: '1ステップ',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => '承認して実行';

  @override
  String get planStatusDraft => 'ドラフト';

  @override
  String get planStatusProposed => 'プラン提案';

  @override
  String get planStatusApproved => 'プラン承認済み';

  @override
  String get planStatusRejected => 'プラン却下';

  @override
  String get planStatusSuperseded => 'プラン置き換え済み';

  @override
  String planRevisionLabel(int revision) {
    return 'リビジョン $revision';
  }

  @override
  String get adapterEnforcementTitle => 'このアダプターが強制すること';

  @override
  String get enforcementFiltersToolSurface => 'Control Centerがツールを選択';

  @override
  String get enforcementInterceptsToolCalls => 'すべての呼び出しを実行前にゲート';

  @override
  String get enforcementObservesCompletionContract => '実行には成果物の完成が求められる';

  @override
  String get enforcementNativeToolsInterceptable => 'ランナー独自のツールが可視';

  @override
  String get enforcementInProcessToolsSandboxed => 'インプロセスのツールはサンドボックス化';

  @override
  String get enforcementYes => 'はい';

  @override
  String get enforcementNo => 'いいえ';

  @override
  String get adapterEnforcementCaveats => '注意点';

  @override
  String get enforcementSummaryModesEnforced => 'モード強制あり';

  @override
  String get enforcementSummaryModesNotEnforced => 'モード強制なし';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の注意点',
      one: '1件の注意点',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      '読み取り専用モードは構造的なものではありません。Control Centerはこのランナー独自のツールを削除できません。';

  @override
  String get caveatToolCallsNotIntercepted =>
      '実行前ゲートがありません。MCPツール呼び出しのみがControl Centerを経由します。';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      'ランナー独自のファイルツールとシェルツールはControl Centerに一切到達しません。OSサンドボックスだけが下限となります。';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      'インプロセスのファイルツールはサンドボックス外で動作するため、ツール面が唯一のファイルシステム境界になります。';

  @override
  String get caveatCompletionContractUnobservable =>
      '成果物を出さずに終わった実行について、Control Centerは注意を促すことも失敗扱いにすることもできません。';

  @override
  String get modeDegraded => '機能制限';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return '$adapterの$modeモードはサンドボックスのみに依存します。エージェント独自のファイルツールは傍受されません。';
  }

  @override
  String get artifactUnavailable => 'アーティファクトは利用できません';

  @override
  String artifactRevisionLabel(int count) {
    return '$count件のリビジョン';
  }

  @override
  String get artifactShowMore => 'さらに表示';

  @override
  String get artifactShowLess => '表示を減らす';

  @override
  String get artifactCopy => 'コピー';

  @override
  String get artifactCopied => 'アーティファクトをコピーしました';

  @override
  String get artifactsTabLabel => 'アーティファクト';

  @override
  String get artifactsEmptyTitle => 'アーティファクトはまだありません';

  @override
  String get artifactsEmptyBody =>
      'エージェントがここでテーブル、チャート、ダイアグラムを公開すると、このリストに表示されます。';

  @override
  String get artifactRevisionPickerLabel => 'リビジョン';

  @override
  String get artifactRestoreRevision => 'このリビジョンを復元';

  @override
  String get artifactOpenInTab => 'タブで開く';

  @override
  String get artifactTitleFallback => 'アーティファクト';

  @override
  String get providerGenerationLabel => '生成のデフォルト';

  @override
  String get providerGenerationHint =>
      'フィールドを空にすると、エンドポイント独自のデフォルトが使用されます。モデルは独自の出力上限とサンプリングレシピを公開しており、他の値で動かすと品質が低下する場合があります。';

  @override
  String get providerMaxTokensLabel => '最大出力トークン';

  @override
  String get addModel => 'モデルを追加';

  @override
  String get modelListTitle => 'モデルリスト';

  @override
  String get railProvidersGroup => 'プロバイダー';

  @override
  String get railCustomProvidersGroup => 'カスタムプロバイダー';

  @override
  String get editModelSettings => 'モデル設定を編集';

  @override
  String get modelIdLabel => 'モデルID';

  @override
  String get modelIdImmutableHint => 'エンドポイントが提供するID。リストに追加した後は変更できません。';

  @override
  String get contextWindowLabel => 'コンテキストウィンドウ';

  @override
  String get inputTypesLabel => '入力タイプ';

  @override
  String get outputTypesLabel => '出力タイプ';

  @override
  String get modalityText => 'テキスト';

  @override
  String get modalityImage => '画像';

  @override
  String get modalityAudio => '音声';

  @override
  String get modalityVideo => '動画';

  @override
  String get modalityPdf => 'PDF';

  @override
  String get modelOverrideReset => '自動に戻す';

  @override
  String get modelOverrideEdited => '編集済み';

  @override
  String get manualModelBadge => '手動追加';

  @override
  String get modelIdRequired => 'モデルIDを入力してください。';

  @override
  String get modelTokensInvalid => 'トークン数を正の整数で入力してください。';

  @override
  String get removeModelAction => 'モデルを削除';

  @override
  String removeModelConfirmTitle(String model) {
    return '$modelを削除しますか？';
  }

  @override
  String get removeModelConfirmBody =>
      'モデルはリストから外れ、それに固定されたエージェントは動作しなくなります。プロバイダーには影響しません。';

  @override
  String get addModelProviderTitle => 'モデルプロバイダーを追加';

  @override
  String get addModelProviderDescription => 'カスタムAPIエンドポイントとそのモデルを設定します。';

  @override
  String get modelListEmptyHint => 'モデルが設定されていません。チャットで使用するにはモデルを追加してください。';

  @override
  String get addProviderModelsHint =>
      'エンドポイントが応答すると、モデルが自動的に取得されます。一覧を返せない場合にのみ手動で追加してください。';

  @override
  String get providerTemperatureLabel => 'Temperature';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved => '生成のデフォルトを保存しました';

  @override
  String get providerGenerationInvalid =>
      '値を確認してください: 最大出力トークンとtop-kは正の数、temperatureは0〜2、top-pは0〜1にしてください。';

  @override
  String get providerGenerationOverridden => '上書き済み';

  @override
  String get branchNotPushed => '未プッシュ';

  @override
  String branchNotOnRemote(String branch) {
    return '「$branch」はこの会話にのみ存在します';
  }

  @override
  String get branchNotOnRemoteHint =>
      'GitHubにはまだこのブランチが存在しないため、プルリクエストでは利用できません。公開すると、ワークツリー内のコミット済みのものだけがプッシュされ、未コミットの変更はそのまま残ります。';

  @override
  String get publishBranch => 'ブランチを公開';

  @override
  String branchPublished(String branch) {
    return '「$branch」をoriginに公開しました';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return 'ブランチを公開しました。未コミットの変更$count件は含まれていません。';
  }

  @override
  String get composePrLoadingBranches => 'GitHubからブランチを読み込み中…';

  @override
  String get composePrBranchesFailed =>
      'GitHubからブランチを読み込めませんでした。ブランチ名を入力するか、GitHub接続を確認してください。';

  @override
  String get composePrSubtitleFromSpace =>
      'この会話のブランチから — GitHubに存在しない場合は先に公開してください';

  @override
  String get obsTabInsights => 'インサイト';

  @override
  String get obsTabLive => 'ライブ';

  @override
  String get obsTabQuality => '品質';

  @override
  String get obsTabUsage => '使用量';

  @override
  String get obsUsageTotalTokens => '合計トークン';

  @override
  String get obsUsagePeakTokens => 'ピークトークン';

  @override
  String get obsUsageLongestSession => '最長セッション';

  @override
  String get obsUsageCurrentStreak => '現在の連続日数';

  @override
  String get obsUsageLongestStreak => '最長連続日数';

  @override
  String obsUsageDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日',
      one: '1日',
      zero: '0日',
    );
    return '$_temp0';
  }

  @override
  String get obsUsageTokenActivity => 'トークンアクティビティ';

  @override
  String get obsUsageActivityModeLabel => 'トークンアクティビティモード';

  @override
  String get obsUsageModeDaily => '日別';

  @override
  String get obsUsageModeWeekly => '週別';

  @override
  String get obsUsageModeCumulative => '累積';

  @override
  String get obsUsageTimeRange => '期間';

  @override
  String get obsUsageTrendTitle => '日別トークントレンド';

  @override
  String get obsUsageModelUsage => 'モデル別使用量';

  @override
  String get obsUsageTokensLabel => 'トークン';

  @override
  String get obsUsageNoActivity => '記録されたトークン使用量はまだありません';

  @override
  String get obsUsageOtherModels => 'その他';

  @override
  String obsUsageCellReadout(String date, String tokens) {
    return '$date · $tokensトークン';
  }

  @override
  String obsUsageActivitySummary(
    String start,
    String end,
    int activeDays,
    String peak,
  ) {
    return '$startから$endまでのトークンアクティビティ。アクティブ日数は$activeDays日。最繁忙日は$peakトークン。';
  }

  @override
  String get obsScreenSubtitle => 'エージェントのライブ制御、コスト帰属、割り当て、品質シグナル';

  @override
  String get obsRangeLast24h => '過去24時間';

  @override
  String get obsRangeLast7d => '過去7日間';

  @override
  String get obsRangeLast30d => '過去30日間';

  @override
  String get obsRangeAll => '全期間';

  @override
  String get obsAddFilter => 'フィルターを追加';

  @override
  String get obsFilterAgent => 'エージェント';

  @override
  String get obsFilterModel => 'モデル';

  @override
  String get obsFilterStatus => 'ステータス';

  @override
  String get obsFilterRole => 'ロール';

  @override
  String get obsKpiTotalRuns => '合計実行数';

  @override
  String get obsKpiTotalCost => '合計コスト';

  @override
  String get obsKpiErrorRate => 'エラー率';

  @override
  String get obsKpiCacheRate => 'キャッシュ率';

  @override
  String get obsKpiTokensPerSec => 'トークン/秒';

  @override
  String get obsKpiAvgLatency => '平均レイテンシ';

  @override
  String get obsKpiTtft => '最初のトークンまでの時間';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '前期間比 $delta';
  }

  @override
  String get obsChartActivity => 'アクティビティ';

  @override
  String get obsChartCost => 'コストの推移';

  @override
  String get obsLegendRuns => '実行';

  @override
  String get obsLegendErrors => 'エラー';

  @override
  String get obsAgentsTitle => 'エージェント';

  @override
  String obsShowAllAgents(int count) {
    return '全$countエージェントを表示';
  }

  @override
  String get obsShowFewerAgents => '表示を減らす';

  @override
  String get obsRunsTitle => '実行';

  @override
  String get obsNoRunsInRange => 'この期間に実行はありません';

  @override
  String get obsColTime => '時刻';

  @override
  String get obsColAgent => 'エージェント';

  @override
  String get obsColStatus => 'ステータス';

  @override
  String get obsColModel => 'モデル';

  @override
  String get obsColDuration => '所要時間';

  @override
  String get obsColTokens => 'トークン';

  @override
  String get obsColCost => 'コスト';

  @override
  String get obsColErrors => 'エラー';

  @override
  String get obsColRuns => '実行';

  @override
  String get obsColAvgLatency => '平均レイテンシ';

  @override
  String get obsColLastActive => '最終アクティブ';

  @override
  String get obsStatusPending => '保留中';

  @override
  String get obsStatusRunning => '実行中';

  @override
  String get obsStatusCompleted => '完了';

  @override
  String get obsStatusError => 'エラー';

  @override
  String get obsRosterLoadError => 'エージェント一覧を読み込めませんでした。';

  @override
  String get obsRosterEmpty => 'エージェントはまだいません';

  @override
  String get obsRosterEmptyDescription =>
      'エージェントを派遣すると、ステータス、現在のツール、トークン、コストがライブでここに表示されます。';

  @override
  String get obsKillAgent => 'エージェントを強制終了';

  @override
  String get obsRosterTokensLabel => 'tok';

  @override
  String get obsCostByRoleTitle => 'ロール別コスト';

  @override
  String get obsCostByRoleSubtitle => 'このワークスペースの支出をロール別に表示';

  @override
  String get obsRoleMain => 'メイン';

  @override
  String get obsRoleSubagents => 'サブエージェント';

  @override
  String get obsRoleAdvisor => 'アドバイザー';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return 'メイン: $main · サブエージェント: $sub · アドバイザー: $advisor';
  }

  @override
  String get obsTotal => '合計';

  @override
  String get obsTokenModelTitle => 'トークンモデル（5軸）';

  @override
  String get obsTokenModelSubtitle => 'このワークスペースが消費した全トークンを軸別に表示';

  @override
  String get obsAxisInput => '入力';

  @override
  String get obsAxisOutput => '出力';

  @override
  String get obsAxisReasoning => '推論';

  @override
  String get obsAxisCacheRead => 'キャッシュ読み取り';

  @override
  String get obsAxisCacheWrite => 'キャッシュ書き込み';

  @override
  String get obsTotalTokens => '合計トークン';

  @override
  String get obsCacheDiscountNote =>
      'キャッシュ読み取りトークンは割引額で課金されるため、同じ量の新しい入力よりはるかに安くつきます。';

  @override
  String get obsByModelTitle => 'モデル別';

  @override
  String get obsByModelSubtitle => 'モデルごとのトークンとコスト使用量';

  @override
  String get obsNoModelUsage => '記録されたモデル使用量はまだありません。';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の実行',
      one: '1件の実行',
    );
    return '$_temp0';
  }

  @override
  String get obsPerRunTitle => '実行あたり';

  @override
  String get obsPerRunSubtitle => '1回の実行にかかる典型的なトークンコスト';

  @override
  String get obsMedianRunTokens => '実行トークンの中央値';

  @override
  String get obsMedianRunTokensSub => '全実行の中央値';

  @override
  String get obsRunsInWorkspace => 'このワークスペース内';

  @override
  String get obsCostShare => 'コスト占有率';

  @override
  String get obsQuotaConfiguredLimits => '設定済みの上限';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      '設定した上限に対する使用量を、ステータスが悪い順に表示します。';

  @override
  String get obsQuotaAddLimit => '上限を追加';

  @override
  String get obsQuotaNoLimits =>
      '割り当て上限はまだ設定されていません — 1つ追加すると、上限に対する使用量を追跡できます。';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return '$titleの上限を削除';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return '$duration後にリセット · $status';
  }

  @override
  String get obsQuotaUsageWindows => '使用ウィンドウ';

  @override
  String get obsQuotaUsageWindowsSubtitle => 'すべてのプロバイダーで観測された使用量。上限は適用されません。';

  @override
  String get obsQuotaNoUsage => '記録された使用量はまだありません。';

  @override
  String get obsQuotaTokensUsed => '使用トークン';

  @override
  String get obsQuotaRequests => 'リクエスト';

  @override
  String get obsQuotaUnitTokens => 'トークン';

  @override
  String get obsQuotaUnitRequests => 'リクエスト';

  @override
  String get obsQuotaUnitCost => 'コスト';

  @override
  String get obsQuotaAddLimitTitle => '割り当て上限を追加';

  @override
  String get obsQuotaProviderLabel => 'プロバイダー';

  @override
  String get obsQuotaWindowLabel => 'ウィンドウ';

  @override
  String get obsQuotaUnitLabel => '単位';

  @override
  String obsQuotaLimitLabel(String unit) {
    return '上限（$unit）';
  }

  @override
  String get obsQuotaCentsHint => '米国セント単位（500 = \$5.00）。';

  @override
  String get obsQuotaStatusOk => 'OK';

  @override
  String get obsQuotaStatusWarning => '警告';

  @override
  String get obsQuotaStatusExhausted => '枯渇';

  @override
  String get obsQuotaStatusUnknown => '不明';

  @override
  String get obsGoalNoActiveTitle => 'アクティブな目標なし';

  @override
  String get obsGoalNoActiveBody =>
      '目標を設定すると、エージェントに目的と任意のトークン予算を与えられます。実行が完了するたびに予算が消化され、残りわずかになるとエージェントはまとめに入るよう促されます。';

  @override
  String get obsGoalSetGoal => '目標を設定';

  @override
  String get obsGoalTokenBudget => 'トークン予算';

  @override
  String obsGoalTokensLeft(String tokens) {
    return '残り$tokens';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens（予算未設定）';
  }

  @override
  String get obsGoalTokensUsed => '使用トークン';

  @override
  String get obsGoalElapsed => '経過時間';

  @override
  String get obsGoalWrapUp => 'まとめに入る';

  @override
  String get obsGoalClear => '目標をクリア';

  @override
  String get obsGoalFallbackTitle => '目標';

  @override
  String get obsGoalSubtitle => 'ゴールモードの予算';

  @override
  String get obsGoalStatusActive => 'アクティブ';

  @override
  String get obsGoalStatusPaused => '一時停止';

  @override
  String get obsGoalStatusBudgetLimited => '予算制限';

  @override
  String get obsGoalStatusComplete => '完了';

  @override
  String get obsGoalStatusDropped => '中止';

  @override
  String get obsGoalObjectiveLabel => '目的';

  @override
  String get obsGoalBudgetLabel => 'トークン予算（任意）';

  @override
  String get obsGoalSetAction => '目標を設定';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => '成功率';

  @override
  String get obsBenchmarkPassed => '合格';

  @override
  String get obsBenchmarkFailed => '失敗';

  @override
  String get obsBenchmarkErrors => 'エラー';

  @override
  String get obsBenchmarkSpend => '支出';

  @override
  String get obsBenchmarkCostPerTask => 'タスクあたりコスト';

  @override
  String get obsBenchmarkTrials => '試行';

  @override
  String get obsBenchmarkNoTrials => '採点する実行がまだありません。';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '他$count件',
      one: '他1件',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => '合格';

  @override
  String get obsBenchmarkTrialFail => '不合格';

  @override
  String get obsBenchmarkTrialError => 'エラー';

  @override
  String get obsBenchmarkTrialRunning => '実行中';

  @override
  String get obsBenchmarkReward => '報酬';

  @override
  String get obsBenchmarkReport => 'レポート';

  @override
  String get obsBenchmarkCopyMarkdown => 'Markdownをコピー';

  @override
  String get obsBenchmarkCopied => 'レポートをクリップボードにコピーしました';

  @override
  String get obsBehaviorCaption =>
      'これはあなた自身のメッセージから解析されたフラストレーションシグナルです。会話の健康度の読み取りであって、エージェントのスコアではありません。ローカルで計算され、データがこのデバイスの外へ出ることはありません。';

  @override
  String get obsBehaviorMessagesAnalyzed => '解析済みメッセージ';

  @override
  String get obsBehaviorTotalSignals => 'シグナル合計';

  @override
  String get obsBehaviorYelling => '叫び';

  @override
  String get obsBehaviorProfanity => '罵倒';

  @override
  String get obsBehaviorAnguish => '悲嘆';

  @override
  String get obsBehaviorNegation => '否定';

  @override
  String get obsBehaviorRepetition => '繰り返し';

  @override
  String get obsBehaviorBlame => '責任転嫁';

  @override
  String get obsBehaviorConversationsTitle => 'フラストレーションが最も高い会話';

  @override
  String get obsBehaviorConversationsSubtitle => 'メッセージ中のシグナル密度でランク付け。';

  @override
  String get obsBehaviorNoSignals => 'フラストレーションシグナルは検出されませんでした — 順調そのものです。';

  @override
  String obsBehaviorMessagesCount(String count) {
    return '$count件のメッセージを解析';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return 'シグナル$count件';
  }

  @override
  String get obsAgentStatusIdle => 'アイドル';

  @override
  String get obsAgentStatusParked => '休止中';

  @override
  String get obsAgentStatusAborted => '中止';

  @override
  String get obsAgentKindSub => 'サブ';

  @override
  String get noChecksOnCommit => 'このコミットにはチェックが実行されていません。';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '実行中 — $countジョブ',
      one: '実行中 — 1ジョブ',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'すべてのチェックが成功 — $countジョブ',
      one: 'すべてのチェックが成功 — 1ジョブ',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '完了 — $countジョブ',
      one: '完了 — 1ジョブ',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$totalジョブ',
      one: '1ジョブ',
    );
    return '$_temp0のうち$failed件が失敗しました';
  }

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countジョブ',
      one: '1ジョブ',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return 'マトリクス: $jobId';
  }

  @override
  String get jobLogsPending => 'ジョブが完了すると、ログがここに表示されます。';

  @override
  String get jobLogsUnavailable => 'このジョブのログは利用できません。';

  @override
  String get noLogsForStep => 'このステップのログは記録されていません。';

  @override
  String get jobLogsTruncated => 'ログは切り詰められました — 最新の出力を表示しています。';

  @override
  String get fullLog => '完全なログ';

  @override
  String get copyLogs => 'ログをコピー';

  @override
  String get resizeGraph => 'ドラッグしてグラフのサイズを変更';

  @override
  String workflowRunStartedAgo(String time) {
    return '$timeに開始';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return '$timeに完了';
  }

  @override
  String get chatBridgesTitle => 'チャットブリッジ';

  @override
  String chatProviderDescription(String provider, String command) {
    return '$providerでボットにメンションしてエージェントに作業を依頼するか、$commandでチケットを作成してください。';
  }

  @override
  String chatConnectProvider(String provider) {
    return '$providerを接続';
  }

  @override
  String get chatDisconnectProvider => '切断';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$teamNameの$botName';
  }

  @override
  String get chatStateLive => '稼働中';

  @override
  String get chatStateConnecting => '接続中…';

  @override
  String get chatStateError => '接続エラー';

  @override
  String get chatNotConnected => '未接続';

  @override
  String chatStreamingUnavailable(String provider) {
    return 'この$providerアプリではライブストリーミングがオフです — 返信は1つのメッセージとして届きます。';
  }

  @override
  String chatAdminOnly(String provider) {
    return 'このワークスペースの$providerを接続できるのは管理者だけです。';
  }

  @override
  String chatConnectHint(String provider) {
    return '$providerアプリを作成し、その認証情報をここに貼り付けてください。Control Centerから$providerへ接続するため、このサーバーに公開アドレスは不要です。';
  }

  @override
  String chatOpenConsole(String provider) {
    return '$providerコンソールを開く';
  }

  @override
  String get chatOpenSetupGuide => 'セットアップガイド';

  @override
  String get chatFieldBotToken => 'ボットトークン';

  @override
  String get chatFieldAppToken => 'アプリレベルトークン';

  @override
  String get chatFieldConfigRefreshToken => 'アプリ設定トークン';

  @override
  String chatFieldOptional(String label) {
    return '$label（任意）';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return '自分の$providerアカウントを連携';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return '$providerアカウントを連携すると、そこで送ったメッセージがあなたのものとして扱われます。';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return '$externalUserIdに連携済み';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return '$providerアカウントを連携';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return 'このコマンドを$providerのボットに送信してください。1回のみ有効で、15分で失効します。';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return '$providerアカウントを連携しました — そこで送ったメッセージはあなたのものとして扱われます。';
  }

  @override
  String get chatLinkedAccounts => '連携済みアカウント';

  @override
  String chatNoLinkedAccounts(String provider) {
    return '$providerアカウントを連携したメンバーはまだいません。';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '連携済みアカウント$count件',
      one: '連携済みアカウント1件',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '$externalUserId · メールアドレスで照合';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '$externalUserId · コードで連携';
  }

  @override
  String get chatUnlink => '連携解除';

  @override
  String get chatCustomizeBot => 'ボットをカスタマイズ';

  @override
  String get chatCustomizeBotDescription => 'ボットの名前、自己紹介、スラッシュコマンド名を変更できます。';

  @override
  String get chatCustomizeBotUnavailable =>
      'ボットを編集するには、Control Centerにアプリ設定トークンが必要です。再接続して、トークンを含めてください。';

  @override
  String chatCreateAppTitle(String provider) {
    return '$providerアプリを作成';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'Control Centerが、適切な権限とイベントを設定した$providerアプリをあなたの代わりに作成できます。$providerで作業を完了したら、認証情報をここに貼り付けてください。';
  }

  @override
  String get chatCreateApp => 'アプリを作成';

  @override
  String get chatCreateAppCta => 'アプリを作ってもらう';

  @override
  String get chatAppNameLabel => 'アプリ名';

  @override
  String get chatBotDisplayNameLabel => 'ボット名（メンバーが@の後に入力するもの）';

  @override
  String get chatDescriptionLabel => '簡単な説明';

  @override
  String get chatAgentDescriptionLabel => 'ボットの自己紹介';

  @override
  String get chatCommandLabel => 'スラッシュコマンド';

  @override
  String get chatDirectMessages => 'ダイレクトメッセージ';

  @override
  String chatDirectMessagesHint(String provider) {
    return 'メンバーがDMでボットとやり取りできるようになります。$providerの有料プランが必要な場合があります。';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return '$providerがアプリ$appIdを作成しました。';
  }

  @override
  String chatRemainingSteps(String provider) {
    return '残りのいくつかの手順は$providerでしか実行できません:';
  }

  @override
  String get chatStepAppToken => 'アプリレベルトークンを生成';

  @override
  String get chatStepInstall => 'アプリをインストール';

  @override
  String get chatOpenAppSettings => 'アプリ設定を開く';

  @override
  String get chatContinueToCredentials => '認証情報を貼り付け';

  @override
  String chatBotUpdated(String provider) {
    return '$providerでボットを更新しました。';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return '$providerがアプリの権限を変更しました。反映するにはアプリを再インストールしてください。';
  }

  @override
  String get chatReinstallApp => 'アプリを再インストール';

  @override
  String chatIconNotEditable(String provider) {
    return 'ボットのアイコンは、$provider自身のアプリ設定でしか変更できません。';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return '$providerで自分で作成することもできます — トークンは不要です。上の設定はリンクと一緒に運ばれます。';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return '$providerで作成';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return 'ブラウザで$providerが開き、この設定が事前入力されています。そこでアプリを作成し、残りの手順を済ませたら、トークンを持って戻ってきてください。';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return '$providerはどのアプリを作成したかを報告しないため、ここからボットをカスタマイズするには、後でアプリ設定トークンが必要です。';
  }

  @override
  String get chatStepCreateApp => '事前入力された設定でアプリを作成';

  @override
  String chatStepCreateAppHint(String provider) {
    return '$providerでワークスペースを選んで確認してください。';
  }

  @override
  String get chatStepAppTokenHint =>
      '基本情報 → アプリレベルトークンで、connections:writeスコープを付与。';

  @override
  String get chatStepInstallHint => 'アプリのインストール → ボットユーザーOAuthトークンをコピー。';

  @override
  String get calendarUseBuiltinApp => 'Control CenterのGoogleアプリを使用';

  @override
  String get calendarUseBuiltinAppHint =>
      'Googleアカウントで承認してください。Google Cloudでの設定は不要です。';

  @override
  String get calendarUseOwnClient => '自分のGoogle Cloudクライアントを使用';

  @override
  String get calendarUseOwnClientHint =>
      '自分のGoogle CloudプロジェクトのOAuthクライアントを入力してください。';

  @override
  String get aboutTitle => 'このアプリについて';

  @override
  String get aboutAppVersion => 'アプリのバージョン';

  @override
  String get aboutServerVersion => '接続中のサーバー';

  @override
  String get aboutRpcCatalog => 'RPCカタログ';

  @override
  String get aboutServerUnknown => '未報告';

  @override
  String get serverStaleTitle => '同梱サーバーがこのアプリより古くなっています';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return '実行中のcc_serverは$serverVersionですが、このアプリは$appVersionです。アプリを再起動すると、最新の同梱サーバービルドが読み込まれます。開発中は、apps/cc_serverで `dart build cli` を実行して再ビルドしてください。';
  }

  @override
  String get updateCheckButton => '更新を確認';

  @override
  String get updateChecking => '更新を確認中…';

  @override
  String get updateUpToDate => '最新です';

  @override
  String get updateDeferredBusy => '更新の準備はできていますが、会議を録画中です — 終了後に案内します。';

  @override
  String get updateOpenedReleasesPage => 'ブラウザでリリースページを開きました。';

  @override
  String get updateCheckFailed => '更新確認に失敗しました';

  @override
  String updateAvailableVersion(String version) {
    return 'バージョン$versionが利用可能です。';
  }

  @override
  String get updateBannerTitle => '新しいControl Centerが利用可能です';

  @override
  String get updateBannerRefresh => '更新';

  @override
  String get updateBlockedRecording => '会議を録画中は更新が一時停止されます — 終了時に再読み込みされます。';

  @override
  String get settingsScopeYou => '自分';

  @override
  String get settingsScopeWorkspace => 'ワークスペース';

  @override
  String get settingsScopeServer => 'サーバー';

  @override
  String get settingsProfile => 'プロフィールと識別情報';

  @override
  String get settingsYourDevices => '自分のデバイス';

  @override
  String get settingsWorkspaceGeneral => '全般';

  @override
  String get settingsServerConnection => '接続とステータス';

  @override
  String get settingsModelProviders => 'モデルプロバイダー';

  @override
  String get settingsVoiceModels => '音声と会議のモデル';

  @override
  String get settingsDiagnostics => '診断とプライバシー';

  @override
  String get settingsAbout => 'このアプリについて';

  @override
  String get settingsScopeBadgeYou => '自分';

  @override
  String get settingsScopeBadgeDevice => 'このデバイス';

  @override
  String get settingsScopeBadgeWorkspace => 'ワークスペース';

  @override
  String get settingsScopeBadgeServer => 'サーバー';

  @override
  String get settingsProfileDescription =>
      '氏名、メールアドレス、あなたの代わりに作成されるコミットに付くgit識別情報です。';

  @override
  String get settingsServerConnectionDescription =>
      'このクライアントが通信するサーバーと、このサーバーの共有方法（mDNS、トンネル、リレー）です。';

  @override
  String get settingsAboutDescription => 'ビルド識別情報と更新。';

  @override
  String get settingsDiagnosticsDescription =>
      'このインストールの隔離、インデックス、同期、ロギング、クラッシュレポートです。';

  @override
  String get settingsWorkspaceGeneralDescription =>
      'このワークスペースの全メンバーで共有される識別情報、ポリシー、規約です。';

  @override
  String get settingsWorkspacePolicyLabel => 'ワークスペースポリシー';

  @override
  String get settingsWorkspacePolicyDescription =>
      'このワークスペースのすべてのメンバーとエージェントに適用されます。';

  @override
  String get settingsSecretGlobsLabel => 'シークレットパスの除外';

  @override
  String get settingsSecretGlobsHelp =>
      '1行に1つのglobを記述します。これらのパスは、組み込みのデフォルトに加えて、コードを含む画面で閲覧者とゲストには非表示になります。';

  @override
  String get settingsReviewConcurrencyLabel => 'レビューの並列数';

  @override
  String get settingsReviewConcurrencyHelp =>
      '明示的な数が指定されていないときに、並列で派遣されるレビュアーの数です。';

  @override
  String get settingsReviewLevelLabel => 'レビューレベル';

  @override
  String get settingsReviewLevelHelp =>
      'AIレビューの深さと、最初に報告される指摘の量です。破棄はされません — 軽いレベルでは軽微な指摘をまとめて表示するだけです。';

  @override
  String get reviewLevelLight => 'ライト';

  @override
  String get reviewLevelBalanced => 'バランス';

  @override
  String get reviewLevelThorough => '徹底';

  @override
  String get reviewLevelLightHint => 'レビュアー1体。本当に重要なものだけを最初に報告します。';

  @override
  String get reviewLevelBalancedHint => 'QA、アーキテクチャ、実装をカバーする3つのレビュアー。';

  @override
  String get reviewLevelThoroughHint =>
      'セキュリティとパフォーマンスの専門家を追加し、見つかったものすべてを報告します。';

  @override
  String get askAiReviewAtLevel => '別のレベルでレビュー';

  @override
  String reviewNitpicksGroup(int count) {
    return '軽微な指摘（$count）';
  }

  @override
  String get reviewFindingResolve => '修正済み';

  @override
  String get reviewFindingResolveHint => 'この指摘を修正済みにします。レビューのカウントから外れます。';

  @override
  String get reviewFindingDismiss => '却下';

  @override
  String get reviewFindingDismissHint =>
      '実際の問題ではありません。今後のPRでこのパターンは指摘されなくなります。';

  @override
  String get reviewFindingReopen => '再オープン';

  @override
  String get reviewFindingStatusUndoLabel => '指摘のステータス';

  @override
  String get reviewFindingDismissTitle => 'この指摘を却下';

  @override
  String get reviewFindingDismissReasonHint => 'なぜ該当しないのですか？レビュアーが読みます。';

  @override
  String reviewFindingStatusFailed(String error) {
    return '指摘を更新できませんでした: $error';
  }

  @override
  String get reviewStaleTitle => 'このレビューは古くなっています';

  @override
  String get reviewStaleBody =>
      'このレビューの実行後、プルリクエストは進んでいます。指摘が、もう存在しないコードを指している可能性があります。';

  @override
  String reviewStaleReviewedAt(String sha) {
    return '$sha時点でレビュー済み';
  }

  @override
  String get reviewStaleRerun => '再レビュー';

  @override
  String reviewStaleNotificationTitle(int prNumber) {
    return '#$prNumberのレビューが古くなっています';
  }

  @override
  String reviewStaleNotificationBody(String title) {
    return '$titleには前回レビュー以降に新しいコミットがあります。';
  }

  @override
  String get reviewCategorySecurity => 'セキュリティ';

  @override
  String get reviewCategoryStability => '安定性';

  @override
  String get reviewCategoryDataIntegrity => 'データ整合性';

  @override
  String get reviewCategoryCorrectness => '正確性';

  @override
  String get reviewCategoryPerformance => 'パフォーマンス';

  @override
  String get reviewCategoryMaintainability => '保守性';

  @override
  String get reviewEffortQuickWin => 'すぐ直せる';

  @override
  String get reviewEffortModerate => '中程度の作業';

  @override
  String get reviewEffortHeavyLift => '大掛かりな作業';

  @override
  String get reviewProposedFix => '修正案';

  @override
  String get reviewAiAgentPrompt => 'AIエージェント用プロンプト';

  @override
  String get reviewCopyAiPrompt => 'プロンプトをコピー';

  @override
  String get settingsWorkspaceAdminOnly => 'これらを変更できるのはワークスペース管理者だけです。';

  @override
  String get chatMyAccountsTitle => '連携済みチャットアカウント';

  @override
  String get settingsServerSso => 'シングルサインオン';

  @override
  String get settingsServerSsoDescription =>
      'ユーザープロビジョニング付きのSAML/OpenID Connectログイン';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabledDescription => 'ユーザーはこのプロバイダーでサインインできます';

  @override
  String get ssoEnabledDescriptionOn => 'このプロバイダーでのサインインが有効になっています';

  @override
  String get ssoIdpMetadataLabel => 'IdPメタデータXML';

  @override
  String get ssoIdpMetadataHint => 'IdPのEntityDescriptor XMLを貼り付け';

  @override
  String get ssoEmailAttributeLabel => 'メールアドレス属性';

  @override
  String get ssoDisplayNameAttributeLabel => '表示名属性';

  @override
  String get ssoGroupsAttributeLabel => 'グループ属性';

  @override
  String get ssoIssuerLabel => 'Issuer URL';

  @override
  String get ssoClientIdLabel => 'クライアントID';

  @override
  String get ssoGroupsClaimLabel => 'グループクレーム';

  @override
  String get ssoAutoMemberLabel => '初回ログイン時にユーザーを全ワークスペースに追加';

  @override
  String get ssoAutoMemberDescription => 'オフにすると、ワークスペースごとに招待が必要になります';

  @override
  String get ssoAllowJitLabel => '初回ログイン時に未知のユーザーをプロビジョニング';

  @override
  String get ssoAllowJitDescription => 'オフにすると、既存アカウントのないユーザーは拒否されます';

  @override
  String get ssoAllowIdpInitiatedLabel => '未要求の（IdP開始）サインインを受け付ける';

  @override
  String get ssoAllowIdpInitiatedDescription => 'アプリを直接起動するIdPポータル専用です';

  @override
  String get ssoWantResponseSignedLabel => '署名付きレスポンスエンベロープを必須にする';

  @override
  String get ssoWantResponseSignedDescription => 'アサーション署名は常に必須です';

  @override
  String get ssoTestConnectionButton => '接続をテスト';

  @override
  String get ssoTestConnectionOk => '接続は正常です:';

  @override
  String get ssoCopySpMetadata => 'SPメタデータをコピー';

  @override
  String get ssoCopySpMetadataDone => 'SPメタデータをクリップボードにコピーしました';

  @override
  String get ssoSavedToast => 'シングルサインオン設定を保存しました';

  @override
  String get ssoUnavailable =>
      'このサーバーはシングルサインオン設定を公開していません。サーバーのバイナリを更新して、再試行してください。';

  @override
  String get ssoScimCardTitle => 'ユーザープロビジョニング（SCIM）';

  @override
  String get ssoScimDescription =>
      'IdPのSCIMコネクタを、下のエンドポイントへベアラートークン付きで向けてください。プロビジョニング解除は、数秒以内にセッションとワークスペースアクセスを失効させます。サーバーはIdPから到達可能である必要があります（トンネルまたは公開URL）。';

  @override
  String get ssoScimEndpoint => 'SCIMエンドポイント';

  @override
  String get ssoScimEndpointUnknownOrigin =>
      '先にサーバーの公開URLを設定するか、トンネルを有効にしてください';

  @override
  String get ssoScimRegenerate => 'トークンを再生成';

  @override
  String get ssoScimRegenerateConfirm =>
      '新しいSCIMベアラートークンを生成しますか？以前のトークンはすぐに使えなくなります。';

  @override
  String get ssoScimTokenTitle => 'ベアラートークン';

  @override
  String get ssoScimTokenPresent => 'トークンが設定されています';

  @override
  String get ssoScimTokenAbsent => 'トークンはまだありません — SCIMを有効にするには生成してください';

  @override
  String get ssoScimTokenOnce => 'SCIMトークン（一度だけ表示）';

  @override
  String ssoSignInWith(String provider) {
    return '$providerでサインイン';
  }

  @override
  String get ssoProbeFailed => 'シングルサインオンでそのサーバーに到達できませんでした';

  @override
  String get ssoOpensBrowser => 'サインインを完了するためにブラウザを開きます';

  @override
  String get ssoWaitingForBrowser => 'ブラウザでのサインイン完了を待機中…';

  @override
  String get ssoBrowserOpenFailed => 'シングルサインオン用のブラウザを開けませんでした';

  @override
  String get ssoUseManualPairing => '代わりに招待コードかペアリングキーでサインイン';

  @override
  String get ssoHideManualPairing => '手動ペアリングを隠す';

  @override
  String get ssoClientIdHint => 'パブリック（PKCE）クライアント — シークレットは不要です';

  @override
  String get ssoClientSecretLabel => 'クライアントシークレット（任意）';

  @override
  String get ssoClientSecretHintUnset => 'コンフィデンシャルなIdPクライアントでのみ必要です';

  @override
  String get ssoClientSecretHintSet => 'シークレットは保存済みです — 維持するには空欄のままにしてください';

  @override
  String get ssoPairingToggle => '手動ペアリングを許可（招待コードとペアリングキー）';

  @override
  String get ssoPairingToggleDescription =>
      'オフにすると参加はシングルサインオンのみになります — 新しいデバイスはSSOログインから参加し、既存のデバイスは引き続き動作します';

  @override
  String get ssoPairConfirmTitle => 'サーバーに接続しますか？';

  @override
  String ssoPairConfirmBody(String server) {
    return '$serverのサインイン資格情報が届きましたが、このアプリからサインインは開始されていません。このサーバーに接続しますか？';
  }

  @override
  String get ssoPairConfirmConnect => '接続';

  @override
  String get ssoPairConfirmCancel => '無視';

  @override
  String get forgeConnections => 'コードホスティング';

  @override
  String get connect => '接続';

  @override
  String get disconnect => '切断';

  @override
  String get notConnected => '未接続';

  @override
  String get checkingConnection => '接続を確認中…';

  @override
  String get fromEnvironment => '環境変数から';

  @override
  String forgeTokenTitle(String forge) {
    return '$forgeトークン';
  }

  @override
  String get settingsAudio => 'オーディオ';

  @override
  String get settingsAudioDescription => 'マイク、ディクテーション、会議検出、サウンドスケープ出力です。';

  @override
  String get audioDevicesSection => 'オーディオデバイス';

  @override
  String get voiceInputBehaviorSection => 'ディクテーションと会議';

  @override
  String get audioOutputDeviceTitle => '出力デバイス';

  @override
  String get audioOutputDefaultHint => 'アプリのすべての音は、システムのデフォルト出力から再生されます。';

  @override
  String get audioOutputGone =>
      '選択した出力デバイスはもう接続されていません — 別のものを選ぶまで、システムのデフォルトが使用されます。';

  @override
  String get reviewHubIntroBody => 'エージェントが差分を分析し、変更領域をマッピングして、合議の評決に達します。';

  @override
  String get reviewHubAlreadyRunning => 'このプルリクエストではレビューがすでに実行中です';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return '前回レビュー以降: 解決$resolved · 新規$added · 未解決$open';
  }

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return '前回のレビューは$sha時点';
  }

  @override
  String reviewArtifactFixAll(int count) {
    return '$count件の指摘を修正';
  }

  @override
  String reviewArtifactFixSelected(int count) {
    return '選択した$count件を修正';
  }

  @override
  String reviewArtifactCommentSelected(int count) {
    return '選択した$count件にコメント';
  }

  @override
  String get webConnectTitle => 'Control Centerへ接続';

  @override
  String get webConnectSubtitle =>
      '実行中のcc-serverにWebSocketで接続します。キーはこのデバイスにとどまります。';

  @override
  String get webConnectServerLabel => 'サーバー';

  @override
  String get webConnectDeviceIdLabel => 'デバイスID';

  @override
  String get webConnectPairingKeyLabel => 'ペアリングキー';

  @override
  String get webConnectPairingKeyHint => 'PSKを貼り付け';

  @override
  String get webConnectStayConnected => 'このデバイスで接続を維持';

  @override
  String get webConnectStayConnectedDetail => 'このデバイスで接続を維持（キーをこのブラウザに保存します）';

  @override
  String failedToCreateWorkspace(String error) {
    return 'ワークスペースを作成できませんでした: $error';
  }

  @override
  String committedRelative(String relative) {
    return '$relativeにコミット';
  }

  @override
  String get selectAgents => 'エージェントを選択';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countエージェント',
      one: '1エージェント',
    );
    return '$_temp0';
  }

  @override
  String get newConversation => '新しい会話';

  @override
  String get untitledConversation => '無題の会話';

  @override
  String get conversationTitleOptionalHint =>
      '任意 — 空欄のままにするとタイトルモデルが自動的に名前を付けます';

  @override
  String get conversationTitlesSectionTitle => '会話タイトル';

  @override
  String get conversationTitlesSectionCaption =>
      'このワークスペースで新しい会話に自動的に名前を付けるランナーを選択します。アダプターを選択するまでタイトルはオフで、設定は全メンバーに適用されます。';

  @override
  String get conversationTitlesModelLabel => 'タイトルモデル';

  @override
  String get conversationTitlesAdapterLabel => 'アダプター';

  @override
  String get conversationTitlesAdapterHint => 'オフ';

  @override
  String get conversationTitlesAdapterOff => 'オフ';

  @override
  String get startThread => 'スレッドを開始';

  @override
  String get deleteSpaceConfirm => 'このスペースを削除しますか？すべてのメッセージが失われます。';

  @override
  String threadTabTitle(String title) {
    return 'スレッド: $title';
  }

  @override
  String threadReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の返信',
      one: '1件の返信',
    );
    return '$_temp0';
  }

  @override
  String threadLastReply(String time) {
    return '最終返信 $time';
  }

  @override
  String signInWithProvider(String provider) {
    return '$providerでサインイン';
  }

  @override
  String get signInAgain => '再サインイン';

  @override
  String get signInNotFinished => 'サインインがまだ完了していません。ブラウザで済ませてから、もう一度確認してください。';

  @override
  String get signedOutTitle => 'サインアウトしました';

  @override
  String get signedOutSubtitle =>
      'コードホスティングへの接続が有効ではなくなりました — トークンの期限切れか、アクセスが取り消されました。他は何も変わっていません。再サインインすれば、すべて前回のまま残っています。';

  @override
  String get viaServerApp => 'このサーバーのアプリ経由';

  @override
  String get ticketing => 'チケット管理';

  @override
  String get ticketingProviderHelp =>
      'チケットの置き場所です。ローカルではControl Center内に保持されます。';

  @override
  String providerComingSoon(String provider) {
    return '$provider（近日）';
  }

  @override
  String get ticketProviderLocal => 'ローカル';

  @override
  String get addKey => 'キーを追加';

  @override
  String get providerApps => 'プロバイダーアプリ';

  @override
  String get providerAppsDescription =>
      'このサーバーが自身として認証する方法と、個人がサインインする経路です。バックグラウンド処理（ウェブフック、ポーリング、同期）は個人のトークンではなくアプリで実行されます。';

  @override
  String get providerAppId => 'アプリID';

  @override
  String get providerPrivateKey => '秘密鍵';

  @override
  String get providerClientId => 'クライアントID';

  @override
  String get providerClientSecret => 'クライアントシークレット';

  @override
  String get providerApiKey => 'APIキー';

  @override
  String get providerCallbackUrl => 'コールバックURL';

  @override
  String get providerAppFullyConfigured => 'サーバーが自身として動作でき、人がサインインできます。';

  @override
  String get providerAppServerOnly =>
      'サーバーは自身として動作できます。人がサインインできるようにするには、クライアントIDとシークレットを追加してください。';

  @override
  String get providerAppSignInOnly =>
      'ユーザーはサインインできます。バックグラウンド処理はそのユーザーの資格情報にフォールバックします。';

  @override
  String providerAppInstalledOn(String accounts) {
    return '認証情報は機能しています。インストール先: $accounts';
  }

  @override
  String deviceCodeInstructions(String provider) {
    return '開いたばかりの$providerページでこのコードを入力してください。クリップボードにコピーしました。';
  }

  @override
  String get deviceCodeWaiting => 'ブラウザでの操作完了を待っています…';

  @override
  String get copyCodeAndOpen => 'コードをコピーして開く';

  @override
  String get couldNotOpenBrowser =>
      'ブラウザを開けませんでした。リンクをコピーして、サインインをご自身で完了してください。';

  @override
  String get contextUsage => 'コンテキスト使用量';

  @override
  String get contextUsageFull => '満杯';

  @override
  String get contextUsageTokens => 'トークン';

  @override
  String get contextSeeMore => 'さらに表示';

  @override
  String get contextSegmentSystemPrompt => 'システムプロンプト';

  @override
  String get contextSegmentRules => 'ルール';

  @override
  String get contextSegmentSkills => 'スキル';

  @override
  String get contextSegmentToolDefinitions => 'ツール定義';

  @override
  String get contextSegmentMcpTools => 'MCPと動的ツール';

  @override
  String get contextSegmentDeferredTools => 'オンデマンドで読み込まれるツール';

  @override
  String get contextSegmentSubagents => 'サブエージェント定義';

  @override
  String get contextSegmentMemory => 'メモリー';

  @override
  String get contextSegmentConversation => '会話';

  @override
  String get contextExplorerTitle => 'コンテキスト';

  @override
  String get contextExplorerEverything => 'すべて';

  @override
  String get contextExplorerSelectPart => 'パートを選ぶと内容を確認できます';

  @override
  String get contextExplorerUnavailable => 'コンテキストの内訳は利用できません';

  @override
  String get contextRetry => '再試行';

  @override
  String get settingsFieldOptional => '任意';

  @override
  String get settingsFilterHint => 'このリストを絞り込み';

  @override
  String get settingsValueNotAvailable => 'まだ利用できません';

  @override
  String get settingsNoEntriesYet => 'まだ何もありません';

  @override
  String get settingsChangedBadge => '変更あり';

  @override
  String get ssoConnectionCardDescription => 'このサーバーへのサインイン方法を選択し、その接続を有効にします。';

  @override
  String get ssoUseSamlForSignIn => 'サインインにSAMLを使用';

  @override
  String get ssoUseOidcForSignIn => 'サインインにOpenID Connectを使用';

  @override
  String get ssoSaveConnection => '接続を保存';

  @override
  String get ssoStateLive => '稼働中';

  @override
  String get ssoStateConfiguredOff => '設定済み・オフ';

  @override
  String get ssoStateOnIncomplete => 'オン・不完全';

  @override
  String get ssoStateActive => 'アクティブ';

  @override
  String get ssoStateAllowed => '許可';

  @override
  String get ssoStateNoToken => 'トークンなし';

  @override
  String get ssoSummaryDirectorySync => 'ディレクトリ同期';

  @override
  String get ssoSummaryManualPairing => '手動ペアリング';

  @override
  String get ssoNoMethodLiveNote =>
      '有効なサインイン方法がありません。接続を設定して有効にするまで、新しいデバイスは招待コードかペアリングキーで参加します。';

  @override
  String get ssoMethodSamlBlurb =>
      'Okta、Entra ID、Google Workspaceなど、SAML 2.0に対応するIdP向けです。';

  @override
  String get ssoMethodOidcBlurb =>
      'OpenID Connectに対応するIdP向けです。通常、設定は2つのうち簡単な方です。';

  @override
  String get ssoGroupIdentityProvider => 'アイデンティティプロバイダー';

  @override
  String get ssoGroupIdentityProviderSamlDescription =>
      'アサーションがどこから来て、このサーバーがどう検証するかです。';

  @override
  String get ssoGroupIdentityProviderOidcDescription =>
      'このサーバーが信頼するIssuerと、認証に使うクライアントです。';

  @override
  String get ssoSpEntityIdShortLabel => 'SPエンティティID';

  @override
  String get ssoSpEntityIdDescription => '空欄のままにすると、サーバーURLから導出されます。';

  @override
  String get ssoIssuerDescription => 'プロバイダーのdiscoveryドキュメントを提供するベースURLです。';

  @override
  String get ssoSecretStored => '保存済み';

  @override
  String get ssoGroupHandoff => 'IdPに必要なもの';

  @override
  String get ssoGroupHandoffDescription =>
      'プロバイダーで作成したアプリケーションに、これらを貼り付けてください。';

  @override
  String get ssoOriginUnknownTitle => 'このサーバーは自身の公開URLを知りません';

  @override
  String get ssoOriginUnknownBody =>
      'サインインURLとコールバックURLはそこから作られるため、設定されるまでプロバイダーはこのサーバーへ到達できません。サーバー → 接続で公開URLを追加するか、トンネルを有効にしてください。';

  @override
  String get ssoAcsUrlLabel => 'Assertion Consumer Service（ACS）URL';

  @override
  String get ssoAcsUrlDescription => 'プロバイダーが署名済みアサーションをPOSTするURLです。';

  @override
  String get ssoSpEntityIdResolvedLabel => 'サービスプロバイダーエンティティID';

  @override
  String get ssoMetadataUrlLabel => 'SPメタデータURL';

  @override
  String get ssoMetadataUrlDescription =>
      'メタデータをインポートするプロバイダーは、代わりにここから取得できます。';

  @override
  String get ssoRedirectUriLabel => 'リダイレクトURI';

  @override
  String get ssoRedirectUriDescription =>
      'プロバイダーのアプリケーションの許可リダイレクトURIに追加してください。';

  @override
  String get ssoSignInUrlLabel => 'サインインURL';

  @override
  String get ssoSignInUrlDescription => 'シングルサインオンを開始させるときは、ユーザーをここへ送ってください。';

  @override
  String get ssoGroupAttributeMapping => '属性マッピング';

  @override
  String get ssoGroupAttributeMappingDescription =>
      '各フィールドをどのクレームが運ぶかです。プロバイダーが名前を変えない限り、デフォルトのままにしてください。';

  @override
  String get ssoGroupAccess => 'アクセスとロール';

  @override
  String get ssoGroupAccessDescription => 'サインインに成功したユーザーが何をできるかです。';

  @override
  String get ssoDefaultRoleShortLabel => 'デフォルトロール';

  @override
  String get ssoDefaultRoleDescription => '下のどのマッピングにもグループが一致しないユーザーに付与されます。';

  @override
  String get ssoRoleMapShortLabel => 'グループ→ロールマッピング';

  @override
  String get ssoRoleMapDescription => '最初に一致したグループが優先されます。オーナーはこの方法では付与できません。';

  @override
  String get ssoRoleMapGroupHint => 'プロバイダーのグループ名';

  @override
  String get ssoRoleMapAdd => 'マッピングを追加';

  @override
  String get ssoRoleMapEmpty => 'マッピングなし — 全員にデフォルトロールが付与されます。';

  @override
  String get ssoAdvancedSummary => '時計ずれ、IdP開始サインイン、署名ポリシー';

  @override
  String get ssoClockSkewShortLabel => '時計ずれ';

  @override
  String get ssoClockSkewDescription =>
      'アサーションタイムスタンプの許容秒数です。90でほとんどのプロバイダーに対応します。';

  @override
  String get ssoScimGenerate => 'トークンを生成';

  @override
  String get ssoScimTokenOnceBody =>
      'クリップボードにコピーしました。表示は一度きりで復元できません。今すぐプロバイダーに貼り付けてください。';

  @override
  String get ssoPairingCardTitle => '手動ペアリング';

  @override
  String get ssoPairingCardDescription =>
      'このサーバーへのもう1つの入り口です。シングルサインオンを経由しないデバイス向けの、招待コードとペアリングキー。';

  @override
  String settingsCountOfTotal(int count, int total) {
    return '$total件中$count件';
  }

  @override
  String get providersNoneConnectedNote =>
      'どのプロバイダーも接続されていないため、内蔵エージェントランタイムが実行できません。下でAPIキーを追加するか、サインインしてください。';

  @override
  String get providersFilterHint => 'プロバイダーを絞り込み';

  @override
  String get providersNoneMatch => 'このフィルターに一致するものはありません';

  @override
  String get providerDeniedHereTitle => 'このワークスペースで拒否されています';

  @override
  String get providerDeniedHereBody =>
      'このプロバイダーは接続されていても、このワークスペースのエージェントは使用できません。他のワークスペースには影響しません。';

  @override
  String get providerNeedsSignIn => 'このプロバイダーを使うにはサインインしてください';

  @override
  String get providerNeedsApiKey => 'このプロバイダーを使うにはAPIキーを追加してください';

  @override
  String get providerApiKeyLabel => 'APIキー';

  @override
  String get providerGenerationDefaults => 'プロバイダーのデフォルト';

  @override
  String get providerNoModelsYet => 'まだモデルは報告されていません。プロバイダーを接続してから、同期してください。';

  @override
  String get providerModelsFilterHint => 'モデルを絞り込み';

  @override
  String get adaptersNoneReadyNote =>
      'カタログされたランナーCLIはどれもこのマシンで見つかりませんでした。1つインストールしてから更新してください。';

  @override
  String get adaptersFilterHint => 'ランナーを絞り込み';

  @override
  String get adaptersLaunchGroup => '起動';

  @override
  String get adaptersLaunchGroupDescription =>
      'エージェントがこのランナーを起動するときに渡されるものです。CLIのインストール前に設定しておくこともできます。';

  @override
  String get adaptersEnvNone => '未設定';

  @override
  String adaptersEnvCount(int count) {
    return '$count件設定済み';
  }

  @override
  String get adapterArgumentsDescription => '起動のたびに、ランナーのコマンドラインに追加されます。';

  @override
  String get defaultChatDescription => '新しい会話と、専用ランナーのないエージェントを実行します。';

  @override
  String get shortTaskDescription =>
      'タイトルや要約などの短いバックグラウンド作業を実行します。小さいモデルが適しています。';

  @override
  String get settingsStateFailed => '失敗';

  @override
  String get providerAppsGroupServer => 'サーバーとして動作';

  @override
  String get providerAppsGroupServerDescription =>
      'リクエストの背後に人がいなくても、バックグラウンド処理がリポジトリへ到達できるようにします。ウェブフック、プルリクエストのポーリング、チケット同期などです。';

  @override
  String get providerAppsGroupPrConversations => 'プルリクエストでの会話';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      '開発者がGitHub上でこのサーバーと直接対話する方法です。ウェブフックも公開URLも不要で、サーバーがポーリングします。';

  @override
  String get providerAppBotLogin => 'ボットログイン';

  @override
  String get providerAppBotLoginEmpty => 'ボットログインを解決するには、接続をテストしてください。';

  @override
  String get providerAppAskOnGitHub => 'GitHubで依頼する';

  @override
  String get providerAppAskOnGitHubHint =>
      'レビューの依頼や質問は、プルリクエストのコメントで上のボットログインにメンションしてください（[bot]サフィックスは省略可）。レビュースレッド内で返信したり、レビュー依頼として `ai-review` ラベルを追加したりもできます。';

  @override
  String get providerAppsGroupSignIn => 'ユーザーのサインイン';

  @override
  String get providerAppsGroupSignInDescription =>
      '各メンバーが自分のアカウントを接続して、自分の資格情報を取得できるようにします。';

  @override
  String get providerAppCapActsAsServer => 'サーバーとして動作';

  @override
  String get providerAppCapSignsIn => 'ユーザーをサインイン';

  @override
  String get portLabel => 'ポート';

  @override
  String get mcpNoTokenWarning =>
      'トークンがないと、このポートに到達できるものであれば何でも、すべてのツールを呼び出せてしまいます。';

  @override
  String get mcpBridgedToolsLabel => 'ツール';

  @override
  String get guardrailFamilyFiles => 'ファイル';

  @override
  String get guardrailFamilyGit => 'Gitとプルリクエスト';

  @override
  String get guardrailFamilyMachine => 'マシンとネットワーク';

  @override
  String get guardrailFamilyControl => 'シークレットとワークスペース';

  @override
  String get guardrailScopeFieldLabel => 'ルールの編集対象';

  @override
  String get guardrailScopeFieldDescription =>
      '狭いスコープが広いスコープより優先されます。ここで設定したルールは、継承されたルールに重ねて適用されます。';

  @override
  String get guardrailSetHere => 'ここで設定済み';

  @override
  String get guardrailClearAllHere => 'すべてクリア';

  @override
  String get sandboxingCardLabel => 'サンドボックス化';

  @override
  String get sandboxingCardDescription =>
      'エージェントの作業をこのホストから隔離して実行するかどうかと、隔離されたエージェントがまだ到達できるもの。';

  @override
  String get sandboxBackendNoneActive => 'ホスト（隔離なし）';

  @override
  String get sandboxSummaryHost => 'ホスト';

  @override
  String get sandboxGroupIsolation => '隔離';

  @override
  String get sandboxGroupIsolationDescription =>
      'エージェントのプロセスとファイル書き込みが実際に行われる場所です。';

  @override
  String get sandboxBackendFieldDescription =>
      '「自動」はこのホストが対応する最も強いものを選びます。勝手に変わらないように固定してください。';

  @override
  String get sandboxCapabilitiesDescription =>
      '境界に開けられた穴です。それぞれが、隔離されたエージェントが外の世界に対してまだできることです。';

  @override
  String get sandboxSummaryInForce => '有効';

  @override
  String get rigsInstallHintLabel => 'インストール方法';

  @override
  String get rigsStarting => '起動中';

  @override
  String get rigsResidentMemory => '使用メモリ';

  @override
  String get installedLabel => 'インストール済み';

  @override
  String get notInstalledLabel => '未インストール';

  @override
  String ssoOtherKindUnsaved(String method) {
    return '$methodに未保存の変更があります';
  }

  @override
  String get collapseComment => 'コメントを折りたたむ';

  @override
  String get expandComment => 'コメントを展開';

  @override
  String get suggestedChange => '提案された変更';

  @override
  String get emptyComment => '空のコメント';

  @override
  String repliesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の返信',
      one: '1件の返信',
    );
    return '$_temp0';
  }

  @override
  String get pendingReview => '保留中のレビュー';

  @override
  String failedToResolveConversation(String error) {
    return '会話を更新できませんでした: $error';
  }

  @override
  String get addSingleComment => '単一のコメントを追加';

  @override
  String get addToReview => 'レビューに追加';

  @override
  String get startAReview => 'レビューを開始';

  @override
  String get reviewNeedsABody => '先に要約を書くか、インラインコメントを追加してください';

  @override
  String get reviewSubmitted => 'レビューを送信しました';

  @override
  String get finishYourReview => 'レビューを完了';

  @override
  String get commentVerdict => 'コメント';

  @override
  String pendingCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '保留中のコメント$count件',
      one: '保留中のコメント1件',
    );
    return '$_temp0';
  }

  @override
  String andNMore(int count) {
    return '他$count件';
  }

  @override
  String get queuedCommentHint => 'このコメントは、レビューを送信するときに投稿されます。';

  @override
  String commentOnLinesRange(int start, int end) {
    return '$start〜$end行目';
  }

  @override
  String get claudeAccountsTitle => 'Claude Codeアカウント';

  @override
  String get claudeAccountsDescription =>
      '各アカウントは個別のClaude Codeログインです。実行では、下に紐付けたアカウントをこの順序で使用します。';

  @override
  String get claudeAccountsEmpty => 'アカウントはまだありません';

  @override
  String get claudeAccountAdd => 'アカウントを追加';

  @override
  String get claudeAccountSignIn => 'サインイン';

  @override
  String get claudeAccountSignInAgain => '再サインイン';

  @override
  String get claudeAccountSignInHint =>
      'サーバーのターミナルでこれを実行してください。ブラウザが開いてログインが完了し、資格情報がこのアカウントのディレクトリに書き込まれます。';

  @override
  String get claudeAccountSignedOut => 'サインアウト済み';

  @override
  String get claudeAccountExpired => 'サインイン期限切れ';

  @override
  String claudeAccountExpiredDetail(String when) {
    return 'サインインは$whenに期限切れになりました。このアカウントを使用するには、再サインインしてください。';
  }

  @override
  String get claudeAccountMakeDefault => 'デフォルトに設定';

  @override
  String get claudeAccountDefault => 'デフォルト';

  @override
  String claudeAccountRemoveConfirm(String label) {
    return '$labelを削除しますか？';
  }

  @override
  String get claudeAccountRemoveDetail =>
      'アカウントをサインアウトし、サーバー上のそのディレクトリを削除します。ログイン自体には影響しません。';

  @override
  String claudeAccountStatusUnknown(String error) {
    return 'このアカウントを確認できませんでした: $error';
  }

  @override
  String claudeAccountUsedPercent(String percent) {
    return '$percent%使用中';
  }

  @override
  String get accountPoolStrategy => 'ローテーション';

  @override
  String get accountPoolPinned => '固定';

  @override
  String get accountPoolRoundRobin => 'ラウンドロビン';

  @override
  String get accountPoolSerial => '1つずつ';

  @override
  String get accountPoolPinnedHint => '常に最初のアカウントで開始します。他は失敗時のフォールバックとして待機します。';

  @override
  String get accountPoolRoundRobinHint =>
      '実行をアカウント全体に分散し、ディスパッチごとに次のアカウントへ移ります。';

  @override
  String get accountPoolSerialHint => '最初のアカウントを使い切ってから、次に手を付けます。';

  @override
  String get accountPoolMoveUp => '上へ';

  @override
  String get accountPoolMoveDown => '下へ';

  @override
  String get accountPoolUsingAll => 'まだ紐付けなし — すべてのアカウントをこの順序で使用します。';

  @override
  String get accountPoolInheriting => 'ワークスペースのアカウントを継承中です。';

  @override
  String get accountPoolResetToWorkspace => 'ワークスペースのアカウントにリセット';

  @override
  String accountPoolCoolingOff(String when) {
    return '$whenまでクォータ不足';
  }

  @override
  String get accountPoolSignedOut => 'サインアウト済み';

  @override
  String get accountPoolExpired => 'サインイン期限切れ';

  @override
  String accountPoolLoadFailed(String error) {
    return 'ローテーションを読み込めませんでした: $error';
  }

  @override
  String get providerSignedInAccount => 'サインイン済みアカウント';

  @override
  String get agentAccountsTab => 'アカウント';

  @override
  String get agentClaudeAccountsNoticeTitle => '複数のClaude Codeアカウント';

  @override
  String agentClaudeAccountsNoticeBody(int count) {
    return 'このランナーは、このホストにある$count個のClaude Codeアカウントのいずれかとしてサインインします。どれを使うか、またはそれらの間でローテーションするかは、アカウントタブで選べます。';
  }

  @override
  String get agentAccountsDescription =>
      'このエージェントの実行が使用するアカウント。各ブロックは最初、ワークスペースの選択を継承します。';

  @override
  String get agentAccountsNothingToRotate =>
      'ローテーションするものがありません — 先に2つ目のアカウントかキーを接続してください。';

  @override
  String failedToPostReply(String error) {
    return '返信を投稿できませんでした: $error';
  }

  @override
  String commentOnLine(int line) {
    return '$line行目';
  }

  @override
  String get viewInDiff => '差分で表示';

  @override
  String get subscriptionUsagePreviousAccount => '前のアカウント';

  @override
  String get subscriptionUsageNextAccount => '次のアカウント';

  @override
  String inReplyTo(String path) {
    return '$pathへの返信';
  }

  @override
  String get subscriptionUsageNoneReported => 'このアカウントの使用量は報告されていません。';

  @override
  String get subscriptionUsageCredits => 'クレジット';

  @override
  String get reviewHubStaticRule => '静的ルール';

  @override
  String get reviewHubStarted => 'レビューを開始しました';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return 'このプルリクエストが追加する行で、決定論的ルール（$rule）によって検出されました — レビュアーエージェントによるものではありません。';
  }

  @override
  String get prReviewArtifactTab => 'PRレビュー';

  @override
  String get prReviewRunning => 'このプルリクエストをレビュー中…';

  @override
  String get prReviewStarting => 'レビューを開始中…';

  @override
  String get prReviewStartingBody =>
      'このプルリクエストのワークツリーを準備しています。準備ができ次第、レビュアーが開始します。';

  @override
  String get prReviewFailed => 'レビューに失敗しました。';

  @override
  String get prReviewRerunning => '再レビュー中…';

  @override
  String get prReviewNoOpenFindings => '未解決の指摘はありません';

  @override
  String prReviewOpenFindings(int count) {
    return '未解決の指摘$count件';
  }

  @override
  String subscriptionUsageSpend(String used, String limit) {
    return '$limitのうち$used';
  }

  @override
  String reviewCommentsPosted(int posted, int skipped, int failed) {
    return 'ボットとして$posted件のコメントを投稿しました。$skipped件スキップ（ファイルアンカーなし）、$failed件失敗。';
  }

  @override
  String reviewFindingsOutOfDiff(int count, String files) {
    return '$count件の指摘が、このプルリクエストで変更されないコードを対象としています（$files）。GitHubは差分へのインラインコメントのみを受け付けます。';
  }

  @override
  String get reviewRailReport => 'レポート';

  @override
  String get reviewNoFindingsTitle => 'レビューの指摘はまだありません';

  @override
  String get reviewNoFindingsHint => 'エージェントが投稿すると、指摘がここに表示されます。';

  @override
  String reviewShowDismissed(int count) {
    return '却下済み$count件を表示';
  }

  @override
  String reviewHideDismissed(int count) {
    return '却下済み$count件を隠す';
  }

  @override
  String reviewDisagreementsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'レビュアーの不一致を$count件検出',
      one: 'レビュアーの不一致を1件検出',
    );
    return '$_temp0';
  }

  @override
  String get reviewFilterKind => '種類';

  @override
  String get reviewFilterStatus => 'ステータス';

  @override
  String get reviewKindBug => 'バグ';

  @override
  String get reviewKindSuggestion => '提案';

  @override
  String get reviewKindRecommendation => '推奨';

  @override
  String get reviewKindQuestion => '質問';

  @override
  String get reviewKindTicket => 'チケット';

  @override
  String get archiveSpace => 'スペースをアーカイブ';

  @override
  String get archivedSpaces => 'アーカイブ済みのスペース';

  @override
  String get archivedSpacesEmpty => 'アーカイブ済みのスペースはありません';

  @override
  String get restoreSpace => '復元';

  @override
  String archivedWhen(String time) {
    return '$timeにアーカイブ';
  }

  @override
  String get deleteSpacePermanently => '完全に削除';

  @override
  String get renameSpace => 'スペースの名前を変更';

  @override
  String get renameConversation => '会話の名前を変更';

  @override
  String get spaceActions => 'スペースの操作';

  @override
  String get conversationActions => '会話の操作';

  @override
  String get editSpaceRepos => 'リポジトリを編集';

  @override
  String get editSpaceReposTitle => 'スペースのリポジトリ';

  @override
  String get editSpaceReposWarning =>
      'リポジトリを追加するとこのスペースへチェックアウトされ、削除するとそのフォルダーは削除されます。';

  @override
  String get agentSectionIdentity => '識別情報';

  @override
  String get agentSectionRuntime => 'ランタイム';

  @override
  String get agentSectionGuardrails => 'ガードレール';

  @override
  String orgChartReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '部下$count人',
      one: '部下1人',
    );
    return '$_temp0';
  }

  @override
  String get teamsFilterHint => 'チームを絞り込み…';

  @override
  String get teamsSummaryWithLeader => 'リーダーあり';

  @override
  String teamCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countチーム',
      one: '1チーム',
      zero: 'チームなし',
    );
    return '$_temp0';
  }

  @override
  String agentDeleteLongDescription(String name) {
    return '$nameを削除すると、そのプロファイル、スキルの紐付け、実行履歴が削除されます。この操作は取り消せません。';
  }

  @override
  String get resetToDefault => 'デフォルトに戻す';

  @override
  String get newAgent => '新しいエージェント';

  @override
  String get newSkill => '新しいスキル';

  @override
  String get zoomIn => '拡大';

  @override
  String get zoomOut => '縮小';

  @override
  String get resetZoom => 'ズームをリセット';

  @override
  String get imageHostedOnGitHub => 'GitHubでホストされた画像';

  @override
  String get imageOpenExternally => '画像 · 外部で開く';

  @override
  String get memoryScopeAll => 'すべてのスコープ';

  @override
  String get memoryScopeWorkspace => 'ワークスペース全体';

  @override
  String get memoryScopeFilterLabel => 'スコープで絞り込み';

  @override
  String memoryScopeRepoTooltip(String repo) {
    return '$repoリポジトリにスコープ済み';
  }

  @override
  String get toolScreenshot => 'エージェントのスクリーンショット';

  @override
  String get toolImageUnavailable => '画像は利用できません';

  @override
  String toolImagesUnavailable(int count) {
    return '$count枚の画像が利用できません';
  }

  @override
  String get shakeUnavailable => 'このサーバーではシェイクは利用できません';

  @override
  String get shakeNothing => 'シェイクできるものはありません — 直近のターンは保護されています';

  @override
  String shakeDone(int tokens) {
    return '約$tokensトークンを解放しました';
  }

  @override
  String get compactionDivider => '圧縮済み';

  @override
  String compactionDividerCount(int count) {
    return '圧縮済み · $count件のメッセージを統合';
  }

  @override
  String get composerDropToAttach => 'ドロップして添付';

  @override
  String get attachmentUnavailable => '添付ファイルは利用できません';

  @override
  String get attachmentUnavailableDetail =>
      'この添付ファイルはもうメモリに保持されていません。プレビューするには再度添付してください。';

  @override
  String get attachmentPreviewFailed => 'このファイルを開けませんでした';

  @override
  String get attachmentPreviewUnsupported => 'このファイル形式のプレビューはありません';

  @override
  String get attachmentTooLargeToPreview => '大きすぎてプレビューできません';

  @override
  String get attachmentOpenExternally => 'デフォルトアプリで開く';

  @override
  String get asideUnavailable => '使用するには、ワークスペース設定でワンショットモデルを設定してください';

  @override
  String get asideEmpty => 'まだ作業元がありません';

  @override
  String get asideFailed => '回答を取得できませんでした';

  @override
  String get handoffTitle => 'ハンドオフ';

  @override
  String get asideTitle => 'サイド質問';

  @override
  String get attachFilesOrDrop => 'ファイルを添付 — またはここにドロップ';

  @override
  String get guidedGoalTitle => '目的を明確にする';

  @override
  String get guidedGoalIntro => '無監視で動くエージェントは、いつ完了かを正確に知る必要があります。まずいくつか質問です。';

  @override
  String get guidedGoalAnswerHint => 'あなたの回答';

  @override
  String get guidedGoalNext => '次へ';

  @override
  String get guidedGoalStart => '目標を開始';

  @override
  String get guidedGoalSkip => 'スキップしてそのまま実行';

  @override
  String guidedGoalStillMissing(String items) {
    return 'まだ未指定: $items';
  }

  @override
  String get conversationTreeTitle => '会話ツリー';

  @override
  String conversationTreeBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countブランチ',
      one: '1ブランチ',
    );
    return '$_temp0';
  }

  @override
  String get conversationTreeSwitch => 'ここから続ける';

  @override
  String get conversationTreeFork => '新しい会話へフォーク';

  @override
  String get conversationTreeCurrent => 'このブランチ上';

  @override
  String get conversationTreeEmpty => 'まだ何もありません';

  @override
  String get conversationTreeForked => '新しい会話にフォークしました';

  @override
  String get conversationTreeSwitched => 'そのメッセージから継続中です';

  @override
  String exportSaved(String path) {
    return '$pathに保存しました';
  }

  @override
  String get exportFailed => 'エクスポートを書き込めませんでした';

  @override
  String get contextCommandNoAgent => 'この会話にエージェントがいないため、開くコンテキストウィンドウがありません';

  @override
  String contextCommandNoSuchAgent(String name, String names) {
    return 'この会話に「$name」という名前のエージェントはいません。候補: $names';
  }

  @override
  String get dumpCopied => 'トランスクリプトをクリップボードにコピーしました';

  @override
  String get messageQueueHint => '入力を続けると、フォローアップの変更がキューに追加されます';

  @override
  String get steerNow => '軌道修正';

  @override
  String get steeringQueueLabel => 'キューに入った軌道修正メッセージ';

  @override
  String get steeringDeliverUnavailable =>
      '現在それを受け取れる実行中のエージェントはいません — キューに残ります。';

  @override
  String get reorderSteeringCard => 'キュー済みメッセージを並べ替え';

  @override
  String get editSteeringCard => 'キュー済みメッセージを編集';

  @override
  String get deleteSteeringCard => 'キュー済みメッセージを削除';

  @override
  String get steeringBadge => '軌道修正済み';

  @override
  String get settingsSandboxLabel => 'サンドボックス';

  @override
  String get sandboxExecGrantsTitle => '実行許可';

  @override
  String get sandboxExecGrantsSubtitle =>
      'エージェントがリポジトリの作業コピーから実行できるプログラム。各エントリは、サンドボックスが尋ねたときにあなたが承認したものです。';

  @override
  String get sandboxExecGrantsEmpty =>
      '判断の記録はまだありません。エージェントが作業コピーからプログラムを実行する必要ができた最初のときに尋ねられます。';

  @override
  String get sandboxExecGrantRevoke => '取り消す';

  @override
  String get sandboxExecGrantAllowed => '許可';

  @override
  String get sandboxExecGrantBlocked => 'ブロック';

  @override
  String get sandboxExecGrantRevokeConfirmTitle => 'この判断を取り消しますか？';

  @override
  String get sandboxExecGrantRevokeConfirmBody =>
      '次にエージェントがこのコピーからプログラムを実行する必要ができたとき、再度尋ねられます。';

  @override
  String get repoScriptsTest => 'テスト';

  @override
  String get repoScriptsTestTooltip => 'このドラフトをリポジトリの使い捨てクローンで実行します';

  @override
  String get repoScriptsRunKindTest => 'テスト';

  @override
  String get demoBadgeLabel => 'デモ';

  @override
  String get demoFilePickerTitle => 'デモファイル';

  @override
  String get demoFilePickerBody =>
      'デモではアップロードを模倣します。いずれかを選ぶと、ディスクに触れずにメッセージへ添付されます。';

  @override
  String get demoFilePickerAttach => '添付';

  @override
  String get demoReadOnlySave => 'デモでは読み取り専用';

  @override
  String get demoBadgeTooltip => 'デモを見ています。データは架空で、エージェントはスクリプト通りに動きます。';

  @override
  String get demoFirstRunTitle => 'ライブデモの中にいます';

  @override
  String demoFirstRunBody(int minutes) {
    return 'これは実際のコードの上で動く本物のアプリです — 作り話なのはデータだけです。エージェントはスクリプトに沿って本物の実行をストリーミングするため、モデルに届くものもマシン上で動くものもありません。ワークスペースはあなただけのもので、$minutes分後に消えます。';
  }

  @override
  String get demoFirstRunDismiss => '了解';

  @override
  String get demoTourTitle => '最初に見るべき場所';

  @override
  String get demoTourSubtitle => 'アプリが実際に何をするかがわかる4つの場所。';

  @override
  String get demoTourSkip => 'スキップ';

  @override
  String get demoTourStarRepo => 'GitHubでスター';

  @override
  String get demoTourOpen => '開く';

  @override
  String get demoTourSpacesTitle => 'エージェントに話しかける';

  @override
  String get demoTourSpacesBody =>
      'スペースでメッセージを送ると、実行のストリーミングが見られます — 思考、ツール呼び出し、コストが、実際の実行とまったく同じように描画されます。';

  @override
  String get demoTourReviewTitle => 'プルリクエストをレビュー';

  @override
  String get demoTourReviewBody =>
      '#412を開きましょう。インラインコメントを残すかレビューを送信すると、あなたの言葉がスレッドに書き込まれ、そのまま残ります。';

  @override
  String get demoTourTicketsTitle => '作業を追う';

  @override
  String get demoTourTicketsBody =>
      'チケット、todo、プランは、エージェントが交わしているのと同じ会話に紐付いています。';

  @override
  String get demoTourInboxTitle => '運用全体を見る';

  @override
  String get demoTourInboxBody =>
      'すべての機能からのあらゆる通知が1つの受信トレイに届きます — レビュー、チケット、実行、会議。';

  @override
  String get demoUnavailableTitle => 'デモでは利用できません';

  @override
  String get demoUnavailableTerminal =>
      'ターミナルは、サーバーホスト上で本物のシェルを動かします。デモには実行面がまったくありません — だからこそ、一般公開しても安全なのです。';

  @override
  String get demoUnavailableRig =>
      'エンクロージャは、エージェントが操作する使い捨ての仮想マシンです。デモは1台も起動しません。VMを起動できる公開エンドポイントはデモではありません。';

  @override
  String get demoUnavailableEditor =>
      'ブラウザ内エディタは、実際のチェックアウトに対してcode-serverプロセスを実行します。デモにはそのどちらもありません。';

  @override
  String get demoUnavailableFeeds =>
      'デモは実際のフィードを読み取りますが、購読リストは固定です。追加や削除はここでは無効です。';

  @override
  String get demoUnavailableForge =>
      'デモは認証情報を保持せず、GitHub、GitLab、Linearには一切接続しません。プルリクエストはフィクスチャで、コメントはローカルに保存されます。';

  @override
  String get demoUnavailableModels =>
      'デモはモデルを呼び出しません。エージェントの実行はスクリプトによる再生なので、コストもかからず、プロバイダーにも届きません。';

  @override
  String get demoUnavailableMcp => 'MCPツール面はデモにマウントされていないため、外部クライアントは接続できません。';

  @override
  String get demoUnavailableRepos =>
      'デモはコードをチェックアウトせず、gitも実行しません。表示されるリポジトリは、プルリクエストの背後にあるフィクスチャです。';

  @override
  String get demoUnavailableSkills =>
      'スキルのインストールは、コードをダウンロードしてスキャンします。デモは何も取得しません。';

  @override
  String get demoUnavailableSso =>
      'シングルサインオンはサーバー設定です。デモでは代わりに一時ゲストとしてサインインします。';

  @override
  String get demoUnavailableAudio =>
      '録音とディクテーションには、ホスト上のオーディオキャプチャと音声モデルが必要です。デモにはどちらもないため、会議は再生のない文字起こしになります。';

  @override
  String get demoUnavailableServerAdmin =>
      'これはサーバー管理です。デモは各訪問者に使い捨てのワークスペースだけを与え、それ以上は何もありません。';

  @override
  String get settingsBackupRestore => 'バックアップと復元';

  @override
  String get settingsBackupRestoreDescription =>
      'このサーバー上の全データベースのスナップショットと、単一ワークスペースのエクスポート・インポート・削除です。';

  @override
  String get backupSnapshotsLabel => 'インストール全体のスナップショット';

  @override
  String get backupSnapshotsExplainer =>
      'スナップショットは、すべてのデータベースをサーバーホスト上のタイムスタンプ付きフォルダーへコピーします。インストール全体の復元は、サーバーを停止してそのフォルダーを書き戻すことになります。単一ワークスペースならここから復元できます。';

  @override
  String get backupNowAction => '今すぐバックアップ';

  @override
  String backupSnapshotWritten(String path) {
    return 'スナップショットを$pathに書き込みました';
  }

  @override
  String get backupNoSnapshots =>
      'スナップショットはまだありません。要求したときにのみ作成されます — 何もスケジュールされていません。';

  @override
  String get backupSnapshotComplete => '完了';

  @override
  String get backupSnapshotIncomplete => '不完全';

  @override
  String get backupSnapshotIncompleteNote =>
      'マニフェストがないか、存在しないファイルを参照しているため、このスナップショットでインストール全体を復元することはできません。含まれているワークスペースファイルは、1つずつなら取り込めます。';

  @override
  String backupSnapshotWorkspaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countワークスペース',
      one: '1ワークスペース',
      zero: 'ワークスペースなし',
    );
    return '$_temp0';
  }

  @override
  String backupSnapshotSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countワークスペースを取得せず',
      one: '1ワークスペースを取得せず',
    );
    return '$_temp0';
  }

  @override
  String get backupServerPathLabel => 'サーバー上のパス';

  @override
  String get backupRestoreAction => '復元';

  @override
  String get backupRestoreTitle => 'ワークスペースを復元';

  @override
  String backupRestoreBody(String name) {
    return '$nameの中身すべてを、このスナップショットが保持するコピーで置き換えます。スナップショット取得以降にそのワークスペースで行われたことはすべて失われ、取り消せません。';
  }

  @override
  String backupRestoreDone(String name) {
    return '$nameをスナップショットから復元しました。';
  }

  @override
  String get backupWorkspaceUnknown => 'このサーバーにはもう存在しません';

  @override
  String get backupWorkspaceDataLabel => 'ワークスペースデータ';

  @override
  String get backupWorkspaceDataExplainer =>
      '1ワークスペースは1つのデータベースファイルなので、エクスポートはテーブルごとのダンプではなく、そのファイルをコピーします。インポートは、指定したファイルで対象ワークスペースの中身すべてを置き換えます。';

  @override
  String get backupExportAction => 'エクスポート';

  @override
  String backupExportDone(String path) {
    return '$pathにエクスポートしました';
  }

  @override
  String get backupExportedFileLabel => 'サーバー上のエクスポート済みファイル';

  @override
  String get backupImportAction => 'インポート';

  @override
  String backupImportTitle(String name) {
    return '$nameへインポート';
  }

  @override
  String backupImportBody(String name) {
    return '$nameの中身すべてをファイルの内容で置き換えます。そのワークスペースが現在保持しているものはすべて失われ、取り消せません。';
  }

  @override
  String get backupImportSourceLabel => 'ワークスペースのデータベースファイル';

  @override
  String get backupImportSourceDescription =>
      'サーバーが読み取れる.dbファイル。パスはこのデバイスではなく、サーバーホスト上で解決されます。';

  @override
  String backupImportDone(String name) {
    return '$nameにインポートしました。';
  }

  @override
  String backupDeleteBody(String name) {
    return '$nameはすべての一覧と検索から消えます。データベースファイルはディスクに残り、バックアップにも含まれ続け、容量が自動的に回収されることはありません。';
  }

  @override
  String get backupExportDescription => 'サーバーにコピーを書き込むか、このデバイスへダウンロードします。';

  @override
  String get backupExportOnServerAction => 'サーバーに保存';

  @override
  String get backupDownloadAction => 'ダウンロード';

  @override
  String backupDownloadSaved(String path) {
    return '$pathに保存しました';
  }

  @override
  String get backupDownloadInBrowser => 'ブラウザがダウンロードしています。';

  @override
  String get backupRestoreFromDeviceLabel => 'このデバイスから復元';

  @override
  String get backupRestoreFromDeviceDescription =>
      'ここでワークスペースのデータベースファイルを選ぶと、Control Centerがそれをサーバーへアップロードします。サーバーがこのマシンでないときに機能する方法です。';

  @override
  String get backupUploadAction => 'ファイルを選んでアップロード';

  @override
  String get backupTransferUnavailable =>
      'この接続はリレー経由でサーバーに到達しているため、ファイル転送は行えません。バックアップのダウンロードやアップロードには、サーバーへ直接接続してください。';

  @override
  String get backupTransferForbidden =>
      'サーバーに拒否されました。ワークスペースのダウンロードには管理者ロール、復元にはオーナー、スナップショット全体にはインストールのオペレーターが必要です。';

  @override
  String get backupTransferUnsupported => 'このサーバーにはバックアップの仕組みがありません。';

  @override
  String get backupTransferTooLarge => 'ファイルがサーバーの受け入れ可能なサイズを超えています。';

  @override
  String get credentialGateWaitingTitle => '資格情報を待機中';

  @override
  String credentialGateHarnessTitle(String provider) {
    return '$providerに資格情報がありません';
  }

  @override
  String get credentialGateSignedOutTitle => 'Claude Codeはサインアウトしています';

  @override
  String get credentialGateExpiredTitle => 'Claude Codeのサインインの有効期限が切れました';

  @override
  String get credentialGatePlanSpentTitle => 'Claude Codeのプラン上限に達しました';

  @override
  String credentialGateWaitingAgent(String agent) {
    return '$agentが続行を待っています。';
  }

  @override
  String get credentialGateWaitingRun => '実行が続行を待っています。';

  @override
  String get credentialGateWatching => '修正を監視しています — 実行は自動的に続行されます。';

  @override
  String credentialGateFreesUpAt(String time) {
    return '$timeに回復します';
  }

  @override
  String credentialGateGivesUpAt(String time) {
    return '実行は$timeに諦めます';
  }

  @override
  String get credentialGateCheckAgain => '再確認';

  @override
  String get credentialGateCancelRun => '実行をキャンセル';

  @override
  String get credentialGateAccountsTried => '試したアカウント';

  @override
  String get credentialGateClaudeSignInHint =>
      '設定 → アダプター → Claude Codeからサインインするか、ターミナルでログインコマンドを実行してください。実行は自動的にそれを検出します。';

  @override
  String get credentialGateOpenSettings => '設定を開く';

  @override
  String get selectModel => 'モデルを選択';

  @override
  String get allModels => 'すべてのモデル';

  @override
  String get noModelsMatchSearch => '検索に一致するモデルがありません';

  @override
  String useCustomModelId(String id) {
    return '「$id」を使用';
  }

  @override
  String get modelFree => '無料';

  @override
  String modelOutputTokens(String tokens) {
    return '出力 $tokens';
  }

  @override
  String modelPricePerMTokens(String input, String output) {
    return '100万トークンあたり入力 $input / 出力 $output';
  }

  @override
  String modelEffortLevels(String levels) {
    return '推論の程度: $levels';
  }

  @override
  String get modelSupportsReasoning => '推論の程度に対応';

  @override
  String get profileDeliveryMetrics => 'デリバリーメトリクス';

  @override
  String profileMetricsSample(int count) {
    return '分析したPR：$count';
  }

  @override
  String get profileMergeRate => 'マージ率';

  @override
  String get profileReviewCoverage => 'レビュー網羅率';

  @override
  String get profilePrSize => 'PRサイズ';

  @override
  String get profileTimeToMerge => 'マージまでの時間';

  @override
  String get profileMergeTimeTrend => 'マージ時間の推移';

  @override
  String get profileWeeklyMedian => '週次中央値、対数スケール';

  @override
  String get profilePrOpeningPattern => '曜日 × 時間、現地時間';

  @override
  String get profileFirstReview => '初回レビューまでの時間';

  @override
  String get profileMetricsTruncated =>
      'パーセンタイル値は、利用可能なプルリクエストの限られたサンプルに基づいています。';

  @override
  String profileLinesChanged(String count) {
    return '$count行';
  }

  @override
  String profileDurationMinutes(int count) {
    return '$count分';
  }

  @override
  String profileDurationHours(int count) {
    return '$count時間';
  }

  @override
  String profileDurationDaysHours(int days, int hours) {
    return '$days日 $hours時間';
  }

  @override
  String profilePercentiles(String median, String p90) {
    return 'p50 $median · p90 $p90';
  }

  @override
  String profileTeamMembers(int count) {
    return 'メンバー：$count';
  }

  @override
  String noPrsByTeamInWorkspace(String team) {
    return 'このワークスペースには$teamによるプルリクエストがありません';
  }

  @override
  String get profilePrStateFilterLabel => 'プルリクエストを状態で絞り込む';

  @override
  String get noProfilePrsMatchSearchHint => '別のタイトルまたはプルリクエスト番号をお試しください';

  @override
  String get rigNetworkUnrestricted => 'ネットワークの制限なし';

  @override
  String get rigNetworkAllowAllHosts => 'すべてのホストを許可';

  @override
  String get rigNetworkBypassTitle => 'すべてのネットワークホストを許可しますか？';

  @override
  String get rigNetworkBypassBody =>
      '隔離環境を再起動し、その内部にある未コミットの作業を破棄します。その後、ゲストは閉じられるまで、すべてのネットワークホストに接続できるようになります。';

  @override
  String get rigNetworkRestartUnrestricted => '制限なしで再起動';

  @override
  String get rigNetworkUnrestrictedBody =>
      'この隔離環境はすべてのネットワークホストに接続できます。既定の制限に戻すには、閉じて新しい環境を開いてください。';

  @override
  String get rigNetworkAlreadyUnrestrictedBody =>
      'この Android エミュレーターはすでに独自のネットワークを管理しているため、Control Center はホストごとの許可リストを適用できません。再起動は不要です。';

  @override
  String get rigClipboardPermissionHostToRigTitle => 'クリップボードをこの環境に貼り付けますか？';

  @override
  String get rigClipboardPermissionHostToRigBody =>
      'Control Center はデバイスのクリップボードを読み取り、その内容を環境に送信します。クリップボードの内容にはパスワードやその他の機密情報が含まれている場合があります。';

  @override
  String get rigClipboardPermissionRigToHostTitle => 'この環境からクリップボードをコピーしますか？';

  @override
  String get rigClipboardPermissionRigToHostBody =>
      'Control Center は環境のクリップボードを読み取り、その内容でデバイスのクリップボードを置き換えます。環境からの内容は信頼できないものとして扱ってください。';

  @override
  String get rigClipboardAllowTenMinutes => '10分間許可';

  @override
  String get rigClipboardAlwaysAllow => '常に許可';

  @override
  String get rigClipboardSettingsTitle => 'クリップボードアクセス';

  @override
  String get rigClipboardSettingsHint =>
      '確認なしで実行できるクリップボード転送を選択します。一時的な権限は10分後に期限切れになります。';

  @override
  String get rigClipboardAlwaysPasteTitle => '環境への貼り付けを常に許可';

  @override
  String get rigClipboardAlwaysPasteDescription =>
      'このデバイスのクリップボードを確認なしで任意の環境に送信します。';

  @override
  String get rigClipboardAlwaysCopyTitle => '環境からのコピーを常に許可';

  @override
  String get rigClipboardAlwaysCopyDescription =>
      '任意の環境からのクリップボード内容を確認なしでこのデバイスに配置します。';
}
