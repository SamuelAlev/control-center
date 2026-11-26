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
  String get teammate => '队友';

  @override
  String get systemSender => '系统';

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
  String get sentAttachmentUnavailable => '附件不可用';

  @override
  String get sentAttachmentLoadFailed => '无法加载附件';

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
  String get mobilePrSelectCommentLine => '选择要评论的行';

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
  String get permissionPrPublish => '更新或合并 pull request';

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
  String get permissionRemembered => '持续批准';

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
  String permissionTools(String tools) {
    return '工具：$tools';
  }

  @override
  String get permissionNotInEffect => '拒绝此操作时不生效';

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
  String mobileGoalFailures(String count) {
    return '连续失败次数：$count';
  }

  @override
  String get mobileGoalFailedDescription => '监督程序在多次运行失败后已停止。请查看对话了解详情。';

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
  String get transcriptToolTodos => '任务';

  @override
  String get transcriptToolSearchMemory => '搜索记忆';

  @override
  String get transcriptToolRenderMedia => '呈现媒体';

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
  String get pushDenied => '浏览器报告通知已被阻止。请检查此站点的权限以及浏览器或设备的通知设置，然后刷新页面。';

  @override
  String get pushOsHint => '浏览器本身也需要在设备的系统设置中获得显示通知的权限。';

  @override
  String get pushServiceUnavailable =>
      '浏览器的推送服务拒绝了订阅。部分浏览器（如 Brave）默认关闭此服务：请在浏览器的隐私设置中查找推送消息选项，然后重试。';

  @override
  String get pushWorkerUnavailable => '无法在此浏览器中启动通知服务。请重新加载页面后重试。';

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
  String get credentialsConnectCodePrompt => '确认码';

  @override
  String get credentialsConnectCodeMalformed => '这看起来不像登录代码。代码由 8 个字母和数字组成。';

  @override
  String get credentialsSignInInvalidCode => '该代码与此次登录不匹配。请检查后重试。';

  @override
  String get credentialsSignInTooManyCodes => '错误代码次数过多。请重新开始登录。';

  @override
  String get credentialsSignInRetryLater => '登录服务当前没有响应。请等待一分钟后重试。';

  @override
  String get credentialsSignInRefused => '登录被拒绝。请重新开始并批准所有请求的权限。';

  @override
  String get credentialsSignInNotSaved => '登录成功，但服务器无法保存。请重试。';

  @override
  String credentialsSignInUnavailable(String provider) {
    return '此服务器尚未设置 $provider 登录。';
  }

  @override
  String get credentialsSignInPhoneUnreachable =>
      '无法从手机安全访问此服务器的登录回调地址。请在桌面应用中登录，或请服务器所有者设置公共 HTTPS 地址。';

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
  String get credentialsUpdateToken => '更新令牌';

  @override
  String get credentialsAddToken => '添加令牌';

  @override
  String get credentialsPersonalToken => '个人访问令牌';

  @override
  String get credentialsPersonalTokenHint => '粘贴个人访问令牌';

  @override
  String get credentialsStopWatching => '停止监测';

  @override
  String get transcriptClaudeSignInExpiredTitle => 'Claude Code 登录已过期';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      '运行已停止，因为其账户无法再通过身份验证。请重新登录，然后重试此轮。';

  @override
  String get transcriptSignInExpiredTitle => '提供方登录已过期';

  @override
  String get transcriptSignInExpiredBody =>
      '运行已停止，因为其提供方凭据已失效。请在 设置 → 提供方 中重新连接，然后重试此轮。';

  @override
  String get permissionHostExecution => '在主机上运行命令';

  @override
  String credentialsSignInLapsed(String provider) {
    return '你的 $provider 登录已失效。请重新登录。';
  }

  @override
  String get credentialsSignInPaused => '已暂停：此工作区的登录服务已更改。服务恢复后即可再次使用。';

  @override
  String credentialsProviderUnreachable(String provider) {
    return '暂时无法连接 $provider，正在重试。';
  }

  @override
  String get credentialsScopeWorkspace => '仅此工作区';

  @override
  String get credentialsScopeAllWorkspaces => '所有工作区';

  @override
  String get credentialsRemoveConfirmWorkspace =>
      '要从此工作区移除你保存的凭据吗？其他工作区会保留各自的凭据。';

  @override
  String get credentialsRemoveConfirmAllWorkspaces => '要从共享它的所有工作区移除你保存的凭据吗？';

  @override
  String get credentialsSignInServerRestarted => '服务器已重启。请重新开始登录。';

  @override
  String repoAccessInstallApp(String owner, String names) {
    return '在 $owner 上安装 GitHub App，让自动化可以访问 $names。轻点即可打开 GitHub。';
  }

  @override
  String repoAccessAskAdminInstall(String owner, String names) {
    return '$owner 上未安装 GitHub App，因此自动化无法访问 $names。请联系工作区管理员安装。';
  }

  @override
  String repoAccessAddToApp(String names) {
    return '将 $names 添加到 GitHub App 的仓库。轻点即可打开 GitHub。';
  }

  @override
  String repoAccessAskAdminAdd(String names) {
    return 'GitHub App 还看不到 $names。请联系工作区管理员将它们添加到 App 的仓库。';
  }

  @override
  String repoAccessSuspended(String names) {
    return 'GitHub App 安装已被暂停。在账号所有者于 GitHub 上恢复安装之前，$names 的自动化已暂停。';
  }

  @override
  String repoAccessOwnerCannotSee(String names) {
    return '此工作区自动化的负责人已无法看到 $names，因此不会再代表其在那里运行任何内容。';
  }

  @override
  String repoAccessOwnerNotSignedIn(String names) {
    return '此工作区自动化的负责人尚未登录代码托管平台，因此 $names 的自动化会等待其登录。';
  }

  @override
  String repoAccessRetrying(String names) {
    return '无法检查对 $names 的访问权限，正在重试。';
  }

  @override
  String hiddenReposSignIn(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '登录 $forge 即可查看另外 $count 个仓库的 pull request',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoForgeAccess(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 个仓库已隐藏，因为你的 $forge 账号看不到它们',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoGrant(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 个仓库已隐藏，因为你在此工作区中没有访问权限',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposChecking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '正在检查你对另外 $count 个仓库的访问权限…',
    );
    return '$_temp0';
  }

  @override
  String get credentialsAtlassianEmail => 'Atlassian 账号邮箱';

  @override
  String get credentialsAtlassianEmailInvalid => '请输入你的 Atlassian 账号邮箱地址。';

  @override
  String get credentialsBitbucketApiToken => 'API 令牌';

  @override
  String repoAccessAutomationTokenMissing(String names) {
    return '没有任何自动化令牌可以读取 $names，因此那里的后台工作已暂停。管理员可以在“设置 → 仓库”中添加一个。';
  }

  @override
  String get credentialsSignInConfirmInBrowser => '请在浏览器中确认，然后输入其显示的代码。';

  @override
  String get credentialsSignInAccountAlreadyBound =>
      '此账户已连接到此服务器上的另一位用户。请使用其他账户登录。';

  @override
  String credentialsTokenUnreachable(String provider) {
    return '无法连接 $provider 来检查此令牌。请稍后再试。';
  }

  @override
  String credentialsTokenRejected(String provider) {
    return '$provider 不接受此令牌。请检查是否完整复制，以及它是否未被撤销。';
  }

  @override
  String credentialsTokenWrongKind(String provider) {
    return '这不是个人令牌。请粘贴你自己 $provider 账户中的个人访问令牌，而不是项目、群组、工作区或机器人令牌。';
  }

  @override
  String credentialsTokenNarrowScope(String scope) {
    return '此令牌缺少 $scope 权限范围，而评审和评论需要该权限。请创建包含该权限的令牌。';
  }

  @override
  String get credentialsTokenExpired => '此令牌已过期。请创建新令牌并粘贴到此处。';

  @override
  String get credentialsSignInRateLimited => '当前请求过多。请稍等片刻后重试。';

  @override
  String get credentialsSignInCancelled => '登录已取消或被拒绝。准备好后请重新开始。';

  @override
  String get credentialsSignInNoLongerOpen => '此次登录已不再有效：它已被取消、使用或替换。请重新开始。';

  @override
  String get noWorkspacesYetHint => '需要工作区管理员邀请你，或服务器所有者为你创建工作区。';

  @override
  String repoAccessReplaced(String repos, String forge) {
    return '$repos 现在指向 $forge 上的另一个仓库。如需继续使用，请在桌面端或 Web 应用中重新关联。';
  }

  @override
  String repoAccessAskAdminRelink(String repos, String forge) {
    return '$repos 现在指向 $forge 上的另一个仓库。工作区管理员需要先重新关联，才能再次使用。';
  }

  @override
  String get runSandboxUnavailableTitle => '智能体需要此服务器上的沙箱';

  @override
  String get runSandboxUnavailable =>
      '此服务器没有沙箱，因此只有其所有者可以在此运行智能体。所有者可以安装沙箱，或为所有人关闭沙箱。';

  @override
  String get scriptToolCalls => '工具调用';

  @override
  String scriptCallCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 次调用',
      one: '1 次调用',
    );
    return '$_temp0';
  }

  @override
  String scriptCallsRunning(int count) {
    return '$count 个运行中';
  }

  @override
  String scriptCallsOk(int count) {
    return '$count 成功';
  }

  @override
  String scriptCallsFailed(int count) {
    return '$count 失败';
  }

  @override
  String scriptCallsDenied(int count) {
    return '$count 已拒绝';
  }

  @override
  String scriptCallsCancelled(int count) {
    return '$count 已取消';
  }

  @override
  String scriptCallsQueued(int count) {
    return '$count 排队中';
  }

  @override
  String scriptCallsSkipped(int count) {
    return '$count 已跳过';
  }

  @override
  String get scriptStepQueued => '排队中';

  @override
  String get scriptStepSkipped => '已跳过';

  @override
  String get scriptGroupLoop => '循环';

  @override
  String get scriptGroupEach => '每一项';

  @override
  String get scriptGroupParallel => '并行';

  @override
  String get scriptGroupFunction => '函数';

  @override
  String scriptCallsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '再显示 $count 次调用',
      one: '再显示 1 次调用',
    );
    return '$_temp0';
  }

  @override
  String get scriptCallsUnplaced => '未能放入脚本中的调用';

  @override
  String get scriptToolComputed => '工具';

  @override
  String scriptStepSemantics(String subject, String state) {
    return '$subject，$state';
  }

  @override
  String get scriptSourceLabel => '脚本';

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
  String get scriptStateRunning => '运行中';

  @override
  String get scriptStateCompleted => '已完成';

  @override
  String get scriptStateFailed => '失败';

  @override
  String get scriptStateTimedOut => '已超时';

  @override
  String get scriptStateCancelled => '已取消';

  @override
  String get scriptStateMemoryExceeded => '内存不足';

  @override
  String get scriptStateOutputExceeded => '输出过多';

  @override
  String get scriptStateSandboxError => '沙箱错误';

  @override
  String get scriptStateRefused => '已拒绝';

  @override
  String get scriptOriginLine => '来自智能体正在运行的脚本';

  @override
  String get codeModeTitle => '代码模式';

  @override
  String get codeModeAvailable => '可用';

  @override
  String get codeModeUnavailable => '不可用';

  @override
  String codeModeUnavailableNote(String reason) {
    return '此服务器无法运行脚本，因此这里的智能体会逐个调用其工具。服务器说明：$reason';
  }

  @override
  String get codeModeNoReason => '未提供原因。';

  @override
  String get workKindUnknown => '出于此版本无法识别的原因：';

  @override
  String get workRefusalUnknown => '服务器拒绝了此操作：';

  @override
  String workActionFailed(String error) {
    return '操作未成功：$error';
  }

  @override
  String get wakeKindStopped => '有人停止了这次运行，因此已挂起。';

  @override
  String get wakeKindAttempts => '投递失败三次。';

  @override
  String get wakeKindAgentDeleted => '该智能体已不存在。';

  @override
  String get wakeKindAgentNotDispatchable => '该智能体已退役。';

  @override
  String get wakeKindAgentPaused => '该智能体已暂停。';

  @override
  String get wakeKindPersonRemoved => '其所代表的人员已离开工作区。';

  @override
  String get wakeKindBudgetBlocked => '预算阻止了运行。';

  @override
  String get wakeKindTakeOver => '有人已接管该工作树。';

  @override
  String get wakeKindRateCapConversation => '此会话在过去一小时内因唤醒启动了 30 次运行。';

  @override
  String get wakeKindRateCapWorkspace => '此工作区在过去一小时内因唤醒启动了 300 次运行。';

  @override
  String get wakeKindLiveRunNoInput => '该智能体在此处的实时运行不接受输入。';

  @override
  String get wakeKindLiveRunOtherOptions => '该智能体在此处的实时运行方式不同，因此这将在它之后启动自己的运行。';

  @override
  String get wakeKindLiveRunOtherPerson => '该智能体在此处的实时运行代表他人，因此这将在它之后启动自己的运行。';

  @override
  String get wakeKindDispatchRefused => '运行无法启动。';

  @override
  String get wakeKindSandboxUnavailable => '没有可用于只读运行的沙箱。';

  @override
  String get wakeKindReadOnlyUnavailable => '此智能体的后端无法保持只读运行。';

  @override
  String get wakeKindServerStopped => '服务器重启停止了该运行。';

  @override
  String get wakeKindServerRestarted => '人员运行期间服务器已重启。';

  @override
  String get wakeKindGuardFailed => '投递前的检查失败。';

  @override
  String get wakeKindLimit => '正在等待提供商的用量限额重置。';

  @override
  String get wakeKindLimitRunLive => '正在等待达到用量限额的运行结束。';

  @override
  String get wakeKindWakeMissed => '服务器关闭期间错过。';

  @override
  String get wakeKindPipelineRunEnded => '其流水线运行已结束。';

  @override
  String get wakeKindGoalEnded => '其目标已结束。';

  @override
  String get wakeKindGoalBudgetExhausted => '其目标已用完预算。';

  @override
  String get wakeKindGoalReviewStale => '自请求此评审以来，目标已发生变更。';

  @override
  String get wakeKindGoalPaused => '其目标已暂停。';

  @override
  String get wakeKindGoalHeld => '其目标已搁置。';

  @override
  String get wakeKindGoalStopped => '其目标已停止。';

  @override
  String get wakeKindAskSettled => '它所回答的问题已经有了结论。';

  @override
  String get wakeKindRuleEnded => '其定时已结束。';

  @override
  String get wakeRefusalNotYours => '此唤醒代表另一人。只有对方可以投递或继续它。';

  @override
  String get wakeRefusalSettled => '此唤醒已经结束。';

  @override
  String get goalRefusalAlreadyActive => '此智能体已有一个进行中的目标。';

  @override
  String get goalRefusalNotInReview => '此目标未在等待评审。';

  @override
  String get goalRefusalEvidenceIncomplete => '目标的证据不完整。';

  @override
  String get goalRefusalClaimPending => '关于其已完成的声明仍在检查中。';

  @override
  String get goalRefusalNotActiveSegment => '此目标没有正在运行的段。';

  @override
  String get goalRefusalNotYours => '只有发起此目标的人可以执行该操作。';

  @override
  String get goalRefusalNotPaused => '请先暂停目标。';

  @override
  String get goalRefusalContractInvalid => '无法读取目标的约定。';

  @override
  String get goalRefusalCheckerUnknown => '没有名为此的智能体。';

  @override
  String get goalRefusalCheckerAmbiguous => '有多个智能体使用此名称。';

  @override
  String get goalRefusalCheckerIsGoalAgent => '检查器必须是执行工作的智能体以外的另一个智能体。';

  @override
  String get goalRefusalCommandInvalid => '无法读取此目标：';

  @override
  String get wakeRuleRefusalIntervalTooShort => '间隔太短。请至少选择一分钟。';

  @override
  String get wakeRuleRefusalTooSoon => '该时间太近。请选择更晚的时间。';

  @override
  String get wakeRuleRefusalLineageEnded => '这一串唤醒已用完其运行次数或时间。';

  @override
  String get wakeRuleRefusalWatchTargetUnreadable => '你无法读取此监视的对象。';

  @override
  String get wakeRuleRefusalExpiryRequired => '请设置结束日期或运行次数。';

  @override
  String get wakeRuleRefusalLimitReached => '此会话或智能体的定时数量已达上限。';

  @override
  String get wakeRuleRefusalInvalidWhen => '无法识别该时间。';

  @override
  String get wakeRuleRefusalNoteTooLong => '便签太长。';

  @override
  String get wakeRuleRefusalExpiryTooLong => '结束时间太远。';

  @override
  String get wakeRuleRefusalLimitOutOfRange => '运行次数、天数或预算上限超出范围。';

  @override
  String get wakeRuleRefusalNextOutsideLoop => '只有循环可以自行选择下一次时间。';

  @override
  String get wakeRuleRefusalWatchRefused => '无法监视该对象。';

  @override
  String get wakeRuleRefusalRuleEnded => '该定时已结束。';

  @override
  String get wakeRuleRefusalNotYours => '该定时属于其他人。';

  @override
  String get wakeRuleEndFired => '已运行其唯一一次。';

  @override
  String get wakeRuleEndExpired => '已到达其结束日期。';

  @override
  String get wakeRuleEndRunCap => '已用完其运行次数。';

  @override
  String get wakeRuleEndCostCap => '已达到其费用上限。';

  @override
  String get wakeRuleEndGoalEnded => '其目标已结束。';

  @override
  String get wakeRuleEndCancelled => '已被取消。';

  @override
  String get wakeRuleEndMemberRemoved => '其所属人员已离开工作区。';

  @override
  String get wakeRuleEndInvalidRow => '无法读取其已存储的设置。';

  @override
  String goalHoldWorking(int segment) {
    final intl.NumberFormat segmentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String segmentString = segmentNumberFormat.format(segment);

    return '正在处理第 $segmentString 段。无需任何人操作。';
  }

  @override
  String get goalHoldWaiting => '正在等待它应得的工作。它将自行继续。';

  @override
  String goalHoldWaitingUntil(String time) {
    return '正在等待它应得的工作。最迟将于 $time 自行继续。';
  }

  @override
  String get goalHoldVerifying => '它声称已完成。服务器正在运行其检查，然后由评审者决定。';

  @override
  String get goalHoldLimit => '已在提供商的用量限额处暂停。重置后将自行继续。';

  @override
  String goalHoldLimitUntil(String time) {
    return '已在提供商的用量限额处暂停。将于 $time 自行继续。';
  }

  @override
  String get goalHoldPerson => '正在等待有人在会话中回答。有人回答后将继续。';

  @override
  String get goalHoldByPerson => '已由人工暂停。在有人继续它之前将保持暂停。';

  @override
  String get goalHoldNeedsReview => '等待评审：它无法自行继续。请将其批准为已完成、继续或取消。';

  @override
  String get goalHoldBudget => '它已用完预算。请提高预算以让它继续。';

  @override
  String goalHoldLimitParks(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return '用量限额暂停：$countString / $maxString';
  }

  @override
  String get goalHoldDetailStalled => '最近几段没有任何进展。';

  @override
  String get goalHoldDetailStalledWaiting => '它在同一项工作上等待了 24 小时，没有任何进展。';

  @override
  String get goalHoldDetailVerificationFailed => '上次检查失败。';

  @override
  String get goalHoldDetailCannotVerify => '检查器无法判断它是否已完成。';

  @override
  String get goalHoldDetailSandboxUnavailable => '没有可用于运行其检查的沙箱。';

  @override
  String get goalHoldDetailCheckerUnavailable => '其检查器智能体不可用。请选择另一个检查器，然后继续。';

  @override
  String get goalHoldDetailCheckBroken => '此检查无法运行：';

  @override
  String get goalHoldDetailWakeSkipped => '其唤醒未被投递。';

  @override
  String get goalHoldDetailClaimPending => '其已完成的声明正在等待检查。';

  @override
  String get goalHoldDetailUnanswered => '发给某人的问题或批准请求未得到回应。';

  @override
  String get goalHoldDetailLimitParks => '它过于频繁地触及用量限额。请检查后再继续。';

  @override
  String get goalHoldDetailInput => '正在等待此会话中的回答。';

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

    return '第 $runString 段，共 $maxString 段';
  }

  @override
  String goalSegmentsNoCap(int run) {
    final intl.NumberFormat runNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String runString = runNumberFormat.format(run);

    return '第 $runString 段，无上限';
  }

  @override
  String goalMoney(String spent, String cap) {
    return '已花费 $spent，上限为 $cap';
  }

  @override
  String goalDeadline(String time) {
    return '截止于 $time';
  }

  @override
  String get goalPipelineStep => '一个流水线步骤正在推进此目标。';

  @override
  String get goalSummaryHeading => '最近的摘要';

  @override
  String get goalDoneMeans => '完成标准';

  @override
  String get goalChecks => '检查';

  @override
  String get goalBoundaries => '边界';

  @override
  String get goalStopWhen => '以下情况下停止并询问';

  @override
  String get goalNoMachineCheck => '没有机器检查。评审者将根据其能读取的内容作出判断。';

  @override
  String get goalCheckEnvironment => '环境任务';

  @override
  String goalLastCheck(int round, String time) {
    final intl.NumberFormat roundNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String roundString = roundNumberFormat.format(round);

    return '上次检查，第 $roundString 轮，$time';
  }

  @override
  String get goalClaim => '它的声明';

  @override
  String get goalCheckPassed => '已通过';

  @override
  String goalCheckFailed(int code) {
    return '失败，退出码 $code';
  }

  @override
  String get goalCheckTimedOut => '已超时';

  @override
  String get goalCheckNotRerun => '未重新运行：没有任何变化';

  @override
  String get goalCheckBroken => '无法运行';

  @override
  String get goalCriterionMet => '已满足';

  @override
  String get goalCriterionUnmet => '未满足';

  @override
  String get goalCriterionCannotTell => '无法判断';

  @override
  String get goalVerdictPass => '结论：已完成';

  @override
  String get goalVerdictFail => '结论：未完成';

  @override
  String get goalVerdictCannotVerify => '结论：无法判断';

  @override
  String get goalConcerns => '顾虑';

  @override
  String goalVerifiedBy(String agent) {
    return '由 $agent 验证';
  }

  @override
  String get goalVerifiedBySelf => '由其自身验证（没有单独的检查器）';

  @override
  String get goalClosedByPerson => '由人工在没有通过检查的情况下关闭';

  @override
  String get goalApprove => '批准完成';

  @override
  String get goalApproveTitle => '将此目标标记为已完成并关闭？';

  @override
  String get goalApproveBody => '没有任何检查确认它。你将凭自己的判断关闭它，目标会记录为人工在未验证的情况下关闭。';

  @override
  String get goalApproveConfirm => '标记为已完成';

  @override
  String get goalResumeNotYours => '继续它或提高其预算，只能由发起它的人操作。';

  @override
  String get goalChooseChecker => '选择另一个检查器';

  @override
  String goalCheckerSet(String agent) {
    return '现在由 $agent 检查。继续以重新验证。';
  }

  @override
  String get goalSchedules => '定时';

  @override
  String get goalRepeat => '重复';

  @override
  String get goalCreateChecks => '检查（可选）';

  @override
  String get goalCreateCheckHint => '工作完成时通过的命令';

  @override
  String get goalCreateAddCheck => '添加检查';

  @override
  String get goalCreateRemoveCheck => '删除检查';

  @override
  String get goalCreateSegmentCap => '段数上限（可选）';

  @override
  String get goalCreateSegmentInvalid => '段数上限须为至少为 1 的整数。';

  @override
  String get scheduleCreateTitle => '重复一个提示';

  @override
  String get scheduleCadence => '频率';

  @override
  String get scheduleEveryMinutes => '每 N 分钟';

  @override
  String get scheduleEveryHours => '每 N 小时';

  @override
  String get scheduleSelfPaced => '由智能体决定';

  @override
  String get scheduleSelfPacedHint => '每次运行后，由智能体在 1 分钟到 1 小时之间选择延迟时间。';

  @override
  String get scheduleInterval => '间隔';

  @override
  String get scheduleNote => '每次运行应该做什么？';

  @override
  String get scheduleCostCap => '费用上限（美元，可选）';

  @override
  String get scheduleExpiryDays => '结束于 N 天后（可选）';

  @override
  String get scheduleCreateInvalid => '请选择空间和智能体，写明每次运行应做什么，并填写至少为 1 的整数。';

  @override
  String get scheduleCreateButton => '启动定时';

  @override
  String get scheduleCreateConfirmTitle => '启动此定时？';

  @override
  String scheduleCreateConfirmEveryMinutes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '将从现在开始，每 $countString 分钟运行一次。',
      one: '将从现在开始，每分钟运行一次。',
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
      other: '将从现在开始，每 $countString 小时运行一次。',
      one: '将从现在开始，每小时运行一次。',
    );
    return '$_temp0';
  }

  @override
  String get scheduleCreateConfirmSelfPaced => '现在运行一次，然后由智能体决定何时再次运行。';

  @override
  String get scheduleCreated => '定时已启动。它已列在“定时”下。';

  @override
  String get schedulesTitle => '定时';

  @override
  String get schedulesLoadFailed => '无法加载定时';

  @override
  String get schedulesEmpty => '没有定时或监视';

  @override
  String get schedulesEmptyDescription =>
      '可以在目标页面重复一个提示，或在会话中发送 /loop 或 /schedule。';

  @override
  String get scheduleMissing => '此定时在此工作区中已不可用。';

  @override
  String scheduleEvery(String interval) {
    return '每 $interval';
  }

  @override
  String get scheduleSelfPacedLoop => '由智能体决定的循环';

  @override
  String get scheduleCron => 'Cron 定时';

  @override
  String scheduleOnce(String time) {
    return '$time 运行一次';
  }

  @override
  String scheduleWatch(String event) {
    return '监视：$event';
  }

  @override
  String get scheduleWatchPrChecks => 'pull request 的检查';

  @override
  String get scheduleWatchPrReview => 'pull request 的评审';

  @override
  String get scheduleWatchPrMerged => 'pull request 合并';

  @override
  String get scheduleWatchEnvironment => '环境';

  @override
  String get scheduleWatchTicket => '工单';

  @override
  String get scheduleWatchPipelineRun => '流水线运行';

  @override
  String get scheduleStatusActive => '进行中';

  @override
  String get scheduleStatusPaused => '已暂停';

  @override
  String get scheduleStatusEnded => '已结束';

  @override
  String scheduleWakes(String agent) {
    return '唤醒 $agent';
  }

  @override
  String scheduleNext(String time) {
    return '下次运行 $time';
  }

  @override
  String scheduleLast(String time) {
    return '上次运行 $time';
  }

  @override
  String scheduleRuns(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString 次运行',
      one: '1 次运行',
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

    return '$countString / $maxString 次运行';
  }

  @override
  String scheduleSkipped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '跳过 $countString 次',
      one: '跳过 1 次',
    );
    return '$_temp0';
  }

  @override
  String scheduleEnds(String time) {
    return '结束于 $time';
  }

  @override
  String scheduleChain(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '属于一个链：剩余 $countString 次运行，结束于 $time';
  }

  @override
  String get scheduleNoteAgent => '智能体自己的便签，以其自己的话：';

  @override
  String get scheduleNotePerson => '某人的便签：';

  @override
  String scheduleActsFor(String name) {
    return '代表 $name';
  }

  @override
  String get scheduleActsForBot => '不代表任何人';

  @override
  String get scheduleGoalBound => '它将随其目标一同结束。';

  @override
  String get schedulePause => '暂停';

  @override
  String get scheduleResume => '继续';

  @override
  String get scheduleDelete => '删除';

  @override
  String get scheduleRemove => '移除';

  @override
  String get scheduleDeleteTitle => '删除此定时？';

  @override
  String get scheduleDeleteBody => '它将永久停止。已经完成的操作不会撤销。';

  @override
  String get scheduleRemoveTitle => '移除此定时？';

  @override
  String get scheduleRemoveBody => '它将从列表中消失。';

  @override
  String get scheduleResumeNotYours => '只有此定时所代表的人可以继续它。';

  @override
  String get scheduleResumeAdminOnly => '只有工作区管理员可以继续不属于任何人的定时。';

  @override
  String get scheduleOpenConversation => '打开会话';

  @override
  String get progressWaiting => '等待中';

  @override
  String get progressNothingWaiting => '没有任何等待项。';

  @override
  String get wakeOriginGoal => '目标';

  @override
  String get wakeOriginGoalCheck => '目标检查';

  @override
  String get wakeOriginGoalReview => '目标评审';

  @override
  String get wakeOriginSchedule => '定时';

  @override
  String get wakeOriginWatch => '监视';

  @override
  String get wakeOriginReply => '回复';

  @override
  String get wakeOriginMessage => '消息';

  @override
  String get wakeOriginWorkFinished => '已完成的工作';

  @override
  String get wakeOriginLimitReset => '用量限额重置';

  @override
  String get wakeOriginRecovery => '恢复';

  @override
  String get wakeOriginAssignment => '任务分配';

  @override
  String get wakeOriginPipelineStep => '流水线步骤';

  @override
  String get wakeOriginImprovementReview => '改进评审';

  @override
  String wakeOriginReplyFrom(String agent) {
    return '来自 $agent 的回复';
  }

  @override
  String wakeOriginMessageFrom(String agent) {
    return '来自 $agent 的消息';
  }

  @override
  String wakeOriginWorkFinishedBy(String agent) {
    return '$agent 完成的工作';
  }

  @override
  String wakeFor(String agent) {
    return '唤醒 $agent';
  }

  @override
  String wakeDue(String time) {
    return '$time 到期';
  }

  @override
  String get wakeDueNow => '现已到期';

  @override
  String get wakeHeld => '已挂起';

  @override
  String wakeExpires(String time) {
    return '$time 过期';
  }

  @override
  String wakeAttempt(int attempt) {
    final intl.NumberFormat attemptNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String attemptString = attemptNumberFormat.format(attempt);

    return '第 $attemptString 次尝试';
  }

  @override
  String get wakeCancel => '取消';

  @override
  String get wakeDeliverNow => '立即投递';

  @override
  String get wakeResume => '继续';

  @override
  String get wakeDismiss => '忽略';

  @override
  String get wakeResumeOnlyTheirs => '只有该运行的所属人员可以继续它。';

  @override
  String get wakeRecovery => '服务器在此次运行期间重启。请继续以恢复运行，或忽略。';

  @override
  String limitParkTitle(String provider, String time) {
    return '已在 $provider 的用量限制处暂停，该限制将于 $time 重置。运行将等待继续，重置后最多等待 7 天。';
  }

  @override
  String limitParkTitleUnnamed(String time) {
    return '已在提供商的用量限制处暂停，该限制将于 $time 重置。运行将等待继续，重置后最多等待 7 天。';
  }

  @override
  String get limitParkResumeNow => '立即继续';

  @override
  String get limitParkCancel => '取消';

  @override
  String limitParkResumed(String provider) {
    return '$provider 用量限额解除后已继续。';
  }

  @override
  String limitParkGone(String provider) {
    return '不再因 $provider 的用量限额而等待。';
  }

  @override
  String get limitParkProviderUnknown => '该提供商';

  @override
  String get mobileHeldMessages => '挂起的消息';

  @override
  String get heldSteeringTitle => '运行在能接收这些消息之前已结束，因此它们被挂起。现在发送你的消息，或将其移除。';

  @override
  String get heldSteeringRelease => '发送挂起的消息';

  @override
  String get notifGoalCompleted => '目标已完成';

  @override
  String get notifGoalFailed => '目标失败';

  @override
  String get notifGoalCancelled => '目标已取消';

  @override
  String get notifGoalBudgetExhausted => '目标已用完预算';

  @override
  String get notifGoalNeedsReview => '有一个目标等待你评审';

  @override
  String get notifGoalNeedsPerson => '有一个目标需要你处理';

  @override
  String get notifGoalOnHold => '有一个目标已搁置';

  @override
  String get notifWakeRuleEnded => '有一个定时已结束';

  @override
  String notifWaitingDigest(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $countString 件事等待你处理',
      one: '有 1 件事等待你处理',
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
      other: '已提出 $countString 项改进',
      one: '已提出 1 项改进',
    );
    return '$_temp0';
  }

  @override
  String get notifPipelineRunHeld => '一次流水线运行因预算而暂停';

  @override
  String notifPipelineRunHeldBody(String spent, String cap) {
    return '已花费 $spent，上限为 $cap';
  }

  @override
  String get notifNeedsYou => '需要你处理';

  @override
  String get notifDigestGoalReview => '目标等待评审';

  @override
  String get notifDigestGoalPerson => '目标需要人工处理';

  @override
  String get notifDigestHeldWake => '已挂起的唤醒';

  @override
  String get notifDigestImprovement => '已提议的改进';

  @override
  String get wakeKindRulePaused => '其定时已暂停。';

  @override
  String get wakeKindRuleBusy => '智能体正忙，而此定时会在这种情况下跳过。';

  @override
  String get wakeKindRuleFolded => '后续事件已取代它。';

  @override
  String get wakeKindRuleSuperseded => '其定时的更晚时间取代了它。';

  @override
  String get wakeKindRuleNotified => '其定时只发送通知，因此没有启动运行。';

  @override
  String get wakeKindRuleLimitParked => '其定时正在等待提供商的用量限额重置。';

  @override
  String get improvementRefusalCooldown => '不久前刚在此会话中进行过一次改进评审。请稍后再试。';

  @override
  String get improvementRefusalQueued => '此会话的评审已在排队等待运行。';

  @override
  String get improvementRefusalAgentNotFound => '该智能体不属于此工作区。';

  @override
  String get steeringRefusalHeldByLimit => '在用量限额处挂起的消息无法手动发送。它们将等待暂停的运行继续。';

  @override
  String limitParkCancelled(String provider) {
    return '$provider 用量限额处的等待已取消。';
  }

  @override
  String limitParkExpired(String provider) {
    return '$provider 用量限额处的等待已过期，运行尚未继续。';
  }

  @override
  String limitParkSkipped(String provider) {
    return '运行未能在 $provider 用量限额解除后继续。';
  }

  @override
  String get heldSteeringLimitTitle =>
      '运行等待用量限制重置期间，这些消息已挂起。它们会在该运行所服务的人继续运行时发送。';

  @override
  String heldSteeringLimitAt(String time) {
    return '在用量限制于 $time 重置前将保持挂起。它们会在该运行所服务的人继续运行时发送。';
  }

  @override
  String get heldSteeringOtherTitle => '由服务器挂起。你可以移除它们。';

  @override
  String workRowWoke(int count, String agent) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已为 $countString 个等待项唤醒 $agent',
      one: '已唤醒 $agent',
    );
    return '$_temp0';
  }

  @override
  String workRowWakeMissed(String agent) {
    return '服务器关闭期间错过了给 $agent 的唤醒。';
  }

  @override
  String workRowWakeSkipped(String agent) {
    return '未投递给 $agent 的唤醒。';
  }

  @override
  String workRowScheduleCreated(String agent) {
    return '已为 $agent 设置定时。';
  }

  @override
  String workRowScheduleEnded(String agent) {
    return '$agent 的定时已结束。';
  }

  @override
  String workRowNoteFromAgent(String agent) {
    return '来自 $agent 的定时便签：';
  }

  @override
  String get workRowNoteFromPerson => '来自某人的定时便签：';

  @override
  String workRowCommandRefusedNamed(String command) {
    return '$command 命令已被拒绝。';
  }

  @override
  String get workRowCommandRefused => '命令已被拒绝。';

  @override
  String workRowCapRaised(String person, String from, String to) {
    return '$person 已将流水线的花费上限从 $from 提高到 $to。';
  }

  @override
  String workRowCapRaisedNoAmounts(String person) {
    return '$person 已提高流水线的花费上限。';
  }

  @override
  String get workRowApplyIncomplete => '对此技能的已接受变更无法完成，因为该技能在此期间已被更改。此提议已回滚。';

  @override
  String get workRowOpenSchedule => '打开定时';

  @override
  String get heldSteeringOthersTitle =>
      '运行在能接收这些消息之前已结束，因此它们被挂起。只有撰写消息的人可以发送它。';

  @override
  String get heldSteeringOnlyYours => '只发送你的消息。其他人的消息将等待其撰写者。';

  @override
  String heldSteeringWrittenBy(String name) {
    return '由 $name 撰写';
  }

  @override
  String get steeringRefusalNotYours => '只有挂起消息的撰写者可以发送它，而这些消息都不是你的。';

  @override
  String get steeringRefusalNeedsWrite => '你需要此空间仓库的写入权限，才能引导代表他人的运行。';

  @override
  String workRowSchedulePaused(String name, String agent) {
    return '$name 暂停了 $agent 的定时。';
  }

  @override
  String get goalVerdictObjective => '整个目标描述';

  @override
  String get notifDigestRequest => '等待你的回答';
}

/// The translations for Chinese, as used in Hong Kong (`zh_HK`).
class AppLocalizationsZhHk extends AppLocalizationsZh {
  AppLocalizationsZhHk() : super('zh_HK');

  @override
  String get failureUnreachable => '無法透過任何路徑連到你的伺服器 — 請確認伺服器正在執行，或改用相同網絡再試';

  @override
  String get systemSender => '系統';

  @override
  String get permissionPrPublish => '更新或合併 pull request';

  @override
  String get permissionRemembered => '持續核准';

  @override
  String get permissionNotInEffect => '此操作設為拒絕時不生效';

  @override
  String get credentialsConnectCodePrompt => '確認代碼';

  @override
  String get credentialsConnectCodeMalformed => '這看起來不像登入代碼。代碼由 8 個字母和數字組成。';

  @override
  String get credentialsSignInInvalidCode => '此代碼與這次登入不符。請檢查後再試一次。';

  @override
  String get credentialsSignInTooManyCodes => '錯誤代碼次數過多。請重新開始登入。';

  @override
  String get credentialsSignInRetryLater => '登入服務目前沒有回應。請等待一分鐘後再試一次。';

  @override
  String get credentialsSignInRefused => '登入遭到拒絕。請重新開始並核准所有要求的權限。';

  @override
  String get credentialsSignInNotSaved => '登入成功，但伺服器無法儲存。請再試一次。';

  @override
  String credentialsSignInUnavailable(String provider) {
    return '此伺服器尚未設定 $provider 登入。';
  }

  @override
  String get credentialsSignInPhoneUnreachable =>
      '無法從手機安全存取此伺服器的登入回傳地址。請在桌面應用程式中登入，或請伺服器擁有者設定公開的 HTTPS 地址。';

  @override
  String get permissionHostExecution => '在主機上執行指令';

  @override
  String credentialsSignInLapsed(String provider) {
    return '你的 $provider 登入已失效。請重新登入。';
  }

  @override
  String get credentialsSignInPaused => '已暫停：此工作區的登入服務已變更。服務恢復後即可再次使用。';

  @override
  String credentialsProviderUnreachable(String provider) {
    return '暫時無法連接 $provider，正在重試。';
  }

  @override
  String get credentialsScopeWorkspace => '僅限此工作區';

  @override
  String get credentialsScopeAllWorkspaces => '所有工作區';

  @override
  String get credentialsRemoveConfirmWorkspace =>
      '要從此工作區移除你儲存的憑證嗎？其他工作區會保留各自的憑證。';

  @override
  String get credentialsRemoveConfirmAllWorkspaces => '要從共用它的所有工作區移除你儲存的憑證嗎？';

  @override
  String get credentialsSignInServerRestarted => '伺服器已重新啟動。請重新開始登入。';

  @override
  String repoAccessInstallApp(String owner, String names) {
    return '在 $owner 上安裝 GitHub App，讓自動化可以存取 $names。輕觸即可開啟 GitHub。';
  }

  @override
  String repoAccessAskAdminInstall(String owner, String names) {
    return '$owner 上未安裝 GitHub App，因此自動化無法存取 $names。請聯絡工作區管理員安裝。';
  }

  @override
  String repoAccessAddToApp(String names) {
    return '將 $names 新增至 GitHub App 的存放庫。輕觸即可開啟 GitHub。';
  }

  @override
  String repoAccessAskAdminAdd(String names) {
    return 'GitHub App 還看不到 $names。請聯絡工作區管理員將它們新增至 App 的存放庫。';
  }

  @override
  String repoAccessSuspended(String names) {
    return 'GitHub App 安裝已暫停。在帳戶擁有者於 GitHub 上恢復安裝之前，$names 的自動化已暫停。';
  }

  @override
  String repoAccessOwnerCannotSee(String names) {
    return '此工作區自動化的負責人已無法看到 $names，因此不會再代表其在那裡執行任何內容。';
  }

  @override
  String repoAccessOwnerNotSignedIn(String names) {
    return '此工作區自動化的負責人尚未登入程式碼代管平台，因此 $names 的自動化會等待其登入。';
  }

  @override
  String repoAccessRetrying(String names) {
    return '無法檢查對 $names 的存取權限，正在重試。';
  }

  @override
  String hiddenReposSignIn(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '登入 $forge 即可查看另外 $count 個存放庫的 pull request',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoForgeAccess(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 個存放庫已隱藏，因為你的 $forge 帳戶看不到它們',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoGrant(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 個存放庫已隱藏，因為你在此工作區中沒有存取權限',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposChecking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '正在檢查你對另外 $count 個存放庫的存取權限…',
    );
    return '$_temp0';
  }

  @override
  String get credentialsAtlassianEmail => 'Atlassian 帳戶電子郵件';

  @override
  String get credentialsAtlassianEmailInvalid => '請輸入你的 Atlassian 帳戶電子郵件地址。';

  @override
  String get credentialsBitbucketApiToken => 'API 權杖';

  @override
  String repoAccessAutomationTokenMissing(String names) {
    return '沒有任何自動化權杖可以讀取 $names，因此那裡的背景工作已暫停。管理員可以在「設定 → 儲存庫」中加入一個。';
  }

  @override
  String get credentialsSignInConfirmInBrowser => '請在瀏覽器中確認，然後輸入它顯示的代碼。';

  @override
  String get credentialsSignInAccountAlreadyBound =>
      '此帳戶已連接到此伺服器上的另一位用戶。請使用其他帳戶登入。';

  @override
  String credentialsTokenUnreachable(String provider) {
    return '無法連接至 $provider 以檢查此權杖。請稍後再試。';
  }

  @override
  String credentialsTokenRejected(String provider) {
    return '$provider 不接受此權杖。請確認你已完整複製，且它未被撤銷。';
  }

  @override
  String credentialsTokenWrongKind(String provider) {
    return '這不是個人權杖。請貼上你自己 $provider 帳戶的個人存取權杖，而非專案、群組、工作區或機器人的權杖。';
  }

  @override
  String credentialsTokenNarrowScope(String scope) {
    return '此權杖缺少 $scope 範圍，而審查與留言需要它。請建立包含該範圍的權杖。';
  }

  @override
  String get credentialsTokenExpired => '此權杖已過期。請建立新的權杖並貼到這裡。';

  @override
  String get credentialsSignInRateLimited => '目前請求過多。請稍候一下，然後再試一次。';

  @override
  String get credentialsSignInCancelled => '登入已取消或遭拒絕。準備好時請再重新開始。';

  @override
  String get credentialsSignInNoLongerOpen => '此登入已不再開啟：它已被取消、使用或取代。請重新開始。';

  @override
  String get noWorkspacesYetHint => '工作區管理員必須邀請你，或伺服器擁有者可以為你建立工作區。';

  @override
  String repoAccessReplaced(String repos, String forge) {
    return '$repos 現在在 $forge 上指向另一個存放庫。請在桌面版或網頁版中重新連接，以繼續使用。';
  }

  @override
  String repoAccessAskAdminRelink(String repos, String forge) {
    return '$repos 現在在 $forge 上指向另一個存放庫。工作區管理員必須重新連接後，才能再次使用。';
  }

  @override
  String get runSandboxUnavailableTitle => '代理需要此伺服器上的沙箱';

  @override
  String get runSandboxUnavailable =>
      '此伺服器沒有沙箱，因此只有其擁有者可以在此執行代理。擁有者可以安裝沙箱，或為所有人關閉沙箱功能。';

  @override
  String get scriptToolCalls => '工具呼叫';

  @override
  String scriptCallCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 次呼叫',
      one: '1 次呼叫',
    );
    return '$_temp0';
  }

  @override
  String scriptCallsRunning(int count) {
    return '$count 個執行中';
  }

  @override
  String scriptCallsOk(int count) {
    return '$count 成功';
  }

  @override
  String scriptCallsFailed(int count) {
    return '$count 失敗';
  }

  @override
  String scriptCallsDenied(int count) {
    return '$count 已拒絕';
  }

  @override
  String scriptCallsCancelled(int count) {
    return '$count 已取消';
  }

  @override
  String scriptCallsQueued(int count) {
    return '$count 已排入佇列';
  }

  @override
  String scriptCallsSkipped(int count) {
    return '$count 已跳過';
  }

  @override
  String get scriptStepQueued => '已排入佇列';

  @override
  String get scriptStepSkipped => '已跳過';

  @override
  String get scriptGroupLoop => '循環';

  @override
  String get scriptGroupEach => '逐項';

  @override
  String get scriptGroupParallel => '並行';

  @override
  String get scriptGroupFunction => '函數';

  @override
  String scriptCallsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '再顯示 $count 次呼叫',
      one: '再顯示 1 次呼叫',
    );
    return '$_temp0';
  }

  @override
  String get scriptCallsUnplaced => '指令碼中未能定位的工具呼叫';

  @override
  String get scriptToolComputed => '工具';

  @override
  String scriptStepSemantics(String subject, String state) {
    return '$subject，$state';
  }

  @override
  String get scriptSourceLabel => '指令碼';

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
  String get scriptStateRunning => '執行中';

  @override
  String get scriptStateCompleted => '已完成';

  @override
  String get scriptStateFailed => '失敗';

  @override
  String get scriptStateTimedOut => '已逾時';

  @override
  String get scriptStateCancelled => '已取消';

  @override
  String get scriptStateMemoryExceeded => '記憶體不足';

  @override
  String get scriptStateOutputExceeded => '輸出過多';

  @override
  String get scriptStateSandboxError => '沙箱錯誤';

  @override
  String get scriptStateRefused => '已拒絕';

  @override
  String get scriptOriginLine => '來自代理正在執行的指令碼';

  @override
  String get codeModeTitle => '程式碼模式';

  @override
  String get codeModeAvailable => '可用';

  @override
  String get codeModeUnavailable => '無法使用';

  @override
  String codeModeUnavailableNote(String reason) {
    return '此伺服器無法執行指令碼，因此這裡的代理會逐一呼叫其工具。伺服器的說明：$reason';
  }

  @override
  String get codeModeNoReason => '未提供原因。';

  @override
  String get workKindUnknown => '此版本未能辨識的原因：';

  @override
  String get workRefusalUnknown => '伺服器拒絕了此操作：';

  @override
  String workActionFailed(String error) {
    return '操作未能完成：$error';
  }

  @override
  String get wakeKindStopped => '因有人停止了執行，故已保留。';

  @override
  String get wakeKindAttempts => '傳遞已失敗三次。';

  @override
  String get wakeKindAgentDeleted => '代理已不存在。';

  @override
  String get wakeKindAgentNotDispatchable => '此代理已退役。';

  @override
  String get wakeKindAgentPaused => '代理已暫停。';

  @override
  String get wakeKindPersonRemoved => '其代表的人已離開工作區。';

  @override
  String get wakeKindBudgetBlocked => '預算阻止了執行。';

  @override
  String get wakeKindTakeOver => '有人已接管此工作樹。';

  @override
  String get wakeKindRateCapConversation => '此對話在過去一小時內已因喚醒而開始 30 次執行。';

  @override
  String get wakeKindRateCapWorkspace => '此工作區在過去一小時內已因喚醒而開始 300 次執行。';

  @override
  String get wakeKindLiveRunNoInput => '代理在此處的進行中執行不接受輸入。';

  @override
  String get wakeKindLiveRunOtherOptions =>
      '代理在此處的進行中執行運作方式不同，因此此項會在其之後啟動自己的執行。';

  @override
  String get wakeKindLiveRunOtherPerson => '代理在此處的進行中執行代表其他人，因此此項會在其之後啟動自己的執行。';

  @override
  String get wakeKindDispatchRefused => '無法啟動執行。';

  @override
  String get wakeKindSandboxUnavailable => '沒有可用的沙箱可供唯讀執行。';

  @override
  String get wakeKindReadOnlyUnavailable => '此代理的後端無法保持唯讀執行。';

  @override
  String get wakeKindServerStopped => '伺服器重新啟動，停止了執行。';

  @override
  String get wakeKindServerRestarted => '伺服器在有人執行期間重新啟動。';

  @override
  String get wakeKindGuardFailed => '傳遞前的檢查失敗。';

  @override
  String get wakeKindLimit => '正在等待供應商的用量上限重設。';

  @override
  String get wakeKindLimitRunLive => '正在等待已達用量上限的執行結束。';

  @override
  String get wakeKindWakeMissed => '伺服器關閉期間已錯過。';

  @override
  String get wakeKindPipelineRunEnded => '其管線執行已結束。';

  @override
  String get wakeKindGoalEnded => '其目標已結束。';

  @override
  String get wakeKindGoalBudgetExhausted => '其目標已用盡預算。';

  @override
  String get wakeKindGoalReviewStale => '此審核被要求之後，目標已有變更。';

  @override
  String get wakeKindGoalPaused => '其目標已暫停。';

  @override
  String get wakeKindGoalHeld => '其目標已保留。';

  @override
  String get wakeKindGoalStopped => '其目標已停止。';

  @override
  String get wakeKindAskSettled => '它所回答的問題已經有結論。';

  @override
  String get wakeKindRuleEnded => '其排程已結束。';

  @override
  String get wakeRefusalNotYours => '此喚醒代表其他人。只有對方可以傳遞、繼續或取消它。';

  @override
  String get wakeRefusalSettled => '此喚醒已經完結。';

  @override
  String get goalRefusalAlreadyActive => '此代理已有進行中的目標。';

  @override
  String get goalRefusalNotInReview => '此目標並未等待審核。';

  @override
  String get goalRefusalEvidenceIncomplete => '目標的證據並不完整。';

  @override
  String get goalRefusalClaimPending => '其已完成的聲明仍在檢查中。';

  @override
  String get goalRefusalNotActiveSegment => '此目標沒有正在執行的段。';

  @override
  String get goalRefusalNotYours => '只有開始此目標的人可以執行此操作。';

  @override
  String get goalRefusalNotPaused => '請先暫停目標。';

  @override
  String get goalRefusalContractInvalid => '無法讀取目標的約定內容。';

  @override
  String get goalRefusalCheckerUnknown => '沒有代理使用此名稱。';

  @override
  String get goalRefusalCheckerAmbiguous => '有多於一個代理使用此名稱。';

  @override
  String get goalRefusalCheckerIsGoalAgent => '審核代理必須是執行工作的代理以外的另一個代理。';

  @override
  String get goalRefusalCommandInvalid => '無法讀取此目標：';

  @override
  String get wakeRuleRefusalIntervalTooShort => '間隔太短。請至少選擇一分鐘。';

  @override
  String get wakeRuleRefusalTooSoon => '該時間太近。請選擇較後的時間。';

  @override
  String get wakeRuleRefusalLineageEnded => '此連串喚醒已用完其執行次數或時間。';

  @override
  String get wakeRuleRefusalWatchTargetUnreadable => '你無法讀取此項將會監看的內容。';

  @override
  String get wakeRuleRefusalExpiryRequired => '請設定結束日期或執行次數。';

  @override
  String get wakeRuleRefusalLimitReached => '此對話或此代理的排程數量已達上限。';

  @override
  String get wakeRuleRefusalInvalidWhen => '無法讀取該時間。';

  @override
  String get wakeRuleRefusalNoteTooLong => '備註太長。';

  @override
  String get wakeRuleRefusalExpiryTooLong => '結束時間太遠。';

  @override
  String get wakeRuleRefusalLimitOutOfRange => '執行次數、天數或預算上限超出範圍。';

  @override
  String get wakeRuleRefusalNextOutsideLoop => '只有循環可以自行選擇下一次的時間。';

  @override
  String get wakeRuleRefusalWatchRefused => '此項無法監看。';

  @override
  String get wakeRuleRefusalRuleEnded => '該排程已經結束。';

  @override
  String get wakeRuleRefusalNotYours => '該排程屬於其他人。';

  @override
  String get wakeRuleEndFired => '已執行其一次。';

  @override
  String get wakeRuleEndExpired => '已到達結束日期。';

  @override
  String get wakeRuleEndRunCap => '已用完其執行次數。';

  @override
  String get wakeRuleEndCostCap => '已達到其費用上限。';

  @override
  String get wakeRuleEndGoalEnded => '其目標已結束。';

  @override
  String get wakeRuleEndCancelled => '已取消。';

  @override
  String get wakeRuleEndMemberRemoved => '其所屬人已離開工作區。';

  @override
  String get wakeRuleEndInvalidRow => '無法讀取其已儲存的設定。';

  @override
  String goalHoldWorking(int segment) {
    final intl.NumberFormat segmentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String segmentString = segmentNumberFormat.format(segment);

    return '正在執行第 $segmentString 段。無需任何人處理。';
  }

  @override
  String get goalHoldWaiting => '正在等待應得的工作。它會自行繼續。';

  @override
  String goalHoldWaitingUntil(String time) {
    return '正在等待應得的工作。最遲會於 $time 自行繼續。';
  }

  @override
  String get goalHoldVerifying => '它表示已完成。伺服器正在執行其檢查，之後由審核者決定。';

  @override
  String get goalHoldLimit => '已在供應商的用量上限暫停。重設後會自行繼續。';

  @override
  String goalHoldLimitUntil(String time) {
    return '已在供應商的用量上限暫停。將於 $time 自行繼續。';
  }

  @override
  String get goalHoldPerson => '正在等待有人在對話中回答。有人回答後便會繼續。';

  @override
  String get goalHoldByPerson => '已由人手暫停。在有人繼續之前，會一直保持暫停。';

  @override
  String get goalHoldNeedsReview => '等待審核：它無法自行繼續。請將其標示為已完成、繼續或取消。';

  @override
  String get goalHoldBudget => '已用盡其預算。提高預算即可讓其繼續。';

  @override
  String goalHoldLimitParks(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return '用量上限暫停：第 $countString 次，上限為 $maxString 次';
  }

  @override
  String get goalHoldDetailStalled => '最近幾段沒有進展。';

  @override
  String get goalHoldDetailStalledWaiting => '它就同一工作等待了 24 小時，但沒有進展。';

  @override
  String get goalHoldDetailVerificationFailed => '最近一次檢查失敗。';

  @override
  String get goalHoldDetailCannotVerify => '審核代理無法判斷是否已完成。';

  @override
  String get goalHoldDetailSandboxUnavailable => '沒有可用的沙箱來執行其檢查。';

  @override
  String get goalHoldDetailCheckerUnavailable => '其審核代理無法使用。請選擇另一個審核代理，然後繼續。';

  @override
  String get goalHoldDetailCheckBroken => '此檢查無法執行：';

  @override
  String get goalHoldDetailWakeSkipped => '其喚醒未有傳遞。';

  @override
  String get goalHoldDetailClaimPending => '其已完成的聲明正等待檢查。';

  @override
  String get goalHoldDetailUnanswered => '給人手的一個問題或核准請求未獲回答。';

  @override
  String get goalHoldDetailLimitParks => '它太常觸及用量上限。請檢視後再繼續。';

  @override
  String get goalHoldDetailInput => '正在等待對話中的回答。';

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

    return '第 $runString 段，共 $maxString 段';
  }

  @override
  String goalSegmentsNoCap(int run) {
    final intl.NumberFormat runNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String runString = runNumberFormat.format(run);

    return '第 $runString 段，無上限';
  }

  @override
  String goalMoney(String spent, String cap) {
    return '已花費 $spent，上限為 $cap';
  }

  @override
  String goalDeadline(String time) {
    return '期限為 $time';
  }

  @override
  String get goalPipelineStep => '一個管線步驟正在推進此目標。';

  @override
  String get goalSummaryHeading => '最近摘要';

  @override
  String get goalDoneMeans => '完成的標準';

  @override
  String get goalChecks => '檢查';

  @override
  String get goalBoundaries => '界線';

  @override
  String get goalStopWhen => '在以下情況停下並詢問';

  @override
  String get goalNoMachineCheck => '沒有機器檢查。審核者會根據其可讀取的內容作出判斷。';

  @override
  String get goalCheckEnvironment => '環境任務';

  @override
  String goalLastCheck(int round, String time) {
    final intl.NumberFormat roundNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String roundString = roundNumberFormat.format(round);

    return '最近一次檢查，第 $roundString 輪，$time';
  }

  @override
  String get goalClaim => '它的聲明';

  @override
  String get goalCheckPassed => '通過';

  @override
  String goalCheckFailed(int code) {
    return '失敗，結束代碼 $code';
  }

  @override
  String get goalCheckTimedOut => '已逾時';

  @override
  String get goalCheckNotRerun => '未重新執行：自上次通過後沒有變更';

  @override
  String get goalCheckBroken => '無法執行';

  @override
  String get goalCriterionMet => '已達成';

  @override
  String get goalCriterionUnmet => '未達成';

  @override
  String get goalCriterionCannotTell => '無法判斷';

  @override
  String get goalVerdictPass => '結論：已完成';

  @override
  String get goalVerdictFail => '結論：未完成';

  @override
  String get goalVerdictCannotVerify => '結論：無法判斷';

  @override
  String get goalConcerns => '疑慮';

  @override
  String goalVerifiedBy(String agent) {
    return '由 $agent 驗證';
  }

  @override
  String get goalVerifiedBySelf => '由其自身驗證（沒有另設審核代理）';

  @override
  String get goalClosedByPerson => '由人手在沒有通過檢查的情況下結束';

  @override
  String get goalApprove => '核准完成';

  @override
  String get goalApproveTitle => '要將此目標標示為已完成嗎？';

  @override
  String get goalApproveBody =>
      '沒有任何檢查確認此目標。你會依自己的判斷將其結束，而目標會記錄為由人手在未驗證的情況下結束。';

  @override
  String get goalApproveConfirm => '標示為已完成';

  @override
  String get goalResumeNotYours => '繼續執行此目標或提高其預算，由開始此目標的人負責。';

  @override
  String get goalChooseChecker => '選擇另一個審核代理';

  @override
  String goalCheckerSet(String agent) {
    return '現由 $agent 進行檢查。請繼續以重新驗證。';
  }

  @override
  String get goalSchedules => '排程';

  @override
  String get goalRepeat => '重複';

  @override
  String get goalCreateChecks => '檢查（選填）';

  @override
  String get goalCreateCheckHint => '工作完成時會通過的指令';

  @override
  String get goalCreateAddCheck => '新增檢查';

  @override
  String get goalCreateRemoveCheck => '移除檢查';

  @override
  String get goalCreateSegmentCap => '段數上限（選填）';

  @override
  String get goalCreateSegmentInvalid => '段數上限必須為至少 1 的整數。';

  @override
  String get scheduleCreateTitle => '重複一則提示';

  @override
  String get scheduleCadence => '頻率';

  @override
  String get scheduleEveryMinutes => '每 N 分鐘';

  @override
  String get scheduleEveryHours => '每 N 小時';

  @override
  String get scheduleSelfPaced => '由代理自定節奏';

  @override
  String get scheduleSelfPacedHint => '代理在每次執行後自行決定延遲時間，介乎 1 分鐘至 1 小時之間。';

  @override
  String get scheduleInterval => '間隔';

  @override
  String get scheduleNote => '每次執行應該做什麼？';

  @override
  String get scheduleCostCap => '費用上限（美元，選填）';

  @override
  String get scheduleExpiryDays => '於 N 天後結束（選填）';

  @override
  String get scheduleCreateInvalid => '請選擇空間與代理，填寫每次執行應做的事，並填入至少為 1 的整數。';

  @override
  String get scheduleCreateButton => '開始排程';

  @override
  String get scheduleCreateConfirmTitle => '要開始此排程嗎？';

  @override
  String scheduleCreateConfirmEveryMinutes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '由現在開始，每 $countString 分鐘執行一次。',
      one: '由現在開始，每分鐘執行一次。',
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
      other: '由現在開始，每 $countString 小時執行一次。',
      one: '由現在開始，每小時執行一次。',
    );
    return '$_temp0';
  }

  @override
  String get scheduleCreateConfirmSelfPaced => '會立即執行一次，之後由代理決定何時再次執行。';

  @override
  String get scheduleCreated => '排程已開始。可於「排程」下查看。';

  @override
  String get schedulesTitle => '排程';

  @override
  String get schedulesLoadFailed => '無法載入排程';

  @override
  String get schedulesEmpty => '沒有排程或監看';

  @override
  String get schedulesEmptyDescription =>
      '從目標畫面重複一則提示，或在對話中傳送 /loop 或 /schedule。';

  @override
  String get scheduleMissing => '此排程在此工作區中已不再可用。';

  @override
  String scheduleEvery(String interval) {
    return '每 $interval';
  }

  @override
  String get scheduleSelfPacedLoop => '自定節奏的循環';

  @override
  String get scheduleCron => 'Cron 排程';

  @override
  String scheduleOnce(String time) {
    return '於 $time 執行一次';
  }

  @override
  String scheduleWatch(String event) {
    return '監看：$event';
  }

  @override
  String get scheduleWatchPrChecks => 'pull request 的檢查';

  @override
  String get scheduleWatchPrReview => 'pull request 的審核';

  @override
  String get scheduleWatchPrMerged => 'pull request 合併';

  @override
  String get scheduleWatchEnvironment => '環境';

  @override
  String get scheduleWatchTicket => '工單';

  @override
  String get scheduleWatchPipelineRun => '管線執行';

  @override
  String get scheduleStatusActive => '進行中';

  @override
  String get scheduleStatusPaused => '已暫停';

  @override
  String get scheduleStatusEnded => '已結束';

  @override
  String scheduleWakes(String agent) {
    return '喚醒 $agent';
  }

  @override
  String scheduleNext(String time) {
    return '下次執行 $time';
  }

  @override
  String scheduleLast(String time) {
    return '上次執行 $time';
  }

  @override
  String scheduleRuns(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString 次執行',
      one: '1 次執行',
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

    return '已執行 $countString／$maxString 次';
  }

  @override
  String scheduleSkipped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已略過 $countString 次',
      one: '已略過 1 次',
    );
    return '$_temp0';
  }

  @override
  String scheduleEnds(String time) {
    return '$time 結束';
  }

  @override
  String scheduleChain(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '屬於一個連串：尚餘 $countString 次執行，將於 $time 結束';
  }

  @override
  String get scheduleNoteAgent => '代理為自己留下的備註，原文如下：';

  @override
  String get scheduleNotePerson => '某人的備註：';

  @override
  String scheduleActsFor(String name) {
    return '代表 $name';
  }

  @override
  String get scheduleActsForBot => '不代表任何人';

  @override
  String get scheduleGoalBound => '它會隨其目標一同結束。';

  @override
  String get schedulePause => '暫停';

  @override
  String get scheduleResume => '繼續';

  @override
  String get scheduleDelete => '刪除';

  @override
  String get scheduleRemove => '移除';

  @override
  String get scheduleDeleteTitle => '要刪除此排程嗎？';

  @override
  String get scheduleDeleteBody => '它將永久停止。已完成的工作不會撤銷。';

  @override
  String get scheduleRemoveTitle => '要移除此排程嗎？';

  @override
  String get scheduleRemoveBody => '它會從清單中消失。';

  @override
  String get scheduleResumeNotYours => '只有此排程所代表的人可以繼續它。';

  @override
  String get scheduleResumeAdminOnly => '只有工作區管理員可以繼續沒有任何負責人的排程。';

  @override
  String get scheduleOpenConversation => '開啟對話';

  @override
  String get progressWaiting => '等待中';

  @override
  String get progressNothingWaiting => '沒有任何項目在等待。';

  @override
  String get wakeOriginGoal => '目標';

  @override
  String get wakeOriginGoalCheck => '目標檢查';

  @override
  String get wakeOriginGoalReview => '目標審核';

  @override
  String get wakeOriginSchedule => '排程';

  @override
  String get wakeOriginWatch => '監看';

  @override
  String get wakeOriginReply => '回覆';

  @override
  String get wakeOriginMessage => '訊息';

  @override
  String get wakeOriginWorkFinished => '已完成的工作';

  @override
  String get wakeOriginLimitReset => '用量上限已重設';

  @override
  String get wakeOriginRecovery => '復原';

  @override
  String get wakeOriginAssignment => '指派';

  @override
  String get wakeOriginPipelineStep => '管線步驟';

  @override
  String get wakeOriginImprovementReview => '改進審核';

  @override
  String wakeOriginReplyFrom(String agent) {
    return '來自 $agent 的回覆';
  }

  @override
  String wakeOriginMessageFrom(String agent) {
    return '來自 $agent 的訊息';
  }

  @override
  String wakeOriginWorkFinishedBy(String agent) {
    return '$agent 完成的工作';
  }

  @override
  String wakeFor(String agent) {
    return '為 $agent';
  }

  @override
  String wakeDue(String time) {
    return '$time 到期';
  }

  @override
  String get wakeDueNow => '現已到期';

  @override
  String get wakeHeld => '已保留';

  @override
  String wakeExpires(String time) {
    return '$time 過期';
  }

  @override
  String wakeAttempt(int attempt) {
    final intl.NumberFormat attemptNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String attemptString = attemptNumberFormat.format(attempt);

    return '第 $attemptString 次嘗試';
  }

  @override
  String get wakeCancel => '取消';

  @override
  String get wakeDeliverNow => '立即傳遞';

  @override
  String get wakeResume => '繼續';

  @override
  String get wakeDismiss => '關閉';

  @override
  String get wakeResumeOnlyTheirs => '只有此次執行的所屬人可以繼續。';

  @override
  String get wakeRecovery => '伺服器在此次執行期間重新啟動。請繼續以恢復執行，或將其關閉。';

  @override
  String limitParkTitle(String provider, String time) {
    return '已因 $provider 用量上限而暫停，上限將於 $time 重設。執行會等待按下繼續，重設後最多 7 天。';
  }

  @override
  String limitParkTitleUnnamed(String time) {
    return '已因供應商嘅用量上限而暫停，上限將於 $time 重設。執行會等待按下繼續，重設後最多 7 天。';
  }

  @override
  String get limitParkResumeNow => '立即繼續';

  @override
  String get limitParkCancel => '取消';

  @override
  String limitParkResumed(String provider) {
    return '$provider 的用量上限過後，已繼續。';
  }

  @override
  String limitParkGone(String provider) {
    return '已不再於 $provider 的用量上限處等待。';
  }

  @override
  String get limitParkProviderUnknown => '供應商';

  @override
  String get mobileHeldMessages => '已保留的訊息';

  @override
  String get heldSteeringTitle => '執行在能夠接收它們之前已經結束，因此已保留。請立即傳送你的訊息，或將其移除。';

  @override
  String get heldSteeringRelease => '傳送已保留的訊息';

  @override
  String get notifGoalCompleted => '目標已完成';

  @override
  String get notifGoalFailed => '目標失敗';

  @override
  String get notifGoalCancelled => '目標已取消';

  @override
  String get notifGoalBudgetExhausted => '目標已用盡預算';

  @override
  String get notifGoalNeedsReview => '有目標等待你審核';

  @override
  String get notifGoalNeedsPerson => '有目標需要你處理';

  @override
  String get notifGoalOnHold => '有目標已保留';

  @override
  String get notifWakeRuleEnded => '有排程已結束';

  @override
  String notifWaitingDigest(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString 件事等待你處理',
      one: '1 件事等待你處理',
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
      other: '已提出 $countString 項改進',
      one: '已提出 1 項改進',
    );
    return '$_temp0';
  }

  @override
  String get notifPipelineRunHeld => '管線執行已在其預算處保留';

  @override
  String notifPipelineRunHeldBody(String spent, String cap) {
    return '已花費 $spent／$cap';
  }

  @override
  String get notifNeedsYou => '需要你處理';

  @override
  String get notifDigestGoalReview => '目標等待審核';

  @override
  String get notifDigestGoalPerson => '目標需要人手處理';

  @override
  String get notifDigestHeldWake => '已保留的喚醒';

  @override
  String get notifDigestImprovement => '已提出的改進';

  @override
  String get wakeKindRulePaused => '其排程已暫停。';

  @override
  String get wakeKindRuleBusy => '代理正忙碌中，而此排程設定為在這種情況下略過。';

  @override
  String get wakeKindRuleFolded => '同一監看的較後事件已取代了它。';

  @override
  String get wakeKindRuleSuperseded => '其排程的較後時間已取代了它。';

  @override
  String get wakeKindRuleNotified => '其排程只會發送通知，因此沒有開始執行。';

  @override
  String get wakeKindRuleLimitParked => '其排程正等待供應商的用量上限重設。';

  @override
  String get improvementRefusalCooldown => '此對話不久前才剛進行過改進審核。請稍後再試。';

  @override
  String get improvementRefusalQueued => '此對話的改進審核已在等待執行。';

  @override
  String get improvementRefusalAgentNotFound => '該代理不屬於此工作區。';

  @override
  String get steeringRefusalHeldByLimit => '用量上限處保留的訊息不能手動傳送。它們會等待暫停的執行繼續。';

  @override
  String limitParkCancelled(String provider) {
    return '已取消在 $provider 用量上限處的等待。';
  }

  @override
  String limitParkExpired(String provider) {
    return '在執行繼續之前，於 $provider 用量上限處的等待已過期。';
  }

  @override
  String limitParkSkipped(String provider) {
    return '執行未有在 $provider 的用量上限過後繼續。';
  }

  @override
  String get heldSteeringLimitTitle => '執行等待用量上限重設期間已保留。執行所服務嗰位人士繼續執行時會送出。';

  @override
  String heldSteeringLimitAt(String time) {
    return '已保留至用量上限於 $time 重設為止。執行所服務嗰位人士繼續執行時會送出。';
  }

  @override
  String get heldSteeringOtherTitle => '由伺服器保留。你可以將其移除。';

  @override
  String workRowWoke(int count, String agent) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已為 $countString 個等待中項目喚醒 $agent',
      one: '已喚醒 $agent',
    );
    return '$_temp0';
  }

  @override
  String workRowWakeMissed(String agent) {
    return '伺服器關閉期間錯過了 $agent 的喚醒。';
  }

  @override
  String workRowWakeSkipped(String agent) {
    return '未能傳遞 $agent 的喚醒。';
  }

  @override
  String workRowScheduleCreated(String agent) {
    return '已為 $agent 設定排程。';
  }

  @override
  String workRowScheduleEnded(String agent) {
    return '$agent 的排程已結束。';
  }

  @override
  String workRowNoteFromAgent(String agent) {
    return '$agent 的排程備註：';
  }

  @override
  String get workRowNoteFromPerson => '某人的排程備註：';

  @override
  String workRowCommandRefusedNamed(String command) {
    return '$command 指令被拒絕。';
  }

  @override
  String get workRowCommandRefused => '有指令被拒絕。';

  @override
  String workRowCapRaised(String person, String from, String to) {
    return '$person 將管線的消費上限由 $from 提高至 $to。';
  }

  @override
  String workRowCapRaisedNoAmounts(String person) {
    return '$person 提高了管線的消費上限。';
  }

  @override
  String get workRowApplyIncomplete => '對此技能所接受的變更無法完成，因為該技能在此期間已有變更。此提案已回復。';

  @override
  String get workRowOpenSchedule => '開啟排程';

  @override
  String get heldSteeringOthersTitle => '執行在能夠接收它們之前已經結束，因此已保留。只有撰寫訊息的人可以傳送。';

  @override
  String get heldSteeringOnlyYours => '只會傳送你的訊息。其他人的訊息會等待其撰寫者。';

  @override
  String heldSteeringWrittenBy(String name) {
    return '由 $name 撰寫';
  }

  @override
  String get steeringRefusalNotYours => '只有撰寫已保留訊息的人可以傳送，而這些訊息都不是你的。';

  @override
  String get steeringRefusalNeedsWrite => '你需要此空間儲存庫嘅寫入權限，才可以引導代表其他人執行嘅執行。';

  @override
  String workRowSchedulePaused(String name, String agent) {
    return '$name 已暫停 $agent 嘅排程。';
  }

  @override
  String get goalVerdictObjective => '整體目標內容';

  @override
  String get notifDigestRequest => '等待你回覆';
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
  String get teammate => '隊友';

  @override
  String get systemSender => '系統';

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
  String get sentAttachmentUnavailable => '附件無法使用';

  @override
  String get sentAttachmentLoadFailed => '無法載入附件';

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
  String get mobilePrSelectCommentLine => '選擇要留言的行';

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
  String get permissionPrPublish => '更新或合併 pull request';

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
  String get permissionRemembered => '持續核准';

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
  String permissionTools(String tools) {
    return '工具：$tools';
  }

  @override
  String get permissionNotInEffect => '此動作設為拒絕時不生效';

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
  String mobileGoalFailures(String count) {
    return '連續失敗次數：$count';
  }

  @override
  String get mobileGoalFailedDescription => '監督程式在多次執行失敗後已停止。請查看對話瞭解詳情。';

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
  String get transcriptToolTodos => '任務';

  @override
  String get transcriptToolSearchMemory => '搜尋記憶';

  @override
  String get transcriptToolRenderMedia => '呈現媒體';

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
  String get pushDenied => '瀏覽器回報通知已遭封鎖。請檢查此網站的權限以及瀏覽器或裝置的通知設定，然後重新整理頁面。';

  @override
  String get pushOsHint => '瀏覽器本身也需要在裝置的系統設定中取得顯示通知的權限。';

  @override
  String get pushServiceUnavailable =>
      '瀏覽器的推播服務拒絕了訂閱。部分瀏覽器（例如 Brave）預設會關閉此服務：請在瀏覽器的隱私設定中尋找推播訊息選項，然後再試一次。';

  @override
  String get pushWorkerUnavailable => '無法在此瀏覽器中啟動通知服務。請重新載入頁面後再試一次。';

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
  String get credentialsConnectCodePrompt => '確認代碼';

  @override
  String get credentialsConnectCodeMalformed => '這看起來不像登入代碼。代碼由 8 個字母和數字組成。';

  @override
  String get credentialsSignInInvalidCode => '此代碼與這次登入不符。請檢查後再試一次。';

  @override
  String get credentialsSignInTooManyCodes => '錯誤代碼次數過多。請重新開始登入。';

  @override
  String get credentialsSignInRetryLater => '登入服務目前沒有回應。請等待一分鐘後再試一次。';

  @override
  String get credentialsSignInRefused => '登入遭到拒絕。請重新開始並核准所有要求的權限。';

  @override
  String get credentialsSignInNotSaved => '登入成功，但伺服器無法儲存。請再試一次。';

  @override
  String credentialsSignInUnavailable(String provider) {
    return '此伺服器尚未設定 $provider 登入。';
  }

  @override
  String get credentialsSignInPhoneUnreachable =>
      '無法從手機安全存取此伺服器的登入回呼位址。請在桌面應用程式中登入，或請伺服器擁有者設定公開的 HTTPS 位址。';

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
  String get credentialsUpdateToken => '更新權杖';

  @override
  String get credentialsAddToken => '新增權杖';

  @override
  String get credentialsPersonalToken => '個人存取權杖';

  @override
  String get credentialsPersonalTokenHint => '貼上個人存取權杖';

  @override
  String get credentialsStopWatching => '停止監看';

  @override
  String get transcriptClaudeSignInExpiredTitle => 'Claude Code 登入已過期';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      '執行已停止，因為其帳號無法再通過驗證。請重新登入，然後重試此回合。';

  @override
  String get transcriptSignInExpiredTitle => '提供者登入已過期';

  @override
  String get transcriptSignInExpiredBody =>
      '執行已停止，因為其提供者憑證已失效。請在 設定 → 提供者 中重新連線，然後重試此回合。';

  @override
  String get permissionHostExecution => '在主機上執行指令';

  @override
  String credentialsSignInLapsed(String provider) {
    return '你的 $provider 登入已失效。請重新登入。';
  }

  @override
  String get credentialsSignInPaused => '已暫停：此工作區的登入服務已變更。服務恢復後即可再次使用。';

  @override
  String credentialsProviderUnreachable(String provider) {
    return '暫時無法連線至 $provider，正在重試。';
  }

  @override
  String get credentialsScopeWorkspace => '僅限此工作區';

  @override
  String get credentialsScopeAllWorkspaces => '所有工作區';

  @override
  String get credentialsRemoveConfirmWorkspace =>
      '要從此工作區移除你儲存的憑證嗎？其他工作區會保留各自的憑證。';

  @override
  String get credentialsRemoveConfirmAllWorkspaces => '要從共用它的所有工作區移除你儲存的憑證嗎？';

  @override
  String get credentialsSignInServerRestarted => '伺服器已重新啟動。請重新開始登入。';

  @override
  String repoAccessInstallApp(String owner, String names) {
    return '在 $owner 上安裝 GitHub App，讓自動化可以存取 $names。輕觸即可開啟 GitHub。';
  }

  @override
  String repoAccessAskAdminInstall(String owner, String names) {
    return '$owner 上未安裝 GitHub App，因此自動化無法存取 $names。請聯絡工作區管理員安裝。';
  }

  @override
  String repoAccessAddToApp(String names) {
    return '將 $names 新增至 GitHub App 的存放庫。輕觸即可開啟 GitHub。';
  }

  @override
  String repoAccessAskAdminAdd(String names) {
    return 'GitHub App 還看不到 $names。請聯絡工作區管理員將它們新增至 App 的存放庫。';
  }

  @override
  String repoAccessSuspended(String names) {
    return 'GitHub App 安裝已暫停。在帳號擁有者於 GitHub 上恢復安裝之前，$names 的自動化已暫停。';
  }

  @override
  String repoAccessOwnerCannotSee(String names) {
    return '此工作區自動化的負責人已無法看到 $names，因此不會再代表其在那裡執行任何內容。';
  }

  @override
  String repoAccessOwnerNotSignedIn(String names) {
    return '此工作區自動化的負責人尚未登入程式碼代管平台，因此 $names 的自動化會等待其登入。';
  }

  @override
  String repoAccessRetrying(String names) {
    return '無法檢查對 $names 的存取權限，正在重試。';
  }

  @override
  String hiddenReposSignIn(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '登入 $forge 即可查看另外 $count 個存放庫的 pull request',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoForgeAccess(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 個存放庫已隱藏，因為你的 $forge 帳號看不到它們',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoGrant(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 個存放庫已隱藏，因為你在此工作區中沒有存取權限',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposChecking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '正在檢查你對另外 $count 個存放庫的存取權限…',
    );
    return '$_temp0';
  }

  @override
  String get credentialsAtlassianEmail => 'Atlassian 帳號電子郵件';

  @override
  String get credentialsAtlassianEmailInvalid => '請輸入你的 Atlassian 帳號電子郵件地址。';

  @override
  String get credentialsBitbucketApiToken => 'API 權杖';

  @override
  String repoAccessAutomationTokenMissing(String names) {
    return '沒有任何自動化權杖可以讀取 $names，因此那裡的背景工作已暫停。管理員可以在「設定 → 儲存庫」中新增一個。';
  }

  @override
  String get credentialsSignInConfirmInBrowser => '請在瀏覽器中確認，然後輸入它顯示的代碼。';

  @override
  String get credentialsSignInAccountAlreadyBound =>
      '此帳戶已連結到此伺服器上的另一位使用者。請使用其他帳戶登入。';

  @override
  String credentialsTokenUnreachable(String provider) {
    return '無法連線至 $provider 以檢查此權杖。請稍後再試。';
  }

  @override
  String credentialsTokenRejected(String provider) {
    return '$provider 不接受此權杖。請確認你已完整複製，且它未被撤銷。';
  }

  @override
  String credentialsTokenWrongKind(String provider) {
    return '這不是個人權杖。請貼上你自己 $provider 帳戶的個人存取權杖，而非專案、群組、工作區或機器人的權杖。';
  }

  @override
  String credentialsTokenNarrowScope(String scope) {
    return '此權杖缺少 $scope 範圍，而審查與留言需要它。請建立包含該範圍的權杖。';
  }

  @override
  String get credentialsTokenExpired => '此權杖已過期。請建立新的權杖並貼到這裡。';

  @override
  String get credentialsSignInRateLimited => '目前請求過多。請稍候一下，然後再試一次。';

  @override
  String get credentialsSignInCancelled => '登入已取消或遭拒絕。準備好時請再重新開始。';

  @override
  String get credentialsSignInNoLongerOpen => '此登入已不再開啟：它已被取消、使用或取代。請重新開始。';

  @override
  String get noWorkspacesYetHint => '工作區管理員必須邀請你，或伺服器擁有者可以為你建立工作區。';

  @override
  String repoAccessReplaced(String repos, String forge) {
    return '$repos 現在在 $forge 上指向另一個存放庫。請在桌面版或網頁版中重新連結，以繼續使用。';
  }

  @override
  String repoAccessAskAdminRelink(String repos, String forge) {
    return '$repos 現在在 $forge 上指向另一個存放庫。工作區管理員必須重新連結後，才能再次使用。';
  }

  @override
  String get runSandboxUnavailableTitle => '代理需要此伺服器上的沙箱';

  @override
  String get runSandboxUnavailable =>
      '此伺服器沒有沙箱，因此只有其擁有者可以在此執行代理。擁有者可以安裝沙箱，或為所有人關閉沙箱功能。';

  @override
  String get scriptToolCalls => '工具呼叫';

  @override
  String scriptCallCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 次呼叫',
      one: '1 次呼叫',
    );
    return '$_temp0';
  }

  @override
  String scriptCallsRunning(int count) {
    return '$count 個執行中';
  }

  @override
  String scriptCallsOk(int count) {
    return '$count 成功';
  }

  @override
  String scriptCallsFailed(int count) {
    return '$count 失敗';
  }

  @override
  String scriptCallsDenied(int count) {
    return '$count 已拒絕';
  }

  @override
  String scriptCallsCancelled(int count) {
    return '$count 已取消';
  }

  @override
  String scriptCallsQueued(int count) {
    return '$count 已排入佇列';
  }

  @override
  String scriptCallsSkipped(int count) {
    return '$count 已跳過';
  }

  @override
  String get scriptStepQueued => '已排入佇列';

  @override
  String get scriptStepSkipped => '已跳過';

  @override
  String get scriptGroupLoop => '迴圈';

  @override
  String get scriptGroupEach => '逐項';

  @override
  String get scriptGroupParallel => '平行';

  @override
  String get scriptGroupFunction => '函式';

  @override
  String scriptCallsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '再顯示 $count 次呼叫',
      one: '再顯示 1 次呼叫',
    );
    return '$_temp0';
  }

  @override
  String get scriptCallsUnplaced => '指令碼中未能定位的工具呼叫';

  @override
  String get scriptToolComputed => '工具';

  @override
  String scriptStepSemantics(String subject, String state) {
    return '$subject，$state';
  }

  @override
  String get scriptSourceLabel => '指令碼';

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
  String get scriptStateRunning => '執行中';

  @override
  String get scriptStateCompleted => '已完成';

  @override
  String get scriptStateFailed => '失敗';

  @override
  String get scriptStateTimedOut => '已逾時';

  @override
  String get scriptStateCancelled => '已取消';

  @override
  String get scriptStateMemoryExceeded => '記憶體不足';

  @override
  String get scriptStateOutputExceeded => '輸出過多';

  @override
  String get scriptStateSandboxError => '沙箱錯誤';

  @override
  String get scriptStateRefused => '已拒絕';

  @override
  String get scriptOriginLine => '來自代理正在執行的指令碼';

  @override
  String get codeModeTitle => '程式碼模式';

  @override
  String get codeModeAvailable => '可用';

  @override
  String get codeModeUnavailable => '無法使用';

  @override
  String codeModeUnavailableNote(String reason) {
    return '此伺服器無法執行指令碼，因此這裡的代理會逐一呼叫其工具。伺服器的說明：$reason';
  }

  @override
  String get codeModeNoReason => '未提供原因。';

  @override
  String get workKindUnknown => '此版本未提供名稱的原因：';

  @override
  String get workRefusalUnknown => '伺服器拒絕了此要求：';

  @override
  String workActionFailed(String error) {
    return '操作未成功：$error';
  }

  @override
  String get wakeKindStopped => '因為有人停止了執行，所以保留此喚醒。';

  @override
  String get wakeKindAttempts => '傳送失敗三次。';

  @override
  String get wakeKindAgentDeleted => '此代理已不存在。';

  @override
  String get wakeKindAgentNotDispatchable => '此代理已退役。';

  @override
  String get wakeKindAgentPaused => '此代理已暫停。';

  @override
  String get wakeKindPersonRemoved => '此喚醒所代表的人員已離開工作區。';

  @override
  String get wakeKindBudgetBlocked => '預算阻擋了執行。';

  @override
  String get wakeKindTakeOver => '有人已接手工作樹。';

  @override
  String get wakeKindRateCapConversation => '此對話在過去一小時內因喚醒而開始了 30 次執行。';

  @override
  String get wakeKindRateCapWorkspace => '此工作區在過去一小時內因喚醒而開始了 300 次執行。';

  @override
  String get wakeKindLiveRunNoInput => '代理在此處的即時執行不接受輸入。';

  @override
  String get wakeKindLiveRunOtherOptions =>
      '代理在此處的即時執行以不同選項運作，因此這會在其之後啟動自己的執行。';

  @override
  String get wakeKindLiveRunOtherPerson => '代理在此處的即時執行代表其他人，因此這會在其之後啟動自己的執行。';

  @override
  String get wakeKindDispatchRefused => '無法啟動執行。';

  @override
  String get wakeKindSandboxUnavailable => '沒有可用於唯讀執行的沙箱。';

  @override
  String get wakeKindReadOnlyUnavailable => '此代理的後端無法維持唯讀執行。';

  @override
  String get wakeKindServerStopped => '伺服器重新啟動時停止了執行。';

  @override
  String get wakeKindServerRestarted => '人員執行期間伺服器重新啟動。';

  @override
  String get wakeKindGuardFailed => '傳送前的檢查失敗。';

  @override
  String get wakeKindLimit => '正在等待供應商的用量上限重設。';

  @override
  String get wakeKindLimitRunLive => '正在等待用量上限下的執行結束。';

  @override
  String get wakeKindWakeMissed => '伺服器關閉期間錯過。';

  @override
  String get wakeKindPipelineRunEnded => '其管線執行已結束。';

  @override
  String get wakeKindGoalEnded => '其目標已結束。';

  @override
  String get wakeKindGoalBudgetExhausted => '其目標已用完預算。';

  @override
  String get wakeKindGoalReviewStale => '自要求此檢閱後，目標已變更。';

  @override
  String get wakeKindGoalPaused => '其目標已暫停。';

  @override
  String get wakeKindGoalHeld => '其目標已保留。';

  @override
  String get wakeKindGoalStopped => '其目標已停止。';

  @override
  String get wakeKindAskSettled => '它所回答的問題已經定案。';

  @override
  String get wakeKindRuleEnded => '其排程已結束。';

  @override
  String get wakeRefusalNotYours => '此喚醒代表另一位人員。只有對方可以傳送或繼續它。';

  @override
  String get wakeRefusalSettled => '此喚醒已經處理完畢。';

  @override
  String get goalRefusalAlreadyActive => '此代理已有進行中的目標。';

  @override
  String get goalRefusalNotInReview => '此目標並未等待檢閱。';

  @override
  String get goalRefusalEvidenceIncomplete => '目標的佐證資料不完整。';

  @override
  String get goalRefusalClaimPending => '關於已完成的聲明仍在檢查中。';

  @override
  String get goalRefusalNotActiveSegment => '此目標沒有正在執行的分段。';

  @override
  String get goalRefusalNotYours => '只有啟動此目標的人員可以執行此操作。';

  @override
  String get goalRefusalNotPaused => '請先暫停目標。';

  @override
  String get goalRefusalContractInvalid => '無法讀取目標的合約。';

  @override
  String get goalRefusalCheckerUnknown => '沒有名為此名稱的代理。';

  @override
  String get goalRefusalCheckerAmbiguous => '有多個代理使用此名稱。';

  @override
  String get goalRefusalCheckerIsGoalAgent => '檢查器必須是執行工作的代理以外的另一個代理。';

  @override
  String get goalRefusalCommandInvalid => '無法讀取此目標：';

  @override
  String get wakeRuleRefusalIntervalTooShort => '間隔太短。請至少選擇一分鐘。';

  @override
  String get wakeRuleRefusalTooSoon => '該時間太近了。請選擇較晚的時間。';

  @override
  String get wakeRuleRefusalLineageEnded => '這一連串的喚醒已用完其執行次數或時間。';

  @override
  String get wakeRuleRefusalWatchTargetUnreadable => '你無法讀取此監看將觀察的對象。';

  @override
  String get wakeRuleRefusalExpiryRequired => '請設定結束日期或執行次數。';

  @override
  String get wakeRuleRefusalLimitReached => '此對話或代理已達到可建立排程的數量上限。';

  @override
  String get wakeRuleRefusalInvalidWhen => '無法讀取該時間。';

  @override
  String get wakeRuleRefusalNoteTooLong => '備註太長。';

  @override
  String get wakeRuleRefusalExpiryTooLong => '結束時間太遠了。';

  @override
  String get wakeRuleRefusalLimitOutOfRange => '執行次數、天數或預算上限超出範圍。';

  @override
  String get wakeRuleRefusalNextOutsideLoop => '只有迴圈可以自行選擇下一次的時間。';

  @override
  String get wakeRuleRefusalWatchRefused => '無法監看此項目。';

  @override
  String get wakeRuleRefusalRuleEnded => '該排程已經結束。';

  @override
  String get wakeRuleRefusalNotYours => '該排程屬於其他人。';

  @override
  String get wakeRuleEndFired => '它已執行一次。';

  @override
  String get wakeRuleEndExpired => '已達到結束日期。';

  @override
  String get wakeRuleEndRunCap => '已用完其執行次數。';

  @override
  String get wakeRuleEndCostCap => '已達到其成本上限。';

  @override
  String get wakeRuleEndGoalEnded => '其目標已結束。';

  @override
  String get wakeRuleEndCancelled => '已取消。';

  @override
  String get wakeRuleEndMemberRemoved => '其人員已離開工作區。';

  @override
  String get wakeRuleEndInvalidRow => '無法讀取其已儲存的設定。';

  @override
  String goalHoldWorking(int segment) {
    final intl.NumberFormat segmentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String segmentString = segmentNumberFormat.format(segment);

    return '正在執行第 $segmentString 段。無需任何人處理。';
  }

  @override
  String get goalHoldWaiting => '正在等待它應得的工作。它會自行繼續。';

  @override
  String goalHoldWaitingUntil(String time) {
    return '正在等待它應得的工作。最遲將於 $time 自行繼續。';
  }

  @override
  String get goalHoldVerifying => '它表示已完成。伺服器會執行其驗證，接著由檢閱者決定。';

  @override
  String get goalHoldLimit => '已在供應商的用量上限處暫停。重設後它會自行繼續。';

  @override
  String goalHoldLimitUntil(String time) {
    return '已在供應商的用量上限處暫停。它將於 $time 自行繼續。';
  }

  @override
  String get goalHoldPerson => '正在等待人員在對話中回覆。有人回覆後它會繼續。';

  @override
  String get goalHoldByPerson => '已由人員暫停。在有人繼續它之前，它會保持暫停。';

  @override
  String get goalHoldNeedsReview => '等待檢閱：它無法自行繼續。請將它標示為已完成、繼續或取消。';

  @override
  String get goalHoldBudget => '它已用完預算。請提高預算，讓它繼續。';

  @override
  String goalHoldLimitParks(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return '用量上限暫停次數：$countString / $maxString';
  }

  @override
  String get goalHoldDetailStalled => '最近幾個分段沒有任何進展。';

  @override
  String get goalHoldDetailStalledWaiting => '它已在同一項工作上等待 24 小時，沒有任何進展。';

  @override
  String get goalHoldDetailVerificationFailed => '上次驗證失敗。';

  @override
  String get goalHoldDetailCannotVerify => '檢查器無法判斷它是否已完成。';

  @override
  String get goalHoldDetailSandboxUnavailable => '沒有可用的沙箱來執行其驗證。';

  @override
  String get goalHoldDetailCheckerUnavailable => '其檢查器代理無法使用。請選擇另一個檢查器，然後繼續。';

  @override
  String get goalHoldDetailCheckBroken => '此驗證無法執行：';

  @override
  String get goalHoldDetailWakeSkipped => '其喚醒未被傳送。';

  @override
  String get goalHoldDetailClaimPending => '其已完成的聲明正等待驗證。';

  @override
  String get goalHoldDetailUnanswered => '給人員的問題或核准請求未獲回覆。';

  @override
  String get goalHoldDetailLimitParks => '它太常碰到用量上限。請檢視後再繼續。';

  @override
  String get goalHoldDetailInput => '正等待對話中的回覆。';

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

    return '第 $runString 段，共 $maxString 段';
  }

  @override
  String goalSegmentsNoCap(int run) {
    final intl.NumberFormat runNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String runString = runNumberFormat.format(run);

    return '第 $runString 段，無上限';
  }

  @override
  String goalMoney(String spent, String cap) {
    return '已用 $spent，上限 $cap';
  }

  @override
  String goalDeadline(String time) {
    return '截止時間 $time';
  }

  @override
  String get goalPipelineStep => '管線步驟正在為此目標工作。';

  @override
  String get goalSummaryHeading => '最近的摘要';

  @override
  String get goalDoneMeans => '完成的標準';

  @override
  String get goalChecks => '驗證';

  @override
  String get goalBoundaries => '界線';

  @override
  String get goalStopWhen => '何時停止並詢問';

  @override
  String get goalNoMachineCheck => '沒有機器驗證。檢閱者會依其可讀取的內容判斷。';

  @override
  String get goalCheckEnvironment => '環境任務';

  @override
  String goalLastCheck(int round, String time) {
    final intl.NumberFormat roundNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String roundString = roundNumberFormat.format(round);

    return '最近一次驗證，第 $roundString 輪，$time';
  }

  @override
  String get goalClaim => '其聲明內容';

  @override
  String get goalCheckPassed => '通過';

  @override
  String goalCheckFailed(int code) {
    return '失敗，結束代碼 $code';
  }

  @override
  String get goalCheckTimedOut => '已逾時';

  @override
  String get goalCheckNotRerun => '未重新執行：自上次通過後沒有任何變更';

  @override
  String get goalCheckBroken => '無法執行';

  @override
  String get goalCriterionMet => '已達成';

  @override
  String get goalCriterionUnmet => '未達成';

  @override
  String get goalCriterionCannotTell => '無法判斷';

  @override
  String get goalVerdictPass => '結論：已完成';

  @override
  String get goalVerdictFail => '結論：未完成';

  @override
  String get goalVerdictCannotVerify => '結論：無法判斷';

  @override
  String get goalConcerns => '疑慮';

  @override
  String goalVerifiedBy(String agent) {
    return '由 $agent 驗證';
  }

  @override
  String get goalVerifiedBySelf => '由其自身驗證（沒有另外的檢查器）';

  @override
  String get goalClosedByPerson => '由人員在未通過驗證的情況下結束';

  @override
  String get goalApprove => '核准完成';

  @override
  String get goalApproveTitle => '要將此目標標示為已完成嗎？';

  @override
  String get goalApproveBody => '沒有任何驗證確認它。你將依自己的判斷結束它，而目標會記錄為由人員在未驗證的情況下結束。';

  @override
  String get goalApproveConfirm => '標示為已完成';

  @override
  String get goalResumeNotYours => '繼續執行或提高其預算，屬於啟動它的人員。';

  @override
  String get goalChooseChecker => '選擇另一位檢查器';

  @override
  String goalCheckerSet(String agent) {
    return '現在由 $agent 檢查。請繼續以重新驗證。';
  }

  @override
  String get goalSchedules => '排程';

  @override
  String get goalRepeat => '重複執行';

  @override
  String get goalCreateChecks => '驗證（選填）';

  @override
  String get goalCreateCheckHint => '工作完成時會通過的指令';

  @override
  String get goalCreateAddCheck => '新增驗證';

  @override
  String get goalCreateRemoveCheck => '移除驗證';

  @override
  String get goalCreateSegmentCap => '分段上限（選填）';

  @override
  String get goalCreateSegmentInvalid => '分段上限必須是至少為 1 的整數。';

  @override
  String get scheduleCreateTitle => '重複一則提示';

  @override
  String get scheduleCadence => '頻率';

  @override
  String get scheduleEveryMinutes => '每 N 分鐘';

  @override
  String get scheduleEveryHours => '每 N 小時';

  @override
  String get scheduleSelfPaced => '由代理決定';

  @override
  String get scheduleSelfPacedHint => '代理會在每次執行後，自行決定延遲 1 分鐘到 1 小時。';

  @override
  String get scheduleInterval => '間隔';

  @override
  String get scheduleNote => '每次執行要做什麼？';

  @override
  String get scheduleCostCap => '成本上限（美元，選填）';

  @override
  String get scheduleExpiryDays => '經過 N 天後結束（選填）';

  @override
  String get scheduleCreateInvalid => '請選擇空間與代理、寫下每次執行要做什麼，並輸入至少為 1 的整數。';

  @override
  String get scheduleCreateButton => '啟動排程';

  @override
  String get scheduleCreateConfirmTitle => '要啟動此排程嗎？';

  @override
  String scheduleCreateConfirmEveryMinutes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '每 $countString 分鐘執行一次，從現在開始。',
      one: '每分鐘執行一次，從現在開始。',
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
      other: '每 $countString 小時執行一次，從現在開始。',
      one: '每小時執行一次，從現在開始。',
    );
    return '$_temp0';
  }

  @override
  String get scheduleCreateConfirmSelfPaced => '現在先執行一次，之後由代理決定何時再次執行。';

  @override
  String get scheduleCreated => '排程已啟動，會列在排程下方。';

  @override
  String get schedulesTitle => '排程';

  @override
  String get schedulesLoadFailed => '無法載入排程';

  @override
  String get schedulesEmpty => '沒有排程或監看';

  @override
  String get schedulesEmptyDescription =>
      '從目標畫面重複一則提示，或在對話中傳送 /loop 或 /schedule。';

  @override
  String get scheduleMissing => '此排程在此工作區中已無法使用。';

  @override
  String scheduleEvery(String interval) {
    return '每 $interval';
  }

  @override
  String get scheduleSelfPacedLoop => '由代理決定的迴圈';

  @override
  String get scheduleCron => 'Cron 排程';

  @override
  String scheduleOnce(String time) {
    return '於 $time 執行一次';
  }

  @override
  String scheduleWatch(String event) {
    return '監看：$event';
  }

  @override
  String get scheduleWatchPrChecks => 'pull request 檢查';

  @override
  String get scheduleWatchPrReview => 'pull request 審查';

  @override
  String get scheduleWatchPrMerged => 'pull request 合併';

  @override
  String get scheduleWatchEnvironment => '環境';

  @override
  String get scheduleWatchTicket => '工單';

  @override
  String get scheduleWatchPipelineRun => '管線執行';

  @override
  String get scheduleStatusActive => '進行中';

  @override
  String get scheduleStatusPaused => '已暫停';

  @override
  String get scheduleStatusEnded => '已結束';

  @override
  String scheduleWakes(String agent) {
    return '喚醒 $agent';
  }

  @override
  String scheduleNext(String time) {
    return '下次執行 $time';
  }

  @override
  String scheduleLast(String time) {
    return '上次執行 $time';
  }

  @override
  String scheduleRuns(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString 次執行',
      one: '1 次執行',
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

    return '已執行 $countString / $maxString 次';
  }

  @override
  String scheduleSkipped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已略過 $countString 次',
      one: '已略過 1 次',
    );
    return '$_temp0';
  }

  @override
  String scheduleEnds(String time) {
    return '$time 結束';
  }

  @override
  String scheduleChain(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '屬於一個連鎖：剩餘 $countString 次執行，於 $time 結束';
  }

  @override
  String get scheduleNoteAgent => '代理自己的備註，以其自己的話說：';

  @override
  String get scheduleNotePerson => '人員的備註：';

  @override
  String scheduleActsFor(String name) {
    return '代表 $name';
  }

  @override
  String get scheduleActsForBot => '不代表任何人';

  @override
  String get scheduleGoalBound => '它會隨其目標一併結束。';

  @override
  String get schedulePause => '暫停';

  @override
  String get scheduleResume => '繼續';

  @override
  String get scheduleDelete => '刪除';

  @override
  String get scheduleRemove => '移除';

  @override
  String get scheduleDeleteTitle => '要刪除此排程嗎？';

  @override
  String get scheduleDeleteBody => '它將永久停止。它已完成的操作不會復原。';

  @override
  String get scheduleRemoveTitle => '要移除此排程嗎？';

  @override
  String get scheduleRemoveBody => '它會從清單中消失。';

  @override
  String get scheduleResumeNotYours => '只有此排程所代表的人員可以繼續它。';

  @override
  String get scheduleResumeAdminOnly => '只有工作區管理員可以繼續不屬於任何人的排程。';

  @override
  String get scheduleOpenConversation => '開啟對話';

  @override
  String get progressWaiting => '等待中';

  @override
  String get progressNothingWaiting => '沒有任何項目在等待。';

  @override
  String get wakeOriginGoal => '目標';

  @override
  String get wakeOriginGoalCheck => '目標驗證';

  @override
  String get wakeOriginGoalReview => '目標檢閱';

  @override
  String get wakeOriginSchedule => '排程';

  @override
  String get wakeOriginWatch => '監看';

  @override
  String get wakeOriginReply => '回覆';

  @override
  String get wakeOriginMessage => '訊息';

  @override
  String get wakeOriginWorkFinished => '已完成的工作';

  @override
  String get wakeOriginLimitReset => '用量上限已重設';

  @override
  String get wakeOriginRecovery => '復原';

  @override
  String get wakeOriginAssignment => '指派';

  @override
  String get wakeOriginPipelineStep => '管線步驟';

  @override
  String get wakeOriginImprovementReview => '改進檢閱';

  @override
  String wakeOriginReplyFrom(String agent) {
    return '來自 $agent 的回覆';
  }

  @override
  String wakeOriginMessageFrom(String agent) {
    return '來自 $agent 的訊息';
  }

  @override
  String wakeOriginWorkFinishedBy(String agent) {
    return '$agent 完成的工作';
  }

  @override
  String wakeFor(String agent) {
    return '給 $agent';
  }

  @override
  String wakeDue(String time) {
    return '預定 $time';
  }

  @override
  String get wakeDueNow => '現已到期';

  @override
  String get wakeHeld => '已保留';

  @override
  String wakeExpires(String time) {
    return '$time 過期';
  }

  @override
  String wakeAttempt(int attempt) {
    final intl.NumberFormat attemptNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String attemptString = attemptNumberFormat.format(attempt);

    return '第 $attemptString 次嘗試';
  }

  @override
  String get wakeCancel => '取消';

  @override
  String get wakeDeliverNow => '立即傳送';

  @override
  String get wakeResume => '繼續';

  @override
  String get wakeDismiss => '關閉';

  @override
  String get wakeResumeOnlyTheirs => '只有執行此項的人員可以繼續它。';

  @override
  String get wakeRecovery => '伺服器在此次執行期間重新啟動。請繼續以接續執行，或關閉此項。';

  @override
  String limitParkTitle(String provider, String time) {
    return '已在 $provider 的用量限制下暫停，該限制將於 $time 重設。執行會等待「繼續」，最多至重設後 7 天。';
  }

  @override
  String limitParkTitleUnnamed(String time) {
    return '已在供應商的用量限制下暫停，該限制將於 $time 重設。執行會等待「繼續」，最多至重設後 7 天。';
  }

  @override
  String get limitParkResumeNow => '立即繼續';

  @override
  String get limitParkCancel => '取消';

  @override
  String limitParkResumed(String provider) {
    return '$provider 的用量上限過後已繼續。';
  }

  @override
  String limitParkGone(String provider) {
    return '已不再於 $provider 的用量上限處等待。';
  }

  @override
  String get limitParkProviderUnknown => '供應商';

  @override
  String get mobileHeldMessages => '保留的訊息';

  @override
  String get heldSteeringTitle => '因執行在能接收前就已結束而保留。請現在傳送你的訊息，或將其移除。';

  @override
  String get heldSteeringRelease => '傳送保留的訊息';

  @override
  String get notifGoalCompleted => '目標已完成';

  @override
  String get notifGoalFailed => '目標失敗';

  @override
  String get notifGoalCancelled => '目標已取消';

  @override
  String get notifGoalBudgetExhausted => '目標已用完預算';

  @override
  String get notifGoalNeedsReview => '有一個目標等待你檢閱';

  @override
  String get notifGoalNeedsPerson => '有一個目標需要你處理';

  @override
  String get notifGoalOnHold => '有一個目標已保留';

  @override
  String get notifWakeRuleEnded => '有一個排程已結束';

  @override
  String notifWaitingDigest(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $countString 件事等待你處理',
      one: '有 1 件事等待你處理',
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
      other: '已提出 $countString 項改進',
      one: '已提出 1 項改進',
    );
    return '$_temp0';
  }

  @override
  String get notifPipelineRunHeld => '管線執行因預算而保留';

  @override
  String notifPipelineRunHeldBody(String spent, String cap) {
    return '已用 $spent，上限 $cap';
  }

  @override
  String get notifNeedsYou => '需要你處理';

  @override
  String get notifDigestGoalReview => '目標等待檢閱';

  @override
  String get notifDigestGoalPerson => '目標需要人員處理';

  @override
  String get notifDigestHeldWake => '已保留的喚醒';

  @override
  String get notifDigestImprovement => '已提出的改進';

  @override
  String get wakeKindRulePaused => '其排程已暫停。';

  @override
  String get wakeKindRuleBusy => '代理忙碌中，而此排程在這種情況下會略過該時間。';

  @override
  String get wakeKindRuleFolded => '同一監看的較後事件取代了它。';

  @override
  String get wakeKindRuleSuperseded => '此排程較晚的時間取代了它。';

  @override
  String get wakeKindRuleNotified => '此排程只發送通知，因此沒有啟動執行。';

  @override
  String get wakeKindRuleLimitParked => '此排程正在等待供應商的用量上限重設。';

  @override
  String get improvementRefusalCooldown => '此對話在不久前才執行過改進檢閱。請稍後再試。';

  @override
  String get improvementRefusalQueued => '此對話的改進檢閱已在等待執行。';

  @override
  String get improvementRefusalAgentNotFound => '指定的代理不屬於此工作區。';

  @override
  String get steeringRefusalHeldByLimit => '用量上限所保留的訊息無法手動傳送。它們會等待暫停的執行繼續。';

  @override
  String limitParkCancelled(String provider) {
    return '已取消在 $provider 用量上限處的等待。';
  }

  @override
  String limitParkExpired(String provider) {
    return '在執行繼續之前，$provider 用量上限處的等待已過期。';
  }

  @override
  String limitParkSkipped(String provider) {
    return '執行未在 $provider 的用量上限過後繼續。';
  }

  @override
  String get heldSteeringLimitTitle => '執行等待用量限制重設期間保留。這些訊息會在其所代表的人繼續執行時送出。';

  @override
  String heldSteeringLimitAt(String time) {
    return '保留至用量限制於 $time 重設。這些訊息會在其所代表的人繼續執行時送出。';
  }

  @override
  String get heldSteeringOtherTitle => '由伺服器保留。你可以移除它們。';

  @override
  String workRowWoke(int count, String agent) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '為 $countString 個等待項目喚醒了 $agent',
      one: '已喚醒 $agent',
    );
    return '$_temp0';
  }

  @override
  String workRowWakeMissed(String agent) {
    return '伺服器關閉期間，錯過了給 $agent 的喚醒。';
  }

  @override
  String workRowWakeSkipped(String agent) {
    return '未傳送給 $agent 的喚醒。';
  }

  @override
  String workRowScheduleCreated(String agent) {
    return '已為 $agent 設定排程。';
  }

  @override
  String workRowScheduleEnded(String agent) {
    return '$agent 的排程已結束。';
  }

  @override
  String workRowNoteFromAgent(String agent) {
    return '來自 $agent 的排程備註：';
  }

  @override
  String get workRowNoteFromPerson => '來自某人的排程備註：';

  @override
  String workRowCommandRefusedNamed(String command) {
    return '$command 指令被拒絕了。';
  }

  @override
  String get workRowCommandRefused => '有一則指令被拒絕了。';

  @override
  String workRowCapRaised(String person, String from, String to) {
    return '$person 已將管線的花費上限從 $from 提高至 $to。';
  }

  @override
  String workRowCapRaisedNoAmounts(String person) {
    return '$person 已提高管線的花費上限。';
  }

  @override
  String get workRowApplyIncomplete => '對此技能已接受的變更無法完成，因為技能在此期間已變更。此提案已回復。';

  @override
  String get workRowOpenSchedule => '開啟排程';

  @override
  String get heldSteeringOthersTitle => '因執行在能接收前就已結束而保留。只有撰寫訊息的人員可以傳送。';

  @override
  String get heldSteeringOnlyYours => '只會傳送你的訊息。其他人的訊息會等待撰寫者處理。';

  @override
  String heldSteeringWrittenBy(String name) {
    return '由 $name 撰寫';
  }

  @override
  String get steeringRefusalNotYours => '只有撰寫保留訊息的人員可以傳送，而這些訊息都不屬於你。';

  @override
  String get steeringRefusalNeedsWrite => '你需要此空間儲存庫的寫入權限，才能引導代表其他人的執行。';

  @override
  String workRowSchedulePaused(String name, String agent) {
    return '$name 已暫停 $agent 的排程。';
  }

  @override
  String get goalVerdictObjective => '目標整體';

  @override
  String get notifDigestRequest => '等待你的回答';
}
