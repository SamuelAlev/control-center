// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => '返回';

  @override
  String get cancel => '取消';

  @override
  String get retry => '重试';

  @override
  String get tryAgain => '再试一次';

  @override
  String get settings => '设置';

  @override
  String get refresh => '刷新';

  @override
  String get approve => '批准';

  @override
  String get deny => '拒绝';

  @override
  String get continueLabel => '继续';

  @override
  String get agentQuestionHeader => '需要你回答的问题';

  @override
  String get agentQuestionAnsweredLabel => '已回答';

  @override
  String get agentQuestionSkip => '跳过';

  @override
  String get agentQuestionSkippedLabel => '已跳过';

  @override
  String get agentQuestionFreeformHint => '输入你的回答…';

  @override
  String get agentApprovalRequired => '需要批准';

  @override
  String get approveAndRemember => '批准 8 小时';

  @override
  String get decline => '拒绝';

  @override
  String get confirm => '确认';

  @override
  String get send => '发送';

  @override
  String get close => '关闭';

  @override
  String get expand => '展开';

  @override
  String get zoomIn => '放大';

  @override
  String get zoomOut => '缩小';

  @override
  String get resetZoom => '重置缩放';

  @override
  String get scanQrPrompt => '扫描 Mac 上的 QR 码以配对此手机。';

  @override
  String get scanQrHelp =>
      '打开相机，对准 Mac 上 Control Center 显示的 QR 码。此手机会通过私有链路直接连接到你的 Mac。';

  @override
  String get connectingToMac => '正在连接到你的 Mac…';

  @override
  String get connectingDetail => '正在建立安全的直连链路。';

  @override
  String get identityChangedTitle => '服务器身份已更改';

  @override
  String get identityChangedBody =>
      '此服务器与配对时保存的身份不再匹配。这可能意味着服务器已重装，或有人在拦截连接。为安全起见，此设备将不会连接。请移除配对，然后扫描 Mac 上的新 QR 码重新配对。';

  @override
  String get removePairing => '移除配对';

  @override
  String get couldntConnect => '无法连接';

  @override
  String get pendingPairingTitle => '要连接到此服务器吗？';

  @override
  String get pendingPairingBody => '有链接请求 Control Center 与此服务器配对。请仅在你亲自发起时继续。';

  @override
  String get connect => '连接';

  @override
  String get failureNotPaired => '未配对 — 请扫描 Mac 上的 QR 码';

  @override
  String get failureUnreachable => '无法通过任何路径访问你的服务器 — 请确认它正在运行，或尝试同一网络';

  @override
  String get failureIdentityChanged => '服务器身份已更改 — 如果已重装，请重新配对此设备';

  @override
  String get failureAuthRejected => '服务器拒绝了此设备 — 请从 Mac 重新配对';

  @override
  String get failureUnknown => '无法连接 — 点按重试';

  @override
  String get statusConnected => '已连接';

  @override
  String get statusConnecting => '正在连接';

  @override
  String get statusOffline => '离线';

  @override
  String get statusIdentityMismatch => '身份不匹配';

  @override
  String get statusNotPaired => '未配对';

  @override
  String get statusConfirmPairing => '确认配对';

  @override
  String get connectionFailed => '连接失败';

  @override
  String get identityMismatchBanner => '服务器身份已更改 — 连接已停止。请重新配对此设备以继续。';

  @override
  String get tabInbox => '收件箱';

  @override
  String get tabTickets => '工单';

  @override
  String get tabChat => '聊天';

  @override
  String get tabPrs => 'PRs';

  @override
  String get tabCalendar => '日历';

  @override
  String get tabNews => '新闻';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label，$count 项待处理';
  }

  @override
  String get updateAvailable => '有新的 Control Center 可用';

  @override
  String get appearance => '外观';

  @override
  String get language => '语言';

  @override
  String get device => '设备';

  @override
  String get themeSystem => '系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get languageSystem => '系统';

  @override
  String get disconnectTapAgain => '再次点按以断开此设备与 Mac 的连接';

  @override
  String get disconnectDevice => '断开此设备';

  @override
  String get disconnect => '断开连接';

  @override
  String get chooseWorkspace => '选择工作区';

  @override
  String get workspaces => '工作区';

  @override
  String get workspacesLoadFailed => '无法加载工作区';

  @override
  String get noWorkspacesYet => '暂无工作区';

  @override
  String selectWorkspace(String name) {
    return '选择 $name';
  }

  @override
  String get inboxLoadFailed => '无法加载收件箱';

  @override
  String get allCaughtUp => '你已全部看完';

  @override
  String get inboxNoForgeAccount => '服务器上未连接 forge 账户，因此还无法将拉取请求归属到你。';

  @override
  String get inboxNothingWaiting => '没有事项被阻塞，也没有拉取请求在等待你处理。';

  @override
  String get blocked => '已阻塞';

  @override
  String get sectionNeedsYourReview => '需要你审核';

  @override
  String get sectionReturnedToYou => '已退回给你';

  @override
  String get sectionApprovedAndReady => '已批准且就绪';

  @override
  String get sectionYourDrafts => '你的草稿';

  @override
  String get sectionWaitingForReviewers => '等待审核人';

  @override
  String get sectionMergingAndMerged => '正在合并及最近已合并';

  @override
  String get sectionWaitingForAuthor => '等待作者';

  @override
  String waitingAgo(String ago) {
    return '已等待 $ago';
  }

  @override
  String get openConversation => '打开对话';

  @override
  String get calendarLoadFailed => '无法加载日历';

  @override
  String get nothingScheduled => '暂无日程';

  @override
  String get calendarEmptyDescription => '已连接日历中的活动会显示在这里。';

  @override
  String get agenda => '议程';

  @override
  String get syncCalendarsNow => '立即同步日历';

  @override
  String get event => '活动';

  @override
  String get eventNotFound => '未找到活动';

  @override
  String get eventNotFoundDescription => '它可能不在议程时间范围内，或已在上游被移除。';

  @override
  String get joinMeeting => '加入会议';

  @override
  String get join => '加入';

  @override
  String attendeesCount(int count) {
    return '参会者（$count）';
  }

  @override
  String get details => '详情';

  @override
  String get allDay => '全天';

  @override
  String get happeningNow => '正在进行';

  @override
  String inDuration(String duration) {
    return '$duration后';
  }

  @override
  String eventTimeRange(String start, String end, String duration) {
    return '$start – $end · $duration';
  }

  @override
  String upNextSemantic(String lead, String title) {
    return '$lead：$title';
  }

  @override
  String get attendeeAccepted => '已接受';

  @override
  String get attendeeDeclined => '已拒绝';

  @override
  String get attendeeMaybe => '待定';

  @override
  String get attendeeNoReply => '未回复';

  @override
  String get organizer => '组织者';

  @override
  String get calendarNoAccounts => '此工作区未连接日历。请从桌面应用连接 — 登录会将令牌存储在服务器上。';

  @override
  String get calendarReauthNeeded => '有日历账户需要重新连接 — 下方内容可能已过期。请从桌面应用重新连接。';

  @override
  String get spacesLoadFailed => '无法加载空间';

  @override
  String get noSpaces => '暂无空间';

  @override
  String get spacesEmptyDescription => '此工作区中的空间会显示在这里。';

  @override
  String get thread => '话题';

  @override
  String get agentWorking => 'Agent 正在工作';

  @override
  String get messagesLoadFailed => '无法加载消息';

  @override
  String get noMessagesYet => '暂无消息';

  @override
  String get noMessagesDescription => '发送一条消息以开始对话。';

  @override
  String get agentResponding => '智能体正在回复';

  @override
  String get agentFinished => '智能体已完成';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names 太大，无法从此处发送。',
      one: '$names 太大，无法从此处发送。',
    );
    return '$_temp0';
  }

  @override
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names 太大，无法从此处通过中继发送。',
      one: '$names 太大，无法从此处通过中继发送。',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed => '无法上传附件。请重试。';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 个附件无法上传，已排除。',
      one: '有 1 个附件无法上传，已排除。',
    );
    return '$_temp0';
  }

  @override
  String get teammate => '队友';

  @override
  String get agent => '智能体';

  @override
  String get attachFile => '附加文件';

  @override
  String get messageHint => '消息';

  @override
  String removeAttachment(String name) {
    return '移除 $name';
  }

  @override
  String get articlesLoadFailed => '无法加载文章';

  @override
  String get noArticles => '暂无文章';

  @override
  String get articlesEmptyDescription => '订阅源更新时，新文章会显示在此处。';

  @override
  String get unread => '未读';

  @override
  String get allFeeds => '全部订阅源';

  @override
  String get save => '保存';

  @override
  String get unsave => '取消保存';

  @override
  String get readFullArticle => '阅读全文';

  @override
  String get ticketsLoadFailed => '无法加载工单';

  @override
  String get noTickets => '暂无工单';

  @override
  String get ticketsEmptyDescription => '此工作区中的工单会显示在此处。';

  @override
  String get all => '全部';

  @override
  String get ticket => '工单';

  @override
  String get ticketLoadFailed => '无法加载工单';

  @override
  String assignedTo(String name) {
    return '已分配给 $name';
  }

  @override
  String get openInBrowser => '在浏览器中打开';

  @override
  String get status => '状态';

  @override
  String get assign => '分配';

  @override
  String get reassign => '重新分配';

  @override
  String get noAgents => '暂无智能体';

  @override
  String get noAgentsDescription => '从此工作区中分配一位座席。';

  @override
  String get statusOpen => '待处理';

  @override
  String get statusInProgress => '进行中';

  @override
  String get statusBlocked => '已阻塞';

  @override
  String get statusInReview => '审核中';

  @override
  String get statusDone => '已完成';

  @override
  String get statusBacklog => '待办';

  @override
  String get lensNeedsMe => '需要我处理';

  @override
  String get lensMine => '我的';

  @override
  String get prsLoadFailed => '无法加载拉取请求';

  @override
  String get noOpenPullRequests => '没有打开的 pull request';

  @override
  String get nothingWaitingOnReview => '暂无等待你审核的内容';

  @override
  String get noOwnOpenPullRequests => '你没有未关闭的拉取请求';

  @override
  String get nothingBlocked => '暂无已阻塞项';

  @override
  String get prsEmptyDescription => '此工作区各仓库中的拉取请求会显示在此处。';

  @override
  String get refreshPullRequests => '刷新拉取请求';

  @override
  String get noForgeConnected => '服务器上未连接 forge，因此无法获取拉取请求。请从桌面应用连接。';

  @override
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 个仓库无法读取。',
      one: '有 1 个仓库无法读取。',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return '无法读取：$names';
  }

  @override
  String get installationSuspendedTitle => 'GitHub App 安装已被暂停';

  @override
  String installationSuspendedBody(String names) {
    return '正在显示 $names 的上次已知数据。请在 GitHub 上恢复安装，或连接具有访问权限的令牌。';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'GitHub App 安装已被暂停。正在显示 $names 的上次已知数据。请在 GitHub 上恢复安装，或连接具有访问权限的令牌。';
  }

  @override
  String get draft => '草稿';

  @override
  String get merged => '已合并';

  @override
  String get closed => '已关闭';

  @override
  String get open => '打开';

  @override
  String get approved => '已批准';

  @override
  String get changesRequested => '已请求变更';

  @override
  String get reviewRequired => '需要审核';

  @override
  String get checksPassing => '检查已通过';

  @override
  String get checksFailing => '检查未通过';

  @override
  String get checksRunning => '检查运行中';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title，$status';
  }

  @override
  String get pullRequest => '拉取请求';

  @override
  String get prLoadFailed => '无法加载此拉取请求';

  @override
  String get openOnForge => '在 forge 上打开';

  @override
  String get requestChangesNeedsComment => '添加评论，说明需要修改的内容。';

  @override
  String get conversation => '对话';

  @override
  String get files => '文件';

  @override
  String get checks => '检查';

  @override
  String labelWithCount(String label, int count) {
    return '$label（$count）';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个文件',
      one: '1 个文件',
    );
    return '$_temp0';
  }

  @override
  String commitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 次提交',
      one: '1 次提交',
    );
    return '$_temp0';
  }

  @override
  String get conflicts => '冲突';

  @override
  String get reviewers => '评审者';

  @override
  String get noDescriptionNoComments => '尚无描述和评论。';

  @override
  String get noChangedFiles => '没有变更的文件。';

  @override
  String get noChecksReported => '头提交没有报告检查结果。';

  @override
  String get reviewCommentHint => '留下审查评论…';

  @override
  String get comment => '评论';

  @override
  String get commentPosted => '评论已发布';

  @override
  String get request => '请求';

  @override
  String get squashAndMerge => '压缩并合并';

  @override
  String noActionsAvailable(String status) {
    return '$status — 没有可用操作。';
  }

  @override
  String get reviewApproved => '已批准';

  @override
  String get reviewRequestedChanges => '请求更改';

  @override
  String get reviewCommented => '已审核';

  @override
  String get reviewPending => '待处理';

  @override
  String get unknownAuthor => '未知';

  @override
  String hideDiffFor(String file) {
    return '隐藏 $file 的差异';
  }

  @override
  String showDiffFor(String file) {
    return '显示 $file 的差异';
  }

  @override
  String get checkRunning => '运行中';

  @override
  String get checkPassed => '已通过';

  @override
  String get checkFailed => '失败';

  @override
  String get checkCancelled => '已取消';

  @override
  String get checkSkipped => '已跳过';

  @override
  String labelWithDuration(String label, String duration) {
    return '$label · $duration';
  }

  @override
  String checkSemanticLabel(String name, String state) {
    return '$name，$state';
  }

  @override
  String get noTextDiff => '此文件没有文本差异 — 它是二进制文件，或过大导致 forge 无法返回差异。';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '显示剩余的 $count 行',
      one: '显示剩余行',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 行未更改',
      one: '1 行未更改',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => '跳到最新';

  @override
  String get streaming => '流式输出';

  @override
  String get working => '工作中';

  @override
  String get input => '输入';

  @override
  String get output => '输出';

  @override
  String get now => '现在';

  @override
  String agoMinutes(int count) {
    return '$count 分钟前';
  }

  @override
  String agoHours(int count) {
    return '$count 小时前';
  }

  @override
  String agoDays(int count) {
    return '$count 天前';
  }

  @override
  String get today => '今天';

  @override
  String get tomorrow => '明天';

  @override
  String get yesterday => '昨天';

  @override
  String durationMinutes(int count) {
    return '$count 分钟';
  }

  @override
  String durationHours(int count) {
    return '$count 小时';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours 小时 $minutes 分钟';
  }
}

/// The translations for Chinese, as used in Hong Kong (`zh_HK`).
class AppLocalizationsZhHk extends AppLocalizationsZh {
  AppLocalizationsZhHk() : super('zh_HK');

  @override
  String get failureUnreachable => '無法透過任何路徑連到你的伺服器 — 請確認伺服器正在執行，或改用相同網絡再試';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => '返回';

  @override
  String get cancel => '取消';

  @override
  String get retry => '重試';

  @override
  String get tryAgain => '再試一次';

  @override
  String get settings => '設定';

  @override
  String get refresh => '重新整理';

  @override
  String get approve => '核准';

  @override
  String get deny => '拒絕';

  @override
  String get continueLabel => '繼續';

  @override
  String get agentQuestionHeader => '給你的問題';

  @override
  String get agentQuestionAnsweredLabel => '已回答';

  @override
  String get agentQuestionSkip => '略過';

  @override
  String get agentQuestionSkippedLabel => '已略過';

  @override
  String get agentQuestionFreeformHint => '輸入你的答案…';

  @override
  String get agentApprovalRequired => '需要核准';

  @override
  String get approveAndRemember => '核准 8 小時';

  @override
  String get decline => '拒絕';

  @override
  String get confirm => '確認';

  @override
  String get send => '傳送';

  @override
  String get close => '關閉';

  @override
  String get expand => '展開';

  @override
  String get zoomIn => '放大';

  @override
  String get zoomOut => '縮小';

  @override
  String get resetZoom => '重設縮放';

  @override
  String get scanQrPrompt => '掃描 Mac 上的 QR code，以配對此手機。';

  @override
  String get scanQrHelp =>
      '開啟相機，對準 Mac 上 Control Center 顯示的 QR。此手機會透過私人連線直接連到你的 Mac。';

  @override
  String get connectingToMac => '正在連線到你的 Mac…';

  @override
  String get connectingDetail => '正在建立安全的直接連線。';

  @override
  String get identityChangedTitle => '伺服器身分已變更';

  @override
  String get identityChangedBody =>
      '此伺服器與配對時儲存的身分不符。這可能表示伺服器已重新安裝，或連線遭到攔截。為了安全起見，此裝置將不會連線。請移除配對，然後從 Mac 掃描新的 QR code 再次配對。';

  @override
  String get removePairing => '移除配對';

  @override
  String get couldntConnect => '無法連線';

  @override
  String get pendingPairingTitle => '要連線到此伺服器嗎？';

  @override
  String get pendingPairingBody =>
      '有連結要求 Control Center 與此伺服器配對。請確認是你本人發起後再繼續。';

  @override
  String get connect => '連線';

  @override
  String get failureNotPaired => '尚未配對 — 請掃描 Mac 上的 QR code';

  @override
  String get failureUnreachable => '無法透過任何路徑連到你的伺服器 — 請確認伺服器正在執行，或改用相同網路再試';

  @override
  String get failureIdentityChanged => '伺服器身分已變更 — 若已重新安裝，請重新配對此裝置';

  @override
  String get failureAuthRejected => '伺服器已拒絕此裝置 — 請從 Mac 重新配對';

  @override
  String get failureUnknown => '無法連線 — 點一下即可重試';

  @override
  String get statusConnected => '已連線';

  @override
  String get statusConnecting => '連線中';

  @override
  String get statusOffline => '離線';

  @override
  String get statusIdentityMismatch => '身分不符';

  @override
  String get statusNotPaired => '尚未配對';

  @override
  String get statusConfirmPairing => '確認配對';

  @override
  String get connectionFailed => '連線失敗';

  @override
  String get identityMismatchBanner => '伺服器身分已變更 — 連線已停止。請重新配對此裝置以繼續。';

  @override
  String get tabInbox => '收件匣';

  @override
  String get tabTickets => '工單';

  @override
  String get tabChat => '聊天';

  @override
  String get tabPrs => 'PRs';

  @override
  String get tabCalendar => '行事曆';

  @override
  String get tabNews => '新聞';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label，$count 項等待中';
  }

  @override
  String get updateAvailable => '有新的 Control Center 可供使用';

  @override
  String get appearance => '外觀';

  @override
  String get language => '語言';

  @override
  String get device => '裝置';

  @override
  String get themeSystem => '系統';

  @override
  String get themeLight => '淺色';

  @override
  String get themeDark => '深色';

  @override
  String get languageSystem => '系統';

  @override
  String get disconnectTapAgain => '再點一次即可將此裝置從 Mac 中斷連線';

  @override
  String get disconnectDevice => '中斷此裝置連線';

  @override
  String get disconnect => '中斷連線';

  @override
  String get chooseWorkspace => '選擇工作區';

  @override
  String get workspaces => '工作區';

  @override
  String get workspacesLoadFailed => '無法載入工作區';

  @override
  String get noWorkspacesYet => '尚無工作區';

  @override
  String selectWorkspace(String name) {
    return '選擇 $name';
  }

  @override
  String get inboxLoadFailed => '無法載入你的收件匣';

  @override
  String get allCaughtUp => '你已全部讀完';

  @override
  String get inboxNoForgeAccount => '伺服器尚未連線 forge 帳戶，因此目前無法將拉取請求歸屬於你。';

  @override
  String get inboxNothingWaiting => '沒有任何事項被阻擋，也沒有拉取請求在等你處理。';

  @override
  String get blocked => '已封鎖';

  @override
  String get sectionNeedsYourReview => '需要你審核';

  @override
  String get sectionReturnedToYou => '已退回給你';

  @override
  String get sectionApprovedAndReady => '已核准且就緒';

  @override
  String get sectionYourDrafts => '你的草稿';

  @override
  String get sectionWaitingForReviewers => '等待審核者';

  @override
  String get sectionMergingAndMerged => '合併中與近期已合併';

  @override
  String get sectionWaitingForAuthor => '等待作者';

  @override
  String waitingAgo(String ago) {
    return '已等待 $ago';
  }

  @override
  String get openConversation => '開啟對話';

  @override
  String get calendarLoadFailed => '無法載入你的行事曆';

  @override
  String get nothingScheduled => '沒有行程';

  @override
  String get calendarEmptyDescription => '已連線行事曆中的活動會顯示於此。';

  @override
  String get agenda => '議程';

  @override
  String get syncCalendarsNow => '立即同步行事曆';

  @override
  String get event => '活動';

  @override
  String get eventNotFound => '找不到活動';

  @override
  String get eventNotFoundDescription => '可能已超出議程範圍，或已在來源端移除。';

  @override
  String get joinMeeting => '加入會議';

  @override
  String get join => '加入';

  @override
  String attendeesCount(int count) {
    return '與會者（$count）';
  }

  @override
  String get details => '詳細資料';

  @override
  String get allDay => '全天';

  @override
  String get happeningNow => '進行中';

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
    return '$lead：$title';
  }

  @override
  String get attendeeAccepted => '已接受';

  @override
  String get attendeeDeclined => '已拒絕';

  @override
  String get attendeeMaybe => '暫定';

  @override
  String get attendeeNoReply => '未回覆';

  @override
  String get organizer => '主辦人';

  @override
  String get calendarNoAccounts => '此工作區尚未連線行事曆。請從桌面應用程式連線 — 登入後權杖會儲存在伺服器上。';

  @override
  String get calendarReauthNeeded =>
      '有行事曆帳戶需要重新連線 — 下方內容可能不是最新狀態。請從桌面應用程式重新連線。';

  @override
  String get spacesLoadFailed => '無法載入空間';

  @override
  String get noSpaces => '沒有空間';

  @override
  String get spacesEmptyDescription => '此工作區中的空間會顯示於此。';

  @override
  String get thread => '討論串';

  @override
  String get agentWorking => 'Agent 正在處理';

  @override
  String get messagesLoadFailed => '無法載入訊息';

  @override
  String get noMessagesYet => '尚無訊息';

  @override
  String get noMessagesDescription => '傳送訊息以開始對話。';

  @override
  String get agentResponding => '代理回應中';

  @override
  String get agentFinished => '代理已完成';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names 過大，無法從此處傳送。',
      one: '$names 過大，無法從此處傳送。',
    );
    return '$_temp0';
  }

  @override
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names 過大，無法從這裡透過中繼傳送。',
      one: '$names 過大，無法從這裡透過中繼傳送。',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed => '無法上傳附件。請再試一次。';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 個附件無法上傳，已略過。',
      one: '有 1 個附件無法上傳，已略過。',
    );
    return '$_temp0';
  }

  @override
  String get teammate => '隊友';

  @override
  String get agent => '代理';

  @override
  String get attachFile => '附加檔案';

  @override
  String get messageHint => '訊息';

  @override
  String removeAttachment(String name) {
    return '移除 $name';
  }

  @override
  String get articlesLoadFailed => '無法載入文章';

  @override
  String get noArticles => '沒有文章';

  @override
  String get articlesEmptyDescription => '摘要更新時，新文章會顯示在這裡。';

  @override
  String get unread => '未讀';

  @override
  String get allFeeds => '所有摘要';

  @override
  String get save => '儲存';

  @override
  String get unsave => '取消儲存';

  @override
  String get readFullArticle => '閱讀完整文章';

  @override
  String get ticketsLoadFailed => '無法載入工單';

  @override
  String get noTickets => '沒有工單';

  @override
  String get ticketsEmptyDescription => '此工作區的工單會顯示在這裡。';

  @override
  String get all => '全部';

  @override
  String get ticket => '工單';

  @override
  String get ticketLoadFailed => '無法載入工單';

  @override
  String assignedTo(String name) {
    return '指派給 $name';
  }

  @override
  String get openInBrowser => '在瀏覽器中開啟';

  @override
  String get status => '狀態';

  @override
  String get assign => '指派';

  @override
  String get reassign => '重新指派';

  @override
  String get noAgents => '沒有代理';

  @override
  String get noAgentsDescription => '從此工作區指派代理。';

  @override
  String get statusOpen => '開啟';

  @override
  String get statusInProgress => '進行中';

  @override
  String get statusBlocked => '已封鎖';

  @override
  String get statusInReview => '審核中';

  @override
  String get statusDone => '完成';

  @override
  String get statusBacklog => '待辦';

  @override
  String get lensNeedsMe => '需要我處理';

  @override
  String get lensMine => '我的';

  @override
  String get prsLoadFailed => '無法載入提取要求';

  @override
  String get noOpenPullRequests => '沒有未結案的 pull request';

  @override
  String get nothingWaitingOnReview => '沒有等待你審查的項目';

  @override
  String get noOwnOpenPullRequests => '你沒有進行中的提取要求';

  @override
  String get nothingBlocked => '沒有已封鎖的項目';

  @override
  String get prsEmptyDescription => '此工作區各儲存庫的提取要求會顯示在這裡。';

  @override
  String get refreshPullRequests => '重新整理提取要求';

  @override
  String get noForgeConnected => '伺服器尚未連線任何 forge，因此無法擷取提取要求。請從桌面應用程式連線。';

  @override
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '無法讀取 $count 個儲存庫。',
      one: '無法讀取 1 個儲存庫。',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return '無法讀取：$names';
  }

  @override
  String get installationSuspendedTitle => 'GitHub App 安裝已暫停';

  @override
  String installationSuspendedBody(String names) {
    return '正在顯示 $names 的上次已知資料。請在 GitHub 上恢復安裝，或連線具有存取權限的權杖。';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'GitHub App 安裝已暫停。正在顯示 $names 的上次已知資料。請在 GitHub 上恢復安裝，或連線具有存取權限的權杖。';
  }

  @override
  String get draft => '草稿';

  @override
  String get merged => '已合併';

  @override
  String get closed => '已關閉';

  @override
  String get open => '開啟';

  @override
  String get approved => '已核准';

  @override
  String get changesRequested => '要求變更';

  @override
  String get reviewRequired => '需要審查';

  @override
  String get checksPassing => '檢查通過';

  @override
  String get checksFailing => '檢查失敗';

  @override
  String get checksRunning => '檢查執行中';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title，$status';
  }

  @override
  String get pullRequest => '提取要求';

  @override
  String get prLoadFailed => '無法載入此提取要求';

  @override
  String get openOnForge => '在 forge 上開啟';

  @override
  String get requestChangesNeedsComment => '請新增評論，說明需要變更的內容。';

  @override
  String get conversation => '對話';

  @override
  String get files => '檔案';

  @override
  String get checks => '檢查';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個檔案',
      one: '1 個檔案',
    );
    return '$_temp0';
  }

  @override
  String commitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個提交',
      one: '1 個提交',
    );
    return '$_temp0';
  }

  @override
  String get conflicts => '衝突';

  @override
  String get reviewers => '檢閱者';

  @override
  String get noDescriptionNoComments => '尚無說明，也還沒有評論。';

  @override
  String get noChangedFiles => '沒有變更的檔案。';

  @override
  String get noChecksReported => 'HEAD 提交沒有回報任何檢查。';

  @override
  String get reviewCommentHint => '留下審查評論…';

  @override
  String get comment => '評論';

  @override
  String get commentPosted => '已發佈評論';

  @override
  String get request => '請求';

  @override
  String get squashAndMerge => 'Squash 並合併';

  @override
  String noActionsAvailable(String status) {
    return '$status — 沒有可用動作。';
  }

  @override
  String get reviewApproved => '已核准';

  @override
  String get reviewRequestedChanges => '已要求變更';

  @override
  String get reviewCommented => '已審查';

  @override
  String get reviewPending => '待處理';

  @override
  String get unknownAuthor => '未知';

  @override
  String hideDiffFor(String file) {
    return '隱藏 $file 的差異';
  }

  @override
  String showDiffFor(String file) {
    return '顯示 $file 的差異';
  }

  @override
  String get checkRunning => '執行中';

  @override
  String get checkPassed => '通過';

  @override
  String get checkFailed => '失敗';

  @override
  String get checkCancelled => '已取消';

  @override
  String get checkSkipped => '已略過';

  @override
  String labelWithDuration(String label, String duration) {
    return '$label · $duration';
  }

  @override
  String checkSemanticLabel(String name, String state) {
    return '$name，$state';
  }

  @override
  String get noTextDiff => '此檔案沒有文字差異 — 可能是二進位檔，或檔案過大，forge 無法回傳差異。';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '顯示剩餘的 $count 行',
      one: '顯示剩餘的那一行',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 行未變更',
      one: '1 行未變更',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => '跳到最新';

  @override
  String get streaming => '串流中';

  @override
  String get working => '處理中';

  @override
  String get input => '輸入';

  @override
  String get output => '輸出';

  @override
  String get now => '現在';

  @override
  String agoMinutes(int count) {
    return '$count 分';
  }

  @override
  String agoHours(int count) {
    return '$count 時';
  }

  @override
  String agoDays(int count) {
    return '$count 天';
  }

  @override
  String get today => '今天';

  @override
  String get tomorrow => '明天';

  @override
  String get yesterday => '昨天';

  @override
  String durationMinutes(int count) {
    return '$count 分';
  }

  @override
  String durationHours(int count) {
    return '$count 時';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours 時 $minutes 分';
  }
}
