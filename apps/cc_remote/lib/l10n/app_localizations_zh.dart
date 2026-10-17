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
  String get copyCommand => '复制命令';

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
  String get scanQrPrompt => '扫描 Control Center 上的 QR 码以配对此手机。';

  @override
  String get scanQrHelp => '打开相机，对准 Control Center 显示的 QR 码。此手机通过私有链路直接连接。';

  @override
  String get connectingToMac => '正在连接到 Control Center…';

  @override
  String get connectingDetail => '正在建立安全的直连链路。';

  @override
  String get identityChangedTitle => '服务器身份已更改';

  @override
  String get identityChangedBody =>
      '此服务器与配对时保存的身份不再匹配。这可能意味着服务器已重装，或有人在拦截连接。为安全起见，此设备将不会连接。请移除配对，然后扫描 Control Center 上的新 QR 码重新配对。';

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
  String get failureNotPaired => '未配对 — 请扫描 Control Center 上的 QR 码';

  @override
  String get failureUnreachable => '无法通过任何路径访问你的服务器 — 请确认它正在运行，或尝试同一网络';

  @override
  String get failureIdentityChanged => '服务器身份已更改 — 如果已重装，请重新配对此设备';

  @override
  String get failureAuthRejected => '服务器拒绝了此设备 — 请从 Control Center 重新配对';

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
  String get disconnectTapAgain => '再次点按以断开此设备与 Control Center 的连接';

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
  String get newSpaceFolder => '新建文件夹';

  @override
  String get folderName => '文件夹名称';

  @override
  String get renameSpaceFolder => '重命名文件夹';

  @override
  String get deleteSpaceFolder => '删除文件夹';

  @override
  String get moveSpaceToFolder => '移至文件夹';

  @override
  String get removeSpaceFromFolder => '从文件夹移除';

  @override
  String get spaceFolderActions => '文件夹操作';

  @override
  String get deleteFolderWithSpacesWarning => '永久删除空间会为所有人移除其中的消息和工作树。此操作无法撤销。';

  @override
  String get deleteSpacesInFolder => '永久删除此文件夹中的空间';

  @override
  String get deleteFolderAndSpaces => '删除文件夹和空间';

  @override
  String get keepSpacesInFolder => '否则，空间将不属于任何文件夹。';

  @override
  String get create => '创建';

  @override
  String get otherSpaces => '其他空间';

  @override
  String get folderUpdateFailed => '无法更新文件夹';

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

  @override
  String get mobileConversations => '对话';

  @override
  String get mobileNewConversation => '新对话';

  @override
  String get mobileConversationName => '对话名称';

  @override
  String get mobileRename => '重命名';

  @override
  String get mobileManageSpace => '管理空间';

  @override
  String get mobileArchived => '已归档';

  @override
  String get mobileSearchMessages => '搜索此空间中的所有消息';

  @override
  String get mobileSearch => '搜索';

  @override
  String get mobileNoResults => '无结果';

  @override
  String get mobileReopen => '重新打开';

  @override
  String get mobileArchive => '归档';

  @override
  String get mobileProgress => '进度与上下文';

  @override
  String get mobileReadFailed => '无法将此对话标记为已读';

  @override
  String get mobileSendFailed => '消息未发送，草稿仍在此处。';

  @override
  String get mobileActionFailed => '操作失败';

  @override
  String get mobileRemove => '移除';

  @override
  String get mobileLinkedMessage => '关联消息';

  @override
  String get mobileOlderMessages => '更早的消息';

  @override
  String get mobileMessageActions => '消息操作';

  @override
  String get mobileOpenThread => '打开讨论串';

  @override
  String get mobileCopyLink => '复制链接';

  @override
  String get mobileStopRun => '停止运行';

  @override
  String get mobileStopRunConfirm => '停止此次智能体运行？已完成的工作会保留。';

  @override
  String get mobileControlUnsupported => '此次运行已结束或不支持此操作。';

  @override
  String get mobilePauseRequested => '已请求在下一轮结束时暂停';

  @override
  String get mobileResumed => '已继续运行';

  @override
  String get mobileStopRequested => '已请求停止';

  @override
  String get mobileQueuedMessages => '排队的消息';

  @override
  String get mobilePauseRun => '下一轮暂停';

  @override
  String get mobileResumeRun => '继续';

  @override
  String get mobileEditQueued => '编辑已排队的消息';

  @override
  String get mobileSteerNow => '立即引导';

  @override
  String get mobileMoveUp => '上移';

  @override
  String get mobileMoveDown => '下移';

  @override
  String get mobileQueueChanged => '队列已变化，或此次运行无法接受实时引导。请刷新后重试。';

  @override
  String get mobileActivity => '活动';

  @override
  String get mobilePermissions => '权限与审计';

  @override
  String get mobilePlans => '计划';

  @override
  String get mobileGoals => '监督目标';

  @override
  String get mobileCredentials => '连接与凭据';

  @override
  String get mobileWorkspaceUnavailable => '此工作区不可用，或你已无权访问。';

  @override
  String get mobilePrReviewThreads => '评审讨论串';

  @override
  String get mobilePrThreadsLoadFailed => '无法加载评审讨论串';

  @override
  String get mobilePrNoReviewThreads => '尚无行内评审讨论串';

  @override
  String get mobilePrCommentPermissionDenied => '你无权在此仓库发表评论。';

  @override
  String get mobilePrPermissionChecking => '正在检查评论权限…';

  @override
  String get mobilePrPermissionLoadFailed => '无法检查评论权限。请重试后发表评论。';

  @override
  String mobilePrThreadLine(String side, String line) {
    return '$side第 $line 行';
  }

  @override
  String get mobilePrOriginalSide => '原始版本';

  @override
  String get mobilePrUpdatedSide => '更新时间';

  @override
  String get mobilePrThreadResolved => '已解决';

  @override
  String get mobilePrReplyHint => '撰写回复…';

  @override
  String get mobilePrCommentRequired => '请先填写评论再发布。';

  @override
  String get mobilePrReply => '回复';

  @override
  String get mobilePrReopenThread => '重新打开讨论';

  @override
  String get mobilePrResolveThread => '解决讨论';

  @override
  String get mobilePrResolvePermissionDenied =>
      '只有 pull request 作者或拥有写入权限的人才能解决此讨论串。';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return '评论$side第 $line 行';
  }

  @override
  String get mobilePrInlineCommentHint => '撰写行内评论…';

  @override
  String get mobilePrPostInlineComment => '发布评论';

  @override
  String get mobilePrCommentUnavailable => '此 pull request 无法添加行内评论。';

  @override
  String get mobilePrPatchUnavailable => '代码托管服务未提供此文件的文本补丁。';

  @override
  String get mobilePrNoPatchForFile => '此文件的补丁不可用。';

  @override
  String get mobileTicketNew => '新建工单';

  @override
  String get mobileTicketCreate => '创建工单';

  @override
  String get mobileTicketEdit => '编辑工单';

  @override
  String get mobileTicketTitle => '标题';

  @override
  String get mobileTicketTitleRequired => '请输入标题以保存工单。';

  @override
  String get mobileTicketDescription => '描述';

  @override
  String get mobileTicketMarkdownHint => '使用 Markdown 添加详情';

  @override
  String get mobileTicketPriority => '优先级';

  @override
  String get mobileTicketPriorityNone => '无优先级';

  @override
  String get mobileTicketPriorityUrgent => '紧急';

  @override
  String get mobileTicketPriorityHigh => '高';

  @override
  String get mobileTicketPriorityMedium => '中';

  @override
  String get mobileTicketPriorityLow => '低';

  @override
  String get mobileTicketLabels => '标签';

  @override
  String get mobileTicketLabelsHint => '每行一个标签';

  @override
  String get mobileTicketLabelsHelp => '每个标签单独占一行。';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return '已提交至 $provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => '未分配';

  @override
  String get mobileTicketAssignedFilter => '已分配';

  @override
  String get mobileTicketAgentsLoadFailed => '无法加载智能体';

  @override
  String get mobileTicketSearch => '搜索工单';

  @override
  String get mobileTicketSearchHint => '标题、编号、描述、标签或负责人';

  @override
  String get mobileTicketClearSearch => '清除工单搜索';

  @override
  String get mobileTicketNoMatches => '没有匹配的工单';

  @override
  String get mobileTicketAdjustFilters => '请尝试其他搜索词或调整筛选条件。';

  @override
  String get mobileTicketClearFilters => '清除筛选';

  @override
  String get mobileTicketNotFound => '找不到工单';

  @override
  String get mobileTicketNotFoundDescription => '此工单可能已被删除或移出此工作区。';

  @override
  String get mobileTicketWorkspaceChanged => '工作区已变更。请返回当前工作区后再保存。';

  @override
  String get mobileTicketOpenLinkedSpace => '打开关联空间';

  @override
  String get mobileTicketReadOnly => '更改工单需要工作区成员权限。';

  @override
  String get permissionTitle => '权限';

  @override
  String get permissionWorkspaceFailed => '无法加载工作区';

  @override
  String get permissionNoWorkspace => '请选择工作区以查看权限。';

  @override
  String get permissionLoading => '正在加载权限…';

  @override
  String get permissionScopeDescription => '查看此范围内各项操作的判定方式。智能体和空间可继承工作区规则。';

  @override
  String get permissionScope => '策略范围';

  @override
  String get permissionWorkspaceScope => '工作区';

  @override
  String get permissionAgentScope => '智能体';

  @override
  String get permissionSpaceScope => '空间';

  @override
  String get permissionAgentContext => '在此空间中执行操作的智能体';

  @override
  String get permissionNoAgentContext => '未选择智能体';

  @override
  String get permissionTargetsFailed => '无法加载范围目标';

  @override
  String get permissionNoTargets => '此范围内没有可用目标。';

  @override
  String get permissionRoleFailed => '无法确认你的工作区角色';

  @override
  String get permissionMemberRequired => '查看策略规则需要工作区成员权限。';

  @override
  String get permissionRulesFailed => '无法加载策略规则';

  @override
  String get permissionAuditAdminOnly => '仅工作区管理员可查看授权记录。';

  @override
  String get permissionAllow => '允许';

  @override
  String get permissionAsk => '先询问';

  @override
  String get permissionDeny => '拒绝';

  @override
  String get permissionFileDelete => '删除文件';

  @override
  String get permissionFileWriteOutsideWorktree => '在工作树外写入';

  @override
  String get permissionGitCommit => '提交更改';

  @override
  String get permissionGitPush => '推送提交';

  @override
  String get permissionPrCreate => '创建 pull request';

  @override
  String get permissionPrPublish => '发布 pull request';

  @override
  String get permissionVendorSyncWrite => '写入供应商同步';

  @override
  String get permissionNetworkEgress => '访问网络';

  @override
  String get permissionSecretAccess => '访问机密信息';

  @override
  String get permissionPackageInstall => '安装软件包';

  @override
  String get permissionProcessSpawn => '启动进程';

  @override
  String get permissionWorkspaceMutation => '更改工作区';

  @override
  String get permissionEnclosureControl => '控制设备舱';

  @override
  String get permissionChangeFailed => '无法更改规则';

  @override
  String get permissionEffectiveDescription =>
      '在不指定操作参数时，此范围内的有效规则如下。下方的条件授权仅适用于匹配的请求；最终由服务器裁定。';

  @override
  String get permissionSpaceAgentNote => '未选择智能体。请在上方选择智能体，以查看专属规则。';

  @override
  String get permissionScopedGrants => '此范围内的规则';

  @override
  String get permissionModePreset => '模式预设';

  @override
  String get permissionBuiltInDefault => '内置默认值';

  @override
  String get permissionRemembered => '已记住的批准';

  @override
  String get permissionSource => '源码';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · 在此设置';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · 已继承';
  }

  @override
  String permissionExpiresAt(String date) {
    return '到期时间：$date';
  }

  @override
  String get permissionSetHere => '在此设置规则';

  @override
  String get permissionRevokeBeforeEdit => '请先撤销此范围内的规则或已记住的规则，再为此操作设置通用规则。';

  @override
  String get permissionConfirmRevoke => '确认撤销';

  @override
  String get permissionRevokeRule => '撤销规则';

  @override
  String permissionCommandPrefix(String prefix) {
    return '命令前缀：$prefix';
  }

  @override
  String get permissionNoExpiry => '永不过期';

  @override
  String get permissionExpired => '已过期';

  @override
  String get permissionExplicitRule => '明确规则';

  @override
  String get permissionEnforcementAdvisory => '建议执行：先询问规则仅记录日志，不弹出提示';

  @override
  String get permissionEnforcementSoft => '软性执行：覆盖规则需要授权';

  @override
  String get permissionEnforcementHard => '强制执行：无法覆盖规则';

  @override
  String permissionPaths(String paths) {
    return '路径：$paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'Git 引用：$refs';
  }

  @override
  String permissionHosts(String hosts) {
    return '主机：$hosts';
  }

  @override
  String permissionCommands(String commands) {
    return '命令：$commands';
  }

  @override
  String permissionMaxCount(String count) {
    return '最大数量：$count';
  }

  @override
  String permissionMaxCents(String cents) {
    return '最高美分数：$cents';
  }

  @override
  String get permissionAuditHeading => '授权记录';

  @override
  String get permissionAuditDescription => '服务器记录的近期决策。只有管理员可以查看日志或验证其哈希链。';

  @override
  String permissionOnBehalfOf(String user) {
    return '代表 $user';
  }

  @override
  String get permissionPrompted => '已请求人工批准';

  @override
  String get permissionVerifyChain => '验证审计链';

  @override
  String get permissionVerifyFailed => '无法验证审计链';

  @override
  String permissionChainIntact(String count) {
    return '链完整 · 已检查 $count 条记录';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return '链在第 $sequence 条记录处断裂：$reason';
  }

  @override
  String get permissionAuditEmpty => '尚无授权决策记录。';

  @override
  String get permissionAuditFailed => '无法加载授权记录';

  @override
  String get mobilePlansLoadFailed => '无法加载计划';

  @override
  String get mobilePlansEmpty => '暂无计划';

  @override
  String get mobilePlansEmptyDescription => '智能体提交的计划将在此显示，供你评审。';

  @override
  String get mobilePlanTitle => '规划';

  @override
  String get mobilePlanMissing => '此计划已不在当前工作区中。';

  @override
  String mobilePlanStepCount(int count) {
    return '$count 个步骤';
  }

  @override
  String get mobilePlanDraft => '草稿';

  @override
  String get mobilePlanProposed => '等待评审';

  @override
  String get mobilePlanApproved => '已批准';

  @override
  String get mobilePlanRejected => '已拒绝';

  @override
  String get mobilePlanSuperseded => '已替代';

  @override
  String get mobilePlanExecuting => '执行中';

  @override
  String get mobilePlanSynthesizing => '汇总中';

  @override
  String get mobilePlanCompleted => '已完成';

  @override
  String get mobilePlanFailed => '失败';

  @override
  String get mobilePlanCancelled => '已取消';

  @override
  String mobilePlanRevision(String revision) {
    return '修订 $revision';
  }

  @override
  String get mobilePlanSteps => '步骤';

  @override
  String get mobilePlanNoSteps => '此计划未提交任何步骤。';

  @override
  String get mobilePlanAssumptions => '待澄清事项';

  @override
  String mobilePlanDependsOn(String keys) {
    return '依赖 $keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return '预估最高 $cost';
  }

  @override
  String get mobilePlanSelect => '选择';

  @override
  String get mobilePlanSelected => '已选中';

  @override
  String get mobilePlanEstimate => '估算费用';

  @override
  String get mobilePlanEstimateRequired => '请先估算计划费用，再批准执行。';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return '预估费用：$low–$high';
  }

  @override
  String get mobilePlanCostUnknown => '不可用';

  @override
  String get mobilePlanNoHardCap => '无硬性上限';

  @override
  String get mobilePlanExceedsBudget => '预估费用超出设定预算。请在批准前核查。';

  @override
  String get mobilePlanPartialEstimate => '此费用估算涵盖整个计划；所选步骤的费用可能更低。';

  @override
  String get mobilePlanConfirmAll => '开始执行整个计划？';

  @override
  String get mobilePlanConfirmSelected => '开始执行所选步骤？';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return '批准后将开始执行，可能产生费用。预估费用上限：$cost。预算上限：$cap。';
  }

  @override
  String get mobilePlanApproveAll => '全部批准并执行';

  @override
  String get mobilePlanApproveSelected => '批准所选步骤并执行';

  @override
  String get mobilePlanWiden => '批准更多步骤';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return '允许再执行 $count 个步骤？这些步骤可能产生费用。当前执行费用上限：$cap。';
  }

  @override
  String get mobilePlanChanged => '计划在评审期间发生变化。请打开最新修订版并重新估算。';

  @override
  String get mobilePlanReject => '拒绝计划';

  @override
  String get mobilePlanRejectConfirm => '拒绝此计划？计划将不会执行。';

  @override
  String get mobilePlanStop => '停止执行';

  @override
  String get mobilePlanStopConfirm => '停止执行此计划？已完成的工作不会撤销。';

  @override
  String mobilePlanRunId(String runId) {
    return '执行编号：$runId';
  }

  @override
  String get mobilePlanExecutionPending => '已批准。正在等待执行记录…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return '已完成 $completed/$total 个执行步骤';
  }

  @override
  String get mobilePlanOpenConversation => '打开对话';

  @override
  String get mobileGoalsTitle => '监督目标';

  @override
  String get mobileGoalsLoadFailed => '无法加载监督目标';

  @override
  String get mobileGoalsEmpty => '暂无监督目标';

  @override
  String get mobileGoalsEmptyDescription => '在空间中启动目标，或在对话中发送 /goal。';

  @override
  String get mobileGoalMissing => '此目标已不在当前工作区中。';

  @override
  String get mobileGoalActive => '使用中';

  @override
  String get mobileGoalPaused => '已暂停';

  @override
  String get mobileGoalCompleted => '已完成';

  @override
  String get mobileGoalFailed => '失败';

  @override
  String get mobileGoalCancelled => '已取消';

  @override
  String get mobileGoalBudgetExhausted => '预算已用尽';

  @override
  String get mobileGoalGoal => '目标';

  @override
  String get mobileGoalLoop => '循环';

  @override
  String mobileGoalKind(String kind) {
    return '类型：$kind';
  }

  @override
  String mobileGoalRuns(String count) {
    return '$count 次运行';
  }

  @override
  String get mobileGoalNoRunLimit => '不限次数';

  @override
  String mobileGoalProgress(
    String runs,
    String maxRuns,
    String spent,
    String cap,
  ) {
    return '运行次数：$runs/$maxRuns · 已花费：$spent/$cap';
  }

  @override
  String mobileGoalDeadline(String date) {
    return '截止时间：$date';
  }

  @override
  String mobileGoalFailures(String count) {
    return '连续失败次数：$count';
  }

  @override
  String get mobileGoalSummary => '完成摘要';

  @override
  String get mobileGoalFailedDescription => '监督程序在多次运行失败后已停止。请查看对话了解详情。';

  @override
  String get mobileGoalBudgetWall => '已达到截止时间或运行次数上限。提高费用上限也无法继续此目标。';

  @override
  String get mobileGoalPause => '暂停目标';

  @override
  String get mobileGoalResume => '继续目标';

  @override
  String get mobileGoalStop => '取消目标';

  @override
  String get mobileGoalStopConfirm => '永久取消此监督目标？取消后无法继续。';

  @override
  String get mobileGoalRaiseBudget => '提高预算并继续';

  @override
  String mobileGoalRaiseTo(String amount) {
    return '将预算提高到 $amount 并继续';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return '将此目标的费用上限从 $oldCap 提高到 $newCap，并继续产生费用？';
  }

  @override
  String get mobileGoalOpenConversation => '打开目标对话';

  @override
  String get mobileGoalCreate => '启动监督目标';

  @override
  String get mobileGoalChooseSpace => '运行空间';

  @override
  String get mobileGoalNoSpaces => '请先创建空间，再启动目标。';

  @override
  String get mobileGoalChooseAgent => '运行智能体';

  @override
  String get mobileGoalNoAgents => '请先添加使用中的智能体，再启动目标。';

  @override
  String mobileGoalSelectedAgent(String name) {
    return '已选择 $name';
  }

  @override
  String get mobileGoalObjectiveHint => '希望智能体实现什么目标？';

  @override
  String get mobileGoalBudgetUsd => '费用上限（美元）';

  @override
  String get mobileGoalCreateInvalid => '请选择空间和智能体，输入目标，并设置大于零的美元费用上限。';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return '以最高 $cap 的费用启动监督目标？智能体可能立即开始运行。';
  }

  @override
  String get mobileGoalUnavailable => '服务器连接尚未就绪。请重新连接后重试。';

  @override
  String get mobileGoalConversationMissing => '所选对话已不在当前工作区中。';

  @override
  String get mobileGoalCreateSent => '目标已启动。监督状态将在此列表中显示。';

  @override
  String get mobileGoalStartRefused => '目标未启动。请查看对话，了解监督程序的原因。';

  @override
  String mobileGoalSelectedSpace(String name) {
    return '已选择 $name';
  }

  @override
  String get requestUnavailable => '此请求已不在当前工作区中。';

  @override
  String get requestAlreadyResolved => '此请求已解决。';

  @override
  String get inboxCredentialsBlocked => '凭据阻碍运行';

  @override
  String get inboxSyncFailures => '供应商同步失败';

  @override
  String get inboxConfigureCredentials => '配置凭据';

  @override
  String get openTicket => '打开工单';

  @override
  String get activityTitle => '活动';

  @override
  String get activityClearAll => '清除活动';

  @override
  String get activityClearConfirm => '此操作将在你的所有设备上隐藏目前记录的全部活动。新活动仍会显示。';

  @override
  String get activityMarkAllRead => '全部标为已读';

  @override
  String get activityMarkAllConfirm => '将此工作区中的所有活动在你的全部设备上标为已读？';

  @override
  String get activityMarkRead => '标为已读';

  @override
  String get activityMarkUnread => '标为未读';

  @override
  String get activityDismiss => '忽略';

  @override
  String get activityResolved => '已解决';

  @override
  String get activityOpen => '打开';

  @override
  String get activityEmpty => '暂无动态';

  @override
  String get activityLoadFailed => '无法加载活动';

  @override
  String get activityAgentWaiting => '智能体需要你提供信息';

  @override
  String get activityAgentBlocked => '智能体操作受阻';

  @override
  String get activityMessage => '新消息';

  @override
  String get activityPullRequest => 'Pull request 更新';

  @override
  String get activityTicket => '工单更新';

  @override
  String get activityMeeting => '会议更新';

  @override
  String get activityCalendar => '日历连接';

  @override
  String get activityRig => '设备舱更新';

  @override
  String get activityEvent => '更新';

  @override
  String get activityPrReady => 'Pull request 已可合并';

  @override
  String get activityPrBlocked => 'Pull request 合并受阻';

  @override
  String get activityPrApproved => 'Pull request 已获批准';

  @override
  String get activityPrChanges => '已请求变更';

  @override
  String get activityPrChecksFailed => 'Pull request 检查失败';

  @override
  String get activityPrChecksRecovered => 'Pull request 检查已恢复';

  @override
  String get activityPrComment => 'Pull request 评论';

  @override
  String get activityPrPublished => 'Pull request 已发布';

  @override
  String get activityPrMerged => '已合并 pull request';

  @override
  String get activityPrMentioned => '在 pull request 中被提及';

  @override
  String get activityPrReviewRequested => '请求评审';

  @override
  String get activityPrReviewStale => '需要重新评审';

  @override
  String get activityTicketAssigned => '工单已分配';

  @override
  String get activityTicketChanged => '工单状态已更改';

  @override
  String get activityMeetingSoon => '会议即将开始';

  @override
  String get activityCalendarExpired => '日历连接已过期';

  @override
  String get activityRigControl => '设备舱控制已更改';

  @override
  String get activityRigClosed => '设备舱已停止';

  @override
  String get mobileSpacesSearch => '搜索空间';

  @override
  String get mobileSpacesArchived => '已归档';

  @override
  String get mobileSpacesActive => '使用中';

  @override
  String get mobileSpacesNew => '新建空间';

  @override
  String get mobileSpacesManage => '管理空间';

  @override
  String get mobileSpacesName => '空间名称';

  @override
  String get mobileSpacesAgents => '智能体';

  @override
  String get mobileSpacesMembers => '人员';

  @override
  String get mobileSpacesRepos => '仓库';

  @override
  String get mobileSpacesAllRepos => '所有关联仓库';

  @override
  String get mobileSpacesNoRepos => '无仓库';

  @override
  String get mobileSpacesBaseBranch => '基础分支（可选）';

  @override
  String get mobileSpacesDefaultBranch => '默认分支';

  @override
  String get mobileSpacesMode => '模式';

  @override
  String get mobileSpacesModeChat => '聊天';

  @override
  String get mobileSpacesModeReview => '评审（只读）';

  @override
  String get mobileSpacesModePlan => '规划（只读）';

  @override
  String get mobileSpacesModeOrchestrate => '编排';

  @override
  String get mobileSpacesAutonomy => '自主权限覆盖设置';

  @override
  String get mobileSpacesAutonomyInherited => '继承';

  @override
  String get mobileSpacesAutonomyPropose => '仅提议';

  @override
  String get mobileSpacesAutonomyApproval => '批准后行动';

  @override
  String get mobileSpacesAutonomyFreely => '自由行动';

  @override
  String get mobileSpacesAutonomyNotice => '覆盖设置无法绕过操作策略的询问或拒绝。只有工作区管理员可以更改。';

  @override
  String get mobileSpacesArchive => '归档空间';

  @override
  String get mobileSpacesReopen => '重新打开空间';

  @override
  String get mobileSpacesSave => '保存更改';

  @override
  String get mobileSpacesCreate => '创建空间';

  @override
  String get mobileSpacesOperationFailed => '无法更新空间';

  @override
  String get mobileSpacesMissing => '在此工作区中找不到该空间';

  @override
  String get mobileSpacesEmptyName => '请输入空间名称';

  @override
  String get mobileSpacesNoMatches => '没有匹配的空间';

  @override
  String get mobileSpacesUnread => '未读的智能体回复';

  @override
  String get mobileSpacesNeedsInput => '需要你提供信息';

  @override
  String get mobileSpacesRunning => '智能体运行中';

  @override
  String get mobileSpacesNoAgents => '此工作区中没有智能体';

  @override
  String get mobileSpacesNoMembers => '没有其他工作区成员';

  @override
  String get mobileSpacesRepoError => '无法加载仓库';

  @override
  String get mobileSpacesRetry => '重试';

  @override
  String get mobileSpacesBranchUnavailable => '创建空间时请选择或输入基础分支；现有空间的基础分支无法更改。';

  @override
  String get mobileSpacesArchivedEmpty => '没有已归档空间';

  @override
  String get mobileSpacesAllRepoWarning => '之后关联到工作区的新仓库也会纳入此空间。';

  @override
  String get mobileSpacesCreatedRetry => '空间已创建。请重试添加人员，或打开空间管理页面。';

  @override
  String get progressTitle => '进度';

  @override
  String get progressConversation => '对话';

  @override
  String get progressLoadFailed => '无法加载进度';

  @override
  String get progressUnavailable => '对话不可用';

  @override
  String get progressUnavailableDescription => '此对话不在当前工作区和空间中。请返回所属空间继续。';

  @override
  String get progressSaveFailed => '无法更新进度';

  @override
  String get progressGoal => '目标';

  @override
  String get progressNoGoal => '未设定当前目标';

  @override
  String get progressSetGoal => '设定目标';

  @override
  String get progressEditGoal => '编辑目标';

  @override
  String get progressClearGoal => '清除目标';

  @override
  String get progressGoalRequired => '请先输入目标再保存。';

  @override
  String get progressTodos => '任务';

  @override
  String get progressNoTodos => '暂无任务';

  @override
  String get progressNewTodo => '新建任务';

  @override
  String get progressAddTodo => '添加任务';

  @override
  String get progressEditTodo => '编辑任务';

  @override
  String get progressTodoRequired => '请先输入任务再保存。';

  @override
  String get progressTodoNoLongerExists => '该任务已移除。请重新加载列表后重试。';

  @override
  String get progressWorkspaceChanged => '当前工作区已变更。请返回此对话后重试。';

  @override
  String progressRemoveTodo(String name) {
    return '移除任务 $name';
  }

  @override
  String get progressPending => '等待中';

  @override
  String get progressInProgress => '进行中';

  @override
  String get progressCompleted => '已完成';

  @override
  String get progressMoveUp => '上移任务';

  @override
  String get progressMoveDown => '下移任务';

  @override
  String get progressRunTree => '智能体运行记录';

  @override
  String get progressNoRuns => '此对话尚无运行记录';

  @override
  String get progressRunning => '运行中';

  @override
  String get progressFailed => '失败';

  @override
  String get progressUnknown => '未知';

  @override
  String get progressHealthy => '使用中';

  @override
  String get progressBlocked => '已阻塞';

  @override
  String get progressLooping => '陷入循环';

  @override
  String get progressStalled => '停滞';

  @override
  String get progressDead => '意外停止';

  @override
  String get progressQuiet => '尚无输出';

  @override
  String get progressCostReported => '服务商报告的费用';

  @override
  String get progressCostNotional => '按订阅标价估算，并非账单';

  @override
  String get progressCostMixed => '混合费用来源';

  @override
  String get progressCostEstimated => '预估费用';

  @override
  String progressDurationSeconds(String seconds) {
    return '$seconds 秒';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return '模型：$model · 时长：$duration · 费用：$cost';
  }

  @override
  String progressStartedAt(String time) {
    return '开始于 $time';
  }

  @override
  String progressLiveness(String state) {
    return '运行状态：$state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return '输入：$input · 输出：$output 个 token';
  }

  @override
  String get progressOutputPreviewLimited => '仅显示结构化输出的前 6,000 个字符。';

  @override
  String progressRetryOf(String runId) {
    return '重试运行 $runId';
  }

  @override
  String get progressContext => '上下文与限制';

  @override
  String get progressNoAgent => '没有可查看的智能体';

  @override
  String progressContextReading(String used, String window) {
    return '$used/$window 个 token';
  }

  @override
  String get progressMeasured => '服务商报告的最近一次调用上下文用量';

  @override
  String get progressEstimated => '根据已存储的对话和持久上下文估算';

  @override
  String get progressContextUnknown => '尚无上下文用量报告';

  @override
  String progressContextPercent(String percent) {
    return '占上下文窗口的 $percent%';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return '已配置的智能体月度上限：$amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return '已存储的当前对话：约 $tokens 个 token';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return '$agent 的持久上下文 · $model';
  }

  @override
  String get progressContextSystem => '系统提示词';

  @override
  String get progressContextRules => '规则';

  @override
  String get progressContextSkills => '技能';

  @override
  String get progressContextTools => '工具定义';

  @override
  String get progressContextMcp => 'MCP 工具';

  @override
  String get progressContextDeferred => '延迟加载的工具';

  @override
  String get progressContextSubagents => '子智能体';

  @override
  String get progressContextRunner => '外部运行器';

  @override
  String get progressContextMemory => '记忆';

  @override
  String get progressContextHistory => '对话历史';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens 个 token';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens 个 token';
  }

  @override
  String get progressOutputs => '最近的输出';

  @override
  String get progressNoOutputs => '暂无近期智能体输出';

  @override
  String get progressStructuredOutputsAbove => '结构化运行输出显示在上方的智能体运行记录中。';

  @override
  String get progressRecentOutputsOnly => '仅显示近期消息。要查看更早的工作，请打开对话。';

  @override
  String get progressPlan => '规划';

  @override
  String get progressArtifact => '制品';

  @override
  String get progressResult => '结果';

  @override
  String get progressHideArtifact => '隐藏制品';

  @override
  String get progressReadArtifact => '查看制品';

  @override
  String get progressArtifactUnavailable => '制品已不可用';

  @override
  String get progressArtifactPreviewLimited => '仅显示此制品的部分预览。';

  @override
  String get progressDiagramSource => '图表源代码';

  @override
  String progressOpenAttachment(String name) {
    return '打开 $name';
  }

  @override
  String get progressOpenPlan => '打开计划';

  @override
  String progressOpenDiff(String label) {
    return '查看已更改的文件：$label';
  }

  @override
  String get progressViewMessage => '查看消息';

  @override
  String get pushTitle => '后台通知';

  @override
  String get pushIntro => '即使应用已关闭，也能在需要你处理事务时收到私人提醒。详情仅通过加密连接查看。';

  @override
  String get pushLoading => '正在检查通知设置…';

  @override
  String get pushError => '无法更新通知。请检查连接后重试。';

  @override
  String get pushEnable => '启用通知';

  @override
  String get pushDisable => '关闭通知';

  @override
  String get pushQuiet => '暂停此设备上的提醒';

  @override
  String get pushCategories => '通知我以下事项';

  @override
  String get pushCategoryAgents => '智能体';

  @override
  String get pushCategoryMessages => '消息';

  @override
  String get pushCategoryPullRequests => 'Pull requests';

  @override
  String get pushCategoryTickets => '工单';

  @override
  String get pushCategoryCalendar => '日历';

  @override
  String get pushCategoryMachines => '机器';

  @override
  String get pushSecureOrigin => '通知需要 HTTPS。';

  @override
  String get pushInstallIos => '在 iPhone 或 iPad 上，请将此应用添加到主屏幕并从主屏幕打开，以启用通知。';

  @override
  String get pushUnsupported => '此浏览器不支持后台通知。';

  @override
  String get pushDenied => '浏览器设置已阻止通知。请在设置中允许通知后继续。';

  @override
  String get pushResubscribe => '重新连接通知';

  @override
  String get pushStatusEnabled => '此设备已开启通知。';

  @override
  String get pushStatusDisabled => '此设备已关闭通知。';

  @override
  String get credentialsTitle => '连接与凭据';

  @override
  String get credentialsIntro => '连接运行任务和集成所需的账户。机密信息存储在服务器上，而非此手机上。';

  @override
  String get credentialsModelProviders => '模型提供商';

  @override
  String get credentialsOwnerOnly =>
      '只有服务器所有者才能添加模型提供商凭据、登录或移除凭据。这些密钥在各工作区之间共用。';

  @override
  String get credentialsContactOwner => '请联系服务器所有者，连接受阻运行任务所需的提供商。';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'Claude Code 需要通过主机上的 CLI 登录。请让服务器所有者在主机终端完成或更新账户登录；无法在此手机上操作。';

  @override
  String get credentialsYourForgeAccounts => '你的代码托管平台账户';

  @override
  String get credentialsYourTicketingAccount => '你的工单平台账户';

  @override
  String get credentialsLocalTicketsNoLogin => '本地工单无需登录。如果工作区使用 Linear，请在此连接。';

  @override
  String get credentialsMembershipRequired =>
      '加入工作区后才能管理你的代码托管平台或工单平台凭据。请联系工作区管理员申请访问权限。';

  @override
  String get credentialsSwitchWorkspace => '此链接指向另一个工作区。请切换到该工作区后再更改凭据。';

  @override
  String get credentialsReturnToInbox =>
      '连接凭据后，请返回收件箱重试受阻的运行任务。主机也会自动检查暂停等待的运行任务。';

  @override
  String get credentialsLoadFailed => '无法加载连接。请检查服务器连接并重试。';

  @override
  String get credentialsOperationFailed => '无法更改此连接。请检查服务器连接、访问权限和凭据，然后重试。';

  @override
  String get credentialsConnected => '已连接';

  @override
  String get credentialsNotConnected => '未连接';

  @override
  String credentialsSignedInAs(String username) {
    return '已登录为 $username';
  }

  @override
  String get credentialsAccount => '已连接的账户';

  @override
  String get credentialsStoredKey => '已存储的密钥';

  @override
  String get credentialsActive => '使用中';

  @override
  String get credentialsRemove => '移除';

  @override
  String get credentialsRemoveConfirm => '移除已保存的凭据？之后可能需要重新登录。';

  @override
  String get credentialsApiKey => 'API 密钥';

  @override
  String get credentialsApiKeyHint => '粘贴提供商 API 密钥';

  @override
  String get credentialsBrowserLogin => '通过浏览器登录';

  @override
  String get credentialsSignInAgain => '请重新登录';

  @override
  String get credentialsWaitingForLogin => '正在等待浏览器授权…';

  @override
  String get credentialsLoginTimedOut => '登录已过期。请重新发起登录。';

  @override
  String get credentialsCopyCode => '复制代码';

  @override
  String get credentialsDeviceCodeHint => '请在提供商页面确认此代码。在服务器完成登录前，请保持此页面打开。';

  @override
  String get credentialsPasteRedirect => '授权码或重定向 URL';

  @override
  String get credentialsPasteRedirectHint => '粘贴提供商提供的代码或完整重定向 URL';

  @override
  String get credentialsCompleteLogin => '完成登录';

  @override
  String get credentialsRedirectUnavailable =>
      '此服务器的浏览器回调无法通过手机安全访问。请让服务器所有者配置公开的 HTTPS 回调，或改为添加令牌。';

  @override
  String get credentialsUpdateToken => '更新令牌';

  @override
  String get credentialsAddToken => '添加令牌';

  @override
  String get credentialsPersonalToken => '个人访问令牌';

  @override
  String get credentialsPersonalTokenHint => '粘贴个人访问令牌';

  @override
  String get credentialsHostManaged =>
      '此连接来自服务器应用或环境。只有服务器所有者能在那里更改；你仍可添加自己的令牌。';

  @override
  String get credentialsStopWatching => '停止监测';
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
  String get copyCommand => '複製命令';

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
  String get scanQrPrompt => '掃描 Control Center 上的 QR code，以配對此手機。';

  @override
  String get scanQrHelp => '開啟相機，對準 Control Center 顯示的 QR。此手機會透過私人連線直接連線。';

  @override
  String get connectingToMac => '正在連線到 Control Center…';

  @override
  String get connectingDetail => '正在建立安全的直接連線。';

  @override
  String get identityChangedTitle => '伺服器身分已變更';

  @override
  String get identityChangedBody =>
      '此伺服器與配對時儲存的身分不符。這可能表示伺服器已重新安裝，或連線遭到攔截。為了安全起見，此裝置將不會連線。請移除配對，然後從 Control Center 掃描新的 QR code 再次配對。';

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
  String get failureNotPaired => '尚未配對 — 請掃描 Control Center 上的 QR code';

  @override
  String get failureUnreachable => '無法透過任何路徑連到你的伺服器 — 請確認伺服器正在執行，或改用相同網路再試';

  @override
  String get failureIdentityChanged => '伺服器身分已變更 — 若已重新安裝，請重新配對此裝置';

  @override
  String get failureAuthRejected => '伺服器已拒絕此裝置 — 請從 Control Center 重新配對';

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
  String get disconnectTapAgain => '再點一次即可將此裝置從 Control Center 中斷連線';

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
  String get newSpaceFolder => '新增資料夾';

  @override
  String get folderName => '資料夾名稱';

  @override
  String get renameSpaceFolder => '重新命名資料夾';

  @override
  String get deleteSpaceFolder => '刪除資料夾';

  @override
  String get moveSpaceToFolder => '移至資料夾';

  @override
  String get removeSpaceFromFolder => '從資料夾移除';

  @override
  String get spaceFolderActions => '資料夾操作';

  @override
  String get deleteFolderWithSpacesWarning => '永久刪除空間會為所有人移除其中的訊息和工作樹。此操作無法復原。';

  @override
  String get deleteSpacesInFolder => '永久刪除此資料夾中的空間';

  @override
  String get deleteFolderAndSpaces => '刪除資料夾和空間';

  @override
  String get keepSpacesInFolder => '否則，空間將不屬於任何資料夾。';

  @override
  String get create => '建立';

  @override
  String get otherSpaces => '其他空間';

  @override
  String get folderUpdateFailed => '無法更新資料夾';

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

  @override
  String get mobileConversations => '對話';

  @override
  String get mobileNewConversation => '新對話';

  @override
  String get mobileConversationName => '對話名稱';

  @override
  String get mobileRename => '重新命名';

  @override
  String get mobileManageSpace => '管理空間';

  @override
  String get mobileArchived => '已封存';

  @override
  String get mobileSearchMessages => '搜尋此空間中的所有訊息';

  @override
  String get mobileSearch => '搜尋';

  @override
  String get mobileNoResults => '無結果';

  @override
  String get mobileReopen => '重新開啟';

  @override
  String get mobileArchive => '封存';

  @override
  String get mobileProgress => '進度與上下文';

  @override
  String get mobileReadFailed => '無法將此對話標記為已讀';

  @override
  String get mobileSendFailed => '訊息未傳送，草稿仍在此處。';

  @override
  String get mobileActionFailed => '動作失敗';

  @override
  String get mobileRemove => '移除';

  @override
  String get mobileLinkedMessage => '關聯訊息';

  @override
  String get mobileOlderMessages => '更早的訊息';

  @override
  String get mobileMessageActions => '訊息操作';

  @override
  String get mobileOpenThread => '開啟討論串';

  @override
  String get mobileCopyLink => '複製連結';

  @override
  String get mobileStopRun => '停止執行';

  @override
  String get mobileStopRunConfirm => '停止此次代理執行？已完成的工作會保留。';

  @override
  String get mobileControlUnsupported => '此次執行已結束或不支援此操作。';

  @override
  String get mobilePauseRequested => '已請求在下一輪結束時暫停';

  @override
  String get mobileResumed => '已繼續執行';

  @override
  String get mobileStopRequested => '已請求停止';

  @override
  String get mobileQueuedMessages => '排隊的訊息';

  @override
  String get mobilePauseRun => '下一輪暫停';

  @override
  String get mobileResumeRun => '繼續';

  @override
  String get mobileEditQueued => '編輯排隊訊息';

  @override
  String get mobileSteerNow => '立即引導';

  @override
  String get mobileMoveUp => '上移';

  @override
  String get mobileMoveDown => '下移';

  @override
  String get mobileQueueChanged => '佇列已變更，或此次執行無法接受即時引導。請重新整理後重試。';

  @override
  String get mobileActivity => '活動';

  @override
  String get mobilePermissions => '權限與稽核';

  @override
  String get mobilePlans => '計畫';

  @override
  String get mobileGoals => '監督目標';

  @override
  String get mobileCredentials => '連線與憑證';

  @override
  String get mobileWorkspaceUnavailable => '此工作區不可用，或你已無權存取。';

  @override
  String get mobilePrReviewThreads => '審查討論串';

  @override
  String get mobilePrThreadsLoadFailed => '無法載入審查討論串';

  @override
  String get mobilePrNoReviewThreads => '尚無行內審查討論串';

  @override
  String get mobilePrCommentPermissionDenied => '你無權在此存放庫發表留言。';

  @override
  String get mobilePrPermissionChecking => '正在檢查留言權限…';

  @override
  String get mobilePrPermissionLoadFailed => '無法檢查留言權限。請重試後發表留言。';

  @override
  String mobilePrThreadLine(String side, String line) {
    return '$side第 $line 行';
  }

  @override
  String get mobilePrOriginalSide => '原始版本';

  @override
  String get mobilePrUpdatedSide => '更新時間';

  @override
  String get mobilePrThreadResolved => '已解決';

  @override
  String get mobilePrReplyHint => '撰寫回覆…';

  @override
  String get mobilePrCommentRequired => '請先填寫留言再發佈。';

  @override
  String get mobilePrReply => '回覆';

  @override
  String get mobilePrReopenThread => '重新開啟討論';

  @override
  String get mobilePrResolveThread => '解決討論';

  @override
  String get mobilePrResolvePermissionDenied =>
      '只有 pull request 作者或擁有寫入權限的人才能解決此討論串。';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return '在$side第 $line 行留言';
  }

  @override
  String get mobilePrInlineCommentHint => '撰寫行內留言…';

  @override
  String get mobilePrPostInlineComment => '發佈留言';

  @override
  String get mobilePrCommentUnavailable => '此 pull request 無法新增行內留言。';

  @override
  String get mobilePrPatchUnavailable => '程式碼代管服務未提供此檔案的文字修補檔。';

  @override
  String get mobilePrNoPatchForFile => '此檔案的修補檔不可用。';

  @override
  String get mobileTicketNew => '新增工單';

  @override
  String get mobileTicketCreate => '建立工單';

  @override
  String get mobileTicketEdit => '編輯工單';

  @override
  String get mobileTicketTitle => '標題';

  @override
  String get mobileTicketTitleRequired => '請輸入標題以儲存工單。';

  @override
  String get mobileTicketDescription => '說明';

  @override
  String get mobileTicketMarkdownHint => '使用 Markdown 新增詳情';

  @override
  String get mobileTicketPriority => '優先順序';

  @override
  String get mobileTicketPriorityNone => '無優先順序';

  @override
  String get mobileTicketPriorityUrgent => '緊急';

  @override
  String get mobileTicketPriorityHigh => '高';

  @override
  String get mobileTicketPriorityMedium => '中';

  @override
  String get mobileTicketPriorityLow => '低';

  @override
  String get mobileTicketLabels => '標籤';

  @override
  String get mobileTicketLabelsHint => '每行一個標籤';

  @override
  String get mobileTicketLabelsHelp => '每個標籤單獨佔一行。';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return '已提交至 $provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => '未指派';

  @override
  String get mobileTicketAssignedFilter => '已指派';

  @override
  String get mobileTicketAgentsLoadFailed => '無法載入代理';

  @override
  String get mobileTicketSearch => '搜尋工單';

  @override
  String get mobileTicketSearchHint => '標題、編號、說明、標籤或負責人';

  @override
  String get mobileTicketClearSearch => '清除工單搜尋';

  @override
  String get mobileTicketNoMatches => '沒有符合的工單';

  @override
  String get mobileTicketAdjustFilters => '請嘗試其他搜尋詞或調整篩選條件。';

  @override
  String get mobileTicketClearFilters => '清除篩選';

  @override
  String get mobileTicketNotFound => '找不到工單';

  @override
  String get mobileTicketNotFoundDescription => '此工單可能已被刪除或移出此工作區。';

  @override
  String get mobileTicketWorkspaceChanged => '工作區已變更。請返回目前工作區後再儲存。';

  @override
  String get mobileTicketOpenLinkedSpace => '開啟關聯空間';

  @override
  String get mobileTicketReadOnly => '更改工單需要工作區成員身分。';

  @override
  String get permissionTitle => '權限';

  @override
  String get permissionWorkspaceFailed => '無法載入工作區';

  @override
  String get permissionNoWorkspace => '請選擇工作區以查看權限。';

  @override
  String get permissionLoading => '正在載入權限…';

  @override
  String get permissionScopeDescription => '查看此範圍內各項操作的判定方式。代理和空間可繼承工作區規則。';

  @override
  String get permissionScope => '策略範圍';

  @override
  String get permissionWorkspaceScope => '工作區';

  @override
  String get permissionAgentScope => '代理';

  @override
  String get permissionSpaceScope => '空間';

  @override
  String get permissionAgentContext => '在此空間中執行操作的代理';

  @override
  String get permissionNoAgentContext => '未選擇代理';

  @override
  String get permissionTargetsFailed => '無法載入範圍目標';

  @override
  String get permissionNoTargets => '此範圍內沒有可用目標。';

  @override
  String get permissionRoleFailed => '無法確認你的工作區角色';

  @override
  String get permissionMemberRequired => '查看策略規則需要工作區成員身分。';

  @override
  String get permissionRulesFailed => '無法載入策略規則';

  @override
  String get permissionAuditAdminOnly => '僅工作區管理員可查看授權紀錄。';

  @override
  String get permissionAllow => '允許';

  @override
  String get permissionAsk => '先詢問';

  @override
  String get permissionDeny => '拒絕';

  @override
  String get permissionFileDelete => '刪除檔案';

  @override
  String get permissionFileWriteOutsideWorktree => '在工作樹之外寫入';

  @override
  String get permissionGitCommit => '提交更改';

  @override
  String get permissionGitPush => '推送提交';

  @override
  String get permissionPrCreate => '建立 pull request';

  @override
  String get permissionPrPublish => '發佈 pull request';

  @override
  String get permissionVendorSyncWrite => '寫入供應商同步資料';

  @override
  String get permissionNetworkEgress => '存取網路';

  @override
  String get permissionSecretAccess => '存取機密資訊';

  @override
  String get permissionPackageInstall => '安裝軟體套件';

  @override
  String get permissionProcessSpawn => '啟動程序';

  @override
  String get permissionWorkspaceMutation => '更改工作區';

  @override
  String get permissionEnclosureControl => '控制設備艙';

  @override
  String get permissionChangeFailed => '無法更改規則';

  @override
  String get permissionEffectiveDescription =>
      '在不指定操作引數時，此範圍內的有效規則如下。下方的條件授權僅適用於符合的請求；最終由伺服器裁定。';

  @override
  String get permissionSpaceAgentNote => '未選擇代理。請在上方選擇代理，以查看專屬規則。';

  @override
  String get permissionScopedGrants => '此範圍內的規則';

  @override
  String get permissionModePreset => '模式預設';

  @override
  String get permissionBuiltInDefault => '內建預設';

  @override
  String get permissionRemembered => '已記住的核准';

  @override
  String get permissionSource => '原始碼';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · 在此設定';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · 已繼承';
  }

  @override
  String permissionExpiresAt(String date) {
    return '到期時間：$date';
  }

  @override
  String get permissionSetHere => '在此設定規則';

  @override
  String get permissionRevokeBeforeEdit => '請先撤銷此範圍內的規則或已記住的規則，再為此操作設定通用規則。';

  @override
  String get permissionConfirmRevoke => '確認撤銷';

  @override
  String get permissionRevokeRule => '撤銷規則';

  @override
  String permissionCommandPrefix(String prefix) {
    return '命令字首：$prefix';
  }

  @override
  String get permissionNoExpiry => '永不過期';

  @override
  String get permissionExpired => '已過期';

  @override
  String get permissionExplicitRule => '明確規則';

  @override
  String get permissionEnforcementAdvisory => '建議性執行：先詢問規則只會記錄，不會顯示確認提示';

  @override
  String get permissionEnforcementSoft => '軟性執行：覆蓋規則需要授權';

  @override
  String get permissionEnforcementHard => '強制執行：無法覆蓋規則';

  @override
  String permissionPaths(String paths) {
    return '路徑：$paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'Git 引用：$refs';
  }

  @override
  String permissionHosts(String hosts) {
    return '主機：$hosts';
  }

  @override
  String permissionCommands(String commands) {
    return '命令：$commands';
  }

  @override
  String permissionMaxCount(String count) {
    return '最大數量：$count';
  }

  @override
  String permissionMaxCents(String cents) {
    return '最高金額（美分）：$cents';
  }

  @override
  String get permissionAuditHeading => '授權紀錄';

  @override
  String get permissionAuditDescription => '伺服器記錄的近期決策。只有管理員可以查看紀錄或驗證其雜湊鏈。';

  @override
  String permissionOnBehalfOf(String user) {
    return '代表 $user';
  }

  @override
  String get permissionPrompted => '已請求人工核准';

  @override
  String get permissionVerifyChain => '驗證稽核鏈';

  @override
  String get permissionVerifyFailed => '無法驗證稽核鏈';

  @override
  String permissionChainIntact(String count) {
    return '鏈完整 · 已檢查 $count 筆紀錄';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return '鏈在第 $sequence 筆紀錄處斷裂：$reason';
  }

  @override
  String get permissionAuditEmpty => '尚無授權決策紀錄。';

  @override
  String get permissionAuditFailed => '無法載入授權紀錄';

  @override
  String get mobilePlansLoadFailed => '無法載入計畫';

  @override
  String get mobilePlansEmpty => '尚無計畫';

  @override
  String get mobilePlansEmptyDescription => '代理提交的計畫將在此顯示，供你審查。';

  @override
  String get mobilePlanTitle => '規劃';

  @override
  String get mobilePlanMissing => '此計畫已不在目前工作區中。';

  @override
  String mobilePlanStepCount(int count) {
    return '$count 個步驟';
  }

  @override
  String get mobilePlanDraft => '草稿';

  @override
  String get mobilePlanProposed => '等待審查';

  @override
  String get mobilePlanApproved => '已核准';

  @override
  String get mobilePlanRejected => '已拒絕';

  @override
  String get mobilePlanSuperseded => '已取代';

  @override
  String get mobilePlanExecuting => '執行中';

  @override
  String get mobilePlanSynthesizing => '彙整中';

  @override
  String get mobilePlanCompleted => '已完成';

  @override
  String get mobilePlanFailed => '失敗';

  @override
  String get mobilePlanCancelled => '已取消';

  @override
  String mobilePlanRevision(String revision) {
    return '修訂版 $revision';
  }

  @override
  String get mobilePlanSteps => '步驟';

  @override
  String get mobilePlanNoSteps => '此計畫未提交任何步驟。';

  @override
  String get mobilePlanAssumptions => '待澄清事項';

  @override
  String mobilePlanDependsOn(String keys) {
    return '依賴 $keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return '預估最高 $cost';
  }

  @override
  String get mobilePlanSelect => '選擇';

  @override
  String get mobilePlanSelected => '已選中';

  @override
  String get mobilePlanEstimate => '估算費用';

  @override
  String get mobilePlanEstimateRequired => '請先估算計畫費用，再核准執行。';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return '預估費用：$low–$high';
  }

  @override
  String get mobilePlanCostUnknown => '不可用';

  @override
  String get mobilePlanNoHardCap => '無硬性上限';

  @override
  String get mobilePlanExceedsBudget => '預估費用超出設定預算。請在核准前確認。';

  @override
  String get mobilePlanPartialEstimate => '此費用估算涵蓋整個計畫；所選步驟的費用可能更低。';

  @override
  String get mobilePlanConfirmAll => '開始執行整個計畫？';

  @override
  String get mobilePlanConfirmSelected => '開始執行所選步驟？';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return '核准後將開始執行，可能產生費用。預估費用上限：$cost。預算上限：$cap。';
  }

  @override
  String get mobilePlanApproveAll => '全部核准並執行';

  @override
  String get mobilePlanApproveSelected => '核准所選步驟並執行';

  @override
  String get mobilePlanWiden => '核准更多步驟';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return '允許再執行 $count 個步驟？這些步驟可能產生費用。目前執行費用上限：$cap。';
  }

  @override
  String get mobilePlanChanged => '計畫在審查期間發生變化。請開啟最新修訂版並重新估算。';

  @override
  String get mobilePlanReject => '拒絕計畫';

  @override
  String get mobilePlanRejectConfirm => '拒絕此計畫？計畫將不會執行。';

  @override
  String get mobilePlanStop => '停止執行';

  @override
  String get mobilePlanStopConfirm => '停止執行此計畫？已完成的工作不會撤銷。';

  @override
  String mobilePlanRunId(String runId) {
    return '執行編號：$runId';
  }

  @override
  String get mobilePlanExecutionPending => '已核准。正在等待執行紀錄…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return '已完成 $completed/$total 個執行步驟';
  }

  @override
  String get mobilePlanOpenConversation => '開啟對話';

  @override
  String get mobileGoalsTitle => '監督目標';

  @override
  String get mobileGoalsLoadFailed => '無法載入監督目標';

  @override
  String get mobileGoalsEmpty => '尚無監督目標';

  @override
  String get mobileGoalsEmptyDescription => '在空間中啟動目標，或在對話中傳送 /goal。';

  @override
  String get mobileGoalMissing => '此目標已不在目前工作區中。';

  @override
  String get mobileGoalActive => '使用中';

  @override
  String get mobileGoalPaused => '已暫停';

  @override
  String get mobileGoalCompleted => '已完成';

  @override
  String get mobileGoalFailed => '失敗';

  @override
  String get mobileGoalCancelled => '已取消';

  @override
  String get mobileGoalBudgetExhausted => '預算已用盡';

  @override
  String get mobileGoalGoal => '目標';

  @override
  String get mobileGoalLoop => '迴圈';

  @override
  String mobileGoalKind(String kind) {
    return '類型：$kind';
  }

  @override
  String mobileGoalRuns(String count) {
    return '$count 次執行';
  }

  @override
  String get mobileGoalNoRunLimit => '不限次數';

  @override
  String mobileGoalProgress(
    String runs,
    String maxRuns,
    String spent,
    String cap,
  ) {
    return '執行次數：$runs/$maxRuns · 已花費：$spent/$cap';
  }

  @override
  String mobileGoalDeadline(String date) {
    return '截止時間：$date';
  }

  @override
  String mobileGoalFailures(String count) {
    return '連續失敗次數：$count';
  }

  @override
  String get mobileGoalSummary => '完成摘要';

  @override
  String get mobileGoalFailedDescription => '監督程式在多次執行失敗後已停止。請查看對話瞭解詳情。';

  @override
  String get mobileGoalBudgetWall => '已達到截止時間或執行次數上限。提高費用上限也無法繼續此目標。';

  @override
  String get mobileGoalPause => '暫停目標';

  @override
  String get mobileGoalResume => '繼續目標';

  @override
  String get mobileGoalStop => '取消目標';

  @override
  String get mobileGoalStopConfirm => '永久取消此監督目標？取消後無法繼續。';

  @override
  String get mobileGoalRaiseBudget => '提高預算並繼續';

  @override
  String mobileGoalRaiseTo(String amount) {
    return '將預算提高到 $amount 並繼續';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return '將此目標的費用上限從 $oldCap 提高到 $newCap，並繼續產生費用？';
  }

  @override
  String get mobileGoalOpenConversation => '開啟目標對話';

  @override
  String get mobileGoalCreate => '啟動監督目標';

  @override
  String get mobileGoalChooseSpace => '在空間中執行';

  @override
  String get mobileGoalNoSpaces => '請先建立空間，再啟動目標。';

  @override
  String get mobileGoalChooseAgent => '使用代理執行';

  @override
  String get mobileGoalNoAgents => '請先新增使用中的代理，再啟動目標。';

  @override
  String mobileGoalSelectedAgent(String name) {
    return '已選擇 $name';
  }

  @override
  String get mobileGoalObjectiveHint => '希望代理實現什麼目標？';

  @override
  String get mobileGoalBudgetUsd => '費用上限（美元）';

  @override
  String get mobileGoalCreateInvalid => '請選擇空間和代理，輸入目標，並設定大於零的美元費用上限。';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return '以最高 $cap 的費用啟動監督目標？代理可能立即開始執行。';
  }

  @override
  String get mobileGoalUnavailable => '伺服器連線尚未就緒。請重新連線後重試。';

  @override
  String get mobileGoalConversationMissing => '所選對話已不在目前工作區中。';

  @override
  String get mobileGoalCreateSent => '目標已啟動。監督狀態將在此清單中顯示。';

  @override
  String get mobileGoalStartRefused => '目標未啟動。請查看對話，瞭解監督程式的原因。';

  @override
  String mobileGoalSelectedSpace(String name) {
    return '已選擇 $name';
  }

  @override
  String get requestUnavailable => '此請求已不在目前工作區中。';

  @override
  String get requestAlreadyResolved => '此請求已解決。';

  @override
  String get inboxCredentialsBlocked => '憑證阻礙執行';

  @override
  String get inboxSyncFailures => '供應商同步失敗';

  @override
  String get inboxConfigureCredentials => '設定憑證';

  @override
  String get openTicket => '開啟工單';

  @override
  String get activityTitle => '活動';

  @override
  String get activityClearAll => '清除活動';

  @override
  String get activityClearConfirm => '此操作將在你的所有裝置上隱藏目前紀錄的全部活動。新活動仍會顯示。';

  @override
  String get activityMarkAllRead => '全部標為已讀';

  @override
  String get activityMarkAllConfirm => '將此工作區中的所有活動在你的全部裝置上標為已讀？';

  @override
  String get activityMarkRead => '標為已讀';

  @override
  String get activityMarkUnread => '標為未讀';

  @override
  String get activityDismiss => '關閉';

  @override
  String get activityResolved => '已解決';

  @override
  String get activityOpen => '開啟';

  @override
  String get activityEmpty => '尚無活動';

  @override
  String get activityLoadFailed => '無法載入活動';

  @override
  String get activityAgentWaiting => '代理需要你提供資訊';

  @override
  String get activityAgentBlocked => '代理操作受阻';

  @override
  String get activityMessage => '新訊息';

  @override
  String get activityPullRequest => 'Pull request 更新';

  @override
  String get activityTicket => '工單更新';

  @override
  String get activityMeeting => '會議更新';

  @override
  String get activityCalendar => '行事曆連線';

  @override
  String get activityRig => '設備艙更新';

  @override
  String get activityEvent => '更新';

  @override
  String get activityPrReady => 'Pull request 已可合併';

  @override
  String get activityPrBlocked => 'Pull request 合併受阻';

  @override
  String get activityPrApproved => 'Pull request 已核准';

  @override
  String get activityPrChanges => '要求變更';

  @override
  String get activityPrChecksFailed => 'Pull request 檢查失敗';

  @override
  String get activityPrChecksRecovered => 'Pull request 檢查已恢復';

  @override
  String get activityPrComment => 'Pull request 留言';

  @override
  String get activityPrPublished => 'Pull request 已發佈';

  @override
  String get activityPrMerged => 'Pull request 已合併';

  @override
  String get activityPrMentioned => '在 pull request 中被提及';

  @override
  String get activityPrReviewRequested => '已請求審查';

  @override
  String get activityPrReviewStale => '需要重新審查';

  @override
  String get activityTicketAssigned => '工單已指派';

  @override
  String get activityTicketChanged => '工單狀態已變更';

  @override
  String get activityMeetingSoon => '會議即將開始';

  @override
  String get activityCalendarExpired => '行事曆連線已過期';

  @override
  String get activityRigControl => '設備艙控制已更改';

  @override
  String get activityRigClosed => '設備艙已停止';

  @override
  String get mobileSpacesSearch => '搜尋空間';

  @override
  String get mobileSpacesArchived => '已封存';

  @override
  String get mobileSpacesActive => '使用中';

  @override
  String get mobileSpacesNew => '新增空間';

  @override
  String get mobileSpacesManage => '管理空間';

  @override
  String get mobileSpacesName => '空間名稱';

  @override
  String get mobileSpacesAgents => '代理';

  @override
  String get mobileSpacesMembers => '人員';

  @override
  String get mobileSpacesRepos => '存放庫';

  @override
  String get mobileSpacesAllRepos => '所有關聯存放庫';

  @override
  String get mobileSpacesNoRepos => '無存放庫';

  @override
  String get mobileSpacesBaseBranch => '基礎分支（可選）';

  @override
  String get mobileSpacesDefaultBranch => '預設分支';

  @override
  String get mobileSpacesMode => '模式';

  @override
  String get mobileSpacesModeChat => '聊天';

  @override
  String get mobileSpacesModeReview => '審查（唯讀）';

  @override
  String get mobileSpacesModePlan => '規劃（唯讀）';

  @override
  String get mobileSpacesModeOrchestrate => '編排';

  @override
  String get mobileSpacesAutonomy => '自主程度覆寫設定';

  @override
  String get mobileSpacesAutonomyInherited => '繼承';

  @override
  String get mobileSpacesAutonomyPropose => '僅提出建議';

  @override
  String get mobileSpacesAutonomyApproval => '經核准後行動';

  @override
  String get mobileSpacesAutonomyFreely => '自由行動';

  @override
  String get mobileSpacesAutonomyNotice => '覆寫設定無法跳過操作政策的確認或拒絕。只有工作區管理員可以變更。';

  @override
  String get mobileSpacesArchive => '封存空間';

  @override
  String get mobileSpacesReopen => '重新開啟空間';

  @override
  String get mobileSpacesSave => '儲存變更';

  @override
  String get mobileSpacesCreate => '建立空間';

  @override
  String get mobileSpacesOperationFailed => '無法更新空間';

  @override
  String get mobileSpacesMissing => '在此工作區中找不到該空間';

  @override
  String get mobileSpacesEmptyName => '請輸入空間名稱';

  @override
  String get mobileSpacesNoMatches => '沒有符合的空間';

  @override
  String get mobileSpacesUnread => '未讀的代理回覆';

  @override
  String get mobileSpacesNeedsInput => '需要你提供資訊';

  @override
  String get mobileSpacesRunning => '代理執行中';

  @override
  String get mobileSpacesNoAgents => '此工作區中沒有代理';

  @override
  String get mobileSpacesNoMembers => '沒有其他工作區成員';

  @override
  String get mobileSpacesRepoError => '無法載入存放庫';

  @override
  String get mobileSpacesRetry => '重試';

  @override
  String get mobileSpacesBranchUnavailable => '建立空間時請選擇或輸入基礎分支；現有空間的基礎分支無法更改。';

  @override
  String get mobileSpacesArchivedEmpty => '沒有已封存的空間';

  @override
  String get mobileSpacesAllRepoWarning => '之後關聯到工作區的新存放庫也會納入此空間。';

  @override
  String get mobileSpacesCreatedRetry => '空間已建立。請重試新增人員，或開啟空間管理頁面。';

  @override
  String get progressTitle => '進度';

  @override
  String get progressConversation => '對話';

  @override
  String get progressLoadFailed => '無法載入進度';

  @override
  String get progressUnavailable => '對話不可用';

  @override
  String get progressUnavailableDescription => '此對話不在目前工作區和空間中。請返回所屬空間繼續。';

  @override
  String get progressSaveFailed => '無法更新進度';

  @override
  String get progressGoal => '目標';

  @override
  String get progressNoGoal => '未設定目前目標';

  @override
  String get progressSetGoal => '設定目標';

  @override
  String get progressEditGoal => '編輯目標';

  @override
  String get progressClearGoal => '清除目標';

  @override
  String get progressGoalRequired => '請先輸入目標再儲存。';

  @override
  String get progressTodos => '任務';

  @override
  String get progressNoTodos => '尚無任務';

  @override
  String get progressNewTodo => '新增任務';

  @override
  String get progressAddTodo => '新增任務';

  @override
  String get progressEditTodo => '編輯任務';

  @override
  String get progressTodoRequired => '請先輸入任務再儲存。';

  @override
  String get progressTodoNoLongerExists => '該任務已移除。請重新載入清單後重試。';

  @override
  String get progressWorkspaceChanged => '目前工作區已變更。請返回此對話後重試。';

  @override
  String progressRemoveTodo(String name) {
    return '移除任務 $name';
  }

  @override
  String get progressPending => '等待中';

  @override
  String get progressInProgress => '進行中';

  @override
  String get progressCompleted => '已完成';

  @override
  String get progressMoveUp => '上移任務';

  @override
  String get progressMoveDown => '下移任務';

  @override
  String get progressRunTree => '代理執行紀錄';

  @override
  String get progressNoRuns => '此對話尚無執行紀錄';

  @override
  String get progressRunning => '執行中';

  @override
  String get progressFailed => '失敗';

  @override
  String get progressUnknown => '未知';

  @override
  String get progressHealthy => '使用中';

  @override
  String get progressBlocked => '已封鎖';

  @override
  String get progressLooping => '陷入迴圈';

  @override
  String get progressStalled => '停滯';

  @override
  String get progressDead => '意外停止';

  @override
  String get progressQuiet => '尚無輸出';

  @override
  String get progressCostReported => '供應商回報的費用';

  @override
  String get progressCostNotional => '按訂閱標價估算，並非帳單';

  @override
  String get progressCostMixed => '混合費用來源';

  @override
  String get progressCostEstimated => '預估費用';

  @override
  String progressDurationSeconds(String seconds) {
    return '$seconds 秒';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return '模型：$model · 時長：$duration · 費用：$cost';
  }

  @override
  String progressStartedAt(String time) {
    return '開始於 $time';
  }

  @override
  String progressLiveness(String state) {
    return '健康狀態：$state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return '輸入：$input · 輸出：$output 個 token';
  }

  @override
  String get progressOutputPreviewLimited => '僅顯示結構化輸出的前 6,000 個字元。';

  @override
  String progressRetryOf(String runId) {
    return '重試執行 $runId';
  }

  @override
  String get progressContext => '上下文與限制';

  @override
  String get progressNoAgent => '沒有可查看的代理';

  @override
  String progressContextReading(String used, String window) {
    return '$used/$window 個 token';
  }

  @override
  String get progressMeasured => '供應商回報的最近一次呼叫上下文用量';

  @override
  String get progressEstimated => '根據已儲存的對話和持久上下文估算';

  @override
  String get progressContextUnknown => '尚未回報上下文用量';

  @override
  String progressContextPercent(String percent) {
    return '占上下文視窗的 $percent%';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return '已設定的代理月度上限：$amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return '已儲存的目前對話：約 $tokens 個 token';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return '$agent 的持久上下文 · $model';
  }

  @override
  String get progressContextSystem => '系統提示';

  @override
  String get progressContextRules => '規則';

  @override
  String get progressContextSkills => '技能';

  @override
  String get progressContextTools => '工具定義';

  @override
  String get progressContextMcp => 'MCP 工具';

  @override
  String get progressContextDeferred => '延遲載入的工具';

  @override
  String get progressContextSubagents => '子代理';

  @override
  String get progressContextRunner => '外部執行器';

  @override
  String get progressContextMemory => '記憶';

  @override
  String get progressContextHistory => '對話歷史';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens 個 token';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens 個 token';
  }

  @override
  String get progressOutputs => '最近的輸出';

  @override
  String get progressNoOutputs => '尚無近期代理輸出';

  @override
  String get progressStructuredOutputsAbove => '結構化執行輸出顯示在上方的代理執行紀錄中。';

  @override
  String get progressRecentOutputsOnly => '僅顯示近期訊息。要查看更早的工作，請開啟對話。';

  @override
  String get progressPlan => '規劃';

  @override
  String get progressArtifact => '成品';

  @override
  String get progressResult => '結果';

  @override
  String get progressHideArtifact => '隱藏成品';

  @override
  String get progressReadArtifact => '查看成品';

  @override
  String get progressArtifactUnavailable => '成品已不可用';

  @override
  String get progressArtifactPreviewLimited => '僅顯示此成品的部分預覽。';

  @override
  String get progressDiagramSource => '圖表原始碼';

  @override
  String progressOpenAttachment(String name) {
    return '開啟 $name';
  }

  @override
  String get progressOpenPlan => '開啟計畫';

  @override
  String progressOpenDiff(String label) {
    return '查看已更改的檔案：$label';
  }

  @override
  String get progressViewMessage => '查看訊息';

  @override
  String get pushTitle => '背景通知';

  @override
  String get pushIntro => '即使應用程式已關閉，有需要你留意的事也能收到私人通知。詳細內容只會透過加密連線顯示。';

  @override
  String get pushLoading => '正在檢查通知設定…';

  @override
  String get pushError => '無法更新通知。請檢查連線後重試。';

  @override
  String get pushEnable => '啟用通知';

  @override
  String get pushDisable => '關閉通知';

  @override
  String get pushQuiet => '暫停此裝置上的提醒';

  @override
  String get pushCategories => '通知我以下事項';

  @override
  String get pushCategoryAgents => '代理';

  @override
  String get pushCategoryMessages => '訊息';

  @override
  String get pushCategoryPullRequests => 'Pull requests';

  @override
  String get pushCategoryTickets => '工單';

  @override
  String get pushCategoryCalendar => '行事曆';

  @override
  String get pushCategoryMachines => '機器';

  @override
  String get pushSecureOrigin => '通知需要 HTTPS。';

  @override
  String get pushInstallIos => '在 iPhone 或 iPad 上，請將此應用程式新增到主畫面並從主畫面開啟，以啟用通知。';

  @override
  String get pushUnsupported => '此瀏覽器不支援背景通知。';

  @override
  String get pushDenied => '瀏覽器設定已阻止通知。請在設定中允許通知後繼續。';

  @override
  String get pushResubscribe => '重新連接通知';

  @override
  String get pushStatusEnabled => '此裝置已開啟通知。';

  @override
  String get pushStatusDisabled => '此裝置已關閉通知。';

  @override
  String get credentialsTitle => '連線與憑證';

  @override
  String get credentialsIntro => '連接執行任務與整合功能使用的帳戶。機密資訊儲存在伺服器上，而非這支手機。';

  @override
  String get credentialsModelProviders => '模型供應商';

  @override
  String get credentialsOwnerOnly => '只有伺服器擁有者能新增、登入或移除模型供應商憑證。這些金鑰由各工作區共用。';

  @override
  String get credentialsContactOwner => '請聯絡伺服器擁有者，連接執行受阻時所需的供應商。';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'Claude Code 須透過主機上的 CLI 登入。請伺服器擁有者在主機終端機完成或更新帳戶登入；無法在這支手機上操作。';

  @override
  String get credentialsYourForgeAccounts => '你的程式碼代管平台帳戶';

  @override
  String get credentialsYourTicketingAccount => '你的工單平台帳戶';

  @override
  String get credentialsLocalTicketsNoLogin => '本機工單無須登入。如果工作區使用 Linear，請在此連線。';

  @override
  String get credentialsMembershipRequired =>
      '加入工作區後才能管理你的程式碼代管平台或工單平台憑證。請向工作區管理員申請存取權限。';

  @override
  String get credentialsSwitchWorkspace => '此連結指向另一個工作區。請切換到該工作區後再變更憑證。';

  @override
  String get credentialsReturnToInbox =>
      '連接憑證後，請返回收件匣重試受阻的執行任務。主機也會自動檢查等待中的執行任務。';

  @override
  String get credentialsLoadFailed => '無法載入連線。請檢查伺服器連線後重試。';

  @override
  String get credentialsOperationFailed => '無法變更此連線。請檢查伺服器連線、存取權限和憑證，然後重試。';

  @override
  String get credentialsConnected => '已連線';

  @override
  String get credentialsNotConnected => '未連線';

  @override
  String credentialsSignedInAs(String username) {
    return '已登入為 $username';
  }

  @override
  String get credentialsAccount => '已連線的帳戶';

  @override
  String get credentialsStoredKey => '已儲存的金鑰';

  @override
  String get credentialsActive => '使用中';

  @override
  String get credentialsRemove => '移除';

  @override
  String get credentialsRemoveConfirm => '移除已儲存的憑證？之後可能需要重新登入。';

  @override
  String get credentialsApiKey => 'API 金鑰';

  @override
  String get credentialsApiKeyHint => '貼上供應商 API 金鑰';

  @override
  String get credentialsBrowserLogin => '透過瀏覽器登入';

  @override
  String get credentialsSignInAgain => '重新登入';

  @override
  String get credentialsWaitingForLogin => '正在等待瀏覽器授權…';

  @override
  String get credentialsLoginTimedOut => '登入已過期。請重新開始登入。';

  @override
  String get credentialsCopyCode => '複製代碼';

  @override
  String get credentialsDeviceCodeHint => '請在供應商頁面確認此代碼。伺服器完成登入前，請保持此畫面開啟。';

  @override
  String get credentialsPasteRedirect => '授權碼或重新導向 URL';

  @override
  String get credentialsPasteRedirectHint => '貼上供應商提供的代碼或完整重新導向 URL';

  @override
  String get credentialsCompleteLogin => '完成登入';

  @override
  String get credentialsRedirectUnavailable =>
      '無法從手機安全連線至此伺服器的瀏覽器回呼網址。請伺服器擁有者設定公開的 HTTPS 回呼網址，或改為新增權杖。';

  @override
  String get credentialsUpdateToken => '更新權杖';

  @override
  String get credentialsAddToken => '新增權杖';

  @override
  String get credentialsPersonalToken => '個人存取權杖';

  @override
  String get credentialsPersonalTokenHint => '貼上個人存取權杖';

  @override
  String get credentialsHostManaged =>
      '此連線來自伺服器應用程式或環境。只有伺服器擁有者能在該處變更；你仍可新增自己的權杖。';

  @override
  String get credentialsStopWatching => '停止監看';
}
